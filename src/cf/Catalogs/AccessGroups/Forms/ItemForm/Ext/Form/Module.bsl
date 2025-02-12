﻿///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region EventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	// Preparing auxiliary data.
	AccessManagementInternal.OnCreateAtServerAllowedValuesEditForm(ThisObject);
	
	InitialSettingsOnReadAndCreate(Object);
	
	CatalogExternalUsersAvailable = AccessRight(
		"View", Metadata.Catalogs.ExternalUsers);
	
	UserTypesList.Add(Type("CatalogRef.Users"));
	UserTypesList.Add(Type("CatalogRef.ExternalUsers"));
	
	// Making the properties always visible.
	
	// Determining if the access restrictions must be set.
	If NOT AccessManagement.LimitAccessAtRecordLevel() Then
		Items.Access.Visible = False;
	EndIf;
	
	// Setting availability for viewing the form in read-only mode.
	Items.UsersPick.Enabled                = NOT ReadOnly;
	Items.UsersPickContextMenu.Enabled = NOT ReadOnly;
	
	If Common.DataSeparationEnabled()
	   AND Object.Ref = Catalogs.AccessGroups.Administrators
	   AND Common.SubsystemExists("StandardSubsystems.SaaS.UsersSaaS") Then
		
		ModuleUsersInternalSaaS = Common.CommonModule("UsersInternalSaaS");
		ActionsWithSaaSUser = ModuleUsersInternalSaaS.GetActionsWithSaaSUser();
		
		If NOT ActionsWithSaaSUser.ChangeAdministrativeAccess Then
			Raise
				NStr("ru = 'Не достаточно прав доступа для изменения состава администраторов.'; en = 'You are not authorized to change the administrators.'; pl = 'Niewystarczające uprawnienia dostępu do edytowania administratorów.';de = 'Unzureichende Zugriffsrechte zum Bearbeiten von Administratoren.';ro = 'Drepturi de acces insuficiente pentru modificarea componenței administratorilor.';tr = 'Yöneticileri düzenlemek için yetersiz erişim hakları.'; es_ES = 'Insuficientes derechos de acceso para editar los administradores.'");
		EndIf;
	EndIf;
	
	UpdateAssignment();
	
	ProcedureExecutedOnCreateAtServer = True;
	
	If ClientApplication.CurrentInterfaceVariant() = ClientApplicationInterfaceVariant.Version8_2 Then
		Items.UsersAdd.OnlyInAllActions = False;
	EndIf;
	
	If Common.IsStandaloneWorkplace() Then
		If Not Object.Ref = Catalogs.AccessGroups.Administrators
		   AND Not AccessManagementInternal.IsProfileOpenExternalReportsAndDataProcessors(Object.Profile) Then
		
			ReadOnly = True;
		Else
			ProhibitAllChangesExceptMembers();
		EndIf;
	EndIf;
	
	Items.FormWriteAndClose.Enabled = Not ReadOnly
		AND AccessRight("Edit", Metadata.Catalogs.AccessGroups);
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	If AnswerToQuestionOnOpenForm = "SetReadOnly" Then
		AnswerToQuestionOnOpenForm = "";
		ReadOnly = True;
		Items.FormWriteAndClose.Enabled = False;
	EndIf;
	
	If AnswerToQuestionOnOpenForm = "SetAdministratorProfile" Then
		AnswerToQuestionOnOpenForm = Undefined;
		Object.Profile = PredefinedValue("Catalog.AccessGroupProfiles.Administrator");
		Modified = True;
		
	ElsIf Not ReadOnly
	        AND Object.Ref = PredefinedValue("Catalog.AccessGroups.Administrators")
	        AND Object.Profile <> PredefinedValue("Catalog.AccessGroupProfiles.Administrator") Then
		
		Cancel = True;
		ShowQueryBox(
			New NotifyDescription("OnOpenAfterAdministratorProfileInstallationConfirmation", ThisObject),
			NStr("ru = 'У группы доступа Администраторы должен быть профиль Администратор.
			           |
			           |Установить профиль в группе доступа (нет - открыть только для просмотра)?'; 
			           |en = 'The Administrators access group must have the Administrator profile.
			           |
			           |Set the profile in the access group (no - open read-only)?'; 
			           |pl = 'Grupa dostępu Administratorzy nie ma profilu Administratora. Czy chcesz ustawić profil Administratorzy dla tej grupy?
			           |
			           |Jeśli klikniesz przycisk Nie, grupa zostanie otwarta w trybie tylko do odczytu.';
			           |de = 'Die Administratoren-Zugriffsgruppe verfügt nicht über das Administratorprofil. 
			           |
			           |Möchten Sie das Administratorprofil für diese Gruppe festlegen? Wenn Sie auf Nein klicken, wird die Gruppe schreibgeschützt geöffnet.';
			           |ro = 'Grupul de acces Administratori nu are profilul Administrator. 
			           |
			           |Doriți să setați profilul Administratori pentru acest grup de acces (nu - deschide grupul numai pentru vizualizare)?';
			           |tr = 'Yöneticiler erişim grubunun yönetici profili yok.
			           |
			           |Bu grup için Yöneticiler profilini ayarlamak istiyor musunuz? Hayır''a tıklarsanız, grup salt okunur modda açılır.'; 
			           |es_ES = 'El grupo de acceso de Administradores no tiene el perfil del Administrador.
			           |
			           |¿Quiere establecer el perfil del Administrador para este grupo? Si hace clic en No, el grupo se abrirá en el modo de solo lectura.'"),
			QuestionDialogMode.YesNo,
			,
			DialogReturnCode.No);
	Else
		If AnswerToQuestionOnOpenForm = "RefreshAccessKindsContent" Then
			AnswerToQuestionOnOpenForm = "";
			RefreshAccessKindsContent();
			AccessKindsOnReadChanged = False;
			
		ElsIf NOT ReadOnly AND AccessKindsOnReadChanged Then
			
			Cancel = True;
			ShowQueryBox(
				New NotifyDescription("OnOpenAfterAccessKindUpdateConfirmation", ThisObject),
				NStr("ru = 'Изменился состав видов доступа профиля этой группы доступа.
				           |
				           |Обновить виды доступа в группе доступа (нет - открыть только для просмотра)?'; 
				           |en = 'Access kinds of this access group profile changed.
				           |
				           |Update access kinds in the access group (if no, open read-only)?'; 
				           |pl = 'Ograniczenia dostępu profilu grupy dostępu zostały zmienione. Czy chcesz zaktualizować ograniczenia dostępu w grupie dostępu?
				           |
				           |Jeśli naciśniesz przycisk Nie, grupa zostanie otwarta w trybie tylko do odczytu.';
				           |de = 'Die Zugriffsbeschränkungen des Zugriffsgruppenprofils wurden geändert. 
				           |
				           |Möchten Sie die Zugriffsbeschränkungen in der Zugriffsgruppe aktualisieren? Wenn Sie auf Nein klicken, wird die Gruppe schreibgeschützt geöffnet.';
				           |ro = 'A fost modificată componența tipurilor de acces ale profilului grupului de acces.
				           |
				           |Doriți să actualizați restricțiile de acces din grupul de acces (nu - deschide grupul numai pentru vizualizare)?';
				           |tr = 'Erişim grubu profilinin erişim kısıtlamaları değiştirildi.
				           |
				           |Erişim grubundaki erişim kısıtlamalarını güncellemek ister misiniz? Hayır''a tıklarsanız, grup salt okunur modda açılır.'; 
				           |es_ES = 'Las restricciones de acceso del perfil del grupo de acceso se han cambiado.
				           |
				           |¿Quiere actualizar las restricciones de acceso en el grupo de acceso? Si hace clic en No, el grupo se abrirá en el modo de solo lectura.'"),
				QuestionDialogMode.YesNo,
				,
				DialogReturnCode.No);
		
		ElsIf NOT ReadOnly
			   AND NOT ValueIsFilled(Object.Ref)
			   AND TypeOf(FormOwner) = Type("FormTable")
			   AND FormOwner.Parent.Parameters.Property("Profile") Then
			
			If ValueIsFilled(FormOwner.Parent.Parameters.Profile) Then
				Object.Profile = FormOwner.Parent.Parameters.Profile;
				AttachIdleHandler("IdleHandlerProfileOnChange", 0.1, True);
			EndIf;
		EndIf;
	EndIf;
	
EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)
	
	If NOT ProcedureExecutedOnCreateAtServer Then
		Return;
	EndIf;
	
	AccessManagementInternal.OnRereadAtServerAllowedValuesEditForm(ThisObject, CurrentObject);
	
	InitialSettingsOnReadAndCreate(CurrentObject);
	
	// StandardSubsystems.AccessManagement
	If Common.SubsystemExists("StandardSubsystems.AccessManagement") Then
		ModuleAccessManagement = Common.CommonModule("AccessManagement");
		ModuleAccessManagement.OnReadAtServer(ThisObject, CurrentObject);
	EndIf;
	// End StandardSubsystems.AccessManagement

EndProcedure

&AtClient
Procedure BeforeWrite(Cancel, WriteParameters)
	
	If StandardSubsystemsClient.ClientRunParameters().DataSeparationEnabled
	   AND Object.Ref = PredefinedValue("Catalog.AccessGroups.Administrators")
	   AND ServiceUserPassword = Undefined Then
		
		Cancel = True;
		UsersInternalClient.RequestPasswordForAuthenticationInService(
			New NotifyDescription("BeforeWriteFollowUp", ThisObject, WriteParameters),
			ThisObject,
			ServiceUserPassword);
		Return;
	EndIf;
	
EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	If NOT Users.IsFullUser() Then
		// The employee responsible for the access group cannot change anything except the list of members.
		// To prevent any unauthorized access group changes on the client, object is re-read.
		// 
		RestoreObjectWithoutGroupMembers(CurrentObject);
	EndIf;
	
	CurrentObject.Users.Clear();
	
	If CurrentObject.Ref <> Catalogs.AccessGroups.Administrators
	   AND ValueIsFilled(CurrentObject.User) Then
		
		If PersonalAccessUsage Then
			CurrentObject.Users.Add().User = CurrentObject.User;
		EndIf;
	Else
		For each Item In GroupUsers.GetItems() Do
			CurrentObject.Users.Add().User = Item.User;
		EndDo;
	EndIf;
	
	If CurrentObject.Ref = Catalogs.AccessGroups.Administrators Then
		Object.Parent      = Undefined;
		Object.EmployeeResponsible = Undefined;
	EndIf;
	
	If Common.DataSeparationEnabled()
		AND Object.Ref = Catalogs.AccessGroups.Administrators Then
		
		CurrentObject.AdditionalProperties.Insert(
			"ServiceUserPassword", ServiceUserPassword);
	EndIf;
	
EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)
	
	SetPrivilegedMode(True);
	
	ProfileMarkedForDeletion = Common.ObjectAttributeValue(Object.Profile, "DeletionMark");
	ProfileMarkedForDeletion = ?(ProfileMarkedForDeletion = Undefined, False, ProfileMarkedForDeletion);
	
	SetPrivilegedMode(False);
	
	If NOT Object.DeletionMark AND ProfileMarkedForDeletion Then
		WriteParameters.Insert("WarnThatProfileIsMarkedForDeletion");
	EndIf;
	
	AccessManagementInternal.AfterWriteAtServerAllowedValuesEditForm(
		ThisObject, CurrentObject, WriteParameters);
		
	UpdateCommentPicture(Items.CommentPage, Object.Comment);
	
	AccessManagement.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	
EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)
	
	Notify("Write_AccessGroups", New Structure, Object.Ref);
	
	If WriteParameters.Property("WarnThatProfileIsMarkedForDeletion") Then
		
		ShowMessageBox(
			New NotifyDescription("AfterWriteCompletion", ThisObject, WriteParameters),
			NStr("ru = 'Группа доступа не влияет на права участников
			           |так как ее профиль помечен на удаление.'; 
			           |en = 'Access group does not influence its member rights
			           |as its profile is marked for deletion.'; 
			           |pl = 'Grupa dostępu nie wpływa na uprawnienia członków
			           |ponieważ jej profil jest zaznaczony do usunięcia.';
			           |de = 'Eine Zugriffsgruppe hat keinen Einfluss auf die Rechte ihrer Mitglieder,
			           |da ihr Profil zum Löschen markiert ist.';
			           |ro = 'Grupul de acces nu are influență asupra drepturilor membrilor săi
			           |,deoarece profilul lui este marcat pentru ștergere.';
			           |tr = 'Erişim grubu, silinmek üzere işaretlendiği için 
			           |üyelerinin herhangi bir hakları etkilemez. '; 
			           |es_ES = 'El grupo de acceso no influye en los derechos de participantes
			           |porque su perfil está marcado para borrar.'"));
	Else
		AfterWriteCompletion(WriteParameters);
	EndIf;
	
EndProcedure

&AtServer
Procedure FillCheckProcessingAtServer(Cancel, CheckedAttributes)
	
	VerifiedObjectAttributes = New Array;
	Errors = Undefined;
	
	// Checking for unfilled and duplicate users.
	VerifiedObjectAttributes.Add("Users.User");
	UsersTreeRows = FormAttributeToValue("GroupUsers").Rows;
	ErrorsCount = ?(Errors = Undefined, 0, Errors.Count());
	
	// Preparing data to check mapping between authorization object types.
	Query = New Query;
	Query.SetParameter("Users", UsersTreeRows.UnloadColumn("User"));
	Query.SetParameter("Parent", Object.Profile);
	Query.Text =
	"SELECT
	|	AccessGroupProfilesAssignment.UsersType
	|INTO AccessGroupProfilesAssignment
	|FROM
	|	Catalog.AccessGroupProfiles.Purpose AS AccessGroupProfilesAssignment
	|WHERE
	|	AccessGroupProfilesAssignment.Ref = &Parent
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ExternalUsers.Ref
	|FROM
	|	Catalog.ExternalUsers AS ExternalUsers
	|WHERE
	|	NOT FALSE IN
	|				(SELECT TOP 1
	|					FALSE
	|				FROM
	|					AccessGroupProfilesAssignment AS AccessGroupProfilesAssignment
	|				WHERE
	|					VALUETYPE(AccessGroupProfilesAssignment.UsersType) = VALUETYPE(ExternalUsers.AuthorizationObject))
	|	AND ExternalUsers.Ref IN(&Users)
	|
	|UNION ALL
	|
	|SELECT
	|	ExternalUserGroupsAssignment.Ref
	|FROM
	|	Catalog.ExternalUsersGroups.Purpose AS ExternalUserGroupsAssignment
	|WHERE
	|	NOT FALSE IN
	|				(SELECT TOP 1
	|					FALSE
	|				FROM
	|					AccessGroupProfilesAssignment AS AccessGroupProfilesAssignment
	|				WHERE
	|					VALUETYPE(AccessGroupProfilesAssignment.UsersType) = VALUETYPE(ExternalUserGroupsAssignment.UsersType))
	|	AND ExternalUserGroupsAssignment.Ref IN(&Users)
	|
	|UNION ALL
	|
	|SELECT
	|	Users.Ref
	|FROM
	|	Catalog.Users AS Users
	|WHERE
	|	NOT FALSE IN
	|				(SELECT TOP 1
	|					FALSE
	|				FROM
	|					AccessGroupProfilesAssignment AS AccessGroupProfilesAssignment
	|				WHERE
	|					VALUETYPE(AccessGroupProfilesAssignment.UsersType) = TYPE(Catalog.Users))
	|	AND Users.Ref IN(&Users)
	|
	|UNION ALL
	|
	|SELECT
	|	UserGroups.Ref
	|FROM
	|	Catalog.UserGroups AS UserGroups
	|WHERE
	|	NOT FALSE IN
	|				(SELECT TOP 1
	|					FALSE
	|				FROM
	|					AccessGroupProfilesAssignment AS AccessGroupProfilesAssignment
	|				WHERE
	|					VALUETYPE(AccessGroupProfilesAssignment.UsersType) = TYPE(Catalog.Users))
	|	AND UserGroups.Ref IN(&Users)";
	
	SetPrivilegedMode(True);
	ProhibitedUsers = Query.Execute().Unload().UnloadColumn("Ref");
	SetPrivilegedMode(False);
	
	For Each CurrentRow In UsersTreeRows Do
		RowNumber = UsersTreeRows.IndexOf(CurrentRow);
		Member = CurrentRow.User;
		
		// Checking whether the value is filled.
		If NOT ValueIsFilled(Member) Then
			CommonClientServer.AddUserError(Errors,
				"GroupUsers[%1].User",
				SpecifyMessage(NStr("ru = 'Пользователь не выбран.'; en = 'User is not selected.'; pl = 'Użytkownik nie jest wybrany.';de = 'Benutzer ist nicht ausgewählt.';ro = 'Utilizatorul nu este selectat.';tr = 'Kullanıcı seçilmedi.'; es_ES = 'Usuario no seleccionado.'"), Member),
				"GroupUsers",
				RowNumber,
				SpecifyMessage(NStr("ru = 'Пользователь в строке %1 не выбран.'; en = 'User is not selected in line #%1.'; pl = 'W wierszu %1 nie wybrano użytkownika.';de = 'Benutzer in Zeile %1 ist nicht ausgewählt.';ro = 'Utilizatorul din rândul %1 nu este selectat.';tr = '%1 satırındaki kullanıcı seçilmedi.'; es_ES = 'Usuario en la línea %1 no está seleccionado.'"), Member));
			Continue;
		EndIf;
		
		// Checking for duplicate values.
		FoundValues = UsersTreeRows.FindRows(
			New Structure("User", CurrentRow.User));
		
		If FoundValues.Count() > 1 Then
			
			If TypeOf(CurrentRow.User) = Type("CatalogRef.Users") Then
				SingleErrorText      = NStr("ru = 'Пользователь ""%2"" повторяется.'; en = 'User ""%2"" is duplicated.'; pl = 'Zduplikowany użytkownik ""%2"".';de = 'Benutzer ""%2"" wird dupliziert.';ro = 'Utilizatorul ""%2"" este dublat.';tr = 'Kullanıcı ""%2"" çoğaltılamaz.'; es_ES = 'Usuario ""%2"" tiene duplicado.'");
				SeveralErrorsText = NStr("ru = 'Пользователь ""%2"" в строке %1 повторяется.'; en = 'User ""%2"" in line %1 is duplicated.'; pl = 'Zduplikowany użytkownik ""%2"" w wierszu %1.';de = 'Duplizieren Sie den Benutzer ""%2"" in der Zeile %1.';ro = 'Utilizatorul ""%2"" în rândul %1 se repetă.';tr = '%1 satırda ""%2"" kullanıcıyı yenileyin.'; es_ES = 'Usuario duplicado ""%2"" en la línea %1.'");
				
			ElsIf TypeOf(CurrentRow.User) = Type("CatalogRef.ExternalUsers") Then
				SingleErrorText      = NStr("ru = 'Внешний пользователь ""%2"" повторяется.'; en = 'External user ""%2"" is duplicated.'; pl = 'Zduplikowany użytkownik zewnętrzny ""%2"".';de = 'Duplizieren Sie den externen Benutzer ""%2"".';ro = 'Utilizator extern ""%2"" se repetă.';tr = '""%2"" dış kullanıcıyı yenileyin.'; es_ES = 'Usuario externo duplicado ""%2"".'");
				SeveralErrorsText = NStr("ru = 'Внешний пользователь ""%2"" в строке %1 повторяется.'; en = 'External user ""%2"" in line %1 is duplicated.'; pl = 'Zduplikowany użytkownik zewnętrzny ""%2"" w wierszu %1.';de = 'Duplizieren Sie den externen Benutzer ""%2"" in Zeile%1.';ro = 'Utilizator extern ""%2"" în rândul %1 se repetă.';tr = '%1 satırda ""%2"" dış kullanıcıyı yenileyin.'; es_ES = 'Usuario externo duplicado ""%2"" en la línea %1.'");
				
			ElsIf TypeOf(CurrentRow.User) = Type("CatalogRef.UserGroups") Then
				SingleErrorText      = NStr("ru = 'Группа пользователей ""%2"" повторяется.'; en = 'User group ""%2"" is duplicated.'; pl = 'Zduplikowana grupa użytkowników ""%2"".';de = 'Duplizieren Sie die Benutzergruppe ""%2"".';ro = 'Grupul de utilizatori ""%2"" se repetă.';tr = '""%2"" kullanıcı grubunu yenileyin.'; es_ES = 'Grupo de usuario duplicado ""%2"".'");
				SeveralErrorsText = NStr("ru = 'Группа пользователей ""%2"" в строке %1 повторяется.'; en = 'Users group ""%2"" in line %1 is duplicated.'; pl = 'Zduplikowana grupa użytkowników ""%2"" w wierszu %1.';de = 'Duplizieren Sie die Benutzergruppe ""%2"" in Zeile%1.';ro = 'Grupul de utilizatori ""%2"" în rândul %1 se repetă.';tr = '%1 satırda ""%2"" kullanıcı grubunu yenileyin.'; es_ES = 'Grupo de usuario duplicado ""%2"" en la línea %1.'");
			Else
				SingleErrorText      = NStr("ru = 'Группа внешних пользователей ""%2"" повторяется.'; en = 'External user group ""%2"" is duplicated.'; pl = 'Zduplikowana zewnętrzna grupa użytkowników ""%2""';de = 'Duplizieren Sie die externe Benutzergruppe ""%2"".';ro = 'Grupul de utilizatori extern ""%2"" se repetă.';tr = '""%2"" dış kullanıcı grubunu yenileyin.'; es_ES = 'Grupo de usuario externo duplicado ""%2"".'");
				SeveralErrorsText = NStr("ru = 'Группа внешних пользователей ""%2"" в строке %1 повторяется.'; en = 'External user group ""%2"" in line %1 is duplicated.'; pl = 'Zduplikowana zewnętrzna grupa użytkowników ""%2"" w wierszu %1.';de = 'Duplizieren Sie die externe Benutzergruppe ""%2"" in Zeile %1.';ro = 'Grupul de utilizatori externi ""%2"" în rândul %1 se repetă.';tr = '%1 satırda ""%2"" kullanıcı grubunu yenileyin.'; es_ES = 'Grupo de usuario externo duplicado ""%2"" en la línea %1.'");
			EndIf;
			
			CommonClientServer.AddUserError(Errors,
				"GroupUsers[%1].User",
				SpecifyMessage(SingleErrorText, Member),
				"GroupUsers",
				RowNumber,
				SpecifyMessage(SeveralErrorsText, Member));
		EndIf;
		
		// Checking for users in the predefined Administrators group.
		If Object.Ref = Catalogs.AccessGroups.Administrators
		   AND TypeOf(CurrentRow.User) <> Type("CatalogRef.Users") Then
			
			If TypeOf(CurrentRow.User) = Type("CatalogRef.ExternalUsers") Then
				SingleErrorText      = NStr("ru = 'Внешний пользователь ""%2"" недопустим в предопределенной группе доступа Администраторы.'; en = 'External user ""%2"" cannot be a member of the predefined Administrators access group.'; pl = 'Grupa dostępu Administratorzy nie może zawierać użytkowników zewnętrznych. Usuń użytkownika zewnętrznego ""%2"" z grupy Administratorzy.';de = 'Die Zugriffsgruppe Administratoren darf keine externen Benutzer enthalten. Entfernen Sie den externen Benutzer ""%2"" aus der Administratorengruppe.';ro = 'Utilizatorul extern ""%2"" nu este admisibil în grupul de acces predefinit Administratori.';tr = 'Yöneticiler erişim grubu harici kullanıcılar içeremez. Yöneticiler grubundan ""%2"" dış kullanıcıyı kaldırın.'; es_ES = 'El grupo de acceso de Administradores no puede contener usuarios externos. Eliminar el usuario externo ""%2"" del grupo de Administradores.'");
				SeveralErrorsText = NStr("ru = 'Внешний пользователь ""%2"" в строке %1 недопустим в предопределенной группе доступа Администраторы.'; en = 'External user ""%2"" in line %1 cannot be a member of the predefined Administrators access group.'; pl = 'Zewnętrzny użytkownik ""%2"" w wierszu %1 jest niepoprawny w predefiniowanej grupie Administratorzy.';de = 'Der externe Benutzer ""%2"" in der Zeile %1 ist in der vordefinierten Gruppe Administratoren ungültig.';ro = 'Utilizatorul extern ""%2"" în rândul %1 nu este admisibil în grupul de acces predefinit Administratori.';tr = '""%2"" satırındaki dış kullanıcı ""%1"" önceden tanımlanmış Yöneticiler grubunda geçersizdir.'; es_ES = 'Usuario externo ""%2"" en la línea %1 es inválido en el grupo predefinido Administradores.'");
				
			ElsIf TypeOf(CurrentRow.User) = Type("CatalogRef.UserGroups") Then
				SingleErrorText      = NStr("ru = 'Группа пользователей ""%2"" недопустима в предопределенной группе доступа Администраторы.'; en = 'User group ""%2"" cannot belong to the predefined Administrators access group.'; pl = 'Grupa dostępu Administratorzy nie może zawierać grup użytkowników. Usuń grupę użytkowników ""%2"" z grupy Administratorzy.';de = 'Die Zugriffsgruppe Administratoren darf keine Benutzergruppen enthalten. Entfernen Sie die Benutzergruppe ""%2"" aus der Gruppe Administratoren.';ro = 'Grupul de utilizatori ""%2"" nu este admisibil în grupul de acces predefinit Administratori.';tr = 'Yöneticiler erişim grubu harici kullanıcılar içeremez. Yöneticiler grubundan ""%2"" kullanıcı grubunu kaldırın.'; es_ES = 'El grupo de acceso de Administradores no puede contener los grupos de usuarios. Eliminar el grupo de usuarios ""%2"" del grupo de Administradores.'");
				SeveralErrorsText = NStr("ru = 'Группа пользователей ""%2"" в строке %1 недопустима в предопределенной группе доступа Администраторы.'; en = 'User group ""%2"" in line %1 cannot belong to the predefined Administrators access group.'; pl = 'Grupa użytkowników ""%2"" w wierszu %1 jest niepoprawna w predefiniowanej grupie dostępu Administratorzy.';de = 'Die ""%2"" Benutzergruppe in Zeile %1 ist in der vordefinierten Zugriffsgruppe Administratoren ungültig.';ro = 'Grupul de utilizatori ""%2"" din rândul %1 nu este admisibil în grupul de acces predefinit Administratori.';tr = '""%2"" satırındaki kullanıcı grubu ""%1"" önceden tanımlanmış Yöneticiler grubunda geçersizdir.'; es_ES = 'El grupo de usuarios ""%2"" en la línea %1 es inválido en el grupo de acceso predefinido Administradores.'");
			Else
				SingleErrorText      = NStr("ru = 'Группа внешних пользователей ""%2"" недопустима в предопределенной группе доступа Администраторы.'; en = 'External user group ""%2"" cannot belong to the predefined Administrators access group.'; pl = 'Grupa dostępu Administratorzy nie może zawierać zewnętrznych grup użytkowników. Usuń zewnętrzną grupę użytkowników ""%2"" z grupy Administratorzy.';de = 'Die Zugriffsgruppe Administratoren darf keine externen Benutzergruppen enthalten. Entfernen Sie die externe Benutzergruppe ""%2"" aus der Gruppe Administratoren.';ro = 'Grupul de utilizatori externi ""%2"" nu este admisibil în grupul de acces predefinit Administratori.';tr = 'Yöneticiler erişim grubu harici kullanıcı gruplarını içeremez. Yöneticiler grubundan ""%2"" dış kullanıcı grubunu kaldırın.'; es_ES = 'El grupo de acceso de Administradores no puede contener los grupos de usuarios externos. Eliminar el grupo de usuarios externos ""%2"" del grupo de Administradores.'");
				SeveralErrorsText = NStr("ru = 'Группа внешних пользователей ""%2"" в строке %1 недопустима в предопределенной группе доступа Администраторы.'; en = 'External user group ""%2"" in line %1 cannot belong to the predefined Administrators access group.'; pl = 'Zewnętrzna grupa użytkowników ""%2"" w wierszu %1 jest niepoprawna w predefiniowanej grupie dostępu Administratorzy.';de = 'Die externe Benutzergruppe ""%2"" in der Zeile %1 ist in der vordefinierten Zugriffsgruppe Administratoren ungültig.';ro = 'Grupul de utilizatori externi ""%2"" în rândul %1 nu este admisibil în grupul de acces predefinit Administratori.';tr = '""%2"" satırındaki dış kullanıcı grubu ""%1"" önceden tanımlanmış Yöneticiler grubunda geçersizdir.'; es_ES = 'Grupo de usuarios externos ""%2"" en la línea %1 es inválido en el grupo de acceso predefinido Administradores.'");
			EndIf;
			
			CommonClientServer.AddUserError(Errors,
				"GroupUsers[%1].User",
				SpecifyMessage(SingleErrorText, Member),
				"GroupUsers",
				RowNumber,
				SpecifyMessage(SeveralErrorsText, Member));
		EndIf;
		
		If ProhibitedUsers.Find(CurrentRow.User) <> Undefined Then
			
			If TypeOf(CurrentRow.User) = Type("CatalogRef.Users") Then
				SingleErrorText      = NStr("ru = 'Пользователь ""%2"" недопустим для указанного типа участников.'; en = 'User ""%2"" does not match the specified member type.'; pl = 'Typ użytkownika ""%2"" nie jest zgodny z określonym typem uczestnika. Zmień typ uczestnika lub wybierz innego użytkownika.';de = 'Der Benutzertyp ""%2"" stimmt nicht mit dem angegebenen Elementtyp überein. Ändern Sie den Elementtyp oder wählen Sie einen anderen Benutzer aus.';ro = 'Utilizatorul ""%2"" este inadmisibil pentru tipul de participanți indicat.';tr = '""%2"" kullanıcı türü belirtilen üye tipi ile eşleşmiyor. Üye türünü değiştirin veya başka bir kullanıcı seçin.'; es_ES = 'El tipo de usuario ""%2"" no coincide con el tipo de miembro especificado. Cambiar el tipo de miembro o seleccionar otro usuario.'");
				SeveralErrorsText = NStr("ru = 'Пользователь ""%2"" в строке %1 недопустим для указанного типа участников.'; en = 'User ""%2"" in line %1 does not match the specified member type.'; pl = 'Typ użytkownika ""%2"" w wierszu %1 nie jest zgodny z określonym typem uczestnika. Zmień typ uczestnika lub wybierz innego użytkownika.';de = 'Der Benutzertyp ""%2"" in der Zeile %1 stimmt nicht mit dem angegebenen Elementtyp überein. Ändern Sie den Elementtyp oder wählen Sie einen anderen Benutzer aus.';ro = 'Utilizatorul ""%2"" în rândul %1 nu este admisibil pentru tipul de participanți indicat.';tr = '""%1""satırındaki ""%2"" kullanıcı türü belirtilen üye tipi ile eşleşmiyor. Üye türünü değiştirin veya başka bir kullanıcı seçin.'; es_ES = 'El tipo de usuario ""%2"" en la línea %1 no coincide con el tipo de miembro especificado. Cambiar el tipo de miembro o seleccionar otro usuario.'");
			ElsIf TypeOf(CurrentRow.User) = Type("CatalogRef.UserGroups") Then
				SingleErrorText      = NStr("ru = 'Группа пользователей ""%2"" недопустима для указанного типа участников.'; en = 'User group ""%2"" does not match the specified member type.'; pl = 'Typ grupy użytkowników ""%2"" nie jest zgodny z określonym typem uczestnika. Zmień typ uczestnika lub wybierz innego użytkownika.';de = 'Der Typ der Benutzergruppe ""%2"" stimmt nicht mit dem angegebenen Elementtyp überein. Ändern Sie den Elementtyp oder wählen Sie einen anderen Benutzer aus.';ro = 'Grupul de utilizatori ""%2"" este inadmisibil pentru tipul de participanți indicat.';tr = '""%2"" kullanıcı grubu türü belirtilen üye tipi ile eşleşmiyor. Üye türünü değiştirin veya başka bir kullanıcı seçin.'; es_ES = 'El tipo del grupo de usuarios ""%2"" no coincide con el tipo de miembro especificado. Cambiar el tipo de miembro o seleccionar otro usuario.'");
				SeveralErrorsText = NStr("ru = 'Группа пользователей ""%2"" в строке %1 недопустима для указанного типа участников.'; en = 'User group ""%2"" in line %1 does not match the specified member type.'; pl = 'Typ grupy użytkowników ""%2"" w wierszu %1 nie jest zgodny z określonym typem uczestnika. Zmień typ uczestnika lub wybierz innego użytkownika.';de = 'Der Typ der Benutzergruppe ""%2"" in der Zeile %1 stimmt nicht mit dem angegebenen Elementtyp überein. Ändern Sie den Elementtyp oder wählen Sie einen anderen Benutzer aus.';ro = 'Grupul de utilizatori ""%2"" în rândul %1este inadmisibil pentru tipul de participanți indicat.';tr = '""%1"" satırındaki ""%2"" kullanıcı grubu türü belirtilen üye tipi ile eşleşmiyor. Üye türünü değiştirin veya başka bir kullanıcı seçin.'; es_ES = 'El tipo del grupo de usuarios ""%2"" en la línea %1 no coincide con el tipo de miembro especificado. Cambiar el tipo de miembro o seleccionar otro usuario.'");
			ElsIf TypeOf(CurrentRow.User) = Type("CatalogRef.ExternalUsers") Then
				SingleErrorText      = NStr("ru = 'Внешний пользователь ""%2"" недопустим для указанного типа участников.'; en = 'External user ""%2"" does not match the specified member type.'; pl = 'Typ użytkownika zewnętrznego ""%2"" nie jest zgodny z określonym typem uczestnika. Zmień typ uczestnika lub wybierz innego użytkownika.';de = 'Der Typ des externen Benutzers ""%2"" stimmt nicht mit dem angegebenen Elementtyp überein. Ändern Sie den Elementtyp oder wählen Sie einen anderen Benutzer aus.';ro = 'Utilizatorul extern ""%2"" este inadmisibil pentru tipul de participanți indicat.';tr = '""%2"" dış kullanıcı türü belirtilen üye tipi ile eşleşmiyor. Üye türünü değiştirin veya başka bir kullanıcı seçin.'; es_ES = 'El tipo de usuario externo ""%2"" no coincide con el tipo de miembro especificado. Cambiar el tipo de miembro o seleccionar otro usuario.'");
				SeveralErrorsText = NStr("ru = 'Внешний пользователь ""%2"" в строке %1 недопустим для указанного типа участников.'; en = 'External user ""%2"" in line %1 does not match the specified member type.'; pl = 'Typ użytkownika zewnętrznego ""%2"" w wierszu %1 nie jest zgodny z określonym typem uczestnika. Zmień typ uczestnika lub wybierz innego użytkownika.';de = 'Der Typ des externen Benutzers ""%2"" in der Zeile %1 stimmt nicht mit dem angegebenen Elementtyp überein. Ändern Sie den Elementtyp oder wählen Sie einen anderen Benutzer aus.';ro = 'Utilizatorul extern ""%2"" în rândul %1 nu este admisibil pentru tipul de participanți indicat.';tr = '""%1""satırındaki ""%2"" dış kullanıcı türü belirtilen üye tipi ile eşleşmiyor. Üye türünü değiştirin veya başka bir kullanıcı seçin.'; es_ES = 'El tipo de usuario externo ""%2"" en la línea %1 no coincide con el tipo de miembro especificado. Cambiar el tipo de miembro o seleccionar otro usuario.'");
			Else // External user group.
				SingleErrorText      = NStr("ru = 'Группа внешних пользователей ""%2"" недопустима для указанного типа участников.'; en = 'External user group ""%2"" does not match the specified member type.'; pl = 'Typ zewnętrznej grupy użytkowników ""%2"" nie jest zgodny z określonym typem uczestnika. Zmień typ uczestnika lub wybierz innego użytkownika.';de = 'Der Typ der externen Benutzergruppe ""%2"" stimmt nicht mit dem angegebenen Elementtyp überein. Ändern Sie den Elementtyp oder wählen Sie einen anderen Benutzer aus.';ro = 'Grupul de utilizatori externi ""%2"" este inadmisibil pentru tipul de participanți indicat.';tr = '""%2"" dış kullanıcı grubu türü belirtilen üye tipi ile eşleşmiyor. Üye türünü değiştirin veya başka bir kullanıcı seçin.'; es_ES = 'El tipo del grupo de usuarios externos ""%2"" no coincide con el tipo de miembro especificado. Cambiar el tipo de miembro o seleccionar otro usuario.'");
				SeveralErrorsText = NStr("ru = 'Группа внешних пользователей ""%2"" в строке %1 недопустима для указанного типа участников.'; en = 'External user group ""%2"" in line %1 does not match the specified member type.'; pl = 'Typ zewnętrznej grupy użytkowników ""%2"" w wierszu %1 nie jest zgodny z określonym typem uczestnika. Zmień typ uczestnika lub wybierz innego użytkownika.';de = 'Der Typ der externen Benutzergruppe ""%2"" in der Zeile %1 stimmt nicht mit dem angegebenen Elementtyp überein. Ändern Sie den Elementtyp oder wählen Sie einen anderen Benutzer aus.';ro = 'Grupul de utilizatori externi ""%2"" în rândul %1este inadmisibil pentru tipul de participanți indicat.';tr = '""%1""satırındaki ""%2"" dış kullanıcı türü belirtilen üye tipi ile eşleşmiyor. Üye türünü değiştirin veya başka bir kullanıcı seçin.'; es_ES = 'El tipo del grupo de usuarios externos ""%2"" en la línea %1 no coincide con el tipo de miembro especificado. Cambiar el tipo de miembro o seleccionar otro usuario.'");
			EndIf;
			
			CommonClientServer.AddUserError(Errors,
				"GroupUsers[%1].User",
				SpecifyMessage(SingleErrorText, Member),
				"GroupUsers",
				RowNumber,
				SpecifyMessage(SeveralErrorsText, Member));
			
		EndIf;
		
	EndDo;
	
	If NOT Common.DataSeparationEnabled()
		AND Object.Ref = Catalogs.AccessGroups.Administrators Then
		
		ErrorDescription = "";
		AccessManagementInternal.CheckAdministratorsAccessGroupForIBUser(
			GroupUsers.GetItems(), ErrorDescription);
		
		If ValueIsFilled(ErrorDescription) Then
			CommonClientServer.AddUserError(Errors,
				"GroupUsers", ErrorDescription, "");
		EndIf;
	EndIf;
	
	// Checking for blank and duplicate access values.
	SkipKindsAndValuesCheck = False;
	If ErrorsCount <> ?(Errors = Undefined, 0, Errors.Count()) Then
		SkipKindsAndValuesCheck = True;
		Items.UsersAndAccess.CurrentPage = Items.GroupUsers;
	EndIf;
	
	AccessManagementInternalClientServer.ProcessingOfCheckOfFillingAtServerAllowedValuesEditForm(
		ThisObject, Cancel, VerifiedObjectAttributes, Errors, SkipKindsAndValuesCheck);
	
	CommonClientServer.ReportErrorsToUser(Errors, Cancel);
	
	CheckedAttributes.Delete(CheckedAttributes.Find("Object"));
	CurrentObject = FormAttributeToValue("Object");
	
	CurrentObject.AdditionalProperties.Insert(
		"VerifiedObjectAttributes", VerifiedObjectAttributes);
	
	If NOT CurrentObject.CheckFilling() Then
		Cancel = True;
	EndIf;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure ProfileOnChange(Item)
	
	ProfileOnChangeAtServer();
	
EndProcedure

&AtClient
Procedure UserOwnerStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	
EndProcedure

&AtClient
Procedure CommentOnChange(Item)
	
	UpdateCommentPicture(Items.CommentPage, Object.Comment);
	
EndProcedure

#EndRegion

#Region UsersFormTableItemsEventHandlers

&AtClient
Procedure UsersOnChange(Item)
	
	Modified = True;
	
EndProcedure

&AtClient
Procedure UsersBeforeAddRow(Item, Cancel, Clone, Parent, Folder)
	
	If Clone Then
		
		If Item.CurrentData.GetParent() <> Undefined Then
			Cancel = True;
			
			Items.Users.CurrentRow =
				Item.CurrentData.GetParent().GetID();
			
			Items.Users.CopyRow();
		EndIf;
		
	ElsIf Items.Users.CurrentRow <> Undefined Then
		Cancel = True;
		Items.Users.CopyRow();
	EndIf;
	
EndProcedure

&AtClient
Procedure UsersBeforeRowChange(Item, Cancel)
	
	If Item.CurrentData.GetParent() <> Undefined Then
		Cancel = True;
		
		Items.Users.CurrentRow =
			Item.CurrentData.GetParent().GetID();
		
		Items.Users.ChangeRow();
	EndIf;
	
EndProcedure

&AtClient
Procedure UsersBeforeDelete(Item, Cancel)
	
	ParentLevelRow = Item.CurrentData.GetParent();
	
	If ParentLevelRow <> Undefined Then
		Cancel = True;
		
		If TypeOf(ParentLevelRow.User) =
		        Type("CatalogRef.UserGroups") Then
			
			ShowMessageBox(,
				NStr("ru = 'Пользователи групп отображаются для сведения,
				           |что они получают доступ групп пользователей.
				           |Их нельзя удалить в этом списке.'; 
				           |en = 'User groups are displayed to show 
				           |that they are granted the user group access.
				           |Users cannot be deleted from this list.'; 
				           |pl = 'Użytkownicy grup są wyświetlani w celu poinformowania,
				           |że uzyskują oni dostęp do grup użytkowników.
				           |Nie można ich usunąć z tej listy.';
				           |de = 'Benutzer von Gruppen werden angezeigt, um zu erfahren,
				           |dass ihnen der Zugriff auf Gruppen von Benutzern gewährt wird.
				           |Sie können nicht aus dieser Liste gelöscht werden.';
				           |ro = 'Utilizatorii grupurilor se afișează pentru informații,
				           |precum că ei au accesul grupurilor de utilizatori.
				           |Ei nu pot fi șterși în această listă.';
				           |tr = 'Grup kullanıcıları, kullanıcı gruplarına 
				           |eriştikleri bilgiler için görüntülenir.
				           |Bu listeden silinemezler.'; 
				           |es_ES = 'Los usuarios de grupos se muestran para saber
				           |que ellos obtienen acceso a los grupos de usuarios.
				           |No se puede eliminarlos en esta lista.'"));
		Else
			ShowMessageBox(,
				NStr("ru = 'Внешние пользователи групп отображаются для сведения,
				           |что они получают доступ групп внешних пользователей.
				           |Их нельзя удалить в этом списке.'; 
				           |en = 'External group users are displayed to show
				           |that they are granted access of external user groups.
				           |They cannot be deleted from this list.'; 
				           |pl = 'Użytkownicy zewnętrzni grup są wyświetlani w celu poinformowania,
				           |że uzyskują oni dostęp do grup użytkowników.
				           |Nie można ich usunąć z tej listy.';
				           |de = 'Externe Benutzer von Gruppen werden angezeigt, um zu erfahren,
				           |dass ihnen der Zugriff auf Gruppen von externen Benutzern gewährt wird.
				           |Sie können nicht aus dieser Liste gelöscht werden.';
				           |ro = 'Utilizatorii externi ai grupurilor se afișează pentru informații,
				           |precum că ei au accesul grupurilor de utilizatori externi.
				           |Ei nu pot fi șterși în această listă.';
				           |tr = 'Harici grup kullanıcıları, harici kullanıcı gruplarına 
				           |eriştikleri bilgiler için görüntülenir.
				           |Bu listeden silinemezler.'; 
				           |es_ES = 'Los usuarios externos de grupos se muestran para saber
				           |que ellos obtienen acceso a los grupos de usuarios.
				           |No se puede eliminarlos en esta lista.'"));
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure UsersOnStartEdit(Item, NewRow, Clone)
	
	If Clone Then
		Item.CurrentData.User = Undefined;
	EndIf;
	
	If Item.CurrentData.User = Undefined Then
		Item.CurrentData.PictureNumber = -1;
		Item.CurrentData.User = PredefinedValue(
			"Catalog.Users.EmptyRef");
	EndIf;
	
EndProcedure

&AtClient
Procedure UsersOnEditEnd(Item, NewRow, CancelEdit)
	
	If NewRow
	   AND Item.CurrentData <> Undefined
	   AND Item.CurrentData.User = PredefinedValue(
	     	"Catalog.Users.EmptyRef") Then
		
		Item.CurrentData.User = Undefined;
	EndIf;
	
EndProcedure

&AtClient
Procedure UsersChoiceProcessing(Item, ValueSelected, StandardProcessing)
	
	If PickMode Then
		GroupUsers.GetItems().Clear();
	EndIf;
	ModifiedRows = New Array;
	
	If TypeOf(ValueSelected) = Type("Array") Then
		For each Value In ValueSelected Do
			ValueNotFound = True;
			For each Item In GroupUsers.GetItems() Do
				If Item.User = Value Then
					ValueNotFound = False;
					Break;
				EndIf;
			EndDo;
			If ValueNotFound Then
				NewItem = GroupUsers.GetItems().Add();
				NewItem.User = Value;
				ModifiedRows.Add(NewItem.GetID());
			EndIf;
		EndDo;
		
	ElsIf Item.CurrentData.User <> ValueSelected Then
		Item.CurrentData.User = ValueSelected;
		ModifiedRows.Add(Item.CurrentRow);
	EndIf;
	
	If ModifiedRows.Count() > 0 Then
		UpdatedRows = Undefined;
		RefreshGroupsUsers(ModifiedRows, UpdatedRows);
		For each RowID In UpdatedRows Do
			Items.Users.Expand(RowID);
		EndDo;
		Modified = True;
	EndIf;
	
EndProcedure

&AtClient
Procedure UsersAfterRemove(Item)
	
	// Setting a tree presentation.
	HasNested = False;
	For each Item In GroupUsers.GetItems() Do
		If Item.GetItems().Count() > 0 Then
			HasNested = True;
			Break;
		EndIf;
	EndDo;
	
	Items.Users.Representation =
		?(HasNested, TableRepresentation.Tree, TableRepresentation.List);
	
EndProcedure

&AtClient
Procedure UserOnChange(Item)
	
	If ValueIsFilled(Items.Users.CurrentData.User) Then
		RefreshGroupsUsers(Items.Users.CurrentRow);
		Items.Users.Expand(Items.Users.CurrentRow);
	Else
		Items.Users.CurrentData.PictureNumber = -1;
	EndIf;
	
EndProcedure

&AtClient
Procedure UserStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	
	SelectPickUsers(False);
	PickMode = False;
	
EndProcedure

&AtClient
Procedure UserClearing(Item, StandardProcessing)
	
	StandardProcessing = False;
	
	Items.Users.CurrentData.PictureNumber = -1;
	Items.Users.CurrentData.User  = PredefinedValue(
		"Catalog.Users.EmptyRef");
	
EndProcedure

&AtClient
Procedure UserTextInputCompletion(Item, Text, ChoiceData, StandardProcessing)
	
	If ValueIsFilled(Text) Then
		StandardProcessing = False;
		If Object.Ref = PredefinedValue("Catalog.AccessGroups.Administrators") Then
			ChoiceData = AccessManagementInternalServerCall.GenerateUserSelectionData(
				Text, False, False);
		Else
			ChoiceData = AccessManagementInternalServerCall.GenerateUserSelectionData(
				Text);
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure UserAutoComplete(Item, Text, ChoiceData, Wait, StandardProcessing)
	
	If ValueIsFilled(Text) Then
		StandardProcessing = False;
		If Object.Ref = PredefinedValue("Catalog.AccessGroups.Administrators") Then
			ChoiceData = AccessManagementInternalServerCall.GenerateUserSelectionData(
				Text, False, False);
		Else
			ChoiceData = AccessManagementInternalServerCall.GenerateUserSelectionData(
				Text);
		EndIf;
	EndIf;
	
EndProcedure

#EndRegion

#Region AccessKindsFormTableItemsEventHandlers

&AtClient
Procedure AccessKindsChoice(Item, RowSelected, Field, StandardProcessing)
	
	If Not ReadOnly
	   AND Not Items.Access.ReadOnly Then
		
		Items.AccessKinds.ChangeRow();
	EndIf;
	
EndProcedure

&AtClient
Procedure AccessKindsOnActivateRow(Item)
	
	AccessManagementInternalClient.AccessKindsOnActivateRow(
		ThisObject, Item);
	
EndProcedure

&AtClient
Procedure AccessKindsOnActivateCell(Item)
	
	AccessManagementInternalClient.AccessKindsOnActivateCell(
		ThisObject, Item);
	
EndProcedure

&AtClient
Procedure AccessKindsOnStartEdit(Item, NewRow, Clone)
	
	AccessManagementInternalClient.AccessKindsOnStartEdit(
		ThisObject, Item, NewRow, Clone);
	
EndProcedure

&AtClient
Procedure AccessKindsOnEndEdit(Item, NewRow, CancelEdit)
	
	AccessManagementInternalClient.AccessKindsOnEndEdit(
		ThisObject, Item, NewRow, CancelEdit);
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Event handlers of the AllAllowedPresentation item of the AccessKinds form table.

&AtClient
Procedure AccessKindsAllAllowedPresentationOnChange(Item)
	
	AccessManagementInternalClient.AccessKindsAllAllowedPresentationOnChange(
		ThisObject, Item);
	
EndProcedure

&AtClient
Procedure AccessKindsAllAllowedPresentationChoiceProcessing(Item, ValueSelected, StandardProcessing)
	
	AccessManagementInternalClient.AccessKindsAllAllowedPresentationChoiceProcessing(
		ThisObject, Item, ValueSelected, StandardProcessing);
	
EndProcedure

#EndRegion

#Region AccessValueFormTableItemsEventHandlers

&AtClient
Procedure AccessValuesOnChange(Item)
	
	AccessManagementInternalClient.AccessValuesOnChange(
		ThisObject, Item);
	
EndProcedure

&AtClient
Procedure AccessValuesOnStartEdit(Item, NewRow, Clone)
	
	AccessManagementInternalClient.AccessValuesOnStartEdit(
		ThisObject, Item, NewRow, Clone);
	
EndProcedure

&AtClient
Procedure AccessValuesOnEndEdit(Item, NewRow, CancelEdit)
	
	AccessManagementInternalClient.AccessValuesOnEndEdit(
		ThisObject, Item, NewRow, CancelEdit);
	
EndProcedure

&AtClient
Procedure AccessValueStartChoice(Item, ChoiceData, StandardProcessing)
	
	AccessManagementInternalClient.AccessValueStartChoice(
		ThisObject, Item, ChoiceData, StandardProcessing);
	
EndProcedure

&AtClient
Procedure AccessValueChoiceProcessing(Item, ValueSelected, StandardProcessing)
	
	AccessManagementInternalClient.AccessValueChoiceProcessing(
		ThisObject, Item, ValueSelected, StandardProcessing);
	
EndProcedure

&AtClient
Procedure AccessValueClearing(Item, StandardProcessing)
	
	AccessManagementInternalClient.AccessValueClearing(
		ThisObject, Item, StandardProcessing);
	
EndProcedure

&AtClient
Procedure AccessValueAutoComplete(Item, Text, ChoiceData, Wait, StandardProcessing)
	
	AccessManagementInternalClient.AccessValueAutoComplete(
		ThisObject, Item, Text, ChoiceData, Wait, StandardProcessing);
	
EndProcedure

&AtClient
Procedure AccessValueTextInputCompletion(Item, Text, ChoiceData, StandardProcessing)
	
	AccessManagementInternalClient.AccessValueTextInputCompletion(
		ThisObject, Item, Text, ChoiceData, StandardProcessing);
	
EndProcedure

#EndRegion

#Region FormCommandHandlers

&AtClient
Procedure WriteAndClose(Command)
	
	Write(New Structure("WriteAndClose"));
	
EndProcedure

&AtClient
Procedure Select(Command)
	
	SelectPickUsers(True);
	PickMode = True;
	
EndProcedure

&AtClient
Procedure SnowUnusedAccessKinds(Command)
	
	ShowUnusedAccessKindsAtServer();
	
EndProcedure

#EndRegion

#Region Private

// OnOpen event handler continuation.
&AtClient
Procedure OnOpenAfterAdministratorProfileInstallationConfirmation(Response, Context) Export
	
	If Response = DialogReturnCode.Yes Then
		AnswerToQuestionOnOpenForm = "SetAdministratorProfile";
	Else
		AnswerToQuestionOnOpenForm = "SetReadOnly";
	EndIf;
	
	Open();
	
EndProcedure

// OnOpen event handler continuation.
&AtClient
Procedure OnOpenAfterAccessKindUpdateConfirmation(Response, Context) Export
	
	If Response = DialogReturnCode.Yes Then
		AnswerToQuestionOnOpenForm = "RefreshAccessKindsContent";
	Else
		AnswerToQuestionOnOpenForm = "SetReadOnly";
	EndIf;
	
	Open();
	
EndProcedure

// The BeforeWrite event handler continuation.
&AtClient
Procedure BeforeWriteFollowUp(SaaSUserNewPassword, WriteParameters) Export
	
	If SaaSUserNewPassword = Undefined Then
		Return;
	EndIf;
	
	ServiceUserPassword = SaaSUserNewPassword;
	
	Try
		Write(WriteParameters);
	Except
		ServiceUserPassword = Undefined;
		Raise;
	EndTry;
	
EndProcedure

// AfterWrite event handler continuation.
&AtClient
Procedure AfterWriteCompletion(WriteParameters) Export
	
	If WriteParameters.Property("WriteAndClose") Then
		AttachIdleHandler("CloseForm", 0.1, True);
	EndIf;
	
EndProcedure

&AtClient
Procedure CloseForm()
	
	Close();
	
EndProcedure

&AtClient
Procedure IdleHandlerProfileOnChange()
	
	ProfileOnChangeAtServer();
	
EndProcedure

&AtServer
Procedure ProhibitAllChangesExceptMembers()
	
	Items.Description.ReadOnly          = True;
	Items.Parent.Visible                   = False;
	Items.Profile.ReadOnly               = True;
	Items.PersonalGroupProperties.Visible = False;
	Items.Comment.ReadOnly           = True;
	
EndProcedure

&AtServer
Procedure InitialSettingsOnReadAndCreate(CurrentObject)
	
	If CurrentObject.Ref = Catalogs.AccessGroups.Administrators Then
		ProhibitAllChangesExceptMembers();
		
		If Not Users.IsFullUser() Then
			ReadOnly = True;
			Items.FormWriteAndClose.Enabled = False;
		EndIf;
	Else
		If ValueIsFilled(CurrentObject.User) Then
			// Preparing for personal access group mode.
			AutoTitle = False;
			Title = AccessManagementInternalClientServer.PresentationAccessGroups(CurrentObject)
				+ " " + NStr("ru = '(Группа доступа)'; en = '(Access group)'; pl = '(Grupa dostępu)';de = '(Zugriffsgruppe)';ro = '(Grup de acces)';tr = '(Erişim grubu)'; es_ES = '(Grupo de acceso)'");
			
			Filter = New Structure("User", CurrentObject.User);
			FoundRows = CurrentObject.Users.FindRows(Filter);
			PersonalAccessUsage = FoundRows.Count() > 0;
		Else
			AutoTitle = True;
		EndIf;
		
		UserFilled = ValueIsFilled(CurrentObject.User);
		
		Items.Description.ReadOnly                 = UserFilled;
		Items.Parent.ReadOnly                     = UserFilled;
		Items.Profile.ReadOnly                      = UserFilled;
		Items.PersonalGroupProperties.Visible        = UserFilled;
		Items.GroupUsers.Visible                = NOT UserFilled;
		
		Items.UsersAndAccess.PagesRepresentation =
			?(UserFilled,
			  FormPagesRepresentation.None,
			  FormPagesRepresentation.TabsOnTop);
		
		Items.AccessKinds.TitleLocation =
			?(UserFilled,
			  FormItemTitleLocation.Top,
			  FormItemTitleLocation.None);
		
		Items.UserOwner.ReadOnly
			= AccessManagementInternal.SimplifiedAccessRightsSetupInterface();
		
		// Preparing to switch to the mode where an employee responsible for group members can edit users.
		If Not Users.IsFullUser() Then
			Items.Description.ReadOnly = True;
			Items.Parent.ReadOnly = True;
			Items.Profile.ReadOnly = True;
			Items.Access.ReadOnly = True;
			Items.EmployeeResponsible.ReadOnly = True;
			Items.Comment.ReadOnly = True;
		EndIf;
	EndIf;
	
	RefreshAccessKindsContent(True);
	
	// Preparing a user tree.
	UsersTree = GroupUsers.GetItems();
	UsersTree.Clear();
	For each TSRow In CurrentObject.Users Do
		UsersTree.Add().User = TSRow.User;
	EndDo;
	RefreshGroupsUsers();
	
	UpdateCommentPicture(Items.CommentPage, Object.Comment);
	
EndProcedure

&AtServer
Procedure ProfileOnChangeAtServer()
	
	UpdateAssignment();
	DeleteNonTypicalUsers();
	RefreshAccessKindsContent();
	AccessManagementInternalClientServer.FillAccessKindsPropertiesInForm(ThisObject);
	
EndProcedure

&AtServer
Procedure UpdateAssignment()
	
	Purpose.Clear();
	AssignmentPresentation = "";
	For Each Member In Object.Profile.Purpose Do
		If Member.UsersType <> Undefined Then
			Purpose.Add(Member.UsersType);
			TypePresentation = Member.UsersType.Metadata().Synonym;
			AssignmentPresentation = ?(IsBlankString(AssignmentPresentation),
				TypePresentation, AssignmentPresentation + ", " + TypePresentation);
		EndIf;
	EndDo;
	Items.Users.ToolTip = NStr("ru = 'Допустимые участники:'; en = 'Allowed members:'; pl = 'Dozwoleni członkowie:';de = 'Zulässige Teilnehmer:';ro = 'Membrii permiși:';tr = 'İzin verilen üyeler:'; es_ES = 'Participantes permitidos:'") + " " + AssignmentPresentation;
	
EndProcedure

&AtServer
Procedure DeleteNonTypicalUsers()
	
	TypesArray = New Array;
	For Each Item In Purpose Do
		TypesArray.Add(TypeOf(Item.Value));
	EndDo;
	
	UsersTree = GroupUsers.GetItems();
	
	Index = UsersTree.Count() - 1;
	
	While Index >= 0 Do
		
		TreeRow = UsersTree.Get(Index);
		DeleteRow = False;
		
		If (TypeOf(TreeRow.User) = Type("CatalogRef.Users")
			Or TypeOf(TreeRow.User) = Type("CatalogRef.UserGroups"))
			AND TypesArray.Find(Type("CatalogRef.Users")) = Undefined Then
			
			DeleteRow = True;
			
		ElsIf TypeOf(TreeRow.User) = Type("CatalogRef.ExternalUsers")
			AND TypesArray.Find(TypeOf(TreeRow.User.AuthorizationObject)) = Undefined Then
			
			UsersTree.Delete(Index);
			
		ElsIf TypeOf(TreeRow.User) = Type("CatalogRef.ExternalUsersGroups") Then
			
			For Each GroupMember In TreeRow.GetItems() Do
				
				If TypesArray.Find(TypeOf(GroupMember.User.AuthorizationObject)) = Undefined Then
					DeleteRow = True;
					Break;
				EndIf;
				
			EndDo;
			
		EndIf;
		
		If DeleteRow Then
			UsersTree.Delete(Index);
		EndIf;
		
		Index = Index - 1;
		
	EndDo;
	
EndProcedure

&AtServer
Procedure RefreshAccessKindsContent(Val OnReadAtServer = False)
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	ProfileAccessKinds.AccessKind,
	|	ProfileAccessKinds.PresetAccessKind,
	|	ProfileAccessKinds.AllAllowed
	|FROM
	|	Catalog.AccessGroupProfiles.AccessKinds AS ProfileAccessKinds
	|WHERE
	|	ProfileAccessKinds.Ref = &Ref
	|	AND NOT ProfileAccessKinds.PresetAccessKind";
	
	Query.SetParameter("Ref", Object.Profile);
	
	SetPrivilegedMode(True);
	ProfileAccessKinds = Query.Execute().Unload();
	SetPrivilegedMode(False);
	
	AccessKindsContentChanged = False;
	
	// Adding missing access kinds.
	Index = ProfileAccessKinds.Count() - 1;
	While Index >= 0 Do
		Row = ProfileAccessKinds[Index];
		
		Filter = New Structure("AccessKind", Row.AccessKind);
		AccessKindProperties = AccessManagementInternal.AccessKindProperties(Row.AccessKind);
		
		If AccessKindProperties = Undefined Then
			ProfileAccessKinds.Delete(Row);
		
		ElsIf Object.AccessKinds.FindRows(Filter).Count() = 0 Then
			AccessKindsContentChanged = True;
			
			If OnReadAtServer Then
				Break;
			Else
				NewRow = Object.AccessKinds.Add();
				NewRow.AccessKind   = Row.AccessKind;
				NewRow.AllAllowed = Row.AllAllowed;
			EndIf;
		EndIf;
		Index = Index - 1;
	EndDo;
	
	// Deleting unused access kinds.
	Index = Object.AccessKinds.Count() - 1;
	While Index >= 0 Do
		
		AccessKind = Object.AccessKinds[Index].AccessKind;
		Filter = New Structure("AccessKind", AccessKind);
		AccessKindProperties = AccessManagementInternal.AccessKindProperties(AccessKind);
		
		If AccessKindProperties = Undefined
		 OR ProfileAccessKinds.FindRows(Filter).Count() = 0 Then
			
			AccessKindsContentChanged = True;
			If OnReadAtServer Then
				Break;
			Else
				Object.AccessKinds.Delete(Index);
				For each CollectionItem In Object.AccessValues.FindRows(Filter) Do
					Object.AccessValues.Delete(CollectionItem);
				EndDo;
			EndIf;
		EndIf;
		Index = Index - 1;
	EndDo;
	
	Modified = Modified
		OR AccessKindsContentChanged AND NOT OnReadAtServer;
	
	// Selecting a check box for prompting the user if they want to update the access kind content.
	If OnReadAtServer
	     AND NOT Object.Ref.IsEmpty() // It is new.
	     AND AccessKindsContentChanged
	     AND Users.IsFullUser() // Only the administrator can update access kinds.
	     AND Common.ObjectAttributeValue(Object.Ref, "Profile") = Object.Profile Then
	     
		AccessKindsOnReadChanged = True;
	EndIf;
	
	Items.Access.Enabled = Object.AccessKinds.Count() > 0;
	
	// Setting access kind order by profile.
	If NOT AccessKindsOnReadChanged Then
		For each TSRow In ProfileAccessKinds Do
			Filter = New Structure("AccessKind", TSRow.AccessKind);
			Index = Object.AccessKinds.IndexOf(Object.AccessKinds.FindRows(Filter)[0]);
			Object.AccessKinds.Move(Index, ProfileAccessKinds.IndexOf(TSRow) - Index);
		EndDo;
	EndIf;
	
	AccessManagementInternalClientServer.FillAccessKindsPropertiesInForm(ThisObject);
	
EndProcedure

&AtServer
Procedure ShowUnusedAccessKindsAtServer()
	
	AccessManagementInternal.RefreshUnusedAccessKindsRepresentation(ThisObject);
	
EndProcedure

&AtClient
Procedure ShowTypeSelectionUsersOrExternalUsers(ContinuationHandler)
	
	ExternalUsersSelectionAndPickup = False;
	
	If Object.Ref = PredefinedValue("Catalog.AccessGroups.Administrators") Then
		ExecuteNotifyProcessing(ContinuationHandler, ExternalUsersSelectionAndPickup);
		Return;
	EndIf;
	
	If Purpose.Count() <> 0 Then
		
		If Purpose.FindByValue(PredefinedValue("Catalog.Users.EmptyRef")) <> Undefined Then
			
			If Purpose.Count() <> 1 Then
				
				If UseExternalUsers Then
					
					UserTypesList.ShowChooseItem(
						New NotifyDescription(
						"ShowTypeSelectionUsersOrExternalUsersCompletion",
						ThisObject,
						ContinuationHandler),
						NStr("ru = 'Выбор типа данных'; en = 'Select data type'; pl = 'Wybierz typ danych';de = 'Wählen Sie den Datentyp aus';ro = 'Select data type';tr = 'Veri türünü seçin'; es_ES = 'Seleccionar el tipo de datos'"),
						UserTypesList[0]);
				Else
					ExecuteNotifyProcessing(ContinuationHandler, ExternalUsersSelectionAndPickup);
				EndIf;
				
				Return;
				
			EndIf;
			
		Else // for external users only.
			
			ExternalUsersSelectionAndPickup = True;
			
		EndIf;
		
	EndIf;
	
	ExecuteNotifyProcessing(ContinuationHandler, ExternalUsersSelectionAndPickup);
	
EndProcedure

&AtClient
Procedure ShowTypeSelectionUsersOrExternalUsersCompletion(SelectedItem, ContinuationHandler) Export
	
	If SelectedItem <> Undefined Then
		ExternalUsersSelectionAndPickup =
			SelectedItem.Value = Type("CatalogRef.ExternalUsers");
		
		ExecuteNotifyProcessing(ContinuationHandler, ExternalUsersSelectionAndPickup);
	Else
		ExecuteNotifyProcessing(ContinuationHandler, Undefined);
	EndIf;
	
EndProcedure

&AtClient
Procedure SelectPickUsers(Select)
	
	CurrentUser = ?(Items.Users.CurrentData = Undefined,
		Undefined, Items.Users.CurrentData.User);
	
	If NOT Select
	   AND ValueIsFilled(CurrentUser)
	   AND (    TypeOf(CurrentUser) = Type("CatalogRef.Users")
	      OR TypeOf(CurrentUser) = Type("CatalogRef.UserGroups") ) Then
	
		ExternalUsersSelectionAndPickup = False;
	
	ElsIf NOT Select
	        AND UseExternalUsers
	        AND ValueIsFilled(CurrentUser)
	        AND (    TypeOf(CurrentUser) = Type("CatalogRef.ExternalUsers")
	           OR TypeOf(CurrentUser) = Type("CatalogRef.ExternalUsersGroups") ) Then
	
		ExternalUsersSelectionAndPickup = True;
	Else
		ShowTypeSelectionUsersOrExternalUsers(
			New NotifyDescription("SelectPickUsersCompletion", ThisObject, Select));
		Return;
	EndIf;
	
	SelectPickUsersCompletion(ExternalUsersSelectionAndPickup, Select);
	
EndProcedure

&AtClient
Procedure SelectPickUsersCompletion(ExternalUsersSelectionAndPickup, Select) Export
	
	If ExternalUsersSelectionAndPickup = Undefined Then
		Return;
	EndIf;
	
	FormParameters = New Structure;
	FormParameters.Insert("ChoiceMode", True);
	FormParameters.Insert("CurrentRow", ?(
		Items.Users.CurrentData = Undefined,
		Undefined,
		Items.Users.CurrentData.User));
	
	If Select Then
		FormParameters.Insert("CloseOnChoice", False);
		FormParameters.Insert("MultipleChoice", True);
		FormParameters.Insert("AdvancedPick", True);
		FormParameters.Insert("ExtendedPickFormParameters", ExtendedPickFormParameters());
	ElsIf Object.Ref <> PredefinedValue("Catalog.AccessGroups.Administrators") Then
		If ExternalUsersSelectionAndPickup Then
			FormParameters.Insert(";SelectExternalUsersGroups", True);
		Else
			FormParameters.Insert("UsersGroupsSelection", True);
		EndIf;
	EndIf;
	
	If ExternalUsersSelectionAndPickup Then
		
		FormParameters.Insert("Purpose", Purpose.UnloadValues());
		
		If Not UseExternalUsers Then
			ShowMessageBox(, NStr("ru = 'Ведение внешних пользователей отключено в настройках программы.'; en = 'External user management is disabled in the application settings.'; pl = 'Prowadzenie użytkowników zewnętrznych zostało wyłączone w ustawieniach programu.';de = 'Die externe Benutzerverwaltung ist in den Programmeinstellungen deaktiviert.';ro = 'Ținerea utilizatorilor externi este dezactivată în setările programului.';tr = 'Harici kullanıcıların tutulması program ayarlarında devre dışı bırakıldı.'; es_ES = 'El seguimiento de los usuarios externos está desactivado en los ajustes del programa.'"));
		ElsIf CatalogExternalUsersAvailable Then
			OpenForm("Catalog.ExternalUsers.ChoiceForm", FormParameters, Items.Users);
		Else
			ShowMessageBox(, NStr("ru = 'Недостаточно прав для выбора внешних пользователей.'; en = 'Insufficient rights to select external users.'; pl = 'Niewystarczające uprawnienia do wyboru użytkowników zewnętrznych.';de = 'Unzureichende Rechte zur Auswahl externer Benutzer.';ro = 'Drepturile insuficiente pentru selectarea utilizatorilor externi.';tr = 'Harici kullanıcıları seçmek için yetersiz hak.'; es_ES = 'Insuficientes derechos para seleccionar usuarios externos.'"));
		EndIf;
	Else
		OpenForm("Catalog.Users.ChoiceForm", FormParameters, Items.Users);
	EndIf;
	
EndProcedure

&AtServer
Function ExtendedPickFormParameters()
	
	CollectionItems = GroupUsers.GetItems();
	
	SelectedUsers = New ValueTable;
	SelectedUsers.Columns.Add("User");
	SelectedUsers.Columns.Add("PictureNumber");
	
	For each Item In CollectionItems Do
		
		SelectedUsersRow = SelectedUsers.Add();
		SelectedUsersRow.User = Item.User;
		SelectedUsersRow.PictureNumber = Item.PictureNumber;
		
	EndDo;
	
	PickFormHeader = NStr("ru = 'Подбор участников группы доступа'; en = 'Select access group members'; pl = 'Wybierz członków grupy dostępu';de = 'Wählen Sie Zugriffsgruppenmitglieder aus';ro = 'Selectați membrii grupului de acces';tr = 'Erişim grubu üyelerini seç.'; es_ES = 'Seleccionar miembros del grupo de acceso'");
	ExtendedPickFormParameters = New Structure;
	ExtendedPickFormParameters.Insert("PickFormHeader", PickFormHeader);
	ExtendedPickFormParameters.Insert("SelectedUsers", SelectedUsers);
	If Object.Ref = PredefinedValue("Catalog.AccessGroups.Administrators") Then
		ExtendedPickFormParameters.Insert("CannotPickGroups");
	EndIf;
	
	StorageAddress = PutToTempStorage(ExtendedPickFormParameters);
	Return StorageAddress;
	
EndFunction

&AtServer
Procedure RefreshGroupsUsers(RowID = Undefined,
                                     ModifiedRows = Undefined)
	
	SetPrivilegedMode(True);
	ModifiedRows = New Array;
	
	If RowID = Undefined Then
		CollectionItems = GroupUsers.GetItems();
		
	ElsIf TypeOf(RowID) = Type("Array") Then
		CollectionItems = New Array;
		For each ID In RowID Do
			CollectionItems.Add(GroupUsers.FindByID(ID));
		EndDo;
	Else
		CollectionItems = New Array;
		CollectionItems.Add(GroupUsers.FindByID(RowID));
	EndIf;
	
	UserGroupMembers = New Array;
	For each Item In CollectionItems Do
		
		If TypeOf(Item.User) = Type("CatalogRef.UserGroups")
		 OR TypeOf(Item.User) = Type("CatalogRef.ExternalUsersGroups") Then
		
			UserGroupMembers.Add(Item.User);
		EndIf;
	EndDo;
	
	Query = New Query;
	Query.SetParameter("UserGroupMembers", UserGroupMembers);
	Query.Text =
	"SELECT
	|	UserGroupCompositions.UsersGroup,
	|	UserGroupCompositions.User
	|FROM
	|	InformationRegister.UserGroupCompositions AS UserGroupCompositions
	|WHERE
	|	UserGroupCompositions.UsersGroup IN(&UserGroupMembers)
	|	AND UserGroupCompositions.User.Invalid <> TRUE";
	
	GroupsUsers = Query.Execute().Unload();
	GroupsUsers.Indexes.Add("UsersGroup");
	
	For each Item In CollectionItems Do
		Item.Ref = Item.User;
		
		If TypeOf(Item.User) = Type("CatalogRef.UserGroups")
		 OR TypeOf(Item.User) = Type("CatalogRef.ExternalUsersGroups") Then
		
			// Filling group users.
			OldUsers = Item.GetItems();
			Filter = New Structure("UsersGroup", Item.User);
			NewUsers = GroupsUsers.FindRows(Filter);
			
			HasChanges = False;
			
			If OldUsers.Count() <> NewUsers.Count() Then
				OldUsers.Clear();
				For each Row In NewUsers Do
					NewItem = OldUsers.Add();
					NewItem.Ref       = Row.User;
					NewItem.User = Row.User;
				EndDo;
				HasChanges = True;
			Else
				Index = 0;
				For each Row In OldUsers Do
					
					If Row.Ref       <> NewUsers[Index].User
					 OR Row.User <> NewUsers[Index].User Then
						
						Row.Ref       = NewUsers[Index].User;
						Row.User = NewUsers[Index].User;
						HasChanges = True;
					EndIf;
					Index = Index + 1;
				EndDo;
			EndIf;
			
			If HasChanges Then
				ModifiedRows.Add(Item.GetID());
			EndIf;
		EndIf;
	EndDo;
	
	Users.FillUserPictureNumbers(
		GroupUsers, "Ref", "PictureNumber", RowID, True);
	
	// Setting a tree presentation.
	HasTree = False;
	For each Item In GroupUsers.GetItems() Do
		If Item.GetItems().Count() > 0 Then
			HasTree = True;
			Break;
		EndIf;
	EndDo;
	Items.Users.Representation = ?(HasTree, TableRepresentation.Tree, TableRepresentation.List);
	
EndProcedure

&AtServer
Procedure RestoreObjectWithoutGroupMembers(CurrentObject)
	
	SetPrivilegedMode(True);
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	AccessGroups.DeletionMark AS DeletionMark,
	|	AccessGroups.Predefined AS Predefined,
	|	AccessGroups.Parent AS Parent,
	|	AccessGroups.IsFolder AS IsFolder,
	|	AccessGroups.Description AS Description,
	|	AccessGroups.Profile AS Profile,
	|	AccessGroups.EmployeeResponsible AS EmployeeResponsible,
	|	AccessGroups.User AS User,
	|	AccessGroups.Comment AS Comment
	|FROM
	|	Catalog.AccessGroups AS AccessGroups
	|WHERE
	|	AccessGroups.Ref = &Ref
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	AccessGroupsAccessKinds.AccessKind AS AccessKind,
	|	AccessGroupsAccessKinds.AllAllowed AS AllAllowed
	|FROM
	|	Catalog.AccessGroups.AccessKinds AS AccessGroupsAccessKinds
	|WHERE
	|	AccessGroupsAccessKinds.Ref = &Ref
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	AccessGroupsAccessValues.AccessKind AS AccessKind,
	|	AccessGroupsAccessValues.AccessValue AS AccessValue
	|FROM
	|	Catalog.AccessGroups.AccessValues AS AccessGroupsAccessValues
	|WHERE
	|	AccessGroupsAccessValues.Ref = &Ref";
	
	Query.SetParameter("Ref", CurrentObject.Ref);
	QueriesResults = Query.ExecuteBatch();
	
	// Restoring attributes.
	FillPropertyValues(CurrentObject, QueriesResults[0].Unload()[0]);
	
	// Restoring the AccessKinds tabular section.
	CurrentObject.AccessKinds.Load(QueriesResults[1].Unload());
	
	// Restoring the AccessValues tabular section.
	CurrentObject.AccessValues.Load(QueriesResults[2].Unload());
	
EndProcedure

&AtServer
Function SpecifyMessage(Row, Value)
	
	Return StrReplace(Row, "%2", Value);
	
EndFunction

&AtClientAtServerNoContext
Procedure UpdateCommentPicture(Item, Comment)
	
	Item.Picture = CommonClientServer.CommentPicture(Comment);
	
EndProcedure

#EndRegion
