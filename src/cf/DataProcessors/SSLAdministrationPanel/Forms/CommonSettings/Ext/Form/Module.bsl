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
	
	ApplicationTimeZone = GetInfoBaseTimeZone();
	If IsBlankString(ApplicationTimeZone) Then
		ApplicationTimeZone = TimeZone();
	EndIf;
	Items.ApplicationTimeZone.ChoiceList.LoadValues(GetAvailableTimeZones());
	
	If Common.SubsystemExists("StandardSubsystems.SecurityProfiles") Then
		ModuleSafeModeManagerInternal = Common.CommonModule("SafeModeManagerInternal");
		
		Items.ConfigureSecurityProfilesUsageGroup.Visible =
			  Users.IsFullUser(, True)
			AND ModuleSafeModeManagerInternal.CanSetUpSecurityProfiles();
	Else
		Items.ConfigureSecurityProfilesUsageGroup.Visible = False;
	EndIf;
	
	If Common.SubsystemExists("StandardSubsystems.GetFilesFromInternet") Then
		Items.OpenProxyServerParametersGroup.Visible =
			  Users.IsFullUser(, True)
			AND Not Common.FileInfobase();
	Else
		Items.OpenProxyServerParametersGroup.Visible = False;
	EndIf;
	
	If Not Common.SubsystemExists("StandardSubsystems.DigitalSignature") Then
		Items.DigitalSignatureAndEncryptionGroup.Visible = False;
	EndIf;
	
	If Not Common.SubsystemExists("StandardSubsystems.Properties") Then
		Items.AdditionalAttributesAndDataGroup.Visible = False;
	EndIf;
	
	If Not Common.SubsystemExists("StandardSubsystems.ObjectsVersioning") Then
		Items.VersioningGroup.Visible = False;
	EndIf;
	
	Items.InfobasePublishingGroup.Visible = Not (Common.DataSeparationEnabled() 
		Or Common.IsStandaloneWorkplace());
	
	SetAvailability();
	
	ApplicationSettingsOverridable.CommonSettingsOnCreateAtServer(ThisObject);
	
	If Common.SubsystemExists("StandardSubsystems.ObjectsVersioning") Then
		ModuleObjectsVersioning = Common.CommonModule("ObjectsVersioning");
		StoreChangeHistory = ModuleObjectsVersioning.StoreHistoryCheckBoxValue();
	Else 
		Items.VersioningGroup.Visible = False;
	EndIf;
	
	If Common.SubsystemExists("StandardSubsystems.FullTextSearch") 
		AND Users.IsFullUser(, True) Then
		
		ModuleFullTextSearchServer = Common.CommonModule("FullTextSearchServer");
		UseFullTextSearch = ModuleFullTextSearchServer.UseSearchFlagValue();
	Else
		Items.FullTextSearchManagementGroup.Visible = False;
	EndIf;
	
EndProcedure

&AtClient
Procedure OnClose(Exit)
	If Exit Then
		Return;
	EndIf;
	UpdateApplicationInterface();
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If CommonClient.SubsystemExists("StandardSubsystems.ObjectsVersioning") Then
		ModuleObjectsVersioningClient = CommonClient.CommonModule("ObjectsVersioningClient");
		ModuleObjectsVersioningClient.StoreHistoryCheckBoxChangeNotificationProcessing(
			EventName, 
			StoreChangeHistory);
	EndIf;
	
	If CommonClient.SubsystemExists("StandardSubsystems.FullTextSearch") Then
		ModuleFullTextSearchClient = CommonClient.CommonModule("FullTextSearchClient");
		ModuleFullTextSearchClient.UseSearchFlagChangeNotificationProcessing(
			EventName, 
			UseFullTextSearch);
	EndIf;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure ApplicationTitleOnChange(Item)
	Attachable_OnChangeAttribute(Item);
	StandardSubsystemsClient.SetAdvancedApplicationCaption();
EndProcedure

&AtClient
Procedure ApplicationTimeZoneOnChange(Item)
	Attachable_OnChangeAttribute(Item);
EndProcedure

&AtClient
Procedure UseAdditionalAttributesAndInfoOnChange(Item)
	Attachable_OnChangeAttribute(Item);
