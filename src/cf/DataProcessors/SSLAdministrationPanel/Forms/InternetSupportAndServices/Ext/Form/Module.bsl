///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Variables

&AtClient
Var RefreshInterface;

#EndRegion

#Region EventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	IsSystemAdministrator   = Users.IsFullUser(, True);
	DataSeparationEnabled        = Common.DataSeparationEnabled();
	IsStandaloneWorkplace = Common.IsStandaloneWorkplace();
	
	If Common.SubsystemExists("StandardSubsystems.AddressClassifier") Then
		SettingsGroupVisibility = Not DataSeparationEnabled;
		If SettingsGroupVisibility Then
			If Common.SubsystemExists("OnlineUserSupport") Then
				ModuleOnlineUserSupport = Common.CommonModule("OnlineUserSupport");
				Items.AddressClassifierRightColumnGroup.Visible = 
					NOT ModuleOnlineUserSupport.AuthenticationDataOfOnlineSupportUserFilled();
				
			Else
				SettingsGroupVisibility = False;
			EndIf;
			
			ModuleAddressClassifierInternal = Common.CommonModule("AddressClassifierInternal");
			AddressInfoAvailabilityInfo = ModuleAddressClassifierInternal.AddressInfoAvailabilityInfo();
			AddressClassifierContainsImportedInfo = AddressInfoAvailabilityInfo.Get("UseImportedItems") = True;
			Items.InformationRegisterInformationRegisterClearAddressClassifier.Enabled = AddressClassifierContainsImportedInfo;
		EndIf;
		Items.AddressClassifierSettingsGroup.Visible = SettingsGroupVisibility;
	Else
		Items.AddressClassifierSettingsGroup.Visible = False;
	EndIf;
	
	Items.ClassifiersGroup.Visible = Not DataSeparationEnabled;
	
	If Common.SubsystemExists("StandardSubsystems.Banks")Then
		DataProcessorName = "ImportBankClassifier";
		Items.ImportBankClassifierGroup.Visible =
			  Not DataSeparationEnabled
			AND Not IsStandaloneWorkplace
			AND IsSystemAdministrator
			AND Metadata.DataProcessors.Find(DataProcessorName) <> Undefined;
	Else
		Items.ImportBankClassifierGroup.Visible = False;
	EndIf;
	
	If Common.SubsystemExists("StandardSubsystems.Currencies") Then
		Items.ExchangeRatesProcessingImportGroup.Visible =
			  Not DataSeparationEnabled
			AND Not IsStandaloneWorkplace;
	Else
		Items.ExchangeRatesProcessingImportGroup.Visible = False;
	EndIf;
	
	If Common.SubsystemExists("StandardSubsystems.ObjectPresentationDeclension") Then
		Items.DeclensionsGroup.Visible =
			  Not DataSeparationEnabled
			AND Not IsStandaloneWorkplace
			AND IsSystemAdministrator;
	Else
		Items.DeclensionsGroup.Visible = False;
	EndIf;
	
	If Common.SubsystemExists("StandardSubsystems.ContactOnlineSupport") Then
		Items.IntegrationOnlineSupportCallGroup.Visible =
			Common.IsWindowsClient();
	Else
		Items.IntegrationOnlineSupportCallGroup.Visible = False;
	EndIf;
	
	If Common.SubsystemExists("StandardSubsystems.MonitoringCenter") Then
		Items.MonitoringCenterGroup.Visible = IsSystemAdministrator;
		If IsSystemAdministrator Then
			MonitoringCenterParameters = GetMonitoringCenterParameters();
			MonitoringCenterAllowSendingData = GetDataSendingRadioButtons(MonitoringCenterParameters.EnableMonitoringCenter, MonitoringCenterParameters.ApplicationInformationProcessingCenter);
			
			ServiceParameters = New Structure("Server, ResourceAddress, Port");
			If MonitoringCenterAllowSendingData = 0 Then
				ServiceParameters.Server = MonitoringCenterParameters.DefaultServer;
				ServiceParameters.ResourceAddress = MonitoringCenterParameters.DefaultResourceAddress;
				ServiceParameters.Port = MonitoringCenterParameters.DefaultPort;
			ElsIf MonitoringCenterAllowSendingData = 1 Then
				ServiceParameters.Server = MonitoringCenterParameters.Server;
				ServiceParameters.ResourceAddress = MonitoringCenterParameters.ResourceAddress;
				ServiceParameters.Port = MonitoringCenterParameters.Port;
			ElsIf MonitoringCenterAllowSendingData = 2 Then
				ServiceParameters = Undefined;
			EndIf;
			
			If ServiceParameters <> Undefined Then
				If ServiceParameters.Port = 80 Then
					Schema = "http://";
					Port = "";
				ElsIf ServiceParameters.Port = 443 Then
					Schema = "https://";
					Port = "";
				Else
					Schema = "http://";
					Port = ":" + Format(ServiceParameters.Port, "NZ=0; NG=");
				EndIf;
				
				MonitoringCenterServiceAddress = Schema + ServiceParameters.Server + Port + "/" + ServiceParameters.ResourceAddress;
			Else
				MonitoringCenterServiceAddress = "";
			EndIf;
			
			Items.MonitoringCenterServiceAddress.Enabled = (MonitoringCenterAllowSendingData = 1);
			Items.MonitoringCenterSettings.Enabled = (MonitoringCenterAllowSendingData <> 2);
			Items.SendContactInformationGroup.Visible = MonitoringCenterParameters.ContactInformationRequest <> 2;
		EndIf;
	Else
		Items.MonitoringCenterGroup.Visible = False;
	EndIf;
	
	AddInsGroupVisibility = False;
	
	If Common.SubsystemExists("StandardSubsystems.AddIns") Then 
		
		ModuleAddInsInternal = Common.CommonModule("AddInsInternal");
		AddInsGroupVisibility = ModuleAddInsInternal.ImportFromPortalIsAvailable();
		
	EndIf;
	
	Items.AddInsGroup.Visible = AddInsGroupVisibility;
	
	// Update items states.
	SetAvailability();
	
	ProcessISLSettings = False;
	If Common.SubsystemExists("OnlineUserSupport") Then
		ModuleOnlineUserSupportClientServer =
			Common.CommonModule("OnlineUserSupportClientServer");
		ISLVersion = ModuleOnlineUserSupportClientServer.LibraryVersion();
		ProcessISLSettings = (CommonClientServer.CompareVersions(ISLVersion, "2.2.1.1") >= 0);
	EndIf;
	
	If ProcessISLSettings Then
		ModuleOnlineUserSupport = Common.CommonModule("OnlineUserSupport");
		ModuleOnlineUserSupport.InternetSupportAndServices_OnCreateAtServer(ThisObject);
	Else
		Items.ISLSettingsGroup.Visible                 = False;
		Items.ISLNewsGroup.Visible                   = False;
		Items.ISLApplicationUpdateGroup.Visible       = False;
		Items.ISLClassifiersUpdateGroup.Visible = False;
		Items.ISLCounterpartiesCheckGroup.Visible      = False;
		Items.ISL1CSPARKRisksGroup.Visible                = False;
	EndIf;
	
	ApplicationSettingsOverridable.OnlineSupportAndServicesOnCreateAtServer(ThisObject);
	
	Items.ConversationsGroup.Visible = Common.SubsystemExists("StandardSubsystems.Conversations");
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	OnChangeConversationsEnabledState();
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If EventName = "OnlineSupportEnabled" Then
		Items.AddressClassifierRightColumnGroup.Visible = False;
	ElsIf EventName = "OnlineSupportDisabled" Then
		Items.AddressClassifierRightColumnGroup.Visible = True;
	EndIf;
	
	If EventName = "AddressClassifierCleared" Or EventName = "AddressClassifierImported" Then
		Items.InformationRegisterInformationRegisterClearAddressClassifier.Enabled = (Parameter = True);
	EndIf;
	
	If EventName = "OnlineSupportDisabled" Or EventName = "OnlineSupportEnabled" Then
		RefreshReusableValues();
	EndIf;
	
	If ProcessISLSettings Then
		If CommonClient.SubsystemExists("OnlineUserSupport.CoreISL") Then
			ModuleOnlineUserSupportClient = CommonClient.CommonModule("OnlineUserSupportClient");
			ModuleOnlineUserSupportClient.OnlineSupportAndServices_NotificationProcessing(
				ThisObject,
				EventName,
				Parameter,
				Source);
		EndIf;
	EndIf;
	
	If EventName = "ConversationsEnabled" Then 
		OnChangeConversationsEnabledState(Parameter);
	EndIf;
	
