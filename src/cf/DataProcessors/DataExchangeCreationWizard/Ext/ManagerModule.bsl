///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Internal

// For internal use.
//
Procedure ExportConnectionSettingsForSubordinateDIBNode(ConnectionSettings) Export
	
	SetPrivilegedMode(True);
	
	XMLString = "";
	Try
		XMLString = ConnectionSettingsInXML(ConnectionSettings);
	Except
		Raise;
	EndTry;
		
	Constants.SubordinateDIBNodeSettings.Set(XMLString);
	ExchangePlans.RecordChanges(ConnectionSettings.InfobaseNode,
		Metadata.Constants.SubordinateDIBNodeSettings);
	
EndProcedure

#Region CheckConnectionToCorrespondent

// For internal use.
//
Procedure OnStartTestConnection(ConnectionSettings, HandlerParameters, ContinueWait = True) Export
	
	BackgroundJobKey = BackgroundJobKey(ConnectionSettings.ExchangePlanName,			
		StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Проверка подключения %1'; en = 'Checking connection %1'; pl = 'Weryfikacja połączenia %1';de = 'Verbindungsprüfung %1';ro = 'Verificarea conexiunii %1';tr = 'Bağlantıyı kontrol et%1'; es_ES = 'Comprobar la conexión %1'"), ConnectionSettings.ExchangeMessagesTransportKind));

	If HasActiveBackgroundJobs(BackgroundJobKey) Then
		Raise StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Проверка подключения %1 уже выполняется.'; en = '%1 connection check is already in progress.'; pl = 'Weryfikacja połączenia %1 jest już w toku.';de = 'Die Verbindungsprüfung %1 ist bereits im Gange.';ro = 'Verificarea conexiunii %1 deja se execută.';tr = 'Bağlantı %1zaten kontrol ediliyor.'; es_ES = 'Prueba de conectar %1 ya se está ejecutando.'"), ConnectionSettings.ExchangeMessagesTransportKind);
	EndIf;
		
	ProcedureParameters = New Structure;
	ProcedureParameters.Insert("ConnectionSettings", ConnectionSettings);
	
	ExecutionParameters = TimeConsumingOperations.BackgroundExecutionParameters(New UUID);
	ExecutionParameters.BackgroundJobDescription = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("ru = 'Проверка подключения к корреспонденту: %1.'; en = 'Check connection to peer: %1.'; pl = 'Weryfikacja połączenia do korespondenta: %1.';de = 'Überprüfung der Verbindung zum Korrespondenten: %1.';ro = 'Verificarea conexiunii la corespondent: %1';tr = 'Muhabire bağlantı kontrolü: %1.'; es_ES = 'Prueba de conectar al correspondiente: %1.'"), ConnectionSettings.ExchangeMessagesTransportKind);
	ExecutionParameters.BackgroundJobKey = BackgroundJobKey;
	ExecutionParameters.RunNotInBackground    = False;
	ExecutionParameters.RunInBackground      = True;
	
	BackgroundJob = TimeConsumingOperations.ExecuteInBackground(
		"DataProcessors.DataExchangeCreationWizard.TestCorrespondentConnection",
		ProcedureParameters,
		ExecutionParameters);
		
	OnStartTimeConsumingOperation(BackgroundJob, HandlerParameters, ContinueWait);
	
EndProcedure

Procedure OnWaitForTestConnection(HandlerParameters, ContinueWait = True) Export
	
	OnWaitTimeConsumingOperation(HandlerParameters, ContinueWait);
	
EndProcedure

Procedure OnCompleteTestConnection(HandlerParameters, CompletionStatus) Export
	
	OnCompleteTimeConsumingOperation(HandlerParameters, CompletionStatus);
	
EndProcedure

#EndRegion

#Region SaveConnectionSettings
// For internal use.
//
Procedure OnStartSaveConnectionSettings(ConnectionSettings, HandlerParameters, ContinueWait = True) Export
	
	BackgroundJobKey = BackgroundJobKey(ConnectionSettings.ExchangePlanName,
		NStr("ru = 'Сохранение настроек подключения'; en = 'Save connection settings'; pl = 'Zapisywanie ustawień połączenia';de = 'Speichern der Verbindungseinstellungen';ro = 'Salvarea setărilor de conectare';tr = 'Bağlantı ayarlarının kaydı'; es_ES = 'Guardar los ajustes de conexión'"));

	If HasActiveBackgroundJobs(BackgroundJobKey) Then
		Raise StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Сохранение настроек подключения для ""%1"" уже выполняется.'; en = 'Saving connection settings for ""%1"" is already in progress.'; pl = 'Zapisywanie ustawień połączenia dla ""%1"" jest już w toku.';de = 'Das Speichern der Verbindungseinstellungen für ""%1"" wird bereits ausgeführt.';ro = 'Salvarea setărilor de conectare pentru ""%1"" deja se execută.';tr = '""%1"" için bağlantı ayarları zaten kaydediliyor.'; es_ES = 'Los ajustes de conexión para ""%1"" se están guardando.'"), ConnectionSettings.ExchangePlanName);
	EndIf;
		
	ProcedureParameters = New Structure;
	ProcedureParameters.Insert("ConnectionSettings", ConnectionSettings);
	
	ExecutionParameters = TimeConsumingOperations.BackgroundExecutionParameters(New UUID);
	ExecutionParameters.BackgroundJobDescription = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("ru = 'Сохранение настроек подключения: %1.'; en = 'Save connection settings: %1'; pl = 'Zapisywanie ustawień połączenia: %1.';de = 'Speichern der Verbindungseinstellungen: %1.';ro = 'Salvarea setărilor de conectare: %1.';tr = 'Bağlantı ayarlarının kaydı: %1.'; es_ES = 'Guardar los ajustes de conexión: %1.'"), ConnectionSettings.ExchangePlanName);
	ExecutionParameters.BackgroundJobKey = BackgroundJobKey;
	ExecutionParameters.RunNotInBackground    = False;
	ExecutionParameters.RunInBackground      = True;
	
	BackgroundJob = TimeConsumingOperations.ExecuteInBackground(
		"DataProcessors.DataExchangeCreationWizard.SaveConnectionSettings",
		ProcedureParameters,
		ExecutionParameters);
		
	OnStartTimeConsumingOperation(BackgroundJob, HandlerParameters, ContinueWait);
	
EndProcedure

// For internal use.
//
Procedure OnWaitForSaveConnectionSettings(HandlerParameters, ContinueWait) Export
	
	OnWaitTimeConsumingOperation(HandlerParameters, ContinueWait);
	
EndProcedure

// For internal use.
//
Procedure OnCompleteSaveConnectionSettings(HandlerParameters, CompletionStatus) Export
	
	OnCompleteTimeConsumingOperation(HandlerParameters, CompletionStatus);
	
EndProcedure

#EndRegion

#Region SaveSynchronizationSettings

// For internal use.
//
Procedure OnStartSaveSynchronizationSettings(SynchronizationSettings, HandlerParameters, ContinueWait = True) Export
	
	ExchangePlanName = DataExchangeCached.GetExchangePlanName(SynchronizationSettings.ExchangeNode);
	
	BackgroundJobKey = BackgroundJobKey(ExchangePlanName,
		NStr("ru = 'Сохранение настроек синхронизации данных'; en = 'Save data synchronization settings'; pl = 'Zapisywanie ustawień synchronizacji danych';de = 'Speichern der Datensynchronisierungseinstellungen';ro = 'Salvarea setărilor de sincronizare a datelor';tr = 'Veri eşleşme ayarlarının kaydı'; es_ES = 'Guardar los ajustes de sincronización de datos'"));

	If HasActiveBackgroundJobs(BackgroundJobKey) Then
		Raise StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Сохранение настроек синхронизации данных для ""%1"" уже выполняется.'; en = 'Saving data synchronization settings for ""%1"" is already in progress.'; pl = 'Zapisywanie ustawień synchronizacji danych dla ""%1"" jest już w toku.';de = 'Das Speichern der Datensynchronisationseinstellungen für ""%1"" wird bereits ausgeführt.';ro = 'Salvarea setărilor de sincronizare a datelor pentru ""%1"" deja se execută.';tr = '""%1"" için veri eşleşme ayarları zaten kaydediliyor.'; es_ES = 'Los ajustes de sincronización de datos para ""%1"" se están guardando.'"), ExchangePlanName);
	EndIf;
		
	ProcedureParameters = New Structure;
	ProcedureParameters.Insert("SynchronizationSettings", SynchronizationSettings);
	
	ExecutionParameters = TimeConsumingOperations.BackgroundExecutionParameters(New UUID);
	ExecutionParameters.BackgroundJobDescription = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("ru = 'Сохранение настроек синхронизации данных: %1.'; en = 'Save data synchronization settings: %1'; pl = 'Zapisywanie ustawień synchronizacji danych: %1.';de = 'Speichern der Datensynchronisierungseinstellungen: %1.';ro = 'Salvarea setărilor de sincronizare a datelor: %1.';tr = 'Veri eşleşme ayarlarının kaydı: %1.'; es_ES = 'Guardar los ajustes de sincronización de datos: %1.'"), ExchangePlanName);
	ExecutionParameters.BackgroundJobKey = BackgroundJobKey;
	ExecutionParameters.RunNotInBackground    = False;
	ExecutionParameters.RunInBackground      = True;
	
	BackgroundJob = TimeConsumingOperations.ExecuteInBackground(
		"DataProcessors.DataExchangeCreationWizard.SaveSynchronizationSettings",
		ProcedureParameters,
		ExecutionParameters);
		
	OnStartTimeConsumingOperation(BackgroundJob, HandlerParameters, ContinueWait);
	
EndProcedure

// For internal use.
//
Procedure OnWaitForSaveSynchronizationSettings(HandlerParameters, ContinueWait) Export
	
	OnWaitTimeConsumingOperation(HandlerParameters, ContinueWait);
	
EndProcedure

// For internal use.
//
Procedure OnCompleteSaveSynchronizationSettings(HandlerParameters, CompletionStatus) Export
	
	OnCompleteTimeConsumingOperation(HandlerParameters, CompletionStatus);
	
EndProcedure

#EndRegion

#Region DeleteDataSynchronizationSetting

// For internal use.
//
Procedure OnStartDeleteSynchronizationSettings(DeletionSettings, HandlerParameters, ContinueWait = True) Export
	
	ExchangePlanName = DataExchangeCached.GetExchangePlanName(DeletionSettings.ExchangeNode);
	
	BackgroundJobKey = BackgroundJobKey(ExchangePlanName,
		NStr("ru = 'Удаление настройки синхронизации данных'; en = 'Delete data synchronization settings'; pl = 'Usuwanie ustawienia synchronizacji danych';de = 'Löschen der Datensynchronisierungseinstellung';ro = 'Ștergerea setării de sincronizare a datelor';tr = 'Veri eşleşme ayarını kaldır'; es_ES = 'Eliminar los ajustes de sincronización de datos'"));

	If HasActiveBackgroundJobs(BackgroundJobKey) Then
		Raise StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Удаление настройки синхронизации данных для ""%1"" уже выполняется.'; en = 'Deletion of data synchronization settings for ""%1"" is already in progress.'; pl = 'Usuwanie ustawienia synchronizacji danych dla ""%1"" jest już w toku.';de = 'Das Löschen der Datensynchronisierungseinstellung für ""%1"" wird bereits ausgeführt.';ro = 'Ștergerea setărilor de sincronizare a datelor pentru ""%1"" deja se execută.';tr = '""%1"" için veri eşleşme ayarları zaten kaldırılıyor.'; es_ES = 'Los ajustes de sincronización de datos para ""%1"" se están eliminando ya.'"), ExchangePlanName);
	EndIf;
		
	ProcedureParameters = New Structure;
	ProcedureParameters.Insert("DeletionSettings", DeletionSettings);
	
	ExecutionParameters = TimeConsumingOperations.BackgroundExecutionParameters(New UUID);
	ExecutionParameters.BackgroundJobDescription = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("ru = 'Удаление настройки синхронизации данных: %1.'; en = 'Delete data synchronization settings: %1'; pl = 'Usuwanie ustawienia synchronizacji danych: %1.';de = 'Löschen der Datensynchronisierungseinstellung: %1.';ro = 'Ștergerea setării de sincronizare a datelor: %1.';tr = 'Veri eşleşme ayarını kaldır:%1'; es_ES = 'Eliminar los ajustes de sincronización de datos: %1'"), ExchangePlanName);
	ExecutionParameters.BackgroundJobKey = BackgroundJobKey;
	ExecutionParameters.RunNotInBackground    = False;
	ExecutionParameters.RunInBackground      = True;
	
	BackgroundJob = TimeConsumingOperations.ExecuteInBackground(
		"DataProcessors.DataExchangeCreationWizard.DeleteSynchronizationSetting",
		ProcedureParameters,
		ExecutionParameters);
		
	OnStartTimeConsumingOperation(BackgroundJob, HandlerParameters, ContinueWait);
	
EndProcedure

// For internal use.
//
Procedure OnWaitForDeleteSynchronizationSettings(HandlerParameters, ContinueWait) Export
	
	OnWaitTimeConsumingOperation(HandlerParameters, ContinueWait);
	
EndProcedure

// For internal use.
//
Procedure OnCompleteDeleteSynchronizationSettings(HandlerParameters, CompletionStatus) Export
	
	OnCompleteTimeConsumingOperation(HandlerParameters, CompletionStatus);
	
EndProcedure

#EndRegion

#Region DataRegistrationForInitialExport

// For internal use.
//
Procedure OnStartRecordDataForInitialExport(RegistrationSettings, HandlerParameters, ContinueWait = True) Export
	
	BackgroundJobKey = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("ru = 'Регистрация данных для начальной выгрузки (%1)'; en = 'Register data for initial export (%1)'; pl = 'Rejestracja danych dla początkowego ładowania (%1)';de = 'Datenregistrierung für den erstmaligen Upload (%1)';ro = 'Înregistrarea datelor pentru exportul inițial (%1)';tr = 'Dışa aktarılacak ilk verilerin kaydı (%1)'; es_ES = 'Registro de datos para subida inicial (%1)'"),
		RegistrationSettings.ExchangeNode);

	If HasActiveBackgroundJobs(BackgroundJobKey) Then
		Raise StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Регистрация данных для начальной выгрузки для ""%1"" уже выполняется.'; en = 'Data registration for initial export for ""%1"" is already in progress.'; pl = 'Rejestracja danych dla początkowego ładowania dla ""%1"" jest już wykonywane.';de = 'Die Datenregistrierung für den ersten Upload für ""%1"" ist bereits in Bearbeitung.';ro = 'Înregistrarea datelor pentru exportul inițial al datelor pentru ""%1"" deja se execută.';tr = '""%1"" için dışa aktarılacak ilk veriler zaten kaydediliyor.'; es_ES = 'Registro de datos para subida inicial para ""%1"" ya se está ejecutando.'"),
			RegistrationSettings.ExchangeNode);
	EndIf;
		
	ProcedureParameters = New Structure;
	ProcedureParameters.Insert("RegistrationSettings", RegistrationSettings);
	
	ExecutionParameters = TimeConsumingOperations.BackgroundExecutionParameters(New UUID);
	ExecutionParameters.BackgroundJobDescription = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("ru = 'Регистрация данных для начальной выгрузки (%1).'; en = 'Register data for initial export (%1)'; pl = 'Rejestracja danych dla początkowego ładowania (%1).';de = 'Datenregistrierung für den erstmaligen Upload (%1).';ro = 'Înregistrarea datelor pentru exportul inițial (%1).';tr = 'Dışa aktarılacak ilk verilerin kaydı (%1).'; es_ES = 'Registro de datos para subida inicial (%1).'"),
		RegistrationSettings.ExchangeNode);
	ExecutionParameters.BackgroundJobKey = BackgroundJobKey;
	ExecutionParameters.RunNotInBackground    = False;
	ExecutionParameters.RunInBackground      = True;
	
	BackgroundJob = TimeConsumingOperations.ExecuteInBackground(
		"DataProcessors.DataExchangeCreationWizard.RegisterDataForInitialExport",
		ProcedureParameters,
		ExecutionParameters);
		
	OnStartTimeConsumingOperation(BackgroundJob, HandlerParameters, ContinueWait);
	
