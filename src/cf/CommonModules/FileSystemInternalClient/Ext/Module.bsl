///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Private

#Region FilesImportFromFileSystem

// The procedure that follows FileSystemClient.ShowPutFile.
Procedure ShowPutFileOnAttachFileSystemExtension(ExtensionAttached, Context) Export
	
	Dialog               = Context.Dialog;
	Interactively         = Context.Interactively;
	FilesToUpload     = Context.FilesToUpload;
	FormID   = Context.FormID;
	CompletionHandler = Context.CompletionHandler;

	ProcessingResultsParameters = New Structure;
	ProcessingResultsParameters.Insert("MultipleChoice",   Dialog.Multiselect);
	ProcessingResultsParameters.Insert("CompletionHandler", CompletionHandler);
	
	If ExtensionAttached Then
		
		If Interactively Then
			FilesToPut = New Array;
		Else
			Dialog = "";
			FilesToPut = FilesToUpload;
		EndIf;
		
		NotifyDescription = New NotifyDescription(
			"ProcessPutFilesResult", ThisObject, ProcessingResultsParameters);
		
		If ValueIsFilled(FormID) Then
			BeginPuttingFiles(NotifyDescription, FilesToPut, Dialog, Interactively, FormID);
		Else
			BeginPuttingFiles(NotifyDescription, FilesToPut, Dialog, Interactively);
		EndIf;
		
	Else 
		
		Handler = New NotifyDescription(
			"ProcessPutFileResult", ThisObject, ProcessingResultsParameters);
			
		If ValueIsFilled(FormID) Then
			BeginPutFile(Handler, , Dialog.FullFileName, True, FormID);
		Else
			BeginPutFile(Handler, , Dialog.FullFileName, True);
		EndIf;
		
		Return;
		
	EndIf;
	
EndProcedure

// Putting files completion.
Procedure ProcessPutFilesResult(FilesThatWerePut, ProcessingResultsParameters) Export
	
	ProcessPutFileResult(FilesThatWerePut <> Undefined, FilesThatWerePut, Undefined,
		ProcessingResultsParameters);
	
EndProcedure

// Putting file completion.
Procedure ProcessPutFileResult(SelectionDone, AddressOrSelectionResult, SelectedFileName,
		ProcessingResultsParameters) Export
	
	If SelectionDone = True Then
		
		If TypeOf(AddressOrSelectionResult) = Type("Array") Then
			
			If ProcessingResultsParameters.MultipleChoice Then
				FilesThatWerePut = AddressOrSelectionResult;
			Else
				
				FilesThatWerePut = New Structure;
				FilesThatWerePut.Insert("Location", AddressOrSelectionResult[0].Location);
				FilesThatWerePut.Insert("Name",      AddressOrSelectionResult[0].Name);
				
			EndIf;
			
		Else
			
			FileDetails = New Structure;
			FileDetails.Insert("Location", AddressOrSelectionResult);
			FileDetails.Insert("Name",      SelectedFileName);
			
			If ProcessingResultsParameters.MultipleChoice Then
				FilesThatWerePut = New Array;
				FilesThatWerePut.Add(FileDetails);
			Else
				FilesThatWerePut = FileDetails;
			EndIf;
			
		EndIf;
		
	Else
		FilesThatWerePut = Undefined;
	EndIf;
	
	ExecuteNotifyProcessing(ProcessingResultsParameters.CompletionHandler, FilesThatWerePut);
	
EndProcedure

#EndRegion

#Region ModifiesStoredDataToFileSystem

// The procedure that follows FileSystemClient.ShowDownloadFiles procedure.
Procedure ShowDownloadFilesOnAttachFileSystemExtension(ExtensionAttached, Context) Export
	
	Interactively = Context.Interactively;
	Dialog = ?(Interactively, Context.Dialog, Context.Dialog.Directory);
	
	If ExtensionAttached Then
		
		CompletionNotification = New NotifyDescription("NotifyGetFilesCompletion", ThisObject, Context);
		BeginGettingFiles(CompletionNotification, Context.FilesToGet,
			Dialog, Interactively);
		
	Else
		
		For Each FileToReceive In Context.FilesToGet Do
			GetFile(FileToReceive.Location, FileToReceive.Name, True);
		EndDo;
		
		If Context.CompletionHandler <> Undefined Then
			ExecuteNotifyProcessing(Context.CompletionHandler, Undefined);
		EndIf;
		
	EndIf;
	
EndProcedure

// The procedure that follows FileSystemClient.ShowDownloadFiles procedure.
Procedure NotifyGetFilesCompletion(ReceivedFiles, AdditionalParameters) Export
	
	If AdditionalParameters.CompletionHandler <> Undefined Then
		ExecuteNotifyProcessing(AdditionalParameters.CompletionHandler, ReceivedFiles);
	EndIf;
	
EndProcedure

#EndRegion

#Region OpeningFiles

// The procedure that follows FileSystemClient.OpenFile.
Procedure OpenFileAfterSaving(SavedFiles, OpeningParameters) Export
	
	If SavedFiles = Undefined Then
		ExecuteNotifyProcessing(OpeningParameters.CompletionHandler, False);
	Else
		
		FileDetails = 
			?(TypeOf(SavedFiles) = Type("Array"), 
				SavedFiles[0], 
				SavedFiles);
		
		CompletionHandler = New NotifyDescription(
			"OpenFileAfterEditingCompletion", ThisObject, OpeningParameters);
		
		OpenFileInViewer(FileDetails.Name, CompletionHandler, OpeningParameters.ForEditing);
		
	EndIf;
	
EndProcedure

