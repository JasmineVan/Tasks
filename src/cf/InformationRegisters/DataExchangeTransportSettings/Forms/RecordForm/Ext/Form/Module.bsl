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
	
	SetFormItemsVisibility();
	
	If ValueIsFilled(Record.DefaultExchangeMessagesTransportKind) Then
		
		PageName = "TransportSettings[TransportKind]";
		PageName = StrReplace(PageName, "[TransportKind]"
		, Common.EnumValueName(Record.DefaultExchangeMessagesTransportKind));
		
		If Items[PageName].Visible Then
			
			Items.TransportKindsPages.CurrentPage = Items[PageName];
			
		EndIf;
		
	EndIf;
	
	EventLogEventEstablishWebServiceConnection 
		= DataExchangeServer.EventLogEventEstablishWebServiceConnection();
	
	If Common.SubsystemExists("StandardSubsystems.GetFilesFromInternet") Then
		Items.InternetAccessParameters.Visible = True;
		Items.InternetAccessParameters1.Visible = True;
	Else
		Items.InternetAccessParameters.Visible = False;
		Items.InternetAccessParameters1.Visible = False;
	EndIf;
	
	If ValueIsFilled(Record.Correspondent) Then
		SetPrivilegedMode(True);
		Passwords = Common.ReadDataFromSecureStorage(Record.Correspondent, "COMUserPassword, FTPConnectionPassword, WSPassword, ArchivePasswordExchangeMessages");
		SetPrivilegedMode(False);
		COMUserPassword = ?(ValueIsFilled(Passwords.COMUserPassword), ThisObject.UUID, "");
		FTPConnectionPassword = ?(ValueIsFilled(Passwords.FTPConnectionPassword), ThisObject.UUID, "");
		WSPassword = ?(ValueIsFilled(Passwords.WSPassword), ThisObject.UUID, "");
		ArchivePasswordExchangeMessages = ?(ValueIsFilled(Passwords.ArchivePasswordExchangeMessages), ThisObject.UUID, "");
	EndIf;
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	InfobaseOperatingModeOnChange();
	
	OSAuthenticationOnChange();
	
EndProcedure

&AtClient
Procedure BeforeWrite(Cancel, WriteParameters)
	
	If WriteParameters.Property("ExternalResourcesAllowed") Then
		Return;
	EndIf;
	
	Cancel = True;
	
	ClosingNotification = New NotifyDescription("AllowExternalResourceCompletion", ThisObject, WriteParameters);
	If StandardSubsystemsClient.ApplicationStartCompleted()
		AND CommonClient.SubsystemExists("StandardSubsystems.SecurityProfiles") Then
		Queries = CreateRequestToUseExternalResources(Record, True, True, True, True);
		ModuleSafeModeManagerClient = CommonClient.CommonModule("SafeModeManagerClient");
		ModuleSafeModeManagerClient.ApplyExternalResourceRequests(Queries, ThisObject, ClosingNotification);
	Else
		ExecuteNotifyProcessing(ClosingNotification, DialogReturnCode.OK);
	EndIf;
	
EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)
	
	If WriteParameters.Property("WriteAndClose") Then
		Close();
	EndIf;
	
EndProcedure

&AtServer
Procedure OnWriteAtServer(Cancel, CurrentObject, WriteParameters)
	SetPrivilegedMode(True);
	If COMUserPasswordChanged Then
		Common.WriteDataToSecureStorage(CurrentObject.Correspondent, COMUserPassword, "COMUserPassword")
	EndIf;
	If FTPConnectionPasswordChanged Then
		Common.WriteDataToSecureStorage(CurrentObject.Correspondent, FTPConnectionPassword, "FTPConnectionPassword")
	EndIf;
	If WSPasswordChanged Then
		Common.WriteDataToSecureStorage(CurrentObject.Correspondent, WSPassword, "WSPassword")
	EndIf;
	If ExchangeMessageArchivePasswordChanged Then
		Common.WriteDataToSecureStorage(CurrentObject.Correspondent, ArchivePasswordExchangeMessages, "ArchivePasswordExchangeMessages")
	EndIf;
	SetPrivilegedMode(False);
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure FILEInformationExchangeDirectoryStartChoice(Item, ChoiceData, StandardProcessing)
	
	DataExchangeClient.FileDirectoryChoiceHandler(Record, "FILEInformationExchangeDirectory", StandardProcessing);
	