EndProcedure

// For internal use.
//
Procedure OnWaitForRecordDataForInitialExport(HandlerParameters, ContinueWait) Export
	
	OnWaitTimeConsumingOperation(HandlerParameters, ContinueWait);
	
EndProcedure

// For internal use.
//
Procedure OnCompleteDataRecordingForInitialExport(HandlerParameters, CompletionStatus) Export
	
	OnCompleteTimeConsumingOperation(HandlerParameters, CompletionStatus);
	
EndProcedure

#EndRegion

#Region XDTOSettingsImport

// For internal use.
//
Procedure OnStartImportXDTOSettings(ImportSettings, HandlerParameters, ContinueWait = True) Export
	
	BackgroundJobKey = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("ru = 'Загрузка настроек XDTO (%1)'; en = 'Import XDTO settings (%1)'; pl = 'Pobieranie ustawień XDTO (%1)';de = 'Download von XDTO-Einstellungen (%1)';ro = 'Importul setărilor XDTO (%1)';tr = 'XDTO ayarlarının içe aktarılması (%1)'; es_ES = 'Carga de ajustes XDTO (%1)'"),
		ImportSettings.ExchangeNode);

	If HasActiveBackgroundJobs(BackgroundJobKey) Then
		Raise StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Загрузка настроек XDTO для ""%1"" уже выполняется.'; en = 'Import of XDTO settings for ""%1"" is already in progress.'; pl = 'Pobieranie ustawień XDTO  dla ""%1"" jest już w toku.';de = 'Der Download der XDTO-Einstellungen für ""%1"" wird bereits ausgeführt.';ro = 'Importul setărilor XDTO pentru ""%1"" deja se execută.';tr = '""%1"" için XDTO ayarları zaten içe aktarılıyor.'; es_ES = 'Los ajustes XDTO para ""%1"" se están cargando ya.'"),
			ImportSettings.ExchangeNode);
	EndIf;
		
	ProcedureParameters = New Structure;
	ProcedureParameters.Insert("ImportSettings", ImportSettings);
	
	ExecutionParameters = TimeConsumingOperations.BackgroundExecutionParameters(New UUID);
	ExecutionParameters.BackgroundJobDescription = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("ru = 'Загрузка настроек XDTO (%1).'; en = 'Import XDTO settings (%1)'; pl = 'Pobieranie ustawień XDTO (%1).';de = 'Download von XDTO-Einstellungen (%1).';ro = 'Importul setărilor XDTO (%1).';tr = 'XDTO ayarlarının içe aktarılması (%1).'; es_ES = 'Cargar los ajustes XDTO (%1).'"),
		ImportSettings.ExchangeNode);
	ExecutionParameters.BackgroundJobKey = BackgroundJobKey;
	ExecutionParameters.RunNotInBackground    = False;
	ExecutionParameters.RunInBackground      = True;
	
	BackgroundJob = TimeConsumingOperations.ExecuteInBackground(
		"DataProcessors.DataExchangeCreationWizard.ImportXDTOCorrespondentSettings",
		ProcedureParameters,
		ExecutionParameters);
		
	OnStartTimeConsumingOperation(BackgroundJob, HandlerParameters, ContinueWait);
	
EndProcedure

// For internal use.
//
Procedure OnWaitForImportXDTOSettings(HandlerParameters, ContinueWait) Export
	
	OnWaitTimeConsumingOperation(HandlerParameters, ContinueWait);
	
EndProcedure

// For internal use.
//
Procedure OnCompleteImportXDTOSettings(HandlerParameters, CompletionStatus) Export
	
	OnCompleteTimeConsumingOperation(HandlerParameters, CompletionStatus);
	
EndProcedure

#EndRegion

Function DataExchangeSettingsFormatVersion() Export
	
	Return "1.2";
	
EndFunction

// For internal use.
//
Procedure OnStartGetDataExchangeSettingOptions(UUID, HandlerParameters, ContinueWait) Export
	
	StandardSettingsTable = Undefined;
	OnGetAvailableDataSynchronizationSettings(StandardSettingsTable);
	
	HandlerParameters = New Structure;
	HandlerParameters.Insert("ResultAddressDefaultSettings", PutToTempStorage(StandardSettingsTable, UUID));
	
	If Common.SubsystemExists("OnlineUserSupport.DataExchangeWithExternalSystems") Then
		ContinueWait = True;
		
		SettingsOptions = ExternalSystemsDataExchangeSettingsOptionDetails();
		
		ProcedureParameters = New Structure;
		ProcedureParameters.Insert("SettingVariants", SettingsOptions);
		ProcedureParameters.Insert("ExchangeNode",       Undefined);
		
		ExecutionParameters = TimeConsumingOperations.BackgroundExecutionParameters(UUID);
		ExecutionParameters.BackgroundJobDescription = NStr("ru = 'Получение доступных вариантов настроек обмена данными с внешними системами.'; en = 'Get available setting options for data exchange with external systems'; pl = 'Uzyskiwanie dostępnych opcji ustawiania wymiany danych z systemami zewnętrznymi.';de = 'Verfügbare Optionen zum Einstellen des Datenaustauschs mit externen Systemen erhalten.';ro = 'Obținerea variantelor disponibile ale setărilor schimbului de date cu sistemele externe.';tr = 'Harici sistemlerle veri alışverişi için kullanılabilir seçeneklerin elde edilmesi.'; es_ES = 'Recepción de variantes disponibles de ajustes de cambio de datos con sistemas externos.'");
		ExecutionParameters.WaitForCompletion = 0;
		ExecutionParameters.RunInBackground    = True;
		
		BackgroundJob = TimeConsumingOperations.ExecuteInBackground(
			"DataExchangeWithExternalSystems.OnGetDataExchangeSettingsOptions",
			ProcedureParameters,
			ExecutionParameters);
			
		HandlerParameterExternalSystems = Undefined;	
		OnStartTimeConsumingOperation(BackgroundJob, HandlerParameterExternalSystems, ContinueWait);
		
		HandlerParameters.Insert("HandlerParameterExternalSystems", HandlerParameterExternalSystems);
		
	EndIf;
	
EndProcedure

// For internal use.
//
Procedure OnWaitForGetDataExchangeSettingOptions(HandlerParameters, ContinueWait) Export
	
	If HandlerParameters.Property("HandlerParameterExternalSystems") Then
		OnWaitTimeConsumingOperation(HandlerParameters.HandlerParameterExternalSystems, ContinueWait);
	Else
		ContinueWait = False;
	EndIf;
	
EndProcedure

// For internal use.
//
Procedure OnCompleteGetDataExchangeSettingOptions(HandlerParameters, Result) Export
	
	Result = New Structure;
	Result.Insert("DefaultSettings", GetFromTempStorage(HandlerParameters.ResultAddressDefaultSettings));
	
	If HandlerParameters.Property("HandlerParameterExternalSystems") Then
		
		SettingsExternalSystems = New Structure;
		SettingsExternalSystems.Insert("ErrorCode"); // SettingsReceived, NoSettings, Error, OnlineSupportNotConnected
		SettingsExternalSystems.Insert("ErrorMessage");
		SettingsExternalSystems.Insert("SettingVariants");
		
		CompletionStatusExternalSystems = Undefined;
		OnCompleteTimeConsumingOperation(HandlerParameters.HandlerParameterExternalSystems, CompletionStatusExternalSystems);
		
		If CompletionStatusExternalSystems.Cancel Then
			SettingsExternalSystems.ErrorCode = "BackgroundJobError";
			SettingsExternalSystems.ErrorMessage = CompletionStatusExternalSystems.ErrorMessage;
		Else
			FillPropertyValues(SettingsExternalSystems, CompletionStatusExternalSystems.Result);
		EndIf;
		
		Result.Insert("SettingsExternalSystems", SettingsExternalSystems);
		
	EndIf;
	
EndProcedure

Function ExternalSystemsDataExchangeSettingsOptionDetails() Export
	
	SettingsOptions = New ValueTable;
	SettingsOptions.Columns.Add("ExchangePlanName",                                 New TypeDescription("String"));
	SettingsOptions.Columns.Add("SettingID",                         New TypeDescription("String"));
	SettingsOptions.Columns.Add("NewDataExchangeCreationCommandTitle", New TypeDescription("String"));
	SettingsOptions.Columns.Add("ExchangeBriefInfo",                      New TypeDescription("FormattedString"));
	SettingsOptions.Columns.Add("ExchangeDetailedInformation",                    New TypeDescription("String"));
	SettingsOptions.Columns.Add("ExchangeCreateWizardTitle",               New TypeDescription("String"));
	SettingsOptions.Columns.Add("CorrespondentDescription",                     New TypeDescription("String"));
	SettingsOptions.Columns.Add("AttachmentParameters");
	
	Return SettingsOptions;
	
EndFunction

Function SettingOptionDetailsStructure() Export
	
	SettingOptionDetails = New Structure;
	SettingOptionDetails.Insert("NewDataExchangeCreationCommandTitle", "");
	SettingOptionDetails.Insert("ExchangeBriefInfo", New FormattedString(""));
	SettingOptionDetails.Insert("ExchangeDetailedInformation", "");
	SettingOptionDetails.Insert("ExchangeCreateWizardTitle", "");
	SettingOptionDetails.Insert("CorrespondentDescription", "");
	
	Return SettingOptionDetails;
	
EndFunction

#EndRegion

#Region Private

#Region TimeConsumingOperations

// For internal use.
//
Procedure OnStartTimeConsumingOperation(BackgroundJob, HandlerParameters, ContinueWait = True)
	
	InitializeTimeConsumingOperationHandlerParameters(HandlerParameters, BackgroundJob);
	
	If BackgroundJob.Status = "Running" Then
		HandlerParameters.ResultAddress       = BackgroundJob.ResultAddress;
		HandlerParameters.OperationID = BackgroundJob.JobID;
		HandlerParameters.TimeConsumingOperation    = True;
		
		ContinueWait = True;
		Return;
	ElsIf BackgroundJob.Status = "Completed" Then
		HandlerParameters.ResultAddress    = BackgroundJob.ResultAddress;
		HandlerParameters.TimeConsumingOperation = False;
		
		ContinueWait = False;
		Return;
	Else
		HandlerParameters.ErrorMessage = BackgroundJob.BriefErrorPresentation;
		If ValueIsFilled(BackgroundJob.DetailedErrorPresentation) Then
			HandlerParameters.ErrorMessage = BackgroundJob.DetailedErrorPresentation;
		EndIf;
		
		HandlerParameters.Cancel = True;
		HandlerParameters.TimeConsumingOperation = False;
		
		ContinueWait = False;
		Return;
	EndIf;
	
EndProcedure

// For internal use.
//
Procedure OnWaitTimeConsumingOperation(HandlerParameters, ContinueWait = True)
	
	If HandlerParameters.Cancel
		Or Not HandlerParameters.TimeConsumingOperation Then
		ContinueWait = False;
		Return;
	EndIf;
	
	JobCompleted = False;
	Try
		JobCompleted = TimeConsumingOperations.JobCompleted(HandlerParameters.OperationID);
	Except
		HandlerParameters.Cancel             = True;
		HandlerParameters.ErrorMessage = DetailErrorDescription(ErrorInfo());
		
		WriteLogEvent(DataExchangeServer.DataExchangeCreationEventLogEvent(),
			EventLogLevel.Error, , , HandlerParameters.ErrorMessage);
	EndTry;
		
	If HandlerParameters.Cancel Then
		ContinueWait = False;
		Return;
	EndIf;
	
	ContinueWait = Not JobCompleted;
	
EndProcedure

// For internal use.
//
Procedure OnCompleteTimeConsumingOperation(HandlerParameters,
		CompletionStatus = Undefined)
	
	CompletionStatus = New Structure;
	CompletionStatus.Insert("Cancel",             False);
	CompletionStatus.Insert("ErrorMessage", "");
	CompletionStatus.Insert("Result",         Undefined);
	
	If HandlerParameters.Cancel Then
		FillPropertyValues(CompletionStatus, HandlerParameters, "Cancel, ErrorMessage");
	Else
		CompletionStatus.Result = GetFromTempStorage(HandlerParameters.ResultAddress);
	EndIf;
	
	HandlerParameters = Undefined;
		
EndProcedure

Procedure InitializeTimeConsumingOperationHandlerParameters(HandlerParameters, BackgroundJob)
	
	HandlerParameters = New Structure;
	HandlerParameters.Insert("BackgroundJob",          BackgroundJob);
	HandlerParameters.Insert("Cancel",                   False);
	HandlerParameters.Insert("ErrorMessage",       "");
	HandlerParameters.Insert("TimeConsumingOperation",      False);
	HandlerParameters.Insert("OperationID",   Undefined);
	HandlerParameters.Insert("ResultAddress",         Undefined);
	HandlerParameters.Insert("AdditionalParameters", New Structure);
	
EndProcedure

Function BackgroundJobKey(ExchangePlanName, Action)
	
	Return StringFunctionsClientServer.SubstituteParametersToString(
		NStr("ru = 'ПланОбмена:%1 Действие:%2'; en = 'ExchangePlan: %1. Action: %2'; pl = 'PlanWymiany:%1 Działanie:%2';de = 'Austauschplan:%1 Aktion:%2';ro = 'ПланОбмена:%1 Действие:%2';tr = 'AlışverişPlanı: %1 Eylem: %2'; es_ES = 'ПланОбмена:%1 Acción:%2'"), ExchangePlanName, Action);
	
EndFunction

Function HasActiveBackgroundJobs(BackgroundJobKey)
	
	Filter = New Structure;
	Filter.Insert("Key",      BackgroundJobKey);
	Filter.Insert("State", BackgroundJobState.Active);
	
	ActiveBackgroundJobs = BackgroundJobs.GetBackgroundJobs(Filter);
	
	Return (ActiveBackgroundJobs.Count() > 0);
	
