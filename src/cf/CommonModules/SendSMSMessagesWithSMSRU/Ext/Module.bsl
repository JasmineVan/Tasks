///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Private

// Sends a text message via SMS.RU.
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
	QueryParameters.Insert("login", Username);
	QueryParameters.Insert("password", Password);
	QueryParameters.Insert("text", Text);
	QueryParameters.Insert("to", RecipientsString);
	QueryParameters.Insert("from", SenderName);
	
	// Send the query
	ResponseText = ExecuteQuery("sms/send", QueryParameters);
	If Not ValueIsFilled(ResponseText) Then
		Result.ErrorDescription = Result.ErrorDescription + NStr("ru = 'Соединение не установлено'; en = 'Connection failed.'; pl = 'Połączenie nie jest ustawione';de = 'Verbindung nicht hergestellt';ro = 'Conexiunea nu a fost stabilită';tr = 'Bağlantı kurulamadı'; es_ES = 'Conexión no establecida'");
		Return Result;
	EndIf;
	
	MessagesIDs = StrSplit(ResponseText, Chars.LF);
	
	ServerResponse = MessagesIDs[0];
	MessagesIDs.Delete(0);
	
	If ServerResponse = "100" Then
		RecipientsNumbers = StrSplit(RecipientsString, ",", False);
		If MessagesIDs.Count() < RecipientsNumbers.Count() Then
			Result.ErrorDescription = NStr("ru = 'Ответ сервера не распознан'; en = 'Cannot parse the server response.'; pl = 'Odpowiedź serwera nie jest rozpoznana';de = 'Serverantwort nicht erkannt';ro = 'Răspunsul serverului nu este recunoscut';tr = 'Sunucu yanıtı tanınmıyor'; es_ES = 'Respuesta del servidor no reconocida'");
			Return Result;
		EndIf;
		
		For Index = 0 To RecipientsNumbers.UBound() Do
			RecipientNumber = RecipientsNumbers[Index];
			MessageID = MessagesIDs[Index];
			If Not IsBlankString(RecipientNumber) Then
				SentMessage = New Structure("RecipientNumber,MessageID",
					RecipientNumber,MessageID);
				Result.SentMessages.Add(SentMessage);
			EndIf;
		EndDo;
	Else
		Result.ErrorDescription = SendingErrorDescription(ServerResponse);
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
	QueryParameters.Insert("login", Username);
	QueryParameters.Insert("password", Password);
	QueryParameters.Insert("id", MessageID);
	
	// Send the query
	StatusCode = ExecuteQuery("sms/status", QueryParameters);
	If Not ValueIsFilled(StatusCode) Then
		Return "Error";
	EndIf;
	
	Result = SMSMessageDeliveryStatus(StatusCode);
	If Result = "Error" Then
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
			|%1 (código de error: %2)'"), StatusGettingErrorDescription(StatusCode), StatusCode, MessageID);
		WriteLogEvent(NStr("ru = 'Отправка SMS'; en = 'Send text messages'; pl = 'Wyslij SMS';de = 'SMS senden';ro = 'Trimitere de SMS';tr = 'SMS gönder'; es_ES = 'Enviar SMS'", Common.DefaultLanguageCode()),
			EventLogLevel.Error, , , ErrorDescription);
	EndIf;
	
	Return Result;
	
EndFunction

Function SMSMessageDeliveryStatus(StatusCode)
	StatusesMap = New Map;
	StatusesMap.Insert("-1", "Pending");
	StatusesMap.Insert("100", "Pending");
	StatusesMap.Insert("101", "Sending");
	StatusesMap.Insert("102", "Sent");
	StatusesMap.Insert("103", "Delivered");
	StatusesMap.Insert("104", "NotDelivered");
	StatusesMap.Insert("105", "NotDelivered");
	StatusesMap.Insert("106", "NotDelivered");
	StatusesMap.Insert("107", "NotDelivered");
	StatusesMap.Insert("108", "NotDelivered");
	
	Result = StatusesMap[Lower(StatusCode)];
	Return ?(Result = Undefined, "Error", Result);
EndFunction

