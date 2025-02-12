﻿///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region EventHandlers

&AtServer
Procedure OnReadAtServer(CurrentObject)
	Rereading = (Cache <> Undefined);
	
	// Read value storage 
	If CurrentObject.HTMLFormatEmail Then
		EmailAttachmentsStructureInHTMLFormat = CurrentObject.EmailPicturesInHTMLFormat.Get();
		If EmailAttachmentsStructureInHTMLFormat = Undefined Then
			EmailAttachmentsStructureInHTMLFormat = New Structure;
		EndIf;
		EmailTextFormattedDocument.SetHTML(CurrentObject.EmailTextInHTMLFormat, EmailAttachmentsStructureInHTMLFormat);
	EndIf;
	
	// Refill form data to be clear on rereading object from DB.
	If Rereading Then
		FillReportTableInfo();
		ReadJobSchedule();
	EndIf;
	
	For Each Row In Object.Reports Do
		Row.DoNotSendIfEmpty = Not Row.SendIfEmpty;
	EndDo;
	
	// StandardSubsystems.AccessManagement
	If Common.SubsystemExists("StandardSubsystems.AccessManagement") Then
		ModuleAccessManagement = Common.CommonModule("AccessManagement");
		ModuleAccessManagement.OnReadAtServer(ThisObject, CurrentObject);
	EndIf;
	// End StandardSubsystems.AccessManagement

EndProcedure

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	SetConditionalAppearance();
	
	ErrorTextOnOpen = ReportMailing.CheckAddRightErrorText();
	If ValueIsFilled(ErrorTextOnOpen) Then
		Return;
	EndIf;
	
	If Object.DeletionMark Then
		ThisObject.ReadOnly = True;
	EndIf;
	
	// Deleting the "To folder" option if the FilesOperations subsystem is not available.
	If TypeOf(Object.Folder) = Type("Undefined") Or TypeOf(Object.Folder) = Type("String") Then
		Items.OtherDeliveryMethod.ChoiceList.Delete(0);
	EndIf;
	
	// Delete the To network directory option if the operation mode in SaaS mode.
	If Common.DataSeparationEnabled() Then
		TransportMethodNetworkDirectory = Items.OtherDeliveryMethod.ChoiceList.FindByValue("UseNetworkDirectory");
		Items.OtherDeliveryMethod.ChoiceList.Delete(TransportMethodNetworkDirectory);
	EndIf;
	
	If Not AccessRight("EventLog", Metadata) Then
		Items.MailingEventsCommand.Visible = False;
		Items.MailingEvents.Visible = False;
	EndIf;
	
	MailingBasis = Parameters.CopyingValue;
	
	// Used on import and write selected report settings.
	CurrentRowIDOfReportsTable = -1;
	
	// Check cache
	IsNew = Object.Ref.IsEmpty();
	CreatedByCopying = Not MailingBasis.IsEmpty();
	
	// Add reports to tabular section.
	If Parameters.Property("ReportsToAttach") AND TypeOf(Parameters.ReportsToAttach) = Type("Array") Then
		Modified = True;
		AddReportsSettings(Parameters.ReportsToAttach);
	EndIf;
	
	Cache = GetCache();
	
	Schedule = New JobSchedule;
	
	MailingWasPersonalized = Object.Personalized;
	
	// Read
	FillReportTableInfo();
	FillEmptyTemplatesWithStandard(Object);
	
	If IsNew AND Not CreatedByCopying Then
		ScheduleOption = Undefined;
		Parameters.Property("ScheduleOption", ScheduleOption);
		FillScheduleByOption(ScheduleOption);
	Else
		ReadJobSchedule();
	EndIf;
	
	// Fill in the mailing author
	If IsNew Then
		// Bulk email author
		CurrentUser = Users.CurrentUser();
		Object.Author = CurrentUser;
		If Not ValueIsFilled(Object.Author) Then
			Cancel = True;
			
			LogParameters = New Structure;
			LogParameters.Insert("EventName", NStr("ru = 'Рассылка отчетов. Открытие формы элемента'; en = 'Report bulk email. Open item form'; pl = 'Report bulk email. Open item form';de = 'Report bulk email. Open item form';ro = 'Report bulk email. Open item form';tr = 'Report bulk email. Open item form'; es_ES = 'Report bulk email. Open item form'", Common.DefaultLanguageCode()));
			LogParameters.Insert("Data", Undefined);
			LogParameters.Insert("Metadata", Metadata.Catalogs.ReportMailings);
			
			Text = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'Ошибка заполнения автора рассылки:
				|Пользователь ""%1"" (%2) не может быть автором.'; 
				|en = 'An error occurred when filling out the bulk email author:
				|User ""%1"" (%2) cannot be an author.'; 
				|pl = 'An error occurred when filling out the bulk email author:
				|User ""%1"" (%2) cannot be an author.';
				|de = 'An error occurred when filling out the bulk email author:
				|User ""%1"" (%2) cannot be an author.';
				|ro = 'An error occurred when filling out the bulk email author:
				|User ""%1"" (%2) cannot be an author.';
				|tr = 'An error occurred when filling out the bulk email author:
				|User ""%1"" (%2) cannot be an author.'; 
				|es_ES = 'An error occurred when filling out the bulk email author:
				|User ""%1"" (%2) cannot be an author.'"),
				String(CurrentUser),
				String(TypeOf(CurrentUser)));
			
			ReportMailing.LogRecord(LogParameters, EventLogLevel.Error, Text);
			
			Return;
		EndIf;
		
		// Asterisks for passwords to be copied from a basis.
		If CreatedByCopying Then
			BasisAuthor = Common.ObjectAttributeValue(MailingBasis, "Author");
			If BasisAuthor = CurrentUser Then
				SetPrivilegedMode(True);
				Passwords = Common.ReadDataFromSecureStorage(MailingBasis, "ArchivePassword, FTPPassword");
				SetPrivilegedMode(False);
				If ValueIsFilled(Passwords.ArchivePassword) Then
					ArchivePassword = PasswordHidden();
					ArchivePasswordChanged = True; // See this parameter processing in the OnWriteAtServer.
				EndIf;
				If ValueIsFilled(Passwords.FTPPassword) Then
					FTPPassword = PasswordHidden();
					FTPPasswordChanged = True; // See this parameter processing in the OnWriteAtServer.
				EndIf;
			EndIf;
		EndIf;
		
		// Reset parameters that cannot be copied to defaults.
		If Not ArchivePasswordChanged Then
			Object.ArchiveName = Cache.Templates.ArchiveName;
		EndIf;
		If Not FTPPasswordChanged Then
			Object.FTPUsername = "";
			Object.FTPServer = "";
			Object.FTPPort = 21;
			Object.FTPDirectory = "";
		EndIf;
	Else
		SetPrivilegedMode(True);
		Passwords = Common.ReadDataFromSecureStorage(Object.Ref, "ArchivePassword, FTPPassword");
		SetPrivilegedMode(False);
		ArchivePassword = ?(ValueIsFilled(Passwords.ArchivePassword), PasswordHidden(), "");
		FTPPassword = ?(ValueIsFilled(Passwords.FTPPassword), PasswordHidden(), "");
	EndIf;
	Passwords = Undefined;
	
	// Allows you to see and control some protected mailing parameters.
	MailingBeingEditedByAuthor = (Object.Author = Users.CurrentUser());
	
	// Add additional report button availability.
	Items.ReportsAddAdditionalReport.Enabled = ?(Cache.EmptyReportValue = Undefined, True, False);
	// WithCache.EmptyReportValue = Undefined when the type of the report attribute is composite, the 
	//   integration with the Additional reports and data processors subsystem is used, respectively.
	
	// Mailing author availability.
	Items.Author.Enabled = Users.IsFullUser();
	
	// List of formats with marks for default formats.
	DefaultFormatsList = ReportMailing.FormatsList();
	
	// Default formats list presentation.
	DefaultFormatsListPresentation = "";
	For Each ListItem In DefaultFormatsList Do
		If ListItem.Check Then
			DefaultFormatsListPresentation = DefaultFormatsListPresentation + ?(DefaultFormatsListPresentation = "", "", ", ") + String(ListItem.Value);
		EndIf;
	EndDo;
	
	// Formats Edit List.
	FormatsList = DefaultFormatsList.Copy();
	
	// Default formats list presentation within the mailing.
	DefaultFormats = "";
	FoundItems = Object.ReportFormats.FindRows(New Structure("Report", Cache.EmptyReportValue));
	If FoundItems.Count() = 0 Then
		DefaultFormats = DefaultFormatsListPresentation;
	Else
		For Each StringFormat In FoundItems Do
			DefaultFormats = DefaultFormats + ?(DefaultFormats = "", "", ", ") + String(StringFormat.Format);
		EndDo;
	EndIf;
	
	// Attachments.
	If EmailAttachmentsStructureInHTMLFormat = Undefined Then
		EmailAttachmentsStructureInHTMLFormat = New Structure;
	EndIf;
	
	// For the recipients and exclusion lists one tabular section is used.
	Items.EmptySettings.RowFilter = New FixedStructure("PictureIndex", 200);
	
	// Selection list of author postal addresses.
	RecipientMailAddresses(Object.Author, Items.AuthorMailAddressKind.ChoiceList);
	
	// Selection list of author postal addresses.
	ConnectEmailSettingsCache();
	
	// Read object settings from object to be copied.
	If CreatedByCopying Then
		ReadObjectSettingsOfObjectToCopy();
	EndIf;
	
	// Activate the first row
	If Object.Reports.Count() > 0 AND CurrentRowIDOfReportsTable = -1 Then
		ReportsRow = Object.Reports[0];
		RowID = ReportsRow.GetID();
		ErrorText = ReportsOnActivateRowAtServer(RowID);
		If ErrorText <> "" Then
			Common.MessageToUser(ErrorText, , "Object.Reports[0].Presentation");
		EndIf;
	EndIf;
	
	VisibilityAvailabilityCorrectness(ThisObject);
	
	FixAttributesValuesBeforeChange();
	
	StandardSubsystemsServer.SetGroupTitleRepresentation(ThisObject);
	For Each Row In Object.Reports Do
		Row.DoNotSendIfEmpty = Not Row.SendIfEmpty;
	EndDo;
	
	If Common.IsMobileClient() Then
		Items.CommandWriteAndClose.Representation = ButtonRepresentation.Picture;
		Items.OtherDeliveryMethods.Group = ChildFormItemsGroup.HorizontalIfPossible;
		Items.UseNetworkDirectory.Group = ChildFormItemsGroup.HorizontalIfPossible;
		Items.UseDirectory.Group = ChildFormItemsGroup.HorizontalIfPossible;
		
		Items.EditSchedule.Enabled = False;
		
		Items.EmailSubjectContextMenuTemplatePreview.Enabled = False;
		Items.EmailTextFormattedDocumentTemplatePreview.Enabled = False;
		Items.EmailTextFormattedDocumentContextMenuTemplatePreview.Enabled = False;
		Items.TemplatePreview.Enabled = False;
		Items.EmailTextContextMenuTemplatePreview.Enabled = False;
	EndIf;
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	If FormWasModifiedAtServer Then
		Modified = True;
	EndIf;
	If ValueIsFilled(ErrorTextOnOpen) Then
		Cancel = True;
		ShowMessageBox(, ErrorTextOnOpen);
		Return;
	EndIf;
	If ValueIsFilled(PopupAlertTextOnOpen) Then
		ShowUserNotification(PopupAlertTextOnOpen, , , PictureLib.ExecuteTask)
	EndIf;
EndProcedure

&AtServer
Procedure FillCheckProcessingAtServer(Cancel, CheckedAttributes)
	// Check data that is output through the attributes of the form itself.
	If Not ValueIsFilled(Object.Description) Then
		Cancel = True;
		MessageText = NStr("ru = 'Не введено наименование'; en = 'Name is not entered'; pl = 'Name is not entered';de = 'Name is not entered';ro = 'Name is not entered';tr = 'Name is not entered'; es_ES = 'Name is not entered'");
		Common.MessageToUser(MessageText, , "Object.Description");
	EndIf;
	If Object.UseEmail AND Not Object.Personal Then
		If Not ValueIsFilled(MailingRecipientType) Then
			Cancel = True;
			MessageText = NStr("ru = 'Не выбран тип получателей'; en = 'Recipient type is not selected'; pl = 'Recipient type is not selected';de = 'Recipient type is not selected';ro = 'Recipient type is not selected';tr = 'Recipient type is not selected'; es_ES = 'Recipient type is not selected'");
			Common.MessageToUser(MessageText, , "MailingRecipientType");
		EndIf;
	EndIf;
	
	If Object.Prepared Then
		If Object.Reports.Count() = 0 Then
			Cancel = True;
			MessageText = NStr("ru = 'Не выбрано ни одного отчета'; en = 'No report is selected'; pl = 'No report is selected';de = 'No report is selected';ro = 'No report is selected';tr = 'No report is selected'; es_ES = 'No report is selected'");
			Common.MessageToUser(MessageText, , "Object.Reports");
		EndIf;
		
		If Not ValueIsFilled(Object.SchedulePeriodicity) Then
			Cancel = True;
			MessageText = NStr("ru = 'Не выбрана периодичность запуска'; en = 'Launch frequency is not selected'; pl = 'Launch frequency is not selected';de = 'Launch frequency is not selected';ro = 'Launch frequency is not selected';tr = 'Launch frequency is not selected'; es_ES = 'Launch frequency is not selected'");
			Common.MessageToUser(MessageText, , "Object.SchedulePeriodicity");
		EndIf;
		
		If Object.UseFTPResource Then
			If Not ValueIsFilled(Object.FTPServer)
				Or Not ValueIsFilled(Object.FTPPort)
				Or Not ValueIsFilled(Object.FTPDirectory) Then
				Cancel = True;
				MessageText = NStr("ru = 'Не введен FTP адрес'; en = 'FTP address is not entered'; pl = 'FTP address is not entered';de = 'FTP address is not entered';ro = 'FTP address is not entered';tr = 'FTP address is not entered'; es_ES = 'FTP address is not entered'");
				Common.MessageToUser(MessageText, , "FTPServerAndDirectory");
			EndIf;
		EndIf;
		
		If Object.UseNetworkDirectory Then
			If Not ValueIsFilled(Object.NetworkDirectoryWindows) Then
				Cancel = True;
				MessageText = NStr("ru = 'Не введен сетевой каталог Windows'; en = 'Network directory Windows is not entered'; pl = 'Network directory Windows is not entered';de = 'Network directory Windows is not entered';ro = 'Network directory Windows is not entered';tr = 'Network directory Windows is not entered'; es_ES = 'Network directory Windows is not entered'");
				Common.MessageToUser(MessageText, , "Object.NetworkDirectoryWindows");
			EndIf;
			If Not ValueIsFilled(Object.NetworkDirectoryLinux) Then
				Cancel = True;
				MessageText = NStr("ru = 'Не введен сетевой каталог Linux'; en = 'Network directory Linux is not entered'; pl = 'Network directory Linux is not entered';de = 'Network directory Linux is not entered';ro = 'Network directory Linux is not entered';tr = 'Network directory Linux is not entered'; es_ES = 'Network directory Linux is not entered'");
				Common.MessageToUser(MessageText, , "Object.NetworkDirectoryLinux");
			EndIf;
		EndIf;
		
		If Object.UseDirectory Then
			If Not ValueIsFilled(Object.Folder) Then
				Cancel = True;
				MessageText = NStr("ru = 'Не выбрана папка'; en = 'Folder is not selected'; pl = 'Folder is not selected';de = 'Folder is not selected';ro = 'Folder is not selected';tr = 'Folder is not selected'; es_ES = 'Folder is not selected'");
				Common.MessageToUser(MessageText, , "Object.Folder");
			EndIf;
		EndIf;
		
		If Object.UseEmail Then
			If Object.Personal Then
				If Not ValueIsFilled(Object.RecipientEmailAddressKind) Then
					Cancel = True;
					MessageText = NStr("ru = 'Не выбран почтовый адрес'; en = 'Email is not selected'; pl = 'Email is not selected';de = 'Email is not selected';ro = 'Email is not selected';tr = 'Email is not selected'; es_ES = 'Email is not selected'");
					Common.MessageToUser(MessageText, , "Object.RecipientEmailAddressKind");
				EndIf;
			Else
				If Not RecipientsSpecified(Object.Recipients) Then
					Cancel = True;
				EndIf;
				If Not ValueIsFilled(Object.RecipientEmailAddressKind) Then
					Cancel = True;
					MessageText = NStr("ru = 'Не выбран тип почтового адреса получателей'; en = 'Recipient email type is not selected'; pl = 'Recipient email type is not selected';de = 'Recipient email type is not selected';ro = 'Recipient email type is not selected';tr = 'Recipient email type is not selected'; es_ES = 'Recipient email type is not selected'");
					Common.MessageToUser(MessageText, , "BulkEmailRecipients");
				EndIf;
			EndIf;
			If Not ValueIsFilled(Object.Account) Then
				Cancel = True;
				MessageText = NStr("ru = 'Не выбрана учетная запись для отправки'; en = 'Account for sending is not selected'; pl = 'Account for sending is not selected';de = 'Account for sending is not selected';ro = 'Account for sending is not selected';tr = 'Account for sending is not selected'; es_ES = 'Account for sending is not selected'");
				Common.MessageToUser(MessageText, , "Object.Account");
			EndIf;
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure BeforeWrite(Cancel, WriteParameters)
	If WriteParameters = Undefined Then
		WriteParameters = New Structure;
	EndIf;
	If Not WriteParameters.Property("Step") Then
		Cancel = True;
		WriteAtClient(Undefined, WriteParameters);
	EndIf;
EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	// Write current row settings.
	If CurrentRowIDOfReportsTable <> -1 Then
		WriteReportsRowSettings(CurrentRowIDOfReportsTable);
	EndIf;
	
	// Next, the following actions are performed:
	// [1] Save user settings.
	//     Store the changed rows settings to the settings of the object to be written (a value storage).
	//     Analysis is performed for all reports if the user has changed the settings.
	// [2] Search blank but required settings.
	//     Analysis is performed for DCS reports if data to mail is prepared.
	CheckRequired = Object.Prepared;
	// [3] Search personalized fields if this mailing is not personalized.
	//     Analysis is performed for all reports if the user has changed the mailing kind from 
	//     personalized to any other.
	MailingIsNotPersonalized = (Not Object.Personalized AND MailingWasPersonalized);
	For Each ReportsRow In Object.Reports Do
		
		ReportsRowObject = CurrentObject.Reports.Get(ReportsRow.LineNumber-1);
		
		If ReportsRow.ChangesMade Then
			// [1], [2] and [3] Read uninitialized settings.
			UserSettings = GetFromTempStorage(ReportsRow.SettingsAddress);
			
			// [1] Write settings.
			ReportsRowObject.Settings = New ValueStorage(UserSettings, New Deflation(9));
			
			If Not CheckRequired AND Not MailingIsNotPersonalized Then
				Continue;
			EndIf;
			
		Else
			
			If Not CheckRequired AND Not MailingIsNotPersonalized Then
				Continue;
			EndIf;
			
			// [2] and [3] Read uninitialized settings.
			If IsTempStorageURL(ReportsRow.SettingsAddress) Then
				UserSettings = GetFromTempStorage(ReportsRow.SettingsAddress);
			Else
				UserSettings = ReportsRowObject.Settings.Get();
			EndIf;
			
		EndIf;
		
		// [2] and [3] Initialize settings.
		ReportParameters = InitializeReport(ReportsRow, True, UserSettings, False);
		ReportSettings = ?(ReportsRow.DCS, ReportParameters.DCSettingsComposer, UserSettings);
		ReportPersonalized = False;
		
		// [2] and [3] DCS reports analysis.
		If ReportsRow.DCS Then
			DCSettings = ReportSettings.Settings;
			DCUserSettings = ReportSettings.UserSettings;
			// [3] Check settings values.
			Filter = New Structure("Use, Value", True, "[Recipient]");
			FoundItems = ReportsClientServer.FindSettings(DCUserSettings.Items, Filter);
			If FoundItems.Count() > 0 Then
				ReportPersonalized = True;
			EndIf;
			// [2] Search and check the available setting.
			AllRequiredSettingsFilled = True;
			For Each UserSetting In DCUserSettings.Items Do
				If TypeOf(UserSetting) = Type("DataCompositionSettingsParameterValue") Then
					ID = UserSetting.UserSettingID;
					CommonSetting = ReportsClientServer.GetObjectByUserID(DCSettings, ID);
					If CommonSetting = Undefined Then 
						Continue;
					EndIf;
					AvailableSetting = ReportsClientServer.FindAvailableSetting(DCSettings, CommonSetting);
					If AvailableSetting = Undefined Then
						Continue;
					EndIf;
					If Not AvailableSetting.Use = DataCompositionParameterUse.Always
						AND Not UserSetting.Use Then
						Continue;
					EndIf;
					If AvailableSetting.DenyIncompleteValues AND Not ValueIsFilled(UserSetting.Value) Then
						AllRequiredSettingsFilled = False;
					EndIf;
				EndIf;
			EndDo;
			
			// [2] Error output.
			If Not AllRequiredSettingsFilled Then
				Cancel = True;
				MessageText = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("ru = 'Для отчета ''%1'' заполнены не все настройки, обязательные для заполнения. Необходимо заполнить все обязательные настройки или снять флажок ''Подготовлена''.'; en = 'Not all required settings are filled in for report ''%1''. Fill in all required settings or clear check box ''Prepared''.'; pl = 'Not all required settings are filled in for report ''%1''. Fill in all required settings or clear check box ''Prepared''.';de = 'Not all required settings are filled in for report ''%1''. Fill in all required settings or clear check box ''Prepared''.';ro = 'Not all required settings are filled in for report ''%1''. Fill in all required settings or clear check box ''Prepared''.';tr = 'Not all required settings are filled in for report ''%1''. Fill in all required settings or clear check box ''Prepared''.'; es_ES = 'Not all required settings are filled in for report ''%1''. Fill in all required settings or clear check box ''Prepared''.'"),
					String(ReportsRow.Report));
				Field = "Reports["+ Format(CurrentObject.Reports.IndexOf(ReportsRowObject), "NZ=0; NG=0") +"].Presentation";
				Common.MessageToUser(MessageText, CurrentObject, Field);
			EndIf;
		EndIf; // ReportsRow.DCS
		
		// [3] Ordinary report analysis.
		If TypeOf(ReportSettings) = Type("ValueTable") Then
			FoundItems = ReportSettings.FindRows(New Structure("Value, Use", "[Recipient]", True));
			If FoundItems.Count() > 0 Then
				ReportPersonalized = True;
			EndIf;
		EndIf;
		If MailingIsNotPersonalized AND ReportPersonalized Then
			Cancel = True;
			MessageText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'В настройках отчета ''%1'' задан отбор по получателю рассылки. Необходимо отключить этот отбор или изменить вид рассылки на ''Свой отчет для каждого получателя''.'; en = 'Filtering by mailing recipient is set in the ""%1"" report settings."
