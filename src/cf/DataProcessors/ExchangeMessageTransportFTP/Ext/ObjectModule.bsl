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
Var FTPServerName;		// FTP server address is a name or address.
Var DirectoryAtFTPServer;// Directory on server for storing and receiving exchange messages.

Var TempExchangeMessageFile; // Temporary exchange message file for importing and exporting data.
Var TempExchangeMessagesDirectory; // Temporary exchange message directory.

Var SendGetDataTimeout; // Timeout that is used for FTP connection when sending and receiving data.

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
	
	ServerNameAndDirectoryAtServer = SplitFTPResourceToServerAndDirectory(TrimAll(FTPConnectionPath));
	FTPServerName			= ServerNameAndDirectoryAtServer.ServerName;
	DirectoryAtFTPServer	= ServerNameAndDirectoryAtServer.DirectoryName;
	
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
	
	// Function return value.
	Result = True;
	
	InitMessages();
	
	If IsBlankString(FTPConnectionPath) Then
		
		GetErrorMessage(101);
		Return False;
		
	EndIf;
	
	// Creating a file in the temporary directory.
	TempConnectionTestFileName = GetTempFileName("tmp");
	FileNameForDestination = DataExchangeServer.TempConnectionTestFileName();
	
	TextWriter = New TextWriter(TempConnectionTestFileName);
	TextWriter.WriteLine(FileNameForDestination);
	TextWriter.Close();
	
	// Copying a file to the external resource from the temporary directory.
	Result = CopyFileToFTPServer(TempConnectionTestFileName, FileNameForDestination, 10);
	
	// Deleting a file from the external resource.
	If Result Then
		
		Result = DeleteFileAtFTPServer(FileNameForDestination, True);
		
	EndIf;
	
	// Deleting a file from the temporary directory.
	DeleteFiles(TempConnectionTestFileName);
	
	Return Result;
EndFunction

///////////////////////////////////////////////////////////////////////////////
// Functions for retrieving properties.

// Function for retrieving property: the time of changing the exchange file message.
//
// Returns:
//  Date - the time of changing the exchange file message.
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

// Retrieves the full name of the exchange message file.
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

// Retrieves the full name of the exchange message directory.
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
			
			// Copying the archive file to the FTP server in the data exchange directory.
			If Not CopyFileToFTPServer(ArchiveTempFileName, OutgoingMessageFileName, SendGetDataTimeout) Then
				Result = False;
			EndIf;
			
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
			
			// Copying the archive file to the FTP server in the data exchange directory.
			If Not CopyFileToFTPServer(ExchangeMessageFileName(), OutgoingMessageFileName, SendGetDataTimeout) Then
				Result = False;
			EndIf;
			
		EndIf;
		
	EndIf;
	
	Return Result;
	
EndFunction

