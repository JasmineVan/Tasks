///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Internal

// Report form command handler.
//
// Parameters:
//   Form – ManagedForm – Report form.
//   Command - FormCommand - a command that was called.
//
// Usage locations:
//   CommonForm.ReportForm.Attachable_Command().
//
Procedure CreateNewBulkEmailFromReport(Form, Command) Export
	OpenReportMailingFromReportForm(Form);
EndProcedure

// Report form command handler.
//
// Parameters:
//   Form – ManagedForm – Report form.
//   Command - FormCommand - a command that was called.
//
// Usage locations:
//   CommonForm.ReportForm.Attachable_Command().
//
Procedure AttachReportToExistingBulkEmail(Form, Command) Export
	FormParameters = New Structure;
	FormParameters.Insert("ChoiceMode", True);
	FormParameters.Insert("ChoiceFoldersAndItems", FoldersAndItemsUse.Items);
	FormParameters.Insert("MultipleChoice", False);
	
	OpenForm("Catalog.ReportMailings.ChoiceForm", FormParameters, Form);
EndProcedure

// Report form command handler.
//
// Parameters:
//   Form – ManagedForm – Report form.
//   Command - FormCommand - a command that was called.
//
// Usage locations:
//   CommonForm.ReportForm.Attachable_Command().
//
Procedure OpenBulkEmailsWithReport(Form, Command) Export
	
	FormParameters = New Structure;
	FormParameters.Insert("Report", Form.ReportSettings.OptionRef);
	OpenForm("Catalog.ReportMailings.ListForm", FormParameters, Form);
	
EndProcedure

// Report form selection handler.
//
// Parameters:
//   Form – ManagedForm – Report form.
//   SelectedValue - Arbitrary     - a selection result in a subordinate form.
//   ChoiceSource    - ManagedForm - a form where the choice is made.
//   Result - Boolean - True if the selection result is processed.
//
// Usage locations:
//   CommonForm.ReportForm.ChoiceProcessing().
//
Procedure ChoiceProcessingReportForm(Form, SelectedValue, ChoiceSource, Result) Export
	
	If Result = True Then
		Return;
	EndIf;
	
	If TypeOf(SelectedValue) = Type("CatalogRef.ReportMailings") Then
		
		OpenReportMailingFromReportForm(Form, SelectedValue);
		
		Result = True;
		
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

// Generates a mailing recipients list, suggests the user to select a specific recipient or all 
//   recipients of the mailing and returns the result of the user selection.
//   
// Called from the items form.
//
Procedure SelectRecipient(ResultHandler, Object, MultipleChoice, ReturnsMap) Export
	
	If Object.Personal = True Then
		ParametersSet = "Ref, RecipientEmailAddressKind, Personal, Author";
	Else
		ParametersSet = "Ref, RecipientEmailAddressKind, Personal, MailingRecipientType, Recipients";
	EndIf;
	
	RecipientsParameters = New Structure(ParametersSet);
	FillPropertyValues(RecipientsParameters, Object);
	ExecutionResult = ReportMailingServerCall.GenerateMailingRecipientsList(RecipientsParameters);
	
	If ExecutionResult.HadCriticalErrors Then
		QuestionToUserParameters                                      = StandardSubsystemsClient.QuestionToUserParameters();
		QuestionToUserParameters.SuggestDontAskAgain = False;
		QuestionToUserParameters.Picture                             = PictureLib.Warning32;
		StandardSubsystemsClient.ShowQuestionToUser(Undefined, ExecutionResult.More, QuestionDialogMode.OK, QuestionToUserParameters);
		Return;
	EndIf;
	
	Recipients = ExecutionResult.Recipients;
	If Recipients.Count() = 1 Then
		Result = Recipients;
		If Not ReturnsMap Then
			For Each KeyAndValue In Recipients Do
				Result = New Structure("Recipient, MailAddress", KeyAndValue.Key, KeyAndValue.Value);
			EndDo;
		EndIf;
		ExecuteNotifyProcessing(ResultHandler, Result);
		Return;
	EndIf;
	
	PossibleRecipients = New ValueList;
	For Each KeyAndValue In Recipients Do
		PossibleRecipients.Add(KeyAndValue.Key, String(KeyAndValue.Key) +" <"+ KeyAndValue.Value +">");
	EndDo;
	If MultipleChoice Then
		PossibleRecipients.Insert(0, Undefined, NStr("ru = 'Всем получателям'; en = 'To all recipients'; pl = 'To all recipients';de = 'To all recipients';ro = 'To all recipients';tr = 'To all recipients'; es_ES = 'To all recipients'"));
	EndIf;
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("ResultHandler", ResultHandler);
	AdditionalParameters.Insert("Recipients", Recipients);
	AdditionalParameters.Insert("ReturnsMap", ReturnsMap);
	
	Handler = New NotifyDescription("SelectRecipientEnd", ThisObject, AdditionalParameters);
	
	PossibleRecipients.ShowChooseItem(Handler, NStr("ru = 'Выбор получателя'; en = 'Select recipient'; pl = 'Select recipient';de = 'Select recipient';ro = 'Select recipient';tr = 'Select recipient'; es_ES = 'Select recipient'"));
