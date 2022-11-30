///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Private

// Sends a text message via SMS4B.
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
	
	QueryParameters = New Structure;
	QueryParameters.Insert("Login", Username);
	QueryParameters.Insert("Password", Password);
	QueryParameters.Insert("Source", SenderName);
	QueryParameters.Insert("Text", Text);
	
	For Each RecipientNumber In RecipientsNumbers Do
		QueryParameters.Insert("Phone", FormatNumber(RecipientNumber));
		QueryResult = ExecuteQuery("SendTXT", QueryParameters);
		
		If StrLen(QueryResult) = 20 Then
			SentMessage = New Structure("RecipientNumber,MessageID", RecipientNumber, QueryResult);
			Result.SentMessages.Add(SentMessage);
		Else
			Result.ErrorDescription = Result.ErrorDescription + StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'SMS на номер %1 не отправлено'; en = 'Cannot send text message to number %1'; pl = 'SMS na numer %1 nie wysłano';de = 'SMS an Nummer %1 nicht gesendet';ro = 'SMS la numărul %1 nu este trimis';tr = '%1 numaraya SMS gönderilmedi'; es_ES = 'SMS al número %1 no se ha enviado'"), RecipientNumber) + ": " + SendingErrorDescription(QueryResult) + Chars.LF;
		EndIf;
	EndDo;
	
	Result.ErrorDescription = TrimR(Result.ErrorDescription);
	If Not IsBlankString(Result.ErrorDescription) Then
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
	QueryParameters.Insert("Login", Username);
	QueryParameters.Insert("Password", Password);
	QueryParameters.Insert("MessageId", MessageID);
	
	// Send the query
	StatusCode = ExecuteQuery("StatusTXT", QueryParameters);
	If IsBlankString(StatusCode) Then
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

Function SMSMessageDeliveryStatus(Val StatusCode)
	StatusesMap = New Map;
	StatusesMap.Insert("-21", "Pending");
	StatusesMap.Insert("-22", "Pending");
	
	If IsBlankString(StatusCode) Or StrStartsWith(StatusCode, "-") 
		Or Not StringFunctionsClientServer.OnlyNumbersInString(StatusCode) Then
			Result = StatusesMap[Lower(StatusCode)];
			Return ?(Result = Undefined, "Error", Result);
	EndIf;
	
	StatusCode = Number(StatusCode);
	
	TotalFragments = StatusCode % 256;
	FragmentsSent = Int(StatusCode / 256) % 256;
	FinalStatus = StatusCode >= 256*256;
	
	If FinalStatus Then
		If TotalFragments = 0 Or TotalFragments > FragmentsSent Then
			Result = "NotDelivered";
		Else
			Result = "Delivered";
		EndIf;
	Else
		If TotalFragments = 0 Or TotalFragments > FragmentsSent Then
			Result = "Sending";
		Else
			Result = "Sent";
		EndIf;
	EndIf;
	
	Return Result;
EndFunction