Function ErrorsDescriptions()
	ErrorsDescriptions = New Map;
	ErrorsDescriptions.Insert("200", NStr("ru = 'Авторизация не выполнена: неверный api_id.'; en = 'Authorization failed: invalid api_id.'; pl = 'Autoryzacja nie jest wykonana: błędny api_id.';de = 'Autorisierung fehlgeschlagen: ungültige api_id.';ro = 'Autorizarea nu este executată: api_id incorect.';tr = 'Yetkilendirme başarısız: yanlış api_id.'; es_ES = 'Autorización no realizada: api_id incorrecto.'"));
	ErrorsDescriptions.Insert("201", NStr("ru = 'Не достаточно средств на лицевом счету.'; en = 'Insufficient account balance.'; pl = 'Nie wystarczająco środków na koncie osobistym.';de = 'Nicht genügend Geld auf dem persönlichen Konto.';ro = 'Mijloace insuficiente pe contul personal.';tr = 'Hesaptaki bakiye yetersiz.'; es_ES = 'Insuficiente saldo en su cuenta personal.'"));
	ErrorsDescriptions.Insert("202", NStr("ru = 'Неправильно указан получатель.'; en = 'Invalid recipient.'; pl = 'Nieprawidłowo jest wskazany odbiorca.';de = 'Ungültiger Empfänger.';ro = 'Destinatarul este indicat incorect.';tr = 'Alıcı yanlış belirtildi.'; es_ES = 'Se ha indicado incorrectamente el destinatario.'"));
	ErrorsDescriptions.Insert("203", NStr("ru = 'Нет текста сообщения.'; en = 'Blank message text.'; pl = 'Brak tekstu komunikatu.';de = 'Kein Nachrichtentext';ro = 'Lipsește textul mesajului.';tr = 'Mesaj metni yok.'; es_ES = 'No hay texto del mensaje.'"));
	ErrorsDescriptions.Insert("204", NStr("ru = 'Имя отправителя не согласовано с провайдером (SMS.RU).'; en = 'Sender name not approved by provider (SMS.RU).'; pl = 'Imię nadawcy nie jest uzgodnione z operatorem Internetu (SMS.RU).';de = 'Der Name des Absenders ist nicht mit dem Provider abgestimmt (SMS.RU).';ro = 'Numele expeditorului nu este coordonat cu providerul (SMS.RU).';tr = 'Gönderenin adı sağlayıcı tarafından (SMS.RU) onaylanmadı.'; es_ES = 'Nombre del destinatario no está acordado con el proveedor (SMS.RU).'"));
	ErrorsDescriptions.Insert("205", NStr("ru = 'Сообщение слишком длинное (превышает 8 SMS).'; en = 'Message too long (exceeds 8 text messages).'; pl = 'Komunikat zbyt długi (przekracza 8 SMS).';de = 'Die Nachricht ist zu lang (mehr als 8 SMS).';ro = 'Mesaj prea lung (depășește 8 SMS).';tr = 'Mesaj çok uzun (8 SMS''den fazla).'; es_ES = 'El mensaje es demasiado largo (supera 8 SMS).'"));
	ErrorsDescriptions.Insert("206", NStr("ru = 'Достигнут дневной лимит на отправку сообщений.'; en = 'Daily limit of sent messages reached.'; pl = 'Został osiągnięty dzienny limit wysyłania komunikatów.';de = 'Das Tageslimit für den Versand von Nachrichten ist erreicht.';ro = 'Limita zilnică pentru trimiterea mesajelor a fost atinsă.';tr = 'Mesaj gönderimi için günlük limite ulaşıldı.'; es_ES = 'Se ha logrado el límite diario de enviar los mensajes.'"));
	ErrorsDescriptions.Insert("207", NStr("ru = 'На этот номер (или один из номеров) нельзя отправлять сообщения, либо указано более 100 номеров в списке получателей'; en = 'Cannot send messages to the number (or one of the numbers), or more than 100 numbers in the recipient list.'; pl = 'Na ten numer (lub jeden z numerów) nie można wysyłać komunikatu, albo jest wskazane więcej niż 100 numerów w liście odbiorców';de = 'Nachrichten können nicht an diese Nummer (oder eine der Nummern) gesendet werden, oder es werden mehr als 100 Nummern in der Liste der Empfänger angegeben';ro = 'Nu puteți trimite mesajul la acest număr (sau la unul din numere), deoarece sunt indicate mai mult de 100 de numere în lista destinatarilor';tr = 'Bu numaraya (veya numaralardan birine) mesaj gönderilemez veya alıcı listesinde 100''den fazla numara gösterilir'; es_ES = 'No se ha podido enviar mensajes a este número (o uno de los números), o se ha indicado más de 100 números en la lista de destinatarios'"));
	ErrorsDescriptions.Insert("208", NStr("ru = 'Параметр time указан неправильно.'; en = 'Invalid ""time"" parameter.'; pl = 'Parametr time jest wskazany niepoprawnie.';de = 'Der Parameter time ist nicht korrekt angegeben.';ro = 'Parametrul time este indicat incorect.';tr = 'Time parametresi yanlış belirtildi.'; es_ES = 'El parámetro time se ha indicado incorrectamente.'"));
	ErrorsDescriptions.Insert("209", NStr("ru = 'Номер получателя (или один из номеров) в стоп-листе (см. в личном кабинете на сайте).'; en = 'Recipient number (or one of the numbers) is in the stop list (see the details in your personal account on the website).'; pl = 'Numer odbiorcy (lub jeden z numerów) w liście stop (zob. na swoim koncie na stronie).';de = 'Die Nummer des Empfängers (oder eine der Nummern) in der Stopp-Liste (siehe das persönliche Konto auf der Website).';ro = 'Numărul destinatarului (sau unul din numere) în stop-listă (vezi în cabinetul personal pe site).';tr = 'Alıcı numarası (veya numaralardan biri) stop-listesindedir (bkz.sitedeki kişisel hesap).'; es_ES = 'El número de destinatario (o uno de los números) en la lista de detención (véase en su cuenta en la página).'"));
	ErrorsDescriptions.Insert("210", NStr("ru = 'Используется GET, где необходимо использовать POST.'; en = 'GET is used where POST is required.'; pl = 'Wykorzystywana GET, gdzie należy stosować POST.';de = 'Es wird von GET verwendet, wo es notwendig ist, POST zu verwenden.';ro = 'Se utilizează GET acolo, unde trebuie de utilizat POST.';tr = 'POST kullanılması gereken yerde GET kullanılıyor.'; es_ES = 'Se usa GET donde hay que usar POST.'"));
	ErrorsDescriptions.Insert("211", NStr("ru = 'Метод не найден.'; en = 'Method not found.'; pl = 'Metoda nie jest znaleziona.';de = 'Methode nicht gefunden.';ro = 'Metoda nu a fost găsită.';tr = 'Yöntem bulunamadı.'; es_ES = 'Método no encontrado.'"));
	ErrorsDescriptions.Insert("212", NStr("ru = 'Неверная кодировка текста сообщения (необходимо использовать UTF-8).'; en = 'Invalid message text encoding (UTF-8 required).'; pl = 'Niewłaściwe kodowanie tekstu komunikatu (należy stosować UTF-8).';de = 'Die Kodierung des Nachrichtentextes ist falsch (UTF-8 sollte verwendet werden).';ro = 'Codificare incorectă a textului mesajului (trebuie să utilizați UTF-8).';tr = 'Mesaj metni yanlış kodlandı (UTF-8 kullanılmalıdır).'; es_ES = 'Codificación incorrecta del texto del mensaje (es necesario usar UTF-8).'"));
	ErrorsDescriptions.Insert("220", NStr("ru = 'Сервис временно недоступен.'; en = 'Service temporarily unavailable.'; pl = 'Serwis tymczasowo jest niedostępny.';de = 'Der Service ist vorübergehend nicht verfügbar.';ro = 'Serviciul temporar este inaccesibil.';tr = 'Servis geçici olarak hizmet dışıdır.'; es_ES = 'Servicio no disponible temporalmente.'"));
	ErrorsDescriptions.Insert("230", NStr("ru = 'Сообщение не принято к отправке: достигнут дневной лимит сообщений на один номер (60 шт).'; en = 'Message cannot be sent: daily limit of messages to a single number (60) reached.'; pl = 'Komunikat nie był przyjęty do wysłania: Został osiągnięty dzienny limit komunikatów do jednego numeru (60 szt.).';de = 'Die Nachricht wird zum Senden nicht akzeptiert: Das tägliche Limit der Nachrichten an eine Nummer (60 Stück) ist erreicht.';ro = 'Mesajul nu este acceptat pentru trimitere: a fost atinsă limita zilnică a mesajelor la un număr (60 un.).';tr = 'Gönderilecek mesaj kabul edilmedi: bir numara için günlük mesaj limitine (60 adet) ulaşıldı.'; es_ES = 'El mensaje no está aceptado para enviar: se ha logrado el límite diario de los mensaje a un número (60 unidades).'"));
	ErrorsDescriptions.Insert("300", NStr("ru = 'Авторизация не выполнена: token устарел (истек срок действия, либо изменился IP отправителя.'; en = 'Authorization failed: outdated token (token expired or sender IP address changed).'; pl = 'Autoryzacja nie jest wykonana: token przestarzały (upłynął termin czynności, albo został zmieniony IP nadawcy.';de = 'Berechtigung nicht ausgeführt: Token ist veraltet (abgelaufen oder die IP des Absenders hat sich geändert.';ro = 'Autorizarea nu este executată: tokenul este învechit (s-a scurs termenul de valabilitate sau s-a modificat IP-ul expeditorului.';tr = 'Yetkilendirme başarısız oldu: token eskimiş (geçerlilik süresi doldu veya gönderenin IP değişti.'; es_ES = 'Autorización no realizada: token está caducado (su período de validez se ha expirado o se ha cambiado IP del remitente.'"));
	ErrorsDescriptions.Insert("301", NStr("ru = 'Авторизация не выполнена: логин или пароль указаны неверно.'; en = 'Authorization failed: invalid username or password.'; pl = 'Autoryzacja nie powiodła się: nazwa użytkownika lub hasło są nieprawidłowe.';de = 'Die Autorisierung ist fehlgeschlagen: Der Benutzername oder das Passwort ist falsch.';ro = 'Autorizația a eșuat: numele de utilizator sau parola sunt incorecte.';tr = 'Yetkilendirme başarısız oldu: girilen kullanıcı kodu veya şifre yanlıştır.'; es_ES = 'Autorización fallada: el nombre de usuario o la contraseña son incorrectos.'"));
	ErrorsDescriptions.Insert("302", NStr("ru = 'Авторизация не выполнена: пользователь авторизован, но аккаунт не подтвержден (пользователь не ввел код, присланный в регистрационной SMS.)'; en = 'Authorization failed: the user is authorized but the account is not confirmed (the user did not enter the code from the registration text message.)'; pl = 'Autoryzacja nie jest wykonana: użytkownik jest autoryzowany, ale konto nie jest potwierdzone (użytkownik nie wprowadził kod, przysłany do SMS rejestracyjnego.)';de = 'Die Autorisierung wurde nicht ausgeführt: Der Benutzer ist autorisiert, aber das Konto ist nicht bestätigt (der Benutzer hat den in der Registrierungs-SMS gesendeten Code nicht eingegeben).';ro = 'Autorizarea nu este executată: utilizatorul a fost autorizat, dar accountul nu a fost confirmat (utilizatorul nu a introdus codul trimis în SMS pentru înregistrare.)';tr = 'Yetkilendirme başarısız oldu: kullanıcı yetkilendirildi, ancak hesap onaylanmadı (kullanıcı kayıt SMS''de gönderilen kodu girmedi.)'; es_ES = 'Autorización no realizada: el usuario se ha autorizado, pero la cuenta no está comprobada (el usuario no ha introducido el código enviado en SMS de registro.)'"));
	
	Return ErrorsDescriptions;
