///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

////////////////////////////////////////////////////////////////////////////////
// Core subsystem.
// Common server procedures and functions to manage:
// - Managing permissions in the security profiles from the current infobase.
//
////////////////////////////////////////////////////////////////////////////////

#Region Variables

#Region InnerState

// Array(UUID) - an array of IDs of requests to use external resources, for whose application the 
// object is initialized.
//
Var RequestsIDs;

// ValueTable - an administration operation execution plan upon applying requests to use external 
// resources. Columns:
//  * ModuleType - CatalogRef.MetadataObjectsIDs,
//  * ModuleID - UUID,
//  * Operation - EnumRef.SecurityProfileAdministrativeOperations,
//  * Name - String - a security profile name.
//
Var AdministrationOperations;

// Structure - the current plan of applying requests to use external resources. The structure includes the following fields:
//  * PermissionsToReplace - ValueTable - operations of replacing the existing permissions to use external resources:
//      * ModuleType - CatalogRef.MetadataObjectsIDs,
//      * ModuleID - UUID,
//      * OwnerType - CatalogRef.MetadataObjectsID,
//      * OwnerID - UUID,
//  * PermissionsToAdd - ValueTable -  operations of adding permissions to use external resources:
//      * ModuleType - CatalogRef.MetadataObjectsIDs,
//      * ModuleID - UUID,
//      * OwnerType - CatalogRef.MetadataObjectsID,
//      * OwnerID - UUID,
//      * Type - String - a XDTO type name describing permissions,
//      * Permissions - Map - details of permissions being added:
//         * Key - String - a permission key (see the PermissionKey function in the register manager module.
//             PermissionsToUseExternalResources).
//         * Value - XDTODataObject - XDTO - details of the premission being added,
//      * PermissionsAdditions - Map - details of additions of permissions to be added:
//         * Key - String - a permission key (see the PermissionKey function in the register manager module.
//             PermissionsToUseExternalResources).
//         * Value - Structure - see the PermissionAddition function in the register manager module.
//             PermissionsToUseExternalResources).
//  * PermissionsToDelete - ValueTable - operations of deleting permissions to use external resources:
//      * ModuleType - CatalogRef.MetadataObjectsIDs,
//      * ModuleID - UUID,
//      * OwnerType - CatalogRef.MetadataObjectsID,
//      * OwnerID - UUID,
//      * Type - String - a XDTO type name describing permissions,
//      * Permissions - Map - details of permissions being deleted:
//         * Key - String - a permission key (see the PermissionKey function in the register manager module.
//             PermissionsToUseExternalResources).
//         * Value - XDTODataObject - XDTO - details of the permission being deleted,
//      * PermissionsAdditions - Map - details of additions of permissions to be deleted:
//         * Key - String - a permission key (see the PermissionKey function in the register manager module.
//             PermissionsToUseExternalResources).
//         * Value - Structure - see the PermissionAddition function in the register manager module.
//             PermissionsToUseExternalResources).
//
Var RequestsApplicationPlan;

// Value table - source permission slice (by permission owners). Columns:
// * ModuleType - CatalogRef.MetadataObjectsIDs,
// * ModuleID - UUID,
// * OwnerType - CatalogRef.MetadataObjectsID,
// * OwnerID - UUID,
// * Type - String - a XDTO type name describing permissions,
// * Permissions - Map - permission details:
//   * Key - String - a permission key (see the PermissionKey function in the register manager module.
//      PermissionsToUseExternalResources).
//   * Value - XDTODataObject - XDTO - permission details,
// * PermissionsAdditions - Map - permission addition details:
//   * Key - String - a permission key (see the PermissionKey function in the register manager module.
//      PermissionsToUseExternalResources).
//   * Value - Structure - see the PermissionAddition function in the register manager module.
//      PermissionsToUseExternalResources).
//
Var SourcePermissionSliceByOwners;

// Value table - a source permission slice (ignoring owners). Columns:
// * ModuleType - CatalogRef.MetadataObjectsIDs,
// * ModuleID - UUID,
// * Type - String - a XDTO type name describing permissions,
// * Permissions - Map - permission details:
//   * Key - String - a permission key (see the PermissionKey function in the register manager module.
//      PermissionsToUseExternalResources).
//   * Value - XDTODataObject - XDTO - permission details,
// * PermissionsAdditions - Map - permission addition details:
//   * Key - String - a permission key (see the PermissionKey function in the register manager module.
//      PermissionsToUseExternalResources).
//   * Value - Structure - see the PermissionAddition function in the register manager module.
//      PermissionsToUseExternalResources).
//
Var SourcePermissionSliceIgnoringOwners;

// Value table - a permission slice after applying requests (broken down by permission owners).
// Columns:
// * ModuleType - CatalogRef.MetadataObjectsIDs,
// * ModuleID - UUID,
// * OwnerType - CatalogRef.MetadataObjectsID,
// * OwnerID - UUID,
// * Type - String - a XDTO type name describing permissions,
// * Permissions - Map - permission details:
//   * Key - String - a permission key (see the PermissionKey function in the register manager module.
//      PermissionsToUseExternalResources).
//   * Value - XDTODataObject - XDTO - permission details,
// * PermissionsAdditions - Map - permission addition details:
//   * Key - String - a permission key (see the PermissionKey function in the register manager module.
//      PermissionsToUseExternalResources).
//   * Value - Structure - see the PermissionAddition function in the register manager module.
//      PermissionsToUseExternalResources).
//
Var RequestsApplicationResultByOwners;

// Value table - a permission slice after applying requests (broken down by permission owners).
// Columns:
// * ModuleType - CatalogRef.MetadataObjectsIDs,
// * ModuleID - UUID,
// * Type - String - a XDTO type name describing permissions,
// * Permissions - Map - permission details:
//   * Key - String - a permission key (see the PermissionKey function in the register manager module.
//      PermissionsToUseExternalResources).
//   * Value - XDTODataObject - XDTO - permission details,
// * PermissionsAdditions - Map - permission addition details:
//   * Key - String - a permission key (see the PermissionKey function in the register manager module.
//      PermissionsToUseExternalResources).
//   * Value - Structure - see the PermissionAddition function in the register manager module.
//      PermissionsToUseExternalResources).
//
Var RequestsApplicationResultIgnoringOwners;