Function ErrorsDescriptions()
	ErrorsDescriptions = New Map;
	
	ErrorsDescriptions.Insert("0", NStr("ru = 'Превышен предел открытых сессий.'; en = 'Open sessions limit exceeded.'; pl = 'Został przekroczony limit otwartych sesji.';de = 'Das Limit für offene Sitzungen wurde überschritten.';ro = 'Este depășită limita de sesiuni deschise.';tr = 'Açık oturumların maksimum sayısı aşıldı.'; es_ES = 'Se ha superado el límite de las sesiones abiertas.'"));
	ErrorsDescriptions.Insert("-1", NStr("ru = 'Неверный логин или пароль.'; en = 'Invalid username or password.'; pl = 'Błędny login lub hasło.';de = 'Falscher Login oder Passwort.';ro = 'Parola sau loghin incorecte.';tr = 'Yanlış kullanıcı kodu veya şifre.'; es_ES = 'Nombre o contraseña incorrectos.'"));
	ErrorsDescriptions.Insert("-10", NStr("ru = 'Отказ сервиса.'; en = 'Service denied.'; pl = 'Niezadziałanie serwisu.';de = 'Servicefehler.';ro = 'Refuzul serviciului.';tr = 'Servis reddi.'; es_ES = 'Rechazo del servidor.'"));
	ErrorsDescriptions.Insert("-20", NStr("ru = 'Сбой сеанса связи.'; en = 'Session error.'; pl = 'Zacięcie sesji połączenia.';de = 'Kommunikationsfehler.';ro = 'Eșecul sesiunii de comunicare.';tr = 'Oturum hatası.'; es_ES = 'Fallo de la sesión de conexión.'"));
	ErrorsDescriptions.Insert("-21", NStr("ru = 'Сообщение не идентифицировано.'; en = 'Invalid message GUID.'; pl = 'Komunikat nie jest zidentyfikowany.';de = 'Nachricht nicht identifiziert.';ro = 'Mesajul nu este identificat.';tr = 'Mesaj tanımlanamadı.'; es_ES = 'Mensaje no identificado.'"));
	ErrorsDescriptions.Insert("-22", NStr("ru = 'Неверный идентификатор сообщения.'; en = 'Invalid message ID.'; pl = 'Błędny identyfikator komunikatu.';de = 'Falsche Nachrichtenkennung.';ro = 'ID incorect l mesajului.';tr = 'Yanlış mesaj kimliği.'; es_ES = 'Identificador del mensaje incorrecto.'"));
	ErrorsDescriptions.Insert("-29", NStr("ru = 'Отвергнуто спам-фильтром.'; en = 'Rejected by spam filter.'; pl = 'Zostało odrzucone przez filtr antyspamowy.';de = 'Vom Spamfilter abgelehnt.';ro = 'Respins de filtrul spam.';tr = 'Spam filtresi tarafından reddedildi.'; es_ES = 'Rechazado por el filtro de no deseado.'"));
	ErrorsDescriptions.Insert("-30", NStr("ru = 'Неверная кодировка сообщения.'; en = 'Invalid message encoding.'; pl = 'Niewłaściwe kodowanie komunikatu.';de = 'Falsche Nachrichtencodierung.';ro = 'Codificare incorectă a mesajului.';tr = 'Yanlış mesaj kodu.'; es_ES = 'Codificación incorrecta del mensaje.'"));
	ErrorsDescriptions.Insert("-31", NStr("ru = 'Неразрешенная зона тарификации.'; en = 'Restricted tariff zone.'; pl = 'Niedozwolona strefa taryfikacji.';de = 'Nicht autorisierte Abrechnungszone.';ro = 'Zonă de tarificare nepermisă.';tr = 'Izin verilmeyen tarifelendirme alanı.'; es_ES = 'Zona de tarificación no permitida.'"));
	ErrorsDescriptions.Insert("-50", NStr("ru = 'Неверный отправитель.'; en = 'Invalid sender.'; pl = 'Błędny nadawca.';de = 'Falscher Absender.';ro = 'Expeditor incorect.';tr = 'Gönderen yanlış.'; es_ES = 'Remitente incorrecto.'"));
	ErrorsDescriptions.Insert("-51", NStr("ru = 'Неразрешенный получатель.'; en = 'Restricted recipient.'; pl = 'Niedozwolony odbiorca.';de = 'Unbefugter Empfänger.';ro = 'Destinatar incorect.';tr = 'Alıcı yanlış.'; es_ES = 'Destinatario no permitido.'"));
	ErrorsDescriptions.Insert("-52", NStr("ru = 'Недостаточно средств на счете.'; en = 'Insufficient account balance.'; pl = 'Niewystarczające środki na rachunku.';de = 'Zu wenig Guthaben auf dem Konto.';ro = 'Mijloace insuficiente pe cont.';tr = 'Hesaptaki bakiye yetersiz.'; es_ES = 'Insuficiente saldo.'"));
	ErrorsDescriptions.Insert("-53", NStr("ru = 'Незарегистрированный отправитель.'; en = 'Unregistered sender.'; pl = 'Nie zarejestrowany nadawca.';de = 'Nicht registrierter Absender.';ro = 'Expeditor neînregistrat.';tr = 'Gönderen kayıtlı değil.'; es_ES = 'Remitente no registrado.'"));
	ErrorsDescriptions.Insert("-65", NStr("ru = 'Необходимы гарантии отправителя, обратитесь в техподдержку.'; en = 'Sender guarantees are required. Please contact the technical support.'; pl = 'Potrzebne są gwarancje nadawcy, zwróć się do pomocy technicznej.';de = 'Die Absendergarantie ist erforderlich, wenden Sie sich an den technischen Support.';ro = 'Sunt necesare garanțiile expeditorului, adresați-vă în suportul tehnic.';tr = 'Gönderenin garantileri gerekiyor, teknik destek servisine başvurun.'; es_ES = 'Se requieren garantías del remitente, diríjase al soporte técnico.'"));
	ErrorsDescriptions.Insert("-66", NStr("ru = 'Не задан отправитель.'; en = 'Sender not specified.'; pl = 'Nie jest podany nadawca.';de = 'Kein Absender zugeordnet.';ro = 'Nu este specificat expeditorul.';tr = 'Gönderen tanımlanmamış.'; es_ES = 'Remitente no especificado.'"));
	ErrorsDescriptions.Insert("-68", NStr("ru = 'Аккаунт заблокирован.'; en = 'Account locked.'; pl = 'Konto jest zablokowane.';de = 'Das Konto ist gesperrt.';ro = 'Account blocat.';tr = 'Hesap bloke edildi.'; es_ES = 'Cuenta bloqueada.'"));
	
	Return ErrorsDescriptions;
