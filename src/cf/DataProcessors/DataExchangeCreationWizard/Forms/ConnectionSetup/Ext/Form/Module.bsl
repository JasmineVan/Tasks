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
	
	CheckCanUseForm(Cancel);
	
	If Cancel Then
		Return;
	EndIf;
	
	InitializeFormAttributes();
	
	InitializeFormProperties();
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	SetNavigationNumber(1);
	
EndProcedure

&AtClient
Procedure BeforeClose(Cancel, Exit, WarningText, StandardProcessing)
	
	WarningText = NStr("ru = 'Прервать настройку параметров подключения для синхронизации данных?'; en = 'Do you want to discard the connection parameters for data synchronization?'; pl = 'Przerwać ustawienie parametrów połączenia dla synchronizacji danych?';de = 'Verbindungseinstellungen für die Datensynchronisation unterbrechen?';ro = 'Întrerupeți setarea parametrilor de conectare pentru sincronizarea datelor?';tr = 'Veri eşleşmesi için bağlantı parametrelerin ayarları durdurulsun mu?'; es_ES = '¿Interrumpir los ajustes de parámetros de conexión para sincronizar los datos?'");
	CommonClient.ShowArbitraryFormClosingConfirmation(
		ThisObject, Cancel, Exit, WarningText, "ForceCloseForm");
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure ConnectionSetupMethodOnChange(Item)
	
	OnChangeConnectionSetupMethod();
	
EndProcedure

&AtClient
Procedure ImportConnectionSettingsFromFileOnChange(Item)
	
	OnChangeImportConnectionSettingsFromFile();
	
EndProcedure

&AtClient
Procedure ConnectionSettingsFileNameToImportStartChoice(Item, ChoiceData, StandardProcessing)
	
	DialogSettings = New Structure;
	DialogSettings.Insert("Title", NStr("ru = 'Выберите файл с настройками подключения'; en = 'Select connection settings file'; pl = 'Wybierz plik z ustawieniami połączenia';de = 'Wählen Sie eine Datei mit Verbindungseinstellungen aus';ro = 'Selectați fișierul cu setările de conectare';tr = 'Bağlantı ayarlarına sahip bir dosya seçin'; es_ES = 'Seleccione un archivo con ajustes de conexión'"));
	DialogSettings.Insert("Filter",    NStr("ru = 'Файл настроек подключения (*.xml)'; en = 'Connection settings file (*.xml)'; pl = 'Plik ustawień połączenia *.xml)';de = 'Verbindungseinstellungsdatei (*.xml)';ro = 'Fișierul setărilor de conectare (*.xml)';tr = 'Bağlantı ayarları dosyası (*.xml) '; es_ES = 'Archivo de ajustes de conexión (*.xml)'") + "|*.xml");
	
	DataExchangeClient.FileSelectionHandler(ThisObject, "ConnectionSettingsFileNameToImport", StandardProcessing, DialogSettings);
	
EndProcedure

&AtClient
Procedure XDTOCorrespondentSettingsFileNameStartChoice(Item, ChoiceData, StandardProcessing)
	
	DialogSettings = New Structure;
	DialogSettings.Insert("Title", NStr("ru = 'Выберите файл с настройками корреспондента'; en = 'Select peer settings file'; pl = 'Wybierz plik z ustawieniami korespondenta';de = 'Wählen Sie die korrespondierende Einstellungsdatei aus';ro = 'Selectați fișierul cu setările corespondentului';tr = 'Muhabir ayarlarına sahip bir dosya seçin'; es_ES = 'Seleccione un archivo con ajustes de correspondiente'"));
	DialogSettings.Insert("Filter",    NStr("ru = 'Файл настроек корреспондента (*.xml)'; en = 'Peer settings file (*.xml)'; pl = 'Plik ustawień korespondenta (*.xml)';de = 'Korrespondenzeinstellungsdatei (*.xml)';ro = 'Fișierul setărilor corespondentului (*.xml)';tr = 'Muhabir ayarları dosyası (*.xml) '; es_ES = 'Archivo de ajustes de correspondiente (*.xml)'") + "|*.xml");
	
	DataExchangeClient.FileSelectionHandler(ThisObject, "XDTOCorrespondentSettingsFileName", StandardProcessing, DialogSettings);
	
EndProcedure

&AtClient
Procedure ConnectionSettingsFileNameToExportStartChoice(Item, ChoiceData, StandardProcessing)
	
	DialogSettings = New Structure;
	DialogSettings.Insert("Mode",     FileDialogMode.Save);
	DialogSettings.Insert("Title", NStr("ru = 'Укажите файл для сохранения настроек подключения'; en = 'Select file to save connection settings'; pl = 'Wybierz plik, aby zapisać ustawienia połączenia';de = 'Geben Sie die Datei an, in der die Verbindungseinstellungen gespeichert werden sollen';ro = 'Indicați fișierul pentru salvarea setărilor de conectare';tr = 'Bağlantı ayarlarının kaydı için bir dosya belirtin'; es_ES = 'Indique un archivo para guardar los ajustes de conexión'"));
	DialogSettings.Insert("Filter",    NStr("ru = 'Файл настроек подключения (*.xml)'; en = 'Connection settings file (*.xml)'; pl = 'Plik ustawień połączenia *.xml)';de = 'Verbindungseinstellungsdatei (*.xml)';ro = 'Fișierul setărilor de conectare (*.xml)';tr = 'Bağlantı ayarları dosyası (*.xml) '; es_ES = 'Archivo de ajustes de conexión (*.xml)'") + "|*.xml");
	
	DataExchangeClient.FileSelectionHandler(ThisObject, "ConnectionSettingsFileNameToExport", StandardProcessing, DialogSettings);
	
EndProcedure

&AtClient
Procedure ExternalConnectionConnectionKindOnChange(Item)
	
	OnChangeConnectionKind();
	
EndProcedure

&AtClient
Procedure InternetConnectionKindOnChange(Item)
	
	OnChangeConnectionKind();
	
EndProcedure

&AtClient
Procedure RegularCommunicationChannelsConnectionKindOnChange(Item)
	
	OnChangeConnectionKind();
	
EndProcedure

&AtClient
Procedure PassiveModeConnectionKindOnChange(Item)
	
	OnChangeConnectionKind();
	
EndProcedure

&AtClient
Procedure RegularCommunicationChannelsFILEDirectoryStartChoice(Item, ChoiceData, StandardProcessing)
	
	DataExchangeClient.FileDirectoryChoiceHandler(ThisObject, "RegularCommunicationChannelsFILEDirectory", StandardProcessing);
	
EndProcedure

&AtClient
Procedure ExternalConnectionInfobaseDirectoryStartChoice(Item, ChoiceData, StandardProcessing)
	
	DataExchangeClient.FileDirectoryChoiceHandler(ThisObject, "ExternalConnectionInfobaseDirectory", StandardProcessing);
	
EndProcedure

&AtClient
Procedure RegularCommunicationChannelsFILEUsageOnChange(Item)
	
	OnChangeRegularCommunicationChannelsFILEUsage();
	
EndProcedure

&AtClient
Procedure RegularCommunicationChannelsFTPUsageOnChange(Item)
	
	OnChangeRegularCommunicationChannelsFTPUsage();
	
EndProcedure

&AtClient
Procedure RegularCommunicationChannelsEMAILUsageOnChange(Item)
	
	OnChangeRegularCommunicationChannelsEMAILUsage();
	
EndProcedure

&AtClient
Procedure ExternalConnectionInfobaseOperationModeFileOnChange(Item)
	
	OnChangeExternalConnectionInfobaseOperationMode();
	
EndProcedure

&AtClient
Procedure ExternalConnectionInfobaseOperationModeClientServerOnChange(Item)
	
	OnChangeExternalConnectionInfobaseOperationMode();
	
EndProcedure

&AtClient
Procedure ExternalConnection1CEnterpriseAuthenticationKindOnChange(Item)
	
	OnChangeExternalConnectionAuthenticationKind();
	
EndProcedure

&AtClient
Procedure ExternalConnectionAuthenticationKindOperatingSystemOnChange(Item)
	
	OnChangeExternalConnectionAuthenticationKind();
	
EndProcedure

&AtClient
Procedure RegularCommunicationChannelsArchiveFilesOnChange(Item)
	
	OnChangeRegularCommunicationChannelsArchiveFiles();
	
EndProcedure

&AtClient
Procedure RegularCommunicationChannelsUseArchivePasswordOnChange(Item)
	
	OnChangeRegularCommunicationChannelsUseArchivePassword();
	
EndProcedure

&AtClient
Procedure RegularCommunicationChannelsFTPUseFileSizeLimitOnChange(Item)
	
	OnChangeRegularCommunicationChannelsFTPUseFileSizeLimit();
	
EndProcedure

&AtClient
Procedure RegularCommunicationChannelsEMAILUseAttachmentSizeLimitOnChange(Item)
	
	OnChangeRegularCommunicationChannelsEMAILUseAttachmentSizeLimit();
	
EndProcedure

#EndRegion

#Region FormCommandHandlers

&AtClient
Procedure NextCommand(Command)
	
	ChangeNavigationNumber(+1);
	
EndProcedure

&AtClient
Procedure BackCommand(Command)
	
	ChangeNavigationNumber(-1);
	
EndProcedure

&AtClient
Procedure DoneCommand(Command)
	
	ForceCloseForm = True;
	
	Result = New Structure;
	Result.Insert("ExchangeNode", ExchangeNode);
	Result.Insert("HasDataToMap", HasDataToMap);
	
	If SaaSModel Then
		Result.Insert("CorrespondentDataArea",  CorrespondentDataArea);
		Result.Insert("IsExchangeWithApplicationInService", IsExchangeWithApplicationInService);
	EndIf;
	
	Result.Insert("PassiveMode", ConnectionKind = "PassiveMode");
	
	Close(Result);
	
EndProcedure

&AtClient
Procedure CancelCommand(Command)
	
	Close();
	
EndProcedure

&AtClient
Procedure HelpCommand(Command)
	
	OpenFormHelp();
	
EndProcedure

&AtClient
Procedure RefreshAvailableApplicationsList(Command)
	
	StartGetConnectionsListForConnection();
	
EndProcedure

&AtClient
Procedure InternetAccessParameters(Command)
	
	DataExchangeClient.OpenProxyServerParametersForm();
	
EndProcedure

&AtClient
Procedure DataSyncDetails(Command)
	
	DataExchangeClient.OpenSynchronizationDetails(ExchangeDetailedInformation);
	
EndProcedure

#EndRegion

#Region Private

#Region GetConnectionsListForConnection

&AtClient
Procedure StartGetConnectionsListForConnection()
	
	Items.SaaSApplicationsPanel.Visible = True;
	Items.ApplicationsSaaS.Enabled = False;
	Items.SaaSApplicationsRefreshAvailableApplicationsList.Enabled = False;
	
	Items.SaaSApplicationsPanel.CurrentPage = Items.SaaSApplicationsPanelWaitPage;
	AttachIdleHandler("GetApplicationListForConnectionOnStart", 0.1, True);
	
EndProcedure

&AtClient
Procedure GetApplicationListForConnectionOnStart()
	
	ParametersOfGetApplicationsListHandler = Undefined;
	ContinueWait = False;
	
	OnStartGetConnectionsListForConnection(ContinueWait);
		
	If ContinueWait Then
		DataExchangeClient.InitializeIdleHandlerParameters(
			ParametersOfGetApplicationsListIdleHandler);
			
		AttachIdleHandler("OnWaitForGetApplicationListForConnection",
			ParametersOfGetApplicationsListIdleHandler.CurrentInterval, True);
	Else
		OnCompleteGettingApplicationsListForConnection();
	EndIf;
	
EndProcedure

&AtClient
Procedure OnWaitForGetApplicationListForConnection()
	
	ContinueWait = False;
	OnWaitGetConnectionsListForConnection(ParametersOfGetApplicationsListHandler, ContinueWait);
	
	If ContinueWait Then
		DataExchangeClient.UpdateIdleHandlerParameters(ParametersOfGetApplicationsListIdleHandler);
		
		AttachIdleHandler("OnWaitForGetApplicationListForConnection",
			ParametersOfGetApplicationsListIdleHandler.CurrentInterval, True);
	Else
		ParametersOfGetApplicationsListIdleHandler = Undefined;
		OnCompleteGettingApplicationsListForConnection();
	EndIf;
	
EndProcedure

&AtClient
Procedure OnCompleteGettingApplicationsListForConnection()
	
	Cancel = False;
	OnCompleteGettingApplicationsListForConnectionAtServer(Cancel);
	
	Items.SaaSApplicationsRefreshAvailableApplicationsList.Enabled = True;
	Items.ApplicationsSaaS.Enabled = True;
	
	If Cancel Then
		Items.SaaSApplicationsPanel.CurrentPage = Items.SaaSApplicationsErrorPage;
	Else
		Items.SaaSApplicationsPanel.Visible = False;
	EndIf;
	
EndProcedure

&AtServer
Procedure OnStartGetConnectionsListForConnection(ContinueWait)
	
	ModuleSetupWizard = DataExchangeServer.ModuleDataSynchronizationBetweenWebApplicationsSetupWizard();
	
	If ModuleSetupWizard = Undefined Then
		ContinueWait = False;
		Return;
	EndIf;
	
	WizardParameters = New Structure;
	WizardParameters.Insert("Mode",                  "NotConfiguredExchanges");
	WizardParameters.Insert("ExchangePlanName",         ExchangePlanName);
	WizardParameters.Insert("SettingID", SettingID);
	
	ModuleSetupWizard.OnStartGetApplicationList(WizardParameters,
		ParametersOfGetApplicationsListHandler, ContinueWait);
	
EndProcedure

&AtServerNoContext
Procedure OnWaitGetConnectionsListForConnection(HandlerParameters, ContinueWait)
	
	ModuleSetupWizard = DataExchangeServer.ModuleDataSynchronizationBetweenWebApplicationsSetupWizard();
	
	If ModuleSetupWizard = Undefined Then
		ContinueWait = False;
		Return;
	EndIf;
	
	ModuleSetupWizard.OnWaitForGetApplicationList(
		HandlerParameters, ContinueWait);
	
EndProcedure

&AtServer
Procedure OnCompleteGettingApplicationsListForConnectionAtServer(Cancel = False)
	
	ModuleSetupWizard = DataExchangeServer.ModuleDataSynchronizationBetweenWebApplicationsSetupWizard();
	
	If ModuleSetupWizard = Undefined Then
		Cancel = True;
		Return;
	EndIf;
	
	CompletionStatus = Undefined;
	ModuleSetupWizard.OnCompleteGetApplicationList(
		ParametersOfGetApplicationsListHandler, CompletionStatus);
		
	If CompletionStatus.Cancel Then
		Cancel = True;
		Return;
	EndIf;
	
	ApplicationsTable = CompletionStatus.Result;
	
	ApplicationsTable.Columns.Add("PictureUseMode", New TypeDescription("Number"));
	ApplicationsTable.FillValues(1, "PictureUseMode"); // online application
	ApplicationsSaaS.Load(ApplicationsTable);
	
