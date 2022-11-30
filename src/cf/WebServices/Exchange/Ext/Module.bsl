///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Private

////////////////////////////////////////////////////////////////////////////////
// Web service operation handlers

// Matches the Upload web service operation.
Function ExecuteExport(ExchangePlanName, InfobaseNodeCode, ExchangeMessageStorage)
	
	CheckInfobaseLockForUpdate();
	
	DataExchangeServer.CheckDataExchangeUsage();
	
	SetPrivilegedMode(True);
	
	ExchangeMessage = "";
	
	DataExchangeServer.ExportForInfobaseNodeViaString(ExchangePlanName, InfobaseNodeCode, ExchangeMessage);
	
	ExchangeMessageStorage = New ValueStorage(ExchangeMessage, New Deflation(9));
	
	Return "";
	
EndFunction

// Matches the Download web service operation.
Function ExecuteImport(ExchangePlanName, InfobaseNodeCode, ExchangeMessageStorage)
	
	CheckInfobaseLockForUpdate();
	
	DataExchangeServer.CheckDataExchangeUsage();
	
	SetPrivilegedMode(True);
	
	DataExchangeServer.ImportForInfobaseNodeViaString(ExchangePlanName, InfobaseNodeCode, ExchangeMessageStorage.Get());
	
	Return "";
	
EndFunction

// Matches the UploadData web service operation.
Function RunDataExport(ExchangePlanName,
								InfobaseNodeCode,
								FileIDAsString,
								TimeConsumingOperation,
								OperationID,
								TimeConsumingOperationAllowed)
	
	CheckInfobaseLockForUpdate();
	
	DataExchangeServer.CheckDataExchangeUsage();
	
	FileID = New UUID;
	FileIDAsString = String(FileID);
	RunExportDataInClientServerMode(ExchangePlanName, InfobaseNodeCode, FileID, TimeConsumingOperation, OperationID, TimeConsumingOperationAllowed);
	
	Return "";
	
EndFunction

// Matches the DownloadData web service operation.
Function RunDataImport(ExchangePlanName,
								InfobaseNodeCode,
								FileIDAsString,
								TimeConsumingOperation,
								OperationID,
								TimeConsumingOperationAllowed)
	
	CheckInfobaseLockForUpdate();
	
	DataExchangeServer.CheckDataExchangeUsage();
	
	FileID = New UUID(FileIDAsString);
	RunImportDataInClientServerMode(ExchangePlanName, InfobaseNodeCode, FileID, TimeConsumingOperation, OperationID, TimeConsumingOperationAllowed);
	
	Return "";
	
EndFunction

// Matches the GetIBParameters web service operation.
Function GetInfobaseParameters(ExchangePlanName, NodeCode, ErrorMessage)
	
	Return DataExchangeServer.GetInfobaseParameters(ExchangePlanName, NodeCode, ErrorMessage);
	
EndFunction

// Matches the GetIBData web service operation.
Function GetInfobaseData(FullTableName)
	
	Result = New Structure("MetadataObjectProperties, CorrespondentInfobaseTable");
	
	Result.MetadataObjectProperties = ValueToStringInternal(DataExchangeServer.MetadataObjectProperties(FullTableName));
	Result.CorrespondentInfobaseTable = ValueToStringInternal(DataExchangeServer.GetTableObjects(FullTableName));
	
	Return ValueToStringInternal(Result);
	
EndFunction

// Matches the GetCommonNodsData web service operation.
Function GetCommonNodesData(ExchangePlanName)
	
	SetPrivilegedMode(True);
	
	Return ValueToStringInternal(DataExchangeServer.DataForThisInfobaseNodeTabularSections(ExchangePlanName));
	
EndFunction