// The procedure that follows FileSystemClient.OpenFile.
// Opens the file in the application associated with the file type.
// Prevents executable files from opening.
//
// Parameters:
//  PathToFile        - String - the full path to the file to open.
//  Notification - NotifyDescription - notification on file open attempt.
//                    If the notification is not specified and an error occurs, the method shows a warning.
//   - ApplicationStarted      - Boolean - True if the external application opened successfully.
//   - AdditionalParameters - Arbitrary - a value that was specified when creating the NotifyDescription object.
//  ForEditing - Boolean - True to open the file for editing, False otherwise.
//  
// Example:
//  CommonUseClient.OpenFileInViewer(DocumentsDir() + "test.pdf");
//  CommonUseClient.OpenFileInViewer(DocumentsDir() + "test.xlsx");
//
Procedure OpenFileInViewer(FilePath, Val Notification = Undefined,
		Val ForEditing = False)
	
	FileInfo = New File(FilePath);
	
	Context = New Structure;
	Context.Insert("FileInfo",          FileInfo);
	Context.Insert("Notification",        Notification);
	Context.Insert("ForEditing", ForEditing);
	
	Notification = New NotifyDescription(
		"OpenFileInViewerAfterCheckFileSystemExtension", ThisObject, Context);
	
	SuggestionText = NStr("ru = 'Для открытия файла необходимо установить расширение работы с файлами.'; en = 'To be able to open files, install the file system extension.'; pl = 'Dla otwarcia pliku należy zainstalować rozszerzenie pracy z plikami.';de = 'Um eine Datei zu öffnen, sollten Sie die Dateierweiterung installieren.';ro = 'Pentru deschiderea fișierului trebuie să instalați extensia de lucru cu fișierele.';tr = 'Dosyayı açmak için, dosyalarla çalışmak için bir uzantı yüklenmelidir.'; es_ES = 'Para abrir el archivo es necesario instalar la extensión de la operación de archivos.'");
	FileSystemClient.AttachFileOperationsExtension(Notification, SuggestionText, False);
	
EndProcedure

// The procedure that follows FileSystemClient.OpenFile.
Procedure OpenFileInViewerAfterCheckFileSystemExtension(ExtensionAttached, Context) Export
	
	FileInfo = Context.FileInfo;
	If ExtensionAttached Then
		
		Notification = New NotifyDescription(
			"OpenFileInViewerAfterCheckIfExists", ThisObject, Context,
			"OpenFileInViewerOnProcessError", ThisObject);
		FileInfo.BeginCheckingExistence(Notification);
		
	Else
		
		ErrorDescription = NStr("ru = 'Расширение для работы с файлами не установлено, открытие файла невозможно.'; en = 'Cannot open the file because the file system extension is not installed.'; pl = 'Rozszerzenie do pracy z plikami nie jest ustanowione, otwarcie pliku jest nie możliwe.';de = 'Dateierweiterung nicht installiert, das Öffnen der Datei ist nicht möglich.';ro = 'Extensia pentru lucrul cu fișierele nu este instalată, fișierul nu poate fi deschis.';tr = 'Dosya işlemi uzantısı yüklü değil, dosya açılamıyor.'; es_ES = 'La extensión del uso de archivos no está instalada, no se puede abrir el archivo.'");
		OpenFileInViewerNotifyOnError(ErrorDescription, Context);
		
	EndIf;
	
EndProcedure

// The procedure that follows FileSystemClient.OpenFile.
Procedure OpenFileInViewerAfterCheckIfExists(Exists, Context) Export
	
	FileInfo = Context.FileInfo;
	If Exists Then
		 
		Notification = New NotifyDescription(
			"OpenFileInViewerAfterCheckIsFIle", ThisObject, Context,
			"OpenFileInViewerOnProcessError", ThisObject);
		FileInfo.BeginCheckingIsFile(Notification);
		
	Else 
		
		ErrorDescription = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Не найден файл, который требуется открыть:
			           |%1'; 
			           |en = 'Cannot find the file to open:
			           |%1.'; 
			           |pl = 'Nie jest znaleziony plik, który trzeba otworzyć:
			           |%1';
			           |de = 'Es wurde keine zu öffnende Datei gefunden:
			           |%1';
			           |ro = 'Nu a fost găsit fișierul care trebuie deschis:
			           |%1';
			           |tr = 'Açılacak dosya bulunamadı: 
			           |%1'; 
			           |es_ES = 'No se ha encontrado archivo que se requiere abrir:
			           |%1'"),
			FileInfo.FullName);
		OpenFileInViewerNotifyOnError(ErrorDescription, Context);
		
	EndIf;
	
EndProcedure

// The procedure that follows FileSystemClient.OpenFile.
Procedure OpenFileInViewerAfterCheckIsFIle(IsFile, Context) Export
	
	// CAC:534-off safe start methods are provided with this function
	
	FileInfo = Context.FileInfo;
	If IsFile Then
		
		If IsBlankString(FileInfo.Extension) Then 
			
			ErrorDescription = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'Имя файла не содержит расширения:
				           |%1'; 
				           |en = 'The file name is missing extension:
				           |%1.'; 
				           |pl = 'Nazwa pliku nie zawiera rozszerzenia:
				           |%1';
				           |de = 'Der Dateiname enthält keine Erweiterung:
				           |%1';
				           |ro = 'Numele fișierului nu conține extensia:
				           |%1';
				           |tr = 'Dosya adı uzantı içermiyor:  
				           |%1'; 
				           |es_ES = 'El nombre de archivo no contiene extensiones:
				           |%1'"),
				FileInfo.FullName);
			
			OpenFileInViewerNotifyOnError(ErrorDescription, Context);
			Return;
			
		EndIf;
		
		If IsExecutableFileExtension(FileInfo.Extension) Then 
			
			ErrorDescription = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'Исполняемые файлы открывать запрещено:
				           |%1'; 
				           |en = 'Opening executable files is disabled:
				           |%1.'; 
				           |pl = 'Otwarcie wykоnywanych plików jest zabronione:
				           |%1';
				           |de = 'Ausführbare Dateien dürfen nicht geöffnet werden:
				           |%1';
				           |ro = 'Este interzisă deschiderea fișierelor care se execută:
				           |%1';
				           |tr = 'Yürütülen dosyalar açılamaz: 
				           |%1'; 
				           |es_ES = 'Está prohibido abrir archivos ejecutivos:
				           |%1'"),
				FileInfo.FullName);
			
			OpenFileInViewerNotifyOnError(ErrorDescription, Context);
			Return;
			
		EndIf;
		
		Notification          = Context.Notification;
		WaitForCompletion = Context.ForEditing;
		
		Notification = New NotifyDescription(
			"OpenFileInViewerAfterStartApplication", ThisObject, Context,
			"OpenFileInViewerOnProcessError", ThisObject);
		BeginRunningApplication(Notification, FileInfo.FullName,, WaitForCompletion);
		
	Else 
		
		ErrorDescription = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Не найден файл, который требуется открыть:
			           |%1'; 
			           |en = 'Cannot find the file to open:
			           |%1.'; 
			           |pl = 'Nie jest znaleziony plik, który trzeba otworzyć:
			           |%1';
			           |de = 'Es wurde keine zu öffnende Datei gefunden:
			           |%1';
			           |ro = 'Nu a fost găsit fișierul care trebuie deschis:
			           |%1';
			           |tr = 'Açılacak dosya bulunamadı: 
			           |%1'; 
			           |es_ES = 'No se ha encontrado archivo que se requiere abrir:
			           |%1'"),
			FileInfo.FullName);
			
		OpenFileInViewerNotifyOnError(ErrorDescription, Context);
		
	EndIf;
	
	// CAC:534-enable
	
