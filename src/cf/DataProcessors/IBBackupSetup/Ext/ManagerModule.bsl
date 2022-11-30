///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure FormGetProcessing(FormType, Parameters, SelectedForm, AdditionalInfo, StandardProcessing)
	
	StandardProcessing = False;
	SelectedForm = "DataProcessor.IBBackupSetup.Form.BackupSetupClientServer";
	
	#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then
		
		If Common.FileInfobase() Then
			SelectedForm = "DataProcessor.IBBackupSetup.Form.BackupSetup";
		EndIf;
		
	#EndIf
	
EndProcedure

#EndRegion

#EndIf