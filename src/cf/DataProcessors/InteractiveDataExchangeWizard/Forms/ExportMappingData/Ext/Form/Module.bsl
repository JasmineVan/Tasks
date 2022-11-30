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
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	SetNavigationNumber(1);
	
EndProcedure

&AtClient
Procedure BeforeClose(Cancel, Exit, WarningText, StandardProcessing)
	
	If InitialExport Then
		WarningText = NStr("ru = 'Отменить начальную выгрузку данных?'; en = 'Do you want to cancel the initial data export?'; pl = 'Anulować początkowe ładowanie danych?';de = 'Erstmaliges Hochladen der Daten abbrechen?';ro = 'Revocați exportul inițial al datelor?';tr = 'Verilerin ilk dışa aktarımı iptal edilsin mi?'; es_ES = '¿Cancelar la subida inicial de datos?'");
	Else
		WarningText = NStr("ru = 'Отменить выгрузку данных?'; en = 'Do you want to cancel the data export?'; pl = 'Anulować ładowanie danych?';de = 'Den Daten-Upload abbrechen?';ro = 'Revocați exportul datelor?';tr = 'Verilerin dışa aktarımı iptal edilsin mi?'; es_ES = '¿Cancelar la subida de datos?'");
	EndIf;
	
	CommonClient.ShowArbitraryFormClosingConfirmation(
		ThisObject, Cancel, Exit, WarningText, "ForceCloseForm");
	
EndProcedure

&AtClient
Procedure OnClose(Exit)
	
	If Not Exit Then
		Notify("DataExchangeCompleted");
	EndIf;
	
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
	
	CloseParameter = Undefined;
	If DataExportCompleted Then
		CloseParameter = ExchangeNode;
	EndIf;
	
	ForceCloseForm = True;
	Close(CloseParameter);
	
EndProcedure

&AtClient
Procedure CancelCommand(Command)
	
	Close();
	
EndProcedure

#EndRegion

#Region Private

#Region ConnectionParametersCheck

&AtClient
Procedure OnStartTestConnection()
	
	ContinueWait = True;
	
	If ConnectOverExternalConnection Then
		If CommonClient.FileInfobase() Then
			CommonClient.RegisterCOMConnector(False);
		EndIf;
	EndIf;
	
	OnStartTestConnectionAtServer(ContinueWait);
	
	If ContinueWait Then
		DataExchangeClient.InitializeIdleHandlerParameters(
			ConnectionCheckIdleHandlerParameters);
			
		AttachIdleHandler("OnWaitForTestConnection",
			ConnectionCheckIdleHandlerParameters.CurrentInterval, True);
	Else
		OnCompleteConnectionTest();
	EndIf;
	
EndProcedure

&AtClient
Procedure OnWaitForTestConnection()
	
	ContinueWait = False;
	OnWaitConnectionCheckAtServer(ConnectionCheckHandlerParameters, ContinueWait);
	
	If ContinueWait Then
		DataExchangeClient.UpdateIdleHandlerParameters(ConnectionCheckIdleHandlerParameters);
		
		AttachIdleHandler("OnWaitForTestConnection",
			ConnectionCheckIdleHandlerParameters.CurrentInterval, True);
	Else
		ConnectionCheckIdleHandlerParameters = Undefined;
		OnCompleteConnectionTest();
	EndIf;
	
EndProcedure

&AtClient
Procedure OnCompleteConnectionTest()
	
	OnCompleteConnectionTestAtServer();
	
	ChangeNavigationNumber(+1);
	
EndProcedure

