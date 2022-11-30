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
	ReportSettings.Details = NStr("ru = 'Список задач, выполненных с нарушением сроков, по исполнителям.'; en = 'Tasks completed with delay by assignee.'; pl = 'Tasks completed with delay by assignee.';de = 'Tasks completed with delay by assignee.';ro = 'Tasks completed with delay by assignee.';tr = 'Tasks completed with delay by assignee.'; es_ES = 'Tasks completed with delay by assignee.'");
	
	OptionSettings = ModuleReportsOptions.OptionDetails(Settings, ReportSettings, "TasksCompletedWithDeadlineViolation");
	OptionSettings.Details = NStr("ru = 'Список задач, выполненных с нарушением сроков, по исполнителям.'; en = 'Tasks completed with delay by assignee.'; pl = 'Tasks completed with delay by assignee.';de = 'Tasks completed with delay by assignee.';ro = 'Tasks completed with delay by assignee.';tr = 'Tasks completed with delay by assignee.'; es_ES = 'Tasks completed with delay by assignee.'");
EndProcedure

// End StandardSubsystems.ReportsOptions

#EndRegion

#EndRegion

#EndIf