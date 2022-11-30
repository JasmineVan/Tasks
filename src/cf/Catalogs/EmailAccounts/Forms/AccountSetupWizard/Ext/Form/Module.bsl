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
	
	Items.GoToSettingsButton.Visible = False;
	
	If Common.SubsystemExists("StandardSubsystems.SecurityProfiles") Then
		ModuleSafeModeManager = Common.CommonModule("SafeModeManager");
		UseSecurityProfiles = ModuleSafeModeManager.UseSecurityProfiles();
	Else
		UseSecurityProfiles = False;
	EndIf;
	
	Items.SetupMethod.Visible = Not UseSecurityProfiles;
	If UseSecurityProfiles Then
		SetupMethod = "Manually";
	Else
		SetupMethod = "Automatically";
	EndIf;
	
	CanReceiveEmails = EmailOperationsInternal.SubsystemSettings().CanReceiveEmails;
	ContextMode = Parameters.ContextMode;
	Items.UseAccount.Visible = Not ContextMode AND CanReceiveEmails;
	Items.Protocol.Enabled = CanReceiveEmails;
	Items.KeepMessagesOnServer.Visible = CanReceiveEmails;
	
	Items.AccountSettingsTitle.Title = ?(ContextMode,
		NStr("ru = 'Для отправки писем необходимо настроить учетную запись электронной почты'; en = 'To be able to send emails, configure the email account'; pl = 'Aby wysłać wiadomości e-mail, skonfiguruj konto poczty elektronicznej';de = 'Konfigurieren Sie das E-Mail-Konto, um E-Mails zu senden';ro = 'Pentru a trimite e-mailuri, configurați contul de e-mail';tr = 'E-postaları göndermek için e-posta hesabınızı yapılandırın'; es_ES = 'Para enviar correos electrónicos, configurar la cuenta de correo electrónico'"),
		NStr("ru = 'Введите параметры учетной записи'; en = 'Enter account parameters'; pl = 'Wprowadź parametry konta';de = 'Geben Sie die Account-Parameter ein';ro = 'Introduceți parametrii contului';tr = 'Hesap parametrelerini girin'; es_ES = 'Introducir los parámetros de la cuenta'"));
		
	If Not ContextMode Then
		Title = NStr("ru = 'Создание учетной записи электронной почты'; en = 'Create email account'; pl = 'Utwórz konto poczty elektronicznej';de = 'E-Mail-Konto erstellen';ro = 'Creați un cont de e-mail';tr = 'E-posta hesabını oluşturun'; es_ES = 'Crear la cuenta de correo electrónico'");
	Else
		Title = NStr("ru = 'Настройка учетной записи электронной почты'; en = 'Configure email account'; pl = 'Ustawienie konta poczty elektronicznej';de = 'E-Mail-Kontoeinstellung';ro = 'Setarea contului de e-mail';tr = 'E-posta hesabın ayarlanması'; es_ES = 'Configuración de la cuenta de correo electrónico'");
	EndIf;
	
	UseForReceiving = Not ContextMode AND CanReceiveEmails;
	UseForSending = True;
	Items.Pages.CurrentPage = Items.AccountSettings;
	
	WindowOptionsKey = ?(ContextMode, "ContextMode", "NoContextMode");
	
	If Parameters.Property("Key") Then
		AccountRef = Parameters.Key;
		QueryText =
		"SELECT
		|	EmailAccounts.EmailAddress AS EmailAddress,
		|	EmailAccounts.UserName AS EmailSenderName,
		|	EmailAccounts.Description AS AccountName
		|FROM
		|	Catalog.EmailAccounts AS EmailAccounts
		|WHERE
		|	EmailAccounts.Ref = &Ref";
		Query = New Query(QueryText);
		Query.SetParameter("Ref", Parameters.Key);
		Selection = Query.Execute().Select();
		If Selection.Next() Then
			FillPropertyValues(ThisObject, Selection);
		EndIf;
	Else
		NewAccountRef = Catalogs.EmailAccounts.GetRef();
		
		If Common.SubsystemExists("StandardSubsystems.ContactInformation") Then
			ModuleUserContactInformation = Common.CommonModule("ContactsManager");
			UserContactInformation = ModuleUserContactInformation.ObjectContactInformationValues(
				Users.CurrentUser(), Enums["ContactInformationTypes"].EmailAddress);
			For Each Contact In UserContactInformation Do
				Address = Contact.Value;
				If Catalogs.EmailAccounts.FindByAttribute("EmailAddress", Address).IsEmpty() Then
					EmailAddress = Address;
					CurrentItem = Items.Password;
					EmailSenderName = Common.ObjectAttributeValue(Users.CurrentUser(), "Description");
					Break;
				EndIf;
			EndDo;
		EndIf;
	EndIf;
	
	IsFullUser = Users.IsFullUser();
	Items.AccountAvailability.Visible = IsFullUser;
	UserAccountKind = ?(IsFullUser, "Total", "Personal");
	
	AuthorizationRequiredOnSendMail = True;
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	SetCurrentPageItems()
EndProcedure