Function GetExchangeMessage(ExistenceCheck)
	
	ExchangeMessagesFilesTable = New ValueTable;
	ExchangeMessagesFilesTable.Columns.Add("File");
	ExchangeMessagesFilesTable.Columns.Add("Modified");
	
	Try
		FTPConnection = GetFTPConnection(SendGetDataTimeout);
	Except
		ErrorText = DetailErrorDescription(ErrorInfo());
		GetErrorMessage(102);
		SupplementErrorMessage(ErrorText);
		Return False;
	EndTry;
	MessageFileNameTemplateForSearch = StrReplace(MessageFileNamePattern, "Message", "Message*");

	Try
		FoundFileArray = FTPConnection.FindFiles(DirectoryAtFTPServer, MessageFileNameTemplateForSearch + ".*", False);
	Except
		ErrorText = DetailErrorDescription(ErrorInfo());
		GetErrorMessage(104);
		SupplementErrorMessage(ErrorText);
		Return False;
	EndTry;
	
	For Each CurrentFile In FoundFileArray Do
		
		// Checking the required extension.
		If ((Upper(CurrentFile.Extension) <> ".ZIP")
			AND (Upper(CurrentFile.Extension) <> ".XML")) Then
			
			Continue;
			
		// Checking that it is a file, not a directory.
		ElsIf NOT CurrentFile.IsFile() Then
			
			Continue;
			
		// Checking that the file size is greater than 0.
		ElsIf (CurrentFile.Size() = 0) Then
			
			Continue;
			
		EndIf;
		
		// The file is a required exchange message. Adding the file to the table.
		TableRow = ExchangeMessagesFilesTable.Add();
		TableRow.File           = CurrentFile;
		TableRow.Modified = CurrentFile.GetModificationTime();
		
	EndDo;
	
	If ExchangeMessagesFilesTable.Count() = 0 Then
		
		If Not ExistenceCheck Then
			GetErrorMessage(1);
		
			MessageString = NStr("ru = 'Каталог обмена информацией на сервере: ""%1""'; en = 'The data exchange directory on the server is %1.'; pl = 'Katalog wymiany informacji na serwerze: ""%1""';de = 'Verzeichnis für den Datenaustausch auf dem Server: ""%1""';ro = 'Directorul schimbului de informații pe server: ""%1""';tr = 'Sunucunda veri alışverişi dizini: ""%1""'; es_ES = 'Directorio de intercambio de datos en el servidor: ""%1""'");
			MessageString = StringFunctionsClientServer.SubstituteParametersToString(MessageString, DirectoryAtFTPServer);
			SupplementErrorMessage(MessageString);
			
			MessageString = NStr("ru = 'Имя файла сообщения обмена: ""%1"" или ""%2""'; en = 'Exchange message file name is %1 or %2'; pl = 'Nazwa pliku wiadomości wymiany: ""%1"" lub ""%2""';de = 'Name der Austausch-Nachrichtendatei: ""%1"" oder ""%2""';ro = 'Numele fișierului mesajului de schimb: ""%1"" sau ""%2""';tr = 'Veri alışverişi dosyasının adı: ""%1"" veya ""%2""'; es_ES = 'Nombre del archivo de mensajes de intercambio: ""%1"" o ""%2""'");
			MessageString = StringFunctionsClientServer.SubstituteParametersToString(MessageString, MessageFileNamePattern + ".xml", MessageFileNamePattern + ".zip");
			SupplementErrorMessage(MessageString);
		EndIf;
		
		Return False;
		
	Else
		
		If ExistenceCheck Then
			Return True;
		EndIf;
		
		ExchangeMessagesFilesTable.Sort("Modified Desc");
		
		// Obtaining the newest exchange message file from the table.
		IncomingMessageFile = ExchangeMessagesFilesTable[0].File;
		
		FilePacked = (Upper(IncomingMessageFile.Extension) = ".ZIP");
		
		If FilePacked Then
			
			// Getting the temporary archive file name.
			ArchiveTempFileName = CommonClientServer.GetFullFileName(ExchangeMessageCatalogName(), MessageFileNamePattern + ".zip");
			
			Try
				FTPConnection.Get(IncomingMessageFile.FullName, ArchiveTempFileName);
			Except
				ErrorText = DetailErrorDescription(ErrorInfo());
				GetErrorMessage(105);
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
				ArchiveFileNameStructure = CommonClientServer.ParseFullFileName(IncomingMessageFile.Name,False);
				MessageFileNameStructure = CommonClientServer.ParseFullFileName(ExchangeMessageFileName(),False);
				
				If ArchiveFileNameStructure.BaseName <> MessageFileNameStructure.BaseName Then
					UnpackedFilesArray = FindFiles(ExchangeMessageCatalogName(), "*.xml", False);
					If UnpackedFilesArray.Count() > 0 Then
						UnpackedFile = UnpackedFilesArray[0];
						MoveFile(UnpackedFile.FullName,ExchangeMessageFileName());
					Else
						GetErrorMessage(7);
						Return False;
					EndIf;
				Else
					GetErrorMessage(7);
					Return False;
				EndIf;
				
			EndIf;
			
		Else
			Try
				FTPConnection.Get(IncomingMessageFile.FullName, ExchangeMessageFileName());
			Except
				ErrorText = DetailErrorDescription(ErrorInfo());
				GetErrorMessage(105);
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
	
	Return FTPConnectionMaxMessageSize;
	
