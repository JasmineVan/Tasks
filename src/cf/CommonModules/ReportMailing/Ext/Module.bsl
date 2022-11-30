///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Public

// Generates reports and sends them according to the transport settings (Foder, FILE, EMAIL, FTP);
//
// Parameters:
//   Mailing - CatalogRef.ReportMailings - a report mailing to be executed.
//   LogParameters - Structure - parameters of the writing to the event log.
//       * EventName - String - an event name (or events group).
//       * Metadata - MetadataObject - metadata to link the event of the event log.
//       * Data - Arbitrary - data to link the event of the event log.
//   AdditionalSettings - Structure - settings that redefine the standard mailing parameters.
//       * Recipients - Map - a set of recipients and their email addresses.
//           ** Key - CatalogRef - a recipient.
//           ** Value - String - a set of recipient e-mail addresses in the row with separators.
//
// Returns:
//   Boolean - a flag of successful mailing completion.
//
Function ExecuteReportsMailing(BulkEmail, LogParameters = Undefined, AdditionalSettings = Undefined) Export
	// Parameters of the writing to the event log.
	If LogParameters = Undefined Then
		LogParameters = New Structure;
	EndIf;
	
	If Not LogParameters.Property("EventName") Then
		LogParameters.Insert("EventName", NStr("ru = 'Рассылка отчетов. Запуск по требованию'; en = 'Report bulk email. Start on demand'; pl = 'Report bulk email. Start on demand';de = 'Report bulk email. Start on demand';ro = 'Report bulk email. Start on demand';tr = 'Report bulk email. Start on demand'; es_ES = 'Report bulk email. Start on demand'", Common.DefaultLanguageCode()));
	EndIf;
	
	If Not LogParameters.Property("Data") Then
		LogParameters.Insert("Data", BulkEmail);
	EndIf;
	
	If Not LogParameters.Property("Metadata") Then
		LogParameters.Insert("Metadata", LogParameters.Data.Metadata());
	EndIf;
	
	// Check rights settings
	If Not OutputRight(LogParameters) Then
		Return False;
	EndIf;
	
	// Check basic mailing attributes.
	If Not BulkEmail.Prepared
		Or BulkEmail.DeletionMark Then
		
		Reason = "";
		If Not BulkEmail.Prepared Then
			Reason = Reason + Chars.LF + NStr("ru = 'Рассылка не подготовлена'; en = 'Bulk email is not prepared'; pl = 'Bulk email is not prepared';de = 'Bulk email is not prepared';ro = 'Bulk email is not prepared';tr = 'Bulk email is not prepared'; es_ES = 'Bulk email is not prepared'");
		EndIf;
		If BulkEmail.DeletionMark Then
			Reason = Reason + Chars.LF + NStr("ru = 'Рассылка помечена на удаление'; en = 'Bulk email is marked for deletion'; pl = 'Bulk email is marked for deletion';de = 'Bulk email is marked for deletion';ro = 'Bulk email is marked for deletion';tr = 'Bulk email is marked for deletion'; es_ES = 'Bulk email is marked for deletion'");
		EndIf;
		
		LogRecord(LogParameters, EventLogLevel.Warning,
			NStr("ru = 'Завершение'; en = 'Completing'; pl = 'Completing';de = 'Completing';ro = 'Completing';tr = 'Completing'; es_ES = 'Completing'"), TrimAll(Reason));
		Return False;
		
	EndIf;
	
	StartCommitted = CommonClientServer.StructureProperty(AdditionalSettings, "StartCommitted");
	If StartCommitted <> True Then
		// Register startup (started but not completed).
		InformationRegisters.ReportMailingStates.FixMailingStart(BulkEmail);
	EndIf;
	
	// Value table
	ValueTable = New ValueTable;
	ValueTable.Columns.Add("Report", Metadata.Catalogs.ReportMailings.TabularSections.Reports.Attributes.Report.Type);
	ValueTable.Columns.Add("SendIfEmpty", New TypeDescription("Boolean"));
	
	SettingTypesArray = New Array;
	SettingTypesArray.Add(Type("Undefined"));
	SettingTypesArray.Add(Type("DataCompositionUserSettings"));
	SettingTypesArray.Add(Type("Structure"));
	
	ValueTable.Columns.Add("Settings", New TypeDescription(SettingTypesArray));
	ValueTable.Columns.Add("Formats", New TypeDescription("Array"));
	
	// Default formats
	DefaultFormats = New Array;
	FoundItems = BulkEmail.ReportFormats.FindRows(New Structure("Report", EmptyReportValue()));
	For Each StringFormat In FoundItems Do
		DefaultFormats.Add(StringFormat.Format);
	EndDo;
	If DefaultFormats.Count() = 0 Then
		FormatsList = FormatsList();
		For Each ListValue In FormatsList Do
			If ListValue.Check Then
				DefaultFormats.Add(ListValue.Value);
			EndIf;
		EndDo;
	EndIf;
	If DefaultFormats.Count() = 0 Then
		Raise NStr("ru = 'Не установлены форматы по умолчанию.'; en = 'Default formats are not set.'; pl = 'Default formats are not set.';de = 'Default formats are not set.';ro = 'Default formats are not set.';tr = 'Default formats are not set.'; es_ES = 'Default formats are not set.'");
	EndIf;
	
	// Fill reports tables
	For Each RowReport In BulkEmail.Reports Do
		Page = ValueTable.Add();
		Page.Report = RowReport.Report;
		Page.SendIfEmpty = RowReport.SendIfEmpty;
		
		// Settings
		Settings = RowReport.Settings.Get();
		If TypeOf(Settings) = Type("ValueTable") Then
			Page.Settings = New Structure;
			FoundItems = Settings.FindRows(New Structure("Use", True));
			For Each SettingRow In FoundItems Do
				Page.Settings.Insert(SettingRow.Attribute, SettingRow.Value);
			EndDo;
		Else
			Page.Settings = Settings;
		EndIf;
		
		// Formats
		FoundItems = BulkEmail.ReportFormats.FindRows(New Structure("Report", RowReport.Report));
		If FoundItems.Count() = 0 Then
			Page.Formats = DefaultFormats;
		Else
			For Each StringFormat In FoundItems Do
				Page.Formats.Add(StringFormat.Format);
			EndDo;
		EndIf;
	EndDo;
	
	// Prepare delivery parameters.
	DeliveryParameters = New Structure;
	DeliveryParameters.Insert("StartCommitted",           True);
	DeliveryParameters.Insert("Author",                        Users.CurrentUser());
	DeliveryParameters.Insert("UseDirectory",            BulkEmail.UseDirectory);
	DeliveryParameters.Insert("UseNetworkDirectory",   BulkEmail.UseNetworkDirectory);
	DeliveryParameters.Insert("UseFTPResource",        BulkEmail.UseFTPResource);
	DeliveryParameters.Insert("UseEmail", BulkEmail.UseEmail);
	DeliveryParameters.Insert("TransliterateFileNames", BulkEmail.TransliterateFileNames);
	
	// Marked delivery method checks.
	If Not DeliveryParameters.UseDirectory
		AND Not DeliveryParameters.UseNetworkDirectory
		AND Not DeliveryParameters.UseFTPResource
		AND Not DeliveryParameters.UseEmail Then
		LogRecord(LogParameters, EventLogLevel.Warning,
			NStr("ru = 'Не выбран способ доставки.'; en = 'Delivery method is not selected.'; pl = 'Delivery method is not selected.';de = 'Delivery method is not selected.';ro = 'Delivery method is not selected.';tr = 'Delivery method is not selected.'; es_ES = 'Delivery method is not selected.'"));
		Return False;
	EndIf;
	
	DeliveryParameters.Insert("Personalized", BulkEmail.Personalized);
	DeliveryParameters.Insert("AddToArchive",      BulkEmail.AddToArchive);
	DeliveryParameters.Insert("ArchiveName",         BulkEmail.ArchiveName);
	SetPrivilegedMode(True);
	DeliveryParameters.Insert("ArchivePassword", Common.ReadDataFromSecureStorage(BulkEmail, "ArchivePassword"));
	SetPrivilegedMode(False);
	
	// Prepare parameters of delivery to the folder.
	If DeliveryParameters.UseDirectory Then
		DeliveryParameters.Insert("Folder", BulkEmail.Folder);
	EndIf;
	
	// Prepare parameters of delivery to the network directory.
	If DeliveryParameters.UseNetworkDirectory Then
		DeliveryParameters.Insert("NetworkDirectoryWindows", BulkEmail.NetworkDirectoryWindows);
		DeliveryParameters.Insert("NetworkDirectoryLinux",   BulkEmail.NetworkDirectoryLinux);
	EndIf;
	
	// Prepare parameters of delivery to the FTP resource.
	If DeliveryParameters.UseFTPResource Then
		DeliveryParameters.Insert("Server",              BulkEmail.FTPServer);
		DeliveryParameters.Insert("Port",                BulkEmail.FTPPort);
		DeliveryParameters.Insert("Username",               BulkEmail.FTPUsername);
		SetPrivilegedMode(True);
		DeliveryParameters.Insert("Password", Common.ReadDataFromSecureStorage(BulkEmail, "FTPPassword"));
		SetPrivilegedMode(False);
		DeliveryParameters.Insert("Directory",             BulkEmail.FTPDirectory);
		DeliveryParameters.Insert("PassiveConnection", BulkEmail.FTPPassiveConnection);
	EndIf;
	
	// Prepare parameters of delivery by email.
	If DeliveryParameters.UseEmail Then
		DeliveryParameters.Insert("Account",   BulkEmail.Account);
		DeliveryParameters.Insert("NotifyOnly", BulkEmail.NotifyOnly);
		DeliveryParameters.Insert("BCC",    BulkEmail.BCC);
		DeliveryParameters.Insert("SubjectTemplate",      BulkEmail.EmailSubject);
		DeliveryParameters.Insert("TextTemplate", 
			?(
				BulkEmail.HTMLFormatEmail, 
				BulkEmail.EmailTextInHTMLFormat, 
				BulkEmail.EmailText));
		
		// Recipients
		If AdditionalSettings <> Undefined AND AdditionalSettings.Property("Recipients") Then
			
			DeliveryParameters.Insert("Recipients", AdditionalSettings.Recipients);
			
		Else
			
			Recipients = GenerateMailingRecipientsList(LogParameters, BulkEmail);
			
			If Recipients.Count() = 0 Then
				
				DeliveryParameters.UseEmail = False;
				
				If Not DeliveryParameters.UseDirectory
					AND Not DeliveryParameters.UseNetworkDirectory
					AND Not DeliveryParameters.UseFTPResource Then
					
					Return False;
					
				EndIf;
				
			EndIf;
			
			DeliveryParameters.Insert("Recipients", Recipients);
			
		EndIf;
		
		// Additional parameters
		DeliveryParameters.Insert("EmailParameters", New Structure);
		
		// Reply to
		If ValueIsFilled(BulkEmail.ReplyToAddress) Then
			DeliveryParameters.EmailParameters.Insert("ReplyToAddress", BulkEmail.ReplyToAddress);
		EndIf;
		
		// Attachments
		DeliveryParameters.EmailParameters.Insert("TextType", ?(BulkEmail.HTMLFormatEmail, "HTML", "PlainText"));
		DeliveryParameters.EmailParameters.Insert("Pictures", New Structure);
		If BulkEmail.HTMLFormatEmail Then
			DeliveryParameters.EmailParameters.Pictures = BulkEmail.EmailPicturesInHTMLFormat.Get();
		EndIf;
		
	EndIf;
	
	If Not DeliveryParameters.Property("StartCommitted") Or Not DeliveryParameters.StartCommitted Then
		InformationRegisters.ReportMailingStates.FixMailingStart(BulkEmail);
	EndIf;
	
	Result = ExecuteBulkEmail(ValueTable, DeliveryParameters, BulkEmail, LogParameters);
	InformationRegisters.ReportMailingStates.FixMailingExecutionResult(BulkEmail, DeliveryParameters);
	Return Result;
	
EndFunction

