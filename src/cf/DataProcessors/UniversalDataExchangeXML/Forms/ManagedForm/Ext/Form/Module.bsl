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
	
	// First of all, checking the access rights.
	If Not AccessRight("Administration", Metadata) Then
		Raise NStr("ru = 'Использование обработки в интерактивном режиме доступно только администратору.'; en = 'Running the data processor manually requires administrator rights.'; pl = 'Używanie przetwarzania danych w trybie interaktywnym jest dostępne tylko dla administratora.';de = 'Die Verwendung des Datenprozessors im interaktiven Modus ist nur für Administratoren verfügbar.';ro = 'Utilizarea procesării în modul interactiv este disponibilă numai pentru administrator.';tr = 'Etkileşimli modda veri işlemcisi kullanımı sadece yönetici için kullanılabilir.'; es_ES = 'Uso del procesador de datos en el modo interactivo está disponible solo para el administrador'");
	EndIf;
	
	CheckPlatformVersionAndCompatibilityMode();
	
	Object.IsInteractiveMode = True;
	Object.SafeMode = True;
	Object.ExchangeProtocolFileEncoding = "TextEncoding.UTF8";
	
	FormHeader = NStr("ru = 'Универсальный обмен данными в формате XML (%DataProcessorVersion%)'; en = 'Universal data exchange in XML format (%DataProcessorVersion%)'; pl = 'Uniwersalna wymiana danymi w formacie XML (%DataProcessorVersion%)';de = 'Universeller Datenaustausch im XML-Format (%DataProcessorVersion%)';ro = 'Universal data exchange in XML format (%DataProcessorVersion%)';tr = 'XML formatında üniversal veri değişimi (%DataProcessorVersion%)'; es_ES = 'Intercambio de datos universal en el formato XML (%DataProcessorVersion%)'");
	FormHeader = StrReplace(FormHeader, "%DataProcessorVersion%", ObjectVersionAsStringAtServer());
	
	Title = FormHeader;
	
	FillTypeAvailableToDeleteList();
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	Items.RulesFileName.ChoiceList.LoadValues(ExchangeRules.UnloadValues());
	Items.ExchangeFileName.ChoiceList.LoadValues(DataImportFromFile.UnloadValues());
	Items.DataFileName.ChoiceList.LoadValues(DataExportToFile.UnloadValues());
	
	OnPeriodChange();
	
	OnChangeChangesRegistrationDeletionType();
	
	ClearDataImportFileData();
	
	DirectExport = ?(Object.DirectReadingInDestinationIB, 1, 0);
	
	SavedImportMode = (Object.ExchangeMode = "Load");
	
	If SavedImportMode Then
		
		// Setting the appropriate page.
		Items.FormMainPanel.CurrentPage = Items.FormMainPanel.ChildItems.Load;
		
	EndIf;
	
	ProcessTransactionManagementItemsEnabled();
	
	ExpandTreeRows(DataToDelete, Items.DataToDelete, "Check");
	
	ArchiveFileOnValueChange();
	DirectExportOnValueChange();
	
	ChangeProcessingMode(IsClient);
	
	#If WebClient Then
		Items.ExportDebugPages.CurrentPage = Items.ExportDebugPages.ChildItems.WebClientExportGroup;
		Items.ImportDebugPages.CurrentPage = Items.ImportDebugPages.ChildItems.WebClientImportGroup;
		Object.HandlersDebugModeFlag = False;
	#EndIf
	
	SetDebugCommandsEnabled();
	
	If SavedImportMode
		AND Object.AutomaticDataImportSetup <> 0 Then
		
		If Object.AutomaticDataImportSetup = 1 Then
			
			NotifyDescription = New NotifyDescription("OnOpenCompletion", ThisObject);
			ShowQueryBox(NotifyDescription, NStr("ru = 'Выполнить загрузку данных из файла обмена?'; en = 'Do you want to import data from the exchange file?'; pl = 'Importować dane z pliku wymiany?';de = 'Daten von der Austausch-Datei importieren?';ro = 'Importați date din fișierul de schimb?';tr = 'Veri alışveriş dosyasından içe aktarılsın mı?'; es_ES = '¿Importar los datos del archivo de intercambio?'"), QuestionDialogMode.YesNo, , DialogReturnCode.Yes);
			
		Else
			
			OnOpenCompletion(DialogReturnCode.Yes, Undefined);
			
		EndIf;
		
	EndIf;
	
	If Not IsWindowsClient() Then
		Items.OSGroup.CurrentPage = Items.OSGroup.ChildItems.LinuxGroup;
	EndIf;
	
EndProcedure

&AtClient
Procedure OnOpenCompletion(Result, AdditionalParameters) Export
	
	If Result = DialogReturnCode.Yes Then
		
		ExecuteImportFromForm();
		ExportPeriodPresentation = PeriodPresentation(Object.StartDate, Object.EndDate);
		
	EndIf;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure ArchiveFileOnChange(Item)
	
	ArchiveFileOnValueChange();
	
EndProcedure

&AtClient
Procedure ExchangeRulesFileNameStartChoice(Item, ChoiceData, StandardProcessing)
	
	SelectFile(Item, ThisObject, "RulesFileName", True, , False, True);
	
EndProcedure

&AtClient
Procedure ExchangeRulesFileNameOpen(Item, StandardProcessing)
	
	OpenInApplication(Item.EditText, StandardProcessing);
	
EndProcedure

&AtClient
Procedure DirectExportOnChange(Item)
	
	DirectExportOnValueChange();
	
EndProcedure

&AtClient
Procedure FormMainPanelOnCurrentPageChange(Item, CurrentPage)
	
	If CurrentPage.Name = "DataExported" Then
		
		Object.ExchangeMode = "DataExported";
		
	ElsIf CurrentPage.Name = "Load" Then
		
		Object.ExchangeMode = "Load";
		
	EndIf;
	
EndProcedure

&AtClient
Procedure DebugModeFlagOnChange(Item)
	
	If Object.DebugModeFlag Then
		
		Object.UseTransactions = False;
				
	EndIf;
	
	ProcessTransactionManagementItemsEnabled();

EndProcedure

&AtClient
Procedure ProcessedObjectCountToUpdateStatusOnChange(Item)
	
	If Object.ProcessedObjectsCountToUpdateStatus = 0 Then
		Object.ProcessedObjectsCountToUpdateStatus = 100;
	EndIf;
	
EndProcedure

&AtClient
Procedure ExchangeFileNameStartChoice(Item, ChoiceData, StandardProcessing)
	
	SelectFile(Item, ThisObject, "ExchangeFileName", False, , Object.ArchiveFile);
	
EndProcedure

&AtClient
Procedure ExchangeProtocolFileNameStartChoice(Item, ChoiceData, StandardProcessing)
	
	SelectFile(Item, Object, "ExchangeProtocolFileName", False, "txt", False);
	
EndProcedure

&AtClient
Procedure ImportExchangeProtocolFileNameStartChoice(Item, ChoiceData, StandardProcessing)
	
	SelectFile(Item, Object, "ImportExchangeLogFileName", False, "txt", False);
	
EndProcedure

&AtClient
Procedure DataFileNameStartChoice(Item, ChoiceData, StandardProcessing)
	
	SelectFile(Item, ThisObject, "DataFileName", False, , Object.ArchiveFile);
	
EndProcedure

&AtClient
Procedure InfobaseConnectionDirectoryStartChoice(Item, ChoiceData, StandardProcessing)
	
	FileSelectionDialog = New FileDialog(FileDialogMode.ChooseDirectory);
	
	FileSelectionDialog.Title = NStr("ru = 'Выберите каталог информационной базы'; en = 'Select infobase directory'; pl = 'Wybierz katalog bazy informacyjnej';de = 'Wählen Sie ein Infobase-Verzeichnis';ro = 'Selectați un director al bazei de date';tr = 'Bir veritabanı yedekleme dizini seçin'; es_ES = 'Seleccionar un directorio de la infobase'");
	FileSelectionDialog.Directory = Object.InfobaseToConnectDirectory;
	FileSelectionDialog.CheckFileExist = True;
	
	Notification = New NotifyDescription("ProcessSelectionInfobaseDirectoryToAdd", ThisObject);
	FileSelectionDialog.Show(Notification);
	
EndProcedure

&AtClient
Procedure ProcessSelectionInfobaseDirectoryToAdd(SelectedFiles, AdditionalParameters) Export
	
	If SelectedFiles = Undefined Then
		Return;
	EndIf;
	
	Object.InfobaseToConnectDirectory = SelectedFiles[0];
	
EndProcedure

&AtClient
Procedure ExchangeProtocolFileNameOpen(Item, StandardProcessing)
	
	OpenInApplication(Item.EditText, StandardProcessing);
	
