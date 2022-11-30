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
	
	DataExchangeServer.CheckExchangeManagementRights();
	
	CheckDataSynchronizationSettingPossibility(Cancel);
	
	If Cancel Then
		Return;
	EndIf;
	
	HandlerParameters = Undefined;
	OnStartGetDataExchangeSettingOptionsAtServer(UUID, HandlerParameters, TimeConsumingOperation);
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	OnStartGetDataExchangeSettingOptions(True);
	
EndProcedure

&AtClient
Procedure URLProcessing(FormattedStringURL, StandardProcessing)
	
	CommandRows = CreateExchangeCommands.FindRows(
		New Structure("URL", FormattedStringURL));
		
	If CommandRows.Count() = 0 Then
		Return;
	EndIf;
	
	CommandRow = CommandRows[0];
	StandardProcessing = False;
	
	WizardParameters = New Structure;
	WizardParameters.Insert("ExchangePlanName",                     CommandRow.ExchangePlanName);
	WizardParameters.Insert("SettingID",             CommandRow.SettingID);
	WizardParameters.Insert("SettingOptionDetails",          CommandRow.SettingOptionDetails);
	WizardParameters.Insert("DataExchangeWithExternalSystem",       CommandRow.ExternalSystem);
	WizardParameters.Insert("ExternalSystemConnectionParameters", CommandRow.ExternalSystemConnectionParameters);
	WizardParameters.Insert("NewSYnchronizationSetting");
	
	WizardUniqueKey = WizardParameters.ExchangePlanName + "_" + WizardParameters.SettingID;
	
	OpenForm("DataProcessor.DataExchangeCreationWizard.Form.SyncSetup", WizardParameters, , WizardUniqueKey);
	
	Close();

EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure DecorationLabelExternalSystemsErrorURLProcessing(Item, FormattedStringURL, StandardProcessing)
	
	If FormattedStringURL = "OpenEventLog" Then
		
		StandardProcessing = False;
		
		If CommonClient.SubsystemExists("OnlineUserSupport.DataExchangeWithExternalSystems") Then
		
			EventLogEvent = New Array;
			
			ModuleDataExchangeWithExternalSystemsClient = CommonClient.CommonModule("DataExchangeWithExternalSystemsClient");
			EventLogEvent.Add(ModuleDataExchangeWithExternalSystemsClient.EventLogEventName());
			
			Filter = New Structure;
			Filter.Insert("EventLogEvent", EventLogEvent);
			Filter.Insert("Level",                   "Error");
			Filter.Insert("StartDate",                EventLogFilterStartDate());
			
			EventLogClient.OpenEventLog(Filter, ThisObject);
		
		EndIf;
		
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandHandlers

&AtClient
Procedure UpdateSettingsList(Command)
	
	OnStartGetDataExchangeSettingOptions();
	
EndProcedure

&AtClient
Procedure EnableOnlineSupport(Command)
	
	If CommonClient.SubsystemExists("OnlineUserSupport") Then
		ClosingNotification = New NotifyDescription("EnableOnlineSupportCompletion", ThisObject);
		
		ModuleOnlineUserSupportClient = CommonClient.CommonModule("OnlineUserSupportClient");
		ModuleOnlineUserSupportClient.ConnectOnlineUserSupport(ClosingNotification, ThisObject);
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

&AtServerNoContext
Function EventLogFilterStartDate()
	
	Return BegOfDay(CurrentSessionDate());
	
EndFunction

&AtClient
Procedure OnStartGetDataExchangeSettingOptions(OnOpen = False)
	
	If Not OnOpen Then
		HandlerParameters = Undefined;
		OnStartGetDataExchangeSettingOptionsAtServer(UUID, HandlerParameters, TimeConsumingOperation);
	EndIf;
	
	If TimeConsumingOperation Then
		Items.SettingsOptionsPanel.CurrentPage  = Items.WaitPage;
		Items.FormRefreshSettingsList.Enabled = False;
		
		DataExchangeClient.InitializeIdleHandlerParameters(IdleHandlerParameters);

		AttachIdleHandler("OnWaitForGetDataExchangeSettingOptions",
			IdleHandlerParameters.CurrentInterval, True);
	Else
		OnCompleteGettingDataExchangeSettingsOptions();
	EndIf;
	
