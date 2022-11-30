///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

#Region ForCallsFromOtherSubsystems

// StandardSubsystems.BatchObjectsModification

// Returns the object attributes that are not recommended to be edited using batch attribute 
// modification data processor.
//
// Returns:
//  Array - a list of object attribute names.
Function AttributesToSkipInBatchProcessing() Export
	
	AttributesToSkip = New Array;
	AttributesToSkip.Add("SuppliedDataID");
	AttributesToSkip.Add("SuppliedProfileChanged");
	AttributesToSkip.Add("Roles.DeleteRole");
	AttributesToSkip.Add("AccessKinds.*");
	AttributesToSkip.Add("AccessValues.*");
	
	Return AttributesToSkip;
	
EndFunction

// End StandardSubsystems.BatchObjectsModification

// StandardSubsystems.AccessManagement

// See AccessManagementOverridable.OnFillListsWithAccessRestriction. 
Procedure OnFillAccessRestriction(Restriction) Export
	
	Restriction.Text =
	"AttachAdditionalTables
	|ThisList AS AccessGroupProfiles
	|
	|LEFT JOIN Catalog.AccessGroups AS AccessGroups
	|	ON AccessGroups.Profile = AccessGroupProfiles.Ref
	|;
	|AllowReadUpdate
	|WHERE
	|	IsFolder
	|	OR Ref <> Value(Catalog.AccessGroupProfiles.Administrator)
	|	  AND IsAuthorizedUser(AccessGroups.EmployeeResponsible)";
	
EndProcedure

// End StandardSubsystems.AccessManagement

// SaaSTechnology.ExportImportData

// See DataExportImportOverridable.OnRegisterDataExportHandlers. 
Procedure BeforeExportObject(Container, ObjectExportManager, Serializer, Object, Artifacts, Cancel) Export
	
	AccessManagementInternal.BeforeExportObject(Container, ObjectExportManager, Serializer, Object, Artifacts, Cancel);
	
EndProcedure

// End SaaSTechnology.ExportImportData

#EndRegion

#EndRegion

#Region Internal

// The procedure updates descriptions of supplied profiles in access restriction parameters when a 
// configuration is modified.
// 
// Parameters:
//  HasChanges - Boolean (return value) - if recorded, True is set, otherwise, it is not changed.
//                  
//
Procedure UpdateSuppliedProfilesDescription(HasChanges = Undefined) Export
	
	SetPrivilegedMode(True);
	
	SuppliedProfiles = SuppliedProfiles();
	
	BeginTransaction();
	Try
		HasCurrentChanges = False;
		
		StandardSubsystemsServer.UpdateApplicationParameter(
			"StandardSubsystems.AccessManagement.SuppliedProfilesDescription",
			SuppliedProfiles, HasCurrentChanges);
		
		StandardSubsystemsServer.AddApplicationParameterChanges(
			"StandardSubsystems.AccessManagement.SuppliedProfilesDescription",
			?(HasCurrentChanges,
			  New FixedStructure("HasChanges", True),
			  New FixedStructure()) );
		
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;
	
EndProcedure

// The procedure updates content of the predefined profiles in the access restriction options when a 
// configuration is modified.
// 
// Parameters:
//  HasChanges - Boolean (return value) - if recorded, True is set, otherwise, it is not changed.
//                  
//
Procedure UpdatePredefinedProfileComposition(HasChanges = Undefined) Export
	
	SetPrivilegedMode(True);
	
	PredefinedProfiles = Metadata.Catalogs.AccessGroupProfiles.GetPredefinedNames();
	
	BeginTransaction();
	Try
		HasDeletedItems = False;
		HasCurrentChanges = False;
		PreviousValue = Undefined;
		
		StandardSubsystemsServer.UpdateApplicationParameter(
			"StandardSubsystems.AccessManagement.AccessGroupPredefinedProfiles",
			PredefinedProfiles, , PreviousValue);
		
		If Not PredefinedProfilesMatch(PredefinedProfiles, PreviousValue, HasDeletedItems) Then
			HasCurrentChanges = True;
		EndIf;
		
		StandardSubsystemsServer.AddApplicationParameterChanges(
			"StandardSubsystems.AccessManagement.AccessGroupPredefinedProfiles",
			?(HasDeletedItems,
			  New FixedStructure("HasDeletedItems", True),
			  New FixedStructure()) );
		
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;
	
	If HasCurrentChanges Then
		HasChanges = True;
	EndIf;
	
EndProcedure

// The procedure updates the supplied catalog profiles according to the result of changing the 
// supplied profiles saved in access restriction settings.
//
Procedure UpdateSuppliedProfilesByConfigurationChanges() Export
	
	SetPrivilegedMode(True);
	
	LastChanges = StandardSubsystemsServer.ApplicationParameterChanges(
		"StandardSubsystems.AccessManagement.SuppliedProfilesDescription");
		
	If LastChanges = Undefined Then
		UpdateRequired = True;
	Else
		UpdateRequired = False;
		For each ChangesPart In LastChanges Do
			
			If TypeOf(ChangesPart) = Type("FixedStructure")
			   AND ChangesPart.Property("HasChanges")
			   AND TypeOf(ChangesPart.HasChanges) = Type("Boolean") Then
				
				If ChangesPart.HasChanges Then
					UpdateRequired = True;
					Break;
				EndIf;
			Else
				UpdateRequired = True;
				Break;
			EndIf;
		EndDo;
	EndIf;
	
	If UpdateRequired Then
		UpdateSuppliedProfiles();
	EndIf;
	
EndProcedure

// Updates supplied profiles and when necessary updates access groups of these profiles.
// If any access group supplied profiles are not found, they are created.
//
// Update details are configured in the FillAccessGroupsSuppliedProfiles procedure of the 
// AccessManagementOverridable common module (see comments to the procedure).
//
// Parameters:
//  HasChanges - Boolean (return value) - if recorded, True is set, otherwise, it is not changed.
//                  
//
Procedure UpdateSuppliedProfiles(HasChanges = Undefined) Export
	
	SuppliedProfiles = AccessManagementInternalCached.SuppliedProfilesDescription();
	
	ProfilesDetails    = SuppliedProfiles.ProfilesDetailsArray;
	UpdateParameters = SuppliedProfiles.UpdateParameters;
	UpdatedProfiles  = New Array;
	
	Query = New Query;
	Query.SetParameter("BlankUUID",
		CommonClientServer.BlankUUID());
	Query.Text =
	"SELECT
	|	AccessGroupProfiles.SuppliedProfileChanged AS SuppliedProfileChanged,
	|	AccessGroupProfiles.SuppliedDataID AS SuppliedDataID,
	|	AccessGroupProfiles.Ref AS Ref,
	|	FALSE AS Found
	|FROM
	|	Catalog.AccessGroupProfiles AS AccessGroupProfiles
	|WHERE
	|	NOT AccessGroupProfiles.IsFolder
	|	AND AccessGroupProfiles.SuppliedDataID <> &BlankUUID";
	CurrentProfiles = Query.Execute().Unload();
	
	For Each ProfileProperties In ProfilesDetails Do
		
		CurrentProfileRow = CurrentProfiles.Find(
			New UUID(ProfileProperties.ID),
			"SuppliedDataID");
		
		ProfileUpdated = False;
		
		If CurrentProfileRow = Undefined Then
			// Creating a new supplied profile.
			If UpdateAccessGroupsProfile(ProfileProperties, True) Then
				HasChanges = True;
			EndIf;
			Profile = SuppliedProfileByID(ProfileProperties.ID);
			
		Else
			CurrentProfileRow.Found = True;
			
			Profile = CurrentProfileRow.Ref;
			If NOT CurrentProfileRow.SuppliedProfileChanged
			 OR UpdateParameters.UpdateModifiedProfiles Then
				// Updating a supplied profile.
				ProfileUpdated = UpdateAccessGroupsProfile(ProfileProperties, True);
			EndIf;
		EndIf;
		
		If UpdateParameters.UpdatingAccessGroups Then
			ProfileAccessGroupsUpdated = Catalogs.AccessGroups.UpdateProfileAccessGroups(
				Profile, UpdateParameters.UpdatingAccessGroupsWithObsoleteSettings);
			
			ProfileUpdated = ProfileUpdated OR ProfileAccessGroupsUpdated;
		EndIf;
		
		If ProfileUpdated Then
			HasChanges = True;
			UpdatedProfiles.Add(Profile);
		EndIf;
	EndDo;
	
	For Each CurrentProfileRow In CurrentProfiles Do
		If CurrentProfileRow.Found Then
			Continue;
		EndIf;
		If CurrentProfileRow.SuppliedProfileChanged Then
			Continue;
		EndIf;
		ProfileObject = CurrentProfileRow.Ref.GetObject();
		If ProfileObject.DeletionMark Then
			Continue;
		EndIf;
		ProfileObject.DeletionMark = True;
		InfobaseUpdate.WriteObject(ProfileObject);
		UpdatedProfiles.Add(ProfileObject.Ref);
		HasChanges = True;
	EndDo;
	
	UpdateAuxiliaryProfilesData(UpdatedProfiles, HasChanges);
	
EndProcedure

Procedure UpdateAuxiliaryProfilesData(Profiles = Undefined, HasChanges = False) Export
	
	If Profiles = Undefined Then
		InformationRegisters.AccessGroupsTables.UpdateRegisterData( , , HasChanges);
		InformationRegisters.AccessGroupsValues.UpdateRegisterData( , HasChanges);
		AccessManagementInternal.UpdateUserRoles( , , HasChanges);
		
	ElsIf Profiles.Count() > 0 Then
		ProfilesAccessGroups = Catalogs.AccessGroups.ProfileAccessGroups(Profiles);
		InformationRegisters.AccessGroupsTables.UpdateRegisterData(ProfilesAccessGroups, , HasChanges);
		InformationRegisters.AccessGroupsValues.UpdateRegisterData(ProfilesAccessGroups, HasChanges);
		
		// Updating user roles.
		UsersForUpdate =
			Catalogs.AccessGroups.UsersForRolesUpdateByProfile(Profiles);
		
		AccessManagementInternal.UpdateUserRoles(UsersForUpdate, , HasChanges);
	EndIf;
	
EndProcedure

