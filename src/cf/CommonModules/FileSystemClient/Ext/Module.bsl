///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Public

#Region FilesImport

// Shows a file selection dialog box and places the selected file into a temporary storage.
// This method provides the functionality of both BeginPutFile and BeginPuttingFiles global context 
// methods. Its return value is not affected by availability of the file system extension.
// Restrictions:
//   Not used to select catalogs -this option is not supported in the web client mode.
//
// Parameters:
//   CompletionHandler- NotifyDescription - contains the description of the procedure that will be 
//                             called after the file with the following parameters will be imported:
//      * FileThatWasPut - Undefined - a user canceled the selection.
//                        - Structure    - user has selected a file.
//                            ** Storage - String - placing data to a temporary storage.
//                            ** Name      - String - a local path, by which a file must be retrieved.
//      * AdditionalParameters - Arbitrary - value that was specified when creating object
//                                NotifyDescription.
//   ImportParameters         - Structure - see FileSystemClient.FileImportParameters. 
//   FileName                  - String - the full path to the file that will be offered to the user 
//                             at the beginning of interactive selection or will be put to the temporary storage in noninteractive. 
//                             If noninteractive mode is selected and the parameter is not filled, an exception will be called.
//   AddressInTempStorage - String - the address where the file will be saved.
//
// Example:
//   Notification = New NotifyDescription("SelectFileAfterPutFiles", ThisObject, Context);
//   ImportParameters = FileSystemClient.FileImportParameters();
//   ImportParameters.FormID = UUID;
//   FileSystemClient.ImportFile(Notification, ImportParameters);
//
Procedure ImportFile(
		CompletionHandler, 
		ImportParameters = Undefined, 
		FileName = "",
		AddressInTempStorage = "") Export
	
	If ImportParameters = Undefined Then
		ImportParameters = FileImportParameters();
	ElsIf Not ImportParameters.Interactively
		AND IsBlankString(FileName) Then
		Raise NStr("ru ='Не указано имя файла для загрузки в неинтерактивном режиме.'; en = 'Import in non-interactive mode failed. The name of the file to import is not specified.'; pl = 'Nazwa pliku nie została podana dla uruchamiania w trybie nieinteraktywnym.';de = 'Für den Download im nicht interaktiven Modus ist kein Dateiname angegeben.';ro = 'Nu este indicat numele fișierului pentru încărcare în regim interactiv.';tr = 'İnteraktif olmayan modda içe aktarılacak dosyanın adı belirtilmedi.'; es_ES = 'El nombre de archivo no está indicado para cargar en el modo no interactivo.'");
	EndIf;
	
	If Not ValueIsFilled(ImportParameters.FormID) Then
		ImportParameters.FormID = New UUID;
	EndIf;
	
	FileDetails    = New TransferableFileDescription(FileName, AddressInTempStorage);
	FilesToUpload = New Array;
	FilesToUpload.Add(FileDetails);
	ImportParameters.Insert("FilesToUpload", FilesToUpload);
	
	ImportParameters.Dialog.FullFileName     = FileName;
	ImportParameters.Dialog.Multiselect = False;
	ShowPutFile(CompletionHandler, ImportParameters);
	
EndProcedure

