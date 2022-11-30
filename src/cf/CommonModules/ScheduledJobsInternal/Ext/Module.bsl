///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Internal

// Checks whether the scheduled job is enabled according to functional options.
//
// Parameters:
//  Job - MetadataObject:ScheduledJob - scheduled job.
//  JobDependencies - ValueTable - table of scheduled jobs dependencies returned by the 
//    ScheduledJobsInternal.ScheduledJobsDependentOnFunctionalOptions method.
//    If it is not specified, it is generated automatically.
//
// Returns:
//  Usage - Boolean - True if the scheduled job is used.
//
Function ScheduledJobAvailableByFunctionalOptions(Job, JobDependencies = Undefined) Export
	
	If JobDependencies = Undefined Then
		JobDependencies = ScheduledJobsDependentOnFunctionalOptions();
	EndIf;
	
	DisableInSubordinateDIBNode = False;
	DisableInStandaloneWorkplace = False;
	Usage                = Undefined;
	IsSubordinateDIBNode        = Common.IsSubordinateDIBNode();
	IsSeparatedMode          = Common.DataSeparationEnabled();
	IsStandaloneWorkplace = Common.IsStandaloneWorkplace();
	
	FoundRows = JobDependencies.FindRows(New Structure("ScheduledJob", Job));
	
	For Each DependencyString In FoundRows Do
		If IsSeparatedMode AND DependencyString.AvailableSaaS = False Then
			Return False;
		EndIf;
		
		DisableInSubordinateDIBNode = (DependencyString.AvailableInSubordinateDIBNode = False) AND IsSubordinateDIBNode;
		DisableInStandaloneWorkplace = (DependencyString.AvailableAtStandaloneWorkstation = False) AND IsStandaloneWorkplace;
		
		If DisableInSubordinateDIBNode Or DisableInStandaloneWorkplace Then
			Return False;
		EndIf;
		
		If DependencyString.FunctionalOption = Undefined Then
			Continue;
		EndIf;
		
		FOValue = GetFunctionalOption(DependencyString.FunctionalOption.Name);
		
		If Usage = Undefined Then
			Usage = FOValue;
		ElsIf DependencyString.DependenceByT Then
			Usage = Usage AND FOValue;
		Else
			Usage = Usage Or FOValue;
		EndIf;
	EndDo;
	
	If Usage = Undefined Then
		Return True;
	Else
		Return Usage;
	EndIf;
	
EndFunction

// Generates a table of dependencies of scheduled jobs on functional options.
//
// Returns:
//  Dependencies - ValueTable - a table of values with the following columns:
//    * ScheduledJob - MetadataObject:ScheduledJob - scheduled job.
//    * FunctionalOption - MetadataObject:FunctionalOption - functional option the scheduled job 
//        depends on.
//    * DependenceByT - Boolean - if the scheduled job depends on more than one functional option 
//        and you want to enable it only when all functional options are enabled, specify True for 
//        each dependency.
//        
//        The default value is False - if one or more functional options are enabled, the scheduled 
//        job is also enabled.
//    * EnableOnEnableFunctionalOption - Boolean, Undefined - if False, the scheduled job will not 
//        be enabled if the functional option is enabled. Value
//        Undefined corresponds to True.
//        The default value is Undefined.
//    * AvailableInSubordinateDIBNode - Boolean, Undefined - True or Undefined if the scheduled job 
//        is available in the DIB node.
//        The default value is Undefined.
//    * AvailableInSaaS - Boolean, Undefined - True or Undefined if the scheduled job is available 
//        in the SaaS.
//        The default value is Undefined.
//    * UseExternalResources - Boolean - True if the scheduled job is operating with external 
//        resources (receiving emails, synchronizing data, etc.).
//        The default value is False.
//
Function ScheduledJobsDependentOnFunctionalOptions() Export
	
	Dependencies = New ValueTable;
	Dependencies.Columns.Add("ScheduledJob");
	Dependencies.Columns.Add("FunctionalOption");
	Dependencies.Columns.Add("DependenceByT", New TypeDescription("Boolean"));
	Dependencies.Columns.Add("AvailableSaaS");
	Dependencies.Columns.Add("AvailableInSubordinateDIBNode");
	Dependencies.Columns.Add("EnableOnEnableFunctionalOption");
	Dependencies.Columns.Add("AvailableAtStandaloneWorkstation");
	Dependencies.Columns.Add("UseExternalResources",  New TypeDescription("Boolean"));
	Dependencies.Columns.Add("IsParameterized",  New TypeDescription("Boolean"));
	
	SSLSubsystemsIntegration.OnDefineScheduledJobSettings(Dependencies);
	ScheduledJobsOverridable.OnDefineScheduledJobSettings(Dependencies);
	
	Dependencies.Sort("ScheduledJob");
	
	Return Dependencies;
	
EndFunction