EndProcedure

&AtClient
Procedure OnClose(Exit)
	If Exit Then
		Return;
	EndIf;
	UpdateApplicationInterface();
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure AllowDataSendingOnChange(Item)
	Var RunResult;
	Items.MonitoringCenterServiceAddress.Enabled = (MonitoringCenterAllowSendingData = 1);
	Items.MonitoringCenterSettings.Enabled = (MonitoringCenterAllowSendingData <> 2);
	If MonitoringCenterAllowSendingData = 2 Then
		MonitoringCenterParametersRecord = New Structure("EnableMonitoringCenter, ApplicationInformationProcessingCenter", False, False);
	ElsIf MonitoringCenterAllowSendingData = 1 Then
		MonitoringCenterParametersRecord = New Structure("EnableMonitoringCenter, ApplicationInformationProcessingCenter", False, True);
	ElsIf MonitoringCenterAllowSendingData = 0 Then
		MonitoringCenterParametersRecord = New Structure("EnableMonitoringCenter, ApplicationInformationProcessingCenter", True, False);
	EndIf;
	MonitoringCenterServiceAddress = GetServiceAddress();
	AllowDataSendingOnChangeAtServer(MonitoringCenterParametersRecord, RunResult);
	If RunResult <> Undefined Then
		MonitoringCenterJobID = RunResult.JobID;
		MonitoringCenterJobResultAddress = RunResult.ResultAddress;
		ModuleMonitoringCenterClient = CommonClient.CommonModule("MonitoringCenterClient");
		Notification = New NotifyDescription("AfterUpdateID", ModuleMonitoringCenterClient);
		IdleParameters = TimeConsumingOperationsClient.IdleParameters(ThisObject);
		IdleParameters.OutputIdleWindow = False;
		TimeConsumingOperationsClient.WaitForCompletion(RunResult, Notification, IdleParameters); 
	EndIf;