// Shows a file selection dialog and puts the selected files to a temporary storage.
// This method provides the functionality of both BeginPutFile and BeginPuttingFiles global context 
// methods. Its return value is not affected by availability of the file system extension.
// Restrictions:
//   Not used to select catalogs -this option is not supported in the web client mode.
//   Multiple selection in the web client is only supported if the file system extension is available.
//
// Parameters:
//   CompletionHandler - NotifyDescription - contains the description of the procedure that will be 
//                             called after the files with the following parameters will be imported:
//      * FilesThatWerePut - Undefined - a user canceled the selection.
//                        - Array - contains objects of the TransferredFileDescription type. The user selected the file.
//                           ** Storage - String - placing data to a temporary storage.
//                           ** Name      - String - a local path, by which a file must be retrieved.
//      * AdditionalParameters - Arbitrary - a value that was specified when creating the NotifyDescription object.
//   ImportParameters    - Structure - see FileSystemClient.FileImportParameters. 
//   FilesToUpload     - Array - contains objects of the TransferableFileDetails type. Can be filled 
//                        completely. In this case the files being imported will be saved to the specified addresses. 
//                        Can be filled partially. Only the names of the array items are filled. In 
//                        this case the files being imported will be placed in new temporary storages. Array can be empty. 
//                        In this case the files to put are defined by the values specified in the ImportParameters parameter. 
//                        If noninteractive mode is selected in import parameters, and the 
//                        FilesToUpload parameter is not filled, an exception will be called.
//
// Example:
//   Notification = New NotifyDescription("LoadExtensionAfterPutFiles", ThisObject, Context);
//   ImportParameters = FileSystemClient.FileImportParameters();
//   ImportParameters.FormID = UUID;
//   FileSystemClient.ImportFiles(Notification, ImportParameters);
//
Procedure ImportFiles(
		CompletionHandler, 
		ImportParameters = Undefined,
		FilesToUpload = Undefined) Export
	
	If ImportParameters = Undefined Then
		ImportParameters = FileImportParameters();
	EndIf;
	
	If Not ImportParameters.Interactively
		AND (FilesToUpload = Undefined 
		Or (TypeOf(FilesToUpload) = Type("Array")
		AND FilesToUpload.Count() = 0)) Then
		
		Raise NStr("ru ='Не указаны файлы для загрузки в неинтерактивном режиме.'; en = 'Import in non-interactive mode failed. The files to import are not specified.'; pl = 'Pliki nie zostały podane do pobrania w trybie nieinteraktywnym.';de = 'Dateien zum Herunterladen im nicht interaktiven Modus sind nicht angegeben.';ro = 'Nu sunt indicate fișierele pentru încărcare în regim neinteractiv.';tr = 'İnteraktif olmayan modda içe aktarılacak dosyaların adı belirtilmedi.'; es_ES = 'No están indicados los archivos para cargar en el modo no interactivo.'");
		
	EndIf;
	
	If FilesToUpload = Undefined Then
		FilesToUpload = New Array;
	EndIf;
	
	If Not ValueIsFilled(ImportParameters.FormID) Then
		ImportParameters.FormID = New UUID;
	EndIf;
	
	ImportParameters.Dialog.Multiselect = True;
	ImportParameters.Insert("FilesToUpload", FilesToUpload);
	ShowPutFile(CompletionHandler, ImportParameters);
	
EndProcedure

#EndRegion

#Region ModifiesStoredData

// Gets the file and saves it to the local file system of the user.
//
// Parameters:
//   CompletionHandler      - NotifyDescription, Undefined - contains the description of the 
//                             procedure that will be called after completion with the following parameters:
//      * ReceivedFiles         - Undefined - files are not received.
//                                - Array - contains objects of the TransferredFileDescription type. Saved files.
//      * AdditionalParameters - Arbitrary - a value that was specified when creating the NotifyDescription object.
//   AddressInTempStorage - String - placing data to a temporary storage.
//   FileName                  - String - a full path according to which the received file and the 
//                             file name with an extension must be saved.
//   SavingParameters       - Structure - see FileSystemClient.FileSavingParameters 
//
// Example:
//   Notification = New NotifyDescription("SaveCertificateAfterFilesReceipt", ThisObject, Context);
//   SavingParameters = FileSystemClient.FileSavingParameters();
//   FileSystemClient.SaveFile(Notification, Context.CertificateAddress, FileName, SavingParameters);
//
Procedure SaveFile(CompletionHandler, AddressInTempStorage, FileName = "",
	SavingParameters = Undefined) Export
	
	If SavingParameters = Undefined Then
		SavingParameters = FileSavingParameters();
	EndIf;
	
	FileData = New TransferableFileDescription(FileName, AddressInTempStorage);
	
	FilesToSave = New Array;
	FilesToSave.Add(FileData);
	
	ShowDownloadFiles(CompletionHandler, FilesToSave, SavingParameters);
	
EndProcedure

// Gets the files and saves them to the local file system of the user.
// To save files in noninteractive mode, the Name property of the FilesToSave parameter must have 
// the full path to the file being saved, or if the Name property contains only the file name with 
// extension, the Directory property of the Dialog item of the SavingParameters parameter is to be filled. 
// Otherwise, an exception will be called.
//
// Parameters:
//   CompletionHandler - NotifyDescription, Undefined - contains the description of the procedure 
//                             that will be called after completion with the following parameters:
//     * ReceivedFiles         - Undefined - files are not received.
//                               - Array - contains objects of the TransferredFileDescription type. Saved files.
//     * AdditionalParameters - Arbitrary - value that was specified when creating object
//                               NotifyDescription.
//   FilesToSave     - Array - contains objects of the TransferredFileDescription type.
//     * Storage - placing data to a temporary storage.
//     * Name      - String - a full path according to which the received file and the file name with an extension must be saved.
//   SavingParameters  - Structure - see FileSystemClient.FileSavingParameters 
//
// Example:
//   Notification = New NotifyDescription("SavePrintFormToFileAfterGetFiles", ThisObject);
//   SavingParameters = FileSystemClient.FilesSavingParameters();
//   FileSystemClient.SaveFiles(Notification, FilesToGet, SavingParameters);
//
Procedure SaveFiles(CompletionHandler, FilesToSave, SavingParameters = Undefined) Export
	
	If SavingParameters = Undefined Then
		SavingParameters = FilesSavingParameters();
	EndIf;
	
	ShowDownloadFiles(CompletionHandler, FilesToSave, SavingParameters);
	
