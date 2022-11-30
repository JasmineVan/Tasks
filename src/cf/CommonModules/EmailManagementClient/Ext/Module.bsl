///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Private

// Opens an email attachment.
//
// Parameters:
//  Ref - CatalogRef.IncomingEmailAttachedFiles,
//            CatalogRef.IncomingEmailAttachedFiles - a reference to file that is to be opened.
//                                                                            
//
Procedure OpenAttachment(Ref, Form, ForEditing = False) Export

	FileData = FilesOperationsClient.FileData(Ref, Form.UUID);
	
	If Form.RestrictedExtensions.FindByValue(FileData.Extension) <> Undefined Then
		
		AdditionalParameters = New Structure("FileData", FileData);
		AdditionalParameters.Insert("ForEditing", ForEditing);
		
		Notification = New NotifyDescription("OpenFileAfterConfirm", ThisObject, AdditionalParameters);
		FormParameters = New Structure;
		FormParameters.Insert("Key", "BeforeOpenFile");
		FormParameters.Insert("FileName", FileData.FileName);
		OpenForm("CommonForm.SecurityWarning", FormParameters, , , , , Notification);
		Return;
		
	EndIf;
	
	FilesOperationsClient.OpenFile(FileData, ForEditing);
	
EndProcedure

Procedure OpenFileAfterConfirm(Result, AdditionalParameters) Export
	
	If Result <> Undefined AND Result = "Continue" Then
		FilesOperationsClient.OpenFile(AdditionalParameters.FileData, AdditionalParameters.ForEditing);
	EndIf;
	
EndProcedure

// Returns an array that contains structures with information about interaction contacts or 
// interaction subject participants.
// Parameters:
//  ContactsTable - Document.TabularSection - contains descriptions and references to interaction 
//                                               contacts or interaction subject participants.
//
Function ContactsTableToArray(ContactsTable) Export
	
	Result = New Array;
	For Each TableRow In ContactsTable Do
		Contact = ?(TypeOf(TableRow.Contact) = Type("String"), Undefined, TableRow.Contact);
		Record = New Structure(
		"Address, Presentation, Contact", TableRow.Address, TableRow.Presentation, Contact);
		Result.Add(Record);
	EndDo;
	
	Return Result;
	
EndFunction

// Get email by all available accounts.
// Parameters:
//  ItemList    - FormTable - a form item that has to be updated after getting emails.
//
Procedure SendReceiveUserEmail(UUID, Form, ItemList = Undefined) Export

	TimeConsumingOperation =  InteractionsServerCall.SendReceiveUserEmailInBackground(UUID);
	If TimeConsumingOperation = Undefined Then
		Return;
	EndIf;
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("ItemList", ItemList);
	
	If TimeConsumingOperation.Status = "Completed" Then
		SendImportUserEmailCompletion(TimeConsumingOperation, AdditionalParameters);
	ElsIf TimeConsumingOperation.Status = "Running" Then
		IdleParameters = TimeConsumingOperationsClient.IdleParameters(Form);
		CompletionNotification = New NotifyDescription("SendImportUserEmailCompletion", ThisObject, AdditionalParameters);
		TimeConsumingOperationsClient.WaitForCompletion(TimeConsumingOperation, CompletionNotification, IdleParameters);
	EndIf;
	
EndProcedure

Procedure SendImportUserEmailCompletion(Result, AdditionalParameters) Export
	
	If Result = Undefined Then
		Return;
	ElsIf Result.Status = "Error" Then
		Raise Result.BriefErrorPresentation;
	ElsIf Result.Status = "Completed" Then
		
		ExecutionResult = InteractionsServerCall.UserEmailSendingReceivingResult(Result.ResultAddress);
		If ExecutionResult = Undefined Then
			Return;
		EndIf;
		
		If AdditionalParameters.Property("ItemList")
			AND AdditionalParameters.ItemList <> Undefined Then
			AdditionalParameters.ItemList.Refresh();
		EndIf;
		
		MessageText = ResultPresentationOfSendingReceivingUserEmails(ExecutionResult);
		ShowUserNotification(MessageText);
	
		If ExecutionResult.HasErrors Then
	
			CommonClient.MessageToUser(
				NStr("ru = 'При получении почты были ошибки. Подробности см. в журнале регистрации'; en = 'Errors occurred while receiving the mail. For more information, see the event log.'; pl = 'Errors occurred while receiving the mail. For more information, see the event log.';de = 'Errors occurred while receiving the mail. For more information, see the event log.';ro = 'Errors occurred while receiving the mail. For more information, see the event log.';tr = 'Errors occurred while receiving the mail. For more information, see the event log.'; es_ES = 'Errors occurred while receiving the mail. For more information, see the event log.'"));
	
		EndIf;
		
		Notify("SendAndReceiveEmailDone");
	EndIf;
	
EndProcedure

Function ResultPresentationOfSendingReceivingUserEmails(ExecutionResult)
	
	MessageText = StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = 'Загружено писем: %1'; en = 'Emails imported: %1'; pl = 'Emails imported: %1';de = 'Emails imported: %1';ro = 'Emails imported: %1';tr = 'Emails imported: %1'; es_ES = 'Emails imported: %1'"), ExecutionResult.EmailsReceived);
	If ExecutionResult.UserAccountsAvailable > 1 Then
		MessageText = MessageText + " " + StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = '(учетных записей: %1)'; en = '(accounts: %1)'; pl = '(accounts: %1)';de = '(accounts: %1)';ro = '(accounts: %1)';tr = '(accounts: %1)'; es_ES = '(accounts: %1)'"),
		                                                                                                ExecutionResult.UserAccountsAvailable);
	EndIf;
	
	Return MessageText;
	
EndFunction

#EndRegion