EndProcedure

&AtClient
Procedure MonitoringCenterServiceAddressOnChange(Item)
	Try
		AddressStructure = CommonClientServer.URIStructure(MonitoringCenterServiceAddress);
		
		If AddressStructure.Schema = "http" Then
			AddressStructure.Insert("SecureConnection", False);
		ElsIf AddressStructure.Schema = "https" Then
			AddressStructure.Insert("SecureConnection", True);
        Else
            AddressStructure.Insert("SecureConnection", False);
		EndIf;
		
		If NOT ValueIsFilled(AddressStructure.Port) Then
			If AddressStructure.Schema = "http" Then
				AddressStructure.Port = 80;
			ElsIf AddressStructure.Schema = "https" Then
				AddressStructure.Port = 443;
            Else
                AddressStructure.Port = 80;
			EndIf;
		EndIf;
	Except
		// Warning, the address format needs to comply with RFC 3986. See details of the CommonClientServer.
		// URIStructure function.
		ErrorDescription = NStr("ru = 'Адрес сервиса'; en = 'Service address'; pl = 'Adres serwisu';de = 'Service-Adresse';ro = 'Adresa serviciului';tr = 'Servis adı'; es_ES = 'Dirección del servicio'") + " "
			+ MonitoringCenterServiceAddress + " "
			+ NStr("ru = 'не является допустимым адресом веб-сервиса для отправки отчетов об использовании программы.'; en = 'is not a valid web service address for sending application usage reports.'; pl = 'nie jest prawidłowym adresem serwisu internetowego do wysyłania raportów na temat korzystania z programu.';de = 'ist keine gültige Webserviceadresse zum Senden von Berichten zur Verwendung des Programms.';ro = 'nu este adresă admisibilă a serviciului web pentru trimiterea rapoartelor despre utilizarea programului.';tr = 'program kullanım raporları göndermek için geçerli bir Web hizmeti adresi değildir.'; es_ES = 'no es dirección admitida del servicio web para enviar los informes del uso del programa.'"); 
		Raise(ErrorDescription);
	EndTry;
	
	MonitoringCenterServiceAddressOnChangeAtServer(AddressStructure);