EndProcedure

#EndRegion

#Region Parameters

// Initializes a parameter structure to import the file from the file system.
// To be used in FileSystemClient.ImportFile and FileSystemClient.ImportFiles
//
// Returns:
//  Structure - with the following properties:
//    * FormID - UUID - a UUID of the form used to put the file.
//                          If the parameter is filled, the DeleteFromTempStorage global context 
//                         method is to be called after completing the operation with the binary 
//                         data. Default value is Undefined.
//                         
//    * Interactively       - Boolean - indicates interactive mode usage when a file selection 
//                         dialog is showed to the user. Default value is True.
//                         
//    * Dialog             - FileSelectionDialog - for the properties, see the Syntax Assistant.
//                         It is used if an Interactively property takes a True value, and if the 
//                         file system extension was applied.
//    * SuggestionText   - String - a text of suggestion to install the extension. If the parameter 
//                         takes the value "", the standard suggestion text will be output.
//                         Default value is "".
//
// Example:
//  ImportParameters = FileSystemClient.FileImportParameters();
//  ImportParameters.Dialog.Title = NStr("en = 'Select a document'");
//  ImportParameters.Dialog.Filter = NStr("en = 'MS Word files (*.doc;*.docx)|*.doc;*.docx|All files(*.*)|*.*'");
//  FileSystemClient.ImportFile(Notification, ImportParameters);
//
Function FileImportParameters() Export
	
	ImportParameters = OperationContext(FileDialogMode.Open);
	ImportParameters.Insert("FormID", Undefined);
	Return ImportParameters;
	
EndFunction

// Initializes a parameter structure to save the file to the file system.
// To be used in FileSystemClient.SaveFile.
//
// Returns:
//  Structure - with the following properties:
//    * Interactively     - Boolean - indicates interactive mode usage when a file selection dialog 
//                       is showed to the user. Default value is True.
//                       
//    * Dialog           - FileSelectionDialog - for the properties, see the Syntax Assistant.
//                       It is used if an Interactively property takes a True value, and if the file 
//                       system extension was applied.
//    * SuggestionText - String - a text of suggestion to install the extension. If the parameter 
//                       takes the value "", the standard suggestion text will be output.
//                       Default value is "".
//
// Example:
//  SavingParameters = FileSystemClient.FileSavingParameters();
//  SavingParameters.Dialog.Title = NStr("en = 'Save key operation profile to file");
//  SavingParameters.Dialog.Filter = "Key operation profile files (*.xml)|*.xml";
//  FileSystemClient.SaveFile(Undefined, SaveKeyOperationsProfileToServer(), , SavingParameters);
//
Function FileSavingParameters() Export
	
	Return OperationContext(FileDialogMode.Save);
	
EndFunction

// Initializes a parameter structure to save the file to the file system.
// To be used in FileSystemClient.SaveFiles.
//
// Returns:
//  Structure - with the following properties:
//    * Interactively     - Boolean - indicates interactive mode usage when a file selection dialog 
//                       is showed to the user. Default value is True.
//                       
//    * Dialog           - FileSelectionDialog - for the properties, see the Syntax Assistant.
//                       It is used if an Interactively property takes a True value, and if the file 
//                       system extension was applied.
//    * SuggestionText - String - a text of suggestion to install the extension. If the parameter 
//                       takes the value "", the standard suggestion text will be output.
//                       Default value is "".
//
// Example:
//  SavingParameters = FileSystemClient.FilesSavingParameters();
//  SavingParameters.Dialog.Title = NStr("en ='Select a folder to save generated document'");
//  FileSystemClient.SaveFiles(Notification, FilesToGet, SavingParameters);
//
Function FilesSavingParameters() Export
	
	Return OperationContext(FileDialogMode.ChooseDirectory);
	
EndFunction

