///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region EventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	Parameters.Property("FileStorageVolume", FileStorageVolume);
	
	FillExcessFilesTable();
	UnnecessaryFilesCount = UnnecessaryFiles.Count();
	
	DateFolder = Format(CurrentSessionDate(), "DF=yyyymmdd") + GetPathSeparator();
	
	CopyFilesBeforeDelete                = False;
	Items.PathToFolderToCopy.Enabled = False;
	
	If Common.IsMobileClient() Then
		CommandBarLocation = FormCommandBarLabelLocation.Auto;
	EndIf;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure DecorationDetailsClick(Item)
	
	ReportParameters = New Structure();
	ReportParameters.Insert("GenerateOnOpen", True);
	ReportParameters.Insert("Filter", New Structure("Volume", FileStorageVolume));
	
	OpenForm("Report.VolumeIntegrityCheck.ObjectForm", ReportParameters);
	
EndProcedure

&AtClient
Procedure FolderPathForCopyStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	
	OpenFileDialog = New FileDialog(FileDialogMode.ChooseDirectory);
	OpenFileDialog.FullFileName = "";
	OpenFileDialog.Directory = PathToFolderToCopy;
	OpenFileDialog.Multiselect = False;
	OpenFileDialog.Title = Title;
	
	Context = New Structure("OpenFileDialog", OpenFileDialog);
	
	ChoiceDialogNotificationDetails = New NotifyDescription(
		"FolderPathForCopyStartChoiceCompletion", ThisObject, Context);
	FileSystemClient.ShowSelectionDialog(ChoiceDialogNotificationDetails, OpenFileDialog);
	
EndProcedure

&AtClient
Procedure FolderPathForCopyStartChoiceCompletion(SelectedFiles, Context) Export
	
	OpenFileDialog = Context.OpenFileDialog;
	
	If SelectedFiles = Undefined Then
		Items.FormDeleteUnnecessaryFiles.Enabled = False;
	Else
		PathToFolderToCopy = OpenFileDialog.Directory;
		PathToFolderToCopy = CommonClientServer.AddLastPathSeparator(PathToFolderToCopy);
		Items.FormDeleteUnnecessaryFiles.Enabled = ValueIsFilled(PathToFolderToCopy);
	EndIf;

EndProcedure

&AtClient
Procedure DestinationDirectoryOnChange(Item)
	
	PathToFolderToCopy                     = CommonClientServer.AddLastPathSeparator(PathToFolderToCopy);
	Items.FormDeleteUnnecessaryFiles.Enabled = ValueIsFilled(PathToFolderToCopy);
	
EndProcedure

&AtClient
Procedure CopyFilesBeforeDeleteOnChange(Item)
	
	If Not CopyFilesBeforeDelete Then
		PathToFolderToCopy                      = "";
		Items.PathToFolderToCopy.Enabled = False;
		Items.FormDeleteUnnecessaryFiles.Enabled  = True;
	Else
		Items.PathToFolderToCopy.Enabled = True;
		If ValueIsFilled(PathToFolderToCopy) Then
			Items.FormDeleteUnnecessaryFiles.Enabled = True;
		Else
			Items.FormDeleteUnnecessaryFiles.Enabled = False;
		EndIf;
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandHandlers

&AtClient
Procedure DeleteUnnecessaryFiles(Command)
	
	If UnnecessaryFilesCount = 0 Then
		ShowMessageBox(, NStr("ru = 'Нет ни одного лишнего файла на диске'; en = 'There are no extraneous files on the hard drive.'; pl = 'Nie ma żadnych zbędnych plików na dysku';de = 'Es gibt keine einzige zusätzliche Datei auf der Festplatte';ro = 'Nu există nici un fișier nedorit pe disc';tr = 'Diskte hiç bir tane fazla dosya yok'; es_ES = 'No hay ningún archivo de sobra en el disco'"));
		Return;
	EndIf;
	
	FileSystemClient.AttachFileOperationsExtension(
		New NotifyDescription("AttachFileSystemExtensionCompletion", ThisObject),, 
		False);
	
EndProcedure

