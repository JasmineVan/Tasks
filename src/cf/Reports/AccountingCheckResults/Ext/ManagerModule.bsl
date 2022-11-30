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
Procedure CustomizeReportOptions(Settings, ReportSettings) Export
	
	ModuleReportsOptions = Common.CommonModule("ReportsOptions");
	ModuleReportsOptions.SetOutputModeInReportPanes(Settings, ReportSettings, False);
	
	ReportSettings.DefineFormSettings = True;
	
	OptionSettings_Main = ReportsOptions.OptionDetails(Settings, ReportSettings, "Main");
	OptionSettings_Main.Details = NStr("ru = 'Выводит результаты проверок учета.'; en = 'Displays the accounting audit results.'; pl = 'Displays the accounting audit results.';de = 'Displays the accounting audit results.';ro = 'Displays the accounting audit results.';tr = 'Displays the accounting audit results.'; es_ES = 'Displays the accounting audit results.'");
	OptionSettings_Main.SearchSettings.Keywords = NStr("ru = 'Отчет о проблемах объекта'; en = 'Report on object issues'; pl = 'Report on object issues';de = 'Report on object issues';ro = 'Report on object issues';tr = 'Report on object issues'; es_ES = 'Report on object issues'");
	
EndProcedure

// See ReportsOptionsOverridable.CustomizeReportsOptions. 
Procedure OnSetUpReportsOptions(Settings) Export
	
	ReportsOptions.CustomizeReportInManagerModule(Settings, Metadata.Reports.AccountingCheckResults);
	ReportsOptions.ReportDetails(Settings, Metadata.Reports.AccountingCheckResults).Enabled = False;
	
EndProcedure

// See ReportsOptionsOverridable.BeforeAddReportsCommands. 
Procedure BeforeAddReportCommands(ReportsCommands, FormSettings, StandardProcessing) Export
	
	If Not AccessRight("View", Metadata.Reports.AccountingCheckResults) Then
		Return;
	EndIf;
	
	If Not StrStartsWith(FormSettings.FormName, Metadata.Catalogs.AccountingCheckRules.FullName()) Then
		Return;
	EndIf;
	
	Command                   = ReportsCommands.Add();
	Command.Presentation     = NStr("ru = 'Результаты проверки учета'; en = 'Accounting audit results'; pl = 'Accounting audit results';de = 'Accounting audit results';ro = 'Accounting audit results';tr = 'Accounting audit results'; es_ES = 'Accounting audit results'");
	Command.FormParameterName = "";
	Command.Importance          = "SeeAlso";
	Command.VariantKey      = "Main";
	Command.Manager          = "Report.AccountingCheckResults";
	
EndProcedure

// End StandardSubsystems.ReportsOptions

#EndRegion

#EndRegion

#EndIf
