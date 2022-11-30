///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Public

// Sends emails.
// The function might throw an exception which must be handled.
//
// Parameters:
//  Account - CatalogRef.EmailAccounts - reference to an email account.
//                 
//  SendingParameters - Structure - contains all email data:
//
//   * To - Array, String - recipient email addresses.
//          - Array - collection of address structures:
//              * Address         - String - email address (required).
//              * Presentation - String - recipient's name.
//          - String - email recipient addresses, separator - ";".
//
//   * MessageRecipients - Array - array of structures describing recipients:
//      ** Address - String - an email recipient address.
//      ** Presentation - String - addressee presentation.
//
//   * Cc        - Array, String - email addresses of copy recipients. See the "To" field description.
//
//   * BCC - Array, String - email addresses of BCC recipients. See the "To" field description.
//
//   * MailSubject       - String - (mandatory) email subject.
//   * Body       - String - (mandatory) email text (plain text, win1251 encoded).
//   * Importance   - InternetMailMessageImportance.
//
//   * Attachments - Array - attached files (described as structures):
//     ** Presentation - String - attachment file name.
//     ** AddressInTempStorage - String - binary attachment data address in temporary storage.
//     ** Encoding - String - an attachment encoding (used if it differs from the message encoding).
//     ** ID - String - (optional) used to store images displayed in the message body.
//
//   * ReplyAddress - Map - see the "To" field description.
//   * BasisIDs - String - IDs of the message basis objects.
//   * ProcessTexts  - Boolean - shows whether message text processing is required on sending.
//   * RequestDeliveryReceipt  - Boolean - shows whether a delivery notification is required.
//   * RequestReadReceipt - Boolean - shows whether a read notification is required.
//   * TextType   - String, Enum.EmailTextTypes, InternetMailTextType - specifies the type of the 
//                  passed text, possible values:
//                  HTML/EmailTextTypes.HTML - email text in HTML format.
//                  PlainText/EmailTextTypes.PlainText - plain text of email message.
//                                                                          Displayed "as is" 
//                                                                          (default value).
//                  MarkedUpText/EmailTextTypes.MarkedUpText - email message in
//                                                                                  Rich Text.
//   * Connection - InternetMail - an existing connection to a mail server. If not specified, a new one is created.
//   * MailProtocol - String - if "IMAP" is specified, IMAP is used. If "All" is specified, both 
//                              SMTP and IMAP are used. If nothing is specified, SMTP is used.
//                               The parameter has relevance only when there is an active connection 
//                              specified in the Connection parameter. Otherwise, the protocol will 
//                              be determined automatically when establishing connection.
//   * MessageID - String - (return parameter) ID of the sent email on SMTP server.
//   * MessageIDIMAPSend - String - (return parameter) ID of the sent email on IMAP server.
//                                         
//   * WrongRecipients - Map - (return parameter) list of addresses that sending was failed to.
//                                          See return value of method InternetMail.Send() in Syntax Assistant.
//
//  DeleteConnection - InternetMail - obsolete, see parameter SendingParameters.Connection.
//  DeleteMailProtocol - String - obsolete, see parameter SendingParameters.MailProtocol.
//
// Returns:
//  String - a sent message ID.
//
Function SendEmailMessage(Val Account, Val SendOptions,
	Val DeleteConnection = Undefined, DeleteMailProtocol = "") Export
	
	If DeleteConnection <> Undefined Then
		SendOptions.Insert("Connection", DeleteConnection);
	EndIf;
	
	If Not IsBlankString(DeleteMailProtocol) Then
		SendOptions.Insert("MailProtocol", DeleteMailProtocol);
	EndIf;
	
	If TypeOf(Account) <> Type("CatalogRef.EmailAccounts")
		Or NOT ValueIsFilled(Account) Then
		Raise NStr("ru = 'Учетная запись не заполнена или заполнена неправильно.'; en = 'The account is not filled or is filled with invalid data.'; pl = 'Konto nie jest wypełnione lub zostało wypełnione nieprawidłowo.';de = 'Das Konto ist nicht ausgefüllt oder nicht korrekt ausgefüllt.';ro = 'Contul nu este completat sau este completat incorect.';tr = 'Hesap yanlış dolduruldu veya doldurulmadı.'; es_ES = 'Cuenta no está rellenada o está rellenada de forma incorrecta.'");
	EndIf;
	
	If SendOptions = Undefined Then
		Raise NStr("ru = 'Не заданы параметры отправки.'; en = 'The mail sending parameters are not specified.'; pl = 'Nie określono parametrów wysyłki.';de = 'Sendeparameter sind nicht angegeben.';ro = 'Parametrii de trimitere nu sunt specificați.';tr = 'Gönderme parametreleri belirtilmemiş.'; es_ES = 'Parámetros de envío no están especificados.'");
	EndIf;
	
	RecipientType = ?(SendOptions.Property("SendTo"), TypeOf(SendOptions.SendTo), Undefined);
	CcType = ?(SendOptions.Property("Cc"), TypeOf(SendOptions.Cc), Undefined);
	BCC = CommonClientServer.StructureProperty(SendOptions, "BCC");
	If BCC = Undefined Then
		BCC = CommonClientServer.StructureProperty(SendOptions, "Bcc");
	EndIf;
	
	If RecipientType = Undefined AND CcType = Undefined AND BCC = Undefined Then
		Raise NStr("ru = 'Не указано ни одного получателя.'; en = 'No recipient is selected.'; pl = 'Nie określono odbiorcy.';de = 'Kein Empfänger ist angegeben.';ro = 'Nu este specificat nici un destinatar.';tr = 'Hiçbir alıcı belirtilmemiş.'; es_ES = 'No hay un destinatario especificado.'");
	EndIf;
	
	If RecipientType = Type("String") Then
		SendOptions.SendTo = CommonClientServer.ParseStringWithEmailAddresses(SendOptions.SendTo);
	ElsIf RecipientType <> Type("Array") Then
		SendOptions.Insert("SendTo", New Array);
	EndIf;
	
	If CcType = Type("String") Then
		SendOptions.Cc = CommonClientServer.ParseStringWithEmailAddresses(SendOptions.Cc);
	ElsIf CcType <> Type("Array") Then
		SendOptions.Insert("Cc", New Array);
	EndIf;
	
	If TypeOf(BCC) = Type("String") Then
		SendOptions.BCC = CommonClientServer.ParseStringWithEmailAddresses(BCC);
	ElsIf TypeOf(BCC) <> Type("Array") Then
		SendOptions.Insert("BCC", New Array);
	EndIf;
	
	If SendOptions.Property("ReplyToAddress") AND TypeOf(SendOptions.ReplyToAddress) = Type("String") Then
		SendOptions.ReplyToAddress = CommonClientServer.ParseStringWithEmailAddresses(SendOptions.ReplyToAddress);
	EndIf;
	
	EmailOperationsInternal.SendMessage(Account, SendOptions);
	EmailOverridable.AfterEmailSending(SendOptions);
	
	If SendOptions.WrongRecipients.Count() > 0 Then
		ErrorText = NStr("ru = 'Следующие почтовые адреса не были приняты почтовым сервером:'; en = 'The following email addresses were declined by mail server:'; pl = 'Następujące adresy e-mail nie zostały przyjęte przez serwer pocztowy:';de = 'Die folgenden E-Mail-Adressen wurden vom Mailserver nicht akzeptiert:';ro = 'Următoarele adrese de e-mail nu au fost acceptate de serverul poștei:';tr = 'Posta sunucusu aşağıdaki posta adreslerini kabul etmedi;'; es_ES = 'Las direcciones del correo electrónico siguientes no han sido aceptadas por el servidor de correo:'");
		For Each WrongRecipient In SendOptions.WrongRecipients Do
			ErrorText = ErrorText + Chars.LF + StringFunctionsClientServer.SubstituteParametersToString("%1: %2",
				WrongRecipient.Key, WrongRecipient.Value);
		EndDo;
		Raise ErrorText;
	EndIf;
	
	Return SendOptions.MessageID;
	