EndProcedure

&AtClient
Procedure FILEInformationExchangeDirectoryOpen(Item, StandardProcessing)
	
	DataExchangeClient.FileOrDirectoryOpenHandler(Record, "FILEInformationExchangeDirectory", StandardProcessing)
	
EndProcedure

&AtClient
Procedure COMInfobaseDirectoryStartChoice(Item, ChoiceData, StandardProcessing)
	
	DataExchangeClient.FileDirectoryChoiceHandler(Record, "COMInfobaseDirectory", StandardProcessing);
	
EndProcedure

&AtClient
Procedure COMInfobaseDirectoryOpen(Item, StandardProcessing)

DataExchangeClient.FileOrDirectoryOpenHandler(Record, "COMInfobaseDirectory", StandardProcessing)

EndProcedure

&AtClient
Procedure COMInfobaseOperatingModeOnChange(Item)
	
	InfobaseOperatingModeOnChange();
	
EndProcedure

&AtClient
Procedure COMOSAuthenticationOnChange(Item)
	
	OSAuthenticationOnChange();
	
EndProcedure

&AtClient
Procedure WSPasswordOnChange(Item)
	WSPasswordChanged = True;
EndProcedure

&AtClient
Procedure ArchivePasswordExchange1MessagesOnChange(Item)
	ExchangeMessageArchivePasswordChanged = True;
EndProcedure

&AtClient
Procedure FTPConnectionPasswordOnChange(Item)
	FTPConnectionPasswordChanged = True;
EndProcedure

&AtClient
Procedure ArchivePasswordExchangeMessagesOnChange(Item)
	ExchangeMessageArchivePasswordChanged = True;
EndProcedure

&AtClient
Procedure ArchivePasswordExchange2MessagesOnChange(Item)
	ExchangeMessageArchivePasswordChanged = True;
EndProcedure

&AtClient
Procedure COMUserPasswordOnChange(Item)
	COMUserPasswordChanged = True;
EndProcedure

#EndRegion

#Region FormCommandHandlers

&AtClient
Procedure TestCOMConnection(Command)
	
	ClosingNotification = New NotifyDescription("TestCOMConnectionCompletion", ThisObject);
	If CommonClient.SubsystemExists("StandardSubsystems.SecurityProfiles") Then
		Queries = CreateRequestToUseExternalResources(Record, True, False, False, False);
		ModuleSafeModeManagerClient = CommonClient.CommonModule("SafeModeManagerClient");
		ModuleSafeModeManagerClient.ApplyExternalResourceRequests(Queries, ThisObject, ClosingNotification);
	Else
		ExecuteNotifyProcessing(ClosingNotification, DialogReturnCode.OK);
	EndIf;
	
EndProcedure

&AtClient
Procedure TestWSConnection(Command)
	
	ClosingNotification = New NotifyDescription("TestWSConnectionCompletion", ThisObject);
	If CommonClient.SubsystemExists("StandardSubsystems.SecurityProfiles") Then
		Queries = CreateRequestToUseExternalResources(Record, False, False, True, False);
		ModuleSafeModeManagerClient = CommonClient.CommonModule("SafeModeManagerClient");
		ModuleSafeModeManagerClient.ApplyExternalResourceRequests(Queries, ThisObject, ClosingNotification);
	Else
		ExecuteNotifyProcessing(ClosingNotification, DialogReturnCode.OK);
	EndIf;
	
EndProcedure

