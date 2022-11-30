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
	
	AvailableVersionsArray = New Map;
	Try
		DataExchangeOverridable.OnGetAvailableFormatVersions(AvailableVersionsArray);
	Except
		// Cannot get available format versions.
		Raise NStr("ru='В информационной базе не поддерживается синхронизация данных через универсальный формат'; en = 'The infobase does not support universal data synchronization format.'; pl = 'W informatycznej bazie danych nie jest obsługiwana synchronizacja danych poprzez uniwersalny format';de = 'Die Informationsbasis unterstützt keine Datensynchronisation durch das Universalformat';ro = 'În baza de informații nu este susținută sincronizarea datelor prin formaul universal';tr = 'Veritabanında, verileri genelel bir biçimde eşleştirme işlemi desteklenmez'; es_ES = 'En la base de información de se admite la sincronización de datos a través del formato único'");
	EndTry;

	DataProcessorObject = FormAttributeToValue("Object");
	FormOpenOption = ?(Parameters.Property("ImportOnly"), "ImportOnly", "");
	
	If FormOpenOption = "ImportOnly" Then
		ThisObject.Title = NStr("ru='Загрузка данных EnterpriseData'; en = 'Import EnterpriseData data'; pl = 'Pobieranie danych EnterpriseData';de = 'Herunterladen der Daten EnterpriseData';ro = 'Import de date EnterpriseData';tr = 'Veri içe aktarılması EnterpriseData'; es_ES = 'Carga de datos EnterpriseData'");
		Items.LabelExportWithIntegratedDataProcessor.Visible = True;
	Else
		Items.LabelExportWithIntegratedDataProcessor.Visible = False;
		ThisObject.Title = NStr("ru='Выгрузка и загрузка данных EnterpriseData'; en = 'Export and import EnterpriseData data'; pl = 'Przesyłanie i pobieranie danych EnterpriseData';de = 'Export und Import von EnterpriseData-Daten';ro = 'Export și import de date EnterpriseData';tr = 'EnterpriseData veri içe aktarımı ve dışa aktarımı'; es_ES = 'Subida y descarga de datos EnterpriseData'");
	EndIf;
	
	MetaDataProcessorName = DataProcessorObject.Metadata().Name;
	NameParts = StrSplit(FormName, ".");
	
	BaseNameForForm = "DataProcessor." + MetaDataProcessorName;
	DataProcessorName = NameParts[1];
	
	Object.ExportSource = "Filter";
	
	DataSeparationEnabled = Common.DataSeparationEnabled();
	
	If AvailableVersionsArray.Count() = 0 Then
		StringSupportedFormatVersions = NStr("ru='Не обнаружены поддерживаемые версии формата'; en = 'No supported format versions are found.'; pl = 'Nie znaleziono obsługiwane wersje formatu';de = 'Es wurden keine unterstützten Format-Versionen gefunden';ro = 'Nu au fost depistate versiunile susținute ale formatului';tr = 'Desteklenen biçim sürümleri bulunamadı'; es_ES = 'No se han encontrado las versiones admitidas del formato'");
		Items.StringSupportedFormatVersions.TextColor = New Color(255,0,0);
		Items.FormExecuteOperation.Enabled = False;
	Else
		StringSupportedFormatVersions = NStr("ru='Поддерживаемые версии формата:'; en = 'Supported format versions:'; pl = 'Obsługiwane wersje formatu:';de = 'Unterstützte Format-Versionen:';ro = 'Versiunile susținute ale formatului:';tr = 'Desteklenen biçim sürümleri:'; es_ES = 'Versiones admitidas del formato:'");
		For Each ArrayElement In AvailableVersionsArray Do
			StringSupportedFormatVersions = StringSupportedFormatVersions + ArrayElement.Key + ", ";
			Items.FormatVersion.ChoiceList.Add(ArrayElement.Key);
		EndDo;
		StringSupportedFormatVersions = Left(StringSupportedFormatVersions, StrLen(StringSupportedFormatVersions)-2);
		Items.StringSupportedFormatVersions.TextColor = New Color(0,0,0);
		Object.FormatVersion = Items.FormatVersion.ChoiceList[AvailableVersionsArray.Count()-1].Value;
		RefreshExportRulesAtServer();
	EndIf;
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	If FormOpenOption = "ImportOnly" Then
		OperationKind = "Load";
		DeveloperMode = False;
	EndIf;
	
	If Not ValueIsFilled(OperationKind) Then
		OperationKind = "Load";
	EndIf;
	// value saved by default appears only when the form is opened.
	If ValueIsFilled(Object.PathToExportExchangeManager) Then
		RefreshExportRulesAtServer();
	EndIf;
	SetVisibility();
	#If WebClient Then
	// Checking file system extension as a precaution.
	BeginInstallFileSystemExtension();
	#EndIf
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure OperationKindOnChange(Item)
	SetVisibility();
EndProcedure

&AtClient
Procedure FormatVersionOnChange(Item)
	If NOT ValueIsFilled(Object.FormatVersion) Then
		Return;
	EndIf;
	
	RefreshExportRulesAtServer();
EndProcedure

&AtClient
Procedure PathToExportExchangeManagerStartChoice(Item, ChoiceData, StandardProcessing)
	ManagerModuleStartChoice("PathToExportExchangeManager", StandardProcessing, True);
EndProcedure

&AtClient
Procedure PathToImportExchangeManagerStartChoice(Item, ChoiceData, StandardProcessing)
	ManagerModuleStartChoice("PathToImportExchangeManager", StandardProcessing, False);
EndProcedure

&AtClient
Procedure PathToExportExchangeManagerOnChange(Item)
	ExportExchangeManagerPathOnChangeAtServer();
EndProcedure