&AtClient
Procedure BeforeClose(Cancel, Exit, WarningText, StandardProcessing)
	
	If Not FormClosingConfirmationRequired Then
		Return;
	EndIf;
	
	Cancel = True;
	If Exit Then
		Return;
	EndIf;
	
	AttachIdleHandler("ShowQueryBoxBeforeCloseForm", 0.1, True);
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure PasswordOnChange(Item)
	PasswordToSendMail = PasswordForReceivingEmails;
EndProcedure

&AtClient
Procedure KeepEmailCopiesOnServerOnChange(Item)
	RefreshDaysBeforeDeleteEnabled();
EndProcedure

&AtClient
Procedure DeleteEmailsFromServerOnChange(Item)
	RefreshDaysBeforeDeleteEnabled();
EndProcedure

&AtClient
Procedure EmailAddressOnChange(Item)
	SettingsFilled = False;
	FormClosingConfirmationRequired = True;
EndProcedure

&AtClient
Procedure EmailSenderNameOnChange(Item)
	FormClosingConfirmationRequired = True;
EndProcedure

&AtClient
Procedure SetupMethodOnChange(Item)
	SetCurrentPageItems();
EndProcedure

&AtClient
Procedure ProtocolOnChange(Item)
	SetItemsVisibility();
EndProcedure

&AtClient
Procedure EncryptOnSendingEmailsOnChange(Item)
	UseSecureConnectionForOutgoingMail = EncryptOnSendMail = "SSL";
EndProcedure

&AtClient
Procedure EncryptOnReceivingEmailsOnChange(Item)
	UseSecureConnectionForIncomingMail = EncryptOnReceiveMail = "SSL";
EndProcedure

&AtClient
Procedure NeedHelpClick(Item)
	
	EmailOperationsClient.GoToEmailAccountInputDocumentation();
	
EndProcedure

#EndRegion

#Region FormCommandHandlers

&AtClient

Procedure Next(Command)
	
	GotoNextPage();
	
EndProcedure

&AtClient
Procedure Back(Command)
	
	CurrentPage = Items.Pages.CurrentPage;
	
	PreviousPage = Undefined;
	If CurrentPage = Items.OutgoingMailServerSetup Then
		PreviousPage = Items.AccountSettings;
	ElsIf CurrentPage = Items.IncomingMailServerSetup Then
		If UseForSending Then
			PreviousPage = Items.OutgoingMailServerSetup;
		Else
			PreviousPage = Items.AccountSettings;
		EndIf;
	ElsIf CurrentPage = Items.AdditionalSettings Then
		If UseForSending Or UseForReceiving Then
			PreviousPage = Items.IncomingMailServerSetup;
		ElsIf UseForSending Then
			PreviousPage = Items.OutgoingMailServerSetup;
		Else
			PreviousPage = Items.AccountSettings;
		EndIf;
	ElsIf CurrentPage = Items.ValidatingAccountSettings Then
		PreviousPage = Items.AccountSettings;
	EndIf;
	
	If PreviousPage <> Undefined Then
		Items.Pages.CurrentPage = PreviousPage;
	EndIf;
	
	SetCurrentPageItems()
EndProcedure

&AtClient
Procedure Cancel(Command)
	Close(False);
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure ShowQueryBoxBeforeCloseForm()
	QuestionText = NStr("ru = 'Введенные данные не записаны. Закрыть форму?'; en = 'You have unsaved data. Do you want to close the form?'; pl = 'Wprowadzone dane nie zostały zapisane. Zamknąć formularz?';de = 'Eingegebene Daten werden nicht geschrieben. Das Formular schließen?';ro = 'Datele introduse nu sunt scrise. Închideți formularul?';tr = 'Girilen veriler yazılmadı. Form kapatılsın mı?'; es_ES = 'Datos introducidos no se han inscrito. ¿Cerrar el formulario?'");
	NotifyDescription = New NotifyDescription("CloseFormConfirmed", ThisObject);
	Buttons = New ValueList;
	Buttons.Add("Close", NStr("ru = 'Закрыть'; en = 'Close'; pl = 'Zamknij';de = 'Schließen';ro = 'Închideți';tr = 'Kapat'; es_ES = 'Cerrar'"));
	Buttons.Add(DialogReturnCode.Cancel, NStr("ru = 'Не закрывать'; en = 'Do not close'; pl = 'Zostaw otwarte';de = 'Offen halten';ro = 'Nu închide';tr = 'Kapatmayın'; es_ES = 'Dejar abierto'"));
	ShowQueryBox(NotifyDescription, QuestionText, Buttons, , DialogReturnCode.Cancel, NStr("ru = 'Настройка учетной записи'; en = 'Configure account'; pl = 'Ustawienia konta';de = 'Konto-Einstellung';ro = 'Setarea contului';tr = 'Hesap ayarı'; es_ES = 'Configuraciones de la cuenta'"));