EndFunction

#EndRegion

Procedure OnGetAvailableDataSynchronizationSettings(SettingsTable)
	
	SettingsTable = New ValueTable;
	SettingsTable.Columns.Add("ExchangePlanName",                                 New TypeDescription("String"));
	SettingsTable.Columns.Add("SettingID",                         New TypeDescription("String"));
	SettingsTable.Columns.Add("CorrespondentConfigurationName",                  New TypeDescription("String"));
	SettingsTable.Columns.Add("CorrespondentConfigurationDescription",         New TypeDescription("String"));
	SettingsTable.Columns.Add("NewDataExchangeCreationCommandTitle", New TypeDescription("String"));
	SettingsTable.Columns.Add("ExchangeCreateWizardTitle",               New TypeDescription("String"));
	SettingsTable.Columns.Add("ExchangeBriefInfo",                      New TypeDescription("String"));
	SettingsTable.Columns.Add("ExchangeDetailedInformation",                    New TypeDescription("String"));
	SettingsTable.Columns.Add("IsDIBExchangePlan",                               New TypeDescription("Boolean"));
	SettingsTable.Columns.Add("IsXDTOExchangePlan",                              New TypeDescription("Boolean"));
	SettingsTable.Columns.Add("ExchangePlanNameToMigrateToNewExchange",          New TypeDescription("String"));
	
	ExchangePlanList = ExchangePlansForSynchronizationSetup();
	
	For Each ExchangePlanName In ExchangePlanList Do
		
		FillTableWithExchangePlanSettingsOptions(SettingsTable, ExchangePlanName);

	EndDo;
	
	DeleteObsoleteSettingsOptionsSaaS(SettingsTable);
	
EndProcedure

Function ExchangePlansForSynchronizationSetup()
	
	ExchangePlansList = New Array;
	
	IsFullUser = Users.IsFullUser(, True);
	
	SaaSModel = Common.DataSeparationEnabled()
		AND Common.SeparatedDataUsageAvailable();
	
	If SaaSModel Then
		ModuleDataExchangeSaaSCashed = Common.CommonModule("DataExchangeSaaSCached");
		ExchangePlansList = ModuleDataExchangeSaaSCashed.DataSynchronizationExchangePlans();
	Else
		ExchangePlansList = DataExchangeCached.SSLExchangePlans();
	EndIf;
	
	For Ind = -ExchangePlansList.UBound() To 0 Do
		
		ExchangePlanName = ExchangePlansList[-Ind];
		
		If (Not IsFullUser
				AND DataExchangeCached.IsDistributedInfobaseExchangePlan(ExchangePlanName))
			Or Not DataExchangeCached.ExchangePlanUsageAvailable(ExchangePlanName) Then
			// Creating a DIB exchange requires system administrator rights.
			ExchangePlansList.Delete(-Ind);
		EndIf;
		
	EndDo;
	
	Return ExchangePlansList;
	
EndFunction

Procedure FillTableWithExchangePlanSettingsOptions(SettingsTable, ExchangePlanName)
	
	ExchangeSettings = DataExchangeServer.ExchangePlanSettingValue(ExchangePlanName,
		"ExchangeSettingsOptions, ExchangePlanNameToMigrateToNewExchange");
	
	For Each SetupOption In ExchangeSettings.ExchangeSettingsOptions Do
		PredefinedSetting = SetupOption.SettingID;
		
		SettingsValuesForOption = DataExchangeServer.ExchangePlanSettingValue(ExchangePlanName,
			"UseDataExchangeCreationWizard,
			|CorrespondentConfigurationName,
			|CorrespondentConfigurationDescription,
			|NewDataExchangeCreationCommandTitle,
			|ExchangeCreateWizardTitle,
			|ExchangeBriefInfo,
			|ExchangeDetailedInformation",
			PredefinedSetting);
			
		If Not SettingsValuesForOption.UseDataExchangeCreationWizard Then
			Continue;
		EndIf;
		
		SettingString = SettingsTable.Add();
		FillPropertyValues(SettingString, SettingsValuesForOption);
		
		SettingString.ExchangePlanName = ExchangePlanName;
		SettingString.SettingID = PredefinedSetting;
		SettingString.IsDIBExchangePlan  = DataExchangeCached.IsDistributedInfobaseExchangePlan(ExchangePlanName);
		SettingString.IsXDTOExchangePlan = DataExchangeCached.IsXDTOExchangePlan(ExchangePlanName);
		SettingString.ExchangePlanNameToMigrateToNewExchange = ExchangeSettings.ExchangePlanNameToMigrateToNewExchange;
		
	EndDo;
	
EndProcedure

Procedure DeleteObsoleteSettingsOptionsSaaS(SettingsTable)
	
	SaaSModel = Common.DataSeparationEnabled()
		AND Common.SeparatedDataUsageAvailable();
		
	If Not SaaSModel Then
		Return;
	EndIf;
	
	XTDOExchangePlans     = New Array;
	ObsoleteSettings = New Array;
	
	For Each SettingString In SettingsTable Do
		If SettingString.IsXDTOExchangePlan Then
			If XTDOExchangePlans.Find(SettingString.ExchangePlanName) = Undefined Then
				XTDOExchangePlans.Add(SettingString.ExchangePlanName);
			EndIf;
			Continue;
		EndIf;
		If Not ValueIsFilled(SettingString.ExchangePlanNameToMigrateToNewExchange) Then
			Continue;
		EndIf;
		ObsoleteSettings.Add(SettingString);
	EndDo;
	
	XDTOSettingsTable = SettingsTable.Copy(New Structure("IsXDTOExchangePlan", True));
	
	SettingsForDelete = New Array;
	For Each SettingString In ObsoleteSettings Do
		For Each XTDOExchangePlan In XTDOExchangePlans Do
			SetupOption = DataExchangeServer.ExchangeSettingOptionForCorrespondent(
				XTDOExchangePlan, SettingString.CorrespondentConfigurationName);
			If Not ValueIsFilled(SetupOption) Then
				Continue;
			EndIf;
			XDTOSettings = XDTOSettingsTable.FindRows(New Structure("SettingID", SetupOption));	
			If XDTOSettings.Count() > 0 Then
				SettingsForDelete.Add(SettingString);
				Break;
			EndIf;
		EndDo;
	EndDo;
	
	For Cnt = 1 To SettingsForDelete.Count() Do
		SettingsTable.Delete(SettingsForDelete[Cnt - 1]);
	EndDo;
	
EndProcedure

Procedure OnConnectToCorrespondent(Cancel, ExchangePlanName, Val CorrespondentVersion, ErrorMessage = "")
	
	If Not ValueIsFilled(CorrespondentVersion) Then
		CorrespondentVersion = "0.0.0.0";
	EndIf;

	Try
		DataExchangeServer.OnConnectToCorrespondent(ExchangePlanName, CorrespondentVersion);
	Except
		ErrorMessage = DetailErrorDescription(ErrorInfo());
		
		WriteLogEvent(DataExchangeServer.DataExchangeCreationEventLogEvent(),
			EventLogLevel.Error, , , StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'При выполнении обработчика ПриПодключенииККорреспонденту произошла ошибка:%1%2'; en = 'OnConnectToCorrespondent handler error:%1%2'; pl = 'Wystąpił błąd podczas wykonywania programu serwisu OnConnectingToCorrespondent:%1%2';de = 'Beim Ausführen des Anwenders BeiVerbindungMitKorrespondent ist ein Fehler aufgetreten:%1%2';ro = 'Eroare la executarea handlerului OnConnectingToCorrespondent:%1%2';tr = 'MuhabireBağlandığında işleyicisini yürütürken bir hata oluştu: %1%2'; es_ES = 'Ha ocurrido un error al ejecutar el manipulador OnConnectingToCorrespondent:%1%2'"),
				Chars.LF, ErrorMessage));
				
		Cancel = True;
	EndTry;
	
EndProcedure

