///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Private

// Generates a permission key (to be used in registers, in which the granted permission details are 
// stored).
//
// Parameters:
//  Permission - XDTODataObject.
//
// Returns: String.
//
Function PermissionKey(Val Permission) Export
	
	Hashing = New DataHashing(HashFunction.MD5);
	Hashing.Append(Common.XDTODataObjectToXMLString(Permission));
	
	Addition = PermissionAddition(Permission);
	If ValueIsFilled(Addition) Then
		Hashing.Append(Common.ValueToXMLString(Addition));
	EndIf;
	
	varKey = XDTOFactory.Create(XDTOFactory.Type("http://www.w3.org/2001/XMLSchema", "hexBinary"), Hashing.HashSum).LexicalValue;
	
	If StrLen(varKey) > 32 Then
		Raise NStr("ru = 'Превышение длины ключа'; en = 'Key length exceeded'; pl = 'Key length exceeded';de = 'Key length exceeded';ro = 'Key length exceeded';tr = 'Key length exceeded'; es_ES = 'Key length exceeded'");
	EndIf;
	
	Return varKey;
	
EndFunction

// Generates a permission addition.
//
// Parameters:
//  Permission - XDTODataObject.
//
// Returns - Arbitrary (serialized to XDTO).
//
Function PermissionAddition(Val Permission) Export
	
	If Permission.Type() = XDTOFactory.Type(SafeModeManagerInternal.Package(), "AttachAddin") Then
		Return SafeModeManagerInternal.AddInBundleFilesChecksum(Permission.TemplateName);
	Else
		Return Undefined;
	EndIf;
	
EndFunction

// Returns the current slice of granted permissions.
//
// Parameters:
//  ByOwners - Boolean - if True, a returned table will contain information on permission owners, 
//    otherwise, the current slice will be collapsed by owner.
//  NoDetails - Boolean - if True, the slice will be returned with the cleared Description field for permissions.
//
// Returns - ValueTable, columns:
//   * ModuleType - CatalogRef.MetadataObjectsIDs,
//   * ModuleID - UUID,
//   * OwnerType - CatalogRef.MetadataObjectsID,
//   * OwnerID - UUID,
//   * Type - String - a XDTO type name describing permissions
//   * Permissions - Map - permission details:
//   * Key - String - a permission key (see the PermissionKey function in the register manager module.
//      PermissionsToUseExternalResources).
//   * Value - XDTODataObject - XDTO - permission details,
//   * PermissionsAdditions - Map - permission addition details:
//   * Key - String - a permission key (see the PermissionKey function in the register manager module.
//      PermissionsToUseExternalResources).
//   * Value - Structure - see the PermissionAddition function in the register manager module.
//      PermissionsToUseExternalResources).
//
Function PermissionsSlice(Val ByOwners = True, Val NoDetails = False) Export
	
	Result = New ValueTable();
	
	Result.Columns.Add("ModuleType", New TypeDescription("CatalogRef.MetadataObjectIDs"));
	Result.Columns.Add("ModuleID", New TypeDescription("UUID"));
	If ByOwners Then
		Result.Columns.Add("OwnerType", New TypeDescription("CatalogRef.MetadataObjectIDs"));
		Result.Columns.Add("OwnerID", New TypeDescription("UUID"));
	EndIf;
	Result.Columns.Add("Type", New TypeDescription("String"));
	Result.Columns.Add("Permissions", New TypeDescription("Map"));
	Result.Columns.Add("PermissionsAdditions", New TypeDescription("Map"));
	
	Selection = Select();
	
	While Selection.Next() Do
		
		Permission = Common.XDTODataObjectFromXMLString(Selection.PermissionBody);
		
		FilterByTable = New Structure();
		FilterByTable.Insert("ModuleType", Selection.ModuleType);
		FilterByTable.Insert("ModuleID", Selection.ModuleID);
		If ByOwners Then
			FilterByTable.Insert("OwnerType", Selection.OwnerType);
			FilterByTable.Insert("OwnerID", Selection.OwnerID);
		EndIf;
		FilterByTable.Insert("Type", Permission.Type().Name);
		
		Row = DataProcessors.ExternalResourcePermissionSetup.PermissionsTableRow(
			Result, FilterByTable);
		
		PermissionBody = Selection.PermissionBody;
		PermissionKey = Selection.PermissionKey;
		PermissionAddition = Selection.PermissionAddition;
		
		If NoDetails Then
			
			If ValueIsFilled(Permission.Description) Then
				
				Permission.Description = "";
				PermissionBody = Common.XDTODataObjectToXMLString(Permission);
				PermissionKey = PermissionKey(Permission);
				
			EndIf;
			
		EndIf;
		
		Row.Permissions.Insert(PermissionKey, PermissionBody);
		
		If ValueIsFilled(PermissionAddition) Then
			Row.PermissionsAdditions.Insert(PermissionKey, PermissionAddition);
		EndIf;
		
	EndDo;
	
	Return Result;
	
