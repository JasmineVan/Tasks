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
Procedure ExecuteAutomaticDataMapping(Parameters, TempStorageAddress) Export
	
	Result = AutomaticDataMappingResult(
		Parameters.InfobaseNode,
		Parameters.ExchangeMessageFileName,
		Parameters.TempExchangeMessageCatalogName,
		Parameters.CheckVersionDifference);
	
	PutToTempStorage(Result, TempStorageAddress);
		
EndProcedure

// For internal use.
// Imports an exchange message from the external source (ftp, email, network directory) to the 
//  temporary directory of the operational system user.
//
Procedure GetExchangeMessageToTemporaryDirectory(Parameters, TempStorageAddress) Export
	
	Cancel = False;
	SetPrivilegedMode(True);
	
	DataStructure = New Structure;
	DataStructure.Insert("TempExchangeMessageCatalogName", "");
	DataStructure.Insert("DataPackageFileID",       Undefined);
	DataStructure.Insert("ExchangeMessageFileName",              "");
	
	If Parameters.EmailReceivedForDataMapping Then
		
		Filter = New Structure("InfobaseNode", Parameters.InfobaseNode);
		CommonSettings = InformationRegisters.CommonInfobasesNodesSettings.Get(Filter);
		
		If ValueIsFilled(CommonSettings.MessageForDataMapping) Then
			TempFileName = DataExchangeServer.GetFileFromStorage(CommonSettings.MessageForDataMapping);
			
			File = New File(TempFileName);
			If File.Exist() AND File.IsFile() Then
				// Placing message information to be mapped back to the storage, in case the data analysis crashes, 
				// to be able to work with the message again.
				DataExchangeServer.PutFileInStorage(TempFileName, CommonSettings.MessageForDataMapping);
				
				DataPackageFileID = File.GetModificationTime();
				
				TempDirectoryNameForExchange = DataExchangeServer.CreateTempExchangeMessagesDirectory();
				TempFileNameForExchange    = CommonClientServer.GetFullFileName(
					TempDirectoryNameForExchange, DataExchangeServer.UniqueExchangeMessageFileName());
				
				FileCopy(TempFileName, TempFileNameForExchange);
				
				DataStructure.TempExchangeMessageCatalogName = TempDirectoryNameForExchange;
				DataStructure.DataPackageFileID       = DataPackageFileID;
				DataStructure.ExchangeMessageFileName              = TempFileNameForExchange;
				
			EndIf;
			
		EndIf;
		
		If IsBlankString(DataStructure.ExchangeMessageFileName) Then
			// A message file for mapping is not found.
			Cancel = True;
		EndIf;
		
	ElsIf Parameters.ExchangeMessagesTransportKind = Enums.ExchangeMessagesTransportTypes.COM Then
		
		DataStructure = DataExchangeServer.GetExchangeMessageFromCorrespondentInfobaseToTempDirectory(Cancel, Parameters.InfobaseNode, False);
		
	ElsIf Parameters.ExchangeMessagesTransportKind = Enums.ExchangeMessagesTransportTypes.WS Then
		
		DataStructure = DataExchangeServer.GetExchangeMessageToTempDirectoryFromCorrespondentInfobaseOverWebService(
			Cancel,
			Parameters.InfobaseNode,
			Parameters.FileID,
			Parameters.TimeConsumingOperation,
			Parameters.OperationID,
			Parameters.WSPassword);
		
	Else // FILE, FTP, EMAIL
		
		DataStructure = DataExchangeServer.GetExchangeMessageToTemporaryDirectory(Cancel, Parameters.InfobaseNode, Parameters.ExchangeMessagesTransportKind, False);
		
	EndIf;
	
	Parameters.Cancel                                = Cancel;
	Parameters.TempExchangeMessageCatalogName = DataStructure.TempExchangeMessageCatalogName;
	Parameters.DataPackageFileID       = DataStructure.DataPackageFileID;
	Parameters.ExchangeMessageFileName              = DataStructure.ExchangeMessageFileName;
	
	PutToTempStorage(Parameters, TempStorageAddress);
	
EndProcedure