// Executes report mailing without the ReportMailing catalog item.
//
////////////////////////////////////////////////////////////////////////////////
// Parameters:
//
//   Reports - ValueTable - a set of reports to be exported. Columns:
//       * Report - CatalogRef.ReportOptions, CatalogRef.AdditionalReportsAndDataProcessors - 
//           Report to be generated.
//       * SendIfEmpty - Boolean - a flag of sending report even if it is empty.
//       * Settings - settings to generate a report.
//           It is used additionally to determine whether the report belongs to the DCS.
//           - DataCompositionUserSettings - a spreadsheet document will be generated by the DSC mechanisms.
//           - Structure - a spreadsheet document will be generated by the Generate() method.
//               *** Key     - String       - a report object attribute name.
//               *** Value - Arbitrary - a report object attribute value.
//           - Undefined - default settings. To determine whether it belongs to the DCS, the  
//               CompositionDataSchema object attribute will be used.
//       * Formats - Array from EnumRef.ReportSaveFormats -
//            Formats in which the report must be saved and sent.
//
//   DeliveryParameters - Structure - report transport settings (delivery method).
//     Attributes set can be different for different delivery methods:
//
//     Required attributes:
//       * Author - CatalogRef.Users - a mailing author.
//       * UseDirectory            - Boolean - deliver reports to the "Stored files" subsystem folder.
//       * UseNetworkDirectory   - Boolean - deliver reports to the file system folder.
//       * UseFTPResource        - Boolean - deliver reports to the FTP.
//       * UseEmail - Boolean - deliver reports by email.
//
//     Required attributes when { UseFolder = True }:
//       * Folder (CatalogRef.FilesDirectories) - the "Stored files" subsystem folder.
//
//     Required attributes when { UseNetworkDirectory = True }:
//       * NetworkDirectoryWindows - String - a file system directory (local at server or network).
//       * NetworkDirectoryLinux   - String - a file system directory (local at server or network).
//
//     Required attributes when { UseFTPResource = True }:
//       * Server              - String - an FTP server name.
//       * Port                - Number - an FTP server port.
//       * Username               - String - an FTP server user name.
//       * Password              - String - an FTP server user password.
//       * Directory             - String - a path to the directory at the FTP server.
//       * PassiveConnection - Boolean - use passive connection.
//
//     Required attributes when { UseEmail = True }:
//       * Account - CatalogRef.EmailAccounts - 
//           Account to send an email message.
//       * Recipients - Map - a set of recipients and their email addresses.
//           ** Key - CatalogRef - a recipient.
//           ** Value - String - a set of recipient e-mail addresses in the row with separators.
//
//     Optional attributes:
//       * Archive - Boolean - archive all generated reports into one archive.
//                                 Archiving can be required, for example, when mailing schedules in html format.
//       * ArchiveName    - String - an archive name.
//       * ArchivePassword - String - an archive password.
//       * TransliterateFileNames - Boolean - a flag that shows whether it is necessary to transliterate mailing report files name.
//
//     Optional attributes when { UseEmail = True }:
//       * Personalized - Boolean - a mailing personalized by recipients.
//           Default value is False.
//           If True value is set, each recipient will receive a report with a filter by it.
//           To do this,  set in the reports the Recipient filter for the attributes that match the recipient type.
//           Applies only to delivery by mail, so when setting to the True, other delivery methods 
//           are disabled:
//           { UseFolder = False }
//            { UseNetworkDirectory = False }
//           { UseFTPResource = False }
//           And related notification features:
//           { NotifyOnly = False}
//       * NotifyOnly - Boolean, False - send notifications only (do not attach generated reports).
//       * BCC    - Boolean, False - if True, when sending fill BCC instead of To.
//       * SubjectTemplate      - String -       an email subject.
//       * TextTemplate    - String -       an email body.
//       * EmailParameters - Structure -    message parameters that will be passed directly to the 
//           EmailOperations subsystem.
//           Their processing can be seen in the EmailOperations module, the SendMessage procedure.
//           The ReportsMailing subsystem can use:
//           ** TextType - InternetMailTextType,String,EnumRef.EmailTextsTypes - 
//               Email text type.
//           ** Attachments - Map - email pictures.
//               *** Key - String - a description.
//               *** Value - picture data.
//                   - String - an address in the temporary storage where the picture is located.
//                   - BinaryData - binary data of a picture.
//                   - Picture - picture data.
//           ** ResponseAddress - String - an email address of the response.
//
//   MailingDescription - String - displayed in the subject and message as well as to display errors.
//
//   LogParameters - Structure - parameters of the writing to the event log.
//       * EventName - String           - an event name (or events group).
//       * Metadata - MetadataObject - metadata to link the event of the event log.
//       * Data     - Arbitrary     - data to link the event of the event log.
//
// Returns:
//   Boolean - a flag of successful mailing completion.
//
Function ExecuteBulkEmail(Reports, DeliveryParameters, MailingDescription = "", LogParameters = Undefined) Export
	MailingExecuted = False;
	
	// Add a tree of generated reports  - spreadsheet document and reports saved in formats (of files).
	ReportsTree = CreateReportsTree();
	
	// Fill with default parameters and check whether key delivery parameters are filled.
	If Not CheckAndFillExecutionParameters(Reports, DeliveryParameters, MailingDescription, LogParameters) Then
		Return False;
	EndIf;
	
	// Row of the general (not personalized by recipients) reports tree.
	DeliveryParameters.Insert("GeneralReportsRow", DefineTreeRowForRecipient(ReportsTree, Undefined, DeliveryParameters));
	
	LogRecord(LogParameters, ,
		StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = 'Инициализирована рассылка %1, автор: %2'; en = 'Bulk email is initialized %1, author: %2'; pl = 'Bulk email is initialized %1, author: %2';de = 'Bulk email is initialized %1, author: %2';ro = 'Bulk email is initialized %1, author: %2';tr = 'Bulk email is initialized %1, author: %2'; es_ES = 'Bulk email is initialized %1, author: %2'"),
		"'"+ String(MailingDescription) +"'","'"+ String(DeliveryParameters.Author) +"'"));
	
	// Generate and save reports.
	ReportsNumber = 1;
	For Each RowReport In Reports Do
		LogText = NStr("ru = 'Отчет %1 формируется'; en = 'Generating report ""%1""'; pl = 'Generating report ""%1""';de = 'Generating report ""%1""';ro = 'Generating report ""%1""';tr = 'Generating report ""%1""'; es_ES = 'Generating report ""%1""'");
		If RowReport.Settings = Undefined Then
			LogText = LogText + Chars.LF + NStr("ru = '(пользовательские настройки не заданы)'; en = '(user settings are not set)'; pl = '(user settings are not set)';de = '(user settings are not set)';ro = '(user settings are not set)';tr = '(user settings are not set)'; es_ES = '(user settings are not set)'");
		EndIf;
		LogRecord(LogParameters, EventLogLevel.Note,
			StringFunctionsClientServer.SubstituteParametersToString(LogText, "'" + String(RowReport.Report) + "'"));
		
		// Initialize report.
		ReportParameters = New Structure("Report, Settings, Formats, SendIfEmpty");
		FillPropertyValues(ReportParameters, RowReport);
		If Not InitializeReport(LogParameters, ReportParameters, DeliveryParameters.Personalized) Then
			Continue;
		EndIf;
		
		If DeliveryParameters.Personalized AND NOT ReportParameters.Personalized Then
			ReportParameters.Errors = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'Отчет ""%1"" не может сформирован, так как в его настройках не указан отбор по получателю рассылки.'; en = 'Cannot generate the ""%1"" report as the filter by bulk email recipient is not specified in its settings.'; pl = 'Cannot generate the ""%1"" report as the filter by bulk email recipient is not specified in its settings.';de = 'Cannot generate the ""%1"" report as the filter by bulk email recipient is not specified in its settings.';ro = 'Cannot generate the ""%1"" report as the filter by bulk email recipient is not specified in its settings.';tr = 'Cannot generate the ""%1"" report as the filter by bulk email recipient is not specified in its settings.'; es_ES = 'Cannot generate the ""%1"" report as the filter by bulk email recipient is not specified in its settings.'"),
				String(RowReport.Report));
			LogRecord(LogParameters, EventLogLevel.Error, ReportParameters.Errors);
			Continue;
		EndIf;
	
		// Generate spreadsheet documents and save in formats.
		Try
			If ReportParameters.Personalized Then
				// Broken down by recipients
				For Each KeyAndValue In DeliveryParameters.Recipients Do
					GenerateAndSaveReport(
						LogParameters,
						ReportParameters,
						ReportsTree,
						DeliveryParameters,
						KeyAndValue.Key);
				EndDo;
			Else
				// Without personalization
				GenerateAndSaveReport(
					LogParameters,
					ReportParameters,
					ReportsTree,
					DeliveryParameters,
					Undefined);
			EndIf;
			LogRecord(LogParameters, EventLogLevel.Note,
				StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = 'Отчет %1 успешно сформирован'; en = 'Report %1 is successfully generated'; pl = 'Report %1 is successfully generated';de = 'Report %1 is successfully generated';ro = 'Report %1 is successfully generated';tr = 'Report %1 is successfully generated'; es_ES = 'Report %1 is successfully generated'"), "'"+ String(RowReport.Report) +"'"));
			ReportsNumber = ReportsNumber + 1;
		Except
			LogRecord(LogParameters, ,
				StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = 'Отчет %1 не сформирован:'; en = 'Report %1 is not generated:'; pl = 'Report %1 is not generated:';de = 'Report %1 is not generated:';ro = 'Report %1 is not generated:';tr = 'Report %1 is not generated:'; es_ES = 'Report %1 is not generated:'"), "'"+ String(RowReport.Report) +"'" ), ErrorInfo());
		EndTry;
	EndDo;
	
	// Check the number of the saved reports.
	If ReportsTree.Rows.Find(3, "Level", True) = Undefined Then
		LogRecord(LogParameters, EventLogLevel.Warning,
			NStr("ru = 'Рассылка отчетов не выполнена, так как отчеты пустые или не сформированы из-за ошибок.'; en = 'Reports are not mailed as they are empty or were not generated due to errors.'; pl = 'Reports are not mailed as they are empty or were not generated due to errors.';de = 'Reports are not mailed as they are empty or were not generated due to errors.';ro = 'Reports are not mailed as they are empty or were not generated due to errors.';tr = 'Reports are not mailed as they are empty or were not generated due to errors.'; es_ES = 'Reports are not mailed as they are empty or were not generated due to errors.'"));
		FileSystem.DeleteTemporaryDirectory(DeliveryParameters.TempFilesDirectory);
		Return False;
	EndIf;
	
	// General reports.
	SharedAttachments = DeliveryParameters.GeneralReportsRow.Rows.FindRows(New Structure("Level", 3), True);
	
	// Send personal reports (personalized).
	For Each RecipientRow In ReportsTree.Rows Do
		If RecipientRow = DeliveryParameters.GeneralReportsRow Then
			Continue; // Ignore the general reports tree row.
		EndIf;
		
		// Personal attachments.
		PersonalAttachments = RecipientRow.Rows.FindRows(New Structure("Level", 3), True);
		
		// Check the number of saved personal reports.
		If PersonalAttachments.Count() = 0 Then
			Continue;
		EndIf;
		
		// Merge common and personal attachments.
		RecipientsAttachments = CombineArrays(SharedAttachments, PersonalAttachments);
		
		// Generate reports presentation.
		GenerateReportPresentationsForRecipient(DeliveryParameters, RecipientRow);
		
		// Archive attachments.
		ArchiveAttachments(RecipientsAttachments, DeliveryParameters, RecipientRow.Value);
		
		// Transport.
		Try
			SendReportsToRecipient(
				RecipientsAttachments,
				DeliveryParameters,
				RecipientRow);
			MailingExecuted = True;
			DeliveryParameters.ExecutedByEmail = True;
		Except
			LogRecord(LogParameters,,
				StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = 'Не удалось отправить отчеты получателю %1:'; en = 'Cannot send reports to recipient %1:'; pl = 'Cannot send reports to recipient %1:';de = 'Cannot send reports to recipient %1:';ro = 'Cannot send reports to recipient %1:';tr = 'Cannot send reports to recipient %1:'; es_ES = 'Cannot send reports to recipient %1:'"), "'"+ String(RecipientRow.Key) +"'"), ErrorInfo());
		EndTry;
		
		//
		If MailingExecuted Then
			DeliveryParameters.Recipients.Delete(RecipientRow.Key);
		EndIf;
	EndDo;
	
	// Send general reports.
	If SharedAttachments.Count() > 0 Then
		// Reports presentation.
		GenerateReportPresentationsForRecipient(DeliveryParameters, RecipientRow);
		
		// Archive attachments.
		ArchiveAttachments(SharedAttachments, DeliveryParameters, DeliveryParameters.TempFilesDirectory);
		
		// Transport.
		If ExecuteDelivery(LogParameters, DeliveryParameters, SharedAttachments) Then
			MailingExecuted = True;
		EndIf;
	EndIf;

	If MailingExecuted Then
		LogRecord(LogParameters, , NStr("ru = 'Рассылка выполнена'; en = 'Bulk email is completed'; pl = 'Bulk email is completed';de = 'Bulk email is completed';ro = 'Bulk email is completed';tr = 'Bulk email is completed'; es_ES = 'Bulk email is completed'"));
	Else
		LogRecord(LogParameters, , NStr("ru = 'Рассылка не выполнена'; en = 'Bulk email failed'; pl = 'Bulk email failed';de = 'Bulk email failed';ro = 'Bulk email failed';tr = 'Bulk email failed'; es_ES = 'Bulk email failed'"));
	EndIf;
	
	FileSystem.DeleteTemporaryDirectory(DeliveryParameters.TempFilesDirectory);
	
	// Result.
	If LogParameters.Property("HadErrors") Then
		DeliveryParameters.HadErrors = LogParameters.HadErrors;
	EndIf;
	If LogParameters.Property("HasWarnings") Then
		DeliveryParameters.HasWarnings = LogParameters.HasWarnings;
	EndIf;
	
	Return MailingExecuted;
EndFunction

// To call from the modules ReportsMailingOverridable or ReportsMailingCached.
//   Adds format (if absent) and sets its parameters (if passed).
//
// Parameters:
//   FormatsList - ListOfValues - a list of formats.
//   FormatRef   - String, EnumRef.ReportStorageFormats - a reference or name of the format.
//   Picture                - Picture - optional. Formats picture.
//   UseByDefault - Boolean   - optional. Flag showing that the format is used by default.
//
Procedure SetFormatsParameters(FormatsList, FormatRef, Picture = Undefined, UseByDefault = Undefined) Export
	If TypeOf(FormatRef) = Type("String") Then
		FormatRef = Enums.ReportSaveFormats[FormatRef];
	EndIf;
	ListItem = FormatsList.FindByValue(FormatRef);
	If ListItem = Undefined Then
		ListItem = FormatsList.Add(FormatRef, String(FormatRef), False, PictureLib.BlankFormat);
	EndIf;
	If Picture <> Undefined Then
		ListItem.Picture = Picture;
	EndIf;
	If UseByDefault <> Undefined Then
		ListItem.Check = UseByDefault;
	EndIf;
EndProcedure

// To call from the modules ReportsMailingOverridable or ReportsMailingCached.
//   Adds recipients type description to the table.
//
// Parameters:
//   TypesTable - ValueTable - passed from procedure parameters as is. Contains types information.
//   AvailableTypes - Array          - passed from procedure parameters as is. Unused types array.
//   Settings     - Structure       - predefined settings to register the main type.
//     Mandatory parameters:
//       * MainType - Type - a main type for the described recipients.
//     Optional parameters:
//       * Presentation - String - a presentation of this type of recipients in the interface.
//       * CIKind - CatalogRef.ContactInformationKinds - a main type or group of contact information 
//           for email addresses of this type of recipients.
//       * ChoiceFormPath - String - a path to the choice form.
//       * AdditionalType - Type - an additional type that can be selected along with the main one from the choice form.
//
Procedure AddItemToRecipientsTypesTable(TypesTable, AvailableTypes, Settings) Export
	SetPrivilegedMode(True);
	
	MainTypesMetadata = Metadata.FindByType(Settings.MainType);
	
	// Register the main type usage.
	TypeIndex = AvailableTypes.Find(Settings.MainType);
	If TypeIndex <> Undefined Then
		AvailableTypes.Delete(TypeIndex);
	EndIf;
	
	// Metadata objects IDs.
	MetadataObjectID = Common.MetadataObjectID(Settings.MainType);
	TableRow = TypesTable.Find(MetadataObjectID, "MetadataObjectID");
	If TableRow = Undefined Then
		TableRow = TypesTable.Add();
		TableRow.MetadataObjectID = MetadataObjectID;
	EndIf;
	
	// Recipients type
	TypesArray = New Array;
	TypesArray.Add(Settings.MainType);
	
	// Recipients type: Main
	TableRow.MainType = New TypeDescription(TypesArray);
	
	// Recipients type: Additional.
	If Settings.Property("AdditionalType") Then
		TypesArray.Add(Settings.AdditionalType);
		
		// Register the additional type.
		TypeIndex = AvailableTypes.Find(Settings.AdditionalType);
		If TypeIndex <> Undefined Then
			AvailableTypes.Delete(TypeIndex);
		EndIf;
	EndIf;
	TableRow.RecipientsType = New TypeDescription(TypesArray);
	
	// Presentation
	If Settings.Property("Presentation") Then
		TableRow.Presentation = Settings.Presentation;
	Else
		TableRow.Presentation = MainTypesMetadata.Synonym;
	EndIf;
	
	// Main type of contact information email for the object.
	If Settings.Property("CIKind") AND Not Settings.CIKind.IsFolder Then
		TableRow.MainCIKind = Settings.CIKind;
		TableRow.CIGroup = Settings.CIKind.Parent;
	Else
		If Settings.Property("CIKind") Then
			TableRow.CIGroup = Settings.CIKind;
		Else
			
			If Common.SubsystemExists("StandardSubsystems.ContactInformation") Then
				
				ModuleContactsManager = Common.CommonModule("ContactsManager");
				CIGroupName = StrReplace(MainTypesMetadata.FullName(), ".", "");
				TableRow.CIGroup = ModuleContactsManager.ContactInformationKindByName(CIGroupName);
				
			EndIf;
			
		EndIf;
		Query = New Query;
		Query.Text = "SELECT TOP 1 Ref FROM Catalog.ContactInformationKinds WHERE Parent = &Parent AND Type = &Type";
		Query.SetParameter("Parent", TableRow.CIGroup);
		Query.Parameters.Insert("Type", Enums.ContactInformationTypes.EmailAddress);
		Selection = Query.Execute().Select();
		If Selection.Next() Then
			TableRow.MainCIKind = Selection.Ref;
		EndIf;
	EndIf;
	
	// Full path to the choice form of this object.
	If Settings.Property("ChoiceFormPath") Then
		TableRow.ChoiceFormPath = Settings.ChoiceFormPath;
	Else
		TableRow.ChoiceFormPath = MainTypesMetadata.FullName() +".ChoiceForm";
	EndIf;
EndProcedure

// Executes an array of mailings and places the result at the ResultAddress address. In the file 
//   mode called directly, in the client/server mode called through a background job.
//
// Parameters:
//   ExecutionParameters - Structure - mailings to be executed and their parameters.
//       * RefArray - Array from CatalogRef.ReportMailings - mailings to be executed.
//       * PreliminarySettings - Structure - parameters, see ReportsMailing.ExecuteReportsMailing. 
//   ResultAddress - String - an address in the temporary storage where the result will be placed.
//
Procedure SendBulkEmailsInBackgroundJob(ExecutionParameters, ResultAddress) Export
	MailingArray           = ExecutionParameters.MailingArray;
	PreliminarySettings = ExecutionParameters.PreliminarySettings;
	
	// Selecting all mailings including nested excluding groups.
	Query = New Query;
	Query.Text = 
	"SELECT ALLOWED DISTINCT
	|	ReportMailings.Ref AS BulkEmail,
	|	ReportMailings.Presentation AS Presentation,
	|	CASE
	|		WHEN ReportMailings.Prepared = TRUE
	|				AND ReportMailings.DeletionMark = FALSE
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS Prepared,
	|	FALSE AS Executed,
	|	FALSE AS WithErrors
	|FROM
	|	Catalog.ReportMailings AS ReportMailings
	|WHERE
	|	ReportMailings.Ref IN HIERARCHY(&MailingArray)
	|	AND ReportMailings.IsFolder = FALSE";
	
	Query.SetParameter("MailingArray", MailingArray);
	MailingsTable = Query.Execute().Unload();
	PreparedReportDistributionDetails = MailingsTable.FindRows(New Structure("Prepared", True));
	Completed = 0;
	WithErrors = 0;
	
	MessagesArray = New Array;
	For Each TableRow In PreparedReportDistributionDetails Do
		LogParameters = New Structure("ErrorArray", New Array);
		
		TableRow.Executed = ExecuteReportsMailing(
			TableRow.BulkEmail,
			LogParameters,
			PreliminarySettings);
		TableRow.WithErrors = (LogParameters.ErrorArray.Count() > 0);
		
		If TableRow.WithErrors Then
			MessagesArray.Add("---" + Chars.LF + Chars.LF + TableRow.Presentation + ":"); // Title
			For Each Message In LogParameters.ErrorArray Do
				MessagesArray.Add(Message);
			EndDo;
		EndIf;
		
		If TableRow.Executed Then
			Completed = Completed + 1;
			If TableRow.WithErrors Then
				WithErrors = WithErrors + 1;
			EndIf;
		EndIf;
	EndDo;
	
	Total        = MailingsTable.Count();
	Prepared = PreparedReportDistributionDetails.Count();
	NotCompleted  = Prepared - Completed;
	
	If Total = 0 Then
		MessageText = NStr("ru = 'Выбранные группы не содержат рассылок отчетов.'; en = 'The selected groups do not have report mailing.'; pl = 'The selected groups do not have report mailing.';de = 'The selected groups do not have report mailing.';ro = 'The selected groups do not have report mailing.';tr = 'The selected groups do not have report mailing.'; es_ES = 'The selected groups do not have report mailing.'");
	ElsIf Total <= 5 Then
		MessageText = "";
		For Each TableRow In MailingsTable Do
			If Not TableRow.Prepared Then
				MessageTemplate = NStr("ru = 'Рассылка ""%1"" не подготовлена.'; en = 'Bulk email ""%1"" is not prepared.'; pl = 'Bulk email ""%1"" is not prepared.';de = 'Bulk email ""%1"" is not prepared.';ro = 'Bulk email ""%1"" is not prepared.';tr = 'Bulk email ""%1"" is not prepared.'; es_ES = 'Bulk email ""%1"" is not prepared.'");
			ElsIf Not TableRow.Executed Then
				MessageTemplate = NStr("ru = 'Рассылка ""%1"" не выполнена.'; en = 'Bulk email ""%1"" was not completed.'; pl = 'Bulk email ""%1"" was not completed.';de = 'Bulk email ""%1"" was not completed.';ro = 'Bulk email ""%1"" was not completed.';tr = 'Bulk email ""%1"" was not completed.'; es_ES = 'Bulk email ""%1"" was not completed.'");
			ElsIf TableRow.WithErrors Then
				MessageTemplate = NStr("ru = 'Рассылка ""%1"" выполнена с ошибками.'; en = 'Bulk email ""%1"" has completed with errors.'; pl = 'Bulk email ""%1"" has completed with errors.';de = 'Bulk email ""%1"" has completed with errors.';ro = 'Bulk email ""%1"" has completed with errors.';tr = 'Bulk email ""%1"" has completed with errors.'; es_ES = 'Bulk email ""%1"" has completed with errors.'");
			Else
				MessageTemplate = NStr("ru = 'Рассылка ""%1"" выполнена.'; en = 'Bulk email ""%1"" is completed.'; pl = 'Bulk email ""%1"" is completed.';de = 'Bulk email ""%1"" is completed.';ro = 'Bulk email ""%1"" is completed.';tr = 'Bulk email ""%1"" is completed.'; es_ES = 'Bulk email ""%1"" is completed.'");
			EndIf;
			MessageTemplate = StringFunctionsClientServer.SubstituteParametersToString(MessageTemplate, TableRow.Presentation);
			
			If MessageText = "" Then
				MessageText = MessageTemplate;
			Else
				MessageText = MessageText + Chars.LF + Chars.LF + MessageTemplate;
			EndIf;
		EndDo;
	Else
		MessageText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Подготовлено рассылок: %1 из %2
			|Выполнено: %3
			|С ошибками: %4
			|Не выполнено: %5'; 
			|en = 'Prepared mailings: %1 of %2
			|Completed: %3
			|With errors: %4
			|Not completed: %5'; 
			|pl = 'Prepared mailings: %1 of %2
			|Completed: %3
			|With errors: %4
			|Not completed: %5';
			|de = 'Prepared mailings: %1 of %2
			|Completed: %3
			|With errors: %4
			|Not completed: %5';
			|ro = 'Prepared mailings: %1 of %2
			|Completed: %3
			|With errors: %4
			|Not completed: %5';
			|tr = 'Prepared mailings: %1 of %2
			|Completed: %3
			|With errors: %4
			|Not completed: %5'; 
			|es_ES = 'Prepared mailings: %1 of %2
			|Completed: %3
			|With errors: %4
			|Not completed: %5'"),
			Format(Prepared, "NZ=0; NG=0"), Format(Total, "NZ=0; NG=0"),
			Format(Completed,    "NZ=0; NG=0"),
			Format(WithErrors,    "NZ=0; NG=0"),
			Format(NotCompleted,  "NZ=0; NG=0"));
	EndIf;
	
	Result = New Structure;
	Result.Insert("BulkEmails", MailingsTable.UnloadColumn("BulkEmail"));
	Result.Insert("Text", MessageText);
	Result.Insert("More", MessagesToUserString(MessagesArray));
	PutToTempStorage(Result, ResultAddress);
EndProcedure

#Region ObsoleteProceduresAndFunctions

// Obsolete. Use ExecuteReportsMailing.
// Generates reports and sends them according to the transport settings (Foder, FILE, EMAIL, FTP);
//
// Parameters:
//   Mailing - CatalogRef.ReportMailings - a report mailing to be executed.
//   LogParameters - Structure - parameters of the writing to the event log.
//       * EventName - String - an event name (or events group).
//       * Metadata - MetadataObject - metadata to link the event of the event log.
//       * Data - Arbitrary - data to link the event of the event log.
//   AdditionalSettings - Structure - settings that redefine the standard mailing parameters.
//       * Recipients - Map - a set of recipients and their email addresses.
//           ** Key - CatalogRef - a recipient.
//           ** Value - String - a set of recipient e-mail addresses in the row with separators.
//
// Returns:
//   Boolean - a flag of successful mailing completion.
//
Function PrepareParametersAndExecuteMailing(BulkEmail, LogParameters = Undefined, AdditionalSettings = Undefined) Export
	
	Return ExecuteReportsMailing(BulkEmail, LogParameters, AdditionalSettings);
	
EndFunction

#EndRegion

#EndRegion

#Region Internal

// Adds commands for creating mailings to the report form.
//
// Usage locations:
//   CommonForm.ReportForm.OnCreateAtServer().
//
Procedure ReportFormAddCommands(Form, Cancel, StandardProcessing) Export
	
	// Mailings can be added only if there is an option link (it is internal or additional).
	If Form.ReportSettings.External Then
		Return;
	EndIf;
	If Not InsertRight() Then
		Return;
	EndIf;
	
	// Add commands and buttons
	Commands = New Array;
	
	CreateCommand = Form.Commands.Add("ReportMailingCreateNew");
	CreateCommand.Action  = "ReportMailingClient.CreateNewBulkEmailFromReport";
	CreateCommand.Picture  = PictureLib.ReportMailing;
	CreateCommand.Title = NStr("ru = 'Создать рассылку отчетов...'; en = 'Create report bulk email...'; pl = 'Create report bulk email...';de = 'Create report bulk email...';ro = 'Create report bulk email...';tr = 'Create report bulk email...'; es_ES = 'Create report bulk email...'");
	CreateCommand.ToolTip = NStr("ru = 'Создать новую рассылку отчетов и добавить в нее отчет с текущими настройками.'; en = 'Create new report bulk email and add a report with current settings to it.'; pl = 'Create new report bulk email and add a report with current settings to it.';de = 'Create new report bulk email and add a report with current settings to it.';ro = 'Create new report bulk email and add a report with current settings to it.';tr = 'Create new report bulk email and add a report with current settings to it.'; es_ES = 'Create new report bulk email and add a report with current settings to it.'");
	Commands.Add(CreateCommand);
	
	AttachCommand = Form.Commands.Add("ReportMailingAddToExisting");
	AttachCommand.Action  = "ReportMailingClient.AttachReportToExistingBulkEmail";
	AttachCommand.Title = NStr("ru = 'Включить в существующую рассылку отчетов...'; en = 'Include in the existing report bulk email...'; pl = 'Include in the existing report bulk email...';de = 'Include in the existing report bulk email...';ro = 'Include in the existing report bulk email...';tr = 'Include in the existing report bulk email...'; es_ES = 'Include in the existing report bulk email...'");
	AttachCommand.ToolTip = NStr("ru = 'Присоединить отчет с текущими настройками к существующей рассылке отчетов.'; en = 'Attach the report with current settings to the existing report bulk email.'; pl = 'Attach the report with current settings to the existing report bulk email.';de = 'Attach the report with current settings to the existing report bulk email.';ro = 'Attach the report with current settings to the existing report bulk email.';tr = 'Attach the report with current settings to the existing report bulk email.'; es_ES = 'Attach the report with current settings to the existing report bulk email.'");
	Commands.Add(AttachCommand);
	
	MailingsWithReportsNumber = MailingsWithReportsNumber(Form.ReportSettings.OptionRef);
	If MailingsWithReportsNumber > 0 Then
		MailingsCommand = Form.Commands.Add("ReportMailingOpenMailingsWithReport");
		MailingsCommand.Action  = "ReportMailingClient.OpenBulkEmailsWithReport";
		MailingsCommand.Title = StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = 'Рассылки отчета (%1)'; en = 'Report bulk emails (%1)'; pl = 'Report bulk emails (%1)';de = 'Report bulk emails (%1)';ro = 'Report bulk emails (%1)';tr = 'Report bulk emails (%1)'; es_ES = 'Report bulk emails (%1)'"), 
			MailingsWithReportsNumber);
		MailingsCommand.ToolTip = NStr("ru = 'Открыть список рассылок, в которые включен отчет.'; en = 'Open list of mailings containing the report.'; pl = 'Open list of mailings containing the report.';de = 'Open list of mailings containing the report.';ro = 'Open list of mailings containing the report.';tr = 'Open list of mailings containing the report.'; es_ES = 'Open list of mailings containing the report.'");
		Commands.Add(MailingsCommand);
	EndIf;
	
	ReportsServer.OutputCommand(Form, Commands, "SubmenuSend", False, False, "ReportMailing");
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Update the infobase.

// Intended for moving passwords to a secure storage.
// This procedure is used in the infobase update handler.
Procedure MovePasswordsToSecureStorage() Export
	
	Query = New Query;
	Query.Text = 
	"SELECT
	|	ReportMailings.Ref, ReportMailings.DeleteFTPPassword, ReportMailings.DeleteArchivePassword
	|FROM
	|	Catalog.ReportMailings AS ReportMailings";
	
	QueryResult = Query.Execute().Select();
	While QueryResult.Next() Do
		If Not IsBlankString(QueryResult.DeleteFTPPassword) 
			Or Not IsBlankString(QueryResult.DeleteArchivePassword) Then
			BeginTransaction();
			Try
				SetPrivilegedMode(True);
				Common.WriteDataToSecureStorage(QueryResult.Ref, QueryResult.DeleteFTPPassword, "FTPPassword");
				Common.WriteDataToSecureStorage(QueryResult.Ref, QueryResult.DeleteArchivePassword, "ArchivePassword");
				SetPrivilegedMode(False);
				BulkEmail = QueryResult.Ref.GetObject();
				BulkEmail.DeleteFTPPassword = "";
				BulkEmail.DeleteArchivePassword = "";
				BulkEmail.Write();
				CommitTransaction();
			Except
				RollbackTransaction();
			EndTry;
		EndIf;
	EndDo;
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Administration panels.

// Returns True if the user has the right to save report mailings.
Function InsertRight() Export
	Return CheckAddRightErrorText() = "";
EndFunction

////////////////////////////////////////////////////////////////////////////////
// Configuration subsystems event handlers.

// See InfobaseUpdateSSL.OnAddUpdateHandlers. 
Procedure OnAddUpdateHandlers(Handlers) Export
	
	Handler = Handlers.Add();
	Handler.ExecutionMode = "Deferred";
	Handler.SharedData     = False;
	Handler.Version          = "2.3.3.30";
	Handler.Comment     = NStr("ru = 'Отключает неиспользуемые регламентные задания рассылок отчетов.'; en = 'Disables unused scheduled jobs of report mailing.'; pl = 'Disables unused scheduled jobs of report mailing.';de = 'Disables unused scheduled jobs of report mailing.';ro = 'Disables unused scheduled jobs of report mailing.';tr = 'Disables unused scheduled jobs of report mailing.'; es_ES = 'Disables unused scheduled jobs of report mailing.'");
	Handler.ID   = New UUID("b1467977-94b3-4282-9ece-09f127e54775");
	Handler.Procedure       = "ReportMailing.UpdateScheduledJobsList";
	Handler.DeferredProcessingQueue          = 1;
	Handler.UpdateDataFillingProcedure = "ReportMailing.RegisterDataForUpdatingScheduledJobsList";
	Handler.ObjectsToBeRead                     = "Catalog.ReportMailings";
	Handler.ObjectsToChange                   = "ScheduledJob.ReportMailing";
	Handler.ExecutionPriorities                = InfobaseUpdate.HandlerExecutionPriorities();
	
	Handler = Handlers.Add();
	Handler.InitialFilling = True;
	Handler.ExecutionMode = "Seamless";
	Handler.Procedure = "ReportMailing.FillPredefinedItemDescriptionPersonalBulkEmail";
	
EndProcedure

// See SafeModeManagerOverridable.OnFillPermissionsToAccessExternalResources. 
Procedure OnFillPermissionsToAccessExternalResources(PermissionRequests) Export
	
	If Not Common.SeparatedDataUsageAvailable() Then
		Return;
	EndIf;
	
	QueryText = 
	"SELECT
	|	ReportMailings.Ref,
	|	ReportMailings.UseFTPResource,
	|	ReportMailings.FTPServer,
	|	ReportMailings.FTPDirectory,
	|	ReportMailings.FTPPort,
	|	ReportMailings.UseNetworkDirectory,
	|	ReportMailings.NetworkDirectoryWindows,
	|	ReportMailings.NetworkDirectoryLinux
	|FROM
	|	Catalog.ReportMailings AS ReportMailings
	|WHERE
	|	ReportMailings.DeletionMark = FALSE
	|	AND (ReportMailings.UseNetworkDirectory = TRUE
	|		OR ReportMailings.UseFTPResource = TRUE)";
	
	Query = New Query;
	Query.Text = QueryText;
	
	ModuleSafeModeManager = Common.CommonModule("SafeModeManager");
	
	BulkEmail = Query.Execute().Select();
	While BulkEmail.Next() Do
		
		PermissionRequests.Add(
			ModuleSafeModeManager.RequestToUseExternalResources(
				PermissionsToUseServerResources(BulkEmail), BulkEmail.Ref));
		
	EndDo;
	
EndProcedure

// See ToDoListOverridable.OnDetermineToDoListHandlers 
Procedure OnFillToDoList(ToDoList) Export
	If Not InsertRight() Then
		Return;
	EndIf;
	
	ToDoName = "ReportMailingIssues";
	ModuleToDoListServer = Common.CommonModule("ToDoListServer");
	If ModuleToDoListServer.UserTaskDisabled(ToDoName) Then
		Return;
	EndIf;
	
	Query = New Query;
	Query.Text =
		"SELECT ALLOWED
		|	COUNT(ReportMailings.Ref) AS Count
		|FROM
		|	InformationRegister.ReportMailingStates AS ReportMailingStates
		|		INNER JOIN Catalog.ReportMailings AS ReportMailings
		|		ON ReportMailingStates.BulkEmail = ReportMailings.Ref
		|WHERE
		|	ReportMailings.Prepared = TRUE
		|	AND ReportMailingStates.WithErrors = TRUE
		|	AND ReportMailings.Author = &Author";
	Filters = New Structure;
	Filters.Insert("DeletionMark", False);
	Filters.Insert("Prepared", True);
	Filters.Insert("WithErrors", True);
	Filters.Insert("IsFolder", False);
	If Users.IsFullUser() Then
		Query.Text = StrReplace(Query.Text, "AND ReportMailings.Author = &Author", "");
	Else
		Filters.Insert("Author", Users.CurrentUser());
		Query.SetParameter("Author", Filters.Author);
	EndIf;
	IssuesCount = Query.Execute().Unload()[0].Count;
	
	FormParameters = New Structure;
	FormParameters.Insert("Filter", Filters);
	FormParameters.Insert("Representation", "List");
	
	Sections = ModuleToDoListServer.SectionsForObject(Metadata.Catalogs.ReportMailings.FullName());
	For Each Section In Sections Do
		ToDoItem = ToDoList.Add();
		ToDoItem.ID  = ToDoName + StrReplace(Section.FullName(), ".", "");
		ToDoItem.HasToDoItems       = IssuesCount > 0;
		ToDoItem.Presentation  = NStr("ru = 'Проблемы с рассылками отчетов'; en = 'Report bulk email issues'; pl = 'Report bulk email issues';de = 'Report bulk email issues';ro = 'Report bulk email issues';tr = 'Report bulk email issues'; es_ES = 'Report bulk email issues'");
		ToDoItem.Count     = IssuesCount;
		ToDoItem.Form          = "Catalog.ReportMailings.ListForm";
		ToDoItem.FormParameters = FormParameters;
		ToDoItem.Important         = True;
		ToDoItem.Owner       = Section;
	EndDo;
EndProcedure

// See BatchObjectModificationOverridable.OnDetermineObjectsWithEditableAttributes. 
Procedure OnDefineObjectsWithEditableAttributes(Objects) Export
	Objects.Insert(Metadata.Catalogs.ReportMailings.FullName(), "AttributesToSkipInBatchProcessing");
EndProcedure

// See ScheduledJobsOverridable.OnDefineScheduledJobsSettings. 
Procedure OnDefineScheduledJobSettings(Dependencies) Export
	Dependence = Dependencies.Add();
	Dependence.ScheduledJob = Metadata.ScheduledJobs.ReportMailing;
	Dependence.UseExternalResources = True;
	Dependence.IsParameterized = True;
EndProcedure

// See AccessManagementOverridable.OnFillListsWithAccessRestriction. 
Procedure OnFillListsWithAccessRestriction(Lists) Export
	
	Lists.Insert(Metadata.Catalogs.ReportMailings, True);
	
EndProcedure

#EndRegion

#Region Private

////////////////////////////////////////////////////////////////////////////////
// Updating an infobase.

// [2.3.3.30] Registers data to execute the UpdateScheduledJobsList handler.
Procedure RegisterDataForUpdatingScheduledJobsList(Parameters) Export
	
	Query = New Query;
	Query.Text = "SELECT
	               |	ReportMailings.Ref AS Ref
	               |FROM
	               |	Catalog.ReportMailings AS ReportMailings
	               |WHERE
	               |	NOT(ReportMailings.Prepared
	               |				AND ReportMailings.ExecuteOnSchedule)
	               |	AND ReportMailings.IsFolder = FALSE";
	RefsArray = Query.Execute().Unload().UnloadColumn("Ref");
	InfobaseUpdate.MarkForProcessing(Parameters, RefsArray);
	
EndProcedure

// [2.3.3.30] Disable unused scheduled jobs of report mailings.
Procedure UpdateScheduledJobsList(Parameters) Export
	
	ReportMailings = InfobaseUpdate.SelectRefsToProcess(Parameters.Queue, "Catalog.ReportMailings");
	ObjectsWithIssuesCount = 0;
	ObjectsProcessed = 0;
	
	While ReportMailings.Next() Do
		Try
			If ReportMailings.Ref <> NULL AND ReportMailings.Ref.ScheduledJob <> NULL Then
				Job = ScheduledJobsServer.Job(ReportMailings.Ref.ScheduledJob);
				If Job <> Undefined AND Job.Use Then
					Job.Use = False;
					Job.Write();
				EndIf;
			EndIf;
			ObjectsProcessed = ObjectsProcessed + 1;
			InfobaseUpdate.MarkProcessingCompletion(ReportMailings.Ref);
		Except
			// If you fail to process any report mailing, try again.
			ObjectsWithIssuesCount = ObjectsWithIssuesCount + 1;
			
			ObjectType = String(TypeOf(ReportMailings.Ref.ScheduledJob));
			MessageText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Не удалось обработать регламентное задание рассылки отчетов: %1 с типом %2 по причине: %3'; en = 'Cannot process scheduled job of report bulk email: %1 with the %2 type due to: %3'; pl = 'Cannot process scheduled job of report bulk email: %1 with the %2 type due to: %3';de = 'Cannot process scheduled job of report bulk email: %1 with the %2 type due to: %3';ro = 'Cannot process scheduled job of report bulk email: %1 with the %2 type due to: %3';tr = 'Cannot process scheduled job of report bulk email: %1 with the %2 type due to: %3'; es_ES = 'Cannot process scheduled job of report bulk email: %1 with the %2 type due to: %3'"),
			String(ReportMailings.Ref), ObjectType, DetailErrorDescription(ErrorInfo()));
			WriteLogEvent(InfobaseUpdate.EventLogEvent(), EventLogLevel.Warning,
			Metadata.Catalogs.ReportMailings, ReportMailings.Ref, MessageText);
		EndTry;
	EndDo;
	
	Parameters.ProcessingCompleted = InfobaseUpdate.DataProcessingCompleted(Parameters.Queue, "Catalog.ReportMailings");
	
	If ObjectsProcessed = 0 AND ObjectsWithIssuesCount <> 0 Then
		MessageText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Процедуре АктуализироватьСписокРегламентныхЗаданий не удалось обработать некоторые регламентные задания рассылки отчетов (пропущены): %1'; en = 'The UpdateScheduledJobsList procedure cannot process some scheduled jobs of report bulk email (skipped): %1'; pl = 'The UpdateScheduledJobsList procedure cannot process some scheduled jobs of report bulk email (skipped): %1';de = 'The UpdateScheduledJobsList procedure cannot process some scheduled jobs of report bulk email (skipped): %1';ro = 'The UpdateScheduledJobsList procedure cannot process some scheduled jobs of report bulk email (skipped): %1';tr = 'The UpdateScheduledJobsList procedure cannot process some scheduled jobs of report bulk email (skipped): %1'; es_ES = 'The UpdateScheduledJobsList procedure cannot process some scheduled jobs of report bulk email (skipped): %1'"), 
				ObjectsWithIssuesCount);
		Raise MessageText;
	Else
		WriteLogEvent(InfobaseUpdate.EventLogEvent(), EventLogLevel.Information,
			Metadata.Catalogs.ReportMailings,,
				StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = 'Процедура АктуализироватьСписокРегламентныхЗаданий обработала очередную порцию рассылки отчетов: %1'; en = 'The UpdateScheduledJobsList procedure has processed report bulk emails: %1'; pl = 'The UpdateScheduledJobsList procedure has processed report bulk emails: %1';de = 'The UpdateScheduledJobsList procedure has processed report bulk emails: %1';ro = 'The UpdateScheduledJobsList procedure has processed report bulk emails: %1';tr = 'The UpdateScheduledJobsList procedure has processed report bulk emails: %1'; es_ES = 'The UpdateScheduledJobsList procedure has processed report bulk emails: %1'"),
					ObjectsProcessed));
	EndIf;
	
