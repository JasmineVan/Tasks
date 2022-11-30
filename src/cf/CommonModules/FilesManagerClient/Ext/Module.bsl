///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Public

#Region ObsoleteProceduresAndFunctions

////////////////////////////////////////////////////////////////////////////////
// Procedures and functions for working with scanner.

// Obsolete. Use FilesOperationsClient.OpenScannerSettingsForm.
// Opens the form of scanning settings.
Procedure OpenScanSettingForm() Export
	
	FilesOperationsClient.OpenScanSettingForm();
	
EndProcedure

#EndRegion

#EndRegion