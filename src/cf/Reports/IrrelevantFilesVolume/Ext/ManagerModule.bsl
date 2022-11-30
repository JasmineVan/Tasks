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
	
	OptionSettings = ModuleReportsOptions.OptionDetails(Settings, ReportSettings, "IrrelevantFilesVolumeByOwners");
	OptionSettings.Details = NStr("ru = 'Позволяет получить информацию об объеме данных, занятых ненужными файлами.'; en = 'Total size of obsolete files.'; pl = 'Umożliwia uzyskanie informacji o ilości danych, zajmowanych przez niepotrzebne pliki.';de = 'Ermöglicht es Ihnen, Informationen über die Datenmenge zu erhalten, die durch unnötige Dateien belegt ist.';ro = 'Puteți obține informații despre volumul de date ocupat de fișiere nedorite.';tr = 'Gereksiz dosyalar ile doldurulmuş veri hacmi hakkında bilgi alınmasına imkan sağlar.'; es_ES = 'Permite obtener la información de volumen de datos ocupados por los archivos no necesarios.'");
	
EndProcedure

// End StandardSubsystems.ReportsOptions

#EndRegion

#EndRegion

#EndIf