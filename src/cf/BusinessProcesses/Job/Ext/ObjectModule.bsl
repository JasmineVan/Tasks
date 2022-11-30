///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

#Region ForCallsFromOtherSubsystems

// StandardSubsystems.AccessManagement

// See AccessManagement.FillAccessValuesSets. 
Procedure FillAccessValuesSets(Table) Export
	
	BusinessProcessesAndTasksOverridable.OnFillingAccessValuesSets(ThisObject, Table);
	
	If Table.Count() > 0 Then
		Return;
	EndIf;
	
	FillDefaultAccessValuesSets(Table);
	
EndProcedure

// End StandardSubsystems.AccessManagement

#EndRegion

#EndRegion

#Region EventHandlers

////////////////////////////////////////////////////////////////////////////////
// Business process event handlers.

Procedure BeforeWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	If Author <> Undefined AND Not Author.IsEmpty() Then
		AuthorString = String(Author);
	EndIf;
	
	BusinessProcessesAndTasksServer.ValidateRightsToChangeBusinessProcessState(ThisObject);
	
	If ValueIsFilled(MainTask)
		AND Common.ObjectAttributeValue(MainTask, "BusinessProcess") = Ref Then
		
		Raise NStr("ru = 'Собственная задача бизнес-процесса не может быть указана как главная задача.'; en = 'Business process task cannot be specified as the main task.'; pl = 'Business process task cannot be specified as the main task.';de = 'Business process task cannot be specified as the main task.';ro = 'Business process task cannot be specified as the main task.';tr = 'Business process task cannot be specified as the main task.'; es_ES = 'Business process task cannot be specified as the main task.'");
		
	EndIf;
	
	SetPrivilegedMode(True);
	TaskPerformersGroup = ?(TypeOf(Performer) = Type("CatalogRef.PerformerRoles"),
		BusinessProcessesAndTasksServer.TaskPerformersGroup(Performer, MainAddressingObject, AdditionalAddressingObject),
		Performer);
	TaskPerformersGroupSupervisor = ?(TypeOf(Supervisor) = Type("CatalogRef.PerformerRoles"),
		BusinessProcessesAndTasksServer.TaskPerformersGroup(Supervisor, MainAddressingObjectSupervisor, AdditionalAddressingObjectSupervisor),
		Supervisor);
	SetPrivilegedMode(False);
	
	If NOT IsNew() AND Common.ObjectAttributeValue(Ref, "Topic") <> Topic Then
		ChangeTaskSubject();
	EndIf;
	
EndProcedure

Procedure Filling(FillingData, FillingText, StandardProcessing)
	
	If IsNew() Then
		Author = Users.AuthorizedUser();
		Supervisor = Users.AuthorizedUser();
		If TypeOf(FillingData) = Type("CatalogRef.Users") Then
			Performer = FillingData;
		Else
			// For auto completion in a blank Assignee field.
			Performer = Catalogs.Users.EmptyRef();
		EndIf;
	EndIf;
	
	If FillingData <> Undefined AND TypeOf(FillingData) <> Type("Structure") 
		AND FillingData <> Tasks.PerformerTask.EmptyRef() Then
		
		If TypeOf(FillingData) <> Type("TaskRef.PerformerTask") Then
			Topic = FillingData;
		Else
			Topic = FillingData.Topic;
		EndIf;
		
	EndIf;	
	
	BusinessProcessesAndTasksServer.FillMainTask(ThisObject, FillingData);

EndProcedure

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	NotCheckedAttributeArray = New Array();
	If Not OnValidation Then
		NotCheckedAttributeArray.Add("Supervisor");
	EndIf;
	Common.DeleteNotCheckedAttributesFromArray(CheckedAttributes, NotCheckedAttributeArray);
EndProcedure

Procedure OnCopy(CopiedObject)
	
	IterationNumber = 0;
	JobCompleted = False;
	Confirmed = False;
	ExecutionResult = "";
	CompletedOn = '00010101000000';
	State = Enums.BusinessProcessStates.Active;
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Flowchart items event handlers.

Procedure ExecuteOnCreateTasks(BusinessProcessRoutePoint, TasksBeingFormed, Cancel)
	
	IterationNumber = IterationNumber + 1;
	Write();
	
	// Setting the addressing attributes and additional attributes for each task.
	For each Task In TasksBeingFormed Do
		
		Task.Author = Author;
		Task.AuthorString = String(Author);
		If TypeOf(Performer) = Type("CatalogRef.PerformerRoles") Then
			Task.PerformerRole = Performer;
			Task.MainAddressingObject = MainAddressingObject;
			Task.AdditionalAddressingObject = AdditionalAddressingObject;
			Task.Performer = Undefined;
		Else	
			Task.Performer = Performer;
		EndIf;
		Task.Description = TaskDescriptionForExecution();
		Task.DueDate = TaskDueDateForExecution();
		Task.Importance = Importance;
		Task.Topic = Topic;
		
	EndDo;
	
