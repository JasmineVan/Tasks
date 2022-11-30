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
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	SetNavigationNumber(1);
	
EndProcedure

&AtClient
Procedure BeforeClose(Cancel, Exit, WarningText, StandardProcessing)
	
	WarningText = NStr("ru = 'Отказаться от удаления настройки синхронизации данных?'; en = 'Do you want to cancel the deletion of the data synchronization setting?'; pl = 'Zrezygnować z usuwania ustawienia synchronizacji danych?';de = 'Einstellungen für die Datensynchronisation nicht löschen?';ro = 'Refuzați ștergerea setării de sincronizare a datelor?';tr = 'Veri eşleşmesi ayarını silmekten vazgeç?'; es_ES = '¿Renunciar la eliminación del ajuste de sincronización de datos?'");
	CommonClient.ShowArbitraryFormClosingConfirmation(
		ThisObject, Cancel, Exit, WarningText, "ForceCloseForm");
	
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
	Close();
	
EndProcedure

&AtClient
Procedure CancelCommand(Command)
	
	Close();
	
EndProcedure

#EndRegion

#Region Private

#Region DeleteSyncSetting

&AtClient
Procedure OnStartDeleteSynchronizationSettings()
	
	ContinueWait = True;
	
	If ConnectOverExternalConnection Then
		If CommonClient.FileInfobase() Then
			CommonClient.RegisterCOMConnector(False);
		EndIf;
	EndIf;
	
	OnStartDeleteOfSynchronizationSettingsAtServer(ContinueWait);
	
	If ContinueWait Then
		DataExchangeClient.InitializeIdleHandlerParameters(
			IdleHandlerParameters);
			
		AttachIdleHandler("OnWaitForDeleteSynchronizationSettings",
			IdleHandlerParameters.CurrentInterval, True);
	Else
		OnCompleteSynchronizationSettingsDeletion();
	EndIf;
	
EndProcedure

&AtClient
Procedure OnWaitForDeleteSynchronizationSettings()
	
	ContinueWait = False;
	OnWaitForDeleteSynchronizationSettingAtServer(IsExchangeWithApplicationInService,
		HandlerParameters, ContinueWait);
	
	If ContinueWait Then
		DataExchangeClient.UpdateIdleHandlerParameters(IdleHandlerParameters);
		
		AttachIdleHandler("OnWaitForDeleteSynchronizationSettings",
			IdleHandlerParameters.CurrentInterval, True);
	Else
		IdleHandlerParameters = Undefined;
		OnCompleteSynchronizationSettingsDeletion();
	EndIf;
	
EndProcedure

&AtClient
Procedure OnCompleteSynchronizationSettingsDeletion()
	
	ErrorMessage = "";
	
	SettingDeleted = True;
	SettingDeletedInCorrespondent = True;
	
	OnCompleteSynchronizationSettingsDeletionAtServer(SettingDeleted,
		SettingDeletedInCorrespondent, ErrorMessage);
	
	If SettingDeleted Then
		ChangeNavigationNumber(+1);
		
		If DeleteSettingItemInCorrespondent
			AND SettingDeletedInCorrespondent Then
			Items.SyncDeletedLabelDecoration.Title = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'Настройки синхронизации данных в этой программе
				|и программе ""%1"" успешно удалены.'; 
				|en = 'Data synchronization settings in this application
				|and in %1 are deleted.'; 
				|pl = 'Ustawienia synchronizacji danych w tym programie
				|i programie ""%1"" pomyślnie usunięte.';
				|de = 'Die Einstellungen zur Datensynchronisation in diesem Programm
				|und dem Programm ""%1"" wurden erfolgreich gelöscht.';
				|ro = 'Setările de sincronizare a datelor în acest program
				|și în programul ""%1"" sunt șterse cu succes.';
				|tr = 'Bu programdaki 
				| ve ""%1"" programdaki veri eşleşme ayarları başarı ile kaldırıldı.'; 
				|es_ES = 'Los ajustes de sincronización de datos en este programa
				|y en el programa ""%1"" se han eliminado con éxito.'"),
				CorrespondentDescription);
		EndIf;
		
	Else
		ChangeNavigationNumber(-1);
		
		If Not IsBlankString(ErrorMessage) Then
			CommonClient.MessageToUser(ErrorMessage);
		Else
			CommonClient.MessageToUser(
				NStr("ru = 'Не удалось удалить настройку синхронизации данных.'; en = 'Cannot delete the data synchronization setting.'; pl = 'Nie udało się usunąć ustawienia synchronizacji danych.';de = 'Die Einstellung für die Datensynchronisation konnte nicht gelöscht werden.';ro = 'Eșec la ștergerea setării de sincronizare a datelor.';tr = 'Veri senkronizasyon ayarları kaldırılamıyor.'; es_ES = 'No se ha podido eliminar el ajuste de sincronización de datos.'"));
		EndIf;
	EndIf;
	