&AtClient
Procedure TestFILEConnection(Command)
	
	ClosingNotification = New NotifyDescription("TestFILEConnectionCompletion", ThisObject);
	If CommonClient.SubsystemExists("StandardSubsystems.SecurityProfiles") Then
		Queries = CreateRequestToUseExternalResources(Record, False, True, False, False);
		ModuleSafeModeManagerClient = CommonClient.CommonModule("SafeModeManagerClient");
		ModuleSafeModeManagerClient.ApplyExternalResourceRequests(Queries, ThisObject, ClosingNotification);
	Else
		ExecuteNotifyProcessing(ClosingNotification, DialogReturnCode.OK);
	EndIf;
	
EndProcedure

&AtClient
Procedure TestFTPConnection(Command)
	
	ClosingNotification = New NotifyDescription("TestFTPConnectionCompletion", ThisObject);
	If CommonClient.SubsystemExists("StandardSubsystems.SecurityProfiles") Then
		Queries = CreateRequestToUseExternalResources(Record, False, False, False, True);
		ModuleSafeModeManagerClient = CommonClient.CommonModule("SafeModeManagerClient");
		ModuleSafeModeManagerClient.ApplyExternalResourceRequests(Queries, ThisObject, ClosingNotification);
	Else
		ExecuteNotifyProcessing(ClosingNotification, DialogReturnCode.OK);
	EndIf;
	
EndProcedure

&AtClient
Procedure TestEMAILConnection(Command)
	
	TestConnection("EMAIL");
	
EndProcedure

&AtClient
Procedure InternetAccessParameters(Command)
	
	DataExchangeClient.OpenProxyServerParametersForm();
	
EndProcedure

&AtClient
Procedure WriteAndClose(Command)
	
	WriteParameters = New Structure;
	WriteParameters.Insert("WriteAndClose");
	Write(WriteParameters);

EndProcedure


#EndRegion

#Region Private

&AtClient
Procedure TestConnection(TransportKindAsString, NewPassword = Undefined)
	
	Cancel = False;
	
	ClearMessages();
	
	TestConnectionAtServer(Cancel, TransportKindAsString, NewPassword);
	
	NotifyUserAboutConnectionResult(Cancel);
	
EndProcedure

&AtServer
Procedure TestConnectionAtServer(Cancel, TransportKindAsString, NewPassword)
	
	ErrorMessage = "";
	
	PasswordsToCheck = Undefined;
	AddPasswordToCheck(PasswordsToCheck, "COMUserPassword");
	AddPasswordToCheck(PasswordsToCheck, "FTPConnectionPassword");
	AddPasswordToCheck(PasswordsToCheck, "WSPassword");
	AddPasswordToCheck(PasswordsToCheck, "ArchivePasswordExchangeMessages");
	
	DataExchangeServer.CheckExchangeMessageTransportDataProcessorAttachment(Cancel, Record,
		Enums.ExchangeMessagesTransportTypes[TransportKindAsString], ErrorMessage, PasswordsToCheck);
		
	If Cancel Then
		Common.MessageToUser(ErrorMessage, , , , Cancel);
	EndIf;
	
EndProcedure

&AtServer
Function AddPasswordToCheck(Passwords, PasswordKind)
	
	If ThisObject[PasswordKind + "Changed"] Then
		If Passwords = Undefined Then
			Passwords = New Structure;
		EndIf;
		
		Passwords.Insert(PasswordKind, ThisObject[PasswordKind]);
	EndIf;
	
EndFunction

