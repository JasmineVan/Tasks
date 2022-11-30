///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Private

// Sends a text message via GSM-INFORM.
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
	
	// Prepare a string of recipients.
	RecipientsString = RecipientsArrayAsString(RecipientsNumbers);
	
	// Check whether required parameters are filled in.
	If IsBlankString(RecipientsString) Or IsBlankString(Text) Then
		Result.ErrorDescription = NStr("ru = 'Неверные параметры сообщения'; en = 'Invalid message parameters.'; pl = 'Błędne parametry komunikatu';de = 'Falsche Nachrichtenparameter';ro = 'Parametri incorecți ai mesajului';tr = 'Mesaj parametreleri yanlış'; es_ES = 'Parámetros incorrectos del mensaje'");
		Return Result;
	EndIf;
	
	// Prepare query options.
	QueryParameters = New Structure;
	QueryParameters.Insert("id", Username);
	QueryParameters.Insert("api_key", Password);
	
	QueryParameters.Insert("cmd", "send");
	QueryParameters.Insert("message", Text);
	QueryParameters.Insert("to", RecipientsString);
	QueryParameters.Insert("sender", SenderName);
	
	// Send the query
	Response = ExecuteQuery(QueryParameters);
	If Response = Undefined Then
		Result.ErrorDescription = Result.ErrorDescription + NStr("ru = 'Соединение не установлено'; en = 'Connection failed.'; pl = 'Połączenie nie jest ustawione';de = 'Verbindung nicht hergestellt';ro = 'Conexiunea nu a fost stabilită';tr = 'Bağlantı kurulamadı'; es_ES = 'Conexión no establecida'");
		Return Result;
	EndIf;
	
	JSONReader = New JSONReader;
	JSONReader.SetString(Response);
	ServerResponse = ReadJSON(JSONReader);
	JSONReader.Close();
	
	If ServerResponse["error_no"] = 0 Then
		For Each Item In ServerResponse["items"] Do
			If Item["error_no"] = 0 Then
				SentMessage = New Structure("RecipientNumber,MessageID", Item["phone"], Format(Item["sms_id"], "NG=0"));
				Result.SentMessages.Add(SentMessage);
			Else
				ErrorCode = Item["error_no"];
				Result.ErrorDescription = Result.ErrorDescription + Item["phone"] + ": " + StatusGettingErrorDescription(ErrorCode) + Chars.LF;
			EndIf;
		EndDo;
		If Not IsBlankString(Result.ErrorDescription) Then
			Result.ErrorDescription = NStr("ru = 'Не удалось отправить SMS'; en = 'Cannot send the text message.'; pl = 'Nie udało się wysłać SMS';de = 'SMS konnte nicht gesendet werden';ro = 'Eșec la trimiterea de SMS';tr = 'SMS gönderilemedi'; es_ES = 'No se ha podido enviar SMS'") + ":" + TrimR(Result.ErrorDescription);
		EndIf;
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
			|%1(código del error: %2)'"), SendingErrorDescription(ServerResponse["error_no"]), ServerResponse["error_no"]);
			
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
Function DeliveryStatus(MessageID, SMSMessageSendingSettings) Export
	Username = SMSMessageSendingSettings.Username;
	Password = SMSMessageSendingSettings.Password;
	
	// Prepare query options.
	QueryParameters = New Structure;
	QueryParameters.Insert("id", Username);
	QueryParameters.Insert("api_key", Password);
	QueryParameters.Insert("sms_id", MessageID);
	QueryParameters.Insert("cmd", "status");
	
	// Send the query
	Response = ExecuteQuery(QueryParameters);
	If Response = Undefined Then
		Return "Error";
	EndIf;
	
	JSONReader = New JSONReader;
	JSONReader.SetString(Response);
	ServerResponse = ReadJSON(JSONReader);
	JSONReader.Close();
	
	ErrorDescription = "";
	ErrorCode = Undefined;
	Result = "Error";
	
	If ServerResponse["error_no"] = 0 Then
		For Each Item In ServerResponse["items"] Do
			If Item.Property("error_no") Then
				ErrorCode = Item["error_no"];
				Break;
			Else
				Result = SMSMessageDeliveryStatus(Item["status_no"]);
			EndIf;
		EndDo;
	Else
		ErrorCode = ServerResponse["error_no"];
	EndIf;
	
	If ErrorCode <> Undefined Then
		ErrorDescription = StatusGettingErrorDescription(ErrorCode);
		Comment = StringFunctionsClientServer.SubstituteParametersToString(NStr(
			"ru = 'Не удалось получить статус доставки SMS (id: ""%3""):
			|%1 (код ошибки: %2)'; 
			|en = 'Cannot get text message delivery status (id: %3):
			|%1 (error code: %2).'; 
			|pl = 'Nie udało się uzyskać status dostawy SMS (id: ""%3""):
			|%1 (kod błędu: %2)';
			|de = 'Fehler beim Abrufen des SMS-Versandstatus (ID: ""%3""):
			|%1 (Fehlercode: %2)';
			|ro = 'Eșec la obținerea statutului de livrare a SMS (id: ""%3""):
			|%1 (codul erorii: %2)';
			|tr = 'SMS teslimat durumu alınamadı (id: ""%3""): 
			|%1 (hata kodu:%2)'; 
			|es_ES = 'No se ha podido recibir el estado de la entrega de SMS  (id: ""%3""):
			|%1 (código de error: %2)'"), ErrorDescription, ErrorCode, MessageID);
		WriteLogEvent(NStr("ru = 'Отправка SMS'; en = 'Send text messages'; pl = 'Wyslij SMS';de = 'SMS senden';ro = 'Trimitere de SMS';tr = 'SMS gönder'; es_ES = 'Enviar SMS'", Common.DefaultLanguageCode()),
			EventLogLevel.Error, , , Comment);
	EndIf;
	
	Return Result;
	
EndFunction

Function SMSMessageDeliveryStatus(StatusCode)
	StatusesMap = New Map;
	StatusesMap.Insert("1", "Sent");
	StatusesMap.Insert("2", "Delivered");
	StatusesMap.Insert("3", "NotDelivered");
	StatusesMap.Insert("4", "Sending");
	StatusesMap.Insert("6", "NotDelivered");
	StatusesMap.Insert("7", "Pending");
	StatusesMap.Insert("8", "Sending");
	StatusesMap.Insert("9", "NotSent");
	StatusesMap.Insert("10", "Sending");
	StatusesMap.Insert("11", "Sent");
	
	Result = StatusesMap[StatusCode];
	Return ?(Result = Undefined, "Pending", Result);
EndFunction

Function ErrorsDescriptions()
	Result = New Map;
	Result.Insert(1, NStr("ru = 'Неверный API-ключ.'; en = 'Invalid API key.'; pl = 'Błędny API-klucz.';de = 'Falscher API-Schlüssel.';ro = 'Cheia API incorectă.';tr = 'API-anahtar yanlış'; es_ES = 'Clave API incorrecta.'"));
	Result.Insert(2, NStr("ru = 'Неизвестная команда.'; en = 'Unknown command.'; pl = 'Nieznane polecenie.';de = 'Unbekannter Befehl.';ro = 'Comandă necunoscută.';tr = 'Bilinmeyen komut.'; es_ES = 'Comando desconocido.'"));
	Result.Insert(3, NStr("ru = 'Пользователь с указанным ID кабинета не найден.'; en = 'The user with the specified account ID is not found.'; pl = 'Użytkownik ze wskazanym ID konta nie jest znaleziony.';de = 'Der Benutzer mit der angegebenen Konto-ID wurde nicht gefunden.';ro = 'Utilizatorul cu ID cabinetului indicat nu a fost găsit.';tr = 'Belirtilen hesap kimliğine sahip kullanıcı bulunamadı.'; es_ES = 'El usuario con ID indicado no se ha encontrado.'"));
	Result.Insert(4, NStr("ru = 'Пустой список телефонов для отправки сообщений.'; en = 'The list of recipient phone numbers is blank.'; pl = 'Pusta lista telefonów do wysłania komunikatów.';de = 'Leere Telefonliste zum Senden von Nachrichten.';ro = 'Lista de telefoane goală pentru trimiterea mesajelor.';tr = 'Mesaj göndermek için boş telefon listesi.'; es_ES = ' LIsta vacía de teléfonos para enviar los mensajes.'"));
	Result.Insert(5, NStr("ru = 'Не указан текст сообщения.'; en = 'The message text blank.'; pl = 'Nie jest wskazany tekst komunikatu.';de = 'Der Text der Nachricht wird nicht angegeben.';ro = 'Nu este indicat textul mesajului.';tr = 'Mesaj metni belirtilmedi.'; es_ES = 'El texto del mensaje no está indicado.'"));
	Result.Insert(6, NStr("ru = 'Не удалось отправить сообщение на указанный номер.'; en = 'Cannot send the message to the specified number.'; pl = 'Nie udało się wysłać komunikat do wskazanego numeru.';de = 'Die Nachricht konnte nicht an die angegebene Nummer gesendet werden.';ro = 'Eșec la trimiterea mesajului la numărul indicat.';tr = 'Mesaj belirtilen numaraya gönderilemedi.'; es_ES = 'No se ha podido enviar el mensaje al número indicado.'"));
	Result.Insert(7, NStr("ru = 'Не указан отправитель по приоритетному трафику.'; en = 'The priority traffic sender is blank.'; pl = 'Nie jest wskazany nadawca wg ruchu priorytetowego.';de = 'Der Absender des Prioritätsverkehrs ist nicht angegeben.';ro = 'Nu este indicat expeditorul conform traficului prioritar.';tr = 'Öncelikli trafik için gönderen belirtilmedi.'; es_ES = 'No se ha indicado el destinatario por el tráfico prioritario.'"));
	Result.Insert(8, NStr("ru = 'Некорректный отправитель, допускается только латиница и цифры.'; en = 'Invalid sender. Only Latin letters and numbers are allowed.'; pl = 'Niepoprawny nadawca. Używaj liter i cyfr łacińskich.';de = 'Falscher Absender. Verwenden Sie lateinische Buchstaben und Zahlen.';ro = 'Expeditor incorect. Utilizați litere și numere latine.';tr = 'Yanlış gönderen, sadece Latin karakter ve rakamlara izin verilir.'; es_ES = 'Remitente incorrecto, se admiten solo letras latinas y cifras.'"));
	Result.Insert(9, NStr("ru = 'Пустой список идентификаторов сообщений для получения статусов.'; en = 'The list of message IDs in the status request is blank.'; pl = 'Pusta lista identyfikatorów komunikatów do pobierania statusów.';de = 'Leere Liste der Nachrichtenbezeichner um Status abzurufen.';ro = 'Lista goală a identificatorilor mesajelor pentru obținerea statutelor.';tr = 'Durumları almak için mesaj kimlikleri listesi boş.'; es_ES = 'Lista vacía de los identificadores de los mensajes para recibir los estados.'"));
	Result.Insert(10, NStr("ru = 'Не найдено сообщение с таким идентификатором.'; en = 'The message with the specified ID is not found.'; pl = 'Nie znaleziono komunikat z takim identyfikatorem.';de = 'Es wurde keine Nachricht mit einem solchen Identifikator gefunden.';ro = 'Mesajul cu asemenea ID nu a fost găsit.';tr = 'Bu kimliğe sahip mesaj bulunamadı.'; es_ES = 'No está encontrado ningún mensaje con este identificador.'"));
	Result.Insert(11, NStr("ru = 'Не удалось оплатить рассылку, проверьте баланс.'; en = 'Payment error. Please check your balance.'; pl = 'Nie udało się opłacić subskrypcję, sprawdź bilans.';de = 'Der Newsletter konnte nicht bezahlt werden, überprüfen Sie den Kontostand.';ro = 'Eșec la achitarea mailingului, verificați bilanțul.';tr = 'Gönderim bedeli ödenemedi, bakiyeyi kontrol edin.'; es_ES = 'No se ha podido pagar el envío, compruebe el saldo.'"));
	
	Return Result;
EndFunction

Function SendingErrorDescription(ErrorCode)
	ErrorsDescriptions = ErrorsDescriptions();
	MessageText = ErrorsDescriptions[ErrorCode];
	If MessageText = Undefined Then
		MessageText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Сообщение не отправлено (код ошибки: %1).'; en = 'Cannot send the message (error code: %1).'; pl = 'Komunikat nie jest wysłany (kod błędu: %1).';de = 'Nachricht nicht gesendet (Fehlercode: %1).';ro = 'Mesajul nu este trimis (codul erorii: %1).';tr = 'Mesaj gönderilemedi (hata kodu: %1).'; es_ES = 'Mensaje no enviado (código del error: %1).'"), ErrorCode);
	EndIf;
	Return MessageText;
EndFunction

Function StatusGettingErrorDescription(ErrorCode)
	ErrorsDescriptions = ErrorsDescriptions();
	MessageText = ErrorsDescriptions[ErrorCode];
	If MessageText = Undefined Then
		MessageText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Статус сообщения не получен (код ошибки: %1).'; en = 'Cannot get message status (error code: %1).'; pl = 'Status komunikatu nie otrzymano (kod błędu: %1).';de = 'Nachrichtenstatus nicht empfangen (Fehlercode: %1).';ro = 'Statutul mesajului nu este primit (codul erorii: %1).';tr = 'Mesaj durumu alınamadı: (hata kodu: %1).'; es_ES = 'Estado del mensaje no recibido (código del error. %1).'"), ErrorCode);
	EndIf;
	Return MessageText;
EndFunction

Function ExecuteQuery(QueryParameters)
	
	HTTPRequest = SendSMSMessage.PrepareHTTPRequest("/api/", QueryParameters);
	HTTPResponse = Undefined;
	
	Try
		Connection = New HTTPConnection("gsm-inform.ru",,,, 
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

Function RecipientsArrayAsString(Array)
	Recipients = New Array;
	CommonClientServer.SupplementArray(Recipients, Array, True);
	
	Result = "";
	For Each Recipient In Recipients Do
		Number = FormatNumber(Recipient);
		If NOT IsBlankString(Number) Then 
			If Not IsBlankString(Result) Then
				Result = Result + ",";
			EndIf;
			Result = Result + Number;
		EndIf;
	EndDo;
	Return Result;
EndFunction

Function FormatNumber(Number)
	Result = "";
	AllowedChars = "+1234567890";
	For Position = 1 To StrLen(Number) Do
		Char = Mid(Number,Position,1);
		If StrFind(AllowedChars, Char) > 0 Then
			Result = Result + Char;
		EndIf;
	EndDo;
	Return Result;	
EndFunction

// This function returns the list of permissions for sending text messages using all available providers.
//
// Returns:
//  Array.
//
Function Permissions() Export
	
	Protocol = "HTTP";
	Address = "gsm-inform.ru";
	Port = Undefined;
	Details = NStr("ru = 'Отправка SMS через ""GSM-INFORM"".'; en = 'Send text messages via GSM-INFORM.'; pl = 'Wysłanie SMS poprzez ""GSM-INFORM"".';de = 'SMS über ""GSM-INFORM"" versenden.';ro = 'Trimiterea de SMS prin ""GSM-INFORM"".';tr = 'GSM-INFORM üzerinden SMS gönderimi.'; es_ES = 'Envío de SMS a través de ""GSM-INFORM"".'");
	
	ModuleSafeModeManager = Common.CommonModule("SafeModeManager");
	
	Permissions = New Array;
	Permissions.Add(
		ModuleSafeModeManager.PermissionToUseInternetResource(Protocol, Address, Port, Details));
	
	Return Permissions;
EndFunction

Procedure OnDefineSettings(Settings) Export
	
	Settings.ServiceDetailsInternetAddress = "http://gsm-inform.ru";
	Settings.OnDefineAuthorizationMethods = True;
	
EndProcedure

Procedure OnDefineAuthorizationMethods(AuthorizationMethods) Export
	
	AuthorizationMethods.Clear();
	
	AuthorizationFields = New ValueList;
	AuthorizationFields.Add("Username", NStr("ru = 'ID кабинета'; en = 'Account ID'; pl = 'ID konta';de = 'Konto-ID';ro = 'ID cabinetului';tr = 'Hesap kimliği'; es_ES = 'ID de la cuenta'"));
	AuthorizationFields.Add("Password", NStr("ru = 'API-ключ'; en = 'API key'; pl = 'API-klucz';de = 'API-Schlüssel';ro = 'Cheia API';tr = 'API-anahtar'; es_ES = 'Clave API'"));
	
	AuthorizationMethods.Insert("ByKey", AuthorizationFields);
	
EndProcedure

#EndRegion

