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
	
	OutboundMessageStatus = NStr("ru = 'Сообщение отправляется...'; en = 'Sending message...'; pl = 'Wysyłanie wiadomości...';de = 'Die Nachricht wird gesendet...';ro = 'Are loc trimiterea mesajului...';tr = 'Mesaj gönderiliyor'; es_ES = 'El mensaje se está enviando...'");
	MessageText = Parameters.Text;
	
	PhoneNumbers = New Array;
	If TypeOf(Parameters.RecipientsNumbers) = Type("Array") Then
		For each PhoneInformation In Parameters.RecipientsNumbers Do
			PhoneNumbers.Add(PhoneInformation.Phone);
		EndDo;
	ElsIf TypeOf(Parameters.RecipientsNumbers) = Type("ValueList") Then
		For each PhoneInformation In Parameters.RecipientsNumbers Do
			PhoneNumbers.Add(PhoneInformation.Value);
		EndDo;
	Else
		PhoneNumbers.Add(String(Parameters.RecipientsNumbers));
	EndIf;
	
	If PhoneNumbers.Count() = 0 Then
		Items.RecipientNumberGroup.Visible = True;
	EndIf;
	
	RecipientsNumbers = " " + StrConcat(PhoneNumbers, ", ");
	
	Title = NStr("ru = 'Отправка SMS на телефон'; en = 'Send text message to phone'; pl = 'Wysyłanie SMS na telefon';de = 'Senden von SMS an das Telefon';ro = 'Trimiteți SMS către telefon';tr = 'SMS telefona gönderimi'; es_ES = 'Enviar SMS al teléfono'") + RecipientsNumbers;
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	MessageLength = StrLen(MessageText);
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure AddSenderOnChange(Item)
	Items.SenderName.Enabled = MentionSenderName;
EndProcedure

#EndRegion

#Region FormCommandHandlers