// See ToDoListOverridable.OnDetermineToDoListHandlers 
Procedure OnFillToDoList(ToDoList) Export
	
	ModuleToDoListServer = Common.CommonModule("ToDoListServer");
	If Not Users.IsFullUser()
		Or ModuleToDoListServer.UserTaskDisabled("AccessGroupProfiles") Then
		Return;
	EndIf;
	
	// This procedure is only called when To-do list subsystem is available. Therefore, the subsystem 
	// availability check is redundant.
	Sections = ModuleToDoListServer.SectionsForObject(Metadata.Catalogs.AccessGroupProfiles.FullName());
	
	For Each Section In Sections Do
		
		IncompatibleAccessGroupsProfilesCount = IncompatibleAccessGroupsProfiles().Count();
		
		ProfileID = "IncompatibleWithCurrentVersion" + StrReplace(Section.FullName(), ".", "");
		ToDoItem = ToDoList.Add();
		ToDoItem.ID = ProfileID;
		ToDoItem.HasToDoItems      = IncompatibleAccessGroupsProfilesCount > 0;
		ToDoItem.Presentation = NStr("ru = 'Не совместимы с текущей версией'; en = 'Incompatible with current version'; pl = 'Niekompatybilny z aktualną wersją';de = 'Nicht kompatibel mit der aktuellen Version';ro = 'Nu sunt compatibile cu versiunea curentă';tr = 'Mevcut sürüm ile uyumlu değildir'; es_ES = 'No es compatible con la versión actual'");
		ToDoItem.Count    = IncompatibleAccessGroupsProfilesCount;
		ToDoItem.Owner      = Section;
		
		ToDoItem = ToDoList.Add();
		ToDoItem.ID = "AccessGroupProfiles";
		ToDoItem.HasToDoItems      = IncompatibleAccessGroupsProfilesCount > 0;
		ToDoItem.Important        = True;
		ToDoItem.Presentation = NStr("ru = 'Профили групп доступа'; en = 'Access group profiles'; pl = 'Profile grup dostępu';de = 'Zugriffsgruppenprofile';ro = 'Profiluri grupuri de acces';tr = 'Erişim grubu profilleri'; es_ES = 'Perfiles del grupo de acceso'");
		ToDoItem.Count    = IncompatibleAccessGroupsProfilesCount;
		ToDoItem.Form         = "Catalog.AccessGroupProfiles.Form.ListForm";
		ToDoItem.FormParameters= New Structure("ProfilesWithRolesMarkedForDeletion", True);
		ToDoItem.Owner      = ProfileID;
		
	EndDo;
	
EndProcedure

#EndRegion

#Region Private

// Returns a string UUID of the supplied and predefined Administrator profile.
// 
//
Function AdministratorProfileID(Row = True) Export
	
	ID = "6c4b0307-43a4-4141-9c35-3dd7e9586d41";
	
	If Row Then
		Return ID;
	EndIf;
	
	Return New UUID(ID);
	
EndFunction

// Returns a reference to a supplied profile by ID.
//
// Parameters:
//  ID - String - a name or UUID of the supplied profile.
//
Function SuppliedProfileByID(ID, RaiseExceptionIfMissingInDatabase = False) Export
	
	SetPrivilegedMode(True);
	
	SuppliedProfiles = AccessManagementInternalCached.SuppliedProfilesDescription();
	ProfileProperties = SuppliedProfiles.ProfilesDetails.Get(String(ID));
	
	If ProfileProperties = Undefined Then
		Raise StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Профиль c идентификатором ""%1""
			           |не поставляется в программе.'; 
			           |en = 'Profile with ID ""%1""
			           |is not supplied in the application.'; 
			           |pl = 'Profil z identyfikatorem ""%1""
			           |nie jest dostarczany w programie.';
			           |de = 'Das Profil mit der Kennung ""%1""
			           |ist im Programm nicht enthalten.';
			           |ro = 'Profilul cu identificatorul ""%1""
			           |nu se furnizează în program.';
			           |tr = '""%1"" 
			           |kimliğine sahip profil uygulamada teslim edilmez.'; 
			           |es_ES = 'El perfil con el identificador ""%1""
			           |no se suministra en el programa.'"),
			String(ID));
	EndIf;
	
	Query = New Query;
	Query.SetParameter("SuppliedDataID",
		New UUID(ProfileProperties.ID));
	
	Query.Text =
	"SELECT
	|	AccessGroupProfiles.Ref AS Ref
	|FROM
	|	Catalog.AccessGroupProfiles AS AccessGroupProfiles
	|WHERE
	|	AccessGroupProfiles.SuppliedDataID = &SuppliedDataID";
	
	Selection = Query.Execute().Select();
	
	If Selection.Next() Then
		Return Selection.Ref;
	EndIf;
	
	If RaiseExceptionIfMissingInDatabase Then
		Raise StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Поставляемый профиль с идентификатором ""%1""
			           |не найден в информационной базе.'; 
			           |en = 'Supplied profile with ID ""%1""
			           |is not found in the infobase.'; 
			           |pl = 'Dostarczany profil z identyfikatorem ""%1""
			           |nie został znaleziony w bazie informacyjnej.';
			           |de = 'Das angegebene Profil mit der Kennung ""%1""
			           |wurde nicht in der Informationsdatenbank gefunden.';
			           |ro = 'Profilul furnizat cu identificatorul ""%1""
			           |nu a fost găsit în baza de informații.';
			           |tr = '""%1"" 
			           | kimliğine sahip profil veri tabanında bulunamadı.'; 
			           |es_ES = 'El perfil suministrado con el identificador ""%1""
			           |no se ha encontrado en la base de información.'"),
			String(ID));
	EndIf;
	
	Return Undefined;
	
EndFunction

// Returns a string UUID of supplied profile data.
// 
//
Function SuppliedProfileID(Profile) Export
	
	SetPrivilegedMode(True);
	
	Query = New Query;
	Query.SetParameter("Ref", Profile);
	
	Query.SetParameter("BlankUUID",
		CommonClientServer.BlankUUID());
	
	Query.Text =
	"SELECT
	|	AccessGroupProfiles.SuppliedDataID
	|FROM
	|	Catalog.AccessGroupProfiles AS AccessGroupProfiles
	|WHERE
	|	AccessGroupProfiles.Ref = &Ref
	|	AND AccessGroupProfiles.SuppliedDataID <> &BlankUUID";
	
	Selection = Query.Execute().Select();
	If Selection.Next() Then
		Return String(Selection.SuppliedDataID);
	EndIf;
	
	Return Undefined;
	
EndFunction

// Checks whether the supplied profile is changed compared to the procedure description.
// AccessManagementOverridable.FillAccessGroupsSuppliedProfiles().
//
// Parameters:
//  Profile - CatalogRef.AccessGroupsProfiles (returns the SuppliedProfileChanged attribute),
//                     
//               - CatalogObject.AccessGroupsProfiles (returns the result of object filling 
//                     comparison to description in the overridable common module).
//                      
//
// Returns:
//  Boolean.
//
Function SuppliedProfileChanged(Profile) Export
	
	If TypeOf(Profile) = Type("CatalogRef.AccessGroupProfiles") Then
		Return Common.ObjectAttributeValue(Profile, "SuppliedProfileChanged");
	EndIf;
	
	ProfilesDetails = AccessManagementInternalCached.SuppliedProfilesDescription().ProfilesDetails;
	ProfileProperties = ProfilesDetails.Get(String(Profile.SuppliedDataID));
	
	If ProfileProperties = Undefined Then
		Return False;
	EndIf;
	
	ProfileRolesDetails = ProfileRolesDetails(ProfileProperties);
	
	If Upper(Profile.Description) <> Upper(ProfileProperties.Description) Then
		Return True;
	EndIf;
	
	If Profile.Roles.Count()            <> ProfileRolesDetails.Count()
	 OR Profile.AccessKinds.Count()     <> ProfileProperties.AccessKinds.Count()
	 OR Profile.AccessValues.Count() <> ProfileProperties.AccessValues.Count()
	 OR Profile.Purpose.Count()      <> ProfileProperties.Purpose.Count() Then
		Return True;
	EndIf;
	
	For each Role In ProfileRolesDetails Do
		RoleMetadata = Metadata.Roles.Find(Role);
		If RoleMetadata = Undefined Then
			Raise StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'При проверке поставляемого профиля ""%1""
				           |роль ""%2"" не найдена в метаданных.'; 
				           |en = 'When checking supplied profile ""%1"", 
				           |role ""%2"" was not found in the metadata.'; 
				           |pl = 'Podczas weryfikacji dostarczanego profilu ""%1""
				           |rola ""%2"" nie została znaleziona w metadanych.';
				           |de = 'Bei der Überprüfung des angegebenen Profils ""%1""
				           |wurde Rolle ""%2"" nicht in den Metadaten gefunden.';
				           |ro = 'În timpul verificării profilului furnizat
				           |""%1"", rolul ""%2"" nu este găsit în metadate.';
				           |tr = 'Sağlanan profil kontrolünde meta veride 
				           |%1rol ""%2"" bulunamadı.'; 
				           |es_ES = 'Al comprobar el perfil suministrado ""%1""
				           | el rol ""%2"" no se ha encontrado en metadatos.'"),
				ProfileProperties.Description,
				Role);
		EndIf;
		RoleID = Common.MetadataObjectID(RoleMetadata);
		If Profile.Roles.FindRows(New Structure("Role", RoleID)).Count() = 0 Then
			Return True;
		EndIf;
	EndDo;
	
	For each AccessKindDetails In ProfileProperties.AccessKinds Do
		AccessKindProperties = AccessManagementInternal.AccessKindProperties(AccessKindDetails.Key);
		Filter = New Structure;
		Filter.Insert("AccessKind",        AccessKindProperties.Ref);
		Filter.Insert("PresetAccessKind", AccessKindDetails.Value = "PresetAccessKind");
		Filter.Insert("AllAllowed",      AccessKindDetails.Value = "AllAllowedByDefault");
		If Profile.AccessKinds.FindRows(Filter).Count() = 0 Then
			Return True;
		EndIf;
	EndDo;
	
	For each AccessValueDetails In ProfileProperties.AccessValues Do
		Filter = New Structure;
		Query = New Query(StrReplace("SELECT Value(%1) AS Value", "%1", AccessValueDetails.AccessValue));
		Filter.Insert("AccessValue", Query.Execute().Unload()[0].Value);
		If Profile.AccessValues.FindRows(Filter).Count() = 0 Then
			Return True;
		EndIf;
	EndDo;
	
	For Each UsersType In ProfileProperties.Purpose Do
		Filter = New Structure;
		Filter.Insert("UsersType", UsersType);
		If Profile.Purpose.FindRows(Filter).Count() = 0 Then
			Return True;
		EndIf;
	EndDo;
	
	Return False;
	
