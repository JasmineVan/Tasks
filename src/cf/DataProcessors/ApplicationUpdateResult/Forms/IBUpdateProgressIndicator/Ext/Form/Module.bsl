///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Variables

&AtClient
Var ContinuationParameters;
&AtClient
Var UpdateExecutionResult;
&AtClient
Var CompletionProcessing;

#EndRegion

#Region EventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	IBUpdateInProgress = True;
	UpdateStartTime = CurrentSessionDate();
	
	ClientServer  = Not Common.FileInfobase();
	Box       = Not Common.DataSeparationEnabled();
	
	ExecutionProgress = 5;
	
	DataUpdateMode = InfobaseUpdateInternal.DataUpdateMode();
	
	UpdateApplicationParametersOnly =
		Not InfobaseUpdate.InfobaseUpdateRequired();
	
	If UpdateApplicationParametersOnly Then
		Title = NStr("ru = 'Обновление параметров работы программы'; en = 'Application parameters update'; pl = 'Zaktualizuj parametry aplikacji';de = 'Anwendungsparameter';ro = 'Actualizarea parametrilor de lucru ai aplicației';tr = 'Uygulama parametrelerini güncelle'; es_ES = 'Actualizar los parámetros de la aplicación'");
		Items.RunMode.CurrentPage = Items.ApplicationParametersUpdate;
		
	ElsIf DataUpdateMode = "InitialFilling" Then
		Title = NStr("ru = 'Начальное заполнение данных'; en = 'Data population'; pl = 'Początkowe wypełnienie danych';de = 'Anfangsdatenpopulation';ro = 'Completarea inițială a datelor';tr = 'İlk veri doldurulması'; es_ES = 'Población inicial de datos'");
		Items.RunMode.CurrentPage = Items.InitialFilling;
		
	ElsIf DataUpdateMode = "MigrationFromAnotherApplication" Then
		Title = NStr("ru = 'Переход с другой программы'; en = 'Migration from another application'; pl = 'Migracja z innej aplikacji';de = 'Migration von einer anderen Anwendung';ro = 'Migrarea dintr-o altă aplicație';tr = 'Başka bir uygulamadan geçiş'; es_ES = 'Migración de otra aplicación'");
		Items.RunMode.CurrentPage = Items.MigrationFromAnotherApplication;
		Items.MigrationFromAnotherApplicationMessageText.Title = StringFunctionsClientServer.SubstituteParametersToString(
			Items.MigrationFromAnotherApplicationMessageText.Title, Metadata.Synonym);
	Else
		Title = NStr("ru = 'Обновление версии программы'; en = 'Application update'; pl = 'Aktualizacja wersji aplikacji';de = 'Aktualisierung der Anwendungsversion';ro = 'Actualizarea versiunii programului';tr = 'Uygulama sürümünün güncelemesi'; es_ES = 'Actualización de la versión de la aplicación'");
		Items.RunMode.CurrentPage = Items.ApplicationVersionUpdate;
		Items.NewConfigurationVersionMessageText.Title = StringFunctionsClientServer.SubstituteParametersToString(
			Items.NewConfigurationVersionMessageText.Title, Metadata.Version);
	EndIf;
	
EndProcedure

&AtClient
Procedure BeforeClose(Cancel, Exit, WarningText, StandardProcessing)
	If IBUpdateInProgress Then
		Cancel = True;
	EndIf;
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure TechnicalInformationClick(Item)
	
	FilterParameters = New Structure;
	FilterParameters.Insert("RunNotInBackground", True);
	FilterParameters.Insert("StartDate", UpdateStartTime);
	EventLogClient.OpenEventLog(FilterParameters);
	
EndProcedure

#EndRegion

#Region Private

////////////////////////////////////////////////////////////////////////////////
// Update of application parameters and shared data in SaaS mode.

&AtClient
Procedure ImportUpdateApplicationParameters(Parameters) Export
	
	ContinuationParameters = Parameters;
	AttachIdleHandler("StartUpdateApplicationParameters", 0.1, True);
	
EndProcedure

