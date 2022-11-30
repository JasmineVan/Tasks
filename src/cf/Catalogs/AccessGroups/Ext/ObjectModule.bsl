///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Variables

Var PreviousValues; // Values of some attributes and tabular sections of the access group before it is changed for use 
                      // in the OnWrite event handler.

#EndRegion

#Region EventHandlers

Procedure BeforeWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	If IsFolder Then
		Return;
	EndIf;
	
	StandardSubsystemsServer.CheckApplicationVersionDynamicUpdate();
	InformationRegisters.RolesRights.CheckRegisterData();
	
	PreviousValues = Common.ObjectAttributesValues(Ref,
		"Ref, Profile, DeletionMark, Users, AccessKinds, AccessValues");
	
	// Deleting blank members of the access group.
	Index = Users.Count() - 1;
	While Index >= 0 Do
		If Not ValueIsFilled(Users[Index].User) Then
			Users.Delete(Index);
		EndIf;
		Index = Index - 1;
	EndDo;
	
	If Ref = Catalogs.AccessGroups.Administrators Then
		
		// Administrator predefined profile is always used.
		Profile = Catalogs.AccessGroupProfiles.Administrator;
		
		// Cannot be a personal access group.
		User = Undefined;
		
		// Regular employees cannot be responsible for the group (only full access users can).
		EmployeeResponsible = Undefined;
		
		// Only full access users are allowed to make changes.
		If NOT PrivilegedMode()
		   AND NOT AccessManagement.HasRole("FullRights") Then
			
			Raise
				NStr("ru = 'Предопределенную группу доступа Администраторы
				           |можно изменять, либо в привилегированном режиме,
				           |либо при наличии роли ""Полные права"".'; 
				           |en = 'The predefined access group Administrators
				           |can be changed only if you have the ""Full access"" role
				           |or in the privileged mode.'; 
				           |pl = 'Nie można zapisać grupy Administratorzy,
				           |ponieważ nie masz wystarczających uprawnień, aby ją edytować.
				           | Skontaktuj się z administratorem, aby uzyskać szczegółowe informacje.';
				           |de = 'Die vordefinierte Zugriffsgruppe Administratoren
				           |kann entweder im privilegierten Modus 
				           |oder mit der Rolle ""Volle Zugriffsrechte"" geändert werden.';
				           |ro = 'Grupul de acces predefinit Administratori
				           |poate fi modificat în regim privilegiat
				           |sau în prezența rolului ""Drepturi depline"".';
				           |tr = 'Önceden belirlenmiş Yönetici grubu, 
				           |ya ayrıcalıklı modda 
				           |ya da ""Tüm haklar"" rolü bulunduğunda değiştirilebilir.  '; 
				           |es_ES = 'El grupo de acceso predeterminado Administradores
				           |se puede cambiar en el modo privilegiado
				           |o si hay rol ""Derechos completos"".'");
		EndIf;
		
		// Checking whether the access group contains regular users only.
		For each CurrentRow In Users Do
			If TypeOf(CurrentRow.User) <> Type("CatalogRef.Users") Then
				Raise
					NStr("ru = 'Предопределенная группа доступа Администраторы
					           |может содержать только пользователей.
					           |
					           |Группы пользователей, внешние пользователи и
					           |группы внешних пользователей недопустимы.'; 
					           |en = 'Predefined access group Administrators
					           |can contain only users.
					           |
					           |User groups, external users, and
					           |external user groups are not allowed.'; 
					           |pl = 'Nie można zapisać grupy Administratorzy, ponieważ zawiera ona 
					           | jedną lub kilka pozycji następujących typów: grupę użytkowników, użytkownika zewnętrznego
					           |lub zewnętrzną grupę użytkowników.
					           |
					           |Usuń te elementy i spróbuj ponownie.';
					           |de = 'Die Gruppe Administratoren kann nicht gespeichert werden, da sie 
					           |ein oder mehrere Elemente der folgenden Typen enthält: Benutzergruppe, externer Benutzer oder 
					           |externe Benutzergruppe. 
					           |
					           |Entfernen Sie diese Elemente und versuchen Sie es erneut.';
					           |ro = 'Grupul de acces predefinit Administratori
					           |poate conține numai utilizatori.
					           |
					           |Grupurile de utilizatori, utilizatorii externi și
					           |grupurile de utilizatori externi sunt inadmisibile.';
					           |tr = 'Yöneticiler  grubu, aşağıdaki türlerden 
					           |bir veya birkaç öğe içerdiği için  kaydedilemez: kullanıcı grubu, harici kullanıcı veya 
					           |harici kullanıcı  grubu.
					           |
					           | Bu öğeleri kaldırın ve tekrar deneyin.'; 
					           |es_ES = 'No se puede guardar el grupo de Administradores porque el grupo contiene
					           |uno o varios artículos de los siguientes tipos: grupo de usuarios, usuario externo,
					           |o el grupo de usuarios externos.
					           |
					           |Eliminar estos artículos y probar de nuevo.'");
			EndIf;
		EndDo;
		
	// Administrator predefined profile cannot be set to an arbitrary access group.
	ElsIf Profile = Catalogs.AccessGroupProfiles.Administrator Then
		Raise
			NStr("ru = 'Предопределенный профиль Администратор может быть только
			           |у предопределенной группы доступа Администраторы.'; 
			           |en = 'Only predefined access group ""Administrators""
			           |can have predefined profile ""Administrator.""'; 
			           |pl = 'Predefiniowany profil Administrator może należeć tylko
			           |do predefiniowanej grupy dostępu Administratorzy.';
			           |de = 'Ein vordefiniertes Administrator-Profil kann nur
			           |von einer vordefinierten Administratoren-Zugriffsgruppe angelegt werden.';
			           |ro = 'Profilul predefinit Administrator poate fi numai
			           |la grupul de acces predefinit Administratori.';
			           |tr = 'Önceden tanımlanmış Yönetici profili 
			           |yalnızca önceden tanımlanmış Yöneticiler erişim grubunda olabilir. '; 
			           |es_ES = 'El perfil predeterminado Administrador lo puede tener solo
			           |el grupo de acceso predeterminado Administradores.'");
	EndIf;
	
	If Not IsFolder Then
		
		// Automatically setting attributes for the personal access group.
		If ValueIsFilled(User) Then
			Parent = Catalogs.AccessGroups.PersonalAccessGroupsParent();
		Else
			User = Undefined;
			If Parent = Catalogs.AccessGroups.PersonalAccessGroupsParent(True) Then
				Parent = Undefined;
			EndIf;
		EndIf;
		
		// Upon clearing a deletion mark from an access group, the deletion mark is also cleared from its 
		// profile.
		If Not DeletionMark AND PreviousValues.DeletionMark = True Then
			ProfileDeletionMark = Common.ObjectAttributeValue(Profile, "DeletionMark");
			ProfileDeletionMark = ?(ProfileDeletionMark = Undefined, False, ProfileDeletionMark);
			If ProfileDeletionMark Then
				LockDataForEdit(Profile);
				ProfileObject = Profile.GetObject();
				ProfileObject.DeletionMark = False;
				ProfileObject.Write();
			EndIf;
		EndIf;
	EndIf;
	
EndProcedure

// Updates:
// - roles of added, remaining, and deleted users
// - InformationRegister.AccessGroupsTables
// - InformationRegister.AccessGroupsValues
//
Procedure OnWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	If IsFolder Then
		Return;
	EndIf;
	
	If Not AdditionalProperties.Property("DoNotUpdateUsersRoles") Then
		UpdateUsersRolesOnChangeAccessGroup();
	EndIf;
	
	HasMembers = Users.Count() <> 0;
	HasOldMembers = PreviousValues.Ref = Ref AND Not PreviousValues.Users.IsEmpty();
	
	If Profile           <> PreviousValues.Profile
	 Or DeletionMark   <> PreviousValues.DeletionMark
	 Or HasMembers <> HasOldMembers Then
		
		InformationRegisters.AccessGroupsTables.UpdateRegisterData(Ref);
	EndIf;
	
	If Catalogs.AccessGroups.AccessKindsOrAccessValuesChanged(PreviousValues, ThisObject)
	 Or DeletionMark   <> PreviousValues.DeletionMark
	 Or HasMembers <> HasOldMembers Then
		
		InformationRegisters.AccessGroupsValues.UpdateRegisterData(Ref);
	EndIf;
	
	Catalogs.AccessGroupProfiles.UpdateAuxiliaryProfilesDataChangedOnImport();
	Catalogs.AccessGroups.UpdateAccessGroupsAuxiliaryDataChangedOnImport();
	Catalogs.AccessGroups.UpdateAuxiliaryDataOfUserGroupsChangedOnImport();
	Catalogs.AccessGroups.UpdateUsersRolesChangedOnImport();
	
	If AccessManagementInternal.LimitAccessAtRecordLevelUniversally() Then
		ChangedMembersTypes = ChangedMembersTypes(Users, PreviousValues.Users);
		AccessManagementInternal.ScheduleAccessGroupsSetsUpdate(
			"AccessGroupsOnChangingMembers",
			ChangedMembersTypes.Users,
			ChangedMembersTypes.ExternalUsers);
		
		If Not DeletionMark Then
			AccessManagementInternal.ScheduleAccessUpdateOnChangeAccessGroupMembers(Ref,
				ChangedMembersTypes);
		EndIf;
		If DeletionMark <> PreviousValues.DeletionMark Then
			AccessManagementInternal.UpdateAccessGroupsOfAllowedAccessKey(Ref);
		EndIf;
	EndIf;
	
EndProcedure

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	If AdditionalProperties.Property("VerifiedObjectAttributes") Then
		Common.DeleteNotCheckedAttributesFromArray(
			CheckedAttributes, AdditionalProperties.VerifiedObjectAttributes);
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

Function ChangedMembersTypes(NewMembers, OldMembers)
	
	ChangedMembersTypes = New Structure;
	ChangedMembersTypes.Insert("Users", False);
	ChangedMembersTypes.Insert("ExternalUsers", False);
	
	AllMembers = NewMembers.Unload(, "User");
	AllMembers.Columns.Add("RowChangeKind", New TypeDescription("Number"));
	AllMembers.FillValues(1, "RowChangeKind");
	If OldMembers <> Undefined Then
		Selection = OldMembers.Select();
		While Selection.Next() Do
			NewRow = AllMembers.Add();
			NewRow.User = Selection.User;
			NewRow.RowChangeKind = -1;
		EndDo;
	EndIf;
	AllMembers.GroupBy("User", "RowChangeKind");
	For Each Row In AllMembers Do
		If Row.RowChangeKind = 0 Then
			Continue;
		EndIf;
		If TypeOf(Row.User) = Type("CatalogRef.Users")
		 Or TypeOf(Row.User) = Type("CatalogRef.UserGroups") Then
			ChangedMembersTypes.Users = True;
		EndIf;
		If TypeOf(Row.User) = Type("CatalogRef.ExternalUsers")
		 Or TypeOf(Row.User) = Type("CatalogRef.ExternalUsersGroups") Then
			ChangedMembersTypes.ExternalUsers = True;
		EndIf;
	EndDo;
	
	Return ChangedMembersTypes;
	
EndFunction

Procedure UpdateUsersRolesOnChangeAccessGroup()
	
	If Common.SubsystemExists("StandardSubsystems.SaaS") Then
		ModuleSaaS = Common.CommonModule("SaaS");
		SessionWithoutSeparators = ModuleSaaS.SessionWithoutSeparators();
	Else
		SessionWithoutSeparators = True;
	EndIf;
	
	If Common.DataSeparationEnabled()
		AND Ref = Catalogs.AccessGroups.Administrators
		AND Not SessionWithoutSeparators
		AND AdditionalProperties.Property("ServiceUserPassword") Then
		
		ServiceUserPassword = AdditionalProperties.ServiceUserPassword;
	Else
		ServiceUserPassword = Undefined;
	EndIf;
	
	SetPrivilegedMode(True);
	
	UsersForUpdate =
		Catalogs.AccessGroups.UsersForRolesUpdate(PreviousValues, ThisObject);
	
	If Ref = Catalogs.AccessGroups.Administrators Then
		// Adding users associated with infobase users with the FullAccess role.
		
		For Each InfobaseUser In InfoBaseUsers.GetUsers() Do
			If InfobaseUser.Roles.Contains(Metadata.Roles.FullRights) Then
				
				FoundUser = Catalogs.Users.FindByAttribute(
					"IBUserID", InfobaseUser.UUID);
				
				If NOT ValueIsFilled(FoundUser) Then
					FoundUser = Catalogs.ExternalUsers.FindByAttribute(
						"IBUserID", InfobaseUser.UUID);
				EndIf;
				
				If ValueIsFilled(FoundUser)
				   AND UsersForUpdate.Find(FoundUser) = Undefined Then
					
					UsersForUpdate.Add(FoundUser);
				EndIf;
				
			EndIf;
		EndDo;
	EndIf;
	
	AccessManagement.UpdateUserRoles(UsersForUpdate, ServiceUserPassword);
	
EndProcedure

#EndRegion

#Else
Raise NStr("ru = 'Недопустимый вызов объекта на клиенте.'; en = 'Invalid object call on the client.'; pl = 'Niedozwolone wezwanie obiektu na kliencie.';de = 'Unzulässiger Objektaufruf auf dem Client.';ro = 'Apel inadmisibil al obiectului pe client.';tr = 'İstemcide kabul edilmeyen nesne çağrısı.'; es_ES = 'Llamada no disponible del objeto en el cliente.'");
#EndIf