EndProcedure

&AtClient
Procedure IntegrationOnlineSupportOnChange(Item)
	Attachable_OnChangeAttribute(Item);
EndProcedure

&AtClient
Procedure APIUsernameDecorationURLProcessing(Item, FormattedStringURL, StandardProcessing)
	
	ModuleOnlineUserSupportClient =
		CommonClient.CommonModule("OnlineUserSupportClient");
	ModuleOnlineUserSupportClient.OnlineSupportAndServices_URLProcessingDecoration(
		ThisObject,
		Item,
		FormattedStringURL,
		StandardProcessing);
	
EndProcedure

&AtClient
Procedure ISLEnableNewsManagerOnChange(Item)
	
	If CommonClient.SubsystemExists("OnlineUserSupport.News") Then
		ModuleNewsProcessingClient = CommonClient.CommonModule("NewsProcessingClient");
		ModuleNewsProcessingClient.OnlineSupportAndServices_EnableNewsOperationsOnChange(
			ThisObject,
			Item);
		RefreshInterface = True;
		AttachIdleHandler("UpdateApplicationInterface", 2, True);
	EndIf;
	
EndProcedure

&AtClient
Procedure ISLUse1CSPARKRisksServiceOnChange(Item)
	
	If CommonClient.SubsystemExists("OnlineUserSupport.SPARKRisks") Then
		Module1CSPARKRisksClient = CommonClient.CommonModule("SPARKRisksClient");
		Module1CSPARKRisksClient.OnlineSupportAndServices_RunSPARKRisksServiceOnCHange(
			ThisObject,
			Item);
		RefreshInterface = True;
		AttachIdleHandler("UpdateApplicationInterface", 2, True);
	EndIf;
	
EndProcedure

&AtClient
Procedure AutomaticUpdatesCheckOnChange(Item)
	
	If CommonClient.SubsystemExists("OnlineUserSupport.GetApplicationUpdates") Then
		ModuleGetApplicationUpdatesClient =
			CommonClient.CommonModule("GetApplicationUpdatesClient");
		ModuleGetApplicationUpdatesClient.OnlineSupportAndServices_AutomaticUpdatesCheckOnChange(
			ThisObject,
			Item);
	EndIf;
	
EndProcedure

&AtClient
Procedure UpdatesCheckScheduleDecorationClick(Item)
	
	If CommonClient.SubsystemExists("OnlineUserSupport.GetApplicationUpdates") Then
		ModuleGetApplicationUpdatesClient =
			CommonClient.CommonModule("GetApplicationUpdatesClient");
		ModuleGetApplicationUpdatesClient.OnlineSupportAndServices_DecorationUpdatesCheckScheduleClick(
			ThisObject,
			Item);
	EndIf;
	
EndProcedure

&AtClient
Procedure PlatformDistributionPackageDirectoryClick(Item, StandardProcessing)
	
	ModuleGetApplicationUpdatesClient =
		CommonClient.CommonModule("GetApplicationUpdatesClient");
	ModuleGetApplicationUpdatesClient.OnlineSupportAndServices_PlatformDistributionPackageDirectoryClick(
		ThisObject,
		Item,
		StandardProcessing);
	
EndProcedure

&AtClient
Procedure ItemizeIBUpdateInEventLogOnChange(Item)
	Attachable_OnChangeAttribute(Item);
