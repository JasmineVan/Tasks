///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Private

// Sends a text message via SMS Services.
//
// Parameters:
//  RecipientsNumbers - Array - recipient numbers in format +7ХХХХХХХХХХ.
//  Text			  - String - a message text with length not more than 480 characters.
//  SenderName 	 - String - a sender name that will be displayed instead of a number of incoming text message.
//  Username			 - String - a username in the text message sending service.
//  Password			 - String - a password in the text message sending service.
//
// Returns:
//  Structure: SentMessages - an array of structures: RecipientNumber.
//                                                  MessageID.
//             ErrorDescription - String - a user presentation of an error. If the string is empty, 
//                                          there is no error.
Function SendSMSMessage(RecipientsNumbers, Text, SenderName, Username, Password) Export
	
	Result = New Structure("SentMessages,ErrorDescription", New Array, "");
	
	// Prepare recipients.
	Recipients = New Array;
	For Each Item In RecipientsNumbers Do
		Recipient = FormatNumberToSend(Item);
		If Recipients.Find(Recipient) = Undefined Then
			Recipients.Add(Recipient);
		EndIf;
	EndDo;
	
	// Check whether required parameters are filled in.
	If RecipientsNumbers.Count() = 0 Or IsBlankString(Text) Then
		Result.ErrorDescription = NStr("ru = 'Неверные параметры сообщения'; en = 'Invalid message parameters.'; pl = 'Błędne parametry komunikatu';de = 'Falsche Nachrichtenparameter';ro = 'Parametri incorecți ai mesajului';tr = 'Mesaj parametreleri yanlış'; es_ES = 'Parámetros incorrectos del mensaje'");
		Return Result;
	EndIf;
	
	// Prepare query options.
	QueryParameters = New Structure;
	QueryParameters.Insert("login", Username);
	QueryParameters.Insert("password", Password);
	QueryParameters.Insert("action", "send");
	QueryParameters.Insert("text", Text);
	QueryParameters.Insert("to", Recipients);
	QueryParameters.Insert("source", SenderName);
	
	// Send the query
	ResponseText = ExecuteQuery("send.php", QueryParameters);
	If Not ValueIsFilled(ResponseText) Then
		Result.ErrorDescription = Result.ErrorDescription + NStr("ru = 'Соединение не установлено'; en = 'Connection failed.'; pl = 'Połączenie nie jest ustawione';de = 'Verbindung nicht hergestellt';ro = 'Conexiunea nu a fost stabilită';tr = 'Bağlantı kurulamadı'; es_ES = 'Conexión no establecida'");
		Return Result;
	EndIf;
	
	XMLReader = New XMLReader;
	XMLReader.SetString(ResponseText);
	ServerResponse = New Structure("code,descr,smsid");
	FillPropertyValues(ServerResponse, XDTOFactory.ReadXML(XMLReader));
	XMLReader.Close();
	
	ResultCode = ServerResponse.code;
	If ResultCode = "1" Then
		MessageID = ServerResponse.smsid;
		For Each Recipient In Recipients Do
			SentMessage = New Structure("RecipientNumber,MessageID", 
				FormatNumberFromSendingResult(Recipient), Recipient + "/" + MessageID);
			Result.SentMessages.Add(SentMessage);
		EndDo;
	Else
		Result.ErrorDescription = StringFunctionsClientServer.SubstituteParametersToString(NStr(
			"ru = 'Не удалось отправить SMS:
			|%1 (код ошибки: %2)'; 
			|en = 'Cannot send the text message:
			|%1 (error code: %2).'; 
			|pl = 'Nie udało się wysłać SMS:
			|%1 (kod błędu: %2)';
			|de = 'SMS konnte nicht gesendet werden:
			|%1 (Fehlercode: %2)';
			|ro = 'Eșec la trimiterea de SMS:
			|%1 (codul erorii: %2)';
			|tr = 'SMS gönderilemedi: 
			|%1 (hata kodu: %2)'; 
			|es_ES = 'No se ha podido enviar SMS:
			|%1(código del error: %2)'"), ServerResponse.descr, ResultCode);
		WriteLogEvent(NStr("ru = 'Отправка SMS'; en = 'Send text messages'; pl = 'Wyslij SMS';de = 'SMS senden';ro = 'Trimitere de SMS';tr = 'SMS gönder'; es_ES = 'Enviar SMS'", Common.DefaultLanguageCode()),
			EventLogLevel.Error, , , Result.ErrorDescription);
	EndIf;
	
	Return Result;
	
EndFunction

// This function returns a text presentation of message delivery status.
//
// Parameters:
//  MessageID - String - ID assigned to a text message upon sending.
//  SMSMessageSendingSettings - Structure - see SMSMessageSendingCached.SMSMessageSendingSettings. 
//
// Returns:
//  String - a delivery status. See details of the SMSMessageSending.DeliveryStatus function.
Function DeliveryStatus(Val MessageID, SMSMessageSendingSettings) Export
	
	IDParts = StrSplit(MessageID, "/", True);
	RecipientNumber = IDParts[0];
	MessageID = IDParts[1];
	
	Username = SMSMessageSendingSettings.Username;
	Password = SMSMessageSendingSettings.Password;
	
	DeliveryStatuses = New Map;
	
	// Prepare query options.
	QueryParameters = New Structure;
	QueryParameters.Insert("login", Username);
	QueryParameters.Insert("password", Password);
	QueryParameters.Insert("smsid", MessageID);
	
	// Send the query
	ResponseText = ExecuteQuery("report.php", QueryParameters);
	If Not ValueIsFilled(ResponseText) Then
		Return "Error";
	EndIf;
	
	XMLReader = New XMLReader;
	XMLReader.SetString(ResponseText);
	ServerResponse = New Structure("code,descr,detail");
	FillPropertyValues(ServerResponse, XDTOFactory.ReadXML(XMLReader));
	XMLReader.Close();

	ResultCode = ServerResponse.code;
	If ResultCode = "1" Then
		For Each Status In ServerResponse.detail.Properties() Do
			Recipients = ServerResponse.detail[Status.Name].Sequence();
			For Index = 0 To Recipients.Count()-1 Do
				Recipient = Recipients.GetValue(Index);
				DeliveryStatuses.Insert(Recipient, SMSMessageDeliveryStatus(Status.Name));
			EndDo;
		EndDo;
	Else
		ErrorDescription = StringFunctionsClientServer.SubstituteParametersToString(NStr(
			"ru = 'Не удалось получить статус доставки SMS (smsid: ""%3""):
			|%1 (код ошибки: %2)'; 
			|en = 'Cannot get text message delivery status (smsid: %3):
			|%1 (error code: %2).'; 
			|pl = 'Nie udało się uzyskać status dostawy SMS (smsid: ""%3""):
			|%1 (kod błędu: %2)';
			|de = 'SMS-Zustellstatus fehlgeschlagen (smsid: ""%3""):
			|%1 (Fehlercode: %2)';
			|ro = 'Eșec la obținerea statutului de livrare a SMS (smsid: ""%3""):
			|%1 (codul erorii: %2)';
			|tr = 'SMS teslimat durumu alınamadı (smsid: ""%3""): 
			|%1 (hata kodu:%2)'; 
			|es_ES = 'No se ha podido recibir el estado de la entrega de SMS  (smsid: ""%3""):
			|%1 (código de error: %2)'"), ServerResponse.descr, ResultCode, MessageID);
		WriteLogEvent(NStr("ru = 'Отправка SMS'; en = 'Send text messages'; pl = 'Wyslij SMS';de = 'SMS senden';ro = 'Trimitere de SMS';tr = 'SMS gönder'; es_ES = 'Enviar SMS'", Common.DefaultLanguageCode()),
			EventLogLevel.Error, , , ErrorDescription);
		Return "Error";
	EndIf;
	
	Result = DeliveryStatuses[RecipientNumber];
	If Result = Undefined Then
		Result = "Pending";
	EndIf;
	
	Return Result;
	
EndFunction

Function SMSMessageDeliveryStatus(StatusCode)
	StatusesMap = New Map;
	StatusesMap.Insert("enqueued", "Sending");
	StatusesMap.Insert("onModer", "Sending");
	StatusesMap.Insert("process", "Sending");
	StatusesMap.Insert("waiting", "Sent");
	StatusesMap.Insert("delivered", "Delivered");
	StatusesMap.Insert("notDelivered", "NotDelivered");
	StatusesMap.Insert("cancel", "NotSent");
	
	Result = StatusesMap[StatusCode];
	Return ?(Result = Undefined, "Pending", Result);
EndFunction

Function ExecuteQuery(MethodName, QueryParameters)
	
	HTTPRequest = SendSMSMessage.PrepareHTTPRequest("/API/XML/" + MethodName, GenerateHTTPRequestBody(QueryParameters));
	HTTPResponse = Undefined;
	
	Try
		Connection = New HTTPConnection("lcab.sms-uslugi.ru",,,, 
			GetFilesFromInternet.GetProxy("http"), 
			60);
		HTTPResponse = Connection.Post(HTTPRequest);
	Except
		WriteLogEvent(NStr("ru = 'Отправка SMS'; en = 'Send text messages'; pl = 'Wyslij SMS';de = 'SMS senden';ro = 'Trimitere de SMS';tr = 'SMS gönder'; es_ES = 'Enviar SMS'", Common.DefaultLanguageCode()),
			EventLogLevel.Error, , , DetailErrorDescription(ErrorInfo()));
	EndTry;
	
	If HTTPResponse <> Undefined Then
		Return HTTPResponse.GetBodyAsString();
	EndIf;
	
	Return Undefined;
	
EndFunction

Function GenerateHTTPRequestBody(QueryParameters)
	
	XMLWriter = New XMLWriter;
	XMLWriter.SetString();
	XMLWriter.WriteXMLDeclaration();
	XMLWriter.WriteStartElement("data");
	For Each Parameter In QueryParameters Do
		If Parameter.Key = "to" Then
			For Each Number In Parameter.Value Do
				XMLWriter.WriteStartElement(Parameter.Key);
				XMLWriter.WriteAttribute("number", Number);
				XMLWriter.WriteEndElement();
			EndDo;
		Else
			XMLWriter.WriteStartElement(Parameter.Key);
			XMLWriter.WriteText(Parameter.Value);
			XMLWriter.WriteEndElement();
		EndIf;
	EndDo;
	XMLWriter.WriteEndElement();
	Return XMLWriter.Close();
	
EndFunction

Function FormatNumberToSend(Number)
	Result = "";
	AllowedChars = "1234567890";
	For Position = 1 To StrLen(Number) Do
		Char = Mid(Number,Position,1);
		If StrFind(AllowedChars, Char) > 0 Then
			Result = Result + Char;
		EndIf;
	EndDo;
	Return Result;
EndFunction

Function FormatNumberFromSendingResult(Number)
	Result = Number;
	
	If StrLen(Result) > 10 Then
		FirstChar = Left(Result, 1);
		If FirstChar = "8" Then
			Result = "+7" + Mid(Result, 2);
		ElsIf FirstChar <> "+" Then
			Result = "+" + Result;
		EndIf;
	EndIf;
	
	Return Result;
EndFunction

// This function returns the list of permissions for sending text messages using all available providers.
//
// Returns:
//  Array.
//
Function Permissions() Export
	
	Protocol = "HTTP";
	Address = "lcab.sms-uslugi.ru";
	Port = Undefined;
	Details = NStr("ru = 'Отправка SMS через ""СМС-Услуги"".'; en = 'Send text messages via SMS Services.'; pl = 'Wysłanie SMS poprzez ""SMS-Usługi"".';de = 'SMS über ""SMS-Dienste"" versenden.';ro = 'Trimiterea de SMS prin ""SMS-Servicii"".';tr = 'SMS-Hizmetler üzerinden SMS gönderimi'; es_ES = 'Enviar SMS a través de ""SMS-Servicios "".'");
	
	ModuleSafeModeManager = Common.CommonModule("SafeModeManager");
	
	Permissions = New Array;
	Permissions.Add(
		ModuleSafeModeManager.PermissionToUseInternetResource(Protocol, Address, Port, Details));
	
	Return Permissions;
EndFunction

Procedure OnDefineSettings(Settings) Export
	
	Settings.ServiceDetailsInternetAddress = "http://sms-uslugi.ru";
	
EndProcedure


#EndRegion