EndProcedure

&AtServer
Procedure OnStartDeleteOfSynchronizationSettingsAtServer(ContinueWait)
	
	DeletionSettings = New Structure;
	
	If IsExchangeWithApplicationInService Then
		
		DeletionSettings.Insert("ExchangePlanName", ExchangePlanName);
		DeletionSettings.Insert("CorrespondentDataArea", CorrespondentDataArea);
		
		ModuleSetupDeletionWizard = DataExchangeServer.ModuleDataSynchronizationBetweenWebApplicationsSetupWizard();
		
	Else
		
		DeletionSettings.Insert("ExchangeNode", ExchangeNode);
		DeletionSettings.Insert("DeleteSettingItemInCorrespondent", DeleteSettingItemInCorrespondent);
		
		ModuleSetupDeletionWizard = DataExchangeServer.ModuleDataExchangeCreationWizard();
		
	EndIf;
	
	If ModuleSetupDeletionWizard = Undefined Then
		ContinueWait = False;
		Return;
	EndIf;
	
	ModuleSetupDeletionWizard.OnStartDeleteSynchronizationSettings(DeletionSettings,
		HandlerParameters, ContinueWait);
	
EndProcedure

&AtServerNoContext
Procedure OnWaitForDeleteSynchronizationSettingAtServer(IsExchangeWithApplicationInService, HandlerParameters, ContinueWait)
	
	If IsExchangeWithApplicationInService Then
		ModuleSetupDeletionWizard = DataExchangeServer.ModuleDataSynchronizationBetweenWebApplicationsSetupWizard();
	Else
		ModuleSetupDeletionWizard = DataExchangeServer.ModuleDataExchangeCreationWizard();
	EndIf;
	
	If ModuleSetupDeletionWizard = Undefined Then
		ContinueWait = False;
		Return;
	EndIf;
	
	ContinueWait = False;
	ModuleSetupDeletionWizard.OnWaitForDeleteSynchronizationSettings(HandlerParameters, ContinueWait);
	
EndProcedure

&AtServer
Procedure OnCompleteSynchronizationSettingsDeletionAtServer(SettingDeleted, SettingDeletedInCorrespondent, ErrorMessage)
	
	If IsExchangeWithApplicationInService Then
		ModuleSetupDeletionWizard = DataExchangeServer.ModuleDataSynchronizationBetweenWebApplicationsSetupWizard();
	Else
		ModuleSetupDeletionWizard = DataExchangeServer.ModuleDataExchangeCreationWizard();
	EndIf;
	
	If ModuleSetupDeletionWizard = Undefined Then
		SettingDeleted = False;
		SettingDeletedInCorrespondent = False;
		Return;
	EndIf;
	
	CompletionStatus = Undefined;
	
	ModuleSetupDeletionWizard.OnCompleteDeleteSynchronizationSettings(
		HandlerParameters, CompletionStatus);
		
	If CompletionStatus.Cancel Then
		SettingDeleted = False;
		
		ErrorMessage = CompletionStatus.ErrorMessage;
		Return;
	Else
		SettingDeleted = CompletionStatus.Result.SettingDeleted;
		SettingDeletedInCorrespondent = CompletionStatus.Result.SettingDeletedInCorrespondent;
		
		ErrorMessage = CompletionStatus.ErrorMessage;
	EndIf;
	
EndProcedure

#EndRegion

#Region FormInitializationOnCreate

