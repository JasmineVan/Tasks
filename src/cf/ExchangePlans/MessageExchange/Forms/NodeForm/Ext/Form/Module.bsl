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
	
	IsThisNode = (Object.Ref = MessageExchangeInternal.ThisNode());
	
	Items.InfoMessagesGroup.Visible = Not IsThisNode;
	
	If Not IsThisNode Then
		
		If Object.Locked Then
			Items.InfoMessage.Title
				= NStr("ru = 'Эта конечная точка заблокирована.'; en = 'This endpoint is locked.'; pl = 'Punkt końcowy zablokowany.';de = 'Dieser Endpunkt ist gesperrt.';ro = 'Acest punct final este blocat.';tr = 'Bu uç nokta kilitlendi.'; es_ES = 'El punto extremo está bloqueado.'");
		ElsIf Object.Leading Then
			Items.InfoMessage.Title
				= NStr("ru = 'Эта конечная точка является ведущей, т.е. инициирует отправку и получение сообщений обмена для текущей информационной системы.'; en = 'This endpoint is leading, that is it initiates current infosystem exchange messages sending and receiving.'; pl = 'Dany punkt końcowy jest wiodący, czyli inicjuje wysyłanie i odbieranie wiadomości wymiany dla bieżącego systemu informacyjnego.';de = 'Dieser Endpunkt ist ein führender, d.h. er initiiert das Senden und Empfangen von Austauschnachrichten für das aktuelle Informationssystem.';ro = 'Acest punct final este principal, adică inițiază trimiterea și primirea mesajelor de schimb pentru sistemul de informații curent.';tr = 'Bu uç nokta bağımlıdır, yani sadece mevcut bilgi sistemi talebi ile değişim mesajları gönderir ve alır.'; es_ES = 'El punto extremo es principal, que significa que inicia el envío y el recibo de los mensajes de intercambio para el sistema de información actual.'");
		Else
			Items.InfoMessage.Title
				= NStr("ru = 'Эта конечная точка является ведомой, т.е. выполняет отправку и получение сообщений обмена только по требованию текущей информационной системы.'; en = 'This endpoint is subordinate, that is it performs exchange messages sending and receiving only upon the current infosystem request.'; pl = 'Ten punkt końcowy jest zależny, czyli wysyła i odbiera wiadomości wymiany tylko wg bieżącego żądania systemu informacyjnego.';de = 'Dieser Endpunkt ist ein Slave, d.h. er sendet und empfängt Austauschnachrichten nur durch die aktuelle Informationssystemanforderung.';ro = 'Acest punct final este subordonat, adică trimite și primește mesaje de schimb numai la cererea sistemului de informații curent.';tr = 'Bu uç nokta bir bağımlıdır, yani sadece mevcut bilgi sistemi talebi ile değişim mesajları gönderir ve alır.'; es_ES = 'El extremo es un esclavo, que es que él envía y recibe los mensaje de intercambio solo por la solicitud del sistema de la información actual.'");
		EndIf;
		
		Items.MakeThisEndpointSubordinate.Visible = Object.Leading AND Not Object.Locked;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure OnClose(Exit)
	
	If Exit Then
		Return;
	EndIf;
	Notify(MessagesExchangeClient.EndpointFormClosedEventName());
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If EventName = MessagesExchangeClient.EventNameLeadingEndpointSet() Then
		
		Close();
		
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandHandlers

&AtClient
Procedure MakeThisEndpointSubordinate(Command)
	
	FormParameters = New Structure("Endpoint", Object.Ref);
	
	OpenForm("CommonForm.LeadingEndpointSetting", FormParameters, ThisObject, Object.Ref);
	
EndProcedure

#EndRegion
