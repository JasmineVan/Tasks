﻿///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region EventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	AccountPasswordRecoveryAddress = Parameters.AccountPasswordRecoveryAddress;
	CloseOnSynchronizationDone           = Parameters.CloseOnSynchronizationDone;
	InfobaseNode                    = Parameters.InfobaseNode;
	Exit                   = Parameters.Exit;
	
	Parameters.Property("IsExchangeWithApplicationInService", ExchangeBetweenSaaSApplications);
	Parameters.Property("CorrespondentDataArea",  CorrespondentDataArea);
	
	If Not ValueIsFilled(InfobaseNode) Then
		
		If DataExchangeServer.IsSubordinateDIBNode() Then
			InfobaseNode = DataExchangeServer.MasterNode();
		Else
			DataExchangeServer.ReportError(NStr("ru = 'Не заданы параметры формы. Форма не может быть открыта.'; en = 'Cannot open the form. The form parameters are not specified.'; pl = 'Parametry formularza nie zostały określone. Nie można otworzyć formularza.';de = 'Formularparameter sind nicht angegeben. Das Formular kann nicht geöffnet werden.';ro = 'Formatele parametrilor nu sunt specificate. Nu se poate deschide formularul.';tr = 'Form parametreleri belirtilmemiş. Form açılamıyor.'; es_ES = 'Parámetros de formulario no están especificados. No se puede abrir el formulario.'"), Cancel);
			Return;
		EndIf;
		
	EndIf;
	
	SetPrivilegedMode(True);
	
	CorrespondentDescription = Common.ObjectAttributeValue(InfobaseNode, "Description");
	MessagesTransportKind     = InformationRegisters.DataExchangeTransportSettings.DefaultExchangeMessagesTransportKind(InfobaseNode);
	ExecuteDataSending    = InformationRegisters.CommonInfobasesNodesSettings.ExecuteDataSending(InfobaseNode);
	
	SetPrivilegedMode(False);
	
	// Initializing user roles.
	DataExchangeAdministrationRoleAssigned = DataExchangeServer.HasRightsToAdministerExchanges();
	RoleAvailableFullAccess                     = Users.IsFullUser();
	
	NoLongSynchronizationPrompt = True;
	CheckVersionDifference       = Not ExchangeBetweenSaaSApplications;
	
	ConnectOverExternalConnection = (MessagesTransportKind = Enums.ExchangeMessagesTransportTypes.COM);
	
	If Common.SubsystemExists("SaaSTechnology.SaaS.DataExchangeSaaS")
		AND DataExchangeServer.IsStandaloneWorkplace() Then
		
		ModuleStandaloneMode = Common.CommonModule("StandaloneMode");
		
		NoLongSynchronizationPrompt = Not ModuleStandaloneMode.LongSynchronizationQuestionSetupFlag();
		CheckVersionDifference       = False;
		
	EndIf;
	
	// Setting form title.
	Title = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("ru = 'Синхронизация данных с ""%1""'; en = 'Synchronize data with %1'; pl = 'Synchronizacja danych z %1';de = 'Datensynchronisation mit %1';ro = 'Sincronizarea datelor cu %1';tr = 'İle veri senkronizasyonu%1'; es_ES = 'Sincronización de datos con %1'"), CorrespondentDescription);
	
	// In "DIB exchange over a web service" scenario authentication parameters (user name and password) 
	// stored in the infobase are redefined.
	// In "non-DIB exchange over a web service" scenario authentication parameters are only redefined 
	// (requested) if the infobase does not store the password.
	UseCurrentUserForAuthentication = False;
	UseSavedAuthenticationParameters    = False;
	SynchronizationPasswordSpecified                          = False;
	SyncPasswordSaved                       = False; // Password is saved in a safe storage (available in the background job)
	WSPassword                                          = "";
	
	If MessagesTransportKind = Enums.ExchangeMessagesTransportTypes.WS Then
		
		If DataExchangeCached.IsDistributedInfobaseNode(InfobaseNode) Then
			
			// It is DIB and exchange by WS, using the current user and password from the session.
			UseCurrentUserForAuthentication = True;
			SynchronizationPasswordSpecified = DataExchangeServer.DataSynchronizationPasswordSpecified(InfobaseNode);
			
		Else
			
			// If the current infobase is not a DIB node, reading the transport settings from the infobase.
			TransportSettings = InformationRegisters.DataExchangeTransportSettings.TransportSettingsWS(InfobaseNode);
			SynchronizationPasswordSpecified = TransportSettings.WSRememberPassword;
			If SynchronizationPasswordSpecified Then
				SyncPasswordSaved = True;
				UseSavedAuthenticationParameters = True;
			Else
				// If user name and password are not available in the register, using the session user name and password.
				SynchronizationPasswordSpecified = DataExchangeServer.DataSynchronizationPasswordSpecified(InfobaseNode);
				If SynchronizationPasswordSpecified Then
					UseSavedAuthenticationParameters = True;
				EndIf;
			EndIf;
			
		EndIf;
		
	EndIf;
	
	HasErrors = ((DataExchangeServer.MasterNode() = InfobaseNode) AND ConfigurationChanged());
	
	BackgroundJobUseProgress = Not ExchangeBetweenSaaSApplications
		AND Not (MessagesTransportKind = Enums.ExchangeMessagesTransportTypes.WS);
		
	ActivePasswordPromptPage = Not HasErrors
		AND (MessagesTransportKind = Enums.ExchangeMessagesTransportTypes.WS)
		AND Not (SynchronizationPasswordSpecified AND NoLongSynchronizationPrompt);
		
	Items.LongSyncWarningGroup.Visible = ActivePasswordPromptPage AND Not NoLongSynchronizationPrompt;
	Items.PromptForPasswordGroup.Visible                     = ActivePasswordPromptPage AND Not SynchronizationPasswordSpecified;
		
	WindowOptionsKey = ?(SynchronizationPasswordSpecified AND NoLongSynchronizationPrompt,
		"SynchronizationPasswordSpecified", "") + "/" + ?(NoLongSynchronizationPrompt, "NoLongSynchronizationPrompt", "");
		
	FillNavigationTable();
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	SetNavigationNumber(1);
	
