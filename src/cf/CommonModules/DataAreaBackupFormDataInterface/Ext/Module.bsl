///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Private

Function GetSettingsFormParameters(Val DataArea) Export
	
	Parameters = Sales().GetSettingsFormParameters(DataArea);
	Parameters.Insert("DataArea", DataArea);
	
	Return Parameters;
	
EndFunction

Function GetAreaSettings(Val DataArea) Export
	
	Return Sales().GetAreaSettings(DataArea);
	
EndFunction

Procedure SetAreaSettings(Val DataArea, Val NewSettings, Val InitialSettings) Export
	
	Sales().SetAreaSettings(DataArea, NewSettings, InitialSettings);
	
EndProcedure

Function GetStandardSettings() Export
	
	Return Sales().GetStandardSettings();
	
EndFunction

////////////////////////////////////////////////////////////////////////////////
// AUXILIARY PROCEDURES AND FUNCTIONS

Function Sales()
	
	If Common.SubsystemExists("StandardSubsystems.SMDataAreasBackup") Then
		Return Common.CommonModule("DataAreaBackupFormDataInterface");
	Else
		Return Common.CommonModule("DataAreaBackupFormDataImplementationWebService");
	EndIf;
	
EndFunction

#EndRegion