// Matches the CreateExchange web service operation.
Function CreateDataExchange(ExchangePlanName, ParametersString, FilterSettingAsString, DefaultValuesAsString)
	
	DataExchangeServer.CheckDataExchangeUsage();
	
	SetPrivilegedMode(True);
	
	// Creating an instance of exchange setup wizard data processor.
	DataExchangeCreationWizard = DataExchangeServer.ModuleDataExchangeCreationWizard().Create();
	DataExchangeCreationWizard.ExchangePlanName = ExchangePlanName;
	
	Cancel = False;
	
	// Loading wizard parameters from a string to the wizard data processor.
	DataExchangeCreationWizard.ImportWizardParameters(Cancel, ParametersString);
	
	If Cancel Then
		Message = NStr("ru = 'При создании настройки обмена во второй информационной базе возникли ошибки: %1'; en = 'Errors occurred in the second infobase during the data exchange setup: %1'; pl = 'Podczas tworzenia ustawień wymiany w drugiej bazie informacyjnej wystąpiły błędy: %1';de = 'Beim Erstellen der Austausch-Einstellung in der zweiten Infobase sind Fehler aufgetreten: %1';ro = 'La crearea setării de schimb în cea de-a doua bază de date au apărut erori: %1';tr = 'İkinci veritabanında değişim ayarı oluştururken, hatalar oluştu: %1'; es_ES = 'Al crear la configuración de intercambio en la segunda infobase, han ocurrido errores: %1'");
		Message = StringFunctionsClientServer.SubstituteParametersToString(Message, DataExchangeCreationWizard.ErrorMessageString());
		
		WriteLogEvent(DataExchangeServer.DataExchangeCreationEventLogEvent(),
			EventLogLevel.Error, , , Message);
		
		Raise Message;
	EndIf;
	
	DataExchangeCreationWizard.WizardRunOption = "ContinueDataExchangeSetup";
	DataExchangeCreationWizard.IsDistributedInfobaseSetup = False;
	DataExchangeCreationWizard.ExchangeMessagesTransportKind = Enums.ExchangeMessagesTransportTypes.WS;
	DataExchangeCreationWizard.SourceInfobasePrefixIsSet = ?(DataExchangeCreationWizard.UsePrefixesForExchangeSettings,
										ValueIsFilled(GetFunctionalOption("InfobasePrefix")),
										ValueIsFilled(DataExchangeCreationWizard.SourceInfobaseID));
	
	// Creating an exchange setting.
	DataExchangeCreationWizard.SetUpNewDataExchangeWebService(
											Cancel,
											ValueFromStringInternal(FilterSettingAsString),
											ValueFromStringInternal(DefaultValuesAsString));
	
	If Cancel Then
		Message = NStr("ru = 'При создании настройки обмена во второй информационной базе возникли ошибки: %1'; en = 'Errors occurred in the second infobase during the data exchange setup: %1'; pl = 'Podczas tworzenia ustawień wymiany w drugiej bazie informacyjnej wystąpiły błędy: %1';de = 'Beim Erstellen der Austausch-Einstellung in der zweiten Infobase sind Fehler aufgetreten: %1';ro = 'La crearea setării de schimb în cea de-a doua bază de date au apărut erori: %1';tr = 'İkinci veritabanında değişim ayarı oluştururken, hatalar oluştu: %1'; es_ES = 'Al crear la configuración de intercambio en la segunda infobase, han ocurrido errores: %1'");
		Message = StringFunctionsClientServer.SubstituteParametersToString(Message, DataExchangeCreationWizard.ErrorMessageString());
		
		WriteLogEvent(DataExchangeServer.DataExchangeCreationEventLogEvent(),
			EventLogLevel.Error, , , Message);
		
		Raise Message;
	EndIf;
	
	Return "";
	
EndFunction

// Matches the UpdateExchange web service operation.
Function UpdateDataExchangeSettings(ExchangePlanName, NodeCode, DefaultValuesAsString)
	
	DataExchangeServer.ExternalConnectionUpdateDataExchangeSettings(ExchangePlanName, NodeCode, DefaultValuesAsString);
	
	Return "";
	
EndFunction

// Matches the RegisterOnlyCatalogData web service operation.
Function RecordOnlyCatalogChanges(ExchangePlanName, NodeCode, TimeConsumingOperation, OperationID)
	
	RegisterDataForInitialExport(ExchangePlanName, NodeCode, TimeConsumingOperation, OperationID, True);
	
	Return "";
	
EndFunction

// Matches the RegisterAllDataExceptCatalogs web service operation.
Function RecordAllDataChangesButCatalogChanges(ExchangePlanName, NodeCode, TimeConsumingOperation, OperationID)
	
	RegisterDataForInitialExport(ExchangePlanName, NodeCode, TimeConsumingOperation, OperationID, False);
	
	Return "";
	