EndProcedure

// The procedure that follows FileSystemClient.OpenFile.
Procedure OpenFileInViewerAfterStartApplication(ReturnCode, Context) Export 
	
	Notification = Context.Notification;
	
	If Notification <> Undefined Then 
		ApplicationStarted = (ReturnCode = 0);
		ExecuteNotifyProcessing(Notification, ApplicationStarted);
	EndIf;
	
EndProcedure

// The procedure that follows FileSystemClient.OpenFile.
Procedure OpenFileInViewerOnProcessError(ErrorInformation, StandardProcessing, Context) Export
	
	StandardProcessing = False;
	OpenFileInViewerNotifyOnError("", Context);
	
EndProcedure

// The procedure that follows FileSystemClient.OpenFile.
Procedure OpenFileAfterEditingCompletion(ApplicationStarted, OpeningParameters) Export
	
	If ApplicationStarted
		AND OpeningParameters.Property("AddressOfBinaryDataToUpdate") Then
		
		Notification = New NotifyDescription(
			"OpenFileAfterDataUpdateInStorage", ThisObject, OpeningParameters);
			
		BeginPutFile(Notification, OpeningParameters.AddressOfBinaryDataToUpdate,
			OpeningParameters.PathToFile, False);
		
	Else
		ExecuteNotifyProcessing(OpeningParameters.CompletionHandler, ApplicationStarted);
	EndIf;
	
EndProcedure

// The procedure that follows FileSystemClient.OpenFile.
Procedure OpenFileAfterDataUpdateInStorage(IsDataUpdated, DataAddress, FileName,
		OpeningParameters) Export
	
	If OpeningParameters.Property("DeleteAfterDataUpdate") Then
		
		AdditionalParameters = New Structure;
		AdditionalParameters.Insert("IsDataUpdated", IsDataUpdated);
		AdditionalParameters.Insert("OpeningParameters", OpeningParameters);
		
		NotifyDescription = New NotifyDescription(
			"OpenFileAfterTempFileDeletion", ThisObject, AdditionalParameters);
			
		BeginDeletingFiles(NotifyDescription, FileName);
		
	Else
		ExecuteNotifyProcessing(OpeningParameters.CompletionHandler, IsDataUpdated);
	EndIf;
	
EndProcedure

// The procedure that follows FileSystemClient.OpenFile.
Procedure OpenFileAfterTempFileDeletion(AdditionalParameters) Export
	
	ExecuteNotifyProcessing(AdditionalParameters.OpeningParameters.CompletionHandler,
		AdditionalParameters.IsDataUpdated);
	
EndProcedure

// The procedure that follows FileSystemClient.OpenFile.
Procedure OpenFileInViewerNotifyOnError(ErrorDescription, Context)
	
	If Not IsBlankString(ErrorDescription) Then 
		ShowMessageBox(, ErrorDescription);
	EndIf;
	
	ApplicationStarted = False;
	ExecuteNotifyProcessing(Context.Notification, ApplicationStarted);
	
EndProcedure

// Parameters:
//  Extension - String - the Extension property of the File object.
//
Function IsExecutableFileExtension(Val Extension)
	
	Extension = Upper(Extension);
	
	// Windows
	Return Extension = ".BAT" // Batch File
		Or Extension = ".BIN" // Binary Executable
		Or Extension = ".CMD" // Command Script
		Or Extension = ".COM" // MS-DOS application
		Or Extension = ".CPL" // Control Panel Extension
		Or Extension = ".EXE" // Executable file
		Or Extension = ".GADGET" // Binary Executable
		Or Extension = ".HTA" // HTML Application
		Or Extension = ".INF1" // Setup Information File
		Or Extension = ".INS" // Internet Communication Settings
		Or Extension = ".INX" // InstallShield Compiled Script
		Or Extension = ".ISU" // InstallShield Uninstaller Script
		Or Extension = ".JOB" // Windows Task Scheduler Job File
		Or Extension = ".LNK" // File Shortcut
		Or Extension = ".MSC" // Microsoft Common Console Document
		Or Extension = ".MSI" // Windows Installer Package
		Or Extension = ".MSP" // Windows Installer Patch
		Or Extension = ".MST" // Windows Installer Setup Transform File
		Or Extension = ".OTM" // Microsoft Outlook macro
		Or Extension = ".PAF" // Portable Application Installer File
		Or Extension = ".PIF" // Program Information File
		Or Extension = ".PS1" // Windows PowerShell Cmdlet
		Or Extension = ".REG" // Registry Data File
		Or Extension = ".RGS" // Registry Script
		Or Extension = ".SCT" // Windows Scriptlet
		Or Extension = ".SHB" // Windows Document Shortcut
		Or Extension = ".SHS" // Shell Scrap Object
		Or Extension = ".U3P" // U3 Smart Application
		Or Extension = ".VB"  // VBScript File
		Or Extension = ".VBE" // VBScript Encoded Script
		Or Extension = ".VBS" // VBScript File
		Or Extension = ".VBSCRIPT" // Visual Basic Script
		Or Extension = ".WS"  // Windows Script
		Or Extension = ".WSF" // Windows Script
	// Linux
		Or Extension = ".CSH" // C Shell Script
		Or Extension = ".KSH" // Unix Korn Shell Script
		Or Extension = ".OUT" // Executable file
		Or Extension = ".RUN" // Executable file
		Or Extension = ".SH"  // Shell Script
	// MacOS
		Or Extension = ".ACTION" // Automator Action
		Or Extension = ".APP" // Executable file
		Or Extension = ".COMMAND" // Terminal Command
		Or Extension = ".OSX" // Executable file
		Or Extension = ".WORKFLOW" // Automator Workflow
	// Other
		Or Extension = ".AIR" // Adobe AIR distribution package
		Or Extension = ".COFFIE" // CoffeeScript (JavaScript) script
		Or Extension = ".JAR" // Java archive
		Or Extension = ".JS"  // JScript File
		Or Extension = ".JSE" // JScript Encoded File
		Or Extension = ".PLX" // Perl executable file
		Or Extension = ".PYC" // Python compiled file
		Or Extension = ".PYO"; // Python optimized code
	
EndFunction