EndFunction

Function SendingErrorDescription(ErrorCode)
	ErrorsDescriptions = ErrorsDescriptions();
	MessageText = ErrorsDescriptions[ErrorCode];
	If MessageText = Undefined Then
		MessageText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Сообщение не отправлено (код ошибки: %1).'; en = 'The message is not sent (error code: %1).'; pl = 'Komunikat nie jest wysłany (kod błędu: %1).';de = 'Nachricht nicht gesendet (Fehlercode: %1).';ro = 'Mesajul nu este trimis (codul erorii: %1).';tr = 'Mesaj gönderilemedi (hata kodu: %1).'; es_ES = 'Mensaje no enviado (código del error: %1).'"), ErrorCode);
	EndIf;
	Return MessageText;
EndFunction

Function StatusGettingErrorDescription(ErrorCode)
	ErrorsDescriptions =ErrorsDescriptions();
	MessageText = ErrorsDescriptions[ErrorCode];
	If MessageText = Undefined Then
		MessageText = NStr("ru = 'Отказ выполнения операции'; en = 'Operation canceled.'; pl = 'Niezadziałanie wykonania operacji';de = 'Nichterfüllung des Vorgangs';ro = 'Refuz de executare a operației';tr = 'İşlem reddedildi'; es_ES = 'Rechazo de realizar la operación'");
	EndIf;
	Return MessageText;