EndProcedure

&AtClient
Procedure OnClose(Exit)
	
	If Exit Then
		Return;
	EndIf;
	
	If TimeConsumingOperation Then
		EndExecutingTimeConsumingOperation(BackgroundJobID);
	EndIf;
	
	If ValueIsFilled(FormReopeningParameters)
		AND FormReopeningParameters.Property("NewDataSynchronizationSetting") Then
		
		NewDataSynchronizationSetting = FormReopeningParameters.NewDataSynchronizationSetting;
		
		FormParameters = New Structure;
		FormParameters.Insert("InfobaseNode",                    NewDataSynchronizationSetting);
		FormParameters.Insert("AccountPasswordRecoveryAddress", AccountPasswordRecoveryAddress);
		
		OpeningParameters = New Structure;
		OpeningParameters.Insert("WindowOpeningMode", FormWindowOpeningMode.LockOwnerWindow);
		
		DataExchangeClient.OpenFormAfterClosingCurrentOne(ThisObject,
			"DataProcessor.DataExchangeExecution.Form.Form", FormParameters, OpeningParameters);
		
	Else
		SaveLongSynchronizationRequestFlag();
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandHandlers

&AtClient
Procedure GoToEventLog(Command)
	
	FormParameters = EventLogFilterData(InfobaseNode);
	OpenForm("DataProcessor.EventLog.Form", FormParameters, ThisObject);
	
EndProcedure

&AtClient
Procedure InstallUpdate(Command)
	
	Close();
	DataExchangeClient.InstallConfigurationUpdate(Exit);
	
EndProcedure

&AtClient
Procedure ForgotPassword(Command)
	
	DataExchangeClient.OpenInstructionHowToChangeDataSynchronizationPassword(AccountPasswordRecoveryAddress);
	
EndProcedure

&AtClient
Procedure RunExchange(Command)
	
	GoNextExecute();
	
EndProcedure

&AtClient
Procedure ContinueSync(Command)
	
	SwitchNumber = SwitchNumber - 1;
	SetNavigationNumber(SwitchNumber + 1);
	
EndProcedure

#EndRegion

#Region Private

////////////////////////////////////////////////////////////////////////////////
// SUPPLIED PART
////////////////////////////////////////////////////////////////////////////////

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

&AtClient
Procedure GoNextExecute()
	
	ChangeNavigationNumber(+1);
	
EndProcedure

&AtClient
Procedure ChangeNavigationNumber(Iterator)
	
	ClearMessages();
	SetNavigationNumber(SwitchNumber + Iterator);
	
EndProcedure

&AtClient
Procedure SetNavigationNumber(Val Value)
	
	IsMoveNext = (Value > SwitchNumber);
	
	SwitchNumber = Value;
	
	If SwitchNumber < 0 Then
		SwitchNumber = 0;
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
	
	Items.DataExchangeExecution.CurrentPage = Items[NavigationRowCurrent.MainPageName];
	
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
				
				CalculationResult = Eval(ProcedureName);
				
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
				
				CalculationResult = Eval(ProcedureName);
				
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
		
		CalculationResult = Eval(ProcedureName);
		
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
		
		CalculationResult = Eval(ProcedureName);
		
		If Cancel Then
			
			If VersionMismatchErrorOnGetData <> Undefined AND VersionMismatchErrorOnGetData.HasError Then
				
				ProcessVersionDifferenceError();
				Return;
				
			EndIf;
			
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

// Adds a new row to the end of the current navigation table.
//
// Parameters:
//
//  MainPageName (required) - String. Name of the MainPanel panel page that matches the current step 
//  number.
//  OnOpenHandlerName (optional) - String. Name of the "open current wizard page" event handler.
//  
//  TimeConsumingOperation (optional) - Boolean. Indicates whether a time-consuming operation page is displayed.
//  True - a time-consuming operation page is displayed; False - a standard page is displayed. Default value -
//  False.
// 
&AtServer
Function NavigationTableNewRow(MainPageName,
		OnOpenHandlerName = "",
		TimeConsumingOperation = False,
		TimeConsumingOperationHandlerName = "")
		
	NewRow = NavigationTable.Add();
	
	NewRow.SwitchNumber = NavigationTable.Count();
	NewRow.MainPageName     = MainPageName;
	
	NewRow.OnSwitchToNextPageHandlerName = "";
	NewRow.OnSwitchToPreviousPageHandlerName = "";
	NewRow.OnOpenHandlerName      = OnOpenHandlerName;
	
	NewRow.TimeConsumingOperation = TimeConsumingOperation;
	NewRow.TimeConsumingOperationHandlerName = TimeConsumingOperationHandlerName;
	
	Return NewRow;
	
EndFunction

////////////////////////////////////////////////////////////////////////////////
// OVERRIDABLE PART
////////////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////////////
// PROCEDURES AND FUNCTIONS SECTION

&AtClient
Procedure ExecuteGoNext()
	
	GoToNext      = True;
	GoNextExecute();
	
EndProcedure

&AtClient
Procedure ProcessVersionDifferenceError()
	
	Items.DataExchangeExecution.CurrentPage = Items.ExchangeCompletion;
	Items.ExchangeCompletionStatus.CurrentPage = Items.VersionsDifferenceError;
	Items.ActionsPanel.CurrentPage = Items.ActionsContinueCancel;
	Items.ContinueSync.DefaultButton = True;
	Items.VersionsDifferenceErrorDecoration.Title = VersionMismatchErrorOnGetData.ErrorText;
	
	CheckVersionDifference = False;
	
EndProcedure

&AtClient
Procedure SaveLongSynchronizationRequestFlag()
	
	Settings = Undefined;
	If SaveLongSynchronizationRequestFlagServer(Not NoLongSynchronizationPrompt, Settings) Then
		ChangedSettings = New Array;
		ChangedSettings.Add(Settings);
		Notify("UserSettingsChanged", ChangedSettings, ThisObject);
	EndIf;
	
EndProcedure