EndProcedure

#EndRegion

#Region ConnectionParametersCheck

&AtClient
Procedure OnStartCheckConnectionOnline()
	
	ContinueWait = True;
	
	If ConnectionKind = "Internet" Then
		OnStartCheckConnectionAtServer("WS", ContinueWait);
	ElsIf ConnectionKind = "ExternalConnection" Then
		OnStartCheckConnectionAtServer("COM", ContinueWait);
	EndIf;
	
	If ContinueWait Then
		DataExchangeClient.InitializeIdleHandlerParameters(
			ConnectionCheckIdleHandlerParameters);
			
		AttachIdleHandler("OnWaitForConnectionCheckOnline",
			ConnectionCheckIdleHandlerParameters.CurrentInterval, True);
	Else
		OnCompleteConnectionTestOnline();
	EndIf;
	
EndProcedure
	
&AtClient
Procedure OnWaitForConnectionCheckOnline()
	
	ContinueWait = False;
	OnWaitConnectionCheckAtServer(ConnectionCheckHandlerParameters, ContinueWait);
	
	If ContinueWait Then
		DataExchangeClient.UpdateIdleHandlerParameters(ConnectionCheckIdleHandlerParameters);
		
		AttachIdleHandler("OnWaitForConnectionCheckOnline",
			ConnectionCheckIdleHandlerParameters.CurrentInterval, True);
	Else
		ConnectionCheckIdleHandlerParameters = Undefined;
		OnCompleteConnectionTestOnline();
	EndIf;
	
EndProcedure

&AtClient
Procedure OnCompleteConnectionTestOnline()
	
	ErrorMessage = "";
	ConnectionCheckCompleted = False;
	OnCompleteConnectionTestAtServer(ConnectionCheckCompleted, ErrorMessage);
	
	If ConnectionCheckCompleted Then
		ChangeNavigationNumber(+1);
	Else
		ChangeNavigationNumber(-1);
		
		If Not IsBlankString(ErrorMessage) Then
			CommonClient.MessageToUser(ErrorMessage);
		Else
			CommonClient.MessageToUser(
				NStr("ru = 'Не удалось подключиться к программе. Проверьте настройки подключения.'; en = 'Cannot connect to the application. Please check the connection settings.'; pl = 'Nie udało się połączyć z programem. Sprawdź ustawienia połączenia.';de = 'Die Verbindung zum Programm konnte nicht hergestellt werden. Überprüfen Sie die Verbindungseinstellungen.';ro = 'Eșec de conectare la program. Verificați setările de conectare.';tr = 'Uygulamaya bağlanılamadı. Bağlantı ayarlarını kontrol edin.'; es_ES = 'No se ha podido conectarse al programa. Compruebe los ajustes de conexión.'"));
		EndIf;
	EndIf;
		
EndProcedure

&AtClient
Procedure OnStartCheckConnectionOffline()
	
	If RegularCommunicationChannelsConnectionCheckQueue = Undefined Then	
		
		RegularCommunicationChannelsConnectionCheckQueue = New Structure;
		
		If RegularCommunicationChannelsFILEUsage Then
			RegularCommunicationChannelsConnectionCheckQueue.Insert("FILE");
		EndIf;
		
		If RegularCommunicationChannelsFTPUsage Then
			RegularCommunicationChannelsConnectionCheckQueue.Insert("FTP");
		EndIf;
		
		If RegularCommunicationChannelsEMAILUsage Then
			RegularCommunicationChannelsConnectionCheckQueue.Insert("EMAIL");
		EndIf;
		
	EndIf;
	
	TransportKindToCheck = Undefined;
	For Each CheckItems In RegularCommunicationChannelsConnectionCheckQueue Do
		TransportKindToCheck = CheckItems.Key;
		Break;
	EndDo;
	
	ContinueWait = True;
	OnStartCheckConnectionAtServer(TransportKindToCheck, ContinueWait);
	
	If ContinueWait Then
		DataExchangeClient.InitializeIdleHandlerParameters(
			ConnectionCheckIdleHandlerParameters);
			
		AttachIdleHandler("OnWaitForConnectionCheckOffline",
			ConnectionCheckIdleHandlerParameters.CurrentInterval, True);
	Else
		OnCompleteConnectionCheckOffline();
	EndIf;
	
EndProcedure

&AtClient
Procedure OnWaitForConnectionCheckOffline()
	
	ContinueWait = False;
	OnWaitConnectionCheckAtServer(ConnectionCheckHandlerParameters, ContinueWait);
	
	If ContinueWait Then
		DataExchangeClient.UpdateIdleHandlerParameters(ConnectionCheckIdleHandlerParameters);
		
		AttachIdleHandler("OnWaitForConnectionCheckOffline",
			ConnectionCheckIdleHandlerParameters.CurrentInterval, True);
	Else
		ConnectionCheckIdleHandlerParameters = Undefined;
		OnCompleteConnectionCheckOffline();
	EndIf;
	
EndProcedure

&AtClient
Procedure OnCompleteConnectionCheckOffline()
	
	ErrorMessage = "";
	ConnectionCheckCompleted = False;
	OnCompleteConnectionTestAtServer(ConnectionCheckCompleted, ErrorMessage);
	
	If ConnectionCheckCompleted Then
		
		TransportKindToCheck = Undefined;
		For Each CheckItems In RegularCommunicationChannelsConnectionCheckQueue Do
			TransportKindToCheck = CheckItems.Key;
			Break;
		EndDo;
		RegularCommunicationChannelsConnectionCheckQueue.Delete(TransportKindToCheck);
		
		If RegularCommunicationChannelsConnectionCheckQueue.Count() > 0 Then
			OnStartCheckConnectionOffline();
		Else
			RegularCommunicationChannelsConnectionCheckQueue = Undefined;
			ChangeNavigationNumber(+1);
		EndIf;
		
	Else
		
		TransportKindToCheck = Undefined;
		RegularCommunicationChannelsConnectionCheckQueue = Undefined;
		ChangeNavigationNumber(-1);
		
		If Not IsBlankString(ErrorMessage) Then
			CommonClient.MessageToUser(ErrorMessage);
		Else
			CommonClient.MessageToUser(
				StringFunctionsClientServer.SubstituteParametersToString(
					NStr("ru = 'Не удалось подключиться к программе. Проверьте настройки подключения %1.'; en = 'Cannot connect to the application. Please check the connection settings %1.'; pl = 'Nie udało się połączyć z programem. Sprawdź ustawienia połączenia %1.';de = 'Die Verbindung zum Programm konnte nicht hergestellt werden. Überprüfen Sie die Verbindungseinstellungen %1.';ro = 'Eșec de conectare la program. Verificați setările de conectare %1.';tr = 'Uygulamaya bağlanılamadı. Bağlantı ayarlarını kontrol edin.%1'; es_ES = 'No se ha podido conectarse al programa. Compruebe los ajustes de conexión %1.'"), TransportKindToCheck));
		EndIf;
				
	EndIf;
	
EndProcedure

&AtClient
Procedure OnStartConnectionCheckInSaaS()
	
	ContinueWait = True;
	OnStartConnectionCheckInSaaSAtServer(ContinueWait);
	
	If ContinueWait Then
		DataExchangeClient.InitializeIdleHandlerParameters(
			ConnectionCheckIdleHandlerParameters);
			
		AttachIdleHandler("OnWaitForConnectionCheckSaaS",
			ConnectionCheckIdleHandlerParameters.CurrentInterval, True);
	Else
		OnCompleteSaaSConnectionCheck();
	EndIf;
	
EndProcedure

&AtClient
Procedure OnWaitForConnectionCheckSaaS()
	
	ContinueWait = False;
	OnWaitConnectionCheckInSaaSAtServer(ConnectionCheckHandlerParameters, ContinueWait);
	
	If ContinueWait Then
		DataExchangeClient.UpdateIdleHandlerParameters(ConnectionCheckIdleHandlerParameters);
		
		AttachIdleHandler("OnWaitForConnectionCheckSaaS",
			ConnectionCheckIdleHandlerParameters.CurrentInterval, True);
	Else
		OnCompleteSaaSConnectionCheck();
	EndIf;
	
EndProcedure

&AtClient
Procedure OnCompleteSaaSConnectionCheck()
	
	ErrorMessage = "";
	ConnectionCheckCompleted = False;
	OnCompleteSaaSConnectionTestAtServer(ConnectionCheckCompleted, ErrorMessage);
	
	If ConnectionCheckCompleted Then
		ChangeNavigationNumber(+1);
	Else
		ChangeNavigationNumber(-1);
		
		If Not IsBlankString(ErrorMessage) Then
			CommonClient.MessageToUser(ErrorMessage);
		Else
			CommonClient.MessageToUser(
				NStr("ru = 'Не удалось подключиться к программе. Проверьте настройки подключения.'; en = 'Cannot connect to the application. Please check the connection settings.'; pl = 'Nie udało się połączyć z programem. Sprawdź ustawienia połączenia.';de = 'Die Verbindung zum Programm konnte nicht hergestellt werden. Überprüfen Sie die Verbindungseinstellungen.';ro = 'Eșec de conectare la program. Verificați setările de conectare.';tr = 'Uygulamaya bağlanılamadı. Bağlantı ayarlarını kontrol edin.'; es_ES = 'No se ha podido conectarse al programa. Compruebe los ajustes de conexión.'"));
		EndIf;
	EndIf;
	
EndProcedure

&AtServer
Procedure OnStartCheckConnectionAtServer(TransportKind, ContinueWait)
	
	ModuleSetupWizard = DataExchangeServer.ModuleDataExchangeCreationWizard();
	
	SettingsStructure = New Structure;
	FillWizardConnectionParametersStructure(SettingsStructure, True);
	SettingsStructure.ExchangeMessagesTransportKind = Enums.ExchangeMessagesTransportTypes[TransportKind];
	
	ModuleSetupWizard.OnStartTestConnection(
		SettingsStructure, ConnectionCheckHandlerParameters, ContinueWait);
	
EndProcedure

&AtServerNoContext
Procedure OnWaitConnectionCheckAtServer(HandlerParameters, ContinueWait)
	
	ModuleSetupWizard = DataExchangeServer.ModuleDataExchangeCreationWizard();
	
	ContinueWait = False;
	ModuleSetupWizard.OnWaitForTestConnection(HandlerParameters, ContinueWait);
	
EndProcedure

&AtServer
Procedure OnCompleteConnectionTestAtServer(ConnectionCheckCompleted, ErrorMessage = "")
	
	ModuleSetupWizard = DataExchangeServer.ModuleDataExchangeCreationWizard();
	
	CompletionStatus = Undefined;
	ModuleSetupWizard.OnCompleteTestConnection(ConnectionCheckHandlerParameters, CompletionStatus);
		
	If CompletionStatus.Cancel Then
		ConnectionCheckCompleted = False;
		ErrorMessage = CompletionStatus.ErrorMessage;
		Return;
	Else
		ConnectionCheckCompleted = CompletionStatus.Result.ConnectionIsSet
			AND CompletionStatus.Result.ConnectionAllowed;
			
		If Not ConnectionCheckCompleted
			AND Not IsBlankString(CompletionStatus.Result.ErrorMessage) Then
			ErrorMessage = CompletionStatus.Result.ErrorMessage;
		EndIf;
			
		If ConnectionCheckCompleted
			AND CompletionStatus.Result.CorrespondentParametersReceived Then
			FillCorrespondentParameters(CompletionStatus.Result.CorrespondentParameters);
		EndIf;
	EndIf;
	
EndProcedure

&AtServer
Procedure OnStartConnectionCheckInSaaSAtServer(ContinueWait)
	
	ModuleSetupWizard = DataExchangeServer.ModuleDataSynchronizationBetweenWebApplicationsSetupWizard();
	
	If ModuleSetupWizard = Undefined Then
		ContinueWait = False;
		Return;
	EndIf;
	
	ConnectionSettings = New Structure;
	ConnectionSettings.Insert("ExchangePlanName",              ExchangePlanName);
	ConnectionSettings.Insert("CorrespondentDescription",  CorrespondentDescription);
	ConnectionSettings.Insert("CorrespondentDataArea", CorrespondentDataArea);
	
	ConnectionCheckHandlerParameters = Undefined;
	ModuleSetupWizard.OnStartGetCommonDataFromCorrespondentNodes(ConnectionSettings,
		ConnectionCheckHandlerParameters, ContinueWait);
	
EndProcedure

&AtServerNoContext
Procedure OnWaitConnectionCheckInSaaSAtServer(HandlerParameters, ContinueWait)

	ModuleSetupWizard = DataExchangeServer.ModuleDataSynchronizationBetweenWebApplicationsSetupWizard();
	
	If ModuleSetupWizard = Undefined Then
		ContinueWait = False;
		Return;
	EndIf;
	
	ContinueWait = False;
	ModuleSetupWizard.OnWaitForGetCommonDataFromCorrespondentNodes(HandlerParameters, ContinueWait);
	
EndProcedure

&AtServer
Procedure OnCompleteSaaSConnectionTestAtServer(ConnectionCheckCompleted, ErrorMessage = "")
	
	ModuleSetupWizard = DataExchangeServer.ModuleDataSynchronizationBetweenWebApplicationsSetupWizard();
	
	If ModuleSetupWizard = Undefined Then
		ConnectionCheckCompleted = False;
		Return;
	EndIf;
	
	CompletionStatus = Undefined;
	ModuleSetupWizard.OnCompleteGetCommonDataFromCorrespondentNodes(
		ConnectionCheckHandlerParameters, CompletionStatus);
	ConnectionCheckHandlerParameters = Undefined;
		
	If CompletionStatus.Cancel Then
		ConnectionCheckCompleted = False;
		ErrorMessage = CompletionStatus.ErrorMessage;
		Return;
	Else
		ConnectionCheckCompleted = CompletionStatus.Result.CorrespondentParametersReceived;
		
		If Not ConnectionCheckCompleted Then
			ErrorMessage = CompletionStatus.Result.ErrorMessage;
			Return;
		EndIf;
		
		If ConnectionCheckCompleted Then
			FillCorrespondentParameters(CompletionStatus.Result.CorrespondentParameters, True);
		EndIf;
	EndIf;
	
EndProcedure

#EndRegion

#Region SaveConnectionSettings

&AtClient
Procedure OnStartSaveConnectionSettings()
	
	ContinueWait = True;
	OnStartSaveConnectionSettingsAtServer(ContinueWait);
	
	If ContinueWait Then
		DataExchangeClient.InitializeIdleHandlerParameters(
			ConnectionSettingsSaveIdleHandlerParameters);
			
		AttachIdleHandler("OnWaitForSaveConnectionSettings",
			ConnectionSettingsSaveIdleHandlerParameters.CurrentInterval, True);
	Else
		OnCompleteConnectionSettingsSaving();
	EndIf;
	