&AtServer
Procedure InitializeFormAttributes()
	
	ExchangeNode = Parameters.ExchangeNode;
	
	Parameters.Property("ExchangePlanName", ExchangePlanName);
	If Not ValueIsFilled(ExchangePlanName) Then
		ExchangePlanName = DataExchangeCached.GetExchangePlanName(ExchangeNode);
	EndIf;
	
	SaaSModel = Common.DataSeparationEnabled()
		AND Common.SeparatedDataUsageAvailable();
		
	Parameters.Property("CorrespondentDataArea",  CorrespondentDataArea);
	Parameters.Property("CorrespondentDescription",   CorrespondentDescription);
	Parameters.Property("IsExchangeWithApplicationInService", IsExchangeWithApplicationInService);
	
	If Not ValueIsFilled(CorrespondentDescription) Then
		CorrespondentDescription = Common.ObjectAttributeValue(ExchangeNode, "Description");
	EndIf;
	
	TransportKind = InformationRegisters.DataExchangeTransportSettings.DefaultExchangeMessagesTransportKind(ExchangeNode);
	OnlineConnection = (TransportKind = Enums.ExchangeMessagesTransportTypes.COM
		Or TransportKind = Enums.ExchangeMessagesTransportTypes.WS);
	IsExchangeWithExternalSystem = (TransportKind = Enums.ExchangeMessagesTransportTypes.ExternalSystem);
	
	ConnectOverExternalConnection = (TransportKind = Enums.ExchangeMessagesTransportTypes.COM);
		
	DeleteSettingItemInCorrespondent = OnlineConnection Or IsExchangeWithExternalSystem;
	
	GetCorrespondentParameters = SaaSModel
		AND Not Parameters.Property("IsExchangeWithApplicationInService")
		AND Not TransportKind = Enums.ExchangeMessagesTransportTypes.WS
		AND Not TransportKind = Enums.ExchangeMessagesTransportTypes.WSPassiveMode
		AND Not IsExchangeWithExternalSystem;
	
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
	
	If GetCorrespondentParameters Then
		NewNavigation = AddNavigationTableRow("GetCorrespondentParametersPage", "NavigationWaitPage");
		NewNavigation.TimeConsumingOperation = True;
		NewNavigation.TimeConsumingOperationHandlerName = "GetCorrespondentParametersPage_TimeConsumingOperation";
	EndIf;
	
	NewNavigation = AddNavigationTableRow("StartPage", "NavigationStartPage");
	NewNavigation.OnOpenHandlerName = "BeginningPage_OnOpen";
	
	NewNavigation = AddNavigationTableRow("WaitPage", "NavigationWaitPage");
	NewNavigation.OnOpenHandlerName = "WaitingPage_OnOpen";
	
	NewNavigation = AddNavigationTableRow("EndPage", "NavigationEndPage");
	NewNavigation.OnOpenHandlerName = "EndPage_OnOpen";
	
EndProcedure

#EndRegion

#Region NavigationEventHandlers

&AtClient
Function Attachable_GetCorrespondentParametersPage_TimeConsumingOperation(Cancel, GoToNext)
	
	GoToNext = False;
	OnStartGetApplicationList();
	
	Return Undefined;
	
EndFunction

&AtClient
Function Attachable_PageStart_OnOpen(Cancel, SkipPage, IsMoveNext)
	
	Items.StartSubGroup.Visible = OnlineConnection Or IsExchangeWithExternalSystem;
	
	If IsExchangeWithExternalSystem Then
		Items.DeleteSettingItemInCorrespondent.Title = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Удалить настройку обмена с системой ""%1"" на Портале 1С:ИТС.'; en = 'Delete exchange with %1 at 1C:ITS Portal'; pl = 'Usuń ustawienia wymiany z systemem ""%1"" na portalu 1C:ITS.';de = 'Löschen Sie die Austauscheinstellungen mit dem System ""%1"" auf dem Portal 1C:ITS.';ro = 'Șterge setarea de schimb cu sistemul ""%1"" pe Portalul 1C:SIT.';tr = '1C:ITS portalındaki ""%1"" sistemi ile veri alışverişi ayarları silindi.'; es_ES = 'Eliminar el ajuste de cambio con el sistema ""%1"" en el Portal 1C:ITS.'"),
			CorrespondentDescription);
	Else
		Items.DeleteSettingItemInCorrespondent.Title = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Удалить настройку также в программе ""%1"".'; en = 'Also delete the setting in %1'; pl = 'Usuń ustawienie również w programie ""%1"".';de = 'Löschen Sie die Einstellung auch im Programm ""%1"".';ro = 'Șterge setarea și în programul ""%1"".';tr = '""%1"" programında da ayarları kaldırın.'; es_ES = 'Eliminar ajuste también en el programa ""%1"".'"),
			CorrespondentDescription);
	EndIf;
	
	Return Undefined;
	
EndFunction

&AtClient
Function Attachable_WaitPage_OnOpen(Cancel, SkipPage, IsMoveNext)
	
	ClosingNotification = New NotifyDescription("AfterPermissionDeletion", ThisObject, ExchangeNode);
	If CommonClient.SubsystemExists("StandardSubsystems.SecurityProfiles") Then
		Queries = DataExchangeServerCall.RequestToClearPermissionsToUseExternalResources(ExchangeNode);
		ModuleSafeModeManagerClient = CommonClient.CommonModule("SafeModeManagerClient");
		ModuleSafeModeManagerClient.ApplyExternalResourceRequests(Queries, Undefined, ClosingNotification);
	Else
		ExecuteNotifyProcessing(ClosingNotification, DialogReturnCode.OK);
	EndIf;
	
	Return Undefined;
	