&AtClient
Procedure StartUpdateApplicationParameters()
	
	ExecutionResult = ImportUpdateApplicationParametersInBackground();
	
	AdditionalParameters = New Structure("BriefErrorPresentation, DetailedErrorPresentation");
	
	If ExecutionResult = "StartupNotRequired" Then
		Result = New Structure("Status", "StartupNotRequired");
		CompleteUpdatingApplicationParameters(Result, AdditionalParameters);
		Return;
	ElsIf ExecutionResult = "SessionRestartRequired" Then
		Terminate(True);
	EndIf;
	
	CompletionNotification = New NotifyDescription("CompleteUpdatingApplicationParameters",
		ThisObject, AdditionalParameters);
	IdleParameters = TimeConsumingOperationsClient.IdleParameters(ThisObject);
	IdleParameters.OutputIdleWindow = False;
	IdleParameters.Interval = 2;
	IdleParameters.OutputProgressBar = True;
	IdleParameters.ExecutionProgressNotification = New NotifyDescription("ApplicationParametersUpdateProgress", ThisObject); 
	TimeConsumingOperationsClient.WaitForCompletion(ExecutionResult, CompletionNotification, IdleParameters);
	
EndProcedure

&AtServer
Function ImportUpdateApplicationParametersInBackground()
	
	RefreshReusableValues();
	
	If Common.DataSeparationEnabled()
	   AND Common.SeparatedDataUsageAvailable() Then
		
		Return "StartupNotRequired";
	EndIf;
	
	If Common.SubsystemExists("StandardSubsystems.ConfigurationUpdate") Then
		ModuleSoftwareUpdate = Common.CommonModule("ConfigurationUpdate");
		Result = ModuleSoftwareUpdate.PatchesChanged();
		If Result.HasChanges Then
			Return "SessionRestartRequired";
		EndIf;
	EndIf;
	
	// Calling a time-consuming operation (usually in a background job).
	Return InformationRegisters.ApplicationParameters.ImportUpdateApplicationParametersInBackground(0,
		UUID, True);
	
EndFunction

&AtClient
Procedure ApplicationParametersUpdateProgress(Progress, AdditionalParameters) Export
	
	If Progress = Undefined Then
		Return;
	EndIf;
	
	If Progress.Status <> "Running" Then
		Return;
	EndIf;
	
	If Progress.Progress <> Undefined Then
		
		If UpdateApplicationParametersOnly Then
			ExecutionProgress = 5 + (90 * Progress.Progress.Percent / 100);
		Else
			ExecutionProgress = 5 + (5 * Progress.Progress.Percent / 100);
		EndIf;
	EndIf;
		
EndProcedure

&AtClient
Procedure CompleteUpdatingApplicationParameters(Result, AdditionalParameters) Export
	
	Try
		ProcessedResult = ProcessedTimeConsumingOperationResult(Result);
	Except
		ErrorInformation = ErrorInfo();
		ProcessedResult = New Structure;
		ProcessedResult.Insert("BriefErrorPresentation",
			BriefErrorDescription(ErrorInformation));
		ProcessedResult.Insert("DetailedErrorPresentation",
			DetailErrorDescription(ErrorInformation));
	EndTry;
	
	If ValueIsFilled(ProcessedResult.BriefErrorPresentation) Then
		UnsuccessfulUpdateMessage(ProcessedResult, Undefined);
		Return;
	EndIf;
	
	ExecutionProgress = ?(UpdateApplicationParametersOnly, 95, 10);
	
	ContinuationParameters.RetrievedClientParameters.Insert("ApplicationParametersUpdateRequired");
	ContinuationParameters.Insert("CountOfReceivedClientParameters",
		ContinuationParameters.RetrievedClientParameters.Count());
	
	RefreshReusableValues();
	
	Try
		ClientParameters = StandardSubsystemsClient.ClientParametersOnStart();
	Except
		ErrorInformation = ErrorInfo();
		AdditionalParameters.Insert("BriefErrorPresentation", BriefErrorDescription(ErrorInformation));
		AdditionalParameters.Insert("DetailedErrorPresentation", DetailErrorDescription(ErrorInformation));
		UnsuccessfulUpdateMessage(AdditionalParameters, Undefined);
		Return;
	EndTry;
	
	If Not UpdateApplicationParametersOnly
	   AND ClientParameters.SeparatedDataUsageAvailable Then
		
		ExecuteNotifyProcessing(ContinuationParameters.ContinuationHandler);
		Return;
	EndIf;
		
	If ClientParameters.Property("SharedInfobaseDataUpdateRequired") Then
		Try
			InfobaseUpdateInternalServerCall.UpdateInfobase(True);
		Except
			ErrorInformation = ErrorInfo();
			AdditionalParameters.Insert("BriefErrorPresentation",   BriefErrorDescription(ErrorInformation));
			AdditionalParameters.Insert("DetailedErrorPresentation", DetailErrorDescription(ErrorInformation));
		EndTry;
		If ValueIsFilled(AdditionalParameters.BriefErrorPresentation) Then
			UnsuccessfulUpdateMessage(AdditionalParameters, Undefined);
			Return;
		EndIf;
	EndIf;
	
	If IBLock <> Undefined
		AND IBLock.Property("RemoveFileInfobaseLock") Then
		InfobaseUpdateInternalServerCall.RemoveFileInfobaseLock();
	EndIf;
	CloseForm(False, False);
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Infobase update (entire infobase update in local mode, or data area update in SaaS mode).