EndFunction

// Matches the GetContinuousOperationStatus web service operation.
Function GetTimeConsumingOperationState(OperationID, ErrorMessageString)
	
	BackgroundJobStates = New Map;
	BackgroundJobStates.Insert(BackgroundJobState.Active,           "Active");
	BackgroundJobStates.Insert(BackgroundJobState.Completed,         "Completed");
	BackgroundJobStates.Insert(BackgroundJobState.Failed, "Failed");
	BackgroundJobStates.Insert(BackgroundJobState.Canceled,          "Canceled");
	
	SetPrivilegedMode(True);
	
	BackgroundJob = BackgroundJobs.FindByUUID(New UUID(OperationID));
	
	If BackgroundJob.ErrorInfo <> Undefined Then
		
		ErrorMessageString = DetailErrorDescription(BackgroundJob.ErrorInfo);
		
	EndIf;
	
	Return BackgroundJobStates.Get(BackgroundJob.State);
	
EndFunction

// Matches the GetFunctionalOption web service operation.
Function GetFunctionalOptionValue(Name)
	
	Return GetFunctionalOption(Name);
	
EndFunction

// Matches the PrepareGetFile web service operation.
Function PrepareGetFile(FileId, BlockSize, TransferId, PartQuantity)
	
	SetPrivilegedMode(True);
	
	TransferId = New UUID;
	
	SourceFileName = DataExchangeServer.GetFileFromStorage(FileId);
	
	TempDirectory = TemporaryExportDirectory(TransferId);
	
	File = New File(SourceFileName);
	
	SourceFileNameInTemporaryDirectory = CommonClientServer.GetFullFileName(TempDirectory, File.Name);
	SharedFileName = CommonClientServer.GetFullFileName(TempDirectory, "data.zip");
	
	CreateDirectory(TempDirectory);
	
	MoveFile(SourceFileName, SourceFileNameInTemporaryDirectory);
	
	Archiver = New ZipFileWriter(SharedFileName,,,, ZIPCompressionLevel.Maximum);
	Archiver.Add(SourceFileNameInTemporaryDirectory);
	Archiver.Write();
	
	If BlockSize <> 0 Then
		// Splitting a file into parts
		FileNames = SplitFile(SharedFileName, BlockSize * 1024);
		PartQuantity = FileNames.Count();
	Else
		PartQuantity = 1;
		MoveFile(SharedFileName, SharedFileName + ".1");
	EndIf;
	
	Return "";
	
EndFunction

// Matches the GetFilePart web service operation.
Function GetFilePart(TransferId, PartNumber, PartData)
	
	FileName = "data.zip.[n]";
	FileName = StrReplace(FileName, "[n]", Format(PartNumber, "NG=0"));
	
	FileNames = FindFiles(TemporaryExportDirectory(TransferId), FileName);
	If FileNames.Count() = 0 Then
		
		MessageTemplate = NStr("ru = 'Не найден фрагмент %1 сессии передачи с идентификатором %2'; en = 'Volume %1 is not found in the transfer session with the following ID: %2'; pl = 'Nie znaleziono fragmentu %1 sesji przesyłania z identyfikatorem %2';de = 'Fragment %1 der Übertragungssitzung mit ID %2 wurde nicht gefunden';ro = 'Fragmentul %1 al sesiunii de transfer cu ID %2 nu a fost găsit';tr = 'ID %2 ile transfer oturumu%1 parçası bulunamadı'; es_ES = 'Fragmento %1 de la sesión de traslado con el identificador %2 no se ha encontrado'");
		MessageText = StringFunctionsClientServer.SubstituteParametersToString(MessageTemplate, String(PartNumber), String(TransferId));
		Raise(MessageText);
		
	ElsIf FileNames.Count() > 1 Then
		
		MessageTemplate = NStr("ru = 'Найдено несколько фрагментов %1 сессии передачи с идентификатором %2'; en = 'Multiple instances of volume %1 are found in the transfer session with the following ID: %2'; pl = 'Nie znaleziono kilku fragmentów %1 sesji przesyłania z identyfikatorem %2';de = 'Mehrere Fragmente %1 der Übertragungssitzung mit ID %2 werden gefunden';ro = 'Au fost găsite mai multe fragmente %1 din sesiunea de transfer cu ID %2';tr = 'ID ile%1 transfer %2 oturumun birkaç parçası bulundu'; es_ES = 'Varios fragmentos %1 de la sesión de traslado con el identificador %2 se han encontrado'");
		MessageText = StringFunctionsClientServer.SubstituteParametersToString(MessageTemplate, String(PartNumber), String(TransferId));
		Raise(MessageText);
		
	EndIf;
	
	PartFileName = FileNames[0].FullName;
	PartData = New BinaryData(PartFileName);
	
	Return "";
	