Procedure TestCorrespondentConnection(Parameters, ResultAddress) Export
	
	ConnectionSettings = Undefined;
	Parameters.Property("ConnectionSettings", ConnectionSettings);
	
	CheckResult = New Structure;
	CheckResult.Insert("ConnectionIsSet", False);
	CheckResult.Insert("ConnectionAllowed",   False);
	CheckResult.Insert("InterfaceVersions",       Undefined);
	CheckResult.Insert("ErrorMessage",      "");
	
	CheckResult.Insert("CorrespondentParametersReceived", False);
	CheckResult.Insert("CorrespondentParameters",         Undefined);
	
	If ConnectionSettings.ExchangeMessagesTransportKind = Enums.ExchangeMessagesTransportTypes.COM Then
		
		Result = DataExchangeServer.EstablishExternalConnectionWithInfobase(ConnectionSettings);
		
		ExternalConnection = Result.Connection;
		If ExternalConnection = Undefined Then
			CheckResult.ErrorMessage = Result.BriefErrorDescription;
			CheckResult.ConnectionIsSet = False;
			
			PutToTempStorage(CheckResult, ResultAddress);
			Return;
		EndIf;
		
		CheckResult.ConnectionIsSet = True;
		CheckResult.InterfaceVersions = DataExchangeServer.InterfaceVersionsThroughExternalConnection(ExternalConnection);
		
		If CheckResult.InterfaceVersions.Find("3.0.1.1") <> Undefined Then
			
			ErrorMessage = "";
			InfobaseParameters = ExternalConnection.DataExchangeExternalConnection.GetInfobaseParameters_2_0_1_6(
				ConnectionSettings.ExchangePlanName, "", ErrorMessage);
				
			CorrespondentParameters = Common.ValueFromXMLString(InfobaseParameters);
			If Not CorrespondentParameters.ExchangePlanExists Then
				CheckResult.ErrorMessage = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("ru = 'В корреспонденте не найден план обмена ""%1"".
					|Убедитесь, что
					| - выбран правильный вид приложения для настройки обмена;
					| - корректно указано расположение программы, к которой выполняется подключение.'; 
					|en = 'Exchange plan ""%1"" is not found in the peer application.
					|Ensure that the following data is correct:
					|- The application type selected in the exchange settings.
					|- The application location specified in the connection settings.'; 
					|pl = 'W korespondencie nie znaleziono planu wymiany ""%1"".
					|Przekonaj się, że
					| - wybrano właściwy rodzaj aplikacji dla ustawienia wymiany;
					| - prawidłowo określono lokalizację programu, do którego wykonywane jest połączenie.';
					|de = 'Es gibt keinen Austauschplan im Korrespondenten""%1"".
					| Stellen Sie sicher, dass
					| - die richtige Art der Anwendung für die Einrichtung der Vermittlungsstelle ausgewählt ist;
					| - der Standort des Programms, zu dem die Verbindung hergestellt wird, korrekt angegeben ist.';
					|ro = 'În corespondent nu a fost găsit planul de schimb ""%1"".
					|Convingeți-vă că
					| - este selectat tipul corect de aplicație pentru setarea schimbului;
					| - este indicată corect locația programului la care se execută corectarea.';
					|tr = 'Muhabirde ""%1"" alışveriş planı bulunamadı. 
					| - 
					|Veri alışverişini yapılandırmak için uygulamanın türü doğru seçildiğinden; 
					|- bağlantının yapıldığı programın konumunun doğru belirtildiğinden emin olun.'; 
					|es_ES = 'En el correspondiente no se ha encontrado un plan de cambio ""%1"".
					|Asegúrese que
					| - se ha seleccionado un tipo correcto de la aplicación para ajustar el cambio;
					| - se ha indicado correctamente la situación del programa en el que se está realizando la conexión.'"),
					ConnectionSettings.ExchangePlanName);
					
				PutToTempStorage(CheckResult, ResultAddress);
				Return;
			EndIf;
				
			CheckResult.CorrespondentParametersReceived = True;
			CheckResult.CorrespondentParameters =	CorrespondentParameters;
			
		Else
			
			CheckResult.ConnectionAllowed = False;
			CheckResult.ErrorMessage = NStr("ru = 'Корреспондент не поддерживает версию 3.0.1.1 интерфейса ""ОбменДанными"".
			|Для настройки подключения необходимо обновить конфигурацию корреспондента, или начать настройку из него.'; 
			|en = 'The peer does not support DataExchange interface version 3.0.1.1.
			|To configure connection, update the peer application''s configuration or start configuring the connection from the peer application.'; 
			|pl = 'Korespondent nie obsługuje interfejsu DataExchange w wersji 3.0.1.1.
			|Aby skonfigurować połączenie, zaktualizuj odpowiednią konfigurację lub rozpocznij od niej konfigurację.';
			|de = 'Der Empfänger unterstützt die DataExchange-Schnittstelle Version 3.0.1.1.1 nicht.
			|Um eine Verbindung herzustellen, aktualisieren Sie die entsprechende Konfiguration oder starten Sie die Einrichtung von ihr aus.';
			|ro = 'Corespondentul nu suportă interfața DataExchange versiunea 3.0.1.1.
			|Pentru a configura conexiunea, actualizați configurația corespondentă sau începeți să o configurați.';
			|tr = 'Muhabir, VeriDeğişimi arayüzü 3.0.1.1 sürümünü desteklemiyor
			|. Bağlantı kurmak için ilgili yapılandırmayı güncelleyin veya buradan kurmaya başlayın.'; 
			|es_ES = 'El correspondiente no admite la versión 3.0.1.1 de la interfaz DataExchange.
			|Para ajustar la conexión es necesario actualizar la configuración del correspondiente o empezar a ajustar sin él.'");
			
			PutToTempStorage(CheckResult, ResultAddress);
			Return;
			
		EndIf;
		
		Cancel = False;
		ErrorMessage = "";
		
		OnConnectToCorrespondent(Cancel, ConnectionSettings.ExchangePlanName,
			CheckResult.CorrespondentParameters.ConfigurationVersion, ErrorMessage);
			
		If Cancel Then
			CheckResult.ConnectionAllowed = False;
			CheckResult.ErrorMessage = ErrorMessage;
			
			PutToTempStorage(CheckResult, ResultAddress);
			Return;
		EndIf;
		
		CheckResult.ConnectionAllowed = True;
		
	ElsIf ConnectionSettings.ExchangeMessagesTransportKind = Enums.ExchangeMessagesTransportTypes.WS Then
		
		Correspondent = New Structure("WSWebServiceURL, WSUsername, WSPassword");
		FillPropertyValues(Correspondent, ConnectionSettings);
		
		Try
			CheckResult.InterfaceVersions = DataExchangeCached.CorrespondentVersions(Correspondent);
		Except
			CheckResult.ErrorMessage = DetailErrorDescription(ErrorInfo());
			CheckResult.ConnectionIsSet = False;
			
			WriteLogEvent(DataExchangeServer.DataExchangeCreationEventLogEvent(),
				EventLogLevel.Error, , , CheckResult.ErrorMessage);
			
			PutToTempStorage(CheckResult, ResultAddress);
			Return;
		EndTry;
		
		ErrorMessageString = "";
		WSProxy = Undefined;
		If CheckResult.InterfaceVersions.Find("3.0.1.1") <> Undefined Then
			
			WSProxy = DataExchangeServer.GetWSProxy_3_0_1_1(Correspondent, ErrorMessageString);
			
		ElsIf CheckResult.InterfaceVersions.Find("2.1.1.7") <> Undefined Then
			
			WSProxy = DataExchangeServer.GetWSProxy_2_1_1_7(Correspondent, ErrorMessageString);
			
		ElsIf CheckResult.InterfaceVersions.Find("2.0.1.6") <> Undefined Then
			
			WSProxy = DataExchangeServer.GetWSProxy_2_0_1_6(Correspondent, ErrorMessageString);
			
		Else
			
			WSProxy = DataExchangeServer.GetWSProxy(Correspondent, ErrorMessageString);
			
		EndIf;
		
		If WSProxy = Undefined Then
			CheckResult.ConnectionIsSet = False;
			CheckResult.ErrorMessage = ErrorMessageString;
			
			PutToTempStorage(CheckResult, ResultAddress);
			Return;
		EndIf;
		
		CheckResult.ConnectionIsSet = True;
		
		If CheckResult.InterfaceVersions.Find("3.0.1.1") <> Undefined Then
			
			ErrorMessage = "";
			InfobaseParameters = WSProxy.GetIBParameters(ConnectionSettings.ExchangePlanName, "", ErrorMessage);
			
			CorrespondentParameters = XDTOSerializer.ReadXDTO(InfobaseParameters);
			If Not CorrespondentParameters.ExchangePlanExists Then
				CheckResult.ErrorMessage = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("ru = 'В корреспонденте не найден план обмена ""%1"".
					|Убедитесь, что
					| - выбран правильный вид приложения для настройки обмена;
					| - указан правильный адрес приложения в Интернете.'; 
					|en = 'Exchange plan ""%1"" is not found in the peer application.
					|Ensure that the following data is correct:
					|- The application type selected in the exchange settings.
					|- The web application address.'; 
					|pl = 'W korespondencie nie znaleziono planu wymiany ""%1"".
					|Przekonaj się, że
					| - wybrano właściwy rodzaj aplikacji dla ustawienia wymiany;
					| - podano poprawny adres aplikacji w Internecie.';
					|de = 'Es gibt keinen Austauschplan im Korrespondenten ""%1"".
					|Stellen Sie sicher, dass
					| - der richtige Anwendungstyp für die Einrichtung der Vermittlungsstelle ausgewählt ist;
					| - die richtige Internetadresse der Anwendung angegeben ist.';
					|ro = 'În corespondent nu a fost găsit planul de schimb ""%1"".
					|Convingeți-vă că
					| - este selectat tipul corect de aplicație pentru setarea schimbului;
					| - este indicată corect adresa aplicației în Internet.';
					|tr = 'Muhabirde ""%1"" alışveriş planı bulunamadı. 
					| - 
					|Veri alışverişini yapılandırmak için uygulamanın türü doğru seçildiğinden; 
					|- bağlantının yapıldığı programın İnternet''teki konumunun doğru belirtildiğinden emin olun.'; 
					|es_ES = 'En el correspondiente no se ha encontrado un plan de cambio ""%1"".
					|Asegúrese de que
					|- se ha seleccionado un tipo correcto de actualización para ajustar el cambio;
					| - se ha indicado dirección correcta de la aplicación en Internet.'"),
					ConnectionSettings.ExchangePlanName);
				
				PutToTempStorage(CheckResult, ResultAddress);
				Return;
			EndIf;
			
			CheckResult.CorrespondentParametersReceived = True;
			CheckResult.CorrespondentParameters = CorrespondentParameters;
			
		Else
			
			CheckResult.ConnectionAllowed = False;
			CheckResult.ErrorMessage = NStr("ru = 'Корреспондент не поддерживает версию 3.0.1.1 интерфейса ""ОбменДанными"".
			|Для настройки подключения необходимо обновить конфигурацию корреспондента, или начать настройку из него.'; 
			|en = 'The peer does not support DataExchange interface version 3.0.1.1.
			|To configure connection, update the peer application''s configuration or start configuring the connection from the peer application.'; 
			|pl = 'Korespondent nie obsługuje interfejsu DataExchange w wersji 3.0.1.1.
			|Aby skonfigurować połączenie, zaktualizuj odpowiednią konfigurację lub rozpocznij od niej konfigurację.';
			|de = 'Der Empfänger unterstützt die DataExchange-Schnittstelle Version 3.0.1.1.1 nicht.
			|Um eine Verbindung herzustellen, aktualisieren Sie die entsprechende Konfiguration oder starten Sie die Einrichtung von ihr aus.';
			|ro = 'Corespondentul nu suportă interfața DataExchange versiunea 3.0.1.1.
			|Pentru a configura conexiunea, actualizați configurația corespondentă sau începeți să o configurați.';
			|tr = 'Muhabir, VeriDeğişimi arayüzü 3.0.1.1 sürümünü desteklemiyor
			|. Bağlantı kurmak için ilgili yapılandırmayı güncelleyin veya buradan kurmaya başlayın.'; 
			|es_ES = 'El correspondiente no admite la versión 3.0.1.1 de la interfaz DataExchange.
			|Para ajustar la conexión es necesario actualizar la configuración del correspondiente o empezar a ajustar sin él.'");
			
			PutToTempStorage(CheckResult, ResultAddress);
			Return;
			
		EndIf;
		
		Cancel = False;
		ErrorMessage = "";
		
		OnConnectToCorrespondent(Cancel, ConnectionSettings.ExchangePlanName,
			CheckResult.CorrespondentParameters.ConfigurationVersion, ErrorMessage);
			
		If Cancel Then
			CheckResult.ConnectionAllowed = False;
			CheckResult.ErrorMessage = ErrorMessage;
			
			PutToTempStorage(CheckResult, ResultAddress);
			Return;
		EndIf;
		
		CheckResult.ConnectionAllowed = True;
		
	ElsIf ConnectionSettings.ExchangeMessagesTransportKind = Enums.ExchangeMessagesTransportTypes.FILE
		Or ConnectionSettings.ExchangeMessagesTransportKind = Enums.ExchangeMessagesTransportTypes.FTP
		Or ConnectionSettings.ExchangeMessagesTransportKind = Enums.ExchangeMessagesTransportTypes.EMAIL Then
		
		Cancel = False;
		ErrorMessage = "";
		
		DataExchangeServer.CheckExchangeMessageTransportDataProcessorAttachment(Cancel,
			ConnectionSettings, ConnectionSettings.ExchangeMessagesTransportKind, ErrorMessage);
			
		If Cancel Then
			CheckResult.ConnectionIsSet = False;
			CheckResult.ErrorMessage = ErrorMessage;
			
			PutToTempStorage(CheckResult, ResultAddress);
			Return;
		EndIf;
		
		CheckResult.ConnectionIsSet = True;
		CheckResult.ConnectionAllowed   = True;
		
	EndIf;
	
	PutToTempStorage(CheckResult, ResultAddress);
	
EndProcedure

Procedure SaveConnectionSettings(Parameters, ResultAddress) Export
	
	ConnectionSettings = Undefined;
	Parameters.Property("ConnectionSettings", ConnectionSettings);
	
	Result = New Structure;
	Result.Insert("ConnectionSettingsSaved", False);
	Result.Insert("HasDataToMap",    False); // For offline transport only.
	Result.Insert("ExchangeNode",                    Undefined);
	Result.Insert("ErrorMessage",             "");
	Result.Insert("XMLConnectionSettingsString",  "");
	
	// 1. Saving the node and connection settings to the infobase.
	Cancel = False;
	Try
		ConfigureDataExchange(ConnectionSettings);
	Except
		Cancel = True;
		Result.ErrorMessage = DetailErrorDescription(ErrorInfo());
		
		WriteLogEvent(DataExchangeServer.DataExchangeCreationEventLogEvent(),
			EventLogLevel.Error, , , Result.ErrorMessage);
	EndTry;
	
	If Cancel Then
		PutToTempStorage(Result, ResultAddress);
		Return;
	EndIf;
	
	// 2. Saving connection settings for correspondent.
	If Not ConnectionSettings.WizardRunOption = "ContinueDataExchangeSetup" Then
		If DataExchangeCached.IsDistributedInfobaseExchangePlan(ConnectionSettings.ExchangePlanName) Then
			ExportConnectionSettingsForSubordinateDIBNode(ConnectionSettings);
		Else
			Result.XMLConnectionSettingsString = ConnectionSettingsInXML(ConnectionSettings);
		EndIf;
	EndIf;
	
	// 3. Saving connection settings at the correspondent side for online connection, or sending a 
	//    message with XDTO settings for offline connection.
	If ConnectionSettings.ExchangeMessagesTransportKind = Enums.ExchangeMessagesTransportTypes.COM Then
		
		Connection = DataExchangeServer.EstablishExternalConnectionWithInfobase(ConnectionSettings);
		Result.ErrorMessage = Connection.DetailedErrorDescription;
		ExternalConnection           = Connection.Connection;
		
		If ExternalConnection = Undefined Then
			Cancel = True;
		Else
			
			CorrespondentConnectionSettings = ExternalConnection.DataProcessors.DataExchangeCreationWizard.Create();
			
			CorrespondentConnectionSettings.WizardRunOption   = "ContinueDataExchangeSetup";
			CorrespondentConnectionSettings.ExchangeSettingsOption = ConnectionSettings.ExchangeSettingsOption;
			
			CorrespondentConnectionSettings.ExchangePlanName               = ConnectionSettings.CorrespondentExchangePlanName;
			CorrespondentConnectionSettings.CorrespondentExchangePlanName = ConnectionSettings.ExchangePlanName;
			CorrespondentConnectionSettings.ExchangeFormat                 = ConnectionSettings.ExchangeFormat;
			
			CorrespondentConnectionSettings.UsePrefixesForExchangeSettings =
				ConnectionSettings.UsePrefixesForCorrespondentExchangeSettings;
			
			CorrespondentConnectionSettings.UsePrefixesForCorrespondentExchangeSettings =
				ConnectionSettings.UsePrefixesForExchangeSettings;
				
			CorrespondentConnectionSettings.SourceInfobasePrefix = ConnectionSettings.DestinationInfobasePrefix;
			CorrespondentConnectionSettings.DestinationInfobasePrefix = ConnectionSettings.SourceInfobasePrefix;
			
			Try
			
				ExternalConnection.DataProcessors.DataExchangeCreationWizard.FillConnectionSettingsFromXMLString(
					CorrespondentConnectionSettings, Result.XMLConnectionSettingsString);
					
			Except
				Cancel = True;
				Result.ErrorMessage = DetailErrorDescription(ErrorInfo());
				
				WriteLogEvent(DataExchangeServer.DataExchangeCreationEventLogEvent(),
					EventLogLevel.Error, , , Result.ErrorMessage);
			EndTry;
				
			If Not Cancel Then
			
				If DataExchangeCached.IsXDTOExchangePlan(ConnectionSettings.ExchangePlanName) Then
					CorrespondentConnectionSettings.ExchangeFormatVersion = ConnectionSettings.ExchangeFormatVersion;
					
					ObjectsTable = DataExchangeXDTOServer.SupportedObjectsInFormat(
						ConnectionSettings.ExchangePlanName, "SendGet", ConnectionSettings.InfobaseNode);
					
					StorageString = XDTOSerializer.XMLString(
						New ValueStorage(ObjectsTable, New Deflation(9)));
						
					CorrespondentConnectionSettings.SupportedObjectsInFormat = ExternalConnection.XDTOSerializer.XMLValue(
						ExternalConnection.NewObject("TypeDescription", "ValueStorage").Types().Get(0), StorageString);
				EndIf;
					
				Try
					
					ExternalConnection.DataExchangeServer.CheckDataExchangeUsage(True);
					
					ExternalConnection.DataProcessors.DataExchangeCreationWizard.ConfigureDataExchange(
						CorrespondentConnectionSettings);
				Except
					Cancel = True;
					Result.ErrorMessage = DetailErrorDescription(ErrorInfo());
					
					WriteLogEvent(DataExchangeServer.DataExchangeCreationEventLogEvent(),
						EventLogLevel.Error, , , Result.ErrorMessage);
				EndTry;
					
			EndIf;
				
		EndIf;
		
	ElsIf ConnectionSettings.ExchangeMessagesTransportKind = Enums.ExchangeMessagesTransportTypes.WS Then
		
		WSProxy = DataExchangeServer.GetWSProxy_3_0_1_1(ConnectionSettings);
		
		If WSProxy = Undefined Then
			Cancel = True;
		Else
			CorrespondentConnectionSettings = New Structure;
			For Each SettingItem In ConnectionSettings Do
				CorrespondentConnectionSettings.Insert(SettingItem.Key);
			EndDo;
			
			CorrespondentConnectionSettings.WizardRunOption   = "ContinueDataExchangeSetup";
			CorrespondentConnectionSettings.ExchangeSettingsOption = ConnectionSettings.ExchangeSettingsOption;
			
			CorrespondentConnectionSettings.ExchangePlanName               = ConnectionSettings.CorrespondentExchangePlanName;
			CorrespondentConnectionSettings.CorrespondentExchangePlanName = ConnectionSettings.ExchangePlanName;
			CorrespondentConnectionSettings.ExchangeFormat                 = ConnectionSettings.ExchangeFormat;
			
			CorrespondentConnectionSettings.UsePrefixesForExchangeSettings =
				ConnectionSettings.UsePrefixesForCorrespondentExchangeSettings;
			
			CorrespondentConnectionSettings.UsePrefixesForCorrespondentExchangeSettings =
				ConnectionSettings.UsePrefixesForExchangeSettings;
				
			CorrespondentConnectionSettings.SourceInfobasePrefix = ConnectionSettings.DestinationInfobasePrefix;
			CorrespondentConnectionSettings.DestinationInfobasePrefix = ConnectionSettings.SourceInfobasePrefix;
			
			If DataExchangeCached.IsXDTOExchangePlan(ConnectionSettings.ExchangePlanName) Then
				CorrespondentConnectionSettings.ExchangeFormatVersion = ConnectionSettings.ExchangeFormatVersion;
				
				ObjectsTable = DataExchangeXDTOServer.SupportedObjectsInFormat(
						ConnectionSettings.ExchangePlanName, "SendGet", ConnectionSettings.InfobaseNode);
				
				CorrespondentConnectionSettings.SupportedObjectsInFormat = New ValueStorage(ObjectsTable, New Deflation(9));
			EndIf;
				
			Serializer = New XDTOSerializer(WSProxy.XDTOFactory);
			
			ConnectionParameters = New Structure;
			ConnectionParameters.Insert("ConnectionSettings", CorrespondentConnectionSettings);
			ConnectionParameters.Insert("XMLParametersString",  Result.XMLConnectionSettingsString);
			
			Try
				WSProxy.CreateExchangeNode(Serializer.WriteXDTO(ConnectionParameters));
			Except
				Cancel = True;
				Result.ErrorMessage = DetailErrorDescription(ErrorInfo());
				
				WriteLogEvent(DataExchangeServer.DataExchangeCreationEventLogEvent(),
					EventLogLevel.Error, , , Result.ErrorMessage);
			EndTry;
			
		EndIf;
		
	ElsIf ConnectionSettings.ExchangeMessagesTransportKind = Enums.ExchangeMessagesTransportTypes.FILE
		Or ConnectionSettings.ExchangeMessagesTransportKind = Enums.ExchangeMessagesTransportTypes.FTP
		Or ConnectionSettings.ExchangeMessagesTransportKind = Enums.ExchangeMessagesTransportTypes.EMAIL Then
		
		If DataExchangeCached.IsXDTOExchangePlan(ConnectionSettings.ExchangePlanName) Then
			
			If ConnectionSettings.WizardRunOption = "ContinueDataExchangeSetup" Then
				// Getting an exchange message with XDTO settings.
				ExchangeParameters = DataExchangeServer.ExchangeParameters();
				ExchangeParameters.ExecuteImport = True;
				ExchangeParameters.ExecuteExport = False;
				ExchangeParameters.ExchangeMessagesTransportKind = ConnectionSettings.ExchangeMessagesTransportKind;
				
				// To set up synchronization, an error in receiving messages via normal communication channels is 
				// not critical (basically, it is possible to have no exchange message).
				CancelReceipt = False;
				AdditionalParameters = New Structure;
				Try
					DataExchangeServer.ExecuteDataExchangeForInfobaseNode(
						ConnectionSettings.InfobaseNode, ExchangeParameters, CancelReceipt, AdditionalParameters);
				Except
					// An exception is critical for saving the setting.
					// There must be no exceptions.
					Cancel = True; 
					Result.ErrorMessage = DetailErrorDescription(ErrorInfo());
					
					WriteLogEvent(DataExchangeServer.DataExchangeCreationEventLogEvent(),
						EventLogLevel.Error, , , Result.ErrorMessage);
				EndTry;
				
				If AdditionalParameters.Property("DataReceivedForMapping") Then
					Result.HasDataToMap = AdditionalParameters.DataReceivedForMapping;
				EndIf;
			Else
				// Sending an exchange message with XDTO settings.
				ExchangeParameters = DataExchangeServer.ExchangeParameters();
				ExchangeParameters.ExecuteImport = False;
				ExchangeParameters.ExecuteExport = True;
				ExchangeParameters.ExchangeMessagesTransportKind = ConnectionSettings.ExchangeMessagesTransportKind;
				
				Try
					DataExchangeServer.ExecuteDataExchangeForInfobaseNode(
						ConnectionSettings.InfobaseNode, ExchangeParameters, Cancel);
				Except
					Cancel = True;
					Result.ErrorMessage = DetailErrorDescription(ErrorInfo());
					
					WriteLogEvent(DataExchangeServer.DataExchangeCreationEventLogEvent(),
						EventLogLevel.Error, , , Result.ErrorMessage);
				EndTry;
			EndIf;
			
		ElsIf Not DataExchangeCached.IsDistributedInfobaseExchangePlan(ConnectionSettings.ExchangePlanName)
			AND Not DataExchangeCached.IsStandardDataExchangeNode(ConnectionSettings.ExchangePlanName) Then
			
			ExchangeSettingsStructure = DataExchangeCached.TransportSettingsOfExchangePlanNode(
				ConnectionSettings.InfobaseNode, ConnectionSettings.ExchangeMessagesTransportKind);
				
			ExchangeMessageTransportDataProcessor = ExchangeSettingsStructure.ExchangeMessageTransportDataProcessor;
			
			If ExchangeMessageTransportDataProcessor.ConnectionIsSet() Then
				
				Result.HasDataToMap = ExchangeMessageTransportDataProcessor.GetMessage(True);
				
				If Not Result.HasDataToMap Then
					// Probably the file can be received if you apply the virtual code (alias) of the node.
					Transliteration = Undefined;
					If ExchangeSettingsStructure.ExchangeTransportKind = Enums.ExchangeMessagesTransportTypes.FILE Then
						ExchangeSettingsStructure.TransportSettings.Property("FILETransliterateExchangeMessageFileNames", Transliteration);
					ElsIf ExchangeSettingsStructure.ExchangeTransportKind = Enums.ExchangeMessagesTransportTypes.EMAIL Then
						ExchangeSettingsStructure.TransportSettings.Property("EMAILTransliterateExchangeMessageFileNames", Transliteration);
					ElsIf ExchangeSettingsStructure.ExchangeTransportKind = Enums.ExchangeMessagesTransportTypes.FTP Then
						ExchangeSettingsStructure.TransportSettings.Property("FTPTransliterateExchangeMessageFileNames", Transliteration);
					EndIf;
					Transliteration = ?(Transliteration = Undefined, False, Transliteration);
					
					FileNameTemplatePrevious = ExchangeSettingsStructure.ExchangeMessageTransportDataProcessor.MessageFileNamePattern;
					ExchangeSettingsStructure.ExchangeMessageTransportDataProcessor.MessageFileNamePattern = DataExchangeServer.MessageFileNamePattern(
						ExchangeSettingsStructure.CurrentExchangePlanNode,
						ExchangeSettingsStructure.InfobaseNode,
						False,
						Transliteration, 
						True);
						
					If FileNameTemplatePrevious <> ExchangeSettingsStructure.ExchangeMessageTransportDataProcessor.MessageFileNamePattern Then
						Result.HasDataToMap = ExchangeMessageTransportDataProcessor.GetMessage(True);
					EndIf;
					
				EndIf;
				
			EndIf;
				
		EndIf;
		
	EndIf;
	
	If Not Cancel Then
		Result.ConnectionSettingsSaved = True;
		Result.ExchangeNode = ConnectionSettings.InfobaseNode;
	Else
		DataExchangeServer.DeleteSynchronizationSetting(ConnectionSettings.InfobaseNode);
		
		Result.ConnectionSettingsSaved = False;
		Result.ExchangeNode = Undefined;
	EndIf;
	
	PutToTempStorage(Result, ResultAddress);
	
EndProcedure

Procedure ImportXDTOCorrespondentSettings(Parameters, ResultAddress) Export
	
	ImportSettings = Undefined;
	Parameters.Property("ImportSettings", ImportSettings);
	
	Result = New Structure;
	Result.Insert("SettingsImported",             True);
	Result.Insert("DataReceivedForMapping", False);
	Result.Insert("ErrorMessage",              "");
	
	// Getting an exchange message with XDTO settings.
	ExchangeParameters = DataExchangeServer.ExchangeParameters();
	ExchangeParameters.ExecuteImport = True;
	ExchangeParameters.ExecuteExport = False;
	ExchangeParameters.ExchangeMessagesTransportKind =
		InformationRegisters.DataExchangeTransportSettings.DefaultExchangeMessagesTransportKind(ImportSettings.ExchangeNode);
		
	AdditionalParameters = New Structure;
	
	Cancel = False;
	Try
		DataExchangeServer.ExecuteDataExchangeForInfobaseNode(
			ImportSettings.ExchangeNode, ExchangeParameters, Cancel, AdditionalParameters);
	Except
		Cancel = True;
		Result.ErrorMessage = DetailErrorDescription(ErrorInfo());
		
		WriteLogEvent(DataExchangeServer.DataExchangeCreationEventLogEvent(),
			EventLogLevel.Error, , , Result.ErrorMessage);
	EndTry;
		
	If Cancel Then
		Result.SettingsImported = False; 
		If IsBlankString(Result.ErrorMessage) Then
			Result.ErrorMessage = NStr("ru = 'Не удалось получить параметры корреспондента.'; en = 'Cannot get peer application parameters.'; pl = 'Nie udało się uzyskać parametry korespondenta.';de = 'Die Parameter des Empfängers konnten nicht empfangen werden.';ro = 'Eșec la obținerea parametrilor corespondentului.';tr = 'Muhabirin parametreleri alınamadı.'; es_ES = 'No se ha podido recibir parámetros del correspondiente.'");
		EndIf;
	Else
		CorrespondentSettings = DataExchangeXDTOServer.SupportedCorrespondentFormatObjects(
			ImportSettings.ExchangeNode, "SendGet");
		Result.SettingsImported = (CorrespondentSettings.Count() > 0);
		
		If Result.SettingsImported Then
			If AdditionalParameters.Property("DataReceivedForMapping") Then
				Result.DataReceivedForMapping = AdditionalParameters.DataReceivedForMapping;
			EndIf;
		EndIf;
	EndIf;
	
	PutToTempStorage(Result, ResultAddress);
	
EndProcedure

Procedure SaveSynchronizationSettings(Parameters, ResultAddress) Export
	
	SynchronizationSettings = Undefined;
	Parameters.Property("SynchronizationSettings", SynchronizationSettings);
	
	Result = New Structure;
	Result.Insert("SettingsSaved", True);
	Result.Insert("ErrorMessage",  "");
	
	ExchangePlanName = DataExchangeCached.GetExchangePlanName(SynchronizationSettings.ExchangeNode);
	
	If DataExchangeServer.HasExchangePlanManagerAlgorithm("OnSaveDataSynchronizationSettings", ExchangePlanName) Then
		BeginTransaction();
		Try
			ObjectNode = SynchronizationSettings.ExchangeNode.GetObject();
			ExchangePlans[ExchangePlanName].OnSaveDataSynchronizationSettings(ObjectNode,
				SynchronizationSettings.FillingData);
			ObjectNode.Write();
			
			If Not DataExchangeServer.SynchronizationSetupCompleted(SynchronizationSettings.ExchangeNode) Then
				DataExchangeServer.CompleteDataSynchronizationSetup(SynchronizationSettings.ExchangeNode);
			EndIf;
			
			CommitTransaction();
		Except
			RollbackTransaction();
			
			Result.SettingsSaved = False;
			Result.ErrorMessage = DetailErrorDescription(ErrorInfo());
			
			WriteLogEvent(DataExchangeServer.DataExchangeCreationEventLogEvent(),
				EventLogLevel.Error, , , Result.ErrorMessage);
		EndTry;
	Else
		If Not DataExchangeServer.SynchronizationSetupCompleted(SynchronizationSettings.ExchangeNode) Then
			DataExchangeServer.CompleteDataSynchronizationSetup(SynchronizationSettings.ExchangeNode);
		EndIf;
	EndIf;
	
	PutToTempStorage(Result, ResultAddress);
	
EndProcedure

Procedure ConfigureDataExchange(ConnectionSettings) Export
	
	SetPrivilegedMode(True);
	
	BeginTransaction();
	Try
		
		// Creating/updating the exchange plan node.
		CreateUpdateExchangePlanNodes(ConnectionSettings);
		
		// Loading message transport settings.
		If ValueIsFilled(ConnectionSettings.ExchangeMessagesTransportKind) Then
			// For online exchange when setting from the box the transport kind will not be filled in and is not required.
			UpdateDataExchangeTransportSettings(ConnectionSettings);
		EndIf;
		
		// Updating the infobase prefix constant value.
		If IsBlankString(GetFunctionalOption("InfobasePrefix"))
			AND Not IsBlankString(ConnectionSettings.SourceInfobasePrefix) Then
			
			DataExchangeServer.SetInfobasePrefix(ConnectionSettings.SourceInfobasePrefix);
			
		EndIf;
		
		If DataExchangeCached.IsDistributedInfobaseExchangePlan(ConnectionSettings.ExchangePlanName)
			AND ConnectionSettings.WizardRunOption = "ContinueDataExchangeSetup" Then
			
			Constants.SubordinateDIBNodeSetupCompleted.Set(True);
			Constants.UseDataSynchronization.Set(True);
			Constants.DoNotUseSeparationByDataAreas.Set(True);
			
			// Importing rules as exchange rules are not migrated to DIB.
			DataExchangeServer.UpdateDataExchangeRules();
			
		EndIf;
		
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;
	
EndProcedure

Procedure DeleteSynchronizationSetting(Parameters, ResultAddress) Export
	
	DeletionSettings = Undefined;
	Parameters.Property("DeletionSettings", DeletionSettings);
	
	Result = New Structure;
	Result.Insert("SettingDeleted",                 True);
	Result.Insert("SettingDeletedInCorrespondent",  DeletionSettings.DeleteSettingItemInCorrespondent);
	Result.Insert("ErrorMessage",                "");
	Result.Insert("ErrorMessageInCorrespondent", "");
	
	// 1. Deleting the synchronization setup in the correspondent application (optional).
	If DeletionSettings.DeleteSettingItemInCorrespondent Then
		DeleteSynchronizationSettingInCorrespondent(DeletionSettings, Result);
		
		If Not Result.SettingDeletedInCorrespondent Then
			Raise StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'При удалении настройки синхронизации в программе ""%1"" возникла ошибка: %2.
				|
				|Попробуйте выполнить удаление позже, или снимите флажок ""Удалить настройку также в программе..."".'; 
				|en = 'Cannot delete the synchronization setting in %1: %2.
				|
				|Try to delete it later or clear the ""Also delete the setting in..."" check box.'; 
				|pl = 'W czasie usunięcia ustawień synchronizacji w programie ""%1"" wystąpił błąd: %2.
				|
				|próbuj wykonać usuwanie później, lub wyczyść pole wyboru ""Usuń ustawienia również w programie..."".';
				|de = 'Beim Löschen der Synchronisationseinstellung im Programm ""%1"" ist ein Fehler aufgetreten: %2.
				|
				|Versuchen Sie, die Deinstallation später durchzuführen, oder deaktivieren Sie das Kontrollkästchen ""Deinstallieren der Einstellung auch im Programm..."".';
				|ro = 'La ștergerea setării de sincronizare în aplicația ""%1"" s-a produs eroarea: %2.
				|
				|Încercați să executați ștergerea mai târziu sau debifați ""Șterge setarea de asemenea în aplicația..."".';
				|tr = '""%1"" programında eşleşme ayarları silinirken bir hata oluştu: %2. 
				|
				| Daha sonra silmeyi deneyin veya ""Programda da ayarları silin..."" onay kutusunu kaldırın.'; 
				|es_ES = 'Al eliminar el ajuste de sincronización en el programa ""%1"" se ha producido un error: %2.
				|
				|Vuelva a eliminar más tarde o quite la casilla de verificación ""Eliminar el ajuste también en el programa..."".'"),
				Common.ObjectAttributeValue(DeletionSettings.ExchangeNode, "Description"),
				Result.ErrorMessageInCorrespondent);
		EndIf;
		
	EndIf;
	
	// 2. Deleting the synchronization settings in this application.
	Try
		DataExchangeServer.DeleteSynchronizationSetting(DeletionSettings.ExchangeNode);
	Except
		Result.SettingDeleted  = False;
		Result.ErrorMessage = DetailErrorDescription(ErrorInfo());
		
		WriteLogEvent(DataExchangeServer.DataExchangeDeletionEventLogEvent(),
			EventLogLevel.Error, , , Result.ErrorMessage);
	EndTry;
	
	PutToTempStorage(Result, ResultAddress);
	
EndProcedure

Procedure DeleteSynchronizationSettingInCorrespondent(DeletionSettings, Result)
	
	ExchangePlanName    = DataExchangeCached.GetExchangePlanName(DeletionSettings.ExchangeNode);
	NodeID = DataExchangeServer.NodeIDForExchange(DeletionSettings.ExchangeNode);
		
	TransportKind = InformationRegisters.DataExchangeTransportSettings.DefaultExchangeMessagesTransportKind(
		DeletionSettings.ExchangeNode);
		
	If TransportKind = Enums.ExchangeMessagesTransportTypes.COM Then
		
		ConnectionSettings = InformationRegisters.DataExchangeTransportSettings.TransportSettings(
			DeletionSettings.ExchangeNode, TransportKind);
		ConnectionResult = DataExchangeServer.EstablishExternalConnectionWithInfobase(ConnectionSettings);
	
		ExternalConnection = ConnectionResult.Connection;
		If ExternalConnection = Undefined Then
			Result.ErrorMessageInCorrespondent = ConnectionResult.DetailedErrorDescription;
			Result.SettingDeletedInCorrespondent = False;
			Return;
		EndIf;
		
		CorrespondentNode = ExternalConnection.DataExchangeServer.ExchangePlanNodeByCode(ExchangePlanName,
			NodeID);
			
		If CorrespondentNode = Undefined Then
			Result.ErrorMessageInCorrespondent = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'В программе-корреспонденте не найден узел плана обмена ""%1"" по коду ""%2"".'; en = 'Exchange plan node ""%1"" is not found in the peer application by code ""%2"".'; pl = 'W programie-korespondencie nie znaleziono węzła planu wymiany ""%1"" wg kodu ""%2""-';de = 'Im korrespondierenden Programm ist kein Austauschplanknoten ""%1"" nach Code ""%2"" zu finden.';ro = 'În programul-corespondent nu a fost găsit nodul planului de schimb ""%1"" conform codului ""%2"".';tr = 'Muhabir programında ""%1"" kodu ile ""%2"" alışveriş planın ünitesi bulunamadı.'; es_ES = 'En el programa-correspondiente no se ha encontrado un nodo del plan de cambio ""%1"" por el código ""%2"".'"),
				ExchangePlanName, NodeID);
			Result.SettingDeletedInCorrespondent = False;
			Return;
		EndIf;
		
		Try
			ExternalConnection.DataExchangeServer.DeleteSynchronizationSetting(CorrespondentNode);
		Except
			Result.SettingDeletedInCorrespondent = False;
			Result.ErrorMessageInCorrespondent = DetailErrorDescription(ErrorInfo());
			
			WriteLogEvent(DataExchangeServer.DataExchangeDeletionEventLogEvent(),
				EventLogLevel.Error, , , Result.ErrorMessageInCorrespondent);
		EndTry;
		
	ElsIf TransportKind = Enums.ExchangeMessagesTransportTypes.WS Then
		
		ConnectionSettings = InformationRegisters.DataExchangeTransportSettings.TransportSettingsWS(
			DeletionSettings.ExchangeNode);
			
		ExchangeSettingsStructure = New Structure;
		ExchangeSettingsStructure.Insert("ExchangePlanName",                  ExchangePlanName);
		ExchangeSettingsStructure.Insert("InfobaseNode",          DeletionSettings.ExchangeNode);
		ExchangeSettingsStructure.Insert("EventLogMessageKey", DataExchangeServer.DataExchangeDeletionEventLogEvent());
		ExchangeSettingsStructure.Insert("CurrentExchangePlanNode",          DataExchangeCached.GetThisExchangePlanNode(ExchangePlanName));
		ExchangeSettingsStructure.Insert("CurrentExchangePlanNodeCode",       NodeID);
		ExchangeSettingsStructure.Insert("ActionOnExchange",               Undefined);
			
		ProxyParameters = New Structure;
		ProxyParameters.Insert("AuthenticationParameters", Undefined);
		ProxyParameters.Insert("EarliestVersion",       "3.0.1.1");
			
		WSProxy = Undefined;
		Cancel = False;
		SetupStatus = Undefined;
		ErrorMessage  = "";
		DataExchangeServer.InitializeWSProxyToManageDataExchange(
			WSProxy, ExchangeSettingsStructure, ProxyParameters, Cancel, SetupStatus, ErrorMessage);
		
		If Cancel Then
			Result.ErrorMessageInCorrespondent = ErrorMessage;
			Result.SettingDeletedInCorrespondent  = False;
			
			WriteLogEvent(DataExchangeServer.DataExchangeDeletionEventLogEvent(),
				EventLogLevel.Error, , , Result.ErrorMessageInCorrespondent);
			Return;
		EndIf;
		
		Try
			WSProxy.RemoveExchangeNode(ExchangePlanName, ExchangeSettingsStructure.CurrentExchangePlanNodeCode);
		Except
			Result.SettingDeletedInCorrespondent = False;
			Result.ErrorMessageInCorrespondent = DetailErrorDescription(ErrorInfo());
			
			WriteLogEvent(DataExchangeServer.DataExchangeDeletionEventLogEvent(),
				EventLogLevel.Error, , , Result.ErrorMessageInCorrespondent);
		EndTry;
			
	ElsIf TransportKind = Enums.ExchangeMessagesTransportTypes.ExternalSystem Then
		If Common.SubsystemExists("OnlineUserSupport.DataExchangeWithExternalSystems") Then
			
			Context = New Structure;
			Context.Insert("Correspondent", DeletionSettings.ExchangeNode);
			
			ModuleDataExchangeWithExternalSystems = Common.CommonModule("DataExchangeWithExternalSystems");
			
			Try
				ModuleDataExchangeWithExternalSystems.OnDeleteSynchronizationSetting(Context);
			Except
				Information = ErrorInfo();
				
				Result.SettingDeletedInCorrespondent  = False;
				Result.ErrorMessageInCorrespondent = BriefErrorDescription(Information);
				
				WriteLogEvent(DataExchangeServer.DataExchangeDeletionEventLogEvent(),
					EventLogLevel.Error, , , DetailErrorDescription(Information));
			EndTry;
			
		EndIf;
	Else
		Result.SettingDeletedInCorrespondent = False;
		Result.ErrorMessage = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Для вида подключения ""%1"" не поддерживается удаление настройки синхронизации на стороне программы-корреспондента.'; en = 'Deletion of synchronisation settings in the peer application is not supported for the ""%1"" connection type.'; pl = 'Dla rodzaju połączenia ""%1"" nie jest obsługiwane usuwanie ustawienia synchronizacji na stronie programu-korespondenta.';de = 'Für den Verbindungstyp ""%1"" wird das Entfernen von Synchronisationseinstellungen auf der Seite des korrespondierenden Programms nicht unterstützt.';ro = 'Pentru tipul de conectare ""%1"" nu este susținută ștergerea setării de sincronizare pe partea programului-corespondent.';tr = '""%1"" Bağlantı türü için, muhabir program tarafında senkronizasyon ayarı kaldırılmaz.'; es_ES = 'Para el tipo de conexión ""%1"" no se admite la eliminación del ajuste de sincronización en el lado del programa-correspondiente.'"),
			TransportKind);
	EndIf;
	
