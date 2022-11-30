
// Функция обработчик "ОпределитьАдресПолучателя" 
//
Function DetermineRecipientAddress(Object) Export
	
	Query = New Query;
	
	Query.SetParameter("User", Object);
	Query.SetParameter("Kind"         , Catalogs.ContactInformationKinds.UserEmail);
	
	Query.Text =
	"SELECT
	|	UsersContactInformation.Presentation
	|FROM
	|	Catalog.Users.ContactInformation AS UsersContactInformation
	|WHERE
	|	UsersContactInformation.Ref = &User
	|	AND UsersContactInformation.Kind = &Kind";
	
	Address = "";
	QueryTable = Query.Execute().SELECT();
	If QueryTable.Next() Then 
		Address = QueryTable.Presentation;
	EndIf;
	
	Return Address;
	
EndFunction

// Процедура обработчик "ОтправитьПисьмо" 
//
Procedure SendMail(Cancel, Account, MessageText, Recipient, MessageTopic) Export
	
	If ValueIsFilled(TrimAll(Account.fmTitleColor)) Then
		MessageText = Account.fmTitleColor + Chars.LF + Chars.LF + MessageText;
	EndIf;	
	
	If ValueIsFilled(TrimAll(Account.fmSignText)) Then
		MessageText = MessageText + Chars.LF + Chars.LF + Account.fmSignText;
	EndIf;
	
	MailParameters = New Structure();
	MailParameters.Insert("Subject", MessageTopic);
	MailParameters.Insert("Body", MessageText);
	
	RecipientAddress = DetermineRecipientAddress(Recipient);
	If ValueIsFilled(RecipientAddress) Then
		_To = New Array();
		_To.Add(New Structure("Address, Presentation", RecipientAddress, TrimAll(Recipient)));
		MailParameters.Insert("_To", _To);
	Else
		CommonClientServer.MessageToUser(StrTemplate(NStr("en='For user ""%1"", the email is not specified in the contact information!';ru='Для пользователя ""%1"" не указан в контактной информации адрес электронной почты!'"), Recipient), , , , , Cancel);
		Return;
	EndIf;
	
	BlindCopies = New Array();
	BlindCopies.Add(New Structure("Address, Presentation", Account.Email, ""));
	MailParameters.Insert("BlindCopies", BlindCopies);
	
	SendEmailMessage(Account, MailParameters);
	
EndProcedure

// Функция для отправки сообщений. Проверяет корректность заполнения учетной
// записи и вызывает функцию, реализующую механику отправки.
//
// см. параметры функции ОтправитьСообщение
// 
// Примечание: параметр ПараметрыПисьма.Вложения может содержать вместо двоичных данных адреса во
//   временном хранилище, по которым хранятся эти данные.
//
Function SendEmailMessage(VAL Account,
	                               VAL MailParameters,
	                               VAL JOIN = Undefined) Export
	
	If TypeOf(Account) <> Type("CatalogRef.EmailAccounts")
	   OR NOT ValueIsFilled(Account) Then
		Raise NStr("en='The account is unfilled or filled in incorrectly.';ru='Учетная запись не заполнена или заполнена неправильно.'");
	EndIf;
	
	If MailParameters = Undefined Then
		Raise NStr("en='The sending options are not specified.';ru='Не заданы параметры отправки.'");
	EndIf;
	
	ToValueType = ?(MailParameters.Property("_To"), TypeOf(MailParameters._To), Undefined);
	CopyValueType = ?(MailParameters.Property("Copies"), TypeOf(MailParameters.Copies), Undefined);
	BlindCopiesValueTypes = ?(MailParameters.Property("BlindCopies"), TypeOf(MailParameters.BlindCopies), Undefined);
	
	If ToValueType = Undefined AND CopyValueType = Undefined AND BlindCopiesValueTypes = Undefined Then
		Raise NStr("en='No recipient is specified.';ru='Не указано ни одного получателя.'");
	EndIf;
	
	If ToValueType = Type("String") Then
		MailParameters._To = fmCommonUseClientServer.SplitStringWithEmailAddresses(MailParameters._To);
	ElsIf ToValueType <> Type("Array") Then
		MailParameters.Insert("_To", New Array);
	EndIf;
	
	If CopyValueType = Type("String") Then
		MailParameters.Copies = fmCommonUseClientServer.SplitStringWithEmailAddresses(MailParameters.Copies);
	ElsIf CopyValueType <> Type("Array") Then
		MailParameters.Insert("Copies", New Array);
	EndIf;
	
	If BlindCopiesValueTypes = Type("String") Then
		MailParameters.BlindCopies = fmCommonUseClientServer.SplitStringWithEmailAddresses(MailParameters.BlindCopies);
	ElsIf BlindCopiesValueTypes <> Type("Array") Then
		MailParameters.Insert("BlindCopies", New Array);
	EndIf;
	
	If MailParameters.Property("ReplyAddress") AND TypeOf(MailParameters.ReplyAddress) = Type("String") Then
		MailParameters.ReplyAddress = fmCommonUseClientServer.SplitStringWithEmailAddresses(MailParameters.ReplyAddress);
	EndIf;
	
	Return SendMessage(Account, MailParameters,JOIN);
	
