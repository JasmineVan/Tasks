///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Variables
Var ErrorMessageString Export;
Var ErrorMessageStringEL Export;

Var ErrorsMessages; // Map that contains predefined error messages.
Var ObjectName;		// The metadata object name

Var TempExchangeMessageFile; // temporary exchange message file for importing and exporting data.
Var TempExchangeMessagesDirectory; // Temporary exchange message directory.

Var MessageSubject;		// message subject pattern
Var SimpleBody;	// Message body text with an attached XML file.
Var CompressedBody;		// Message body text with an attached compressed file.
Var BatchBody;	// Message body text with an attached compressed file that contains a file set.
Var EmailOperationsCommonModule;

Var DirectoryID;
#EndRegion

#Region Private

////////////////////////////////////////////////////////////////////////////////
// Internal export procedures and functions.

// Creates a temporary directory in the temporary file directory of the operating system user.
//
// Parameters:
//  No.
// 
//  Returns:
//    Boolean - True if the function is executed successfully, False if an error occurred.
// 
Function ExecuteActionsBeforeProcessMessage() Export
	
	InitMessages();
	
	DirectoryID = Undefined;
	
	Return CreateTempExchangeMessagesDirectory();
	
EndFunction

// Sends the exchange message to the specified resource from the temporary exchange message directory.
//
// Parameters:
//  No.
// 
//  Returns:
//    Boolean - True if the function is executed successfully, False if an error occurred.
// 
Function SendMessage() Export
	
	InitMessages();
	
	Try
		Result = SendExchangeMessage();
	Except
		Result = False;
	EndTry;
	
	Return Result;
	
EndFunction

// Gets an exchange message from the specified resource and puts it in the temporary exchange message directory.
//
// Parameters:
//  ExistenceCheck - Boolean - True if it is necessary to check whether exchange messages exist without their import.
// 
//  Returns:
//    Boolean - True if the function is executed successfully, False if an error occurred.
// 
Function GetMessage(ExistenceCheck = False) Export
	
	InitMessages();
	
	Try
		Result = GetExchangeMessage(ExistenceCheck);
	Except
		Result = False;
	EndTry;
	
	Return Result;
	
EndFunction

// Deletes the temporary exchange message directory after performing data import or export.
//
// Parameters:
//  No.
// 
//  Returns:
//    Boolean - True
//
Function ExecuteActionsAfterProcessMessage() Export
	
	InitMessages();
	
	DeleteTempExchangeMessagesDirectory();
	
	Return True;
	
EndFunction

// Initializes data processor properties with initial values and constants.
//
// Parameters:
//  No.
// 
Procedure Initializing() Export
	
	InitMessages();
	
	MessageSubject = "Exchange message (%1)"; // this string does not require localization.
	MessageSubject = StringFunctionsClientServer.SubstituteParametersToString(MessageSubject, MessageFileNamePattern);
	
	SimpleBody	= NStr("ru = 'Сообщение обмена данными'; en = 'Data exchange message'; pl = 'Wiadomość wymiany danych';de = 'Datenaustausch Nachricht';ro = 'Mesaj de schimb de date';tr = 'Veri değişim mesajı'; es_ES = 'Mensaje de intercambio de datos'");
	CompressedBody	= NStr("ru = 'Сжатое сообщение обмена данными'; en = 'Compressed data exchange message'; pl = 'Skompresowana wiadomość wymiany danych';de = 'Komprimierte Datenaustausch Nachricht';ro = 'Mesaj de schimb de date comprimat';tr = 'Sıkıştırılmış veri alışverişi mesajı'; es_ES = 'Mensaje comprimido de intercambio de datos'");
	BatchBody	= NStr("ru = 'Пакетное сообщение обмена данными'; en = 'Batch data exchange message'; pl = 'Pakietowa wiadomość wymiany danych';de = 'Charge-Datenaustausch-Nachricht';ro = 'Mesaj pachet al schimbului de date';tr = 'Veri alışverişi paket mesajı'; es_ES = 'Mensaje de paquete del intercambio de datos'");
	
EndProcedure

