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
	ReportSettings.Details = NStr("ru = 'Анализ зависших задач, которые не могут быть выполнены, так как у них не назначены исполнители.'; en = 'Unassigned tasks analysis (tasks not assigned to any users).'; pl = 'Unassigned tasks analysis (tasks not assigned to any users).';de = 'Unassigned tasks analysis (tasks not assigned to any users).';ro = 'Unassigned tasks analysis (tasks not assigned to any users).';tr = 'Unassigned tasks analysis (tasks not assigned to any users).'; es_ES = 'Unassigned tasks analysis (tasks not assigned to any users).'");
	
	OptionSettings = ModuleReportsOptions.OptionDetails(Settings, ReportSettings, "UnassignedTasksSummary");
	OptionSettings.Details = NStr("ru = 'Сводка по количеству зависших задач, назначенных на роли, для которых не задано ни одного исполнителя.'; en = 'Unassigned tasks summary (tasks assigned to blank roles).'; pl = 'Unassigned tasks summary (tasks assigned to blank roles).';de = 'Unassigned tasks summary (tasks assigned to blank roles).';ro = 'Unassigned tasks summary (tasks assigned to blank roles).';tr = 'Unassigned tasks summary (tasks assigned to blank roles).'; es_ES = 'Unassigned tasks summary (tasks assigned to blank roles).'");
	
	OptionSettings = ModuleReportsOptions.OptionDetails(Settings, ReportSettings, "UnassignedTasksByPerformers");
	OptionSettings.Details = NStr("ru = 'Список зависших задач, назначенных на роли, для которых не задано ни одного исполнителя.'; en = 'Unassigned tasks (tasks assigned to blank roles).'; pl = 'Unassigned tasks (tasks assigned to blank roles).';de = 'Unassigned tasks (tasks assigned to blank roles).';ro = 'Unassigned tasks (tasks assigned to blank roles).';tr = 'Unassigned tasks (tasks assigned to blank roles).'; es_ES = 'Unassigned tasks (tasks assigned to blank roles).'");
	
	OptionSettings = ModuleReportsOptions.OptionDetails(Settings, ReportSettings, "UnassignedTasksByAddressingObjects");
	OptionSettings.Details = NStr("ru = 'Список зависших задач по объектам адресации.'; en = 'Unassigned tasks by addressing objects.'; pl = 'Unassigned tasks by addressing objects.';de = 'Unassigned tasks by addressing objects.';ro = 'Unassigned tasks by addressing objects.';tr = 'Unassigned tasks by addressing objects.'; es_ES = 'Unassigned tasks by addressing objects.'");
	
	OptionSettings = ModuleReportsOptions.OptionDetails(Settings, ReportSettings, "OverdueTasks");
	OptionSettings.Details = NStr("ru = 'Список просроченных и зависших задач, которые не могут быть выполнены, так как у них не назначены исполнители.'; en = 'Unassigned and overdue tasks (tasks not assigned to any users).'; pl = 'Unassigned and overdue tasks (tasks not assigned to any users).';de = 'Unassigned and overdue tasks (tasks not assigned to any users).';ro = 'Unassigned and overdue tasks (tasks not assigned to any users).';tr = 'Unassigned and overdue tasks (tasks not assigned to any users).'; es_ES = 'Unassigned and overdue tasks (tasks not assigned to any users).'");
EndProcedure

// End StandardSubsystems.ReportsOptions

#EndRegion

#EndRegion

#EndIf