// Sets a flag of scheduled jobs usage in the infobase depending on values of functional options.
// 
//
// Parameters:
//  EnableJobs - Boolean - if True, disabled scheduled jobs will be enabled when they become 
//                             available according to functional options. Default value is False.
//
Procedure SetScheduledJobsUsageByFunctionalOptions(EnableJobs = False) Export
	
	IsSubordinateDIBNode = Common.IsSubordinateDIBNode();
	IsStandaloneWorkplace = Common.IsStandaloneWorkplace();
	
	DependentScheduledJobs = ScheduledJobsDependentOnFunctionalOptions();
	Jobs = DependentScheduledJobs.Copy(,"ScheduledJob");
	Jobs.GroupBy("ScheduledJob");
	
	For Each RowJob In Jobs Do
		
		Usage                    = Undefined;
		DisableJob                 = True;
		DisableInSubordinateDIBNode     = False;
		DisableInStandaloneWorkplace = False;
		
		FoundRows = DependentScheduledJobs.FindRows(New Structure("ScheduledJob", RowJob.ScheduledJob));
		
		For Each DependencyString In FoundRows Do
			DisableInSubordinateDIBNode = (DependencyString.AvailableInSubordinateDIBNode = False) AND IsSubordinateDIBNode;
			DisableInStandaloneWorkplace = (DependencyString.AvailableAtStandaloneWorkstation = False) AND IsStandaloneWorkplace;
			If DisableInSubordinateDIBNode Or DisableInStandaloneWorkplace Then
				Usage = False;
				Break;
			EndIf;
			
			If DependencyString.FunctionalOption = Undefined Then
				Continue;
			EndIf;
			
			FOValue = GetFunctionalOption(DependencyString.FunctionalOption.Name);
			
			If DependencyString.EnableOnEnableFunctionalOption = False Then
				If DisableJob Then
					DisableJob = Not FOValue;
				EndIf;
				FOValue = False;
			EndIf;
			
			If Usage = Undefined Then
				Usage = FOValue;
			ElsIf DependencyString.DependenceByT Then
				Usage = Usage AND FOValue;
			Else
				Usage = Usage Or FOValue;
			EndIf;
		EndDo;
		
		If Usage = Undefined
			Or (Usage AND Not EnableJobs) // Only disable scheduled jobs automatically on update.
			Or (Not Usage AND Not DisableJob) Then
			Continue;
		EndIf;
		
		JobsList = ScheduledJobsServer.FindJobs(New Structure("Metadata", RowJob.ScheduledJob));
		For Each ScheduledJob In JobsList Do
			JobParameters = New Structure("Use", Usage);
			ScheduledJobsServer.ChangeJob(ScheduledJob, JobParameters);
		EndDo;
		
	EndDo;
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Event subscription handlers.

// The procedure enables or disables the scheduled jobs created in the infobase on functional option 
// change.
//
// Parameters:
//  Source - ConstantValueManager - constant stores the value of FO.
//  Cancel - Boolean - cancel while writing constant.
//
Procedure EnableScheduledJobOnChangeFunctionalOption(Source, Cancel) Export
	
	If Source.DataExchange.Load Then
		Return;
	EndIf;
	
	SetPrivilegedMode(True);
	ChangeScheduledJobsUsageByFunctionalOptions(Source, Source.Value);
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Configuration subsystems event handlers.

// See ExportImportDataOverridable.AfterDataImport. 
Procedure AfterImportData(Container) Export
	
	ExternalResourcesOperationsLock.AfterImportData(Container);
	
EndProcedure

// See SaaSOverridable.OnFillIBParametersTable. 
Procedure OnFillIIBParametersTable(Val ParametersTable) Export
	
	If Common.SubsystemExists("StandardSubsystems.SaaS.CoreSaaS") Then
		ModuleSaaS = Common.CommonModule("SaaS");
		ModuleSaaS.AddConstantToIBParametersTable(ParametersTable, "MaxActiveBackgroundJobExecutionTime");
		ModuleSaaS.AddConstantToIBParametersTable(ParametersTable, "MaxActiveBackgroundJobCount");
	EndIf;
	
EndProcedure

// See InfobaseUpdateSSL.OnAddUpdateHandlers. 
Procedure OnAddUpdateHandlers(Handlers) Export
	
	Handler = Handlers.Add();
	Handler.Version = "2.3.1.24";
	Handler.Procedure = "ScheduledJobsInternal.SetScheduledJobsUsageByFunctionalOptions";
	Handler.ExecutionMode = "Exclusive";
	
	Handler = Handlers.Add();
	Handler.Version = "2.3.3.12";
	Handler.InitialFilling = True;
	Handler.ExecutionMode = "Seamless";
	Handler.Procedure = "ExternalResourcesOperationsLock.UpdateExternalResourceAccessLockParameters";
	
EndProcedure

// See JobsQueueOverridable.OnDefineScheduledJobsUsage. 
Procedure OnDefineScheduledJobsUsage(UsageTable) Export
	
	DependentScheduledJobs = ScheduledJobsDependentOnFunctionalOptions();
	
	FilterParameters = New Structure;
	FilterParameters.Insert("AvailableSaaS", False);
	SaaSJobsToDisable = DependentScheduledJobs.Copy(FilterParameters ,"ScheduledJob");
	For Each JobToDisable In SaaSJobsToDisable Do
		If UsageTable.Find(JobToDisable.ScheduledJob.Name, "ScheduledJob") <> Undefined Then
			Continue;
		EndIf;
		
		NewRow = UsageTable.Add();
		NewRow.ScheduledJob = JobToDisable.ScheduledJob.Name;
		NewRow.Use       = False;
	EndDo;
	
	FilterParameters.Insert("AvailableSaaS", True);
	SaaSJobsToEnable = DependentScheduledJobs.Copy(FilterParameters ,"ScheduledJob");
	For Each JobToEnable In SaaSJobsToEnable Do
		If UsageTable.Find(JobToEnable.ScheduledJob.Name, "ScheduledJob") <> Undefined Then
			Continue;
		EndIf;
		
		NewRow = UsageTable.Add();
		NewRow.ScheduledJob = JobToEnable.ScheduledJob.Name;
		NewRow.Use       = True;
	EndDo;
	