// Checks whether the connection to the specified resource can be established.
//
// Parameters:
//  No.
// 
//  Returns:
//    Boolean - True if connection can be established. Otherwise, False.
//
Function ConnectionIsSet() Export
	
	InitMessages();
	
	If NOT ValueIsFilled(EMAILUserAccount) Then
		GetErrorMessage(101);
		Return False;
	EndIf;
	
	Return True;
	
EndFunction

///////////////////////////////////////////////////////////////////////////////
// Functions for retrieving properties.

// Time exchange message file changed.
//
// Returns:
//  String - the exchange message file date.
//
Function ExchangeMessageFileDate() Export
	
	Result = Undefined;
	
	If TypeOf(TempExchangeMessageFile) = Type("File") Then
		
		If TempExchangeMessageFile.Exist() Then
			
			Result = TempExchangeMessageFile.GetModificationTime();
			
		EndIf;
		
	EndIf;
	
	Return Result;
	
EndFunction

// Full exchange message file name.
//
// Returns:
//  String - a full name of the exchange message file.
//
Function ExchangeMessageFileName() Export
	
	Name = "";
	
	If TypeOf(TempExchangeMessageFile) = Type("File") Then
		
		Name = TempExchangeMessageFile.FullName;
		
	EndIf;
	
	Return Name;
	
EndFunction

// Full exchange message directory name.
//
// Returns:
//  String - a full name of the exchange message directory.
//
Function ExchangeMessageCatalogName() Export
	
	Name = "";
	
	If TypeOf(TempExchangeMessagesDirectory) = Type("File") Then
		
		Name = TempExchangeMessagesDirectory.FullName;
		
	EndIf;
	
	Return Name;
	
EndFunction

///////////////////////////////////////////////////////////////////////////////
// Local internal procedures and functions.

Function CreateTempExchangeMessagesDirectory()
	
	// Creating the temporary exchange message directory.
	Try
		TempDirectoryName = DataExchangeServer.CreateTempExchangeMessagesDirectory(DirectoryID);
	Except
		GetErrorMessage(4);
		SupplementErrorMessage(BriefErrorDescription(ErrorInfo()));
		Return False;
	EndTry;
	
	TempExchangeMessagesDirectory = New File(TempDirectoryName);
	
	MessageFileName = CommonClientServer.GetFullFileName(ExchangeMessageCatalogName(), MessageFileNamePattern + ".xml");
	
	TempExchangeMessageFile = New File(MessageFileName);
	
	Return True;
EndFunction

Function DeleteTempExchangeMessagesDirectory()
	
	Try
		If Not IsBlankString(ExchangeMessageCatalogName()) Then
			DeleteFiles(ExchangeMessageCatalogName());
			TempExchangeMessagesDirectory = Undefined;
		EndIf;
		
		If Not DirectoryID = Undefined Then
			DataExchangeServer.GetFileFromStorage(DirectoryID);
			DirectoryID = Undefined;
		EndIf;
	Except
		Return False;
	EndTry;
	
	Return True;
	
EndFunction

Function SendExchangeMessage()
	
	Result = True;
	
	Extension = ?(CompressOutgoingMessageFile(), ".zip", ".xml");
	
	OutgoingMessageFileName = MessageFileNamePattern + Extension;
	
	If CompressOutgoingMessageFile() Then
		
		// Getting the temporary archive file name.
		ArchiveTempFileName = CommonClientServer.GetFullFileName(ExchangeMessageCatalogName(), MessageFileNamePattern + ".zip");
		
		Try
			
			Archiver = New ZipFileWriter(ArchiveTempFileName, ArchivePasswordExchangeMessages, NStr("ru = 'Файл сообщения обмена'; en = 'Exchange message file'; pl = 'Plik komunikatów wymiany';de = 'Austausch-Nachrichtendatei';ro = 'fișier mesaje de schimb';tr = 'Alışveriş mesajı dosyası'; es_ES = 'Archivo de mensaje de intercambio'"));
			Archiver.Add(ExchangeMessageFileName());
			Archiver.Write();
			
		Except
			
			Result = False;
			GetErrorMessage(3);
			SupplementErrorMessage(BriefErrorDescription(ErrorInfo()));
			
		EndTry;
		
		Archiver = Undefined;
		
		If Result Then
			
			// Checking that the exchange message size does not exceed the maximum allowed size.
			If DataExchangeServer.ExchangeMessageSizeExceedsAllowed(ArchiveTempFileName, MaxMessageSize()) Then
				GetErrorMessage(108);
				Result = False;
			EndIf;
			
		EndIf;
		
		If Result Then
			
			Result = SendMessagebyEmail(
									CompressedBody,
									OutgoingMessageFileName,
									ArchiveTempFileName);
			
		EndIf;
		
	Else
		
		If Result Then
			
			// Checking that the exchange message size does not exceed the maximum allowed size.
			If DataExchangeServer.ExchangeMessageSizeExceedsAllowed(ExchangeMessageFileName(), MaxMessageSize()) Then
				GetErrorMessage(108);
				Result = False;
			EndIf;
			
		EndIf;
		
		If Result Then
			
			Result = SendMessagebyEmail(
									SimpleBody,
									OutgoingMessageFileName,
									ExchangeMessageFileName());
			
		EndIf;
		
	EndIf;
	
	Return Result;
	
