///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Internal

// Gets a scheduled job by name.
//
// Parameters:
//  ScheduledJobName - String - a scheduled job name.
//    CreateNew - Boolean - if missing, a new one is created.
//
Function GetScheduledJobExternalCall(ScheduledJobName, CreateNew = True) Export
	Return GetScheduledJob(ScheduledJobName, CreateNew);
EndFunction

// Sets the default schedule of a scheduled job.
//
// Parameters:
//  ScheduledJobName - ScheduledJob.
//
Procedure SetDefaultScheduleExternalCall(Job) Export
	SetDefaultSchedule(Job);
EndProcedure

// Deletes a scheduled job by name.
//
// Parameters:
//  ScheduledJobName - String - a scheduled job name.
//
Procedure DeleteScheduledJobExternalCall(ScheduledJobName) Export
	DeleteScheduledJob(ScheduledJobName);
EndProcedure

// Sets a value of the monitoring center parameter.
//
// Parameters:
//  Parameter - String - a monitoring center parameter key. See possible key values in the 
//                      GetDefaultParameters procedure of the MonitoringCenterInternal module.
//  Value - Arbitrary type - a monitoring center parameter value.
//
Function SetMonitoringCenterParameterExternalCall(Parameter, Value) Export
	Return SetMonitoringCenterParameter(Parameter, Value);	
EndFunction

// This function gets default monitoring center parameters.
// Returns
//    Structure - a value of the MonitoringCenterParameters constant.
//
Function GetDefaultParametersExternalCall() Export
	Return GetDefaultParameters();
EndFunction

// This function gets monitoring center parameters.
// Parameters:
//    Parameters - Structure - where keys are parameters whose values are to be got.
// Returns
//    Structure - a value of the MonitoringCenterParameters constant.
//
Function GetMonitoringCenterParametersExternalCall(Parameters = Undefined) Export
	Return GetMonitoringCenterParameters(Parameters);
EndFunction

// This function sets monitoring center parameters.
// Parameters:
//    Parameters - Structure - parameters whose values are to be got.
//
Function SetMonitoringCenterParametersExternalCall(NewParameters) Export
	SetMonitoringCenterParameters(NewParameters);
EndFunction

Function StartDiscoveryPackageSending() Export
	ExecutionParameters = TimeConsumingOperations.BackgroundExecutionParameters(New UUID);
	ExecutionParameters.WaitForCompletion = 0;
	ProcedureParameters = New Structure("Iterator, SendTestPackageFlag, GetID", 0, False, True);
	RunResult = TimeConsumingOperations.ExecuteInBackground("MonitoringCenterInternal.SendTestPackage", ProcedureParameters, ExecutionParameters);
	Return RunResult;
EndFunction

////////////////////////////////////////////////////////////////////////////////
// Configuration subsystems event handlers.

// See ScheduledJobsOverridable.OnDefineScheduledJobsSettings. 
Procedure OnDefineScheduledJobSettings(Dependencies) Export
	Dependence = Dependencies.Add();
	Dependence.ScheduledJob = Metadata.ScheduledJobs.StatisticsDataCollectionAndSending;
	Dependence.UseExternalResources = True;
	
	Dependence = Dependencies.Add();
	Dependence.ScheduledJob = Metadata.ScheduledJobs.ErrorReportCollectionAndSending;
	Dependence.UseExternalResources = True;
EndProcedure

// See InfobaseUpdateSSL.OnAddUpdateHandlers. 
Procedure OnAddUpdateHandlers(Handlers) Export
	
	Handler = Handlers.Add();
	Handler.InitialFilling = True;
	Handler.Procedure = "MonitoringCenterInternal.InitialFilling";
	
	Handler = Handlers.Add();
	Handler.ExecutionMode = "Seamless";
	Handler.SharedData = True;
	Handler.Version = "2.4.1.7";
	Handler.Procedure = "MonitoringCenterInternal.AddInfobaseIDPermanent";
	
	If StandardSubsystemsServer.IsBaseConfigurationVersion() AND NOT SeparationByDataAreasEnabled() Then
		Handler = Handlers.Add();
		Handler.ExecutionMode = "Deferred";
		Handler.Version          = "2.4.4.79";
		Handler.Comment     = NStr("ru = 'Включает отправку сведений об использовании программы в фирму ""1С"". Отключить отправку сведений можно в разделе Администрирование / Интернет-поддержка и сервисы / Центр мониторинга'; en = 'Enables the option of sending information about using the application to 1C company. You can disable this option in Settings/Online user support and services/Monitoring center'; pl = 'Enables the option of sending information about using the application to 1C company. You can disable this option in Settings/Online user support and services/Monitoring center';de = 'Enables the option of sending information about using the application to 1C company. You can disable this option in Settings/Online user support and services/Monitoring center';ro = 'Enables the option of sending information about using the application to 1C company. You can disable this option in Settings/Online user support and services/Monitoring center';tr = 'Enables the option of sending information about using the application to 1C company. You can disable this option in Settings/Online user support and services/Monitoring center'; es_ES = 'Enables the option of sending information about using the application to 1C company. You can disable this option in Settings/Online user support and services/Monitoring center'");
		Handler.ID   = New UUID("68c8c60c-5b23-436a-9555-a6f24a6b1ffd");
		Handler.Procedure       = "MonitoringCenterInternal.EnableSendingInfo";
		Handler.DeferredProcessingQueue          = 1;
		Handler.UpdateDataFillingProcedure = "MonitoringCenterInternal.EnableSendingInfoFilling";
		Handler.ObjectsToBeRead                     = "Constant.MonitoringCenterParameters";
		Handler.ObjectsToChange                   = "Constant.MonitoringCenterParameters, ScheduledJob.StatisticsDataCollectionAndSending";
	EndIf;
	
EndProcedure