EndProcedure
	
&AtClient
Procedure OnWaitForSaveConnectionSettings()
	
	ContinueWait = False;
	OnWaitForSaveConnectionSettingsAtServer(IsExchangeWithApplicationInService,
		ConnectionSettingsSaveHandlerParameters, ContinueWait);
	
	If ContinueWait Then
		DataExchangeClient.UpdateIdleHandlerParameters(ConnectionSettingsSaveIdleHandlerParameters);
		
		AttachIdleHandler("OnWaitForSaveConnectionSettings",
			ConnectionSettingsSaveIdleHandlerParameters.CurrentInterval, True);
	Else
		OnCompleteConnectionSettingsSaving();
	EndIf;
	
EndProcedure

&AtClient
Procedure OnCompleteConnectionSettingsSaving()
	
	ConnectionSettingsSaved = False;
	ConnectionSettingsAddressInStorage = "";
	ErrorMessage = "";
	
	OnCompleteConnectionSettingsSavingAtServer(ConnectionSettingsSaved,
		ConnectionSettingsAddressInStorage, ErrorMessage);
		
	Result = New Structure;
	Result.Insert("Cancel",             Not ConnectionSettingsSaved);
	Result.Insert("ErrorMessage", ErrorMessage);
	
	CompletionNotification = New NotifyDescription("SaveConnectionSettingsCompletion", ThisObject);
	
	If ConnectionSettingsSaved Then
		If SaveConnectionParametersToFile
			AND ValueIsFilled(ConnectionSettingsAddressInStorage) Then
			
			AdditionalParameters = New Structure;
			AdditionalParameters.Insert("CompletionNotification", CompletionNotification);
			
			FileReceiptNotification = New NotifyDescription("GetConnectionSettingsFileCompletion",
				ThisObject, AdditionalParameters);
				
			FilesToGet = New Array;
			FilesToGet.Add(
				New TransferableFileDescription(ConnectionSettingsFileNameToExport, ConnectionSettingsAddressInStorage));
				
			BeginGettingFiles(FileReceiptNotification, FilesToGet, , False);
			
		Else
			
			ExecuteNotifyProcessing(CompletionNotification, Result);
			
		EndIf;
	Else
		
		ExecuteNotifyProcessing(CompletionNotification, Result);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure GetConnectionSettingsFileCompletion(ReceivedFiles, AdditionalParameters) Export
	
	Result = New Structure;
	Result.Insert("Cancel",             False);
	Result.Insert("ErrorMessage", "");
	
	If ReceivedFiles = Undefined Then
		Result.Cancel = True;
		Result.ErrorMessage = NStr("ru = 'Не удалось сохранить настройки подключения в файл.'; en = 'Cannot save the connection settings to a file.'; pl = 'Nie udało się zapisać ustawienia połączenia do pliku.';de = 'Die Verbindungseinstellungen konnten nicht in der Datei gespeichert werden.';ro = 'Eșec de salvare a setării de conectare în fișier.';tr = 'Bağlantı ayarları dosyada kaydedilemedi.'; es_ES = 'No se ha podido guardar los ajustes de conexión en el archivo.'");
	EndIf;
	
	ExecuteNotifyProcessing(AdditionalParameters.CompletionNotification, Result);
	
EndProcedure

&AtClient
Procedure SaveConnectionSettingsCompletion(Result, AdditionalParameters) Export
	
	If Not Result.Cancel Then
		
		ChangeNavigationNumber(+1);
		
		Notify("Write_ExchangePlanNode");
		
	Else
		
		ChangeNavigationNumber(-1);
		
		MessageText = Result.ErrorMessage;
		If IsBlankString(MessageText) Then
			MessageText = NStr("ru = 'Не удалось сохранить настройки подключения.'; en = 'Cannot save the connection settings.'; pl = 'Nie udało się zapisać ustawienia połączenia.';de = 'Die Verbindungseinstellungen konnten nicht gespeichert werden.';ro = 'Eșec de salvare a setării de conectare.';tr = 'Bağlantı ayarları kaydedilemedi.'; es_ES = 'No se ha podido guardar los ajustes de conexión.'");
		EndIf;
		
		CommonClient.MessageToUser(MessageText);
			
	EndIf;
	
EndProcedure

&AtServer
Procedure OnStartSaveConnectionSettingsAtServer(ContinueWait)
	
	If IsExchangeWithApplicationInService Then
		
		ConnectionSettings = New Structure;
		ConnectionSettings.Insert("ExchangePlanName",               CorrespondentExchangePlanName);
		ConnectionSettings.Insert("CorrespondentExchangePlanName", ExchangePlanName);
		
		ConnectionSettings.Insert("SettingID",       SettingID);
		
		ConnectionSettings.Insert("ExchangeFormat", ExchangeFormat);
		
		ConnectionSettings.Insert("Description", Description);
		ConnectionSettings.Insert("CorrespondentDescription", CorrespondentDescription);
		
		ConnectionSettings.Insert("Prefix",               Prefix);
		ConnectionSettings.Insert("CorrespondentPrefix", CorrespondentPrefix);
		
		ConnectionSettings.Insert("SourceInfobaseID", SourceInfobaseID);
		ConnectionSettings.Insert("DestinationInfobaseID", DestinationInfobaseID);
		
		ConnectionSettings.Insert("CorrespondentEndpoint", CorrespondentEndpoint);

		ConnectionSettings.Insert("Correspondent");
		ConnectionSettings.Insert("CorrespondentDataArea", CorrespondentDataArea);
		
		If XDTOSetup Then
			ConnectionSettings.Insert("XDTOCorrespondentSettings", New Structure);
			ConnectionSettings.XDTOCorrespondentSettings.Insert("SupportedVersions", New Array);
			ConnectionSettings.XDTOCorrespondentSettings.Insert("SupportedObjects", SupportedCorrespondentFormatObjects);
			
			ConnectionSettings.XDTOCorrespondentSettings.SupportedVersions.Add(ExchangeFormatVersion);
		EndIf;
		
		ModuleSetupWizard = DataExchangeServer.ModuleDataSynchronizationBetweenWebApplicationsSetupWizard();
	Else
		
		// Connection settings in the attribute structure format of the data exchange creation wizard.
		ConnectionSettings = New Structure;
		FillWizardConnectionParametersStructure(ConnectionSettings);
		
		ModuleSetupWizard = DataExchangeServer.ModuleDataExchangeCreationWizard();
			
	EndIf;
	
	If ModuleSetupWizard = Undefined Then
		ContinueWait = False;
		Return;
	EndIf;
	
	ConnectionSettingsSaveHandlerParameters = Undefined;
	ModuleSetupWizard.OnStartSaveConnectionSettings(ConnectionSettings,
		ConnectionSettingsSaveHandlerParameters, ContinueWait);
	
EndProcedure

&AtServerNoContext
Procedure OnWaitForSaveConnectionSettingsAtServer(IsExchangeWithApplicationInService, HandlerParameters, ContinueWait)
	
	If IsExchangeWithApplicationInService Then
		ModuleSetupWizard = DataExchangeServer.ModuleDataSynchronizationBetweenWebApplicationsSetupWizard();
	Else
		ModuleSetupWizard = DataExchangeServer.ModuleDataExchangeCreationWizard();
	EndIf;
	
	If ModuleSetupWizard = Undefined Then
		ContinueWait = False;
		Return;
	EndIf;
	
	ContinueWait = False;
	ModuleSetupWizard.OnWaitForSaveConnectionSettings(HandlerParameters, ContinueWait);
	
EndProcedure

&AtServer
Procedure OnCompleteConnectionSettingsSavingAtServer(ConnectionSettingsSaved,
		ConnectionSettingsAddressInStorage, ErrorMessage)
	
	CompletionStatus = Undefined;
	
	If IsExchangeWithApplicationInService Then
		ModuleSetupWizard = DataExchangeServer.ModuleDataSynchronizationBetweenWebApplicationsSetupWizard();
	Else
		ModuleSetupWizard = DataExchangeServer.ModuleDataExchangeCreationWizard();
	EndIf;
	
	If ModuleSetupWizard = Undefined Then
		ConnectionSettingsSaved = False;
		Return;
	EndIf;
	
	ModuleSetupWizard.OnCompleteSaveConnectionSettings(
		ConnectionSettingsSaveHandlerParameters, CompletionStatus);
	ConnectionSettingsSaveHandlerParameters = Undefined;
		
	If CompletionStatus.Cancel Then
		ConnectionSettingsSaved = False;
		ErrorMessage = CompletionStatus.ErrorMessage;
		Return;
	Else
		ConnectionSettingsSaved = CompletionStatus.Result.ConnectionSettingsSaved;
		
		If Not ConnectionSettingsSaved Then
			ErrorMessage = CompletionStatus.Result.ErrorMessage;
			Return;
		EndIf;
		
		ExchangeNode = CompletionStatus.Result.ExchangeNode;
		
		If SaveConnectionParametersToFile Then
			TempFile = GetTempFileName("xml");
			
			Record = New TextWriter;
			Record.Open(TempFile, "UTF-8");
			Record.Write(CompletionStatus.Result.XMLConnectionSettingsString);
			Record.Close();
			
			ConnectionSettingsAddressInStorage = PutToTempStorage(
				New BinaryData(TempFile), UUID);
				
			DeleteFiles(TempFile);
		EndIf;
		
		If Not SaaSModel Then
			HasDataToMap = CompletionStatus.Result.HasDataToMap;
		EndIf;
	EndIf;
	
EndProcedure

#EndRegion

&AtServer
Procedure FillWizardConnectionParametersStructure(WizardSettingsStructure, WithoutCorrespondent = False)
	
	// Transforming structure of form attributes to structure of wizard attributes.
	WizardSettingsStructure.Insert("ExchangePlanName",               ExchangePlanName);
	WizardSettingsStructure.Insert("CorrespondentExchangePlanName", CorrespondentExchangePlanName);
	
	WizardSettingsStructure.Insert("ExchangeSettingsOption", SettingID);
	
	WizardSettingsStructure.Insert("ExchangeFormat", ExchangeFormat);
	
	If ValueIsFilled(ExchangeNode)
		AND Not WithoutCorrespondent Then
		WizardSettingsStructure.Insert("Correspondent", ExchangeNode);
	EndIf;
	
	If ContinueSetupInSubordinateDIBNode
		Or ImportConnectionParametersFromFile Then
		WizardSettingsStructure.Insert("WizardRunOption", "ContinueDataExchangeSetup");
	Else
		WizardSettingsStructure.Insert("WizardRunOption", "SetUpNewDataExchange");
	EndIf;
	
	WizardSettingsStructure.Insert("NewRef", Undefined);
	
	WizardSettingsStructure.Insert("PredefinedNodeCode", SourceInfobaseID);
		
	WizardSettingsStructure.Insert("SecondInfobaseNewNodeCode", DestinationInfobaseID);
	WizardSettingsStructure.Insert("CorrespondentNodeCode",   DestinationInfobaseID);
	
	WizardSettingsStructure.Insert("ThisInfobaseDescription",   Description);
	WizardSettingsStructure.Insert("SecondInfobaseDescription", CorrespondentDescription);
	
	WizardSettingsStructure.Insert("SourceInfobasePrefix", Prefix);
	WizardSettingsStructure.Insert("DestinationInfobasePrefix", CorrespondentPrefix);
	
	WizardSettingsStructure.Insert("InfobaseNode", ExchangeNode);
	
	WizardSettingsStructure.Insert("UsePrefixesForExchangeSettings",               UsePrefixesForExchangeSettings);
	WizardSettingsStructure.Insert("UsePrefixesForCorrespondentExchangeSettings", UsePrefixesForCorrespondentExchangeSettings);
	
	WizardSettingsStructure.Insert("SourceInfobaseID", SourceInfobaseID);
	WizardSettingsStructure.Insert("DestinationInfobaseID", DestinationInfobaseID);
	
	WizardSettingsStructure.Insert("ExchangeDataSettingsFileFormatVersion",
		DataExchangeServer.ModuleDataExchangeCreationWizard().DataExchangeSettingsFormatVersion());
		
	WizardSettingsStructure.Insert("ExchangeFormatVersion", ExchangeFormatVersion);
	WizardSettingsStructure.Insert("SupportedObjectsInFormat", SupportedCorrespondentFormatObjects);
	
	// Transport settings. 	
	WizardSettingsStructure.Insert("COMOperatingSystemAuthentication",
		ExternalConnectionAuthenticationKind = "OperatingSystem");
	WizardSettingsStructure.Insert("COMInfobaseOperatingMode",
		?(ExternalConnectionInfobaseOperationMode = "File", 0, 1));
	WizardSettingsStructure.Insert("COM1CEnterpriseServerSideInfobaseName",
		ExternalConnectionInfobaseName);
	WizardSettingsStructure.Insert("COMUsername",
		ExternalConnectionUsername);
	WizardSettingsStructure.Insert("COM1CEnterpriseServerName",
		ExternalConnectionServerCluster);
	WizardSettingsStructure.Insert("COMInfobaseDirectory",
		ExternalConnectionInfobaseDirectory);
	WizardSettingsStructure.Insert("COMUserPassword",
		ExternalConnectionPassword);
		
	WizardSettingsStructure.Insert("EMAILMaxMessageSize",
		RegularCommunicationChannelsMAILMaxAttachmentSize);
	WizardSettingsStructure.Insert("EMAILCompressOutgoingMessageFile",
		RegularCommunicationChannelsArchiveFiles);
	WizardSettingsStructure.Insert("EMAILUserAccount",
		RegularCommunicationChannelsMAILUserAccount);
	WizardSettingsStructure.Insert("EMAILTransliterateExchangeMessageFileNames",
		RegularCommunicationChannelsTransliterateFileNames);
	
	WizardSettingsStructure.Insert("FILEInformationExchangeDirectory",
		RegularCommunicationChannelsFILEDirectory);
	WizardSettingsStructure.Insert("FILECompressOutgoingMessageFile",
		RegularCommunicationChannelsArchiveFiles);
	WizardSettingsStructure.Insert("FILETransliterateExchangeMessageFileNames",
		RegularCommunicationChannelsTransliterateFileNames);
	
	WizardSettingsStructure.Insert("FTPCompressOutgoingMessageFile",
		RegularCommunicationChannelsArchiveFiles);
	WizardSettingsStructure.Insert("FTPConnectionMaxMessageSize",
		RegularCommunicationChannelsFTPMaxFileSize);
	WizardSettingsStructure.Insert("FTPConnectionPassword",
		RegularCommunicationChannelsFTPPassword);
	WizardSettingsStructure.Insert("FTPConnectionPassiveConnection",
		RegularCommunicationChannelsFTPPassiveMode);
	WizardSettingsStructure.Insert("FTPConnectionUser",
		RegularCommunicationChannelsFTPUser);
	WizardSettingsStructure.Insert("FTPConnectionPort",
		RegularCommunicationChannelsFTPPort);
	WizardSettingsStructure.Insert("FTPConnectionPath",
		RegularCommunicationChannelsFTPPath);
	WizardSettingsStructure.Insert("FTPTransliterateExchangeMessageFileNames",
		RegularCommunicationChannelsTransliterateFileNames);
		
	WizardSettingsStructure.Insert("WSWebServiceURL", InternetWebAddress);
	WizardSettingsStructure.Insert("WSRememberPassword", InternetRememberPassword);
	WizardSettingsStructure.Insert("WSUsername", InternetUsername);
	WizardSettingsStructure.Insert("WSPassword", InternetPassword);
	
	If ConnectionKind = "Internet" Then
		WizardSettingsStructure.Insert("ExchangeMessagesTransportKind", Enums.ExchangeMessagesTransportTypes.WS);
	ElsIf ConnectionKind = "ExternalConnection" Then
		WizardSettingsStructure.Insert("ExchangeMessagesTransportKind", Enums.ExchangeMessagesTransportTypes.COM);
	ElsIf ConnectionKind = "RegularCommunicationChannels" Then
		If Not ValueIsFilled(RegularCommunicationChannelsDefaultTransportType) Then
			If RegularCommunicationChannelsFILEUsage Then
				WizardSettingsStructure.Insert("ExchangeMessagesTransportKind", Enums.ExchangeMessagesTransportTypes.FILE);
			ElsIf RegularCommunicationChannelsFTPUsage Then
				WizardSettingsStructure.Insert("ExchangeMessagesTransportKind", Enums.ExchangeMessagesTransportTypes.FTP);
			ElsIf RegularCommunicationChannelsEMAILUsage Then
				WizardSettingsStructure.Insert("ExchangeMessagesTransportKind", Enums.ExchangeMessagesTransportTypes.EMAIL);
			EndIf;
		ElsIf RegularCommunicationChannelsDefaultTransportType = "FILE" Then
			WizardSettingsStructure.Insert("ExchangeMessagesTransportKind", Enums.ExchangeMessagesTransportTypes.FILE);
		ElsIf RegularCommunicationChannelsDefaultTransportType = "FTP" Then
			WizardSettingsStructure.Insert("ExchangeMessagesTransportKind", Enums.ExchangeMessagesTransportTypes.FTP);
		ElsIf RegularCommunicationChannelsDefaultTransportType = "EMAIL" Then
			WizardSettingsStructure.Insert("ExchangeMessagesTransportKind", Enums.ExchangeMessagesTransportTypes.EMAIL);
		EndIf;
	ElsIf ConnectionKind = "PassiveMode" Then
		WizardSettingsStructure.Insert("ExchangeMessagesTransportKind", Enums.ExchangeMessagesTransportTypes.WSPassiveMode);
	EndIf;
	
	WizardSettingsStructure.Insert("UseTransportParametersCOM",   ConnectionKind = "ExternalConnection");
	
	WizardSettingsStructure.Insert("UseTransportParametersEMAIL", RegularCommunicationChannelsEMAILUsage);
	WizardSettingsStructure.Insert("UseTransportParametersFILE",  RegularCommunicationChannelsFILEUsage);
	WizardSettingsStructure.Insert("UseTransportParametersFTP",   RegularCommunicationChannelsFTPUsage);
	
	WizardSettingsStructure.Insert("ArchivePasswordExchangeMessages", RegularCommunicationChannelsArchivePassword);
	