&AtClient
Procedure ExportRulesTableChoice(Item, RowSelected, Field, StandardProcessing)
	StandardProcessing = False;
	CurrentData = Items.ExportRuleTable.CurrentData;
	If CurrentData.FullMetadataName = "" Then
		Return;
	EndIf;
	StructureFilter = New Structure("FullMetadataName", CurrentData.FullMetadataName);
	AddRegistrationRows = Object.AdditionalRegistration.FindRows(StructureFilter);
	CurrPeriodChoice = Undefined;
	CurrDataPeriod = Undefined;
	CurrFilter = Undefined;
	
	If AddRegistrationRows.Count() > 0 Then
		CurrPeriodChoice = AddRegistrationRows[0].SelectPeriod;
		CurrDataPeriod = AddRegistrationRows[0].Period;
		CurrFilter = AddRegistrationRows[0].Filter;
	EndIf;
	
	NameOfFormToOpen = BaseNameForForm + ".Form.PeriodAndFilterEdit";
	FormParameters = New Structure;
	FormParameters.Insert("Title",           CurrentData.Presentation);
	FormParameters.Insert("SelectPeriod",        CurrPeriodChoice);
	FormParameters.Insert("SettingsComposer", SettingsComposerByTableName(
									CurrentData.FullMetadataName, CurrentData.Presentation, CurrFilter));
	FormParameters.Insert("DataPeriod",        CurrDataPeriod);
	
	FormParameters.Insert("FromStorageAddress", UUID);
	
	OpenForm(NameOfFormToOpen, FormParameters, Items.ExportRuleTable);
EndProcedure

&AtClient
Procedure ExportRulesTableChoiceProcessing(Item, ValueSelected, StandardProcessing)
	StandardProcessing = False;
	
	FullMDName = Items.ExportRuleTable.CurrentData.FullMetadataName;
	CurrentRowID = Items.ExportRuleTable.CurrentData.GetID();
	FilterStringEditingAdditionalCompositionServer(ValueSelected, FullMDName, CurrentRowID);
EndProcedure

&AtClient
Procedure PathToImportFileStartChoice(Item, ChoiceData, StandardProcessing)
	SelectFileForImportAtClient();
EndProcedure

&AtClient
Procedure PathToExportFileStartChoice(Item, ChoiceData, StandardProcessing)
	SelectFileForExportAtClient();
EndProcedure

&AtClient
Procedure ImportSourceOnChange(Item)
	SetVisibility();
EndProcedure

&AtClient
Procedure ExportPlaceOnChange(Item)
	SetVisibility();
EndProcedure

&AtClient
Procedure ExportSourceOnChange(Item)
	SetVisibility();
EndProcedure

#EndRegion

#Region FormCommandHandlers

&AtClient
Procedure ExecuteOperation(Command)
	JobID = Undefined;
	
	If OperationKind = "Load" Then
		AttachIdleHandler("ImportMessage", 0.1, True);
	Else
		AttachIdleHandler("ExportData", 0.1, True);
	EndIf;
EndProcedure

&AtClient
Procedure AbortExportImport(Command)
	If JobID = Undefined Then
		Return;
	EndIf;
	AbortImportExportServer();
	JobID = Undefined;
	Items.ExportImport.CurrentPage = ?(OperationKind = "Load", Items.Load, Items.DataExported);
	SetVisibilityOfButtonsEnabledStates(True);
	Message = New UserMessage();
	Message.Text = NStr("ru = 'Выполнение операции прервано.'; en = 'The operation is canceled.'; pl = 'Wykonanie operacji przerwane.';de = 'Der Vorgang wird abgebrochen.';ro = 'Operație întreruptă.';tr = 'Işlem durduruldu.'; es_ES = 'La ejecución de operación se ha interrumpido.'");
	Message.Message();

EndProcedure


&AtClient
Procedure SaveXML(Command)
	FileAddressInStorage = SaveXMLAtServer();
	If ValueIsFilled(ExportFilePath) Then
		WriteExportResultToFile(FileAddressInStorage);
	Else
		SelectFileForExportAtClient(True, FileAddressInStorage);
	EndIf;
EndProcedure

&AtClient
Procedure OpenXML(Command)
	FileAddress = "";
	
	AddtnlParameters = New Structure("FileKind", "DataFile");
	NotifyDescription = New NotifyDescription("PutFileInStorageComplete", ThisObject, AddtnlParameters);
	FilesToPut = New Array;
	Interactively = True;
	If ValueIsFilled(PathToImportFile) Then
		FileDetails = New TransferableFileDescription(PathToImportFile,FileAddress);
		FilesToPut.Add(FileDetails);
		Interactively = False;
	EndIf;
	BeginPuttingFiles(NotifyDescription, FilesToPut,,Interactively, UUID);
EndProcedure

&AtClient
Procedure SaveSettings(Command)
	FileAddressInStorage = SaveExportSettingsAtServer();
	GetFile(FileAddressInStorage, NStr("ru = 'Файл настроек.xml'; en = 'Settings file.xml'; pl = 'Plik ustawień.xml';de = 'Einstellungsdatei.xml';ro = 'Fișierul setărilor.xml';tr = 'Ayarlar dosyası.xml'; es_ES = 'Archivo de ajustes.xml'"));
EndProcedure

&AtClient
Procedure RestoreSettings(Command)
	FileAddress = "";
	AddtnlParameters = New Structure("FileKind", "SettingsFile");
		NotifyDescription = New NotifyDescription("PutFileInStorageComplete", ThisObject, AddtnlParameters);
	FilesToPut = New Array;
	FileDetails = New TransferableFileDescription(,FileAddress);
	FilesToPut.Add(FileDetails);
	BeginPuttingFiles(NotifyDescription, FilesToPut,,True, UUID);