// For internal use.
// Gets an exchange message from the correspondent infobase via web service to the temporary directory of OS user.
//
Procedure GetExchangeMessageFromCorrespondentToTemporaryDirectory(Parameters, TempStorageAddress) Export
	
	Cancel = False;
	
	SetPrivilegedMode(True);
	
	DataStructure = DataExchangeServer.GetExchangeMessageToTempDirectoryFromCorrespondentInfobaseOverWebServiceTimeConsumingOperationCompletion(
		Cancel,
		Parameters.InfobaseNode,
		Parameters.FileID,
		Parameters.WSPassword);
	
	Parameters.Cancel                                = Cancel;
	Parameters.TempExchangeMessageCatalogName = DataStructure.TempExchangeMessageCatalogName;
	Parameters.DataPackageFileID       = DataStructure.DataPackageFileID;
	Parameters.ExchangeMessageFileName              = DataStructure.ExchangeMessageFileName;
	
	PutToTempStorage(Parameters, TempStorageAddress);
	
EndProcedure

// For internal use.
//
Procedure RunDataImport(Parameters, TempStorageAddress) Export
	
	DataExchangeParameters = DataExchangeServer.DataExchangeParametersThroughFileOrString();
	
	DataExchangeParameters.InfobaseNode        = Parameters.InfobaseNode;
	DataExchangeParameters.FullNameOfExchangeMessageFile = Parameters.ExchangeMessageFileName;
	DataExchangeParameters.ActionOnExchange             = Enums.ActionsOnExchange.DataImport;
	
	DataExchangeServer.ExecuteDataExchangeForInfobaseNodeOverFileOrString(DataExchangeParameters);
	
EndProcedure

// For internal use.
// It exports data and is called by a background job.
// Parameters - a structure with parameters to pass.
Procedure RunDataExport(Parameters, TempStorageAddress) Export
	
	Cancel = False;
	
	ExchangeParameters = DataExchangeServer.ExchangeParameters();
	ExchangeParameters.ExecuteImport            = False;
	ExchangeParameters.ExecuteExport            = True;
	ExchangeParameters.TimeConsumingOperationAllowed  = True;
	ExchangeParameters.ExchangeMessagesTransportKind = Parameters.ExchangeMessagesTransportKind;
	ExchangeParameters.TimeConsumingOperation           = Parameters.TimeConsumingOperation;
	ExchangeParameters.OperationID        = Parameters.OperationID;
	ExchangeParameters.FileID           = Parameters.FileID;
	ExchangeParameters.AuthenticationParameters      = Parameters.WSPassword;
	
	DataExchangeServer.ExecuteDataExchangeForInfobaseNode(Parameters.InfobaseNode, ExchangeParameters, Cancel);
	
	Parameters.TimeConsumingOperation      = ExchangeParameters.TimeConsumingOperation;
	Parameters.OperationID   = ExchangeParameters.OperationID;
	Parameters.FileID      = ExchangeParameters.FileID;
	Parameters.WSPassword                = ExchangeParameters.AuthenticationParameters;
	Parameters.Cancel                   = Cancel;
	
	PutToTempStorage(Parameters, TempStorageAddress);
	
EndProcedure

// For internal use.
//
Function AllDataMapped(StatisticsInformation) Export
	
	Return (StatisticsInformation.FindRows(New Structure("PictureIndex", 1)).Count() = 0);
	
EndFunction

// For internal use.
//
Function HasUnmappedMasterData(StatisticsInformation) Export
	Return (StatisticsInformation.FindRows(New Structure("PictureIndex, IsMasterData", 1, True)).Count() > 0);
EndFunction

#Region DataRegistration