EndFunction

Function SendingErrorDescription(ErrorCode)
	ErrorsDescriptions = ErrorsDescriptions();
	MessageText = ErrorsDescriptions[ErrorCode];
	If MessageText = Undefined Then
		MessageText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Код ошибки: ""%1"".'; en = 'Error code: %1.'; pl = 'Kod błędu: ""%1"".';de = 'Fehlercode: ""%1"".';ro = 'Codul erorii: ""%1"".';tr = 'Hata kodu: ""%1"".'; es_ES = 'Código de error: ""%1"".'"), ErrorCode);
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
	
	HTTPRequest = SendSMSMessage.PrepareHTTPRequest("/ws/s1c.asmx/" + MethodName, QueryParameters);
	HTTPResponse = Undefined;
	
	Try
		Connection = New HTTPConnection("sms4b.ru",,,, 
			GetFilesFromInternet.GetProxy("https"),
			60, 
			CommonClientServer.NewSecureConnection());
			
		HTTPResponse = Connection.Post(HTTPRequest);
	Except
		WriteLogEvent(NStr("ru = 'Отправка SMS'; en = 'Send text messages'; pl = 'Wyslij SMS';de = 'SMS senden';ro = 'Trimitere de SMS';tr = 'SMS gönder'; es_ES = 'Enviar SMS'", Common.DefaultLanguageCode()),
			EventLogLevel.Error, , , DetailErrorDescription(ErrorInfo()));
	EndTry;
	
	Result = "";
	If HTTPResponse <> Undefined Then
		ResponseText = HTTPResponse.GetBodyAsString();
		XMLReader = New XMLReader;
		XMLReader.SetString(ResponseText);
		XMLReader.Read();
		If XMLReader.Name = "string" Then
			If XMLReader.Read() Then
				Result = XMLReader.Value;
			EndIf;
		EndIf;
		XMLReader.Close();
	EndIf;
	
	Return Result;
	
EndFunction

Function FormatNumber(Number)
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

// This function returns the list of permissions for sending text messages using all available providers.
//
// Returns:
//  Array.
//
Function Permissions() Export
	
	Protocol = "HTTPS";
	Address = "sms4b.ru";
	Port = Undefined;
	Details = NStr("ru = 'Отправка SMS через ""SMS4B"".'; en = 'Send text messages via SMS4B.'; pl = 'Wysyłanie SMS poprzez ""SMS4B"".';de = 'SMS über ""SMS4B"" versenden.';ro = 'Trimiterea de SMS prin ""SMS4B"".';tr = 'SMS4B üzerinden SMS gönderimi.'; es_ES = 'Enviar SMS a través de ""SMS4B"".'");
	
	ModuleSafeModeManager = Common.CommonModule("SafeModeManager");
	
	Permissions = New Array;
	Permissions.Add(
		ModuleSafeModeManager.PermissionToUseInternetResource(Protocol, Address, Port, Details));
	
	Return Permissions;
EndFunction

Procedure OnDefineSettings(Settings) Export
	
	Settings.ServiceDetailsInternetAddress = "http://sms4b.ru";
	
EndProcedure

#EndRegion

