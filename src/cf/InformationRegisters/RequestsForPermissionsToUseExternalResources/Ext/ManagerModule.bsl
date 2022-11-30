///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Private

// Creates a request for security profile administration.
//
// Parameters:
//  ProgramModule - AnyRef - a reference that describes a module that requires a security profile to 
//    be attached,
//  Operation - EnumRef.SecurityProfileAdministrativeOperations.
//
// Returns - UUID - an ID of the created request.
//
Function PermissionAdministrationRequest(Val ProgramModule, Val Operation) Export
	
	If Not RequestForPermissionsToUseExternalResourcesRequired() Then
		Return New UUID();
	EndIf;
	
	If Operation = Enums.SecurityProfileAdministrativeOperations.Creating Then
		SecurityProfileName = NewSecurityProfileName(ProgramModule);
	Else
		SecurityProfileName = SecurityProfileName(ProgramModule);
	EndIf;
	
	Manager = CreateRecordManager();
	Manager.QueryID = New UUID();
	
	If SafeModeManager.SafeModeSet() Then
		Manager.SafeMode = SafeMode();
	Else
		Manager.SafeMode = False;
	EndIf;
	
	Manager.Operation = Operation;
	Manager.AdministrationRequest = True;
	Manager.Name = SecurityProfileName;
	
	ModuleProperties = SafeModeManagerInternal.PropertiesForPermissionRegister(ProgramModule);
	Manager.ModuleType = ModuleProperties.Type;
	Manager.ModuleID = ModuleProperties.ID;
	
	Manager.Write();
	
	RecordKey = CreateRecordKey(New Structure("QueryID", Manager.QueryID));
	LockDataForEdit(RecordKey);
	
	Return Manager.QueryID;
	
EndFunction

// Creates a request for permissions to use external resources.
//
// Parameters:
//  ProgramModule - AnyRef - a reference that describes a module that requires a security profile to 
//    be attached,
//  Owner - AnyRef - a reference to the infobase object the permissions being requested are 
//    logically connected with. For example, all permissions to access file storage volume 
//    directories are logically associated with relevant FilesStorageVolumes catalog items, all 
//    permissions to access data exchange directories (or other resources according to the used 
//    exchange transport) are logically associated with relevant exchange plan nodes, and so on. If  
//    a permission is logically isolated (for example, if granting of a permission is controlled by 
//    the constant value with the Boolean type), it is recommended that you use a reference to the MetadataObjectsIDs catalog item,
//  ReplacementMode - Boolean - defines the replacement mode of permissions previously granted for this owner. 
//    If the value is True, in addition to granting the requested permissions, clearing all 
//    permissions that were previously requested for the owner are added to the request.
//  PermissionsToAdd - Array(XDTODataObject) - an array of XDTODataObjects that match internal 
//    details of permissions to access external resources being requested. It is assumed that all 
//    XDTODataObjects passed as parameters are generated using the SafeModeManager.Permission*() functions.
//  PermissionsToDelete - Array(XDTODataObject) - an array of XDTODataObjects that match internal 
//    details of permissions to access external resources being canceled. It is assumed that all 
//    XDTODataObjects passed as parameters are generated using the SafeModeManager.Permission*() functions.
//
// Returns - UUID - an ID of the created request.
//
Function RequestToUsePermissions(Val ProgramModule, Val Owner, Val ReplacementMode, Val PermissionsToAdd, Val PermissionsToDelete) Export
	
	If Not RequestForPermissionsToUseExternalResourcesRequired() Then
		Return New UUID();
	EndIf;
	
	If Owner = Undefined Then
		Owner = Catalogs.MetadataObjectIDs.EmptyRef();
	EndIf;
	
	If ProgramModule = Undefined Then
		ProgramModule = Catalogs.MetadataObjectIDs.EmptyRef();
	EndIf;
	
	If SafeModeManager.SafeModeSet() Then
		SafeMode = SafeMode();
	Else
		SafeMode = False;
	EndIf;
	
	Manager = CreateRecordManager();
	Manager.QueryID = New UUID();
	Manager.AdministrationRequest = False;
	Manager.SafeMode = SafeMode;
	Manager.ReplacementMode = ReplacementMode;
	Manager.Operation = Enums.SecurityProfileAdministrativeOperations.Update;
	
	OwnerProperties = SafeModeManagerInternal.PropertiesForPermissionRegister(Owner);
	Manager.OwnerType = OwnerProperties.Type;
	Manager.OwnerID = OwnerProperties.ID;
	
	ModuleProperties = SafeModeManagerInternal.PropertiesForPermissionRegister(ProgramModule);
	Manager.ModuleType = ModuleProperties.Type;
	Manager.ModuleID = ModuleProperties.ID;
	
	If PermissionsToAdd <> Undefined Then
		
		PermissionsArray = New Array();
		For Each NewPermission In PermissionsToAdd Do
			PermissionsArray.Add(Common.XDTODataObjectToXMLString(NewPermission));
		EndDo;
		
		If PermissionsArray.Count() > 0 Then
			Manager.PermissionsToAdd = Common.ValueToXMLString(PermissionsArray);
		EndIf;
		
	EndIf;
	
	If PermissionsToDelete <> Undefined Then
		
		PermissionsArray = New Array();
		For Each PermissionToRevoke In PermissionsToDelete Do
			PermissionsArray.Add(Common.XDTODataObjectToXMLString(PermissionToRevoke));
		EndDo;
		
		If PermissionsArray.Count() > 0 Then
			Manager.PermissionsToDelete = Common.ValueToXMLString(PermissionsArray);
		EndIf;
		
	EndIf;
	
	Manager.Write();
	
	RecordKey = CreateRecordKey(New Structure("QueryID", Manager.QueryID));
	LockDataForEdit(RecordKey);
	
	Return Manager.QueryID;
	
