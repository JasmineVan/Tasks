﻿///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Public

////////////////////////////////////////////////////////////////////////////////
// Main procedures and functions.

// Returns the current user or the current external user, depending on which one has signed in.
// 
//  It is recommended that you use the function in a script fragment that supports both sign in options.
//
// Returns:
//  CatalogRef.Users, CatalogRef.ExternalUsers - a user or an external user.
//    
//
Function AuthorizedUser() Export
	
	Return UsersInternal.AuthorizedUser();
	
EndFunction

// Returns the current user.
//  It is recommended that you use the function in a script fragment that does not support external users.
//
//  If the current user is external, throws an exception.
//
// Returns:
//  CatalogRef.Users - a user.
//
Function CurrentUser() Export
	
	Return UsersInternalClientServer.CurrentUser(AuthorizedUser());
	
EndFunction

// Returns True if the current user is external.
//
// Returns:
//  Boolean - True if the current user is external.
//
Function IsExternalUserSession() Export
	
	Return UsersInternalCached.IsExternalUserSession();
	
EndFunction

// Checks whether the current user or the specified user has full access rights.
// 
// A user is a full access user:
// a) who has the FullAccess role and the role for system administration (if 
//    CheckSystemAdministrationRights = True), and if the list of infobase users is not empty;
// b) if the infobase user list is empty and the main role of configuration is not specified or is 
//    FullAccess.
//
// Parameters:
//  User - Undefined - checking the current infobase user.
//               - CatalogRef.Users, CatalogRef.ExternalUsers - a searching for infobase user by 
//                    UUID set in the attribute
//                    IBUserID. Returns False if the infobase user is not found.
//               - InfobaseUser - checks the infobase user that is passed to the function.
//
//  CheckSystemAdministrationRights - Boolean - if True, checks whether the user has the 
//                 administrative role.
//
//  ForPrivilegedMode - Boolean - if True, the function returns True for the current user (provided 
//                 that privileged mode is set).
//
// Returns:
//  Boolean - if True, the user has full access rights.
//
Function IsFullUser(User = Undefined,
                                    CheckSystemAdministrationRights = False,
                                    ForPrivilegedMode = True) Export
	
	PrivilegedModeSet = PrivilegedMode();
	
	SetPrivilegedMode(True);
	IBUserProperies = CheckedIBUserProperties(User);
	
	If IBUserProperies = Undefined Then
		Return False;
	EndIf;
	
	CheckFullAccessRole = Not CheckSystemAdministrationRights;
	CheckSystemAdministratorRole = CheckSystemAdministrationRights;
	
	If Not IBUserProperies.IsCurrentIBUser Then
		Roles = IBUserProperies.InfobaseUser.Roles;
		
		// Checking roles for the saved infobase user if the user to be checked is not the current one.
		If CheckFullAccessRole
		   AND Not Roles.Contains(Metadata.Roles.FullRights) Then
			Return False;
		EndIf;
		
		If CheckSystemAdministratorRole
		   AND Not Roles.Contains(Metadata.Roles.SystemAdministrator) Then
			Return False;
		EndIf;
		
		Return True;
	EndIf;
	
	If ForPrivilegedMode AND PrivilegedModeSet Then
		Return True;
	EndIf;
	
	If StandardSubsystemsCached.PrivilegedModeSetOnStart() Then
		// User has full access rights if the client application runs with the UsePrivilegedMode parameter 
		// (provided that privileged mode is set).
		Return True;
	EndIf;
	
	If Not ValueIsFilled(IBUserProperies.Name) AND Metadata.DefaultRoles.Count() = 0 Then
		// If the default roles collection is empty and the user is not specified, the user has full access 
		// rights (as in the privileged mode).
		Return True;
	EndIf;
	
	If Not ValueIsFilled(IBUserProperies.Name)
	   AND PrivilegedModeSet
	   AND IBUserProperies.AdministrationRight Then
		// If the user is not specified and has the Administration right and privileged mode is set, the 
		// user has full access rights.
		// 
		Return True;
	EndIf;
	
	// Checking roles of the current infobase user (the current session roles are checked instead of the 
	// user roles that are saved to the infobase).
	If CheckFullAccessRole
	   AND Not IBUserProperies.RoleAvailableFullAccess Then // Do not change to RolesAvailable.
		Return False;
	EndIf;
	
	If CheckSystemAdministratorRole
	   AND Not IBUserProperies.SystemAdministratorRoleAvailable Then // Do not change to RolesAvailable.
		Return False;
	EndIf;
	
	Return True;
	
EndFunction

// Returns True if at least one of the specified roles is available for the user, or the user has 
// full access rights.
//
// Parameters:
//  RolesNames - String - names of roles whose availability is checked, separated by commas.
//
//  User - Undefined - checking the current infobase user.
//               - CatalogRef.Users, CatalogRef.ExternalUsers - a searching for infobase user by 
//                    UUID set in the attribute.
//                    IBUserID. Returns False if the infobase user is not found.
//               - InfobaseUser - checks the infobase user that is passed to the function.
//
//  ForPrivilegedMode - Boolean - if True, the function returns True for the current user (provided 
//                 that privileged mode is set).
//
// Returns:
//  Boolean - True if at least one of the roles is available, or the 
//           InfobaseUserWithFullAccess(User) function returns True.
//
Function RolesAvailable(RolesNames,
                     User = Undefined,
                     ForPrivilegedMode = True) Export
	
	SystemAdministratorRole = IsFullUser(User, True, ForPrivilegedMode);
	FullAccessRole          = IsFullUser(User, False,   ForPrivilegedMode);
	
	If SystemAdministratorRole AND FullAccessRole Then
		Return True;
	EndIf;
	
	RolesNamesArray = StrSplit(RolesNames, ",", False);
	
	SystemAdministratorRoleRequired = False;
	RolesAssignment = UsersInternalCached.RolesAssignment();
	
	For Each RoleName In RolesNamesArray Do
		If RolesAssignment.ForSystemAdministratorsOnly.Get(RoleName) <> Undefined Then
			SystemAdministratorRoleRequired = True;
			Break;
		EndIf;
	EndDo;
	
	If SystemAdministratorRole AND    SystemAdministratorRoleRequired
	 Or FullAccessRole          AND Not SystemAdministratorRoleRequired Then
		Return True;
	EndIf;
	
	SetPrivilegedMode(True);
	IBUserProperies = CheckedIBUserProperties(User);
	
	If IBUserProperies = Undefined Then
		Return False;
	EndIf;
	
	If IBUserProperies.IsCurrentIBUser Then
		For Each RoleName In RolesNamesArray Do
			If IsInRole(TrimAll(RoleName)) Then // Do not change to RolesAvailable.
				Return True;
			EndIf;
		EndDo;
	Else
		Roles = IBUserProperies.InfobaseUser.Roles;
		For Each RoleName In RolesNamesArray Do
			If Roles.Contains(Metadata.Roles.Find(TrimAll(RoleName))) Then
				Return True;
			EndIf;
		EndDo;
	EndIf;
	
	Return False;
	
EndFunction

// Checks whether an infobase user has at least one authentication kind.
//
// Parameters:
//  IBUserDetails - UUID - an infobase user ID.
//                         - Structure - contains 3 authentication properties:
//                             * StandardAuthentication - Boolean - 1C:Enterprise authentication.
//                             * OSAuthentication - Boolean - operating system authentication.
//                             * OpenIDAuthentication - Boolean - OpenID authentication.
//                         - InfobaseUser - an infobase user.
//                         - CatalogRef.Users - a user.
//                         - CatalogRef.ExternalUsers - an external user.
//
// Returns:
//  Boolean - True if at least one authentication property is True.
//
Function CanSignIn(IBUserDetails) Export
	
	SetPrivilegedMode(True);
	
	UUID = Undefined;
	
	If TypeOf(IBUserDetails) = Type("CatalogRef.Users")
	 Or TypeOf(IBUserDetails) = Type("CatalogRef.ExternalUsers") Then
		
		UUID = Common.ObjectAttributeValue(
			IBUserDetails, "IBUserID");
		
		If TypeOf(UUID) <> Type("UUID") Then
			Return False;
		EndIf;
		
	ElsIf TypeOf(IBUserDetails) = Type("UUID") Then
		UUID = IBUserDetails;
	EndIf;
	
	If UUID <> Undefined Then
		InfobaseUser = InfoBaseUsers.FindByUUID(UUID);
		
		If InfobaseUser = Undefined Then
			Return False;
		EndIf;
	Else
		InfobaseUser = IBUserDetails;
	EndIf;
	
	Return InfobaseUser.StandardAuthentication
		OR InfobaseUser.OSAuthentication
		OR InfobaseUser.OpenIDAuthentication;
	
EndFunction

////////////////////////////////////////////////////////////////////////////////
// Procedures and functions used in managed forms.

