///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region EventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	User = Parameters.User;
	ServiceUserPassword = Parameters.ServiceUserPassword;
	OldEmail = Parameters.OldEmail;
	
EndProcedure

#EndRegion

#Region FormCommandHandlers

&AtClient
Procedure ChangeEmailAddress(Command)
	
	If Not CheckFilling() Then
		Return;
	EndIf;
	
	QuestionText = "";
	If Not ValueIsFilled(OldEmail) Then
		QuestionText =
			NStr("ru = 'Адрес электронной почты пользователя сервиса изменен.
			           |Владельцы и администраторы абонента больше не смогут изменять параметры пользователя.'; 
			           |en = 'The email address of the service user is changed.
			           |Subscriber owners and administrators cannot change the user parameters from now on.'; 
			           |pl = 'Adres e-mail użytkownika usługi został zmieniony.
			           |Właściciele lub administratorzy abonamentu nie będą już mogli zmieniać parametrów użytkownika.';
			           |de = 'Die E-Mail-Adresse des Servicebenutzers wird geändert. 
			           |Die Abonnentenbesitzer oder Administratoren können die Benutzerparameter nicht mehr ändern.';
			           |ro = 'Adresa de e-mail a utilizatorului serviciului este modificată.
			           |Proprietarii sau administratorii abonatului nu vor mai putea schimba parametrii utilizatorului.';
			           |tr = 'Servis kullanıcısının e-posta adresi değişti. 
			           |Abone sahipleri veya yöneticileri artık kullanıcı parametrelerini değiştiremez.'; 
			           |es_ES = 'Dirección de correo electrónico del usuario de servicio se ha cambiado.
			           |Propietarios del suscriptor o administradores no podrán cambiar los parámetros de usuario más.'")
			+ Chars.LF
			+ Chars.LF;
	EndIf;
	QuestionText = QuestionText + NStr("ru = 'Выполнить изменение адреса электронной почты?'; en = 'Do you want to change the email address?'; pl = 'Zamienić adres e-mail?';de = 'Ändern Sie die E-Mail-Adresse?';ro = 'Modificați adresa de e-mail?';tr = 'E-posta adresini değiştirmek istiyor musunuz?'; es_ES = '¿Cambiar la dirección de correo electrónico?'");
	
	ShowQueryBox(
		New NotifyDescription("ChangeEmailFollowUp", ThisObject),
		QuestionText,
		QuestionDialogMode.YesNoCancel);
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure CreateEmailAddressChangeRequest()
	
	SSLSubsystemsIntegration.OnCreateRequestToChangeEmail(NewEmailAddress,
		User, ServiceUserPassword);
	
EndProcedure

&AtClient
Procedure ChangeEmailFollowUp(Response, Context) Export
	
	If Response = DialogReturnCode.Yes Then
		
		Try
			CreateEmailAddressChangeRequest();
		Except
			ServiceUserPassword = "";
			AttachIdleHandler("CloseForm", 0.1, True);
			Raise;
		EndTry;
		
		ShowMessageBox(
			New NotifyDescription("ChangeEmailAddressCompletion", ThisObject, Context),
			NStr("ru = 'На указанный адрес отправлено письмо с запросом на подтверждение.
			           |Почта будет изменена только после подтверждения запроса пользователем.'; 
			           |en = 'A confirmation request is sent to the specified email address.
			           |The email address will be changed after the confirmation.'; 
			           |pl = 'E-mail z prośbą o potwierdzenie został wysłany na podany adres.
			           |Adres e-mail zostanie zmieniony dopiero po potwierdzeniu zgłoszenia przez użytkownika.';
			           |de = 'Die E-Mail mit der Bestätigungsanfrage wurde an die angegebene Adresse gesendet. 
			           |Die E-Mail wird erst geändert, nachdem die Anfrage von einem Benutzer bestätigt wurde.';
			           |ro = 'E-mailul cu solicitare de confirmare a fost trimis la adresa specificată.
			           |E-mailul va fi modificat numai după confirmarea din partea utilizatorului.';
			           |tr = 'Onay talebini içeren eposta belirtilen adrese gönderildi. 
			           |E-posta, yalnızca bir kullanıcının talebi onaylandıktan sonra değiştirilecektir.'; 
			           |es_ES = 'El correo electrónico con la solicitud de confirmación se ha enviado a la dirección especificada.
			           |Correo electrónico se cambiará solo después de la confirmación de la solicitud por un usuario.'"));
		
	ElsIf Response = DialogReturnCode.No Then
		ChangeEmailAddressCompletion(Context);
	EndIf;
	
EndProcedure

&AtClient
Procedure ChangeEmailAddressCompletion(Context) Export
	
	Close();
	
EndProcedure

&AtClient
Procedure CloseForm()
	
	Close(ServiceUserPassword);
	
EndProcedure

#EndRegion
