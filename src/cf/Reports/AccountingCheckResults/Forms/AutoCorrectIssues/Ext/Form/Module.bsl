///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region EventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	CheckID = Parameters.CheckID;
	
	If CheckID = "StandardSubsystems.CheckCircularRefs" Then
		QuestionText = NStr("ru = 'Исправление циклических ссылок может занять продолжительное время. Выполнить исправление?'; en = 'Fixing the circular references can take a long time. Do you want to fix these?'; pl = 'Fixing the circular references can take a long time. Do you want to fix these?';de = 'Fixing the circular references can take a long time. Do you want to fix these?';ro = 'Fixing the circular references can take a long time. Do you want to fix these?';tr = 'Fixing the circular references can take a long time. Do you want to fix these?'; es_ES = 'Fixing the circular references can take a long time. Do you want to fix these?'");
	ElsIf CheckID = "StandardSubsystems.CheckNoPredefinedItems" Then
		QuestionText = NStr("ru = 'Создать отсутствующие предопределенные элементы заново?'; en = 'Create the missing predefined items?'; pl = 'Create the missing predefined items?';de = 'Create the missing predefined items?';ro = 'Create the missing predefined items?';tr = 'Create the missing predefined items?'; es_ES = 'Create the missing predefined items?'");
	EndIf;
	
	Items.QuestionLabel.Title = QuestionText;
	SetCurrentPage(ThisObject, "Question");
	
EndProcedure

#EndRegion

#Region FormCommandHandlers

&AtClient
Procedure ResolveIssue(Command)
	
	If CheckID = "StandardSubsystems.CheckCircularRefs" Then
		TimeConsumingOperation = ResolveIssueInBackground(CheckID);
		IdleParameters = TimeConsumingOperationsClient.IdleParameters(ThisObject);
		CompletionNotification = New NotifyDescription("FixIssueInBackgroundCompletion", ThisObject);
		TimeConsumingOperationsClient.WaitForCompletion(TimeConsumingOperation, CompletionNotification, IdleParameters);
	ElsIf CheckID = "StandardSubsystems.CheckNoPredefinedItems" Then
		SetCurrentPage(ThisObject, "TroubleshootingInProgress");
		RestoreMissingPredefinedItems();
		SetCurrentPage(ThisObject, "FixedSuccessfully");
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

&AtClientAtServerNoContext
Procedure SetCurrentPage(Form, PageName)
	
	FormItems = Form.Items;
	If PageName = "TroubleshootingInProgress" Then
		FormItems.TroubleshootingIndicatorGroup.Visible         = True;
		FormItems.TroubleshootingStartIndicatorGroup.Visible   = False;
		FormItems.TroubleshootingSuccessIndicatorGroup.Visible = False;
	ElsIf PageName = "FixedSuccessfully" Then
		FormItems.TroubleshootingIndicatorGroup.Visible         = False;
		FormItems.TroubleshootingStartIndicatorGroup.Visible   = False;
		FormItems.TroubleshootingSuccessIndicatorGroup.Visible = True;
	Else // "Question"
		FormItems.TroubleshootingIndicatorGroup.Visible         = False;
		FormItems.TroubleshootingStartIndicatorGroup.Visible   = True;
		FormItems.TroubleshootingSuccessIndicatorGroup.Visible = False;
	EndIf;
	
EndProcedure

&AtServer
Function ResolveIssueInBackground(CheckID)
	
	If TimeConsumingOperation <> Undefined Then
		TimeConsumingOperations.CancelJobExecution(TimeConsumingOperation.JobID);
	EndIf;
	
	SetCurrentPage(ThisObject, "TroubleshootingInProgress");
	
	ExecutionParameters = TimeConsumingOperations.BackgroundExecutionParameters(UUID);
	ExecutionParameters.BackgroundJobDescription = NStr("ru = 'Исправление циклических ссылок'; en = 'Fixing circular references'; pl = 'Fixing circular references';de = 'Fixing circular references';ro = 'Fixing circular references';tr = 'Fixing circular references'; es_ES = 'Fixing circular references'");
	
	Return TimeConsumingOperations.ExecuteInBackground("AccountingAuditInternal.FixInfiniteLoopInBackgroundJob",
		New Structure("CheckID", CheckID), ExecutionParameters);
	
EndFunction

&AtClient
Procedure FixIssueInBackgroundCompletion(Result, AdditionalParameters) Export
	
	TimeConsumingOperation = Undefined;

	If Result = Undefined Then
		SetCurrentPage(ThisObject, "TroubleshootingInProgress");
		Return;
	ElsIf Result.Status = "Error" Then
		SetCurrentPage(ThisObject, "Question");
		Raise Result.BriefErrorPresentation;
	ElsIf Result.Status = "Completed" Then
		SetCurrentPage(ThisObject, "FixedSuccessfully");
	EndIf;
	
EndProcedure

&AtServerNoContext
Procedure RestoreMissingPredefinedItems() 
	
	StandardSubsystemsServer.RestorePredefinedItems();
	
EndProcedure

#EndRegion