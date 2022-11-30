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
	
	EndpointConnectionEventLogEvent = MessageExchangeInternal.EndpointConnectionEventLogEvent();
	
	StandardSubsystemsServer.SetGroupTitleRepresentation(ThisObject);
	
EndProcedure

&AtClient
Procedure BeforeClose(Cancel, Exit, WarningText, StandardProcessing)
	
	Notification = New NotifyDescription("ConnectAndClose", ThisObject);
	WarningText = NStr("ru = 'Отменить подключение конечной точки?'; en = 'Do you want to cancel the endpoint connection?'; pl = 'Czy chcesz przerwać połączenie z punktem końcowym?';de = 'Do you want to cancel connection to the endpoint?';ro = 'Doriți să revocați conectarea punctului final?';tr = 'Uç noktanın bağlantısını iptal etmek istiyor musunuz?'; es_ES = '¿Quiere cancelar la conexión para el punto extremo?'");
	CommonClient.ShowFormClosingConfirmation(Notification, Cancel, Exit, WarningText);
	
EndProcedure

#EndRegion

#Region FormCommandHandlers

&AtClient
Procedure ConnectEndpoint(Command)
	
	ConnectAndClose();
	
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure ConnectAndClose(Result = Undefined, AdditionalParameters = Undefined) Export
	
	Cancel = False;
	FillError = False;
	
	ConnectEndpointAtServer(Cancel, FillError);
	
	If FillError Then
		Return;
	EndIf;
	
	If Cancel Then
		
		NString = NStr("ru = 'При подключении конечной точки возникли ошибки.
		|Перейти в журнал регистрации?'; 
		|en = 'Errors occurred during the endpoint connection. 
		|Go to the event log?'; 
		|pl = 'Podczas łączenia się z punktem końcowym wystąpiły błędy.
		|Czy chcesz otworzyć dziennik zdarzeń?';
		|de = 'Beim Verbinden mit dem Endpunkt sind Fehler aufgetreten. 
		|Möchten Sie das Ereignisprotokoll öffnen?';
		|ro = 'Erori la conectarea punctului final.
		|Doriți să treceți în registrul logare?';
		|tr = 'Uç noktasına bağlanırken hatalar oluştu.
		| Olay günlüğünü açmak istiyor musunuz?'; 
		|es_ES = 'No había errores al conectar para el punto extremo.
		|¿Quiere abrir el registro de eventos?'");
		NotifyDescription = New NotifyDescription("OpenEventLog", ThisObject);
		ShowQueryBox(NotifyDescription, NString, QuestionDialogMode.YesNo, ,DialogReturnCode.No);
		Return;
	EndIf;
	
	Notify(MessagesExchangeClient.EndpointAddedEventName());
	
	ShowUserNotification(,,NStr("ru = 'Подключение конечной точки успешно завершено.'; en = 'The endpoint is connected.'; pl = 'Podłączenie punktu końcowego zakończone pomyślnie.';de = 'Verbindung des Endpunktes erfolgreich abgeschlossen.';ro = 'Conectarea punctului final este finalizată cu succes.';tr = 'Uç noktanın bağlantısı başarıyla tamamlandı.'; es_ES = 'Conexión del punto extremo se ha finalizado con éxito.'"));
	
	Modified = False;
	
	Close();
	
EndProcedure

&AtClient
Procedure OpenEventLog(Response, AdditionalParameters) Export
	
	If Response = DialogReturnCode.Yes Then
		
		Filter = New Structure;
		Filter.Insert("EventLogEvent", EndpointConnectionEventLogEvent);
		OpenForm("DataProcessor.EventLog.Form", Filter, ThisObject);
		
	EndIf;
	
EndProcedure

&AtServer
Procedure ConnectEndpointAtServer(Cancel, FillError)
	
	If Not CheckFilling() Then
		FillError = True;
		Return;
	EndIf;
	
	SenderConnectionSettings = DataExchangeServer.WSParameterStructure();
	SenderConnectionSettings.WSWebServiceURL   = SenderSettingsWSURL;
	SenderConnectionSettings.WSUsername = SenderSettingsWSUsername;
	SenderConnectionSettings.WSPassword          = SenderSettingsWSPassword;
	
	RecipientConnectionSettings = DataExchangeServer.WSParameterStructure();
	RecipientConnectionSettings.WSWebServiceURL   = RecipientSettingsWSURL;
	RecipientConnectionSettings.WSUsername = RecipientSettingsWSUsername;
	RecipientConnectionSettings.WSPassword          = RecipientSettingsWSPassword;
	
	MessageExchange.ConnectEndpoint(
		Cancel,
		SenderConnectionSettings,
		RecipientConnectionSettings);
	
EndProcedure

#EndRegion