EndProcedure

&AtClient
Procedure CloseFormConfirmed(QuestionResult, AdditionalParameters = Undefined) Export
	
	If QuestionResult = DialogReturnCode.Cancel Then
		Return;
	EndIf;
	
	FormClosingConfirmationRequired = False;
	Close(False);
	
EndProcedure

&AtClient
Procedure GotoNextPage()
	
	Cancel = False;
	CurrentPage = Items.Pages.CurrentPage;
	
	NextPage = Undefined;
	If CurrentPage = Items.AccountSettings Then
		CheckFillingOnAccountSettingsPage(Cancel);
		If Not Cancel AND Not SettingsFilled Then
			FillAccountSettings();
		EndIf;
		If SetupMethod = "Automatically" Or ValidationCompletedWithErrors Then
			NextPage = Items.ValidatingAccountSettings;
		Else
			If UseForSending Then
				NextPage = Items.OutgoingMailServerSetup;
			ElsIf UseForReceiving Then
				NextPage = Items.IncomingMailServerSetup;
			Else
				NextPage = Items.AdditionalSettings;
			EndIf;
		EndIf;
	ElsIf CurrentPage = Items.OutgoingMailServerSetup Then
		NextPage = Items.IncomingMailServerSetup;
	ElsIf CurrentPage = Items.IncomingMailServerSetup Then
		NextPage = Items.AdditionalSettings;
	ElsIf CurrentPage = Items.AdditionalSettings Then
		NextPage = Items.ValidatingAccountSettings;
	ElsIf CurrentPage = Items.ValidatingAccountSettings Then
		If ValidationCompletedWithErrors Then
			NextPage = Items.AccountSettings;
		Else
			NextPage = Items.AccountConfigured;
		EndIf;
	EndIf;
	
	If Cancel Then
		Return;
	EndIf;
	
	If NextPage = Undefined Then
		Close(True);
	Else
		Items.Pages.CurrentPage = NextPage;
		SetCurrentPageItems();
	EndIf;
	
	If Items.Pages.CurrentPage = Items.ValidatingAccountSettings Then
		If SetupMethod = "Automatically" Then
			AttachIdleHandler("SetUpConnectionParametersAutomatically", 0.1, True);
		Else
			AttachIdleHandler("ExecuteSettingsCheck", 0.1, True);
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure ExecuteSettingsCheck()
	
	ClosingNotification = New NotifyDescription("CheckSettingsPermissionRequestExecuted", ThisObject);
	If CommonClient.SubsystemExists("StandardSubsystems.SecurityProfiles") Then
		Query = CreateRequestToUseExternalResources();
		
		ModuleSafeModeManagerClient = CommonClient.CommonModule("SafeModeManagerClient");
		ModuleSafeModeManagerClient.ApplyExternalResourceRequests(
			CommonClientServer.ValueInArray(Query), ThisObject, ClosingNotification);
	Else
		ExecuteNotifyProcessing(ClosingNotification, DialogReturnCode.OK);
	EndIf;
	
EndProcedure

&AtClient
Procedure CheckSettingsPermissionRequestExecuted(QueryResult, AdditionalParameters) Export
	If Not QueryResult = DialogReturnCode.OK Then
		Return;
	EndIf;
	
	ValidateAccountSettings();
	If ValueIsFilled(AccountRef) Then 
		NotifyChanged(TypeOf(AccountRef));
	EndIf;
	GotoNextPage();
EndProcedure

&AtServer
Function CreateRequestToUseExternalResources()
	
	ModuleSafeModeManager = Common.CommonModule("SafeModeManager");
	
	Return ModuleSafeModeManager.RequestToUseExternalResources(
		Permissions(), NewAccountRef);
	
EndFunction

&AtServer
Function Permissions()
	
	Result = New Array;
	
	ModuleSafeModeManager = Common.CommonModule("SafeModeManager");
	
	If UseForSending Then
		Result.Add(
			ModuleSafeModeManager.PermissionToUseInternetResource(
				"SMTP",
				OutgoingMailServer,
				OutgoingMailServerPort,
				NStr("ru = 'Электронная почта.'; en = 'Email.'; pl = 'E-mail.';de = 'E-Mail.';ro = 'E-mail.';tr = 'E-posta.'; es_ES = 'Correo electrónico.'")));
	EndIf;
	
	If UseForReceiving Then
		Result.Add(
			ModuleSafeModeManager.PermissionToUseInternetResource(
				Protocol,
				IncomingMailServer,
				IncomingMailServerPort,
				NStr("ru = 'Электронная почта.'; en = 'Email.'; pl = 'E-mail.';de = 'E-Mail.';ro = 'E-mail.';tr = 'E-posta.'; es_ES = 'Correo electrónico.'")));
	EndIf;
	
	Return Result;
	