EndProcedure

&AtClient
Procedure EnableDeveloperMode(Command)
	
	DeveloperMode = Not DeveloperMode;
	ImportSource = ?(DeveloperMode, ImportSource, 0);
	ExportLocation = ?(DeveloperMode, ExportLocation, 0);
	ExportSource = ?(DeveloperMode, ExportSource, "Filter");
	SetVisibility();
	
EndProcedure

#EndRegion

#Region Private
&AtClient
Procedure ImportMessage()
	Items.TimeConsumingOperationNoteTextDecoration.Title = NStr("ru='Выполняется загрузка данных...'; en = 'Importing data...'; pl = 'Import danych...';de = 'Daten importieren...';ro = 'Are loc importul de date...';tr = 'Veriler içe aktarılıyor...'; es_ES = 'Importando los datos...'");
	Items.ExportImport.CurrentPage = Items.Wait;
	SetVisibilityOfButtonsEnabledStates(False);
	If ImportSource = 1 Then
		If NOT ValueIsFilled(DataForXDTOImport) Then
			CommonClient.MessageToUser(NStr("ru='Текстовое поле с данными для загрузки не заполнено.'; en = 'Please specify the data to import.'; pl = 'Pole tekstowe z danymi do pobrania nie wypełnione.';de = 'Das Download-Textfeld ist nicht ausgefüllt.';ro = 'Caseta de text cu datele pentru import nu este completată.';tr = 'Veri yükleme metin kutusu doldurulmadı.'; es_ES = 'El campo de texto con los datos para descarga no se ha rellenado.'"));
			Return;
		EndIf;
		StartDataImport();
	Else
		If ValueIsFilled(PathToImportFile) Then
			ImportFromFileAtClient();
		Else
			// Import will start automatically after choice.
			SelectFileForImportAtClient(True);
		EndIf;
	EndIf;
EndProcedure

&AtClient
Procedure StartDataImport()
	MessagesArray = Undefined;
	TimeConsumingOperation = ImportDataAtServer();
	JobID = TimeConsumingOperation.JobID;
	If TimeConsumingOperation.Status = "Completed" Then
		TimeConsumingOperation.Property("Messages", MessagesArray);
		ReportOperationEnd(True);
	Else
		ModuleTimeConsumingOperationsClient = CommonClient.CommonModule("TimeConsumingOperationsClient");
		IdleParameters = ModuleTimeConsumingOperationsClient.IdleParameters(ThisObject);
		IdleParameters.OutputIdleWindow = False;
		
		NotifyDescription = New NotifyDescription("OnCompleteImport", ThisObject);
		ModuleTimeConsumingOperationsClient.WaitForCompletion(TimeConsumingOperation, NotifyDescription, IdleParameters);
	EndIf;

EndProcedure

&AtClient
Procedure OnCompleteImport(Result, AdditionalParameters) Export
	If Result = Undefined Then
		Raise NStr("ru='Загрузка данных завершена неудачно.'; en = 'Cannot import data.'; pl = 'Pobieranie danych zakończone niepowodzeniem.';de = 'Download der Daten fehlgeschlagen.';ro = 'Eșec la importul de date.';tr = 'Veri alımı tamamlanamadı.'; es_ES = 'La descarga de datos se ha terminado sin éxito.'");
	ElsIf Result.Status = "Error" Then
		Raise Result.BriefErrorPresentation;
	EndIf;
	ReportOperationEnd(True);
EndProcedure

&AtClient
Procedure ExportData()
	Items.TimeConsumingOperationNoteTextDecoration.Title = NStr("ru = 'Выполняется выгрузка данных...'; en = 'Exporting data...'; pl = 'Eksportowanie danych...';de = 'Daten exportieren...';ro = 'Se exportă date ...';tr = 'Veri dışa aktarılıyor...'; es_ES = 'Exportando los datos...'");
	Items.ExportImport.CurrentPage = Items.Wait;
	SetVisibilityOfButtonsEnabledStates(False);
	MessagesArray = Undefined;
	TimeConsumingOperation = ExportDataAtServer();
	JobID = TimeConsumingOperation.JobID;
	If TimeConsumingOperation.Status = "Completed" Then
		ResultStorageAddress = TimeConsumingOperation.ResultAddress;
		TimeConsumingOperation.Property("Messages", MessagesArray);
		ProcessExportResult();
	Else
		ModuleTimeConsumingOperationsClient = CommonClient.CommonModule("TimeConsumingOperationsClient");
		IdleParameters = ModuleTimeConsumingOperationsClient.IdleParameters(ThisObject);
		IdleParameters.OutputIdleWindow = False;
		
		NotifyDescription = New NotifyDescription("OnCompleteExport", ThisObject);
		ModuleTimeConsumingOperationsClient.WaitForCompletion(TimeConsumingOperation, NotifyDescription, IdleParameters);
	EndIf;
EndProcedure

&AtClient
Procedure OnCompleteExport(Result, AdditionalParameters) Export
	If Result = Undefined Then
		Raise NStr("ru='Выгрузка данных завершена неудачно. Отсутствует результат выгрузки.'; en = 'Cannot export data. The export result is missing.'; pl = 'Przesyłanie danych zakończone niepowodzeniem. Brak wyniku przesyłania.';de = 'Der Daten-Upload wurde nicht erfolgreich abgeschlossen. Kein Ergebnis beim Hochladen.';ro = 'Export eșuat. Lipsește rezultatul.';tr = 'Dışa aktarım başarısız oldu. Dışa aktarım sonucu yok.'; es_ES = 'La subida de los datos se ha terminado sin éxito. No hay resultado de subida.'");
	ElsIf Result.Status = "Error" Then
		Raise Result.BriefErrorPresentation;
	EndIf;
	ResultStorageAddress = Result.ResultAddress;
	ProcessExportResult();