EndProcedure

&AtClient
Procedure ISLDownloadAndInstallPatchesAutomaticallyOnChange(Item)
	
	ModuleGetApplicationUpdatesClient =
		CommonClient.CommonModule("GetApplicationUpdatesClient");
	ModuleGetApplicationUpdatesClient.OnlineSupportAndServices_ImportAndInstallPatchesAutomaticallyOnChange(
		ThisObject,
		Item);
	
EndProcedure

&AtClient
Procedure ScheduleDecorationInstallPatchesClick(Item)
	
	ModuleGetApplicationUpdatesClient =
		CommonClient.CommonModule("GetApplicationUpdatesClient");
	ModuleGetApplicationUpdatesClient.OnlineSupportAndServices_PatchesInstallationScheduleDecorationClick(
		ThisObject,
		Item);
	
EndProcedure

#EndRegion

#Region FormCommandHandlers

// StandardSubsystems.IBVersionUpdate
&AtClient
Procedure DeferredDataProcessing(Command)
	
	FormParameters = New Structure("OpenedFromAdministrationPanel", True);
	OpenForm(
		"DataProcessor.ApplicationUpdateResult.Form.DeferredIBUpdateProgressIndicator",
		FormParameters);
	
EndProcedure
// End StandardSubsystems.IBVersionUpdate

&AtClient
Procedure ISLSignInOrSignOut(Command)
	
	If CommonClient.SubsystemExists("OnlineUserSupport.CoreISL") Then
		ModuleOnlineUserSupportClient =
			CommonClient.CommonModule("OnlineUserSupportClient");
		ModuleOnlineUserSupportClient.OnlineSupportAndServices_SignInOtSignOutISL(
			ThisObject,
			Command);
	EndIf;
	
EndProcedure

&AtClient
Procedure ISLMessageToTechnicalSupport(Command)
	
	If CommonClient.SubsystemExists("OnlineUserSupport.CoreISL") Then
		ModuleOnlineUserSupportClient = CommonClient.CommonModule("OnlineUserSupportClient");
		ModuleOnlineUserSupportClient.OnlineSupportAndServices_MessageToTechnicalSupport(
			ThisObject,
			Command);
	EndIf;
	
EndProcedure

&AtClient
Procedure ISLOnlineSupportDashboard(Command)
	
	If CommonClient.SubsystemExists("OnlineUserSupport.OneCITSPortalDashboard") Then
		Module1CITSPortalMonitorClient = CommonClient.CommonModule("1CITSPortalDashboardClient");
		Module1CITSPortalMonitorClient.OnlineSupportAndServices_1CITSPortalDashboard(
			ThisObject,
			Command);
	EndIf;
	
EndProcedure

&AtClient
Procedure ISLNewsManagement(Command)
	
	If CommonClient.SubsystemExists("OnlineUserSupport.News") Then
		ModuleNewsProcessingClient = CommonClient.CommonModule("NewsProcessingClient");
		ModuleNewsProcessingClient.OnlineSupportAndServices_NewsManagement(
			ThisObject,
			Command);
	EndIf;
	
EndProcedure

&AtClient
Procedure ISLApplicationUpdate(Command)
	
	If CommonClient.SubsystemExists("OnlineUserSupport.GetApplicationUpdates") Then
		ModuleGetApplicationUpdatesClient = CommonClient.CommonModule("GetApplicationUpdatesClient");
		ModuleGetApplicationUpdatesClient.OnlineSupportAndServices_ApplicationUpdate(
			ThisObject,
			Command);
	EndIf;
	
EndProcedure

&AtClient
Procedure ISLClassifiersUpdate(Command)
	
	If CommonClient.SubsystemExists("OnlineUserSupport.ClassifiersOperations") Then
		ModuleGetClassifiersOperationsClient = CommonClient.CommonModule("ClassifiersOperationsClient");
		ModuleGetClassifiersOperationsClient.OnlineSupportAndServices_ClassifiersUpdate(
			ThisObject,
			Command);
	EndIf;
	
EndProcedure