&AtClient
Procedure Send(Command)
	
	If StrLen(MessageText) = 0 Then
		ShowMessageBox(, NStr("ru = 'Необходимо ввести текст сообщения'; en = 'Please enter the text.'; pl = 'Należy wprowadzić tekst wiadomości';de = 'Sie müssen den Text der Nachricht eingeben';ro = 'Introduceți textul mesajului';tr = 'Mesaj metnini girin'; es_ES = 'Es necesario introducir el texto del mensaje'"));
		Return;
	EndIf;
	
	If NOT SMSMessageSendingIsSetUp() Then
		OpenForm("CommonForm.OutboundSMSSettings");
		Return;
	EndIf;
	
	Items.Pages.CurrentPage = Items.StatusPage;
	
	If Items.Find("SMSSendingOpenSetting") <> Undefined Then
		Items.SMSSendingOpenSetting.Visible = False;
	EndIf;
	
	Items.Close.Visible = True;
	Items.Close.DefaultButton = True;
	Items.Send.Visible = False;
	
	// Sending from server context.
	SendSMSMessage();

	// Check a sending status.
	If Not IsBlankString(MessageID) Then
		Items.Pages.CurrentPage = Items.MessageSentPage;
		AttachIdleHandler("CheckDeliveryStatus", 2, True);
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SendSMSMessage()
	
	// Reset a displayed delivery status.
	MessageID = "";
	
	// Prepare recipients numbers.
	NumbersArray = TextLinesToArray(RecipientsNumbers);
	
	// Sending.
	SendingResult = SendSMSMessage.SendSMSMessage(NumbersArray, MessageText, SenderName, SendInTransliteration);
	
	
	// Display information on errors occurred upon sending.
	If IsBlankString(SendingResult.ErrorDescription) Then
		// Check delivery for the first recipient.
		If SendingResult.SentMessages.Count() > 0 Then
			MessageID = SendingResult.SentMessages[0].MessageID;
		EndIf;
		Items.Pages.CurrentPage = Items.MessageSentPage;
	Else
		Items.Pages.CurrentPage = Items.MessageNotSentPage;
		
		MessageTemplate = NStr("ru = 'Отправка не выполнена:
		|%1
		|Подробности см. в журнале регистрации.'; 
		|en = 'Cannot send the message.
		|%1
		|For details, see the event log.'; 
		|pl = 'Wysyłanie nie zostało wykonane:
		|%1
		|Szczegóły zob. w dzienniku rejestracji.';
		|de = 'Senden fehlgeschlagen:
		|%1
		|Weitere Informationen finden Sie im Ereignisprotokoll.';
		|ro = 'Mesajul nu a fost trimis:
		|%1
		|Detalii vezi în Registrul logare.';
		|tr = 'Gönderilemedi:
		|%1
		|Detaylar için kayıt günlüğüne bakınız.'; 
		|es_ES = 'Envío no ejecutado:
		|%1
		|Véase los detalles en el registro.'");
		
		Items.MessageNotSentText.Title = StringFunctionsClientServer.SubstituteParametersToString(
			MessageTemplate, SendingResult.ErrorDescription);
	EndIf;
	
EndProcedure

&AtClient
Procedure CheckDeliveryStatus()
	
	DeliveryResult = DeliveryStatus(MessageID);
	OutboundMessageStatus = DeliveryResult.Details;
	
	DeliveryResults = New Array;
	DeliveryResults.Add("Error");
	DeliveryResults.Add("NotDelivered");
	DeliveryResults.Add("Delivered");
	DeliveryResults.Add("NotSent");
	
	StatusCheckCompleted = DeliveryResults.Find(DeliveryResult.Status) <> Undefined;
	Items.DeliveryStatusCheckGroup.Visible = StatusCheckCompleted;
	
	StateTemplate = NStr("ru = 'Отправка сообщения выполнена. Состояние доставки:
		|%1.'; 
		|en = 'The message is sent. Delivery status:
		|%1'; 
		|pl = 'Wysyłanie wiadomości zostało wykonane. Stan dostarczenia:
		|%1.';
		|de = 'Nachricht wurde gesendet. Versandstatus:
		|%1.';
		|ro = 'Mesajul a fost trimis. Statutul livrării:
		|%1.';
		|tr = 'Mesaj teslim edildi. Teslimat durumu: 
		|%1'; 
		|es_ES = 'Envío del mensaje ejecutado. Estado de la entrega:
		|%1.'");
	Items.MessageSentText.Title = StringFunctionsClientServer.SubstituteParametersToString(
		StateTemplate, DeliveryResult.Details);
	
	
	If DeliveryResult.Status = "Error" Then
		Items.AnimationDecoration.Picture = PictureLib.Error32;
	Else
		If DeliveryResults.Find(DeliveryResult.Status) <> Undefined Then
			Items.AnimationDecoration.Picture = PictureLib.Done32;
			Items.DeliveryStatusCheckGroup.Visible = False;
		Else
			AttachIdleHandler("CheckDeliveryStatus", 2, True);
			Items.DeliveryStatusCheckGroup.Visible = True;
		EndIf;
	EndIf;
	
EndProcedure

&AtServerNoContext
Function DeliveryStatus(MessageID)
	
	DeliveryStatuses = New Map;
	DeliveryStatuses.Insert("Error", NStr("ru = 'произошла ошибка при подключении к провайдеру SMS'; en = 'SMS provider connection error.'; pl = 'zaistniał błąd podczas połączenia z dostawcą usług SMS';de = 'bei der Verbindung zum SMS-Anbieter ist ein Fehler aufgetreten';ro = 'eroare de conectare la providerul SMS';tr = 'SMS sağlayıcısına bağlanırken hata oluştu'; es_ES = 'ha ocurrido un error al conectarse al proveedor de SMS'"));
	DeliveryStatuses.Insert("Pending", NStr("ru = 'сообщение не отправлялось провайдером'; en = 'The provider has not sent the message.'; pl = 'wiadomość nie była wysyłana przez dostawcę';de = 'die Nachricht wurde nicht vom Provider gesendet';ro = 'mesajul nu a fost trimis de provider';tr = 'mesaj sağlayıcı tarafından gönderilmedi'; es_ES = 'mensaje no se ha enviado por el proveedor'"));
	DeliveryStatuses.Insert("Sending", NStr("ru = 'выполняется отправка провайдером'; en = 'The provider is sending the message.'; pl = 'trwa wysyłanie przez dostawcę';de = 'wird vom Provider gesendet';ro = 'are loc trimiterea de către provider';tr = 'sağlayıcı tarafından gönderiliyor'; es_ES = 'se está enviando por proveedor'"));
	DeliveryStatuses.Insert("Sent", NStr("ru = 'отправлено провайдером'; en = 'The provider sent the message.'; pl = 'wysłano przez dostawcę';de = 'von einem Provider gesendet';ro = 'trimis de provider';tr = 'sağlayıcı tarafından gönderildi'; es_ES = 'enviado por proveedor'"));
	DeliveryStatuses.Insert("NotSent", NStr("ru = 'сообщение не отправлено провайдером'; en = 'The provider did not send the message.'; pl = 'wiadomość nie została wysłana przez dostawcę';de = 'Nachricht nicht vom Provider gesendet';ro = 'mesajul nu a fost trimis de provider';tr = 'mesaj sağlayıcı tarafından gönderilmedi'; es_ES = 'mensaje no enviado por proveedor'"));
	DeliveryStatuses.Insert("Delivered", NStr("ru = 'сообщение доставлено'; en = 'The message is delivered.'; pl = 'wiadomość została dostarczona';de = 'die Nachricht wurde zugestellt';ro = 'mesajul este livrat';tr = 'mesaj teslim edildi'; es_ES = 'mensaje entregado'"));
	DeliveryStatuses.Insert("NotDelivered", NStr("ru = 'сообщение не доставлено'; en = 'The message is not delivered.'; pl = 'wiadomość nie została dostarczona';de = 'die Nachricht wurde nicht zugestellt';ro = 'mesajul nu este livrat';tr = 'mesaj teslim edilmedi'; es_ES = 'mensaje no entregado'"));
	
	DeliveryResult = New Structure("Status, Details");
	DeliveryResult.Status = SendSMSMessage.DeliveryStatus(MessageID);
	DeliveryResult.Details = DeliveryStatuses[DeliveryResult.Status];
	If DeliveryResult.Details = Undefined Then
		DeliveryResult.Details = "<" + DeliveryResult.Status + ">";
	EndIf;
	
	Return DeliveryResult;
	
EndFunction

&AtServer
Function TextLinesToArray(Text)
	
	Result = New Array;
	
	TextDocument = New TextDocument;
	TextDocument.SetText(Text);
	
	For RowNumber = 1 To TextDocument.LineCount() Do
		Row = TextDocument.GetLine(RowNumber);
		If Not IsBlankString(Row) Then
			Result.Add(Row);
		EndIf;
	EndDo;
	
	Return Result;
	
EndFunction

&AtClient
Procedure TextChangeEditText(Item, Text, StandardProcessing)
	MessageLength = StrLen(Text);
	StandardProcessing = False;
EndProcedure

&AtServerNoContext
Function SMSMessageSendingIsSetUp()
 	Return SendSMSMessage.SMSMessageSendingSetupCompleted();
EndFunction

#EndRegion