&AtServer
Procedure OnStartTestConnectionAtServer(ContinueWait)
	
	If TransportKind = Enums.ExchangeMessagesTransportTypes.WS
		AND PromptForPassword Then
		ConnectionSettings = InformationRegisters.DataExchangeTransportSettings.TransportSettingsWS(ExchangeNode, WSPassword);
	Else
		ConnectionSettings = InformationRegisters.DataExchangeTransportSettings.TransportSettings(ExchangeNode, TransportKind);
	EndIf;
	ConnectionSettings.Insert("ExchangeMessagesTransportKind", TransportKind);
	
	ConnectionSettings.Insert("ExchangePlanName", DataExchangeCached.GetExchangePlanName(ExchangeNode));
	
	ModuleSetupWizard = DataExchangeServer.ModuleDataExchangeCreationWizard();
	
	ModuleSetupWizard.OnStartTestConnection(
		ConnectionSettings, ConnectionCheckHandlerParameters, ContinueWait);
	
EndProcedure

&AtServerNoContext
Procedure OnWaitConnectionCheckAtServer(HandlerParameters, ContinueWait)
	
	ModuleSetupWizard = DataExchangeServer.ModuleDataExchangeCreationWizard();
	
	ContinueWait = False;
	ModuleSetupWizard.OnWaitForTestConnection(HandlerParameters, ContinueWait);
	
EndProcedure

&AtServer
Procedure OnCompleteConnectionTestAtServer()
	
	ModuleSetupWizard = DataExchangeServer.ModuleDataExchangeCreationWizard();
	
	CompletionStatus = Undefined;
	ModuleSetupWizard.OnCompleteTestConnection(
		ConnectionCheckHandlerParameters, CompletionStatus);
		
	If CompletionStatus.Cancel Then
		ConnectionCheckCompleted = False;
		ErrorMessage = CompletionStatus.ErrorMessage;
	Else
		ConnectionCheckCompleted = CompletionStatus.Result.ConnectionIsSet
			AND CompletionStatus.Result.ConnectionAllowed;
			
		If Not ConnectionCheckCompleted
			AND Not IsBlankString(CompletionStatus.Result.ErrorMessage) Then
			ErrorMessage = CompletionStatus.Result.ErrorMessage;
		EndIf;
	EndIf;
	
EndProcedure

#EndRegion

#Region ChangeRegistration

&AtClient
Procedure OnStartChangeRegistration()
	
	ContinueWait = True;
	OnStartChangesRegistrationAtServer(ContinueWait);
	
	If ContinueWait Then
		DataExchangeClient.InitializeIdleHandlerParameters(
			DataRegistrationIdleHandlerParametersForInitialExport);
			
		AttachIdleHandler("OnWaitForChangeRegistration",
			DataRegistrationIdleHandlerParametersForInitialExport.CurrentInterval, True);
	Else
		OnCompleteChangeRegistration();
	EndIf;
	
EndProcedure

&AtClient
Procedure OnWaitForChangeRegistration()
	
	ContinueWait = False;
	OnWaitForChangeRegistrationAtServer(DataRegistrationHandlerParametersForInitialExport, ContinueWait);
	
	If ContinueWait Then
		DataExchangeClient.UpdateIdleHandlerParameters(DataRegistrationIdleHandlerParametersForInitialExport);
		
		AttachIdleHandler("OnWaitForChangeRegistration",
			DataRegistrationIdleHandlerParametersForInitialExport.CurrentInterval, True);
	Else
		DataRegistrationIdleHandlerParametersForInitialExport = Undefined;
		OnCompleteChangeRegistration();
	EndIf;
	
EndProcedure

&AtClient
Procedure OnCompleteChangeRegistration()
	
	OnCompleteChangeRegistrationAtServer();
	
	ChangeNavigationNumber(+1);
	
EndProcedure

&AtServer
Procedure OnStartChangesRegistrationAtServer(ContinueWait)
	
	ModuleSetupWizard = DataExchangeServer.ModuleDataExchangeCreationWizard();
	
	RegistrationSettings = New Structure;
	RegistrationSettings.Insert("ExchangeNode", ExchangeNode);
	
	ModuleSetupWizard.OnStartRecordDataForInitialExport(
		RegistrationSettings, DataRegistrationHandlerParametersForInitialExport, ContinueWait);
	
EndProcedure