EndProcedure

&AtServer
Procedure ReadWizardConnectionParametersStructure(WizardSettingsStructure)
	
	// Transforming structure of wizard attributes to structure of form attributes.
	SourceInfobaseID = WizardSettingsStructure.PredefinedNodeCode;
	DestinationInfobaseID = WizardSettingsStructure.SecondInfobaseNewNodeCode;
	
	CorrespondentExchangePlanName = WizardSettingsStructure.CorrespondentExchangePlanName;
	
	UsePrefixesForCorrespondentExchangeSettings =
		Not DataExchangeCached.IsXDTOExchangePlan(ExchangePlanName)
			Or StrLen(DestinationInfobaseID) <> 36
			Or StrLen(SourceInfobaseID) <> 36;
	
	If DescriptionChangeAvailable Then
		Description = WizardSettingsStructure.ThisInfobaseDescription;
	EndIf;
	
	If CorrespondentDescriptionChangeAvailable Then
		CorrespondentDescription = WizardSettingsStructure.SecondInfobaseDescription;
	EndIf;
	
	If PrefixChangeAvailable Then
		Prefix = WizardSettingsStructure.SourceInfobasePrefix;
		If IsBlankString(Prefix)
			AND (UsePrefixesForExchangeSettings Or UsePrefixesForCorrespondentExchangeSettings) Then
			Prefix = WizardSettingsStructure.PredefinedNodeCode;
		EndIf;
	EndIf;
	
	If CorrespondentPrefixChangeAvailable Then
		CorrespondentPrefix = WizardSettingsStructure.DestinationInfobasePrefix;
		If IsBlankString(CorrespondentPrefix)
			AND (UsePrefixesForExchangeSettings Or UsePrefixesForCorrespondentExchangeSettings) Then
			CorrespondentPrefix = WizardSettingsStructure.SecondInfobaseNewNodeCode;
		EndIf;
	EndIf;
	
	// Transport settings.
	ExternalConnectionAuthenticationKind =
		?(WizardSettingsStructure.COMOperatingSystemAuthentication, "OperatingSystem", "1CEnterprise");
	ExternalConnectionInfobaseOperationMode =
		?(WizardSettingsStructure.COMInfobaseOperatingMode = 0, "File", "ClientServer");
	ExternalConnectionInfobaseName =
		WizardSettingsStructure.COM1CEnterpriseServerSideInfobaseName;
	ExternalConnectionUsername =
		WizardSettingsStructure.COMUsername;
	ExternalConnectionServerCluster =
		WizardSettingsStructure.COM1CEnterpriseServerName;
	ExternalConnectionInfobaseDirectory =
		WizardSettingsStructure.COMInfobaseDirectory;
	ExternalConnectionPassword =
		WizardSettingsStructure.COMUserPassword;
	
	RegularCommunicationChannelsMAILMaxAttachmentSize =
		WizardSettingsStructure.EMAILMaxMessageSize;
	RegularCommunicationChannelsEMAILEnableAttachmentSizeLimit = 
		ValueIsFilled(RegularCommunicationChannelsMAILMaxAttachmentSize);
	RegularCommunicationChannelsMAILUserAccount =
		WizardSettingsStructure.EMAILUserAccount;
	
	RegularCommunicationChannelsFILEDirectory =
		WizardSettingsStructure.FILEInformationExchangeDirectory;
	
	RegularCommunicationChannelsFTPMaxFileSize =
		WizardSettingsStructure.FTPConnectionMaxMessageSize;
	RegularCommunicationChannelsFTPEnableFileSizeLimit =
		ValueIsFilled(RegularCommunicationChannelsFTPMaxFileSize);
	RegularCommunicationChannelsFTPPassword =
		WizardSettingsStructure.FTPConnectionPassword;
	RegularCommunicationChannelsFTPPassiveMode =
		WizardSettingsStructure.FTPConnectionPassiveConnection;
	RegularCommunicationChannelsFTPUser =
		WizardSettingsStructure.FTPConnectionUser;
	RegularCommunicationChannelsFTPPort =
		WizardSettingsStructure.FTPConnectionPort;
	RegularCommunicationChannelsFTPPath =
		WizardSettingsStructure.FTPConnectionPath;
		
	InternetWebAddress        = WizardSettingsStructure.WSWebServiceURL;
	InternetRememberPassword = WizardSettingsStructure.WSRememberPassword;
	InternetUsername = WizardSettingsStructure.WSUsername;
	InternetPassword          = WizardSettingsStructure.WSPassword;
	
	If WizardSettingsStructure.ExchangeMessagesTransportKind = Enums.ExchangeMessagesTransportTypes.WS Then
		ConnectionKind = "Internet";
	ElsIf WizardSettingsStructure.ExchangeMessagesTransportKind = Enums.ExchangeMessagesTransportTypes.COM Then
		ConnectionKind = "ExternalConnection";
	ElsIf WizardSettingsStructure.ExchangeMessagesTransportKind = Enums.ExchangeMessagesTransportTypes.FILE
		Or WizardSettingsStructure.ExchangeMessagesTransportKind = Enums.ExchangeMessagesTransportTypes.FTP
		Or WizardSettingsStructure.ExchangeMessagesTransportKind = Enums.ExchangeMessagesTransportTypes.EMAIL Then
		ConnectionKind = "RegularCommunicationChannels";
	ElsIf WizardSettingsStructure.ExchangeMessagesTransportKind = Enums.ExchangeMessagesTransportTypes.WSPassiveMode Then
		ConnectionKind = "PassiveMode";
	EndIf;
	
	RegularCommunicationChannelsEMAILUsage = WizardSettingsStructure.UseTransportParametersEMAIL;
	RegularCommunicationChannelsFILEUsage  = WizardSettingsStructure.UseTransportParametersFILE;
	RegularCommunicationChannelsFTPUsage   = WizardSettingsStructure.UseTransportParametersFTP;
	
	If RegularCommunicationChannelsFILEUsage Then
		RegularCommunicationChannelsDefaultTransportType = "FILE";
	ElsIf RegularCommunicationChannelsFTPUsage Then
		RegularCommunicationChannelsDefaultTransportType = "FTP";
	ElsIf RegularCommunicationChannelsEMAILUsage Then
		RegularCommunicationChannelsDefaultTransportType = "EMAIL";
	EndIf;
	
	RegularCommunicationChannelsTransliterateFileNames =
		WizardSettingsStructure.FILETransliterateExchangeMessageFileNames
		Or WizardSettingsStructure.FTPTransliterateExchangeMessageFileNames
		Or WizardSettingsStructure.EMAILTransliterateExchangeMessageFileNames;
		
	RegularCommunicationChannelsArchiveFiles =
		WizardSettingsStructure.FILECompressOutgoingMessageFile
		Or WizardSettingsStructure.FTPCompressOutgoingMessageFile
		Or WizardSettingsStructure.EMAILCompressOutgoingMessageFile;	
	
	RegularCommunicationChannelsArchivePassword = WizardSettingsStructure.ArchivePasswordExchangeMessages;
	
	RegularCommunicationChannelsProtectArchiveWithPassword = ValueIsFilled(RegularCommunicationChannelsArchivePassword);
	
EndProcedure

&AtServer
Procedure FillCorrespondentParameters(CorrespondentParameters, CorrespondentInSaaS = False)
	
	If ValueIsFilled(CorrespondentParameters.InfobasePrefix) Then
		CorrespondentPrefix = CorrespondentParameters.InfobasePrefix;
		CorrespondentPrefixChangeAvailable = False;
	Else
		CorrespondentPrefix = CorrespondentParameters.DefaultInfobasePrefix;
		CorrespondentPrefixChangeAvailable = True;
	EndIf;
	
	If Not CorrespondentInSaaS Then
		If ValueIsFilled(CorrespondentParameters.InfobaseDescription) Then
			CorrespondentDescription = CorrespondentParameters.InfobaseDescription;
		Else
			CorrespondentDescription = CorrespondentParameters.DefaultInfobaseDescription;
		EndIf;
	EndIf;
	
	DestinationInfobaseID = CorrespondentParameters.ThisNodeCode;
	
	CorrespondentConfigurationVersion = CorrespondentParameters.ConfigurationVersion;
	
	CorrespondentExchangePlanName = CorrespondentParameters.ExchangePlanName;
	
	If XDTOSetup Then
		UsePrefixesForCorrespondentExchangeSettings = CorrespondentParameters.UsePrefixesForExchangeSettings;
		
		ExchangeFormatVersion = DataExchangeXDTOServer.MaxCommonFormatVersion(
			ExchangePlanName, CorrespondentParameters.ExchangeFormatVersions);
		
		SupportedCorrespondentFormatObjects = New ValueStorage(
			CorrespondentParameters.SupportedObjectsInFormat, New Deflation(9));
	ElsIf ConnectionKind = "Internet"
		AND StrLen(DestinationInfobaseID) = 9 Then
		UsePrefixesForExchangeSettings               = False;
		UsePrefixesForCorrespondentExchangeSettings = False;
		
		If IsBlankString(SourceInfobaseID) Then
			SourceInfobaseID = Prefix;
		EndIf;
	EndIf;
	
EndProcedure

&AtServer
Procedure FillConnectionParametersFromXMLAtServer(AddressInStorage, Cancel, ErrorMessage = "")
	
	ModuleSetupWizard = DataExchangeServer.ModuleDataExchangeCreationWizard();
	
	TempFile = GetTempFileName("xml");
		
	FileData = GetFromTempStorage(AddressInStorage);
	FileData.Write(TempFile);
	
	Try
		ConnectionSettings = ModuleSetupWizard.Create();
		ConnectionSettings.ExchangePlanName = ExchangePlanName;
		ConnectionSettings.ExchangeSettingsOption = SettingID;
		ConnectionSettings.WizardRunOption = "ContinueDataExchangeSetup";
		
		ModuleSetupWizard.FillConnectionSettingsFromXMLString(
			ConnectionSettings, TempFile, True);
	Except
		Cancel = True;
		ErrorMessage   = BriefErrorDescription(ErrorInfo());
		ErrorMessageEventLog = DetailErrorDescription(ErrorInfo());
		
		WriteLogEvent(DataExchangeServer.DataExchangeCreationEventLogEvent(),
			EventLogLevel.Error, , , ErrorMessageEventLog);
	EndTry;
		
	DeleteFiles(TempFile);
	DeleteFromTempStorage(AddressInStorage);
	
	If Not Cancel Then
		ReadWizardConnectionParametersStructure(ConnectionSettings);
	EndIf;
	
EndProcedure