EndProcedure

&AtClient
Procedure ImportExchangeProtocolFileNameOpen(Item, StandardProcessing)
	
	OpenInApplication(Item.EditText, StandardProcessing);
	
EndProcedure

&AtClient
Procedure InfobaseConnectionDirectoryOpen(Item, StandardProcessing)
	
	OpenInApplication(Item.EditText, StandardProcessing);
	
EndProcedure

&AtClient
Procedure InfobaseWindowsAuthenticationForConnectionOnChange(Item)
	
	Items.InfobaseToConnectUser.Enabled = NOT Object.InfobaseToConnectWindowsAuthentication;
	Items.InfobaseToConnectPassword.Enabled = NOT Object.InfobaseToConnectWindowsAuthentication;
	
EndProcedure

&AtClient
Procedure RuleFileNameOnChange(Item)
	
	File = New File(RulesFileName);
	
	Notification = New NotifyDescription("AfterExistenceCheckRulesFileName", ThisObject);
	File.BeginCheckingExistence(Notification);
	
EndProcedure

&AtClient
Procedure AfterExistenceCheckRulesFileName(Exists, AdditionalParameters) Export
	
	If Not Exists Then
		MessageToUser(NStr("ru = 'Не найден файл правил обмена'; en = 'Exchange rule file not found'; pl = 'Nie znaleziono pliku reguł wymiany.';de = 'Die Datei der Austauschregeln wurde nicht gefunden';ro = 'Fișierul regulilor de schimb nu a fost găsit';tr = 'Değişim kuralları dosyası bulunamadı'; es_ES = 'Archivo de las reglas de intercambio no encontrado'"), "RulesFileName");
		SetImportRuleFlag(False);
		Return;
	EndIf;
	
	If RuleAndExchangeFileNamesMatch() Then
		Return;
	EndIf;
	
	NotifyDescription = New NotifyDescription("RuleFileNameOnChangeCompletion", ThisObject);
	ShowQueryBox(NotifyDescription, NStr("ru = 'Загрузить правила обмена данными?'; en = 'Do you want to import data exchange rules?'; pl = 'Importuj reguły wymiany danych?';de = 'Importieren Sie Datenaustauschregeln?';ro = 'Importați regulile schimbului de date?';tr = 'Veri değişimi kuralları içe aktarılsın mı?'; es_ES = '¿Importar las reglas de intercambio de datos?'"), QuestionDialogMode.YesNo, , DialogReturnCode.Yes);
	
EndProcedure

&AtClient
Procedure RuleFileNameOnChangeCompletion(Result, AdditionalParameters) Export
	
	If Result = DialogReturnCode.Yes Then
		
		ExecuteImportExchangeRules();
		
	Else
		
		SetImportRuleFlag(False);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure ExchangeFileNameOpen(Item, StandardProcessing)
	
	OpenInApplication(Item.EditText, StandardProcessing);
	
EndProcedure

&AtClient
Procedure ExchangeFileNameOnChange(Item)
	
	ClearDataImportFileData();
	
EndProcedure

&AtClient
Procedure UseTransactionsOnChange(Item)
	
	ProcessTransactionManagementItemsEnabled();
	
EndProcedure

&AtClient
Procedure ImportHandlerDebugModeFlagOnChange(Item)
	
	SetDebugCommandsEnabled();
	
EndProcedure

&AtClient
Procedure ExportHandlerDebugModeFlagOnChange(Item)
	
	SetDebugCommandsEnabled();
	
EndProcedure

&AtClient
Procedure DataFileNameOpening(Item, StandardProcessing)
	
	OpenInApplication(Item.EditText, StandardProcessing);
	
EndProcedure

&AtClient
Procedure DataFileNameOnChange(Item)
	
	If EmptyAttributeValue(DataFileName, "DataFileName", Items.DataFileName.Title)
		Or RuleAndExchangeFileNamesMatch() Then
		Return;
	EndIf;
	
	Object.ExchangeFileName = DataFileName;
	
	File = New File(Object.ExchangeFileName);
	Object.ArchiveFile = (Upper(File.Extension) = Upper(".zip"));
	
EndProcedure

&AtClient
Procedure InfobaseTypeForConnectionOnChange(Item)
	
	InfobaseTypeForConnectionOnValueChange();
	
EndProcedure

&AtClient
Procedure InfobasePlatformVersionForConnectionOnChange(Item)
	
	If IsBlankString(Object.InfobaseToConnectPlatformVersion) Then
		
		Object.InfobaseToConnectPlatformVersion = "V8";
		
	EndIf;
	
EndProcedure

&AtClient
Procedure ChangeRecordsForExchangeNodeDeleteAfterExportTypeOnChange(Item)
	
	OnChangeChangesRegistrationDeletionType();
	
EndProcedure

&AtClient
Procedure ExportPeriodOnChange(Item)
	
	OnPeriodChange();
	
EndProcedure

&AtClient
Procedure DeletionPeriodOnChange(Item)
	
	OnPeriodChange();
	
EndProcedure

&AtClient
Procedure SafeImportOnChange(Item)
	
	ChangeSafeImportMode();
	
EndProcedure

&AtClient
Procedure NameOfImportRulesFileStartChoice(Item, ChoiceData, StandardProcessing)
	
	SelectFile(Item, ThisObject, "NameOfImportRulesFile", True, , False, True);
	
EndProcedure

&AtClient
Procedure NameOfImportRulesFileOnChange(Item)
	
	PutImportRulesFileInStorage();
	
EndProcedure

#EndRegion

#Region ExportRulesTableFormTableItemsEventHandlers

&AtClient
Procedure ExportRulesTableBeforeRowChange(Item, Cancel)
	
	If Item.CurrentItem.Name = "ExchangeNodeRef" Then
		
		If Item.CurrentData.IsFolder Then
			Cancel = True;
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure ExportRulesTableOnChange(Item)
	
	If Item.CurrentItem.Name = "DER" Then
		
		curRow = Item.CurrentData;
		
		If curRow.Enable = 2 Then
			curRow.Enable = 0;
		EndIf;
		
		SetSubordinateItemsMarks(curRow, "Enable");
		SetParentMarks(curRow, "Enable");
		
	EndIf;
	
EndProcedure

#EndRegion

#Region DataToDeleteFormTableItemEventHandlers

&AtClient
Procedure DataToDeleteOnChange(Item)
	
	curRow = Item.CurrentData;
	
	SetSubordinateItemsMarks(curRow, "Check");
	SetParentMarks(curRow, "Check");

EndProcedure

#EndRegion

#Region FormCommandHandlers

&AtClient
Procedure ConnectionTest(Command)
	
	EstablishConnectionWithDestinationIBAtServer();
	
EndProcedure

&AtClient
Procedure GetExchangeFileInfo(Command)
	
	FileAddress = "";
	
	If IsClient Then
		
		NotifyDescription = New NotifyDescription("GetExchangeFileInfoCompletion", ThisObject);
		BeginPutFile(NotifyDescription, FileAddress,NStr("ru = 'Файл обмена'; en = 'Exchange file'; pl = 'Plik wymiany';de = 'Datei austauschen';ro = 'Schimbați fișierul';tr = 'Alışveriş dosyası'; es_ES = 'Archivo de intercambio'"),, UUID);
		
	Else
		
		GetExchangeFileInfoCompletion(True, FileAddress, "", Undefined);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure GetExchangeFileInfoCompletion(Result, Address, SelectedFileName, AdditionalParameters) Export
	
	If Result Then
		
		Try
			
			OpenImportFileAtServer(Address);
			ExportPeriodPresentation = PeriodPresentation(Object.StartDate, Object.EndDate);
			
		Except
			
			MessageToUser(NStr("ru = 'Не удалось прочитать файл обмена.'; en = 'Cannot read the exchange file.'; pl = 'Nie można odczytać pliku wymiany.';de = 'Die Austauschdatei kann nicht gelesen werden.';ro = 'Nu se poate citi fișierul de schimb.';tr = 'Değişim dosyası okunamıyor.'; es_ES = 'No se puede leer el archivo de intercambio.'"));
			ClearDataImportFileData();
			
		EndTry;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure DeletionSelectAll(Command)
	
	For Each Row In DataToDelete.GetItems() Do
		
		Row.Check = 1;
		SetSubordinateItemsMarks(Row, "Check");
		
	EndDo;
	
EndProcedure

&AtClient
Procedure DeletionClearAll(Command)
	
	For Each Row In DataToDelete.GetItems() Do
		Row.Check = 0;
		SetSubordinateItemsMarks(Row, "Check");
	EndDo;
	