EndProcedure

// The procedure is called on update to SL version 3.0.2.128 and during the initial filling.
Procedure FillPredefinedItemDescriptionPersonalBulkEmail() Export
	
	PersonalMailings = Catalogs.ReportMailings.PersonalMailings.GetObject();
	PersonalMailings.Description = NStr("ru='Личные рассылки'; en = 'Personal mailings'; pl = 'Personal mailings';de = 'Personal mailings';ro = 'Personal mailings';tr = 'Personal mailings'; es_ES = 'Personal mailings'");
	InfobaseUpdate.WriteObject(PersonalMailings);
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Scheduled job execution.

// Starts mailing and controls result.
//
// Parameters:
//   Mailing - CatalogRef.ReportMailings - a report mailing to be executed.
//
Procedure ExecuteScheduledMailing(BulkEmail) Export
	
	// Checks.
	Common.OnStartExecuteScheduledJob(Metadata.ScheduledJobs.ReportMailing);
	
	// Register startup (started but not completed).
	InformationRegisters.ReportMailingStates.FixMailingStart(BulkEmail);
	
	If Not AccessRight("Read", Metadata.Catalogs.ReportMailings) Then
		Raise
			NStr("ru = 'У текущего пользователя недостаточно прав для чтения рассылок отчетов.
				|Рекомендуется отключить все рассылки этого пользователя или сменить автора его рассылок (на вкладке ""Расписание"").'; 
				|en = 'The current user has insufficient rights to view report bulk mails. 
				|It is recommended that you unsubscribe this user from all bulk mails or change the author of their mailings (on the Schedule tab).'; 
				|pl = 'The current user has insufficient rights to view report bulk mails. 
				|It is recommended that you unsubscribe this user from all bulk mails or change the author of their mailings (on the Schedule tab).';
				|de = 'The current user has insufficient rights to view report bulk mails. 
				|It is recommended that you unsubscribe this user from all bulk mails or change the author of their mailings (on the Schedule tab).';
				|ro = 'The current user has insufficient rights to view report bulk mails. 
				|It is recommended that you unsubscribe this user from all bulk mails or change the author of their mailings (on the Schedule tab).';
				|tr = 'The current user has insufficient rights to view report bulk mails. 
				|It is recommended that you unsubscribe this user from all bulk mails or change the author of their mailings (on the Schedule tab).'; 
				|es_ES = 'The current user has insufficient rights to view report bulk mails. 
				|It is recommended that you unsubscribe this user from all bulk mails or change the author of their mailings (on the Schedule tab).'");
	EndIf;
	Query = New Query("SELECT ALLOWED ExecuteOnSchedule FROM Catalog.ReportMailings WHERE Ref = &Ref");
	Query.SetParameter("Ref", BulkEmail);
	Selection = Query.Execute().Select();
	If Not Selection.Next() Then
		Raise
			NStr("ru = 'У текущего пользователя недостаточно прав для чтения этой рассылки.
				|Рекомендуется сменить автора рассылки (на вкладке ""Расписание"").'; 
				|en = 'The current user has insufficient rights to read this bulk email. 
				|It is recommended that you change the bulk email author (on the Schedule tab).'; 
				|pl = 'The current user has insufficient rights to read this bulk email. 
				|It is recommended that you change the bulk email author (on the Schedule tab).';
				|de = 'The current user has insufficient rights to read this bulk email. 
				|It is recommended that you change the bulk email author (on the Schedule tab).';
				|ro = 'The current user has insufficient rights to read this bulk email. 
				|It is recommended that you change the bulk email author (on the Schedule tab).';
				|tr = 'The current user has insufficient rights to read this bulk email. 
				|It is recommended that you change the bulk email author (on the Schedule tab).'; 
				|es_ES = 'The current user has insufficient rights to read this bulk email. 
				|It is recommended that you change the bulk email author (on the Schedule tab).'");
	EndIf;
	If Not Selection.ExecuteOnSchedule Then
		Raise StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'У рассылки отчетов ""%1"" отключен флажок ""Выполнять по расписанию""
				|Рекомендуется отключить соответствующее регламентное задание или перезаписать эту рассылку.'; 
				|en = 'The ""Run on schedule"" check box is cleared for bulk email of reports ""%1"". 
				|It is recommended that you disable the corresponding scheduled job or rewrite the bulk email.'; 
				|pl = 'The ""Run on schedule"" check box is cleared for bulk email of reports ""%1"". 
				|It is recommended that you disable the corresponding scheduled job or rewrite the bulk email.';
				|de = 'The ""Run on schedule"" check box is cleared for bulk email of reports ""%1"". 
				|It is recommended that you disable the corresponding scheduled job or rewrite the bulk email.';
				|ro = 'The ""Run on schedule"" check box is cleared for bulk email of reports ""%1"". 
				|It is recommended that you disable the corresponding scheduled job or rewrite the bulk email.';
				|tr = 'The ""Run on schedule"" check box is cleared for bulk email of reports ""%1"". 
				|It is recommended that you disable the corresponding scheduled job or rewrite the bulk email.'; 
				|es_ES = 'The ""Run on schedule"" check box is cleared for bulk email of reports ""%1"". 
				|It is recommended that you disable the corresponding scheduled job or rewrite the bulk email.'"),
			String(BulkEmail));
	EndIf;
	
	// Parameters of the writing to the event log.
	LogParameters = New Structure("EventName, Metadata, Data");
	LogParameters.EventName = NStr("ru = 'Рассылка отчетов. Запуск по расписанию'; en = 'Report bulk email. Run on schedule'; pl = 'Report bulk email. Run on schedule';de = 'Report bulk email. Run on schedule';ro = 'Report bulk email. Run on schedule';tr = 'Report bulk email. Run on schedule'; es_ES = 'Report bulk email. Run on schedule'", Common.DefaultLanguageCode());
	LogParameters.Metadata = BulkEmail.Metadata();
	LogParameters.Data     = BulkEmail;
	
	// BulkEmail
	ExecuteReportsMailing(BulkEmail, LogParameters, New Structure("StartCommitted", True));
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Internal export procedures and functions.

// Generate a recipients list from the Recipients tabular section of mailing.
//
// Parameters:
//   Mailing - CatalogRef.ReportMailings, Structure - a catalog item for which recipients list 
//              generating is required.
//
// Returns:
//   Structure - a result of the mailing recipients list receiving.
//       * Recipients - Map - Recipients. See ExecuteMailing(), description for the  DeliveryParameters.Recipients.
//       * Errors- String - errors that occurred in the process.
//
Function GenerateMailingRecipientsList(LogParameters, BulkEmail) Export
	
	CIKind = BulkEmail.RecipientEmailAddressKind;
	
	If BulkEmail.Personal Then
		
		TSAttributes = Metadata.Catalogs.ReportMailings.TabularSections.Recipients.Attributes;
		
		RecipientsType = TypeOf(BulkEmail.Author);
		RecipientsTable = New ValueTable;
		For Each Attribute In TSAttributes Do
			RecipientsTable.Columns.Add(Attribute.Name, Attribute.Type);
		EndDo;
		RecipientsTable.Add().Recipient = BulkEmail.Author;
		
	Else
		
		RecipientsType = BulkEmail.MailingRecipientType.MetadataObjectKey.Get();
		RecipientsTable = BulkEmail.Recipients.Unload();
		
	EndIf;
	
	RecipientsList = New Map;
	
	Query = New Query;
	If RecipientsType = Type("CatalogRef.Users") Then
	
		QueryText =
		"SELECT
		|	RecipientsTable.Recipient,
		|	RecipientsTable.Excluded
		|INTO ttRecipientTable
		|FROM
		|	&RecipientsTable AS RecipientsTable
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT ALLOWED DISTINCT
		|	MAX(ReportMailingRecipients.Excluded) AS Excluded,
		|	UserGroupCompositions.User
		|INTO ttRecipients
		|FROM
		|	ttRecipientTable AS ReportMailingRecipients
		|		INNER JOIN InformationRegister.UserGroupCompositions AS UserGroupCompositions
		|		ON ReportMailingRecipients.Recipient = UserGroupCompositions.UsersGroup
		|			AND (UserGroupCompositions.UsersGroup.DeletionMark = FALSE)
		|WHERE
		|	UserGroupCompositions.User REFS Catalog.Users
		|	AND UserGroupCompositions.User.DeletionMark = FALSE
		|	AND UserGroupCompositions.User.Invalid = FALSE
		|	AND UserGroupCompositions.User.Internal = FALSE
		|
		|GROUP BY
		|	UserGroupCompositions.User
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT ALLOWED DISTINCT
		|	ttRecipients.User AS Recipient,
		|	tsContactInformation.Presentation AS EMail
		|FROM
		|	ttRecipients AS ttRecipients
		|		LEFT JOIN Catalog.Users.ContactInformation AS tsContactInformation
		|		ON ttRecipients.User = tsContactInformation.Ref
		|WHERE
		|	ttRecipients.Excluded = FALSE
		|	AND tsContactInformation.Kind = &CIKind";
		
	Else
		
		QueryText =
		"SELECT
		|	RecipientsTable.Recipient,
		|	RecipientsTable.Excluded
		|INTO ttRecipientTable
		|FROM
		|	&RecipientsTable AS RecipientsTable
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT ALLOWED DISTINCT
		|	RecipientsCatalog.Ref AS Recipient,
		|	tsContactInformation.Presentation AS EMail
		|FROM
		|	Catalog.Users AS RecipientsCatalog
		|		LEFT JOIN Catalog.Users.ContactInformation AS tsContactInformation
		|		ON (tsContactInformation.Ref = RecipientsCatalog.Ref)
		|			AND (tsContactInformation.Kind = &CIKind)
		|WHERE
		|	RecipientsCatalog.Ref IN HIERARCHY
		|			(SELECT
		|				Recipients.Recipient
		|			FROM
		|				ttRecipientTable AS Recipients
		|			WHERE
		|				Recipients.Excluded = FALSE)
		|	AND (NOT RecipientsCatalog.Ref IN HIERARCHY
		|				(SELECT
		|					RecipientExclusions.Recipient
		|				FROM
		|					ttRecipientTable AS RecipientExclusions
		|				WHERE
		|					RecipientExclusions.Excluded = TRUE))
		|	AND RecipientsCatalog.DeletionMark = FALSE
		|	AND &ThisIsNotGroup";
		
		SetPrivilegedMode(True);
		MetadataRecipients = Metadata.FindByType(RecipientsType);
		SetPrivilegedMode(False);
		
		If Not MetadataRecipients.Hierarchical Then
			// Not hierarchical
			QueryText = StrReplace(QueryText, "IN HIERARCHY", "IN");
			QueryText = StrReplace(QueryText, "AND &ThisIsNotGroup", "");
		ElsIf MetadataRecipients.HierarchyType = Metadata.ObjectProperties.HierarchyType.HierarchyOfItems Then
			// Item hierarchy
			QueryText = StrReplace(QueryText, "AND &ThisIsNotGroup", "");
		Else
			// Group hierarchy
			QueryText = StrReplace(QueryText, "AND &ThisIsNotGroup", "AND RecipientsCatalog.IsFolder = FALSE");
		EndIf;
		
		QueryText = StrReplace(QueryText, "Catalog.Users", MetadataRecipients.FullName());
		
	EndIf;
	
	Query.SetParameter("RecipientsTable", RecipientsTable);
	If ValueIsFilled(CIKind) Then
		Query.SetParameter("CIKind", CIKind);
	Else
		QueryText = StrReplace(QueryText, ".Kind = &CIKind", ".Type = &CIType");
		Query.SetParameter("CIType", Enums.ContactInformationTypes.EmailAddress);
	EndIf;
	Query.Text = QueryText;
	
	ErrorMessageTextForEventLog = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("ru = 'При формировании списка получателей ""%1"" возникла ошибка:'; en = 'An error occurred when generating list of recipients ""%1"":'; pl = 'An error occurred when generating list of recipients ""%1"":';de = 'An error occurred when generating list of recipients ""%1"":';ro = 'An error occurred when generating list of recipients ""%1"":';tr = 'An error occurred when generating list of recipients ""%1"":'; es_ES = 'An error occurred when generating list of recipients ""%1"":'"), String(RecipientsType));
	
	//  Extension mechanism
	Try
		StandardProcessing = True;
		ReportMailingOverridable.BeforeGenerateMailingRecipientsList(BulkEmail, Query, StandardProcessing, RecipientsList);
		If StandardProcessing <> True Then
			Return RecipientsList;
		EndIf;
	Except
		LogRecord(LogParameters,, ErrorMessageTextForEventLog, ErrorInfo());
		Return RecipientsList;
	EndTry;
	
	// Standard processing
	Try
		VTTotal = Query.Execute().Unload();
	Except
		LogRecord(LogParameters,, ErrorMessageTextForEventLog, ErrorInfo());
		Return RecipientsList;
	EndTry;
	
	For Each RowTotal In VTTotal Do
		If Not ValueIsFilled(RowTotal.EMail) Then
			Continue;
		EndIf;
		
		CurrentAddress = RecipientsList.Get(RowTotal.Recipient);
		If CurrentAddress = Undefined Then
			CurrentAddress = "";
		Else
			CurrentAddress = CurrentAddress +"; ";
		EndIf;
		CurrentAddress = CurrentAddress + RowTotal.EMail;
		RecipientsList.Insert(RowTotal.Recipient, CurrentAddress);
	EndDo;
	
	If RecipientsList.Count() = 0 Then
		ErrorsText = NStr("ru = 'Не удалось сформировать список получателей %1 рассылки %2 по одной из возможных причин:
		| - У получателей не заполнен почтовый адрес %3;
		| - Не заполнен список получателей;
		| - Выбраны пустые группы получателей;
		| - Получатели помечены на удаление;
		| - Исключены все получатели (исключение имеет наивысший приоритет; участники исключенных групп также исключаются из списка);
		| - Недостаточно прав доступа к справочнику;
		| - Рекомендуется проверить корректность настройки учетной записи электронной почты, от имени которой выполняется рассылка.'; 
		|en = 'Cannot generate a list of recipients %1 of the %2 bulk email due to one of the reasons:
		| - Recipient email address %3 is not filled in
		| - Recipient list is not filled in
		| - Empty recipient groups are selected
		| - Recipients are marked for deletion
		| - All recipients are excluded (exclusion has the highest priority; participants of excluded groups are excluded from the list as well)
		| - Insufficient rights to access the catalog
		| - It is recommended that you check whether setting of the email account used for bulk email is correct.'; 
		|pl = 'Cannot generate a list of recipients %1 of the %2 bulk email due to one of the reasons:
		| - Recipient email address %3 is not filled in
		| - Recipient list is not filled in
		| - Empty recipient groups are selected
		| - Recipients are marked for deletion
		| - All recipients are excluded (exclusion has the highest priority; participants of excluded groups are excluded from the list as well)
		| - Insufficient rights to access the catalog
		| - It is recommended that you check whether setting of the email account used for bulk email is correct.';
		|de = 'Cannot generate a list of recipients %1 of the %2 bulk email due to one of the reasons:
		| - Recipient email address %3 is not filled in
		| - Recipient list is not filled in
		| - Empty recipient groups are selected
		| - Recipients are marked for deletion
		| - All recipients are excluded (exclusion has the highest priority; participants of excluded groups are excluded from the list as well)
		| - Insufficient rights to access the catalog
		| - It is recommended that you check whether setting of the email account used for bulk email is correct.';
		|ro = 'Cannot generate a list of recipients %1 of the %2 bulk email due to one of the reasons:
		| - Recipient email address %3 is not filled in
		| - Recipient list is not filled in
		| - Empty recipient groups are selected
		| - Recipients are marked for deletion
		| - All recipients are excluded (exclusion has the highest priority; participants of excluded groups are excluded from the list as well)
		| - Insufficient rights to access the catalog
		| - It is recommended that you check whether setting of the email account used for bulk email is correct.';
		|tr = 'Cannot generate a list of recipients %1 of the %2 bulk email due to one of the reasons:
		| - Recipient email address %3 is not filled in
		| - Recipient list is not filled in
		| - Empty recipient groups are selected
		| - Recipients are marked for deletion
		| - All recipients are excluded (exclusion has the highest priority; participants of excluded groups are excluded from the list as well)
		| - Insufficient rights to access the catalog
		| - It is recommended that you check whether setting of the email account used for bulk email is correct.'; 
		|es_ES = 'Cannot generate a list of recipients %1 of the %2 bulk email due to one of the reasons:
		| - Recipient email address %3 is not filled in
		| - Recipient list is not filled in
		| - Empty recipient groups are selected
		| - Recipients are marked for deletion
		| - All recipients are excluded (exclusion has the highest priority; participants of excluded groups are excluded from the list as well)
		| - Insufficient rights to access the catalog
		| - It is recommended that you check whether setting of the email account used for bulk email is correct.'");
		
		LogRecord(LogParameters, EventLogLevel.Error,
			StringFunctionsClientServer.SubstituteParametersToString(ErrorsText, "'"+ String(RecipientsType) +"'",
			"'"+ String(LogParameters.Data) +"'", "'"+ String(CIKind) +"'"), "");
	EndIf;
	
	Return RecipientsList;
EndFunction

// Connects, checks and initializes the report by reference and used before generating or editing 
// parameters.
//
// Parameters:
//   ReportParameters - Structure - a settings report and the result of its initialization.
//       * Report - CatalogRef.ReportOptions - a report reference.
//       * Settings - Undefined, DataCompositionUserSettings,ValueTable - 
//           Report settings to use, for details see the WriteReportsRowSettings procedure of the 
//           Catalog.ReportsMailing.ObjectForm module.
//   PersonalizationAvailable - Boolean - True if a report can be personalized.
//   UUIDOfForm - UUID - optional. DCS location address.
//
// Parameters to be changed during the method operation:
//   ReportParameters - Structure - 
//     Initialization result:
//       * Initialized - Boolean - True if was successful.
//       * Errors - String - an error text.
//     Properties of all reports:
//       * Name - String - a report name.
//       * IsOption - Boolean - True if vendor is the ReportOptions catalog.
//       * DCS - Boolean - True if a report is based on DCS.
//       * Metadata - MetadataObject: Report - report metadata.
//       * Object - ReportObject.<report name>, ExternalReport - a report object.
//     Properties of reports based on DCS:
//       * DCSSchema - DataCompositionSchema
//       * DCSettingsComposer - DataCompositionSettingsComposer
//       * DCSettings - DataCompositionSettings - 
//       * SchemaURL - String - an address of data composition schema in the temporary storage.
//     Properties of arbitrary reports:
//       * AvailableAttributes - Structure - a name and parameters of the attribute.
//           ** <Attribute name> - Structure - attribute parameters.
//               *** Presentation - String - attribute presentation.
//               *** Type - TypeDescription - attribute type.
//
// Returns:
//   Boolean - True if initialization was successful (matches the ReportParameters.Initialized).
//
Function InitializeReport(LogParameters, ReportParameters, PersonalizationAvailable, UUIDOfForm = Undefined) Export
	
	// Check reinitialization.
	If ReportParameters.Property("Initialized") Then
		Return ReportParameters.Initialized;
	EndIf;
	
	ReportParameters.Insert("Initialized", False);
	ReportParameters.Insert("Errors", "");
	ReportParameters.Insert("Personalized", False);
	ReportParameters.Insert("PersonalFilters", New Map);
	ReportParameters.Insert("IsOption", TypeOf(ReportParameters.Report) = Type("CatalogRef.ReportsOptions"));
	ReportParameters.Insert("DCS", False);
	ReportParameters.Insert("AvailableAttributes", Undefined);
	ReportParameters.Insert("DCSettingsComposer", Undefined);
	
	AttachmentParameters = New Structure;
	AttachmentParameters.Insert("OptionRef",              ReportParameters.Report);
	AttachmentParameters.Insert("FormID",          UUIDOfForm);
	AttachmentParameters.Insert("DCUserSettings", ReportParameters.Settings);
	If TypeOf(AttachmentParameters.DCUserSettings) <> Type("DataCompositionUserSettings") Then
		AttachmentParameters.DCUserSettings = New DataCompositionUserSettings;
	EndIf;
	Try
		Attachment = ReportsOptions.AttachReportAndImportSettings(AttachmentParameters);
		CommonClientServer.SupplementStructure(ReportParameters, Attachment, True);
	Except
		ReportParameters.Errors = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Не удалось подключить и загрузить настройки отчета ""%1"".'; en = 'Cannot attach report ""%1"" and load its settings.'; pl = 'Cannot attach report ""%1"" and load its settings.';de = 'Cannot attach report ""%1"" and load its settings.';ro = 'Cannot attach report ""%1"" and load its settings.';tr = 'Cannot attach report ""%1"" and load its settings.'; es_ES = 'Cannot attach report ""%1"" and load its settings.'"),
			String(ReportParameters.Report));
		LogRecord(
			LogParameters,
			EventLogLevel.Error,
			ReportParameters.Errors,
			ErrorInfo());
		Return ReportParameters.Initialized;
	EndTry;
	
	// In existing mailings, we generate only reports that are ready for mailing.
	If ReportMailingCached.ReportsToExclude().Find(Attachment.ReportRef) <> Undefined Then
		ReportParameters.Errors = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Отчет ""%1"" не предназначен для рассылки.
			|Подробнее см. в процедуре ОпределитьИсключаемыеОтчеты модуля РассылкаОтчетовПереопределяемый.'; 
			|en = 'Report ""%1"" is not intended for bulk mail.
			|For more information, see procedure DetermineReportsToExclude of module ReportMailingOverridable.'; 
			|pl = 'Report ""%1"" is not intended for bulk mail.
			|For more information, see procedure DetermineReportsToExclude of module ReportMailingOverridable.';
			|de = 'Report ""%1"" is not intended for bulk mail.
			|For more information, see procedure DetermineReportsToExclude of module ReportMailingOverridable.';
			|ro = 'Report ""%1"" is not intended for bulk mail.
			|For more information, see procedure DetermineReportsToExclude of module ReportMailingOverridable.';
			|tr = 'Report ""%1"" is not intended for bulk mail.
			|For more information, see procedure DetermineReportsToExclude of module ReportMailingOverridable.'; 
			|es_ES = 'Report ""%1"" is not intended for bulk mail.
			|For more information, see procedure DetermineReportsToExclude of module ReportMailingOverridable.'"),
			String(Attachment.ReportRef));
		LogRecord(LogParameters, EventLogLevel.Error, ReportParameters.Errors);
		Return False;
	EndIf;
	If Not Attachment.Success Then
		LogRecord(LogParameters, EventLogLevel.Error, Attachment.ErrorText);
		Return False;
	EndIf;
	ReportParameters.DCSettingsComposer = Attachment.Object.SettingsComposer;
	
	// Determine whether the report belongs to the Data Composition System.
	If TypeOf(ReportParameters.Settings) = Type("DataCompositionUserSettings") Then
		ReportParameters.DCS = True;
	ElsIf TypeOf(ReportParameters.Settings) = Type("ValueTable") Then
		ReportParameters.DCS = False;
	ElsIf TypeOf(ReportParameters.Settings) = Type("Structure") Then
		ReportParameters.DCS = False;
	Else
		ReportParameters.DCS = (ReportParameters.Object.DataCompositionSchema <> Undefined);
	EndIf;
	
	// Initialize a report and fill its parameters.
	If ReportParameters.DCS Then
		
		// Set personal filters.
		If PersonalizationAvailable Then
			DCUserSettings = ReportParameters.DCSettingsComposer.UserSettings;
			Filter = New Structure("Use, Value", True, "[Recipient]");
			FoundItems = ReportsClientServer.FindSettings(DCUserSettings.Items, Filter);
			For Each DCUserSetting In FoundItems Do
				DCID = DCUserSettings.GetIDByObject(DCUserSetting);
				If DCID <> Undefined Then
					ReportParameters.PersonalFilters.Insert(DCID);
				EndIf;
			EndDo;
		EndIf;
		
	Else // Not DCS Report.
		
		// Available report attributes
		ReportParameters.AvailableAttributes = New Structure;
		For Each Attribute In ReportParameters.Metadata.Attributes Do
			ReportParameters.AvailableAttributes.Insert(Attribute.Name, 
				New Structure("Presentation, Type", Attribute.Presentation(), Attribute.Type));
		EndDo;
		
		If ValueIsFilled(ReportParameters.Settings) Then
			
			// Check whether attributes are available.
			// Prepare personal filters mappings.
			// Set static values of attributes.
			For Each SettingDetails In ReportParameters.Settings Do
				If Type(SettingDetails) = Type("ValueTableRow") Then
					AttributeName = SettingDetails.Attribute;
				Else
					AttributeName = SettingDetails.Key;
				EndIf;
				SettingValue = SettingDetails.Value;
				
				// Attribute availability
				If Not ReportParameters.AvailableAttributes.Property(AttributeName) Then
					Continue;
				EndIf;
				
				// Belonging to the mechanism of personalization.
				If PersonalizationAvailable AND SettingValue = "[Recipient]" Then
					// Register a personal filter field.
					ReportParameters.PersonalFilters.Insert(AttributeName);
				Else
					// Set value of report object attribute.
					ReportParameters.Object[AttributeName] = SettingValue;
				EndIf;
				
			EndDo;
			
		EndIf;
		
	EndIf;
	
	ReportParameters.Personalized = (ReportParameters.PersonalFilters.Count() > 0);
	ReportParameters.Initialized = True;
	
	Return True;
