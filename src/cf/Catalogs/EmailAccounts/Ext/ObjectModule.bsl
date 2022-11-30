///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure Filling(FillingData, FillingText, StandardProcessing)
	
	FillObjectWithDefaultValues();
	
EndProcedure

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	If Not UseForSending AND Not UseForReceiving Then
		CheckedAttributes.Clear();
		CheckedAttributes.Add("Description");
		Return;
	EndIf;
	
	NotCheckedAttributeArray = New Array;
	
	If Not UseForSending Then
		NotCheckedAttributeArray.Add("OutgoingMailServer");
	EndIf;
	
	If Not UseForReceiving AND ProtocolForIncomingMail = "POP" Then
		NotCheckedAttributeArray.Add("IncomingMailServer");
	EndIf;
		
	If Not IsBlankString(EmailAddress) AND Not CommonClientServer.EmailAddressMeetsRequirements(EmailAddress, True) Then
		Common.MessageToUser(
			NStr("ru = 'Почтовый адрес заполнен неверно.'; en = 'Invalid email address.'; pl = 'Nieprawidłowy adres pocztowy.';de = 'Falsche Postdresse.';ro = 'Adresă poștală incorectă.';tr = 'Yanlış posta adresi'; es_ES = 'Dirección postal incorrecta.'"), ThisObject, "EmailAddress");
		NotCheckedAttributeArray.Add("EmailAddress");
		Cancel = True;
	EndIf;
	
	Common.DeleteNotCheckedAttributesFromArray(CheckedAttributes, NotCheckedAttributeArray);
	
EndProcedure

Procedure BeforeDelete(Cancel)
	If DataExchange.Load Then
		Return;
	EndIf;
	
	SetPrivilegedMode(True);
	Common.DeleteDataFromSecureStorage(Ref);
	SetPrivilegedMode(False);
EndProcedure

Procedure BeforeWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	If User <> TrimAll(User) Then
		User = TrimAll(User);
	EndIf;
	
	If SMTPUser <> TrimAll(SMTPUser) Then
		SMTPUser = TrimAll(SMTPUser);
	EndIf;
	
	If Not AdditionalProperties.Property("DoNotCheckSettingsForChanges") AND Not Ref.IsEmpty() Then
		PasswordCheckIsRequired = Catalogs.EmailAccounts.PasswordCheckIsRequired(Ref, ThisObject);
		If PasswordCheckIsRequired Then
			PasswordCheck = Undefined;
			If Not AdditionalProperties.Property("Password", PasswordCheck) Or Not PasswordCorrect(PasswordCheck) Then
				ErrorMessageText = NStr("ru = 'Не подтвержден пароль для изменения настроек учетной записи.'; en = 'The password required to change the account settings is not confirmed.'; pl = 'Nie potwierdzono hasła do zmiany ustawień konta.';de = 'Nicht bestätigtes Passwort zum Ändern der Kontoeinstellungen.';ro = 'Nu este confirmată parola pentru modificarea setărilor contului.';tr = 'Hesap ayarlarını değiştirmek için şifre doğrulanmadı.'; es_ES = 'No está comprobada la contraseña para cambiar los ajustes de la cuenta.'");
				Raise ErrorMessageText;
			EndIf;
		EndIf;
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

Procedure FillObjectWithDefaultValues() Export
	
	UserName = NStr("ru = '1С:Предприятие'; en = '1C:Enterprise'; pl = '1C:Enterprise';de = '1C:Enterprise';ro = '1C:Enterprise';tr = '1C:Enterprise'; es_ES = '1C:Empresa'");
	UseForReceiving = False;
	UseForSending = False;
	KeepMessageCopiesAtServer = False;
	KeepMailAtServerPeriod = 0;
	Timeout = 30;
	IncomingMailServerPort = 110;
	OutgoingMailServerPort = 25;
	ProtocolForIncomingMail = "POP";
	
	If Predefined Then
		Description = NStr("ru = 'Системная учетная запись'; en = 'System account'; pl = 'Systemowy zapis ewidencyjny';de = 'System-Benutzerkonto';ro = 'Contul de sistem';tr = 'Sistem hesabı'; es_ES = 'Cuenta de sistema'");
	EndIf;
	
EndProcedure

Function PasswordCorrect(PasswordCheck)
	SetPrivilegedMode(True);
	Passwords = Common.ReadDataFromSecureStorage(Ref, "Password,SMTPPassword");
	SetPrivilegedMode(False);
	
	PasswordsToCheck = New Array;
	If ValueIsFilled(Passwords.Password) Then
		PasswordsToCheck.Add(Passwords.Password);
	EndIf;
	If ValueIsFilled(Passwords.SMTPPassword) Then
		PasswordsToCheck.Add(Passwords.SMTPPassword);
	EndIf;
	
	For Each PasswordToCheck In PasswordsToCheck Do
		If PasswordCheck <> PasswordToCheck Then
			Return False;
		EndIf;
	EndDo;
	
	Return True;
EndFunction

#EndRegion

#Else
Raise NStr("ru = 'Недопустимый вызов объекта на клиенте.'; en = 'Invalid object call on the client.'; pl = 'Niedozwolone wezwanie obiektu na kliencie.';de = 'Unzulässiger Objektaufruf auf dem Client.';ro = 'Apel inadmisibil al obiectului pe client.';tr = 'İstemcide kabul edilmeyen nesne çağrısı.'; es_ES = 'Llamada no disponible del objeto en el cliente.'");
#EndIf