///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Variables

&AtClient
Var ParametersBeforeWrite;

#EndRegion

#Region EventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.LockOwner Then
		WindowOpeningMode = FormWindowOpeningMode.LockOwnerWindow;
	EndIf;
	
	CanReceiveEmails = EmailOperationsInternal.SubsystemSettings().CanReceiveEmails;
	
	Items.UseAccount.ShowTitle = CanReceiveEmails;
	Items.ForReceiving.Visible = CanReceiveEmails;
	Items.KeepMessagesOnServer.Visible = Object.ProtocolForIncomingMail = "POP" AND CanReceiveEmails;
	
	If Not CanReceiveEmails Then
		Items.ForSending.Title = NStr("ru = 'Использовать для отправки писем'; en = 'Use this account to send mail'; pl = 'Używaj do wysyłania wiadomości';de = 'Verwendung zum Versenden von E-Mails';ro = 'Utilizare pentru trimiterea scrisorilor';tr = 'E-posta göndermek için kullan'; es_ES = 'Usar para enviar el correo'");
	EndIf;
	
	Items.IncomingMailServer.Title = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("ru = 'Сервер %1'; en = '%1 server'; pl = 'Serwer %1';de = 'Server %1';ro = 'Server %1';tr = 'Sunucu%1'; es_ES = 'Servidor %1'"), Object.ProtocolForIncomingMail);
	
	If Object.Ref.IsEmpty() Then
		Object.UseForSending = True;
		Object.UseForReceiving = CanReceiveEmails;
	EndIf;
	
	DeleteMailFromServer = Object.KeepMailAtServerPeriod > 0;
	If Not DeleteMailFromServer Then
		Object.KeepMailAtServerPeriod = 10;
	EndIf;
	
	If NOT Object.Ref.IsEmpty() Then
		SetPrivilegedMode(True);
		Passwords = Common.ReadDataFromSecureStorage(Object.Ref, "Password, SMTPPassword");
		SetPrivilegedMode(False);
		Password = ?(ValueIsFilled(Passwords.Password), ThisObject.UUID, "");
		SMTPPassword = ?(ValueIsFilled(Passwords.SMTPPassword), ThisObject.UUID, "");
		
		If Not Catalogs.EmailAccounts.EditionAllowed(Object.Ref) Then
			ReadOnly = True;
		EndIf;
	EndIf;
	
	Items.FormWriteAndClose.Enabled = Not ReadOnly;
	
	ThisIsPersonalAccount = ValueIsFilled(Object.AccountOwner);
	Items.AccountUser.Enabled = ThisIsPersonalAccount;
	UserAccountKind = ?(ThisIsPersonalAccount, "Personal", "Total");
	Items.AccountAvailabilityGroup.Enabled = Users.IsFullUser();
	AccountOwner = Object.AccountOwner;
	
	POPIsUsed = Object.ProtocolForIncomingMail = "POP";
	AuthorizationRequiredOnSendMail = ValueIsFilled(Object.SMTPUser);
	Items.AuthorizationOnSendMail.Enabled = AuthorizationRequiredOnSendMail;
	SetGroupTypeAuthorizationRequired(ThisObject, POPIsUsed);
	Items.SendBCCToThisAddress.Visible = POPIsUsed;
	
	EncryptOnSendMail = ?(Object.UseSecureConnectionForOutgoingMail, "SSL", "Auto");
	EncryptOnReceiveMail = ?(Object.UseSecureConnectionForIncomingMail, "SSL", "Auto");
	
	AuthorizationMethodOnSendMail = ?(Object.SignInBeforeSendingRequired, "POP", "SMTP");
	
	AttributesRequiringPasswordToChange = Catalogs.EmailAccounts.AttributesRequiringPasswordToChange();
	
EndProcedure

&AtServer
Procedure OnWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	If PasswordChanged Then
		SetPrivilegedMode(True);
		Common.WriteDataToSecureStorage(CurrentObject.Ref, Password);
		Common.WriteDataToSecureStorage(CurrentObject.Ref, Password, "SMTPPassword");
		SetPrivilegedMode(False);
	EndIf;
	