"Remove this filter or change the mailing kind to ""Unique report for each recipient"".'; pl = 'Filtering by mailing recipient is set in the ""%1"" report settings."
"Remove this filter or change the mailing kind to ""Unique report for each recipient"".';de = 'Filtering by mailing recipient is set in the ""%1"" report settings."
"Remove this filter or change the mailing kind to ""Unique report for each recipient"".';ro = 'Filtering by mailing recipient is set in the ""%1"" report settings."
"Remove this filter or change the mailing kind to ""Unique report for each recipient"".';tr = 'Filtering by mailing recipient is set in the ""%1"" report settings."
"Remove this filter or change the mailing kind to ""Unique report for each recipient"".'; es_ES = 'Filtering by mailing recipient is set in the ""%1"" report settings."
"Remove this filter or change the mailing kind to ""Unique report for each recipient"".'"),
				String(ReportsRow.Report));
			Field = "Reports["+ Format(CurrentObject.Reports.IndexOf(ReportsRowObject), "NZ=0; NG=0") +"].Presentation";
			Common.MessageToUser(MessageText, CurrentObject, Field);
		EndIf;
		
		If Object.Personalized AND	NOT ReportPersonalized Then
			Cancel = True;
			MessageText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'В настройках отчета ""%1"" не указан отбор по получателю рассылки.'; en = 'Filter by bulk email recipient is not specified in the ""%1"" report settings.'; pl = 'Filter by bulk email recipient is not specified in the ""%1"" report settings.';de = 'Filter by bulk email recipient is not specified in the ""%1"" report settings.';ro = 'Filter by bulk email recipient is not specified in the ""%1"" report settings.';tr = 'Filter by bulk email recipient is not specified in the ""%1"" report settings.'; es_ES = 'Filter by bulk email recipient is not specified in the ""%1"" report settings.'"),
				String(ReportsRow.Report));
			Field = "Reports["+ Format(CurrentObject.Reports.IndexOf(ReportsRowObject), "NZ=0; NG=0") +"].Presentation";
			Common.MessageToUser(MessageText, CurrentObject, Field);
		EndIf;
		
	EndDo;
	
	CurrentObject.EmailPicturesInHTMLFormat = Undefined;
	If CurrentObject.HTMLFormatEmail Then
		CurrentObject.EmailText = TrimAll(EmailTextFormattedDocument.GetText());
		If CurrentObject.EmailText = "" Then
			CurrentObject.EmailTextInHTMLFormat = "";
		Else
			EmailTextFormattedDocument.GetHTML(CurrentObject.EmailTextInHTMLFormat, EmailAttachmentsStructureInHTMLFormat);
			If TypeOf(EmailAttachmentsStructureInHTMLFormat) = Type("Structure")
				AND EmailAttachmentsStructureInHTMLFormat.Count() > 0 Then
				CurrentObject.EmailPicturesInHTMLFormat = New ValueStorage(EmailAttachmentsStructureInHTMLFormat, New Deflation(9));
			EndIf;
			CurrentObject.EmailText = EmailTextFormattedDocument.GetText();
		EndIf;
	EndIf;
	
	// Writing the values
	If ValueIsFilled(MailingRecipientType) Then
		FoundItems = RecipientsTypesTable.FindRows(New Structure("RecipientsType", MailingRecipientType));
		If FoundItems.Count() = 1 Then
			CurrentObject.MailingRecipientType = FoundItems[0].MetadataObjectID;
		Else
			CurrentObject.MailingRecipientType = Catalogs.MetadataObjectIDs.EmptyRef();
		EndIf;
	Else
		CurrentObject.MailingRecipientType = Catalogs.MetadataObjectIDs.EmptyRef();
	EndIf;
	
	// All operations with scheduled jobs are placed in the object module.
	If Object.SchedulePeriodicity <> Enums.ReportMailingSchedulePeriodicities.Custom Then
		Schedule.EndTime = Schedule.BeginTime + 600;
	EndIf;
	CurrentObject.AdditionalProperties.Insert("Schedule", Schedule);
EndProcedure

&AtServer
Procedure OnWriteAtServer(Cancel, CurrentObject, WriteParameters)
	ArchivePasswordChangedButHidden = ArchivePasswordChanged AND ArchivePassword = PasswordHidden();
	FTPPasswordChangedButHidden = FTPPasswordChanged AND FTPPassword = PasswordHidden();
	
	If (ArchivePasswordChangedButHidden Or FTPPasswordChangedButHidden) AND ValueIsFilled(MailingBasis) Then
		CurrentUser = Users.CurrentUser();
		BasisAuthor = Common.ObjectAttributeValue(MailingBasis, "Author");
		If BasisAuthor = CurrentUser Then
			SetPrivilegedMode(True);
			If ArchivePasswordChangedButHidden Then
				TemporaryVariable = Common.ReadDataFromSecureStorage(MailingBasis, "ArchivePassword");
				Common.WriteDataToSecureStorage(CurrentObject.Ref, TemporaryVariable, "ArchivePassword");
				ArchivePasswordChanged = False;
			EndIf;
			If FTPPasswordChangedButHidden Then
				TemporaryVariable = Common.ReadDataFromSecureStorage(MailingBasis, "FTPPassword");
				Common.WriteDataToSecureStorage(CurrentObject.Ref, TemporaryVariable, "FTPPassword");
				FTPPasswordChanged = False;
			EndIf;
			SetPrivilegedMode(False);
		EndIf;
		MailingBasis = Undefined;
	EndIf;
	
	If ArchivePasswordChanged Then
		SetPrivilegedMode(True);
		Common.WriteDataToSecureStorage(CurrentObject.Ref, ArchivePassword, "ArchivePassword");
		SetPrivilegedMode(False);
	EndIf;
	
	If FTPPasswordChanged Then
		SetPrivilegedMode(True);
		Common.WriteDataToSecureStorage(CurrentObject.Ref, FTPPassword, "FTPPassword");
		SetPrivilegedMode(False);
	EndIf;
	
EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)

	// StandardSubsystems.AccessManagement
	If Common.SubsystemExists("StandardSubsystems.AccessManagement") Then
		ModuleAccessManagement = Common.CommonModule("AccessManagement");
		ModuleAccessManagement.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	EndIf;
	// End StandardSubsystems.AccessManagement

	// Refill form tables associated with objects tables (since object tables have already been filled).
	FillReportTableInfo();
	ReportsOnActivateRowAtServer(CurrentRowIDOfReportsTable);
	
	// Update the attributes initial values in the cache.
	FixAttributesValuesBeforeChange();
	For Each Row In Object.Reports Do
		Row.DoNotSendIfEmpty = Not Row.SendIfEmpty;
	EndDo;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure PreparedOnChange(Item)
	VisibilityAvailabilityCorrectness(ThisObject, "Prepared");
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Schedule page

&AtClient
Procedure ExecuteOnScheduleOnChange(Item)
	VisibilityAvailabilityCorrectness(ThisObject, "ExecuteOnSchedule");
EndProcedure

&AtClient
Procedure MonthsOnChange(Item)
	If Item <> Undefined Then
		Schedule.Months = ChangeArrayContent(ThisObject[Item.Name], Cache.Matches.Months[Item.Name], Schedule.Months);
	EndIf;
	VisibilityAvailabilityCorrectness(ThisObject, "Months");
EndProcedure

&AtClient
Procedure WeekDaysOnChange(Item)
	If Item <> Undefined Then
		Schedule.WeekDays = ChangeArrayContent(ThisObject[Item.Name], Cache.Matches.WeekDays[Item.Name], Schedule.WeekDays);
	EndIf;
	VisibilityAvailabilityCorrectness(ThisObject, "WeekDays");
EndProcedure

&AtClient
Procedure EditSchedule(Command)
	ChangeScheduleInDialog();
EndProcedure

&AtClient
Procedure SchedulePeriodicityOnChange(Item)
	VisibilityAvailabilityCorrectness(ThisObject, "SchedulePeriodicity");
	
#If NOT MobileClient Then
	If Object.SchedulePeriodicity = PredefinedValue("Enum.ReportMailingSchedulePeriodicities.Custom") Then
		ChangeScheduleInDialog();
	EndIf;
#EndIf
EndProcedure

&AtClient
Procedure MonthBeginEndHyperlinkClick(Item)
	If Schedule.DayInMonth = 0 Then
		DayInMonth = 1;
		Schedule.DayInMonth = -1;
	Else
		Schedule.DayInMonth = -Schedule.DayInMonth;
	EndIf;
	Modified = True;
	VisibilityAvailabilityCorrectness(ThisObject, "MonthBeginEnd");
EndProcedure

&AtClient
Procedure BeginTimeOnChange(Item)
	Schedule.BeginTime = BeginTime;
	VisibilityAvailabilityCorrectness(ThisObject, "BeginTime");
EndProcedure

&AtClient
Procedure DaysRepeatPeriodOnChange(Item)
	Schedule.DaysRepeatPeriod = DaysRepeatPeriod;
	VisibilityAvailabilityCorrectness(ThisObject, "DaysRepeatPeriod");
EndProcedure

&AtClient
Procedure MonthDayOnChange(Item)
	Schedule.DayInMonth = ?(Schedule.DayInMonth >= 0, DayInMonth, -DayInMonth);
	VisibilityAvailabilityCorrectness(ThisObject, "DayInMonth");
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Delivery page

&AtClient
Procedure MailingRecipientsTypeChoiceProcessing(Item, ValueSelected, StandardProcessing)
	If ValueSelected = MailingRecipientType Then
		StandardProcessing = False;
		Return;
	EndIf;
	
	FoundItems = RecipientsTypesTable.FindRows(New Structure("RecipientsType", ValueSelected));
	If FoundItems.Count() <> 1 Then
		StandardProcessing = False;
		Return;
	EndIf;
	
	// Clear recipients (if necessary).
	If Object.Recipients.Count() > 0 Then
		StandardProcessing = False;
		
		QuestionRow = NStr("ru = 'Для продолжения необходимо очистить список получателей.'; en = 'To continue, clear the recipient list.'; pl = 'To continue, clear the recipient list.';de = 'To continue, clear the recipient list.';ro = 'To continue, clear the recipient list.';tr = 'To continue, clear the recipient list.'; es_ES = 'To continue, clear the recipient list.'");
		
		Buttons = New ValueList;
		Buttons.Add(DialogReturnCode.Yes, NStr("ru = 'Очистить'; en = 'Clear'; pl = 'Clear';de = 'Clear';ro = 'Clear';tr = 'Clear'; es_ES = 'Clear'"));
		Buttons.Add(DialogReturnCode.Cancel);
		
		AdditionalParameters = New Structure;
		AdditionalParameters.Insert("SelectedValue", ValueSelected);
		Handler = New NotifyDescription("MailingRecipientsTypeChoiceChoiceProcessingEnd", ThisObject, AdditionalParameters);
		
		ShowQueryBox(Handler, QuestionRow, Buttons, 60, DialogReturnCode.Yes);
	EndIf;
EndProcedure

&AtClient
Procedure MailingRecipientsTypeChoiceOnChange(Item)
	FoundItems = RecipientsTypesTable.FindRows(New Structure("RecipientsType", MailingRecipientType));
	If FoundItems.Count() = 1 Then
		RecipientRow = FoundItems[0];
		Object.MailingRecipientType = RecipientRow.MetadataObjectID;
		Object.RecipientEmailAddressKind = RecipientRow.MainCIKind;
	EndIf;
EndProcedure

&AtClient
Procedure MailingRecipientsTypeChoiceClear(Item, StandardProcessing)
	StandardProcessing = False;
EndProcedure

&AtClient
Procedure AuthorPostalAddressKindOpen(Item, StandardProcessing)
	StandardProcessing = False;
	ShowValue(, Object.Author);
EndProcedure

&AtClient
Procedure FTPServerAndDirectoryOnChange(Item)
	SelectedValue = ReportMailingClient.ParseFTPAddress(FTPServerAndDirectory);
	FTPServerAndDirectoryChoiceProcessing(Item, SelectedValue, True);
EndProcedure

&AtClient
Procedure FTPServerAndDirectoryStartChoice(Item, ChoiceData, StandardProcessing)
	CustomFormParameters = New Structure("Server, Directory, Port, Username, PassiveConnection");
	For Each KeyAndValue In CustomFormParameters Do
		CustomFormParameters[KeyAndValue.Key] = Object["FTP" + KeyAndValue.Key];
	EndDo;
	CustomFormParameters.Insert("Password", FTPPassword);
	CustomFormParameters.Insert("Title", NStr("ru = '<Укажите получателя>'; en = '<Specify recipient>'; pl = '<Specify recipient>';de = '<Specify recipient>';ro = '<Specify recipient>';tr = '<Specify recipient>'; es_ES = '<Specify recipient>'"));
	
	OpenForm("Catalog.ReportMailings.Form.FTPParameters", CustomFormParameters, Item);
EndProcedure

&AtClient
Procedure FTPServerAndDirectoryChoiceProcessing(Item, ValueSelected, StandardProcessing)
	StandardProcessing = False;
	If ValueSelected = Undefined Or TypeOf(ValueSelected) <> Type("Structure") Then
		Return;
	EndIf;
	For Each KeyAndValue In ValueSelected Do
		If KeyAndValue.Key = "Password" Then
			If KeyAndValue.Value <> FTPPassword AND KeyAndValue.Value <> PasswordHidden() Then
				FTPPassword = KeyAndValue.Value;
				FTPPasswordChanged = True;
			EndIf;
		Else
			Object["FTP" + KeyAndValue.Key] = KeyAndValue.Value;
		EndIf;
	EndDo;
	
	VisibilityAvailabilityCorrectness(ThisObject, "FTPServerAndDirectory");
	Modified = True;
EndProcedure

&AtClient
Procedure FTPServerAndDirectoryClearing(Item, StandardProcessing)
	StandardProcessing = False;
EndProcedure

&AtClient
Procedure FTPServerAndDirectoryOpen(Item, StandardProcessing)

	StandardProcessing = False;
	
	FullAddress = "ftp://"+ Object.FTPServer +":"+ Format(Object.FTPPort, "NZ=21; NG=0") + Object.FTPDirectory;
	FileSystemClient.OpenURL(FullAddress);

EndProcedure

&AtClient
Procedure MailingKindOnChange(Item)
	Object.Personal            = (BulkEmailType = "Personal");
	Object.Personalized = (BulkEmailType = "Personalized");
	
	VisibilityAvailabilityCorrectness(ThisObject, "BulkEmailType");
EndProcedure

&AtClient
Procedure UseEmailOnChange(Item)
	VisibilityAvailabilityCorrectness(ThisObject, "UseEmail");
	
	If Not Publish AND Not Object.UseEmail Then
		Publish = True;
		EvaluateAdditionalDeliveryMethodsCheckBoxes();
		VisibilityAvailabilityCorrectness(ThisObject, "Publish");
	EndIf;
EndProcedure

&AtClient
Procedure NotifyOnlyOnChange(Item)
	VisibilityAvailabilityCorrectness(ThisObject, "NotifyOnly");
EndProcedure

&AtClient
Procedure OtherTransportMethodOnChange(Item)
	EvaluateAdditionalDeliveryMethodsCheckBoxes();
	VisibilityAvailabilityCorrectness(ThisObject, "OtherDeliveryMethod");
EndProcedure

&AtClient
Procedure OtherTransportMethodTextEditEnd(Item, Text, ChoiceData, DataGetParameters, StandardProcessing)
	StandardProcessing = NOT IsBlankString(Text);
EndProcedure

&AtClient
Procedure PublishOnChange(Item)
	EvaluateAdditionalDeliveryMethodsCheckBoxes();
	VisibilityAvailabilityCorrectness(ThisObject, "Publish");
	
	If Not Publish AND Not Object.UseEmail Then
		Object.UseEmail = True;
		VisibilityAvailabilityCorrectness(ThisObject, "UseEmail");
	EndIf;
EndProcedure

&AtClient
Procedure FolderOpen(Item, StandardProcessing)
	If CommonClient.SubsystemExists("StandardSubsystems.FilesOperations") Then
		ModuleFilesOperationsInternalClient = CommonClient.CommonModule("FilesOperationsInternalClient");
		ModuleFilesOperationsInternalClient.ReportsMailingViewFolder(StandardProcessing, Object.Folder);
	EndIf;
EndProcedure

&AtClient
Procedure FolderChoiceProcessing(Item, ValueSelected, StandardProcessing)
	If Not ChangeFolderAndFilesRight(ValueSelected) Then
		StandardProcessing = False;
		WarningText = NStr("ru = 'Недостаточно прав для изменения файлов папки ""%1"".'; en = 'Insufficient rights to change files of folder ""%1"".'; pl = 'Insufficient rights to change files of folder ""%1"".';de = 'Insufficient rights to change files of folder ""%1"".';ro = 'Insufficient rights to change files of folder ""%1"".';tr = 'Insufficient rights to change files of folder ""%1"".'; es_ES = 'Insufficient rights to change files of folder ""%1"".'");
		WarningText = StringFunctionsClientServer.SubstituteParametersToString(WarningText, String(ValueSelected));
		ShowMessageBox(, WarningText);
	EndIf;
EndProcedure