EndFunction

// Creates and initializes a manager for requests to use external resources.
//
// Parameters:
//  RequestsIDs - Array(UUID) - request IDs, for which a manager is created.
//   
//
// Returns: DataProcessorObject.ExternalResourcesPermissionsSetup.
//
Function PermissionsApplicationManager(Val RequestsIDs) Export
	
	Manager = DataProcessors.ExternalResourcePermissionSetup.Create();
	
	QueryText =
		"SELECT
		|	PermissionRequests.ModuleType,
		|	PermissionRequests.ModuleID,
		|	PermissionRequests.OwnerType,
		|	PermissionRequests.OwnerID,
		|	PermissionRequests.Operation,
		|	PermissionRequests.Name,
		|	PermissionRequests.ReplacementMode,
		|	PermissionRequests.PermissionsToAdd,
		|	PermissionRequests.PermissionsToDelete,
		|	PermissionRequests.QueryID
		|FROM
		|	InformationRegister.RequestsForPermissionsToUseExternalResources AS PermissionRequests
		|WHERE
		|	PermissionRequests.QueryID IN(&RequestIDs)
		|
		|ORDER BY
		|	PermissionRequests.AdministrationRequest DESC";
	Query = New Query(QueryText);
	Query.SetParameter("RequestIDs", RequestsIDs);
	
	Selection = Query.Execute().Select();
	
	While Selection.Next() Do
		
		RecordKey = CreateRecordKey(New Structure("QueryID", Selection.QueryID));
		LockDataForEdit(RecordKey);
		
		If Selection.Operation = Enums.SecurityProfileAdministrativeOperations.Creating
			OR Selection.Operation = Enums.SecurityProfileAdministrativeOperations.Delete Then
			
			Manager.AddRequestID(Selection.QueryID);
			
			Manager.AddAdministrationOperation(
				Selection.ModuleType,
				Selection.ModuleID,
				Selection.Operation,
				Selection.Name);
			
		EndIf;
		
		PermissionsToAdd = New Array();
		If ValueIsFilled(Selection.PermissionsToAdd) Then
			
			Array = Common.ValueFromXMLString(Selection.PermissionsToAdd);
			
			For Each ArrayElement In Array Do
				PermissionsToAdd.Add(Common.XDTODataObjectFromXMLString(ArrayElement));
			EndDo;
			
		EndIf;
		
		PermissionsToDelete = New Array();
		If ValueIsFilled(Selection.PermissionsToDelete) Then
			
			Array = Common.ValueFromXMLString(Selection.PermissionsToDelete);
			
			For Each ArrayElement In Array Do
				PermissionsToDelete.Add(Common.XDTODataObjectFromXMLString(ArrayElement));
			EndDo;
			
		EndIf;
		
		Manager.AddRequestID(Selection.QueryID);
		
		Manager.AddRequestForPermissionsToUseExternalResources(
			Selection.ModuleType,
			Selection.ModuleID,
			Selection.OwnerType,
			Selection.OwnerID,
			Selection.ReplacementMode,
			PermissionsToAdd,
			PermissionsToDelete);
		
	EndDo;
	
	Manager.CalculateRequestsApplication();
	
	Return Manager;
	