// Initializes a parameter structure to open the file.
// To be used in FileSystemClient.OpenFile.
//
// Returns:
//  Structure - with the following properties:
//    *Encoding         - String - a text file encoding. If the parameter is not specified, the text 
//                       format will be determined automatically. See the code list in the Syntax 
//                       Assistant in the Write method details of the text document. Default value is "".
//    *ForEditing - Boolean - True to open the file for editing, False otherwise. If the parameter 
//                       takes the True value, waiting for application closing, and if in the
//                       FileLocation parameter the address is stored in the temporary storage, it updates the file data.
//                       Default value is False.
//
Function FileOpeningParameters() Export
	
	Context = New Structure;
	Context.Insert("Encoding", "");
	Context.Insert("ForEditing", False);
	Return Context;
	
EndFunction

#EndRegion

#Region RunExternalApplications

// Opens a file for viewing or editing.
// If the file is opened from the binary data in a temporary storage, it is previously saved to the 
// temporary directory.
//
// Parameters:
//  FileLocation    - String - the full path to the file in the file system or a file data address 
//                       in a temporary storage.
//  CompletionHandler - NotifyDescription, Undefined - the description of the procedure that gets 
//                       the method result with the following parameters:
//    * FileIsChanged             - Boolean - the file is changed on a hard drive or the binary data in a temporary storage.
//    * AdditionalParameters - Arbitrary - value that was specified when creating object
//                              NotifyDescription.
//  FileName             - String - the name of the file with an extension or the file extension without the dot. 
//                       If the FileLocation parameter contains the address in a temporary storage and the parameter
//                       FileName is empty, an exception is thrown.
//  OpeningParameters    - Structure - see FileSystemClient.FileOpeningParameters. 
//
Procedure OpenFile(
		FileLocation,
		CompletionHandler = Undefined,
		FileName = "",
		OpeningParameters = Undefined) Export
		
	If OpeningParameters = Undefined Then
		OpeningParameters = FileOpeningParameters();
	EndIf;
	
	OpeningParameters.Insert("CompletionHandler", CompletionHandler);
	If IsTempStorageURL(FileLocation) Then
		
		If IsBlankString(FileName) Then
			Raise NStr("ru ='Не указано имя файла.'; en = 'The file name is not specified.'; pl = 'Nazwa pliku nie jest określona.';de = 'Der Dateiname ist nicht angegeben.';ro = 'Numele fișierului nu este specificat.';tr = 'Dosya adı belirlenmedi.'; es_ES = 'No está indicado nombre del archivo.'");
		EndIf;
		
		PathToFile = TempFileFullName(FileName);
		
		OpeningParameters.Insert("PathToFile", PathToFile);
		OpeningParameters.Insert("AddressOfBinaryDataToUpdate", FileLocation);
		OpeningParameters.Insert("DeleteAfterDataUpdate", True);
		
		SavingParameters = FileSavingParameters();
		SavingParameters.Interactively = False;
		
		NotifyDescription = New NotifyDescription(
			"OpenFileAfterSaving", FileSystemInternalClient, OpeningParameters);
		
		SaveFile(NotifyDescription, FileLocation, PathToFile, SavingParameters);
		
	Else
		FileSystemInternalClient.OpenFileAfterSaving(New Structure("Name", FileLocation), OpeningParameters);
	EndIf;
	
EndProcedure

// Opens Windows Explorer to the specified directory.
// If a file path is specified, the pointer is placed on the file.
//
// Parameters:
//  PathToDirectoryOrFile - String - the full path to a file or folder on the drive.
//
// Example:
//  // For Windows OS
//  FileSystemClient.OpenExplorer("C:\Users");
//  FileSystemClient.OpenExplorer("C:\Program Files\1cv8\common\1cestart.exe");
//  // For Linux OS
//  FileSystemClient.OpenExplorer("/home/");
//  FileSystemClient.OpenExplorer("/opt/1C/v8.3/x86_64/1cv8c");
//
Procedure OpenExplorer(PathToDirectoryOrFile) Export
	
	FileInfo = New File(PathToDirectoryOrFile);
	
	Context = New Structure;
	Context.Insert("FileInfo", FileInfo);
	
	Notification = New NotifyDescription(
		"OpenExplorerAfterCheckFileSystemExtension", FileSystemInternalClient, Context);
		
	SuggestionText = NStr("ru = 'Для открытия папки необходимо установить расширение работы с файлами.'; en = 'To be able to open directories, install the file system extension.'; pl = 'Dla otwarcia foldera należy zainstalować rozszerzenie pracy z plikami.';de = 'Um einen Ordner zu öffnen, müssen Sie die Dateierweiterung installieren.';ro = 'Pentru deschiderea folderului trebuie să instalați extensia de lucru cu fișierele.';tr = 'Klasörü açmak için, dosyalarla çalışmak için bir uzantı yüklenmelidir.'; es_ES = 'Para abrir la carpeta es necesario instalar la extensión de la operación de archivos.'");
	AttachFileOperationsExtension(Notification, SuggestionText, False);
	