&AtClient
Procedure InitializeDataProcessorVariables()
	
	// Initialization of data processor variables
	ProgressPercent                   = 0;
	MessageFileIDInService = "";
	TimeConsumingOperationID     = "";
	ProgressAdditionalInformation             = "";
	TimeConsumingOperation                  = False;
	TimeConsumingOperationCompleted         = False;
	TimeConsumingOperationCompletedWithError = False;
	
EndProcedure

&AtServer
Procedure CheckWhetherTransferToNewExchangeIsRequired()
	
	MessagesArray = GetUserMessages(True);
	
	If MessagesArray = Undefined Then
		Return;
	EndIf;
	
	Count = MessagesArray.Count();
	If Count = 0 Then
		Return;
	EndIf;
	
	Message      = MessagesArray[Count-1];
	MessageText = Message.Text;
	
	// A subsystem ID is deleted from the message if necessary.
	If StrStartsWith(MessageText, "{MigrationToNewExchangeDone}") Then
		
		MessageData = Common.ValueFromXMLString(MessageText);
		
		If MessageData <> Undefined
			AND TypeOf(MessageData) = Type("Structure") Then
			
			ExchangePlanName                    = MessageData.ExchangePlanNameToMigrateToNewExchange;
			ExchangePlanNodeCode                = MessageData.Code;
			NewDataSynchronizationSetting = ExchangePlans[ExchangePlanName].FindByCode(ExchangePlanNodeCode);
			
			BackgroundJobExecutionResult.AdditionalResultData.Insert("FormReopeningParameters",
				New Structure("NewDataSynchronizationSetting", NewDataSynchronizationSetting));
				
			BackgroundJobExecutionResult.AdditionalResultData.Insert("ForceCloseForm", True);
			
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure InitializeAuthenticationParameters(AuthenticationParameters)
	
	If UseSavedAuthenticationParameters Then
		If Not SyncPasswordSaved Then
			AuthenticationParameters = New Structure;
			AuthenticationParameters.Insert("UseCurrentUser", UseCurrentUserForAuthentication);
		EndIf;
	Else
		AuthenticationParameters = New Structure;
		AuthenticationParameters.Insert("UseCurrentUser", UseCurrentUserForAuthentication);
		If Not SynchronizationPasswordSpecified Then
			AuthenticationParameters.Insert("Password", WSPassword);
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure TestConnection(HasConnection)
	
	AuthenticationParameters = Undefined;
	InitializeAuthenticationParameters(AuthenticationParameters);
	
	TestConnectionAtServer(HasConnection, AuthenticationParameters);
	
EndProcedure

&AtServer
Procedure TestConnectionAtServer(HasConnection, AuthenticationParameters)
	
	SetPrivilegedMode(True);
	AttachmentParameters = InformationRegisters.DataExchangeTransportSettings.TransportSettingsWS(InfobaseNode, AuthenticationParameters);
	
	DataSyncDisabled = False;
	UserErrorMessage = "";
	SetupCompleted = True;
	DataReceivedForMapping = False;
	
	HasConnection = DataExchangeServer.CorrespondentConnectionEstablished(InfobaseNode,
		AttachmentParameters, UserErrorMessage, SetupCompleted, DataReceivedForMapping);
	
	If Not HasConnection Then
		ErrorMessage = NStr("ru = 'Не удалось подключиться к приложению в Интернете, по причине ""%1"".
			|Убедитесь, что:
			|- введен правильный пароль;
			|- указан корректный адрес для подключения;
			|- приложение доступно по указанному в настройках адресу;
			|- настройка синхронизации не была удалена в приложении в Интернете.
			|Повторите попытку синхронизации.'; 
			|en = 'Cannot connect to the web application. Reason: ""%1""
			|Ensure that:
			|- The password is correct.
			|- The connection address is correct.
			|- The application is available at the address specified in the settings.
			|- The synchronization settings were not deleted from the web application.
			|Then retry the synchronization.'; 
			|pl = 'Nie można połączyć się z aplikacją przez Internet z powodu ""%1"". 
			|Upewnij się, że:
			|- zostało wpisane poprawne hasło;
			|- podano poprawny adres połączenia;
			|- aplikacja jest dostępna pod adresem określonym w ustawieniach;
			|- ustawienie synchronizacji nie zostało usunięte w aplikacji w Internecie.
			|Ponów próbę synchronizacji.';
			|de = 'Die Verbindung zur Anwendung im Internet konnte wegen ""%1"" nicht hergestellt werden.
			|Stellen Sie sicher, dass:
			|- das richtige Passwort eingegeben wird;
			|- die richtige Adresse für die Verbindung angegeben wird;
			|- die Anwendung an der in den Einstellungen angegebenen Adresse verfügbar ist;
			|- die Synchronisationseinstellung nicht aus der Anwendung im Internet entfernt wurde.
			|Wiederholen Sie den Synchronisationsversuch.';
			|ro = 'Eșec de conectare la aplicația în Internet din motivul ""%1"".
			|Convingeți-vă că:
			|- este introdusă parola corectă;
			|- este indicată adresa corectă pentru conectare;
			|- aplicația este accesibilă la adresa indicată în setări;
			|- setarea sincronizării nu a fost ștearsă în aplicația din Internet.
			|Repetați tentativa de sincronizare.';
			|tr = '""%1""nedeniyle İnternet''te uygulamaya bağlanılamadı. 
			|
			| - doğru şifreyi girdiğinizden; 
			|- bağlanmak için doğru adres belirtildiğinden; 
			|- uygulama ayarlarında belirtilen adreste mevcut olduğundan; 
			|- senkronizasyon ayarı İnternet uygulamasında silinmediğimden emin olun. 
			|Tekrar eşleştirmeye deneyin.'; 
			|es_ES = 'No se ha podido conectarse con la aplicación en Internet a causa de ""%1"".
			|Asegúrese de que:
			|- se ha introducido una contraseña correcta;
			|- se ha indicado una dirección correcta para conectar;
			|- la aplicación está disponible por la dirección indicada en los ajustes;
			|- el ajuste de sincronización no se ha eliminado en la aplicación en Internet.
			|Vuelva a probar la sincronización.'");
		ErrorMessage = StringFunctionsClientServer.SubstituteParametersToString(ErrorMessage, UserErrorMessage);
		If ActivePasswordPromptPage Then
			Common.MessageToUser(ErrorMessage);
		EndIf;
		DataSyncDisabled = True;
	ElsIf Not SetupCompleted Then
		UserErrorMessage = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Для продолжения необходимо перейти в программу ""%1"" и завершить в ней настройку синхронизации. Выполнение обмена данными отменено.'; en = 'To continue, open %1 and complete the synchronization setup there.\nThe data exchange is canceled.'; pl = 'Aby kontynuować, musisz przejść do programu ""%1"" i zakończyć w nim konfigurację synchronizacji. Wymiana danych została anulowana.';de = 'Um fortzufahren, gehen Sie zum Programm ""%1"" und beenden Sie die Synchronisationseinstellung darin. Der Datenaustausch wird abgebrochen.';ro = 'Pentru continuare trebuie să treceți în aplicația ""%1"" și să finalizați setarea sincronizării în ea. Executarea schimbului de date este revocată.';tr = 'Devam etmek için ""%1"" programına geçmeniz ve eşleşme ayarlarını tamamlamanız gerekir. Veri alışverişi iptal edildi.'; es_ES = 'Para continuar es necesario pasar al programa ""%1"" y terminar de ajustar la sincronización en él. Ejecución de intercambio de datos cancelada.'"),
			CorrespondentDescription);
		DataSyncDisabled = True;
	ElsIf DataReceivedForMapping Then
		UserErrorMessage = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Для продолжения необходимо перейти в программу ""%1"" и выполнить загрузку сообщения для сопоставления данных. Выполнение обмена данными отменено.'; en = 'To continue, open %1 and import the data mapping message.\nThe data exchange is canceled.'; pl = 'Aby kontynuować, musisz przejść do programu ""%1"" i pobrać wiadomość, aby dopasować dane. Wymiana danych została anulowana.';de = 'Um fortzufahren, müssen Sie zum Programm ""%1"" gehen und die Meldung herunterladen, um die Daten zu vergleichen. Der Datenaustausch wurde abgebrochen.';ro = 'Pentru continuare trebuie să treceți în aplicația ""%1"" și să executați importul mesajului pentru confruntarea datelor. Executarea schimbului de date este revocată.';tr = 'Devam etmek için ""%1"" programına geçmeniz ve veri karşılaştırmak için mesajı içe aktarmanız gerekir. Veri alışverişi iptal edildi.'; es_ES = 'Para continuar es necesario pasar al programa ""%1"" y cargar el mensaje para comparar los datos. Ejecución de intercambio de datos cancelada.'"),
			CorrespondentDescription);
		DataSyncDisabled = True;
	EndIf;
	
