///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	TaskWasExecuted = Common.ObjectAttributeValue(Ref, "Executed");
	If Executed AND TaskWasExecuted <> True AND NOT AddressingAttributesAreFilled() Then
		
		Common.MessageToUser(
			NStr("ru = 'Необходимо указать исполнителя задачи.'; en = 'Specify task assignee.'; pl = 'Specify task assignee.';de = 'Specify task assignee.';ro = 'Specify task assignee.';tr = 'Specify task assignee.'; es_ES = 'Specify task assignee.'"),,,
			"Object.Performer", Cancel);
		Return;
			
	EndIf;
	
	If DueDate <> '00010101' AND StartDate > DueDate Then
		Common.MessageToUser(
			NStr("ru = 'Дата начала исполнения не должна превышать крайний срок.'; en = 'Execution start date cannot be later than the deadline.'; pl = 'Execution start date cannot be later than the deadline.';de = 'Execution start date cannot be later than the deadline.';ro = 'Execution start date cannot be later than the deadline.';tr = 'Execution start date cannot be later than the deadline.'; es_ES = 'Execution start date cannot be later than the deadline.'"),,,
			"Object.StartDate", Cancel);
		Return;
	EndIf;
	
EndProcedure

Procedure BeforeWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	If NOT Ref.IsEmpty() Then
		InitialAttributes = Common.ObjectAttributesValues(Ref, 
			"Executed, DeletionMark, BusinessProcessState");
	Else
		InitialAttributes = New Structure(
			"Executed, DeletionMark, BusinessProcessState",
			False, False, Enums.BusinessProcessStates.EmptyRef());
	EndIf;
		
	If InitialAttributes.DeletionMark <> DeletionMark Then
		BusinessProcessesAndTasksServer.OnMarkTaskForDeletion(Ref, DeletionMark);
	EndIf;
	
	If NOT InitialAttributes.Executed AND Executed Then
		
		If BusinessProcessState = Enums.BusinessProcessStates.Stopped Then
			Raise NStr("ru = 'Нельзя выполнять задачи остановленных бизнес-процессов.'; en = 'Cannot perform tasks of terminated business processes.'; pl = 'Cannot perform tasks of terminated business processes.';de = 'Cannot perform tasks of terminated business processes.';ro = 'Cannot perform tasks of terminated business processes.';tr = 'Cannot perform tasks of terminated business processes.'; es_ES = 'Cannot perform tasks of terminated business processes.'");
		EndIf;
		
		// If the task is completed, writing the user that actually completed the task to the Performer 
		// attribute. It is needed later for reports.
		//  This action is only required if the task is not completed in the infobase, but it is completed 
		// in the object.
		If NOT ValueIsFilled(Performer) Then
			Performer = Users.AuthorizedUser();
		EndIf;
		If CompletionDate = Date(1, 1, 1) Then
			CompletionDate = CurrentSessionDate();
		EndIf;
	ElsIf NOT DeletionMark AND InitialAttributes.Executed AND Executed Then
			Common.MessageToUser(
				NStr("ru = 'Эта задача уже была выполнена ранее.'; en = 'This task is already completed.'; pl = 'This task is already completed.';de = 'This task is already completed.';ro = 'This task is already completed.';tr = 'This task is already completed.'; es_ES = 'This task is already completed.'"),,,, Cancel);
			Return;
	EndIf;
	
	If Importance.IsEmpty() Then
		Importance = Enums.TaskImportanceOptions.Normal;
	EndIf;
	
	If NOT ValueIsFilled(BusinessProcessState) Then
		BusinessProcessState = Enums.BusinessProcessStates.Active;
	EndIf;
	
	SubjectString = Common.SubjectString(Topic);
	
	If NOT Ref.IsEmpty() AND InitialAttributes.BusinessProcessState <> BusinessProcessState Then
		SetSubordinateBusinessProcessesState(BusinessProcessState);
	EndIf;
	
	If Executed AND Not AcceptedForExecution Then
		AcceptedForExecution = True;
		AcceptForExecutionDate = CurrentSessionDate();
	EndIf;
	
	// StandardSubsystems.AccessManagement
	SetPrivilegedMode(True);
	TaskPerformersGroup = BusinessProcessesAndTasksServer.TaskPerformersGroup(PerformerRole, 
		MainAddressingObject, AdditionalAddressingObject);
	SetPrivilegedMode(False);
	// End StandardSubsystems.AccessManagement
	
	// Filling attribute AcceptForExecutionDate.
	If AcceptedForExecution AND AcceptForExecutionDate = Date('00010101') Then
		AcceptForExecutionDate = CurrentSessionDate();
	EndIf;
	
EndProcedure

Procedure Filling(FillingData, FillingText, StandardProcessing)
	
	If TypeOf(FillingData) = Type("TaskObject.PerformerTask") Then
		FillPropertyValues(ThisObject, FillingData, 
			"BusinessProcess,RoutePoint,Description,Performer,PerformerRole,MainAddressingObject," 
			+ "AdditionalAddressingObject,Importance,CompletionDate,Author,Details,DueDate," 
			+ "StartDate,ExecutionResult,Topic");
		Date = CurrentSessionDate();
	EndIf;
	If NOT ValueIsFilled(Importance) Then
		Importance = Enums.TaskImportanceOptions.Normal;
	EndIf;
	
	If NOT ValueIsFilled(BusinessProcessState) Then
		BusinessProcessState = Enums.BusinessProcessStates.Active;
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

Procedure SetSubordinateBusinessProcessesState(NewState)
	
	BeginTransaction();
	Try
		SubordinateBusinessProcesses = BusinessProcessesAndTasksServer.MainTaskBusinessProcesses(Ref, True);
		
		If SubordinateBusinessProcesses <> Undefined Then
			For Each SubordinateBusinessProcess In SubordinateBusinessProcesses Do
				BusinessProcessObject = SubordinateBusinessProcess.GetObject();
				BusinessProcessObject.Lock();
				BusinessProcessObject.State = NewState;
				BusinessProcessObject.Write();
			EndDo;	
		EndIf;	
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;
	
EndProcedure

// Determines whether addressing attributes are filled in: assignee or assignee role.
// 
// Returns:
//  Boolean - returns True if an assignee or assignee role is specified in the task.
//
Function AddressingAttributesAreFilled()
	
	Return ValueIsFilled(Performer) OR NOT PerformerRole.IsEmpty();

EndFunction

#EndRegion

#Else
Raise NStr("ru = 'Недопустимый вызов объекта на клиенте.'; en = 'Invalid object call on the client.'; pl = 'Invalid object call on the client.';de = 'Invalid object call on the client.';ro = 'Invalid object call on the client.';tr = 'Invalid object call on the client.'; es_ES = 'Invalid object call on the client.'");
#EndIf