EndProcedure

// SelectRecipient procedure execution result handler.
Procedure SelectRecipientEnd(SelectedItem, AdditionalParameters) Export
	If SelectedItem = Undefined Then
		Result = Undefined;
	Else
		If AdditionalParameters.ReturnsMap Then
			If SelectedItem.Value = Undefined Then
				Result = AdditionalParameters.Recipients;
			Else
				Result = New Map;
				Result.Insert(SelectedItem.Value, AdditionalParameters.Recipients[SelectedItem.Value]);
			EndIf;
		Else
			Result = New Structure("Recipient, MailAddress", SelectedItem.Value, AdditionalParameters.Recipients[SelectedItem.Value]);
		EndIf;
	EndIf;
	
	ExecuteNotifyProcessing(AdditionalParameters.ResultHandler, Result);
EndProcedure

// Executes mailing in the background.
Procedure ExecuteNow(Parameters) Export
	Handler = New NotifyDescription("ExecuteNowInBackground", ThisObject, Parameters);
	If Parameters.IsItemForm Then
		Object = Parameters.Form.Object;
		If Not Object.Prepared Then
			ShowMessageBox(, NStr("ru = 'Рассылка не подготовлена'; en = 'Bulk email is not prepared'; pl = 'Bulk email is not prepared';de = 'Bulk email is not prepared';ro = 'Bulk email is not prepared';tr = 'Bulk email is not prepared'; es_ES = 'Bulk email is not prepared'"));
			Return;
		EndIf;
		If Object.UseEmail Then
			SelectRecipient(Handler, Parameters.Form.Object, True, True);
			Return;
		EndIf;
	EndIf;
	ExecuteNotifyProcessing(Handler, Undefined);
EndProcedure

// Runs background job, it is called when all parameters are ready.
Procedure ExecuteNowInBackground(Recipients, Parameters) Export
	PreliminarySettings = Undefined;
	If Parameters.IsItemForm Then
		If Parameters.Form.Object.UseEmail Then
			If Recipients = Undefined Then
				Return;
			EndIf;
			PreliminarySettings = New Structure("Recipients", Recipients);
		EndIf;
		StateText = NStr("ru = 'Выполняется рассылка отчетов.'; en = 'Sending reports.'; pl = 'Sending reports.';de = 'Sending reports.';ro = 'Sending reports.';tr = 'Sending reports.'; es_ES = 'Sending reports.'");
	Else
		StateText = NStr("ru = 'Выполняются рассылки отчетов.'; en = 'Sending reports.'; pl = 'Sending reports.';de = 'Sending reports.';ro = 'Sending reports.';tr = 'Sending reports.'; es_ES = 'Sending reports.'");
	EndIf;
	
	MethodParameters = New Structure;
	MethodParameters.Insert("MailingArray", Parameters.MailingArray);
	MethodParameters.Insert("PreliminarySettings", PreliminarySettings);
	
	Job = ReportMailingServerCall.RunBackgroundJob(MethodParameters, Parameters.Form.UUID);
	
	WaitSettings = TimeConsumingOperationsClient.IdleParameters(Parameters.Form);
	WaitSettings.OutputIdleWindow = True;
	WaitSettings.MessageText = StateText;
	
	Handler = New NotifyDescription("ExecuteNowInBackgroundEnd", ThisObject, Parameters);
	TimeConsumingOperationsClient.WaitForCompletion(Job, Handler, WaitSettings);
	