&AtClient
Procedure AttachFileSystemExtensionCompletion(ExtensionAttached, AdditionalParameters) Export
	
	If Not ExtensionAttached Then
		ShowMessageBox(, NStr("ru = 'Расширение работы с файлами не установлено. Работа с файлами с неустановленным расширением в веб клиенте невозможна.'; en = 'The file system extension is not installed. It is required to perform file operations on the web client.'; pl = 'Rozszerzenie pracy z plikami nie jest zainstalowano. Praca z plikami z nieustalonym rozszerzeniem w web kliencie jest niemożliwe.';de = 'Die Dateierweiterung ist nicht installiert. Das Arbeiten mit Dateien mit einer deinstallierten Erweiterung im Webclient ist nicht möglich.';ro = 'Extensia de lucru cu fișierele nu este instalată. Lucrul cu fișierele cu extensia neinstalată în web-client nu este posibil.';tr = 'Dosya uzantısı yüklü değil. Bir web istemcisinde yüklü olmayan bir uzantıya sahip dosyalarla çalışmak mümkün değildir.'; es_ES = 'La extensión de operaciones con archivos no está establecido. Es imposible usar los archivos con extensiones no especificadas en el cliente web.'"));
		Return;
	EndIf;
	
	If Not CopyFilesBeforeDelete Then
		AfterCheckWriteToDirectory(True, New Structure);
	Else
		FolderForCopying = New File(PathToFolderToCopy);
		FolderForCopying.BeginCheckingExistence(New NotifyDescription("FolderExistanceCheckCompletion", ThisObject));
	EndIf;
	
EndProcedure

&AtClient
Procedure FolderExistanceCheckCompletion(Exists, AdditionalParameters) Export
	
	If Not Exists Then
		ShowMessageBox(, NStr("ru = 'Путь к каталогу копирования некорректен.'; en = 'Invalid destination directory.'; pl = 'Ścieżka do folderu kopiowania jest nieprawidłowa.';de = 'Der Pfad zum Kopierverzeichnis ist falsch.';ro = 'Calea spre catalogul de copiere este incorectă.';tr = 'Kopya dizini yolu yanlıştır.'; es_ES = 'Ruta al catálogo de copiar incorrecta.'"));
	Else
		RightToWriteToDirectory(New NotifyDescription("AfterCheckWriteToDirectory", ThisObject));
	EndIf;
	
EndProcedure

&AtClient
Procedure AfterCheckWriteToDirectory(Result, AdditionalParameters) Export
	
	If Not Result Then
		Return;
	EndIf;
	
	If UnnecessaryFiles.Count() = 0 Then
		Return;
	EndIf;
	
	FinalNotificationParameters = New Structure;
	FinalNotificationParameters.Insert("FilesArrayWithErrors", New Array);
	FinalNotificationParameters.Insert("NumberOfDeletedFiles",  0);
	FinalNotification = New NotifyDescription("AfterProcessFiles", ThisObject, FinalNotificationParameters);
	
	ExecuteNotifyProcessing(New NotifyDescription("ProcessNextFile", ThisObject,
		New Structure("FinalNotification, CurrentFile", FinalNotification, Undefined), "ProcessNextFileError", ThisObject));
	
EndProcedure

&AtClient
Procedure ProcessNextFile(Result, AdditionalParameters) Export
	
	CurrentFile       = AdditionalParameters.CurrentFile;
	LastIteration = False;
	
	If CurrentFile = Undefined Then
		CurrentFile = UnnecessaryFiles.Get(0);
	Else
		
		CurrentFileIndex = UnnecessaryFiles.IndexOf(CurrentFile);
		If CurrentFileIndex = UnnecessaryFiles.Count() - 1 Then
			LastIteration = True;
		Else
			CurrentFile = UnnecessaryFiles.Get(CurrentFileIndex + 1);
		EndIf;
		
	EndIf;
	
	CurrentFileFullName = CurrentFile.FullName;
	DirectoryForCopying  = PathToFolderToCopy + DateFolder + GetPathSeparator();
	
	CurrentFileParameters = New Structure;
	CurrentFileParameters.Insert("FinalNotification",    AdditionalParameters.FinalNotification);
	CurrentFileParameters.Insert("CurrentFile",           CurrentFile);
	CurrentFileParameters.Insert("LastIteration",     LastIteration);
	CurrentFileParameters.Insert("DirectoryForCopying", DirectoryForCopying);
	
	If Not IsBlankString(PathToFolderToCopy) Then
		
		File = New File(CurrentFileFullName);
		File.BeginCheckingExistence(New NotifyDescription("CheckFileExistEnd", ThisObject, CurrentFileParameters));
		
	Else
		
		BeginDeletingFiles(New NotifyDescription("ProcessNextFileDeletionEnd", ThisObject, CurrentFileParameters,
			"ProcessNextFileError", ThisObject), CurrentFileFullName);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure CheckFileExistEnd(FileExists, AdditionalParameters) Export
	
	If Not FileExists Then
		ExecuteNotifyProcessing(AdditionalParameters.FinalNotification);
	Else
		CurrentDayDirectory = New File(AdditionalParameters.DirectoryForCopying);
		CurrentDayDirectory.BeginCheckingExistence(New NotifyDescription("DayDirectoryExistEnd", ThisObject, AdditionalParameters));
	EndIf;
	