EndProcedure

&AtServer
Procedure FillCheckProcessingAtServer(Cancel, CheckedAttributes)
	If UserAccountKind = "Personal" AND Not ValueIsFilled(Object.AccountOwner) Then 
		Cancel = True;
		MessageText = NStr("ru = 'Не выбран владелец учетной записи.'; en = 'Please select an account owner.'; pl = 'Nie wybrano właściciela konta.';de = 'Der Kontoinhaber ist nicht ausgewählt.';ro = 'Nu este selectat titularul contului.';tr = 'Hesap sahibi seçilmedi.'; es_ES = 'No se ha seleccionado el propietario de la cuenta.'");
		Common.MessageToUser(MessageText, , "Object.AccountOwner");
	EndIf;
EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	CurrentObject.SMTPUser = CurrentObject.User;
	CurrentObject.AdditionalProperties.Insert("Password", PasswordCheck);
EndProcedure

&AtClient
Procedure BeforeClose(Cancel, Exit, WarningText, StandardProcessing)
	NotifyDescription = New NotifyDescription("BeforeCloseConfirmationReceived", ThisObject);
	CommonClient.ShowFormClosingConfirmation(NotifyDescription, Cancel, Exit);
EndProcedure

&AtClient
Procedure BeforeWrite(Cancel, WriteParameters)
	
	FillObjectAttributes();
	
	If Not ChecksBeforeWriteExecuted(WriteParameters) Then
		Cancel = True;
		Return;
	EndIf;
	
EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)
	
	Notify("Write_EmailAccount",,Object.Ref);
	
	If WriteParameters.Property("WriteAndClose") Then
		Close();
	EndIf;
	
	AccountOwner = Object.AccountOwner;
	
	If WriteParameters.Property("CheckSettings") Then
		AttachIdleHandler("ExecuteSettingsCheck", 0.1, True);
	EndIf;
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	SetKeepEmailsAtServerSettingKind();
EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)

	// StandardSubsystems.AccessManagement
	If Common.SubsystemExists("StandardSubsystems.AccessManagement") Then
		ModuleAccessManagement = Common.CommonModule("AccessManagement");
		ModuleAccessManagement.OnReadAtServer(ThisObject, CurrentObject);
	EndIf;
	// End StandardSubsystems.AccessManagement

EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)

	// StandardSubsystems.AccessManagement
	If Common.SubsystemExists("StandardSubsystems.AccessManagement") Then
		ModuleAccessManagement = Common.CommonModule("AccessManagement");
		ModuleAccessManagement.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	EndIf;
	// End StandardSubsystems.AccessManagement

EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure ProtocolOnChange(Item)
	
	If IsBlankString(Object.ProtocolForIncomingMail) Then
		Object.ProtocolForIncomingMail = "IMAP";
	EndIf;
	
	If Object.ProtocolForIncomingMail = "IMAP" Then
		If StrStartsWith(Object.IncomingMailServer, "pop.") Then
			Object.IncomingMailServer = "imap." + Mid(Object.IncomingMailServer, 5);
		EndIf
	Else
		If StrStartsWith(Object.IncomingMailServer, "imap.") Then
			Object.IncomingMailServer = "pop." + Mid(Object.IncomingMailServer, 6);
		EndIf;
	EndIf;
	
	Items.IncomingMailServer.Title = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("ru = 'Сервер %1'; en = '%1 server'; pl = 'Serwer %1';de = 'Server %1';ro = 'Server %1';tr = 'Sunucu%1'; es_ES = 'Servidor %1'"), Object.ProtocolForIncomingMail);
		
	POPIsUsed = Object.ProtocolForIncomingMail = "POP";
	Items.KeepMessagesOnServer.Visible = POPIsUsed AND CanReceiveEmails;
	
	SetGroupTypeAuthorizationRequired(ThisObject, POPIsUsed);
	
	ConnectIncomingMailPort();
	SetKeepEmailsAtServerSettingKind();
	
	Items.SendBCCToThisAddress.Visible = POPIsUsed;
	
EndProcedure