EndFunction

///////////////////////////////////////////////////////////////////////////////
// Functions for retrieving properties.

Function CompressOutgoingMessageFile()
	
	Return FTPCompressOutgoingMessageFile;
	
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
	ErrorsMessages.Insert(001, NStr("ru = 'В каталоге обмена информацией не был обнаружен файл сообщения с данными.'; en = 'No message file with data was found in the exchange directory.'; pl = 'W katalogu wymiany informacji nie znaleziono pliku wiadomości z danymi.';de = 'Das Verzeichnis für den Informationsaustausch enthält keine Nachrichtendatei mit Daten.';ro = 'Directorul schimbului de informații nu conține un fișierul mesajului cu date.';tr = 'Veri alışverişi dizininde veri mesajı dosyası bulundu.'; es_ES = 'Directorio de intercambio de información no contiene un archivo de mensajes con datos.'"));
	ErrorsMessages.Insert(002, NStr("ru = 'Ошибка при распаковке сжатого файла сообщения.'; en = 'Error unpacking the exchange message file.'; pl = 'Podczas rozpakowywania skompresowanego pliku wiadomości wystąpił błąd.';de = 'Beim Entpacken einer komprimierten Nachrichtendatei ist ein Fehler aufgetreten.';ro = 'Eroare la despachetarea fișierului de mesaj comprimat.';tr = 'Sıkıştırılmış mesaj dosyası açılırken bir hata oluştu.'; es_ES = 'Ha ocurrido un error al desembalar un archivo de mensajes comprimido.'"));
	ErrorsMessages.Insert(003, NStr("ru = 'Ошибка при сжатии файла сообщения обмена.'; en = 'Error packing the exchange message file.'; pl = 'Błąd podczas kompresji pliku wiadomości wymiany.';de = 'Beim Komprimieren der Austausch-Nachrichtendatei ist ein Fehler aufgetreten.';ro = 'Eroare la comprimarea fișierului mesajului de schimb.';tr = 'Veri alışverişi mesajı dosyası sıkıştırılırken bir hata oluştu.'; es_ES = 'Ha ocurrido un error al comprimir el archivo de mensajes de intercambio.'"));
	ErrorsMessages.Insert(004, NStr("ru = 'Ошибка при создании временного каталога.'; en = 'An error occurred when creating a temporary directory.'; pl = 'Błąd podczas tworzenia katalogu tymczasowego.';de = 'Beim Erstellen eines temporären Verzeichnisses ist ein Fehler aufgetreten.';ro = 'A apărut o eroare la crearea unui director temporar.';tr = 'Geçici bir dizin oluştururken bir hata oluştu.'; es_ES = 'Ha ocurrido un error al crear un directorio temporal.'"));
	ErrorsMessages.Insert(005, NStr("ru = 'Архив не содержит файл сообщения обмена.'; en = 'The archive does not contain the exchange message file.'; pl = 'Archiwum nie zawiera pliku wiadomości wymiany.';de = 'Das Archiv enthält keine Austausch-Nachrichtendatei.';ro = 'Arhiva nu conține fișierul mesajului de schimb.';tr = 'Arşiv, veri alışveriş mesajı dosyasını içermiyor.'; es_ES = 'Archivo no incluye el archivo de mensajes de intercambio.'"));
	
	// Errors codes that are dependent on the transport kind.
	ErrorsMessages.Insert(101, NStr("ru = 'Не задан путь на сервере.'; en = 'Path on the server is not specified.'; pl = 'Nie określono ścieżki na serwerze.';de = 'Pfad auf dem Server ist nicht angegeben.';ro = 'Calea de pe server nu este specificată.';tr = 'Sunucudaki yol belirtilmemiş.'; es_ES = 'Ruta en el servidor no está especificada.'"));
	ErrorsMessages.Insert(102, NStr("ru = 'Ошибка инициализации подключения к FTP-серверу.'; en = 'Error initializing connection to the FTP server.'; pl = 'Błąd inicjalizacji połączenia z serwerem FTP.';de = 'Bei der Initialisierung der Verbindung zum FTP-Server ist ein Fehler aufgetreten.';ro = 'A apărut o eroare la inițializarea conexiunii la serverul FTP.';tr = 'FTP-sunucusuna bağlantı başlatma hatası.'; es_ES = 'Ha ocurrido un error al iniciar la conexión al servidor FTP.'"));
	ErrorsMessages.Insert(103, NStr("ru = 'Ошибка подключения к FTP-серверу, проверьте правильность задания пути и права доступа к ресурсу.'; en = 'Error establishing connection to the FTP server. Check whether the path is specified correctly and whether access rights are sufficient.'; pl = 'Błąd połączenia z serwerem FTP, sprawdź poprawność ścieżki i prawa dostępu do zasobu.';de = 'Beim Herstellen der Verbindung zum FTP-Server ist ein Fehler aufgetreten. Überprüfen Sie die Richtigkeit des Pfads und die Zugriffsrechte für die Ressource.';ro = 'A apărut o eroare de conectare la serverul FTP, verificați corectitudinea specificării căii și drepturile de acces la resursă.';tr = 'FTP-sunucuna bağlantı hatası, yol ve kaynak erişim hakkının doğru belirlenip belirlenmediğini kontrol edin.'; es_ES = 'Ha ocurrido un error al conectar al servidor FTP, revisar la exactitud de la ruta y los derechos de acceso para el recurso.'"));
	ErrorsMessages.Insert(104, NStr("ru = 'Ошибка при поиске файлов на FTP-сервере.'; en = 'Error searching for files on the FTP server.'; pl = 'Błąd podczas wyszukiwania plików na serwerze FTP.';de = 'Bei der Suche nach Dateien auf dem FTP-Server ist ein Fehler aufgetreten.';ro = 'A apărut o eroare la căutarea fișierelor pe serverul FTP.';tr = 'Dosyalar FTP-sunucuda aranırken bir hata oluştu.'; es_ES = 'Ha ocurrido un error al buscar los archivos en el servidor FTP.'"));
	ErrorsMessages.Insert(105, NStr("ru = 'Ошибка при получении файла с FTP-сервера.'; en = 'Error receiving the file from the FTP server.'; pl = 'Błąd podczas pobierania pliku z serwera FTP.';de = 'Beim Empfang der Datei vom FTP-Server ist ein Fehler aufgetreten.';ro = 'A apărut o eroare la primirea fișierului de pe serverul FTP.';tr = 'Dosya FTP-sunucusundan alınırken bir hata oluştu.'; es_ES = 'Ha ocurrido un error al recibir el archivo del servidor FTP.'"));
	ErrorsMessages.Insert(106, NStr("ru = 'Ошибка удаления файла на FTP-сервере, проверьте права доступа к ресурсу.'; en = 'Error deleting the file from the FTP server. Check whether resource access rights are sufficient.'; pl = 'Błąd usunięcia pliku na serwerze FTP, sprawdź prawa dostępu do zasobu.';de = 'Beim Entfernen der Datei auf dem FTP-Server ist ein Fehler aufgetreten. Überprüfen Sie die Zugriffsrechte für die Ressource.';ro = 'Eroare la ștergerea fișierului de pe serverul FTP, verificați drepturile de acces la resursă.';tr = 'Dosya FTP-sunucusundan kaldırılırken bir hata oluştu, kayak erişim haklarını kontrol edin.'; es_ES = 'Ha ocurrido un error al eliminar el archivo del servidor FTP, revisar los derechos de acceso para el recurso.'"));
	
	ErrorsMessages.Insert(108, NStr("ru = 'Превышен допустимый размер сообщения обмена.'; en = 'The maximum allowed exchange message size is exceeded.'; pl = 'Przekroczono dopuszczalny rozmiar wiadomości wymiany.';de = 'Die Größe der Austausch-Nachricht überschreitet das zulässige Limit.';ro = 'Dimensiunea mesajului de schimb depășește limita admisă.';tr = 'Veri alışverişi mesajının maksimum boyutu aşıldı.'; es_ES = 'Tamaño del mensaje de intercambio supera el límite permitido.'"));
	