EndFunction

// Checks whether an interactive request for permissions to use external resources is required.
//
// Returns: Boolean.
//
Function RequestForPermissionsToUseExternalResourcesRequired()
	
	If Not CanRequestForPermissionsToUseExternalResources() Then
		Return False;
	EndIf;
	
	Return Constants.UseSecurityProfiles.Get() AND Constants.AutomaticallyConfigurePermissionsInSecurityProfiles.Get();
	
EndFunction

// Checks whether permissions to use external resources can be requested interactively.
//
// Returns: Boolean.
//
Function CanRequestForPermissionsToUseExternalResources()
	
	If Common.FileInfobase(InfoBaseConnectionString()) OR Not GetFunctionalOption("UseSecurityProfiles") Then
		
		// In File mode or when security profiles are disabled, permission requests can be written if the 
		// privileged mode is on or by the administrator.
		Return PrivilegedMode() OR Users.IsFullUser();
		
	Else
		
		// In client/server mode, when security profiles are enabled, permission requests can be written by 
		// administrator only, regardless of whether the privileged mode is on or not.
		If Not Users.IsFullUser() Then
			
			Raise NStr("ru = 'Недостаточно прав доступа для запроса разрешений на использование внешних ресурсов.'; en = 'Insufficient access rights to request permissions to use external resources.'; pl = 'Insufficient access rights to request permissions to use external resources.';de = 'Insufficient access rights to request permissions to use external resources.';ro = 'Insufficient access rights to request permissions to use external resources.';tr = 'Insufficient access rights to request permissions to use external resources.'; es_ES = 'Insufficient access rights to request permissions to use external resources.'");
			
		EndIf;
		
		Return True;
		
	EndIf; 
	
EndFunction

// Returns a security profile name for the infobase or the external module.
//
// Parameters:
//  ExternalModule - AnyRef - a reference to the catalog item used as an external module.
//    
//
// Returns:
//   String - a security profile name.
//
Function SecurityProfileName(Val ProgramModule)
	
	If ProgramModule = Catalogs.MetadataObjectIDs.EmptyRef() Then
		
		Return Constants.InfobaseSecurityProfile.Get();
		
	Else
		
		Return InformationRegisters.ExternalModulesAttachmentModes.ExternalModuleAttachmentMode(ProgramModule);
		
	EndIf;
	
EndFunction

// Generates a security profile name for the infobase or the external module.
//
// Parameters:
//   ExternalModule - AnyRef - a reference to the catalog item used as an external module.
//                                 
//
// Returns:
//   String - a security profile name.
//
Function NewSecurityProfileName(Val ProgramModule)
	
	If ProgramModule = Catalogs.MetadataObjectIDs.EmptyRef() Then
		
		Result = "Infobase_" + String(New UUID());
		
	Else
		
		ModuleManager = SafeModeManagerInternal.ExternalModuleManager(ProgramModule);
		Template = ModuleManager.SecurityProfileNamePattern(ProgramModule);
		Return StrReplace(Template, "%1", String(New UUID()));
		
	EndIf;
	
	Return Result;
	