EndProcedure

// Accepts the background job result.
Procedure ExecuteNowInBackgroundEnd(Job, Parameters) Export
	
	If Job = Undefined Then
		Return; // Canceled.
	EndIf;
	
	If Job.Status = "Completed" Then
		Result = GetFromTempStorage(Job.ResultAddress);
		MailingNumber = Result.BulkEmails.Count();
		If MailingNumber > 0 Then
			NotifyChanged(?(MailingNumber > 1, Type("CatalogRef.ReportMailings"), Result.BulkEmails[0]));
		EndIf;
		ShowUserNotification(,, Result.Text, PictureLib.ReportMailing, UserNotificationStatus.Information);
		
	Else
		Raise NStr("ru = 'Не удалось выполнить рассылки отчетов:'; en = 'Cannot mail reports:'; pl = 'Cannot mail reports:';de = 'Cannot mail reports:';ro = 'Cannot mail reports:';tr = 'Cannot mail reports:'; es_ES = 'Cannot mail reports:'")
			+ Chars.LF + Job.BriefErrorPresentation;
	EndIf;
	
EndProcedure

// Opens report mailing from the report form.
//
// Parameters:
//   Form – ManagedForm – Report form.
//   Ref - CatalogRef.ReportsMailing - optional. Report mailing reference.
//
Procedure OpenReportMailingFromReportForm(Form, Ref = Undefined)
	ReportSettings = Form.ReportSettings;
	ReportOptionMode = (TypeOf(Form.CurrentVariantKey) = Type("String") AND Not IsBlankString(Form.CurrentVariantKey));
	
	ReportsParametersRow = New Structure("ReportFullName, VariantKey, OptionRef, Settings");
	ReportsParametersRow.ReportFullName = ReportSettings.FullName;
	ReportsParametersRow.VariantKey   = Form.CurrentVariantKey;
	ReportsParametersRow.OptionRef  = ReportSettings.OptionRef;
	If ReportOptionMode Then
		ReportsParametersRow.Settings = Form.Report.SettingsComposer.UserSettings;
	EndIf;
	
	ReportsToAttach = New Array;
	ReportsToAttach.Add(ReportsParametersRow);
	
	FormParameters = New Structure;
	FormParameters.Insert("ReportsToAttach", ReportsToAttach);
	If Ref <> Undefined Then
		FormParameters.Insert("Key", Ref);
	EndIf;
	
	OpenForm("Catalog.ReportMailings.ObjectForm", FormParameters, , String(Form.UUID) + ".OpenReportsMailing");
	
EndProcedure