EndFunction

// Loads messages from email server for the specified account.
// Before loading, checks account filling for validity.
// The function might throw an exception which must be handled.
//
// Parameters:
//   Account - CatalogRef.EmailAccounts - email account.
//
//   ImportParameters - Structure - with the following properties:
//     * Columns - Array - array of strings of column names. The column names must match the fields 
//                          of object
//                          InternetMailMessage.
//     * TestMode - Boolean - used to check server connection.
//     * GetHeaders - Boolean - if True, the returned set only includes message headers.
//                                       
//     * HeadersIDs - Array - headers or IDs of the messages whose full texts are to be retrieved.
//                                    
//     * CastMessagesToType - Boolean - return a set of received email messages as a value table 
//                                    with simple types. Default value is True.
//
// Returns:
//   MessageSet - ValueTable, Boolean - list of emails with the following columns:
//                 Importance, Attachments**, SentDate, ReceivedDate, Title, SenderName,
//                 ID, Cc, Return address, Sender, Recipients, Size, Texts,
//                 Encoding, NonASCIISymbolsEncodingMode, Partial is filled in if the Status is True.
//                 
//
//                 In test mode, True is returned.
//
//                 ** Note. If any of the attachments are email messages,
//                 they are not returned but their attachments, binary data and texts, are 
//                 recursively returned as binary data.
//
Function DownloadEmailMessages(Val Account, Val ImportParameters = Undefined) Export
	
	UseForReceiving = Common.ObjectAttributeValue(Account, "UseForReceiving");
	If NOT UseForReceiving Then
		Raise NStr("ru = 'Учетная запись не предназначена для получения сообщений.'; en = 'The account not intended to receive messages.'; pl = 'Konto nie jest przeznaczone do odbierania wiadomości.';de = 'Das Konto ist nicht für den Empfang von Nachrichten vorgesehen.';ro = 'Contul nu este destinat primirii mesajelor.';tr = 'Hesap mesaj almak için uygun değildir.'; es_ES = 'Cuenta no está destinada para recibir mensajes.'");
	EndIf;
	
	If ImportParameters = Undefined Then
		ImportParameters = New Structure;
	EndIf;
	
	Result = EmailOperationsInternal.DownloadMessages(Account, ImportParameters);
	Return Result;
	
