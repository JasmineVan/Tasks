///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Internal

// Adds a record to the register by the passed structure values.
Procedure AddRecord(RecordStructure) Export
	
	BeginTransaction();
	Try
		DataExchangeServer.AddRecordToInformationRegister(RecordStructure, "DataExchangeTransportSettings");
		
		WritePassword("COMUserPassword", "COMUserPassword", RecordStructure);
		WritePassword("FTPConnectionPassword", "FTPConnectionPassword", RecordStructure);
		WritePassword("WSPassword", "WSPassword", RecordStructure);
		WritePassword("ArchivePasswordExchangeMessages", "ArchivePasswordExchangeMessages", RecordStructure);
		
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;
	
EndProcedure

// Updates a register record based on the passed structure values.
Procedure UpdateRecord(RecordStructure) Export
	
	BeginTransaction();
	Try
		DataExchangeServer.UpdateInformationRegisterRecord(RecordStructure, "DataExchangeTransportSettings");
		
		WritePassword("COMUserPassword", "COMUserPassword", RecordStructure);
		WritePassword("FTPConnectionPassword", "FTPConnectionPassword", RecordStructure);
		WritePassword("WSPassword", "WSPassword", RecordStructure);
		WritePassword("ArchivePasswordExchangeMessages", "ArchivePasswordExchangeMessages", RecordStructure);
		
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;
	
EndProcedure

// For internal use.
// 
Function TransportSettingsWS(Correspondent, AuthenticationParameters = Undefined) Export
	
	SetPrivilegedMode(True);
	
	SettingsStructure = ExchangeTransportSettingsContent("WS");
	Result = GetRegisterDataByStructure(Correspondent, SettingsStructure);
	
	WSPassword = Common.ReadDataFromSecureStorage(Correspondent, "WSPassword");
	SetPrivilegedMode(False);
	
	If TypeOf(WSPassword) = Type("String")
		Or WSPassword = Undefined Then
		
		Result.Insert("WSPassword", WSPassword);
	Else
		Raise NStr("ru='Ошибка при извлечении пароля из безопасного хранилища.'; en = 'An error occurred while extracting password from secure storage.'; pl = 'Błąd podczas pobierania hasła z bezpiecznej przechowalni.';de = 'Fehler beim Abrufen des Passworts vom sicheren Speicher.';ro = 'Eroare la extragerea parolei din storagele securizat.';tr = 'Güvenli depolamadan şifre alınırken hata oluştu.'; es_ES = 'Error al extraer la contraseña del almacenamiento seguro.'");
	EndIf;
	
	If TypeOf(AuthenticationParameters) = Type("Structure") Then // Initializing exchange using the current user name.
		
		If AuthenticationParameters.UseCurrentUser Then
			
			Result.WSUsername = InfoBaseUsers.CurrentUser().Name;
			
		EndIf;
		
		Password = Undefined;
		
		If AuthenticationParameters.Property("Password", Password)
			AND Password <> Undefined Then // The password is specified on the client
			
			Result.WSPassword = Password;
			
		Else // The password is not specified on the client.
			
			Password = DataExchangeServer.DataSynchronizationPassword(Correspondent);
			
			Result.WSPassword = ?(Password = Undefined, "", Password);
			
		EndIf;
		
	ElsIf TypeOf(AuthenticationParameters) = Type("String") Then
		Result.WSPassword = AuthenticationParameters;
	EndIf;
	
	Return Result;
EndFunction

