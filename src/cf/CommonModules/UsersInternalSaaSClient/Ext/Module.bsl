///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Internal

// Opens the service user password input form.
//
// Parameters:
//  ContinuationHandler - NotifyDescription to be processed after the password is entered.
//  OwnerForm - ManagedForm that requests the password.
//  SaaSUserPassword - String - current SaaS user password.
//
Procedure RequestPasswordForAuthenticationInService(ContinuationHandler, OwnerForm, ServiceUserPassword) Export
	
	If ServiceUserPassword = Undefined Then
		OpenForm("CommonForm.AuthenticationInService", , OwnerForm, , , , ContinuationHandler);
	Else
		ExecuteNotifyProcessing(ContinuationHandler, ServiceUserPassword);
	EndIf;
	
EndProcedure

#EndRegion