EndFunction

// Generates a report and checks that the result is empty.
//
// Parameters:
//   LogParameters - Structure - parameters of the writing to the event log. See LogRecord(). 
//   ReportParameters - Structure - See InitializeReport(), return value. 
//   Recipient - CatalogRef - a recipient reference.
//
// Returns:
//   Structure - report generation result.
//       * Spreadsheet - SpreadsheetDocument - a spreadsheet document.
//       * IsEmpty - Boolean - True if the report did not contain any parameters values.
//
Function GenerateReport(LogParameters, ReportParameters, Recipient = Undefined)
	Result = New Structure("SpreadsheetDoc, Generated, IsEmpty", New SpreadsheetDocument, False, True);
	
	If Not ReportParameters.Property("Initialized") Then
		LogRecord(LogParameters, ,
			StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = 'Отчет ''%1'' не инициализирован'; en = 'Report ''%1'' is not initialized'; pl = 'Report ''%1'' is not initialized';de = 'Report ''%1'' is not initialized';ro = 'Report ''%1'' is not initialized';tr = 'Report ''%1'' is not initialized'; es_ES = 'Report ''%1'' is not initialized'"), String(ReportParameters.Report)));
		Return Result;
	EndIf;
	
	// Report connection settings.
	GenerationParameters = New Structure;
	
	// Fill personalized recipients data.
	If Recipient <> Undefined AND ReportParameters.Property("PersonalFilters") Then
		If ReportParameters.DCS Then
			DCUserSettings = ReportParameters.DCSettingsComposer.UserSettings;
			For Each KeyAndValue In ReportParameters.PersonalFilters Do
				Setting = DCUserSettings.GetObjectByID(KeyAndValue.Key);
				If TypeOf(Setting) = Type("DataCompositionFilterItem") Then
					Setting.RightValue = Recipient;
				ElsIf TypeOf(Setting) = Type("DataCompositionSettingsParameterValue") Then
					Setting.Value = Recipient;
				EndIf;
			EndDo;
			GenerationParameters.Insert("DCUserSettings", DCUserSettings);
		Else
			For Each KeyAndValue In ReportParameters.PersonalFilters Do
				ReportParameters.Object[KeyAndValue.Key] = Recipient;
			EndDo;
		EndIf;
	EndIf;
	
	GenerationParameters.Insert("Connection", ReportParameters);
	Generation = ReportsOptions.GenerateReport(GenerationParameters, True, Not ReportParameters.SendIfEmpty);
	
	If Not Generation.Success Then
		LogRecord(LogParameters, EventLogLevel.Error,
			StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = 'Отчет ""%1"":'; en = 'Report ""%1"":'; pl = 'Report ""%1"":';de = 'Report ""%1"":';ro = 'Report ""%1"":';tr = 'Report ""%1"":'; es_ES = 'Report ""%1"":'"),
			String(ReportParameters.Report)), Generation.ErrorText);
		Result.SpreadsheetDoc = Undefined;
		Return Result;
	EndIf;
	
	Result.Generated = True;
	Result.SpreadsheetDoc = Generation.SpreadsheetDocument;
	If ReportParameters.SendIfEmpty Then
		Result.IsEmpty = False;
	Else
		Result.IsEmpty = Generation.IsEmpty;
	EndIf;
	
	Return Result;