Procedure OnStartRecordData(RegistrationSettings, HandlerParameters, ContinueWait = True) Export
	
	BackgroundJobKey = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("ru = 'Регистрация данных для выгрузки (%1)'; en = 'Register data for export (%1)'; pl = 'Rejestracja danych do pobierania (%1)';de = 'Datenregistrierung für den Upload (%1)';ro = 'Înregistrarea datelor pentru export (%1)';tr = 'Dışa aktarılacak verilerin kaydı (%1)'; es_ES = 'Registro de datos para subir (%1)'"),
		RegistrationSettings.ExchangeNode);

	If HasActiveBackgroundJobs(BackgroundJobKey) Then
		Raise StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Регистрация данных для начальной выгрузки для ""%1"" уже выполняется.'; en = 'Data registration for initial export to ""%1"" is already running.'; pl = 'Rejestracja danych dla początkowego ładowania dla ""%1"" jest już wykonywane.';de = 'Die Datenregistrierung für den ersten Upload für ""%1"" ist bereits in Bearbeitung.';ro = 'Înregistrarea datelor pentru exportul inițial al datelor pentru ""%1"" deja se execută.';tr = '""%1"" için dışa aktarılacak ilk veriler zaten kaydediliyor.'; es_ES = 'Registro de datos para subida inicial para ""%1"" ya se está ejecutando.'"),
			RegistrationSettings.ExchangeNode);
	EndIf;
		
	ProcedureParameters = New Structure;
	ProcedureParameters.Insert("RegistrationSettings", RegistrationSettings);
	
	ExecutionParameters = TimeConsumingOperations.BackgroundExecutionParameters(New UUID);
	ExecutionParameters.BackgroundJobDescription = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("ru = 'Регистрация данных для выгрузки (%1).'; en = 'Register data for export (%1).'; pl = 'Rejestracja danych do pobierania (%1).';de = 'Datenregistrierung für den Upload (%1).';ro = 'Înregistrarea datelor pentru export (%1).';tr = 'Dışa aktarılacak verilerin kaydı (%1).'; es_ES = 'Registro de datos para subir (%1).'"),
		RegistrationSettings.ExchangeNode);
	ExecutionParameters.BackgroundJobKey = BackgroundJobKey;
	ExecutionParameters.RunNotInBackground    = False;
	ExecutionParameters.RunInBackground      = True;
	
	BackgroundJob = TimeConsumingOperations.ExecuteInBackground(
		"DataProcessors.InteractiveDataExchangeWizard.RegisterDataforExport",
		ProcedureParameters,
		ExecutionParameters);
		
	OnStartTimeConsumingOperation(BackgroundJob, HandlerParameters, ContinueWait);
	
EndProcedure

Procedure OnWaitForRecordData(HandlerParameters, ContinueWait = True) Export
	
	OnWaitTimeConsumingOperation(HandlerParameters, ContinueWait);
	
EndProcedure

Procedure OnCompleteDataRecording(HandlerParameters, CompletionStatus) Export
	
	OnCompleteTimeConsumingOperation(HandlerParameters, CompletionStatus);
	
EndProcedure

#EndRegion

#Region ExportMappingData

// For internal use.
//
Procedure OnStartExportDataForMapping(ExportSettings, HandlerParameters, ContinueWait = True) Export
	
	BackgroundJobKey = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("ru = 'Выгрузка данных для сопоставления (%1)'; en = 'Export mapping data (%1)'; pl = 'Pobieranie danych do porównania (%1)';de = 'Hochladen von Daten zum Vergleich (%1)';ro = 'Exportul datelor pentru confruntare (%1)';tr = 'Karşılaştırılacak verileri dışa aktarma (%1)'; es_ES = 'Subida de datos para comparar (%1)'"),
		ExportSettings.ExchangeNode);

	If HasActiveBackgroundJobs(BackgroundJobKey) Then
		Raise StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Выгрузка данных для сопоставления для ""%1"" уже выполняется.'; en = 'Export of mapping data for ""%1"" is already running.'; pl = 'Ładowanie danych dla dopasowania dla ""%1"" jest już wykonywane.';de = 'Die Daten für den Vergleich von ""%1"" werden bereits hochgeladen.';ro = 'Exportul datelor pentru confruntare pentru ""%1"" deja se execută.';tr = '""%1"" karşılaştırılacak veriler zaten dışa aktarılıyor.'; es_ES = 'La subida de datos para comparar para ""%1"" se está ejecutando ya.'"),
			ExportSettings.ExchangeNode);
	EndIf;
		
	ProcedureParameters = New Structure;
	ProcedureParameters.Insert("ExportSettings", ExportSettings);
	
	ExecutionParameters = TimeConsumingOperations.BackgroundExecutionParameters(New UUID);
	ExecutionParameters.BackgroundJobDescription = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("ru = 'Выгрузка данных для сопоставления (%1).'; en = 'Export mapping data (%1).'; pl = 'Pobieranie danych do porówniania (%1).';de = 'Hochladen von Daten zum Vergleich (%1).';ro = 'Exportul datelor pentru confruntare (%1).';tr = 'Karşılaştırılacak verileri dışa aktarma (%1).'; es_ES = 'Subida de datos para comparar (%1).'"),
		ExportSettings.ExchangeNode);
	ExecutionParameters.BackgroundJobKey = BackgroundJobKey;
	ExecutionParameters.RunNotInBackground    = False;
	ExecutionParameters.RunInBackground      = True;
	
	BackgroundJob = TimeConsumingOperations.ExecuteInBackground(
		"DataProcessors.InteractiveDataExchangeWizard.ExportDataForMapping",
		ProcedureParameters,
		ExecutionParameters);
		
	OnStartTimeConsumingOperation(BackgroundJob, HandlerParameters, ContinueWait);
	