EndProcedure

&AtClient
Procedure DayDirectoryExistEnd(DirectoryExist, AdditionalParameters) Export
	
	If Not DirectoryExist Then
		BeginCreatingDirectory(New NotifyDescription("CreateDayDirectoryEnd", ThisObject, AdditionalParameters), AdditionalParameters.DirectoryForCopying);
	Else
		FileTargetName = AdditionalParameters.DirectoryForCopying + AdditionalParameters.CurrentFile.Name;
		File = New File(FileTargetName);
		File.BeginCheckingExistence(New NotifyDescription("CheckTargetFileExistEnd", ThisObject, AdditionalParameters));
	EndIf;
	
EndProcedure

&AtClient
Procedure CreateDayDirectoryEnd(DirectoryName, AdditionalParameters) Export
	
	FileTargetName = AdditionalParameters.DirectoryForCopying + AdditionalParameters.CurrentFile.Name;
	File = New File(FileTargetName);
	File.BeginCheckingExistence(New NotifyDescription("CheckTargetFileExistEnd", ThisObject, AdditionalParameters));
	
EndProcedure

&AtClient
Procedure CheckTargetFileExistEnd(FileExists, AdditionalParameters) Export
	
	DirectoryForCopying  = AdditionalParameters.DirectoryForCopying;
	CurrentFileName       = AdditionalParameters.CurrentFile.Name;
	CurrentFileFullName = AdditionalParameters.CurrentFile.FullName;
	
	If Not FileExists Then
		FileTargetName = DirectoryForCopying + CurrentFileName;
	Else
		FileSeparatedName = StrSplit(CurrentFileName, ".");
		NameWithoutExtension    = FileSeparatedName.Get(0);
		Extension          = FileSeparatedName.Get(1);
		FileTargetName    = DirectoryForCopying + NameWithoutExtension + "_" + String(New UUID) + "." + Extension;
	EndIf;
		
	BeginMovingFile(New NotifyDescription("ProcessNextFileMoveEnd", ThisObject, AdditionalParameters,
		"ProcessNextFileError", ThisObject), CurrentFileFullName, FileTargetName);
	
EndProcedure

&AtClient
Procedure ProcessNextFileMoveEnd(Result, AdditionalParameters) Export
	
	ProcessesNextFileEnd(AdditionalParameters);
	
EndProcedure

&AtClient
Procedure ProcessNextFileDeletionEnd(AdditionalParameters) Export
	
	ProcessesNextFileEnd(AdditionalParameters);
	
EndProcedure

&AtClient
Procedure ProcessesNextFileEnd(AdditionalParameters)
	
	CurrentFile                  = AdditionalParameters.CurrentFile;
	FinalNotification           = AdditionalParameters.FinalNotification;
	FinalNotificationParameters = FinalNotification.AdditionalParameters;
	
	FinalNotificationParameters.Insert("NumberOfDeletedFiles", FinalNotificationParameters.NumberOfDeletedFiles + 1);
	
	If AdditionalParameters.LastIteration Then
		ExecuteNotifyProcessing(FinalNotification);
	Else
		ExecuteNotifyProcessing(New NotifyDescription("ProcessNextFile", ThisObject,
			New Structure("FinalNotification, CurrentFile", FinalNotification, CurrentFile), "ProcessNextFileError", ThisObject));
	EndIf;
	