EndProcedure

&AtClient
Procedure ProcessExportResult()
	If ExportLocation = 1 Then
		Object.XDTOExportResult = GetFromTempStorage(ResultStorageAddress);
		ReportOperationEnd(False);
	Else
		If NOT ValueIsFilled(ExportFilePath) Then
			// After choosing the file, the export result will be recorded there.
			SelectFileForExportAtClient(True, ResultStorageAddress);
		Else
			WriteExportResultToFile(ResultStorageAddress);
		EndIf;
	EndIf;
EndProcedure

&AtClient
Procedure WriteExportResultToFile(ResultStorageAddress)
	NotificationFileReceived = New NotifyDescription("ExportFileReceived", ThisObject);
	FilesToGet = New Array;
	ExportFile = New TransferableFileDescription(ExportFilePath, ResultStorageAddress);
	FilesToGet.Add(ExportFile);
	BeginGettingFiles(NotificationFileReceived,FilesToGet,,False);
EndProcedure

&AtClient
Procedure ExportFileReceived(ReceivedFiles, AdditionalParameters) Export
	If ReceivedFiles <> Undefined Then
		If NOT ValueIsFilled(ExportFilePath) Then
			ExportFilePath = ReceivedFiles[0].Name;
		EndIf;
		ReportOperationEnd(False);
		ThisObject.RefreshDataRepresentation();
	EndIf;
EndProcedure

&AtClient
Procedure SelectFileForImportAtClient(ImportAfterChoice = False)
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("ImportAfterChoice", ImportAfterChoice);
	
	Notification = New NotifyDescription("AttachFileSystemExtensionCompletion", ThisObject, AdditionalParameters);
	BeginAttachingFileSystemExtension(Notification);
	
EndProcedure

&AtClient
Procedure AttachFileSystemExtensionCompletion(Attached, AdditionalParameters) Export
	
	If Not Attached Then
		CommonClient.MessageToUser(
			NStr("ru = 'Для продолжения необходимо установить расширение работы с файлами.'; en = 'To continue, please install the file system extension.'; pl = 'Aby kontynuować, należy zainstalować rozszerzenie do pracy z plikami.';de = 'Um fortzufahren, müssen Sie die Erweiterung Arbeiten mit Dateien installieren.';ro = 'Pentru continuare trebuie să instalați extensia de lucru cu fișierele.';tr = 'Devam etmek için dosyalarla çalışma uzantısı yüklenmelidir.'; es_ES = 'Para seguir es necesario instalar la extensión del uso de archivos.'"));
		Return;
	EndIf;
	
	OpenFileDialog = New FileDialog(FileDialogMode.Open);
	OpenFileDialog.Filter = NStr("ru = 'Данные загрузки'; en = 'Data to import'; pl = 'Importuj dane';de = 'Daten importieren';ro = 'Import date';tr = 'Veri içe aktar'; es_ES = 'Importar datos'")+ "(*.xml)|*.xml";
	
	NotificationParameters = New Structure;
	NotificationParameters.Insert("ForImport", True);
	NotificationParameters.Insert("ImportAfterChoice", AdditionalParameters.ImportAfterChoice);
	
	ChoiceNotification = New NotifyDescription("FileSelected", ThisObject, NotificationParameters);
	OpenFileDialog.Show(ChoiceNotification);
	
EndProcedure

&AtClient
Procedure SelectFileForExportAtClient(ExportAfterChoice = False, ResultStorageAddress = "")
	OpenFileDialog = New FileDialog(FileDialogMode.Save);
	OpenFileDialog.Filter = NStr("ru = 'Данные выгрузки'; en = 'Data to export'; pl = 'Dane przesyłania';de = 'Daten hochladen';ro = 'Datele de export';tr = 'Dışa aktarma verileri'; es_ES = 'Datos de subir'")+ "(*.xml)|*.xml";
	ChoiceNotification = New NotifyDescription("FileSelected", ThisObject, 
		New Structure("ForImport, ExportAfterChoice, ResultStorageAddress", False, ExportAfterChoice, ResultStorageAddress));
	OpenFileDialog.Show(ChoiceNotification);
EndProcedure


&AtClient
Procedure PutFileInStorageComplete(FilesThatWerePut, AdditionalParameters) Export
	ImportFileAddress = "";
	If FilesThatWerePut <> Undefined Then
		ImportFileAddress = FilesThatWerePut[0].Location;
		If AdditionalParameters.FileKind = "DataFile" Then
			OpenXMLAtServer();
		ElsIf AdditionalParameters.FileKind = "DataFileToImport" Then
			StartDataImport();
		ElsIf AdditionalParameters.FileKind = "SettingsFile" Then
			ImportExportSettingsAtServer();
		EndIf;
	EndIf;
EndProcedure