// Returns a list of users, user groups, external users, and external user groups.
// 
// The function is used in the TextEditEnd and AutoComplete event handlers.
//
// Parameters:
//  Text         - String - characters entered by the user.
//
//  IncludeGroups - Boolean - if True, includes user groups and external user groups in the result.
//                  Ignored if the UseUserGroups functional option is disabled.
//
//  IncludeExternalUsers - Undefined, Boolean - if Undefined, takes the return value of the 
//                  ExternalUsers.EnableExternalUsers function.
//
//  NoUsers - Boolean - if True, the Users catalog items are excluded from the result.
//                  
//
// Returns:
//  ValueList - the list of values and user presentations that meet the parameters.
//
Function GenerateUserSelectionData(Val Text,
                                             Val IncludeGroups = True,
                                             Val IncludeExternalUsers = Undefined,
                                             Val NoUsers = False) Export
	
	IncludeGroups = IncludeGroups AND GetFunctionalOption("UseUserGroups");
	
	Query = New Query;
	Query.SetParameter("Text", Text + "%");
	Query.SetParameter("IncludeGroups", IncludeGroups);
	Query.Text = 
	"SELECT ALLOWED
	|	VALUE(Catalog.Users.EmptyRef) AS Ref,
	|	"""" AS Description,
	|	-1 AS PictureNumber
	|WHERE
	|	FALSE";
	
	If NOT NoUsers Then
		QueryText =
		"SELECT
		|	Users.Ref,
		|	Users.Description,
		|	1 AS PictureNumber
		|FROM
		|	Catalog.Users AS Users
		|WHERE
		|	Users.Description LIKE &Text
		|	AND Users.Invalid = FALSE
		|	AND Users.Internal = FALSE
		|
		|UNION ALL
		|
		|SELECT
		|	UserGroups.Ref,
		|	UserGroups.Description,
		|	3
		|FROM
		|	Catalog.UserGroups AS UserGroups
		|WHERE
		|	&IncludeGroups
		|	AND UserGroups.Description LIKE &Text";
		
		Query.Text = Query.Text + " UNION ALL " + QueryText;
	EndIf;
	
	If TypeOf(IncludeExternalUsers) <> Type("Boolean") Then
		IncludeExternalUsers = ExternalUsers.UseExternalUsers();
	EndIf;
	IncludeExternalUsers = IncludeExternalUsers
	                            AND AccessRight("Read", Metadata.Catalogs.ExternalUsers);
	
	If IncludeExternalUsers Then
		QueryText =
		"SELECT
		|	ExternalUsers.Ref,
		|	ExternalUsers.Description,
		|	7 AS PictureNumber
		|FROM
		|	Catalog.ExternalUsers AS ExternalUsers
		|WHERE
		|	ExternalUsers.Description LIKE &Text
		|	AND ExternalUsers.Invalid = FALSE
		|
		|UNION ALL
		|
		|SELECT
		|	ExternalUsersGroups.Ref,
		|	ExternalUsersGroups.Description,
		|	9
		|FROM
		|	Catalog.ExternalUsersGroups AS ExternalUsersGroups
		|WHERE
		|	&IncludeGroups
		|	AND ExternalUsersGroups.Description LIKE &Text";
		
		Query.Text = Query.Text + " UNION ALL " + QueryText;
	EndIf;
	
	Selection = Query.Execute().Select();
	
	ChoiceData = New ValueList;
	
	While Selection.Next() Do
		ChoiceData.Add(Selection.Ref, Selection.Description, , PictureLib["UserState" + Format(Selection.PictureNumber + 1, "ND=2; NLZ=; NG=")]);
	EndDo;
	
	Return ChoiceData;
	
EndFunction

// Populates user picture numbers, user groups, external users, and external user groups in all rows 
// or given rows (see the RowID parameter) of a TableOrTree collection.
// 
// Parameters:
//  TableOrTree - FormDataCollection, FormDataTree - the collection to populate.
//  UserFieldName   - String - the name of the TableOrTree collection row that contains a reference 
//                                   to a user, user group, external user, or external user group.
//                                   It is the input parameter for the picture number.
//  PictureNumberFieldName - String - name of the column in the TableOrTree collection with the 
//                                   picture number that needs to be filled.
//  RowID  - Undefined, Number - ID of the row (not a sequence number) must be filled (child rows of 
//                                   the tree will be filled as well), if Undefined, the pictures 
//                                   will be filled in every row.
//  ProcessSecondAndThirdLevelHierarchy - Boolean - if True, and the collection of the FormDataTree 
//                                 type is specified in the TableOrTree parameter, the fields will 
//                                 be filled up to the fourth tree level inclusive, otherwise, the 
//                                 fields will be filled only at the first and second tree level.
//
Procedure FillUserPictureNumbers(Val TableOrTree,
                                               Val UserFieldName,
                                               Val PictureNumberFieldName,
                                               Val RowID = Undefined,
                                               Val ProcessSecondAndThirdLevelHierarchy = False) Export
	
	SetPrivilegedMode(True);
	
	If RowID = Undefined Then
		RowsArray = Undefined;
		
	ElsIf TypeOf(RowID) = Type("Array") Then
		RowsArray = New Array;
		For each ID In RowID Do
			RowsArray.Add(TableOrTree.FindByID(ID));
		EndDo;
	Else
		RowsArray = New Array;
		RowsArray.Add(TableOrTree.FindByID(RowID));
	EndIf;
	
	If TypeOf(TableOrTree) = Type("FormDataTree") Then
		If RowsArray = Undefined Then
			RowsArray = TableOrTree.GetItems();
		EndIf;
		UsersTable = New ValueTable;
		UsersTable.Columns.Add(UserFieldName,
			Metadata.InformationRegisters.UserGroupCompositions.Dimensions.UsersGroup.Type);
		For Each Row In RowsArray Do
			UsersTable.Add()[UserFieldName] = Row[UserFieldName];
			If ProcessSecondAndThirdLevelHierarchy Then
				For each Row2 In Row.GetItems() Do
					UsersTable.Add()[UserFieldName] = Row2[UserFieldName];
					For each Row3 In Row2.GetItems() Do
						UsersTable.Add()[UserFieldName] = Row3[UserFieldName];
					EndDo;
				EndDo;
			EndIf;
		EndDo;
	ElsIf TypeOf(TableOrTree) = Type("FormDataCollection") Then
		If RowsArray = Undefined Then
			RowsArray = TableOrTree;
		EndIf;
		UsersTable = New ValueTable;
		UsersTable.Columns.Add(UserFieldName,
			Metadata.InformationRegisters.UserGroupCompositions.Dimensions.UsersGroup.Type);
		For Each Row In RowsArray Do
			UsersTable.Add()[UserFieldName] = Row[UserFieldName];
		EndDo;
	ElsIf TypeOf(TableOrTree) = Type("Array") Then
		RowsArray = TableOrTree;
		UsersTable = New ValueTable;
		UsersTable.Columns.Add(UserFieldName,
			Metadata.InformationRegisters.UserGroupCompositions.Dimensions.UsersGroup.Type);
		For Each Row In TableOrTree Do
			UsersTable.Add()[UserFieldName] = Row[UserFieldName];
		EndDo;
	Else
		If RowsArray = Undefined Then
			RowsArray = TableOrTree;
		EndIf;
		UsersTable = TableOrTree.Unload(RowsArray, UserFieldName);
	EndIf;
	
	Query = New Query(StrReplace(
	"SELECT DISTINCT
	|	Users.UserFieldName AS User
	|INTO Users
	|FROM
	|	&Users AS Users
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Users.User,
	|	CASE
	|		WHEN Users.User = UNDEFINED
	|			THEN -1
	|		WHEN VALUETYPE(Users.User) = TYPE(Catalog.Users)
	|			THEN CASE
	|					WHEN CAST(Users.User AS Catalog.Users).DeletionMark
	|						THEN 0
	|					ELSE 1
	|				END
	|		WHEN VALUETYPE(Users.User) = TYPE(Catalog.UserGroups)
	|			THEN CASE
	|					WHEN CAST(Users.User AS Catalog.UserGroups).DeletionMark
	|						THEN 2
	|					ELSE 3
	|				END
	|		WHEN VALUETYPE(Users.User) = TYPE(Catalog.ExternalUsers)
	|			THEN CASE
	|					WHEN CAST(Users.User AS Catalog.ExternalUsers).DeletionMark
	|						THEN 6
	|					ELSE 7
	|				END
	|		WHEN VALUETYPE(Users.User) = TYPE(Catalog.ExternalUsersGroups)
	|			THEN CASE
	|					WHEN CAST(Users.User AS Catalog.ExternalUsersGroups).DeletionMark
	|						THEN 8
	|					ELSE 9
	|				END
	|		ELSE -2
	|	END AS PictureNumber
	|FROM
	|	Users AS Users", "UserFieldName", UserFieldName));
	Query.SetParameter("Users", UsersTable);
	PicturesNumbers = Query.Execute().Unload();
	
	For Each Row In RowsArray Do
		FoundRow = PicturesNumbers.Find(Row[UserFieldName], "User");
		Row[PictureNumberFieldName] = ?(FoundRow = Undefined, -2, FoundRow.PictureNumber);
		If ProcessSecondAndThirdLevelHierarchy Then
			For each Row2 In Row.GetItems() Do
				FoundRow = PicturesNumbers.Find(Row2[UserFieldName], "User");
				Row2[PictureNumberFieldName] = ?(FoundRow = Undefined, -2, FoundRow.PictureNumber);
				For each Row3 In Row2.GetItems() Do
					FoundRow = PicturesNumbers.Find(Row3[UserFieldName], "User");
					Row3[PictureNumberFieldName] = ?(FoundRow = Undefined, -2, FoundRow.PictureNumber);
				EndDo;
			EndDo;
		EndIf;
	EndDo;
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Procedures and functions used for infobase update.

// The procedure is used for infobase update and initial filling. It does one of the following:.
// 1) Creates the first administrator and maps it to a new user or an existing item of the Users 
//    catalog.
// 2) Maps the administrator that is specified in the InfobaseUser parameter to a new user or an 
//    existing Users catalog item.
//
// Parameters:
//  IBUser - Undefined - create the first administrator if it is missing.
//                 - InfobaseUser is used for mapping an existing administrator to a new user or an 
//                   existing Users catalog item.
//                   
//
// Returns:
//  Undefined - the first administrator already exists.
//  CatalogRef.Users - a user in the directory, to which the created first administrator or the 
//                                  specified existing one is mapped.
//
Function CreateAdministrator(InfobaseUser = Undefined) Export
	
	If Not Common.SeparatedDataUsageAvailable() Then
		Raise NStr("ru = 'Справочник Пользователи недоступен в неразделенном режиме.'; en = 'The ""Users"" catalog is unavailable in shared mode.'; pl = 'Użytkownicy katalogu nie są dostępni w trybie spersonalizowanym.';de = 'Benutzerverzeichnis sind im ungeteilten Modus nicht verfügbar.';ro = 'Clasificatorul Utilizatori este inaccesibil în regim neseparat.';tr = 'Kullanıcı katalogu ayrılmamış modda kullanılamaz.'; es_ES = 'El catálogo Usuarios no está disponible en el modo no distribuido.'");
	EndIf;
	
	SetPrivilegedMode(True);
	
	// Adding administrator.
	If InfobaseUser = Undefined Then
		IBUsers = InfoBaseUsers.GetUsers();
		
		If IBUsers.Count() = 0 Then
			If Common.DataSeparationEnabled() Then
				Raise
					NStr("ru = 'Невозможно автоматически создать первого администратора области данных.'; en = 'Cannot automatically create the first administrator of the data area.'; pl = 'Nie jest możliwe automatyczne utworzenie pierwszego administratora regionu danych.';de = 'Der erste Datenbereichsadministrator kann nicht automatisch erstellt werden.';ro = 'Primul administrator al domeniului de date nu poate fi creat automat.';tr = 'İlk veri alanı yöneticisi otomatik olarak oluşturulamıyor.'; es_ES = 'Es imposible crear automáticamente el primer administrador del área de datos.'");
			EndIf;
			InfobaseUser = InfoBaseUsers.CreateUser();
			InfobaseUser.Name       = "Administrator";
			InfobaseUser.FullName = InfobaseUser.Name;
			InfobaseUser.Roles.Clear();
			InfobaseUser.Roles.Add(Metadata.Roles.FullRights);
			SystemAdministratorRole = Metadata.Roles.SystemAdministrator;
			If NOT InfobaseUser.Roles.Contains(SystemAdministratorRole) Then
				InfobaseUser.Roles.Add(SystemAdministratorRole);
			EndIf;
			InfobaseUser.Write();
		Else
			// If a user with administrative rights exists, there is no need to create another administrator.
			// 
			For Each CurrentIBUser In IBUsers Do
				If UsersInternal.AdministratorRolesAvailable(CurrentIBUser) Then
					Return Undefined; // The first administrator has already been created.
				EndIf;
			EndDo;
			// The first administrator is created incorrectly.
			ErrorText =
				NStr("ru = 'Список пользователей информационной базы не пустой, однако не удалось
				           |найти ни одного пользователя с ролями Полные права и Администратор системы.
				           |
				           |Вероятно, пользователи создавались в конфигураторе.
				           |Требуется назначить роли Полные права и Администратор системы хотя бы одному пользователю.'; 
				           |en = 'The list of infobase users is not blank. However, no users
				           |with both ""Full access"" and ""System administrator"" roles are found.
				           |
				           |The users were probably created in Designer.
				           |Assign both ""Full access"" and ""System administrator"" roles to one or more users.'; 
				           |pl = 'Lista użytkowników bazy informacyjnej nie jest pusta, ale nie 
				           |odnaleziono pojedynczego użytkownika z pełnymi prawami i rolami Administratora systemu.
				           |
				           | Prawdopodobnie użytkownicy zostali utworzeni w konfiguratorze.
				           | Należy przypisać Pełne prawa i role Administratora systemu do co najmniej jednego użytkownika.';
				           |de = 'Die Liste der Benutzer der Informationsbasis ist nicht leer, es konnten jedoch keine Benutzer mit den Rollen Vollständige Rechte und Systemadministrator
				           |gefunden werden.
				           |
				           |Wahrscheinlich wurden die Benutzer im Konfigurator angelegt.
				           |Es ist notwendig , die Rollen Vollständige Rechte und Systemadministrator mindestens einem Benutzer zuzuordnen.';
				           |ro = 'Lista utilizatorilor bazei de informații nu este goală, însă nu a fost
				           |găsit nici un utilizator cu rolurile Drepturi depline și Administratorul sistemului.
				           |
				           |Posibil, utilizatorii au fost creați în designer.
				           |Trebuie să atribuiți rolurile Drepturi depline și Administratorul sistemului cel puțin unui utilizator.';
				           |tr = 'Veri tabanı kullanıcı listesi boş değil, ancak Tam haklar ve Sistem Yöneticisi rolleri olan 
				           |herhangi bir kullanıcı bulunamadı. 
				           |
				           |Muhtemelen kullanıcılar yapılandırıcıda oluşturuldu.
				           | En az bir kullanıcı için Tam haklar ve Sistem Yönetici rolleri atanmalıdır.'; 
				           |es_ES = 'La lista de usuario de la base de información no está vacía pero no se ha podido
				           |encontrar ningún usuario con los roles Derechos completos y Administrador del sistema.
				           |
				           |Es posible que los usuarios hayan sido creados en el configurador.
				           |Se requiere especificar los roles Derechos completos y Administrador del sistema aunque sea para un usuario.'");
			Raise ErrorText;
		EndIf;
	Else
		If Not UsersInternal.AdministratorRolesAvailable(InfobaseUser) Then
			ErrorText =
				NStr("ru = 'Невозможно создать пользователя в справочнике для пользователя
				           |информационной базы ""%1"",
				           |так как у него нет ролей Полные права и Администратор системы.
				           |
				           |Вероятно, пользователь был создан в конфигураторе.
				           |Для автоматического создания пользователя в справочнике требуется
				           |назначить ему роли Полные права и Администратор системы.'; 
				           |en = 'Cannot create a user in the catalog
				           |mapped to the infobase user""%1""
				           |because it does not have ""Full access"" and ""System administrator"" roles.
				           |
				           |The user was probably created in Designer.
				           |To have a user created in the catalog automatically,
				           |grant the infobase user both ""Full access"" and ""System administrator"" roles.'; 
				           |pl = 'Nie można utworzyć użytkownika w katalogu dla użytkownika
				           |bazy informacyjnej ""%1"",
				           |ponieważ nie ma on pełnionych ról Pełne prawa i Administrator systemu.
				           |
				           |Prawdopodobnie użytkownik został utworzony w konfiguratorze.
				           |Aby automatycznie utworzyć użytkowników katalogu, należy
				           |przypisać jemu role Pełnych praw i Administratora systemu.';
				           |de = 'Es ist nicht möglich, einen Benutzer im Verzeichnis für den Benutzer
				           |der Informationsbasis ""%1"" anzulegen,
				           |da er nicht die Rolle Vollständige Rechte und Systemadministrator hat.
				           |
				           |Wahrscheinlich wurde der Benutzer im Konfigurator angelegt.
				           |Für die automatische Erstellung eines Benutzers im Verzeichnis ist es erforderlich,
				           |ihm die Rollen Vollständige Rechte und den Systemadministrator zuzuweisen.';
				           |ro = 'Nu puteți crea utilizatorul în clasificatorul pentru utilizatorul
				           |bazei de informații ""%1"",
				           |deoarece el nu are rolurile Drepturi depline și Administratorul sistemului.
				           |
				           |Posibil, utilizatorul a fost creat în designer.
				           |Pentru crearea automată a utilizatorului în clasificator trebuie să-i
				           |atribuiți rolurile Drepturi depline și Administratorul sistemului.';
				           |tr = 'Referans veritabanında ""%1"" bilgi veritabanının kullanıcısı için bir kullanıcı 
				           |oluşturmak mümkün değildir, 
				           |çünkü Tam Haklar ve Sistem Yöneticisi rolleri mevcut değildir. 
				           |Kullanıcı muhtemelen konfigüratörde yaratılmıştır. 
				           |Dizinde otomatik olarak bir kullanıcı oluşturmak için, ona 
				           |Tam haklar ve Sistem Yöneticisi 
				           |hakları verilmelidir.'; 
				           |es_ES = 'Es imposible crear un usuario en el catálogo para el usuario
				           |de la base de información ""%1""
				           |porque no tiene roles Derechos completos y Administrador del sistema.
				           |
				           |Es posible que el usuario haya sido creado en el configurador.
				           |Para crear automáticamente el usuario en el catálogo se requiere
				           |especificarle los roles Derechos completos y Administrador del sistema.'");
			Raise StringFunctionsClientServer.SubstituteParametersToString(ErrorText, String(InfobaseUser));
		EndIf;
		
		FindAmbiguousIBUsers(Undefined, InfobaseUser.UUID);
	EndIf;
	
	If UsersInternal.UserByIDExists(
	         InfobaseUser.UUID) Then
		
		User = Catalogs.Users.FindByAttribute(
			"IBUserID", InfobaseUser.UUID);
		
		// If the administrator is mapped to an external user, it is an error. Clear the mapping.
		// 
		If NOT ValueIsFilled(User) Then
			
			ExternalUser = Catalogs.ExternalUsers.FindByAttribute(
				"IBUserID", InfobaseUser.UUID);
			
			ExternalUserObject = ExternalUser.GetObject();
			ExternalUserObject.IBUserID = Undefined;
			ExternalUserObject.DataExchange.Load = True;
			ExternalUserObject.Write();
		EndIf;
	EndIf;
	
	If NOT ValueIsFilled(User) Then
		User = Catalogs.Users.FindByDescription(InfobaseUser.FullName);
		
		If ValueIsFilled(User)
		   AND ValueIsFilled(User.IBUserID)
		   AND User.IBUserID <> InfobaseUser.UUID
		   AND InfoBaseUsers.FindByUUID(
		         User.IBUserID) <> Undefined Then
			
			User = Undefined;
		EndIf;
	EndIf;
	
	If NOT ValueIsFilled(User) Then
		User = Catalogs.Users.CreateItem();
		UserCreated = True;
	Else
		User = User.GetObject();
		UserCreated = False;
	EndIf;
	
	User.Description = InfobaseUser.FullName;
	
	IBUserDetails = New Structure;
	IBUserDetails.Insert("Action", "Write");
	IBUserDetails.Insert(
		"UUID", InfobaseUser.UUID);
	
	User.AdditionalProperties.Insert(
		"IBUserDetails", IBUserDetails);
	
	User.AdditionalProperties.Insert("CreateAdministrator",
		?(InfobaseUser = Undefined,
		  NStr("ru = 'Выполнено создание первого администратора.'; en = 'The first administrator is created.'; pl = 'Wykonano tworzenie pierwszego administratora.';de = 'Der erste Administrator wurde angelegt.';ro = 'Primul administrator este creat.';tr = 'İlk yönetici oluşturuldu.'; es_ES = 'Se ha creado el primer administrador.'"),
		  ?(UserCreated,
		    NStr("ru = 'Администратор сопоставлен с новым пользователем справочника.'; en = 'The administrator is mapped to a new catalog user.'; pl = 'Administrator jest powiązany z nowym katalogiem użytkowników.';de = 'Der Administrator ist dem neuen Benutzerverzeichnis zugeordnet.';ro = 'Administratorul este confruntat cu utilizatorul nou al clasificatorului.';tr = 'Yönetici yeni katalog kullanıcısı ile karşılaştırılmıştır.'; es_ES = 'El administrador está comparado con el usuario del catálogo.'"),
		    NStr("ru = 'Администратор сопоставлен с существующим пользователем справочника.'; en = 'The administrator is mapped to an existing catalog user.'; pl = 'Administrator jest powiązany do istniejącego użytkownika katalogu.';de = 'Ein Administrator wird einem vorhandenen Verzeichnisbenutzer zugeordnet.';ro = 'Administratorul este confruntat cu utilizatorul existent al clasificatorului.';tr = 'Yönetici mevcut katalog kullanıcısı ile karşılaştırılmıştır.'; es_ES = 'El administrador está comparado con el usuario nuevo del catálogo.'")) ) );
		
	User.Write();
	
	Return User.Ref;
	
EndFunction

// Sets the UseUserGroups constant value to True if at least one user group exists in the catalog.
// 
//
// Used upon infobase update.
//
Procedure IfUserGroupsExistSetUsage() Export
	
	SetPrivilegedMode(True);
	
	Query = New Query(
	"SELECT
	|	TRUE AS TrueValue
	|FROM
	|	Catalog.UserGroups AS UserGroups
	|WHERE
	|	UserGroups.Ref <> VALUE(Catalog.UserGroups.AllUsers)
	|
	|UNION ALL
	|
	|SELECT
	|	TRUE
	|FROM
	|	Catalog.ExternalUsersGroups AS ExternalUsersGroups
	|WHERE
	|	ExternalUsersGroups.Ref <> VALUE(Catalog.ExternalUsersGroups.AllExternalUsers)");
	
	If NOT Query.Execute().IsEmpty() Then
		Constants.UseUserGroups.Set(True);
	EndIf;
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Procedures and functions for infobase user operations.

// Returns a textual presentation for cases, when a user is not specified or selected.
//
// Returns:
//   String - "<Not specified>"
//
Function UnspecifiedUserFullName() Export
	
	Return NStr("ru = '<Не указан>'; en = '<Not specified>'; pl = '<Nieokreślony>';de = '<Nicht angegeben>';ro = '<Nespecificat>';tr = '<Belirtilmedi>'; es_ES = '<No especificado>'");
	
EndFunction

// Returns a reference of an unspecified user.
// Parameters:
//  CreateIfDoesNotExist - Boolean - the initial value is False. If you set True, then the user 
//                            creation "<Not specified>" will be executed.
//
// Returns:
//  CatalogRef.Users - an unspecified user exists in the directory.
//  Undefined - an unspecified user does not exist in the directory.
//
Function UnspecifiedUserRef(CreateIfDoesNotExists = False) Export
	
	Ref = UsersInternal.UnspecifiedUserProperties().Ref;
	
	If Ref = Undefined AND CreateIfDoesNotExists Then
		Ref = UsersInternal.CreateUnspecifiedUser();
	EndIf;
	
	Return Ref;
	
EndFunction

// Checks whether the infobase user is mapped to an item of the Users catalog or the ExternalUsers 
// catalog.
// 
// Parameters:
//  IBUser - String - an infobase user name.
//                 - UUID - an infobase user UUID.
//                 - InfobaseUser - 
//
//  Account - InfobaseUser - (return value).
//
// Returns:
//  Boolean - True if the infobase user exists and its ID is used either in the Users catalog or in 
//   the ExternalUsers catalog.
//
Function IBUserOccupied(InfobaseUser, Account = Undefined) Export
	
	SetPrivilegedMode(True);
	
	If TypeOf(InfobaseUser) = Type("String") Then
		Account = InfoBaseUsers.FindByName(InfobaseUser);
		
	ElsIf TypeOf(InfobaseUser) = Type("UUID") Then
		Account = InfoBaseUsers.FindByUUID(InfobaseUser);
	Else
		Account = InfobaseUser;
	EndIf;
	
	If Account = Undefined Then
		Return False;
	EndIf;
	
	Return UsersInternal.UserByIDExists(
		Account.UUID);
	
EndFunction

// Returns an empty structure that describes infobase user properties.
// The purpose of the structure properties corresponds to the properties of the InfobaseUser object.
//
// Returns:
//  Structure - with the following properties:
//   * UUID - UUID - an UUID of the infobase user.
//   * Name - String - the name of an infobase user. For example, "Smith".
//   * FullName - String - the full name of an infobase user.
//                                          For example, "John Smith (sales manager)".
//   * OpenIDAuthentication - Boolean - the flag that indicates whether the user is allowed to use OpenID authentication.
//
//   * StandardAuthentication - Boolean - the flag that indicates whether user name and password authentication is allowed.
//   * ShowInList - Boolean - the flag that indicates whether to show the full user name in the list at startup.
//   * Password - String, Undefined - the password used for standard authentication.
//   * PasswordHash - String, Undefined - a password hash.
//   * PasswordSet - Boolean - the flag that indicates whether the user has a password.
//   * CannotChangePassword - Boolean - the flag that indicates whether the user can change the password.
//
//   * OSAuthentication - Boolean - the flag that indicates whether authentication by the means of OS is allowed.
//   * OSUser - String - the name of the OS user associated to the application user. Not applicable 
//                                          for the training version of the platform.
//
//   * DefaultInterface - String, Undefined - the name of the main user interface of the infobase 
//                                         (from the Metadata.Interfaces collection).
//   * RunMode - String, Undefined - valid values are "Auto", "OrdinaryApplication", or "ManagedApplication".
//   * Language - String, Undefined - the language name from the Metadata.Languages collection.
//   * Roles - Undefined - roles are not specified.
//                               - Array - a collection of infobase user role names.
//
Function NewIBUserDetails() Export
	
	// Preparing the data structure for storing the return value.
	Properties = New Structure;
	
	Properties.Insert("UUID", CommonClientServer.BlankUUID());
	
	Properties.Insert("Name",                       "");
	Properties.Insert("FullName",                 "");
	Properties.Insert("OpenIDAuthentication",      False);
	Properties.Insert("StandardAuthentication", False);
	Properties.Insert("ShowInList",   False);
	Properties.Insert("PreviousPassword",              Undefined);
	Properties.Insert("Password",                    Undefined);
	Properties.Insert("StoredPasswordValue", Undefined);
	Properties.Insert("PasswordIsSet",          False);
	Properties.Insert("CannotChangePassword",   False);
	Properties.Insert("OSAuthentication",          False);
	Properties.Insert("OSUser",            "");
	
	Properties.Insert("DefaultInterface",
		?(Metadata.DefaultInterface = Undefined, "", Metadata.DefaultInterface.Name));
	
	Properties.Insert("RunMode",              "Auto");
	
	Properties.Insert("Language",
		?(Metadata.DefaultLanguage = Undefined, "", Metadata.DefaultLanguage.Name));
	
	Properties.Insert("Roles", Undefined);
	
	Return Properties;
	
EndFunction

// Returns an infobase user properties as a structure.
// If a user with the specified ID or name does not exist, Undefined is returned.
//
// Parameters:
//  NameOrID - String, UUID - name or ID of the infobase user.
//
// Returns:
//  String, Undefined - user properties. See User.NewIBUserDetails. 
//                            Undefined, if a user with the specified ID or name does not exist.
//
Function IBUserProperies(Val NameOrID) Export
	
	CommonClientServer.CheckParameter("Users.IBUserProperies", "NameOrID",
		NameOrID, New TypeDescription("String, UUID"));
		 
	Properties = NewIBUserDetails();
	Properties.Roles = New Array;
	
	If TypeOf(NameOrID) = Type("UUID") Then
		
		If Common.SubsystemExists("StandardSubsystems.SaaS") Then
			ModuleSaaS = Common.CommonModule("SaaS");
			SessionWithoutSeparators = ModuleSaaS.SessionWithoutSeparators();
		Else
			SessionWithoutSeparators = True;
		EndIf;
		
		If Common.DataSeparationEnabled()
		   AND SessionWithoutSeparators
		   AND Common.SeparatedDataUsageAvailable()
		   AND NameOrID = InfoBaseUsers.CurrentUser().UUID Then
			
			InfobaseUser = InfoBaseUsers.CurrentUser();
		Else
			InfobaseUser = InfoBaseUsers.FindByUUID(NameOrID);
		EndIf;
		
	ElsIf TypeOf(NameOrID) = Type("String") Then
		InfobaseUser = InfoBaseUsers.FindByName(NameOrID);
	Else
		InfobaseUser = Undefined;
	EndIf;
	
	If InfobaseUser = Undefined Then
		Return Undefined;
	EndIf;
	
	CopyIBUserProperties(Properties, InfobaseUser);
	Properties.Insert("InfobaseUser", InfobaseUser);
	Return Properties;
	
EndFunction

// Writes new property values of the specified infobase user or creates a new infobase user.
// An exception will be called if a user does not exist and also on attempts to create an existing user.
//
// Parameters:
//  NameOrID - String, UUID - a name or ID of the user whose properties require setting.
//                                                           Or name of a new infobase user.
//  PropertiesToUpdate - Structure - see Users.NewIBUserDetails. 
//    If a property is not specified in the structure, a read or initial value is used.
//    The following structure properties have their peculiarities:
//      * IBUser - InfobaseUser - a return parameter: an infobase user whose properties were written.
//                                  
//      * UUID - UUID - a return parameter: the written infobase user UUID.
//                                  
//      * PreviousPassword - Undefined, String - if the specified password does not match the 
//                                  existing one, an exception will be raised.
//
//  CreateNewUser - specify True to create a new infobase user called NameOrID.
//
//  IsExternalUser - Boolean - specify True if the infobase user corresponds to an external user 
//                                    (the ExternalUsers item in the directory).
//
Procedure SetIBUserProperies(Val NameOrID, Val PropertiesToUpdate,
	Val CreateNew = False, Val IsExternalUser = False) Export
	
	ProcedureName = "Users.SetIBUserProperies";
	
	CommonClientServer.CheckParameter(ProcedureName, "NameOrID",
		NameOrID, New TypeDescription("String, UUID"));
	
	CommonClientServer.CheckParameter(ProcedureName, "PropertiesToUpdate",
		PropertiesToUpdate, Type("Structure"));
	
	CommonClientServer.CheckParameter(ProcedureName, "CreateNew",
		CreateNew, Type("Boolean"));
	
	CommonClientServer.CheckParameter(ProcedureName, "IsExternalUser",
		IsExternalUser, Type("Boolean"));
	
	PreviousProperties = IBUserProperies(NameOrID);
	UserExists = PreviousProperties <> Undefined;
	If UserExists Then
		InfobaseUser = PreviousProperties.InfobaseUser;
	Else
		InfobaseUser = Undefined;
		PreviousProperties = NewIBUserDetails();
	EndIf;
		
	If Not UserExists Then
		If Not CreateNew Then
			Raise StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'Пользователь информационной базы ""%1"" не существует.'; en = 'Infobase user ""%1"" does not exist.'; pl = 'Informacje o bazie danych użytkownika ""%1"" nie istnieją.';de = 'Der Benutzer der Informationsbasis ""%1"" existiert nicht.';ro = 'Utilizatorul bazei de informații ""%1"" nu există.';tr = 'Veritabanı kullanıcısı ""%1"" bulunamadı.'; es_ES = 'El usuario de la infobase ""%1"" no encontrado.'"),
				NameOrID);
		EndIf;
		InfobaseUser = InfoBaseUsers.CreateUser();
	Else
		If CreateNew Then
			Raise ErrorDescriptionOnWriteIBUser(
				NStr("ru = 'Невозможно создать пользователя информационной базы %1, так как он уже существует.'; en = 'Cannot create infobase user %1. The user already exists.'; pl = 'Niemożliwe jest utworzenie użytkownika bazy danych %1, ponieważ taki użytkownik już istnieje.';de = 'Es ist nicht möglich, eine Benutzerinformationsdatenbank zu erstellen%1, da diese bereits vorhanden ist.';ro = 'Nu puteți crea utilizatorul bazei de informații %1, deoarece el deja există.';tr = 'Veritabanı kullanıcısı zaten mevcut olduğundan, %1 oluşturulamaz.'; es_ES = 'Es imposible crear un usuario de la base de información %1, porque ya existe.'"),
				PreviousProperties.Name,
				PreviousProperties.UUID);
		EndIf;
		
		If PropertiesToUpdate.Property("PreviousPassword")
		   AND TypeOf(PropertiesToUpdate.PreviousPassword) = Type("String") Then
			
			PreviousPasswordMatches = UsersInternal.PreviousPasswordMatchSaved(
				PropertiesToUpdate.PreviousPassword, PreviousProperties.UUID);
			
			If Not PreviousPasswordMatches Then
				Raise ErrorDescriptionOnWriteIBUser(
					NStr("ru = 'При записи пользователя информационной базы %1 старый пароль указан не верно.'; en = 'Cannot save infobase user %1. The previous password is incorrect.'; pl = 'Podczas zapisu użytkownika bazy informacyjnej %1 stare hasło zostało podane niepoprawnie.';de = 'Das %1 alte Passwort ist beim Schreiben des Datenbankbenutzers nicht korrekt.';ro = 'La înregistrarea utilizatorului bazei de informații %1 parola veche este indicată incorect.';tr = 'Veritabanı%1 kullanıcısı yazılırken, eski şifre yanlış şekilde belirtildi.'; es_ES = 'Al guardar el usuario de la base de información %1 la contraseña antigua ha sido indicada incorrectamente.'"),
					PreviousProperties.Name,
					PreviousProperties.UUID);
			EndIf;
		EndIf;
	EndIf;
	
	// Preparing new property values.
	PasswordErrorText = "";
	NewProperties = Common.CopyRecursive(PreviousProperties);
	For Each KeyAndValue In NewProperties Do
		If Not PropertiesToUpdate.Property(KeyAndValue.Key)
		 Or PropertiesToUpdate[KeyAndValue.Key] = Undefined Then
			Continue;
		EndIf;
		If KeyAndValue.Key <> "Password" Then
			NewProperties[KeyAndValue.Key] = PropertiesToUpdate[KeyAndValue.Key];
			Continue;
		EndIf;
		If PropertiesToUpdate.Property("StoredPasswordValue")
		   AND PropertiesToUpdate.StoredPasswordValue <> Undefined Then
			Continue;
		EndIf;
		Settings = UsersInternalCached.Settings();
		If Settings.CommonAuthorizationSettings Then
			AuthorizationSettings = ?(IsExternalUser, Settings.ExternalUsers, Settings.Users);
			PasswordErrorText = UsersInternal.PasswordLengthOrComplexityError(
				PropertiesToUpdate.Password,
				AuthorizationSettings.MinPasswordLength,
				AuthorizationSettings.PasswordMustMeetComplexityRequirements);
		Else
			PasswordErrorText = UsersInternal.PasswordLengthOrComplexityError(
				PropertiesToUpdate.Password,
				GetUserPasswordMinLength(),
				GetUserPasswordStrengthCheck());
		EndIf;
		NewProperties.StoredPasswordValue =
			UsersInternal.PasswordHashString(PropertiesToUpdate.Password, True);
	EndDo;
	
	CopyIBUserProperties(InfobaseUser, NewProperties);
	
	If ValueIsFilled(PasswordErrorText) Then
		Raise ErrorDescriptionOnWriteIBUser(
			NStr("ru = 'Не удалось записать свойства пользователя информационной базы %1 по причине:
			           |%2.'; 
			           |en = 'Cannot save properties of infobase user %1. Reason:
			           |%2.'; 
			           |pl = 'Nie udało się nagrać właściwości użytkownika bazy informacyjnej %1 z powodu:
			           |%2.';
			           |de = 'Es war nicht möglich, Eigenschaften des Benutzers der Informationsbasis %1aufzuschreiben, weil:
			           |%2.';
			           |ro = 'Eșec la înregistrarea proprietăților utilizatorului bazei de informații %1 din motivul:
			           |%2.';
			           |tr = '""%1"" veritabanın kullanıcısının özellikleri aşağıdaki nedenle kaydedilemedi: 
			           |%2.'; 
			           |es_ES = 'No se ha podido guardar las propiedades de usuario de la base de información %1 a causa de:
			           |%2.'"),
			InfobaseUser.Name,
			?(UserExists, PreviousProperties.UUID, Undefined),
			PasswordErrorText);
	EndIf;
	
	If Common.DataSeparationEnabled() Then
		InfobaseUser.ShowInList = False;
	EndIf;
	
	// Attempt to write a new infobase user or edit an existing one.
	Try
		UsersInternal.WriteInfobaseUser(InfobaseUser, IsExternalUser);
	Except
		Raise ErrorDescriptionOnWriteIBUser(
			NStr("ru = 'Не удалось записать свойства пользователя информационной базы %1 по причине:
			           |%2.'; 
			           |en = 'Cannot save properties of infobase user %1. Reason:
			           |%2.'; 
			           |pl = 'Nie udało się nagrać właściwości użytkownika bazy informacyjnej %1 z powodu:
			           |%2.';
			           |de = 'Es war nicht möglich, Eigenschaften des Benutzers der Informationsbasis %1aufzuschreiben, weil:
			           |%2.';
			           |ro = 'Eșec la înregistrarea proprietăților utilizatorului bazei de informații %1 din motivul:
			           |%2.';
			           |tr = '""%1"" veritabanın kullanıcısının özellikleri aşağıdaki nedenle kaydedilemedi: 
			           |%2.'; 
			           |es_ES = 'No se ha podido guardar las propiedades de usuario de la base de información %1 a causa de:
			           |%2.'"),
			InfobaseUser.Name,
			?(UserExists, PreviousProperties.UUID, Undefined),
			ErrorInfo());
	EndTry;
	
	If ValueIsFilled(PreviousProperties.Name) AND PreviousProperties.Name <> NewProperties.Name Then
		// Moving user settings.
		UsersInternal.CopyUserSettings(PreviousProperties.Name, NewProperties.Name, True);
	EndIf;
	
	If CreateNew Then
		UsersInternal.SetInitialSettings(InfobaseUser.Name, IsExternalUser);
	EndIf;
	
	UsersOverridable.OnWriteInfobaseUser(PreviousProperties, NewProperties);
	PropertiesToUpdate.Insert("UUID", InfobaseUser.UUID);
	PropertiesToUpdate.Insert("InfobaseUser", InfobaseUser);
	
EndProcedure

// Deletes the specified infobase user.
//
// Parameters:
//  NameOrID - String, UUID - the name of ID of the user to delete.
//
Procedure DeleteIBUser(Val NameOrID) Export
	
	CommonClientServer.CheckParameter("Users.DeleteIBUser", "NameOrID",
		NameOrID, New TypeDescription("String, UUID"));
		
	DeletedIBUserProperties = IBUserProperies(NameOrID);
	If DeletedIBUserProperties = Undefined Then
		Raise StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Пользователь информационной базы ""%1"" не существует.'; en = 'Infobase user ""%1"" does not exist.'; pl = 'Informacje o bazie danych użytkownika ""%1"" nie istnieją.';de = 'Der Benutzer der Informationsbasis ""%1"" existiert nicht.';ro = 'Utilizatorul bazei de informații ""%1"" nu există.';tr = 'Veritabanı kullanıcısı ""%1"" bulunamadı.'; es_ES = 'El usuario de la infobase ""%1"" no encontrado.'"),
			NameOrID);
	EndIf;
	InfobaseUser = DeletedIBUserProperties.InfobaseUser;
		
	Try
		
		SaaSIntegration.BeforeDeleteIBUser(InfobaseUser);
		InfobaseUser.Delete();
		
	Except
		Raise ErrorDescriptionOnWriteIBUser(
			NStr("ru = 'Не удалось удалить пользователя информационной базы %1 по причине:
			           |%2.'; 
			           |en = 'Cannot delete infobase user %1. Reason:
			           |%2.'; 
			           |pl = 'Nie można usunąć użytkownika z bazy informacyjnej %1 z powodu:
			           |%2.';
			           |de = 'Es war nicht möglich, den Benutzer der Informationsbasis %1 zu löschen weil:
			           |%2.';
			           |ro = 'Eșec la ștergerea utilizatorului bazei de informații %1 din motivul:
			           |%2.';
			           |tr = '""%1"" veritabanın kullanıcısı aşağıdaki nedenle silinemedi: 
			           |%2.'; 
			           |es_ES = 'No se ha podido eliminar el usuario de la base de información %1 a causa de:
			           |%2.'"),
			InfobaseUser.Name,
			InfobaseUser.UUID,
			ErrorInfo());
	EndTry;
	UsersOverridable.AfterDeleteInfobaseUser(DeletedIBUserProperties);
	
EndProcedure

// Copies infobase user properties and performs conversion to/from string ID for the following 
// properties: default interface, language, run mode, and roles.
// 
//
//  Properties that do not exist in the source or in the destination are not copied.
//
//  Password and PasswordHash properties are not copied if
// the source value is Undefined.
//
//  The OSAuthentication, StandardAuthentication,
// OpenIDAuthentication and OSUser are not reinstalled if they match, when the Recipient is of the 
// InfoBaseUser kind.
//
//  The UUID, PasswordSet, and PreviousPassword properties
// are not copied, if the Recipient is of the InfobaseUser type.
//
//  Performs conversion only if the Source and Destination have the following type:
// InfobaseUser.
//
// Parameters:
//  Destination - Structure, InfobaseUser, ManagedForm - a subarray of properties from 
//                 NewIBUserInfo().
//
//  Source - Structure, InfobaseUser, ManagedForm - like destination, but the types are reverse, 
//                 that is when Destination is of the InfobaseUser type, Source is not of the 
//                 InfobaseUser type.
// 
//  PropertiesToCopy - String - the list of comma-separated properties to copy (without the prefix).
//  PropertiesToExclude - the list of comma-separated properties to exclude from copying (without the prefix).
//  PropertyPrefix - String - the initial name for Source or Destination if its type is NOT structure.
//
Procedure CopyIBUserProperties(Destination,
                                            Source,
                                            PropertiesToCopy = "",
                                            PropertiesToExclude = "",
                                            PropertyPrefix = "") Export
	
	If TypeOf(Destination) = Type("InfoBaseUser")
	   AND TypeOf(Source) = Type("InfoBaseUser")
	   
	 Or TypeOf(Destination) = Type("InfoBaseUser")
	   AND TypeOf(Source) <> Type("Structure")
	   AND TypeOf(Source) <> Type("ManagedForm")
	   
	 Or TypeOf(Source) = Type("InfoBaseUser")
	   AND TypeOf(Destination) <> Type("Structure")
	   AND TypeOf(Destination) <> Type("ManagedForm") Then
		
		Raise
			NStr("ru = 'Недопустимое значение параметра Приемник или Источник
			           |в процедуре СкопироватьСвойстваПользователяИБ общего модуля Пользователи.'; 
			           |en = 'Invalid value of Source or Destination parameter
			           |in CopyIBUserProperties procedure of Users common module.'; 
			           |pl = 'Niepoprawna wartość parametru Odbiorca lub Źródło
			           | w procedurze KopiowanieWłaściwości UżytkownikaIB Użytkowników modułu wspólnej biblioteki.';
			           |de = 'Ungültiger Wert des Parameters Empfänger oder Quelle
			           |in der Prozedur KopierenVonBenutzereigenschaftenDerIB im allgemeinen Modul Benutzer';
			           |ro = 'Valoare inadmisibilă a parametrului Receptor sau Sursa
			           |în procedura СкопироватьСвойстваПользователяИБ modulului general Utilizatori.';
			           |tr = 'Kullanıcılar ortak modülün VTKullanıcıÖzellikleriniKopyalar prosedüründe Alıcı veya Kaynak 
			           | parametresi kabul edilemez.'; 
			           |es_ES = 'Valor no admitido del parámetro Receptor o Fuente
			           |en el procedimiento CopyIBUserProperties del módulo común Usuario.'");
	EndIf;
	
	AllProperties = NewIBUserDetails();
	
	If ValueIsFilled(PropertiesToCopy) Then
		CopiedPropertiesStructure = New Structure(PropertiesToCopy);
	Else
		CopiedPropertiesStructure = AllProperties;
	EndIf;
	
	If ValueIsFilled(PropertiesToExclude) Then
		ExcludedPropertiesStructure = New Structure(PropertiesToExclude);
	Else
		ExcludedPropertiesStructure = New Structure;
	EndIf;
	
	If StandardSubsystemsServer.IsTrainingPlatform() Then
		ExcludedPropertiesStructure.Insert("OSAuthentication");
		ExcludedPropertiesStructure.Insert("OSUser");
	EndIf;
	
	PasswordSet = False;
	
	For each KeyAndValue In AllProperties Do
		Property = KeyAndValue.Key;
		
		If NOT CopiedPropertiesStructure.Property(Property)
		 OR ExcludedPropertiesStructure.Property(Property) Then
		
			Continue;
		EndIf;
		
		If TypeOf(Source) = Type("InfoBaseUser")
		   AND (    TypeOf(Destination) = Type("Structure")
		      Or TypeOf(Destination) = Type("ManagedForm") ) Then
			
			If Property = "Password"
			 OR Property = "PreviousPassword" Then
				
				PropertyValue = Undefined;
				
			ElsIf Property = "DefaultInterface" Then
				PropertyValue = ?(Source.DefaultInterface = Undefined,
				                     "",
				                     Source.DefaultInterface.Name);
			
			ElsIf Property = "RunMode" Then
				ValueFullName = GetPredefinedValueFullName(Source.RunMode);
				PropertyValue = Mid(ValueFullName, StrFind(ValueFullName, ".") + 1);
				
			ElsIf Property = "Language" Then
				PropertyValue = ?(Source.Language = Undefined,
				                     "",
				                     Source.Language.Name);
				
			ElsIf Property = "Roles" Then
				
				TempStructure = New Structure("Roles", New ValueTable);
				FillPropertyValues(TempStructure, Destination);
				If TypeOf(TempStructure.Roles) = Type("ValueTable") Then
					Continue;
				ElsIf TempStructure.Roles = Undefined Then
					Destination.Roles = New Array;
				Else
					Destination.Roles.Clear();
				EndIf;
				
				For each Role In Source.Roles Do
					Destination.Roles.Add(Role.Name);
				EndDo;
				
				Continue;
			Else
				PropertyValue = Source[Property];
			EndIf;
			
			PropertyFullName = PropertyPrefix + Property;
			TempStructure = New Structure(PropertyFullName, PropertyValue);
			FillPropertyValues(Destination, TempStructure);
		Else
			If TypeOf(Source) = Type("Structure") Then
				If Source.Property(Property) Then
					PropertyValue = Source[Property];
				Else
					Continue;
				EndIf;
			Else
				PropertyFullName = PropertyPrefix + Property;
				TempStructure = New Structure(PropertyFullName, New ValueTable);
				FillPropertyValues(TempStructure, Source);
				PropertyValue = TempStructure[PropertyFullName];
				If TypeOf(PropertyValue) = Type("ValueTable") Then
					Continue;
				EndIf;
			EndIf;
			
			If TypeOf(Destination) = Type("InfoBaseUser") Then
			
				If Property = "UUID"
				 OR Property = "PreviousPassword"
				 OR Property = "PasswordIsSet" Then
					
					Continue;
					
				ElsIf Property = "OpenIDAuthentication"
				      OR Property = "StandardAuthentication"
				      OR Property = "OSAuthentication"
				      OR Property = "OSUser" Then
					
					If Destination[Property] <> PropertyValue Then
						Destination[Property] = PropertyValue;
					EndIf;
					
				ElsIf Property = "Password" Then
					If PropertyValue <> Undefined Then
						Destination.Password = PropertyValue;
						PasswordSet = True;
					EndIf;
					
				ElsIf Property = "StoredPasswordValue" Then
					If PropertyValue <> Undefined
					   AND NOT PasswordSet Then
						Destination.StoredPasswordValue = PropertyValue;
					EndIf;
					
				ElsIf Property = "DefaultInterface" Then
					If TypeOf(PropertyValue) = Type("String") Then
						Destination.DefaultInterface = Metadata.Interfaces.Find(PropertyValue);
					Else
						Destination.DefaultInterface = Undefined;
					EndIf;
				
				ElsIf Property = "RunMode" Then
					If PropertyValue = "Auto"
					 OR PropertyValue = "OrdinaryApplication"
					 OR PropertyValue = "ManagedApplication" Then
						
						Destination.RunMode = ClientRunMode[PropertyValue];
					Else
						Destination.RunMode = ClientRunMode.Auto;
					EndIf;
					
				ElsIf Property = "Language" Then
					If TypeOf(PropertyValue) = Type("String") Then
						Destination.Language = Metadata.Languages.Find(PropertyValue);
					Else
						Destination.Language = Undefined;
					EndIf;
					
				ElsIf Property = "Roles" Then
					Destination.Roles.Clear();
					If PropertyValue <> Undefined Then
						For each RoleName In PropertyValue Do
							Role = Metadata.Roles.Find(RoleName);
							If Role <> Undefined Then
								Destination.Roles.Add(Role);
							EndIf;
						EndDo;
					EndIf;
				Else
					If Property = "Name"
					   AND Destination[Property] <> PropertyValue Then
					
						If StrLen(PropertyValue) > 64 Then
							Raise StringFunctionsClientServer.SubstituteParametersToString(
								NStr("ru = 'Ошибка записи пользователя информационной базы
								           |Имя (для входа): ""%1""
								           |превышает длину 64 символа.'; 
								           |en = 'Cannot save the infobase user.
								           |Username: ""%1"".
								           |The name length exceeds 64 characters.'; 
								           |pl = 'Błąd podczas zapisywania użytkownika bazy danych 
								           |Nazwa (dla logowania): ""%1""
								           | przekracza 64 znaki.';
								           |de = 'Fehler beim Schreiben der Benutzerinfobase
								           |Name (für die Eingabe): ""%1""
								           |überschreitet 64 Zeichen.';
								           |ro = 'Eroare de înregistrare a utilizatorului bazei de informații
								           |Numele (pentru intrare): ""%1""
								           |depășește lungimea de 64 de simboluri.';
								           |tr = 'Veritabanı kullanıcı adı kaydedilirken bir hata oluştu
								           |İsim 
								           | (giriş için): %1 64 karakter uzunluğunu aşıyor.'; 
								           |es_ES = 'Ha ocurrido un error al guardar el usuario de la base de información
								           |Nombre (para inicio de sesión): ""%1""
								           | excede la longitud en 64 símbolos.'"),
								PropertyValue);
							
						ElsIf StrFind(PropertyValue, ":") > 0 Then
							Raise StringFunctionsClientServer.SubstituteParametersToString(
								NStr("ru = 'Ошибка записи пользователя информационной базы
								           |Имя (для входа): ""%1""
								           |содержит запрещенный символ "":"".'; 
								           |en = 'Cannot save the infobase user.
								           |Username: ""%1"".
								           |The name contains a prohibited character "":"".'; 
								           |pl = 'Błąd podczas zapisywania użytkownika bazy danych 
								           |Nazwa (w przypadku logowania): ""%1""
								           | zawiera niedozwolony znak "":"".';
								           |de = 'Fehler beim Schreiben der Benutzerinfobase
								           |Name (für die Eingabe): ""%1""
								           | enthält ein verbotenes Zeichen. ';
								           |ro = 'Eroare de înregistrare a utilizatorului bazei de informații
								           |Numele (pentru intrare): ""%1""
								           |conține simbolul interzis "":"".';
								           |tr = 'Veritabanı kullanıcı kaydedilirken bir hata oluştu
								           |İsim 
								           | (giriş için): %1 izin verilmeyen karakter içeriyor "":"".'; 
								           |es_ES = 'Ha ocurrido un error al guardar el usuario de la base de información
								           |Nombre (para inicio de sesión): ""%1""
								           | un símbolo prohibido "":"".'"),
								PropertyValue);
						EndIf;
					EndIf;
					Destination[Property] = Source[Property];
				EndIf;
			Else
				If Property = "Roles" Then
					
					TempStructure = New Structure("Roles", New ValueTable);
					FillPropertyValues(TempStructure, Destination);
					If TypeOf(TempStructure.Roles) = Type("ValueTable") Then
						Continue;
					ElsIf TempStructure.Roles = Undefined Then
						Destination.Roles = New Array;
					Else
						Destination.Roles.Clear();
					EndIf;
					
					If Source.Roles <> Undefined Then
						For each Role In Source.Roles Do
							Destination.Roles.Add(Role.Name);
						EndDo;
					EndIf;
					Continue;
					
				ElsIf TypeOf(Source) = Type("Structure") Then
					PropertyFullName = PropertyPrefix + Property;
				Else
					PropertyFullName = Property;
				EndIf;
				TempStructure = New Structure(PropertyFullName, PropertyValue);
				FillPropertyValues(Destination, TempStructure);
			EndIf;
		EndIf;
	EndDo;
	
EndProcedure

// Returns an item of the Users catalog that is mapped to the specified infobase user.
// 
//  Searching for the user requires administrative rights. If you do not have administrative rights,
// you can only search a user for the current infobase user.
// 
// Parameters:
//  Username - String - the user name for infobase authentication.
//
// Returns:
//  CatalogRef.Users if the user is found.
//  Catalogs.Users.EmptyRef() - if the infobase user is found.
//  Undefined                            - if the infobase user is not found.
//
Function FindByName(Val Username) Export
	
	SetPrivilegedMode(True);
	InfobaseUser = InfoBaseUsers.FindByName(Username);
	
	If InfobaseUser = Undefined Then
		Return Undefined;
	Else
		FindAmbiguousIBUsers(Undefined, InfobaseUser.UUID);
		
		Return Catalogs.Users.FindByAttribute(
			"IBUserID",
			InfobaseUser.UUID);
	EndIf;
	
EndFunction

// Searches for infobase user IDs that are used more than once and either raises an exception or 
// returns the list of found infobase users.
// 
//
// Parameters:
//  User - Undefined - checking all users and external users.
//               - CatalogRef.Users, CatalogRef.ExternalUsers - checking only the given reference.
//                 
//
//  UUID - Undefined - checking all infobase user IDs.
//                          - UUID - checking the user with the given ID.
//
//  FoundIDs - Undefined - if an error found, en exception is raised.
//                          - Map -  if an error found, en exception is not raised and the map is 
//                              populated as follows:
//                              * Key     - the undefined user ID.
//                              * Value - the array of users and external users.
//
//  ServiceUserID - Boolean - if False, check IBUserID. If True, check ServiceUserID.
//                                              
//
Procedure FindAmbiguousIBUsers(Val User,
                                            Val UUID = Undefined,
                                            Val FoundIDs = Undefined,
                                            Val ServiceUserID = False) Export
	
	SetPrivilegedMode(True);
	BlankUUID = CommonClientServer.BlankUUID();
	
	If TypeOf(UUID) <> Type("UUID")
	 Or UUID = BlankUUID Then
		
		UUID = Undefined;
	EndIf;
	
	Query = New Query;
	Query.SetParameter("BlankUUID", BlankUUID);
	
	If User = Undefined AND UUID = Undefined Then
		Query.Text =
		"SELECT
		|	Users.IBUserID AS AmbiguousID
		|FROM
		|	Catalog.Users AS Users
		|
		|GROUP BY
		|	Users.IBUserID
		|
		|HAVING
		|	Users.IBUserID <> &BlankUUID AND
		|	COUNT(Users.Ref) > 1
		|
		|UNION ALL
		|
		|SELECT
		|	ExternalUsers.IBUserID
		|FROM
		|	Catalog.ExternalUsers AS ExternalUsers
		|
		|GROUP BY
		|	ExternalUsers.IBUserID
		|
		|HAVING
		|	ExternalUsers.IBUserID <> &BlankUUID AND
		|	COUNT(ExternalUsers.Ref) > 1
		|
		|UNION ALL
		|
		|SELECT
		|	Users.IBUserID
		|FROM
		|	Catalog.Users AS Users
		|		INNER JOIN Catalog.ExternalUsers AS ExternalUsers
		|		ON (ExternalUsers.IBUserID = Users.IBUserID)
		|			AND (Users.IBUserID <> &BlankUUID)";
		
	ElsIf UUID <> Undefined Then
		
		Query.SetParameter("UUID", UUID);
		Query.Text =
		"SELECT
		|	Users.IBUserID AS AmbiguousID
		|FROM
		|	Catalog.Users AS Users
		|WHERE
		|	Users.IBUserID = &UUID
		|
		|UNION ALL
		|
		|SELECT
		|	ExternalUsers.IBUserID
		|FROM
		|	Catalog.ExternalUsers AS ExternalUsers
		|WHERE
		|	ExternalUsers.IBUserID = &UUID";
	Else
		Query.SetParameter("User", User);
		Query.Text =
		"SELECT
		|	Users.IBUserID AS AmbiguousID
		|FROM
		|	Catalog.Users AS Users
		|WHERE
		|	Users.IBUserID IN
		|			(SELECT
		|				CatalogUsers.IBUserID
		|			FROM
		|				Catalog.Users AS CatalogUsers
		|			WHERE
		|				CatalogUsers.Ref = &User
		|				AND CatalogUsers.IBUserID <> &BlankUUID)
		|
		|UNION ALL
		|
		|SELECT
		|	ExternalUsers.IBUserID
		|FROM
		|	Catalog.ExternalUsers AS ExternalUsers
		|WHERE
		|	ExternalUsers.IBUserID IN
		|			(SELECT
		|				CatalogUsers.IBUserID
		|			FROM
		|				Catalog.Users AS CatalogUsers
		|			WHERE
		|				CatalogUsers.Ref = &User
		|				AND CatalogUsers.IBUserID <> &BlankUUID)";
		
		If TypeOf(User) = Type("CatalogRef.ExternalUsers") Then
			Query.Text = StrReplace(Query.Text,
				"Catalog.Users AS CatalogUsers",
				"Catalog.ExternalUsers AS CatalogUsers");
		EndIf;
	EndIf;
	
	If ServiceUserID Then
		Query.Text = StrReplace(Query.Text,
			"IBUserID",
			"ServiceUserID");
	EndIf;
	
	DataExported = Query.Execute().Unload();
	
	If User = Undefined AND UUID = Undefined Then
		If DataExported.Count() = 0 Then
			Return;
		EndIf;
	Else
		If DataExported.Count() < 2 Then
			Return;
		EndIf;
	EndIf;
	
	AmbiguousIDs = DataExported.UnloadColumn("AmbiguousID");
	
	Query = New Query;
	Query.SetParameter("AmbiguousIDs", AmbiguousIDs);
	Query.Text =
	"SELECT
	|	AmbiguousIDs.AmbiguousID AS AmbiguousID,
	|	AmbiguousIDs.User AS User
	|FROM
	|	(SELECT
	|		Users.IBUserID AS AmbiguousID,
	|		Users.Ref AS User
	|	FROM
	|		Catalog.Users AS Users
	|	WHERE
	|		Users.IBUserID IN(&AmbiguousIDs)
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		ExternalUsers.IBUserID,
	|		ExternalUsers.Ref
	|	FROM
	|		Catalog.ExternalUsers AS ExternalUsers
	|	WHERE
	|		ExternalUsers.IBUserID IN(&AmbiguousIDs)) AS AmbiguousIDs
	|
	|ORDER BY
	|	AmbiguousIDs.AmbiguousID,
	|	AmbiguousIDs.User";
	
	DataExported = Query.Execute().Unload();
	
	ErrorDescription = NStr("ru = 'Ошибка в базе данных.'; en = 'Database error.'; pl = 'Błąd w bazie danych.';de = 'Fehler in der Datenbank.';ro = 'Eroare în baza de date.';tr = 'Veritabanı hatası.'; es_ES = 'Error en la base de datos.'") + Chars.LF;
	CurrentAmbiguousID = Undefined;
	
	For Each Row In DataExported Do
		If Row.AmbiguousID <> CurrentAmbiguousID Then
			CurrentAmbiguousID = Row.AmbiguousID;
			If TypeOf(FoundIDs) = Type("Map") Then
				CurrentUsers = New Array;
				FoundIDs.Insert(CurrentAmbiguousID, CurrentUsers);
			Else
				CurrentIBUser = InfoBaseUsers.CurrentUser();
				
				If CurrentIBUser.UUID <> CurrentAmbiguousID Then
					CurrentIBUser =
						InfoBaseUsers.FindByUUID(
							CurrentAmbiguousID);
				EndIf;
				
				If CurrentIBUser = Undefined Then
					Username = NStr("ru = '<не найден>'; en = '<not found>'; pl = '<nieokreślony>';de = '<nicht gefunden>';ro = '<nu a fost găsită>';tr = '<bulunamadı>'; es_ES = '<no encontrado>'");
				Else
					Username = CurrentIBUser.Name;
				EndIf;
				
				ErrorDescription = ErrorDescription + Chars.LF;
				If ServiceUserID Then
					ErrorDescription = ErrorDescription + StringFunctionsClientServer.SubstituteParametersToString(
						NStr("ru = 'Пользователю сервиса с идентификатором ""%1""
						           |соответствует более одного элемента в справочнике:'; 
						           |en = 'The service user with ID ""%1""
						           |is mapped to multiple catalog items:'; 
						           |pl = 'Użytkownik usługi z identyfikatorem ""%1""
						           | odpowiada więcej niż jednemu elementowi w katalogu:';
						           |de = 'Der Servicebenutzer mit der Kennung ""%1""
						           |entspricht mehr als einem Element im Verzeichnis:';
						           |ro = 'Utilizatorului serviciului cu identificatorul ""%1""
						           |îi corespunde mai mult de un element în clasificator:';
						           |tr = '""%1"" tanımlayıcısı olan servis kullanıcısı 
						           | kılavuzdaki birden fazla öğe ile uyumludur:'; 
						           |es_ES = 'El usuario del servicio con el identificador ""%1""
						           |corresponde a más de un elemento en el catálogo:'"),
						CurrentAmbiguousID);
				Else
					ErrorDescription = ErrorDescription + StringFunctionsClientServer.SubstituteParametersToString(
						NStr("ru = 'Пользователю ИБ ""%1"" с идентификатором ""%2""
						           |соответствует более одного элемента в справочнике:'; 
						           |en = 'Infobase user ""%1"" with ID ""%2""
						           |is mapped to multiple catalog items:'; 
						           |pl = 'Użytkownik IB ""%1"" z identyfikatorem ""%2""
						           | pasuje do więcej niż jednego elementu w katalogu:';
						           |de = 'Der Benutzer der IB ""%1"" mit der Kennung ""%2""
						           |entspricht mehr als einem Element im Verzeichnis:';
						           |ro = 'Utilizatorului BI ""%1"" cu identificatorul ""%2""
						           |îi corespunde mai mult de un element în clasificator:';
						           |tr = '%1Tanımlayıcı olan 
						           |VT kullanıcısı, %2kataloğunda birden fazla öğeye karşılık gelir:'; 
						           |es_ES = 'Al usuario de la IB ""%1"" con el identificador ""%2""
						           | corresponde a más de un elemento en el catálogo:'"),
						Username,
						CurrentAmbiguousID);
				EndIf;
				ErrorDescription = ErrorDescription + Chars.LF;
			EndIf;
		EndIf;
		
		If TypeOf(FoundIDs) = Type("Map") Then
			CurrentUsers.Add(Row.User);
		Else
			ErrorDescription = ErrorDescription + "- "
				+ StringFunctionsClientServer.SubstituteParametersToString(
					NStr("ru = '""%1"" %2'; en = '""%1"" %2'; pl = '""%1"" %2';de = '""%1"" %2';ro = '""%1"" %2';tr = '""%1"" %2'; es_ES = '""%1"" %2'"),
					Row.User,
					GetURL(Row.User)) + Chars.LF;
		EndIf;
	EndDo;
	
	If TypeOf(FoundIDs) <> Type("Map") Then
		Raise ErrorDescription;
	EndIf;
	
EndProcedure

// Returns a password hash.
//
// Parameters:
//  Password - String - a password for which it is required to get a password hash.
//
// Returns:
//  String - a password hash.
//
Function PasswordHashString(Val Password) Export
	
	Return UsersInternal.PasswordHashString(Password);
	
EndFunction

////////////////////////////////////////////////////////////////////////////////
// Other procedures and functions.

// Defines if a configuration supports common authentication settings, such as:
// password complexity, password change, application usage time limits, and others.
// See the CommonAuthorizationSettings property in UsersOverridable.OnDefineSettings.
//
// Returns:
//  Boolean - True if the configuration supports common authentication users.
//
Function CommonAuthorizationSettingsUsed() Export
	
	Return UsersInternalCached.Settings().CommonAuthorizationSettings;
	
EndFunction

// Returns roles assignment specified bythe  library and application developers.
// Area of application: only for automatized configuration check.
//
// Returns:
//  Structure - see parameter of the same name in the OnDefineRolesAssignment procedure of the 
//              UsersOverridable common module.
//
Function RolesAssignment() Export
	
	RolesAssignment = New Structure;
	RolesAssignment.Insert("ForSystemAdministratorsOnly",                New Array);
	RolesAssignment.Insert("ForSystemUsersOnly",                  New Array);
	RolesAssignment.Insert("ForExternalUsersOnly",                  New Array);
	RolesAssignment.Insert("BothForUsersAndExternalUsers", New Array);
	
	UsersOverridable.OnDefineRoleAssignment(RolesAssignment);
	SSLSubsystemsIntegration.OnDefineRoleAssignment(RolesAssignment);
	
	Return RolesAssignment;
	
EndFunction

// Checks whether the rights of roles match the role assignments specified in the 
// OnDefineRolesAssignment procedure of the UsersOverridable common module.
//
// It is applied if:
//  - the security of configuration is checked before updating it to a new version automatically;
//  - the configuration is checked before assembling;
//  - the configuration is checked when developing.
//
// Parameters:
//  CheckAll - Boolean - if False, the role assignment check is skipped according to the 
//                          requirements of the service technologies (which is faster), otherwise 
//                          the check is performed if separation is enabled.
//
//  ErrorsList - Undefined - if errors are found, the text of errors is generated and an exception is called.
//               - ValueList - (return value) - found errors are added to the list without calling an exception.
//                   * Value - String - a role name.
//                                   - Undefined - the role specified in the procedure is not found in metadata.
//                   * Presentation - String - an error text.
//
Procedure CheckRoleAssignment(CheckAll = False, ErrorsList = Undefined) Export
	
	RolesAssignment = UsersInternalCached.RolesAssignment();
	
	UsersInternal.CheckRoleAssignment(RolesAssignment, CheckAll, ErrorsList);
	
EndProcedure

// Adds system administrators to the access group connected with the predefined 
// OpenExternalReportsAndDataProcessors profile.
// Hides the security warnings that pop-up upon the first start of the administrator session.
// Not for the SaaS mode.
//
// Parameters:
//   OpenAllowed - Boolean - if True, set opening permission.
//
Procedure SetExternalReportsAndDataProcessorsOpenRight(OpenAllowed) Export
	
	If Common.DataSeparationEnabled() Then
		Return;
	EndIf;
	
	AdministrationParameters = StandardSubsystemsServer.AdministrationParameters();
	AdministrationParameters.Insert("OpenExternalReportsAndDataProcessorsDecisionMade", True);
	StandardSubsystemsServer.SetAdministrationParameters(AdministrationParameters);
	
	If Common.SubsystemExists("StandardSubsystems.AccessManagement") Then
		ModuleAccessControlInternal = Common.CommonModule("AccessManagementInternal");
		ModuleAccessControlInternal.SetExternalReportsAndDataProcessorsOpenRight(OpenAllowed);
		Return;
	EndIf;
	
	SystemAdministratorRole = Metadata.Roles.SystemAdministrator;
	InteractiveOpeningRole = Metadata.Roles.InteractiveOpenExtReportsAndDataProcessors;
	
	IBUsers = InfoBaseUsers.GetUsers();
	For Each InfobaseUser In IBUsers Do
		
		If Not InfobaseUser.Roles.Contains(SystemAdministratorRole) Then
			Continue;
		EndIf;
		
		UserChanged = False;
		HasInteractiveOpeningRole = InfobaseUser.Roles.Contains(InteractiveOpeningRole);
		If OpenAllowed Then 
			If Not HasInteractiveOpeningRole Then 
				InfobaseUser.Roles.Add(InteractiveOpeningRole);
				UserChanged = True;
			EndIf;
		Else 
			If HasInteractiveOpeningRole Then
				InfobaseUser.Roles.Delete(InteractiveOpeningRole);
				UserChanged = True;
			EndIf;
		EndIf;
		If UserChanged Then 
			InfobaseUser.Write();
		EndIf;
		
		SettingsDetails = New SettingsDescription;
		SettingsDetails.Presentation = NStr("ru ='Предупреждение безопасности'; en = 'Security warning'; pl = 'Ostrzeżenie bezpieczeństwa';de = 'Sicherheitswarnung';ro = 'Avertisment de securitate';tr = 'Güvenlik uyarısı'; es_ES = 'Aviso de seguridad'");
		Common.CommonSettingsStorageSave(
			"SecurityWarning", 
			"UserAccepts", 
			True, 
			SettingsDetails, 
			InfobaseUser.Name);
		
	EndDo;
	
EndProcedure

#Region ObsoleteProceduresAndFunctions

// Obsolete. According to the standard 488 "Standard Roles", the FullRights role can no longer 
// contain system administration rights (including rights for base versions).
// Now the role of system administration is always SystemAdministrator.
//
// Parameters:
//  ForCheck - Boolean - no longer matters.
//
// Returns:
//  MetadataObject - a role.
//
Function SystemAdministratorRole(ForCheck = False) Export
	
	Return Metadata.Roles.SystemAdministrator;
	
EndFunction

// Obsolete. Use Users.IBUserProperties instead.
//
// Reads user information properties of the infobase.
// If the user with the specified name or ID does not exist, writes a message to the 
// ErrorDescription parameter.
//
// Parameters:
//  ID - String, UUID - name or ID of the infobase user.
//  Properties - Structure - the read user properties. See Users.NewIBUserDetails. 
//  ErrorDescription - String    - an error description for the scenario when the user does not exist.
//  IBUser - InfobaseUser - an internal parameter.
//
// Returns:
//  Boolean - True if user properties are successfully read. Otherwise, see the ErrorDescription parameter.
//
Function ReadIBUser(Val ID, Properties = Undefined,
	ErrorDescription = "", InfobaseUser = Undefined) Export
	
	Properties = IBUserProperies(ID);
	Result = Properties <> Undefined;
	If Result Then
		InfobaseUser = Properties.InfobaseUser;
	Else
		Properties = NewIBUserDetails();
		Properties.Roles = New Array;
		ErrorDescription = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Пользователь информационной базы ""%1"" не существует.'; en = 'Infobase user ""%1"" does not exist.'; pl = 'Informacje o bazie danych użytkownika ""%1"" nie istnieją.';de = 'Der Benutzer der Informationsbasis ""%1"" existiert nicht.';ro = 'Utilizatorul bazei de informații ""%1"" nu există.';tr = 'Veritabanı kullanıcısı ""%1"" bulunamadı.'; es_ES = 'El usuario de la infobase ""%1"" no encontrado.'"),
			ID);
	EndIf;
	Return Result;
	
EndFunction

// Obsolete. Use Users.SetIBUserProperties instead.
// Overwrites properties of the infobase user that is found by string ID or UUID, or creates a new 
// infobase user (if an attempt to create an existing user is made, there will be an error).
// 
//
// Parameters:
//  ID - String, UUID - a user ID.
//
//  PropertiesToUpdate - Structure - see Users.NewIBUserDetails. 
//    If a property is not specified in the structure, a read or initial value is used.
//    The following structure properties have their peculiarities:
//      * UUID - UUID - an UUID of an infobase user is installed to it after the user is written.
//                                  
//      * PreviousPassword            - Undefined, String - if the specified password does not match 
//                                  the current one, display an error (see the ErrorDescription parameter).
//
//  CreateNew - False - no additional actions.
//                - Undefined, True - creates new infobase user if IBUser it is not found by the 
//                  specified ID.
//                  If the parameter value is True and the IBUser is found by the specified ID, an 
//                  error will appear.
//
//  ErrorDescription - String - an error description for the scenario when a user cannot be read.
//
//  User - CatalogRef.Users, CatalogObject.Users,
//                   CatalogRef.ExternalUsers, and CatalogObject.ExternalUsers are a user with who 
//                     the IBUser is mapped to.
//                 - Undefined - a reference or an object of the user in the directory if it exists.
//                 - InfobaseUser - (return value), if the writing is a success.
//
// Returns:
//  Boolean - if True, the user is written. Otherwise, see ErrorDescription. 
//
Function WriteIBUser(Val ID,
                               Val PropertiesToUpdate,
                               Val CreateNew = False,
                               ErrorDescription = "",
                               User = Undefined) Export
	
	PreviousProperties = IBUserProperies(ID);
	PreliminaryRead = PreviousProperties <> Undefined;
	If PreviousProperties <> Undefined Then
		InfobaseUser = PreviousProperties.InfobaseUser;
	Else	
		InfobaseUser = Undefined;
		PreviousProperties = NewIBUserDetails();
		PreviousProperties.Roles = New Array;
	EndIf;	
		
	If NOT PreliminaryRead Then
		
		If CreateNew = Undefined OR CreateNew = True Then
			InfobaseUser = InfoBaseUsers.CreateUser();
		Else
			Return False;
		EndIf;
	ElsIf CreateNew = True Then
		ErrorDescription = ErrorDescriptionOnWriteIBUser(
			NStr("ru = 'Невозможно создать пользователя информационной базы
			           |%1,
			           |так как он уже существует.'; 
			           |en = 'Cannot create infobase user
			           |%1
			           |because this user already exists.'; 
			           |pl = 'Nie można utworzyć użytkownika bazy informacyjnej
			           |%1,
			           |tak jak on już istnieje.';
			           |de = 'Es ist nicht möglich, einen Benutzer der Informationsbasis anzulegen
			           |%1,
			           |da er bereits existiert.';
			           |ro = 'Nu puteți crea utilizatorul bazei de informații
			           |%1,
			           |deoarece el deja există.';
			           |tr = 'Veritabanı kullanıcısı zaten mevcut olduğundan 
			           |
			           |, %1 oluşturulamaz.'; 
			           |es_ES = 'No se puede crear el usuario de la base de información
			           |%1
			           |, porque ya existe.'"),
			PreviousProperties.Name,
			PreviousProperties.UUID);
		Return False;
	Else
		If PropertiesToUpdate.Property("PreviousPassword")
		   AND TypeOf(PropertiesToUpdate.PreviousPassword) = Type("String") Then
			
			PreviousPasswordMatches = UsersInternal.PreviousPasswordMatchSaved(
				PropertiesToUpdate.PreviousPassword, PreviousProperties.UUID);
			
			If NOT PreviousPasswordMatches Then
				ErrorDescription = ErrorDescriptionOnWriteIBUser(
					NStr("ru = 'При записи пользователя информационной базы
					           |%1,
					           |старый пароль указан не верно.'; 
					           |en = 'Cannot save infobase user
					           |%1
					           |because the previous password is incorrect.'; 
					           |pl = 'Podczas nagrywania użytkownika bazy informacyjnej
					           |%1,
					           |stare hasło jest nie poprawnie podane.';
					           |de = 'Beim Aufzeichnen des Datenbankbenutzers
					           |%1
					           |ist das alte Passwort nicht korrekt.';
					           |ro = 'La înregistrarea utilizatorului bazei de informații
					           |%1,
					           |parola veche este indicată incorect.';
					           |tr = 'Veritabanı%1 
					           |kullanıcısı kaydedilirken, 
					           |eski şifre yanlış şekilde belirtildi.'; 
					           |es_ES = 'Al guardar el usuario de la base de información
					           |%1
					           |, la contraseña antigua se ha especificado de forma incorrecta.'"),
					PreviousProperties.Name,
					PreviousProperties.UUID);
				Return False;
			EndIf;
		EndIf;
	EndIf;
	
	IsExternalUser = TypeOf(User) = Type("CatalogRef.ExternalUsers")
		Or TypeOf(User) = Type("CatalogObject.ExternalUsers");
	
	// Preparing new property values.
	NewProperties = Common.CopyRecursive(PreviousProperties);
	For Each KeyAndValue In NewProperties Do
		If Not PropertiesToUpdate.Property(KeyAndValue.Key)
		 Or PropertiesToUpdate[KeyAndValue.Key] = Undefined Then
			Continue;
		EndIf;
		If KeyAndValue.Key <> "Password" Then
			NewProperties[KeyAndValue.Key] = PropertiesToUpdate[KeyAndValue.Key];
			Continue;
		EndIf;
		If PropertiesToUpdate.Property("StoredPasswordValue")
		   AND PropertiesToUpdate.StoredPasswordValue <> Undefined Then
			Continue;
		EndIf;
		Settings = UsersInternalCached.Settings();
		If Settings.CommonAuthorizationSettings Then
			AuthorizationSettings = ?(IsExternalUser, Settings.ExternalUsers, Settings.Users);
			PasswordErrorText = UsersInternal.PasswordLengthOrComplexityError(
				PropertiesToUpdate.Password,
				AuthorizationSettings.MinPasswordLength,
				AuthorizationSettings.PasswordMustMeetComplexityRequirements);
		Else
			PasswordErrorText = UsersInternal.PasswordLengthOrComplexityError(
				PropertiesToUpdate.Password,
				GetUserPasswordMinLength(),
				GetUserPasswordStrengthCheck());
		EndIf;
		NewProperties.StoredPasswordValue =
			UsersInternal.PasswordHashString(PropertiesToUpdate.Password, True);
	EndDo;
	
	CopyIBUserProperties(InfobaseUser, NewProperties);
	
	If ValueIsFilled(PasswordErrorText) Then
		Raise ErrorDescriptionOnWriteIBUser(
			NStr("ru = 'Не удалось записать свойства пользователя информационной базы %1 по причине:
			           |%2.'; 
			           |en = 'Cannot save properties of infobase user %1. Reason:
			           |%2.'; 
			           |pl = 'Nie udało się nagrać właściwości użytkownika bazy informacyjnej %1 z powodu:
			           |%2.';
			           |de = 'Es war nicht möglich, Eigenschaften des Benutzers der Informationsbasis %1aufzuschreiben, weil:
			           |%2.';
			           |ro = 'Eșec la înregistrarea proprietăților utilizatorului bazei de informații %1 din motivul:
			           |%2.';
			           |tr = '""%1"" veritabanın kullanıcısının özellikleri aşağıdaki nedenle kaydedilemedi: 
			           |%2.'; 
			           |es_ES = 'No se ha podido guardar las propiedades de usuario de la base de información %1 a causa de:
			           |%2.'"),
			InfobaseUser.Name,
			?(PreliminaryRead, PreviousProperties.UUID, Undefined),
			PasswordErrorText);
	EndIf;
	
	If Common.DataSeparationEnabled() Then
		InfobaseUser.ShowInList = False;
	EndIf;
	
	// Attempting to write a new or modified infobase user.
	Try
		UsersInternal.WriteInfobaseUser(InfobaseUser, IsExternalUser);
	Except
		ErrorInformation = ErrorInfo();
		ErrorDescription = ErrorDescriptionOnWriteIBUser(
			NStr("ru = 'При записи пользователя информационной базы
			           |%1 произошла ошибка:
			           |
			           |%2.'; 
			           |en = 'Cannot save infobase user
			           |%1. Reason:
			           |
			           |%2'; 
			           |pl = 'Podczas nagrywania użytkownika bazy informacyjnej 
			           |%1 wystąpił błąd:
			           |
			           |%2.';
			           |de = 'Beim Anmelden des Benutzers der Informationsbasis 
			           |%1 ist ein Fehler aufgetreten:
			           |
			           |%2.';
			           |ro = 'La înregistrarea utilizatorului bazei de informații
			           |%1 s-a produs eroarea:
			           |
			           |""%2"".';
			           |tr = 'Veritabanı%1 
			           |kullanıcısı kaydedilirken, bir hata oluştu: 
			           |%2 "
".'; 
			           |es_ES = 'Al guardar un usuario de la base de información 
			           |%1 se ha producido un error:
			           |
			           |%2.'"),
			InfobaseUser.Name,
			?(PreliminaryRead, PreviousProperties.UUID, Undefined),
			ErrorInformation);
		Return False;
	EndTry;
	
	If ValueIsFilled(PreviousProperties.Name)
	   AND PreviousProperties.Name <> NewProperties.Name Then
		// Copying settings.
		UsersInternal.CopyUserSettings(
			PreviousProperties.Name, NewProperties.Name, True);
	EndIf;
	
	If CreateNew = Undefined Or CreateNew = True Then
		UsersInternal.SetInitialSettings(InfobaseUser.Name, IsExternalUser);
	EndIf;
	
	UsersOverridable.OnWriteInfobaseUser(PreviousProperties, NewProperties);
	
	PropertiesToUpdate.Insert("UUID", InfobaseUser.UUID);
	User = InfobaseUser;
	Return True;
	
EndFunction

#EndRegion

#EndRegion

#Region Private

// Generates a brief error description for displaying to users and also writes error details to the 
// event log if WriteToLog is True.
//
// Parameters:
//  ErrorTemplate - template that contains parameter %1 for infobase user presentation and parameter 
//                       %2 for error description.
//
//  Username - the user name for infobase authentication.
//
//  IBUserID - Undefined, UUID.
//
//  ErrorInformation - ErrorInformation.
//
//  WriteToLog - Boolean. If True, write an error description to the event log.
//                       
//
// Returns:
//  String - an error description displayed to end users.
//
Function ErrorDescriptionOnWriteIBUser(ErrorTemplate,
                                              Username,
                                              IBUserID,
                                              ErrorInformation = Undefined,
                                              WriteToLog = True)
	
	If WriteToLog Then
		WriteLogEvent(
			NStr("ru = 'Пользователи.Ошибка записи пользователя ИБ'; en = 'Users.Error writing infobase user'; pl = 'Użytkownicy Błąd podczas rejestrowania użytkownika IB';de = 'Benutzer.Fehler beim Aufzeichnen des Benutzers der IB';ro = 'Utilizatori.Eroare de înregistrare a utilizatorului BI';tr = 'Kullanıcılar. VT kullanıcı kayıt hatası'; es_ES = 'Usuarios.Error al guardar el usuario de la BI'",
			     Common.DefaultLanguageCode()),
			EventLogLevel.Error,
			,
			,
			StringFunctionsClientServer.SubstituteParametersToString(ErrorTemplate,
				"""" + Username + """ (" + ?(ValueIsFilled(IBUserID),
					NStr("ru = 'Новый'; en = 'New'; pl = 'Nowy';de = 'Neu';ro = 'Nou';tr = 'Yeni'; es_ES = 'Nuevo'"), String(IBUserID)) + ")",
				?(TypeOf(ErrorInformation) = Type("ErrorInfo"),
					DetailErrorDescription(ErrorInformation), String(ErrorInformation))));
	EndIf;
	
	Return StringFunctionsClientServer.SubstituteParametersToString(ErrorTemplate, """" + Username + """",
		?(TypeOf(ErrorInformation) = Type("ErrorInfo"),
			BriefErrorDescription(ErrorInformation), String(ErrorInformation)));
	
