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
	ReportSettings.Details = NStr("ru = 'Список и сводная статистика по задачам.'; en = 'Task list and summary.'; pl = 'Task list and summary.';de = 'Task list and summary.';ro = 'Task list and summary.';tr = 'Task list and summary.'; es_ES = 'Task list and summary.'");
	
	OptionSettings = ModuleReportsOptions.OptionDetails(Settings, ReportSettings, "CurrentTasks");
	OptionSettings.Details = NStr("ru = 'Список всех задач в работе к заданному сроку.'; en = 'All tasks in progress by the specified due date.'; pl = 'All tasks in progress by the specified due date.';de = 'All tasks in progress by the specified due date.';ro = 'All tasks in progress by the specified due date.';tr = 'All tasks in progress by the specified due date.'; es_ES = 'All tasks in progress by the specified due date.'");
	
	OptionSettings = ModuleReportsOptions.OptionDetails(Settings, ReportSettings, "PerformerDisciplineSummary");
	OptionSettings.Details = NStr("ru = 'Сводка по количеству выполненных в срок и просроченных задачах у исполнителей.'; en = 'Overdue tasks and tasks completed on schedule summary by assignee.'; pl = 'Overdue tasks and tasks completed on schedule summary by assignee.';de = 'Overdue tasks and tasks completed on schedule summary by assignee.';ro = 'Overdue tasks and tasks completed on schedule summary by assignee.';tr = 'Overdue tasks and tasks completed on schedule summary by assignee.'; es_ES = 'Overdue tasks and tasks completed on schedule summary by assignee.'");
EndProcedure

// End StandardSubsystems.ReportsOptions

#EndRegion

#EndRegion

#EndIf