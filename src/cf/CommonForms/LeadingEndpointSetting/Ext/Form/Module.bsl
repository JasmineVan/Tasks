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
	
	LeadingEndpointSettingEventLogMessage = MessageExchangeInternal.LeadingEndpointSettingEventLogMessage();
	
	Endpoint = Parameters.Endpoint;
	
	// Reading the connection setting values.
	FillPropertyValues(ThisObject, InformationRegisters.MessageExchangeTransportSettings.TransportSettingsWS(Endpoint));
	
	Title = StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = 'Установка ведущей конечной точки для ""%1""'; en = 'Setting the leading endpoint for %1'; pl = 'Ustaw wiodący punkt końcowy dla ""%1""';de = 'Setze den führenden Endpunkt für ""%1""';ro = 'Setarea punctului final pentru ""%1""';tr = '""%1"" için başlangıç uç noktasını ayarlayın'; es_ES = 'Establecer el punto extremo principal para ""%1""'"),
		Common.ObjectAttributeValue(Endpoint, "Description"));
	
EndProcedure

&AtClient
Procedure BeforeClose(Cancel, Exit, WarningText, StandardProcessing)
	
	WarningText = NStr("ru = 'Отменить выполнение операции?'; en = 'Do you want to cancel the operation?'; pl = 'Czy chcesz anulować operację?';de = 'Möchten Sie den Vorgang abbrechen?';ro = 'Doriți să revocați executarea operației?';tr = 'İşlemi iptal etmek istiyor musunuz?'; es_ES = '¿Quiere cancelar la operación?'");
	CommonClient.ShowArbitraryFormClosingConfirmation(
		ThisObject, Cancel, Exit, WarningText, "ForceCloseForm");
	
EndProcedure

#EndRegion

#Region FormCommandHandlers

&AtClient
Procedure Apply(Command)
	
	Cancel = False;
	FillError = False;
	
	SetLeadingEndpointAtServer(Cancel, FillError);
	
	If FillError Then
		Return;
	EndIf;
	
	If Cancel Then
		
		NString = NStr("ru = 'При установке ведущей конечной точки возникли ошибки.
		|Перейти в журнал регистрации?'; 
		|en = 'Errors occurred when trying to establish the leading endpoint.
		|Go to the event log?'; 
		|pl = 'Wystąpiły błędy podczas ustawiania wiodącego punktu końcowego.
		|Czy chcesz otworzyć dziennik zdarzeń?';
		|de = 'Beim Festlegen des führenden Endpunkts sind Fehler aufgetreten. 
		|Möchten Sie das Ereignisprotokoll öffnen?';
		|ro = 'Erori la setarea punctului final principal.
		|Doriți să treceți în registrul logare?';
		|tr = 'Başlangıç uç noktası ayarlanırken hata oluştu. 
		| Olay günlüğünü açmak istiyor musunuz?'; 
		|es_ES = 'Han ocurrido errores al configurar el punto extremo principal.
		|¿Quiere abrir el registro de eventos?'");
		NotifyDescription = New NotifyDescription("OpenEventLog", ThisObject);
		ShowQueryBox(NotifyDescription, NString, QuestionDialogMode.YesNo, ,DialogReturnCode.No);
		Return;
	EndIf;
	
	Notify(MessagesExchangeClient.EventNameLeadingEndpointSet());
	
	ShowUserNotification(,, NStr("ru = 'Установка ведущей конечной точки успешно завершена.'; en = 'The leading endpoint is set.'; pl = 'Główny punkt końcowy został ustawiony pomyślnie.';de = 'Der führende Endpunkt wird erfolgreich festgelegt.';ro = 'Punctul final principal este setat cu succes.';tr = 'Başlangıç uç noktası başarı ile ayarlandı.'; es_ES = 'Punto extremo principal se ha establecido con éxito.'"));
	
	ForceCloseForm = True;
	
	Close();
	
EndProcedure

&AtClient
Procedure OpenEventLog(Response, AdditionalParameters) Export
	
	If Response = DialogReturnCode.Yes Then
		
		Filter = New Structure;
		Filter.Insert("EventLogEvent", LeadingEndpointSettingEventLogMessage);
		OpenForm("DataProcessor.EventLog.Form", Filter, ThisObject);
		
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SetLeadingEndpointAtServer(Cancel, FillError)
	
	If Not CheckFilling() Then
		FillError = True;
		Return;
	EndIf;
	
	WSConnectionSettings = DataExchangeServer.WSParameterStructure();
	
	FillPropertyValues(WSConnectionSettings, ThisObject);
	
	MessageExchangeInternal.SetLeadingEndpointAtSender(Cancel, WSConnectionSettings, Endpoint);
	
EndProcedure

#EndRegion