// Structure - delta between the source and resulting permission slices (by permission owners):
//  * PermissionsToAdd - ValueTable - details of the permissions being added, columns:
//    * ModuleType - CatalogRef.MetadataObjectsIDs,
//    * ModuleID - UUID,
//    * OwnerType - CatalogRef.MetadataObjectsID,
//    * OwnerID - UUID,
//    * Type - String - a XDTO type name describing permissions,
//    * Permissions - Map - permission details:
//      * Key - String - a permission key (see the PermissionKey function in the register manager module.
//         PermissionsToUseExternalResources).
//      * Value - XDTODataObject - XDTO - permission details,
//    * PermissionsAdditions - Map - permission addition details:
//      * Key - String - a permission key (see the PermissionKey function in the register manager module.
//         PermissionsToUseExternalResources).
//      * Value - Structure - see the PermissionAddition function in the register manager module.
//         PermissionsToUseExternalResources).
//  * PermissionsToDelete - ValueTable - details of permissions being deleted, columns:
//    * ModuleType - CatalogRef.MetadataObjectsIDs,
//    * ModuleID - UUID,
//    * OwnerType - CatalogRef.MetadataObjectsID,
//    * OwnerID - UUID,
//    * Type - String - a XDTO type name describing permissions,
//    * Permissions - Map - permission details:
//      * Key - String - a permission key (see the PermissionKey function in the register manager module.
//         PermissionsToUseExternalResources).
//      * Value - XDTODataObject - XDTO - permission details,
//    * PermissionsAdditions - Map - permission addition details:
//      * Key - String - a permission key (see the PermissionKey function in the register manager module.
//         PermissionsToUseExternalResources).
//      * Value - Structure - see the PermissionAddition function in the register manager module.
//         PermissionsToUseExternalResources).
//
Var DeltaByOwners;

// Structure - delta between the source and resulting permission slices (ignoring permission owners):
//  * PermissionsToAdd - ValueTable - details of the permissions being added, columns:
//    * ModuleType - CatalogRef.MetadataObjectsIDs,
//    * ModuleID - UUID,
//    * Type - String - a XDTO type name describing permissions,
//    * Permissions - Map - permission details:
//      * Key - String - a permission key (see the PermissionKey function in the register manager module.
//         PermissionsToUseExternalResources).
//      * Value - XDTODataObject - XDTO - permission details,
//    * PermissionsAdditions - Map - permission addition details:
//      * Key - String - a permission key (see the PermissionKey function in the register manager module.
//         PermissionsToUseExternalResources).
//      * Value - Structure - see the PermissionAddition function in the register manager module.
//         PermissionsToUseExternalResources).
//  * PermissionsToDelete - ValueTable - details of permissions being deleted, columns:
//    * ModuleType - CatalogRef.MetadataObjectsIDs,
//    * ModuleID - UUID,
//    * Type - String - a XDTO type name describing permissions,
//    * Permissions - Map - permission details:
//      * Key - String - a permission key (see the PermissionKey function in the register manager module.
//         PermissionsToUseExternalResources).
//      * Value - XDTODataObject - XDTO - permission details,
//    * PermissionsAdditions - Map - permission addition details:
//      * Key - String - a permission key (see the PermissionKey function in the register manager module.
//         PermissionsToUseExternalResources).
//      * Value - Structure - see the PermissionAddition function in the register manager module.
//         PermissionsToUseExternalResources).
//
Var DeltaIgnoringOwners;

// Boolean - indicates whether information about granted permissions is cleared before applying the permissions.
//
Var ClearingPermissionsBeforeApplying;

#EndRegion

#EndRegion

#Region Internal

// Adds a permission ID to the list of permissions to be processed. Once the permissions are applied, 
// the requests with added IDs are cleared.
//
// Parameters:
//  RequestID - UUID - an ID of the request to use external resources.
//    
//
Procedure AddRequestID(Val QueryID) Export
	
	RequestsIDs.Add(QueryID);
	
EndProcedure

// Adds a security profile administration operation to the request apllication plan.
//
// Parameters:
//  ModuleType - CatalogRef.MetadataObjectsIDs,
//  ModuleID - UUID,
//  Operation - EnumRef.SecurityProfileAdministrativeOperations,
//  Name - String - a security profile name.
//
Procedure AddAdministrationOperation(Val ModuleType, Val ModuleID, Val Operation, Val Name) Export
	
	Filter = New Structure();
	Filter.Insert("ModuleType", ModuleType);
	Filter.Insert("ModuleID", ModuleID);
	Filter.Insert("Operation", Operation);
	
	Rows = AdministrationOperations.FindRows(Filter);
	
	If Rows.Count() = 0 Then
		
		Row = AdministrationOperations.Add();
		FillPropertyValues(Row, Filter);
		Row.Name = Name;
		
	EndIf;
	
EndProcedure

// Adds properties of the request for permissions to use external resources to the request application plan.
//
// Parameters:
//  ModuleType - CatalogRef.MetadataObjectsIDs,
//  ModuleID - UUID,
//  OwnerType - CatalogRef.MetadataObjectsID,
//  OwnerID - UUID,
//  ReplacementMode - Boolean,
//  PermissionsToAdd - Array(XDTODataObject) or Undefined,
//  PermissionsToDelete - Array(XDTODataObject) or Undefined.
//
Procedure AddRequestForPermissionsToUseExternalResources(
		Val ModuleType, Val ModuleID,
		Val OwnerType, Val OwnerID,
		Val ReplacementMode,
		Val PermissionsToAdd = Undefined,
		Val PermissionsToDelete = Undefined) Export
	
	Filter = New Structure();
	Filter.Insert("ModuleType", ModuleType);
	Filter.Insert("ModuleID", ModuleID);
	
	Row = DataProcessors.ExternalResourcePermissionSetup.PermissionsTableRow(
		AdministrationOperations, Filter, False);
	
	If Row = Undefined Then
		
		If ModuleType = Catalogs.MetadataObjectIDs.EmptyRef() Then
			
			Name = Constants.InfobaseSecurityProfile.Get();
			
		Else
			
			Name = InformationRegisters.ExternalModulesAttachmentModes.ExternalModuleAttachmentMode(
				SafeModeManagerInternal.ReferenceFormPermissionRegister(
					ModuleType, ModuleID));
			
		EndIf;
		
		AddAdministrationOperation(
			ModuleType,
			ModuleID,
			Enums.SecurityProfileAdministrativeOperations.Update,
			Name);
		
	Else
		
		Name = Row.Name;
		
	EndIf;
	
	If ReplacementMode Then
		
		Filter = New Structure();
		Filter.Insert("ModuleType", ModuleType);
		Filter.Insert("ModuleID", ModuleID);
		Filter.Insert("OwnerType", OwnerType);
		Filter.Insert("OwnerID", OwnerID);
		
		DataProcessors.ExternalResourcePermissionSetup.PermissionsTableRow(
			RequestsApplicationPlan.PermissionsToReplace, Filter);
		
	EndIf;
	
	If PermissionsToAdd <> Undefined Then
		
		For Each PermissionToAdd In PermissionsToAdd Do
			
			Filter = New Structure();
			Filter.Insert("ModuleType", ModuleType);
			Filter.Insert("ModuleID", ModuleID);
			Filter.Insert("OwnerType", OwnerType);
			Filter.Insert("OwnerID", OwnerID);
			Filter.Insert("Type", PermissionToAdd.Type().Name);
			
			Row = DataProcessors.ExternalResourcePermissionSetup.PermissionsTableRow(
				RequestsApplicationPlan.PermissionsToAdd, Filter);
			
			PermissionKey = InformationRegisters.PermissionsToUseExternalResources.PermissionKey(PermissionToAdd);
			PermissionAddition = InformationRegisters.PermissionsToUseExternalResources.PermissionAddition(PermissionToAdd);
			
			Row.Permissions.Insert(PermissionKey, Common.XDTODataObjectToXMLString(PermissionToAdd));
			
			If ValueIsFilled(PermissionAddition) Then
				Row.PermissionsAdditions.Insert(PermissionKey, Common.ValueToXMLString(PermissionAddition));
			EndIf;
			
		EndDo;
		
	EndIf;
	
	If PermissionsToDelete <> Undefined Then
		
		For Each PermissionToDelete In PermissionsToDelete Do
			
			Filter = New Structure();
			Filter.Insert("ModuleType", ModuleType);
			Filter.Insert("ModuleID", ModuleID);
			Filter.Insert("OwnerType", OwnerType);
			Filter.Insert("OwnerID", OwnerID);
			Filter.Insert("Type", PermissionToDelete.Type().Name);
			
			Row = DataProcessors.ExternalResourcePermissionSetup.PermissionsTableRow(
				RequestsApplicationPlan.PermissionsToDelete, Filter);
			
			PermissionKey = InformationRegisters.PermissionsToUseExternalResources.PermissionKey(PermissionToDelete);
			PermissionAddition = InformationRegisters.PermissionsToUseExternalResources.PermissionAddition(PermissionToDelete);
			
			Row.Permissions.Insert(PermissionKey, Common.XDTODataObjectToXMLString(PermissionToDelete));
			
			If ValueIsFilled(PermissionAddition) Then
				Row.PermissionsAdditions.Insert(PermissionKey, Common.ValueToXMLString(PermissionAddition));
			EndIf;
			
		EndDo;
		
	EndIf;
	
