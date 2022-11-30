///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Variables

&AtClient
Var ExternalResourcesAllowed;

#EndRegion

#Region EventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	UpdateExchangePlanChoiceList();
	
	UpdateRuleTemplateChoiceList();
	
	UpdateRuleInfo();
	
	UpdateRuleSource();
	
	DataExchangeRuleImportEventLogEvent = DataExchangeServer.DataExchangeRuleImportEventLogEvent();
	
	Items.ExchangePlanGroup.Visible = IsBlankString(Record.ExchangePlanName);
	
EndProcedure

&AtClient
Procedure BeforeWrite(Cancel, WriteParameters)
	
	If ExternalResourcesAllowed <> True Then
		
		ClosingNotification = New NotifyDescription("AllowExternalResourceCompletion", ThisObject, WriteParameters);
		If CommonClient.SubsystemExists("StandardSubsystems.SecurityProfiles") Then
			Queries = CreateRequestToUseExternalResources(Record);
			ModuleSafeModeManagerClient = CommonClient.CommonModule("SafeModeManagerClient");
			ModuleSafeModeManagerClient.ApplyExternalResourceRequests(Queries, ThisObject, ClosingNotification);
		Else
			ExecuteNotifyProcessing(ClosingNotification, DialogReturnCode.OK);
		EndIf;
		
		Cancel = True;
		Return;
		
	EndIf;
	ExternalResourcesAllowed = False;
	
	If RulesSource = "StandardRulesFromConfiguration" Then
		// Importing rules from configuration
		PerformRuleImport(Undefined, "", False);
	EndIf;
	
EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)
	
	If WriteParameters.Property("WriteAndClose") Then
		Close();
	EndIf;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure ExchangePlanNameOnChange(Item)
	
	Record.RulesTemplateName = "";
	
	// server call
	UpdateRuleTemplateChoiceList();
	
EndProcedure

&AtClient
Procedure RuleSourceOnChange(Item)
	
	Items.RulesSourceFile.Enabled = (RulesSource = "RuelsImportedFromFile");
	
	If RulesSource = "StandardRulesFromConfiguration" Then
		
		Record.DebugMode = False;
		
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandHandlers

&AtClient
Procedure ImportRules(Command)
	
	ClearMessages();
	
	// Importing from file on the client
	NameParts = CommonClientServer.ParseFullFileName(Record.RulesFileName);
	
	DialogParameters = New Structure;
	DialogParameters.Insert("Title", NStr("ru = 'Укажите, из какого файла загрузить правила'; en = 'Specify a file to import the rules from'; pl = 'Określ plik, z którego będą zaimportowane reguły';de = 'Geben Sie eine Datei an, aus der die Regeln importiert werden sollen';ro = 'Specificați un fișier pentru a importa regulile de la';tr = 'Kuralları içe aktarmak için bir dosya belirtin.'; es_ES = 'Especificar un archivo del cual importar las reglas'"));
	DialogParameters.Insert("Filter",
		  NStr("ru = 'Файлы правил регистрации (*.xml)'; en = 'Registration rule files (*.xml)'; pl = 'Pliki reguł rejestracji (*.xml)';de = 'Registrierungsregeldateien (*.xml)';ro = 'Fișierele regulilor de înregistrare (*.xml)';tr = 'Kayıt kural dosyaları (* .xml)'; es_ES = 'Archivo de las reglas de registro (*.xml)'") + "|*.xml|"
		+ NStr("ru = 'Архивы ZIP (*.zip)'; en = 'ZIP archive (*.zip)'; pl = 'Archiwum ZIP (*.zip)';de = 'ZIP-Archive (*.zip)';ro = 'Arhivele ZIP (*.zip)';tr = 'Zip arşivleri(*.zip)'; es_ES = 'Archivos ZIP (*.zip)'")   + "|*.zip");
	
	DialogParameters.Insert("FullFileName", NameParts.FullName);
	DialogParameters.Insert("FilterIndex", ?( Lower(NameParts.Extension) = ".zip", 1, 0) ); 
	
	Notification = New NotifyDescription("ImportRulesCompletion", ThisObject);
	DataExchangeClient.SelectAndSendFileToServer(Notification, DialogParameters, UUID);
