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
	
	SetConditionalAppearance();
	
	CheckDataSynchronizationSettingPossibility(Cancel);
	
	If Cancel Then
		Return;
	EndIf;
	
	URL = "e1cib/app/CommonForm.DataSynchronization";
	
	InitializeFormAttributes();
	
	SetFormItemsView();
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	RefreshDashboardDataInteractively();
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If    EventName = "DataExchangeCompleted"
		Or EventName = "Write_DataExchangeScenarios"
		Or EventName = "Write_ExchangePlanNode"
		Or EventName = "ObjectMappingWizardFormClosed"
		Or EventName = "DataExchangeResultFormClosed" Then
		
		RefreshDashboardDataInBackground();
		
	ElsIf EventName = "DataExchangeCreationWizardFormClosed" Then
		
		RefreshDashboardDataInteractively();
		
	EndIf;
	
EndProcedure

#EndRegion

#Region NodesStatesListFormTableItemsEventHandlers

&AtClient
Procedure ApplicationsListSelection(Item, RowSelected, Field, StandardProcessing)
	
	CurrentData = Items.ApplicationsList.CurrentData;
		
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	OpenSynchronizationParametersSettingsForm(CurrentData);
	
EndProcedure

&AtClient
Procedure ApplicationsListOnActivateRow(Item)
	
	CurrentData = Items.ApplicationsList.CurrentData;
	
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	Items.ApplicationsListInitialDataExport.Enabled =
		CurrentData.InteractiveSendingAvailable AND Not CurrentData.StartDataExchangeFromCorrespondent;
		
	Items.ApplicationsListRunSyncWithAdditionalFilters.Enabled =
		CurrentData.InteractiveSendingAvailable AND Not CurrentData.StartDataExchangeFromCorrespondent;
	
EndProcedure

#EndRegion

#Region FormCommandHandlers

&AtClient
Procedure RunSync(Command)
	
	SynchronizationExecutionCommandProcessing();
	
EndProcedure

&AtClient
Procedure RunSyncWithAdditionalFilters(Command)
	
	SynchronizationExecutionCommandProcessing(True);
	
EndProcedure

&AtClient
Procedure ConfigureDataExchangeScenarios(Command)
	
	CurrentData = Items.ApplicationsList.CurrentData;
	
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	DataExchangeClient.SetExchangeExecutionScheduleCommandProcessing(CurrentData.InfobaseNode, ThisObject);
	
EndProcedure

&AtClient
Procedure RefreshScreen(Command)
	
	RefreshDashboardDataInteractively();
	
EndProcedure

&AtClient
Procedure ChangeInfobaseNode(Command)
	
	CurrentData = Items.ApplicationsList.CurrentData;
		
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	OpenSynchronizationParametersSettingsForm(CurrentData);
	
EndProcedure

&AtClient
Procedure GoToDataImportEventLog(Command)
	
	GoToEventLog("DataImport");
	
EndProcedure

&AtClient
Procedure GoToDataExportEventLog(Command)
	
	GoToEventLog("DataExport");
	
EndProcedure

&AtClient
Procedure InstallUpdate(Command)
	
	DataExchangeClient.InstallConfigurationUpdate();
	
EndProcedure

&AtClient
Procedure ExchangeInfo(Command)

	CurrentData = Items.ApplicationsList.CurrentData;
	
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	ReferenceToDetails = DetailedInformationAtServer(CurrentData.InfobaseNode);
	
	DataExchangeClient.OpenSynchronizationDetails(ReferenceToDetails);
	
EndProcedure

&AtClient
Procedure OpenDataSyncResults(Command)
	
	DataExchangeClient.OpenDataExchangeResults(UsedNodesArray(ApplicationsList));
	
EndProcedure

&AtClient
Procedure CompositionOfDataToSend(Command)
	
	CurrentData = Items.ApplicationsList.CurrentData;
	
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	DataExchangeClient.OpenCompositionOfDataToSend(CurrentData.InfobaseNode);
	
EndProcedure

&AtClient
Procedure CreateSyncSetting(Command)
	
	DataExchangeClient.OpenNewDataSynchronizationSettingForm(NewDataSyncForm,
		NewDataSyncFormParameters);
	
EndProcedure