EndProcedure

Procedure RegisterDataForInitialExport(Parameters, ResultAddress) Export
	
	RegistrationSettings = Undefined;
	Parameters.Property("RegistrationSettings", RegistrationSettings);
	
	Result = New Structure;
	Result.Insert("DataRegistered", True);
	Result.Insert("ErrorMessage",      "");
	
	ReceivedMessageNumber = Common.ObjectAttributeValue(RegistrationSettings.ExchangeNode, "ReceivedNo");
	
	Try
		DataExchangeServer.RegisterDataForInitialExport(RegistrationSettings.ExchangeNode, , ReceivedMessageNumber = 0);
	Except
		Result.DataRegistered = False;
		Result.ErrorMessage = DetailErrorDescription(ErrorInfo());
		
		WriteLogEvent(DataExchangeServer.RegisterDataForInitialExportEventLogEvent(),
			EventLogLevel.Error, , , Result.ErrorMessage);
	EndTry;
	
	PutToTempStorage(Result, ResultAddress);
	
EndProcedure

Function NodeCode(ConnectionSettings)
	
	If ConnectionSettings.UsePrefixesForExchangeSettings
		Or ConnectionSettings.UsePrefixesForCorrespondentExchangeSettings Then
		
		Return ConnectionSettings.SourceInfobasePrefix;
			
	Else
		
		Return ConnectionSettings.SourceInfobaseID;
		
	EndIf;
	