&AtServer
Function ExportDataAtServer()
	AddFilterDataIfNecessary();
	ResultStorageAddress = "";
	DataProcessorObject = FormAttributeToValue("Object");
	ParametersStructure = New Structure;
	ParametersStructure.Insert("ExportLocation", ExportLocation);
	ParametersStructure.Insert("IsBackgroundJob", True);
	ParametersStructure.Insert("PathToExportExchangeManager", DataProcessorObject.PathToExportExchangeManager);
	ParametersStructure.Insert("FormatVersion", DataProcessorObject.FormatVersion);
	ParametersStructure.Insert("ExchangeNode", DataProcessorObject.ExchangeNode);
	ParametersStructure.Insert("AllDocumentsFilterPeriod", DataProcessorObject.AllDocumentsFilterPeriod);
	ParametersStructure.Insert("AdditionalRegistration", DataProcessorObject.AdditionalRegistration);

	JobParameters = New Structure;
	JobParameters.Insert("DataProcessorName", DataProcessorName);
	JobParameters.Insert("MethodName", "ExportToXMLResult");
	JobParameters.Insert("ExecutionParameters", ParametersStructure);
	JobParameters.Insert("IsExternalDataProcessor", False);

	MethodBeingExecuted = "TimeConsumingOperations.RunDataProcessorObjectModuleProcedure";

	ModuleTimeConsumingOperations = Common.CommonModule("TimeConsumingOperations");
	ExecutionParameters = ModuleTimeConsumingOperations.BackgroundExecutionParameters(UUID);
	ExecutionParameters.BackgroundJobDescription = NStr("ru = 'Выгрузка данных EnterpriseData'; en = 'Export EnterpriseData data'; pl = 'Przesyłanie danych EnterpriseData';de = 'Hochladen der Daten EnterpriseData';ro = 'Export de date EnterpriseData';tr = 'Veri dışa aktarılması EnterpriseData '; es_ES = 'Subida de datos EnterpriseData'");
	BackgroundJobResult = ModuleTimeConsumingOperations.ExecuteInBackground(MethodBeingExecuted, JobParameters, ExecutionParameters);
	Return BackgroundJobResult;
EndFunction

&AtServer
Function ImportDataAtServer()
	
	DataProcessorObject = FormAttributeToValue("Object");
	ParametersStructure = New Structure;
	If ImportSource = 1 Then
		ParametersStructure.Insert("XMLText", DataForXDTOImport);
	Else
		BinaryData = GetFromTempStorage(ImportFileAddress);
		AddressOnServer = GetTempFileName("xml");
		// Temporary file is deleted not using the DeleteFiles(AddressOnServer) of this function, but using 
		// DeleteFiles(AddressOnServer) in the MessageImport procedure of the processing module.
		BinaryData.Write(AddressOnServer);
		DeleteFromTempStorage(ImportFileAddress);
		ParametersStructure.Insert("AddressOnServer", AddressOnServer);
	EndIf;
	ParametersStructure.Insert("PathToImportExchangeManager", DataProcessorObject.PathToImportExchangeManager);
	ParametersStructure.Insert("FormatVersion", DataProcessorObject.FormatVersion);
	ParametersStructure.Insert("IsBackgroundJob", True);
	
	JobParameters = New Structure;
	JobParameters.Insert("DataProcessorName", DataProcessorName);
	JobParameters.Insert("MethodName", "MessageImport");
	JobParameters.Insert("ExecutionParameters", ParametersStructure);
	JobParameters.Insert("IsExternalDataProcessor", False);
	
	MethodBeingExecuted = "TimeConsumingOperations.RunDataProcessorObjectModuleProcedure";

	
	ModuleTimeConsumingOperations = Common.CommonModule("TimeConsumingOperations");
	ExecutionParameters = ModuleTimeConsumingOperations.BackgroundExecutionParameters(UUID);
	ExecutionParameters.BackgroundJobDescription = NStr("ru = 'Загрузка данных EnterpriseData'; en = 'Import EnterpriseData data'; pl = 'Pobieranie danych EnterpriseData';de = 'Herunterladen der Daten EnterpriseData';ro = 'Import de date EnterpriseData';tr = 'Veri içe aktarılması EnterpriseData'; es_ES = 'Carga de datos EnterpriseData'");
	BackgroundJobResult = ModuleTimeConsumingOperations.ExecuteInBackground(MethodBeingExecuted, JobParameters, ExecutionParameters);
	Return BackgroundJobResult;

EndFunction

&AtServer
Procedure AddFilterDataIfNecessary()
	If Object.ExportSource = "Node" Then
		TreeRows = Object.ExportRuleTable.GetItems();
		TreeRows.Clear();
		Object.AdditionalRegistration.Clear();
		Return;
	Else
		Object.ExchangeNode = Undefined;
	EndIf;
	
	For Each MetadataGroupString In Object.ExportRuleTable.GetItems() Do
		IsDocument = (MetadataGroupString.Description = "Documents");
		For Each MetadataString In MetadataGroupString.GetItems() Do
			FullMDName = MetadataString.FullMetadataName;
			AdditionStrings = Object.AdditionalRegistration.FindRows(New Structure("FullMetadataName", FullMDName));
			If MetadataString.Enable = False Then
				If AdditionStrings.Count() > 0 Then
					MetadataString.FilterPresentation = "";
					TotalRows = AdditionStrings.Count();
					For Counter = 1 To TotalRows Do
						Object.AdditionalRegistration.Delete(AdditionStrings[TotalRows-Counter]);
					EndDo;
				EndIf;
			ElsIf AdditionStrings.Count() = 0 Then
				NewString = Object.AdditionalRegistration.Add();
				FillPropertyValues(NewString, MetadataString, "FullMetadataName, Presentation");
				NewString.FilterString = NStr("ru = 'Все объекты'; en = 'All objects'; pl = 'Wszystkie obiekty';de = 'Alle Objekte';ro = 'Toate obiectele';tr = 'Tüm nesneler'; es_ES = 'Todos objetos'");
				If IsDocument Then
					NewString.SelectPeriod = True;
				EndIf;
			EndIf;
		EndDo;
	EndDo;
EndProcedure