EndProcedure

///////////////////////////////////////////////////////////////////////////////
// Procedures and functions for working with FTP connection.

Function GetFTPConnection(Timeout)
	
	FTPSettings = DataExchangeServer.FTPConnectionSettings(Timeout);
	FTPSettings.Server               = FTPServerName;
	FTPSettings.Port                 = FTPConnectionPort;
	FTPSettings.UserName      = FTPConnectionUser;
	FTPSettings.UserPassword   = FTPConnectionPassword;
	FTPSettings.PassiveConnection  = FTPConnectionPassiveConnection;
	FTPSettings.SecureConnection = DataExchangeServer.SecureConnection(FTPConnectionPath);
	
	Return DataExchangeServer.FTPConnection(FTPSettings);
	
EndFunction

Function CopyFileToFTPServer(Val SourceFileName, DestinationFileName, Val Timeout)
	
	Var DirectoryAtServer;
	
	ServerAndDirectoryAtServer = SplitFTPResourceToServerAndDirectory(TrimAll(FTPConnectionPath));
	DirectoryAtServer = ServerAndDirectoryAtServer.DirectoryName;
	
	Try
		FTPConnection = GetFTPConnection(Timeout);
	Except
		ErrorText = DetailErrorDescription(ErrorInfo());
		GetErrorMessage(102);
		SupplementErrorMessage(ErrorText);
		Return False;
	EndTry;
	
	Try
		FTPConnection.Put(SourceFileName, DirectoryAtServer + DestinationFileName);
	Except
		ErrorText = DetailErrorDescription(ErrorInfo());
		GetErrorMessage(103);
		SupplementErrorMessage(ErrorText);
		Return False;
	EndTry;
	
	Try
		FilesArray = FTPConnection.FindFiles(DirectoryAtServer, DestinationFileName, False);
	Except
		ErrorText = DetailErrorDescription(ErrorInfo());
		GetErrorMessage(104);
		SupplementErrorMessage(ErrorText);
		Return False;
	EndTry;
	
	Return FilesArray.Count() > 0;
	