&AtClient
Procedure ISLUseCounterpartiesCheckOnChange(Item)
	
	If CommonClient.SubsystemExists("OnlineUserSupport.CounterpartiesFunctions") Then
		ModuleCounterpartiesManagerClient =
			CommonClient.CommonModule("CounterpartyFunctionsClient");
		ModuleCounterpartiesManagerClient.OnlineSupportAndServices_UseCounterpartiesCheckOnChange(
			ThisObject,
			Item);
		RefreshInterface = True;
		AttachIdleHandler("UpdateApplicationInterface", 2, True);
	EndIf;
	
EndProcedure

&AtClient
Procedure ISLCounterpartiesCheckCheckAccessToWebService(Command)
	
	If CommonClient.SubsystemExists("OnlineUserSupport.CounterpartiesFunctions") Then
		ModuleCounterpartiesManagerClient = CommonClient.CommonModule("CounterpartyFunctionsClient");
		ModuleCounterpartiesManagerClient.OnlineSupportAndServices_ISLCounterpartiesCheckWebServiceAccessCheck(
			ThisObject,
			Command);
	EndIf;
	
EndProcedure

&AtClient
Procedure EnableDisableConversations(Command)
	
	If CommonClient.SubsystemExists("StandardSubsystems.Conversations") Then
		
		ModuleConversationsServiceClient = CommonClient.CommonModule("ConversationsServiceClient");
		
		If ModuleConversationsServiceClient.Connected() Then
			ModuleConversationsServiceClient.ShowDisconnection();
		Else 
			ModuleConversationsServiceClient.ShowConnection();
		EndIf;
		
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

#Region PrivateEventHandlers

&AtClient
Procedure OnChangeConversationsEnabledState(ConversationsEnabled = Undefined)
	
	If CommonClient.SubsystemExists("StandardSubsystems.Conversations") Then
		
		If ConversationsEnabled = Undefined Then 
			ModuleConversationsServiceClient = CommonClient.CommonModule("ConversationsServiceClient");
			ConversationsEnabled = ModuleConversationsServiceClient.Connected();
		EndIf;
		
		If ConversationsEnabled Then 
			Items.EnableDisableConversations.Title = NStr("ru = 'Отключить'; en = 'Disable'; pl = 'Wyłącz';de = 'Deaktivieren';ro = 'Dezactivare';tr = 'Devre dışı bırak'; es_ES = 'Desactivar'");
			Items.ConversationsEnabledState.Title = NStr("ru = 'Обсуждения подключены.'; en = 'Conversations are enabled.'; pl = 'Dyskusje są podłączone.';de = 'Diskussionen sind verbunden.';ro = 'Conversațiile sunt conectate.';tr = 'Tartışmalar bağlı.'; es_ES = 'Conversaciones activadas.'");
		Else 
			Items.EnableDisableConversations.Title = NStr("ru = 'Подключить'; en = 'Enable'; pl = 'Połącz';de = 'Verbinden';ro = 'Conectare';tr = 'Bağla'; es_ES = 'Conectar'");
			Items.ConversationsEnabledState.Title = NStr("ru = 'Подключение обсуждений не выполнено.'; en = 'Conversations are disabled.'; pl = 'Konwersacje są wyłączone.';de = 'Gespräche sind deaktiviert.';ro = 'Conversațiile sunt dezactivate.';tr = 'Konuşmalar devre dışı.'; es_ES = 'Conversaciones deshabilitadas.'");
		EndIf;
		
	EndIf;
	
EndProcedure

#EndRegion

////////////////////////////////////////////////////////////////////////////////
// Client

&AtClient
Procedure Attachable_OnChangeAttribute(Item, InterfaceUpdateIsRequired = True)
	
	ConstantName = OnChangeAttributeServer(Item.Name);
	
	RefreshReusableValues();
	
	If InterfaceUpdateIsRequired Then
		RefreshInterface = True;
		AttachIdleHandler("UpdateApplicationInterface", 2, True);
	EndIf;
	
	If ConstantName <> "" Then
		Notify("Write_ConstantsSet", New Structure, ConstantName);
	EndIf;
	