EndFunction

// Checks whether initial filling is done for an access group profile in an overridable module.
//
// Parameters:
//  Profile - CatalogRef.AccessGroupsProfiles.
//  
// Returns:
//  Boolean.
//
Function HasInitialProfileFilling(Val Profile) Export
	
	SuppliedDataID = String(Common.ObjectAttributeValue(
		Profile, "SuppliedDataID"));
	
	SuppliedProfiles = AccessManagementInternalCached.SuppliedProfilesDescription();
	ProfileProperties = SuppliedProfiles.ProfilesDetails.Get(SuppliedDataID);
	
	Return ProfileProperties <> Undefined;
	
EndFunction

// Determines whether the supplied profile is prohibited from editing.
// Not supplied profiles cannot be prohibited from editing.
//
// Parameters:
//  Profile - CatalogObject.AccessGroupsProfiles,
//                 DataFormStructure generated according to the object.
//  
// Returns:
//  Boolean.
//
Function ProfileChangeProhibition(Val Profile) Export
	
	If Profile.SuppliedDataID =
			New UUID(AdministratorProfileID()) Then
		// Changing the Administrator profile is always prohibited.
		Return True;
	EndIf;
	
	SuppliedProfiles = AccessManagementInternalCached.SuppliedProfilesDescription();
	
	ProfileProperties = SuppliedProfiles.ProfilesDetails.Get(
		String(Profile.SuppliedDataID));
	
	Return ProfileProperties <> Undefined
	      AND SuppliedProfiles.UpdateParameters.DenyProfilesChange;
	
EndFunction

// Returns the supplied profile assignment description.
//
// Parameters:
//  Profile - CatalogRef.AccessGroupsProfiles.
//
// Returns:
//  String.
//
Function SuppliedProfileDetails(Profile) Export
	
	SuppliedDataID = String(Common.ObjectAttributeValue(
		Profile, "SuppliedDataID"));
	
	SuppliedProfiles = AccessManagementInternalCached.SuppliedProfilesDescription();
	ProfileProperties = SuppliedProfiles.ProfilesDetails.Get(SuppliedDataID);
	
	Text = "";
	If ProfileProperties <> Undefined Then
		Text = ProfileProperties.Details;
	EndIf;
	
	Return Text;
	
EndFunction

// Creates a supplied profile in the AccessGroupsProfiles catalog, and allows to refill a previously 
// created supplied profile by its supplied description.
// 
//  Initial filling is searched by string UUD of the profile.
//
// Parameters:
//  Profile - CatalogRef.AccessGroupsProfiles.
//                 If initial filling description is found for the profile, the profile content is 
//                 completely replaced.
//
// UpdateAccessGroups - Boolean, if True, access kinds of profile access groups are updated.
//
Procedure FillSuppliedProfile(Val Profile, Val UpdateAccessGroups) Export
	
	SuppliedDataID = String(Common.ObjectAttributeValue(
		Profile, "SuppliedDataID"));
	
	SuppliedProfiles = AccessManagementInternalCached.SuppliedProfilesDescription();
	ProfileProperties = SuppliedProfiles.ProfilesDetails.Get(SuppliedDataID);
	
	If ProfileProperties <> Undefined Then
		
		UpdateAccessGroupsProfile(ProfileProperties);
		
		If UpdateAccessGroups Then
			Catalogs.AccessGroups.UpdateProfileAccessGroups(Profile, True);
		EndIf;
	EndIf;
	
EndProcedure

// Returns a list of references to profiles containing unavailable roles or roles marked for deletion.
//
// Returns:
//  Array - an array of elements CatalogRef.AccessGroupsProfiles.
//
Function IncompatibleAccessGroupsProfiles() Export
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	Profiles.Ref AS Ref,
	|	Profiles.Purpose.(
	|		UsersType AS UsersType
	|	) AS Purpose,
	|	Profiles.Roles.(
	|		Role AS Role
	|	) AS Roles
	|FROM
	|	Catalog.AccessGroupProfiles AS Profiles";
	
	DataExported = Query.Execute().Unload();
	
	IncompatibleProfiles = New Array;
	UnavailableRolesByAssignment = New Map;
	
	For Each ProfileDetails In DataExported Do
		ProfileAssignment = AccessManagementInternalClientServer.ProfileAssignment(ProfileDetails);
		UnavailableRoles = UnavailableRolesByAssignment.Get(ProfileAssignment);
		If UnavailableRoles = Undefined Then
			UnavailableRoles = UsersInternalCached.UnavailableRoles(ProfileAssignment);
			UnavailableRolesByAssignment.Insert(ProfileAssignment, UnavailableRoles);
		EndIf;
		
		If ProfileDetails.Roles.Find(Undefined, "Role") <> Undefined Then
			IncompatibleProfiles.Add(ProfileDetails.Ref);
			Continue;
		EndIf;
		
		RolesDetails = Common.MetadataObjectsByIDs(
			ProfileDetails.Roles.UnloadColumn("Role"), False);
		
		For Each RoleDetails In RolesDetails Do
			If RoleDetails.Value = Undefined Then
				// A role, which is not available until the application restart, is not a problem.
				Continue;
			EndIf;
			
			If RoleDetails.Value = Null
			 Or UnavailableRoles.Get(RoleDetails.Value.Name) <> Undefined
			 Or Upper(Left(RoleDetails.Value.Name, StrLen("Delete"))) = Upper("Delete") Then
				
				IncompatibleProfiles.Add(ProfileDetails.Ref);
				Break;
			EndIf;
		EndDo;
	EndDo;
	
	Return IncompatibleProfiles;
	
EndFunction

// See Catalogs.AccessGroupsProfiles.SuppliedProfiles. 
Function SuppliedProfilesDescription() Export
	
	SuppliedProfiles = StandardSubsystemsServer.ApplicationParameter(
		"StandardSubsystems.AccessManagement.SuppliedProfilesDescription");
	
	If SuppliedProfiles = Undefined Then
		UpdateSuppliedProfilesDescription();
	EndIf;
	
	SuppliedProfiles = StandardSubsystemsServer.ApplicationParameter(
		"StandardSubsystems.AccessManagement.SuppliedProfilesDescription");
	
	Return SuppliedProfiles;
	
EndFunction

Function AccessKindsOrValuesOrAssignmentChanged(PreviousValues, CurrentObject) Export
	
	If PreviousValues.Ref <> CurrentObject.Ref Then
		Return True;
	EndIf;
	
	AccessKinds     = PreviousValues.AccessKinds.Unload();
	AccessValues = PreviousValues.AccessValues.Unload();
	Assignment      = PreviousValues.Purpose.Unload();
	
	If AccessKinds.Count()     <> CurrentObject.AccessKinds.Count()
	 Or AccessValues.Count() <> CurrentObject.AccessValues.Count()
	 Or Assignment.Count()      <> CurrentObject.Purpose.Count() Then
		
		Return True;
	EndIf;
	
	Filter = New Structure("AccessKind, PresetAccessKind, AllAllowed");
	For Each Row In CurrentObject.AccessKinds Do
		FillPropertyValues(Filter, Row);
		If AccessKinds.FindRows(Filter).Count() = 0 Then
			Return True;
		EndIf;
	EndDo;
	
	Filter = New Structure("AccessKind, AccessValue");
	For Each Row In CurrentObject.AccessValues Do
		FillPropertyValues(Filter, Row);
		If AccessValues.FindRows(Filter).Count() = 0 Then
			Return True;
		EndIf;
	EndDo;
	
	Filter = New Structure("UsersType");
	For Each Row In CurrentObject.Purpose Do
		FillPropertyValues(Filter, Row);
		If Assignment.FindRows(Filter).Count() = 0 Then
			Return True;
		EndIf;
	EndDo;
	
	Return False;
	
EndFunction

////////////////////////////////////////////////////////////////////////////////
// Procedures and functions to support data exchange in DIB.

// For internal use only.
Procedure RestoreExtensionsRolesComponents(DataItem) Export
	
	DeleteExtensionsRoles(DataItem);
	
	Query = New Query;
	Query.SetParameter("Profile", DataItem.Ref);
	Query.Text =
	"SELECT DISTINCT
	|	ProfileRoles.Role AS Role
	|FROM
	|	Catalog.AccessGroupProfiles.Roles AS ProfileRoles
	|WHERE
	|	ProfileRoles.Ref = &Profile
	|	AND VALUETYPE(ProfileRoles.Role) = TYPE(Catalog.ExtensionObjectIDs)";
	
	// Adding extension roles to new components of configuration roles.
	Selection = Query.Execute().Select();
	While Selection.Next() Do
		DataItem.Roles.Add().Role = Selection.Role;
	EndDo;
	
EndProcedure

// For internal use only.
Procedure DeleteExtensionsRoles(DataItem) Export
	
	Index = DataItem.Roles.Count() - 1;
	While Index >= 0 Do
		If TypeOf(DataItem.Roles[Index].Role) <> Type("CatalogRef.MetadataObjectIDs") Then
			DataItem.Roles.Delete(Index);
		EndIf;
		Index = Index - 1;
	EndDo;
	
EndProcedure

// For internal use only.
Procedure DeleteExtensionsRolesInAllAccessGroupsProfiles() Export
	
	Query = New Query;
	Query.Text =
	"SELECT DISTINCT
	|	ProfileRoles.Ref AS Ref
	|FROM
	|	Catalog.AccessGroupProfiles.Roles AS ProfileRoles
	|WHERE
	|	VALUETYPE(ProfileRoles.Role) <> TYPE(Catalog.MetadataObjectIDs)";
	
	HasChanges = False;
	
	Selection = Query.Execute().Select();
	While Selection.Next() Do
		ProfileObject = Selection.Ref.GetObject();
		DeleteExtensionsRoles(ProfileObject);
		If ProfileObject.Modified() Then
			InfobaseUpdate.WriteObject(ProfileObject, False);
			HasChanges = True;
		EndIf;
	EndDo;
	
	If HasChanges Then
		InformationRegisters.AccessGroupsTables.UpdateRegisterData();
	EndIf;
	
EndProcedure