EndFunction

&AtClient
Function Attachable_WaitPage_TimeConsumingOperation(Cancel, GoToNext)
	
	GoToNext = False;
	
	Return Undefined;
	
EndFunction

&AtClient
Function Attachable_EndPage_OnOpen(Cancel, SkipPage, IsMoveNext)
	
	Notify("Write_ExchangePlanNode");
	CloseForms("NodeForm");
	CloseForms("SyncSetup");
	
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
		Raise NStr("ru = 'Не определена страница для отображения.'; en = 'The page to display is not specified.'; pl = 'Nie określono strony do wyświetlenia.';de = 'Die anzuzeigende Seite ist nicht definiert.';ro = 'Pagina pentru afișare nu este definită.';tr = 'Gösterilecek sayfa tanımlanmamış.'; es_ES = 'Página para visualizar no está definida.'");
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

&AtClient
Procedure OnStartGetApplicationList()
	
	HandlerParameters = Undefined;
	ContinueWait = False;
	
	OnStartGettingApplicationsListAtServer(HandlerParameters, ContinueWait);
		
	If ContinueWait Then
		DataExchangeClient.InitializeIdleHandlerParameters(IdleHandlerParameters);
			
		AttachIdleHandler("OnWaitForGetApplicationList",
			IdleHandlerParameters.CurrentInterval, True);
	Else
		OnCompleteGettingApplicationsList();
	EndIf;
	
EndProcedure

&AtClient
Procedure OnWaitForGetApplicationList()
	
	ContinueWait = False;
	OnWaitGettingApplicationsListAtServer(HandlerParameters, ContinueWait);
	
	If ContinueWait Then
		DataExchangeClient.UpdateIdleHandlerParameters(IdleHandlerParameters);
		
		AttachIdleHandler("OnWaitForGetApplicationList",
			IdleHandlerParameters.CurrentInterval, True);
	Else
		IdleHandlerParameters = Undefined;
		OnCompleteGettingApplicationsList();
	EndIf;
	
EndProcedure

&AtClient
Procedure OnCompleteGettingApplicationsList()
	
	GoToNext = True;
	OnCompleteGettingApplicationsListAtServer(GoToNext);
	
	If GoToNext Then
		ChangeNavigationNumber(+1);
	EndIf;
	
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
Procedure OnCompleteGettingApplicationsListAtServer(GoToNext)
	
	ModuleSetupWizard = DataExchangeServer.ModuleDataSynchronizationBetweenWebApplicationsSetupWizard();
	
	If ModuleSetupWizard = Undefined Then
		Return;
	EndIf;
	
	CompletionStatus = Undefined;
	ModuleSetupWizard.OnCompleteGetApplicationList(HandlerParameters, CompletionStatus);
		
	If Not CompletionStatus.Cancel Then
		ApplicationsTable = CompletionStatus.Result;
		ApplicationRow = ApplicationsTable.Find(ExchangeNode, "Correspondent");
		If Not ApplicationRow = Undefined Then
			IsExchangeWithApplicationInService = True;
			CorrespondentDataArea  = ApplicationRow.DataArea;
			CorrespondentDescription   = ApplicationRow.ApplicationDescription;
		EndIf;
	Else
		Common.MessageToUser(CompletionStatus.ErrorMessage);
		GoToNext = False;
	EndIf;
	
EndProcedure

&AtClient
Procedure AfterPermissionDeletion(Result, InfobaseNode) Export
	
	If Result = DialogReturnCode.OK Then
		OnStartDeleteSynchronizationSettings();
	Else
		ChangeNavigationNumber(-1);
	EndIf;
	
EndProcedure

&AtClient
Procedure CloseForms(Val FormName)
	
	ApplicationWindows = GetWindows();
	
	If ApplicationWindows = Undefined Then
		Return;
	EndIf;
		
	For Each ApplicationWindow In ApplicationWindows Do
		If ApplicationWindow.IsMain Then
			Continue;
		EndIf;
			
		Form = ApplicationWindow.GetContent();
		
		If TypeOf(Form) = Type("ManagedForm")
			AND Not Form.Modified
			AND StrFind(Form.FormName, FormName) <> 0 Then
			
			Form.Close();
			
		EndIf;
	EndDo;
	
EndProcedure

#EndRegion