&AtClientAtServerNoContext
Procedure SetGroupTypeAuthorizationRequired(Form, POPIsUsed)
	
	If POPIsUsed Then
		Form.Items.AuthorizationRequiredOnSendMail.Title = NStr("ru = 'При отправке писем требуется авторизация'; en = 'Require authorization to send mail'; pl = 'Do wysyłki listów wymagane jest uwierzytelnienie';de = 'Beim Versenden von E-Mails ist eine Autorisierung erforderlich';ro = 'La trimiterea scrisorilor este necesară autorizare';tr = 'E-posta gönderirken yetkilendirme gereklidir.'; es_ES = 'Se requiere autorización al enviar los correos'");
	Else
		Form.Items.AuthorizationRequiredOnSendMail.Title = NStr("ru = 'При отправке писем требуется авторизация на сервере исходящей почты (SMTP)'; en = 'Require authorization on outgoing (SMTP) mail server to send mail'; pl = 'Podczas wysyłania listów wymagane jest uwierzytelnienie na serwerze poczty wychodzącej (SMTP)';de = 'Beim Versenden von E-Mails ist eine Autorisierung auf dem Postausgangsserver (SMTP) erforderlich';ro = 'La trimiterea scrisorilor este necesară autorizare pe serverul poștei de ieșire (SMTP)';tr = 'E-posta gönderirken, giden posta sunucusunda (SMTP) yetkilendirme gereklidir)'; es_ES = 'Se requiere autorización en el servidor del correo saliente (SMTP) al enviar los correos'");
	EndIf;

	Form.Items.AuthorizationOnSendMail.Visible = POPIsUsed;
	
EndProcedure

&AtClient
Procedure IncomingMailServerOnChange(Item)
	Object.IncomingMailServer = TrimAll(Lower(Object.IncomingMailServer));
EndProcedure

&AtClient
Procedure OutgoingMailServerOnChange(Item)
	Object.OutgoingMailServer = TrimAll(Lower(Object.OutgoingMailServer));
EndProcedure

&AtClient
Procedure EmailAddressOnChange(Item)
	Object.EmailAddress = TrimAll(Object.EmailAddress);
EndProcedure

&AtClient
Procedure KeepEmailCopiesOnServerOnChange(Item)
	SetKeepEmailsAtServerSettingKind();
EndProcedure

&AtClient
Procedure DeleteEmailsFromServerOnChange(Item)
	SetKeepEmailsAtServerSettingKind();
EndProcedure

&AtClient
Procedure PasswordForReceivingEmailsOnChange(Item)
	PasswordChanged = True;
EndProcedure

&AtClient
Procedure PasswordForSendingEmailsOnChange(Item)
	SMTPPasswordChanged = True;
EndProcedure

&AtClient
Procedure AccountOwnerOnChange(Item)
	Items.AccountUser.Enabled = UserAccountKind = "Personal";
	NotifyOfChangesAccountOwner();
EndProcedure

&AtClient
Procedure AccountUserOnChange(Item)
	NotifyOfChangesAccountOwner();
EndProcedure

&AtClient
Procedure AuthorizationRequiredBeforeSendingOnChange(Item)
	Items.Receiving.Enabled = CanReceiveEmails Or Object.SignInBeforeSendingRequired;
EndProcedure

&AtClient
Procedure AuthorizationRequiredOnSendingEmailsOnChange(Item)
	Items.AuthorizationOnSendMail.Enabled = AuthorizationRequiredOnSendMail;
	Items.AuthorizationOnSendMail.Visible = Object.ProtocolForIncomingMail = "POP";
EndProcedure

&AtClient
Procedure EncryptOnSendingEmailsOnChange(Item)
	Object.UseSecureConnectionForOutgoingMail = EncryptOnSendMail = "SSL";
	ConnectOutgoingMailPort();
EndProcedure

&AtClient
Procedure EncryptOnReceivingEmailsOnChange(Item)
	Object.UseSecureConnectionForIncomingMail = EncryptOnReceiveMail = "SSL";
	ConnectIncomingMailPort();
EndProcedure