EndFunction


&AtClient
Procedure CheckFillingOnAccountSettingsPage(Cancel)
	
	ClearMessages();
	
	If IsBlankString(EmailAddress) Then
		CommonClient.MessageToUser(NStr("ru = 'Введите адрес электронной почты'; en = 'Please enter the email address.'; pl = 'Wprowadź adres e-mail';de = 'E-Mail Adresse eingeben';ro = 'Introduceți adresa de e-mail';tr = 'E-posta adresini girin'; es_ES = 'Introducir la dirección de correo electrónico'"), , "EmailAddress", , Cancel);
	ElsIf Not CommonClientServer.EmailAddressMeetsRequirements(EmailAddress, True) Then
		CommonClient.MessageToUser(NStr("ru = 'Адрес электронной почты введен неверно'; en = 'Invalid email address.'; pl = 'Adres email jest nieprawidłowy';de = 'E-Mail Adresse ist nicht korrekt';ro = 'Adresa de email este introdusă incorect';tr = 'E-posta adresi geçersizdir'; es_ES = 'Dirección de correo electrónico es inválida'"), , "EmailAddress", , Cancel);
	EndIf;
	
	If IsBlankString(PasswordForReceivingEmails) Then
		CommonClient.MessageToUser(NStr("ru = 'Необходимо ввести пароль'; en = 'Please enter the password.'; pl = 'Należy wprowadzić hasło';de = 'Passwort muss eingegeben werden';ro = 'Trebuie să introduceți parola';tr = 'Şifre girilmelidir'; es_ES = 'Es necesario introducir la contraseña'"), , "PasswordForReceivingEmails", , Cancel);
	EndIf;
	
EndProcedure

&AtClient
Procedure SetCurrentPageItems()
	
	CurrentPage = Items.Pages.CurrentPage;
	
	// NextButton
	If CurrentPage = Items.AccountConfigured Then
		If ContextMode Then
			ButtonNextTitle = NStr("ru = 'Продолжить'; en = 'Continue'; pl = 'Kontynuuj';de = 'Weiter';ro = 'Continuare';tr = 'Devam'; es_ES = 'Continuar'");
		Else
			ButtonNextTitle = NStr("ru = 'Закрыть'; en = 'Close'; pl = 'Zamknij';de = 'Schließen';ro = 'Închideți';tr = 'Kapat'; es_ES = 'Cerrar'");
		EndIf;
	Else
		If CurrentPage = Items.AccountSettings
			AND ValidationCompletedWithErrors Then
				ButtonNextTitle = NStr("ru = 'Повторить'; en = 'Retry'; pl = 'Powtórz';de = 'Wiederholen';ro = 'Repetare';tr = 'Tekrarla'; es_ES = 'Repetir'");
		ElsIf CurrentPage = Items.AccountSettings
			AND SetupMethod = "Automatically" Then
			If ContextMode Then
				ButtonNextTitle = NStr("ru = 'Настроить'; en = 'Configure'; pl = 'Dostosuj';de = 'Anpassung';ro = 'Setare';tr = 'Ayarla'; es_ES = 'Ajustar'");
			Else
				ButtonNextTitle = NStr("ru = 'Создать'; en = 'Create'; pl = 'Utworzyć';de = 'Erstellen';ro = 'Actualizare';tr = 'Oluştur'; es_ES = 'Crear'");
			EndIf;
		Else
			ButtonNextTitle = NStr("ru = 'Далее >'; en = 'Next >'; pl = 'Dalej >';de = 'Weiter >';ro = 'Următorul >';tr = 'Sonraki >'; es_ES = 'Siguiente >'");
		EndIf;
	EndIf;
	Items.NextButton.Title = ButtonNextTitle;
	Items.NextButton.Enabled = CurrentPage <> Items.ValidatingAccountSettings;
	Items.NextButton.Visible = CurrentPage <> Items.ValidatingAccountSettings;
	
	// BackButton
	Items.BackButton.Visible = CurrentPage <> Items.AccountSettings
		AND CurrentPage <> Items.AccountConfigured
		AND CurrentPage <> Items.ValidatingAccountSettings;
	
	// CancelButton
	Items.CancelButton.Visible = CurrentPage <> Items.AccountConfigured;
	
	// GotoSettingsButton
	Items.GoToSettingsButton.Visible = Not UseSecurityProfiles AND (CurrentPage = Items.AccountSettings
		AND ValidationCompletedWithErrors Or Not ContextMode AND CurrentPage = Items.AccountConfigured);
		
	If Not ContextMode AND CurrentPage = Items.AccountConfigured Then
		Items.GoToSettingsButton.Title = NStr("ru = 'Перейти к учетной записи'; en = 'Go to account'; pl = 'Przejdź do konta';de = 'Zum Konto gehen';ro = 'Du-te la cont';tr = 'Hesaba git'; es_ES = 'Ir a la cuenta'");
	Else
		Items.GoToSettingsButton.Title = NStr("ru = 'Настроить вручную'; en = 'Configure manually'; pl = 'Ustaw ręcznie';de = 'Manuell konfigurieren';ro = 'Setare în mod manual';tr = 'Manuel olarak ayarla'; es_ES = 'Ajustar manualmente'");
	EndIf;
	
	If CurrentPage = Items.AccountSettings Then
		Items.CannotConnectPictureAndLabel.Visible = ValidationCompletedWithErrors;
		Items.SetupMethod.Visible = Not ValidationCompletedWithErrors AND Not UseSecurityProfiles;
	EndIf;
	
	If CurrentPage = Items.IncomingMailServerSetup Then
		RefreshDaysBeforeDeleteEnabled();
		SetItemsVisibility();
	EndIf;
	
	If CurrentPage = Items.AccountConfigured Then
		Items.AccountConfiguredLabel.Title = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Настройка параметров учетной записи
				|%1 завершена.'; 
				|en = 'Configuring account 
				|%1 is completed.'; 
				|pl = 'Ustawienie parametrów konta 
				|%1 zostało zakończone.';
				|de = 'Die Kontoeinstellungen
				|%1 sind abgeschlossen.';
				|ro = 'Setarea parametrilor contului
				|%1este finalizată.';
				|tr = 'Hesap
				| %1 parametresinin ayarı tamamlandı.'; 
				|es_ES = 'Los ajustes de los parámetros de la cuenta
				|%1 se han terminado.'"), EmailAddress);
	EndIf;
	