&AtClient
Procedure DeleteSynchronizationSetting(Command)
	
	CurrentData = Items.ApplicationsList.CurrentData;
	
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	If CurrentData.IsExchangeWithApplicationInService 
		AND CurrentData.SynchronizationSetupInServiceManager Then
			
		ShowMessageBox(, NStr("ru = 'Для удаления настройки синхронизации данных перейдите в менеджер сервиса.
			|В менеджере сервиса воспользуйтесь командой ""Синхронизация данных"".'; 
			|en = 'To delete data synchronization settings, go to the service manager.
			|In the service manager, click ""Data synchronization"".'; 
			|pl = 'Aby usunąć ustawienia synchronizacji danych, przejdź do menedżera serwisu. 
			|W menedżerze serwisu użyj polecenia ""Synchronizacja danych"".';
			|de = 'Um die Einstellung für die Datensynchronisation zu löschen, gehen Sie zum Service Manager.
			|Verwenden Sie im Service Manager den Befehl ""Datensynchronisation"".';
			|ro = 'Pentru a șterge setările de sincronizare a datelor, mergeți la managerul de servicii.
			|În managerul de servicii utilizați comanda ""Sincronizarea datelor"".';
			|tr = 'Veri senkronizasyonunu ayarlamak için servis yöneticisine gidin. 
			|Servis yöneticisinde ""Veri Senkronizasyonu"" komutunu kullanın.'; 
			|es_ES = 'Para eliminar el ajuste de sincronización de datos, pase al gestor de servicio.
			|En el gestor de servicio, utilice el comando ""Sincronización de datos"".'"));
		
	Else
		
		WizardParameters = New Structure;
		WizardParameters.Insert("ExchangeNode",                   CurrentData.InfobaseNode);
		WizardParameters.Insert("ExchangePlanName",               CurrentData.ExchangePlanName);
		WizardParameters.Insert("CorrespondentDataArea",  CurrentData.DataArea);
		WizardParameters.Insert("CorrespondentDescription",   CurrentData.CorrespondentDescription);
		WizardParameters.Insert("IsExchangeWithApplicationInService", CurrentData.IsExchangeWithApplicationInService);
		
		OpenForm("DataProcessor.DataExchangeCreationWizard.Form.DeleteSyncSetting",
			WizardParameters, ThisObject, , , , , FormWindowOpeningMode.LockOwnerWindow);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure ImportDataSyncRules(Command)
	
	CurrentData = Items.ApplicationsList.CurrentData;
	
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	ExchangePlanInfo = ExchangePlanInfo(CurrentData.ExchangePlanName);
	
	If ExchangePlanInfo.ConversionRulesAreUsed Then
		DataExchangeClient.ImportDataSyncRules(ExchangePlanInfo.ExchangePlanName);
	Else
		RulesKind = PredefinedValue("Enum.DataExchangeRulesTypes.ObjectsRegistrationRules");
		
		Filter              = New Structure("ExchangePlanName, RulesKind", ExchangePlanInfo.ExchangePlanName, RulesKind);
		FillingValues = New Structure("ExchangePlanName, RulesKind", ExchangePlanInfo.ExchangePlanName, RulesKind);
		DataExchangeClient.OpenInformationRegisterWriteFormByFilter(Filter, FillingValues, "DataExchangeRules", 
			CurrentData.InfobaseNode, "ObjectsRegistrationRules");
		
	EndIf;
	
EndProcedure

&AtClient
Procedure InitialDataExport(Command)
	
	CurrentData = Items.ApplicationsList.CurrentData;
	
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	DataToCompleteSetup = Undefined;
	If ContinueNewSynchronizationSetup(CurrentData, DataToCompleteSetup) Then
		AdditionalParameters = New Structure;
		AdditionalParameters.Insert("CurrentData",                CurrentData);
		AdditionalParameters.Insert("DataToCompleteSetup", DataToCompleteSetup);
		
		CompletionNotification = New NotifyDescription("QuestionContinueSynchronizationSetupCompletion", ThisObject, AdditionalParameters);
		ShowQueryBox(CompletionNotification,
			NStr("ru = 'Перед выгрузкой данных для сопоставления необходимо завершить настройку синхронизации.
			|Открыть форму помощника настройки?'; 
			|en = 'Before exporting data for mapping, please complete the synchronization setup.
			|Do you want to open the setup wizard?'; 
			|pl = 'Przed eksportowaniem danych dla porównania należy zakończyć ustawienie synchronizacji. 
			|Otworzyć formularz asystenta ustawienia?';
			|de = 'Die Synchronisationseinstellung muss abgeschlossen sein, bevor die Daten zum Vergleich hochgeladen werden.
			|Das Setup-Assistent Formular öffnen?';
			|ro = 'Înainte de descărcarea datelor pentru confruntare trebuie să finalizați setarea sincronizării.
			|Deschideți forma asistentului setării?';
			|tr = 'Verileri kaldırmadan önce eşlemek için eşitleme ayarını tamamlamanız gerekir. 
			|Kurulum Asistanı formunu açmak istiyor musunuz?'; 
			|es_ES = 'Antes de subir los datos para comparar es necesario terminar el ajuste de sincronización.
			|¿Abrir el formulario del ayudante de ajuste?'"),
			QuestionDialogMode.YesNo);
	ElsIf Not CurrentData.InteractiveSendingAvailable Then
		ShowMessageBox(, NStr("ru = 'Для выбранного варианта настройки синхронизации выгрузка данных для сопоставления не поддерживается.'; en = 'Exporting data for mapping is not supported for the selected synchronization setup option.'; pl = 'Dla wybranego wariantu ustawienia synchronizacji eksportowanie danych dla porównania nie jest obsługiwane.';de = 'Der Export von Daten zum Vergleich wird für die gewählte Synchronisationseinstellung nicht unterstützt.';ro = 'Pentru varianta selectată de setare a sincronizării nu este susținută descărcarea datelor pentru confruntare.';tr = 'Seçilen eşleştirme ayarı seçeneği için, eşleme için veri yükleme desteklenmez.'; es_ES = 'Para la opción seleccionada del ajuste de sincronización la subida de datos para comparar no se admite.'"));
		Return;
	Else
		WizardParameters = New Structure;
		WizardParameters.Insert("ExchangeNode", CurrentData.InfobaseNode);
		WizardParameters.Insert("IsExchangeWithApplicationInService", CurrentData.IsExchangeWithApplicationInService);
		WizardParameters.Insert("CorrespondentDataArea", CurrentData.DataArea);
		
		ClosingNotification = New NotifyDescription("InitialDataExportCompletion", ThisObject);
		OpenForm("DataProcessor.InteractiveDataExchangeWizard.Form.ExportMappingData",
			WizardParameters, ThisObject, , , , ClosingNotification, FormWindowOpeningMode.LockOwnerWindow);
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SetConditionalAppearance()
	
	ConditionalAppearance.Items.Clear();
	
	// Dull font color is used for configured but never run synchronization.
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ApplicationsListStatePresentation.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("ApplicationsList.StatePresentation");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = NStr("ru = 'Не запускалась'; en = 'Not started yet'; pl = 'Nie było wykonywane';de = 'Nicht gestartet';ro = 'Nu a fost executată';tr = 'Başlatılmadı'; es_ES = 'No se lanzaba'");
	Item.Appearance.SetParameterValue("TextColor", StyleColors.InaccessibleCellTextColor);
	
	// "N/a" text and a dull font color for the missing prefix of the correspondent application.
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ApplicationsListCorrespondentPrefix.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("ApplicationsList.CorrespondentPrefix");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	Item.Appearance.SetParameterValue("TextColor", StyleColors.InaccessibleCellTextColor);
	Item.Appearance.SetParameterValue("Text", NStr("ru = 'н/д'; en = 'n/a'; pl = 'd/p';de = 'n/d';ro = 'f/d';tr = 'n/d'; es_ES = 'н/д'"));
	
	// Special font color of the synchronization with incomplete setup.
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ApplicationsListStatePresentation.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("ApplicationsList.StatePresentation");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = NStr("ru = 'Настройка не завершена'; en = 'Setup pending'; pl = 'Ustawienie nie jest zakończone';de = 'Setup nicht abgeschlossen';ro = 'Setarea nu este finalizată';tr = 'Ayarlar tamamlanmadı'; es_ES = 'Ajuste no terminado'");
	Item.Appearance.SetParameterValue("TextColor", WebColors.DarkRed);
	
	// Hiding a blank picture of data synchronization state.
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ApplicationsListStatePicture.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("ApplicationsList.StatePicture");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = 0;
	
	Item.Appearance.SetParameterValue("Show", False);
	
	// Hiding a blank picture of data export state.
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ApplicationsListExportStatePicture.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("ApplicationsList.ExportStatePicture");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = 0;
	
	Item.Appearance.SetParameterValue("Show", False);
	
	// Hiding a blank picture of data import state.
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ApplicationsListImportStatePicture.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("ApplicationsList.ImportStatePicture");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = 0;
	
	Item.Appearance.SetParameterValue("Show", False);
		
EndProcedure

&AtClient
Procedure QuestionContinueSynchronizationSetupCompletion(QuestionResult, AdditionalParameters) Export
	
	If Not QuestionResult = DialogReturnCode.Yes Then
		Return;
	EndIf;
	
	OpenNewSynchronizationSetupWizardForm(
		AdditionalParameters.CurrentData,
		AdditionalParameters.DataToCompleteSetup);
		
EndProcedure

&AtClient
Procedure InitialDataExportCompletion(ClosingResult, AdditionalParameters) Export
	
	AttachIdleHandler("RefreshDashboardDataInteractively", 0.1, True);
	
EndProcedure

&AtClient
Procedure OpenSynchronizationParametersSettingsForm(CurrentData)
	
	DataToCompleteSetup = Undefined;
	If ContinueNewSynchronizationSetup(CurrentData, DataToCompleteSetup) Then
		OpenNewSynchronizationSetupWizardForm(CurrentData, DataToCompleteSetup);
		Return;
	EndIf;
		
	OpenExchangePlanNodeForm(CurrentData);
	
EndProcedure

&AtClient
Function ContinueNewSynchronizationSetup(CurrentData, DataToCompleteSetup)
	
	ApplicationRow = New Structure("InfobaseNode, ExchangePlanName, CorrespondentVersion, ExternalSystem");
	FillPropertyValues(ApplicationRow, CurrentData);
	
	DataToCompleteSetup = Undefined;
	
	Return Not SynchronizationSetupCompleted(ApplicationRow, DataToCompleteSetup);
	
EndFunction

&AtClient
Procedure OpenNewSynchronizationSetupWizardForm(CurrentData, DataToCompleteSetup)
	
	WizardParameters = New Structure;
	WizardParameters.Insert("ExchangeNode",             CurrentData.InfobaseNode);
	WizardParameters.Insert("ExchangePlanName",         CurrentData.ExchangePlanName);
	WizardParameters.Insert("SettingID", DataToCompleteSetup.SettingID);
	
	If SaaSModel Then
		WizardParameters.Insert("CorrespondentDataArea",  CurrentData.DataArea);
		WizardParameters.Insert("IsExchangeWithApplicationInService", CurrentData.IsExchangeWithApplicationInService);
	EndIf;
	
	WizardParameters.Insert("SettingOptionDetails", DataToCompleteSetup.SettingOptionDetails);
	
	ClosingNotification = New NotifyDescription("OpenSynchronizationParametersSettingsFormCompletion", ThisObject);
	
	If CurrentData.ExternalSystem Then
		WizardParameters.Insert("DataExchangeWithExternalSystem", True);
		
		BackgroundJob = BackgroundJobSettingsOptionsOfDataExchangeWithExternalSystems(
			WizardParameters.ExchangeNode, UUID);
		
		If Not BackgroundJob = Undefined Then
			AdditionalParameters = New Structure;
			AdditionalParameters.Insert("WizardParameters",  WizardParameters);
			AdditionalParameters.Insert("ClosingNotification", ClosingNotification);
			
			CompletionNotification = New NotifyDescription(
				"OnCompleteGettingSettingsOptionsOfDataExchangeWithExternalSystems", ThisObject, AdditionalParameters);
	
			IdleParameters = TimeConsumingOperationsClient.IdleParameters(ThisObject);
			IdleParameters.OutputIdleWindow = True;
			
			TimeConsumingOperationsClient.WaitForCompletion(BackgroundJob, CompletionNotification, IdleParameters);
		EndIf;
		Return;
	EndIf;
	
	WizardUniqueKey = WizardParameters.ExchangePlanName
		+ "_" + WizardParameters.SettingID + "_" + WizardParameters.ExchangeNode.UUID();
	
	OpenForm("DataProcessor.DataExchangeCreationWizard.Form.SyncSetup",
		WizardParameters, ThisObject, WizardUniqueKey, , , ClosingNotification, FormWindowOpeningMode.Independent);
	
EndProcedure
	
&AtClient
Procedure OpenExchangePlanNodeForm(CurrentData)
	
	WizardFormName = StrReplace("ExchangePlan.[ExchangePlanName].ObjectForm", "[ExchangePlanName]", CurrentData.ExchangePlanName);
	
	WizardParameters = New Structure;
	WizardParameters.Insert("Key", CurrentData.InfobaseNode);
	
	ClosingNotification = New NotifyDescription("OpenSynchronizationParametersSettingsFormCompletion", ThisObject);
	
	OpenForm(WizardFormName,
		WizardParameters, ThisObject, , , , ClosingNotification, FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure OpenSynchronizationParametersSettingsFormCompletion(ClosingResult, AdditionalParameters) Export
	
	AttachIdleHandler("RefreshDashboardDataInteractively", 0.1, True);
	
EndProcedure

&AtClient
Procedure OnCompleteGettingSettingsOptionsOfDataExchangeWithExternalSystems(Result, AdditionalParameters) Export
	
	If Result.Status = "Completed" Then
		
		Cancel = False;
		ErrorMessage = "";
		ProcessReceivingSettingsOptionsResultAtServer(
			Result.ResultAddress, Cancel, ErrorMessage, AdditionalParameters.WizardParameters);
			
		If Cancel Then
			ShowMessageBox(, ErrorMessage);
		Else
			OpenForm("DataProcessor.DataExchangeCreationWizard.Form.SyncSetup",
				AdditionalParameters.WizardParameters, ThisObject, , , , AdditionalParameters.ClosingNotification, FormWindowOpeningMode.Independent);
		EndIf;
			
	ElsIf Result.Status = "Error" Then
			
		ShowMessageBox(, Result.BriefErrorPresentation);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure SynchronizationExecutionCommandProcessing(UseAdditionalFilters = False)
	
	CurrentData = Items.ApplicationsList.CurrentData;
	
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	DataToCompleteSetup = Undefined;
	If ContinueNewSynchronizationSetup(CurrentData, DataToCompleteSetup) Then
		AdditionalParameters = New Structure;
		AdditionalParameters.Insert("CurrentData",                CurrentData);
		AdditionalParameters.Insert("DataToCompleteSetup", DataToCompleteSetup);
		
		CompletionNotification = New NotifyDescription("QuestionContinueSynchronizationSetupCompletion", ThisObject, AdditionalParameters);
		ShowQueryBox(CompletionNotification,
			NStr("ru = 'Перед запуском синхронизации данных необходимо завершить ее настройку.
			|Открыть форму помощника настройки?'; 
			|en = 'Before starting data synchronization, please complete the synchronization setup.
			|Do you want to open the setup wizard ?'; 
			|pl = 'Przed uruchomieniem synchronizacji należy zakończyć jej ustawienie. 
			|Otworzyć formularz asystenta ustawienia?';
			|de = 'Bevor Sie mit der Datensynchronisation beginnen, müssen Sie die Konfiguration abschließen.
			|Das Formular Setup Assistent öffnen?';
			|ro = 'Înainte de lansarea sincronizării datelor trebuie să finalizați setarea ei.
			|Deschideți forma asistentului setării?';
			|tr = 'Verileri eşleştirmeye başlamadan önce, yapılandırma tamamlanmalıdır. 
			| Kurulum Asistanı formunu açmak istiyor musunuz?'; 
			|es_ES = 'Antes de lanzar la sincronización de datos es necesario terminar su ajuste,
			|¿Abrir el formulario del ayudante de ajuste?'"),
			QuestionDialogMode.YesNo);
	ElsIf CurrentData.StartDataExchangeFromCorrespondent
		AND Not EmailReceivedForDataMapping(CurrentData.InfobaseNode) Then
		ShowMessageBox(, StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Запуск синхронизации с ""%1"" из этой программы не поддерживается.
			|Перейдите в ""%1"" и запустите синхронизацию из нее.'; 
			|en = 'Starting synchronization with %1 from this application is not supported.
			|Please open %1 and start the synchronization from there.'; 
			|pl = 'Uruchomienie synchronizacji z ""%1"" z tego programu nie jest obsługiwane. 
			|Przejdź do ""%1"" i uruchom synchronizację z niego.';
			|de = 'Das Starten der Synchronisation mit ""%1"" aus diesem Programm wird nicht unterstützt.
			|Gehen Sie zu ""%1"" und starten Sie die Synchronisation daraus.';
			|ro = 'Lansarea sincronizării cu ""%1"" din acest program nu este susținută.
			|Treceți în ""%1"" și lansați sincronizarea din ea.';
			|tr = 'Bu uygulamadan ""%1"" ''den eşleştirmesi başlatılamıyor.  
			| ""%1"" ''e geçin ve eşleştirmeyi oradan başlatın.'; 
			|es_ES = 'El lanzamiento de sincronización con ""%1"" de este programa no se admiten.
			|Pase a ""%1"" y lance de allí la sincronización.'"), CurrentData.CorrespondentDescription));
	Else
		AdditionalParameters = New Structure;
		AdditionalParameters.Insert("ExchangeNode",     CurrentData.InfobaseNode);
		AdditionalParameters.Insert("ExchangePlanName", CurrentData.ExchangePlanName);
		
		AdditionalParameters.Insert("IsExchangeWithApplicationInService", CurrentData.IsExchangeWithApplicationInService);
		AdditionalParameters.Insert("CorrespondentDataArea",  CurrentData.DataArea);
		
		AdditionalParameters.Insert("UseAdditionalFilters",                   UseAdditionalFilters);
		AdditionalParameters.Insert("InteractiveSendingAvailable",           CurrentData.InteractiveSendingAvailable);
		AdditionalParameters.Insert("DataExchangeOption",                    CurrentData.DataExchangeOption);
		AdditionalParameters.Insert("EmailReceivedForDataMapping", EmailReceivedForDataMapping(CurrentData.InfobaseNode));
		AdditionalParameters.Insert("StartDataExchangeFromCorrespondent",            CurrentData.StartDataExchangeFromCorrespondent);
		
		ContinuationDetails = New NotifyDescription("ContinueSynchronizationExecution", ThisObject, AdditionalParameters);
			
		If CurrentData.IsExchangeWithApplicationInService Then
			ExecuteNotifyProcessing(ContinuationDetails);
		Else
			CheckConversionRulesCompatibility(ContinuationDetails);
		EndIf;
	EndIf;
	
EndProcedure

&AtServerNoContext
Function BackgroundJobSettingsOptionsOfDataExchangeWithExternalSystems(
		ExchangeNode,
		UUID)
	
	BackgroundJob = Undefined;
	
	If Common.SubsystemExists("OnlineUserSupport.DataExchangeWithExternalSystems") Then
		ModuleWizard = DataExchangeServer.ModuleDataExchangeCreationWizard();
		SettingsOptions = ModuleWizard.ExternalSystemsDataExchangeSettingsOptionDetails();
		
		ProcedureParameters = New Structure;
		ProcedureParameters.Insert("SettingVariants", SettingsOptions);
		ProcedureParameters.Insert("ExchangeNode",       ExchangeNode);
		
		ExecutionParameters = TimeConsumingOperations.BackgroundExecutionParameters(UUID);
		ExecutionParameters.BackgroundJobDescription = NStr("ru = 'Получение доступных вариантов настроек обмена данными с внешними системами.'; en = 'Get available setup options for data exchange with external systems'; pl = 'Uzyskiwanie dostępnych opcji ustawiania wymiany danych z systemami zewnętrznymi.';de = 'Verfügbare Optionen zum Einstellen des Datenaustauschs mit externen Systemen erhalten.';ro = 'Obținerea variantelor disponibile ale setărilor schimbului de date cu sistemele externe.';tr = 'Harici sistemlerle veri alışverişi için kullanılabilir seçeneklerin elde edilmesi.'; es_ES = 'Recepción de variantes disponibles de ajustes de cambio de datos con sistemas externos.'");
		ExecutionParameters.RunInBackground = True;
		
		BackgroundJob = TimeConsumingOperations.ExecuteInBackground(
			"DataExchangeWithExternalSystems.OnGetDataExchangeSettingsOptions",
			ProcedureParameters,
			ExecutionParameters);
	EndIf;
	
	Return BackgroundJob;
	
EndFunction

&AtServerNoContext
Procedure ProcessReceivingSettingsOptionsResultAtServer(ResultAddress, Cancel, ErrorMessage, WizardParameters)
	
	Result = GetFromTempStorage(ResultAddress);
	
	If Not ValueIsFilled(Result.ErrorCode) Then
		Filter = New Structure("ExchangePlanName, SettingID");
		FillPropertyValues(Filter, WizardParameters);
		
		SettingsOptionsRows = Result.SettingVariants.FindRows(Filter);
		If SettingsOptionsRows.Count() > 0 Then
			FillPropertyValues(WizardParameters.SettingOptionDetails, SettingsOptionsRows[0]);
		Else
			Cancel = True;
			ErrorMessage = NStr("ru = 'Настройка подключения к данному сервису недоступна.'; en = 'There are no connections settings available for this service.'; pl = 'Ustawienie połączenia do tej usługi nie jest dostępne.';de = 'Die Verbindungseinstellung für diesen Dienst ist nicht verfügbar.';ro = 'Setarea de conectare la acest serviciu nu este accesibilă.';tr = 'Bu servise bağlantı ayarları mevcut değil.'; es_ES = 'El ajuste de conexión a este servicio no está disponible.'");
		EndIf;
	Else
		Cancel = True;
		If ValueIsFilled(Result.ErrorCode) Then
			ErrorMessage = Result.ErrorMessage;
		EndIf;
	EndIf;
	
	DeleteFromTempStorage(ResultAddress);
	
EndProcedure

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

&AtServerNoContext
Function SynchronizationSetupCompleted(ApplicationRow, DataToCompleteSetup = Undefined)
	
	ModuleWizard = DataExchangeServer.ModuleDataExchangeCreationWizard();
	SettingOptionDetails = ModuleWizard.SettingOptionDetailsStructure();
	
	SettingID = DataExchangeServer.SavedExchangePlanNodeSettingOption(
		ApplicationRow.InfobaseNode);
		
	If Not ApplicationRow.ExternalSystem Then
		SettingsValuesForOption = DataExchangeServer.ExchangePlanSettingValue(ApplicationRow.ExchangePlanName,
			"CorrespondentConfigurationDescription,
			|NewDataExchangeCreationCommandTitle,
			|ExchangeCreateWizardTitle,
			|ExchangeBriefInfo,
			|ExchangeDetailedInformation",
			SettingID,
			ApplicationRow.CorrespondentVersion);
			
		FillPropertyValues(SettingOptionDetails, SettingsValuesForOption);
		SettingOptionDetails.CorrespondentDescription = SettingsValuesForOption.CorrespondentConfigurationDescription;
	EndIf;
	
	DataToCompleteSetup = New Structure;
	DataToCompleteSetup.Insert("SettingID",    SettingID);
	DataToCompleteSetup.Insert("SettingOptionDetails", SettingOptionDetails);
	
	Return DataExchangeServer.SynchronizationSetupCompleted(ApplicationRow.InfobaseNode);
	
EndFunction

&AtServerNoContext
Function ExchangePlanInfo(ExchangePlanName)
	
	Result = New Structure;
	Result.Insert("ExchangePlanName", ExchangePlanName);
	Result.Insert("ConversionRulesAreUsed",
		DataExchangeCached.HasExchangePlanTemplate(ExchangePlanName, "ExchangeRules"));
	
	Return Result;
	
EndFunction

&AtClient
Procedure GoToEventLog(ActionOnExchange)
	
	CurrentData = Items.ApplicationsList.CurrentData;
	
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	DataExchangeClient.GoToDataEventLogModally(CurrentData.InfobaseNode,
		ThisObject, ActionOnExchange);

EndProcedure

&AtClient
Procedure RefreshDashboardDataInteractively()
	
	ApplicationsListLineIndex = GetCurrentRowIndex("ApplicationsList");
	
	If SaaSModel Then
		OnDashboardDataUpdateStart();
	Else
		RefreshApplicationsList();
		ExecuteCursorPositioning("ApplicationsList", ApplicationsListLineIndex);
	EndIf;
	
	AttachIdleHandler("RefreshDashboardDataInBackground", 60, True);
	
EndProcedure

&AtClient
Procedure RefreshDashboardDataInBackground()
	
	ApplicationsListLineIndex = GetCurrentRowIndex("ApplicationsList");
	
	UpdateSaaSApplications = SaaSModel;
	RefreshApplicationsList(UpdateSaaSApplications);
	
	If SaaSModel
		AND UpdateSaaSApplications Then
		OnStartUpdateMonitorDataInBackground();
	Else
		ExecuteCursorPositioning("ApplicationsList", ApplicationsListLineIndex);
	EndIf;
	
	AttachIdleHandler("RefreshDashboardDataInBackground", 60, True);
	
EndProcedure

&AtClient
Procedure OnDashboardDataUpdateStart()
	
	If Not ParametersOfGetApplicationsListIdleHandler = Undefined Then
		Return;
	EndIf;
	
	ParametersOfGetApplicationsListHandler = Undefined;
	ContinueWait = False;
	
	OnStartGettingApplicationsListAtServer(
		ParametersOfGetApplicationsListHandler, ContinueWait);
		
	If ContinueWait Then
		
		Items.ApplicationsListPanel.CurrentPage = Items.WaitPage;
		Items.CommandBar.Enabled = False;
		
		DataExchangeClient.InitializeIdleHandlerParameters(
			ParametersOfGetApplicationsListIdleHandler);
			
		AttachIdleHandler("OnWaitForDashboardDataRefresh",
			ParametersOfGetApplicationsListIdleHandler.CurrentInterval, True);
		
	Else
		OnCompleteDashboardDataRefresh();
	EndIf;
	
EndProcedure

&AtClient
Procedure OnWaitForDashboardDataRefresh()
	
	ContinueWait = False;
	OnWaitGettingApplicationsListAtServer(ParametersOfGetApplicationsListHandler, ContinueWait);
	
	If ContinueWait Then
		DataExchangeClient.UpdateIdleHandlerParameters(ParametersOfGetApplicationsListIdleHandler);
		
		AttachIdleHandler("OnWaitForDashboardDataRefresh",
			ParametersOfGetApplicationsListIdleHandler.CurrentInterval, True);
	Else
		ParametersOfGetApplicationsListIdleHandler = Undefined;
		OnCompleteDashboardDataRefresh();
	EndIf;
	
EndProcedure

&AtClient
Procedure OnCompleteDashboardDataRefresh()
	
	OnCompleteGettingApplicationsListAtServer();
	
	Items.ApplicationsListPanel.CurrentPage = Items.ApplicationsListPage;
	Items.CommandBar.Enabled = True;
	
EndProcedure

&AtClient
Procedure OnStartUpdateMonitorDataInBackground()
	
	If Not ParametersOfGetApplicationsListIdleHandler = Undefined Then
		Return;
	EndIf;
	
	ParametersOfGetApplicationsListHandler = Undefined;
	ContinueWait = False;
	
	OnStartGettingApplicationsListAtServer(
		ParametersOfGetApplicationsListHandler, ContinueWait);
		
	If ContinueWait Then
		
		DataExchangeClient.InitializeIdleHandlerParameters(
			ParametersOfGetApplicationsListIdleHandler);
			
		AttachIdleHandler("OnWaitForUpdateMonitorDataImBackround",
			ParametersOfGetApplicationsListIdleHandler.CurrentInterval, True);
		
	Else
		OnCompleteDashboardDataRefreshInBackground();
	EndIf;
	
EndProcedure

&AtClient
Procedure OnWaitForUpdateMonitorDataImBackround()
	
	ContinueWait = False;
	OnWaitGettingApplicationsListAtServer(ParametersOfGetApplicationsListHandler, ContinueWait);
	
	If ContinueWait Then
		DataExchangeClient.UpdateIdleHandlerParameters(ParametersOfGetApplicationsListIdleHandler);
		
		AttachIdleHandler("OnWaitForUpdateMonitorDataImBackround",
			ParametersOfGetApplicationsListIdleHandler.CurrentInterval, True);
	Else
		ParametersOfGetApplicationsListIdleHandler = Undefined;
		OnCompleteDashboardDataRefreshInBackground();
	EndIf;
	
EndProcedure

&AtClient
Procedure OnCompleteDashboardDataRefreshInBackground()
	
	OnCompleteGettingApplicationsListAtServer();
	ExecuteCursorPositioning("ApplicationsList", ApplicationsListLineIndex);
	
EndProcedure

&AtServerNoContext
Procedure OnStartGettingApplicationsListAtServer(HandlerParameters, ContinueWait)
	
	ModuleSetupWizard = DataExchangeServer.ModuleDataSynchronizationBetweenWebApplicationsSetupWizard();
	
	If ModuleSetupWizard = Undefined Then
		ContinueWait = False;
		Return;
	EndIf;
	
	WizardParameters = New Structure("Mode", "ConfiguredExchanges");
	
	ModuleSetupWizard.OnStartGetApplicationList(WizardParameters,
		HandlerParameters, ContinueWait);
	
EndProcedure

&AtServerNoContext
Procedure OnWaitGettingApplicationsListAtServer(HandlerParameters, ContinueWait)
	
	ModuleSetupWizard = DataExchangeServer.ModuleDataSynchronizationBetweenWebApplicationsSetupWizard();
	
	If ModuleSetupWizard = Undefined Then
		ContinueWait = False;
		Return;
	EndIf;
	
	ModuleSetupWizard.OnWaitForGetApplicationList(
		HandlerParameters, ContinueWait);
	
EndProcedure

&AtServer
Procedure OnCompleteGettingApplicationsListAtServer()
	
	SaaSApplications.Clear();
	
	ModuleSetupWizard = DataExchangeServer.ModuleDataSynchronizationBetweenWebApplicationsSetupWizard();
	
	If Not ModuleSetupWizard = Undefined Then
		CompletionStatus = Undefined;
		ModuleSetupWizard.OnCompleteGetApplicationList(
			ParametersOfGetApplicationsListHandler, CompletionStatus);
			
		If Not CompletionStatus.Cancel Then
			ApplicationsTable = CompletionStatus.Result;
			SaaSApplications.Load(ApplicationsTable.Copy(, "Correspondent, DataArea, ApplicationDescription"));
		EndIf;
	EndIf;
	
	RefreshApplicationsList();
	
EndProcedure

&AtServer
Procedure RefreshApplicationsList(UpdateSaaSApplications = False)
	
	Items.ApplicationsListPanel.CurrentPage = Items.ApplicationsListPage;
	Items.CommandBar.Enabled = True;
	
	SSLExchangePlans = DataExchangeCached.SSLExchangePlans();
	
	ApplicationsBeforeUpdate = ApplicationsList.Unload(, "InfobaseNode").UnloadColumn("InfobaseNode");
	DashboardTable = DataExchangeServer.DataExchangeMonitorTable(SSLExchangePlans);
	ApplicationsAfterUpdate = DashboardTable.UnloadColumn("InfobaseNode");
	
	HasConfiguredExchanges = (ApplicationsAfterUpdate.Count() > 0);
	
	If UpdateSaaSApplications
		AND HasConfiguredExchanges Then
		UpdateSaaSApplications = False;
		For Each Application In ApplicationsAfterUpdate Do
			If ApplicationsBeforeUpdate.Find(Application) = Undefined Then
				UpdateSaaSApplications = True;
				Return;
			EndIf;
		EndDo;
	EndIf;
	
	ApplicationsList.Load(DashboardTable);
	
	For Each ApplicationRow In ApplicationsList Do
		
		ApplicationRow.CorrespondentDescription = Common.ObjectAttributeValue(
			ApplicationRow.InfobaseNode, "Description");
			
		SaaSApplicationRows = SaaSApplications.FindRows(
			New Structure("Correspondent", ApplicationRow.InfobaseNode));
			
		If SaaSApplicationRows.Count() > 0 Then
			SaaSApplicationRow = SaaSApplicationRows[0];
			
			ApplicationRow.IsExchangeWithApplicationInService = True;
			ApplicationRow.DataArea = SaaSApplicationRow.DataArea;
			ApplicationRow.CorrespondentDescription = SaaSApplicationRow.ApplicationDescription;
		EndIf;
		
		If ApplicationRow.IsExchangeWithApplicationInService Then
			
			ApplicationRow.ApplicationOperationMode = 1;
			ApplicationRow.InteractiveSendingAvailable = True;
			
		Else
			
			TransportKind = InformationRegisters.DataExchangeTransportSettings.DefaultExchangeMessagesTransportKind(
				ApplicationRow.InfobaseNode);
			
			If TransportKind = Enums.ExchangeMessagesTransportTypes.WS
				Or TransportKind = Enums.ExchangeMessagesTransportTypes.ExternalSystem Then
				ApplicationRow.ApplicationOperationMode = 1; // service
			Else
				ApplicationRow.ApplicationOperationMode = 0;
			EndIf;
				
			If Not ValueIsFilled(TransportKind)
				Or (TransportKind = Enums.ExchangeMessagesTransportTypes.WSPassiveMode) Then
				// Exchange with this infobase is set up via WS.
				ApplicationRow.StartDataExchangeFromCorrespondent = True;
			EndIf;
			
			ApplicationRow.InteractiveSendingAvailable =
				Not DataExchangeCached.IsDistributedInfobaseExchangePlan(ApplicationRow.ExchangePlanName)
				AND Not DataExchangeCached.IsStandardDataExchangeNode(ApplicationRow.ExchangePlanName);
				
			ApplicationRow.ExternalSystem = (TransportKind = Enums.ExchangeMessagesTransportTypes.ExternalSystem);
			
		EndIf;
		
		ApplicationRow.InteractiveSendingAvailable = ApplicationRow.InteractiveSendingAvailable
			AND Not (ApplicationRow.DataExchangeOption = "ReceiveOnly");
		
		SynchronizationState = DataSynchronizationState(ApplicationRow);
		ApplicationRow.StatePresentation = SynchronizationState.Presentation;
		ApplicationRow.StatePicture      = SynchronizationState.Picture;
		
		If ValueIsFilled(ApplicationRow.LastRunDate) Then
			ApplicationRow.ExportStatePicture = ExecutionResultPicture(ApplicationRow.LastDataExportResult);
			
			If Not ApplicationRow.EmailReceivedForDataMapping Then
				ApplicationRow.ImportStatePicture = ExecutionResultPicture(ApplicationRow.LastDataImportResult);
			EndIf;
		Else
			// The Never label is not shown if synchronization has never run not to overload the interface.
			// 
			ApplicationRow.LastSuccessfulExportDatePresentation = "";
			ApplicationRow.LastSuccessfulImportDatePresentation = "";
		EndIf;
		
		If ApplicationRow.EmailReceivedForDataMapping Then
			// If data for mapping is received, display the message receiving date.
			ApplicationRow.LastSuccessfulImportDatePresentation = ApplicationRow.MessageDatePresentationForDataMapping;
			ApplicationRow.ImportStatePicture = 5;
		EndIf;
		
	EndDo;
	
	UpdateRequired = DataExchangeServer.UpdateInstallationRequired();
	
	SetFormItemsView();
	
	RefreshSynchronizationResultsCommand();
	
EndProcedure

&AtServerNoContext
Function DataSynchronizationState(ApplicationRow)
	
	State = New Structure;
	State.Insert("Presentation", "");
	State.Insert("Picture",      0);
	
	If Not ApplicationRow.SetupCompleted Then
		State.Presentation = NStr("ru = 'Настройка не завершена'; en = 'Setup pending'; pl = 'Ustawienie nie jest zakończone';de = 'Setup nicht abgeschlossen';ro = 'Setarea nu este finalizată';tr = 'Ayarlar tamamlanmadı'; es_ES = 'Ajuste no terminado'");
		State.Picture = 3;
		
		If ApplicationRow.EmailReceivedForDataMapping Then
			State.Presentation = NStr("ru = 'Настройка не завершена, получены данные для сопоставления'; en = 'Setup pending, received data to map'; pl = 'Ustawienie nie jest zakończone, odebrane dane do porównania';de = 'Konfiguration nicht abgeschlossen, Vergleichsdaten empfangen';ro = 'Setarea nu este finalizată, sunt primite datele pentru confruntare';tr = 'Ayarlar tamamlanmadı, karşılaştırılacak veriler elde edildi'; es_ES = 'Ajuste no finalizado, datos recibidos para comparar'");
		EndIf;
	Else
		If ApplicationRow.LastImportStartDate > ApplicationRow.LastImportEndDate Then
			State.Presentation = NStr("ru = 'Загрузка данных...'; en = 'Importing data...'; pl = 'Import danych...';de = 'Daten importieren...';ro = 'Se importă date...';tr = 'Veriler içe aktarılıyor...'; es_ES = 'Importando los datos...'");
			State.Picture = 4;
		ElsIf ApplicationRow.LastExportStartDate > ApplicationRow.LastExportEndDate Then
			State.Presentation = NStr("ru = 'Выгрузка данных...'; en = 'Exporting data...'; pl = 'Eksport danych...';de = 'Daten exportieren...';ro = 'Export de date...';tr = 'Veriler dışa aktarılıyor...'; es_ES = 'Exportando los datos...'");
			State.Picture = 4;
		ElsIf Not ValueIsFilled(ApplicationRow.LastRunDate) Then
			State.Presentation = NStr("ru = 'Не запускалась'; en = 'Not started yet'; pl = 'Nie było wykonywane';de = 'Nicht gestartet';ro = 'Nu a fost executată';tr = 'Başlatılmadı'; es_ES = 'No se lanzaba'");
			
			If ApplicationRow.EmailReceivedForDataMapping Then
				State.Presentation = NStr("ru = 'Получены данные для сопоставления'; en = 'Received data to map'; pl = 'Odebrane dane do porównania';de = 'Daten stehen zum Abgleich zur Verfügung';ro = 'Au fost primite datele pentru confruntare';tr = 'Karşılaştırılacak veriler elde edildi'; es_ES = 'Datos recibidos para comparar'");
			EndIf;
		Else
			State.Presentation = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'Прошлый запуск: %1'; en = 'Last started on: %1'; pl = 'Poprzednie uruchomienie: %1';de = 'Letzter Start: %1';ro = 'Lansarea precedentă: %1';tr = 'Geçmiş başlatma: %1'; es_ES = 'Lanzamiento anterior: %1'"),
				ApplicationRow.LastStartDatePresentation);
				
			If ApplicationRow.EmailReceivedForDataMapping Then
				State.Presentation = NStr("ru = 'Получены данные для сопоставления'; en = 'Received data to map'; pl = 'Odebrane dane do porównania';de = 'Daten stehen zum Abgleich zur Verfügung';ro = 'Au fost primite datele pentru confruntare';tr = 'Karşılaştırılacak veriler elde edildi'; es_ES = 'Datos recibidos para comparar'");
			EndIf;
		EndIf;
	EndIf;
	
	Return State;
	
EndFunction

&AtServerNoContext
Function ExecutionResultPicture(ExecutionResult)
	
	If ExecutionResult = 2 Then
		Return 3; // completed with warnings
	ElsIf ExecutionResult = 1 Then
		Return 2; // error
	ElsIf ExecutionResult = 0 Then
		Return 0; // success
	EndIf;
	
	// without status
	Return 0;
	
EndFunction

&AtServer
Procedure InitializeFormAttributes()
	
	HasExchangeAdministrationRight   = DataExchangeServer.HasRightsToAdministerExchanges();
	
	HasEventLogViewRight = AccessRight("EventLog", Metadata);
	HasRightToUpdate                 = AccessRight("UpdateDataBaseConfiguration", Metadata);
	
	IBPrefix = DataExchangeServer.InfobasePrefix();
	
	SaaSModel = Common.DataSeparationEnabled()
		AND Common.SeparatedDataUsageAvailable();
	
EndProcedure

&AtServer
Procedure SetFormItemsView()
	
	// Command bar.
	Items.ApplicationsListControlGroup.Visible                 = HasExchangeAdministrationRight;
	Items.ApplicationsListChangeAndCompositionGroup.Visible           = HasExchangeAdministrationRight AND HasConfiguredExchanges;
	Items.ApplicationsListDataExchangeExecutionGroup.Visible    = HasConfiguredExchanges;
	Items.ApplicationsListExchangeScheduleGroup.Visible = HasExchangeAdministrationRight AND HasConfiguredExchanges;
	Items.ApplicationsListEventsGroup.Visible                    = HasEventLogViewRight AND HasConfiguredExchanges;
	Items.ApplicationsListDeleteSyncSetting.Visible    = HasExchangeAdministrationRight AND HasConfiguredExchanges;
	
	// Context menu.
	Items.ApplicationsListContextMenuChangeAndContentGroup.Visible           = HasExchangeAdministrationRight AND HasConfiguredExchanges;
	Items.ApplicationsListContextMenuDataExchangeExecutionGroup.Visible    = HasConfiguredExchanges;
	Items.ApplicationsListContextMenuDataExchangeScheduleGroup.Visible = HasExchangeAdministrationRight AND HasConfiguredExchanges;
	Items.ApplicationsListContextMenuEventsGroup.Visible                    = HasEventLogViewRight AND HasConfiguredExchanges;
	Items.ApplicationsListContextMenuControlGroup.Visible                 = HasExchangeAdministrationRight AND HasConfiguredExchanges;
	
	// Item visibility in the form header.
	Items.InfoPanelUpdateRequired.Visible = UpdateRequired;
	
	If HasRightToUpdate Then
		Items.RefereshRightPage.CurrentPage = Items.DataExchangePausedHasRightToUpdateInfo;
	Else
		Items.RefereshRightPage.CurrentPage = Items.InfoDataExchangePausedNoRightToUpdate;
	EndIf;
	
	// Availability of items in the form header.
	Items.OpenDataSyncResults.Enabled = HasConfiguredExchanges;
	
	// Force disabling of visibility of commands of schedule setup and importing rules in SaaS.
	If SaaSModel Then
		
		// Command bar.
		Items.ApplicationsListImportDataSyncRules.Visible = False;
		Items.ApplicationsListExchangeScheduleGroup.Visible    = False;
		
		// Context menu.
		Items.ApplicationsListContextMenuDataExchangeScheduleGroup.Visible = False;
		
	EndIf;
	
EndProcedure

&AtServer
Procedure RefreshSynchronizationResultsCommand()
	
	TitleStructure = DataExchangeServer.IssueMonitorHyperlinkTitleStructure(
		UsedNodesArray(ApplicationsList));
	FillPropertyValues(Items.OpenDataSyncResults, TitleStructure);
	
EndProcedure

&AtClientAtServerNoContext
Function UsedNodesArray(DashboardTable)
	
	Result = New Array;
	
	For Each DashboardRow In DashboardTable Do
		Result.Add(DashboardRow.InfobaseNode);
	EndDo;
	
	Return Result;
	
EndFunction

&AtClient
Function GetCurrentRowIndex(TableName)
	
	// Function return value.
	RowIndex = Undefined;
	
	// Placing a mouse pointer upon refreshing the dashboard.
	CurrentData = Items[TableName].CurrentData;
	
	If CurrentData <> Undefined Then
		
		RowIndex = ThisObject[TableName].IndexOf(CurrentData);
		
	EndIf;
	
	Return RowIndex;
	
EndFunction

&AtClient
Procedure ExecuteCursorPositioning(TableName, RowIndex)
	
	If RowIndex <> Undefined Then
		
		// Checking the mouse pointer position once the new data is received.
		If ThisObject[TableName].Count() <> 0 Then
			
			If RowIndex > ThisObject[TableName].Count() - 1 Then
				
				RowIndex = ThisObject[TableName].Count() - 1;
				
			EndIf;
			
			// placing a mouse pointer
			Items[TableName].CurrentRow = ThisObject[TableName][RowIndex].GetID();
			
		EndIf;
		
	EndIf;
	
	// If the row positioning failed, the first row is set as the current one.
	If Items[TableName].CurrentRow = Undefined
		AND ThisObject[TableName].Count() <> 0 Then
		
		Items[TableName].CurrentRow = ThisObject[TableName][0].GetID();
		
	EndIf;
	
EndProcedure

&AtServerNoContext
Function DetailedInformationAtServer(ExchangeNode)
	
	ExchangePlanName = ExchangeNode.Metadata().Name;
	
	ExchangeSettingsOption = DataExchangeServer.SavedExchangePlanNodeSettingOption(ExchangeNode);
	CorrespondentVersion   = DataExchangeServer.CorrespondentVersion(ExchangeNode);
	
	ReferenceToDetails = DataExchangeServer.ExchangePlanSettingValue(
		ExchangePlanName, "ExchangeDetailedInformation", ExchangeSettingsOption, CorrespondentVersion);
	
	Return ReferenceToDetails;
	
EndFunction

&AtClient
Procedure OpenInteractiveSynchronizationWizard(AdditionalParameters)
	
	WizardParameters = New Structure;
	WizardParameters.Insert("IsExchangeWithApplicationInService", AdditionalParameters.IsExchangeWithApplicationInService);
	WizardParameters.Insert("CorrespondentDataArea",  AdditionalParameters.CorrespondentDataArea);
	
	WizardParameters.Insert("SendData", Not AdditionalParameters.StartDataExchangeFromCorrespondent);
	
	WizardParameters.Insert("ExportAdditionMode",
		AdditionalParameters.UseAdditionalFilters Or AdditionalParameters.DataExchangeOption = "ReceiveAndSend");
	
	WizardParameters.Insert("ScheduleSetup", False);
	
	AuxiliaryParameters = New Structure;
	AuxiliaryParameters.Insert("WizardParameters", WizardParameters);
	
	DataExchangeClient.OpenObjectsMappingWizardCommandProcessing(AdditionalParameters.ExchangeNode,
		ThisObject, AuxiliaryParameters);
	
EndProcedure

&AtClient
Procedure OpenAutomaticSynchronizationWizard(AdditionalParameters)
	
	WizardParameters = New Structure;	
	WizardParameters.Insert("IsExchangeWithApplicationInService", AdditionalParameters.IsExchangeWithApplicationInService);
	WizardParameters.Insert("CorrespondentDataArea",  AdditionalParameters.CorrespondentDataArea);
		
	AuxiliaryParameters = New Structure;
	AuxiliaryParameters.Insert("WizardParameters", WizardParameters);
		
	DataExchangeClient.ExecuteDataExchangeCommandProcessing(AdditionalParameters.ExchangeNode,
		ThisObject, , True, AuxiliaryParameters);
	
EndProcedure

&AtClient
Procedure ContinueSynchronizationExecution(Result, AdditionalParameters) Export
	
	If AdditionalParameters.EmailReceivedForDataMapping Then
		
		OpenInteractiveSynchronizationWizard(AdditionalParameters);
			
	Else
		
		If Not AdditionalParameters.InteractiveSendingAvailable
			Or (AdditionalParameters.DataExchangeOption = "Synchronization"
				AND Not AdditionalParameters.UseAdditionalFilters) Then
			
			OpenAutomaticSynchronizationWizard(AdditionalParameters);
			
		Else
			
			OpenInteractiveSynchronizationWizard(AdditionalParameters);
				
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure CheckConversionRulesCompatibility(ContinuationHandler)
	
	ErrorDescription = Undefined;
	If ConversionRulesCompatibleWithCurrentVersion(ContinuationHandler.AdditionalParameters.ExchangePlanName, ErrorDescription) Then
		
		ExecuteNotifyProcessing(ContinuationHandler);
		
	Else
		
		Buttons = New ValueList;
		Buttons.Add("GoToRuleImport", NStr("ru = 'Загрузить правила'; en = 'Load rules'; pl = 'Zaimportować reguły';de = 'Regeln importieren';ro = 'Încărcare reguli';tr = 'Kuralları içe aktar'; es_ES = 'Importar las reglas'"));
		If ErrorDescription.ErrorKind <> "InvalidConfiguration" Then
			Buttons.Add("Continue", NStr("ru = 'Продолжить'; en = 'Continue'; pl = 'Kontynuuj';de = 'Weiter';ro = 'Continuare';tr = 'Devam'; es_ES = 'Continuar'"));
		EndIf;
		Buttons.Add("Cancel", NStr("ru = 'Отмена'; en = 'Cancel'; pl = 'Anuluj';de = 'Abbrechen';ro = 'Revocare';tr = 'İptal'; es_ES = 'Cancelar'"));
		
		AdditionalParameters = New Structure;
		AdditionalParameters.Insert("ContinuationHandler", ContinuationHandler);
		AdditionalParameters.Insert("ExchangePlanName",       ContinuationHandler.AdditionalParameters.ExchangePlanName);
		
		Notification = New NotifyDescription("AfterConversionRulesCheckForCompatibility", ThisObject, AdditionalParameters);
		
		FormParameters = StandardSubsystemsClient.QuestionToUserParameters();
		FormParameters.Picture = ErrorDescription.Picture;
		FormParameters.SuggestDontAskAgain = False;
		If ErrorDescription.ErrorKind = "InvalidConfiguration" Then
			FormParameters.Title = NStr("ru = 'Синхронизация данных не может быть выполнена'; en = 'Cannot perform data synchronization'; pl = 'Synchronizacja danych nie może zostać wykonana';de = 'Die Datensynchronisation kann nicht ausgeführt werden';ro = 'Sincronizarea datelor nu poate fi executată';tr = 'Veri senkronizasyonu yapılamıyor'; es_ES = 'Sincronización de datos no puede ejecutarse'");
		Else
			FormParameters.Title = NStr("ru = 'Синхронизация данных может быть выполнена некорректно'; en = 'Data synchronization might be performed incorrectly'; pl = 'Synchronizacja danych może być wykonana niepoprawnie';de = 'Datensynchronisierung wird möglicherweise falsch ausgeführt';ro = 'Sincronizarea datelor poate fi executată incorect';tr = 'Veri senkronizasyonu yanlış yürütülebilir'; es_ES = 'Sincronización de datos puede ejecutarse de forma incorrecta'");
		EndIf;
		
		StandardSubsystemsClient.ShowQuestionToUser(Notification, ErrorDescription.ErrorText, Buttons, FormParameters);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure AfterConversionRulesCheckForCompatibility(Result, AdditionalParameters) Export
	
	If Result <> Undefined Then
		
		If Result.Value = "Continue" Then
			
			ExecuteNotifyProcessing(AdditionalParameters.ContinuationHandler);
			
		ElsIf Result.Value = "GoToRuleImport" Then
			
			DataExchangeClient.ImportDataSyncRules(AdditionalParameters.ExchangePlanName);
			
		EndIf; // No action is required if the value is "Cancel".
		
	EndIf;
	
EndProcedure

&AtServer
Function ConversionRulesCompatibleWithCurrentVersion(ExchangePlanName, ErrorDescription)
	
	RulesData = Undefined;
	If Not ConversionRulesImportedFromFile(ExchangePlanName, RulesData) Then
		Return True;
	EndIf;
	
	Return InformationRegisters.DataExchangeRules.ConversionRulesCompatibleWithCurrentVersion(ExchangePlanName,
		ErrorDescription, RulesData);
		
EndFunction

&AtServer
Function ConversionRulesImportedFromFile(ExchangePlanName, RulesInformation)
	
	SetPrivilegedMode(True);
	
	Query = New Query(
	"SELECT
	|	DataExchangeRules.RulesAreRead,
	|	DataExchangeRules.RulesKind
	|FROM
	|	InformationRegister.DataExchangeRules AS DataExchangeRules
	|WHERE
	|	DataExchangeRules.ExchangePlanName = &ExchangePlanName
	|	AND DataExchangeRules.RulesSource = VALUE(Enum.DataExchangeRulesSources.File)
	|	AND DataExchangeRules.RulesAreImported = TRUE
	|	AND DataExchangeRules.RulesKind = VALUE(Enum.DataExchangeRulesTypes.ObjectConversionRules)");
	Query.SetParameter("ExchangePlanName", ExchangePlanName);
	
	Selection = Query.Execute().Select();
	If Selection.Next() Then
		RulesStructure = Selection.RulesAreRead.Get().Conversion;
		
		RulesInformation = New Structure;
		RulesInformation.Insert("ConfigurationName",              RulesStructure.Source);
		RulesInformation.Insert("ConfigurationVersion",           RulesStructure.SourceConfigurationVersion);
		RulesInformation.Insert("ConfigurationSynonymInRules", RulesStructure.SourceConfigurationSynonym);
		
		Return True;
	EndIf;
	
	Return False;
	
EndFunction

&AtServerNoContext
Function EmailReceivedForDataMapping(ExchangeNode)
	
	Return DataExchangeServer.MessageWithDataForMappingReceived(ExchangeNode);
	
EndFunction

#EndRegion