&AtClient
Procedure ManagerModuleStartChoice(ManagerModuleAttribute, StandardProcessing, UpdateExport)
	StandardProcessing = False;
	
	OpenFileDialog = New FileDialog(FileDialogMode.Open);
	OpenFileDialog.Filter = NStr("ru = 'Менеджер обмена (*.epf)'; en = 'Exchange manager (*.epf)'; pl = 'Menedżer wymiany (*.epf)';de = 'Austausch-Manager (*.epf)';ro = 'Managerul schimbului (*.epf)';tr = 'Alışveriş yöneticisi (*.epf)'; es_ES = 'Gestor del cambio (*.epf)'") + "|*.epf" ;
	ChoiceNotification = New NotifyDescription("FileSelected", ThisObject, 
		New Structure("ManagerModule, AttributeName, UpdateExport", True, ManagerModuleAttribute, UpdateExport));
	OpenFileDialog.Show(ChoiceNotification);
EndProcedure

&AtServer
Function SaveXMLAtServer()
	TX = New TextDocument;
	TX.SetText(Object.XDTOExportResult);
	AddressOnServer = GetTempFileName("xml");
	TX.Write(AddressOnServer);
	AddressInStorage = PutToTempStorage(New BinaryData(AddressOnServer));
	DeleteFiles(AddressOnServer);
	Return AddressInStorage;
EndFunction

&AtServer
Procedure OpenXMLAtServer()
	BinaryData = GetFromTempStorage(ImportFileAddress);
	AddressOnServer = GetTempFileName("xml");
	BinaryData.Write(AddressOnServer);
	TX = New TextDocument;
	TX.Read(AddressOnServer);
	DataForXDTOImport = TX.GetText();
	DeleteFiles(AddressOnServer);
EndProcedure

&AtServer
Procedure ImportExportSettingsAtServer()
	BinaryData = GetFromTempStorage(ImportFileAddress);
	FileNameAtServer = GetTempFileName("xml");
	BinaryData.Write(FileNameAtServer);

	Object.AdditionalRegistration.Clear();
	Object.AllDocumentsFilterPeriod = New StandardPeriod;
	XMLReader = New XMLReader;
	XMLReader.OpenFile(FileNameAtServer);
	NewString = Undefined;
	While XMLReader.Read() Do
		If XMLReader.NodeType = XMLNodeType.StartElement Then
			If XMLReader.Name = "Period" Then
				While XMLReader.ReadAttribute() Do
					If XMLReader.Name = "Beg" Then
						Object.AllDocumentsFilterPeriod.StartDate = XMLValue(Type("Date"), XMLReader.Value);
					ElsIf XMLReader.Name = "End" Then
						Object.AllDocumentsFilterPeriod.EndDate = XMLValue(Type("Date"), XMLReader.Value);
					EndIf;
				EndDo;
			ElsIf XMLReader.Name = "Object" Then
				NewString = Object.AdditionalRegistration.Add();
				While XMLReader.ReadAttribute() Do
					If XMLReader.Name = "Type" Then
						NewString.FullMetadataName = XMLValue(Type("String"), XMLReader.Value);
					ElsIf XMLReader.Name = "Sel_Period" Then
						NewString.SelectPeriod = XMLValue(Type("Boolean"), XMLReader.Value);
					ElsIf XMLReader.Name = "Beg_Period" Then
						NewString.Period.StartDate = XMLValue(Type("Date"), XMLReader.Value); 
					ElsIf XMLReader.Name = "End_Period" Then
						NewString.Period.EndDate = XMLValue(Type("Date"), XMLReader.Value);
					ElsIf XMLReader.Name = "F_String" Then
						NewString.FilterString = XMLValue(Type("String"), XMLReader.Value);
					EndIf;
				EndDo;
				Continue;
			ElsIf XMLReader.Name = "Filter" Then
				FIlterRow = NewString.Filter.Items.Add(Type("DataCompositionFilterItem"));
				FilterValueType = Undefined;
				FilterValue = Undefined;
				While XMLReader.ReadAttribute() Do
					If XMLReader.Name = "Present" Then
						FIlterRow.Presentation = XMLValue(Type("String"), XMLReader.Value);
					ElsIf XMLReader.Name = "Comp" Then
						PageComparisonType = TrimAll(XMLValue(Type("String"), XMLReader.Value));
						If ValueIsFilled(PageComparisonType) Then
							FIlterRow.ComparisonType = DataCompositionComparisonType[PageComparisonType];
						EndIf;
					ElsIf XMLReader.Name = "Val_L" Then
						FIlterRow.LeftValue = New DataCompositionField(TrimAll(XMLValue(Type("String"), XMLReader.Value)));
					ElsIf XMLReader.Name = "Val_R" Then
						 FilterValue = XMLReader.Value;
					ElsIf XMLReader.Name = "Type_R" Then
						 FilterValueType = XMLReader.Value;
					EndIf;
				EndDo;
				If FilterValue <> Undefined Then
					FullFilterItemName = Metadata.FindByFullName(FilterValueType);
					If FullFilterItemName <> Undefined Then
										
						FilterObjectManager = Common.ObjectManagerByFullName(FilterValueType);
						
						If StrFind(Upper(FilterValueType), "ENUM") > 0 Then
							ValueRef = FilterObjectManager[FilterValue];
						Else
							ValueRef = FilterObjectManager.GetRef(New UUID(FilterValue));
						EndIf;
						
						FIlterRow.RightValue = ValueRef;
						
					Else
						FIlterRow.RightValue = XMLValue(Type(FilterValueType),FilterValue);
					EndIf;
				EndIf;
			EndIf;
		EndIf;
	EndDo;
	XMLReader.Close();
	DeleteFiles(FileNameAtServer);
	RefreshExportRulesAtServer();
EndProcedure