EndFunction

Function GetExchangeMessage(ExistenceCheck)
	
	ExchangeMessagesTable = New ValueTable;
	ExchangeMessagesTable.Columns.Add("ID", New TypeDescription("Array"));
	ExchangeMessagesTable.Columns.Add("PostingDate", New TypeDescription("Date"));
	
	ColumnsArray = New Array;
	
	ColumnsArray.Add("ID");
	ColumnsArray.Add("PostingDate");
	ColumnsArray.Add("Subject");
	
	ImportParameters = New Structure;
	ImportParameters.Insert("Columns", ColumnsArray);
	ImportParameters.Insert("GetHeaders", True);
	
	Try
		MessageSet = EmailOperationsCommonModule.DownloadEmailMessages(EMAILUserAccount, ImportParameters);
	Except
		ErrorText = DetailErrorDescription(ErrorInfo());
		GetErrorMessage(103);
		SupplementErrorMessage(ErrorText);
		Return False;
	EndTry;
	
	SearchSubjectsSubstring = Upper(StrReplace(TrimAll(MessageFileNamePattern), "Message_", ""));
	
	For Each EmailMessage In MessageSet Do
		
		EmailMessageSubject = TrimAll(EmailMessage.Subject);
		EmailMessageSubject = StrReplace(EmailMessageSubject, Chars.Tab, "");
		
		If Upper(EmailMessageSubject) <> Upper(TrimAll(MessageSubject)) Then
			// The message name can be in the format of Message_[prefix]_UID1_UID2 
			If StrFind(Upper(EmailMessageSubject), SearchSubjectsSubstring) = 0 Then
				Continue;
			EndIf;
		EndIf;
		
		NewRow = ExchangeMessagesTable.Add();
		FillPropertyValues(NewRow, EmailMessage);
		
	EndDo;
	
	If ExchangeMessagesTable.Count() = 0 Then
		
		If Not ExistenceCheck Then
			GetErrorMessage(104);
		
			MessageString = NStr("ru = 'Не обнаружены письма с заголовком: ""%1""'; en = 'The messages with %1 header are not found.'; pl = 'Nie znaleziono wiadomości e-mail z tytułem: ""%1""';de = 'E-Mails mit dem Titel ""%1"" werden nicht gefunden';ro = 'Scrisorile cu titlul ""%1"" nu au fost găsite';tr = '""%1"" başlıklı yazılar bulunmadı'; es_ES = 'Correos electrónicos con el título ""%1"" no se han encontrado'");
			MessageString = StringFunctionsClientServer.SubstituteParametersToString(MessageString, MessageSubject);
			SupplementErrorMessage(MessageString);
		EndIf;
		
		Return False;
		
	Else
		
		If ExistenceCheck Then
			Return True;
		EndIf;
		
		ExchangeMessagesTable.Sort("PostingDate Desc");
		
		ColumnsArray = New Array;
		ColumnsArray.Add("Attachments");
		
		ImportParameters = New Structure;
		ImportParameters.Insert("Columns", ColumnsArray);
		ImportParameters.Insert("HeadersIDs", ExchangeMessagesTable[0].ID);
		
		Try
			MessageSet = EmailOperationsCommonModule.DownloadEmailMessages(EMAILUserAccount, ImportParameters);
		Except
			ErrorText = DetailErrorDescription(ErrorInfo());
			GetErrorMessage(105);
			SupplementErrorMessage(ErrorText);
			Return False;
		EndTry;
		
		BinaryData = MessageSet[0].Attachments.Get(MessageFileNamePattern+".zip");
		
		If BinaryData <> Undefined Then
			FilePacked = True;
		Else
			BinaryData = MessageSet[0].Attachments.Get(MessageFileNamePattern+".xml");
			FilePacked = False;
		EndIf;
		
		// The message name can be in the format of Message_[prefix]_UID1_UID2 
		FilePacked = False;
		SearchTemplate = StrReplace(MessageFileNamePattern, "Message_","");
		For Each CurAttachment In MessageSet[0].Attachments Do
			If StrFind(CurAttachment.Key, SearchTemplate) > 0 Then
				BinaryData = CurAttachment.Value;
				If StrEndsWith(CurAttachment.Key,".zip") > 0 Then
					FilePacked = True;
				EndIf;
				// Rewrite the accurate file name template as an attachment name without an extension.
				AttachedFileNameStructure = CommonClientServer.ParseFullFileName(CurAttachment.Key,False);
				MessageFileNamePattern = AttachedFileNameStructure.BaseName;
				Break;
			EndIf;
		EndDo;
			
		If BinaryData = Undefined Then
			GetErrorMessage(109);
			Return False;
		EndIf;
		
		If FilePacked Then
			
			// Getting the temporary archive file name.
			ArchiveTempFileName = CommonClientServer.GetFullFileName(ExchangeMessageCatalogName(), MessageFileNamePattern + ".zip");
			
			Try
				BinaryData.Write(ArchiveTempFileName);
			Except
				ErrorText = DetailErrorDescription(ErrorInfo());
				GetErrorMessage(106);
				SupplementErrorMessage(ErrorText);
				Return False;
			EndTry;
			
			// Unpacking the temporary archive file.
			SuccessfullyUnpacked = DataExchangeServer.UnpackZipFile(ArchiveTempFileName, ExchangeMessageCatalogName(), ArchivePasswordExchangeMessages);
			
			If Not SuccessfullyUnpacked Then
				GetErrorMessage(2);
				Return False;
			EndIf;
			
			// Checking that the message file exists.
			File = New File(ExchangeMessageFileName());
			
			If Not File.Exist() Then
				// The archive name probably does not match name of the file inside.
				MessageFileNameStructure = CommonClientServer.ParseFullFileName(ExchangeMessageFileName(),False);

				If MessageFileNamePattern <> MessageFileNameStructure.BaseName Then
					UnpackedFilesArray = FindFiles(ExchangeMessageCatalogName(), "*.xml", False);
					If UnpackedFilesArray.Count() > 0 Then
						UnpackedFile = UnpackedFilesArray[0];
						MoveFile(UnpackedFile.FullName,ExchangeMessageFileName());
					Else
						GetErrorMessage(5);
						Return False;
					EndIf;
				Else
					GetErrorMessage(5);
					Return False;
				EndIf;
				
			EndIf;
			
		Else
			
			Try
				BinaryData.Write(ExchangeMessageFileName());
			Except
				ErrorText = DetailErrorDescription(ErrorInfo());
				GetErrorMessage(106);
				SupplementErrorMessage(ErrorText);
				Return False;
			EndTry;
			
		EndIf;
		
	EndIf;
	
	Return True;
	
