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
	
	ReportsOptionsAvailable = PerformanceMonitorInternal.SubsystemExists("StandardSubsystems.ReportsOptions");
	If ReportsOptionsAvailable Then
		ModuleReportsOptions = PerformanceMonitorInternal.CommonModule("ReportsOptions");
		
		OptionSettings = ModuleReportsOptions.OptionDetails(Settings, ReportSettings, "PerformanceMonitorByKeyOperations");
		OptionSettings.Details = 
			NStr("ru = 'Предоставляет информацию об оценке производительности'; en = 'Provides data on performance assessment'; pl = 'Provides data on performance assessment';de = 'Provides data on performance assessment';ro = 'Provides data on performance assessment';tr = 'Provides data on performance assessment'; es_ES = 'Provides data on performance assessment'");
			
		OptionSettings = ModuleReportsOptions.OptionDetails(Settings, ReportSettings, "PerformanceMonitorComparison");
		OptionSettings.Details = 
			NStr("ru = 'Предоставляет информацию о сравнении оценки производительности за период'; en = 'Provides information on performance assessment comparison for a period'; pl = 'Provides information on performance assessment comparison for a period';de = 'Provides information on performance assessment comparison for a period';ro = 'Provides information on performance assessment comparison for a period';tr = 'Provides information on performance assessment comparison for a period'; es_ES = 'Provides information on performance assessment comparison for a period'");
			
		OptionSettings = ModuleReportsOptions.OptionDetails(Settings, ReportSettings, "PerformanceMonitorPeriodInColumns");
		OptionSettings.Details = 
			NStr("ru = 'Предоставляет информацию об оценке производительности в разрезе периодов. Периоды представлены в колонках'; en = 'Provides data on performance assessment by periods. Periods are displayed in columns'; pl = 'Provides data on performance assessment by periods. Periods are displayed in columns';de = 'Provides data on performance assessment by periods. Periods are displayed in columns';ro = 'Provides data on performance assessment by periods. Periods are displayed in columns';tr = 'Provides data on performance assessment by periods. Periods are displayed in columns'; es_ES = 'Provides data on performance assessment by periods. Periods are displayed in columns'");
	EndIf;
			
EndProcedure

// End StandardSubsystems.ReportsOptions

#EndRegion

#EndRegion

#EndIf