EndProcedure

&AtClient
Procedure ProcessNextFileError(ErrorInformation, StandardProcessing, AdditionalParameters) Export
	
	CurrentFile      = AdditionalParameters.CurrentFile;
	CurrentFileName = CurrentFile.Name;
	
	FinalNotification           = AdditionalParameters.FinalNotification;
	FinalNotificationParameters = FinalNotification.AdditionalParameters;
	
	ErrorStructure = New Structure;
	ErrorStructure.Insert("Name",    CurrentFileName);
	ErrorStructure.Insert("Error", BriefErrorDescription(ErrorInformation));
	
	FilesArrayWithErrors = FinalNotificationParameters.FilesArrayWithErrors;
	FilesArrayWithErrors.Add(ErrorStructure);
	FinalNotificationParameters.Insert("FilesArrayWithErrors", FilesArrayWithErrors);
	
	ProcessErrorMessage(CurrentFile.FullName, DetailErrorDescription(ErrorInformation));
	
	If AdditionalParameters.LastIteration Then
		ExecuteNotifyProcessing(FinalNotification);
	Else
		ExecuteNotifyProcessing(New NotifyDescription("ProcessNextFile", ThisObject,
			New Structure("FinalNotification, CurrentFile", FinalNotification, CurrentFile), "ProcessNextFileError", ThisObject));
	EndIf;
	
EndProcedure

&AtClient
Procedure AfterProcessFiles(Result, AdditionalParameters) Export
	
	NumberOfDeletedFiles  = AdditionalParameters.NumberOfDeletedFiles;
	FilesArrayWithErrors = AdditionalParameters.FilesArrayWithErrors;
	
	If NumberOfDeletedFiles <> 0 Then
		NotificationText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Удалено файлов: %1'; en = 'Files deleted: %1'; pl = 'Usuniętych plików: %1';de = 'Gelöschte Dateien: %1';ro = 'Fișiere șterse: %1';tr = 'Silinen dosya: %1'; es_ES = 'Eliminado archivos: %1'"),
			NumberOfDeletedFiles);
		ShowUserNotification(
			NStr("ru = 'Завершено удаление лишних файлов.'; en = 'The extraneous files are deleted.'; pl = 'Zakończono usuwanie zbędnych plików.';de = 'Das Löschen nicht benötigter Dateien ist abgeschlossen.';ro = 'Este finalizată ștergerea fișierelor nedorite.';tr = 'Fazla dosya silindi.'; es_ES = 'Se han eliminado los archivos de sobra.'"),
			,
			NotificationText,
			PictureLib.Information32);
	EndIf;
	
	If FilesArrayWithErrors.Count() > 0 Then
		ErrorsReport = New SpreadsheetDocument;
		GenerateErrorsReport(ErrorsReport, FilesArrayWithErrors);
		ErrorsReport.Show();
	EndIf;
	
	Close();
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure FillExcessFilesTable()
	
	FilesTableOnHardDrive = New ValueTable;
	TableColumns       = FilesTableOnHardDrive.Columns;
	TableColumns.Add("Name");
	TableColumns.Add("File");
	TableColumns.Add("BaseName");
	TableColumns.Add("FullName");
	TableColumns.Add("Path");
	TableColumns.Add("Volume");
	TableColumns.Add("Extension");
	TableColumns.Add("VerificationStatus");
	TableColumns.Add("Count");
	TableColumns.Add("WasEditedBy");
	TableColumns.Add("ModificationDate");

	VolumePath = FilesOperationsInternal.FullVolumePath(FileStorageVolume);
	
	FilesArray = FindFiles(VolumePath,"*", True);
	For Each File In FilesArray Do
		
		If Not File.IsFile() Then
			Continue;
		EndIf;
		
		NewRow = FilesTableOnHardDrive.Add();
		NewRow.Name              = File.Name;
		NewRow.BaseName = File.BaseName;
		NewRow.FullName        = File.FullName;
		NewRow.Path             = File.Path;
		NewRow.Extension       = File.Extension;
		NewRow.VerificationStatus   = NStr("ru = 'Лишние файлы (есть на диске, но сведения о них отсутствуют)'; en = 'Extraneous files (files on the hard drive that are not registered in the application)'; pl = 'Zbędne pliki (są na dysku, ale brakuje o nich informacji)';de = 'Nicht benötigte Dateien (es gibt einige auf der Festplatte, aber keine Informationen darüber sind verfügbar)';ro = 'Fișiere nedorite (există pe disc, dar informațiile despre ele lipsesc)';tr = 'Fazlalık dosyalar (diskte mevcut, ancak onlar ile ilgili veri yok)'; es_ES = 'Archivos innecesarios (hay en el disco pero no hay información de ellos)'");
		NewRow.Count       = 1;
		NewRow.Volume              = FileStorageVolume;
		
	EndDo;
	
	FilesOperationsInternal.CheckFilesIntegrity(FilesTableOnHardDrive, FileStorageVolume);
	FilesTableOnHardDrive.Indexes.Add("VerificationStatus");
	ExcessFilesArray = FilesTableOnHardDrive.FindRows(
		New Structure("VerificationStatus", NStr("ru = 'Лишние файлы (есть на диске, но сведения о них отсутствуют)'; en = 'Extraneous files (files on the hard drive that are not registered in the application)'; pl = 'Zbędne pliki (są na dysku, ale brakuje o nich informacji)';de = 'Nicht benötigte Dateien (es gibt einige auf der Festplatte, aber keine Informationen darüber sind verfügbar)';ro = 'Fișiere nedorite (există pe disc, dar informațiile despre ele lipsesc)';tr = 'Fazlalık dosyalar (diskte mevcut, ancak onlar ile ilgili veri yok)'; es_ES = 'Archivos innecesarios (hay en el disco pero no hay información de ellos)'")));
	
	For Each File In ExcessFilesArray Do
		NewRow = UnnecessaryFiles.Add();
		FillPropertyValues(NewRow, File);
	EndDo;
	
	UnnecessaryFiles.Sort("Name");
	
