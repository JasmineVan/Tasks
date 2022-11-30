///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Private

// Checks whether the permissions to use external resources are applied.
// Used for troubleshooting issues when changes in security profile settings in a server cluster 
// were made but the operation within which the changes had to be done was not completed.
// 
//
// Returns - Structure:
//  CheckResult - Boolean - if False, then the operation was not completed and the user must be 
//                      prompted to cancel the changes in the security profile settings in the 
//                      server cluster,
//  RequestsIDs - Array(UUID) - an array of IDs of requests to use external resources that must be 
//                           applied to cancel changes in the security profile settings in the 
//                           server cluster,
//  TempStorageAddress - String - an address in a temporary storage, where the state of permission 
//                             requests, which must be applied to cancel changes in the security 
//                             profile settings in the server cluster, was placed,
//                             
//  StateTemporaryStorageAddress - String - an address in a temporary storage, to which the inner 
//                                      processing state was placed.
//                                      ExternalResourcesPermissionsSetup.
//
Function CheckApplyPermissionsToUseExternalResources() Export
	
	Return DataProcessors.ExternalResourcePermissionSetup.ExecuteApplicabilityCheckRequestsProcessing();
	
EndFunction

// Deletes requests to use external resources if the user cancels them.
//
// Parameters:
//  RequestsIDs - Array(UUID) - an array of IDs of requests to use external resources.
//                           
//
Procedure CancelApplyRequestsToUseExternalResources(Val RequestsIDs) Export
	
	InformationRegisters.RequestsForPermissionsToUseExternalResources.DeleteRequests(RequestsIDs);
	
EndProcedure

#EndRegion