EndProcedure

// Opens a URL in an application associated with URL protocol.
//
// Valid protocols: http, https, e1c, v8help, mailto, tel, skype.
//
// Do not use protocol file:// to open Explorer or a file.
// - To Open Explorer, use OpenExplorer. 
// - To open a file in an associated application, use OpenFileInViewer. 
//
// Parameters:
//  URL - Reference - a link to open.
//  Notification - NotifyDescription - notification on file open attempt.
//      If the notification is not specified and an error occurs, the method shows a warning.
//      - ApplicationStarted - Boolean - True if the external application opened successfully.
//      - AdditionalParameters - Arbitrary - a value that was specified when creating the NotifyDescription object.
//
// Example:
//  FileSystemClient.OpenURL("e1cib/navigationpoint/startpage"); // Home page.
//  FileSystemClient.OpenURL("v8help://1cv8/QueryLanguageFullTextSearchInData");
//  FileSystemClient.OpenURL("https://1c.ru");
//  FileSystemClient.OpenURL("mailto:help@1c.ru");
//  FileSystemClient.OpenURL("skype:echo123?call");
//
Procedure OpenURL(URL, Val Notification = Undefined) Export
	
	// CAC:534-off safe start methods are provided with this function
	
	Context = New Structure;
	Context.Insert("URL", URL);
	Context.Insert("Notification", Notification);
	
	ErrorDescription = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("ru = 'Не удалось перейти по ссылке ""%1"" по причине: 
		           |Неверно задана навигационная ссылка.'; 
		           |en = 'Cannot follow link %1.
		           |The URL is invalid.'; 
		           |pl = 'Nie udało się przejść pod linkiem ""%1"" z powodu: 
		           |Błędnie jest podany link nawigacyjny.';
		           |de = 'Konnte dem Link ""%1"" nicht folgen, weil: 
		           |Der Navigationslink wurde nicht korrekt gesetzt.';
		           |ro = 'Eșec de urmare a linkului ""%1"" din motivul: 
		           |Linkul de navigare este specificat incorect.';
		           |tr = 'Aşağıdaki nedenle ""%1"" linke geçemedi: 
		           |Gezinme bağlantısı yanlış ayarlandı.'; 
		           |es_ES = 'No se ha podido pasar por enlace ""%1"" a causa de: 
		           |Enlace de navegación está especificado incorrectamente.'"),
		URL);
	
	If Not FileSystemInternalClient.IsAllowedRef(URL) Then 
		
		FileSystemInternalClient.OpenURLNotifyOnError(ErrorDescription, Context);
		
	ElsIf FileSystemInternalClient.IsWebURL(URL)
		Or CommonInternalClient.IsURL(URL) Then 
		
		Try
		
#If ThickClientOrdinaryApplication Then
			
			// Platform design feature: GotoURL is not supported by ordinary applications running in the thick client mode.
			Notification = New NotifyDescription(
				,, Context,
				"OpenURLOnProcessError", FileSystemInternalClient);
			BeginRunningApplication(Notification, URL);
#Else
			GotoURL(URL);
#EndIf
			
			If Notification <> Undefined Then 
				ApplicationStarted = True;
				ExecuteNotifyProcessing(Notification, ApplicationStarted);
			EndIf;
			
		Except
			FileSystemInternalClient.OpenURLNotifyOnError(ErrorDescription, Context);
		EndTry;
		
	ElsIf FileSystemInternalClient.IsHelpRef(URL) Then 
		
		OpenHelp(URL);
		
	Else 
		
		Notification = New NotifyDescription(
			"OpenURLAfterCheckFileSystemExtension", FileSystemInternalClient, Context);
		
		SuggestionText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Для открытия ссылки ""%1"" необходимо установить расширение работы с файлами.'; en = 'To be able to open link ""%1"", install the file system extension.'; pl = 'Dla otwarcia linku ""%1"" należy zainstalować rozszerzenie pracy z plikami.';de = 'Um den Link ""%1"" zu öffnen, müssen Sie die Dateierweiterung installieren.';ro = 'Pentru deschiderea referinței ""%1"" trebuie să instalați extensia de lucru cu fișierele.';tr = '""%1"" linki açmak için, dosyalarla çalışma uzantısı yüklenmelidir.'; es_ES = 'Para abrir el enlace ""%1"" es necesario instalar la extensión de la operación de archivos.'"),
			URL);
		AttachFileOperationsExtension(Notification, SuggestionText, False);
		
	EndIf;
	
	// CAC:534-enable
	