// Returns set of scheduled job schedules filling templates.
Function ScheduleFillingOptionsList() Export
	
	VariantList = New ValueList;
	VariantList.Add(1, NStr("ru = 'Каждый день'; en = 'Every day'; pl = 'Every day';de = 'Every day';ro = 'Every day';tr = 'Every day'; es_ES = 'Every day'"));
	VariantList.Add(2, NStr("ru = 'Каждый второй день'; en = 'Every second day'; pl = 'Every second day';de = 'Every second day';ro = 'Every second day';tr = 'Every second day'; es_ES = 'Every second day'"));
	VariantList.Add(3, NStr("ru = 'Каждый четвертый день'; en = 'Every fourth day'; pl = 'Every fourth day';de = 'Every fourth day';ro = 'Every fourth day';tr = 'Every fourth day'; es_ES = 'Every fourth day'"));
	VariantList.Add(4, NStr("ru = 'По будням'; en = 'On weekdays'; pl = 'On weekdays';de = 'On weekdays';ro = 'On weekdays';tr = 'On weekdays'; es_ES = 'On weekdays'"));
	VariantList.Add(5, NStr("ru = 'По выходным'; en = 'On weekends'; pl = 'On weekends';de = 'On weekends';ro = 'On weekends';tr = 'On weekends'; es_ES = 'On weekends'"));
	VariantList.Add(6, NStr("ru = 'По понедельникам'; en = 'On Mondays'; pl = 'On Mondays';de = 'On Mondays';ro = 'On Mondays';tr = 'On Mondays'; es_ES = 'On Mondays'"));
	VariantList.Add(7, NStr("ru = 'По пятницам'; en = 'On Fridays'; pl = 'On Fridays';de = 'On Fridays';ro = 'On Fridays';tr = 'On Fridays'; es_ES = 'On Fridays'"));
	VariantList.Add(8, NStr("ru = 'По воскресеньям'; en = 'On Sundays'; pl = 'On Sundays';de = 'On Sundays';ro = 'On Sundays';tr = 'On Sundays'; es_ES = 'On Sundays'"));
	VariantList.Add(9, NStr("ru = 'В первый день месяца'; en = 'On the first day of the month'; pl = 'On the first day of the month';de = 'On the first day of the month';ro = 'On the first day of the month';tr = 'On the first day of the month'; es_ES = 'On the first day of the month'"));
	VariantList.Add(10, NStr("ru = 'В последний день месяца'; en = 'On the last day of the month'; pl = 'On the last day of the month';de = 'On the last day of the month';ro = 'On the last day of the month';tr = 'On the last day of the month'; es_ES = 'On the last day of the month'"));
	VariantList.Add(11, NStr("ru = 'Каждый квартал десятого числа'; en = 'Every quarter on the 10th'; pl = 'Every quarter on the 10th';de = 'Every quarter on the 10th';ro = 'Every quarter on the 10th';tr = 'Every quarter on the 10th'; es_ES = 'Every quarter on the 10th'"));
	VariantList.Add(12, NStr("ru = 'Другое...'; en = 'Other...'; pl = 'Other...';de = 'Other...';ro = 'Other...';tr = 'Other...'; es_ES = 'Other...'"));
	
	Return VariantList;
EndFunction

// Parses the FTP address string into the Username, Password, Port and Directory.
//   Detailed - see RFC 1738 (http://tools.ietf.org/html/rfc1738#section-3.1). 
//   Template: ftp://<user>:<password>@<host>:<port>/<url-path>.
//   Fragments <user>:<password>@, :<password>, :<port> and /<url-path> can be absent.
//
// Parameters:
//   FTPAddress - String - a full path to the ftp resource.
//
// Returns:
//   Result - Structure - a result of parsing the full path.
//       * Username - String - ftp user name.
//       * Password - String - ftp user password.
//       * Server - String - a server name.
//       * Port - Number - server port. 21 by default.
//       * Directory - String - path to the directory at the server. The first character is always /.
//
Function ParseFTPAddress(FullFTPAddress) Export
	
	Result = New Structure;
	Result.Insert("Username", "");
	Result.Insert("Password", "");
	Result.Insert("Server", "");
	Result.Insert("Port", 21);
	Result.Insert("Directory", "/");
	
	FTPAddress = FullFTPAddress;
	
	// Cut ftp://.
	Pos = StrFind(FTPAddress, "://");
	If Pos > 0 Then
		FTPAddress = Mid(FTPAddress, Pos + 3);
	EndIf;
	
	// Directory.
	Pos = StrFind(FTPAddress, "/");
	If Pos > 0 Then
		Result.Directory = Mid(FTPAddress, Pos);
		FTPAddress = Left(FTPAddress, Pos - 1);
	EndIf;
	
	// Username and password.
	Pos = StrFind(FTPAddress, "@");
	If Pos > 0 Then
		UsernamePassword = Left(FTPAddress, Pos - 1);
		FTPAddress = Mid(FTPAddress, Pos + 1);
		
		Pos = StrFind(UsernamePassword, ":");
		If Pos > 0 Then
			Result.Username = Left(UsernamePassword, Pos - 1);
			Result.Password = Mid(UsernamePassword, Pos + 1);
		Else
			Result.Username = UsernamePassword;
		EndIf;
	EndIf;
	
	// Server and port.
	Pos = StrFind(FTPAddress, ":");
	If Pos > 0 Then
		
		Result.Server = Left(FTPAddress, Pos - 1);
		
		NumberType = New TypeDescription("Number");
		Port     = NumberType.AdjustValue(Mid(FTPAddress, Pos + 1));
		Result.Port = ?(Port > 0, Port, Result.Port);
		
	Else
		
		Result.Server = FTPAddress;
		
	EndIf;
	
	Return Result;
	
EndFunction

#EndRegion