EndFunction

Function CorrespondentNodeCode(ConnectionSettings)
	
	If ConnectionSettings.UsePrefixesForExchangeSettings
		Or ConnectionSettings.UsePrefixesForCorrespondentExchangeSettings Then
		
		Return ConnectionSettings.DestinationInfobasePrefix;
			
	Else
		
		Return ConnectionSettings.DestinationInfobaseID;
		
	EndIf;
	
EndFunction

Procedure CreateUpdateExchangePlanNodes(ConnectionSettings)
	
	ThisNodeCode  = NodeCode(ConnectionSettings);
	NewNodeCode = CorrespondentNodeCode(ConnectionSettings);
	
	ExchangePlanManager = ExchangePlans[ConnectionSettings.ExchangePlanName];
	
	// Refreshing predefined node code of this base if it is not filled in.
	ThisNode = ExchangePlanManager.ThisNode();
	
	ThisNodeCodeInDatabase = Common.ObjectAttributeValue(ThisNode, "Code");
	IsDIBExchangePlan  = DataExchangeCached.IsDistributedInfobaseExchangePlan(
		ConnectionSettings.ExchangePlanName);
	
	If IsBlankString(ThisNodeCodeInDatabase) Then
		
		ThisNodeObject = ThisNode.GetObject();
		ThisNodeObject.Code = ThisNodeCode;
		ThisNodeObject.Description = ConnectionSettings.ThisInfobaseDescription;
		ThisNodeObject.AdditionalProperties.Insert("GettingExchangeMessage");
		ThisNodeObject.Write();
		
		ThisNodeCodeInDatabase = ThisNodeCode;
		
	EndIf;
	
	CreateNewNode = False;
	
	// Receiving the correspondent node.
	If IsDIBExchangePlan
		AND ConnectionSettings.WizardRunOption = "ContinueDataExchangeSetup" Then
		
		MasterNode = DataExchangeServer.MasterNode();
		
		If MasterNode = Undefined Then
			
			Raise NStr("ru = 'Главный узел для текущей информационной базы не определен.
							|Возможно, информационная база не является подчиненным узлом в РИБ.'; 
							|en = 'The master node is not defined.
							|Probably this infobase is not a subordinate DIB node.'; 
							|pl = 'Główny węzeł bieżącej bazy informacyjnej nie został określony.
							|Być może baza informacyjna nie jest podrzędnym węzłem w RIB.';
							|de = 'Der Hauptknoten für die aktuelle Infobase ist nicht festgelegt.
							|Vielleicht ist die Infobase kein untergeordneter Knoten im RIB.';
							|ro = 'Nodul principal pentru baza de date curentă nu este determinat.
							|Probabil, baza de date nu este un nod subordonat în BID.';
							|tr = 'Geçerli veritabanı için ana ünite tanımlanmamıştır.
							| Veritabanı RİB''deki alt ünitesi olmayabilir.'; 
							|es_ES = 'El nodo principal para la infobase actual no está determinado.
							|Probablemente, la infobase no es un nodo subordinado en el RIB.'");
		EndIf;
		
		NewNode = MasterNode.GetObject();
		
		// Transferring common data from the predefined node.
		ThisNodeObject = ThisNode.GetObject();
		
		ExchangePlanMetadata = NewNode.Metadata();
		SharedDataString = DataExchangeServer.ExchangePlanSettingValue(ConnectionSettings.ExchangePlanName,
			"CommonNodeData", ConnectionSettings.ExchangeSettingsOption);
		
		SharedData = StrSplit(SharedDataString, ", ", False);
		For Each ItemCommonData In SharedData Do
			If ExchangePlanMetadata.TabularSections.Find(ItemCommonData) = Undefined Then
				FillPropertyValues(NewNode, ThisNodeObject, ItemCommonData);
			Else
				NewNode[ItemCommonData].Load(ThisNodeObject[ItemCommonData].Unload());
			EndIf;
		EndDo;
	Else
		// Creating or updating the node.
		NewNodeRef = ExchangePlanManager.FindByCode(NewNodeCode);
		
		CreateNewNode = NewNodeRef.IsEmpty();
		
		If CreateNewNode Then
			NewNode = ExchangePlanManager.CreateNode();
			NewNode.Code = NewNodeCode;
		Else
			Raise StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'Значение префикса программы ""%1"" не уникально (""%2""). Уже существует настройка синхронизации с таким же префиксом.
				|Для продолжения необходимо назначить в программе ""%1"" уникальный префикс информационной базы, отличный от текущего.'; 
				|en = 'The %1 prefix is not unique (""%2""). A synchronization setting with the specified prefix already exists.
				|Please specify a unique infobase prefix in %1.'; 
				|pl = 'Wartość przedrostka programu ""%1"" nie jest unikalna (""%2""). Istnieje już konfigurowanie synchronizacji z tym samym przedrostkiem.
				|Aby kontynuować, należy przypisać w programie ""%1"" unikalny przedrostek bazy informacyjnej, odmienny od aktualnego.';
				|de = 'Der Wert des Programmpräfix ""%1"" ist nicht eindeutig (""%2""). Es gibt bereits eine Synchronisationseinstellung mit dem gleichen Präfix.
				|Um fortzufahren, müssen Sie im Programm ""%1"" ein eindeutiges Informationsbasispräfix vergeben, das sich vom aktuellen Präfix unterscheidet.';
				|ro = 'Valoarea prefixului programului ""%1"" nu este unică (""%2""). Deja există setarea de sincronizare cu același prefix.
				|Pentru continuare trebuie să atribuiți în programul ""%1"" prefixul unic al bazei de informații, diferit de cel curent.';
				|tr = '""%1""Programın önek değeri benzersiz değil (""%2""). Aynı önek ile eşitleme ayarı zaten mevcut. 
				|Devam etmek için, ""%1"" programında, mevcut ile aynı olmayan, benzersiz bir veri tabanı öneki atanmalıdır.'; 
				|es_ES = 'El valor del prefijo del programa ""%1"" no es único (""%2""). Ya existe un ajuste de sincronización con el mismo prefijo.
				|Para la aplicación es necesario establecer en el programa ""%1"" un prefijo único de la base de información que es distinta de la actual.'"),
				ConnectionSettings.SecondInfobaseDescription, NewNodeCode);
		EndIf;
		
		NewNode.Description = ConnectionSettings.SecondInfobaseDescription;
		
		If Common.HasObjectAttribute("SettingsMode", Metadata.ExchangePlans[ConnectionSettings.ExchangePlanName]) Then
			NewNode.SettingsMode = ConnectionSettings.ExchangeSettingsOption;
		EndIf;
		
		If CreateNewNode Then
			NewNode.Fill(Undefined);
		EndIf;
		
		If DataExchangeCached.IsXDTOExchangePlan(ConnectionSettings.ExchangePlanName) Then
			If ValueIsFilled(ConnectionSettings.ExchangeFormatVersion) Then
				NewNode.ExchangeFormatVersion = ConnectionSettings.ExchangeFormatVersion;
			EndIf;
		EndIf;
		
	EndIf;
	
	// Resetting message counters.
	NewNode.SentNo = 0;
	NewNode.ReceivedNo     = 0;
	
	If Common.DataSeparationEnabled()
		AND Common.SeparatedDataUsageAvailable()
		AND DataExchangeServer.IsSeparatedSSLExchangePlan(ConnectionSettings.ExchangePlanName) Then
		
		NewNode.RegisterChanges = True;
		
	EndIf;
	
	If ValueIsFilled(ConnectionSettings.NewRef) Then
		NewNode.SetNewObjectRef(ConnectionSettings.NewRef);
	EndIf;
	
	NewNode.DataExchange.Load = True;
	NewNode.Write();
	
	If DataExchangeCached.IsXDTOExchangePlan(ConnectionSettings.ExchangePlanName) Then
		If ConnectionSettings.SupportedObjectsInFormat <> Undefined Then
			InformationRegisters.XDTODataExchangeSettings.UpdateCorrespondentSettings(NewNode.Ref,
				"SupportedObjects", ConnectionSettings.SupportedObjectsInFormat.Get());
		EndIf;
		
		RecordStructure = New Structure;
		RecordStructure.Insert("InfobaseNode",       NewNode.Ref);
		RecordStructure.Insert("CorrespondentExchangePlanName", ConnectionSettings.CorrespondentExchangePlanName);
		
		DataExchangeServer.UpdateInformationRegisterRecord(RecordStructure, "XDTODataExchangeSettings");
	EndIf;
	
	ConnectionSettings.InfobaseNode = NewNode.Ref;
	
	// Common node data.
	InformationRegisters.CommonInfobasesNodesSettings.UpdatePrefixes(
		ConnectionSettings.InfobaseNode,
		?(ConnectionSettings.UsePrefixesForExchangeSettings
			Or ConnectionSettings.UsePrefixesForCorrespondentExchangeSettings, ConnectionSettings.SourceInfobasePrefix, ""),
		ConnectionSettings.DestinationInfobasePrefix);
	
	If CreateNewNode
		AND Not Common.DataSeparationEnabled() Then
		DataExchangeServer.UpdateDataExchangeRules();
	EndIf;
	
	If ThisNodeCode <> ThisNodeCodeInDatabase
		AND DataExchangeCached.IsXDTOExchangePlan(ConnectionSettings.ExchangePlanName)
		AND (ConnectionSettings.UsePrefixesForExchangeSettings
			Or ConnectionSettings.UsePrefixesForCorrespondentExchangeSettings) Then
		// Node in the correspondent base needs recoding.
		StructureTemporaryCode = New Structure;
		StructureTemporaryCode.Insert("Correspondent", ConnectionSettings.InfobaseNode);
		StructureTemporaryCode.Insert("NodeCode",       ThisNodeCode);
		
		DataExchangeServer.AddRecordToInformationRegister(StructureTemporaryCode, "PredefinedNodesAliases");
	EndIf;