EndProcedure

// For internal use.
//
Procedure OnCompleteExportDataForMapping(HandlerParameters, CompletionStatus) Export
	
	OnCompleteTimeConsumingOperation(HandlerParameters, CompletionStatus);
	
EndProcedure

#EndRegion

#EndRegion

#Region Private

Procedure RegisterDataforExport(Parameters, ResultAddress) Export
	
	RegistrationSettings = Undefined;
	Parameters.Property("RegistrationSettings", RegistrationSettings);
	
	Result = New Structure;
	Result.Insert("DataRegistered", True);
	Result.Insert("ErrorMessage",      "");
	
	StructureAddition = RegistrationSettings.ExportAddition;
	
	ExportAddition = DataProcessors.InteractiveExportModification.Create();
	FillPropertyValues(ExportAddition, StructureAddition, , "AdditionalRegistration, AdditionalNodeScenarioRegistration");
	
	ExportAddition.AllDocumentsFilterComposer.LoadSettings(StructureAddition.AllDocumentsSettingFilterComposer);
		
	DataExchangeServer.FillValueTable(ExportAddition.AdditionalRegistration, StructureAddition.AdditionalRegistration);
	DataExchangeServer.FillValueTable(ExportAddition.AdditionalNodeScenarioRegistration, StructureAddition.AdditionalNodeScenarioRegistration);
	
	If Not StructureAddition.AllDocumentsComposer = Undefined Then
		ExportAddition.AllDocumentsComposerAddress = PutToTempStorage(StructureAddition.AllDocumentsComposer);
	EndIf;
	
	// Saving export addition settings.
	DataExchangeServer.InteractiveExportModificationSaveSettings(ExportAddition, 
		DataExchangeServer.ExportAdditionSettingsAutoSavingName());
	
	// Registering additional data.
	Try
		DataExchangeServer.InteractiveExportModificationRegisterAdditionalData(ExportAddition);
	Except
		Result.DataRegistered = False;
		
		Information = ErrorInfo();
		
		Result.ErrorMessage = NStr("ru = 'Возникла проблема при добавлении данных к выгрузке:'; en = 'An issue occurred while adding data to export:'; pl = 'Wystąpił problem podczas dodawania danych do ładowania:';de = 'Beim Hinzufügen von Daten zum Upload ist ein Problem aufgetreten:';ro = 'Problemă la adăugarea datelor la export:';tr = 'Veriler dışa aktarmaya eklendiğinde bir sorun oluştu:'; es_ES = 'Se ha producido un error al añadir los datos en la subida:'") 
			+ Chars.LF + BriefErrorDescription(Information)
			+ Chars.LF + NStr("ru = 'Необходимо изменить условия отбора.'; en = 'Please change the filter conditions.'; pl = 'Należy zmienić warunki doboru.';de = 'Es ist notwendig, die Auswahlbedingungen zu ändern.';ro = 'Trebuie să modificați condițiile de filtrare.';tr = 'Seçim koşulları değiştirilmelidir.'; es_ES = 'Es necesario cambiar las condiciones de selección.'");
			
		WriteLogEvent(DataExchangeServer.DataExchangeCreationEventLogEvent(),
			EventLogLevel.Error, , , DetailErrorDescription(Information));
	EndTry;
	
	PutToTempStorage(Result, ResultAddress);
	
EndProcedure