EndProcedure

&AtClient
Procedure RightToWriteToDirectory(SourceNotification)
	
	If IsBlankString(PathToFolderToCopy) Then
		ExecuteNotifyProcessing(SourceNotification, True);
		Return
	EndIf;
	
	DirectoryName = PathToFolderToCopy + "CheckAccess\";
	
	DirectoryDeletionParameters  = New Structure("SourceNotification, DirectoryName", SourceNotification, DirectoryName);
	DirectoryCreationNotification = New NotifyDescription("AfterCreateDirectory", ThisObject, DirectoryDeletionParameters, "AfterDirectoryCreationError", ThisObject);
	BeginCreatingDirectory(DirectoryCreationNotification, DirectoryName);
	
EndProcedure

&AtClient
Procedure AfterDirectoryCreationError(ErrorInformation, StandardProcessing, AdditionalParameters) Export
	
	ProcessAccessRightsError(ErrorInformation, AdditionalParameters.SourceNotification);
	
EndProcedure

&AtClient
Procedure AfterCreateDirectory(Result, AdditionalParameters) Export
	
	BeginDeletingFiles(New NotifyDescription("AfterDeleteDirectory", ThisObject, AdditionalParameters, "AfterDirectoryDeletionError", ThisObject), AdditionalParameters.DirectoryName);
	
EndProcedure

&AtClient
Procedure AfterDeleteDirectory(AdditionalParameters) Export
	
	ExecuteNotifyProcessing(AdditionalParameters.SourceNotification, True);
	
EndProcedure

&AtClient
Procedure AfterDirectoryDeletionError(ErrorInformation, StandardProcessing, AdditionalParameters) Export
	
	ProcessAccessRightsError(ErrorInformation, AdditionalParameters.SourceNotification);
	
EndProcedure

