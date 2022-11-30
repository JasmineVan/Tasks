///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

#Region ForCallsFromOtherSubsystems

// StandardSubsystems.ReportsOptions

// See ReportsOptionsOverridable.CustomizeReportsOptions. 
//
Procedure CustomizeReportOptions(Settings, ReportSettings) Export
	ModuleReportsOptions = Common.CommonModule("ReportsOptions");
	ReportSettings.Details = NStr("ru = 'Список и сводная статистика по выполнению заданий.'; en = 'Jobs and job execution summary.'; pl = 'Jobs and job execution summary.';de = 'Jobs and job execution summary.';ro = 'Jobs and job execution summary.';tr = 'Jobs and job execution summary.'; es_ES = 'Jobs and job execution summary.'");
	
	OptionSettings = ModuleReportsOptions.OptionDetails(Settings, ReportSettings, "JobsList");
	OptionSettings.Details = NStr("ru = 'Список всех заданий за указанный период.'; en = 'All jobs for the specified period.'; pl = 'All jobs for the specified period.';de = 'All jobs for the specified period.';ro = 'All jobs for the specified period.';tr = 'All jobs for the specified period.'; es_ES = 'All jobs for the specified period.'");
	
	OptionSettings = ModuleReportsOptions.OptionDetails(Settings, ReportSettings, "JobsStatistics");
	OptionSettings.Details = NStr("ru = 'Сводная диаграмма по всем выполненным, отмененным заданиям и заданиям в работе.'; en = 'Pivot chart of all tasks that are completed, canceled, or in progress.'; pl = 'Pivot chart of all tasks that are completed, canceled, or in progress.';de = 'Pivot chart of all tasks that are completed, canceled, or in progress.';ro = 'Pivot chart of all tasks that are completed, canceled, or in progress.';tr = 'Pivot chart of all tasks that are completed, canceled, or in progress.'; es_ES = 'Pivot chart of all tasks that are completed, canceled, or in progress.'");
	
	OptionSettings = ModuleReportsOptions.OptionDetails(Settings, ReportSettings, "CheckExecutionCyclesStatistics");
	OptionSettings.Details = NStr("ru = 'Топ 10 авторов по среднему количеству перепроверок заданий.'; en = 'Top 10 authors by average time of job counterchecks.'; pl = 'Top 10 authors by average time of job counterchecks.';de = 'Top 10 authors by average time of job counterchecks.';ro = 'Top 10 authors by average time of job counterchecks.';tr = 'Top 10 authors by average time of job counterchecks.'; es_ES = 'Top 10 authors by average time of job counterchecks.'");
	
	OptionSettings = ModuleReportsOptions.OptionDetails(Settings, ReportSettings, "DurationStatistics");
	OptionSettings.Details = NStr("ru = 'Топ 10 авторов по средней длительности выполнения заданий.'; en = 'Top 10 authors by average time of job completion.'; pl = 'Top 10 authors by average time of job completion.';de = 'Top 10 authors by average time of job completion.';ro = 'Top 10 authors by average time of job completion.';tr = 'Top 10 authors by average time of job completion.'; es_ES = 'Top 10 authors by average time of job completion.'");
EndProcedure

// End StandardSubsystems.ReportsOptions

#EndRegion

#EndRegion

#EndIf