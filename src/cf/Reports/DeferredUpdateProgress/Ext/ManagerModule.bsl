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
	
	OptionSettings = ModuleReportsOptions.OptionDetails(Settings, ReportSettings, "DeferredUpdateProgress");
	OptionSettings.Details = NStr("ru = 'Прогресс выполнения дополнительных процедур обработки данных.'; en = 'Progress of additional data processing procedures.'; pl = 'Postęp wykonania dodatkowych procedur przetwarzania danych.';de = 'Fortschritte bei zusätzlichen Datenverarbeitungsverfahren.';ro = 'Progresul executării procedurilor suplimentare de procesare a datelor.';tr = 'Ek veri işleme prosedürleri yürütülüyor.'; es_ES = 'El progreso de realizar los procedimientos adicionales del procesamiento de datos.'");
	OptionSettings.SearchSettings.Keywords = NStr("ru = 'Отложенное обновление'; en = 'Deferred update'; pl = 'Odroczona aktualizacja';de = 'Verzögerte Aktualisierung';ro = 'Actualizare amânată';tr = 'Gelecek döneme ait güncelleme'; es_ES = 'Actualización diferida'");
EndProcedure

// End StandardSubsystems.ReportsOptions

#EndRegion

#EndRegion

#EndIf