Procedure ExportDataForMapping(Parameters, ResultAddress) Export
	
	ExportSettings = Undefined;
	Parameters.Property("ExportSettings", ExportSettings);
	
	Result = New Structure;
	Result.Insert("DataExported",   True);
	Result.Insert("ErrorMessage", "");
	
	ExchangeParameters = DataExchangeServer.ExchangeParameters();
	ExchangeParameters.ExecuteImport = False;
	ExchangeParameters.ExecuteExport = True;
	ExchangeParameters.ExchangeMessagesTransportKind = ExportSettings.TransportKind;
	ExchangeParameters.MessageForDataMapping = True;
	
	If ExportSettings.Property("WSPassword") Then
		ExchangeParameters.Insert("AuthenticationParameters", ExportSettings.WSPassword);
	EndIf;
	
	Cancel = False;
	Try
		DataExchangeServer.ExecuteDataExchangeForInfobaseNode(
			ExportSettings.ExchangeNode, ExchangeParameters, Cancel);
	Except
		Result.DataExported = False;
		Result.ErrorMessage = DetailErrorDescription(ErrorInfo());
		
		WriteLogEvent(DataExchangeServer.DataImportToMapEventLogEvent(),
			EventLogLevel.Error, , , Result.ErrorMessage);
	EndTry;
		
	Result.DataExported = Result.DataExported AND Not Cancel;
	
	If Not Result.DataExported
		AND IsBlankString(Result.ErrorMessage) Then
		Result.ErrorMessage = NStr("ru = 'При выполнении выгрузки данных для сопоставления возникли ошибки (см. Журнал регистрации).'; en = 'Errors occurred while exporting mapping data (see the event log).'; pl = 'Podczas wykonywania ładowania danych dla dopasowania wynikły błędy (patrz Dziennik rejestracji).';de = 'Beim Hochladen der Daten für den Vergleich sind Fehler aufgetreten (siehe Ereignisprotokoll).';ro = 'Erori la executarea exportului de date pentru confruntare (vezi Registrul logare).';tr = 'Karşılaştırılacak veri dışa aktarma işlemi sırasında hatalar oluştu (bkz. Kayıt günlüğü).'; es_ES = 'Al subir los datos para comparar se ha producido errores (véase el Registro).'");
	EndIf;
	
	PutToTempStorage(Result, ResultAddress);
	
EndProcedure

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

Function HasActiveBackgroundJobs(BackgroundJobKey)
	
	Filter = New Structure;
	Filter.Insert("Key",      BackgroundJobKey);
	Filter.Insert("State", BackgroundJobState.Active);
	
	ActiveBackgroundJobs = BackgroundJobs.GetBackgroundJobs(Filter);
	
	Return (ActiveBackgroundJobs.Count() > 0);
	
EndFunction

#EndRegion

// Analyzes the incoming exchange message. Fills in the Statistics table with data.
//
// Parameters:
//   Parameters - Structure
//   Cancel - Boolean - a cancellation flag. It is set to True if errors occur during the procedure execution.
//   ExchangeExecutionResult - EnumRef.ExchangeExecutionResults - the result of data exchange execution.
//
Function StatisticsTableExchangeMessages(Parameters,
		Cancel, ExchangeExecutionResult = Undefined, ErrorMessage = "")
		
	StatisticsInformation = Undefined;	
	InitializeStatisticsTable(StatisticsInformation);
	
	TempExchangeMessagesDirectoryName = Parameters.TempExchangeMessageCatalogName;
	InfobaseNode               = Parameters.InfobaseNode;
	ExchangeMessageFileName              = Parameters.ExchangeMessageFileName;
	
	If IsBlankString(TempExchangeMessagesDirectoryName) Then
		// Data from the correspondent infobase cannot be received.
		Cancel = True;
		Return StatisticsInformation;
	EndIf;
	
	SetPrivilegedMode(True);
	
	ExchangeSettingsStructure = DataExchangeServer.ExchangeSettingsStructureForInteractiveImportSession(
		InfobaseNode, ExchangeMessageFileName);
	
	If ExchangeSettingsStructure.Cancel Then
		Return StatisticsInformation;
	EndIf;
	
	DataExchangeDataProcessor = ExchangeSettingsStructure.DataExchangeDataProcessor;
	
	AnalysisParameters = New Structure("CollectClassifiersStatistics", True);	
	DataExchangeDataProcessor.ExecuteExchangeMessageAnalysis(AnalysisParameters);
	
	ExchangeExecutionResult = DataExchangeDataProcessor.ExchangeExecutionResult();
	
	If DataExchangeDataProcessor.ErrorFlag() Then
		Cancel = True;
		ErrorMessage = DataExchangeDataProcessor.ErrorMessageString();
		Return StatisticsInformation;
	EndIf;
	
	PackageHeaderDataTable = DataExchangeDataProcessor.PackageHeaderDataTable();
	For Each BatchTitleDataLine In PackageHeaderDataTable Do
		StatisticsInformationString = StatisticsInformation.Add();
		FillPropertyValues(StatisticsInformationString, BatchTitleDataLine);
	EndDo;
	
	// Supplying the statistic table with utility data
	ErrorMessage = "";
	SupplementStatisticTable(StatisticsInformation, Cancel, ErrorMessage);
	
	// Determining table strings with the OneToMany flag
	TempStatistics = StatisticsInformation.Copy(, "DestinationTableName, IsObjectDeletion");
	
	AddColumnWithValueToTable(TempStatistics, 1, "Iterator");
	
	TempStatistics.GroupBy("DestinationTableName, IsObjectDeletion", "Iterator");
	
	For Each TableRow In TempStatistics Do
		
		If TableRow.Iterator > 1 AND Not TableRow.IsObjectDeletion Then
			
			StatisticsInformationRows = StatisticsInformation.FindRows(New Structure("DestinationTableName, IsObjectDeletion",
				TableRow.DestinationTableName, TableRow.IsObjectDeletion));
			
			For Each StatisticsInformationString In StatisticsInformationRows Do
				
				StatisticsInformationString["OneToMany"] = True;
				
			EndDo;
			
		EndIf;
		
	EndDo;
	
	Return StatisticsInformation;
	
