///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Public

// Defines the sections where the additional data processor calling command is available.
// Add the metadata of sections where the commands are available to the Sections array.
// 
// For the start page, specify AdditionalReportsAndDataProcessorsClientServer.StartPageName.
//
// Parameters:
//   Sections - Array - sections where commands calling additional data processors are available.
//       * MetadataObject: Subsystem - section (subsystem) metadata.
//       * String - for the start page.
//
Procedure GetSectionsWithAdditionalDataProcessors(Sections) Export
	
	
	
EndProcedure

// Defines the sections where the command that opens additional reports is available.
// Add the metadata of sections where the commands are available to the Sections array.
// 
// For the start page, specify AdditionalReportsAndDataProcessorsClientServer.StartPageName.
//
// Parameters:
//   Sections - Array - sections where commands for calling additional reports are available.
//       * MetadataObject: Subsystem - section (subsystem) metadata.
//       * String - for the start page.
//
Procedure GetSectionsWithAdditionalReports(Sections) Export
	
	
	
EndProcedure

#EndRegion