EndProcedure

&AtServerNoContext
Function EventLogFilterData(InfobaseNode)
	
	SelectedEvents = New Array;
	SelectedEvents.Add(DataExchangeServer.EventLogMessageKey(InfobaseNode, Enums.ActionsOnExchange.DataImport));
	SelectedEvents.Add(DataExchangeServer.EventLogMessageKey(InfobaseNode, Enums.ActionsOnExchange.DataExport));
	
	DataExchangesStatesImport = DataExchangeServer.DataExchangesStates(InfobaseNode, Enums.ActionsOnExchange.DataImport);
	DataExchangesStatesExport = DataExchangeServer.DataExchangesStates(InfobaseNode, Enums.ActionsOnExchange.DataExport);
	
	Result = New Structure;
	Result.Insert("EventLogEvent", SelectedEvents);
	Result.Insert("StartDate",    Min(DataExchangesStatesImport.StartDate, DataExchangesStatesExport.StartDate));
	Result.Insert("EndDate", Max(DataExchangesStatesImport.EndDate, DataExchangesStatesExport.EndDate));
	
	Return Result;
	
EndFunction

&AtServerNoContext
Function SaveLongSynchronizationRequestFlagServer(Val Flag, Settings = Undefined)
	
	If Common.SubsystemExists("SaaSTechnology.SaaS.DataExchangeSaaS")
		AND DataExchangeServer.IsStandaloneWorkplace() Then
		
		ModuleStandaloneMode = Common.CommonModule("StandaloneMode");
		MustSave = Flag <> ModuleStandaloneMode.LongSynchronizationQuestionSetupFlag();
		
		If MustSave Then
			ModuleStandaloneMode.LongSynchronizationQuestionSetupFlag(Flag, Settings);
		EndIf;
		
	Else
		MustSave = False;
	EndIf;
	
	Return MustSave;
EndFunction

&AtServerNoContext
Procedure EndExecutingTimeConsumingOperation(JobID)
	TimeConsumingOperations.CancelJobExecution(JobID);
EndProcedure

&AtServerNoContext
Function UpdateInstallationRequired()
	
	Return DataExchangeServer.UpdateInstallationRequired();
	
EndFunction

////////////////////////////////////////////////////////////////////////////////
// SECTION OF STEP CHANGE HANDLERS

////////////////////////////////////////////////////////////////////////////////
// Common exchange pages

&AtClient
Function Attachable_DataImport_OnOpen(Cancel, SkipPage, IsMoveNext)
	
	If DataSyncDisabled Then
		SkipPage = True;
	Else
		InitializeDataProcessorVariables();
	EndIf;
	
	Return Undefined;
	
EndFunction

&AtClient
Function Attachable_DataImport_TimeConsumingOperationProcessing(Cancel, GoToNext)
	
	If DataSyncDisabled Then
		GoToNext = True;
	Else
		GoToNext = False;
		
		BackgroundJobCurrentAction = 1;
		BackgroundJobStartClient(BackgroundJobCurrentAction,
			"DataProcessors.DataExchangeExecution.StartDataExchangeExecution",
			Cancel);
	EndIf;
	
	Return Undefined;
	
EndFunction

&AtClient
Function Attachable_DataExport_OnOpen(Cancel, SkipPage, IsMoveNext)
	
	If DataSyncDisabled Then
		SkipPage = True;
	Else
		InitializeDataProcessorVariables();
	EndIf;
	
	Return Undefined;
	
EndFunction