EndProcedure

&AtClient
Procedure DeletionDelete(Command)
	
	NotifyDescription = New NotifyDescription("DeletionDeleteCompletion", ThisObject);
	ShowQueryBox(NotifyDescription, NStr("ru = 'Удалить выбранные данные в информационной базе?'; en = 'Do you want to delete selected data?'; pl = 'Usunąć wybrane dane z bazy informacyjnej?';de = 'Die ausgewählten Daten in der Infobase löschen?';ro = 'Ștergeți datele selectate în baza de date?';tr = 'Seçilen veriler veritabanında silinsin mi?'; es_ES = '¿Borrar los datos seleccionados en la infobase?'"), QuestionDialogMode.YesNo, , DialogReturnCode.No);
	
EndProcedure

&AtClient
Procedure DeletionDeleteCompletion(Result, AdditionalParameters) Export
	
	If Result = DialogReturnCode.Yes Then
		
		DeleteAtServer();
		
	EndIf;
	
EndProcedure

&AtClient
Procedure ExportSelectAll(Command)
	
	For Each Row In Object.ExportRuleTable.GetItems() Do
		Row.Enable = 1;
		SetSubordinateItemsMarks(Row, "Enable");
	EndDo;
	
EndProcedure

&AtClient
Procedure ExportClearAll(Command)
	
	For Each Row In Object.ExportRuleTable.GetItems() Do
		Row.Enable = 0;
		SetSubordinateItemsMarks(Row, "Enable");
	EndDo;
	
EndProcedure

&AtClient
Procedure ExportClearExchangeNodes(Command)
	
	FillExchangeNodeInTreeRowsAtServer(Undefined);
	
EndProcedure

&AtClient
Procedure ExportMarkExchangeNode(Command)
	
	If Items.ExportRuleTable.CurrentData = Undefined Then
		Return;
	EndIf;
	
	FillExchangeNodeInTreeRowsAtServer(Items.ExportRuleTable.CurrentData.ExchangeNodeRef);
	
EndProcedure

&AtClient
Procedure SaveParameters(Command)
	
	SaveParametersAtServer();
	
EndProcedure

&AtClient
Procedure RestoreParameters(Command)
	
	RestoreParametersAtServer();
	
EndProcedure

&AtClient
Procedure ExportDebugSetup(Command)
	
	Object.ExchangeRuleFileName = FileNameAtServerOrClient(RulesFileName, RuleFileAddressInStorage);
	
	OpenHandlerDebugSetupForm(True);
	
EndProcedure

&AtClient
Procedure AtClient(Command)
	
	If Not IsClient Then
		
		IsClient = True;
		
		ChangeProcessingMode(IsClient);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure AtServer(Command)
	
	If IsClient Then
		
		IsClient = False;
		
		ChangeProcessingMode(IsClient);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure ImportDebugSetup(Command)
	
	ExchangeFileAddressInStorage = "";
	FileNameForExtension = "";
	
	If IsClient Then
		
		NotifyDescription = New NotifyDescription("ImportDebugSetupCompletion", ThisObject);
		BeginPutFile(NotifyDescription, ExchangeFileAddressInStorage,NStr("ru = 'Файл обмена'; en = 'Exchange file'; pl = 'Plik wymiany';de = 'Datei austauschen';ro = 'Schimbați fișierul';tr = 'Alışveriş dosyası'; es_ES = 'Archivo de intercambio'"),, UUID);
		
	Else
		
		If EmptyAttributeValue(ExchangeFileName, "ExchangeFileName", Items.ExchangeFileName.Title) Then
			Return;
		EndIf;
		
		ImportDebugSetupCompletion(True, ExchangeFileAddressInStorage, FileNameForExtension, Undefined);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure ImportDebugSetupCompletion(Result, Address, SelectedFileName, AdditionalParameters) Export
	
	If Result Then
		
		Object.ExchangeFileName = FileNameAtServerOrClient(ExchangeFileName ,Address, SelectedFileName);
		
		OpenHandlerDebugSetupForm(False);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure ExecuteExport(Command)
	
	ExecuteExportFromForm();
	
EndProcedure

&AtClient
Procedure ExecuteImport(Command)
	
	ExecuteImportFromForm();
	
EndProcedure

&AtClient
Procedure ReadExchangeRules(Command)
	
	If Not IsWindowsClient() AND DirectExport = 1 Then
		ShowMessageBox(,NStr("ru = 'Прямое подключение к информационной базе поддерживается только в клиенте под управлением ОС Windows.'; en = 'Direct connection to the infobase is available only on a client running Windows OS.'; pl = 'Bezpośrednie podłączenie do bazy informacyjnej jest obsługiwane tylko w kliencie w systemie operacyjnym Windows.';de = 'Eine direkte Verbindung zur Informationsbasis wird nur auf dem Client unter Windows unterstützt.';ro = 'Conectarea directă la baza de date este susținută numai în clientul gestionat de sistemul de operare Windows.';tr = 'Veri tabanına doğrudan bağlantı yalnızca Windows tabanlı bir istemcide desteklenir.'; es_ES = 'Conexión directa a la infobase solo se admite en un cliente bajo OS Windows.'"));
		Return;
	EndIf;
	
	FileNameForExtension = "";
	
	If IsClient Then
		
		NotifyDescription = New NotifyDescription("ReadExchangeRulesCompletion", ThisObject);
		BeginPutFile(NotifyDescription, RuleFileAddressInStorage,NStr("ru = 'Файл правил обмена'; en = 'Exchange rule file'; pl = 'Plik reguł wymiany';de = 'Austausch-Regeldatei';ro = 'Schimbați regula fișierului';tr = 'Alışveriş kuralı dosyası'; es_ES = 'Archivo de la regla de intercambio'"),, UUID);
		
	Else
		
		RuleFileAddressInStorage = "";
		If EmptyAttributeValue(RulesFileName, "RulesFileName", Items.RulesFileName.Title) Then
			Return;
		EndIf;
		
		ReadExchangeRulesCompletion(True, RuleFileAddressInStorage, FileNameForExtension, Undefined);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure ReadExchangeRulesCompletion(Result, Address, SelectedFileName, AdditionalParameters) Export
	
	If Result Then
		
		RuleFileAddressInStorage = Address;
		
		ExecuteImportExchangeRules(Address, SelectedFileName);
		
		If Object.ErrorFlag Then
			
			SetImportRuleFlag(False);
			
		Else
			
			SetImportRuleFlag(True);
			
		EndIf;
		
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

// Opens an exchange file in an external application.
//
// Parameters:
//  
// 
&AtClient
Procedure OpenInApplication(FileName, StandardProcessing = False)
	
	StandardProcessing = False;
	
	AdditionalParameters = New Structure();
	AdditionalParameters.Insert("FileName", FileName);
	AdditionalParameters.Insert("NotifyDescription", New NotifyDescription);
	
	File = New File();
	File.BeginInitialization(New NotifyDescription("CheckFileExistence", ThisObject, AdditionalParameters), FileName);
	
EndProcedure

// Continuation of the procedure (see above).
&AtClient
Procedure CheckFileExistence(File, AdditionalParameters) Export
	NotifyDescription = New NotifyDescription("AfterDetermineFileExistence", ThisObject, AdditionalParameters);
	File.BeginCheckingExistence(NotifyDescription);
EndProcedure

// Continuation of the procedure (see above).
&AtClient
Procedure AfterDetermineFileExistence(Exists, AdditionalParameters) Export
	
	If Exists Then
		BeginRunningApplication(AdditionalParameters.NotifyDescription, AdditionalParameters.FileName);
	EndIf;
	
EndProcedure

&AtClient
Procedure ClearDataImportFileData()
	
	Object.ExchangeRulesVersion = "";
	Object.DataExportDate = "";
	ExportPeriodPresentation = "";
	
EndProcedure

&AtClient
Procedure ProcessTransactionManagementItemsEnabled()
	
	Items.UseTransactions.Enabled = NOT Object.DebugModeFlag;
	
	Items.ObjectsPerTransaction.Enabled = Object.UseTransactions;
	
EndProcedure

&AtClient
Procedure ArchiveFileOnValueChange()
	
	If Object.ArchiveFile Then
		DataFileName = StrReplace(DataFileName, ".xml", ".zip");
	Else
		DataFileName = StrReplace(DataFileName, ".zip", ".xml");
	EndIf;
	
	Items.ExchangeFileCompressionPassword.Enabled = Object.ArchiveFile;
	
EndProcedure