EndFunction

Procedure GetErrorMessage(MessageNumber)
	
	SetErrorMessageString(ErrorsMessages[MessageNumber]);
	
EndProcedure

Procedure SetErrorMessageString(Val Message)
	
	If Message = Undefined Then
		Message = NStr("ru = 'Внутренняя ошибка'; en = 'Internal error'; pl = 'Błąd zewnętrzny';de = 'Interner Fehler';ro = 'Eroare internă';tr = 'Dahili hata'; es_ES = 'Error interno'");
	EndIf;
	
	ErrorMessageString   = Message;
	ErrorMessageStringEL = ObjectName + ": " + Message;
	
EndProcedure

Procedure SupplementErrorMessage(Message)
	
	ErrorMessageStringEL = ErrorMessageStringEL + Chars.LF + Message;
	
EndProcedure

// The overridable function, returns the maximum allowed size of a message to be sent.
// 
// 
Function MaxMessageSize()
	
	Return EMAILMaxMessageSize;
	
EndFunction

///////////////////////////////////////////////////////////////////////////////
// Functions for retrieving properties.

// Retrieves a flag that shows that the outgoing message file is compressed.
// 
Function CompressOutgoingMessageFile()
	
	Return EMAILCompressOutgoingMessageFile;
	
EndFunction