EndProcedure

// See DataExchangeOverridable.OnSetUpSubordinateDIBNode. 
Procedure OnSetUpSubordinateDIBNode() Export
	
	SetScheduledJobsUsageByFunctionalOptions();
	
EndProcedure

#EndRegion

#Region Private

Function SettingValue(SettingName) Export
	
	Settings = DefaultSettings();
	ScheduledJobsOverridable.OnDefineSettings(Settings);
	
	Return Settings[SettingName];
	
EndFunction

// Contains the default settings.
//
// Returns:
//  Structure - a structure with the keys:
//    * UnlockCommandLocation - String - determines unlock command location for operations with 
//                                                     external resources.
//
Function DefaultSettings()
	
	SubsystemSettings = New Structure;
	SubsystemSettings.Insert("UnlockCommandPlacement",
		NStr("ru = 'Блокировку также можно снять позднее в разделе <b>Администрирование - Обслуживание</b>.'; en = 'You can also release the lock later in <b>Administration - Service</b>.'; pl = 'Możesz także usunąć blokadę później w sekcji <b>Administracja - Obsługa</b>.';de = 'Die Sperre kann auch später im Abschnitt <b>Administration - Service</b>aufgehoben werden.';ro = 'De asemenea, puteți debloca mai târziu în compartimentul<b>Administrare - Deservire</b>.';tr = 'Kilitleme, <b>Yönetim-bakım</b> bölümünde daha sonra da kaldırılabilir.'; es_ES = 'Se puede quitar el bloqueo también más tarde en la sección <b>Administración - Servicio</b>.'"));
	
	Return SubsystemSettings;
	
EndFunction

// Throws an exception if the user does not have the administration right.
Procedure RaiseIfNoAdministrationRights() Export
	
	If Common.DataSeparationEnabled()
		AND Common.SeparatedDataUsageAvailable() Then
		If NOT Users.IsFullUser() Then
			Raise NStr("ru = 'Нарушение прав доступа.'; en = 'Access rights violation.'; pl = 'Naruszenie praw dostępu.';de = 'Verletzung von Zugriffsrechten.';ro = 'Încălcarea drepturilor de acces.';tr = 'Erişim hakkı ihlali.'; es_ES = 'Violación del derecho de acceso.'");
		EndIf;
	Else
		If NOT PrivilegedMode() Then
			VerifyAccessRights("Administration", Metadata);
		EndIf;
	EndIf;
	
EndProcedure

Procedure GenerateScheduledJobsTable(Parameters, StorageAddress) Export
	
	ScheduledJobID = Parameters.ScheduledJobID;
	Table                           = Parameters.Table;
	DisabledJobs                = Parameters.DisabledJobs;
	
	// Updating the ScheduledJobs table and the ChoiceList list of the scheduled job for filter.
	CurrentJobs = ScheduledJobs.GetScheduledJobs();
	DisabledJobs.Clear();
	
	ScheduledJobsParameters = ScheduledJobsDependentOnFunctionalOptions();
	FilterParameters        = New Structure;
	JobsToBeParameterized = New Array;
	FilterParameters.Insert("IsParameterized", True);
	SearchResult = ScheduledJobsParameters.FindRows(FilterParameters);
	For Each ResultString In SearchResult Do
		JobsToBeParameterized.Add(ResultString.ScheduledJob);
	EndDo;
	
	SaaSSubsystem = Metadata.Subsystems.StandardSubsystems.Subsystems.Find("SaaS");
	For Each MetadataObject In Metadata.ScheduledJobs Do
		If Not ScheduledJobAvailableByFunctionalOptions(MetadataObject, ScheduledJobsParameters) Then
			DisabledJobs.Add(MetadataObject.Name);
			Continue;
		EndIf;
		If NOT Common.DataSeparationEnabled() AND SaaSSubsystem <> Undefined Then
			If SaaSSubsystem.Content.Contains(MetadataObject) Then
				DisabledJobs.Add(MetadataObject.Name);
				Continue;
			EndIf;
			For each Subsystem In SaaSSubsystem.Subsystems Do
				If Subsystem.Content.Contains(MetadataObject) Then
					DisabledJobs.Add(MetadataObject.Name);
					Continue;
				EndIf;
			EndDo;
		EndIf;
	EndDo;
	
	If ScheduledJobID = Undefined Then
		
		Index = 0;
		For Each Job In CurrentJobs Do
			
			ID = String(Job.UUID);
			
			If Index >= Table.Count() Or Table[Index].ID <> ID Then
				
				// Inserting a new job.
				ToBeUpdated = Table.Insert(Index);
				
				// Setting a UUID.
				ToBeUpdated.ID = ID;
			Else
				ToBeUpdated = Table[Index];
			EndIf;
			
			If JobsToBeParameterized.Find(Job.Metadata) <> Undefined Then
				ToBeUpdated.Parameterized = True;
			EndIf;
			
			SetScheduledJobProperties(ToBeUpdated, Job);
			Index = Index + 1;
		EndDo;
	
		// Deleting unnecessary rows.
		While Index < Table.Count() Do
			Table.Delete(Index);
		EndDo;
		Table.Sort("Description");
	Else
		Job = ScheduledJobs.FindByUUID(
			New UUID(ScheduledJobID));
		
		Rows = Table.FindRows(
			New Structure("ID", ScheduledJobID));
		
		If Job <> Undefined
		   AND Rows.Count() > 0 Then
			
			RowJob = Rows[0];
			If JobsToBeParameterized.Find(Job.Metadata) <> Undefined Then
				RowJob.Parameterized = True;
			EndIf;
			SetScheduledJobProperties(RowJob, Job);
		EndIf;
	EndIf;
	
	Result = New Structure;
	Result.Insert("Table", Table);
	Result.Insert("DisabledJobs", DisabledJobs);
	
	PutToTempStorage(Result, StorageAddress);
	
