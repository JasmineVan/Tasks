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

// Returns object attributes allowed to be edited using batch attribute change data processor.
// 
//
// Returns:
//  Array - a list of object attribute names.
Function AttributesToEditInBatchProcessing() Export
	
	Result = New Array;
	Result.Add("UseForSending");
	Result.Add("UseForReceiving");
	Return Result;
	
EndFunction

// End StandardSubsystems.BatchObjectsModification

// StandardSubsystems.AccessManagement

// See AccessManagementOverridable.OnFillListsWithAccessRestriction. 
Procedure OnFillAccessRestriction(Restriction) Export
	
	Restriction.Text =
	"AllowRead
	|WHERE
	|	ValueAllowed(Ref)
	|	OR ValueAllowed(AccountOwner, EmptyRef AS False)
	|;
	|AllowUpdateIfReadingAllowed
	|WHERE
	|	ValueAllowed(AccountOwner, EmptyRef AS False)";
	
EndProcedure

// End StandardSubsystems.AccessManagement

#EndRegion

#EndRegion

#Region Internal

// Registers the objects to be updated to the latest version in the InfobaseUpdate exchange plan.
// 
//
Procedure RegisterDataToProcessForMigrationToNewVersion(Parameters) Export
	
	If Common.SubsystemExists("StandardSubsystems.Interactions") Then
		ModuleInteractions = Common.CommonModule("Interactions");
		ModuleInteractions.RegisterEmailAccountsToProcessingToMigrateToNewVersion(Parameters);
	EndIf;
	
EndProcedure

Procedure ProcessDataForMigrationToNewVersion(Parameters) Export
	
	Accounts = New Array;
	Selection = InfobaseUpdate.SelectRefsToProcess(Parameters.Queue, "Catalog.EmailAccounts");
	While Selection.Next() Do
		Accounts.Add(Selection.Ref);
	EndDo;
	
	QueryText =
	"SELECT
	|	EmailAccounts.Ref AS Ref
	|FROM
	|	Catalog.EmailAccounts AS EmailAccounts
	|WHERE
	|	EmailAccounts.Ref IN(&Accounts)";
	
	Query = New Query(QueryText);
	Query.SetParameter("Accounts", Accounts);
	
	Lock = New DataLock;
	If Common.SubsystemExists("StandardSubsystems.Interactions") Then
		ModuleInteractions = Common.CommonModule("Interactions");
		ModuleInteractions.BeforeSetLockInEmailAccountsUpdateHandler(Lock);
	EndIf;
	Lock.Add("Catalog.EmailAccounts");
	
	BeginTransaction();
	Try
		Lock.Lock();
		
		AccountOwners = New Map;
		If Common.SubsystemExists("StandardSubsystems.Interactions") Then
			ModuleInteractions = Common.CommonModule("Interactions");
			AccountOwners = ModuleInteractions.EmailAccountsOwners(Accounts);
		EndIf;
		
		Selection = Query.Execute().Select();
		While Selection.Next() Do
			Account = Selection.Ref.GetObject();
			Account.AdditionalProperties.Insert("DoNotCheckSettingsForChanges");
			If AccountOwners[Selection.Ref] <> Undefined Then
				Account.AccountOwner = AccountOwners[Selection.Ref];
			EndIf;
			InfobaseUpdate.WriteData(Account);
		EndDo;
		
		CommitTransaction();
	Except
		RollbackTransaction();
		WriteLogEvent(NStr("ru = 'Обновление персональных учетных записей'; en = 'Update personal accounts'; pl = 'Aktualizacja kont prywatnych';de = 'Aktualisierung der persönlichen Konten';ro = 'Actualizarea conturilor personale';tr = 'Kişisel hesapların güncellemesi'; es_ES = 'Actualización de las cuentas personales'", Common.DefaultLanguageCode()),
			EventLogLevel.Error,,, DetailErrorDescription(ErrorInfo()));
		Raise;
	EndTry;
	
	Parameters.ProcessingCompleted = InfobaseUpdate.DataProcessingCompleted(Parameters.Queue, "Catalog.EmailAccounts");
	
EndProcedure

#EndRegion

#Region Private

Procedure FormGetProcessing(FormType, Parameters, SelectedForm, AdditionalInformation, StandardProcessing)
	
	If FormType = "ObjectForm" 
		AND Not Parameters.Property("CopyingValue")
		AND AccessRight("Edit", Metadata.Catalogs.EmailAccounts)
		AND (Not Parameters.Property("Key") 
			Or Not EmailOperations.AccountSetUp(Parameters.Key, False, False) AND EditionAllowed(Parameters.Key)) Then
		
		SelectedForm = "AccountSetupWizard";
		StandardProcessing = False;
	EndIf;
	