EndFunction

Function DeleteFileAtFTPServer(Val FileName, ConnectionTest = False)
	
	Var DirectoryAtServer;
	
	ServerAndDirectoryAtServer = SplitFTPResourceToServerAndDirectory(TrimAll(FTPConnectionPath));
	DirectoryAtServer = ServerAndDirectoryAtServer.DirectoryName;
	
	Try
		FTPConnection = GetFTPConnection(10);
	Except
		ErrorText = DetailErrorDescription(ErrorInfo());
		GetErrorMessage(102);
		SupplementErrorMessage(ErrorText);
		Return False;
	EndTry;
	
	Try
		FTPConnection.Delete(DirectoryAtServer + FileName);
	Except
		ErrorText = DetailErrorDescription(ErrorInfo());
		GetErrorMessage(106);
		SupplementErrorMessage(ErrorText);
		
		If ConnectionTest Then
			
			ErrorMessage = NStr("ru = 'Не удалось проверить подключение с помощью тестового файла ""%1"".
			|Возможно, заданный каталог не существует или не доступен.
			|Рекомендуется также обратиться к документации по FTP-серверу для настройки поддержки имен файлов с кириллицей.'; 
			|en = 'Cannot check connection with test file ""%1"".
			|Maybe, the specified directory does not exist or is unavailable.
			|It is also recommended to address FTP server documentation to configure support of cyrillic file names.'; 
			|pl = 'Nie udało się sprawdzić połączenia z użyciem pliku testowego ""%1"".
			|Być może określony katalog nie istnieje lub nie jest dostępny.
			|Zaleca się także, aby zobaczyć dokumentację serwera FTP,  skonfigurować obsługę plików cyrylicy.';
			|de = 'Fehler beim Überprüfen der Verbindung durch die Testdatei ""%1"".
			|Vielleicht existiert das angegebene Verzeichnis nicht oder ist nicht verfügbar.
			|Es wird auch empfohlen, die FTP-Server-Dokumentation zu lesen, um die Unterstützung der kyrillischen Namensdateien einzurichten.';
			|ro = 'Eșec la verificarea conexiunii cu ajutorul fișierului de testare ""%1"".
			|Posibil, directorul specificat nu există sau nu este disponibil.
			|De asemenea, este recomandat să vedeți documentația serverului FTP pentru a configura suportul fișierelor de nume Chirilice.';
			|tr = '""%1""Test dosyasını kullanarak bağlantıyı test edilemedi. 
			|Belirtilen dizin mevcut olmayabilir ya da erişilmeyebilir. 
			| Ayrıca Kiril alfabesi ile belirlenen dosya adlarını desteklemek için FTP sunucu ile ilgili belgelere bakmanız önerilir.'; 
			|es_ES = 'Fallado a revisar la conexión por el archivo de prueba ""%1"".
			|Probablemente, el directorio especificado no existe o no está disponible.
			|También se recomienda ver la documentación del servidor FTP para configurar el soporte de los archivos de nombre Cirílicos.'");
			ErrorMessage = StringFunctionsClientServer.SubstituteParametersToString(ErrorMessage, FileName);
			SupplementErrorMessage(ErrorMessage);
			
		EndIf;
		
		Return False;
	EndTry;
	
	Return True;
	
EndFunction

Function SplitFTPResourceToServerAndDirectory(Val FullPath)
	
	Result = New Structure("ServerName, DirectoryName");
	
	FTPParameters = DataExchangeServer.FTPServerNameAndPath(FullPath);
	
	Result.ServerName  = FTPParameters.Server;
	Result.DirectoryName = FTPParameters.Path;
	
	Return Result;
EndFunction

#EndRegion

#Region Initializing

InitMessages();
ErrorMessageInitialization();

TempExchangeMessagesDirectory = Undefined;
TempExchangeMessageFile    = Undefined;

FTPServerName       = Undefined;
DirectoryAtFTPServer = Undefined;

ObjectName = NStr("ru = 'Обработка: %1'; en = 'Data processor: %1'; pl = 'Opracowanie: %1';de = 'Datenprozessor: %1';ro = 'DataProcessor:  %1';tr = 'Veri işlemcisi: %1'; es_ES = 'Procesador de datos: %1'");
ObjectName = StringFunctionsClientServer.SubstituteParametersToString(ObjectName, Metadata().Name);

SendGetDataTimeout = 12*60*60;

#EndRegion

#Else
Raise NStr("ru = 'Недопустимый вызов объекта на клиенте.'; en = 'Invalid object call on the client.'; pl = 'Niedozwolone wezwanie obiektu na kliencie.';de = 'Unzulässiger Objektaufruf auf dem Client.';ro = 'Apel inadmisibil al obiectului pe client.';tr = 'İstemcide kabul edilmeyen nesne çağrısı.'; es_ES = 'Llamada no disponible del objeto en el cliente.'");
#EndIf