EndProcedure

// Returns:
//  Structure - where:
//    * CurrentDirectory - String - sets the current directory of the application being started up.
//    * Notification - NotifyDescription - notification of the running application completion result, 
//          if the notification is not specified and an error occurs, the method shows a warning.
//          - Result - Structure - the application operation result:
//              -- ApplicationStarted - Boolean - True if the external application opened successfully.
//              -- ErrorDescription - String - a brief error description. Empty string on cancel by user.
//              -- ReturnCode - Number - the application return code.
//              -- OutputStream - String - the application result passed to stdout.
//                             Always takes a value "" in a web client.
//              -- ErrorStream - String - the application errors passed to stderr.
//                             Always takes a value "" in a web client.
//          - AdditionalParameters - Arbitrary - a value that was specified when creating the NotifyDescription object.
//    * WaitForCompletion - Boolean - True, wait for the running application to end before proceeding.
//    * GetOutputStream - Boolean - False - result is passed to stdout. Ignored if WaitForCompletion 
//         is not specified.
//    * GetErrorStream - Boolean - False - errors are passed to stderr stream. Ignored if 
//         WaitForCompletion is not specified.
//    * ExecutionEncoding - String, Number - an encoding set in Windows using the chcp command.
//          Ignored under Linux or MacOS. Possible values are: OEM, CP866, UTF8 or code page number.
//    * ExecuteWithFullRights - Boolean - True, if the application must be run with full system 
//          privileges:
//          - Windows: UAC query.
//          - Linux: execution with pkexec command.
//          - OSX, web client, and mobile client: will be returned Result.ErrorDescription.
//
Function ApplicationStartupParameters() Export
	
	Parameters = New Structure;
	Parameters.Insert("CurrentDirectory", "");
	Parameters.Insert("Notification", Undefined);
	Parameters.Insert("WaitForCompletion", True);
	Parameters.Insert("GetOutputStream", False);
	Parameters.Insert("GetErrorStream", False);
	Parameters.Insert("ExecutionEncoding", Undefined);
	Parameters.Insert("ExecuteWithFullRights", False);
	
	Return Parameters;
	
EndFunction

// Runs an external application using the startup parameters.
//
// Parameters:
//  StartupCommand - String - application startup command line.
//                 - Array - the first array element, the path to the application being executed,
//      if Array, the first array element is a path to the application being executed, the rest of 
//      the elements are its startup parameters. An array matches the one that the called application in argv will get.
//  ApplicationStartupParameters - Structure - see FileSystemClient.ApplicationStartupParameters 
//
Procedure StartApplication(Val StartupCommand, ApplicationStartupParameters = Undefined) Export
	
	If ApplicationStartupParameters = Undefined Then 
		ApplicationStartupParameters = ApplicationStartupParameters();
	EndIf;
	
	CommandRow = CommonInternalClientServer.SafeCommandString(StartupCommand);
	
	OutputThreadFileName = "";
	ErrorsThreadFileName = "";
	