EndProcedure

Procedure SetScheduledJobProperties(Target, JobSource)
	
	FillPropertyValues(Target, JobSource);
	
	// Description adjustment
	Target.Description = ScheduledJobPresentation(JobSource);
	
	// Setting the Completion date and the Completion state by the last background procedure .
	LastBackgroundJobProperties = LastBackgroundJobScheduledJobExecutionProperties(JobSource);
	
	Target.JobName = JobSource.Metadata.Name;
	If LastBackgroundJobProperties = Undefined Then
		Target.StartDate          = TextUndefined();
		Target.EndDate       = TextUndefined();
		Target.ExecutionState = TextUndefined();
	Else
		Target.StartDate          = ?(ValueIsFilled(LastBackgroundJobProperties.Begin),
		                               LastBackgroundJobProperties.Begin,
		                               "<>");
		Target.EndDate       = ?(ValueIsFilled(LastBackgroundJobProperties.End),
		                               LastBackgroundJobProperties.End,
		                               "<>");
		Target.ExecutionState = LastBackgroundJobProperties.State;
	EndIf;
		
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Procedures and functions for working with scheduled jobs.

// It is intended for "manual" immediate execution of the scheduled job procedure either in the 
// client session (in the file infobase) or in the background job on the server (in the server infobase).
// It is used in any connection mode.
// The "manual" run mode does not affect the scheduled job execution according to the emergency and 
// main schedules, as the background job has no reference to the scheduled job.
// The BackgroundJob type does not allow such a reference, so the same rule is applied to file mode.
// 
// 
// Parameters:
//  Job - ScheduledJob, String - ScheduledJob UUID string.
//
// Returns:
//  Structure with the following properties:
//    * StartTime - Undefined, Date - for the file infobase, sets the passed time as the scheduled 
//                        job method start time.
//                        For the server infobase returns the background job start time upon completion.
//    * BackgroundJobID - String - for the server infobase, returns the running background job ID.
//
Function ExecuteScheduledJobManually(Val Job) Export
	
	RaiseIfNoAdministrationRights();
	SetPrivilegedMode(True);
	
	ExecutionParameters = ScheduledJobExecutionParameters();
	ExecutionParameters.ProcedureAlreadyExecuting = False;
	Job = ScheduledJobsServer.GetScheduledJob(Job);
	
	ExecutionParameters.Started = False;
	LastBackgroundJobProperties = LastBackgroundJobScheduledJobExecutionProperties(Job);
	
	If LastBackgroundJobProperties <> Undefined
	   AND LastBackgroundJobProperties.State = BackgroundJobState.Active Then
		
		ExecutionParameters.StartedAt  = LastBackgroundJobProperties.Begin;
		If ValueIsFilled(LastBackgroundJobProperties.Description) Then
			ExecutionParameters.BackgroundJobPresentation = LastBackgroundJobProperties.Description;
		Else
			ExecutionParameters.BackgroundJobPresentation = ScheduledJobPresentation(Job);
		EndIf;
	Else
		BackgroundJobDescription = StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = 'Запуск вручную: %1'; en = 'Manual start: %1'; pl = 'Uruchomienie ręczne: %1';de = 'Manuell starten: %1';ro = 'Lansare manuală: %1';tr = 'Manuel olarak başlat: %1'; es_ES = 'Iniciar manualmente: %1'"), ScheduledJobPresentation(Job));
		// Time-consuming operations are not used, because the method of the scheduled job is called.
		BackgroundJob = BackgroundJobs.Execute(Job.Metadata.MethodName, Job.Parameters, String(Job.UUID), BackgroundJobDescription);
		ExecutionParameters.BackgroundJobID = String(BackgroundJob.UUID);
		ExecutionParameters.StartedAt = BackgroundJobs.FindByUUID(BackgroundJob.UUID).Begin;
		ExecutionParameters.Started = True;
	EndIf;
	
	ExecutionParameters.ProcedureAlreadyExecuting = NOT ExecutionParameters.Started;
	Return ExecutionParameters;
	
EndFunction

Function ScheduledJobExecutionParameters() 
	
	Result = New Structure;
	Result.Insert("StartedAt");
	Result.Insert("BackgroundJobID");
	Result.Insert("BackgroundJobPresentation");
	Result.Insert("ProcedureAlreadyExecuting");
	Result.Insert("Started");
	Return Result;
	
EndFunction