&AtServer
Procedure FillExchangeNodeInTreeRows(Tree, ExchangeNode)
	
	For Each Row In Tree Do
		
		If Row.IsFolder Then
			
			FillExchangeNodeInTreeRows(Row.GetItems(), ExchangeNode);
			
		Else
			
			Row.ExchangeNodeRef = ExchangeNode;
			
		EndIf;
		
	EndDo;
	
EndProcedure

&AtClient
Function RuleAndExchangeFileNamesMatch()
	
	If Upper(TrimAll(RulesFileName)) = Upper(TrimAll(DataFileName)) Then
		
		MessageToUser(NStr("ru = 'Файл правил обмена не может совпадать с файлом данных.
		|Выберите другой файл для выгрузки данных.'; 
		|en = 'Exchange rule file cannot match the data file.
		|Select another file to export the data to.'; 
		|pl = 'Plik reguł wymiany nie może być jednakowy z plikiem danych.
		|Wybierz inny plik do eksportu danych.';
		|de = 'Die Austausch-Regeldatei kann nicht mit der Datendatei übereinstimmen.
		|Wählen Sie die andere Datei für den Datenexport.';
		|ro = 'Fișierul regulilor de schimb nu poate coincide cu fișierul de date.
		|Selectați celălalt fișier pentru exportul de date.';
		|tr = 'Alışveriş kuralları dosyası veri dosyasıyla eşleşemez. 
		|Veri aktarımı için diğer dosyayı seçin.'; 
		|es_ES = 'Archivo de las reglas de intercambio no puede emparejarse con el archivo de datos.
		|Seleccionar otro archivo para la exportación de datos.'"));
		Return True;
		
	Else
		
		Return False;
		
	EndIf;
	
EndFunction

// Fills a value tree with metadata objects available for deletion
&AtServer
Procedure FillTypeAvailableToDeleteList()
	
	DataTree = FormAttributeToValue("DataToDelete");
	
	DataTree.Rows.Clear();
	
	TreeRow = DataTree.Rows.Add();
	TreeRow.Presentation = NStr("ru = 'Справочники'; en = 'Catalogs'; pl = 'Katalogi';de = 'Stammdaten';ro = 'Cataloage';tr = 'Ana kayıtlar'; es_ES = 'Catálogos'");
	
	For each MetadataObject In Metadata.Catalogs Do
		
		If Not AccessRight("Delete", MetadataObject) Then
			Continue;
		EndIf;
		
		MDRow = TreeRow.Rows.Add();
		MDRow.Presentation = MetadataObject.Name;
		MDRow.Metadata = "CatalogRef." + MetadataObject.Name;
		
	EndDo;
	
	TreeRow = DataTree.Rows.Add();
	TreeRow.Presentation = NStr("ru = 'Планы видов характеристик'; en = 'Charts of characteristic types'; pl = 'Plany rodzajów charakterystyk';de = 'Diagramme von charakteristischen Typen';ro = 'Diagrame de tipuri caracteristice';tr = 'Karakteristik tiplerin çizelgeleri'; es_ES = 'Diagramas de los tipos de características'");
	
	For each MetadataObject In Metadata.ChartsOfCharacteristicTypes Do
		
		If Not AccessRight("Delete", MetadataObject) Then
			Continue;
		EndIf;
		
		MDRow = TreeRow.Rows.Add();
		MDRow.Presentation = MetadataObject.Name;
		MDRow.Metadata = "ChartOfCharacteristicTypesRef." + MetadataObject.Name;
		
	EndDo;
	
	TreeRow = DataTree.Rows.Add();
	TreeRow.Presentation = NStr("ru = 'Документы'; en = 'Documents'; pl = 'Dokumenty';de = 'Dokumente';ro = 'Documente';tr = 'Belgeler'; es_ES = 'Documentos'");
	
	For each MetadataObject In Metadata.Documents Do
		
		If Not AccessRight("Delete", MetadataObject) Then
			Continue;
		EndIf;
		
		MDRow = TreeRow.Rows.Add();
		MDRow.Presentation = MetadataObject.Name;
		MDRow.Metadata = "DocumentRef." + MetadataObject.Name;
		
	EndDo;
	
	TreeRow = DataTree.Rows.Add();
	TreeRow.Presentation = "InformationRegisters";
	
	For each MetadataObject In Metadata.InformationRegisters Do
		
		If Not AccessRight("Update", MetadataObject) Then
			Continue;
		EndIf;
		
		Subordinate = (MetadataObject.WriteMode = Metadata.ObjectProperties.RegisterWriteMode.RecorderSubordinate);
		If Subordinate Then Continue EndIf;
		
		MDRow = TreeRow.Rows.Add();
		MDRow.Presentation = MetadataObject.Name;
		MDRow.Metadata = "InformationRegisterRecord." + MetadataObject.Name;
		
	EndDo;
	
	ValueToFormAttribute(DataTree, "DataToDelete");
	
EndProcedure

// Returns data processor version
&AtServer
Function ObjectVersionAsStringAtServer()
	
	Return FormAttributeToValue("Object").ObjectVersionAsString();
	
EndFunction

&AtClient
Procedure ExecuteImportExchangeRules(RuleFileAddressInStorage = "", FileNameForExtension = "")
	
	Object.ErrorFlag = False;
	
	ImportExchangeRulesAndParametersAtServer(RuleFileAddressInStorage, FileNameForExtension);
	
	If Object.ErrorFlag Then
		
		SetImportRuleFlag(False);
		
	Else
		
		SetImportRuleFlag(True);
		ExpandTreeRows(Object.ExportRuleTable, Items.ExportRuleTable, "Enable");
		
	EndIf;
	
EndProcedure

&AtClient
Procedure ExpandTreeRows(DataTree, PresentationOnForm, CheckBoxName)
	
	TreeRows = DataTree.GetItems();
	
	For Each Row In TreeRows Do
		
		RowID=Row.GetID();
		PresentationOnForm.Expand(RowID, False);
		EnableParentIfSubordinateItemsEnabled(Row, CheckBoxName);
		
	EndDo;
	
EndProcedure

&AtClient
Procedure EnableParentIfSubordinateItemsEnabled(TreeRow, CheckBoxName)
	
	Enable = TreeRow[CheckBoxName];
	
	For Each SubordinateRow In TreeRow.GetItems() Do
		
		If SubordinateRow[CheckBoxName] = 1 Then
			
			Enable = 1;
			
		EndIf;
		
		If SubordinateRow.GetItems().Count() > 0 Then
			
			EnableParentIfSubordinateItemsEnabled(SubordinateRow, CheckBoxName);
			
		EndIf;
		
	EndDo;
	
	TreeRow[CheckBoxName] = Enable;
	
EndProcedure

&AtClient
Procedure OnPeriodChange()
	
	Object.StartDate = ExportPeriod.StartDate;
	Object.EndDate = ExportPeriod.EndDate;
	
EndProcedure

&AtServer
Procedure ImportExchangeRulesAndParametersAtServer(RuleFileAddressInStorage, FileNameForExtension)
	
	ExchangeRulesFileName = FileNameAtServerOrClient(RulesFileName ,RuleFileAddressInStorage, FileNameForExtension);
	
	If ExchangeRulesFileName = Undefined Then
		
		Return;
		
	Else
		
		Object.ExchangeRuleFileName = ExchangeRulesFileName;
		
	EndIf;
	
	ObjectForServer = FormAttributeToValue("Object");
	ObjectForServer.ExportRuleTable = FormAttributeToValue("Object.ExportRuleTable");
	ObjectForServer.ParameterSetupTable = FormAttributeToValue("Object.ParameterSetupTable");
	
	ObjectForServer.ImportExchangeRules();
	ObjectForServer.InitializeInitialParameterValues();
	ObjectForServer.Parameters.Clear();
	Object.ErrorFlag = ObjectForServer.ErrorFlag;
	
	If IsClient Then
		
		DeleteFiles(Object.ExchangeRuleFileName);
		
	EndIf;
	
	ValueToFormAttribute(ObjectForServer.ExportRuleTable, "Object.ExportRuleTable");
	ValueToFormAttribute(ObjectForServer.ParameterSetupTable, "Object.ParameterSetupTable");
	
EndProcedure

// Opens file selection dialog.
//
&AtClient
Procedure SelectFile(Item, StorageObject, PropertyName, CheckForExistence, Val DefaultExtension = "xml",
	ArchiveDataFile = True, RuleFileSelection = False)
	
	FileSelectionDialog = New FileDialog(FileDialogMode.Open);

	If DefaultExtension = "txt" Then
		
		FileSelectionDialog.Filter = "File protocol exchange (*.txt)|*.txt";
		FileSelectionDialog.DefaultExt = "txt";
		
	ElsIf Object.ExchangeMode = "DataExported" Then
		
		If ArchiveDataFile Then
			
			FileSelectionDialog.Filter = "Archived file data (*.zip)|*.zip";
			FileSelectionDialog.DefaultExt = "zip";
			
		ElsIf RuleFileSelection Then
			
			FileSelectionDialog.Filter = "File data (*.xml)|*.xml|Archived file data (*.zip)|*.zip";
			FileSelectionDialog.DefaultExt = "xml";
			
		Else
			
			FileSelectionDialog.Filter = "File data (*.xml)|*.xml";
			FileSelectionDialog.DefaultExt = "xml";
			
		EndIf; 
		
	Else
		If RuleFileSelection Then
			FileSelectionDialog.Filter = "File data (*.xml)|*.xml";
			FileSelectionDialog.DefaultExt = "xml";
		Else
			FileSelectionDialog.Filter = "File data (*.xml)|*.xml|Archived file data (*.zip)|*.zip";
			FileSelectionDialog.DefaultExt = "xml";
		EndIf;
	EndIf;
	
	FileSelectionDialog.Title = NStr("ru = 'Выберите файл'; en = 'Select file'; pl = 'Wybierz plik';de = 'Datei auswählen';ro = 'Selectați fișierul';tr = 'Dosya seç'; es_ES = 'Seleccionar un archivo'");
	FileSelectionDialog.Preview = False;
	FileSelectionDialog.FilterIndex = 0;
	FileSelectionDialog.FullFileName = Item.EditText;
	FileSelectionDialog.CheckFileExist = CheckForExistence;
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("StorageObject", StorageObject);
	AdditionalParameters.Insert("PropertyName",    PropertyName);
	AdditionalParameters.Insert("Item",        Item);
	
	Notification = New NotifyDescription("FileSelectionDialogChoiceProcessing", ThisObject, AdditionalParameters);
	FileSelectionDialog.Show(Notification);
	
EndProcedure

&AtClient
Procedure FileSelectionDialogChoiceProcessing(SelectedFiles, AdditionalParameters) Export
	
	If SelectedFiles = Undefined Then
		Return;
	EndIf;
	
	AdditionalParameters.StorageObject[AdditionalParameters.PropertyName] = SelectedFiles[0];
	
	Item = AdditionalParameters.Item;
	
	If Item = Items.RulesFileName Then
		RuleFileNameOnChange(Item);
	ElsIf Item = Items.ExchangeFileName Then
		ExchangeFileNameOnChange(Item);
	ElsIf Item = Items.DataFileName Then
		DataFileNameOnChange(Item);
	ElsIf Item = Items.NameOfImportRulesFile Then
		NameOfImportRulesFileOnChange(Item);
	EndIf;
	
EndProcedure

&AtServer
Procedure EstablishConnectionWithDestinationIBAtServer()
	
	ObjectForServer = FormAttributeToValue("Object");
	FillPropertyValues(ObjectForServer, Object);
	ConnectionResult = ObjectForServer.EstablishConnectionWithDestinationIB();
	
	If ConnectionResult <> Undefined Then
		
		MessageToUser(NStr("ru = 'Подключение успешно установлено.'; en = 'Connection established.'; pl = 'Połączenie zostało pomyślnie ustanowione.';de = 'Die Verbindung wurde erfolgreich hergestellt.';ro = 'Conexiunea a fost stabilită cu succes.';tr = 'Bağlantı başarıyla yapıldı.'; es_ES = 'Conexión se ha establecido con éxito.'"));
		
	EndIf;
	
EndProcedure

// Sets mark value in subordinate tree rows according to the mark value in the current row.
// 
//
// Parameters:
//  CurRow      - a value tree row.
// 
&AtClient
Procedure SetSubordinateItemsMarks(curRow, CheckBoxName)
	
	SubordinateElements = curRow.GetItems();
	
	If SubordinateElements.Count() = 0 Then
		Return;
	EndIf;
	
	For Each Row In SubordinateElements Do
		
		Row[CheckBoxName] = curRow[CheckBoxName];
		
		SetSubordinateItemsMarks(Row, CheckBoxName);
		
	EndDo;
		
EndProcedure

// Sets mark values in parent tree rows according to the mark value in the current row.
// 
//
// Parameters:
//  CurRow      - a value tree row.
// 
&AtClient
Procedure SetParentMarks(curRow, CheckBoxName)
	
	Parent = curRow.GetParent();
	If Parent = Undefined Then
		Return;
	EndIf; 
	
	CurState = Parent[CheckBoxName];
	
	EnabledItemsFound  = False;
	DisabledItemsFound = False;
	
	For Each Row In Parent.GetItems() Do
		If Row[CheckBoxName] = 0 Then
			DisabledItemsFound = True;
		ElsIf Row[CheckBoxName] = 1
			OR Row[CheckBoxName] = 2 Then
			EnabledItemsFound  = True;
		EndIf; 
		If EnabledItemsFound AND DisabledItemsFound Then
			Break;
		EndIf; 
	EndDo;
	
	If EnabledItemsFound AND DisabledItemsFound Then
		Enable = 2;
	ElsIf EnabledItemsFound AND (Not DisabledItemsFound) Then
		Enable = 1;
	ElsIf (Not EnabledItemsFound) AND DisabledItemsFound Then
		Enable = 0;
	ElsIf (Not EnabledItemsFound) AND (Not DisabledItemsFound) Then
		Enable = 2;
	EndIf;
	
	If Enable = CurState Then
		Return;
	Else
		Parent[CheckBoxName] = Enable;
		SetParentMarks(Parent, CheckBoxName);
	EndIf; 
	
EndProcedure

&AtServer
Procedure OpenImportFileAtServer(FileAddress)
	
	If IsClient Then
		
		BinaryData = GetFromTempStorage (FileAddress);
		AddressOnServer = GetTempFileName(".xml");
		// Temporary file is deleted not via DeleteFiles(AddressOnServer), but via
		// DeleteFiles(Object.ExchangeFileName) below.
		BinaryData.Write(AddressOnServer);
		Object.ExchangeFileName = AddressOnServer;
		
	Else
		
		FileOnServer = New File(ExchangeFileName);
		
		If Not FileOnServer.Exist() Then
			
			MessageToUser(NStr("ru = 'Не найден файл обмена на сервере.'; en = 'Exchange file not found on the server.'; pl = 'Plik wymiany nie został znaleziony na serwerze.';de = 'Austausch-Datei wurde nicht auf dem Server gefunden.';ro = 'Fișierul schimbului nu a fost găsit pe server.';tr = 'Alışveriş dosyası sunucuda bulunamadı.'; es_ES = 'Archivo de intercambio no encontrado en el servidor.'"), "ExchangeFileName");
			Return;
			
		EndIf;
		
		Object.ExchangeFileName = ExchangeFileName;
		
	EndIf;
	
	ObjectForServer = FormAttributeToValue("Object");
	
	ObjectForServer.OpenImportFile(True);
	
	Object.StartDate = ObjectForServer.StartDate;
	Object.EndDate = ObjectForServer.EndDate;
	Object.DataExportDate = ObjectForServer.DataExportDate;
	Object.ExchangeRulesVersion = ObjectForServer.ExchangeRulesVersion;
	Object.Comment = ObjectForServer.Comment;
	
EndProcedure

// Deletes marked metadata tree rows.
//
&AtServer
Procedure DeleteAtServer()
	
	ObjectForServer = FormAttributeToValue("Object");
	DataBeingDeletedTree = FormAttributeToValue("DataToDelete");
	
	ObjectForServer.InitManagersAndMessages();
	
	For Each TreeRow In DataBeingDeletedTree.Rows Do
		
		For Each MDRow In TreeRow.Rows Do
			
			If Not MDRow.Check Then
				Continue;
			EndIf;
			
			TypeString = MDRow.Metadata;
			ObjectForServer.DeleteObjectsOfType(TypeString);
			
		EndDo;
		
	EndDo;
	
EndProcedure

// Sets an exchange node at tree rows.
//
&AtServer
Procedure FillExchangeNodeInTreeRowsAtServer(ExchangeNode)
	
	FillExchangeNodeInTreeRows(Object.ExportRuleTable.GetItems(), ExchangeNode);
	
EndProcedure

// Saves parameter values.
//
&AtServer
Procedure SaveParametersAtServer()
	
	ParametersTable = FormAttributeToValue("Object.ParameterSetupTable");
	
	ParametersToSave = New Map;
	
	For Each TableRow In ParametersTable Do
		ParametersToSave.Insert(TableRow.Description, TableRow.Value);
	EndDo;
	
	SystemSettingsStorage.Save("UniversalDataExchangeXML", "Parameters", ParametersToSave);
	
EndProcedure

// Restores parameter values
//
&AtServer
Procedure RestoreParametersAtServer()
	
	ParametersTable = FormAttributeToValue("Object.ParameterSetupTable");
	RestoredParameters = SystemSettingsStorage.Load("UniversalDataExchangeXML", "Parameters");
	
	If TypeOf(RestoredParameters) <> Type("Map") Then
		Return;
	EndIf;
	
	If RestoredParameters.Count() = 0 Then
		Return;
	EndIf;
	
	For Each Param In RestoredParameters Do
		
		ParameterName = Param.Key;
		
		TableRow = ParametersTable.Find(Param.Key, "Description");
		
		If TableRow <> Undefined Then
			
			TableRow.Value = Param.Value;
			
		EndIf;
		
	EndDo;
	
	ValueToFormAttribute(ParametersTable, "Object.ParameterSetupTable");
	
EndProcedure

// Performs interactive data export.
//
&AtClient
Procedure ExecuteImportFromForm()
	
	FileAddress = "";
	FileNameForExtension = "";
	
	AddRowToChoiceList(Items.ExchangeFileName.ChoiceList, ExchangeFileName, DataImportFromFile);
	
	If IsClient Then
		
		NotifyDescription = New NotifyDescription("ExecuteImportFromFormCompletion", ThisObject);
		BeginPutFile(NotifyDescription, FileAddress,NStr("ru = 'Файл обмена'; en = 'Exchange file'; pl = 'Plik wymiany';de = 'Datei austauschen';ro = 'Schimbați fișierul';tr = 'Alışveriş dosyası'; es_ES = 'Archivo de intercambio'"),, UUID);
		
	Else
		
		If EmptyAttributeValue(ExchangeFileName, "ExchangeFileName", Items.ExchangeFileName.Title) Then
			Return;
		EndIf;
		
		ExecuteImportFromFormCompletion(True, FileAddress, FileNameForExtension, Undefined);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure ExecuteImportFromFormCompletion(Result, Address, SelectedFileName, AdditionalParameters) Export
	
	If Result Then
		
		ExecuteImportAtServer(Address, SelectedFileName);
		
		OpenExchangeProtocolDataIfNecessary();
		
	EndIf;
	
EndProcedure

&AtServer
Procedure ExecuteImportAtServer(FileAddress, FileNameForExtension)
	
	FileToImportName = FileNameAtServerOrClient(ExchangeFileName ,FileAddress, FileNameForExtension);
	
	If FileToImportName = Undefined Then
		
		Return;
		
	Else
		
		Object.ExchangeFileName = FileToImportName;
		
	EndIf;
	
	If Object.SafeImport Then
		If IsTempStorageURL(ImportRulesFileAddressInStorage) Then
			BinaryData = GetFromTempStorage(ImportRulesFileAddressInStorage);
			AddressOnServer = GetTempFileName("xml");
			// Temporary file is deleted not via DeleteFiles(AddressOnServer), but via
			// DeleteFiles(Object.ExchangeRuleFileName) below.
			BinaryData.Write(AddressOnServer);
			Object.ExchangeRuleFileName = AddressOnServer;
		Else
			MessageToUser(NStr("ru = 'Не указан файл правил для загрузки данных.'; en = 'File of data import rules is not specified.'; pl = 'Nie wskazano pliku reguł do pobierania danych.';de = 'Es ist keine Regeldatei für das Herunterladen von Daten angegeben.';ro = 'Fișierul regulilor pentru importul de date nu a fost găsit.';tr = 'Verileri içe aktarma kuralları dosyası belirtilmedi.'; es_ES = 'No se ha indicado un archivo de reglas para cargar los datos.'"));
			Return;
		EndIf;
	EndIf;
	
	ObjectForServer = FormAttributeToValue("Object");
	FillPropertyValues(ObjectForServer, Object);
	ObjectForServer.ExecuteImport();
	
	Try
		
		If Not IsBlankString(FileAddress) Then
			DeleteFiles(FileToImportName);
		EndIf;
		
	Except
		WriteLogEvent(NStr("ru = 'Универсальный обмен данными в формате XML'; en = 'Universal data exchange in XML format'; pl = 'Uniwersalna wymiana danymi w formacie XML';de = 'Universeller Datenaustausch im XML-Format';ro = 'Schimbul universal de date în format XML';tr = 'XML formatında üniversal veri değişimi'; es_ES = 'Intercambio de datos universal en el formato XML'", ObjectForServer.DefaultLanguageCode()),
			EventLogLevel.Error,,, DetailErrorDescription(ErrorInfo()));
	EndTry;
	
	ObjectForServer.Parameters.Clear();
	ValueToFormAttribute(ObjectForServer, "Object");
	
	RulesAreImported = False;
	Items.FormExecuteExport.Enabled = False;
	Items.ExportNoteLabel.Visible = True;
	Items.ExportDebugAvailableGroup.Enabled = False;
	
EndProcedure

&AtServer
Function FileNameAtServerOrClient(AttributeName ,Val FileAddress, Val FileNameForExtension = ".xml",
	CreateNew = False, CheckForExistence = True)
	
	FileName = Undefined;
	
	If IsClient Then
		
		If CreateNew Then
			
			Extension = ? (Object.ArchiveFile, ".zip", ".xml");
			
			FileName = GetTempFileName(Extension);
			
		Else
			
			Extension = FileExtention(FileNameForExtension);
			BinaryData = GetFromTempStorage(FileAddress);
			AddressOnServer = GetTempFileName(Extension);
			// The temporary file is deleted not via the DeleteFiles(AddressOnServer), but via 
			// DeleteFiles(Object.ExchangeRulesFileName) and DeleteFiles(Object.ExchangeFileName) below.
			BinaryData.Write(AddressOnServer);
			FileName = AddressOnServer;
			
		EndIf;
		
	Else
		
		FileOnServer = New File(AttributeName);
		
		If Not FileOnServer.Exist() AND CheckForExistence Then
			
			MessageToUser(NStr("ru = 'Указанный файл не существует.'; en = 'The file does not exist.'; pl = 'Podany plik nie istnieje.';de = 'Die angegebene Datei existiert nicht.';ro = 'Fișierul specificat nu există.';tr = 'Belirtilen dosya mevcut değil.'; es_ES = 'El archivo especificado no existe.'"));
			
		Else
			
			FileName = AttributeName;
			
		EndIf;
		
	EndIf;
	
	Return FileName;
	
EndFunction

&AtServer
Function FileExtention(Val FileName)
	
	PointPosition = LastSeparator(FileName);
	
	Extension = Right(FileName,StrLen(FileName) - PointPosition + 1);
	
	Return Extension;
	
EndFunction

&AtServer
Function LastSeparator(StringWithSeparator, Separator = ".")
	
	StringLength = StrLen(StringWithSeparator);
	
	While StringLength > 0 Do
		
		If Mid(StringWithSeparator, StringLength, 1) = Separator Then
			
			Return StringLength; 
			
		EndIf;
		
		StringLength = StringLength - 1;
		
	EndDo;

EndFunction

&AtClient
Procedure ExecuteExportFromForm()
	
	// Adding rule file name and data file name to the selection list.
	AddRowToChoiceList(Items.RulesFileName.ChoiceList, RulesFileName, ExchangeRules);
	
	If Not Object.DirectReadingInDestinationIB AND Not IsClient Then
		
		If RuleAndExchangeFileNamesMatch() Then
			Return;
		EndIf;
		
		AddRowToChoiceList(Items.DataFileName.ChoiceList, DataFileName, DataExportToFile);
		
	EndIf;
	
	DataFileAddressInStorage = ExecuteExportAtServer();
	
	If DataFileAddressInStorage = Undefined Then
		Return;
	EndIf;
	
	ExpandTreeRows(Object.ExportRuleTable, Items.ExportRuleTable, "Enable");
	
	If IsClient AND Not DirectExport AND Not Object.ErrorFlag Then
		
		FileToSaveName = ?(Object.ArchiveFile, NStr("ru = 'Файл выгрузки.zip'; en = 'Export file.zip'; pl = 'Eksportowany plik.zip';de = 'Datei.zip exportieren';ro = 'Export fișiere.zip';tr = 'Dışa aktarma dosyası.zip'; es_ES = 'Exportar el archivo.zip'"),NStr("ru = 'Файл выгрузки.xml'; en = 'Export file.xml'; pl = 'Eksportowany plik.xml';de = 'Datei.xml exportieren';ro = 'Export fișiere.xml';tr = 'Dışa aktarma dosyası.xml '; es_ES = 'Exportar el archivo.xml'"));
		
		GetFile(DataFileAddressInStorage, FileToSaveName)
		
	EndIf;
	
	OpenExchangeProtocolDataIfNecessary();
	
EndProcedure

&AtServer
Function ExecuteExportAtServer()
	
	Object.ExchangeRuleFileName = FileNameAtServerOrClient(RulesFileName, RuleFileAddressInStorage);
	
	If Not DirectExport Then
		
		TempDataFileName = FileNameAtServerOrClient(DataFileName, "",,True, False);
		
		If TempDataFileName = Undefined Then
			
			MessageToUser(NStr("ru = 'Не определен файл данных'; en = 'Data file not specified'; pl = 'Plik danych nie jest określony';de = 'Datendatei ist nicht angegeben';ro = 'Fișierul de date nu este specificat';tr = 'Veri dosyası belirtilmedi'; es_ES = 'Archivo de datos no está especificado'"));
			Return Undefined;
			
		Else
			
			Object.ExchangeFileName = TempDataFileName;
			
		EndIf;
		
	EndIf;
	
	ExportRulesTable = FormAttributeToValue("Object.ExportRuleTable");
	ParametersSetupTable = FormAttributeToValue("Object.ParameterSetupTable");
	
	ObjectForServer = FormAttributeToValue("Object");
	FillPropertyValues(ObjectForServer, Object);
	
	If ObjectForServer.HandlersDebugModeFlag Then
		
		Cancel = False;
		
		File = New File(ObjectForServer.EventHandlerExternalDataProcessorFileName);
		
		If Not File.Exist() Then
			
			MessageToUser(NStr("ru = 'Файл внешней обработки отладчиков событий не существует на сервере'; en = 'Event debugger external data processor file does not exist on the server'; pl = 'Zewnętrzny plik opracowania debuggera zdarzeń nie istnieje na serwerze';de = 'Eine externe Datenprozessordatei von Ereignisdebuggern ist auf dem Server nicht vorhanden';ro = 'Fișierul procesării externe a handlerelor evenimentelor nu există pe server';tr = 'Sunucuda olay hata ayıklayıcılarının dış veri işlemci dosyası yok'; es_ES = 'Archivo del procesador de datos externo de los depuradores de eventos no existe en el servidor'"));
			Return Undefined;
			
		EndIf;
		
		ObjectForServer.ExportEventHandlers(Cancel);
		
		If Cancel Then
			
			MessageToUser(NStr("ru = 'Не удалось выгрузить обработчики событий'; en = 'Cannot export event handlers'; pl = 'Nie można wyeksportować programów do obsługi zdarzeń';de = 'Ereignis-Anwender können nicht exportiert werden';ro = 'Nu se pot exporta dispozitivele de gestionare a evenimentelor';tr = 'Etkinlik işleyicileri dışa aktarılamıyor'; es_ES = 'No se puede exportar los manipuladores de eventos'"));
			Return "";
			
		EndIf;
		
	Else
		
		ObjectForServer.ImportExchangeRules();
		ObjectForServer.InitializeInitialParameterValues();
		
	EndIf;
	
	ChangeExportRuleTree(ObjectForServer.ExportRuleTable.Rows, ExportRulesTable.Rows);
	ChangeParameterTable(ObjectForServer.ParameterSetupTable, ParametersSetupTable);
	
	ObjectForServer.ExecuteExport();
	ObjectForServer.ExportRuleTable = FormAttributeToValue("Object.ExportRuleTable");
	
	If IsClient AND Not DirectExport Then
		
		DataFileAddress = PutToTempStorage(New BinaryData(Object.ExchangeFileName), UUID);
		DeleteFiles(Object.ExchangeFileName);
		
	Else
		
		DataFileAddress = "";
		
	EndIf;
	
	If IsClient Then
		
		DeleteFiles(ObjectForServer.ExchangeRuleFileName);
		
	EndIf;
	
	ObjectForServer.Parameters.Clear();
	ValueToFormAttribute(ObjectForServer, "Object");
	
	Return DataFileAddress;
	
EndFunction

&AtClient
Procedure SetDebugCommandsEnabled();
	
	Items.ImportDebugSetup.Enabled = Object.HandlersDebugModeFlag;
	Items.ExportDebugSetup.Enabled = Object.HandlersDebugModeFlag;
	
EndProcedure

// Modifies a DER tree according to the tree specified in the form
//
&AtServer
Procedure ChangeExportRuleTree(SourceTreeRows, TreeToReplaceRows)
	
	EnableColumn = TreeToReplaceRows.UnloadColumn("Enable");
	SourceTreeRows.LoadColumn(EnableColumn, "Enable");
	NodeColumn = TreeToReplaceRows.UnloadColumn("ExchangeNodeRef");
	SourceTreeRows.LoadColumn(NodeColumn, "ExchangeNodeRef");
	
	For Each SourceTreeRow In SourceTreeRows Do
		
		RowIndex = SourceTreeRows.IndexOf(SourceTreeRow);
		TreeToChangeRow = TreeToReplaceRows.Get(RowIndex);
		
		ChangeExportRuleTree(SourceTreeRow.Rows, TreeToChangeRow.Rows);
		
	EndDo;
	
EndProcedure

// Changed parameter table according the table in the form.
//
&AtServer
Procedure ChangeParameterTable(BaseTable, FormTable)
	
	DescriptionColumn = FormTable.UnloadColumn("Description");
	BaseTable.LoadColumn(DescriptionColumn, "Description");
	ValueColumn = FormTable.UnloadColumn("Value");
	BaseTable.LoadColumn(ValueColumn, "Value");
	
EndProcedure

&AtClient
Procedure DirectExportOnValueChange()
	
	ExportParameters = Items.ExportParameters;
	
	ExportParameters.CurrentPage = ?(DirectExport = 0,
										  ExportParameters.ChildItems.ExportToFile,
										  ExportParameters.ChildItems.ExportToDestinationIB);
	
	Object.DirectReadingInDestinationIB = (DirectExport = 1);
	
	InfobaseTypeForConnectionOnValueChange();
	
EndProcedure

&AtClient
Procedure InfobaseTypeForConnectionOnValueChange()
	
	InfobaseType = Items.InfobaseType;
	InfobaseType.CurrentPage = ?(Object.InfobaseToConnectType,
								InfobaseType.ChildItems.FileInfobase,
								InfobaseType.ChildItems.ServerInfobase);
	
EndProcedure

&AtClient
Procedure AddRowToChoiceList(ValueListToSave, SavingValue, ParameterNameToSave)
	
	If IsBlankString(SavingValue) Then
		Return;
	EndIf;
	
	FoundItem = ValueListToSave.FindByValue(SavingValue);
	If FoundItem <> Undefined Then
		ValueListToSave.Delete(FoundItem);
	EndIf;
	
	ValueListToSave.Insert(0, SavingValue);
	
	While ValueListToSave.Count() > 10 Do
		ValueListToSave.Delete(ValueListToSave.Count() - 1);
	EndDo;
	
	ParameterNameToSave = ValueListToSave;
	
EndProcedure

&AtClient
Procedure OpenHandlerDebugSetupForm(EventHandlersFromRuleFile)
	
	DataProcessorName = Left(FormName, LastSeparator(FormName));
	FormNameToCall = DataProcessorName + "HandlerDebugSetupManagedForm";
	
	FormParameters = New Structure;
	FormParameters.Insert("EventHandlerExternalDataProcessorFileName", Object.EventHandlerExternalDataProcessorFileName);
	FormParameters.Insert("AlgorithmsDebugMode", Object.AlgorithmDebugMode);
	FormParameters.Insert("ExchangeRuleFileName", Object.ExchangeRuleFileName);
	FormParameters.Insert("ExchangeFileName", Object.ExchangeFileName);
	FormParameters.Insert("ReadEventHandlersFromExchangeRulesFile", EventHandlersFromRuleFile);
	FormParameters.Insert("DataProcessorName", DataProcessorName);
	
	Mode = FormWindowOpeningMode.LockOwnerWindow;
	Handler = New NotifyDescription("OpenHandlerDebugSetupFormCompletion", ThisObject, EventHandlersFromRuleFile);
	
	OpenForm(FormNameToCall, FormParameters, ThisObject,,,,Handler, Mode);
	
EndProcedure

&AtClient
Procedure OpenHandlerDebugSetupFormCompletion(DebugParameters, EventHandlersFromRuleFile) Export
	
	If DebugParameters <> Undefined Then
		
		FillPropertyValues(Object, DebugParameters);
		
		If IsClient Then
			
			If EventHandlersFromRuleFile Then
				
				FileName = Object.ExchangeRuleFileName;
				
			Else
				
				FileName = Object.ExchangeFileName;
				
			EndIf;
			
			Notification = New NotifyDescription("OpenHandlersDebugSettingsFormCompletionFileDeletion", ThisObject);
			BeginDeletingFiles(Notification, FileName);
			
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure OpenHandlersDebugSettingsFormCompletionFileDeletion(AdditionalParameters) Export
	
	Return;
	
EndProcedure

&AtClient
Procedure ChangeFileLocation()
	
	Items.RulesFileName.Visible = Not IsClient;
	Items.DataFileName.Visible = Not IsClient;
	Items.ExchangeFileName.Visible = Not IsClient;
	Items.SafeImportGroup.Visible = Not IsClient;
	
	SetImportRuleFlag(False);
	
EndProcedure

&AtClient
Procedure ChangeProcessingMode(RunMode)
	
	ModeGroup = CommandBar.ChildItems.ProcessingMode.ChildItems;
	
	ModeGroup.FormAtClient.Check = RunMode;
	ModeGroup.FormAtServer.Check = Not RunMode;
	
	CommandBar.ChildItems.ProcessingMode.Title = 
	?(RunMode, NStr("ru = 'Режим работы (на клиенте)'; en = 'Mode (client)'; pl = 'Tryb pracy (na kliencie)';de = 'Betriebsmodus (auf dem Client)';ro = 'Mod de funcționare (pe client)';tr = 'Çalışma modu (istemcide)'; es_ES = 'Modo de operación (en el cliente)'"), NStr("ru = 'Режим работы (на сервере)'; en = 'Mode (server)'; pl = 'Tryb pracy (na serwerze)';de = 'Betriebsmodus (auf dem Server)';ro = 'Mod de funcționare (pe server)';tr = 'Çalışma modu (sunucuda)'; es_ES = 'Modo de operación (en el servidor)'"));
	
	Object.ExportRuleTable.GetItems().Clear();
	Object.ParameterSetupTable.Clear();
	
	ChangeFileLocation();
	
EndProcedure

&AtClient
Procedure OpenExchangeProtocolDataIfNecessary()
	
	If NOT Object.OpenExchangeProtocolsAfterExecutingOperations Then
		Return;
	EndIf;
	
	#If Not WebClient Then
		
		If Not IsBlankString(Object.ExchangeProtocolFileName) Then
			OpenInApplication(Object.ExchangeProtocolFileName);
		EndIf;
		
		If Object.DirectReadingInDestinationIB Then
			
			Object.ImportExchangeLogFileName = GetProtocolNameForSecondCOMConnectionInfobaseAtServer();
			
			If Not IsBlankString(Object.ImportExchangeLogFileName) Then
				OpenInApplication(Object.ImportExchangeLogFileName);
			EndIf;
			
		EndIf;
		
	#EndIf
	
EndProcedure

&AtServer
Function GetProtocolNameForSecondCOMConnectionInfobaseAtServer()
	
	Return FormAttributeToValue("Object").GetProtocolNameForCOMConnectionSecondInfobase();
	
EndFunction

&AtClient
Function EmptyAttributeValue(Attribute, DataPath, Title)
	
	If IsBlankString(Attribute) Then
		
		MessageText = NStr("ru = 'Поле ""%1"" не заполнено'; en = 'Field ""%1"" is blank'; pl = 'Pole ""%1"" nie jest wypełnione';de = 'Das Feld ""%1"" ist nicht ausgefüllt';ro = 'Câmpul ""%1"" nu este completat';tr = '""%1"" alanı doldurulmadı.'; es_ES = 'El ""%1"" campo no está rellenado'");
		MessageText = StrReplace(MessageText, "%1", Title);
		
		MessageToUser(MessageText, DataPath);
		
		Return True;
		
	Else
		
		Return False;
		
	EndIf;
	
EndFunction

&AtClient
Procedure SetImportRuleFlag(Flag)
	
	RulesAreImported = Flag;
	Items.FormExecuteExport.Enabled = Flag;
	Items.ExportNoteLabel.Visible = Not Flag;
	Items.ExportDebugGroup.Enabled = Flag;
	
EndProcedure

&AtClient
Procedure OnChangeChangesRegistrationDeletionType()
	
	If IsBlankString(ChangesRegistrationDeletionTypeForExportedExchangeNodes) Then
		Object.ChangesRegistrationDeletionTypeForExportedExchangeNodes = 0;
	Else
		Object.ChangesRegistrationDeletionTypeForExportedExchangeNodes = Number(ChangesRegistrationDeletionTypeForExportedExchangeNodes);
	EndIf;
	
EndProcedure

&AtClientAtServerNoContext
Procedure MessageToUser(Text, DataPath = "")
	
	Message = New UserMessage;
	Message.Text = Text;
	Message.DataPath = DataPath;
	Message.Message();
	
EndProcedure

// Returns True if the client application is running on Windows.
//
// Returns:
//  Boolean. Returns False if the client OS is not Linux.
//
&AtClient
Function IsWindowsClient()
	
	SystemInfo = New SystemInfo;
	
	IsWindowsClient = SystemInfo.PlatformType = PlatformType.Windows_x86
	             OR SystemInfo.PlatformType = PlatformType.Windows_x86_64;
	
	Return IsWindowsClient;
	
EndFunction

&AtServer
Procedure CheckPlatformVersionAndCompatibilityMode()
	
	Information = New SystemInfo;
	If Not (Left(Information.AppVersion, 3) = "8.3"
		AND (Metadata.CompatibilityMode = Metadata.ObjectProperties.CompatibilityMode.DontUse
		Or (Metadata.CompatibilityMode <> Metadata.ObjectProperties.CompatibilityMode.Version8_1
		AND Metadata.CompatibilityMode <> Metadata.ObjectProperties.CompatibilityMode.Version8_2_13
		AND Metadata.CompatibilityMode <> Metadata.ObjectProperties.CompatibilityMode["Version8_2_16"]
		AND Metadata.CompatibilityMode <> Metadata.ObjectProperties.CompatibilityMode["Version8_3_1"]
		AND Metadata.CompatibilityMode <> Metadata.ObjectProperties.CompatibilityMode["Version8_3_2"]))) Then
		
		Raise NStr("ru = 'Обработка предназначена для запуска на версии платформы
			|1С:Предприятие 8.3 с отключенным режимом совместимости или выше'; 
			|en = 'The data processor is intended for use with 
			|1C:Enterprise 8.3 or later, with disabled compatibility mode'; 
			|pl = 'Przetwarzanie jest przeznaczona do uruchomienia na wersji platformy 
			|1C:Enterprise 8.3 z odłączonym trybem kompatybilności lub wyżej';
			|de = 'Die Verarbeitung soll auf der Plattform Version 
			|1C:Enterprise 8.3 mit deaktiviertem Kompatibilitätsmodus oder höher gestartet werden';
			|ro = 'Procesarea este destinată pentru lansare pe versiunea platformei
			|1C:Enterprise 8.3 cu regimul de compatibilitate dezactivat sau mai sus';
			|tr = 'İşlem, 
			|1C: İşletme 8.3 platform sürümü (veya üzeri) uyumluluk modu kapalı olarak başlamak için kullanılır'; 
			|es_ES = 'El procesamiento se utiliza para iniciar en la versión de la plataforma
			| 1C:Enterprise 8.3 con el modo de compatibilidad desactivado o superior'");
		
	EndIf;
	
EndProcedure

&AtClient
Procedure ChangeSafeImportMode(Interactively = True)
	
	Items.SafeImportGroup.Enabled = Object.SafeImport;
	
	ThroughStorage = IsClient;
	#If WebClient Then
		ThroughStorage = True;
	#EndIf
	
	If Object.SafeImport AND ThroughStorage Then
		PutImportRulesFileInStorage();
	EndIf;
	
EndProcedure

&AtClient
Procedure PutImportRulesFileInStorage()
	
	ThroughStorage = IsClient;
	#If WebClient Then
		ThroughStorage = True;
	#EndIf
	
	FileAddress = "";
	NotifyDescription = New NotifyDescription("PutImportRulesFileInStorageCompletion", ThisObject);
	BeginPutFile(NotifyDescription, FileAddress,
		?(ThroughStorage, NStr("ru = 'Файл обмена'; en = 'Exchange file'; pl = 'Plik wymiany';de = 'Datei austauschen';ro = 'Schimbați fișierul';tr = 'Alışveriş dosyası'; es_ES = 'Archivo de intercambio'"), NameOfImportRulesFile), ThroughStorage, UUID);
	
EndProcedure

&AtClient
Procedure PutImportRulesFileInStorageCompletion(Result, Address, SelectedFileName, AdditionalParameters) Export
	
	If Result Then
		ImportRulesFileAddressInStorage = Address;
	EndIf;
	
EndProcedure

#EndRegion