&AtClient
Procedure UpdateInfobase() Export
	
	ExecutionProgress = 10;
	AttachIdleHandler("StartInfobaseUpdate", 0.1, True);
	
EndProcedure

&AtClient
Procedure StartInfobaseUpdate()
	
	UpdateStartTime = CommonClient.SessionDate();
	
	IBUpdateResult = UpdateInfobaseInBackground();
	
	If Not IBUpdateResult.Property("ResultAddress") Then
		CompleteInfobaseUpdate(IBUpdateResult, Undefined);
		Return;
	EndIf;
	
	If ClientServer AND Box Then
		ContinuationProcedure = "RegisterDataForDeferredUpdate";
	Else
		ContinuationProcedure = "CompleteInfobaseUpdate";
	EndIf;
	
	CompletionNotification = New NotifyDescription(ContinuationProcedure, ThisObject);
	IdleParameters = TimeConsumingOperationsClient.IdleParameters(ThisObject);
	IdleParameters.OutputIdleWindow = False;
	IdleParameters.OutputProgressBar = True;
	IdleParameters.OutputMessages = True;
	IdleParameters.ExecutionProgressNotification = New NotifyDescription("InfobaseUpdateProgress", ThisObject); 
	TimeConsumingOperationsClient.WaitForCompletion(IBUpdateResult, CompletionNotification, IdleParameters);
	
EndProcedure

&AtServer
Function UpdateInfobaseInBackground()
	
	Result = InfobaseUpdateInternal.UpdateInfobaseInBackground(UUID, IBLock);
	IBLock = Result.IBLock;
	Return Result;
	
EndFunction

&AtClient
Procedure InfobaseUpdateProgress(Progress, AdditionalParameters) Export
	
	If Progress = Undefined Then
		Return;
	EndIf;
	
	If Progress.Status = "Error" Then
		Return;
	EndIf;
	
	If Progress.Property("AdditionalParameters")
		AND Progress.AdditionalParameters.Property("DataExchange") Then
		Return;
	EndIf;
	
	If Progress.Progress <> Undefined Then
		ExecutionProgress = 10 + (90 * Progress.Progress.Percent / 100);
	EndIf;
	ProcessRegistrationRuleError(Progress.Messages);
	
EndProcedure