// Returns the scheduled job presentation, according to the blank details exception order:
// 
// Description, Metadata.Synonym, and Metadata.Name.
//
// Parameters:
//  Job - ScheduledJob, String - if a string, a UUID string.
//
// Returns:
//  String.
//
Function ScheduledJobPresentation(Val Job) Export
	
	RaiseIfNoAdministrationRights();
	SetPrivilegedMode(True);
	
	If TypeOf(Job) = Type("ScheduledJob") Then
		ScheduledJob = Job;
	Else
		ScheduledJob = ScheduledJobs.FindByUUID(New UUID(Job));
	EndIf;
	
	If ScheduledJob <> Undefined Then
		Presentation = ScheduledJob.Description;
		
		If IsBlankString(ScheduledJob.Description) Then
			Presentation = ScheduledJob.Metadata.Synonym;
			
			If IsBlankString(Presentation) Then
				Presentation = ScheduledJob.Metadata.Name;
			EndIf
		EndIf;
	Else
		Presentation = TextUndefined();
	EndIf;
	
	Return Presentation;
	
EndFunction

// Returns the text "<not defined>".
Function TextUndefined() Export
	
	Return NStr("ru = '<не определено>'; en = '<not defined>'; pl = '<nie określono>';de = '<nicht bestimmt>';ro = '<nu este determinată>';tr = '<belirlenmedi>'; es_ES = '<no determinado>'");
	
EndFunction

// Returns a multiline String containing Messages and ErrorDescription, the last background job is 
// found by the scheduled job ID and there are messages/errors.
// 
//
// Parameters:
//  Job - ScheduledJob, String - UUID
//                 ScheduledJob string.
//
// Returns:
//  String.
//
Function ScheduledJobMessagesAndErrorDescriptions(Val Job) Export
	
	RaiseIfNoAdministrationRights();
	SetPrivilegedMode(True);

	ScheduledJobID = ?(TypeOf(Job) = Type("ScheduledJob"), String(Job.UUID), Job);
	LastBackgroundJobProperties = LastBackgroundJobScheduledJobExecutionProperties(ScheduledJobID);
	Return ?(LastBackgroundJobProperties = Undefined,
	          "",
	          BackgroundJobMessagesAndErrorDescriptions(LastBackgroundJobProperties.ID) );
	
EndFunction

////////////////////////////////////////////////////////////////////////////////
// Procedures and functions for working with background jobs.

// Cancels the background job if possible, i.e. if it is running on the server and is active.
//
// Parameters:
//  ID - a string UUID of a BackgroundJob.
// 
Procedure CancelBackgroundJob(ID) Export
	
	RaiseIfNoAdministrationRights();
	SetPrivilegedMode(True);
	
	NewUUID = New UUID(ID);
	Filter = New Structure;
	Filter.Insert("UUID", NewUUID);
	BackgroundJobArray = BackgroundJobs.GetBackgroundJobs(Filter);
	If BackgroundJobArray.Count() = 1 Then
		BackgroundJob = BackgroundJobArray[0];
	Else
		Raise NStr("ru = 'Фоновое задание не найдено на сервере.'; en = 'The background job is not found on the server.'; pl = 'Na serwerze nie znaleziono zadania w tle.';de = 'Hintergrundjob wurde auf dem Server nicht gefunden.';ro = 'Sarcina de fundal nu a fost găsită pe server.';tr = 'Arkaplan işi sunucuda bulunamadı.'; es_ES = 'Tarea de fondo no encontrada en el servidor.'");
	EndIf;
	
	If BackgroundJob.State <> BackgroundJobState.Active Then
		Raise NStr("ru = 'Задание не выполняется, его нельзя отменить.'; en = 'The job is not being executed, it cannot be canceled.'; pl = 'Zadanie nie może byc zakończone, nie można go anulować.';de = 'Der Job kann nicht abgeschlossen werden, er kann nicht abgebrochen werden.';ro = 'Sarcina nu se execută, ea nu poate fi revocată.';tr = 'İş tamamlanamıyor, iptal edilemez.'; es_ES = 'No se puede finalizar la tarea, no puede cancelarse.'");
	EndIf;
	
	BackgroundJob.Cancel();
	
EndProcedure

// For internal use only.
//
Procedure FillBackgroundJobsPropertiesTableInBackground(Parameters, StorageAddress) Export
	
	PropertiesTable = BackgroundJobsProperties(Parameters.Filter);
	
	Result = New Structure;
	Result.Insert("PropertiesTable", PropertiesTable);
	
	PutToTempStorage(Result, StorageAddress);
	
EndProcedure

