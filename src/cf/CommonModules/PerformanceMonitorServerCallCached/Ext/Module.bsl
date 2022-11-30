///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Internal

// Checks whether performance measurement is required.
//
// Returns:
//  Boolean - True if measurements must be made, False otherwise.
//
Function RunPerformanceMeasurements() Export
	
	SetPrivilegedMode(True);
	Return Constants.RunPerformanceMeasurements.Get();
	
EndFunction

#EndRegion