EndFunction

// Writes a permission to the register.
//
// Parameters:
//  ModuleType - CatalogRef.MetadataObjectsIDs,
//  ModuleID - UUID,
//  OwnerType - CatalogRef.MetadataObjectsID,
//  OwnerID - UUID,
//  PermissionKey - String - a permission key,
//  Permission - XDTODataObject - XDTO - a permission presentation,
//  PermissionAddition - Arbitrary (serialized to XDTO).
//
Procedure AddPermission(Val ModuleType, Val ModuleID, Val OwnerType, Val OwnerID, Val PermissionKey, Val Permission, Val PermissionAddition = Undefined) Export
	
	Manager = CreateRecordManager();
	Manager.ModuleType = ModuleType;
	Manager.ModuleID = ModuleID;
	Manager.OwnerType = OwnerType;
	Manager.OwnerID = OwnerID;
	Manager.PermissionKey = PermissionKey;
	
	Manager.Read();
	
	If Manager.Selected() Then
		
		Raise StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Дублирование разрешений по ключевым полям:
                  |- ТипПрограммногоМодуля: %1
                  |- ИдентификаторПрограммногоМодуля: %2
                  |- ТипВладельца: %3
                  |- ИдентификаторВладельца: %4
                  |- КлючРазрешения: %5.'; 
                  |en = 'Permission duplication by key fields:
                  |- ModuleType: %1
                  |- ModuleID: %2
                  |- OwnerType: %3
                  |- OwnerID: %4
                  |- PermissionKey: %5.'; 
                  |pl = 'Permission duplication by key fields:
                  |- ModuleType: %1
                  |- ModuleID: %2
                  |- OwnerType: %3
                  |- OwnerID: %4
                  |- PermissionKey: %5.';
                  |de = 'Permission duplication by key fields:
                  |- ModuleType: %1
                  |- ModuleID: %2
                  |- OwnerType: %3
                  |- OwnerID: %4
                  |- PermissionKey: %5.';
                  |ro = 'Permission duplication by key fields:
                  |- ModuleType: %1
                  |- ModuleID: %2
                  |- OwnerType: %3
                  |- OwnerID: %4
                  |- PermissionKey: %5.';
                  |tr = 'Permission duplication by key fields:
                  |- ModuleType: %1
                  |- ModuleID: %2
                  |- OwnerType: %3
                  |- OwnerID: %4
                  |- PermissionKey: %5.'; 
                  |es_ES = 'Permission duplication by key fields:
                  |- ModuleType: %1
                  |- ModuleID: %2
                  |- OwnerType: %3
                  |- OwnerID: %4
                  |- PermissionKey: %5.'"),
			String(ModuleType),
			String(ModuleID),
			String(OwnerType),
			String(OwnerID),
			PermissionKey);
		
	Else
		
		Manager.ModuleType = ModuleType;
		Manager.ModuleID = ModuleID;
		Manager.OwnerType = OwnerType;
		Manager.OwnerID = OwnerID;
		Manager.PermissionKey = PermissionKey;
		Manager.PermissionBody = Common.XDTODataObjectToXMLString(Permission);
		
		If ValueIsFilled(PermissionAddition) Then
			Manager.PermissionAddition = Common.ValueToXMLString(PermissionAddition);
		EndIf;
		
		Manager.Write(False);
		
	EndIf;
	
EndProcedure