// For internal use only.
Procedure RegisterProfileChangedOnImport(DataItem) Export
	
	// Registering profiles for whose access groups you need to update information registers
	// AccessGroupsTables, AccessGroupsValues, DefaultAccessGroupsValues, and user roles.
	
	PreviousValues = Common.ObjectAttributesValues(DataItem.Ref,
		"Ref, DeletionMark, Roles, Purpose, AccessKinds, AccessValues");
	
	RegistrationRegistration = False;
	Profile = DataItem.Ref;
	
	If TypeOf(DataItem) = Type("ObjectDeletion") Then
		RegistrationRegistration = True;
		
	ElsIf PreviousValues.Ref <> DataItem.Ref Then
		RegistrationRegistration = True;
		Profile = UsersInternal.ObjectRef(DataItem);
		
	ElsIf PreviousValues.DeletionMark <> DataItem.DeletionMark
	      Or AccessKindsOrValuesOrAssignmentChanged(PreviousValues, DataItem) Then
		
		RegistrationRegistration = True;
	Else
		OldRoles = PreviousValues.Roles.Unload();
		If OldRoles.Count() <> DataItem.Roles.Count() Then
			RegistrationRegistration = True;
		Else
			For Each Row In DataItem.Roles Do
				If OldRoles.Find(Row.Role, "Role") = Undefined Then
					RegistrationRegistration = True;
					Break;
				EndIf;
			EndDo;
		EndIf;
	EndIf;
	
	If Not RegistrationRegistration Then
		Return;
	EndIf;
	
	Catalogs.AccessGroups.RegisterRefs("Profiles", Profile);
	
EndProcedure

// For internal use only.
Procedure UpdateAuxiliaryProfilesDataChangedOnImport() Export
	
	If Common.DataSeparationEnabled() Then
		// Changes to profiles in SWP are blocked and are not imported into the data area.
		Return;
	EndIf;
	
	ChangedProfiles = Catalogs.AccessGroups.RegisteredRefs("Profiles");
	
	If ChangedProfiles.Count() = 0 Then
		Return;
	EndIf;
	
	If ChangedProfiles.Count() = 1
	   AND ChangedProfiles[0] = Undefined Then
		
		UpdateAuxiliaryProfilesData();
	Else
		UpdateAuxiliaryProfilesData(ChangedProfiles);
	EndIf;
	
	Catalogs.AccessGroups.RegisterRefs("Profiles", Null);
	
EndProcedure

// Infobase update handlers.

// Fills in supplied data IDs upon match to the reference ID.
Procedure FillSuppliedDataIDs() Export
	
	SetPrivilegedMode(True);
	
	SuppliedProfiles = AccessManagementInternalCached.SuppliedProfilesDescription();
	
	SuppliedProfileReferences = New Array;
	
	For each ProfileDetails In SuppliedProfiles.ProfilesDetailsArray Do
		SuppliedProfileReferences.Add(GetRef(
			New UUID(ProfileDetails.ID)));
	EndDo;
	
	Query = New Query;
	Query.SetParameter("BlankUUID",
		CommonClientServer.BlankUUID());
	
	Query.SetParameter("SuppliedProfileReferences", SuppliedProfileReferences);
	Query.Text =
	"SELECT
	|	AccessGroupProfiles.Ref
	|FROM
	|	Catalog.AccessGroupProfiles AS AccessGroupProfiles
	|WHERE
	|	AccessGroupProfiles.SuppliedDataID = &BlankUUID
	|	AND AccessGroupProfiles.Ref IN (&SuppliedProfileReferences)";
	
	Selection = Query.Execute().Select();
	
	While Selection.Next() Do
		ProfileObject = Selection.Ref.GetObject();
		ProfileObject.SuppliedDataID = Selection.Ref.UUID();
		InfobaseUpdate.WriteData(ProfileObject);
	EndDo;
	
EndProcedure

// Replaces a reference to CCT.AccessKinds with a blank reference of main type of access kind values.
Procedure ConvertAccessKindsIDs() Export
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	AccessGroupProfiles.Ref AS Ref
	|FROM
	|	Catalog.AccessGroupProfiles AS AccessGroupProfiles
	|WHERE
	|	(TRUE IN
	|				(SELECT TOP 1
	|					TRUE
	|				FROM
	|					Catalog.AccessGroupProfiles.AccessKinds AS AccessKinds
	|				WHERE
	|					AccessKinds.Ref = AccessGroupProfiles.Ref
	|					AND VALUETYPE(AccessKinds.AccessKind) = TYPE(ChartOfCharacteristicTypes.DeleteAccessKinds))
	|			OR TRUE IN
	|				(SELECT TOP 1
	|					TRUE
	|				FROM
	|					Catalog.AccessGroupProfiles.AccessValues AS AccessValues
	|				WHERE
	|					AccessValues.Ref = AccessGroupProfiles.Ref
	|					AND VALUETYPE(AccessValues.AccessKind) = TYPE(ChartOfCharacteristicTypes.DeleteAccessKinds)))
	|
	|UNION ALL
	|
	|SELECT
	|	AccessGroups.Ref
	|FROM
	|	Catalog.AccessGroups AS AccessGroups
	|WHERE
	|	(TRUE IN
	|				(SELECT TOP 1
	|					TRUE
	|				FROM
	|					Catalog.AccessGroups.AccessKinds AS AccessKinds
	|				WHERE
	|					AccessKinds.Ref = AccessGroups.Ref
	|					AND VALUETYPE(AccessKinds.AccessKind) = TYPE(ChartOfCharacteristicTypes.DeleteAccessKinds))
	|			OR TRUE IN
	|				(SELECT TOP 1
	|					TRUE
	|				FROM
	|					Catalog.AccessGroups.AccessValues AS AccessValues
	|				WHERE
	|					AccessValues.Ref = AccessGroups.Ref
	|					AND VALUETYPE(AccessValues.AccessKind) = TYPE(ChartOfCharacteristicTypes.DeleteAccessKinds)))";
	
	Selection = Query.Execute().Select();
	
	If Selection.Count() = 0 Then
		Return;
	EndIf;
	
	AccessKindsProperties = AccessManagementInternalCached.AccessKindsProperties();
	
	While Selection.Next() Do
		Object = Selection.Ref.GetObject();
		
		Index = Object.AccessKinds.Count()-1;
		While Index >= 0 Do
			Row = Object.AccessKinds[Index];
			Try
				AccessKindName = ChartsOfCharacteristicTypes.DeleteAccessKinds.GetPredefinedItemName(
					Row.AccessKind);
			Except
				AccessKindName = "";
			EndTry;
			AccessKindProperties = AccessKindsProperties.ByNames.Get(AccessKindName);
			If AccessKindProperties = Undefined Then
				Object.AccessKinds.Delete(Index);
			Else
				Row.AccessKind = AccessKindProperties.Ref;
			EndIf;
			Index = Index - 1;
		EndDo;
		
		Index = Object.AccessValues.Count()-1;
		While Index >= 0 Do
			Row = Object.AccessValues[Index];
			Try
				AccessKindName = ChartsOfCharacteristicTypes.DeleteAccessKinds.GetPredefinedItemName(
					Row.AccessKind);
			Except
				AccessKindName = "";
			EndTry;
			AccessKindProperties = AccessKindsProperties.ByNames.Get(AccessKindName);
			If AccessKindProperties = Undefined Then
				Object.AccessValues.Delete(Index);
			Else
				Row.AccessKind = AccessKindProperties.Ref;
				If Object.AccessKinds.Find(Row.AccessKind, "AccessKind") = Undefined Then
					Object.AccessValues.Delete(Index);
				EndIf;
			EndIf;
			Index = Index - 1;
		EndDo;
		InfobaseUpdate.WriteData(Object);
	EndDo;
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Auxiliary procedures and functions.