&AtServer
Procedure FillXDTOCorrespondentSettingsFromXMLAtServer(AddressInStorage, Cancel, ErrorMessage = "")
	
	ModuleSetupWizard = DataExchangeServer.ModuleDataExchangeCreationWizard();
	
	TempFile = GetTempFileName("xml");
		
	FileData = GetFromTempStorage(AddressInStorage);
	FileData.Write(TempFile);
	
	Try
		XDTOCorrespondentSettings = ModuleSetupWizard.XDTOCorrespondentSettingsFromXML(
			TempFile, True, ExchangePlans[ExchangePlanName].EmptyRef());
	Except
		Cancel = True;
		ErrorMessage = DetailErrorDescription(ErrorInfo());
		
		WriteLogEvent(DataExchangeServer.DataExchangeCreationEventLogEvent(),
			EventLogLevel.Error, , , ErrorMessage);
	EndTry;

	DeleteFiles(TempFile);
	DeleteFromTempStorage(AddressInStorage);
	
	If Not Cancel Then
		ExchangeFormatVersion = DataExchangeXDTOServer.MaxCommonFormatVersion(ExchangePlanName,
			XDTOCorrespondentSettings.SupportedVersions);
			
		SupportedCorrespondentFormatObjects = New ValueStorage(XDTOCorrespondentSettings.SupportedObjects,
			New Deflation(9));
			
		DestinationInfobaseID = XDTOCorrespondentSettings.SenderID;
		
		UsePrefixesForCorrespondentExchangeSettings = (StrLen(DestinationInfobaseID) <> 36);
	EndIf;
	
EndProcedure

&AtServer
Procedure FillAvailableTransportKinds()
	
	AvailableTransportKinds = New Structure;
	
	UsedExchangeMessagesTransports = DataExchangeCached.UsedExchangeMessagesTransports(
		ExchangePlans[ExchangePlanName].EmptyRef(), SettingID);
		
	For Each CurrentTransportKind In UsedExchangeMessagesTransports Do
		// In SaaS mode, exchange via the Internet and passive Internet connections are supported for XDTO 
		// exchange plans only.	
		If SaaSModel Then
			If CurrentTransportKind <> Enums.ExchangeMessagesTransportTypes.WS
				AND CurrentTransportKind <> Enums.ExchangeMessagesTransportTypes.WSPassiveMode Then
				Continue;
			EndIf;
			
			If Not XDTOSetup Then
				Continue;
			EndIf;
		EndIf;
			
		AvailableTransportKinds.Insert(Common.EnumValueName(CurrentTransportKind));
	EndDo;
	
EndProcedure

&AtClient
Procedure OnCompletePutConnectionSettingsFileForImport(SelectionResult, Address, SelectedFileName, AdditionalParameters) Export
	
	Result = New Structure;
	Result.Insert("Cancel", False);
	Result.Insert("ErrorMessage", "");
	
	If Not SelectionResult Then
		Result.Cancel = True;
	Else
		FillConnectionParametersFromXMLAtServer(Address, Result.Cancel, Result.ErrorMessage);
	EndIf;
	
	If Result.Cancel Then
		If IsBlankString(Result.ErrorMessage) Then
			Result.ErrorMessage = NStr("ru = 'Не удалось загрузить файл с настройками подключения.'; en = 'Cannot load the connection settings file.'; pl = 'Nie udało się pobrać pliku z ustawieniami połączenia.';de = 'Die Datei mit den Verbindungseinstellungen konnte nicht heruntergeladen werden.';ro = 'Eșec de încărcare a fișierului cu setările de conectare.';tr = 'Bağlantı ayarlarına sahip dosya içe aktarılamadı.'; es_ES = 'No se ha podido descargar el archivo con ajustes de conexión.'");
		EndIf;
	Else
		DescriptionChangeAvailable = False;
		PrefixChangeAvailable     = False;
		
		CorrespondentDescriptionChangeAvailable = False;
		CorrespondentPrefixChangeAvailable     = False;
	EndIf;
	
	ExecuteNotifyProcessing(AdditionalParameters.Notification, Result);
	
EndProcedure

&AtClient
Procedure OnCompletePutXDTOCorrespondentSettingsFile(SelectionResult, Address, SelectedFileName, AdditionalParameters) Export
	
	Result = New Structure;
	Result.Insert("Cancel",             False);
	Result.Insert("ErrorMessage", "");
	
	If Not SelectionResult Then
		Result.Cancel = True;
	Else
		FillXDTOCorrespondentSettingsFromXMLAtServer(Address, Result.Cancel, Result.ErrorMessage);
	EndIf;
	
	If Result.Cancel Then
		If IsBlankString(Result.ErrorMessage) Then
			Result.ErrorMessage = NStr("ru = 'Не удалось загрузить файл с настройками корреспондента.'; en = 'Cannot load the file with peer application settings.'; pl = 'Nie udało się pobrać pliku z ustawieniami korespondenta.';de = 'Es konnte keine Datei mit den korrespondierenden Einstellungen heruntergeladen werden.';ro = 'Eșec de încărcare a fișierului cu setările corespondentului.';tr = 'Muhabir ayarlarına sahip dosya içe aktarılamadı.'; es_ES = 'No se ha podido descargar el archivo con ajustes del correspondiente.'");
		EndIf;
	EndIf;
	
	ExecuteNotifyProcessing(AdditionalParameters.Notification, Result);
	
EndProcedure

&AtClient
Procedure ConnectionParametersRegularCommunicationChannelsContinueSetting(Result, AdditionalParameters) Export
	
	If Result.Cancel Then
		ChangeNavigationNumber(-1);
		CommonClient.MessageToUser(Result.ErrorMessage);
		Return;
	EndIf;
	
	Items.InternetAccessParameters.Visible = InternetAccessParametersSetupAvailable;
	
	Items.SyncOverDirectoryGroup.Visible = AvailableTransportKinds.Property("FILE");
	Items.SyncOverFTPGroup.Visible = AvailableTransportKinds.Property("FTP");
	Items.SyncOverEMAILGroup.Visible = AvailableTransportKinds.Property("EMAIL");
	
	If RegularCommunicationChannelsFILEUsage Then
		Items.SyncOverDirectoryGroup.Show();
	Else
		Items.SyncOverDirectoryGroup.Hide();
	EndIf;
	
	If RegularCommunicationChannelsFTPUsage Then
		Items.SyncOverFTPGroup.Show();
	Else
		Items.SyncOverFTPGroup.Hide();
	EndIf;
	
	If RegularCommunicationChannelsEMAILUsage Then
		Items.SyncOverEMAILGroup.Show();
	Else
		Items.SyncOverEMAILGroup.Hide();
	EndIf;
	
	If AdditionalParameters.IsMoveNext Then
	
		OnChangeRegularCommunicationChannelsFILEUsage();
		OnChangeRegularCommunicationChannelsFTPUsage();
		OnChangeRegularCommunicationChannelsEMAILUsage();
		
		OnChangeRegularCommunicationChannelsArchiveFiles();
		
	EndIf;
	
EndProcedure

&AtClient
Procedure CommonSynchronizationSettingsContinueSetting(Result, AdditionalParameters) Export
	
	If Result.Cancel Then
		ChangeNavigationNumber(-1);
		CommonClient.MessageToUser(Result.ErrorMessage);
		Return;
	EndIf;
	
	If AdditionalParameters.IsMoveNext Then
		Items.RegularCommunicationChannelsDefaultTransportType.ChoiceList.Clear();
		
		If RegularCommunicationChannelsFILEUsage Then
			Items.RegularCommunicationChannelsDefaultTransportType.ChoiceList.Add("FILE");
			RegularCommunicationChannelsDefaultTransportType = "FILE";
		EndIf;
		
		If RegularCommunicationChannelsFTPUsage Then
			Items.RegularCommunicationChannelsDefaultTransportType.ChoiceList.Add("FTP");
			If Not ValueIsFilled(RegularCommunicationChannelsDefaultTransportType) Then
				RegularCommunicationChannelsDefaultTransportType = "FTP";
			EndIf;
		EndIf;
		
		If RegularCommunicationChannelsEMAILUsage Then
			Items.RegularCommunicationChannelsDefaultTransportType.ChoiceList.Add("EMAIL");
			If Not ValueIsFilled(RegularCommunicationChannelsDefaultTransportType) Then
				RegularCommunicationChannelsDefaultTransportType = "EMAIL";
			EndIf;
		EndIf;
	EndIf;
	
	CommonClientServer.SetFormItemProperty(Items,
		"RegularCommunicationChannelsDefaultTransportType",
		"Visible",
		Items.RegularCommunicationChannelsDefaultTransportType.ChoiceList.Count() > 1);
		
	SaveConnectionParametersToFile = (ConnectionKind = "PassiveMode")
		Or ((ConnectionKind = "RegularCommunicationChannels")
			AND Not DIBSetup AND Not ImportConnectionParametersFromFile);
		
	CommonClientServer.SetFormItemProperty(Items,
		"ConnectionSettingsFileNameToExport", "Visible", SaveConnectionParametersToFile);
			
	If SaveConnectionParametersToFile
		AND (ConnectionKind = "RegularCommunicationChannels")
		AND RegularCommunicationChannelsFILEUsage Then
		ConnectionSettingsFileNameToExport = CommonClientServer.GetFullFileName(
			RegularCommunicationChannelsFILEDirectory, SettingsFileNameForDestination + ".xml");
	EndIf;
		
	CommonClientServer.SetFormItemProperty(Items,
		"ApplicationSettingsGroupPresentation", "Visible", Not (ConnectionKind = "PassiveMode"));
	
	CommonClientServer.SetFormItemProperty(Items,
		"Description", "ReadOnly", Not DescriptionChangeAvailable);
	
	CommonClientServer.SetFormItemProperty(Items,
		"Prefix", "ReadOnly", Not PrefixChangeAvailable);
	
	CommonClientServer.SetFormItemProperty(Items,
		"CorrespondentDescription", "ReadOnly", Not CorrespondentDescriptionChangeAvailable);
	
	CommonClientServer.SetFormItemProperty(Items,
		"CorrespondentPrefix", "ReadOnly", Not CorrespondentPrefixChangeAvailable);
	
EndProcedure

&AtClient
Procedure RegisterCOMConnectorCompletion(Registered, AdditionalParameters) Export
	
	OnStartCheckConnectionOnline();
	
EndProcedure

#Region FormInitializationOnCreate

&AtServer
Procedure CheckCanUseForm(Cancel = False)
	
	// Parameters of the data exchange creation wizard must be passed.
	If Not Parameters.Property("ExchangePlanName")
		Or Not Parameters.Property("SettingID") Then
		MessageText = NStr("ru = 'Форма не предназначена для непосредственного использования.'; en = 'The form cannot be opened manually.'; pl = 'Formularz nie jest przeznaczony dla bezpośredniego użycia.';de = 'Das Formular ist nicht für den direkten Gebrauch bestimmt.';ro = 'Forma nu este destinată pentru utilizare nemijlocită.';tr = 'Form doğrudan kullanım için uygun değildir.'; es_ES = 'El formulario no está destinado para el uso directo.'");
		Common.MessageToUser(MessageText, , , , Cancel);
		Return;
	EndIf;
	
EndProcedure

&AtServer
Procedure InitializeFormProperties()
	
	If DIBSetup Then
		Title = NStr("ru = 'Настройка распределенной информационной базы'; en = 'Configure distributed infobase'; pl = 'Konfiguracja przydzielonej bazy informacyjnej';de = 'Aufbau einer verteilten Informationsbasis';ro = 'Setarea bazei de informații distribuite';tr = 'Dağıtılmış veri tabanı ayarı'; es_ES = 'Ajuste de la base de información distribuida'");
	Else
		Title = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Настройка подключения к ""%1""'; en = 'Configure connection to %1'; pl = 'Ustawienie połączenia do ""%1""';de = 'Verbindungsaufbau zu ""%1"" einstellen';ro = 'Setarea conexiunii la ""%1""';tr = '""%1"" bağlantı ayarları'; es_ES = 'Ajuste de conexión a ""%1""'"),
			CorrespondentConfigurationDescription);
	EndIf;
	
EndProcedure

&AtServer
Procedure InitializeFormAttributes()
	
	ExchangePlanName         = Parameters.ExchangePlanName;
	SettingID = Parameters.SettingID;
	
	ContinueSetupInSubordinateDIBNode = Parameters.Property("ContinueSetupInSubordinateDIBNode");
	
	CorrespondentConfigurationVersion = "";
	
	SaaSModel = Common.DataSeparationEnabled()
		AND Common.SeparatedDataUsageAvailable();
		
	InternetAccessParametersSetupAvailable = Not SaaSModel
		AND Common.SubsystemExists("StandardSubsystems.GetFilesFromInternet");
		
	DIBSetup  = DataExchangeCached.IsDistributedInfobaseExchangePlan(ExchangePlanName);
	XDTOSetup = DataExchangeServer.IsXDTOExchangePlan(ExchangePlanName);
	
	FillAvailableTransportKinds();
	
	If AvailableTransportKinds.Property("COM") Then
		ConnectionKind = "ExternalConnection";
		
		ExternalConnectionInfobaseOperationMode = "File";
		ExternalConnectionAuthenticationKind = "1CEnterprise";
	ElsIf AvailableTransportKinds.Property("WS") Then
		ConnectionKind = "Internet";
	ElsIf AvailableTransportKinds.Property("FILE")
		Or AvailableTransportKinds.Property("FTP")
		Or AvailableTransportKinds.Property("EMAIL") Then
		ConnectionKind = "RegularCommunicationChannels";
	ElsIf AvailableTransportKinds.Property("WSPassiveMode") Then
		ConnectionKind = "PassiveMode";
	EndIf;
	
	If AvailableTransportKinds.Property("FILE") Then
		RegularCommunicationChannelsFILEUsage  = True;
	ElsIf AvailableTransportKinds.Property("FTP") Then
		RegularCommunicationChannelsFTPUsage   = True;
	ElsIf AvailableTransportKinds.Property("EMAIL") Then
		RegularCommunicationChannelsEMAILUsage = True;
	EndIf;
	
	If AvailableTransportKinds.Property("FTP") Then
		RegularCommunicationChannelsFTPPort = 21;
		RegularCommunicationChannelsFTPPassiveMode = True;
	EndIf;
	
	ConnectionSetupMethod = ?(SaaSModel, "ApplicationFromList", "ConfigureManually");
	
	SettingsValuesForOption = DataExchangeServer.ExchangePlanSettingValue(ExchangePlanName,
		"CorrespondentConfigurationName,
		|ExchangeFormat,
		|SettingsFileNameForDestination,
		|CorrespondentConfigurationDescription,
		|ExchangeBriefInfo,
		|ExchangeDetailedInformation,
		|DataSyncSettingsWizardFormName",
		SettingID);
	
	FillPropertyValues(ThisObject, SettingsValuesForOption);
	
	CorrespondentExchangePlanName = ExchangePlanName;
	
	DescriptionChangeAvailable = False;
	PrefixChangeAvailable     = False;
	
	CorrespondentDescriptionChangeAvailable = True;
	CorrespondentPrefixChangeAvailable     = True;
	
	If SaaSModel Then
		ModuleDataExchangeSaaS = Common.CommonModule("DataExchangeSaaS");
		Description = ModuleDataExchangeSaaS.GeneratePredefinedNodeDescription();
	Else
		// This infobase presentation.
		Description = DataExchangeServer.PredefinedExchangePlanNodeDescription(ExchangePlanName);
		If IsBlankString(Description) Then
			DescriptionChangeAvailable = True;
			Description = DataExchangeCached.ThisInfobaseName();
		EndIf;
		DescriptionChangeAvailable = True;
		
		CorrespondentDescription = CorrespondentConfigurationDescription;
	EndIf;
	
	Prefix = GetFunctionalOption("InfobasePrefix");
	If IsBlankString(Prefix) Then
		PrefixChangeAvailable = True;
		DataExchangeOverridable.OnDetermineDefaultInfobasePrefix(Prefix);
	EndIf;
	
	If DIBSetup Then
		ConnectionKind = "RegularCommunicationChannels";
	EndIf;
	
	If ContinueSetupInSubordinateDIBNode Then
		ExchangeNode = DataExchangeServer.MasterNode();
		
		// Filling parameters from connection settings in the constant.
		ModuleSetupWizard = DataExchangeServer.ModuleDataExchangeCreationWizard();
		
		ExchangeCreationWizard = ModuleSetupWizard.Create();
		ExchangeCreationWizard.ExchangePlanName = ExchangePlanName;
		ExchangeCreationWizard.ExchangeSettingsOption = SettingID;
		ExchangeCreationWizard.WizardRunOption = "ContinueDataExchangeSetup";
		
		ModuleSetupWizard.FillConnectionSettingsFromConstant(ExchangeCreationWizard);		
		ReadWizardConnectionParametersStructure(ExchangeCreationWizard);
		
		DescriptionChangeAvailable = False;
		PrefixChangeAvailable     = False;
		
		CorrespondentDescriptionChangeAvailable = False;
		CorrespondentPrefixChangeAvailable     = False;
	EndIf;
	
	SourceInfobaseID = DataExchangeServer.CodeOfPredefinedExchangePlanNode(ExchangePlanName);
	
	If XDTOSetup Then
		UsePrefixesForExchangeSettings = Not DataExchangeXDTOServer.VersionWithDataExchangeIDSupported(
			ExchangePlans[ExchangePlanName].EmptyRef());
		
		If IsBlankString(SourceInfobaseID) Then
			SourceInfobaseID = ?(UsePrefixesForExchangeSettings,
				Prefix, String(New UUID));
		EndIf;
	Else
		UsePrefixesForExchangeSettings = True;
	EndIf;
	
	// To get settings from the correspondent, set the default mode.
	UsePrefixesForCorrespondentExchangeSettings = True;
	
	FillNavigationTable();
	