&AtClient
Procedure CompleteInfobaseUpdate(Result, AdditionalParameters) Export
	
	If Result = Undefined Or Result.Status = "Canceled" Then
		
		HandlersExecutionFlag = IBLock.Error;
		
	ElsIf Result.Status = "Completed"  Then
		
		UpdateResult = GetFromTempStorage(Result.ResultAddress);
		If TypeOf(UpdateResult) = Type("Structure") Then
			If UpdateResult.Property("BriefErrorPresentation")
				AND UpdateResult.Property("DetailedErrorPresentation") Then
				Result.BriefErrorPresentation = UpdateResult.BriefErrorPresentation;
				Result.DetailedErrorPresentation = UpdateResult.DetailedErrorPresentation;
			Else
				HandlersExecutionFlag = UpdateResult.Result;
				SetSessionParametersFromBackgroundJob(UpdateResult.ClientParametersAtServer);
				ExecutionProgress = 100;
			EndIf;
		Else
			HandlersExecutionFlag = UpdateResult;
		EndIf;
		ProcessRegistrationRuleError(Result.Messages);
		
	Else // error
		HandlersExecutionFlag = IBLock.Error;
	EndIf;
	
	If HandlersExecutionFlag = "LockScheduledJobsExecution" Then
		RestartWithScheduledJobExecutionLock();
	EndIf;
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("DocumentUpdateDetails", Undefined);
	AdditionalParameters.Insert("BriefErrorPresentation", Result.BriefErrorPresentation);
	AdditionalParameters.Insert("DetailedErrorPresentation", Result.DetailedErrorPresentation);
	AdditionalParameters.Insert("UpdateStartTime", UpdateStartTime);
	AdditionalParameters.Insert("UpdateEndTime", CommonClient.SessionDate());
	AdditionalParameters.Insert("HandlersExecutionFlag", HandlersExecutionFlag);
	
	If HandlersExecutionFlag = "ExclusiveModeSettingError" Then
		
		UpdateInfobaseWhenCannotSetExclusiveMode(AdditionalParameters);
		Return;
		
	EndIf;
	
	RemoveFileInfobaseLock = False;
	If IBLock.Property("RemoveFileInfobaseLock", RemoveFileInfobaseLock) Then
		
		If RemoveFileInfobaseLock Then
			InfobaseUpdateInternalServerCall.RemoveFileInfobaseLock();
		EndIf;
		
	EndIf;
	
	UpdateInfobaseCompletion(AdditionalParameters);
	
EndProcedure

&AtClient
Procedure ProcessRegistrationRuleError(UserMessages)
	
	// See DataExchangeEvents.ProcessRegistrationRulesError 
	If UserMessages <> Undefined Then
		For Each UserMessage In UserMessages Do
			
			StringBeginning = "DataExchange=";
			If StrStartsWith(UserMessage.Text, StringBeginning) Then
				ExchangePlanName = Mid(UserMessage.Text, StrLen(StringBeginning) + 1);
			EndIf;
			
		EndDo;
	EndIf;

EndProcedure

&AtClient
Procedure UpdateInfobaseWhenCannotSetExclusiveMode(AdditionalParameters)
	
	If AdditionalParameters.HandlersExecutionFlag <> "ExclusiveModeSettingError" Then
		UpdateInfobaseCompletion(AdditionalParameters);
		Return;
	EndIf;
	
	If Not CommonClient.SubsystemExists("StandardSubsystems.UserSessionsCompletion") Then
		UnsuccessfulUpdateMessage(AdditionalParameters, Undefined);
		Return;
	EndIf;
	
	// Opening a form for disabling active sessions.
	Notification = New NotifyDescription("UpdateInfobaseWhenCannotSetExclusiveModeCompletion",
		ThisObject, AdditionalParameters);
	
	ModuleIBConnectionsClient = CommonClient.CommonModule("IBConnectionsClient");
	ModuleIBConnectionsClient.OnOpenExclusiveModeSetErrorForm(Notification);
	
EndProcedure

&AtClient
Procedure UpdateInfobaseWhenCannotSetExclusiveModeCompletion(Cancel, AdditionalParameters) Export
	
	If Cancel <> False Then
		CloseForm(True, False);
		Return;
	EndIf;
	
	SetIBLockParametersWhenCannotSetExclusiveMode();
	StartInfobaseUpdate();
	
EndProcedure

&AtClient
Procedure SetIBLockParametersWhenCannotSetExclusiveMode()
	
	If IBLock = Undefined Then
		IBLock = New Structure;
	EndIf;
	
	IBLock.Insert("Use", False);
	IBLock.Insert("RemoveFileInfobaseLock", True);
	IBLock.Insert("Error", Undefined);
	IBLock.Insert("NonexclusiveUpdate", Undefined);
	IBLock.Insert("RecordKey", Undefined);
	IBLock.Insert("DebugMode", Undefined);
	
EndProcedure