EndProcedure

Function EditionAllowed(Account) Export
	Result = AccessRight("Edit", Metadata.Catalogs.EmailAccounts);
	If Common.SubsystemExists("StandardSubsystems.AccessManagement") Then
		ModuleAccessManagement = Common.CommonModule("AccessManagement");
		Result = Result AND ModuleAccessManagement.EditionAllowed(Account);
	EndIf;
	Return Result;
EndFunction

Function AccountPermissions(Account = Undefined) Export
	
	Result = New Map;
	
	QueryText = 
	"SELECT
	|	EmailAccounts.ProtocolForIncomingMail AS Protocol,
	|	EmailAccounts.IncomingMailServer AS Server,
	|	EmailAccounts.IncomingMailServerPort AS Port,
	|	EmailAccounts.Ref
	|INTO MailServers
	|FROM
	|	Catalog.EmailAccounts AS EmailAccounts
	|WHERE
	|	EmailAccounts.ProtocolForIncomingMail <> """"
	|	AND EmailAccounts.DeletionMark = FALSE
	|	AND EmailAccounts.UseForReceiving = TRUE
	|	AND EmailAccounts.IncomingMailServer <> """"
	|	AND EmailAccounts.IncomingMailServerPort > 0
	|
	|UNION ALL
	|
	|SELECT
	|	""SMTP"",
	|	EmailAccounts.OutgoingMailServer,
	|	EmailAccounts.OutgoingMailServerPort,
	|	EmailAccounts.Ref
	|FROM
	|	Catalog.EmailAccounts AS EmailAccounts
	|WHERE
	|	EmailAccounts.DeletionMark = FALSE
	|	AND EmailAccounts.UseForSending = TRUE
	|	AND EmailAccounts.OutgoingMailServer <> """"
	|	AND EmailAccounts.OutgoingMailServerPort > 0
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	MailServers.Ref AS Ref,
	|	MailServers.Protocol AS Protocol,
	|	MailServers.Server AS Server,
	|	MailServers.Port AS Port
	|FROM
	|	MailServers AS MailServers
	|WHERE
	|	&Ref = UNDEFINED
	|
	|GROUP BY
	|	MailServers.Protocol,
	|	MailServers.Server,
	|	MailServers.Port,
	|	MailServers.Ref
	|
	|UNION ALL
	|
	|SELECT
	|	MailServers.Ref,
	|	MailServers.Protocol,
	|	MailServers.Server,
	|	MailServers.Port
	|FROM
	|	MailServers AS MailServers
	|WHERE
	|	MailServers.Ref = &Ref
	|
	|GROUP BY
	|	MailServers.Protocol,
	|	MailServers.Server,
	|	MailServers.Port,
	|	MailServers.Ref
	|TOTALS BY
	|	Ref";
	
	Query = New Query(QueryText);
	Query.SetParameter("Ref", Account);
	
	ModuleSafeModeManager = Common.CommonModule("SafeModeManager");
	
	Accounts = Query.Execute().Select(QueryResultIteration.ByGroups);
	While Accounts.Next() Do
		Permissions = New Array;
		AccountSettings = Accounts.Select();
		While AccountSettings.Next() Do
			Permissions.Add(
				ModuleSafeModeManager.PermissionToUseInternetResource(
					AccountSettings.Protocol,
					AccountSettings.Server,
					AccountSettings.Port,
					NStr("ru = 'Электронная почта.'; en = 'Email.'; pl = 'E-mail.';de = 'E-Mail.';ro = 'E-mail.';tr = 'E-posta.'; es_ES = 'Correo electrónico.'")));
		EndDo;
		Result.Insert(Accounts.Ref, Permissions);
	EndDo;
	
	Return Result;
	
EndFunction

Procedure DefineAccountSettings(Parameters, ResultAddress) Export
	
	EmailAddress = Parameters.EmailAddress;
	Password = Parameters.Password;
	
	FoundSMTPProfile = Undefined;
	FoundIMAPProfile = Undefined;
	FoundPOPProfile = Undefined;
	
	If Parameters.ForSending Then
		FoundSMTPProfile = DefineSMTPSettings(EmailAddress, Password);
	EndIf;
	
	If Parameters.ForSending Or Parameters.ForReceiving Then
		FoundIMAPProfile = DefineIMAPSettings(EmailAddress, Password);
		If FoundIMAPProfile = Undefined AND Parameters.ForReceiving Then
			FoundPOPProfile = DefinePOPSettings(EmailAddress, Password);
		EndIf;
	EndIf;
	
	Result = New Structure;
	
	If FoundIMAPProfile <> Undefined Then
		Result.Insert("UsernameForReceivingEmails", FoundIMAPProfile.IMAPUser);
		Result.Insert("PasswordForReceivingEmails", FoundIMAPProfile.IMAPPassword);
		Result.Insert("Protocol", "IMAP");
		Result.Insert("IncomingMailServer", FoundIMAPProfile.IMAPServerAddress);
		Result.Insert("IncomingMailServerPort", FoundIMAPProfile.IMAPPort);
		Result.Insert("UseSecureConnectionForIncomingMail", FoundIMAPProfile.IMAPUseSSL);
	EndIf;
	
	If FoundPOPProfile <> Undefined Then
		Result.Insert("UsernameForReceivingEmails", FoundPOPProfile.User);
		Result.Insert("PasswordForReceivingEmails", FoundPOPProfile.Password);
		Result.Insert("Protocol", "POP");
		Result.Insert("IncomingMailServer", FoundPOPProfile.POP3ServerAddress);
		Result.Insert("IncomingMailServerPort", FoundPOPProfile.POP3Port);
		Result.Insert("UseSecureConnectionForIncomingMail", FoundPOPProfile.POP3UseSSL);
	EndIf;
	
	If FoundSMTPProfile <> Undefined Then
		Result.Insert("UserNameForSendingEmails", FoundSMTPProfile.SMTPUser);
		Result.Insert("PasswordForSendingEmails", FoundSMTPProfile.SMTPPassword);
		Result.Insert("OutgoingMailServer", FoundSMTPProfile.SMTPServerAddress);
		Result.Insert("OutgoingMailServerPort", FoundSMTPProfile.SMTPPort);
		Result.Insert("UseSecureConnectionForOutgoingMail", FoundSMTPProfile.SMTPUseSSL);
	EndIf;
	
	Result.Insert("ForReceiving", FoundIMAPProfile <> Undefined Or FoundPOPProfile <> Undefined);
	Result.Insert("ForSending", FoundSMTPProfile <> Undefined);
	
	PutToTempStorage(Result, ResultAddress);
	
EndProcedure

Function DefinePOPSettings(EmailAddress, Password)
	For Each Profile In POPProfiles(EmailAddress, Password) Do
		ServerMessage = TestConnectionToIncomingMailServer(Profile, InternetMailProtocol.POP3);
		
		If AuthenticationError(ServerMessage) Then
			For Each Username In UsernameOptions(EmailAddress) Do
				SetUserName(Profile, Username);
				ServerMessage = TestConnectionToIncomingMailServer(Profile, InternetMailProtocol.POP3);
				If Not AuthenticationError(ServerMessage) Then
					Break;
				EndIf;
			EndDo;
			If AuthenticationError(ServerMessage) Then
				Break;
			EndIf;
		EndIf;
		
		If Connected(ServerMessage) Then
			Return Profile;
		EndIf;
	EndDo;
	
	Return Undefined;
EndFunction

Function DefineIMAPSettings(EmailAddress, Password)
	For Each Profile In IMAPProfiles(EmailAddress, Password) Do
		ServerMessage = TestConnectionToIncomingMailServer(Profile, InternetMailProtocol.IMAP);
		
		If AuthenticationError(ServerMessage) Then
			For Each Username In UsernameOptions(EmailAddress) Do
				SetUserName(Profile, Username);
				ServerMessage = TestConnectionToIncomingMailServer(Profile, InternetMailProtocol.IMAP);
				If Not AuthenticationError(ServerMessage) Then
					Break;
				EndIf;
			EndDo;
			If AuthenticationError(ServerMessage) Then
				Break;
			EndIf;
		EndIf;
		
		If Connected(ServerMessage) Then
			Return Profile;
		EndIf;
	EndDo;
	
	Return Undefined;
EndFunction

Function DefineSMTPSettings(EmailAddress, Password)
	For Each Profile In SMTPProfiles(EmailAddress, Password) Do
		ServerMessage = TestConnectionToOutgoingMailServer(Profile, EmailAddress);
		
		If AuthenticationError(ServerMessage) Then
			For Each Username In UsernameOptions(EmailAddress) Do
				SetUserName(Profile, Username);
				ServerMessage = TestConnectionToOutgoingMailServer(Profile, EmailAddress);
				If Not AuthenticationError(ServerMessage) Then
					Break;
				EndIf;
			EndDo;
			If AuthenticationError(ServerMessage) Then
				Break;
			EndIf;
		EndIf;
		
		If Connected(ServerMessage) Then
			Return Profile;
		EndIf;
	EndDo;
	
	Return Undefined;
EndFunction

Function POPProfiles(EmailAddress, Password)
	Result = New Array;
	ProfileSettings = DefaultSettings(EmailAddress, Password);
	
	For Each ConnectionSettingsOption In POPServerConnectionSettingsOptions(EmailAddress) Do
		Profile = New InternetMailProfile;
		FillPropertyValues(ProfileSettings, ConnectionSettingsOption);
		FillPropertyValues(Profile, InternetMailProfile(ProfileSettings, InternetMailProtocol.POP3));
		Result.Add(Profile);
	EndDo;
	
	Return Result;
EndFunction

Function IMAPProfiles(EmailAddress, Password)
	Result = New Array;
	ProfileSettings = DefaultSettings(EmailAddress, Password);
	
	For Each ConnectionSettingsOption In IMAPServerConnectionSettingsOptions(EmailAddress) Do
		Profile = New InternetMailProfile;
		FillPropertyValues(ProfileSettings, ConnectionSettingsOption);
		FillPropertyValues(Profile, InternetMailProfile(ProfileSettings, InternetMailProtocol.IMAP));
		Result.Add(Profile);
	EndDo;
	
	Return Result;
EndFunction

Function SMTPProfiles(EmailAddress, Password)
	Result = New Array;
	ProfileSettings = DefaultSettings(EmailAddress, Password);
	
	For Each ConnectionSettingsOption In SMTPServerConnectionSettingsOptions(EmailAddress) Do
		Profile = New InternetMailProfile;
		FillPropertyValues(ProfileSettings, ConnectionSettingsOption);
		FillPropertyValues(Profile, InternetMailProfile(ProfileSettings, InternetMailProtocol.SMTP));
		Result.Add(Profile);
	EndDo;
	
	Return Result;
EndFunction

Function AuthenticationError(ServerMessage)
	Return StrFind(Lower(ServerMessage), "auth") > 0
		Or StrFind(Lower(ServerMessage), "password") > 0
		Or StrFind(Lower(ServerMessage), "credentials") > 0;
EndFunction

Function Connected(ServerMessage)
	Return IsBlankString(ServerMessage);
EndFunction

Procedure SetUserName(Profile, Username)
	If Not IsBlankString(Profile.User) Then
		Profile.User = Username;
	EndIf;
	If Not IsBlankString(Profile.IMAPUser) Then
		Profile.IMAPUser = Username;
	EndIf;
	If Not IsBlankString(Profile.SMTPUser) Then
		Profile.SMTPUser = Username;
	EndIf;
EndProcedure

Function DefaultSettings(EmailAddress, Password)
	
	Position = StrFind(EmailAddress, "@");
	ServerNameInAccount = Mid(EmailAddress, Position + 1);
	
	Settings = New Structure;
	
	Settings.Insert("UsernameForReceivingEmails", EmailAddress);
	Settings.Insert("UserNameForSendingEmails", EmailAddress);
	
	Settings.Insert("PasswordToSendMail", Password);
	Settings.Insert("PasswordForReceivingEmails", Password);
	
	Settings.Insert("Protocol", "POP");
	Settings.Insert("IncomingMailServer", "pop." + ServerNameInAccount);
	Settings.Insert("IncomingMailServerPort", 995);
	Settings.Insert("UseSecureConnectionForIncomingMail", True);
	Settings.Insert("UseSafeAuthorizationAtIncomingMailServer", False);
	
	Settings.Insert("OutgoingMailServer", "smtp." + ServerNameInAccount);
	Settings.Insert("OutgoingMailServerPort", 465);
	Settings.Insert("UseSecureConnectionForOutgoingMail", True);
	Settings.Insert("UseSafeAuthorizationAtOutgoingMailServer", False);
	Settings.Insert("SignInBeforeSendingRequired", False);
	
	Settings.Insert("ServerTimeout", 30);
	Settings.Insert("KeepEmailCopiesOnServer", True);
	Settings.Insert("DeleteEmailsFromServerAfter", 0);
	
	Return Settings;
	
EndFunction

Function TestConnectionToIncomingMailServer(Profile, Protocol)
	
	InternetMail = New InternetMail;
	
	ErrorText = "";
	Try
		InternetMail.Logon(Profile, Protocol);
	Except
		ErrorText = BriefErrorDescription(ErrorInfo());
	EndTry;
	
	InternetMail.Logoff();
	
	If Protocol = InternetMailProtocol.POP3 Then
		TextForLog = StringFunctionsClientServer.SubstituteParametersToString("%1:%2%3 (%4)" + Chars.LF + "%5",
			Profile.POP3ServerAddress,
			Profile.POP3Port,
			?(Profile.POP3UseSSL, "/SSL", ""),
			Profile.User,
			?(IsBlankString(ErrorText), NStr("ru = 'OK'; en = 'OK'; pl = 'OK';de = 'OK';ro = 'OK';tr = 'OK'; es_ES = 'OK'"), ErrorText));
	Else
		TextForLog = StringFunctionsClientServer.SubstituteParametersToString("%1:%2%3 (%4)" + Chars.LF + "%5",
			Profile.IMAPServerAddress,
			Profile.IMAPPort,
			?(Profile.IMAPUseSSL, "/SSL", ""),
			Profile.IMAPUser,
			?(IsBlankString(ErrorText), NStr("ru = 'OK'; en = 'OK'; pl = 'OK';de = 'OK';ro = 'OK';tr = 'OK'; es_ES = 'OK'"), ErrorText));
	EndIf;
	
	WriteLogEvent(NStr("ru = 'Проверка подключения к почтовому серверу'; en = 'Check connection to the mail server'; pl = 'Weryfikacja podłączenia do serwera pocztowego';de = 'Überprüfen der Verbindung zum Mailserver';ro = 'Verificarea conexiunii la serverul poștal';tr = 'Posta sunucusuna bağlanma kontrolü'; es_ES = 'Comprobar la conexión al servidor de correo'", Common.DefaultLanguageCode()), 
		EventLogLevel.Information, , , TextForLog);
	
	Return ErrorText;
	
EndFunction

Function TestConnectionToOutgoingMailServer(Profile, EmailAddress)
	
	MailSubject = NStr("ru = 'Тестовое сообщение 1С:Предприятие'; en = 'Test message from 1C:Enterprise'; pl = 'Wiadomość tekstowa 1C:Enterprise';de = '1C: Enterprise Testnachricht';ro = 'Mesaj de testare 1C:Enterprise';tr = '1C:Enterprise test mesajı'; es_ES = 'Mensaje de prueba de la 1C:Empresa'");
	Body = NStr("ru = 'Это сообщение отправлено подсистемой электронной почты 1С:Предприятие'; en = 'This message is sent via the ""Email operations"" subsystem.'; pl = 'Ta wiadomość została wysłana przez podsystem poczty elektronicznej 1C:Enterprise ';de = 'Diese Nachricht wird vom Subsystem von 1C: Enterprise E-Mail gesendet';ro = 'Acest mesaj este trimis de subsistemul poștei electronice al 1C:Enterprise';tr = 'Bu mesaj 1C:Enterprise e-postanın alt sistemi tarafından gönderildi'; es_ES = 'Este mensaje se ha enviado por el subsistema del correo electrónico de la 1C:Empresa'");
	EmailSenderName = NStr("ru = '1С:Предприятие'; en = '1C:Enterprise'; pl = '1C:Enterprise';de = '1C:Enterprise';ro = '1C:Enterprise';tr = '1C:Enterprise'; es_ES = '1C:Empresa'");
	
	Email = New InternetMailMessage;
	Email.Subject = MailSubject;
	
	Recipient = Email.To.Add(EmailAddress);
	Recipient.DisplayName = EmailSenderName;
	
	Email.SenderName = EmailSenderName;
	Email.From.DisplayName = EmailSenderName;
	Email.From.Address = EmailAddress;
	
	Text = Email.Texts.Add(Body);
	Text.TextType = InternetMailTextType.PlainText;

	InternetMail = New InternetMail;
	
	ErrorText = "";
	Try
		InternetMail.Logon(Profile);
		InternetMail.Send(Email);
	Except
		ErrorText = BriefErrorDescription(ErrorInfo());
	EndTry;
	
	InternetMail.Logoff();
	
	TextForLog = StringFunctionsClientServer.SubstituteParametersToString("%1:%2%3 (%4)" + Chars.LF + "%5",
		Profile.SMTPServerAddress,
		Profile.SMTPPort,
		?(Profile.SMTPUseSSL, "/SSL", ""),
		Profile.SMTPUser,
		?(IsBlankString(ErrorText), NStr("ru = 'OK'; en = 'OK'; pl = 'OK';de = 'OK';ro = 'OK';tr = 'OK'; es_ES = 'OK'"), ErrorText));
		
	WriteLogEvent(NStr("ru = 'Проверка подключения к почтовому серверу'; en = 'Check connection to the mail server'; pl = 'Weryfikacja podłączenia do serwera pocztowego';de = 'Überprüfen der Verbindung zum Mailserver';ro = 'Verificarea conexiunii la serverul poștal';tr = 'Posta sunucusuna bağlanma kontrolü'; es_ES = 'Comprobar la conexión al servidor de correo'", Common.DefaultLanguageCode()), 
		EventLogLevel.Information, , , TextForLog);
	
	Return ErrorText;
	
EndFunction

Function InternetMailProfile(ProfileSettings, Protocol)
	
	ForReceiving = Protocol <> InternetMailProtocol.SMTP;
	
	Profile = New InternetMailProfile;
	If ForReceiving Or ProfileSettings.SignInBeforeSendingRequired Then
		If Protocol = InternetMailProtocol.IMAP Then
			Profile.IMAPServerAddress = ProfileSettings.IncomingMailServer;
			Profile.IMAPUseSSL = ProfileSettings.UseSecureConnectionForIncomingMail;
			Profile.IMAPPassword = ProfileSettings.PasswordForReceivingEmails;
			Profile.IMAPUser = ProfileSettings.UsernameForReceivingEmails;
			Profile.IMAPPort = ProfileSettings.IncomingMailServerPort;
			Profile.IMAPSecureAuthenticationOnly = ProfileSettings.UseSafeAuthorizationAtIncomingMailServer;
		Else
			Profile.POP3ServerAddress = ProfileSettings.IncomingMailServer;
			Profile.POP3UseSSL = ProfileSettings.UseSecureConnectionForIncomingMail;
			Profile.Password = ProfileSettings.PasswordForReceivingEmails;
			Profile.User = ProfileSettings.UsernameForReceivingEmails;
			Profile.POP3Port = ProfileSettings.IncomingMailServerPort;
			Profile.POP3SecureAuthenticationOnly = ProfileSettings.UseSafeAuthorizationAtIncomingMailServer;
		EndIf;
	EndIf;
	
	If Not ForReceiving Then
		Profile.POP3BeforeSMTP = ProfileSettings.SignInBeforeSendingRequired;
		Profile.SMTPServerAddress = ProfileSettings.OutgoingMailServer;
		Profile.SMTPUseSSL = ProfileSettings.UseSecureConnectionForOutgoingMail;
		Profile.SMTPPassword = ProfileSettings.PasswordToSendMail;
		Profile.SMTPUser = ProfileSettings.UserNameForSendingEmails;
		Profile.SMTPPort = ProfileSettings.OutgoingMailServerPort;
		Profile.SMTPSecureAuthenticationOnly = ProfileSettings.UseSafeAuthorizationAtOutgoingMailServer;
	EndIf;
	
	Profile.Timeout = ProfileSettings.ServerTimeout;
	
	Return Profile;
	
EndFunction

Function UsernameOptions(EmailAddress)
	
	Position = StrFind(EmailAddress, "@");
	UserNameInAccount = Left(EmailAddress, Position - 1);
	
	Result = New Array;
	Result.Add(UserNameInAccount);
	
	Return Result;
	
EndFunction

Function IMAPServerConnectionSettingsOptions(EmailAddress) Export
	
	Position = StrFind(EmailAddress, "@");
	ServerNameInAccount = Mid(EmailAddress, Position + 1);
	
	Result = New ValueTable;
	Result.Columns.Add("IncomingMailServer");
	Result.Columns.Add("IncomingMailServerPort");
	Result.Columns.Add("UseSecureConnectionForIncomingMail");
	
	// icloud.com
	If ServerNameInAccount = "icloud.com" Then
		SetupOption = Result.Add();
		SetupOption.IncomingMailServer = "imap.mail.me.com";
		SetupOption.IncomingMailServerPort = 993;
		SetupOption.UseSecureConnectionForIncomingMail = True;
		Return Result;
	EndIf;
	
	// outlook.com
	If ServerNameInAccount = "outlook.com" Then
		SetupOption = Result.Add();
		SetupOption.IncomingMailServer = "imap-mail.outlook.com";
		SetupOption.IncomingMailServerPort = 993;
		SetupOption.UseSecureConnectionForIncomingMail = True;
		Return Result;
	EndIf;

	// Standard settings suitable for popular email services, such as Gmail. Server name with the "imap.
	// " prefix, secure connection
	SetupOption = Result.Add();
	SetupOption.IncomingMailServer = "imap." + ServerNameInAccount;
	SetupOption.IncomingMailServerPort = 993;
	SetupOption.UseSecureConnectionForIncomingMail = True;
	
	// Server name with the "mail." prefix, secure connection.
	SetupOption = Result.Add();
	SetupOption.IncomingMailServer = "mail." + ServerNameInAccount;
	SetupOption.IncomingMailServerPort = 993;
	SetupOption.UseSecureConnectionForIncomingMail = True;
	
	// Server name without the "imap." prefix, secure connection.
	SetupOption = Result.Add();
	SetupOption.IncomingMailServer = ServerNameInAccount;
	SetupOption.IncomingMailServerPort = 993;
	SetupOption.UseSecureConnectionForIncomingMail = True;
	
	// Server name with the "imap." prefix, insecure connection.
	SetupOption = Result.Add();
	SetupOption.IncomingMailServer = "imap." + ServerNameInAccount;
	SetupOption.IncomingMailServerPort = 143;
	SetupOption.UseSecureConnectionForIncomingMail = False;
	
	// Server name with the "mail." prefix, insecure connection.
	SetupOption = Result.Add();
	SetupOption.IncomingMailServer = "mail." + ServerNameInAccount;
	SetupOption.IncomingMailServerPort = 143;
	SetupOption.UseSecureConnectionForIncomingMail = False;
	
	// Server name without the "imap." prefix, insecure connection.
	SetupOption = Result.Add();
	SetupOption.IncomingMailServer = ServerNameInAccount;
	SetupOption.IncomingMailServerPort = 143;
	SetupOption.UseSecureConnectionForIncomingMail = False;
	
	Return Result;
	
EndFunction

Function POPServerConnectionSettingsOptions(EmailAddress)
	
	Position = StrFind(EmailAddress, "@");
	ServerNameInAccount = Mid(EmailAddress, Position + 1);
	
	Result = New ValueTable;
	Result.Columns.Add("IncomingMailServer");
	Result.Columns.Add("IncomingMailServerPort");
	Result.Columns.Add("UseSecureConnectionForIncomingMail");
	
	// Standard settings suitable for popular email services, such as Gmail. Server name with the "pop." 
	// prefix, secure connection
	SetupOption = Result.Add();
	SetupOption.IncomingMailServer = "pop." + ServerNameInAccount;
	SetupOption.IncomingMailServerPort = 995;
	SetupOption.UseSecureConnectionForIncomingMail = True;
	
	// Server name with the "pop3." prefix, secure connection.
	SetupOption = Result.Add();
	SetupOption.IncomingMailServer = "pop3." + ServerNameInAccount;
	SetupOption.IncomingMailServerPort = 995;
	SetupOption.UseSecureConnectionForIncomingMail = True;
	
	// Server name with the "mail." prefix, secure connection.
	SetupOption = Result.Add();
	SetupOption.IncomingMailServer = "mail." + ServerNameInAccount;
	SetupOption.IncomingMailServerPort = 995;
	SetupOption.UseSecureConnectionForIncomingMail = True;
	
	// Server name without a prefix, secure connection.
	SetupOption = Result.Add();
	SetupOption.IncomingMailServer = ServerNameInAccount;
	SetupOption.IncomingMailServerPort = 995;
	SetupOption.UseSecureConnectionForIncomingMail = True;
	
	// Server name with the "pop." prefix, insecure connection.
	SetupOption = Result.Add();
	SetupOption.IncomingMailServer = "pop." + ServerNameInAccount;
	SetupOption.IncomingMailServerPort = 110;
	SetupOption.UseSecureConnectionForIncomingMail = False;
	
	// Server name with the "pop3." prefix, insecure connection.
	SetupOption = Result.Add();
	SetupOption.IncomingMailServer = "pop3." + ServerNameInAccount;
	SetupOption.IncomingMailServerPort = 110;
	SetupOption.UseSecureConnectionForIncomingMail = False;
	
	// Server name with the "mail." prefix, insecure connection.
	SetupOption = Result.Add();
	SetupOption.IncomingMailServer = "mail." + ServerNameInAccount;
	SetupOption.IncomingMailServerPort = 110;
	SetupOption.UseSecureConnectionForIncomingMail = False;
	
	// Server name without a prefix, insecure connection.
	SetupOption = Result.Add();
	SetupOption.IncomingMailServer = ServerNameInAccount;
	SetupOption.IncomingMailServerPort = 110;
	SetupOption.UseSecureConnectionForIncomingMail = False;
	
	Return Result;
	
EndFunction

Function SMTPServerConnectionSettingsOptions(EmailAddress) Export
	
	Position = StrFind(EmailAddress, "@");
	ServerNameInAccount = Mid(EmailAddress, Position + 1);
	
	Result = New ValueTable;
	Result.Columns.Add("OutgoingMailServer");
	Result.Columns.Add("OutgoingMailServerPort");
	Result.Columns.Add("UseSecureConnectionForOutgoingMail");
	
	// icloud.com
	If ServerNameInAccount = "icloud.com" Then
		SetupOption = Result.Add();
		SetupOption.OutgoingMailServer = "smtp.mail.me.com";
		SetupOption.OutgoingMailServerPort = 587;
		SetupOption.UseSecureConnectionForOutgoingMail = False;
		Return Result;
	EndIf;
	
	// outlook.com
	If ServerNameInAccount = "outlook.com" Then
		SetupOption = Result.Add();
		SetupOption.OutgoingMailServer = "smtp-mail.outlook.com";
		SetupOption.OutgoingMailServerPort = 587;
		SetupOption.UseSecureConnectionForOutgoingMail = False;
		Return Result;
	EndIf;
	
	// Standard settings suitable for popular email services, such as Gmail. Server name with the "smtp.
	// " prefix, secure connection, port 465
	SetupOption = Result.Add();
	SetupOption.OutgoingMailServer = "smtp." + ServerNameInAccount;
	SetupOption.OutgoingMailServerPort = 465;
	SetupOption.UseSecureConnectionForOutgoingMail = True;
	
	// Server name with the "mail." prefix, secure connection, port 465.
	SetupOption = Result.Add();
	SetupOption.OutgoingMailServer = "mail." + ServerNameInAccount;
	SetupOption.OutgoingMailServerPort = 465;
	SetupOption.UseSecureConnectionForOutgoingMail = True;
	
	// Server name without a prefix, secure connection, port 465.
	SetupOption = Result.Add();
	SetupOption.OutgoingMailServer = ServerNameInAccount;
	SetupOption.OutgoingMailServerPort = 465;
	SetupOption.UseSecureConnectionForOutgoingMail = True;
	
	// Server name with the "smtp." prefix, secure connection (STARTTLS), port 587
	SetupOption = Result.Add();
	SetupOption.OutgoingMailServer = "smtp." + ServerNameInAccount;
	SetupOption.OutgoingMailServerPort = 587;
	SetupOption.UseSecureConnectionForOutgoingMail = False;
	
	// Server name with the "mail." prefix, secure connection (STARTTLS), port 587
	SetupOption = Result.Add();
	SetupOption.OutgoingMailServer = "mail." + ServerNameInAccount;
	SetupOption.OutgoingMailServerPort = 587;
	SetupOption.UseSecureConnectionForOutgoingMail = False;
	
	// Server name without a prefix, secure connection (STARTTLS), port 587
	SetupOption = Result.Add();
	SetupOption.OutgoingMailServer = ServerNameInAccount;
	SetupOption.OutgoingMailServerPort = 587;
	SetupOption.UseSecureConnectionForOutgoingMail = False;
	
	// Server name with the "smtp." prefix, insecure connection
	SetupOption = Result.Add();
	SetupOption.OutgoingMailServer = "smtp." + ServerNameInAccount;
	SetupOption.OutgoingMailServerPort = 25;
	SetupOption.UseSecureConnectionForOutgoingMail = False;
	
	// Server name with the "mail." prefix, insecure connection.
	SetupOption = Result.Add();
	SetupOption.OutgoingMailServer = "mail." + ServerNameInAccount;
	SetupOption.OutgoingMailServerPort = 25;
	SetupOption.UseSecureConnectionForOutgoingMail = False;
	
	// Server name without a prefix, insecure connection.
	SetupOption = Result.Add();
	SetupOption.OutgoingMailServer = ServerNameInAccount;
	SetupOption.OutgoingMailServerPort = 25;
	SetupOption.UseSecureConnectionForOutgoingMail = False;
	
	Return Result;
	
EndFunction

Function AttributesRequiringPasswordToChange() Export
	
	Return "UseForSending,UseForReceiving,IncomingMailServer,OutgoingMailServer,AccountOwner,UseSecureConnectionForIncomingMail,UseSecureConnectionForOutgoingMail,UseSafeAuthorizationAtIncomingMailServer,UseSafeAuthorizationAtOutgoingMailServer,User,SMTPUser";
	
EndFunction

Function PasswordCheckIsRequired(Ref, AttributeValuesBeforeWrite) Export
	
	If Ref.IsEmpty() Then
		Return False;
	EndIf;
	
	AttributesList = AttributesRequiringPasswordToChange();
	WrittenAttributeValues = Common.ObjectAttributesValues(Ref, AttributesList);
	
	Result = ValueIsFilled(WrittenAttributeValues.AccountOwner);
	If Result Then
		BeforeChange = New Structure(AttributesList);
		FillPropertyValues(BeforeChange, WrittenAttributeValues);
		AfterChange = New Structure(AttributesList);
		FillPropertyValues(AfterChange, AttributeValuesBeforeWrite);
		Result = Common.ValueToXMLString(BeforeChange) <> Common.ValueToXMLString(AfterChange);
	EndIf;
	
	Return Result;
	
EndFunction

#EndRegion

#EndIf