// Returns a background job property table.
//  See the table structure in the EmptyBackgroundJobPropertyTable() function.
// 
// Parameters:
//  Filter - Structure - valid fields:
//                 ID, Key, State, Beginning, End,
//                 Description, MethodName, and ScheduledJob.
//
// Returns:
//  ValueTable returns a table after filter.
//
Function BackgroundJobsProperties(Filter = Undefined) Export
	
	RaiseIfNoAdministrationRights();
	SetPrivilegedMode(True);
	
	Table = NewBackgroundJobsProperties();
	
	If ValueIsFilled(Filter) AND Filter.Property("GetLastScheduledJobBackgroundJob") Then
		Filter.Delete("GetLastScheduledJobBackgroundJob");
		GetLast = True;
	Else
		GetLast = False;
	EndIf;
	
	ScheduledJob = Undefined;
	
	// Adding the history of background jobs received from the server.
	If ValueIsFilled(Filter) AND Filter.Property("ScheduledJobID") Then
		If Filter.ScheduledJobID <> "" Then
			ScheduledJob = ScheduledJobs.FindByUUID(
				New UUID(Filter.ScheduledJobID));
			CurrentFilter = New Structure("Key", Filter.ScheduledJobID);
			BackgroundJobsStartedManually = BackgroundJobs.GetBackgroundJobs(CurrentFilter);
			If ScheduledJob <> Undefined Then
				LastBackgroundJob = ScheduledJob.LastJob;
			EndIf;
			If NOT GetLast OR LastBackgroundJob = Undefined Then
				CurrentFilter = New Structure("ScheduledJob", ScheduledJob);
				AutomaticBackgroundJobs = BackgroundJobs.GetBackgroundJobs(CurrentFilter);
			EndIf;
			If GetLast Then
				If LastBackgroundJob = Undefined Then
					LastBackgroundJob = LastBackgroundJobInArray(AutomaticBackgroundJobs);
				EndIf;
				
				LastBackgroundJob = LastBackgroundJobInArray(
					BackgroundJobsStartedManually, LastBackgroundJob);
				
				If LastBackgroundJob <> Undefined Then
					BackgroundJobArray = New Array;
					BackgroundJobArray.Add(LastBackgroundJob);
					AddBackgroundJobProperties(BackgroundJobArray, Table);
				EndIf;
				Return Table;
			EndIf;
			AddBackgroundJobProperties(BackgroundJobsStartedManually, Table);
			AddBackgroundJobProperties(AutomaticBackgroundJobs, Table);
		Else
			BackgroundJobArray = New Array;
			AllScheduledJobIDs = New Map;
			For each CurrentJob In ScheduledJobs.GetScheduledJobs() Do
				AllScheduledJobIDs.Insert(
					String(CurrentJob.UUID), True);
			EndDo;
			AllBackgroundJobs = BackgroundJobs.GetBackgroundJobs();
			For each CurrentJob In AllBackgroundJobs Do
				If CurrentJob.ScheduledJob = Undefined
				   AND AllScheduledJobIDs[CurrentJob.Key] = Undefined Then
				
					BackgroundJobArray.Add(CurrentJob);
				EndIf;
			EndDo;
			AddBackgroundJobProperties(BackgroundJobArray, Table);
		EndIf;
	Else
		If NOT ValueIsFilled(Filter) Then
			BackgroundJobArray = BackgroundJobs.GetBackgroundJobs();
		Else
			If Filter.Property("ID") Then
				Filter.Insert("UUID", New UUID(Filter.ID));
				Filter.Delete("ID");
			EndIf;
			BackgroundJobArray = BackgroundJobs.GetBackgroundJobs(Filter);
			If Filter.Property("UUID") Then
				Filter.Insert("ID", String(Filter.UUID));
				Filter.Delete("UUID");
			EndIf;
		EndIf;
		AddBackgroundJobProperties(BackgroundJobArray, Table);
	EndIf;
	
	If ValueIsFilled(Filter) AND Filter.Property("ScheduledJobID") Then
		ScheduledJobsForProcessing = New Array;
		If Filter.ScheduledJobID <> "" Then
			If ScheduledJob = Undefined Then
				ScheduledJob = ScheduledJobs.FindByUUID(
					New UUID(Filter.ScheduledJobID));
			EndIf;
			If ScheduledJob <> Undefined Then
				ScheduledJobsForProcessing.Add(ScheduledJob);
			EndIf;
		EndIf;
	Else
		ScheduledJobsForProcessing = ScheduledJobs.GetScheduledJobs();
	EndIf;
	
	Table.Sort("Begin Desc, End Desc");
	
	// Filtering background jobs.
	If ValueIsFilled(Filter) Then
		Start    = Undefined;
		End     = Undefined;
		State = Undefined;
		If Filter.Property("Begin") Then
			Start = ?(ValueIsFilled(Filter.Begin), Filter.Begin, Undefined);
			Filter.Delete("Begin");
		EndIf;
		If Filter.Property("End") Then
			End = ?(ValueIsFilled(Filter.End), Filter.End, Undefined);
			Filter.Delete("End");
		EndIf;
		If Filter.Property("State") Then
			If TypeOf(Filter.State) = Type("Array") Then
				State = Filter.State;
				Filter.Delete("State");
			EndIf;
		EndIf;
		
		If Filter.Count() <> 0 Then
			Rows = Table.FindRows(Filter);
		Else
			Rows = Table;
		EndIf;
		// Performing additional filter by period and state (if the filter is defined).
		ItemNumber = Rows.Count() - 1;
		While ItemNumber >= 0 Do
			If Start    <> Undefined AND Start > Rows[ItemNumber].Begin
				Or End     <> Undefined AND End  < ?(ValueIsFilled(Rows[ItemNumber].End), Rows[ItemNumber].End, CurrentSessionDate())
				Or State <> Undefined AND State.Find(Rows[ItemNumber].State) = Undefined Then
				Rows.Delete(ItemNumber);
			EndIf;
			ItemNumber = ItemNumber - 1;
		EndDo;
		// Deleting unnecessary rows from the table.
		If TypeOf(Rows) = Type("Array") Then
			RowNumber = Table.Count() - 1;
			While RowNumber >= 0 Do
				If Rows.Find(Table[RowNumber]) = Undefined Then
					Table.Delete(Table[RowNumber]);
				EndIf;
				RowNumber = RowNumber - 1;
			EndDo;
		EndIf;
	EndIf;
	
	Return Table;
	
EndFunction