EndProcedure

&AtClient
Procedure InfobasePublicationURLOnChange(Item)
	
	Attachable_OnChangeAttribute(Item);
	
EndProcedure

&AtClient
Procedure InfobasePublicationURLStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	AttachIdleHandler("InfobasePublicationURLStartChoiceFollowUp", 0.1, True);
	
EndProcedure

&AtClient
Procedure LocalInfobasePublicationURLStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	AttachIdleHandler("LocalInfobasePublicationURLStartChoiceFollowUp", 0.1, True);
	
EndProcedure

&AtClient
Procedure StoreChangesHistoryOnChange(Item)
	
	If CommonClient.SubsystemExists("StandardSubsystems.ObjectsVersioning") Then
		ModuleObjectsVersioningClient = CommonClient.CommonModule("ObjectsVersioningClient");
		ModuleObjectsVersioningClient.OnStoreHistoryCheckBoxChange(StoreChangeHistory);
	EndIf;
	
EndProcedure

&AtClient
Procedure UseFullTextSearchOnChange(Item)
	
	If CommonClient.SubsystemExists("StandardSubsystems.FullTextSearch") Then
		ModuleFullTextSearchClient = CommonClient.CommonModule("FullTextSearchClient");
		ModuleFullTextSearchClient.OnChangeUseSearchFlag(UseFullTextSearch);
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandHandlers

&AtClient
Procedure SecurityProfilesUsage(Command)
	
	If CommonClient.SubsystemExists("StandardSubsystems.SecurityProfiles") Then
		ModuleSafeModeManagerClient = CommonClient.CommonModule("SafeModeManagerClient");
		ModuleSafeModeManagerClient.OpenSecurityProfileSetupDialog();
	EndIf;
	
EndProcedure

&AtClient
Procedure ConfigureChangesHistoryStorage(Command)
	
	If CommonClient.SubsystemExists("StandardSubsystems.ObjectsVersioning") Then
		ModuleObjectsVersioningClient = CommonClient.CommonModule("ObjectsVersioningClient");
		ModuleObjectsVersioningClient.ShowSetting();
	EndIf;
	
EndProcedure

&AtClient
Procedure ConfigureFullTextSearch(Command)
	
	If CommonClient.SubsystemExists("StandardSubsystems.FullTextSearch") Then
		ModuleFullTextSearchClient = CommonClient.CommonModule("FullTextSearchClient");
		ModuleFullTextSearchClient.ShowSetting();
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure InfobasePublicationURLStartChoiceFollowUp()
	
	InfobasePublicationURLStartChoiceCompletion("InfobasePublicationURL");
	
EndProcedure

&AtClient
Procedure LocalInfobasePublicationURLStartChoiceFollowUp()
	
	InfobasePublicationURLStartChoiceCompletion("LocalInfobasePublishingURL");
	
EndProcedure

&AtClient
Procedure InfobasePublicationURLStartChoiceCompletion(AttributeName)
	
	If CommonClient.ClientConnectedOverWebServer() Then
		InfobasePublicationURLStartChoiceAtServer(AttributeName, InfoBaseConnectionString());
		Attachable_OnChangeAttribute(Items[AttributeName]);
	Else
		ShowMessageBox(, NStr("ru = 'Не удалось автоматически заполнить поле, т.к. клиентское приложение не подключено через веб-сервер.'; en = 'Cannot populate the field as the client application is not connected over a web server.'; pl = 'Nie można automatycznie wypełnić pola, ponieważ aplikacja kliencka nie jest podłączona przez serwer internetowy.';de = 'Es war nicht möglich, das Feld automatisch auszufüllen, da die Client-Anwendung nicht über den Webserver verbunden ist.';ro = 'Eșec la completarea automată a câmpului, deoarece aplicația de client nu este conectată prin serverul web.';tr = 'İstemci uygulaması Web sunucusu üzerinden bağlı olmadığından alan otomatik olarak doldurulamadı.'; es_ES = 'No se ha podido rellenar automáticamente el campo porque la aplicación de cliente no está activado a través del servidor web.'"));
	EndIf;
	
