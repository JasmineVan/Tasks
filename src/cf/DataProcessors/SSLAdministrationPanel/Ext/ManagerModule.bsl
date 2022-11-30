///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Internal

////////////////////////////////////////////////////////////////////////////////
// Configuration subsystems event handlers.

// See CommonOverridable.OnAddMetadataObjectsRenaming. 
Procedure OnAddMetadataObjectsRenaming(Total) Export
	
	Library = "StandardSubsystems";
	
	Common.AddRenaming(Total,
		"2.2.1.12",
		"Subsystem.SettingsAndAdministration",
		"Subsystem.Administration",
		Library);
	
EndProcedure

// Defines sections, where the report panel is available.
//   For more information, see details of the UsedSections procedure of the ReportsOptions common 
//   module.
//
Procedure OnDefineSectionsWithReportOptions(Sections) Export
	
	Sections.Add(Metadata.Subsystems.Administration, NStr("ru = 'Отчеты администратора'; en = 'Administrator''s reports'; pl = 'Raporty dla administratora';de = 'Administrator-Berichte';ro = 'Rapoartele administratorului';tr = 'Yönetici raporları'; es_ES = 'Informes del administrador'"));
	
EndProcedure

// See AdditionalReportsAndDataProcessorsOverridable.DefineSectionsWithAdditionalReports. 
Procedure OnDefineSectionsWithAdditionalReports(Sections) Export
	
	Sections.Add(Metadata.Subsystems.Administration);
	
EndProcedure

// See AdditionalReportsAndDataProcessorsOverridable.DefineSectionsWithAdditionalDataProcessors. 
Procedure OnDefineSectionsWithAdditionalDataProcessors(Sections) Export
	
	Sections.Add(Metadata.Subsystems.Administration);
	
EndProcedure

#EndRegion

#EndIf