EndProcedure

Procedure UpdateDataExchangeTransportSettings(ConnectionSettings)
	
	RecordStructure = New Structure;
	RecordStructure.Insert("Correspondent",                           ConnectionSettings.InfobaseNode);
	RecordStructure.Insert("DefaultExchangeMessagesTransportKind", ConnectionSettings.ExchangeMessagesTransportKind);
	
	RecordStructure.Insert("COMOperatingSystemAuthentication");
	RecordStructure.Insert("COMInfobaseOperatingMode");
	RecordStructure.Insert("COM1CEnterpriseServerSideInfobaseName");
	RecordStructure.Insert("COMUsername");
	RecordStructure.Insert("COM1CEnterpriseServerName");
	RecordStructure.Insert("COMInfobaseDirectory");
	RecordStructure.Insert("COMUserPassword");
	
	RecordStructure.Insert("EMAILMaxMessageSize");
	RecordStructure.Insert("EMAILCompressOutgoingMessageFile");
	RecordStructure.Insert("EMAILUserAccount");
	RecordStructure.Insert("EMAILTransliterateExchangeMessageFileNames");
	
	RecordStructure.Insert("FILEInformationExchangeDirectory");
	RecordStructure.Insert("FILECompressOutgoingMessageFile");
	RecordStructure.Insert("FILETransliterateExchangeMessageFileNames");
	
	RecordStructure.Insert("FTPCompressOutgoingMessageFile");
	RecordStructure.Insert("FTPConnectionMaxMessageSize");
	RecordStructure.Insert("FTPConnectionPassword");
	RecordStructure.Insert("FTPConnectionPassiveConnection");
	RecordStructure.Insert("FTPConnectionUser");
	RecordStructure.Insert("FTPConnectionPort");
	RecordStructure.Insert("FTPConnectionPath");
	RecordStructure.Insert("FTPTransliterateExchangeMessageFileNames");
	
	RecordStructure.Insert("WSWebServiceURL");
	RecordStructure.Insert("WSUsername");
	RecordStructure.Insert("WSPassword");
	RecordStructure.Insert("WSRememberPassword");
	
	RecordStructure.Insert("WSUseHighVolumeDataTransfer", True);
	
	RecordStructure.Insert("ArchivePasswordExchangeMessages");
	
	FillPropertyValues(RecordStructure, ConnectionSettings);
	
	InformationRegisters.DataExchangeTransportSettings.AddRecord(RecordStructure);
	
EndProcedure

#Region SettingsInXMLFormat

Procedure FillConnectionSettingsFromConstant(ConnectionSettings) Export
	
	SetPrivilegedMode(True);
	StringForConnection = Constants.SubordinateDIBNodeSettings.Get();
	
	FillConnectionSettingsFromXMLString(ConnectionSettings, StringForConnection);
	
EndProcedure

Procedure FillConnectionSettingsFromXMLString(ConnectionSettings,
		FileNameXMLString, IsFile = False, IsOnlineConnection = False) Export
	
	SettingsStructure = Undefined;
	Try
		ReadConnectionSettingsFromXMLToStructure(SettingsStructure, FileNameXMLString, IsFile);
	Except
		Raise;
	EndTry;
	
	// Verifying read from the file parameters.
	CorrectSettingsFile = False;
	ExchangePlanNameInSettings = "";
	
	If SettingsStructure.Property("ExchangePlanName", ExchangePlanNameInSettings)
		AND SettingsStructure.ExchangePlanName = ConnectionSettings.ExchangePlanName Then
		CorrectSettingsFile = True;
	Else
		CorrectSettingsFile = False;
		
		If DataExchangeCached.IsXDTOExchangePlan(ConnectionSettings.ExchangePlanName) Then
			If SettingsStructure.Property("XDTOExchangeParameters")
				AND SettingsStructure.XDTOExchangeParameters.Property("ExchangeFormat")
				AND SettingsStructure.XDTOExchangeParameters.ExchangeFormat = ConnectionSettings.ExchangeFormat Then
				CorrectSettingsFile = True;
			EndIf;
		EndIf;
	EndIf;
	
	If Not CorrectSettingsFile Then
		Raise StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Файл не содержит настроек подключения для выбранного обмена данными.
			|Выбран обмен ""%1"".
			|В файле указаны настройки для обмена ""%2"".'; 
			|en = 'The file does not contain connection settings for the selected data exchange.
			|Exchange ""%1"" is selected,
			|while the file contains settings for exchange ""%2"".'; 
			|pl = 'Plik nie zawiera ustawień połączenia dla wybranej wymiany danych.
			|Wybrana wymiana ""%1"".
			|W pliku są określone ustawienia do wymiany ""%2"".';
			|de = 'Die Datei enthält keine Verbindungseinstellungen für den ausgewählten Datenaustausch.
			|Der Austausch ""%1"" ist ausgewählt.
			|Die Datei enthält die Einstellungen für den Austausch ""%2"".';
			|ro = 'Fișierul nu conține setările de conectare pentru schimbul de date selectat.
			|Este selectat schimbul ""%1"".
			|În fișier sunt indicate setările pentru schimbul ""%2"".';
			|tr = 'Dosya seçilen veri paylaşımı için bağlantı ayarlarını içermez. 
			| ""%1"" veri alışverişi seçildi. 
			|Dosyada, ""%2"" paylaşımı için ayarlar belirtilmiştir.'; 
			|es_ES = 'El archivo no contiene ajustes de conexión para el cambio de datos seleccionado.
			|Se ha seleccionado el cambio ""%1"".
			|En el archivo se han indicado ajustes para cambiar ""%2"".'"),
			ConnectionSettings.ExchangePlanName, ExchangePlanNameInSettings);
	EndIf;
	
	If Not ValueIsFilled(ConnectionSettings.CorrespondentExchangePlanName) Then
		ConnectionSettings.CorrespondentExchangePlanName = SettingsStructure.ExchangePlanName;
	EndIf;
	
	FillPropertyValues(ConnectionSettings, SettingsStructure, , "ExchangePlanName, SourceInfobasePrefix");
	
	If Not IsOnlineConnection
		Or Not ValueIsFilled(ConnectionSettings.UsePrefixesForExchangeSettings) Then
		ExchangePlanEmptyRef = ExchangePlans[ConnectionSettings.ExchangePlanName].EmptyRef();
		
		ConnectionSettings.UsePrefixesForExchangeSettings = 
			Not DataExchangeCached.IsXDTOExchangePlan(ConnectionSettings.ExchangePlanName)
				Or Not DataExchangeXDTOServer.VersionWithDataExchangeIDSupported(ExchangePlanEmptyRef);
	EndIf;
	
	If Not IsOnlineConnection Then
		SecondInfobaseNewNodeCode = Undefined;		
		SettingsStructure.Property("SecondInfobaseNewNodeCode", SecondInfobaseNewNodeCode);
		
		ConnectionSettings.UsePrefixesForCorrespondentExchangeSettings =
			ConnectionSettings.UsePrefixesForCorrespondentExchangeSettings
				Or (ConnectionSettings.WizardRunOption = "ContinueDataExchangeSetup"
					AND DataExchangeCached.IsXDTOExchangePlan(ConnectionSettings.ExchangePlanName)
					AND ValueIsFilled(SecondInfobaseNewNodeCode)
					AND StrLen(SecondInfobaseNewNodeCode) <> 36);
	EndIf;
			
	If Not ConnectionSettings.UsePrefixesForExchangeSettings
		AND Not ConnectionSettings.UsePrefixesForCorrespondentExchangeSettings Then
		
		SettingsStructure.Property("PredefinedNodeCode", ConnectionSettings.SourceInfobaseID);
		SettingsStructure.Property("SecondInfobaseNewNodeCode",  ConnectionSettings.DestinationInfobaseID);
		
	Else
		
		SettingsStructure.Property("SourceInfobasePrefix", ConnectionSettings.SourceInfobasePrefix);
		SettingsStructure.Property("SecondInfobaseNewNodeCode",            ConnectionSettings.DestinationInfobasePrefix);
		
	EndIf;
	
	If ConnectionSettings.WizardRunOption = "ContinueDataExchangeSetup"
		AND (ConnectionSettings.UsePrefixesForExchangeSettings
			Or ConnectionSettings.UsePrefixesForCorrespondentExchangeSettings) Then
		
		IBPrefix = GetFunctionalOption("InfobasePrefix");
		If Not IsBlankString(IBPrefix)
			AND IBPrefix <> ConnectionSettings.SourceInfobasePrefix Then
			
			Raise StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'Префикс программы, указанный при настройке (""%1""), не соответствует префиксу в этой программе (""%2"").
				|Для продолжения необходимо начать настройку заново из другой программы, и указать корректный префикс (""%2"").'; 
				|en = 'The application prefix specified during the exchange setup (""%1"") does not match the prefix in this application (""%2"").
				|Please start the setup from the other application and specify the correct prefix (""%2"").'; 
				|pl = 'Przedrostek programu, podany podczas konfiguracji (""%1""), nie odpowiada przedrostkowi w tym programie (""%2"").
				|Aby kontynuować, należy rozpocząć konfigurację od nowa z innego programu i podać właściwy prefiks (""%2"").';
				|de = 'Das in der Einstellung (""%1"") angegebene Programmpräfix entspricht nicht dem Präfix in diesem Programm (""%2"").
				|Um fortzufahren, müssen Sie von einem anderen Programm aus erneut starten und das richtige Präfix (""%2"") eingeben.';
				|ro = 'Prefixul programului indicat la setarea (""%1"") nu corespunde prefixului în acest program (""%2"").
				|Pentru continuare trebuie să începeți setarea din nou din alt program și să indicați prefixul corect (""%2"").';
				|tr = 'Yapılandırılma esnasında belirtilen program öneki (""%1""), bu programdaki ( ""%2"" ) önek ile eşleşmiyor. 
				|Devam etmek için başka bir programdan yeniden yapılandırmaya başlamalı ve doğru önek ( ""%2"" ) belirtilmelidir.'; 
				|es_ES = 'El prefijo del programa indicado al ajustar (""%1"") no corresponde al prefijo en este programa (""%2"").
				|Para continuar es necesario empezar a ajustar de nuevo de otro programa e indicar un prefijo correcto (""%2"").'"),
				ConnectionSettings.SourceInfobasePrefix, IBPrefix);
			
		EndIf;
		
	EndIf;
	
	EmailAccount = Undefined;
	
	If Common.SubsystemExists("StandardSubsystems.EmailOperations")
		AND SettingsStructure.Property("EmailAccount", EmailAccount)
		AND EmailAccount <> Undefined Then
		
		ModuleEmailOperationsInternal = Common.CommonModule("EmailOperationsInternal");
		ThisInfobaseAccount = ModuleEmailOperationsInternal.ThisInfobaseAccountByCorrespondentAccountData(
			EmailAccount);
		ConnectionSettings.EMAILUserAccount = ThisInfobaseAccount.Ref;
		
	EndIf;
	
	// Supporting the exchange settings file of the 1.0 version format.
	If ConnectionSettings.ExchangeDataSettingsFileFormatVersion = "1.0" Then
		
		ConnectionSettings.ThisInfobaseDescription    = NStr("ru = 'Эта информационная база'; en = 'This infobase'; pl = 'Ta baza informacyjna';de = 'Dies ist eine Infobase';ro = 'Această bază de informații';tr = 'Bu veri tabanı'; es_ES = 'Es una infobase'");
		ConnectionSettings.SecondInfobaseDescription  = SettingsStructure.DataExchangeExecutionSettingsDescription;
		ConnectionSettings.SecondInfobaseNewNodeCode = SettingsStructure.NewNodeCode;
		
	EndIf;
	
EndProcedure

