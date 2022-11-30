///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Internal

// Returns the string of the day, days kind.
//
// Parameters:
//   Number - Number - an integer to which to add numeration item.
//   FormatString - String - see the parameter of the same name of the NumberInWords method, for 
//                                          example, DE=True.
//   NumerationItemParameters - String - see the parameter of the same name of the NumberInWords 
//                                          method, for example, NStr("en= day, days,,,0'").
//
//  Returns:
//   String.
//
Function IntegerSubject(Number, FormatString, NumerationItemParameters) Export
	
	Integer = Int(Number);
	
	NumberInWords = NumberInWords(Integer, FormatString, NStr("ru = ',,,,,,,,0'; en = ',,,,,,,,0'; pl = ',,,,,,,,0';de = ',,,,,,,,0';ro = ',,,,,,,,0';tr = ',,,,,,,,0'; es_ES = ',,,,,,,,0'"));
	
	SubjectAndNumberInWords = NumberInWords(Integer, FormatString, NumerationItemParameters);
	
	Return StrReplace(SubjectAndNumberInWords, NumberInWords, "");
	
EndFunction

#EndRegion

#Region Private

// Generates the user name based on the  full name.
Function GetIBUserShortName(Val FullName) Export
	
	Separators = New Array;
	Separators.Add(" ");
	Separators.Add(".");
	
	ShortName = "";
	For Counter = 1 To 3 Do
		
		If Counter <> 1 Then
			ShortName = ShortName + Upper(Left(FullName, 1));
		EndIf;
		
		SeparatorPosition = 0;
		For each Separator In Separators Do
			CurrentSeparatorPosition = StrFind(FullName, Separator);
			If CurrentSeparatorPosition > 0
			   AND (    SeparatorPosition = 0
			      OR SeparatorPosition > CurrentSeparatorPosition ) Then
				SeparatorPosition = CurrentSeparatorPosition;
			EndIf;
		EndDo;
		
		If SeparatorPosition = 0 Then
			If Counter = 1 Then
				ShortName = FullName;
			EndIf;
			Break;
		EndIf;
		
		If Counter = 1 Then
			ShortName = Left(FullName, SeparatorPosition - 1);
		EndIf;
		
		FullName = Right(FullName, StrLen(FullName) - SeparatorPosition);
		While Separators.Find(Left(FullName, 1)) <> Undefined Do
			FullName = Mid(FullName, 2);
		EndDo;
	EndDo;
	
	Return ShortName;
	
EndFunction

// For the Users and ExternalUsers catalogs item form.
Procedure UpdateLifetimeRestriction(Form) Export
	
	Items = Form.Items;
	
	Items.ChangeAuthorizationRestriction.Visible =
		Items.IBUserProperies.Visible AND Form.AccessLevel.ListManagement;
	
	If Not Items.IBUserProperies.Visible Then
		Items.CanSignIn.Title = "";
		Return;
	EndIf;
	
	Items.ChangeAuthorizationRestriction.Enabled = Form.AccessLevel.AuthorizationSettings;
	
	TitleWithRestriction = "";
	
	If Form.UnlimitedValidityPeriod Then
		TitleWithRestriction = NStr("ru = 'Вход в программу разрешен (без ограничения срока)'; en = 'Can sign in (no expiration period)'; pl = 'Wejście do programu jest dozwolone (bez ograniczeń czasowych)';de = 'Der Login in das Programm ist erlaubt (zeitlich unbegrenzt).';ro = 'Intrarea în program este permisă (fără restricționarea termenului)';tr = 'Uygulamaya giriş yasaklandı (süre kısıtlaması olmadan)'; es_ES = 'La entrada en el programa está permitida (sin restricción del período)'");
		
	ElsIf ValueIsFilled(Form.ValidityPeriod) Then
		TitleWithRestriction = StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = 'Вход в программу разрешен (до %1)'; en = 'Can sign in (till %1)'; pl = 'Logowanie do programu jest dozwolone (do %1)';de = 'Der Login in das Programm ist erlaubt (bis %1)';ro = 'Intrarea în program este permisă (până la %1)';tr = 'Uygulamaya girişe izin verildi (%1 kadar)'; es_ES = 'La entrada en el programa está permitida (hasta %1)'"),
			Format(Form.ValidityPeriod, "DLF=D"));
			
	ElsIf ValueIsFilled(Form.InactivityPeriodBeforeDenyingAuthorization) Then
		TitleWithRestriction = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Вход в программу разрешен (запретить, если не работает более %1)'; en = 'Can sign in (revoke access after inactivity period: %1)'; pl = 'Wejście do programu jest dozwolone (zabroń, jeśli nie pracuje ponad %1)';de = 'Der Login in das Programm ist erlaubt (verboten, wenn es seit %1 nicht mehr arbeitet)';ro = 'Intrarea în program este permisă (interzice, dacă nu lucrează mai mult de %1)';tr = 'Uygulamaya girişe izin verildi (%1''den fazla çalışmaması durumunda yasakla)'; es_ES = 'La entrada en el programa está permitida (prohibir si no lo usa más de %1)'"),
			Format(Form.InactivityPeriodBeforeDenyingAuthorization, "NG=") + " "
				+ IntegerSubject(Form.InactivityPeriodBeforeDenyingAuthorization,
					"", NStr("ru = 'день,дня,дней,,,,,,0'; en = 'day,days,,,0'; pl = 'dzień, dni,,,0';de = 'Tag, Tag, Tage ,,,,,, 0';ro = 'zi,zile,zile,,,,,,0';tr = 'gün, gün, gün,,,,,,0'; es_ES = 'día,días,,,0'")));
	EndIf;
	
	If ValueIsFilled(TitleWithRestriction) Then
		Items.CanSignIn.Title = TitleWithRestriction;
		Items.ChangeAuthorizationRestriction.Title = NStr("ru = 'Изменить ограничение'; en = 'Edit authentication restrictions'; pl = 'Edytuj ograniczenia uwierzytelniania';de = 'Einschränkung der Änderung';ro = 'Modificați restricțiile de autentificare';tr = 'Kısıtlamayı değiştir'; es_ES = 'Cambiar la restricción'");
	Else
		Items.CanSignIn.Title = "";
		Items.ChangeAuthorizationRestriction.Title = NStr("ru = 'Установить ограничение'; en = 'Set authentication restriction'; pl = 'Ustaw ograniczenie';de = 'Setzen Sie ein Limit';ro = 'Stabilire restricția';tr = 'Kısıtla'; es_ES = 'Establecer la restricción'");
	EndIf;
	