&AtServer
Function SaveExportSettingsAtServer()
	AddFilterDataIfNecessary();
	TempFileName = GetTempFileName("xml");

	XMLWriter = New XMLWriter;
	XMLWriter.OpenFile(TempFileName);
	XMLWriter.WriteXMLDeclaration();
	XMLWriter.WriteStartElement("Objects");
	If ValueIsFilled(Object.AllDocumentsFilterPeriod) Then
		XMLWriter.WriteStartElement("Period");
		XMLWriter.WriteAttribute("Beg", XMLString(Object.AllDocumentsFilterPeriod.StartDate));
		XMLWriter.WriteAttribute("End", XMLString(Object.AllDocumentsFilterPeriod.EndDate));
		XMLWriter.WriteEndElement(); //Period
	EndIf;
	For Each Page In Object.AdditionalRegistration Do
		XMLWriter.WriteStartElement("Object");
		XMLWriter.WriteAttribute("Type", XMLString(Page.FullMetadataName));
		If Page.SelectPeriod Then
			XMLWriter.WriteAttribute("Sel_Period", XMLString(Page.SelectPeriod));
			If ValueIsFilled(Page.Period) Then
				XMLWriter.WriteAttribute("Beg_Period", XMLString(Page.Period.StartDate));
				XMLWriter.WriteAttribute("End_Period", XMLString(Page.Period.EndDate));
			EndIf;
		EndIf;
		XMLWriter.WriteAttribute("F_String", XMLString(Page.FilterString));
		If Page.Filter.Items.Count() > 0 Then
			For Each FilterItem In Page.Filter.Items Do
				XMLWriter.WriteStartElement("Filter");
				XMLWriter.WriteAttribute("Comp", XMLString(TrimAll(FilterItem.ComparisonType)));
				XMLWriter.WriteAttribute("Present", XMLString(TrimAll(FilterItem.Presentation)));
				If ValueIsFilled(FilterItem.LeftValue) Then
					WriteFilterValue(FilterItem.LeftValue, "_L", XMLWriter)
				EndIf;
				If ValueIsFilled(FilterItem.RightValue) Then
					WriteFilterValue(FilterItem.RightValue, "_R", XMLWriter)
				EndIf;
				XMLWriter.WriteEndElement();//Filter
			EndDo;
		EndIf;
		XMLWriter.WriteEndElement(); //Object
	EndDo;
	XMLWriter.WriteEndElement(); //Objects
	XMLWriter.Close();
	AddressInStorage = PutToTempStorage(New BinaryData(TempFileName));
	DeleteFiles(TempFileName);
	Return AddressInStorage;
EndFunction

&AtServer
Procedure WriteFilterValue(Val FilterItem_Value, Postfix, XMLWriter)
	DataType = TypeOf(FilterItem_Value);
	MetadataObject =  Metadata.FindByType(DataType);
	
	If MetadataObject <> Undefined Then
		XMLWriter.WriteAttribute("Type" + Postfix,  MetadataObject.FullName());
	Else 
		XMLWriter.WriteAttribute("Type" + Postfix,  String(DataType));
	EndIf;
	If XMLType(DataType) <> Undefined Then
		XMLWriter.WriteAttribute("Val" + Postfix, XMLString(FilterItem_Value));
	Else
		XMLWriter.WriteAttribute("Val" + Postfix, XMLString(String(FilterItem_Value)));
	EndIf;
	
EndProcedure

&AtClient
Procedure SetVisibility()
	Items.FormAbort.Visible = False;
	// Operation kind.
	Items.ExportImport.CurrentPage = ?(OperationKind = "Load", Items.Load, Items.DataExported);
	// A limited option of using the data processor.
	If ValueIsFilled(FormOpenOption) Then
		Items.FormEnableAdvancedFeatures.Visible = False;
		Items.OperationKind.Visible = False;
		Items.PathToImportExchangeManager.Visible = False;
		Items.DataForImportGroup.Visible = False;
		Items.ImportSource.Visible = False;
		Return;
	EndIf;
	If OperationKind = "DataExported" Then
		Items.ExchangeNode.Visible = (DeveloperMode AND Object.ExportSource = "Node");
		Items.FiltersSettingsGroup.Visible = (Object.ExportSource = "Filter");
		Items.ExportRuleTable.Visible = (Object.ExportSource = "Filter");
		Items.PathToExportExchangeManager.Visible = DeveloperMode AND Not DataSeparationEnabled;
		Items.ExportSource.Visible = DeveloperMode;
		Items.ExportLocation.Visible = DeveloperMode;
		Items.ExportResult.Visible = ExportLocation = 1;
		Items.ExportFilePath.Visible = ExportLocation <> 1;
		Items.ExportMain.PagesRepresentation = ?(ExportLocation = 1, FormPagesRepresentation.TabsOnTop, FormPagesRepresentation.None);
	Else
		Items.PathToImportExchangeManager.Visible = DeveloperMode AND Not DataSeparationEnabled;
		Items.ImportSource.Visible = DeveloperMode;
		Items.DataForImportGroup.Visible = (ImportSource = 1);
		Items.PathToImportFile.Visible = (ImportSource <> 1);
	EndIf;
	Items.FormEnableAdvancedFeatures.Check = DeveloperMode;
EndProcedure

&AtServer
Procedure RefreshExportRulesAtServer()
	DataProcessorObject = FormAttributeToValue("Object");
	DataProcessorObject.FillExportRules();
	ValueToFormAttribute(DataProcessorObject, "Object");
EndProcedure

&AtServer
Function SettingsComposerByTableName(TableName, Presentation, Filter)
	DataProcessorObject = FormAttributeToValue("Object");
	Return DataProcessorObject.SettingsComposerByTableName(TableName, Presentation, Filter, UUID);
EndFunction

&AtServer
Function FilterPresentation(Period, Filter)
	DataProcessorObject = FormAttributeToValue("Object");
	Return DataProcessorObject.FilterPresentation(Period, Filter);
EndFunction