EndProcedure

&AtClient
Procedure RefreshDaysBeforeDeleteEnabled()
	Items.DeleteMailFromServer.Enabled = KeepEmailCopiesOnServer;
	Items.KeepMailAtServerPeriod.Enabled = DeleteMailFromServer;
EndProcedure

&AtClient
Procedure SetItemsVisibility()
	Items.KeepMessagesOnServer.Visible = Protocol = "POP";
EndProcedure

&AtClient
Procedure GotoSettings(Command)
	CurrentPage = Items.Pages.CurrentPage;
	If Not ContextMode AND CurrentPage = Items.AccountConfigured Then
		ShowValue(,AccountRef);
		Close(True);
	Else
		If SetupMethod = "Automatically" Then
			SetupMethod = "Manually";
		EndIf;
		Items.Pages.CurrentPage = Items.OutgoingMailServerSetup;
		SetCurrentPageItems();
	EndIf;
EndProcedure

&AtClient
Procedure FillAccountSettings()
	FillPropertyValues(ThisObject, DefaultSettings(EmailAddress, PasswordForReceivingEmails));
	If IsBlankString(AccountName) Then
		AccountName = EmailAddress;
	EndIf;

	SettingsFilled = True;
	
	EncryptOnSendMail = ?(UseSecureConnectionForOutgoingMail, "SSL", "Auto");
	EncryptOnReceiveMail = ?(UseSecureConnectionForIncomingMail, "SSL", "Auto");
EndProcedure

&AtServerNoContext
Function DefaultSettings(EmailAddress, Password)
	
	Position = StrFind(EmailAddress, "@");
	ServerNameInAccount = Mid(EmailAddress, Position + 1);
	
	Settings = New Structure;
	
	Settings.Insert("UsernameForReceivingEmails", EmailAddress);
	Settings.Insert("UserNameForSendingEmails", EmailAddress);
	
	Settings.Insert("PasswordToSendMail", Password);
	Settings.Insert("PasswordForReceivingEmails", Password);
	
	Settings.Insert("Protocol", "IMAP");
	Settings.Insert("IncomingMailServer", "imap." + ServerNameInAccount);
	Settings.Insert("IncomingMailServerPort", 993);
	Settings.Insert("UseSecureConnectionForIncomingMail", True);
	Settings.Insert("UseSafeAuthorizationAtIncomingMailServer", False);
	
	Settings.Insert("OutgoingMailServer", "smtp." + ServerNameInAccount);
	Settings.Insert("OutgoingMailServerPort", 587);
	Settings.Insert("UseSecureConnectionForOutgoingMail", False);
	Settings.Insert("UseSafeAuthorizationAtOutgoingMailServer", False);
	
	Settings.Insert("ServerTimeout", 30);
	Settings.Insert("KeepEmailCopiesOnServer", True);
	Settings.Insert("KeepMailAtServerPeriod", 10);
	
	IMAPDefaultSettings = Catalogs.EmailAccounts.IMAPServerConnectionSettingsOptions(EmailAddress)[0];
	SMTPDefaultSettings = Catalogs.EmailAccounts.SMTPServerConnectionSettingsOptions(EmailAddress)[0];
	
	FillPropertyValues(Settings, IMAPDefaultSettings);
	FillPropertyValues(Settings, SMTPDefaultSettings);
	
	Return Settings;
