///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Public

// Is called when deleting the data area.
// All data areas that cannot be deleted in the standard way must be deleted in this procedure.
// 
//
// Parameters:
//   DataArea - Number - value of the separator of the data area to be deleted.
// 
Procedure DataAreaOnDelete(Val DataArea) Export
	
EndProcedure

// Generates a list of infobase parameters.
//
// Parameters:
//   ParametersTable - ValueTable - infobase parameter details, see SaaS.GetIBParametersTable(). 
//
Procedure OnFillIIBParametersTable(Val ParametersTable) Export
	
EndProcedure

// The procedure is called before an attempt to get the infobase parameter values from the constants 
// with the same name.
//
// Parameters:
//   ParameterNames - Array - parameter names whose values are to be received.
//     If the parameter value is received in this procedure, the processed parameter name must be 
//     removed from the array.
//   ParameterValues - Structure - parameter values.
//
Procedure OnGetIBParametersValues(Val ParametersNames, Val ParametersValues) Export
	
EndProcedure

// Called before an attempt to write infobase parameters as constants with the same name.
// 
//
// Parameters:
//   ParametersValues - Structure - parameter values to be set.
//     If the parameter value is set in the procedure, the matching KeyAndValue pair must be deleted 
//     from the structure.
//
Procedure OnSetIBParametersValues(Val ParametersValues) Export
	
EndProcedure

// The procedure is called when enabling the data separation, during the first start of the 
// configuration with "InitializeSeparatedIB" parameter.
// 
// Place code here to enable scheduled jobs used only when data separation is enabled and to disable 
// jobs used only when data separation is disabled.
// 
//
Procedure OnEnableSeparationByDataAreas() Export
	
	
EndProcedure

// Sets default rights for the user.
// Called in SaaS mode if user rights are changed in the service manager without administrative 
// rights.
//
// Parameters:
//  User - CatalogRef.Users - user, for which default rights are to be set.
//   
//
Procedure SetDefaultRights(User) Export
	
	
	
EndProcedure

#EndRegion