&AtServer
Procedure ExecuteExternalConnectionTest(Cancel)
	
	ConnectionParameters = New Structure;
	ConnectionParameters.Insert("COMInfobaseOperatingMode", Record.COMInfobaseOperatingMode);
	ConnectionParameters.Insert("COMOperatingSystemAuthentication", Record.COMOperatingSystemAuthentication);
	ConnectionParameters.Insert("COM1CEnterpriseServerSideInfobaseName",
		Record.COM1CEnterpriseServerSideInfobaseName);
	ConnectionParameters.Insert("COMUsername", Record.COMUsername);
	ConnectionParameters.Insert("COM1CEnterpriseServerName", Record.COM1CEnterpriseServerName);
	ConnectionParameters.Insert("COMInfobaseDirectory", Record.COMInfobaseDirectory);
	
	If Not COMUserPasswordChanged Then
		
		SetPrivilegedMode(True);
		ConnectionParameters.Insert("COMUserPassword",
			Common.ReadDataFromSecureStorage(Record.Correspondent, "COMUserPassword", True));
		SetPrivilegedMode(False);
		
	Else
		
		ConnectionParameters.Insert("COMUserPassword", COMUserPassword);
		
	EndIf;
	
	// Attempting to establish external connection.
	Result = DataExchangeServer.EstablishExternalConnectionWithInfobase(ConnectionParameters);
	// Displaying error message.
	If Result.Connection = Undefined Then
		Common.MessageToUser(Result.BriefErrorDescription, , , , Cancel);
	EndIf;
	
EndProcedure

&AtServer
Procedure TestWSConnectionEstablished(Cancel)
	
	ConnectionParameters = DataExchangeServer.WSParameterStructure();
	FillPropertyValues(ConnectionParameters, Record);
	
	If Not WSPasswordChanged Then
		
		SetPrivilegedMode(True);
		ConnectionParameters.WSPassword = Common.ReadDataFromSecureStorage(Record.Correspondent, "WSPassword", True);
		SetPrivilegedMode(False);
		
	Else
		
		ConnectionParameters.WSPassword = WSPassword;
		
	EndIf;
	
	UserMessage = "";
	If Not DataExchangeServer.CorrespondentConnectionEstablished(Record.Correspondent, ConnectionParameters, UserMessage) Then
		Common.MessageToUser(UserMessage,,,, Cancel);
	EndIf;
	
EndProcedure

&AtServer
Procedure SetFormItemsVisibility()
	
	UsedTransports = New Array;
	
	If ValueIsFilled(Record.Correspondent) Then
		
		UsedTransports = DataExchangeCached.UsedExchangeMessagesTransports(Record.Correspondent);
		
	EndIf;
	
	For Each TransportTypePage In Items.TransportKindsPages.ChildItems Do
		
		TransportTypePage.Visible = False;
		
	EndDo;
	
	Items.DefaultExchangeMessagesTransportKind.ChoiceList.Clear();
	
	For Each Item In UsedTransports Do
		
		FormItemName = "TransportSettings[TransportKind]";
		FormItemName = StrReplace(FormItemName, "[TransportKind]", Common.EnumValueName(Item));
		
		Items[FormItemName].Visible = True;
		
		Items.DefaultExchangeMessagesTransportKind.ChoiceList.Add(Item, String(Item));
		
	EndDo;
	
	If UsedTransports.Count() = 1 Then
		
		Items.TransportKindsPages.PagesRepresentation = FormPagesRepresentation.None;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure NotifyUserAboutConnectionResult(Val ConnectionError)
	
	WarningText = ?(ConnectionError, NStr("ru = 'Не удалось установить подключение.'; en = 'Cannot establish connection.'; pl = 'Połączenie nie powiodło się.';de = 'Kann nicht verbinden.';ro = 'Eșec la stabilirea conexiunii.';tr = 'Bağlantı yapılamadı.'; es_ES = 'No se puede conectar.'"),
											   NStr("ru = 'Подключение успешно установлено.'; en = 'Connection established.'; pl = 'Połączenie zostało pomyślnie ustanowione.';de = 'Die Verbindung wurde erfolgreich hergestellt.';ro = 'Conexiunea a fost stabilită cu succes.';tr = 'Bağlantı başarıyla yapıldı.'; es_ES = 'Conexión se ha establecido con éxito.'"));
	ShowMessageBox(, WarningText);
	
EndProcedure