EndProcedure

#EndRegion

#Region WizardScenarios

&AtServer
Function AddNavigationTableRow(MainPageName, NavigationPageName, DecorationPageName = "")
	
	NavigationsString = NavigationTable.Add();
	NavigationsString.SwitchNumber = NavigationTable.Count();
	NavigationsString.MainPageName = MainPageName;
	NavigationsString.NavigationPageName = NavigationPageName;
	NavigationsString.DecorationPageName = DecorationPageName;
	
	Return NavigationsString;
	
EndFunction

&AtServer
Procedure FillNavigationTable()
	
	NavigationTable.Clear();
	
	If DIBSetup Then
		NewNavigation = AddNavigationTableRow("ConnectionParametersRegularCommunicationChannelsPage", "NavigationStartPage");
		NewNavigation.OnOpenHandlerName = "CommonCommunicationChannelsConnectionParametersPage_OnOpen";
		NewNavigation.OnSwitchToNextPageHandlerName = "CommonCommunicationChannelsConnectionParametersPage_OnGoNext";
	Else
		NewNavigation = AddNavigationTableRow("ConnectionSetupMethodPage", "NavigationStartPage");
		NewNavigation.OnOpenHandlerName = "ConnectionSetupMethodPage_OnOpen";
		NewNavigation.OnSwitchToNextPageHandlerName = "ConnectionSetupMethodPage_OnGoNext";
		
		NewNavigation = AddNavigationTableRow("ConnectionParametersInternetPage", "PageNavigationFollowUp");
		NewNavigation.OnOpenHandlerName = "InternetConnectionParametersPage_OnOpen";
		NewNavigation.OnSwitchToNextPageHandlerName = "InternetConnectionParametersPage_OnGoNext";
		
		If Not SaaSModel Then
			NewNavigation = AddNavigationTableRow("ConnectionParametersExternalConnectionPage", "PageNavigationFollowUp");
			NewNavigation.OnOpenHandlerName = "ConnectionParametersExternalConnectionPage_OnOpen";
			NewNavigation.OnSwitchToNextPageHandlerName = "ConnectionParametersExternalConnectionPage_OnGoNext";
			
			NewNavigation = AddNavigationTableRow("ConnectionParametersRegularCommunicationChannelsPage", "PageNavigationFollowUp");
			NewNavigation.OnOpenHandlerName = "CommonCommunicationChannelsConnectionParametersPage_OnOpen";
			NewNavigation.OnSwitchToNextPageHandlerName = "CommonCommunicationChannelsConnectionParametersPage_OnGoNext";
		EndIf;
	EndIf;
	
	NewNavigation = AddNavigationTableRow("ConnectionTestPage", "PageNavigationFollowUp");
	NewNavigation.OnOpenHandlerName = "ConnectionCheckPage_OnOpen";
	NewNavigation.TimeConsumingOperation = True;
	NewNavigation.TimeConsumingOperationHandlerName = "ConnectionCheckPage_TimeConsumingOperation";
	
	NewNavigation = AddNavigationTableRow("CommonSynchronizationSettingsPage", "PageNavigationFollowUp");
	NewNavigation.OnOpenHandlerName = "GeneralSynchronizationSettingsPage_OnOpen";
	NewNavigation.OnSwitchToNextPageHandlerName = "GeneralSynchronizationSettingsPage_OnGoNext";
	
	NewNavigation = AddNavigationTableRow("SaveConnectionSettingsPage", "PageNavigationFollowUp");
	NewNavigation.TimeConsumingOperation = True;
	NewNavigation.TimeConsumingOperationHandlerName = "SaveConnectionSettingsPage_TimeConsumingOperation";
	
	NewNavigation = AddNavigationTableRow("EndPage", "NavigationEndPage");
	
EndProcedure

#EndRegion

#Region FormAttributesChangesHandlers

&AtClient
Procedure OnChangeConnectionSetupMethod()
	
	IsExchangeWithApplicationInService = (ConnectionSetupMethod = "ApplicationFromList");
	
	If ConnectionSetupMethod = "ApplicationFromList" Then
		Items.ConnectionSetupMethodsPanel.CurrentPage = Items.MyApplicationsPage;
		
		StartGetConnectionsListForConnection();
	ElsIf ConnectionSetupMethod = "ConfigureManually" Then
		
		Items.ExternalConnectionConnectionKind.Visible  = AvailableTransportKinds.Property("COM");
		Items.InternetConnectionKind.Visible           = AvailableTransportKinds.Property("WS");
		Items.RegularCommunicationChannelsConnectionKind.Visible = AvailableTransportKinds.Property("FILE")
			Or AvailableTransportKinds.Property("FTP")
			Or AvailableTransportKinds.Property("EMAIL");
			
		Items.PassiveModeConnectionKind.Visible      = AvailableTransportKinds.Property("WSPassiveMode");
		
		Items.SettingsFilePassiveModeGroup.Visible = AvailableTransportKinds.Property("WSPassiveMode");
		Items.SettingsFileRegularCommunicationChannelsGroup.Visible = AvailableTransportKinds.Property("FILE")
			Or AvailableTransportKinds.Property("FTP")
			Or AvailableTransportKinds.Property("EMAIL");
		
		Items.ConnectionSetupMethodsPanel.CurrentPage = Items.ConnectionKindsPage;
		OnChangeConnectionKind();
		
	EndIf;
	
EndProcedure

&AtClient
Procedure OnChangeImportConnectionSettingsFromFile()
	
	CommonClientServer.SetFormItemProperty(Items,
		"ConnectionSettingsFileNameToImport", "Enabled", ImportConnectionParametersFromFile);
	
EndProcedure

&AtClient
Procedure OnChangeConnectionKind()
	
	CommonClientServer.SetFormItemProperty(Items,
		"SettingsFileRegularCommunicationChannelsGroup", "Enabled", ConnectionKind = "RegularCommunicationChannels");
	
	CommonClientServer.SetFormItemProperty(Items,
		"SettingsFilePassiveModeGroup", "Enabled", ConnectionKind = "PassiveMode");
	
	If ConnectionKind = "RegularCommunicationChannels" Then
		OnChangeImportConnectionSettingsFromFile();
	EndIf;
	
EndProcedure

&AtClient
Procedure OnChangeRegularCommunicationChannelsFILEUsage()
	
	CommonClientServer.SetFormItemProperty(Items,
		"RegularCommunicationChannelFILEUsageGroup", "Enabled", RegularCommunicationChannelsFILEUsage);
	
EndProcedure
	
&AtClient
Procedure OnChangeRegularCommunicationChannelsFTPUsage()
	
	CommonClientServer.SetFormItemProperty(Items,
		"RegularCommunicationChannelFTPUsageGroup", "Enabled", RegularCommunicationChannelsFTPUsage);
	
	OnChangeRegularCommunicationChannelsFTPUseFileSizeLimit();
	
EndProcedure

&AtClient
Procedure OnChangeRegularCommunicationChannelsEMAILUsage()
	
	CommonClientServer.SetFormItemProperty(Items,
		"RegularCommunicationChannelsEMAILUsageGroup", "Enabled", RegularCommunicationChannelsEMAILUsage);
	
	OnChangeRegularCommunicationChannelsEMAILUseAttachmentSizeLimit();
	
EndProcedure

&AtClient
Procedure OnChangeExternalConnectionInfobaseOperationMode()
	
	CommonClientServer.SetFormItemProperty(Items,
		"ExternalConnectionInfobaseDirectory",
		"Enabled", ExternalConnectionInfobaseOperationMode = "File");
		
	CommonClientServer.SetFormItemProperty(Items,
		"ExternalConnectionServerCluster",
		"Enabled", ExternalConnectionInfobaseOperationMode = "ClientServer");
		
	CommonClientServer.SetFormItemProperty(Items,
		"ExternalConnectionInfobaseName",
		"Enabled", ExternalConnectionInfobaseOperationMode = "ClientServer");
	
EndProcedure
	
&AtClient
Procedure OnChangeExternalConnectionAuthenticationKind()
	
	CommonClientServer.SetFormItemProperty(Items,
		"ExternalConnectionUsername",
		"Enabled", ExternalConnectionAuthenticationKind = "1CEnterprise");
		
	CommonClientServer.SetFormItemProperty(Items,
		"ExternalConnectionPassword",
		"Enabled", ExternalConnectionAuthenticationKind = "1CEnterprise");
	
EndProcedure

&AtClient
Procedure OnChangeRegularCommunicationChannelsArchiveFiles()
	
	CommonClientServer.SetFormItemProperty(Items,
		"RegularCommunicationChannelArchivePasswordGroup", "Enabled", RegularCommunicationChannelsArchiveFiles);
	
	OnChangeRegularCommunicationChannelsUseArchivePassword();
	
EndProcedure

&AtClient
Procedure OnChangeRegularCommunicationChannelsUseArchivePassword()
	
	CommonClientServer.SetFormItemProperty(Items,
		"RegularCommunicationChannelsArchivePassword", "Enabled", RegularCommunicationChannelsProtectArchiveWithPassword);
	
EndProcedure

&AtClient
Procedure OnChangeRegularCommunicationChannelsFTPUseFileSizeLimit()
	
	CommonClientServer.SetFormItemProperty(Items,
		"RegularCommunicationChannelsFTPMaxFileSize",
		"Enabled",
		RegularCommunicationChannelsFTPEnableFileSizeLimit);
	
EndProcedure

&AtClient
Procedure OnChangeRegularCommunicationChannelsEMAILUseAttachmentSizeLimit()
	
	CommonClientServer.SetFormItemProperty(Items,
		"RegularCommunicationChannelsMAILMaxAttachmentSize",
		"Enabled",
		RegularCommunicationChannelsEMAILEnableAttachmentSizeLimit);
	
EndProcedure

#EndRegion

#Region NavigationEventHandlers

&AtClient
Function Attachable_ConnectionSetupMethodPage_OnOpen(Cancel, SkipPage, IsMoveNext)
	
	Items.ConnectionSetupMethod.Visible = SaaSModel
		AND (AvailableTransportKinds.Property("WS") Or AvailableTransportKinds.Property("WSPassiveMode"));
		
	If IsMoveNext Then
		OnChangeConnectionSetupMethod();
	EndIf;
	
	Return Undefined;
	
EndFunction