Function ConnectionSettingsInXML(ConnectionSettings, FileName = "", EncodingType = "UTF-8") Export
	
	XMLWriter = New XMLWriter;
	
	If IsBlankString(FileName) Then
		XMLWriter.SetString(EncodingType);
	Else
		XMLWriter.OpenFile(FileName, EncodingType);
	EndIf;
	
	XMLWriter.WriteXMLDeclaration();
	
	If ConnectionSettings.ExchangeMessagesTransportKind = Enums.ExchangeMessagesTransportTypes.WSPassiveMode Then
		
		CorrespondentNode = ConnectionSettings.InfobaseNode;
		
		HeaderParameters = DataExchangeXDTOServer.ExchangeMessageHeaderParameters();
	
		HeaderParameters.ExchangeFormat            = ConnectionSettings.ExchangeFormat;
		HeaderParameters.IsExchangeViaExchangePlan = True;
		
	 	HeaderParameters.ExchangePlanName = ConnectionSettings.ExchangePlanName;
		HeaderParameters.PredefinedNodeAlias = DataExchangeServer.PredefinedNodeAlias(CorrespondentNode);
		
		HeaderParameters.RecipientID  = DataExchangeServer.CorrespondentNodeIDForExchange(CorrespondentNode);
		HeaderParameters.SenderID = DataExchangeServer.NodeIDForExchange(CorrespondentNode);
		
		FormatVersions = DataExchangeServer.ExchangePlanSettingValue(ConnectionSettings.ExchangePlanName, "ExchangeFormatVersions");
		For Each FormatVersion In FormatVersions Do
			HeaderParameters.SupportedVersions.Add(FormatVersion.Key);
		EndDo;
			
		HeaderParameters.SupportedObjects = DataExchangeXDTOServer.SupportedObjectsInFormat(
			ConnectionSettings.ExchangePlanName, "SendGet", CorrespondentNode);
		
		HeaderParameters.Prefix = DataExchangeServer.InfobasePrefix();
		
		HeaderParameters.CorrespondentNode = CorrespondentNode;
	
		DataExchangeXDTOServer.WriteExchangeMessageHeader(XMLWriter, HeaderParameters);
		
	Else
		XMLWriter.WriteStartElement("SetupParameters");
		XMLWriter.WriteAttribute("FormatVersion", DataExchangeSettingsFormatVersion());
		
		XMLWriter.WriteNamespaceMapping("xsd", "http://www.w3.org/2001/XMLSchema");
		XMLWriter.WriteNamespaceMapping("xsi", "http://www.w3.org/2001/XMLSchema-instance");
		XMLWriter.WriteNamespaceMapping("v8",  "http://v8.1c.ru/data");
		
		WriteConnectionParameters(XMLWriter, ConnectionSettings);
		
		If ConnectionSettings.UseTransportParametersEMAIL Then
			WriteEmailAccount(XMLWriter, ConnectionSettings);
		EndIf;
		
		If DataExchangeCached.IsXDTOExchangePlan(ConnectionSettings.ExchangePlanName) Then
			WriteXDTOExchangeParameters(XMLWriter, ConnectionSettings.ExchangePlanName);
		EndIf;
		
		XMLWriter.WriteEndElement(); // SetupParameters
	EndIf;
	
	Return XMLWriter.Close();
	
EndFunction

Procedure WriteConnectionParameters(XMLWriter, ConnectionSettings)
	
	XMLWriter.WriteStartElement("MainExchangeParameters");
	
	AddXMLRecord(XMLWriter, ConnectionSettings.ExchangePlanName,         "ExchangePlanName");
	
	AddXMLRecord(XMLWriter, ConnectionSettings.ThisInfobaseDescription,   "SecondInfobaseDescription");
	AddXMLRecord(XMLWriter, ConnectionSettings.SecondInfobaseDescription, "ThisInfobaseDescription");
	
	If ConnectionSettings.UsePrefixesForExchangeSettings
		Or ConnectionSettings.UsePrefixesForCorrespondentExchangeSettings Then
		
		AddXMLRecord(XMLWriter, ConnectionSettings.SourceInfobasePrefix, "SecondInfobaseNewNodeCode");
		
	Else
		
		AddXMLRecord(XMLWriter, ConnectionSettings.SourceInfobaseID, "SecondInfobaseNewNodeCode");
		
	EndIf;
	
	AddXMLRecord(XMLWriter, ConnectionSettings.DestinationInfobasePrefix, "SourceInfobasePrefix");
	
	// Exchange message transport settings.
	If ConnectionSettings.ExchangeMessagesTransportKind <> Enums.ExchangeMessagesTransportTypes.WS Then
		AddXMLRecord(XMLWriter, ConnectionSettings.ExchangeMessagesTransportKind, "ExchangeMessagesTransportKind");
	Else
		AddXMLRecord(XMLWriter, Undefined, "ExchangeMessagesTransportKind");
	EndIf;
	AddXMLRecord(XMLWriter, ConnectionSettings.ArchivePasswordExchangeMessages,  "ArchivePasswordExchangeMessages");
	
	If ConnectionSettings.UseTransportParametersEMAIL Then
		
		AddXMLRecord(XMLWriter, ConnectionSettings.EMAILMaxMessageSize, "EMAILMaxMessageSize");
		AddXMLRecord(XMLWriter, ConnectionSettings.EMAILCompressOutgoingMessageFile,        "EMAILCompressOutgoingMessageFile");
		AddXMLRecord(XMLWriter, ConnectionSettings.EMAILUserAccount,                         "EMAILUserAccount");
		
	EndIf;
	
	If ConnectionSettings.UseTransportParametersFILE Then
		
		AddXMLRecord(XMLWriter, ConnectionSettings.FILEInformationExchangeDirectory,       "FILEInformationExchangeDirectory");
		AddXMLRecord(XMLWriter, ConnectionSettings.FILECompressOutgoingMessageFile, "FILECompressOutgoingMessageFile");
		
	EndIf;
	
	If ConnectionSettings.UseTransportParametersFTP Then
		
		AddXMLRecord(XMLWriter, ConnectionSettings.FTPCompressOutgoingMessageFile,                  "FTPCompressOutgoingMessageFile");
		AddXMLRecord(XMLWriter, ConnectionSettings.FTPConnectionMaxMessageSize, "FTPConnectionMaxMessageSize");
		AddXMLRecord(XMLWriter, ConnectionSettings.FTPConnectionPassword,                                "FTPConnectionPassword");
		AddXMLRecord(XMLWriter, ConnectionSettings.FTPConnectionPassiveConnection,                   "FTPConnectionPassiveConnection");
		AddXMLRecord(XMLWriter, ConnectionSettings.FTPConnectionUser,                          "FTPConnectionUser");
		AddXMLRecord(XMLWriter, ConnectionSettings.FTPConnectionPort,                                  "FTPConnectionPort");
		AddXMLRecord(XMLWriter, ConnectionSettings.FTPConnectionPath,                                  "FTPConnectionPath");
		
	EndIf;
	
	If ConnectionSettings.UseTransportParametersCOM Then
		
		IBConnectionParameters = CommonClientServer.GetConnectionParametersFromInfobaseConnectionString(
			InfoBaseConnectionString());
		
		InfobaseOperatingMode             = IBConnectionParameters.InfobaseOperatingMode;
		NameOfInfobaseOn1CEnterpriseServer = IBConnectionParameters.NameOfInfobaseOn1CEnterpriseServer;
		NameOf1CEnterpriseServer                     = IBConnectionParameters.NameOf1CEnterpriseServer;
		InfobaseDirectory                   = IBConnectionParameters.InfobaseDirectory;
		
		InfobaseUser   = InfoBaseUsers.CurrentUser();
		OSAuthentication = InfobaseUser.OSAuthentication;
		Username  = InfobaseUser.Name;
		
		AddXMLRecord(XMLWriter, InfobaseOperatingMode,             "COMInfobaseOperatingMode");
		AddXMLRecord(XMLWriter, NameOfInfobaseOn1CEnterpriseServer, "COM1CEnterpriseServerSideInfobaseName");
		AddXMLRecord(XMLWriter, NameOf1CEnterpriseServer,                     "COM1CEnterpriseServerName");
		AddXMLRecord(XMLWriter, InfobaseDirectory,                   "COMInfobaseDirectory");
		AddXMLRecord(XMLWriter, OSAuthentication,                            "COMOperatingSystemAuthentication");
		AddXMLRecord(XMLWriter, Username,                             "COMUsername");
		
	EndIf;
	
	AddXMLRecord(XMLWriter, ConnectionSettings.UseTransportParametersEMAIL, "UseTransportParametersEMAIL");
	AddXMLRecord(XMLWriter, ConnectionSettings.UseTransportParametersFILE,  "UseTransportParametersFILE");
	AddXMLRecord(XMLWriter, ConnectionSettings.UseTransportParametersFTP,   "UseTransportParametersFTP");
	
	// Supporting the exchange settings file of the 1.0 version format.
	AddXMLRecord(XMLWriter, ConnectionSettings.ThisInfobaseDescription, "DataExchangeExecutionSettingsDescription");
	
	If ConnectionSettings.UsePrefixesForExchangeSettings
		Or ConnectionSettings.UsePrefixesForCorrespondentExchangeSettings Then
		AddXMLRecord(XMLWriter, ConnectionSettings.SourceInfobasePrefix, "NewNodeCode");
	Else
		AddXMLRecord(XMLWriter, ConnectionSettings.SourceInfobaseID, "NewNodeCode");
	EndIf;
	
	IBNodeCode = Common.ObjectAttributeValue(ConnectionSettings.InfobaseNode, "Code");
	
	AddXMLRecord(XMLWriter, IBNodeCode, "PredefinedNodeCode");
	
	XMLWriter.WriteEndElement(); // MainExchangeParameters
	
EndProcedure

Procedure WriteEmailAccount(XMLWriter, ConnectionSettings)
	
	EMAILUserAccount = Undefined;
	If ValueIsFilled(ConnectionSettings.EMAILUserAccount) Then
		EMAILUserAccount = ConnectionSettings.EMAILUserAccount.GetObject();
	EndIf;
	
	XMLWriter.WriteStartElement("EmailAccount");
	WriteXML(XMLWriter, EMAILUserAccount);
	XMLWriter.WriteEndElement(); // EmailAccount
	
EndProcedure

Procedure WriteXDTOExchangeParameters(XMLWriter, ExchangePlanName)
	
	XMLWriter.WriteStartElement("XDTOExchangeParameters");
	
	ExchangeFormat = DataExchangeServer.ExchangePlanSettingValue(ExchangePlanName, "ExchangeFormat");
	
	WriteXML(XMLWriter, ExchangeFormat, "ExchangeFormat", XMLTypeAssignment.Explicit);
	
	XMLWriter.WriteEndElement(); // XDTOExchangeParameters
	
EndProcedure

Procedure AddXMLRecord(XMLWriter, Value, FullName)
	
	WriteXML(XMLWriter, Value, FullName, XMLTypeAssignment.Explicit);
	
EndProcedure

Procedure ReadConnectionSettingsFromXMLToStructure(SettingsStructure, FileNameXMLString, IsFile)
	
	SettingsStructure = New Structure;
	
	XMLReader = New XMLReader;
	If IsFile Then
		XMLReader.OpenFile(FileNameXMLString);
	Else
		XMLReader.SetString(FileNameXMLString);
	EndIf;
	
	XMLReader.Read(); // SetupParameters
	
	FormatVersion = XMLReader.GetAttribute("FormatVersion");
	SettingsStructure.Insert("ExchangeDataSettingsFileFormatVersion",
		?(FormatVersion = Undefined, "1.0", FormatVersion));
	
	XMLReader.Read(); // MainExchangeParameters
	
	// Reading the MainExchangeParameters node.
	ReadDataToStructure(SettingsStructure, XMLReader);
	
	If SettingsStructure.Property("UseTransportParametersEMAIL")
		AND SettingsStructure.UseTransportParametersEMAIL Then
		
		// Reading the EmailAccount node.
		XMLReader.Read(); // EmailAccount {ItemStart}
		
		SettingsStructure.Insert("EmailAccount", ReadXML(XMLReader));
		
		XMLReader.Read(); // EmailAccount {ItemEnd}
		
	EndIf;
		
	XMLReader.Close();
	
EndProcedure

Procedure ReadDataToStructure(SettingsStructure, XMLReader)
	
	If XMLReader.NodeType <> XMLNodeType.StartElement Then
		Raise NStr("ru = 'Ошибка разбора XML.'; en = 'XML file parsing error.'; pl = 'Błąd analizy XML.';de = 'XML-Analysefehler.';ro = 'Eroare de parsare XML.';tr = 'XML ayrıştırma hatası.'; es_ES = 'Error de analizar XML.'");
	EndIf;
	
	XMLReader.Read();
	
	While XMLReader.NodeType <> XMLNodeType.EndElement Do
		
		NodeName = XMLReader.Name;
		SettingsStructure.Insert(NodeName, ReadXML(XMLReader));
		
	EndDo;
	
	XMLReader.Read();
	
EndProcedure

Function XDTOCorrespondentSettingsFromXML(FileNameXMLString, IsFile, ExchangeNode) Export
	
	XMLReader = New XMLReader;
	If IsFile Then
		XMLReader.OpenFile(FileNameXMLString);
	Else
		XMLReader.SetString(FileNameXMLString);
	EndIf;
	
	XMLReader.Read(); // Message
	XMLReader.Read(); // Header
	
	Header = XDTOFactory.ReadXML(XMLReader,
		XDTOFactory.Type("http://www.1c.ru/SSL/Exchange/Message", XMLReader.LocalName));
		
	SettingsStructure = New Structure;
	DataExchangeXDTOServer.FillCorrespondentXDTOSettingsStructure(SettingsStructure, Header, , ExchangeNode);
	
	// Checking if the sender UID corresponds to the format.
	UID = Header.Confirmation.From;
	Try
		UID = New UUID(UID);
	Except
		Raise StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Идентификатор отправителя <%1> в файле с настройками EnterpriseData не соответствует ожидаемому формату GUID.'; en = 'The sender ID %1 in the EnterpriseData settings file does not match the expected GUID format.'; pl = 'Identyfikator nadawcy <%1> w pliku z ustawieniami EnterpriseData nie odpowiada formatu oczekiwanemu GUID.';de = 'Die Absender-ID <%1> in der EnterpriseData-Einstellungsdatei stimmt nicht mit dem erwarteten GUID-Format überein.';ro = 'Identificatorul expeditorului <%1> în fișierul cu setările EnterpriseData nu corespunde formatului așteptat GUID.';tr = 'EnterpriseData ayarlarına sahip bir dosyadaki <%1>  gönderenin kimliği GUID biçimle eşleşmiyor.'; es_ES = 'El identificador del remitente <%1> en el archivo con ajustes EnterpriseData no corresponde al formato esperado GUID.'"),
			UID);
	EndTry;
	
	SettingsStructure.Insert("SenderID", Header.Confirmation.From);
		
	XMLReader.Close();
	
	Return SettingsStructure;
	
EndFunction

#EndRegion

#EndRegion

#EndIf