&AtClient
Procedure AuthorizationMethodForSendingEmailOnChange(Item)
	Object.SignInBeforeSendingRequired = ?(AuthorizationMethodOnSendMail = "POP", True, False);
	SetKeepEmailsAtServerSettingKind();
EndProcedure

&AtClient
Procedure NeedHelpClick(Item)
	
	EmailOperationsClient.GoToEmailAccountInputDocumentation();
	
EndProcedure

#EndRegion

#Region FormCommandHandlers

&AtClient
Procedure WriteAndClose(Command)
	
	Write(New Structure("WriteAndClose"));
	
EndProcedure

&AtClient
Procedure CheckSettings(Command)
	ExecuteSettingsCheck();
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure SetKeepEmailsAtServerSettingKind()
	
	POPIsUsed = Object.ProtocolForIncomingMail = "POP";
	Items.KeepMessagesOnServer.Visible = POPIsUsed AND CanReceiveEmails;
	Items.MailRetentionPeriodSetup.Enabled = Object.KeepMessageCopiesAtServer;
	Items.KeepMailAtServerPeriod.Enabled = DeleteMailFromServer;
	
EndProcedure

&AtClient
Procedure ConnectIncomingMailPort()
	If Object.ProtocolForIncomingMail = "IMAP" Then
		If Object.IncomingMailServerPort = 995 Then
			Object.IncomingMailServerPort = 993;
		EndIf;
	Else
		If Object.IncomingMailServerPort = 993 Then
			Object.IncomingMailServerPort = 995;
		EndIf;
	EndIf;
EndProcedure

&AtClient
Procedure ConnectOutgoingMailPort()
	If Object.UseSecureConnectionForOutgoingMail Then
		If Object.OutgoingMailServerPort = 587 Then
			Object.OutgoingMailServerPort = 465;
		EndIf;
	Else
		If Object.OutgoingMailServerPort = 465 Then
			Object.OutgoingMailServerPort = 587;
		EndIf;
	EndIf;
EndProcedure

&AtClient
Procedure BeforeCloseConfirmationReceived(QuestionResult, AdditionalParameters) Export
	Write(New Structure("WriteAndClose"));
EndProcedure

&AtClient
Procedure NotifyOfChangesAccountOwner()
	Notify("OnChangeEmailAccountKind", UserAccountKind = "Personal", ThisObject);
EndProcedure

&AtClient
Procedure FillObjectAttributes()
	
	If Not DeleteMailFromServer Then
		Object.KeepMailAtServerPeriod = 0;
	EndIf;
	
	If Object.ProtocolForIncomingMail = "IMAP" Then
		Object.KeepMessageCopiesAtServer = True;
		Object.KeepMailAtServerPeriod = 0;
	EndIf;
	
	If UserAccountKind = "Total" AND ValueIsFilled(Object.AccountOwner) Then
		Object.AccountOwner = Undefined;
	EndIf;

EndProcedure

&AtClient
Function ChecksBeforeWriteExecuted(WriteParameters)
	
	ParametersBeforeWrite = WriteParameters;
	
	If Not ParametersBeforeWrite.Property("FillingCheckExecuted") Then
		AttachIdleHandler("CheckFillingAndWrite", 0.1, True);
		Return False;
	EndIf;
	
	If Not ParametersBeforeWrite.Property("PermissionsReceived") Then
		AttachIdleHandler("CheckPermissionsAndWrite", 0.1, True);
		Return False;
	EndIf;
	
	If Not PasswordCheckExecuted(ParametersBeforeWrite) Then
		AttachIdleHandler("InputAccountPasswordAndWrite", 0.1, True);
		Return False;
	EndIf;
	
	Return True;
	
EndFunction

&AtClient
Procedure CheckFillingAndWrite()
	
	If CheckFilling() Then
		ParametersBeforeWrite.Insert("FillingCheckExecuted");
		Write(ParametersBeforeWrite);
	EndIf;
	
EndProcedure

