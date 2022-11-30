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
	ReportSettings.Details = NStr("ru = 'Список задач, которые должны быть выполнены к указанной дате.'; en = 'Tasks that must be completed by the specified due date.'; pl = 'Tasks that must be completed by the specified due date.';de = 'Tasks that must be completed by the specified due date.';ro = 'Tasks that must be completed by the specified due date.';tr = 'Tasks that must be completed by the specified due date.'; es_ES = 'Tasks that must be completed by the specified due date.'");
	
	OptionSettings = ModuleReportsOptions.OptionDetails(Settings, ReportSettings, "ExpiringTasksOnDate");
	OptionSettings.Details = NStr("ru = 'Список задач, которые должны быть выполнены к указанной дате.'; en = 'Tasks that must be completed by the specified due date.'; pl = 'Tasks that must be completed by the specified due date.';de = 'Tasks that must be completed by the specified due date.';ro = 'Tasks that must be completed by the specified due date.';tr = 'Tasks that must be completed by the specified due date.'; es_ES = 'Tasks that must be completed by the specified due date.'");
EndProcedure

// End StandardSubsystems.ReportsOptions

#EndRegion

#EndRegion

#EndIf