&AtServer 
Procedure FilterStringEditingAdditionalCompositionServer(ChoiceStructure, FullMDName, CurRowID)
	AddRegistrationData = Object.AdditionalRegistration.FindRows(
		New Structure("FullMetadataName", FullMDName));
	CurrentData = Object.ExportRuleTable.FindByID(CurRowID);
	If AddRegistrationData.Count() = 0 Then
		Row = Object.AdditionalRegistration.Add();
		FillPropertyValues(Row, CurrentData,"FullMetadataName, Presentation");
		FillString = Row;
	Else
		FillString = AddRegistrationData[0];
	EndIf;
	
	FillString.Period       = ChoiceStructure.DataPeriod;
	FillString.Filter        = ChoiceStructure.SettingsComposer.Settings.Filter;
	FillString.FilterString = FilterPresentation(FillString.Period, FillString.Filter);
	
	CurrentData.FilterPresentation = FillString.FilterString;
	CurrentData.Enable = True;
EndProcedure

&AtClient
Procedure ExportRulesTableEnableOnChange(Item)
	CurrentRowData = Items.ExportRuleTable.CurrentData;
	If CurrentRowData.GetItems().Count() > 0 Then
		For Each Page In CurrentRowData.GetItems() Do
			Page.Enable = CurrentRowData.Enable;
		EndDo;
	EndIf;
EndProcedure

&AtServer
Procedure ExportExchangeManagerPathOnChangeAtServer()
	RefreshExportRulesAtServer();
EndProcedure

&AtClient
Procedure FileSelected(SelectedFiles, AdditionalParameters) Export
	If SelectedFiles = Undefined Then
		Return;
	EndIf;
	If AdditionalParameters.Property("ForImport") Then
		If AdditionalParameters.ForImport Then
			PathToImportFile = SelectedFiles[0];
			// Checking whether the file exists.
			If AdditionalParameters.ImportAfterChoice Then
				ImportFromFileAtClient();
			EndIf;
		Else
			ExportFilePath = SelectedFiles[0];
			If AdditionalParameters.ExportAfterChoice Then
				WriteExportResultToFile(AdditionalParameters.ResultStorageAddress);
			EndIf;
		EndIf;
	ElsIf AdditionalParameters.Property("ManagerModule") Then
		Object[AdditionalParameters.AttributeName] = SelectedFiles[0];
		If AdditionalParameters.UpdateExport Then
			ExportExchangeManagerPathOnChangeAtServer();
		EndIf;
	EndIf;
EndProcedure

&AtClient
Procedure ImportFromFileAtClient()
	AddtnlParameters = New Structure("FileKind", "DataFileToImport");
	NotifyDescription = New NotifyDescription("PutFileInStorageComplete", ThisObject, AddtnlParameters);
	FilesToPut = New Array;
	Interactively = True;
	If ValueIsFilled(PathToImportFile) Then
		FileDetails = New TransferableFileDescription(PathToImportFile);
		Interactively = False;
		FilesToPut.Add(FileDetails);
	EndIf;
	BeginPuttingFiles(NotifyDescription, FilesToPut, , Interactively, UUID);
EndProcedure

&AtClient
Procedure ReportOperationEnd(Import = False)
	OutputBackgroundJobMessages();
	JobID = Undefined;
	Items.ExportImport.CurrentPage = ?(Import, Items.Load, Items.DataExported);
	SetVisibilityOfButtonsEnabledStates(True);
	Message = New UserMessage();
	If Import Then
		Message.Text = NStr("ru = 'Загрузка данных завершена.'; en = 'Data import completed.'; pl = 'Pobieranie danych zakończone.';de = 'Der Datenimport ist abgeschlossen.';ro = 'Importul de date este finalizat.';tr = 'Verinin içe aktarımı tamamlandı.'; es_ES = 'Importación de datos se ha finalizado.'");
	Else
		Message.Text = NStr("ru = 'Выгрузка данных завершена.'; en = 'Data export completed.'; pl = 'Dane są eksportowane.';de = 'Daten werden exportiert.';ro = 'Exportul de date finalizat.';tr = 'Veri dışa aktarıldı.'; es_ES = 'Datos se han exportado.'");
	EndIf;
	Message.Message();
EndProcedure

&AtClient
Procedure SetVisibilityOfButtonsEnabledStates(FlagAvailability)
	Items.UpperGroup.Visible = FlagAvailability;
	Items.FormExecuteOperation.Visible = FlagAvailability;
	Items.FormEnableAdvancedFeatures.Enabled = FlagAvailability;
	Items.FormAbort.Visible = NOT FlagAvailability;
	ThisObject.RefreshDataRepresentation();
EndProcedure

&AtClient
Procedure OutputBackgroundJobMessages()
	If NOT ValueIsFilled(MessagesArray) Then
		MessagesArray = ReadBackgroundJobMessages(JobID);
	EndIf;
	If ValueIsFilled(MessagesArray) Then
		For Each CurrMessage In MessagesArray Do
			If StrStartsWith(CurrMessage.Text,"{") Then
				Continue;
			EndIf;
			CurrMessage.Message();
		EndDo;
	EndIf;
EndProcedure

&AtServerNoContext
Function ReadBackgroundJobMessages(ID)
	If NOT ValueIsFilled(ID) Then
		Return Undefined;
	EndIf;
	Job = BackgroundJobs.FindByUUID(ID);
	If Job = Undefined Then
		Return Undefined;
	EndIf;
	
	Return Job.GetUserMessages(True);
EndFunction

&AtServer
Procedure AbortImportExportServer()
	ModuleTimeConsumingOperations = Common.CommonModule("TimeConsumingOperations");
	ModuleTimeConsumingOperations.CancelJobExecution(JobID);
EndProcedure
#EndRegion