EndFunction

// For internal use.
//
Function AutomaticDataMappingResult(Val Correspondent,
		Val ExchangeMessageFileName, Val TempExchangeMessagesDirectoryName, CheckVersionDifference)
		
	Result = New Structure;
	Result.Insert("StatisticsInformation",      Undefined);
	Result.Insert("AllDataMapped",     True);
	Result.Insert("HasUnmappedMasterData",   False);
	Result.Insert("StatisticsBlank",          True);
	Result.Insert("Cancel",                     False);
	Result.Insert("ErrorMessage",         "");
	Result.Insert("ExchangeExecutionResult", Undefined);
	
	// Mapping data received from a correspondent.
	// Getting mapping statistics.
	SetPrivilegedMode(True);
	
	DataExchangeServer.InitializeVersionDifferenceCheckParameters(CheckVersionDifference);
	
	// Analyzing exchange messages.
	AnalysisParameters = New Structure;
	AnalysisParameters.Insert("TempExchangeMessageCatalogName", TempExchangeMessagesDirectoryName);
	AnalysisParameters.Insert("InfobaseNode",               Correspondent);
	AnalysisParameters.Insert("ExchangeMessageFileName",              ExchangeMessageFileName);
	
	StatisticsInformation = StatisticsTableExchangeMessages(AnalysisParameters,
		Result.Cancel, Result.ExchangeExecutionResult, Result.ErrorMessage);
	
	If Result.Cancel Then
		If SessionParameters.VersionMismatchErrorOnGetData.HasError Then
			Return SessionParameters.VersionMismatchErrorOnGetData;
		EndIf;
		
		Return Result;
	EndIf;
	
	InteractiveDataExchangeWizard = Create();
	InteractiveDataExchangeWizard.InfobaseNode = Correspondent;
	InteractiveDataExchangeWizard.ExchangeMessageFileName = ExchangeMessageFileName;
	InteractiveDataExchangeWizard.TempExchangeMessageCatalogName = TempExchangeMessagesDirectoryName;
	InteractiveDataExchangeWizard.ExchangePlanName = DataExchangeCached.GetExchangePlanName(Correspondent);
	InteractiveDataExchangeWizard.ExchangeMessagesTransportKind = Undefined;
	
	InteractiveDataExchangeWizard.StatisticsInformation.Load(StatisticsInformation);
	
	// Mapping data and getting statistics.
	InteractiveDataExchangeWizard.ExecuteDefaultAutomaticMappingAndGetMappingStatistics(Result.Cancel);
	
	If Result.Cancel Then
		Raise StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Не удалось загрузить данные из ""%1"" (этап автоматического сопоставления данных).'; en = 'Cannot import data from ""%1"" (automatic data mapping step).'; pl = 'Nie można importować danych z ""%1"" (krok automatycznego mapowania danych)';de = 'Daten von ""%1"" (automatischer Datenabbildungsschritt) können nicht importiert werden.';ro = 'Nu se poate importa date din ""%1"" (pasul automat de mapare a datelor).';tr = 'Veriler ""%1"" (otomatik veri eşlenme adımı) ''dan içe aktarılamıyor.'; es_ES = 'No se puede importar los datos de ""%1"" (paso de mapeo automático de datos).'"),
			Common.ObjectAttributeValue(Correspondent, "Description"));
	EndIf;
	
	StatisticsTable = InteractiveDataExchangeWizard.StatisticsTable();
	
	Result.StatisticsInformation    = StatisticsTable;
	Result.AllDataMapped   = AllDataMapped(StatisticsTable);
	Result.StatisticsBlank        = (StatisticsTable.Count() = 0);
	Result.HasUnmappedMasterData = HasUnmappedMasterData(StatisticsTable);
	
	Return Result;
	