EndProcedure

Procedure ExecuteBeforeTasksCreation(BusinessProcessRoutePoint, TasksBeingFormed, StandardProcessing)
	
	If Topic = Undefined Or Topic.IsEmpty() Then
		Return;
	EndIf;
	
EndProcedure

Procedure ExecuteOnExecute(BusinessProcessRoutePoint, Task, Cancel)
	
	ExecutionResult = CompletePointExecutionResult(Task) + ExecutionResult;
	Write();
	
EndProcedure

Procedure CheckOnCreateTasks(BusinessProcessRoutePoint, TasksBeingFormed, Cancel)
	
	If Supervisor.IsEmpty() Then
		Cancel = True;
		Return;
	EndIf;
	
	// Setting the addressing attributes and additional attributes for each task.
	For each Task In TasksBeingFormed Do
		
		Task.Author = Author;
		If TypeOf(Supervisor) = Type("CatalogRef.PerformerRoles") Then
			Task.PerformerRole = Supervisor;
			Task.MainAddressingObject = MainAddressingObjectSupervisor;
			Task.AdditionalAddressingObject = AdditionalAddressingObjectSupervisor;
		Else	
			Task.Performer = Supervisor;
		EndIf;
		
		Task.Description = TaskDescriptionForCheck();
		Task.DueDate = TaskDueDateForCheck();
		Task.Importance = Importance;
		Task.Topic = Topic;
		
	EndDo;
	
EndProcedure

Procedure CheckOnExecute(BusinessProcessRoutePoint, Task, Cancel)

	ExecutionResult = ValidatePointExecutionResult(Task) + ExecutionResult;
	Write();
	
EndProcedure

Procedure CheckRequiredConditionCheck(BusinessProcessRoutePoint, Result)
	
	Result = OnValidation;

EndProcedure

Procedure ReturnToPerformerConditionCheck(BusinessProcessRoutePoint, Result)
	
	Result = NOT Confirmed;
	
EndProcedure

Procedure CompletionOnComplete(BusinessProcessRoutePoint, Cancel)
	
	CompletedOn = BusinessProcessesAndTasksServer.BusinessProcessCompletionDate(Ref);
	Write();
	
EndProcedure

#EndRegion

#Region Private

