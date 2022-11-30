///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Private

// The procedure updates the register data during the full update of auxiliary data.
// 
// Parameters:
//  HasChanges - Boolean (return value) - if recorded, True is set, otherwise, it is not changed.
//                  
//
Procedure UpdateRegisterData(HasChanges = Undefined) Export
	
	If Not AccessManagementInternal.LimitAccessAtRecordLevelUniversally() Then
		Return;
	EndIf;
	
	AccessManagementInternal.ActiveAccessRestrictionParameters(Undefined,
		Undefined, True, False, False, HasChanges);
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Updating an infobase.

Procedure RegisterDataToProcessForMigrationToNewVersion2(Parameters) Export
	
	// Data registration is not required.
	
EndProcedure

Procedure ProcessDataForMigrationToNewVersion2(Parameters) Export
	
	DataRestrictionDetails = AccessManagementInternal.DataRestrictionsDetails();
	ExternalUsersEnabled = Constants.UseExternalUsers.Get();
	
	Lists = New Array;
	ListsForExternalUsers = New Array;
	For Each KeyAndValue In DataRestrictionDetails Do
		Lists.Add(KeyAndValue.Key);
		If ExternalUsersEnabled Then
			ListsForExternalUsers.Add(KeyAndValue.Key);
		EndIf;
	EndDo;
	
	PlanningParameters = AccessManagementInternal.AccessUpdatePlanningParameters();
	
	PlanningParameters.DataAccessKeys = False;
	PlanningParameters.ForExternalUsers = False;
	PlanningParameters.IsUpdateContinuation = True;
	PlanningParameters.Details = "ProcessDataForMigrationToNewVersion2";
	AccessManagementInternal.ScheduleAccessUpdate(Lists, PlanningParameters);
	
	PlanningParameters.ForUsers = False;
	PlanningParameters.ForExternalUsers = True;
	PlanningParameters.Details = "ProcessDataForMigrationToNewVersion2";
	AccessManagementInternal.ScheduleAccessUpdate(ListsForExternalUsers, PlanningParameters);
	
	Parameters.ProcessingCompleted = True;
	
EndProcedure

Procedure RegisterDataToProcessForMigrationToNewVersion3(Parameters) Export
	
	// Data registration is not required.
	
EndProcedure

Procedure ProcessDataForMigrationToNewVersion3(Parameters) Export
	
	Constants.LimitAccessAtRecordLevelUniversally.Set(True);
	
	Parameters.ProcessingCompleted = True;
	
EndProcedure

#EndRegion

#EndIf