&AtClient
Function Attachable_DataExport_TimeConsumingOperationProcessing(Cancel, GoToNext)
	
	If DataSyncDisabled Then
		GoToNext = True;
	Else
		GoToNext = False;
		OnStartExportData(Cancel);
	EndIf;
	
	Return Undefined;
	
EndFunction

&AtClient
Function Attachable_DataExport_TimeConsumingOperationProcessing_End(Cancel, GoToNext)
	
	If TimeConsumingOperationCompleted
		AND Not TimeConsumingOperationCompletedWithError Then
		DataExchangeServerCall.RecordDataExportInTimeConsumingOperationMode(
			InfobaseNode,
			OperationStartDate);
	EndIf;
	
	Return Undefined;
	
EndFunction

&AtClient
Procedure OnStartExportData(Cancel)
	
	If ExchangeBetweenSaaSApplications Then
		ContinueWait = True;
		OnStartExportDataAtServer(ContinueWait);
		
		If ContinueWait Then
			DataExchangeClient.InitializeIdleHandlerParameters(
				DataExportIdleHandlerParameters);
				
			AttachIdleHandler("OnWaitForExportData",
				DataExportIdleHandlerParameters.CurrentInterval, True);
		Else
			OnCompleteDataExport();
		EndIf;
	Else
		BackgroundJobCurrentAction = 2;
		BackgroundJobStartClient(BackgroundJobCurrentAction,
			"DataProcessors.DataExchangeExecution.StartDataExchangeExecution", Cancel);
	EndIf;
	
EndProcedure

&AtClient
Procedure OnWaitForExportData()
	
	ContinueWait = False;
	OnWaitForExportDataAtServer(DataExportHandlerParameters, ContinueWait);
	
	If ContinueWait Then
		DataExchangeClient.UpdateIdleHandlerParameters(DataExportIdleHandlerParameters);
		
		AttachIdleHandler("OnWaitForExportData",
			DataExportIdleHandlerParameters.CurrentInterval, True);
	Else
		OnCompleteDataExport();
	EndIf;
	
EndProcedure

&AtClient
Procedure OnCompleteDataExport()
	
	DataExported = False;
	ErrorMessage = "";
	
	OnCompleteDataExportAtServer(DataExportHandlerParameters, DataExported, ErrorMessage);
	
	TimeConsumingOperationCompleted = True;
	TimeConsumingOperationCompletedWithError = Not DataExported;
	HasErrors = HasErrors Or Not DataExported;
	OutputErrorDescriptionToUser = True;
	UserErrorMessage = ErrorMessage;
	
	ChangeNavigationNumber(+1);
	
EndProcedure

&AtServer
Procedure OnStartExportDataAtServer(ContinueWait)
	
	ModuleInteractiveExchangeWizard = DataExchangeServer.ModuleInteractiveDataExchangeWizardInSaaS();
	
	If ModuleInteractiveExchangeWizard = Undefined Then
		ContinueWait = False;
		Return;
	EndIf;
	
	ExportSettings = New Structure;
	ExportSettings.Insert("Correspondent",               InfobaseNode);
	ExportSettings.Insert("CorrespondentDataArea", CorrespondentDataArea);
	
	DataExportHandlerParameters = Undefined;
	ModuleInteractiveExchangeWizard.OnStartExportData(ExportSettings,
		DataExportHandlerParameters, ContinueWait);
	
EndProcedure
	
&AtServerNoContext
Procedure OnWaitForExportDataAtServer(HandlerParameters, ContinueWait)
	
	ModuleInteractiveExchangeWizard = DataExchangeServer.ModuleInteractiveDataExchangeWizardInSaaS();
	
	If ModuleInteractiveExchangeWizard = Undefined Then
		ContinueWait = False;
	EndIf;
	
	ModuleInteractiveExchangeWizard.OnWaitForExportData(HandlerParameters, ContinueWait);
	
EndProcedure

&AtServerNoContext
Procedure OnCompleteDataExportAtServer(HandlerParameters, DataExported, ErrorMessage)
	
	ModuleInteractiveExchangeWizard = DataExchangeServer.ModuleInteractiveDataExchangeWizardInSaaS();
	
	If ModuleInteractiveExchangeWizard = Undefined Then
		DataExported = False;
		Return;
	EndIf;
	
	CompletionStatus = Undefined;
	
	ModuleInteractiveExchangeWizard.OnCompleteExportData(HandlerParameters, CompletionStatus);
	HandlerParameters = Undefined;
		
	If CompletionStatus.Cancel Then
		DataExported = False;
		ErrorMessage = CompletionStatus.ErrorMessage;
		Return;
	Else
		DataExported = CompletionStatus.Result.DataExported;
		
		If Not DataExported Then
			ErrorMessage = CompletionStatus.Result.ErrorMessage;
			Return;
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Function Attachable_ExchangeCompletion_OnOpen(Cancel, SkipPage, IsMoveNext)
	
	Items.ActionsPanel.CurrentPage = Items.ActionsClose;
	Items.FormClose.DefaultButton = True;
	
	ExchangeCompletedWithErrorPage = ?(DataExchangeAdministrationRoleAssigned,
		Items.ExchangeCompletedWithErrorForAdministrator,
		Items.ExchangeCompletedWithError);
	
	If DataSyncDisabled Then
		
		Items.ExchangeCompletionStatus.CurrentPage = Items.ExchangeCompletedWithConnectionError;
		
	ElsIf HasErrors Then
		
		If UpdateRequired Or UpdateInstallationRequired() Then
			
			If RoleAvailableFullAccess Then 
				Items.ActionsPanel.CurrentPage = Items.ActionsInstallClose;
				Items.InstallUpdate.DefaultButton = True;
			EndIf;
			
			Items.ExchangeCompletionStatus.CurrentPage = Items.ExchangeCompletedWithErrorUpdateRequired;
			
			Items.PanelUpdateRequired.CurrentPage = ?(RoleAvailableFullAccess, 
				Items.UpdateRequiredFullAccess, Items.UpdateRequiredRestrictedAccess);
				
			Items.UpdateRequiredTextFullAccess.Title = StringFunctionsClientServer.SubstituteParametersToString(
				Items.UpdateRequiredTextFullAccess.Title, CorrespondentDescription);
				
			Items.UpdateRequiredTextRestrictedAccess.Title = StringFunctionsClientServer.SubstituteParametersToString(
				Items.UpdateRequiredTextRestrictedAccess.Title, CorrespondentDescription);
			
		Else
				
			Items.ExchangeCompletionStatus.CurrentPage = ExchangeCompletedWithErrorPage;
			
			If OutputErrorDescriptionToUser Then
				CommonClient.MessageToUser(UserErrorMessage);
			EndIf;
			
		EndIf;
		
	Else
		
		Items.ExchangeCompletionStatus.CurrentPage = Items.ExchangeSucceeded;
		
	EndIf;
	
	// Updating all opened dynamic lists.
	DataExchangeClient.RefreshAllOpenDynamicLists();
	
	Return Undefined;
	
