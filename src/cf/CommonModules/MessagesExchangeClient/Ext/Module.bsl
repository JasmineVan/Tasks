///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Internal

// Sends and receives system messages.
// 
Procedure SendAndReceiveMessages() Export
	
	Cancel = False;
	
	MessagesExchangeServerCall.SendAndReceiveMessages(Cancel);
	
	If Cancel Then
		
		ShowUserNotification(NStr("ru = 'Возникли ошибки при отправке и получении сообщений.'; en = 'Errors occurred while sending and receiving emails.'; pl = 'Powstały błędy przy wysłaniu i otrzymaniu komunikatów.';de = 'Beim Senden und Empfangen von Nachrichten sind Fehler aufgetreten.';ro = 'Erori la trimiterea și primirea mesajelor.';tr = 'Mesaj gönderilirken ve alınırken hatalar oluştu.'; es_ES = 'Errores ocurridos al enviar y recibir mensajes.'"),,
				NStr("ru = 'Используйте журнал регистрации для диагностики ошибок.'; en = 'Use the event log to diagnose errors.'; pl = 'Użyj dziennika zdarzeń do diagnostyki błędów.';de = 'Verwenden Sie das Ereignisprotokoll, um Fehler zu diagnostizieren.';ro = 'Utilizați jurnalul de evenimente pentru a diagnostica erorile.';tr = 'Hataları teşhis etmek için olay günlüğünü kullanın.'; es_ES = 'Utilizar el registro de eventos para diagnosticar los errores.'"), PictureLib.Error32);
		
	Else
		
		ShowUserNotification(NStr("ru = 'Отправка и получение сообщений успешно завершены.'; en = 'Messages are sent and recieved.'; pl = 'Wysyłanie i odbiór wiadomości zakończone pomyślnie.';de = 'Senden und Empfangen von Nachrichten erfolgreich abgeschlossen.';ro = 'Succes la trimiterea și primirea mesajelor.';tr = 'Mesajların gönderilmesi ve alınması başarıyla tamamlandı.'; es_ES = 'Envío y recepción de mensajes se ha finalizado con éxito.'"),,, PictureLib.Information32);
		
	EndIf;
	
	Notify(EventNameSendAndReceiveMessageExecuted());
	
EndProcedure

#EndRegion

#Region Private

// For internal use only.
//
// Returns:
//   String.
//
Function EndpointAddedEventName() Export
	
	Return "MessageExchange.EndpointAdded";
	
EndFunction

// For internal use only.
//
// Returns:
//   String.
//
Function EventNameSendAndReceiveMessageExecuted() Export
	
	Return "MessageExchange.SendAndReceiveExecuted";
	
EndFunction

// For internal use only.
//
// Returns:
//   String.
//
Function EndpointFormClosedEventName() Export
	
	Return "MessageExchange.EndpointFormClosed";
	
EndFunction

// For internal use only.
//
// Returns:
//   String.
//
Function EventNameLeadingEndpointSet() Export
	
	Return "MessageExchange.LeadingEndpointSet";
	
EndFunction

#EndRegion