// See CommonOverridable.OnAddClientParametersOnStart. 
Procedure OnAddClientParametersOnStart(Parameters) Export
	
	ClientRunParameters = New Structure("SessionTimeZone, UserHash, RegisterBusinessStatistics,
											|PromptForFullDump, PromptForFullDumpDisplayed, DumpsInformation,
											|RequestForGettingDumps,SendingRequest,RequestForGettingContacts,
											|RequestForGettingContactsDisplayed");
	
	UserUUID = String(InfoBaseUsers.CurrentUser().UUID);
	SessionNumber = Format(InfoBaseSessionNumber(), "NG=0");
	UserHash = Common.CheckSumString(UserUUID + SessionNumber);
	
	RegisterBusinessStatistics = GetMonitoringCenterParameters("RegisterBusinessStatistics");
	RequestForGettingContacts = GetMonitoringCenterParameters("ContactInformationRequest") = 3;
	NotificationOfDumpsParameters = NotificationOfDumpsParameters();
	
	IsFullUser = Users.IsFullUser(, True);
	
	MonitoringCenterSettings = New Structure;
	// Notifications are always enabled as notifications of dumps are important for Administrator.
	MonitoringCenterSettings.Insert("EnableNotifications", True);
	MonitoringCenterOverridable.OnDefineSettings(MonitoringCenterSettings);
	
	ClientRunParameters.PromptForFullDump = IsFullUser AND MonitoringCenterSettings.EnableNotifications;	
	ClientRunParameters.PromptForFullDumpDisplayed = False;
	ClientRunParameters.RequestForGettingDumps = NotificationOfDumpsParameters.RequestForGettingDumps;
	ClientRunParameters.SendingRequest = NotificationOfDumpsParameters.SendingRequest;
	ClientRunParameters.DumpsInformation = NotificationOfDumpsParameters.DumpsInformation;
	ClientRunParameters.SessionTimeZone = SessionTimeZone();
	ClientRunParameters.UserHash = UserHash;
	ClientRunParameters.RegisterBusinessStatistics = RegisterBusinessStatistics;
	ClientRunParameters.RequestForGettingContacts = RequestForGettingContacts;
	ClientRunParameters.RequestForGettingContactsDisplayed = False;
		
	Parameters.Insert("MonitoringCenter", New FixedStructure(ClientRunParameters));
	
	// Write a user activity in business statistics when starting the procedure.
	WriteUserActivity(UserHash);
	
EndProcedure

Procedure OnExecuteStandardDinamicChecksAtServer(Parameters) Export
	
	If Parameters["ClientInformation"]["ClientParameters"]["RegisterBusinessStatistics"] Then
	
		RegisterBusinessStatistics = GetMonitoringCenterParameters("RegisterBusinessStatistics");
			
		ParametersNew = New Map(Parameters);
		ParametersNew.Insert("RegisterBusinessStatistics", RegisterBusinessStatistics);
		
		BackgroundJobKey = "OnExecuteStandardDinamicChecksAtServerInBackground" + Parameters["ClientInformation"]["ClientParameters"]["UserHash"];
		
		Filter = New Structure;
		Filter.Insert("Key", BackgroundJobKey);
		Filter.Insert("State", BackgroundJobState.Active);
		ActiveBackgroundJobs = BackgroundJobs.GetBackgroundJobs(Filter);
		
		If ActiveBackgroundJobs.Count() = 0 Then
			
			BackgroundJobParameters = New Array;
			BackgroundJobParameters.Add(Parameters);
			BackgroundJobs.Execute("MonitoringCenterInternal.OnExecuteStandardDinamicChecksAtServerInBackground",
				BackgroundJobParameters,
				BackgroundJobKey,
				"MonitoringCenterInternal.OnExecuteStandardDinamicChecksAtServer");
		EndIf;
		
		Parameters = New FixedMap(ParametersNew);
		
	EndIf;
	
	If Parameters["ClientInformation"]["ClientParameters"]["PromptForFullDump"] Then
		
		NotificationOfDumpsParameters = NotificationOfDumpsParameters();
		
		RequestForGettingDumps = NotificationOfDumpsParameters.RequestForGettingDumps
								AND NOT Parameters.Get("PromptForFullDumpDisplayed") = True;
		RequestForGettingContacts = GetMonitoringCenterParameters("ContactInformationRequest") = 3
								AND NOT Parameters.Get("RequestForGettingContactsDisplayed") = True;
		
		ParametersNew = New Map(Parameters);
		ParametersNew.Insert("RequestForGettingDumps", RequestForGettingDumps);
		ParametersNew.Insert("DumpsSendingRequest", NotificationOfDumpsParameters.SendingRequest);
		ParametersNew.Insert("DumpsInformation", NotificationOfDumpsParameters.DumpsInformation);
		ParametersNew.Insert("RequestForGettingContacts", RequestForGettingContacts);
		Parameters = New FixedMap(ParametersNew);
		
	EndIf;
	
	MonitoringCenterParameters = New Structure("TestPackageSent,ApplicationInformationProcessingCenter,EnableMonitoringCenter");
	MonitoringCenterParameters = GetMonitoringCenterParameters(MonitoringCenterParameters);
	
	If NOT MonitoringCenterParameters.TestPackageSent AND NOT SeparationByDataAreasEnabled() Then
		// It is not reasonable to send a test package as the data is already being sent.
		If MonitoringCenterParameters.EnableMonitoringCenter OR MonitoringCenterParameters.ApplicationInformationProcessingCenter Then
			SetPrivilegedMode(True);
			SetMonitoringCenterParameter("TestPackageSent", True);
			SetPrivilegedMode(False);
		Else
			BackgroundJobKey = "SendTestPackageFlag";
			
			Filter = New Structure;
			Filter.Insert("Key", BackgroundJobKey);
			Filter.Insert("State", BackgroundJobState.Active);
			ActiveBackgroundJobs = BackgroundJobs.GetBackgroundJobs(Filter);
			If ActiveBackgroundJobs.Count() = 0 Then                                                                      
				ProcedureParameters = New Structure("Iterator, SendTestPackageFlag, GetID", 0, True, False);
				ParametersArray = New Array;
				ParametersArray.Add(ProcedureParameters);
				ParametersArray.Add(Undefined);				
				BackgroundJobs.Execute("MonitoringCenterInternal.SendTestPackage",
					ParametersArray,
					BackgroundJobKey,
					NStr("ru = 'Центр мониторинга: отправка тестового пакета'; en = 'Monitoring center: send test package'; pl = 'Monitoring center: send test package';de = 'Monitoring center: send test package';ro = 'Monitoring center: send test package';tr = 'Monitoring center: send test package'; es_ES = 'Monitoring center: send test package'"));
			EndIf;
		EndIf;
	EndIf;
	
	If Common.FileInfobase() Then
		MonitoringCenterParameters = New Structure("SendDumpsFiles,DumpOption,DumpCollectingEnd,FullDumpsCollectionEnabled");
		MonitoringCenterParameters = GetMonitoringCenterParameters(MonitoringCenterParameters);
			
		StartErrorReportsCollectionAndSending = Not MonitoringCenterParameters.SendDumpsFiles = 0
												AND Not IsBlankString(MonitoringCenterParameters.DumpOption)
												AND CurrentUniversalDate() < MonitoringCenterParameters.DumpCollectingEnd;
												
		If StartErrorReportsCollectionAndSending Then
			ID = Parameters["ClientInformation"]["ClientParameters"]["UserHash"];
			BackgroundJobKey = "CollectAndSendServerErrorReportsInBackground" + ID;
			
			Filter = New Structure;
			Filter.Insert("Key", BackgroundJobKey);
			Filter.Insert("State", BackgroundJobState.Active);
			ActiveBackgroundJobs = BackgroundJobs.GetBackgroundJobs(Filter);
			
			If ActiveBackgroundJobs.Count() = 0 Then
				BackgroundJobParameters = New Array;
				BackgroundJobParameters.Add(True);
				BackgroundJobParameters.Add(ID);
				BackgroundJobs.Execute("MonitoringCenterInternal.CollectAndSendDumps",
					BackgroundJobParameters,
					BackgroundJobKey,
					NStr("ru = 'Сбор и отправка отчетов об ошибках'; en = 'Collect and send error reports'; pl = 'Collect and send error reports';de = 'Collect and send error reports';ro = 'Collect and send error reports';tr = 'Collect and send error reports'; es_ES = 'Collect and send error reports'"));
				EndIf;
		Else
			If MonitoringCenterParameters.FullDumpsCollectionEnabled[ComputerName()] = True Then
				StopFullDumpsCollection();
			EndIf;
		EndIf;	
	EndIf;
		
EndProcedure

Procedure OnExecuteStandardDinamicChecksAtServerInBackground(Parameters) Export
	
	WriteClientScreensStatistics(Parameters);
	WriteSystemInformation(Parameters);
	WriteClientInformation(Parameters);
	WriteDataFromClient(Parameters);
	
EndProcedure

// See ToDoListOverridable.OnDetermineToDoListHandlers 
Procedure OnFillToDoList(ToDoList) Export
	
	// Only system administrator is authorized to change a constant.
	If NOT Users.IsFullUser(, True) Then
		Return;
	EndIf;
	
	MonitoringCenterParameters = GetMonitoringCenterParameters();
	
	ModuleToDoListServer = Common.CommonModule("ToDoListServer");
	
	Sections = ModuleToDoListServer.SectionsForObject("DataProcessor.MonitoringCenterSettings");
	If Sections.Count() = 0 Then
		// Not included to the command interface.
		AdministrationSection = Metadata.Subsystems.Find("Administration");
		If AdministrationSection = Undefined Then
			Return;
		EndIf;
		Sections.Add(AdministrationSection);
	EndIf;
	
	// 1. Process request for getting dumps.
	RequestForGettingDumps = MonitoringCenterParameters.SendDumpsFiles = 2 AND MonitoringCenterParameters.BasicChecksPassed;
	For Each Section In Sections Do
		ToDoItem = ToDoList.Add();
		ToDoItem.ID  = "RequestForGettingDumps";
		ToDoItem.HasToDoItems       = RequestForGettingDumps;
		ToDoItem.Important         = True;
		ToDoItem.HideInSettings = True;
		ToDoItem.Owner       = Section;
		ToDoItem.Presentation  = NStr("ru = 'Предоставить отчеты об ошибках'; en = 'Provide error reports'; pl = 'Provide error reports';de = 'Provide error reports';ro = 'Provide error reports';tr = 'Provide error reports'; es_ES = 'Provide error reports'");
		ToDoItem.Count     = 0;
		ToDoItem.ToolTip      = NStr("ru = 'Зарегистрированы аварийные завершения работы программы. Пожалуйста, расскажите нам об этой проблеме.'; en = 'Abnormal application terminations were registered. Please contact us on this issue.'; pl = 'Abnormal application terminations were registered. Please contact us on this issue.';de = 'Abnormal application terminations were registered. Please contact us on this issue.';ro = 'Abnormal application terminations were registered. Please contact us on this issue.';tr = 'Abnormal application terminations were registered. Please contact us on this issue.'; es_ES = 'Abnormal application terminations were registered. Please contact us on this issue.'");
		ToDoItem.FormParameters = New Structure("Variant", "Query");
		ToDoItem.Form          = "DataProcessor.MonitoringCenterSettings.Form.RequestForErrorReportsCollectionAndSending";
	EndDo;

	// 2. Process request for sending dumps.
	HasDumps = MonitoringCenterParameters.Property("DumpInstances") AND MonitoringCenterParameters.DumpInstances.Count();
	SendingRequest = MonitoringCenterParameters.SendDumpsFiles = 1
						AND NOT IsBlankString(MonitoringCenterParameters.DumpOption)
						AND HasDumps
						AND MonitoringCenterParameters.RequestConfirmationBeforeSending
						AND MonitoringCenterParameters.DumpType = "3"
						AND Not IsBlankString(MonitoringCenterParameters.DumpsInformation)
						AND MonitoringCenterParameters.BasicChecksPassed;
	For Each Section In Sections Do
		ToDoItem = ToDoList.Add();
		ToDoItem.ID  = "DumpsSendingRequest";
		ToDoItem.HasToDoItems       = SendingRequest;
		ToDoItem.Important         = False;
		ToDoItem.Owner       = Section;
		ToDoItem.Presentation  = NStr("ru = 'Отправить отчеты об ошибках'; en = 'Send error reports'; pl = 'Send error reports';de = 'Send error reports';ro = 'Send error reports';tr = 'Send error reports'; es_ES = 'Send error reports'");
		ToDoItem.Count     = 0;
		ToDoItem.ToolTip      = NStr("ru = 'Отчеты об аварийном завершении собраны и подготовлены. Пожалуйста, согласуйте их отправку.'; en = 'Crash reports are collected and prepared. Please approve reports submission.'; pl = 'Crash reports are collected and prepared. Please approve reports submission.';de = 'Crash reports are collected and prepared. Please approve reports submission.';ro = 'Crash reports are collected and prepared. Please approve reports submission.';tr = 'Crash reports are collected and prepared. Please approve reports submission.'; es_ES = 'Crash reports are collected and prepared. Please approve reports submission.'");
		ToDoItem.FormParameters = New Structure;
		ToDoItem.Form          = "DataProcessor.MonitoringCenterSettings.Form.RequestForSendingErrorReports";
	EndDo;
	
	// 3. Contact information request.
	HasContactInformationRequest = MonitoringCenterParameters.ContactInformationRequest = 3;
	For Each Section In Sections Do
		ToDoItem = ToDoList.Add();
		ToDoItem.ID  = "ContactInformationRequest";
		ToDoItem.HasToDoItems       = HasContactInformationRequest;
		ToDoItem.Important         = True;
		ToDoItem.Owner       = Section;
		ToDoItem.Presentation  = NStr("ru = 'Сообщить о проблемах производительности'; en = 'Inform of performance issues'; pl = 'Inform of performance issues';de = 'Inform of performance issues';ro = 'Inform of performance issues';tr = 'Inform of performance issues'; es_ES = 'Inform of performance issues'");
		ToDoItem.Count     = 0;
		ToDoItem.ToolTip      = NStr("ru = 'Обнаружены проблемы производительности. Пожалуйста, расскажите нам об этих проблемах.'; en = 'Performance issues are detected. Contact us on this issue.'; pl = 'Performance issues are detected. Contact us on this issue.';de = 'Performance issues are detected. Contact us on this issue.';ro = 'Performance issues are detected. Contact us on this issue.';tr = 'Performance issues are detected. Contact us on this issue.'; es_ES = 'Performance issues are detected. Contact us on this issue.'");
		ToDoItem.FormParameters = New Structure("OnRequest", True);
		ToDoItem.Form          = "DataProcessor.MonitoringCenterSettings.Form.SendContactInformation";
	EndDo;
	
EndProcedure

#EndRegion

#Region Private

#Region WorkWithScheduledJobs

Function GetScheduledJob(ScheduledJobName, CreateNew = True)
	Result = Undefined;
	
	SetPrivilegedMode(True);
	Jobs = ScheduledJobs.GetScheduledJobs(New Structure("Metadata", ScheduledJobName));
	If Jobs.Count() = 0 Then
		If CreateNew Then
			Job = ScheduledJobs.CreateScheduledJob(Metadata["ScheduledJobs"][ScheduledJobName]);
			Job.Use = True;
			Job.Write();
			Result = Job;
		EndIf;
	Else
		Result = Jobs[0];
	EndIf;
	
	Return Result;
EndFunction

Procedure SetDefaultSchedule(Job)
	Job.Schedule.DaysRepeatPeriod = 1;
	Job.Schedule.RepeatPeriodInDay = 600;
	Job.Write();
EndProcedure

Procedure DeleteScheduledJob(ScheduledJobName)
	ScheduledJob = GetScheduledJob(ScheduledJobName, False);
	If ScheduledJob <> Undefined Then
		ScheduledJob.Delete();
	EndIf;
EndProcedure

Procedure MonitoringCenterScheduledJob() Export
	Common.OnStartExecuteScheduledJob(Metadata.ScheduledJobs.StatisticsDataCollectionAndSending);
	
	PerformanceMonitorRecordRequired = False;
	
	PerformanceMonitorExists = Common.SubsystemExists("StandardSubsystems.PerformanceMonitor");
	If PerformanceMonitorExists Then
		ModulePerformanceMonitor = Common.CommonModule("PerformanceMonitor");
		StartTime = ModulePerformanceMonitor.StartTimeMeasurement();
	EndIf;
	
	StartDate = CurrentUniversalDate();
	MonitoringCenterParameters = New Structure();
	
	MonitoringCenterParameters.Insert("EnableMonitoringCenter");
	MonitoringCenterParameters.Insert("ApplicationInformationProcessingCenter");
	MonitoringCenterParameters.Insert("RegisterDumps");
	MonitoringCenterParameters.Insert("DumpRegistrationNextCreation");
	MonitoringCenterParameters.Insert("DumpRegistrationCreationPeriod");
	
	MonitoringCenterParameters.Insert("RegisterBusinessStatistics");
	MonitoringCenterParameters.Insert("BusinessStatisticsNextSnapshot");
	MonitoringCenterParameters.Insert("BusinessStatisticsSnapshotPeriod");
	
	MonitoringCenterParameters.Insert("RegisterConfigurationStatistics");
	MonitoringCenterParameters.Insert("RegisterConfigurationSettings");
	MonitoringCenterParameters.Insert("ConfigurationStatisticsNextGeneration");
	MonitoringCenterParameters.Insert("ConfigurationStatisticsGenerationPeriod");
	
	MonitoringCenterParameters.Insert("SendDataNextGeneration");
	MonitoringCenterParameters.Insert("SendDataGenerationPeriod");
	MonitoringCenterParameters.Insert("NotificationDate");
	MonitoringCenterParameters.Insert("ForceSendMinidumps");
	MonitoringCenterParameters.Insert("UserResponseTimeout");
	
	MonitoringCenterParameters = GetMonitoringCenterParameters(MonitoringCenterParameters);
	
	If (MonitoringCenterParameters.EnableMonitoringCenter OR MonitoringCenterParameters.ApplicationInformationProcessingCenter) AND IsMasterNode() Then 
		If MonitoringCenterParameters.RegisterDumps AND StartDate >= MonitoringCenterParameters.DumpRegistrationNextCreation Then
			Try
				DumpsRegistration();
			Except
				Comment = DetailErrorDescription(ErrorInfo());
				WriteLogEvent(
					NStr("ru = 'Центр мониторинга - регистрация дампов'; en = 'Monitoring center - dump registration'; pl = 'Monitoring center - dump registration';de = 'Monitoring center - dump registration';ro = 'Monitoring center - dump registration';tr = 'Monitoring center - dump registration'; es_ES = 'Monitoring center - dump registration'",
					Common.DefaultLanguageCode()),
					EventLogLevel.Error,
					,
					,
					Comment);
				SetMonitoringCenterParameter("RegisterDumps", False);
				MonitoringCenter.WriteBusinessStatisticsOperation("MonitoringCenter.DumpsRegistration.Error", 1, Comment);
			EndTry;
			
			MonitoringCenterParameters.DumpRegistrationNextCreation =
			CurrentUniversalDate()
			+ MonitoringCenterParameters.DumpRegistrationCreationPeriod;
			
			PerformanceMonitorRecordRequired = True;
		EndIf;
		
		If MonitoringCenterParameters.RegisterBusinessStatistics AND StartDate >= MonitoringCenterParameters.BusinessStatisticsNextSnapshot Then
			Try
				StatisticsOperationsRegistration();
			Except
				Comment = DetailErrorDescription(ErrorInfo());
				WriteLogEvent(
					NStr("ru = 'Центр мониторинга - регистрация операций статистики'; en = 'Monitoring center - register statistics operations'; pl = 'Monitoring center - register statistics operations';de = 'Monitoring center - register statistics operations';ro = 'Monitoring center - register statistics operations';tr = 'Monitoring center - register statistics operations'; es_ES = 'Monitoring center - register statistics operations'",
					Common.DefaultLanguageCode()),
					EventLogLevel.Error,
					,
					,
					Comment);
				MonitoringCenter.WriteBusinessStatisticsOperation("MonitoringCenter.StatisticsOperationsRegistration.Error", 1, Comment);
			EndTry;
						
			MonitoringCenterParameters.BusinessStatisticsNextSnapshot =
			CurrentUniversalDate()
			+ MonitoringCenterParameters.BusinessStatisticsSnapshotPeriod;
			
			PerformanceMonitorRecordRequired = True;
		EndIf;
		
		If (MonitoringCenterParameters.RegisterConfigurationStatistics OR MonitoringCenterParameters.RegisterConfigurationSettings) AND StartDate >= MonitoringCenterParameters.ConfigurationStatisticsNextGeneration Then
			Try
				CollectConfigurationStatistics(New Structure("RegisterConfigurationStatistics, RegisterConfigurationSettings", MonitoringCenterParameters.RegisterConfigurationStatistics, MonitoringCenterParameters.RegisterConfigurationSettings));
			Except
				Comment = DetailErrorDescription(ErrorInfo());
				WriteLogEvent(
					NStr("ru = 'Центр мониторинга - собрать статистику конфигурации'; en = 'Monitoring center - obtain configuration statistics'; pl = 'Monitoring center - obtain configuration statistics';de = 'Monitoring center - obtain configuration statistics';ro = 'Monitoring center - obtain configuration statistics';tr = 'Monitoring center - obtain configuration statistics'; es_ES = 'Monitoring center - obtain configuration statistics'",
					Common.DefaultLanguageCode()),
					EventLogLevel.Error,
					,
					,
					Comment);
				MonitoringCenter.WriteBusinessStatisticsOperation("MonitoringCenter.CollectConfigurationStatistics.Error", 1, Comment);
			EndTry;
				
			MonitoringCenterParameters.ConfigurationStatisticsNextGeneration =
			CurrentUniversalDate()
			+ MonitoringCenterParameters.ConfigurationStatisticsGenerationPeriod;
			
			PerformanceMonitorRecordRequired = True;
		EndIf;
		
		If StartDate >= MonitoringCenterParameters.SendDataNextGeneration Then
			Try
				CreatePackageToSend();
			Except
				Comment = DetailErrorDescription(ErrorInfo());
				WriteLogEvent(
					NStr("ru = 'Центр мониторинга - сформировать пакет для отправки'; en = 'Monitoring center - generate a package for sending'; pl = 'Monitoring center - generate a package for sending';de = 'Monitoring center - generate a package for sending';ro = 'Monitoring center - generate a package for sending';tr = 'Monitoring center - generate a package for sending'; es_ES = 'Monitoring center - generate a package for sending'",
					Common.DefaultLanguageCode()),
					EventLogLevel.Error,
					,
					,
					Comment);
				MonitoringCenter.WriteBusinessStatisticsOperation("MonitoringCenter.CreatePackageToSend.Error", 1, Comment);
			EndTry;
			
			Try
				HTTPResponse = SendMonitoringData();
				If HTTPResponse.StatusCode = 200 Then
					// Everything is OK.
				EndIf;
			Except
				Comment = DetailErrorDescription(ErrorInfo());
				WriteLogEvent(
					NStr("ru = 'Центр мониторинга - отправить данные мониторинга'; en = 'Monitoring center - send monitoring data'; pl = 'Monitoring center - send monitoring data';de = 'Monitoring center - send monitoring data';ro = 'Monitoring center - send monitoring data';tr = 'Monitoring center - send monitoring data'; es_ES = 'Monitoring center - send monitoring data'",
					Common.DefaultLanguageCode()),
					EventLogLevel.Error,
					,
					,
					Comment);
				MonitoringCenter.WriteBusinessStatisticsOperation("MonitoringCenter.SendMonitoringData.Error", 1, Comment);
			EndTry;
			
			MonitoringCenterParameters.SendDataNextGeneration = CurrentUniversalDate()
				+ GetMonitoringCenterParameters("SendDataGenerationPeriod");
				
			MonitoringCenterParameters.Delete("DumpRegistrationNextCreation");
			MonitoringCenterParameters.Delete("DumpRegistrationCreationPeriod");
			
			MonitoringCenterParameters.Delete("BusinessStatisticsNextSnapshot");
			MonitoringCenterParameters.Delete("BusinessStatisticsSnapshotPeriod");
			
			MonitoringCenterParameters.Delete("ConfigurationStatisticsNextGeneration");
			MonitoringCenterParameters.Delete("ConfigurationStatisticsGenerationPeriod");
			
			PerformanceMonitorRecordRequired = True;
		EndIf;
		
		// To prevent parameters set upon processing response from the server from being recorded, delete 
		// these parameters.
		MonitoringCenterParameters.Delete("RegisterDumps");
		MonitoringCenterParameters.Delete("RegisterBusinessStatistics");
		MonitoringCenterParameters.Delete("RegisterConfigurationStatistics");
		MonitoringCenterParameters.Delete("RegisterConfigurationSettings");
		MonitoringCenterParameters.Delete("SendDataGenerationPeriod");
		
		SetMonitoringCenterParameters(MonitoringCenterParameters);
	Else
		DeleteScheduledJob("StatisticsDataCollectionAndSending");
	EndIf;
	
	// Make sure that sending is not prohibited, a dump option is specified and collection time is not expired.
	MonitoringCenterParameters.Insert("SendDumpsFiles");
	MonitoringCenterParameters.Insert("DumpOption");
	MonitoringCenterParameters.Insert("DumpCollectingEnd");
	
	MonitoringCenterParameters = GetMonitoringCenterParameters(MonitoringCenterParameters);
	
	StartErrorReportsCollectionAndSending = Not MonitoringCenterParameters.SendDumpsFiles = 0
											AND Not IsBlankString(MonitoringCenterParameters.DumpOption)
											AND StartDate < MonitoringCenterParameters.DumpCollectingEnd;
	If StartErrorReportsCollectionAndSending Then
		
		If NOT ValueIsFilled(MonitoringCenterParameters.NotificationDate) Then
			// Set a notification date.
			SetMonitoringCenterParameter("NotificationDate", StartDate);
		ElsIf StartDate > MonitoringCenterParameters.NotificationDate + MonitoringCenterParameters.UserResponseTimeout * 86400
			AND MonitoringCenterParameters.ForceSendMinidumps = 2 Then
			// Timeout is expired, enable a forced sending.
			SetMonitoringCenterParameter("ForceSendMinidumps", 1);	
			MonitoringCenter.WriteBusinessStatisticsOperation("MonitoringCenter.DumpsRegistration.ForcedMinidumpSendingEnabled", 1);
		EndIf;
		
		If Common.FileInfobase() Then
			// For the file base, the data is collected and sent in  OnExecuteStandardPeriodicChecksAtServer.
		Else    			
			// Check if there is a scheduled job.			
			ScheduledJob = GetScheduledJob("ErrorReportCollectionAndSending", False);
			If ScheduledJob = Undefined Then
				ScheduledJob = GetScheduledJob("ErrorReportCollectionAndSending", True);
				SetDefaultSchedule(ScheduledJob);
			EndIf;                                      			
		EndIf;
	EndIf;											
	
	If PerformanceMonitorExists AND PerformanceMonitorRecordRequired Then
		ModulePerformanceMonitor.EndTimeMeasurement("MonitoringCenterCollectAndSubmitStatisticalData", StartTime);
	EndIf;
EndProcedure

#EndRegion

#Region WorkWithBusinessStatistics

Procedure ParseStatisticsOperationsBuffer(CurrentDate)
	PerformanceMonitorExists = Common.SubsystemExists("StandardSubsystems.PerformanceMonitor");
	If PerformanceMonitorExists Then
		ModulePerformanceMonitor = Common.CommonModule("PerformanceMonitor");
		StartTime = ModulePerformanceMonitor.StartTimeMeasurement();
	EndIf;
	
	MonitoringCenterParameters = GetMonitoringCenterParameters(New Structure("AggregationPeriodMinor, AggregationPeriod"));
	AggregationPeriod = MonitoringCenterParameters.AggregationPeriodMinor;
	DeletionPeriod = MonitoringCenterParameters.AggregationPeriod;
				
	ProcessRecordsUntil = Date(1, 1, 1) + Int((CurrentDate - Date(1, 1, 1))/AggregationPeriod)*AggregationPeriod;
			
	QueryResultOperations = InformationRegisters.StatisticsOperationsClipboard.GetAggregatedOperationsRecords(ProcessRecordsUntil, AggregationPeriod, DeletionPeriod);
	QueryResultComment = InformationRegisters.StatisticsOperationsClipboard.GetAggregatedRecordsComment(ProcessRecordsUntil, AggregationPeriod, DeletionPeriod);
	QueryResultAreas = InformationRegisters.StatisticsOperationsClipboard.GetAggregatedRecordsStatisticsAreas(ProcessRecordsUntil, AggregationPeriod, DeletionPeriod);
	BeginTransaction();
	Try
		InformationRegisters.MeasurementsStatisticsOperations.WriteMeasurements(QueryResultOperations);
		InformationRegisters.MeasurementsStatisticsComments.WriteMeasurements(QueryResultComment);
		InformationRegisters.MeasurementsStatisticsAreas.WriteMeasurements(QueryResultAreas);
		
		InformationRegisters.StatisticsOperationsClipboard.DeleteRecords(ProcessRecordsUntil);	
		
		CommitTransaction();
	Except
		RollbackTransaction();
		Error = DetailErrorDescription(ErrorInfo());
		WriteLogEvent(EventLogEventMonitoringCenterParseStatisticsOperationsBuffer(), EventLogLevel.Error, Metadata.CommonModules.MonitoringCenterInternal,,Error);
		Raise Error;
	EndTry;
	
	If PerformanceMonitorExists Then
		ModulePerformanceMonitor.EndTimeMeasurement("MonitoringCenterAnalyzeStatisticsOperationBuffer", StartTime);
	EndIf;
EndProcedure

Procedure AggregateStatisticsOperationsMeasurements(CurrentDate)
	PerformanceMonitorExists = Common.SubsystemExists("StandardSubsystems.PerformanceMonitor");
	If PerformanceMonitorExists Then
		ModulePerformanceMonitor = Common.CommonModule("PerformanceMonitor");
		StartTime = ModulePerformanceMonitor.StartTimeMeasurement();
	EndIf;
	
	MonitoringCenterParameters = GetMonitoringCenterParameters(New Structure("AggregationPeriodMinor, AggregationPeriod, AggregationBoundary"));
	AggregationPeriod = MonitoringCenterParameters.AggregationPeriodMinor;
	DeletionPeriod = MonitoringCenterParameters.AggregationPeriod;
	
	AggregationBoundary = MonitoringCenterParameters.AggregationBoundary;
	ProcessRecordsUntil = Date(1, 1, 1) + Int((CurrentDate - Date(1, 1, 1))/AggregationPeriod)*AggregationPeriod;
	
	If ProcessRecordsUntil > AggregationBoundary Then
		BeginTransaction();
		Try
			QueryResultOperationsAggregated = InformationRegisters.MeasurementsStatisticsOperations.GetAggregatedRecords(AggregationBoundary, ProcessRecordsUntil, AggregationPeriod, DeletionPeriod);
			QueryResultCommentAggregated = InformationRegisters.MeasurementsStatisticsComments.GetAggregatedRecords(AggregationBoundary, ProcessRecordsUntil, AggregationPeriod, DeletionPeriod);
			QueryResultAreasAggregated = InformationRegisters.MeasurementsStatisticsAreas.GetAggregatedRecords(AggregationBoundary, ProcessRecordsUntil, AggregationPeriod, DeletionPeriod);
			
			InformationRegisters.MeasurementsStatisticsOperations.DeleteRecords(AggregationBoundary, ProcessRecordsUntil);
			InformationRegisters.MeasurementsStatisticsComments.DeleteRecords(AggregationBoundary, ProcessRecordsUntil);
			InformationRegisters.MeasurementsStatisticsAreas.DeleteRecords(AggregationBoundary, ProcessRecordsUntil);
			
			InformationRegisters.MeasurementsStatisticsOperations.WriteMeasurements(QueryResultOperationsAggregated);
			InformationRegisters.MeasurementsStatisticsComments.WriteMeasurements(QueryResultCommentAggregated);
			InformationRegisters.MeasurementsStatisticsAreas.WriteMeasurements(QueryResultAreasAggregated);
			
			SetMonitoringCenterParameter("AggregationBoundary", ProcessRecordsUntil);
			
			CommitTransaction();
		Except
			RollbackTransaction();
			Error = DetailErrorDescription(ErrorInfo());
			WriteLogEvent(NStr("ru = 'Центр мониторинга.Агрегировать замеры операций статистики'; en = 'Monitoring center.Aggregate measurements of statistics operations'; pl = 'Monitoring center.Aggregate measurements of statistics operations';de = 'Monitoring center.Aggregate measurements of statistics operations';ro = 'Monitoring center.Aggregate measurements of statistics operations';tr = 'Monitoring center.Aggregate measurements of statistics operations'; es_ES = 'Monitoring center.Aggregate measurements of statistics operations'", Common.DefaultLanguageCode()), EventLogLevel.Error, Metadata.CommonModules.MonitoringCenterInternal,,Error);
			Raise Error;
		EndTry;
	EndIf;
	
	If PerformanceMonitorExists Then
		ModulePerformanceMonitor.EndTimeMeasurement("MonitoringCenterAggregateStatisticsOperationsMeasurements", StartTime);
	EndIf;
EndProcedure

Procedure StatisticsOperationsRegistration()
	PerformanceMonitorExists = Common.SubsystemExists("StandardSubsystems.PerformanceMonitor");
	If PerformanceMonitorExists Then
		ModulePerformanceMonitor = Common.CommonModule("PerformanceMonitor");
		StartTime = ModulePerformanceMonitor.StartTimeMeasurement();
	EndIf;
	
	CurrentDate = CurrentUniversalDate();
	
	ParseStatisticsOperationsBuffer(CurrentDate);
	AggregateStatisticsOperationsMeasurements(CurrentDate);
	DeleteObsoleteStatisticsOperationsData();
	
	If PerformanceMonitorExists Then
		ModulePerformanceMonitor.EndTimeMeasurement("MonitoringCenterStatisticsOperationRegistration", StartTime);
	EndIf;
EndProcedure

Procedure DeleteObsoleteStatisticsOperationsData()
	PerformanceMonitorExists = Common.SubsystemExists("StandardSubsystems.PerformanceMonitor");
	If PerformanceMonitorExists Then
		ModulePerformanceMonitor = Common.CommonModule("PerformanceMonitor");
		StartTime = ModulePerformanceMonitor.StartTimeMeasurement();
	EndIf;
	
	MonitoringCenterParameters = GetMonitoringCenterParameters(New Structure("LastPackageDate, DeletionPeriod"));
	
	LastPackageDate = MonitoringCenterParameters.LastPackageDate;
	DeletionPeriod = MonitoringCenterParameters.DeletionPeriod;
	
	DeletionBoundary = Date(1,1,1) + Int((LastPackageDate - Date(1,1,1))/DeletionPeriod) * DeletionPeriod;
	
	BeginTransaction();
	Try
		InformationRegisters.MeasurementsStatisticsOperations.DeleteRecords(Date(1,1,1), DeletionBoundary);
		InformationRegisters.MeasurementsStatisticsComments.DeleteRecords(Date(1,1,1), DeletionBoundary);
		InformationRegisters.MeasurementsStatisticsAreas.DeleteRecords(Date(1,1,1), DeletionBoundary);
		
		CommitTransaction();
	Except
		RollbackTransaction();
		Error = DetailErrorDescription(ErrorInfo());
		WriteLogEvent(NStr("ru = 'Центр мониторинга.Удалить устаревшие данные операций статистики'; en = 'Monitoring center.Delete obsolete data of statistics operations'; pl = 'Monitoring center.Delete obsolete data of statistics operations';de = 'Monitoring center.Delete obsolete data of statistics operations';ro = 'Monitoring center.Delete obsolete data of statistics operations';tr = 'Monitoring center.Delete obsolete data of statistics operations'; es_ES = 'Monitoring center.Delete obsolete data of statistics operations'", Common.DefaultLanguageCode()), EventLogLevel.Error, Metadata.CommonModules.MonitoringCenterInternal,,Error);
		Raise Error;
	EndTry;
	
	If PerformanceMonitorExists Then
		ModulePerformanceMonitor.EndTimeMeasurement("MonitoringCenterDeleteOutdatedStatisticsOperationData", StartTime);
	EndIf;
EndProcedure

#EndRegion

#Region WorkWithJSON

Function GenerateJSONStructure(SectionName, Data, AdditionalParameters = Undefined)
	If AdditionalParameters = Undefined Then
		AdditionalParameters = New Map;
	EndIf;
	
	StartDate = AdditionalParameters["StartDate"];
	EndDate = AdditionalParameters["EndDate"];
	AddtnlParameters = AdditionalParameters["AddlParameters"];
	IndexColumns = AdditionalParameters["IndexColumns"];
	
	If TypeOf(Data) = Type("QueryResult") Then
		JSONStructure = GenerateJSONStructureQueryResult(SectionName, Data, StartDate, EndDate, AddtnlParameters, IndexColumns);
	ElsIf TypeOf(Data) = Type("ValueTable") Then
		JSONStructure = GenerateJSONStructureValueTable(SectionName, Data, StartDate, EndDate, AddtnlParameters, IndexColumns);
	EndIf;
	
	Return JSONStructure;
EndFunction

Function GenerateJSONStructureQueryResult(SectionName, Data, StartDate, EndDate, AddtnlParameters, IndexColumns)
	JSONStructure = New Map;
	
	Section = New Structure;
	
	
	If StartDate <> Undefined Then
		Section.Insert("date_start", StartDate);
	EndIf;
	
	If EndDate <> Undefined Then
		Section.Insert("date_end", EndDate);
	EndIf;
	
	If AddtnlParameters <> Undefined Then
		For Each Parameter In AddtnlParameters Do
			Section.Insert(Parameter.Key, Parameter.Value);
		EndDo;
	EndIf;
			
	Rows = New Array;
	Selection = Data.Select();
	// Used to store data structure.
	CollectionsStructures = New Structure;
	// Used to store collection data as a key field - attributes with values.
	CollectionsMaps = New Map; 
	// List of columns to be excluded from export. Their data goes to CollectionsMaps
	ColumnsToExclude = New Map;
	If IndexColumns <> Undefined Then
		ValuesIndexes = New Map;
		For Each CurColumn In IndexColumns Do
			ValuesIndexes.Insert(CurColumn.Key, New Map);
			If CurColumn.Value.Count() Then
				CollectionsMaps.Insert(CurColumn.Key, New Map);
				ObjectStructure = New Structure;
				For Each Record In CurColumn.Value Do
					ObjectStructure.Insert(Record.Key);
					ColumnsToExclude.Insert(Record.Key, True);
				EndDo;
				CollectionsStructures.Insert(CurColumn.Key, ObjectStructure);
			EndIf;
		EndDo;
	EndIf;
	
	Columns = New Array;
	For Each CurColumn In Data.Columns Do
		If ColumnsToExclude[CurColumn.Name] = True Then
			Continue;
		EndIf;
		Columns.Add(CurColumn.Name);
	EndDo;
	Section.Insert("columns", Columns);
	
	While Selection.Next() Do
		Row = New Array;
		For Each CurColumn In Columns Do
			ValueToAdd = Selection[CurColumn];
			If IndexColumns <> Undefined AND IndexColumns[CurColumn] <> Undefined Then
				If IndexColumns[CurColumn][ValueToAdd] = Undefined Then
					ValueIndex = IndexColumns[CurColumn].Count() + 1;
					IndexColumns[CurColumn].Insert(ValueToAdd, ValueIndex);
					ValuesIndexes[CurColumn].Insert(Format(ValueIndex, "NG=0"), ValueToAdd);
				EndIf;
				
				ValueToAdd = IndexColumns[CurColumn][ValueToAdd];
			EndIf;
			
			If CollectionsStructures.Property(CurColumn) 
				AND CollectionsMaps[CurColumn][Selection[CurColumn]] = Undefined Then
				ObjectMap = New Map;
				For Each Record In CollectionsStructures[CurColumn] Do
					ObjectMap.Insert(Record.Key, Selection[Record.Key]);
				EndDo;
				CollectionsMaps[CurColumn].Insert(Selection[CurColumn], ObjectMap);
			EndIf;
			
			Row.Add(ValueToAdd);
		EndDo;
		Rows.Add(Row);
	EndDo;
	
	For Each Record In CollectionsMaps Do
		Section.Insert(Record.Key, Record.Value);
	EndDo;
	Section.Insert("columnsValueIndex", ValuesIndexes);
	Section.Insert("rows", Rows);		
	
	JSONStructure.Insert(SectionName, Section);
	
	Return JSONStructure;
EndFunction

Function GenerateJSONStructureValueTable(SectionName, Data, StartDate, EndDate, AddtnlParameters, IndexColumns)
	JSONStructure = New Map;
	
	Section = New Structure;
	
	
	If StartDate <> Undefined Then
		Section.Insert("date_start", StartDate);
	EndIf;
	
	If EndDate <> Undefined Then
		Section.Insert("date_end", EndDate);
	EndIf;
	
	If AddtnlParameters <> Undefined Then
		For Each Parameter In AddtnlParameters Do
			Section.Insert(Parameter.Key, Parameter.Value);
		EndDo;
	EndIf;
			
	Rows = New Array;
	// Used to store data structure.
	CollectionsStructures = New Structure;
	// Used to store collection data as a key field - attributes with values.
	CollectionsMaps = New Map; 
	// List of columns to be excluded from export. Their data goes to CollectionsMaps
	ColumnsToExclude = New Map;
	If IndexColumns <> Undefined Then
		ValuesIndexes = New Map;
		For Each CurColumn In IndexColumns Do
			ValuesIndexes.Insert(CurColumn.Key, New Map);
			If CurColumn.Value.Count() Then
				CollectionsMaps.Insert(CurColumn.Key, New Map);
				ObjectStructure = New Structure;
				For Each Record In CurColumn.Value Do
					ObjectStructure.Insert(Record.Key);
					ColumnsToExclude.Insert(Record.Key, True);
				EndDo;
				CollectionsStructures.Insert(CurColumn.Key, ObjectStructure);
			EndIf;
		EndDo;
	EndIf;
	
	Columns = New Array;
	For Each CurColumn In Data.Columns Do
		If ColumnsToExclude[CurColumn.Name] = True Then
			Continue;
		EndIf;
		Columns.Add(CurColumn.Name);
	EndDo;
	Section.Insert("columns", Columns);
	
	For Each Selection In Data Do
		Row = New Array;
		For Each CurColumn In Columns Do
			ValueToAdd = Selection[CurColumn];
			If IndexColumns <> Undefined AND IndexColumns[CurColumn] <> Undefined Then
				If IndexColumns[CurColumn][ValueToAdd] = Undefined Then
					ValueIndex = IndexColumns[CurColumn].Count() + 1;
					IndexColumns[CurColumn].Insert(ValueToAdd, ValueIndex);
					ValuesIndexes[CurColumn].Insert(Format(ValueIndex, "NG=0"), ValueToAdd);
				EndIf;
				
				ValueToAdd = IndexColumns[CurColumn][ValueToAdd];
			EndIf;
			
			If CollectionsStructures.Property(CurColumn) 
				AND CollectionsMaps[CurColumn][Selection[CurColumn]] = Undefined Then
				ObjectMap = New Map;
				For Each Record In CollectionsStructures[CurColumn] Do
					ObjectMap.Insert(Record.Key, Selection[Record.Key]);
				EndDo;
				CollectionsMaps[CurColumn].Insert(Selection[CurColumn], ObjectMap);
			EndIf;
			
			Row.Add(ValueToAdd);
		EndDo;
		Rows.Add(Row);
	EndDo;
	
	For Each Record In CollectionsMaps Do
		Section.Insert(Record.Key, Record.Value);
	EndDo;
	Section.Insert("columnsValueIndex", ValuesIndexes);
	Section.Insert("rows", Rows);		
	
	JSONStructure.Insert(SectionName, Section);
	
	Return JSONStructure;
EndFunction

Function GenerateJSONStructureForSending(Parameters)
	StartDate = Parameters.StartDate;
	EndDate = Parameters.EndDate;
	
	TopDumpsQuantity = Parameters.TopDumpsQuantity;
	TopApdex = Parameters.TopApdex;
	TopApdexTech = Parameters.TopApdexTech;
	DeletionPeriod = Parameters.DeletionPeriod;
	
	MonitoringCenterParameters = New Structure();
	MonitoringCenterParameters.Insert("InfoBaseID");
	MonitoringCenterParameters.Insert("InfobaseIDPermanent");
	MonitoringCenterParameters.Insert("RegisterSystemInformation");
	MonitoringCenterParameters.Insert("RegisterSubsystemVersions");
	MonitoringCenterParameters.Insert("RegisterDumps");
	MonitoringCenterParameters.Insert("RegisterBusinessStatistics");
	MonitoringCenterParameters.Insert("RegisterConfigurationStatistics");
	MonitoringCenterParameters.Insert("RegisterConfigurationSettings");
	MonitoringCenterParameters.Insert("RegisterPerformance");
	MonitoringCenterParameters.Insert("RegisterTechnologicalPerformance");
	MonitoringCenterParameters = GetMonitoringCenterParameters(MonitoringCenterParameters);
	
	If MonitoringCenterParameters.RegisterSystemInformation Then
		Info = GetSystemInformation();
	EndIf;
	
	If MonitoringCenterParameters.RegisterSubsystemVersions Then
		Subsystems = SubsystemsVersions();
	EndIf;
	
	
	If MonitoringCenterParameters.RegisterDumps Then
		TopDumps = InformationRegisters.PlatformDumps.GetTopOptions(StartDate, EndDate, TopDumpsQuantity);
		
		AdditionalParameters = New Map;
		AdditionalParameters.Insert("StartDate", StartDate);
		AdditionalParameters.Insert("EndDate", EndDate);
		DUMPSSection = GenerateJSONStructure("dumps", TopDumps, AdditionalParameters);
	EndIf;
	
	If MonitoringCenterParameters.RegisterBusinessStatistics Then
		
		QueryResult = InformationRegisters.MeasurementsStatisticsOperations.GetMeasurements(StartDate, EndDate, DeletionPeriod);
		IndexColumns = New Map;
		IndexColumns.Insert("StatisticsOperation", New Map);
		IndexColumns.Insert("Period", New Map);
		
		AdditionalParameters = New Map;
		AdditionalParameters.Insert("StartDate", StartDate);
		AdditionalParameters.Insert("EndDate", EndDate);
		AdditionalParameters.Insert("IndexColumns", IndexColumns);
		StatisticsOperationsSection = GenerateJSONStructure("OperationStatistics", QueryResult, AdditionalParameters);
		StatisticsOperationsSection["OperationStatistics"].Insert("AggregationPeriod", DeletionPeriod);
		
		QueryResult = InformationRegisters.MeasurementsStatisticsComments.GetMeasurements(StartDate, EndDate, DeletionPeriod);
		IndexColumns = New Map;
		IndexColumns.Insert("StatisticsOperation", New Map);
		IndexColumns.Insert("Period", New Map);
		IndexColumns.Insert("StatisticsComment", New Map);
		
		AdditionalParameters = New Map;
		AdditionalParameters.Insert("StartDate", StartDate);
		AdditionalParameters.Insert("EndDate", EndDate);
		AdditionalParameters.Insert("IndexColumns", IndexColumns);
		StatisticsCommentsSection = GenerateJSONStructure("CommentsStatistics", QueryResult, AdditionalParameters);
		
		StatisticsCommentsSection["CommentsStatistics"]["columnsValueIndex"].Delete("StatisticsOperation");
		StatisticsCommentsSection["CommentsStatistics"]["columnsValueIndex"].Delete("Period");
		StatisticsCommentsSection["CommentsStatistics"].Insert("AggregationPeriod", DeletionPeriod);
		
		QueryResult = InformationRegisters.MeasurementsStatisticsAreas.GetMeasurements(StartDate, EndDate, DeletionPeriod);
		IndexColumns = New Map;
		IndexColumns.Insert("StatisticsOperation", New Map);
		IndexColumns.Insert("Period", New Map);
		IndexColumns.Insert("StatisticsArea", New Map);
		
		AdditionalParameters = New Map;
		AdditionalParameters.Insert("StartDate", StartDate);
		AdditionalParameters.Insert("EndDate", EndDate);
		AdditionalParameters.Insert("IndexColumns", IndexColumns);
		StatisticsAreasSection = GenerateJSONStructure("StatisticalAreas", QueryResult, AdditionalParameters);
		StatisticsAreasSection["StatisticalAreas"]["columnsValueIndex"].Delete("StatisticsOperation");
		StatisticsAreasSection["StatisticalAreas"]["columnsValueIndex"].Delete("Period");
		StatisticsAreasSection["StatisticalAreas"].Insert("AggregationPeriod", DeletionPeriod);
		
		QueryResult = InformationRegisters.StatisticsMeasurements.GetHourMeasurements(StartDate, EndDate);
		IndexColumns = New Map;
		IndexColumns.Insert("StatisticsOperation", New Map);
		IndexColumns.Insert("Period", New Map);
		
		AdditionalParameters = New Map;
		AdditionalParameters.Insert("IndexColumns", IndexColumns);
		StatisticsOperationsSectionClientHour = GenerateJSONStructure("OperationStatisticsClientHour", QueryResult, AdditionalParameters);
		
		QueryResult = InformationRegisters.StatisticsMeasurements.GetDayMeasurements(StartDate, EndDate);
		IndexColumns = New Map;
		IndexColumns.Insert("StatisticsOperation", New Map);
		IndexColumns.Insert("Period", New Map);
		
		AdditionalParameters = New Map;
		AdditionalParameters.Insert("IndexColumns", IndexColumns);
		StatisticsOperationsSectionClientDay = GenerateJSONStructure("OperationStatisticsClientDay", QueryResult, AdditionalParameters);
		
	EndIf;
	
	SeparationByDataAreasEnabled = SeparationByDataAreasEnabled();
	
	#Region StatisticsConfigurationSection
	If MonitoringCenterParameters.RegisterConfigurationStatistics Then
		If SeparationByDataAreasEnabled Then
			QueryResultNames = InformationRegisters.ConfigurationStatistics.GetStatisticsNames(0);
			ValueTableNames = QueryResultNames.Unload();
			
			Array = New Array;
			CheckDigit_10_0 = New NumberQualifiers(10, 0, AllowedSign.Nonnegative);
			Array.Add(Type("Number"));
			TypesDetailsNumber_10_0 = New TypeDescription(Array, CheckDigit_10_0,,,);
			ValueTableNames.Columns.Add("RowIndex", TypesDetailsNumber_10_0);
			MetadataNamesStructure = New Map;
			For Each curRow In ValueTableNames Do
				RowIndex = ValueTableNames.IndexOf(curRow);
				curRow.RowIndex = RowIndex;
				MetadataNamesStructure.Insert(RowIndex, curRow.StatisticsOperationDescription); 
			EndDo;
			
			ConfigurationStatisticsSection = New Structure("StatisticsConfiguration", New Structure);
			ConfigurationStatisticsSection.StatisticsConfiguration.Insert("MetadataName", Metadata.Name);
			ConfigurationStatisticsSection.StatisticsConfiguration.Insert("WorkingMode", ?(Common.FileInfobase(), "F", "S"));
			ConfigurationStatisticsSection.StatisticsConfiguration.Insert("DivisionByRegions", SeparationByDataAreasEnabled);
			ConfigurationStatisticsSection.StatisticsConfiguration.Insert("MetadataIndexName", New Map);
			For Each curRow In ValueTableNames Do
				ConfigurationStatisticsSection.StatisticsConfiguration.MetadataIndexName.Insert(String(curRow.RowIndex), curRow.StatisticsOperationDescription);
			EndDo;
						
			ConfigurationStatisticsSection.StatisticsConfiguration.Insert("StatisticsConfigurationByRegions", New Map);
			DataAreasResult = InformationRegisters.ConfigurationStatistics.GetDataAreasQueryResult();
			Selection = DataAreasResult.Select();
			While Selection.Next() Do
				DataAreaString = String(Selection.DataArea);
				DataAreaRef = InformationRegisters.StatisticsAreas.GetRef(DataAreaString);
				
				If InformationRegisters.StatisticsAreas.CollectConfigurationStatistics(DataAreaString) Then
					QueryResult = InformationRegisters.ConfigurationStatistics.GetStatistics(0, ValueTableNames, DataAreaRef);
					AreaConfigurationStatistics = GenerateJSONStructure(DataAreaString, QueryResult);
					ConfigurationStatisticsSection.StatisticsConfiguration.StatisticsConfigurationByRegions.Insert(DataAreaString, AreaConfigurationStatistics[DataAreaString]); 
				EndIf;
			EndDo;
			DataOnUsedExtensions = New Structure;
		Else
			QueryResult = InformationRegisters.ConfigurationStatistics.GetStatistics(0);
			AddtnlParameters = New Structure("MetadataName", Metadata.Name);
			AddtnlParameters.Insert("WorkingMode", ?(Common.FileInfobase(), "F", "S"));
			AddtnlParameters.Insert("DivisionByRegions", SeparationByDataAreasEnabled);
			AddtnlParameters.Insert("CompatibilityMode", String(Metadata.CompatibilityMode));
			AddtnlParameters.Insert("InterfaceCompatibilityMode", String(Metadata.InterfaceCompatibilityMode));
			AddtnlParameters.Insert("ModalityUseMode", String(Metadata.ModalityUseMode));
			DataOnUsedExtensions = DataOnUsedExtensions();
			DataOnRolesUsage = DataOnRolesUsage();
			AddtnlParameters.Insert("UsingExtensions", DataOnUsedExtensions.ExtensionsUsage);
			
			AdditionalParameters = New Map;
			AdditionalParameters.Insert("StartDate", StartDate);
			AdditionalParameters.Insert("AddlParameters", AddtnlParameters);
			ConfigurationStatisticsSection = GenerateJSONStructure("StatisticsConfiguration", QueryResult, AdditionalParameters);
		EndIf;
	EndIf;
	#EndRegion
	
	#Region OptionsSection
	If MonitoringCenterParameters.RegisterConfigurationSettings Then
		If SeparationByDataAreasEnabled Then
			QueryResultNames = InformationRegisters.ConfigurationStatistics.GetStatisticsNames(1);
			ValueTableNames = QueryResultNames.Unload();
			
			Array = New Array;
			CheckDigit_10_0 = New NumberQualifiers(10, 0, AllowedSign.Nonnegative);
			Array.Add(Type("Number"));
			TypesDetailsNumber_10_0 = New TypeDescription(Array, CheckDigit_10_0,,,);
			ValueTableNames.Columns.Add("RowIndex", TypesDetailsNumber_10_0);
			MetadataNamesStructure = New Map;
			For Each curRow In ValueTableNames Do
				RowIndex = ValueTableNames.IndexOf(curRow);
				curRow.RowIndex = RowIndex;
				MetadataNamesStructure.Insert(RowIndex, curRow.StatisticsOperationDescription); 
			EndDo;
			
			ConfigurationSettingSection = New Structure("Options", New Structure);
			ConfigurationSettingSection.Options.Insert("MetadataName", Metadata.Name);
			ConfigurationSettingSection.Options.Insert("WorkingMode", ?(Common.FileInfobase(), "F", "S"));
			ConfigurationSettingSection.Options.Insert("DivisionByRegions", SeparationByDataAreasEnabled);
			ConfigurationSettingSection.Options.Insert("MetadataIndexName", New Map);
			For Each curRow In ValueTableNames Do
				ConfigurationSettingSection.Options.MetadataIndexName.Insert(String(curRow.RowIndex), curRow.StatisticsOperationDescription);
			EndDo;
			
			ConfigurationSettingSection.Options.Insert("OptionsByRegions", New Map);
			DataAreasResult = InformationRegisters.ConfigurationStatistics.GetDataAreasQueryResult();
			Selection = DataAreasResult.Select();
			While Selection.Next() Do
				DataAreaString = String(Selection.DataArea);
				DataAreaRef = InformationRegisters.StatisticsAreas.GetRef(DataAreaString);
				
				If InformationRegisters.StatisticsAreas.CollectConfigurationStatistics(DataAreaString) Then
					QueryResult = InformationRegisters.ConfigurationStatistics.GetStatistics(1, ValueTableNames, DataAreaRef);
					AreaConfigurationStatistics = GenerateJSONStructure(DataAreaString, QueryResult);
					ConfigurationSettingSection.Options.OptionsByRegions.Insert(DataAreaString, AreaConfigurationStatistics[DataAreaString]); 
				EndIf;
			EndDo;
		Else
			QueryResult = InformationRegisters.ConfigurationStatistics.GetStatistics(1);
			AddtnlParameters = New Structure("MetadataName", Metadata.Name);
			AddtnlParameters.Insert("WorkingMode", ?(Common.FileInfobase(), 0, 1));
			
			AdditionalParameters = New Map;
			AdditionalParameters.Insert("StartDate", StartDate);
			AdditionalParameters.Insert("AddlParameters", AddtnlParameters);
			ConfigurationSettingSection = GenerateJSONStructure("Options", QueryResult, AdditionalParameters);
		EndIf;
	EndIf;
	#EndRegion
		
	PerformanceMonitorExists = Common.SubsystemExists("StandardSubsystems.PerformanceMonitor");
	If PerformanceMonitorExists Then
		ModulePerformanceMonitorInternal = Common.CommonModule("PerformanceMonitorInternal");
		
		If MonitoringCenterParameters.RegisterPerformance Then
			QueryResult = ModulePerformanceMonitorInternal.GetAPDEXTop(StartDate, EndDate, DeletionPeriod, TopApdex);
			IndexColumns = New Map;
			IndexColumns.Insert("Period", New Map);
			KeyOperationCollection = New Map;
			KeyOperationCollection.Insert("KOD");
			KeyOperationCollection.Insert("KON");
			IndexColumns.Insert("KOHash", KeyOperationCollection);
						
			AdditionalParameters = New Map;
			AdditionalParameters.Insert("StartDate", StartDate);
			AdditionalParameters.Insert("EndDate", AddtnlParameters);
			AdditionalParameters.Insert("IndexColumns", IndexColumns);
			TopAPDEXSection = GenerateJSONStructure("TopApdex", QueryResult, AdditionalParameters);	
			TopAPDEXSection["TopApdex"].Insert("AggregationPeriod", DeletionPeriod);
		EndIf;
		
		If MonitoringCenterParameters.RegisterTechnologicalPerformance Then
			QueryResult = ModulePerformanceMonitorInternal.GetTopTechnologicalAPDEX(StartDate, EndDate, DeletionPeriod, TopApdexTech);
			IndexColumns = New Map;
			IndexColumns.Insert("Period", New Map);
			KeyOperationCollection = New Map;
			KeyOperationCollection.Insert("KOD");
			KeyOperationCollection.Insert("KON");
			IndexColumns.Insert("KOHash", KeyOperationCollection);
			
			AdditionalParameters = New Map;
			AdditionalParameters.Insert("StartDate", StartDate);
			AdditionalParameters.Insert("EndDate", AddtnlParameters);
			AdditionalParameters.Insert("IndexColumns", IndexColumns);
			TopAPDEXSectionInternal = GenerateJSONStructure("TopApdexTechnology", QueryResult, AdditionalParameters);
			TopAPDEXSectionInternal["TopApdexTechnology"].Insert("AggregationPeriod", DeletionPeriod);
		EndIf;
	EndIf;
	
	InfobaseID = String(MonitoringCenterParameters.InfoBaseID);
	InfobaseIDPermanent = String(MonitoringCenterParameters.InfobaseIDPermanent);
	JSONStructure = New Structure;
	JSONStructure.Insert("ib",  InfobaseID);
	JSONStructure.Insert("ibConst",  InfobaseIDPermanent);
	JSONStructure.Insert("versionPacket",  "1.0.5.0");
	JSONStructure.Insert("datePacket",  CurrentUniversalDate());
	
	If MonitoringCenterParameters.RegisterSystemInformation Then
		JSONStructure.Insert("info",  Info);
	EndIf;
	
	If MonitoringCenterParameters.RegisterSubsystemVersions Then
		JSONStructure.Insert("versions",  Subsystems);
	EndIf;
		
	If MonitoringCenterParameters.RegisterDumps Then
		JSONStructure.Insert("dumps", DUMPSSection["dumps"]);
		DataOnFullDumps = New Structure;
		DataOnFullDumps.Insert("SendingResult", Parameters.SendingResult);
		DataOnFullDumps.Insert("SendDumpsFiles", Parameters.SendDumpsFiles);
		DataOnFullDumps.Insert("RequestConfirmationBeforeSending", Parameters.RequestConfirmationBeforeSending);
		JSONStructure.Insert("FullDumps", DataOnFullDumps);		
	EndIf;
	
	If MonitoringCenterParameters.RegisterBusinessStatistics Then
		BusinessStatistics = New Structure;
		BusinessStatistics.Insert("OperationStatistics", StatisticsOperationsSection["OperationStatistics"]);
		BusinessStatistics.Insert("CommentsStatistics", StatisticsCommentsSection["CommentsStatistics"]);
		BusinessStatistics.Insert("StatisticalAreas", StatisticsAreasSection["StatisticalAreas"]);
		BusinessStatistics.Insert("OperationStatisticsClientHour", StatisticsOperationsSectionClientHour["OperationStatisticsClientHour"]);
		BusinessStatistics.Insert("OperationStatisticsClientDay", StatisticsOperationsSectionClientDay["OperationStatisticsClientDay"]);
		JSONStructure.Insert("business", BusinessStatistics);
	EndIf;
	
	If MonitoringCenterParameters.RegisterConfigurationStatistics Then
		JSONStructure.Insert("config", ConfigurationStatisticsSection["StatisticsConfiguration"]);
		JSONStructure.Insert("extensionsInfo", DataOnUsedExtensions);
		JSONStructure.Insert("statisticOfRoles", DataOnRolesUsage);
	EndIf;
	
	If MonitoringCenterParameters.RegisterConfigurationSettings Then
		JSONStructure.Insert("options", ConfigurationSettingSection["Options"]);
	EndIf;
		
	If PerformanceMonitorExists Then
		If MonitoringCenterParameters.RegisterPerformance Then
			JSONStructure.Insert("perf", TopAPDEXSection["TopApdex"]);
		EndIf;
		
		If MonitoringCenterParameters.RegisterTechnologicalPerformance Then
			JSONStructure.Insert("internal_perf", TopAPDEXSectionInternal["TopApdexTechnology"]);
		EndIf;
	EndIf;
	
	If Parameters.ContactInformationChanged 
		AND (Parameters.ContactInformationRequest = 0 
		OR Parameters.ContactInformationRequest = 1) Then
		ContactInformation = New Structure;
		ContactInformation.Insert("ContactInformationRequest", Parameters.ContactInformationRequest);
		ContactInformation.Insert("ContactInformation", Parameters.ContactInformation);
		ContactInformation.Insert("ContactInformationComment", Parameters.ContactInformationComment);
		ContactInformation.Insert("PortalUsername", Parameters.PortalUsername);
		JSONStructure.Insert("contacts", ContactInformation);		
	EndIf;
			
	Return JSONStructure;
EndFunction

Function JSONStringToStructure(JSONString)
	JSONReader = New JSONReader();
	JSONReader.SetString(JSONString);
	
	JSONStructure = ReadJSON(JSONReader);
	
	Return JSONStructure;
EndFunction

Function JSONStructureToString(JSONStructure) Export
	JSONWriter = New JSONWriter;
	JSONWriter.SetString(New JSONWriterSettings(JSONLineBreak.None));
	WriteJSON(JSONWriter, JSONStructure);
		
	Return JSONWriter.Close();
EndFunction

#EndRegion

#Region WorkWithHTTPService

Function HTTPServiceSendDataInternal(Parameters)
	
	SecureConnection = Undefined;
	If Parameters.SecureConnection Then
		SecureConnection = CommonClientServer.NewSecureConnection();
	EndIf;
	
	InternetProxy = Undefined;
	If Common.SubsystemExists("StandardSubsystems.GetFilesFromInternet") Then
		ModuleNetworkDownload = Common.CommonModule("GetFilesFromInternet");
		InternetProxy = ModuleNetworkDownload.GetProxy("https");
	EndIf;
	
	HTTPConnection = New HTTPConnection(
		Parameters.Server, Parameters.Port,,,
		InternetProxy,
		Parameters.Timeout, 
		SecureConnection);
	
	HTTPRequest = New HTTPRequest(Parameters.ResourceAddress);
	
	If Parameters.DataType = "Text" Then
		HTTPRequest.SetBodyFromString(Parameters.Data);
	ElsIf Parameters.DataType = "ZIP" Then
		ArchiveFileName = WriteDataToArchive(Parameters.Data);
		ArchiveBinaryData = New BinaryData(ArchiveFileName);
		HTTPRequest.SetBodyFromBinaryData(ArchiveBinaryData);
	ElsIf Parameters.DataType = "BinaryData" Then
		ArchiveBinaryData = New BinaryData(Parameters.Data);
		HTTPRequest.SetBodyFromBinaryData(ArchiveBinaryData);
	EndIf;
	
	Try
		If Parameters.Method = "POST" Then
			HTTPResponse = HTTPConnection.Post(HTTPRequest);
		ElsIf Parameters.Method = "GET" Then
			HTTPResponse = HTTPConnection.Get(HTTPRequest);
		EndIf;
		
		HTTPResponseStructure = HTTPResponseToStructure(HTTPResponse);
		
		If HTTPResponseStructure.StatusCode = 200 Then
			If Parameters.DataType = "ZIP" Then
				DeleteFiles(ArchiveFileName);
			ElsIf Parameters.DataType = "BinaryData" Then
				DeleteFiles(Parameters.Data);
			EndIf;
		EndIf;
	Except
		HTTPResponseStructure = New Structure("StatusCode", 105);
	EndTry;
	
	Return HTTPResponseStructure;
EndFunction

Function WriteDataToArchive(Data)
	DataFileName = GetTempFileName("txt");
	ArchiveFileName = GetTempFileName("zip");
	
	TextWriter = New TextWriter(DataFileName);
	TextWriter.Write(Data);
	TextWriter.Close();
	
	ZipArchive = New ZipFileWriter(ArchiveFileName,,,ZIPCompressionMethod.Deflate,ZIPCompressionLevel.Maximum);
	ZipArchive.Add(DataFileName, ZIPStorePathMode.DontStorePath);
	ZipArchive.Write();
	
	DeleteFiles(DataFileName);
	
	Return ArchiveFileName; 
EndFunction

Function HTTPResponseToStructure(Response)
	Result = New Structure;
	
	Result.Insert("StatusCode", Response.StatusCode);
	Result.Insert("Headers",  New Map);
	For each Parameter In Response.Headers Do
		Result.Headers.Insert(Parameter.Key, Parameter.Value);
	EndDo;
	
	If Response.Headers["Content-Type"] <> Undefined Then
		ContentType = Response.Headers["Content-Type"];
		If StrFind(ContentType, "text/plain") > 0 Then
			Body = Response.GetBodyAsString();
			Result.Insert("Body", Body);
		ElsIf StrFind(ContentType, "text/html") > 0 Then
			Body = Response.GetBodyAsString();
			Result.Insert("Body", Body);
		ElsIf StrFind(ContentType, "application/json") Then
			Body = Response.GetBodyAsString();
			Result.Insert("Body", Body);
		Else
			Body = "Not known ContentType = " + ContentType + ". See. <Function HTTPResponseToStructure(Response) Export>";
			Result.Insert("Body", Body);
		EndIf;
	EndIf;	
	
	Return Result;
EndFunction

#EndRegion

#Region WorkWithDumpsRegistration

Procedure DumpsRegistration()
	PerformanceMonitorExists = Common.SubsystemExists("StandardSubsystems.PerformanceMonitor");
	If PerformanceMonitorExists Then
		ModulePerformanceMonitor = Common.CommonModule("PerformanceMonitor");
		StartTime = ModulePerformanceMonitor.StartTimeMeasurement();
	EndIf;
	
	DumpType = GetMonitoringCenterParameters("DumpType");
	DumpsDirectory = GetDumpsDirectory(DumpType);
	
	If DumpsDirectory.Path <> Undefined Then
		// Check if it is necessary to notify Administrator of process failure.
		CheckIfNotificationOfDumpsIsRequired(DumpsDirectory.Path);
		If DumpsDirectory.DeleteDumps Then
			DumpsToDelete = InformationRegisters.PlatformDumps.GetDumpsToDelete();
			
			For Each DumpToDelete In DumpsToDelete Do
				File = New File(DumpToDelete.FileName);
				If File.Exist() Then
					Try
						DeleteFiles(File.FullName);
						DumpToDelete.FileName = "";
						InformationRegisters.PlatformDumps.ChangeRecord(DumpToDelete);
					Except
						WriteLogEvent(EventLogEventMonitoringCenterDumpDeletion(), EventLogLevel.Error,,,
						DetailErrorDescription(ErrorInfo()));
					EndTry;
				Else
					DumpToDelete.FileName = "";
					InformationRegisters.PlatformDumps.ChangeRecord(DumpToDelete);
				EndIf;
			EndDo;
		EndIf;
		
		DumpsFiles = FindFiles(DumpsDirectory.Path, "*.mdmp");
		DumpsFilesNames = New Array;
		For Each DumpFile In DumpsFiles Do
			DumpsFilesNames.Add(DumpFile.FullName);
		EndDo;
		
		DumpsFilesRegistered = InformationRegisters.PlatformDumps.GetRegisteredDumps(DumpsFilesNames);
		
		For Each DumpFile In DumpsFiles Do
			If DumpsFilesRegistered[DumpFile.FullName] = Undefined Then 
				DumpNew = New Structure;
				DumpStructure = DumpDetails(DumpFile.Name);
				
				DumpNew.Insert("RegistrationDate", CurrentUniversalDateInMilliseconds());
				DumpNew.Insert("DumpOption", DumpStructure.Process + "_" + DumpStructure.PlatformVersion + "_" + DumpStructure.BeforeAfter);
				DumpNew.Insert("PlatformVersion", PlatformVersionToNumber(DumpStructure.PlatformVersion));
				DumpNew.Insert("FileName", DumpFile.FullName);
				
				InformationRegisters.PlatformDumps.ChangeRecord(DumpNew);
			EndIf;
		EndDo;
	Else
		SetMonitoringCenterParameter("RegisterDumps", False);
	EndIf;
	
	If PerformanceMonitorExists Then
		ModulePerformanceMonitor.EndTimeMeasurement("MonitoringCenterDumpRegistration", StartTime);
	EndIf;
EndProcedure

#EndRegion

#Region WorkWithConfigurationStatistics

Procedure CollectConfigurationStatistics(MonitoringCenterParameters = Undefined)
	If MonitoringCenterParameters = Undefined Then
		MonitoringCenterParameters.Insert("RegisterConfigurationStatistics");
		MonitoringCenterParameters.Insert("RegisterConfigurationSettings");
		MonitoringCenterParameters = GetMonitoringCenterParameters(MonitoringCenterParameters);
	EndIf;
	
	// It collects base configuration statistics if there is the Performance monitor subsystem and 
	// measures execution duration.
	// 
	//
	#Region BaseConfigurationStatistics
	
	If MonitoringCenterParameters.RegisterConfigurationStatistics OR  MonitoringCenterParameters.RegisterConfigurationSettings Then
		
		PerformanceMonitorRecordRequired = False;
		
		InformationRegisters.ConfigurationStatistics.ClearConfigurationStatistics();
		
		PerformanceMonitorExists = Common.SubsystemExists("StandardSubsystems.PerformanceMonitor");
		If PerformanceMonitorExists Then
			ModulePerformanceMonitor = Common.CommonModule("PerformanceMonitor");
			StartTime = ModulePerformanceMonitor.StartTimeMeasurement();
		EndIf;
		
		If MonitoringCenterParameters.RegisterConfigurationStatistics Then
			InformationRegisters.ConfigurationStatistics.WriteConfigurationStatistics();
			PerformanceMonitorRecordRequired = True;
		EndIf;
		
		If MonitoringCenterParameters.RegisterConfigurationSettings Then
			InformationRegisters.ConfigurationStatistics.WriteConfigurationSettings();
			PerformanceMonitorRecordRequired = True;
		EndIf;
		
		If PerformanceMonitorExists AND PerformanceMonitorRecordRequired Then
			ModulePerformanceMonitor.EndTimeMeasurement("MonitoringCenterCollectConfigurationStatisticalDataBasic", StartTime);
		EndIf;
	EndIf;
	
	#EndRegion
	
	// It collects configuration statistics if there is the Performance monitor subsystem and measures 
	// execution duration.
	// 
	//
	#Region ConfigurationStatisticsStandardSubsystems
	
	If MonitoringCenterParameters.RegisterConfigurationStatistics Then
		If PerformanceMonitorExists Then
			StartTime = ModulePerformanceMonitor.StartTimeMeasurement();
		EndIf;
		
		SeparationByDataAreasEnabled = SeparationByDataAreasEnabled();
		If SeparationByDataAreasEnabled Then
			DataAreasQueryResult = InformationRegisters.ConfigurationStatistics.GetDataAreasQueryResult();
			Selection = DataAreasQueryResult.Select();
			While Selection.Next() Do
				DataAreaString = String(Selection.DataArea);
				If InformationRegisters.StatisticsAreas.CollectConfigurationStatistics(DataAreaString) Then
					Try
						SetSessionSeparation(True, Selection.DataArea);
					Except
						Info = ErrorInfo();
						WriteLogEvent(NStr("ru = 'Центр мониторинга.Статистика конфигурации переопределяемая'; en = 'Monitoring center.Configuration statistics overridable'; pl = 'Monitoring center.Configuration statistics overridable';de = 'Monitoring center.Configuration statistics overridable';ro = 'Monitoring center.Configuration statistics overridable';tr = 'Monitoring center.Configuration statistics overridable'; es_ES = 'Monitoring center.Configuration statistics overridable'", Common.DefaultLanguageCode()),
						EventLogLevel.Error,
						,,
						NStr("ru = 'Не удалось установить разделение сеанса.Область данных'; en = 'Cannot set the session separation.Data area'; pl = 'Cannot set the session separation.Data area';de = 'Cannot set the session separation.Data area';ro = 'Cannot set the session separation.Data area';tr = 'Cannot set the session separation.Data area'; es_ES = 'Cannot set the session separation.Data area'", Common.DefaultLanguageCode()) + " = " + Format(Selection.DataArea, "NG=0")
						+ Chars.LF + DetailErrorDescription(Info));
						
						SetSessionSeparation(False);
						Continue;
					EndTry;
					SSLSubsystemsIntegration.OnCollectConfigurationStatisticsParameters();
					MonitoringCenterOverridable.OnCollectConfigurationStatisticsParameters();
					SetSessionSeparation(False);
				EndIf;
			EndDo;
		Else
			SSLSubsystemsIntegration.OnCollectConfigurationStatisticsParameters();
			MonitoringCenterOverridable.OnCollectConfigurationStatisticsParameters();
		EndIf;
		
		If PerformanceMonitorExists Then
			ModulePerformanceMonitor.EndTimeMeasurement("MonitoringCenterCollectConfigurationStatisticalDataStandardSubsystems", StartTime);
		EndIf;
	EndIf;
	
	#EndRegion
	
EndProcedure

#EndRegion

#Region WorkWithPackagesToSend

Procedure CreatePackageToSend()
	PerformanceMonitorExists = Common.SubsystemExists("StandardSubsystems.PerformanceMonitor");
	If PerformanceMonitorExists Then
		ModulePerformanceMonitor = Common.CommonModule("PerformanceMonitor");
		StartTime = ModulePerformanceMonitor.StartTimeMeasurement();
	EndIf;
	
	CurDate = CurrentUniversalDate(); 
	
	MonitoringCenterParameters = GetMonitoringCenterParameters();
	
	Parameters = New Structure;
	Parameters.Insert("StartDate", Date(1,1,1) + Int((MonitoringCenterParameters.LastPackageDate - Date(1,1,1))/MonitoringCenterParameters.DeletionPeriod) * MonitoringCenterParameters.DeletionPeriod);
	Parameters.Insert("EndDate", Date(1,1,1) + Int((CurDate - Date(1,1,1))/MonitoringCenterParameters.DeletionPeriod) * MonitoringCenterParameters.DeletionPeriod - 1);
	Parameters.Insert("TopDumpsQuantity", 5);
	Parameters.Insert("TopApdex", MonitoringCenterParameters.TopApdex);
	Parameters.Insert("TopApdexTech", MonitoringCenterParameters.TopApdexTech);
	Parameters.Insert("DeletionPeriod", MonitoringCenterParameters.DeletionPeriod);
	Parameters.Insert("SendingResult", MonitoringCenterParameters.SendingResult);
	Parameters.Insert("SendDumpsFiles", MonitoringCenterParameters.SendDumpsFiles);
	Parameters.Insert("RequestConfirmationBeforeSending", MonitoringCenterParameters.RequestConfirmationBeforeSending);
	// Contact information.
	Parameters.Insert("ContactInformationRequest", MonitoringCenterParameters.ContactInformationRequest);
	Parameters.Insert("ContactInformation", MonitoringCenterParameters.ContactInformation);
	Parameters.Insert("ContactInformationComment", MonitoringCenterParameters.ContactInformationComment);
	Parameters.Insert("PortalUsername", MonitoringCenterParameters.PortalUsername);
	Parameters.Insert("ContactInformationChanged", MonitoringCenterParameters.ContactInformationChanged);
		
	BeginTransaction();
	Try
		JSONStructure = GenerateJSONStructureForSending(Parameters);
		InformationRegisters.PackagesToSend.WriteNewPackage(CurDate, JSONStructure, MonitoringCenterParameters.LastPackageNumber + 1);
		
		MonitoringCenterParametersRecord = New Structure("LastPackageDate, LastPackageNumber");
		MonitoringCenterParametersRecord.LastPackageDate = CurDate;
		MonitoringCenterParametersRecord.LastPackageNumber = MonitoringCenterParameters.LastPackageNumber + 1;
		SetMonitoringCenterParameters(MonitoringCenterParametersRecord);
		
		CommitTransaction();
	Except
		RollbackTransaction();
		Error = DetailErrorDescription(ErrorInfo());
		WriteLogEvent(NStr("ru = 'Центр мониторинга.Формирование пакета для отправки'; en = 'Monitoring center.Generate a package for sending'; pl = 'Monitoring center.Generate a package for sending';de = 'Monitoring center.Generate a package for sending';ro = 'Monitoring center.Generate a package for sending';tr = 'Monitoring center.Generate a package for sending'; es_ES = 'Monitoring center.Generate a package for sending'", Common.DefaultLanguageCode()), EventLogLevel.Error, Metadata.CommonModules.MonitoringCenterInternal,,Error);
		Raise Error;
	EndTry;
	
	InformationRegisters.PackagesToSend.DeleteOldPackages();
	
	If PerformanceMonitorExists Then
		ModulePerformanceMonitor.EndTimeMeasurement("MonitoringCenterGeneratePackageToSend", StartTime);
	EndIf;
EndProcedure

Function SendMonitoringData(TestPackage = False)
	Parameters = GetSendServiceParameters();
	
	PerformanceMonitorExists = Common.SubsystemExists("StandardSubsystems.PerformanceMonitor");
	If PerformanceMonitorExists Then
		ModulePerformanceMonitor = Common.CommonModule("PerformanceMonitor");
		StartTime = ModulePerformanceMonitor.StartTimeMeasurement();
	EndIf;
	
	NumbersOfPackagesToSend = InformationRegisters.PackagesToSend.GetPackagesNumbers();
	For Each PackageNumber In NumbersOfPackagesToSend Do
		Package = InformationRegisters.PackagesToSend.GetPackage(PackageNumber);
		If Package <> Undefined Then
						
			PackageHash = Package.PackageHash;
			PackageNumber = Format(Package.PackageNumber, "NZ=0; NG=0");
			ID = String(Parameters.InfoBaseID);
			
			If Parameters.SecureConnection Then
				JoinType = "https";
			Else
				JoinType = "http";
			EndIf;
												
			ResourceAddress = Parameters.ResourceAddress;
			If Right(ResourceAddress, 1) <> "/" Then
				ResourceAddress = ResourceAddress + "/";
			EndIf;
			ResourceAddress = ResourceAddress + ID + "/" + PackageNumber + "/" + PackageHash;
			
			HTTPParameters = New Structure;
			HTTPParameters.Insert("Server", Parameters.Server);
			HTTPParameters.Insert("ResourceAddress", ResourceAddress);
			HTTPParameters.Insert("Data", Package.PackageBody);
			HTTPParameters.Insert("Port", Parameters.Port);
			HTTPParameters.Insert("SecureConnection", Parameters.SecureConnection);	
			HTTPParameters.Insert("Method", "POST");
			HTTPParameters.Insert("DataType", "Text");
			HTTPParameters.Insert("Timeout", 60);
			
			HTTPResponse = HTTPServiceSendDataInternal(HTTPParameters);
			
			If HTTPResponse.StatusCode = 200 Then
				AnswersParameters = JSONStringToStructure(HTTPResponse.Body);
				If Not TestPackage Then
					SetSendingParameters(AnswersParameters);
				Else
					If AnswersParameters.Property("foundCopy") AND AnswersParameters.foundCopy Then
						PerformActionsOnDetectCopy();
					Else
						SetMonitoringCenterParameter("DiscoveryPackageSent", True);
					EndIf;						
				EndIf;
				InformationRegisters.PackagesToSend.DeletePackage(PackageNumber);
			Else
				Break;
			EndIf;
		EndIf;
	EndDo;
	
	If PerformanceMonitorExists Then
		ModulePerformanceMonitor.EndTimeMeasurement("MonitoringCenterSubmitMonitoringData", StartTime);
	EndIf;
	
	Return HTTPResponse;
EndFunction

#EndRegion

#Region WorkWithMonitoringCenterParameters

Function RunPerformanceMeasurements()
	PerformanceMonitorExists = Common.SubsystemExists("StandardSubsystems.PerformanceMonitor");
	If PerformanceMonitorExists Then
		ModulePerformanceMonitorServerCallCached = Common.CommonModule("PerformanceMonitorServerCallCached");
		RunPerformanceMeasurements = ModulePerformanceMonitorServerCallCached.RunPerformanceMeasurements();
	Else
		RunPerformanceMeasurements = Undefined;
	EndIf;
	
	Return RunPerformanceMeasurements;
EndFunction

Function GetDefaultParameters()
	ConstantParameters = New Structure;
	
	// Parameters of collecting information on the system.
	//
	ConstantParameters.Insert("EnableMonitoringCenter", False);
	
	// Flag of processing center
	// True	- an external developer.
	//
	ConstantParameters.Insert("ApplicationInformationProcessingCenter", False);
	
	// Infobase ID.
	//
	InfobaseID = New UUID();
	ConstantParameters.Insert("InfoBaseID", InfobaseID);
	ConstantParameters.Insert("InfobaseIDPermanent", InfobaseID);
	
	// Parameters of collecting information on the system.
	//
	ConstantParameters.Insert("RegisterSystemInformation", False);
	
	// Parameters of collecting information on subsystem versions.
	//
	ConstantParameters.Insert("RegisterSubsystemVersions", False);
	
	// Dumps collection parameters
	//
	ConstantParameters.Insert("DumpRegistrationNextCreation", Date(1,1,1));
	ConstantParameters.Insert("DumpRegistrationCreationPeriod", 600);
	ConstantParameters.Insert("RegisterDumps", False);
	
	// Business statistics collection parameters.
	//
	ConstantParameters.Insert("AggregationPeriodMinor", 60);
	ConstantParameters.Insert("AggregationPeriod", 600);
	ConstantParameters.Insert("DeletionPeriod", 3600);
	ConstantParameters.Insert("AggregationBoundary", Date(1,1,1));
	ConstantParameters.Insert("BusinessStatisticsNextSnapshot", Date(1,1,1));
	ConstantParameters.Insert("BusinessStatisticsSnapshotPeriod", 600);
	ConstantParameters.Insert("RegisterBusinessStatistics", False);
	
	// Configuration statistics collection parameters.
	//
	ConstantParameters.Insert("ConfigurationStatisticsNextGeneration", Date(1,1,1));
	ConstantParameters.Insert("ConfigurationStatisticsGenerationPeriod", 86400);
	ConstantParameters.Insert("RegisterConfigurationStatistics", False);
	ConstantParameters.Insert("RegisterConfigurationSettings", False);
	
	// Performance data collection parameters.
	// 	If the PerformanceMonitorEnabled parameter is equal to zero, the function is disabled.
	// 	If the PerformanceMonitorEnabled parameter is equal to one, the function is enabled by monitoring center.
	// 	If the PerformanceMonitorEnabled parameter is equal to two, the function is enabled by performance monitor.
	//
	ConstantParameters.Insert("PerformanceMonitorEnabled", 0);
	
	ConstantParameters.Insert("RegisterPerformance", False);
	ConstantParameters.Insert("TopApdex", 10);
	ConstantParameters.Insert("RegisterTechnologicalPerformance", False);
	ConstantParameters.Insert("TopApdexTech", 10);
	ConstantParameters.Insert("RunPerformanceMeasurements", RunPerformanceMeasurements());
	
	// Data sending parameters
	//
	ConstantParameters.Insert("SendDataNextGeneration", Date(1,1,1));
	ConstantParameters.Insert("SendDataGenerationPeriod", 607800);
	ConstantParameters.Insert("LastPackageDate", Date(1,1,1));
	ConstantParameters.Insert("LastPackageNumber", 0);
	ConstantParameters.Insert("PackagesToSend", 3);
	ConstantParameters.Insert("Server", "pult.1c.ru");
	ConstantParameters.Insert("ResourceAddress", "pult/v1/packet/");
	ConstantParameters.Insert("DumpsResourceAddress", "pult/v1/dump/");
	ConstantParameters.Insert("Port", 443);
	ConstantParameters.Insert("SecureConnection", True);
	
	// Parameters of collecting and sending reports on errors (dumps).
	//
	// SendDumpsFiles
	//	0 - no.
	//  1 - yes.
	//  2 - no answer to the question is available, it was never asked.
	ConstantParameters.Insert("SendDumpsFiles", 2);
	ConstantParameters.Insert("DumpOption", "");
	// Fact of undergoing base checks, for example, free space and rights to change log files.
	// Required to generate notifications.
	ConstantParameters.Insert("BasicChecksPassed", False); 
	ConstantParameters.Insert("RequestConfirmationBeforeSending", True);
	ConstantParameters.Insert("SendingResult", "");
	ConstantParameters.Insert("DumpsInformation", ""); // Information that will be displayed to a user upon sending approval.
	ConstantParameters.Insert("SpaceReserveDisabled", 40);
	ConstantParameters.Insert("SpaceReserveEnabled", 20);
	ConstantParameters.Insert("DumpCollectingEnd", Date(2017,1,1));
	// It stores the list of computers where collection of full and sometimes mini dumps is enabled.
	ConstantParameters.Insert("FullDumpsCollectionEnabled", New Map);
	ConstantParameters.Insert("DumpInstances", New Map);
	ConstantParameters.Insert("DumpInstancesApproved", New Map);
	// Parameters of checking dumps failure frequency.
	ConstantParameters.Insert("DumpsCheckDepth", 604800);
	ConstantParameters.Insert("MinDumpsCount", 10000);
	ConstantParameters.Insert("DumpCheckNext", Date(1,1,1));
	ConstantParameters.Insert("DumpsCheckFrequency", 14400);
	// Defines a type of dumps being collected. By default, mini dumps.
	ConstantParameters.Insert("DumpType", "0"); // "0" - mini dump, "3" - full dump.
	
	// Forced sending of mini dumps.
	ConstantParameters.Insert("UserResponseTimeout", 14); // How many days to wait for an answer from the Administrator, in days.
	ConstantParameters.Insert("ForceSendMinidumps", 0); // How many days to wait for an answer from the Administrator, in days.
	ConstantParameters.Insert("NotificationDate", Date(1,1,1)); // Date of dumps request registration or notification of dumps.
	
	
	// Test package sending parameters.
	//
	ConstantParameters.Insert("TestPackageSent", False);
	ConstantParameters.Insert("TestPackageSendingAttemptCount", 0);
	
	// Discovery package sending parameters (for getting ID).
	//
	ConstantParameters.Insert("DiscoveryPackageSent", False);
	
	// Parameters of getting contact information.
	//
	// ContactInformationRequest
	//	0 - the user refused.
	//  1 - the user agreed.
	//  2 - no answer to the question is available, it was never asked.
	//  3 - a request for providing contact information is received.
	ConstantParameters.Insert("ContactInformationRequest", 2);
	ConstantParameters.Insert("ContactInformation", "");
	ConstantParameters.Insert("ContactInformationComment", "");
	ConstantParameters.Insert("PortalUsername", "");
	ConstantParameters.Insert("ContactInformationChanged", False);
	
	Return ConstantParameters; 
EndFunction

Function GetMonitoringCenterParameters(Parameters = Undefined) Export
	ConstantParameters = Constants.MonitoringCenterParameters.Get().Get();
	If ConstantParameters = Undefined Then
		ConstantParameters = New Structure;
	EndIf;
	
	DefaultParameters = GetDefaultParameters();
	
	For Each CurParameter In DefaultParameters Do
		If NOT ConstantParameters.Property(CurParameter.Key) Then
			ConstantParameters.Insert(CurParameter.Key, CurParameter.Value);
		EndIf;
	EndDo;
	
	If ConstantParameters = Undefined Then
		ConstantParameters = DefaultParameters;
	EndIf;
	
	If Parameters = Undefined Then
		Parameters = ConstantParameters;
	Else
		If TypeOf(Parameters) = Type("Structure") Then
			For Each CurParameter In Parameters Do
				Parameters[CurParameter.Key] = ConstantParameters[CurParameter.Key];
			EndDo;
		ElsIf TypeOf(Parameters) = Type("String") Then
			Parameters = ConstantParameters[Parameters];
		EndIf;
	EndIf;
	
	ConstantParameters.Insert("RunPerformanceMeasurements", RunPerformanceMeasurements());
	
	Return Parameters;
EndFunction

Function SetSendingParameters(Parameters)
	SendOptions = New Structure;
	SendOptions.Insert("PerformanceMonitorEnabled");
	SendOptions.Insert("RunPerformanceMeasurements");
	GetMonitoringCenterParameters(SendOptions);
	
	SendOptions.Insert("RegisterSystemInformation", False);
	SendOptions.Insert("RegisterSubsystemVersions", False);
	SendOptions.Insert("RegisterDumps", False);
	SendOptions.Insert("RegisterBusinessStatistics", False);
	SendOptions.Insert("RegisterConfigurationStatistics", False);
	SendOptions.Insert("RegisterConfigurationSettings", False);
	SendOptions.Insert("RegisterPerformance", False);
	SendOptions.Insert("RegisterTechnologicalPerformance", False);
	SendOptions.Insert("SendingResult", ""); // Reset a dump sending result to zero upon successful sending.
	SendOptions.Insert("DiscoveryPackageSent", True); // If a response from the service is received, always True.
	SendOptions.Insert("ContactInformationChanged", False);  // Always clear the contacts change flag upon successful sending.
	
	ParametersMap = New Structure;
	ParametersMap.Insert("info", "RegisterSystemInformation");
	ParametersMap.Insert("versions", "RegisterSubsystemVersions");
	ParametersMap.Insert("dumps", "RegisterDumps");
	ParametersMap.Insert("business", "RegisterBusinessStatistics");
	ParametersMap.Insert("config", "RegisterConfigurationStatistics");
	ParametersMap.Insert("options", "RegisterConfigurationSettings");
	ParametersMap.Insert("perf", "RegisterPerformance");
	ParametersMap.Insert("internal_perf", "RegisterTechnologicalPerformance");
	
	Settings = Parameters.packetProperties;
	For Each CurSetting In Settings Do
		If ParametersMap.Property(CurSetting) Then
			varKey = ParametersMap[CurSetting];
			
			If SendOptions.Property(varKey) Then
				SendOptions[varKey] = True;
			EndIf;
		EndIf;
	EndDo;
	
	If Parameters.Property("settings") Then
		NewSettings = Parameters.settings;
		NewSettings = StrReplace(NewSettings, ";", Chars.LF);
		DefaultSettings = GetDefaultParameters();
		For curRow = 1 To StrLineCount(NewSettings) Do
			CurSetting = StrGetLine(NewSettings, curRow);
			CurSetting = StrReplace(CurSetting, "=", Chars.LF);
			
			varKey = StrGetLine(CurSetting, 1);
			Value = StrGetLine(CurSetting, 2);
			
			If DefaultSettings.Property(varKey) Then
				If TypeOf(DefaultSettings[varKey]) = Type("Number") Then
					DetailsNumber = New TypeDescription("Number");
					CastedValue = DetailsNumber.AdjustValue(Value);
					If Format(CastedValue, "NZ=0; NG=") = Value Then
						SendOptions.Insert(varKey, CastedValue);
					EndIf;
				ElsIf TypeOf(DefaultSettings[varKey]) = Type("String") Then
					SendOptions.Insert(varKey, Value);
				ElsIf TypeOf(DefaultSettings[varKey]) = Type("Boolean") Then
					DetailsBoolean = New TypeDescription("Boolean");
					CastedValue = DetailsBoolean.AdjustValue(Value);
					If Format(CastedValue, "BF=false; BT=true") = Value Then
						SendOptions.Insert(varKey, CastedValue);
					EndIf;
				ElsIf TypeOf(DefaultSettings[varKey]) = Type("Date") Then
					DetailsDate = New TypeDescription("Date");
					CastedValue = DetailsDate.AdjustValue(Value);
					If Format(CastedValue, "DF=yyyymmddHHmmss") = Value Then
						SendOptions.Insert(varKey, CastedValue);
					EndIf;
				EndIf;
			EndIf;
		EndDo;
	EndIf;
	
	If Parameters.Property("deliveryIntervalHours") Then
		SendOptions.Insert("SendDataGenerationPeriod", Parameters.deliveryIntervalHours * 60 * 60);
	EndIf;
	
	If SendOptions["RegisterPerformance"] OR SendOptions["RegisterTechnologicalPerformance"] Then
		// There is no performance monitor subsystem.
		If SendOptions.RunPerformanceMeasurements = Undefined Then
			SendOptions.PerformanceMonitorEnabled = 0;
		// Disabled.
		ElsIf SendOptions.PerformanceMonitorEnabled = 0 AND NOT SendOptions.RunPerformanceMeasurements Then
			SendOptions.PerformanceMonitorEnabled = 1;
		// Enabled by performance monitor.
		ElsIf SendOptions.PerformanceMonitorEnabled = 0 AND SendOptions.RunPerformanceMeasurements Then
			SendOptions.PerformanceMonitorEnabled = 2;
		// Enabled by monitoring center.
		ElsIf SendOptions.PerformanceMonitorEnabled = 1 AND NOT SendOptions.RunPerformanceMeasurements Then
			SendOptions.PerformanceMonitorEnabled = 1;
		// Enabled by monitoring center.
		ElsIf SendOptions.PerformanceMonitorEnabled = 1 AND SendOptions.RunPerformanceMeasurements Then
			SendOptions.PerformanceMonitorEnabled = 1;
		// It was enabled by performance monitor and then disabled.
		ElsIf SendOptions.PerformanceMonitorEnabled = 2 AND NOT SendOptions.RunPerformanceMeasurements Then
			SendOptions.PerformanceMonitorEnabled = 0;
		// Enabled by performance monitor.
		ElsIf SendOptions.PerformanceMonitorEnabled = 2 AND SendOptions.RunPerformanceMeasurements Then
			SendOptions.PerformanceMonitorEnabled = 2;
		EndIf;
	Else
		// There is no performance monitor subsystem.
		If SendOptions.RunPerformanceMeasurements = Undefined Then
			SendOptions.PerformanceMonitorEnabled = 0;
		// Disabled.
		ElsIf SendOptions.PerformanceMonitorEnabled = 0 AND NOT SendOptions.RunPerformanceMeasurements Then
			SendOptions.PerformanceMonitorEnabled = 0;
		// Enabled by performance monitor.
		ElsIf SendOptions.PerformanceMonitorEnabled = 0 AND SendOptions.RunPerformanceMeasurements Then
			SendOptions.PerformanceMonitorEnabled = 2;
		// Enabled by monitoring center.
		ElsIf SendOptions.PerformanceMonitorEnabled = 1 AND NOT SendOptions.RunPerformanceMeasurements Then
			SendOptions.PerformanceMonitorEnabled = 0;
		// Enabled by monitoring center.
		ElsIf SendOptions.PerformanceMonitorEnabled = 1 AND SendOptions.RunPerformanceMeasurements Then
			SendOptions.PerformanceMonitorEnabled = 0;
		// It was enabled by performance monitor and then disabled.
		ElsIf SendOptions.PerformanceMonitorEnabled = 2 AND NOT SendOptions.RunPerformanceMeasurements Then
			SendOptions.PerformanceMonitorEnabled = 0;
		// Enabled by performance monitor.
		ElsIf SendOptions.PerformanceMonitorEnabled = 2 AND SendOptions.RunPerformanceMeasurements Then
			SendOptions.PerformanceMonitorEnabled = 2;
		EndIf;
	EndIf;
	
	If Parameters.Property("foundCopy") AND Parameters.foundCopy Then
		PerformActionsOnDetectCopy();
		SendOptions.Insert("DiscoveryPackageSent", False);
	EndIf;

	BeginTransaction();
	Try
		If SendOptions.PerformanceMonitorEnabled = 0 AND NOT SendOptions.RunPerformanceMeasurements = Undefined Then
			ModulePerformanceMonitor = Common.CommonModule("PerformanceMonitor");
			ModulePerformanceMonitor.EnablePerformanceMeasurements(False);
		ElsIf SendOptions.PerformanceMonitorEnabled = 1 AND NOT SendOptions.RunPerformanceMeasurements = Undefined Then
			ModulePerformanceMonitor = Common.CommonModule("PerformanceMonitor");	
			ModulePerformanceMonitor.EnablePerformanceMeasurements(True);
		EndIf;
		
		SetMonitoringCenterParameters(SendOptions);
		CommitTransaction();
	Except
		RollbackTransaction();
		Error = DetailErrorDescription(ErrorInfo());
		WriteLogEvent(NStr("ru = 'Центр мониторинга.Установка параметров отправки'; en = 'Monitoring center.Set sending parameters'; pl = 'Monitoring center.Set sending parameters';de = 'Monitoring center.Set sending parameters';ro = 'Monitoring center.Set sending parameters';tr = 'Monitoring center.Set sending parameters'; es_ES = 'Monitoring center.Set sending parameters'", Common.DefaultLanguageCode()), EventLogLevel.Error, Metadata.CommonModules.MonitoringCenterInternal,,Error);
		Raise Error;
	EndTry;
	
	Return SendOptions;
	
EndFunction

Function SetMonitoringCenterParameters(NewParameters)
	Error = "Success";
	Lock = New DataLock;
	Lock.Add("Constant.MonitoringCenterParameters");
	
	BeginTransaction();
	
	Try
		Lock.Lock();
		Parameters = GetMonitoringCenterParameters();
		
		If NewParameters.Property("RunPerformanceMeasurements") Then
			NewParameters.Delete("RunPerformanceMeasurements");
		EndIf;
				
		For Each CurParameter In NewParameters Do
			If NOT Parameters.Property(CurParameter.Key) Then
				Parameters.Insert(CurParameter.Key);
			EndIf;
			
			Parameters[CurParameter.Key] = CurParameter.Value;
		EndDo;
		
		Storage = New ValueStorage(Parameters);
		
		Constants.MonitoringCenterParameters.Set(Storage);
		
		CommitTransaction();
	Except
		RollbackTransaction();
		Error = DetailErrorDescription(ErrorInfo());
		WriteLogEvent(NStr("ru = 'Центр мониторинга.Установка параметров центра мониторинга'; en = 'Monitoring center.Set monitoring center parameters'; pl = 'Monitoring center.Set monitoring center parameters';de = 'Monitoring center.Set monitoring center parameters';ro = 'Monitoring center.Set monitoring center parameters';tr = 'Monitoring center.Set monitoring center parameters'; es_ES = 'Monitoring center.Set monitoring center parameters'", Common.DefaultLanguageCode()), EventLogLevel.Error, Metadata.CommonModules.MonitoringCenterInternal,,Error);
		Raise Error;
	EndTry;
	Return Error;
EndFunction

Procedure DeleteMonitoringCenterParameters()
	Try
		Parameters = New Structure;
		Storage = New ValueStorage(Parameters);
		Constants.MonitoringCenterParameters.Set(Storage);
	Except
		Error = DetailErrorDescription(ErrorInfo());
		WriteLogEvent(NStr("ru = 'Центр мониторинга.Удалить параметры центра мониторинга'; en = 'Monitoring center.Delete monitoring center parameters'; pl = 'Monitoring center.Delete monitoring center parameters';de = 'Monitoring center.Delete monitoring center parameters';ro = 'Monitoring center.Delete monitoring center parameters';tr = 'Monitoring center.Delete monitoring center parameters'; es_ES = 'Monitoring center.Delete monitoring center parameters'", Common.DefaultLanguageCode()), EventLogLevel.Error, Metadata.CommonModules.MonitoringCenterInternal,,Error);
		Raise Error;
	EndTry;
EndProcedure

Function SetMonitoringCenterParameter(Parameter, Value)
	Error = "Success";
	Lock = New DataLock;
	Lock.Add("Constant.MonitoringCenterParameters");
	
	BeginTransaction();
	Try
		Lock.Lock();
		Parameters = GetMonitoringCenterParameters();
		
		If NOT Parameters.Property(Parameter) Then
			Parameters.Insert(Parameter);
		EndIf;
		
		Parameters[Parameter] = Value;
		
		Storage = New ValueStorage(Parameters);
		
		Constants.MonitoringCenterParameters.Set(Storage);
		
		CommitTransaction();
	Except
		RollbackTransaction();
		Error = DetailErrorDescription(ErrorInfo());
		WriteLogEvent(NStr("ru = 'Центр мониторинга.Установка параметров центра мониторинга'; en = 'Monitoring center.Set monitoring center parameters'; pl = 'Monitoring center.Set monitoring center parameters';de = 'Monitoring center.Set monitoring center parameters';ro = 'Monitoring center.Set monitoring center parameters';tr = 'Monitoring center.Set monitoring center parameters'; es_ES = 'Monitoring center.Set monitoring center parameters'", Common.DefaultLanguageCode()), EventLogLevel.Error, Metadata.CommonModules.MonitoringCenterInternal,,Error);
		Raise Error;
	EndTry;
	Return Error;
EndFunction

Function GetSendServiceParameters()
	ServiceParameters = New Structure;
	
	ServiceParameters.Insert("EnableMonitoringCenter");
	ServiceParameters.Insert("ApplicationInformationProcessingCenter");
	ServiceParameters.Insert("InfoBaseID");
	ServiceParameters.Insert("Server");
	ServiceParameters.Insert("ResourceAddress");
	ServiceParameters.Insert("DumpsResourceAddress");
	ServiceParameters.Insert("Port");
	ServiceParameters.Insert("SecureConnection");
	
	GetMonitoringCenterParameters(ServiceParameters);
	
	If ServiceParameters.EnableMonitoringCenter AND NOT ServiceParameters.ApplicationInformationProcessingCenter Then
		DefaultServiceParameters = GetDefaultParameters();
		
		ServiceParameters.Insert("Server", DefaultServiceParameters.Server);
		ServiceParameters.Insert("ResourceAddress", DefaultServiceParameters.ResourceAddress);
		ServiceParameters.Insert("DumpsResourceAddress", DefaultServiceParameters.DumpsResourceAddress);
		ServiceParameters.Insert("Port", DefaultServiceParameters.Port);
		ServiceParameters.Insert("SecureConnection", DefaultServiceParameters.SecureConnection);
	EndIf;
	
	ServiceParameters.Delete("EnableMonitoringCenter");
	ServiceParameters.Delete("ApplicationInformationProcessingCenter");
	
	Return ServiceParameters;
EndFunction

#EndRegion

#Region WorkWithSettingsFile

// This function gets dumps collection directory on the server. This is an export function for testing carried out by the data processor.
// Returns
//    Structure - contains a path to a dumps directory and dumps deletion flag.
//
Function GetDumpsDirectory(DumpType = "0", StopCollectingFull = False) Export
	SettingsDirectory = GetTechnologicalLogSettingsDirectory();
	DumpsDirectory = FindDumpsDirectory(SettingsDirectory, DumpType, StopCollectingFull);
	
	Return DumpsDirectory;
EndFunction

Function GeneratePathWithSeparator(Path)
	If ValueIsFilled(Path) Then
		PathSeparator = GetServerPathSeparator();
		If Right(Path, 1) <> PathSeparator Then
			Path = Path + PathSeparator;
		EndIf;
	EndIf;
	
	Return Path;
EndFunction

Function FindDumpsDirectory(SettingsDirectory, DumpType, StopCollectingFull) 
	DumpsDirectory = New Structure("Path, DeleteDumps, ErrorDescription", "", False, "");
	
	SettingsFileName = "logcfg.xml";
	DirectoryPath = GeneratePathWithSeparator(SettingsDirectory.Path);
	
	FullDumpsCollectionEnabled = GetMonitoringCenterParameters("FullDumpsCollectionEnabled")[ComputerName()];
		
	File = New File(DirectoryPath + SettingsFileName);
	If File.Exist() Then
		Try
			XMLReader = New XMLReader;
			XMLReader.OpenFile(File.FullName, New XMLReaderSettings(,,,,,,,True, True));
			While XMLReader.Read() Do
				If XMLReader.NodeType = XMLNodeType.StartElement AND XMLReader.HasName AND Upper(XMLReader.Name) = "DUMP" Then
					DumpsParameters = New Structure;
					If XMLReader.AttributeCount() > 0 Then
						While XMLReader.ReadAttribute() Do
							DumpsParameters.Insert(XMLReader.LocalName, XMLReader.Value);
						EndDo;
					EndIf;
				EndIf;
			EndDo;
		Except
			Message = NStr("ru='Ошибка чтения файла настроек технологического журнала'; en = 'An error occurred when reading a setting file of the technological log'; pl = 'An error occurred when reading a setting file of the technological log';de = 'An error occurred when reading a setting file of the technological log';ro = 'An error occurred when reading a setting file of the technological log';tr = 'An error occurred when reading a setting file of the technological log'; es_ES = 'An error occurred when reading a setting file of the technological log'");
			Message = Message + " """ +File.FullName + """." + Chars.LF;
			Message = Message + NStr("ru='Скорее всего файл поврежден. Регистрация дампов не возможна. Удалите поврежденный файл или восстановите настройки.'; en = 'The file is likely corrupt. Cannot register dumps. Delete the corrupt file or reset settings.'; pl = 'The file is likely corrupt. Cannot register dumps. Delete the corrupt file or reset settings.';de = 'The file is likely corrupt. Cannot register dumps. Delete the corrupt file or reset settings.';ro = 'The file is likely corrupt. Cannot register dumps. Delete the corrupt file or reset settings.';tr = 'The file is likely corrupt. Cannot register dumps. Delete the corrupt file or reset settings.'; es_ES = 'The file is likely corrupt. Cannot register dumps. Delete the corrupt file or reset settings.'");
			
			WriteLogEvent(NStr("ru = 'Центр мониторинга'; en = 'Monitoring center'; pl = 'Monitoring center';de = 'Monitoring center';ro = 'Monitoring center';tr = 'Monitoring center'; es_ES = 'Monitoring center'", Common.DefaultLanguageCode()), EventLogLevel.Warning,,,Message);
			
			DumpsDirectory.Path = Undefined;
			DumpsDirectory.ErrorDescription = NStr("ru='Ошибка чтения файла настроек технологического журнала'; en = 'An error occurred when reading a setting file of the technological log'; pl = 'An error occurred when reading a setting file of the technological log';de = 'An error occurred when reading a setting file of the technological log';ro = 'An error occurred when reading a setting file of the technological log';tr = 'An error occurred when reading a setting file of the technological log'; es_ES = 'An error occurred when reading a setting file of the technological log'");
			Return DumpsDirectory;
		EndTry;
		
		If DumpsParameters <> Undefined Then
			If NOT DumpsParameters.Property("location") OR NOT DumpsParameters.Property("create") OR NOT DumpsParameters.Property("type") Then
				Message = NStr("ru='Ошибка секции сбора дампов в файле настроек технологического журнала'; en = 'Dump collection section error in the setting file of technological log'; pl = 'Dump collection section error in the setting file of technological log';de = 'Dump collection section error in the setting file of technological log';ro = 'Dump collection section error in the setting file of technological log';tr = 'Dump collection section error in the setting file of technological log'; es_ES = 'Dump collection section error in the setting file of technological log'");
				Message = Message + " """ +File.FullName + """." + Chars.LF;
				Message = Message + NStr("ru='Регистрация дампов не возможна. Удалите файл или восстановите настройки.'; en = 'Cannot register dumps. Remove the file or restore the settings.'; pl = 'Cannot register dumps. Remove the file or restore the settings.';de = 'Cannot register dumps. Remove the file or restore the settings.';ro = 'Cannot register dumps. Remove the file or restore the settings.';tr = 'Cannot register dumps. Remove the file or restore the settings.'; es_ES = 'Cannot register dumps. Remove the file or restore the settings.'");
				XMLReader.Close();
				
				WriteLogEvent(NStr("ru = 'Центр мониторинга'; en = 'Monitoring center'; pl = 'Monitoring center';de = 'Monitoring center';ro = 'Monitoring center';tr = 'Monitoring center'; es_ES = 'Monitoring center'", Common.DefaultLanguageCode()), EventLogLevel.Warning,,,Message);
				
				DumpsDirectory.Path = Undefined;
				DumpsDirectory.ErrorDescription = NStr("ru='Ошибка секции сбора дампов в файле настроек технологического журнала'; en = 'Dump collection section error in the setting file of technological log'; pl = 'Dump collection section error in the setting file of technological log';de = 'Dump collection section error in the setting file of technological log';ro = 'Dump collection section error in the setting file of technological log';tr = 'Dump collection section error in the setting file of technological log'; es_ES = 'Dump collection section error in the setting file of technological log'");
				Return DumpsDirectory;
			EndIf;
		EndIf;
				
		If DumpsParameters <> Undefined Then
			DumpsDirectory.Path = GeneratePathWithSeparator(DumpsParameters.Location);
			If StrFind(DumpsDirectory.Path, "80af5716-b134-4b1c-a38d-4658d1ac4196") > 0 AND NOT FullDumpsCollectionEnabled = True Then
				DumpsDirectory.DeleteDumps = True;
			EndIf;
			XMLReader.Close();
			
			If DumpsParameters.type <> DumpType Then
				CreateDumpsCollectionSection(File, XMLReader, DumpsDirectory, DumpType);
			ElsIf StrFind(DumpsDirectory.Path, "80af5716-b134-4b1c-a38d-4658d1ac4196") > 0 Then
				If NOT DumpsParameters.Property("externaldump") Then
					CreateDumpsCollectionSection(File, XMLReader, DumpsDirectory, DumpType);
				ElsIf DumpsParameters.externaldump <> "1" Then
					CreateDumpsCollectionSection(File, XMLReader, DumpsDirectory, DumpType);
				EndIf;
			EndIf;
		Else
			XMLReader.Close();
			CreateDumpsCollectionSection(File, XMLReader, DumpsDirectory, DumpType);
		EndIf;
			
	Else
		DumpsDirectory.Path = CreateDumpsCollectionSettingsFile(DirectoryPath, DumpType);
		If NOT FullDumpsCollectionEnabled Then
			DumpsDirectory.DeleteDumps = True;
		EndIf;
		If DumpsDirectory.Path = Undefined Then
			DumpsDirectory.ErrorDescription = NStr("ru='Ошибка создания файла настроек технологического журнала. Регистрация дампов не возможна.'; en = 'An error occurred while creating the setting file of the technological log. Cannot register dumps.'; pl = 'An error occurred while creating the setting file of the technological log. Cannot register dumps.';de = 'An error occurred while creating the setting file of the technological log. Cannot register dumps.';ro = 'An error occurred while creating the setting file of the technological log. Cannot register dumps.';tr = 'An error occurred while creating the setting file of the technological log. Cannot register dumps.'; es_ES = 'An error occurred while creating the setting file of the technological log. Cannot register dumps.'");
		EndIf;
	EndIf;
	
	Return DumpsDirectory;
EndFunction

Function CreateDumpsCollectionSection(File, XMLReader, DumpsDirectory, DumpType)
	
	ID = "80af5716-b134-4b1c-a38d-4658d1ac4196";
	
	XMLReader.OpenFile(File.FullName, New XMLReaderSettings(,,,,,,,False, False));
	
	DOMBuilder = New DOMBuilder;
	DocumentDOM = DOMBuilder.Read(XMLReader);
	DocumentDOM.Normalize();
	XMLReader.Close();
		If DocumentDOM.HasChildNodes() Then
		FirstChild = DocumentDOM.FirstChild;
		If Upper(FirstChild.NodeName) = "CONFIG" Then
			DefaultPath = StrFind(DumpsDirectory.Path, ID) > 0;
			If IsBlankString(DumpsDirectory.Path) OR DefaultPath Then
				DumpsDirectory.Path = GeneratePathWithSeparator(GeneratePathWithSeparator(TempFilesDir() + "Dumps") + ID);
			EndIf;
			DumpsDirectory.DeleteDumps = True;
			
			ItemsDumps = DocumentDOM.GetElementByTagName("dump");
			If ItemsDumps.Count() = 0 Then
				
				ItemDumps = DocumentDOM.CreateElement("dump");
				ItemDumps.SetAttribute("location", DumpsDirectory.Path);
				ItemDumps.SetAttribute("create", "1");
				ItemDumps.SetAttribute("type", DumpType);
				ItemDumps.SetAttribute("externaldump", "1");
				FirstChild.AppendChild(ItemDumps);
			Else
				For Each CurItem In ItemsDumps Do
					CurItem.SetAttribute("externaldump", "1");
					CurItem.SetAttribute("type", DumpType);
					CurItem.SetAttribute("location", DumpsDirectory.Path);
				EndDo;
			EndIf;
			
			Try
				XMLWriter = New XMLWriter;
				DOMWriter = New DOMWriter; 
				XMLWriter.OpenFile(File.FullName, New XMLWriterSettings(,,True,True));
				DOMWriter.Write(DocumentDOM, XMLWriter);
				XMLWriter.Close();
			Except
				Message = NStr("ru='Ошибка записи файла настроек технологического журнала. Регистрация дампов не возможна.'; en = 'An error occurred while writing the setting file of the technological log. Cannot register dumps.'; pl = 'An error occurred while writing the setting file of the technological log. Cannot register dumps.';de = 'An error occurred while writing the setting file of the technological log. Cannot register dumps.';ro = 'An error occurred while writing the setting file of the technological log. Cannot register dumps.';tr = 'An error occurred while writing the setting file of the technological log. Cannot register dumps.'; es_ES = 'An error occurred while writing the setting file of the technological log. Cannot register dumps.'");
				Message = Message + " """ +File.FullName + """." + Chars.LF;
				Message = Message + DetailErrorDescription(ErrorInfo());
				
				WriteLogEvent(NStr("ru = 'Центр мониторинга - регистрация дампов'; en = 'Monitoring center - dump registration'; pl = 'Monitoring center - dump registration';de = 'Monitoring center - dump registration';ro = 'Monitoring center - dump registration';tr = 'Monitoring center - dump registration'; es_ES = 'Monitoring center - dump registration'", Common.DefaultLanguageCode()), EventLogLevel.Warning,,,Message);
				
				DumpsDirectory.Path = Undefined;
				DumpsDirectory.ErrorDescription = NStr("ru='Ошибка записи файла настроек технологического журнала. Регистрация дампов не возможна.'; en = 'An error occurred while writing the setting file of the technological log. Cannot register dumps.'; pl = 'An error occurred while writing the setting file of the technological log. Cannot register dumps.';de = 'An error occurred while writing the setting file of the technological log. Cannot register dumps.';ro = 'An error occurred while writing the setting file of the technological log. Cannot register dumps.';tr = 'An error occurred while writing the setting file of the technological log. Cannot register dumps.'; es_ES = 'An error occurred while writing the setting file of the technological log. Cannot register dumps.'");
				Return DumpsDirectory;
			EndTry;
		EndIf;
	EndIf;
EndFunction

// This function generates a path to a dumps directory.
// The dumps directory is cleared automatically using the DumpsRegistration method.
// Parameters:
//    DirectoryPath - String - a path to a directory where a setting file of technological log is stored.
// Returns:
//    DumpsDirectory - String - a path to a directory where mini dumps will be stored.
//
Function CreateDumpsCollectionSettingsFile(DirectoryPath, DumpType)
	SettingsFileName = "logcfg.xml";
	
	ID = "80af5716-b134-4b1c-a38d-4658d1ac4196";
	DumpsDirectory = GeneratePathWithSeparator(GeneratePathWithSeparator(TempFilesDir() + "Dumps") + ID);
	
	Try
		XMLWriter = New XMLWriter;
		XMLWriter.OpenFile(DirectoryPath + SettingsFileName);
		DumpsCollection =
		"<config xmlns=""http://v8.1c.ru/v8/tech-log"">
		|	<dump location=""" + DumpsDirectory + """ create=""1"" type=""" + DumpType + """ externaldump=""1""/>
		|</config>";
		XMLWriter.WriteRaw(DumpsCollection);
		XMLWriter.Close();
	Except
		Message = NStr("ru='Ошибка создания файла настроек технологического журнала. Регистрация дампов не возможна.'; en = 'An error occurred while creating the setting file of the technological log. Cannot register dumps.'; pl = 'An error occurred while creating the setting file of the technological log. Cannot register dumps.';de = 'An error occurred while creating the setting file of the technological log. Cannot register dumps.';ro = 'An error occurred while creating the setting file of the technological log. Cannot register dumps.';tr = 'An error occurred while creating the setting file of the technological log. Cannot register dumps.'; es_ES = 'An error occurred while creating the setting file of the technological log. Cannot register dumps.'");
		Message = Message + " """ +DirectoryPath + SettingsFileName + """." + Chars.LF;
		Message = Message + DetailErrorDescription(ErrorInfo());
		
		WriteLogEvent(NStr("ru = 'Центр мониторинга'; en = 'Monitoring center'; pl = 'Monitoring center';de = 'Monitoring center';ro = 'Monitoring center';tr = 'Monitoring center'; es_ES = 'Monitoring center'", Common.DefaultLanguageCode()), EventLogLevel.Warning,,,Message);
		
		DumpsDirectory = Undefined;
		
	EndTry;
	
	Return DumpsDirectory;
EndFunction

Function GetTechnologicalLogSettingsDirectory()
	SettingsDirectory = New Structure("Path, Exist, ErrorDescription", "", False, "");
	
	// Directories where it was searched are required as a protection from looping.
	SettingsDirectories = New Array;
	
	SettingsFileName = "logcfg.xml";
	SettingsConfigurationFileName = "conf.cfg";
	
	ApplicationDirectory = GeneratePathWithSeparator(BinDir());
		
	SearchForDirectory = True;
	Counter = 0;
	DirectoryPath = GeneratePathWithSeparator(ApplicationDirectory + "conf");
	While SearchForDirectory = True Do
		// Check if it was searched in the current directory (protection from looping).
		If SettingsDirectories.Find(DirectoryPath) <> Undefined Then
			SettingsDirectory.Path = "";
			SettingsDirectory.Exist = False;
			SettingsDirectory.ErrorDescription = NStr("ru = 'Обнаружена циклическая ссылка'; en = 'Circular ref is found'; pl = 'Circular ref is found';de = 'Circular ref is found';ro = 'Circular ref is found';tr = 'Circular ref is found'; es_ES = 'Circular ref is found'", Common.DefaultLanguageCode());
			
			SearchForDirectory = False;
		Else
			FullSettingsFileName = DirectoryPath + SettingsFileName;
			SettingsFile = New File(FullSettingsFileName);
			If SettingsFile.Exist() Then
				SettingsDirectory.Path = DirectoryPath;
				SettingsDirectory.Exist = True;
				SettingsDirectory.ErrorDescription = "";
				
				SearchForDirectory = False;
			Else
				SettingsDirectories.Add(DirectoryPath);
				
				FullSettingsConfigurationFileName = DirectoryPath + SettingsConfigurationFileName;
				SettingsConfigurationFile = New File(FullSettingsConfigurationFileName);
				If SettingsConfigurationFile.Exist() Then
					DirectoryPath = GetDirectoryFromSettingsConfigurationFile(SettingsConfigurationFile);
					If DirectoryPath.Exist Then
						DirectoryPath = GeneratePathWithSeparator(DirectoryPath.Path);
					Else
						SettingsDirectory.Path = DirectoryPath.Path;
						SettingsDirectory.Exist = DirectoryPath.Exist;
						SettingsDirectory.ErrorDescription = DirectoryPath.ErrorDescription;
						
						SearchForDirectory = False;
					EndIf;
				Else
					SettingsDirectory.Path = "";
					SettingsDirectory.Exist = False;
					SettingsDirectory.ErrorDescription = NStr("ru = 'Не найден файл конфигурации настроек в каталоге'; en = 'Setting configuration file is not found in the directory'; pl = 'Setting configuration file is not found in the directory';de = 'Setting configuration file is not found in the directory';ro = 'Setting configuration file is not found in the directory';tr = 'Setting configuration file is not found in the directory'; es_ES = 'Setting configuration file is not found in the directory'", Common.DefaultLanguageCode()) + " " + DirectoryPath;
					
					SearchForDirectory = False;
				EndIf;
			EndIf;
		EndIf;
		
		Counter = Counter + 1;
		
		If Counter >= 100 Then
			SearchForDirectory = False;
		EndIf;
	EndDo;
	
	Return SettingsDirectory;
EndFunction

Function GetDirectoryFromSettingsConfigurationFile(SettingsConfigurationFile)
	SettingsDirectory = New Structure("Path, Exist, ErrorDescription", "", False, "");
	
	SearchString = "ConfLocation=";
	SearchStringLength = StrLen(SearchString);
	
	Text = New TextReader(SettingsConfigurationFile.FullName);
	Data = Text.Read();
	
	SearchIndex = StrFind(Data, SearchString);
	If SearchIndex > 0 Then
		DataBuffer = Right(Data, StrLen(Data) - (SearchIndex + SearchStringLength - 1));
		SearchIndex = StrFind(DataBuffer, Chars.LF);
		If SearchIndex > 0 Then
			SettingsDirectory.Path = GeneratePathWithSeparator(Left(DataBuffer, SearchIndex - 1));
		Else
			SettingsDirectory.Path = GeneratePathWithSeparator(DataBuffer);
		EndIf;
		SettingsDirectory.Exist = True;
		SettingsDirectory.ErrorDescription = "";
	Else
		SettingsDirectory.Path = GeneratePathWithSeparator(SettingsConfigurationFile.Path);
		SettingsDirectory.Exist = False;
		SettingsDirectory.ErrorDescription = NStr("ru = 'Не найдена секция ConfLocation в файле'; en = 'The ConfLocation section is not found in the file'; pl = 'The ConfLocation section is not found in the file';de = 'The ConfLocation section is not found in the file';ro = 'The ConfLocation section is not found in the file';tr = 'The ConfLocation section is not found in the file'; es_ES = 'The ConfLocation section is not found in the file'", Common.DefaultLanguageCode()) + " " + SettingsConfigurationFile.FullName;
	EndIf;
		
	Return SettingsDirectory;
EndFunction

#EndRegion

#Region WorkWithDumps

Function DumpDetails(Val FileName)
	FileName = StrReplace(FileName, "_", Chars.LF);
	
	DumpStructure = New Structure;
	If StrLineCount(FileName) >= 3  Then
		DumpStructure.Insert("Process", StrGetLine(FileName, 1));
		DumpStructure.Insert("PlatformVersion", StrGetLine(FileName, 2));
		DumpStructure.Insert("BeforeAfter", StrGetLine(FileName, 3));
	Else
		SysInfo = New SystemInfo;
		DumpStructure.Insert("Process", "userdump");
		DumpStructure.Insert("PlatformVersion", SysInfo.AppVersion);
		DumpStructure.Insert("BeforeAfter", "ffffffff");
	EndIf;
	
	Return DumpStructure;
EndFunction

Function PlatformVersionToNumber(Version) Export
	PlatformVersion = StrReplace(Version, ".", Chars.LF);
	PlatformVersionNumber = Number(Left(StrGetLine(PlatformVersion, 1) + "000000", 6)
		+ Left(StrGetLine(PlatformVersion, 2) + "000000", 6)
		+ Left(StrGetLine(PlatformVersion, 3) + "000000", 6)
		+ Left(StrGetLine(PlatformVersion, 4) + "000000", 6));
	
	Return PlatformVersionNumber;
EndFunction

#EndRegion

#Region WorkWithSystemInformation
Function GetSystemInformation()
	SysInfo = New SystemInfo;
	
	Result = New Structure;
	Result.Insert("ComputerName", Common.CheckSumString(ComputerName()));
	Result.Insert("OSVersion", String(SysInfo.OSVersion));
	Result.Insert("AppVersion", String(SysInfo.AppVersion));
	Result.Insert("ClientID", String(SysInfo.ClientID));
	Result.Insert("RAM", String(SysInfo.RAM));
	Result.Insert("Processor", String(SysInfo.Processor));
	Result.Insert("PlatformType", String(SysInfo.PlatformType));
	Result.Insert("CurrentLanguage", String(CurrentLanguage()));
	Result.Insert("CurrentLocaleCode", String(CurrentLocaleCode()));
	Result.Insert("CurrentSystemLanguage", String(CurrentSystemLanguage()));
	Result.Insert("CurrentRunMode", String(CurrentRunMode()));
	Result.Insert("SessionTimeZone", String(SessionTimeZone()));
	
	Return Result;
EndFunction

Function SubsystemsVersions()
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	SubsystemsVersions.SubsystemName AS SubsystemName,
	|	SubsystemsVersions.Version AS Version
	|FROM
	|	InformationRegister.SubsystemsVersions AS SubsystemsVersions";
	
	Result = Query.Execute();
	
	Subsystems = New Structure;
	Selection = Result.Select();
	While Selection.Next() Do
		Subsystems.Insert(Selection.SubsystemName, Selection.Version);
	EndDo;
	
	Return Subsystems;
EndFunction

#EndRegion

#Region WorkWithConfigurationExtensions

Function DataOnUsedExtensions()

	ExtensionStructure = New Structure;
	                   	
	ExtensionArray = ConfigurationExtensions.Get();
	ExtensionsUsed = ExtensionArray.Count()>0;
	ExtensionStructure.Insert("ExtensionsUsage", ExtensionsUsed);
	
	If Not ExtensionsUsed Then
		Return ExtensionStructure;
	EndIf;
	
	ExtensionsDetailsArray = New Array;	
	For Each Extension In ExtensionArray Do
		ExtensionDetails = New Structure("Name, Version, Purpose, SafeMode, UnsafeOperationProtection, Synonym");
		FillPropertyValues(ExtensionDetails, Extension);
		ExtensionDetails.Insert("UnsafeOperationProtection", ?(ExtensionDetails.UnsafeActionProtection = Undefined, False, ExtensionDetails.UnsafeActionProtection.UnsafeOperationWarnings));
		ExtensionDetails.Insert("Purpose", String(ExtensionDetails.Purpose));		
		ExtensionsDetailsArray.Add(ExtensionDetails);
	EndDo;
	
	ExtensionStructure.Insert("ExtensionsDetails", ExtensionsDetailsArray);	
	
	ExtensionsMetadata = New Map;
	MetadataDetails = MetadataDetails();
	For Each StrWrite In MetadataDetails Do
		AddExtensionsInformation(StrWrite.Key, StrWrite.Value, ExtensionsMetadata);
	EndDo;
	
	ExtensionStructure.Insert("ExtensionsMetadata", ExtensionsMetadata);
	
	Return ExtensionStructure;
	
EndFunction

Procedure AddExtensionsInformation(ObjectClass, ObjectArchitecture, ExtensionsMetadata)
	For Each MetadataObject In Metadata[ObjectClass] Do
		// First, iterate the subordinate ones.
		For Each StructureItem In ObjectArchitecture Do
			If StructureItem.Value = "Recursively" Then
				AddExtensionsInformationRecursively(MetadataObject, StructureItem.Key, ObjectArchitecture, ExtensionsMetadata);
			EndIf;
			For Each SubordinateObject In MetadataObject[StructureItem.Key] Do
				ObjectExtension = SubordinateObject.ConfigurationExtension();
				If ObjectExtension = Undefined Then
					Continue;
				EndIf;		
				ExtensionsMetadata.Insert(SubordinateObject.FullName(), ObjectExtension.Name);
			EndDo;
		EndDo;
		
		ObjectExtension = MetadataObject.ConfigurationExtension();
		If ObjectExtension = Undefined Then
			If MetadataObject.ChangedByConfigurationExtensions() Then
				ExtensionsMetadata.Insert(MetadataObject.FullName(), True);		
			EndIf;
			Continue;
		EndIf;		
		ExtensionsMetadata.Insert(MetadataObject.FullName(), ObjectExtension.Name);
	EndDo;

EndProcedure

Procedure AddExtensionsInformationRecursively(Object, RecursiveAttributeName, ObjectArchitecture, ExtensionsMetadata)
	For Each RecursiveObject In Object[RecursiveAttributeName] Do
		For Each StructureItem In ObjectArchitecture Do
			If StructureItem.Value = "Recursively" Then
				AddExtensionsInformationRecursively(RecursiveObject, StructureItem.Key, ObjectArchitecture, ExtensionsMetadata);
			EndIf;
			For Each SubordinateObject In RecursiveObject[StructureItem.Key] Do
				ObjectExtension = SubordinateObject.ConfigurationExtension();
				If ObjectExtension = Undefined Then
					Continue;
				EndIf;		
				ExtensionsMetadata.Insert(SubordinateObject.FullName(), ObjectExtension.Name);
			EndDo;
		EndDo;
		
		ObjectExtension = RecursiveObject.ConfigurationExtension();
		If ObjectExtension = Undefined Then
			Continue;
		EndIf;		
		ExtensionsMetadata.Insert(RecursiveObject.FullName(), ObjectExtension.Name);	
	EndDo;
EndProcedure
 
Function MetadataDetails()
	MetadataDetails = New Map;
	MetadataDetails.Insert("Subsystems", New Structure("Subsystems", "Recursively"));
	MetadataDetails.Insert("CommonModules", New Structure);
	MetadataDetails.Insert("SessionParameters", New Structure);
	MetadataDetails.Insert("CommonAttributes", New Structure);
	MetadataDetails.Insert("CommonAttributes", New Structure);
	MetadataDetails.Insert("ExchangePlans", New Structure("Attributes, TabularSections, Forms, Commands, Templates"));
	MetadataDetails.Insert("FilterCriteria", New Structure("Forms, Commands"));
	MetadataDetails.Insert("EventSubscriptions", New Structure);
	MetadataDetails.Insert("ScheduledJobs", New Structure);
	MetadataDetails.Insert("FunctionalOptions", New Structure);
	MetadataDetails.Insert("FunctionalOptionsParameters", New Structure);
	MetadataDetails.Insert("DefinedTypes", New Structure);
	MetadataDetails.Insert("SettingsStorages", New Structure("Forms, Templates"));
	MetadataDetails.Insert("CommonForms", New Structure);
	MetadataDetails.Insert("CommonCommands", New Structure);
	MetadataDetails.Insert("CommandGroups", New Structure);
	MetadataDetails.Insert("CommonTemplates", New Structure);
	MetadataDetails.Insert("CommonPictures", New Structure);
	MetadataDetails.Insert("XDTOPackages", New Structure);
	MetadataDetails.Insert("WebServices", New Structure);
	MetadataDetails.Insert("HTTPServices", New Structure);
	MetadataDetails.Insert("WSReferences", New Structure);
	MetadataDetails.Insert("StyleItems", New Structure);
	MetadataDetails.Insert("Languages", New Structure);	
	MetadataDetails.Insert("Constants", New Structure);
	MetadataDetails.Insert("Catalogs", New Structure("Attributes, TabularSections, Forms, Commands, Templates"));
	MetadataDetails.Insert("Documents", New Structure("Attributes, TabularSections, Forms, Commands, Templates"));
	MetadataDetails.Insert("DocumentJournals", New Structure("Columns, Forms, Commands, Templates"));
	MetadataDetails.Insert("Enums", New Structure("EnumValues, Forms, Commands, Templates"));
	MetadataDetails.Insert("Reports", New Structure("Attributes, TabularSections, Forms, Commands, Templates"));
	MetadataDetails.Insert("DataProcessors", New Structure("Attributes, TabularSections, Forms, Commands, Templates"));
	MetadataDetails.Insert("ChartsOfCharacteristicTypes", New Structure("Attributes, TabularSections, Forms, Commands, Templates"));
	MetadataDetails.Insert("ChartsOfAccounts", New Structure("Attributes, TabularSections, Forms, Commands, Templates"));
	MetadataDetails.Insert("ChartsOfCalculationTypes", New Structure("Attributes, TabularSections, Forms, Commands, Templates"));
	MetadataDetails.Insert("InformationRegisters", New Structure("Dimensions, Resources, Attributes, Forms, Commands, Templates"));
	MetadataDetails.Insert("AccumulationRegisters", New Structure("Dimensions, Resources, Attributes, Forms, Commands, Templates"));
	MetadataDetails.Insert("AccountingRegisters", New Structure("Dimensions, Resources, Attributes, Forms, Commands, Templates"));
	MetadataDetails.Insert("CalculationRegisters", New Structure("Dimensions, Resources, Attributes, Forms, Commands, Templates"));
	MetadataDetails.Insert("BusinessProcesses", New Structure("Attributes, TabularSections, Forms, Commands, Templates"));
	MetadataDetails.Insert("Tasks", New Structure("AddressingAttributes, Attributes, TabularSections, Forms, Commands, Templates"));
	
	Return MetadataDetails;
EndFunction

#EndRegion

#Region WorkWithAccessRightsSubsystem

Function DataOnRolesUsage()
	DataOnRolesUsage = New Structure;
	
	// Getting data on roles usage.	
	Query = New Query(RolesUsageQueryText());
	Query.SetParameter("EmptyUID", CommonClientServer.BlankUUID());
	Query.SetParameter("CurrentDate", BegOfDay(CurrentSessionDate()));
	ResultPackage = Query.ExecuteBatch();
	
	// Generating structure: roles by access group profiles.
	IndexColumns = New Map;
	IndexColumns.Insert("ProfileUID", New Map);
	IndexColumns.Insert("RoleName", New Map);	
	AdditionalParameters = New Map;
	AdditionalParameters.Insert("IndexColumns", IndexColumns);
	
	ProfileRoles = ResultPackage[8].Unload();
	ProfileRoles.Columns.Add("ProfileUID", New TypeDescription("String"));
	For Each Row In ProfileRoles Do
		Row.ProfileUID = String(Row.Profile.UUID());
	EndDo;
	ProfileRoles.Columns.Delete("Profile");
	
	RolesOfProfiles = GenerateJSONStructure("RolesOfProfiles", ProfileRoles, AdditionalParameters);
	DataOnRolesUsage.Insert("RolesOfProfiles", RolesOfProfiles["RolesOfProfiles"]);
	
	// Generating structure: statistics on profiles usage.
	IndexColumns = New Map;
	IndexColumns.Insert("ProfileUID", New Map);	
	IndexColumns.Insert("Description", New Map);
	IndexColumns.Insert("SuppliedDataID", New Map);
	AdditionalParameters = New Map;
	AdditionalParameters.Insert("IndexColumns", IndexColumns);
	
	ProfilesData = ResultPackage[7].Unload();
	ProfilesData.Columns.Add("ProfileUID", New TypeDescription("String"));
	ProfilesData.Columns.Add("SuppliedDataIDRow", New TypeDescription("String"));
	For Each Row In ProfilesData Do
		Row.SuppliedDataIDRow = String(Row.SuppliedDataID);
		Row.ProfileUID = String(Row.Profile.UUID());
	EndDo;
	ProfilesData.Columns.Delete("SuppliedDataID");
	ProfilesData.Columns.SuppliedDataIDRow.Name = "SuppliedDataID";
	ProfilesData.Columns.Delete("Profile");
	
	Profiles = GenerateJSONStructure("Profiles", ProfilesData, AdditionalParameters);
	DataOnRolesUsage.Insert("Profiles", Profiles["Profiles"]);
	
	Return DataOnRolesUsage;
EndFunction

Function RolesUsageQueryText()
	
	Return
	"SELECT
	|	UserGroupCompositions.UsersGroup AS UsersGroup,
	|	UsersInfo.User AS User,
	|	CASE
	|		WHEN DATEDIFF(UsersInfo.LastActivityDate, &CurrentDate, DAY) <= 7
	|			THEN 1
	|		ELSE 0
	|	END AS ActiveWeekly,
	|	CASE
	|		WHEN DATEDIFF(UsersInfo.LastActivityDate, &CurrentDate, DAY) <= 30
	|			THEN 1
	|		ELSE 0
	|	END AS ActiveMonthly
	|INTO TTGroupListsAndActivity
	|FROM
	|	InformationRegister.UserGroupCompositions AS UserGroupCompositions
	|		LEFT JOIN InformationRegister.UsersInfo AS UsersInfo
	|		ON UserGroupCompositions.User = UsersInfo.User
	|WHERE
	|	UserGroupCompositions.Used
	|	AND NOT UserGroupCompositions.User.IBUserID = &EmptyUID
	|
	|INDEX BY
	|	UsersGroup,
	|	User
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	AccessGroupProfiles.Ref AS Profile,
	|	AccessGroupProfiles.SuppliedDataID AS SuppliedDataID,
	|	AccessGroupProfiles.SuppliedProfileChanged AS SuppliedProfileChanged,
	|	AccessGroupProfiles.Description AS Description,
	|	AccessGroupsUsers.Ref AS AccessGroup,
	|	AccessGroupsUsers.Ref.User = VALUE(Catalog.Users.EmptyRef)
	|		OR AccessGroupsUsers.Ref.User = VALUE(Catalog.ExternalUsers.EmptyRef)
	|		OR AccessGroupsUsers.Ref.User = UNDEFINED AS CommonAccessGroup,
	|	AccessGroupsUsers.User AS TabularSectionUser,
	|	UserGroupCompositions.User AS InformationRegisterUser,
	|	UserGroupCompositions.ActiveWeekly AS ActiveWeekly,
	|	UserGroupCompositions.ActiveMonthly AS ActiveMonthly
	|INTO TTProfileData
	|FROM
	|	Catalog.AccessGroups.Users AS AccessGroupsUsers
	|		INNER JOIN TTGroupListsAndActivity AS UserGroupCompositions
	|		ON AccessGroupsUsers.User = UserGroupCompositions.UsersGroup
	|		INNER JOIN Catalog.AccessGroupProfiles AS AccessGroupProfiles
	|		ON (AccessGroupProfiles.Ref = AccessGroupsUsers.Ref.Profile)
	|			AND (NOT AccessGroupsUsers.Ref.Profile.DeletionMark)
	|WHERE
	|	NOT AccessGroupsUsers.Ref.Profile.DeletionMark
	|
	|GROUP BY
	|	AccessGroupProfiles.Ref,
	|	AccessGroupProfiles.Description,
	|	AccessGroupsUsers.User,
	|	UserGroupCompositions.User,
	|	UserGroupCompositions.ActiveWeekly,
	|	UserGroupCompositions.ActiveMonthly,
	|	AccessGroupsUsers.Ref,
	|	AccessGroupsUsers.Ref.User = VALUE(Catalog.Users.EmptyRef)
	|		OR AccessGroupsUsers.Ref.User = VALUE(Catalog.ExternalUsers.EmptyRef)
	|		OR AccessGroupsUsers.Ref.User = UNDEFINED,
	|	AccessGroupProfiles.SuppliedDataID,
	|	AccessGroupProfiles.SuppliedProfileChanged
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	TTProfileData.Profile AS Profile,
	|	TTProfileData.Description AS Description,
	|	TTProfileData.SuppliedDataID AS SuppliedDataID,
	|	TTProfileData.SuppliedProfileChanged AS SuppliedProfileChanged
	|INTO Profiles
	|FROM
	|	TTProfileData AS TTProfileData
	|
	|INDEX BY
	|	Profile
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Profiles.Profile AS Profile,
	|	SUM(CASE
	|			WHEN NOT AccessGroupProfilesAccessKinds.AccessKind IS NULL
	|				THEN 1
	|			ELSE 0
	|		END) AS TotalAccessKinds,
	|	SUM(CASE
	|			WHEN ISNULL(AccessGroupProfilesAccessKinds.PresetAccessKind, FALSE)
	|				THEN 1
	|			ELSE 0
	|		END) AS PresetAccessKinds
	|INTO AccessKinds
	|FROM
	|	Profiles AS Profiles
	|		LEFT JOIN Catalog.AccessGroupProfiles.AccessKinds AS AccessGroupProfilesAccessKinds
	|		ON Profiles.Profile = AccessGroupProfilesAccessKinds.Ref
	|
	|GROUP BY
	|	Profiles.Profile
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Nested.Profile AS Profile,
	|	COUNT(DISTINCT Nested.AccessGroup) AS AccessGroup,
	|	SUM(CASE
	|			WHEN NOT Nested.CommonAccessGroup
	|				THEN 1
	|			ELSE 0
	|		END) AS PersonalGroup
	|INTO AccessGroups
	|FROM
	|	(SELECT
	|		TTProfileData.Profile AS Profile,
	|		TTProfileData.AccessGroup AS AccessGroup,
	|		TTProfileData.CommonAccessGroup AS CommonAccessGroup
	|	FROM
	|		TTProfileData AS TTProfileData
	|	
	|	GROUP BY
	|		TTProfileData.Profile,
	|		TTProfileData.AccessGroup,
	|		TTProfileData.CommonAccessGroup) AS Nested
	|
	|GROUP BY
	|	Nested.Profile
	|
	|INDEX BY
	|	Profile
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Nested.Profile AS Profile,
	|	SUM(CASE
	|			WHEN Nested.TabularSectionUser REFS Catalog.UserGroups
	|				THEN 1
	|			ELSE 0
	|		END) AS UserGroups,
	|	SUM(CASE
	|			WHEN Nested.TabularSectionUser REFS Catalog.ExternalUsersGroups
	|				THEN 1
	|			ELSE 0
	|		END) AS ExternalUserGroups
	|INTO UserGroups
	|FROM
	|	(SELECT
	|		TTProfileData.Profile AS Profile,
	|		TTProfileData.TabularSectionUser AS TabularSectionUser
	|	FROM
	|		TTProfileData AS TTProfileData
	|	
	|	GROUP BY
	|		TTProfileData.Profile,
	|		TTProfileData.TabularSectionUser) AS Nested
	|
	|GROUP BY
	|	Nested.Profile
	|
	|INDEX BY
	|	Profile
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Nested.Profile AS Profile,
	|	SUM(CASE
	|			WHEN Nested.InformationRegisterUser REFS Catalog.Users
	|				THEN 1
	|			ELSE 0
	|		END) AS Users,
	|	SUM(CASE
	|			WHEN Nested.InformationRegisterUser REFS Catalog.ExternalUsers
	|				THEN 1
	|			ELSE 0
	|		END) AS ExternalUsers,
	|	SUM(Nested.ActiveWeekly) AS ActiveWeekly,
	|	SUM(Nested.ActiveMonthly) AS ActiveMonthly
	|INTO ProfileUsers
	|FROM
	|	(SELECT
	|		TTProfileData.Profile AS Profile,
	|		TTProfileData.InformationRegisterUser AS InformationRegisterUser,
	|		SUM(TTProfileData.ActiveWeekly) AS ActiveWeekly,
	|		SUM(TTProfileData.ActiveMonthly) AS ActiveMonthly
	|	FROM
	|		TTProfileData AS TTProfileData
	|	
	|	GROUP BY
	|		TTProfileData.Profile,
	|		TTProfileData.InformationRegisterUser) AS Nested
	|
	|GROUP BY
	|	Nested.Profile
	|
	|INDEX BY
	|	Profile
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Profiles.Profile AS Profile,
	|	Profiles.Description AS Description,
	|	Profiles.SuppliedDataID AS SuppliedDataID,
	|	Profiles.SuppliedProfileChanged AS SuppliedProfileChanged,
	|	ISNULL(AccessGroups.AccessGroup, 0) AS AccessGroup,
	|	ISNULL(AccessGroups.PersonalGroup, 0) AS PersonalGroup,
	|	ISNULL(UserGroups.UserGroups, 0) AS UserGroups,
	|	ISNULL(UserGroups.ExternalUserGroups, 0) AS ExternalUserGroups,
	|	ISNULL(ProfileUsers.Users, 0) AS Users,
	|	ISNULL(ProfileUsers.ExternalUsers, 0) AS ExternalUsers,
	|	ISNULL(ProfileUsers.ActiveWeekly, 0) AS ActiveWeekly,
	|	ISNULL(ProfileUsers.ActiveMonthly, 0) AS ActiveMonthly,
	|	ISNULL(AccessKinds.TotalAccessKinds, 0) AS TotalAccessKinds,
	|	ISNULL(AccessKinds.PresetAccessKinds, 0) AS PresetAccessKinds
	|FROM
	|	Profiles AS Profiles
	|		LEFT JOIN ProfileUsers AS ProfileUsers
	|		ON Profiles.Profile = ProfileUsers.Profile
	|		LEFT JOIN UserGroups AS UserGroups
	|		ON Profiles.Profile = UserGroups.Profile
	|		LEFT JOIN AccessGroups AS AccessGroups
	|		ON Profiles.Profile = AccessGroups.Profile
	|		LEFT JOIN AccessKinds AS AccessKinds
	|		ON Profiles.Profile = AccessKinds.Profile
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	Profiles.Profile AS Profile,
	|	ISNULL(AccessGroupProfilesRoles.Role.Name, """") AS RoleName
	|FROM
	|	Profiles AS Profiles
	|		LEFT JOIN Catalog.AccessGroupProfiles.Roles AS AccessGroupProfilesRoles
	|		ON Profiles.Profile = AccessGroupProfilesRoles.Ref
	|			AND (Profiles.SuppliedDataID = &EmptyUID
	|				OR Profiles.SuppliedProfileChanged)
	|
	|ORDER BY
	|	Profile";
	
EndFunction


#EndRegion


#Region WorkInSeparationByDataAreasMode

Function SeparationByDataAreasEnabled() Export
	
	If Common.SubsystemExists("StandardSubsystems.SaaS") Then
		SaaSCommonModule = Common.CommonModule("SaaS");
		SeparationByDataAreasEnabled = SaaSCommonModule.DataSeparationEnabled();
	Else
		SeparationByDataAreasEnabled = False;
	EndIf;
	
	Return SeparationByDataAreasEnabled;
	
EndFunction

#EndRegion

#Region WorkInDIBMode

Function IsMasterNode()
	SetPrivilegedMode(True);
	
	Return NOT ExchangePlans.MasterNode() <> Undefined;
EndFunction

#EndRegion

#Region CommonFunctions

Function EventLogEventMonitoringCenterDumpDeletion()
	Return NStr("ru = 'Центр мониторинга.Удаление дампа'; en = 'Monitoring center.Removing the dump'; pl = 'Monitoring center.Removing the dump';de = 'Monitoring center.Removing the dump';ro = 'Monitoring center.Removing the dump';tr = 'Monitoring center.Removing the dump'; es_ES = 'Monitoring center.Removing the dump'", Common.DefaultLanguageCode());
EndFunction

Function EventLogEventMonitoringCenterParseStatisticsOperationsBuffer()
	Return NStr("ru = 'Центр мониторинга.Разобрать буфер операций статистики'; en = 'Monitoring center.Parse the buffer of statistics operations'; pl = 'Monitoring center.Parse the buffer of statistics operations';de = 'Monitoring center.Parse the buffer of statistics operations';ro = 'Monitoring center.Parse the buffer of statistics operations';tr = 'Monitoring center.Parse the buffer of statistics operations'; es_ES = 'Monitoring center.Parse the buffer of statistics operations'", Common.DefaultLanguageCode());
EndFunction
#EndRegion

#Region ClientInformation

Procedure WriteClientScreensStatistics(Parameters)
	
	Screens = Parameters["ClientInformation"]["CustomerScreens"]; 
	UserHash = Parameters["ClientInformation"]["ClientParameters"]["UserHash"];
	
	For Each CurScreen In Screens Do
		
		StatisticsOperationName = "ClientStatistics.SystemInformation.MonitorResolution." + CurScreen;
		MonitoringCenter.WriteBusinessStatisticsOperationDay(StatisticsOperationName, UserHash, 1);
		
		StatisticsOperationName = StatisticsOperationName + "." + Parameters["ClientInformation"]["SystemInformation"]["UserAgentInformation"]; 
		MonitoringCenter.WriteBusinessStatisticsOperationDay(StatisticsOperationName, UserHash, 1);
		
	EndDo;
	
	MonitorCountString = Format(Screens.Count(), "NG=0");
	MonitoringCenter.WriteBusinessStatisticsOperationDay("ClientStatistics.SystemInformation.MonitorCount." + MonitorCountString, UserHash, 1);
	
EndProcedure

Procedure WriteSystemInformation(Parameters)
	
	UserHash = Parameters["ClientInformation"]["ClientParameters"]["UserHash"];
	
	For Each CurSystemInfo In Parameters["ClientInformation"]["SystemInformation"] Do
		StatisticsOperationName = "ClientStatistics.SystemInformation." + CurSystemInfo.Key + "." + CurSystemInfo.Value;
		MonitoringCenter.WriteBusinessStatisticsOperationDay(StatisticsOperationName, UserHash, 1);
	EndDo;
	
EndProcedure

Procedure WriteClientInformation(Parameters)
	
	UserHash = Parameters["ClientInformation"]["ClientParameters"]["UserHash"];
	
	WriteUserActivity(UserHash);
	
	StatisticsOperationName = "ClientStatistics.ActiveWindows";
	Value =  Parameters["ClientInformation"]["ActiveWindows"];
	MonitoringCenter.WriteBusinessStatisticsOperationHour(StatisticsOperationName, UserHash, Value);
	
EndProcedure

Procedure WriteUserActivity(UserHash)
	StatisticsOperationName = "ClientStatistics.ActiveUsers";
	MonitoringCenter.WriteBusinessStatisticsOperationHour(StatisticsOperationName, UserHash, 1);
EndProcedure

Procedure WriteDataFromClient(Parameters)
	
	CurDate = CurrentUniversalDate();
	
	Measurements = Parameters["Measurements"];
	For Each MeasurementsOfType In Measurements Do
		
		RecordPeriodType = MeasurementsOfType.Key;
		
		If RecordPeriodType = 0 Then
			WriteDataFromClientExact(MeasurementsOfType.Value);
		Else
			WriteDataFromClientUnique(MeasurementsOfType.Value, RecordPeriodType, CurDate);
		EndIf;
		
	EndDo;
	
EndProcedure

Procedure WriteDataFromClientExact(Measurements)
	
	InformationRegisters.StatisticsOperationsClipboard.WriteBusinessStatisticsOperations(Measurements);
			
EndProcedure

Procedure WriteDataFromClientUnique(Measurements, RecordPeriodType, CurDate)
	
	If RecordPeriodType = 1 Then
		RecordPeriod = BegOfHour(CurDate);
	ElsIf RecordPeriodType = 2 Then
		RecordPeriod = BegOfDay(CurDate);
	EndIf;
	
	WriteParameters = New Structure("OperationName, UniqueKey, Value, Replace, RecordType, RecordPeriod");
	For Each CurMeasurement In Measurements Do
		
		WriteParameters.OperationName = CurMeasurement.Value.StatisticsOperation;
		WriteParameters.UniqueKey = CurMeasurement.Value.Key;
		WriteParameters.Value = CurMeasurement.Value.Value;
		WriteParameters.Replace = CurMeasurement.Value.Replace;
		WriteParameters.RecordType = RecordPeriodType;
		WriteParameters.RecordPeriod = RecordPeriod;
		
		WriteBusinessStatisticsOperationInternal(WriteParameters);	
		
	EndDo;
	
EndProcedure

#EndRegion

Procedure InitialFilling() Export
	
	If SeparationByDataAreasEnabled() Then
		Return;
	EndIf;
	
	CurDate = CurrentUniversalDate();
	
	DeleteMonitoringCenterParameters();
	MonitoringCenterParameters = GetDefaultParameters();
	
	If Common.FileInfobase() Then
		MonitoringCenterParameters.BusinessStatisticsSnapshotPeriod = 3600;
	EndIf;
	
	MonitoringCenterParameters.DumpRegistrationNextCreation = CurDate + MonitoringCenterParameters.DumpRegistrationCreationPeriod;
	MonitoringCenterParameters.BusinessStatisticsNextSnapshot = CurDate + MonitoringCenterParameters.BusinessStatisticsSnapshotPeriod;
	MonitoringCenterParameters.ConfigurationStatisticsNextGeneration = CurDate + MonitoringCenterParameters.ConfigurationStatisticsGenerationPeriod;
	
	RNG = New RandomNumberGenerator(CurrentUniversalDateInMilliseconds());
	SendingDelta = RNG.RandomNumber(0, 86400);
	MonitoringCenterParameters.SendDataNextGeneration = CurDate + SendingDelta;
	
	MonitoringCenterParameters.AggregationPeriodMinor = 600;
	MonitoringCenterParameters.AggregationPeriod = 3600;
	MonitoringCenterParameters.DeletionPeriod = 86400;
	
	If StandardSubsystemsServer.IsBaseConfigurationVersion() Then
		MonitoringCenterParameters.EnableMonitoringCenter = True;
	EndIf;
	
	SetMonitoringCenterParameters(MonitoringCenterParameters);
	
	If StandardSubsystemsServer.IsBaseConfigurationVersion() Then
		ScheduledJob = GetScheduledJob("StatisticsDataCollectionAndSending", True);
		SetDefaultSchedule(ScheduledJob);
	EndIf;
	
EndProcedure

Procedure AddInfobaseIDPermanent() Export
	
	MonitoringCenterParameters = GetMonitoringCenterParameters();
	MonitoringCenterParameters.Insert("InfobaseIDPermanent", MonitoringCenterParameters.InfoBaseID);
	SetMonitoringCenterParameters(MonitoringCenterParameters);
	
EndProcedure

Procedure EnableSendingInfo(Parameters) Export
	
	MonitoringCenterParameters = GetMonitoringCenterParameters(New Structure("EnableMonitoringCenter, ApplicationInformationProcessingCenter"));
	// If it is already enabled, do nothing.
	If MonitoringCenterParameters.EnableMonitoringCenter OR MonitoringCenterParameters.ApplicationInformationProcessingCenter Then
		Parameters.ProcessingCompleted = True;
		Return;
	EndIf;
	MonitoringCenterParameters = New Structure("EnableMonitoringCenter, ApplicationInformationProcessingCenter", True, False);
	SetMonitoringCenterParameters(MonitoringCenterParameters);
	ScheduledJob = GetScheduledJob("StatisticsDataCollectionAndSending", True);
	SetDefaultSchedule(ScheduledJob);
	
	Parameters.ProcessingCompleted = True;
EndProcedure

Procedure EnableSendingInfoFilling(Parameters) Export
	
EndProcedure

Procedure WriteBusinessStatisticsOperationInternal(WriteParameters) Export
	
	RecordPeriod = WriteParameters.RecordPeriod;
	RecordPeriodType = WriteParameters.RecordType;
	varKey = WriteParameters.UniqueKey;
	StatisticsOperation = MonitoringCenterCached.GetStatisticsOperationRef(WriteParameters.OperationName);
	Value = WriteParameters.Value;
	Replace = WriteParameters.Replace;
	
	InformationRegisters.StatisticsMeasurements.WriteBusinessStatisticsOperation(RecordPeriod, RecordPeriodType, varKey, StatisticsOperation, Value, Replace);
	
EndProcedure

Procedure PerformActionsOnDetectCopy()
	
	MonitoringCenterParameters = GetMonitoringCenterParameters();
	MonitoringCenterParameters.InfoBaseID = New UUID();
	MonitoringCenterParameters.LastPackageNumber = 0;
	
	SetMonitoringCenterParameters(MonitoringCenterParameters);
	
	InformationRegisters.PackagesToSend.Clear();
	
EndProcedure

Procedure SetSessionSeparation(Usage, DataArea = Undefined)
	
	If Common.SubsystemExists("StandardSubsystems.SaaS") Then
		ModuleSaaS = Common.CommonModule("SaaS");
		ModuleSaaS.SetSessionSeparation(Usage, DataArea);
	EndIf;
	
EndProcedure

Function NotificationOfDumpsParameters()
	ParametersToGet = New Structure;
	ParametersToGet.Insert("SendDumpsFiles");
	ParametersToGet.Insert("BasicChecksPassed");
	ParametersToGet.Insert("DumpInstances");
	ParametersToGet.Insert("DumpOption");
	ParametersToGet.Insert("DumpType");
	ParametersToGet.Insert("RequestConfirmationBeforeSending");
	ParametersToGet.Insert("DumpsInformation");
	
	MonitoringCenterParameters = GetMonitoringCenterParameters(ParametersToGet);
	
	RequestForGettingDumps = MonitoringCenterParameters.SendDumpsFiles = 2
								AND MonitoringCenterParameters.BasicChecksPassed;
									
	HasDumps = MonitoringCenterParameters.Property("DumpInstances") AND MonitoringCenterParameters.DumpInstances.Count();
	SendingRequest = MonitoringCenterParameters.SendDumpsFiles = 1
						AND NOT IsBlankString(MonitoringCenterParameters.DumpOption)
						AND HasDumps
						AND MonitoringCenterParameters.RequestConfirmationBeforeSending
						AND MonitoringCenterParameters.DumpType = "3"
						AND Not IsBlankString(MonitoringCenterParameters.DumpsInformation)
						AND MonitoringCenterParameters.BasicChecksPassed;
						
	NotificationOfDumpsParameters = New Structure;
	NotificationOfDumpsParameters.Insert("RequestForGettingDumps", RequestForGettingDumps);
	NotificationOfDumpsParameters.Insert("SendingRequest", SendingRequest);
	NotificationOfDumpsParameters.Insert("DumpsInformation", MonitoringCenterParameters.DumpsInformation);
	
	Return NotificationOfDumpsParameters;
EndFunction

#Region DumpsCollectionAndSending

// In client/server mode, the function is called by scheduled job DumpsCollectionAndSending.
// From it, two background jobs are started: DumpsCollection and DumpsSending.
//
Procedure CollectAndSendDumps(FromClientAtServer = False, JobID = "") Export
	
	Common.OnStartExecuteScheduledJob(Metadata.ScheduledJobs.ErrorReportCollectionAndSending);
	
	DumpsCollectionAndSendingParameters = GetMonitoringCenterParameters();
	DumpOption = DumpsCollectionAndSendingParameters.DumpOption;
	ComputerName = ComputerName();
	DumpTypeChanged = False;
	
	// Check if dump collection is allowed.
	If DumpsCollectionAndSendingParameters.SendDumpsFiles = 0 Then
		SetPrivilegedMode(True);
		SetMonitoringCenterParameter("SendingResult", NStr("ru = 'Пользователь отказал в предоставлении дампов.'; en = 'User refused to submit dumps.'; pl = 'User refused to submit dumps.';de = 'User refused to submit dumps.';ro = 'User refused to submit dumps.';tr = 'User refused to submit dumps.'; es_ES = 'User refused to submit dumps.'"));
		SetPrivilegedMode(False);
		StopFullDumpsCollection();
		Return;
	EndIf;
	
	// Check if collection of full dumps was requested.
	If IsBlankString(DumpOption) Then
		Return;
	EndIf;
	
	// Check if it is a time to disconnect.
	If CurrentSessionDate() >= DumpsCollectionAndSendingParameters.DumpCollectingEnd Then
		SetPrivilegedMode(True);
		SetMonitoringCenterParameter("SendingResult", NStr("ru = 'Сбор дампов прекращен по таймауту.'; en = 'Dump collection timed out.'; pl = 'Dump collection timed out.';de = 'Dump collection timed out.';ro = 'Dump collection timed out.';tr = 'Dump collection timed out.'; es_ES = 'Dump collection timed out.'"));	
		SetPrivilegedMode(False);
		StopFullDumpsCollection();
		Return;
	EndIf;
	
	// Collect full dumps only in the master node.
	If NOT IsMasterNode() Then 
		Return;
	EndIf;
	
	DumpRequirement = DumpIsRequired(DumpOption, DumpOption);
	// If the dump is not required, disable dumps collection.
	If NOT DumpRequirement.Required Then
		StopFullDumpsCollection();
		Return;
	Else  		
		// If the type of a dump being collected does not match the required one, change the dump type.
		// It is necessary to collect mini or full dumps, and the user agreed it.
		If DumpRequirement.DumpType <> DumpsCollectionAndSendingParameters.DumpType 
			AND (DumpRequirement.DumpType = "0" 
				OR DumpsCollectionAndSendingParameters.SendDumpsFiles = 1 
				AND DumpRequirement.DumpType = "3") Then			
			SetPrivilegedMode(True);
			SetMonitoringCenterParameter("DumpType", DumpRequirement.DumpType);
			DumpsCollectionAndSendingParameters.DumpType = DumpRequirement.DumpType;
			SetPrivilegedMode(False);
			DumpTypeChanged = True;
		EndIf;   		
	EndIf;
	
	// Check if logcfg can be changed if required and get dumps storage directory.
	// At the same time, check if dumps collection is enabled.
	DumpType = DumpsCollectionAndSendingParameters.DumpType;
	DumpsDirectory = GetDumpsDirectory(DumpType);
	DumpsCollectionAndSendingParameters.Insert("DumpsDirectory", DumpsDirectory.Path);
	If DumpsDirectory.Path = Undefined Then
		SetPrivilegedMode(True);
		SetMonitoringCenterParameter("SendingResult", DumpsDirectory.ErrorDescription);
		SetPrivilegedMode(False);
		StopFullDumpsCollection();
		Return;	
	Else
		If DumpsCollectionAndSendingParameters.SendDumpsFiles = 1
			OR DumpsCollectionAndSendingParameters.ForceSendMinidumps = 1
			AND DumpsCollectionAndSendingParameters.DumpType = "0" Then
			DumpsCollectionAndSendingParameters.FullDumpsCollectionEnabled.Insert(ComputerName, True);
		EndIf;
	EndIf;                                  
	
	// Get data about free space on the hard drive where dumps are collected.
	SeparatorPosition = StrFind(DumpsDirectory.Path, GetServerPathSeparator());
	If SeparatorPosition = 0 Then
		SetPrivilegedMode(True);
		SetMonitoringCenterParameter("SendingResult", NStr("ru='Не удалось определить букву диска'; en = 'Cannot determine the drive letter'; pl = 'Cannot determine the drive letter';de = 'Cannot determine the drive letter';ro = 'Cannot determine the drive letter';tr = 'Cannot determine the drive letter'; es_ES = 'Cannot determine the drive letter'"));
		SetPrivilegedMode(False);
		StopFullDumpsCollection();
		Return;
	EndIf;
	DriveLetter = Left(DumpsDirectory.Path, SeparatorPosition-1);
		                                    	
	// If dump collection is enabled.
	If DumpsCollectionAndSendingParameters.FullDumpsCollectionEnabled[ComputerName] = True Then
		
		If IsBlankString(JobID) Then
			JobID = "ExecutionAtServer";
		EndIf;
		
		// If the dump type is changed, it is necessary to clear a dumps directory.
		If DumpTypeChanged Then
			FilesDeleted(DumpsDirectory.Path);
		Else
			// Collect dumps.
			CollectDumps(DumpsCollectionAndSendingParameters);
		EndIf;
		
		// Send dumps.
		SendDumps(DumpsCollectionAndSendingParameters);
		
		MeasurementResult = FreeSpaceOnHardDrive(DriveLetter, FromClientAtServer);
		If NOT MeasurementResult.Success Then
			SetPrivilegedMode(True);
			SetMonitoringCenterParameter("SendingResult", MeasurementResult.ErrorDescription);
			SetPrivilegedMode(False);
			StopFullDumpsCollection();
			Return;
		EndIf;
		
		// Check if there is enough free space for collecting full dumps.
		// The check is carried out after dumps collection and sending in result of which some space is freed up.
		If MeasurementResult.Value/1024 < DumpsCollectionAndSendingParameters.SpaceReserveEnabled
			AND DumpType = "3" Then
			SetPrivilegedMode(True);
			SetMonitoringCenterParameter("SendingResult", NStr("ru = 'Недостаточно свободного места для хранения дампов. Сбор дампов будет отключен.'; en = 'There is not enough free space to store dumps. Dump collection will be disabled.'; pl = 'There is not enough free space to store dumps. Dump collection will be disabled.';de = 'There is not enough free space to store dumps. Dump collection will be disabled.';ro = 'There is not enough free space to store dumps. Dump collection will be disabled.';tr = 'There is not enough free space to store dumps. Dump collection will be disabled.'; es_ES = 'There is not enough free space to store dumps. Dump collection will be disabled.'"));	
			SetPrivilegedMode(False);
			StopFullDumpsCollection();
			Return;
		EndIf;
		
		FullDumpsCollectionEnabled = GetMonitoringCenterParameters("FullDumpsCollectionEnabled");
		FullDumpsCollectionEnabled.Insert(ComputerName, True);
		SetPrivilegedMode(True);
		SetMonitoringCenterParameters(New Structure("BasicChecksPassed, FullDumpsCollectionEnabled, SendingResult", True, FullDumpsCollectionEnabled, ""));
		SetPrivilegedMode(False);
		
	Else
		// If dump collection is disabled.
		MeasurementResult = FreeSpaceOnHardDrive(DriveLetter, FromClientAtServer);
		If NOT MeasurementResult.Success Then
			SetPrivilegedMode(True);
			SetMonitoringCenterParameter("SendingResult", MeasurementResult.ErrorDescription);
			SetPrivilegedMode(False);
			StopFullDumpsCollection();
			Return;
		EndIf;
		
		// Check if there is enough free space for collecting full dumps.
		If MeasurementResult.Value/1024 < DumpsCollectionAndSendingParameters.SpaceReserveDisabled
			AND DumpType = "3" Then
			SetPrivilegedMode(True);
			SetMonitoringCenterParameter("SendingResult", NStr("ru = 'Недостаточно свободного места для сбора дампов.'; en = 'There is not enough free space to collect dumps.'; pl = 'There is not enough free space to collect dumps.';de = 'There is not enough free space to collect dumps.';ro = 'There is not enough free space to collect dumps.';tr = 'There is not enough free space to collect dumps.'; es_ES = 'There is not enough free space to collect dumps.'"));	
			SetPrivilegedMode(False);
			StopFullDumpsCollection();
			Return;
		EndIf;
		
		SetPrivilegedMode(True);
		SetMonitoringCenterParameters(New Structure("BasicChecksPassed, SendingResult", True, ""));
		SetPrivilegedMode(False);
				
		// Automatically generates the current user task in OnFillToDoList.
		
	EndIf;
	
	// Deletes obsolete dumps files, except for requested ones.
	DeleteObsoleteFiles(DumpOption, DumpsDirectory.Path);
			
EndProcedure

Procedure CollectDumps(Parameters)
	
	// Get a dumps storage directory.
	DumpsDirectory = Parameters.DumpsDirectory;
	
	PropertyName = ?(Parameters.RequestConfirmationBeforeSending AND Parameters.DumpType = "3", "DumpInstances", "DumpInstancesApproved");
	
	If NOT Parameters.Property(PropertyName) Then
		Parameters.Insert(PropertyName, New Map);	
	EndIf;
	
	ComputerName = ComputerName();
		
	// Search for dumps in the directory.
	DumpsFiles = FindFiles(DumpsDirectory, "*.mdmp");
	HasChanges = False;
	// Look over found dumps.
	For Each DumpFile In DumpsFiles Do	    
		
		// If the dumps have a zero offset, delete them immediately.
		If StrFind(DumpFile.BaseName, "00000000") > 0 Then
			FilesDeleted(DumpFile.FullName);
			Continue;
		EndIf;
		
		DumpStructure = DumpDetails(DumpFile.Name);
	 	
		DumpOption = DumpStructure.Process + "_" + DumpStructure.PlatformVersion + "_" + DumpStructure.BeforeAfter;
						
		// If a dump has a non-zero offset, check if this dump is to be sent and if it matches the requested one.
		DumpRequirement = DumpIsRequired(DumpOption, Parameters.DumpOption, Parameters.DumpType);
		If DumpRequirement.Required Then
			
			ArchiveName = DumpsDirectory + DumpOption + ".zip"; 
			
			// Archive the dump and write information on it (name + size).
			ZipFileWriter = New ZipFileWriter();
			ZipFileWriter.Open(ArchiveName,,,ZIPCompressionMethod.Deflate);
			ZipFileWriter.Add(DumpFile.FullName);
			ZipFileWriter.Write();
			
			ArchiveFile = New File(ArchiveName);
			Size = Round(ArchiveFile.Size()/1024/1024,3); // File size in Megabytes.
			
			DumpData = New Structure;
			DumpData.Insert("FullName", ArchiveName);
			DumpData.Insert("Size", Size);
			DumpData.Insert("ComputerName", ComputerName);
			
			Parameters[PropertyName].Insert(DumpOption, DumpData);
			
			HasChanges = True;
			
		EndIf;
		
		// Delete the original dump.
		FilesDeleted(DumpFile.FullName);
		
	EndDo;
	
	If HasChanges Then 
		MonitoringCenterParameters = GetMonitoringCenterParameters(New Structure(PropertyName));
		For Each Record In Parameters[PropertyName] Do
			MonitoringCenterParameters[PropertyName].Insert(Record.Key, Record.Value);	
		EndDo;
		SetPrivilegedMode(True);
		SetMonitoringCenterParameter(PropertyName, MonitoringCenterParameters[PropertyName]);
		SetPrivilegedMode(False);
	EndIf;
	
EndProcedure

Procedure SendDumps(Parameters)
	
	Parameters.Insert("DumpInstancesApproved", GetMonitoringCenterParameters("DumpInstancesApproved"));
	
	If Parameters.RequestConfirmationBeforeSending AND Parameters.DumpType = "3" Then
		
		If Parameters.Property("DumpInstances") AND Parameters.DumpInstances.Count() Then
	
			TemplateRequestForSending = NStr("ru = 'Для отправки подготовлены отчеты об ошибках (%1 шт.)
		                             |Общий объем данных: %2 МБ.
		                             |Отправить указанные файлы для анализа в фирму ""1С""?'; 
		                             |en = 'Error reports (%1) are ready to be sent
		                             |Total data volume: %2 MB.
		                             |Send the specified files for analysis to 1C company?'; 
		                             |pl = 'Error reports (%1) are ready to be sent
		                             |Total data volume: %2 MB.
		                             |Send the specified files for analysis to 1C company?';
		                             |de = 'Error reports (%1) are ready to be sent
		                             |Total data volume: %2 MB.
		                             |Send the specified files for analysis to 1C company?';
		                             |ro = 'Error reports (%1) are ready to be sent
		                             |Total data volume: %2 MB.
		                             |Send the specified files for analysis to 1C company?';
		                             |tr = 'Error reports (%1) are ready to be sent
		                             |Total data volume: %2 MB.
		                             |Send the specified files for analysis to 1C company?'; 
		                             |es_ES = 'Error reports (%1) are ready to be sent
		                             |Total data volume: %2 MB.
		                             |Send the specified files for analysis to 1C company?'");	
			
			TotalSpace = 0;
			TotalPieces = 0;
						
			For Each Record In Parameters.DumpInstances Do
				
				DumpOption = Record.Key;
				DumpData = Record.Value;
				
				// Ask the Monitoring Center service if this dump is required.
				DumpRequirement = DumpIsRequired(DumpOption, Parameters.DumpOption, Parameters.DumpType);
				If DumpRequirement.Required Then
					TotalPieces = TotalPieces + 1;
					TotalSpace = TotalSpace + DumpData.Size;
				Else
					FilesDeleted(DumpData.FullName);
				EndIf;
				
			EndDo;
			
			// Ask the user if they want to send dumps.
			RequestForSending = StringFunctionsClientServer.SubstituteParametersToString(TemplateRequestForSending, TotalPieces, Format(TotalSpace,"NFD=; NZ=0"));
			SetPrivilegedMode(True);
			SetMonitoringCenterParameter("DumpsInformation", RequestForSending);
			SetPrivilegedMode(False);
			
		EndIf;
		
	Else
		For Each Record In Parameters.DumpInstances Do
			Parameters.DumpInstancesApproved.Insert(Record.Key, Record.Value);
		EndDo;
		
		SetPrivilegedMode(True);
		SetMonitoringCenterParameter("DumpInstancesApproved", Parameters.DumpInstancesApproved);
		SetPrivilegedMode(False);
		
	EndIf;             
	
	ComputerName = ComputerName();
	RequiredDump = Parameters.DumpOption;
	
	// Send dumps.
	ArrayOfSent = New Array;
	For Each Record In Parameters.DumpInstancesApproved Do
		// It is reasonable to check if we are using the required machine.
		If ComputerName <> Record.Value.ComputerName Then
			Continue;
		EndIf;
		If DumpSending(Record.Key, Record.Value, RequiredDump, Parameters.DumpType) Then
			ArrayOfSent.Add(Record.Key);
		EndIf;
	EndDo;
	
	// Remove sent dumps from the constant.
	HasChanges = False;
	Parameters.Insert("DumpInstancesApproved", GetMonitoringCenterParameters("DumpInstancesApproved"));
	For Each Item In ArrayOfSent Do
		Parameters.DumpInstancesApproved.Delete(Item);
		HasChanges = True;
	EndDo;
	If HasChanges Then 
		SetPrivilegedMode(True);
		SetMonitoringCenterParameter("DumpInstancesApproved", Parameters.DumpInstancesApproved);
		SetPrivilegedMode(False);
	EndIf;
	
EndProcedure

Procedure StopFullDumpsCollection()
	
	Stopped = True;
	
	// Clear dumps collection parameters.
	NewParameters = New Structure;
	NewParameters.Insert("DumpOption", "");
	NewParameters.Insert("DumpInstances", New Map);
	NewParameters.Insert("DumpInstancesApproved", New Map);
	NewParameters.Insert("DumpsInformation", "");
	NewParameters.Insert("DumpType", "0");
	NewParameters.Insert("NotificationDate", Date(1,1,1));
	NewParameters.Insert("BasicChecksPassed", False);
	
	Try
		SetPrivilegedMode(True);
		SetMonitoringCenterParameters(NewParameters);
		SetPrivilegedMode(False);
	Except
		// Cannot disable collection of full dumps.
		Stopped = False;
	EndTry;
	
	// Change logcfg.
	DumpsDirectory = GetDumpsDirectory("0", True);
	If DumpsDirectory.Path = Undefined Then
		// Cannot change logcfg
		Stopped = False;
	EndIf;
	// Delete dumps files.
	If DumpsDirectory.Path <> Undefined Then
		If NOT FilesDeleted(DumpsDirectory.Path) Then
			// Cannot delete dumps files.
			Stopped = False;	
		EndIf;
	EndIf;	 
	
	If Stopped Then
		FullDumpsCollectionEnabled = GetMonitoringCenterParameters("FullDumpsCollectionEnabled");
		FullDumpsCollectionEnabled.Delete(ComputerName());
		SetPrivilegedMode(True);
		SetMonitoringCenterParameter("FullDumpsCollectionEnabled", FullDumpsCollectionEnabled); 
		SetPrivilegedMode(False);
		DeleteScheduledJob("ErrorReportCollectionAndSending");
	EndIf;
	
EndProcedure

Procedure DeleteObsoleteFiles(RequiredDump, PathToDirectory)
	
	FilesArray = FindFiles(PathToDirectory,"*");
	For Each File In FilesArray Do             		
		DumpStructure = DumpDetails(File.Name);	 	
		DumpOption = DumpStructure.Process + "_" + DumpStructure.PlatformVersion + "_" + DumpStructure.BeforeAfter;
		If DumpOption = RequiredDump Then
			Continue;
		EndIf;
		
		// Delete a file that is older than three days.
		If File.Exist() AND CurrentSessionDate() - File.GetModificationTime() > 3*86400 Then
			FilesDeleted(File.FullName);
		EndIf;
		
	EndDo;
	
EndProcedure

Function FreeSpaceOnHardDrive(DriveLetter, FromClientAtServer)
	
	QueryResult = New Structure;
	QueryResult.Insert("Value", 0);
	QueryResult.Insert("Success", True);
	QueryResult.Insert("ErrorDescription", ""); 
	
	CommandLine = "typeperf ""\LogicalDisk(" + DriveLetter + ")\Free Megabytes"" -sc 1";
	
	ApplicationStartupParameters = FileSystem.ApplicationStartupParameters();
	ApplicationStartupParameters.WaitForCompletion = True;
	ApplicationStartupParameters.GetOutputStream = True;
	ApplicationStartupParameters.GetErrorStream = True;
	ApplicationStartupParameters.ExecutionEncoding = "OEM";
	
	RunResult = FileSystem.StartApplication(CommandLine, ApplicationStartupParameters);
	
	ErrorStream = RunResult.ErrorStream;
	OutputStream = RunResult.OutputStream;
	
	If ValueIsFilled(ErrorStream) Then 
		QueryResult.Success = False;
		QueryResult.ErrorDescription = NStr("ru='Ошибка при выполнении команды typeperf'; en = 'An error occurred while running the typeperf command'; pl = 'An error occurred while running the typeperf command';de = 'An error occurred while running the typeperf command';ro = 'An error occurred while running the typeperf command';tr = 'An error occurred while running the typeperf command'; es_ES = 'An error occurred while running the typeperf command'");
	Else 
		RowsArray = StringFunctionsClientServer.SplitStringIntoSubstringsArray(OutputStream, Chars.LF, True, True);
		If RowsArray.Count() >= 2 Then
			SearchRow = RowsArray[1];
			SubstringsArray = StringFunctionsClientServer.SplitStringIntoSubstringsArray(SearchRow, ",", True, True);
			If SubstringsArray.Count() >= 2 Then
				SearchRow = SubstringsArray[1];
				SearchRow = StrReplace(SearchRow,"""","");
				Try
					QueryResult.Value = Number(SearchRow);
					MonitoringCenter.WriteBusinessStatisticsOperationDay(
						"ClientStatistics.SystemInformation.FreeOnDisk." + DriveLetter, "", QueryResult.Value, True);
				Except
					QueryResult.Success = False;
					QueryResult.ErrorDescription = ErrorDescription();
				EndTry;
			EndIf;
		Else
			QueryResult.Success = False;
			QueryResult.ErrorDescription = NStr("ru='Не удалось разобрать результат typeperf'; en = 'Cannot parse the result typeperf'; pl = 'Cannot parse the result typeperf';de = 'Cannot parse the result typeperf';ro = 'Cannot parse the result typeperf';tr = 'Cannot parse the result typeperf'; es_ES = 'Cannot parse the result typeperf'");
		EndIf;
	EndIf;
	
	Return QueryResult;
	
EndFunction

// This function returns whether the dump is to be collected.
// If the dump type is specified, the function returns only whether the dump is to be collected.
// If the dump type is not specified, the function returns the dump type and whether the dump is to be collected.
// If the service is not available, collect full dumps.
//
Function DumpIsRequired(DumpOption, RequestedDump, DumpType = "")
	
	Result = New Structure("Required, DumpType", False, DumpType);
	RequiredDumps = RequiredDumps(DumpOption);
	
	// If the query cannot be executed, it is supposed that the dump is required when it matches the 
	// required dump.
	If NOT RequiredDumps.RequestSuccessful Then
		If DumpOption = RequestedDump Then
			Result.Required = True;
			Result.DumpType = "3";
		EndIf;
	Else
		// Check upon collecting and sending the dump.
		If Not IsBlankString(DumpType) Then
			If DumpType = "0" AND RequiredDumps.MiniDump Then
				Result.Required = True;
			ElsIf DumpType = "3" AND RequiredDumps.FullDump Then
				Result.Required = True;
			EndIf;
		Else
			// In case when the type of the dump being collected is to be determined.
			If RequiredDumps.MiniDump Then
				Result.Required = True;
				Result.DumpType = "0";
			ElsIf RequiredDumps.FullDump Then
				Result.Required = True;
				Result.DumpType = "3";
			EndIf;
		EndIf;
	EndIf;  
	
	Return Result;
	
EndFunction

// Returns required dump types by a dump option.
//
Function RequiredDumps(DumpOption)
	Result = New Structure("RequestSuccessful, MiniDump, FullDump", False, False, False);
	
	// Access the HTTP service.
	Parameters = GetSendServiceParameters(); 
		
	// Find out whether the dump is up-to-date.
	ResourceAddress = Parameters.DumpsResourceAddress;
	If Right(ResourceAddress, 1) <> "/" Then
		ResourceAddress = ResourceAddress + "/";
	EndIf;
	
	GUID = String(Parameters.InfoBaseID);
	ResourceAddress = ResourceAddress + "IsDumpNeeded" + "/" + GUID + "/" + DumpOption + "/json";
	
	HTTPParameters = New Structure;
	HTTPParameters.Insert("Server", Parameters.Server);
	HTTPParameters.Insert("ResourceAddress", ResourceAddress);
	HTTPParameters.Insert("Data", "");
	HTTPParameters.Insert("Port", Parameters.Port);
	HTTPParameters.Insert("SecureConnection", Parameters.SecureConnection);	
	HTTPParameters.Insert("Method", "GET");
	HTTPParameters.Insert("DataType", "");
	HTTPParameters.Insert("Timeout", 60);
	
	HTTPResponse = HTTPServiceSendDataInternal(HTTPParameters);
	
	If HTTPResponse.StatusCode = 200 Then
		Response = JSONStringToStructure(HTTPResponse.Body);
		Result.MiniDump = Response.MiniDump;
		Result.FullDump = Response.FullDump;
		Result.RequestSuccessful = True;
	EndIf;
	
	Return Result;
EndFunction 

Function CanLoadDump(DumpOption, DumpType)
	
	Result = False;
	
	// Access the HTTP service.
	Parameters = GetSendServiceParameters(); 
		
	// Find out whether the dump is up-to-date.
	ResourceAddress = Parameters.DumpsResourceAddress;
	If Right(ResourceAddress, 1) <> "/" Then
		ResourceAddress = ResourceAddress + "/";
	EndIf;
	
	GUID = String(Parameters.InfoBaseID);
	ResourceAddress = ResourceAddress + "CanLoadDump" + "/" + GUID + "/" + DumpOption + "/" + DumpType;
	
	HTTPParameters = New Structure;
	HTTPParameters.Insert("Server", Parameters.Server);
	HTTPParameters.Insert("ResourceAddress", ResourceAddress);
	HTTPParameters.Insert("Data", "");
	HTTPParameters.Insert("Port", Parameters.Port);
	HTTPParameters.Insert("SecureConnection", Parameters.SecureConnection);	
	HTTPParameters.Insert("Method", "GET");
	HTTPParameters.Insert("DataType", "");
	HTTPParameters.Insert("Timeout", 60);
	
	HTTPResponse = HTTPServiceSendDataInternal(HTTPParameters);
	
	If HTTPResponse.StatusCode = 200 Then
		Result = HTTPResponse.Body = "true";
	EndIf;
		
	Return Result;
	
EndFunction

Function DumpSending(DumpOption, Data, RequiredDump, DumpType)
	
	SendingResult = False;
	
	// Check if the file exists.
	// It might happen that the dump is displayed in the list of approved dumps but the file is actually missing.
	// In this case, the file is considered to be successfully sent.
	File = New File(Data.FullName);
	If NOT File.Exist() Then
		Return True;
	EndIf;
	
	// Check whether the dump is up-to-date. If not, delete it.
	DumpRequirement = DumpIsRequired(DumpOption, RequiredDump, DumpType);
	If Not DumpRequirement.Required Then
		FilesDeleted(Data.FullName);
		Return True;
	EndIf;
	
	// Check whether the server allows us to load the dump, it might take some time.
	If Not CanLoadDump(DumpOption, DumpType) Then
		Return False;
	EndIf;
	
	Parameters = GetSendServiceParameters();
	
	PerformanceMonitorExists = Common.SubsystemExists("StandardSubsystems.PerformanceMonitor");
	If PerformanceMonitorExists Then
		ModulePerformanceMonitor = Common.CommonModule("PerformanceMonitor");
		StartTime = ModulePerformanceMonitor.StartTimeMeasurement();
	EndIf;
	
	// Send the dump via the HTTP service.
	GUID = String(Parameters.InfoBaseID);
	HashSSL = New DataHashing(HashFunction.CRC32);
	HashSSL.AppendFile(Data.FullName);
	HASH = Format(HashSSL.HashSum,"NG=0"); 
	
	ResourceAddress = Parameters.DumpsResourceAddress;
	If Right(ResourceAddress, 1) <> "/" Then
		ResourceAddress = ResourceAddress + "/";
	EndIf;
	
	ResourceAddress = ResourceAddress + "LoadDump" + "/" + GUID + "/" + DumpOption + "/" + HASH + "/" + DumpType;
	
	HTTPParameters = New Structure;
	HTTPParameters.Insert("Server", Parameters.Server);
	HTTPParameters.Insert("ResourceAddress", ResourceAddress);
	HTTPParameters.Insert("Data", Data.FullName);
	HTTPParameters.Insert("Port", Parameters.Port);
	HTTPParameters.Insert("SecureConnection", Parameters.SecureConnection);	
	HTTPParameters.Insert("Method", "POST");
	HTTPParameters.Insert("DataType", "BinaryData");
	HTTPParameters.Insert("Timeout", 0);
	
	// Archive is deleted upon successful sending.
	HTTPResponse = HTTPServiceSendDataInternal(HTTPParameters);
	
	If HTTPResponse.StatusCode = 200 Then
		SendingResult = HTTPResponse.Body = "true";	
	EndIf;
		
	If PerformanceMonitorExists Then
		ModulePerformanceMonitor.EndTimeMeasurement("MonitoringCenterSubmitErrorReport", StartTime);
	EndIf;
	
	Return SendingResult;
		
EndFunction

Function FilesDeleted(Path, Mask = "")
	Try
		DeleteFiles(Path, Mask)
	Except
		Return False;
	EndTry;
	Return True;
EndFunction

Procedure CheckIfNotificationOfDumpsIsRequired(DumpsDirectoryPath)
	
	MonitoringCenterParameters = New Structure();
	MonitoringCenterParameters.Insert("SendDumpsFiles");
	MonitoringCenterParameters.Insert("DumpOption");
	MonitoringCenterParameters.Insert("DumpCollectingEnd");
	MonitoringCenterParameters.Insert("DumpsCheckDepth");
	MonitoringCenterParameters.Insert("MinDumpsCount");
	MonitoringCenterParameters.Insert("DumpCheckNext");
	MonitoringCenterParameters.Insert("DumpsCheckFrequency");
	MonitoringCenterParameters.Insert("DumpType");
	MonitoringCenterParameters.Insert("SpaceReserveDisabled");
	MonitoringCenterParameters = GetMonitoringCenterParameters(MonitoringCenterParameters);
	
	// Administrator refused to collect and send dumps.
	If MonitoringCenterParameters.SendDumpsFiles = 0 Then
		Return;
	EndIf;
	
	CurrentDate = CurrentUniversalDate();
	// Dumps collection is already enabled, checks are not required.
	If Not MonitoringCenterParameters.SendDumpsFiles = 0
		AND Not IsBlankString(MonitoringCenterParameters.DumpOption)
		AND CurrentDate < MonitoringCenterParameters.DumpCollectingEnd Then
		Return;
	EndIf;  
	
	// If the time for the next check did not come.
	If MonitoringCenterParameters.DumpCheckNext > CurrentDate Then
		Return;
	EndIf;
	
	SetMonitoringCenterParameter("DumpCheckNext", CurrentDate + MonitoringCenterParameters.DumpsCheckFrequency);
	
	StartDate = CurrentDate - MonitoringCenterParameters.DumpsCheckDepth;
	
	SysInfo = New SystemInfo;
	
	TopDumps = InformationRegisters.PlatformDumps.GetTopOptions(StartDate, CurrentDate, 10, SysInfo.AppVersion);
	Selection = TopDumps.Select();
	While Selection.Next() Do
		// If the number of dumps exceeds the minimum one, check whether the dump is required.
		If Selection.OptionsCount >=	MonitoringCenterParameters.MinDumpsCount Then
			// If the dump is required, initiate its collection.
			DumpRequirement = DumpIsRequired(Selection.DumpOption, "");
			If DumpRequirement.Required Then
				If DumpRequirement.DumpType = "3" Then
					// For a full dump, check if there is enough space.
					SeparatorPosition = StrFind(DumpsDirectoryPath, GetServerPathSeparator());
					If SeparatorPosition = 0 Then
						Continue;	
					EndIf;
					DriveLetter = Left(DumpsDirectoryPath, SeparatorPosition-1);
					MeasurementResult = FreeSpaceOnHardDrive(DriveLetter, False);
					If NOT MeasurementResult.Success Then
						Continue;
					EndIf;
					If MeasurementResult.Value/1024 < MonitoringCenterParameters.SpaceReserveDisabled Then
						Continue;
					EndIf;
				EndIf;
				
			    // Set dumps collection parameters.
				NewParameters = New Structure;
				NewParameters.Insert("DumpOption", Selection.DumpOption);
				NewParameters.Insert("DumpCollectingEnd", BegOfDay(CurrentDate)+30*86400);
				// Until the user agrees, cannot enable collection of full dumps.
				If MonitoringCenterParameters.SendDumpsFiles = 1 Then
					NewParameters.Insert("DumpType", DumpRequirement.DumpType);
				Else
					NewParameters.Insert("DumpType", "0");
				EndIf;
				SetMonitoringCenterParameters(NewParameters);
				MonitoringCenter.WriteBusinessStatisticsOperation("MonitoringCenter.DumpsRegistration.NotifyAdministrator", 1);
								
				// Abort collection traversal as collecting of dumps is requested from Administrator.
				Break;
				
			EndIf;
		Else
			// Abort collection traversal if the number of dumps is less than the minimum one.
			Break;
		EndIf;
	EndDo;
	
EndProcedure

#EndRegion

#Region TestPackageSending

// This procedure sends a test package to monitoring center.
// Parameters:
//  ExecutionParameters - Structure:
//   * Iterator	   - Number. Upon an external call, it must be equal to zero.
//   * TestPackageSending - Boolean.
//   * GetID - Boolean.
//
Procedure SendTestPackage(ExecutionParameters, ResultAddress) Export
	
	SetPrivilegedMode(True);
	
	ExecutionResult = New Structure("Success, BriefErrorPresentation", True, "");
	
	PerformanceMonitorExists = Common.SubsystemExists("StandardSubsystems.PerformanceMonitor");
	If PerformanceMonitorExists Then
		ModulePerformanceMonitor = Common.CommonModule("PerformanceMonitor");
		StartTime = ModulePerformanceMonitor.StartTimeMeasurement();
	EndIf;
	
	// Disable parameters to prevent excessive data from being sent.
	NewParameters = New Structure;
	NewParameters.Insert("RegisterSystemInformation", False);
	NewParameters.Insert("RegisterSubsystemVersions", False);
	NewParameters.Insert("RegisterDumps", False);
	NewParameters.Insert("RegisterBusinessStatistics", False);
	NewParameters.Insert("RegisterConfigurationStatistics", False);
	NewParameters.Insert("RegisterConfigurationSettings", False);
	NewParameters.Insert("RegisterPerformance", False);
	NewParameters.Insert("RegisterTechnologicalPerformance", False);
	SetMonitoringCenterParameters(NewParameters);
	
	StartDate = CurrentUniversalDate();
	MonitoringCenterParameters = New Structure();
	MonitoringCenterParameters.Insert("TestPackageSent");
	MonitoringCenterParameters.Insert("TestPackageSendingAttemptCount");
	MonitoringCenterParameters.Insert("SendDataNextGeneration");
	MonitoringCenterParameters.Insert("SendDataGenerationPeriod");
	MonitoringCenterParameters.Insert("EnableMonitoringCenter");
	MonitoringCenterParameters.Insert("ApplicationInformationProcessingCenter");
	MonitoringCenterParameters.Insert("DiscoveryPackageSent");
	
	MonitoringCenterParameters = GetMonitoringCenterParameters(MonitoringCenterParameters);
	
	If TestPackageSendingPossible(MonitoringCenterParameters, StartDate) AND ExecutionParameters.SendTestPackageFlag
		OR GetIDPossible(MonitoringCenterParameters) AND ExecutionParameters.GetID Then
		
		Try
			CreatePackageToSend();
		Except
			ExecutionResult.Success = False;
			ExecutionResult.BriefErrorPresentation = NStr("ru = 'Ошибка при формировании пакета.'; en = 'An error occurred while generating the package.'; pl = 'An error occurred while generating the package.';de = 'An error occurred while generating the package.';ro = 'An error occurred while generating the package.';tr = 'An error occurred while generating the package.'; es_ES = 'An error occurred while generating the package.'");
			Comment = DetailErrorDescription(ErrorInfo());
			WriteLogEvent(
			NStr("ru = 'Центр мониторинга - сформировать тестовый пакет для отправки'; en = 'Monitoring center - generate test package to send'; pl = 'Monitoring center - generate test package to send';de = 'Monitoring center - generate test package to send';ro = 'Monitoring center - generate test package to send';tr = 'Monitoring center - generate test package to send'; es_ES = 'Monitoring center - generate test package to send'",
			Common.DefaultLanguageCode()),
			EventLogLevel.Error,
			,
			,
			Comment);
		EndTry;
		
		Try
			HTTPResponse = SendMonitoringData(ExecutionParameters.SendTestPackageFlag);
			If HTTPResponse.StatusCode = 200 Then
				MonitoringCenterParameters.TestPackageSent = True;
			Else
				ExecutionResult.Success = False;
				ExecutionResult.BriefErrorPresentation = NStr("ru = 'Ошибка при отправке пакета.'; en = 'An error occurred while sending a package.'; pl = 'An error occurred while sending a package.';de = 'An error occurred while sending a package.';ro = 'An error occurred while sending a package.';tr = 'An error occurred while sending a package.'; es_ES = 'An error occurred while sending a package.'");
				Template = NStr("ru = 'Ошибка HTTP при отправке пакета. Код %1'; en = 'An HTTP error occurred while sending a package. Code %1'; pl = 'An HTTP error occurred while sending a package. Code %1';de = 'An HTTP error occurred while sending a package. Code %1';ro = 'An HTTP error occurred while sending a package. Code %1';tr = 'An HTTP error occurred while sending a package. Code %1'; es_ES = 'An HTTP error occurred while sending a package. Code %1'");
				Comment = StringFunctionsClientServer.SubstituteParametersToString(Template, HTTPResponse.StatusCode); 
				WriteLogEvent(
				NStr("ru = 'Центр мониторинга - отправить тестовые данные мониторинга'; en = 'Monitoring center - send monitoring test data'; pl = 'Monitoring center - send monitoring test data';de = 'Monitoring center - send monitoring test data';ro = 'Monitoring center - send monitoring test data';tr = 'Monitoring center - send monitoring test data'; es_ES = 'Monitoring center - send monitoring test data'",
				Common.DefaultLanguageCode()),
				EventLogLevel.Error,
				,
				,
				Comment);
			EndIf;
		Except
			ExecutionResult.Success = False;
			ExecutionResult.BriefErrorPresentation = NStr("ru = 'Ошибка при отправке пакета.'; en = 'An error occurred while sending a package.'; pl = 'An error occurred while sending a package.';de = 'An error occurred while sending a package.';ro = 'An error occurred while sending a package.';tr = 'An error occurred while sending a package.'; es_ES = 'An error occurred while sending a package.'");
			Comment = DetailErrorDescription(ErrorInfo());
			WriteLogEvent(
			NStr("ru = 'Центр мониторинга - отправить тестовые данные мониторинга'; en = 'Monitoring center - send monitoring test data'; pl = 'Monitoring center - send monitoring test data';de = 'Monitoring center - send monitoring test data';ro = 'Monitoring center - send monitoring test data';tr = 'Monitoring center - send monitoring test data'; es_ES = 'Monitoring center - send monitoring test data'",
			Common.DefaultLanguageCode()),
			EventLogLevel.Error,
			,
			,
			Comment);
			MonitoringCenter.WriteBusinessStatisticsOperation("MonitoringCenter.SendMonitoringData.Error", 1, Comment);
		EndTry;
		
		If ExecutionResult.Success Then
			ExecutionParameters.Insert("Iterator", ExecutionParameters.Iterator + 1);
		EndIf;
		
		DiscoveryPackageSent = GetMonitoringCenterParameters("DiscoveryPackageSent");
		
		If ExecutionResult.Success AND NOT DiscoveryPackageSent AND ExecutionParameters.Iterator < 2 Then
			// ID is changed, send the package again.
			SendTestPackage(ExecutionParameters, ResultAddress);
		ElsIf ExecutionResult.Success AND DiscoveryPackageSent Then	
		
			If ExecutionParameters.GetID Then
				// Send the package with data in one hour.
				SetMonitoringCenterParameter("SendDataNextGeneration", CurrentUniversalDate() + 3600); 
				PutToTempStorage(ExecutionResult, ResultAddress);
				If PerformanceMonitorExists Then
					ModulePerformanceMonitor.EndTimeMeasurement("MonitoringCenterHandshake", StartTime);
				EndIf;
			EndIf; 			
		ElsIf ExecutionParameters.GetID AND NOT ExecutionResult.Success Then
			PutToTempStorage(ExecutionResult, ResultAddress);		
		EndIf;
		
		If ExecutionParameters.SendTestPackageFlag Then
			MonitoringCenterParameters.SendDataNextGeneration = CurrentUniversalDate()
			+ GetMonitoringCenterParameters("SendDataGenerationPeriod");
			MonitoringCenterParameters.TestPackageSendingAttemptCount = MonitoringCenterParameters.TestPackageSendingAttemptCount + 1;
			
			MonitoringCenterParameters.Delete("SendDataGenerationPeriod");
			MonitoringCenterParameters.Delete("EnableMonitoringCenter");
			MonitoringCenterParameters.Delete("ApplicationInformationProcessingCenter");
			MonitoringCenterParameters.Delete("DiscoveryPackageSent");
			
			SetMonitoringCenterParameters(MonitoringCenterParameters);
		EndIf;
		
	ElsIf ExecutionParameters.GetID AND MonitoringCenterParameters.DiscoveryPackageSent Then
		PutToTempStorage(ExecutionResult, ResultAddress);	
	EndIf;
		
	SetPrivilegedMode(False);
	
EndProcedure

Function TestPackageSendingPossible(MonitoringCenterParameters, StartDate)
	Return NOT MonitoringCenterParameters.TestPackageSent AND MonitoringCenterParameters.TestPackageSendingAttemptCount < 3
		AND IsMasterNode() AND StartDate >= MonitoringCenterParameters.SendDataNextGeneration;
EndFunction
	
Function GetIDPossible(MonitoringCenterParameters)
	Return (MonitoringCenterParameters.EnableMonitoringCenter OR MonitoringCenterParameters.ApplicationInformationProcessingCenter)
		AND IsMasterNode() AND MonitoringCenterParameters.DiscoveryPackageSent = False;
EndFunction

#EndRegion


#EndRegion
