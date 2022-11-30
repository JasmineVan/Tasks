///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Public

// Called when checking whether security profiles can be used.
//
// Parameters:
//  Cancel - Boolean - if the configuration is not adapted to security profiles, set the parameter 
//   value of this procedure to True.
//   
//
Procedure OnCheckSecurityProfilesUsageAvailability(Cancel) Export
	
	
	
EndProcedure

// Called when checking whether security profiles can be set up.
//
// Parameters:
//  Cancel - Boolean - if security profiles cannot be used for the infobase, set the value of this 
//    parameter to True.
//
Procedure CanSetUpSecurityProfilesOnCheck(Cancel) Export
	
	
	
EndProcedure

// Called when infobase security profiles are enabled for the infobase.
//
Procedure OnEnableSecurityProfiles() Export
	
	
	
EndProcedure

// Fills in a list of requests for external permissions that must be granted when an infobase is 
// created or an application is updated.
//
// Parameters:
//  PermissionRequests - Array - a list of values returned by the function.
//                      SafeModeManager.RequestToUseExternalResources().
//
Procedure OnFillPermissionsToAccessExternalResources(PermissionRequests) Export
	
	
	
EndProcedure

// Called when creating a request for permissions to use external resources.
//
// Parameters:
//  ProgramModule - AnyRef - a reference to the infobase object that represents a program module,
//     for which the permissions are requested.
//  Owner - AnyRef - a reference to the infobase object that represents an object that owns 
//    requested permissions to use external resources.
//  ReplacementMode - Boolean - indicates whether permissions granted earlier by owner were replaced.
//  PermissionsToAdd - Array - XDTODataObject array of permissions being added,
//  PermissionsToDelete - Array - XDTODataObject array of permissions being deleted,
//  StandardProcessing - Boolean - indicates that a standard data processor to create a request to 
//    use external resources is processed.
//  Result - UUID - a request ID (if StandardProcessing parameter value is set to False in the 
//    handler).
//
Procedure OnRequestPermissionsToUseExternalResources(Val ProgramModule, Val Owner, Val ReplacementMode, 
	Val PermissionsToAdd, Val PermissionsToDelete, StandardProcessing, Result) Export
	
	
	
EndProcedure

// Called when requesting to create a security profile.
//
// Parameters:
//  ProgramModule - AnyRef - a reference to the infobase object that represents a program module,
//     for which the permissions are requested.
//  StandardProcessing - Boolean - indicates that a standard data processor is being executed,
//  Result - UUID - a request ID (if StandardProcessing parameter value is set to False in the 
//    handler).
//
Procedure OnRequestToCreateSecurityProfile(Val ProgramModule, StandardProcessing, Result) Export
	
	
	
EndProcedure

// Called when requesting to delete a security profile.
//
// Parameters:
//  ProgramModule - AnyRef - a reference to the infobase object that represents a program module,
//     for which the permissions are requested.
//  StandardProcessing - Boolean - indicates that a standard data processor is being executed,
//  Result - UUID - a request ID (if StandardProcessing parameter value is set to False in the 
//    handler).
//
Procedure OnRequestToDeleteSecurityProfile(Val ProgramModule, StandardProcessing, Result) Export
	
	
	
EndProcedure

// Called when attaching an external module. In the handler procedure body, you can change the safe 
// mode, in which the module is attached.
//
// Parameters:
//  ExternalModule - AnyRef - a reference to the infobase object that represents the external module 
//    to be attached.
//  SafeMode - TypeToDefine.SafeMode - a safe mode, in which the external module will be attached to 
//    the infobase. Can be changed within this procedure.
//
Procedure OnAttachExternalModule(Val ExternalModule, SafeMode) Export
	
	
	
EndProcedure

#EndRegion