EndProcedure

&AtClient
Procedure UnloadRules(Command)
	
	NameParts = CommonClientServer.ParseFullFileName(Record.RulesFileName);
	
	StorageAddress = GetURLAtServer();
	NameFilter = NStr("ru = 'Файлы правил (*.xml)'; en = 'Rule files (*.xml)'; pl = 'Pliki reguł (*.xml)';de = 'Regeldateien (*.xml)';ro = 'Fișiere de reguli (*.xml)';tr = 'Kural dosyaları (* .xml)'; es_ES = 'Archivos de reglas (*.xml)'") + "|*.xml";
	
	If IsBlankString(StorageAddress) Then
		Return;
	EndIf;
	
	If IsBlankString(NameParts.BaseName) Then
		FullFileName = NStr("ru = 'Правила регистрации'; en = 'Registration rules'; pl = 'Reguły rejestracji';de = 'Registrierungsregeln';ro = 'Regulile de înregistrare';tr = 'Kayıt Kuralları'; es_ES = 'Reglas de Registro'");
	Else
		FullFileName = NameParts.BaseName;
	EndIf;
	
	DialogParameters = New Structure;
	DialogParameters.Insert("Mode", FileDialogMode.Save);
	DialogParameters.Insert("Title", NStr("ru = 'Укажите в какой файл выгрузить правила'; en = 'Specify file to export rules'; pl = 'Określ do jakiego pliku wyeksportować reguły';de = 'Geben Sie eine Datei an, in die die Regeln exportiert werden';ro = 'Specificați fișierul în care vor fi descărcate regulile';tr = 'Kuralların dışa aktarılacağı bir dosya belirtin'; es_ES = 'Especificar un archivo para el cual las reglas se exportarán'") );
	DialogParameters.Insert("FullFileName", FullFileName);
	DialogParameters.Insert("Filter", NameFilter);
	
	FileToReceive = New Structure("Name, Location", FullFileName, StorageAddress);
	
	DataExchangeClient.SelectAndSaveFileAtClient(FileToReceive, DialogParameters);

	
EndProcedure

&AtClient
Procedure WriteAndClose(Command)
	
	WriteParameters = New Structure;
	WriteParameters.Insert("WriteAndClose");
	Write(WriteParameters);
	
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure ShowEventLogWhenErrorOccurred(Response, AdditionalParameters) Export
	
	If Response = DialogReturnCode.Yes Then
		
		Filter = New Structure;
		Filter.Insert("EventLogEvent", DataExchangeRuleImportEventLogEvent);
		OpenForm("DataProcessor.EventLog.Form", Filter, ThisObject, , , , , FormWindowOpeningMode.LockOwnerWindow);
		
	EndIf;
	
EndProcedure

&AtServer
Procedure UpdateExchangePlanChoiceList()
	
	ExchangePlanList = DataExchangeCached.SSLExchangePlansList();
	
	FillList(ExchangePlanList, Items.ExchangePlanName.ChoiceList);
	
EndProcedure

&AtServer
Procedure UpdateRuleTemplateChoiceList()
	
	If IsBlankString(Record.ExchangePlanName) Then
		
		Items.MainGroup.Title = NStr("ru = 'Правила конвертации'; en = 'Conversion rules'; pl = 'Reguły konwersji';de = 'Konvertierungsregeln';ro = 'Reguli de conversie';tr = 'Dönüşüm kuralları'; es_ES = 'Reglas de conversión'");
		
	Else
		
		Items.MainGroup.Title = StringFunctionsClientServer.SubstituteParametersToString(
			Items.MainGroup.Title, Metadata.ExchangePlans[Record.ExchangePlanName].Synonym);
		
	EndIf;
	
	TemplatesList = DataExchangeCached.RegistrationRulesForExchangePlanFromConfiguration(Record.ExchangePlanName);
	
	ChoiceList = Items.RulesTemplateName.ChoiceList;
	ChoiceList.Clear();
	
	FillList(TemplatesList, ChoiceList);
	
	Items.SourceConfigurationTemplate.CurrentPage = ?(TemplatesList.Count() = 1,
		Items.SingleTemplatePage, Items.SeveralTemplatesPage);
	