EndFunction

Procedure InitializeStatisticsTable(StatisticsTable)
	
	StatisticsTable = New ValueTable;
	StatisticsTable.Columns.Add("DataImportedSuccessfully", New TypeDescription("Boolean"));
	StatisticsTable.Columns.Add("DestinationTableName", New TypeDescription("String"));
	StatisticsTable.Columns.Add("PictureIndex", New TypeDescription("Number"));
	StatisticsTable.Columns.Add("UsePreview", New TypeDescription("Boolean"));
	StatisticsTable.Columns.Add("Key", New TypeDescription("String"));
	StatisticsTable.Columns.Add("ObjectCountInSource", New TypeDescription("Number"));
	StatisticsTable.Columns.Add("ObjectCountInDestination", New TypeDescription("Number"));
	StatisticsTable.Columns.Add("UnmappedObjectCount", New TypeDescription("Number"));
	StatisticsTable.Columns.Add("MappedObjectCount", New TypeDescription("Number"));
	StatisticsTable.Columns.Add("OneToMany", New TypeDescription("Boolean"));
	StatisticsTable.Columns.Add("SearchFields", New TypeDescription("String"));
	StatisticsTable.Columns.Add("TableFields", New TypeDescription("String"));
	StatisticsTable.Columns.Add("Presentation", New TypeDescription("String"));
	StatisticsTable.Columns.Add("MappedObjectPercentage", New TypeDescription("Number"));
	StatisticsTable.Columns.Add("SynchronizeByID", New TypeDescription("Boolean"));
	StatisticsTable.Columns.Add("SourceTypeString", New TypeDescription("String"));
	StatisticsTable.Columns.Add("ObjectTypeString", New TypeDescription("String"));
	StatisticsTable.Columns.Add("DestinationTypeString", New TypeDescription("String"));
	StatisticsTable.Columns.Add("IsClassifier", New TypeDescription("Boolean"));
	StatisticsTable.Columns.Add("IsObjectDeletion", New TypeDescription("Boolean"));
	StatisticsTable.Columns.Add("IsMasterData", New TypeDescription("Boolean"));
	
EndProcedure

Procedure SupplementStatisticTable(StatisticsInformation, Cancel, ErrorMessage = "")
	
	For Each TableRow In StatisticsInformation Do
		
		Try
			Type = Type(TableRow.ObjectTypeString);
		Except
			Cancel = True;
			ErrorMessage = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'Ошибка: тип ""%1"" не определен.'; en = 'Error: the %1 type is not defined.'; pl = 'Błąd: typ ""%1"" nie jest zdefiniowany.';de = 'Fehler: Der Typ ""%1"" ist nicht definiert.';ro = 'Eroare: nu este definit tipul ""%1"".';tr = 'Hata: ""%1"" tipi tanımlanmamış.'; es_ES = 'Error: el tipo ""%1"" no está definido.'"), TableRow.ObjectTypeString);
			Break;
		EndTry;
		
		ObjectMetadata = Metadata.FindByType(Type);
		
		TableRow.DestinationTableName = ObjectMetadata.FullName();
		TableRow.Presentation       = ObjectMetadata.Presentation();
		
		TableRow.Key = String(New UUID);
		
	EndDo;
	
EndProcedure

Procedure AddColumnWithValueToTable(Table, IteratorValue, IteratorFieldName)
	
	Table.Columns.Add(IteratorFieldName);
	
	Table.FillValues(IteratorValue, IteratorFieldName);
	
EndProcedure

#EndRegion

#EndIf