&AtClient
Procedure UpdateInfobaseCompletion(AdditionalParameters)
	
	If ValueIsFilled(AdditionalParameters.BriefErrorPresentation) Then
		
		UpdateEndTime = CommonClient.SessionDate();
		UnsuccessfulUpdateMessage(AdditionalParameters, UpdateEndTime);
		Return;
		
	EndIf;
	
	UpdateInfobaseCompletionServer(AdditionalParameters);
	RefreshReusableValues();
	
	CloseForm(False, False);
	
EndProcedure

&AtServer
Procedure UpdateInfobaseCompletionServer(AdditionalParameters)
	
	// If infobase update is completed, unlock the infobase.
	InfobaseUpdateInternal.UnlockIB(IBLock);
	InfobaseUpdateInternal.WriteUpdateExecutionTime(
		AdditionalParameters.UpdateStartTime, AdditionalParameters.UpdateEndTime);
	
EndProcedure

&AtClient
Procedure CloseForm(Cancel, Restart)
	
	IBUpdateInProgress = False;
	Close(New Structure("Cancel, Restart", Cancel, Restart));
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Registering data for the parallel deferred update.

&AtClient
Procedure RegisterDataForDeferredUpdate(Result, AdditionalParameters) Export
	
	UpdateResult = GetFromTempStorage(Result.ResultAddress);
	
	CompletionProcessing = New NotifyDescription("CompleteInfobaseUpdate", ThisObject, Result);
	UpdateExecutionResult = Result;
	If Result.Status <> "Completed"
		Or (TypeOf(UpdateResult) = Type("Structure")
			AND UpdateResult.Property("BriefErrorPresentation")
			AND UpdateResult.Property("DetailedErrorPresentation")) Then
		ExecuteNotifyProcessing(CompletionProcessing, UpdateExecutionResult);
		Return;
	EndIf;
	
	RegistrationState = FillDataForParallelDeferredUpdate();
	If RegistrationState.Status <> "Running" Then
		FillPropertyValues(UpdateExecutionResult, RegistrationState, "Status,BriefErrorPresentation,DetailedErrorPresentation");
		ExecuteNotifyProcessing(CompletionProcessing, UpdateExecutionResult);
	Else
		JobID = RegistrationState.JobID;
		AttachIdleHandler("Attachable_CheckDeferredHandlersFillingProcedures", 5);
	EndIf;
	
EndProcedure