///////////////////////////////////////////////////////////////////////////////
// Initialization

Procedure InitMessages()
	
	ErrorMessageString   = "";
	ErrorMessageStringEL = "";
	
EndProcedure

Procedure ErrorMessageInitialization()
	
	ErrorsMessages = New Map;
	
	// Common error codes
	ErrorsMessages.Insert(001, NStr("ru = 'Не обнаружены сообщения обмена.'; en = 'Exchange messages are not detected.'; pl = 'Nie znaleziono wiadomości wymiany.';de = 'Austausch-E-Mails werden nicht gefunden.';ro = 'Mesajele de schimb nu au fost găsite.';tr = 'Veri alışverişi mesajları bulunamadı.'; es_ES = 'Correos electrónicos de intercambio no se han encontrado.'"));
	ErrorsMessages.Insert(002, NStr("ru = 'Ошибка при распаковке сжатого файла сообщения.'; en = 'Error unpacking the exchange message file.'; pl = 'Podczas rozpakowywania skompresowanego pliku wiadomości wystąpił błąd.';de = 'Beim Entpacken einer komprimierten Nachrichtendatei ist ein Fehler aufgetreten.';ro = 'Eroare la despachetarea fișierului de mesaj comprimat.';tr = 'Sıkıştırılmış mesaj dosyası açılırken bir hata oluştu.'; es_ES = 'Ha ocurrido un error al desembalar un archivo de mensajes comprimido.'"));
	ErrorsMessages.Insert(003, NStr("ru = 'Ошибка при сжатии файла сообщения обмена.'; en = 'Error packing the exchange message file.'; pl = 'Błąd podczas kompresji pliku wiadomości wymiany.';de = 'Beim Komprimieren der Austausch-Nachrichtendatei ist ein Fehler aufgetreten.';ro = 'Eroare la comprimarea fișierului mesajului de schimb.';tr = 'Veri alışverişi mesajı dosyası sıkıştırılırken bir hata oluştu.'; es_ES = 'Ha ocurrido un error al comprimir el archivo de mensajes de intercambio.'"));
	ErrorsMessages.Insert(004, NStr("ru = 'Ошибка при создании временного каталога.'; en = 'An error occurred when creating a temporary directory.'; pl = 'Błąd podczas tworzenia katalogu tymczasowego.';de = 'Beim Erstellen eines temporären Verzeichnisses ist ein Fehler aufgetreten.';ro = 'A apărut o eroare la crearea unui director temporar.';tr = 'Geçici bir dizin oluştururken bir hata oluştu.'; es_ES = 'Ha ocurrido un error al crear un directorio temporal.'"));
	ErrorsMessages.Insert(005, NStr("ru = 'Архив не содержит файл сообщения обмена.'; en = 'The archive does not contain the exchange message file.'; pl = 'Archiwum nie zawiera pliku wiadomości wymiany.';de = 'Das Archiv enthält keine Austausch-Nachrichtendatei.';ro = 'Arhiva nu conține fișierul mesajului de schimb.';tr = 'Arşiv, veri alışveriş mesajı dosyasını içermiyor.'; es_ES = 'Archivo no incluye el archivo de mensajes de intercambio.'"));
	ErrorsMessages.Insert(006, NStr("ru = 'Сообщение обмена не отправлено: превышен допустимый размер сообщения.'; en = 'Exchange message was not sent: the maximum allowed message size is exceeded.'; pl = 'Wiadomość wymiany nie została wysłana: przekroczono dopuszczalny rozmiar wiadomości.';de = 'Austausch-Nachricht wurde nicht gesendet: zulässige Nachrichtengröße überschritten.';ro = 'Mesajul de schimb nu a fost trimis: a fost depășită dimensiunea permisă a mesajului.';tr = 'Alışveriş mesajı gönderilmedi: maksimum mesaj boyutu aşıldı.'; es_ES = 'Mensaje de intercambio no se ha enviado: tamaño permitido de mensaje superado.'"));
	
	// Errors codes that are dependent on the transport kind.
	ErrorsMessages.Insert(101, NStr("ru = 'Ошибка инициализации: не указана учетная запись электронной почты транспорта сообщений обмена.'; en = 'Initialization error: the exchange message transport email account is not specified.'; pl = 'Błąd inicjalizacji: nie wskazano konta poczty elektronicznej transportu wiadomości wymiany.';de = 'Initialisierungsfehler: E-Mail-Konto des Austausch-Nachrichtentransports wurde nicht angegeben.';ro = 'Eroare de inițiere: contul de e-mail al transportului mesajului de schimb nu este specificat.';tr = 'Başlatma hatası: ileti aktarım paylaşımı e-posta hesabı belirtilmedi.'; es_ES = 'Error de iniciación: cuenta de correo electrónico del transporte de mensajes de intercambio no está especificado.'"));
	ErrorsMessages.Insert(102, NStr("ru = 'Ошибка при отправке сообщения электронной почты.'; en = 'Error sending the email message.'; pl = 'Błąd podczas wysyłania wiadomości e-mail.';de = 'Beim Senden der E-Mail ist ein Fehler aufgetreten.';ro = 'A apărut o eroare la trimiterea e-mail-ului.';tr = 'E-posta gönderilirken bir hata oluştu.'; es_ES = 'Ha ocurrido un error al enviar el correo electrónico.'"));
	ErrorsMessages.Insert(103, NStr("ru = 'Ошибка при получении заголовков сообщений с сервера электронной почты.'; en = 'Error receiving message headers from the email server.'; pl = 'Błąd  podczas odbioru tytułów wiadomości z serwera poczty e-mail.';de = 'Beim Abrufen von Nachrichtentiteln vom E-Mail-Server ist ein Fehler aufgetreten.';ro = 'A apărut o eroare la obținerea titlurilor de mesaje de pe server-ul de e-mail.';tr = 'E-posta sunucundan mesaj başlıkları alınırken bir hata oluştu.'; es_ES = 'Ha ocurrido un error al obtener los títulos de mensajes desde el servidor de correos electrónicos.'"));
	ErrorsMessages.Insert(104, NStr("ru = 'Не обнаружены сообщения обмена на почтовом сервере.'; en = 'Exchange messages were not found on the email server.'; pl = 'Nie znaleziono wiadomości wymiany na serwerze pocztowym.';de = 'Austausch-E-Mails werden nicht auf dem E-Mail-Server gefunden.';ro = 'Mesajele de schimb nu au fost găsite pe serverul de e-mail.';tr = 'Posta sunucusunda alışveriş mesajları bulunamadı.'; es_ES = 'Correos electrónicos de intercambio no se han encontrado en el servidor de correos electrónicos.'"));
	ErrorsMessages.Insert(105, NStr("ru = 'Ошибка при получении сообщения с сервера электронной почты.'; en = 'Error receiving the message from the email server.'; pl = 'Błąd  podczas odbioru wiadomości z serwera poczty e-mail.';de = 'Beim Empfang einer Nachricht vom E-Mail-Server ist ein Fehler aufgetreten.';ro = 'A apărut o eroare la primirea mesajului de la serverul de e-mail.';tr = 'E-posta sunucundan mesaj alınırken bir hata oluştu.'; es_ES = 'Ha ocurrido un error al recibir un mensaje del servidor de correos electrónicos.'"));
	ErrorsMessages.Insert(106, NStr("ru = 'Ошибка при записи файла сообщения обмена на диск.'; en = 'Error saving the exchange message file to the hard disk.'; pl = 'Błąd podczas zapisu pliku wiadomości wymiany na dysk.';de = 'Beim Schreiben der Austausch-Nachrichtendatei auf den Datenträger ist ein Fehler aufgetreten.';ro = 'Eroare la înregistrarea fișierului mesajului de schimb pe disc.';tr = 'Alışveriş mesajı dosyası diske kaydedilirken bir hata oluştu.'; es_ES = 'Ha ocurrido un error al grabar el archivo de mensajes de intercambio para el disco.'"));
	ErrorsMessages.Insert(107, NStr("ru = 'Проверка параметров учетной записи завершилась с ошибками.'; en = 'Errors occur when verifying account parameters.'; pl = 'Sprawdzenie parametrów konta zostało zakończone z błędami.';de = 'Die Prüfung der Kontoparameter wird mit Fehlern abgeschlossen.';ro = 'Verificarea parametrilor contului este finalizată cu erori.';tr = 'Hesap parametreleri hatalarla kontrol edildi.'; es_ES = 'Revisión de parámetros de la cuenta se ha finalizado con errores.'"));
	ErrorsMessages.Insert(108, NStr("ru = 'Превышен допустимый размер сообщения обмена.'; en = 'The maximum allowed exchange message size is exceeded.'; pl = 'Przekroczono dopuszczalny rozmiar wiadomości wymiany.';de = 'Die Größe der Austausch-Nachricht überschreitet das zulässige Limit.';ro = 'Dimensiunea mesajului de schimb depășește limita admisă.';tr = 'Veri alışverişi mesajının maksimum boyutu aşıldı.'; es_ES = 'Tamaño del mensaje de intercambio supera el límite permitido.'"));
	ErrorsMessages.Insert(109, NStr("ru = 'Ошибка: в почтовом сообщении не найден файл с сообщением.'; en = 'Error: no exchange message file is found in the email message.'; pl = 'Błąd: w wiadomości e-mail nie znaleziono pliku z komunikatem.';de = 'Fehler: Eine Datei mit Nachricht wurde in der E-Mail-Nachricht nicht gefunden.';ro = 'Eroare: în mesajul poștal nu a fost găsit fișierul cu mesajul.';tr = 'Hata: posta mesajında mesaj dosyası bulunamadı.'; es_ES = 'Error: un archivo con el mensaje no se ha encontrado en el mensaje de correos.'"));
	