EndProcedure

&AtClient
Procedure OnWaitForGetDataExchangeSettingOptions()
	
	OnWaitForGetDataExchangeSettingOptionsAtServer(HandlerParameters, TimeConsumingOperation);
	
	If TimeConsumingOperation Then
		DataExchangeClient.UpdateIdleHandlerParameters(IdleHandlerParameters);

		AttachIdleHandler("OnWaitForGetDataExchangeSettingOptions",
			IdleHandlerParameters.CurrentInterval, True);
	Else
		OnCompleteGettingDataExchangeSettingsOptions();
	EndIf;
	
EndProcedure

&AtClient
Procedure OnCompleteGettingDataExchangeSettingsOptions()
	
	OnCompleteGettingDataExchangeSettingsOptionsAtServer();
	
EndProcedure

&AtClient
Procedure EnableOnlineSupportCompletion(Result, AdditionalParameters) Export
	
	OnStartGetDataExchangeSettingOptions();
	
EndProcedure

&AtServerNoContext
Procedure OnStartGetDataExchangeSettingOptionsAtServer(UUID, HandlerParameters, ContinueWait)
	
	ModuleWizard = DataExchangeServer.ModuleDataExchangeCreationWizard();
	ModuleWizard.OnStartGetDataExchangeSettingOptions(UUID, HandlerParameters, ContinueWait);
	
EndProcedure

&AtServerNoContext
Procedure OnWaitForGetDataExchangeSettingOptionsAtServer(HandlerParameters, ContinueWait)
	
	ModuleWizard = DataExchangeServer.ModuleDataExchangeCreationWizard();
	ModuleWizard.OnWaitForGetDataExchangeSettingOptions(HandlerParameters, ContinueWait);
	
EndProcedure

&AtServer
Procedure OnCompleteGettingDataExchangeSettingsOptionsAtServer()
	
	Settings = Undefined;
	
	ModuleWizard = DataExchangeServer.ModuleDataExchangeCreationWizard();
	ModuleWizard.OnCompleteGetDataExchangeSettingOptions(HandlerParameters, Settings);
	
	ClearNewExchangeCreationCommands();
	AddCreateNewExchangeCommands(Settings);
	
	Items.SettingsOptionsPanel.CurrentPage  = Items.SettingsOptionsPage;
	Items.FormRefreshSettingsList.Enabled = True;
	
EndProcedure

&AtServer
Procedure ClearNewExchangeCreationCommands()
	
	CreateExchangeCommands.Clear();
	
	DeleteGroupSubordinateItems(Items.OtherApplicationsExchangeGroup);
	DeleteGroupSubordinateItems(Items.DIBExchangeGroup);
	DeleteGroupSubordinateItems(Items.ExternalSystemsSettingsOptionsPage);
	
EndProcedure

&AtServer
Procedure DeleteGroupSubordinateItems(ItemGroup)
	
	While ItemGroup.ChildItems.Count() > 0 Do
		Items.Delete(ItemGroup.ChildItems[0]);
	EndDo;
	
EndProcedure