EndFunction

// Clears irrelevant requests to use external resources.
//
Procedure ClearObsoleteRequests() Export
	
	BeginTransaction();
	
	Try
		
		Selection = Select();
		
		While Selection.Next() Do
			
			Try
				
				varKey = CreateRecordKey(New Structure("QueryID", Selection.QueryID));
				LockDataForEdit(varKey);
				
			Except
				
				// No exception processing required.
				// Expected exception - an attempt to delete the same register record from another session.
				Continue;
				
			EndTry;
			
			Manager = CreateRecordManager();
			Manager.QueryID = Selection.QueryID;
			Manager.Delete();
			
		EndDo;
		
		CommitTransaction();
		
	Except
		
		RollbackTransaction();
		Raise;
		
	EndTry;
	
EndProcedure

// Creates blank replacement requests for all previously granted permissions.
//
// Returns: Array(UUID) - IDs of requests to replace all previously granted permissions.
//   
//
Function ReplacementRequestsForAllGrantedPermissions() Export
	
	Result = New Array();
	
	QueryText =
		"SELECT DISTINCT
		|	PermissionsTable.ModuleType,
		|	PermissionsTable.ModuleID,
		|	PermissionsTable.OwnerType,
		|	PermissionsTable.OwnerID
		|FROM
		|	InformationRegister.PermissionsToUseExternalResources AS PermissionsTable";
	
	Query = New Query(QueryText);
	Selection = Query.Execute().Select();
	
	While Selection.Next() Do
		
		ProgramModule = SafeModeManagerInternal.ReferenceFormPermissionRegister(
			Selection.ModuleType,
			Selection.ModuleID);
		
		Owner = SafeModeManagerInternal.ReferenceFormPermissionRegister(
			Selection.OwnerType,
			Selection.OwnerID);
		
		ReplacementRequest = SafeModeManagerInternal.PermissionChangeRequest(
			Owner, True, New Array(), , ProgramModule);
		
		Result.Add(ReplacementRequest);
		
	EndDo;
	
	Return Result;
	
EndFunction

// Serializes requests to use external resources.
//
// Parameters:
//  IDs - Array(UUID) - IDs requests to be serialized.
//   
//
// Returns - String.
//
Function WriteRequestsToXMLString(Val IDs) Export
	
	Result = New Array();
	
	For Each ID In IDs Do
		
		Set = CreateRecordSet();
		Set.Filter.QueryID.Set(ID);
		Set.Read();
		
		Result.Add(Set);
		
	EndDo;
	
	Return Common.ValueToXMLString(Result);
	
EndFunction

// Deserializes requests to use external resources.
//
// Parameters:
//  XMLString - String - a result of the WriteRequestsToXMLString() function.
//
Procedure ReadRequestsFromXMLString(Val XMLString) Export
	
	Queries = Common.ValueFromXMLString(XMLString);
	
	BeginTransaction();
	
	Try
		
		For Each Query In Queries Do
			Query.Write();
		EndDo;
		
		CommitTransaction();
		
	Except
		
		RollbackTransaction();
		Raise;
		
	EndTry;
	
EndProcedure

// Deletes requests to use external resources.
//
// Parameters:
//  RequestsIDs - Array(UUID) - IDs of requests to delete.
//
Procedure DeleteRequests(Val RequestsIDs) Export
	
	BeginTransaction();
	
	Try
		
		For Each QueryID In RequestsIDs Do
			
			Manager = CreateRecordManager();
			Manager.QueryID = QueryID;
			Manager.Delete();
			
		EndDo;
		
		CommitTransaction();
		
	Except
		
		RollbackTransaction();
		Raise;
		
	EndTry;
	
EndProcedure

#EndRegion

#EndIf
