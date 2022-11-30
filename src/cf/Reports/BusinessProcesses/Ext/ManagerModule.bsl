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
	ReportSettings.Details = NStr("ru = 'Список и сводная статистика по всем бизнес-процессам.'; en = 'Business process list and summary.'; pl = 'Business process list and summary.';de = 'Business process list and summary.';ro = 'Business process list and summary.';tr = 'Business process list and summary.'; es_ES = 'Business process list and summary.'");
	
	OptionSettings = ModuleReportsOptions.OptionDetails(Settings, ReportSettings, "BusinessProcessesList");
	OptionSettings.Details = NStr("ru = 'Список бизнес-процессов определенных видов за указанный интервал.'; en = 'Business processes of certain types for the specified period.'; pl = 'Business processes of certain types for the specified period.';de = 'Business processes of certain types for the specified period.';ro = 'Business processes of certain types for the specified period.';tr = 'Business processes of certain types for the specified period.'; es_ES = 'Business processes of certain types for the specified period.'");
	
	OptionSettings = ModuleReportsOptions.OptionDetails(Settings, ReportSettings, "StatisticsByKinds");
	OptionSettings.Details = NStr("ru = 'Сводная диаграмма по количеству активных и завершенных бизнес-процессов.'; en = 'Pivot chart of all active and completed business processes.'; pl = 'Pivot chart of all active and completed business processes.';de = 'Pivot chart of all active and completed business processes.';ro = 'Pivot chart of all active and completed business processes.';tr = 'Pivot chart of all active and completed business processes.'; es_ES = 'Pivot chart of all active and completed business processes.'");
EndProcedure

// End StandardSubsystems.ReportsOptions

#EndRegion

#EndRegion

#EndIf