// Updates the values of attributes of uncompleted tasks according to the Job business process 
// attributes:
//   Importance, DueDate, Description, and Author.
//
Procedure ChangeUncompletedTasksAttributes() Export

	BeginTransaction();
	Try
		Lock = New DataLock;
		LockItem = Lock.Add("Task.PerformerTask");
		LockItem.SetValue("BusinessProcess", Ref);
		Lock.Lock();
		
		Query = New Query( 
			"SELECT
			|	Tasks.Ref AS Ref
			|FROM
			|	Task.PerformerTask AS Tasks
			|WHERE
			|	Tasks.BusinessProcess = &BusinessProcess
			|	AND Tasks.DeletionMark = FALSE
			|	AND Tasks.Executed = FALSE");
		Query.SetParameter("BusinessProcess", Ref);
		DetailedRecordsSelection = Query.Execute().Select();
		
		While DetailedRecordsSelection.Next() Do
			TaskObject = DetailedRecordsSelection.Ref.GetObject();
			TaskObject.Importance = Importance;
			TaskObject.DueDate = 
				?(TaskObject.RoutePoint = BusinessProcesses.Job.RoutePoints.Execute, 
				TaskDueDateForExecution(), TaskDueDateForCheck());
			TaskObject.Description = 
				?(TaskObject.RoutePoint = BusinessProcesses.Job.RoutePoints.Execute, 
				TaskDescriptionForExecution(), TaskDescriptionForCheck());
			TaskObject.Author = Author;
			// Data are not locked for editing as
			// This change has a higher priority than the opened task forms.
			TaskObject.Write();
		EndDo;
		
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;

EndProcedure 

Procedure ChangeTaskSubject()

	SetPrivilegedMode(True);
	BeginTransaction();
	Try
		Lock = New DataLock;
		LockItem = Lock.Add("Task.PerformerTask");
		LockItem.SetValue("BusinessProcess", Ref);
		Lock.Lock();
		
		Query = New Query(
			"SELECT
			|	Tasks.Ref AS Ref
			|FROM
			|	Task.PerformerTask AS Tasks
			|WHERE
			|	Tasks.BusinessProcess = &BusinessProcess");

		Query.SetParameter("BusinessProcess", Ref);
		DetailedRecordsSelection = Query.Execute().Select();
		
		While DetailedRecordsSelection.Next() Do
			TaskObject = DetailedRecordsSelection.Ref.GetObject();
			TaskObject.Topic = Topic;
			// Data are not locked for editing as
			// This change has a higher priority than the opened task forms.
			TaskObject.Write();
		EndDo;
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;

EndProcedure 

Function TaskDescriptionForExecution()
	
	Return Description;	
	
EndFunction

Function TaskDueDateForExecution()
	
	Return DueDate;	
	
EndFunction

Function TaskDescriptionForCheck()
	
	Return BusinessProcesses.Job.RoutePoints.Validate.TaskDescription + ": " + Description;
	
EndFunction

Function TaskDueDateForCheck()
	
	Return VerificationDueDate;	
	
EndFunction

Function CompletePointExecutionResult(Val TaskRef)
	
	StringFormat = ?(JobCompleted,
		"%1, %2 " + NStr("ru = 'выполнил(а) задачу'; en = 'performed the task'; pl = 'performed the task';de = 'performed the task';ro = 'performed the task';tr = 'performed the task'; es_ES = 'performed the task'") + ":
		           |%3
		           |",
		"%1, %2 " + NStr("ru = 'отклонил(а) задачу'; en = 'declined the task'; pl = 'declined the task';de = 'declined the task';ro = 'declined the task';tr = 'declined the task'; es_ES = 'declined the task'") + ":
		           |%3
		           |");
	TaskData = Common.ObjectAttributesValues(TaskRef, 
		"ExecutionResult,CompletionDate,Performer");
	Comment = TrimAll(TaskData.ExecutionResult);
	Comment = ?(IsBlankString(Comment), "", Comment + Chars.LF);
	Result = StringFunctionsClientServer.SubstituteParametersToString(StringFormat, TaskData.CompletionDate, TaskData.Performer, Comment);
	Return Result;
	
EndFunction

Function ValidatePointExecutionResult(Val TaskRef)
	
	If NOT Confirmed Then
		StringFormat = "%1, %2 " + NStr("ru = 'вернул(а) задачу на доработку'; en = 'sent the task back for revision'; pl = 'sent the task back for revision';de = 'sent the task back for revision';ro = 'sent the task back for revision';tr = 'sent the task back for revision'; es_ES = 'sent the task back for revision'") + ":
			|%3
			|";
	Else
		StringFormat = ?(JobCompleted,
			"%1, %2 " + NStr("ru = 'подтвердил(а) выполнение задачи'; en = 'confirmed task completion'; pl = 'confirmed task completion';de = 'confirmed task completion';ro = 'confirmed task completion';tr = 'confirmed task completion'; es_ES = 'confirmed task completion'") + ":
			           |%3
			           |",
			"%1, %2 " + NStr("ru = 'подтвердил(а) отмену задачи'; en = 'confirmed task cancellation'; pl = 'confirmed task cancellation';de = 'confirmed task cancellation';ro = 'confirmed task cancellation';tr = 'confirmed task cancellation'; es_ES = 'confirmed task cancellation'") + ":
			           |%3
			           |");
	EndIf;
	
	TaskData = Common.ObjectAttributesValues(TaskRef, 
		"ExecutionResult,CompletionDate,Performer");
	Comment = TrimAll(TaskData.ExecutionResult);
	Comment = ?(IsBlankString(Comment), "", Comment + Chars.LF);
	Result = StringFunctionsClientServer.SubstituteParametersToString(StringFormat, TaskData.CompletionDate, TaskData.Performer, Comment);
	Return Result;

EndFunction

Procedure FillDefaultAccessValuesSets(Table)
	
	// Default restriction logic for
	// - Reading:    Author OR Performer (taking into account addressing) OR Supervisor (taking into account addressing).
	// - Changes: Author.
	
	// If the subject is not specified (the business process is not based on another subject), then the subject is not involved in the restriction logic.
	
	// Reading, Сhanging: set No.1.
	Row = Table.Add();
	Row.SetNumber     = 1;
	Row.Read          = True;
	Row.Update       = True;
	Row.AccessValue = Author;
	
	// Reading: set No. 2.
	Row = Table.Add();
	Row.SetNumber     = 2;
	Row.Read          = True;
	Row.AccessValue = TaskPerformersGroup;
	
	// Reading: set No. 3.
	Row = Table.Add();
	Row.SetNumber     = 3;
	Row.Read          = True;
	Row.AccessValue = TaskPerformersGroupSupervisor;
	
EndProcedure

#EndRegion

#Else
Raise NStr("ru = 'Недопустимый вызов объекта на клиенте.'; en = 'Invalid object call on the client.'; pl = 'Invalid object call on the client.';de = 'Invalid object call on the client.';ro = 'Invalid object call on the client.';tr = 'Invalid object call on the client.'; es_ES = 'Invalid object call on the client.'");
#EndIf