EndFunction

&AtClient
Function Attachable_ExchangeCompletion_TimeConsumingOperationProcessing(Cancel, GoToNext)
	
	GoToNext = False;
	
	Notify("DataExchangeCompleted");
	
	If CloseOnSynchronizationDone
		AND Not DataSyncDisabled
		AND Not HasErrors Then
		
		Close();
	EndIf;
	
	Return Undefined;
	
EndFunction

////////////////////////////////////////////////////////////////////////////////
// Pages of exchange over a web service

&AtClient
Function Attachable_UserPasswordRequest_OnOpen(Cancel, SkipPage, IsMoveNext)
	
	Items.ForgotPassword.Visible = Not IsBlankString(AccountPasswordRecoveryAddress);
	
	Items.RunExchange.DefaultButton = True;
	
	Return Undefined;
	
EndFunction

&AtClient
Function Attachable_UserPasswordRequest_OnGoNext(Cancel)
	
	If Not SynchronizationPasswordSpecified
		AND IsBlankString(WSPassword) Then
		CommonClient.MessageToUser(NStr("ru = 'Не указан пароль.'; en = 'The password is blank.'; pl = 'Hasło nie zostało określone.';de = 'Passwort ist nicht angegeben.';ro = 'Parola nu este specificată.';tr = 'Şifre belirtilmemiş.'; es_ES = 'Contraseña no está especificada.'"), , "WSPassword", , Cancel);
		Return Undefined;
	EndIf;
	
	SaveLongSynchronizationRequestFlag();
	
EndFunction

&AtClient
Function Attachable_ConnectionCheckWait_TimeConsumingOperationProcessing(Cancel, GoToNext)
	
	If ConnectOverExternalConnection Then
		If CommonClient.FileInfobase() Then
			CommonClient.RegisterCOMConnector(False);
		EndIf;
		Return Undefined;
	EndIf;
	
	HasConnection = False;
	TestConnection(HasConnection);
	If HasConnection Then
		WSPassword = String(New UUID);
		UseSavedAuthenticationParameters = True;
		SynchronizationPasswordSpecified = True;
	Else
		If ActivePasswordPromptPage Then
			Cancel = True;
		EndIf;
	EndIf;
	GoToNext = Not Cancel;
	
EndFunction

////////////////////////////////////////////////////////////////////////////////
// SECTION OF PROCESSING BACKGROUND JOBS

&AtClient
Procedure BackgroundJobStartClient(Action, JobName, Cancel)
	
	JobParameters = New Structure;
	JobParameters.Insert("JobName",                          JobName);
	JobParameters.Insert("Cancel",                               Cancel);
	JobParameters.Insert("InfobaseNode",              InfobaseNode);
	JobParameters.Insert("ExecuteImport",                   BackgroundJobCurrentAction = 1);
	JobParameters.Insert("ExecuteExport",                   BackgroundJobCurrentAction = 2);
	JobParameters.Insert("ExchangeMessagesTransportKind",        MessagesTransportKind);
	JobParameters.Insert("TimeConsumingOperation",                  TimeConsumingOperation);
	JobParameters.Insert("TimeConsumingOperationID",     TimeConsumingOperationID);
	JobParameters.Insert("MessageFileIDInService", MessageFileIDInService);
	
	Result = BackgroundJobStartAtServer(JobParameters, VersionMismatchErrorOnGetData, CheckVersionDifference);
	
	If Result = Undefined Then
		Cancel = True;
		Return;
	EndIf;
	
	If Result.Status = "Running" Then
		
		IdleParameters = TimeConsumingOperationsClient.IdleParameters(ThisObject);
		IdleParameters.OutputIdleWindow  = False;
		IdleParameters.OutputMessages     = True;
		
		If BackgroundJobUseProgress Then
			IdleParameters.OutputProgressBar     = True;
			IdleParameters.ExecutionProgressNotification = New NotifyDescription("BackgroundJobExecutionProgress", ThisObject);
			IdleParameters.Interval                       = 1;
		EndIf;
		
		CompletionNotification = New NotifyDescription("BackgroundJobCompletion", ThisObject);
		TimeConsumingOperationsClient.WaitForCompletion(Result, CompletionNotification, IdleParameters);
		
	Else
		BackgroundJobExecutionResult = Result;
		AttachIdleHandler("BackgroundJobExecutionResult", 0.1, True);
	EndIf;
	
EndProcedure

&AtClient
Procedure BackgroundJobCompletion(Result, AdditionalParameters) Export
	
	BackgroundJobExecutionResult = Result;
	BackgroundJobExecutionResult();
	
EndProcedure

&AtClient
Procedure BackgroundJobExecutionProgress(Progress, AdditionalParameters) Export
	
	If Progress = Undefined Then
		Return;
	EndIf;
	
	If Progress.Progress <> Undefined Then
		ProgressStructure      = Progress.Progress;
		
		AdditionalProgressParameters = Undefined;
		If Not ProgressStructure.Property("AdditionalParameters", AdditionalProgressParameters) Then
			Return;
		EndIf;
		
		If Not AdditionalProgressParameters.Property("DataExchange") Then
			Return;
		EndIf;
		
		ProgressPercent       = ProgressStructure.Percent;
		ProgressAdditionalInformation = ProgressStructure.Text;
	EndIf;
	
