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
	
	Result = DataExchangeServer.InfobaseParameters(ExchangePlanName, NodeCode, ErrorMessage);
	Return XDTOSerializer.WriteXDTO(Result);
	
EndFunction

// Matches the CreateExchangeNode web service operation.
Function CreateDataExchangeNode(XDTOParameters)
	
	DataExchangeServer.CheckDataExchangeUsage(True);
	
	Parameters = XDTOSerializer.ReadXDTO(XDTOParameters);
	
	ConnectionSettings = Parameters.ConnectionSettings;
	XMLParametersString  = Parameters.XMLParametersString;
	
	ModuleSetupWizard = DataExchangeServer.ModuleDataExchangeCreationWizard();
	Try
		ModuleSetupWizard.FillConnectionSettingsFromXMLString(
			ConnectionSettings, Parameters.XMLParametersString, , True);
			
		ModuleSetupWizard.ConfigureDataExchange(
			ConnectionSettings);
	Except
		ErrorMessage = DetailErrorDescription(ErrorInfo());
			
		WriteLogEvent(DataExchangeServer.DataExchangeCreationEventLogEvent(),
			EventLogLevel.Error, , , ErrorMessage);
			
		Raise ErrorMessage;
	EndTry;
	
	Return "";
	
EndFunction

// Matches the RemoveExchangeNode web service operation.
Function DeleteDataExchangeNode(ExchangePlanName, NodeID)
	
	ExchangeNode = DataExchangeServer.ExchangePlanNodeByCode(ExchangePlanName, NodeID);
		
	If ExchangeNode = Undefined Then
		ApplicationPresentation = ?(Common.DataSeparationEnabled(),
			Metadata.Synonym, DataExchangeCached.ThisInfobaseName());
			
		Raise StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'В ""%1"" не найден узел плана обмена ""%2"" с идентификатором ""%3"".'; en = 'Exchange plan node ""%2"" with ID %3 was not found in %1.'; pl = 'W ""%1"" nie znaleziono węzła planu wymiany ""%2"" z identyfikatorem ""%3"".';de = 'Der Austauschplanknoten ""%2"" mit der Kennung ""%3"" ist in ""%1"" nicht zu finden.';ro = 'În ""%1"" nu a fost găsit nodul planului de schimb ""%2"" cu identificatorul ""%3"".';tr = '""%1"" ''de ""%2"" tanımlayıcısına sahip ""%3"" alışveriş planı ünitesi bulunamadı.'; es_ES = 'En ""%1"" no se ha encontrado el nodo del plan de cambio ""%2"" con el identificador ""%3"".'"),
			ApplicationPresentation, ExchangePlanName, NodeID);
	EndIf;
	
	DataExchangeServer.DeleteSynchronizationSetting(ExchangeNode);
	
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

// Matches the PrepareGetFile web service operation.
Function PrepareGetFile(FileId, BlockSize, TransferId, PartQuantity)
	
	SetPrivilegedMode(True);
	
	TransferId = New UUID;
	
	SourceFileName = DataExchangeServer.GetFileFromStorage(FileId);
	
	TempDirectory = TemporaryExportDirectory(TransferId);
	
	SourceFileNameInTemporaryDirectory = CommonClientServer.GetFullFileName(TempDirectory, "data.zip");
	
	CreateDirectory(TempDirectory);
	
	MoveFile(SourceFileName, SourceFileNameInTemporaryDirectory);
	
	If BlockSize <> 0 Then
		// Splitting a file into parts
		FileNames = SplitFile(SourceFileNameInTemporaryDirectory, BlockSize * 1024);
		PartQuantity = FileNames.Count();
		
		DeleteFiles(SourceFileNameInTemporaryDirectory);
	Else
		PartQuantity = 1;
		MoveFile(SourceFileNameInTemporaryDirectory, SourceFileNameInTemporaryDirectory + ".1");
	EndIf;
	
	Return "";
	
EndFunction

// Matches the GetFilePart web service operation.
Function GetFilePart(TransferId, PartNumber, PartData)
	
	FileNames = FindPartFile(TemporaryExportDirectory(TransferId), PartNumber);
	
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

// Matches the PutMessageForDataMatching web service operation.
Function PutMessageForDataMatching(ExchangePlanName, NodeID, FileID)
	
	ExchangeNode = DataExchangeServer.ExchangePlanNodeByCode(ExchangePlanName, NodeID);
		
	If ExchangeNode = Undefined Then
		ApplicationPresentation = ?(Common.DataSeparationEnabled(),
			Metadata.Synonym, DataExchangeCached.ThisInfobaseName());
			
		Raise StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'В ""%1"" не найден узел плана обмена ""%2"" с идентификатором ""%3"".'; en = 'Exchange plan node ""%2"" with ID %3 was not found in %1.'; pl = 'W ""%1"" nie znaleziono węzła planu wymiany ""%2"" z identyfikatorem ""%3"".';de = 'Der Austauschplanknoten ""%2"" mit der Kennung ""%3"" ist in ""%1"" nicht zu finden.';ro = 'În ""%1"" nu a fost găsit nodul planului de schimb ""%2"" cu identificatorul ""%3"".';tr = '""%1"" ''de ""%2"" tanımlayıcısına sahip ""%3"" alışveriş planı ünitesi bulunamadı.'; es_ES = 'En ""%1"" no se ha encontrado el nodo del plan de cambio ""%2"" con el identificador ""%3"".'"),
			ApplicationPresentation, ExchangePlanName, NodeID);
	EndIf;
	
	CheckInfobaseLockForUpdate();
	
	DataExchangeServer.CheckDataExchangeUsage();
	
	DataExchangeInternal.PutMessageForDataMapping(ExchangeNode, FileID);
		
	Return "";
	