EndProcedure

&AtServer
Procedure FillList(SourceList, DestinationList)
	
	For Each Item In SourceList Do
		
		FillPropertyValues(DestinationList.Add(), Item);
		
	EndDo;
	
EndProcedure

&AtServer
Procedure ImportRulesAtServer(Cancel, TempStorageAddress, RulesFileName, IsArchive)
	
	Record.RulesSource = ?(RulesSource = "StandardRulesFromConfiguration",
		Enums.DataExchangeRulesSources.ConfigurationTemplate, Enums.DataExchangeRulesSources.File);
	
	Object = FormAttributeToValue("Record");
	
	InformationRegisters.DataExchangeRules.ImportRules(Cancel, Object, TempStorageAddress, RulesFileName, IsArchive);
	
	If Not Cancel Then
		
		Object.Write();
		
		Modified = False;
		
		// Open session cache for the registration mechanism has become obsolete.
		DataExchangeInternal.ResetObjectsRegistrationMechanismCache();
		RefreshReusableValues();
	EndIf;
	
	ValueToFormAttribute(Object, "Record");
	
	UpdateRuleInfo();
	Items.ExchangePlanGroup.Visible = IsBlankString(Record.ExchangePlanName);
	
EndProcedure

&AtServer
Function GetURLAtServer()
	
	Filter = New Structure;
	Filter.Insert("ExchangePlanName", Record.ExchangePlanName);
	Filter.Insert("RulesKind",      Record.RulesKind);
	
	RecordKey = InformationRegisters.DataExchangeRules.CreateRecordKey(Filter);
	
	Return GetURL(RecordKey, "XMLRules");
	
EndFunction