EndProcedure

// For the Users and ExternalUsers catalogs item form.
Procedure CheckPasswordSet(Form, PasswordSet, AuthorizedUser) Export
	
	Items = Form.Items;
	
	If PasswordSet Then
		Items.PasswordExistsLabel.Title = NStr("ru = 'Пароль установлен'; en = 'The password is set.'; pl = 'Hasło ustawione';de = 'Passwort gesetzt';ro = 'Parola este instalată';tr = 'Şifre belirlendi'; es_ES = 'Contraseña establecida'");
		Items.UserMustChangePasswordOnAuthorization.Title =
			NStr("ru = 'Потребовать смену пароля при входе'; en = 'Require password change upon authorization'; pl = 'Wymagaj zmiany hasła po zalogowaniu';de = 'Passwortänderung bei der Anmeldung anfordern';ro = 'Cere modificarea parolei la autentificare';tr = 'Oturum açma sırasında şifre değişikliği talep et'; es_ES = 'Requerir el cambio de la contraseña al entrar'");
	Else
		Items.PasswordExistsLabel.Title = NStr("ru = 'Пустой пароль'; en = 'Blank password'; pl = 'Puste hasło';de = 'Leeres Passwort';ro = 'Parola necompletată';tr = 'Boş şifre'; es_ES = 'Contraseña vacía'");
		Items.UserMustChangePasswordOnAuthorization.Title =
			NStr("ru = 'Потребовать установку пароля при входе'; en = 'Require to set a password upon authorization'; pl = 'Wymagaj ustawianie hasła podczas logowania';de = 'Erfordert Passworteinstellung bei der Anmeldung';ro = 'Cere instalarea parolei la intrare';tr = 'Oturum açma sırasında şifre belirlenmesini talep et'; es_ES = 'Requerir especificar la contraseña al entrar'");
	EndIf;
	
	If PasswordSet
	   AND Form.Object.Ref = AuthorizedUser Then
		
		Items.ChangePassword.Title = NStr("ru = 'Сменить пароль...'; en = 'Change password...'; pl = 'Zmień hasło...';de = 'Ändern Sie das Passwort...';ro = 'Modificare parolă...';tr = 'Şifreyi değiştir...'; es_ES = 'Cambiar la contraseña...'");
	Else
		Items.ChangePassword.Title = NStr("ru = 'Установить пароль...'; en = 'Set password...'; pl = 'Ustaw hasło...';de = 'Ein Passwort festlegen...';ro = 'Setare parolă...';tr = 'Şifreyi belirle...'; es_ES = 'Establecer la contraseña...'");
	EndIf;
	
EndProcedure

// For internal use only.
Function CurrentUser(AuthorizedUser) Export
	
	If TypeOf(AuthorizedUser) <> Type("CatalogRef.Users") Then
		Raise
			NStr("ru = 'Невозможно получить текущего пользователя
			           |в сеансе внешнего пользователя.'; 
			           |en = 'Cannot get the current external user
			           |in the external user session.'; 
			           |pl = 'Nie można uzyskać bieżącego użytkownika
			           |w sesji użytkownika zewnętrznego.';
			           |de = 'Der aktuelle Benutzer
			           |kann in einer externen Benutzersitzung nicht abgerufen werden.';
			           |ro = 'Nu puteți obține utilizatorul curent
			           |în sesiunea utilizatorului extern.';
			           |tr = 'Geçerli 
			           |kullanıcı harici kullanıcı oturumunda alınamıyor.'; 
			           |es_ES = 'No se puede obtener el usuario actual
			           |en la sesión del usuario externo.'");
	EndIf;
	
	Return AuthorizedUser;
	
EndFunction

// For internal use only.
Function CurrentExternalUser(AuthorizedUser) Export
	
	If TypeOf(AuthorizedUser) <> Type("CatalogRef.ExternalUsers") Then
		Raise
			NStr("ru = 'Невозможно получить текущего внешнего пользователя
			           |в сеансе пользователя.'; 
			           |en = 'Cannot get the current external user
			           |in the user session.'; 
			           |pl = 'Nie można uzyskać bieżącego użytkownika zewnętrznego 
			           |w sesji użytkownika.';
			           |de = 'Es ist nicht möglich, den aktuellen externen Benutzer
			           |in einer Benutzersitzung zu erhalten.';
			           |ro = 'Nu puteți obține utilizatorul curent extern
			           |în sesiunea utilizatorului.';
			           |tr = 'Geçerli harici kullanıcı, 
			           | kullanıcı oturumunda alınamıyor.'; 
			           |es_ES = 'No se puede obtener el usuario externo actual
			           |en la sesión del usuario.'");
	EndIf;
	
	Return AuthorizedUser;
	
EndFunction

#EndRegion