// Returns BackgroundJob properties by a UUID string.
//
// Parameters:
//  ID - String - BackgroundJob UUID.
//  PropertyNames - string, if filled, returns a structure with the specified properties.
// 
// Returns:
//  ValueTableRow, Structure - BackgroundJob properties.
//
Function GetBackgroundJobProperties(ID, PropertiesNames = "") Export
	
	RaiseIfNoAdministrationRights();
	SetPrivilegedMode(True);
	
	Filter = New Structure("ID", ID);
	BackgroundJobPropertyTable = BackgroundJobsProperties(Filter);
	
	If BackgroundJobPropertyTable.Count() > 0 Then
		If ValueIsFilled(PropertiesNames) Then
			Result = New Structure(PropertiesNames);
			FillPropertyValues(Result, BackgroundJobPropertyTable[0]);
		Else
			Result = BackgroundJobPropertyTable[0];
		EndIf;
	Else
		Result = Undefined;
	EndIf;
	
	Return Result;
	
EndFunction

// Returns the properties of the last background job executed with the scheduled job, if there is one.
// The procedure works both in file mode and client/server mode.
//
// Parameters:
//  ScheduledJob - ScheduledJob, String - ScheduledJob UUID string.
//
// Returns:
//  ValueTableRow, Undefined.
//
Function LastBackgroundJobScheduledJobExecutionProperties(ScheduledJob)
	
	RaiseIfNoAdministrationRights();
	SetPrivilegedMode(True);
	
	ScheduledJobID = ?(TypeOf(ScheduledJob) = Type("ScheduledJob"), String(ScheduledJob.UUID), ScheduledJob);
	Filter = New Structure;
	Filter.Insert("ScheduledJobID", ScheduledJobID);
	Filter.Insert("GetLastScheduledJobBackgroundJob");
	BackgroundJobPropertyTable = BackgroundJobsProperties(Filter);
	BackgroundJobPropertyTable.Sort("End Asc");
	
	If BackgroundJobPropertyTable.Count() = 0 Then
		BackgroundJobProperties = Undefined;
	ElsIf NOT ValueIsFilled(BackgroundJobPropertyTable[0].End) Then
		BackgroundJobProperties = BackgroundJobPropertyTable[0];
	Else
		BackgroundJobProperties = BackgroundJobPropertyTable[BackgroundJobPropertyTable.Count()-1];
	EndIf;
	
	Return BackgroundJobProperties;
	
EndFunction