EndFunction

// Transports attachments for all delivery methods.
//
// Parameters:
//   Author - CatalogRef - a mailing author.
//   DeliveryParameters - Structure - see ExecuteMailing(). 
//   Attachments - Map - see AddReportsToAttachments(). 
//
// Returns:
//   Structure - a delivery result.
//       * Delivery - String - a delivery method presentation.
//       * Executed - Boolean - True if the delivery is executed at least by one of the methods.
//
Function ExecuteDelivery(LogParameters, DeliveryParameters, Attachments) Export
	Result = False;
	ErrorMessageTemplate = NStr("ru = 'Ошибка доставки отчетов'; en = 'Report delivery error'; pl = 'Report delivery error';de = 'Report delivery error';ro = 'Report delivery error';tr = 'Report delivery error'; es_ES = 'Report delivery error'");
	TestMode = CommonClientServer.StructureProperty(DeliveryParameters, "TestMode", False);
	
	////////////////////////////////////////////////////////////////////////////
	// To network directory.
	
	If DeliveryParameters.UseNetworkDirectory Then
		
		ServerNetworkDdirectory = DeliveryParameters.NetworkDirectoryWindows;
		SystemInfo = New SystemInfo;
		ServerPlatformType = SystemInfo.PlatformType;		
		
		If ServerPlatformType = PlatformType.Linux_x86
			Or ServerPlatformType = PlatformType.Linux_x86_64 Then
			ServerNetworkDdirectory = DeliveryParameters.NetworkDirectoryLinux;
		EndIf;
		
		Try
			For Each Attachment In Attachments Do
				FileCopy(Attachment.Value, ServerNetworkDdirectory + Attachment.Key);
				If DeliveryParameters.AddReferences <> "" Then
					DeliveryParameters.RecipientReportsPresentation = StrReplace(
						DeliveryParameters.RecipientReportsPresentation,
						Attachment.Value,
						DeliveryParameters.NetworkDirectoryWindows + Attachment.Key);
				EndIf;
			EndDo;
			Result = True;
			DeliveryParameters.ExecutedToNetworkDirectory = True;
			
			If TestMode Then // Delete all created.
				For Each Attachment In Attachments Do
					DeleteFiles(ServerNetworkDdirectory + Attachment.Key);
				EndDo;
			EndIf;
		Except
			LogRecord(LogParameters, ,
				ErrorMessageTemplate, ErrorInfo());
		EndTry;
		
	EndIf;
	
	////////////////////////////////////////////////////////////////////////////
	// To FTP resource.
	
	If DeliveryParameters.UseFTPResource Then
		
		Destination = "ftp://"+ DeliveryParameters.Server +":"+ Format(DeliveryParameters.Port, "NZ=0; NG=0") + DeliveryParameters.Directory;
		
		Try
			If Common.SubsystemExists("StandardSubsystems.GetFilesFromInternet") Then
				ModuleNetworkDownload = Common.CommonModule("GetFilesFromInternet");
				Proxy = ModuleNetworkDownload.GetProxy("ftp");
			Else
				Proxy = Undefined;
			EndIf;
			If DeliveryParameters.Property("Password") Then
				Password = DeliveryParameters.Password;
			Else
				SetPrivilegedMode(True);
				DataFromStorage = Common.ReadDataFromSecureStorage(DeliveryParameters.Owner, "FTPPassword");
				SetPrivilegedMode(False);
				Password = ?(ValueIsFilled(DataFromStorage), DataFromStorage, "");
			EndIf;
			Connection = New FTPConnection(
				DeliveryParameters.Server,
				DeliveryParameters.Port,
				DeliveryParameters.Username,
				Password,
				Proxy,
				DeliveryParameters.PassiveConnection,
				15);
			Connection.SetCurrentDirectory(DeliveryParameters.Directory);
			For Each Attachment In Attachments Do
				Connection.Put(Attachment.Value, DeliveryParameters.Directory + Attachment.Key);
				If DeliveryParameters.AddReferences <> "" Then
					DeliveryParameters.RecipientReportsPresentation = StrReplace(
						DeliveryParameters.RecipientReportsPresentation,
						Attachment.Value,
						Destination + Attachment.Key);
				EndIf;
			EndDo;
			
			Result = True;
			DeliveryParameters.ExecutedAtFTP = True;
			
			If TestMode Then // Delete all created.
				For Each Attachment In Attachments Do
					Connection.Delete(DeliveryParameters.Directory + Attachment.Key);
				EndDo;
			EndIf;
		Except
			LogRecord(LogParameters, ,
				ErrorMessageTemplate, ErrorInfo());
		EndTry;
		
	EndIf;
	
	////////////////////////////////////////////////////////////////////////////
	// To folder.
	
	If DeliveryParameters.UseDirectory Then
		
		If Common.SubsystemExists("StandardSubsystems.FilesOperations") Then
			ModuleFilesOperationsInternal = Common.CommonModule("FilesOperationsInternal");
			Try
				ModuleFilesOperationsInternal.OnExecuteDeliveryToFolder(DeliveryParameters, Attachments);
				Result = True;
				DeliveryParameters.ExecutedToFolder = True;
			Except
				LogRecord(LogParameters, ,
					ErrorMessageTemplate, ErrorInfo());
			EndTry;
		EndIf;
		
	EndIf;
	
	////////////////////////////////////////////////////////////////////////////
	// By email.
	
	If DeliveryParameters.UseEmail Then
		
		If DeliveryParameters.NotifyOnly Then
			ErrorMessageTemplate = NStr("ru = 'Невозможно отправить уведомление о рассылке по электронной почте:'; en = 'Cannot send bulk email notification by email:'; pl = 'Cannot send bulk email notification by email:';de = 'Cannot send bulk email notification by email:';ro = 'Cannot send bulk email notification by email:';tr = 'Cannot send bulk email notification by email:'; es_ES = 'Cannot send bulk email notification by email:'");
			EmailAttachments = New Map;
		Else
			ErrorMessageTemplate = NStr("ru = 'Невозможно отправить отчет по электронной почте:'; en = 'Cannot send report by email:'; pl = 'Cannot send report by email:';de = 'Cannot send report by email:';ro = 'Cannot send report by email:';tr = 'Cannot send report by email:'; es_ES = 'Cannot send report by email:'");
			EmailAttachments = Attachments;
		EndIf;
		
		Try
			SendReportsToRecipient(EmailAttachments, DeliveryParameters);
			If Not DeliveryParameters.NotifyOnly Then
				Result = True;
			EndIf;
			If Result = True Then
				DeliveryParameters.ExecutedByEmail = True;
			EndIf;
		Except
			LogRecord(LogParameters, ,
				ErrorMessageTemplate, ErrorInfo());
		EndTry;
		
	EndIf;
	
	Return Result;
EndFunction

// Gets a username by the Users catalog reference.
//
// Parameters:
//   User - CatalogRef.Users - a user reference.
//
// Returns:
//   String - a username.
//
Function IBUserName(User) Export
	If Not ValueIsFilled(User) Then
		Return Undefined;
	EndIf;
	
	SetPrivilegedMode(True);
	
	InfobaseUser = InfoBaseUsers.FindByUUID(
		Common.ObjectAttributeValue(User, "IBUserID"));
	If InfobaseUser = Undefined Then
		Return Undefined;
	EndIf;
	
	Return InfobaseUser.Name;
EndFunction

// Creates a record in the event log and in messages to a user.
//   Supports error information passing.
//
// Parameters:
//   LogParameters - Structure - parameters of the writing to the event log.
//       * EventName - String - an event name (or events group).
//       * Metadata - MetadataObject - metadata to link the event of the event log.
//       * Data - Arbitrary - data to link the event of the event log.
//       * ErrorsArray - user messages.
//   LogLevel - EventLogLevel - message importance for the administrator.
//       Determined automatically based on the ProblemDetails parameter type.
//       When type = ErrorInformation, then Error, when type = String, then Warning, otherwise 
//       Information.
//       
//   Text - String - brief details of the issue.
//   ProblemDetails - ErrorInformation, String - a problem description that is added after the text.
//       Errors brief presentation is output to the user, and an error detailed presentation is written in the log.
//
Procedure LogRecord(LogParameters, Val LogLevel = Undefined, Val Text = "", Val IssueDetails = Undefined) Export
	
	// Determine the event log level based on the type of the passed error message.
	If TypeOf(LogLevel) <> Type("EventLogLevel") Then
		If TypeOf(IssueDetails) = Type("ErrorInfo") Then
			LogLevel = EventLogLevel.Error;
		ElsIf TypeOf(IssueDetails) = Type("String") Then
			LogLevel = EventLogLevel.Warning;
		Else
			LogLevel = EventLogLevel.Information;
		EndIf;
	EndIf;
	
	WriteToLog = ValueIsFilled(LogParameters.Data);
	
	TextForLog      = Text;
	TextForUser = Text;
	If TypeOf(IssueDetails) = Type("ErrorInfo") Then
		TextForLog      = TextForLog      + Chars.LF + DetailErrorDescription(IssueDetails);
		TextForUser = TextForUser + Chars.LF + BriefErrorDescription(IssueDetails);
	ElsIf TypeOf(IssueDetails) = Type("String") Then
		TextForLog      = TextForLog      + Chars.LF + IssueDetails;
		TextForUser = TextForUser + Chars.LF + IssueDetails;
	EndIf;
	TextForLog      = TrimAll(TextForLog);
	TextForUser = TrimAll(TextForUser);
	
	// The event log.
	If WriteToLog Then
		SetPrivilegedMode(True);
		WriteLogEvent(
			LogParameters.EventName, 
			LogLevel, 
			LogParameters.Metadata, 
			LogParameters.Data, 
			TextForLog);
		SetPrivilegedMode(False);
	EndIf;
	
	// Message to a user.
	ErrorLevel = LogLevel = EventLogLevel.Error;
	WarningLevel = Not ErrorLevel AND LogLevel = EventLogLevel.Warning;
	If ErrorLevel Or WarningLevel Then
		If ErrorLevel Then
			LogParameters.Insert("HadErrors", True);
		Else
			LogParameters.Insert("HasWarnings", True);
		EndIf;
		Message = New UserMessage;
		Message.Text = TextForUser;
		Message.SetData(LogParameters.Data);
		If LogParameters.Property("ErrorArray") Then
			LogParameters.ErrorArray.Add(Message);
		Else
			Message.Message();
		EndIf;
	EndIf;
	
EndProcedure