Function ExternalSystemTransportSettings(Correspondent) Export
	
	Query = New Query(
	"SELECT
	|	DataExchangeTransportSettings.ExternalSystemConnectionParameters AS ExternalSystemConnectionParameters
	|FROM
	|	InformationRegister.DataExchangeTransportSettings AS DataExchangeTransportSettings
	|WHERE
	|	DataExchangeTransportSettings.Correspondent = &Correspondent
	|	AND DataExchangeTransportSettings.DefaultExchangeMessagesTransportKind = &DefaultExchangeMessagesTransportKind");
	Query.SetParameter("Correspondent", Correspondent);
	Query.SetParameter("DefaultExchangeMessagesTransportKind", Enums.ExchangeMessagesTransportTypes.ExternalSystem);
	
	SetPrivilegedMode(True);
	
	Selection = Query.Execute().Select();
	If Selection.Next() Then
		Return Selection.ExternalSystemConnectionParameters.Get();
	EndIf;
	
	Return Undefined;
	
EndFunction

Procedure SaveExternalSystemTransportSettings(Correspondent, AttachmentParameters) Export
	
	SetPrivilegedMode(True);
	
	RecordManager = CreateRecordManager();
	RecordManager.Correspondent = Correspondent;
	RecordManager.DefaultExchangeMessagesTransportKind = Enums.ExchangeMessagesTransportTypes.ExternalSystem;
	RecordManager.ExternalSystemConnectionParameters = New ValueStorage(AttachmentParameters, New Deflation(9));
	
	RecordManager.Write(True);
	
EndProcedure

#EndRegion

#Region Private

// See SafeModeManagerOverridable.OnFillPermissionsToAccessExternalResources. 
Procedure OnFillPermissionsToAccessExternalResources(PermissionsRequests) Export
	
	TransportSettings = SavedTransportSettings();
	
	While TransportSettings.Next() Do
		
		QueryParameters = RequiestToUseExternalResourcesParameters();
		RequestToUseExternalResources(PermissionsRequests, TransportSettings, QueryParameters);
		
	EndDo;
	
EndProcedure

Function SavedTransportSettings()
	
	Query = New Query;
	Query.Text = "SELECT
	|	TransportSettings.Correspondent AS Correspondent,
	|	TransportSettings.FTPConnectionPath,
	|	TransportSettings.FILEInformationExchangeDirectory,
	|	TransportSettings.WSWebServiceURL,
	|	TransportSettings.COMInfobaseDirectory,
	|	TransportSettings.COM1CEnterpriseServerSideInfobaseName,
	|	TransportSettings.FTPConnectionPath AS FTPConnectionPath,
	|	TransportSettings.FTPConnectionPort AS FTPConnectionPort,
	|	TransportSettings.WSWebServiceURL AS WSWebServiceURL,
	|	TransportSettings.FILEInformationExchangeDirectory AS FILEInformationExchangeDirectory
	|FROM
	|	InformationRegister.DataExchangeTransportSettings AS TransportSettings";
	
	QueryResult = Query.Execute();
	
	Return QueryResult.Select();
	
EndFunction

Function RequiestToUseExternalResourcesParameters() Export
	
	Parameters = New Structure;
	Parameters.Insert("RequestCOM",  True);
	Parameters.Insert("RequestFILE", True);
	Parameters.Insert("RequestWS",   True);
	Parameters.Insert("RequestFTP",  True);
	
	Return Parameters;
	
EndFunction

Procedure RequestToUseExternalResources(PermissionsRequests, Record, QueryParameters) Export
	
	Permissions = New Array;
	
	ModuleSafeModeManager = Common.CommonModule("SafeModeManager");
	
	If QueryParameters.RequestFTP AND Not IsBlankString(Record.FTPConnectionPath) Then
		
		AddressStructure = CommonClientServer.URIStructure(Record.FTPConnectionPath);
		Permissions.Add(ModuleSafeModeManager.PermissionToUseInternetResource(
			AddressStructure.Schema, AddressStructure.Host, Record.FTPConnectionPort));
		
	EndIf;
	
	If QueryParameters.RequestFILE AND Not IsBlankString(Record.FILEInformationExchangeDirectory) Then
		
		Permissions.Add(ModuleSafeModeManager.PermissionToUseFileSystemDirectory(
			Record.FILEInformationExchangeDirectory, True, True));
		
	EndIf;
	
	If QueryParameters.RequestWS AND Not IsBlankString(Record.WSWebServiceURL) Then
		
		AddressStructure = CommonClientServer.URIStructure(Record.WSWebServiceURL);
		If ValueIsFilled(AddressStructure.Schema) Then
			Permissions.Add(ModuleSafeModeManager.PermissionToUseInternetResource(
				AddressStructure.Schema, AddressStructure.Host, AddressStructure.Port));
		EndIf;
		
	EndIf;
	
	If QueryParameters.RequestCOM AND (Not IsBlankString(Record.COMInfobaseDirectory)
		Or Not IsBlankString(Record.COM1CEnterpriseServerSideInfobaseName)) Then
		
		COMConnectorName = CommonClientServer.COMConnectorName();
		Permissions.Add(ModuleSafeModeManager.PermissionToCreateCOMClass(
			COMConnectorName, Common.COMConnectorID(COMConnectorName)));
		
	EndIf;
	
	// Permissions to perform synchronization by email are requested in the Email operations subsystem.
	
	If Permissions.Count() > 0 Then
		
		PermissionsRequests.Add(
			ModuleSafeModeManager.RequestToUseExternalResources(Permissions, Record.Correspondent));
		
	EndIf;
	
EndProcedure

Procedure WritePassword(PasswordNameInStructure, PasswordNameOnWrite, RecordStructure)
	
	If RecordStructure.Property(PasswordNameInStructure) Then
		SetPrivilegedMode(True);
		Common.WriteDataToSecureStorage(RecordStructure.Correspondent, RecordStructure[PasswordNameInStructure], PasswordNameOnWrite);
		SetPrivilegedMode(False);
	EndIf;
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// The functions of receiving setting values for exchange plan node.

// Retrieves settings of the specified transport kind.
// If the transport kind is not specified (ExchangeTransportKind = Undefined), it receives settings 
// of all transport kinds existing in the system.
//
Function TransportSettings(Val Correspondent, Val ExchangeTransportKind = Undefined) Export
	
	SetPrivilegedMode(True);
	
	RecordManager = CreateRecordManager();
	RecordManager.Correspondent = Correspondent;
	RecordManager.Read();
	
	If RecordManager.Selected() Then
		Return ExchangeTransportSettings(Correspondent, ExchangeTransportKind);
	ElsIf Common.DataSeparationEnabled()
		AND Common.SeparatedDataUsageAvailable() Then
		Return InformationRegisters["DataAreaExchangeTransportSettings"].TransportSettings(Correspondent);
	EndIf;
	
	Return ExchangeTransportSettings(Correspondent, ExchangeTransportKind);
	
EndFunction

Function DefaultExchangeMessagesTransportKind(Correspondent) Export
	
	SetPrivilegedMode(True);
	
	// Function return value.
	MessagesTransportKind = Undefined;
	
	Query = New Query(
	"SELECT
	|	TransportSettings.DefaultExchangeMessagesTransportKind AS DefaultExchangeMessagesTransportKind
	|FROM
	|	InformationRegister.DataExchangeTransportSettings AS TransportSettings
	|WHERE
	|	TransportSettings.Correspondent = &Correspondent");
	Query.SetParameter("Correspondent", Correspondent);
	
	Selection = Query.Execute().Select();
	If Selection.Next() Then
		MessagesTransportKind = Selection.DefaultExchangeMessagesTransportKind;
	EndIf;
	
	If MessagesTransportKind = Undefined
		AND Common.DataSeparationEnabled()
		AND Common.SeparatedDataUsageAvailable() Then
		Query = New Query(
		"SELECT
		|	DataAreasTransportSettings.DefaultExchangeMessagesTransportKind AS DefaultExchangeMessagesTransportKind
		|FROM
		|	InformationRegister.DataAreaExchangeTransportSettings AS DataAreaTransportSettings
		|		INNER JOIN InformationRegister.DataAreasExchangeTransportSettings AS DataAreasTransportSettings
		|		ON (DataAreasTransportSettings.CorrespondentEndpoint = DataAreaTransportSettings.CorrespondentEndpoint)
		|WHERE
		|	DataAreaTransportSettings.Correspondent = &Correspondent");
		Query.SetParameter("Correspondent", Correspondent);
	
		Selection = Query.Execute().Select();
		If Selection.Next() Then
			MessagesTransportKind = Selection.DefaultExchangeMessagesTransportKind;
		EndIf;
		
	EndIf;
	
	Return MessagesTransportKind;
	
EndFunction

Function DataExchangeDirectoryName(ExchangeMessagesTransportKind, InfobaseNode) Export
	
	// Function return value.
	Result = "";
	
	If ExchangeMessagesTransportKind = Enums.ExchangeMessagesTransportTypes.FILE Then
		
		TransportSettings = TransportSettings(InfobaseNode);
		
		Result = TransportSettings["FILEInformationExchangeDirectory"];
		
	ElsIf ExchangeMessagesTransportKind = Enums.ExchangeMessagesTransportTypes.FTP Then
		
		TransportSettings = TransportSettings(InfobaseNode);
		
		Result = TransportSettings["FTPConnectionPath"];
		
	EndIf;
	
	Return Result;
EndFunction

Function NodeTransportSettingsAreSet(Correspondent) Export
	
	Query = New Query(
	"SELECT
	|	1 AS HasSettings
	|FROM
	|	InformationRegister.DataExchangeTransportSettings AS TransportSettings
	|WHERE
	|	TransportSettings.Correspondent = &Correspondent");
	Query.SetParameter("Correspondent", Correspondent);
	
	Return Not Query.Execute().IsEmpty();
	
EndFunction

Function ConfiguredTransportTypes(InfobaseNode) Export
	
	Result = New Array;
	
	TransportSettings = TransportSettings(InfobaseNode);
	
	If Common.DataSeparationEnabled()
		AND Common.SeparatedDataUsageAvailable() Then
		
		If Not TransportSettings = Undefined Then
			If ValueIsFilled(TransportSettings.FILEInformationExchangeDirectory) Then
				Result.Add(Enums.ExchangeMessagesTransportTypes.FILE);
			EndIf;
			
			If ValueIsFilled(TransportSettings.FTPConnectionPath) Then
				Result.Add(Enums.ExchangeMessagesTransportTypes.FTP);
			EndIf;
		EndIf;
		
	Else
		If ValueIsFilled(TransportSettings.COMInfobaseDirectory) 
			Or ValueIsFilled(TransportSettings.COM1CEnterpriseServerSideInfobaseName) Then
			Result.Add(Enums.ExchangeMessagesTransportTypes.COM);
		EndIf;
		
		If ValueIsFilled(TransportSettings.EMAILUserAccount) Then
			Result.Add(Enums.ExchangeMessagesTransportTypes.EMAIL);
		EndIf;
		
		If ValueIsFilled(TransportSettings.FILEInformationExchangeDirectory) Then
			Result.Add(Enums.ExchangeMessagesTransportTypes.FILE);
		EndIf;
		
		If ValueIsFilled(TransportSettings.FTPConnectionPath) Then
			Result.Add(Enums.ExchangeMessagesTransportTypes.FTP);
		EndIf;
		
		If ValueIsFilled(TransportSettings.WSWebServiceURL) Then
			Result.Add(Enums.ExchangeMessagesTransportTypes.WS);
		EndIf;
	EndIf;
	
	Return Result;
	
EndFunction

////////////////////////////////////////////////////////////////////////////////
// Local internal procedures and functions.

// Retrieves settings of the specified transport kind.
// If the transport kind is not specified (ExchangeTransportKind = Undefined), it receives settings 
// of all transport kinds existing in the system.
//
// Parameters:
//  No.
// 
// Returns:
//  
//
Function ExchangeTransportSettings(Correspondent, ExchangeTransportKind)
	
	SettingsStructure = New Structure;
	
	// Common settings for all transport kinds.
	SettingsStructure.Insert("DefaultExchangeMessagesTransportKind");
	PasswordsList = "ArchivePasswordExchangeMessages";
	
	If ExchangeTransportKind = Undefined Then
		PasswordsList = PasswordsList + ",FTPConnectionPassword,WSPassword,COMUserPassword";
		For Each TransportKind In Enums.ExchangeMessagesTransportTypes Do
			
			TransportSettingsStructure = ExchangeTransportSettingsContent(Common.EnumValueName(TransportKind));
			
			SettingsStructure = MergeCollections(SettingsStructure, TransportSettingsStructure);
			
		EndDo;
		
	Else
		
		TransportSettingsStructure = ExchangeTransportSettingsContent(Common.EnumValueName(ExchangeTransportKind));
		SettingsStructure = MergeCollections(SettingsStructure, TransportSettingsStructure);
		
		If ExchangeTransportKind = Enums.ExchangeMessagesTransportTypes.COM Then
			PasswordsList = PasswordsList + ",COMUserPassword";
		ElsIf ExchangeTransportKind = Enums.ExchangeMessagesTransportTypes.WS Then
			PasswordsList = PasswordsList + ",WSPassword";
		ElsIf ExchangeTransportKind = Enums.ExchangeMessagesTransportTypes.FTP Then
			PasswordsList = PasswordsList + ",FTPConnectionPassword";
		EndIf;
	EndIf;
	
	Result = GetRegisterDataByStructure(Correspondent, SettingsStructure);
	Result.Insert("UseTempDirectoryToSendAndReceiveMessages", True);
	
	SetPrivilegedMode(True);
	Passwords = Common.ReadDataFromSecureStorage(Correspondent, PasswordsList);
	SetPrivilegedMode(False);
	
	If TypeOf(Passwords) = Type("Structure") Then
		For each KeyAndValue In Passwords Do
			Result.Insert(KeyAndValue.Key, KeyAndValue.Value);
		EndDo;
	Else
		Result.Insert(PasswordsList, Passwords);
	EndIf;
	
	Return Result;
EndFunction

Function GetRegisterDataByStructure(Correspondent, SettingsStructure)
	
	If Not ValueIsFilled(Correspondent) Then
		Return SettingsStructure;
	EndIf;
	
	If SettingsStructure.Count() = 0 Then
		Return SettingsStructure;
	EndIf;
	
	// Generating a query text by the required fields only (by parameters for the specified transport 
	// kind).
	QueryText = "SELECT ";
	
	For Each SettingItem In SettingsStructure Do
		
		QueryText = QueryText + SettingItem.Key + ", ";
		
	EndDo;
	
	// Deleting the last ", " character.
	StringFunctionsClientServer.DeleteLastCharInString(QueryText, 2);
	
	QueryText = QueryText + "
	|FROM
	|	InformationRegister.DataExchangeTransportSettings AS TransportSettings
	|WHERE
	|	TransportSettings.Correspondent = &Correspondent
	|";
	
	Query = New Query;
	Query.Text = QueryText;
	Query.SetParameter("Correspondent", Correspondent);
	
	Selection = Query.Execute().Select();
	
	// Filling the structure if settings for the node are filled.
	If Selection.Next() Then
		
		For Each SettingItem In SettingsStructure Do
			
			SettingsStructure[SettingItem.Key] = Selection[SettingItem.Key];
			
		EndDo;
		
	EndIf;
	
	Return SettingsStructure;
	
EndFunction

Function ExchangeTransportSettingsContent(SearchSubstring)
	
	TransportSettingsStructure = New Structure;
	
	RecordSet = CreateRecordSet();
	Record = RecordSet.Add(); // For default values.
	
	For Each Resource In RecordSet.Metadata().Resources Do
		
		If StrFind(Resource.Name, SearchSubstring) <> 0 Then
			
			TransportSettingsStructure.Insert(Resource.Name, Record[Resource.Name]);
			
		EndIf;
		
	EndDo;
	
	Return TransportSettingsStructure;
	
EndFunction

Function MergeCollections(Structure1, Structure2)
	
	ResultingStructure = New Structure;
	
	SupplementCollection(Structure1, ResultingStructure);
	SupplementCollection(Structure2, ResultingStructure);
	
	Return ResultingStructure;
EndFunction

Procedure SupplementCollection(Source, Destination)
	
	For Each Item In Source Do
		
		Destination.Insert(Item.Key, Item.Value);
		
	EndDo;
	
EndProcedure

#EndRegion

#EndIf