&AtClient
Procedure CheckPermissionsAndWrite()
	
	NotifyDescription = New NotifyDescription("AfterCheckPermissions", ThisObject, ParametersBeforeWrite);
	
	If CommonClient.SubsystemExists("StandardSubsystems.SecurityProfiles") Then
		ModuleSafeModeManagerClient = CommonClient.CommonModule("SafeModeManagerClient");
		ModuleSafeModeManagerClient.ApplyExternalResourceRequests(
			PermissionRequestsToUseExternalResources(), ThisObject, NotifyDescription);
	Else
		ExecuteNotifyProcessing(NotifyDescription, DialogReturnCode.OK);
	EndIf;
	
EndProcedure

&AtServer
Function PermissionRequestsToUseExternalResources()
	
	Query = Undefined;
	
	If Common.SubsystemExists("StandardSubsystems.SecurityProfiles") Then
		ModuleSafeModeManager = Common.CommonModule("SafeModeManager");
		Query = ModuleSafeModeManager.RequestToUseExternalResources(Permissions(), Object.Ref);
	EndIf;
	
	Return CommonClientServer.ValueInArray(Query);
	
EndFunction

&AtServer
Function Permissions()
	
	Result = New Array;
	
	ModuleSafeModeManager = Common.CommonModule("SafeModeManager");
	
	If Object.UseForSending Then
		Result.Add(
			ModuleSafeModeManager.PermissionToUseInternetResource(
				"SMTP",
				Object.OutgoingMailServer,
				Object.OutgoingMailServerPort,
				NStr("ru = 'Электронная почта.'; en = 'Email.'; pl = 'Poczta elektroniczna.';de = 'E-Mail.';ro = 'Poșta electronică.';tr = 'E-posta.'; es_ES = 'Correo electrónico.'")));
	EndIf;
	
	If Object.UseForReceiving Then
		Result.Add(
			ModuleSafeModeManager.PermissionToUseInternetResource(
				Object.ProtocolForIncomingMail,
				Object.IncomingMailServer,
				Object.IncomingMailServerPort,
				NStr("ru = 'Электронная почта.'; en = 'Email.'; pl = 'Poczta elektroniczna.';de = 'E-Mail.';ro = 'Poșta electronică.';tr = 'E-posta.'; es_ES = 'Correo electrónico.'")));
	EndIf;
	
	Return Result;
	
EndFunction

&AtClient
Procedure AfterCheckPermissions(Result, WriteParameters) Export
	
	If Result = DialogReturnCode.OK Then
		WriteParameters.Insert("PermissionsReceived");
		Write(ParametersBeforeWrite);
	EndIf;
	
EndProcedure

&AtClient
Function PasswordCheckExecuted(WriteParameters)
	
	If Not WriteParameters.Property("PasswordEntered") Then
		AttributeValuesBeforeWrite = New Structure(AttributesRequiringPasswordToChange);
		FillPropertyValues(AttributeValuesBeforeWrite, Object);
		Return Not PasswordCheckIsRequired(Object.Ref, AttributeValuesBeforeWrite);
	EndIf;
	
	Return True;
	
EndFunction

&AtServerNoContext
Function PasswordCheckIsRequired(Ref, AttributesValues)
	Return Catalogs.EmailAccounts.PasswordCheckIsRequired(Ref, AttributesValues);
EndFunction

&AtClient
Procedure InputAccountPasswordAndWrite()
	
	PasswordCheck = "";
	NotifyDescription = New NotifyDescription("AfterPasswordEnter", ThisObject, ParametersBeforeWrite);
	OpenForm("Catalog.EmailAccounts.Form.CheckAccountAccess", , ThisObject, , , , NotifyDescription);
	
EndProcedure

&AtClient
Procedure AfterPasswordEnter(Password, WriteParameters) Export
	
	If TypeOf(Password) = Type("String") Then
		PasswordCheck = Password;
		WriteParameters.Insert("PasswordEntered");
		Write(WriteParameters);
	EndIf;
	
EndProcedure

&AtClient
Procedure ExecuteSettingsCheck()
	If Modified Then
		Write(New Structure("CheckSettings"));
	Else
		EmailOperationsClient.CheckAccount(Object.Ref);
	EndIf;
EndProcedure

#EndRegion