// Generates PermissionsArray according to report mailing data.
Function PermissionsToUseServerResources(BulkEmail) Export
	Permissions = New Array;
	
	ModuleSafeModeManager = Common.CommonModule("SafeModeManager");
	
	If BulkEmail.UseNetworkDirectory Then
		If ValueIsFilled(BulkEmail.NetworkDirectoryWindows) Then
			Item = ModuleSafeModeManager.PermissionToUseFileSystemDirectory(
				BulkEmail.NetworkDirectoryWindows,
				True,
				True,
				NStr("ru = 'Сетевой каталог для публикации отчетов с сервера Windows.'; en = 'Network directory for report publication from Windows server.'; pl = 'Network directory for report publication from Windows server.';de = 'Network directory for report publication from Windows server.';ro = 'Network directory for report publication from Windows server.';tr = 'Network directory for report publication from Windows server.'; es_ES = 'Network directory for report publication from Windows server.'"));
			Permissions.Add(Item);
		EndIf;
		If ValueIsFilled(BulkEmail.NetworkDirectoryLinux) Then
			Item = ModuleSafeModeManager.PermissionToUseFileSystemDirectory(
				BulkEmail.NetworkDirectoryLinux,
				True,
				True,
				NStr("ru = 'Сетевой каталог для публикации отчетов с сервера Linux.'; en = 'Network directory for report publication from Linux server.'; pl = 'Network directory for report publication from Linux server.';de = 'Network directory for report publication from Linux server.';ro = 'Network directory for report publication from Linux server.';tr = 'Network directory for report publication from Linux server.'; es_ES = 'Network directory for report publication from Linux server.'"));
			Permissions.Add(Item);
		EndIf;
	EndIf;
	If BulkEmail.UseFTPResource Then
		If ValueIsFilled(BulkEmail.FTPServer) Then
			Item = ModuleSafeModeManager.PermissionToUseInternetResource(
				"FTP",
				BulkEmail.FTPServer + BulkEmail.FTPDirectory,
				BulkEmail.FTPPort,
				NStr("ru = 'FTP ресурс для публикации отчетов.'; en = 'FTP resource for publishing reports.'; pl = 'FTP resource for publishing reports.';de = 'FTP resource for publishing reports.';ro = 'FTP resource for publishing reports.';tr = 'FTP resource for publishing reports.'; es_ES = 'FTP resource for publishing reports.'"));
			Permissions.Add(Item);
		EndIf;
	EndIf;
	Return Permissions;
EndFunction

Function EventLogParameters(BulkEmail) Export
	Query = New Query;
	Query.Text =
	"SELECT
	|	States.LastRunStart,
	|	States.LastRunCompletion,
	|	States.SessionNumber
	|FROM
	|	InformationRegister.ReportMailingStates AS States
	|WHERE
	|	States.BulkEmail = &BulkEmail";
	Query.SetParameter("BulkEmail", BulkEmail);
	
	SetPrivilegedMode(True);
	Selection = Query.Execute().Select();
	If Not Selection.Next() Then
		Return Undefined;
	EndIf;
	Result = New Structure;
	Result.Insert("StartDate", Selection.LastRunStart);
	Result.Insert("EndDate", Selection.LastRunCompletion);
	// Interval is not more than 30 minutes because sessions numbers can be reused.
	If Not ValueIsFilled(Result.EndDate) Or Result.EndDate < Result.StartDate Then
		Result.EndDate = Result.StartDate + 30 * 60; 
	EndIf;
	If Not ValueIsFilled(Selection.SessionNumber) Then
		Result.Insert("Data", BulkEmail);
	Else
		Sessions = New ValueList;
		Sessions.Add(Selection.SessionNumber);
		Result.Insert("Session", Sessions);
	EndIf;
	Return Result;
EndFunction

////////////////////////////////////////////////////////////////////////////////
// Local internal procedures and functions.

// In addition to generating reports, executes personalization on the list of recipients and 
//   generates reports broken down by recipients (if necessary).
//
// Parameters:
//   LogParameters - Structure - parameters of the writing to the event log.
//       * Prefix - String - prefix for the name of the event of the event log.
//       * Metadata - MetadataObject - metadata to write to the event log.
//       * Data - Arbitrary - metadata to write to the event log.
//   ReportParameters - Structure - see ExecuteMailing(), the ReportsTable parameter. 
//   ReportsTree - ValueTree - reports and result of formation.
//   DeliveryParameters - Structure - see ExecuteMailing(), the DeliveryParameters parameter. 
//   Recipient - CatalogRef - a recipient reference.
//
// Execution result is written in the ReportsTree.
// Errors are written to the log and messages of the user session.
//
Procedure GenerateAndSaveReport(LogParameters, ReportParameters, ReportsTree, DeliveryParameters, RecipientRef)
	
	// Determine the tree root string mapping to the recipient.
	// 1 - Recipients
	//   Key - a reference
	//   Value - a recipients directory.
	//   Settings - a generated reports presentation.
	RecipientRow = DefineTreeRowForRecipient(ReportsTree, RecipientRef, DeliveryParameters);
	RecipientsDirectory = RecipientRow.Value;
	
	// Generate a report for the recipient.
	Result = GenerateReport(LogParameters, ReportParameters, RecipientRef);
	
	// Check the result
	If Not Result.Generated Or (Result.IsEmpty AND Not ReportParameters.SendIfEmpty) Then
		Return;
	EndIf;
	
	// Register the intermediate result.
	// 2 - user spreadsheet documents.
	//   Key - a report name
	//   Value - a spreadsheet document.
	//   Settings - ............. all report parameters .............
	RowReport = RecipientRow.Rows.Add();
	RowReport.Level   = 2;
	RowReport.Key      = String(ReportParameters.Report);
	RowReport.Value  = Result.SpreadsheetDoc;
	RowReport.Settings = ReportParameters;
	
	ReportPresentation = TrimAll(RowReport.Key);// + ([FormatsPresentation]) ;
	
	// Save a spreadsheet document in formats.
	FormatsPresentation = "";
	For Each Format In ReportParameters.Formats Do
		
		FormatParameters = DeliveryParameters.FormatsParameters.Get(Format);
		
		If FormatParameters = Undefined Then
			Continue;
		EndIf;
		
		FullFileName = RecipientsDirectory + FileName(
			RowReport.Key + " (" + FormatParameters.Name + ")"
			+ ?(FormatParameters.Extension = Undefined, "", FormatParameters.Extension), DeliveryParameters.TransliterateFileNames);
		
		FindFreeFileName(FullFileName);
		
		StandardProcessing = True;
		
		//  Extension mechanism
		ReportMailingOverridable.BeforeSaveSpreadsheetDocumentToFormat(
			StandardProcessing,
			RowReport.Value,
			Format,
			FullFileName);
		
		// Save a report by the built-in subsystem tools.
		If StandardProcessing = True Then
			ErrorTitle = NStr("ru = 'Ошибка записи отчета %1 в формат %2:'; en = 'An error occurred when writing report %1 to format %2:'; pl = 'An error occurred when writing report %1 to format %2:';de = 'An error occurred when writing report %1 to format %2:';ro = 'An error occurred when writing report %1 to format %2:';tr = 'An error occurred when writing report %1 to format %2:'; es_ES = 'An error occurred when writing report %1 to format %2:'");
			
			If FormatParameters.FileType = Undefined Then
				LogRecord(LogParameters, EventLogLevel.Error,
					StringFunctionsClientServer.SubstituteParametersToString(ErrorTitle, "'"+ RowReport.Key +"'", "'"+ FormatParameters.Name +"'"),
					NStr("ru = 'Формат не поддерживается'; en = 'Format is not supported'; pl = 'Format is not supported';de = 'Format is not supported';ro = 'Format is not supported';tr = 'Format is not supported'; es_ES = 'Format is not supported'"));
				Continue;
			EndIf;
			
			Try
				RowReport.Value.Write(FullFileName, FormatParameters.FileType);
			Except
				LogRecord(LogParameters, EventLogLevel.Error,
					StringFunctionsClientServer.SubstituteParametersToString(ErrorTitle, "'"+ RowReport.Key +"'", "'"+ FormatParameters.Name +"'"),
					ErrorInfo());
				Continue;
			EndTry;
		EndIf;
		
		// Checks and result registration.
		TempFile = New File(FullFileName);
		If Not TempFile.Exist() Then
			LogRecord(LogParameters, EventLogLevel.Error,
				StringFunctionsClientServer.SubstituteParametersToString(ErrorTitle + Chars.LF + NStr("ru = 'Файл %3 не найден.'; en = 'File %3 is not found.'; pl = 'File %3 is not found.';de = 'File %3 is not found.';ro = 'File %3 is not found.';tr = 'File %3 is not found.'; es_ES = 'File %3 is not found.'"),
				"'"+ RowReport.Key +"'",
				"'"+ FormatParameters.Name +"'",
				"'"+ TempFile.FullName +"'"));
			Continue;
		EndIf;
		
		// Register the final result - the saved report in a temporary directory.
		// 3 - Recipients files
		//   Key - a file name
		//   Value - full path to the file.
		//   Settings - file settings.
		FileRow = RowReport.Rows.Add();
		FileRow.Level = 3;
		FileRow.Key      = TempFile.Name;
		FileRow.Value  = TempFile.FullName;
		
		FileRow.Settings = New Structure("FileWithDirectory, FileName, FullFileName, DirectoryName, FullDirectoryName, 
			|Format, Name, Extension, FileType, Ref");
		
		FileRow.Settings.Format = Format;
		FillPropertyValues(FileRow.Settings, FormatParameters, "Name, Extension, FileType");
		
		FileRow.Settings.FileName          = TempFile.Name;
		FileRow.Settings.FullFileName    = TempFile.FullName;
		FileRow.Settings.DirectoryName       = TempFile.BaseName + "_files";
		FileRow.Settings.FullDirectoryName = TempFile.Path + FileRow.Settings.DirectoryName + "\";
		
		FileDirectory = New File(FileRow.Settings.FullDirectoryName);
		
		FileRow.Settings.FileWithDirectory = (FileDirectory.Exist() AND FileDirectory.IsDirectory());
		
		If FileRow.Settings.FileWithDirectory AND Not DeliveryParameters.AddToArchive Then
			// Directory and the file are archived and an archive is sent instead of the file.
			ArchiveName       = TempFile.BaseName + ".zip";
			FullArchiveName = RecipientsDirectory + ArchiveName;
			
			SaveMode = ZIPStorePathMode.StoreRelativePath;
			ProcessingMode  = ZIPSubDirProcessingMode.ProcessRecursively;
			
			ZipFileWriter = New ZipFileWriter(FullArchiveName);
			ZipFileWriter.Add(FileRow.Settings.FullFileName,    SaveMode, ProcessingMode);
			ZipFileWriter.Add(FileRow.Settings.FullDirectoryName, SaveMode, ProcessingMode);
			ZipFileWriter.Write();
			
			FileRow.Key     = ArchiveName;
			FileRow.Value = FullArchiveName;
		EndIf;
		
		FileDirectory = Undefined;
		TempFile = Undefined;
		
		FormatsPresentation = FormatsPresentation 
			+ ?(FormatsPresentation = "", "", ", ") 
			// An opening tag for links (full paths to the files will be replaced with the links to files in the final storage).
			+ ?(DeliveryParameters.AddReferences = "ToFormats", "<a href = '"+ FileRow.Value +"'>", "")
			// format name
			+ FormatParameters.Name
			// end tag for links
			+ ?(DeliveryParameters.AddReferences = "ToFormats", "</a>", "");
			
		//
		If DeliveryParameters.AddReferences = "AfterReports" Then
			ReportPresentation = ReportPresentation + Chars.LF + "<" + FileRow.Value + ">";
		EndIf;
		
	EndDo;
	
	// Presentation of a specific report.
	ReportPresentation = StrReplace(ReportPresentation, "[FormatsPresentation]", FormatsPresentation);
	RowReport.Settings.Insert("PresentationInEmail", ReportPresentation);
	
EndProcedure

// Auxiliary procedure of the ExecuteMailing function fills default values for parameters that were 
//   not passed explicitly.
//   Also prepares and fills parameters required for mailing.
//
// Parameters and return value:
//   See ExecuteMailing(). 
//
Function CheckAndFillExecutionParameters(ValueTable, DeliveryParameters, MailingDescription, LogParameters)
	// Parameters of the writing to the event log.
	If TypeOf(LogParameters) <> Type("Structure") Then
		LogParameters = New Structure;
	EndIf;
	If Not LogParameters.Property("EventName") Then
		LogParameters.Insert("EventName", NStr("ru = 'Рассылка отчетов. Запуск по требованию'; en = 'Report bulk email. Start on demand'; pl = 'Report bulk email. Start on demand';de = 'Report bulk email. Start on demand';ro = 'Report bulk email. Start on demand';tr = 'Report bulk email. Start on demand'; es_ES = 'Report bulk email. Start on demand'", Common.DefaultLanguageCode()));
	EndIf;
	If Not LogParameters.Property("Data") Then
		LogParameters.Insert("Data", MailingDescription);
	EndIf;
	If Not LogParameters.Property("Metadata") Then
		LogParameters.Insert("Metadata", Undefined);
		DataType = TypeOf(LogParameters.Data);
		If DataType <> Type("Structure") AND Common.IsReference(DataType) Then
			LogParameters.Metadata = LogParameters.Data.Metadata();
		EndIf;
	EndIf;
	
	// Check access rights.
	If Not OutputRight(LogParameters) Then
		Return False;
	EndIf;
	
	ReportsAvailability = ReportsOptions.ReportsAvailability(ValueTable.UnloadColumn("Report"));
	Unavailable = ReportsAvailability.Copy(New Structure("Available", False));
	If Unavailable.Count() > 0 Then
		LogRecord(LogParameters, EventLogLevel.Error,
			StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = 'В рассылке есть недоступные отчеты (%1):%2'; en = 'There are unavailable reports in bulk email(%1):%2'; pl = 'There are unavailable reports in bulk email(%1):%2';de = 'There are unavailable reports in bulk email(%1):%2';ro = 'There are unavailable reports in bulk email(%1):%2';tr = 'There are unavailable reports in bulk email(%1):%2'; es_ES = 'There are unavailable reports in bulk email(%1):%2'"),
			Unavailable.Count(),
			Chars.LF + Chars.Tab + StrConcat(Unavailable.UnloadColumn("Presentation"), Chars.LF + Chars.Tab)));
		Return False;
	EndIf;
	
	DeliveryParameters.Insert("BulkEmail", TrimAll(String(MailingDescription)));
	DeliveryParameters.Insert("ExecutionDate", CurrentSessionDate());
	DeliveryParameters.Insert("HadErrors",                   False);
	DeliveryParameters.Insert("HasWarnings",           False);
	DeliveryParameters.Insert("ExecutedToFolder",              False);
	DeliveryParameters.Insert("ExecutedToNetworkDirectory",     False);
	DeliveryParameters.Insert("ExecutedAtFTP",               False);
	DeliveryParameters.Insert("ExecutedByEmail",  False);
	DeliveryParameters.Insert("ExecutedPublicationMethods", "");
	
	If DeliveryParameters.UseDirectory Then
		If Not ValueIsFilled(DeliveryParameters.Folder) Then
			DeliveryParameters.UseDirectory = False;
			LogRecord(LogParameters, EventLogLevel.Warning,
				NStr("ru = 'Папка не заполнена, доставка в папку отключена'; en = 'The folder is not filled in. Delivery to the folder is disabled'; pl = 'The folder is not filled in. Delivery to the folder is disabled';de = 'The folder is not filled in. Delivery to the folder is disabled';ro = 'The folder is not filled in. Delivery to the folder is disabled';tr = 'The folder is not filled in. Delivery to the folder is disabled'; es_ES = 'The folder is not filled in. Delivery to the folder is disabled'"));
		Else
			If Common.SubsystemExists("StandardSubsystems.FilesOperations") Then
				ModuleFilesOperationsInternal = Common.CommonModule("FilesOperationsInternal");
				AccessRight = ModuleFilesOperationsInternal.RightToAddFilesToFolder(DeliveryParameters.Folder);
			Else
				AccessRight = True;
			EndIf;
			If Not AccessRight Then
				SetPrivilegedMode(True);
				FoldersPresentation = String(DeliveryParameters.Folder);
				SetPrivilegedMode(False);
				LogRecord(LogParameters, EventLogLevel.Error,
					StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = 'Недостаточно прав для создания файлов в папке ""%1"".'; en = 'You are not authorized to create files in the ""%1"" folder.'; pl = 'You are not authorized to create files in the ""%1"" folder.';de = 'You are not authorized to create files in the ""%1"" folder.';ro = 'You are not authorized to create files in the ""%1"" folder.';tr = 'You are not authorized to create files in the ""%1"" folder.'; es_ES = 'You are not authorized to create files in the ""%1"" folder.'"),
					FoldersPresentation));
				Return False;
			EndIf;
		EndIf;
	EndIf;
	
	If DeliveryParameters.UseNetworkDirectory Then
		If Not ValueIsFilled(DeliveryParameters.NetworkDirectoryWindows) 
			Or Not ValueIsFilled(DeliveryParameters.NetworkDirectoryLinux) Then
			
			If ValueIsFilled(DeliveryParameters.NetworkDirectoryWindows) Then
				SubstitutionValue = NStr("ru = 'Linux'; en = 'Linux'; pl = 'Linux';de = 'Linux';ro = 'Linux';tr = 'Linux'; es_ES = 'Linux'");
			ElsIf ValueIsFilled(DeliveryParameters.NetworkDirectoryLinux) Then
				SubstitutionValue = NStr("ru = 'Windows'; en = 'Windows'; pl = 'Windows';de = 'Windows';ro = 'Windows';tr = 'Windows'; es_ES = 'Windows'");
			Else
				SubstitutionValue = NStr("ru = 'Windows и Linux'; en = 'Windows and Linux'; pl = 'Windows and Linux';de = 'Windows and Linux';ro = 'Windows and Linux';tr = 'Windows and Linux'; es_ES = 'Windows and Linux'");
			EndIf;
			
			DeliveryParameters.UseNetworkDirectory = False;
			LogRecord(LogParameters, EventLogLevel.Error,
				StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = 'Сетевой каталог %1 не выбран, доставка в сетевой каталог отключена'; en = 'Network directory %1 is not selected, delivery into network directory is disabled'; pl = 'Network directory %1 is not selected, delivery into network directory is disabled';de = 'Network directory %1 is not selected, delivery into network directory is disabled';ro = 'Network directory %1 is not selected, delivery into network directory is disabled';tr = 'Network directory %1 is not selected, delivery into network directory is disabled'; es_ES = 'Network directory %1 is not selected, delivery into network directory is disabled'"),
				SubstitutionValue));
			
		Else
			
			DeliveryParameters.NetworkDirectoryWindows = CommonClientServer.AddLastPathSeparator(
				DeliveryParameters.NetworkDirectoryWindows);
			DeliveryParameters.NetworkDirectoryLinux = CommonClientServer.AddLastPathSeparator(
				DeliveryParameters.NetworkDirectoryLinux);
			
		EndIf;
	EndIf;
	
	If DeliveryParameters.UseFTPResource AND Not ValueIsFilled(DeliveryParameters.Server) Then
		DeliveryParameters.UseFTPResource = False;
		LogRecord(LogParameters, EventLogLevel.Error,
			NStr("ru = 'FTP сервер не заполнен, доставка в папку на FTP ресурс отключена'; en = 'FTP server is not filled in, delivery to folder on FTP resource is disabled'; pl = 'FTP server is not filled in, delivery to folder on FTP resource is disabled';de = 'FTP server is not filled in, delivery to folder on FTP resource is disabled';ro = 'FTP server is not filled in, delivery to folder on FTP resource is disabled';tr = 'FTP server is not filled in, delivery to folder on FTP resource is disabled'; es_ES = 'FTP server is not filled in, delivery to folder on FTP resource is disabled'"));
	EndIf;
	
	If DeliveryParameters.UseEmail AND Not ValueIsFilled(DeliveryParameters.Account) Then
		DeliveryParameters.UseEmail = False;
		LogRecord(LogParameters, EventLogLevel.Error,
			NStr("ru = 'Учетная запись не выбрана, доставка по электронной почте отключена'; en = 'No account is selected, email delivery is disabled'; pl = 'No account is selected, email delivery is disabled';de = 'No account is selected, email delivery is disabled';ro = 'No account is selected, email delivery is disabled';tr = 'No account is selected, email delivery is disabled'; es_ES = 'No account is selected, email delivery is disabled'"));
	EndIf;
	
	If Not DeliveryParameters.Property("Personalized") Then
		DeliveryParameters.Insert("Personalized", False);
	EndIf;
	
	If DeliveryParameters.Personalized Then
		If Not DeliveryParameters.UseEmail Then
			LogRecord(LogParameters, EventLogLevel.Error,
				NStr("ru = 'Персонализированная рассылка может быть отправлена только по электронной почте'; en = 'Personalized bulk email can be sent only by email'; pl = 'Personalized bulk email can be sent only by email';de = 'Personalized bulk email can be sent only by email';ro = 'Personalized bulk email can be sent only by email';tr = 'Personalized bulk email can be sent only by email'; es_ES = 'Personalized bulk email can be sent only by email'"));
			Return False;
		EndIf;
		
		DeliveryParameters.UseDirectory          = False;
		DeliveryParameters.UseNetworkDirectory = False;
		DeliveryParameters.UseFTPResource      = False;
		DeliveryParameters.Insert("NotifyOnly", False);
	EndIf;
	
	If DeliveryParameters.UseEmail Then
		// Connection to a mail server rises the longest.
		If Not DeliveryParameters.Property("Connection") Then
			DeliveryParameters.Insert("Connection", Undefined);
		EndIf;
		
		//  Email delivery notification.
		If Not DeliveryParameters.Property("NotifyOnly") Then
			DeliveryParameters.Insert("NotifyOnly", False);
		EndIf;
		
		If DeliveryParameters.NotifyOnly
			AND Not DeliveryParameters.UseDirectory
			AND Not DeliveryParameters.UseNetworkDirectory
			AND Not DeliveryParameters.UseFTPResource Then
			LogRecord(LogParameters, EventLogLevel.Warning,
				NStr("ru = 'Использование уведомлений по электронной почте возможно только совместно с другими способами доставки'; en = 'Use of email notifications is available only with other delivery methods'; pl = 'Use of email notifications is available only with other delivery methods';de = 'Use of email notifications is available only with other delivery methods';ro = 'Use of email notifications is available only with other delivery methods';tr = 'Use of email notifications is available only with other delivery methods'; es_ES = 'Use of email notifications is available only with other delivery methods'"));
			Return False;
		EndIf;
		
		// Email parameters.
		If Not DeliveryParameters.Property("BCC") Then
			DeliveryParameters.Insert("BCC", False);
		EndIf;
		If Not DeliveryParameters.Property("EmailParameters") Then
			DeliveryParameters.Insert("EmailParameters", New Structure);
		EndIf;
		
		EmailParameters = DeliveryParameters.EmailParameters;
		
		EmailParameters.Insert("ProcessTexts", False);
		
		// Internet mail text type.
		If Not EmailParameters.Property("TextType") Or Not ValueIsFilled(EmailParameters.TextType) Then
			EmailParameters.Insert("TextType", InternetMailTextType.PlainText);
		EndIf;
		
		DeliveryParameters.Insert("HTMLFormatEmail", EmailParameters.TextType = "HTML" Or EmailParameters.TextType = InternetMailTextType.HTML);
		
		// For backward compatibility.
		If EmailParameters.Property("Attachments") Then
			EmailParameters.Insert("Pictures", EmailParameters.Attachments);
		EndIf;
		
		// Subjects template
		If Not DeliveryParameters.Property("SubjectTemplate") Or Not ValueIsFilled(DeliveryParameters.SubjectTemplate) Then
			DeliveryParameters.Insert("SubjectTemplate", SubjectTemplate());
		EndIf;
		
		// Message template
		If Not DeliveryParameters.Property("TextTemplate") Or Not ValueIsFilled(DeliveryParameters.TextTemplate) Then
			DeliveryParameters.Insert("TextTemplate", TextTemplate());
			If DeliveryParameters.HTMLFormatEmail Then
				Document = New FormattedDocument;
				Document.Add(DeliveryParameters.TextTemplate, FormattedDocumentItemType.Text);
				Document.GetHTML(DeliveryParameters.TextTemplate, New Structure);
			EndIf;
		EndIf;
		
		// Delete unnecessary style elements.
		If DeliveryParameters.HTMLFormatEmail Then
			StyleLeft = StrFind(DeliveryParameters.TextTemplate, "<style");
			StyleRight = StrFind(DeliveryParameters.TextTemplate, "</style>");
			If StyleLeft > 0 AND StyleRight > StyleLeft Then
				DeliveryParameters.TextTemplate = Left(DeliveryParameters.TextTemplate, StyleLeft - 1) + Mid(DeliveryParameters.TextTemplate, StyleRight + 8);
			EndIf;
		EndIf;
		
		// Value content for the substitution.
		TemplateFillingStructure = New Structure("BulkEmailDescription, Author, SystemTitle, ExecutionDate");
		TemplateFillingStructure.BulkEmailDescription = DeliveryParameters.BulkEmail;
		TemplateFillingStructure.Author                = DeliveryParameters.Author;
		TemplateFillingStructure.SystemTitle     = ThisInfobaseName();
		TemplateFillingStructure.ExecutionDate       = DeliveryParameters.ExecutionDate;
		If Not DeliveryParameters.Personalized Then
			TemplateFillingStructure.Insert("Recipient", "");
		EndIf;
		
		// Subjects template
		DeliveryParameters.SubjectTemplate = ReportsDistributionClientServer.FillTemplate(
			DeliveryParameters.SubjectTemplate, 
			TemplateFillingStructure);
		
		// Message template
		DeliveryParameters.TextTemplate = ReportsDistributionClientServer.FillTemplate(
			DeliveryParameters.TextTemplate,
			TemplateFillingStructure);
		
		// Flags that show whether it is necessary to fill in the templates (checks cache).
		DeliveryParameters.Insert(
			"FillRecipientInSubjectTemplate",
			StrFind(DeliveryParameters.SubjectTemplate, "[Recipient]") <> 0);
		DeliveryParameters.Insert(
			"FillRecipientInMessageTemplate",
			StrFind(DeliveryParameters.TextTemplate, "[Recipient]") <> 0);
		DeliveryParameters.Insert(
			"FillGeneratedReportsInMessageTemplate",
			StrFind(DeliveryParameters.TextTemplate, "[GeneratedReports]") <> 0);
		DeliveryParameters.Insert(
			"FillTransportMethodInMessageTemplate",
			StrFind(DeliveryParameters.TextTemplate, "[DeliveryMethod]") <> 0);
		
		// Reports presentation.
		DeliveryParameters.Insert("RecipientReportsPresentation", "");
	EndIf;
	
	// Temporary file directory.
	DeliveryParameters.Insert("TempFilesDirectory", FileSystem.CreateTemporaryDirectory("RP"));
	
	// Recipients temporary files directory mapping.
	DeliveryParameters.Insert("RecipientsSettings", New Map);
	
	// Archive settings: checkbox and password.
	If Not DeliveryParameters.Property("AddToArchive") Then
		DeliveryParameters.Insert("AddToArchive", False);
		DeliveryParameters.Insert("ArchivePassword", "");
	ElsIf Not DeliveryParameters.Property("ArchivePassword") Then
		DeliveryParameters.Insert("ArchivePassword", "");
	EndIf;
	
	// Archive name (delete forbidden characters, fill a template) and extension.
	If DeliveryParameters.AddToArchive Then
		If Not DeliveryParameters.Property("ArchiveName") Or Not ValueIsFilled(DeliveryParameters.ArchiveName) Then
			DeliveryParameters.Insert("ArchiveName", ArchivePatternName());
		EndIf;
		Structure = New Structure("BulkEmailDescription, ExecutionDate", DeliveryParameters.BulkEmail, CurrentSessionDate());
		ArchiveName = ReportsDistributionClientServer.FillTemplate(DeliveryParameters.ArchiveName, Structure);
		DeliveryParameters.ArchiveName = FileName(ArchiveName, DeliveryParameters.TransliterateFileNames);
		If Lower(Right(DeliveryParameters.ArchiveName, 4)) <> ".zip" Then
			DeliveryParameters.ArchiveName = DeliveryParameters.ArchiveName +".zip";
		EndIf;
	EndIf;
	
	// Formats parameters.
	DeliveryParameters.Insert("FormatsParameters", New Map);
	For Each MetadataFormat In Metadata.Enums.ReportSaveFormats.EnumValues Do
		Format = Enums.ReportSaveFormats[MetadataFormat.Name];
		FormatParameters = WriteSpreadsheetDocumentToFormatParameters(Format);
		FormatParameters.Insert("Name", MetadataFormat.Name);
		DeliveryParameters.FormatsParameters.Insert(Format, FormatParameters);
	EndDo;
	
	// File name transliteration parameters.
	If Not DeliveryParameters.Property("TransliterateFileNames") Then
		DeliveryParameters.Insert("TransliterateFileNames", False);
	EndIf;
	
	// Parameters for adding links to the final files to the message.
	DeliveryParameters.Insert("AddReferences", "");
	If DeliveryParameters.UseEmail 
		AND (DeliveryParameters.UseDirectory
			Or DeliveryParameters.UseNetworkDirectory
			Or DeliveryParameters.UseFTPResource)
		AND DeliveryParameters.FillGeneratedReportsInMessageTemplate Then
		
		If DeliveryParameters.AddToArchive Then
			DeliveryParameters.AddReferences = "ToArchive";
		ElsIf DeliveryParameters.HTMLFormatEmail Then
			DeliveryParameters.AddReferences = "ToFormats";
		Else
			DeliveryParameters.AddReferences = "AfterReports";
		EndIf;
	EndIf;
	
	Return True;
