﻿///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region EventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	// Executing form initialization script. For new objects it is executed in OnCreateAtServer.
	// For an existing object it is executed in OnReadAtServer.
	If Object.Ref.IsEmpty() Then
		InitializeForm();
	EndIf;
	
	CurrentUser = Users.CurrentUser();
	
	// StandardSubsystems.FilesOperations
	If Common.SubsystemExists("StandardSubsystems.FilesOperations") Then
		ModuleFilesOperations = Common.CommonModule("FilesOperations");
		HyperlinkParameters = ModuleFilesOperations.FilesHyperlink();
		HyperlinkParameters.Placement = "CommandBar";
		HyperlinkParameters.Owner = "Object.BusinessProcess";
		ModuleFilesOperations.OnCreateAtServer(ThisObject, HyperlinkParameters);
	EndIf;
	// End StandardSubsystems.FilesOperations
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	BusinessProcessesAndTasksClient.UpdateAcceptForExecutionCommandsAvailability(ThisObject);
	
	// StandardSubsystems.FilesOperations
	If CommonClient.SubsystemExists("StandardSubsystems.FilesOperations") Then
		ModuleFilesOperationsClient = CommonClient.CommonModule("FilesOperationsClient");
		ModuleFilesOperationsClient.OnOpen(ThisObject, Cancel);
	EndIf;
	// End StandardSubsystems.FilesOperations
	
EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	ExecuteTask = False;
	If NOT (WriteParameters.Property("ExecuteTask", ExecuteTask) AND ExecuteTask) Then
		Return;
	EndIf;
	
	If NOT JobCompleted AND NOT JobConfirmed 
		AND NOT ValueIsFilled(CurrentObject.ExecutionResult) Then
		Common.MessageToUser(
			NStr("ru = 'Укажите причину, по которой задача возвращается на доработку.'; en = 'Specify the reason why the task is sent back for revision.'; pl = 'Specify the reason why the task is sent back for revision.';de = 'Specify the reason why the task is sent back for revision.';ro = 'Specify the reason why the task is sent back for revision.';tr = 'Specify the reason why the task is sent back for revision.'; es_ES = 'Specify the reason why the task is sent back for revision.'"),,
			"Object.ExecutionResult",,
			Cancel);
		Return;
	ElsIf NOT JobCompleted AND JobConfirmed 
		AND NOT ValueIsFilled(CurrentObject.ExecutionResult) Then
		Common.MessageToUser(
			NStr("ru = 'Укажите причину, по которой задача отменяется.'; en = 'Specify the reason why the task is canceled.'; pl = 'Specify the reason why the task is canceled.';de = 'Specify the reason why the task is canceled.';ro = 'Specify the reason why the task is canceled.';tr = 'Specify the reason why the task is canceled.'; es_ES = 'Specify the reason why the task is canceled.'"),,
			"Object.ExecutionResult",,
			Cancel);		
		Return;
	EndIf;
	
	WriteBusinessProcessAttributes(CurrentObject);
	
EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)
	
	InitializeForm();
	
	// StandardSubsystems.AccessManagement
	If Common.SubsystemExists("StandardSubsystems.AccessManagement") Then
		ModuleAccessManagement = Common.CommonModule("AccessManagement");
		ModuleAccessManagement.OnReadAtServer(ThisObject, CurrentObject);
	EndIf;
	// End StandardSubsystems.AccessManagement

EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	BusinessProcessesAndTasksClient.TaskFormNotificationProcessing(ThisObject, EventName, Parameter, Source);
	
	If EventName = "Write_Job" Then
		If (Source = JobReference OR (TypeOf(Source) = Type("Array") 
			AND Source.Find(JobReference) <> Undefined)) Then
			Read();
		EndIf;
	EndIf;
	
	// StandardSubsystems.FilesOperations
	If CommonClient.SubsystemExists("StandardSubsystems.FilesOperations") Then
		ModuleFilesOperationsClient = CommonClient.CommonModule("FilesOperationsClient");
		ModuleFilesOperationsClient.NotificationProcessing(ThisObject, EventName);
	EndIf;
	// End StandardSubsystems.FilesOperations
	
EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)

	// StandardSubsystems.AccessManagement
	If Common.SubsystemExists("StandardSubsystems.AccessManagement") Then
		ModuleAccessManagement = Common.CommonModule("AccessManagement");
		ModuleAccessManagement.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	EndIf;
	// End StandardSubsystems.AccessManagement

EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure ExecutionStartDateScheduledOnChange(Item)
	
	If Object.StartDate = BegOfDay(Object.StartDate) Then
		Object.StartDate = EndOfDay(Object.StartDate);
	EndIf;
	
EndProcedure

&AtClient
Procedure SubjectClick(Item, StandardProcessing)
	
	StandardProcessing = False;
	ShowValue(,Object.Topic);
	
EndProcedure

// StandardSubsystems.FilesOperations
&AtClient
Procedure Attachable_PreviewFieldClick(Item, StandardProcessing)
	
	If CommonClient.SubsystemExists("StandardSubsystems.FilesOperations") Then
		ModuleFilesOperationsClient = CommonClient.CommonModule("FilesOperationsClient");
		ModuleFilesOperationsClient.PreviewFieldClick(ThisObject, Item, StandardProcessing);
	EndIf;
	
EndProcedure