EndProcedure

&AtClient
Procedure BackgroundJobExecutionResult()
	
	BackgroundJobGetResultAtServer();
	
	// If data exchange is performed with the application on the Internet, then you need to wait until 
	// the synchronization is completed on the correspondent side.
	If TimeConsumingOperation Then
		AttachIdleHandler("TimeConsumingOperationIdleHandler", 0.1, True);
	Else
		AttachIdleHandler("TimeConsumingOperationCompletion", 0.1, True);
	EndIf;
	
EndProcedure

&AtClient
Procedure TimeConsumingOperationIdleHandler()
	
	TimeConsumingOperationCompletedWithError = False;
	ErrorMessage                   = "";
	
	AuthenticationParameters = Undefined;
	InitializeAuthenticationParameters(AuthenticationParameters);
	
	ActionState = DataExchangeServerCall.TimeConsumingOperationStateForInfobaseNode(
		TimeConsumingOperationID,
		InfobaseNode,
		AuthenticationParameters,
		ErrorMessage);
	
	If ActionState = "Active" Then
		AttachIdleHandler("TimeConsumingOperationIdleHandler", 5, True);
	Else
		
		If ActionState <> "Completed" Then
			TimeConsumingOperationCompletedWithError = True;
			HasErrors                          = True;
		EndIf;
		
		TimeConsumingOperation              = False;
		TimeConsumingOperationCompleted     = True;
		TimeConsumingOperationID = "";
		
		AttachIdleHandler("TimeConsumingOperationCompletion", 0.1, True);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure TimeConsumingOperationCompletion()
	
	If BackgroundJobUseProgress Then
		ProgressPercent       = 100;
		ProgressAdditionalInformation = "";
	EndIf;
	
	If TimeConsumingOperationCompletedWithError Then
		MessageFileIDInService = "";
	Else
		
		// If a long-term data acquisition from an application on the Internet was performed, then it is 
		// necessary to import the received file with data to the base.
		If BackgroundJobCurrentAction = 1 
			AND ValueIsFilled(MessageFileIDInService) Then
				
			BackgroundJobStartClient(BackgroundJobCurrentAction,
				"DataProcessors.DataExchangeExecution.ImportFileDownloadedFromInternet",
				False);
				
		EndIf;
		
	EndIf;
	
	If Not ValueIsFilled(MessageFileIDInService) Then
		AfterCompleteBackgroundJob();
	EndIf;
	
EndProcedure

&AtClient
Procedure AfterCompleteBackgroundJob()
	
	// Migration to new exchange is completed. Close the form and open it again with other parameters.
	If BackgroundJobExecutionResult.AdditionalResultData.Property("ForceCloseForm") 
		AND BackgroundJobExecutionResult.AdditionalResultData.ForceCloseForm Then
		FormReopeningParameters = BackgroundJobExecutionResult.AdditionalResultData.FormReopeningParameters;
		ThisObject.Close();
	EndIf;
	
	// Go further with a one second delay to display the progress bar 100%.
	AttachIdleHandler("ExecuteGoNext", 0.1, True);
	
EndProcedure

&AtServer
Function BackgroundJobStartAtServer(JobParameters, VersionDifferenceErrorOnGetData, CheckVersionDifference)
	
	If JobParameters.ExecuteImport Then
		
		If CheckVersionDifference Then
			DataExchangeServer.InitializeVersionDifferenceCheckParameters(CheckVersionDifference);
		EndIf;
		
		DescriptionTemplate = NStr("ru = 'Выполняется загрузка данных из %1'; en = 'Importing data from %1'; pl = 'Importowanie danych z %1';de = 'Die Daten werden heruntergeladen aus %1';ro = 'Are loc importul de date din %1';tr = '%1''den veriler içe aktarılıyor'; es_ES = 'Se están descargando los datos de %1'");
		
	Else
		DescriptionTemplate = NStr("ru = 'Выполняется выгрузка данных в %1'; en = 'Exporting data to %1'; pl = 'Jest wykonywane przesyłanie danych do %1';de = 'Die Daten werden hochgeladen zu %1';ro = 'Are loc exportul de date în %1';tr = 'Veriler %1''e aktarılıyor'; es_ES = 'Se están subiendo los datos a %1'");
	EndIf;
	
	JobDescription = StringFunctionsClientServer.SubstituteParametersToString(
		DescriptionTemplate, JobParameters.InfobaseNode);
	
	ExecutionParameters = TimeConsumingOperations.BackgroundExecutionParameters(UUID);
	ExecutionParameters.BackgroundJobDescription = JobDescription;
	ExecutionParameters.WaitForCompletion = 0;
	
	OperationStartDate = CurrentSessionDate();
	JobParameters.Insert("OperationStartDate", OperationStartDate);
	
	AuthenticationParameters = Undefined;
	If Not SyncPasswordSaved Then
		If UseCurrentUserForAuthentication Then
			AuthenticationParameters = New Structure;
			AuthenticationParameters.Insert("UseCurrentUser", True);
			AuthenticationParameters.Insert("Password",
				DataExchangeServer.DataSynchronizationPassword(InfobaseNode));
		Else
			AuthenticationParameters = DataExchangeServer.DataSynchronizationPassword(InfobaseNode);
		EndIf;
	EndIf;
	JobParameters.Insert("AuthenticationParameters", AuthenticationParameters);
	
	Result = TimeConsumingOperations.ExecuteInBackground(
		JobParameters.JobName,
		JobParameters,
		ExecutionParameters);
		
	BackgroundJobID  = Result.JobID;
	BackgroundJobStorageAddress = Result.ResultAddress;
	
	Return Result;
	
EndFunction

