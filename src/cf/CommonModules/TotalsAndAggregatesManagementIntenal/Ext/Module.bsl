///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Internal

// Calculates totals of all accounting registers and accumulations for which they are enabled.
Procedure CalculateTotals() Export
	
	SessionDate = CurrentSessionDate();
	AccumulationRegisterPeriod  = EndOfMonth(AddMonth(SessionDate, -1)); // Last month end.
	AccountingRegisterPeriod = EndOfMonth(SessionDate); // End of the current month.
	
	Cache = SplitCheckCache();
	
	// Totals calculation for accumulation registers.
	BalanceKind = Metadata.ObjectProperties.AccumulationRegisterType.Balance;
	For Each MetadataRegister In Metadata.AccumulationRegisters Do
		If MetadataRegister.RegisterType <> BalanceKind Then
			Continue;
		EndIf;
		If Not MetadataObjectAvailableOnSplit(Cache, MetadataRegister) Then
			Continue;
		EndIf;
		AccumulationRegisterManager = AccumulationRegisters[MetadataRegister.Name];
		If AccumulationRegisterManager.GetMaxTotalsPeriod() >= AccumulationRegisterPeriod Then
			Continue;
		EndIf;
		AccumulationRegisterManager.SetMaxTotalsPeriod(AccumulationRegisterPeriod);
		If Not AccumulationRegisterManager.GetTotalsUsing()
			Or Not AccumulationRegisterManager.GetPresentTotalsUsing() Then
			Continue;
		EndIf;
		AccumulationRegisterManager.RecalcPresentTotals();
	EndDo;
	
	// Totals calculation for accounting registers.
	For Each MetadataRegister In Metadata.AccountingRegisters Do
		If Not MetadataObjectAvailableOnSplit(Cache, MetadataRegister) Then
			Continue;
		EndIf;
		AccountingRegisterManager = AccountingRegisters[MetadataRegister.Name];
		If AccountingRegisterManager.GetTotalsPeriod() >= AccountingRegisterPeriod Then
			Continue;
		EndIf;
		AccountingRegisterManager.SetMaxTotalsPeriod(AccountingRegisterPeriod);
		If Not AccountingRegisterManager.GetTotalsUsing()
			Or Not AccountingRegisterManager.GetPresentTotalsUsing() Then
			Continue;
		EndIf;
		AccountingRegisterManager.RecalcPresentTotals();
	EndDo;
	
	// Data registration.
	If LocalFileOperationMode() Then
		TotalsParameters = TotalsAndAggregatesParameters();
		TotalsParameters.TotalsCalculationDate = BegOfMonth(SessionDate);
		WriteTotalsAndAggregatesParameters(TotalsParameters);
	EndIf;
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Configuration subsystems event handlers.

