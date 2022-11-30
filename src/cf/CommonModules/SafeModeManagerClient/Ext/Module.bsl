///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Public

// Applies requests to use external resources saved to the infobase.
//
// Parameters:
//  IDs - Array - IDs of requests to be applied,
//  OwnerForm - ManagedForm - a form to be locked before permissions are applied,
//  ClosingNotification - NotifyDescription that will be called when permissions are granted.
//
Procedure ApplyExternalResourceRequests(Val IDs, OwnerForm, ClosingNotification) Export
	
	StandardProcessing = True;
	SaaSIntegrationClient.OnConfirmRequestsToUseExternalResources(IDs, OwnerForm, ClosingNotification, StandardProcessing);
	If Not StandardProcessing Then
		Return;
	EndIf;
		
	SafeModeManagerClientOverridable.OnConfirmRequestsToUseExternalResources(
		IDs, OwnerForm, ClosingNotification, StandardProcessing);
	ExternalResourcePermissionSetupClient.StartInitializingRequestForPermissionsToUseExternalResources(
		IDs, OwnerForm, ClosingNotification);
	
EndProcedure

// Opens the security profile setup dialog for the current infobase.
// 
//
Procedure OpenSecurityProfileSetupDialog() Export
	
	OpenForm(
		"DataProcessor.ExternalResourcePermissionSetup.Form.SecurityProfileSetup",
		,
		,
		"DataProcessor.ExternalResourcePermissionSetup.Form.SecurityProfileSetup",
		,
		,
		,
		FormWindowOpeningMode.Independent);
	
EndProcedure

// Enables the administrator to open an external data processor or a report with safe mode selection.
//
// Parameters:
//   Owner - ManagedForm - a form that owns the external report or data processor form.
//
Procedure OpenExternalDataProcessorOrReport(Owner) Export
	
	OpenForm("DataProcessor.ExternalResourcePermissionSetup.Form.OpenExternalDataProcessorOrReportWithSafeModeSelection",,
		Owner);
	
EndProcedure

#EndRegion