&AtServer
Procedure AddCreateNewExchangeCommands(Settings)
	
	DefaultSettings = Undefined;
	If Settings.Property("DefaultSettings", DefaultSettings) Then
		
		SettingsTableOtherApplications = DefaultSettings.Copy(New Structure("IsDIBExchangePlan", False));
		SettingsTableOtherApplications.Sort("IsXDTOExchangePlan");
		AddNewExchangeCreationCommandsStandardSettings(SettingsTableOtherApplications, Items.OtherApplicationsExchangeGroup);
		
		DIBSettingsTable = DefaultSettings.Copy(New Structure("IsDIBExchangePlan", True));
		AddNewExchangeCreationCommandsStandardSettings(DIBSettingsTable, Items.DIBExchangeGroup);
		
	EndIf;
	
	SettingsExternalSystems = Undefined;
	If Settings.Property("SettingsExternalSystems", SettingsExternalSystems) Then
		
		Items.ExternalSystemsExchangeGroup.Visible = True;
		
		If SettingsExternalSystems.ErrorCode = "" Then
			
			If SettingsExternalSystems.SettingVariants.Count() > 0 Then
				AddNewExchangeCreationCommandsSettingsExternalSystems(
					SettingsExternalSystems.SettingVariants, Items.ExternalSystemsSettingsOptionsPage);
				Items.ExternalSystemsExchangePanel.CurrentPage = Items.ExternalSystemsSettingsOptionsPage;
			Else
				Items.ExternalSystemsExchangePanel.CurrentPage = Items.ExternalStystemsNoneSettingsOptionsPage;
			EndIf;
			
		ElsIf SettingsExternalSystems.ErrorCode = "InvalidUsernameOrPassword" Then
			
			If Common.DataSeparationEnabled()
				AND Common.SeparatedDataUsageAvailable() Then
				Items.ExternalSystemsExchangePanel.CurrentPage = Items.PageExternalSystemsOnlineSupportNotEnabledInSaaS;
			Else
				Items.ExternalSystemsExchangePanel.CurrentPage = Items.PageExternalSystemsOnlineSupportNotEnabled;
			EndIf;
			
		ElsIf ValueIsFilled(SettingsExternalSystems.ErrorCode) Then
			
			Items.ExternalSystemsExchangePanel.CurrentPage = Items.ExternalSystemsErrorPage;
			
		EndIf;
		
	Else
		
		Items.ExternalSystemsExchangeGroup.Visible = False;
		
	EndIf;
	
EndProcedure

&AtServer
Procedure AddNewExchangeCreationCommandsStandardSettings(SettingsTable, ParentGroup)
	
	ConfigurationTable = SettingsTable.Copy(, "CorrespondentConfigurationName");
	ConfigurationTable.GroupBy("CorrespondentConfigurationName");
	
	For Each ConfigurationString In ConfigurationTable Do
		
		SetupStrings = SettingsTable.FindRows(
			New Structure("CorrespondentConfigurationName", ConfigurationString.CorrespondentConfigurationName));
		
		For Each SettingString In SetupStrings Do
			
			SettingOptionDetails = SettingOptionDetailsStructure();
			FillPropertyValues(SettingOptionDetails, SettingString);
			SettingOptionDetails.CorrespondentDescription = SettingString.CorrespondentConfigurationDescription;
			
			AddNewExchangeCreationCommandForSettingOption(
				ParentGroup,
				SettingString.ExchangePlanName,
				SettingString.SettingID,
				SettingOptionDetails);
			
		EndDo;
		
	EndDo;
	
EndProcedure

&AtServer
Procedure AddNewExchangeCreationCommandsSettingsExternalSystems(SettingsOptions, ParentGroup)
	
	For Each SettingsOption In SettingsOptions Do
		
		SettingOptionDetails = SettingOptionDetailsStructure();
		FillPropertyValues(SettingOptionDetails, SettingsOption);
		
		AddNewExchangeCreationCommandForSettingOption(
			ParentGroup,
			SettingsOption.ExchangePlanName,
			SettingsOption.SettingID,
			SettingOptionDetails,
			True,
			SettingsOption.AttachmentParameters);
		
	EndDo;
	
EndProcedure