&AtServerNoContext
Procedure OnWaitForChangeRegistrationAtServer(HandlerParameters, ContinueWait)
	
	ModuleSetupWizard = DataExchangeServer.ModuleDataExchangeCreationWizard();
	
	ContinueWait = False;
	ModuleSetupWizard.OnWaitForRecordDataForInitialExport(
		HandlerParameters, ContinueWait);
	
EndProcedure

&AtServer
Procedure OnCompleteChangeRegistrationAtServer()
	
	ModuleSetupWizard = DataExchangeServer.ModuleDataExchangeCreationWizard();
	
	CompletionStatus = Undefined;
	ModuleSetupWizard.OnCompleteDataRecordingForInitialExport(
		DataRegistrationHandlerParametersForInitialExport, CompletionStatus);
		
	If CompletionStatus.Cancel Then
		ChangesRegistrationCompleted = False;
		ErrorMessage = CompletionStatus.ErrorMessage;
	Else
		ChangesRegistrationCompleted = CompletionStatus.Result.DataRegistered;
			
		If Not ChangesRegistrationCompleted
			AND Not IsBlankString(CompletionStatus.Result.ErrorMessage) Then
			ErrorMessage = CompletionStatus.Result.ErrorMessage;
		EndIf;
	EndIf;
	
EndProcedure

#EndRegion

#Region DataExport

&AtClient
Procedure OnStartExportDataForMapping()
	
	ProgressPercent = 0;
	
	ContinueWait = True;
	OnStartDataExportToMapAtServer(ContinueWait);
	
	If ContinueWait Then
		
		If IsExchangeWithApplicationInService Then
			DataExchangeClient.InitializeIdleHandlerParameters(
				MappingDataExportIdleHandlerParameters);
				
			AttachIdleHandler("OnWaitForExportDataForMapping",
				MappingDataExportIdleHandlerParameters.CurrentInterval, True);
		Else
			CompletionNotification = New NotifyDescription("DataExportForMappingCompletion", ThisObject);
		
			IdleParameters = TimeConsumingOperationsClient.IdleParameters(ThisObject);
			IdleParameters.OutputIdleWindow = False;
			IdleParameters.OutputProgressBar = UseProgress;
			IdleParameters.ExecutionProgressNotification = New NotifyDescription("DataExportForMappingProgress", ThisObject);
			
			TimeConsumingOperationsClient.WaitForCompletion(MappingDataExportHandlerParameters.BackgroundJob,
				CompletionNotification, IdleParameters);
		EndIf;
			
	Else
			
		OnCompleteDataExportForMapping();
		
	EndIf;
	
EndProcedure

&AtClient
Procedure OnWaitForExportDataForMapping()
	
	ContinueWait = False;
	OnWaitDataExportToMapAtServer(MappingDataExportHandlerParameters, ContinueWait);
	
	If ContinueWait Then
		DataExchangeClient.UpdateIdleHandlerParameters(MappingDataExportIdleHandlerParameters);
		
		AttachIdleHandler("OnWaitForExportDataForMapping",
			MappingDataExportIdleHandlerParameters.CurrentInterval, True);
	Else
		MappingDataExportIdleHandlerParameters = Undefined;
		OnCompleteDataExportForMapping();
	EndIf;
	
EndProcedure

&AtClient
Procedure OnCompleteDataExportForMapping()
	
	ProgressPercent = 100;
	
	OnCompleteDataExportForMappingAtServer();
	ChangeNavigationNumber(+1);
	
EndProcedure

&AtClient
Procedure DataExportForMappingCompletion(Result, AdditionalParameters) Export
	
	OnCompleteDataExportForMapping();
	
EndProcedure

&AtClient
Procedure DataExportForMappingProgress(Progress, AdditionalParameters) Export
	
	If Progress = Undefined Then
		Return;
	EndIf;
	
	ProgressStructure = Progress.Progress;
	If ProgressStructure <> Undefined Then
		ProgressPercent = ProgressStructure.Percent;
	EndIf;
	
EndProcedure

