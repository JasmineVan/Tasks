///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Private

// Performs an asynchronous processing of a notification of closing external resource permissions 
// setup wizard form when the call is executed using an idle handler.
// DialogReturnCode.OK is passed as a result to the handler.
//
// The procedure is not intended for direct call.
//
Procedure FinishExternalResourcePermissionSetup() Export
	
	ExternalResourcePermissionSetupClient.CompleteSetUpPermissionsToUseExternalResourcesSynchronously(DialogReturnCode.OK);
	
EndProcedure

// Performs an asynchronous processing of a notification of closing external resource permissions 
// setup wizard form when the call is executed using an idle handler.
// DialogReturnCode.Cancel is passed as a result to the handler.
//
// The procedure is not intended for direct call.
//
Procedure CancelExternalResourcePermissionSetup() Export
	
	ExternalResourcePermissionSetupClient.CompleteSetUpPermissionsToUseExternalResourcesSynchronously(DialogReturnCode.Cancel);
	
EndProcedure

#EndRegion