EndFunction

&AtServer
Function TestConnectionToIncomingMailServer()
	
	Profile = InternetMailProfile(True);
	InternetMail = New InternetMail;
	
	ProtocolToUse = InternetMailProtocol.POP3;
	If Protocol = "IMAP" Then
		ProtocolToUse = InternetMailProtocol.IMAP;
	EndIf;
	
	ErrorText = "";
	Try
		InternetMail.Logon(Profile, ProtocolToUse);
	Except
		ErrorText = BriefErrorDescription(ErrorInfo());
	EndTry;
	
	InternetMail.Logoff();
	
	Return ErrorText;
	
EndFunction

&AtServer
Function TestConnectionToOutgoingMailServer()
	
	MailSubject = NStr("ru = 'Тестовое сообщение 1С:Предприятие'; en = 'Test message from 1C:Enterprise'; pl = 'Wiadomość tekstowa 1C:Enterprise';de = '1C: Enterprise Testnachricht';ro = 'Mesaj de testare 1C:Enterprise';tr = '1C:Enterprise test mesajı'; es_ES = 'Mensaje de prueba de la 1C:Empresa'");
	Body = NStr("ru = 'Это сообщение отправлено подсистемой электронной почты 1С:Предприятие'; en = 'This message is sent via the ""Email operations"" subsystem.'; pl = 'Ta wiadomość została wysłana przez podsystem poczty elektronicznej 1C:Enterprise ';de = 'Diese Nachricht wird vom Subsystem von 1C: Enterprise E-Mail gesendet';ro = 'Acest mesaj este trimis de subsistemul poștei electronice al 1C:Enterprise';tr = 'Bu mesaj 1C:Enterprise e-postanın alt sistemi tarafından gönderildi'; es_ES = 'Este mensaje se ha enviado por el subsistema del correo electrónico de la 1C:Empresa'");
	
	Email = New InternetMailMessage;
	Email.Subject = MailSubject;
	
	Recipient = Email.To.Add(EmailAddress);
	Recipient.DisplayName = EmailSenderName;
	
	Email.SenderName = EmailSenderName;
	Email.From.DisplayName = EmailSenderName;
	Email.From.Address = EmailAddress;
	
	Text = Email.Texts.Add(Body);
	Text.TextType = InternetMailTextType.PlainText;

	Profile = InternetMailProfile();
	InternetMail = New InternetMail;
	
	ErrorText = "";
	Try
		InternetMail.Logon(Profile);
		InternetMail.Send(Email);
	Except
		ErrorText = BriefErrorDescription(ErrorInfo());
	EndTry;
	
	InternetMail.Logoff();
	
	Return ErrorText;
	
EndFunction

&AtServer
Procedure ValidateAccountSettings()
	
	ValidationCompletedWithErrors = False;
	
	IncomingMailServerMessage = "";
	If UseForReceiving Then
		IncomingMailServerMessage = TestConnectionToIncomingMailServer();
	EndIf;
	
	OutgoingMailServerMessage = "";
	If UseForSending Then
		OutgoingMailServerMessage = TestConnectionToOutgoingMailServer();
	EndIf;
	
	ErrorText = "";
	If Not IsBlankString(OutgoingMailServerMessage) Then
		ErrorText = NStr("ru = 'Not managed to connect lot server outgoing mail:'" + Chars.LF)
			+ OutgoingMailServerMessage + Chars.LF;
	EndIf;
	
	If Not IsBlankString(IncomingMailServerMessage) Then
		ErrorText = ErrorText
			+ NStr("ru = 'Not managed to connect lot server incoming mail:'" + Chars.LF)
			+ IncomingMailServerMessage;
	EndIf;
	
	ErrorMessages = TrimAll(ErrorText);
			
	If Not IsBlankString(ErrorText) Then
		ValidationCompletedWithErrors = True;
	Else
		Try
			NewAccount();
		Except
			ValidationCompletedWithErrors = True;
			ErrorMessages = BriefErrorDescription(ErrorInfo());
		EndTry;
	EndIf;
	