EndFunction

// Matches the Ping web service operation.
Function Ping()
	// Testing connection.
	Return "";
EndFunction

// Matches the TestConnection web service operation.
Function TestConnection(ExchangePlanName, NodeCode, Result)
	
	// Checking whether a user has rights to perform the data exchange.
	Try
		DataExchangeServer.CheckCanSynchronizeData(True);
	Except
		Result = BriefErrorDescription(ErrorInfo());
		Return False;
	EndTry;
	
	// Checking whether the infobase is locked for update.
	Try
		CheckInfobaseLockForUpdate();
	Except
		Result = BriefErrorDescription(ErrorInfo());
		Return False;
	EndTry;
	
	SetPrivilegedMode(True);
	
	// Checking whether the exchange plan node exists (it might be deleted).
	NodeRef = DataExchangeServer.ExchangePlanNodeByCode(ExchangePlanName, NodeCode);
	If NodeRef = Undefined
		Or Common.ObjectAttributeValue(NodeRef, "DeletionMark") Then
		ApplicationPresentation = ?(Common.DataSeparationEnabled(),
			Metadata.Synonym, DataExchangeCached.ThisInfobaseName());
			
		ExchangePlanPresentation = Metadata.ExchangePlans[ExchangePlanName].Presentation();
			
		Result = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'В ""%1"" не найдена настройка синхронизации данных ""%2"" с идентификатором ""%3"".'; en = 'Data synchronization line ""%2"" with ID %3 was not found in %1.'; pl = 'W ""%1"" nie znaleziono ustawienia synchronizacji danych ""%2"" z identyfikatorem ""%3"".';de = 'Die Einstellung für die Datensynchronisation ""%2"" mit der Kennung ""%3"" wurde in ""%1"" nicht gefunden.';ro = 'În ""%1"" nu a fost găsită setarea de sincronizare a datelor ""%2"" cu identificatorul ""%3"".';tr = '""%1"" ''de ""%2"" tanımlayıcısına sahip veri senkronizasyon ayarları ""%3"" bulunamadı.'; es_ES = 'En ""%1"" no se ha encontrado ajuste de sincronización de datos ""%2"" con el identificador ""%3"".'"),
			ApplicationPresentation, ExchangePlanPresentation, NodeCode);
		
		Return False;
	EndIf;
	
	Return True;
EndFunction

////////////////////////////////////////////////////////////////////////////////
// Local internal procedures and functions.

Procedure CheckInfobaseLockForUpdate()
	
	If ValueIsFilled(InfobaseUpdateInternal.InfobaseLockedForUpdate()) Then
		
		Raise NStr("ru = 'Синхронизация данных временно недоступна в связи с обновлением приложения в Интернете.'; en = 'Data synchronization is unavailable for the duration of Internet-based update.'; pl = 'Synchronizacja danych jest tymczasowo niedostępna z powodu aktualizacji aplikacji online.';de = 'Die Datensynchronisierung ist aufgrund des Online-Anwendungsupdates vorübergehend nicht verfügbar.';ro = 'Sincronizarea datelor este temporar indisponibilă din cauza actualizării aplicației online.';tr = 'Çevrimiçi uygulama güncellemesi nedeniyle veri senkronizasyonu geçici olarak kullanılamıyor.'; es_ES = 'Sincronización de datos no se encuentra temporalmente disponible debido a la actualización online de la aplicación.'");
		
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
	ProcedureParameters.Insert("UseCompression", True);
	
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

Function FindPartFile(Val Directory, Val FileNumber)
	
	For DigitsCount = NumberDigitsCount(FileNumber) To 5 Do
		
		FormatString = StringFunctionsClientServer.SubstituteParametersToString("ND=%1; NLZ=; NG=0", String(DigitsCount));
		
		FileName = StringFunctionsClientServer.SubstituteParametersToString("data.zip.%1", Format(FileNumber, FormatString));
		
		FileNames = FindFiles(Directory, FileName);
		
		If FileNames.Count() > 0 Then
			
			Return FileNames;
			
		EndIf;
		
	EndDo;
	
	Return New Array;
EndFunction

Function NumberDigitsCount(Val Number)
	
	Return StrLen(Format(Number, "NFD=0; NG=0"));
	
EndFunction

#EndRegion