// Returns a multiline String containing Messages and ErrorDescription if the background job is 
// found by the ID and there are messages/errors.
//
// Parameters:
//  Job - String - a BackgroundJob UUID string.
//
// Returns:
//  String.
//
Function BackgroundJobMessagesAndErrorDescriptions(ID, BackgroundJobProperties = Undefined) Export
	
	RaiseIfNoAdministrationRights();
	SetPrivilegedMode(True);
	
	If BackgroundJobProperties = Undefined Then
		BackgroundJobProperties = GetBackgroundJobProperties(ID);
	EndIf;
	
	Row = "";
	If BackgroundJobProperties <> Undefined Then
		For each Message In BackgroundJobProperties.UserMessages Do
			Row = Row + ?(Row = "",
			                    "",
			                    "
			                    |
			                    |") + Message.Text;
		EndDo;
		If ValueIsFilled(BackgroundJobProperties.ErrorDescription) Then
			Row = Row + ?(Row = "",
			                    BackgroundJobProperties.ErrorDescription,
			                    "
			                    |
			                    |" + BackgroundJobProperties.ErrorDescription);
		EndIf;
	EndIf;
	
	Return Row;
	
EndFunction

////////////////////////////////////////////////////////////////////////////////
// Auxiliary procedures and functions.

Procedure ChangeScheduledJobsUsageByFunctionalOptions(Source, Val Usage)
	
	If Not Common.SeparatedDataUsageAvailable() Then
		Return;
	EndIf;
	
	SourceType = TypeOf(Source);
	FOStorage = Metadata.FindByType(SourceType);
	FunctionalOption = Undefined;
	IsSubordinateDIBNode = Common.IsSubordinateDIBNode();
	IsStandaloneWorkplace = Common.IsStandaloneWorkplace();
	
	DependentScheduledJobs = ScheduledJobsDependentOnFunctionalOptions();
	
	FOList = DependentScheduledJobs.Copy(,"FunctionalOption");
	FOList.GroupBy("FunctionalOption");
	
	For Each FOString In FOList Do
		
		If FOString.FunctionalOption = Undefined Then
			Continue;
		EndIf;
		
		If FOString.FunctionalOption.Location = FOStorage Then
			FunctionalOption = FOString.FunctionalOption;
			Break;
		EndIf;
		
	EndDo;
	
	If FunctionalOption = Undefined
		Or GetFunctionalOption(FunctionalOption.Name) = Usage Then
		Return;
	EndIf;
	
	Jobs = DependentScheduledJobs.Copy(New Structure("FunctionalOption", FunctionalOption) ,"ScheduledJob");
	Jobs.GroupBy("ScheduledJob");
	
	For Each RowJob In Jobs Do
		
		UsageByFO                = Undefined;
		DisableJob                 = True;
		DisableInSubordinateDIBNode     = False;
		DisableInStandaloneWorkplace = False;
		
		FoundRows = DependentScheduledJobs.FindRows(New Structure("ScheduledJob", RowJob.ScheduledJob));
		
		For Each DependencyString In FoundRows Do
			DisableInSubordinateDIBNode = (DependencyString.AvailableInSubordinateDIBNode = False) AND IsSubordinateDIBNode;
			DisableInStandaloneWorkplace = (DependencyString.AvailableAtStandaloneWorkstation = False) AND IsStandaloneWorkplace;
			If DisableInSubordinateDIBNode Or DisableInStandaloneWorkplace Then
				Break;
			EndIf;
			
			If DependencyString.FunctionalOption = Undefined Then
				Continue;
			EndIf;
			
			If DependencyString.FunctionalOption = FunctionalOption Then
				FOValue = Usage;
			Else
				FOValue = GetFunctionalOption(DependencyString.FunctionalOption.Name);
			EndIf;
			
			If DependencyString.EnableOnEnableFunctionalOption = False Then
				If DisableJob Then
					DisableJob = Not FOValue;
				EndIf;
				FOValue = False;
			EndIf;
			
			If UsageByFO = Undefined Then
				UsageByFO = FOValue;
			ElsIf DependencyString.DependenceByT Then
				UsageByFO = UsageByFO AND FOValue;
			Else
				UsageByFO = UsageByFO Or FOValue;
			EndIf;
		EndDo;
		
		If DisableInSubordinateDIBNode Or DisableInStandaloneWorkplace Then
			Usage = False;
		Else
			If Usage <> UsageByFO Then
				Continue;
			EndIf;
			
			If Not Usage AND Not DisableJob Then
				Continue;
			EndIf;
		EndIf;
		
		JobsList = ScheduledJobsServer.FindJobs(New Structure("Metadata", RowJob.ScheduledJob));
		For Each ScheduledJob In JobsList Do
			JobParameters = New Structure("Use", Usage);
			ScheduledJobsServer.ChangeJob(ScheduledJob, JobParameters);
		EndDo;
		
	EndDo;
	
EndProcedure

// Returns a new background job property table.
//
// Returns:
//  ValueTable.
//
Function NewBackgroundJobsProperties()
	
	NewTable = New ValueTable;
	NewTable.Columns.Add("ID",                     New TypeDescription("String"));
	NewTable.Columns.Add("Description",                      New TypeDescription("String"));
	NewTable.Columns.Add("Key",                              New TypeDescription("String"));
	NewTable.Columns.Add("Begin",                            New TypeDescription("Date"));
	NewTable.Columns.Add("End",                             New TypeDescription("Date"));
	NewTable.Columns.Add("ScheduledJobID", New TypeDescription("String"));
	NewTable.Columns.Add("State",                         New TypeDescription("BackgroundJobState"));
	NewTable.Columns.Add("MethodName",                         New TypeDescription("String"));
	NewTable.Columns.Add("Location",                      New TypeDescription("String"));
	NewTable.Columns.Add("ErrorDescription",        New TypeDescription("String"));
	NewTable.Columns.Add("StartAttempt",                    New TypeDescription("Number"));
	NewTable.Columns.Add("UserMessages",             New TypeDescription("Array"));
	NewTable.Columns.Add("SessionNumber",                       New TypeDescription("Number"));
	NewTable.Columns.Add("SessionStarted",                      New TypeDescription("Date"));
	NewTable.Indexes.Add("ID, Begin");
	
	Return NewTable;
	
EndFunction

Procedure AddBackgroundJobProperties(Val BackgroundJobArray, Val BackgroundJobPropertyTable)
	
	Index = BackgroundJobArray.Count() - 1;
	While Index >= 0 Do
		BackgroundJob = BackgroundJobArray[Index];
		Row = BackgroundJobPropertyTable.Add();
		FillPropertyValues(Row, BackgroundJob);
		Row.ID = BackgroundJob.UUID;
		ScheduledJob = BackgroundJob.ScheduledJob;
		
		If ScheduledJob = Undefined
		   AND StringFunctionsClientServer.IsUUID(BackgroundJob.Key) Then
			
			ScheduledJob = ScheduledJobs.FindByUUID(New UUID(BackgroundJob.Key));
		EndIf;
		Row.ScheduledJobID = ?(
			ScheduledJob = Undefined,
			"",
			ScheduledJob.UUID);
		
		Row.ErrorDescription = ?(
			BackgroundJob.ErrorInfo = Undefined,
			"",
			DetailErrorDescription(BackgroundJob.ErrorInfo));
		
		Index = Index - 1;
	EndDo;
	
EndProcedure

Function LastBackgroundJobInArray(BackgroundJobArray, LastBackgroundJob = Undefined)
	
	For each CurrentBackgroundJob In BackgroundJobArray Do
		If LastBackgroundJob = Undefined Then
			LastBackgroundJob = CurrentBackgroundJob;
			Continue;
		EndIf;
		If ValueIsFilled(LastBackgroundJob.End) Then
			If NOT ValueIsFilled(CurrentBackgroundJob.End)
			 OR LastBackgroundJob.End < CurrentBackgroundJob.End Then
				LastBackgroundJob = CurrentBackgroundJob;
			EndIf;
		Else
			If NOT ValueIsFilled(CurrentBackgroundJob.End)
			   AND LastBackgroundJob.Begin < CurrentBackgroundJob.Begin Then
				LastBackgroundJob = CurrentBackgroundJob;
			EndIf;
		EndIf;
	EndDo;
	
	Return LastBackgroundJob;
	
EndFunction

#EndRegion