&AtClient
Procedure NetworkDirectoryWindowsOnChange(Item)
	Object.NetworkDirectoryWindows = CommonClientServer.AddLastPathSeparator(Object.NetworkDirectoryWindows);
	If IsBlankString(Object.NetworkDirectoryLinux) Then
		Object.NetworkDirectoryLinux = StrReplace(Object.NetworkDirectoryWindows, "\", "/");
	EndIf; 
EndProcedure

&AtClient
Procedure NetworkDirectoryLinuxOnChange(Item)
	Object.NetworkDirectoryLinux = CommonClientServer.AddLastPathSeparator(Object.NetworkDirectoryLinux);
	If IsBlankString(Object.NetworkDirectoryWindows) Then
		Object.NetworkDirectoryWindows = StrReplace(Object.NetworkDirectoryLinux, "/", "\");
	EndIf; 
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Additional page

&AtClient
Procedure DefaultFormatsStartChoice(Item, ChoiceData, StandardProcessing)
	StandardProcessing = False;
	Handler = New NotifyDescription("DefaultFormatsSelectionCompletion", ThisObject);
	ChooseFormat(Cache.EmptyReportValue, Handler);
EndProcedure

&AtClient
Procedure DefaultFormatsClear(Item, StandardProcessing)
	StandardProcessing = False;
	ClearFormat(Cache.EmptyReportValue);
	DefaultFormats = DefaultFormatsListPresentation;
	VisibilityAvailabilityCorrectness(ThisObject, "DefaultFormats");
EndProcedure

&AtClient
Procedure ArchiveOnChange(Item)
	VisibilityAvailabilityCorrectness(ThisObject, "AddToArchive");
EndProcedure

&AtClient
Procedure AuthorOnChange(Item)
	CurrentList = Items.AuthorMailAddressKind.ChoiceList;
	CurrentList.Clear();
	NewList = New ValueList;
	RecipientMailAddresses(Object.Author, NewList);
	For Each ListItem In NewList Do
		FillPropertyValues(CurrentList.Add(), ListItem);
	EndDo;
	If NewList.FindByValue(Object.RecipientEmailAddressKind) = Undefined Then
		Object.RecipientEmailAddressKind = Undefined;
	EndIf;
EndProcedure

&AtClient
Procedure ParentChoiceProcessing(Item, ValueSelected, StandardProcessing)
	If ValueSelected = Cache.PersonalMailingsGroup Then
		StandardProcessing = False;
		ShowMessageBox(, NStr("ru = 'Выбранная группа используется только для личных рассылок по электронной почте'; en = 'The selected group is used only for private mailing'; pl = 'The selected group is used only for private mailing';de = 'The selected group is used only for private mailing';ro = 'The selected group is used only for private mailing';tr = 'The selected group is used only for private mailing'; es_ES = 'The selected group is used only for private mailing'"));
	EndIf;
EndProcedure

&AtClient
Procedure ArchivePasswordOnChange(Item)
	ArchivePasswordChanged = True;
EndProcedure

#EndRegion

#Region ReportstFormTableItemEventHandlers

&AtClient
Procedure ReportsChoiceProcessing(Item, ValueSelected, StandardProcessing)
	StandardProcessing = False;
	
	FillingStructure = New Structure;
	FillingStructure.Insert("Formats", DefaultFormatsPresentation());
	FillingStructure.Insert("SendIfEmpty", False);
	FillingStructure.Insert("DoNotSendIfEmpty", True);
	FillingStructure.Insert("Enabled", True);
	
	NewRowArray = ChoicePickupDragToTabularSection(
		ValueSelected,
		Object.Reports,
		"Report",
		FillingStructure,
		True);
	
	Template = New FixedStructure("Count, RowsArray, ReportsPresentations, Text", 0, Undefined, "");
	ChoiceStructure = New Structure;
	ChoiceStructure.Insert("Selected",   New Structure(Template));
	ChoiceStructure.Insert("Success",   New Structure(Template));
	ChoiceStructure.Insert("WithErrors", New Structure(Template));
	ChoiceStructure.Selected.RowsArray   = NewRowArray;
	ChoiceStructure.Success.RowsArray   = New Array;
	ChoiceStructure.WithErrors.RowsArray = New Array;
	
	// Initialize the added report rows and fill the selection structure.
	CheckAddedReportRows(ChoiceStructure);
	
	If ChoiceStructure.WithErrors.Count > 0 Then
		
		If ChoiceStructure.Selected.Count = 1 Then
			MessageText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'Не удалось включить отчет в рассылку по причине:
					|%1'; 
					|en = 'Cannot include the report in bulk mail due to:
					|%1'; 
					|pl = 'Cannot include the report in bulk mail due to:
					|%1';
					|de = 'Cannot include the report in bulk mail due to:
					|%1';
					|ro = 'Cannot include the report in bulk mail due to:
					|%1';
					|tr = 'Cannot include the report in bulk mail due to:
					|%1'; 
					|es_ES = 'Cannot include the report in bulk mail due to:
					|%1'"), ChoiceStructure.WithErrors.Text);
		ElsIf ChoiceStructure.Success.Count = 0 Then
			MessageText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'Не удалось включить отчеты в рассылку по причине:
					|%1'; 
					|en = 'Cannot include reports in bulk mail due to:
					|%1'; 
					|pl = 'Cannot include reports in bulk mail due to:
					|%1';
					|de = 'Cannot include reports in bulk mail due to:
					|%1';
					|ro = 'Cannot include reports in bulk mail due to:
					|%1';
					|tr = 'Cannot include reports in bulk mail due to:
					|%1'; 
					|es_ES = 'Cannot include reports in bulk mail due to:
					|%1'"), ChoiceStructure.WithErrors.Text);
		Else
			MessageText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'В рассылку включено отчетов: %1 из %2
					|Подробности:
					|%3'; 
					|en = 'Reports included in bulk mail: %1 of %2 
					|Details:
					|%3'; 
					|pl = 'Reports included in bulk mail: %1 of %2 
					|Details:
					|%3';
					|de = 'Reports included in bulk mail: %1 of %2 
					|Details:
					|%3';
					|ro = 'Reports included in bulk mail: %1 of %2 
					|Details:
					|%3';
					|tr = 'Reports included in bulk mail: %1 of %2 
					|Details:
					|%3'; 
					|es_ES = 'Reports included in bulk mail: %1 of %2 
					|Details:
					|%3'"),
				Format(ChoiceStructure.Success.Count, "NZ=0; NG="),
				Format(ChoiceStructure.Selected.Count, "NZ=0; NG="), 
				ChoiceStructure.WithErrors.Text);
		EndIf;
		ShowMessageBox(Undefined, MessageText);
		
	Else
		
		If ChoiceStructure.Success.Count = 0 Then
			NotificationTitle = Undefined;
			NotificationText = NStr("ru = 'Все выбранные отчеты уже включены в рассылку'; en = 'All the selected reports are already included in mailing.'; pl = 'All the selected reports are already included in mailing.';de = 'All the selected reports are already included in mailing.';ro = 'All the selected reports are already included in mailing.';tr = 'All the selected reports are already included in mailing.'; es_ES = 'All the selected reports are already included in mailing.'");
		Else
			If ChoiceStructure.Selected.Count = 1 Then
				NotificationTitle = NStr("ru = 'Отчет включен в рассылку'; en = 'Report is included in the bulk email'; pl = 'Report is included in the bulk email';de = 'Report is included in the bulk email';ro = 'Report is included in the bulk email';tr = 'Report is included in the bulk email'; es_ES = 'Report is included in the bulk email'");
			Else
				NotificationTitle = NStr("ru = 'Отчеты включены в рассылку'; en = 'Reports are included in the bulk email'; pl = 'Reports are included in the bulk email';de = 'Reports are included in the bulk email';ro = 'Reports are included in the bulk email';tr = 'Reports are included in the bulk email'; es_ES = 'Reports are included in the bulk email'");
			EndIf;
			NotificationText = ChoiceStructure.Success.ReportsPresentations;
		EndIf;
		
		ShowUserNotification(
			NotificationTitle,
			,
			NotificationText,
			PictureLib.Done32);
		
	EndIf;
	
	VisibilityAvailabilityCorrectness(ThisObject, "Reports");
EndProcedure

&AtClient
Procedure ReportsOnActivateRow(Item)
	AttachIdleHandler("ReportsTableRowActivationHandler", 0.1, True);
EndProcedure

&AtClient
Procedure ReportsTableRowActivationHandler()
	ReportsRow = Items.Reports.CurrentData;
	If ReportsRow = Undefined Then
		Items.ReportSettingsPages.CurrentPage = Items.BlankPage;
		Return;
	EndIf;
	
	RowID = ReportsRow.GetID();
	If RowID = CurrentRowIDOfReportsTable Then
		Return;
	EndIf;
	
	WarningText = ReportsOnActivateRowAtServer(RowID);
	If WarningText <> "" Then
		ShowMessageBox(, WarningText);
	EndIf;
EndProcedure

&AtClient
Procedure ReportsBeforeRowChange(Item, Cancel)
	Cancel = True;
EndProcedure

&AtClient
Procedure ReportsBeforeAddRow(Item, Cancel, Clone, Parent, Folder)
	Cancel = True;
EndProcedure

&AtClient
Procedure ReportsAfterDeleteRow(Item)
	VisibilityAvailabilityCorrectness(ThisObject, "Reports");
EndProcedure

#EndRegion

#Region UserSettingsFormTableItemEventHandlers

&AtClient
Procedure UserSettingsOnChange(Item)
	ReportsRow = Items.Reports.CurrentData;
	If ReportsRow = Undefined Then
		Return;
	EndIf;
	
	ReportsRow.ChangesMade = True;
EndProcedure

&AtClient
Procedure UserSettingsOnActivateRow(Item)
	If Items.ReportSettingsPages.CurrentPage <> Items.ComposerPage Then
		Return;
	EndIf;
	Report = Items.Reports.CurrentData;
	If Report = Undefined Or TypeOf(Report.Report) <> Type("CatalogRef.ReportsOptions") Then
		Return;
	EndIf;
	DCID = Items.UserSettings.CurrentRow;
	ValueViewOnly = False;
	ReportMailingClientOverridable.OnActivateRowSettings(Report, DCSettingsComposer, DCID, ValueViewOnly);
	If Items.UserSettingsValue.ReadOnly <> ValueViewOnly Then
		Items.UserSettingsValue.ReadOnly = ValueViewOnly;
	EndIf;
EndProcedure

&AtClient
Procedure UserSettingsValueStartChoice(Item, ChoiceData, StandardProcessing)
	UserSettingStartChoice(StandardProcessing);
EndProcedure

&AtClient
Procedure UserSettingsValueClear(Item, StandardProcessing)
	If Items.ReportSettingsPages.CurrentPage <> Items.ComposerPage Then
		Return;
	EndIf;
	Report = Items.Reports.CurrentData;
	If Report = Undefined Or TypeOf(Report.Report) <> Type("CatalogRef.ReportsOptions") Then
		Return;
	EndIf;
	DCID = Items.UserSettings.CurrentRow;
	ReportMailingClientOverridable.OnSettingsClear(Report, DCSettingsComposer, DCID, StandardProcessing);
EndProcedure

&AtClient
Procedure UserSettingsChoice(Item, RowSelected, Field, StandardProcessing)
	UserSettingStartChoice(StandardProcessing);
EndProcedure

#EndRegion

#Region CurReportSettingsFormTableItemEventHandlers

&AtClient
Procedure CurReportSettingsValueOnChange(Item)
	SettingsString = Items.CurrentReportSettings.CurrentData;
	If SettingsString = Undefined Then
		Return;
	EndIf;
	
	SettingsString.Use = True;
EndProcedure

&AtClient
Procedure CurReportSettingsOnChange(Item)
	ReportsRow = Items.Reports.CurrentData;
	If ReportsRow = Undefined Then
		Return;
	EndIf;
	
	ReportsRow.ChangesMade = True;
EndProcedure

#EndRegion

#Region ReportFormatsFormTableItemEventHandlers

&AtClient
Procedure ReportFormatsBeforeAddRow(Item, Cancel, Clone, Parent, Folder, Parameter)
	Cancel = True;
EndProcedure

&AtClient
Procedure ReportFormatsBeforeDelete(Item, Cancel)
	Cancel = True;
EndProcedure

&AtClient
Procedure ReportFormatsStartChoiceFormats(Item, ChoiceData, StandardProcessing)
	StandardProcessing = False;
	ReportsRow = Items.ReportFormats.CurrentData;
	If ReportsRow = Undefined Then
		Return;
	EndIf;
	
	Variables = New Structure;
	Variables.Insert("ReportsRow", ReportsRow);
	
	Handler = New NotifyDescription("ReportFormatsEndChoiceFormat", ThisObject, Variables);
	
	ChooseFormat(ReportsRow.Report, Handler);
EndProcedure

&AtClient
Procedure ReportFormatsClearFormats(Item, StandardProcessing)
	StandardProcessing = False;
	ReportsRow = Items.ReportFormats.CurrentData;
	If ReportsRow = Undefined Then
		Return;
	EndIf;
	
	ClearFormat(ReportsRow.Report);
	ReportsRow.Formats = DefaultFormatsPresentation();
EndProcedure

&AtClient
Procedure ReportFormatsSendIfEmptyOnChange(Item)
	CurrentData = Items.ReportFormats.CurrentData;
	If CurrentData = Undefined Then
		Return;
	EndIf;
	CurrentData.DoNotSendIfEmpty = Not CurrentData.SendIfEmpty;
EndProcedure

&AtClient
Procedure ReportFormatsDoNotSendEmptyOnChange(Item)
	CurrentData = Items.ReportFormats.CurrentData;
	If CurrentData = Undefined Then
		Return;
	EndIf;
	CurrentData.SendIfEmpty = Not CurrentData.DoNotSendIfEmpty;
EndProcedure

#EndRegion

#Region FormCommandHandlers

////////////////////////////////////////////////////////////////////////////////
// Command bar

&AtClient
Procedure CommandWriteAndClose(Command)
	WriteParameters = New Structure;
	WriteParameters.Insert("CommandName", "CommandWriteAndClose");
	WriteAtClient(Undefined, WriteParameters);
EndProcedure

&AtClient
Procedure MailingRecipientsClick(Item, StandardProcessing)
	StandardProcessing = False;
	
	If Not ValueIsFilled(Object.MailingRecipientType) Then
		ErrorText = NStr("ru = 'Для ввода получателей необходимо выбрать их тип'; en = 'To enter recipients, select their type'; pl = 'To enter recipients, select their type';de = 'To enter recipients, select their type';ro = 'To enter recipients, select their type';tr = 'To enter recipients, select their type'; es_ES = 'To enter recipients, select their type'");
		CommonClient.MessageToUser(ErrorText, , "MailingRecipientType");
		Return;
	EndIf;
	
	Handler = New NotifyDescription("BulkEmailRecipientsClickCompletion", ThisObject);
	
	FormParameters = New Structure;
	FormParameters.Insert("Recipients", Object.Recipients);
	FormParameters.Insert("MailingRecipientType", MailingRecipientType);
	FormParameters.Insert("RecipientEmailAddressKind", Object.RecipientEmailAddressKind);
	FormParameters.Insert("BulkEmailDescription", Object.Description);
	
	OpenForm("Catalog.ReportMailings.Form.BulkEmailRecipients", FormParameters, , , , , Handler);
EndProcedure

&AtClient
Procedure CommandWrite(Command)
	WriteParameters = New Structure;
	WriteParameters.Insert("CommandName", "CommandWrite");
	WriteAtClient(Undefined, WriteParameters);
EndProcedure

&AtClient
Procedure ExecuteNowCommand(Command)
	If Not Object.Prepared Then
		ShowMessageBox(, NStr("ru = 'Рассылка не подготовлена'; en = 'Bulk email is not prepared'; pl = 'Bulk email is not prepared';de = 'Bulk email is not prepared';ro = 'Bulk email is not prepared';tr = 'Bulk email is not prepared'; es_ES = 'Bulk email is not prepared'"));
		Return;
	EndIf;
	WriteParameters = New Structure;
	WriteParameters.Insert("CommandName", "ExecuteNowCommand");
	WriteAtClient(Undefined, WriteParameters);
EndProcedure

&AtClient
Procedure MailingEventsCommand(Command)
	WriteParameters = New Structure;
	WriteParameters.Insert("CommandName", "MailingEventsCommand");
	WriteAtClient(Undefined, WriteParameters);
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Reports page

&AtClient
Procedure AddReport(Command)
	SelectedValues = New ValueList;
	For Each ReportsRow In Object.Reports Do
		If TypeOf(ReportsRow.Report) = Type("CatalogRef.ReportsOptions") Then
			SelectedValues.Add(ReportsRow.Report);
		EndIf;
	EndDo;
	
	ChoiceFilter = New Structure;
	ChoiceFilter.Insert("ReportType", 1);
	ChoiceFilter.Insert("Report", New Structure("Kind, Value", "NotInList", Cache.ReportsToBeExcluded));
	
	ChoiceFormParameters = New Structure;
	ChoiceFormParameters.Insert("WindowOpeningMode",  FormWindowOpeningMode.LockOwnerWindow);
	ChoiceFormParameters.Insert("ChoiceMode",        True);
	ChoiceFormParameters.Insert("MultipleChoice", True);
	ChoiceFormParameters.Insert("CloseOnChoice", False);
	ChoiceFormParameters.Insert("Filter",              ChoiceFilter);
	ChoiceFormParameters.Insert("SelectedValues",  SelectedValues);
	
	OpenForm("Catalog.ReportsOptions.ChoiceForm", ChoiceFormParameters, Items.Reports);
EndProcedure

&AtClient
Procedure AddAdditionalReport(Command)
	// Additional reports pickup form.
	If CommonClient.SubsystemExists("StandardSubsystems.AdditionalReportsAndDataProcessors") Then
		ModuleAdditionalReportsAndDataProcessorsClient = CommonClient.CommonModule("AdditionalReportsAndDataProcessorsClient");
		ModuleAdditionalReportsAndDataProcessorsClient.ReportDistributionPickAddlReport(Items.Reports);
	EndIf;
EndProcedure

&AtClient
Procedure ReportPreview(Command)
	If Not CheckFilling() Then
		Return;
	EndIf;
	
	ClearMessages();
	
	ReportsRow = Items.Reports.CurrentData;
	If ReportsRow = Undefined Then
		ShowMessageBox(, NStr("ru = 'Выберите отчет'; en = 'Select report'; pl = 'Select report';de = 'Select report';ro = 'Select report';tr = 'Select report'; es_ES = 'Select report'"));
		Return;
	EndIf;
	If Not ReportsRow.Enabled Then
		ShowMessageBox(, ReportsRow.Presentation);
		Return;
	EndIf;
	
	ReportParameters = New Structure;
	ReportParameters.Insert("Report",                ReportsRow.Report);
	ReportParameters.Insert("Settings",            Undefined);
	ReportParameters.Insert("SendIfEmpty", ReportsRow.SendIfEmpty);
	ReportParameters.Insert("Formats",              New Array);
	ReportParameters.Insert("Presentation",        ReportsRow.Presentation);
	ReportParameters.Insert("FullName",            ReportsRow.FullName);
	ReportParameters.Insert("VariantKey",         ReportsRow.VariantKey);
	
	If ReportsRow.DCS Then
		ReportParameters.Settings = DCSettingsComposer.UserSettings;
	Else
		ReportParameters.Settings = New Array;
		FoundItems = CurrentReportSettings.FindRows(New Structure("Use", True));
		For Each SettingRow In FoundItems Do
			SettingToAdd = New Structure("Attribute, Value", SettingRow.Attribute, SettingRow.Value);
			ReportParameters.Settings.Add(SettingToAdd);
		EndDo;
	EndIf;
	
	If Object.Personalized Then
		If Not RecipientsSpecified(Object.Recipients) Then
			Return;
		EndIf;
		Handler = New NotifyDescription("ReportsPreviewContinue", ThisObject, ReportParameters);
		ReportMailingClient.SelectRecipient(Handler, Object, False, False);
	Else
		ReportsPreviewContinue(Undefined, ReportParameters);
	EndIf;
EndProcedure

&AtClient
Procedure ReportsPreviewContinue(SelectionResult, ReportParameters) Export
	DCUserSettings = ReportParameters.Settings;
	Filter = New Structure("Use, Value", True, "[Recipient]");
	If TypeOf(DCUserSettings) = Type("DataCompositionUserSettings") Then
		PersonalizedSettings = ReportsClientServer.FindSettings(DCUserSettings.Items, Filter);
	Else
		PersonalizedSettings = ReportsClientServer.FindSettings(DCUserSettings, Filter);
	EndIf;
	If Object.Personalized Then
		If SelectionResult = Undefined Then
			Return;
		Else
			Recipient = SelectionResult.Recipient;
		EndIf;
		For Each DCUserSetting In PersonalizedSettings Do
			If TypeOf(DCUserSetting) = Type("DataCompositionFilterItem") Then
				DCUserSetting.RightValue = Recipient;
			ElsIf TypeOf(DCUserSetting) = Type("DataCompositionSettingsParameterValue") Then
				DCUserSetting.Value = Recipient;
			EndIf;
		EndDo;
	EndIf;
	
	FormParameters = New Structure;
	FormParameters.Insert("UserSettings", DCUserSettings);
	FormParameters.Insert("GenerateOnOpen", True);
	
	ReportsOptionsClient.OpenReportForm(ThisObject, ReportParameters.Report, FormParameters);
	
	For Each DCUserSetting In PersonalizedSettings Do
		If TypeOf(DCUserSetting) = Type("DataCompositionFilterItem") Then
			DCUserSetting.RightValue = "[Recipient]";
		ElsIf TypeOf(DCUserSetting) = Type("DataCompositionSettingsParameterValue") Then
			DCUserSetting.Value = "[Recipient]";
		EndIf;
	EndDo;
EndProcedure

&AtClient
Procedure SpecifyMailingRecipient(Command)
	ClearMessages();
	
	// Check - whether the possibility to personalize the mailing enabled.
	If Not Object.Personalized Then
		KindPresentaion = Items.BulkEmailType.ChoiceList.FindByValue("Personalized").Presentation;
		MessageText = NStr("ru = 'Использовать получателя в параметрах возможно только для вида рассылки ""%1""'; en = 'Recipient can be used in parameters only for bulk email kind ""%1""'; pl = 'Recipient can be used in parameters only for bulk email kind ""%1""';de = 'Recipient can be used in parameters only for bulk email kind ""%1""';ro = 'Recipient can be used in parameters only for bulk email kind ""%1""';tr = 'Recipient can be used in parameters only for bulk email kind ""%1""'; es_ES = 'Recipient can be used in parameters only for bulk email kind ""%1""'");
		MessageText = StringFunctionsClientServer.SubstituteParametersToString(MessageText, KindPresentaion);
		CommonClient.MessageToUser(MessageText, , "BulkEmailType");
		Return;
	EndIf;
	
	// Get the main type of recipients.
	TypesCount = MailingRecipientType.Types().Count();
	If TypesCount <> 1 AND TypesCount <> 2 Then
		CommonClient.MessageToUser(NStr("ru = 'Поле ""Получатели"" не заполнено'; en = 'The Recipients field is not populated'; pl = 'The Recipients field is not populated';de = 'The Recipients field is not populated';ro = 'The Recipients field is not populated';tr = 'The Recipients field is not populated'; es_ES = 'The Recipients field is not populated'"), , "MailingRecipientType");
		Return;
	EndIf;
	
	FoundMetadataObjectIDs = RecipientsTypesTable.FindRows(New Structure("RecipientsType", MailingRecipientType));
	If FoundMetadataObjectIDs.Count() <> 1 Then
		ShowMessageBox(, NStr("ru = 'Тип получателей не найден'; en = 'Recipient type is not found'; pl = 'Recipient type is not found';de = 'Recipient type is not found';ro = 'Recipient type is not found';tr = 'Recipient type is not found'; es_ES = 'Recipient type is not found'"));
		Return;
	EndIf;
	
	TypesArray = FoundMetadataObjectIDs[0].MainType.Types();
	If TypesArray.Count() <> 1 Then
		ShowMessageBox(, NStr("ru = 'Тип получателей не найден'; en = 'Recipient type is not found'; pl = 'Recipient type is not found';de = 'Recipient type is not found';ro = 'Recipient type is not found';tr = 'Recipient type is not found'; es_ES = 'Recipient type is not found'"));
		Return;
	EndIf;
	
	MainRecipientsType = TypesArray[0];
	
	Setting = IdentifySetting();
	If Setting = Undefined Then
		Return;
	EndIf;
	
	// Recipients type content check.
	If Not Setting.AvailableTypeInfo.ContainsType(MainRecipientsType) Then
		WarningText = NStr("ru = 'Тип ""%1"" не подходит по типу к выбранной настройке.
			|Необходимо выбрать другой тип получателей рассылки или другую настройку.'; 
			|en = 'Type ""%1"" is not suitable for the selected setting. 
			|Select another recipient type or setting.'; 
			|pl = 'Type ""%1"" is not suitable for the selected setting. 
			|Select another recipient type or setting.';
			|de = 'Type ""%1"" is not suitable for the selected setting. 
			|Select another recipient type or setting.';
			|ro = 'Type ""%1"" is not suitable for the selected setting. 
			|Select another recipient type or setting.';
			|tr = 'Type ""%1"" is not suitable for the selected setting. 
			|Select another recipient type or setting.'; 
			|es_ES = 'Type ""%1"" is not suitable for the selected setting. 
			|Select another recipient type or setting.'");
		WarningText = StringFunctionsClientServer.SubstituteParametersToString(WarningText, String(MainRecipientsType));
		ShowMessageBox(, WarningText);
		Return;
	EndIf;
	
	Setting.Initiator.EndEditRow(False);
	Setting.SettingsString.Use = True;
	If Setting.DCS Then
		If Setting.IsFilterItem Then
			If Setting.SettingsString.ComparisonType = DataCompositionComparisonType.InList
				Or Setting.SettingsString.ComparisonType = DataCompositionComparisonType.InHierarchy
				Or Setting.SettingsString.ComparisonType = DataCompositionComparisonType.InListByHierarchy
				Or Setting.SettingsString.ComparisonType = DataCompositionComparisonType.NotInList
				Or Setting.SettingsString.ComparisonType = DataCompositionComparisonType.NotInHierarchy
				Or Setting.SettingsString.ComparisonType = DataCompositionComparisonType.NotInListByHierarchy Then
				Setting.SettingsString.ComparisonType = DataCompositionComparisonType.Equal;
			EndIf;
			Setting.SettingsString.RightValue = "[Recipient]";
		Else
			Setting.SettingsString.Value = "[Recipient]";
		EndIf;
	Else
		Setting.SettingsString.Value = "[Recipient]";
	EndIf;
	
	MailingWasPersonalized = True;
	Items.Reports.CurrentData.ChangesMade = True;
	Modified = True;
	
EndProcedure

&AtClient
Procedure DeleteMailingRecipient(Command)
	ClearMessages();
	
	Setting = IdentifySetting();
	If Setting = Undefined Then
		Return;
	EndIf;
	
	Setting.Initiator.EndEditRow(False);
	ChangesMade = False;
	If Setting.DCS Then
		If Setting.IsFilterItem Then
			If Setting.SettingsString.RightValue = "[Recipient]" Then
				Setting.SettingsString.RightValue = Undefined;
				ChangesMade = True;
			EndIf;
		Else
			If Setting.SettingsString.Value = "[Recipient]" Then 
				Setting.SettingsString.Value = Undefined;
				ChangesMade = True;
			EndIf;
		EndIf;
	Else
		If Setting.SettingsString.Value = "[Recipient]" Then 
			Setting.SettingsString.Value = Undefined;
			ChangesMade = True;
		EndIf;
	EndIf;
	
	If ChangesMade Then
		Items.Reports.CurrentData.ChangesMade = True;
		Modified = True;
	EndIf;
EndProcedure

&AtClient
Function IdentifySetting()
	
	DCS = (Items.ReportSettingsPages.CurrentPage = Items.ComposerPage);
	If DCS Then
		Initiator = Items.UserSettings;
	Else
		Initiator = Items.CurrentReportSettings;
	EndIf;
	
	// Get details of the types available for selection.
	If DCS Then
		
		// User setting ID.
		SettingID = Initiator.CurrentRow;
		If SettingID = Undefined Then
			ShowMessageBox(, NStr("ru = 'Не выбрана настройка отчета.'; en = 'Report setting is not selected.'; pl = 'Report setting is not selected.';de = 'Report setting is not selected.';ro = 'Report setting is not selected.';tr = 'Report setting is not selected.'; es_ES = 'Report setting is not selected.'"));
			Return Undefined;
		EndIf;
		
		// Get a row from data composition settings.
		SettingsString = DCSettingsComposer.UserSettings.GetObjectByID(SettingID);
		If SettingsString = Undefined Then
			ShowMessageBox(, NStr("ru = 'Не выбрана настройка отчета.'; en = 'Report setting is not selected.'; pl = 'Report setting is not selected.';de = 'Report setting is not selected.';ro = 'Report setting is not selected.';tr = 'Report setting is not selected.'; es_ES = 'Report setting is not selected.'"));
			Return Undefined;
		EndIf;
		
		// Setting type check.
		If TypeOf(SettingsString) = Type("DataCompositionFilterItem") Then
			IsFilterItem = True;
		ElsIf TypeOf(SettingsString) = Type("DataCompositionSettingsParameterValue") Then
			IsFilterItem = False;
		Else
			ShowMessageBox(, NStr("ru = 'Указывать получателя можно только для параметров и отборов отчетов.'; en = 'You can specify the recipient only for report parameters and filters.'; pl = 'You can specify the recipient only for report parameters and filters.';de = 'You can specify the recipient only for report parameters and filters.';ro = 'You can specify the recipient only for report parameters and filters.';tr = 'You can specify the recipient only for report parameters and filters.'; es_ES = 'You can specify the recipient only for report parameters and filters.'"));
			Return Undefined;
		EndIf;
		
		// Data composition field.
		If IsFilterItem Then
			
			If ValueIsFilled(SettingsString.LeftValue) Then
				DCField = SettingsString.LeftValue;
			Else
				
				DCField = DetermineFieldFromComposer(SettingID, DCSettingsComposer.Settings.Filter.Items);
				If DCField = Undefined Then
					DCField = DetermineFieldFromComposer(SettingID, DCSettingsComposer.UserSettings.Items);
				EndIf;
				If DCField = Undefined Then
					ShowMessageBox(, NStr("ru = 'Для настройки отчета не найдено описание доступного поля'; en = 'To configure the report, the available field description is not found'; pl = 'To configure the report, the available field description is not found';de = 'To configure the report, the available field description is not found';ro = 'To configure the report, the available field description is not found';tr = 'To configure the report, the available field description is not found'; es_ES = 'To configure the report, the available field description is not found'"));
					Return Undefined;
				EndIf;
				
			EndIf;
			AvailableDCField = DCSettingsComposer.Settings.Filter.FilterAvailableFields.FindField(DCField);
			
		Else
			AvailableDCField = DCSettingsComposer.Settings.DataParameters.AvailableParameters.FindParameter(SettingsString.Parameter);
		EndIf;
		
		If AvailableDCField = Undefined Then
			Return Undefined;
		EndIf;
		AvailableTypeInfo = AvailableDCField.ValueType;
		
	Else
		
		// Types array for arbitrary reports.
		SettingsString = Initiator.CurrentData;
		If SettingsString = Undefined Then
			ShowMessageBox(, NStr("ru = 'Не выбрана настройка отчета.'; en = 'Report setting is not selected.'; pl = 'Report setting is not selected.';de = 'Report setting is not selected.';ro = 'Report setting is not selected.';tr = 'Report setting is not selected.'; es_ES = 'Report setting is not selected.'"));
			Return Undefined;
		EndIf;
		
		AvailableTypeInfo = SettingsString.Type;
	EndIf;
	
	Result = New Structure;
	Result.Insert("DCS", DCS);
	Result.Insert("Initiator", Initiator);
	Result.Insert("AvailableTypeInfo", AvailableTypeInfo);
	Result.Insert("SettingsString", SettingsString);
	Result.Insert("IsFilterItem", IsFilterItem);
	Return Result;
	
EndFunction

&AtClient
Function DetermineFieldFromComposer(SettingID, Collection)
	For Each Item In Collection Do
		If String(Item.UserSettingID) = String(SettingID)
			AND ValueIsFilled(String(Item.LeftValue)) Then
			Return Item.LeftValue;
		EndIf;
		
		If TypeOf(Item) = Type("DataCompositionFilterItemGroup")
			Or TypeOf(Item) = Type("DataCompositionFilter") Then
			Field = DetermineFieldFromComposer(SettingID, Item.Items);
			If Field <> Undefined Then
				Return Field;
			EndIf;
		EndIf;
	EndDo;
	
	Return Undefined;
EndFunction

////////////////////////////////////////////////////////////////////////////////
// Schedule page

&AtClient
Procedure SelectAll(Command)
	AllMonths = New Array;
	For Each KeyAndValue In Cache.Matches.Months Do
		ThisObject[KeyAndValue.Key] = True;
		AllMonths.Add(KeyAndValue.Value);
	EndDo;
	Schedule.Months = AllMonths;
	VisibilityAvailabilityCorrectness(ThisObject, "Months");
EndProcedure

&AtClient
Procedure ClearAll(Command)
	AllMonths = New Array;
	For Each KeyAndValue In Cache.Matches.Months Do
		ThisObject[KeyAndValue.Key] = False;
	EndDo;
	Schedule.Months = AllMonths;
	VisibilityAvailabilityCorrectness(ThisObject, "Months");
EndProcedure

&AtClient
Procedure FillScheduleByTemplate(Command)
	Handler = New NotifyDescription("FillScheduleByTemplateCompletion", ThisObject);
	
	VariantList = ReportMailingClient.ScheduleFillingOptionsList();
	VariantList.ShowChooseItem(Handler, NStr("ru = 'Выберите шаблон расписания'; en = 'Select schedule template'; pl = 'Select schedule template';de = 'Select schedule template';ro = 'Select schedule template';tr = 'Select schedule template'; es_ES = 'Select schedule template'"));
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Delivery page

&AtClient
Procedure AddChangeMailingDateTemplate(Command)
	AddTemplate();
	
	Variables = New Structure;
	Variables.Insert("Item",      CurrentItem);
	Variables.Insert("OldText",  Variables.Item.SelectedText);
	Variables.Insert("Prefix",      "[ExecutionDate(");
	Variables.Insert("Postfix",     ")]");
	Variables.Insert("FormatText", "");
	
	PrefixLength  = StrLen(Variables.Prefix);
	PrefixPosition  = StrFind(Variables.OldText, Variables.Prefix);
	PostfixPosition = StrFind(Variables.OldText, Variables.Postfix);
	
	Variables.Insert("PreviousFragmentFound", (PrefixPosition > 0 AND PostfixPosition > PrefixPosition));
	If Variables.PreviousFragmentFound Then
		Variables.FormatText = Mid(Variables.OldText, PrefixPosition + PrefixLength, PostfixPosition - PrefixPosition - PrefixLength);
	EndIf;
	
	Handler = New NotifyDescription("AddChangeMailingDateTemplateEnd", ThisObject, Variables);
	
	Dialog = New FormatStringWizard;
	Dialog.AvailableTypes = New TypeDescription("Date");
	Dialog.Text         = Variables.FormatText;
	Dialog.Show(Handler);
	
EndProcedure

&AtClient
Procedure AddRecipientTemplate(Command)
	// Clear message window
	ClearMessages();
	
	//
	If NOT Object.Personalized Then
		MessageText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Использование получателя в тексте шаблона возможно только для вида рассылки ""%1""'; en = 'You can use recipient in the template text only for the bulk email kind ""%1""'; pl = 'You can use recipient in the template text only for the bulk email kind ""%1""';de = 'You can use recipient in the template text only for the bulk email kind ""%1""';ro = 'You can use recipient in the template text only for the bulk email kind ""%1""';tr = 'You can use recipient in the template text only for the bulk email kind ""%1""'; es_ES = 'You can use recipient in the template text only for the bulk email kind ""%1""'"),
			Items.BulkEmailType.ChoiceList.FindByValue("Personalized").Presentation);
		CommonClient.MessageToUser(MessageText, , "BulkEmailType");
		Return;
	EndIf;
	
	AddTemplate("[Recipient]");
	MailingWasPersonalized = True;
EndProcedure

&AtClient
Procedure AddGeneratedReportsTemplate(Command)
	AddTemplate("[GeneratedReports]", True);
EndProcedure

&AtClient
Procedure AddAuthorTemplate(Command)
	AddTemplate("[Author]");
EndProcedure

&AtClient
Procedure AddMailingDescriptionTemplate(Command)
	AddTemplate("[BulkEmailDescription]");
EndProcedure

&AtClient
Procedure AddSystemTemplate(Command)
	AddTemplate("[SystemTitle]");
EndProcedure

&AtClient
Procedure AddDeliveryMethodTemplate(Command)
	AddTemplate("[DeliveryMethod]");
EndProcedure

&AtClient
Procedure AddDefaultTemplate(Command)
	OverwriteSubject = (CurrentItem = Items.EmailSubject);
	
	If OverwriteSubject Then
		SubjectValue = Object.EmailSubject;
		DefaultTemplate = Cache.Templates.Subject;
	Else
		If Object.HTMLFormatEmail Then
			SubjectValue = EmailTextFormattedDocument.GetText();
		Else
			SubjectValue = Object.EmailText;
		EndIf;
		SubjectValue = TrimAll(SubjectValue);
		DefaultTemplate = Cache.Templates.Text;
	EndIf;
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("SubjectRefill", OverwriteSubject);
	AdditionalParameters.Insert("DefaultTemplate", DefaultTemplate);
	
	If SubjectValue = "" Then
		// Empty subject  - required to be filled without questions.
		AddDefaultTemplateEnd(1, AdditionalParameters);
		
	ElsIf SubjectValue = DefaultTemplate Then
		// Subject matches the template — no fill required.
		
		If OverwriteSubject Then
			WarningText = NStr("ru = 'Тема письма уже соответствует шаблону по умолчанию.'; en = 'Email subject already matches the default template.'; pl = 'Email subject already matches the default template.';de = 'Email subject already matches the default template.';ro = 'Email subject already matches the default template.';tr = 'Email subject already matches the default template.'; es_ES = 'Email subject already matches the default template.'");
		Else
			WarningText = NStr("ru = 'Текст письма уже соответствует шаблону по умолчанию.'; en = 'Email text already matches the default template.'; pl = 'Email text already matches the default template.';de = 'Email text already matches the default template.';ro = 'Email text already matches the default template.';tr = 'Email text already matches the default template.'; es_ES = 'Email text already matches the default template.'");
		EndIf;
		ShowMessageBox(, WarningText);
		
	Else
		// Subject is not empty - you need to ask a replacement for a standard template.
		
		If OverwriteSubject Then
			QuestionTitle = NStr("ru = 'Добавить в тему письма шаблон по умолчанию'; en = 'Add default template to the email subject'; pl = 'Add default template to the email subject';de = 'Add default template to the email subject';ro = 'Add default template to the email subject';tr = 'Add default template to the email subject'; es_ES = 'Add default template to the email subject'");
			QuestionText = NStr("ru = 'Заменить тему письма на шаблон по умолчанию?'; en = 'Replace the email subject with the default template?'; pl = 'Replace the email subject with the default template?';de = 'Replace the email subject with the default template?';ro = 'Replace the email subject with the default template?';tr = 'Replace the email subject with the default template?'; es_ES = 'Replace the email subject with the default template?'");
		Else
			QuestionTitle = NStr("ru = 'Добавить в текст письма шаблон по умолчанию'; en = 'Add default template to the email body'; pl = 'Add default template to the email body';de = 'Add default template to the email body';ro = 'Add default template to the email body';tr = 'Add default template to the email body'; es_ES = 'Add default template to the email body'");
			QuestionText = NStr("ru = 'Заменить текст письма на шаблон по умолчанию?'; en = 'Replace the email text with the default template?'; pl = 'Replace the email text with the default template?';de = 'Replace the email text with the default template?';ro = 'Replace the email text with the default template?';tr = 'Replace the email text with the default template?'; es_ES = 'Replace the email text with the default template?'");
		EndIf;
		
		Buttons = New ValueList;
		Buttons.Add(1, NStr("ru = 'Заменить'; en = 'Replace'; pl = 'Replace';de = 'Replace';ro = 'Replace';tr = 'Replace'; es_ES = 'Replace'"));
		Buttons.Add(2, NStr("ru = 'Добавить'; en = 'Add'; pl = 'Add';de = 'Add';ro = 'Add';tr = 'Add'; es_ES = 'Add'"));
		Buttons.Add(DialogReturnCode.Cancel);
		
		Handler = New NotifyDescription("AddDefaultTemplateEnd", ThisObject, AdditionalParameters);
		
		ShowQueryBox(Handler, QuestionText, Buttons, 60, 1, QuestionTitle);
	EndIf;
	
EndProcedure

&AtClient
Procedure TemplatePreview(Command)
	AddTemplate();
	
	If CurrentItem = Items.EmailTextFormattedDocument Then
		Template = EmailTextFormattedDocument.GetText();
	ElsIf CurrentItem = Items.EmailText Then
		Template = Object.EmailText;
	ElsIf CurrentItem = Items.EmailSubject Then
		Template = Object.EmailSubject;
	EndIf;
	
	GeneratedReports = "";
	For Each RowReport In Object.Reports Do
		GeneratedReports = GeneratedReports
		+ Chars.LF
		+ RowReport.Presentation
		+ " (" 
		+ ?(RowReport.Formats = DefaultFormatsPresentation(), DefaultFormats, RowReport.Formats) 
		+ ")";
	EndDo;
	GeneratedReports = TrimL(GeneratedReports);
	
	DeliveryParameters = New Structure("NotifyOnly, HTMLFormatEmail, Folder, NetworkDirectoryWindows, Server, Port, Directory");
	FillPropertyValues(DeliveryParameters, Object);
	DeliveryParameters.Insert("ExecutedToFolder", Object.UseDirectory);
	DeliveryParameters.Insert("ExecutedToNetworkDirectory", Object.UseNetworkDirectory);
	DeliveryParameters.Insert("ExecutedAtFTP", Object.UseFTPResource);
	DeliveryMethod = ReportsDistributionClientServer.DeliveryMethodsPresentation(DeliveryParameters);
	
	TemplateParameters = New Structure;
	TemplateParameters.Insert("BulkEmailDescription", Object.Description);
	TemplateParameters.Insert("Author",                Object.Author);
	TemplateParameters.Insert("SystemTitle",     Cache.SystemTitle);
	TemplateParameters.Insert("ExecutionDate",       CommonClient.SessionDate());
	TemplateParameters.Insert("GeneratedReports", GeneratedReports);
	TemplateParameters.Insert("DeliveryMethod",       DeliveryMethod);
	
#If NOT MobileClient Then
	TextDocument = New TextDocument;
	TextDocument.SetText(ReportsDistributionClientServer.FillTemplate(Template, TemplateParameters));
	TextDocument.Show();
#EndIf
EndProcedure

&AtClient
Procedure CheckPublication(Command)
	// Transport parameters
	DeliveryParameters = New Structure;
	//
	DeliveryParameters.Insert("UseDirectory",            Object.UseDirectory);
	DeliveryParameters.Insert("UseNetworkDirectory",   Object.UseNetworkDirectory);
	DeliveryParameters.Insert("UseFTPResource",        Object.UseFTPResource);
	DeliveryParameters.Insert("UseEmail", False);
	//
	CheckMailing(DeliveryParameters);
EndProcedure

&AtClient
Procedure CheckEmail(Command)
	// Transport parameters
	DeliveryParameters = New Structure;
	//
	DeliveryParameters.Insert("UseDirectory",            False);
	DeliveryParameters.Insert("UseNetworkDirectory",   False);
	DeliveryParameters.Insert("UseFTPResource",        False);
	DeliveryParameters.Insert("UseEmail", True);
	//
	CheckMailing(DeliveryParameters);
EndProcedure

&AtClient
Procedure ChangeTextTypeToHTML(Command)
	Modified = True;
	Object.HTMLFormatEmail = True;
	EmailTextFromHTML = TrimAll(EmailTextFormattedDocument.GetText());
	If EmailTextFromHTML <> Object.EmailText Then
		EmailTextFormattedDocument.Delete();
		EmailTextFormattedDocument.Add(Object.EmailText, FormattedDocumentItemType.Text);
	EndIf;
	CurrentItem = Items.EmailTextFormattedDocument;
	VisibilityAvailabilityCorrectness(ThisObject, "HTMLFormatEmail");
EndProcedure

&AtClient
Procedure ChangeTextTypeToNormal(Command)
	Modified = True;
	Object.HTMLFormatEmail = False;
	EmailTextFromHTML = TrimAll(EmailTextFormattedDocument.GetText());
	If Object.EmailText <> EmailTextFromHTML Then
		Object.EmailText = EmailTextFromHTML;
	EndIf;
	CurrentItem = Items.EmailText;
	VisibilityAvailabilityCorrectness(ThisObject, "HTMLFormatEmail");
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Additional page

&AtClient
Procedure ClearAllSendIfBlank(Command)
	If Object.Reports.Count() > 0 Then
		Modified = True;
		For Each StrReport In Object.Reports Do
			StrReport.SendIfEmpty = False;
			StrReport.DoNotSendIfEmpty = True;
		EndDo;
	EndIf;
EndProcedure

&AtClient
Procedure SelectAllSendIfBlank(Command)
	If Object.Reports.Count() > 0 Then
		Modified = True;
		For Each StrReport In Object.Reports Do
			StrReport.SendIfEmpty = True;
			StrReport.DoNotSendIfEmpty = False;
		EndDo;
	EndIf;
EndProcedure

#EndRegion

#Region Private

////////////////////////////////////////////////////////////////////////////////
// Client.

&AtClient
Procedure UserSettingStartChoice(StandardProcessing)
	If Items.ReportSettingsPages.CurrentPage <> Items.ComposerPage Then
		Return;
	EndIf;
	Report = Items.Reports.CurrentData;
	If Report = Undefined Or TypeOf(Report.Report) <> Type("CatalogRef.ReportsOptions") Then
		Return;
	EndIf;
	DCID = Items.UserSettings.CurrentRow;
	Handler = New NotifyDescription("SelectUserSettingsCompletion", ThisObject);
	ReportMailingClientOverridable.OnSettingChoiceStart(Report, DCSettingsComposer, DCID, StandardProcessing, Handler);
EndProcedure

&AtClient
Procedure SelectUserSettingsCompletion(Result, ExecutionParameters) Export
	If TypeOf(Result) = Type("DataCompositionUserSettings") Then
		DCSettingsComposer.LoadUserSettings(Result);
	Else
		Return;
	EndIf;
	Report = Items.Reports.CurrentData;
	If Report = Undefined Or TypeOf(Report.Report) <> Type("CatalogRef.ReportsOptions") Then
		Return;
	EndIf;
	Report.ChangesMade = True;
EndProcedure

&AtClient
Procedure BulkEmailRecipientsClickCompletion(Result, Parameter) Export
	If Result = Undefined Then
		Return;
	EndIf;
	
	Object.RecipientEmailAddressKind = Result.RecipientEmailAddressKind;
	Object.Recipients.Clear();
	For Each Item In Result.Recipients Do 
		NewRow = Object.Recipients.Add();
		NewRow.Recipient = Item.Recipient;
		NewRow.Excluded = Item.Excluded;
	EndDo;
	
	VisibilityAvailabilityCorrectness(ThisObject, "BulkEmailRecipients");
	Modified = True;
EndProcedure

&AtClient
Procedure MailingRecipientsTypeChoiceChoiceProcessingEnd(Response, AdditionalParameters) Export
	If Response = DialogReturnCode.Yes Then
		Object.Recipients.Clear();
		MailingRecipientType = AdditionalParameters.SelectedValue;
		Modified = True;
		MailingRecipientsTypeChoiceOnChange(Undefined);
		VisibilityAvailabilityCorrectness(ThisObject, "BulkEmailRecipients");
	EndIf;
EndProcedure

&AtClient
Procedure AddDefaultTemplateEnd(Response, AdditionalParameters) Export
	DefaultTemplate = AdditionalParameters.DefaultTemplate;
	If Response = 1 Then
		If AdditionalParameters.SubjectRefill Then
			Object.EmailSubject = DefaultTemplate;
		Else
			If Object.HTMLFormatEmail Then
				EmailTextFormattedDocument.Delete();
				EmailTextFormattedDocument.Add(DefaultTemplate, FormattedDocumentItemType.Text);
			Else
				Object.EmailText = DefaultTemplate;
			EndIf;
		EndIf;
	ElsIf Response = 2 Then
		AddTemplate(DefaultTemplate);
	EndIf;
EndProcedure

&AtClient
Procedure CheckMailingAfterResponseToQuestion(Response, DeliveryParameters) Export
	If Response = 1 Or Modified Then
		If Response = 1 Then
			Object.Prepared = True;
		EndIf;
		WriteParameters = New Structure;
		WriteParameters.Insert("CommandName", "CommandCheckMailing");
		WriteParameters.Insert("DeliveryParameters", DeliveryParameters);
		WriteAtClient(Undefined, WriteParameters);
		Return;
	ElsIf Response <> -1 Then
		Return;
	EndIf;
	
	// Clear message window.
	ClearMessages();
	
	// Generate delivery parameters.
	DeliveryParameters.Insert("BulkEmail", Object.Description);
	
	// Folder.
	If DeliveryParameters.UseDirectory Then
		DeliveryParameters.Insert("Folder", Object.Folder);
	EndIf;
	
	// Network folder.
	If DeliveryParameters.UseNetworkDirectory Then
		DeliveryParameters.Insert("NetworkDirectoryWindows", Object.NetworkDirectoryWindows);
		DeliveryParameters.Insert("NetworkDirectoryLinux",   Object.NetworkDirectoryLinux);
	EndIf;
	
	// FTP.
	If DeliveryParameters.UseFTPResource Then
		DeliveryParameters.Insert("Owner",            Object.Ref);
		DeliveryParameters.Insert("Server",              Object.FTPServer);
		DeliveryParameters.Insert("Port",                Object.FTPPort);
		DeliveryParameters.Insert("Username",               Object.FTPUsername);
		If FTPPasswordChanged Then
			DeliveryParameters.Insert("Password", FTPPassword);
		EndIf;
		DeliveryParameters.Insert("Directory",             Object.FTPDirectory);
		DeliveryParameters.Insert("PassiveConnection", Object.FTPPassiveConnection);
	EndIf;
	
	Handler = New NotifyDescription("CheckMailingAfterRecipientsChoice", ThisObject, DeliveryParameters);
	
	// Mail.
	If DeliveryParameters.UseEmail Then
		ReportMailingClient.SelectRecipient(Handler, Object, False, True);
		Return;
	EndIf;
	
	ExecuteNotifyProcessing(Handler, Undefined);
	
EndProcedure

&AtClient
Procedure CheckMailingAfterRecipientsChoice(SelectionResult, DeliveryParameters) Export
	// CheckMailingAfterResponseToQuestion procedure execution result handler.
	If DeliveryParameters.UseEmail Then
		If SelectionResult = Undefined Then
			Return;
		EndIf;
		
		DeliveryParameters.Insert("Account", Object.Account);
		DeliveryParameters.Insert("BCC",  Object.BCC);
		DeliveryParameters.Insert("SubjectTemplate",    NStr("ru = 'Тестовое сообщение 1С:Предприятие'; en = 'Test message from 1C:Enterprise'; pl = 'Test message from 1C:Enterprise';de = 'Test message from 1C:Enterprise';ro = 'Test message from 1C:Enterprise';tr = 'Test message from 1C:Enterprise'; es_ES = 'Test message from 1C:Enterprise'"));
		DeliveryParameters.Insert("TextTemplate",  NStr("ru = 'Это сообщение отправлено системой рассылок 1С:Предприятие.'; en = 'This message is sent by 1C: Enterprise mailing system.'; pl = 'This message is sent by 1C: Enterprise mailing system.';de = 'This message is sent by 1C: Enterprise mailing system.';ro = 'This message is sent by 1C: Enterprise mailing system.';tr = 'This message is sent by 1C: Enterprise mailing system.'; es_ES = 'This message is sent by 1C: Enterprise mailing system.'") + Chars.LF + Cache.SystemTitle);
		DeliveryParameters.Insert("Recipients",    SelectionResult);
		DeliveryParameters.Insert("NotifyOnly", False);
		DeliveryParameters.Insert("FillTransportMethodInMessageTemplate",       False);
		DeliveryParameters.Insert("FillGeneratedReportsInMessageTemplate", False);
		DeliveryParameters.Insert("FillRecipientInSubjectTemplate",                False);
		DeliveryParameters.Insert("FillRecipientInMessageTemplate",           False);
		DeliveryParameters.Insert("EmailParameters", New Structure);
		DeliveryParameters.Insert("Connection",      Undefined);
		
	EndIf;
	
	DeliveryParameters.Insert("AddReferences", "");
	
	ExecutionResult = CheckTransportMethod(Object.Ref, DeliveryParameters);
	StandardSubsystemsClient.ShowQuestionToUser(Undefined, 
		StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = '%1
			|%2'; 
			|en = '%1
			|%2'; 
			|pl = '%1
			|%2';
			|de = '%1
			|%2';
			|ro = '%1
			|%2';
			|tr = '%1
			|%2'; 
			|es_ES = '%1
			|%2'"), ExecutionResult.Text, ExecutionResult.More), QuestionDialogMode.OK);
	
EndProcedure

&AtClient
Procedure FillScheduleByTemplateCompletion(SelectedItem, AdditionalParameters) Export
	If SelectedItem <> Undefined Then
		FillScheduleByOption(SelectedItem.Value, True);
	EndIf;
EndProcedure

&AtClient
Procedure AddChangeMailingDateTemplateEnd(ResultRow, Variables) Export
	If ResultRow = Undefined Then
		Return;
	EndIf;
	
	NewFragment   = Variables.Prefix + ResultRow + Variables.Postfix;
	PreviousFragment  = Variables.Prefix + Variables.FormatText + Variables.Postfix;
	
	If Variables.Item = Items.EmailTextFormattedDocument Then
		ReplacementExecuted = False;
		If Variables.PreviousFragmentFound Then
			SearchResult = EmailTextFormattedDocument.FindText(PreviousFragment);
			If SearchResult <> Undefined Then
				FoundItems = EmailTextFormattedDocument.GetItems(SearchResult.BeginBookmark, SearchResult.EndBookmark);
				For Each FDText In FoundItems Do
					If StrFind(FDText.Text, PreviousFragment) > 0 Then
						FDText.Text = StrReplace(FDText.Text, PreviousFragment, NewFragment);
						ReplacementExecuted = True;
						Break;
					EndIf;
				EndDo;
			EndIf;
		EndIf; // Variable.PreviousFragmentFound
		If Not ReplacementExecuted Then
			If TrimAll(Variables.OldText) = PreviousFragment Then
				// For a formatted document, the SelectedText property is used in those rare cases when it is safe 
				//  for text to be edited.
				Variables.Item.SelectedText = NewFragment;
			Else
				EmailTextFormattedDocument.Add(NewFragment, FormattedDocumentItemType.Text);
			EndIf;
		EndIf;
	Else
		If Variables.PreviousFragmentFound Then
			If ResultRow = Variables.FormatText Then
				Return;
			EndIf;
			Variables.Item.SelectedText = StrReplace(Variables.OldText, PreviousFragment, NewFragment);
		Else
			Variables.Item.SelectedText = Variables.OldText + NewFragment;
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure SelectEndFormat(FormatsList, Variables) Export
	If FormatsList = Undefined Then
		Return;
	EndIf;
	
	// Changes check
	FormatsMatch = True;
	For Index = 1 To FormatsList.Count() Do
		If FormatsList[Index - 1].Check <> Variables.FormatsListCopy[Index - 1].Check Then
			FormatsMatch = False;
			Break;
		EndIf;
	EndDo;
	If FormatsMatch Then
		Return;
	EndIf;
	
	FormatPresentation = "";
	
	// Clear existing records.
	ClearFormat(Variables.ReportRef);
	
	// Add marked formats.
	For Each ListItem In FormatsList Do
		If ListItem.Check Then
			StringFormat = Object.ReportFormats.Add();
			StringFormat.Report  = Variables.ReportRef;
			StringFormat.Format = ListItem.Value;
			FormatPresentation = FormatPresentation + ?(FormatPresentation = "", "", ", ") + String(ListItem.Value);
		EndIf;
	EndDo;
	
	If Variables.IsDefaultFormat AND FormatPresentation = "" Then
		FormatPresentation = DefaultFormatsListPresentation;
	EndIf;
	
	ExecuteNotifyProcessing(Variables.ResultHandler, FormatPresentation);
EndProcedure

&AtClient
Procedure ReportFormatsEndChoiceFormat(FormatPresentation, Variables) Export
	If FormatPresentation <> Undefined Then
		Variables.ReportsRow.Formats = FormatPresentation;
	EndIf;
EndProcedure

&AtClient
Procedure DefaultFormatsSelectionCompletion(FormatPresentation, Variables) Export
	If FormatPresentation <> Undefined Then
		DefaultFormats = FormatPresentation;
	EndIf;
	VisibilityAvailabilityCorrectness(ThisObject, "DefaultFormats");
EndProcedure

&AtClient
Procedure AfterChangeSchedule(ScheduleResult, AdditionalParameters) Export
	If ScheduleResult <> Undefined Then
		Modified = True;
		Schedule = ScheduleResult;
		VisibilityAvailabilityCorrectness(ThisObject, "Schedule");
	EndIf;
EndProcedure

&AtClient
Function ChoicePickupDragItemToTabularSection(PickingItem, TabularSection, AttributeName, FillingStructure, Uniqueness = True)
	
	If (TypeOf(PickingItem) = Type("Structure")) Or TypeOf(PickingItem) = Type("FormDataCollectionItem") Then
		If PickingItem.Property(AttributeName) Then
			AttributeValue = PickingItem[AttributeName];
		Else
			Return Undefined;
		EndIf;
	Else // (CatalogRef.*) drag from the pickup or selection form.
		AttributeValue = PickingItem;
	EndIf;
	
	// Attributes uniqueness in the table borders is required.
	FoundItems = TabularSection.FindRows(New Structure(AttributeName, AttributeValue));
	
	If Uniqueness AND FoundItems.Count() > 0 Then
		Return Undefined;
	EndIf;
	
	TableRow = TabularSection.Add();
	TableRow[AttributeName] = AttributeValue;
	FillPropertyValues(TableRow, FillingStructure);
	If (TypeOf(PickingItem) = Type("Structure")) Then
		For Each KeyAndValue In PickingItem Do
			If FillingStructure.Property(KeyAndValue.Key) Then
				PickingItem.Delete(PickingItem.Key);
			EndIf;
		EndDo;
		FillPropertyValues(TableRow, PickingItem);
	EndIf;
	
	Return TableRow;
EndFunction

&AtClient
Function ChoicePickupDragToTabularSection(SelectedValue, TabularSection, AttributeName, FillingStructure, IDs = False)
	Modified = True;
	NewRowArray = New Array;
	
	If TypeOf(SelectedValue) = Type("Array") Then
		For Each PickingItem In SelectedValue Do
			Result = ChoicePickupDragItemToTabularSection(PickingItem, TabularSection, AttributeName, FillingStructure);
			If Result <> Undefined Then
				NewRowArray.Add(?(IDs, Result.GetID(), Result));
			EndIf;
		EndDo;
	Else
		Result = ChoicePickupDragItemToTabularSection(SelectedValue, TabularSection, AttributeName, FillingStructure);
		If Result <> Undefined Then
			NewRowArray.Add(?(IDs, Result.GetID(), Result));
		EndIf;
	EndIf;
	Return NewRowArray;
EndFunction

&AtClient
Procedure ChooseFormat(ReportRef, ResultHandler)
	// To store all formats selected by the user, using the ReportFormats tabular section.
	// At the same time, an empty value of the Report attribute is used for default formats.
	// Depending on the type of deployment, the Report attribute can take the Undefined or EmptyRef value.
	IsDefaultFormat = Not ValueIsFilled(ReportRef);
	
	FoundItems = Object.ReportFormats.FindRows(New Structure("Report", ReportRef));
	If FoundItems.Count() > 0 Then
		FormatsList.FillChecks(False);
		For Each StringFormat In FoundItems Do
			FormatsList.FindByValue(StringFormat.Format).Check = True;
		EndDo;
	Else
		FormatsList = DefaultFormatsList.Copy();
		If Not IsDefaultFormat Then
			FoundItems = Object.ReportFormats.FindRows(New Structure("Report", Cache.EmptyReportValue));
			If FoundItems.Count() > 0 Then
				FormatsList.FillChecks(False);
				For Each StringFormat In FoundItems Do
					FormatsList.FindByValue(StringFormat.Format).Check = True;
				EndDo;
			EndIf;
		EndIf;
	EndIf;
	
	If IsDefaultFormat Then
		DialogTitle = NStr("ru = 'Выберите форматы по умолчанию'; en = 'Select default formats'; pl = 'Select default formats';de = 'Select default formats';ro = 'Select default formats';tr = 'Select default formats'; es_ES = 'Select default formats'");
	Else
		DialogTitle = NStr("ru = 'Выберите форматы для отчета ""%1""'; en = 'Select formats for report ""%1""'; pl = 'Select formats for report ""%1""';de = 'Select formats for report ""%1""';ro = 'Select formats for report ""%1""';tr = 'Select formats for report ""%1""'; es_ES = 'Select formats for report ""%1""'");
		DialogTitle = StringFunctionsClientServer.SubstituteParametersToString(DialogTitle, String(ReportRef));
	EndIf;
	
	Variables = New Structure;
	Variables.Insert("ReportRef",        ReportRef);
	Variables.Insert("FormatsListCopy",  FormatsList.Copy());
	Variables.Insert("IsDefaultFormat", IsDefaultFormat);
	Variables.Insert("ResultHandler", ResultHandler);
	Handler = New NotifyDescription("SelectEndFormat", ThisObject, Variables);
	
	FormatsList.ShowCheckItems(Handler, DialogTitle);
	
EndProcedure

&AtClient
Procedure ClearFormat(ReportRef)
	Modified = True;
	FoundItems = Object.ReportFormats.FindRows(New Structure("Report", ReportRef));
	For Each StringFormat In FoundItems Do
		Object.ReportFormats.Delete(StringFormat);
	EndDo;
EndProcedure

&AtClient
Procedure AddTemplate(TextTemplate = Undefined, SkipEmailSubject = False)
	// Checking and setting focus on the item.
	If SkipEmailSubject Or Not (CurrentItem = Items.EmailSubject Or CurrentItem = Items.ArchiveName) Then
		If Object.HTMLFormatEmail Then
			If CurrentItem <> Items.EmailTextFormattedDocument Then
				CurrentItem = Items.EmailTextFormattedDocument;
			EndIf;
		Else
			If CurrentItem <> Items.EmailText Then
				CurrentItem = Items.EmailText;
			EndIf;
		EndIf;
	EndIf;
	
	If TextTemplate = Undefined Then
		// Just preparing to add a template (switching current item).
		Return;
	EndIf;
	
	If CurrentItem.SelectedText = "" Then
		// Formatted document incorrectly fulfills property changes.
		//  SelectedText if nothing is selected, therefore an alternative method of text adding is used.
		//  
		If CurrentItem = Items.EmailTextFormattedDocument Then
			EmailTextFormattedDocument.Add(TextTemplate, FormattedDocumentItemType.Text);
		Else
			CurrentItem.SelectedText = TextTemplate;
		EndIf;
	Else
		CurrentItem.SelectedText = CurrentItem.SelectedText + TextTemplate;
	EndIf;
EndProcedure

&AtClient
Function ChangeArrayContent(Add, Item, Val Array)
	Index = Array.Find(Item);
	If Add AND Index = Undefined Then
		UBoundPlus1 = ?(Array.Count() >= Item, Item, Array.Count());
		For Index = 1 To UBoundPlus1 Do
			If Array[UBoundPlus1 - Index] < Item Then
				Array.Insert(UBoundPlus1 - Index + 1, Item);
				Return Array;
			EndIf;
		EndDo;
		Array.Insert(0, Item);
	ElsIf Not Add AND Index <> Undefined Then
		Array.Delete(Index);
	EndIf;
	Return Array;
EndFunction

&AtClient
Procedure ChangeScheduleInDialog()
#If NOT MobileClient Then
	Handler = New NotifyDescription("AfterChangeSchedule", ThisObject);
	ScheduleDialog = New ScheduledJobDialog(Schedule);
	ScheduleDialog.Show(Handler);
#EndIf
EndProcedure

&AtClient
Procedure EvaluateAdditionalDeliveryMethodsCheckBoxes()
	Object.UseDirectory        = Publish AND (OtherDeliveryMethod = "UseDirectory");
	Object.UseNetworkDirectory = Publish AND (OtherDeliveryMethod = "UseNetworkDirectory");
	Object.UseFTPResource    = Publish AND (OtherDeliveryMethod = "UseFTPResource");
EndProcedure

&AtClient
Procedure CheckMailing(DeliveryParameters)
	// Clear message window.
	ClearMessages();
	
	// Check the data readiness and the need for writing.
	If Not Object.Prepared Or Object.Ref.IsEmpty() Then
		QuestionTitle = NStr("ru = 'Проверка способа доставки'; en = 'Check delivery method'; pl = 'Check delivery method';de = 'Check delivery method';ro = 'Check delivery method';tr = 'Check delivery method'; es_ES = 'Check delivery method'");
		If Not Object.Prepared Then
			QuestionText = NStr("ru = 'Перед проверкой рассылка должна быть подготовлена.
			|Нажмите ""Продолжить"", чтобы включить флажок ""Подготовлена"" и записать рассылку.'; 
			|en = 'Please prepare bulk email before the check.
			|Click ""Continue"" to select the ""Prepared"" check box and write bulk email.'; 
			|pl = 'Please prepare bulk email before the check.
			|Click ""Continue"" to select the ""Prepared"" check box and write bulk email.';
			|de = 'Please prepare bulk email before the check.
			|Click ""Continue"" to select the ""Prepared"" check box and write bulk email.';
			|ro = 'Please prepare bulk email before the check.
			|Click ""Continue"" to select the ""Prepared"" check box and write bulk email.';
			|tr = 'Please prepare bulk email before the check.
			|Click ""Continue"" to select the ""Prepared"" check box and write bulk email.'; 
			|es_ES = 'Please prepare bulk email before the check.
			|Click ""Continue"" to select the ""Prepared"" check box and write bulk email.'");
		Else
			QuestionText = NStr("ru = 'Перед проверкой рассылка должна быть записана.
			|Нажмите ""Продолжить"", чтобы записать рассылку.'; 
			|en = 'Please write bulk email before the check.
			|To write bulk email, click ""Continue"".'; 
			|pl = 'Please write bulk email before the check.
			|To write bulk email, click ""Continue"".';
			|de = 'Please write bulk email before the check.
			|To write bulk email, click ""Continue"".';
			|ro = 'Please write bulk email before the check.
			|To write bulk email, click ""Continue"".';
			|tr = 'Please write bulk email before the check.
			|To write bulk email, click ""Continue"".'; 
			|es_ES = 'Please write bulk email before the check.
			|To write bulk email, click ""Continue"".'");
		EndIf;
		
		Buttons = New ValueList;
		Buttons.Add(1, NStr("ru = 'Продолжить'; en = 'Continue'; pl = 'Continue';de = 'Continue';ro = 'Continue';tr = 'Continue'; es_ES = 'Continue'"));
		Buttons.Add(DialogReturnCode.Cancel);
		
		Handler = New NotifyDescription("CheckMailingAfterResponseToQuestion", ThisObject, DeliveryParameters);
		ShowQueryBox(Handler, QuestionText, Buttons, 60, 1, QuestionTitle);
	Else
		CheckMailingAfterResponseToQuestion(-1, DeliveryParameters);
	EndIf;
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Client, Server

&AtClientAtServerNoContext
Procedure SwitchPage(Items, PageSetName, CurrentPageSuffix)
	Items[PageSetName].CurrentPage = Items[PageSetName + CurrentPageSuffix];
EndProcedure

&AtClientAtServerNoContext
Function PasswordHidden()
	Return "********";
EndFunction

&AtClientAtServerNoContext
Procedure VisibilityAvailabilityCorrectness(Form, Changes = "")
	Object = Form.Object;
	Items = Form.Items;
	
	If Changes = "" Or Changes = "FTPServerAndDirectory" Then
		If ValueIsFilled(Object.FTPServer) Then
			AddressPresentation = "ftp://";
			If ValueIsFilled(Object.FTPUsername) Then
				AddressPresentation = AddressPresentation + Object.FTPUsername + ?(ValueIsFilled(Form.FTPPassword), ":" + PasswordHidden(), "") + "@";
			EndIf;
			Form.FTPServerAndDirectory = AddressPresentation + Object.FTPServer + ":" + Format(Object.FTPPort, "NZ=0; NG=0") + Object.FTPDirectory;
		Else
			Form.FTPServerAndDirectory = "";
		EndIf;
	EndIf;
	
	If Changes = ""
		Or Changes = "Prepared"
		Or Changes = "ExecuteOnSchedule"
		Or Changes = "BulkEmailType"
		Or Changes = "Publish"
		Or Changes = "UseEmail" Then
		
		Items.Reports.AutoMarkIncomplete         = Object.Prepared;
		Items.ReportFormats.AutoMarkIncomplete = Object.Prepared;
		
		Items.SchedulePeriodicity.AutoMarkIncomplete = Object.Prepared AND Object.ExecuteOnSchedule;
		
		Items.NetworkDirectoryWindows.AutoMarkIncomplete = Object.Prepared AND Form.Publish;
		Items.NetworkDirectoryLinux.AutoMarkIncomplete   = Object.Prepared AND Form.Publish;
		Items.FTPServerAndDirectory.AutoMarkIncomplete     = Object.Prepared AND Form.Publish;
		Items.Folder.AutoMarkIncomplete                 = Object.Prepared AND Form.Publish;
		
		Items.AuthorMailAddressKind.AutoMarkIncomplete = Object.Prepared AND Object.Personal;
		Items.Account.AutoMarkIncomplete = Object.Prepared AND Object.UseEmail;
		
	EndIf;
	
	If Changes = "" Or Changes = "BulkEmailType" Then
		// Correctness
		If Object.Personal AND Object.Personalized Then
			Object.Personal = False;
		EndIf;
		
		PersonalMailingsGroupUsed = (Object.Parent = Form.Cache.PersonalMailingsGroup);
		If Object.Personal <> PersonalMailingsGroupUsed Then
			SetFormModified(Form, "Parent", , 
				NStr("ru = 'Группа установлена в соответствии с видом рассылки'; en = 'Group is set according to bulk email kind'; pl = 'Group is set according to bulk email kind';de = 'Group is set according to bulk email kind';ro = 'Group is set according to bulk email kind';tr = 'Group is set according to bulk email kind'; es_ES = 'Group is set according to bulk email kind'"));
			Object.Parent = ?(Object.Personal, Form.Cache.PersonalMailingsGroup, Undefined);
		EndIf;
		
		If Object.Personal Then
			CommonMailing = False;
			Form.BulkEmailType = "Personal";
		ElsIf Object.Personalized Then
			CommonMailing = False;
			Form.BulkEmailType = "Personalized";
		Else
			CommonMailing = True;
			Form.BulkEmailType = "Total";
		EndIf;
		
		If Not CommonMailing Then
			Object.UseDirectory            = False;
			Object.UseNetworkDirectory   = False;
			Object.UseFTPResource        = False;
			Object.UseEmail = True;
		EndIf;
		
		// Visibility & Availability
		Items.Parent.Enabled = Not Object.Personal;
		SwitchPage(Items, "BulkEmailTypes", ?(Object.Personal, "Personal", "ForRecipients"));
		Items.OtherDeliveryMethods.Visible = CommonMailing;
		Items.UseEmail.Visible = CommonMailing;
		
		If Object.Personal Then
			Items.BulkEmailRecipients.Visible = False;
		Else
			Items.BulkEmailRecipients.Visible = True;
			If Not CommonMailing Then
				Items.BulkEmailRecipients.TitleLocation = FormItemTitleLocation.Auto;
			Else
				Items.BulkEmailRecipients.TitleLocation = FormItemTitleLocation.None;
			EndIf;
		EndIf;
		
		// Restore parameters
		If Object.UseDirectory Then
			Form.OtherDeliveryMethod = "UseDirectory";
			Form.Publish = True;
		ElsIf Object.UseNetworkDirectory Then
			Form.OtherDeliveryMethod = "UseNetworkDirectory";
			Form.Publish = True;
		ElsIf Object.UseFTPResource Then
			Form.OtherDeliveryMethod = "UseFTPResource";
			Form.Publish = True;
		Else
			Form.OtherDeliveryMethod = Items.OtherDeliveryMethod.ChoiceList[0].Value;
			Form.Publish = False;
		EndIf;
		
		Items.UseMailingRecipientInReport1Setting.Visible = Object.Personalized;
		Items.UseMailingRecipientInReport2Setting.Visible = Object.Personalized;
		Items.UseMailingRecipientInReport3Setting.Visible = Object.Personalized;
		Items.UseMailingRecipientInReport4Setting.Visible = Object.Personalized;
	EndIf;
	
	If Changes = "" Or Changes = "Reports" Then
		ReportCount = Form.Object.Reports.Count();
		If ReportCount > 0 Then
			Items.ReportsPage.Title = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'Отчеты (%1)'; en = 'Reports (%1)'; pl = 'Reports (%1)';de = 'Reports (%1)';ro = 'Reports (%1)';tr = 'Reports (%1)'; es_ES = 'Reports (%1)'"), 
				Format(ReportCount, "NZ=0; NG="));
		Else
			Items.ReportsPage.Title = NStr("ru = 'Отчеты'; en = 'Reports'; pl = 'Reports';de = 'Reports';ro = 'Reports';tr = 'Reports'; es_ES = 'Reports'") ;
		EndIf;
	EndIf;
	
	If Changes = "" Or Changes = "OtherDeliveryMethod" Or Changes = "Publish" Or Changes = "BulkEmailType" Then
		Items.OtherDeliveryMethod.Enabled  = Form.Publish;
		Items.DeliveryParameters.Enabled     = Form.Publish;
		Items.DeliveryParameters.CurrentPage = Items[Form.OtherDeliveryMethod];
		Items.CheckPublication.Enabled   = Form.Publish;
	EndIf;
	
	If Changes = "" Or Changes = "UseEmail" Or Changes = "BulkEmailType" Then
		Items.AccountGroup.Enabled = Object.UseEmail;
		Items.EmailParameters.Enabled = Object.UseEmail;
		Items.AdditionalParametersOfMailing.Enabled = Object.UseEmail;
		Items.BulkEmailRecipients.Enabled = Object.UseEmail;
	EndIf;
	
	If Changes = "" Or Changes = "BulkEmailRecipients" Then
		RecipientsPresentation = RecipientsPresentation(Form);
		Form.BulkEmailRecipients = RecipientsPresentation.Short;
		Items.BulkEmailRecipients.ToolTip = RecipientsPresentation.Full;
	EndIf;
	
	If Changes = ""
		Or Changes = "NotifyOnly"
		Or Changes = "UseEmail"
		Or Changes = "OtherDeliveryMethod"
		Or Changes = "Publish"
		Or Changes = "BulkEmailType" Then
		
		Items.NotifyOnly.Visible = (Object.UseEmail AND Form.Publish);
		If Not Items.NotifyOnly.Visible Then
			Object.NotifyOnly = False;
		EndIf;
		
		TransportMethods = "";
		If Object.UseDirectory Then
			TransportMethods = NStr("ru = 'папка'; en = 'folder'; pl = 'folder';de = 'folder';ro = 'folder';tr = 'folder'; es_ES = 'folder'");
		EndIf;
		If Object.UseNetworkDirectory Then
			TransportMethods = NStr("ru = 'сетевой каталог'; en = 'network directory'; pl = 'network directory';de = 'network directory';ro = 'network directory';tr = 'network directory'; es_ES = 'network directory'");
		EndIf;
		If Object.UseFTPResource Then
			TransportMethods = NStr("ru = 'FTP'; en = 'FTP'; pl = 'FTP';de = 'FTP';ro = 'FTP';tr = 'FTP'; es_ES = 'FTP'");
		EndIf;
		If Object.UseEmail AND Not Object.NotifyOnly Then
			TransportMethods = TransportMethods + ?(TransportMethods = "", NStr("ru = 'эл. почта'; en = 'email'; pl = 'email';de = 'email';ro = 'email';tr = 'email'; es_ES = 'email'"), " "+ NStr("ru = 'и эл. почта'; en = 'and email'; pl = 'and email';de = 'and email';ro = 'and email';tr = 'and email'; es_ES = 'and email'"));
		EndIf;
		
		Items.DeliveryPage.Title = StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = 'Доставка (%1)'; en = 'Delivery (%1)'; pl = 'Delivery (%1)';de = 'Delivery (%1)';ro = 'Delivery (%1)';tr = 'Delivery (%1)'; es_ES = 'Delivery (%1)'"), TransportMethods);
	EndIf;
	
	If Changes = "" Or Changes = "HTMLFormatEmail" Then
		SwitchPage(Items, "EmailTextPages", ?(Object.HTMLFormatEmail, "HTML", "NormalText"));
	EndIf;
	
	If Changes = "" Or Changes = "AddToArchive" Then
		Items.ArchiveName.Enabled    = Object.AddToArchive;
		Items.ArchivePassword.Enabled = Object.AddToArchive;
	EndIf;
	
	If Changes = "" Or Changes = "ExecuteOnSchedule" Then
		If Object.ExecuteOnSchedule Then
			Items.SchedulePage.Title = NStr("ru = 'Расписание (активно)'; en = 'Schedule (active)'; pl = 'Schedule (active)';de = 'Schedule (active)';ro = 'Schedule (active)';tr = 'Schedule (active)'; es_ES = 'Schedule (active)'");
		Else
			Items.SchedulePage.Title = NStr("ru = 'Расписание (не активно)'; en = 'Schedule (not active)'; pl = 'Schedule (not active)';de = 'Schedule (not active)';ro = 'Schedule (not active)';tr = 'Schedule (not active)'; es_ES = 'Schedule (not active)'");
		EndIf;
		Items.ExecuteOnScheduleParameters.Enabled = Object.ExecuteOnSchedule;
		Items.PeriodicityPages.Enabled           = Object.ExecuteOnSchedule;
	EndIf;
	
	If Changes = "" Or Changes = "SchedulePeriodicity" Then
		
		If Object.SchedulePeriodicity = PredefinedValue("Enum.ReportMailingSchedulePeriodicities.Daily") Then
			EnumerationName = "Daily";
		ElsIf Object.SchedulePeriodicity = PredefinedValue("Enum.ReportMailingSchedulePeriodicities.MonthlyDistribution") Then
			EnumerationName = "MonthlyDistribution";
		ElsIf Object.SchedulePeriodicity = PredefinedValue("Enum.ReportMailingSchedulePeriodicities.Weekly") Then
			EnumerationName = "Weekly";
		Else
			EnumerationName = "Custom";
		EndIf;
		
		Pages = Items.PeriodicityPages.ChildItems;
		VisiblePagesName = "Page"+EnumerationName;
		For Each Page In Pages Do
			Page.Visible = (Page.Name = VisiblePagesName);
		EndDo;
		If EnumerationName = "Custom" Then
			Items.TimeOrChangePages.CurrentPage = Items.ChangeSchedulePage;
		Else
			Items.TimeOrChangePages.CurrentPage = Items.BeginTimePage;
		EndIf;
		
		// Reset parameters that do not match simplified editing bookmarks.
		If Changes = "SchedulePeriodicity"
			AND (EnumerationName = "Daily" 
			Or EnumerationName = "Weekly"
			Or EnumerationName = "MonthlyDistribution") Then
			
			// Common parameters
			Form.Schedule.BeginDate = '00010101';
			Form.Schedule.EndDate  = '00010101';
			Form.Schedule.EndTime = '00010101';
			Form.Schedule.CompletionTime = '00010101';
			Form.Schedule.WeekDayInMonth = 0;
			Form.Schedule.DetailedDailySchedules = New Array;
			Form.Schedule.CompletionInterval = 0;
			Form.Schedule.RepeatPause = 0;
			Form.Schedule.WeeksPeriod = 0;
			Form.Schedule.RepeatPeriodInDay = 0;
			
			If EnumerationName <> "Daily" Then
				Form.Schedule.DaysRepeatPeriod = 1;
			EndIf;
			
			If EnumerationName <> "Weekly" Then
				SelectedWeekDays = New Array;
				For Index = 1 To 7 Do
					SelectedWeekDays.Add(Index);
				EndDo;
				Form.Schedule.WeekDays = SelectedWeekDays;
			EndIf;
			
			If EnumerationName <> "MonthlyDistribution" Then
				AllMonths = New Array;
				For Index = 1 To 12 Do
					AllMonths.Add(Index);
				EndDo;
				Form.Schedule.Months = AllMonths;
				Form.Schedule.DayInMonth = 0;
			EndIf;
		EndIf;
		
		// Restoring parameters on the current bookmark according to schedule parameters.
		If EnumerationName = "Daily" Then
			Form.BeginTime = Form.Schedule.BeginTime;
			Form.DaysRepeatPeriod = Form.Schedule.DaysRepeatPeriod;
		ElsIf EnumerationName = "Weekly" Then
			Form.BeginTime = Form.Schedule.BeginTime;
			For Each KeyAndValue In Form.Cache.Matches.WeekDays Do
				Form[KeyAndValue.Key] = (Form.Schedule.WeekDays.Find(KeyAndValue.Value) <> Undefined);
			EndDo;
		ElsIf EnumerationName = "MonthlyDistribution" Then
			Form.BeginTime = Form.Schedule.BeginTime;
			If Form.Schedule.DayInMonth >= 0 Then
				Form.DayInMonth = Form.Schedule.DayInMonth;
				Items.BegEndOfMonthHyperlink.Title = NStr("ru = 'начала'; en = 'beginning'; pl = 'beginning';de = 'beginning';ro = 'beginning';tr = 'beginning'; es_ES = 'beginning'");
			Else
				Form.DayInMonth = -Form.Schedule.DayInMonth;
				Items.BegEndOfMonthHyperlink.Title = NStr("ru = 'конца'; en = 'end'; pl = 'end';de = 'end';ro = 'end';tr = 'end'; es_ES = 'end'");
			EndIf;
			For Each KeyAndValue In Form.Cache.Matches.Months Do
				Form[KeyAndValue.Key] = (Form.Schedule.Months.Find(KeyAndValue.Value) <> Undefined);
			EndDo;
		EndIf;
		
	EndIf; // Changes = Or Changes = SchedulePeriodicity
	
	If Changes = "" Or Changes = "MonthBeginEnd" Then
		Items.BegEndOfMonthHyperlink.Title = ?(Form.Schedule.DayInMonth >= 0, "beginning", "end");
	EndIf;
	
	If Changes = "" Or Changes = "DefaultFormats" Then
		Items.DefaultFormats.ClearButton = (Form.DefaultFormats <> Form.DefaultFormatsListPresentation);
	EndIf;
	
	If Changes = "" Or Items.Pages.CurrentPage = Items.SchedulePage Then
		Items.SchedulePresentation.Visible = Object.ExecuteOnSchedule;
		If Object.ExecuteOnSchedule Then
			Items.SchedulePresentation.Title = SchedulePresentation(Form.Schedule);
		EndIf;
	EndIf;
EndProcedure

// Generates the presentation of scheduled job schedule.
//
// Parameters:
//   Schedule - JobSchedule - a schedule.
//
// Returns:
//   String - schedule presentation.
//
&AtClientAtServerNoContext
Function SchedulePresentation(Schedule)
	SchedulePresentation = String(Schedule);
	SchedulePresentation = Upper(Left(SchedulePresentation, 1)) + Mid(SchedulePresentation, 2);
	SchedulePresentation = StrReplace(StrReplace(SchedulePresentation, "  ", " "), " ]", "]") + ".";
	Return SchedulePresentation;
EndFunction

&AtClientAtServerNoContext
Function RecipientsPresentation(Form)
	Recipients  = Form.Object.Recipients;
	Enabled  = Recipients.FindRows(New Structure("Excluded", False));
	Disabled = Recipients.FindRows(New Structure("Excluded", True));
	
	DisabledPresentation = ReportsDistributionClientServer.ListPresentation(Disabled, "Recipient", 0);
	Balance       = 75 - DisabledPresentation.LengthOfShort;
	Presentation = ReportsDistributionClientServer.ListPresentation(Enabled, "Recipient", Balance);
	If Presentation.Total = 0 Then
		Presentation.Short = NStr("ru = '<Укажите получателей>'; en = '<Specify recipients>'; pl = '<Specify recipients>';de = '<Specify recipients>';ro = '<Specify recipients>';tr = '<Specify recipients>'; es_ES = '<Specify recipients>'");
		Return Presentation;
	EndIf;
	
	If DisabledPresentation.MaximumExceeded Then
		DisabledPresentation.Short = DisabledPresentation.Short + ", ...";
	EndIf;
	If Presentation.MaximumExceeded Then
		Presentation.Short = Presentation.Short + ", ...";
	EndIf;
	
	If DisabledPresentation.Total > 0 Then
		SplitTemplate = NStr("ru = 'Кроме'; en = 'Except'; pl = 'Except';de = 'Except';ro = 'Except';tr = 'Except'; es_ES = 'Except'")+ ": ";
		Presentation.Full = Presentation.Full + ";" + Chars.LF + SplitTemplate + DisabledPresentation.Full;
		If Presentation.LengthOfShort + DisabledPresentation.LengthOfShort <= 75 Then
			Presentation.Short = Presentation.Short + "; " + SplitTemplate + DisabledPresentation.Short;
		EndIf;
	EndIf;
	If Presentation.MaximumExceeded
		Or DisabledPresentation.MaximumExceeded Then
		If DisabledPresentation.Total > 0 Then
			EndTemplate = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = '(всего %1, исключая %2)'; en = '(total %1 not including %2)'; pl = '(total %1 not including %2)';de = '(total %1 not including %2)';ro = '(total %1 not including %2)';tr = '(total %1 not including %2)'; es_ES = '(total %1 not including %2)'"),
				Presentation.Total,
				DisabledPresentation.Total);
		Else
			EndTemplate = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = '(всего %1)'; en = '(total %1)'; pl = '(total %1)';de = '(total %1)';ro = '(total %1)';tr = '(total %1)'; es_ES = '(total %1)'"),
				Presentation.Total);
		EndIf;
		Presentation.Short = Presentation.Short + "; " + EndTemplate;
	EndIf;
	
	Return Presentation;
EndFunction

&AtClientAtServerNoContext
Procedure SetFormModified(Form, Field = "", DataPath = "", Text = "")
	If Not Form.Modified Then
		Form.FormWasModifiedAtServer = True;
		If ValueIsFilled(Text) Then
			Message = New UserMessage;
			Message.Text = Text;
			Message.Field = Field;
			Message.DataPath = DataPath;
			Message.Message();
		EndIf;
	EndIf;
EndProcedure

&AtClientAtServerNoContext
Function DefaultFormatsPresentation()
	Return NStr("ru = 'по умолчанию'; en = 'default'; pl = 'default';de = 'default';ro = 'default';tr = 'default'; es_ES = 'default'");
EndFunction

&AtClientAtServerNoContext
Function RecipientsSpecified(Recipients)
	
	For Each TableRow In Recipients Do
		If Not TableRow.Excluded Then
			Return True;
		EndIf;
	EndDo;
	
	MessageText = NStr("ru = 'Не выбрано ни одного получателя'; en = 'No recipient is selected'; pl = 'No recipient is selected';de = 'No recipient is selected';ro = 'No recipient is selected';tr = 'No recipient is selected'; es_ES = 'No recipient is selected'");
	
	Message = New UserMessage;
	Message.Text = MessageText;
	Message.Field = "BulkEmailRecipients";
	Message.Message();
	
	Return False;
	
EndFunction

////////////////////////////////////////////////////////////////////////////////
// Server call, Server

&AtServerNoContext
Function RecipientMailAddresses(Recipient, ValueList)
	
	Recipients = New Array;
	Recipients.Add(Recipient);
	ContactInformationTypes = New Array;
	ContactInformationTypes.Add(Enums.ContactInformationTypes.EmailAddress);
	Try
		MailAddresses = ContactsManager.ObjectsContactInformation(Recipients, ContactInformationTypes,, CurrentSessionDate());
	Except
		Return ValueList;
	EndTry;
	
	For Each EmailAddress In MailAddresses Do
		If ValueIsFilled(EmailAddress.Presentation) Then
			ValueList.Add(EmailAddress.Kind, EmailAddress.Presentation + " (" + String(EmailAddress.Kind) + ")");
		EndIf;
	EndDo;
	
	Return ValueList;
	
EndFunction

&AtServerNoContext
Function ChangeFolderAndFilesRight(Folder)
	
	If Common.SubsystemExists("StandardSubsystems.FilesOperations") Then
		ModuleFilesOperationsInternal = Common.CommonModule("FilesOperationsInternal");
		Result = ModuleFilesOperationsInternal.RightToAddFilesToFolder(Folder);
	Else
		Result = True;
	EndIf;
	
	Return Result;
	
EndFunction

&AtServer
Function ReportsOnActivateRowAtServer(RowID, AddCommonText = True, Val UserSettings = Undefined)
	// Save previous report settings.
	If RowID <> CurrentRowIDOfReportsTable AND CurrentRowIDOfReportsTable <> -1 Then
		WriteReportsRowSettings(CurrentRowIDOfReportsTable);
	EndIf;
	CurrentRowIDOfReportsTable = RowID;
	
	// Row search
	ReportsRow = Object.Reports.FindByID(RowID);
	If ReportsRow = Undefined Then
		CurrentRowIDOfReportsTable = -1;
		Return "";
	EndIf;
	
	If UserSettings = Undefined Then
		// Read current row settings from temporary storage or tabular section by reference.
		If IsTempStorageURL(ReportsRow.SettingsAddress) Then
			UserSettings = GetFromTempStorage(ReportsRow.SettingsAddress);
		Else
			RowIndex = Object.Reports.IndexOf(ReportsRow);
			ReportsRowObject = FormAttributeToValue("Object").Reports.Get(RowIndex);
			UserSettings = ?(ReportsRowObject = Undefined, Undefined, ReportsRowObject.Settings.Get());
		EndIf;
	EndIf;
	
	If Not ReportsRow.Enabled Then
		Items.ReportSettingsPages.CurrentPage = Items.BlankPage;
		Return "";
	EndIf;
	
	// Initialization
	ReportParameters = InitializeReport(ReportsRow, AddCommonText, UserSettings);
	
	Return ReportParameters.Errors;
EndFunction

&AtServer
Procedure FillScheduleByOption(Option, RefreshVisibility = False)
	// Options list - see ReportsMailingClientServer.ScheduleFillingOptionsList(). 
	
	Schedule = New JobSchedule;
	
	// at 7:30 am
	Schedule.BeginTime = '00010101073000';
	
	// every day
	Schedule.DaysRepeatPeriod = 1;
	
	// by days of the week
	WeekDayMin = 1;
	MaxWeekDay = 7;
	
	// by all months
	AllMonths = New Array;
	For Index = 1 To 12 Do
		AllMonths.Add(Index);
	EndDo;
	Schedule.Months = AllMonths;
	
	If Option = 1 Then // Every day
		Object.SchedulePeriodicity = Enums.ReportMailingSchedulePeriodicities.Daily;
		
	ElsIf Option = 2 Then // Every second day
		Object.SchedulePeriodicity = Enums.ReportMailingSchedulePeriodicities.Daily;
		Schedule.DaysRepeatPeriod = 2;
		
	ElsIf Option = 3 Then // Every fourth day
		Object.SchedulePeriodicity = Enums.ReportMailingSchedulePeriodicities.Daily;
		Schedule.DaysRepeatPeriod = 4;
		
	ElsIf Option = 4 Then // On weekdays
		Object.SchedulePeriodicity = Enums.ReportMailingSchedulePeriodicities.Weekly;
		WeekDayMin = 1;
		MaxWeekDay = 5;
		
	ElsIf Option = 5 Then // On weekends
		Object.SchedulePeriodicity = Enums.ReportMailingSchedulePeriodicities.Weekly;
		Schedule.BeginTime = '00010101220000'; // at 10:00 pm
		WeekDayMin = 6;
		MaxWeekDay = 7;
		
	ElsIf Option = 6 Then // On Mondays
		Object.SchedulePeriodicity = Enums.ReportMailingSchedulePeriodicities.Weekly;
		WeekDayMin = 1;
		MaxWeekDay = 1;
		
	ElsIf Option = 7 Then // On Fridays
		Object.SchedulePeriodicity = Enums.ReportMailingSchedulePeriodicities.Weekly;
		WeekDayMin = 5;
		MaxWeekDay = 5;
		
	ElsIf Option = 8 Then // On Sundays
		Object.SchedulePeriodicity = Enums.ReportMailingSchedulePeriodicities.Weekly;
		Schedule.BeginTime = '00010101220000'; // at 10:00 pm
		WeekDayMin = 7;
		MaxWeekDay = 7;
		
	ElsIf Option = 9 Then // In the first day of the month
		Object.SchedulePeriodicity = Enums.ReportMailingSchedulePeriodicities.MonthlyDistribution;
		Schedule.DayInMonth = 1;
		
	ElsIf Option = 10 Then // In the last day of the month
		Object.SchedulePeriodicity = Enums.ReportMailingSchedulePeriodicities.MonthlyDistribution;
		Schedule.DayInMonth = -1;
		
	ElsIf Option = 11 Then // WithEvery quarter on the 10th.
		AllMonths = New Array;
		AllMonths.Add(1);
		AllMonths.Add(4);
		AllMonths.Add(7);
		AllMonths.Add(10);
		Schedule.Months = AllMonths;
		Object.SchedulePeriodicity = Enums.ReportMailingSchedulePeriodicities.MonthlyDistribution;
		Schedule.DayInMonth = 10;
		
	ElsIf Option = 12 Then // Other...
		Object.SchedulePeriodicity = Enums.ReportMailingSchedulePeriodicities.Custom;
	
	Else
		Object.SchedulePeriodicity = Enums.ReportMailingSchedulePeriodicities.Daily;
		
	EndIf;
	
	// by days of the week
	SelectedWeekDays = New Array;
	For Index = WeekDayMin To MaxWeekDay Do
		SelectedWeekDays.Add(Index);
	EndDo;
	Schedule.WeekDays = SelectedWeekDays;
	
	If RefreshVisibility Then
		VisibilityAvailabilityCorrectness(ThisObject);
	EndIf;
EndProcedure

&AtServer
Procedure CheckAddedReportRows(ChoiceStructure)
	// ChoiceStructure:
	//   Selected - Structure - rows selected by the user.
	//   Done - Structure - rows initialized and added to the list.
	//   WithErrors - Structure - rows not added to the list due to errors.
	//       * RowArray - Array - an array of rows IDs.
	//       * Count - Number - rows number.
	//       * ReportPresentations - String - presentation of all reports of the specified rows.
	//       * Text - String - an error text.
	
	ErrorArray = New Array;
	
	ChoiceStructure.Selected.Count = ChoiceStructure.Selected.RowsArray.Count();
	For ReverseIndex = 1 To ChoiceStructure.Selected.Count Do
		Index = ChoiceStructure.Selected.Count - ReverseIndex;
		ReportsRowID = ChoiceStructure.Selected.RowsArray[Index];
		
		ReportsRow = Object.Reports.FindByID(ReportsRowID);
		If ReportsRow.Presentation = "" Then
			ReportsRow.Presentation = String(ReportsRow.Report);
		EndIf;
		
		WarningString = ReportsOnActivateRowAtServer(ReportsRowID, False);
		If WarningString = "" Then
			varKey = "Success";
		Else
			varKey = "WithErrors";
			ErrorArray.Add(WarningString);
		EndIf;
		
		ChoiceStructure[varKey].Count = ChoiceStructure[varKey].Count + 1;
		ChoiceStructure[varKey].RowsArray.Add(ReportsRowID);
		ChoiceStructure[varKey].ReportsPresentations = ChoiceStructure[varKey].ReportsPresentations
		+ ?(ChoiceStructure[varKey].ReportsPresentations = "", "", ", ")
		+ ReportsRow.Presentation;
	EndDo;
	
	// Set cursor position on the first of the added items.
	If ChoiceStructure.Success.Count > 0 Then
		Items.Reports.CurrentRow = ChoiceStructure.Success.RowsArray[0];
		CurrentRowIDOfReportsTable = Items.Reports.CurrentRow;
		ReportsOnActivateRowAtServer(ReportsRowID, False);
	EndIf;
	
	// Error text assembly.
	If ChoiceStructure.WithErrors.Count > 0 Then
		ChoiceStructure.WithErrors.Text = ReportMailing.MessagesToUserString(ErrorArray);
	EndIf;
EndProcedure

&AtServer
Function CheckTransportMethod(BulkEmail, Val DeliveryParameters)
	DeliveryParameters.Insert("ExecutionDate", CurrentSessionDate());
	
	// Initialize record parameters to the event log.
	SetPrivilegedMode(True);
	
	LogParameters = New Structure;
	LogParameters.Insert("EventName",   NStr("ru = 'Рассылка отчетов. Проверка способа доставки'; en = 'Report bulk email. Check delivery method'; pl = 'Report bulk email. Check delivery method';de = 'Report bulk email. Check delivery method';ro = 'Report bulk email. Check delivery method';tr = 'Report bulk email. Check delivery method'; es_ES = 'Report bulk email. Check delivery method'", Common.DefaultLanguageCode()));
	LogParameters.Insert("Data",       BulkEmail);
	LogParameters.Insert("Metadata",   Metadata.Catalogs.ReportMailings);
	LogParameters.Insert("ErrorArray", New Array);
	
	SetPrivilegedMode(False);
	
	// Add delivery parameters for writing execution result.
	DeliveryParameters.Insert("TestMode",           True);
	DeliveryParameters.Insert("HadErrors",                  False);
	DeliveryParameters.Insert("HasWarnings",          False);
	DeliveryParameters.Insert("ExecutedToFolder",             False);
	DeliveryParameters.Insert("ExecutedToNetworkDirectory",    False);
	DeliveryParameters.Insert("ExecutedAtFTP",              False);
	DeliveryParameters.Insert("ExecutedByEmail", False);
	
	// Write an empty spreadsheet document in html 4.
	FullFileName = GetTempFileName(".html");
	
	SpreadsheetDoc = New SpreadsheetDocument;
	SpreadsheetDoc.Write(FullFileName, SpreadsheetDocumentFileType.HTML4);
	
	// Generate attachments
	File = New File(FullFileName);
	
	Attachments = New Map;
	Attachments.Insert(File.Name, File.FullName);
	
	// Delivery
	BeginTransaction();
	Try
		Completed = ReportMailing.ExecuteDelivery(LogParameters, DeliveryParameters, Attachments);
		RollbackTransaction(); // After the end of the test, all changes in the base are rolled back.
	Except
		RollbackTransaction();
		Raise;
	EndTry;
	
	// Cleat attachments
	For Each Attachment In Attachments Do
		DeleteFiles(Attachment.Value);
	EndDo;
	
	ExecutionResult = New Structure("Text, More", "", "");
	If Completed Then
		ExecutionResult.Text = NStr("ru = 'Тест способа доставки успешно пройден.'; en = 'Delivery method test is successfully passed.'; pl = 'Delivery method test is successfully passed.';de = 'Delivery method test is successfully passed.';ro = 'Delivery method test is successfully passed.';tr = 'Delivery method test is successfully passed.'; es_ES = 'Delivery method test is successfully passed.'");
	Else
		ExecutionResult.Text = NStr("ru = 'Тест способа доставки не пройден.'; en = 'Delivery method test failed.'; pl = 'Delivery method test failed.';de = 'Delivery method test failed.';ro = 'Delivery method test failed.';tr = 'Delivery method test failed.'; es_ES = 'Delivery method test failed.'");
		ExecutionResult.More = ReportMailing.MessagesToUserString(LogParameters.ErrorArray, False);
	EndIf;
	
	Return ExecutionResult;
EndFunction

////////////////////////////////////////////////////////////////////////////////
// Server

&AtServer
Procedure SetConditionalAppearance()

	ConditionalAppearance.Items.Clear();

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.CurrentReportSettings.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("CurrentReportSettings.Found");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;

	Item.Appearance.SetParameterValue("TextColor", StyleColors.InaccessibleCellTextColor);
	Item.Appearance.SetParameterValue("Enabled", False);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.Reports.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ReportFormats.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Reports.Enabled");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;

	Item.Appearance.SetParameterValue("TextColor", StyleColors.InaccessibleCellTextColor);
	Item.Appearance.SetParameterValue("ReadOnly", True);
	
	// Mailing recipients appearance
	
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.UserSettingsValue.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.UserSettingsValue.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("DCSettingsComposer.UserSettings.Value");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = NStr("ru='<Пустое значение>'; en = '<Empty value>'; pl = '<Empty value>';de = '<Empty value>';ro = '<Empty value>';tr = '<Empty value>'; es_ES = '<Empty value>'");
	
	Item.Appearance.SetParameterValue("Text", NStr("ru='[Recipient]'; en = '[Recipient]'; pl = '[Recipient]';de = '[Recipient]';ro = '[Recipient]';tr = '[Recipient]'; es_ES = '[Recipient]'"));
	Item.Appearance.SetParameterValue("ReadOnly", True);
	
EndProcedure

&AtServer
Function GetCache()
	
	// Convert descriptions to values.
	WeekDays = New Map;
	WeekDays.Insert(Items.Monday.Name, 1);
	WeekDays.Insert(Items.Tuesday.Name,     2);
	WeekDays.Insert(Items.Wednesday.Name,       3);
	WeekDays.Insert(Items.Thursday.Name,     4);
	WeekDays.Insert(Items.Friday.Name,     5);
	WeekDays.Insert(Items.Saturday.Name,     6);
	WeekDays.Insert(Items.Sunday.Name, 7);
	WeekDays = New FixedMap(WeekDays);
	
	Months = New Map;
	Months.Insert(Items.January.Name,   1);
	Months.Insert(Items.February.Name,  2);
	Months.Insert(Items.March.Name,     3);
	Months.Insert(Items.April.Name,   4);
	Months.Insert(Items.May.Name,      5);
	Months.Insert(Items.June.Name,     6);
	Months.Insert(Items.July.Name,     7);
	Months.Insert(Items.August.Name,   8);
	Months.Insert(Items.September.Name, 9);
	Months.Insert(Items.October.Name,  10);
	Months.Insert(Items.November.Name,   11);
	Months.Insert(Items.December.Name,  12);
	Months = New FixedMap(Months);
	
	// Defaults for fields that support filling templates.
	Templates = New FixedStructure("Subject, Text, ArchiveName",
		ReportMailing.SubjectTemplate(),
		ReportMailing.TextTemplate(),
		ReportMailing.ArchivePatternName());
	
	// Cache structure.
	Cache = New Structure;
	Cache.Insert("EmptyReportValue", ReportMailing.EmptyReportValue());
	Cache.Insert("PersonalMailingsGroup", Catalogs.ReportMailings.PersonalMailings);
	Cache.Insert("SystemTitle", ReportMailing.ThisInfobaseName());
	Cache.Insert("Matches", New FixedStructure("WeekDays, Months", WeekDays, Months));
	Cache.Insert("Templates", Templates);
	Cache.Insert("ReportsToBeExcluded", ReportMailingCached.ReportsToExclude());
	
	Return New FixedStructure(Cache);
EndFunction

&AtServer
Procedure FillReportTableInfo()
	ReportsAvailability = ReportsOptions.ReportsAvailability(Object.Reports.Unload(, "Report").UnloadColumn("Report"));
	For Each ReportsRow In Object.Reports Do
		ReportInformation = ReportsAvailability.Find(ReportsRow.Report, "Ref");
		If ReportInformation = Undefined Then
			ReportsRow.Enabled = False;
			ReportsRow.Presentation = NStr("ru = '<Недостаточно прав для работы с отчетом>'; en = '<Insufficient rights to access the report>'; pl = '<Insufficient rights to access the report>';de = '<Insufficient rights to access the report>';ro = '<Insufficient rights to access the report>';tr = '<Insufficient rights to access the report>'; es_ES = '<Insufficient rights to access the report>'");
		Else
			ReportsRow.Enabled = ReportInformation.Available;
			ReportsRow.Presentation = ReportInformation.Presentation;
		EndIf;
		ReportsRow.Formats = "";
		FoundItems = Object.ReportFormats.FindRows(New Structure("Report", ReportsRow.Report));
		For Each StringFormat In FoundItems Do
			ReportsRow.Formats = ReportsRow.Formats + ?(ReportsRow.Formats = "", "", ", ") + String(StringFormat.Format);
		EndDo;
		If ReportsRow.Formats = "" Then
			ReportsRow.Formats = DefaultFormatsPresentation();
		EndIf;
	EndDo;
EndProcedure

&AtServer
Procedure ReadJobSchedule()
	SetPrivilegedMode(True);
	JobID = ?(CreatedByCopying, MailingBasis.ScheduledJob, Object.ScheduledJob);
	If TypeOf(JobID) = Type("UUID") Then
		Job = ScheduledJobs.FindByUUID(JobID);
		If Job <> Undefined Then
			Schedule = Job.Schedule;
			If Object.SchedulePeriodicity <> Enums.ReportMailingSchedulePeriodicities.Custom Then
				Schedule.EndTime = '00010101';
			EndIf;
		EndIf;
	EndIf;
EndProcedure

&AtServer
Procedure ReadObjectSettingsOfObjectToCopy()
	RowsCount = Object.Reports.Count();
	For ReverseIndex = 1 To RowsCount Do
		Index = RowsCount - ReverseIndex;
		ReportsRow = Object.Reports.Get(Index);
		ObjectToCopyReportsRow = MailingBasis.Reports.Get(Index);
		
		DCUserSettings = ObjectToCopyReportsRow.Settings.Get();
		
		ReportsRow.ChangesMade = True;
		
		RowID = ReportsRow.GetID();
		WarningString = ReportsOnActivateRowAtServer(RowID, True, DCUserSettings);
		If WarningString <> "" Then
			Common.MessageToUser(WarningString, , "Object.Reports["+ Index +"].Presentation");
		EndIf;
	EndDo;
EndProcedure

&AtServer
Procedure ConnectEmailSettingsCache()
	// Connect recipients type cache.
	RecipientsTypesTable.Load(ReportMailingCached.RecipientsTypesTable());
	
	// Fill the recipients type selection list.
	For Each RecipientRow In RecipientsTypesTable Do
		Items.MailingRecipientType.ChoiceList.Add(RecipientRow.RecipientsType, RecipientRow.Presentation);
		If RecipientRow.MetadataObjectID = Object.MailingRecipientType Then
			MailingRecipientType = RecipientRow.RecipientsType;
			If Object.RecipientEmailAddressKind.IsEmpty() AND ValueIsFilled(RecipientRow.MainCIKind) Then
				Object.RecipientEmailAddressKind = RecipientRow.MainCIKind;
			EndIf;
		EndIf;
	EndDo;
EndProcedure

&AtServer
Procedure FillEmptyTemplatesWithStandard(CurrentObject)
	// Object data
	If IsBlankString(CurrentObject.EmailSubject) Then
		CurrentObject.EmailSubject = Cache.Templates.Subject;
	EndIf;
	If IsBlankString(CurrentObject.EmailText) Then
		CurrentObject.EmailText = Cache.Templates.Text;
	EndIf;
	If IsBlankString(CurrentObject.ArchiveName) Then
		CurrentObject.ArchiveName = Cache.Templates.ArchiveName;
	EndIf;
	// Form data
	If IsBlankString(EmailTextFormattedDocument.GetText()) Then
		EmailTextFormattedDocument.Add(Cache.Templates.Text, FormattedDocumentItemType.Text);
	EndIf;
EndProcedure

&AtServer
Procedure WriteReportsRowSettings(RowID)
	ReportsRow = Object.Reports.FindByID(RowID);
	If ReportsRow = Undefined Then
		Return;
	EndIf;
	
	If Not ReportsRow.Initialized Then
		ValueToSave = Undefined;
	ElsIf ReportsRow.DCS Then
		ValueToSave = DCSettingsComposer.UserSettings;
	Else
		ColumnNames = "Attribute, Presentation, Value, Use";
		Filter = New Structure("Found", True);
		ValueToSave = CurrentReportSettings.Unload().Copy(Filter, ColumnNames);
	EndIf;
	
	Address = ?(IsTempStorageURL(ReportsRow.SettingsAddress), ReportsRow.SettingsAddress, UUID);
	
	ReportsRow.SettingsAddress = PutToTempStorage(ValueToSave, Address);
EndProcedure

&AtServer
Function InitializeReport(ReportsRow, AddCommonText, UserSettings, Interactively = True)
	// Log parameters
	LogParameters = New Structure;
	LogParameters.Insert("EventName",   NStr("ru = 'Рассылка отчетов. Инициализация отчета'; en = 'Report mailing. Report initialization'; pl = 'Report mailing. Report initialization';de = 'Report mailing. Report initialization';ro = 'Report mailing. Report initialization';tr = 'Report mailing. Report initialization'; es_ES = 'Report mailing. Report initialization'", Common.DefaultLanguageCode()));
	LogParameters.Insert("Data",       ?(ValueIsFilled(Object.Ref), Object.Ref, ReportsRow.Report));
	LogParameters.Insert("Metadata",   Metadata.Catalogs.ReportMailings);
	LogParameters.Insert("ErrorArray", New Array);
	
	// Initialize report
	ReportParameters = New Structure("Report, Settings", ReportsRow.Report, UserSettings);
	ReportMailing.InitializeReport(
		LogParameters,
		ReportParameters,
		Object.Personalized,
		ThisObject.UUID);
	
	ReportParameters.Insert("ErrorArray", LogParameters.ErrorArray);
	ReportParameters.Errors = ReportMailing.MessagesToUserString(ReportParameters.ErrorArray, AddCommonText);
	
	If ReportParameters.Initialized Then
		ReportsRow.DCS             = ReportParameters.DCS;
		ReportsRow.Initialized = ReportParameters.Initialized;
		ReportsRow.FullName       = ReportParameters.FullName;
		ReportsRow.VariantKey    = ReportParameters.VariantKey;
		// Support the ability to directly select additional reports references in reports mailings.
		If ValueIsFilled(ReportParameters.OptionRef) Then
			ReportsRow.Report         = ReportParameters.OptionRef;
			ReportsRow.Presentation = String(ReportsRow.Report);
		EndIf;
	EndIf;
	
	If Not Interactively Then
		Return ReportParameters;
	EndIf;
	
	// Check the initialization result.
	If Not ReportsRow.Initialized Then
		// Delete row.
		Object.Reports.Delete(ReportsRow);
		
		// Empty settings page.
		Items.ReportSettingsPages.CurrentPage = Items.BlankPage;
		
		Return ReportParameters;
	EndIf;
	
	// Restoring settings
	If ReportsRow.DCS Then
		
		DCSettingsComposer = ReportParameters.DCSettingsComposer;
		Items.ReportSettingsPages.CurrentPage = Items.ComposerPage;
		
	Else
		
		// Clear & Restore
		If TypeOf(UserSettings) = Type("ValueTable") Then
			CurrentReportSettings.Load(UserSettings);
		Else
			CurrentReportSettings.Clear();
		EndIf;
		
		For Each KeyAndValue In ReportParameters.AvailableAttributes Do
			// Updating attributes to be evaluated.
			FoundItems = CurrentReportSettings.FindRows(New Structure("Attribute", KeyAndValue.Key));
			If FoundItems.Count() = 0 Then
				SettingRow = CurrentReportSettings.Add();
				SettingRow.Attribute = KeyAndValue.Key;
			Else
				SettingRow = FoundItems[0];
			EndIf;
			SettingRow.Presentation = KeyAndValue.Value.Presentation;
			SettingRow.Type           = KeyAndValue.Value.Type;
			SettingRow.Found     = True;
			SettingRow.PictureIndex = 3;
		EndDo;
		
		// Disabling undetected rows.
		FoundItems = CurrentReportSettings.FindRows(New Structure("Found", False));
		For Each SettingRow In FoundItems Do
			SettingRow.Use = False;
			SettingRow.PictureIndex = 4;
		EndDo;
		
		Items.ReportSettingsPages.CurrentPage = Items.CurrentReportSettingsPage;
		
	EndIf;
	
	Return ReportParameters;
EndFunction

&AtServer
Procedure AddReportsSettings(ReportsToAttach)
	
	For Each ReportsParametersRow In ReportsToAttach Do
		If ReportsParametersRow.Property("OptionRef")
			AND TypeOf(ReportsParametersRow.OptionRef) = Type("CatalogRef.ReportsOptions")
			AND ReportsParametersRow.OptionRef <> Catalogs.ReportsOptions.EmptyRef() Then
			OptionRef = ReportsParametersRow.OptionRef;
		Else
			ReportInformation = ReportsOptions.GenerateReportInformationByFullName(ReportsParametersRow.ReportFullName);
			OptionRef = ReportsOptions.ReportOption(ReportInformation.Report, ReportsParametersRow.VariantKey);
		EndIf;
		
		If OptionRef.DeletionMark Then
			Continue;
		EndIf;
		
		FoundItems = Object.Reports.FindRows(New Structure("Report", OptionRef));
		If FoundItems.Count() > 0 Then
			ReportsRow = FoundItems[0];
		Else
			ReportsRow = Object.Reports.Add();
			ReportsRow.Report                = OptionRef;
			ReportsRow.SendIfEmpty = False;
			ReportsRow.DoNotSendIfEmpty   = True;
			ReportsRow.Enabled          = True;
		EndIf;
		
		ReportsRow.ChangesMade = True;
		
		If Not IsNew Then
			If FoundItems.Count() > 0 Then
				MessageRowTemplate = NStr("ru = 'Для отчета ""%1"" загружены новые пользовательские настройки.'; en = 'New user settings are imported for report ''%1''.'; pl = 'New user settings are imported for report ''%1''.';de = 'New user settings are imported for report ''%1''.';ro = 'New user settings are imported for report ''%1''.';tr = 'New user settings are imported for report ''%1''.'; es_ES = 'New user settings are imported for report ''%1''.'");
			Else
				MessageRowTemplate = NStr("ru = 'Добавлен отчет ""%1"".'; en = '""%1"" report is added.'; pl = '""%1"" report is added.';de = '""%1"" report is added.';ro = '""%1"" report is added.';tr = '""%1"" report is added.'; es_ES = '""%1"" report is added.'");
			EndIf;
			MessageRowTemplate = StringFunctionsClientServer.SubstituteParametersToString(MessageRowTemplate, String(OptionRef));
			If PopupAlertTextOnOpen = "" Then
				PopupAlertTextOnOpen = MessageRowTemplate;
			Else
				PopupAlertTextOnOpen = PopupAlertTextOnOpen + Chars.LF + MessageRowTemplate;
			EndIf;
			RowIndex = Object.Reports.IndexOf(ReportsRow);
		EndIf;
		
		DCUserSettings = ReportsParametersRow.Settings;
		
		RowID = ReportsRow.GetID();
		Items.Reports.CurrentRow = RowID;
		WarningString = ReportsOnActivateRowAtServer(RowID, True, DCUserSettings);
		If WarningString <> "" Then
			Common.MessageToUser(WarningString, , "Object.Reports["+ RowIndex +"].Presentation");
		Else
			WriteReportsRowSettings(RowID);
		EndIf;
	EndDo;
	
	CurrentRowIDOfReportsTable = -1;
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Writing object

&AtClient
Procedure WriteAtClient(Result, WriteParameters) Export
	// Initialize parameters.
	If Not WriteParameters.Property("Step") Then
		ClearMessages(); // Clear message window.
		WriteParameters.Insert("Step", 1);
	EndIf;
	
	// Resource permissions.
	If WriteParameters.Step = 1 AND PermissionsToUseServerResourcesRequired() Then
		WriteParameters.Step = 2;
		// DoQueryBox.
		Handler = New NotifyDescription("WriteAtClient", ThisObject, WriteParameters);
		If CommonClient.SubsystemExists("StandardSubsystems.SecurityProfiles") Then
			Permissions = PermissionsToUseServerResources();
			ModuleSafeModeManagerClient = CommonClient.CommonModule("SafeModeManagerClient");
			ModuleSafeModeManagerClient.ApplyExternalResourceRequests(Permissions, ThisObject, Handler);
		Else
			ExecuteNotifyProcessing(Handler, DialogReturnCode.OK);
		EndIf;
	ElsIf WriteParameters.Step = 1 Then
		// Question is not required.
		WriteParameters.Step = 3;
	ElsIf WriteParameters.Step = 2 Then
		// Process response.
		If Result = DialogReturnCode.OK Then
			WriteParameters.Step = 3; // External resources allowed. Continue writing.
		Else
			Return; // Cancel writing.
		EndIf;
	EndIf;
	
	// Disable archiving.
	If WriteParameters.Step = 3 AND PreferablyDisableArchiving() Then
		WriteParameters.Step = 4;
		// DoQueryBox.
		QuestionTitle = NStr("ru = 'Отключить архивацию'; en = 'Disable backup'; pl = 'Disable backup';de = 'Disable backup';ro = 'Disable backup';tr = 'Disable backup'; es_ES = 'Disable backup'");
		QuestionText = NStr("ru = 'При публикации отчетов в папку рекомендуется отключать архивацию в ZIP.'; en = 'Disable archiving to ZIP when publishing reports into a folder.'; pl = 'Disable archiving to ZIP when publishing reports into a folder.';de = 'Disable archiving to ZIP when publishing reports into a folder.';ro = 'Disable archiving to ZIP when publishing reports into a folder.';tr = 'Disable archiving to ZIP when publishing reports into a folder.'; es_ES = 'Disable archiving to ZIP when publishing reports into a folder.'");
		
		Buttons = New ValueList;
		Buttons.Add(DialogReturnCode.Yes, NStr("ru = 'Отключить архивацию в ZIP'; en = 'Disable archiving to ZIP'; pl = 'Disable archiving to ZIP';de = 'Disable archiving to ZIP';ro = 'Disable archiving to ZIP';tr = 'Disable archiving to ZIP'; es_ES = 'Disable archiving to ZIP'"));
		Buttons.Add(DialogReturnCode.Ignore, NStr("ru = 'Продолжить'; en = 'Continue'; pl = 'Continue';de = 'Continue';ro = 'Continue';tr = 'Continue'; es_ES = 'Continue'"));
		Buttons.Add(DialogReturnCode.Cancel);
		
		Handler = New NotifyDescription("WriteAtClient", ThisObject, WriteParameters);
		ShowQueryBox(Handler, QuestionText, Buttons, 60, DialogReturnCode.Yes, QuestionTitle);
	ElsIf WriteParameters.Step = 3 Then
		// Question is not required.
		WriteParameters.Step = 5;
	ElsIf WriteParameters.Step = 4 Then
		// Process response.
		If Result = DialogReturnCode.Yes Then
			Object.AddToArchive = False; // Disable archiving.
			WriteParameters.Step = 5; // Continue writing.
		ElsIf Result = DialogReturnCode.Ignore Then
			WriteParameters.Step = 5; // Continue writing without disabling archiving.
		Else
			Return; // Cancel writing.
		EndIf;
	EndIf;
	
	// Write.
	If WriteParameters.Step = 5 Then
		WriteParameters.Step = 6;
		Success = Write(WriteParameters);
		If Not Success Then
			Return; // Cancel writing.
		EndIf;
		CommandName = CommonClientServer.StructureProperty(WriteParameters, "CommandName");
		If CommandName = "ExecuteNowCommand" Then
			ExecuteNow();
		ElsIf CommandName = "CommandWriteAndClose" Then
			Close();
		ElsIf CommandName = "MailingEventsCommand" Then
			MailingEvents();
		ElsIf CommandName = "CommandCheckMailing" Then
			CheckMailing(CommonClientServer.StructureProperty(WriteParameters, "DeliveryParameters"));
		EndIf;
	EndIf;
EndProcedure

&AtClient
Function PermissionsToUseServerResourcesRequired()
	If Object.UseNetworkDirectory
		AND (ValueIsFilled(Object.NetworkDirectoryWindows) Or ValueIsFilled(Object.NetworkDirectoryLinux)) Then
		// Publish to the network directory. Permissions are required.
		If AttributesValuesChanged("UseNetworkDirectory, NetworkDirectoryWindows, NetworkDirectoryLinux") Then
			// User changed the values of the attributes to be checked.
			Return True;
		EndIf;
	EndIf;
	If Object.UseFTPResource AND ValueIsFilled(Object.FTPServer) Then
		// Publish to the network directory. Permissions are required.
		If AttributesValuesChanged("UseFTPResource, FTPServer, FTPDirectory") Then
			// User changed the values of the attributes to be checked.
			Return True;
		EndIf;
	EndIf;
	
	Return False;
EndFunction

&AtClient
Function PreferablyDisableArchiving()
	If Object.UseDirectory
		AND Object.AddToArchive
		AND (Object.NotifyOnly Or Not Object.UseEmail) Then
		// Publish to the folder with notifications mailing. Preferably disable archiving.
		If AttributesValuesChanged("UseDirectory, UseEmail, NotifyOnly, AddToArchive") Then
			// User changed the values of the attributes to be checked.
			Return True;
		EndIf;
	EndIf;
	
	Return False;
EndFunction

&AtServer
Function PermissionsToUseServerResources()
	PermissionsSet = ReportMailing.PermissionsToUseServerResources(Object);
	ModuleSafeModeManager = Common.CommonModule("SafeModeManager");
	PermissionsRef = ModuleSafeModeManager.RequestToUseExternalResources(PermissionsSet, Object.Ref);
	PermissionsRefArray = New Array;
	PermissionsRefArray.Add(PermissionsRef);
	Return PermissionsRefArray;
EndFunction

&AtClient
Function AttributesValuesChanged(AttributesNames)
	AttributesNames = StrSplit(AttributesNames, ",", False);
	For Each AttributeName In AttributesNames Do
		AttributeName = TrimAll(AttributeName);
		If Object[AttributeName] <> AttributesValuesBeforeChange[AttributeName] Then
			Return True;
		EndIf;
	EndDo;
	Return False;
EndFunction

&AtServer
Procedure FixAttributesValuesBeforeChange()
	
	AttributesNames = "UseDirectory, UseEmail, NotifyOnly, AddToArchive";
	AttributesNames = AttributesNames + ", UseNetworkDirectory, NetworkDirectoryWindows, NetworkDirectoryLinux";
	AttributesNames = AttributesNames + ", UseFTPResource, FTPServer, FTPDirectory";
	AttributesValuesBeforeChange = New Structure(AttributesNames);
	FillPropertyValues(AttributesValuesBeforeChange, Object);
	AttributesValuesBeforeChange = New FixedStructure(AttributesValuesBeforeChange);
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Copy the ExecuteNow command to support asynchrony.

&AtClient
Procedure ExecuteNow()
	MailingArray = New Array;
	MailingArray.Add(Object.Ref);
	
	StartParameters = New Structure("MailingArray, Form, IsItemForm");
	StartParameters.MailingArray = MailingArray;
	StartParameters.Form = ThisObject;
	StartParameters.IsItemForm = True;
	
	ReportMailingClient.ExecuteNow(StartParameters);
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Copy the Mailing events command to support asynchrony.

&AtClient
Procedure MailingEvents()
	EventLogFormParameters = EventLogParameters(Object.Ref);
	If EventLogFormParameters = Undefined Then
		ShowMessageBox(, NStr("ru = 'Рассылка еще не выполнялась.'; en = 'Bulk email was not performed yet.'; pl = 'Bulk email was not performed yet.';de = 'Bulk email was not performed yet.';ro = 'Bulk email was not performed yet.';tr = 'Bulk email was not performed yet.'; es_ES = 'Bulk email was not performed yet.'"));
		Return;
	EndIf;
	OpenForm("DataProcessor.EventLog.Form", EventLogFormParameters, ThisObject);
EndProcedure

&AtServerNoContext
Function EventLogParameters(BulkEmail)
	Return ReportMailing.EventLogParameters(BulkEmail);
EndFunction

#EndRegion