EndProcedure

///////////////////////////////////////////////////////////////////////////////
// Procedures and functions for operating with email.

Function SendMessagebyEmail(Body, OutgoingMessageFileName, PathToFile)
	
	Attachments = New Map;
	Attachments.Insert(OutgoingMessageFileName,
						New BinaryData(PathToFile));
	
	EmailAddress = Common.ObjectAttributeValue(EMAILUserAccount, "EmailAddress");					
						
	MessageParameters = New Structure;
	MessageParameters.Insert("SendTo",     EmailAddress);
	MessageParameters.Insert("Subject",     MessageSubject);
	MessageParameters.Insert("Body",     Body);
	MessageParameters.Insert("Attachments", Attachments);
	
	Try
		EmailOperationsCommonModule.SendEmailMessage(EMAILUserAccount, MessageParameters);
	Except
		ErrorText = DetailErrorDescription(ErrorInfo());
		GetErrorMessage(102);
		SupplementErrorMessage(ErrorText);
		Return False;
	EndTry;
	
	Return True;
	
EndFunction

#EndRegion

#Region Initializing

InitMessages();
ErrorMessageInitialization();

TempExchangeMessagesDirectory = Undefined;
TempExchangeMessageFile    = Undefined;

ObjectName = NStr("ru = 'Обработка: %1'; en = 'Data processor: %1'; pl = 'Opracowanie: %1';de = 'Datenprozessor: %1';ro = 'DataProcessor:  %1';tr = 'Veri işlemcisi: %1'; es_ES = 'Procesador de datos: %1'");
ObjectName = StringFunctionsClientServer.SubstituteParametersToString(ObjectName, Metadata().Name);

If Common.SubsystemExists("StandardSubsystems.EmailOperations") Then
	EmailOperationsCommonModule = Common.CommonModule("EmailOperations");
EndIf;

#EndRegion

#Else
Raise NStr("ru = 'Недопустимый вызов объекта на клиенте.'; en = 'Invalid object call on the client.'; pl = 'Niedozwolone wezwanie obiektu na kliencie.';de = 'Unzulässiger Objektaufruf auf dem Client.';ro = 'Apel inadmisibil al obiectului pe client.';tr = 'İstemcide kabul edilmeyen nesne çağrısı.'; es_ES = 'Llamada no disponible del objeto en el cliente.'");
#EndIf