EndFunction

// Returns the default subject template for delivery by email.
Function SubjectTemplate() Export
	Return NStr("ru = '[BulkEmailDescription] от [ДатаВыполнения(ДЛФ=''D'')]'; en = '[BulkEmailDescription] from [ExecutionDate(DLF=''D'')]'; pl = '[BulkEmailDescription] from [ExecutionDate(DLF=''D'')]';de = '[BulkEmailDescription] from [ExecutionDate(DLF=''D'')]';ro = '[BulkEmailDescription] from [ExecutionDate(DLF=''D'')]';tr = '[BulkEmailDescription] from [ExecutionDate(DLF=''D'')]'; es_ES = '[BulkEmailDescription] from [ExecutionDate(DLF=''D'')]'");
EndFunction

// Returns the default body template for delivery by email.
Function TextTemplate() Export
	Return NStr(
		"ru = 'Сформированы отчеты:
		|
		|[GeneratedReports]
		|
		|[DeliveryMethod]
		|
		|[SystemTitle]
		|[ДатаВыполнения(ДЛФ=''DD'')]'; 
		|en = 'The following reports were generated:
		|
		|[GeneratedReports]
		|
		|[DeliveryMethod]
		|
		|[SystemTitle]
		|[ExecutionDate(DLF=''DD'')]'; 
		|pl = 'The following reports were generated:
		|
		|[GeneratedReports]
		|
		|[DeliveryMethod]
		|
		|[SystemTitle]
		|[ExecutionDate(DLF=''DD'')]';
		|de = 'The following reports were generated:
		|
		|[GeneratedReports]
		|
		|[DeliveryMethod]
		|
		|[SystemTitle]
		|[ExecutionDate(DLF=''DD'')]';
		|ro = 'The following reports were generated:
		|
		|[GeneratedReports]
		|
		|[DeliveryMethod]
		|
		|[SystemTitle]
		|[ExecutionDate(DLF=''DD'')]';
		|tr = 'The following reports were generated:
		|
		|[GeneratedReports]
		|
		|[DeliveryMethod]
		|
		|[SystemTitle]
		|[ExecutionDate(DLF=''DD'')]'; 
		|es_ES = 'The following reports were generated:
		|
		|[GeneratedReports]
		|
		|[DeliveryMethod]
		|
		|[SystemTitle]
		|[ExecutionDate(DLF=''DD'')]'");
EndFunction

// Returns the default archive description template.
Function ArchivePatternName() Export
	// For date format localization is not required.
	Return NStr("ru = '[BulkEmailDescription]_[ДатаВыполнения(ДФ=''yyyy-MM-dd'')]'; en = '[BulkEmailDescription]_[ExecutionDate(DF=''MM/dd/yyyy'')]'; pl = '[BulkEmailDescription]_[ExecutionDate(DF=''MM/dd/yyyy'')]';de = '[BulkEmailDescription]_[ExecutionDate(DF=''MM/dd/yyyy'')]';ro = '[BulkEmailDescription]_[ExecutionDate(DF=''MM/dd/yyyy'')]';tr = '[BulkEmailDescription]_[ExecutionDate(DF=''MM/dd/yyyy'')]'; es_ES = '[BulkEmailDescription]_[ExecutionDate(DF=''MM/dd/yyyy'')]'");
EndFunction

// Generates the mailing list from the recipients list, prepares all email parameters and passes 
//   control to the EmailOperations subsystem.
//   To monitor the fulfillment, it is recommended to call in construction the Attempt... Exception.
//
// Parameters:
//   Attachments - Map - see SaveReportsToFormats(), the Result parameter. 
//   DeliveryParameters - Structure - see ExecuteMailing(), the DeliveryParameters parameter. 
//   RowRecipient - recipient settings:
//       - Undefined - whole recipients list from the DeliveryParameters.Recipients is used.
//       - ValueTreeRow - the Recipient row property is used.
//
Procedure SendReportsToRecipient(Attachments, DeliveryParameters, RecipientRow = Undefined)
	Recipient = ?(RecipientRow = Undefined, Undefined, RecipientRow.Key);
	EmailParameters = DeliveryParameters.EmailParameters;
	
	// Attachments - reports
	EmailParameters.Insert("Attachments", ConvertToMap(Attachments, "Key", "Value"));
	
	// Subject and body templates
	SubjectTemplate = DeliveryParameters.SubjectTemplate;
	TextTemplate = DeliveryParameters.TextTemplate;
	
	// Insert generated reports into the message template.
	If DeliveryParameters.FillGeneratedReportsInMessageTemplate Then
		If DeliveryParameters.HTMLFormatEmail Then
			DeliveryParameters.RecipientReportsPresentation = StrReplace(
				DeliveryParameters.RecipientReportsPresentation,
				Chars.LF,
				Chars.LF + "<br>");
		EndIf;
		TextTemplate = StrReplace(TextTemplate, "[GeneratedReports]", DeliveryParameters.RecipientReportsPresentation);
	EndIf;
	
	// Delivery method is filled earlier (outside this procedure).
	If DeliveryParameters.FillTransportMethodInMessageTemplate Then
		TextTemplate = StrReplace(TextTemplate, "[DeliveryMethod]", ReportsDistributionClientServer.DeliveryMethodsPresentation(DeliveryParameters));
	EndIf;
	
	// Subject and body of the message
	EmailParameters.Insert("Subject", SubjectTemplate);
	EmailParameters.Insert("Body", TextTemplate);
	
	// Subject and body of the message
	DeliveryAddressKey = ?(DeliveryParameters.BCC, "BCC", "SendTo");
	
	If Recipient = Undefined Then
		If DeliveryParameters.Recipients.Count() = 0 Then
			Return;
		EndIf;
		
		// Deliver to all recipients
		If DeliveryParameters.FillRecipientInSubjectTemplate Or DeliveryParameters.FillRecipientInMessageTemplate Then
			// Templates are personalized - delivery to each recipient.
			For Each KeyAndValue In DeliveryParameters.Recipients Do
				// Subject and body of the message
				If DeliveryParameters.FillRecipientInSubjectTemplate Then
					EmailParameters.Subject = StrReplace(SubjectTemplate, "[Recipient]", String(KeyAndValue.Key));
				EndIf;
				If DeliveryParameters.FillRecipientInMessageTemplate Then
					EmailParameters.Body = StrReplace(TextTemplate, "[Recipient]", String(KeyAndValue.Key));
				EndIf;
				
				// Recipient
				EmailParameters.Insert(DeliveryAddressKey, KeyAndValue.Value);
				
				// Sending email
				SendEmailMessage(DeliveryParameters, EmailParameters);
			EndDo;
		Else
			// Templates are not personalized - glue recipients email addresses and joint delivery.
			SendTo = "";
			For Each KeyAndValue In DeliveryParameters.Recipients Do
				SendTo = SendTo + ?(SendTo = "", "", ", ") + KeyAndValue.Value;
			EndDo;
			
			EmailParameters.Insert(DeliveryAddressKey, SendTo);
			
			// Sending email
			SendEmailMessage(DeliveryParameters, EmailParameters);
		EndIf;
	Else
		// Deliver to a specific recipient.
		
		// Subject and body of the message
		If DeliveryParameters.FillRecipientInSubjectTemplate Then
			EmailParameters.Subject = StrReplace(SubjectTemplate, "[Recipient]", String(Recipient));
		EndIf;
		If DeliveryParameters.FillRecipientInMessageTemplate Then
			EmailParameters.Body = StrReplace(TextTemplate, "[Recipient]", String(Recipient));
		EndIf;
		
		// Recipient
		EmailParameters.Insert(DeliveryAddressKey, DeliveryParameters.Recipients[Recipient]);
		
		// Sending email
		SendEmailMessage(DeliveryParameters, EmailParameters);
	EndIf;
	
EndProcedure

Procedure SendEmailMessage(DeliveryParameters, EmailParameters)
	If EmailParameters.Property("Pictures")
		 AND EmailParameters.Pictures <> Undefined
		 AND EmailParameters.Pictures.Count() > 0 Then
		FormattedDocument = New FormattedDocument;
		FormattedDocument.SetHTML(EmailParameters.Body, EmailParameters.Pictures);
		EmailParameters.Body = FormattedDocument;
	EndIf;
	
	EmailOperations.SendEmailMessage(
		DeliveryParameters.Account, EmailParameters, DeliveryParameters.Connection);
EndProcedure

// Converts the collection to mapping.
Function ConvertToMap(Collection, KeyName, ValueName)
	If TypeOf(Collection) = Type("Map") Then
		Return New Map(New FixedMap(Collection));
	EndIf;
	Result = New Map;
	For Each Item In Collection Do
		Result.Insert(Item[KeyName], Item[ValueName]);
	EndDo;
	Return Result;
EndFunction

// Combines arrays and returns the result of the union.
Function CombineArrays(Array1, Array2)
	Array = New Array;
	For Each ArrayElement In Array1 Do
		Array.Add(ArrayElement);
	EndDo;
	For Each ArrayElement In Array2 Do
		Array.Add(ArrayElement);
	EndDo;
	Return Array;
EndFunction

// Executes archiving of attachments in accordance with the delivery parameters.
//
// Parameters:
//   Attachments - Map, ValueTreeRow - see CreateReportsTree(), return value, level 3. 
//   DeliveryParameters - Structure - see ExecuteMailing(), the DeliveryParameters parameter. 
//   TempFilesDir - String - a directory for archiving.
//
Procedure ArchiveAttachments(Attachments, DeliveryParameters, TempFilesDirectory)
	If Not DeliveryParameters.AddToArchive Then
		Return;
	EndIf;
	
	// Directory and file are archived and the file name is changed to the archive name.
	FullFileName = TempFilesDirectory + DeliveryParameters.ArchiveName;
	
	SaveMode = ZIPStorePathMode.StoreRelativePath;
	ProcessingMode  = ZIPSubDirProcessingMode.ProcessRecursively;
	
	ZipFileWriter = New ZipFileWriter(FullFileName, DeliveryParameters.ArchivePassword);
	
	For Each Attachment In Attachments Do
		ZipFileWriter.Add(Attachment.Value, SaveMode, ProcessingMode);
		If Attachment.Settings.FileWithDirectory = True Then
			ZipFileWriter.Add(Attachment.Settings.FullDirectoryName, SaveMode, ProcessingMode);
		EndIf;
	EndDo;
	
	ZipFileWriter.Write();
	
	Attachments = New Map;
	Attachments.Insert(DeliveryParameters.ArchiveName, FullFileName);
	
	If DeliveryParameters.UseEmail Then
		If DeliveryParameters.FillGeneratedReportsInMessageTemplate Then
			DeliveryParameters.RecipientReportsPresentation = 
				DeliveryParameters.RecipientReportsPresentation 
				+ Chars.LF 
				+ Chars.LF
				+ NStr("ru = 'Файлы отчетов запакованы в архив'; en = 'Report files are archived'; pl = 'Report files are archived';de = 'Report files are archived';ro = 'Report files are archived';tr = 'Report files are archived'; es_ES = 'Report files are archived'")
				+ " ";
		EndIf;
		
		If DeliveryParameters.AddReferences = "ToArchive" Then
			// Delivery method involves links adding.
			If DeliveryParameters.HTMLFormatEmail Then
				DeliveryParameters.RecipientReportsPresentation = TrimAll(
					DeliveryParameters.RecipientReportsPresentation
					+"<a href = '"+ FullFileName +"'>"+ DeliveryParameters.ArchiveName +"</a>");
			Else
				DeliveryParameters.RecipientReportsPresentation = TrimAll(
					DeliveryParameters.RecipientReportsPresentation
					+""""+ DeliveryParameters.ArchiveName +""":"+ Chars.LF +"<"+ FullFileName +">");
			EndIf;
		ElsIf DeliveryParameters.FillGeneratedReportsInMessageTemplate Then
			// Delivery by mail only
			DeliveryParameters.RecipientReportsPresentation = TrimAll(
				DeliveryParameters.RecipientReportsPresentation
				+""""+ DeliveryParameters.ArchiveName +"""");
		EndIf;
		
	EndIf;
	
EndProcedure

// Parameters for saving a spreadsheet document in format.
//
// Parameters:
//   Format - EnumRef.ReportSaveFormats - a format for which you need to get the parameters.
//
// Returns:
//   Result - Structure - write parameters.
//       * Extension - String - extension with which you can save the file.
//       * FileType - SpreadsheetDocumentFileType - a spreadsheet document save format.
//           This procedure is used to define the SpreadsheetFileType parameter of the SpreadsheetDocument.Write method.
//
Function WriteSpreadsheetDocumentToFormatParameters(Format)
	Result = New Structure("Extension, FileType");
	If Format = Enums.ReportSaveFormats.XLSX Then
		Result.Extension = ".xlsx";
		Result.FileType = SpreadsheetDocumentFileType.XLSX;
		
	ElsIf Format = Enums.ReportSaveFormats.XLS Then
		Result.Extension = ".xls";
		Result.FileType = SpreadsheetDocumentFileType.XLS;
		
	ElsIf Format = Enums.ReportSaveFormats.ODS Then
		Result.Extension = ".ods";
		Result.FileType = SpreadsheetDocumentFileType.ODS;
		
	ElsIf Format = Enums.ReportSaveFormats.MXL Then
		Result.Extension = ".mxl";
		Result.FileType = SpreadsheetDocumentFileType.MXL;
		
	ElsIf Format = Enums.ReportSaveFormats.PDF Then
		Result.Extension = ".pdf";
		Result.FileType = SpreadsheetDocumentFileType.PDF;
		
	ElsIf Format = Enums.ReportSaveFormats.HTML Then
		Result.Extension = ".html";
		Result.FileType = SpreadsheetDocumentFileType.HTML;
		
	ElsIf Format = Enums.ReportSaveFormats.HTML4 Then
		Result.Extension = ".html";
		Result.FileType = SpreadsheetDocumentFileType.HTML4;
		
	ElsIf Format = Enums.ReportSaveFormats.DOCX Then
		Result.Extension = ".docx";
		Result.FileType = SpreadsheetDocumentFileType.DOCX;
		
	ElsIf Format = Enums.ReportSaveFormats.TXT Then
		Result.Extension = ".txt";
		Result.FileType = SpreadsheetDocumentFileType.TXT;
	
	ElsIf Format = Enums.ReportSaveFormats.ANSITXT Then
		Result.Extension = ".txt";
		Result.FileType = SpreadsheetDocumentFileType.ANSITXT;
		
	Else 
		// Pattern for all formats added during the deployment the saving handler of which has to be in the 
		// overridable module.
		Result.Extension = Undefined;
		Result.FileType = Undefined;
		
	EndIf;
	
	Return Result;
EndFunction

// Converts invalid file characters to similar valid characters.
//   Operates only with the file name, the path is not supported.
//
// Parameters:
//   InitialFileName - String - a file name from which you have to remove invalid characters.
//
// Returns:
//   Result - String - conversion result.
//
Function FileName(InitialFileName, TranslitFilesNames)
	
	Result = Left(TrimAll(InitialFileName), 255);
	
	ReplacementsMap = New Map;
	
	// Standard unsupported characters.
	ReplacementsMap.Insert("""", "'");
	ReplacementsMap.Insert("/", "_");
	ReplacementsMap.Insert("\", "_");
	ReplacementsMap.Insert(":", "_");
	ReplacementsMap.Insert(";", "_");
	ReplacementsMap.Insert("|", "_");
	ReplacementsMap.Insert("=", "_");
	ReplacementsMap.Insert("?", "_");
	ReplacementsMap.Insert("*", "_");
	ReplacementsMap.Insert("<", "_");
	ReplacementsMap.Insert(">", "_");
	
	// Characters not supported by the obsolete OS.
	ReplacementsMap.Insert("[", "");
	ReplacementsMap.Insert("]", "");
	ReplacementsMap.Insert(",", "");
	ReplacementsMap.Insert("{", "");
	ReplacementsMap.Insert("}", "");
	
	For Each KeyAndValue In ReplacementsMap Do
		Result = StrReplace(Result, KeyAndValue.Key, KeyAndValue.Value);
	EndDo;
	
	If TranslitFilesNames Then
		Result = StringFunctionsClientServer.LatinString(Result);
	EndIf;
	
	Return Result;
EndFunction

// Value tree required for generating and delivering reports.
Function CreateReportsTree()
	// Tree structure by nesting levels:
	//
	// 1 - Recipients:
	//   Key - a reference.
	//   Value - a recipients directory.
	//
	// 2 - Recipients spreadsheet documents:
	//   Key - a report name.
	//   Value - a spreadsheet document.
	//   Settings - all report parameters...
	//
	// 3 - Recipients files:
	//   Key - a file name.
	//   Value - full path to the file.
	//   Settings - FileWithDirectory, FileName, FullFileName, DirectoryName, FullDirectoryName, Format, Name, Extension, FileType.
	
	ReportsTree = New ValueTree;
	ReportsTree.Columns.Add("Level", New TypeDescription("Number"));
	ReportsTree.Columns.Add("Key");
	ReportsTree.Columns.Add("Value");
	ReportsTree.Columns.Add("Settings", New TypeDescription("Structure"));
	
	Return ReportsTree;
EndFunction

// Checks the current users right to output information. If there are no rights - an event log record is created.
Function OutputRight(LogParameters)
	OutputRight = AccessRight("Output", Metadata);
	If Not OutputRight Then
		LogRecord(LogParameters, EventLogLevel.Error,
			StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = 'У пользователя %1 недостаточно прав на вывод информации'; en = 'User %1 has insufficient rights to display information'; pl = 'User %1 has insufficient rights to display information';de = 'User %1 has insufficient rights to display information';ro = 'User %1 has insufficient rights to display information';tr = 'User %1 has insufficient rights to display information'; es_ES = 'User %1 has insufficient rights to display information'"),
			"'"+ String(Users.CurrentUser()) +"'"));
	EndIf;
	Return OutputRight;
EndFunction

// Converts an array of messages to a user in one string.
Function MessagesToUserString(ErrorArray = Undefined, AddCommonText = True) Export
	If ErrorArray = Undefined Then
		ErrorArray = GetUserMessages(True);
	EndIf;
	
	Indent = Chars.LF + Chars.LF;
	
	AllErrors = "";
	For Each Error In ErrorArray Do
		AllErrors = TrimAll(AllErrors + Indent + ?(TypeOf(Error) = Type("String"), Error, Error.Text));
	EndDo;
	If AllErrors <> "" AND AddCommonText Then
		AllErrors = AllErrors + Indent + "---" + Indent + NStr("ru = 'Подробности см. в журнале регистрации.'; en = 'See the event log for details.'; pl = 'See the event log for details.';de = 'See the event log for details.';ro = 'See the event log for details.';tr = 'See the event log for details.'; es_ES = 'See the event log for details.'");
	EndIf;
	
	Return AllErrors;
EndFunction

// If the file exists - adds a suffix to the file name.
//
// Parameters:
//   FullFileName - String - a file name to start a search.
//
Procedure FindFreeFileName(FullFileName)
	File = New File(FullFileName);
	
	If Not File.Exist() Then
		Return;
	EndIf;
	
	// Set a file names template to substitute various suffixes.
	NameTemplate = "";
	NameLength = StrLen(FullFileName);
	SlashCode = CharCode("/");
	BackSlashCode = CharCode("\");
	PointCode = CharCode(".");
	For ReverseIndex = 1 To NameLength Do
		Index = NameLength - ReverseIndex + 1;
		Code = CharCode(FullFileName, Index);
		If Code = PointCode Then
			NameTemplate = Left(FullFileName, Index - 1) + "<template>" + Mid(FullFileName, Index);
			Break;
		ElsIf Code = SlashCode Or Code = BackSlashCode Then
			Break;
		EndIf;
	EndDo;
	If NameTemplate = "" Then
		NameTemplate = FullFileName + "<template>";
	EndIf;
	
	Index = 0;
	While File.Exist() Do
		Index = Index + 1;
		FullFileName = StrReplace(NameTemplate, "<template>", " ("+ Format(Index, "NG=") +")");
		File = New File(FullFileName);
	EndDo;
EndProcedure

// Creates the tree root row for the recipient (if it is absent) and fills it with default parameters.
//
// Parameters:
//   ReportsTree - ValueTree - see CreateReportsTree(), return value, level 1. 
//   RecipientRef - CatalogRef, Undefined - a recipient reference.
//   DeliveryParameters - Structure - see ExecuteMailing(), the DeliveryParameters parameter. 
//
// Returns:
//   ValueTreeRow - see CreateReportsTree(), return value, level 1. 
//
Function DefineTreeRowForRecipient(ReportsTree, RecipientRef, DeliveryParameters)
	
	RecipientRow = ReportsTree.Rows.Find(RecipientRef, "Key", False);
	If RecipientRow = Undefined Then
		
		RecipientsDirectory = DeliveryParameters.TempFilesDirectory;
		If RecipientRef <> Undefined Then
			RecipientsDirectory = RecipientsDirectory 
				+ FileName(String(RecipientRef), DeliveryParameters.TransliterateFileNames)
				+ " (" + String(RecipientRef.UUID()) + ")\";
			CreateDirectory(RecipientsDirectory);
		EndIf;
		
		RecipientRow = ReportsTree.Rows.Add();
		RecipientRow.Level  = 1;
		RecipientRow.Key     = RecipientRef;
		RecipientRow.Value = RecipientsDirectory;
		
	EndIf;
	
	Return RecipientRow;
	
EndFunction

// Generates reports presentation for recipients.
Procedure GenerateReportPresentationsForRecipient(DeliveryParameters, RecipientRow)
	
	GeneratedReports = "";
	
	If DeliveryParameters.UseEmail AND DeliveryParameters.FillGeneratedReportsInMessageTemplate Then
		
		Separator = Chars.LF;
		If DeliveryParameters.AddReferences = "AfterReports" Then
			Separator = Separator + Chars.LF;
		EndIf;
		
		Index = 0;
		
		For Each RowReport In DeliveryParameters.GeneralReportsRow.Rows Do
			Index = Index + 1;
			GeneratedReports = GeneratedReports 
			+ Separator 
			+ Format(Index, "NG=") 
			+ ". " 
			+ RowReport.Settings.PresentationInEmail;
		EndDo;
		
		If RecipientRow <> Undefined AND RecipientRow <> DeliveryParameters.GeneralReportsRow Then
			For Each RowReport In RecipientRow.Rows Do
				Index = Index + 1;
				GeneratedReports = GeneratedReports 
				+ Separator 
				+ Format(Index, "NG=") 
				+ ". " 
				+ RowReport.Settings.PresentationInEmail;
			EndDo;
		EndIf;
		
	EndIf;
	
	DeliveryParameters.Insert("RecipientReportsPresentation", TrimAll(GeneratedReports));
	
EndProcedure

// Checks if there are external data sets.
//
// Parameters:
//   DataSets - DataCompositionTemplateDataSets - a collection of data sets to be checked.
//
// Returns:
//   Boolean - True if there are external data sets.
//
Function ThereIsExternalDataSet(DataSets)
	
	For Each DataSet In DataSets Do
		
		If TypeOf(DataSet) = Type("DataCompositionTemplateDataSetObject") Then
			
			Return True;
			
		ElsIf TypeOf(DataSet) = Type("DataCompositionTemplateDataSetUnion") Then
			
			If ThereIsExternalDataSet(DataSet.Items) Then
				
				Return True;
				
			EndIf;
			
		EndIf;
		
	EndDo;
	
	Return False;
	
EndFunction

Function MailingsWithReportsNumber(ReportOption)
	
	If Not ValueIsFilled(ReportOption) Or TypeOf(ReportOption) <> Type("CatalogRef.ReportsOptions") 
		Or ReportOption.IsEmpty() Then
		Return 0;
	EndIf;
	
	Query = New Query(
		"SELECT ALLOWED
		|	COUNT(DISTINCT Reports.Ref) AS Count
		|FROM
		|	Catalog.ReportMailings.Reports AS Reports
		|WHERE
		|	Reports.Report = &ReportOption");
		
	Query.SetParameter("ReportOption", ReportOption);
	Return Query.Execute().Unload()[0].Count;
	
EndFunction	

// Checks rights and generates error text.
Function CheckAddRightErrorText() Export
	If Not AccessRight("Output", Metadata) Then
		Return NStr("ru = 'Нет прав на вывод информации.'; en = 'You have no rights to display information.'; pl = 'You have no rights to display information.';de = 'You have no rights to display information.';ro = 'You have no rights to display information.';tr = 'You have no rights to display information.'; es_ES = 'You have no rights to display information.'");
	EndIf;
	If Not AccessRight("Update", Metadata.Catalogs.ReportMailings) Then
		Return NStr("ru = 'Нет прав на рассылки отчетов.'; en = 'You have no rights to mail reports.'; pl = 'You have no rights to mail reports.';de = 'You have no rights to mail reports.';ro = 'You have no rights to mail reports.';tr = 'You have no rights to mail reports.'; es_ES = 'You have no rights to mail reports.'");
	EndIf;
	If Not EmailOperations.CanSendEmails() Then
		Return NStr("ru = 'Нет прав на отправку писем или нет доступных учетных записей.'; en = 'You have no rights to send emails or there are no available accounts.'; pl = 'You have no rights to send emails or there are no available accounts.';de = 'You have no rights to send emails or there are no available accounts.';ro = 'You have no rights to send emails or there are no available accounts.';tr = 'You have no rights to send emails or there are no available accounts.'; es_ES = 'You have no rights to send emails or there are no available accounts.'");
	EndIf;
	Return "";
EndFunction

// Returns a value list of the ReportSaveFormats enumeration.
//
// Returns:
//   FormatsList - ValueList - a list of formats with marks on the system default formats.
//       * Value - EnumRef.ReportSaveFormats - a reference to the described format.
//       * Presentation - String - user presentation of the described format.
//       * CheckMark - Boolean - a flag of usage as a default format.
//       * Picture      - Picture - a picture of the format.
//
Function FormatsList() Export
	FormatsList = New ValueList;
	
	SetFormatsParameters(FormatsList, "HTML4", PictureLib.HTMLFormat, True);
	SetFormatsParameters(FormatsList, "PDF"  , PictureLib.PDFFormat);
	SetFormatsParameters(FormatsList, "XLSX" , PictureLib.Excel2007Format);
	SetFormatsParameters(FormatsList, "XLS"  , PictureLib.ExcelFormat);
	SetFormatsParameters(FormatsList, "ODS"  , PictureLib.OpenOfficeCalcFormat);
	SetFormatsParameters(FormatsList, "MXL"  , PictureLib.MXLFormat);
	SetFormatsParameters(FormatsList, "DOCX" , PictureLib.Word2007Format);
	SetFormatsParameters(FormatsList, "TXT"    , PictureLib.TXTFormat);
	SetFormatsParameters(FormatsList, "ANSITXT", PictureLib.TXTFormat);
	
	ReportMailingOverridable.OverrideFormatsParameters(FormatsList);
	
	// Remaining formats
	Query = New Query;
	Query.Text = 
	"SELECT
	|	Formats.Ref
	|FROM
	|	Enum.ReportSaveFormats AS Formats
	|WHERE
	|	(NOT Formats.Ref IN (&FormatArray))";
	Query.SetParameter("FormatArray", FormatsList.UnloadValues());
	Selection = Query.Execute().Select();
	While Selection.Next() Do
		SetFormatsParameters(FormatsList, Selection.Ref);
	EndDo;
	
	Return FormatsList;
EndFunction

// Gets an empty value for the search in the Reports or ReportFormats table of the ReportsMailing catalog.
Function EmptyReportValue() Export
	SetPrivilegedMode(True);
	Return Metadata.Catalogs.ReportMailings.TabularSections.ReportFormats.Attributes.Report.Type.AdjustValue();
EndFunction

// Gets the application header, and if it is not specified, a synonym for configuration metadata.
Function ThisInfobaseName() Export
	
	SetPrivilegedMode(True);
	Result = Constants.SystemTitle.Get();
	Return ?(IsBlankString(Result), Metadata.Synonym, Result);
	
EndFunction

#EndRegion