EndProcedure

&AtClient
Procedure UpdateApplicationInterface()
	
	If RefreshInterface = True Then
		RefreshInterface = False;
		CommonClient.RefreshApplicationInterface();
	EndIf;
	
EndProcedure

&AtClient
Function GetServiceAddress()
	
	MonitoringCenterParameters = GetMonitoringCenterParameters();
			
	ServiceParameters = New Structure("Server, ResourceAddress, Port");
	
	If MonitoringCenterAllowSendingData = 0 Then
		ServiceParameters.Server = MonitoringCenterParameters.DefaultServer;
		ServiceParameters.ResourceAddress = MonitoringCenterParameters.DefaultResourceAddress;
		ServiceParameters.Port = MonitoringCenterParameters.DefaultPort;
	ElsIf MonitoringCenterAllowSendingData = 1 Then
		ServiceParameters.Server = MonitoringCenterParameters.Server;
		ServiceParameters.ResourceAddress = MonitoringCenterParameters.ResourceAddress;
		ServiceParameters.Port = MonitoringCenterParameters.Port;
	ElsIf MonitoringCenterAllowSendingData = 2 Then
		ServiceParameters = Undefined;	
	EndIf;
	
	If ServiceParameters <> Undefined Then
		If ServiceParameters.Port = 80 Then
			Schema = "http://";
			Port = "";
		ElsIf ServiceParameters.Port = 443 Then
			Schema = "https://";
			Port = "";
		Else
			Schema = "http://";
			Port = ":" + Format(ServiceParameters.Port, "NZ=0; NG=");
		EndIf;
		
		ServiceAddress = Schema + ServiceParameters.Server + Port + "/" + ServiceParameters.ResourceAddress;
	Else
		ServiceAddress = "";
	EndIf;
	
	Return ServiceAddress;
EndFunction

////////////////////////////////////////////////////////////////////////////////
// Server call

&AtServer
Function OnChangeAttributeServer(ItemName)
	
	DataPathAttribute = Items[ItemName].DataPath;
	
	ConstantName = SaveAttributeValue(DataPathAttribute);
	
	SetAvailability(DataPathAttribute);
	
	If ItemName = "UseMorpherDeclinationService"
		AND Common.SubsystemExists("StandardSubsystems.ObjectPresentationDeclension") Then
		ModuleObjectsPresentationsDeclension = Common.CommonModule("ObjectPresentationDeclension");
		ModuleObjectsPresentationsDeclension.SetDeclensionServiceAvailability(True);
	EndIf;
	
	RefreshReusableValues();
	
	Return ConstantName;
	
EndFunction

////////////////////////////////////////////////////////////////////////////////
// Server

&AtServer
Procedure SetAvailability(DataPathAttribute = "")
	
	If Not Users.IsFullUser(, True) Then
		Return;
	EndIf;
	
	If (DataPathAttribute = "ConstantsSet.UseOnlineSupport" Or DataPathAttribute = "")
		AND Common.SubsystemExists("StandardSubsystems.ContactOnlineSupport") Then
		Items.OnlineSupportSettingGroup.Enabled = ConstantsSet.UseOnlineSupport;
	EndIf;
	
	If (DataPathAttribute = "ConstantsSet.UseMorpherDeclinationService" Or DataPathAttribute = "")
		AND Common.SubsystemExists("StandardSubsystems.ObjectPresentationDeclension") Then
		
		CommonClientServer.SetFormItemProperty(
			Items, "InflectionSettingsGroup", "Enabled",
			ConstantsSet.UseMorpherDeclinationService);
			
	EndIf;
	
EndProcedure

&AtServer
Function SaveAttributeValue(DataPathAttribute)
	
	NameParts = StrSplit(DataPathAttribute, ".");
	If NameParts.Count() <> 2 Then
		Return "";
	EndIf;
	
	ConstantName = NameParts[1];
	ConstantManager = Constants[ConstantName];
	ConstantValue = ConstantsSet[ConstantName];
	
	If ConstantManager.Get() <> ConstantValue Then
		ConstantManager.Set(ConstantValue);
	EndIf;
	
	Return ConstantName;
	