// Deletes the permission from the register.
//
// Parameters:
//  ModuleType - CatalogRef.MetadataObjectsIDs,
//  ModuleID - UUID,
//  OwnerType - CatalogRef.MetadataObjectsID,
//  OwnerID - UUID,
//  PermissionKey - String - a permission key,
//  Permission - XDTODataObject - XDTO - a permission presentation.
//
Procedure DeletePermission(Val ModuleType, Val ModuleID, Val OwnerType, Val OwnerID, Val PermissionKey, Val Permission) Export
	
	Manager = CreateRecordManager();
	Manager.ModuleType = ModuleType;
	Manager.ModuleID = ModuleID;
	Manager.OwnerType = OwnerType;
	Manager.OwnerID = OwnerID;
	Manager.PermissionKey = PermissionKey;
	
	Manager.Read();
	
	If Manager.Selected() Then
		
		If Manager.PermissionBody <> Common.XDTODataObjectToXMLString(Permission) Then
			
			Raise StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'Позиция разрешений по ключам:
	                  |- ТипПрограммногоМодуля: %1
	                  |- ИдентификаторПрограммногоМодуля: %2
	                  |- ТипВладельца: %3
	                  |- ИдентификаторВладельца: %4
	                  |- КлючРазрешения: %5.'; 
	                  |en = 'Position of permissions by keys: 
	                  |- ModuleType: %1
	                  |- ModuleID: %2
	                  |- OwnerType: %3
	                  |- OwnerID: %4
	                  |- PermissionKey: %5.'; 
	                  |pl = 'Position of permissions by keys: 
	                  |- ModuleType: %1
	                  |- ModuleID: %2
	                  |- OwnerType: %3
	                  |- OwnerID: %4
	                  |- PermissionKey: %5.';
	                  |de = 'Position of permissions by keys: 
	                  |- ModuleType: %1
	                  |- ModuleID: %2
	                  |- OwnerType: %3
	                  |- OwnerID: %4
	                  |- PermissionKey: %5.';
	                  |ro = 'Position of permissions by keys: 
	                  |- ModuleType: %1
	                  |- ModuleID: %2
	                  |- OwnerType: %3
	                  |- OwnerID: %4
	                  |- PermissionKey: %5.';
	                  |tr = 'Position of permissions by keys: 
	                  |- ModuleType: %1
	                  |- ModuleID: %2
	                  |- OwnerType: %3
	                  |- OwnerID: %4
	                  |- PermissionKey: %5.'; 
	                  |es_ES = 'Position of permissions by keys: 
	                  |- ModuleType: %1
	                  |- ModuleID: %2
	                  |- OwnerType: %3
	                  |- OwnerID: %4
	                  |- PermissionKey: %5.'"),
				String(ModuleType),
				String(ModuleID),
				String(OwnerType),
				String(OwnerID),
				PermissionKey);
				
		EndIf;
		
		Manager.Delete();
		
	Else
		
		Raise StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Попытка удаления несуществующего разрешения:
                  |- ТипПрограммногоМодуля: %1
                  |- ИдентификаторПрограммногоМодуля: %2
                  |- ТипВладельца: %3
                  |- ИдентификаторВладельца: %4
                  |- КлючРазрешения: %5.'; 
                  |en = 'Attempting to delete nonexistent permission:
                  |- ModuleType: %1
                  |- ModuleID: %2
                  |- OwnerType: %3
                  |- OwnerID: %4
                  |- PermissionKey: %5.'; 
                  |pl = 'Attempting to delete nonexistent permission:
                  |- ModuleType: %1
                  |- ModuleID: %2
                  |- OwnerType: %3
                  |- OwnerID: %4
                  |- PermissionKey: %5.';
                  |de = 'Attempting to delete nonexistent permission:
                  |- ModuleType: %1
                  |- ModuleID: %2
                  |- OwnerType: %3
                  |- OwnerID: %4
                  |- PermissionKey: %5.';
                  |ro = 'Attempting to delete nonexistent permission:
                  |- ModuleType: %1
                  |- ModuleID: %2
                  |- OwnerType: %3
                  |- OwnerID: %4
                  |- PermissionKey: %5.';
                  |tr = 'Attempting to delete nonexistent permission:
                  |- ModuleType: %1
                  |- ModuleID: %2
                  |- OwnerType: %3
                  |- OwnerID: %4
                  |- PermissionKey: %5.'; 
                  |es_ES = 'Attempting to delete nonexistent permission:
                  |- ModuleType: %1
                  |- ModuleID: %2
                  |- OwnerType: %3
                  |- OwnerID: %4
                  |- PermissionKey: %5.'"),
			String(ModuleType),
			String(ModuleID),
			String(OwnerType),
			String(OwnerID),
			PermissionKey);
		
	EndIf;
	
EndProcedure

#EndRegion

#EndIf