#EndRegion

#Region OpenExplorer

// Continue the CommonClient.OpenExplorer procedure.
Procedure OpenExplorerAfterCheckFileSystemExtension(ExtensionAttached, Context) Export
	
	FileInfo = Context.FileInfo;
	
	If ExtensionAttached Then
		Notification = New NotifyDescription(
			"OpenExplorerAfterCheckIfExists", ThisObject, Context, 
			"OpenExplorerOnProcessError", ThisObject);
		FileInfo.BeginCheckingExistence(Notification);
	Else
		ErrorDescription = NStr("ru = 'Расширение для работы с файлами не установлено, открытие папки не возможно.'; en = 'Cannot open directories because the file system extension is not installed.'; pl = 'Rozszerzenie do pracy z plikami nie jest ustawione, otwarcie folderu jest niemożliwe.';de = 'Die Erweiterung für das Arbeiten mit Dateien ist nicht installiert, das Öffnen eines Ordners ist nicht möglich.';ro = 'Extensia pentru lucrul cu fișierele nu este instalată, folderul nu poate fi deschis.';tr = 'Dosya işlemi uzantısı yüklü değil, klasör açılamıyor.'; es_ES = 'La extensión del uso de archivos no está instalada, no se puede abrir el catálogo.'");
		OpenExplorerNotifyOnError(ErrorDescription, Context);
	EndIf;
	
EndProcedure

// Continue the CommonClient.OpenExplorer procedure.
Procedure OpenExplorerAfterCheckIfExists(Exists, Context) Export 
	
	FileInfo = Context.FileInfo;
	
	If Exists Then 
		Notification = New NotifyDescription(
			"OpenExplorerAfterCheckIsFIle", ThisObject, Context, 
			"OpenExplorerOnProcessError", ThisObject);
		FileInfo.BeginCheckingIsFile(Notification);
	Else 
		ErrorDescription = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Не найдена папка, которую требуется открыть в проводнике:
			           |""%1""'; 
			           |en = 'Cannot find the directory to open:
			           |%1.'; 
			           |pl = 'Nie wyszukano folder, który trzeba otworzyć w przewodniku:
			           |""%1""';
			           |de = 'Der Ordner, den Sie im Explorer öffnen möchten, wird nicht gefunden:
			           |""%1""';
			           |ro = 'Nu a fost găsit folderul care trebuie deschis în conductor:
			           |""%1""';
			           |tr = 'Dosya gezgininde açmak istediğiniz klasör bulunamadı: 
			           | ""%1""'; 
			           |es_ES = 'No se ha encontrado carpeta que se requiere abrir en el explorador:
			           |""%1""'"),
			FileInfo.FullName);
		OpenExplorerNotifyOnError(ErrorDescription, Context);
	EndIf;
	
EndProcedure