EndProcedure

&AtServer
Procedure InfobasePublicationURLStartChoiceAtServer(AttributeName, ConnectionString)
	
	ConnectionParameters = StringFunctionsClientServer.ParametersFromString(ConnectionString);
	If ConnectionParameters.Property("WS") Then
		ConstantsSet[AttributeName] = ConnectionParameters.WS;
	EndIf;
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Client

&AtClient
Procedure Attachable_OnChangeAttribute(Item, UpdateInterface = True)
	
	ConstantName = OnChangeAttributeServer(Item.Name);
	
	RefreshReusableValues();
	
	If UpdateInterface Then
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

////////////////////////////////////////////////////////////////////////////////
// Server call

&AtServer
Function OnChangeAttributeServer(ItemName)
	
	DataPathAttribute = Items[ItemName].DataPath;
	
	ConstantName = SaveAttributeValue(DataPathAttribute);
	
	SetAvailability(DataPathAttribute);
	
	RefreshReusableValues();
	
	Return ConstantName;
	
EndFunction

////////////////////////////////////////////////////////////////////////////////
// Server

&AtServer
Function SaveAttributeValue(DataPathAttribute)
	
	// Saving values of attributes not directly related to constants (in ratio one to one).
	If DataPathAttribute = "ApplicationTimeZone" Then
		If ApplicationTimeZone <> GetInfoBaseTimeZone() Then 
			SetPrivilegedMode(True);
			Try
				SetExclusiveMode(True);
				SetInfoBaseTimeZone(ApplicationTimeZone);
				SetExclusiveMode(False);
			Except
				SetExclusiveMode(False);
				Raise;
			EndTry;
			SetPrivilegedMode(False);
			SetSessionTimeZone(ApplicationTimeZone);
		EndIf;
		Return "";
	EndIf;
	
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
	
	If ConstantName = "UseAdditionalAttributesAndInfo" AND ConstantValue = False Then
		ThisObject.Read();
	EndIf;
	
	Return ConstantName;
	
EndFunction

&AtServer
Procedure SetAvailability(DataPathAttribute = "")
	
	If (DataPathAttribute = "ConstantsSet.UseAdditionalAttributesAndInfo" Or DataPathAttribute = "")
		AND Common.SubsystemExists("StandardSubsystems.Properties") Then
		
		CommonClientServer.SetFormItemProperty(
			Items, "AdditionalAttributesAndInfoOtherSettingsGroup",
			"Enabled", ConstantsSet.UseAdditionalAttributesAndInfo);
		
		CommonClientServer.SetFormItemProperty(
			Items, "AdditioinalAttributesAndInfoGroup",
			"Enabled", ConstantsSet.UseAdditionalAttributesAndInfo);
	EndIf;
	
	If (DataPathAttribute = "ConstantsSet.UseDigitalSignature"
		Or DataPathAttribute = "ConstantsSet.UseEncryption" Or DataPathAttribute = "")
		AND Common.SubsystemExists("StandardSubsystems.DigitalSignature") Then
		
		Items.DigitalSignatureAndEncryptionSettingsGroup.Enabled =
			ConstantsSet.UseDigitalSignature Or ConstantsSet.UseEncryption;
	EndIf;
	
	If Common.SubsystemExists("StandardSubsystems.SecurityProfiles") Then
		ModuleSafeModeManager = Common.CommonModule("SafeModeManager");
		UseSecurityProfiles = ModuleSafeModeManager.UseSecurityProfiles();
	Else
		UseSecurityProfiles = False;
	EndIf;
	
	If DataPathAttribute = "" Then
		ProxySettingAvailabilityAtServer = Not UseSecurityProfiles;
		
		CommonClientServer.SetFormItemProperty(
			Items, "OpenProxyServerParametersGroup",
			"Enabled", ProxySettingAvailabilityAtServer);
		CommonClientServer.SetFormItemProperty(
			Items, "ConfigureProxyServerAtServerGroupUnavailableWhenUsingSecurityProfiles",
			"Visible", Not ProxySettingAvailabilityAtServer);
	EndIf;
	
EndProcedure

#EndRegion