&AtServer
Procedure OnStartDataExportToMapAtServer(ContinueWait)
	
	ExportSettings = New Structure;
	
	If IsExchangeWithApplicationInService Then
		ExportSettings.Insert("Correspondent", ExchangeNode);
		ExportSettings.Insert("CorrespondentDataArea", CorrespondentDataArea);
		
		ModuleInteractiveExchangeWizard = DataExchangeServer.ModuleInteractiveDataExchangeWizardInSaaS();
	Else
		ExportSettings.Insert("ExchangeNode", ExchangeNode);
		ExportSettings.Insert("TransportKind", TransportKind);
		
		If TransportKind = Enums.ExchangeMessagesTransportTypes.WS
			AND PromptForPassword Then
			ExportSettings.Insert("WSPassword", WSPassword);
		EndIf;
		
		ModuleInteractiveExchangeWizard = DataExchangeServer.ModuleInteractiveDataExchangeWizard();
	EndIf;
	
	If ModuleInteractiveExchangeWizard = Undefined Then
		ContinueWait = False;
		Return;
	EndIf;
	
	ModuleInteractiveExchangeWizard.OnStartExportDataForMapping(
		ExportSettings, MappingDataExportHandlerParameters, ContinueWait);
	
EndProcedure
	
&AtServerNoContext
Procedure OnWaitDataExportToMapAtServer(HandlerParameters, ContinueWait)
	
	ModuleInteractiveExchangeWizard = DataExchangeServer.ModuleInteractiveDataExchangeWizardInSaaS();
	
	If ModuleInteractiveExchangeWizard = Undefined Then
		ContinueWait = False;
		Return;
	EndIf;
	
	ModuleInteractiveExchangeWizard.OnWaitForExportDataForMapping(HandlerParameters, ContinueWait);
	
EndProcedure

&AtServer
Procedure OnCompleteDataExportForMappingAtServer()
	
	If IsExchangeWithApplicationInService Then
		ModuleInteractiveExchangeWizard = DataExchangeServer.ModuleInteractiveDataExchangeWizardInSaaS();
	Else
		ModuleInteractiveExchangeWizard = DataExchangeServer.ModuleInteractiveDataExchangeWizard();
	EndIf;
	
	If ModuleInteractiveExchangeWizard = Undefined Then
		DataExportCompleted = False;
		Return;
	EndIf;
	
	CompletionStatus = Undefined;
	
	ModuleInteractiveExchangeWizard.OnCompleteExportDataForMapping(
		MappingDataExportHandlerParameters, CompletionStatus);
		
	If CompletionStatus.Cancel Then
		DataExportCompleted = False;
		ErrorMessage = CompletionStatus.ErrorMessage;
	Else
		DataExportCompleted = CompletionStatus.Result.DataExported;
			
		If Not DataExportCompleted
			AND Not IsBlankString(CompletionStatus.Result.ErrorMessage) Then
			ErrorMessage = CompletionStatus.Result.ErrorMessage;
		EndIf;
	EndIf;
	
EndProcedure

#EndRegion

#Region FormInitializationOnCreate

&AtServer
Procedure CheckCanUseForm(Cancel = False)
	
	// It is required to pass the parameters of data export execution.
	If Not Parameters.Property("ExchangeNode") Then
		MessageText = NStr("ru = 'Форма не предназначена для непосредственного использования.'; en = 'The form cannot be opened manually.'; pl = 'Formularz nie jest przeznaczony dla bezpośredniego użycia.';de = 'Das Formular ist nicht für den direkten Gebrauch bestimmt.';ro = 'Forma nu este destinată pentru utilizare nemijlocită.';tr = 'Form doğrudan kullanım için uygun değildir.'; es_ES = 'El formulario no está destinado para el uso directo.'");
		Common.MessageToUser(MessageText, , , , Cancel);
		Return;
	EndIf;
	
	If DataExchangeCached.IsDistributedInfobaseNode(Parameters.ExchangeNode) Then
		MessageText = NStr("ru = 'Начальная выгрузка не поддерживается для узлов распределенных информационных баз.'; en = 'Initial export is not supported for distributed infobase nodes.'; pl = 'Początkowe ładowanie nie jest obsługiwane dla węzłów rozprowadzonych baz informacyjnych.';de = 'Der anfängliche Upload wird für Knoten verteilter Informationsdatenbanken nicht unterstützt.';ro = 'Exportul inițial nu este susținut pentru nodurile bazelor de informații distribuite.';tr = 'Dağıtılmış veritabanların üniteleri için ilk dışa aktarma desteklenmiyor.'; es_ES = 'La subida inicial no se admite para los nodos de las bases de información distribuidas.'");
		Common.MessageToUser(MessageText, , , , Cancel);
		Return;
	EndIf;
	