&AtClient
Procedure Attachable_PreviewFieldDragCheck(Item, DragParameters, StandardProcessing)
	
	If CommonClient.SubsystemExists("StandardSubsystems.FilesOperations") Then
		ModuleFilesOperationsClient = CommonClient.CommonModule("FilesOperationsClient");
		ModuleFilesOperationsClient.PreviewFieldCheckDragging(ThisObject, Item,
			DragParameters, StandardProcessing);
	EndIf;
	
EndProcedure

&AtClient
Procedure Attachable_PreviewFieldDrag(Item, DragParameters, StandardProcessing)
	
	If CommonClient.SubsystemExists("StandardSubsystems.FilesOperations") Then
		ModuleFilesOperationsClient = CommonClient.CommonModule("FilesOperationsClient");
		ModuleFilesOperationsClient.PreviewFieldDrag(ThisObject, Item,
			DragParameters, StandardProcessing);
	EndIf;
	
EndProcedure
// End StandardSubsystems.FilesOperations

#EndRegion

#Region FormCommandHandlers

&AtClient
Procedure WriteAndCloseComplete(Command)
	
	BusinessProcessesAndTasksClient.WriteAndCloseComplete(ThisObject);
	
EndProcedure

&AtClient
Procedure Completed(Command)
	
	JobConfirmed = True;
	JobCompleted = True;
	BusinessProcessesAndTasksClient.WriteAndCloseComplete(ThisObject, True);
	
EndProcedure

&AtClient
Procedure Returned(Command)
	
	JobConfirmed = False;
	JobCompleted = False;
	BusinessProcessesAndTasksClient.WriteAndCloseComplete(ThisObject, True);
	
EndProcedure

&AtClient
Procedure Canceled(Command)
	
	JobConfirmed = True;
	JobCompleted = False;
	BusinessProcessesAndTasksClient.WriteAndCloseComplete(ThisObject, True);
	
EndProcedure

&AtClient
Procedure ChangeJobComplete(Command)
	
	Write();
	ShowValue(,JobReference);
	
EndProcedure

&AtClient
Procedure More(Command)
	
	BusinessProcessesAndTasksClient.OpenAdditionalTaskInfo(Object.Ref);
	
EndProcedure

&AtClient
Procedure AcceptForExecution(Command)
	
	BusinessProcessesAndTasksClient.AcceptTaskForExecution(ThisObject, CurrentUser);	
	
EndProcedure

&AtClient
Procedure CancelAcceptForExecution(Command)
	
	BusinessProcessesAndTasksClient.CancelAcceptTaskForExecution(ThisObject);
	
EndProcedure

// StandardSubsystems.FilesOperations
&AtClient
Procedure Attachable_AttachedFilesPanelCommand(Command)
	
	If CommonClient.SubsystemExists("StandardSubsystems.FilesOperations") Then
		ModuleFilesOperationsClient = CommonClient.CommonModule("FilesOperationsClient");
		ModuleFilesOperationsClient.AttachmentsControlCommand(ThisObject, Command);
	EndIf;
	
EndProcedure
// End StandardSubsystems.FilesOperations

#EndRegion

#Region Private

&AtServer
Procedure InitializeForm()
	
	InitialExecutionFlag = Object.Executed;
	ReadBusinessProcessAttributes();
	SetItemsState();
	
	UseDateAndTimeInTaskDeadlines = GetFunctionalOption("UseDateAndTimeInTaskDeadlines");
	Items.ExecutionStartDateScheduledTime.Visible = UseDateAndTimeInTaskDeadlines;
	Items.CompletionDateTime.Visible = UseDateAndTimeInTaskDeadlines;
	BusinessProcessesAndTasksServer.SetDateFormat(Items.DueDate);
	BusinessProcessesAndTasksServer.SetDateFormat(Items.Date);
	
	BusinessProcessesAndTasksServer.TaskFormOnCreateAtServer(ThisObject, Object, 
		Items.StateGroup, Items.CompletionDate);
	Items.ResultDetails.ReadOnly = Object.Executed;
	Performer = ?(ValueIsFilled(Object.Performer), Object.Performer, Object.PerformerRole);
	
	If AccessRight("Update", Metadata.BusinessProcesses.Job) Then
		Items.Completed.Enabled = True;
		Items.Canceled.Enabled = True;
		Items.Returned.Enabled = True;
	Else
		Items.Completed.Enabled = False;
		Items.Canceled.Enabled = False;
		Items.Returned.Enabled = False;
	EndIf;
	
EndProcedure

&AtServer
Procedure ReadBusinessProcessAttributes()
	
	TaskObject = FormAttributeToValue("Object");
	
	SetPrivilegedMode(True);
	JobObject = TaskObject.BusinessProcess.GetObject();
	JobCompleted = JobObject.Completed;
	JobReference = JobObject.Ref;
	JobConfirmed = JobObject.Confirmed;
	JobExecutionResult = JobObject.ExecutionResult;
	JobContent = JobObject.Content;
	
EndProcedure	

&AtServer
Procedure WriteBusinessProcessAttributes(TaskObject)
	
	SetPrivilegedMode(True);
	JobObject = TaskObject.BusinessProcess.GetObject();
	LockDataForEdit(JobObject.Ref);
	JobObject.Completed = JobCompleted;
	JobObject.Confirmed = JobConfirmed;
	JobObject.Write();

EndProcedure	

&AtServer
Procedure SetItemsState()
	
	BusinessProcesses.Job.SetTaskFormItemsState(ThisObject);
	
EndProcedure	

#EndRegion