&AtServer
Procedure AddNewExchangeCreationCommandForSettingOption(
		ParentGroup,
		ExchangePlanName,
		SettingID,
		SettingOptionDetails,
		ExternalSystem = False,
		ExternalSystemConnectionParameters = Undefined)
	
	URL = "Settings" + ExchangePlanName + "Variant" + SettingID;
			
	ItemRef = Items.Add(
		"LabelDecoration" + URL,
		Type("FormDecoration"),
		ParentGroup);
	ItemRef.Type = FormDecorationType.Label;
	ItemRef.Title = New FormattedString(
		SettingOptionDetails.NewDataExchangeCreationCommandTitle, , , , URL);
	ItemRef.ToolTipRepresentation = ToolTipRepresentation.ShowBottom;
	ItemRef.AutoMaxWidth = False;
	
	ItemRef.ExtendedTooltip.Title = SettingOptionDetails.ExchangeBriefInfo;
	ItemRef.ExtendedTooltip.AutoMaxWidth = False;
	
	StringCommand = CreateExchangeCommands.Add();
	StringCommand.URL = URL;
	StringCommand.ExchangePlanName = ExchangePlanName;
	StringCommand.SettingID = SettingID;
	StringCommand.SettingOptionDetails = SettingOptionDetails;
	StringCommand.ExternalSystem = ExternalSystem;
	StringCommand.ExternalSystemConnectionParameters = ExternalSystemConnectionParameters;
	
EndProcedure

&AtServerNoContext
Function SettingOptionDetailsStructure()
	
	ModuleWizard = DataExchangeServer.ModuleDataExchangeCreationWizard();
	Return ModuleWizard.SettingOptionDetailsStructure();
	
EndFunction

&AtServer
Procedure CheckDataSynchronizationSettingPossibility(Cancel = False)
	
	MessageText = "";
	If Common.DataSeparationEnabled() Then
		If Common.SeparatedDataUsageAvailable() Then
			ModuleDataExchangeSaaSCashed = Common.CommonModule("DataExchangeSaaSCached");
			If Not ModuleDataExchangeSaaSCashed.DataSynchronizationSupported() Then
		 		MessageText = NStr("ru = 'Возможность настройки синхронизации данных в данной программе не предусмотрена.'; en = 'This application does not support data synchronization setup.'; pl = 'Możliwość ustawienia synchronizacji danych w tym programie nie jest przewidziana.';de = 'Die Möglichkeit, in diesem Programm eine Datensynchronisation einzurichten, ist nicht vorgesehen.';ro = 'Posibilitatea setării sincronizării datelor în acest program nu este prevăzută.';tr = 'Bu programda veri eşleşmesi ayarları yapılandırılamaz.'; es_ES = 'Posibilidad de ajustar la sincronización de datos en este programa no está prevista.'");
				Cancel = True;
			EndIf;
		Else
			MessageText = NStr("ru = 'В неразделенном режиме настройка синхронизации данных с другими программами недоступна.'; en = 'Cannot configure data synchronization in shared mode.'; pl = 'W niepodzielonym trybie ustawienie synchronizacji danych z innymi programami jest niedostępne.';de = 'Die Einrichtung der Datensynchronisation mit anderen Programmen ist im ungeteilten Modus nicht möglich.';ro = 'În regimul neseparat setarea sincronizării datelor cu alte programe este inaccesibilă.';tr = 'Bölünmemiş modda, diğer programlarla veri eşleştirmesi ayarları kullanılamaz.'; es_ES = 'En el modo no distribuido el ajuste de sincronización de datos con otro programa no está disponible.'");
			Cancel = True;
		EndIf;
	Else
		ExchangePlanList = DataExchangeCached.SSLExchangePlans();
		If ExchangePlanList.Count() = 0 Then
			MessageText = NStr("ru = 'Возможность настройки синхронизации данных в данной программе не предусмотрена.'; en = 'This application does not support data synchronization setup.'; pl = 'Możliwość ustawienia synchronizacji danych w tym programie nie jest przewidziana.';de = 'Die Möglichkeit, in diesem Programm eine Datensynchronisation einzurichten, ist nicht vorgesehen.';ro = 'Posibilitatea setării sincronizării datelor în acest program nu este prevăzută.';tr = 'Bu programda veri eşleşmesi ayarları yapılandırılamaz.'; es_ES = 'Posibilidad de ajustar la sincronización de datos en este programa no está prevista.'");
			Cancel = True;
		EndIf;
	EndIf;
	
	If Cancel
		AND Not IsBlankString(MessageText) Then
		Common.MessageToUser(MessageText);
	EndIf;
	
EndProcedure

#EndRegion