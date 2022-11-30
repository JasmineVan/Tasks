///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Public

// Returns a flag that shows whether external users are enabled  in the application (the 
// UseExternalUsers functional option value).
//
// Returns:
//  Boolean - if True, external users are allowed.
//
Function UseExternalUsers() Export
	
	Return GetFunctionalOption("UseExternalUsers");
	
EndFunction

// Returns the current external user.
//  It is recommended that you use the function in a script fragment that supports external users only.
//
//  If the current user is not external, throws an exception.
//
// Returns:
//  CatalogRef.ExternalUsers - an external user.
//
Function CurrentExternalUser() Export
	
	Return UsersInternalClientServer.CurrentExternalUser(
		Users.AuthorizedUser());
	
EndFunction

// Returns a reference to the external user authorization object from the infobase.
// Authorization object is a reference to an infobase object (for example, a counterparty, an 
// individual, and others) associated with an external user.
//
// Parameters:
//  ExternalUser - Undefined - the current external user.
//                      - CatalogRef.ExternalUsers - the specified external user.
//
// Returns:
//  Ref - authorization object of one of the types specified in the property
//           "Metadata.Catalogs.ExternalUsers.Attributes.AuthorizationObjects.Type".
//
Function GetExternalUserAuthorizationObject(ExternalUser = Undefined) Export
	
	If ExternalUser = Undefined Then
		ExternalUser = CurrentExternalUser();
	EndIf;
	
	AuthorizationObject = Common.ObjectAttributesValues(ExternalUser, "AuthorizationObject").AuthorizationObject;
	
	If ValueIsFilled(AuthorizationObject) Then
		If UsersInternal.AuthorizationObjectIsInUse(AuthorizationObject, ExternalUser) Then
			Raise StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'Ошибка в базе данных:
				           |Объект авторизации ""%1"" (%2)
				           |установлен для нескольких внешних пользователей.'; 
				           |en = 'Database error:
				           |Authorization object ""%1"" (%2)
				           |is set for multiple external users.'; 
				           |pl = 'Błąd bazy danych:
				           |Obiekt autoryzacji ""%1"" (%2)
				           |jest ustawiony dla kilku użytkowników zewnętrznych.';
				           |de = 'Datenbankfehler: 
				           |Das Autorisierungsobjekt ""%1"" (%2) 
				           | ist für mehrere externe Benutzer eingestellt.';
				           |ro = 'Eroare în baza de date: 
				           |Obiectul de autorizare ""%1"" (%2) 
				           |este setat pentru mai mulți utilizatori externi.';
				           |tr = 'Veritabanı hatası: 
				           |Yetkilendirme nesnesi "
" (%1) birkaç %2 harici kullanıcı için ayarlanmıştır.'; 
				           |es_ES = 'Error de la base de datos:
				           |Objeto de autorización ""%1"" (%2)
				           |está establecido para varios usuarios externos.'"),
				AuthorizationObject,
				TypeOf(AuthorizationObject));
		EndIf;
	Else
		Raise StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Ошибка в базе данных:
			           |Для внешнего пользователя ""%1"" не задан объект авторизации.'; 
			           |en = 'Database error:
			           |No authorization object is specified for external user ""%1"".'; 
			           |pl = 'Błąd w bazie danych: 
			           |Dla zewnętrznego użytkownika ""%1"" nie jest zadany autoryzacji.';
			           |de = 'Fehler in der Datenbank:
			           |Dem externen Benutzer ""%1"" ist kein Berechtigungsobjekt zugeordnet.';
			           |ro = 'Eroare în baza de date: 
			           |Pentru utilizatorul extern ""%1"" nu este setat obiectul de autorizare.';
			           |tr = 'Veritabanı hatası: %1"
" Harici kullanıcı için yetkilendirme nesnesi ayarlanmamış.'; 
			           |es_ES = 'Error de la base de datos:
			           |Para el usuario externo ""%1"" el objeto de autorización no está establecido.'"),
			ExternalUser);
	EndIf;
	
	Return AuthorizationObject;
	
EndFunction

// It specifies how external users listed as authorization objects in the ExternalUsers catalog are 
// displayed in catalog lists (partners, respondents, and others).
//
// Parameters:
//  Form - ManagedForm - calling object.
//
Procedure ShowExternalUsersListView(Form) Export
	
	If AccessRight("Read", Metadata.Catalogs.ExternalUsers) Then
		Return;
	EndIf;
	
	// Hiding unavailable information items.
	QuerySchema = New QuerySchema;
	QuerySchema.SetQueryText(Form.List.QueryText);
	Sources = QuerySchema.QueryBatch[0].Operators[0].Sources;
	For Index = 0 To Sources.Count() - 1 Do
		If Sources[Index].Source.TableName = "Catalog.ExternalUsers" Then
			Sources.Delete(Index);
		EndIf;
	EndDo;
	Form.List.QueryText = QuerySchema.GetQueryText();
	
EndProcedure

#EndRegion