EndFunction

// Matches the ReleaseFile web service operation.
Function ReleaseFile(TransferId)
	
	Try
		DeleteFiles(TemporaryExportDirectory(TransferId));
	Except
		WriteLogEvent(DataExchangeServer.TempFileDeletionEventLogMessageText(),
			EventLogLevel.Error,,, DetailErrorDescription(ErrorInfo()));
	EndTry;
	
	Return "";
	
EndFunction

// Matches the PutFilePart web service operation.
Function PutFilePart(TransferId, PartNumber, PartData)
	
	TempDirectory = TemporaryExportDirectory(TransferId);
	
	If PartNumber = 1 Then
		
		CreateDirectory(TempDirectory);
		
	EndIf;
	
	FileName = CommonClientServer.GetFullFileName(TempDirectory, GetPartFileName(PartNumber));
	
	PartData.Write(FileName);
	
	Return "";
	
EndFunction

// Matches the SaveFileFromParts web service operation.
Function SaveFileFromParts(TransferId, PartQuantity, FileId)
	
	SetPrivilegedMode(True);
	
	TempDirectory = TemporaryExportDirectory(TransferId);
	
	PartsFilesToMerge = New Array;
	
	For PartNumber = 1 To PartQuantity Do
		
		FileName = CommonClientServer.GetFullFileName(TempDirectory, GetPartFileName(PartNumber));
		
		If FindFiles(FileName).Count() = 0 Then
			MessageTemplate = NStr("ru = 'Не найден фрагмент %1 сессии передачи с идентификатором %2.
					|Необходимо убедиться, что в настройках программы заданы параметры
					|""Каталог временных файлов для Linux"" и ""Каталог временных файлов для Windows"".'; 
					|en = 'Fragment %1 of the transfer session with ID %2 is not found. 
					|Make sure that the ""Directory of temporary files for Linux""
					| and ""Directory of temporary files for Windows"" parameters are specified in the application settings.'; 
					|pl = 'Nie znaleziono fragmentu %1 sesji przesyłania z identyfikatorem %2.
					|Należy upewnić się, że
					|w ustawieniach aplikacji określono parametry ""Katalog plików tymczasowych Linux"" i ""Katalog plików tymczasowych Windows"".';
					|de = 'Das Fragment der Übertragungssitzung %1 mit ID %2 wird nicht gefunden. 
					|Es ist notwendig sicherzustellen, 
					|dass in den Anwendungseinstellungen die Parameter ""Verzeichnis der temporären Dateien für Linux"" und ""Verzeichnis der temporären Dateien für Windows"" angegeben sind.';
					|ro = 'Fragmentul %1 al sesiunii de transfer cu ID %2 nu este găsit.
					|Este necesar să vă asigurați că în setările aplicației sunt specificați parametrii
					|""Directorul fișierelor temporare pentru Linux"" și ""Directorul fișierelor temporare pentru Windows"".';
					|tr = '%1ID ile transfer oturumu %2 parçası bulunamadı. 
					|Uygulama ayarlarında ""Linux için geçici dosya dizini"" ve ""Windows için geçici dosya dizini"" 
					|belirtildiğinden emin olmak gerekir.'; 
					|es_ES = 'Fragmento de la sesión de traslado %1 con el identificador %2 no se ha encontrado.
					|Es necesario asegurarse de que
					|los parámetros de las configuraciones ""Directorio de los archivos temporales para Linux"" y ""Directorio de los archivos temporales para Windows"" están especificados en la aplicación.'");
			MessageText = StringFunctionsClientServer.SubstituteParametersToString(MessageTemplate, String(PartNumber), String(TransferId));
			Raise(MessageText);
		EndIf;
		
		PartsFilesToMerge.Add(FileName);
		
	EndDo;
	
	ArchiveName = CommonClientServer.GetFullFileName(TempDirectory, "data.zip");
	
	MergeFiles(PartsFilesToMerge, ArchiveName);
	
	Dearchiver = New ZipFileReader(ArchiveName);
	
	If Dearchiver.Items.Count() = 0 Then
		Try
			DeleteFiles(TempDirectory);
		Except
			WriteLogEvent(DataExchangeServer.TempFileDeletionEventLogMessageText(),
				EventLogLevel.Error,,, DetailErrorDescription(ErrorInfo()));
		EndTry;
		Raise(NStr("ru = 'Файл архива не содержит данных.'; en = 'The archive file does not contain data.'; pl = 'Plik archiwum nie zawiera danych.';de = 'Die Archivdatei enthält keine Daten.';ro = 'Fișierul arhivei nu conține date.';tr = 'Arşiv dosyası veri içermemektedir.'; es_ES = 'Documento del archivo no contiene datos.'"));
	EndIf;
	
	DumpDirectory = DataExchangeServer.TempFilesStorageDirectory();
	
	FileName = CommonClientServer.GetFullFileName(DumpDirectory, Dearchiver.Items[0].Name);
	
	Dearchiver.Extract(Dearchiver.Items[0], DumpDirectory);
	Dearchiver.Close();
	
	FileId = DataExchangeServer.PutFileInStorage(FileName);
	
	Try
		DeleteFiles(TempDirectory);
	Except
		WriteLogEvent(DataExchangeServer.TempFileDeletionEventLogMessageText(),
			EventLogLevel.Error,,, DetailErrorDescription(ErrorInfo()));
	EndTry;
	
	Return "";
	
EndFunction

// Matches the PutFileIntoStorage web service operation.
Function PutFileIntoStorage(FileName, FileId)
	
	SetPrivilegedMode(True);
	
	FileId = DataExchangeServer.PutFileInStorage(FileName);
	
	Return "";
	
EndFunction

// Matches the GetFileFromStorage web service operation.
Function GetFileFromStorage(FileId)
	
	SetPrivilegedMode(True);
	
	SourceFileName = DataExchangeServer.GetFileFromStorage(FileId);
	
	File = New File(SourceFileName);
	
	Return File.Name;
	
EndFunction

// Matches the FileExists web service operation.
Function FileExists(FileName)
	
	SetPrivilegedMode(True);
	
	TempFileFullName = CommonClientServer.GetFullFileName(DataExchangeServer.TempFilesStorageDirectory(), FileName);
	
	File = New File(TempFileFullName);
	
	Return File.Exist();
	
EndFunction

////////////////////////////////////////////////////////////////////////////////
// Local internal procedures and functions.

Procedure CheckInfobaseLockForUpdate()
	
	IBLockedForUpdate = InfobaseUpdateInternal.InfobaseLockedForUpdate();
	If ValueIsFilled(IBLockedForUpdate) Then
		Raise IBLockedForUpdate;
	EndIf;
	
EndProcedure

Procedure RunExportDataInClientServerMode(ExchangePlanName,
														InfobaseNodeCode,
														FileID,
														TimeConsumingOperation,
														OperationID,
														TimeConsumingOperationAllowed)
	
	BackgroundJobKey = ExportImportDataBackgroundJobKey(ExchangePlanName,
		InfobaseNodeCode,
		NStr("ru = 'Выгрузка'; en = 'Export'; pl = 'Eksportowanie';de = 'Entladen';ro = 'Export';tr = 'Dışa aktarma'; es_ES = 'Subida'"));
	
	If HasActiveDataSynchronizationBackgroundJobs(BackgroundJobKey) Then
		Raise NStr("ru = 'Синхронизация данных уже выполняется.'; en = 'Data synchronization is already running.'; pl = 'Synchronizacja danych jest już w toku.';de = 'Die Datensynchronisation wird bereits ausgeführt.';ro = 'Sincronizarea datelor deja se execută.';tr = 'Veri senkronizasyonu zaten yürütülüyor.'; es_ES = 'Sincronización de datos ya se está ejecutando.'");
	EndIf;
	
	ProcedureParameters = New Structure;
	ProcedureParameters.Insert("ExchangePlanName", ExchangePlanName);
	ProcedureParameters.Insert("InfobaseNodeCode", InfobaseNodeCode);
	ProcedureParameters.Insert("FileID", FileID);
	
	ExecutionParameters = TimeConsumingOperations.BackgroundExecutionParameters(New UUID);
	ExecutionParameters.BackgroundJobDescription = NStr("ru = 'Выгрузка данных через веб-сервис.'; en = 'Export data via web service.'; pl = 'Wyeksportowanie danych za pośrednictwem serwisu internetowego.';de = 'Export von Daten über Webservice.';ro = 'Exportul datelor prin intermediul serviciului web.';tr = 'Verileri web servis üzerinden dışa aktarma'; es_ES = 'Subida de datos a través del servicio web.'");
	ExecutionParameters.BackgroundJobKey = BackgroundJobKey;
	
	ExecutionParameters.RunNotInBackground = Not TimeConsumingOperationAllowed;
	ExecutionParameters.RunInBackground   = TimeConsumingOperationAllowed;
	
	BackgroundJob = TimeConsumingOperations.ExecuteInBackground(
		"DataExchangeServer.ExportToFileTransferServiceForInfobaseNode",
		ProcedureParameters,
		ExecutionParameters);
		
	If BackgroundJob.Status = "Running" Then
		OperationID = String(BackgroundJob.JobID);
		TimeConsumingOperation = True;
		Return;
	ElsIf BackgroundJob.Status = "Completed" Then
		TimeConsumingOperation = False;
		Return;
	Else
		Message = NStr("ru = 'Ошибка при выгрузке данных через веб-сервис.'; en = 'An error occurred during the data export through the web service.'; pl = 'Podczas eksportu danych z pomocą serwisu internetowego wystąpił błąd.';de = 'Beim Exportieren von Daten über den Webservice ist ein Fehler aufgetreten.';ro = 'A apărut o eroare la exportul datelor prin intermediul serviciului web.';tr = 'Web hizmeti yoluyla veri dışa aktarılırken bir hata oluştu.'; es_ES = 'Ha ocurrido un error al exportar los datos a través del servicio web.'");
		If ValueIsFilled(BackgroundJob.DetailedErrorPresentation) Then
			Message = BackgroundJob.DetailedErrorPresentation;
		EndIf;
		
		WriteLogEvent(DataExchangeServer.EventLogEventExportDataToFilesTransferService(),
			EventLogLevel.Error, , , Message);
		
		Raise Message;
	EndIf;
	
EndProcedure

Procedure RunImportDataInClientServerMode(ExchangePlanName,
													InfobaseNodeCode,
													FileID,
													TimeConsumingOperation,
													OperationID,
													TimeConsumingOperationAllowed)
	
	BackgroundJobKey = ExportImportDataBackgroundJobKey(ExchangePlanName,
		InfobaseNodeCode,
		NStr("ru = 'Загрузка'; en = 'Import'; pl = 'Pobieranie';de = 'Beladen';ro = 'Import';tr = 'İçe aktarma'; es_ES = 'Descarga'"));
	
	If HasActiveDataSynchronizationBackgroundJobs(BackgroundJobKey) Then
		Raise NStr("ru = 'Синхронизация данных уже выполняется.'; en = 'Data synchronization is already running.'; pl = 'Synchronizacja danych jest już w toku.';de = 'Die Datensynchronisation wird bereits ausgeführt.';ro = 'Sincronizarea datelor deja se execută.';tr = 'Veri senkronizasyonu zaten yürütülüyor.'; es_ES = 'Sincronización de datos ya se está ejecutando.'");
	EndIf;
	
	ProcedureParameters = New Structure;
	ProcedureParameters.Insert("ExchangePlanName", ExchangePlanName);
	ProcedureParameters.Insert("InfobaseNodeCode", InfobaseNodeCode);
	ProcedureParameters.Insert("FileID", FileID);
	
	ExecutionParameters = TimeConsumingOperations.BackgroundExecutionParameters(New UUID);
	ExecutionParameters.BackgroundJobDescription = NStr("ru = 'Загрузка данных через веб-сервис.'; en = 'Import data via web service.'; pl = 'Pobieranie danych za pośrednictwem serwisu internetowego.';de = 'Import von Daten über Webservice.';ro = 'Importul datelor prin intermediul serviciului web.';tr = 'Verileri web servis üzerinden içe aktarma.'; es_ES = 'Descarga de datos a través del servidor web.'");
	ExecutionParameters.BackgroundJobKey = BackgroundJobKey;
	
	ExecutionParameters.RunNotInBackground = Not TimeConsumingOperationAllowed;
	ExecutionParameters.RunInBackground   = TimeConsumingOperationAllowed;
	
	BackgroundJob = TimeConsumingOperations.ExecuteInBackground(
		"DataExchangeServer.ImportFromFileTransferServiceForInfobaseNode",
		ProcedureParameters,
		ExecutionParameters);
		
	If BackgroundJob.Status = "Running" Then
		OperationID = String(BackgroundJob.JobID);
		TimeConsumingOperation = True;
		Return;
	ElsIf BackgroundJob.Status = "Completed" Then
		TimeConsumingOperation = False;
		Return;
	Else
		
		Message = NStr("ru = 'Ошибка при загрузке данных через веб-сервис.'; en = 'An error occurred during the data import through the web service.'; pl = 'Podczas importu danych z pomocą serwisu internetowego wystąpił błąd.';de = 'Beim Importieren von Daten mit dem Webservice ist ein Fehler aufgetreten.';ro = 'A apărut o eroare la importul datelor prin intermediul serviciului web.';tr = 'Web hizmeti kullanılarak veri alınırken bir hata oluştu.'; es_ES = 'Ha ocurrido un error al importar los datos utilizando el servicio web.'");
		If ValueIsFilled(BackgroundJob.DetailedErrorPresentation) Then
			Message = BackgroundJob.DetailedErrorPresentation;
		EndIf;
		
		WriteLogEvent(DataExchangeServer.ExportDataFromFileTransferServiceEventLogEvent(),
			EventLogLevel.Error, , , Message);
		
		Raise Message;
	EndIf;
	
EndProcedure

Function ExportImportDataBackgroundJobKey(ExchangePlan, NodeCode, Action)
	
	Return StringFunctionsClientServer.SubstituteParametersToString(
		NStr("ru = 'ПланОбмена:%1 КодУзла:%2 Действие:%3'; en = 'ExchangePlan:%1 NodeCode:%2 Action:%3'; pl = 'PlanWymiany:%1 KodWęzła:%2 Działanie:%3';de = 'AustauschPlan:%1 CodeKnoten:%2 Aktion:%3';ro = 'ПланОбмена:%1 КодУзла:%2 Действие:%3';tr = 'AlışverişPlanı:%1 ÜniteKodu: %2 Eylem: %3'; es_ES = 'ExchangePlan:%1 NodeCode:%2 Acción:%3'"),
		ExchangePlan,
		NodeCode,
		Action);
	
EndFunction

Function HasActiveDataSynchronizationBackgroundJobs(BackgroundJobKey)
	
	Filter = New Structure;
	Filter.Insert("Key", BackgroundJobKey);
	Filter.Insert("State", BackgroundJobState.Active);
	
	ActiveBackgroundJobs = BackgroundJobs.GetBackgroundJobs(Filter);
	
	Return (ActiveBackgroundJobs.Count() > 0);
	
EndFunction

Procedure RegisterDataForInitialExport(Val ExchangePlanName, Val NodeCode, TimeConsumingOperation, OperationID, CatalogsOnly)
	
	SetPrivilegedMode(True);
	
	InfobaseNode = DataExchangeServer.ExchangePlanNodeByCode(ExchangePlanName, NodeCode);
	
	If Not ValueIsFilled(InfobaseNode) Then
		Message = NStr("ru = 'Не найден узел плана обмена; имя плана обмена %1; код узла %2'; en = 'Exchange plan node not found. Node name: %1, node code: %2.'; pl = 'Nie znaleziono węzła planu wymiany; nazwa planu wymiany %1; kod węzła %2';de = 'Der Austauschplan-Knoten wurde nicht gefunden. Name des Austauschplans %1; Knotencode %2';ro = 'Nodul planului de schimb nu a fost găsit; numele planului de schimb %1; codul nodului %2';tr = 'Değişim plan ünitesi bulunamadı; değişim planı adı%1; ünite kodu %2'; es_ES = 'Nodo del plan de intercambio no encontrado; nombre del plan de intercambio %1; código del nodo %2'");
		Message = StringFunctionsClientServer.SubstituteParametersToString(Message, ExchangePlanName, NodeCode);
		Raise Message;
	EndIf;
	
	If Common.FileInfobase() Then
		
		If CatalogsOnly Then
			
			DataExchangeServer.RegisterOnlyCatalogsForInitialExport(InfobaseNode);
			
		Else
			
			DataExchangeServer.RegisterAllDataExceptCatalogsForInitialExport(InfobaseNode);
			
		EndIf;
		
	Else
		
		If CatalogsOnly Then
			MethodName = "DataExchangeServer.RegisterCatalogsOnlyForInitialBackgroundExport";
			JobDescription = NStr("ru = 'Регистрация изменений справочников для начальной выгрузки.'; en = 'Register catalog changes for initial export.'; pl = 'Rejestracja zmian katalogów do początkowego wyeksportowania.';de = 'Registrieren Sie Änderungen an den Verzeichnissen für den ersten Upload.';ro = 'Înregistrarea modificărilor clasificatoarelor pentru exportul inițial.';tr = 'İlk dışa aktarma için dizin değişikliklerin kaydı.'; es_ES = 'Registro de cambios de catálogos para la subida inicial.'");
		Else
			MethodName = "DataExchangeServer.RegisterAllDataExceptCatalogsForInitialBackgroundExport";
			JobDescription = NStr("ru = 'Регистрация изменений всех данных кроме справочников для начальной выгрузки.'; en = 'Register all data changes except for catalogs for initial export.'; pl = 'Rejestracja zmian wszystkich danych z wyjątkiem katalogów dla początkowego wyeksportowania.';de = 'Registrierung von Änderungen aller Daten außer Verzeichnisse für den ersten Upload.';ro = 'Înregistrarea modificărilor tuturor datelor cu excepția clasificatoarelor pentru exportul inițial.';tr = 'Ilk dışa aktarma dizinleri haricinde tüm veri değişikliklerin kaydı.'; es_ES = 'Registro de cambios de todos los datos a excepción de la subida inicial.'");
		EndIf;
		
		ProcedureParameters = New Structure;
		ProcedureParameters.Insert("InfobaseNode", InfobaseNode);
		
		ExecutionParameters = TimeConsumingOperations.BackgroundExecutionParameters(New UUID);
		ExecutionParameters.BackgroundJobDescription = JobDescription;
		
		ExecutionParameters.RunInBackground = True;
		
		BackgroundJob = TimeConsumingOperations.ExecuteInBackground(MethodName, ProcedureParameters, ExecutionParameters);
			
		If BackgroundJob.Status = "Running" Then
			OperationID = String(BackgroundJob.JobID);
			TimeConsumingOperation = True;
		ElsIf BackgroundJob.Status = "Completed" Then
			TimeConsumingOperation = False;
		Else
			If ValueIsFilled(BackgroundJob.DetailedErrorPresentation) Then
				Raise BackgroundJob.DetailedErrorPresentation;
			EndIf;
			
			Raise StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'Ошибка при выполнении фонового задания: %1'; en = 'An error occurred while executing the background job: %1'; pl = 'Błąd podczas wykonywania pracy w tle: %1';de = 'Fehler bei der Ausführung von Hintergrundjobs: %1';ro = 'Eroare la executarea sarcinii de fundal: %1';tr = 'Arka plan görevi yürütülürken bir hata oluştu: %1'; es_ES = 'Error al realizar la tarea de fondo: %1'"),
				JobDescription);
		EndIf;
		
	EndIf;
	
EndProcedure

Function GetPartFileName(PartNumber)
	
	Result = "data.zip.[n]";
	
	Return StrReplace(Result, "[n]", Format(PartNumber, "NG=0"));
EndFunction

Function TemporaryExportDirectory(Val SessionID)
	
	SetPrivilegedMode(True);
	
	TempDirectory = "{SessionID}";
	TempDirectory = StrReplace(TempDirectory, "SessionID", String(SessionID));
	
	Result = CommonClientServer.GetFullFileName(DataExchangeServer.TempFilesStorageDirectory(), TempDirectory);
	
	Return Result;
EndFunction

#EndRegion