&AtClient
Procedure ProcessAccessRightsError(ErrorInformation, SourceNotification)
	
	ErrorTemplate = NStr("ru = 'Путь каталога для копирования некорректен.
	|Возможно учетная запись, от лица которой работает
	|сервер 1С:Предприятия, не имеет прав доступа к указанному каталогу.
	|
	|%1'; 
	|en = 'Invalid destination directory.
	|Possibly an account on whose behalf 1C:Enterprise server is running
	|does not have access rights to the directory.
	|
	|%1'; 
	|pl = 'Ścieżka katalogu do kopiowania jest nieprawidłowa.
	|Być może konto, w imieniu którego pracuje
	|serwer 1C:Enterprise, nie posiada praw dostępu do wskazanego katalogu.
	|
	|%1';
	|de = 'Der zu kopierende Verzeichnispfad ist falsch.
	|Es ist möglich, dass das Konto, für das der
	|1C:Enterprise Server ausgeführt wird, keine Zugriffsrechte für das angegebene Verzeichnis hat.
	|
	|%1';
	|ro = 'Calea catalogului pentru copiere nu este corectă.
	|Posibil contul, din numele căruia funcționează
	|serverul 1C:Enterprise nu are drepturi de acces la directorul indicat.
	|
	|%1';
	|tr = 'Birim yolu doğru değil. 
	|1C:Enterprise sunucusunun 
	|çalıştığı hesap, disk bölümü dizinine erişim haklarına sahip değildir. 
	|
	|%1'; 
	|es_ES = 'La ruta al catálogo de copiar no es correcta.
	|Es posible que la cuenta que usa
	|el servidor de 1C:Enterprise no tenga derechos de acceso al catálogo del tomo.
	|
	|%1'");
	
	ErrorText = StringFunctionsClientServer.SubstituteParametersToString(ErrorTemplate, BriefErrorDescription(ErrorInformation));
	CommonClient.MessageToUser(ErrorText, , , "PathToFolderToCopy");
	
	ExecuteNotifyProcessing(SourceNotification, False);
	
EndProcedure

&AtServer
Procedure ProcessErrorMessage(FileName, ErrorInformation)
	
	WriteLogEvent(NStr("ru = 'Файлы.Ошибка удаления лишних файлов'; en = 'Files.Extraneous files deletion error'; pl = 'Pliki. Błąd usuwania zbędnych plików';de = 'Dateien.Fehler beim Löschen nicht benötigter Dateien';ro = 'Fișiere.Eroare de ștergere a fișierelor nedorite';tr = 'Dosyalar. Gereksiz dosyaları silme hatası'; es_ES = 'Archivos.Error de eliminar los archivos de sobra'", Common.DefaultLanguageCode()),
		EventLogLevel.Information,,,
		StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'При удалении файла с диска
				|""%1""
				|возникла ошибка:
				|""%2"".'; 
				|en = 'Cannot delete file
				|%1
				|from the hard drive. Reason:
				|%2'; 
				|pl = 'Podczas usuwania pliku z dysku
				|""%1""
				|zaistniał błąd:
				|""%2"".';
				|de = 'Beim Löschen einer Datei von der Festplatte 
				|""%1""
				| tritt ein Fehler auf:
				|""%2"".';
				|ro = 'La ștergerea fișierului de pe discul
				|""%1""
				|s-a produs eroarea:
				|""%2"".';
				|tr = 'Bir dosya diskten silindiğinde 
				|""%1""
				|bir hata oluştu: 
				|""%2"".'; 
				|es_ES = 'Al eliminar el archivo del disco
				|""%1""
				|se ha producido un error:
				|""%2"".'"),
			FileName,
			ErrorInformation));
		
EndProcedure

&AtServer
Procedure GenerateErrorsReport(ErrorsReport, FilesArrayWithErrors)
	
	TabTemplate = Catalogs.FileStorageVolumes.GetTemplate("ReportTemplate");
	
	AreaHeader = TabTemplate.GetArea("Title");
	AreaHeader.Parameters.Details = NStr("ru = 'Файлы с ошибками:'; en = 'Files with errors:'; pl = 'Pliki z błędami:';de = 'Dateien mit Fehlern:';ro = 'Fișiere cu erori:';tr = 'Hatalı dosyalar:'; es_ES = 'Archivos con errores:'");
	ErrorsReport.Put(AreaHeader);
	
	AreaRow = TabTemplate.GetArea("Row");
	
	For Each FileWithError In FilesArrayWithErrors Do
		AreaRow.Parameters.Name = FileWithError.Name;
		AreaRow.Parameters.Error = FileWithError.Error;
		ErrorsReport.Put(AreaRow);
	EndDo;
	
EndProcedure

#EndRegion