EndFunction

&AtServerNoContext
Function GetDataSendingRadioButtons(EnableMonitoringCenter, ApplicationInformationProcessingCenter)
	State = ?(EnableMonitoringCenter, "1", "0") + ?(ApplicationInformationProcessingCenter, "1", "0");
	
	If State = "00" Then
		Result = 2;
	ElsIf State = "01" Then
		Result = 1;
	ElsIf State = "10" Then
		Result = 0;
	ElsIf State = "11" Then
		// But this cannot happen...
	EndIf;
	
	Return Result;
EndFunction

&AtServerNoContext
Function GetMonitoringCenterParameters()
	ModuleMonitoringCenterInternal = Common.CommonModule("MonitoringCenterInternal");
	MonitoringCenterParameters = ModuleMonitoringCenterInternal.GetMonitoringCenterParametersExternalCall();
	
	DefaultServiceParameters = ModuleMonitoringCenterInternal.GetDefaultParametersExternalCall();
	MonitoringCenterParameters.Insert("DefaultServer", DefaultServiceParameters.Server);
	MonitoringCenterParameters.Insert("DefaultResourceAddress", DefaultServiceParameters.ResourceAddress);
	MonitoringCenterParameters.Insert("DefaultPort", DefaultServiceParameters.Port);
	
	Return MonitoringCenterParameters;
EndFunction

&AtServerNoContext
Procedure AllowDataSendingOnChangeAtServer(MonitoringCenterParameters, RunResult)
	ModuleMonitoringCenterInternal = Common.CommonModule("MonitoringCenterInternal");
	ModuleMonitoringCenterInternal.SetMonitoringCenterParametersExternalCall(MonitoringCenterParameters);
	
	EnableMonitoringCenter = MonitoringCenterParameters.EnableMonitoringCenter;
	ApplicationInformationProcessingCenter = MonitoringCenterParameters.ApplicationInformationProcessingCenter;
	
	Result = GetDataSendingRadioButtons(EnableMonitoringCenter, ApplicationInformationProcessingCenter);
	
	If Result = 0 Or Result = 1 Then
		// Send a discovery package.
		RunResult = ModuleMonitoringCenterInternal.StartDiscoveryPackageSending();
	EndIf;
	
	If Result = 0 Then
		// Enable a job of collecting and sending statistics.
		ScheduledJob = ModuleMonitoringCenterInternal.GetScheduledJobExternalCall("StatisticsDataCollectionAndSending", True);
		ModuleMonitoringCenterInternal.SetDefaultScheduleExternalCall(ScheduledJob);
	ElsIf Result = 1 Then
		ScheduledJob = ModuleMonitoringCenterInternal.GetScheduledJobExternalCall("StatisticsDataCollectionAndSending", True);
		ModuleMonitoringCenterInternal.SetDefaultScheduleExternalCall(ScheduledJob);
	ElsIf Result = 2 Then
		ModuleMonitoringCenterInternal.DeleteScheduledJobExternalCall("StatisticsDataCollectionAndSending");
	EndIf;
EndProcedure

&AtServerNoContext
Procedure MonitoringCenterServiceAddressOnChangeAtServer(AddressStructure)
	MonitoringCenterParameters = New Structure();
	MonitoringCenterParameters.Insert("Server", AddressStructure.Host);
	MonitoringCenterParameters.Insert("ResourceAddress", AddressStructure.PathAtServer);
	MonitoringCenterParameters.Insert("Port", AddressStructure.Port);
	MonitoringCenterParameters.Insert("SecureConnection", AddressStructure.SecureConnection);
	
	ModuleMonitoringCenterInternal = Common.CommonModule("MonitoringCenterInternal");
	ModuleMonitoringCenterInternal.SetMonitoringCenterParametersExternalCall(MonitoringCenterParameters);
EndProcedure

#EndRegion