&AtServer
Function FillDataForParallelDeferredUpdate()
	
	// Clearing the InfobaseUpdate exchange plan.
	If Not (StandardSubsystemsCached.DIBUsed("WithFilter") AND Common.IsSubordinateDIBNode()) Then
		Query = New Query;
		Query.Text = 
		"SELECT
		|	InfobaseUpdate.Ref AS Node
		|FROM
		|	ExchangePlan.InfobaseUpdate AS InfobaseUpdate
		|WHERE
		|	NOT InfobaseUpdate.ThisNode";
		
		Selection = Query.Execute().Select();
		While Selection.Next() Do
			ExchangePlans.DeleteChangeRecords(Selection.Node);
		EndDo;
	EndIf;
	
	UpdateInfo = InfobaseUpdateInternal.InfobaseUpdateInfo();
	UpdateInfo.DataToProcess = New Map;
	DataToProcess = UpdateInfo.DataToProcess;
	LibraryDescriptions    = StandardSubsystemsCached.SubsystemsDetails().ByNames;
	
	For Each LibraryDescription In UpdateInfo.HandlersTree.Rows Do
		If LibraryDescriptions[LibraryDescription.LibraryName].DeferredHandlerExecutionMode <> "Parallel" Then
			InfobaseUpdateInternal.CanlcelDeferredUpdateHandlersRegistration(LibraryDescription.LibraryName, True);
			Continue;
		EndIf;
		
		ParallelSinceVersion = LibraryDescriptions[LibraryDescription.LibraryName].ParralelDeferredUpdateFromVersion;
		For Each VersionDetails In LibraryDescription.Rows Do
			If VersionDetails.VersionNumber = "*" Then
				Continue;
			EndIf;
			
			If ValueIsFilled(ParallelSinceVersion)
				AND CommonClientServer.CompareVersions(VersionDetails.VersionNumber, ParallelSinceVersion) < 0 Then
				Continue;
			EndIf;
			
			For Each HandlerDetails In VersionDetails.Rows Do
				DataToProcessDetails = InfobaseUpdateInternal.NewDataToProcessDetails(
					HandlerDetails.Multithreaded,
					True);
				
				If HandlerDetails.Multithreaded Then
					DataToProcessDetails.SelectionParameters =
						InfobaseUpdate.AdditionalMultithreadProcessingDataSelectionParameters();
				EndIf;
				
				DataToProcessDetails.HandlerName = HandlerDetails.HandlerName;
				DataToProcessDetails.Queue = HandlerDetails.DeferredProcessingQueue;
				DataToProcessDetails.FillingProcedure = HandlerDetails.UpdateDataFillingProcedure;
				DataToProcess[HandlerDetails.HandlerName] = DataToProcessDetails;
			EndDo;
		EndDo;
		
	EndDo;
	
	InfobaseUpdateInternal.WriteInfobaseUpdateInfo(UpdateInfo);
	
	If Not Common.IsSubordinateDIBNode()
		AND Common.SubsystemExists("StandardSubsystems.DataExchange") Then
		ModuleDataExchangeServer = Common.CommonModule("DataExchangeServer");
		ModuleDataExchangeServer.ClearConstantValueWithChangesForSUbordinateDIBNodeWithFilters();
	EndIf;
	
	RegistrationProgress = New Structure;
	RegistrationProgress.Insert("InitialProgress", ExecutionProgress);
	RegistrationProgress.Insert("TotalProcedureCount", DataToProcess.Count());
	RegistrationProgress.Insert("ProceduresCompleted", 0);
	
	// Unlocking the infobase and executing the registration on the exchange plan.
	InfobaseUpdateInternal.UnlockIB(IBLock);
	
	Return StartDeferredHandlerFillingProcedures();
	
EndFunction

&AtClient
Procedure Attachable_CheckDeferredHandlersFillingProcedures()
	
	Result = CheckDeferredHandlerFillingProcedures();
	
	If Result.Status <> "Running" Then
		FillPropertyValues(UpdateExecutionResult, Result);
		ExecuteNotifyProcessing(CompletionProcessing, UpdateExecutionResult);
		DetachIdleHandler("Attachable_CheckDeferredHandlersFillingProcedures");
	EndIf;
	
EndProcedure

&AtServer
Function StartDeferredHandlerFillingProcedures()
	
	ExecutionParameters = TimeConsumingOperations.BackgroundExecutionParameters(UUID);
	ExecutionParameters.BackgroundJobDescription = NStr("ru = 'Управление многопоточной регистрацией данных отложенного обновления'; en = 'Manage multi-threaded registration of deferred update data'; pl = 'Zarządzanie wielopotokową rejestracją danych odłożonej aktualizacji';de = 'Verwalten Sie die Registrierung von ausstehenden Aktualisierungsdaten für mehrere Threads';ro = 'Administrarea înregistrării multi-flux a datelor de actualizare amânată';tr = 'Ertelenmiş güncelleme verilerinin çok akışlı kaydını yönetme'; es_ES = 'Gestión del registro de muchos flujos de los datos de actualización aplazada'");
	
	ProcedureName = "InfobaseUpdateInternal.StartDeferredHandlerDataRegistration";
	ExecutionResult = TimeConsumingOperations.ExecuteInBackground(ProcedureName, UUID, ExecutionParameters);
	
	Return CheckDeferredHandlerFillingProcedures(ExecutionResult);
	
EndFunction