#If Not WebClient Then
	If ApplicationStartupParameters.WaitForCompletion Then
		
		// CAC:441-off temporary files are deleted after the asynchronous operations
		
		If ApplicationStartupParameters.GetOutputStream Then
			OutputThreadFileName = GetTempFileName("stdout.tmp");
			CommandRow = CommandRow + " > """ + OutputThreadFileName + """";
		EndIf;
		
		If ApplicationStartupParameters.GetErrorStream Then 
			ErrorsThreadFileName = GetTempFileName("stderr.tmp");
			CommandRow = CommandRow + " 2> """ + ErrorsThreadFileName + """";
		EndIf;
		
		// CAC:441-enable
		
	EndIf;
#EndIf
	
	Context = New Structure;
	Context.Insert("CommandString", CommandRow);
	Context.Insert("CurrentDirectory", ApplicationStartupParameters.CurrentDirectory);
	Context.Insert("Notification", ApplicationStartupParameters.Notification);
	Context.Insert("WaitForCompletion", ApplicationStartupParameters.WaitForCompletion);
	Context.Insert("ExecutionEncoding", ApplicationStartupParameters.ExecutionEncoding);
	Context.Insert("GetOutputStream", ApplicationStartupParameters.GetOutputStream);
	Context.Insert("GetErrorStream", ApplicationStartupParameters.GetErrorStream);
	Context.Insert("OutputThreadFileName", OutputThreadFileName);
	Context.Insert("ErrorsThreadFileName", ErrorsThreadFileName);
	Context.Insert("ExecuteWithFullRights", ApplicationStartupParameters.ExecuteWithFullRights);
	
	Notification = New NotifyDescription(
		"StartApplicationAfterCheckFileSystemExtension", FileSystemInternalClient, Context);
	SuggestionText = 
		NStr("ru = 'Для создания временного каталога необходимо установить расширение работы с файлами.'; en = 'To be able to create temporary directories, install the file system extension.'; pl = 'W celu utworzenia tymczasowego katalogu należy zainstalować rozszerzenie pracy z plikami.';de = 'Um ein temporäres Verzeichnis zu erstellen, müssen Sie eine Dateierweiterung installieren.';ro = 'Pentru crearea directorului temporar trebuie să instalați extensia de lucru cu fișierele.';tr = 'Geçici dizini oluşturmak için, dosyalarla çalışmak için bir uzantı yüklenmelidir.'; es_ES = 'Para crear un catálogo temporal es necesario instalar la extensión del uso de archivos.'");
	AttachFileOperationsExtension(Notification, SuggestionText, False);
	
EndProcedure

#EndRegion

#Region Miscellaneous

// Calls directory selection dialog.
//
// Parameters:
//   CompletionHandler - NotifyDescription - contains the description of the procedure that will be 
//                        called after the selection dialog box is closed, with the following parameters:
//      - PathToDirectory - String - the full path to a directory. If the file system extension is 
//                        not set, or the user canceled the selection, returns the blank string.
//      - AdditionalParameters - a value that was specified on creating the NotifyDescription object.
//   Title - String - a title of the directory selection dialog.
//
Procedure SelectDirectory(CompletionHandler, Title = "") Export
	
	Context = New Structure;
	Context.Insert("CompletionHandler", CompletionHandler);
	Context.Insert("Title", Title);
	
	NotifyDescription = New NotifyDescription(
		"SelectDirectoryOnAttachFileSystemExtension", FileSystemInternalClient, Context);
	AttachFileOperationsExtension(NotifyDescription);
	
EndProcedure

// Shows a file selection dialog.
//
// Parameters:
//   CompletionHandler - NotifyDescription - contains the description of the procedure that will be 
//           called after the selection dialog box is closed, with the following parameters:
//   Dialog - FileSelectionDialog - for the properties, see the Syntax Assistant.
//
Procedure ShowSelectionDialog(CompletionHandler, Dialog) Export
	
	Context = New Structure;
	Context.Insert("CompletionHandler", CompletionHandler);
	Context.Insert("Dialog", Dialog);
	
	NotifyDescription = New NotifyDescription(
		"ShowSelectionDialogOnAttachFileSystemExtension", FileSystemInternalClient, Context);
	AttachFileOperationsExtension(NotifyDescription);
	
EndProcedure

// Gets temporary directory name.
//
// Parameters:
//  Notification - NotifyDescription - notification on getting directory name attempt with the following parameters.
//    - DirectoryName - String - path to the directory.
//    - AdditionalParameters - Structure - a value that was specified when creating the NotifyDescription object.
//  Extension - Sting - the suffix in the directory name, which helps to identify the directory for analysis.
//
Procedure CreateTemporaryDirectory(Val Notification, Extension = "") Export 
	
	Context = New Structure;
	Context.Insert("Notification", Notification);
	Context.Insert("Extension", Extension);
	
	Notification = New NotifyDescription("CreateTemporaryDirectoryAfterCheckFileSystemExtension",
		FileSystemInternalClient, Context);
		
	SuggestionText = NStr("ru = 'Для создания временного каталога необходимо установить расширение работы с файлами.'; en = 'To be able to create temporary directories, install the file system extension.'; pl = 'W celu utworzenia tymczasowego katalogu należy zainstalować rozszerzenie pracy z plikami.';de = 'Um ein temporäres Verzeichnis zu erstellen, müssen Sie eine Dateierweiterung installieren.';ro = 'Pentru crearea directorului temporar trebuie să instalați extensia de lucru cu fișierele.';tr = 'Geçici dizini oluşturmak için, dosyalarla çalışmak için bir uzantı yüklenmelidir.'; es_ES = 'Para crear un catálogo temporal es necesario instalar la extensión del uso de archivos.'");
	AttachFileOperationsExtension(Notification, SuggestionText, False);
	
EndProcedure

// Suggests the user to install the file system extension in the web client.
// The function to be incorporated in the beginning of code areas that process files.
//
// Parameters:
//  OnCloseNotifyDescription - NotifyDescription - the description of the procedure to be called 
//          once a form is closed. Parameters:
//    - ExtensionAttached - Boolean - True if the extension is attached.
//    - AdditionalParameters - Arbitrary - the parameters specified in OnCloseNotifyDescription.
//  SuggestionText - String - a message text. If the text is not specified, the default text is displayed.
//  CanContinueWithoutInstalling - If True, displays the ContinueWithoutInstalling button. If False, 
//          displays the Cancel button.
//
// Example:
//
//  Notification = New NotifyDescription("PrintDocumentCompletion", ThisObject);
//  MessageText = NStr("en = 'To print the document, install the file system extension.'");
//  FileSystemClient.AttachFileOperationsExtension(Notification, MessageText);
//
//  Procedure PrintDocumentCompletion(ExtensionAttached, AdditionalParameters) Export
//    If ExtensionAttached Then
//     // Script that print a document only if the file system extension is attached.
//     // ...
//    Else
//     // Script that print a document if the file system extension is not attached.
//     // ...
//    EndIf.
//
Procedure AttachFileOperationsExtension(
		OnCloseNotifyDescription, 
		SuggestionText = "",
		CanContinueWithoutInstalling = True) Export
	
	NotificationDescriptionCompletion = New NotifyDescription(
		"StartFileSystemExtensionAttachingWhenAnsweringToInstallationQuestion", FileSystemInternalClient,
		OnCloseNotifyDescription);
	
#If Not WebClient Then
	// In the thin, thick, and web clients the extension is always attached.
	ExecuteNotifyProcessing(NotificationDescriptionCompletion, "AttachmentNotRequired");
	Return;
#EndIf
	
	Context = New Structure;
	Context.Insert("NotifyDescriptionCompletion", NotificationDescriptionCompletion);
	Context.Insert("SuggestionText",             SuggestionText);
	Context.Insert("CanContinueWithoutInstalling", CanContinueWithoutInstalling);
	
	Notification = New NotifyDescription(
		"StartFileSystemExtensionAttachingOnSetExtension", FileSystemInternalClient, Context);
	BeginAttachingFileSystemExtension(Notification);
	
EndProcedure

#EndRegion

#EndRegion

#Region Private

// Initializes a parameter structure to interact with the file system.
//
// Parameters:
//  DialogMode - FileSelectionDialogMode - the run mode of generating file selection dialog.
//
// Returns:
//  Structure - see FileSystemClient.FileImportParameters and FileSystemClient.FileSavingParameters
//
Function OperationContext(DialogMode)
	
	Context = New Structure();
	Context.Insert("Dialog", New FileDialog(DialogMode));
	Context.Insert("Interactively", True);
	Context.Insert("SuggestionText", "");
	
	Return Context;
	
EndFunction

// Places the selected files into a temporary storage.
// See FileSystemClient.ImportFile and FileSystemClient.ImportFiles. 
//
Procedure ShowPutFile(CompletionHandler, PutParameters)
	
	PutParameters.Insert("CompletionHandler", CompletionHandler);
	NotifyDescription = New NotifyDescription(
		"ShowPutFileOnAttachFileSystemExtension", FileSystemInternalClient, PutParameters);
	AttachFileOperationsExtension(NotifyDescription, PutParameters.SuggestionText);
	
EndProcedure

// Saves files from temporary storage to the file system.
// See FileSystemClient.SaveFile and FileSystemClient.SaveFiles. 
//
Procedure ShowDownloadFiles(CompletionHandler, FilesToSave, ReceivingParameters)
	
	ReceivingParameters.Insert("FilesToGet",      FilesToSave);
	ReceivingParameters.Insert("CompletionHandler", CompletionHandler);
	
	NotifyDescription = New NotifyDescription(
		"ShowDownloadFilesOnAttachFileSystemExtension", FileSystemInternalClient, ReceivingParameters);
	AttachFileOperationsExtension(NotifyDescription, ReceivingParameters.SuggestionText);
	
EndProcedure

// Gets the path to save the file in the temporary files catalog.
//
// Parameters:
//  FileName - String - the name of the file with an extension or the file extension without the dot.
//
// Returns:
//  String - path to save the file.
//
Function TempFileFullName(Val FileName)

#If WebClient Then
	
	Return ?(StrFind(FileName, ".") = 0, 
		Format(CommonClient.SessionDate(), "DF=yyyyMMddHHmmss") + "." + FileName, FileName);
	
#Else
	
	ExtensionPosition = StrFind(FileName, ".");
	If ExtensionPosition = 0 Then
		Return GetTempFileName(FileName);
	Else
		Return TempFilesDir() + FileName;
	EndIf;
	
#EndIf

EndFunction

#EndRegion