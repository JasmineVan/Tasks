///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Private

// Returns info on the last version check of the valid period-end closing dates.
//
// Returns:
//  Structure - with the following properties:
//   * Date - Date - date and time of the last valid date check.
//
Function LastCheckOfEffectiveClosingDatesVersion() Export
	
	Return New Structure("Date", '00010101');
	
EndFunction

#EndRegion