// Continue the CommonClient.OpenExplorer procedure.
Procedure OpenExplorerAfterCheckIsFIle(IsFile, Context) Export 
	
	// CAC:534-off safe start methods are provided with this function
	
	FileInfo = Context.FileInfo;
	
	Notification = New NotifyDescription(,,, "OpenExplorerOnProcessError", ThisObject);
	If IsFile Then
		If CommonClient.IsWindowsClient() Then
			BeginRunningApplication(Notification, "explorer.exe /select, """ + FileInfo.FullName + """");
		Else // It is Linux or MacOS.
			BeginRunningApplication(Notification, "file:///" + FileInfo.Path);
		EndIf;
	Else // It is a directory.
		BeginRunningApplication(Notification, "file:///" + FileInfo.FullName);
	EndIf;
	
	// CAC:534-enable
	
EndProcedure

// Continue the CommonClient.OpenExplorer procedure.
Procedure OpenExplorerOnProcessError(ErrorInformation, StandardProcessing, Context) Export 
	
	StandardProcessing = False;
	OpenExplorerNotifyOnError("", Context);
	
EndProcedure

// Continue the CommonClient.OpenExplorer procedure.
Procedure OpenExplorerNotifyOnError(ErrorDescription, Context)
	
	If Not IsBlankString(ErrorDescription) Then 
		ShowMessageBox(, ErrorDescription);
	EndIf;
	
EndProcedure

#EndRegion

#Region OpenURL

// Continue the CommonClient.OpenURL procedure.
Procedure OpenURLAfterCheckFileSystemExtension(ExtensionAttached, Context) Export
	
	// CAC:534-off safe start methods are provided with this function
	
	URL = Context.URL;
	
	If ExtensionAttached Then
		
		Notification          = Context.Notification;
		WaitForCompletion = (Notification <> Undefined);
		
		Notification = New NotifyDescription(
			"OpenURLAfterStartApplication", ThisObject, Context,
			"OpenURLOnProcessError", ThisObject);
		BeginRunningApplication(Notification, URL,, WaitForCompletion);
		
	Else
		ErrorDescription = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Расширение для работы с файлами не установлено, переход по ссылке ""%1"" невозможен.'; en = 'Cannot follow the link ""%1"" because the file system extension is not installed.'; pl = 'Rozszerzenie do pracy z plikami nie jest ustanowione, przejście pod linkiem ""%1"" jest niemożliwe.';de = 'Die Erweiterung für die Arbeit mit Dateien ist nicht installiert, der Link ""%1"" ist nicht möglich.';ro = 'Extensia pentru lucrul cu fișierele nu este instalată, nu puteți urma linkul ""%1"".';tr = 'Dosya uzantısı yüklü değil, ""%1"" bağlantısına geçilemez.'; es_ES = 'La extensión para usar los archivos no está instalada, no se puede pasar por el enlace ""%1"".'"),
			URL);
		OpenURLNotifyOnError(ErrorDescription, Context);
	EndIf;
	
	// CAC:534-enable
	
EndProcedure

// Continue the CommonClient.OpenURL procedure.
Procedure OpenURLAfterStartApplication(ReturnCode, Context) Export 
	
	Notification = Context.Notification;
	
	If Notification <> Undefined Then 
		ApplicationStarted = (ReturnCode = 0 Or ReturnCode = Undefined);
		ExecuteNotifyProcessing(Notification, ApplicationStarted);
	EndIf;
	
EndProcedure

// Continue the CommonClient.OpenURL procedure.
Procedure OpenURLOnProcessError(ErrorInformation, StandardProcessing, Context) Export 
	
	StandardProcessing = False;
	OpenURLNotifyOnError("", Context);
	
EndProcedure

// Continue the CommonClient.OpenURL procedure.
Procedure OpenURLNotifyOnError(ErrorDescription, Context) Export
	
	Notification = Context.Notification;
	
	If Notification = Undefined Then
		If Not IsBlankString(ErrorDescription) Then 
			ShowMessageBox(, ErrorDescription);
		EndIf;
	Else 
		ApplicationStarted = False;
		ExecuteNotifyProcessing(Notification, ApplicationStarted);
	EndIf;
	
EndProcedure

// Checks whether the passed string is a web URL.
// 
// Parameters:
//  String - String - passed URL.
//
Function IsWebURL(String) Export
	
	Return StrStartsWith(String, "http://")  // a usual connection.
		Or StrStartsWith(String, "https://");// a secure connection.
	
EndFunction

// Checks whether the passed string is a reference to the online help.
// 
// Parameters:
//  String - String - passed URL.
//
Function IsHelpRef(String) Export
	
	Return StrStartsWith(String, "v8help://");
	
EndFunction

// Checks whether the passed string is a valid reference to the protocol whitelist.
// 
// Parameters:
//  String - String - passed URL.
//
Function IsAllowedRef(String) Export
	
	Return StrStartsWith(String, "e1c:")
		Or StrStartsWith(String, "e1cib/")
		Or StrStartsWith(String, "e1ccs/")
		Or StrStartsWith(String, "v8help:")
		Or StrStartsWith(String, "http:")
		Or StrStartsWith(String, "https:")
		Or StrStartsWith(String, "mailto:")
		Or StrStartsWith(String, "tel:")
		Or StrStartsWith(String, "skype:");
	
EndFunction

#EndRegion

#Region StartApplication

// Continue the CommonClient.StartApplication procedure.
Procedure StartApplicationAfterCheckFileSystemExtension(ExtensionAttached, Context) Export
	
	If ExtensionAttached Then
		
		CurrentDirectory = Context.CurrentDirectory;
		
		If IsBlankString(CurrentDirectory) Then
			StartApplicationBeginRunning(Context);
		Else 
			FileInfo = New File(CurrentDirectory);
			Notification = New NotifyDescription(
				"StartApplicationAfterCheckIfExists", ThisObject, Context,
				"StartApplicationOnProcessError", ThisObject);
			FileInfo.BeginCheckingExistence(Notification);
		EndIf;
		
	Else
		ErrorDescription = NStr("ru = 'Расширение для работы с файлами не установлено, запуск программы невозможен.'; en = 'Cannot start the application because the file system extension is not installed.'; pl = 'Rozszerzenie do pracy z plikami nie jest ustanowione, uruchomienie programu jest niemożliwe.';de = 'Die Dateierweiterung ist nicht installiert, das Programm kann nicht gestartet werden.';ro = 'Extensia pentru lucrul cu fișierele nu este instalată, programul nu poate fi lansat.';tr = 'Dosya işlemi uzantısı yüklü değil, uygulama başlatılamıyor.'; es_ES = 'La extensión del uso de archivos no está instalada, no se puede iniciar el programa.'");
		StartApplicationNotifyOnError(ErrorDescription, Context);
	EndIf;
	
EndProcedure

// Continue the CommonClient.StartApplication procedure.
Procedure StartApplicationAfterCheckIfExists(Exists, Context) Export
	
	CurrentDirectory = Context.CurrentDirectory;
	FileInfo = New File(CurrentDirectory);
	
	If Exists Then 
		Notification = New NotifyDescription(
			"StartApplicationAfterCheckIsDirectory", ThisObject, Context,
			"StartApplicationOnProcessError", ThisObject);
		FileInfo.BeginCheckingIsDirectory(Notification);
	Else 
		CommandRow = Context.CommandString;
		
		ErrorDescription = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Не удалось запустить программу
			           |%1
			           |по причине:
			           |Не существует каталог, указанный как ТекущийКаталог
			           |%2'; 
			           |en = 'Cannot start the application
			           |%1.
			           |Reason:
			           |The catalog that is specified as CurrentDirectory does not exist:
			           |%2'; 
			           |pl = 'Nie można uruchomić programu
			           |%1
			           |z powodu:
			           |Brak katalogu określonego, jako CurrentDirectory
			           |%2';
			           |de = 'Das Programm
			           |%1
			           |konnte nicht gestartet werden, weil:
			           |Es ist kein Verzeichnis als CurrentDirectory angegeben
			           |%2';
			           |ro = 'Eșec la lansarea aplicației
			           |%1
			           |din motivul:
			           |Nu există catalogul indicat ca CurrentDirectory
			           |%2';
			           |tr = 'Program aşağıdaki nedenle başlatılamadı
			           |%1
			           |:
			           |CurrentDirectory olarak belirtilen dizin mevcut değil
			           |%2'; 
			           |es_ES = 'No se ha podido lanzar el programa
			           |%1
			           |a causa de:
			           |No existe catálogo indicado como CurrentDirectory
			           |%2'"),
			CommandRow,
			CurrentDirectory);
		StartApplicationNotifyOnError(ErrorDescription, Context);
	EndIf;
	
EndProcedure

// Continue the CommonClient.OpenFileInViewer procedure.
Procedure StartApplicationAfterCheckIsDirectory(IsDirectory, Context) Export
	
	If IsDirectory Then
		StartApplicationBeginRunning(Context);
	Else
		CommandRow = Context.CommandString;
		CurrentDirectory = Context.CurrentDirectory;
		
		ErrorDescription = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Не удалось запустить программу
			           |%1
			           |по причине:
			           |ТекущийКаталог не является каталогом %2'; 
			           |en = 'Cannot start the application
			           |%1.
			           |Reason:
			           |CurrentDirectory is not a directory: %2'; 
			           |pl = 'Nie można uruchomić programu
			           |%1
			           |z powodu:
			           |CurrentDirectory nie jest katalogiem %2';
			           |de = 'Das Programm
			           |%1
			           |konnte nicht gestartet werden, weil:
			           |Das CurrentDirectory ist kein Verzeichnis %2';
			           |ro = 'Eșec la lansarea programului
			           |%1
			           |fin motivul:
			           |CurrentDirectory nu este catalog %2';
			           |tr = 'Program aşağıdaki nedenle başlatılamadı
			           |%1
			           |:
			           |CurrentDirectory bir dizin değildir%2'; 
			           |es_ES = 'No se ha podido lanzar el programa
			           |%1
			           |a causa de:
			           |CurrentDirectory no es catálogo %2'"),
			CommandRow,
			CurrentDirectory);
		StartApplicationNotifyOnError(ErrorDescription, Context);
	EndIf;
	
EndProcedure

// Continue the CommonClient.StartApplication procedure.
Procedure StartApplicationBeginRunning(Context)
	
	// CAC:534-off safe start methods are provided with this function
	
	If Context.ExecuteWithFullRights Then 
		StartApplicationWithFullRights(Context);
	Else
		
		CommandRow = Context.CommandString;
		CurrentDirectory = Context.CurrentDirectory;
		WaitForCompletion = Context.WaitForCompletion;
		
		Notification = New NotifyDescription(
			"StartApplicationAfterStartApplication", ThisObject, Context,
			"StartApplicationOnProcessError", ThisObject);
		BeginRunningApplication(Notification, CommandRow, CurrentDirectory, WaitForCompletion);
	EndIf;
	
	// CAC:534-enable
	
EndProcedure

// Continue the CommonClient.StartApplication procedure.
Procedure StartApplicationAfterStartApplication(ReturnCode, Context) Export 
	
	Notification = Context.Notification;
	If Notification = Undefined Then
		Return;
	EndIf;
		
	If Context.WaitForCompletion AND ReturnCode = Undefined Then
		ErrorDescription = NStr("ru = 'Произошла неизвестная ошибка при запуске программы.'; en = 'Unknown error occurred while starting the application.'; pl = 'Wystąpił nieznany błąd podczas uruchomienia programu.';de = 'Beim Start des Programms ist ein unbekannter Fehler aufgetreten.';ro = 'Eroare necunoscută la lansarea programului.';tr = 'Uygulama başlatıldığında bilinmeyen bir hata oluştu.'; es_ES = 'Se ha producido un error desconocido al iniciar el programa.'");
		StartApplicationNotifyOnError(ErrorDescription, Context);
		Return;
	EndIf;
	
	Result = ApplicationStartResult();
	Result.ApplicationStarted = True;
	Result.ReturnCode = ReturnCode;
	If Context.WaitForCompletion Then
		FillThreadResult(Result, Context);
	EndIf;
	ExecuteNotifyProcessing(Notification, Result);
	
EndProcedure

// Continue the CommonClient.StartApplication procedure.
Procedure StartApplicationOnProcessError(ErrorInformation, StandardProcessing, Context) Export 
	
	StandardProcessing = False;
	ErrorDescription = BriefErrorDescription(ErrorInformation);
	StartApplicationNotifyOnError(ErrorDescription, Context);
	
EndProcedure

// Continue the CommonClient.StartApplication procedure.
Procedure StartApplicationNotifyOnError(ErrorDescription, Context)
	
	Notification = Context.Notification;
	If Notification = Undefined Then
		If Not IsBlankString(ErrorDescription) Then
			ShowMessageBox(, ErrorDescription);
		EndIf;
		Return;
	EndIf;
		
	Result = ApplicationStartResult();
	Result.ErrorDescription = ErrorDescription;
	If Context.WaitForCompletion Then
		FillThreadResult(Result, Context);
	EndIf;
	ExecuteNotifyProcessing(Notification, Result);
	
EndProcedure

// Continue the CommonClient.StartApplication procedure.
Function ApplicationStartResult()
	
	Result = New Structure;
	Result.Insert("ApplicationStarted", False);
	Result.Insert("ErrorDescription", "");
	Result.Insert("ReturnCode", -13);
	Result.Insert("OutputStream", "");
	Result.Insert("ErrorStream", "");
	
	Return Result;
	
EndFunction

// Continue the CommonClient.StartApplication procedure.
Procedure StartApplicationWithFullRights(Context)
	
#If WebClient Then
	ErrorDescription = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("ru = 'Не удалось запустить программу
		           |%1
		           |по причине:
		           |Запуск программ с повышением привилегий недоступен в веб-клиенте.'; 
		           |en = 'Cannot start the application
		           |%1.
		           |Reason:
		           |The web client does not support starting applications with elevated privileges.'; 
		           |pl = 'Nie można uruchomić programu
		           |%1
		           |z powodu:
		           |Uruchamianie programów z podwyższeniem uprawnień nie jest dostępne w kliencie www.';
		           |de = 'Das Programm
		           |%1
		           |konnte nicht gestartet werden, weil:
		           |Das Starten von Programmen mit Privilegienerweiterung ist im Webclient nicht möglich.';
		           |ro = 'Eșec la lansarea aplicației
		           |%1
		           |din motivul:
		           |Lansarea aplicațiilor cu mărirea privilegiilor este inaccesibilă în web-client.';
		           |tr = '
		           |Program aşağıdaki nedenle %1
		           |başlatılamadı: 
		           |Web istemcide öncelikleri artıracak programların başlatılması.'; 
		           |es_ES = 'No se ha podido lanzar el programa
		           |%1
		           | a causa de:
		           |No está disponible lanzar los programas aumentando las privilegias en el cliente web.'"),
		Context.CommandString);
	StartApplicationNotifyOnError(ErrorDescription, Context);
#ElsIf MobileClient Then
	ErrorDescription = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("ru = 'Не удалось запустить программу
		           |%1
		           |по причине:
		           |Запуск программ с повышением привилегий недоступен в мобильном клиенте.'; 
		           |en = 'Cannot start the application
		           |%1.
		           |Reason:
		           |The web client does not support starting applications with elevated privileges.'; 
		           |pl = 'Nie można uruchomić programu
		           |%1
		           |z powodu:
		           |Uruchamianie programów z podwyższeniem uprawnień nie jest dostępne w kliencie mobilnym.';
		           |de = 'Das Programm
		           |%1
		           |konnte nicht gestartet werden, weil:
		           |Das Starten von Programmen mit erweiterten Rechten ist im mobilen Client nicht möglich.';
		           |ro = 'Eșec la lansarea aplicației
		           |%1
		           |din motivul:
		           |Lansarea aplicațiilor cu mărirea privilegiilor este inaccesibilă în clientul mobil.';
		           |tr = '
		           |Program aşağıdaki nedenle %1
		           |başlatılamadı: 
		           |Web istemcide öncelikleri artıracak programların başlatılması.'; 
		           |es_ES = 'No se ha podido lanzar el programa
		           |%1
		           | a causa de:
		           |No está disponible lanzar los programas aumentando las privilegias en el cliente móvil.'"),
		Context.CommandString);
	StartApplicationNotifyOnError(ErrorDescription, Context);
#Else
	
	If CommonClient.IsWindowsClient() Then 
		StartApplicationWithFullWindowsRights(Context);
	ElsIf CommonClient.IsLinuxClient() Then 
		StartApplicationWithFullLinuxRights(Context);
	Else
		ErrorDescription = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Не удалось запустить программу
			           |%1
			           |по причине:
			           |Запуск программ с повышением привилегий доступен только в Windows и Linux.'; 
			           |en = 'Cannot start the application
			           |%1.
			           |Reason:
			           |Starting applications with elevated privileges is supported for Windows and Linux only.'; 
			           |pl = 'Nie można uruchomić programu
			           |%1
			           |z powodu:
			           |Uruchamianie programów z podwyższeniem uprawnień jest dostępne tylko w Windows i Linux.';
			           |de = 'Das Programm
			           |%1
			           |konnte nicht gestartet werden, weil:
			           |Das Ausführen von Programmen mit Privilegienerweiterung ist nur unter Windows und Linux möglich.';
			           |ro = 'Eșec la lansarea aplicației
			           |%1
			           |din motivul:
			           |Lansarea aplicațiilor cu mărirea privilegiilor este accesibilă numai în Windows sau Linux.';
			           |tr = 'Program başlatılamadıbu nedenle: 
			           |ayrıcalık yükselterek programları %1çalıştırmak yalnızca Windows ve Linux''ta kullanılabilir.
			           |
			           |'; 
			           |es_ES = 'No se ha podido lanzar el programa
			           |%1
			           |a causa de:
			           |Está disponible lanzar os programas aumentando las privilegias solo en Windows y Linux.'"),
			Context.CommandString);
		StartApplicationNotifyOnError(ErrorDescription, Context);
	EndIf;
	
#EndIf
	
EndProcedure

// Continue the CommonClient.StartApplication procedure.
Procedure FillThreadResult(Result, Context)
	
#If Not WebClient Then
		
	If Context.GetOutputStream
		AND Not IsBlankString(Context.OutputThreadFileName) Then
		Result.OutputStream = ReadThreadFile(Context.OutputThreadFileName);
	EndIf;
	
	If Context.GetErrorStream
		AND Not IsBlankString(Context.ErrorsThreadFileName) Then
		Result.ErrorStream = ReadThreadFile(Context.ErrorsThreadFileName);
	EndIf;
		
#EndIf

EndProcedure

// Continue the CommonClient.StartApplication procedure.
Function ReadThreadFile(PathToFile)
	
	// CAC:566-off synchronous calls outside the thin client
	
#If WebClient Then
	Return "";
#Else
	ThreadFile = New File(PathToFile);
	If Not ThreadFile.Exist() Then
		Return "";
	EndIf;
	
	ReadThreadFile = New TextReader(PathToFile);
	Result = ReadThreadFile.Read();
	ReadThreadFile.Close();
	
	DeleteFiles(PathToFile);
	
	Return ?(Result = Undefined, "", Result);
#EndIf
	
	// ACC:566-disable
	
EndFunction

#If Not WebClient AND Not MobileClient Then

// Continue the CommonClient.StartApplication procedure.
Procedure StartApplicationWithFullWindowsRights(Context)
	
	// CAC:534-off safe start methods are provided with this function
	
	CommandRow = Context.CommandString;
	CurrentDirectory = Context.CurrentDirectory;
	ExecutionEncoding = Context.ExecutionEncoding;
	
	WaitForCompletion = False;
	
	CommandFileName = GetTempFileName("run.bat"); // CAC:441 is deleted automatically after the start.
	TextDocument = CommonInternalClientServer.NewWindowsCommandStartFile(
		CommandRow, CurrentDirectory, WaitForCompletion, ExecutionEncoding);
	TextDocument.Write(CommandFileName, TextEncoding.OEM);
	
	Try
		Shell = New COMObject("Shell.Application");
		// Start with passing the action verb (increasing privileges).
		ReturnCode = Shell.ShellExecute("cmd", "/c """ + CommandFileName + """",, "runas", 0);
		Shell = Undefined;
	Except
		Shell = Undefined;
		ErrorInformation = ErrorInfo();
		StandardProcessing = True;
		StartApplicationOnProcessError(ErrorInformation, StandardProcessing, Context);
		Return;
	EndTry;
	
	If ReturnCode = Undefined Then 
		ReturnCode = 0;
	EndIf;
	
	StartApplicationAfterStartApplication(ReturnCode, Context);
	
	// CAC:534-enable
	
EndProcedure

// Continue the CommonClient.StartApplication procedure.
Procedure StartApplicationWithFullLinuxRights(Context)
	
	// CAC:534-off safe start methods are provided with this function
	
	CurrentDirectory = Context.CurrentDirectory;
	CommandRow = Context.CommandString;
	
	CommandWithPrivilegesRaise = "pkexec env DISPLAY=$DISPLAY XAUTHORITY=$XAUTHORITY " + CommandRow;
	WaitForCompletion = True;
	
	Notification = New NotifyDescription(
		"StartApplicationAfterStartApplication", ThisObject, Context,
		"StartApplicationOnProcessError", ThisObject);
	BeginRunningApplication(Notification, CommandWithPrivilegesRaise, CurrentDirectory, WaitForCompletion);
	
	// CAC:534-enable
	
EndProcedure

#EndIf

#EndRegion

#Region ChooseDirectory

// The procedure that follows FileSystemClient.SelectDirectory.
Procedure SelectDirectoryOnAttachFileSystemExtension(ExtensionAttached, Context) Export
	
	If Not ExtensionAttached Then
		ExecuteNotifyProcessing(Context.CompletionHandler, "");
	EndIf;
	
	NotifyDescription = New NotifyDescription(
		"SelectDirectoryAtSelectionEnd", ThisObject, Context.CompletionHandler);
	
	Dialog = New FileDialog(FileDialogMode.ChooseDirectory);
	Dialog.Multiselect = False;
	If Not IsBlankString(Context.Title) Then
		Dialog.Title = Context.Title;
	EndIf;
	
	Dialog.Show(NotifyDescription);
	
EndProcedure

// The procedure that follows FileSystemClient.SelectDirectory.
Procedure SelectDirectoryAtSelectionEnd(DirectoriesArray, CompletionHandler) Export
	
	PathToDirectory = 
		?(DirectoriesArray = Undefined Or DirectoriesArray.Count() = 0,
			"", 
			DirectoriesArray[0]);
	
	ExecuteNotifyProcessing(CompletionHandler, PathToDirectory);
	
EndProcedure

#EndRegion

#Region ShowSelectionDialog

// The procedure that follows FileSystemClient.ShowSelectionDialog.
Procedure ShowSelectionDialogOnAttachFileSystemExtension(ExtensionAttached, Context) Export
	
	If Not ExtensionAttached Then
		ExecuteNotifyProcessing(Context.CompletionHandler, "");
	EndIf;
	
	Context.Dialog.Show(Context.CompletionHandler);
	
EndProcedure

#EndRegion

#Region FileSystemExtension

// The procedure that follows FileSystemClient.StartFileSystemExtensionAttaching.
Procedure StartFileSystemExtensionAttachingOnSetExtension(Attached, Context) Export
	
	// If the extension is already installed, there is no need to ask about it
	If Attached Then
		ExecuteNotifyProcessing(Context.NotifyDescriptionCompletion, "AttachmentNotRequired");
		Return;
	EndIf;
	
	// The extension is not available for the MacOS web client.
	If CommonClient.IsOSXClient() Then
		ExecuteNotifyProcessing(Context.NotifyDescriptionCompletion);
		Return;
	EndIf;
	
	ParameterName = "StandardSubsystems.SuggestFileSystemExtensionInstallation";
	FirstCallDuringSession = ApplicationParameters[ParameterName] = Undefined;
	If ApplicationParameters[ParameterName] = Undefined Then
		ApplicationParameters.Insert(ParameterName, SuggestFileSystemExtensionInstallation());
	EndIf;
	
	SuggestFileSystemExtensionInstallation = ApplicationParameters[ParameterName] Or FirstCallDuringSession;
	If Context.CanContinueWithoutInstalling AND Not SuggestFileSystemExtensionInstallation Then
		
		ExecuteNotifyProcessing(Context.NotifyDescriptionCompletion);
		
	Else 
		
		FormParameters = New Structure;
		FormParameters.Insert("SuggestionText", Context.SuggestionText);
		FormParameters.Insert("CanContinueWithoutInstalling", Context.CanContinueWithoutInstalling);
		OpenForm(
			"CommonForm.FileSystemExtensionInstallationQuestion", 
			FormParameters,,,,, 
			Context.NotifyDescriptionCompletion);
		
	EndIf;
	
EndProcedure

// The procedure that follows FileSystemClient.StartFileSystemExtensionAttaching.
Procedure StartFileSystemExtensionAttachingWhenAnsweringToInstallationQuestion(Action, ClosingNotification) Export
	
	ExtensionAttached = (Action = "ExtensionAttached" Or Action = "AttachmentNotRequired");
	
#If WebClient Then
	If Action = "DoNotPrompt"
		Or Action = "ExtensionAttached" Then
		
		SystemInfo = New SystemInfo();
		ClientID = SystemInfo.ClientID;
		ApplicationParameters["StandardSubsystems.SuggestFileSystemExtensionInstallation"] = False;
		CommonServerCall.CommonSettingsStorageSave(
			"ApplicationSettings/SuggestFileSystemExtensionInstallation", ClientID, False);
		
	EndIf;
#EndIf
	
	ExecuteNotifyProcessing(ClosingNotification, ExtensionAttached);
	
EndProcedure

// The procedure that follows FileSystemClient.StartFileSystemExtensionAttaching.
Function SuggestFileSystemExtensionInstallation()
	
	SystemInformation = New SystemInfo();
	ClientID = SystemInformation.ClientID;
	Return CommonServerCall.CommonSettingsStorageLoad(
		"ApplicationSettings/SuggestFileSystemExtensionInstallation", ClientID, True);
	
EndFunction

#EndRegion

#Region TemporaryFiles

#Region CreateTemporaryDirectory

// The procedure that follows FileSystemClient.CreateTemporaryDirectory.
Procedure CreateTemporaryDirectoryAfterCheckFileSystemExtension(ExtensionAttached, Context) Export
	
	If ExtensionAttached Then
		
		Notification = New NotifyDescription(
			"CreateTemporaryDirectoryAfterGetTemporaryDirectory", ThisObject, Context,
			"CreateTemporaryDirectoryOnProcessError", ThisObject);
		
		BeginGettingTempFilesDir(Notification);
		
	Else
		ErrorDescription = 
			NStr("ru = 'Расширение для работы с файлами не установлено, создание временного каталога невозможно.'; en = 'Cannot create temporary directories because the file system extension is not installed.'; pl = 'Rozszerzenie do pracy z plikami nie jest ustanowione, tworzenie tymczasowego katalogu jest niemożliwe.';de = 'Erweiterung für die Arbeit mit Dateien ist nicht installiert, die Erstellung eines temporären Verzeichnisses ist nicht möglich.';ro = 'Extensia pentru lucrul cu fișierele nu este instalată, directorul temporar nu poate fi creat.';tr = 'Dosya işlemi uzantısı yüklü değil, geçici katalog açılamıyor.'; es_ES = 'La extensión del uso de archivos no está instalada, no se puede crear un catálogo temporal.'");
		CreateTemporaryDirectoryNotifyOnError(ErrorDescription, Context);
	EndIf;
	
EndProcedure

// The procedure that follows FileSystemClient.CreateTemporaryDirectory.
Procedure CreateTemporaryDirectoryAfterGetTemporaryDirectory(TemporaryFileDirectoryName, Context) Export 
	
	Notification = Context.Notification;
	Extension = Context.Extension;
	
	DirectoryName = "v8_" + String(New UUID);
	
	If Not IsBlankString(Extension) Then 
		DirectoryName = DirectoryName + "." + Extension;
	EndIf;
	
	BeginCreatingDirectory(Notification, TemporaryFileDirectoryName + DirectoryName);
	
EndProcedure

// The procedure that follows FileSystemClient.CreateTemporaryDirectory.
Procedure CreateTemporaryDirectoryOnProcessError(ErrorInformation, StandardProcessing, Context) Export 
	
	StandardProcessing = False;
	ErrorDescription = BriefErrorDescription(ErrorInformation);
	CreateTemporaryDirectoryNotifyOnError(ErrorDescription, Context);
	
EndProcedure

// The procedure that follows FileSystemClient.CreateTemporaryDirectory.
Procedure CreateTemporaryDirectoryNotifyOnError(ErrorDescription, Context)
	
	ShowMessageBox(, ErrorDescription);
	DirectoryName = "";
	ExecuteNotifyProcessing(Context.Notification, DirectoryName);
	
EndProcedure

#EndRegion

#EndRegion

#EndRegion