EndProcedure

&AtServer
Procedure NewAccount()
	
	SystemAccount = Catalogs.EmailAccounts.SystemEmailAccount;
	If ContextMode 
		AND UserAccountKind = "Total"
		AND Not EmailOperations.AccountSetUp(SystemAccount)
		AND Catalogs.EmailAccounts.EditionAllowed(SystemAccount) Then
		
		Account = SystemAccount.GetObject();
	Else
		If AccountRef.IsEmpty() Then
			Account = Catalogs.EmailAccounts.CreateItem();
			Account.SetNewObjectRef(NewAccountRef);
		Else
			Account = AccountRef.GetObject();
		EndIf;
	EndIf;
	FillPropertyValues(Account, ThisObject);
	Account.UserName = EmailSenderName;
	Account.User = UsernameForReceivingEmails;
	Account.SMTPUser = UsernameToSendMail;
	Account.Timeout = ServerTimeout;
	Account.KeepMessageCopiesAtServer = KeepEmailCopiesOnServer;
	Account.KeepMailAtServerPeriod = ?(KeepEmailCopiesOnServer AND DeleteMailFromServer AND Protocol = "POP", KeepMailAtServerPeriod, 0);
	Account.ProtocolForIncomingMail = Protocol;
	Account.Description = AccountName;
	If UserAccountKind = "Personal" Then
		Account.AccountOwner = Users.CurrentUser();
	Else
		Account.AccountOwner = Catalogs.Users.EmptyRef();
	EndIf;
	Account.AdditionalProperties.Insert("DoNotCheckSettingsForChanges");
	
	BeginTransaction();
	Try
		Account.Write();
		AccountRef = Account.Ref;
		FormClosingConfirmationRequired = False;
		
		SetPrivilegedMode(True);
		Common.WriteDataToSecureStorage(AccountRef, PasswordForReceivingEmails);
		Common.WriteDataToSecureStorage(AccountRef, PasswordToSendMail, "SMTPPassword");
		SetPrivilegedMode(False);
		
		CommitTransaction();
	Except
		RollbackTransaction();
		WriteLogEvent(NStr("ru = 'Ошибка при создании учетной записи электронной почты'; en = 'Email account creation error'; pl = 'Błąd podczas tworzenia konta poczty elektronicznej';de = 'Fehler bei der Erstellung eines E-Mail-Kontos';ro = 'Eroare la crearea contului poștei electronice';tr = 'E-posta hesabı oluşturulurken hata oluştu'; es_ES = 'Error al crear la cuenta del correo electrónico'", Common.DefaultLanguageCode()),
			EventLogLevel.Error, , , DetailErrorDescription(ErrorInfo()));
		Raise;
	EndTry;
	
EndProcedure

&AtServer
Function InternetMailProfile(ForReceiving = False)
	
	Profile = New InternetMailProfile;
	If ForReceiving Or SignInBeforeSendingRequired Then
		If Protocol = "IMAP" Then
			Profile.IMAPServerAddress = IncomingMailServer;
			Profile.IMAPUseSSL = UseSecureConnectionForIncomingMail;
			Profile.IMAPPassword = PasswordForReceivingEmails;
			Profile.IMAPUser = UsernameForReceivingEmails;
			Profile.IMAPPort = IncomingMailServerPort;
			Profile.IMAPSecureAuthenticationOnly = UseSafeAuthorizationAtIncomingMailServer;
		Else
			Profile.POP3ServerAddress = IncomingMailServer;
			Profile.POP3UseSSL = UseSecureConnectionForIncomingMail;
			Profile.Password = PasswordForReceivingEmails;
			Profile.User = UsernameForReceivingEmails;
			Profile.POP3Port = IncomingMailServerPort;
			Profile.POP3SecureAuthenticationOnly = UseSafeAuthorizationAtIncomingMailServer;
		EndIf;
	EndIf;
	
	If Not ForReceiving Then
		Profile.POP3BeforeSMTP = SignInBeforeSendingRequired;
		Profile.SMTPServerAddress = OutgoingMailServer;
		Profile.SMTPUseSSL = UseSecureConnectionForOutgoingMail;
		Profile.SMTPPassword = PasswordToSendMail;
		Profile.SMTPUser = UsernameToSendMail;
		Profile.SMTPPort = OutgoingMailServerPort;
		Profile.SMTPSecureAuthenticationOnly = UseSafeAuthorizationAtOutgoingMailServer;
	EndIf;
	
	Profile.Timeout = ServerTimeout;
	
	Return Profile;
	
EndFunction