EndFunction

// This method is required by IsFullUser and RolesAvailable functions.

Function CheckedIBUserProperties(User)
	
	CurrentIBUserProperties = UsersInternalCached.CurrentIBUserProperties();
	InfobaseUser = Undefined;
	
	If TypeOf(User) = Type("InfoBaseUser") Then
		InfobaseUser = User;
		
	ElsIf User = Undefined Or User = AuthorizedUser() Then
		Return CurrentIBUserProperties;
	Else
		// User passed to the function is not the current user.
		If ValueIsFilled(User) Then
			IBUserID = Common.ObjectAttributeValue(User, "IBUserID");
			If CurrentIBUserProperties.UUID = IBUserID Then
				Return CurrentIBUserProperties;
			EndIf;
			InfobaseUser = InfoBaseUsers.FindByUUID(IBUserID);
		EndIf;
	EndIf;
	
	If InfobaseUser = Undefined Then
		Return Undefined;
	EndIf;
	
	If CurrentIBUserProperties.UUID = InfobaseUser.UUID Then
		Return CurrentIBUserProperties;
	EndIf;
	
	Properties = New Structure;
	Properties.Insert("IsCurrentIBUser", False);
	Properties.Insert("InfobaseUser", InfobaseUser);
	
	Return Properties;
	
EndFunction

#EndRegion
