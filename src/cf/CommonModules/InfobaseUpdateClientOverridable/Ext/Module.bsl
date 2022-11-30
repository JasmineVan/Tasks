///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Public

// Is called by following a link or double-clicking a cell of a spreadsheet document that contains 
// the change log (common template: ShowChangeHistory).
//
// Parameters:
//   Area - SpreadsheetDocumentRange - a document area that was clicked.
//             
//
Procedure OnClickUpdateDetailsDocumentHyperlink(Val Area) Export
	
	

EndProcedure

// Is called in the BeforeStart handler. Checks for an update to a current version of a program.
// 
//
// Parameters:
//  DataVersion - String - data version of a main configuration that is to be updated (from the 
//                          SubsystemVersions information register).
//
Procedure OnDetermineUpdateAvailability(Val DataVersion) Export
	
	
	
EndProcedure

#EndRegion
