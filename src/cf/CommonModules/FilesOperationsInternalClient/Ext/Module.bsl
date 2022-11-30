///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////////////
// "Stored files" subsystem.
//
////////////////////////////////////////////////////////////////////////////////

#Region Internal

// Returns the path to the user working directory.
Function UserWorkingDirectory() Export
	
	Return FilesOperationsInternalClientCached.UserWorkingDirectory();
	
EndFunction

// Opens the folder form with the list of files.
//
// Parameters:
//   StandardProcessing - Boolean - passed "as is" from the "Opening" handler parameters.
//   Folder - CatalogRef.Files - a folder to be opened.
//
// Usage locations:
//   Catalog.ReportsMailings.Form.ItemForm.FolderOpen().
//
Procedure ReportsMailingViewFolder(StandardProcessing, Folder) Export
	
	StandardProcessing = False;
	FormParameters = New Structure("Folder", Folder);
	OpenForm("Catalog.Files.Form.Files", FormParameters, , Folder);
	
EndProcedure

Procedure MoveAllFilesToVolumes() Export
	
	OpenForm("DataProcessor.MoveFilesToVolumes.Form");
	
EndProcedure

// Creates File on the hard drive, based on the passed path to file and opens the card.
//
//  AddingOptions - Structure:
//       * ResultHandler - NotifyDescription, Undefined.
//             - Description of the result handler procedure. The method result is passed to this procedure.
//       * FullFileName - String - optional. A full path and name of the file on the client.
//             If not specified, a dialog box to select a file will open.
//       * FileOwner - AnyRef - a file owner.
//       * FormOwner - ManagedForm, from which the file creation is called.
//       * DontOpenCardAfterCreateFromFile - Boolean.
//             - True when the file card does not open after creation.
//       * NameOfFileToCreate - String - optional. New file name.
//
Procedure AddFormFileSystemWithExtension(ExecutionParameters) Export
	
	Result = AddFromFileSystemWithExtensionSynchronous(ExecutionParameters);
	If Not Result.FileAdded Then
		If ValueIsFilled(Result.ErrorText) Then
			ReturnResultAfterShowWarning(ExecutionParameters.ResultHandler, Result.ErrorText, Undefined);
		Else
			ReturnResult(ExecutionParameters.ResultHandler, Undefined);
		EndIf;
		Return;
	EndIf;
	
	If ExecutionParameters.DontOpenCardAfterCreateFromFIle <> True Then
		FormParameters = New Structure("OpenCardAfterCreateFile", True);
		OnCloseNotifyDescription = PrepareHandlerForDialog(ExecutionParameters.ResultHandler);
		FilesOperationsClient.OpenFileForm(Result.FileRef,, FormParameters, OnCloseNotifyDescription); 
	Else
		ReturnResult(ExecutionParameters.ResultHandler, Result);
	EndIf;
	
EndProcedure

// Creates File on the hard drive, based on the passed path to file and opens the card.
//
//  AddingOptions - Structure:
//       * FullFileName - String - optional. A full path and name of the file on the client.
//             If not specified, a synchronous dialog box to select a file will open.
//       * FileOwner - AnyRef - a file owner.
//       * UUID - UUID - a form ID to store the file.
//       * NameOfFileToCreate - String - optional. New file name.
//
// Returns:
//   Structure - result.
//       * FileAdded - Boolean - shows whether the operation is performed successfully.
//       * FileRef - CatalogRef.Files
//       * ErrorText - String.
//
Function AddFromFileSystemWithExtensionSynchronous(ExecutionParameters) Export
	
	Result = New Structure;
	Result.Insert("FileAdded", False);
	Result.Insert("FileRef",   Undefined);
	Result.Insert("ErrorText",  "");
	
	DIalogBoxFilter = ?(ExecutionParameters.Property("SelectionDialogFilter"),
		ExecutionParameters.SelectionDialogFilter, NStr("ru = 'Все файлы (*.*)|*.*'; en = 'All files (*.*)|*.*'; pl = 'Wszystkie pliki(*.*)|*.*';de = 'Alle Dateien (*.*)|*.*';ro = 'Toate fișierele (*.*)|*.*';tr = 'Tüm dosyalar(*.*)|*.*'; es_ES = 'Todos archivos (*.*)|*.*'"));
		
	If Not ExecutionParameters.Property("FullFileName") Then
		// Import from the file system with file operation extension.
		FileSelectionDialog = New FileDialog(FileDialogMode.Open);
		FileSelectionDialog.Multiselect = False;
		FileSelectionDialog.Title = NStr("ru = 'Выбор файла'; en = 'Select file'; pl = 'Wybierz plik';de = 'Datei auswählen';ro = 'Selectare fișier';tr = 'Dosya seç'; es_ES = 'Seleccionar un archivo'");
		FileSelectionDialog.Filter = DIalogBoxFilter;
		FileSelectionDialog.Directory = FilesOperationsInternalServerCall.FolderWorkingDirectory(ExecutionParameters.FileOwner);
		If NOT FileSelectionDialog.Choose() Then
			Return Result;
		EndIf;
		ExecutionParameters.Insert("FullFileName", FileSelectionDialog.FullFileName);
	EndIf;
	
	If Not ExecutionParameters.Property("NameOfFileToCreate") Then
		ExecutionParameters.Insert("NameOfFileToCreate", Undefined);
	EndIf;
	
	ClientFile = New File(ExecutionParameters.FullFileName);
	If ExecutionParameters.Property("MaxSize")
		AND ExecutionParameters.MaxSize > 0
		AND ClientFile.Size() > ExecutionParameters.MaxSize*1024*1024 Then
		
		ErrorText = NStr("ru = 'Размер файла превышает %1 Мб.'; en = 'The file size exceeds %1 MB.'; pl = 'Rozmiar pliku przekracza %1 MB.';de = 'Die Dateigröße überschreitet %1 MB.';ro = 'Dimensiunea fișierului depășește %1 Mb.';tr = 'Dosya boyutu %1MB''yi aşıyor.'; es_ES = 'El tamaño del archivo supera %1 MB.'");
		Result.ErrorText = StringFunctionsClientServer.SubstituteParametersToString(ErrorText, 
			ExecutionParameters.MaxSize);
		
		Return Result;
		
	EndIf;
	
	CheckCanImportFile(ClientFile);
	
	CommonSettings = CommonFilesOperationsSettings();
	ExtractFilesTextsAtClient = NOT CommonSettings.ExtractTextFilesOnServer;
	If ExtractFilesTextsAtClient Then
		TempTextStorageAddress = ExtractTextToTempStorage(ClientFile.FullName,
			ExecutionParameters.OwnerForm.UUID);
	Else
		TempTextStorageAddress = "";
	EndIf;
		
	// Storing the file to a temporary storage.
	TempFileStorageAddress = "";
	
	FilesToPut = New Array;
	Details = New TransferableFileDescription(ClientFile.FullName, "");
	FilesToPut.Add(Details);
	
	FilesThatWerePut = New Array;
	FilesPut = PutFiles(FilesToPut, FilesThatWerePut, , False, ExecutionParameters.OwnerForm.UUID);
	If NOT FilesPut Then
		Return Result;
	EndIf;
	
	If FilesThatWerePut.Count() = 1 Then
		TempFileStorageAddress = FilesThatWerePut[0].Location;
	EndIf;
	
#If MobileClient Then
	PresentationOnMobileDevice = ClientFile.GetMobileDeviceLibraryFilePresentation();
	FileExtention = CommonClientServer.GetFileNameExtension(PresentationOnMobileDevice);
	FileNameWithoutExtension = StrReplace(PresentationOnMobileDevice, "." + FileExtention, "");
#Else
	FileExtention = CommonClientServer.ExtensionWithoutPoint(ClientFile.Extension);
	FileNameWithoutExtension = ClientFile.BaseName;
#EndIf
	
	If ExecutionParameters.NameOfFileToCreate <> Undefined Then
		CreationName = ExecutionParameters.NameOfFileToCreate;
	Else
		CreationName = FileNameWithoutExtension;
	EndIf;
	
	// Creating the File card in database.
	Try
		If FilesOperationsInternalClientCached.IsDirectoryFiles(ExecutionParameters.FileOwner) Then
			FileInfo = FilesOperationsClientServer.FileInfo("FileWithVersion", ClientFile);
			FileInfo.TempFileStorageAddress = TempFileStorageAddress;
			FileInfo.TempTextStorageAddress = TempTextStorageAddress;
			FileInfo.WriteToHistory = True;
			FileInfo.BaseName = CreationName;
			FileInfo.ExtensionWithoutPoint = FileExtention;
			Result.FileRef = FilesOperationsInternalServerCall.CreateFileWithVersion(ExecutionParameters.FileOwner, FileInfo);
		Else
			FileParameters = New Structure;
			FileParameters.Insert("FilesOwner",              ExecutionParameters.FileOwner);
			FileParameters.Insert("Author",                       Undefined);
			FileParameters.Insert("BaseName",            FileNameWithoutExtension);
			FileParameters.Insert("ExtensionWithoutPoint",          FileExtention);
			FileParameters.Insert("Modified");
			FileParameters.Insert("ModificationTimeUniversal");
			
			Result.FileRef = FilesOperationsInternalServerCall.AppendFile(FileParameters,
				TempFileStorageAddress,
				TempTextStorageAddress);
		EndIf;	
		Result.FileAdded = True;
	Except
		Result.ErrorText = ErrorCreatingNewFile(ErrorInfo());
	EndTry;
	
	If Result.ErrorText <> "" Then
		Return Result;
	EndIf;
	
	NotificationParameters = New Structure;
	NotificationParameters.Insert("FileOwner", ExecutionParameters.FileOwner);
	NotificationParameters.Insert("File"         , Result.FileRef);
	NotificationParameters.Insert("IsNew"     , True);
	Notify("Write_File", NotificationParameters, Result.FileRef);
	
	ShowUserNotification(
		NStr("ru = 'Создание:'; en = 'Created:'; pl = 'Utworzony:';de = 'Erstellt:';ro = 'Creată:';tr = 'Oluşturuldu:'; es_ES = 'Creado:'"),
		GetURL(Result.FileRef),
		Result.FileRef,
		PictureLib.Information32);
	
	Return Result;
	
EndFunction

// Continues AttachedFilesClient procedure execution.AddFiles.
Procedure AddFilesAddInSuggested(FileSystemExtensionAttached, AdditionalParameters) Export
	
	FileOwner = AdditionalParameters.FileOwner;
	FormID = AdditionalParameters.FormID;
	
	If Not AdditionalParameters.Property("Filter") Then
		AdditionalParameters.Insert("Filter","");
	EndIf;
	
	If FileSystemExtensionAttached Then
		
		Filter = AdditionalParameters.Filter;
		OpenCardAfterCreateFromFile = False;
		If AdditionalParameters.Property("DontOpenCardAfterCreateFromFIle") Then
			OpenCardAfterCreateFromFile = Not AdditionalParameters.DontOpenCardAfterCreateFromFIle;
		EndIf;
		
		SelectedFiles = New Array;
		
		If Not AdditionalParameters.Property("FullFileName") Then
			SelectFile = New FileDialog(FileDialogMode.Open);
			SelectFile.Multiselect = True;
			SelectFile.Title = NStr("ru = 'Выбор файла'; en = 'Select file'; pl = 'Wybierz plik';de = 'Datei auswählen';ro = 'Selectare fișier';tr = 'Dosya seç'; es_ES = 'Seleccionar un archivo'");
			SelectFile.Filter = ?(ValueIsFilled(Filter), Filter, NStr("ru = 'Все файлы'; en = 'All files'; pl = 'Wszystkie pliki';de = 'Alle Dateien';ro = 'Toate fișierele';tr = 'Tüm dosyalar'; es_ES = 'Todos archivos'") + " (*.*)|*.*");
			If SelectFile.Choose() Then
				SelectedFiles = SelectFile.SelectedFiles;
			EndIf;
		Else
			SelectedFiles.Add(AdditionalParameters.FullFileName);
		EndIf;
		
		NameOfFileToCreate = "";
		If AdditionalParameters.Property("NameOfFileToCreate") Then
			NameOfFileToCreate = AdditionalParameters.NameOfFileToCreate;
		EndIf;
		
		If SelectedFiles.Count() > 0  Then
			AttachedFilesArray = New Array;
			PutSelectedFilesInStorage(
				SelectedFiles,
				FileOwner,
				AttachedFilesArray,
				FormID,
				NameOfFileToCreate,
				AdditionalParameters.GroupOfFiles);
			
			If AttachedFilesArray.Count() = 1 AND OpenCardAfterCreateFromFile Then
				AttachedFile = AttachedFilesArray[0];
				
				ShowUserNotification(
					NStr("ru = 'Создание:'; en = 'Created:'; pl = 'Utworzony:';de = 'Erstellt:';ro = 'Creat:';tr = 'Oluşturuldu:'; es_ES = 'Creado:'"),
					GetURL(AttachedFile),
					AttachedFile,
					PictureLib.Information32);
				
				FormParameters = New Structure("IsNew", True);
				FilesOperationsClient.OpenFileForm(AttachedFile,, FormParameters)
			EndIf;
			
			If AttachedFilesArray.Count() > 0 Then
				NotifyChanged(AttachedFilesArray[0]);
				NotifyChanged(FileOwner);
				NotificationParameters = New Structure;
				NotificationParameters.Insert("FileOwner", FileOwner);
				NotificationParameters.Insert("File"         , AttachedFilesArray[0]);
				NotificationParameters.Insert("IsNew"     , True);
				Notify("Write_File", NotificationParameters, AttachedFilesArray);
			EndIf;
			
			If AdditionalParameters.Property("ResultHandler")
				AND AdditionalParameters.ResultHandler <> Undefined Then
				ExecuteNotifyProcessing(AdditionalParameters.ResultHandler, AttachedFilesArray);
			EndIf;
			
		EndIf;
		
	Else // If the web client has no extension attached.
		NotifyDescription = New NotifyDescription("AddFilesCompletion", ThisObject, AdditionalParameters);
		PutSelectedFilesInStorageWeb(NotifyDescription, FileOwner, FormID);
	EndIf;
	
EndProcedure

// Shows a standard warning.
//
// Parameters:
//  ResultHandler - NotifyDescription, Undefined - description of the procedure that gets the method result.
//  CommandPresentation - String - optional. The name of the command that requires the file system extension.
//
Procedure ShowFileSystemExtensionRequiredMessageBox(ResultHandler, CommandPresentation = "") Export
	If Not ClientSupportsSynchronousCalls() Then
		WarningText = NStr("ru = 'Выполнение команды ""%1"" в браузерах
			|Google Chrome и Mozilla Firefox не поддерживается.'; 
			|en = 'The ""%1"" command is not supported in
			|Google Chrome and Mozilla Firefox.'; 
			|pl = 'Wykonanie polecenia ""%1"" w przeglądarkach
			|Google Chrome oraz Mozilla Firefox nie jest obsługiwane.';
			|de = 'Die Ausführung des Befehls ""%1"" in den Browsern
			|Google Chrome und Mozilla Firefox wird nicht unterstützt.';
			|ro = 'Executarea comenzii ""%1"" în browserele
			|Google Chrome și Mozilla Firefox nu este susținută.';
			|tr = '""%1"" komutu 
			| Google Chrome ve Mozilla Firefox arama motorlarında desteklenmiyor.'; 
			|es_ES = 'No se admite la ejecución del comando ""%1"" en los navegadores web
			|Google Chrome y Mozilla Firefox.'");
	Else
		WarningText = NStr("ru = 'Для выполнения команды ""%1"" необходимо
			|установить расширение для веб-клиента 1С:Предприятие.'; 
			|en = 'To run the ""%1"" command,
			|install the 1C:Enterprise extension for the web client.'; 
			|pl = 'Aby wykonać polecenie ""%1"" należy
			|zainstalować rozszerzenie dla klienta sieci web 1C:Enterprise.';
			|de = 'Um den Befehl ""%1"" auszuführen, ist es notwendig
			|, die Erweiterung für den Webclient 1C:Enterprise einzustellen.';
			|ro = 'Pentru executarea comenzii ""%1"" trebuie
			|să instalați extensia pentru clientul Web 1C:Enterprise.';
			|tr = '""%1"" Komutunun çalıştırılması için 1C: İşletme 
			|web istemcisinin uzantısı yüklenmelidir.'; 
			|es_ES = 'Para realizar el comando ""%1"" es necesario
			|instalar la extensión para el cliente web de 1C:Enterprise.'");
	EndIf;
	If ValueIsFilled(CommandPresentation) Then
		WarningText = StrReplace(WarningText, "%1", CommandPresentation);
	Else
		WarningText = StrReplace(WarningText, " ""%1""", "");
	EndIf;
	ReturnResultAfterShowWarning(ResultHandler, WarningText, Undefined);
EndProcedure

// Saves the path to the user's working directory to the settings.
//
// Parameters:
//  DirectoryName - String - a file directory name.
//
Procedure SetUserWorkingDirectory(DirectoryName) Export
	
	FilesOperationsInternalServerCall.SetUserWorkingDirectory(DirectoryName);
	
EndProcedure

// Returns My documents directory + the current user name or the folder previously used for data 
// export.
//
Function DumpDirectory() Export
	
	Path = "";
	
#If Not WebClient AND NOT MobileClient Then
	
	ClientParameters = StandardSubsystemsClient.ClientRunParameters();
	
	Path = CommonServerCall.CommonSettingsStorageLoad("ExportFolderName", "ExportFolderName");
	
	If Path = Undefined Then
		If NOT ClientParameters.IsBaseConfigurationVersion Then
			Path = MyDocumentsDirectory();
			CommonServerCall.CommonSettingsStorageSave(
				"ExportFolderName", "ExportFolderName", Path);
		EndIf;
	EndIf;
	
#EndIf
	
	Return Path;
	
EndFunction

// Shows the file selection dialog box to user and returns an array of selected files to import.
// 
//
Function FilesToImport() Export
	
	OpenFileDialog = New FileDialog(FileDialogMode.Open);
	OpenFileDialog.FullFileName     = "";
	OpenFileDialog.Filter             = NStr("ru = 'Все файлы(*.*)|*.*'; en = 'All files (*.*)|*.*'; pl = 'Wszystkie pliki(*.*)|*.*';de = 'Alle Dateien (*.*)|*.*';ro = 'Toate fișierele (*.*)|*.*';tr = 'Tüm dosyalar (*. *) | *. *'; es_ES = 'Todos archivos (*.*)|*.*'");
	OpenFileDialog.Multiselect = True;
	OpenFileDialog.Title          = NStr("ru = 'Выберите файлы'; en = 'Select files'; pl = 'Wybrać pliki';de = 'Dateien wählen';ro = 'Selectați fișiere';tr = 'Dosyaları seçin'; es_ES = 'Seleccionar archivos'");
	
	FileNamesArray = New Array;
	
	If OpenFileDialog.Choose() Then
		FilesArray = OpenFileDialog.SelectedFiles;
		
		For Each FileName In FilesArray Do
			FileNamesArray.Add(FileName);
		EndDo;
		
	EndIf;
	
	Return FileNamesArray;
	
EndFunction

// Checks if the file name contains prohibited characters.
//
// Parameters:
//  FileName - String - the file name to check.
//
//  DeleteIncorrectChars - Boolean - if True, delete incorrect characters from the passed row.
//             
//
Procedure CorrectFileName(FileName, DeleteInvalidCharacters = False) Export
	
	// The list of prohibited characters is taken from here: http://support.microsoft.com/kb/100108/ru 
	// The forbidden characters for the FAT and NTFS file systems were combined.
	
	ExceptionStr = CommonClientServer.GetProhibitedCharsInFileName();
	
	ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("ru = 'В имени файла не должно быть следующих символов: %1'; en = 'A file name cannot contain the following characters: %1'; pl = 'Nazwa pliku nie może zawierać następnych symboli: %1';de = 'Der Dateiname darf folgende Zeichen nicht enthalten: %1';ro = 'Numele fișierului nu poate conține următoarele caractere: %1';tr = 'Dosya adı aşağıdaki karakterleri içeremez:%1'; es_ES = 'Nombre del archivo no puede contener los siguientes símbolos: %1'"), ExceptionStr);
	
	Result = True;
	
	FoundProhibitedCharsArray =
		CommonClientServer.FindProhibitedCharsInFileName(FileName);
	
	If FoundProhibitedCharsArray.Count() <> 0 Then
		
		Result = False;
		
		If DeleteInvalidCharacters Then
			FileName = CommonClientServer.ReplaceProhibitedCharsInFileName(FileName, "");
		EndIf;
		
	EndIf;
	
	If Not Result Then
		Raise ErrorText;
	EndIf;
	
EndProcedure

// Iterates through directories recursively and counts the number of files and their total size.
Procedure GetFileListSize(Path, FilesArray, TotalSize, TotalCount) Export
	
	For Each SelectedFile In FilesArray Do
		
		If SelectedFile.IsDirectory() Then
			NewPath = String(Path);
			
			NewPath = NewPath + GetPathSeparator();
			
			NewPath = NewPath + String(SelectedFile.Name);
			FilesArrayInDirectory = FindFiles(NewPath, GetAllFilesMask());
			
			If FilesArrayInDirectory.Count() <> 0 Then
				GetFileListSize(
					NewPath, FilesArrayInDirectory, TotalSize, TotalCount);
			EndIf;
		
			Continue;
		EndIf;
		
		TotalSize = TotalSize + SelectedFile.Size();
		TotalCount = TotalCount + 1;
		
	EndDo;
	
EndProcedure

// Returns a path to the directory of the following kind:
// "C:\Documents and Settings\USERNAME\Application Data\1C\FilesА8\".
//
Function SelectPathToUserDataDirectory() Export
	
	DirectoryName = "";
	If FileSystemExtensionAttached() Then
		DirectoryName = UserDataWorkDir();
	EndIf;
	
	Return DirectoryName;
	
EndFunction

// Opens Windows Explorer and selects the specified file.
Function OpenExplorerWithFile(Val FullFileName) Export
	
	FileOnHardDrive = New File(FullFileName);
	
	If NOT FileOnHardDrive.Exist() Then
		Return False;
	EndIf;
	
	FileSystemClient.OpenExplorer(FileOnHardDrive.FullName);
	
	Return True;
	
EndFunction

// Returns the result of attaching file system extension.
//
//  Returns:
//   Boolean - at thin client it is always True, in the Google Chrome browser always false.
//            
//
Function FileSystemExtensionAttached() Export
	If ClientSupportsSynchronousCalls() Then
		Return AttachFileSystemExtension();
	Else
		Return False;
	EndIf;
EndFunction

// See the description of procedure at CommonClient.ShowFileSystemExtensionInstallationQuestion. 
//
Procedure ShowFileSystemExtensionInstallationQuestion(NotifyDescription) Export
	If Not ClientSupportsSynchronousCalls() Then
		ExecuteNotifyProcessing(NotifyDescription, False);
	Else
		FileSystemClient.AttachFileOperationsExtension(NotifyDescription);
	EndIf;
EndProcedure

Procedure SendFilesViaEmail(FilesArray, FormID, SendOptions, IsFile = False) Export
	
	If FilesArray.Count() = 0 Then
		Return;
	EndIf;
	
	Parameters = New Structure;
	Parameters.Insert("FilesArray", FilesArray);
	Parameters.Insert("FormID", FormID);
	Parameters.Insert("IsFile", IsFile);
	Parameters.Insert("SendOptions", SendOptions);
	
	NotifyDescription = New NotifyDescription("SendFileViaEmailAccountSettingOffered", ThisObject, Parameters);
	If CommonClient.SubsystemExists("StandardSubsystems.EmailOperations") Then
		ModuleEmailOperationsClient = CommonClient.CommonModule("EmailOperationsClient");
		ModuleEmailOperationsClient.CheckAccountForSendingEmailExists(NotifyDescription);
	EndIf;
	
EndProcedure

Procedure SendFileViaEmailAccountSettingOffered(AccountSetUp, AdditionalParameters) Export
	
	If AccountSetUp <> True Then
		Return;
	EndIf;
	
	AttachmentsList = FilesOperationsInternalServerCall.PutFilesInTempStorage(AdditionalParameters);
	SendOptions = AdditionalParameters.SendOptions;
	
	SendOptions.Insert("Attachments", AttachmentsList);
	SendOptions.Insert("DeleteFilesAfterSending", True);
	
	ModuleEmailOperationsClient = CommonClient.CommonModule("EmailOperationsClient");
	ModuleEmailOperationsClient.CreateNewEmailMessage(SendOptions);
	
EndProcedure

Function FileUpdateParameters(ResultHandler, ObjectRef, FormID) Export
	
	HandlerParameters = New Structure;
	HandlerParameters.Insert("ResultHandler", ResultHandler);
	HandlerParameters.Insert("ObjectRef", ObjectRef);
	HandlerParameters.Insert("FormID", FormID);
	HandlerParameters.Insert("StoreVersions");
	HandlerParameters.Insert("CurrentUserEditsFile");
	HandlerParameters.Insert("BeingEditedBy");
	HandlerParameters.Insert("CurrentVersionAuthor");
	HandlerParameters.Insert("PassedFullPathToFile", "");
	HandlerParameters.Insert("CreateNewVersion");
	HandlerParameters.Insert("VersionComment");
	HandlerParameters.Insert("ShowNotification", True);
	HandlerParameters.Insert("ApplyToAll", False);
	HandlerParameters.Insert("UnlockFiles", True);
	HandlerParameters.Insert("Encoding");
	Return HandlerParameters;
	
EndFunction	

// Click the Show service files command in the file list.
//
// Parameters:
//  List - a dynamic list.
//
// Returns:
//  Boolean - display of service commands in the list.
//
Function ShowServiceFilesClick(List) Export
	
	FilterItem = CommonClientServer.FindFilterItemByPresentation(List.Filter.Items, "HideInternal");
	If FilterItem = Undefined Then
		Return False;
	EndIf;
	
	ShowServiceFiles = FilterItem.Use;
	FilterItem.Use = Not ShowServiceFiles;
	Return ShowServiceFiles;
	
EndFunction

// Saves edited file to the infobase and unlocks it.
//
// Parameters:
//   Parameters - Structure - see FileUpdateParameters. 
//
Procedure EndEditAndNotify(Parameters) Export
	
	If Parameters.ObjectRef = Undefined Then
		ReturnResult(Parameters.ResultHandler, Undefined);
		Return;
	EndIf;
	
	ExecutionParameters = New Structure;
	ExecutionParameters.Insert("ResultHandler", Parameters.ResultHandler);
	ExecutionParameters.Insert("CommandParameter", Parameters.ObjectRef);
	Handler = New NotifyDescription("FinishEditWithNotificationCompletion", ThisObject, ExecutionParameters);
	
	HandlerParameters = FileUpdateParameters(Handler, Parameters.ObjectRef, Parameters.FormID);
	HandlerParameters.CreateNewVersion = Parameters.CreateNewVersion;
	EndEdit(HandlerParameters);

EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Procedures and functions for cryptography operations.

// Check signatures of the file data in the table.
// 
// Parameters:
//  Form - ManagedForm - with following attributes:
//    * Object - FormDataStructure - as the object with Ref and Encrypted properties has.
//                  For example, CatalogObject.File, CatalogObject.DocumentAttachedFiles.
//
//    * DigitalSignatures - FormDataCollection - with the following fields:
//       * SignatureCheckDate - Date - (return value) - the check date.
//       * Status              - String - (reurn value) - the check result.
//       * SignatureAddress        - String - signature data address in temporary storage.
//
//  RefToBinaryData - BinaryData - file binary data.
//                         - String - an address in temporary storage or an URL.
//
//  SelectedRows - Array - a property of the DigitalSignatures parameter form table.
//                   - Undefined - check all signatures.
//
Procedure CheckSignatures(Form, RefToBinaryData, SelectedRows = Undefined) Export
	
	// 1. Receiving the binary data addressand addresses of signature binary data.
	// 2. Decrypting the file if it is encrypted and then running a check.
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("Form", Form);
	AdditionalParameters.Insert("SelectedRows", SelectedRows);
	
	If Not Form.Object.Encrypted Then
		CheckSignaturesAfterPrepareData(RefToBinaryData, AdditionalParameters);
		Return;
	EndIf;
	
	If Not CommonClient.SubsystemExists("StandardSubsystems.DigitalSignature") Then
		Return;
	EndIf;
	
	DataDetails = New Structure;
	DataDetails.Insert("Operation",              NStr("ru = 'Расшифровка файла'; en = 'Decrypt file'; pl = 'Deszyfrowanie plików';de = 'Dateientschlüsselung';ro = 'Decriptarea fișierului';tr = 'Dosya şifresini çözme'; es_ES = 'Descodificación del archivo'"));
	DataDetails.Insert("DataTitle",       NStr("ru = 'Файл'; en = 'File'; pl = 'Plik';de = 'Datei';ro = 'Fișier';tr = 'Dosya'; es_ES = 'Archivo'"));
	DataDetails.Insert("Data",                RefToBinaryData);
	DataDetails.Insert("Presentation",         Form.Object.Ref);
	DataDetails.Insert("EncryptionCertificates", Form.Object.Ref);
	DataDetails.Insert("NotifyOnCompletion",   False);
	
	FollowUpHandler = New NotifyDescription("AfterFileDecryptionOnCheckSignature", ThisObject, AdditionalParameters);
	
	ModuleDigitalSignatureClient = CommonClient.CommonModule("DigitalSignatureClient");
	ModuleDigitalSignatureClient.Decrypt(DataDetails, , FollowUpHandler);
	
EndProcedure

// Continue the CheckSignatures procedure.
Procedure CheckSignaturesAfterCheckRow(Result, AdditionalParameters) Export
	
	SignatureRow = AdditionalParameters.SignatureRow;
	SignatureRow.SignatureValidationDate = CommonClient.SessionDate();
	SignatureRow.SignatureCorrect   = (Result = True);
	SignatureRow.ErrorDescription = ?(SignatureRow.SignatureCorrect, "", Result);
	
	FilesOperationsInternalClientServer.FillSignatureStatus(SignatureRow);
	
	CheckSignaturesLoopStart(AdditionalParameters);
	
EndProcedure

// For the file form.
Procedure SetCommandsAvailabilityOfDigitalSignaturesList(Form) Export
	
	Items = Form.Items;
	HasSignatures = (Form.DigitalSignatures.Count() <> 0);
	
	Items.DigitalSignaturesOpen.Enabled      = HasSignatures;
	Items.DigitalSignaturesCheck.Enabled    = HasSignatures;
	Items.DigitalSignaturesCheckAll.Enabled = HasSignatures;
	Items.DigitalSignaturesSave.Enabled    = HasSignatures;
	Items.DigitalSignaturesDelete.Enabled      = HasSignatures;
	
EndProcedure

// For the file form.
Procedure SetCommandsAvailabilityOfEncryptionCertificatesList(Form) Export
	
	Object   = Form.Object;
	Items = Form.Items;
	
	Items.EncryptionCertificatesOpen.Enabled = Object.Encrypted;
	
EndProcedure

#Region Scanning

// Checks whether the scanning component is installed and is there is at least one scanner.
Function ScanCommandAvailable() Export
	
#If MobileClient Then
	Return MultimediaTools.PhotoSupported();
#Else
	If Not InitAddIn(False) Then
		Return False;
	EndIf;
	
	Twain = ApplicationParameters["StandardSubsystems.TwainComponent"];
	If Twain.IsDevicePresent() Then
		Return True;
	EndIf;
	
	Return False;
#EndIf
	
EndFunction

// Opens the dialog box of scanning and view picture.
Procedure AddFromScanner(ExecutionParameters) Export
	
#If MobileClient Then
	
	MultimediaData = MultimediaTools.MakePhoto();
	If MultimediaData = Undefined Then
		ReturnResult(ExecutionParameters.ResultHandler, Undefined);
		Return;
	EndIf;
	
	NameWithoutExtension = "img_" + Format(CommonClient.SessionDate(), "DF=yyyyMMdd_hhmmss");
	
	FileParameters = New Structure;
	FileParameters.Insert("Author", Undefined);
	FileParameters.Insert("FilesOwner", ExecutionParameters.FileOwner);
	FileParameters.Insert("BaseName", NameWithoutExtension);
	FileParameters.Insert("ExtensionWithoutPoint", MultimediaData.FileExtention);
	FileParameters.Insert("Modified", Undefined);
	FileParameters.Insert("ModificationTimeUniversal", Undefined);
	
	FileAddress = PutToTempStorage(MultimediaData.GetBinaryData(),
		ExecutionParameters.OwnerForm.UUID);
		
	Result = New Structure;
	Result.Insert("FileAdded", True);
	Result.Insert("FileRef", FilesOperationsInternalServerCall.AppendFile(FileParameters, FileAddress));
	ReturnResult(ExecutionParameters.ResultHandler, Result);
	
#Else
		
	If Not CommonClient.IsWindowsClient() Then
		ReturnResult(ExecutionParameters.ResultHandler, Undefined);
		Return;
	EndIf;
	
	SystemInfo = New SystemInfo();
	
	FormParameters = New Structure("FileOwner, IsFile, DontOpenCardAfterCreateFromFIle, OneFileOnly");
	FillPropertyValues(FormParameters, ExecutionParameters);
	FormParameters.Insert("ClientID", SystemInfo.ClientID);
	
	ResultHandler = PrepareHandlerForDialog(ExecutionParameters.ResultHandler);
	OpenForm("DataProcessor.Scanning.Form.ScanningResult", FormParameters, ExecutionParameters.OwnerForm, , , , ResultHandler);
	
#EndIf
	
EndProcedure

#EndRegion

////////////////////////////////////////////////////////////////////////////////
// Common procedures and functions of operations with operating system files.

// Open file version.
//
// Parameters:
//  ResultHandler - NotifyDescription, Undefined - description of the procedure that gets the method result.
//  FileData             - a structure with file data.
//  UUID - the form UUID.
//
Procedure OpenFileVersion(ResultHandler, FileData, UUID = Undefined) Export
	
	HandlerParameters = New Structure;
	HandlerParameters.Insert("ResultHandler", ResultHandler);
	HandlerParameters.Insert("FileData", FileData);
	HandlerParameters.Insert("UUID", UUID);
	
	Handler = New NotifyDescription("OpenFileVersionAfterInstallExtension", ThisObject, HandlerParameters);
	
	ShowFileSystemExtensionInstallationQuestion(Handler);
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Configuration subsystems event handlers.

// See CommonClientOverridable.BeforeExit. 
Procedure BeforeExit(Cancel, Warnings) Export
	
	Response = CheckLockedFilesOnExit();
	If Response = Undefined Then 
		Return;
	EndIf;
	
	If TypeOf(Response) <> Type("Structure") Then
		Return;
	EndIf;
	
	UserWarning = StandardSubsystemsClient.WarningOnExit();
	UserWarning.HyperlinkText = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("ru = 'Открыть список редактируемых файлов (%1)'; en = 'Open list of locked files (%1)'; pl = 'Otwórz listę edytowanych plików (%1)';de = 'Liste der bearbeiteten Dateien öffnen (%1)';ro = 'Deschideți lista fișierelor editate (%1)';tr = 'Düzenlenmiş dosya listesini açın (%1)'; es_ES = 'Abrir la lista de los archivos editados (%1)'"),
		Response.LockedFilesCount);
	UserWarning.WarningText = NStr("ru = 'Имеются занятые для редактирования файлы'; en = 'There are files locked for editing'; pl = 'Masz zablokowane pliki do edycji';de = 'Sie haben Dateien zur Bearbeitung gesperrt';ro = 'Există fișiere blocate pentru editare';tr = 'Dosyaları düzenlemek için kilitlediniz'; es_ES = 'Usted ha bloqueado los archivos para editar'");
	
	ActionOnClickHyperlink = UserWarning.ActionOnClickHyperlink;
	
	ApplicationWarningForm = Undefined;
	Response.Property("ApplicationWarningForm", ApplicationWarningForm);
	ApplicationWarningFormParameters = Undefined;
	Response.Property("ApplicationWarningFormParameters", ApplicationWarningFormParameters);
	
	Form = Undefined;
	Response.Property("Form", Form);
	FormParameters = Undefined;
	Response.Property("FormParameters", FormParameters);
	
	If ApplicationWarningForm <> Undefined Then 
		ActionOnClickHyperlink.ApplicationWarningForm = ApplicationWarningForm;
		ActionOnClickHyperlink.ApplicationWarningFormParameters = ApplicationWarningFormParameters;
	EndIf;
	If Form <> Undefined Then 
		ActionOnClickHyperlink.Form = Form;
		ActionOnClickHyperlink.FormParameters = FormParameters;
	EndIf;
	
	Warnings.Add(UserWarning);
	
EndProcedure

#Region TextExtraction

// Extracts the text from the file on the client hard disk and stores the result to the server.
Procedure ExtractVersionText(FileOrFileVersion,
                             FileAddress,
                             Extension,
                             UUID,
                             Encoding = Undefined) Export

#If NOT WebClient Then
	FileNameWithPath = GetTempFileName(Extension);
	
	If Not GetFile(FileAddress, FileNameWithPath, False) Then
		Return;
	EndIf;
	
	// If files are stored on the hard disk (on the server), deleting a file from the temporary storage 
	// after receiving it.
	If IsTempStorageURL(FileAddress) Then
		DeleteFromTempStorage(FileAddress);
	EndIf;
	
	ExtractionResult = "NotExtracted";
	TempTextStorageAddress = "";
	
	Text = "";
	If FileNameWithPath <> "" Then
		
		// Extracting text from the file
		Cancel = False;
		Text = ExtractText(FileNameWithPath, Cancel, Encoding);
		
		If Cancel = False Then
			ExtractionResult = "Extracted";
			
			If Not IsBlankString(Text) Then
				TempFileName = GetTempFileName();
				TextFile = New TextWriter(TempFileName, TextEncoding.UTF8);
				TextFile.Write(Text);
				TextFile.Close();
				
				ImportResult = PutFileFromHardDriveInTempStorage(TempFileName, , UUID);
				If ImportResult <> Undefined Then
					TempTextStorageAddress = ImportResult;
				EndIf;
				
				DeleteFiles(TempFileName);
			EndIf;
		Else
			// When "no one" can extract the text, it is a normal case and an error message is not generated.
			// 
			ExtractionResult = "FailedExtraction";
		EndIf;
		
	EndIf;
	
	DeleteFiles(FileNameWithPath);
	
	FilesOperationsInternalServerCall.RecordTextExtractionResult(
		FileOrFileVersion, ExtractionResult, TempTextStorageAddress);
		
#EndIf

EndProcedure

#EndRegion

#EndRegion

#Region Private

// Returns True if a file with such extension can be imported.
Function CheckExtentionOfFileToDownload(FileExtention, RaiseException = True)
	
	CommonSettings = CommonFilesOperationsSettings();
	If NOT CommonSettings.FilesImportByExtensionDenied Then
		Return True;
	EndIf;
	
	If FilesOperationsInternalClientServer.FileExtensionInList(
		CommonSettings.DeniedExtensionsList, FileExtention) Then
		
		If RaiseException Then
			Raise StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'Загрузка файлов с расширением ""%1"" запрещена.
				           |Обратитесь к администратору.'; 
				           |en = 'Uploading files with the %1 extension is not allowed.
				           |Please contact the administrator.'; 
				           |pl = 'Nie można importować plików z rozszerzeniem ""%1"".
				           |Skontaktuj się z administratorem.';
				           |de = 'Dateien mit der Erweiterung ""%1"" können nicht importiert werden. 
				           |Kontaktieren Sie Ihren Administrator.';
				           |ro = 'Nu se pot importa fișiere cu extensia ""%1"". 
				           |Adresați-vă administratorului.';
				           |tr = '""%1"" Uzantılı dosya içe aktarılamıyor. 
				           |Yöneticinize başvurun.'; 
				           |es_ES = 'No se puede importar archivos con la extensión ""%1"".
				           |Contactar su administrador.'"),
				FileExtention);
		Else
			Return False;
		EndIf;
	EndIf;
	
	Return True;
	
EndFunction

// Extract text from a file and return it as a string.
Function ExtractText(FullFileName, Cancel = False, Encoding = Undefined)
	
	ExtractedText = "";
	
	Try
		File = New File(FullFileName);
		If Not File.Exist() Then
			Cancel = True;
			Return ExtractedText;
		EndIf;
	Except
		Cancel = True;
		Return ExtractedText;
	EndTry;
	
	Stop = False;
	CommonSettings = CommonFilesOperationsSettings();
	
#If Not WebClient AND NOT MobileClient Then
	
	FileNameExtension =
		CommonClientServer.GetFileNameExtension(FullFileName);
	
	FileExtensionInList = FilesOperationsInternalClientServer.FileExtensionInList(
		CommonSettings.TestFilesExtensionsList, FileNameExtension);
	
	If FileExtensionInList Then
		Return FilesOperationsInternalClientServer.ExtractTextFromTextFile(
			FullFileName, Encoding, Cancel);
	EndIf;
	
	Try
		Extracting = New TextExtraction(FullFileName);
		ExtractedText = Extracting.GetText();
	Except
		// If there is no handler to extract the text, this is not an error but a normal scenario. It is a normal case.
		ExtractedText = "";
		Stop = True;
	EndTry;
		
#EndIf
	
	If IsBlankString(ExtractedText) Then
		
		FileNameExtension =
			CommonClientServer.GetFileNameExtension(FullFileName);
		
		FileExtensionInList = FilesOperationsInternalClientServer.FileExtensionInList(
			CommonSettings.FilesExtensionsListOpenDocument, FileNameExtension);
		
		If FileExtensionInList Then
			Return FilesOperationsInternalClientServer.ExtractOpenDocumentText(FullFileName, Cancel);
		EndIf;
		
	EndIf;
	
	If Stop Then
		Cancel = True;
	EndIf;
	
	Return ExtractedText;
	
EndFunction

// Returns the path to the working directory of user data. This directory is used as the initial 
// value for the user working directory.
//
// Parameters:
//  Notification - NotifyDescription - a notification that runs after the user working directory is 
//   received. As a result the Structure returns with the following properties:
//     * Directory        - String - full name of the user data working directory.
//     * ErrorDescription - String - an error text if the directory is not received.
//
Procedure GetUserDataWorkingDirectory(Notification)
	
	Context = New Structure;
	Context.Insert("Notification", Notification);
	
	BeginGettingUserDataWorkDir(New NotifyDescription(
		"GetUserDataWorkingDirectoryAfterGet", ThisObject, Context,
		"GetUserDataWorkingDirectoryAfterGetDataError", ThisObject));
	
EndProcedure

// Continue the GetUserDataWorkingDirectory procedure.
Procedure GetUserDataWorkingDirectoryAfterGetDataError(ErrorInformation, StandardProcessing, Context) Export
	
	StandardProcessing = False;
	
	Result = New Structure;
	Result.Insert("Directory", "");
	Result.Insert("ErrorDescription", StringFunctionsClientServer.SubstituteParametersToString(
		NStr("ru = 'Не удалось получить рабочий каталог данных пользователя по причине:
		           |%1'; 
		           |en = 'Cannot retrieve the user''s working directory. Reason:
		           |%1'; 
		           |pl = 'Nie udało się uzyskać katalog roboczy danych użytkownika z powodu:
		           |%1';
		           |de = 'Ein Arbeitsverzeichnis mit Benutzerdaten konnte aus folgendem Grund nicht gefunden werden:
		           |%1';
		           |ro = 'Eșec la obținerea directorului de date ale utilizatorului din motivul:
		           |%1';
		           |tr = 'Aşağıdaki nedenlerden dolayı kullanıcı verilerinin 
		           |çalışma dizini alınamadı:%1'; 
		           |es_ES = 'No se ha podido recibir el catálogo de trabajo de los datos de usuario a causa de:
		           |%1'"), BriefErrorDescription(ErrorInformation)));
	
	ExecuteNotifyProcessing(Context.Notification, Result);
	
EndProcedure

// Continue the GetUserDataWorkingDirectory procedure.
Procedure GetUserDataWorkingDirectoryAfterGet(UserDataDir, Context) Export
	
	Result = New Structure;
	Result.Insert("Directory", UserDataDir);
	Result.Insert("ErrorDescription", "");
	
	ExecuteNotifyProcessing(Context.Notification, Result);
	
EndProcedure

// Continue the CheckSignatures procedure.
Procedure CheckSignaturesLoopStart(AdditionalParameters)
	
	If AdditionalParameters.Collection.Count() <= AdditionalParameters.IndexOf + 1 Then
		AdditionalParameters.Form.RefreshDataRepresentation();
		Return;
	EndIf;
	
	AdditionalParameters.IndexOf = AdditionalParameters.IndexOf + 1;
	Item = AdditionalParameters.Collection[AdditionalParameters.IndexOf];
	
	AdditionalParameters.Insert("SignatureRow", ?(TypeOf(Item) <> Type("Number"), Item,
		AdditionalParameters.Form.DigitalSignatures.FindByID(Item)));
		
	ModuleDigitalSignatureClient = CommonClient.CommonModule("DigitalSignatureClient");
	ModuleDigitalSignatureClient.VerifySignature(
		New NotifyDescription("CheckSignaturesAfterCheckRow", ThisObject, AdditionalParameters),
		AdditionalParameters.Data,
		AdditionalParameters.SignatureRow.SignatureAddress,
		AdditionalParameters.CryptoManager,
		AdditionalParameters.SignatureRow.SignatureDate);
	
EndProcedure

// Checks file properties in the working directory and in the file storage, asks for user 
// confirmation if necessary and returns the action to be performed on the file.
//
// Parameters:
//  ResultHandler - NotifyDescription, Undefined - description of the procedure that gets the method result.
//  FileNameWithPath - full file name with its path in the working directory.
// 
//  FileData    - a structure with the following properties:
//                   Size                       - Number.
//                   ModificationDateUniversal - Date.
//                   InWorkingDirectoryForRead     - Boolean.
//
// Returns:
//  String - possible strings:
//  OpenExistingFile, TakeFromStorageAndOpen, Cancel.
// 
Procedure ActionOnOpenFileInWorkingDirectory(ResultHandler, FileNameWithPath, FileData)
	
	If FileData.Property("UpdatePathFromFileOnHardDrive") Then
		ReturnResult(ResultHandler, "GetFromStorageAndOpen");
		Return;
	EndIf;
	
	Parameters = New Structure;
	Parameters.Insert("FileOperation", "OpenInWorkingFolder");
	Parameters.Insert("FullFileNameInWorkingDirectory", FileNameWithPath);
	
	File = New File(Parameters.FullFileNameInWorkingDirectory);
	
	Parameters.Insert("ChangeDateUniversalInFileStorage",
		FileData.UniversalModificationDate);
	
	Parameters.Insert("ChangeDateUniversalInWorkingDirectory",
		File.GetModificationUniversalTime());
	
	Parameters.Insert("ChangeDateInWorkingDirectory",
		ToLocalTime(Parameters.ChangeDateUniversalInWorkingDirectory));
	
	Parameters.Insert("ChangeDateInFileStorage",
		ToLocalTime(Parameters.ChangeDateUniversalInFileStorage));
	
	Parameters.Insert("SizeInWorkingDirectory", File.Size());
	Parameters.Insert("SizeInFileStorage", FileData.Size);
	
	DateDifference = Parameters.ChangeDateUniversalInWorkingDirectory
	           - Parameters.ChangeDateUniversalInFileStorage;
	
	If DateDifference < 0 Then
		DateDifference = -DateDifference;
	EndIf;
	
	If DateDifference <= 1 Then // Second is a possible difference (Win95 can have that).
		
		If Parameters.SizeInFileStorage <> 0
		   AND Parameters.SizeInFileStorage <> Parameters.SizeInWorkingDirectory Then
			// Date is the same, but the size is different. It is a rare but possible case.
			
			Parameters.Insert("Title",
				NStr("ru = 'Размер файла отличается'; en = 'Different file sizes'; pl = 'Różnica rozmiaru plilku';de = 'Dateigröße ist anders';ro = 'Dimensiunea fișierului diferă';tr = 'Dosya boyutu farklı'; es_ES = 'Tamaño del archivo es diferente'"));
			
			Parameters.Insert("Message",
				NStr("ru = 'Размер файла в рабочем каталоге на компьютере и его копии в программе отличается.
				           |
				           |Взять файл из программы и заменить им существующий на компьютере или
				           |открыть существующий без обновления?'; 
				           |en = 'The size of the local file copy differs from the size of the file stored in the application.
				           |
				           |Do you want to update the local file
				           |or open the local file without updating it?'; 
				           |pl = 'Rozmiar pliku w folderze roboczym na komputerze i jego kopii w programie jest inny.
				           |
				           |Pobrać plik z programu i zastąpić go istniejącym na komputerze lub 
				           |otworzyć istniejący bez aktualizacji?';
				           |de = 'Die Größe der Datei im Arbeitsverzeichnis auf dem Computer und ihre Kopie im Programm ist unterschiedlich.
				           |
				           |Eine Datei aus dem Programm nehmen und durch eine bestehende ersetzen oder
				           |eine bestehende öffnen, ohne sie zu aktualisieren?';
				           |ro = 'Dimensiunea fișierului în directorul pe computer și copiei lui în program este diferită.
				           |
				           |Luați fișierul din program și înlocuiți cu el cel existent pe computer sau
				           |deschideți cel existent fără actualizare?';
				           |tr = 'Bir bilgisayardaki çalışma dizinindeki dosyanın boyutu ve programdaki kopyası farklıdır. 
				           |
				           |Programdan bir dosya alınıp bilgisayarda var olan biriyle değiştirilsin mi yoksa
				           | güncelleme olmadan mevcut dosya açılsın mı?'; 
				           |es_ES = 'El tamaño del archivo en el catálogo de trabajo en el ordenador y su copia en el programa se diferencian.
				           |
				           |¿Tomar el archivo del programa y reemplazar con él el existente en el ordenador o
				           |abrir el existente sin actualizar?'"));
		Else
			// All matches (both date and size).
			ReturnResult(ResultHandler, "OpenExistingFile");
			Return;
		EndIf;
		
	ElsIf Parameters.ChangeDateUniversalInWorkingDirectory
	        < Parameters.ChangeDateUniversalInFileStorage Then
		// The most recent file is in the file storage
		
		If FileData.InWorkingDirectoryForRead = False Then
			// The file in the working directory is for editing.
			
			Parameters.Insert("Title", NStr("ru = 'В программе более новая версия файла'; en = 'Newer file version in application'; pl = 'Program ma nowszą wersję pliku';de = 'Das Programm hat eine neuere Version der Datei';ro = 'În program este o versiune mai nouă a fișierului';tr = 'Uygulamada dosyanın daha yeni sürümü mevcut'; es_ES = 'En el programa hay una versión del archivo más nueva'"));
			
			Parameters.Insert("Message",
				NStr("ru = 'Файл в программе, отмеченный как занятый для редактирования,
				           |имеет более позднюю дату изменения (новее), чем его копия в рабочем каталоге на компьютере.
				           |
				           |Взять файл из программы и заменить им существующий на компьютере или
				           |открыть существующий?'; 
				           |en = 'The file in the application was modified
				           |later than its local copy.
				           |
				           |Do you want to retrieve the file from the application
				           |or open the local copy?'; 
				           |pl = 'Plik w programie oznaczonym jako zajęty do edycji,
				           |ma późniejszą datę zmiany (nowszą) niż jego kopię w katalogu roboczym na komputerze.
				           |
				           |Pobrać plik z programu i zastąpić go istniejącym na komputerze lub
				           |otworzyć istniejący?';
				           |de = 'Eine Datei im Programm, die als zur Bearbeitung besetzt markiert ist,
				           |hat ein späteres Änderungsdatum (neuer) als ihre Kopie im Arbeitsverzeichnis auf dem Computer.
				           |
				           |Eine Datei aus dem Programm nehmen und durch eine bestehende auf Ihrem Computer ersetzen oder
				           |eine bestehende öffnen?';
				           |ro = 'Fișierul din program marcat ca ocupat pentru editare,
				           |are data de modificare mai târzie (mai nouă) decât copia lui în directorul pe computer.
				           |
				           |Luați fișierul din program și înlocuiți cu el cel existent pe computer sau
				           |deschideți cel existent fără actualizare?';
				           |tr = 'Uygulamada düzenleme için meşgul olarak işaretlenmiş bir dosya, 
				           |bilgisayarınızdaki çalışma dizinindeki kopyadan daha sonraki bir değiştirme tarihine (daha yeni) sahiptir. 
				           |
				           |Uygulamadan bir dosya alıp bilgisayarda varolan bir dosya ile değiştirilsin mi yoksa 
				           |varolan bir dosya açılsın mı?'; 
				           |es_ES = 'El archivo en el programa marcado como ocupado para editar
				           |tiene la fecha de cambio más tarde (más nueva) que su copia en el catálogo de trabajo en el ordenador.
				           |
				           |¿Tomar el archivo del programa y reemplazar con él el existente en el ordenador o
				           |abrir el existente?'"));
		Else
			// The file in the working directory is for reading.
			
			// Updating the file from the storage without asking for confirmation.
			ReturnResult(ResultHandler, "GetFromStorageAndOpen");
			Return;
		EndIf;
	
	ElsIf Parameters.ChangeDateUniversalInWorkingDirectory
	        > Parameters.ChangeDateUniversalInFileStorage Then
		// The most recent file is in the working directory
		
		If FileData.InWorkingDirectoryForRead = False
		   AND FileData.BeingEditedBy = UsersClient.AuthorizedUser() Then
			
			// The file in the working directory is locked for editing by the current user
			ReturnResult(ResultHandler, "OpenExistingFile");
			Return;
		Else
			// The file in the working directory is for reading.
		
			Parameters.Insert("Title", NStr("ru = 'На компьютере более новая копия файла'; en = 'Newer local file version'; pl = 'Na komputerze nowsza kopia pliku';de = 'Auf dem Computer ist eine neuere Kopie der Datei';ro = 'Pe computer este o versiune mai nouă a fișierului';tr = 'Bilgisayarda dosyanın daha yeni kopyası mevcut'; es_ES = 'En el ordenador hay una copia del archivo más nueva'"));
			
			Parameters.Insert(
				"Message",
				NStr("ru = 'Копия файла в рабочем каталоге на компьютере имеет более позднюю дату изменения (новее), чем в программе. Возможно, эта копия была отредактирована.
				           |
				           |Открыть существующий файл на компьютере или заменить его на файл
				           |из программы c потерей изменений и открыть?'; 
				           |en = 'The local file copy was modified later than the file in the application. The local copy might have been edited.
				           |
				           |Do you want to open the local copy or replace it with the file
				           |from the application?'; 
				           |pl = 'Kopia pliku w katalogu roboczym na komputerze ma późniejszą datę zmiany (nowszą) niż w programie. Być może ta kopia została zmodyfikowana.
				           |
				           |Otworzyć istniejący plik na komputerze lub zastąpić go plikiem
				           | programu z utratą zmian i otworzyć go?';
				           |de = 'Die Kopie der Datei im Arbeitsverzeichnis auf dem Computer hat ein späteres Änderungsdatum (neuer) als im Programm. Diese Kopie wurde möglicherweise bearbeitet. 
				           |
				           |Eine bestehende Datei auf Ihrem Computer öffnen oder durch eine Datei
				           |aus dem Programm mit dem Verlust von Änderungen ersetzen und öffnen?';
				           |ro = 'Copia fișierului în directorul pe computer are data de modificare mai târzie (mai nouă) decât în program. Posibil, această copie a fost editată.
				           |
				           |Deschideți fișierul existent pe computer sau îl înlocuiți cu fișierul
				           |din program cu pierderea modificărilor și deschideți?';
				           |tr = 'Bilgisayarınızdaki çalışma dizinindeki bir dosyanın bir kopyası, programda olduğundan daha sonraki bir değişiklik tarihine (daha yeni) sahiptir. Bu kopya düzenlenmiş olabilir. 
				           |
				           |Bilgisayarınızda varolan bir dosya açılsın veya 
				           |uygulamadaki dosya ile değişiklikleri kaybederek değiştirilsin ve açılsın mı?'; 
				           |es_ES = 'La copia del archivo en el catálogo de trabajo en el ordenador tiene la fecha de cambio más tarde (más nueva) que en el programa. Es posible que esta copia haya sido editada.
				           |
				           |¿Abrir el archivo existente en el ordenador o reemplazarlo con el archivo
				           |del programa perdiendo los cambios y abrir?'"));
		EndIf;
	EndIf;
	
	// SelectActionOnFilesDifference
	OpenForm("CommonForm.SelectActionOnFilesDifference", Parameters, , , , , ResultHandler, FormWindowOpeningMode.LockWholeInterface);
	
EndProcedure

// Returns the My Documents directory.
//
Function MyDocumentsDirectory()
	Return DocumentsDir();
EndFunction

// Returns the path to the user working directory.
//
// Parameters:
//  Notification - NotifyDescription - a notification that runs after the user working directory is 
//   received. As a result the Structure returns with the following properties:
//     * Directory        - String - full name of the user working directory.
//     * ErrorDescription - String - an error text if the directory is not received.
//
Procedure GetUserWorkingDirectory(Notification)
	
	ParameterName = "StandardSubsystems.WorkingDirectoryAccessCheckExecuted";
	If ApplicationParameters[ParameterName] = Undefined Then
		ApplicationParameters.Insert(ParameterName, False);
	EndIf;
	
	DirectoryName =
		StandardSubsystemsClient.ClientRunParameters().PersonalFilesOperationsSettings.PathToLocalFileCache;
	
	// Already set.
	If DirectoryName <> Undefined
		AND NOT IsBlankString(DirectoryName)
		AND ApplicationParameters["StandardSubsystems.WorkingDirectoryAccessCheckExecuted"] Then
		
		Result = New Structure;
		Result.Insert("Directory", DirectoryName);
		Result.Insert("ErrorDescription", "");
		
		ExecuteNotifyProcessing(Notification, Result);
		Return;
	EndIf;
	
	Context = New Structure;
	Context.Insert("Notification", Notification);
	Context.Insert("Directory", DirectoryName);
	
	GetUserDataWorkingDirectory(New NotifyDescription(
		"GetUserWorkingDirectoryAfterGetDataDirectory", ThisObject, Context));
	
EndProcedure

// Continue the GetUserWorkingDirectory procedure.
Procedure GetUserWorkingDirectoryAfterGetDataDirectory(Result, Context) Export
	
	If ValueIsFilled(Result.ErrorDescription) Then
		ExecuteNotifyProcessing(Context.Notification, Result);
		Return;
	EndIf;
	
#If NOT WebClient Then
	
	If Result.Directory <> Context.Directory Then
		// Create a directory for files.
		Try
			CreateDirectory(Context.Directory);
			TestDirectoryName = Context.Directory + "CheckAccess\";
			CreateDirectory(TestDirectoryName);
			DeleteFiles(TestDirectoryName);
		Except
			// The path does not exit or not enough rights to create a directory, using the default settings.
			// 
			Context.Directory = Undefined;
		EndTry;
	EndIf;
	
#EndIf
	
	ApplicationParameters["StandardSubsystems.WorkingDirectoryAccessCheckExecuted"] = True;
	
	If Context.Directory = Undefined Then
		SetUserWorkingDirectory(Result.Directory);
	Else
		Result.Directory = Context.Directory;
	EndIf;
	
	ExecuteNotifyProcessing(Context.Notification, Result);
	
EndProcedure

// Shows file editing tips in the web client if the Show file editing tips option is enabled.
// 
//
// Parameters:
//  ResultHandler - NotifyDescription, Undefined - description of the procedure that gets the method result.
//
Procedure OutputNotificationOnEdit(ResultHandler)
	PersonalSettings = PersonalFilesOperationsSettings();
	If PersonalSettings.ShowTooltipsOnEditFiles = True Then
		If NOT FileSystemExtensionAttached() Then
			ReminderText = 
				NStr("ru = 'Сейчас будет предложено открыть или сохранить файл.
				|
				|1. Нажмите кнопку ""Сохранить"" (""Save"").
				|
				|2. Выберите каталог для сохранения файла на компьютере и запомните его
				|(каталог понадобится для редактирования и помещения файла обратно в программу).
				|
				|3. Для редактирования файла перейдите в выбранный ранее каталог,
				|найдите там сохраненный файл и откройте его.'; 
				|en = 'You will be prompted to open or save the file.
				|
				|1. Click ""Save"".
				|
				|2. Select a directory to save the file and remember its name 
				|(you will need it to edit and put the file back to the application).
				|
				|3. To edit the file, open the previously selected directory,
				|find the saved file, and open it.'; 
				|pl = 'Teraz zostanie wyświetlony komunikat, aby otworzyć lub zapisać plik.
				|
				|1. Kliknij przycisk ""Zapisz"" (""Save"").
				|
				|2. Wybierz katalog dla zapisania pliku na komputerze i zapamiętaj go
				|(katalog będzie potrzebny do edycji i przechowania pliku z powrotem w programie).
				|
				|3. Dla edycji pliku, przejdź do wybranego wcześniej katalogu,
				|znajdź tam zapisany plik i otwórz go.';
				|de = 'Sie werden nun aufgefordert, die Datei zu öffnen oder zu speichern.
				|
				|1. Klicken Sie auf die Schaltfläche ""Speichern"" (""Save"").
				|
				|2. Wählen Sie ein Verzeichnis, in dem Sie die Datei auf Ihrem Computer speichern und merken können
				|(Sie benötigen ein Verzeichnis, um die Datei zu bearbeiten und wieder in das Programm zu übertragen).
				|
				|3. Um die Datei zu bearbeiten, gehen Sie in das zuvor ausgewählte Verzeichnis,
				|suchen Sie die gespeicherte Datei und öffnen Sie sie.';
				|ro = 'Vi se va solicita să deschideți sau să salvați fișierul.
				|
				|1. Faceți click pe Salvare.
				|
				|2. Selectați un catalog pentru salvarea fișierului pe calculator și rețineți-l
				|(veți avea nevoie de catalog pentru a edita și a salva fișierul înapoi în aplicație).
				|
				|3. Pentru a edita fișierul, accesați catalogul selectat anterior,
				|găsiți fișierul salvat și deschideți-l.';
				|tr = 'Şimdi dosyayı açmanız ya da kaydetmeniz istenecektir.
				|
				|1.Kaydet üzerine Tıklayın.
				|
				|2.Dosyayı kaydetmek için klasör seçin ve
				|bu klasörü hatırlayın (dosyayı düzenlemek ve dosyayı depolamaya geri koymak için klasöre ihtiyacınız olacaktır).
				|
				|3. Dosyayı düzenlemek için
				| önceden seçilen klasöre gidin, kaydedilmiş dosyayı bulun ve açın.'; 
				|es_ES = 'Ahora se le pedirá abrir o guardar el archivo.
				|
				|1. Haga clic en el botón ""Guardar"" (""Save"").
				|
				|2. Seleccione el catálogo para guardar el archivo en el ordenador y recuerde el catálogo
				|(lo necesitará para editar y volver a colocar el archivo al programa).
				|
				|3. Para editar el archivo pase al catálogo anteriormente seleccionado,
				|encuentre el archivo guardado y ábralo.'");
				
			SystemInfo = New SystemInfo;
			If StrFind(SystemInfo.UserAgentInformation, "Firefox") <> 0 Then
				ReminderText = ReminderText
				+ "
				|
				|"
				+ NStr("ru = '(По умолчанию браузер Mozilla Firefox автоматически сохраняет файлы в каталоге ""Мои документы"")'; en = '(By default Mozilla Firefox saves files to ""My Documents"" directory.)'; pl = '(Domyślnie Mozilla Firefox automatycznie zapisuje pliki w katalogu Moje dokumenty)';de = '(Standardmäßig speichert Mozilla Firefox die Dateien automatisch in ""Eigene Dateien"")';ro = '(În mod implicit, Mozilla Firefox salvează automat fișiere în dosarul ""Documentele mele"")';tr = '(Varsayılan olarak, Mozilla Firefox dosyaları ""Belgelerim"" klasörüne otomatik olarak kaydeder)'; es_ES = '(Por defecto, Mozilla Firefox automáticamente guarda los archivos en el catálogo ""Mis documentos"")'");
			EndIf;
			Buttons = New ValueList;
			Buttons.Add("Continue", NStr("ru = 'Продолжить'; en = 'Continue'; pl = 'Kontynuuj';de = 'Weiter';ro = 'Continuare';tr = 'Devam'; es_ES = 'Continuar'"));
			Buttons.Add("Cancel", NStr("ru = 'Отмена'; en = 'Cancel'; pl = 'Anuluj';de = 'Abbrechen';ro = 'Revocare';tr = 'İptal'; es_ES = 'Cancelar'"));
			ReminderParameters = New Structure;
			ReminderParameters.Insert("Picture", PictureLib.Information32);
			ReminderParameters.Insert("CheckBoxText",
				NStr("ru = 'Больше не показывать это сообщение'; en = 'Do not show this message again'; pl = 'Nie pokazuj ponownie tej wiadomości';de = 'Diese Nachricht nicht wieder anzeigen';ro = 'Nu mai afișa acest mesaj';tr = 'Bu mesajı tekrar gösterme'; es_ES = 'No mostrar este mensaje más'"));
			ReminderParameters.Insert("Title",
				NStr("ru = 'Получение файла для просмотра или редактирования'; en = 'Get file to view or edit'; pl = 'Odbierz plik do przeglądania lub edytowania';de = 'Datei zur Ansicht oder Bearbeitung empfangen';ro = 'Obținerea fișierului pentru vizualizare sau editare';tr = 'Görüntüleme veya düzenleme için dosya al'; es_ES = 'Recibir archivo para ver o editar'"));
			StandardSubsystemsClient.ShowQuestionToUser(
				ResultHandler, ReminderText, Buttons, ReminderParameters);
			
			Return;
		EndIf;
	EndIf;
	ReturnResult(ResultHandler, True);
EndProcedure

// Continue the CheckSignatures procedure.
Procedure CheckSignaturesAfterCreateCryptoManager(CryptoManager, AdditionalParameters) Export
	
	If TypeOf(CryptoManager) <> Type("CryptoManager")
	   AND CryptoManager <> "CryptographyService" Then
		Return;
	EndIf;
	If CryptoManager = "CryptographyService" Then
		CryptoManager = Undefined;
	EndIf;
	
	AdditionalParameters.Insert("IndexOf", -1);
	AdditionalParameters.Insert("CryptoManager", CryptoManager);
	
	CheckSignaturesLoopStart(AdditionalParameters);
	
EndProcedure

// Continue the CheckSignatures procedure.
Procedure CheckSignaturesAfterPrepareData(Data, AdditionalParameters)
	
	If Not CommonClient.SubsystemExists("StandardSubsystems.DigitalSignature") Then
		Return;
	EndIf;
	
	If AdditionalParameters.SelectedRows = Undefined Then
		Collection = AdditionalParameters.Form.DigitalSignatures;
	Else
		Collection = AdditionalParameters.SelectedRows;
	EndIf;
	
	If CommonClient.SubsystemExists("SaaSTechnology.SaaS.DigitalSignatureSaaS") Then
		ModuleSignatureSaaSClientServer = CommonClient.CommonModule("DigitalSignatureSaaSClientServer");
		UseDigitalSignatureSaaS = ModuleSignatureSaaSClientServer.UsageAllowed();
	Else
		UseDigitalSignatureSaaS = False;
	EndIf;
	
	ModuleDigitalSignatureClient = CommonClient.CommonModule("DigitalSignatureClient");
	
	If UseDigitalSignatureSaaS
	 Or Not ModuleDigitalSignatureClient.VerifyDigitalSignaturesOnTheServer() Then
		
		AdditionalParameters.Insert("Data", Data);
		AdditionalParameters.Insert("Collection", Collection);
		AdditionalParameters.Insert("ModuleDigitalSignatureClient", ModuleDigitalSignatureClient);
		If UseDigitalSignatureSaaS Then
			CheckSignaturesAfterCreateCryptoManager("CryptographyService", AdditionalParameters);
		Else
			ModuleDigitalSignatureClient.CreateCryptoManager(
				New NotifyDescription("CheckSignaturesAfterCreateCryptoManager",
					ThisObject, AdditionalParameters),
				"SignatureCheck");
		EndIf;
		Return;
	EndIf;
	
	If TypeOf(Data) = Type("BinaryData") Then
		DataAddress = PutToTempStorage(Data, AdditionalParameters.FormID);
	Else
		DataAddress = Data;
	EndIf;
	
	RowsData = New Array;
	
	For each Item In Collection Do
		SignatureRow = ?(TypeOf(Item) <> Type("Number"), Item,
			AdditionalParameters.Form.DigitalSignatures.FindByID(Item));
		
		RowData = New Structure;
		RowData.Insert("SignatureAddress",        SignatureRow.SignatureAddress);
		RowData.Insert("Status",              SignatureRow.Status);
		RowData.Insert("SignatureCorrect",        SignatureRow.SignatureCorrect);
		RowData.Insert("SignatureDate",         SignatureRow.SignatureDate);
		RowData.Insert("ErrorDescription",      SignatureRow.ErrorDescription);
		RowData.Insert("SignatureValidationDate", SignatureRow.SignatureValidationDate);
		RowsData.Add(RowData);
	EndDo;
	
	FilesOperationsInternalServerCall.CheckSignatures(DataAddress, RowsData);
	
	Index = 0;
	For each Item In Collection Do
		SignatureRow = ?(TypeOf(Item) <> Type("Number"), Item,
			AdditionalParameters.Form.DigitalSignatures.FindByID(Item));
		
		SignatureRow.SignatureCorrect        = RowsData[Index].SignatureCorrect;
		SignatureRow.SignatureValidationDate = RowsData[Index].SignatureValidationDate;
		SignatureRow.ErrorDescription      = RowsData[Index].ErrorDescription;
		
		FilesOperationsInternalClientServer.FillSignatureStatus(SignatureRow);
		Index = Index + 1;
	EndDo;
	
EndProcedure

// Puts files from the hard disk in the storage of attached files.
// 
// Parameters:
//  SelectedFiles                 - Array - paths to files on the hard drive.
//  FileOwner                  - a reference to the file owner.
//  FilesOperationsSettings        - Structure.
//  AttachedFilesArray      - Array (return value) - filled in with the references to the added 
//                                   files.
//  FormID             - a form UUID.
//
Procedure PutSelectedFilesInStorage(Val SelectedFiles,
                                            Val FileOwner,
                                            AttachedFilesArray,
                                            Val FormID,
                                            Val NameOfFileToCreate = "",
                                            Val GroupOfFiles = Undefined)
	
	CommonSettings = CommonFilesOperationsSettings();
	
	CurrentPosition = 0;
	
	LastSavedFile = Undefined;
	
	For Each FullFileName In SelectedFiles Do
		
		CurrentPosition = CurrentPosition + 1;
		
		File = New File(FullFileName);
		
		CheckCanImportFile(File);
		
		If CommonSettings.ExtractTextFilesOnServer Then
			TempTextStorageAddress = "";
		Else
			TempTextStorageAddress = ExtractTextToTempStorage(FullFileName, FormID);
		EndIf;
	
		ModificationTimeUniversal = File.GetModificationUniversalTime();
		
		UpdateFileSavingState(SelectedFiles, File, CurrentPosition, NameOfFileToCreate);
		LastSavedFile = File;
		
		FilesToPut = New Array;
		Details = New TransferableFileDescription(File.FullName, "");
		FilesToPut.Add(Details);
		
		FilesThatWerePut = New Array;
		
		If NOT PutFiles(FilesToPut, FilesThatWerePut, , False, FormID) Then
			CommonClient.MessageToUser(
				StringFunctionsClientServer.SubstituteParametersToString(
					NStr("ru = 'Ошибка при помещении файла
					           |""%1""
					           |в программу.'; 
					           |en = 'An error occurred when storing file
					           |""%1""
					           |to the application.'; 
					           |pl = 'Błąd pomieszczenia pliku
					           |""%1""
					           |do repozytorium tymczasowego.';
					           |de = 'Fehler beim Platzieren der Datei
					           |""%1""
					           |im Zwischenspeicher.';
					           |ro = 'Eroare de plasare a fișierului
					           |""%1""
					           |în storagele temporar.';
					           |tr = '
					           |""%1""
					           | dosyanın geçici depolama için yerleştirme hatası.'; 
					           |es_ES = 'Error de colocar el archivo
					           |""%1""
					           |en el almacenamiento temporal.'"),
					File.FullName) );
			Continue;
		EndIf;
		
		TempFileStorageAddress = FilesThatWerePut[0].Location;
		
	#If MobileClient Then
		PresentationOnMobileDevice = File.GetMobileDeviceLibraryFilePresentation();
		FileExtention = CommonClientServer.GetFileNameExtension(PresentationOnMobileDevice);
		FileNameWithoutExtension = StrReplace(PresentationOnMobileDevice, "." + FileExtention, "");
	#Else
		FileExtention = CommonClientServer.ExtensionWithoutPoint(File.Extension);
		FileNameWithoutExtension = File.BaseName;
	#EndIf
	
		NameWithoutExtension = ?(IsBlankString(NameOfFileToCreate), FileNameWithoutExtension, NameOfFileToCreate);
		// Creating file cards in the database.
		FileParameters = New Structure;
		FileParameters.Insert("FilesOwner",              FileOwner);
		FileParameters.Insert("Author",                       Undefined);
		FileParameters.Insert("BaseName",            NameWithoutExtension);
		FileParameters.Insert("ExtensionWithoutPoint",          FileExtention);
		FileParameters.Insert("GroupOfFiles",                GroupOfFiles);
		FileParameters.Insert("Modified");
		FileParameters.Insert("ModificationTimeUniversal", ModificationTimeUniversal);
		
		AttachedFile = FilesOperationsInternalServerCall.AppendFile(
			FileParameters,
			TempFileStorageAddress,
			TempTextStorageAddress);
		
		If AttachedFile = Undefined Then
			Continue;
		EndIf;
		
		AttachedFilesArray.Add(AttachedFile);
		
	EndDo;
	
	UpdateFileSavingState(SelectedFiles, LastSavedFile, , NameWithoutExtension);
	
EndProcedure

Procedure UpdateFileSavingState(Val SelectedFiles,
											 Val File,
											 Val CurrentPosition = Undefined,
											 NameOfFileToCreate = "");
	
	If File = Undefined Then
		Return;
	EndIf;
	
	FileNameToSave = ?(IsBlankString(NameOfFileToCreate), File.Name, NameOfFileToCreate);
	
	SizeInMB = FilesOperationsInternalClientServer.GetStringWithFileSize(File.Size() / (1024 * 1024));
	
	If SelectedFiles.Count() > 1 Then
		If CurrentPosition = Undefined Then
			ShowUserNotification(NStr("ru = 'Сохранение файлов'; en = 'Save files'; pl = 'Zapisywanie pliku';de = 'Datei speichern';ro = 'Salvarea fișierului';tr = 'Dosyayı kaydet'; es_ES = 'Guardar el archivo'"),, NStr("ru = 'Сохранение файлов успешно завершено'; en = 'The files are saved.'; pl = 'Zapisywanie plików pomyślnie zakończone';de = 'Speichern von Dateien erfolgreich abgeschlossen';ro = 'Salvarea fișierelor este finalizată cu succes';tr = 'Dosya kaydı başarı ile tamamlandı'; es_ES = 'Los archivos se han guardado con éxito'"));
		EndIf;
	Else
		If CurrentPosition = Undefined Then
			NoteText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'Файл ""%1"" (%2 Мб) сохранен.'; en = 'File ""%1"" (%2 MB) is saved.'; pl = 'Plik ""%1"" (%2 MB) zapisany.';de = 'Die Datei ""%1"" (%2 MB) wird gespeichert.';ro = 'Fișierul ""%1"" (%2 Mb) este salvat.';tr = 'Dosya ""%1"" (%2 MB) kaydedildi.'; es_ES = 'Archivo ""%1"" (%2 MB) guardado.'"),
				FileNameToSave,
				SizeInMB);
			ShowUserNotification(NStr("ru = 'Сохранение файла'; en = 'Save files'; pl = 'Zapisywanie pliku';de = 'Datei speichern';ro = 'Salvarea fișierului';tr = 'Dosyayı kaydet'; es_ES = 'Guardar el archivo'"), , NoteText, PictureLib.Information32);
		EndIf;
	EndIf;
	
EndProcedure

// Puts a file from the hard disk into the storage of attached files (web client).
// 
// Parameters:
//  ResultHandler    - NotifyDescription - a procedure, to which control after execution is passed.
//                            Parameters of the procedure being called:
//                             AttachedFile      - Ref, Undefined - a reference to the added file, or
//                                                       Undefined if the file was not placed.
//                             AdditionalParameters - Arbitrary - value that was specified when 
//                                                                      creating the notification object.
//  FileOwner           - a reference to the file owner.
//  FilesOperationsSettings - structure.
//  UUID      - the form UUID.
//
Procedure PutSelectedFilesInStorageWeb(ResultHandler, Val FileOwner, Val FormID)
	
	Parameters = New Structure;
	Parameters.Insert("FileOwner", FileOwner);
	Parameters.Insert("ResultHandler", ResultHandler);
	
	NotifyDescription = New NotifyDescription("PutSelectedFilesInStorageWebCompletion", ThisObject, Parameters);
	BeginPutFile(NotifyDescription, , ,True, FormID);
	
EndProcedure

// Continues the PutSelectedFilesInStorageWeb procedure.
Procedure PutSelectedFilesInStorageWebCompletion(Result, Address, SelectedFileName, AdditionalParameters) Export
	
	Handler = AdditionalParameters.ResultHandler;
	If Not Result Then
		ExecuteNotifyProcessing(Handler, Undefined);
		Return;
	EndIf;
	
	TempFileStorageAddress = Address;
	FileName = SelectedFileName;
	FileOwner = AdditionalParameters.FileOwner;
	PathStructure = CommonClientServer.ParseFullFileName(SelectedFileName);
	FilesGroup = ?(Handler.AdditionalParameters.Property("GroupOfFiles"),
		Handler.AdditionalParameters.GroupOfFiles, "");
	
	If Not IsBlankString(PathStructure.Extension) Then
		Extension = CommonClientServer.ExtensionWithoutPoint(PathStructure.Extension);
		NameWithoutExtension = PathStructure.BaseName;
	Else
		Raise StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Ошибка при помещении файла
			           |""%1""
			           |в программу.'; 
			           |en = 'An error occurred when storing file
			           |""%1""
			           |to the application.'; 
			           |pl = 'Błąd pomieszczenia pliku
			           |""%1""
			           |do repozytorium tymczasowego.';
			           |de = 'Fehler beim Platzieren der Datei
			           |""%1""
			           |im Zwischenspeicher.';
			           |ro = 'Eroare de plasare a fișierului
			           |""%1""
			           |în storagele temporar.';
			           |tr = '
			           |""%1""
			           | dosyanın geçici depolama için yerleştirme hatası.'; 
			           |es_ES = 'Error de colocar el archivo
			           |""%1""
			           |en el almacenamiento temporal.'"),
			FileName);
	EndIf;
	
	CheckExtentionOfFileToDownload(Extension);
	FileParameters = New Structure;
	FileParameters.Insert("FilesOwner",              FileOwner);
	FileParameters.Insert("Author",                       Undefined);
	FileParameters.Insert("BaseName",            NameWithoutExtension);
	FileParameters.Insert("ExtensionWithoutPoint",          Extension);
	FileParameters.Insert("GroupOfFiles",                ?(ValueIsFilled(FilesGroup), FilesGroup, ""));
	FileParameters.Insert("Modified");
	FileParameters.Insert("ModificationTimeUniversal");
	
	// Creating file cards in the database.
	AttachedFile = FilesOperationsInternalServerCall.AppendFile(
		FileParameters,
		TempFileStorageAddress);
		
	ExecuteNotifyProcessing(Handler, AttachedFile);
	
EndProcedure

// Checks whether it is possible to unlock File.
//
// Parameters:
//  ObjectRef - CatalogRef.Files - a file.
//
//  EditedByCurrentUser - Boolean - file is edited by the current user.
//                 
//
//  EditedBy  - CatalogRef.Users - the user who locked the file.
//
//  ErrorString - a string, where the reason of an error is returned (for example, "File is locked 
//                 by other user").
//
// Returns:
//  Boolean. True if the file can be unlocked.
//
Function AbilityToUnlockFile(ObjectRef,
                                  EditedByCurrentUser,
                                  BeingEditedBy,
                                  ErrorRow = "") Export
	
	If EditedByCurrentUser Then 
		Return True;
	ElsIf Not ValueIsFilled(BeingEditedBy) Then
		ErrorRow = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Невозможно освободить файл ""%1"",
			           |т.к. он никем не занят.'; 
			           |en = 'Cannot unlock file ""%1""
			           |because it is not locked.'; 
			           |pl = 'Nie można odblokować
			           |pliku ""%1"", ponieważ jest on nie zajęty przez nikogo.';
			           |de = 'Unmöglich, die 
			           |Datei ""%1"" zu entsperren, weil sie von niemandem besetzt ist.';
			           |ro = 'Fișierul ""%1"" nu poate fi deblocat,
			           |deoarece el nu este ocupat.';
			           |tr = '"
" dosyası %1 başkası tarafından işgal edildiği için kilidi açılamadı.'; 
			           |es_ES = 'Imposible desbloquear
			           |el archivo ""%1"" debido a que está ocupado por nadie.'"),
			String(ObjectRef));
		Return False;
	Else
		If PersonalFilesOperationsSettings().IsFullUser Then
			Return True;
		EndIf;
		
		ErrorRow = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Невозможно освободить файл ""%1"",
			           |т.к. он занят пользователем ""%2"".'; 
			           |en = 'Cannot unlock file ""%1""
			           |because it is locked by ""%2"".'; 
			           |pl = 'Nie można odblokować
			           |pliku ""%1"", ponieważ jest on zajęty przez użytkownika ""%2"".';
			           |de = 'Die 
			           |Datei ""%1"" kann nicht entsperrt werden, da sie vom Benutzer belegt ist ""%2"".';
			           |ro = 'Fișierul ""%1"" nu poate fi deblocat,
			           |deoarece el este ocupat de utilizatorul ""%2"".';
			           |tr = '"
" dosyası ""%1"" kullanıcı tarafından işgal edildiği için kilidi %2 açılamadı.'; 
			           |es_ES = 'Imposible desbloquear
			           |el archivo ""%1"" debido a que está ocupado por el usuario ""%2"".'"),
			String(ObjectRef),
			String(BeingEditedBy));
		Return False;
	EndIf;
	
EndFunction

Procedure UnlockFiles(FileList) Export
	FilesArray = New Array;
	For Each ListItem In FileList.SelectedRows Do
		RowData = FileList.RowData(ListItem);
		If Not AbilityToUnlockFile(
				RowData.Ref,
				RowData.CurrentUserEditsFile,
				RowData.BeingEditedBy) Then
			Continue;
		EndIf;
		FilesArray.Add(RowData.Ref);
	EndDo;
	
	If FilesArray.Count() = 0 Then 
		Return;
	EndIf;
	
	LockedFilesCount = FilesOperationsInternalServerCall.UnlockFiles(FilesArray);
	StandardSubsystemsClient.SetClientParameter("LockedFilesCount", LockedFilesCount);
	If FilesArray.Count() > 0 Then
		NotifyChanged(TypeOf(FilesArray[0]));
		Notify("Write_File", New Structure, Undefined);
	Else	
		NotifyChanged(FilesArray[0]);
		Notify("Write_File", New Structure, FilesArray[0]);
	EndIf;
EndProcedure

// Unlocks file without updating it.
//
// Parameters:
//  FileData             - a structure with file data.
//  UUID - the managed form UUID.
//
Procedure UnlockFileWithoutQuestion(FileData, UUID = Undefined)
	
	FilesOperationsInternalServerCall.UnlockFile(FileData, UUID);
	ExtensionAttached = FileSystemExtensionAttached();
	If ExtensionAttached Then
		ReregisterFileInWorkingDirectory(FileData, True, FileData.OwnerWorkingDirectory <> "");
	EndIf;
	
	ShowUserNotification(NStr("ru = 'Файл освобожден'; en = 'The file is released.'; pl = 'Plik wolny';de = 'Die Datei wird veröffentlicht';ro = 'Fișierul este lansat';tr = 'Dosya bırakıldı'; es_ES = 'Archivo está lanzado'"),
		FileData.URL, FileData.FullVersionDescription, PictureLib.Information32);
	
EndProcedure

// Moves files to the specified folder.
//
// Parameters:
//  ObjectsRef - Array - an array of files.
//
//  Folder         - CatalogRef.FilesFolders - a folder, where files must be moved.
//                  
//
Procedure MoveFilesToFolder(ObjectsRef, Folder) Export
	
	FilesData = FilesOperationsInternalServerCall.MoveFiles(ObjectsRef, Folder);
	
	For Each FileData In FilesData Do
		
		ShowUserNotification(
			NStr("ru = 'Перенос файла'; en = 'Move file'; pl = 'Przemieszczenie pliku';de = 'Datei übertragen';ro = 'Transferați fișierul';tr = 'Dosyayı taşı'; es_ES = 'Transferir el archivo'"),
			FileData.URL,
			StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'Файл ""%1""
				           |перенесен в папку ""%2"".'; 
				           |en = 'File ""%1""
				           |is moved to folder ""%2"".'; 
				           |pl = 'Plik ""%1""
				           | został przeniesiony do folderu ""%2"".';
				           |de = 'Die Datei ""%1""
				           |wurde in den Ordner ""%2"" verschoben.';
				           |ro = 'Fișierul ""%1""
				           |a fost transferat în folderul ""%2"".';
				           |tr = 'Dosya ""%1"" 
				           | ""%2"" klasöre taşındı.'; 
				           |es_ES = 'El archivo ""%1""
				           | ha sido trasladado en la carpeta ""%2"".'"),
				String(FileData.Ref),
				String(Folder)),
			PictureLib.Information32);
		
	EndDo;
	
EndProcedure

// Extracts text from a file and puts it to a temporary storage.
Function ExtractTextToTempStorage(FullFileName, UUID = "", Cancel = False,
	Encoding = Undefined)
	
	TempStorageAddress = "";
	
	#If Not WebClient Then
		
		Text = ExtractText(FullFileName, Cancel, Encoding);
		
		If IsBlankString(Text) Then
			Return "";
		EndIf;
		
		TempFileName = GetTempFileName();
		TextFile = New TextWriter(TempFileName, TextEncoding.UTF8);
		TextFile.Write(Text);
		TextFile.Close();
		
		ImportResult = PutFileFromHardDriveInTempStorage(TempFileName, , UUID);
		If ImportResult <> Undefined Then
			TempStorageAddress = ImportResult;
		EndIf;
		
		DeleteFiles(TempFileName);
		
	#EndIf
	
	Return TempStorageAddress;
	
EndFunction

// Returns a string constant for generating event log messages.
//
// Returns:
//   Row
//
Function EventLogEvent()
	
	Return NStr("ru = 'Файлы'; en = 'Files'; pl = 'Pliki';de = 'Dateien';ro = 'Fișiere';tr = 'Ekler'; es_ES = 'Archivos'", CommonClient.DefaultLanguageCode());
	
EndFunction

// Returns a message text about an error creating a new file.
//
// Parameters:
//  ErrorInformation - ErrorInformation.
//
Function ErrorCreatingNewFile(ErrorInformation)
	
	Return StringFunctionsClientServer.SubstituteParametersToString(
		NStr("ru = 'Ошибка создания нового файла.
		           |
		           |%1'; 
		           |en = 'Cannot create the file.
		           |
		           |%1'; 
		           |pl = 'Wystąpił błąd podczas tworzenia nowego pliku.
		           |
		           |%1';
		           |de = 'Beim Erstellen einer neuen Datei ist ein Fehler aufgetreten. 
		           |
		           |%1';
		           |ro = 'A apărut o eroare la crearea unui fișier nou. 
		           |
		           |%1';
		           |tr = 'Yeni bir dosya oluşturulurken bir hata oluştu.
		           |
		           |%1'; 
		           |es_ES = 'Ha ocurrido un error al crear un nuevo archivo.
		           |
		           |%1'"),
		BriefErrorDescription(ErrorInformation));

EndFunction

// Checks file extension and size.
Function CheckCanImportFile(File,
                                          RaiseException = True,
                                          ArrayOfFilesNamesWithErrors = Undefined)
	
	CommonSettings = CommonFilesOperationsSettings();
	
	// A file size is too big.
	If File.Size() > CommonSettings.MaxFileSize Then
		
		SizeInMB     = File.Size() / (1024 * 1024);
		SizeInMBMax = CommonSettings.MaxFileSize / (1024 * 1024);
		
		ErrorDescription = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Размер файла ""%1"" (%2 Мб)
			           |превышает максимально допустимый размер файла (%3 Мб).'; 
			           |en = 'The size of file ""%1"" (%2 MB)
			           |exceeds the limit (%3 MB).'; 
			           |pl = 'Rozmiar pliku ""%1"" (%2 MB)
			           |przekracza maksymalny dopuszczalny rozmiar pliku (%3 MB).';
			           |de = 'Die Dateigröße ""%1"" (%2 MB)
			           |überschreitet die maximale Dateigröße (%3 MB).';
			           |ro = 'Dimensiunea fișierului ""%1"" (%2 Mb)
			           |depășește dimensiunea maximă permisă a fișierului (%3Mb).';
			           |tr = '"
"%1Mb) dosyasının %2 boyutu  izin verilen maksimum dosya boyutunu (%3 Mb) aşıyor.'; 
			           |es_ES = 'El tamaño del archivo ""%1"" (%2 MB)
			           |supera el tamaño máximo admitido del archivo (%3 MB).'"),
			File.Name,
			FilesOperationsInternalClientServer.GetStringWithFileSize(SizeInMB),
			FilesOperationsInternalClientServer.GetStringWithFileSize(SizeInMBMax));
		
		If RaiseException Then
			Raise ErrorDescription;
		EndIf;
		
		Record = New Structure;
		Record.Insert("FileName", File.FullName);
		Record.Insert("Error",   ErrorDescription);
		
		ArrayOfFilesNamesWithErrors.Add(Record);
		Return False;
	EndIf;
	
	// Checking file extension
	If Not CheckExtentionOfFileToDownload(File.Extension, False) Then
		
		ErrorDescription = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Загрузка файлов с расширением ""%1"" запрещена.
			           |Обратитесь к администратору.'; 
			           |en = 'Uploading files with ""%1"" extension is not allowed.
			           |Please contact the administrator.'; 
			           |pl = 'Nie można importować plików z rozszerzeniem ""%1"".
			           |Skontaktuj się z administratorem.';
			           |de = 'Dateien mit der Erweiterung ""%1"" können nicht importiert werden. 
			           |Kontaktieren Sie Ihren Administrator.';
			           |ro = 'Nu se pot importa fișiere cu extensia ""%1"". 
			           |Adresați-vă administratorului.';
			           |tr = '""%1"" Uzantılı dosya içe aktarılamıyor. 
			           |Yöneticinize başvurun.'; 
			           |es_ES = 'No se puede importar archivos con la extensión ""%1"".
			           |Contactar su administrador.'"),
			File.Extension);
		
		If RaiseException Then
			Raise ErrorDescription;
		EndIf;
		
		Record = New Structure;
		Record.Insert("FileName", File.FullName);
		Record.Insert("Error",   ErrorDescription);
		
		ArrayOfFilesNamesWithErrors.Add(Record);
		Return False;
	EndIf;
	
	// Word temporary files are not used.
	If StrStartsWith(File.Name, "~")
		AND File.GetHidden() Then
		
		Return False;
	EndIf;
	
	Return True;
	
EndFunction

////////////////////////////////////////////////////////////////////////////////
// Completes file editing and puts the file to the server.

// Completes editing a file and puts it to the server.
//
// Parameters:
//   Parameters - Structure - see FileUpdateParameters. 
//
Procedure EndEdit(Parameters)
	
	Handler = New NotifyDescription("FinishEditAfterInstallExtension", ThisObject, Parameters);
	ShowFileSystemExtensionInstallationQuestion(Handler);
	
EndProcedure

// Continuation of the procedure (see above).
Procedure FinishEditAfterInstallExtension(ExtensionInstalled, ExecutionParameters) Export
	ExecutionParameters.Insert("FileData", Undefined);
	
	If FileSystemExtensionAttached() Then
		FinishEditWithExtension(ExecutionParameters);
	Else
		FinishEditWithoutExtension(ExecutionParameters);
	EndIf;
EndProcedure

// Continuation of the procedure (see above).
Procedure FinishEditWithExtension(ExecutionParameters)
	// Web client with file system extension,
	// Thin client,
	// Thick client.
	
	ExecutionParameters.FileData = FilesOperationsInternalServerCall.FileDataAndWorkingDirectory(ExecutionParameters.ObjectRef);
	
	// Checking the ability to unlock the file.
	ErrorText = "";
	CanUnlockFile = AbilityToUnlockFile(
		ExecutionParameters.FileData.Ref,
		ExecutionParameters.FileData.CurrentUserEditsFile,
		ExecutionParameters.FileData.BeingEditedBy,
		ErrorText);
	If Not CanUnlockFile Then
		ReturnResultAfterShowWarning(ExecutionParameters.ResultHandler, ErrorText, False);
		Return;
	EndIf;
	
	ExecutionParameters.Insert("FullFilePath", ExecutionParameters.PassedFullPathToFile);
	If ExecutionParameters.FullFilePath = "" Then
		ExecutionParameters.FullFilePath = ExecutionParameters.FileData.FullFileNameInWorkingDirectory;
	EndIf;
	
	// Checking whether the file is on the hard drive.
	ExecutionParameters.Insert("NewVersionFile", New File(ExecutionParameters.FullFilePath));
	
	If Not ValueIsFilled(ExecutionParameters.FullFilePath)
	 Or Not ExecutionParameters.NewVersionFile.Exist() Then
		
		If ExecutionParameters.ApplyToAll = False Then
			If Not IsBlankString(ExecutionParameters.FullFilePath) Then
				WarningString = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("ru = 'Не удалось поместить файл
					           |""%1"" (%2),
					           |в программу, т.к. он не существует в рабочем каталоге на компьютере.
					           |
					           |Освободить файл?'; 
					           |en = 'Cannot store file
					           |""%1"" (%2)
					           |to the application as it does not exist in the working directory.
					           |
					           |Do you want to release the file?'; 
					           |pl = 'Nie można umieścić pliku
					           |""%1"" (%2),
					           |w programie, ponieważ nie istnieje on w roboczym katalogu na komputerze.
					           |
					           |Zwolnić plik?';
					           |de = 'Es war nicht möglich, die Datei
					           |""%1"" (%2)
					           |in das Programm einzufügen, da sie nicht im Arbeitsverzeichnis auf dem Computer existiert.
					           |
					           |Die Datei freigeben?';
					           |ro = 'Nu se poate pune fișierul
					           |""%1"" (%2)
					           | în aplicație, deoarece nu există în directorul de lucru de pe calculator.
					           |
					           |Eliberați fișierul?';
					           |tr = 'Bilgisayardaki iş dizininde bulunmadığından dosya "
" (
					           |
					           |) dosya deposuna konulamadı. %1
					           |%2Dosya kilidi açılsın mı?'; 
					           |es_ES = 'No se ha podido colocar el archivo
					           |""%1"" (%2)
					           |en el programa, porque no existe en el catálogo de trabajo en el ordenador.
					           |
					           |¿Liberar el archivo?'"),
					String(ExecutionParameters.FileData.Ref),
					ExecutionParameters.FullFilePath);
			Else
				WarningString = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("ru = 'Не удалось поместить файл ""%1"",
					           |в программу, т.к. он не существует в рабочем каталоге на компьютере.
					           |
					           |Освободить файл?'; 
					           |en = 'Cannot store file ""%1""
					           |to the application as it does not exist in the working directory.
					           |
					           |Do you want to release the file?'; 
					           |pl = 'Nie można umieścić pliku ""%1"",
					           |w programie, ponieważ nie istnieje on w roboczym katalogu na komputerze.
					           |
					           |Zwolnić plik?';
					           |de = 'Es war nicht möglich, die Datei""%1"" 
					           |in das Programm einzufügen, da sie nicht im Arbeitsverzeichnis auf dem Computer existiert.
					           |
					           |Die Datei freigeben?';
					           |ro = 'Nu se poate pune fișierul ""%1""
					           |în aplicație deoarece nu există în directorul de lucru de pe calculator.
					           |
					           |Eliberați fișierul?';
					           |tr = 'Bilgisayardaki iş dizininde bulunmadığından dosya "
" %1dosya deposuna konulamadı. 
					           |
					           |Dosya kilidi açılsın mı?'; 
					           |es_ES = 'No se ha podido colocar el archivo""%1""
					           |en el programa, porque no existe en el catálogo de trabajo en el ordenador.
					           |
					           |¿Liberar el archivo?'"),
					String(ExecutionParameters.FileData.Ref));
			EndIf;
			
			Handler = New NotifyDescription("FinishEditWithExtensionAfterRespondQuestionUnlockFile", ThisObject, ExecutionParameters);
			ShowQueryBox(Handler, WarningString, QuestionDialogMode.YesNo);
		Else
			FinishEditWithExtensionAfterRespondQuestionUnlockFile(-1, ExecutionParameters)
		EndIf;
		
		Return;
	EndIf;
	
	Try
		ReadOnly = ExecutionParameters.NewVersionFile.GetReadOnly();
		ExecutionParameters.NewVersionFile.SetReadOnly(Not ReadOnly);
		ExecutionParameters.NewVersionFile.SetReadOnly(ReadOnly);
	Except
		ErrorText = NStr("ru = 'Не удалось поместить файл ""%1"" в рабочий каталог на компьютер,
			|так как возможно он заблокирован другой программой.'; 
			|en = 'Cannot store file ""%1""
			|to the working directory as it might have been locked by another application.'; 
			|pl = 'Nie można umieścić pliku ""%1"" w katalogu roboczego na komputerze,
			|tak jak możliwe, że jest zablokowany przez inny program.';
			|de = 'Die Datei ""%1""
			| kann nicht in das Arbeitsverzeichnis des Computers kopiert werden, da sie möglicherweise von einer anderen Anwendung gesperrt wurde.';
			|ro = 'Nu se poate pune fișierul ""%1""
			| în directorul de lucru de pe calculator, deoarece ar fi putut fi blocat de o altă aplicație.';
			|tr = 'Dosya ""%1"" başka bir uygulama tarafından kilitlenmiş olabileceğinden dolayı, 
			|bilgisayardaki iş dizinine yerleştirilemedi.'; 
			|es_ES = 'No se ha podido colocar el archivo""%1""en el programa,
			|porque es posible que esté bloqueado por otro programa.'");
		ErrorText = StrReplace(ErrorText, "%1", String(ExecutionParameters.FileData.Ref));
		Raise ErrorText + Chars.LF + Chars.LF + DetailErrorDescription(ErrorInfo());
	EndTry;
	
	// Requesting a comment and version storage flag.
	If ExecutionParameters.CreateNewVersion = Undefined Then
		
		ExecutionParameters.CreateNewVersion = True;
		CreateNewVersionAvailability = True;
		
		If ExecutionParameters.FileData.StoreVersions Then
			ExecutionParameters.CreateNewVersion = True;
			
			// If the author of the current version is not the current user, the "Do not create a new version" 
			// is disabled.
			If ExecutionParameters.FileData.CurrentVersionAuthor <> ExecutionParameters.FileData.BeingEditedBy Then
				CreateNewVersionAvailability = False;
			Else
				CreateNewVersionAvailability = True;
			EndIf;
		Else
			ExecutionParameters.CreateNewVersion = False;
			CreateNewVersionAvailability = False;
		EndIf;
		
		ParametersStructure = New Structure;
		ParametersStructure.Insert("FileRef",                    ExecutionParameters.FileData.Ref);
		ParametersStructure.Insert("VersionComment",            "");
		ParametersStructure.Insert("CreateNewVersion",            ExecutionParameters.CreateNewVersion);
		ParametersStructure.Insert("CreateNewVersionAvailability", CreateNewVersionAvailability);
		
		Handler = New NotifyDescription("CompleteEditingWithExtensionAfterPutFileOnServer", ThisObject, ExecutionParameters);
		OpenForm("DataProcessor.FilesOperations.Form.SaveFileToInfobaseForm", ParametersStructure, , , , , Handler);
		
	Else // The CreateNewVersion and VersionComment parameters are external.
		
		If ExecutionParameters.FileData.StoreVersions Then
			
			// If the author of the current version is not the current user, the "Do not create a new version" 
			// is disabled.
			If ExecutionParameters.FileData.CurrentVersionAuthor <> ExecutionParameters.FileData.BeingEditedBy Then
				ExecutionParameters.CreateNewVersion = True;
			EndIf;
			
		Else
			ExecutionParameters.CreateNewVersion = False;
		EndIf;
		
		FinishEditWithExtensionAfterCheckNewVersion(ExecutionParameters);
	EndIf;
	
EndProcedure

// Continuation of the procedure (see above).
Procedure FinishEditWithExtensionAfterRespondQuestionUnlockFile(Response, ExecutionParameters) Export
	If Response <> -1 Then
		If Response = DialogReturnCode.Yes Then
			ExecutionParameters.UnlockFiles = True;
		Else
			ExecutionParameters.UnlockFiles = False;
		EndIf;
	EndIf;
	
	If ExecutionParameters.UnlockFiles Then
		UnlockFileWithoutQuestion(ExecutionParameters.FileData, ExecutionParameters.FormID);
		ReturnResult(ExecutionParameters.ResultHandler, True);
	Else
		ReturnResult(ExecutionParameters.ResultHandler, False);
	EndIf;
EndProcedure

// Continuation of the procedure (see above).
Procedure CompleteEditingWithExtensionAfterPutFileOnServer(Result, ExecutionParameters) Export
	
	If TypeOf(Result) <> Type("Structure") Then
		ReturnResult(ExecutionParameters.ResultHandler, False);
		Return;
	EndIf;
	
	If Result.ReturnCode <> DialogReturnCode.OK Then
		ReturnResult(ExecutionParameters.ResultHandler, False);
		Return;
	EndIf;
	
	ExecutionParameters.CreateNewVersion = Result.CreateNewVersion;
	ExecutionParameters.VersionComment = Result.VersionComment;
	
	FinishEditWithExtensionAfterCheckNewVersion(ExecutionParameters);
	
EndProcedure

// Continuation of the procedure (see above).
Procedure FinishEditWithExtensionAfterCheckNewVersion(ExecutionParameters)
	
	If Not ExecutionParameters.FileData.Encrypted Then
		FinishEditWithExtensionAfterCheckEncrypted(Undefined, ExecutionParameters);
		Return;
	EndIf;
	
	// The file with the encrypted again flag is encrypted for the same certificates.
	
	ExecutionParameters.Insert("NotificationAfterEncryption", New NotifyDescription(
		"FinishEditWithExtensionAfterCheckEncrypted", ThisObject, ExecutionParameters));
	
	EncryptFileBeforePutFileInFileStorage(ExecutionParameters);
	
EndProcedure

// Continuation of the procedure (see above).
Procedure FinishEditWithExtensionAfterCheckEncrypted(NotDefined, ExecutionParameters) Export
	
	FileInfo = FilesOperationsClientServer.FileInfo("FileWithVersion", ExecutionParameters.NewVersionFile);
	FileInfo.Comment = ExecutionParameters.VersionComment;
	FileInfo.StoreVersions = ExecutionParameters.CreateNewVersion;
	
	If ExecutionParameters.Property("AddressAfterEncryption") Then
		FileInfo.TempFileStorageAddress = ExecutionParameters.AddressAfterEncryption;
	Else
		FilesToPut = New Array;
		Details = New TransferableFileDescription(ExecutionParameters.FullFilePath, "");
		FilesToPut.Add(Details);
		
		FilesThatWerePut = New Array;
		Try
			FilesPut = PutFiles(FilesToPut, FilesThatWerePut,, False, ExecutionParameters.FormID);
		Except
			ErrorInformation = ErrorInfo();
			
			QuestionText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'Не удалось поместить файл с компьютера в программу по причине:
				|""%1"".
				|
				|Повторить операцию?'; 
				|en = 'Cannot store the file to the application. Reason:
				|""%1""
				|
				|Do you want to retry?'; 
				|pl = 'Nie można umieścić pliku z komputera w programie z powodu:
				|""%1"".
				|
				|Powtórzyć operację?';
				|de = 'Es ist nicht möglich, die Datei vom Computer in die Anwendung zu übertragen, da: 
				|""%1"". 
				|
				|Den Vorgang wiederholen?';
				|ro = 'Nu se poate pune fișierul de pe calculator în aplicație din cauza:
				|""%1"".
				|
				|Reîncercați operația?';
				|tr = 'Aşağıdaki nedenle bilgisayardaki dosya uygulamaya yerleştirilemedi: 
				|""%1"". 
				|
				| İşlem tekrarlansın mı?'; 
				|es_ES = 'No se ha podido colocar el archivo del ordenador en el programa a causa de:
				|""%1"".
				|
				|¿Repetir la operación?'"),
				BriefErrorDescription(ErrorInformation));
			
			Notification  = New NotifyDescription("FinishEditWithExtensionAfterCheckEncryptedRepeat", ThisObject, ExecutionParameters);
			ShowQueryBox(Notification, QuestionText, QuestionDialogMode.RetryCancel);
			Return;
		EndTry;
		
		If Not FilesPut Then
			ReturnResult(ExecutionParameters.ResultHandler, False);
			Return;
		EndIf;
		
		If FilesThatWerePut.Count() = 1 Then
			FileInfo.TempFileStorageAddress = FilesThatWerePut[0].Location;
		EndIf;
	EndIf;
	
	CommonFilesOperationsSettings = CommonFilesOperationsSettings();
	If Not CommonFilesOperationsSettings.ExtractTextFilesOnServer Then
		Try
			FileInfo.TempTextStorageAddress = ExtractTextToTempStorage(ExecutionParameters.FullFilePath,
				ExecutionParameters.FormID,, ExecutionParameters.Encoding);
		Except
			FinishEditWithExtensionExceptionProcessing(ErrorInfo(), ExecutionParameters);
			Return;
		EndTry;
	EndIf;
	
	DontChangeRecordInWorkingDirectory = False;
	If ExecutionParameters.PassedFullPathToFile <> "" Then
		DontChangeRecordInWorkingDirectory = True;
	EndIf;
	
	Try
		VersionUpdated = FilesOperationsInternalServerCall.SaveChangesAndUnlockFile(ExecutionParameters.FileData, FileInfo, 
			DontChangeRecordInWorkingDirectory, ExecutionParameters.FullFilePath, UserWorkingDirectory(), 
			ExecutionParameters.FormID);
	Except
		FinishEditWithExtensionExceptionProcessing(ErrorInfo(), ExecutionParameters);
		Return;
	EndTry;
	
	ExecutionParameters.Insert("VersionUpdated", VersionUpdated);
	NewVersion = ExecutionParameters.FileData.CurrentVersion;
	
	If ExecutionParameters.PassedFullPathToFile = "" Then
		
		If ExecutionParameters.Property("DeleteFileFromLocalFileCacheOnCompleteEdit2") Then
			
			DeleteFileFromLocalFileCacheOnCompleteEdit = ExecutionParameters.DeleteFileFromLocalFileCacheOnCompleteEdit2;
			AskQuestion = False;
		Else
			
			PersonalFilesOperationsSettings = PersonalFilesOperationsSettings();
			DeleteFileFromLocalFileCacheOnCompleteEdit = PersonalFilesOperationsSettings.DeleteFileFromLocalFileCacheOnCompleteEdit;
			AskQuestion = PersonalFilesOperationsSettings.ConfirmOnDeleteFilesFromLocalCache;
			
			If DeleteFileFromLocalFileCacheOnCompleteEdit = Undefined Then
				DeleteFileFromLocalFileCacheOnCompleteEdit = False;
			EndIf;
			
			If ExecutionParameters.FileData.OwnerWorkingDirectory <> "" Then
				DeleteFileFromLocalFileCacheOnCompleteEdit = False;
			EndIf;
		EndIf;
		
		If DeleteFileFromLocalFileCacheOnCompleteEdit Then
			Handler = New NotifyDescription("FinishEditWithExtensionAfterDeleteFileFromWorkingDirectory", ThisObject, ExecutionParameters);
			DeleteFileFromWorkingDirectory(Handler, NewVersion, DeleteFileFromLocalFileCacheOnCompleteEdit, AskQuestion);
			Return;
		Else
			File = New File(ExecutionParameters.FullFilePath);
			File.SetReadOnly(True);
		EndIf;
	EndIf;
	
	FinishEditWithExtensionAfterDeleteFileFromWorkingDirectory(-1, ExecutionParameters);
	
EndProcedure

// Continuation of the procedure (see above).
//
Procedure FinishEditWithExtensionAfterCheckEncryptedRepeat(Result, Parameter) Export
	If Result = DialogReturnCode.Retry Then
		FinishEditWithExtensionAfterCheckEncrypted(Undefined, Parameter);
	EndIf;
EndProcedure

// Continuation of the procedure (see above).
Procedure FinishEditWithExtensionAfterDeleteFileFromWorkingDirectory(Result, ExecutionParameters) Export
	
	If ExecutionParameters.ShowNotification Then
		If ExecutionParameters.VersionUpdated Then
			NoteTemplate = NStr("ru = 'Файл ""%1""
			                             |обновлен и освобожден.'; 
			                             |en = 'File ""%1""
			                             |is updated and released.'; 
			                             |pl = 'Plik ""%1""
			                             |został zaktualizowany i zwolniony.';
			                             |de = 'Datei ""%1""
			                             |aktualisiert und freigegeben.';
			                             |ro = 'Fișierul ""%1""
			                             |este actualizat și deblocat.';
			                             |tr = 'Dosya ""%1""
			                             | güncellendi ve kilidi açıldı.'; 
			                             |es_ES = 'Archivo ""%1""
			                             |actualizado y liberado.'");
		Else
			NoteTemplate = NStr("ru = 'Файл ""%1""
			                             |не изменился и освобожден.'; 
			                             |en = 'File ""%1""
			                             |is not modified and released.'; 
			                             |pl = 'Plik ""%1""
			                             |nie został zmieniony i został zwolniony.';
			                             |de = 'Datei ""%1""
			                             |hat sich nicht geändert und ist freigegeben.';
			                             |ro = 'Fișierul
			                             |""%1"" nu a fost modificat și este deblocat.';
			                             |tr = '"
" Dosyası %1 değiştirilmedi ve kilidi açılmadı.'; 
			                             |es_ES = 'Archivo ""%1""
			                             |no cambiado y liberado.'");
		EndIf;
		
		ShowUserNotification(
			NStr("ru = 'Редактирование закончено'; en = 'Editing completed'; pl = 'Edycja została zakończona';de = 'Die Bearbeitung ist abgeschlossen';ro = 'Editarea este finalizată';tr = 'Düzenleme tamamlandı'; es_ES = 'Edición está finalizada'"),
			ExecutionParameters.FileData.URL,
			StringFunctionsClientServer.SubstituteParametersToString(
				NoteTemplate, String(ExecutionParameters.FileData.Ref)),
			PictureLib.Information32);
		
		If Not ExecutionParameters.VersionUpdated Then
			Handler = New NotifyDescription("FinishEditWithExtensionAfterShowNotification", ThisObject, ExecutionParameters);
			ShowInformationFileWasNotModified(Handler);
			Return;
		EndIf;
	EndIf;
	
	FinishEditWithExtensionAfterShowNotification(-1, ExecutionParameters);
	
EndProcedure

// Continuation of the procedure (see above).
Procedure FinishEditWithExtensionAfterShowNotification(Result, ExecutionParameters) Export
	
	
	If TypeOf(Result) = Type("Structure") AND Result.DoNotAskAgain Then
		CommonServerCall.CommonSettingsStorageSave(
			"ApplicationSettings", "ShowFileNotModifiedFlag", False,,, True);
	EndIf;
	
	ReturnResult(ExecutionParameters.ResultHandler, True);
	
EndProcedure

// Continuation of the procedure (see above).
Procedure FinishEditWithExtensionExceptionProcessing(ErrorInformation, ExecutionParameters)
	
	QuestionText = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("ru = 'Не удалось поместить файл ""%1""
		           |с диска на компьютере в программу по причине
		           |""%2"".
		           |
		           |Повторить операцию?'; 
		           |en = 'Cannot store file ""%1""
		           |from the hard drive to the application. Reason:
		           |""%2"".
		           |
		           |Do you want to retry?'; 
		           |pl = 'Nie można umieścić pliku ""%1""
		           |na dysku twardym na komputerze w programie z powodu
		           |""%2"".
		           |
		           |Powtórzyć operację?';
		           |de = 'Die ""%1""-Datei
		           |kann aufgrund von
		           |""%2"" nicht von der Festplatte auf die Anwendung übertragen werden.
		           |
		           |Den Vorgang wiederholen?';
		           |ro = 'Nu se poate pune fișierul ""%1""
		           |din unitatea de disc în aplicație din cauza 
		           |""%2"".
		           |
		           |Reîncercați operația?';
		           |tr = 'Dosya ""%1""
		           | bilgisayardaki diskten 
		           |""%2"" nedenle uygulamaya yerleştirilemedi. 
		           |
		           | İşlem tekrarlansın mı?'; 
		           |es_ES = 'No se ha podido colocar el archivo ""%1""
		           |del disco en el ordenador en el programa a causa de
		           |""%2"".
		           |
		           |¿Repetir la operación?'"),
		String(ExecutionParameters.FileData.Ref),
		BriefErrorDescription(ErrorInformation));
	
	Handler = New NotifyDescription("FinishEditWithExtensionAfterRespondQuestionRepeat", ThisObject, ExecutionParameters);
	ShowQueryBox(Handler, QuestionText, QuestionDialogMode.RetryCancel);
	
EndProcedure

// Continuation of the procedure (see above).
Procedure FinishEditWithExtensionAfterRespondQuestionRepeat(Response, ExecutionParameters) Export
	
	If Response = DialogReturnCode.Cancel Then
		ReturnResult(ExecutionParameters.ResultHandler, False);
		Return;
	EndIf;
	
	FinishEditWithExtensionAfterCheckEncrypted(Undefined, ExecutionParameters);
	
EndProcedure

// Continuation of the procedure (see above).
Procedure FinishEditWithoutExtension(ExecutionParameters)
	// Web client without file system extension.
	
	If ExecutionParameters.FileData = Undefined Then
		ExecutionParameters.FileData  = FilesOperationsInternalServerCall.FileData(ExecutionParameters.ObjectRef);
		ExecutionParameters.StoreVersions                      = ExecutionParameters.FileData.StoreVersions;
		ExecutionParameters.CurrentUserEditsFile = ExecutionParameters.FileData.CurrentUserEditsFile;
		ExecutionParameters.BeingEditedBy                        = ExecutionParameters.FileData.BeingEditedBy;
		ExecutionParameters.CurrentVersionAuthor                 = ExecutionParameters.FileData.CurrentVersionAuthor;
		ExecutionParameters.Encoding                          = ExecutionParameters.FileData.CurrentVersionEncoding;
	EndIf;
	
	// Checking the ability to unlock the file.
	ErrorText = "";
	CanUnlockFile = AbilityToUnlockFile(
		ExecutionParameters.ObjectRef,
		ExecutionParameters.CurrentUserEditsFile,
		ExecutionParameters.BeingEditedBy,
		ErrorText);
	If Not CanUnlockFile Then
		ReturnResultAfterShowWarning(ExecutionParameters.ResultHandler, ErrorText, False);
		Return;
	EndIf;
	
	ExecutionParameters.Insert("FullFilePath", "");
	
	If ExecutionParameters.CreateNewVersion = Undefined Then
		
		ExecutionParameters.CreateNewVersion = True;
		CreateNewVersionAvailability = True;
		
		If ExecutionParameters.StoreVersions Then
			ExecutionParameters.CreateNewVersion = True;
			
			// If the author of the current version is not the current user, the "Do not create a new version" 
			// is disabled.
			If ExecutionParameters.CurrentVersionAuthor <> ExecutionParameters.BeingEditedBy Then
				CreateNewVersionAvailability = False;
			Else
				CreateNewVersionAvailability = True;
			EndIf;
		Else
			ExecutionParameters.CreateNewVersion = False;
			CreateNewVersionAvailability = False;
		EndIf;
		
		ParametersStructure = New Structure;
		ParametersStructure.Insert("FileRef",                    ExecutionParameters.ObjectRef);
		ParametersStructure.Insert("VersionComment",            "");
		ParametersStructure.Insert("CreateNewVersion",            ExecutionParameters.CreateNewVersion);
		ParametersStructure.Insert("CreateNewVersionAvailability", CreateNewVersionAvailability);
		
		Handler = New NotifyDescription("CompleteEditingWithoutExtensionAfterPutFileOnServer", ThisObject, ExecutionParameters);
		
		OpenForm("DataProcessor.FilesOperations.Form.SaveFileToInfobaseForm", ParametersStructure, , , , , Handler);
		
	Else // The CreateNewVersion and VersionComment parameters are external.
		
		If ExecutionParameters.StoreVersions Then
			
			// If the author of the current version is not the current user, the "Do not create a new version" 
			// is disabled.
			If ExecutionParameters.CurrentVersionAuthor <> ExecutionParameters.BeingEditedBy Then
				ExecutionParameters.CreateNewVersion = True;
			EndIf;
			
		Else
			ExecutionParameters.CreateNewVersion = False;
		EndIf;
		
		FinishEditWithoutExtensionAfterCheckNewVersion(ExecutionParameters)
		
	EndIf;
	
EndProcedure

// Continuation of the procedure (see above).
Procedure CompleteEditingWithoutExtensionAfterPutFileOnServer(Result, ExecutionParameters) Export
	
	If TypeOf(Result) <> Type("Structure") Then
		ReturnResult(ExecutionParameters.ResultHandler, False);
		Return;
	EndIf;
	
	If Result.ReturnCode <> DialogReturnCode.OK Then
		ReturnResult(ExecutionParameters.ResultHandler, False);
		Return;
	EndIf;
	
	ExecutionParameters.CreateNewVersion = Result.CreateNewVersion;
	ExecutionParameters.VersionComment = Result.VersionComment;
	
	FinishEditWithoutExtensionAfterCheckNewVersion(ExecutionParameters);
	
EndProcedure

// Continuation of the procedure (see above).
Procedure FinishEditWithoutExtensionAfterCheckNewVersion(ExecutionParameters)
	
	Handler = New NotifyDescription("FinishEditWithoutExtensionAfterReminder", ThisObject, ExecutionParameters);
	ShowReminderBeforePutFile(Handler);
	
EndProcedure

// Continuation of the procedure (see above).
Procedure FinishEditWithoutExtensionAfterReminder(Result, ExecutionParameters) Export
	
	If Result = DialogReturnCode.Cancel Or Result = Undefined Then
		Return;
	EndIf;
	
	If TypeOf(Result) = Type("Structure") AND Result.Property("DoNotAskAgain") AND Result.DoNotAskAgain Then
		CommonServerCall.CommonSettingsStorageSave(
			"ApplicationSettings", "ShowTooltipsOnEditFiles", False,,, True);
	EndIf;
	
	Handler = New NotifyDescription("FinishEditWithoutExtensionAfterImportFile", ThisObject, ExecutionParameters);
	BeginPutFile(Handler, , ExecutionParameters.FullFilePath, , ExecutionParameters.FormID);
	
EndProcedure

// Continuation of the procedure (see above).
Procedure FinishEditWithoutExtensionAfterImportFile(Put, Address, SelectedFileName, ExecutionParameters) Export
	
	If Not Put Then
		ReturnResult(ExecutionParameters.ResultHandler, False);
		Return;
	EndIf;
	
	ExecutionParameters.Insert("ImportedFileAddress", Address);
	ExecutionParameters.Insert("SelectedFileName", SelectedFileName);
	
	If ExecutionParameters.FileData = Undefined Then
		FileData = FilesOperationsInternalServerCall.FileData(ExecutionParameters.ObjectRef);
	Else
		FileData = ExecutionParameters.FileData;
	EndIf;
	If Not FileData.Encrypted Then
		FinishEditWithoutExtensionAfterEncryptFile(Null, ExecutionParameters);
		Return;
	EndIf;
	If CertificatesNotSpecified(FileData.EncryptionCertificatesArray) Then
		ReturnResult(ExecutionParameters.ResultHandler, False);
		Return;
	EndIf;
	
	If Not CommonClient.SubsystemExists("StandardSubsystems.DigitalSignature") Then
		ReturnResult(ExecutionParameters.ResultHandler, False);
		Return;
	EndIf;
	
	// SuggestFileSystemExtensionInstallationNow() is not required, because everything is done in the memory via BinaryData
	
	DataDetails = New Structure;
	DataDetails.Insert("Operation",            NStr("ru = 'Шифрование файла'; en = 'Encrypt file'; pl = 'Szyfrowanie plików';de = 'Dateiverschlüsselung';ro = 'Criptarea fișierului';tr = 'Dosya şifreleme'; es_ES = 'Codificación del archivo'"));
	DataDetails.Insert("DataTitle",     NStr("ru = 'Файл'; en = 'File'; pl = 'Plik';de = 'Datei';ro = 'Fișier';tr = 'Dosya'; es_ES = 'Archivo'"));
	DataDetails.Insert("Data",              Address);
	DataDetails.Insert("Presentation",       ExecutionParameters.ObjectRef);
	DataDetails.Insert("CertificatesSet",   ExecutionParameters.ObjectRef);
	DataDetails.Insert("NoConfirmation",    True);
	DataDetails.Insert("NotifyOnCompletion", False);
	
	FollowUpHandler = New NotifyDescription("FinishEditWithoutExtensionAfterEncryptFile",
		ThisObject, ExecutionParameters);
	
	ModuleDigitalSignatureClient = CommonClient.CommonModule("DigitalSignatureClient");
	ModuleDigitalSignatureClient.Encrypt(DataDetails, , FollowUpHandler);
	
EndProcedure

// Continuation of the procedure (see above).
Procedure FinishEditWithoutExtensionAfterEncryptFile(DataDetails, ExecutionParameters) Export
	
	If DataDetails = Null Then
		Address = ExecutionParameters.ImportedFileAddress;
		
	ElsIf Not DataDetails.Success Then
		ReturnResult(ExecutionParameters.ResultHandler, False);
		Return;
	Else
		If TypeOf(DataDetails.EncryptedData) = Type("BinaryData") Then
			Address = PutToTempStorage(DataDetails.EncryptedData,
				ExecutionParameters.FormID);
		Else
			Address = DataDetails.EncryptedData;
		EndIf;
	EndIf;
	
	FileInfo = FilesOperationsClientServer.FileInfo("FileWithVersion");
	
	FileInfo.TempFileStorageAddress = Address;
	FileInfo.Comment = ExecutionParameters.VersionComment;
	
	PathStructure = CommonClientServer.ParseFullFileName(ExecutionParameters.SelectedFileName);
	If Not IsBlankString(PathStructure.Extension) Then
		FileInfo.ExtensionWithoutPoint = CommonClientServer.ExtensionWithoutPoint(PathStructure.Extension);
		FileInfo.BaseName = PathStructure.BaseName;
	EndIf;
	FileInfo.StoreVersions = ExecutionParameters.CreateNewVersion;
	
	Try
		Result = FilesOperationsInternalServerCall.SaveChangesAndUnlockFileByRef(ExecutionParameters.ObjectRef,
			FileInfo, ExecutionParameters.FullFilePath, UserWorkingDirectory(), 
			ExecutionParameters.FormID);
		ExecutionParameters.FileData = Result.FileData;
	Except
		FinishEditExceptionHandler(ErrorInfo(), ExecutionParameters);
		Return;
	EndTry;
	
	If ExecutionParameters.ShowNotification Then
		If Result.Success Then
			NoteTemplate = NStr("ru = 'Файл ""%1""
			                             |обновлен и освобожден.'; 
			                             |en = 'File ""%1""
			                             |is updated and released.'; 
			                             |pl = 'Plik ""%1""
			                             |został zaktualizowany i zwolniony.';
			                             |de = 'Datei ""%1""
			                             |aktualisiert und freigegeben.';
			                             |ro = 'Fișierul ""%1""
			                             |este actualizat și deblocat.';
			                             |tr = 'Dosya ""%1""
			                             | güncellendi ve kilidi açıldı.'; 
			                             |es_ES = 'Archivo ""%1""
			                             |actualizado y liberado.'");
		Else
			NoteTemplate = NStr("ru = 'Файл ""%1""
			                             |не изменился и освобожден.'; 
			                             |en = 'File ""%1""
			                             |is not modified and released.'; 
			                             |pl = 'Plik ""%1""
			                             |nie został zmieniony i został zwolniony.';
			                             |de = 'Datei ""%1""
			                             |hat sich nicht geändert und ist freigegeben.';
			                             |ro = 'Fișierul
			                             |""%1"" nu a fost modificat și este deblocat.';
			                             |tr = '"
" Dosyası %1 değiştirilmedi ve kilidi açılmadı.'; 
			                             |es_ES = 'Archivo ""%1""
			                             |no cambiado y liberado.'");
		EndIf;
		
		ShowUserNotification(
			NStr("ru = 'Редактирование закончено'; en = 'Editing completed'; pl = 'Edycja została zakończona';de = 'Die Bearbeitung ist abgeschlossen';ro = 'Editarea este finalizată';tr = 'Düzenleme tamamlandı'; es_ES = 'Edición está finalizada'"),
			ExecutionParameters.FileData.URL,
			StringFunctionsClientServer.SubstituteParametersToString(
				NoteTemplate, String(ExecutionParameters.FileData.Ref)),
			PictureLib.Information32);
		
		If Not Result.Success Then
			Handler = New NotifyDescription("FinishEditWithoutExtensionAfterShowNotification", ThisObject, ExecutionParameters);
			ShowInformationFileWasNotModified(Handler);
			Return;
		EndIf;
	EndIf;
	
	FinishEditWithoutExtensionAfterShowNotification(-1, ExecutionParameters);
	
EndProcedure

// Continuation of the procedure (see above).
Procedure FinishEditWithoutExtensionAfterShowNotification(Result, ExecutionParameters) Export
	
	If TypeOf(Result) = Type("Structure") AND Result.Property("DoNotAskAgain") AND Result.DoNotAskAgain Then
		CommonServerCall.CommonSettingsStorageSave(
			"ApplicationSettings","ShowFileNotModifiedFlag", False,,, True);
	EndIf;
	
	ReturnResult(ExecutionParameters.ResultHandler, True);
	
EndProcedure

// Continuation of the procedure (see above).
Procedure FinishEditExceptionHandler(ErrorInformation, ExecutionParameters)
	
	ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("ru = 'Не удалось поместить файл ""%1""
		           |с диска на компьютере в программу по причине
		           |""%2"".
		           |
		           |Повторить операцию?'; 
		           |en = 'Cannot store file ""%1""
		           |from the hard drive to the application. Reason:
		           |""%2"".
		           |
		           |Do you want to retry?'; 
		           |pl = 'Nie można umieścić pliku ""%1""
		           |na dysku twardym na komputerze w programie z powodu
		           |""%2"".
		           |
		           |Powtórzyć operację?';
		           |de = 'Die ""%1""-Datei
		           |kann aufgrund von
		           |""%2"" nicht von der Festplatte auf die Anwendung übertragen werden.
		           |
		           |Den Vorgang wiederholen?';
		           |ro = 'Nu se poate pune fișierul ""%1""
		           |din unitatea de disc în aplicație din cauza 
		           |""%2"".
		           |
		           |Reîncercați operația?';
		           |tr = 'Dosya ""%1""
		           | bilgisayardaki diskten 
		           |""%2"" nedenle uygulamaya yerleştirilemedi. 
		           |
		           | İşlem tekrarlansın mı?'; 
		           |es_ES = 'No se ha podido colocar el archivo ""%1""
		           |del disco en el ordenador en el programa a causa de
		           |""%2"".
		           |
		           |¿Repetir la operación?'"),
		String(ExecutionParameters.ObjectRef),
		BriefErrorDescription(ErrorInformation));
	
	Handler = New NotifyDescription("FinishEditWithoutExtensionAfterRespondQuestionRepeat", ThisObject, ExecutionParameters);
	ShowQueryBox(Handler, ErrorText, QuestionDialogMode.RetryCancel);
	
EndProcedure

// Continuation of the procedure (see above).
Procedure FinishEditWithoutExtensionAfterRespondQuestionRepeat(Response, ExecutionParameters) Export
	If Response = DialogReturnCode.Cancel Then
		ReturnResult(ExecutionParameters.ResultHandler, False);
	Else
		FinishEditWithoutExtensionAfterCheckNewVersion(ExecutionParameters);
	EndIf;
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Selecting the file and creating a new version of it.

// Selects a file on the hard drive and creates a new version of it.
//
// Parameters:
//  ResultHandler - NotifyDescription, Undefined - description of the procedure that gets the method result.
//  FileData - a structure with file data.
//  FormID - a form UUID.
//
// Returns:
//  Boolean. True if the operation is successful.
//
Procedure UpdateFromFileOnHardDrive(
	ResultHandler,
	FileData,
	FormID,
	FileAddingOptions = Undefined)
	
	If Not FileSystemExtensionAttached() Then
		ReturnResult(ResultHandler, False);
		Return;
	EndIf;
		
	Dialog = New FileDialog(FileDialogMode.Open);
	
	If Not IsBlankString(FileData.OwnerWorkingDirectory) Then
		ChoicePath = FileData.OwnerWorkingDirectory;
	Else
		ChoicePath = CommonServerCall.CommonSettingsStorageLoad("ApplicationSettings", "FolderForUpdateFromFile");
	EndIf;
	
	If ChoicePath = Undefined Or ChoicePath = "" Then
		ChoicePath = MyDocumentsDirectory();
	EndIf;
	
	Dialog.Title                   = NStr("ru = 'Выбор файла'; en = 'Select file'; pl = 'Wybierz plik';de = 'Datei auswählen';ro = 'Selectare fișier';tr = 'Dosya seç'; es_ES = 'Seleccionar un archivo'");
	Dialog.Preview     = False;
	Dialog.CheckFileExist = False;
	Dialog.Multiselect          = False;
	Dialog.Directory                     = ChoicePath;
	
	Dialog.FullFileName = CommonClientServer.GetNameWithExtension(
		FileData.FullVersionDescription, FileData.Extension);
	
	If FileAddingOptions <> Undefined
		AND FileAddingOptions.Property("SelectionDialogFilter")
		AND Not IsBlankString(FileAddingOptions.SelectionDialogFilter) Then
		
		Dialog.Filter = FileAddingOptions.SelectionDialogFilter;
		
	Else
		
		EncryptedFilesExtension = "";
		
		If CommonClient.SubsystemExists("StandardSubsystems.DigitalSignature") Then
			ModuleDigitalSignatureClient = CommonClient.CommonModule("DigitalSignatureClient");
			
			If ModuleDigitalSignatureClient.UseEncryption() Then
				EncryptedFilesExtension =
					ModuleDigitalSignatureClient.PersonalSettings().EncryptedFilesExtension;
			EndIf;
		EndIf;
		
		If ValueIsFilled(EncryptedFilesExtension) Then
			Filter = NStr("ru = 'Файл (*.%1)|*.%1|Зашифрованный файл (*.%2)|*.%2|Все файлы (*.*)|*.*'; en = 'File (*.%1)|*.%1|Encrypted file (*.%2)|*.%2|All files (*.*)|*.*'; pl = 'Plik *.) | *. | *.%1)|*.%1|Zaszyfrowany plik (*.%2)|*.%2|Wszystkie pliki (*.*)|*.*';de = 'Datei *.%1) | *.%1 | Verschlüsselte Datei (*.%2) | *. %2| Alle Dateien (*. *) | *. *';ro = 'Fişier *.%1)|*.%1|Fișier criptat(*.%2)|*.%2|Toate fișierele (*.*)|*.*';tr = 'Dosya *.%1) | *.%1 | Şifreli dosya (*.) | *.%2 | Tüm dosyalar (*.%2 *) | *. *'; es_ES = 'Archivo *.%1)|*.%1|Archivo codificado (*.%2)|*.%2|Todos archivos (*.*)|*.*'");
			Dialog.Filter = StringFunctionsClientServer.SubstituteParametersToString(Filter, FileData.Extension, EncryptedFilesExtension);
		Else
			Filter = NStr("ru = 'Файл (*.%1)|*.%1|Все файлы (*.*)|*.*'; en = 'File (*.%1)|*.%1|All files (*.*)|*.*'; pl = 'Plik (*.%1)|*.%1|Wszystkie pliki (*.*)|*.*';de = 'Datei (*.%1) | *. %1| Alle Dateien (*. *) | *. *';ro = 'Fișierul (*.%1)|*.%1|Toate fișierele (*.*)|*.*';tr = 'Dosya (*.%1) | *. | %1Tüm dosyalar (*. *) | *. *'; es_ES = 'Archivo (*.%1)|*.%1|Todos arhcivos (*.*)|*.*'");
			Dialog.Filter = StringFunctionsClientServer.SubstituteParametersToString(Filter, FileData.Extension);
		EndIf;
		
	EndIf;
	
	If Not Dialog.Choose() Then
		ReturnResult(ResultHandler, False);
		Return;
	EndIf;
	
	ChoicePathPrevious = ChoicePath;
	FileOnHardDrive = New File(Dialog.FullFileName);
	
	If FileAddingOptions <> Undefined
		AND FileAddingOptions.Property("MaxSize")
		AND FileAddingOptions.MaxSize > 0
		AND FileOnHardDrive.Size() > FileAddingOptions.MaxSize*1024*1024 Then
		
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Размер файла превышает %1 Мб.'; en = 'The file size exceeds %1 MB.'; pl = 'Rozmiar pliku przekracza %1 MB.';de = 'Die Dateigröße überschreitet %1 MB.';ro = 'Dimensiunea fișierului depășește %1 Mb.';tr = 'Dosya boyutu %1MB''yi aşıyor.'; es_ES = 'El tamaño del archivo supera %1 MB.'"), FileAddingOptions.MaxSize);
		ReturnResultAfterShowWarning(ResultHandler, ErrorText, False);
		Return;
		
	EndIf;
	
	ChoicePath = FileOnHardDrive.Path;
	If IsBlankString(FileData.OwnerWorkingDirectory) Then
		If ChoicePathPrevious <> ChoicePath Then
			CommonServerCall.CommonSettingsStorageSave("ApplicationSettings", "FolderForUpdateFromFile",  ChoicePath);
		EndIf;
	EndIf;
	
	ExecutionParameters = New Structure;
	ExecutionParameters.Insert("ResultHandler", ResultHandler);
	ExecutionParameters.Insert("FileData",          FileData);
	ExecutionParameters.Insert("FormID",   FormID);
	ExecutionParameters.Insert("DialogBoxFullFileName", Dialog.FullFileName);
	ExecutionParameters.Insert("CreateNewVersion",   Undefined);
	ExecutionParameters.Insert("VersionComment",   Undefined);
	
	ExecutionParameters.Insert("FileOnHardDrive", New File(ExecutionParameters.DialogBoxFullFileName));
	ExecutionParameters.Insert("FileNameAndExtensionOnHardDrive", ExecutionParameters.FileOnHardDrive.Name);
	ExecutionParameters.Insert("FileName", ExecutionParameters.FileOnHardDrive.BaseName);
	
	ExecutionParameters.Insert("ChangeTimeSelected",
		ExecutionParameters.FileOnHardDrive.GetModificationUniversalTime());
	
	ExecutionParameters.Insert("FileExtensionOnHardDrive",
		CommonClientServer.ExtensionWithoutPoint(ExecutionParameters.FileOnHardDrive.Extension));
	
	ExecutionParameters.Insert("EncryptedFilesExtension", EncryptedFilesExtension);
	
	ExecutionParameters.Insert("FileEncrypted", Lower(ExecutionParameters.FileExtensionOnHardDrive)
		= Lower(ExecutionParameters.EncryptedFilesExtension));
		
	CheckCanImportFile(FileOnHardDrive);
	If Not ExecutionParameters.FileEncrypted Then
		UpdateFromFileOnHardDriveFollowUp(ExecutionParameters);
		Return;
	EndIf;
	
	// cutting .p7m at the end.
	Position = StrFind(ExecutionParameters.FileNameAndExtensionOnHardDrive, ExecutionParameters.FileExtensionOnHardDrive);
	ExecutionParameters.FileNameAndExtensionOnHardDrive = Left(ExecutionParameters.FileNameAndExtensionOnHardDrive, Position - 2);
	
	// cutting .p7m at the end.
	ExecutionParameters.Insert("DialogBoxFullFileNamePrevious", ExecutionParameters.DialogBoxFullFileName);
	Position = StrFind(ExecutionParameters.DialogBoxFullFileName, ExecutionParameters.FileExtensionOnHardDrive);
	ExecutionParameters.DialogBoxFullFileName = Left(ExecutionParameters.DialogBoxFullFileName, Position - 2);
	
	TempFileNonEncrypted = New File(ExecutionParameters.DialogBoxFullFileName);
	
	ExecutionParameters.FileExtensionOnHardDrive = CommonClientServer.ExtensionWithoutPoint(
		TempFileNonEncrypted.Extension);
	
	// Decrypt here and enter the same date of change, as of DialogBoxFullFileNamePrevious.
	
	FilesToPut = New Array;
	FileDetails = New TransferableFileDescription(ExecutionParameters.DialogBoxFullFileNamePrevious);
	FilesToPut.Add(FileDetails);
	
	BeginPuttingFiles(New NotifyDescription("UpdateFromFileOnHardDriveBeforeDecryption", ThisObject, ExecutionParameters),
		FilesToPut, , False, ExecutionParameters.FormID);
	
EndProcedure

// Continuation of the procedure (see above).
Procedure UpdateFromFileOnHardDriveBeforeDecryption(FilesToPut, ExecutionParameters) Export
	
	If Not ValueIsFilled(FilesToPut) Then
		ReturnResult(ExecutionParameters.ResultHandler, False);
		Return;
	EndIf;
	
	If Not CommonClient.SubsystemExists("StandardSubsystems.DigitalSignature") Then
		Return;
	EndIf;
	
	DataDetails = New Structure;
	DataDetails.Insert("Operation",              NStr("ru = 'Расшифровка файла'; en = 'Decrypt file'; pl = 'Deszyfrowanie plików';de = 'Dateientschlüsselung';ro = 'Decriptarea fișierului';tr = 'Dosya şifresini çözme'; es_ES = 'Descodificación del archivo'"));
	DataDetails.Insert("DataTitle",       NStr("ru = 'Файл'; en = 'File'; pl = 'Plik';de = 'Datei';ro = 'Fișier';tr = 'Dosya'; es_ES = 'Archivo'"));
	DataDetails.Insert("Data",                FilesToPut[0].Location);
	DataDetails.Insert("Presentation",         ExecutionParameters.FileData.Ref);
	DataDetails.Insert("EncryptionCertificates", New Array);
	DataDetails.Insert("NotifyOnCompletion",   False);
	
	FollowUpHandler = New NotifyDescription("UpdateFromFileOnHardDriveAfterDecryption",
		ThisObject, ExecutionParameters);
	
	ModuleDigitalSignatureClient = CommonClient.CommonModule("DigitalSignatureClient");
	ModuleDigitalSignatureClient.Decrypt(DataDetails, , FollowUpHandler);
	
EndProcedure

// Continuation of the procedure (see above).
Procedure UpdateFromFileOnHardDriveAfterDecryption(DataDetails, ExecutionParameters) Export
	
	If Not DataDetails.Success Then
		ReturnResult(ExecutionParameters.ResultHandler, False);
		Return;
	EndIf;
	
	If TypeOf(DataDetails.DecryptedData) = Type("BinaryData") Then
		FileAddress = PutToTempStorage(DataDetails.DecryptedData,
			ExecutionParameters.FormID);
	Else
		FileAddress = DataDetails.DecryptedData;
	EndIf;
	
	ExecutionParameters.Insert("FileAddress", FileAddress);
	
	FilesToTransfer = New Array;
	FileDetails = New TransferableFileDescription(ExecutionParameters.DialogBoxFullFileName, FileAddress);
	FilesToTransfer.Add(FileDetails);
	
	If Not GetFiles(FilesToTransfer, , , False) Then
		ReturnResult(ExecutionParameters.ResultHandler, False);
		Return;
	EndIf;
	
	TempFileNonEncrypted = New File(ExecutionParameters.DialogBoxFullFileName);
	TempFileNonEncrypted.SetModificationUniversalTime(ExecutionParameters.ChangeTimeSelected);
	
	ExecutionParameters.FileEncrypted = False;
	
	UpdateFromFileOnHardDriveFollowUp(ExecutionParameters);
	
EndProcedure

// Continuation of the procedure (see above).
Procedure UpdateFromFileOnHardDriveFollowUp(ExecutionParameters)
	
	// Refresh file data because it could have changed.
	ExecutionParameters.FileData = FilesOperationsInternalServerCall.FileDataAndWorkingDirectory(ExecutionParameters.FileData.Ref);
	
	PreviousVersion = ExecutionParameters.FileData.Version;
	
	NameAndExtensionOfFileInDatabase = CommonClientServer.GetNameWithExtension(
		ExecutionParameters.FileData.FullVersionDescription, ExecutionParameters.FileData.Extension);
	
	ExecutionParameters.Insert("FileDateInDatabase", ExecutionParameters.FileData.UniversalModificationDate);
	
	If ExecutionParameters.ChangeTimeSelected < ExecutionParameters.FileDateInDatabase Then // There is a newer one in the storage.
		
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Файл ""%1""
			           |на диске на компьютере имеет более позднюю дату изменения (%2),
			           |чем выбранный файл (%3).
			           |
			           |Операция прервана.'; 
			           |en = 'The local file copy ""%1""
			           |was modified later (%2)
			           |than the selected file (%3).
			           |
			           |The operation is canceled.'; 
			           |pl = 'Plik ""%1""
			           |na dysku na komputerze ma późniejszy termin zmiany (%2),
			           |niż wybrany plik (%3).
			           |
			           |Operacja przerwana.';
			           |de = 'Die Datei ""%1""
			           |auf der Festplatte des Computers hat ein späteres Änderungsdatum (%2)
			           |als die ausgewählte Datei (%3).
			           |
			           |Der Vorgang wird unterbrochen.';
			           |ro = 'Fișierul 
			           |""%1"" de pe discul pe computer are data de modificare mai târzie (%2),
			           | decât fișierul selectat (%3). 
			           |
			           | Operație întreruptă.';
			           |tr = 'Bilgisayar diskinde bulunan ""%1"" 
			           |
			           |dosya seçilmiş dosyaya (
			           |) göre daha geç değişiklik tarihine (%2) sahiptir. %3
			           | İşlem sonlandırıldı.'; 
			           |es_ES = 'El archivo ""%1""
			           |en el disco en el ordenador tiene la fecha más tarde del cambio (%2)
			           |que el archivo seleccionado (%3).
			           |
			           |Operación interrumpida.'"),
			String(ExecutionParameters.FileData.Ref),
			ToLocalTime(ExecutionParameters.FileDateInDatabase),
			ToLocalTime(ExecutionParameters.ChangeTimeSelected));
		
		ReturnResultAfterShowWarning(ExecutionParameters.ResultHandler, ErrorText, False);
		Return;
	EndIf;
	
	// Checking if there is the file in the working directory
	InWorkingDirectoryForRead = True;
	InOwnerWorkingDirectory = False;
	FullFileName = "";
	FileInWorkingDirectory = FileInLocalFilesCache(
		Undefined,
		PreviousVersion,
		FullFileName,
		InWorkingDirectoryForRead,
		InOwnerWorkingDirectory);
	
	If ExecutionParameters.FileData.CurrentUserEditsFile Then // File was already locked.
		
		If FileInWorkingDirectory = True Then
			FileInCache = New File(FullFileName);
			ModificationTimeInCache = FileInCache.GetModificationUniversalTime();
			
			If ExecutionParameters.ChangeTimeSelected < ModificationTimeInCache Then // The most recent file is in the working directory.
				
				ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("ru = 'Файл ""%1""
					           |в рабочем каталоге имеет более позднюю дату изменения (%2),
					           |чем выбранный файл (%3).
					           |
					           |Операция прервана.'; 
					           |en = 'The file in the working directory ""%1""
					           |was modified later (%2)
					           |than the selected file (%3).
					           |
					           |The operation is canceled.'; 
					           |pl = 'Plik ""%1""
					           |w katalogu roboczym ma późniejszy termin zmiany (%2),
					           |niż wybrany plik (%3).
					           |
					           |Operacja przerwana.';
					           |de = 'Die Datei ""%1""
					           |im Arbeitsverzeichnis hat ein späteres Änderungsdatum (%2)
					           |als die ausgewählte Datei (%3).
					           |
					           |Der Vorgang wird unterbrochen.';
					           |ro = 'Fișierul 
					           |""%1"" din director are data de modificare mai târzie (%2),
					           | decât fișierul selectat (%3). 
					           |
					           | Operație întreruptă.';
					           |tr = 'Çalışma dizinindeki  
					           |""%1"" dosya seçili dosyadan (%3) daha geç değişiklik 
					           |tarihine (%2) sahiptir. 
					           |
					           | İşlem sonlandırıldı.'; 
					           |es_ES = 'El archivo ""%1""
					           |en el catálogo de trabajo tiene la fecha más tarde del cambio (%2)
					           |que el archivo seleccionado (%3).
					           |
					           |Operación interrumpida.'"),
					String(ExecutionParameters.FileData.Ref),
					ToLocalTime(ModificationTimeInCache),
					ToLocalTime(ExecutionParameters.ChangeTimeSelected));
				
				ReturnResultAfterShowWarning(ExecutionParameters.ResultHandler, ErrorText, False);
				Return;
			EndIf;
			
			#If Not WebClient AND NOT MobileClient Then
				// Checking if the file is not locked by the application.
				Try
					TextDocument = New TextDocument;
					TextDocument.Read(FullFileName);
				Except
					ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
						NStr("ru = 'Файл ""%1""
						           |в рабочем каталоге открыт для редактирования.
						           |
						           |Закончите редактирование перед выполнением
						           |обновления из файла на диске.'; 
						           |en = 'File ""%1""
						           |in the working directory is open for editing.
						           |
						           |Please complete the editing before
						           |updating it from a file on a hard drive.'; 
						           |pl = 'Plik ""%1""
						           |w katalogu roboczym jest otwarty do edycji.
						           |
						           |Zakończ edycję przed wykonaniem
						           |aktualizacji z pliku na dysku.';
						           |de = 'Datei ""%1""
						           |im Arbeitsverzeichnis ist zur Bearbeitung geöffnet.
						           |
						           |Beenden Sie die Bearbeitung, bevor Sie aus der Datei auf der Festplatte
						           |aktualisieren.';
						           |ro = 'Fișierul 
						           |""%1"" din director este deschis pentru editare. 
						           |
						           |Finalizați editarea înainte 
						           |de actualizarea de pe fișierul pe disc.';
						           |tr = 'Çalışma dizinindeki
						           | "
" dosyası düzenleme için açıldı. %1
						           |Diskteki dosyadan güncelleme yapmadan önce düzenlemeyi bitir
						           |'; 
						           |es_ES = 'El archivo ""%1""
						           |en el catálogo de trabajo está abierto para editar.
						           |
						           |Termine de editarlo antes de
						           |actualizar del archivo en el disco.'"),
						FullFileName);
					ReturnResultAfterShowWarning(ExecutionParameters.ResultHandler, ErrorText, Undefined);
					Return;
				EndTry;
			#EndIf
			
		EndIf;
		
	EndIf;
	
	If FileInWorkingDirectory AND ExecutionParameters.FileNameAndExtensionOnHardDrive <> NameAndExtensionOfFileInDatabase Then
		Handler = New NotifyDescription("UpdateFromFileOnHardDriveAfterDeleteFileFromWorkingDirectory", ThisObject, ExecutionParameters);
		DeleteFileFromWorkingDirectory(Handler, ExecutionParameters.FileData.CurrentVersion, True);
		Return;
	EndIf;
	
	UpdateFromFileOnHardDriveAfterDeleteFileFromWorkingDirectory(-1, ExecutionParameters);
	
EndProcedure

// Continuation of the procedure (see above).
Procedure UpdateFromFileOnHardDriveAfterDeleteFileFromWorkingDirectory(Result, ExecutionParameters) Export
	
	If Result <> -1 Then
		If Result.Success <> True Then
			ReturnResult(ExecutionParameters.ResultHandler, False);
			Return;
		EndIf;
	EndIf;
	
	ExecutionParameters.Insert("CurrentUserEditsFile", ExecutionParameters.FileData.CurrentUserEditsFile);
	
	If Not ExecutionParameters.FileData.CurrentUserEditsFile Then
		
		ErrorText = "";
		CanLockFile = FilesOperationsClientServer.WhetherPossibleLockFile(ExecutionParameters.FileData, ErrorText);
		If Not CanLockFile Then
			ReturnResultAfterShowWarning(ExecutionParameters.ResultHandler, ErrorText, Undefined);
			Return;
		EndIf;
		
		ErrorText = "";
		FileLocked = FilesOperationsInternalServerCall.LockFile(ExecutionParameters.FileData, ErrorText, 
			ExecutionParameters.FormID);
		If Not FileLocked Then 
			ReturnResultAfterShowWarning(ExecutionParameters.ResultHandler, ErrorText, Undefined);
			Return;
		EndIf;
		
		ForReading = False;
		InOwnerWorkingDirectory = ExecutionParameters.FileData.OwnerWorkingDirectory <> "";
		ReregisterFileInWorkingDirectory(ExecutionParameters.FileData, ForReading, InOwnerWorkingDirectory);
		
	EndIf;
	
	NewFullFileName = "";
	ExecutionParameters.FileData.Insert("UpdatePathFromFileOnHardDrive", ExecutionParameters.DialogBoxFullFileName);
	ExecutionParameters.FileData.Extension = CommonClientServer.ExtensionWithoutPoint(ExecutionParameters.FileExtensionOnHardDrive);
	
	// Putting from the selected file on the hard disk to the working directory because the 
	// UpdatePathFromFileOnHardDisk property is specified.
	Handler = New NotifyDescription("UpdateFromFileOnHardDriveAfterGetFileToWorkingDirectory", ThisObject, ExecutionParameters);
	GetVersionFileToWorkingDirectory(Handler, ExecutionParameters.FileData, NewFullFileName, ExecutionParameters.FormID);
	
EndProcedure

// Continuation of the procedure (see above).
Procedure UpdateFromFileOnHardDriveAfterGetFileToWorkingDirectory(Result, ExecutionParameters) Export
	
	// The result processing is not required.
	If ExecutionParameters.FileEncrypted Then
		FilesOperationsInternalServerCall.CheckEncryptedFlag(ExecutionParameters.FileData.Ref, ExecutionParameters.FileEncrypted);
	EndIf;
	
	PassedFullPathToFile = "";
	
	Handler = New NotifyDescription("UpdateFromFileOnHardDriveAfterFinishEdit", ThisObject, ExecutionParameters);
	If ExecutionParameters.CurrentUserEditsFile Then // File was already locked.
		HandlerParameters = FileUpdateParameters(Handler, ExecutionParameters.FileData.Ref, ExecutionParameters.FormID);
		HandlerParameters.PassedFullPathToFile = PassedFullPathToFile;
		HandlerParameters.CreateNewVersion = ExecutionParameters.CreateNewVersion;
		HandlerParameters.VersionComment = ExecutionParameters.VersionComment;
		SaveFileChanges(HandlerParameters);
	Else
		HandlerParameters = FileUpdateParameters(Handler, ExecutionParameters.FileData.Ref, ExecutionParameters.FormID);
		HandlerParameters.StoreVersions = ExecutionParameters.FileData.StoreVersions;
		HandlerParameters.CurrentUserEditsFile = ExecutionParameters.FileData.CurrentUserEditsFile;
		HandlerParameters.BeingEditedBy = ExecutionParameters.FileData.BeingEditedBy;
		HandlerParameters.CurrentVersionAuthor = ExecutionParameters.FileData.CurrentVersionAuthor;
		HandlerParameters.PassedFullPathToFile = PassedFullPathToFile;
		HandlerParameters.CreateNewVersion = ExecutionParameters.CreateNewVersion;
		HandlerParameters.VersionComment = ExecutionParameters.VersionComment;
		EndEdit(HandlerParameters);
	EndIf;
	
EndProcedure

// Continuation of the procedure (see above).
Procedure UpdateFromFileOnHardDriveAfterFinishEdit(EditResult, ExecutionParameters) Export
	
	If ExecutionParameters.FileEncrypted Then
		DeleteFileWithoutConfirmation(ExecutionParameters.DialogBoxFullFileName);
	EndIf;
	ReturnResult(ExecutionParameters.ResultHandler, True);
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Marking file locked for editing.

// Marks a file locked for editing.
//
// Parameters:
//  ResultHandler - NotifyDescription, Undefined - description of the procedure that gets the method result.
//  ObjectRef            - CatalogRef.Files - a file.
//  UUID - the form UUID.
//
// Returns:
//  Boolean. True if the operation is successful.
//
Procedure LockFileByRef(ResultHandler, ObjectRef, UUID = Undefined)
	
	HandlerParameters = New Structure;
	HandlerParameters.Insert("ResultHandler", ResultHandler);
	HandlerParameters.Insert("ObjectRef", ObjectRef);
	HandlerParameters.Insert("UUID", UUID);
	
	Handler = New NotifyDescription("LockFileByRefAfterInstallExtension", ThisObject, HandlerParameters);
	
	ShowFileSystemExtensionInstallationQuestion(Handler);
	
EndProcedure

// Continuation of the procedure (see above).
Procedure LockFileByRefAfterInstallExtension(ExtensionInstalled, ExecutionParameters) Export
	
	ExecutionParameters.Insert("FileData", Undefined);
	
	ErrorText = "";
	FileDataReceivedAndFileLocked = FilesOperationsInternalServerCall.GetFileDataAndLockFile(ExecutionParameters.ObjectRef,
		ExecutionParameters.FileData, ErrorText, ExecutionParameters.UUID);
	If Not FileDataReceivedAndFileLocked Then // If you cannot lock the file, an error message is displayed.
		ReturnResultAfterShowWarning(ExecutionParameters.ResultHandler, ErrorText, False);
		Return;
	EndIf;
	
	If FileSystemExtensionAttached() Then
		ForReading = False;
		InOwnerWorkingDirectory = ExecutionParameters.FileData.OwnerWorkingDirectory <> "";
		ReregisterFileInWorkingDirectory(ExecutionParameters.FileData, ForReading, InOwnerWorkingDirectory);
	EndIf;
	
	ShowUserNotification(
		NStr("ru = 'Редактирование файла'; en = 'Edit file'; pl = 'Edycja pliku';de = 'Datei bearbeiten';ro = 'Editarea fișierului';tr = 'Dosya düzenle'; es_ES = 'Editar el archivo'"),
		ExecutionParameters.FileData.URL,
		StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Файл ""%1""
			           |занят для редактирования.'; 
			           |en = 'File ""%1""
			           |is locked for editing.'; 
			           |pl = 'Plik ""%1""
			           |zajęty do edycji.';
			           |de = 'Datei ""%1""
			           |ist für die Bearbeitung belegt.';
			           |ro = 'Fișierul ""%1""
			           |este blocat pentru editare.';
			           |tr = 'Dosya ""%1"" 
			           | düzenlenmek üzere meşgul edildi.'; 
			           |es_ES = 'Archivo ""%1""
			           | ocupado para editar.'"), String(ExecutionParameters.FileData.Ref)),
		PictureLib.Information32);
	
	ReturnResult(ExecutionParameters.ResultHandler, True);
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Marking files as locked for editing.

// Marks files as locked for editing.
//
// Parameters:
//  ResultHandler - NotifyDescription, Undefined - description of the procedure that gets the method result.
//  FilesArray - Array - an array of files.
//
Procedure LockFilesByRefs(ResultHandler, Val FilesArray)
	
	HandlerParameters = New Structure;
	HandlerParameters.Insert("ResultHandler", ResultHandler);
	HandlerParameters.Insert("FilesArray", FilesArray);
	
	Handler = New NotifyDescription("LockFilesByRefsAfterInstallExtension", ThisObject, HandlerParameters);
	
	ShowFileSystemExtensionInstallationQuestion(Handler);
	
EndProcedure

// Continuation of the procedure (see above).
Procedure LockFilesByRefsAfterInstallExtension(ExtensionInstalled, ExecutionParameters) Export
	
	// Receiving an array of these files.
	FilesData = New Array;
	FilesOperationsInternalServerCall.GetDataForFilesArray(ExecutionParameters.FilesArray, FilesData);
	InArrayBoundary  = FilesData.UBound();
	
	For Ind = 0 To InArrayBoundary Do
		FileData = FilesData[InArrayBoundary - Ind];
		
		ErrorRow = "";
		If Not FilesOperationsClientServer.WhetherPossibleLockFile(FileData, ErrorRow)
		 Or ValueIsFilled(FileData.BeingEditedBy) Then // Cannot lock.
			
			FilesData.Delete(InArrayBoundary - Ind);
		EndIf;
	EndDo;
	
	// Lock files.
	LockedFilesCount = 0;
	
	For Each FileData In FilesData Do
		
		If Not FilesOperationsInternalServerCall.LockFile(FileData, "") Then 
			Continue;
		EndIf;
		
		If FileSystemExtensionAttached() Then
			ForReading = False;
			InOwnerWorkingDirectory = FileData.OwnerWorkingDirectory <> "";
			ReregisterFileInWorkingDirectory(FileData, ForReading, InOwnerWorkingDirectory);
		EndIf;
		
		LockedFilesCount = LockedFilesCount + 1;
	EndDo;
	
	ShowUserNotification(
		NStr("ru = 'Занять файлы'; en = 'Lock files'; pl = 'Zablokuj pliki';de = 'Dateien sperren';ro = 'Blocați fișierele';tr = 'Dosyaları kilitle'; es_ES = 'Bloquear los archivos'"),
		,
		StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Файлы (%1 из %2) заняты для редактирования.'; en = 'Files (%1 out of %2) are locked for editing.'; pl = 'Pliki (%1 z %2) są zajęte do edycji.';de = 'Dateien (%1 von%2) sind für die Bearbeitung gesperrt.';ro = 'Fișierele (%1 din %2) sunt blocate pentru editare.';tr = 'Dosyalar (%1''in %2) düzenleme için kilitlendi.'; es_ES = 'Archivos (%1 de %2) están bloqueados para editar.'"),
			LockedFilesCount,
			ExecutionParameters.FilesArray.Count()),
		PictureLib.Information32);
	
	ReturnResult(ExecutionParameters.ResultHandler, True);
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Open file by reference to edit.

// Opens file for editing.
//
// Parameters:
//  ResultHandler - NotifyDescription, Undefined - description of the procedure that gets the method result.
//  ObjectRef            - CatalogRef.Files - a file.
//  UUID - the form UUID.
//  OwnerWorkingDirectory - String - a working directory of the owner.
//
// Returns:
//  Boolean. True if the operation is successful.
//
Procedure EditFileByRef(ResultHandler,
	ObjectRef,
	UUID = Undefined,
	OwnerWorkingDirectory = Undefined)
	
	HandlerParameters = New Structure;
	HandlerParameters.Insert("ResultHandler", ResultHandler);
	HandlerParameters.Insert("ObjectRef", ObjectRef);
	HandlerParameters.Insert("UUID", UUID);
	HandlerParameters.Insert("OwnerWorkingDirectory", OwnerWorkingDirectory);
	
	Handler = New NotifyDescription("EditFileByRefAfterInstallExtension", ThisObject, HandlerParameters);
	
	ShowFileSystemExtensionInstallationQuestion(Handler);
	
EndProcedure

// Continuation of the procedure (see above).
Procedure EditFileByRefAfterInstallExtension(ExtensionInstalled, ExecutionParameters) Export
	
	ExecutionParameters.Insert("FileData", Undefined);
	ExecutionParameters.Insert("ExtensionAttached", FileSystemExtensionAttached());
	
	ErrorText = "";
	DataReceived = FilesOperationsInternalServerCall.GetFileDataToOpenAndLockFile(ExecutionParameters.ObjectRef,
		ExecutionParameters.FileData, ErrorText, ExecutionParameters.UUID, ExecutionParameters.OwnerWorkingDirectory);
	
	If Not DataReceived Then
		StandardProcessing = True;
		FilesOperationsClientOverridable.OnFileCaptureError(ExecutionParameters.FileData, StandardProcessing);
		
		If StandardProcessing Then
			// If you cannot lock the file, an error message is displayed.
			ReturnResultAfterShowWarning(ExecutionParameters.ResultHandler, ErrorText, False);
			Return;
		EndIf;
		
		ReturnResult(ExecutionParameters.ResultHandler, True);
		Return;
	EndIf;
	
	If ExecutionParameters.ExtensionAttached Then
		ForReading = False;
		InOwnerWorkingDirectory = ExecutionParameters.FileData.OwnerWorkingDirectory <> "";
		ReregisterFileInWorkingDirectory(ExecutionParameters.FileData, ForReading, InOwnerWorkingDirectory);
	EndIf;
	
	ShowUserNotification(
		NStr("ru = 'Редактирование файла'; en = 'Edit files'; pl = 'Edycja pliku';de = 'Datei bearbeiten';ro = 'Editarea fișierului';tr = 'Dosya düzenle'; es_ES = 'Editar el archivo'"),
		ExecutionParameters.FileData.URL,
		StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Файл ""%1""
			           |занят для редактирования.'; 
			           |en = 'File ""%1""
			           |is locked for editing.'; 
			           |pl = 'Plik ""%1""
			           |zajęty do edycji.';
			           |de = 'Datei ""%1""
			           |ist für die Bearbeitung belegt.';
			           |ro = 'Fișierul ""%1""
			           |este blocat pentru editare.';
			           |tr = 'Dosya ""%1"" 
			           | düzenlenmek üzere meşgul edildi.'; 
			           |es_ES = 'Archivo ""%1""
			           | ocupado para editar.'"), String(ExecutionParameters.FileData.Ref)),
			PictureLib.Information32);
	
	// If File does not have a file, a card will open.
	If ExecutionParameters.FileData.Version.IsEmpty() Then 
		ReturnResultAfterShowValue(ExecutionParameters.ResultHandler, ExecutionParameters.FileData.Ref, True);
		Return;
	EndIf;
	
	If ExecutionParameters.ExtensionAttached Then
		Handler = New NotifyDescription("EditFileByRefWithExtensionAfterGetFileToWorkingDirectory", ThisObject, ExecutionParameters);
		GetVersionFileToWorkingDirectory(
			Handler,
			ExecutionParameters.FileData,
			"",
			ExecutionParameters.UUID);
	Else
		FillTemporaryFormID(ExecutionParameters.UUID, ExecutionParameters);
		
		Handler = New NotifyDescription("EditFileByRefCompletion", ThisObject, ExecutionParameters);
		OpenFileWithoutExtension(Handler, ExecutionParameters.FileData, ExecutionParameters.UUID);
	EndIf;
	
EndProcedure

// Continuation of the procedure (see above).
Procedure EditFileByRefWithExtensionAfterGetFileToWorkingDirectory(Result, ExecutionParameters) Export
	
	If Result.FileReceived = True Then
		UUID = ?(ExecutionParameters.Property("UUID"),
			ExecutionParameters.UUID, Undefined);
		OpenFileWithApplication(ExecutionParameters.FileData, Result.FullFileName, UUID);
	EndIf;
	
	ReturnResult(ExecutionParameters.ResultHandler, Result.FileReceived = True);
	
EndProcedure

// Continuation of the procedure (see above).
Procedure EditFileByRefCompletion(Result, ExecutionParameters) Export
	
	ClearTemporaryFormID(ExecutionParameters);
	
	ReturnResult(ExecutionParameters.ResultHandler, Result = True);
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Opening file for editing.

// Opens file for editing.
//
// Parameters:
//  ResultHandler - NotifyDescription, Undefined - description of the procedure that gets the method result.
//  FileData             - a structure with file data.
//  UUID - the form UUID.
//
Procedure EditFile(ResultHandler, FileData, UUID = Undefined) Export
	
	HandlerParameters = New Structure;
	HandlerParameters.Insert("ResultHandler", ResultHandler);
	HandlerParameters.Insert("FileData", FileData);
	HandlerParameters.Insert("UUID", UUID);
	
	Handler = New NotifyDescription("EditFileAfterInstallExtension", ThisObject, HandlerParameters);
	
	ShowFileSystemExtensionInstallationQuestion(Handler);
	
EndProcedure

// Continuation of the procedure (see above).
Procedure EditFileAfterInstallExtension(ExtensionInstalled, ExecutionParameters) Export
	
	ErrorText = "";
	CanLockFile = FilesOperationsClientServer.WhetherPossibleLockFile(
		ExecutionParameters.FileData,
		ErrorText);
	If Not CanLockFile Then
		ReturnResultAfterShowWarning(ExecutionParameters.ResultHandler, ErrorText, False);
		Return;
	EndIf;
	
	// If File is not locked, lock it.
	If Not ValueIsFilled(ExecutionParameters.FileData.BeingEditedBy) Then
		Handler = New NotifyDescription("EditFileAfterLockFile", ThisObject, ExecutionParameters);
		LockFile(Handler, ExecutionParameters.FileData, ExecutionParameters.UUID);
		Return;
	EndIf;
	
	EditFileAfterLockFile(-1, ExecutionParameters);
	
EndProcedure

// Continuation of the procedure (see above).
Procedure EditFileAfterLockFile(FileData, ExecutionParameters) Export
	
	If FileData = Undefined Then
		ReturnResult(ExecutionParameters.ResultHandler, False);
		Return;
	EndIf;
	
	If FileData <> -1 Then
		ExecutionParameters.FileData = FileData;
	EndIf;
	
	// If File does not have a file, open the card.
	If ExecutionParameters.FileData.Version.IsEmpty() Then 
		ReturnResultAfterShowValue(ExecutionParameters.ResultHandler, ExecutionParameters.FileData.Ref, True);
		Return;
	EndIf;
	
	If FileSystemExtensionAttached() Then
		Handler = New NotifyDescription("EditFileWithExtensionAfterGetFileToWorkingDirectory", ThisObject, ExecutionParameters);
		GetVersionFileToWorkingDirectory(
			Handler,
			ExecutionParameters.FileData,
			"",
			ExecutionParameters.UUID);
	Else
		FillTemporaryFormID(ExecutionParameters.UUID, ExecutionParameters);
		
		Handler = New NotifyDescription("EditFileWithoutExtensionCompletion", ThisObject, ExecutionParameters);
		OpenFileWithoutExtension(Handler, ExecutionParameters.FileData, ExecutionParameters.UUID);
	EndIf;
	
EndProcedure

// Continuation of the procedure (see above).
Procedure EditFileWithExtensionAfterGetFileToWorkingDirectory(Result, ExecutionParameters) Export
	
	If Result.FileReceived = True Then
		UUID = ?(ExecutionParameters.Property("UUID"),
			ExecutionParameters.UUID, Undefined);
		OpenFileWithApplication(ExecutionParameters.FileData, Result.FullFileName, UUID);
	EndIf;
	
	ReturnResult(ExecutionParameters.ResultHandler, Result.FileReceived = True);
	
EndProcedure

// Continuation of the procedure (see above).
Procedure EditFileWithoutExtensionCompletion(Result, ExecutionParameters) Export
	
	ClearTemporaryFormID(ExecutionParameters);
	
	ReturnResult(ExecutionParameters.ResultHandler, Result = True);
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Opening the file version.

// Continuation of the procedure (see above).
Procedure OpenFileVersionAfterInstallExtension(ExtensionInstalled, ExecutionParameters) Export
	
	If FileSystemExtensionAttached() Then
		Handler = New NotifyDescription("OpenFileVersionAfterGetFileToWorkingDirectory", ThisObject, ExecutionParameters);
		GetVersionFileToWorkingDirectory(
			Handler,
			ExecutionParameters.FileData,
			"",
			ExecutionParameters.UUID);
	Else
		Address = FilesOperationsInternalServerCall.GetURLToOpen(
			ExecutionParameters.FileData.Version, ExecutionParameters.UUID);
		
		FileName = CommonClientServer.GetNameWithExtension(
			ExecutionParameters.FileData.FullVersionDescription, ExecutionParameters.FileData.Extension);
		
		GetFile(Address, FileName, True);
		
		ReturnResult(ExecutionParameters.ResultHandler, Undefined);
	EndIf;
	
EndProcedure

// Continuation of the procedure (see above).
Procedure OpenFileVersionAfterGetFileToWorkingDirectory(Result, ExecutionParameters) Export
	
	If Result.FileReceived Then
		UUID = ?(ExecutionParameters.Property("UUID"),
			ExecutionParameters.UUID, Undefined);
		OpenFileWithApplication(ExecutionParameters.FileData, Result.FullFileName, UUID);
	EndIf;
	
	ReturnResult(ExecutionParameters.ResultHandler, Undefined);
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Unlocking files without updating them.

// Unlocks files without updating them.
//
// Parameters:
//  ResultHandler - NotifyDescription, Undefined - description of the procedure that gets the method result.
//  FilesArray - Array - an array of files.
//
Procedure UnlockFilesByRefs(ResultHandler, Val FilesArray)
	
	HandlerParameters = New Structure;
	HandlerParameters.Insert("ResultHandler", ResultHandler);
	HandlerParameters.Insert("FilesArray", FilesArray);
	
	Handler = New NotifyDescription("UnlockFilesByRefsAfterInstallExtension", ThisObject, HandlerParameters);
	
	ShowFileSystemExtensionInstallationQuestion(Handler);
	
EndProcedure

// Continuation of the procedure (see above).
Procedure UnlockFilesByRefsAfterInstallExtension(ExtensionInstalled, ExecutionParameters) Export
	
	// Receiving an array of these files.
	ExecutionParameters.Insert("FilesData", New Array);
	FilesOperationsInternalServerCall.GetDataForFilesArray(ExecutionParameters.FilesArray, ExecutionParameters.FilesData);
	InArrayBoundary = ExecutionParameters.FilesData.UBound();
	
	// Checking the ability to unlock files.
	For Ind = 0 To InArrayBoundary Do
		FileData = ExecutionParameters.FilesData[InArrayBoundary - Ind];
		
		ErrorText = "";
		CanUnlockFile = AbilityToUnlockFile(
			FileData.Ref,
			FileData.CurrentUserEditsFile,
			FileData.BeingEditedBy,
			ErrorText);
		If Not CanUnlockFile Then
			ExecutionParameters.FilesData.Delete(InArrayBoundary - Ind);
		EndIf;
		
	EndDo;
	
	If Not FileSystemExtensionAttached() Then
		Return;
	EndIf;
	
	Handler = New NotifyDescription("UnlockFilesByRefsAfterRespondQuestionCancelEdit", ThisObject, ExecutionParameters);
	
	ShowQueryBox(
		Handler,
		NStr("ru = 'Отмена редактирования файлов может
		           |привести к потере Ваших изменений.
		           |
		           |Продолжить?'; 
		           |en = 'If you cancel editing,
		           |you will lose the changes.
		           |
		           |Do you want to continue?'; 
		           |pl = 'Anulowanie edycji plików może
		           |spowodować utratę Twoich zmian.
		           |
		           |Kontynuować?';
		           |de = 'Wenn Sie die Bearbeitung von Dateien abbrechen, gehen Ihre Änderungen möglicherweise
		           |verloren.
		           |
		           |Fortfahren?';
		           |ro = 'Anularea redactării fișierelor poate
		           |duce la pierderea modificărilor dvs.
		           |
		           |Continuați?';
		           |tr = 'Dosya düzenlemenin
		           | iptali, değişikliklerinizi kaybetmenize neden olabilir. 
		           |
		           |Devam etmek istiyor musunuz?'; 
		           |es_ES = 'Cancelación de la edición de archivos puede
		           |llevar a la pérdida de sus cambios.
		           |
		           |¿Continuar?'"),
		QuestionDialogMode.YesNo,
		,
		DialogReturnCode.No);
	
EndProcedure

// Continuation of the procedure (see above).
Procedure UnlockFilesByRefsAfterRespondQuestionCancelEdit(Response, ExecutionParameters) Export
	
	If Response <> DialogReturnCode.Yes Then
		ReturnResult(ExecutionParameters.ResultHandler, Undefined);
		Return;
	EndIf;
	
	// Locking files.
	For Each FileData In ExecutionParameters.FilesData Do
		
		Parameters = FileUnlockParameters(Undefined, FileData.Ref);
		Parameters.StoreVersions = FileData.StoreVersions;
		Parameters.CurrentUserEditsFile = FileData.CurrentUserEditsFile;
		Parameters.BeingEditedBy = FileData.BeingEditedBy;
		Parameters.DontAskQuestion = True;
		UnlockFile(Parameters);
		
	EndDo;
	
	ShowUserNotification(
		NStr("ru = 'Отменить редактирование файлов'; en = 'Cancel file editing'; pl = 'Skasować redagowanie plików';de = 'Abbrechen der Dateibearbeitung';ro = 'Anulați editarea fișierelor';tr = 'Dosya düzenlemeyi iptal et'; es_ES = 'Cancelar la edición del archivo'"),,
		StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Отменено редактирование файлов (%1 из %2).'; en = 'File editing canceled (%1 out of %2).'; pl = 'Edycja pliku jest anulowana (%1 od %2).';de = 'Dateibearbeitung ist abgebrochen (%1 von %2).';ro = 'Editarea fișierelor este anulată (%1 din %2).';tr = 'Dosya düzenlemesi iptal edildi (%1''in %2).'; es_ES = 'Edición del archivo cancelada (%1 de %2).'"),
			ExecutionParameters.FilesData.Count(),
			ExecutionParameters.FilesArray.Count()),
		PictureLib.Information32);
	
	ReturnResult(ExecutionParameters.ResultHandler, Undefined);
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Unlocking file without updating it.

// Returns:
//   Structure - with the following properties:
//    * ResultHandler    - NotifyDescription, Undefined - description of the procedure that gets the 
//                                method result.
//    * ObjectRef            - CatalogRef.Files - a file.
//    * Version                  - CatalogRef.FilesVersions - a file version.
//    * StoreVersions           - Boolean - store versions.
//    * EditedByCurrentUser - Boolean - file is edited by the current user.
//    * EditedBy             - CatalogRef.Users - user who locked the file.
//    * UUID - UUID - the managed form ID.
//    * DontAskQuestion        - Boolean - do not ask "Cancellation of a file editing may result in 
//                                         the loss of your changes. Continue?"
//
Function FileUnlockParameters(ResultHandler, ObjectRef) Export
	
	HandlerParameters = New Structure;
	HandlerParameters.Insert("ResultHandler", ResultHandler);
	HandlerParameters.Insert("ObjectRef", ObjectRef);
	HandlerParameters.Insert("Version");
	HandlerParameters.Insert("StoreVersions");
	HandlerParameters.Insert("CurrentUserEditsFile");
	HandlerParameters.Insert("BeingEditedBy");
	HandlerParameters.Insert("UUID");
	HandlerParameters.Insert("DontAskQuestion", False);
	Return HandlerParameters;
	
EndFunction	

// Unlocks file without updating it.
//
// Parameters:
//  FileUnlockParameters - Structure - see FileUnlockParameters. 
//
Procedure UnlockFile(FileUnlockParameters)
	
	Handler = New NotifyDescription("UnlockFileAfterInstallExtension", ThisObject, FileUnlockParameters);
	ShowFileSystemExtensionInstallationQuestion(Handler);
	
EndProcedure

// Continuation of the procedure (see above).
Procedure UnlockFileAfterInstallExtension(ExtensionInstalled, ExecutionParameters) Export
	
	ExecutionParameters.Insert("FileData", Undefined);
	ExecutionParameters.Insert("ContinueWork", True);
	
	If ExecutionParameters.StoreVersions = Undefined Then
		ExecutionParameters.FileData = FilesOperationsInternalServerCall.FileData(
			?(ExecutionParameters.ObjectRef <> Undefined, ExecutionParameters.ObjectRef, ExecutionParameters.Version));
		
		If NOT ValueIsFilled(ExecutionParameters.ObjectRef) Then
			ExecutionParameters.ObjectRef = ExecutionParameters.FileData.Ref;
		EndIf;
		ExecutionParameters.StoreVersions                      = ExecutionParameters.FileData.StoreVersions;
		ExecutionParameters.CurrentUserEditsFile = ExecutionParameters.FileData.CurrentUserEditsFile;
		ExecutionParameters.BeingEditedBy                        = ExecutionParameters.FileData.BeingEditedBy;
	EndIf;
	
	// Checking the ability to unlock the file.
	ErrorText = "";
	CanUnlockFile = AbilityToUnlockFile(
		ExecutionParameters.ObjectRef,
		ExecutionParameters.CurrentUserEditsFile,
		ExecutionParameters.BeingEditedBy,
		ErrorText);
	
	If Not CanUnlockFile Then
		ReturnResultAfterShowWarning(ExecutionParameters.ResultHandler, ErrorText, False);
		Return;
	EndIf;
	
	If ExecutionParameters.DontAskQuestion = False Then
		ExecutionParameters.ResultHandler = PrepareHandlerForDialog(ExecutionParameters.ResultHandler);
		Handler = New NotifyDescription("UnlockFileAfterRespondQuestionCancelEdit", ThisObject, ExecutionParameters);
		QuestionText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Отмена редактирования файла
			           |""%1""
			           |может привести к потере ваших изменений.
			           |
			           |Продолжить?'; 
			           |en = 'If you cancel editing file
			           |""%1"",
			           |you will lose the changes.
			           |
			           |Do you want to continue?'; 
			           |pl = 'Anulowanie edycji pliku
			           |""%1""
			           |może spowodować utratę Twoich zmian.
			           |
			           |Kontynuować?';
			           |de = 'Wenn Sie die Bearbeitung einer Datei
			           |""%1""
			           |abbrechen, gehen Ihre Änderungen möglicherweise verloren.
			           |
			           |Fortfahren?';
			           |ro = 'Revocarea editării fișierului
			           |""%1""
			           |poate conduce la pierderea modificărilor dvs.
			           |
			           |Continuați?';
			           |tr = '""%1""
			           |Dosya düzenlemenin
			           | iptali, değişikliklerinizi kaybetmenize neden olabilir. 
			           |
			           |Devam etmek istiyor musunuz?'; 
			           |es_ES = 'Cancelación de la edición de archivo
			           |""%1""
			           |puede llevar a la pérdida de sus cambios.
			           |
			           |¿Continuar?'"),
			String(ExecutionParameters.ObjectRef));
		ShowQueryBox(Handler, QuestionText, QuestionDialogMode.YesNo, , DialogReturnCode.No);
		Return;
	EndIf;
	
	UnlockFileAfterRespondQuestionCancelEdit(-1, ExecutionParameters);
	
EndProcedure

// Continuation of the procedure (see above).
Procedure UnlockFileAfterRespondQuestionCancelEdit(Response, ExecutionParameters) Export
	
	If Response <> -1 Then
		If Response = DialogReturnCode.Yes Then
			ExecutionParameters.ContinueWork = True;
		Else
			ExecutionParameters.ContinueWork = False;
		EndIf;
	EndIf;
	
	If ExecutionParameters.ContinueWork Then
		
		FilesOperationsInternalServerCall.GetFileDataAndUnlockFile(ExecutionParameters.ObjectRef,
			ExecutionParameters.FileData, ExecutionParameters.UUID);
		NotifyChanged(TypeOf(ExecutionParameters.ObjectRef));
		Notify("Write_File", New Structure("Event", "FileDataChanged"), ExecutionParameters.ObjectRef);
		
		If FileSystemExtensionAttached() Then
			ForReading = True;
			InOwnerWorkingDirectory = ExecutionParameters.FileData.OwnerWorkingDirectory <> "";
			ReregisterFileInWorkingDirectory(ExecutionParameters.FileData, ForReading, InOwnerWorkingDirectory);
		EndIf;
		
		If Not ExecutionParameters.DontAskQuestion Then
			ShowUserNotification(
				NStr("ru = 'Файл освобожден'; en = 'File released'; pl = 'Plik wolny';de = 'Die Datei wird veröffentlicht';ro = 'Fișierul este lansat';tr = 'Dosya bırakıldı'; es_ES = 'Archivo está lanzado'"),
				ExecutionParameters.FileData.URL,
				ExecutionParameters.FileData.FullVersionDescription,
				PictureLib.Information32);
		EndIf;
		
	EndIf;
	
	ReturnResult(ExecutionParameters.ResultHandler, True);
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Recording file changes.

// Start recording the file changes.
//
// Parameters:
//   FileUpdateParameters - Structure - see FileUpdateParameters. 
//
Procedure SaveFileChanges(FileUpdateParameters) 
	
	Handler = New NotifyDescription("SaveFileChangesAfterInstallExtensions", ThisObject, FileUpdateParameters);
	ShowFileSystemExtensionInstallationQuestion(Handler);
		
EndProcedure

// Continuation of the procedure (see above).
Procedure SaveFileChangesAfterInstallExtensions(ExtensionInstalled, ExecutionParameters) Export
	
	ExecutionParameters.Insert("FileData", Undefined);
	ExecutionParameters.Insert("TempStorageAddress", Undefined);
	ExecutionParameters.Insert("FullFilePath", Undefined);
	
	If FileSystemExtensionAttached() Then
		SaveFileChangesWithExtension(ExecutionParameters);
	Else
		SaveFileChangesWithoutExtension(ExecutionParameters);
	EndIf;
	
EndProcedure

// Continuation of the procedure (see above).
Procedure SaveFileChangesWithExtension(ExecutionParameters)
	// Code for the thin client, thick client, and web client with the attached extension.
	
	ExecutionParameters.FileData = FilesOperationsInternalServerCall.FileDataAndWorkingDirectory(ExecutionParameters.ObjectRef);
	
	ExecutionParameters.StoreVersions = ExecutionParameters.FileData.StoreVersions;
	
	// Checking the ability to unlock the file.
	ErrorText = "";
	CanUnlockFile = AbilityToUnlockFile(
		ExecutionParameters.FileData.Ref,
		ExecutionParameters.FileData.CurrentUserEditsFile,
		ExecutionParameters.FileData.BeingEditedBy,
		ErrorText);
	If Not CanUnlockFile Then
		ReturnResultAfterShowWarning(ExecutionParameters.ResultHandler, ErrorText, False);
		Return;
	EndIf;
	
	ExecutionParameters.FullFilePath = ExecutionParameters.PassedFullPathToFile;
	If ExecutionParameters.FullFilePath = "" Then
		ExecutionParameters.FullFilePath = ExecutionParameters.FileData.FullFileNameInWorkingDirectory;
	EndIf;
	
	// Checking whether the file is on the hard drive.
	ExecutionParameters.Insert("NewVersionFile", New File(ExecutionParameters.FullFilePath));
	If Not ExecutionParameters.NewVersionFile.Exist() Then
		If Not IsBlankString(ExecutionParameters.FullFilePath) Then
			WarningString = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'Не удалось поместить файл ""%1"" 
				           |в программу, так как он не существует на диске на компьютере:
				           |%2.
				           |
				           |Освободить файл?'; 
				           |en = 'Cannot store file
				           |""%1""
				           |to the application as it does not exist on the hard drive:
				           |%2
				           |Do you want to release the file?'; 
				           |pl = 'Nie można umieścić pliku ""%1"" 
				           |programu, ponieważ on nie istnieje na dysku twardym:
				           |%2.
				           |
				           |Zwolnić plik?';
				           |de = 'Die Datei
				           |""%1""
				           |kann nicht in die Anwendung eingefügt werden, da sie nicht auf der Festplatte vorhanden ist:
				           |%2
				           |Die Datei freigeben?';
				           |ro = 'Fișierul 
				           |""%1""
				           |nu poate fi pus în aplicație deoarece nu există pe hard disk:
				           |%2
				           |Eliberați fișierul?';
				           |tr = 'Dosya ""%1""
				           | bilgisayardaki diskte 
				           |
				           |bulunmadığından dolayı uygulamaya yerleştirilemedi: 
				           |%2. Dosyanın kilidi açılsın mı?'; 
				           |es_ES = 'No se ha podido colocar el archivo ""%1"" 
				           |en el programa, porque no existe en el disco o en el ordenador:
				           |%2.
				           |
				           |¿Liberar el archivo?'"),
				String(ExecutionParameters.FileData.Ref),
				ExecutionParameters.FullFilePath);
		Else
			WarningString = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'Не удалось поместить файл ""%1""
				           |в программу, так как он не существует на диске на компьютере.
				           |
				           |Освободить файл?'; 
				           |en = 'Cannot store file ""%1""
				           |to the application as it does not exist on the hard drive.
				           |
				           |Do you want to release the file?'; 
				           |pl = 'Nie można umieścić pliku ""%1"" 
				           | programu, ponieważ on nie istnieje na dysku twardym:
				           |.
				           |Zwolnić plik?';
				           |de = 'Die Datei ""%1""
				           | kann nicht in die Anwendung eingefügt werden, da sie nicht auf der Festplatte vorhanden ist.
				           |
				           |Die Datei freigeben?';
				           |ro = 'Nu se poate pune ""%1""
				           | fișierul la aplicație deoarece nu există pe hard disk.
				           |
				           |Eliberați fișierul?';
				           |tr = 'Dosya ""%1"" bilgisayardaki diskte 
				           |bulunmadığından dolayı uygulamaya yerleştirilemedi.
				           |
				           |Dosyanın kilidi açılsın mı?'; 
				           |es_ES = 'No se ha podido colocar el archivo ""%1"" 
				           |en el programa, porque no existe en el disco en el ordenador.
				           |
				           |¿Librar el archivo?'"),
				String(ExecutionParameters.FileData.Ref));
		EndIf;
		
		Handler = New NotifyDescription("SaveFileChangesWithExtensionAfterRespondQuestionUnlockFile", ThisObject, ExecutionParameters);
		ShowQueryBox(Handler, WarningString, QuestionDialogMode.YesNo);
		Return;
	EndIf;
	
	// Requesting a comment and version storage flag.
	If ExecutionParameters.CreateNewVersion = Undefined Then
		
		ExecutionParameters.CreateNewVersion = True;
		CreateNewVersionAvailability = True;
		
		If ExecutionParameters.FileData.StoreVersions Then
			ExecutionParameters.CreateNewVersion = True;
			
			// If the author of the current version is not the current user, the "Do not create a new version" 
			// is disabled.
			If ExecutionParameters.FileData.CurrentVersionAuthor <> ExecutionParameters.FileData.BeingEditedBy Then
				CreateNewVersionAvailability = False;
			Else
				CreateNewVersionAvailability = True;
			EndIf;
		Else
			ExecutionParameters.CreateNewVersion = False;
			CreateNewVersionAvailability = False;
			SaveFileChangesWithExtensionAfterCheckNewVersion(ExecutionParameters);
			Return;
		EndIf;
		
		ParametersStructure = New Structure;
		ParametersStructure.Insert("FileRef",                    ExecutionParameters.FileData.Ref);
		ParametersStructure.Insert("VersionComment",            "");
		ParametersStructure.Insert("CreateNewVersion",            ExecutionParameters.CreateNewVersion);
		ParametersStructure.Insert("CreateNewVersionAvailability", CreateNewVersionAvailability);
		
		Handler = New NotifyDescription("SaveFileChangesWithExtensionAfterPutFileOnServer", ThisObject, ExecutionParameters);
		
		OpenForm("DataProcessor.FilesOperations.Form.SaveFileToInfobaseForm", ParametersStructure, , , , , Handler);
		
	Else // The CreateNewVersion and VersionComment parameters are external.
		
		If ExecutionParameters.StoreVersions Then
			
			// If the author of the current version is not the current user, the "Do not create a new version" 
			// is disabled.
			If ExecutionParameters.CurrentVersionAuthor <> ExecutionParameters.BeingEditedBy Then
				ExecutionParameters.CreateNewVersion = True;
			EndIf;
			
		Else
			ExecutionParameters.CreateNewVersion = False;
		EndIf;
		
		SaveFileChangesWithExtensionAfterCheckNewVersion(ExecutionParameters);
		
	EndIf;
	
EndProcedure

// Continuation of the procedure (see above).
Procedure SaveFileChangesWithExtensionAfterRespondQuestionUnlockFile(Response, ExecutionParameters) Export
	
	If Response = DialogReturnCode.Yes Then
		UnlockFileWithoutQuestion(ExecutionParameters.FileData, ExecutionParameters.FormID);
	EndIf;
	
	ReturnResult(ExecutionParameters.ResultHandler, False);
	
EndProcedure

// Continuation of the procedure (see above).
Procedure SaveFileChangesWithExtensionAfterPutFileOnServer(Result, ExecutionParameters) Export
	
	If TypeOf(Result) <> Type("Structure") Then
		ReturnResult(ExecutionParameters.ResultHandler, False);
		Return;
	EndIf;
	
	ReturnCode = Result.ReturnCode;
	If ReturnCode <> DialogReturnCode.OK Then
		ReturnResult(ExecutionParameters.ResultHandler, False);
		Return;
	EndIf;
	
	ExecutionParameters.CreateNewVersion = Result.CreateNewVersion;
	ExecutionParameters.VersionComment = Result.VersionComment;
	
	SaveFileChangesWithExtensionAfterCheckNewVersion(ExecutionParameters);
	
EndProcedure

// Continuation of the procedure (see above).
Procedure SaveFileChangesWithExtensionAfterCheckNewVersion(ExecutionParameters)
	
	If Not ExecutionParameters.FileData.Encrypted Then
		SaveFileChangesWithExtensionAfterCheckEncrypted(Undefined, ExecutionParameters);
		Return;
	EndIf;
	
	// The file with the encrypted again flag is encrypted for the same certificates.
	
	ExecutionParameters.Insert("NotificationAfterEncryption", New NotifyDescription(
		"SaveFileChangesWithExtensionAfterCheckEncrypted", ThisObject, ExecutionParameters));
	
	EncryptFileBeforePutFileInFileStorage(ExecutionParameters);
	
EndProcedure

// Continuation of the procedure (see above).
Procedure SaveFileChangesWithExtensionAfterCheckEncrypted(NotDefined, ExecutionParameters) Export
	
	FileInfo = FilesOperationsClientServer.FileInfo("FileWithVersion", ExecutionParameters.NewVersionFile);
	FileInfo.Comment = ExecutionParameters.VersionComment;
	FileInfo.StoreVersions = ExecutionParameters.CreateNewVersion;
	
	If ExecutionParameters.Property("AddressAfterEncryption") Then
		FileInfo.TempFileStorageAddress = ExecutionParameters.AddressAfterEncryption;
	Else
		FilesToPut = New Array;
		Details = New TransferableFileDescription(ExecutionParameters.FullFilePath, "");
		FilesToPut.Add(Details);
		
		FilesThatWerePut = New Array;
		FilesPut = PutFiles(FilesToPut, FilesThatWerePut, , False, ExecutionParameters.FormID);
		
		If Not FilesPut Then
			ReturnResult(ExecutionParameters.ResultHandler, True);
			Return;
		EndIf;
		
		If FilesThatWerePut.Count() = 1 Then
			FileInfo.TempFileStorageAddress = FilesThatWerePut[0].Location;
		EndIf;
	EndIf;
	
	CommonFilesOperationsSettings = CommonFilesOperationsSettings();
	DirectoryName = UserWorkingDirectory();
	
	RelativeFilePath = "";
	If ExecutionParameters.FileData.OwnerWorkingDirectory <> "" Then // Has working directory.
		RelativeFilePath = ExecutionParameters.FullFilePath;
	Else
		Position = StrFind(ExecutionParameters.FullFilePath, DirectoryName);
		If Position <> 0 Then
			RelativeFilePath = Mid(ExecutionParameters.FullFilePath, StrLen(DirectoryName) + 1);
		EndIf;
	EndIf;
	
	If Not CommonFilesOperationsSettings.ExtractTextFilesOnServer Then
		FileInfo.TempTextStorageAddress = ExtractTextToTempStorage(ExecutionParameters.FullFilePath,
			ExecutionParameters.FormID);
	Else
		FileInfo.TempTextStorageAddress = "";
	EndIf;
	
	DontChangeRecordInWorkingDirectory = False;
	If ExecutionParameters.PassedFullPathToFile <> "" Then
		DontChangeRecordInWorkingDirectory = True;
	EndIf;
	
	VersionUpdated = FilesOperationsInternalServerCall.SaveFileChanges(ExecutionParameters.FileData.Ref, FileInfo, 
		DontChangeRecordInWorkingDirectory, RelativeFilePath, ExecutionParameters.FullFilePath, 
		ExecutionParameters.FileData.OwnerWorkingDirectory <> "", ExecutionParameters.FormID);
	If ExecutionParameters.ShowNotification Then
		If VersionUpdated Then
			ShowUserNotification(
				NStr("ru = 'Новая версия сохранена'; en = 'New version saved'; pl = 'Nowa wersja zapisana';de = 'Neue Version wird gespeichert';ro = 'Noua versiune este salvată';tr = 'Yeni sürüm kaydedildi'; es_ES = 'Nueva versión guardada'"),
				ExecutionParameters.FileData.URL,
				ExecutionParameters.FileData.FullVersionDescription,
				PictureLib.Information32);
		Else
			ShowUserNotification(
				NStr("ru = 'Новая версия не сохранена'; en = 'New version not saved'; pl = 'Nowa wersja nie jest zapisana';de = 'Neue Version wird nicht gespeichert';ro = 'Noua versiune nu este salvată';tr = 'Yeni sürüm kaydedilmedi'; es_ES = 'Nueva versión no guardada'"),,
				NStr("ru = 'Файл не изменился'; en = 'The file is not changed.'; pl = 'Plik nie został zmieniony';de = 'Die Datei wurde nicht geändert';ro = 'Fișierul nu este modificat';tr = 'Dosya değişmedi'; es_ES = 'Archivo no se ha cambiado'"),
				PictureLib.Information32);
			Handler = New NotifyDescription("SaveFileChangesWithExtensionAfterShowNotification", ThisObject, ExecutionParameters);
			ShowInformationFileWasNotModified(Handler);
			Return;
		EndIf;
	EndIf;
	
	SaveFileChangesWithExtensionAfterShowNotification(-1, ExecutionParameters);
	
EndProcedure

// Continuation of the procedure (see above).
Procedure SaveFileChangesWithExtensionAfterShowNotification(Result, ExecutionParameters) Export
	
	If  TypeOf(Result) = Type("Structure") AND Result.Property("DoNotAskAgain") AND Result.DoNotAskAgain Then
		CommonServerCall.CommonSettingsStorageSave(
			"ApplicationSettings","ShowFileNotModifiedFlag", False,,, True);
		RefreshReusableValues();
	EndIf;
	
	ReturnResult(ExecutionParameters.ResultHandler, True);
	
EndProcedure

// Continuation of the procedure (see above).
Procedure SaveFileChangesWithoutExtension(ExecutionParameters)
	
	If ExecutionParameters.StoreVersions = Undefined Then
		ExecutionParameters.FileData = FilesOperationsInternalServerCall.FileData(ExecutionParameters.ObjectRef);
		ExecutionParameters.StoreVersions                      = ExecutionParameters.FileData.StoreVersions;
		ExecutionParameters.CurrentUserEditsFile = ExecutionParameters.FileData.CurrentUserEditsFile;
		ExecutionParameters.BeingEditedBy                        = ExecutionParameters.FileData.BeingEditedBy;
		ExecutionParameters.CurrentVersionAuthor                 = ExecutionParameters.FileData.CurrentVersionAuthor;
	EndIf;
	
	// Checking the ability to unlock the file.
	ErrorText = "";
	CanUnlockFile = AbilityToUnlockFile(
		ExecutionParameters.ObjectRef,
		ExecutionParameters.CurrentUserEditsFile,
		ExecutionParameters.BeingEditedBy,
		ErrorText);
	If Not CanUnlockFile Then
		ReturnResultAfterShowWarning(ExecutionParameters.ResultHandler, ErrorText, False);
		Return;
	EndIf;
	
	ExecutionParameters.FullFilePath = "";
	If ExecutionParameters.CreateNewVersion = Undefined Then
		
		// Requesting a comment and version storage flag.
		ExecutionParameters.CreateNewVersion = True;
		CreateNewVersionAvailability = True;
		
		If ExecutionParameters.StoreVersions Then
			ExecutionParameters.CreateNewVersion = True;
			
			// If the author of the current version is not the current user, the "Do not create a new version" 
			// is disabled.
			If ExecutionParameters.CurrentVersionAuthor <> ExecutionParameters.BeingEditedBy Then
				CreateNewVersionAvailability = False;
			Else
				CreateNewVersionAvailability = True;
			EndIf;
		Else
			ExecutionParameters.CreateNewVersion = False;
			CreateNewVersionAvailability = False;
		EndIf;
		
		ParametersStructure = New Structure;
		ParametersStructure.Insert("FileRef",                    ExecutionParameters.ObjectRef);
		ParametersStructure.Insert("VersionComment",            "");
		ParametersStructure.Insert("CreateNewVersion",            ExecutionParameters.CreateNewVersion);
		ParametersStructure.Insert("CreateNewVersionAvailability", CreateNewVersionAvailability);
		
		Handler = New NotifyDescription("SaveFileChangesWithoutExtensionAfterPutFileOnServer", ThisObject, ExecutionParameters);
		
		OpenForm("DataProcessor.FilesOperations.Form.SaveFileToInfobaseForm", ParametersStructure, , , , , Handler);
		
	Else // The CreateNewVersion and VersionComment parameters are external.
		
		If ExecutionParameters.StoreVersions Then
			
			// If the author of the current version is not the current user, the "Do not create a new version" 
			// is disabled.
			If ExecutionParameters.CurrentVersionAuthor <> ExecutionParameters.BeingEditedBy Then
				ExecutionParameters.CreateNewVersion = True;
			EndIf;
			
		Else
			ExecutionParameters.CreateNewVersion = False;
		EndIf;
		
		SaveFileChangesWithoutExtensionAfterCheckNewVersion(ExecutionParameters);
		
	EndIf;
	
EndProcedure

// Continuation of the procedure (see above).
Procedure SaveFileChangesWithoutExtensionAfterPutFileOnServer(Result, ExecutionParameters) Export
	
	If TypeOf(Result) <> Type("Structure") Then
		ReturnResult(ExecutionParameters.ResultHandler, False);
		Return;
	EndIf;
	
	If Result.ReturnCode <> DialogReturnCode.OK Then
		ReturnResult(ExecutionParameters.ResultHandler, False);
		Return;
	EndIf;
	
	ExecutionParameters.CreateNewVersion = Result.CreateNewVersion;
	ExecutionParameters.VersionComment = Result.VersionComment;
	
	SaveFileChangesWithoutExtensionAfterCheckNewVersion(ExecutionParameters);
	
EndProcedure

// Continuation of the procedure (see above).
Procedure SaveFileChangesWithoutExtensionAfterCheckNewVersion(ExecutionParameters)
	
	Handler = New NotifyDescription("SaveFileChangesWithoutExtensionAfterReminder", ThisObject, ExecutionParameters);
	ShowReminderBeforePutFile(Handler);
	
EndProcedure

// Continuation of the procedure (see above).
Procedure SaveFileChangesWithoutExtensionAfterReminder(Result, ExecutionParameters) Export
	
	If Result.Value = DialogReturnCode.OK Then
		
		If  TypeOf(Result) = Type("Structure") AND Result.Property("DoNotAskAgain") AND Result.DoNotAskAgain Then
			CommonServerCall.CommonSettingsStorageSave(
				"ApplicationSettings", "ShowTooltipsOnEditFiles", False,,, True);
		EndIf;
		Handler = New NotifyDescription("SaveFileChangesWithoutExtensionAfterImportFile", ThisObject, ExecutionParameters);
		BeginPutFile(Handler, , ExecutionParameters.FullFilePath, , ExecutionParameters.FormID);
		
	EndIf;
	
EndProcedure

// Continuation of the procedure (see above).
Procedure SaveFileChangesWithoutExtensionAfterImportFile(Put, Address, SelectedFileName, ExecutionParameters) Export
	
	If Not Put Then
		ReturnResult(ExecutionParameters.ResultHandler, False);
		Return;
	EndIf;
	
	ExecutionParameters.Insert("ImportedFileAddress", Address);
	ExecutionParameters.Insert("SelectedFileName", SelectedFileName);
	
	If ExecutionParameters.FileData = Undefined Then
		FileData = FilesOperationsInternalServerCall.FileData(ExecutionParameters.ObjectRef);
	Else
		FileData = ExecutionParameters.FileData;
	EndIf;
	If Not FileData.Encrypted Then
		SaveFileChangesWithoutExtensionAfterEncryptFile(Null, ExecutionParameters);
		Return;
	EndIf;
	If CertificatesNotSpecified(FileData.EncryptionCertificatesArray) Then
		ReturnResult(ExecutionParameters.ResultHandler, False);
		Return;
	EndIf;
	
	If Not CommonClient.SubsystemExists("StandardSubsystems.DigitalSignature") Then
		ReturnResult(ExecutionParameters.ResultHandler, False);
		Return;
	EndIf;
	
	// SuggestFileSystemExtensionInstallationNow() is not required, because everything is done in the memory via BinaryData
	
	DataDetails = New Structure;
	DataDetails.Insert("Operation",            NStr("ru = 'Шифрование файла'; en = 'Encrypt file'; pl = 'Szyfrowanie plików';de = 'Dateiverschlüsselung';ro = 'Criptarea fișierului';tr = 'Dosya şifreleme'; es_ES = 'Codificación del archivo'"));
	DataDetails.Insert("DataTitle",     NStr("ru = 'Файл'; en = 'File'; pl = 'Plik';de = 'Datei';ro = 'Fișier';tr = 'Dosya'; es_ES = 'Archivo'"));
	DataDetails.Insert("Data",              Address);
	DataDetails.Insert("Presentation",       ExecutionParameters.ObjectRef);
	DataDetails.Insert("CertificatesSet",   ExecutionParameters.ObjectRef);
	DataDetails.Insert("NoConfirmation",    True);
	DataDetails.Insert("NotifyOnCompletion", False);
	
	FollowUpHandler = New NotifyDescription("SaveFileChangesWithoutExtensionAfterEncryptFile",
		ThisObject, ExecutionParameters);
	
	ModuleDigitalSignatureClient = CommonClient.CommonModule("DigitalSignatureClient");
	ModuleDigitalSignatureClient.Encrypt(DataDetails, , FollowUpHandler);
	
EndProcedure

// Continuation of the procedure (see above).
Procedure SaveFileChangesWithoutExtensionAfterEncryptFile(DataDetails, ExecutionParameters) Export
	
	If DataDetails = Null Then
		Address = ExecutionParameters.ImportedFileAddress;
		
	ElsIf Not DataDetails.Success Then
		ReturnResult(ExecutionParameters.ResultHandler, False);
		Return;
	Else
		If TypeOf(DataDetails.EncryptedData) = Type("BinaryData") Then
			Address = PutToTempStorage(DataDetails.EncryptedData,
				ExecutionParameters.FormID);
		Else
			Address = DataDetails.EncryptedData;
		EndIf;
	EndIf;
	
	FileInfo = FilesOperationsClientServer.FileInfo("FileWithVersion");
	ExecutionParameters.TempStorageAddress = Address;
	FileInfo.TempFileStorageAddress = Address;
	FileInfo.StoreVersions = ExecutionParameters.CreateNewVersion;
	
	PathStructure = CommonClientServer.ParseFullFileName(ExecutionParameters.SelectedFileName);
	If Not IsBlankString(PathStructure.Extension) Then
		FileInfo.ExtensionWithoutPoint = CommonClientServer.ExtensionWithoutPoint(PathStructure.Extension);
		FileInfo.BaseName = PathStructure.BaseName;
	EndIf;
	
	Result = FilesOperationsInternalServerCall.GetFileDataAndSaveFileChanges(ExecutionParameters.ObjectRef, FileInfo, 
		"", ExecutionParameters.FullFilePath, False, ExecutionParameters.FormID);
	ExecutionParameters.FileData = Result.FileData;
	If ExecutionParameters.ShowNotification Then
		ShowUserNotification(
			NStr("ru = 'Новая версия сохранена'; en = 'The new version is saved.'; pl = 'Nowa wersja zapisana';de = 'Neue Version wird gespeichert';ro = 'Noua versiune este salvată';tr = 'Yeni sürüm kaydedildi'; es_ES = 'Nueva versión guardada'"),
			ExecutionParameters.FileData.URL,
			ExecutionParameters.FileData.FullVersionDescription,
			PictureLib.Information32);
	EndIf;
	
	ReturnResult(ExecutionParameters.ResultHandler, True);
	
EndProcedure


// For the SaveFileChanges and EndEdit procedure.
Procedure EncryptFileBeforePutFileInFileStorage(ExecutionParameters)
	
	If CertificatesNotSpecified(ExecutionParameters.FileData.EncryptionCertificatesArray) Then
		ReturnResult(ExecutionParameters.ResultHandler, False);
		Return;
	EndIf;
	
	If Not CommonClient.SubsystemExists("StandardSubsystems.DigitalSignature") Then
		ReturnResult(ExecutionParameters.ResultHandler, False);
		Return;
	EndIf;
	
	// SuggestFileSystemExtensionInstallationNow() is not required, because everything is done in the memory via BinaryData
	
	DataDetails = New Structure;
	DataDetails.Insert("Operation",            NStr("ru = 'Шифрование файла'; en = 'Encrypt file'; pl = 'Szyfrowanie plików';de = 'Dateiverschlüsselung';ro = 'Criptarea fișierului';tr = 'Dosya şifreleme'; es_ES = 'Codificación del archivo'"));
	DataDetails.Insert("DataTitle",     NStr("ru = 'Файл'; en = 'File'; pl = 'Plik';de = 'Datei';ro = 'Fișier';tr = 'Dosya'; es_ES = 'Archivo'"));
	DataDetails.Insert("Data",              ExecutionParameters.FullFilePath);
	DataDetails.Insert("Presentation",       ExecutionParameters.ObjectRef);
	DataDetails.Insert("CertificatesSet",   ExecutionParameters.ObjectRef);
	DataDetails.Insert("NoConfirmation",    True);
	DataDetails.Insert("NotifyOnCompletion", False);
	
	FollowUpHandler = New NotifyDescription("EncryptFileBeforePutFileInFileStorageAfterFileEncryption",
		ThisObject, ExecutionParameters);
	
	ModuleDigitalSignatureClient = CommonClient.CommonModule("DigitalSignatureClient");
	ModuleDigitalSignatureClient.Encrypt(DataDetails, , FollowUpHandler);
	
EndProcedure

// Continuation of the procedure (see above).
Procedure EncryptFileBeforePutFileInFileStorageAfterFileEncryption(DataDetails, ExecutionParameters) Export
	
	If DataDetails = Null Then
		Address = ExecutionParameters.ImportedFileAddress;
		
	ElsIf Not DataDetails.Success Then
		ReturnResult(ExecutionParameters.ResultHandler, False);
		Return;
	Else
		If TypeOf(DataDetails.EncryptedData) = Type("BinaryData") Then
			Address = PutToTempStorage(DataDetails.EncryptedData,
				ExecutionParameters.FormID);
		Else
			Address = DataDetails.EncryptedData;
		EndIf;
	EndIf;
	
	ExecutionParameters.Insert("AddressAfterEncryption", Address);
	
	ExecuteNotifyProcessing(ExecutionParameters.NotificationAfterEncryption);
	
EndProcedure

// For the SaveFileChanges and EndEdit procedure.
Function CertificatesNotSpecified(CertificatesArray)
	
	If CertificatesArray.Count() = 0 Then
		ShowMessageBox(,
			NStr("ru = 'У зашифрованного файла не указаны сертификаты.
			           |Расшифруйте файл и зашифруйте заново.'; 
			           |en = 'Certificates of the encrypted file are not specified.
			           |Please decrypt the file and then encrypt it again.'; 
			           |pl = 'Zaszyfrowany plik nie ma określonych certyfikatów.
			           |Odszyfruj plik i ponownie zaszyfruj.';
			           |de = 'Die verschlüsselte Datei enthält keine angegebenen Zertifikate. 
			           |Entschlüsseln Sie die Datei und verschlüsseln Sie sie erneut.';
			           |ro = 'Fișierul criptat nu are certificate specificate.
			           |Decripați fișierul și criptați din nou.';
			           |tr = 'Şifrelenmiş dosya belirtilen sertifikalara sahip değil. 
			           |Dosyayı çöz ve tekrar şifrele.'; 
			           |es_ES = 'Archivo codificado no tiene los certificados especificados.
			           |Descodificar el archivo y codificarlo de nuevo.'"));
		
		Return True;
	EndIf;
	
	Return False;
	
EndFunction

////////////////////////////////////////////////////////////////////////////////
// Marking file locked for editing.

// Marking file locked for editing.
//
// Parameters:
//   ResultHandler - NotifyDescription, Undefined - description of the procedure that gets the method result.
//   FileData - a structure with file data.
//
// Returns:
//   * Undefined - if the file is not locked.
//   * Structure with file data - if the file is locked.
//
Procedure LockFile(ResultHandler, FileData, UUID)
	
	HandlerParameters = New Structure;
	HandlerParameters.Insert("ResultHandler",    ResultHandler);
	HandlerParameters.Insert("FileData",             FileData);
	HandlerParameters.Insert("UUID", UUID);
	
	Handler = New NotifyDescription("LockFileAfterInstallExtension", ThisObject, HandlerParameters);
	
	ShowFileSystemExtensionInstallationQuestion(Handler);
	
EndProcedure

// Continuation of the procedure (see above).
Procedure LockFileAfterInstallExtension(ExtensionInstalled, ExecutionParameters) Export
	
	ErrorText = "";
	CanLockFile = FilesOperationsClientServer.WhetherPossibleLockFile(
		ExecutionParameters.FileData,
		ErrorText);
	If Not CanLockFile Then
		ReturnResultAfterShowWarning(ExecutionParameters.ResultHandler, ErrorText, Undefined);
		Return;
	EndIf;
	
	ErrorText = "";
	FileLocked = FilesOperationsInternalServerCall.LockFile(ExecutionParameters.FileData,
		ErrorText, ExecutionParameters.UUID);
	
	If Not FileLocked Then
		ReturnResultAfterShowWarning(ExecutionParameters.ResultHandler, ErrorText, Undefined);
		Return;
	EndIf;
	
	If FileSystemExtensionAttached() Then
		ForReading = False;
		InOwnerWorkingDirectory = ExecutionParameters.FileData.OwnerWorkingDirectory <> "";
		ReregisterFileInWorkingDirectory(ExecutionParameters.FileData, ForReading, InOwnerWorkingDirectory);
	EndIf;
	
	ShowUserNotification(
		NStr("ru = 'Редактирование файла'; en = 'Edit files'; pl = 'Edycja pliku';de = 'Datei bearbeiten';ro = 'Editarea fișierului';tr = 'Dosya düzenle'; es_ES = 'Editar el archivo'"),
		ExecutionParameters.FileData.URL,
		StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Файл ""%1""
			           |занят для редактирования.'; 
			           |en = 'File ""%1""
			           |is locked for editing.'; 
			           |pl = 'Plik ""%1""
			           |zajęty do edycji.';
			           |de = 'Datei ""%1""
			           |ist für die Bearbeitung belegt.';
			           |ro = 'Fișierul ""%1""
			           |este blocat pentru editare.';
			           |tr = 'Dosya ""%1"" 
			           | düzenlenmek üzere meşgul edildi.'; 
			           |es_ES = 'Archivo ""%1""
			           | ocupado para editar.'"),
			String(ExecutionParameters.FileData.Ref)),
		PictureLib.Information32);
	
	ReturnResult(ExecutionParameters.ResultHandler, ExecutionParameters.FileData);
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Adding files.

// Continues AttachedFilesClient procedure execution.AddFiles.
Procedure AddFilesCompletion(AttachedFile, AdditionalParameters) Export
	
	If AttachedFile = Undefined Then
		Return;
	EndIf;
	
	FileOwner = AdditionalParameters.FileOwner;
	NotifyChanged(AttachedFile);
	NotifyChanged(FileOwner);
	
	NotificationParameters = New Structure;
	NotificationParameters.Insert("FileOwner", FileOwner);
	NotificationParameters.Insert("File"         , AttachedFile);
	NotificationParameters.Insert("IsNew"     , True);
	Notify("Write_File", NotificationParameters, AttachedFile);
	
	If AdditionalParameters.Property("ResultHandler")
		AND AdditionalParameters.ResultHandler <> Undefined Then
		AttachedFilesArray = New Array;
		AttachedFilesArray.Add(AttachedFile);
		ExecuteNotifyProcessing(AdditionalParameters.ResultHandler, AttachedFilesArray);
	EndIf;
	
	OpenCardAfterCreateFromFile = False;
	If AdditionalParameters.Property("DontOpenCardAfterCreateFromFIle") Then
		OpenCardAfterCreateFromFile = Not AdditionalParameters.DontOpenCardAfterCreateFromFIle;
	EndIf;
	If OpenCardAfterCreateFromFile Then
		
		ShowUserNotification(
			NStr("ru = 'Создание'; en = 'Create'; pl = 'Tworzenie';de = 'Erstellung';ro = 'Creare';tr = 'Oluştur'; es_ES = 'Crear'"),
			GetURL(AttachedFile),
			AttachedFile,
			PictureLib.Information32);
		FilesOperationsClient.OpenFileForm(AttachedFile);
			
	EndIf;
		
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Unlocking files without updating them.

////////////////////////////////////////////////////////////////////////////////
// Deleting file. The attribute Read only is removed before deleting the file.

// Delete the file, removing the readonly attribute without dialog boxes.
//
// Parameters:
//  FullFileName - String -  a full file name.
//
Procedure DeleteFileWithoutConfirmation(FullFileName)
	
	File = New File(FullFileName);
	If File.Exist() Then
		File.SetReadOnly(False);
		DeleteFiles(FullFileName);
	EndIf;
	
EndProcedure

// Delete the file, removing the readonly attribute.
//
// Parameters:
//  ResultHandler - NotifyDescription, Structure, Undefined - description of the procedure that gets 
//                         the method result.
//  FullFileName - String -  a full file name.
//  AskQuestion - Boolean - ask question about deletion.
//  QuestionHeader - String - Question header - adds text to the question about deletion.
//
Procedure DeleteFile(ResultHandler, FullFileName, AskQuestion = Undefined, QuestionHeader = Undefined)
	
	If AskQuestion = Undefined Then
		PersonalSettings = PersonalFilesOperationsSettings();
		AskQuestion = PersonalSettings.ConfirmOnDeleteFilesFromLocalCache;
	EndIf;
	
	ExecutionParameters = New Structure;
	ExecutionParameters.Insert("ResultHandler", ResultHandler);
	ExecutionParameters.Insert("FullFileName", FullFileName);
	
	If AskQuestion = True Then
		QuestionText =
			NStr("ru = 'Удалить файл ""%1""
			           |из рабочего каталога?'; 
			           |en = 'Do you want to delete file ""%1""
			           |from the working directory?'; 
			           |pl = 'Usunąć plik ""%1""
			           | z roboczego katalogu?';
			           |de = 'Die Datei ""%1""
			           |aus dem Arbeitsverzeichnis löschen?';
			           |ro = 'Ștergeți fișierul ""%1""
			           |din director?';
			           |tr = 'Dosya ""%1"" 
			           | çalışma dizninden silinsin mi?'; 
			           |es_ES = '¿Eliminar el archivo ""%1""
			           |del catálogo de trabajo?'");
		QuestionText = StrReplace(QuestionText, "%1", FullFileName);
		If QuestionHeader <> Undefined Then
			QuestionText = QuestionHeader + Chars.LF + Chars.LF + QuestionText;
		EndIf;
		ExecutionParameters.ResultHandler = PrepareHandlerForDialog(ExecutionParameters.ResultHandler);
		Handler = New NotifyDescription("DeleteFileAfterRespondQuestion", ThisObject, ExecutionParameters);
		ShowQueryBox(Handler, QuestionText, QuestionDialogMode.YesNo);
		Return;
	EndIf;
	
	DeleteFileAfterRespondQuestion(-1, ExecutionParameters);
	
EndProcedure

// Continuation of the procedure (see above).
Procedure DeleteFileAfterRespondQuestion(Response, ExecutionParameters) Export
	
	If Response <> -1 Then
		If Response = DialogReturnCode.No Then
			ReturnResult(ExecutionParameters.ResultHandler, False);
			Return;
		EndIf;
	EndIf;
	
	DeleteFileWithoutConfirmation(ExecutionParameters.FullFileName);
	
	ReturnResult(ExecutionParameters.ResultHandler, True);
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Receiving a file from the storage to working directory.

// Receives File from the storage to working directory and returns a path to this file.
// 
//
// Parameters:
//  ResultHandler - NotifyDescription, Undefined - description of the procedure that gets the method result.
//  FileData        - a structure with file data.
//  FullFileName     - String.
//  ForRead           - Boolean - False for reading, True for editing.
//  FormID - a form UUID.
//
// Returns:
//   Structure - result.
//       * FileReceived - Boolean - shows whether the operation is performed successfully.
//       * FullFileName - String - a full file name.
//
Procedure GetVersionFileToLocalFilesCache(
	ResultHandler,
	FileData,
	ForReading,
	FormID,
	AdditionalParameters)
	
	ExecutionParameters = New Structure;
	ExecutionParameters.Insert("ResultHandler", ResultHandler);
	ExecutionParameters.Insert("FileData", FileData);
	ExecutionParameters.Insert("ForReading", ForReading);
	ExecutionParameters.Insert("FormID", FormID);
	ExecutionParameters.Insert("AdditionalParameters", AdditionalParameters);
	
	GetVersionFileToLocalFilesCacheStart(ExecutionParameters);
	
EndProcedure

// Continuation of the procedure (see above).
Procedure GetVersionFileToLocalFilesCacheStart(ExecutionParameters)
	
	ExecutionParameters.Insert("FullFileName", "");
	ExecutionParameters.Insert("FileReceived", False);
	
	InWorkingDirectoryForRead = True;
	InOwnerWorkingDirectory = False;
	
	FileInWorkingDirectory = FileInLocalFilesCache(
		ExecutionParameters.FileData,
		ExecutionParameters.FileData.Version,
		ExecutionParameters.FullFileName,
		InWorkingDirectoryForRead,
		InOwnerWorkingDirectory);
	
	If FileInWorkingDirectory = False Then
		GetFromServerAndRegisterInLocalFilesCache(
			ExecutionParameters.ResultHandler,
			ExecutionParameters.FileData,
			ExecutionParameters.FullFileName,
			ExecutionParameters.FileData.UniversalModificationDate,
			ExecutionParameters.ForReading,
			ExecutionParameters.FormID,
			ExecutionParameters.AdditionalParameters);
		Return;
	EndIf;

	// Receiving a file path in the working directory and checking it for uniqueness.
	If ExecutionParameters.FullFileName = "" Then
		CommonClient.MessageToUser(
			NStr("ru = 'Не удалось получить файл из программы в рабочий каталог на компьютере.'; en = 'Cannot get the file from the application to the working directory.'; pl = 'Nie udało się pobrać pliku z programu do katalogu roboczego na komputerze.';de = 'Es war nicht möglich, die Datei aus dem Programm in das Arbeitsverzeichnis auf dem Computer zu erhalten.';ro = 'Eșec la obținerea fișierului din program în directorul pe computer.';tr = 'Uygulamadaki dosya bilgisayardaki çalışma diznine alınamadı.'; es_ES = 'No se ha podido recibir el archivo del programa al catálogo de trabajo en el ordenador.'"));
		ReturnResult(ExecutionParameters.ResultHandler, ExecutionParameters);
		Return;
	EndIf;
	
	// The file is found in the working directory.
	// Checking the modification date and deciding what to do next.
	Handler = New NotifyDescription("GetVersionFileToLocalFilesCacheAfterActionChoice", ThisObject, ExecutionParameters);
	
	ActionOnOpenFileInWorkingDirectory(
		Handler,
		ExecutionParameters.FullFileName,
		ExecutionParameters.FileData);
	
EndProcedure

// Continuation of the procedure (see above).
Procedure GetVersionFileToLocalFilesCacheAfterActionChoice(Result, ExecutionParameters) Export
	
	If Result = "GetFromStorageAndOpen" Then
		
		Handler = New NotifyDescription("GetVersionFileToLocalFilesCacheAfterDelete", ThisObject, ExecutionParameters);
		DeleteFile(Handler, ExecutionParameters.FullFileName);
		
	ElsIf Result = "OpenExistingFile" Then
		
		If ExecutionParameters.FileData.InWorkingDirectoryForRead <> ExecutionParameters.ForReading Then
			InOwnerWorkingDirectory = ExecutionParameters.FileData.OwnerWorkingDirectory <> "";
			
			RegegisterInWorkingDirectory(
				ExecutionParameters.FileData.Version,
				ExecutionParameters.FullFileName,
				ExecutionParameters.ForReading,
				InOwnerWorkingDirectory);
		EndIf;
		
		ExecutionParameters.FileReceived = True;
		ReturnResult(ExecutionParameters.ResultHandler, ExecutionParameters);
		
	Else // Result = "Cancel".
		ExecutionParameters.FullFileName = "";
		ReturnResult(ExecutionParameters.ResultHandler, ExecutionParameters);
	EndIf;
	
EndProcedure

// Continuation of the procedure (see above).
Procedure GetVersionFileToLocalFilesCacheAfterDelete(FileDeleted, ExecutionParameters) Export
	
	GetFromServerAndRegisterInLocalFilesCache(
		ExecutionParameters.ResultHandler,
		ExecutionParameters.FileData,
		ExecutionParameters.FullFileName,
		ExecutionParameters.FileData.UniversalModificationDate,
		ExecutionParameters.ForReading,
		ExecutionParameters.FormID,
		ExecutionParameters.AdditionalParameters);
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Receiving a file from the application to hard drive.

// Receives the file from the infobase to the local hard drive and returns the path to this file in 
// the parameter.
//
// Parameters:
//  ResultHandler - NotifyDescription, Undefined - description of the procedure that gets the method result.
//  FileData  - a structure with file data.
//  FullFileName - String - here a full name of the file is returned.
//  FormID - a form UUID.
//
// Returns:
//   Structure - the result of receiving a file.
//       * FileReceived - Boolean - shows whether the operation is performed successfully.
//       * FullFileName - String - a full file name.
//
Procedure GetVersionFileToWorkingDirectory(
		ResultHandler,
		FileData,
		FullFileName,
		FormID = Undefined,
		AdditionalParameters = Undefined) Export
	
	DirectoryName = UserWorkingDirectory();
	
	If DirectoryName = Undefined Or IsBlankString(DirectoryName) Then
		ReturnResult(ResultHandler, New Structure("FileReceived, FullFileName", False, FullFileName));
		Return;
	EndIf;
	
	If FileData.OwnerWorkingDirectory = "" 
		Or FileData.Version <> FileData.CurrentVersion AND ValueIsFilled(FileData.CurrentVersion) Then
		GetVersionFileToLocalFilesCache(
			ResultHandler,
			FileData,
			FileData.ForReading,
			FormID,
			AdditionalParameters);
	Else
		GetVersionFileToFolderWorkingDirectory(
			ResultHandler,
			FileData,
			FullFileName,
			FileData.ForReading,
			FormID,
			AdditionalParameters);
	EndIf;
	
EndProcedure

// See the procedure of the same name in FilesOperationsClient common module.
Procedure GetAttachedFile(Notification, AttachedFile, FormID, AdditionalParameters = Undefined) Export
	
	If AdditionalParameters = Undefined Then
		AdditionalParameters = New Structure;
	EndIf;
	
	Context = New Structure;
	Context.Insert("Notification",         Notification);
	Context.Insert("AttachedFile", AttachedFile);
	Context.Insert("FormID", FormID);
	Context.Insert("ForEditing",  False);
	Context.Insert("FileData",        Undefined);
	FillPropertyValues(AdditionalParameters, Context);
	
	If TypeOf(Context.FileData) <> Type("Structure")
	 Or Not ValueIsFilled(Context.FileData.BinaryFileDataRef) Then
		
		Context.Insert("FileData", FilesOperationsInternalServerCall.GetFileData(
			Context.AttachedFile, Context.FormID, True, Context.ForEditing));
	EndIf;
	
	Context.Insert("ErrorTitle",
		NStr("ru = 'Не удалось получить файл на компьютер из программы по причине:'; en = 'Cannot get the file from the application. Reason:'; pl = 'Nie udało się pobrać pliku na komputer z programu z powodu:';de = 'Es war nicht möglich, die Datei aus dem Programm auf den Computer zu erhalten, aus folgendem Grund:';ro = 'Eșec la obținerea fișierului pe computer din program din motivul:';tr = 'Dosya, aşağıdakiler nedeniyle dosya bilgisayara alınamıyor:'; es_ES = 'No se ha podido recibir el archivo del programa al ordenador a causa de:'") + Chars.LF);
	
	If Context.ForEditing
	   AND Context.FileData.BeingEditedBy <> UsersClient.AuthorizedUser() Then
		
		Result = New Structure;
		Result.Insert("FullFileName", "");
		Result.Insert("ErrorDescription", Context.ErrorTitle + StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Файл уже редактирует пользователь %1.'; en = 'The file is locked by %1.'; pl = 'Plik jest już edytowany przez użytkownika %1.';de = 'Die Datei wird bereits vom Benutzer bearbeitet %1.';ro = 'Fișierul este deja editat de utilizator %1.';tr = 'Dosya zaten  %1 kullanıcı tarafından düzenleniyor.'; es_ES = 'El archivo ya se está editando por el usuario %1.'"), String(Context.FileData.BeingEditedBy)));
		ExecuteNotifyProcessing(Context.Notification, Result);
		Return;
	EndIf;
	
	Context.Insert("ForEditing", ValueIsFilled(Context.FileData.BeingEditedBy));
	
	FileSystemClient.AttachFileOperationsExtension(New NotifyDescription(
		"GetAttachedFileAfterAttachExtension", ThisObject, Context));
	
EndProcedure

// Continue the GetAttachedFile procedure.
Procedure GetAttachedFileAfterAttachExtension(ExtensionAttached, Context) Export
	
	If Not ExtensionAttached Then
		Result = New Structure;
		Result.Insert("FullFileName", "");
		Result.Insert("ErrorDescription", Context.ErrorTitle
			+ NStr("ru = 'В браузере не установлено расширение для работы с файлами.'; en = 'The file system extension is not installed in the browser.'; pl = 'W przeglądarce nie jest zainstalowane rozszerzenie do pracy z plikami.';de = 'Im Browser ist keine Dateiendung installiert.';ro = 'Extensia pentru lucrul cu fișierele nu este instalată în browser.';tr = 'Web tarayıcısı için dosya işlem uzantısı yüklenmedi.'; es_ES = 'En el navegador web está instalada la extensión para trabajar con los archivos.'"));
		ExecuteNotifyProcessing(Context.Notification, Result);
		Return;
	EndIf;
	
	GetUserWorkingDirectory(New NotifyDescription(
		"GetAttachedFileAfterGetWorkingDirectory", ThisObject, Context));
	
EndProcedure

// Continue the GetAttachedFile procedure.
Procedure GetAttachedFileAfterGetWorkingDirectory(Result, Context) Export
	
	If ValueIsFilled(Result.ErrorDescription) Then
		Result = New Structure;
		Result.Insert("FullFileName", "");
		Result.Insert("ErrorDescription", Context.ErrorTitle + Result.ErrorDescription);
		ExecuteNotifyProcessing(Context.Notification, Result);
		Return;
	EndIf;
	
	Context.Insert("UserWorkingDirectory", Result.Directory);
	Context.Insert("FileDirectory", Context.UserWorkingDirectory + Context.FileData.RelativePath);
	Context.Insert("FullFileName", Context.FileDirectory + Context.FileData.FileName);
	
	FileOperations = New Array;
	
	Action = New Structure;
	Action.Insert("Action", "CreateFolder");
	Action.Insert("File", Context.FileDirectory);
	Action.Insert("ErrorTitle", Context.ErrorTitle
		+ NStr("ru = 'Создание каталога не выполнено по причине:'; en = 'Cannot create the directory. Reason:'; pl = 'Katalog nie został utworzony z powodu:';de = 'Verzeichnis wird nicht erstellt aufgrund von:';ro = ' Catalogul nu este creat din cauza:';tr = 'Dizin aşağıdakilerden dolayı oluşturulmadı:'; es_ES = 'Directorio no está creado debido a:'"));
	FileOperations.Add(Action);
	
	Action = New Structure;
	Action.Insert("Action", "SetProperties");
	Action.Insert("File",  Context.FullFileName);
	Action.Insert("Properties", New Structure("ReadOnly", False));
	Action.Insert("ErrorTitle", Context.ErrorTitle
		+ NStr("ru = 'Изменение свойства файла ""Только просмотр"" не выполнено по причине:'; en = 'Cannot change the ""Read-only"" property. Reason:'; pl = 'Nie można zmienić właściwości ""Tylko podgląd"" pliku z powodu:';de = 'Die Eigenschaft ""Nur anzeigen"" der Datei kann nicht geändert werden als:';ro = 'Nu se poate schimba proprietatea ""Vizualizare numai"" a fișierului ca:';tr = 'Dosyanın ""Yalnızca görüntüle"" özelliğini değiştiremezsiniz:'; es_ES = 'No se puede cambiar la propiedad ""Solo ver"" del archivo como:'"));
	FileOperations.Add(Action);
	
	Action = New Structure;
	Action.Insert("Action", "Get");
	Action.Insert("File",  Context.FullFileName);
	Action.Insert("Address", Context.FileData.BinaryFileDataRef);
	Action.Insert("ErrorTitle", Context.ErrorTitle);
	FileOperations.Add(Action);
	
	FileProperties = New Structure;
	FileProperties.Insert("ReadOnly", Not Context.ForEditing);
	FileProperties.Insert("UniversalModificationTime", Context.FileData.UniversalModificationDate);
	
	Action = New Structure;
	Action.Insert("Action", "SetProperties");
	Action.Insert("File",  Context.FullFileName);
	Action.Insert("Properties", FileProperties);
	Action.Insert("ErrorTitle", Context.ErrorTitle
		+ NStr("ru = 'Установка свойств файла не выполнено по причине:'; en = 'Cannot set file properties. Reason:'; pl = 'Nie można ustawić właściwości pliku z powodu:';de = 'Dateieigenschaften können nicht festgelegt werden aufgrund von:';ro = 'Nu se pot seta proprietățile fișierelor datorită:';tr = 'Aşağıdakilerden dolayı dosya özellikleri ayarlanamıyor:'; es_ES = 'No se puede establecer las propiedades del archivo debido a:'"));
	FileOperations.Add(Action);
	
	ProcessFile(New NotifyDescription(
			"GetAttachedFileAfterProcessFile", ThisObject, Context),
		FileOperations, Context.FormID);
	
EndProcedure

// Continue the GetAttachedFile procedure.
Procedure GetAttachedFileAfterProcessFile(ActionsResult, Context) Export
	
	Result = New Structure;
	
	If ValueIsFilled(ActionsResult.ErrorDescription) Then
		Result.Insert("FullFileName", "");
		Result.Insert("ErrorDescription", ActionsResult.ErrorDescription);
	Else
		Result.Insert("FullFileName", Context.FullFileName);
		Result.Insert("ErrorDescription", "");
	EndIf;
	
	ExecuteNotifyProcessing(Context.Notification, Result);
	
EndProcedure

// See the procedure with the same name in the AttachedFilesClient common module.
Procedure PutAttachedFile(Notification, AttachedFile, FormID, AdditionalParameters = Undefined) Export
	
	If AdditionalParameters = Undefined Then
		AdditionalParameters = New Structure;
	EndIf;
	
	Context = New Structure;
	Context.Insert("Notification",                Notification);
	Context.Insert("AttachedFile",        AttachedFile);
	Context.Insert("FormID",        FormID);
	Context.Insert("FileData",               Undefined);
	Context.Insert("FullNameOfFileToPut", Undefined);
	AdditionalParameters.Property("FileData",    Context.FileData);
	AdditionalParameters.Property("FullFileName", Context.FullNameOfFileToPut);
	
	If TypeOf(Context.FileData) <> Type("Structure") Then
		Context.Insert("FileData", FilesOperationsInternalServerCall.GetFileData(
			Context.AttachedFile, Context.FormID, False));
	EndIf;
	
	Context.Insert("ErrorTitle",
		NStr("ru = 'Не удалось поместить файл с компьютера в программу по причине:'; en = 'Cannot store the local file to the application. Reason:'; pl = 'Nie można umieścić pliku z komputera w aplikacji z powodu:';de = 'Die Datei kann nicht vom Computer in die Anwendung übertragen werden, da:';ro = 'Nu se poate pune fișierul de pe calculator în aplicație datorită:';tr = 'Bir dosya, aşağıdakilerden dolayı dosya depolama birimine yerleştirilemiyor:'; es_ES = 'No se ha podido colocar el archivo del ordenador en el programa a causa de:'") + Chars.LF);
	
	FileSystemClient.AttachFileOperationsExtension(New NotifyDescription(
		"PutAttachedFileAfterAttachExtension", ThisObject, Context));
	
EndProcedure

// Continues the PutAttachedFile procedure.
Procedure PutAttachedFileAfterAttachExtension(ExtensionAttached, Context) Export
	
	If Not ExtensionAttached Then
		Result = New Structure;
		Result.Insert("ErrorDescription", Context.ErrorTitle
			+ NStr("ru = 'В браузере не установлено расширение для работы с файлами.'; en = 'The file system extension is not installed in the browser.'; pl = 'W przeglądarce nie jest zainstalowane rozszerzenie do pracy z plikami.';de = 'Im Browser ist keine Dateiendung installiert.';ro = 'Extensia pentru lucrul cu fișierele nu este instalată în browser.';tr = 'Web tarayıcısı için dosya işlem uzantısı yüklenmedi.'; es_ES = 'En el navegador web está instalada la extensión para trabajar con los archivos.'"));
		ExecuteNotifyProcessing(Context.Notification, Result);
		Return;
	EndIf;
	
	GetUserWorkingDirectory(New NotifyDescription(
		"PutAttachedFileAfterGetWorkingDirectory", ThisObject, Context));
	
EndProcedure

// Continues the PutAttachedFile procedure.
Procedure PutAttachedFileAfterGetWorkingDirectory(Result, Context) Export
	
	If ValueIsFilled(Result.ErrorDescription) Then
		ErrorResult = New Structure;
		ErrorResult.Insert("ErrorDescription", Context.ErrorTitle + Result.ErrorDescription);
		ExecuteNotifyProcessing(Context.Notification, ErrorResult);
		Return;
	EndIf;
	
	Context.Insert("UserWorkingDirectory", Result.Directory);
	Context.Insert("FileDirectory",   Context.UserWorkingDirectory + Context.FileData.RelativePath);
	Context.Insert("FullFileName", Context.FileDirectory + Context.FileData.FileName);
	
	File = New File(Context.FullFileName);
	If NOT File.Exist() Then
		// for compatibility of the two subsystems.
		Context.Insert("FileDirectory",   Context.UserWorkingDirectory);
		Context.Insert("FullFileName", Context.FileData.FullFileNameInWorkingDirectory);
		
		If IsBlankString(Context.FileData.FullFileNameInWorkingDirectory) Then
			// the file is missing in the working directory, simply unlock it.
			UnlockFileWithoutQuestion(Context.FileData, Context.FormID);
			Return;
		EndIf;
	EndIf;
	
	If Not ValueIsFilled(Context.FullNameOfFileToPut) Then
		Context.FullNameOfFileToPut = Context.FullFileName;
	EndIf;
	
	FileDetails = New TransferableFileDescription(Context.FullFileName);
	FilesToPut = New Array;
	FilesToPut.Add(FileDetails);
	
	FileOperations = New Array;
	
	Calls = New Array;
	
	If Context.FullFileName <> Context.FullNameOfFileToPut Then
		Action = New Structure;
		Action.Insert("Action", "CreateFolder");
		Action.Insert("File", Context.FileDirectory);
		Action.Insert("ErrorTitle", Context.ErrorTitle
			+ NStr("ru = 'Создание каталога не выполнено по причине:'; en = 'Cannot create the directory. Reason:'; pl = 'Katalog nie został utworzony z powodu:';de = 'Verzeichnis wird nicht erstellt aufgrund von:';ro = ' Catalogul nu este creat din cauza:';tr = 'Dizin aşağıdakilerden dolayı oluşturulmadı:'; es_ES = 'Directorio no está creado debido a:'"));
		FileOperations.Add(Action);
		
		Action = New Structure;
		Action.Insert("Action", "SetProperties");
		Action.Insert("File",  Context.FullFileName);
		Action.Insert("Properties", New Structure("ReadOnly", False));
		Action.Insert("ErrorTitle", Context.ErrorTitle
			+ NStr("ru = 'Изменение свойства файла ""Только просмотр"" не выполнено по причине:'; en = 'Cannot change the ""Read-only"" property. Reason:'; pl = 'Nie można zmienić właściwości ""Tylko podgląd"" pliku z powodu:';de = 'Die Eigenschaft ""Nur anzeigen"" der Datei kann nicht geändert werden als:';ro = 'Nu se poate schimba proprietatea ""Vizualizare numai"" a fișierului ca:';tr = 'Dosyanın ""Yalnızca görüntüle"" özelliğini değiştiremezsiniz:'; es_ES = 'No se puede cambiar la propiedad ""Solo ver"" del archivo como:'"));
		FileOperations.Add(Action);
		
		Action = New Structure;
		Action.Insert("Action", "CopyFromSource");
		Action.Insert("File",     Context.FullFileName);
		Action.Insert("Source", Context.FullNameOfFileToPut);
		Action.Insert("ErrorTitle", Context.ErrorTitle
			+ NStr("ru = 'Копирование файла не выполнено по причине:'; en = 'Cannot copy the file. Reason:'; pl = 'Plik nie został skopiowany z powodu:';de = 'Die Datei wird nicht kopiert aufgrund von:';ro = 'Fișierul nu este copiat din cauza:';tr = 'Dosya aşağıdaki nedeniyle kopyalanmadı:'; es_ES = 'Archivo no se ha copiado debido a:'"));
		FileOperations.Add(Action);
		AddCall(Calls, "StartCopyFile", Context.FullNameOfFileToPut, Context.FullFileName, Undefined, Undefined);
	EndIf;
	
	Action = New Structure;
	Action.Insert("Action", "SetProperties");
	Action.Insert("File",  Context.FullFileName);
	Action.Insert("Properties", New Structure("ReadOnly", True));
	Action.Insert("ErrorTitle", Context.ErrorTitle
		+ NStr("ru = 'Изменение свойства файла ""Только просмотр"" не выполнено по причине:'; en = 'Cannot change the ""Read-only"" property. Reason:'; pl = 'Nie można zmienić właściwości ""Tylko podgląd"" pliku z powodu:';de = 'Die Eigenschaft ""Nur anzeigen"" der Datei kann nicht geändert werden als:';ro = 'Nu se poate schimba proprietatea ""Vizualizare numai"" a fișierului ca:';tr = 'Dosyanın ""Yalnızca görüntüle"" özelliğini değiştiremezsiniz:'; es_ES = 'No se puede cambiar la propiedad ""Solo ver"" del archivo como:'"));
	FileOperations.Add(Action);
	
	Context.Insert("FileProperties", New Structure);
	Context.FileProperties.Insert("UniversalModificationTime");
	Context.FileProperties.Insert("BaseName");
	Context.FileProperties.Insert("Extension");
	
	Action = New Structure;
	Action.Insert("Action", "GetProperties");
	Action.Insert("File",  Context.FullFileName);
	Action.Insert("Properties", Context.FileProperties);
	Action.Insert("ErrorTitle", Context.ErrorTitle
		+ NStr("ru = 'Получение свойств файла не выполнено по причине:'; en = 'Cannot get the file properties. Reason:'; pl = 'Właściwości pliku nie zostały otrzymane z powodu:';de = 'Dateieigenschaften wurden nicht empfangen aufgrund von:';ro = 'Proprietățile fișierelor nu au fost primite din cauza:';tr = 'Aşağıdakilerden dolayı dosya özellikleri alınmadı:'; es_ES = 'Propiedades del archivo no se han recibido debido a:'"));
	FileOperations.Add(Action);
	
	Context.Insert("PuttingAction", New Structure);
	Context.PuttingAction.Insert("Action", "Put");
	Context.PuttingAction.Insert("File",  Context.FullFileName);
	Context.PuttingAction.Insert("ErrorTitle", Context.ErrorTitle);
	FileOperations.Add(Context.PuttingAction);
	AddCall(Calls, "BeginPuttingFiles", FilesToPut, Undefined, False, Context.FormID);
	
	Context.Insert("FileOperations", FileOperations);
	
	BeginRequestingUserPermission(New NotifyDescription(
		"PutAttachedFileAfterGetPermissions", ThisObject, Context), Calls);
	
EndProcedure

Procedure AddCall(Calls, Method, P1, P2, P3, P4)
	
	Call = New Array;
	Call.Add(Method);
	Call.Add(P1);
	Call.Add(P2);
	Call.Add(P3);
	Call.Add(P4);
	
	Calls.Add(Call);
	
EndProcedure

// Continues the PutAttachedFile procedure.
Procedure PutAttachedFileAfterGetPermissions(PermissionsReceived, Context) Export
	
	If PermissionsReceived Then
		ProcessFile(New NotifyDescription(
				"PutAttachedFileAfterProcessFile", ThisObject, Context),
			Context.FileOperations, Context.FormID);
	EndIf;
		
EndProcedure

// Continues the PutAttachedFile procedure.
Procedure PutAttachedFileAfterProcessFile(ActionsResult, Context) Export
	
	Result = New Structure;
	
	If ValueIsFilled(ActionsResult.ErrorDescription) Then
		Result.Insert("ErrorDescription", ActionsResult.ErrorDescription);
		ExecuteNotifyProcessing(Context.Notification, Result);
		Return;
	EndIf;
	
	Result.Insert("ErrorDescription", "");
	
	Extension = Context.FileProperties.Extension;
	
	FileInfo = New Structure;
	FileInfo.Insert("UniversalModificationDate",   Context.FileProperties.UniversalModificationTime);
	FileInfo.Insert("FileAddressInTempStorage", Context.PuttingAction.Address);
	FileInfo.Insert("TempTextStorageAddress", "");
	FileInfo.Insert("BaseName",               Context.FileProperties.BaseName);
	FileInfo.Insert("Extension",                     Right(Extension, StrLen(Extension)-1));
	FileInfo.Insert("BeingEditedBy",                    Undefined);
	
	Try
		FilesOperationsInternalServerCall.UpdateAttachedFile(
			Context.AttachedFile, FileInfo);
	Except
		ErrorInformation = ErrorInfo();
		Result.Insert("ErrorDescription", Context.ErrorTitle + Chars.LF
			+ BriefErrorDescription(ErrorInformation));
	EndTry;
	
	ExecuteNotifyProcessing(Context.Notification, Result);
	
EndProcedure

///////////////////////////////////////////////////////////////////////////////
// Opening the explorer with positioning on the file.

// The procedure opens Windows Explorer positioning on File.
//
// Parameters:
//  ResultHandler - NotifyDescription, Undefined - description of the procedure that gets the method result.
//  FileData  - a structure with file data.
//
Procedure FileDirectory(ResultHandler, FileData) Export
	
	// If File does not have the file, this operation is pointless.
	If FileData.Version.IsEmpty() Then 
		Return;
	EndIf;
	
	#If WebClient Then
		If NOT FileSystemExtensionAttached() Then
			ShowFileSystemExtensionRequiredMessageBox(ResultHandler);
			Return;
		EndIf;
	#EndIf
	
	FullFileName = GetFilePathInWorkingDirectory(FileData);
	If OpenExplorerWithFile(FullFileName) Then
		Return;
	EndIf;
	
	FileName = CommonClientServer.GetNameWithExtension(
		FileData.FullVersionDescription, FileData.Extension);
	
	HandlerParameters = New Structure;
	HandlerParameters.Insert("ResultHandler", ResultHandler);
	HandlerParameters.Insert("FileData", FileData);
	HandlerParameters.Insert("FileName", FileName);
	HandlerParameters.Insert("FullFileName", FullFileName);
	Handler = New NotifyDescription("FileDirectoryAfterRespondQuestionGetFile", ThisObject, HandlerParameters);
	
	QuestionButtons = New ValueList;
	QuestionButtons.Add(DialogReturnCode.Yes, NStr("ru= 'Сохранить и открыть каталог'; en = 'Save and open the directory'; pl = 'Zapisz i otwórz katalog';de = 'Verzeichnis speichern und öffnen';ro = 'Salvează și deschide directorul';tr = 'Dizini kaydet ve aç'; es_ES = 'Guardar y abrir el catálogo'"));
	QuestionButtons.Add(DialogReturnCode.No, NStr("ru= 'Отмена'; en = 'Cancel'; pl = 'Anuluj';de = 'Abbrechen';ro = 'Revocare';tr = 'İptal'; es_ES = 'Cancelar'"));
	ShowQueryBox(Handler,
		StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = 'Каталог файла не существует. Возможно, на данном компьютере файл ""%1"" еще не открывался.
			|Сохранить файл на компьютер и открыть его каталог?'; 
			|en = 'The file directory does not exist. Probably file ""%1"" was never opened on this computer.
			|Do you want to save a local file copy and open its directory?'; 
			|pl = 'Katalog pliku nie istnieje. Być może, na tym komputerze plik ""%1"" nie był jeszcze otwierany.
			|Zapisać plik na komputerze i otworzyć jego katalog?';
			|de = 'Das Dateiverzeichnis existiert nicht. Die Datei ""%1"" wurde möglicherweise noch nicht auf diesem Computer geöffnet.
			|Die Datei auf Ihrem Computer speichern und das Verzeichnis öffnen?';
			|ro = 'Directorul fișierului nu există. Posibil, pe acest computer fișierul ""%1"" încă nu a fost deschis.
			|Salvați fișierul pe computer și deschideți directorul lui?';
			|tr = 'Dosya dizini yok. Belki de bu bilgisayarda ""%1"" dosyası henüz açılmamıştır. 
			|Dosya bilgisayara kaydedilsin ve dizini açılsın mı?'; 
			|es_ES = 'El catálogo del archivo no existe. Es posible que en este ordenador el archivo ""%1"" todavía no se haya abierto.
			|¿Guardar el archivo en el ordenador y abrir su catálogo?'"),
			FileName),
		QuestionButtons);
	
EndProcedure

// Continuation of the procedure (see above).
Procedure FileDirectoryAfterRespondQuestionGetFile(Response, ExecutionParameters) Export
	
	If Response = DialogReturnCode.Yes Then
		Handler = New NotifyDescription("FileDirectoryAfterGetFileToWorkingDirectory", ThisObject, ExecutionParameters);
		GetVersionFileToWorkingDirectory(Handler, ExecutionParameters.FileData, ExecutionParameters.FullFileName);
	Else
		FileDirectoryAfterGetFileToWorkingDirectory(-1, ExecutionParameters);
	EndIf;
	
EndProcedure

// Continuation of the procedure (see above).
Procedure FileDirectoryAfterGetFileToWorkingDirectory(Result, ExecutionParameters) Export
	
	If Result <> -1 Then
		ExecutionParameters.FullFileName = Result.FullFileName;
		OpenExplorerWithFile(ExecutionParameters.FullFileName);
	EndIf;
	
	// For the option of storing files on hard drive (on the server), deleting the File from the temporary storage after receiving it.
	If IsTempStorageURL(ExecutionParameters.FileData.CurrentVersionURL) Then
		DeleteFromTempStorage(ExecutionParameters.FileData.CurrentVersionURL);
	EndIf;
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Deleting the file from the hard drive and from the information register.

// Delete from the hard drive and from the information register.
//
// Parameters:
//  ResultHandler - NotifyDescription, Undefined - description of the procedure that gets the method result.
//  Ref  - CatalogRef.Files - a file.
//  DeleteInWorkingDirectory - Boolean - delete even in the working directory
//
// Returns:
//   Structure - the result of deleting file from the hard drive and working directory.
//       * Success - Boolean - shows whether the operation is performed successfully.
//
Procedure DeleteFileFromWorkingDirectory(ResultHandler, Ref, DeleteInWorkingDirectory = False, AskQuestion = True) Export
	
	ExecutionParameters = New Structure;
	ExecutionParameters.Insert("ResultHandler", ResultHandler);
	ExecutionParameters.Insert("Ref", Ref);
	ExecutionParameters.Insert("Success", False);
	ExecutionParameters.Insert("DirectoryName", UserWorkingDirectory());
	
	ExecutionParameters.Insert("FullFileNameFromRegister", Undefined);
	
	InOwnerWorkingDirectory = False;
	ExecutionParameters.FullFileNameFromRegister = FilesOperationsInternalServerCall.GetFullFileNameFromRegister(
		ExecutionParameters.Ref, ExecutionParameters.DirectoryName, False, InOwnerWorkingDirectory);
	
	If ExecutionParameters.FullFileNameFromRegister <> "" Then
		
		// We do not usually delete files in working directory, only if the DeleteInWorkingDirectory is passed.
		If Not InOwnerWorkingDirectory OR DeleteInWorkingDirectory = True Then
			
			FileOnHardDrive = New File(ExecutionParameters.FullFileNameFromRegister);
			
			If FileOnHardDrive.Exist() Then
				FileOnHardDrive.SetReadOnly(False);
				
				RegisterHandlerDetails(
					ExecutionParameters, ThisObject, "DeleteFileFromWorkingDirectoryAfterDeleteFile");
				
				DeleteFile(ExecutionParameters, ExecutionParameters.FullFileNameFromRegister, AskQuestion);
				If ExecutionParameters.AsynchronousDialog.Open = True Then
					Return;
				EndIf;
				
				DeleteFileFromWorkingDirectoryAfterDeleteFile(
					ExecutionParameters.AsynchronousDialog.ResultWhenNotOpen, ExecutionParameters);
				Return;
				
			EndIf;
		EndIf;
	EndIf;
	
	DeleteFileFromWorkingDirectoryCompletion(ExecutionParameters);
	
EndProcedure

// Continuation of the procedure (see above).
Procedure DeleteFileFromWorkingDirectoryAfterDeleteFile(Result, ExecutionParameters) Export
	
	PathWithSubdirectory = ExecutionParameters.DirectoryName;
	Position = StrFind(ExecutionParameters.FullFileNameFromRegister, GetPathSeparator());
	If Position <> 0 Then
		PathWithSubdirectory = PathWithSubdirectory + Left(ExecutionParameters.FullFileNameFromRegister, Position);
	EndIf;
	
	FilesArrayInDirectory = FindFiles(PathWithSubdirectory, "*");
	If FilesArrayInDirectory.Count() = 0 Then
		If PathWithSubdirectory <> ExecutionParameters.DirectoryName Then
			DeleteFiles(PathWithSubdirectory);
		EndIf;
	EndIf;
	
	DeleteFileFromWorkingDirectoryCompletion(ExecutionParameters);
	
EndProcedure

// Continuation of the procedure (see above).
Procedure DeleteFileFromWorkingDirectoryCompletion(ExecutionParameters)
	
	If ExecutionParameters.FullFileNameFromRegister = "" Then
		FilesOperationsInternalServerCall.DeleteFromRegister(ExecutionParameters.Ref);
	Else
		FileOnHardDrive = New File(ExecutionParameters.FullFileNameFromRegister);
		If NOT FileOnHardDrive.Exist() Then
			FilesOperationsInternalServerCall.DeleteFromRegister(ExecutionParameters.Ref);
		EndIf;
	EndIf;
	
	ExecutionParameters.Success = True;
	ReturnResult(ExecutionParameters.ResultHandler, ExecutionParameters);
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Clearing the working directory.

// Clear space to place file. If there is enough space, it does nothing.
//
// Parameters:
//  ResultHandler - NotifyDescription, Undefined - description of the procedure that gets the method result.
//  VersionAttributes  - a structure with version attributes.
//
Procedure ClearSpaceInWorkingDirectory(ResultHandler, VersionAttributes)

	#If WebClient Then
		// The amount of free disk space cannot be determined in the web client.
		ReturnResultAfterShowWarning(
			ResultHandler,
			NStr("ru = 'Очистка рабочего каталога не поддерживается в веб-клиенте.'; en = 'Working directory cleanup is not supported in the web client.'; pl = 'Oczyszczenie katalogu roboczego nie jest dostępne w kliencie sieci Web.';de = 'Die Bereinigung von Arbeitsverzeichnissen wird im Webclient nicht unterstützt.';ro = 'Curățarea directorului de lucru nu este acceptată în clientul web.';tr = 'Web istemcisinde çalışma dizini temizleme desteklenmez.'; es_ES = 'El vaciar del directorio en función no está admitido en el cliente web.'"),
			Undefined);
		Return;
	#EndIf
	
	MaxSize = PersonalFilesOperationsSettings().LocalFileCacheMaxSize;
	
	// If the WorkingDirectory size is set to 0, then it is considered that there is no limit and the 
	// default of 10 MB is not used.
	If MaxSize = 0 Then
		Return;
	EndIf;
	
	DirectoryName = UserWorkingDirectory();
	
	FilesArray = FindFiles(DirectoryName, GetAllFilesMask());
	
	WorkingDirectoryFileSize = 0;
	TotalCount = 0;
	// Calculating the full size of files in the working directory.
	GetFileListSize(DirectoryName, FilesArray, WorkingDirectoryFileSize, TotalCount);
	
	Size = VersionAttributes.Size;
	If WorkingDirectoryFileSize + Size > MaxSize Then
		CleanUpWorkingDirectory(ResultHandler, WorkingDirectoryFileSize, Size, False); // ClearAll = False.
	EndIf;
	
EndProcedure

// Clearing the working directory to make space. First it deletes the files most recently placed in 
// the working directory.
//
// Parameters:
//  ResultHandler - NotifyDescription, Undefined - description of the procedure that gets the method result.
//  SizeOfFilesInWorkingDirectory  - Number - the size of files in working directory.
//  SizeOfFileToAdd - Number - size of file to add.
//  ClearAll - Boolean - delete all files in the directory (and not just delete files until the required amount of disk space is free).
//
Procedure CleanUpWorkingDirectory(ResultHandler, WorkingDirectoryFileSize, SizeOfFileToAdd, ClearAll) Export
	
	#If WebClient Then
		ReturnResultAfterShowWarning(ResultHandler, NStr("ru = 'Очистка рабочего каталога не поддерживается в веб-клиенте.'; en = 'Working directory cleanup is not supported in the web client.'; pl = 'Oczyszczenie katalogu roboczego nie jest dostępne w kliencie sieci Web.';de = 'Die Bereinigung von Arbeitsverzeichnissen wird im Webclient nicht unterstützt.';ro = 'Curățarea directorului de lucru nu este acceptată în clientul web.';tr = 'Web istemcisinde çalışma dizini temizleme desteklenmez.'; es_ES = 'El vaciar del directorio en función no está admitido en el cliente web.'"), Undefined);
		Return;
	#EndIf
	
	HandlerParameters = New Structure;
	HandlerParameters.Insert("ResultHandler", ResultHandler);
	HandlerParameters.Insert("WorkingDirectoryFilesSize", WorkingDirectoryFileSize);
	HandlerParameters.Insert("SizeOfFileToAdd", SizeOfFileToAdd);
	HandlerParameters.Insert("ClearAll", ClearAll);
	
	ClearWorkingDirectoryStart(HandlerParameters);
	
EndProcedure

// Continuation of the procedure (see above).
Procedure ClearWorkingDirectoryStart(ExecutionParameters)
	
	DirectoryName = UserWorkingDirectory();
	
	FilesTable = New Array;
	FilesArray = FindFiles(DirectoryName, "*");
	ProcessFilesTable(DirectoryName, FilesArray, FilesTable);
	
	// Server call - for sorting by date, which means that in the beginning there will be items, placed 
	//  in the working directory long ago.
	FilesOperationsInternalServerCall.SortStructuresArray(FilesTable);
	
	PersonalSettings = PersonalFilesOperationsSettings();
	MaxSize = PersonalSettings.LocalFileCacheMaxSize;
	
	AverageFileSize = 1000;
	If FilesTable.Count() <> 0 Then
		AverageFileSize = ExecutionParameters.WorkingDirectoryFilesSize / FilesTable.Count();
	EndIf;
	
	AmountOfFreeSpaceRequired = MaxSize / 10;
	If AverageFileSize * 3 / 2 > AmountOfFreeSpaceRequired Then
		AmountOfFreeSpaceRequired = AverageFileSize * 3 / 2;
	EndIf;
	
	SpaceLeft = ExecutionParameters.WorkingDirectoryFilesSize + ExecutionParameters.SizeOfFileToAdd;
	
	ExecutionParameters.Insert("DirectoryName", DirectoryName);
	ExecutionParameters.Insert("MaxSize", MaxSize);
	ExecutionParameters.Insert("SpaceLeft", SpaceLeft);
	ExecutionParameters.Insert("FreeSpaceRequired", AmountOfFreeSpaceRequired);
	
	ExecutionParameters.Insert("FilesTable", FilesTable);
	ExecutionParameters.Insert("ItemNumber", 1);
	ExecutionParameters.Insert("ItemCount", FilesTable.Count());
	ExecutionParameters.Insert("Item", Undefined);
	ExecutionParameters.Insert("YesForAll", False);
	ExecutionParameters.Insert("NoForAll", False);
	
	ExecutionParameters.Insert("StepNumber", 0);
	ExecutionParameters.Insert("StopCycle", False);
	
	RegisterHandlerDetails(ExecutionParameters, ThisObject, "ClearWorkingFolderDialogHandlerLoop");
	
	ClearWorkingDirectoryStartLoop(ExecutionParameters);
	
EndProcedure

// Continuation of the procedure (see above).
Procedure ClearWorkingDirectoryStartLoop(ExecutionParameters)
	
	While ExecutionParameters.ItemNumber <= ExecutionParameters.ItemCount Do
		ExecutionParameters.Item = ExecutionParameters.FilesTable[ExecutionParameters.ItemNumber - 1];
		ExecutionParameters.ItemNumber = ExecutionParameters.ItemNumber + 1;
		
		ExecutionParameters.StepNumber = 1;
		ClearWorkingDirectoryLoopHandler(ExecutionParameters);
		If ExecutionParameters.AsynchronousDialog.Open Then
			Return; // Loop pause. Stack is being cleared.
		EndIf;
		If ExecutionParameters.StopCycle Then
			Break;
		EndIf;
	EndDo;
	
	// Actions after loop.
	If ExecutionParameters.ClearAll Then
		FilesOperationsInternalServerCall.ClearAllExceptLocked();
	EndIf;
	
	ReturnResult(ExecutionParameters.ResultHandler, Undefined);
	
EndProcedure

// Continuation of the procedure (see above).
Procedure ClearWorkingDirectoryLoopHandler(ExecutionParameters)
	
	If ExecutionParameters.StepNumber = 1 Then
		If Not ExecutionParameters.YesForAll
			AND ExecutionParameters.Item.Version.IsEmpty() Then
			
			If ExecutionParameters.NoForAll Then
				Return; // Towards the cycle, this is equal to the keyword "Continue."
			EndIf;
			
			If ExecutionParameters.ClearAll = False Then
				QuestionText = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("ru = 'Выполняется очистка рабочего каталога на компьютере.
					           |
					           |В программе отсутствует файл
					           |""%1"".
					           |
					           |Удалить его копию из рабочего каталога на компьютере?'; 
					           |en = 'Cleaning up the working directory.
					           |
					           |File ""%1""
					           |is not registered in the application.
					           |
					           |Do you want to delete it from the working directory?'; 
					           |pl = 'Odbywa się czyszczenie katalogu roboczego na komputerze.
					           |
					           |W programie brakuje pliku
					           |""%1"".
					           |
					           |Usunąć jego kopię z katalogu roboczego na komputerze?';
					           |de = 'Das Arbeitsverzeichnis auf dem Computer wird gelöscht.
					           |
					           |Es gibt keine Datei
					           |""%1"" im Programm.
					           |
					           |Eine Kopie davon aus dem Arbeitsverzeichnis auf dem Computer löschen?';
					           |ro = 'Are loc golirea directorului pe computer.
					           |
					           |În program lipsește fișierul
					           |""%1"".
					           |
					           |Ștergeți copia lui din directorul pe computer?';
					           |tr = 'Bilgisayarda çalışma dizinini temizleme işlemi yapılıyor. 
					           |
					           |Uygulamada "
" %1dosyası eksik. 
					           |
					           |Bilgisayarınızdaki çalışma dizininden bir kopyası silinsin mi?'; 
					           |es_ES = 'Se está limpiando el archivo de trabajo en el ordenador.
					           |
					           |En el programa no hay archivo
					           |""%1"".
					           |
					           |¿Eliminar su copia del catálogo de trabajo en el ordenador?'"),
					ExecutionParameters.DirectoryName + ExecutionParameters.Item.Path);
			Else
				QuestionText = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("ru = 'В программе отсутствует файл
					           |""%1"".
					           |
					           |Удалить его копию из рабочего каталога на компьютере?'; 
					           |en = 'File ""%1"" 
					           |is not registered in the application.
					           |
					           |Do you want to delete it from the working directory?'; 
					           |pl = 'W programie brakuje pliku
					           |""%1"".
					           |
					           |Usunąć jego kopię z katalogu roboczego na komputerze?';
					           |de = 'Es gibt keine Datei
					           |""%1"" im Programm.
					           |
					           |Eine Kopie davon aus dem Arbeitsverzeichnis auf deinem Computer löschen?';
					           |ro = 'În program lipsește fișierul
					           |""%1"".
					           |
					           |Ștergeți copia lui din directorul pe computer?';
					           |tr = 'Uygulamada 
					           |""%1"" dosyası eksik. 
					           |
					           |Bilgisayarınızdaki çalışma dizininden bir kopyası silinsin mi?'; 
					           |es_ES = 'En el programa no hay archivo
					           |""%1"".
					           |
					           |¿Eliminar su copia del catálogo de trabajo en el ordenador?'"),
					ExecutionParameters.DirectoryName + ExecutionParameters.Item.Path);
			EndIf;
			
			Buttons = New ValueList;
			Buttons.Add("Yes",         NStr("ru = 'Да'; en = 'Yes'; pl = 'Tak';de = 'Ja';ro = 'Da';tr = 'Evet'; es_ES = 'Sí'"));
			Buttons.Add("YesForAll",  NStr("ru = 'Да для всех'; en = 'Yes to all'; pl = 'Tak, dla wszystkich';de = 'Ja zu allen';ro = 'Da la toate';tr = 'Hepsine evet'; es_ES = 'Sí a todo'"));
			Buttons.Add("No",        NStr("ru = 'Нет'; en = 'No'; pl = 'Nie';de = 'Nein';ro = 'Nu';tr = 'No'; es_ES = 'No'"));
			Buttons.Add("NoForAll", NStr("ru = 'Нет для всех'; en = 'Not for all'; pl = 'Nie, dla wszystkich';de = 'Nein zu allen';ro = 'Nu pentru toate';tr = 'Hayır, hepsi için değil'; es_ES = 'No para todo'"));
			
			ShowQueryBox(PrepareHandlerForDialog(ExecutionParameters), QuestionText, Buttons);
			Return;
		EndIf;
		
		ExecutionParameters.StepNumber = 2;
	EndIf;
	
	If ExecutionParameters.StepNumber = 2 Then
		FullPath = ExecutionParameters.DirectoryName + ExecutionParameters.Item.Path;
		FileOnHardDrive = New File(FullPath);
		FileOnHardDrive.SetReadOnly(False);
		If ExecutionParameters.ClearAll = False Then
			QuestionHeader = NStr("ru = 'Выполняется очистка рабочего каталога на компьютере при добавлении файла.'; en = 'Cleaning up the working directory to free up space for a new file.'; pl = 'Odbywa się czyszczenie katalogu roboczego na komputerze podczas dodawania pliku.';de = 'Das Arbeitsverzeichnis auf dem Computer wird bereinigt, wenn Sie eine Datei hinzufügen.';ro = 'Se execută golirea directorului pe computer la adăugarea fișierului.';tr = 'Dosya eklendiğinde bilgisayarda çalışma dizini temizleniyor.'; es_ES = 'Se está vaciando el catálogo en función en el ordenador al añadir el archivo.'");
		Else
			QuestionHeader = NStr("ru = 'Выполняется очистка рабочего каталога на компьютере.'; en = 'Cleaning up the working directory.'; pl = 'Odbywa się czyszczenie katalogu roboczego na komputerze.';de = 'Das Arbeitsverzeichnis auf dem Computer wird bereinigt.';ro = 'Se execută golirea directorului pe computer.';tr = 'Bilgisayardaki çalışma dizini temizleniyor.'; es_ES = 'Se está vaciando el catálogo en función en el ordenador.'");
		EndIf;
		
		DeleteFile(ExecutionParameters, FullPath, Undefined, QuestionHeader);
		If ExecutionParameters.AsynchronousDialog.Open Then
			Return; // Loop pause. Stack is being cleared.
		EndIf;
		
		ExecutionParameters.StepNumber = 3;
	EndIf;
	
	If ExecutionParameters.StepNumber = 3 Then
		
		PathWithSubdirectory = ExecutionParameters.DirectoryName;
		Position = StrFind(ExecutionParameters.Item.Path, GetPathSeparator());
		If Position <> 0 Then
			PathWithSubdirectory = ExecutionParameters.DirectoryName + Left(ExecutionParameters.Item.Path, Position);
		EndIf;
		
		// If the directory has become blank, delete it.
		FilesArrayInDirectory = FindFiles(PathWithSubdirectory, "*");
		If FilesArrayInDirectory.Count() = 0 Then
			If PathWithSubdirectory <> ExecutionParameters.DirectoryName Then
				DeleteFiles(PathWithSubdirectory);
			EndIf;
		EndIf;
		
		// Deleting from the information register.
		FilesOperationsInternalServerCall.DeleteFromRegister(ExecutionParameters.Item.Version);
		
		ExecutionParameters.SpaceLeft = ExecutionParameters.SpaceLeft - ExecutionParameters.Item.Size;
		If ExecutionParameters.SpaceLeft < ExecutionParameters.MaxSize - ExecutionParameters.FreeSpaceRequired Then
			If Not ExecutionParameters.ClearAll Then
				// If there is enough free space, exit the loop.
				ExecutionParameters.StopCycle = True;
				Return;
			EndIf;
		EndIf;
		
	EndIf;
	
EndProcedure

// Continuation of the procedure (see above).
Procedure ClearWorkingFolderDialogHandlerLoop(Result, ExecutionParameters) Export
	
	If ExecutionParameters.StepNumber = 1 Then
		If Result = "No" Then
			ContinueExecution = False;
		ElsIf Result = "NoForAll" Then
			ContinueExecution = False;
			ExecutionParameters.NoForAll = True;
		ElsIf Result = "Yes" Then
			ContinueExecution = True;
		ElsIf Result = "YesForAll" Then
			ContinueExecution = True;
			ExecutionParameters.YesForAll = True;
		EndIf;
	ElsIf ExecutionParameters.StepNumber = 2 Then
		ContinueExecution = True;
	EndIf;
	
	// Continue deleting the file
	If ContinueExecution Then
		ExecutionParameters.StepNumber = ExecutionParameters.StepNumber + 1;
		ExecutionParameters.AsynchronousDialog.Open = False;
		ClearWorkingDirectoryLoopHandler(ExecutionParameters);
		If ExecutionParameters.AsynchronousDialog.Open Then
			Return; // Loop pause. Stack is being cleared.
		EndIf;
	EndIf;
	
	// Continue loop.
	ExecutionParameters.AsynchronousDialog.Open = False;
	ClearWorkingDirectoryStartLoop(ExecutionParameters);
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Receiving file from the server and its registration in the local cache.

// Receive the File from server and register it in the local cache.
//
// Parameters:
//  ResultHandler - NotifyDescription, Undefined - description of the procedure that gets the method result.
//  FileData  - a structure with file data.
//  FullFileNameInWorkingDirectory - String - here a full file name is returned.
//  FileDateInBase - Date - file date in base.
//  ForRead - Boolean - a file is placed for reading.
//  FormID - a form UUID.
//
// Returns:
//   Structure - result.
//       * FileReceived - Boolean - shows whether the operation is performed successfully.
//       * FullFileName - String - a full file name.
//
Procedure GetFromServerAndRegisterInLocalFilesCache(ResultHandler,
	FileData,
	FullFileName,
	ModificationTimeUniversal,
	ForReading,
	FormID,
	AdditionalParameters = Undefined)
	
	// Parametrization variables:
	ExecutionParameters = New Structure;
	ExecutionParameters.Insert("ResultHandler", ResultHandler);
	ExecutionParameters.Insert("FileData", FileData);
	ExecutionParameters.Insert("FullFileName", FullFileName);
	ExecutionParameters.Insert("ModificationTimeUniversal", ModificationTimeUniversal);
	ExecutionParameters.Insert("ForReading", ForReading);
	ExecutionParameters.Insert("FormID", FormID);
	ExecutionParameters.Insert("AdditionalParameters", AdditionalParameters);
	
	GetFromServerAndRegisterInLocalFilesCacheStart(ExecutionParameters);
	
EndProcedure

// Continuation of the procedure (see above).
Procedure GetFromServerAndRegisterInLocalFilesCacheStart(ExecutionParameters)
	
	// Execution variables:
	ExecutionParameters.Insert("InOwnerWorkingDirectory", ExecutionParameters.FileData.OwnerWorkingDirectory <> "");
	ExecutionParameters.Insert("DirectoryName", "");
	ExecutionParameters.Insert("DirectoryNamePreviousValue", "");
	ExecutionParameters.Insert("FileName", "");
	ExecutionParameters.Insert("FullPathMaxSize", 260);
	ExecutionParameters.Insert("FileReceived", False);
	
	If ExecutionParameters.FullFileName = "" Then
		ExecutionParameters.DirectoryName = UserWorkingDirectory();
		ExecutionParameters.DirectoryNamePreviousValue = ExecutionParameters.DirectoryName;
		
		// Generating a file name with an extension.
		ExecutionParameters.FileName = ExecutionParameters.FileData.FullVersionDescription;
		If Not IsBlankString(ExecutionParameters.FileData.Extension) Then 
			ExecutionParameters.FileName = CommonClientServer.GetNameWithExtension(ExecutionParameters.FileName, ExecutionParameters.FileData.Extension);
		EndIf;
		
		ExecutionParameters.FullFileName = "";
		If Not IsBlankString(ExecutionParameters.FileName) Then
			ExecutionParameters.FullFileName = ExecutionParameters.DirectoryName + FilesOperationsInternalClientServer.GetUniqueNameWithPath(
				ExecutionParameters.DirectoryName,
				ExecutionParameters.FileName);
		EndIf;
		
		If IsBlankString(ExecutionParameters.FileName) Then
			ReturnResult(ExecutionParameters.ResultHandler, ExecutionParameters);
			Return;
		EndIf;
		
		ExecutionParameters.FullPathMaxSize = 260;
		If Lower(ExecutionParameters.FileData.Extension) = "xls" Or Lower(ExecutionParameters.FileData.Extension) = "xlsx" Then
			// The excel name length together with the path cannot exceed 218 characters.
			ExecutionParameters.FullPathMaxSize = 218;
		EndIf;
		
		MaxFileNameLength = ExecutionParameters.FullPathMaxSize - 5; // min 5 for "C:\1\"
		
		If ExecutionParameters.InOwnerWorkingDirectory = False Then
#If Not WebClient Then
			If StrLen(ExecutionParameters.FullFileName) > ExecutionParameters.FullPathMaxSize Then
				UserDirectoryPath = UserDataDir();
				MaxFileNameLength = ExecutionParameters.FullPathMaxSize - StrLen(UserDirectoryPath);
				
				// If the file hame plus 5 exceeds 260, write "Replace the file name with a shorter one. OK" and exit.
				If StrLen(ExecutionParameters.FileName) > MaxFileNameLength Then
					MessageText =
					StringFunctionsClientServer.SubstituteParametersToString(
						NStr("ru = 'Длина пути к файлу (рабочий каталог плюс имя файла) превышает %1 символов
						           |%2'; 
						           |en = 'The file path (working directory + file name) is longer than %1 characters:
						           |%2'; 
						           |pl = 'Długość ścieżki dostępu do pliku (katalog roboczy plus nazwa pliku
						           |) przekracza %1 symboli %2';
						           |de = 'Die Länge des Pfads zur Datei (Arbeitsverzeichnis plus Datei
						           | Name) überschreitet %1 die Anzahl der Zeichen %2 ';
						           |ro = 'Lungimea căii spre fișier (numele directorului plus numele fișierului) depășește %1 caractere
						           |%2';
						           |tr = 'Dosya yolu uzunluğu (çalışma dizini artı dosya adı) %1karakterleri aşıyor
						           |%2'; 
						           |es_ES = 'La longitud de la ruta para el archivo (directorio en función más el nombre
						           |del archivo) excede %1 símbolos %2'"),
						ExecutionParameters.FullPathMaxSize,
						ExecutionParameters.FullFileName);
					
					MessageText = MessageText + Chars.CR + Chars.CR
						+ NStr("ru = 'Измените имя файла на более короткое.'; en = 'Please choose a shorter file name.'; pl = 'Zmień nazwę pliku na krótszą.';de = 'Ersetzen Sie den Dateinamen durch einen kürzeren.';ro = 'Înlocuiți numele fișierului cu unul mai scurt.';tr = 'Dosya adını daha kısa olanla değiştirin.'; es_ES = 'Reemplazar el nombre del archivo con uno más corto.'");
					ReturnResultAfterShowWarning(ExecutionParameters.ResultHandler, MessageText, ExecutionParameters);
					Return;
				EndIf;
				
				GetFromServerAndRegisterInLocalFilesCacheOfferSelectDirectory(-1, ExecutionParameters);
				Return;
			EndIf;
#EndIf
		EndIf;
		
	EndIf;
	
	GetFromServerAndRegisterInLocalFilesCacheFollowUp(ExecutionParameters);
	
EndProcedure

// Continuation of the procedure (see above).
Procedure GetFromServerAndRegisterInLocalFilesCacheOfferSelectDirectory(Response, ExecutionParameters)
	
	QuestionText = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("ru = 'Длина пути к файлу превышает %1 символов:
		|%2
		|
		|Выбрать другой основной рабочий каталог?'; 
		|en = 'The file path (working directory + file name) is longer than %1 characters:
		|%2
		|
		|Do you want to select a different main working directory?'; 
		|pl = 'Długość ścieżki do pliku przekracza %1 znaków:
		|%2
		|
		|Wybrać inny główny katalog roboczy?';
		|de = 'Dateipfadlänge überschreitet %1 Zeichen:
		|%2
		|
		|Anderes Hauptarbeitsverzeichnis auswählen?';
		|ro = 'Lungimea căii fișierului depășește %1 caractere:
		| %2
		|
		|Alegeți un alt director principal?';
		|tr = 'Dosya yolu uzunluğu %1karakteri aşıyor: 
		|%2
		|
		|Farklı bir ana çalışma dizini seçilsin mi?'; 
		|es_ES = 'La longitud de la ruta al archivo supera %1 símbolos:
		|%2
		|
		|¿Seleccionar otro catálogo en función principal?'"),
		ExecutionParameters.FullPathMaxSize,
		ExecutionParameters.FullFileName);
	Handler = New NotifyDescription("GetFromServerAndRegisterInLocalFilesCacheStartToSelectDirectory", ThisObject, ExecutionParameters);
	ShowQueryBox(Handler, QuestionText, QuestionDialogMode.YesNo);
	
EndProcedure

// Continuation of the procedure (see above).
Procedure GetFromServerAndRegisterInLocalFilesCacheStartToSelectDirectory(Response, ExecutionParameters) Export
	
	If Response = DialogReturnCode.No Then
		ReturnResult(ExecutionParameters.ResultHandler, ExecutionParameters);
		Return;
	EndIf;
	
	// Selecting a new path to a working directory.
	Title = NStr("ru = 'Выберите другой основной рабочий каталог'; en = 'Select another main working directory'; pl = 'Wybrać inny główny katalog roboczy';de = 'Wählen Sie ein anderes Hauptarbeitsverzeichnis';ro = 'Selectați un alt director principal de lucru';tr = 'Başka ana çalışma dizini seçin'; es_ES = 'Seleccionar otro directorio en función principal'");
	DirectorySelected = ChoosePathToWorkingDirectory(ExecutionParameters.DirectoryName, Title, False);
	If Not DirectorySelected Then
		ReturnResult(ExecutionParameters.ResultHandler, ExecutionParameters);
		Return;
	EndIf;
	
	ExecutionParameters.FullFileName = ExecutionParameters.DirectoryName + FilesOperationsInternalClientServer.GetUniqueNameWithPath(
		ExecutionParameters.DirectoryName,
		ExecutionParameters.FileName);
	
	// fits into 260 characters
	If StrLen(ExecutionParameters.FullFileName) <= ExecutionParameters.FullPathMaxSize Then
		Handler = New NotifyDescription("GetFromServerAndRegisterInLocalFilesCacheAfterMoveWorkingDirectoryContent", ThisObject, ExecutionParameters);
		MoveWorkingDirectoryContent(Handler, ExecutionParameters.DirectoryNamePreviousValue, ExecutionParameters.DirectoryName);
	Else
		GetFromServerAndRegisterInLocalFilesCacheOfferSelectDirectory(-1, ExecutionParameters);
	EndIf;
	
EndProcedure

// Continuation of the procedure (see above).
Procedure GetFromServerAndRegisterInLocalFilesCacheAfterMoveWorkingDirectoryContent(ContentMoved, ExecutionParameters) Export
	
	If ContentMoved Then
		SetUserWorkingDirectory(ExecutionParameters.DirectoryName);
		GetFromServerAndRegisterInLocalFilesCacheFollowUp(ExecutionParameters);
	Else
		ReturnResult(ExecutionParameters.ResultHandler, ExecutionParameters);
	EndIf;
	
EndProcedure

// Continuation of the procedure (see above).
Procedure GetFromServerAndRegisterInLocalFilesCacheFollowUp(ExecutionParameters)
	
	#If Not WebClient Then
		If ExecutionParameters.InOwnerWorkingDirectory = False Then
			ClearSpaceInWorkingDirectory(Undefined, ExecutionParameters.FileData);
		EndIf;
	#EndIf
	
	// Write File to directory
	ExecutionParameters.FileName = CommonClientServer.GetNameWithExtension(
		ExecutionParameters.FileData.FullVersionDescription,
		ExecutionParameters.FileData.Extension);
	
	FileOnHardDriveByName = New File(ExecutionParameters.FullFileName);
	NameAndExtensionInPath = FileOnHardDriveByName.Name;
	Position = StrFind(ExecutionParameters.FullFileName, NameAndExtensionInPath);
	PathToFile = "";
	If Position <> 0 Then
		PathToFile = Left(ExecutionParameters.FullFileName, Position - 1); // -1 - slash deduction
	EndIf;
	
	PathToFile = CommonClientServer.AddLastPathSeparator(PathToFile);
	ExecutionParameters.Insert("ParameterPathToFile", PathToFile);
	
	ExecutionParameters.FullFileName = PathToFile + ExecutionParameters.FileName; // an extension could have been replaced
	
	If ExecutionParameters.FileData.Property("UpdatePathFromFileOnHardDrive") Then
		
		FileCopy(ExecutionParameters.FileData.UpdatePathFromFileOnHardDrive, ExecutionParameters.FullFileName);
		GetFromServerAndRegisterInLocalFilesCacheCompletion(ExecutionParameters);
		
		Return;
	EndIf;
	
	If ExecutionParameters.FileData.Encrypted Then
		
		If Not CommonClient.SubsystemExists("StandardSubsystems.DigitalSignature") Then
			Return;
		EndIf;
		
		FillTemporaryFormID(ExecutionParameters.FormID, ExecutionParameters);
		
		ReturnStructure = FilesOperationsInternalServerCall.FileDataAndBinaryData(
			ExecutionParameters.FileData.Version,, ExecutionParameters.FormID);
		
		DataDetails = New Structure;
		DataDetails.Insert("Operation",              NStr("ru = 'Расшифровка файла'; en = 'Decrypt file'; pl = 'Deszyfrowanie plików';de = 'Dateientschlüsselung';ro = 'Decriptarea fișierului';tr = 'Dosya şifresini çözme'; es_ES = 'Descodificación del archivo'"));
		DataDetails.Insert("DataTitle",       NStr("ru = 'Файл'; en = 'File'; pl = 'Plik';de = 'Datei';ro = 'Fișier';tr = 'Dosya'; es_ES = 'Archivo'"));
		DataDetails.Insert("Data",                ReturnStructure.BinaryData);
		DataDetails.Insert("Presentation",         ExecutionParameters.FileData.Ref);
		DataDetails.Insert("EncryptionCertificates", ExecutionParameters.FileData.Ref);
		DataDetails.Insert("NotifyOnCompletion",   False);
		
		FollowUpHandler = New NotifyDescription(
			"GetFromServerAndRegisterInLocalFilesCacheAfterDecryption",
			ThisObject,
			ExecutionParameters);
		
		ModuleDigitalSignatureClient = CommonClient.CommonModule("DigitalSignatureClient");
		ModuleDigitalSignatureClient.Decrypt(DataDetails, , FollowUpHandler);
		
		Return;
	EndIf;
	
	GetFromServerAndRegisterInLocalFilesCacheFileSending(ExecutionParameters);
	
EndProcedure

// Continuation of the procedure (see above).
Procedure GetFromServerAndRegisterInLocalFilesCacheAfterDecryption(DataDetails, ExecutionParameters) Export
	
	If Not DataDetails.Success Then
		ReturnResult(ExecutionParameters.ResultHandler, ExecutionParameters);
		Return;
	EndIf;
	
	If TypeOf(DataDetails.DecryptedData) = Type("BinaryData") Then
		FileAddress = PutToTempStorage(DataDetails.DecryptedData,
			ExecutionParameters.FormID);
	Else
		FileAddress = DataDetails.DecryptedData;
	EndIf;
	
	GetFromServerAndRegisterInLocalFilesCacheFileSending(ExecutionParameters, FileAddress);
	
EndProcedure

// Continuation of the procedure (see above).
Procedure GetFromServerAndRegisterInLocalFilesCacheFileSending(ExecutionParameters, FileAddress = Undefined)
	
	If FileAddress = Undefined Then
		If ExecutionParameters.FileData.Version <> ExecutionParameters.FileData.CurrentVersion Then
			FileAddress = FilesOperationsInternalServerCall.GetURLToOpen(
				ExecutionParameters.FileData.Version, ExecutionParameters.FormID);
		Else
			FileAddress = ExecutionParameters.FileData.BinaryFileDataRef;
		EndIf;
	EndIf;
	
	FilesToTransfer = New Array;
	Details = New TransferableFileDescription(ExecutionParameters.FullFileName, FileAddress);
	FilesToTransfer.Add(Details);
	
	#If WebClient Then
		If ExecutionParameters.AdditionalParameters <> Undefined AND ExecutionParameters.AdditionalParameters.Property("OpenFile") Then
			
		OperationArray = New Array;
		
		CallDetails = New Array;
		CallDetails.Add("GetFiles");
		CallDetails.Add(FilesToTransfer);
		CallDetails.Add(Undefined);  // Obsolete attribute.
		CallDetails.Add(ExecutionParameters.ParameterPathToFile);
		CallDetails.Add(False);          // Interactively = False.
		OperationArray.Add(CallDetails);
		
		CallDetails = New Array;
		CallDetails.Add("RunApplication");
		CallDetails.Add(ExecutionParameters.FullFileName);
		OperationArray.Add(CallDetails);
		
		If Not RequestUserPermission(OperationArray) Then
			// User did not give a permission.
			ClearTemporaryFormID(ExecutionParameters);
			ReturnResult(ExecutionParameters.ResultHandler, ExecutionParameters);
			Return;
		EndIf;
		
		EndIf;
	#EndIf
	
	ReceivedFiles = New Array;
	If Not GetFiles(FilesToTransfer, ReceivedFiles , , False) Then
		ClearTemporaryFormID(ExecutionParameters);
		ReturnResult(ExecutionParameters.ResultHandler, ExecutionParameters);
		Return;
	EndIf;
	
	// If files are stored on the hard disk (on the server), the file is deleted from the temporary 
	// storage after receiving it.
	If IsTempStorageURL(FileAddress) Then
		DeleteFromTempStorage(FileAddress);
	EndIf;
	
	// Setting file change time equal to the change time of the current version.
	FileOnHardDrive = New File(ExecutionParameters.FullFileName);
	FileOnHardDrive.SetModificationUniversalTime(ExecutionParameters.ModificationTimeUniversal);
	
	GetFromServerAndRegisterInLocalFilesCacheCompletion(ExecutionParameters);
	
EndProcedure

// Continuation of the procedure (see above).
Procedure GetFromServerAndRegisterInLocalFilesCacheCompletion(ExecutionParameters)
	
	FileOnHardDrive = New File(ExecutionParameters.FullFileName);
	
	// Because the size on the hard drive may differ from the size in the base (when added from the web client).
	FileSize = FileOnHardDrive.Size();
	
	FileOnHardDrive.SetReadOnly(ExecutionParameters.ForReading);
	
	ExecutionParameters.DirectoryName = UserWorkingDirectory();
	
	FilesOperationsInternalServerCall.PutFileInformationInRegister(ExecutionParameters.FileData.Version,
		ExecutionParameters.FullFileName, ExecutionParameters.DirectoryName, ExecutionParameters.ForReading, FileSize,
		ExecutionParameters.InOwnerWorkingDirectory);
	
	If ExecutionParameters.FileData.Size <> FileSize Then
		// When updating from file on the hard drive correction is not required.
		If Not ExecutionParameters.FileData.Property("UpdatePathFromFileOnHardDrive") Then
			
			FilesOperationsInternalServerCall.UpdateSizeOfFileAndVersion(ExecutionParameters.FileData, 
				FileSize, ExecutionParameters.FormID);
			
			NotifyChanged(ExecutionParameters.FileData.Ref);
			NotifyChanged(ExecutionParameters.FileData.Version);
			
			NotificationParameters = New Structure;
			NotificationParameters.Insert("File"         , ExecutionParameters.FileData.Ref);
			NotificationParameters.Insert("Event"      , "FileDataChanged");
			NotificationParameters.Insert("IsNew"     , False);
			
			Notify("Write_File", NotificationParameters, ExecutionParameters.FileData.Ref);
		EndIf;
	EndIf;
	
	ClearTemporaryFormID(ExecutionParameters);
	
	ExecutionParameters.FileReceived = True;
	ReturnResult(ExecutionParameters.ResultHandler, ExecutionParameters);
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Receiving a file from the storage to working directory.

// Receives File from the storage to folder working directory and returns a path to this file.
// 
//
// Parameters:
//  ResultHandler - NotifyDescription, Undefined - description of the procedure that gets the method result.
//  FileData        - a structure with file data.
//  FullFileName     - String (return value).
//  ForRead           - Boolean - False for reading, True for editing.
//  FormID - a form UUID.
//
// Returns:
//   Structure - result.
//       * FileReceived - Boolean - shows whether the operation is performed successfully.
//       * FullFileName - String - a full file name.
//
Procedure GetVersionFileToFolderWorkingDirectory(ResultHandler,
	FileData,
	FullFileName,
	ForReading,
	FormID,
	AdditionalParameters)
	
	ExecutionParameters = New Structure;
	ExecutionParameters.Insert("ResultHandler", ResultHandler);
	ExecutionParameters.Insert("FileData", FileData);
	ExecutionParameters.Insert("FullFileName", FullFileName);
	ExecutionParameters.Insert("ForReading", ForReading);
	ExecutionParameters.Insert("FormID", FormID);
	ExecutionParameters.Insert("AdditionalParameters", AdditionalParameters);
	
	GetVersionFileToFolderWorkingDirectoryStart(ExecutionParameters);
	
EndProcedure

// Continuation of the procedure (see above).
Procedure GetVersionFileToFolderWorkingDirectoryStart(ExecutionParameters)
	
	ExecutionParameters.Insert("FileReceived", False);
	
	// Generating a file name with an extension.
	FileName = ExecutionParameters.FileData.FullVersionDescription;
	If Not IsBlankString(ExecutionParameters.FileData.Extension) Then 
		FileName = CommonClientServer.GetNameWithExtension(
			FileName, ExecutionParameters.FileData.Extension);
	EndIf;
	
	If ExecutionParameters.FullFileName = "" Then
		ExecutionParameters.FullFileName = ExecutionParameters.FileData.OwnerWorkingDirectory + FileName;
		Handler = New NotifyDescription("GetVersionFileToFolderWorkingDirectoryAfterCheckPathLength", ThisObject, ExecutionParameters);
		CheckFullPathMaxLengthInWorkingDirectory(Handler, ExecutionParameters.FileData, ExecutionParameters.FullFileName, FileName);
	Else
		GetVersionFileToFolderWorkingDirectoryFollowUp(ExecutionParameters);
	EndIf;
	
EndProcedure

// Continuation of the procedure (see above).
Procedure GetVersionFileToFolderWorkingDirectoryAfterCheckPathLength(Result, ExecutionParameters) Export
	
	If Result = False Then
		ReturnResult(ExecutionParameters.ResultHandler, ExecutionParameters);
	Else
		GetVersionFileToFolderWorkingDirectoryFollowUp(ExecutionParameters);
	EndIf;
	
EndProcedure

// Continuation of the procedure (see above).
Procedure GetVersionFileToFolderWorkingDirectoryFollowUp(ExecutionParameters)
	
	// Search for file registration in working directory (full name with the path).
	FoundProperties = FilesOperationsInternalServerCall.FindInRegisterByPath(ExecutionParameters.FullFileName);
	ExecutionParameters.Insert("FileIsInRegister", FoundProperties.FileIsInRegister);
	Version            = FoundProperties.File;
	PutFileDate     = ?(ExecutionParameters.FileIsInRegister, FoundProperties.PutFileDate, PutFileDate);
	Owner          = FoundProperties.Owner;
	InRegisterForReading = FoundProperties.InRegisterForReading;
	FileCodeInRegister = FoundProperties.FileCodeInRegister;
	InRegisterFolder    = FoundProperties.InRegisterFolder;
	
	FileOnHardDrive = New File(ExecutionParameters.FullFileName);
	FileOnHardDriveExists = FileOnHardDrive.Exist();
	
	// Deleting the file registration if it does not exist.
	If ExecutionParameters.FileIsInRegister AND Not FileOnHardDriveExists Then
		FilesOperationsInternalServerCall.DeleteFromRegister(Version);
		ExecutionParameters.FileIsInRegister = False;
	EndIf;
	
	If Not ExecutionParameters.FileIsInRegister AND Not FileOnHardDriveExists Then
		GetFromServerAndRegisterInFolderWorkingDirectory(
			ExecutionParameters.ResultHandler,
			ExecutionParameters.FileData,
			ExecutionParameters.FullFileName,
			ExecutionParameters.FileData.UniversalModificationDate,
			ExecutionParameters.ForReading,
			ExecutionParameters.FormID,
			ExecutionParameters.AdditionalParameters);
		Return;
	EndIf;
	
	// It is found that the file exists in the working directory.
	
	If ExecutionParameters.FileIsInRegister AND Version <> ExecutionParameters.FileData.CurrentVersion Then
		
		If Owner = ExecutionParameters.FileData.Ref AND InRegisterForReading = True Then
			// If the owners of the file versions match and the existing file in the working directory is 
			// registered for reading, then you can replace it with another file from the storage.
			// 
			GetFromServerAndRegisterInFolderWorkingDirectory(
				ExecutionParameters.ResultHandler,
				ExecutionParameters.FileData,
				ExecutionParameters.FullFileName,
				ExecutionParameters.FileData.UniversalModificationDate,
				ExecutionParameters.ForReading,
				ExecutionParameters.FormID,
				ExecutionParameters.AdditionalParameters);
			Return;
		EndIf;
		
		If ExecutionParameters.FileData.Owner = InRegisterFolder Then // The same folder.
			WarningText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'В рабочем каталоге на компьютере уже есть файл
				           |""%1"",
				           |соответствующий другому файлу в программе.
				           |
				           |Код файла в программе: %2.
				           |Код файла в рабочем каталоге: %3.
				           |
				           |Рекомендуется переименовать один из файлов в программе.'; 
				           |en = 'The working directory contains file
				           |""%1""
				           |that matches another file stored in the application.
				           |
				           |File code in the application: %2.
				           |File code in the working directory: %3.
				           |
				           |It is recommended that you rename one of the files in the application.'; 
				           |pl = 'W katalogu roboczym na komputerze istnieje już plik
				           |""%1"",
				           |odpowiedni do innego pliku w programie.
				           |
				           |Kod pliku w programie: %2.
				           |Kod pliku w katalogu roboczym: %3.
				           |
				           |Zaleca się zmienić nazwę jednego z plików w programie.';
				           |de = 'Es gibt bereits eine
				           |""%1""
				           |Datei im Arbeitsverzeichnis auf dem Computer, die einer anderen Datei im Programm entspricht.
				           |
				           |Datei-Code im Programm: %2.
				           |Datei-Code im Arbeitsverzeichnis: %3.
				           |
				           |Es wird empfohlen, eine der Dateien im Programm umzubenennen.';
				           |ro = 'În directorul pe computer deja există fișierul
				           |""%1"",
				           |ce corespunde altui fișier în program.
				           |
				           |Codul fișierului în program: %2.
				           |Codul fișierului în director: %3.
				           |
				           |Recomandăm să redenumiți unul din fișiere în program.';
				           |tr = 'Bilgisayardaki çalışma dizininde uygulamadaki 
				           |diğer dosyaya uygun 
				           |""%1"" dosyası mevcut.  
				           |
				           | Uygulamadaki dosya kodu: %2. 
				           | Çalışma dizinindeki dosya kodu: %3. 
				           |
				           | Uygulamadaki dosyalardan birini yeniden isimlendirilmesi önerilir.'; 
				           |es_ES = 'En el catálogo en función en el ordenador ya existe el archivo
				           |""%1""
				           |que corresponde a otro archivo en el programa.
				           |
				           |El código del archivo en el programa: %2.
				           |El código en el catálogo en función: %3.
				           |
				           |Se recomienda renombrar uno de los archivos en el programa.'"),
				ExecutionParameters.FullFileName,
				ExecutionParameters.FileData.FileCode,
				FileCodeInRegister);
		Else
			WarningText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'В рабочем каталоге на компьютере уже есть файл
				           |""%1"",
				           |соответствующий другому файлу в программе.
				           |
				           |Код файла в программе: %2.
				           |Код файла в рабочем каталоге: %3.
				           |
				           |Рекомендуется указать другой рабочий каталог для одной из папок в программе.
				           |(У двух папок не должно быть одинакового рабочего каталога).'; 
				           |en = 'The working directory contains file
				           |""%1""
				           |that matches another file stored in the application.
				           |
				           |File code in the application: %2.
				           |File code in the working directory: %3.
				           |
				           |It is recommended that you select another working directory for one of the application folders.
				           |(Two folders cannot have the same working directory.)'; 
				           |pl = 'W katalogu roboczym na komputerze istnieje już plik
				           |""%1"",
				           |odpowiedni do innego pliku w programie.
				           |
				           |Kod pliku w programie: %2.
				           |Kod pliku w katalogu roboczym: %3.
				           |
				           |Zaleca się określić inny katalog roboczy dla jednego z folderów w programie.
				           |(U dwóch folderów nie może być tego samego katalogu roboczego).';
				           |de = 'Es gibt bereits eine
				           |""%1""
				           |Datei im Arbeitsverzeichnis auf dem Computer, die einer anderen Datei im Programm entspricht.
				           |
				           |Datei-Code im Programm: %2.
				           |Datei-Code im Arbeitsverzeichnis: %3.
				           |
				           |Es wird empfohlen, ein anderes Arbeitsverzeichnis für einen der Ordner im Programm anzugeben.
				           |(Zwei Ordner sollten nicht das gleiche Arbeitsverzeichnis haben).';
				           |ro = 'În directorul pe computer deja există fișierul
				           |""%1"",
				           |ce corespunde altui fișier în program.
				           |
				           |Codul fișierului în program: %2.
				           |Codul fișierului în director: %3.
				           |
				           |Recomandăm să indicați alt director pentru unul din folderele din program.
				           |(Două foldere nu pot avea același director).';
				           |tr = 'Bilgisayardaki çalışma dizininde uygulamadaki 
				           |diğer dosyaya uygun 
				           |""%1"" dosyası mevcut.  
				           |
				           | Uygulamadaki dosya kodu: %2. 
				           | Çalışma dizinindeki dosya kodu: %3. 
				           |
				           | Uygulamadaki klasörlerden biri için başka çalışma dizinin belirtilmesi önerilir.
				           | (İki klasörde aynı çalışma dizinine sahip olmamalıdır).'; 
				           |es_ES = 'En el catálogo en función en el ordenador ya existe el archivo
				           |""%1""
				           |que corresponde a otro archivo en el programa.
				           |
				           |El código del archivo en el programa: %2.
				           |El código en el catálogo en función: %3.
				           |
				           |Se recomienda indicar otro catálogo en función para una de las carpetas en el programa.
				           |(Dos carpetas no pueden tener el mismo catálogo en función).'"),
				ExecutionParameters.FullFileName,
				ExecutionParameters.FileData.FileCode,
				FileCodeInRegister);
		EndIf;
		
		ReturnResultAfterShowWarning(ExecutionParameters.ResultHandler, WarningText, ExecutionParameters);
		Return;
	EndIf;
	
	// The file is found in the working directory.
	// Either the file is unregistered or registered and the versions are the same.
	
	// Checking the modification date and deciding what to do next.
	Handler = New NotifyDescription("GetVersionsFileToFolderWorkingDirectoryAfterActionChoice", ThisObject, ExecutionParameters);
	
	ActionOnOpenFileInWorkingDirectory(
		Handler,
		ExecutionParameters.FullFileName,
		ExecutionParameters.FileData);
	
EndProcedure

// Continuation of the procedure (see above).
Procedure GetVersionsFileToFolderWorkingDirectoryAfterActionChoice(Result, ExecutionParameters) Export
	
	If Result = "GetFromStorageAndOpen" Then
		
		// In the folder working directory, the confirmation setting during deletion is not used.
		DeleteFileWithoutConfirmation(ExecutionParameters.FullFileName);
		GetFromServerAndRegisterInLocalFilesCache(
			ExecutionParameters.ResultHandler,
			ExecutionParameters.FileData,
			ExecutionParameters.FullFileName,
			ExecutionParameters.FileData.UniversalModificationDate,
			ExecutionParameters.ForReading,
			ExecutionParameters.FormID,
			ExecutionParameters.AdditionalParameters);
		
	ElsIf Result = "OpenExistingFile" Then
		
		If ExecutionParameters.FileData.InWorkingDirectoryForRead <> ExecutionParameters.ForReading
			Or Not ExecutionParameters.FileIsInRegister Then
			
			InOwnerWorkingDirectory = ExecutionParameters.FileData.OwnerWorkingDirectory <> "";
			
			RegegisterInWorkingDirectory(
				ExecutionParameters.FileData.Version,
				ExecutionParameters.FullFileName,
				ExecutionParameters.ForReading,
				InOwnerWorkingDirectory);
		EndIf;
		
		ExecutionParameters.FileReceived = True;
		ReturnResult(ExecutionParameters.ResultHandler, ExecutionParameters);
		
	Else // Result = "Cancel".
		ExecutionParameters.FullFileName = "";
		ReturnResult(ExecutionParameters.ResultHandler, ExecutionParameters);
	EndIf;
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Receiving file from the server and its registration in the working directory.

// Receive the File from server and register it in the working directory.
//
// Parameters:
//  ResultHandler - NotifyDescription, Undefined - description of the procedure that gets the method result.
//  FileData  - a structure with file data.
//  FullFileNameInWorkingDirectory - String - here a full file name is returned.
//  FileDateInBase - Date - file date in base.
//  ForRead - Boolean - a file is placed for reading.
//  FormID - a form UUID.
//
// Returns:
//   Structure - result.
//       * FileReceived - Boolean - shows whether the operation is performed successfully.
//       * FullFileName - String - a full file name.
//
Procedure GetFromServerAndRegisterInFolderWorkingDirectory(
	ResultHandler,
	FileData,
	FullFileNameInFolderWorkiingDirectory,
	FileDateInDatabase,
	ForReading,
	FormID,
	AdditionalParameters)
	
	ExecutionParameters = New Structure;
	ExecutionParameters.Insert("ResultHandler", ResultHandler);
	ExecutionParameters.Insert("FileData", FileData);
	ExecutionParameters.Insert("FullFileNameInFolderWorkingDirectory", FullFileNameInFolderWorkiingDirectory);
	ExecutionParameters.Insert("FileDateInDatabase", FileDateInDatabase);
	ExecutionParameters.Insert("ForReading", ForReading);
	ExecutionParameters.Insert("FormID", FormID);
	ExecutionParameters.Insert("AdditionalParameters", AdditionalParameters);
	
	GetFromServerAndRegisterInFolderWorkingDirectoryStart(ExecutionParameters);
	
EndProcedure

// Continuation of the procedure (see above).
Procedure GetFromServerAndRegisterInFolderWorkingDirectoryStart(ExecutionParameters)
	
	ExecutionParameters.Insert("FullFileName", "");
	ExecutionParameters.Insert("FileReceived", False);
	
	InWorkingDirectoryForRead = True;
	InOwnerWorkingDirectory = False;
	
	FileInWorkingDirectory = FileInLocalFilesCache(
		ExecutionParameters.FileData,
		ExecutionParameters.FileData.Version,
		ExecutionParameters.FullFileName,
		InWorkingDirectoryForRead,
		InOwnerWorkingDirectory);
	
	If FileInWorkingDirectory = False Then
		GetFromServerAndRegisterInLocalFilesCache(
			ExecutionParameters.ResultHandler,
			ExecutionParameters.FileData,
			ExecutionParameters.FullFileNameInFolderWorkingDirectory,
			ExecutionParameters.FileData.UniversalModificationDate,
			ExecutionParameters.ForReading,
			ExecutionParameters.FormID,
			ExecutionParameters.AdditionalParameters);
		Return;
	EndIf;

	// Receiving a file path in the working directory and checking it for uniqueness.
	If ExecutionParameters.FullFileName = "" Then
		CommonClient.MessageToUser(
			NStr("ru = 'Не удалось получить файл из программы в рабочий каталог на компьютере.'; en = 'Cannot get the file from the application to the working directory.'; pl = 'Nie udało się pobrać pliku z programu do katalogu roboczego na komputerze.';de = 'Es war nicht möglich, die Datei aus dem Programm in das Arbeitsverzeichnis auf dem Computer zu erhalten.';ro = 'Eșec la obținerea fișierului din program în directorul pe computer.';tr = 'Uygulamadaki dosya bilgisayardaki çalışma diznine alınamadı.'; es_ES = 'No se ha podido recibir el archivo del programa al catálogo de trabajo en el ordenador.'"));
		ReturnResult(ExecutionParameters.ResultHandler, ExecutionParameters);
		Return;
	EndIf;
	
	// The file is found in the working directory.
	// Checking the modification date and deciding what to do next.
	Handler = New NotifyDescription("GetFromServerAndRegisterInFolderWorkingDirectoryAfterActionChoice", ThisObject, ExecutionParameters);
	
	ActionOnOpenFileInWorkingDirectory(
		Handler,
		ExecutionParameters.FullFileName,
		ExecutionParameters.FileData);
	
EndProcedure

// Continuation of the procedure (see above).
Procedure GetFromServerAndRegisterInFolderWorkingDirectoryAfterActionChoice(Result, ExecutionParameters) Export
	
	If Result = "GetFromStorageAndOpen" Then
		
		// In the folder working directory, the confirmation setting during deletion is not used.
		DeleteFileWithoutConfirmation(ExecutionParameters.FullFileName);
		
		GetFromServerAndRegisterInLocalFilesCache(
			ExecutionParameters.ResultHandler,
			ExecutionParameters.FileData,
			ExecutionParameters.FullFileName,
			ExecutionParameters.FileData.UniversalModificationDate,
			ExecutionParameters.ForReading,
			ExecutionParameters.FormID,
			ExecutionParameters.AdditionalParameters);
		
	ElsIf Result = "OpenExistingFile" Then
		
		If ExecutionParameters.FileData.InWorkingDirectoryForRead <> ExecutionParameters.ForReading Then
			InOwnerWorkingDirectory = ExecutionParameters.FileData.OwnerWorkingDirectory <> "";
			
			RegegisterInWorkingDirectory(
				ExecutionParameters.FileData.Version,
				ExecutionParameters.FullFileName,
				ExecutionParameters.ForReading,
				InOwnerWorkingDirectory);
		EndIf;
		
		ExecutionParameters.FileReceived = True;
		ReturnResult(ExecutionParameters.ResultHandler, ExecutionParameters);
		
	Else // Result = "Cancel".
		ExecutionParameters.FullFileName = "";
		ReturnResult(ExecutionParameters.ResultHandler, ExecutionParameters);
	EndIf;
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Checking the max length of working directory, replacing and moving files.

// Checks the max length and changes and moves files if necessary.
//
// Parameters:
//  ResultHandler - NotifyDescription, Undefined - description of the procedure that gets the method result.
//  FileData  - a structure with file data.
//  FullFileName - String - a full file name.
//  NormalFileName - String - a file name (without path).
//
// Returns:
//   Boolean - shows whether the operation is completed successfully.
//       * True if the length of full file name does not exceed 260.
//
Procedure CheckFullPathMaxLengthInWorkingDirectory(ResultHandler,
		FileData, FullFileName, NormalFileName)
	
	ExecutionParameters = New Structure;
	ExecutionParameters.Insert("ResultHandler", ResultHandler);
	ExecutionParameters.Insert("FileData", FileData);
	ExecutionParameters.Insert("FullFileName", FullFileName);
	ExecutionParameters.Insert("NormalFileName", NormalFileName);
	
	CheckFullPathMaxLengthInWorkingDirectoryStart(ExecutionParameters);
	
EndProcedure

// Continuation of the procedure (see above).
Procedure CheckFullPathMaxLengthInWorkingDirectoryStart(ExecutionParameters)
	
	#If WebClient Then
		ReturnResult(ExecutionParameters.ResultHandler, True);
		Return;
	#EndIf
	
	ExecutionParameters.Insert("DirectoryNamePreviousValue", ExecutionParameters.FileData.OwnerWorkingDirectory);
	ExecutionParameters.Insert("FullPathMaxSize", 260);
	If Lower(ExecutionParameters.FileData.Extension) = "xls" Or Lower(ExecutionParameters.FileData.Extension) = "xlsx" Then
		// The excel name length together with the path cannot exceed 218 characters.
		ExecutionParameters.FullPathMaxSize = 218;
	EndIf;
	
	MaxFileNameLength = ExecutionParameters.FullPathMaxSize - 5; // min 5 for "C:\1\"
	
	If StrLen(ExecutionParameters.FullFileName) <= ExecutionParameters.FullPathMaxSize Then
		ReturnResult(ExecutionParameters.ResultHandler, True);
		Return;
	EndIf;
	
	MessageText = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("ru = 'Длина полного пути к файлу (рабочий каталог плюс имя файла) превышает %1 символов
		           |""%2"".'; 
		           |en = 'The file path (working directory + file name) is longer than %1 characters:
		           |%2'; 
		           |pl = 'Długość pełnej ścieżki do pliku (katalog roboczy plus nazwa pliku) przekracza %1 znaków
		           |""%2"".';
		           |de = 'Die Länge des vollständigen Dateipfades (Arbeitsverzeichnis plus Dateiname) übersteigt %1 Zeichen
		           |""%2"".';
		           |ro = 'Lungimea căii depline spre fișier (numele directorului plus numele fișierului) depășește %1 caractere
		           |""%2"".';
		           |tr = 'Dosya yolu uzunluğu (çalışma dizini artı dosya adı) %1karakterleri aşıyor
		           |""%2"".'; 
		           |es_ES = 'La longitud de la ruta al archivo (catálogo en función más nombre del archivo) supera %1 símbolos
		           |""%2"".'"),
		ExecutionParameters.FullPathMaxSize,
		ExecutionParameters.FullFileName);
	
	UserDirectoryPath = UserDataDir();
	MaxFileNameLength = ExecutionParameters.FullPathMaxSize - StrLen(UserDirectoryPath);
	
	// If the file hame plus 5 exceeds 260, write "Replace the file name with a shorter one. OK" and exit.
	If StrLen(ExecutionParameters.NormalFileName) > MaxFileNameLength Then
		MessageText = MessageText + Chars.CR + Chars.CR
			+ NStr("ru = 'Измените имя файла на более короткое.'; en = 'Please choose a shorter file name.'; pl = 'Zmień nazwę pliku na krótszą.';de = 'Ersetzen Sie den Dateinamen durch einen kürzeren.';ro = 'Înlocuiți numele fișierului cu unul mai scurt.';tr = 'Dosya adını daha kısa olanla değiştirin.'; es_ES = 'Reemplazar el nombre del archivo con uno más corto.'");
		ReturnResultAfterShowWarning(ExecutionParameters.ResultHandler, MessageText, False);
		Return;
	EndIf;
	
	// If the structure of folders (a path to the working directory of the current folder) exceeds 260-5 
	// (1.txt), write "Change folder names or move this folder to another one".
	If StrLen(ExecutionParameters.FileData.OwnerWorkingDirectory) > ExecutionParameters.FullPathMaxSize - 5 Then
		MessageText = MessageText + Chars.CR + Chars.CR
			+ NStr("ru = 'Измените имена папок или перенесите текущую папку в другую папку.'; en = 'Please rename the folders or move the current folder to another one.'; pl = 'Zmień nazwy folderów lub przemieść ten folder do innego folderu.';de = 'Ändern Sie die Ordnernamen oder verschieben Sie diesen Ordner in einen anderen Ordner.';ro = 'Schimbați numele dosarelor sau mutați acest dosar în altul.';tr = 'Klasör adlarını değiştirin veya bu klasörü başka bir klasöre taşıyın.'; es_ES = 'Cambiar los nombres de la carpeta o mover esta carpeta a otra.'");
		ReturnResultAfterShowWarning(ExecutionParameters.ResultHandler, MessageText, False);
		Return;
	EndIf;
	
	CheckFullPathMaxLengthInWorkingDirectorySuggestChooseDirectory(ExecutionParameters);
	
EndProcedure

// Continuation of the procedure (see above).
Procedure CheckFullPathMaxLengthInWorkingDirectorySuggestChooseDirectory(ExecutionParameters)
	
	QuestionText = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("ru = 'Длина полного пути к файлу (рабочий каталог плюс имя файла) превышает %1 символов
		|""%2"".
		|
		|Выбрать другой основной рабочий каталог?
		|(Содержимое рабочего каталога будет перенесено в выбранный каталог).'; 
		|en = 'The full file path (working directory + file name) is longer than %1 characters:
		|%2
		|
		|Do you want to select a different main working directory?
		|(The working directory content will be moved to the selected directory.)'; 
		|pl = 'Długość pełnej ścieżki do pliku (katalog roboczy plus nazwa pliku) 
		|%1przekracza ""%2"" znaków.
		|
		|Czy chcesz
		|wybrać inny domyślny katalog roboczy? (Zawartość katalogu roboczego zostanie przeniesiona do wybranego katalogu).';
		|de = 'Die Länge des vollständigen Pfads zur Datei (Arbeitsverzeichnis plus Name der angehängten Datei) überschreitet die 
		|%1Zeichen ""%2"".
		|
		|Möchten Sie ein anderes Standardarbeitsverzeichnis
		|auswählen? (Der Inhalt des Arbeitsverzeichnisses wird in das ausgewählte Verzeichnis übertragen).';
		|ro = 'Lungimea căii complete la fișier (director plus nume de fișier) depășește %1  caractere
		|""%2"".
		|
		|Doriți să selectați alt director principal?
		|(Conținutul directorului va fi transferat în directorul selectat).';
		|tr = 'Tam dosya yolu uzunluğu (çalışma dizini artı dosya adı) %1"
" %2karakterlerini aşıyor. 
		|
		|Başka bir ana çalışma dizini seçilsin mi? 
		|(Çalışma dizininin içeriği seçilen dizine aktarılır).'; 
		|es_ES = 'Longitud de la ruta completa para el archivo (directorio en función más el nombre del archivo del adjunto) excede
		|%1 símbolos ""%2"".
		|
		|¿Quiere
		|seleccionar otro directorio en función por defecto? (Los contenidos del directorio en función se transferirán al directorio seleccionado).'"),
		ExecutionParameters.FullPathMaxSize, ExecutionParameters.FullFileName);
	Handler = New NotifyDescription("CheckFullPathMaxLengthInWorkingDirectoryStartChooseDirectory", ThisObject, ExecutionParameters);
	ShowQueryBox(Handler, QuestionText, QuestionDialogMode.YesNo);
	
EndProcedure

// Continuation of the procedure (see above).
Procedure CheckFullPathMaxLengthInWorkingDirectoryStartChooseDirectory(Response, ExecutionParameters) Export
	
	If Response = DialogReturnCode.No Then
		ReturnResult(ExecutionParameters.ResultHandler, False);
		Return;
	EndIf;
	
	// Selecting a new path to a working directory.
	Title = NStr("ru = 'Выберите другой рабочий каталог'; en = 'Select another working directory'; pl = 'Wybierz inny katalog roboczy';de = 'Wählen Sie ein anderes Arbeitsverzeichnis';ro = 'Selectați un alt director de lucru';tr = 'Başka bir çalışma dizini seç'; es_ES = 'Seleccionar otro directorio en función'");
	DirectorySelected = ChoosePathToWorkingDirectory(ExecutionParameters.FileData.OwnerWorkingDirectory, Title, True);
	If Not DirectorySelected Then
		ReturnResult(ExecutionParameters.ResultHandler, False);
		Return;
	EndIf;
	
	ExecutionParameters.FullFileName = ExecutionParameters.FileData.OwnerWorkingDirectory + ExecutionParameters.NormalFileName;
	
	// fits into 260 characters
	If StrLen(ExecutionParameters.FullFileName) <= ExecutionParameters.FullPathMaxSize Then
		Handler = New NotifyDescription("CheckFullPathMaxLengthInWorkingDirectoryAfterMoveWorkingDirectoryContent", ThisObject, ExecutionParameters);
		MoveWorkingDirectoryContent(Handler, ExecutionParameters.DirectoryNamePreviousValue, ExecutionParameters.FileData.OwnerWorkingDirectory);
	Else
		CheckFullPathMaxLengthInWorkingDirectorySuggestChooseDirectory(ExecutionParameters);
	EndIf;
	
EndProcedure

// Continuation of the procedure (see above).
Procedure CheckFullPathMaxLengthInWorkingDirectoryAfterMoveWorkingDirectoryContent(ContentMoved, ExecutionParameters) Export
	
	If ContentMoved Then
		// FilesInWorkingDirectory information register now has the full path to file. You need to change it: 
		// select the main part and replace it by SQL query by the current user.
		// 
		FilesOperationsInternalServerCall.SaveFolderWorkingDirectoryAndReplacePathsInRegister(
			ExecutionParameters.FileData.Owner,
			ExecutionParameters.FileData.OwnerWorkingDirectory,
			ExecutionParameters.DirectoryNamePreviousValue);
	EndIf;
	ReturnResult(ExecutionParameters.ResultHandler, ContentMoved);
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Copying the content from one directory to another.

// Copies all files from the specified directory to another one.
//
// Parameters:
//   ResultHandler - NotifyDescription, Undefined - description of the procedure that gets the method result.
//   SourceDirectory  - String - the directory previous name.
//   RecipientDirectory  - String - new name of the directory.
//
// Returns:
//   Structure - the result of copying.
//       * ErrorOccurred           - Boolean - True when all files are copied.
//       * ErrorInformation       - ErrorInformation - information about an error.
//       * ErrorFullFileName   - String - a full name of the file that caused an error when copying.
//       * CopiedFilesAndFolders - Array - full names of recipient files and folders.
//       * OriginalFilesAndFolders  - Array - full names of source files and folders.
//
Procedure CopyDirectoryContent1(ResultHandler, Val SourceDirectory, Val RecipientDirectory)
	
	Result = New Structure;
	Result.Insert("ErrorOccurred",           False);
	Result.Insert("ErrorFileFullName",   "");
	Result.Insert("ErrorInfo",       "");
	Result.Insert("CopiedFilesAndFolders", New Array);
	Result.Insert("OriginalFilesAndFolders",  New Array);
	
	CopyDirectoryContent(Result, SourceDirectory, RecipientDirectory);
	
	If Result.ErrorOccurred Then
		
		QuestionText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Не удалось скопировать файл
			           |""%1"".
			           |Возможно он занят другим приложением.
			           |
			           |Повторить операцию?'; 
			           |en = 'Cannot copy file
			           |""%1"".
			           |Probably it is locked by another application.
			           |
			           |Do you want to retry?'; 
			           |pl = 'Nie udało się skopiować pliku
			           |""%1"".
			           |Być może jest on zajęty przez inną aplikację.
			           |
			           |Powtórzyć operację?';
			           |de = 'Die Datei
			           |""%1"" konnte nicht kopiert werden.
			           |Vielleicht ist sie mit einer anderen Anwendung belegt.
			           |
			           |Den Vorgang wiederholen?';
			           |ro = 'Eșec la copierea fișierului
			           |""%1"".
			           |Posibil să fie blocat de o altă aplicație.
			           |
			           |Repetați operația?';
			           |tr = '"
" %1Dosyası kopyalanamadı. 
			           |Başka bir uygulama tarafından kullanılıyor olabilir. 
			           |
			           |İşlemi tekrar yapmak istiyor musunuz?'; 
			           |es_ES = 'No se ha podido copiar el archivo
			           |""%1"".
			           |Es posible que esté ocupado por otra aplicación.
			           |
			           |¿Repetir la operación?'"),
			Result.ErrorFileFullName);
		
		ExecutionParameters = New Structure;
		ExecutionParameters.Insert("ResultHandler", ResultHandler);
		ExecutionParameters.Insert("SourceDirectory", SourceDirectory);
		ExecutionParameters.Insert("DestinationDirectory", RecipientDirectory);
		ExecutionParameters.Insert("Result", Result);
		
		Handler = New NotifyDescription("CopyDirectoryContentAfterRespondQuestion", 
			ThisObject, ExecutionParameters);
		
		ShowQueryBox(Handler, QuestionText, QuestionDialogMode.YesNo);
	Else
		ReturnResult(ResultHandler, Result);
	EndIf;
	
EndProcedure

// Continuation of the procedure (see above).
Procedure CopyDirectoryContentAfterRespondQuestion(Response, ExecutionParameters) Export
	
	If Response = DialogReturnCode.No Then
		ReturnResult(ExecutionParameters.ResultHandler, ExecutionParameters.Result);
	Else
		CopyDirectoryContent1(
			ExecutionParameters.ResultHandler,
			ExecutionParameters.SourceDirectory,
			ExecutionParameters.DestinationDirectory);
	EndIf;
	
EndProcedure

// Copies all files from the specified directory to another one.
//
// Parameters:
//   Result - Structure - the result of copying. See CopyDirectoryContent1(), return value. 
//   SourceDirectory  - String - the directory previous name.
//   RecipientDirectory  - String - new name of the directory.
//
Procedure CopyDirectoryContent(Result, SourceDirectory, RecipientDirectory)
	
	RecipientDirectory = CommonClientServer.AddLastPathSeparator(RecipientDirectory);
	SourceDirectory = CommonClientServer.AddLastPathSeparator(SourceDirectory);
	
	CreateDirectory(RecipientDirectory);
	
	Result.CopiedFilesAndFolders.Add(RecipientDirectory);
	Result.OriginalFilesAndFolders.Add(SourceDirectory);
	
	SourceFiles = FindFiles(SourceDirectory, "*");
	
	For Each SourceFile In SourceFiles Do
		
		SourceFullFileName = SourceFile.FullName;
		SourceFileName       = SourceFile.Name;
		FullRecipientFileName = RecipientDirectory + SourceFileName;
		
		If SourceFile.IsDirectory() Then
			
			CopyDirectoryContent(Result, SourceFullFileName, FullRecipientFileName);
			If Result.ErrorOccurred Then
				Return;
			EndIf;
			
		Else
			
			Result.OriginalFilesAndFolders.Add(SourceFullFileName);
			
			RecipientFile = New File(FullRecipientFileName);
			If RecipientFile.Exist() Then
				// This is required for backward copying. In this case files can exist already.
				Result.CopiedFilesAndFolders.Add(FullRecipientFileName);
			Else
				Try
					FileCopy(SourceFullFileName, FullRecipientFileName);
				Except
					Result.ErrorOccurred         = True;
					Result.ErrorInfo     = ErrorInfo();
					Result.ErrorFileFullName = SourceFullFileName;
					Return;
				EndTry;
				Result.CopiedFilesAndFolders.Add(FullRecipientFileName);
			EndIf;
		EndIf;
		
	EndDo;
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Moving the working directory content into a new one.

// Transfers all files from the working directory to another directory (including those taken for editing).
//
// Parameters:
//   ResultHandler - NotifyDescription, Undefined - description of the procedure that gets the method result.
//   SourceDirectory - String - previous name of the directory.
//   RecipientDirectory - String - new name of the directory.
//
// Returns:
//   Boolean - shows whether the operation is completed successfully.
//
Procedure MoveWorkingDirectoryContent(ResultHandler, SourceDirectory, RecipientDirectory) Export
	
	// A new path is a subset of the old one. This is prohibited, because it can cause looping.
	If StrFind(Lower(RecipientDirectory), Lower(SourceDirectory)) <> 0 Then
		WarningText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Выбранный рабочий каталог
			           |""%1""
			           |входит в старый рабочий каталог
			           |""%2"".'; 
			           |en = 'The destination working directory
			           |""%1""
			           |is included in the source working directory
			           |""%2"".'; 
			           |pl = 'Wybrany katalog roboczy
			           |""%1""
			           |wchodzi do starego katalogu roboczego
			           |""%2"".';
			           |de = 'Das ausgewählte Arbeitsverzeichnis
			           |""%1""
			           |ist im alten Arbeitsverzeichnis
			           |""%2"" enthalten.';
			           |ro = 'Directorul selectat
			           |""%1""
			           |face parte din directorul vechi
			           |""%2"".';
			           |tr = 'Seçilmiş çalışma dizini 
			           |""%1""
			           | eski çalışma dizini kapsamındadır 
			           |""%2"".'; 
			           |es_ES = 'El catálogo seleccionado
			           |""%1""
			           |forma parte del catálogo en función antiguo
			           |""%2"".'"),
			RecipientDirectory,
			SourceDirectory);
		ReturnResultAfterShowWarning(ResultHandler, WarningText, False);
		Return;
	EndIf;
	
	// Copying files from the old directory to a new one.
	HandlerParameters = New Structure;
	HandlerParameters.Insert("ResultHandler", ResultHandler);
	HandlerParameters.Insert("SourceDirectory", SourceDirectory);
	HandlerParameters.Insert("DestinationDirectory", RecipientDirectory);
	Handler = New NotifyDescription("MoveWorkingDirectoryContentAfterCopyToNewDirectory", ThisObject, HandlerParameters);
	
	CopyDirectoryContent1(Handler, SourceDirectory, RecipientDirectory);
	
EndProcedure

// Continuation of the procedure (see above).
Procedure MoveWorkingDirectoryContentAfterCopyToNewDirectory(Result, ExecutionParameters) Export
	
	If Result.ErrorOccurred Then
		// A copying error occurred and then user canceled the operation.
		
		Handler = New NotifyDescription(
			"MoveWorkingDirectoryContentAfterCancelAndClearRecipient",
			ThisObject,
			ExecutionParameters);
		
		DeleteDirectoryContent(Handler, Result.CopiedFilesAndFolders); // Clearing the recipient folder.
	Else
		// Copying succeeded. Clearing the old directory.
		Handler = New NotifyDescription(
			"MoveWorkingDirectoryContentAfterSuccessAndClearSource",
			ThisObject,
			ExecutionParameters);
		
		DeleteDirectoryContent(Handler, Result.OriginalFilesAndFolders);
	EndIf;
	
EndProcedure

// Continuation of the procedure (see above).
Procedure MoveWorkingDirectoryContentAfterCancelAndClearRecipient(RecipientDirectoryCleareed, ExecutionParameters) Export
	
	ReturnResult(ExecutionParameters.ResultHandler, False);
	
EndProcedure

// Continuation of the procedure (see above).
Procedure MoveWorkingDirectoryContentAfterSuccessAndClearSource(SourceDirectoryCleared, ExecutionParameters) Export
	
	If SourceDirectoryCleared Then
		// Old directory has been cleared. All the operation steps are completed successfully.
		ReturnResult(ExecutionParameters.ResultHandler, True);
	Else
		// Old directory has not been cleared. Rolling back the whole operation.
		Handler = New NotifyDescription("MoveWorkingDirectoryContentAfterSuccessAndCancelClearing", ThisObject, ExecutionParameters);
		CopyDirectoryContent1(Handler, ExecutionParameters.DestinationDirectory, ExecutionParameters.SourceDirectory);
	EndIf;
	
EndProcedure

// Continuation of the procedure (see above).
Procedure MoveWorkingDirectoryContentAfterSuccessAndCancelClearing(Result, ExecutionParameters) Export
	
	// Rolling back operation.
	If Result.ErrorOccurred Then
		// Warning that an error occurred during the operation rollback.
		WarningText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Не удалось скопировать обратно содержимое каталога
			           |""%1""
			           |в каталог
			           |""%2"".'; 
			           |en = 'Cannot copy files from directory
			           |""%1""
			           |back to directory
			           |""%2"".'; 
			           |pl = 'Nie udało się skopiować z powrotem zawartość katalogu
			           |""%1""
			           |do katalogu
			           |""%2"".';
			           |de = 'Der Inhalt des Verzeichnisses
			           |""%1""
			           |konnte nicht in das Verzeichnis
			           |""%2""zurückkopiert werden.';
			           |ro = 'Eșec la copierea conținutului directorului
			           |""%1""
			           |înapoi în directorul 
			           |""%2"".';
			           |tr = '
			           |""%1""
			           | dizinin içeriği 
			           |""%2"" dizine geri kopyalanamadı.'; 
			           |es_ES = 'No se ha podido volver a copiar el contenido del catálogo
			           |""%1""
			           |en el catálogo
			           |""%2"".'"),
			ExecutionParameters.DestinationDirectory,
			ExecutionParameters.SourceDirectory);
		ReturnResultAfterShowWarning(ExecutionParameters.ResultHandler, WarningText, False);
	Else
		// The operation was rolled back successfully.
		ReturnResult(ExecutionParameters.ResultHandler, False);
	EndIf;
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Deleting the path array of passed folders and files.

// Deletes all files and folders from the passed array.
//   Passing from the end.
//
// Parameters:
//   ResultHandler - NotifyDescription, Undefined - description of the procedure that gets the method result.
//   CopiedFilesAndFolders - Array - (String) a path array of files and folders.
//
// Returns:
//   Boolean - shows whether the operation is completed successfully.
//
Procedure DeleteDirectoryContent(ResultHandler, CopiedFilesAndFolders)
	
	ExecutionParameters = New Structure;
	ExecutionParameters.Insert("ResultHandler", ResultHandler);
	ExecutionParameters.Insert("CopiedFilesAndFolders", CopiedFilesAndFolders);
	ExecutionParameters.Insert("UBound", CopiedFilesAndFolders.Count() - 1);
	ExecutionParameters.Insert("IndexOf", 0);
	
	DeleteDirectoryContentStart(ExecutionParameters);
	
EndProcedure

// Continuation of the procedure (see above).
Procedure DeleteDirectoryContentStart(ExecutionParameters)
	
	For Index = ExecutionParameters.IndexOf To ExecutionParameters.UBound Do
		Path = ExecutionParameters.CopiedFilesAndFolders[ExecutionParameters.UBound - Index];
		File = New File(Path);
		If Not File.Exist() Then
			Continue; // For example, Word temporary file ~aaa.doc could be deleted when closing Word.
		EndIf;
		
		Try
			If File.IsFile() AND File.GetReadOnly() Then
				File.SetReadOnly(False);
			EndIf;
			DeleteFiles(Path);
			FileDeleted = True;
		Except
			FileDeleted = False;
		EndTry;
		
		If Not FileDeleted Then
			QuestionText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'Не удалось удалить файл
				           |""%1"".
				           |Возможно он занят другим приложением.
				           |
				           |Повторить операцию?'; 
				           |en = 'Cannot delete file
				           |""%1"".
				           |Probably it is locked by another application.
				           |
				           |Do you want to retry?'; 
				           |pl = 'Nie udało się usunąć pliku
				           |""%1"".
				           |Być może jest on zajęty przez inną aplikację.
				           |
				           |Powtórzyć operację?';
				           |de = 'Die Datei
				           |""%1""konnte nicht gelöscht werden.
				           |Vielleicht ist sie mit einer anderen Anwendung belegt.
				           |
				           |Den Vorgang wiederholen?';
				           |ro = 'Eșec la copierea fișierului
				           |""%1"".
				           |Posibil să fie blocat de o altă aplicație.
				           |
				           |Repetați operația?';
				           |tr = '"
" %1Dosyası kopyalanamadı. 
				           |Başka bir uygulama tarafından kullanılıyor olabilir. 
				           |
				           |İşlemi tekrar yapmak istiyor musunuz?'; 
				           |es_ES = 'No se ha podido eliminar el archivo
				           |""%1"".
				           |Es posible que esté ocupado por otra aplicación.
				           |
				           |¿Repetir la operación?'"),
				Path);
			ExecutionParameters.IndexOf = Index;
			Handler = New NotifyDescription("DeleteDirectoryContentAfterRespondQuestionRepeat", ThisObject, ExecutionParameters);
			ShowQueryBox(Handler, QuestionText, QuestionDialogMode.YesNo);
			Return;
		EndIf;
	EndDo;
	
	ReturnResult(ExecutionParameters.ResultHandler, True);
	
EndProcedure

// Continuation of the procedure (see above).
Procedure DeleteDirectoryContentAfterRespondQuestionRepeat(Response, ExecutionParameters) Export
	
	If Response = DialogReturnCode.No Then
		ReturnResult(ExecutionParameters.ResultHandler, False);
	Else
		DeleteDirectoryContentStart(ExecutionParameters);
	EndIf;
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Import files checking their size.

// Import with auxiliary operations such as checking the size limit and subsequently deleting files 
//          and showing errors when importing only one folder, it will return a reference to it.
//
// Parameters:
//  ExecutionParameters - Structure - see FilesImportParameters. 
//
// Returns:
//   Undefined - if files are not imported.
//   Structure - if files are imported.
//       * FolderForAddingCurrent - CatalogRef.FilesFolders - a folder to add files to.
//
Procedure ExecuteFilesImport(Val ExecutionParameters) Export
	
	InternalParameters = CommonClient.CopyRecursive(ExecutionParameters);
	Handler = New NotifyDescription("FilesImportAfterCheckSizes", ThisObject, InternalParameters);
	CheckMaxFilesSize(Handler, InternalParameters);
	
EndProcedure

// Continuation of the procedure (see above).
Procedure FilesImportAfterCheckSizes(Result, ExecutionParameters) Export
	
	If Result.Success = False Then
		ReturnResult(ExecutionParameters.ResultHandler, Undefined);
		Return;
	EndIf;
	
	ExecutionParameters.Insert("TotalCount", Result.TotalCount);
	If ExecutionParameters.TotalCount = 0 Then
		ReturnResultAfterShowWarning(ExecutionParameters.ResultHandler, NStr("ru = 'Нет файлов для добавления'; en = 'There are no files to add.'; pl = 'Nie ma plików do dodania';de = 'Es sind keine Dateien hinzuzufügen';ro = 'Nu există fișiere de adăugat';tr = 'Eklenecek dosya yok'; es_ES = 'No hay archivos para añadir'"), Undefined);
		Return;
	EndIf;
	
	ExecutionParameters.Insert("FirstFolderWithSameName", Undefined);
	ExecutionParameters.Insert("FolderForAddingCurrent", Undefined);
	ExecutionParameters.Insert("SelectedFilesInBoundary", ExecutionParameters.SelectedFiles.Count()-1);
	ExecutionParameters.Insert("SelectedFilesIndex", -1);
	ExecutionParameters.Insert("Indicator", 0);
	ExecutionParameters.Insert("Counter", 0);
	ExecutionParameters.Insert("FilesArray", New Array);
	ExecutionParameters.Insert("ArrayOfFilesNamesWithErrors", New Array);
	ExecutionParameters.Insert("AllFilesStructureArray", New Array);
	ExecutionParameters.Insert("AllFoldersArray", New Array);
	ExecutionParameters.Insert("FilesArrayOfThisDirectory", Undefined);
	ExecutionParameters.Insert("FolderName", Undefined);
	ExecutionParameters.Insert("Path", Undefined);
	ExecutionParameters.Insert("FolderAlreadyFound", Undefined);
	RegisterHandlerDetails(ExecutionParameters, ThisObject, "ImportFilesLoopContinueImportAfterRecurringQuestions");
	FilesImportLoop(ExecutionParameters);
	
EndProcedure

// Continuation of the procedure (see above).
Procedure FilesImportLoop(ExecutionParameters)
	
	ExecutionParameters.SelectedFilesIndex = ExecutionParameters.SelectedFilesIndex + 1;
	For Index = ExecutionParameters.SelectedFilesIndex To ExecutionParameters.SelectedFilesInBoundary Do
		ExecutionParameters.SelectedFilesIndex = Index;
		FileName = ExecutionParameters.SelectedFiles[Index];
		
		SelectedFile = New File(FileName.Value);
		
		DirectorySelected = False;
		If SelectedFile.Exist() Then
			DirectorySelected = SelectedFile.IsDirectory();
		EndIf;
		
		If DirectorySelected Then
			ExecutionParameters.Path = FileName.Value;
			ExecutionParameters.FilesArrayOfThisDirectory = FindFilesPseudo(ExecutionParameters.PseudoFileSystem, ExecutionParameters.Path);
			
			ExecutionParameters.FolderName = SelectedFile.Name;
			
			ExecutionParameters.FolderAlreadyFound = False;
			
			If FilesOperationsInternalServerCall.HasFolderWithThisName(
					ExecutionParameters.FolderName,
					ExecutionParameters.Owner,
					ExecutionParameters.FirstFolderWithSameName) Then
				QuestionText = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("ru = 'Папка ""%1"" уже существует.
					           |
					           |Продолжить импорт папки?'; 
					           |en = 'Folder ""%1"" already exists.
					           |
					           |Do you want to continue the upload?'; 
					           |pl = 'Folder ""%1"" już istnieje.
					           |
					           |Kontynuować import folderu?';
					           |de = 'Der Ordner ""%1"" existiert bereits.
					           |
					           |Ordnerimport fortsetzen?';
					           |ro = 'Dosarul ""%1"" există deja.
					           |
					           |Continuați importul dosarului?';
					           |tr = 'Klasör ""%1"" zaten var. 
					           |
					           |Klasör içe aktarılıyor mu?'; 
					           |es_ES = 'Carpeta ""%1"" ya existe.
					           |
					           |¿Continuar la importación de la carpeta?'"),
					ExecutionParameters.FolderName);
				Handler = New NotifyDescription("FilesImportLoopAfterRespondQuestionContinue", ThisObject, ExecutionParameters);
				ShowQueryBox(Handler, QuestionText, QuestionDialogMode.YesNo);
				Return;
			EndIf;
			FilesImportLoopContinueImport(ExecutionParameters);
			If ExecutionParameters.AsynchronousDialog.Open = True Then
				Return;
			EndIf;
		Else
			ExecutionParameters.FilesArray.Add(SelectedFile);
		EndIf;
	EndDo;
	
	If ExecutionParameters.FilesArray.Count() <> 0 Then
		// The actual import
		RegisterHandlerDetails(ExecutionParameters, ThisObject, "ImportFilesAfterLoopAfterRecurringQuestions");
		ImportFilesRecursively(ExecutionParameters.Owner, ExecutionParameters.FilesArray, ExecutionParameters);
		
		If ExecutionParameters.AsynchronousDialog.Open = True Then
			Return;
		EndIf;
	EndIf;
	
	FilesImportAfterLoopFollowUp(ExecutionParameters);
	
EndProcedure

// Continuation of the procedure (see above).
Procedure FilesImportLoopAfterRespondQuestionContinue(Response, ExecutionParameters) Export
	
	If Response <> DialogReturnCode.No Then
		FilesImportLoopContinueImport(ExecutionParameters);
	EndIf;
	
	FilesImportLoop(ExecutionParameters);
	
EndProcedure

// Continuation of the procedure (see above).
Procedure FilesImportLoopContinueImport(ExecutionParameters)
	
	If Not ExecutionParameters.FolderAlreadyFound Then
		PathSeparator = GetPathSeparator();
		WorkingDirectory  = ExecutionParameters.Path + ?(Right(ExecutionParameters.Path, 1) = PathSeparator, "", PathSeparator);
		If FilesOperationsInternalClientCached.IsDirectoryFiles(ExecutionParameters.Owner) Then
			ExecutionParameters.FolderForAddingCurrent = FilesOperationsInternalServerCall.CreateFilesFolder(
				ExecutionParameters.FolderName, ExecutionParameters.Owner, , , WorkingDirectory);
		Else		
			ExecutionParameters.FolderForAddingCurrent = ExecutionParameters.Owner;
			ExecutionParameters.GroupOfFiles = FilesOperationsInternalServerCall.CreateFilesFolder(
				ExecutionParameters.FolderName, ExecutionParameters.Owner, , ExecutionParameters.GroupOfFiles, WorkingDirectory);
		EndIf;	
	EndIf;
	
	// The actual import
	ImportFilesRecursively(ExecutionParameters.FolderForAddingCurrent, ExecutionParameters.FilesArrayOfThisDirectory, ExecutionParameters);
	If ExecutionParameters.AsynchronousDialog.Open = True Then
		Return;
	EndIf;
	
	ExecutionParameters.AllFoldersArray.Add(ExecutionParameters.Path);
	
EndProcedure

// Continuation of the procedure (see above).
Procedure ImportFilesLoopContinueImportAfterRecurringQuestions(Result, ExecutionParameters) Export
	
	ExecutionParameters.AsynchronousDialog.Open = False;
	ExecutionParameters.AllFoldersArray.Add(ExecutionParameters.Path);
	FilesImportLoop(ExecutionParameters);
	
EndProcedure

// Continuation of the procedure (see above).
Procedure ImportFilesAfterLoopAfterRecurringQuestions(Result, ExecutionParameters) Export
	
	FilesImportAfterLoopFollowUp(ExecutionParameters);
	
EndProcedure

// Continuation of the procedure (see above).
Procedure FilesImportAfterLoopFollowUp(ExecutionParameters)
	
	If ExecutionParameters.AllFilesStructureArray.Count() > 1 Then
		StateText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Импорт файлов завершен. Импортировано файлов: %1'; en = 'The upload is completed. Files uploaded: %1.'; pl = 'Import plików zakończony. Importowano plików: %1';de = 'Der Dateiimport ist abgeschlossen. Dateien importiert: %1';ro = 'Importul fișierelor este finalizat. Fișiere importate: %1';tr = 'Dosyaların içe aktarımı tamamlandı.  İçe aktarılan dosya sayısı: %1'; es_ES = 'Archivos se han importado. Archivos importados: %1'"), String(ExecutionParameters.AllFilesStructureArray.Count()) );
		ShowUserNotification(StateText);
	EndIf;
	
	If ExecutionParameters.DeleteFilesAfterAdd = True Then
		DeleteFilesAfterAdd(ExecutionParameters.AllFilesStructureArray, ExecutionParameters.AllFoldersArray);
	EndIf;
	
	If ExecutionParameters.AllFilesStructureArray.Count() = 1 Then
		Item0 = ExecutionParameters.AllFilesStructureArray[0];
		Ref = GetURL(Item0.File);
		ShowUserNotification(
			NStr("ru = 'Изменение:'; en = 'Updated:'; pl = 'Aktualizuj:';de = 'Aktualisieren:';ro = 'Actualizați:';tr = 'Güncelle:'; es_ES = 'Actualizar:'"),
			Ref,
			Item0.File,
			PictureLib.Information32);
	EndIf;
	
	// Error message output
	If ExecutionParameters.ArrayOfFilesNamesWithErrors.Count() <> 0 Then
		Parameters = New Structure;
		Parameters.Insert("ArrayOfFilesNamesWithErrors", ExecutionParameters.ArrayOfFilesNamesWithErrors);
		
		OpenForm("DataProcessor.FilesOperations.Form.ReportForm", Parameters);
	EndIf;
	
	If ExecutionParameters.SelectedFiles.Count() <> 1 Then
		ExecutionParameters.FolderForAddingCurrent = Undefined;
	EndIf;
	
	ReturnResult(ExecutionParameters.ResultHandler, ExecutionParameters);
	
EndProcedure

// Deletes files after import or download.
Procedure DeleteFilesAfterAdd(AllFilesStructureArray, AllFoldersArray)
	
	For Each Item In AllFilesStructureArray Do
		SelectedFile = New File(Item.FileName);
		SelectedFile.SetReadOnly(False);
		DeleteFiles(SelectedFile.FullName);
	EndDo;
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Saving File to hard drive

// Saving File to hard drive
// 
// Parameters:
//   ResultHandler - NotifyDescription, Undefined - description of the procedure that gets the method result.
//   FileData  - a structure with file data.
//   UUID - a form UUID.
//
// Returns:
//   String - the selected full file path.
//
Procedure SaveAs(ResultHandler, FileData, UUID) Export
	
	ExecutionParameters = New Structure;
	ExecutionParameters.Insert("ResultHandler", ResultHandler);
	ExecutionParameters.Insert("FileData", FileData);
	ExecutionParameters.Insert("UUID", UUID);
	
	If FileSystemExtensionAttached() Then
		SaveAsWithExtension(ExecutionParameters);
	Else
		SaveAsWithoutExtension(ExecutionParameters);
	EndIf;
	
EndProcedure

// Continuation of the procedure (see above).
Procedure SaveAsWithExtension(ExecutionParameters)
	
	// Checking whether the file is already in cache, and if it is, show a dialog box with a choice.
	ExecutionParameters.Insert("PathToFileInCache", "");
	If ExecutionParameters.FileData.CurrentUserEditsFile Then
		InWorkingDirectoryForRead = True;
		InOwnerWorkingDirectory = False;
		ExecutionParameters.Insert("FullFileName", "");
		FileInWorkingDirectory = FileInLocalFilesCache(ExecutionParameters.FileData, ExecutionParameters.FileData.Version, ExecutionParameters.FullFileName, InWorkingDirectoryForRead, InOwnerWorkingDirectory);
		
		If FileInWorkingDirectory = True Then
			
			FileDateInDatabase = ExecutionParameters.FileData.UniversalModificationDate;
			
			VersionFile = New File(ExecutionParameters.FullFileName);
			FileDateOnHardDrive = VersionFile.GetModificationUniversalTime();
			
			If FileDateOnHardDrive > FileDateInDatabase Then // The working directory has a newer one (changed by a third party user).
				FormOpenParameters = New Structure;
				FormOpenParameters.Insert("File", ExecutionParameters.FullFileName);
				
				Message = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("ru = 'Дата изменения файла ""%1""
					           |в рабочем каталоге на компьютере более поздняя (новее), чем в программе.
					           |Возможно, файл на компьютере был отредактирован.'; 
					           |en = 'The local copy of file ""%1""
					           |was modified later than the file in the application.
					           |The local copy might have been edited.'; 
					           |pl = 'Data modyfikacji pliku ""%1""
					           |w katalogu roboczym na komputerze jest późniejsza (nowsza), niż w programie.
					           |Być może plik na komputerze był edytowany.';
					           |de = 'Das Datum, an dem die Datei ""%1""
					           |im Arbeitsverzeichnis des Computers geändert wird, ist später (neuer) als im Programm.
					           |Die Datei auf dem Computer wurde möglicherweise bearbeitet.';
					           |ro = 'Data modificării fișierului ""%1""
					           |în directorul pe computer este mai târzie (nouă) decât în program.
					           |Posibil, fișierul pe computer a fost editat.';
					           |tr = 'Bilgisayardaki çalışma dizinindeki ""%1""
					           | dosyanın değişim tarihi, uygulamadaki tarihten daha geç (yeni)dir. 
					           |Bilgisayardaki dosya düzenlenmiş olabilir.'; 
					           |es_ES = 'La fecha de la modificación del archivo ""%1""
					           |en el catálogo en función en el ordenador es más tarde (nueva) que en el programa.
					           |Es posible que el archivo en el ordenador haya sido editado.'"),
					String(ExecutionParameters.FileData.Ref));
				
				FormOpenParameters.Insert("Message", Message);
				
				Handler = New NotifyDescription("SaveAsWithExtensionAfterRespondQuestionDateNewer", ThisObject, ExecutionParameters);
				OpenForm("DataProcessor.FilesOperations.Form.FileCreationModeForSaveAs", FormOpenParameters, , , , , Handler, FormWindowOpeningMode.LockWholeInterface);
				Return;
			EndIf;
		EndIf;
	EndIf;
	
	SaveAsWithExtensionFollowUp(ExecutionParameters);
	
EndProcedure

// Continuation of the procedure (see above).
Procedure SaveAsWithExtensionAfterRespondQuestionDateNewer(Response, ExecutionParameters) Export
	
	If Response = DialogReturnCode.Cancel Or Response = Undefined Then
		ReturnResult(ExecutionParameters.ResultHandler, "");
		Return;
	EndIf;
	
	If Response = 1 Then // Based on file on local computer.
		ExecutionParameters.PathToFileInCache = ExecutionParameters.FullFileName;
	EndIf;
	
	SaveAsWithExtensionFollowUp(ExecutionParameters);
	
EndProcedure

// Continuation of the procedure (see above).
Procedure SaveAsWithExtensionFollowUp(ExecutionParameters)
	
	ExecutionParameters.Insert("ChoicePath", ExecutionParameters.FileData.FolderForSaveAs);
	If ExecutionParameters.ChoicePath = Undefined Or ExecutionParameters.ChoicePath = "" Then
		ExecutionParameters.ChoicePath = MyDocumentsDirectory();
	EndIf;
	
	ExecutionParameters.Insert("SaveDecrypted", False);
	ExecutionParameters.Insert("EncryptedFilesExtension", "");
	
	If ExecutionParameters.FileData.Encrypted Then
		Handler = New NotifyDescription("SaveAsWithExtensionAfterSaveModeChoice",
			ThisObject, ExecutionParameters);
		
		OpenForm("DataProcessor.FilesOperations.Form.SelectEncryptedFileSaveMode", , , , , ,
			Handler, FormWindowOpeningMode.LockWholeInterface);
	Else
		SaveAsWithExtensionAfterSaveModeChoice(-1, ExecutionParameters);
	EndIf;
	
EndProcedure

// Continuation of the procedure (see above).
Procedure SaveAsWithExtensionAfterSaveModeChoice(Result, ExecutionParameters) Export
	
	If TypeOf(Result) = Type("Structure") Then
		ExecutionParameters.EncryptedFilesExtension = Result.EncryptedFilesExtension;
		
		If Result.SaveDecrypted = 1 Then
			ExecutionParameters.SaveDecrypted = True;
		Else
			ExecutionParameters.SaveDecrypted = False;
		EndIf;
		
	ElsIf Result <> -1 Then
		ReturnResult(ExecutionParameters.ResultHandler, "");
		Return;
	EndIf;
	
	If Not ExecutionParameters.SaveDecrypted Then
		SaveAsWithExtensionAfterDecryption(-1, ExecutionParameters);
		Return;
	EndIf;
	
	If Not CommonClient.SubsystemExists("StandardSubsystems.DigitalSignature") Then
		Return;
	EndIf;
	
	ReturnStructure = FilesOperationsInternalServerCall.FileDataAndBinaryData(ExecutionParameters.FileData.Version,, 
		ExecutionParameters.UUID);
	
	DataDetails = New Structure;
	DataDetails.Insert("Operation",              NStr("ru = 'Расшифровка файла'; en = 'Decrypt file'; pl = 'Deszyfrowanie plików';de = 'Dateientschlüsselung';ro = 'Decriptarea fișierului';tr = 'Dosya şifresini çözme'; es_ES = 'Descodificación del archivo'"));
	DataDetails.Insert("DataTitle",       NStr("ru = 'Файл'; en = 'File'; pl = 'Plik';de = 'Datei';ro = 'Fișier';tr = 'Dosya'; es_ES = 'Archivo'"));
	DataDetails.Insert("Data",                ReturnStructure.BinaryData);
	DataDetails.Insert("Presentation",         ExecutionParameters.FileData.Ref);
	DataDetails.Insert("EncryptionCertificates", ExecutionParameters.FileData.Ref);
	DataDetails.Insert("NotifyOnCompletion",   False);
	
	FollowUpHandler = New NotifyDescription("SaveAsWithExtensionAfterDecryption", ThisObject, ExecutionParameters);
	
	ModuleDigitalSignatureClient = CommonClient.CommonModule("DigitalSignatureClient");
	ModuleDigitalSignatureClient.Decrypt(DataDetails, , FollowUpHandler);
	
EndProcedure

// Continuation of the procedure (see above).
Procedure SaveAsWithExtensionAfterDecryption(DataDetails, ExecutionParameters) Export
	
	If DataDetails <> -1 Then
		If Not DataDetails.Success Then
			ReturnResult(ExecutionParameters.ResultHandler, ExecutionParameters);
			Return;
		EndIf;
	
		If TypeOf(DataDetails.DecryptedData) = Type("BinaryData") Then
			FileAddress = PutToTempStorage(DataDetails.DecryptedData,
				ExecutionParameters.UUID);
		Else
			FileAddress = DataDetails.DecryptedData;
		EndIf;
	Else
		If ExecutionParameters.FileData.Property("BinaryFileDataRef") Then
			FileAddress = ExecutionParameters.FileData.BinaryFileDataRef;
			ExecutionParameters.FileData.Insert("FullVersionDescription", ExecutionParameters.FileData.Description);
		Else
			FileAddress = ExecutionParameters.FileData.CurrentVersionURL;
			If ExecutionParameters.FileData.CurrentVersion <> ExecutionParameters.FileData.Version Then
				FileAddress = FilesOperationsInternalServerCall.GetURLToOpen(
					ExecutionParameters.FileData.Version, ExecutionParameters.UUID);
			EndIf;
		EndIf;
	EndIf;
	
	NameWithExtension = CommonClientServer.GetNameWithExtension(
		ExecutionParameters.FileData.FullVersionDescription, ExecutionParameters.FileData.Extension);
	
	Extension = ExecutionParameters.FileData.Extension;
	
	If ExecutionParameters.FileData.Encrypted
	   AND Not ExecutionParameters.SaveDecrypted Then
		
		If Not IsBlankString(ExecutionParameters.EncryptedFilesExtension) Then
			NameWithExtension = NameWithExtension + "." + ExecutionParameters.EncryptedFilesExtension;
			Extension = ExecutionParameters.EncryptedFilesExtension;
		EndIf;
	EndIf;
	
	// Selecting a full path to the file on the hard drive.
	SelectFile = New FileDialog(FileDialogMode.Save);
	SelectFile.Multiselect = False;
	SelectFile.FullFileName = NameWithExtension;
	SelectFile.DefaultExt = Extension;
	Filter = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("ru = 'Все файлы (*.%1)|*.%1'; en = 'All files  (*.%1)|*.%1'; pl = 'Wszystkie pliki (*.%1)|*.%1';de = 'Alle Dateien (*.%1)| *.%1';ro = 'Toate fișierele (*.%1)|*.%1';tr = 'Tüm dosyalar (*.%1)|*.%1'; es_ES = 'Todos archivos (*.%1)|*.%1'"), Extension);
	SelectFile.Filter = Filter;
	SelectFile.Directory = ExecutionParameters.ChoicePath;
	
	If Not SelectFile.Choose() Then
		ReturnResult(ExecutionParameters.ResultHandler, New Structure);
		Return;
	EndIf;
	
	FullFileName = SelectFile.FullFileName;
	
	File = New File(FullFileName);
	
	If File.Exist() Then
		If ExecutionParameters.PathToFileInCache <> FullFileName Then
			File.SetReadOnly(False);
			DeleteFiles(SelectFile.FullFileName);
		EndIf;
	EndIf;
	
	If ExecutionParameters.PathToFileInCache <> "" Then
		If ExecutionParameters.PathToFileInCache <> FullFileName Then
			FileCopy(ExecutionParameters.PathToFileInCache, SelectFile.FullFileName);
		EndIf;
	Else
		FilesToTransfer = New Array;
		Details = New TransferableFileDescription(FullFileName, FileAddress);
		FilesToTransfer.Add(Details);
		
		PathToFile = File.Path;
		PathToFile = CommonClientServer.AddLastPathSeparator(PathToFile);
		
		// Saving File from the database to the hard drive.
		If GetFiles(FilesToTransfer,, PathToFile, False) Then
			
			// For the option of storing files on hard drive (on the server), deleting the File from the temporary storage after receiving it.
			If IsTempStorageURL(FileAddress) Then
				DeleteFromTempStorage(FileAddress);
			EndIf;
			
			NewFile = New File(FullFileName);
			
			NewFile.SetModificationUniversalTime(
				ExecutionParameters.FileData.UniversalModificationDate);
			
		EndIf;
	EndIf;
	
	ShowUserNotification(NStr("ru = 'Файл успешно сохранен'; en = 'File saved'; pl = 'Zapis pliku zakończony pomyślnie';de = 'Die Datei wurde erfolgreich gespeichert';ro = 'Fișier salvat cu succes';tr = 'Dosya başarıyla kaydedildi'; es_ES = 'Archivo se ha guardado con éxito'"), , FullFileName);
	
	ChoicePathPrevious = ExecutionParameters.ChoicePath;
	ExecutionParameters.ChoicePath = File.Path;
	If ChoicePathPrevious <> ExecutionParameters.ChoicePath Then
		CommonServerCall.CommonSettingsStorageSave("ApplicationSettings", "FolderForSaveAs", ExecutionParameters.ChoicePath);
	EndIf;
	
	ReturnResult(ExecutionParameters.ResultHandler, New Structure("FullFileName", FullFileName));
	
EndProcedure

// Continuation of the procedure (see above).
Procedure SaveAsWithoutExtension(ExecutionParameters)
	
	ExecutionParameters.Insert("SaveDecrypted", False);
	ExecutionParameters.Insert("EncryptedFilesExtension", "");
	
	If ExecutionParameters.FileData.Encrypted Then
		Handler = New NotifyDescription("SaveAsWithoutExtensionAfterSaveModeChoice",
			ThisObject, ExecutionParameters);
		
		OpenForm("DataProcessor.FilesOperations.Form.SelectEncryptedFileSaveMode", , , , , ,
			Handler, FormWindowOpeningMode.LockWholeInterface);
	Else
		SaveAsWithoutExtensionAfterSaveModeChoice(-1, ExecutionParameters);
	EndIf;
	
EndProcedure

// Continuation of the procedure (see above).
Procedure SaveAsWithoutExtensionAfterSaveModeChoice(Result, ExecutionParameters) Export
	
	If TypeOf(Result) = Type("Structure") Then
		ExecutionParameters.EncryptedFilesExtension = Result.EncryptedFilesExtension;
		
		If Result.SaveDecrypted = 1 Then
			ExecutionParameters.SaveDecrypted = True;
		Else
			ExecutionParameters.SaveDecrypted = False;
		EndIf;
		
	ElsIf Result <> -1 Then
		ReturnResult(ExecutionParameters.ResultHandler, "");
		Return;
	EndIf;
	
	FillTemporaryFormID(ExecutionParameters.UUID, ExecutionParameters);
	
	Handler = New NotifyDescription("SaveAsWithoutExtensionCompletion", ThisObject, ExecutionParameters);
	OpenFileWithoutExtension(Handler, ExecutionParameters.FileData, ExecutionParameters.UUID,
		False, ExecutionParameters.SaveDecrypted, ExecutionParameters.EncryptedFilesExtension);
	
EndProcedure

// Continuation of the procedure (see above).
Procedure SaveAsWithoutExtensionCompletion(Result, ExecutionParameters) Export
	
	ClearTemporaryFormID(ExecutionParameters);
	
	If Result <> True Then
		Return;
	EndIf;
	
	If Not ExecutionParameters.SaveDecrypted
	   AND ExecutionParameters.FileData.Encrypted
	   AND ValueIsFilled(ExecutionParameters.EncryptedFilesExtension) Then
		
		Extension = ExecutionParameters.EncryptedFilesExtension;
	Else
		Extension = ExecutionParameters.FileData.Extension;
	EndIf;
	
	FileName = CommonClientServer.GetNameWithExtension(
		ExecutionParameters.FileData.FullVersionDescription, Extension);
	
	ReturnResult(ExecutionParameters.ResultHandler, New Structure("FullFileName", FileName));
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Shows a reminder before placing a file if it is set up.

// It will show a reminder if it is set up.
//
// Parameters:
//   ResultHandler - NotifyDescription, Undefined - description of the procedure that gets the method result.
//
Procedure ShowReminderBeforePutFile(ResultHandler)
	
	PersonalSettings = PersonalFilesOperationsSettings();
	If PersonalSettings.ShowTooltipsOnEditFiles = True Then
		If Not FileSystemExtensionAttached() Then
			ReminderText = 
				NStr("ru = 'Сейчас будет предложено выбрать файл для того,
				|чтобы поместить его в программу и закончить редактирование.
				|
				|Найдите нужный файл в том каталоге, который был
				|указан ранее при начале редактирования.'; 
				|en = 'You will be prompted to select a file
				|to commit.
				|
				|Please select the file from the directory
				|that you specified when you started editing the file.'; 
				|pl = 'Zostaniesz poproszony o wybranie pliku dla,
				|umieszczenia go w programie i zakończenia edycji.
				|
				|Znajdź plik w katalogu, który był
				|podany wcześniej na początku edycji.';
				|de = 'Sie werden aufgefordert, eine Datei
				|auszuwählen, um sie in die Anwendung zu übernehmen und die Bearbeitung abzuschließen.
				|
				|Suchen Sie die Datei in dem Verzeichnis, das
				|zuvor beim Start der Bearbeitung angegeben wurde.';
				|ro = 'Vi se va solicita să selectați un fișier
				|pentru a-l adăuga în aplicație și să terminați editarea.
				|
				|Găsiți fișierul din directorul
				|specificat anterior la începutul editării.';
				|tr = 'Şimdi uygulamaya koymak
				|ve düzenlemeyi tamamlamak için bir dosya seçin.
				|
				|Düzenlemenin başında belirttiğiniz
				|katalogda gerekli dosyayı bulun.'; 
				|es_ES = 'Ahora se ofrecerá seleccionar un archivo
				|para colocarlo en el programa y finalizar la edición.
				|
				|Encuentre el archivo necesario en el catálogo que ha sido
				|indicado anteriormente al empezar a editar.'");
				
			Buttons = New ValueList;
			Buttons.Add("Continue", NStr("ru = 'Продолжить'; en = 'Continue'; pl = 'Kontynuuj';de = 'Weiter';ro = 'Continuare';tr = 'Devam'; es_ES = 'Continuar'"));
			Buttons.Add("Cancel", NStr("ru = 'Отмена'; en = 'Cancel'; pl = 'Anuluj';de = 'Abbrechen';ro = 'Revocare';tr = 'İptal'; es_ES = 'Cancelar'"));
			ReminderParameters = New Structure;
			ReminderParameters.Insert("Picture", PictureLib.Information32);
			ReminderParameters.Insert("CheckBoxText",
				NStr("ru = 'Больше не показывать это сообщение'; en = 'Do not show this message again'; pl = 'Nie pokazuj ponownie tej wiadomości';de = 'Diese Nachricht nicht wieder anzeigen';ro = 'Nu mai afișa acest mesaj';tr = 'Bu mesajı tekrar gösterme'; es_ES = 'No mostrar este mensaje más'"));
			ReminderParameters.Insert("Title",
				NStr("ru = 'Помещение файла'; en = 'Store file'; pl = 'Umieszczenie pliku';de = 'Ablegen der Datei';ro = 'Plasarea fișierului';tr = 'Dosya yerleştirme'; es_ES = 'Ubicación del archivo'"));
			StandardSubsystemsClient.ShowQuestionToUser(
				ResultHandler, ReminderText, Buttons, ReminderParameters);
			Return;
		EndIf;
	EndIf;
	ReturnResult(ResultHandler, True);
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Checks size of files.

// Check File Size Limit - returns False if there are files that exceed the size limit, and the user 
//   has selected "Cancel" in the warning dialog box about the presence of such files.
//
// Parameters:
//  ResultHandler - NotifyDescription, Undefined - description of the procedure that gets the method result.
//  CheckParameters - Structure - with the following properties:
//    * SelectedFiles - Array - an array of "File" objects.
//    * Recursively - Boolean - pass subdirectories recursively.
//    * PseudoFileSystem - Map - file system emulation, returns an array of strings (subdirectories 
//                                             and files) for a string (directory).
//
// Returns:
//   Structure - result:
//       * Success               - Boolean - shows whether the operation is performed successfully.
//       * CountTotal - Number  - a number of imported files.
//
Procedure CheckMaxFilesSize(ResultHandler, CheckParameters)
	
	ExecutionParameters = New Structure;
	ExecutionParameters.Insert("ResultHandler", ResultHandler);
	ExecutionParameters.Insert("TotalCount", 0);
	ExecutionParameters.Insert("Success", False);
	
	ArrayOfTooBigFiles = New Array;
	
	Path = "";
	
	FilesArray = New Array;
	
	For Each FileName In CheckParameters.SelectedFiles Do
		
		Path = FileName.Value;
		SelectedFile = New File(Path);
		
		SelectedFile = New File(FileName.Value);
		DirectorySelected = False;
		
		If SelectedFile.Exist() Then
			DirectorySelected = SelectedFile.IsDirectory();
		EndIf;
		
		If DirectorySelected Then
			FilesArrayOfThisDirectory = FindFilesPseudo(CheckParameters.PseudoFileSystem, Path);
			FindTooBigFiles(FilesArrayOfThisDirectory, ArrayOfTooBigFiles, CheckParameters.Recursively, 
				ExecutionParameters.TotalCount, CheckParameters.PseudoFileSystem);
		Else
			FilesArray.Add(SelectedFile);
		EndIf;
	EndDo;
	
	If FilesArray.Count() <> 0 Then
		FindTooBigFiles(FilesArray, ArrayOfTooBigFiles, CheckParameters.Recursively, 
			ExecutionParameters.TotalCount, CheckParameters.PseudoFileSystem);
	EndIf;
	
	// There was at least one file that was too big.
	If ArrayOfTooBigFiles.Count() <> 0 Then 
		TooBigFiles = New ValueList;
		Parameters = New Structure;
		
		For Each File In ArrayOfTooBigFiles Do
			BigFile = New File(File);
			FileSizeInMB = Int(BigFile.Size() / (1024 * 1024));
			StringText = StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = '%1 (%2 МБ)'; en = '%1 (%2 MB)'; pl = '%1 (%2 MB)';de = '%1 (%2 MB)';ro = '%1 (%2 MB)';tr = '%1(%2MB)'; es_ES = '%1 (%2 MB)'"), String(File), String(FileSizeInMB));
			TooBigFiles.Add(StringText);
		EndDo;
		
		Parameters.Insert("TooBigFiles", TooBigFiles);
		Parameters.Insert("Title", NStr("ru = 'Предупреждение при загрузке файлов'; en = 'File upload warning'; pl = 'Ostrzeżenie przy imporcie plików';de = 'Datei- Import Warnung';ro = 'Avertisment la importul fișierelor';tr = 'Dosya içe aktarma uyarısı'; es_ES = 'Aviso de la importación del archivo'"));
		
		Handler = New NotifyDescription("CheckFileSizeLimitAfterRespondQuestion", ThisObject, ExecutionParameters);
		OpenForm("DataProcessor.FilesOperations.Form.QuestionOnFileImport", Parameters, , , , , Handler, FormWindowOpeningMode.LockWholeInterface);
		Return;
	EndIf;
	
	ExecutionParameters.Success = True;
	ReturnResult(ExecutionParameters.ResultHandler, ExecutionParameters);
	
EndProcedure

// Continuation of the procedure (see above).
Procedure CheckFileSizeLimitAfterRespondQuestion(Response, ExecutionParameters) Export
	
	ExecutionParameters.Success = (Response = DialogReturnCode.OK);
	ReturnResult(ExecutionParameters.ResultHandler, ExecutionParameters);
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Shows that the file has not been modified.

// It will show a reminder if it is set up.
//
// Parameters:
//   ResultHandler - NotifyDescription, Undefined - description of the procedure that gets the method result.
//
Procedure ShowInformationFileWasNotModified(ResultHandler)
	
	PersonalSettings = PersonalFilesOperationsSettings();
	If PersonalSettings.ShowFileNotModifiedFlag Then
		ReminderText = NStr("ru = 'Версия не была создана, т.к. файл не изменен. Комментарий не сохранен.'; en = 'Cannot create a version as the file is not changed. The comment is discarded.'; pl = 'Wersja nie została utworzona, ponieważ plik nie został zmieniony. Komentarz nie został zapisany.';de = 'Die Version wurde nicht erstellt, da die Datei nicht geändert wurde. Der Kommentar wird nicht gespeichert.';ro = 'Versiunea nu a fost creată deoarece fișierul nu a fost modificat. Comentariul nu este salvat.';tr = 'Dosya değişmediğinden sürüm oluşturulmadı. Yorum kaydedilmedi.'; es_ES = 'Versión no se ha creado, porque el archivo no se ha cambiado. El comentario no se ha guardado.'");
		Buttons = QuestionDialogMode.OK;
		ReminderParameters = New Structure;
		ReminderParameters.Insert("LockWholeInterface", True);
		ReminderParameters.Insert("Picture", PictureLib.Information32);
		ReminderParameters.Insert("CheckBoxText",
			NStr("ru = 'Больше не показывать это сообщение'; en = 'Do not show this message again'; pl = 'Nie pokazuj ponownie tej wiadomości';de = 'Diese Nachricht nicht wieder anzeigen';ro = 'Nu mai afișa acest mesaj';tr = 'Bu mesajı tekrar gösterme'; es_ES = 'No mostrar este mensaje más'"));
		ReminderParameters.Insert("Title",
			NStr("ru = 'Информация'; en = 'Information'; pl = 'Informacyjny';de = 'Information';ro = 'Informație';tr = 'Bilgi'; es_ES = 'Información'"));
		StandardSubsystemsClient.ShowQuestionToUser(
			ResultHandler, ReminderText, Buttons, ReminderParameters);
	Else
		ReturnResult(ResultHandler, Undefined);
	EndIf;
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Imports the edited file into the application, removes the lock and sends a notification.

// Continuation of the procedure (see above).
Procedure FinishEditWithNotificationCompletion(Result, ExecutionParameters) Export
	
	If Result = True Then
		Notify("Write_File", New Structure("Event", "EditFinished"), ExecutionParameters.CommandParameter);
		NotifyChanged(ExecutionParameters.CommandParameter);
		Notify("Write_File", New Structure("Event", "FileDataChanged"), ExecutionParameters.CommandParameter);
		Notify("Write_File", New Structure("Event", "VersionSaved"), ExecutionParameters.CommandParameter);
		LockedFilesCount = StandardSubsystemsClient.ClientParameter("LockedFilesCount");
		StandardSubsystemsClient.SetClientParameter("LockedFilesCount", LockedFilesCount - 1);
	EndIf;
	
	ReturnResult(ExecutionParameters.ResultHandler, Result);
	
EndProcedure

// Saves edited files to the infobase and removes the lock.
//
// Parameters:
//   Parameters - Structure - see FileUpdateParameters. 
//
Procedure FinishEditByRefsWithNotification(Parameters) Export
	
	If TypeOf(Parameters.FilesArray) <> Type("Array") Then
		ReturnResult(Parameters.ResultHandler, Undefined);
		Return;
	EndIf;
	
	Handler = New NotifyDescription("FinishEditByRefsAfterInstallExtension", ThisObject, Parameters);
	ShowFileSystemExtensionInstallationQuestion(Handler);
	
EndProcedure

// Continuation of the procedure (see above).
Procedure FinishEditByRefsAfterInstallExtension(ExtensionInstalled, ExecutionParameters) Export
	
	ExecutionParameters.Insert("FilesData", New Array);
	FilesOperationsInternalServerCall.GetDataForFilesArray(ExecutionParameters.FilesArray, ExecutionParameters.FilesData);
	
	// Finish editing files.
	For Each FileData In ExecutionParameters.FilesData Do
		
		HandlerParameters = FileUpdateParameters(
		Undefined,
		FileData.Ref,
		ExecutionParameters.FormID);
		FillPropertyValues(HandlerParameters, ExecutionParameters);
		HandlerParameters.Insert("FileData", Undefined);
		HandlerParameters.StoreVersions = FileData.StoreVersions;
		HandlerParameters.CurrentUserEditsFile = FileData.CurrentUserEditsFile;
		HandlerParameters.BeingEditedBy = FileData.BeingEditedBy;
		HandlerParameters.CurrentVersionAuthor = FileData.BeingEditedBy;
		HandlerParameters.Encoding = FileData.CurrentVersionEncoding;
		HandlerParameters.Insert("DeleteFileFromLocalFileCacheOnCompleteEdit2", ExecutionParameters.DeleteFileFromLocalFileCacheOnCompleteEdit2);
		If ExecutionParameters.CanCreateFileVersions Then
			HandlerParameters.CreateNewVersion = ExecutionParameters.StoreVersions;
		Else
			HandlerParameters.CreateNewVersion = False;
		EndIf;
		HandlerParameters.ApplyToAll = True;
		
		If ExtensionInstalled Then
			FinishEditWithExtension(HandlerParameters);
		Else
			FinishEditWithoutExtension(HandlerParameters);
		EndIf;
	EndDo;
	
	ShowUserNotification(
	NStr("ru = 'Завершить редактирование файлов'; en = 'Commit files'; pl = 'Zakończyć edycję plików';de = 'Beenden der Dateibearbeitung';ro = 'Finalizare editarea fișierelor';tr = 'Dosya düzenlemeyi bitir'; es_ES = 'Finalizar edición de archivos'"),,
	StringFunctionsClientServer.SubstituteParametersToString(
	NStr("ru = 'Завершено редактирование файлов (%1 из %2).'; en = 'Commit files (%1 of %2).'; pl = 'Zakończona edycja plików (%1 z %2).';de = 'Die Bearbeitung der Dateien (%1 von %2) ist abgeschlossen.';ro = 'Editarea fișierelor este finalizată (%1 din %2).';tr = 'Dosya düzenlemesi tamamlandı (%1''in %2).'; es_ES = 'Finalizar edición de archivos (%1 de %2).'"),
	ExecutionParameters.FilesData.Count(),
	ExecutionParameters.FilesArray.Count()),
	PictureLib.Information32);
	
	ResultHandler = New NotifyDescription("FinishEditFilesArrayWithNotificationCompletion", ThisObject, ExecutionParameters);
	ReturnResult(ResultHandler, True);

EndProcedure

Procedure FinishEditFilesArrayWithNotificationCompletion(Result, ExecutionParameters) Export
	
	If Result = True Then
		For Each FileRef In ExecutionParameters.FilesArray Do
			Notify("Write_File", New Structure("Event", "EditFinished"), FileRef);
			NotifyChanged(FileRef);
			Notify("Write_File", New Structure("Event", "FileDataChanged"), FileRef);
			Notify("Write_File", New Structure("Event", "VersionSaved"), FileRef);
			LockedFilesCount = StandardSubsystemsClient.ClientParameter("LockedFilesCount");
			StandardSubsystemsClient.SetClientParameter("LockedFilesCount", LockedFilesCount - 1);
		EndDo;
	EndIf;
	
EndProcedure

// Adds files to the list by dragging.
//
// Parameters:
//  FileOwner      - Reference - file owner.
//  FormID - a form UUID.
//  FilesNamesArray   - a Row Array of paths to files.
//
Procedure AddFilesWithDrag(Val FileOwner, Val FormID, Val FileNamesArray) Export
	
	AttachedFilesArray = New Array;
	PutSelectedFilesInStorage(
		FileNamesArray,
		FileOwner,
		AttachedFilesArray,
		FormID);
	
	If AttachedFilesArray.Count() = 1 Then
		AttachedFile = AttachedFilesArray[0];
		
		ShowUserNotification(
			NStr("ru = 'Создание'; en = 'Create'; pl = 'Tworzenie';de = 'Erstellung';ro = 'Creare';tr = 'Oluştur'; es_ES = 'Crear'"),
			GetURL(AttachedFile),
			AttachedFile,
			PictureLib.Information32);
		
		FormParameters = New Structure("AttachedFile, IsNew", AttachedFile, True);
		OpenForm("DataProcessor.FilesOperations.Form.AttachedFile", FormParameters, , AttachedFile);
	EndIf;
	
	If AttachedFilesArray.Count() > 0 Then
		NotifyChanged(AttachedFilesArray[0]);
		NotifyChanged(FileOwner);
		Notify("Write_File", 
			New Structure("IsNew, FileOwner", True, FileOwner), AttachedFilesArray);
	EndIf;
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Captures a file, opens a dialog box for editing and sends notifications.

// Locks a file for editing and opens it.
Procedure EditWithNotification(
	ResultHandler,
	ObjectRef,
	UUID = Undefined,
	OwnerWorkingDirectory = Undefined) Export
	
	If ObjectRef = Undefined Then
		ReturnResult(ResultHandler, Undefined);
		Return;
	EndIf;
	
	ExecutionParameters = New Structure;
	ExecutionParameters.Insert("ResultHandler", ResultHandler);
	ExecutionParameters.Insert("ObjectRef", ObjectRef);
	Handler = New NotifyDescription("EditWithNotificationCompletion", ThisObject, ExecutionParameters);
	EditFileByRef(Handler, ObjectRef, UUID, OwnerWorkingDirectory);
	
EndProcedure

// Continuation of the procedure (see above).
Procedure EditWithNotificationCompletion(FileEdited, ExecutionParameters) Export
	
	If FileEdited Then
		NotifyChanged(ExecutionParameters.ObjectRef);
		Notify("Write_File", New Structure("Event", "FileDataChanged"), ExecutionParameters.ObjectRef);
		Notify("Write_File", New Structure("Event", "FileWasEdited"), ExecutionParameters.ObjectRef);
		LockedFilesCount = StandardSubsystemsClient.ClientParameter("LockedFilesCount");
		StandardSubsystemsClient.SetClientParameter("LockedFilesCount", LockedFilesCount + 1);
	EndIf;
	
	ReturnResult(ExecutionParameters.ResultHandler, Undefined);
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Captures a file or several files and sends a message.

// Locks a file or several files.
//
// Parameters:
//   ResultHandler - NotifyDescription, Undefined - description of the procedure that gets the method result.
//   CommandParameter - either a reference to file or an array of references to files.
//   UUID.
//
Procedure LockWithNotification(ResultHandler, CommandParameter, UUID = Undefined) Export
	
	If CommandParameter = Undefined Then
		ReturnResult(ResultHandler, Undefined);
		Return;
	EndIf;
	
	ExecutionParameters = New Structure;
	ExecutionParameters.Insert("ResultHandler", ResultHandler);
	ExecutionParameters.Insert("CommandParameter", CommandParameter);
	If TypeOf(CommandParameter) = Type("Array") Then
		Handler = New NotifyDescription("LockWithNotificationFilesArrayCompletion", ThisObject, ExecutionParameters);
		LockFilesByRefs(Handler, CommandParameter);
	Else
		Handler = New NotifyDescription("LockWIthNotificationOneFileCompletion", ThisObject, ExecutionParameters);
		LockFileByRef(Handler, CommandParameter, UUID)
	EndIf;
	
EndProcedure

// Continuation of the procedure (see above).
Procedure LockWithNotificationFilesArrayCompletion(Result, ExecutionParameters) Export
	
	NotifyChanged(Type("CatalogRef.Files"));
	For Each FileRef In ExecutionParameters.CommandParameter Do
		Notify("Write_File", New Structure("Event", "FileDataChanged"), FileRef);
		NotifyChanged(FileRef);
	EndDo;
	ReturnResult(ExecutionParameters.ResultHandler, Undefined);
	
EndProcedure

// Continuation of the procedure (see above).
Procedure LockWIthNotificationOneFileCompletion(Result, ExecutionParameters) Export
	
	If Result = True Then
		NotifyChanged(ExecutionParameters.CommandParameter);
		Notify("Write_File", New Structure("Event", "FileDataChanged"), ExecutionParameters.CommandParameter);
	EndIf;
	
	ReturnResult(ExecutionParameters.ResultHandler, Undefined);
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Unlocks a file and sends a notification.

// Unlocks a file locked earlier.
//
// Parameters:
//   Parameters - Structure - see FileUnlockParameters. 
//
Procedure UnlockFileWithNotification(Parameters) Export
	
	If Parameters.ObjectRef = Undefined Then
		ReturnResult(Parameters.ResultHandler, Undefined);
		Return;
	EndIf;
	
	ExecutionParameters = New Structure;
	ExecutionParameters.Insert("ResultHandler", Parameters.ResultHandler);
	ExecutionParameters.Insert("CommandParameter", Parameters.ObjectRef);
	If TypeOf(Parameters.ObjectRef) = Type("Array") Then
		Handler = New NotifyDescription("UnlockFileWithNotificationFilesArrayCompletion", ThisObject, ExecutionParameters);
		UnlockFilesByRefs(Handler, Parameters.ObjectRef);
	Else
		Handler = New NotifyDescription("UnlockFileWithNotificationOneFileCompletion", ThisObject, ExecutionParameters);
		Parameters = FileUnlockParameters(Handler, Parameters.ObjectRef);
		Parameters.StoreVersions = Parameters.StoreVersions;
		Parameters.CurrentUserEditsFile = Parameters.CurrentUserEditsFile;
		Parameters.BeingEditedBy = Parameters.BeingEditedBy;
		Parameters.UUID = Parameters.UUID;
		UnlockFile(Parameters);
	EndIf;
	
EndProcedure

// Continuation of the procedure (see above).
Procedure UnlockFileWithNotificationFilesArrayCompletion(Result, ExecutionParameters) Export
	
	NotifyChanged(Type("CatalogRef.Files"));
	For Each FileRef In ExecutionParameters.CommandParameter Do
		Notify("Write_File", New Structure("Event", "FileDataChanged"), FileRef);
	EndDo;
	ReturnResult(ExecutionParameters.ResultHandler, Undefined);
	
EndProcedure

// Continuation of the procedure (see above).
Procedure UnlockFileWithNotificationOneFileCompletion(Result, ExecutionParameters) Export
	
	If Result = True Then
		NotifyChanged(ExecutionParameters.CommandParameter);
		Notify("Write_File", New Structure("Event", "FileDataChanged"), ExecutionParameters.CommandParameter);
		LockedFilesCount = StandardSubsystemsClient.ClientParameter("LockedFilesCount");
		StandardSubsystemsClient.SetClientParameter("LockedFilesCount", LockedFilesCount - 1);
	EndIf;
	
	ReturnResult(ExecutionParameters.ResultHandler, Undefined);
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Opens a file and sends a notification.

// Opens a file.
//
// Parameters:
//   ResultHandler - NotifyDescription, Undefined - description of the procedure that gets the method result.
//   FileData             - a structure with file data.
//   UUID - UUID - forms.
//
Procedure OpenFileWithNotification(ResultHandler, FileData, UUID = Undefined, ForEditing = True) Export
	
	ExecutionParameters = New Structure;
	ExecutionParameters.Insert("ResultHandler", ResultHandler);
	ExecutionParameters.Insert("FileData", FileData);
	ExecutionParameters.Insert("ForEditing", ForEditing);
	ExecutionParameters.Insert("UUID", UUID);
	
	// The file does not contain the owner, just open it by reference from the temporary storage.
	If NOT ExecutionParameters.FileData.Property("Owner") Or Not ValueIsFilled(ExecutionParameters.FileData.Owner) Then
		NotifyDescription = New NotifyDescription("OpenFileAddInSuggested", FilesOperationsInternalClient, ExecutionParameters);
		ShowFileSystemExtensionInstallationQuestion(NotifyDescription);
		Return;
	EndIf;
	
	// If File does not have a file, open the card.
	If ExecutionParameters.FileData.Version.IsEmpty() AND ExecutionParameters.FileData.StoreVersions Then
		Handler = New NotifyDescription("OpenFileWIthNotificationCompletion", ThisObject, ExecutionParameters);
		ShowValue(Handler, ExecutionParameters.FileData.Ref);
		Return;
	EndIf;
	
	Handler = New NotifyDescription("OpenFileWithNotificationAfterInstallExtension", ThisObject, ExecutionParameters);
	ShowFileSystemExtensionInstallationQuestion(Handler);
	
EndProcedure

// Continuation of the procedure (see above).
Procedure OpenFileWithNotificationAfterInstallExtension(ExtensionInstalled, ExecutionParameters) Export
	
	If FileSystemExtensionAttached() Then
		Handler = New NotifyDescription("OpenFileWithNotificationWithExtensionAfterGetVersionToWorkingDirectory", ThisObject, ExecutionParameters);
		GetVersionFileToWorkingDirectory(
			Handler,
			ExecutionParameters.FileData,
			"",
			ExecutionParameters.UUID,
			New Structure("OpenFile", True));
	Else
		FillTemporaryFormID(ExecutionParameters.UUID, ExecutionParameters);
		
		Handler = New NotifyDescription("OpenFileWIthNotificationCompletion", ThisObject, ExecutionParameters);
		OpenFileWithoutExtension(Handler, ExecutionParameters.FileData, ExecutionParameters.UUID);
	EndIf;
	
EndProcedure

// Continuation of the procedure (see above).
Procedure OpenFileWithNotificationWithExtensionAfterGetVersionToWorkingDirectory(Result, ExecutionParameters) Export
	
	If Result.FileReceived = True Then
		FileOnHardDrive = New File(Result.FullFileName);
		FileOnHardDrive.SetReadOnly(Not ExecutionParameters.ForEditing);
		UUID = ?(ExecutionParameters.Property("UUID"),
			ExecutionParameters.UUID, Undefined);
		OpenFileWithApplication(ExecutionParameters.FileData, Result.FullFileName, UUID);
	EndIf;
	
	OpenFileWIthNotificationCompletion(Result.FileReceived = True, ExecutionParameters);
	
EndProcedure

// Continuation of the procedure (see above).
Procedure OpenFileWIthNotificationCompletion(Result, ExecutionParameters) Export
	
	ClearTemporaryFormID(ExecutionParameters);
	
	If Result <> True Then
		Return;
	EndIf;
	
	NotificationParameters = New Structure;
	NotificationParameters.Insert("Event", "FileOpened");
	Notify("FileOpened", NotificationParameters, ExecutionParameters.FileData.Ref);
	
EndProcedure


Procedure OpenFileWithoutExtension(Notification, FileData, FormID,
		WithNotification = True, SaveDecrypted = True, EncryptedFilesExtension = "")
	
	Context = New Structure;
	Context.Insert("Notification",             Notification);
	Context.Insert("FileData",            FileData);
	Context.Insert("FormID",     FormID);
	Context.Insert("WithNotification",       WithNotification);
	Context.Insert("SaveDecrypted", SaveDecrypted);
	Context.Insert("EncryptedFilesExtension", EncryptedFilesExtension);
	
	If Context.SaveDecrypted
		AND FileData.Encrypted Then
		
		If Not CommonClient.SubsystemExists("StandardSubsystems.DigitalSignature") Then
			ExecuteNotifyProcessing(Context.Notification, False);
			Return;
		EndIf;
		
		ReturnStructure = FilesOperationsInternalServerCall.FileDataAndBinaryData(
			FileData.Version,, FormID);
		
		DataDetails = New Structure;
		DataDetails.Insert("Operation",              NStr("ru = 'Расшифровка файла'; en = 'Decrypt file'; pl = 'Deszyfrowanie plików';de = 'Dateientschlüsselung';ro = 'Decriptarea fișierului';tr = 'Dosya şifresini çözme'; es_ES = 'Descodificación del archivo'"));
		DataDetails.Insert("DataTitle",       NStr("ru = 'Файл'; en = 'File'; pl = 'Plik';de = 'Datei';ro = 'Fișier';tr = 'Dosya'; es_ES = 'Archivo'"));
		DataDetails.Insert("Data",                ReturnStructure.BinaryData);
		DataDetails.Insert("Presentation",         FileData.Ref);
		DataDetails.Insert("EncryptionCertificates", FileData.Ref);
		DataDetails.Insert("NotifyOnCompletion",   False);
		
		FollowUpHandler = New NotifyDescription(
			"OpenFileWithoutExtensionAfterDecryption", ThisObject, Context);
		
		ModuleDigitalSignatureClient = CommonClient.CommonModule("DigitalSignatureClient");
		ModuleDigitalSignatureClient.Decrypt(DataDetails, , FollowUpHandler);
		Return;
		
	EndIf;
	
	Context.Insert("FileAddress", FileData.BinaryFileDataRef);
	
	OpenFileWithoutExtensionReminder(Context);
	
EndProcedure

// Continuation of the procedure (see above).
Procedure OpenFileWithoutExtensionAfterDecryption(DataDetails, Context) Export
	
	If Not DataDetails.Success Then
		ExecuteNotifyProcessing(Context.Notification, False);
		Return;
	EndIf;
	
	If TypeOf(DataDetails.DecryptedData) = Type("BinaryData") Then
		FileAddress = PutToTempStorage(DataDetails.DecryptedData,
			Context.FormID);
	Else
		FileAddress = DataDetails.DecryptedData;
	EndIf;
	
	Context.Insert("FileAddress", FileAddress);
	
	OpenFileWithoutExtensionReminder(Context);
	
EndProcedure

// Continuation of the procedure (see above).
Procedure OpenFileWithoutExtensionReminder(Context)
	
	If Context.WithNotification
		AND Context.FileData.CurrentUserEditsFile Then
		
		OutputNotificationOnEdit(New NotifyDescription(
		"OpenFileWithoutExtensionFileSending", ThisObject, Context));
	Else
		OpenFileWithoutExtensionFileSending(True, Context);
	EndIf;
	
EndProcedure

// Continuation of the procedure (see above).
Procedure OpenFileWithoutExtensionFileSending(Result, Context) Export
	
	If (TypeOf(Result) = Type("Structure") AND Result.Value = "Cancel") Or Result = Undefined Then
		Return;
	EndIf;
	
	If TypeOf(Result) = Type("Structure") AND Result.Property("DoNotAskAgain") AND Result.DoNotAskAgain Then
		FilesOperationsInternalServerCall.ShowTooltipsOnEditFiles(False);
	EndIf;
	
	If Not Context.SaveDecrypted
		AND Context.FileData.Encrypted
		AND ValueIsFilled(Context.EncryptedFilesExtension) Then
		
		Extension = Context.EncryptedFilesExtension;
	Else
		Extension = Context.FileData.Extension;
	EndIf;
	
	FileName = CommonClientServer.GetNameWithExtension(
		Context.FileData.FullVersionDescription, Extension);
	
	GetFile(Context.FileAddress, FileName, True);
	
	ExecuteNotifyProcessing(Context.Notification, True);
	
EndProcedure

// Fills in a temporary form ID for cases when it is not necessary to return data in temporary 
// storage to the calling code, for example, as in the Open and OpenFileDirectory procedures in the 
// FilesOperationsClient common module.
//
Procedure FillTemporaryFormID(FormID, ExecutionParameters)
	
	If ValueIsFilled(FormID) Then
		Return;
	EndIf;
	
	ExecutionParameters.Insert("TempForm", GetForm("DataProcessor.FilesOperations.Form.QuestionForm"));
	FormID = ExecutionParameters.TempForm.UUID;
	StandardSubsystemsClient.SetFormStorageOption(ExecutionParameters.TempForm, True);
	
EndProcedure

// Cancels the storage of the temporary ID, filled earlier.
Procedure ClearTemporaryFormID(ExecutionParameters)
	
	If ExecutionParameters.Property("TempForm") Then
		StandardSubsystemsClient.SetFormStorageOption(ExecutionParameters.TempForm, False);
	EndIf;
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Imports file to the application and sends a message.

// Saves the file to the infobase but does not unlock it.
Procedure SaveFileChangesWithNotification(ResultHandler, CommandParameter, FormID) Export
	
	If CommandParameter = Undefined Then
		ReturnResult(ResultHandler, Undefined);
		Return;
	EndIf;
	
	ExecutionParameters = New Structure;
	ExecutionParameters.Insert("ResultHandler", ResultHandler);
	ExecutionParameters.Insert("CommandParameter", CommandParameter);
	
	Handler = New NotifyDescription("SaveFileChangesWithNotificationCompletion", ThisObject, ExecutionParameters);
	HandlerParameters = FileUpdateParameters(Handler, CommandParameter, FormID);
	SaveFileChanges(HandlerParameters);
	
EndProcedure

// Continuation of the procedure (see above).
Procedure SaveFileChangesWithNotificationCompletion(Result, ExecutionParameters) Export
	
	If Result = True Then
		Notify("Write_File", New Structure("Event", "FileDataChanged"), ExecutionParameters.CommandParameter);
		Notify("Write_File", New Structure("Event", "VersionSaved"), ExecutionParameters.CommandParameter);
	EndIf;
	
	ReturnResult(ExecutionParameters.ResultHandler, Undefined);
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Shows the file selection dialog box on the hard drive, imports the selected file into the application as a version and sends a notification.

// Selects a file on the hard drive and creates a new version from it.
Procedure UpdateFromFileOnHardDriveWithNotification(
	ResultHandler,
	FileData,
	FormID,
	FileAddingOptions = Undefined) Export
	
	If Not FileSystemExtensionAttached() Then
		ShowFileSystemExtensionRequiredMessageBox(ResultHandler);
		Return;
	EndIf;
	
	ExecutionParameters = New Structure;
	ExecutionParameters.Insert("ResultHandler", ResultHandler);
	ExecutionParameters.Insert("FileData", FileData);
	Handler = New NotifyDescription("UpdateFromFileOnHardDriveWithNotificationCompletion", ThisObject, ExecutionParameters);
	UpdateFromFileOnHardDrive(Handler, FileData, FormID, FileAddingOptions);
	
EndProcedure

// Continuation of the procedure (see above).
Procedure UpdateFromFileOnHardDriveWithNotificationCompletion(Result, ExecutionParameters) Export
	
	If Result = True Then
		NotifyChanged(ExecutionParameters.FileData.Ref);
		Notify("Write_File", New Structure("Event", "FileDataChanged"), ExecutionParameters.FileData.Ref);
		Notify("Write_File", New Structure("Event", "VersionSaved"), ExecutionParameters.FileData.Ref);
	EndIf;
	
	ReturnResult(ExecutionParameters.ResultHandler, Undefined);
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Encrypting files.

// Encrypt file.
//
// Parameters:
//  ResultHandler - NotifyDescription, Undefined - description of the procedure that gets the method result.
//  FileData - a structure with file data.
//  UUID - the form UUID.
//
// Returns:
//   Structure - result.
//       * Success - Boolean - shows whether the operation is performed successfully.
//       * DataArrayToStroeInDatabase - Array - an array of data to write to the application.
//       * ThumbprintsArray - Array - an array of thumbprints.
//
Procedure Encrypt(ResultHandler, FileData, UUID) Export
	
	ExecutionParameters = New Structure;
	ExecutionParameters.Insert("ResultHandler", ResultHandler);
	ExecutionParameters.Insert("FileData", FileData);
	ExecutionParameters.Insert("UUID", UUID);
	ExecutionParameters.Insert("Success", False);
	ExecutionParameters.Insert("DataArrayToStoreInDatabase", New Array);
	ExecutionParameters.Insert("ThumbprintsArray", New Array);
	
	If ExecutionParameters.FileData.Encrypted Then
		WarningText = NStr("ru = 'Файл ""%1"" уже зашифрован.'; en = 'File ""%1"" is already encrypted.'; pl = 'Plik ""%1"" jest już zaszyfrowany.';de = 'Die Datei ""%1"" ist bereits verschlüsselt.';ro = 'Fișierul ""%1"" este deja criptat.';tr = '""%1"" Dosyası zaten şifrelenmiş.'; es_ES = 'Archivo ""%1"" ya está codificado.'");
		WarningText = StrReplace(WarningText, "%1", String(ExecutionParameters.FileData.Ref));
		ReturnResultAfterShowWarning(ExecutionParameters.ResultHandler, WarningText, ExecutionParameters);
		Return;
	EndIf;
	
	If ValueIsFilled(ExecutionParameters.FileData.BeingEditedBy) Then
		WarningText = NStr("ru = 'Нельзя зашифровать занятый файл.'; en = 'Cannot encrypt the file because it is locked.'; pl = 'Nie można zaszyfrować zajętego pliku.';de = 'Verschlüsselte Datei kann nicht verschlüsselt werden.';ro = 'Nu se poate cripta fișierul blocat.';tr = 'Kilitli dosya şifrelenemiyor.'; es_ES = 'No se puede cifrar un archivo bloqueado.'");
		ReturnResultAfterShowWarning(ExecutionParameters.ResultHandler, WarningText, ExecutionParameters);
		Return;
	EndIf;
	
	If Not CommonClient.SubsystemExists("StandardSubsystems.DigitalSignature") Then
		Return;
	EndIf;
	
	// SuggestFileSystemExtensionInstallationNow() is not required, because everything is done in the memory via BinaryData
	
	VersionsArray = FilesOperationsInternalServerCall.FileDataAndURLOfAllFileVersions(ExecutionParameters.FileData.Ref,
		ExecutionParameters.UUID);
	
	If VersionsArray.Count() = 0 Then
		ReturnResult(ExecutionParameters.ResultHandler, False);
		Return;
	EndIf;
	
	ExecutionParameters.DataArrayToStoreInDatabase = New Array;
	
	FilePresentation = String(ExecutionParameters.FileData.Ref);
	If ExecutionParameters.FileData.VersionsCount > 1 Then
		FilePresentation = FilePresentation + " (" + StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Версий: %1'; en = 'Versions: %1'; pl = 'Wersje: %1';de = 'Versionen: %1';ro = 'Versiuni: %1';tr = 'Sürümler:%1'; es_ES = 'Versiones: %1'"), ExecutionParameters.FileData.VersionsCount) + ")";
	EndIf;
	PresentationsList = New ValueList;
	PresentationsList.Add(ExecutionParameters.FileData.Ref, FilePresentation);
	
	DataSet = New Array;
	
	For each VersionProperties In VersionsArray Do
		
		CurrentExecutionParameters = New Structure;
		CurrentExecutionParameters.Insert("ExecutionParameters", ExecutionParameters);
		CurrentExecutionParameters.Insert("VersionRef", VersionProperties.VersionRef);
		CurrentExecutionParameters.Insert("FileAddress",   VersionProperties.VersionURL);
		
		DataItem = New Structure;
		DataItem.Insert("Data", VersionProperties.VersionURL);
		
		DataItem.Insert("ResultPlacement", New NotifyDescription(
			"OnGetEncryptedData", ThisObject, CurrentExecutionParameters));
		
		DataSet.Add(DataItem);
	EndDo;
	
	DataDetails = New Structure;
	DataDetails.Insert("Operation",            NStr("ru = 'Шифрование файла'; en = 'Encrypt file'; pl = 'Szyfrowanie plików';de = 'Dateiverschlüsselung';ro = 'Criptarea fișierului';tr = 'Dosya şifreleme'; es_ES = 'Codificación del archivo'"));
	DataDetails.Insert("DataTitle",     NStr("ru = 'Файл'; en = 'File'; pl = 'Plik';de = 'Datei';ro = 'Fișier';tr = 'Dosya'; es_ES = 'Archivo'"));
	DataDetails.Insert("DataSet",         DataSet);
	DataDetails.Insert("SetPresentation", NStr("ru = 'Файлы (%1)'; en = 'Files (%1)'; pl = 'Pliki (%1)';de = 'Dateien (%1)';ro = 'Fișiere (%1)';tr = 'Dosyalar (%1)'; es_ES = 'Archivo (%1)'"));
	DataDetails.Insert("PresentationsList", PresentationsList);
	DataDetails.Insert("NotifyOnCompletion", False);
	
	FollowUpHandler = New NotifyDescription("AfterFileEncryption", ThisObject, ExecutionParameters);
	
	ModuleDigitalSignatureClient = CommonClient.CommonModule("DigitalSignatureClient");
	ModuleDigitalSignatureClient.Encrypt(DataDetails, , FollowUpHandler);
	
EndProcedure

// Continues the Encrypt procedure. It is called from the DigitalSignature subsystem.
Procedure OnGetEncryptedData(Parameters, CurrentExecutionParameters) Export
	
	ExecutionParameters = CurrentExecutionParameters.ExecutionParameters;
	
	EncryptedData = Parameters.DataDetails.CurrentDataSetItem.EncryptedData;
	If TypeOf(EncryptedData) = Type("BinaryData") Then
		TempStorageAddress = PutToTempStorage(EncryptedData,
			ExecutionParameters.UUID);
	Else
		TempStorageAddress = EncryptedData;
	EndIf;
	
	DataToWriteAtServer = New Structure;
	DataToWriteAtServer.Insert("TempStorageAddress", TempStorageAddress);
	DataToWriteAtServer.Insert("VersionRef", CurrentExecutionParameters.VersionRef);
	DataToWriteAtServer.Insert("FileAddress",   CurrentExecutionParameters.FileAddress);
	DataToWriteAtServer.Insert("TempTextStorageAddress", "");
	
	ExecutionParameters.DataArrayToStoreInDatabase.Add(DataToWriteAtServer);
	
	ExecuteNotifyProcessing(Parameters.Notification, New Structure);
	
EndProcedure

// The Encrypt procedure completion. It is called from the DigitalSignature subsystem.
Procedure AfterFileEncryption(DataDetails, ExecutionParameters) Export
	
	ExecutionParameters.Success = DataDetails.Success;
	
	If DataDetails.Success Then
		If TypeOf(DataDetails.EncryptionCertificates) = Type("String") Then
			ExecutionParameters.Insert("ThumbprintsArray", GetFromTempStorage(
				DataDetails.EncryptionCertificates));
		Else
			ExecutionParameters.Insert("ThumbprintsArray", DataDetails.EncryptionCertificates);
		EndIf;
		NotifyOfFileChange(ExecutionParameters.FileData);
	EndIf;
	
	ReturnResult(ExecutionParameters.ResultHandler, ExecutionParameters);
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Decrypting files.

// It decrypts the File and Version objects.
//
// Parameters:
//  ResultHandler - NotifyDescription, Undefined - description of the procedure that gets the method result.
//  FileRef  - CatalogRef.Files - a file.
//  UUID - a form UUID.
//  FileData  - a structure with file data.
//
// Returns:
//   Structure - result.
//       * Success - Boolean - shows whether the operation is performed successfully.
//       * DataArrayToAddToBase - an array of structures.
//
Procedure Decrypt(ResultHandler, FileRef, UUID, FileData) Export
	
	If Not CommonClient.SubsystemExists("StandardSubsystems.DigitalSignature") Then
		Return;
	EndIf;
	
	ExecutionParameters = New Structure;
	ExecutionParameters.Insert("ResultHandler", ResultHandler);
	ExecutionParameters.Insert("FileRef", FileRef);
	ExecutionParameters.Insert("UUID", UUID);
	ExecutionParameters.Insert("FileData", FileData);
	ExecutionParameters.Insert("Success", False);
	ExecutionParameters.Insert("DataArrayToStoreInDatabase", New Array);
	
	// SuggestFileSystemExtensionInstallationNow() is not required, because everything is done in the memory via BinaryData
	
	VersionsArray = FilesOperationsInternalServerCall.FileDataAndURLOfAllFileVersions(
		ExecutionParameters.FileRef, ExecutionParameters.UUID);
	
	ExecutionParameters.DataArrayToStoreInDatabase = New Array;
	
	ExecutionParameters.Insert("ExtractTextFilesOnServer",
		CommonFilesOperationsSettings().ExtractTextFilesOnServer);
	
	FilePresentation = String(ExecutionParameters.FileData.Ref);
	If ExecutionParameters.FileData.VersionsCount > 1 Then
		FilePresentation = FilePresentation + " (" + StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Версий: %1'; en = 'Versions: %1'; pl = 'Wersje: %1';de = 'Versionen: %1';ro = 'Versiuni: %1';tr = 'Sürümler:%1'; es_ES = 'Versiones: %1'"), ExecutionParameters.FileData.VersionsCount) + ")";
	EndIf;
	PresentationsList = New ValueList;
	PresentationsList.Add(ExecutionParameters.FileData.Ref, FilePresentation);
	
	EncryptionCertificates = New Array;
	EncryptionCertificates.Add(ExecutionParameters.FileData.Ref);
	
	DataSet = New Array;
	
	For each VersionProperties In VersionsArray Do
		
		CurrentExecutionParameters = New Structure;
		CurrentExecutionParameters.Insert("ExecutionParameters", ExecutionParameters);
		CurrentExecutionParameters.Insert("VersionRef", VersionProperties.VersionRef);
		CurrentExecutionParameters.Insert("FileAddress",   VersionProperties.VersionURL);
		
		DataItem = New Structure;
		DataItem.Insert("Data", VersionProperties.VersionURL);
		
		DataItem.Insert("ResultPlacement", New NotifyDescription(
			"OnGetDecryptedData", ThisObject, CurrentExecutionParameters));
		
		DataSet.Add(DataItem);
	EndDo;
	
	DataDetails = New Structure;
	DataDetails.Insert("Operation",              NStr("ru = 'Расшифровка файла'; en = 'Decrypt file'; pl = 'Deszyfrowanie plików';de = 'Dateientschlüsselung';ro = 'Decriptarea fișierului';tr = 'Dosya şifresini çözme'; es_ES = 'Descodificación del archivo'"));
	DataDetails.Insert("DataTitle",       NStr("ru = 'Файл'; en = 'File'; pl = 'Plik';de = 'Datei';ro = 'Fișier';tr = 'Dosya'; es_ES = 'Archivo'"));
	DataDetails.Insert("DataSet",           DataSet);
	DataDetails.Insert("SetPresentation",   NStr("ru = 'Файлы (%1)'; en = 'Files (%1)'; pl = 'Pliki (%1)';de = 'Dateien (%1)';ro = 'Fișiere (%1)';tr = 'Dosyalar (%1)'; es_ES = 'Archivo (%1)'"));
	DataDetails.Insert("PresentationsList",   PresentationsList);
	DataDetails.Insert("EncryptionCertificates", EncryptionCertificates);
	DataDetails.Insert("NotifyOnCompletion",   False);
	
	FollowUpHandler = New NotifyDescription("AfterFileDecryption", ThisObject, ExecutionParameters);
	
	ModuleDigitalSignatureClient = CommonClient.CommonModule("DigitalSignatureClient");
	ModuleDigitalSignatureClient.Decrypt(DataDetails, , FollowUpHandler);
	
EndProcedure

// Continues the Decrypt procedure. It is called from the DigitalSignature subsystem.
Procedure OnGetDecryptedData(Parameters, CurrentExecutionParameters) Export
	
	ExecutionParameters = CurrentExecutionParameters.ExecutionParameters;
	
	DecryptedData = Parameters.DataDetails.CurrentDataSetItem.DecryptedData;
	If TypeOf(DecryptedData) = Type("BinaryData") Then
		TempStorageAddress = PutToTempStorage(DecryptedData,
			ExecutionParameters.UUID);
		#If Not WebClient Then
			DecodedBinaryData = DecryptedData;
		#EndIf
	Else
		TempStorageAddress = DecryptedData;
		#If Not WebClient Then
			DecodedBinaryData = GetFromTempStorage(TempStorageAddress);
		#EndIf
	EndIf;
	
	TempTextStorageAddress = "";
	#If Not WebClient Then
		If Not ExecutionParameters.ExtractTextFilesOnServer Then
			FullFilePath = GetTempFileName(ExecutionParameters.FileData.Extension);
			DecodedBinaryData.Write(FullFilePath);
			
			TempTextStorageAddress = ExtractTextToTempStorage(FullFilePath, ExecutionParameters.UUID);
			
			DeleteFiles(FullFilePath);
		EndIf;
	#EndIf
	
	DataToWriteAtServer = New Structure;
	DataToWriteAtServer.Insert("TempStorageAddress", TempStorageAddress);
	DataToWriteAtServer.Insert("VersionRef", CurrentExecutionParameters.VersionRef);
	DataToWriteAtServer.Insert("FileAddress",   CurrentExecutionParameters.FileAddress);
	DataToWriteAtServer.Insert("TempTextStorageAddress", TempTextStorageAddress);
	
	ExecutionParameters.DataArrayToStoreInDatabase.Add(DataToWriteAtServer);
	
	ExecuteNotifyProcessing(Parameters.Notification, New Structure);
	
EndProcedure

// The Decrypt procedure completion. It is called from the DigitalSignature subsystem.
Procedure AfterFileDecryption(DataDetails, ExecutionParameters) Export
	
	ExecutionParameters.Success = DataDetails.Success;
	
	If DataDetails.Success Then
		NotifyOfFileChange(ExecutionParameters.FileData);
	EndIf;
	
	ReturnResult(ExecutionParameters.ResultHandler, ExecutionParameters);
	
EndProcedure

// Continue the CheckSignatures procedure. It is called from the DigitalSignature subsystem.
Procedure AfterFileDecryptionOnCheckSignature(DataDetails, AdditionalParameters) Export
	
	If Not DataDetails.Success Then
		Return;
	EndIf;
	
	CheckSignaturesAfterPrepareData(DataDetails.DecryptedData, AdditionalParameters);
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Procedures that continue asynchronous procedures.

////////////////////////////////////////////////////////////////////////////////
// Creates a new file.

// Creates a new file interactively calling the dialog box of selection the File creation mode.
//
// Parameters:
//   See FilesOperationsClient.AddFile(). 
//
Procedure AppendFile(
	ResultHandler,
	FileOwner,
	OwnerForm,
	CreateMode = 1,
	AddingOptions = Undefined) Export
	
	ExecutionParameters = New Structure;
	If AddingOptions = Undefined
		Or TypeOf(AddingOptions) = Type("Boolean") Then
		
		ExecutionParameters.Insert("MaxSize", 0);
		ExecutionParameters.Insert("SelectionDialogFilter",  NStr("ru = 'Все файлы(*.*)|*.*'; en = 'All files (*.*)|*.*'; pl = 'Wszystkie pliki(*.*)|*.*';de = 'Alle Dateien (*.*)| *.*';ro = 'Toate fișierele(*.*)|*.*';tr = 'Tüm dosyalar(*.*)|*.*'; es_ES = 'Todos archivos(*.*)|*.*'"));
		ExecutionParameters.Insert("DontOpenCardAfterCreateFromFIle", ?(AddingOptions = Undefined, False, AddingOptions));
		
	Else
		ExecutionParameters.Insert("MaxSize", AddingOptions.MaxSize);
		ExecutionParameters.Insert("SelectionDialogFilter", AddingOptions.SelectionDialogFilter);
		ExecutionParameters.Insert("DontOpenCardAfterCreateFromFIle", AddingOptions.DontOpenCard);
	EndIf;
	
	ExecutionParameters.Insert("ResultHandler", ResultHandler);
	ExecutionParameters.Insert("FileOwner", FileOwner);
	ExecutionParameters.Insert("OwnerForm", OwnerForm);
	ExecutionParameters.Insert("IsFile", True);
	
	Handler = New NotifyDescription("AddAfterCreationModeChoice", ThisObject, ExecutionParameters);
	
	FormParameters = New Structure;
	FormParameters.Insert("CreateMode", CreateMode);
	FormParameters.Insert("ScanCommandAvailable", FilesOperationsInternalClientCached.ScanCommandAvailable());
	
	OpenForm("Catalog.Files.Form.FormNewItem", FormParameters, , , , , Handler);
	
EndProcedure

Procedure AddFileFromFileSystem(FileOwner, OwnerForm) Export
	
	ExecutionParameters = New Structure;
	ExecutionParameters.Insert("ResultHandler",                    Undefined);
	ExecutionParameters.Insert("FileOwner",                           FileOwner);
	ExecutionParameters.Insert("OwnerForm",                           OwnerForm);
	ExecutionParameters.Insert("IsFile",                                 True);
	
	AddAfterCreationModeChoice(2, ExecutionParameters);
	
EndProcedure

// Creates a new file interactively, using the specified method.
//
// Parameters:
//   CreationMode - Number - file creation mode.
//       And 1 - from a template (by copying other file),
//       * 2 - from the hard disk (from the client file system),
//       * 3 - from scanner.
//   ExecutionParameter - Structure - for types of value and descriptions see FilesOperationsClient.AppendFile().
//       * ResultHandler.
//       * FileOwner.
//       * OwnerForm
//       * DontOpenCardAfterCreateFromFile
//
Procedure AddAfterCreationModeChoice(CreateMode, ExecutionParameters) Export
	
	ExecutionParameters.Insert("DontOpenCardAfterCreateFromFIle", True);
	
	If CreateMode = 1 Then // Copy other file.
		AddBasedOnTemplate(ExecutionParameters);
	ElsIf CreateMode = 2 Then // Import from file system.
		If FileSystemExtensionAttached() Then
			AddFormFileSystemWithExtension(ExecutionParameters);
		Else
			AddFromFileSystemWithoutExtension(ExecutionParameters);
		EndIf;
	ElsIf CreateMode = 3 Then // Read from scanner.
		AddFromScanner(ExecutionParameters);
	Else
		ReturnResult(ExecutionParameters.ResultHandler, Undefined);
	EndIf;
	
EndProcedure

// Continuation of the procedure (see above).
Procedure AddBasedOnTemplate(ExecutionParameters) Export
	
	// Copy from the template file.
	FormParameters = New Structure;
	FormParameters.Insert("SelectTemplate", True);
	FormParameters.Insert("CurrentRow", PredefinedValue("Catalog.FilesFolders.Templates"));
	Handler = New NotifyDescription("AddBasedOnTemplateAfterTemplateChoice", ThisObject, ExecutionParameters);
	OpeningMode = FormWindowOpeningMode.LockWholeInterface;
	OpenForm("Catalog.Files.Form.ChoiceForm", FormParameters, , , , , Handler, OpeningMode);
	
EndProcedure

// Continuation of the procedure (see above).
Procedure AddBasedOnTemplateAfterTemplateChoice(Result, ExecutionParameters) Export
	
	If Result = Undefined Then
		ReturnResult(ExecutionParameters.ResultHandler, Undefined);
		Return;
	EndIf;
	
	FormParameters = New Structure;
	FormParameters.Insert("CreateMode", "FromTemplate");
	FormParameters.Insert("FilesStorageCatalogName",
		?(ExecutionParameters.Property("FilesStorageCatalogName"),
		ExecutionParameters.FilesStorageCatalogName, 
		FilesOperationsInternalServerCall.FileStoringCatalogName(ExecutionParameters.FileOwner)));
		
	OnCloseNotifyDescription = PrepareHandlerForDialog(ExecutionParameters.ResultHandler);
	FilesOperationsClient.CopyFile(ExecutionParameters.FileOwner, Result, FormParameters, OnCloseNotifyDescription); 
	
EndProcedure

// Continuation of the procedure (see above).
Procedure AddFromFileSystemWithoutExtension(ExecutionParameters)
	
	// Import from file system without file system extension (web client).
	ChoiceDialog = New FileDialog(FileDialogMode.Open);
	If ExecutionParameters.Property("SelectionDialogFilter") Then
		ChoiceDialog.Filter = ExecutionParameters.SelectionDialogFilter;
	EndIf;
	
	Handler = New NotifyDescription("AddFromFileSystemWithoutFileSystemExtensionAfterImportFile", ThisObject, ExecutionParameters);
	BeginPutFile(Handler, , ChoiceDialog, , ExecutionParameters.OwnerForm.UUID);
	
EndProcedure

// Continuation of the procedure (see above).
Procedure AddFromFileSystemWithoutFileSystemExtensionAfterImportFile(Put, Address, SelectedFileName, ExecutionParameters) Export
	
	If Not Put Then
		ReturnResult(ExecutionParameters.ResultHandler, Undefined);
		Return;
	EndIf;
	
	Result = New Structure;
	Result.Insert("FileAdded", False);
	Result.Insert("FileRef",   Undefined);
	Result.Insert("ErrorText",  "");
	
	PathStructure = CommonClientServer.ParseFullFileName(SelectedFileName);
	If IsBlankString(PathStructure.Extension) Then
		QuestionText = NStr("ru = 'Необходимо указать файл с расширением.'; en = 'Please select a file with extension.'; pl = 'Określ plik z rozszerzeniem.';de = 'Datei mit Erweiterung angeben.';ro = 'Specificați fișierul cu extensie.';tr = 'Uzantı ile dosya belirtin.'; es_ES = 'Especificar el archivo con la extensión.'");
		Buttons = New ValueList;
		Buttons.Add(DialogReturnCode.Retry, NStr("ru = 'Выбрать другой файл'; en = 'Select another file'; pl = 'Wybierz inny plik';de = 'Wählen Sie eine andere Datei';ro = 'Selectați un alt fișier';tr = 'Başka bir dosya seç'; es_ES = 'Seleccionar otro archivo'"));
		Buttons.Add(DialogReturnCode.Cancel);
		Handler = New NotifyDescription("AddFromFileSystemWithoutExtensionAfterRespondQuestionContinue", ThisObject, ExecutionParameters);
		ShowQueryBox(Handler, QuestionText, Buttons);
		Return;
	EndIf;
	
	If ExecutionParameters.Property("MaxSize")
		AND ExecutionParameters.MaxSize > 0 Then
		
		FileSize = GetFromTempStorage(Address).Size();
		If FileSize > ExecutionParameters.MaxSize*1024*1024 Then
			
			ErrorText = NStr("ru = 'Размер файла превышает %1 Мб.'; en = 'The file size exceeds %1 MB.'; pl = 'Rozmiar pliku przekracza %1 MB.';de = 'Die Dateigröße überschreitet %1 MB.';ro = 'Dimensiunea fișierului depășește %1 Mb.';tr = 'Dosya boyutu %1MB''yi aşıyor.'; es_ES = 'El tamaño del archivo supera %1 MB.'");
			Result.ErrorText = StringFunctionsClientServer.SubstituteParametersToString(ErrorText, 
				ExecutionParameters.MaxSize);
			ReturnResultAfterShowWarning(ExecutionParameters.ResultHandler, Result.ErrorText, Undefined);
			Return;
			
		EndIf;
		
	EndIf;
	
	// Creating a file in the infobase.
	Try
		
		If FilesOperationsInternalClientCached.IsDirectoryFiles(ExecutionParameters.FileOwner) Then
			
			FileInfo = FilesOperationsClientServer.FileInfo("FileWithVersion");
			FileInfo.TempFileStorageAddress = Address;
			FileInfo.BaseName = PathStructure.BaseName;
			FileInfo.ExtensionWithoutPoint = CommonClientServer.ExtensionWithoutPoint(PathStructure.Extension);
			Result.FileRef = FilesOperationsInternalServerCall.CreateFileWithVersion(ExecutionParameters.FileOwner, FileInfo);
			Result.FileAdded = True;
			
		Else
			
			FileParameters = New Structure;
			FileParameters.Insert("FilesOwner",     ExecutionParameters.FileOwner);
			FileParameters.Insert("Author",              Undefined);
			FileParameters.Insert("BaseName",   PathStructure.BaseName);
			FileParameters.Insert("ExtensionWithoutPoint", CommonClientServer.ExtensionWithoutPoint(PathStructure.Extension));
			FileParameters.Insert("Modified");
			FileParameters.Insert("ModificationTimeUniversal");
			
			Result.FileRef = FilesOperationsInternalServerCall.AppendFile(FileParameters,Address);
			Result.FileAdded = True;
			
		EndIf;
		
	Except
		Result.ErrorText = ErrorCreatingNewFile(ErrorInfo());
	EndTry;
	If Result.ErrorText <> "" Then
		ReturnResultAfterShowWarning(ExecutionParameters.ResultHandler, Result.ErrorText, Undefined);
		Return;
	EndIf;
	
	NotificationParameters = New Structure;
	NotificationParameters.Insert("Owner", ExecutionParameters.FileOwner);
	NotificationParameters.Insert("File",     Result.FileRef);
	NotificationParameters.Insert("IsNew", True);
	Notify("Write_File", NotificationParameters, Result.FileRef);
	
	ShowUserNotification(
		NStr("ru = 'Создание:'; en = 'Created:'; pl = 'Utworzony:';de = 'Erstellt:';ro = 'Creat:';tr = 'Oluşturuldu:'; es_ES = 'Creado:'"),
		GetURL(Result.FileRef),
		Result.FileRef,
		PictureLib.Information32);
	
	If ExecutionParameters.DontOpenCardAfterCreateFromFIle <> True Then
		FormParameters = New Structure("OpenCardAfterCreateFile", True);
		OnCloseNotifyDescription = PrepareHandlerForDialog(ExecutionParameters.ResultHandler);
		FilesOperationsClient.OpenFileForm(Result.FileRef,, FormParameters, OnCloseNotifyDescription);
	Else
		ReturnResult(ExecutionParameters.ResultHandler, Result);
	EndIf;
	
EndProcedure

// Continuation of the procedure (see above).
Procedure AddFromFileSystemWithoutExtensionAfterRespondQuestionContinue(Response, ExecutionParameters) Export
	
	If Response = DialogReturnCode.Retry Then
		AddFromFileSystemWithoutExtension(ExecutionParameters);
	Else
		ReturnResult(ExecutionParameters.ResultHandler, Undefined);
	EndIf;
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Sends a notification about finishing the file encryption or decryption.

// Notifies by the end of Encrypt.
// Parameters:
//  FilesArrayInWorkingDirectoryToDelete - Array - an array of strings that are paths to files.
//  FileOwner  - AnyRef - file owner.
//  FileRef  - CatalogRef.Files - a file.
Procedure InformOfEncryption(FilesArrayInWorkingDirectoryToDelete,
                                   FileOwner,
                                   FileRef) Export
	
	NotifyChanged(FileRef);
	Notify("Write_File", New Structure("Event", "AttachedFileEncrypted"), FileOwner);
	Notify("Write_File", New Structure("Event", "FileDataChanged"), FileRef);
	
	// Deleting all file versions from working directory.
	For Each FullFileName In FilesArrayInWorkingDirectoryToDelete Do
		DeleteFileWithoutConfirmation(FullFileName);
	EndDo;
	
	If Not CommonClient.SubsystemExists("StandardSubsystems.DigitalSignature") Then
		Return;
	EndIf;
	ModuleDigitalSignatureClient = CommonClient.CommonModule("DigitalSignatureClient");
	ModuleDigitalSignatureClient.InformOfObjectEncryption(
		StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Файл: %1'; en = 'File: %1'; pl = 'Plik: %1';de = 'Datei: %1';ro = 'Fişier: %1';tr = 'Dosya: %1'; es_ES = 'Archivo: %1'"), FileRef));
	
EndProcedure

// Notifies by the end of Decrypt.
// Parameters:
//  FileOwner  - AnyRef - file owner.
//  FileRef  - CatalogRef.Files - a file.
Procedure InformOfDecryption(FileOwner, FileRef) Export
	
	NotifyChanged(FileRef);
	Notify("Write_File", New Structure("Event", "AttachedFileEncrypted"), FileOwner);
	Notify("Write_File", New Structure("Event", "FileDataChanged"), FileRef);
	
	If Not CommonClient.SubsystemExists("StandardSubsystems.DigitalSignature") Then
		Return;
	EndIf;
	ModuleDigitalSignatureClient = CommonClient.CommonModule("DigitalSignatureClient");
	ModuleDigitalSignatureClient.InformOfObjectDecryption(
		StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Файл: %1'; en = 'File: %1'; pl = 'Plik: %1';de = 'Datei: %1';ro = 'Fişier: %1';tr = 'Dosya: %1'; es_ES = 'Archivo: %1'"), FileRef));
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Operations with digital signatures.
Procedure SignFile(AttachedFile, FileData, FormID,
			CompletionHandler = Undefined, HandlerOnGetSignature = Undefined) Export
	
	ExecutionParameters = New Structure;
	ExecutionParameters.Insert("CompletionHandler", CompletionHandler);
	ExecutionParameters.Insert("AttachedFile",   AttachedFile);
	ExecutionParameters.Insert("FileData",          FileData);
	ExecutionParameters.Insert("FormID",   FormID);
	
	FollowUpHandler = New NotifyDescription("AfterAddSignatures", ThisObject, ExecutionParameters);
	If Not CheckSignPossibility(FileData, CompletionHandler, FollowUpHandler, ExecutionParameters) Then
		Return;
	EndIf;
	
	DataDetails = New Structure;
	DataDetails.Insert("Operation",            NStr("ru = 'Подписание файла'; en = 'Sign file'; pl = 'Podpisywanie pliku';de = 'Dateisignierung';ro = 'Semnarea fișierelor';tr = 'Dosya imzalama'; es_ES = 'Firma del archivo'"));
	DataDetails.Insert("DataTitle",     NStr("ru = 'Файл'; en = 'File'; pl = 'Plik';de = 'Datei';ro = 'Fișier';tr = 'Dosya'; es_ES = 'Archivo'"));
	DataDetails.Insert("Presentation",       AttachedFile);
	DataDetails.Insert("ShowComment", True);
	
	DataDetails.Insert("Data", ExecutionParameters.FileData.BinaryFileDataRef);
	
	If HandlerOnGetSignature = Undefined Then
		DataDetails.Insert("Object", AttachedFile);
	Else
		DataDetails.Insert("Object", HandlerOnGetSignature);
	EndIf;
	
	ModuleDigitalSignatureClient = CommonClient.CommonModule("DigitalSignatureClient");
	ModuleDigitalSignatureClient.Sign(DataDetails, FormID, FollowUpHandler);
	
EndProcedure

// Finish the SignFile and AddSignatureFromFile procedures.
Procedure AfterAddSignatures(DataDetails, ExecutionParameters) Export
	
	If DataDetails.Success Then
		NotifyChanged(ExecutionParameters.AttachedFile);
		Notify("Write_File", New Structure, ExecutionParameters.AttachedFile);
	EndIf;
	
	If ExecutionParameters.CompletionHandler <> Undefined Then
		ExecuteNotifyProcessing(ExecutionParameters.CompletionHandler, DataDetails.Success);
	EndIf;
	
EndProcedure

// Adds digital signatures to the object file from the signature files on the hard drive.
Procedure AddSignatureFromFile(File, FormID, CompletionHandler) Export
	
	FileProperties = FilesOperationsInternalServerCall.FileDataAndBinaryData(File, , FormID);
	
	ExecutionParameters = New Structure;
	ExecutionParameters.Insert("CompletionHandler", CompletionHandler);
	ExecutionParameters.Insert("FileData", FileProperties.FileData);
	ExecutionParameters.Insert("FormID", FormID);
	
	If Not CheckSignPossibility(ExecutionParameters.FileData,
		CompletionHandler, CompletionHandler, ExecutionParameters) Then
		
		Return;
		
	EndIf;
	
	DataDetails = New Structure;
	DataDetails.Insert("DataTitle",     NStr("ru = 'Файл'; en = 'File'; pl = 'Plik';de = 'Datei';ro = 'Fișier';tr = 'Dosya'; es_ES = 'Archivo'"));
	DataDetails.Insert("Presentation",       ExecutionParameters.FileData.Ref);
	DataDetails.Insert("ShowComment", True);
	DataDetails.Insert("Data",              FileProperties.BinaryData);
	
	DataDetails.Insert("Object",
		New NotifyDescription("OnGetSignatures", ThisObject, ExecutionParameters));
	
	FollowUpHandler = New NotifyDescription("AfterSignFile",
		ThisObject, ExecutionParameters);
	
	ModuleDigitalSignatureClient = CommonClient.CommonModule("DigitalSignatureClient");
	ModuleDigitalSignatureClient.AddSignatureFromFile(DataDetails,, FollowUpHandler);
	
EndProcedure

// Continue the AddSignatureFromFile procedure.
// It is called from the DigitalSignature subsystem after preparing signatures from files for 
// non-standard way of adding a signature to the object.
//
Procedure OnGetSignatures(Parameters, Context) Export
	
	FilesOperationsInternalServerCall.AddSignatureToFile(
		Context.FileData.Ref,
		Parameters.DataDetails.Signatures,
		Context.FormID);
	
	ExecuteNotifyProcessing(Parameters.Notification, New Structure);
	
EndProcedure

// The AddSignatureFromFile procedure completion.
Procedure AfterSignFile(DataDetails, ExecutionParameters) Export
	
	If DataDetails.Success Then
		NotifyOfFileChange(ExecutionParameters.FileData);
	EndIf;
	
	ReturnResult(ExecutionParameters.CompletionHandler, DataDetails.Success);
	
EndProcedure

// For the AfterSignFile and AfterSignFiles procedures.
Procedure NotifyOfFileChange(FileData)
	
	NotifyChanged(FileData.Ref);
	NotifyChanged(FileData.CurrentVersion);
	
	NotificationParameter = New Structure("Event", "AttachedFileSigned");
	Notify("Write_File", NotificationParameter, FileData.Owner);
	
EndProcedure

// Saves file with the digital signature
Procedure SaveFileWithSignature(File, FormID) Export
	
	If Not CommonClient.SubsystemExists("StandardSubsystems.DigitalSignature") Then
		Return;
	EndIf;
	
	FileData = FilesOperationsInternalServerCall.FileDataToSave(File);
	
	ExecutionParameters = New Structure;
	ExecutionParameters.Insert("FileData", FileData);
	ExecutionParameters.Insert("FormID", FormID);
	
	DataDetails = New Structure;
	DataDetails.Insert("DataTitle",     NStr("ru = 'Файл'; en = 'File'; pl = 'Plik';de = 'Datei';ro = 'Fișier';tr = 'Dosya'; es_ES = 'Archivo'"));
	DataDetails.Insert("Presentation",       ExecutionParameters.FileData.Ref);
	DataDetails.Insert("ShowComment", True);
	DataDetails.Insert("Object",              ExecutionParameters.FileData.Ref);
	
	DataDetails.Insert("Data",
		New NotifyDescription("OnSaveFileData", ThisObject, ExecutionParameters));
	
	ModuleDigitalSignatureClient = CommonClient.CommonModule("DigitalSignatureClient");
	ModuleDigitalSignatureClient.SaveDataWithSignature(DataDetails);
	
EndProcedure

// Continue the SaveFileWithSignatures procedure.
// It is called from the DigitalSignature subsystem after selecting signatures to save.
//
Procedure OnSaveFileData(Parameters, Context) Export
	
	AdditionalParameters = New Structure("Notification", Parameters.Notification);
	NotificationHandler = New NotifyDescription("OnSaveFileDataReturnResult", ThisObject, AdditionalParameters);
	SaveAs(NotificationHandler, Context.FileData, Context.FormID);
	
EndProcedure

// Continue the SaveFileWithSignatures procedure.
// It is called from the DigitalSignature subsystem after selecting signatures to save.
//
Procedure OnSaveFileDataReturnResult(Result, AdditionalParameters) Export

	If TypeOf(Result) = Type("String") Then
		Result = ?(ValueIsFilled(Result), New Structure("FullFileName", Result), New Structure);
	EndIf;
	ExecuteNotifyProcessing(AdditionalParameters.Notification, Result);

EndProcedure

Function CheckSignPossibility(FileData, CompletionHandler, ResultHandler, ExecutionParameters)
	
	If Not CommonClient.SubsystemExists("StandardSubsystems.DigitalSignature") Then
		Return False;
	EndIf;
	
	If ValueIsFilled(FileData.BeingEditedBy) Then
		WarningText = FilesOperationsInternalClientServer.FileUsedByAnotherProcessCannotBeSignedMessageString();
		ReturnResultAfterShowWarning(ResultHandler, WarningText, ExecutionParameters);
		Return False;
	EndIf;
	
	If FileData.Encrypted Then
		WarningText = FilesOperationsInternalClientServer.EncryptedFileCannotBeSignedMessageString();
		ReturnResultAfterShowWarning(CompletionHandler, WarningText, ExecutionParameters);
		Return False;
	EndIf;
	
	Return True;
	
EndFunction

////////////////////////////////////////////////////////////////////////////////
// Imports the structure of files and directories from the hard disk to the application.

// Returns:
//  Structure - with the following properties:
//    * ResultHandler      - NotifyDescription - a handler that requires the import result.
//    * Owner                  - DefinedType.AttachedFilesOwner - a folder or an owner object, to 
//                                                                                 which the imported files are added.
//    * FilesGroup              - DefinedType.AttachedFile - a group of files, to which the imported 
//                                                                       files are added.
//    * SelectedFiles            - ValueList - imported objects of the File group.
//    * Indicator                 - Number - a number from 0 to 100 is the progress of executing.
//    * Comment               - String - a comment.
//    * StoreVersions             - Boolean - store versions.
//    * DeleteFilesAfterAdd - Boolean - delete SelectedFiles after importing.
//    * Recursively                - Boolean - recursively iterate subdirectories.
//    * FormID        - UUID - the form ID.
//    * PseudoFileSystem     - Map - file system emulation for a row (directory), it returns an 
//                                                 array of rows (subdirectories and files).
//    * Encoding                 - String - an encoding for text files.
//    * AddedFiles          - Array - added files, an output parameter.
//
Function FilesImportParameters() Export
	ExecutionParameters = New Structure;
	ExecutionParameters.Insert("ResultHandler");
	ExecutionParameters.Insert("Owner");
	ExecutionParameters.Insert("GroupOfFiles");
	ExecutionParameters.Insert("SelectedFiles");
	ExecutionParameters.Insert("Comment");
	ExecutionParameters.Insert("StoreVersions");
	ExecutionParameters.Insert("DeleteFilesAfterAdd");
	ExecutionParameters.Insert("Recursively");
	ExecutionParameters.Insert("FormID");
	ExecutionParameters.Insert("PseudoFileSystem", New Map);
	ExecutionParameters.Insert("Encoding");
	ExecutionParameters.Insert("AddedFiles", New Array);
	Return ExecutionParameters;
EndFunction

// Recursive function of importing files from the hard drive. It takes an array of files (or directories)
// - if it is a file, it simply adds it; if it is a directory, it creates a group and recursively calls itself.
//
// Parameters:
//  ExecutionParameters   - Structure - with the following properties:
//    * ResultHandler      - NotifyDescription, Structure - a handler that requires the import 
//                                  result.
//    * Owner                  - AnyRef - a file owner.
//    * SelectedFiles            - Array, ValueList - an objects of the File type.
//    * Indicator                 - Number - a number from 0 to 100 is the progress of executing.
//    * ArrayOfFilesNamesWithErrors - Array - an array of file names with errors.
//    * AllFilesStructureArray  - Array - a structure array of all files.
//    * Comment               - String - a comment.
//    * StoreVersions             - Boolean - store versions.
//    * DeleteFilesAfterAdd - Boolean - delete SelectedFiles after importing.
//    * Recursively                - Boolean - recursively iterate subdirectories.
//    * CountTotal       - Number - a total number of imported files.
//    * Counter                   - Number - counter of processed files (file is not necessarily loaded).
//    * FormID        - UUID - the form ID.
//    * PseudoFileSystem     - Map - file system emulation for a row (directory), it returns an 
//                                                 array of rows (subdirectories and files).
//    * AddedFiles          - Array - added files, an output parameter.
//    * AllFoldersArray           - Array - an array of all folders.
//    * Encoding                 - String - an encoding for text files.
//
Procedure ImportFilesRecursively(Owner, SelectedFiles, ExecutionParameters)
	
	InternalParameters = New Structure;
	For Each KeyAndValue In ExecutionParameters Do
		InternalParameters.Insert(KeyAndValue.Key, KeyAndValue.Value);
	EndDo;
	InternalParameters.ResultHandler = ExecutionParameters;
	InternalParameters.Owner = Owner;
	InternalParameters.SelectedFiles = SelectedFiles;
	
	InternalParameters.Insert("FoldersArrayForQuestionWhetherFolderAlreadyExists", New Array);
	ImportFilesRecursivelyWithoutDialogBoxes(InternalParameters.Owner, InternalParameters.SelectedFiles, InternalParameters, True); 
	If InternalParameters.FoldersArrayForQuestionWhetherFolderAlreadyExists.Count() = 0 Then
		// The question is not required.
		ReturnResult(InternalParameters.ResultHandler, Undefined);
		Return;
	EndIf;
	
	// As you answer the questions in the folder from the 
	// ExecutionParametersFoldersArrayForQuestionWhetherFolderAlreadyExists, they are written to the ExecutionParameters.SelectedFiles.
	// Then recursion is restarted.
	InternalParameters.SelectedFiles = New Array;
	InternalParameters.Insert("FolderToAddToSelectedFiles", Undefined);
	ImportFilesRecursivelySetNextQuestion(InternalParameters);
	
EndProcedure

// Continuation of the procedure (see above).
Procedure ImportFilesRecursivelySetNextQuestion(ExecutionParameters)
	
	ExecutionParameters.ResultHandler = PrepareHandlerForDialog(ExecutionParameters.ResultHandler);
	ExecutionParameters.FolderToAddToSelectedFiles = ExecutionParameters.FoldersArrayForQuestionWhetherFolderAlreadyExists[0];
	ExecutionParameters.FoldersArrayForQuestionWhetherFolderAlreadyExists.Delete(0);
	
	QuestionText = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("ru = 'Папка ""%1"" уже существует.
		           |Продолжить импорт папки?'; 
		           |en = 'Folder ""%1"" already exists.
		           |Do you want to continue the upload?'; 
		           |pl = 'Folder ""%1"" już istnieje.
		           |Kontynuować import folderu?';
		           |de = 'Der Ordner ""%1"" existiert bereits.
		           |Ordner-Import fortsetzen?';
		           |ro = 'Dosarul ""%1"" există deja.
		           |Continuați importul dosarului?';
		           |tr = 'Klasör ""%1"" zaten var. 
		           |Klasörü içe aktarmaya devam etmek istiyor musunuz?'; 
		           |es_ES = 'Carpeta ""%1"" ya existe.
		           |¿Continuar la importación de la carpeta?'"),
		ExecutionParameters.FolderToAddToSelectedFiles.Name);
	
	Handler = New NotifyDescription("FilesImportRecursivelyAfterRespondQuestion", ThisObject, ExecutionParameters);
	
	ShowQueryBox(Handler, QuestionText, QuestionDialogMode.YesNo);
	
EndProcedure

// Continuation of the procedure (see above).
Procedure FilesImportRecursivelyAfterRespondQuestion(Response, ExecutionParameters) Export
	
	If Response <> DialogReturnCode.No Then
		ExecutionParameters.SelectedFiles.Add(ExecutionParameters.FolderToAddToSelectedFiles);
	EndIf;
	
	// After responses to all question recursion is restarted.
	If ExecutionParameters.FoldersArrayForQuestionWhetherFolderAlreadyExists.Count() = 0 Then
		ImportFilesRecursivelyWithoutDialogBoxes(ExecutionParameters.Owner,	ExecutionParameters.SelectedFiles, ExecutionParameters,
			False); // AskQuestionFolderAlreadyExists (used only for the first level of recursion).
		
		If ExecutionParameters.FoldersArrayForQuestionWhetherFolderAlreadyExists.Count() = 0 Then
			// There are no more questions.
			ReturnResult(ExecutionParameters.ResultHandler, Undefined);
			Return;
		Else
			// There are more questions.
			ExecutionParameters.SelectedFiles = New Array;
		EndIf;
	EndIf;
	
	ImportFilesRecursivelySetNextQuestion(ExecutionParameters);
	
EndProcedure

// Recursive function of importing files from the hard drive. It takes an array of files (or directories)
// - if it is a file, it simply adds it; if it is a directory, it creates a group and recursively calls itself.
//
// Parameters:
//  Owner            - AnyRef - a file owner.
//  SelectedFiles      - Array - an array of FIle objects.
//  ExecutionParameters - Structure - see the parameter of the same name at ImportFilesRecursively.
//  AskQuestionFolderAlreadyExists - Boolean -True only for the first level of recursion.
//
Procedure ImportFilesRecursivelyWithoutDialogBoxes(Val Owner, Val SelectedFiles, Val ExecutionParameters, Val AskQuestionFolderAlreadyExists)
	
	Var FirstFolderWithSameName;
	
	For Each SelectedFile In SelectedFiles Do
		
		If Not SelectedFile.Exist() Then
			Record = New Structure;
			Record.Insert("FileName", SelectedFile.FullName);
			Record.Insert("Error", NStr("ru = 'Файл отсутствует на диске.'; en = 'The file is not found on the hard drive.'; pl = 'Plik nie jest obecny na dysku.';de = 'Die Datei ist nicht auf der Festplatte vorhanden.';ro = 'Fișierul nu este prezent pe disc.';tr = 'Diskte dosya yok.'; es_ES = 'Archivo no está presente en el disco.'"));
			ExecutionParameters.ArrayOfFilesNamesWithErrors.Add(Record);
			Continue;
		EndIf;
		
		Try
			
			If SelectedFile.Extension = ".lnk" Then
				SelectedFile = DereferenceLnkFile(SelectedFile);
			EndIf;
			
			If SelectedFile.IsDirectory() Then
				
				If ExecutionParameters.Recursively = True Then
					NewPath = String(SelectedFile.Path);
					NewPath = CommonClientServer.AddLastPathSeparator(NewPath);
					NewPath = NewPath + String(SelectedFile.Name);
					FilesArray = FindFilesPseudo(ExecutionParameters.PseudoFileSystem, NewPath);
					
					// Creating a group in the directory that is the equivalent of a folder on the hard drive.
					If FilesArray.Count() <> 0 Then
						FileName = SelectedFile.Name;
						
						FolderAlreadyFound = False;
						
						If FilesOperationsInternalServerCall.HasFolderWithThisName(FileName, Owner, FirstFolderWithSameName) Then
							
							If AskQuestionFolderAlreadyExists Then
								ExecutionParameters.FoldersArrayForQuestionWhetherFolderAlreadyExists.Add(SelectedFile);
								Continue;
							EndIf;
						EndIf;
						
						If Not FolderAlreadyFound Then
							FilesFolderRef = FilesOperationsInternalServerCall.CreateFilesFolder(FileName, Owner);
						EndIf;
						
						// The AskQuestionFolderAlreadyExists parameter is needed not to ask a question at level 1 of 
						// recursion, when folders, for which a positive response has already been received, are passed.
						ImportFilesRecursivelyWithoutDialogBoxes(FilesFolderRef, FilesArray, ExecutionParameters, True); 
						ExecutionParameters.AllFoldersArray.Add(NewPath);
					EndIf;
				EndIf;
				
				Continue;
			EndIf;
			
			If Not CheckCanImportFile(
			          SelectedFile, False, ExecutionParameters.ArrayOfFilesNamesWithErrors) Then
				Continue;
			EndIf;
			
			// Refreshing a progress indicator.
			ExecutionParameters.Counter = ExecutionParameters.Counter + 1;
			// Calculating percentage
			ExecutionParameters.Indicator = Int(ExecutionParameters.Counter * 100 / ExecutionParameters.TotalCount);
			SizeInMB = SelectedFile.Size() / (1024 * 1024);
			LabelMore = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'Обрабатывается файл ""%1"" (%2 Мб)...'; en = 'Processing file ""%1"" (%2 MB)...'; pl = 'Jest przetwarzany plik ""%1""(%2 MB)...';de = 'Datei ""%1"" (%2 MB) wird gerade bearbeitet...';ro = 'Are loc procesarea fișierului ""%1"" (%2 Mb)...';tr = '""%1"" (%2MB) dosyası işleniyor...'; es_ES = 'Se está procesando el archivo ""%1"" (%2 MB)...'"),
				SelectedFile.Name, 
				FilesOperationsInternalClientServer.GetStringWithFileSize(SizeInMB));
				
			StateText = NStr("ru = 'Импорт файлов с диска...'; en = 'Uploading files from the hard drive...'; pl = 'Importowanie plików z dysku...';de = 'Dateien von Festplatte importieren...';ro = 'Importarea fișierelor de pe disc...';tr = 'Dosyalar diskten içe aktarılıyor ...'; es_ES = 'Importando los archivos desde el disco...'");
			
			Status(StateText,
				ExecutionParameters.Indicator,
				LabelMore,
				PictureLib.Information32);
			
			// Creating Item of the FIles catalog.
			TempFileStorageAddress = "";
			
			FilesToPut = New Array;
			Details = New TransferableFileDescription(SelectedFile.FullName, "");
			FilesToPut.Add(Details);
			
			FilesThatWerePut = New Array;
			
			If Not PutFiles(FilesToPut, FilesThatWerePut, , False, ExecutionParameters.FormID) Then
				Raise StringFunctionsClientServer.SubstituteParametersToString(
					NStr("ru = 'Ошибка помещения файла
					           |""%1""
					           |во временное хранилище.'; 
					           |en = 'Cannot store file
					           |""%1""
					           |to the application.'; 
					           |pl = 'Błąd pomieszczenia pliku
					           |""%1""
					           |do repozytorium tymczasowego.';
					           |de = 'Fehler beim Platzieren der Datei
					           |""%1""
					           |im Zwischenspeicher.';
					           |ro = 'Eroare de plasare a fișierului
					           |""%1""
					           |în storagele temporar.';
					           |tr = '
					           |""%1""
					           | dosyanın geçici depolama için yerleştirme hatası.'; 
					           |es_ES = 'Error de colocar el archivo
					           |""%1""
					           |en el almacenamiento temporal.'"),
					SelectedFile.FullName);
			EndIf;
			
			If FilesThatWerePut.Count() = 1 Then
				TempFileStorageAddress = FilesThatWerePut[0].Location;
			EndIf;
			
			If NOT CommonFilesOperationsSettings().ExtractTextFilesOnServer Then
				TempTextStorageAddress = ExtractTextToTempStorage(SelectedFile.FullName,
					ExecutionParameters.FormID, , ExecutionParameters.Encoding);
			Else
				TempTextStorageAddress = "";
			EndIf;
			
			// Creating Item of the FIles catalog.
			ImportFile(SelectedFile, Owner, ExecutionParameters, TempFileStorageAddress, TempTextStorageAddress);
				
		Except
			ErrorInformation = ErrorInfo();
			
			ErrorMessage = BriefErrorDescription(ErrorInformation);
			CommonClient.MessageToUser(ErrorMessage);
			EventLogClient.AddMessageForEventLog(EventLogEvent(),
				"Error", DetailErrorDescription(ErrorInformation),,True);
			
			Record = New Structure;
			Record.Insert("FileName", SelectedFile.FullName);
			Record.Insert("Error", ErrorMessage);
			ExecutionParameters.ArrayOfFilesNamesWithErrors.Add(Record);
			
		EndTry;
	EndDo;
	
EndProcedure

Procedure ImportFile(Val SelectedFile, Val Owner, Val ExecutionParameters, Val TempFileStorageAddress, Val TempTextStorageAddress) 
	
	If FilesOperationsInternalClientCached.IsDirectoryFiles(Owner) Then
		FileInfo = FilesOperationsClientServer.FileInfo("FileWithVersion", SelectedFile);
		FileInfo.TempFileStorageAddress = TempFileStorageAddress;
		FileInfo.TempTextStorageAddress = TempTextStorageAddress;
		FileInfo.Comment = ExecutionParameters.Comment;
		FileInfo.Encoding = ExecutionParameters.Encoding;

		FileRef = FilesOperationsInternalServerCall.CreateFileWithVersion(Owner, FileInfo);
	Else
		FileParameters = New Structure;
		FileParameters.Insert("FilesOwner",              Owner);
		FileParameters.Insert("Author",                       Undefined);
		FileParameters.Insert("BaseName",            SelectedFile.BaseName);
		FileParameters.Insert("ExtensionWithoutPoint",          CommonClientServer.ExtensionWithoutPoint(SelectedFile.Extension));
		FileParameters.Insert("GroupOfFiles",                ExecutionParameters.GroupOfFiles);
		FileParameters.Insert("Modified");
		FileParameters.Insert("ModificationTimeUniversal");
		
		FileRef = FilesOperationsInternalServerCall.AppendFile(FileParameters,
												TempFileStorageAddress,
												TempTextStorageAddress,
												ExecutionParameters.Comment);
	EndIf;
	
	If ExecutionParameters.Encoding <> Undefined Then
		FilesOperationsInternalServerCall.WriteFileVersionEncoding(FileRef, ExecutionParameters.Encoding); 
	EndIf;
	
	DeleteFromTempStorage(TempFileStorageAddress);
	If Not IsBlankString(TempTextStorageAddress) Then
		DeleteFromTempStorage(TempTextStorageAddress);
	EndIf;
	
	AddedFileAndPath = New Structure("FileRef, Path", FileRef, SelectedFile.Path);
	ExecutionParameters.AddedFiles.Add(AddedFileAndPath);
	
	Record = New Structure;
	Record.Insert("FileName", SelectedFile.FullName);
	Record.Insert("File", FileRef);
	ExecutionParameters.AllFilesStructureArray.Add(Record);

EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Other internal procedures and functions.

// When renaming File and FileVersion, it updates information in the working directory (file name on 
// hard drive and in register).
//
// Parameters:
//  CurrentVersion  - CatalogRef.FilesVersions - a file version.
//  NewName       - String - a new file name.
//
Procedure RefreshInformationInWorkingDirectory(CurrentVersion, NewName) Export
	
	DirectoryName = UserWorkingDirectory();
	FullFileName = "";
	
	InWorkingDirectoryForRead = True;
	InOwnerWorkingDirectory = False;
	
	FileInWorkingDirectory = FileInLocalFilesCache(
		Undefined,
		CurrentVersion,
		FullFileName,
		InWorkingDirectoryForRead,
		InOwnerWorkingDirectory);
	
	If FileInWorkingDirectory = False Then
		Return;
	EndIf;
	
	File = New File(FullFileName);
	OnlyName = File.Name;
	FileSize = File.Size();
	PathWithoutName = Left(FullFileName, StrLen(FullFileName) - StrLen(OnlyName));
	NewFullName = PathWithoutName + NewName + File.Extension;
	MoveFile(FullFileName, NewFullName);
	
	FilesOperationsInternalServerCall.DeleteFromRegister(CurrentVersion);
	FilesOperationsInternalServerCall.PutFileInformationInRegister(CurrentVersion,
		NewFullName, DirectoryName, InWorkingDirectoryForRead, FileSize, InOwnerWorkingDirectory);
	
EndProcedure

// Reregister in the working directory with another flag ForRead if there is such a file.
// Parameters:
//  FileData  - a structure with file data.
//  ForRead - Boolean - a file is placed for reading.
//  InOwnerWorkingDirectory - Boolean - a file is in owner working directory (not in the main working directory).
Procedure ReregisterFileInWorkingDirectory(FileData, ForReading, InOwnerWorkingDirectory)
	
	// If the File does not have a file, do not do anything in the working directory.
	If FileData.Version.IsEmpty() Then 
		Return;
	EndIf;

	DirectoryName = UserWorkingDirectory();
	FullFileName = "";
	
	InWorkingDirectoryForRead = True;
	FileInWorkingDirectory = FileInLocalFilesCache(FileData, FileData.CurrentVersion, FullFileName, InWorkingDirectoryForRead, InOwnerWorkingDirectory);
	If FileInWorkingDirectory = False Then
		Return;
	EndIf;
	
	FilesOperationsInternalServerCall.PutFileInformationInRegister(FileData.CurrentVersion, FullFileName, DirectoryName, ForReading, 0, InOwnerWorkingDirectory);
	File = New File(FullFileName);
	File.SetReadOnly(ForReading);
	
EndProcedure

// The function is designed to open file using the corresponding application.
//
// Parameters:
//  FileData  - a structure with file data.
//  FileToOpenName - String - file full name.
//  OwnerID - UUID - an owner form ID.
//
Procedure OpenFileWithApplication(FileData, FileNameToOpen, OwnerID = Undefined)
	
	If Not FileSystemExtensionAttached() Then
		Return;
	EndIf;
		
	PersonalFilesOperationsSettings = PersonalFilesOperationsSettings();
	
	TextFilesOpeningMethod = PersonalFilesOperationsSettings.TextFilesOpeningMethod;
	If TextFilesOpeningMethod = PredefinedValue("Enum.OpenFileForViewingMethods.UsingBuiltInEditor") Then
		
		TextFilesExtension = PersonalFilesOperationsSettings.TextFilesExtension;
		If FilesOperationsInternalClientServer.FileExtensionInList(TextFilesExtension, FileData.Extension) Then
			
			FormParameters = New Structure;
			FormParameters.Insert("File", FileData.Ref);
			FormParameters.Insert("FileData", FileData);
			FormParameters.Insert("FileNameToOpen", FileNameToOpen);
			FormParameters.Insert("OwnerID", OwnerID);
			
			OpenForm("DataProcessor.FilesOperations.Form.EditTextFile", 
				FormParameters, , FileData.Ref);
			Return;
			
		EndIf;
		
	EndIf;
	
#If Not MobileClient Then
	If Lower(FileData.Extension) = Lower("grs") Then
		
		Schema = New GraphicalSchema; 
		Schema.Read(FileNameToOpen);
		
		FormHeader = CommonClientServer.GetNameWithExtension(
			FileData.FullVersionDescription, FileData.Extension);
		
		Schema.Show(FormHeader, FileNameToOpen);
		Return;
		
	EndIf;
#EndIf
	
	If Lower(FileData.Extension) = Lower("mxl") Then
		
		FilesToPut = New Array;
		FilesToPut.Add(New TransferableFileDescription(FileNameToOpen));
		FilesThatWerePut = New Array;
		If Not PutFiles(FilesToPut, FilesThatWerePut, , False) Then
			Return;
		EndIf;
		SpreadsheetDocument = FilesThatWerePut[0].Location;
		
		FormHeader = CommonClientServer.GetNameWithExtension(
			FileData.FullVersionDescription, FileData.Extension);
			
		OpeningParameters = New Structure;
		OpeningParameters.Insert("DocumentName", FormHeader);
		OpeningParameters.Insert("PathToFile", FileNameToOpen);
		OpeningParameters.Insert("SpreadsheetDocument", SpreadsheetDocument);
		If Not FileData.ForReading Then
			OpeningParameters.Insert("AttachedFile", FileData.Ref);
		EndIf;
		
		OpenForm("CommonForm.EditSpreadsheetDocument", OpeningParameters);
		
		Return;
		
	EndIf;
	
	// Open File
	FileSystemClient.OpenFile(FileNameToOpen);
	
EndProcedure

// Returns parameters to work with locked files.
// Returns:
//	Undefined - if there is no files being edited or you do not need to work with them.
//	Structure - a structure with passed parameters.
// 
Function CheckLockedFilesOnExit()
	
	If UsersClient.IsExternalUserSession() Then
		Return Undefined;
	EndIf;
	
	PersonalFilesOperationsSettings = StandardSubsystemsClient.ClientParameter("PersonalFilesOperationsSettings");
	ShowLockedFilesOnExit = PersonalFilesOperationsSettings.ShowLockedFilesOnExit;
	
	If Not ShowLockedFilesOnExit Then
		Return Undefined;
	EndIf;
	
	CurrentUser = UsersClient.AuthorizedUser();
	
	LockedFilesCount = StandardSubsystemsClient.ClientParameter("LockedFilesCount");
	If LockedFilesCount = 0 Then
		Return Undefined;
	EndIf;
	
	ApplicationWarningFormParameters = New Structure;
	ApplicationWarningFormParameters.Insert("MessageQuestion",      NStr("ru = 'Завершить работу с программой?'; en = 'Do you want to exit the application?'; pl = 'Czy chcesz zamknąć aplikację?';de = 'Möchten Sie die Anwendung beenden?';ro = 'Doriți să părăsiți aplicația?';tr = 'Uygulamadan çıkmak ister misiniz?'; es_ES = '¿Quiere salir de la aplicación?'"));
	ApplicationWarningFormParameters.Insert("MessageTitle",   NStr("ru = 'Следующие файлы заняты для редактирования:'; en = 'The following files are locked:'; pl = 'Następujące pliki są zajęte dla edycji:';de = 'Die folgenden Dateien sind für die Bearbeitung belegt:';ro = 'Următoarele fișiere sunt ocupate pentru editare:';tr = 'Aşağıdaki dosyalar düzenleme için kullanılıyor:'; es_ES = 'Los archivos siguientes están ocupados para editar:'"));
	ApplicationWarningFormParameters.Insert("Title",            NStr("ru = 'Завершение работы'; en = 'Exit application'; pl = 'Zamknij aplikację';de = 'Anwendung verlassen';ro = 'Ieșiți din aplicație';tr = 'Uygulamadan çık'; es_ES = 'Salir de la aplicación'"));
	ApplicationWarningFormParameters.Insert("BeingEditedBy",          CurrentUser);
	
	ApplicationWarningForm = "DataProcessor.FilesOperations.Form.LockedFilesListWithQuestion";
	Form                         = "DataProcessor.FilesOperations.Form.FilesToEdit";
	
	ReturnParameters = New Structure;
	ReturnParameters.Insert("ApplicationWarningForm", ApplicationWarningForm);
	ReturnParameters.Insert("ApplicationWarningFormParameters", ApplicationWarningFormParameters);
	ReturnParameters.Insert("Form", Form);
	ReturnParameters.Insert("ApplicationWarningForm", ApplicationWarningForm);
	ReturnParameters.Insert("LockedFilesCount", LockedFilesCount);
	
	Return ReturnParameters;
	
EndFunction

// Passing files in working directory recursively and collecting information about them.
// Parameters:
//  Path - String - a working directory path.
//  FilesArray - Array - an array of "File" objects.
//  FilesTable - Array - an array of file structures.
Procedure ProcessFilesTable(Path, FilesArray, FilesTable)
	
#If Not WebClient Then
	Var Version;
	Var PutFileDate;
	
	DirectoryName = UserWorkingDirectory();
	
	For Each SelectedFile In FilesArray Do
		
		If SelectedFile.IsDirectory() Then
			NewPath = String(Path);
			NewPath = NewPath + GetPathSeparator();
			NewPath = NewPath + String(SelectedFile.Name);
			FilesArrayInDirectory = FindFiles(NewPath, GetAllFilesMask());
			
			If FilesArrayInDirectory.Count() <> 0 Then
				ProcessFilesTable(NewPath, FilesArrayInDirectory, FilesTable);
			EndIf;
		
			Continue;
		EndIf;
		
		// Do not delete Word temporary files from the working directory.
		If StrStartsWith(SelectedFile.Name, "~") AND SelectedFile.GetHidden() Then
			Continue;
		EndIf;
		
		RelativePath = Mid(SelectedFile.FullName, StrLen(DirectoryName) + 1);
		
		// If it is not found it on the hard drive, the minimum date will be the oldest one and will be 
		//  deleted when clearing the oldest files from the working directory.
		PutFileDate = Date('00010101');
		
		FoundProperties = FilesOperationsInternalServerCall.FindInRegisterByPath(RelativePath);
		FileIsInRegister = FoundProperties.FileIsInRegister;
		Version            = FoundProperties.File;
		PutFileDate     = ?(FileIsInRegister, FoundProperties.PutFileDate, PutFileDate);
		
		If FileIsInRegister Then
			EditedByCurrentUser = FilesOperationsInternalServerCall.GetEditedByCurrentUser(Version);
			
			// If it is not locked by the current user, you can delete it.
			If Not EditedByCurrentUser Then
				Record = New Structure;
				Record.Insert("Path", RelativePath);
				Record.Insert("Size", SelectedFile.Size());
				Record.Insert("Version", Version);
				Record.Insert("PutFileInWorkingDirectoryDate", PutFileDate);
				FilesTable.Add(Record);
			EndIf;
		Else
			Record = New Structure;
			Record.Insert("Path", RelativePath);
			Record.Insert("Size", SelectedFile.Size());
			Record.Insert("Version", Version);
			Record.Insert("PutFileInWorkingDirectoryDate", PutFileDate);
			FilesTable.Add(Record);
		EndIf;
		
	EndDo;
#EndIf
	
EndProcedure

// Receives a relative path to file in working directory. If the information register has the path, 
// receiving it from there and if not, generating it and writing to the information register.
//
// Parameters:
//  FileData  - a structure with file data.
//
// Returns:
//   String  - a file path
Function GetFilePathInWorkingDirectory(FileData)
	
	PathToReturn = "";
	FullFileName = "";
	DirectoryName = UserWorkingDirectory();
	
	// First try to find such a record in the information register.
	FullFileName = FileData.FullFileNameInWorkingDirectory;
	
	If FullFileName <> "" Then
		// Also look whether the hard drive has it.
		FileOnHardDrive = New File(FullFileName);
		If FileOnHardDrive.Exist() Then
			Return FullFileName;
		EndIf;
	EndIf;
	
	// Generating a file name with an extension.
	FileName = FileData.FullVersionDescription;
	Extension = FileData.Extension;
	If Not IsBlankString(Extension) Then 
		FileName = CommonClientServer.GetNameWithExtension(FileName, Extension);
	EndIf;
	
	FullFileName = "";
	If Not IsBlankString(FileName) Then
		If Not IsBlankString(FileData.OwnerWorkingDirectory) Then
			FullFileName = FileData.OwnerWorkingDirectory + FileData.FullVersionDescription + "." + FileData.Extension;
		Else
			FullFileName = FilesOperationsInternalClientServer.GetUniqueNameWithPath(DirectoryName, FileName);
		EndIf;
	EndIf;
	
	If IsBlankString(FileName) Then
		Return "";
	EndIf;
	
	// Writing file name to the register.
	ForReading = True;
	InOwnerWorkingDirectory = FileData.OwnerWorkingDirectory <> "";
	FilesOperationsInternalServerCall.WriteFullFileNameToRegister(FileData.Version, FullFileName, ForReading, InOwnerWorkingDirectory);
	
	If FileData.OwnerWorkingDirectory = "" Then
		PathToReturn = DirectoryName + FullFileName;
	Else
		PathToReturn = FullFileName;
	EndIf;
	
	Return PathToReturn;
	
EndFunction

////////////////////////////////////////////////////////////////////////////////
// AUXILIARY PROCEDURES AND FUNCTIONS

// Returns a structure that contains various personal settings.
Function PersonalFilesOperationsSettings() Export
	
	PersonalSettings =
		StandardSubsystemsClient.ClientRunParameters().PersonalFilesOperationsSettings;
	
	// Checking and updating the settings that are stored on the server and calculated on the client.
	// 
	
	Return PersonalSettings;
	
EndFunction

// Returns a structure that contains various personal settings.
Function CommonFilesOperationsSettings()
	
	CommonSettings = StandardSubsystemsClient.ClientRunParameters().CommonFilesOperationsSettings;
	
	// Checking and updating the settings that are stored on the server and calculated on the client.
	// 
	
	Return CommonSettings;
	
EndFunction

// Whether working directory has File for the specified version.
// Parameters:
//  FileData  - a structure with file data.
//
// Returns:
//  Boolean  - file is in the working directory.
//  CurrentVersion  - CatalogRef.FilesVersions - a file version.
//  FullFileName - String - name of the file with a path.
//  InWorkingdirectoryForRead - Boolean - a file is placed for reading.
//  InOwnerWorkingDirectory - Boolean - a file is in owner working directory (not in the main working directory).
Function FileInLocalFilesCache(FileData, CurrentVersion, FullFileName, InWorkingDirectoryForRead, InOwnerWorkingDirectory)
	FullFileName = "";
	
	// If it is an active version, take it from the FileData.
	If FileData <> Undefined AND FileData.CurrentVersion = CurrentVersion Then
		FullFileName = FileData.FullFileNameInWorkingDirectory;
		InWorkingDirectoryForRead = FileData.InWorkingDirectoryForRead;
	Else
		InWorkingDirectoryForRead = True;
		DirectoryName = UserWorkingDirectory();
		// Try to find such a record in the information register.
		FullFileName = FilesOperationsInternalServerCall.GetFullFileNameFromRegister(CurrentVersion, DirectoryName, InWorkingDirectoryForRead, InOwnerWorkingDirectory);
	EndIf;
	
	If FullFileName <> "" Then
		// Also look whether the hard drive has it.
		FileOnHardDrive = New File(FullFileName);
		If FileOnHardDrive.Exist() Then
			Return True;
		Else
			FullFileName = "";
			// Deleting it from the register immediately, because register has it but hard drive does not.
			FilesOperationsInternalServerCall.DeleteFromRegister(CurrentVersion);
		EndIf;
	EndIf;
	
	Return False;
	
EndFunction

// Select a path to the working directory.
// Parameters:
//  DirectoryName  - String - previous name of the directory.
//  Title  - String - a title of the form of directory path selection.
//  OwnerWorkingDirectory - String-  a working directory of the owner.
//
// Returns:
//   Boolean  - shows whether the operation is performed successfully.
Function ChoosePathToWorkingDirectory(DirectoryName, Title, OwnerWorkingDirectory) Export
	
	Mode = FileDialogMode.ChooseDirectory;
	OpenFileDialog = New FileDialog(Mode);
	OpenFileDialog.FullFileName = "";
	OpenFileDialog.Directory = DirectoryName;
	OpenFileDialog.Multiselect = False;
	OpenFileDialog.Title = Title;
	
	If OpenFileDialog.Choose() Then
		
		DirectoryName = OpenFileDialog.Directory;
		DirectoryName = CommonClientServer.AddLastPathSeparator(DirectoryName);
		
		// Creating a directory for files
		Try
			CreateDirectory(DirectoryName);
			TestDirectoryName = DirectoryName + "CheckAccess\";
			CreateDirectory(TestDirectoryName);
			DeleteFiles(TestDirectoryName);
		Except
			// Not authorized to create a directory, or this path does not exist.
			
			ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'Неверный путь или отсутствуют права на запись в каталог
				           |""%1"".'; 
				           |en = 'Invalid path or insufficient rights to write to directory
				           |""%1"".'; 
				           |pl = 'Nieprawidłowa ścieżka lub brak prawa do zapisu w katalogu
				           |""%1"".';
				           |de = 'Falscher Pfad oder keine Schreibrechte auf das Verzeichnis
				           |""%1"".';
				           |ro = 'Traseu incorect sau lipsesc drepturile pentru înregistrare în directorul
				           |""%1"".';
				           |tr = '""%1"" 
				           |dizinine yazmak için yanlış yol veya yetersiz haklar.'; 
				           |es_ES = 'Ruta incorrecta o no hay derechos de guardar en el catálogo
				           |""%1"".'"),
				DirectoryName);
			ShowMessageBox(, ErrorText);
			Return False;
		EndTry;
		
		If OwnerWorkingDirectory = False Then
#If Not WebClient Then
			FilesArrayInDirectory = FindFiles(DirectoryName, GetAllFilesMask());
			If FilesArrayInDirectory.Count() <> 0 Then
				ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("ru = 'В выбранном рабочем каталоге
					           |""%1""
					           |уже есть файлы.
					           |
					           |Выберите другой каталог.'; 
					           |en = 'The selected working directory 
					           |""%1""
					           |contains files.
					           |
					           |Please select another directory.'; 
					           |pl = 'W wybranym katalogu roboczym
					           |""%1""
					           |są już pliki.
					           |
					           |Wybierz inny katalog.';
					           |de = 'Im ausgewählten Arbeitsverzeichnis
					           |""%1""
					           |befinden sich bereits Dateien.
					           |
					           |Wählen Sie ein anderes Verzeichnis aus.';
					           |ro = 'În directorul selectat
					           |""%1""
					           |deja există fișiere.
					           |
					           |Selectați alt director.';
					           |tr = 'Seçilen çalışma dizininde %1 "
"
					           | zaten dosyalar var. 
					           |
					           |Başka bir dizin seçin.'; 
					           |es_ES = 'En el catálogo en función seleccionado
					           |""%1""
					           |ya hay archivos. 
					           |
					           |Seleccione otro catálogo.'"),
					DirectoryName);
				ShowMessageBox(, ErrorText);
				Return False;
			EndIf;
#EndIf
		EndIf;
		
		Return True;
	EndIf;
	
	Return False;
	
EndFunction

// Reregister it In working directory with another ForRead flag.
// Parameters:
//  CurrentVersion  - CatalogRef.FilesVersions - a file version.
//  FullFileName - String - a full file name.
//  ForRead - Boolean - a file is placed for reading.
//  InOwnerWorkingDirectory - Boolean - a file is in owner working directory (not in the main working directory).
Procedure RegegisterInWorkingDirectory(CurrentVersion, FullFileName, ForReading, InOwnerWorkingDirectory)
	
	DirectoryName = UserWorkingDirectory();
	
	FilesOperationsInternalServerCall.PutFileInformationInRegister(CurrentVersion, FullFileName, DirectoryName, ForReading, 0, InOwnerWorkingDirectory);
	File = New File(FullFileName);
	File.SetReadOnly(ForReading);
	
EndProcedure

// Passing files in working directory recursively to determine the size of files.
// Parameters:
//  FilesArray - Array - an array of "File" objects.
//  TooBigFilesArray - Array - an array of files.
//  Recursively - Boolean - pass subdirectories recursively.
//  TotalCount - Number - total number of imported files.
//  PseudoFileSystem - Map - file system emulation, returns an array of strings (subdirectories and 
//                                         files) for a string (directory).
//
Procedure FindTooBigFiles(
				FilesArray,
				ArrayOfTooBigFiles,
				Recursively,
				TotalCount,
				Val PseudoFileSystem) 
	
	MaxFileSize = CommonFilesOperationsSettings().MaxFileSize;
	
	For Each SelectedFile In FilesArray Do
		
		If SelectedFile.Exist() Then
			
			If SelectedFile.Extension = ".lnk" Then
				SelectedFile = DereferenceLnkFile(SelectedFile);
			EndIf;
			
			If SelectedFile.IsDirectory() Then
				
				If Recursively Then
					NewPath = String(SelectedFile.Path);
					NewPath = CommonClientServer.AddLastPathSeparator(NewPath);
					NewPath = NewPath + String(SelectedFile.Name);
					FilesArrayInDirectory = FindFilesPseudo(PseudoFileSystem, NewPath);
					
					// Recursion
					If FilesArrayInDirectory.Count() <> 0 Then
						FindTooBigFiles(FilesArrayInDirectory, ArrayOfTooBigFiles, Recursively, TotalCount, PseudoFileSystem);
					EndIf;
				EndIf;
			
				Continue;
			EndIf;
			
			TotalCount = TotalCount + 1;
			
			// A file size is too big.
			If SelectedFile.Size() > MaxFileSize Then
				ArrayOfTooBigFiles.Add(SelectedFile.FullName);
				Continue;
			EndIf;
		
		EndIf;
	EndDo;
	
EndProcedure

// Returns an array of files, emulating the work of FindFiles, not by file system, but by Map. If 
//  PseudoFileSystem is blank, it works with the file system.
Function FindFilesPseudo(Val PseudoFileSystem, Path)
	
	If PseudoFileSystem.Count() = 0 Then
		Files = FindFiles(Path, GetAllFilesMask());
		Return Files;
	EndIf;
	
	Files = New Array;
	
	ValueFound = PseudoFileSystem.Get(String(Path));
	If ValueFound <> Undefined Then
		For Each FileName In ValueFound Do
			FileFromList = New File(FileName);
			Files.Add(FileFromList);
		EndDo;
	EndIf;
	
	Return Files;
	
EndFunction

// Dereference the lnk file
// Parameters:
//  SelectedFile - File - a File type object.
//
// Returns:
//   String - the item, which the link file refers to.
Function DereferenceLnkFile(SelectedFile)
	
#If Not WebClient AND NOT MobileClient Then
	ShellApp = New COMObject("shell.application");
	FolderObj = ShellApp.NameSpace(SelectedFile.Path);// Full path to lnk file (only).
	FolderObjItem = FolderObj.items().item(SelectedFile.Name); 	// only lnk file name
	Link = FolderObjItem.GetLink();
	Return New File(Link.path);
#EndIf
	
	Return SelectedFile;
	
EndFunction

////////////////////////////////////////////////////////////////////////////////
// Comparing versions and files.
// Compares 2 files (txt doc doc odt mxl) using Microsift Office or OpenOffice from 1C:Enterprise script for spreadsheet documents.
Procedure CompareFiles(FormID, FirstFile, SecondFile, Extension, VersionOwner = Undefined) Export
	
	FileVersionsComparisonMethod = Undefined;
	
	ExtensionSupported = (
	Extension = "txt"
	OR Extension = "doc"
	OR Extension = "docx"
	OR Extension = "rtf"
	OR Extension = "htm"
	OR Extension = "html"
	OR Extension = "mxl"
	OR Extension = "odt");
	
	If Not ExtensionSupported Then
		WarningText =
		NStr("ru = 'Сравнение файлов поддерживается только для файлов следующих типов: 
			|   Текстовый документ (.txt)
			|   Документ формата RTF (.rtf) 
			|   Документ Microsoft Word (.doc, .docx) 
			|   Документ HTML (.html .htm) 
			|   Табличный документ (.mxl) 
			|   Текстовый документ OpenDocument (.odt)'; 
			|en = 'Comparison is supported only for the following file types: 
			|   Text document (.txt)
			|   RTF document (.rtf) 
			|   Microsoft Word document (.doc, .docx)  
			|   HTML document (.html, .htm) 
			|   Spreadsheet document (.mxl) 
			|   OpenDocument text (.odt)'; 
			|pl = 'Porównywanie plików jest obsługiwane tylko dla plików następujących rodzajów:
			| Dokument tekstowy (.txt)
			| Dokument w formacie RTF (.rtf) 
			|Dokument Microsoft Word (.doc, .docx)
			| Dokument HTML (.html .htm) 
			|Dokument tabelaryczny (.mxl) 
			|Dokument tekstowy OpenDocument (.odt)';
			|de = 'Der Dateivergleich wird nur für folgende Dateitypen unterstützt: 
			|Textdokument (.txt)
			|  RTF-Dokument (.rtf) 
			|  Microsoft Word-Dokument (.doc,.docx) 
			|  HTML-Dokument (.html.htm) 
			|  Tabellen-Dokument (.mxl) 
			|  Textdokument OpenDocument (.odt)';
			|ro = 'Compararea fișierelor este susținută numai pentru fișierele de următoarele tipuri: 
			|   Documentul text (.txt)
			|   Documentul de format RTF (.rtf) 
			|   Documentul Microsoft Word (.doc, .docx) 
			|   Documentul HTML (.html .htm) 
			|   Documentul tabelar (.mxl) 
			|   Documentul text OpenDocument (.odt)';
			|tr = 'Dosya karşılaştırması yalnızca aşağıdaki türdeki dosyalar için destekleniyor: 
			|Metin belgesi (.txt) 
			| RTF belge (.rtf), 
			|Microsoft Word Belgesi (.doc .docx) 
			|HTML belgesi (.html .htm) 
			|Tablo belgesi (.mxl) 
			|OpenDocument Metin belgesi (.odt)'; 
			|es_ES = 'La comparación de los archivos se admite solo para los archivos de los siguientes tipos: 
			|   Documento de texto (.txt)
			|   Documento del formato RTF (.rtf) 
			|   Documento Microsoft Word (.doc, .docx) 
			|   Documento HTML (.html .htm) 
			|   Documento de tabla (.mxl) 
			|   Documento de texto OpenDocument (.odt)'");
		ShowMessageBox(, WarningText);
		Return;
	EndIf;
	
	If Extension = "odt" Then
		FileVersionsComparisonMethod = "OpenOfficeOrgWriter";
	ElsIf Extension = "htm" OR Extension = "html" Then
		FileVersionsComparisonMethod = "MicrosoftOfficeWord";
	ElsIf Extension = "mxl" Then
		FileVersionsComparisonMethod = "CompareSpreadsheetDocuments";
	EndIf;
	
	ExecutionParameters = New Structure;
	ExecutionParameters.Insert("FileVersionsComparisonMethod", FileVersionsComparisonMethod);
	ExecutionParameters.Insert("CurrentStep",              1);
	ExecutionParameters.Insert("File1Data",            Undefined);
	ExecutionParameters.Insert("File2Data",            Undefined);
	ExecutionParameters.Insert("Result1",              Undefined);
	ExecutionParameters.Insert("Result2",              Undefined);
	ExecutionParameters.Insert("FullFileName1",         Undefined);
	ExecutionParameters.Insert("FullFileName2",         Undefined);
	ExecutionParameters.Insert("UUID", FormID);
	ExecutionParameters.Insert("Ref1",                 FirstFile);
	ExecutionParameters.Insert("Ref2",                 SecondFile);
	ExecutionParameters.Insert("VersionOwner",          VersionOwner);
	
	FillCompareParameters(-1, ExecutionParameters);
	
EndProcedure

Procedure FillCompareParameters(Result, ExecutionParameters) Export
	
	If Result <> -1 Then
		If ExecutionParameters.CurrentStep = 1 Then
			If Result <> DialogReturnCode.OK Then
				Return;
			EndIf;
			
			PersonalSettings = PersonalFilesOperationsSettings();
			ExecutionParameters.FileVersionsComparisonMethod = PersonalSettings.FileVersionsComparisonMethod;
			
			If ExecutionParameters.FileVersionsComparisonMethod = Undefined Then
				Return;
			EndIf;
			ExecutionParameters.CurrentStep = 2;
			
		ElsIf ExecutionParameters.CurrentStep = 3 Then
			ExecutionParameters.Result1      = Result.FileReceived;
			ExecutionParameters.FullFileName1 = Result.FullFileName;
			ExecutionParameters.CurrentStep = 4;
			
		ElsIf ExecutionParameters.CurrentStep = 4 Then
			ExecutionParameters.Result2      = Result.FileReceived;
			ExecutionParameters.FullFileName2 = Result.FullFileName;
			ExecutionParameters.CurrentStep = 5;
		EndIf;
	EndIf;
	
	If ExecutionParameters.CurrentStep = 1 Then
		If ExecutionParameters.FileVersionsComparisonMethod = Undefined Then
			
			PersonalSettings = PersonalFilesOperationsSettings();
			ExecutionParameters.FileVersionsComparisonMethod = PersonalSettings.FileVersionsComparisonMethod;
			
			If ExecutionParameters.FileVersionsComparisonMethod = Undefined Then
				// First call means that setting has not been initialized yet.
				Handler = New NotifyDescription("FillCompareParameters", ThisObject, ExecutionParameters);
				OpenForm("DataProcessor.FilesOperations.Form.SelectVersionCompareMethod", ,
					ThisObject, , , , Handler);
				Return;
			EndIf;
		EndIf;
		ExecutionParameters.CurrentStep = 2;
	EndIf;
	
	If ExecutionParameters.CurrentStep = 2 Then
		
		If ExecutionParameters.Property("VersionOwner") AND ValueIsFilled(ExecutionParameters.VersionOwner) Then
			ExecutionParameters.File1Data = FilesOperationsInternalServerCall.FileDataToOpen(
				ExecutionParameters.VersionOwner, ExecutionParameters.Ref1, ExecutionParameters.UUID);
			ExecutionParameters.File2Data = FilesOperationsInternalServerCall.FileDataToOpen(
				ExecutionParameters.VersionOwner ,ExecutionParameters.Ref2, ExecutionParameters.UUID);
		Else
			ExecutionParameters.File1Data = FilesOperationsInternalServerCall.FileDataToOpen(
				ExecutionParameters.Ref1, Undefined, ExecutionParameters.UUID);
			ExecutionParameters.File2Data = FilesOperationsInternalServerCall.FileDataToOpen(
				ExecutionParameters.Ref2, Undefined, ExecutionParameters.UUID);
		EndIf;
		
		ExecutionParameters.CurrentStep = 3;
	EndIf;
	
	If ExecutionParameters.CurrentStep = 3 Then
		Handler = New NotifyDescription("FillCompareParameters", ThisObject, ExecutionParameters);
		GetVersionFileToWorkingDirectory(
			Handler, ExecutionParameters.File1Data, ExecutionParameters.FullFileName1);
		Return;
	EndIf;
	
	If ExecutionParameters.CurrentStep = 4 Then
		Handler = New NotifyDescription("FillCompareParameters", ThisObject, ExecutionParameters);
		GetVersionFileToWorkingDirectory(
			Handler, ExecutionParameters.File2Data, ExecutionParameters.FullFileName2);
		Return;
	EndIf;
	
	If ExecutionParameters.CurrentStep = 5 Then
		If ExecutionParameters.Result1 AND ExecutionParameters.Result2 Then
			FileTitleTemplate = NStr("ru='Файл №%1 (%2)'; en = 'File #%1 (%2)'; pl = 'Plik №%1 (%2)';de = 'Dateinummer%1(%2)';ro = 'Fișierul Nr.%1 (%2)';tr = 'Dosya №%1 (%2)'; es_ES = 'Archivo №%1 (%2)'");
			File1Name = CommonClientServer.GetNameWithExtension(
				ExecutionParameters.File1Data.FullVersionDescription,
				ExecutionParameters.File1Data.Extension);
			File1Title = StringFunctionsClientServer.SubstituteParametersToString(
				FileTitleTemplate,
				File1Name,
				ExecutionParameters.File1Data.VersionNumber);
				
			File2Name = CommonClientServer.GetNameWithExtension(
				ExecutionParameters.File2Data.FullVersionDescription,
				ExecutionParameters.File2Data.Extension);
			File2Title = StringFunctionsClientServer.SubstituteParametersToString(
				FileTitleTemplate,
				File2Name,
				ExecutionParameters.File2Data.VersionNumber);
				
			If ExecutionParameters.File1Data.VersionNumber < ExecutionParameters.File2Data.VersionNumber Then
				FullFileNameLeft  = ExecutionParameters.FullFileName1;
				FileTitleLeft  = File1Title;
				FullFileNameRight = ExecutionParameters.FullFileName2;
				FileTitleRight = File2Title;
			Else
				FullFileNameLeft  = ExecutionParameters.FullFileName2;
				FileTitleLeft  = File2Title;
				FullFileNameRight = ExecutionParameters.FullFileName1;
				FileTitleRight = File1Title;
			EndIf;
				
			ExecuteCompareFiles(
				FullFileNameLeft,
				FullFileNameRight,
				ExecutionParameters.FileVersionsComparisonMethod,
				FileTitleLeft,
				FileTitleRight);
		EndIf;
	EndIf;
	
EndProcedure

Procedure ExecuteCompareFiles(File1Path, File2Path, FileVersionsComparisonMethod, TitleLeft = "", TitleRight = "") Export
	
#If Not WebClient AND NOT MobileClient Then
	
	Try
		If FileVersionsComparisonMethod = "MicrosoftOfficeWord" Then
			WordObject = New COMObject("Word.Application");
			WordObject.Visible = 0;
			WordObject.WordBasic.DisableAutoMacros(1);
			
			Document = WordObject.Documents.Open(File1Path);
			
			Document.Merge(File2Path, 2, 0, 0); // MergeTarget:=wdMergeTargetSelected, DetectFormatChanges:=False, UseFormattingFrom:=wdFormattingFromCurrent
			
			WordObject.Visible = 1;
			WordObject.Activate();
			
			Document.Close();
		ElsIf FileVersionsComparisonMethod = "OpenOfficeOrgWriter" Then 
			
			// Removing readonly, otherwise, it will not work.
			File1 = New File(File1Path);
			File1.SetReadOnly(False);
			
			File2 = New File(File2Path);
			File2.SetReadOnly(False);
			
			// Open OpenOffice
			ServiceManager = New COMObject("com.sun.star.ServiceManager");
			Desktop = ServiceManager.createInstance("com.sun.star.frame.Desktop");
			Dispatcher = ServiceManager.createInstance("com.sun.star.frame.DispatchHelper");
			
			// Opening parameters: disabling macros.
			DocumentParameters = New COMSafeArray("VT_VARIANT", 1);
			StartMode = AssignValueToProperty(ServiceManager,
				"MacroExecutionMode",
				0); // const short NEVER_EXECUTE = 0
			DocumentParameters.SetValue(0, StartMode);
			
			// Open OpenOffice document.
			Desktop.loadComponentFromURL(ConvertToURL(File2Path), "_blank", 0, DocumentParameters);
			
			frame = Desktop.getCurrentFrame();
			
			// Set showing changes.
			CompareParameters = New COMSafeArray("VT_VARIANT", 1);
			CompareParameters.SetValue(0, AssignValueToProperty(ServiceManager, "ShowTrackedChanges", True));
			dispatcher.executeDispatch(frame, ".uno:ShowTrackedChanges", "", 0, CompareParameters);
			
			// Compare with the document.
			CallParameters = New COMSafeArray("VT_VARIANT", 1);
			CallParameters.SetValue(0, AssignValueToProperty(ServiceManager, "URL", ConvertToURL(File1Path)));
			dispatcher.executeDispatch(frame, ".uno:CompareDocuments", "", 0, CallParameters);
			
		ElsIf FileVersionsComparisonMethod = "CompareSpreadsheetDocuments" Then
			
			FilesToPut = New Array;
			FilesToPut.Add(New TransferableFileDescription(File1Path));
			FilesToPut.Add(New TransferableFileDescription(File2Path));
			FilesThatWerePut = New Array;
			If Not PutFiles(FilesToPut, FilesThatWerePut, , False) Then
				Return;
			EndIf;
			SpreadsheetDocumentLeft  = FilesThatWerePut[0].Location;
			SpreadsheetDocumentRight = FilesThatWerePut[1].Location;
			
			SpreadsheetDocumentsStructure = New Structure("Left, Right", SpreadsheetDocumentLeft, SpreadsheetDocumentRight);
			SpreadsheetDocumentsAddress = PutToTempStorage(SpreadsheetDocumentsStructure, Undefined);
			
			FormOpenParameters = New Structure("SpreadsheetDocumentsAddress, TitleLeft, TitleRight", 
				SpreadsheetDocumentsAddress, TitleLeft, TitleRight);
			OpenForm("CommonForm.CompareSpreadsheetDocuments", FormOpenParameters, ThisObject);
		EndIf;
		
	Except
		
		ErrorMessage = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Не удалось сравнить файлы по причине: %1'; en = 'Cannot compare the files. Reason: %1'; pl = 'Nie można porównać pliku z powodu:%1';de = 'Konnte die Dateien aus dem folgenden Grund nicht vergleichen: %1 ';ro = 'Eșec la compararea fișierelor din motivul: %1';tr = 'Aşağıdakiler nedeniyle dosyalar karşılaştırılamıyor:%1'; es_ES = 'No se ha podido comparar archivos a causa de: %1'"),
			BriefErrorDescription(ErrorInfo()));
			
		EventLogClient.AddMessageForEventLog(
			NStr("ru = 'Файлы. Сравнение файлов'; en = 'Files. File comparison'; pl = 'Pliki. Porównanie plików';de = 'Dateien. Vergleich von Dateien';ro = 'Fișiere. Compararea fișierelor';tr = 'Dosyaları. Dosya karşılaştırması'; es_ES = 'Archivos. Comparación de archivos'", CommonClient.DefaultLanguageCode()),
			"Error", ErrorMessage, , True);
		
		Raise ErrorMessage;
		
	EndTry;
	
#EndIf
	
EndProcedure

// The function converts a Windows file name into OpenOffice URL.
Function ConvertToURL(FileName)
	
	Return "file:///" + StrReplace(FileName, "\", "/");
	
EndFunction

// Creating a structure for OpenOffice parameters.
Function AssignValueToProperty(Object, PropertyName, PropertyValue)
	
	Properties = Object.Bridge_GetStruct("com.sun.star.beans.PropertyValue");
	Properties.Name = PropertyName;
	Properties.Value = PropertyValue;
	
	Return Properties;
	
EndFunction

// Returns the user data directory inside the standard directory of application data.
// This directory can be used to store files locked by the current user.
// This method requires the file system extension installed to operate in the web client.
//
Function UserDataDir()
	
	#If WebClient Or MobileClient Then
		Return UserDataWorkDir();
	#Else
		If Not CommonClient.IsWindowsClient() Then
			Return UserDataWorkDir();
		Else
			Shell = New COMObject("WScript.Shell");
			UserDataDir = Shell.ExpandEnvironmentStrings("%APPDATA%");
			Return CommonClientServer.AddLastPathSeparator(UserDataDir);
		EndIf;
	#EndIf
	
EndFunction

// Opens the form to drag items.
Procedure OpenDragFormFromOutside(FolderForAdding, FileNamesArray) Export
	
	FormParameters = New Structure;
	FormParameters.Insert("FolderForAdding", FolderForAdding);
	FormParameters.Insert("FileNamesArray",   FileNamesArray);
	
	OpenForm("Catalog.Files.Form.DragForm", FormParameters);
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Internal procedures and functions for asynchronous methods.
//
// Common parameter description:
//   Handler - NotifyDescription, Undefined, Structure - a handler procedure for asynchronous method.
//       * Undefined       - processing is not required.
//       * NotifyDescription - a handler procedure description.
//     In rare cases, it can be necessary to abort the execution of the code only when it is 
//     necessary to show an asynchronous dialog box (in cycles, for example).
//     In such cases, the Handler receives the parameter Structure of the calling code with the 
//     required AsynchronousDialogBox key, which is used when interrupting the code and opening the 
//     asynchronous dialog box:
//       * Structure - a structure of the calling code parameters.
//           ** AsynchronousDIalogBox - Structure -
//               *** Open       - Boorean - True if the dialog box was opened.
//               *** ProcedureName - String - a procedure name of the calling code handler.
//               *** Module       - CommonModule, ManagedForm - a module of the calling code handler.
//             In this case, NotifyDescription is generated from the ProcedureName and Module keys.
//             Attention. Not all asynchronous procedures support passing of the Structure type. Read the composition of types.
//
//   Result - Arbitrary - the result that needs to be returned to Handler.
//

// Shows a notification dialog box and then, once the dialog box is closed, calls the handler and passes the user input to that handler.
Procedure ReturnResultAfterShowWarning(Handler, WarningText, Result)
	
	If Handler <> Undefined Then
		HandlerParameters = New Structure;
		HandlerParameters.Insert("Handler", PrepareHandlerForDialog(Handler));
		HandlerParameters.Insert("Result", Result);
		Handler = New NotifyDescription("ReturnResultAfterCloseSimpleDialog", ThisObject, HandlerParameters);
		ShowMessageBox(Handler, WarningText);
	Else
		ShowMessageBox(, WarningText);
	EndIf;
	
EndProcedure

// Shows a value view window and then, once it is closed, calls the handler and passes the user input to that handler.
Procedure ReturnResultAfterShowValue(Handler, Value, Result)
	
	If Handler <> Undefined Then
		HandlerParameters = New Structure;
		HandlerParameters.Insert("Handler", PrepareHandlerForDialog(Handler));
		HandlerParameters.Insert("Result", Result);
		Handler = New NotifyDescription("ReturnResultAfterCloseSimpleDialog", ThisObject, HandlerParameters);
		ShowValue(Handler, Value);
	Else
		ShowValue(, Value);
	EndIf;
	
EndProcedure

// Continuation of the procedure (see above).
Procedure ReturnResultAfterCloseSimpleDialog(Structure) Export
	
	If TypeOf(Structure.Handler) = Type("NotifyDescription") Then
		ExecuteNotifyProcessing(Structure.Handler, Structure.Result);
	EndIf;
	
EndProcedure

// Returns the direct call result when the dialog box was not opened.
Procedure ReturnResult(Handler, Result) Export
	
	Handler = PrepareHandlerForDirectCall(Handler, Result);
	If TypeOf(Handler) = Type("NotifyDescription") Then
		ExecuteNotifyProcessing(Handler, Result);
	EndIf;
	
EndProcedure

// Writes information required to prepare the handler of asynchronous dialog box.
Procedure RegisterHandlerDetails(ExecutionParameters, Module, ProcedureName) Export
	
	ExecutionParameters.Insert("AsynchronousDialog", New Structure);
	ExecutionParameters.AsynchronousDialog.Insert("Module",                 Module);
	ExecutionParameters.AsynchronousDialog.Insert("ProcedureName",           ProcedureName);
	ExecutionParameters.AsynchronousDialog.Insert("Open",                 False);
	ExecutionParameters.AsynchronousDialog.Insert("ResultWhenNotOpen", Undefined);
	
EndProcedure

// Prepares a handler for an asynchronous dialog.
Function PrepareHandlerForDialog(HandlerOrStructure) Export
	
	If TypeOf(HandlerOrStructure) = Type("Structure") Then
		// Recursive registration of all caller script handlers.
		If HandlerOrStructure.Property("ResultHandler") Then
			HandlerOrStructure.ResultHandler = PrepareHandlerForDialog(HandlerOrStructure.ResultHandler);
		EndIf;
		If HandlerOrStructure.Property("AsynchronousDialog") Then
			// Registration of the opened dialog.
			HandlerOrStructure.AsynchronousDialog.Open = True;
			// Handler creation (and fixing the entire parameter structure).
			Handler = New NotifyDescription(
				HandlerOrStructure.AsynchronousDialog.ProcedureName,
				HandlerOrStructure.AsynchronousDialog.Module,
				HandlerOrStructure);
		Else
			Handler = Undefined;
		EndIf;
	Else
		Handler = HandlerOrStructure;
	EndIf;
	
	Return Handler;
	
EndFunction

// Preparing the result of direct call handler without opening the dialog box.
Function PrepareHandlerForDirectCall(HandlerOrStructure, Result)
	
	If TypeOf(HandlerOrStructure) = Type("Structure") Then
		If HandlerOrStructure.Property("AsynchronousDialog") Then
			HandlerOrStructure.AsynchronousDialog.ResultWhenNotOpen = Result;
		EndIf;
		Return Undefined; // The handler for dialog box was not prepared => The calling code did not stop.
	Else
		Return HandlerOrStructure;
	EndIf;
	
EndFunction

////////////////////////////////////////////////////////////////////////////////
// Executes a batch of non-interactive actions with a file.
// If the file does not exist, actions will not be skipped.
//
// You can get the following properties: Name, BaseName, FullName, Path, Extention, Exists,
//    ModificationTime, UnivarsalModificationTime, ReadOnly, Invisibility, Size, IsDirectory, IsFile.
//
// You can set the following properties: ModificationTime, UniversalModificationTime, ReadOnly, and Invisibility.
// Can perform the following file operations: Delete.
//
// Parameters:
//  Notification - NotifyDescription - a notification that runs after executing actions with the 
//   file. As a result the Structure returns with the following properties:
//     * ErrorDescription - String - an error text if one of the actions is not performed.
//     * Results     - Array - contains the result by each action as a structure:
//             * File       - File - an initialized object file.
//                          - Undefined - an error of file initialization.
//             * Exists - Boolean - False if the file does not exist.
//
//  ActionsWithFile - Array - containing structures with name and parameters of the action.
//    * Actions - String    - GetProperties, SetProperties, Delete, CopyFromSource,
//                             CreateDirectory, Get, or Put.
//    * File     - String    - a full file name on the computer.
//               - File      - File - an initialized object File.
//    * Properties - Structure - see properties that you can receive or set.
//    * Source - String    - a full name of the file on the computer, from which you need to create a copy.
//    * Address    - String    - an address of the file binary data, for example, a temporary storage address.
//    * ErrorTitle - String - the text, to which you need to add a line break and an error presentation.
//
Procedure ProcessFile(Notification, FileOperations, FormID = Undefined)
	
	Context = New Structure;
	Context.Insert("Notification",         Notification);
	Context.Insert("FileOperations",    FileOperations);
	Context.Insert("FormID", FormID);
	
	Context.Insert("ActionsResult", New Structure);
	Context.ActionsResult.Insert("ErrorDescription", "");
	Context.ActionsResult.Insert("Results", New Array);
	
	Context.Insert("IndexOf", -1);
	ProcessFileLoopStart(Context);
	
EndProcedure

// Continue the ProcessFile procedure.
Procedure ProcessFileLoopStart(Context)
	
	If Context.IndexOf + 1 >= Context.FileOperations.Count() Then
		ExecuteNotifyProcessing(Context.Notification, Context.ActionsResult);
		Return;
	EndIf;
	
	Context.IndexOf = Context.IndexOf + 1;
	Context.Insert("ActionDetails", Context.FileOperations[Context.IndexOf]);
	
	Context.Insert("Result",  New Structure);
	Context.Result.Insert("File", Undefined);
	Context.Result.Insert("Exist", False);
	
	Context.ActionsResult.Results.Add(Context.Result);
	
	Context.Insert("PropertiesForGetting", New Structure);
	Context.Insert("PropertiesForInstalling", New Structure);
	
	Action = Context.ActionDetails.Action;
	File = Context.ActionDetails.File;
	FullFileName = ?(TypeOf(File) = Type("File"), File.FullName, File);
	
	If Action = "Delete" Then
		BeginDeletingFiles(New NotifyDescription(
			"ProcessFileAfterDeleteFiles", ThisObject, Context,
			"ProcessFileAfterError", ThisObject), FullFileName);
		Return;
	
	ElsIf Action = "CopyFromSource" Then
		BeginCopyingFile(New NotifyDescription(
			"ProcessFileAfterCopyFile", ThisObject, Context,
			"ProcessFileAfterError", ThisObject), Context.ActionDetails.Source, FullFileName);
		Return;
	
	ElsIf Action = "CreateFolder" Then
		BeginCreatingDirectory(New NotifyDescription(
			"ProcessFileAfterCreateDirectory", ThisObject, Context,
			"ProcessFileAfterError", ThisObject), FullFileName);
		Return;
	
	ElsIf Action = "Get" Then
		FileDetails = New TransferableFileDescription(FullFileName, Context.ActionDetails.Address);
		FilesToGet = New Array;
		FilesToGet.Add(FileDetails);
		BeginGettingFiles(New NotifyDescription(
				"ProcessFileAfterGetFiles", ThisObject, Context,
				"ProcessFileAfterError", ThisObject),
			FilesToGet, , False);
		Return;
	
	ElsIf Action = "Put" Then
		FileDetails = New TransferableFileDescription(FullFileName);
		FilesToPut = New Array;
		FilesToPut.Add(FileDetails);
		BeginPuttingFiles(New NotifyDescription(
				"ProcessFileAfterPutFiles", ThisObject, Context,
				"ProcessFileAfterError", ThisObject),
			FilesToPut, , False, Context.FormID);
		Return;
	
	ElsIf Action = "GetProperties" Then
		Context.Insert("PropertiesForGetting", Context.ActionDetails.Properties);
		
	ElsIf Action = "SetProperties" Then
		Context.Insert("PropertiesForInstalling", Context.ActionDetails.Properties);
	EndIf;
	
	If TypeOf(File) = Type("File") Then
		Context.Insert("File", File);
		ProcessFileAfterInitializeFile(File, Context);
	Else
		Context.Insert("File", New File);
		Context.File.BeginInitialization(New NotifyDescription(
			"ProcessFileAfterInitializeFile", ThisObject, Context,
			"ProcessFileAfterError", ThisObject), File);
	EndIf;
	
EndProcedure

// Continue the ProcessFile procedure.
Procedure ProcessFileAfterError(ErrorInformation, StandardProcessing, Context) Export
	
	StandardProcessing = False;
	
	If TypeOf(ErrorInformation) = Type("ErrorInfo") Then
		Context.ActionsResult.ErrorDescription = BriefErrorDescription(ErrorInformation);
	Else
		Context.ActionsResult.ErrorDescription = ErrorInformation;
	EndIf;
	
	If Context.ActionDetails.Property("ErrorTitle") Then
		Context.ActionsResult.ErrorDescription = Context.ActionDetails.ErrorTitle
			+ Chars.LF + Context.ActionsResult.ErrorDescription;
	EndIf;
	
	ExecuteNotifyProcessing(Context.Notification, Context.ActionsResult);
	
EndProcedure

// Continue the ProcessFile procedure.
Procedure ProcessFileAfterDeleteFiles(Context) Export
	
	ProcessFileLoopStart(Context);
	
EndProcedure

// Continue the ProcessFile procedure.
Procedure ProcessFileAfterCopyFile(CopiedFile, Context) Export
	
	ProcessFileLoopStart(Context);
	
EndProcedure

// Continue the ProcessFile procedure.
Procedure ProcessFileAfterCreateDirectory(DirectoryName, Context) Export
	
	ProcessFileLoopStart(Context);
	
EndProcedure

// Continue the ProcessFile procedure.
Procedure ProcessFileAfterGetFiles(ReceivedFiles, Context) Export
	
	If TypeOf(ReceivedFiles) <> Type("Array") Or ReceivedFiles.Count() = 0 Then
		ProcessFileAfterError(NStr("ru = 'Получение файла было отменено.'; en = 'Getting the file was canceled.'; pl = 'Zatwierdzenie pliku zostało anulowane.';de = 'Der Dateiempfang wurde abgebrochen.';ro = 'Primirea fișierului a fost anulată.';tr = 'Dosya alımı iptal edildi.'; es_ES = 'Recibo del archivo se ha cancelado.'"), Undefined, Context);
		Return;
	EndIf;
	
	ProcessFileLoopStart(Context);
	
EndProcedure

// Continue the ProcessFile procedure.
Procedure ProcessFileAfterPutFiles(FilesThatWerePut, Context) Export
	
	If TypeOf(FilesThatWerePut) <> Type("Array") Or FilesThatWerePut.Count() = 0 Then
		ProcessFileAfterError(NStr("ru = 'Помещение файла было отменено.'; en = 'Storing the file was canceled.'; pl = 'Umieszczenie pliku zostało anulowane.';de = 'Die Dateiablage wurde abgebrochen.';ro = 'Plasarea fișierului a fost anulată.';tr = 'Dosya yerleşimi iptal edildi.'; es_ES = 'Colocación del archivo se ha cancelado.'"), Undefined, Context);
		Return;
	EndIf;
	
	Context.ActionDetails.Insert("Address", FilesThatWerePut[0].Location);
	
	ProcessFileLoopStart(Context);
	
EndProcedure

// Continue the ProcessFile procedure.
Procedure ProcessFileAfterInitializeFile(File, Context) Export
	
	Context.Insert("File", File);
	Context.Result.Insert("File", File);
	FillPropertyValues(Context.PropertiesForGetting, File);
	
	Context.File.BeginCheckingExistence(New NotifyDescription(
		"ProcessFileAfterCheckExistence", ThisObject, Context,
		"ProcessFileAfterError", ThisObject));
	
EndProcedure

// Continue the ProcessFile procedure.
Procedure ProcessFileAfterCheckExistence(Exists, Context) Export
	
	Context.Result.Insert("Exist", Exists);
	
	If Not Context.Result.Exist Then
		ProcessFileLoopStart(Context);
		Return;
	EndIf;
	
	If Context.PropertiesForGetting.Count() = 0 Then
		ProcessFileAfterCheckIsFile(Null, Context);
		
	ElsIf Context.PropertiesForGetting.Property("Modified") Then
		Context.File.BeginGettingModificationTime(New NotifyDescription(
			"ProcessFileAfterGetModificationTime", ThisObject, Context,
			"ProcessFileAfterError", ThisObject));
	Else
		ProcessFileAfterGetModificationTime(Null, Context);
	EndIf;
	
EndProcedure

// Continue the ProcessFile procedure.
Procedure ProcessFileAfterGetModificationTime(ChangeTime, Context) Export
	
	If ChangeTime <> Null Then
		Context.PropertiesForGetting.Modified = ChangeTime;
	EndIf;
	
	If Context.PropertiesForGetting.Property("UniversalModificationTime") Then
		Context.File.BeginGettingModificationUniversalTime(New NotifyDescription(
			"ProcessFileAfterGetUniversalModificationTime", ThisObject, Context,
			"ProcessFileAfterError", ThisObject));
	Else
		ProcessFileAfterGetUniversalModificationTime(Null, Context);
	EndIf;
	
EndProcedure

// Continue the ProcessFile procedure.
Procedure ProcessFileAfterGetUniversalModificationTime(UniversalModificationTime, Context) Export
	
	If UniversalModificationTime <> Null Then
		Context.PropertiesForGetting.UniversalModificationTime = UniversalModificationTime;
	EndIf;
	
	If Context.PropertiesForGetting.Property("ReadOnly") Then
		Context.File.BeginGettingReadOnly(New NotifyDescription(
			"ProcessFileAfterGetReadOnly", ThisObject, Context,
			"ProcessFileAfterError", ThisObject));
	Else
		ProcessFileAfterGetReadOnly(Null, Context);
	EndIf;
	
EndProcedure

// Continue the ProcessFile procedure.
Procedure ProcessFileAfterGetReadOnly(ReadOnly, Context) Export
	
	If ReadOnly <> Null Then
		Context.PropertiesForGetting.ReadOnly = ReadOnly;
	EndIf;
	
	If Context.PropertiesForGetting.Property("Invisibility") Then
		Context.File.BeginGettingHidden(New NotifyDescription(
			"ProcessFileAfterGetInvisibility", ThisObject, Context,
			"ProcessFileAfterError", ThisObject));
	Else
		ProcessFileAfterGetInvisibility(Null, Context);
	EndIf;
	
EndProcedure

// Continue the ProcessFile procedure.
Procedure ProcessFileAfterGetInvisibility(Invisibility, Context) Export
	
	If Invisibility <> Null Then
		Context.PropertiesForGetting.Invisibility = Invisibility;
	EndIf;
	
	If Context.PropertiesForGetting.Property("Size") Then
		Context.File.BeginGettingSize(New NotifyDescription(
			"ProcessFileAfterGetSize", ThisObject, Context,
			"ProcessFileAfterError", ThisObject));
	Else
		ProcessFileAfterGetSize(Null, Context);
	EndIf;
	
EndProcedure

// Continue the ProcessFile procedure.
Procedure ProcessFileAfterGetSize(Size, Context) Export
	
	If Size <> Null Then
		Context.PropertiesForGetting.Size = Size;
	EndIf;
	
	If Context.PropertiesForGetting.Property("IsDirectory") Then
		Context.File.BeginCheckingIsDirectory(New NotifyDescription(
			"ProcessFileAfterCheckIsDirectory", ThisObject, Context,
			"ProcessFileAfterError", ThisObject));
	Else
		ProcessFileAfterCheckIsDirectory(Null, Context);
	EndIf;
	
EndProcedure

// Continue the ProcessFile procedure.
Procedure ProcessFileAfterCheckIsDirectory(IsDirectory, Context) Export
	
	If IsDirectory <> Null Then
		Context.PropertiesForGetting.IsDirectory = IsDirectory;
	EndIf;
	
	If Context.PropertiesForGetting.Property("IsFile") Then
		Context.File.BeginCheckingIsFile(New NotifyDescription(
			"ProcessFileAfterCheckIsFile", ThisObject, Context,
			"ProcessFileAfterError", ThisObject));
	Else
		ProcessFileAfterCheckIsFile(Null, Context);
	EndIf;
	
EndProcedure

// Continue the ProcessFile procedure.
Procedure ProcessFileAfterCheckIsFile(IsFile, Context) Export
	
	If IsFile <> Null Then
		Context.PropertiesForGetting.IsFile = IsFile;
	EndIf;
	
	If Context.PropertiesForInstalling.Count() = 0 Then
		ProcessFileAfterSetInvisibility(Context);
		
	ElsIf Context.PropertiesForInstalling.Property("Modified") Then
		Context.File.BeginSettingModificationTime(New NotifyDescription(
			"ProcessFileAfterSetModificationTime", ThisObject, Context,
			"ProcessFileAfterError", ThisObject), Context.PropertiesForInstalling.Modified);
	Else
		ProcessFileAfterSetModificationTime(Context);
	EndIf;
	
EndProcedure

// Continue the ProcessFile procedure.
Procedure ProcessFileAfterSetModificationTime(Context) Export
	
	If Context.PropertiesForInstalling.Property("UniversalModificationTime") Then
		Context.File.BeginSettingModificationUniversalTime(New NotifyDescription(
			"ProcessFileAfterSetUniversalModificationTime", ThisObject, Context,
			"ProcessFileAfterError", ThisObject), Context.PropertiesForInstalling.UniversalModificationTime);
	Else
		ProcessFileAfterSetUniversalModificationTime(Context);
	EndIf;
	
EndProcedure

// Continue the ProcessFile procedure.
Procedure ProcessFileAfterSetUniversalModificationTime(Context) Export
	
	If Context.PropertiesForInstalling.Property("ReadOnly") Then
		Context.File.BeginSettingReadOnly(New NotifyDescription(
			"ProcessFileAfterSetReadOnly", ThisObject, Context,
			"ProcessFileAfterError", ThisObject), Context.PropertiesForInstalling.ReadOnly);
	Else
		ProcessFileAfterSetReadOnly(Context);
	EndIf;
	
EndProcedure

// Continue the ProcessFile procedure.
Procedure ProcessFileAfterSetReadOnly(Context) Export
	
	If Context.PropertiesForInstalling.Property("Invisibility") Then
		Context.File.BeginSettingHidden(New NotifyDescription(
			"ProcessFileAfterSetInvisibility", ThisObject, Context,
			"ProcessFileAfterError", ThisObject), Context.PropertiesForInstalling.Invisibility);
	Else
		ProcessFileAfterSetInvisibility(Context);
	EndIf;
	
EndProcedure

// Continue the ProcessFile procedure.
Procedure ProcessFileAfterSetInvisibility(Context) Export
	
	ProcessFileLoopStart(Context);
	
EndProcedure

// Uploads the file from the client to a temporary storage on the server. Does not work without file extension.
Function PutFileFromHardDriveInTempStorage(FullFileName, FileAddress = "", UUID = Undefined)
	If Not FileSystemExtensionAttached() Then
		Return Undefined;
	EndIf;
	WhatToUpload = New Array;
	WhatToUpload.Add(New TransferableFileDescription(FullFileName, FileAddress));
	ImportResult = New Array;
	FileImported = PutFiles(WhatToUpload, ImportResult, , False, UUID);
	If Not FileImported Or ImportResult.Count() = 0 Then
		Return Undefined;
	EndIf;
	Return ImportResult[0].Location;
EndFunction

////////////////////////////////////////////////////////////////////////////////
// Procedures and functions for working with scanner.

// Initialize the scanning add in.
Function InitAddIn(TryInitAddIn = True) Export
	
	If Not ScanAvailable() Then 
		Return False;
	EndIf;
	
	ParameterName = "StandardSubsystems.TwainComponent";
	If ApplicationParameters[ParameterName] = Undefined Then
		
		// Calling the CommonClient.AttachAddInFromTemplate is not required, because
		// The external add-in is attached from the template and scanning is not available in the web client.
		ReturnCode = AttachAddIn("CommonTemplate.TwainComponent", "twain");
		If Not ReturnCode Then
			
			If Not TryInitAddIn Then
				Return False;
			EndIf;
			
			InstallAddIn("CommonTemplate.TwainComponent");
			
			Return InitAddIn(False); // Recursively.
			
		EndIf;
		
		ApplicationParameters.Insert(ParameterName, New("AddIn.twain.AddInNativeExtension"));
	EndIf;
	
	Return True;
	
EndFunction

Function ScanAvailable() Export
	
#If WebClient Or MobileClient Then
	Return False;
#Else
	Return CommonClient.ClientPlatformType() = PlatformType.Windows_x86;
#EndIf
	
EndFunction

// Set the scanning add-in.
//
// Parameters:
//  ResultHandler - NotifyDescription, Undefined - description of the procedure that gets the method result.
//
// Returns:
//   Boolean - shows whether the operation is completed successfully.
//
// See also:
//   Variable of the TwainComponent global context.
//
Procedure InstallAddInSSL(ResultHandler) Export
	
	If InitAddIn() Then
		ReturnResult(ResultHandler, True);
		Return;
	EndIf;
	
	ExecutionParameters = New Structure;
	ExecutionParameters.Insert("ResultHandler", ResultHandler);
	Handler = New NotifyDescription("InstallAddInCompletion", ThisObject, ExecutionParameters);
	
	// Calling the CommonClient.AttachAddInFromTemplate is not required, because
	// The external add-in is attached from the template and scanning is not available in the web client.
	BeginInstallAddIn(Handler, "CommonTemplate.TwainComponent");
	
EndProcedure

// Continuation of the procedure (see above).
Procedure InstallAddInCompletion(ExecutionParameters) Export
	
	AddInAttached = InitAddIn();
	ReturnResult(ExecutionParameters.ResultHandler, AddInAttached);
	
EndProcedure

// Returns TWAIN devices (an array of strings).
Function EnumDevices() Export
	
	Array = New Array;
	
	If Not InitAddIn() Then
		Return Array;
	EndIf;
	
	Twain = ApplicationParameters["StandardSubsystems.TwainComponent"];
	DevicesString = Twain.EnumDevices();
	
	For Index = 1 To StrLineCount(DevicesString) Do
		Row = StrGetLine(DevicesString, Index);
		Array.Add(Row);
	EndDo;
	
	Return Array;
	
EndFunction

// Returns scanner setting by name.
//
// Parameters:
//   DeviceName - String - a scanner name.
//   SettingName  - String - a setting name, for example, "XRESOLUTION", "PIXELTYPE", "ROTATION", or 
//       "SUPPORTEDSIZES".
//
// Returns:
//   Number - a scanner setting value.
//
Function GetSetting(DeviceName, SettingName) Export
	
	If Not CommonClient.IsWindowsClient() Then
		Return -1;
	EndIf;
	
	Try
		Twain = ApplicationParameters["StandardSubsystems.TwainComponent"];
		Return Twain.GetSetting(DeviceName, SettingName);
	Except
		Return -1;
	EndTry;
	
EndFunction

////////////////////////////////////////////////////////////////////////////////
// Auxiliary procedures intended to support the asynchronous model.
//
Function ClientSupportsSynchronousCalls()
	
#If WebClient Then
	// Symchronous methods are not supported in Chrome and Firefox.
	SystemInfo = New SystemInfo;
	ApplicationInformationArray = StrSplit(SystemInfo.UserAgentInformation, " ", False);
	
	For Each ApplicationInformation In ApplicationInformationArray Do
		If StrFind(ApplicationInformation, "Chrome") > 0 OR StrFind(ApplicationInformation, "Firefox") > 0 Then
			Return False;
		EndIf;
	EndDo;
#EndIf
	
	Return True;
	
EndFunction

////////////////////////////////////////////////////////////////////////////////
// Processing common form events of file operations.

Procedure SelectModeAndEditFile(ResultHandler, FileData, CommandEditAvailability) Export
	// Select a file opening mode and start editing.
	ResultOpen = "Open";
	// Other opening modes are available.
	// "Edit"
	// "Cancel".
	
	PersonalSettings = PersonalFilesOperationsSettings();
	
	OpeningMethod = PersonalSettings.TextFilesOpeningMethod;
	If OpeningMethod = PredefinedValue("Enum.OpenFileForViewingMethods.UsingBuiltInEditor") Then
		
		ExtensionInList = FilesOperationsInternalClientServer.FileExtensionInList(
			PersonalSettings.TextFilesExtension,
			FileData.Extension);
		
		If ExtensionInList Then
			ReturnResult(ResultHandler, ResultOpen);
			Return;
		EndIf;
		
	EndIf;
	
	OpeningMethod = PersonalSettings.GraphicalSchemasOpeningMethod;
	If OpeningMethod = PredefinedValue("Enum.OpenFileForViewingMethods.UsingBuiltInEditor") Then
		
		ExtensionInList = FilesOperationsInternalClientServer.FileExtensionInList(
			PersonalSettings.GraphicalSchemasExtension,
			FileData.Extension);
		
		If ExtensionInList Then
			ReturnResult(ResultHandler, ResultOpen);
			Return;
		EndIf;
		
	EndIf;
	
	// If the file is already locked for editing, open without asking.
	If Not ValueIsFilled(FileData.BeingEditedBy)
		AND PersonalSettings.PromptForEditModeOnOpenFile = True
		AND CommandEditAvailability Then
		
		ExecutionParameters = New Structure;
		ExecutionParameters.Insert("ResultHandler", ResultHandler);
		Handler = New NotifyDescription("SelectModeAndEditFileCompletion", ThisObject, ExecutionParameters);
		
		OpenForm("DataProcessor.FilesOperations.Form.OpeningModeChoiceForm", , , , , , Handler, FormWindowOpeningMode.LockWholeInterface);
		Return;
	EndIf;
	
	ReturnResult(ResultHandler, ResultOpen);
	
EndProcedure

Procedure SelectModeAndEditFileCompletion(Result, ExecutionParameters) Export
	
	ResultOpen = "Open";
	ResultEdit = "Edit";
	ResultCancel = "Cancel";
	
	If TypeOf(Result) <> Type("Structure") Then
		ReturnResult(ExecutionParameters.ResultHandler, ResultCancel);
		Return;
	EndIf;
	
	If Result.HowToOpen = 1 Then
		ReturnResult(ExecutionParameters.ResultHandler, ResultEdit);
		Return;
	EndIf;
	
	ReturnResult(ExecutionParameters.ResultHandler, ResultOpen);
	
EndProcedure

Function FileCommandsAvailable(Items) Export
	// File commands are available. There is at least one row in the list and grouping is not selected.
	
	FileRef = Items.List.CurrentRow;
	
	If FileRef = Undefined Then 
		Return False;
	EndIf;
	
	If TypeOf(Items.List.CurrentRow) = Type("DynamicalListGroupRow") Then
		Return False;
	EndIf;
	
	Return True;
	
EndFunction

///////////////////////////////////////////////////////////////////////////////////
// Print the spreadsheet document with the digital signature stamp.

Procedure PrintFileWithStamp(SpreadsheetDocument) Export
	
	If CommonClient.SubsystemExists("StandardSubsystems.Print") Then
		ModulePrintManagerClient = CommonClient.CommonModule("PrintManagementClient");
		PrintFormID = "AttachedFile";
		SpreadsheetDocument.Protection = False;
		
		PrintFormsCollection = ModulePrintManagerClient.NewPrintFormsCollection(PrintFormID);
		PrintForm = ModulePrintManagerClient.PrintFormDetails(PrintFormsCollection, PrintFormID);
		PrintForm.TemplateSynonym = NStr("ru = 'Файл со штампом'; en = 'File with stamp'; pl = 'Plik z pieczątką';de = 'Datei mit Stempel';ro = 'Fișierul cu ștampilă';tr = 'Kaşeli dosya'; es_ES = 'Archivo con sello'");
		PrintForm.SpreadsheetDocument = SpreadsheetDocument;
		
		ModulePrintManagerClient.PrintDocuments(PrintFormsCollection);
	Else
		SpreadsheetDocument.Print(PrintDialogUseMode.Use);
	EndIf;
	
EndProcedure

// Backward compatibility. OPening a file without owner by an address to the temporary storage.

// Continue the OpenFile procedure.
Procedure OpenFileAddInSuggested(FileSystemExtensionAttached, AdditionalParameters) Export
	
	FileData = AdditionalParameters.FileData;
	ForEditing = AdditionalParameters.ForEditing;
	
	If FileSystemExtensionAttached Then
		
		UserWorkingDirectory = UserWorkingDirectory();
		FullFileNameAtClient = UserWorkingDirectory + FileData.RelativePath + FileData.FileName;
		FileOnHardDrive = New File(FullFileNameAtClient);
		
		AdditionalParameters.Insert("ForEditing", ForEditing);
		AdditionalParameters.Insert("UserWorkingDirectory", UserWorkingDirectory);
		AdditionalParameters.Insert("FileOnHardDrive", FileOnHardDrive);
		AdditionalParameters.Insert("FullFileNameAtClient", FullFileNameAtClient);
		
		If ValueIsFilled(FileData.BeingEditedBy) AND ForEditing AND FileOnHardDrive.Exist() Then
			FileOnHardDrive.SetReadOnly(False);
			GetFile = False;
		ElsIf FileOnHardDrive.Exist() Then
			NotifyDescription = New NotifyDescription("OpenFileDialogShown", ThisObject, AdditionalParameters);
			ShowDialogNeedToGetFileFromServer(NotifyDescription, FullFileNameAtClient, FileData, ForEditing);
			Return;
		Else
			GetFile = True;
		EndIf;
		
		OpenFileDialogShown(GetFile, AdditionalParameters);
	Else
		NotifyDescription = New NotifyDescription("OpenFileReminderShown", ThisObject, AdditionalParameters);
		OutputNotificationOnEdit(NotifyDescription);
	EndIf;
	
EndProcedure

// Continue the OpenFile procedure.
Procedure OpenFileReminderShown(ReminderResult, AdditionalParameters) Export
	
	If ReminderResult = DialogReturnCode.Cancel Or ReminderResult = Undefined Then
		Return;
	EndIf;
	
	FileData = AdditionalParameters.FileData;
	GetFile(FileData.BinaryFileDataRef, FileData.FileName, True);
	
EndProcedure

// Continue the OpenFile procedure.
Procedure OpenFileDialogShown(GetFile, AdditionalParameters) Export
	
	If GetFile = Undefined Then
		Return;
	EndIf;
	
	FileData = AdditionalParameters.FileData;
	ForEditing = AdditionalParameters.ForEditing;
	UserWorkingDirectory = AdditionalParameters.UserWorkingDirectory;
	FileOnHardDrive = AdditionalParameters.FileOnHardDrive;
	FullFileNameAtClient = AdditionalParameters.FullFileNameAtClient;
	
	CanOpenFile = True;
	If GetFile Then
		FullFileNameAtClient = "";
		CanOpenFile = GetFileToWorkingDirectory(
			FileData.BinaryFileDataRef,
			FileData.RelativePath,
			FileData.UniversalModificationDate,
			FileData.FileName,
			UserWorkingDirectory,
			FullFileNameAtClient);
	EndIf;
		
	If CanOpenFile Then
		
		If ForEditing Then
			FileOnHardDrive.SetReadOnly(False);
		Else
			FileOnHardDrive.SetReadOnly(True);
		EndIf;
		
		UUID = ?(AdditionalParameters.Property("UUID"),
			AdditionalParameters.UUID, Undefined);
			
		OpenFileWithApplication(FileData, FullFileNameAtClient, UUID);
		
	EndIf;
		
EndProcedure

Function GetFileToWorkingDirectory(Val FileBinaryDataAddress,
                                    Val RelativePath,
                                    Val UniversalModificationDate,
                                    Val FileName,
                                    Val UserWorkingDirectory,
                                    FullFileNameAtClient)
	
	If UserWorkingDirectory = Undefined
	 OR IsBlankString(UserWorkingDirectory) Then
		
		Return False;
	EndIf;
	
	DirectoryForSave = UserWorkingDirectory + RelativePath;
	
	Try
		CreateDirectory(DirectoryForSave);
	Except
		ErrorMessage = BriefErrorDescription(ErrorInfo());
		ErrorMessage = NStr("ru = 'Ошибка создания каталога на диске:'; en = 'Cannot create the directory on the hard drive:'; pl = 'Wystąpił błąd podczas tworzenia katalogu na dysku:';de = 'Beim Erstellen eines Verzeichnisses auf dem Laufwerk ist ein Fehler aufgetreten:';ro = 'A apărut o eroare la crearea unui catalog pe unitate:';tr = 'Sürücüde bir dizin oluştururken bir hata oluştu:'; es_ES = 'Ha ocurrido un error al crear un directorio en el drive:'") + " " + ErrorMessage;
		CommonClient.MessageToUser(ErrorMessage);
		Return False;
	EndTry;
	
	File = New File(DirectoryForSave + FileName);
	If File.Exist() Then
		File.SetReadOnly(False);
		DeleteFiles(DirectoryForSave + FileName);
	EndIf;
	
	FileToReceive = New TransferableFileDescription(DirectoryForSave + FileName, FileBinaryDataAddress);
	FilesToGet = New Array;
	FilesToGet.Add(FileToReceive);
	
	ReceivedFiles = New Array;
	
	If GetFiles(FilesToGet, ReceivedFiles, , False) Then
		FullFileNameAtClient = ReceivedFiles[0].Name;
		File = New File(FullFileNameAtClient);
		File.SetModificationUniversalTime(UniversalModificationDate);
		Return True;
	EndIf;
	
	Return False;
	
EndFunction

Procedure ShowDialogNeedToGetFileFromServer(ResultHandler, Val FileNameWithPath, Val FileData, Val ForEditing)
	
	StandardFileData = New Structure;
	StandardFileData.Insert("UniversalModificationDate", FileData.UniversalModificationDate);
	StandardFileData.Insert("Size",                       FileData.Size);
	StandardFileData.Insert("InWorkingDirectoryForRead",     NOT ForEditing);
	StandardFileData.Insert("BeingEditedBy",                  FileData.BeingEditedBy);
	
	// The file is found in the working directory.
	// Checking the modification date and deciding what to do next.
	
	Parameters = New Structure;
	Parameters.Insert("ResultHandler", ResultHandler);
	Parameters.Insert("FileNameWithPath", FileNameWithPath);
	NotifyDescription = New NotifyDescription("ShowDialogNeedToGetFileFromServerActionDefined", ThisObject, Parameters);
	ActionOnOpenFileInWorkingDirectory(NotifyDescription, FileNameWithPath, StandardFileData);
	
EndProcedure

// Continues ShowDialogNeedToGetFileFromServer procedure execution.
Procedure ShowDialogNeedToGetFileFromServerActionDefined(Action, AdditionalParameters) Export
	FileNameWithPath = AdditionalParameters.FileNameWithPath;
	
	If Action = "GetFromStorageAndOpen" Then
		File = New File(FileNameWithPath);
		File.SetReadOnly(False);
		DeleteFiles(FileNameWithPath);
		Result = True;
	ElsIf Action = "OpenExistingFile" Then
		Result = False;
	Else // Action = "Cancel".
		Result = Undefined;
	EndIf;
	
	ExecuteNotifyProcessing(AdditionalParameters.ResultHandler, Result);
	
EndProcedure

#EndRegion