EndProcedure

&AtServer
Procedure InitializeFormAttributes()
	
	ExchangeNode = Parameters.ExchangeNode;
	
	If Parameters.Property("InitialExport") Then
		DataExportMode = "InitialExport";
		InitialExport = True;
	Else
		DataExportMode = "StandardExport";
	EndIf;
	
	ApplicationDescription = Common.ObjectAttributeValue(ExchangeNode, "Description");
	
	Parameters.Property("IsExchangeWithApplicationInService", IsExchangeWithApplicationInService);
	Parameters.Property("CorrespondentDataArea",  CorrespondentDataArea);
	
	UseProgress = Not IsExchangeWithApplicationInService;
		
	TransportKind = InformationRegisters.DataExchangeTransportSettings.DefaultExchangeMessagesTransportKind(ExchangeNode);
	
	ConnectOverExternalConnection = (TransportKind = Enums.ExchangeMessagesTransportTypes.COM);
	
	If TransportKind = Enums.ExchangeMessagesTransportTypes.WS Then
		
		UseProgress = False;
		
		TransportSettings = InformationRegisters.DataExchangeTransportSettings.TransportSettingsWS(ExchangeNode);
		
		PromptForPassword = Not (TransportSettings.WSRememberPassword
			Or DataExchangeServer.DataSynchronizationPasswordSpecified(ExchangeNode));
		
	EndIf;
		
	FillNavigationTable();
	
	SetApplicationDescriptionInFormLabels();
	
EndProcedure

&AtServer
Procedure SetApplicationDescriptionInFormLabels()
	
	Items.PasswordLabelDecoration.Title = StrReplace(Items.PasswordLabelDecoration.Title,
		"%ApplicationDescription%", ApplicationDescription);
	
	Items.DataExportNoProgressBarLabelDecoration.Title = StrReplace(Items.DataExportNoProgressBarLabelDecoration.Title,
		"%ApplicationDescription%", ApplicationDescription);
	
	Items.DataExportProgressLabelDecoration.Title = StrReplace(Items.DataExportProgressLabelDecoration.Title,
		"%ApplicationDescription%", ApplicationDescription);
	
	Items.ExportCompletedLabelDecoration.Title = StrReplace(Items.ExportCompletedLabelDecoration.Title,
		"%ApplicationDescription%", ApplicationDescription);
	
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
	
	NewNavigation = AddNavigationTableRow("StartPage", "NavigationStartPage");
	NewNavigation.OnOpenHandlerName = "BeginningPage_OnOpen";
	
	If PromptForPassword Then
		NewNavigation = AddNavigationTableRow("PasswordRequestPage", "PageNavigationFollowUp");
		NewNavigation.OnSwitchToNextPageHandlerName = "PasswordRequestPage_OnGoNext";
	EndIf;
	
	NewNavigation = AddNavigationTableRow("ConnectionTestPage", "NavigationWaitPage");
	NewNavigation.TimeConsumingOperation = True;
	NewNavigation.TimeConsumingOperationHandlerName = "ConnectionCheckPage_TimeConsumingOperation";
	
	NewNavigation = AddNavigationTableRow("ChangeRecordingPage", "NavigationWaitPage");
	NewNavigation.OnOpenHandlerName = "ChangeRegistrationPage_OnOpen";
	NewNavigation.TimeConsumingOperation = True;
	NewNavigation.TimeConsumingOperationHandlerName = "ChangeRegistrationPage_TimeConsumingOperation";
	
	If UseProgress Then
		NewNavigation = AddNavigationTableRow("ExportDataProgressPage", "NavigationWaitPage");
	Else
		NewNavigation = AddNavigationTableRow("ExportDataWithoutProgressPage", "NavigationWaitPage");
	EndIf;
	NewNavigation.OnOpenHandlerName = "DataExportPage_OnOpen";
	NewNavigation.TimeConsumingOperation = True;
	NewNavigation.TimeConsumingOperationHandlerName = "DataExportPage_TimeConsumingOperation";
	
	NewNavigation = AddNavigationTableRow("EndPage", "NavigationEndPage");
	NewNavigation.OnOpenHandlerName = "EndPage_OnOpen";
	