&AtServer
Procedure UpdateRuleInfo()
	
	If Record.RulesSource = Enums.DataExchangeRulesSources.File Then
		
		RulesInformation = NStr("ru = 'Использование правил, загруженных из файла,
									|может привести к ошибкам при переходе на новую версию программы.
									|
									|[RulesInformation]'; 
									|en = 'Using rules imported from the file
									|may cause some problems when migrating to a new version of the application.
									|
									|[RulesInformation]'; 
									|pl = 'Używanie reguł, pobranych z pliku,
									|może prowadzić do błędów podczas aktualizacji do nowej wersji programu.
									|
									|[RulesInformation]';
									|de = 'Die Verwendung von Regeln, die aus der Datei
									|importiert wurden, kann zu Problemen bei der Übertragung auf eine neue Version der Anwendung führen.
									|
									|[RulesInformation]';
									|ro = 'Utilizarea regulilor importate din fișier
									|poate cauza probleme când se transferă la o nouă versiune a aplicației.
									|
									|[RulesInformation]';
									|tr = 'Dosyadan içe aktarılan kuralları kullanmak, 
									|uygulamanın yeni bir sürümüne aktarırken bazı sorunlara neden olur. 
									| 
									|[RulesInformation]'; 
									|es_ES = 'El uso de reglas descargadas del archivos
									|puede llevar a errores al pasar a la versión nueva del programa.
									|
									|[RulesInformation]'");
		
		RulesInformation = StrReplace(RulesInformation, "[RulesInformation]", Record.RulesInformation);
		
	Else
		
		RulesInformation = Record.RulesInformation;
		
	EndIf;
	
EndProcedure

&AtServer
Procedure UpdateRuleSource()
	
	RulesSource = ?(Record.RulesSource = Enums.DataExchangeRulesSources.ConfigurationTemplate,
		"StandardRulesFromConfiguration", "RuelsImportedFromFile");
	
EndProcedure

&AtClient
Procedure PerformRuleImport(Val PutFileAddress, Val FileName, Val IsArchive)
	Cancel = False;
	
	ImportRulesAtServer(Cancel, PutFileAddress, FileName, IsArchive);
	
	If Not Cancel Then
		ShowUserNotification(,, NStr("ru = 'Правила успешно загружены в информационную базу.'; en = 'The rules are imported to the infobase.'; pl = 'Import reguł do bazy informacyjnej zakończony pomyślnie.';de = 'Die Regeln wurden erfolgreich in die Infobase importiert.';ro = 'Regulile au fost importate cu succes în baza de date.';tr = 'Kurallar, veritabanına başarıyla aktarıldı.'; es_ES = 'Reglas se han importado con éxito a la infobase.'"));
		Return;
	EndIf;
	
	ErrorText = NStr("ru = 'В процессе загрузки правил были обнаружены ошибки.
	                         |Перейти в журнал регистрации?'; 
	                         |en = 'Errors occurred when importing the rules.
	                         |Proceed to the event log?'; 
	                         |pl = 'Błędy wykryto podczas pobierania reguł.
	                         |Przejdź do dziennika rejestracji?';
	                         |de = 'Beim Importieren der Regeln wurden Fehler festgestellt.
	                         |Zum Ereignisprotokoll wechseln?';
	                         |ro = 'Erori în procesul de import al regulilor.
	                         |Treceți în registrul logare?';
	                         |tr = 'Kurallar içe aktarılırken hatalar tespit edildi. 
	                         |Kayıt günlüğüne geçmek istiyor musunuz?'; 
	                         |es_ES = 'Al descargar las reglas se han encontrado errores.
	                         |¿Pasar al registro?'");
	
	Notification = New NotifyDescription("ShowEventLogWhenErrorOccurred", ThisObject);
	ShowQueryBox(Notification, ErrorText, QuestionDialogMode.YesNo, ,DialogReturnCode.No);
EndProcedure

&AtClient
Procedure ImportRulesCompletion(Val PutFilesResult, Val AdditionalParameters) Export
	
	PutFileAddress = PutFilesResult.Location;
	ErrorText           = PutFilesResult.ErrorDescription;
	
	If IsBlankString(ErrorText) AND IsBlankString(PutFileAddress) Then
		ErrorText = NStr("ru = 'Ошибка передачи файла на сервер'; en = 'An error occurred when transferring the file to the server'; pl = 'Podczas przesyłania pliku na serwer wystąpił błąd';de = 'Beim Übertragen der Datei an den Server ist ein Fehler aufgetreten';ro = 'A apărut o eroare la transferarea fișierului pe server';tr = 'Dosya sunucuya aktarılırken bir hata oluştu'; es_ES = 'Ha ocurrido un error al transferir el archivo al servidor'");
	EndIf;
	
	If Not IsBlankString(ErrorText) Then
		CommonClient.MessageToUser(ErrorText);
		Return;
	EndIf;
		
	RulesSource = "RuelsImportedFromFile";
	
	// The file is successfully transferred, importing the file to the server.
	NameParts = CommonClientServer.ParseFullFileName(PutFilesResult.Name);
	
	PerformRuleImport(PutFileAddress, NameParts.Name, Lower(NameParts.Extension) = ".zip");
EndProcedure

&AtClient
Procedure AllowExternalResourceCompletion(Result, WriteParameters) Export
	
	If Result = DialogReturnCode.OK Then
		ExternalResourcesAllowed = True;
		Write(WriteParameters);
	EndIf;
	
EndProcedure

&AtServerNoContext
Function CreateRequestToUseExternalResources(Val Record)
	
	PermissionsRequests = New Array;
	ConversionRulesFromFile = InformationRegisters.DataExchangeRules.ConversionRulesFromFile(Record.ExchangePlanName);
	HasConvertionRules = (ConversionRulesFromFile <> Undefined);
	RegistrationRulesFromFile = (Record.RulesSource = Enums.DataExchangeRulesSources.File);
	InformationRegisters.DataExchangeRules.RequestToUseExternalResources(PermissionsRequests,
		?(HasConvertionRules, ConversionRulesFromFile, Record), HasConvertionRules, RegistrationRulesFromFile);
	Return PermissionsRequests;
	
EndFunction

#EndRegion