EndFunction

Function SendMessage(VAL Account,
	                       VAL MailParameters,
	                       JOIN = Undefined) Export
	
	// Объявление переменных перед первым использованием в качестве
	// параметра метода Свойство структуры ПараметрыПисьма.
	// Переменные содержат значения переданных в функцию параметров.
	Var _To, Subject, Body, Attachments, ReplyAddress, TextType, Copies, BlindCopies, Password;
	
	If NOT MailParameters.Property("Subject", Subject) Then
		Subject = "";
	EndIf;
	
	If NOT MailParameters.Property("Body", Body) Then
		Body = "";
	EndIf;
	
	_To = MailParameters._To;
	
	If TypeOf(_To) = Type("String") Then
		_To = fmCommonUseClientServer.SplitStringWithEmailAddresses(_To);
	EndIf;
	
	Mail = New InternetMailMessage;
	Mail.Subject = Subject;
	
	// формируем адрес получателя	
	For Each RecipientEmail In _To Do
		Recipient = Mail.To.Add(RecipientEmail.Address);
		Recipient.DisplayName = RecipientEmail.Presentation;
	EndDo;
	
	If MailParameters.Property("Copies", Copies) Then
		// формируем адрес получателя поля Копии
		For Each RecipientMailAddressCopies In Copies Do
			Recipient = Mail.Copies.Add(RecipientMailAddressCopies.Address);
			Recipient.DisplayName = RecipientMailAddressCopies.Presentation;
		EndDo;
	EndIf;
	
	If MailParameters.Property("BlindCopies", BlindCopies) Then
		// формируем адрес получателя поля Копии
		For Each RecipientMailAddressBlindCopies In BlindCopies Do
			Recipient = Mail.BlindCopies.Add(RecipientMailAddressBlindCopies.Address);
			Recipient.DisplayName = RecipientMailAddressBlindCopies.Presentation;
		EndDo;
	EndIf;
	
	// формируем адрес ответа, если необходимо
	If MailParameters.Property("ReplyAddress", ReplyAddress) Then
		For Each ReplyMailAddress In ReplyAddress Do
			MailReturnAddress = Mail.ReturnAddress.Add(ReplyMailAddress.Address);
			MailReturnAddress.DisplayName = ReplyMailAddress.Presentation;
		EndDo;
	EndIf;
	
	
	// получение реквизитов отправителя
	SenderAttributes = fmCommonUseServerCall.ObjectAttributeValues(Account, "UserName, EmailAddress");
	
	// добавляем к письму имя отправителя
	Mail.SenderName              = SenderAttributes.UserName;
	Mail.From.DisplayName = SenderAttributes.UserName;
	Mail.From.Address           = SenderAttributes.EmailAddress;
	
	// добавляем вложения к письму
	If Attachments <> Undefined Then
		For Each ItemAttachment In Attachments Do
			If TypeOf(ItemAttachment.Value) = Type("Structure") Then
				NewAttachment = Mail.Attachments.Add(ItemAttachment.Value.BinaryData, ItemAttachment.Key);
				NewAttachment.ID = ItemAttachment.Value.ID;
			Else
				Mail.Attachments.Add(ItemAttachment.Value, ItemAttachment.Key);
			EndIf;
		EndDo;
	EndIf;

	// Установим строку с идентификаторами оснований
	If MailParameters.Property("BasisIDs") Then
		Mail.SetField("References", MailParameters.BasisIDs);
	EndIf;
	
	// добавляем текст
	Text = Mail.Texts.Add(Body);
	If MailParameters.Property("TextType", TextType) Then
		If TypeOf(TextType) = Type("String") Then
			If      TextType = "HTML" Then
				Text.TextType = InternetMailTextType.HTML;
			ElsIf TextType = "RichText" Then
				Text.TextType = InternetMailTextType.RichText;
			Else
				Text.TextType = InternetMailTextType.PlainText;
			EndIf;
		ElsIf TypeOf(TextType) = Type("EnumRef.EmailTextTypes") Then
			If      TextType = Enums.EmailTextTypes.HTML
				  OR TextType = Enums.EmailTextTypes.HTMLWithPictures Then
				Text.TextType = InternetMailTextType.HTML;
			ElsIf TextType = Enums.EmailTextTypes.RichText Then
				Text.TextType = InternetMailTextType.RichText;
			Else
				Text.TextType = InternetMailTextType.PlainText;
			EndIf;
		Else
			Text.TextType = TextType;
		EndIf;
	Else
		Text.TextType = InternetMailTextType.PlainText;
	EndIf;

	// Зададим важность
	Importance = Undefined;
	If MailParameters.Property("Importance", Importance) Then
		Mail.Importance = Importance;
	EndIf;
	
	// Зададим кодировку
	Encoding = Undefined;
	If MailParameters.Property("Encoding", Encoding) Then
		Mail.Encoding = Encoding;
	EndIf;

	If MailParameters.Property("DoProcessTexts") AND NOT MailParameters.DoProcessTexts Then
		ProcessMessageText =  InternetMailTextProcessing.Process;
	Else
		ProcessMessageText =  InternetMailTextProcessing.DontProcess;
	EndIf;
	
	If MailParameters.Property("RequestDeliveryReceipt") Then
		Mail.RequestDeliveryReceipt = MailParameters.RequestDeliveryReceipt;
		Mail.DeliveryReceiptAddresses.Add(SenderAttributes.Email);
	EndIf;
	
	If MailParameters.Property("RequestReadReceipt") Then
		Mail.RequestReadReceipt = MailParameters.RequestReadReceipt;
		Mail.ReadReceiptAddresses.Add(SenderAttributes.Email);
	EndIf;
	
	If TypeOf(JOIN) <> Type("InternetMail") Then
		Profile = EmailOperationsInternal.InternetMailProfile(Account, False);
		JOIN = New InternetMail;
		JOIN.Logon(Profile);
	EndIf;

	JOIN.Send(Mail, ProcessMessageText);
	
	Return Mail.MessageID;
	
