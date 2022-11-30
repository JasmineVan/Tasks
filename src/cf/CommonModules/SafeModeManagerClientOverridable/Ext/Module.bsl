///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Public

// Called when requests to use external resources are confirmed.
// 
// Parameters:
//  RequestsIDs - Array - IDs of requests to be applied.
//  OwnerForm - ManagedForm - a form to be locked before permissions are applied.
//  ClosingNotification - NotifyDescription that will be called when permissions are granted.
//  StandardProcessing - Boolean - indicates that the standard processing of usage of permissions to 
//    use external resources is executed (connection to a service agent via COM connection or to an 
//    administration server requesting cluster connection parameters from the user). Can be set to 
//    False in the event handler. In this case, standard session termination processing is not performed.
//
Procedure OnConfirmRequestsToUseExternalResources(Val RequestsIDs, OwnerForm, ClosingNotification, StandardProcessing) Export
	
	
	
EndProcedure

#EndRegion