EndProcedure

// Adds a flag whether to clear permission data from the registers to the request application plan.
// Used to restore profiles.
//
Procedure AddClearingPermissionsBeforeApplying() Export
	
	ClearingPermissionsBeforeApplying = True;
	
EndProcedure

// Calculates a result of application of requests to use external resources.
//
Procedure CalculateRequestsApplication() Export
	
	BeginTransaction();
	Try
		DataProcessors.ExternalResourcePermissionSetup.LockRegistersOfGrantedPermissions();
		
		SourcePermissionSliceByOwners = InformationRegisters.PermissionsToUseExternalResources.PermissionsSlice();
		CalculateRequestsApplicationResultByOwners();
		CalculateDeltaByOwners();
		
		SourcePermissionSliceIgnoringOwners = InformationRegisters.PermissionsToUseExternalResources.PermissionsSlice(False, True);
		CalculateRequestsApplicationResultIgnoringOwners();
		CalculateDeltaIgnoringOwners();
		
		RollbackTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;
	
	If MustApplyPermissionsInServersCluster() Then
		
		Try
			LockDataForEdit(Semaphore());
		Except
			Raise
				NStr("ru = 'Ошибка конкурентного доступа к настройке разрешений на использование внешних ресурсов.
				           |Попробуйте выполнить операцию позже.'; 
				           |en = 'An error occurred when competitively accessing settings of permissions for external resource usage.
				           |Try to perform the operation later.'; 
				           |pl = 'An error occurred when competitively accessing settings of permissions for external resource usage.
				           |Try to perform the operation later.';
				           |de = 'An error occurred when competitively accessing settings of permissions for external resource usage.
				           |Try to perform the operation later.';
				           |ro = 'An error occurred when competitively accessing settings of permissions for external resource usage.
				           |Try to perform the operation later.';
				           |tr = 'An error occurred when competitively accessing settings of permissions for external resource usage.
				           |Try to perform the operation later.'; 
				           |es_ES = 'An error occurred when competitively accessing settings of permissions for external resource usage.
				           |Try to perform the operation later.'");
		EndTry;
		
	EndIf;
	
EndProcedure

// Checks whether permissions must be applied in the server cluster.
//
// Returns: Boolean.
//
Function MustApplyPermissionsInServersCluster() Export
	
	If DeltaIgnoringOwners.ItemsToAdd.Count() > 0 Then
		Return True;
	EndIf;
	
	If DeltaIgnoringOwners.ItemsToDelete.Count() > 0 Then
		Return True;
	EndIf;
	
	For Each AdministrationOperation In AdministrationOperations Do
		If AdministrationOperation.Operation = Enums.SecurityProfileAdministrativeOperations.Delete Then
			Return True;
		EndIf;
	EndDo;
	
	Return False;
	
EndFunction

// Checks whether permissions must be written to registers.
//
// Returns: Boolean.
//
Function RecordPermissionsToRegisterRequired() Export
	
	If DeltaByOwners.ItemsToAdd.Count() > 0 Then
		Return True;
	EndIf;
	
	If DeltaByOwners.ItemsToDelete.Count() > 0 Then
		Return True;
	EndIf;
	
	For Each AdministrationOperation In AdministrationOperations Do
		If AdministrationOperation.Operation = Enums.SecurityProfileAdministrativeOperations.Delete Then
			Return True;
		EndIf;
	EndDo;
	
	Return False;
	
EndFunction

// Returns a presentation of requests for permissions to use external resources.
//
// Parameters:
//  AsRequired - Boolean - a presentation is generated as a list of permissions, not as a list of 
//    operations upon changing permissions.
//
// Returns: SpreadsheetDocument.
//
Function Presentation(Val AsRequired = False) Export
	
	Return Reports.ExternalResourcesInUse.RequestsForPermissionsToUseExternalResoursesPresentation(
		AdministrationOperations,
		DeltaIgnoringOwners.ItemsToAdd,
		DeltaIgnoringOwners.ItemsToDelete,
		AsRequired);
	
EndFunction

// Returns a scenario of applying requests for permissions to use external resources.
//
// Returns: Array(Structure), structure fields:
//                        * Operation - EnumRef.SecurityProfileAdministrativeOperations,
//                        * Profile - String - a security profile name,
//                        * Permissions - Structure - see
//                                                   ClusterAdministration.SecurityProfileProperties().
//
Function ApplyingScenario() Export
	
	Result = New Array();
	
	For Each Details In AdministrationOperations Do
		
		ResultItem = New Structure("Operation,Profile,Permissions");
		ResultItem.Operation = Details.Operation;
		ResultItem.Profile = Details.Name;
		ResultItem.Permissions = ProfileInClusterAdministrationInterfaceNotation(ResultItem.Profile, Details.ModuleType, Details.ModuleID);
		
		IsConfigurationProfile = (Details.ModuleType = Catalogs.MetadataObjectIDs.EmptyRef());
		
		If IsConfigurationProfile Then
			
			AdditionalOperationPriority = False;
			
			If Details.Operation = Enums.SecurityProfileAdministrativeOperations.Creating Then
				AdditionalOperation = Enums.SecurityProfileAdministrativeOperations.Purpose;
			EndIf;
			
			If Details.Operation = Enums.SecurityProfileAdministrativeOperations.Delete Then
				AdditionalOperation = Enums.SecurityProfileAdministrativeOperations.AssignmentDeletion;
				AdditionalOperationPriority = True;
			EndIf;
			
			AdditionalItem = New Structure("Operation,Profile,Permissions", AdditionalOperation, Details.Name);
			
		EndIf;
		
		If IsConfigurationProfile AND AdditionalOperationPriority Then
			
			Result.Add(AdditionalItem);
			
		EndIf;
		
		Result.Add(ResultItem);
		
		If IsConfigurationProfile AND Not AdditionalOperationPriority Then
			
			Result.Add(AdditionalItem);
			
		EndIf;
		
	EndDo;
	
	Return Result;
	
EndFunction

// Serializes an internal state of the object.
//
// Returns - String.
//
Function WriteStateToXMLString() Export
	
	State = New Structure();
	
	State.Insert("SourcePermissionSliceByOwners", SourcePermissionSliceByOwners);
	State.Insert("RequiestApplyingResultByOwners", RequestsApplicationResultByOwners);
	State.Insert("DeltaByOwners", DeltaByOwners);
	State.Insert("SourcePermissionSliceIgnoringOwners", SourcePermissionSliceIgnoringOwners);
	State.Insert("RequiestApplyingResultIgnoringOwners", RequestsApplicationResultIgnoringOwners);
	State.Insert("DeltaIgnoringOwners", DeltaIgnoringOwners);
	State.Insert("AdministrationOperations", AdministrationOperations);
	State.Insert("RequestIDs", RequestsIDs);
	State.Insert("ClearingPermissionsBeforeApply", ClearingPermissionsBeforeApplying);
	
	Return Common.ValueToXMLString(State);
	
EndFunction

// Deserializes an internal state of the object.
//
// Parameters:
//  XMLString - String - a result returned by the WriteStateToXMLString() function.
//
Procedure ReadStateFromXMLString(Val XMLString) Export
	
	State = Common.ValueFromXMLString(XMLString);
	
	SourcePermissionSliceByOwners = State.SourcePermissionSliceByOwners;
	RequestsApplicationResultByOwners = State.RequiestApplyingResultByOwners;
	DeltaByOwners = State.DeltaByOwners;
	SourcePermissionSliceIgnoringOwners = State.SourcePermissionSliceIgnoringOwners;
	RequestsApplicationResultIgnoringOwners = State.RequiestApplyingResultIgnoringOwners;
	DeltaIgnoringOwners = State.DeltaIgnoringOwners;
	AdministrationOperations = State.AdministrationOperations;
	RequestsIDs = State.RequestIDs;
	ClearingPermissionsBeforeApplying = State.ClearingPermissionsBeforeApply;
	
EndProcedure

// Saves in the infobse the fact that requests to use external resource are applied.
//
Procedure CompleteApplyRequestsToUseExternalResources() Export
	
	BeginTransaction();
	Try
		
		If RecordPermissionsToRegisterRequired() Then
			
			If ClearingPermissionsBeforeApplying Then
				
				DataProcessors.ExternalResourcePermissionSetup.ClearPermissions(, False);
				
			EndIf;
			
			For Each PermissionsToDelete In DeltaByOwners.ItemsToDelete Do
				
				For Each KeyAndValue In PermissionsToDelete.Permissions Do
					
					InformationRegisters.PermissionsToUseExternalResources.DeletePermission(
						PermissionsToDelete.ModuleType,
						PermissionsToDelete.ModuleID,
						PermissionsToDelete.OwnerType,
						PermissionsToDelete.OwnerID,
						KeyAndValue.Key,
						Common.XDTODataObjectFromXMLString(KeyAndValue.Value));
					
				EndDo;
				
			EndDo;
			
			For Each ItemsToAdd In DeltaByOwners.ItemsToAdd Do
				
				For Each KeyAndValue In ItemsToAdd.Permissions Do
					
					Addition = ItemsToAdd.PermissionsAdditions.Get(KeyAndValue.Key);
					If Addition <> Undefined Then
						Addition = Common.ValueFromXMLString(Addition);
					EndIf;
					
					InformationRegisters.PermissionsToUseExternalResources.AddPermission(
						ItemsToAdd.ModuleType,
						ItemsToAdd.ModuleID,
						ItemsToAdd.OwnerType,
						ItemsToAdd.OwnerID,
						KeyAndValue.Key,
						Common.XDTODataObjectFromXMLString(KeyAndValue.Value),
						Addition);
					
				EndDo;
				
			EndDo;
			
			For Each Details In AdministrationOperations Do
				
				IsConfigurationProfile = (Details.ModuleType = Catalogs.MetadataObjectIDs.EmptyRef());
				
				If Details.Operation = Enums.SecurityProfileAdministrativeOperations.Creating Then
					
					If IsConfigurationProfile Then
						
						Constants.InfobaseSecurityProfile.Set(Details.Name);
						
					Else
						
						Manager = InformationRegisters.ExternalModulesAttachmentModes.CreateRecordManager();
						Manager.ModuleType = Details.ModuleType;
						Manager.ModuleID = Details.ModuleID;
						Manager.SafeMode = Details.Name;
						Manager.Write();
						
					EndIf;
					
				EndIf;
				
				If Details.Operation = Enums.SecurityProfileAdministrativeOperations.Delete Then
					
					If IsConfigurationProfile Then
						
						Constants.InfobaseSecurityProfile.Set("");
						DataProcessors.ExternalResourcePermissionSetup.ClearPermissions();
						
					Else
						
						ProgramModule = SafeModeManagerInternal.ReferenceFormPermissionRegister(
							Details.ModuleType, Details.ModuleID);
						DataProcessors.ExternalResourcePermissionSetup.ClearPermissions(
							ProgramModule, True);
						
					EndIf;
					
				EndIf;
				
			EndDo;
			
		EndIf;
		
		InformationRegisters.RequestsForPermissionsToUseExternalResources.DeleteRequests(RequestsIDs);
		InformationRegisters.RequestsForPermissionsToUseExternalResources.ClearObsoleteRequests();
		
		UnlockDataForEdit(Semaphore());
		
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;
	
EndProcedure

#EndRegion

#Region Private

// Calculates a request application result by owners.
//
Procedure CalculateRequestsApplicationResultByOwners()
	
	RequestsApplicationResultByOwners = New ValueTable();
	
	For Each SourceColumn In SourcePermissionSliceByOwners.Columns Do
		RequestsApplicationResultByOwners.Columns.Add(SourceColumn.Name, SourceColumn.ValueType);
	EndDo;
	
	For Each SourceString In SourcePermissionSliceByOwners Do
		NewRow = RequestsApplicationResultByOwners.Add();
		FillPropertyValues(NewRow, SourceString);
	EndDo;
	
	// Applying the plan
	
	// Overwrite
	For Each ReplacementTableRow In RequestsApplicationPlan.PermissionsToReplace Do
		
		Filter = New Structure();
		Filter.Insert("ModuleType", ReplacementTableRow.ModuleType);
		Filter.Insert("ModuleID", ReplacementTableRow.ModuleID);
		Filter.Insert("OwnerType", ReplacementTableRow.OwnerType);
		Filter.Insert("OwnerID", ReplacementTableRow.OwnerID);
		
		Rows = RequestsApplicationResultByOwners.FindRows(Filter);
		
		For Each Row In Rows Do
			RequestsApplicationResultByOwners.Delete(Row);
		EndDo;
		
	EndDo;
	
	// Adding permissions
	For Each AddedItemsRow In RequestsApplicationPlan.PermissionsToAdd Do
		
		Filter = New Structure();
		Filter.Insert("ModuleType", AddedItemsRow.ModuleType);
		Filter.Insert("ModuleID", AddedItemsRow.ModuleID);
		Filter.Insert("OwnerType", AddedItemsRow.OwnerType);
		Filter.Insert("OwnerID", AddedItemsRow.OwnerID);
		Filter.Insert("Type", AddedItemsRow.Type);
		
		Row = DataProcessors.ExternalResourcePermissionSetup.PermissionsTableRow(
			RequestsApplicationResultByOwners, Filter);
		
		For Each KeyAndValue In AddedItemsRow.Permissions Do
			
			Row.Permissions.Insert(KeyAndValue.Key, KeyAndValue.Value);
			
			If AddedItemsRow.PermissionsAdditions.Get(KeyAndValue.Key) <> Undefined Then
				Row.PermissionsAdditions.Insert(KeyAndValue.Key, AddedItemsRow.PermissionsAdditions.Get(KeyAndValue.Key));
			EndIf;
			
		EndDo;
		
	EndDo;
	
	// Deleting permissions
	For Each PermissionsToDeleteRow In RequestsApplicationPlan.PermissionsToDelete Do
		
		Filter = New Structure();
		Filter.Insert("ModuleType", PermissionsToDeleteRow.ModuleType);
		Filter.Insert("ModuleID", PermissionsToDeleteRow.ModuleID);
		Filter.Insert("OwnerType", PermissionsToDeleteRow.OwnerType);
		Filter.Insert("OwnerID", PermissionsToDeleteRow.OwnerID);
		Filter.Insert("Type", PermissionsToDeleteRow.Type);
		
		Row = DataProcessors.ExternalResourcePermissionSetup.PermissionsTableRow(
			RequestsApplicationResultByOwners, Filter);
		
		For Each KeyAndValue In PermissionsToDeleteRow.Permissions Do
			
			Row.Permissions.Delete(KeyAndValue.Key);
			
			If PermissionsToDeleteRow.PermissionsAdditions.Get(KeyAndValue.Key) <> Undefined Then
				
				Row.PermissionsAdditions.Insert(KeyAndValue.Key, PermissionsToDeleteRow.PermissionsAdditions.Get(KeyAndValue.Key));
				
			EndIf;
			
		EndDo;
		
	EndDo;
	
EndProcedure

// Calculates a request application result ignoring owners.
//
Procedure CalculateRequestsApplicationResultIgnoringOwners()
	
	RequestsApplicationResultIgnoringOwners = New ValueTable();
	
	For Each SourceColumn In SourcePermissionSliceIgnoringOwners.Columns Do
		RequestsApplicationResultIgnoringOwners.Columns.Add(SourceColumn.Name, SourceColumn.ValueType);
	EndDo;
	
	For Each ResultString In RequestsApplicationResultByOwners Do
		
		Filter = New Structure();
		Filter.Insert("ModuleType", ResultString.ModuleType);
		Filter.Insert("ModuleID", ResultString.ModuleID);
		Filter.Insert("Type", ResultString.Type);
		
		Row = DataProcessors.ExternalResourcePermissionSetup.PermissionsTableRow(
			RequestsApplicationResultIgnoringOwners, Filter);
		
		For Each KeyAndValue In ResultString.Permissions Do
			
			SourcePermission = Common.XDTODataObjectFromXMLString(KeyAndValue.Value);
			// Details must not affect hash sums for an option without ownersю
			PermissionDetails = SourcePermission.Description;
			SourcePermission.Description = ""; 
			PermissionKey = InformationRegisters.PermissionsToUseExternalResources.PermissionKey(SourcePermission);
			
			Permission = Row.Permissions.Get(PermissionKey);
			If Permission = Undefined Then
				
				If ResultString.Type = "FileSystemAccess" Then
					
					// Searching for nested and parent permissions to use a file system directory.
					// 
					
					If SourcePermission.AllowedRead Then
						
						If SourcePermission.AllowedWrite Then
							
							// Searching for a permission to read the same catalog.
							PermissionCopy = Common.XDTODataObjectFromXMLString(Common.XDTODataObjectToXMLString(SourcePermission));
							PermissionCopy.AllowedWrite = False;
							CopyKey = InformationRegisters.PermissionsToUseExternalResources.PermissionKey(PermissionCopy);
							
							// Deleting the nested permission. It becomes useless once the current one is added.
							NestedPermission = Row.Permissions.Get(CopyKey);
							If NestedPermission <> Undefined Then
								Row.Permissions.Delete(CopyKey);
							EndIf;
							
						Else
							
							// Searching for a permission to read and write to the same catalog.
							PermissionCopy = Common.XDTODataObjectFromXMLString(Common.XDTODataObjectToXMLString(SourcePermission));
							PermissionCopy.AllowedWrite = True;
							CopyKey = InformationRegisters.PermissionsToUseExternalResources.PermissionKey(PermissionCopy);
							
							// There is no need to process this permission, the directory will be available by the parent permission.
							ParentPermission = Row.Permissions.Get(CopyKey);
							If ParentPermission <> Undefined Then
								Continue;
							EndIf;
							
						EndIf;
						
					EndIf;
					
				EndIf;
				
				SourcePermission.Description = PermissionDetails; 
				Row.Permissions.Insert(PermissionKey, Common.XDTODataObjectToXMLString(SourcePermission));
				
				Addition = ResultString.PermissionsAdditions.Get(KeyAndValue.Key);
				If Addition <> Undefined Then
					Row.PermissionsAdditions.Insert(PermissionKey, Addition);
				EndIf;
				
			EndIf;
			
		EndDo;
		
	EndDo;
	
EndProcedure

// Calculates a delta between two permission broken down by owners.
//
Procedure CalculateDeltaByOwners()
	
	DeltaByOwners = New Structure();
	
	DeltaByOwners.Insert("ItemsToAdd", New ValueTable);
	DeltaByOwners.ItemsToAdd.Columns.Add("ModuleType", New TypeDescription("CatalogRef.MetadataObjectIDs"));
	DeltaByOwners.ItemsToAdd.Columns.Add("ModuleID", New TypeDescription("UUID"));
	DeltaByOwners.ItemsToAdd.Columns.Add("OwnerType", New TypeDescription("CatalogRef.MetadataObjectIDs"));
	DeltaByOwners.ItemsToAdd.Columns.Add("OwnerID", New TypeDescription("UUID"));
	DeltaByOwners.ItemsToAdd.Columns.Add("Type", New TypeDescription("String"));
	DeltaByOwners.ItemsToAdd.Columns.Add("Permissions", New TypeDescription("Map"));
	DeltaByOwners.ItemsToAdd.Columns.Add("PermissionsAdditions", New TypeDescription("Map"));
	
	DeltaByOwners.Insert("ItemsToDelete", New ValueTable);
	DeltaByOwners.ItemsToDelete.Columns.Add("ModuleType", New TypeDescription("CatalogRef.MetadataObjectIDs"));
	DeltaByOwners.ItemsToDelete.Columns.Add("ModuleID", New TypeDescription("UUID"));
	DeltaByOwners.ItemsToDelete.Columns.Add("OwnerType", New TypeDescription("CatalogRef.MetadataObjectIDs"));
	DeltaByOwners.ItemsToDelete.Columns.Add("OwnerID", New TypeDescription("UUID"));
	DeltaByOwners.ItemsToDelete.Columns.Add("Type", New TypeDescription("String"));
	DeltaByOwners.ItemsToDelete.Columns.Add("Permissions", New TypeDescription("Map"));
	DeltaByOwners.ItemsToDelete.Columns.Add("PermissionsAdditions", New TypeDescription("Map"));
	
	// Comparing source permissions with the resulting ones.
	
	For Each Row In SourcePermissionSliceByOwners Do
		
		Filter = New Structure();
		Filter.Insert("ModuleType", Row.ModuleType);
		Filter.Insert("ModuleID", Row.ModuleID);
		Filter.Insert("OwnerType", Row.OwnerType);
		Filter.Insert("OwnerID", Row.OwnerID);
		Filter.Insert("Type", Row.Type);
		
		Rows = RequestsApplicationResultByOwners.FindRows(Filter);
		If Rows.Count() > 0 Then
			ResultString = Rows.Get(0);
		Else
			ResultString = Undefined;
		EndIf;
		
		For Each KeyAndValue In Row.Permissions Do
			
			If ResultString = Undefined Or ResultString.Permissions.Get(KeyAndValue.Key) = Undefined Then
				
				// The permission was in the source ones  but it is absent in the resulting ones, it is a permission being deleted.
				
				ItemsToDeleteRow = DataProcessors.ExternalResourcePermissionSetup.PermissionsTableRow(
					DeltaByOwners.ItemsToDelete, Filter);
				
				If ItemsToDeleteRow.Permissions.Get(KeyAndValue.Key) = Undefined Then
					
					ItemsToDeleteRow.Permissions.Insert(KeyAndValue.Key, KeyAndValue.Value);
					
					If Row.PermissionsAdditions.Get(KeyAndValue.Key) <> Undefined Then
						ItemsToDeleteRow.PermissionsAdditions.Insert(KeyAndValue.Key, Row.PermissionsAdditions.Get(KeyAndValue.Key));
					EndIf;
					
				EndIf;
				
			EndIf;
			
		EndDo;
		
	EndDo;
	
	// Comparing the resulting permissions with the source ones.
	
	For Each Row In RequestsApplicationResultByOwners Do
		
		Filter = New Structure();
		Filter.Insert("ModuleType", Row.ModuleType);
		Filter.Insert("ModuleID", Row.ModuleID);
		Filter.Insert("OwnerType", Row.OwnerType);
		Filter.Insert("OwnerID", Row.OwnerID);
		Filter.Insert("Type", Row.Type);
		
		Rows = SourcePermissionSliceByOwners.FindRows(Filter);
		If Rows.Count() > 0 Then
			SourceString = Rows.Get(0);
		Else
			SourceString = Undefined;
		EndIf;
		
		For Each KeyAndValue In Row.Permissions Do
			
			If SourceString = Undefined OR SourceString.Permissions.Get(KeyAndValue.Key) = Undefined Then
				
				// The permission is in resulting ones but it is absent in the source ones, it is a permission being added.
				
				ItemsToAddRow = DataProcessors.ExternalResourcePermissionSetup.PermissionsTableRow(
					DeltaByOwners.ItemsToAdd, Filter);
				
				If ItemsToAddRow.Permissions.Get(KeyAndValue.Key) = Undefined Then
					
					ItemsToAddRow.Permissions.Insert(KeyAndValue.Key, KeyAndValue.Value);
					
					If Row.PermissionsAdditions.Get(KeyAndValue.Key) <> Undefined Then
						ItemsToAddRow.PermissionsAdditions.Insert(KeyAndValue.Key, Row.PermissionsAdditions.Get(KeyAndValue.Key));
					EndIf;
					
				EndIf;
				
			EndIf;
			
		EndDo;
		
	EndDo;
	
EndProcedure

// Calculates a delta between two permission slices ignoring owners.
//
Procedure CalculateDeltaIgnoringOwners()
	
	DeltaIgnoringOwners = New Structure();
	
	DeltaIgnoringOwners.Insert("ItemsToAdd", New ValueTable);
	DeltaIgnoringOwners.ItemsToAdd.Columns.Add("ModuleType", New TypeDescription("CatalogRef.MetadataObjectIDs"));
	DeltaIgnoringOwners.ItemsToAdd.Columns.Add("ModuleID", New TypeDescription("UUID"));
	DeltaIgnoringOwners.ItemsToAdd.Columns.Add("Type", New TypeDescription("String"));
	DeltaIgnoringOwners.ItemsToAdd.Columns.Add("Permissions", New TypeDescription("Map"));
	DeltaIgnoringOwners.ItemsToAdd.Columns.Add("PermissionsAdditions", New TypeDescription("Map"));
	
	DeltaIgnoringOwners.Insert("ItemsToDelete", New ValueTable);
	DeltaIgnoringOwners.ItemsToDelete.Columns.Add("ModuleType", New TypeDescription("CatalogRef.MetadataObjectIDs"));
	DeltaIgnoringOwners.ItemsToDelete.Columns.Add("ModuleID", New TypeDescription("UUID"));
	DeltaIgnoringOwners.ItemsToDelete.Columns.Add("Type", New TypeDescription("String"));
	DeltaIgnoringOwners.ItemsToDelete.Columns.Add("Permissions", New TypeDescription("Map"));
	DeltaIgnoringOwners.ItemsToDelete.Columns.Add("PermissionsAdditions", New TypeDescription("Map"));
	
	// Comparing source permissions with the resulting ones.
	
	For Each Row In SourcePermissionSliceIgnoringOwners Do
		
		Filter = New Structure();
		Filter.Insert("ModuleType", Row.ModuleType);
		Filter.Insert("ModuleID", Row.ModuleID);
		Filter.Insert("Type", Row.Type);
		
		Rows = RequestsApplicationResultIgnoringOwners.FindRows(Filter);
		If Rows.Count() > 0 Then
			ResultString = Rows.Get(0);
		Else
			ResultString = Undefined;
		EndIf;
		
		For Each KeyAndValue In Row.Permissions Do
			
			If ResultString = Undefined OR ResultString.Permissions.Get(KeyAndValue.Key) = Undefined Then
				
				// The permission was in the source ones  but it is absent in the resulting ones, it is a permission being deleted.
				
				PermissionsToDeleteRow = DataProcessors.ExternalResourcePermissionSetup.PermissionsTableRow(
					DeltaIgnoringOwners.ItemsToDelete, Filter);
				
				If PermissionsToDeleteRow.Permissions.Get(KeyAndValue.Key) = Undefined Then
					
					PermissionsToDeleteRow.Permissions.Insert(KeyAndValue.Key, KeyAndValue.Value);
					
					If Row.PermissionsAdditions.Get(KeyAndValue.Key) <> Undefined Then
						PermissionsToDeleteRow.PermissionsAdditions.Insert(KeyAndValue.Key, Row.PermissionsAdditions.Get(KeyAndValue.Key));
					EndIf;
					
				EndIf;
				
			EndIf;
			
		EndDo;
		
	EndDo;
	
	// Comparing the resulting permissions with the source ones.
	
	For Each Row In RequestsApplicationResultIgnoringOwners Do
		
		Filter = New Structure();
		Filter.Insert("ModuleType", Row.ModuleType);
		Filter.Insert("ModuleID", Row.ModuleID);
		Filter.Insert("Type", Row.Type);
		
		Rows = SourcePermissionSliceIgnoringOwners.FindRows(Filter);
		If Rows.Count() > 0 Then
			SourceString = Rows.Get(0);
		Else
			SourceString = Undefined;
		EndIf;
		
		For Each KeyAndValue In Row.Permissions Do
			
			If SourceString = Undefined OR SourceString.Permissions.Get(KeyAndValue.Key) = Undefined Then
				
				// The permission is in resulting ones but it is absent in the source ones, it is a permission being added.
				
				PermissionsToAddRow = DataProcessors.ExternalResourcePermissionSetup.PermissionsTableRow(
					DeltaIgnoringOwners.ItemsToAdd, Filter);
				
				If PermissionsToAddRow.Permissions.Get(KeyAndValue.Key) = Undefined Then
					
					PermissionsToAddRow.Permissions.Insert(KeyAndValue.Key, KeyAndValue.Value);
					
					If Row.PermissionsAdditions.Get(KeyAndValue.Key) <> Undefined Then
						PermissionsToAddRow.PermissionsAdditions.Insert(KeyAndValue.Key, Row.PermissionsAdditions.Get(KeyAndValue.Key));
					EndIf;
					
				EndIf;
				
			EndIf;
			
		EndDo;
		
	EndDo;
	
EndProcedure

// Creates security profile details in the cluster server administration interface notation.
// 
//
// Parameters:
//  ProfileName - String - a security profile name,
//  ModuleType - CatalogRef.MetadataObjectsIDs,
//  ModuleID - UUID.
//
// Returns: Structure - see ClusterAdministration.SecurityProfileProperties(). 
//
Function ProfileInClusterAdministrationInterfaceNotation(Val ProfileName, Val ModuleType, Val ModuleID)
	
	Profile = ClusterAdministration.SecurityProfileProperties();
	Profile.Name = ProfileName;
	Profile.Details = NewSecurityProfileDetails(ModuleType, ModuleID);
	Profile.SafeModeProfile = True;
	
	Profile.FileSystemFullAccess = False;
	Profile.FullCOMObjectAccess = False;
	Profile.FullAddInAccess = False;
	Profile.FullExternalModuleAccess = False;
	Profile.FullOperatingSystemApplicationAccess = False;
	Profile.FullInternetResourceAccess = False;
	
	Profile.FullAccessToPrivilegedMode = False;
	
	Filter = New Structure();
	Filter.Insert("ModuleType", ModuleType);
	Filter.Insert("ModuleID", ModuleID);
	
	Rows = RequestsApplicationResultIgnoringOwners.FindRows(Filter);
	
	For Each Row In Rows Do
		
		For Each KeyAndValue In Row.Permissions Do
			
			Permission = Common.XDTODataObjectFromXMLString(KeyAndValue.Value);
			
			If Row.Type = "FileSystemAccess" Then
				
				If StandardVirtualDirectories().Get(Permission.Path) <> Undefined Then
					
					VirtualDirectory = ClusterAdministration.VirtualDirectoryProperties();
					VirtualDirectory.LogicalURL = Permission.Path;
					VirtualDirectory.PhysicalURL = StandardVirtualDirectories().Get(Permission.Path);
					VirtualDirectory.DataReader = Permission.AllowedRead;
					VirtualDirectory.DataWriter = Permission.AllowedWrite;
					VirtualDirectory.Details = Permission.Description;
					Profile.VirtualDirectories.Add(VirtualDirectory);
					
				Else
					
					VirtualDirectory = ClusterAdministration.VirtualDirectoryProperties();
					VirtualDirectory.LogicalURL = Permission.Path;
					VirtualDirectory.PhysicalURL = EscapePercentChar(Permission.Path);
					VirtualDirectory.DataReader = Permission.AllowedRead;
					VirtualDirectory.DataWriter = Permission.AllowedWrite;
					VirtualDirectory.Details = Permission.Description;
					Profile.VirtualDirectories.Add(VirtualDirectory);
					
				EndIf;
				
			ElsIf Row.Type = "CreateComObject" Then
				
				COMClass = ClusterAdministration.COMClassProperties();
				COMClass.Name = Permission.ProgId;
				COMClass.CLSID = Permission.CLSID;
				COMClass.Computer = Permission.ComputerName;
				COMClass.Details = Permission.Description;
				Profile.COMClasses.Add(COMClass);
				
			ElsIf Row.Type = "AttachAddin" Then
				
				Addition = Common.ValueFromXMLString(Row.PermissionsAdditions.Get(KeyAndValue.Key));
				For Each AdditionKeyAndValue In Addition Do
					
					AddIn = ClusterAdministration.AddInProperties();
					AddIn.Name = Permission.TemplateName + "\" + AdditionKeyAndValue.Key;
					AddIn.HashSum = AdditionKeyAndValue.Value;
					AddIn.Details = Permission.Description;
					Profile.AddIns.Add(AddIn);
					
				EndDo;
				
			ElsIf Row.Type = "ExternalModule" Then
				
				ExternalModule = ClusterAdministration.ExternalModuleProperties();
				ExternalModule.Name = Permission.Name;
				ExternalModule.HashSum = Permission.Hash;
				ExternalModule.Details = Permission.Description;
				Profile.ExternalModules.Add(ExternalModule);
				
			ElsIf Row.Type = "RunApplication" Then
				
				OSApplication = ClusterAdministration.OSApplicationProperties();
				OSApplication.Name = Permission.CommandMask;
				OSApplication.CommandLinePattern = Permission.CommandMask;
				OSApplication.Details = Permission.Description;
				Profile.OSApplications.Add(OSApplication);
				
			ElsIf Row.Type = "InternetResourceAccess" Then
				
				InternetResource = ClusterAdministration.InternetResourceProperties();
				InternetResource.Name = Lower(Permission.Protocol) + "://" + Lower(Permission.Host) + ":" + Permission.Port;
				InternetResource.Protocol = Permission.Protocol;
				InternetResource.Address = Permission.Host;
				InternetResource.Port = Permission.Port;
				InternetResource.Details = Permission.Description;
				Profile.InternetResources.Add(InternetResource);
				
			ElsIf Row.Type = "ExternalModulePrivilegedModeAllowed" Then
				
				Profile.FullAccessToPrivilegedMode = True;
				
			EndIf;
			
			
		EndDo;
		
	EndDo;
	
	Return Profile;
	
EndFunction

// Generates security profile details for the infobase or the external module.
//
// Parameters:
//  ExternalModule - AnyRef - a reference to the catalog item used as an external module.
//    
//
// Returns:
//   String - security profile details.
//
Function NewSecurityProfileDetails(Val ModuleType, Val ModuleID)
	
	Template = NStr("ru = '[ИБ %1] %2 ""%3""'; en = '[Infobase %1] %2 ""%3""'; pl = '[Infobase %1] %2 ""%3""';de = '[Infobase %1] %2 ""%3""';ro = '[Infobase %1] %2 ""%3""';tr = '[Infobase %1] %2 ""%3""'; es_ES = '[Infobase %1] %2 ""%3""'");
	
	IBName = "";
	ConnectionString = InfoBaseConnectionString();
	Substrings = StrSplit(ConnectionString, ";");
	For Each Substring In Substrings Do
		If StrStartsWith(Substring, "Ref") Then
			IBName = StrReplace(Right(Substring, StrLen(Substring) - 4), """", "");
		EndIf;
	EndDo;
	If IsBlankString(IBName) Then
		Raise NStr("ru = 'Строка соединения информационной базы должна содержать информационной базы'; en = 'Infobase connection string must contain the infobase.'; pl = 'Infobase connection string must contain the infobase.';de = 'Infobase connection string must contain the infobase.';ro = 'Infobase connection string must contain the infobase.';tr = 'Infobase connection string must contain the infobase.'; es_ES = 'Infobase connection string must contain the infobase.'");
	EndIf;
	
	If ModuleType = Catalogs.MetadataObjectIDs.EmptyRef() Then
		Return StringFunctionsClientServer.SubstituteParametersToString(Template, IBName,
			NStr("ru = 'Профиль безопасности для информационной базы'; en = 'Security profile for infobase'; pl = 'Security profile for infobase';de = 'Security profile for infobase';ro = 'Security profile for infobase';tr = 'Security profile for infobase'; es_ES = 'Security profile for infobase'"), InfoBaseConnectionString());
	Else
		ProgramModule = SafeModeManagerInternal.ReferenceFormPermissionRegister(ModuleType, ModuleID);
		Dictionary = SafeModeManagerInternal.ExternalModuleManager(ProgramModule).ExternalModuleContainerDictionary();
		ModuleDescription = Common.ObjectAttributeValue(ProgramModule, "Description");
		Return StringFunctionsClientServer.SubstituteParametersToString(Template, IBName, Dictionary.NominativeCase, ModuleDescription);
	EndIf;
	
EndFunction

// Returns physical paths of standard virtual directories.
//
// Returns - Map:
//                         * Key - String - a virtual directory alias,
//                         * Value - String - a physical path.
//
Function StandardVirtualDirectories()
	
	Result = New Map();
	
	Result.Insert("/temp", "%t/%r/%s/%p");
	Result.Insert("/bin", "%e");
	
	Return Result;
	
EndFunction

// Escapes the percent character in the physical path of the virtual directory.
//
// Parameters:
//  SourceLine - String - a source physical path of the virtual directory.
//
// Returns: String.
//
Function EscapePercentChar(Val SourceString)
	
	Return StrReplace(SourceString, "%", "%%");
	
EndFunction

// Returns a semaphore to be used when applying requests to use external resources.
//
// Returns - InformationRegisterRecordKey.RequestsForPermissionsToUseExternalResources.
//
Function Semaphore()
	
	varKey = New Structure();
	varKey.Insert("QueryID", New UUID("8e02fbd3-3f9f-4c3c-964d-7c602ad4eb38"));
	
	Return InformationRegisters.RequestsForPermissionsToUseExternalResources.CreateRecordKey(varKey);
	
EndFunction

#EndRegion

#Region Initializing

RequestsIDs = New Array();

RequestsApplicationPlan = New Structure();

RequestsApplicationPlan.Insert("PermissionsToReplace", New ValueTable);
RequestsApplicationPlan.PermissionsToReplace.Columns.Add("ModuleType", New TypeDescription("CatalogRef.MetadataObjectIDs"));
RequestsApplicationPlan.PermissionsToReplace.Columns.Add("ModuleID", New TypeDescription("UUID"));
RequestsApplicationPlan.PermissionsToReplace.Columns.Add("OwnerType", New TypeDescription("CatalogRef.MetadataObjectIDs"));
RequestsApplicationPlan.PermissionsToReplace.Columns.Add("OwnerID", New TypeDescription("UUID"));

RequestsApplicationPlan.Insert("PermissionsToAdd", New ValueTable);
RequestsApplicationPlan.PermissionsToAdd.Columns.Add("ModuleType", New TypeDescription("CatalogRef.MetadataObjectIDs"));
RequestsApplicationPlan.PermissionsToAdd.Columns.Add("ModuleID", New TypeDescription("UUID"));
RequestsApplicationPlan.PermissionsToAdd.Columns.Add("OwnerType", New TypeDescription("CatalogRef.MetadataObjectIDs"));
RequestsApplicationPlan.PermissionsToAdd.Columns.Add("OwnerID", New TypeDescription("UUID"));
RequestsApplicationPlan.PermissionsToAdd.Columns.Add("Type", New TypeDescription("String"));
RequestsApplicationPlan.PermissionsToAdd.Columns.Add("Permissions", New TypeDescription("Map"));
RequestsApplicationPlan.PermissionsToAdd.Columns.Add("PermissionsAdditions", New TypeDescription("Map"));

RequestsApplicationPlan.Insert("PermissionsToDelete", New ValueTable);
RequestsApplicationPlan.PermissionsToDelete.Columns.Add("ModuleType", New TypeDescription("CatalogRef.MetadataObjectIDs"));
RequestsApplicationPlan.PermissionsToDelete.Columns.Add("ModuleID", New TypeDescription("UUID"));
RequestsApplicationPlan.PermissionsToDelete.Columns.Add("OwnerType", New TypeDescription("CatalogRef.MetadataObjectIDs"));
RequestsApplicationPlan.PermissionsToDelete.Columns.Add("OwnerID", New TypeDescription("UUID"));
RequestsApplicationPlan.PermissionsToDelete.Columns.Add("Type", New TypeDescription("String"));
RequestsApplicationPlan.PermissionsToDelete.Columns.Add("Permissions", New TypeDescription("Map"));
RequestsApplicationPlan.PermissionsToDelete.Columns.Add("PermissionsAdditions", New TypeDescription("Map"));

AdministrationOperations = New ValueTable;
AdministrationOperations.Columns.Add("ModuleType", New TypeDescription("CatalogRef.MetadataObjectIDs"));
AdministrationOperations.Columns.Add("ModuleID", New TypeDescription("UUID"));
AdministrationOperations.Columns.Add("Operation", New TypeDescription("EnumRef.SecurityProfileAdministrativeOperations"));
AdministrationOperations.Columns.Add("Name", New TypeDescription("String"));

ClearingPermissionsBeforeApplying = False;

#EndRegion

#Else
Raise NStr("ru = 'Недопустимый вызов объекта на клиенте.'; en = 'Invalid object call on the client.'; pl = 'Invalid object call on the client.';de = 'Invalid object call on the client.';ro = 'Invalid object call on the client.';tr = 'Invalid object call on the client.'; es_ES = 'Invalid object call on the client.'");
#EndIf