EndFunction

// Отправляет письмо через регистр сведений Оповещения.
// Из регистра письма отправляются фоновым заданием.
//
Procedure SendMailViaNotification(Recipient, Subject, Content, ASubject=Undefined) Export
	
	// Создадим запись в регистре сведений оповещения.
	RecordManager = InformationRegisters.fmNotification.CreateRecordManager();
	RecordManager.Recipient = Recipient;
	RecordManager.NotificationDate = CurrentDate();
	RecordManager.Channel = Enums.fmNotificationChannels.Email;
	// Ссылка есть не всегда, например если источник НаборЗаписей.
	Try
		RecordManager.Subject = ASubject;
	Except
	EndTry;
	// Ресурсы.
	
	RecordManager.Subject = Subject;
	RecordManager.Content = Content;
	RecordManager.Write();
	
EndProcedure

// Процедура отправки оповещений электронной почтой
//
Procedure NotificationSendingByEmail() Export
	
	// Обработка непосредственно записей регистра Оповещений с последующим созданием писем
	Query = New Query;
	Query.SetParameter("NotificationDate",CurrentDate());
	Query.Text = "SELECT
	               |	fmNotification.Recipient,
	               |	fmNotification.Subject,
	               |	fmNotification.NotificationDate AS NotificationDate,
	               |	fmNotification.Channel AS Channel,
	               |	fmNotification.UpdateDate,
	               |	fmNotification.Content,
	               |	fmNotification.NotificationPeriod,
	               |	fmNotification.Periodicity,
	               |	fmNotification.Subject
	               |FROM
	               |	InformationRegister.fmNotification AS fmNotification
	               |WHERE
	               |	fmNotification.NotificationDate <= &NotificationDate
	               |	AND fmNotification.Channel = Value(Enum.fmNotificationChannels.Email)
	               |
	               |ORDER BY
	               |	Channel,
	               |	NotificationDate";
	
	Selection = Query.Execute().SELECT();
	
	WriteLogEvent("Scheduled Notification ON E-Mail",
			EventLogLevel.Information, , ,
			NStr("en='The scheduled e-mail notification has been started';ru='Начато регламентное оповещение по E-Mail'"));
	
	While Selection.Next() Do
		
		// получим адрес ЭП получателя
		If NOT ValueIsFilled(Selection.Recipient) Then
			Continue;
		Else
			
			Recipient = DetermineRecipientAddress(Selection.Recipient);
			MailSubject = Selection.Subject;
			LetterText = Selection.Content;
			AccountForSending = Catalogs.EmailAccounts.fmNotificationSendingAccount;
			
		EndIf;
		
		// если его нет то ту-ту
		If NOT ValueIsFilled(Recipient) Then
			Continue;
		EndIf;
		
		Addressees = New Array;
		Addressees.Add(New Structure("Address, Presentation", Recipient, Recipient));
		
		// заполним параметры письма и отправим его
		MailParameters = New Structure;
		MailParameters.Insert("_To", Addressees);
		MailParameters.Insert("Subject",      MailSubject);
		MailParameters.Insert("Body",      LetterText);
		MailParameters.Insert("Encoding", "utf-8");
		
		Try
			SendEmailMessage(AccountForSending, MailParameters);
			
			//Если удачно все отправили, то удаляем запись регистра оповещений
			RecordManager = InformationRegisters.fmNotification.CreateRecordManager();
			RecordManager.Recipient		= Selection.Recipient;
			RecordManager.Subject			= Selection.Subject;
			RecordManager.NotificationDate	= Selection.NotificationDate;
			RecordManager.Channel			= Selection.Channel;
			RecordManager.Read();
			If RecordManager.Selected() Then
				RecordManager.Delete();
			EndIf;
		Except
			
			WriteLogEvent(NStr("en='Scheduled e-mail notification';ru='Регламентное оповещение по E-Mail'"),
				EventLogLevel.Error, , ,
				DetailErrorDescription(ErrorInfo()));
			
		EndTry;
		
	EndDo;
			
	WriteLogEvent(NStr("en='Scheduled e-mail notification';ru='Регламентное оповещение по E-Mail'"), 
		EventLogLevel.Information, , ,
		NStr("en='The scheduled e-mail notification is completed';ru='Закончено регламентное оповещение по E-Mail'"));
			
	
EndProcedure
