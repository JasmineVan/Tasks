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
	
	InitializeFormAttributes();
	
	InitializeFormProperties();
	
	SetInitialFormItemsView();
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	FillSetupStagesTable();
	UpdateCurrentSettingsStateDisplay();
	
EndProcedure

&AtClient
Procedure BeforeClose(Cancel, Exit, WarningText, StandardProcessing)
	
	If Exit Then
		Return;
	EndIf;
	
	RefExists   = False;
	SetupCompleted = False;
	
	If ValueIsFilled(ExchangeNode) Then
		SetupCompleted = SynchronizationSetupCompleted(ExchangeNode, RefExists);
		If Not RefExists Then
			// Closing form when deleting sinchronization setup.
			Return;
		EndIf;
	EndIf;
	
	If Not ValueIsFilled(ExchangeNode)
		Or Not SetupCompleted
		Or (DIBSetup AND Not ContinueSetupInSubordinateDIBNode AND Not InitialImageCreated(ExchangeNode))Then
		WarningText = NStr("ru = 'Настройка синхронизации данных еще не завершена.
		|Завершить работу с помощником? Настройку можно будет продолжить позже.'; 
		|en = 'The data synchronization setup is not completed.
		|Do you want to close the wizard? You can continue the setup later.'; 
		|pl = 'Konfigurowanie synchronizacji danych nie zostało jeszcze zakończone.
		|Zakończyć pracę z asystentem? Konfigurację można będzie kontynuować później.';
		|de = 'Die Einrichtung der Datensynchronisation ist noch nicht abgeschlossen.
		|Den Assistenten abschalten? Die Konfiguration kann später fortgesetzt werden.';
		|ro = 'Setarea sincronizării datelor încă nu este finalizată.
		|Finalizați lucrul cu asistentul? Setarea poate fi finalizată mai târziu.';
		|tr = 'Veri senkronizasyonu ayarı henüz tamamlanmadı.
		|Sihirbazdan çıkmak istiyor musunuz? Ayarlara daha sonra devam edilebilir.'; 
		|es_ES = 'El ajuste de sincronización de datos no se ha terminado.
		|¿Finalizar el trabajo con ayudante? Se puede seguir ajustando después.'");
		CommonClient.ShowArbitraryFormClosingConfirmation(
			ThisObject, Cancel, Exit, WarningText, "ForceCloseForm");
	EndIf;
	
EndProcedure

&AtClient
Procedure OnClose(Exit)
	
	If Not Exit Then
		Notify("DataExchangeCreationWizardFormClosed");
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandHandlers

&AtClient
Procedure DataSyncDetails(Command)
	
	DataExchangeClient.OpenSynchronizationDetails(SettingOptionDetails.ExchangeDetailedInformation);
	
EndProcedure

&AtClient
Procedure SetUpConnectionParameters(Command)
	
	If IsExchangeWithApplicationInService
		AND (Not NewSYnchronizationSetting
			Or Not CurrentSetupStep = "ConnectionSetup") Then
		WarnString = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Настройка подключения к ""%1"" уже выполнена.
			|Редактирование параметров подключения не предусмотрено.'; 
			|en = 'Connection to ""%1"" is already configured.
			|Editing the connection parameters is not allowed.'; 
			|pl = 'Konfigurowanie połączenia do ""%1"" zostało już wykonane.
			|Edycja ustawień połączenia nie jest przewidziane.';
			|de = 'Die Verbindung zum ""%1"" ist bereits hergestellt.
			|Die Verbindungsparameter können nicht bearbeitet werden.';
			|ro = 'Setarea conexiunii la ""%1"" deja este executată.
			|Editarea parametrilor conexiunii nu este prevăzută.';
			|tr = '""%1"" ''e bağlantı ayarları zaten yapıldı.  
			| Bağlantı parametreleri düzenlenemez.'; 
			|es_ES = 'El ajuste de conexión a ""%1"" se ha ejecutado ya.
			|No está previsto editar los parámetros de conexión.'"), ExchangeNode);
		ShowMessageBox(, WarnString);
		Return;
	EndIf;
	
	ClosingNotification = New NotifyDescription("SetUpConnectionParametersCompletion", ThisObject);
	
	If DataExchangeWithExternalSystem Then
		If CommonClient.SubsystemExists("OnlineUserSupport.DataExchangeWithExternalSystems") Then
			Context = New Structure;
			Context.Insert("SettingID", SettingID);
			Context.Insert("AttachmentParameters", ExternalSystemConnectionParameters);
			Context.Insert("Correspondent", ExchangeNode);
			
			If NewSYnchronizationSetting
				AND CurrentSetupStep = "ConnectionSetup" Then
				Context.Insert("Mode", "NewConnection");
			Else
				Context.Insert("Mode", "EditConnectionParameters");
			EndIf;
			
			Cancel = False;
			WizardFormName  = "";
			WizardParameters = New Structure;
			
			ModuleDataExchangeWithExternalSystemsClient = CommonClient.CommonModule("DataExchangeWithExternalSystemsClient");
			ModuleDataExchangeWithExternalSystemsClient.BeforeConnectionParametersSetting(
				Context, Cancel, WizardFormName, WizardParameters);
			
			If Not Cancel Then
				OpenForm(WizardFormName,
					WizardParameters, ThisObject, , , , ClosingNotification, FormWindowOpeningMode.LockOwnerWindow);
			EndIf;
		EndIf;
		Return;
	ElsIf NewSYnchronizationSetting Then
		WizardParameters = New Structure;
		WizardParameters.Insert("ExchangePlanName",         ExchangePlanName);
		WizardParameters.Insert("SettingID", SettingID);
		If ContinueSetupInSubordinateDIBNode Then
			WizardParameters.Insert("ContinueSetupInSubordinateDIBNode");
		EndIf;
		
		OpenForm("DataProcessor.DataExchangeCreationWizard.Form.ConnectionSetup",
			WizardParameters, ThisObject, , , , ClosingNotification, FormWindowOpeningMode.LockOwnerWindow);
	Else
		Filter              = New Structure("Correspondent", ExchangeNode);
		FillingValues = New Structure("Correspondent", ExchangeNode);
		
		DataExchangeClient.OpenInformationRegisterWriteFormByFilter(Filter,
			FillingValues, "DataExchangeTransportSettings", ThisObject);
	EndIf;
	
EndProcedure

&AtClient
Procedure GetConnectionConfirmation(Command)
	
	If Not DataExchangeWithExternalSystem
		Or XDTOCorrespondentSettingsReceived(ExchangeNode) Then
		ShowMessageBox(, NStr("ru = 'Подключение подтверждено.'; en = 'The connection is confirmed.'; pl = 'Połączenie zostało potwierdzone.';de = 'Verbindung bestätigt.';ro = 'Conectarea este confirmată.';tr = 'Bağlantı doğrulandı.'; es_ES = 'Conexión confirmada.'"));
		Return;
	EndIf;
	
	If CommonClient.SubsystemExists("OnlineUserSupport.DataExchangeWithExternalSystems") Then
		Context = New Structure;
		Context.Insert("Mode",                  "ConnectionConfirmation");
		Context.Insert("Correspondent",          ExchangeNode);
		Context.Insert("SettingID", "SettingID");
		Context.Insert("AttachmentParameters",   ExternalSystemConnectionParameters);
		
		Cancel = False;
		WizardFormName  = "";
		WizardParameters = New Structure;
		
		ModuleDataExchangeWithExternalSystemsClient = CommonClient.CommonModule("DataExchangeWithExternalSystemsClient");
		ModuleDataExchangeWithExternalSystemsClient.BeforeConnectionParametersSetting(
			Context, Cancel, WizardFormName, WizardParameters);
		
		If Not Cancel Then
			ClosingNotification = New NotifyDescription("GetConnectionConfirmationCompletion", ThisObject);
			OpenForm(WizardFormName,
				WizardParameters, ThisObject, , , , ClosingNotification, FormWindowOpeningMode.LockOwnerWindow);
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure ConfigureDataExportImportRules(Command)
	
	ContinueNotification = New NotifyDescription("SetDataSendingAndReceivingRulesFollowUp", ThisObject);
	
	// Get the correspondent settings for the XDTO exchange plan before setting export and import rules.
	// 
	If XDTOSetup Then
		AbortSetup = False;
		ExecuteXDTOSettingsImportIfNecessary(AbortSetup, ContinueNotification);
		
		If AbortSetup Then
			Return;
		EndIf;
	EndIf;
	
	Result = New Structure;
	Result.Insert("ContinueSetup",            True);
	Result.Insert("DataReceivedForMapping", DataReceivedForMapping);
	
	ExecuteNotifyProcessing(ContinueNotification, Result);
	
EndProcedure

&AtClient
Procedure CreateInitialDIBImage(Command)
	
	WizardParameters = New Structure("Key, Node", ExchangeNode, ExchangeNode);
			
	ClosingNotification = New NotifyDescription("CreateInitialDIBImageCompletion", ThisObject);
	OpenForm(InitialImageCreationFormName,
		WizardParameters, ThisObject, , , , ClosingNotification, FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure MapAndExportData(Command)
	
	ContinueNotification = New NotifyDescription("MapAndExportDataFollowUp", ThisObject);
	
	WizardParameters = New Structure;
	WizardParameters.Insert("SendData",     False);
	WizardParameters.Insert("ScheduleSetup", False);
	
	If IsExchangeWithApplicationInService Then
		WizardParameters.Insert("CorrespondentDataArea", CorrespondentDataArea);
	EndIf;
	
	AuxiliaryParameters = New Structure;
	AuxiliaryParameters.Insert("WizardParameters",  WizardParameters);
	AuxiliaryParameters.Insert("ClosingNotification", ContinueNotification);
	
	DataExchangeClient.OpenObjectsMappingWizardCommandProcessing(ExchangeNode,
		ThisObject, AuxiliaryParameters);
	
EndProcedure

&AtClient
Procedure ExecuteInitialDataExport(Command)
	
	WizardParameters = New Structure;
	WizardParameters.Insert("ExchangeNode", ExchangeNode);
	WizardParameters.Insert("InitialExport");
	
	If SaaSModel Then
		WizardParameters.Insert("IsExchangeWithApplicationInService", IsExchangeWithApplicationInService);
		WizardParameters.Insert("CorrespondentDataArea",  CorrespondentDataArea);
	EndIf;
	
	ClosingNotification = New NotifyDescription("ExecuteInitialDataExportCompletion", ThisObject);
	OpenForm("DataProcessor.InteractiveDataExchangeWizard.Form.ExportMappingData",
		WizardParameters, ThisObject, , , , ClosingNotification, FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

#EndRegion

#Region Private

&AtServerNoContext
Function SynchronizationSetupStatus(ExchangeNode)
	
	Result = New Structure;
	Result.Insert("SynchronizationSetupCompleted",           SynchronizationSetupCompleted(ExchangeNode));
	Result.Insert("InitialImageCreated",                      InitialImageCreated(ExchangeNode));
	Result.Insert("MessageWithDataForMappingReceived", DataExchangeServer.MessageWithDataForMappingReceived(ExchangeNode));
	Result.Insert("XDTOCorrespondentSettingsReceived",       XDTOCorrespondentSettingsReceived(ExchangeNode));
	
	Return Result;
	
EndFunction

&AtServerNoContext
Function XDTOCorrespondentSettingsReceived(ExchangeNode)
	
	CorrespondentSettings = DataExchangeXDTOServer.SupportedCorrespondentFormatObjects(ExchangeNode, "SendGet");
	
	Return CorrespondentSettings.Count() > 0;
	
EndFunction

&AtServerNoContext
Function InitialImageCreated(ExchangeNode)
	
	Return InformationRegisters.CommonInfobasesNodesSettings.InitialImageCreated(ExchangeNode);
	
EndFunction

&AtClient
Procedure SetUpConnectionParametersCompletion(ClosingResult, AdditionalParameters) Export
	
	If ClosingResult <> Undefined
		AND TypeOf(ClosingResult) = Type("Structure") Then
		
		If ClosingResult.Property("ExchangeNode") Then
			ExchangeNode = ClosingResult.ExchangeNode;
			UniqueKey = ExchangePlanName + "_" + SettingID + "_" + ExchangeNode.UUID();
			
			If DataExchangeWithExternalSystem Then
				UpdateExternalSystemConnectionParameters(ExchangeNode, ExternalSystemConnectionParameters);
			EndIf;
		EndIf;
		
		If SaaSModel Then
			ClosingResult.Property("IsExchangeWithApplicationInService", IsExchangeWithApplicationInService);
			ClosingResult.Property("CorrespondentDataArea",  CorrespondentDataArea);
		EndIf;
		
		If ClosingResult.Property("HasDataToMap")
			AND ClosingResult.HasDataToMap Then
			DataReceivedForMapping = True;
		EndIf;
		
		If ClosingResult.Property("PassiveMode")
			AND ClosingResult.PassiveMode Then
			InteractiveSendingAvailable = False;
		EndIf;
		
		FillSetupStagesTable();
		UpdateCurrentSettingsStateDisplay();
		
		If CurrentSetupStep = "ConnectionSetup" Then
			GoToNextSetupStage();
		EndIf;
		
	EndIf;
	
EndProcedure

&AtServerNoContext
Procedure UpdateExternalSystemConnectionParameters(ExchangeNode, ExternalSystemConnectionParameters)
	
	ExternalSystemConnectionParameters = InformationRegisters.DataExchangeTransportSettings.ExternalSystemTransportSettings(ExchangeNode);
	
EndProcedure

&AtClient
Procedure GetConnectionConfirmationCompletion(Result, AdditionalParameters) Export
	
	If XDTOCorrespondentSettingsReceived(ExchangeNode) Then
		GoToNextSetupStage();
	EndIf;
	
EndProcedure

&AtClient
Procedure ExecuteXDTOSettingsImportIfNecessary(AbortSetup, ContinueNotification)
	
	SetupStatus = SynchronizationSetupStatus(ExchangeNode);
	If Not SetupStatus.SynchronizationSetupCompleted
		AND Not SetupStatus.XDTOCorrespondentSettingsReceived Then
		
		ImportParameters = New Structure;
		ImportParameters.Insert("ExchangeNode", ExchangeNode);
		
		OpenForm("DataProcessor.DataExchangeCreationWizard.Form.XDTOSettingsImport",
			ImportParameters, ThisObject, , , , ContinueNotification, FormWindowOpeningMode.LockOwnerWindow);
			
		AbortSetup = True;
	EndIf;
	
EndProcedure

&AtClient
Procedure SetDataSendingAndReceivingRulesFollowUp(ClosingResult, AdditionalParameters) Export
	
	If Not ClosingResult.ContinueSetup Then
		Return;
	EndIf;
	
	InteractiveSendingAvailable = InteractiveSendingAvailable
		AND Not (DataExchangeServerCall.DataExchangeOption(ExchangeNode) = "ReceiveOnly");
	
	If ClosingResult.DataReceivedForMapping
		AND Not DataReceivedForMapping Then
		DataReceivedForMapping = ClosingResult.DataReceivedForMapping;
	EndIf;
	
	FillSetupStagesTable();
	UpdateCurrentSettingsStateDisplay();
	
	ClosingNotification = New NotifyDescription("SetDataSendingAndReceivingRulesCompletion", ThisObject);
	
	CheckParameters = New Structure;
	CheckParameters.Insert("Correspondent",          ExchangeNode);
	CheckParameters.Insert("ExchangePlanName",         ExchangePlanName);
	CheckParameters.Insert("SettingID", SettingID);
	
	SetupExecuted = False;
	BeforeDataSynchronizationSetup(CheckParameters, SetupExecuted, DataSyncSettingsWizardFormName);
	
	If SetupExecuted Then
		ShowMessageBox(, NStr("ru = 'Настройка правил отправки и получения данных выполнена.'; en = 'The rules for sending and receiving data are configured.'; pl = 'Konfiguracja reguł wysyłania i odbierania danych została wykonana.';de = 'Die Regeln für das Senden und Empfangen von Daten werden festgelegt.';ro = 'Setarea regulilor de trimitere și primire a datelor este executată.';tr = 'Veri gönderme ve alma kurallarının ayarları yapıldı.'; es_ES = 'Se ha realizado el ajuste de reglas y recepción de datos.'"));
		ExecuteNotifyProcessing(ClosingNotification, True);
		Return;
	EndIf;
	
	WizardParameters = New Structure;
	
	If IsBlankString(DataSyncSettingsWizardFormName) Then
		WizardParameters.Insert("Key", ExchangeNode);
		WizardParameters.Insert("WizardFormName", "ExchangePlan.[ExchangePlanName].ObjectForm");
		
		WizardParameters.WizardFormName = StrReplace(WizardParameters.WizardFormName,
			"[ExchangePlanName]", ExchangePlanName);
	Else
		WizardParameters.Insert("ExchangeNode", ExchangeNode);
		WizardParameters.Insert("WizardFormName", DataSyncSettingsWizardFormName);
	EndIf;
	
	OpenForm(WizardParameters.WizardFormName,
		WizardParameters, ThisObject, , , , ClosingNotification, FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure SetDataSendingAndReceivingRulesCompletion(ClosingResult, AdditionalParameters) Export
	
	If CurrentSetupStep = "RulesSetting"
		AND SynchronizationSetupCompleted(ExchangeNode) Then
		Notify("Write_ExchangePlanNode");
		If ContinueSetupInSubordinateDIBNode Then
			RefreshInterface();
		EndIf;
		GoToNextSetupStage();
	EndIf;
	
EndProcedure

&AtClient
Procedure MapAndExportDataFollowUp(ClosingResult, AdditionalParameters) Export
	
	If TypeOf(ClosingResult) = Type("Structure") Then
		DataImportResult = Undefined;
		If ClosingResult.Property("DataImportResult", DataImportResult) Then
			If DataImportResult = "Error"
				Or DataImportResult = "Error_MessageTransport" Then
				Return;
			EndIf;
		EndIf;
	EndIf;
	
	If CurrentSetupStep = "MapAndImport"
		AND DataForMappingImported(ExchangeNode) Then
		GoToNextSetupStage();
	EndIf;
	
EndProcedure

&AtClient
Procedure CreateInitialDIBImageCompletion(ClosingResult, AdditionalParameters) Export
	
	If CurrentSetupStep = "InitialDIBImage"
		AND InitialImageCreated(ExchangeNode) Then
		GoToNextSetupStage();
	EndIf;
	
	RefreshInterface();
	
EndProcedure

&AtClient
Procedure ExecuteInitialDataExportCompletion(ClosingResult, AdditionalParameters) Export
	
	If CurrentSetupStep = "InitialDataExport"
		AND ClosingResult = ExchangeNode Then
		GoToNextSetupStage();
	EndIf;
	
EndProcedure

&AtClient
Procedure UpdateCurrentSettingsStateDisplay()
	
	// Visibility of setup items.
	For Each SetupStage In AllSetupSteps Do
		CommonClientServer.SetFormItemProperty(Items,
			"Group" + SetupStage.Key,
			"Visible",
			SetupSteps.FindRows(New Structure("Name", SetupStage.Key)).Count() > 0);
	EndDo;
	
	If IsBlankString(CurrentSetupStep) Then
		// All stages are completed.
		For Each SetupStage In SetupSteps Do
			Items["Group" + SetupStage.Name].Enabled = True;
			Items[SetupStage.Button].Font = SetupStage.StandardFont;
			
			// Green flag is only for the main setting stages.
			If AllSetupSteps[SetupStage.Name] = "Main" Then
				Items["Panel" + SetupStage.Name].CurrentPage = Items["Page" + SetupStage.Name + "Success"];
			Else
				Items["Panel" + SetupStage.Name].CurrentPage = Items["Page" + SetupStage.Name + "IsEmpty"];
			EndIf;
		EndDo;
	Else
		
		CurrentStageFound = False;
		For Each SetupStage In SetupSteps Do
			If SetupStage.Name = CurrentSetupStep Then
				Items["Group" + SetupStage.Name].Enabled = True;
				Items["Panel" + SetupStage.Name].CurrentPage = Items["Page" + SetupStage.Name + "Current"];
				Items[SetupStage.Button].Font = SetupStage.BoldFont;
				CurrentStageFound = True;
			ElsIf Not CurrentStageFound Then
				Items["Group" + SetupStage.Name].Enabled = True;
				Items["Panel" + SetupStage.Name].CurrentPage = Items["Page" + SetupStage.Name + "Success"];
				Items[SetupStage.Button].Font = SetupStage.StandardFont;
			Else
				Items["Group" + SetupStage.Name].Enabled = False;
				Items["Panel" + SetupStage.Name].CurrentPage = Items["Page" + SetupStage.Name + "IsEmpty"];
				Items[SetupStage.Button].Font = SetupStage.StandardFont;
			EndIf;
		EndDo;
		
		For Each SetupStage In AllSetupSteps Do
			RowsStages = SetupSteps.FindRows(New Structure("Name", SetupStage.Key));
			If RowsStages.Count() = 0 Then
				Items["Group" + SetupStage.Key].Enabled = False;
				Items["Panel" + SetupStage.Key].CurrentPage = Items["Page" + SetupStage.Key + "IsEmpty"];
			EndIf;
		EndDo;
	EndIf;
			
EndProcedure

&AtClient
Procedure GoToNextSetupStage()
	
	NextRow = Undefined;
	CurrentStageFound = False;
	For Each SetupStagesString In SetupSteps Do
		If CurrentStageFound Then
			NextRow = SetupStagesString;
			Break;
		EndIf;
		
		If SetupStagesString.Name = CurrentSetupStep Then
			CurrentStageFound = True;
		EndIf;
	EndDo;
	
	If NextRow <> Undefined Then
		CurrentSetupStep = NextRow.Name;
		
		If CurrentSetupStep = "RulesSetting" Then
			CheckParameters = New Structure;
			CheckParameters.Insert("Correspondent",          ExchangeNode);
			CheckParameters.Insert("ExchangePlanName",         ExchangePlanName);
			CheckParameters.Insert("SettingID", SettingID);
			
			SetupExecuted = SynchronizationSetupCompleted(ExchangeNode);
			If Not SetupExecuted Then
				If Not XDTOSetup Or XDTOCorrespondentSettingsReceived(ExchangeNode) Then
					BeforeDataSynchronizationSetup(CheckParameters, SetupExecuted, DataSyncSettingsWizardFormName);
				EndIf;
			EndIf;
			
			If SetupExecuted Then
				GoToNextSetupStage();
				Return;
			EndIf;
		EndIf;
		
		If AllSetupSteps[CurrentSetupStep] <> "Main" Then
			CurrentSetupStep = "";
		EndIf;
	Else
		CurrentSetupStep = "";
	EndIf;
	
	AttachIdleHandler("UpdateCurrentSettingsStateDisplay", 0.2, True);
	
EndProcedure

&AtServerNoContext
Function SynchronizationSetupCompleted(ExchangeNode, RefExists = False)
	
	RefExists = Common.RefExists(ExchangeNode);
	Return DataExchangeServer.SynchronizationSetupCompleted(ExchangeNode);
	
EndFunction

&AtServerNoContext
Function DataForMappingImported(ExchangeNode)
	
	Return Not DataExchangeServer.MessageWithDataForMappingReceived(ExchangeNode);
	
EndFunction

&AtServerNoContext
Procedure BeforeDataSynchronizationSetup(CheckParameters, SetupExecuted, WizardFormName)
	
	If DataExchangeServer.HasExchangePlanManagerAlgorithm("BeforeDataSynchronizationSetup", CheckParameters.ExchangePlanName) Then
		
		Context = New Structure;
		Context.Insert("Correspondent",          CheckParameters.Correspondent);
		Context.Insert("SettingID", CheckParameters.SettingID);
		Context.Insert("InitialSetting",     Not SynchronizationSetupCompleted(CheckParameters.Correspondent));
		
		ExchangePlans[CheckParameters.ExchangePlanName].BeforeDataSynchronizationSetup(
			Context, SetupExecuted, WizardFormName);
		
		If SetupExecuted Then
			DataExchangeServer.CompleteDataSynchronizationSetup(CheckParameters.Correspondent);
		EndIf;
		
	EndIf;
	
EndProcedure

#Region FormInitializationOnCreate

&AtServer
Procedure InitializeFormProperties()
	
	Title = SettingOptionDetails.ExchangeCreateWizardTitle;
	
	If IsBlankString(Title) Then
		If DIBSetup Then
			Title = NStr("ru = 'Настройка распределенной информационной базы'; en = 'Configure distributed infobase'; pl = 'Konfiguracja przydzielonej bazy informacyjnej';de = 'Aufbau einer verteilten Informationsbasis';ro = 'Setarea bazei de informații distribuite';tr = 'Dağıtılmış veri tabanı ayarı'; es_ES = 'Ajuste de la base de información distribuida'");
		Else
			Title = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'Настройка синхронизации данных с ""%1""'; en = 'Configure data synchronization with %1'; pl = 'Ustawianie synchronizacji danych z ""%1""';de = 'Einstellung der Datensynchronisation mit ""%1""';ro = 'Setarea sincronizării datelor cu ""%1""';tr = '%1 ile veri senkronizasyonu ayarı'; es_ES = 'Configuración de la sincronización de datos con ""%1""'"),
				SettingOptionDetails.CorrespondentDescription);
		EndIf;
	EndIf;
	
EndProcedure

&AtServer
Procedure InitializeFormAttributes()
	
	Parameters.Property("SettingOptionDetails",    SettingOptionDetails);
	Parameters.Property("DataExchangeWithExternalSystem", DataExchangeWithExternalSystem);
	
	NewSYnchronizationSetting = Parameters.Property("NewSYnchronizationSetting");
	ContinueSetupInSubordinateDIBNode = Parameters.Property("ContinueSetupInSubordinateDIBNode");
	
	SaaSModel = Common.DataSeparationEnabled()
		AND Common.SeparatedDataUsageAvailable();
	
	If NewSYnchronizationSetting Then
		ExchangePlanName         = Parameters.ExchangePlanName;
		SettingID = Parameters.SettingID;
		
		If DataExchangeWithExternalSystem Then
			Parameters.Property("ExternalSystemConnectionParameters", ExternalSystemConnectionParameters);
		Else
			If Not ContinueSetupInSubordinateDIBNode Then
				If DataExchangeServer.IsSubordinateDIBNode() Then
					DIBExchangePlanName = DataExchangeServer.MasterNode().Metadata().Name;
					
					ContinueSetupInSubordinateDIBNode = (ExchangePlanName = DIBExchangePlanName)
						AND Not Constants.SubordinateDIBNodeSetupCompleted.Get();
				EndIf;
			EndIf;
			
			If ContinueSetupInSubordinateDIBNode Then
				DataExchangeServer.OnContinueSubordinateDIBNodeSetup();
				ExchangeNode = DataExchangeServer.MasterNode();
			EndIf;
		EndIf;
	Else
		ExchangeNode = Parameters.ExchangeNode;
		
		ExchangePlanName         = DataExchangeCached.GetExchangePlanName(ExchangeNode);
		SettingID = DataExchangeServer.SavedExchangePlanNodeSettingOption(ExchangeNode);
		
		If SaaSModel Then
			Parameters.Property("CorrespondentDataArea",  CorrespondentDataArea);
			Parameters.Property("IsExchangeWithApplicationInService", IsExchangeWithApplicationInService);
		EndIf;
		
		If DataExchangeWithExternalSystem Then
			UpdateExternalSystemConnectionParameters(ExchangeNode, ExternalSystemConnectionParameters);
		EndIf;
	EndIf;
	
	If ContinueSetupInSubordinateDIBNode
		Or (Not DataExchangeWithExternalSystem
			AND SettingOptionDetails = Undefined) Then
		ModuleWizard = DataExchangeServer.ModuleDataExchangeCreationWizard();
		SettingOptionDetails = ModuleWizard.SettingOptionDetailsStructure();
		
		SettingsValuesForOption = DataExchangeServer.ExchangePlanSettingValue(ExchangePlanName,
			"CorrespondentConfigurationDescription,
			|NewDataExchangeCreationCommandTitle,
			|ExchangeCreateWizardTitle,
			|ExchangeBriefInfo,
			|ExchangeDetailedInformation",
			SettingID);
			
		FillPropertyValues(SettingOptionDetails, SettingsValuesForOption);
		SettingOptionDetails.CorrespondentDescription = SettingsValuesForOption.CorrespondentConfigurationDescription;
	EndIf;
	
	TransportKind = Undefined;
	If ValueIsFilled(ExchangeNode) Then
		SetupCompleted = SynchronizationSetupCompleted(ExchangeNode);
		TransportKind = InformationRegisters.DataExchangeTransportSettings.DefaultExchangeMessagesTransportKind(ExchangeNode);
		TransportSettingsAvailable = ValueIsFilled(TransportKind);
	EndIf;
	
	Backup = Not SaaSModel
		AND Not ContinueSetupInSubordinateDIBNode
		AND Common.SubsystemExists("StandardSubsystems.IBBackup");
		
	If Backup Then
		ModuleIBBackupServer = Common.CommonModule("IBBackupServer");
		
		BackupDataProcessorURL =
			ModuleIBBackupServer.BackupDataProcessorURL();
	EndIf;
		
	DIBSetup                  = DataExchangeCached.IsDistributedInfobaseExchangePlan(ExchangePlanName);
	XDTOSetup                 = DataExchangeServer.IsXDTOExchangePlan(ExchangePlanName);
	UniversalExchangeSetup = DataExchangeCached.IsStandardDataExchangeNode(ExchangePlanName); // without conversion rules
	
	InteractiveSendingAvailable = Not DIBSetup AND Not UniversalExchangeSetup;
	
	If Not DataExchangeWithExternalSystem Then
	
		If NewSYnchronizationSetting
			Or DIBSetup
			Or UniversalExchangeSetup Then
			DataReceivedForMapping = False;
		ElsIf IsExchangeWithApplicationInService Then
			DataReceivedForMapping = DataExchangeServer.MessageWithDataForMappingReceived(ExchangeNode);
		Else
			If TransportKind = Enums.ExchangeMessagesTransportTypes.COM
				Or TransportKind = Enums.ExchangeMessagesTransportTypes.WS
				Or TransportKind = Enums.ExchangeMessagesTransportTypes.WSPassiveMode
				Or Not TransportSettingsAvailable Then
				DataReceivedForMapping = DataExchangeServer.MessageWithDataForMappingReceived(ExchangeNode);
			Else
				DataReceivedForMapping = True;
			EndIf;
		EndIf;
		
	EndIf;
	
	SettingsValuesForOption = DataExchangeServer.ExchangePlanSettingValue(ExchangePlanName,
		"InitialImageCreationFormName,
		|DataSyncSettingsWizardFormName",
		SettingID);
	FillPropertyValues(ThisObject, SettingsValuesForOption);
	
	If IsBlankString(InitialImageCreationFormName)
		AND Common.SubsystemExists("StandardSubsystems.FilesOperations") Then
		InitialImageCreationFormName = "CommonForm.[InitialImageCreationForm]";
		InitialImageCreationFormName = StrReplace(InitialImageCreationFormName,
			"[InitialImageCreationForm]", "CreateInitialImageWithFiles");
	EndIf;
	
	CurrentSetupStep = "";
	If NewSYnchronizationSetting Then
		CurrentSetupStep = "ConnectionSetup";
	ElsIf DataExchangeWithExternalSystem
		AND Not XDTOCorrespondentSettingsReceived(ExchangeNode) Then
		CurrentSetupStep = "ConnectionConfirmation";
	ElsIf Not SynchronizationSetupCompleted(ExchangeNode) Then
		CurrentSetupStep = "RulesSetting";
	ElsIf DIBSetup
		AND Not ContinueSetupInSubordinateDIBNode
		AND Not InitialImageCreated(ExchangeNode) Then
		If Not IsBlankString(InitialImageCreationFormName) Then
			CurrentSetupStep = "InitialDIBImage";
		EndIf;
	EndIf;
	
	AllSetupSteps = New Structure;
	AllSetupSteps.Insert("ConnectionSetup",     "Main");
	AllSetupSteps.Insert("ConnectionConfirmation", "Main");
	AllSetupSteps.Insert("RulesSetting",          "Main");
	AllSetupSteps.Insert("InitialDIBImage",        "Main");
	AllSetupSteps.Insert("MapAndImport",   "Main");
	AllSetupSteps.Insert("InitialDataExport",  "Main");
	
EndProcedure

&AtClient
Function AddSetupStage(Name, Button)
	
	StageString = SetupSteps.Add();
	StageString.Name     = Name;
	StageString.Button       = Button;
	StageString.StandardFont = New Font(Items[Button].Font, , , False);
	StageString.BoldFont  = New Font(Items[Button].Font, , , True);
	
	Return StageString;
	
EndFunction

&AtClient
Procedure FillSetupStagesTable()
	
	SetupSteps.Clear();
	
	If TransportSettingsAvailable
		Or NewSYnchronizationSetting Then
		AddSetupStage("ConnectionSetup", "SetUpConnectionParameters");
	EndIf;
	
	If DataExchangeWithExternalSystem Then
		AddSetupStage("ConnectionConfirmation", "GetConnectionConfirmation");
	EndIf;
	
	AddSetupStage("RulesSetting", "SetSendingAndReceivingRules");
	
	If DataExchangeWithExternalSystem Then
		Return;
	EndIf;
	
	If DIBSetup
		AND Not ContinueSetupInSubordinateDIBNode
		AND Not IsBlankString(InitialImageCreationFormName) Then
		AddSetupStage("InitialDIBImage", "CreateInitialDIBImage");
	EndIf;
	
	If Not DIBSetup
		AND Not UniversalExchangeSetup
		AND DataReceivedForMapping Then
		AddSetupStage("MapAndImport", "MapAndExportData");
	EndIf;
		
	If InteractiveSendingAvailable
		AND (TransportSettingsAvailable
			Or NewSYnchronizationSetting) Then
		AddSetupStage("InitialDataExport", "ExecuteInitialDataExport");
	EndIf;
	
EndProcedure

&AtServer
Procedure SetInitialFormItemsView()
	
	Items.ExchangeBriefInfoLabelDecoration.Title = SettingOptionDetails.ExchangeBriefInfo;
	Items.DataSyncDetails.Visible = ValueIsFilled(SettingOptionDetails.ExchangeDetailedInformation);
	Items.BackupGroup.Visible = Backup;
	Items.GetConnectionConfirmation.ExtendedTooltip.Title = StrReplace(
		Items.GetConnectionConfirmation.ExtendedTooltip.Title,
		"%CorrespondentDescription%",
		SettingOptionDetails.CorrespondentDescription);
		
	If Backup Then
		LabelPartsBackup = New Array;
		LabelPartsBackup.Add(NStr("ru = 'Перед началом настройки новой синхронизации данных рекомендуется'; en = 'Before you start configuring new data synchronization, it is recommended that you'; pl = 'Przed rozpoczęciem konfiguracji nowej synchronizacji danych zalecane jest';de = 'Vor dem Einrichten wird eine neue Datensynchronisation empfohlen';ro = 'Înainte de a începe setarea unei noi sincronizări de date recomandăm';tr = 'Yeni veri eşleşme ayarlarından önce '; es_ES = 'Antes de empezar a ajustar una sincronización nueva de los datos se recomienda'"));
		LabelPartsBackup.Add(" ");
		LabelPartsBackup.Add(
			New FormattedString(NStr("ru = 'создать резервную копию данных'; en = 'back up your data'; pl = 'tworzenie kopii zapasowej danych';de = 'Daten sichern';ro = 'să creați copia de rezervă a datelor';tr = 'veri yedeklemeniz önerilir'; es_ES = 'crear una copia de respaldo de datos'"), , , , BackupDataProcessorURL));
		LabelPartsBackup.Add(".");
		
		Items.BackupLabelDecoration.Title = New FormattedString(LabelPartsBackup);
	EndIf;
	
EndProcedure

#EndRegion

#EndRegion