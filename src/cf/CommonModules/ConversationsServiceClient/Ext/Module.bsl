///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Internal

Function Connected() Export
	
	Return ConversationsServiceServerCall.Connected();
	
EndFunction

Procedure ShowConnection(CompletionDetails = Undefined) Export
	
	OpenForm("DataProcessor.EnableDiscussions.Form",,,,,, CompletionDetails);
	
EndProcedure

Procedure ShowDisconnection() Export
	
	If Not ConversationsServiceServerCall.Connected() Then 
		ShowMessageBox(, NStr("ru = 'Подключение обсуждений не выполнено.'; en = 'Discussions are not enabled.'; pl = 'Discussions are not enabled.';de = 'Discussions are not enabled.';ro = 'Discussions are not enabled.';tr = 'Discussions are not enabled.'; es_ES = 'Discussions are not enabled.'"));
		Return;
	EndIf;
	
	Buttons = New ValueList;
	Buttons.Add("Disable", NStr("ru = 'Отключить'; en = 'Disable'; pl = 'Disable';de = 'Disable';ro = 'Disable';tr = 'Disable'; es_ES = 'Disable'"));
	Buttons.Add(DialogReturnCode.No);
	
	Notification = New NotifyDescription("AfterResponseToDisablePrompt", ThisObject);
	
	ShowQueryBox(Notification, NStr("ru = 'Отключить обсуждения?'; en = 'Disable discussions?'; pl = 'Disable discussions?';de = 'Disable discussions?';ro = 'Disable discussions?';tr = 'Disable discussions?'; es_ES = 'Disable discussions?'"),
		Buttons,, DialogReturnCode.No);
	
EndProcedure

Procedure AfterWriteUser(Form, CompletionDetails) Export
	
	If Not Form.SuggestDiscussions Then
		ExecuteNotifyProcessing(CompletionDetails);
		Return;
	EndIf;
	
	Form.SuggestDiscussions = False;
		
	CompletionNotification = New NotifyDescription("SuggestDiscussionsCompletion", ThisObject, CompletionDetails);
	QuestionParameters = StandardSubsystemsClient.QuestionToUserParameters();
	QuestionParameters.SuggestDontAskAgain = True;
	QuestionParameters.Title = NStr("ru = 'Обсуждения (система взаимодействий)'; en = 'Discussions (interaction system)'; pl = 'Discussions (interaction system)';de = 'Discussions (interaction system)';ro = 'Discussions (interaction system)';tr = 'Discussions (interaction system)'; es_ES = 'Discussions (interaction system)'");
	StandardSubsystemsClient.ShowQuestionToUser(CompletionNotification, Form.SuggestConversationsText,
		QuestionDialogMode.YesNo, QuestionParameters);
	
EndProcedure

#EndRegion

#Region Private

Procedure AfterResponseToDisablePrompt(ReturnCode, Context) Export
	
	If ReturnCode = "Disable" Then 
		OnDisconnect();
	EndIf;
	
EndProcedure

Procedure OnDisconnect()
	
	Notification = New NotifyDescription("AfterDisconnectSuccessfully", ThisObject,,
		"OnProcessDisableDiscussionError", ThisObject);
	CollaborationSystem.BeginInfoBaseUnregistration(Notification);
	
EndProcedure

Procedure AfterDisconnectSuccessfully(Context) Export
	
	Notify("ConversationsEnabled", False);
	
EndProcedure

Procedure OnProcessDisableDiscussionError(ErrorInformation, StandardProcessing, Context) Export 
	
	StandardProcessing = False;
	ShowErrorInfo(ErrorInformation);
	
EndProcedure

Procedure SuggestDiscussionsCompletion(Result, CompletionDetails) Export
	
	If Result = Undefined Then
		ExecuteNotifyProcessing(CompletionDetails);
		Return;
	EndIf;
	
	If Result.DoNotAskAgain Then
		CommonServerCall.CommonSettingsStorageSave("ApplicationSettings", "SuggestDiscussions", False);
	EndIf;
	
	If Result.Value = DialogReturnCode.Yes Then
		ShowConnection();
		Return;
	EndIf;
	ExecuteNotifyProcessing(CompletionDetails);
	
EndProcedure

#EndRegion