EndFunction

// Get available email accounts.
//
//  Parameters:
//   ForSending - Boolean - choose only accounts that are configured to send mail.
//   ForReceiving - Boolean - choose only accounts that are configured to receive mail.
//   IncludingSystemEmailAccount - Boolean - include the system account if it is configured for sending and receiving emails.
//
// Returns:
//  AvailableEmailAccounts - ValueTable - description of accounts:
//   Reference       - CatalogRef.EmailAccounts - account.
//   Description - String - an account description.
//   Address        - String - an email address.
//
Function AvailableEmailAccounts(Val ForSending = Undefined,
										Val ForReceiving  = Undefined,
										Val IncludingSystemEmailAccount = True) Export
	
	If Not AccessRight("Read", Metadata.Catalogs.EmailAccounts) Then
		Return New ValueTable;
	EndIf;
	
	QueryText = 
	"SELECT ALLOWED
	|	EmailAccounts.Ref AS Ref,
	|	EmailAccounts.Description AS Description,
	|	EmailAccounts.EmailAddress AS Address,
	|	CASE
	|		WHEN EmailAccounts.Ref = VALUE(Catalog.EmailAccounts.SystemEmailAccount)
	|			THEN 0
	|		ELSE 1
	|	END AS Priority
	|FROM
	|	Catalog.EmailAccounts AS EmailAccounts
	|WHERE
	|	EmailAccounts.DeletionMark = FALSE
	|	AND CASE
	|			WHEN &ForSending = UNDEFINED
	|				THEN TRUE
	|			ELSE EmailAccounts.UseForSending = &ForSending
	|		END
	|	AND CASE
	|			WHEN &ForReceiving = UNDEFINED
	|				THEN TRUE
	|			ELSE EmailAccounts.UseForReceiving = &ForReceiving
	|		END
	|	AND CASE
	|			WHEN &IncludeSystemEmailAccount
	|				THEN TRUE
	|			ELSE EmailAccounts.Ref <> VALUE(Catalog.EmailAccounts.SystemEmailAccount)
	|		END
	|	AND EmailAccounts.EmailAddress <> """"
	|	AND CASE
	|			WHEN EmailAccounts.UseForReceiving
	|				THEN EmailAccounts.IncomingMailServer <> """"
	|			ELSE TRUE
	|		END
	|	AND CASE
	|			WHEN EmailAccounts.UseForSending
	|				THEN EmailAccounts.OutgoingMailServer <> """"
	|			ELSE TRUE
	|		END
	|	AND (EmailAccounts.AccountOwner = VALUE(Catalog.Users.EmptyRef)
	|			OR EmailAccounts.AccountOwner = &CurrentUser)
	|
	|ORDER BY
	|	Priority,
	|	Description";
	
	Query = New Query;
	Query.Text = QueryText;
	Query.Parameters.Insert("ForSending", ForSending);
	Query.Parameters.Insert("ForReceiving", ForReceiving);
	Query.Parameters.Insert("IncludeSystemEmailAccount", IncludingSystemEmailAccount);
	Query.Parameters.Insert("CurrentUser", Users.CurrentUser());
	
	Return Query.Execute().Unload();
	
EndFunction

// Gets the reference to the account by the account purpose kind.
//
// Returns:
//  Account- CatalogRef.EmailAccounts  - reference to account description.
//                  
//
Function SystemAccount() Export
	
	Return Catalogs.EmailAccounts.SystemEmailAccount;
	
EndFunction

// Checks that the system account is available (can be used).
//
// Returns:
//  Boolean - True if the account is available.
//
Function CheckSystemAccountAvailable() Export
	
	Return EmailOperationsInternal.CheckSystemAccountAvailable();
	
EndFunction

// Returns True if at least one configured email account is available, or user has sufficient access 
// rights to configure the account.
//
// Returns:
//  Boolean - True if the account is available.
//
Function CanSendEmails() Export
	
	If AccessRight("Update", Metadata.Catalogs.EmailAccounts) Then
		Return True;
	EndIf;
	
	If Not AccessRight("Read", Metadata.Catalogs.EmailAccounts) Then
		Return False;
	EndIf;
		
	QueryText = 
	"SELECT ALLOWED TOP 1
	|	1 AS Count
	|FROM
	|	Catalog.EmailAccounts AS EmailAccounts
	|WHERE
	|	NOT EmailAccounts.DeletionMark
	|	AND EmailAccounts.UseForSending
	|	AND EmailAccounts.EmailAddress <> """"
	|	AND EmailAccounts.OutgoingMailServer <> """"
	|	AND (EmailAccounts.AccountOwner = VALUE(Catalog.Users.EmptyRef)
	|			OR EmailAccounts.AccountOwner = &CurrentUser)";
	
	Query = New Query(QueryText);
	Query.Parameters.Insert("CurrentUser", Users.CurrentUser());
	Selection = Query.Execute().Select();
	
	Return Selection.Next();
	
EndFunction

// Checks whether the account is configured for sending or receiving email.
//
// Parameters:
//  Account - Catalog.EmailAccounts - account to be checked.
//  ForSending  - Boolean - check parameters used to send email.
//  ForReceiving - Boolean - check parameters used to receive email.
// 
// Returns:
//  Boolean - True if the account is configured.
//
Function AccountSetUp(Account, Val ForSending = Undefined, Val ForReceiving = Undefined) Export
	
	Parameters = Common.ObjectAttributesValues(Account, "EmailAddress,IncomingMailServer,OutgoingMailServer,UseForReceiving,UseForSending,ProtocolForIncomingMail");
	If ForSending = Undefined Then
		ForSending = Parameters.UseForSending;
	EndIf;
	If ForReceiving = Undefined Then
		ForReceiving = Parameters.UseForReceiving;
	EndIf;
	
	Return Not (IsBlankString(Parameters.EmailAddress) 
		Or ForReceiving AND IsBlankString(Parameters.IncomingMailServer)
		Or ForSending AND (IsBlankString(Parameters.OutgoingMailServer)
			Or (Parameters.ProtocolForIncomingMail = "IMAP" AND IsBlankString(Parameters.IncomingMailServer))));
		
EndFunction

// Checks email account settings.
//
// Parameters:
//  Account     - CatalogRef.EmailAccounts - account to be checked.
//  ErrorMessage - String - an error message text or a blank string if no errors occurred.
//  AdditionalMessage - String - messages containg information on the checks made for the account.
//
Procedure CheckSendReceiveEmailAvailability(Account, ErrorMessage, AdditionalMessage) Export
	
	EmailOperationsInternal.CheckSendReceiveEmailAvailability(Account, 
		ErrorMessage, AdditionalMessage);
	
EndProcedure

#EndRegion
