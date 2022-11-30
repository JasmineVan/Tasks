///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Private

// Sends a text message via SMS CENTER.
//
// Parameters:
//  RecipientsNumbers - Array - recipient numbers in format +7ХХХХХХХХХХ.
//  Text - String - a message text with length not more than 480 characters.
//  SenderName - String - a sender name that will be displayed instead of a number of incoming text message.
//  Username - String - a username in the text message sending service.
//  Password - String - a password in the text message sending service.
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
	QueryParameters.Insert("login", Username);
	QueryParameters.Insert("psw", Password);
	
	QueryParameters.Insert("mes", Text);
	QueryParameters.Insert("phones", RecipientsString);
	QueryParameters.Insert("sender", SenderName);
	QueryParameters.Insert("fmt", 3); // Response in JSON format.
	QueryParameters.Insert("op", 1); // Display information for each number separately.
	QueryParameters.Insert("charset", "utf-8");

	// Send the query
	ResponseText = ExecuteQuery("send.php", QueryParameters);
	If Not ValueIsFilled(ResponseText) Then
		Result.ErrorDescription = Result.ErrorDescription + NStr("ru = 'Соединение не установлено'; en = 'Connection failed.'; pl = 'Połączenie nie jest ustawione';de = 'Verbindung nicht hergestellt';ro = 'Conexiunea nu a fost stabilită';tr = 'Bağlantı kurulamadı'; es_ES = 'Conexión no establecida'");
		Return Result;
	EndIf;
	
	JSONReader = New JSONReader;
	JSONReader.SetString(ResponseText);
	ServerResponse = ReadJSON(JSONReader);
	JSONReader.Close();
	
	If ServerResponse.Property("error") Then
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
			|%1(código del error: %2)'"), SendingErrorDescription(ServerResponse["error_code"]), ServerResponse["error_code"]);
			
		WriteLogEvent(NStr("ru = 'Отправка SMS'; en = 'Send text messages'; pl = 'Wyslij SMS';de = 'SMS senden';ro = 'Trimitere de SMS';tr = 'SMS gönder'; es_ES = 'Enviar SMS'", Common.DefaultLanguageCode()),
			EventLogLevel.Error, , , Result.ErrorDescription);
	Else
		MessageID = ServerResponse["id"];
		For Each SendingInfo In ServerResponse["phones"] Do
			RecipientNumber = FormatNumber(SendingInfo["phone"]);
			If SendingInfo.Property("status") AND ValueIsFilled(SendingInfo["status"]) Then
				Continue;
			EndIf;
			SentMessage = New Structure("RecipientNumber,MessageID", RecipientNumber,
				"" + RecipientNumber + "/" + Format(MessageID, "NG=0"));
			Result.SentMessages.Add(SentMessage);
		EndDo;
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
	
	IDParts = StrSplit(MessageID, "/", True);
	
	// Prepare query options.
	QueryParameters = New Structure;
	QueryParameters.Insert("login", Username);
	QueryParameters.Insert("psw", Password);
	QueryParameters.Insert("phone", IDParts[0]);
	QueryParameters.Insert("id", Number(IDParts[1]));
	QueryParameters.Insert("fmt", 3);
	
	// Send the query
	ResponseText = ExecuteQuery("status.php", QueryParameters);
	If Not ValueIsFilled(ResponseText) Then
		Return "Error";
	EndIf;
	
	JSONReader = New JSONReader;
	JSONReader.SetString(ResponseText);
	ServerResponse = ReadJSON(JSONReader);
	JSONReader.Close();
	
	If ServerResponse.Property("error") Then
		ErrorDescription = StringFunctionsClientServer.SubstituteParametersToString(NStr(
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
			|%1 (código de error: %2)'"), StatusGettingErrorDescription(ServerResponse["error_code"]), ServerResponse["error_code"], MessageID);
		WriteLogEvent(NStr("ru = 'Отправка SMS'; en = 'Send text messages'; pl = 'Wyslij SMS';de = 'SMS senden';ro = 'Trimitere de SMS';tr = 'SMS gönder'; es_ES = 'Enviar SMS'", Common.DefaultLanguageCode()),
			EventLogLevel.Error, , , ErrorDescription);
		Return "Error";
	EndIf;
	
	Return SMSMessageDeliveryStatus(ServerResponse["status"]);
	
EndFunction

Function SMSMessageDeliveryStatus(StatusCode)
	StatusesMap = New Map;
	StatusesMap.Insert(-3, "Pending");
	StatusesMap.Insert(-1, "Sending");
	StatusesMap.Insert(0, "Sent");
	StatusesMap.Insert(1, "Delivered");
	StatusesMap.Insert(3, "NotDelivered");
	StatusesMap.Insert(20, "NotDelivered");
	StatusesMap.Insert(22, "NotSent");
	StatusesMap.Insert(23, "NotSent");
	StatusesMap.Insert(24, "NotSent");
	StatusesMap.Insert(25, "NotSent");
	
	Result = StatusesMap[StatusCode];
	Return ?(Result = Undefined, "Error", Result);
EndFunction

Function SendingErrorDescription(ErrorCode)
	ErrorsDescriptions = New Map;
	ErrorsDescriptions.Insert(1, NStr("ru = 'Ошибка в параметрах.'; en = 'Parameters error.'; pl = 'Błąd w parametrach.';de = 'Fehler in den Parametern.';ro = 'Eroare în parametri.';tr = 'Parametre hatası.'; es_ES = 'Error en parámetros.'"));
	ErrorsDescriptions.Insert(2, NStr("ru = 'Неверный логин или пароль.'; en = 'Invalid username or password.'; pl = 'Błędny login lub hasło.';de = 'Falscher Login oder Passwort.';ro = 'Parola sau loghin incorecte.';tr = 'Yanlış kullanıcı kodu veya şifre.'; es_ES = 'Nombre o contraseña incorrectos.'"));
	ErrorsDescriptions.Insert(3, NStr("ru = 'Недостаточно средств на счете.'; en = 'Insufficient account balance.'; pl = 'Niewystarczające środki na rachunku.';de = 'Zu wenig Guthaben auf dem Konto.';ro = 'Mijloace insuficiente pe cont.';tr = 'Hesaptaki bakiye yetersiz.'; es_ES = 'Insuficiente saldo.'"));
	ErrorsDescriptions.Insert(4, NStr("ru = 'IP-адрес временно заблокирован из-за частых ошибок в запросах.Подробнее см. http://smsc.ru/faq/99'; en = 'IP address is temporarily blocked due to frequent request errors. For details, see http://smsc.ru/faq/99.'; pl = 'IP-adres tymczasowo jest zablokowany z powodu częstych błędów w zapytaniach. Szczegóły zob. http://smsc.ru/faq/99';de = 'Die IP-Adresse ist aufgrund häufiger Fehler bei Anfragen vorübergehend gesperrt. Weitere Informationen finden Sie unter http://smsc.ru/faq/99';ro = 'Adresa IP este blocată temporar din cauza erorilor frecvente în interogări. Detalii vezi la http://smsc.ru/faq/99';tr = 'IP adresi, isteklerdeki sık sık hatalar nedeniyle geçici olarak engellendi. Daha detaylı bilgi için http://smsc.ru /faq/99'; es_ES = 'La dirección IP está bloqueada temporalmente a causa de los errores frecuentes en las consultas. Véase más http://smsc.ru/faq/99'"));
	ErrorsDescriptions.Insert(5, NStr("ru = 'Неверный формат даты.'; en = 'Invalid datt format.'; pl = 'Błędny format daty.';de = 'Ungültiges Datumsformat.';ro = 'Format de date invalid.';tr = 'Geçersiz veri formatı.'; es_ES = 'Formato de fecha inválido.'"));
	ErrorsDescriptions.Insert(6, NStr("ru = 'Сообщение запрещено (по тексту или по имени отправителя).'; en = 'Message denied (by text or sender name).'; pl = 'Komunikat jest zabroniony (wg tekstu lub wg nazwy nadawcy).';de = 'Nachricht ist verboten (per Text oder Name des Absenders).';ro = 'Mesaj interzis (după text sau numele expeditorului).';tr = 'Mesaj yasaktır (metin veya gönderenin adına göre).'; es_ES = 'Mensaje prohibido (por el texto o por el nombre de remitento).'"));
	ErrorsDescriptions.Insert(7, NStr("ru = 'Неверный формат номера телефона.'; en = 'Invalid phone number format.'; pl = 'Błędny format numeru telefonu.';de = 'Falsches Rufnummernformat.';ro = 'Format incorect al numărului de telefon.';tr = 'Yanlış telefon numarası biçimi.'; es_ES = 'Formato del número de teléfono inválido.'"));
	ErrorsDescriptions.Insert(8, NStr("ru = 'Сообщение на указанный номер не может быть доставлено.'; en = 'Message cannot be delivered to the specified number.'; pl = 'Komunikat do wskazanego numeru nie może być dostarczony.';de = 'Nachricht kann nicht an die angegebene Nummer zugestellt werden.';ro = 'Mesajul nu poate fi livrat la numărul de telefon indicat.';tr = 'Belirtilen numaraya mesaj teslim edilemez.'; es_ES = 'El mensaje al número indicado no puede ser entregado.'"));
	ErrorsDescriptions.Insert(9, NStr("ru = 'Отправка более одного одинакового запроса на передачу SMS-сообщения в течение минуты.'; en = 'Multiple identical requests to send a text message within a minute.'; pl = 'Wysłanie więcej niż jednego jednakowego zapytania do przekazania SMS-komunikatu w ciągu minuty.';de = 'Senden von mehr als einer identischen Aufforderung zum Senden einer SMS innerhalb einer Minute.';ro = 'Trimiterea a mai mult de o interogare similară pentru transmiterea mesajului SMS în decurs de un minut.';tr = 'Bir dakika içinde SMS mesajı göndermek için birden fazla aynı istek gönderildi.'; es_ES = 'El envío de más de una consulta igual de enviar el mensaje SMS durante un minuto.'"));
	
	MessageText = ErrorsDescriptions[ErrorCode];
	If MessageText = Undefined Then
		MessageText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Сообщение не отправлено (код ошибки: %1).'; en = 'Cannot send the message (error code: %1).'; pl = 'Komunikat nie jest wysłany (kod błędu: %1).';de = 'Nachricht nicht gesendet (Fehlercode: %1).';ro = 'Mesajul nu este trimis (codul erorii: %1).';tr = 'Mesaj gönderilemedi (hata kodu: %1).'; es_ES = 'Mensaje no enviado (código del error: %1).'"), ErrorCode);
	EndIf;
	Return MessageText;
EndFunction

Function StatusGettingErrorDescription(ErrorCode)
	ErrorsDescriptions = New Map;
	ErrorsDescriptions.Insert(1, NStr("ru = 'Ошибка в параметрах.'; en = 'Parameters error.'; pl = 'Błąd w parametrach.';de = 'Fehler in den Parametern.';ro = 'Eroare în parametri.';tr = 'Parametre hatası.'; es_ES = 'Error en parámetros.'"));
	ErrorsDescriptions.Insert(2, NStr("ru = 'Неверный логин или пароль.'; en = 'Invalid username or password.'; pl = 'Błędny login lub hasło.';de = 'Falscher Login oder Passwort.';ro = 'Parola sau loghin incorecte.';tr = 'Yanlış kullanıcı kodu veya şifre.'; es_ES = 'Nombre o contraseña incorrectos.'"));
	ErrorsDescriptions.Insert(5, NStr("ru = 'Ошибка удаления сообщения.'; en = 'Message deletion error.'; pl = 'Błąd usuwania komunikatu.';de = 'Fehler beim Löschen der Nachricht.';ro = 'Eroare de ștergere a mesajului.';tr = 'Mesaj silinmesi hatası.'; es_ES = 'Error de eliminar el mensaje.'"));
	ErrorsDescriptions.Insert(4, NStr("ru = 'IP-адрес временно заблокирован из-за частых ошибок в запросах. Подробнее см. http://smsc.ru/faq/99'; en = 'IP address is temporarily blocked due to frequent request errors. For details, see http://smsc.ru/faq/99.'; pl = 'IP-adres tymczasowo jest zablokowany z powodu częstych błędów w zapytaniach. Szczegóły zob. http://smsc.ru/faq/99';de = 'Die IP-Adresse ist aufgrund häufiger Fehler bei Anfragen vorübergehend gesperrt. Weitere Informationen finden Sie unter http://smsc.ru/faq/99';ro = 'Adresa IP este blocată temporar din cauza erorilor frecvente în interogări. Detalii vezi la http://smsc.ru/faq/99';tr = 'IP adresi, isteklerdeki sık sık hatalar nedeniyle geçici olarak engellendi. Daha detaylı bilgi için http://smsc.ru /faq/99'; es_ES = 'La dirección IP está bloqueada temporalmente a causa de los errores frecuentes en las consultas. Véase más http://smsc.ru/faq/99'"));
	ErrorsDescriptions.Insert(9, NStr("ru = 'Отправка более пяти запросов на получения статуса одного и того же сообщения в течение минуты.'; en = 'Over five status requests for a single message within a minute.'; pl = 'Wysłanie więcej niż pięciu zapytań do pobierania statusu jednego i tego samego komunikatu w ciągu minuty.';de = 'Senden von mehr als fünf Anfragen für den gleichen Nachrichtenstatus innerhalb einer Minute.';ro = 'Trimiterea a mai mult de cinci interogări pentru obținerea statutului unuia și aceluiași mesaj în decurs de un minut.';tr = 'Bir dakika içinde aynı mesajın durumu almak için beşten fazla istek gönderildi.'; es_ES = 'El envío de más de cinco consultas para recibir el estado del mismo mensaje durante un minuto.'"));
	
	MessageText = ErrorsDescriptions[ErrorCode];
	If MessageText = Undefined Then
		MessageText = NStr("ru = 'Отказ выполнения операции'; en = 'Operation canceled.'; pl = 'Niezadziałanie wykonania operacji';de = 'Nichterfüllung des Vorgangs';ro = 'Refuz de executare a operației';tr = 'İşlem reddedildi'; es_ES = 'Rechazo de realizar la operación'");
	EndIf;
	Return MessageText;
EndFunction

Function ExecuteQuery(MethodName, QueryParameters)
	
	HTTPRequest = SendSMSMessage.PrepareHTTPRequest("/sys/" + MethodName, QueryParameters);
	HTTPResponse = Undefined;
	
	Try
		Connection = New HTTPConnection("smsc.ru", , , , GetFilesFromInternet.GetProxy("https"), 
			60, CommonClientServer.NewSecureConnection());
		HTTPResponse = Connection.Post(HTTPRequest);
	Except
		WriteLogEvent(NStr("ru = 'Отправка SMS'; en = 'Send text messages'; pl = 'Wyslij SMS';de = 'SMS senden';ro = 'Trimitere de SMS';tr = 'SMS gönder'; es_ES = 'Enviar SMS'", Common.DefaultLanguageCode()),
			EventLogLevel.Error, , , DetailErrorDescription(ErrorInfo()));
		Return Undefined;
	EndTry;
	
	If HTTPResponse.StatusCode <> 200 Then
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Запрос ""%1"" не выполнен. Код состояния: %2.'; en = 'The %1 request failed. Status code: %2.'; pl = 'Zapytanie ""%1"" nie jest wykonane. Kod statusu: %2.';de = 'Anforderung ""%1"" nicht ausgeführt. Statuscode: %2.';ro = 'Interogarea ""%1"" nu este executată. Codul statutului: %2.';tr = '""%1"" isteği başarısız oldu. Durum kodu: %2'; es_ES = 'La solicitud ""%1"" no se ha realizado, Código del estado: %2.'"), MethodName, HTTPResponse.StatusCode) + Chars.LF
			+ HTTPResponse.GetBodyAsString();
		WriteLogEvent(NStr("ru = 'Отправка SMS'; en = 'Send text messages'; pl = 'Wyslij SMS';de = 'SMS senden';ro = 'Trimitere de SMS';tr = 'SMS gönder'; es_ES = 'Enviar SMS'", Common.DefaultLanguageCode()),
			EventLogLevel.Error, , , ErrorText);
		Return Undefined;
	EndIf;
	
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
	
	Protocol = "HTTPS";
	Address = "smsc.ru";
	Port = Undefined;
	Details = NStr("ru = 'Отправка SMS через ""SMS-ЦЕНТР"".'; en = 'Send text messages via SMS CENTER.'; pl = 'Wysłanie SMS poprzez ""SMS-ЦЕНТР"".';de = 'SMS über ""SMS-ZENTRUM"" versenden.';ro = 'Trimiterea de SMS prin ""SMS-CENTRU"".';tr = 'SMS-MERKEZİ üzerinden SMS gönderimi.'; es_ES = 'Enviar SMS a través de ""SMS-CENTRO"".'");
	
	ModuleSafeModeManager = Common.CommonModule("SafeModeManager");
	
	Permissions = New Array;
	Permissions.Add(
		ModuleSafeModeManager.PermissionToUseInternetResource(Protocol, Address, Port, Details));
	
	Return Permissions;
EndFunction

Procedure OnDefineSettings(Settings) Export
	
	Settings.ServiceDetailsInternetAddress = "https://smsc.ru";
	
EndProcedure


#EndRegion

