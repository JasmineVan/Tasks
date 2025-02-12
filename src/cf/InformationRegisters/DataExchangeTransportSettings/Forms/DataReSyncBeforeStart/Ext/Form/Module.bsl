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
	
	InfobaseNode = DataExchangeServer.MasterNode();
	IsStandaloneWorkplace = DataExchangeServer.IsStandaloneWorkplace();
	
	If IsStandaloneWorkplace Then
		Items.ConnectionParametersPages.CurrentPage = Items.SWPPage;
		ModuleStandaloneMode = Common.CommonModule("StandaloneMode");
		AccountPasswordRecoveryAddress = ModuleStandaloneMode.AccountPasswordRecoveryAddress();
		TimeConsumingOperationAllowed = True;
		
		If DataExchangeServer.DataSynchronizationPasswordSpecified(InfobaseNode) Then
			Password = DataExchangeServer.DataSynchronizationPassword(InfobaseNode);
		EndIf;
		
	EndIf;
	
	NodeNameLabel = NStr("ru = 'Не удалось установить обновление программы, полученное из
		|""%1"".
		|Техническую информацию см. в <a href = ""ЖурналРегистрации"">Журнале регистрации</a>.'; 
		|en = 'Cannot install the application update received from ""%1"".
		|See <a href = ""EventLog"">
		|the Event log</a> for technical information.'; 
		|pl = 'Instalacja aktualizacji aplikacji
		| pobranej z ""%1"" nie powiodła się.
		|Informację techniczną zob. <a href = ""EventLogMonitor"">Dziennik zdarzeń</a>.';
		|de = 'Das von ""%1"" empfangene Anwendungsupdate kann nicht installiert werden.
		|Siehe <a href = ""EventLog"">
		|das Event Log</a> für technische Informationen.';
		|ro = 'Nu se poate instala actualizarea aplicației primită de la ""%1"" .
		|Vizualizați <a href = ""EventLog"">
		|Jurnalul de evenimente</a> pentru informații tehnice.';
		|tr = '""%1"" den gelen uygulama güncellemesi yüklenemiyor. 
		|Teknik bilgi için <a href = ""EventLog""> 
		|Olay günlüğü </a> bölümüne bakın.'; 
		|es_ES = 'Fallado a instalar la actualización de la aplicación recibida de ""%1"".
		|Ver la información técnica <a href = ""EventLog"">
		|Registro de evento</a>.'");
	NodeNameLabel = StringFunctionsClientServer.SubstituteParametersToString(NodeNameLabel, InfobaseNode.Description);
	Items.NodeNameHelpText.Title = StringFunctionsClientServer.FormattedString(NodeNameLabel);
	
	SetFormItemsView();
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure InfoLabelNodeNameURLProcessing(Item, FormattedStringURL, StandardProcessing)
	
	StandardProcessing = False;
	
	FormParameters = New Structure;
	
	OpenForm("DataProcessor.EventLog.Form.EventLog", FormParameters,,,,,,
		FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

#EndRegion

#Region FormCommandHandlers

&AtClient
Procedure SyncAndContinue(Command)
	
	WarningText = "";
	HasErrors = False;
	TimeConsumingOperation = False;
	
	CheckUpdateRequired();
	
	If UpdateStatus = "NoUpdateRequired" Then
		
		SynchronizeAndContinueWithoutIBUpdate();
		
	ElsIf UpdateStatus = "InfobaseUpdate" Then
		
		SynchronizeAndContinueWithIBUpdate();
		
	ElsIf UpdateStatus = "ConfigurationUpdate" Then
		
		WarningText = NStr("ru = 'Из главного узла получены изменения, которые еще не применены.
			|Требуется открыть конфигуратор и обновить конфигурацию базы данных.'; 
			|en = 'Changes that have not been applied yet were received from the main node.
			|Open Designer and update the database configuration.'; 
			|pl = 'Z głównego węzła zostały uzyskane zmiany, które nie są jeszcze wprowadzone.
			|Należy przejść do konstruktora i zaktualizować konfigurację bazy danych.';
			|de = 'Änderungen, die noch nicht angewendet wurden, wurden vom Hauptknoten empfangen.
			|Es ist notwendig, den Designer zu öffnen und die Datenbankkonfiguration zu aktualisieren.';
			|ro = 'Modificările care nu sunt încă aplicate au fost primite de la nodul principal.
			|Este necesar să deschideți designerul și să actualizați configurația bazei de date.';
			|tr = 'Henüz uygulanmayan değişiklikler ana üniteden alındı. 
			|Tasarımcıyı açmak ve veritabanı konfigürasyonunu güncellemek gerekir.'; 
			|es_ES = 'Cambios que no se han aplicado aún, se habían recibido del nodo principal.
			|Es necesario abrir el diseñador y actualizar la configuración de la base de datos.'");
		
	EndIf;
	
	If Not TimeConsumingOperation Then
		
		SynchronizeAndContinueCompletion();
		
	EndIf;
	
EndProcedure

&AtClient
Procedure DoNotSyncAndContinue(Command)
	
	DoNotSyncAndContinueAtServer();
	
	Close("Continue");
	
EndProcedure

&AtClient
Procedure ExitApplication(Command)
	
	Close();
	
EndProcedure

&AtClient
Procedure ConnectionParameters(Command)
	
	Filter              = New Structure("Correspondent", InfobaseNode);
	FillingValues = New Structure("Correspondent", InfobaseNode);
	
	DataExchangeClient.OpenInformationRegisterWriteFormByFilter(Filter,
		FillingValues, "DataExchangeTransportSettings", Undefined);
	
EndProcedure

&AtClient
Procedure ForgotPassword(Command)
	DataExchangeClient.OpenInstructionHowToChangeDataSynchronizationPassword(AccountPasswordRecoveryAddress);
EndProcedure

#EndRegion

#Region Private

////////////////////////////////////////////////////////////////////////////////
// Scenario without infobase updating.

&AtClient
Procedure SynchronizeAndContinueWithoutIBUpdate()
	
	ImportDataExchangeMessageWithoutUpdating();
	
	If TimeConsumingOperation Then
		
		AttachIdleHandler("TimeConsumingOperationIdleHandler", 5, True);
		
	Else
		
		SynchronizeAndContinueWithoutIBUpdateCompletion();
		
	EndIf;
	
EndProcedure

&AtServer
Procedure SynchronizeAndContinueWithoutIBUpdateCompletion()
	
	// Repeat mode must be enabled in the following cases.
	// Case 1. A new configuration version is received and therefore infobase update is required.
	// If Cancel = True, the procedure execution must be stopped, otherwise data duplicates can be created,
	// - If Cancel = False, an error might occur during the infobase update and you might need to reimport the message.
	// Case 2. Received configuration version is equal to the current infobase configuration version and no updating required.
	// If Cancel = True, an error might occur during the infobase startup, possible cause is that 
	//   predefined items are not imported.
	// - If Cancel = False, it is possible to continue import because export can be performed later. If 
	//   export cannot be succeeded, it is possible to receive a new message to import.
	
	SetPrivilegedMode(True);
	
	If Not HasErrors Then
		
		DataExchangeServer.SetDataExchangeMessageImportModeBeforeStart("ImportPermitted", False);
		
		// If the message is imported, reimporting is not required.
		If Constants.LoadDataExchangeMessage.Get() Then
			Constants.LoadDataExchangeMessage.Set(False);
		EndIf;
		Constants.RetryDataExchangeMessageImportBeforeStart.Set(False);
		
		Try
			ExportMessageAfterInfobaseUpdate();
		Except
			// If exporting data fails, it is possible to start the application and export data in 1C:Enterprise 
			// mode.
			EventLogMessageKey = DataExchangeServer.EventLogMessageTextDataExchange();
			WriteLogEvent(EventLogMessageKey,
				EventLogLevel.Error,,, DetailErrorDescription(ErrorInfo()));
		EndTry;
		
	ElsIf ConfigurationChanged() Then
		If NOT Constants.LoadDataExchangeMessage.Get() Then
			Constants.LoadDataExchangeMessage.Set(True);
		EndIf;
		WarningText = NStr("ru = 'Из главного узла получены изменения, которые нужно применить.
			|Требуется открыть конфигуратор и обновить конфигурацию базы данных.'; 
			|en = 'Changes to be applied were received from the main node.
			|Open Designer and update the database configuration.'; 
			|pl = 'Z głównego węzła zostały uzyskane zmiany, które trzeba wprowadzić.
			|Należy przejść do konstruktora i zaktualizować konfigurację bazy danych.';
			|de = 'Änderungen, die angewendet werden sollten, wurden vom Hauptknoten empfangen.
			|Es ist notwendig, den Designer zu öffnen und die Datenbankkonfiguration zu aktualisieren.';
			|ro = 'Modificările care trebuie aplicate au fost primite de la nodul principal.
			|Este necesar să deschideți designerul și să actualizați configurația bazei de date.';
			|tr = 'Henüz uygulanmayan değişiklikler ana üniteden alındı. 
			|Tasarımcıyı açmak ve veritabanı konfigürasyonunu güncellemek gerekir.'; 
			|es_ES = 'Cambios que tienen que aplicarse se han recibido del nodo principal.
			|Es necesario abrir el diseñador y actualizar la configuración de la base de datos.'");
	Else
		
		If InfobaseUpdate.InfobaseUpdateRequired() Then
			EnableDataExchangeMessageImportRecurrenceBeforeStart();
		EndIf;
		
		WarningText = NStr("ru = 'Получение данных из главного узла завершилось с ошибками.
			|Подробности см. в журнале регистрации.'; 
			|en = 'Receiving data from the main node is completed with errors.
			|See details in the event log.'; 
			|pl = 'Pobieranie danych z głównego węzła zakończono z błędami.
			|Zobacz szczegóły w dzienniku zdarzeń.';
			|de = 'Der Datenempfang vom Hauptknoten wurde mit Fehlern abgeschlossen.
			|Suchen Sie im Ereignisprotokoll nach Details.';
			|ro = 'Primirea datelor din nodului principal a fost finalizată cu erori.
			|Detalii vezi în registrul logare.';
			|tr = 'Ana üniteden veri girişi hatalarla tamamlandı. 
			|Olay günlüğündeki ayrıntıları arayın.'; 
			|es_ES = 'Recibo de datos fuera del nodo principal se ha finalizado con errores.
			|Ver los detalles en el registro de eventos.'");
		
		DataExchangeServer.SetDataExchangeMessageImportModeBeforeStart("ImportPermitted", False);
		
	EndIf;
	
EndProcedure

&AtServer
Procedure ExportMessageAfterInfobaseUpdate()
	
	// The repeat mode can be disabled if messages are imported and the infobase is updated successfully.
	DataExchangeServer.DisableDataExchangeMessageImportRepeatBeforeStart();
	
	Try
		If GetFunctionalOption("UseDataSynchronization") Then
			
			InfobaseNode = DataExchangeServer.MasterNode();
			
			If InfobaseNode <> Undefined Then
				
				ExecuteExport = True;
				
				TransportSettings = InformationRegisters.DataExchangeTransportSettings.TransportSettings(InfobaseNode);
				
				TransportKind = TransportSettings.DefaultExchangeMessagesTransportKind;
				
				If TransportKind = Enums.ExchangeMessagesTransportTypes.WS
					AND Not TransportSettings.WSRememberPassword Then
					
					ExecuteExport = False;
					
					InformationRegisters.CommonInfobasesNodesSettings.SetDataSendingFlag(InfobaseNode);
					
				EndIf;
				
				If ExecuteExport Then
					
					AuthenticationParameters = ?(IsStandaloneWorkplace, New Structure("UseCurrentUser, Password", True, Password), Undefined);
					
					// Export only.
					Cancel = False;
					
					ExchangeParameters = DataExchangeServer.ExchangeParameters();
					ExchangeParameters.ExchangeMessagesTransportKind = TransportKind;
					ExchangeParameters.ExecuteImport = False;
					ExchangeParameters.ExecuteExport = True;
					ExchangeParameters.AuthenticationParameters = AuthenticationParameters;
					
					DataExchangeServer.ExecuteDataExchangeForInfobaseNode(InfobaseNode, ExchangeParameters, Cancel);
					
				EndIf;
				
			EndIf;
			
		EndIf;
		
	Except
		WriteLogEvent(DataExchangeServer.EventLogMessageTextDataExchange(),
			EventLogLevel.Error,,, DetailErrorDescription(ErrorInfo()));
	EndTry;
	
EndProcedure

&AtServer
Procedure ImportDataExchangeMessageWithoutUpdating()
	
	Try
		ImportMessageBeforeInfobaseUpdate();
	Except
		WriteLogEvent(DataExchangeServer.EventLogMessageTextDataExchange(),
			EventLogLevel.Error,,, DetailErrorDescription(ErrorInfo()));
		HasErrors = True;
	EndTry;
	
	SetFormItemsView();
	
EndProcedure

&AtServer
Procedure ImportMessageBeforeInfobaseUpdate()
	
	If DataExchangeInternal.DataExchangeMessageImportModeBeforeStart(
			"SkipImportDataExchangeMessageBeforeStart") Then
		Return;
	EndIf;
	
	If GetFunctionalOption("UseDataSynchronization") Then
		
		If InfobaseNode <> Undefined Then
			
			SetPrivilegedMode(True);
			DataExchangeServer.SetDataExchangeMessageImportModeBeforeStart("ImportPermitted", True);
			SetPrivilegedMode(False);
			
			// Updating object registration rules before importing data.
			DataExchangeServer.UpdateDataExchangeRules();
			
			TransportKind = InformationRegisters.DataExchangeTransportSettings.DefaultExchangeMessagesTransportKind(InfobaseNode);
			
			OperationStartDate = CurrentSessionDate();
			
			AuthenticationParameters = ?(IsStandaloneWorkplace, New Structure("UseCurrentUser, Password", True, Password), Undefined);
			
			// Import only.
			ExchangeParameters = DataExchangeServer.ExchangeParameters();
			ExchangeParameters.ExchangeMessagesTransportKind = TransportKind;
			ExchangeParameters.ExecuteImport = True;
			ExchangeParameters.ExecuteExport = False;
			
			ExchangeParameters.TimeConsumingOperationAllowed = TimeConsumingOperationAllowed;
			ExchangeParameters.TimeConsumingOperation          = TimeConsumingOperation;
			ExchangeParameters.OperationID       = OperationID;
			ExchangeParameters.FileID          = FileID;
			ExchangeParameters.AuthenticationParameters     = AuthenticationParameters;
			
			DataExchangeServer.ExecuteDataExchangeForInfobaseNode(InfobaseNode, ExchangeParameters, HasErrors);
			
			TimeConsumingOperationAllowed = ExchangeParameters.TimeConsumingOperationAllowed;
			TimeConsumingOperation          = ExchangeParameters.TimeConsumingOperation;
			OperationID       = ExchangeParameters.OperationID;
			FileID          = ExchangeParameters.FileID;
			AuthenticationParameters     = ExchangeParameters.AuthenticationParameters;
			
		EndIf;
		
	EndIf;
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Scenario that includes infobase update.

&AtClient
Procedure SynchronizeAndContinueWithIBUpdate()
	
	ImportDataExchangeMessageWithUpdate();
	
	If TimeConsumingOperation Then
		
		AttachIdleHandler("TimeConsumingOperationIdleHandler", 5, True);
		
	Else
		
		SynchronizeAndContinueWithIBUpdateCompletion();
		
	EndIf;
	
EndProcedure

&AtServer
Procedure SynchronizeAndContinueWithIBUpdateCompletion()
	
	SetPrivilegedMode(True);
	
	If Not HasErrors Then
		
		DataExchangeServer.SetDataExchangeMessageImportModeBeforeStart("ImportPermitted", False);
		
		If NOT Constants.LoadDataExchangeMessage.Get() Then
			Constants.LoadDataExchangeMessage.Set(True);
		EndIf;
		
		DataExchangeServer.SetDataExchangeMessageImportModeBeforeStart(
			"SkipImportPriorityDataBeforeStart", True);
		
	ElsIf ConfigurationChanged() Then
			
		If NOT Constants.LoadDataExchangeMessage.Get() Then
			Constants.LoadDataExchangeMessage.Set(True);
		EndIf;
		WarningText = NStr("ru = 'Из главного узла получены изменения, которые нужно применить.
			|Требуется открыть конфигуратор и обновить конфигурацию базы данных.'; 
			|en = 'Changes to be applied were received from the main node.
			|Open Designer and update the database configuration.'; 
			|pl = 'Z głównego węzła zostały uzyskane zmiany, które trzeba wprowadzić.
			|Należy przejść do konstruktora i zaktualizować konfigurację bazy danych.';
			|de = 'Änderungen, die angewendet werden sollten, wurden vom Hauptknoten empfangen.
			|Es ist notwendig, den Designer zu öffnen und die Datenbankkonfiguration zu aktualisieren.';
			|ro = 'Modificările care trebuie aplicate au fost primite de la nodul principal.
			|Este necesar să deschideți designerul și să actualizați configurația bazei de date.';
			|tr = 'Henüz uygulanmayan değişiklikler ana üniteden alındı. 
			|Tasarımcıyı açmak ve veritabanı konfigürasyonunu güncellemek gerekir.'; 
			|es_ES = 'Cambios que tienen que aplicarse se han recibido del nodo principal.
			|Es necesario abrir el diseñador y actualizar la configuración de la base de datos.'");
		
	Else
		
		DataExchangeServer.SetDataExchangeMessageImportModeBeforeStart("ImportPermitted", False);
		
		EnableDataExchangeMessageImportRecurrenceBeforeStart();
		
		WarningText = NStr("ru = 'Получение данных из главного узла завершилось с ошибками.
			|Подробности см. в журнале регистрации.'; 
			|en = 'Receiving data from the main node is completed with errors.
			|See details in the event log.'; 
			|pl = 'Pobieranie danych z głównego węzła zakończono z błędami.
			|Zobacz szczegóły w dzienniku zdarzeń.';
			|de = 'Der Datenempfang vom Hauptknoten wurde mit Fehlern abgeschlossen.
			|Suchen Sie im Ereignisprotokoll nach Details.';
			|ro = 'Primirea datelor din nodului principal a fost finalizată cu erori.
			|Detalii vezi în registrul logare.';
			|tr = 'Ana üniteden veri girişi hatalarla tamamlandı. 
			|Olay günlüğündeki ayrıntıları arayın.'; 
			|es_ES = 'Recibo de datos fuera del nodo principal se ha finalizado con errores.
			|Ver los detalles en el registro de eventos.'");
		
	EndIf;
	
EndProcedure

&AtServer
Procedure ImportDataExchangeMessageWithUpdate()
	
	Try
		ImportPriorityDataToSubordinateDIBNode();
	Except
		WriteLogEvent(DataExchangeServer.EventLogMessageTextDataExchange(),
			EventLogLevel.Error,,, DetailErrorDescription(ErrorInfo()));
		HasErrors = True;
	EndTry;
	
	SetFormItemsView();
	
EndProcedure

&AtServer
Procedure ImportPriorityDataToSubordinateDIBNode()
	
	If DataExchangeInternal.DataExchangeMessageImportModeBeforeStart(
			"SkipImportDataExchangeMessageBeforeStart") Then
		Return;
	EndIf;
	
	If DataExchangeInternal.DataExchangeMessageImportModeBeforeStart(
			"SkipImportPriorityDataBeforeStart") Then
		Return;
	EndIf;
	
	SetPrivilegedMode(True);
	DataExchangeServer.SetDataExchangeMessageImportModeBeforeStart("ImportPermitted", True);
	SetPrivilegedMode(False);
	
	CheckDataSynchronizationEnabled();
	
	If GetFunctionalOption("UseDataSynchronization") Then
		
		InfobaseNode = DataExchangeServer.MasterNode();
		
		If InfobaseNode <> Undefined Then
			
			TransportKind = InformationRegisters.DataExchangeTransportSettings.DefaultExchangeMessagesTransportKind(InfobaseNode);
			
			OperationStartDate = CurrentSessionDate();
			
			AuthenticationParameters = ?(IsStandaloneWorkplace, New Structure("UseCurrentUser, Password", True, Password), Undefined);
			
			// Importing application parameters only.
			ExchangeParameters = DataExchangeServer.ExchangeParameters();
			ExchangeParameters.ExchangeMessagesTransportKind = TransportKind;
			ExchangeParameters.ExecuteImport = True;
			ExchangeParameters.ExecuteExport = False;
			ExchangeParameters.ParametersOnly   = True;
			
			ExchangeParameters.TimeConsumingOperationAllowed = TimeConsumingOperationAllowed;
			ExchangeParameters.TimeConsumingOperation          = TimeConsumingOperation;
			ExchangeParameters.OperationID       = OperationID;
			ExchangeParameters.FileID          = FileID;
			ExchangeParameters.AuthenticationParameters     = AuthenticationParameters;
			
			DataExchangeServer.ExecuteDataExchangeForInfobaseNode(InfobaseNode, ExchangeParameters, HasErrors);
			
			TimeConsumingOperationAllowed = ExchangeParameters.TimeConsumingOperationAllowed;
			TimeConsumingOperation          = ExchangeParameters.TimeConsumingOperation;
			OperationID       = ExchangeParameters.OperationID;
			FileID          = ExchangeParameters.FileID;
			AuthenticationParameters     = ExchangeParameters.AuthenticationParameters;
			
		EndIf;
		
	EndIf;
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Scenario that does not include synchronization

&AtServer
Procedure DoNotSyncAndContinueAtServer()
	
	SetPrivilegedMode(True);
	
	If NOT InfobaseUpdate.InfobaseUpdateRequired() Then
		If Constants.LoadDataExchangeMessage.Get() Then
			Constants.LoadDataExchangeMessage.Set(False);
			DataExchangeServer.ClearDataExchangeMessageFromMasterNode();
		EndIf;
	EndIf;
	
	DataExchangeServer.SetDataExchangeMessageImportModeBeforeStart(
		"SkipImportDataExchangeMessageBeforeStart", True);
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Internal procedures and functions.

&AtServer
Procedure CheckUpdateRequired()
	
	SetPrivilegedMode(True);
	
	If ConfigurationChanged() Then
		UpdateStatus = "ConfigurationUpdate";
	ElsIf InfobaseUpdate.InfobaseUpdateRequired() Then
		UpdateStatus = "InfobaseUpdate";
	Else
		UpdateStatus = "NoUpdateRequired";
	EndIf;
	
EndProcedure

&AtClient
Procedure SynchronizeAndContinueCompletion()
	
	SetFormItemsView();
	
	If IsBlankString(WarningText) Then
		Close("Continue");
	Else
		ShowMessageBox(, WarningText);
	EndIf;
	
EndProcedure

// Sets the RetryDataExchangeMessageImportBeforeStart constant value to True.
// Clears exchange messages received from the master node.
//
&AtServer
Procedure EnableDataExchangeMessageImportRecurrenceBeforeStart()
	
	DataExchangeServer.ClearDataExchangeMessageFromMasterNode();
	
	Constants.RetryDataExchangeMessageImportBeforeStart.Set(True);
	
EndProcedure

&AtClient
Procedure TimeConsumingOperationIdleHandler()
	
	AuthenticationParameters = ?(IsStandaloneWorkplace, New Structure("UseCurrentUser, Password", True, Password), Undefined);
	
	ActionState = DataExchangeServerCall.TimeConsumingOperationStateForInfobaseNode(
		OperationID,
		InfobaseNode,
		AuthenticationParameters,
		WarningText);
	
	If ActionState = "Active" Then
		
		AttachIdleHandler("TimeConsumingOperationIdleHandler", 5, True);
		
	Else
		
		If ActionState <> "Completed" Then
			
			HasErrors = True;
			
		EndIf;
		
		TimeConsumingOperation = False;
		
		ProcessTimeConsumingOperationCompletion();
		
		If UpdateStatus = "NoUpdateRequired" Then
			
			SynchronizeAndContinueWithoutIBUpdateCompletion();
			
		ElsIf UpdateStatus = "InfobaseUpdate" Then
			
			SynchronizeAndContinueWithIBUpdateCompletion();
			
		EndIf;
		
		SynchronizeAndContinueCompletion();
		
	EndIf;
	
EndProcedure

&AtServer
Procedure CheckDataSynchronizationEnabled()
	
	If NOT GetFunctionalOption("UseDataSynchronization") Then
		
		If Common.DataSeparationEnabled() Then
			
			UseDataSynchronization = Constants.UseDataSynchronization.CreateValueManager();
			UseDataSynchronization.AdditionalProperties.Insert("DisableObjectChangeRecordMechanism");
			UseDataSynchronization.DataExchange.Load = True;
			UseDataSynchronization.Value = True;
			UseDataSynchronization.Write();
			
		Else
			
			If DataExchangeServer.GetExchangePlansInUse().Count() > 0 Then
				
				UseDataSynchronization = Constants.UseDataSynchronization.CreateValueManager();
				UseDataSynchronization.AdditionalProperties.Insert("DisableObjectChangeRecordMechanism");
				UseDataSynchronization.DataExchange.Load = True;
				UseDataSynchronization.Value = True;
				UseDataSynchronization.Write();
				
			EndIf;
			
		EndIf;
		
	EndIf;
	
EndProcedure

&AtServer
Procedure SetFormItemsView()
	
	If DataExchangeServer.LoadDataExchangeMessage()
		AND InfobaseUpdate.InfobaseUpdateRequired() Then
		
		Items.FormDoNotSyncAndContinue.Visible = False;
		Items.DoNotSyncHelpText.Visible = False;
	Else
		Items.FormDoNotSyncAndContinue.Visible = True;
		Items.DoNotSyncHelpText.Visible = True;
	EndIf;
	
	Items.MainPanel.CurrentPage = ?(TimeConsumingOperation, Items.TimeConsumingOperation, Items.Begin);
	Items.TimeConsumingOperationButtonsGroup.Visible = TimeConsumingOperation;
	Items.MainButtonsGroup.Visible = Not TimeConsumingOperation;
	
EndProcedure

&AtClient
Procedure ProcessTimeConsumingOperationCompletion()
	
	If Not HasErrors Then
		
		ExecuteDataExchangeForInfobaseNodeTimeConsumingOperationCompletion(
			InfobaseNode,
			FileID,
			OperationStartDate);
		
	EndIf;
	
EndProcedure

&AtServer
Procedure ExecuteDataExchangeForInfobaseNodeTimeConsumingOperationCompletion(
															Val InfobaseNode,
															Val FileID,
															Val OperationStartDate)
	
	DataExchangeServer.CheckCanSynchronizeData();
	
	DataExchangeServer.CheckDataExchangeUsage();
	
	AuthenticationParameters = ?(IsStandaloneWorkplace, New Structure("UseCurrentUser, Password", True, Password), Undefined);
	
	SetPrivilegedMode(True);
	
	Try
		FileExchangeMessages = DataExchangeServer.GetFileFromStorageInService(New UUID(FileID),
			InfobaseNode,, AuthenticationParameters);
	Except
		DataExchangeServer.RecordExchangeCompletionWithError(InfobaseNode,
			Enums.ActionsOnExchange.DataImport,
			OperationStartDate,
			DetailErrorDescription(ErrorInfo()));
			HasErrors = True;
		Return;
	EndTry;
	
	NewMessage = New BinaryData(FileExchangeMessages);
	DataExchangeServer.SetDataExchangeMessageFromMasterNode(NewMessage, InfobaseNode);
	
	Try
		DeleteFiles(FileExchangeMessages);
	Except
		WriteLogEvent(DataExchangeServer.EventLogMessageTextDataExchange(),
			EventLogLevel.Error,,, DetailErrorDescription(ErrorInfo()));
	EndTry;
	
	Try
		
		ParametersOnly = (UpdateStatus = "InfobaseUpdate");
		TransportKind = InformationRegisters.DataExchangeTransportSettings.DefaultExchangeMessagesTransportKind(InfobaseNode);
		
		ExchangeParameters = DataExchangeServer.ExchangeParameters();
		ExchangeParameters.ExchangeMessagesTransportKind = TransportKind;
		ExchangeParameters.ExecuteImport = True;
		ExchangeParameters.ExecuteExport = False;
		ExchangeParameters.ParametersOnly = ParametersOnly;
		ExchangeParameters.AuthenticationParameters = AuthenticationParameters;
		
		DataExchangeServer.ExecuteDataExchangeForInfobaseNode(InfobaseNode, ExchangeParameters, HasErrors);
		
	Except
		
		WriteLogEvent(DataExchangeServer.EventLogMessageTextDataExchange(),
			EventLogLevel.Error,,, DetailErrorDescription(ErrorInfo()));
		HasErrors = True;
		
	EndTry;
	
EndProcedure


#EndRegion