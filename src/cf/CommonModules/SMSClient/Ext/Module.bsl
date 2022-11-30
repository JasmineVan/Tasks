///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Public

// Open the form to send a new text message.
//
// Parameters:
//  RecipientsNumbers - Array - recipient numbers in format +<CountryCode><DEFCode><number>(as string).
//  Text - String - a message text with length not more than 1000 characters.
//  AdditionalParameters - Structure - additional text message sending parameters.
//    * SenderName - String - a sender name that recipients will see instead of a number.
//    * Transliterate - Boolean - True if the message text is to be transliterated before sending.
Procedure SendSMSMessage(RecipientsNumbers, Text, AdditionalParameters) Export
	
	StandardProcessing = True;
	SendSMSMessagesClientOverridable.OnSendSMSMessage(RecipientsNumbers, Text, AdditionalParameters, StandardProcessing);
	If StandardProcessing Then
		
		SendOptions = New Structure("RecipientsNumbers, Text, AdditionalParameters");
		SendOptions.RecipientsNumbers       = RecipientsNumbers;
		SendOptions.Text                   = Text;
		SendOptions.AdditionalParameters = ?(TypeOf(AdditionalParameters) = Type("Structure"), AdditionalParameters, New Structure);
		
		If Not SendOptions.AdditionalParameters.Property("Transliterate") Then
			SendOptions.AdditionalParameters.Insert("Transliterate", False);
		EndIf;
		
		NotifyDescription = New NotifyDescription("CreateNewSMSMessageSettingsCheckCompleted", ThisObject, SendOptions);
		CheckForSMSMessageSendingSettings(NotifyDescription);
		
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

// If a user has no settings for sending text messages, does one of the following depending on the 
// user rights: show the text message settings form, or show a message that sending is unavailable.
//
// Parameters:
//  ResultHandler - NotifyDescription - the procedure to be called after the check is completed.
//
Procedure CheckForSMSMessageSendingSettings(ResultHandler)
	
	ClientRunParameters = StandardSubsystemsClient.ClientRunParameters();
	If ClientRunParameters.CanSendSMSMessage Then
		ExecuteNotifyProcessing(ResultHandler, True);
	Else
		If ClientRunParameters.IsFullUser Then
			NotifyDescription = New NotifyDescription("AfterSetUpSMSMessage", ThisObject, ResultHandler);
			OpenForm("CommonForm.OutboundSMSSettings",,,,,, NotifyDescription);
		Else
			MessageText = NStr("ru = 'Для отправки SMS требуется произвести настройку параметров подключения
				|Обратитесь к администратору.'; 
				|en = 'The connections parameters for sending text messages are not configured.
				|Please contact the administrator.'; 
				|pl = 'Dla wysyłki SMS trzeba wykonać ustawienie parametrów podłączenia
				|Zwróć się do administratora.';
				|de = 'Um SMS zu versenden, müssen Sie die Verbindungseinstellungen konfigurieren
				|Bitte wenden Sie sich an Ihren Administrator.';
				|ro = 'Pentru trimiterea SMS trebuie să executați setarea parametrilor de conectare
				|Adresați-vă administratorului.';
				|tr = 'SMS göndermek için, bağlantı ayarlarını yapılandırılmalıdır
				| Yöneticinize başvurun.'; 
				|es_ES = 'Para enviar SMS se requiere ajustar los parámetros de conexión
				|Diríjase al administrador.'");
			ShowMessageBox(, MessageText);
		EndIf;
	EndIf;
	
EndProcedure

Procedure AfterSetUpSMSMessage(Result, ResultHandler) Export
	ClientRunParameters = StandardSubsystemsClient.ClientRunParameters();
	If ClientRunParameters.CanSendSMSMessage Then
		ExecuteNotifyProcessing(ResultHandler, True);
	EndIf;
EndProcedure

// Continues the SendSMSMessage procedure.
Procedure CreateNewSMSMessageSettingsCheckCompleted(SMSMessageSendingIsSetUp, SendOptions) Export
	
	If SMSMessageSendingIsSetUp Then
		
		ClientRunParameters = StandardSubsystemsClient.ClientRunParameters();
		If CommonClient.SubsystemExists("StandardSubsystems.Interactions")
			AND ClientRunParameters.UseOtherInteractions Then
			
			Topic = ?(SendOptions.AdditionalParameters.Property("Topic"), SendOptions.AdditionalParameters.Topic, Undefined);
			
			ModuleClientInteractions = CommonClient.CommonModule("InteractionsClient");
			ModuleClientInteractions.OpenSMSMessageSendingForm(SendOptions.RecipientsNumbers, SendOptions.Text, Topic, SendOptions.AdditionalParameters.Transliterate);
		Else
			OpenForm("CommonForm.SendSMSMessage", SendOptions);
		EndIf;
		
	EndIf;
	
EndProcedure

#EndRegion