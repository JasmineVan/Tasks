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
	ModuleReportsOptions.SetOutputModeInReportPanes(Settings, ReportSettings, False);
	
	ReportSettings.DefineFormSettings = True;
	
	OptionSettings = ModuleReportsOptions.OptionDetails(Settings, ReportSettings, "Main");
	OptionSettings.Enabled = False;
	OptionSettings.Details = NStr("ru = 'Поиск мест использования объектов приложения.'; en = 'Search for usage locations.'; pl = 'Wyszukiwanie lokalizacji wykorzystania obiektów aplikacji.';de = 'Suchen Sie nach Verwendungsorten von Anwendungsobjekten.';ro = 'Căutarea locurilor de utilizare a obiectelor aplicației.';tr = 'Uygulama nesnelerinin kullanım yerlerini arayın.'; es_ES = 'Búsqueda de las ubicaciones de uso de los objetos de la aplicación.'");
EndProcedure

// It is used for calling from the ReportsOptionsOverridable.BeforeAddReportsCommands procedure.
// 
// Parameters:
//   ReportsCommands - ValueTable - a table of commands to be shown in the submenu.
//                                      See ReportsOptionsOverridable.BeforeAddReportsCommands. 
//
// Returns:
//   ValueTableRow, Undefined - an added command or Undefined if there are no rights to view the report.
//
Function AddUsageInstanceCommand(ReportCommands) Export
	If Not AccessRight("View", Metadata.Reports.SearchForReferences) Then
		Return Undefined;
	EndIf;
	Command = ReportCommands.Add();
	Command.Presentation      = NStr("ru = 'Места использования'; en = 'Usage locations'; pl = 'Liczba lokalizacji użytkowania';de = 'Verwendungsstandorte';ro = 'Locuri de utilizare';tr = 'Kullanım yerleri'; es_ES = 'Ubicaciones de uso'");
	Command.MultipleChoice = True;
	Command.Importance           = "SeeAlso";
	Command.FormParameterName  = "Filter.RefSet";
	Command.VariantKey       = "Main";
	Command.Manager           = "Report.SearchForReferences";
	Return Command;
EndFunction

// End StandardSubsystems.ReportsOptions

#EndRegion

#EndRegion

#EndIf