&AtClient
Procedure SetUpConnectionParametersAutomatically()
	
	ErrorMessages = NStr("ru = 'Не удалось определить настройки подключения. 
	|Настройте параметры подключения вручную.'; 
	|en = 'Cannot determine the connection settings.
	|Please configure the connection parameters.'; 
	|pl = 'Nie można ustalić ustawień połączenia. 
	|Ustaw parametry połączenia ręcznie.';
	|de = 'Verbindungseinstellungen konnten nicht ermittelt werden. 
	|Stellen Sie die Verbindungsparameter manuell ein.';
	|ro = 'Eșec la stabilirea setărilor conexiunii.
	|Setați manual parametrii de conectare.';
	|tr = 'Bağlantı ayarları belirlenemedi. 
	|Bağlantı ayarlarını manuel olarak yapılandırın.'; 
	|es_ES = 'No se puede determinar las configuraciones de conexión. 
	|Establecer los parámetros de conexión manualmente.'");
	
	If StrFind(Lower(EmailAddress), "@gmail.com") > 0 Then
		ErrorMessages = ErrorMessages + Chars.LF
			+ NStr("ru = 'См. также рекомендации по настройке почты Gmail:
					|http://buh.ru/articles/documents/42429/#briefly_43166'; 
					|en = 'See also: http://buh.ru/articles/documents/42429/#briefly_43166
					|(recommendations on configuring a Gmail account, in Russian).'; 
					|pl = 'Zob. również zalecenia odnośnie ustawień poczty Gmail:
					|http://buh.ru/articles/documents/42429/#briefly_43166';
					|de = 'Weitere Informationen zur Einrichtung Ihrer E-Mail finden Sie unter Gmail:
					|http://buh.ru/articles/documents/42429/#briefly_43166';
					|ro = 'Mai vezi și recomandările cu privire la configurarea poștei Gmail:
					|http://buh.ru/articles/documents/42429/#briefly_43166';
					|tr = 'Gmail ayarları ile ilgili önerilere bakın:
					|http://buh.ru/articles/documents/42429/#briefly_43166'; 
					|es_ES = 'Ver también las recomendaciones de ajustar el correo Gmail:
					|http://buh.ru/articles/documents/42429/#briefly_43166'");
	EndIf;
	
	ValidationCompletedWithErrors = False;
	
	TimeConsumingOperation = PickAccountSettings();
	
	IdleParameters = TimeConsumingOperationsClient.IdleParameters(ThisObject);
	IdleParameters.OutputIdleWindow = False;
	
	NotifyDescription = New NotifyDescription("OnCompletePickup", ThisObject);
	TimeConsumingOperationsClient.WaitForCompletion(TimeConsumingOperation, NotifyDescription, IdleParameters);
	
EndProcedure

&AtServer
Function PickAccountSettings()
	
	JobDescription = NStr("ru = 'Поиск настроек почтового сервера'; en = 'Search for mail server settings'; pl = 'Wyszukiwanie ustawień serwera pocztowego';de = 'Suchen nach Mailserver-Einstellungen';ro = 'Căutarea setărilor serverului poștal';tr = 'Posta sunucusunun ayarlarını arama'; es_ES = 'Búsqueda de los ajustes del servidor de correo electrónico'");
	MethodBeingExecuted = "Catalogs.EmailAccounts.DefineAccountSettings";
	
	ParametersStructure = New Structure;
	ParametersStructure.Insert("EmailAddress", EmailAddress);
	ParametersStructure.Insert("Password", PasswordForReceivingEmails);
	ParametersStructure.Insert("ForSending", UseForSending);
	ParametersStructure.Insert("ForReceiving", UseForReceiving);
	
	ExecutionParameters = TimeConsumingOperations.BackgroundExecutionParameters(UUID);
	ExecutionParameters.BackgroundJobDescription = JobDescription;
	
	Return TimeConsumingOperations.ExecuteInBackground(MethodBeingExecuted, ParametersStructure, ExecutionParameters);
	
EndFunction

&AtClient
Procedure OnCompletePickup(Result, AdditionalParameters) Export
	
	If Result = Undefined Then
		Return;
	EndIf;
	
	If Result.Status = "Error" Then
		ValidationCompletedWithErrors = True;
		GotoNextPage();
		Return;
	EndIf;
	
	FoundSettings = GetFromTempStorage(Result.ResultAddress);
	
	ValidationCompletedWithErrors = UseForSending AND Not FoundSettings.ForSending 
		Or UseForReceiving AND Not FoundSettings.ForReceiving;
		
	FillPropertyValues(ThisObject, FoundSettings);
	If Not ValidationCompletedWithErrors Then
		Try
			NewAccount();
		Except
			ValidationCompletedWithErrors = True;
			ErrorMessages = BriefErrorDescription(ErrorInfo());
		EndTry;
		NotifyChanged(NewAccountRef);
	EndIf;
	GotoNextPage();
	
EndProcedure

#EndRegion