// See InfobaseUpdateSSL.OnAddUpdateHandlers. 
Procedure OnAddUpdateHandlers(Handlers) Export
	
	Handler = Handlers.Add();
	Handler.InitialFilling = True;
	Handler.Version              = "2.4.1.1";
	Handler.Procedure           = "TotalsAndAggregatesManagementIntenal.UpdateScheduledJobUsage";
	Handler.ExecutionMode     = "Seamless";
	Handler.ID       = New UUID("16ec32f9-d68f-4283-9e6f-924a8655d2e4");
	Handler.Comment         =
		NStr("ru = 'Включает или отключает обновление и перестроение агрегатов по расписанию,
		|в зависимости от того, есть ли в программе регистры с агрегатами.'; 
		|en = 'Enables or disables update and rebuilding of aggregates according to schedule,
		|depending on whether there are registers with aggregates in the application.'; 
		|pl = 'Enables or disables update and rebuilding of aggregates according to schedule,
		|depending on whether there are registers with aggregates in the application.';
		|de = 'Enables or disables update and rebuilding of aggregates according to schedule,
		|depending on whether there are registers with aggregates in the application.';
		|ro = 'Enables or disables update and rebuilding of aggregates according to schedule,
		|depending on whether there are registers with aggregates in the application.';
		|tr = 'Enables or disables update and rebuilding of aggregates according to schedule,
		|depending on whether there are registers with aggregates in the application.'; 
		|es_ES = 'Enables or disables update and rebuilding of aggregates according to schedule,
		|depending on whether there are registers with aggregates in the application.'");
	
EndProcedure

// See InfobaseUpdateSSL.AfterUpdateInfobase. 
Procedure AfterUpdateInfobase(Val PreviousVersion, Val CurrentVersion,
		Val CompletedHandlers, OutputUpdatesDetails, ExclusiveMode) Export
	
	If NOT LocalFileOperationMode() Then
		Return;
	EndIf;
	
	// These actions must be performed after all update handlers are complete as they can change the 
	// state or usage of totals and aggregates.
	
	GenerateTotalsAndAggregatesParameters();
	
EndProcedure

// See JobsQueueOverridable.OnGetTemplatesList. 
Procedure OnGetTemplateList(JobTemplates) Export
	
	JobTemplates.Add("AggregatesUpdate");
	JobTemplates.Add("AggregatesRebuild");
	JobTemplates.Add("TotalsPeriodSetup");
	
EndProcedure

// See ToDoListOverridable.OnDetermineToDoListHandlers 
Procedure OnFillToDoList(ToDoList) Export
	If Not LocalFileOperationMode() Then
		Return;
	EndIf;
	
	ProcessMetadata = Metadata.DataProcessors.ShiftTotalsBoundary;
	If Not AccessRight("Use", ProcessMetadata) Then
		Return;
	EndIf;
	
	ProcessFullName = ProcessMetadata.FullName();
	
	ModuleToDoListServer = Common.CommonModule("ToDoListServer");
	Sections = ModuleToDoListServer.SectionsForObject(ProcessFullName);
	
	Prototype = New Structure("HasToDoItems, Important, Form, Presentation, ToolTip");
	Prototype.HasToDoItems = MustMoveTotalsBorder();
	Prototype.Important   = True;
	Prototype.Form    = ProcessFullName + ".Form";
	Prototype.Presentation = NStr("ru = 'Оптимизировать программу'; en = 'Optimize application'; pl = 'Optimize application';de = 'Optimize application';ro = 'Optimize application';tr = 'Optimize application'; es_ES = 'Optimize application'");
	Prototype.ToolTip     = NStr("ru = 'Ускорить проведение документов и формирование отчетов.
		|Обязательная ежемесячная процедура, может занять некоторое время.'; 
		|en = 'Speed up document posting and report generation.
		|Required monthly procedure, this might take a while.'; 
		|pl = 'Speed up document posting and report generation.
		|Required monthly procedure, this might take a while.';
		|de = 'Speed up document posting and report generation.
		|Required monthly procedure, this might take a while.';
		|ro = 'Speed up document posting and report generation.
		|Required monthly procedure, this might take a while.';
		|tr = 'Speed up document posting and report generation.
		|Required monthly procedure, this might take a while.'; 
		|es_ES = 'Speed up document posting and report generation.
		|Required monthly procedure, this might take a while.'");
	
	For Each Section In Sections Do
		ToDoItem = ToDoList.Add();
		ToDoItem.ID  = StrReplace(Prototype.Form, ".", "") + StrReplace(Section.FullName(), ".", "");
		ToDoItem.Owner       = Section;
		FillPropertyValues(ToDoItem, Prototype);
	EndDo;
	
EndProcedure

#EndRegion

#Region Private

////////////////////////////////////////////////////////////////////////////////
// Scheduled job execution.

// TotalsPeriodSetup scheduled job handler.
Procedure TotalsPeriodSetupJobHandler() Export
	
	Common.OnStartExecuteScheduledJob(Metadata.ScheduledJobs.TotalsPeriodSetup);
	
	CalculateTotals();
	
EndProcedure

// UpdateAggregates scheduled job handler.
Procedure UpdateAggregatesJobHandler() Export
	
	Common.OnStartExecuteScheduledJob(Metadata.ScheduledJobs.AggregatesUpdate);
	
	UpdateAggregates();
	
EndProcedure

// RebuildAggregates scheduled job handler.
Procedure RebuildAggregatesJobHandler() Export
	
	Common.OnStartExecuteScheduledJob(Metadata.ScheduledJobs.AggregatesRebuild);
	
	RebuildAggregates();
	
EndProcedure

// For internal use.
Procedure UpdateAggregates()
	
	Cache = SplitCheckCache();
	
	// Aggregates update for turnover accumulation registers.
	TurnoversKind = Metadata.ObjectProperties.AccumulationRegisterType.Turnovers;
	For Each MetadataRegister In Metadata.AccumulationRegisters Do
		If MetadataRegister.RegisterType <> TurnoversKind Then
			Continue;
		EndIf;
		If Not MetadataObjectAvailableOnSplit(Cache, MetadataRegister) Then
			Continue;
		EndIf;
		AccumulationRegisterManager = AccumulationRegisters[MetadataRegister.Name];
		If Not AccumulationRegisterManager.GetAggregatesMode()
			Or Not AccumulationRegisterManager.GetAggregatesUsing() Then
			Continue;
		EndIf;
		// Aggregates update.
		AccumulationRegisterManager.UpdateAggregates();
	EndDo;
EndProcedure

// For internal use.
Procedure RebuildAggregates()
	
	Cache = SplitCheckCache();
	
	// Aggregates rebuild for turnover accumulation registers.
	TurnoversKind = Metadata.ObjectProperties.AccumulationRegisterType.Turnovers;
	For Each MetadataRegister In Metadata.AccumulationRegisters Do
		If MetadataRegister.RegisterType <> TurnoversKind Then
			Continue;
		EndIf;
		If Not MetadataObjectAvailableOnSplit(Cache, MetadataRegister) Then
			Continue;
		EndIf;
		AccumulationRegisterManager = AccumulationRegisters[MetadataRegister.Name];
		If Not AccumulationRegisterManager.GetAggregatesMode()
			Or Not AccumulationRegisterManager.GetAggregatesUsing() Then
			Continue;
		EndIf;
		// Rebuild aggregates.
		AccumulationRegisterManager.RebuildAggregatesUsing();
	EndDo;
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// For file mode operation.

// Returns True if the infobase operates in the file mode and split is disabled.
Function LocalFileOperationMode()
	Return Common.FileInfobase() AND NOT Common.DataSeparationEnabled();
EndFunction

// Checks whether totals and aggregates are actual. Returns True if there are no registers.
Function MustMoveTotalsBorder() Export
	Parameters = TotalsAndAggregatesParameters();
	Return Parameters.HasTotalsRegisters AND AddMonth(Parameters.TotalsCalculationDate, 2) < CurrentSessionDate();
EndFunction

// Gets a value of the TotalsAndAggregatesParameters constant.
Function TotalsAndAggregatesParameters()
	SetPrivilegedMode(True);
	Parameters = Constants.TotalsAndAggregatesParameters.Get().Get();
	If TypeOf(Parameters) <> Type("Structure") OR NOT Parameters.Property("HasTotalsRegisters") Then
		Parameters = GenerateTotalsAndAggregatesParameters();
	EndIf;
	Return Parameters;
EndFunction

// Overwrites the TotalsAndAggregatesParameters constant.
Function GenerateTotalsAndAggregatesParameters()
	Parameters = New Structure;
	Parameters.Insert("HasTotalsRegisters", False);
	Parameters.Insert("TotalsCalculationDate",  '39991231235959'); // 12/1/3999 11:59:59 PM, the maximum date.
	
	BalanceKind = Metadata.ObjectProperties.AccumulationRegisterType.Balance;
	For Each MetadataRegister In Metadata.AccumulationRegisters Do
		If MetadataRegister.RegisterType = BalanceKind Then
			Date = AccumulationRegisters[MetadataRegister.Name].GetMaxTotalsPeriod() + 1;
			Parameters.HasTotalsRegisters = True;
			Parameters.TotalsCalculationDate  = Min(Parameters.TotalsCalculationDate, Date);
		EndIf;
	EndDo;
	
	If NOT Parameters.HasTotalsRegisters Then
		Parameters.Insert("TotalsCalculationDate", '00010101');
	EndIf;
	
	WriteTotalsAndAggregatesParameters(Parameters);
	
	Return Parameters;
EndFunction

// Writes a value of the TotalsAndAggregatesParameters constant.
Procedure WriteTotalsAndAggregatesParameters(Parameters) Export
	Constants.TotalsAndAggregatesParameters.Set(New ValueStorage(Parameters));
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Updating an infobase.

// [2.3.4.7] Updates usage of UpdateAggregates and RebuildAggregates scheduled jobs.
Procedure UpdateScheduledJobUsage() Export
	// UpdateAggregates and RebuildAggregates scheduled jobs.
	HasRegistersWithAggregates = HasRegistersWithAggregates();
	UpdateScheduledJob(Metadata.ScheduledJobs.AggregatesUpdate, HasRegistersWithAggregates);
	UpdateScheduledJob(Metadata.ScheduledJobs.AggregatesRebuild, HasRegistersWithAggregates);
	
	// TotalsPeriodSetup scheduled job.
	UpdateScheduledJob(Metadata.ScheduledJobs.TotalsPeriodSetup, True);
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Other

// Secondary for UpdateScheduledJobsUsage procedure.
Procedure UpdateScheduledJob(ScheduledJobMetadata, Usage)
	FoundItems = ScheduledJobsServer.FindJobs(New Structure("Metadata", ScheduledJobMetadata));
	For Each Job In FoundItems Do
		Changes = New Structure("Use", Usage);
		// Change the schedule only if it was not set and only out of the box.
		If Not ScheduleFilled(Job.Schedule)
			AND Not Common.DataSeparationEnabled() Then
			Changes.Insert("Schedule", DefaultSchedule(ScheduledJobMetadata));
		EndIf;
		ScheduledJobsServer.ChangeJob(Job, Changes);
	EndDo;
EndProcedure

// Defines whether the job schedule is set.
//
// Parameters:
//   Schedule - JobSchedule - a job schedule.
//
// Returns:
//   Boolean - True if the job schedule is set.
//
Function ScheduleFilled(Schedule)
	Return Schedule <> Undefined
		AND String(Schedule) <> String(New JobSchedule);
EndFunction

// Returns the default job schedule.
//   The function is used instead of MetadataObject: ScheduledJob.Schedule property as its value is 
//   always set to Undefined.
Function DefaultSchedule(ScheduledJobMetadata)
	Schedule = New JobSchedule;
	Schedule.DaysRepeatPeriod = 1;
	If ScheduledJobMetadata = Metadata.ScheduledJobs.AggregatesUpdate Then
		Schedule.BeginTime = Date(1, 1, 1, 01, 00, 00);
		AddDetailedSchedule(Schedule, "BeginTime", Date(1, 1, 1, 01, 00, 00));
		AddDetailedSchedule(Schedule, "BeginTime", Date(1, 1, 1, 14, 00, 00));
	ElsIf ScheduledJobMetadata = Metadata.ScheduledJobs.AggregatesRebuild Then
		Schedule.BeginTime = Date(1, 1, 1, 03, 00, 00);
		SetWeekDays(Schedule, "6");
	ElsIf ScheduledJobMetadata = Metadata.ScheduledJobs.TotalsPeriodSetup Then
		Schedule.BeginTime = Date(1, 1, 1, 01, 00, 00);
		Schedule.DayInMonth = 5;
	Else
		Return Undefined;
	EndIf;
	Return Schedule;
EndFunction

// Secondary for the DefaultSchedule function.
Procedure AddDetailedSchedule(Schedule, varKey, Value)
	DetailedSchedule = New JobSchedule;
	FillPropertyValues(DetailedSchedule, New Structure(varKey, Value));
	Array = Schedule.DetailedDailySchedules;
	Array.Add(DetailedSchedule);
	Schedule.DetailedDailySchedules = Array;
EndProcedure

// Secondary for the DefaultSchedule function.
Procedure SetWeekDays(Schedule, WeekDaysInRow)
	WeekDays = New Array;
	RowsArray = StrSplit(WeekDaysInRow, ",", False);
	For Each WeekDayNumberRow In RowsArray Do
		WeekDays.Add(Number(TrimAll(WeekDayNumberRow)));
	EndDo;
	Schedule.WeekDays = WeekDays;
EndProcedure

Function SplitCheckCache()
	Cache = New Structure;
	Cache.Insert("SaaSModel", Common.DataSeparationEnabled());
	If Cache.SaaSModel Then
		If Common.SubsystemExists("StandardSubsystems.SaaS") Then
			ModuleSaaS = Common.CommonModule("SaaS");
			MainDataSeparator = ModuleSaaS.MainDataSeparator();
			AuxiliaryDataSeparator = ModuleSaaS.AuxiliaryDataSeparator();
		Else
			MainDataSeparator = Undefined;
			AuxiliaryDataSeparator = Undefined;
		EndIf;
		
		Cache.Insert("InDataArea",                   Common.SeparatedDataUsageAvailable());
		Cache.Insert("MainDataSeparator",        MainDataSeparator);
		Cache.Insert("AuxiliaryDataSeparator", AuxiliaryDataSeparator);
	EndIf;
	Return Cache;
EndFunction

Function MetadataObjectAvailableOnSplit(Cache, MetadataObject)
	If Not Cache.SaaSModel Then
		Return True;
	EndIf;
	
	If Common.SubsystemExists("StandardSubsystems.SaaS") Then
		ModuleSaaS = Common.CommonModule("SaaS");
		IsSeparatedMetadataObject = ModuleSaaS.IsSeparatedMetadataObject(MetadataObject);
	Else
		IsSeparatedMetadataObject = False;
	EndIf;
	
	Return Cache.InDataArea = IsSeparatedMetadataObject;
EndFunction

Function HasRegistersWithAggregates()
	Cache = SplitCheckCache();
	TurnoversKind = Metadata.ObjectProperties.AccumulationRegisterType.Turnovers;
	For Each MetadataRegister In Metadata.AccumulationRegisters Do
		If MetadataRegister.RegisterType <> TurnoversKind Then
			Continue;
		EndIf;
		If Not MetadataObjectAvailableOnSplit(Cache, MetadataRegister) Then
			Continue;
		EndIf;
		AccumulationRegisterManager = AccumulationRegisters[MetadataRegister.Name];
		If Not AccumulationRegisterManager.GetAggregatesMode()
			Or Not AccumulationRegisterManager.GetAggregatesUsing() Then
			Continue;
		EndIf;
		Return True;
	EndDo;
	
	Return False;
EndFunction

#EndRegion