EndProcedure

#EndRegion

#Region NavigationEventHandlers

&AtClient
Function Attachable_PageStart_OnOpen(Cancel, SkipPage, IsMoveNext)
	
	Items.DataExportMode.Enabled = Not InitialExport;
	
	Return Undefined;
	
EndFunction

&AtClient
Function Attachable_PasswordRequestPage_OnGoNext(Cancel)
	
	If Not PromptForPassword Then
		Return Undefined;
	EndIf;
	
	If IsBlankString(WSPassword) Then
		CommonClient.MessageToUser(
			NStr("ru = 'Укажите пароль.'; en = 'Please enter the password.'; pl = 'Podaj hasło.';de = 'Geben Sie Ihr Passwort ein.';ro = 'Specificați parola.';tr = 'Şifreyi belirtin.'; es_ES = 'Indique la contraseña.'"), , "WSPassword", , Cancel);
	EndIf;
	
	Return Undefined;
	
EndFunction

&AtClient
Function Attachable_ConnectionTestPage_TimeConsumingOperation(Cancel, GoToNext)
	
	GoToNext = False;
	OnStartTestConnection();
	
	Return Undefined;
	
EndFunction

&AtClient
Function Attachable_ChangesRegistrationPage_OnOpen(Cancel, SkipPage, IsMoveNext)
	
	If Not ConnectionCheckCompleted Then
		SkipPage = True;
		Return Undefined;
	Else
		If DataExportMode = "StandardExport" Then
			SkipPage = True;
			ChangesRegistrationCompleted = True;
		EndIf;
	EndIf;
	
	Return Undefined;
	
EndFunction

&AtClient
Function Attachable_ChangesRegistrationPage_TimeConsumingOperation(Cancel, GoToNext)
	
	GoToNext = False;
	OnStartChangeRegistration();
	
	Return Undefined;
	
EndFunction

&AtClient
Function Attachable_DataExportPage_OnOpen(Cancel, SkipPage, IsMoveNext)
	
	SkipPage = Not ConnectionCheckCompleted
		Or Not ChangesRegistrationCompleted;
		
	Return Undefined;
	
EndFunction

&AtClient
Function Attachable_DataExportPage_TimeConsumingOperation(Cancel, GoToNext)
	
	GoToNext = False;
	OnStartExportDataForMapping();
	
	Return Undefined;
	
EndFunction

&AtClient
Function Attachable_EndPage_OnOpen(Cancel, SkipPage, IsMoveNext)
	
	If Not ConnectionCheckCompleted Then
		Items.CompletionStatusPanel.CurrentPage = Items.CompletionPageConnectionCheckError;
	ElsIf Not ChangesRegistrationCompleted Then
		Items.CompletionStatusPanel.CurrentPage = Items.ChangesRegistrationErrorPage;
	ElsIf Not DataExportCompleted Then
		Items.CompletionStatusPanel.CurrentPage = Items.DataExportErrorPage;
	Else
		Items.CompletionStatusPanel.CurrentPage = Items.SuccessfulCompletionPage;
	EndIf;
	
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
