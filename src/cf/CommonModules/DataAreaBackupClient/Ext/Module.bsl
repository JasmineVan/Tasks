///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Public

// Prompt users for back up.
//
Procedure PromptUserToBackUp() Export
	
	If StandardSubsystemsClient.ClientRunParameters().DataAreaBackup Then
		
		FormName = "CommonForm.BackupCreation";
		
	Else
		
		FormName = "CommonForm.DataExport";
		
	EndIf;
	
	OpenForm(FormName);
	
EndProcedure

#EndRegion

#Region Internal

////////////////////////////////////////////////////////////////////////////////
// Configuration subsystems event handlers.

// See SSLSubsystemsIntegrationClient.OnCheckIfCanBackUpInUserMode. 
Procedure OnCheckIfCanBackUpInUserMode(Result) Export
	
	If StandardSubsystemsClient.ClientRunParameters().DataSeparationEnabled Then
		
		Result = True;
		
	EndIf;
	
EndProcedure

// See SSLSubsystemsIntegrationClient.OnPromptUserForBackup. 
Procedure OnPromptUserForBackup() Export
	
	If StandardSubsystemsClient.ClientRunParameters().DataSeparationEnabled Then
		
		PromptUserToBackUp();
		
	EndIf;
	
EndProcedure

#EndRegion