&AtClient
Procedure InfobaseOperatingModeOnChange()
	
	CurrentPage = ?(Record.COMInfobaseOperatingMode = 0, Items.InfobaseFileModePage, Items.InfobaseClientServerModePage);
	
	Items.InfobaseModes.CurrentPage = CurrentPage;
	
EndProcedure

&AtClient
Procedure OSAuthenticationOnChange()
	
	Items.COMUsername.Enabled    = Not Record.COMOperatingSystemAuthentication;
	Items.COMUserPassword.Enabled = Not Record.COMOperatingSystemAuthentication;
	
EndProcedure

&AtClient
Procedure AllowExternalResourceCompletion(Result, WriteParameters) Export
	
	If Result = DialogReturnCode.OK Then
		If WriteParameters.Property("WriteAndClose") Then
			AttachIdleHandler("WriteAndCloseAfterExternalResourcesPermissionQuery", 0.1, True);
		Else
			AttachIdleHandler("WriteAfterExternalResourcesPermissionQuery", 0.1, True);
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure WriteAndCloseAfterExternalResourcesPermissionQuery()
	
	WriteParameters = New Structure;
	WriteParameters.Insert("ExternalResourcesAllowed");
	WriteParameters.Insert("WriteAndClose");
	
	Write(WriteParameters);
	
EndProcedure

&AtClient
Procedure WriteAfterExternalResourcesPermissionQuery()
	
	WriteParameters = New Structure;
	WriteParameters.Insert("ExternalResourcesAllowed");
	
	Write(WriteParameters);
	
EndProcedure

&AtServerNoContext
Function CreateRequestToUseExternalResources(Val Record, RequestCOM,
	RequestFILE, RequestWS, RequestFTP)
	
	PermissionsRequests = New Array;
	
	QueryParameters = InformationRegisters.DataExchangeTransportSettings.RequiestToUseExternalResourcesParameters();
	QueryParameters.RequestCOM  = RequestCOM;
	QueryParameters.RequestFILE = RequestFILE;
	QueryParameters.RequestWS   = RequestWS;
	QueryParameters.RequestFTP  = RequestFTP;
	
	InformationRegisters.DataExchangeTransportSettings.RequestToUseExternalResources(PermissionsRequests,
		Record, QueryParameters);
		
	Return PermissionsRequests;
	
EndFunction

&AtClient
Procedure TestFILEConnectionCompletion(Result, AdditionalParameters) Export
	
	If Result = DialogReturnCode.OK Then
		
		TestConnection("FILE");
		
	EndIf;
	
EndProcedure

&AtClient
Procedure TestFTPConnectionCompletion(Result, AdditionalParameters) Export
	
	If Result = DialogReturnCode.OK Then
		
		TestConnection("FTP", ?(FTPConnectionPasswordChanged, FTPConnectionPassword, Undefined));
		
	EndIf;
	
EndProcedure

&AtClient
Procedure TestWSConnectionCompletion(Result, AdditionalParameters) Export
	
	If Result = DialogReturnCode.OK Then
		
		Cancel = False;
		
		ClearMessages();
		
		TestWSConnectionEstablished(Cancel);
		
		NotifyUserAboutConnectionResult(Cancel);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure TestCOMConnectionCompletion(Result, AdditionalParameters) Export
	
	If Result = DialogReturnCode.OK Then
		
		ClearMessages();
		
		If CommonClient.FileInfobase() Then
			Notification = New NotifyDescription("TestCOMConnectionCompletionAfterCheckCOMConnector", ThisObject);
			CommonClient.RegisterCOMConnector(False, Notification);
		Else 
			TestCOMConnectionCompletionAfterCheckCOMConnector(True, Undefined);
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure TestCOMConnectionCompletionAfterCheckCOMConnector(Registered, Context) Export
	
	If Registered Then 
		
		Cancel = False;
		
		ExecuteExternalConnectionTest(Cancel);
		NotifyUserAboutConnectionResult(Cancel)
		
	EndIf;
	
EndProcedure

#EndRegion