&AtServer
Function CheckDeferredHandlerFillingProcedures(ControllingBackgroundJobExecutionResult = Undefined)
	
	If ControllingBackgroundJobExecutionResult = Undefined Then
		ControllingBackgroundJobExecutionResult = TimeConsumingOperations.ActionCompleted(JobID);
	EndIf;
	
	UpdateInfo = InfobaseUpdateInternal.InfobaseUpdateInfo();
	Status = ControllingBackgroundJobExecutionResult.Status;
	
	If Status = "Completed" Then
		InfobaseUpdateInternal.CanlcelDeferredUpdateHandlersRegistration();
	ElsIf Status = "Error" Or Status = "Canceled" Then
		InfobaseUpdateInternal.CancelAllThreadsExecution(UpdateInfo.ThreadsDetails);
		InfobaseUpdateInternal.WriteInfobaseUpdateInfo(UpdateInfo);
		Return ControllingBackgroundJobExecutionResult;
	EndIf;
	
	// Refreshing progress.
	ProceduresCompleted = 0;
	For Each DataToProcessDetails In UpdateInfo.DataToProcess Do
		If DataToProcessDetails.Value.Status = "Completed" Then
			ProceduresCompleted = ProceduresCompleted + 1;
		EndIf;
	EndDo;
	RegistrationProgress.ProceduresCompleted = ProceduresCompleted;
	If RegistrationProgress.TotalProcedureCount <> 0 Then
		ProgressIncrement = RegistrationProgress.ProceduresCompleted / RegistrationProgress.TotalProcedureCount * (100 - RegistrationProgress.InitialProgress);
	Else
		ProgressIncrement = 0;
	EndIf;
	ExecutionProgress = ExecutionProgress + ProgressIncrement;
	
	Return ControllingBackgroundJobExecutionResult;
	
EndFunction

////////////////////////////////////////////////////////////////////////////////
// Common procedures for all stages.

&AtClient
Procedure BeginClose() Export
	
	AttachIdleHandler("ContinueClosing", 0.1, True);
	
EndProcedure

&AtClient
Procedure ContinueClosing() Export
	
	IBUpdateInProgress = False;
	
	CloseForm(False, False);
	
EndProcedure

&AtClient
Procedure UnsuccessfulUpdateMessage(AdditionalParameters, UpdateEndTime)
	
	NotifyDescription = New NotifyDescription("UpdateInfobaseActionsOnError", ThisObject);
	
	FormParameters = New Structure;
	FormParameters.Insert("BriefErrorPresentation",   AdditionalParameters.BriefErrorPresentation);
	FormParameters.Insert("DetailedErrorPresentation", AdditionalParameters.DetailedErrorPresentation);
	FormParameters.Insert("UpdateStartTime",      UpdateStartTime);
	FormParameters.Insert("UpdateEndTime",   UpdateEndTime);
	
	If ValueIsFilled(ExchangePlanName) Then
		
		ModuleDataExchangeClient = CommonClient.CommonModule("DataExchangeClient");
		NameOfFormToOpen = ModuleDataExchangeClient.FailedUpdateMessageFormName();
		FormParameters.Insert("ExchangePlanName", ExchangePlanName);
		
	Else	
		NameOfFormToOpen = "DataProcessor.ApplicationUpdateResult.Form.UnsuccessfulUpdateMessage";
	
	EndIf;
	
	OpenForm(NameOfFormToOpen, FormParameters,,,,,NotifyDescription);
	
EndProcedure

&AtClient
Procedure UpdateInfobaseActionsOnError(ExitApplication, AdditionalParameters) Export
	
	If IBLock <> Undefined
		AND IBLock.Property("RemoveFileInfobaseLock") Then
		InfobaseUpdateInternalServerCall.RemoveFileInfobaseLock();
	EndIf;
	
	If ExitApplication <> False Then
		CloseForm(True, False);
	Else
		CloseForm(True, True);
	EndIf;
	
EndProcedure

&AtClient
Procedure RestartWithScheduledJobExecutionLock()
	
	NewStartupParameter = LaunchParameter + ";ScheduledJobsDisabled";
	NewStartupParameter = "/AllowExecuteScheduledJobs -Off " + "/C """ + NewStartupParameter + """";
	Terminate(True, NewStartupParameter);
	
EndProcedure

&AtServerNoContext
Procedure SetSessionParametersFromBackgroundJob(ClientParametersAtServer)
	
	SessionParameters.ClientParametersAtServer = ClientParametersAtServer;
	SessionParameters.IBUpdateInProgress = False;
	
EndProcedure

&AtServerNoContext
Function ProcessedTimeConsumingOperationResult(Result)
	
	Return InformationRegisters.ApplicationParameters.ProcessedTimeConsumingOperationResult(Result);
	
EndFunction

#EndRegion