EndFunction

Function ExecuteQuery(MethodName, QueryParameters)
	
	HTTPRequest = SendSMSMessage.PrepareHTTPRequest("/" + MethodName, QueryParameters);
	HTTPResponse = Undefined;
	
	Try
		Connection = New HTTPConnection("sms.ru", , , , GetFilesFromInternet.GetProxy("https"),
			60, CommonClientServer.NewSecureConnection());
			
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
	Address = "sms.ru";
	Port = Undefined;
	Details = NStr("ru = 'Отправка SMS через ""SMS.RU"".'; en = 'Send text messages via SMS.RU.'; pl = 'Wysłanie SMS poprzez ""SMS.RU"".';de = 'SMS über ""SMS.RU"" versenden.';ro = 'Trimiterea de SMS prin ""SMS.RU"".';tr = 'SMS.RU üzerinden SMS gönderimi.'; es_ES = 'Enviar SMS a través de ""SMS.RU"".'");
	
	ModuleSafeModeManager = Common.CommonModule("SafeModeManager");
	
	Permissions = New Array;
	Permissions.Add(
		ModuleSafeModeManager.PermissionToUseInternetResource(Protocol, Address, Port, Details));
	
	Return Permissions;
EndFunction

Procedure OnDefineSettings(Settings) Export
	
	Settings.ServiceDetailsInternetAddress = "http://sms.ru";
	
EndProcedure

#EndRegion