&AtServer
Procedure BackgroundJobGetResultAtServer()
	
	If BackgroundJobExecutionResult = Undefined Then
		BackgroundJobExecutionResult = New Structure;
		BackgroundJobExecutionResult.Insert("Status", Undefined);
	EndIf;
	
	BackgroundJobExecutionResult.Insert("AdditionalResultData", New Structure());
	
	ErrorMessage = "";
	
	StandardErrorPresentation = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("ru = 'Не удалось выполнить %1. Подробности см. в журнале регистрации'; en = 'Cannot %1. See the event log for details.'; pl = 'Nie udało się wykonać %1. Szczegóły zobacz w dzienniku rejestracji';de = 'Der Vorgang konnte nicht abgeschlossen werden %1. Weitere Informationen finden Sie im Ereignisprotokoll';ro = 'Eșec la executarea %1. Detalii vezi în registrul logare';tr = '""%1"" çalıştırılamadı. Ayrıntılar için olay günlüğüne bakın.'; es_ES = 'No se ha podido realizar %1. Véase más en el registro'"),
		?(BackgroundJobCurrentAction = 1, NStr("ru = 'получение данных'; en = 'receive data'; pl = 'pobieranie danych';de = 'Daten empfangen';ro = 'primirea datelor';tr = 'veri alınıyor'; es_ES = 'recepción de datos'"), NStr("ru = 'отправку данных'; en = 'send data'; pl = 'wysyłanie danych';de = 'Daten senden';ro = 'trimiterea datelor';tr = 'veriyi gönder'; es_ES = 'envío de datos'")));
	
	If BackgroundJobExecutionResult.Status = "Error" Then
		ErrorMessage = BackgroundJobExecutionResult.DetailedErrorPresentation;
	Else
		
		BackgroundExecutionResult = GetFromTempStorage(BackgroundJobStorageAddress);
		
		If BackgroundExecutionResult = Undefined Then
			ErrorMessage = StandardErrorPresentation;
		Else
			
			If BackgroundExecutionResult.ExecuteImport Then
				
				// Data on exchange rule version difference.
				VersionMismatchErrorOnGetData = DataExchangeServer.VersionMismatchErrorOnGetData();
				
				If VersionMismatchErrorOnGetData <> Undefined
					AND VersionMismatchErrorOnGetData.HasError = True Then
					ErrorMessage = VersionMismatchErrorOnGetData.ErrorText;
				EndIf;
				
				// Checking the transition to a new data exchange.
				CheckWhetherTransferToNewExchangeIsRequired();
				
				If BackgroundJobExecutionResult.AdditionalResultData.Property("FormReopeningParameters") Then
					Return;
				EndIf;
				
			EndIf;
			
			If BackgroundExecutionResult.Cancel AND Not ValueIsFilled(ErrorMessage) Then
				ErrorMessage = StandardErrorPresentation;
			EndIf;
			
			FillPropertyValues(
				ThisObject,
				BackgroundExecutionResult,
				"TimeConsumingOperation, TimeConsumingOperationID, MessageFileIDInService");
			
			DeleteFromTempStorage(BackgroundJobStorageAddress);
			
		EndIf;
		
		BackgroundJobStorageAddress = Undefined;
		BackgroundJobID  = Undefined;
		
	EndIf;
	
	// If errors occurred during data synchronization, record them.
	If ValueIsFilled(ErrorMessage) Then
		
		// If a time-consuming operation was started in the correspondent base, it must be completed.
		If Not TimeConsumingOperationCompleted Then
			EndExecutingTimeConsumingOperation(TimeConsumingOperationID);
		EndIf;
		
		TimeConsumingOperationCompleted         = True;
		TimeConsumingOperationCompletedWithError = True;
		
		HasErrors = True;
		
	EndIf;
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// FILLING WIZARD NAVIGATION TABLE SECTION

&AtServer
Procedure FillNavigationTable()
	
	NavigationTable.Clear();
	
	// Initializing the current exchange scenario.
	If HasErrors Then
		
		NavigationTableNewRow("ExchangeCompletion", "ExchangeCompletion_OnOpen");
		
	Else
		
		If BackgroundJobUseProgress Then
			PageNameSynchronizationImport = "DataSynchronizationWaitProgressBarImport";
			PageNameSynchronizationExport = "DataSynchronizationWaitProgressBarExport";
		Else
			PageNameSynchronizationImport = "DataSynchronizationWait";
			PageNameSynchronizationExport = "DataSynchronizationWait";
		EndIf;
		
		If ExchangeBetweenSaaSApplications Then
			// Getting and sending.
			NavigationTableNewRow(PageNameSynchronizationExport, "DataExport_OnOpen", True, "DataExport_TimeConsumingOperationProcessing");
			NavigationTableNewRow(PageNameSynchronizationExport, , True, "DataExport_TimeConsumingOperationProcessing_Completion");
		Else
			
			If ActivePasswordPromptPage Then
				NavigationRow = NavigationTableNewRow("UserPasswordRequest", "UserPasswordRequest_OnOpen");
				NavigationRow.OnSwitchToNextPageHandlerName = "UserPasswordRequest_OnGoNext";
			EndIf;
			
			If MessagesTransportKind = Enums.ExchangeMessagesTransportTypes.WS
				Or MessagesTransportKind = Enums.ExchangeMessagesTransportTypes.COM Then
				NavigationTableNewRow("DataSynchronizationWait", , True, "ConnectionTestWaiting_TimeConsumingOperationProcessing");
			EndIf;
			
			If ExecuteDataSending Then
				// Sending
				NavigationTableNewRow(PageNameSynchronizationExport, "DataExport_OnOpen", True, "DataExport_TimeConsumingOperationProcessing");
				NavigationTableNewRow(PageNameSynchronizationExport, , True, "DataExport_TimeConsumingOperationProcessing_Completion");
			EndIf;
			
			// Receiving
			NavigationTableNewRow(PageNameSynchronizationImport, "DataImport_OnOpen", True, "DataImport_TimeConsumingOperationProcessing");
			// Sending
			NavigationTableNewRow(PageNameSynchronizationExport, "DataExport_OnOpen", True, "DataExport_TimeConsumingOperationProcessing");
			NavigationTableNewRow(PageNameSynchronizationExport, , True, "DataExport_TimeConsumingOperationProcessing_Completion");
			
		EndIf;
		
		// Completing
		NavigationTableNewRow("ExchangeCompletion", "ExchangeCompletion_OnOpen", True, "ExchangeCompletion_TimeConsumingOperationProcessing");
		
	EndIf;
	
EndProcedure

#EndRegion