Function SuppliedProfiles()
	
	UpdateParameters = New Structure;
	// Properties of supplied profile updates.
	UpdateParameters.Insert("UpdateModifiedProfiles", True);
	UpdateParameters.Insert("DenyProfilesChange", True);
	// Properties of update of supplied profile access groups.
	UpdateParameters.Insert("UpdatingAccessGroups", True);
	UpdateParameters.Insert("UpdatingAccessGroupsWithObsoleteSettings", False);
	
	ProfilesDetails = New Array;
	
	SSLSubsystemsIntegration.OnFillSuppliedAccessGroupProfiles(
		ProfilesDetails, UpdateParameters);
	
	AccessManagementOverridable.OnFillSuppliedAccessGroupProfiles(
		ProfilesDetails, UpdateParameters);
	
	ErrorTitle =
		NStr("ru = 'Заданы недопустимые значения в процедуре ПриЗаполненииПоставляемыхПрофилейГруппДоступа
		           |общего модуля УправлениеДоступомПереопределяемый.'; 
		           |en = 'Invalid values in the OnFillSuppliedAccessGroupProfiles procedure
		           |of the AccessManagementOverridable common module.'; 
		           |pl = 'W procedurze OnFillSuppliedAccessGroupProfiles
		           |modułu ogólnego AccessManagementOverridable określono niedozwolone wartości.';
		           |de = 'Ungültige Werte im Verfahren OnFillSuppliedAccessGroupProfiles
		           |des gemeinsamen Moduls AccessManagementOverridable.';
		           |ro = 'Au fost specificate valori inadmisibile în procedura OnFillSuppliedAccessGroupProfiles
		           |a modulului general AccessManagementOverridable.';
		           |tr = 'ErişimYönetimiYenidenBelirlenen ortak modülün AccessManagementOverridable
		           |prosedürümde belirlenen değerler kabul edilemez.  '; 
		           |es_ES = 'Valores no válidos en el procedimiento OnFillSuppliedAccessGroupProfiles 
		           |del módulo común de Access Management Overridable.'")
		+ Chars.LF
		+ Chars.LF;
	
	If UpdateParameters.DenyProfilesChange
	   AND NOT UpdateParameters.UpdateModifiedProfiles Then
		
		Raise ErrorTitle
			+ NStr("ru = 'Когда в параметре ПараметрыОбновления свойство
			             |ОбновлятьИзмененныеПрофили установлено Ложь,
			             |тогда свойство ЗапретитьИзменениеПрофилей тоже
			             |должно быть установлено Ложь.'; 
			             |en = 'When the UpdateChangedProfiles property 
			             |of the UpdateParameters parameter is set to False, 
			             |the DenyProfilesChange property 
			             |must also be set to False.'; 
			             |pl = 'Kiedy w parametrze ParametryAktualizacji dla właściwości
			             |ZaktualizujZmienioneProfile ustawiono Fałsz,
			             |dla właściwości ZabrońZmianProfili również
			             |musi być ustawione Fałsz.';
			             |de = 'Wenn die Eigenschaft GeänderteProfileAktualisieren im Parameter AktualisierungsOptionen
			             | auf Falsch gesetzt ist,
			             |sollte die Eigenschaft GeänderteProfileVerweigern ebenfalls
			             |auf Falsch gesetzt sein.';
			             |ro = 'Dacă în parametrul ПараметрыОбновления proprietatea
			             |ОбновлятьИзмененныеПрофили este setată la Fals,
			             |atunci proprietatea ЗапретитьИзменениеПрофилей de asemenea
			             |trebuie să fie setată la Fals.';
			             |tr = 'GüncellemeParametreleri parametresinde DeğiştirilmişProfilleriGüncelle özelliği 
			             |
			             |Yanlış olarak belirlendiğinde, 
			             | ProfillerinDeğişikliğiğiYasakla özelliği de Yanlış olarak belirlenmelidir.'; 
			             |es_ES = 'Cuando la propiedad UpdateChangedProfiles 
			             |del parámetro UpdateParameters se establece en False, 
			             |la propiedad DenyProfilesChange 
			             |también se debe establecer en False.'");
	EndIf;
	
	// Description for filling the Administrator predefined profile.
	AdministratorProfileDetails = AccessManagement.NewAccessGroupProfileDescription();
	AdministratorProfileDetails.Name           = "Administrator";
	AdministratorProfileDetails.ID = AdministratorProfileID();
	AdministratorProfileDetails.Description  = NStr("ru = 'Администратор'; en = 'Administrator'; pl = 'Administrator';de = 'Administrator';ro = 'Administrator';tr = 'Yönetici'; es_ES = 'Administrador'");
	AdministratorProfileDetails.Roles.Add("SystemAdministrator");
	AdministratorProfileDetails.Roles.Add("FullRights");
	
	AdministratorProfileDetails.Details =
		NStr("ru = 'Предназначен для:
		           |- настройки параметров работы и обслуживания информационной системы,
		           |- настройки прав доступа других пользователей,
		           |- удаления помеченных объектов,
		           |- в редких случаях для внесения изменений в конфигурацию.
		           |
		           |Рекомендуется не использовать для ""обычной"" работы в информационной системе.'; 
		           |en = 'Used to:
		           |- Set up and maintain information system parameters
		           |- Assign access rights to users
		           |- Delete marked objects
		           |- Make changes to configuration (in rare cases).
		           |
		           |It is not recommended that you use it for regular information system operations.'; 
		           |pl = 'Przeznaczony do:
		           |- ustawiania parametrów pracy i obsługi systemu informacyjnego,
		           |- ustawiania praw dostępu innych użytkowników,
		           |- usuwania zaznaczonych obiektów,
		           |- rzadko do wprowadzania zmian do konfiguracji.
		           |
		           |Zaleca się nie używać go do ""zwykłej"" pracy w systemie informacyjnym. ';
		           |de = 'Bestimmt für:
		           |- Einstellungen der Betriebs- und Wartungsparameter des Informationssystems,
		           |- Einstellungen der Zugriffsrechte anderer Benutzer,
		           |- Löschen der markierten Objekte,
		           |- in seltenen Fällen für Änderungen an der Konfiguration.
		           |
		           |Es wird empfohlen, nicht für ""normale"" Arbeiten im Informationssystem zu verwenden.';
		           |ro = 'Este destinat pentru:
		           |- setarea parametrilor de lucru și deservire a sistemului de informații,
		           |- setarea drepturilor de acces ale altor utilizatori,
		           |- ștergerea obiectelor marcate,
		           |- în cazuri rare, pentru introducerea modificărilor în configurație.
		           |
		           |Recomandăm să nu utilizați pentru lucrul ""normal"" în sistemul de informații.';
		           |tr = 'Aşağıdaki amaç için tasarlanmıştır: 
		           |- bilgi sisteminin iş ve bakım ayarları, 
		           |- diğer kullanıcıların erişim hakları ayarları, 
		           |- etiketli nesneleri silme, 
		           |- nadir durumlarda yapılandırmada değişiklik yapmak. 
		           |
		           |Bilgi sisteminde ""normal"" bir çalışma için kullanılmaması önerilir.'; 
		           |es_ES = 'Está destinado para:
		           |- ajuste de parámetros de trabajo y servicio del sistema de información,
		           |- ajustes de derechos de acceso de otros usuarios,
		           |- eliminación de los objetos marcados,
		           |- en unos casos para realizar modificaciones en la configuración.
		           |
		           |Se recomienda no usar para el trabajo ""regular"" en el sistema de información.'")
		+ Chars.LF;
	
	ProfilesDetails.Add(AdministratorProfileDetails);
	
	If Not Common.DataSeparationEnabled() Then
		ProfilesDetails.Add(
			AccessManagementInternal.OpenExternalReportsAndDataProcessorsProfileDetails());
	EndIf;
	
	AllRoles = UsersInternal.AllRoles().Map;
	
	AccessKindsProperties = AccessManagementInternalCached.AccessKindsProperties();
	
	// Transforming descriptions into mapping between IDs and properties for storage and quick 
	// processing.
	ProfilesProperties = New Map;
	ProfilesDetailsArray = New Array;
	For Each ProfileDetails In ProfilesDetails Do
		// Profile ID.
		If Not ValueIsFilled(ProfileDetails.ID) Then
			Raise ErrorTitle + StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'В описании профиля ""%1"" не заполнено свойство Идентификатор.'; en = 'The ID property is not filled in the ""%1"" profile description.'; pl = 'W opisie profilu ""%1"" nie wypełniona właściwość Identyfikator.';de = 'Die Eigenschaft Identitätsmerkmal wird in der Profilbeschreibung ""%1"" nicht ausgefüllt.';ro = 'În descrierea profilului ""%1"" nu este completată proprietatea Identificator.';tr = '""%1"" profil açıklamasında Tanımlayıcı özelliği doldurulmamıştır.'; es_ES = 'En la descripción del perfil ""%1"" no está rellenada la propiedad Identificador.'"),
				?(ValueIsFilled(ProfileDetails.Name), ProfileDetails.Name, ProfileDetails.Description));
				
		ElsIf Not StringFunctionsClientServer.IsUUID(ProfileDetails.ID) Then
			Raise ErrorTitle + StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'В описании профиля ""%1"" указан некорректный идентификатор: ""%2"".'; en = 'Incorrect ID ""%2"" is specified in the ""%1"" profile description.'; pl = 'W opisie profilu ""%1"" jest wskazany niepoprawny identyfikator: ""%2"".';de = 'In der Beschreibung des Profils ""%1"" gibt es eine falsche Kennung: ""%2"".';ro = 'În descrierea profilului ""%1"" este indicat identificatorul incorect: ""%2"".';tr = '""%1"" profil açıklamasında yanlış tanımlayıcı belirtildi: ""%2"".'; es_ES = 'En la descripción del perfil ""%1"" está indicado un identificador no correcto: ""%2"".'"),
				?(ValueIsFilled(ProfileDetails.Name), ProfileDetails.Name, ProfileDetails.Description),
				ProfileDetails.ID);
		EndIf;
		
		// Profile purpose.
		If ProfileDetails.Purpose.Count() = 0 Then
			ProfileDetails.Purpose.Add(Type("CatalogRef.Users"));
		EndIf;
		AssignmentsArray = New Array;
		For Each Type In ProfileDetails.Purpose Do
			If TypeOf(Type) = Type("TypeDescription") Then
				Types = Type.Types();
			Else
				Types = CommonClientServer.ValueInArray(Type);
			EndIf;
			For Each Type In Types Do
				If TypeOf(Type) <> Type("Type")
				 Or Not Common.IsReference(Type)
				 Or Not Metadata.DefinedTypes.User.Type.ContainsType(Type)
				 Or Type <> Type("CatalogRef.Users")
				   AND Not Metadata.DefinedTypes.ExternalUser.Type.ContainsType(Type) Then
					Raise ErrorTitle + StringFunctionsClientServer.SubstituteParametersToString(
						NStr("ru = 'В описании профиля ""%1""
						           |указано недопустимое назначение ""%2 (%3)"".
						           |Ожидается назначение, как значение типа ""Тип"" для ссылки,
						           |указанное в определяемом типе Пользователь и
						           |указанное в определяемом типе ВнешнийПользователь
						           |(кроме типа СправочникСсылка.Пользователи).'; 
						           |en = 'Invalid purpose ""%2 (%3)""
						           |is specified in the description of profile ""%1.""
						           |The expected purpose is a value of ""Type"" type for the reference,
						           |which is specified in defined type User and 
						           |defined type ExternalUser
						           |(except for CatalogRef.Users type).'; 
						           |pl = 'W opisie profilu ""%1""
						           |wskazano niedozwoloną wartość ""%2 (%3)"".
						           |Jest oczekiwany przydział, jako wartość typu ""Typ"" do linku,
						           |wskazana w określanym typie Użytkownik i
						           |wskazana w określanym typie UżytkownikZewnętrzny
						           |(oprócz typu KatalogLink.Użytkownicy).';
						           |de = 'Die Profilbeschreibung ""%1""
						           |zeigt eine ungültige Zuordnung ""%2 (%3)"" an.
						           |Es wird erwartet, dass die Zuordnung der Wert des Typs ""Typ"" für die Referenz ist,
						           |die im definierten Benutzertyp angegeben und
						           |im definierten Typ ExternerBenutzer
						           |angegeben ist (außer dem ReferenzTyp.Benutzer).';
						           |ro = 'În descrierea profilului ""%1""
						           |este indicată valoarea inadmisibilă ""%2 (%3)"".
						           |Se așteaptă destinația, ca valoarea tipului ""Tip"" pentru referință,
						           |indicată în tipul determinat Пользователь și
						           |indicată în tipul determinat ВнешнийПользователь
						           |(cu excepția tipului СправочникСсылка.Пользователи).';
						           |tr = '""%1""
						           | Profil açıklamasında geçersiz bir atama ""%2""(%3) belirtildi. 
						           |Atama, Kullanıcı tanımlı türde belirtilen ve Harici Kullanıcı tanımlı türde 
						           |(KatalogReferans.Kullanıcılar türü hariç) 
						           |belirtilen bağlantı için 
						           |""Tür "" türünde bir değer olarak bekleniyor.'; 
						           |es_ES = 'El propósito no válido ""%2(%3)"" 
						           |se especifica en la descripción del perfil ""%1."" 
						           |El propósito esperado es un valor de tipo ""Tipo"" para la referencia, 
						           |que se especifica en el tipo definido Usuario y 
						           |tipo definido Usuario Externo 
						           |(excepto para el tipo CatálogoRef.Users) .'"),
						?(ValueIsFilled(ProfileDetails.Name),
						  ProfileDetails.Name,
						  ProfileDetails.ID),
						  String(Type), String(TypeOf(Type)));
				EndIf;
				RefTypeDetails = New TypeDescription(CommonClientServer.ValueInArray(Type));
				Value = RefTypeDetails.AdjustValue(Undefined);
				AssignmentsArray.Add(Value);
			EndDo;
		EndDo;
		ProfileDetails.Purpose = AssignmentsArray;
		
		// Checking roles.
		ProfileAssignment = AccessManagementInternalClientServer.ProfileAssignment(ProfileDetails);
		UnavailableRoles = UsersInternalCached.UnavailableRoles(ProfileAssignment, False);
		
		For Each Role In ProfileDetails.Roles Do
			// Checking whether the metadata contains roles.
			If AllRoles.Get(Role) = Undefined Then
				Raise ErrorTitle + StringFunctionsClientServer.SubstituteParametersToString(
					NStr("ru = 'В описании профиля ""%1 (%2)""
					           |роль ""%3"" не найдена в метаданных.'; 
					           |en = 'Role ""%3"" is not found in metadata
					           |in  description of the ""%1 (%2)"" profile.'; 
					           |pl = 'W opisie profilu ""%1 (%2)""
					           |rola ""%3"" nie została znaleziona w metadanych.';
					           |de = 'In der Profilbeschreibung ""%1 (%2)""
					           | wurde die Rolle ""%3"" nicht in den Metadaten gefunden.';
					           |ro = 'În descrierea profilului ""%1(%2)""
					           | rolul ""%3"" nu s-a găsit în metadate.';
					           |tr = 'Profil açıklamasında 
					           |""%1 (%2)"" rolü ""%3"" meta veride bulunamadı.'; 
					           |es_ES = 'En la descripción del perfil ""%1 (%2)""
					           |el rol ""%3"" no se ha encontrado en metadatos.'"),
					ProfileDetails.Name,
					ProfileDetails.ID,
					Role);
			EndIf;
			// Checking correspondence between the assignment of roles and a profile.
			If UnavailableRoles.Get(Role) <> Undefined Then
				Raise ErrorTitle + StringFunctionsClientServer.SubstituteParametersToString(
					NStr("ru = 'В описании профиля ""%1 (%2)""
					           |указана роль ""%3"", 
					           |которая не соответствует назначению профиля:
					           |""%4"".'; 
					           |en = 'Role ""%3"" that 
					           |does not correspond to the profile assignment:
					           |""%4
					           |is specified in description of profile ""%1 (%2)"".'; 
					           |pl = 'W opisie profilu ""%1 (%2)""
					           |wskazano rolę ""%3"", 
					           |która nie odpowiada przydziałowi profilu:
					           |""%4"".';
					           |de = 'In der Profilbeschreibung ""%1 (%2)""
					           | wird die Rolle ""%3"" angegeben, 
					           |die nicht dem Verwendungszweck des Profils entspricht:
					           |""%4"".';
					           |ro = 'În descrierea profilului ""%1 (%2)""
					           |este indicat rolul ""%3"", 
					           |care nu corespunde destinației profilului:
					           |""%4"".';
					           |tr = 'Profil açıklamasında ""%1(%2)"", 
					           |%4profilin amacına uymayan "
" %3
					           |rol belirtilmiştir.'; 
					           |es_ES = 'En la descripción del perfil ""%1 (%2)""
					           |se ha indicado el rol ""%3""
					           |que no corresponde a la asignación del perfil:
					           |""%4"".'"),
					ProfileDetails.Name,
					ProfileDetails.ID,
					Role,
					ProfileAssignmentPresentation(ProfileAssignment));
			EndIf;
		EndDo;
		If Common.DataSeparationEnabled() Then
			// Filling in the list of unavailable roles in SaaS to determine if the supplied profiles need to be 
			// updated.
			ProfileDetails.Insert("RolesUnavailableInService",
				ProfileRolesUnavailableInService(ProfileDetails, ProfileAssignment));
		EndIf;
		
		If ProfilesProperties.Get(ProfileDetails.ID) <> Undefined Then
			Raise StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'Профиль с идентификатором ""%1"" уже существует.'; en = 'Profile with ID ""%1"" already exists.'; pl = 'Profil z identyfikatorem ""%1"" już istnieje.';de = 'Profil mit ID ""%1"" existiert bereits.';ro = 'Profil cu identificatorul ""%1"" există deja.';tr = '""%1"" kimliğine sahip profil zaten mevcuttur.'; es_ES = 'Perfil con el identificador ""%1"" ya existe.'"),
				ProfileDetails.ID);
		EndIf;
		ProfilesProperties.Insert(ProfileDetails.ID, ProfileDetails);
		ProfilesDetailsArray.Add(ProfileDetails);
		If ValueIsFilled(ProfileDetails.Name) Then
			If ProfilesProperties.Get(ProfileDetails.Name) <> Undefined Then
				Raise ErrorTitle + StringFunctionsClientServer.SubstituteParametersToString(
					NStr("ru = 'Профиль с именем ""%1"" уже существует.'; en = 'Profile with name ""%1"" already exists.'; pl = 'Profil o nazwie ""%1"" już istnieje.';de = 'Das Profil mit dem Namen ""%1"" existiert bereits.';ro = 'Profilul cu numele ""%1"" există deja.';tr = '""%1"" isimli profil zaten mevcuttur.'; es_ES = 'Perfil con el nombre ""%1"" ya existe.'"),
					ProfileDetails.Name);
			EndIf;
			ProfilesProperties.Insert(ProfileDetails.Name, ProfileDetails);
		EndIf;
		// Transformation of ValuesList to Mapping for recording.
		AccessKinds = New Map;
		For Each ListItem In ProfileDetails.AccessKinds Do
			AccessKindName       = ListItem.Value;
			AccessKindClarification = ListItem.Presentation;
			If AccessKindsProperties.ByNames.Get(AccessKindName) = Undefined Then
				Raise ErrorTitle + StringFunctionsClientServer.SubstituteParametersToString(
					NStr("ru = 'В описании профиля ""%1""
					           |указан несуществующий вид доступа ""%2"".'; 
					           |en = 'Non-existing access kind ""%2"" 
					           |is specified in description of profile ""%1"".'; 
					           |pl = 'W opisie profilu ""%1""
					           |wskazano nieistniejący rodzaj dostępu ""%2"".';
					           |de = 'In der Profilbeschreibung ""%1""
					           |gibt es eine nicht vorhandene Zugriffsart ""%2"".';
					           |ro = 'În descrierea profilului ""%1""
					           | este specificat tipul de acces invalid ""%2"".';
					           |tr = 'Profil
					           |açıklamasında ""%1"" geçersiz erişim türü ""%2"" belirlendi.'; 
					           |es_ES = 'En la descripción del perfil ""%1""
					           |se ha indicado un tipo de acceso no existente ""%2"".'"),
					?(ValueIsFilled(ProfileDetails.Name),
					  ProfileDetails.Name,
					  ProfileDetails.ID),
					AccessKindName);
			EndIf;
			
			AccessKindMatchesProfileAssignment =
				AccessManagementInternalClientServer.AccessKindMatchesProfileAssignment(
					AccessKindName, ProfileAssignment);
			
			If Not AccessKindMatchesProfileAssignment Then
				Raise ErrorTitle + StringFunctionsClientServer.SubstituteParametersToString(
					NStr("ru = 'В описании профиля ""%1""
					           |указан вид доступа ""%2""
					           |который не соответствует назначению профиля:
					           |""%3"".'; 
					           |en = 'Access kind ""%2"" that
					           |does not correspond to profile assignment ""%3"" 
					           |is specified in the 
					           |""%1"" profile description.'; 
					           |pl = 'W opisie profilu ""%1""
					           |wskazano rodzaj dostępu ""%2""
					           |który nie odpowiada przydziałowi profilu:
					           |""%3"".';
					           |de = 'In der Beschreibung des Profils ""%1""
					           |wird die Art des Zugriffs ""%2""
					           |angegeben, die nicht dem Zweck des Profils:
					           |""%3"" entspricht.';
					           |ro = 'În descrierea profilului ""%1""
					           | este specificat tipul de acces ""%2""
					           |care nu corespunde destinației profilului:
					           |""%3"".';
					           |tr = '""%1"" 
					           | profil açıklamasında, profilin amacına uygun olmayan ""%2""
					           |erişim hakkı belirtilmiştir: 
					           |""%3"".'; 
					           |es_ES = 'En la descripción del perfil ""%1""
					           |se ha indicado un tipo de acceso ""%2""
					           |que corresponde al destino de perfil:
					           |""%3"".'"),
					?(ValueIsFilled(ProfileDetails.Name),
					  ProfileDetails.Name,
					  ProfileDetails.ID),
					AccessKindName,
					ProfileAssignmentPresentation(ProfileAssignment));
			EndIf;
			If AccessKindClarification <> ""
			   AND AccessKindClarification <> "AllDeniedByDefault"
			   AND AccessKindClarification <> "PresetAccessKind"
			   AND AccessKindClarification <> "AllAllowedByDefault" Then
				
				Raise ErrorTitle + StringFunctionsClientServer.SubstituteParametersToString(
					NStr("ru = 'В описании профиля ""%1""
					           |для вида доступа ""%2"" указано неизвестное уточнение ""%3"".
					           |
					           |Допустимы только следующие уточнения:
					           |- ""ВначалеВсеЗапрещены"" или """",
					           |- ""ВначалеВсеРазрешены"",
					           |- ""Предустановленный"".'; 
					           |en = 'Unknown clarification ""%3"" 
					           |is specified in the description of the ""%1"" profile for access kind ""%2.""
					           |
					           |Only the following clarifications are allowed:
					           |- AllDeniedByDefault
					           |- AllAllowedByDefault
					           |- PresetAccessKind'; 
					           |pl = 'W opisie profilu ""%3"" 
					           |dla rodzaju dostępu ""%1"" określono nieznane uściślenie ""%2"". 
					           |
					           |Tylko następujące należności są prawidłowe:
					           |- AllDeniedByDefault
					           |- AllAllowedByDefault
					           |- PresetAccessKind';
					           |de = 'Unbekannte Klarstellung ""%3"" 
					           |ist in der Beschreibung des ""%1"" Profils für die Zugriffsart ""%2"" angegeben.
					           |
					           |Nur folgende Klarstellungen sind erlaubt:
					           |- AllDeniedByDefault
					           |- AllAllowedByDefault
					           |- PresetAccessKind';
					           |ro = 'Clarificarea necunoscută ""%3"" 
					           |este specificată în descrierea profilului ""%1"" pentru tipul de acces ""%2.""
					           |
					           |Sunt permise următoarele clarificări: 
					           |- AllDeniedByDefault
					           |- AllAllowedByDefault
					           |- PresetAccessKind';
					           |tr = '""%2"" erişim türüne ait profil açıklamasında ""%1""
					           |bilinmeyen arıtıcı ""%3"" belirtilmiştir.
					           |
					           | Sadece aşağıdaki arıtıcılar geçerlidir: 
					           |- ""BaşlangıçtaYasaklananlar"" veya """" 
					           |- "" ""BaşlangıçtaİzinVerilenler"", 
					           |- ""Ön ayar"". '; 
					           |es_ES = 'En la descripción del perfil ""%1""
					           |para el tipo de acceso ""%2"" el refinador desconocido ""%3"" está especificado.
					           |
					           |Solo los siguientes refinadores son válidos:
					           |- ""AllProhibitedInBeginning"" o """",
					           |- ""AllAllowedInBeginning"",
					           |- ""Preestablecido"".'"),
					?(ValueIsFilled(ProfileDetails.Name),
					  ProfileDetails.Name,
					  ProfileDetails.ID),
					AccessKindName,
					AccessKindClarification);
			EndIf;
			AccessKinds.Insert(AccessKindName, AccessKindClarification);
		EndDo;
		ProfileDetails.AccessKinds = AccessKinds;
		
		// Deleting duplicate values.
		AccessValues = New Array;
		AccessValuesTable = New ValueTable;
		AccessValuesTable.Columns.Add("AccessKind",      Metadata.DefinedTypes.AccessValue.Type);
		AccessValuesTable.Columns.Add("AccessValue", Metadata.DefinedTypes.AccessValue.Type);
		
		For Each ListItem In ProfileDetails.AccessValues Do
			Filter = New Structure;
			Filter.Insert("AccessKind",      ListItem.Value);
			Filter.Insert("AccessValue", ListItem.Presentation);
			AccessKind      = Filter.AccessKind;
			AccessValue = Filter.AccessValue;
			
			AccessKindProperties = AccessKindsProperties.ByNames.Get(AccessKind);
			If AccessKindProperties = Undefined Then
				Raise ErrorTitle + StringFunctionsClientServer.SubstituteParametersToString(
					NStr("ru = 'В описании профиля ""%1""
					           |указан несуществующий вид доступа ""%2""
					           |для значения доступа
					           |""%3"".'; 
					           |en = 'Non-existing access kind ""%2"" 
					           | is specified
					           |in description of the ""%1"" profile
					           |for access value ""%3"".'; 
					           |pl = 'W opisie profilu ""%1""
					           |wskazano nieistniejący rodzaj dostępu ""%2""
					           |dla wartości dostępu
					           |""%3"".';
					           |de = 'In der Profilbeschreibung ""%1""
					           |gibt es eine nicht vorhandene Zugriffsart ""%2""
					           |für den Zugriffswert
					           |""%3"".';
					           |ro = 'În descrierea profilului ""%1""
					           | este specificat tipul de acces inexistent ""%2""
					           | pentru valoarea de acces 
					           |""%3"".';
					           |tr = 'Profil açıklamasında ""%1"" 
					           |erişim değeri
					           |""%2"" için ""%3"" 
					           |geçersiz erişim türü belirlendi.'; 
					           |es_ES = 'En la descripción del perfil ""%1""
					           |se ha indicado un tipo de acceso no existente ""%2""
					           | para el valor de acceso
					           |""%3"".'"),
					?(ValueIsFilled(ProfileDetails.Name),
					  ProfileDetails.Name,
					  ProfileDetails.ID),
					AccessKind,
					AccessValue);
			EndIf;
			
			MetadataObject = Undefined;
			PointPosition = StrFind(AccessValue, ".");
			If PointPosition > 0 Then
				MetadataObjectKind = Left(AccessValue, PointPosition - 1);
				RowBalance = Mid(AccessValue, PointPosition + 1);
				PointPosition = StrFind(RowBalance, ".");
				If PointPosition > 0 Then
					MetadataObjectName = Left(RowBalance, PointPosition - 1);
					FullMetadataObjectName = MetadataObjectKind + "." + MetadataObjectName;
					MetadataObject = Metadata.FindByFullName(FullMetadataObjectName);
				EndIf;
			EndIf;
			
			If MetadataObject = Undefined Then
				Raise ErrorTitle + StringFunctionsClientServer.SubstituteParametersToString(
					NStr("ru = 'В описании профиля ""%1""
					           |для вида доступа ""%2""
					           |не существует тип указанного значения доступа
					           |""%3"".'; 
					           |en = 'Specified access type ""%3"" 
					           |for access kind ""%2"" 
					           |does not exist in description of the 
					           |""%1"" profile.'; 
					           |pl = 'W opisie profilu ""%1""
					           |dla rodzaju dostępu ""%2""
					           |nie istnieje typ wskazanej wartości dostępu
					           |""%3"".';
					           |de = 'In der Profilbeschreibung ""%1""
					           |für Zugriffstyp ""%2""
					           |gibt es keine Art des angegebenen Zugriffswertes
					           |""%3"".';
					           |ro = 'În descrierea profilului ""%1""
					           | pentru tipul de acces ""%2""
					           | nu există tipul valorii de acces specificate 
					           |""%3"".';
					           |tr = '""%2"" 
					           |profil açıklamasında ""%1"" 
					           |erişim türüne ait ""%3""
					           | belirtilmiş erişim değeri mevcut değildir.'; 
					           |es_ES = 'En la descripción del perfil ""%1""
					           |para el tipo de acceso ""%2""
					           |no existe tipo del valor indicado de acceso
					           |""%3"".'"),
					?(ValueIsFilled(ProfileDetails.Name),
					  ProfileDetails.Name,
					  ProfileDetails.ID),
					AccessKind,
					AccessValue);
			EndIf;
			
			Try
				AccessValuesBlankRef = Common.ObjectManagerByFullName(
					FullMetadataObjectName).EmptyRef();
			Except
				AccessValuesBlankRef = Undefined;
			EndTry;
			
			If AccessValuesBlankRef = Undefined Then
				Raise ErrorTitle + StringFunctionsClientServer.SubstituteParametersToString(
					NStr("ru = 'В описании профиля ""%1""
					           |для вида доступа ""%2""
					           |указан не ссылочный тип значения доступа
					           |""%3"".'; 
					           |en = 'Non-reference access value type ""%3""
					           | is specified in description of the ""%1"" profile
					           |for access kind
					           |""%2"".'; 
					           |pl = 'W opisie profilu ""%1""
					           |dla rodzaju dostępu ""%2""
					           |nie określono typu odniesienia
					           |""%3"".';
					           |de = 'In der Profilbeschreibung ""%1""
					           |für die Zugriffsart ""%2""
					           |ist keine Referenzart des Zugriffswertes
					           |""%3""angegeben.';
					           |ro = 'În descrierea profilului ""%1""
					           | pentru tipul de acces ""%2""
					           | nu este indicat tipul de referință al valorii de acces 
					           |""%3"".';
					           |tr = '""%2"" 
					           |profil açıklamasında ""%1"" 
					           |erişim türüne ait  ""%3 
					           |referans türü değeri belirlenmedi.'; 
					           |es_ES = 'En la descripción del perfil ""%1""
					           |para el tipo de acceso ""%2""
					           |está indicado un tipo de valor de acceso no enlace
					           |""%3"".'"),
					?(ValueIsFilled(ProfileDetails.Name),
					  ProfileDetails.Name,
					  ProfileDetails.ID),
					AccessKind,
					AccessValue);
			EndIf;
			AccessValueType = TypeOf(AccessValuesBlankRef);
			
			AccessKindPropertiesByType = AccessKindsProperties.ByValuesTypes.Get(AccessValueType);
			If AccessKindPropertiesByType = Undefined
			 OR AccessKindPropertiesByType.Name <> AccessKind Then
				
				Raise ErrorTitle + StringFunctionsClientServer.SubstituteParametersToString(
					NStr("ru = 'В описании профиля ""%1""
					           |указано значение доступа ""%3""
					           |типа, который не указан в свойствах вида доступа ""%2"".'; 
					           |en = 'Access value ""%3""
					           | of the type not specified in properties of access kind ""%2""
					           | is specified in description of profile ""%1"".'; 
					           |pl = 'W opisie profilu ""%1""
					           |określono wartość dostępu ""%3"" typu
					           |, która nie jest określona we właściwościach typu ""%2"" dostępu.';
					           |de = 'Die Profilbeschreibung ""%1""
					           |gibt den Zugriffswert ""%3""
					           |des Typs an, der nicht in den Eigenschaften der Zugriffsart ""%2"" angegeben ist.';
					           |ro = 'În descrierea profilului ""%1""
					           | este specificat tipul de acces ""%3""
					           | de tipul care nu este indicat în proprietățile tipului de acces ""%2"".';
					           |tr = 'Profil açıklamasında ""%1""
					           | erişim türü ""%3"" özelliklerinde belirlenmeyen "
" türünün %2 erişim değeri belirlendi.'; 
					           |es_ES = 'En la descripción del perfil ""%1""
					           |se ha indicado un valor de acceso ""%3""
					           |del tipo que se ha indicado en las propiedades del tipo de acceso ""%2"".'"),
					?(ValueIsFilled(ProfileDetails.Name),
					  ProfileDetails.Name,
					  ProfileDetails.ID),
					AccessKind,
					AccessValue);
			EndIf;
			
			If AccessValuesTable.FindRows(Filter).Count() > 0 Then
				Raise ErrorTitle + StringFunctionsClientServer.SubstituteParametersToString(
					NStr("ru = 'В описании профиля ""%1""
					           |для вида доступа ""%2""
					           |повторно указано значение доступа
					           |""%3"".'; 
					           |en = 'Access value ""%3""
					           | is specified repeatedly in description of profile ""%1""
					           | for access kind 
					           |""%2"".'; 
					           |pl = 'W opisie profilu ""%1""
					           |dla rodzaju
					           |dostępu ""%2"" wartość dostępu
					           |""%3"" jest określona ponownie.';
					           |de = 'In der Profilbeschreibung ""%1""
					           |für Zugriffsart ""%2""
					           |wird der Zugriffswert
					           |""%3"" erneut angegeben.';
					           |ro = 'În descrierea profilului ""%1""
					           | pentru tipul de acces ""%2""
					           | este indicată repetat valoarea de acces 
					           |""%3"".';
					           |tr = '""%1"" profil açıklamasında %3 erişim türü  için "
" 
					           |erişim değeri ""%2"" 
					           |tekrar belirlendi.'; 
					           |es_ES = 'En la descripción del perfil ""%1""
					           |para el tipo de acceso ""%2""
					           |se ha indicado una vez más el valor de acceso 
					           |""%3"".'"),
					?(ValueIsFilled(ProfileDetails.Name),
					  ProfileDetails.Name,
					  ProfileDetails.ID),
					AccessKind,
					AccessValue);
			EndIf;
			AccessValues.Add(Filter);
		EndDo;
		ProfileDetails.AccessValues = AccessValues;
	EndDo;
	
	SuppliedProfiles = New Structure;
	SuppliedProfiles.Insert("UpdateParameters",    UpdateParameters);
	SuppliedProfiles.Insert("ProfilesDetails",       ProfilesProperties);
	SuppliedProfiles.Insert("ProfilesDetailsArray", ProfilesDetailsArray);
	
	Return Common.FixedData(SuppliedProfiles);
	
EndFunction

// For the SuppliedProfiles procedure.
Function ProfileAssignmentPresentation(ProfileAssignment)
	
	If ProfileAssignment = "BothForUsersAndExternalUsers" Then
		Return NStr("ru = 'Совместно для пользователей и внешних пользователей'; en = 'Shared by users and external users'; pl = 'Wspólnie dla użytkowników i użytkowników zewnętrznych';de = 'Gemeinsam für Benutzer und externe Benutzer';ro = 'Pentru utilizatori și utilizatorii externi';tr = 'Kullanıcılar ve harici kullanıcılar için ortak'; es_ES = 'Para usuarios y usuarios externos'");
		
	ElsIf ProfileAssignment = "ForExternalUsers" Then
		Return NStr("ru = 'Для внешних пользователей'; en = 'For external users'; pl = 'Dla użytkowników zewnętrznych';de = 'Für externe Benutzer';ro = 'Pentru utilizatori externi';tr = 'Harici kullanıcılar için'; es_ES = 'Para los usuarios externos'");
	EndIf;
	
	Return NStr("ru = 'Для пользователей'; en = 'For users'; pl = 'Dla użytkowników';de = 'Für Benutzer';ro = 'Pentru utilizatori';tr = 'Kullanıcılar için'; es_ES = 'Para usuarios'");
	
EndFunction

Function PredefinedProfilesMatch(NewProfiles, OldProfiles, HasDeletedItems)
	
	If TypeOf(NewProfiles) <> TypeOf(OldProfiles) Then
		HasDeletedItems = True;
		Return False;
	EndIf;
	
	PredefinedProfilesMatch =
		NewProfiles.Count() = OldProfiles.Count();
	
	For Each Profile In OldProfiles Do
		If NewProfiles.Find(Profile) = Undefined Then
			PredefinedProfilesMatch = False;
			HasDeletedItems = True;
			Break;
		EndIf;
	EndDo;
	
	Return PredefinedProfilesMatch;
	
EndFunction

// Replaces an existing supplied access group profile by its description or creates a new one.
//
// Parameters:
//  ProfileProperties - FixedStructure - profile properties matching the structure returned by the 
//                    NewAccessGroupsProfileDetails function of the AccessManagement common module.
// 
// Returns:
//  Boolean. True - a profile is changed.
//
Function UpdateAccessGroupsProfile(ProfileProperties, DoNotUpdateUsersRoles = False)
	
	ProfileChanged = False;
	
	ProfileReference = SuppliedProfileByID(ProfileProperties.ID);
	If ProfileReference = Undefined Then
		
		If ValueIsFilled(ProfileProperties.Name) Then
			Query = New Query;
			Query.Text =
			"SELECT
			|	AccessGroupProfiles.Ref AS Ref,
			|	AccessGroupProfiles.PredefinedDataName AS PredefinedDataName
			|FROM
			|	Catalog.AccessGroupProfiles AS AccessGroupProfiles
			|WHERE
			|	AccessGroupProfiles.Predefined = TRUE";
			Selection = Query.Execute().Select();
			
			While Selection.Next() Do
				PredefinedItemName = Selection.PredefinedDataName;
				If Upper(ProfileProperties.Name) = Upper(PredefinedItemName) Then
					ProfileReference = Selection.Ref;
					Break;
				EndIf;
			EndDo;
		EndIf;
		
		If ProfileReference = Undefined Then
			// The supplied profile is not found and must be created.
			ProfileObject = CreateItem();
		Else
			// The supplied profile is associated with a predefined item.
			ProfileObject = ProfileReference.GetObject();
		EndIf;
		
		ProfileObject.SuppliedDataID =
			New UUID(ProfileProperties.ID);
		
		ProfileChanged = True;
	Else
		ProfileObject = ProfileReference.GetObject();
		ProfileChanged = SuppliedProfileChanged(ProfileObject);
	EndIf;
	
	If ProfileChanged Then
		
		If Not InfobaseUpdate.InfobaseUpdateInProgress()
		   AND Not InfobaseUpdate.IsCallFromUpdateHandler() Then
			
			LockDataForEdit(ProfileObject.Ref, ProfileObject.DataVersion);
		EndIf;
		
		ProfileObject.Description = ProfileProperties.Description;
		
		ProfileObject.Roles.Clear();
		For each Role In ProfileRolesDetails(ProfileProperties) Do
			RoleMetadata = Metadata.Roles.Find(Role);
			If RoleMetadata = Undefined Then
				Raise StringFunctionsClientServer.SubstituteParametersToString(
					NStr("ru = 'При обновлении поставляемого профиля ""%1""
					           |роль ""%2"" не найдена в метаданных.'; 
					           |en = 'The ""%2"" role was not found 
					           |in the metadata while updating supplied profile ""%1"".'; 
					           |pl = 'Podczas aktualizacji dostarczanego profilu ""%1""
					           | rola ""%2"" nie została znaleziona w metadanych.';
					           |de = 'Bei der Aktualisierung des ausgelieferten Profils ""%1""
					           |wird die Rolle ""%2"" in den Metadaten nicht gefunden.';
					           |ro = 'În timpul actualizării profilului furnizat ""%1""
					           | rolul ""%2"" nu este găsit în metadate.';
					           |tr = 'Sağlanan profil güncellenmesinde meta veride 
					           |%1rol ""%2"" bulunamadı.'; 
					           |es_ES = 'Al actualizar el perfil suministrado ""%1""
					           | el rol ""%2"" no se ha encontrado en metadatos.'"),
					ProfileProperties.Description,
					Role);
			EndIf;
			ProfileObject.Roles.Add().Role =
				Common.MetadataObjectID(RoleMetadata);
		EndDo;
		
		ProfileObject.AccessKinds.Clear();
		For each AccessKindDetails In ProfileProperties.AccessKinds Do
			AccessKindProperties = AccessManagementInternal.AccessKindProperties(AccessKindDetails.Key);
			Row = ProfileObject.AccessKinds.Add();
			Row.AccessKind        = AccessKindProperties.Ref;
			Row.PresetAccessKind = AccessKindDetails.Value = "PresetAccessKind";
			Row.AllAllowed      = AccessKindDetails.Value = "AllAllowedByDefault";
		EndDo;
		
		ProfileObject.AccessValues.Clear();
		For each AccessValueDetails In ProfileProperties.AccessValues Do
			AccessKindProperties = AccessManagementInternal.AccessKindProperties(AccessValueDetails.AccessKind);
			ValueRow = ProfileObject.AccessValues.Add();
			ValueRow.AccessKind = AccessKindProperties.Ref;
			Query = New Query(StrReplace("SELECT Value(%1) AS Value", "%1", AccessValueDetails.AccessValue));
			ValueRow.AccessValue = Query.Execute().Unload()[0].Value;
		EndDo;
		
		ProfileObject.Purpose.Clear();
		For each AssignmentType In ProfileProperties.Purpose Do
			AssignmentRow = ProfileObject.Purpose.Add();
			AssignmentRow.UsersType = AssignmentType;
		EndDo;
		
		If DoNotUpdateUsersRoles Then
			ProfileObject.AdditionalProperties.Insert("DoNotUpdateUsersRoles");
		EndIf;
		
		InfobaseUpdate.WriteObject(ProfileObject);
		
		If Not InfobaseUpdate.InfobaseUpdateInProgress()
		   AND Not InfobaseUpdate.IsCallFromUpdateHandler() Then
			
			UnlockDataForEdit(ProfileObject.Ref);
		EndIf;
		
	EndIf;
	
	Return ProfileChanged;
	
EndFunction

Function ProfileRolesDetails(ProfileDetails)
	
	If Not Common.DataSeparationEnabled() Then
		Return ProfileDetails.Roles;
	EndIf;
	
	ProfileAssignment = AccessManagementInternalClientServer.ProfileAssignment(ProfileDetails);
	UnavailableRoles = UsersInternalCached.UnavailableRoles(ProfileAssignment);
	
	ProfileRolesDetails = New Array;
	
	For Each Role In ProfileDetails.Roles Do
		If UnavailableRoles.Get(Role) = Undefined Then
			ProfileRolesDetails.Add(Role);
		EndIf;
	EndDo;
	
	Return New FixedArray(ProfileRolesDetails);
	
EndFunction

Function ProfileRolesUnavailableInService(ProfileDetails, ProfileAssignment)
	
	UnavailableRoles = UsersInternalCached.UnavailableRoles(ProfileAssignment, True);
	UnavailableProfileRoles = New Map;
	
	For Each Role In ProfileDetails.Roles Do
		If UnavailableRoles.Get(Role) <> Undefined Then
			UnavailableProfileRoles.Insert(Role, True);
		EndIf;
	EndDo;
	
	Return New FixedMap(UnavailableProfileRoles);
	
EndFunction

#EndRegion

#EndIf