&AtClient
Function Attachable_ConnectionSetupMethodPage_OnGoNext(Cancel)
	
	If ConnectionSetupMethod = "ApplicationFromList" Then
		
		CurrentData = Items.ApplicationsSaaS.CurrentData;
		If CurrentData = Undefined Then
			CommonClient.MessageToUser(
				NStr("ru = 'Выберите приложение из списка для продолжения настройки подключения.'; en = 'To continue the connection setup, select an application.'; pl = 'Wybierz aplikację z listy, aby kontynuować konfigurację połączenia.';de = 'Wählen Sie eine Anwendung aus der Liste aus, um die Konfiguration der Verbindung fortzusetzen.';ro = 'Selectați aplicația din listă pentru a continua setările de conectare.';tr = 'Bağlantı ayarlarına devam etmek için listeden bir uygulamayı seçin.'; es_ES = 'Seleccione una aplicación de la lista para seguir ajustando la conexión.'"),
				, "ApplicationsSaaS", , Cancel);
			Return Undefined;
		ElsIf CurrentData.SynchronizationSetupInServiceManager Then
			ShowMessageBox(, NStr("ru = 'Для настройки синхронизации данных с выбранным приложением перейдите в менеджер сервиса.
				|В менеджере сервиса воспользуйтесь командой ""Синхронизация данных"".'; 
				|en = 'To configure data synchronization with the selected application, open the service manager.
				|In the service manager, click ""Data synchronization"".'; 
				|pl = 'Dla ustawienia synchronizacji danych z wybranej aplikacji, przejdź do menedżera serwisu.
				|W menedżerze serwisu należy użyć polecenia ""Synchronizacja danych"".';
				|de = 'Um die Synchronisierung der Daten mit der ausgewählten Anwendung einzurichten, gehen Sie zum Service Manager.
				|Verwenden Sie im Service Manager den Befehl ""Datensynchronisation"".';
				|ro = 'Pentru a seta sincronizarea datelor cu aplicația dorită, mergeți la managerul de servicii.
				|În managerul de servicii utilizați comanda ""Sincronizarea datelor"".';
				|tr = 'Veri senkronizasyonunu ayarlamak için servis yöneticisine gidin. 
				|Servis yöneticisinde ""Veri Senkronizasyonu"" komutunu kullanın.'; 
				|es_ES = 'Para ajustar la sincronización de datos con la aplicación seleccionada pase al gestor de servicio,
				|En el gestor de servicio use el comando ""Sincronización de datos"".'"));
			Cancel = True;
			Return Undefined;
		Else
			AreaPrefix = CurrentData.Prefix;
			
			CorrespondentDescription   = CurrentData.ApplicationDescription;
			CorrespondentAreaPrefix = CurrentData.CorrespondentPrefix;
			
			CorrespondentEndpoint = CurrentData.CorrespondentEndpoint;
			CorrespondentDataArea = CurrentData.DataArea;
			
			ConnectionKind = "";
		EndIf;
		
	ElsIf ConnectionSetupMethod = "ConfigureManually" Then
		
		If ConnectionKind = "RegularCommunicationChannels"
			AND ImportConnectionParametersFromFile Then
			If IsBlankString(ConnectionSettingsFileNameToImport) Then
				CommonClient.MessageToUser(
					NStr("ru = 'Выберите файл с настройками подключения.'; en = 'Please select a file with connection settings.'; pl = 'Wybierz plik z ustawieniami połączenia.';de = 'Wählen Sie eine Datei mit Verbindungseinstellungen aus.';ro = 'Selectați fișierul cu setările de conectare.';tr = 'Bağlantı ayarlarına sahip bir dosya seçin.'; es_ES = 'Seleccione un archivo con ajustes de conexión.'"),
					, "ConnectionSettingsFileNameToImport", , Cancel);
				Return Undefined;
			EndIf;
		ElsIf ConnectionKind = "PassiveMode" Then
			If IsBlankString(XDTOCorrespondentSettingsFileName) Then
				CommonClient.MessageToUser(
					NStr("ru = 'Выберите файл с настройками программы-корреспондента.'; en = 'Please select a file with peer application settings.'; pl = 'Wybierz plik z ustawieniami programu-korespondenta.';de = 'Wählen Sie eine Datei mit den korrespondierenden Programmeinstellungen aus.';ro = 'Selectați fișierul cu setările aplicației-corespondente.';tr = 'Muhabir program ayarlarına sahip bir dosya seçin.'; es_ES = 'Seleccione un archivo con ajustes del programa-correspondiente.'"),
					, "XDTOCorrespondentSettingsFileName", , Cancel);
				Return Undefined;
			EndIf;
		EndIf;
		
	EndIf;
	
	Return Undefined;
	
EndFunction

&AtClient
Function Attachable_ConnectionParametersInternetPage_OnOpen(Cancel, SkipPage, IsMoveNext)
	
	If ConnectionKind <> "Internet" Then
		SkipPage = True;
		Return Undefined;
	EndIf;
	
	Items.InternetAccessParameters1.Visible = InternetAccessParametersSetupAvailable;
	
	Return Undefined;
	
EndFunction

&AtClient
Function Attachable_ConnectionParametersInternetPage_OnGoNext(Cancel)
	
	If ConnectionKind <> "Internet" Then
		Return Undefined;
	EndIf;
	
	If IsBlankString(InternetWebAddress) Then
		CommonClient.MessageToUser(
			NStr("ru = 'Укажите адрес программы в Интернет.'; en = 'Please enter the web application address.'; pl = 'Podaj adres aplikacji online.';de = 'Geben Sie eine Online-Anwendungsadresse an.';ro = 'Specificați o adresă de aplicație online.';tr = 'Çevrimiçi uygulama adresini belirtin.'; es_ES = 'Especificar una dirección online de la aplicación.'"),
			, "InternetWebAddress", , Cancel);
		Return Undefined;
	EndIf;
	
	Return Undefined;
	
EndFunction

&AtClient
Function Attachable_ConnectionParametersExternalConnectionPage_OnOpen(Cancel, SkipPage, IsMoveNext)
	
	If SaaSModel Then
		SkipPage = True;
	EndIf;
	
	If ConnectionKind <> "ExternalConnection" Then
		SkipPage = True;
	EndIf;
	
	OnChangeExternalConnectionInfobaseOperationMode();
	OnChangeExternalConnectionAuthenticationKind();
	
	Return Undefined;
	
EndFunction

&AtClient
Function Attachable_ConnectionParametersExternalConnectionPage_OnGoNext(Cancel)
	
	If ConnectionKind <> "ExternalConnection" Then
		Return Undefined;
	EndIf;
	
	If ExternalConnectionInfobaseOperationMode = "File" Then
		
		If IsBlankString(ExternalConnectionInfobaseDirectory) Then
			CommonClient.MessageToUser(
				NStr("ru = 'Выберите каталог расположения информационной базы.'; en = 'Please select an infobase directory.'; pl = 'Wybierz katalog lokalizacji bazy informacyjnej.';de = 'Wählen Sie das Verzeichnis des Informationsbasisstandortes aus.';ro = 'Selectați catalogul de amplasare a al bazei de date.';tr = 'Veri tabanın konum dizinini seçin.'; es_ES = 'Seleccione un catálogo de situación de la base de información.'"),
				, "ExternalConnectionInfobaseDirectory", , Cancel);
			Return Undefined;
		EndIf;
		
	ElsIf ExternalConnectionInfobaseOperationMode = "ClientServer" Then
		
		If IsBlankString(ExternalConnectionServerCluster) Then
			CommonClient.MessageToUser(
				NStr("ru = 'Укажите имя кластера серверов 1С:Предприятия.'; en = 'Please specify a 1C:Enterprise server cluster name.'; pl = 'Wprowadź nazwę klastra serwerów 1C:Enterprise.';de = 'Geben Sie den Namen des 1C:Enterprise Server-Clusters ein.';ro = 'Specificați numele clusterului serverelor 1C:Enterprise.';tr = '1C:İşletme sunucuların küme adını belirtin.'; es_ES = 'Indique el nombre de clúster de servidores de 1C:Enterprise.'"),
				, "ExternalConnectionServerCluster", , Cancel);
			Return Undefined;
		EndIf;
		
		If IsBlankString(ExternalConnectionInfobaseName) Then
			CommonClient.MessageToUser(
				NStr("ru = 'Укажите имя информационной базы в кластере серверов 1С:Предприятия.'; en = 'Please specify an infobase name in 1C:Enterprise server cluster.'; pl = 'Wprowadź nazwę bazy informacyjnej w klastrze serwerów 1C:Enterprise.';de = 'Geben Sie den Namen der Informationsbasis im 1C:Enterprise Server-Cluster ein.';ro = 'Indicați numele bazei de informații în clusterul serverelor 1C:Enterprise.';tr = '1C:İşletme sunucuların kümesindeki veritabanın adını belirtin.'; es_ES = 'Indique el nombre de la base de información en el clúster de servidores de 1C:Enterprise.'"),
				, "ExternalConnectionInfobaseName", , Cancel);
			Return Undefined;
		EndIf;
		
	EndIf;
	
	Return Undefined;
	
EndFunction

&AtClient
Function Attachable_ConnectionParametersRegularCommunicationChannelsPage_OnOpen(Cancel, SkipPage, IsMoveNext)
	
	If ConnectionKind <> "RegularCommunicationChannels" Then
		SkipPage = True;
		Return Undefined;
	EndIf;
	
	SetupAdditionalParameters = New Structure;
	SetupAdditionalParameters.Insert("IsMoveNext", IsMoveNext);
	ContinueSetupNotification = New NotifyDescription("ConnectionParametersRegularCommunicationChannelsContinueSetting",
		ThisObject, SetupAdditionalParameters);
	
	If IsMoveNext
		AND ImportConnectionParametersFromFile Then
		// Importing settings from the file.
		AdditionalParameters = New Structure;
		AdditionalParameters.Insert("Notification", ContinueSetupNotification);
		
		CompletionNotification = New NotifyDescription("OnCompletePutConnectionSettingsFileForImport", ThisObject, AdditionalParameters);
		BeginPutFile(CompletionNotification, , ConnectionSettingsFileNameToImport, False, UUID);
	Else
		Result = New Structure;
		Result.Insert("Cancel", False);
		Result.Insert("ErrorMessage", "");
		
		ExecuteNotifyProcessing(ContinueSetupNotification, Result);
	EndIf;
	
	Return Undefined;
	
EndFunction

&AtClient
Function Attachable_ConnectionParametersRegularCommunicationChannelsPage_OnGoNext(Cancel)
	
	If ConnectionKind <> "RegularCommunicationChannels" Then
		Return Undefined;
	EndIf;
	
	If Not RegularCommunicationChannelsFILEUsage
		AND Not RegularCommunicationChannelsFTPUsage
		AND Not RegularCommunicationChannelsEMAILUsage Then
		CommonClient.MessageToUser(
			NStr("ru = 'Выберите хотя бы один способ передачи файлов с данными.'; en = 'Please select at least one method of transferring data files.'; pl = 'Wybierz przynajmniej jeden sposób przesyłania plików z danymi.';de = 'Wählen Sie mindestens eine Möglichkeit zum Übertragen von Datendateien.';ro = 'Selectați cel puțin o metodă de trimitere a fișierelor cu datele.';tr = 'En az bir tane veri dosyasını aktarma yöntemini seçin.'; es_ES = 'Seleccione aunque sea un modo de pasar los archivos con los datos.'"),
			, "RegularCommunicationChannelsFILEUsage", , Cancel);
		Return Undefined;
	EndIf;
	
	If RegularCommunicationChannelsArchiveFiles
		AND RegularCommunicationChannelsProtectArchiveWithPassword
		AND IsBlankString(RegularCommunicationChannelsArchivePassword) Then
		CommonClient.MessageToUser(
			NStr("ru = 'Укажите пароль для архивации файлов.'; en = 'Please enter the archive password.'; pl = 'Wprowadź hasło dla archiwizacji plików.';de = 'Geben Sie ein Passwort für die Archivierung von Dateien an.';ro = 'Indicați parola pentru arhivarea datelor.';tr = 'Dosyaların arşivlenmesi için şifre belirtin.'; es_ES = 'Indique la contraseña para archivar los archivos.'"),
			, "RegularCommunicationChannelsArchivePassword", , Cancel);
		Return Undefined;
	EndIf;
	
	If RegularCommunicationChannelsFILEUsage Then
		
		If IsBlankString(RegularCommunicationChannelsFILEDirectory) Then
			CommonClient.MessageToUser(
				NStr("ru = 'Выберите каталог для передачи файлов с данными.'; en = 'Please select a file transfer directory.'; pl = 'Wybierz katalog, dla przesyłania plików z danymi.';de = 'Wählen Sie ein Verzeichnis aus, um die Datendateien zu übertragen.';ro = 'Selectați directorul pentru trimiterea fișierelor cu datele.';tr = 'Veri dosyaların aktarımı için bir dizin seçin.'; es_ES = 'Seleccione un catálogo para pasar los archivos con datos.'"),
				, "RegularCommunicationChannelsFILEDirectory", , Cancel);
			Return Undefined;
		EndIf;
		
	EndIf;
	
	If RegularCommunicationChannelsFTPUsage Then
		
		If IsBlankString(RegularCommunicationChannelsFTPPath) Then
			CommonClient.MessageToUser(
				NStr("ru = 'Укажите адрес каталога для передачи файлов с данными.'; en = 'Please specify a file transfer directory.'; pl = 'Wprowadź adres katalogu dla przesyłania plików z danymi.';de = 'Geben Sie die Adresse des Verzeichnisses für die Übertragung von Datendateien an.';ro = 'Indicați adresa directorului pentru trimiterea fișierelor cu datele.';tr = 'Veri dosyaların aktarımı için dizin adresini belirtin.'; es_ES = 'Indique una dirección del catálogo para pasar los archivos con los datos.'"),
				, "RegularCommunicationChannelsFTPPath", , Cancel);
			Return Undefined;
		EndIf;
		
		If RegularCommunicationChannelsFTPEnableFileSizeLimit
			AND Not ValueIsFilled(RegularCommunicationChannelsFTPMaxFileSize) Then
			CommonClient.MessageToUser(
				NStr("ru = 'Укажите максимальный допустимый размер файлов с данными.'; en = 'Please specify the file size limit.'; pl = 'Wprowadź maksymalnie dopuszczalny rozmiar plików z danymi.';de = 'Geben Sie die maximal zulässige Größe von Datendateien an.';ro = 'Indicați dimensiunea maximă admisibilă a fișierelor cu datele.';tr = 'Maksimum izin verilebilecek veri dosyasını belirtin.'; es_ES = 'Indique un tamaño máximo disponible de archivos con los datos.'"),
				, "RegularCommunicationChannelsFTPMaxFileSize", , Cancel);
			Return Undefined;
		EndIf;

	EndIf;
	
	If RegularCommunicationChannelsEMAILUsage Then
		
		If Not ValueIsFilled(RegularCommunicationChannelsMAILUserAccount) Then
			CommonClient.MessageToUser(
				NStr("ru = 'Выберите учетную запись электронной почты для отправки сообщений с данными.'; en = 'Please select an email account.'; pl = 'Wybierz konto e-mail do wysyłania wiadomości z danymi.';de = 'Wählen Sie ein E-Mail-Konto, um Datennachrichten zu senden.';ro = 'Selectați contul de e-mail pentru trimiterea mesajelor cu datele.';tr = 'Veri mesajların gönderilmesi için e-mail hesabını belirtin.'; es_ES = 'Seleccione una cuenta del correo electrónico para enviar los mensajes de datos.'"),
				, "RegularCommunicationChannelsMAILUserAccount", , Cancel);
			Return Undefined;
		EndIf;
		
		If RegularCommunicationChannelsEMAILEnableAttachmentSizeLimit
			AND Not ValueIsFilled(RegularCommunicationChannelsMAILMaxAttachmentSize) Then
			CommonClient.MessageToUser(
				NStr("ru = 'Укажите максимальный допустимый размер почтового вложения.'; en = 'Please specify the attachment size limit.'; pl = 'Wprowadź maksymalnie dopuszczalny rozmiar załącznika wiadomości e-mail.';de = 'Geben Sie die maximal zulässige Größe des E-Mail-Anhangs an.';ro = 'Indicați dimensiunea maximă admisibilă a atașamentului la e-mail.';tr = 'Maksimum izin verilen e-mail ekinin boyutunu belirtin.'; es_ES = 'Indique un tamaño máximo del archivo adjunto.'"),
				, "RegularCommunicationChannelsMAILMaxAttachmentSize", , Cancel);
			Return Undefined;
		EndIf;
		
	EndIf;
	
	Return Undefined;
	
EndFunction

&AtClient
Function Attachable_ConnectionTestPage_OnOpen(Cancel, SkipPage, IsMoveNext)
	
	If ConnectionKind = "PassiveMode" Then
		
		SkipPage = True;
		
	ElsIf ConnectionKind = "ExternalConnection"
		Or ConnectionKind = "Internet"
		Or SaaSModel Then
		
		Items.ConnectionCheckPanel.CurrentPage = Items.ConnectionCheckOnlinePage;
		
	ElsIf ConnectionKind = "RegularCommunicationChannels" Then
		
		Items.ConnectionCheckPanel.CurrentPage = Items.ConnectionCheckOfflinePage;
		
	EndIf;
	
	Return Undefined;
	
EndFunction

&AtClient
Function Attachable_ConnectionTestPage_TimeConsumingOperation(Cancel, GoToNext)
	
	GoToNext = False;
	
	If ConnectionKind = "PassiveMode" Then
		
		GoToNext = True;
		
	ElsIf ConnectionKind = "ExternalConnection"
		Or ConnectionKind = "Internet" Then
		
		If ConnectionKind = "ExternalConnection"
			AND CommonClient.FileInfobase() Then
			Notification = New NotifyDescription("RegisterCOMConnectorCompletion", ThisObject);
			CommonClient.RegisterCOMConnector(False, Notification);
		Else
			OnStartCheckConnectionOnline();
		EndIf;
		
	ElsIf SaaSModel Then
		
		OnStartConnectionCheckInSaaS();
		
	ElsIf ConnectionKind = "RegularCommunicationChannels" Then
		
		OnStartCheckConnectionOffline();
		
	EndIf;
	
	Return Undefined;
	
EndFunction

&AtClient
Function Attachable_CommonSynchronizationSettingsPage_OnOpen(Cancel, SkipPage, IsMoveNext)
	
	SetupAdditionalParameters = New Structure;
	SetupAdditionalParameters.Insert("IsMoveNext", IsMoveNext);
	ContinueSetupNotification = New NotifyDescription("CommonSynchronizationSettingsContinueSetting",
		ThisObject, SetupAdditionalParameters);
	
	If IsMoveNext
		AND ConnectionKind = "PassiveMode" Then
		// Importing correspondent settings from the file.
		AdditionalParameters = New Structure;
		AdditionalParameters.Insert("Notification", ContinueSetupNotification);
		
		CompletionNotification = New NotifyDescription("OnCompletePutXDTOCorrespondentSettingsFile", ThisObject, AdditionalParameters);
		BeginPutFile(CompletionNotification, , XDTOCorrespondentSettingsFileName, False, UUID);
	Else
		
		Result = New Structure;
		Result.Insert("Cancel", False);
		Result.Insert("ErrorMessage", "");
		
		ExecuteNotifyProcessing(ContinueSetupNotification, Result);
		
	EndIf;
	
	Return Undefined;
	
EndFunction

&AtClient
Function Attachable_CommonSynchronizationSettingsPage_OnGoNext(Cancel)
	
	If Not ConnectionKind = "PassiveMode" Then
	
		If DescriptionChangeAvailable
			AND IsBlankString(Description) Then
			CommonClient.MessageToUser(
				NStr("ru = 'Укажите наименование этой программы.'; en = 'Please specify the description of this application.'; pl = 'Podaj nazwę tej aplikacji.';de = 'Geben Sie diesen Anwendungsnamen an.';ro = 'Specificați numele acestei aplicații.';tr = 'Bu programın adını belirtin.'; es_ES = 'Especificar el nombre de esta aplicación.'"),
				, "Description", , Cancel);
		EndIf;
			
		If PrefixChangeAvailable
			AND IsBlankString(Prefix) Then
			CommonClient.MessageToUser(
				NStr("ru = 'Укажите префикс этой программы.'; en = 'Please specify the prefix for this application.'; pl = 'Wprowadź prefiks tego programu.';de = 'Geben Sie das Präfix dieses Programms an.';ro = 'Specificați prefixul acestei aplicații.';tr = 'Bu programın önekini belirtin.'; es_ES = 'Indique el prefijo de este programa.'"),
				, "Prefix", , Cancel);
		EndIf;
			
	EndIf;
	
	If CorrespondentDescriptionChangeAvailable
		AND IsBlankString(CorrespondentDescription) Then
		CommonClient.MessageToUser(
			NStr("ru = 'Укажите наименование программы-корреспондента.'; en = 'Please specify the description of the peer application.'; pl = 'Wprowadź nazwę programu-korespondenta.';de = 'Geben Sie den Namen des korrespondierenden Programms ein.';ro = 'Specificați numele aplicației-corespondente.';tr = 'Muhabir programın adını belirtin.'; es_ES = 'Indique el nombre del programa-correspondiente.'"),
			, "CorrespondentDescription", , Cancel);
	EndIf;
		
	If Not ConnectionKind = "PassiveMode" Then
	
		If CorrespondentPrefixChangeAvailable
			AND IsBlankString(CorrespondentPrefix) Then
			CommonClient.MessageToUser(
				NStr("ru = 'Укажите префикс программы-корреспондента.'; en = 'Please specify the peer application prefix.'; pl = 'Wprowadź prefiks programu-korespondenta.';de = 'Geben Sie das Präfix des korrespondierenden Programms ein.';ro = 'Specificați prefixul aplicației-corespondente.';tr = 'Muhabir programın önekini belirtin.'; es_ES = 'Indique el prefijo del programa-correspondiente.'"),
				, "CorrespondentPrefix", , Cancel);
		EndIf;
			
	EndIf;
	
	If SaveConnectionParametersToFile
		AND IsBlankString(ConnectionSettingsFileNameToExport) Then
		CommonClient.MessageToUser(
			NStr("ru = 'Укажите путь к файлу для сохранения настроек подключения.'; en = 'Please specify the path for saving the connection settings file.'; pl = 'Wprowadź ścieżkę do pliku, aby zapisać ustawienia połączenia.';de = 'Geben Sie den Pfad zur Datei an, um die Verbindungseinstellungen zu speichern.';ro = 'Indicați calea spre fișierul pentru salvarea setărilor de conectare.';tr = 'Bağlantı ayarlarını kaydetmek için dosya yolunu belirtin.'; es_ES = 'Indique la ruta al archivo para guardar los ajustes de conexión.'"),
			, "ConnectionSettingsFileNameToExport", , Cancel);
	EndIf;
	
	Return Undefined;
	
EndFunction

&AtClient
Function Attachable_SaveConnectionSettingsPage_TimeConsumingOperation(Cancel, GoToNext)
	
	GoToNext = False;
	OnStartSaveConnectionSettings();
	
	Return Undefined;
	
EndFunction

#EndRegion

#Region AdditionalNavigationHandlers

&AtClient
Procedure ChangeNavigationNumber(Iterator)
	
	ClearMessages();
	
	SetNavigationNumber(SwitchNumber + Iterator);
	
EndProcedure

&AtClient
Procedure SetNavigationNumber(Val Value)
	
	IsMoveNext = (Value > SwitchNumber);
	
	SwitchNumber = Value;
	
	If SwitchNumber < 1 Then
		
		SwitchNumber = 1;
		
	EndIf;
	
	NavigationNumberOnChange(IsMoveNext);
	
EndProcedure

&AtClient
Procedure NavigationNumberOnChange(Val IsMoveNext)
	
	// Executing navigation event handlers.
	ExecuteNavigationEventHandlers(IsMoveNext);
	
	// Setting page view.
	NavigationRowsCurrent = NavigationTable.FindRows(New Structure("SwitchNumber", SwitchNumber));
	
	If NavigationRowsCurrent.Count() = 0 Then
		Raise NStr("ru = 'Не определена страница для отображения.'; en = 'The page to display is not specified.'; pl = 'Strona do wyświetlenia nie jest zdefiniowana.';de = 'Die Seite für die Anzeige ist nicht definiert.';ro = 'Pagina pentru afișare nu este definită.';tr = 'Gösterilecek sayfa tanımlanmamış.'; es_ES = 'Página para visualizar no se ha definido.'");
	EndIf;
	
	NavigationRowCurrent = NavigationRowsCurrent[0];
	
	Items.MainPanel.CurrentPage  = Items[NavigationRowCurrent.MainPageName];
	Items.NavigationPanel.CurrentPage = Items[NavigationRowCurrent.NavigationPageName];
	
	Items.NavigationPanel.CurrentPage.Enabled = Not (IsMoveNext AND NavigationRowCurrent.TimeConsumingOperation);
	
	// Setting the default button.
	NextButton = GetFormButtonByCommandName(Items.NavigationPanel.CurrentPage, "NextCommand");
	
	If NextButton <> Undefined Then
		
		NextButton.DefaultButton = True;
		
	Else
		
		DoneButton = GetFormButtonByCommandName(Items.NavigationPanel.CurrentPage, "DoneCommand");
		
		If DoneButton <> Undefined Then
			
			DoneButton.DefaultButton = True;
			
		EndIf;
		
	EndIf;
	
	If IsMoveNext AND NavigationRowCurrent.TimeConsumingOperation Then
		
		AttachIdleHandler("ExecuteTimeConsumingOperationHandler", 0.1, True);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure ExecuteNavigationEventHandlers(Val IsMoveNext)
	
	// Navigation event handlers.
	If IsMoveNext Then
		
		NavigationRows = NavigationTable.FindRows(New Structure("SwitchNumber", SwitchNumber - 1));
		
		If NavigationRows.Count() > 0 Then
			NavigationRow = NavigationRows[0];
		
			// OnNavigationToNextPage handler.
			If Not IsBlankString(NavigationRow.OnSwitchToNextPageHandlerName)
				AND Not NavigationRow.TimeConsumingOperation Then
				
				ProcedureName = "Attachable_[HandlerName](Cancel)";
				ProcedureName = StrReplace(ProcedureName, "[HandlerName]", NavigationRow.OnSwitchToNextPageHandlerName);
				
				Cancel = False;
				
				Result = Eval(ProcedureName);
				
				If Cancel Then
					
					SetNavigationNumber(SwitchNumber - 1);
					
					Return;
					
				EndIf;
				
			EndIf;
		EndIf;
		
	Else
		
		NavigationRows = NavigationTable.FindRows(New Structure("SwitchNumber", SwitchNumber + 1));
		
		If NavigationRows.Count() > 0 Then
			NavigationRow = NavigationRows[0];
		
			// OnNavigationToPreviousPage handler.
			If Not IsBlankString(NavigationRow.OnSwitchToPreviousPageHandlerName)
				AND Not NavigationRow.TimeConsumingOperation Then
				
				ProcedureName = "Attachable_[HandlerName](Cancel)";
				ProcedureName = StrReplace(ProcedureName, "[HandlerName]", NavigationRow.OnSwitchToPreviousPageHandlerName);
				
				Cancel = False;
				
				Result = Eval(ProcedureName);
				
				If Cancel Then
					
					SetNavigationNumber(SwitchNumber + 1);
					
					Return;
					
				EndIf;
				
			EndIf;
		EndIf;
		
	EndIf;
	
	NavigationRowsCurrent = NavigationTable.FindRows(New Structure("SwitchNumber", SwitchNumber));
	
	If NavigationRowsCurrent.Count() = 0 Then
		Raise NStr("ru = 'Не определена страница для отображения.'; en = 'The page to display is not specified.'; pl = 'Strona do wyświetlenia nie jest zdefiniowana.';de = 'Die Seite für die Anzeige ist nicht definiert.';ro = 'Pagina pentru afișare nu este definită.';tr = 'Gösterilecek sayfa tanımlanmamış.'; es_ES = 'Página para visualizar no se ha definido.'");
	EndIf;
	
	NavigationRowCurrent = NavigationRowsCurrent[0];
	
	If NavigationRowCurrent.TimeConsumingOperation AND Not IsMoveNext Then
		
		SetNavigationNumber(SwitchNumber - 1);
		Return;
	EndIf;
	
	// OnOpen handler
	If Not IsBlankString(NavigationRowCurrent.OnOpenHandlerName) Then
		
		ProcedureName = "Attachable_[HandlerName](Cancel, SkipPage, IsMoveNext)";
		ProcedureName = StrReplace(ProcedureName, "[HandlerName]", NavigationRowCurrent.OnOpenHandlerName);
		
		Cancel = False;
		SkipPage = False;
		
		Result = Eval(ProcedureName);
		
		If Cancel Then
			
			SetNavigationNumber(SwitchNumber - 1);
			
			Return;
			
		ElsIf SkipPage Then
			
			If IsMoveNext Then
				
				SetNavigationNumber(SwitchNumber + 1);
				
				Return;
				
			Else
				
				SetNavigationNumber(SwitchNumber - 1);
				
				Return;
				
			EndIf;
			
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure ExecuteTimeConsumingOperationHandler()
	
	NavigationRowsCurrent = NavigationTable.FindRows(New Structure("SwitchNumber", SwitchNumber));
	
	If NavigationRowsCurrent.Count() = 0 Then
		Raise NStr("ru = 'Не определена страница для отображения.'; en = 'The page to display is not specified.'; pl = 'Strona do wyświetlenia nie jest zdefiniowana.';de = 'Die Seite für die Anzeige ist nicht definiert.';ro = 'Pagina pentru afișare nu este definită.';tr = 'Gösterilecek sayfa tanımlanmamış.'; es_ES = 'Página para visualizar no se ha definido.'");
	EndIf;
	
	NavigationRowCurrent = NavigationRowsCurrent[0];
	
	// TimeConsumingOperationProcessing handler.
	If Not IsBlankString(NavigationRowCurrent.TimeConsumingOperationHandlerName) Then
		
		ProcedureName = "Attachable_[HandlerName](Cancel, GoToNext)";
		ProcedureName = StrReplace(ProcedureName, "[HandlerName]", NavigationRowCurrent.TimeConsumingOperationHandlerName);
		
		Cancel = False;
		GoToNext = True;
		
		Result = Eval(ProcedureName);
		
		If Cancel Then
			
			SetNavigationNumber(SwitchNumber - 1);
			
			Return;
			
		ElsIf GoToNext Then
			
			SetNavigationNumber(SwitchNumber + 1);
			
			Return;
			
		EndIf;
		
	Else
		
		SetNavigationNumber(SwitchNumber + 1);
		
		Return;
		
	EndIf;
	
EndProcedure

&AtClient
Function GetFormButtonByCommandName(FormItem, CommandName)
	
	For Each Item In FormItem.ChildItems Do
		
		If TypeOf(Item) = Type("FormGroup") Then
			
			FormItemByCommandName = GetFormButtonByCommandName(Item, CommandName);
			
			If FormItemByCommandName <> Undefined Then
				
				Return FormItemByCommandName;
				
			EndIf;
			
		ElsIf TypeOf(Item) = Type("FormButton")
			AND StrFind(Item.CommandName, CommandName) > 0 Then
			
			Return Item;
			
		Else
			
			Continue;
			
		EndIf;
		
	EndDo;
	
	Return Undefined;
	
EndFunction

#EndRegion

#EndRegion