///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Internal

// See ObjectAttributesLock.OnDefineObjectsWithLockedAttributes. 
Procedure OnDefineObjectsWithLockedAttributes(Objects) Export
	Objects.Insert(Metadata.Catalogs.FileSynchronizationAccounts.FullName(), "");
EndProcedure

// Used when exporting files to go to the service (STL).
//
Procedure ExportFile(Val FileObject, Val NewFileName) Export
	
	If FileObject.FileStorageType = Enums.FileStorageTypes.InVolumesOnHardDrive Then
		
		FullPath = FullVolumePath(FileObject.Volume) + FileObject.PathToFile;
		FileCopy(FullPath, NewFileName);
		
		// The source file could have been set to Read only.
		// An attribute inherited while copying is removed before deleting the file.
		FileProperties = New File(NewFileName);
		
		If FileProperties.Exist() AND FileProperties.GetReadOnly() Then
			
			FileProperties.SetReadOnly(False);
			
		EndIf;
		
	Else // Enums.FilesStorageTypes.InInfobase
		
		FileBinaryData = FilesOperations.FileBinaryData(FileObject.Ref);
		FileBinaryData.Write(NewFileName);
		
	EndIf;
	
	FillFilePathOnSend(FileObject);
	
EndProcedure

// Used when importing files to go to the service (STL).
//
Procedure ImportFile(Val FileObject, Val PathToFile) Export
	
	BinaryData = New BinaryData(PathToFile);
	
	If FilesStorageTyoe() = Enums.FileStorageTypes.InVolumesOnHardDrive Then
		
		If TypeOf(FileObject.Ref) = Type("CatalogRef.FilesVersions") Then
			VersionNumber = FileObject.VersionNumber;
		Else
			VersionNumber = "";
		EndIf;
		
		// Adding file to a volume with sufficient free space
		FileInfo = AddFileToVolume(BinaryData, 
			FileObject.UniversalModificationDate, FileObject.Description, FileObject.Extension,
			VersionNumber, FilePathOnGetHasFlagEncrypted(FileObject));
		
		FileObject.Volume = FileInfo.Volume;
		FileObject.PathToFile = FileInfo.PathToFile;
		FileObject.FileStorageType = Enums.FileStorageTypes.InVolumesOnHardDrive;
		FileObject.FileStorage = New ValueStorage(Undefined);
		
	Else
		
		FileObject.AdditionalProperties.Insert("FileBinaryData", BinaryData);
		FileObject.FileStorage = New ValueStorage(Undefined);
		FileObject.Volume = Catalogs.FileStorageVolumes.EmptyRef();
		FileObject.PathToFile = "";
		FileObject.FileStorageType = Enums.FileStorageTypes.InInfobase;
		
	EndIf;
	
EndProcedure

Procedure FillAdditionalFileData(Result, AttachedFile, FileVersion = Undefined) Export
	
	CatalogSupportsPossibitityToStoreVersions = Common.HasObjectAttribute("CurrentVersion", Metadata.FindByType(TypeOf(AttachedFile)));
	
	If CatalogSupportsPossibitityToStoreVersions AND ValueIsFilled(AttachedFile.CurrentVersion) Then
		CurrentFileVersion = AttachedFile.CurrentVersion;
	Else
		CurrentFileVersion = AttachedFile.Ref;
	EndIf;
	
	Result.Insert("CurrentVersion", CurrentFileVersion);
	
	If FileVersion <> Undefined Then
		Result.Insert("Version", FileVersion);
	ElsIf CatalogSupportsPossibitityToStoreVersions AND ValueIsFilled(AttachedFile.CurrentVersion) Then
		Result.Insert("Version", AttachedFile.CurrentVersion);
	Else
		Result.Insert("Version", AttachedFile.Ref);
	EndIf;
	
	If ValueIsFilled(FileVersion) Then
		CurrentVersionObject = FileVersion.GetObject();
		Result.Insert("VersionNumber", CurrentVersionObject.VersionNumber);
		CurrentFileVersion = FileVersion;
	Else
		Result.Insert("VersionNumber", 0);
		CurrentFileVersion = Result.Version;
		CurrentVersionObject = AttachedFile;
	EndIf;
	
	Result.Insert("Description",                 CurrentVersionObject.Description);
	Result.Insert("Extension",                   CurrentVersionObject.Extension);
	Result.Insert("Size",                       CurrentVersionObject.Size);
	Result.Insert("UniversalModificationDate", CurrentVersionObject.UniversalModificationDate);
	Result.Insert("Volume",                          CurrentVersionObject.Volume);
	Result.Insert("Author",                        CurrentVersionObject.Author);
	Result.Insert("TextExtractionStatus",       CurrentVersionObject.TextExtractionStatus);
	Result.Insert("FullVersionDescription",     TrimAll(CurrentVersionObject.Description));
	
	KeyStructure = New Structure("File", CurrentFileVersion);
	RecordKey = InformationRegisters.BinaryFilesData.CreateRecordKey(KeyStructure);
	CurrentVersionURL = GetURL(RecordKey, "FileBinaryData");
	Result.Insert("CurrentVersionURL", CurrentVersionURL);
	
	CurrentVersionEncoding = GetFileVersionEncoding(CurrentFileVersion);
	Result.Insert("CurrentVersionEncoding", CurrentVersionEncoding);
	CurrentUser = Users.AuthorizedUser();
	ForReading = Result.BeingEditedBy <> CurrentUser;
	Result.Insert("ForReading", ForReading);
	
	InWorkingDirectoryForRead = True;
	InOwnerWorkingDirectory = False;
	DirectoryName = UserWorkingDirectory();
	
	If ValueIsFilled(CurrentFileVersion) Then
		FullFileNameInWorkingDirectory = FilesOperationsInternalServerCall.GetFullFileNameFromRegister(CurrentFileVersion, DirectoryName, InWorkingDirectoryForRead, InOwnerWorkingDirectory);
	
		Result.Insert("FullFileNameInWorkingDirectory", FullFileNameInWorkingDirectory);
	EndIf;
	Result.Insert("InWorkingDirectoryForRead", InWorkingDirectoryForRead);
	Result.Insert("OwnerWorkingDirectory", "");
	
	EditedByCurrentUser = (Result.BeingEditedBy = CurrentUser);
	Result.Insert("CurrentUserEditsFile", EditedByCurrentUser);
	
	TextExtractionStatusString = "NotExtracted";
	If Result.TextExtractionStatus = Enums.FileTextExtractionStatuses.NotExtracted Then
		TextExtractionStatusString = "NotExtracted";
	ElsIf Result.TextExtractionStatus = Enums.FileTextExtractionStatuses.Extracted Then
		TextExtractionStatusString = "Extracted";
	ElsIf Result.TextExtractionStatus = Enums.FileTextExtractionStatuses.FailedExtraction Then
		TextExtractionStatusString = "FailedExtraction";
	EndIf;
	Result.Insert("TextExtractionStatus", TextExtractionStatusString);
	
	FolderForSaveAs = Common.CommonSettingsStorageLoad("ApplicationSettings", "FolderForSaveAs");
	Result.Insert("FolderForSaveAs", FolderForSaveAs);
	
EndProcedure

// Adds settings specific to the "Stored files"  subsystem.
//
// Parameters:
//  CommonSettings        - Structure - settings common for all users.
//  PersonalSettings - Structure - settings different for different users.
//  
Procedure AddFilesOperationsSettings(CommonSettings, PersonalSettings) Export
	
	SetPrivilegedMode(True);
	
	PersonalSettings.Insert("ActionOnDoubleClick", ActionOnDoubleClick());
	PersonalSettings.Insert("FileVersionsComparisonMethod",  FileVersionsComparisonMethod());
	
	PersonalSettings.Insert("PromptForEditModeOnOpenFile",
		PromptForEditModeOnOpenFile());
	
	PersonalSettings.Insert("IsFullUser",
		Users.IsFullUser(,, False));
	
	ShowLockedFilesOnExit = Common.CommonSettingsStorageLoad(
		"ApplicationSettings", "ShowLockedFilesOnExit");
	
	If ShowLockedFilesOnExit = Undefined Then
		ShowLockedFilesOnExit = True;
		
		Common.CommonSettingsStorageSave(
			"ApplicationSettings",
			"ShowLockedFilesOnExit",
			ShowLockedFilesOnExit);
	EndIf;
	
	PersonalSettings.Insert("ShowLockedFilesOnExit",
		ShowLockedFilesOnExit);
	
	PersonalSettings.Insert("ShowSizeColumn", GetShowSizeColumn());
	
EndProcedure

// It will return the total size of files in a volume (in bytes).
Function CalculateFileSizeInVolume(VolumeRef) Export
	
	If Not Common.SeparatedDataUsageAvailable() Then
		Return 0;
	EndIf;
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	ISNULL(SUM(Versions.Size), 0) AS FilesSize
	|FROM
	|	Catalog.FilesVersions AS Versions
	|WHERE
	|	Versions.Volume = &Volume";
	
	Query.Parameters.Insert("Volume", VolumeRef);
	
	Selection = Query.Execute().Select();
	
	If Selection.Next() Then
		FileSizeInVolume = Number(Selection.FilesSize);
	EndIf;
	
	OwnersTypes = Metadata.InformationRegisters.FilesExist.Dimensions.ObjectWithFiles.Type.Types();
	TotalCatalogNames = New Map;
	
	Query = New Query;
	Query.Parameters.Insert("Volume", VolumeRef);
	
	For Each Type In OwnersTypes Do
		
		If Type = Type("CatalogRef.MetadataObjectIDs") Then
			Continue;
		EndIf;
		
		CatalogNames = FileStorageCatalogNames(Type, True);
		
		For each KeyAndValue In CatalogNames Do
			If TotalCatalogNames[KeyAndValue.Key] <> Undefined Then
				Continue;
			EndIf;
			AttachedFilesCatalogName = KeyAndValue.Key;
			TotalCatalogNames.Insert(KeyAndValue.Key, True);
		
			Query.Text =
			"SELECT
			|	ISNULL(SUM(AttachedFiles.Size), 0) AS FilesSize
			|FROM
			|	&CatalogName AS AttachedFiles
			|WHERE
			|	AttachedFiles.Volume = &Volume";
			Query.Text = StrReplace(Query.Text, "&CatalogName",
				"Catalog." + AttachedFilesCatalogName);
			
			Selection = Query.Execute().Select();
			If Selection.Next() Then
				FileSizeInVolume = FileSizeInVolume + Selection.FilesSize;
			EndIf
		EndDo;
	EndDo;
	
	Return FileSizeInVolume;
	
EndFunction

// Reads file version encoding.
//
// Parameters:
//   VersionRef - a reference to file version.
//
// Returns:
//   Encoding string
Function GetFileVersionEncoding(VersionRef) Export
	
	SetPrivilegedMode(True);
	
	RecordManager = InformationRegisters.FilesEncoding.CreateRecordManager();
	RecordManager.File = VersionRef;
	RecordManager.Read();
	
	Return RecordManager.Encoding;
	
EndFunction

// Receives all subordinate files.
// Parameters:
//  FileOwner - AnyRef - a file owner.
//
// Returns:
//   Array - an array of files
Function GetAllSubordinateFiles(FileOwner) Export
	
	Query = New Query;
	Query.Text =
	"SELECT ALLOWED
	|	Files.Ref AS Ref
	|FROM
	|	Catalog.Files AS Files
	|WHERE
	|	Files.FileOwner = &FileOwner";
	
	Query.SetParameter("FileOwner", FileOwner);
	
	Return Query.Execute().Unload().UnloadColumn("Ref");
	
EndFunction

// Returns True if a file with such extension can be imported.
Function CheckExtentionOfFileToDownload(FileExtention, RaiseException = True) Export
	
	CommonSettings = FilesOperationsInternalCached.FilesOperationSettings().CommonSettings;
	
	If NOT CommonSettings.FilesImportByExtensionDenied Then
		Return True;
	EndIf;
	
	If FilesOperationsInternalClientServer.FileExtensionInList(
		CommonSettings.DeniedExtensionsList, FileExtention) Then
		
		If RaiseException Then
			Raise StringFunctionsClientServer.SubstituteParametersToString(
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
				FileExtention);
		Else
			Return False;
		EndIf;
	EndIf;
	
	Return True;
	
EndFunction

////////////////////////////////////////////////////////////////////////////////
// Procedures used for data exchange.

// Returns the array of catalogs that own files.
//
// Returns: Array (MetadataObject).
//
Function FilesCatalogs() Export
	
	Result = New Array();
	
	MetadataCollections = New Array();
	MetadataCollections.Add(Metadata.Catalogs);
	MetadataCollections.Add(Metadata.Documents);
	MetadataCollections.Add(Metadata.BusinessProcesses);
	MetadataCollections.Add(Metadata.Tasks);
	MetadataCollections.Add(Metadata.ChartsOfAccounts);
	MetadataCollections.Add(Metadata.ExchangePlans);
	MetadataCollections.Add(Metadata.ChartsOfCharacteristicTypes);
	MetadataCollections.Add(Metadata.ChartsOfCalculationTypes);
	
	For Each MetadataCollection In MetadataCollections Do
		
		For Each MetadataObject In MetadataCollection Do
			
			ObjectManager = Common.ObjectManagerByFullName(MetadataObject.FullName());
			EmptyRef = ObjectManager.EmptyRef();
			FileStorageCatalogNames = FileStorageCatalogNames(EmptyRef, True);
			
			For Each FileStoringCatalogName In FileStorageCatalogNames Do
				Result.Add(Metadata.Catalogs[FileStoringCatalogName.Key]);
			EndDo;
			
		EndDo;
		
	EndDo;
	
	Result.Add(Metadata.Catalogs.FilesVersions);
	
	Return Result;
	
EndFunction

// Returns an array of metadata objects used for storing binary file data in the infobase.
// 
//
// Returns: Array (MetadataObject).
//
Function InfobaseFileStoredObjects() Export
	
	Result = New Array();
	Result.Add(Metadata.InformationRegisters.BinaryFilesData);
	Return Result;
	
EndFunction

// Returns a file extension.
//
// Object - CatalogObject,
//
Function FileExtention(Object) Export
	
	Return Object.Extension;
	
EndFunction

// Returns objects that have attached files (using the "Stored files" subsystem).
//
// Used together with the AttachedFiles.ConvertFilesInAttached() function.
//
// Parameters:
//  FilesOwnersTable - String - a full name of metadata that can own attached files.
//                            
//
Function ReferencesToObjectsWithFiles(Val FilesOwnersTable) Export
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	ObjectsWithFiles.Ref AS Ref
	|FROM
	|	&Table AS ObjectsWithFiles
	|WHERE
	|	TRUE IN
	|			(SELECT TOP 1
	|				TRUE
	|			FROM
	|				Catalog.Files AS Files
	|			WHERE
	|				Files.FileOwner = ObjectsWithFiles.Ref)";
	
	Query.Text = StrReplace(Query.Text, "&Table", FilesOwnersTable);
	
	Return Query.Execute().Unload().UnloadColumn("Ref");
	
EndFunction

// Checks the the current user right when using the limit for a folder or file.
// 
//
// Parameters:
//   Folder - CatalogRef.FilesFolders, CatalogRef.Files - a file folder.
//       - CatalogRef - owner of the files.
//
// Usage locations:
//   ReportsMailing.FillMailingParametersWithDefaultParameters().
//   Catalog.ReportsMailings.Forms.ItemForm.FolderAndFilesChangeRight().
//
Function RightToAddFilesToFolder(Folder) Export
	
	If Common.SubsystemExists("StandardSubsystems.AccessManagement") Then
		ModuleAccessManagement = Common.CommonModule("AccessManagement");
		Return ModuleAccessManagement.HasRight("AddFiles", Folder);
	EndIf;
	
	Return True;
	
EndFunction

// Writes attachments to a folder.
// 
// Parameters: see the ExecuteDelivery procedure description of the ReportsMailing module.
//
Procedure OnExecuteDeliveryToFolder(DeliveryParameters, Attachments) Export
	
	// Transfer attachments to the table
	SetPrivilegedMode(True);
	
	AttachmentsTable = New ValueTable;
	AttachmentsTable.Columns.Add("FileName",              New TypeDescription("String"));
	AttachmentsTable.Columns.Add("FullFilePath",      New TypeDescription("String"));
	AttachmentsTable.Columns.Add("File",                  New TypeDescription("File"));
	AttachmentsTable.Columns.Add("FileRef",            New TypeDescription("CatalogRef.Files"));
	AttachmentsTable.Columns.Add("FileNameWithoutExtension", Metadata.Catalogs.Files.StandardAttributes.Description.Type);
	
	SetPrivilegedMode(False);
	
	For Each Attachment In Attachments Do
		TableRow = AttachmentsTable.Add();
		TableRow.FileName              = Attachment.Key;
		TableRow.FullFilePath      = Attachment.Value;
		TableRow.File                  = New File(TableRow.FullFilePath);
		TableRow.FileNameWithoutExtension = TableRow.File.BaseName;
	EndDo;
	
	// Searching the existing files
	Query = New Query;
	Query.Text = 
	"SELECT ALLOWED DISTINCT
	|	Files.Ref,
	|	Files.Description
	|FROM
	|	Catalog.Files AS Files
	|WHERE
	|	Files.FileOwner = &FileOwner
	|	AND Files.Description IN(&FileNamesArray)";
	
	Query.SetParameter("FileOwner", DeliveryParameters.Folder);
	Query.SetParameter("FileNamesArray", AttachmentsTable.UnloadColumn("FileNameWithoutExtension"));
	
	ExistingFiles = Query.Execute().Unload();
	For Each File In ExistingFiles Do
		TableRow = AttachmentsTable.Find(File.Description, "FileNameWithoutExtension");
		TableRow.FileRef = File.Ref;
	EndDo;
	
	Comment = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("ru = 'Рассылка отчетов %1 от %2'; en = 'Report mailing: %1, %2'; pl = 'Wysyłanie raportów %1 od %2';de = 'Versand von Berichten %1 von %2';ro = 'Trimiterea rapoartelor %1 de la %2';tr = '%1 raporların %2 ''den gönderimi '; es_ES = 'Informes de envío de correos electrónicos %1 de %2'"),
		"'"+ DeliveryParameters.BulkEmail +"'",
		Format(DeliveryParameters.ExecutionDate, "DLF=DT"));
	
	For Each Attachment In AttachmentsTable Do
		
		FileInfo = FilesOperationsClientServer.FileInfo("FileWithVersion", Attachment.File);
		FileInfo.TempFileStorageAddress = PutToTempStorage(New BinaryData(Attachment.FullFilePath));
		FileInfo.BaseName = Attachment.FileNameWithoutExtension;
		FileInfo.Comment = Comment;
		
		// Record
		If ValueIsFilled(Attachment.FileRef) Then
			VersionRef = CreateVersion(Attachment.FileRef, FileInfo);
			UpdateVersionInFile(Attachment.FileRef, VersionRef, FileInfo.TempTextStorageAddress);
		Else
			Attachment.FileRef = FilesOperationsInternalServerCall.CreateFileWithVersion(DeliveryParameters.Folder, FileInfo); 
		EndIf;
		
		// Filling the reference to file
		If DeliveryParameters.AddReferences <> "" Then
			DeliveryParameters.RecipientReportsPresentation = StrReplace(
				DeliveryParameters.RecipientReportsPresentation,
				Attachment.FullFilePath,
				GetInfoBaseURL() + "#" + GetURL(Attachment.FileRef));
		EndIf;
		
		// Clearing
		DeleteFromTempStorage(FileInfo.TempFileStorageAddress);
	EndDo;
	
EndProcedure

// Sets a deletion mark for all versions of the specified file.
Procedure MarkForDeletionFileVersions(Val FileRef, Val VersionException) Export
	
	FullVersionsCatalogName = Metadata.FindByType(TypeOf(VersionException)).FullName();
	
	QueryText =
	"SELECT
	|	FilesVersions.Ref AS Ref
	|FROM
	|	Catalog." + Metadata.FindByType(FullVersionsCatalogName) + " AS FilesVersions
	|WHERE
	|	FilesVersions.Owner = &Owner
	|	AND NOT FilesVersions.DeletionMark
	|	AND FilesVersions.Ref <> &Except";
	
	Query = New Query;
	Query.Text = QueryText;
	Query.SetParameter("Owner", FileRef);
	Query.SetParameter("Except", VersionException);
	VersionsSelection = Query.Execute().Unload();
	
	BeginTransaction();
	Try
		Lock = New DataLock;
		For Each Version In VersionsSelection Do
			LockItem = Lock.Add(FullVersionsCatalogName);
			LockItem.SetValue("Ref", Version.Ref);
		EndDo;
		Lock.Lock();
		
		For Each Version In VersionsSelection Do
			VersionObject = Version.Ref.GetObject();
			VersionObject.DeletionMark = True;
			VersionObject.AdditionalProperties.Insert("FileConversion", True);
			VersionObject.Write();
		EndDo;
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;
	
EndProcedure

// Returns the map of catalog names and Boolean values for the specified owner.
// 
// 
// Parameters:
//  FilesOwher - Reference - an object for adding file.
// 
Function FileStorageCatalogNames(FilesOwner, DoNotRaiseException = False) Export
	
	If TypeOf(FilesOwner) = Type("Type") Then
		FilesOwnerType = FilesOwner;
	Else
		FilesOwnerType = TypeOf(FilesOwner);
	EndIf;
	
	OwnerMetadata = Metadata.FindByType(FilesOwnerType);
	
	CatalogNames = New Map;
	
	StandardMainCatalogName = OwnerMetadata.Name
		+ ?(StrEndsWith(OwnerMetadata.Name, "AttachedFiles"), "", "AttachedFiles");
		
	If Metadata.Catalogs.Find(StandardMainCatalogName) <> Undefined Then
		CatalogNames.Insert(StandardMainCatalogName, True);
	ElsIf Metadata.DefinedTypes.FilesOwner.Type.ContainsType(FilesOwnerType) Then
		CatalogNames.Insert("Files", True);
	EndIf;
	
	// Redefining the default catalog for attached file storage.
	FilesOperationsOverridable.OnDefineFileStorageCatalogs(
		FilesOwnerType, CatalogNames);
	
	DefaultCatalogIsSpecified = False;
	
	For each KeyAndValue In CatalogNames Do
		
		If Metadata.Catalogs.Find(KeyAndValue.Key) = Undefined Then
			
			Raise StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'Ошибка при определении имен справочников для хранения файлов.
				           |У владельца файлов типа ""%1""
				           |указан несуществующий справочник ""%2"".'; 
				           |en = 'Cannot determine a file storage catalog name.
				           |Missing catalog ""%2""
				           |is assigned to the owner of files of ""%1"" type.'; 
				           |pl = 'Błąd przy ustalaniu nazw przewodników do przechowywania plików.
				           |U właściciela plików rodzaju ""%1""
				           |jest podany nieistniejący przewodnik ""%2"".';
				           |de = 'Fehler bei der Definition von Verzeichnisnamen für die Dateiablage.
				           |Der Eigentümer des Dateityps ""%1""
				           |hat ein nicht existierendes Verzeichnis ""%2"".';
				           |ro = 'Eroare la determinarea numelor clasificatoarelor pentru a stoca fișierele.
				           |La titularul fișierelor de tipul ""%1""
				           |este specificat clasificatorul inexistent ""%2"".';
				           |tr = 'Dosyaları depolamak için katalog adları belirlenirken bir hata oluştu. 
				           |"
" tür dosya sahibinde ""%1"" varolmayan %2 katalog belirtildi.'; 
				           |es_ES = 'Ha ocurrido un error al determinar los nombres de catálogos para guardar los archivos.
				           |En el propietario de archivos del ""%1""
				           |tipo el catálogo inexistente ""%2"" está especificado.'"),
				String(FilesOwnerType),
				String(KeyAndValue.Key));
				
		ElsIf Not StrEndsWith(KeyAndValue.Key, "AttachedFiles") AND Not KeyAndValue.Key ="Files" Then
			
			Raise StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'Ошибка при определении имен справочников для хранения файлов.
				           |У владельца файлов типа ""%1""
				           |указано имя справочника ""%2""
				           |без окончания ""ПрисоединенныеФайлы"".'; 
				           |en = 'Cannot determine a file storage catalog name.
				           |Catalog ""%2""
				           |that does not have the ""AttachedFiles"" suffix
				           |is assigned to the file owner of ""%1"" type.'; 
				           |pl = 'Błąd przy ustalaniu nazw przewodników do przechowywania plików.
				           |U właściciela plików rodzaju ""%1""
				           |podano nazwę przewodnika ""%2""
				           |bez zakończenia ""Dołączone Pliki"".';
				           |de = 'Bei der Definition von Katalognamen für die Dateiablage ist ein Fehler aufgetreten.
				           |Der Katalogname ""%2""
				           | ohne Endung ""AttachedFiles""
				           |wird für den Dateibesitzer vom Typ ""%1"" angegeben.';
				           |ro = 'A apărut o eroare la definirea denumirilor de cataloage pentru stocarea fișierelor.
				           |Numele de catalog ""%2""
				           |fără a se termina ""AttachedFiles""
				           |este specificat pentru proprietarul de fișier de tip ""%1"".';
				           |tr = 'Dosyaları depolamak için katalog adları belirlenirken bir hata oluştu. 
				           |"
" tür dosya sahibinde ""%1"" katalog 
				           |adı ""%2"" ""AttachedFiles"" takısı olmadan belirtildi.'; 
				           |es_ES = 'Ha ocurrido un error al determinar los nombres de catálogos para guardar los archivos.
				           |En el propietario de archivos del tipo ""%1""
				           | el nombre del catálogo ""%2""
				           |está especificado sin acabar ""AttachedFiles"".'"),
				String(FilesOwnerType),
				String(KeyAndValue.Key));
			
		ElsIf KeyAndValue.Value = Undefined Then
			CatalogNames.Insert(KeyAndValue.Key, False);
			
		ElsIf KeyAndValue.Value = True Then
			If DefaultCatalogIsSpecified Then
				Raise StringFunctionsClientServer.SubstituteParametersToString(
					NStr("ru = 'Ошибка при определении имен справочников для хранения файлов.
					           |У владельца файлов типа ""%1""
					           |основной справочник указан более одного раза.'; 
					           |en = 'Cannot determine a file storage catalog name.
					           |Multiple main catalogs are assigned to the owner of files of 
					           |""%1"" type.'; 
					           |pl = 'Błąd przy ustalaniu nazw przewodników do przechowywania plików.
					           |U właściciela plików rodzaju ""%1""
					           |podstawowy przewodnik został podany więcej niż jeden raz.';
					           |de = 'Fehler bei der Definition von Verzeichnisnamen für die Dateiablage.
					           |Der Eigentümer von Dateien vom Typ ""%1""
					           | hat das Hauptverzeichnis mehr als einmal.';
					           |ro = 'Eroare la determinarea numelor clasificatoarelor pentru a stoca fișierele.
					           |La titularul fișierelor de tipul ""%1""
					           |clasificatorul principal este specificat mai mult de o dată.';
					           |tr = 'Dosyaları depolamak için katalog adları belirlenirken bir hata oluştu. 
					           | "
"tür dosya sahibi %1 ana katalog birden fazla kez belirtildi.'; 
					           |es_ES = 'Ha ocurrido un error al determinar los nombre de catálogos para guardar los archivos.
					           |El propietario de archivos del tipo ""%1""
					           |tiene el catálogo principal especificado más de una vez.'"),
					String(FilesOwnerType),
					String(KeyAndValue.Key));
			EndIf;
			DefaultCatalogIsSpecified = True;
		EndIf;
	EndDo;
	
	If CatalogNames.Count() = 0 Then
		
		If DoNotRaiseException Then
			Return CatalogNames;
		EndIf;
		
		Raise StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Ошибка при определении имен справочников для хранения файлов.
			           |У владельца файлов типа ""%1""
			           |не имеется справочников для хранения файлов.'; 
			           |en = 'Cannot determine a file storage catalog name.
			           |The owner of files of ""%1"" type
			           |does not have file storage catalogs.'; 
			           |pl = 'Błąd przy ustalaniu nazw przewodników do przechowywania plików.
			           |U właściciela plików rodzaju ""%1""
			           |nie ma poradników do przechowywania plików.';
			           |de = 'Fehler bei der Definition von Verzeichnisnamen für die Dateiablage.
			           |Der ""%1""
			           | Dateieigentümer hat keine Verzeichnisse zum Speichern von Dateien.';
			           |ro = 'Eroare la determinarea numelor clasificatoarelor pentru a stoca fișierele.
			           |La titularul fișierelor de tipul ""%1""
			           |nu există clasificatoare pentru stocarea fișierelor.';
			           |tr = 'Dosyaları depolamak için katalog adları belirlenirken bir hata oluştu. 
			           |""
			           |%1"" tür dosya sahibinin dosyaların depolanacağı katalogları yok.'; 
			           |es_ES = 'Ha ocurrido un error al determinar los nombre de catálogos para guardar los archivos.
			           |El propietario de archivos del tipo ""%1""
			           |no tiene catálogos para guardar los archivos.'"),
			String(FilesOwnerType));
	EndIf;
	
	Return CatalogNames;
	
EndFunction

// Creates copies of all Source attached files for the Recipient.
// Source and Recipient must be objects of the same type.
//
// Parameters:
//  Source   - Reference - an object with attached files for copying.
//  Recipient - Reference - an object, to which the attached files are copied to.
//
Procedure CopyAttachedFiles(Val Source, Val Recipient) Export
	
	DigitalSignatureAvailable = Undefined;
	ModuleDigitalSignatureInternal = Undefined;
	If Common.SubsystemExists("StandardSubsystems.DigitalSignature") Then
		ModuleDigitalSignature = Common.CommonModule("DigitalSignature");
		ModuleDigitalSignatureInternal = Common.CommonModule("DigitalSignatureInternal");
	EndIf;
	
	CopiedFiles = AllSubordinateFiles(Source.Ref);
	For Each CopiedFile In CopiedFiles Do
		If DigitalSignatureAvailable = Undefined Then
			DigitalSignatureAvailable = (ModuleDigitalSignatureInternal <> Undefined) 
				AND (ModuleDigitalSignatureInternal.DigitalSignatureAvailable(TypeOf(CopiedFile)));
		EndIf;
		If Common.ObjectAttributeValue(CopiedFile, "DeletionMark") Then
			Continue;
		EndIf;
		BeginTransaction();
		Try
			ObjectManager = Common.ObjectManagerByRef(CopiedFile);
			FileCopy = CopiedFile.Copy();
			FileCopyRef = ObjectManager.GetRef();
			FileCopy.SetNewObjectRef(FileCopyRef);
			FileCopy.FileOwner = Recipient.Ref;
			FileCopy.BeingEditedBy = Catalogs.Users.EmptyRef();
			
			FileCopy.TextStorage = CopiedFile.TextStorage;
			FileCopy.TextExtractionStatus = CopiedFile.TextExtractionStatus;
			FileCopy.FileStorage = CopiedFile.FileStorage;
			
			BinaryData = FilesOperations.FileBinaryData(CopiedFile);
			FileCopy.FileStorageType = FilesStorageTyoe();
			
			If FilesStorageTyoe() = Enums.FileStorageTypes.InInfobase Then
				WriteFileToInfobase(FileCopyRef, BinaryData);
			Else
				// Add the file to a volume with sufficient free space.
				FileInfo = AddFileToVolume(BinaryData, FileCopy.UniversalModificationDate,
					FileCopy.Description, FileCopy.Extension);
				FileCopy.PathToFile = FileInfo.PathToFile;
				FileCopy.Volume = FileInfo.Volume;
			EndIf;
			FileCopy.Write();
			
			If DigitalSignatureAvailable Then
				SetSignatures = ModuleDigitalSignature.SetSignatures(CopiedFile);
				ModuleDigitalSignature.AddSignature(FileCopy.Ref, SetSignatures);
				
				SourceCertificates = ModuleDigitalSignature.EncryptionCertificates(CopiedFile);
				ModuleDigitalSignature.WriteEncryptionCertificates(FileCopy, SourceCertificates);
			EndIf;
			CommitTransaction();
		Except
			RollbackTransaction();
			Raise;
		EndTry;
	EndDo;
	
EndProcedure

// Returns file object structure.
//
Function FileObject(Val AttachedFile) Export
	
	FileObject = Undefined;
	
	FileObjectMetadata = Metadata.FindByType(TypeOf(AttachedFile));
	
	// This is the file catalog.
	If Common.HasObjectAttribute("FileOwner", FileObjectMetadata) Then
		// With the ability to store versions.
		If Common.HasObjectAttribute("CurrentVersion", FileObjectMetadata) AND ValueIsFilled(AttachedFile.CurrentVersion) Then
			FileObject = Common.ObjectAttributesValues(AttachedFile.CurrentVersion, 
					"Ref, FileStorageType, Description,Extension,Volume,PathToFile");
			FileObject.Insert("FileOwner", AttachedFile.FileOwner);
		// Without the ability to store versions.
		Else
			FileObject = Common.ObjectAttributesValues(AttachedFile, 
				"Ref, FileStorageType,FileOwner,Description,Extension,Volume,PathToFile");
		EndIf;
	// This is a catalog of file versions.
	ElsIf Common.HasObjectAttribute("ParentVersion", FileObjectMetadata) Then
		FileObject = Common.ObjectAttributesValues(AttachedFile, 
			"Ref, FileStorageType,Description,Extension,Volume,PathToFile");
		FileObject.Insert("FileOwner",
			Common.ObjectAttributeValue(AttachedFile.Owner, "FileOwner"));
	EndIf;
	
	Return FileObject;
	
EndFunction

////////////////////////////////////////////////////////////////////////////////
// Clear unused files

Function QueryTextToClearFiles(FileOwner, Setting, ExceptionsArray, ExceptionItem, DataForReport = False) Export
	
	FullFilesCatalogName = Setting.FileOwnerType.FullName;
	FilesObjectMetadata = Metadata.FindByFullName(FullFilesCatalogName);
	HasAbilityToStoreVersions = Common.HasObjectAttribute("CurrentVersion", FilesObjectMetadata);
	If HasAbilityToStoreVersions Then
		CatalogFilesVersions = Common.MetadataObjectID(FilesObjectMetadata.Attributes.CurrentVersion.Type.Types()[0]);
		FullFilesVersionsCatalogName = CatalogFilesVersions.FullName;
		
		If Setting.ClearingPeriod <> Enums.FilesCleanupPeriod.ByRule Then
			If DataForReport Then
				QueryText = 
				"SELECT 
				|	VALUETYPE(Files.FileOwner) AS FileOwner,
				|	FilesVersions.Size /1024 /1024 AS IrrelevantFilesVolume";
			Else
				QueryText = 
				"SELECT 
				|	Files.Ref AS FileRef,
				|	FilesVersions.Ref AS VersionRef";
			EndIf;
			QueryText = QueryText + "
			|FROM
			|	" + FullFilesCatalogName + " AS Files
			|		INNER JOIN " + FullFilesVersionsCatalogName + " AS FilesVersions
			|		ON Files.Ref = FilesVersions.Owner
			|WHERE
			|	FilesVersions.CreationDate <= &ClearingPeriod
			|	AND NOT Files.DeletionMark
			|	AND VALUETYPE(Files.FileOwner) = &OwnerType
			|	AND CASE
			|			WHEN FilesVersions.FileStorageType = VALUE(Enum.FileStorageTypes.InVolumesOnHardDrive)
			|				THEN FilesVersions.Volume <> VALUE(Catalog.FileStorageVolumes.EmptyRef)
			|						OR (CAST(FilesVersions.PathToFile AS STRING(100))) <> """"
			|			ELSE TRUE
			|		END
			|	";
		Else
			
			ObjectType = FileOwner;
			AllCatalogs = Catalogs.AllRefsType();
			AllDocuments = Documents.AllRefsType();
			
			QueryText = 
			"SELECT
			|	" + ObjectType.Name + ".Ref,";
			If AllCatalogs.ContainsType(TypeOf(ObjectType.EmptyRefValue)) Then
				Catalog = Metadata.Catalogs[ObjectType.Name];
				For Each Attribute In Catalog.Attributes Do
					QueryText = QueryText + Chars.LF + ObjectType.Name + "." + Attribute.Name + ",";
				EndDo;
			ElsIf  
				AllDocuments.ContainsType(TypeOf(ObjectType.EmptyRefValue)) Then
				Document = Metadata.Documents[ObjectType.Name];
				For Each Attribute In Document.Attributes Do
					If Attribute.Type = New TypeDescription("Date") Then
						QueryText = QueryText + Chars.LF + "DATEDIFF(" + Attribute.Name + ", &CurrentDate, DAY) AS DaysBeforeDeletionFrom" + Attribute.Name + ",";
					EndIf;
					QueryText = QueryText + Chars.LF + ObjectType.Name + "." + Attribute.Name + ",";
				EndDo;
			EndIf;
			If DataForReport Then
				QueryText = QueryText + "
				|	VALUETYPE(Files.FileOwner) AS FileOwner,
				|	FilesVersions.Size /1024 /1024 AS IrrelevantFilesVolume";
			Else
				QueryText = QueryText + "
				|	Files.Ref AS FileRef,
				|	FilesVersions.Ref AS VersionRef";
			EndIf;
			QueryText = QueryText + "
			|FROM
			|	" + ObjectType.FullName+ " AS " + ObjectType.Name + "
			|	INNER JOIN "+ FullFilesCatalogName + " AS Files
			|			INNER JOIN " + FullFilesVersionsCatalogName + " AS FilesVersions
			|			ON Files.Ref = FilesVersions.Owner
			|		ON " + ObjectType.Name + ".Ref = Files.FileOwner
			|WHERE
			|	NOT Files.DeletionMark
			|	AND NOT ISNULL(FilesVersions.DeletionMark, False)
			|	AND CASE
			|			WHEN FilesVersions.FileStorageType = VALUE(Enum.FileStorageTypes.InVolumesOnHardDrive)
			|				THEN FilesVersions.Volume <> VALUE(Catalog.FileStorageVolumes.EmptyRef)
			|						OR (CAST(FilesVersions.PathToFile AS STRING(100))) <> """"
			|			ELSE TRUE
			|		END
			|	AND VALUETYPE(Files.FileOwner) = &OwnerType";
		EndIf;
	Else
		If Setting.ClearingPeriod <> Enums.FilesCleanupPeriod.ByRule Then
			If DataForReport Then
				QueryText = 
				"SELECT
				|	VALUETYPE(Files.FileOwner) AS FileOwner,
				|	Files.Size /1024 /1024 AS IrrelevantFilesVolume";
			Else
				QueryText = 
				"SELECT
				|	Files.Ref AS FileRef";
			EndIf;
			QueryText = QueryText + "
			|FROM
			|	Catalog." + Setting.FileOwnerType.Name + " AS Files
			|		INNER JOIN " + FileOwner.FullName + " AS CatalogFiles
			|		ON Files.FileOwner = CatalogFiles.Ref
			|WHERE
			|	Files.CreationDate <= &ClearingPeriod
			|	AND NOT Files.DeletionMark
			|	AND CASE
			|			WHEN Files.FileStorageType = VALUE(Enum.FileStorageTypes.InVolumesOnHardDrive)
			|				THEN (CAST(Files.PathToFile AS STRING(100))) <> """"
			|						OR NOT Files.Volume = VALUE(Catalog.FileStorageVolumes.EmptyRef)
			|			ELSE TRUE
			|		END
			|	AND VALUETYPE(Files.FileOwner) = &OwnerType
			|	";
		Else
			
			ObjectType = FileOwner;
			AllCatalogs = Catalogs.AllRefsType();
			AllDocuments = Documents.AllRefsType();
			
			QueryText = 
			"SELECT
			|	CatalogFiles.Ref,
			|	VALUETYPE(Files.FileOwner) AS FileOwner,
			|	Files.Size /1024 /1024 AS IrrelevantFilesVolume,";
			If AllCatalogs.ContainsType(TypeOf(ObjectType.EmptyRefValue)) Then
				Catalog = Metadata.Catalogs[ObjectType.Name];
				For Each Attribute In Catalog.Attributes Do
					QueryText = QueryText + Chars.LF + "CatalogFiles." + Attribute.Name + ",";
				EndDo;
			ElsIf AllDocuments.ContainsType(TypeOf(ObjectType.EmptyRefValue)) Then
				Document = Metadata.Documents[ObjectType.Name];
				For Each Attribute In Document.Attributes Do
					If Attribute.Type = New TypeDescription("Date") Then
						QueryText = QueryText + Chars.LF + "DATEDIFF(" + Attribute.Name + ", &CurrentDate, DAY) AS DaysBeforeDeletionFrom" + Attribute.Name + ",";
					EndIf;
					QueryText = QueryText + Chars.LF + "CatalogFiles." + Attribute.Name + ",";
				EndDo;
			EndIf;
			QueryText = QueryText + "
			|	Files.Ref AS FileRef
			|FROM
			|	Catalog." + Setting.FileOwnerType.Name + " AS Files
			|		LEFT JOIN " + FileOwner.FullName + " AS CatalogFiles
			|		ON Files.FileOwner = CatalogFiles.Ref
			|WHERE
			|	NOT Files.DeletionMark
			|	AND CASE
			|			WHEN Files.FileStorageType = VALUE(Enum.FileStorageTypes.InVolumesOnHardDrive)
			|				THEN (CAST(Files.PathToFile AS STRING(100))) <> """"
			|						OR NOT Files.Volume = VALUE(Catalog.FileStorageVolumes.EmptyRef)
			|			ELSE TRUE
			|		END
			|	AND VALUETYPE(Files.FileOwner) = &OwnerType";
		EndIf;
	EndIf;
	
	If ExceptionsArray.Count() > 0 Then
		QueryText = QueryText + "
		|	AND NOT Files.FileOwner IN HIERARCHY (&ExceptionsArray)";
	EndIf;
	If ExceptionItem <> Undefined Then
		QueryText = QueryText + "
		|	AND Files.FileOwner IN HIERARCHY (&ExceptionItem)";
	EndIf;
	If HasAbilityToStoreVersions AND Setting.Action = Enums.FilesCleanupOptions.CleanUpVersions Then
		QueryText =  QueryText + "
		|	AND FilesVersions.Ref <> Files.CurrentVersion
		|	AND FilesVersions.ParentVersion <> VALUE(Catalog.FilesVersions.EmptyRef)";
	EndIf;
	
	Return QueryText;
	
EndFunction

Function FullFilesVolumeQueryText() Export
	MetadataCatalogs = Metadata.Catalogs;
	AddFieldAlias = True;
	QueryText = "";
	For Each Catalog In MetadataCatalogs Do
		If Catalog.Attributes.Find("FileOwner") <> Undefined Then
			
			HasAbilityToStoreVersions = Common.HasObjectAttribute("CurrentVersion", Catalog);
			If HasAbilityToStoreVersions Then
				CatalogFilesVersions =
					Common.MetadataObjectID(Catalog.Attributes.CurrentVersion.Type.Types()[0]);
				FullFilesVersionsCatalogName = CatalogFilesVersions.FullName;
			
				QueryText = QueryText + ?(IsBlankString(QueryText),"", " UNION ALL") + "
					|
					|SELECT
					|	VALUETYPE(Files.FileOwner) AS FileOwner,
					|	SUM(ISNULL(FilesVersions.Size, Files.Size) / 1024 / 1024) AS TotalFileSize
					|FROM
					|	Catalog." + Catalog.Name + " AS Files
					|		LEFT JOIN "+ FullFilesVersionsCatalogName + " AS FilesVersions
					|		ON Files.Ref = FilesVersions.Owner
					|WHERE
					|	NOT Files.DeletionMark
					|	AND NOT ISNULL(FilesVersions.DeletionMark, FALSE)
					|
					|GROUP BY
					|	VALUETYPE(Files.FileOwner)";
					
				If AddFieldAlias Then
					AddFieldAlias = False;
				EndIf;
			Else
				QueryText = QueryText + ?(IsBlankString(QueryText),"", " UNION ALL") + "
					|
					|SELECT
					|	VALUETYPE(Files.FileOwner) " + ?(AddFieldAlias, "AS FileOwner,",",") + "
					|	Files.Size / 1024 / 1024 " + ?(AddFieldAlias, "AS TotalFileSize","") + "
					|FROM
					|	Catalog." + Catalog.Name + " AS Files
					|WHERE
					|	NOT Files.DeletionMark";
				
				If AddFieldAlias Then
					AddFieldAlias = False;
				EndIf;
			EndIf;
				
		EndIf;
	EndDo;
	
	Return QueryText;
	
EndFunction

Procedure CheckFilesIntegrity(FilesTableOnHardDrive, Volume) Export
	
	Query = New Query;
	FilesTypes = Metadata.DefinedTypes.AttachedFile.Type.Types();
	
	AddFieldAlias = True;
	
	For Each CatalogFiles In FilesTypes Do
		CatalogMetadata = Metadata.FindByType(CatalogFiles);
		If CatalogMetadata.Attributes.Find("FileOwner") <> Undefined Then
			HasAbilityToStoreVersions = Common.HasObjectAttribute("CurrentVersion", CatalogMetadata);
			
			Query.Text = Query.Text + ?(IsBlankString(Query.Text),"", " UNION ALL") + "
				|
				|SELECT
				|	CatalogAttachedFiles.Ref " + ?(AddFieldAlias, "AS Ref,",",") + "
				|	CatalogAttachedFiles.Extension " + ?(AddFieldAlias, "AS Extension,",",") + "
				|	CatalogAttachedFiles.Description " + ?(AddFieldAlias, "AS Description,",",") + "
				|	CatalogAttachedFiles.Volume " + ?(AddFieldAlias, "AS Volume,",",") + "
				|	CatalogAttachedFiles.Changed " + ?(AddFieldAlias, "AS WasEditedBy,",",") + "
				|	CatalogAttachedFiles.UniversalModificationDate " + ?(AddFieldAlias, "AS FileModificationDate,",",") + "
				|	CatalogAttachedFiles.PathToFile " + ?(AddFieldAlias, "AS PathToFile","") + "
				|FROM
				|	Catalog." + CatalogMetadata.Name + " AS CatalogAttachedFiles
				|WHERE
				|	CatalogAttachedFiles.Volume = &Volume
				|	AND CatalogAttachedFiles.FileStorageType = VALUE(Enum.FileStorageTypes.InVolumesOnHardDrive)
				|	AND NOT CatalogAttachedFiles.DeletionMark";
			If HasAbilityToStoreVersions Then
				CatalogFilesVersions = Metadata.FindByType(CatalogMetadata.Attributes.CurrentVersion.Type.Types()[0]);
				Query.Text = Query.Text + "
					|	AND CatalogAttachedFiles.CurrentVersion = VALUE(Catalog." + CatalogFilesVersions.Name + ".EmptyRef)";
			EndIf;
			
			If AddFieldAlias Then
				AddFieldAlias = False;
			EndIf;
		ElsIf CatalogMetadata.Attributes.Find("ParentVersion") <> Undefined Then
			Query.Text = Query.Text + ?(IsBlankString(Query.Text),"", " UNION ALL") + "
				|
				|SELECT
				|	CatalogAttachedFiles.Ref " + ?(AddFieldAlias, "AS Ref,",",") + "
				|	CatalogAttachedFiles.Extension " + ?(AddFieldAlias, "AS Extension,",",") + "
				|	CatalogAttachedFiles.Description " + ?(AddFieldAlias, "AS Description,",",") + "
				|	CatalogAttachedFiles.Volume " + ?(AddFieldAlias, "AS Volume,",",") + "
				|	CatalogAttachedFiles.Author " + ?(AddFieldAlias, "AS WasEditedBy,",",") + "
				|	CatalogAttachedFiles.UniversalModificationDate " + ?(AddFieldAlias, "AS FileModificationDate,",",") + "
				|	CatalogAttachedFiles.PathToFile " + ?(AddFieldAlias, "AS PathToFile","") + "
				|FROM
				|	Catalog." + CatalogMetadata.Name + " AS CatalogAttachedFiles
				|WHERE
				|	CatalogAttachedFiles.Volume = &Volume
				|	AND CatalogAttachedFiles.FileStorageType = VALUE(Enum.FileStorageTypes.InVolumesOnHardDrive)
				|	AND NOT CatalogAttachedFiles.DeletionMark";
			
			If AddFieldAlias Then
				AddFieldAlias = False;
			EndIf;
			
		EndIf;
	EndDo;

	Query.SetParameter("Volume", Volume);
	
	QueryResult = Query.Execute();
	
	Selection = QueryResult.Select();
	
	FullVolumePath = FullVolumePath(Volume);
	
	While Selection.Next() Do
		
		VersionRef = Selection.Ref;
		PathToFile   = Selection.PathToFile;
		
		If ValueIsFilled(Selection.PathToFile) AND ValueIsFilled(Selection.Volume) Then
			
			// Removing the extra point if the file has no extension.
			If VersionRef.Extension = "" AND StrEndsWith(PathToFile, ".") Then
				PathToFile = Left(PathToFile, StrLen(PathToFile) - 1);
			EndIf;
			
			FullFilePath = FullVolumePath + PathToFile;
			ExistingFile = FilesTableOnHardDrive.FindRows(New Structure("FullName", FullFilePath));
			
			If ExistingFile.Count() = 0 Then
				
				NonExistingFile = FilesTableOnHardDrive.Add();
				NonExistingFile.VerificationStatus = NStr("ru = 'Отсутствуют данные в томе на диске'; en = 'No data in volume on the hard drive'; pl = 'Brak danych w woluminie na dysku';de = 'Keine Daten im Volume auf der Festplatte';ro = 'Lipsesc datele în volum pe disc';tr = 'Disk biriminde veri yok'; es_ES = 'No hay datos en el tomo en el disco'");
				NonExistingFile.File = VersionRef;
				NonExistingFile.FullName = FullFilePath;
				NonExistingFile.Extension = VersionRef.Extension;
				NonExistingFile.Name = VersionRef.Description;
				NonExistingFile.Volume = Volume;
				NonExistingFile.WasEditedBy = Selection.WasEditedBy;
				NonExistingFile.ModificationDate = Selection.FileModificationDate;
				NonExistingFile.Count = 1;
				
			Else
				
				ExistingFile[0].File = VersionRef;
				ExistingFile[0].VerificationStatus = NStr("ru = 'Целостные данные'; en = 'Data integrity check passed'; pl = 'Holistyczne dane';de = 'Ganzheitliche Daten';ro = 'Date integre';tr = 'Bütünsel veriler'; es_ES = 'Datos enteros'");
				
			EndIf;
			
		EndIf;
		
	EndDo;

EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Managing file volumes

// Returns the file storage type.
// 
// Returns:
//  Boolean. If true, files are stored in volumes on the hard disk.
//
Function StoreFilesInVolumesOnHardDrive() Export
	
	SetPrivilegedMode(True);
	
	StoreFilesInVolumesOnHardDrive = Constants.StoreFilesInVolumesOnHardDrive.Get();
	
	Return StoreFilesInVolumesOnHardDrive;
	
EndFunction

// Returns the file storage type, which shows whether the files are stored in volumes.
// If there are no file storage volumes, files are stored in the infobase.
//
// Returns:
//  EnumsRef.FilesStorageTypes.
//
Function FilesStorageTyoe() Export
	
	SetPrivilegedMode(True);
	
	StoreFilesInVolumesOnHardDrive = Constants.StoreFilesInVolumesOnHardDrive.Get();
	
	If StoreFilesInVolumesOnHardDrive Then
		
		If FilesOperations.HasFileStorageVolumes() Then
			Return Enums.FileStorageTypes.InVolumesOnHardDrive;
		Else
			Return Enums.FileStorageTypes.InInfobase;
		EndIf;
		
	Else
		Return Enums.FileStorageTypes.InInfobase;
	EndIf;

EndFunction

// Checks whether there is at least one file in one of the volumes.
//
// Returns:
//  Boolean.
//
Function HasFilesInVolumes() Export
	
	Query = New Query;
	Query.Text =
	"SELECT TOP 1
	|	FilesInfo.File AS File
	|FROM
	|	InformationRegister.FilesInfo AS FilesInfo
	|WHERE
	|	FilesInfo.FileStorageType = VALUE(Enum.FileStorageTypes.InVolumesOnHardDrive)";
	
	Return Not Query.Execute().IsEmpty();
	
EndFunction

// Returns a full path of the volume depending on the OS.
Function FullVolumePath(VolumeRef) Export
	
	SetPrivilegedMode(True);
	If Common.IsWindowsServer() Then
		
		Return VolumeRef.FullPathWindows;
	Else
		Return VolumeRef.FullPathLinux;
	EndIf;
	
EndFunction

// Adds a file to one of the volumes (that has free space).
//
// Parameters:
//   BinaryDataOrPath  - BinaryData, String - binary data of a file or a full file path on hard drive.
//   ModificationTimeUniversal - Date - universal time, which will be set to the file as the last 
//                                        modification time.
//   NameWithoutExtension       - String - a file name without extension.
//   Extension             - String - a file extension without point.
//   VersionNumber            - String - the file version number. If specified, the file name for 
//                                     storage on the hard drive is formed as follows:
//                                     BaseName + "." + VersionNumber + "." + Extension otherwise, 
//                                     BaseName + "." + Extension
//   Encrypted             - Boolean - if True, the extension ".p7m" will be added to the full file name.
//   DateToPlaceInVolume - Date   - if it is not specified, the current session time is used.
//  
//  Returns:
//    Structure - with the following properties:
//      * Volume         - CatalogRef.FilesStorageVolumes - the volume, in which the file was placed.
//      * FilePath  - String - a path, by which the file was placed in the volume.
//
Function AddFileToVolume(BinaryDataOrPath, ModificationTimeUniversal, NameWithoutExtension, Extension,
	VersionNumber = "", Encrypted = False, PutInVolumeDate = Undefined) Export
	
	ExpectedTypes = New Array;
	ExpectedTypes.Add(Type("BinaryData"));
	ExpectedTypes.Add(Type("String"));
	CommonClientServer.CheckParameter("FilesOperationsInternal.AddFileToVolume", "BinaryDataOrPath", BinaryDataOrPath,	
		New TypeDescription(ExpectedTypes));
		
	SetPrivilegedMode(True);
	
	VolumeRef = Catalogs.FileStorageVolumes.EmptyRef();
	
	BriefDescriptionOfAllErrors   = ""; // Errors from all volumes
	DetailedDescriptionOfAllErrors = ""; // For the event log.
	
	Query = New Query;
	Query.Text = 
		"SELECT
		|	FileStorageVolumes.Ref
		|FROM
		|	Catalog.FileStorageVolumes AS FileStorageVolumes
		|WHERE
		|	FileStorageVolumes.DeletionMark = FALSE
		|
		|ORDER BY
		|	FileStorageVolumes.FillOrder";

	Selection = Query.Execute().Select();
	
	If Selection.Count() = 0 Then
		Raise NStr("ru = 'Нет ни одного тома для размещения файла.'; en = 'There is no volume available for storing the file.'; pl = 'Nie ma żadnego woluminu dla alokacji plików.';de = 'Es gibt keine Volumes zum Platzieren einer Datei.';ro = 'Nu există volume pentru plasarea fișierului.';tr = 'Dosyaların yerleştirileceği birimler yok.'; es_ES = 'No hay tomos para colocar archivos.'");
	EndIf;
	
	While Selection.Next() Do
		
		VolumeRef = Selection.Ref;
		
		VolumePath = FullVolumePath(VolumeRef);
		// Adding a slash mark at the end if it is not there.
		VolumePath = CommonClientServer.AddLastPathSeparator(VolumePath);
		
		// Generating the file name to be stored on the hard disk as follows:
		// - file name.version number.file extension.
		If IsBlankString(VersionNumber) Then
			FileName = NameWithoutExtension + "." + Extension;
		Else
			FileName = NameWithoutExtension + "." + VersionNumber + "." + Extension;
		EndIf;
		
		If Encrypted Then
			FileName = FileName + "." + "p7m";
		EndIf;
		
		Try
			
			If TypeOf(BinaryDataOrPath) = Type("BinaryData") Then
				FileSize = BinaryDataOrPath.Size();
			Else // Otherwise, this is a path to a file on the hard drive.
				SourceFile = New File(BinaryDataOrPath);
				If SourceFile.Exist() Then
					FileSize = SourceFile.Size();
				Else
					ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("ru = 'Не удалось добавить файл ""%1"" ни в один из томов, т.к. он отсутствует.
						|Возможно, файл удален антивирусной программой.
						|Обратитесь к администратору.'; 
						|en = 'Cannot add file ""%1"" to a volume because the file is missing.
						|The file might have been deleted by antivirus software.
						|Please contact the administrator.'; 
						|pl = 'Nie udało się dodać pliku ""%1"" do żadnego z woluminów ponieważ go brakuje.
						|Plik może być usunięty przez oprogramowanie antywirusowe.
						|Skontaktuj się z administratorem.';
						|de = 'Die Datei ""%1"" konnte keinem der Volumes hinzugefügt werden, da sie fehlt.
						|Die Datei wurde möglicherweise von einem Antivirenprogramm gelöscht.
						|Bitte wenden Sie sich an den Administrator.';
						|ro = 'Eșec la adăugarea fișierului ""%1"" în careva din volume, deoarece el lipsește.
						|Posibil, fișierul este șters de programul antivirus.
						|Adresați-vă administratorului.';
						|tr = 'Birimlerden hiçbirine ""%1"" dosyası eksik olduğundan dolayı eklenemedi. 
						|Dosya virüsten koruma programı tarafından silinmiş olabilir. 
						|Lütfen sistem yöneticinize başvurun.'; 
						|es_ES = 'No se ha podido añadir el archivo ""%1"" en ninguno de los tomos porque está ausente.
						|Es posible que el archivo haya sido eliminado por el programa antivirus.
						|Diríjase al administrador.'"),
						FileName);
						
					Raise ErrorText;
					
				EndIf;
			EndIf;
			
			// If MaxSize = 0, there is no limit to the file size on the volume.
			If VolumeRef.MaxSize <> 0 Then
				
				CurrentSizeInBytes = CalculateFileSizeInVolume(VolumeRef.Ref);
				
				NewSizeInBytes = CurrentSizeInBytes + FileSize;
				NewSize = NewSizeInBytes / (1024 * 1024);
				
				If NewSize > VolumeRef.MaxSize Then
					
					Raise StringFunctionsClientServer.SubstituteParametersToString(
						NStr("ru = 'Превышен максимальный размер тома (%1 Мб).'; en = 'The volume size limit (%1 MB) is exceeded.'; pl = 'Przekroczono maksymalny rozmiar woluminu (%1 MB).';de = 'Die maximale Volumen-Größe wurde überschritten (%1MB).';ro = 'Dimensiunea maximă a volumului a fost depășită (%1 MB).';tr = 'Maksimum birim boyutu aşıldı (%1MB).'; es_ES = 'Tamaño del volumen máximo excedido (%1 MB).'"),
						VolumeRef.MaxSize);
				EndIf;
			EndIf;
			
			Date = CurrentSessionDate();
			If PutInVolumeDate <> Undefined Then
				Date = PutInVolumeDate;
			EndIf;
			
			// The use of the absolute date format "DF" in the next line is correct, as the date is not meant 
			// for user view.
			DateFolder = Format(Date, "DF=yyyymmdd") + GetPathSeparator();
			
			VolumePath = VolumePath + DateFolder;
			
			FileNameWithPath = FilesOperationsInternalClientServer.GetUniqueNameWithPath(VolumePath, FileName);
			FullFileNameWithPath = VolumePath + FileNameWithPath;
			
			If TypeOf(BinaryDataOrPath) = Type("BinaryData") Then
				BinaryDataOrPath.Write(FullFileNameWithPath);
			Else // Otherwise, this is a path to a file on the hard drive.
				FileCopy(BinaryDataOrPath, FullFileNameWithPath);
			EndIf;
			
			// Setting file change time equal to the change time of the current version.
			FileOnHardDrive = New File(FullFileNameWithPath);
			FileOnHardDrive.SetModificationUniversalTime(ModificationTimeUniversal);
			FileOnHardDrive.SetReadOnly(True);
			
			Return New Structure("Volume,PathToFile", VolumeRef, DateFolder + FileNameWithPath); 
			
		Except
			ErrorInformation = ErrorInfo();
			
			If DetailedDescriptionOfAllErrors <> "" Then
				DetailedDescriptionOfAllErrors = DetailedDescriptionOfAllErrors + Chars.LF + Chars.LF;
				BriefDescriptionOfAllErrors   = BriefDescriptionOfAllErrors   + Chars.LF + Chars.LF;
			EndIf;
			
			ErrorDescriptionTemplate =
				NStr("ru = 'Ошибка при добавлении файла ""%1""
				           |в том ""%2"" (%3):
				           |""%4"".'; 
				           |en = 'Cannot add file ""%1""
				           |to volume ""%2"" (%3):
				           |""%4""'; 
				           |pl = 'Błąd podczas dodawania pliku ""%1""
				           |do woluminu ""%2"" (%3):
				           |""%4"".';
				           |de = 'Fehler beim Hinzufügen einer Datei ""%1""
				           |in das Volume ""%2"" (%3):
				           |""%4"".';
				           |ro = 'Eroare la adăugarea fișierului ""%1""
				           |în volumul ""%2"" (%3):
				           |""%4"".';
				           |tr = '""%1"" 
				           |Dosyası eklenirken hata oluştu ""%2"" (%3): 
				           |""%4"".'; 
				           |es_ES = 'Error al añadir el archivo ""%1""
				           |en el tomo ""%2"" (%3): 
				           |""%4"".'");
			
			DetailedDescriptionOfAllErrors = DetailedDescriptionOfAllErrors
				+ StringFunctionsClientServer.SubstituteParametersToString(
					ErrorDescriptionTemplate,
					FileName,
					String(VolumeRef),
					VolumePath,
					DetailErrorDescription(ErrorInformation));
			
			BriefDescriptionOfAllErrors = BriefDescriptionOfAllErrors
				+ StringFunctionsClientServer.SubstituteParametersToString(
					ErrorDescriptionTemplate,
					FileName,
					String(VolumeRef),
					VolumePath,
					BriefErrorDescription(ErrorInformation));
			
			// Move to the next volume.
			Continue;
		EndTry;
		
	EndDo;
	
	SetPrivilegedMode(False);
	
	// Writing an event log record for the administrator, it includes the errors from all volumes.
	// 
	ErrorMessageTemplate = NStr("ru = 'Не удалось добавить файл ни в один из томов.
		|Список ошибок:
		|
		|%1'; 
		|en = 'Cannot add file to a volume.
		|Errors:
		|
		|%1'; 
		|pl = 'Nie udało się dodać pliku do żadnego z woluminów.
		|Lista błędów:
		|
		|%1';
		|de = 'Die Datei konnte zu keinem der Volumes hinzugefügt werden.
		|Fehlerliste:
		|
		|%1';
		|ro = 'Eșec la adăugarea fișierului în careva din volume.
		|Lista erorilor:
		|
		|%1';
		|tr = 'Birimlerden hiçbirine dosya eklenemedi. 
		|Hata listesi:
		|
		|%1'; 
		|es_ES = 'No se ha podido añadir archivo en ninguno de los tomos.
		|Lista de errores:
		|
		|%1'");
	
	WriteLogEvent(
		NStr("ru = 'Файлы.Добавление файла'; en = 'Files.Add file'; pl = 'Pliki. Dodawanie pliku';de = 'Dateien. Hinzufügen einer Datei';ro = 'Fișiere.Adăugarea fișierului';tr = 'Dosyalar. Dosyanın eklenmesi'; es_ES = 'Archivos. Añadiendo un archivo'", Common.DefaultLanguageCode()),
		EventLogLevel.Error,,,
		StringFunctionsClientServer.SubstituteParametersToString(ErrorMessageTemplate, DetailedDescriptionOfAllErrors));
	
	If Users.IsFullUser() Then
		ExceptionString = StringFunctionsClientServer.SubstituteParametersToString(ErrorMessageTemplate, BriefDescriptionOfAllErrors);
	Else
		// Message to end user.
		ExceptionString = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Не удалось добавить файл:
			           |""%1.%2"".
			           |
			           |Обратитесь к администратору.'; 
			           |en = 'Cannot add file
			           |""%1.%2"".
			           |
			           |Please contact the administrator.'; 
			           |pl = 'Nie udało się dodać pliku:
			           |""%1.%2"".
			           |
			           |Skontaktuj się z administratorem.';
			           |de = 'Die Datei konnte nicht hinzugefügt werden:
			           |""%1.%2"".
			           |
			           | Wenden Sie sich an den Administrator.';
			           |ro = 'Eșec la adăugarea fișierului:
			           |""%1.%2"".
			           |
			           |Adresați-vă administratorului.';
			           |tr = 'Dosya eklenemedi: 
			           |""%1.%2"" 
			           |
			           |Lütfen sistem yöneticinize başvurun.'; 
			           |es_ES = 'No se ha podido añadir archivo:
			           |""%1.%2"".
			           |
			           |Diríjase al administrador.'"),
			NameWithoutExtension, Extension);
	EndIf;
	
	Raise ExceptionString;

EndFunction

////////////////////////////////////////////////////////////////////////////////
// Access management.

Function IsFilesOrFilesVersionsCatalog(FullName) Export
	
	NameParts = StrSplit(FullName, ".", False);
	If NameParts.Count() <> 2 Then
		Return False;
	EndIf;
	
	If Upper(NameParts[0]) <> Upper("Catalog")
	   AND Upper(NameParts[0]) <> Upper("Catalog") Then
		Return False;
	EndIf;
	
	If StrEndsWith(Upper(NameParts[1]), Upper("AttachedFiles"))
	 Or Upper(NameParts[1]) = Upper("Files")
	 Or Upper(NameParts[1]) = Upper("FilesVersions") Then
		
		Return True;
	EndIf;
	
	Return False;
	
EndFunction

////////////////////////////////////////////////////////////////////////////////
// Digital signature and encryption for files.

Function DigitalSignatureAvailable(FileType) Export
	
	If Common.SubsystemExists("StandardSubsystems.DigitalSignature") Then
		ModuleDigitalSignatureInternal = Common.CommonModule("DigitalSignatureInternal");
		Return ModuleDigitalSignatureInternal.DigitalSignatureAvailable(FileType);
	EndIf;
	
	Return False;
	
EndFunction

// Controls the visibility of items and commands depending on the availability and use of digital 
// signature and encryption.
//
Procedure CryptographyOnCreateFormAtServer(Form, IsListForm = True, RowsPictureOnly = False) Export
	
	Items = Form.Items;
	
	DigitalSigning = False;
	Encryption = False;
	
	If Common.SubsystemExists("StandardSubsystems.DigitalSignature") Then
	
		ModuleDigitalSignatureInternal = Common.CommonModule("DigitalSignatureInternal");
		If ModuleDigitalSignatureInternal.UseInteractiveAdditionOfDigitalSignaturesAndEncryption() Then
			ModuleDigitalSignature = Common.CommonModule("DigitalSignature");
			DigitalSigning    = ModuleDigitalSignature.UseDigitalSignature();
			Encryption               = ModuleDigitalSignature.UseEncryption();
		EndIf;
		
	EndIf;
	
	If IsListForm Then
		If Common.IsCatalog(Metadata.FindByFullName(Form.List.MainTable)) Then
			FilesTable = Common.ObjectManagerByFullName(Form.List.MainTable);
			Available = DigitalSignatureAvailable(TypeOf(FilesTable.EmptyRef()));
		Else
			Available = True;
		EndIf;
	Else
		Available = DigitalSignatureAvailable(TypeOf(Form.Object.Ref));
	EndIf;
	Used = (DigitalSigning Or Encryption) AND Available;
	
	If IsListForm Then
		Items.ListSignedEncryptedPictureNumber.Visible = Used;
	EndIf;
	
	If Not RowsPictureOnly Then
		Items.FormDigitalSignatureAndEncryptionCommandsGroup.Visible = Used;
		
		If IsListForm Then
			Items.ListContextMenuDigitalSignatureAndEncryptionCommandsGroup.Visible = Used;
		Else
			Items.DigitalSignaturesGroup.Visible = DigitalSigning;
			Items.EncryptionCertificatesGroup.Visible = Encryption;
		EndIf;
	EndIf;
	
	If Not Used Then
		Return;
	EndIf;
	
	If Not RowsPictureOnly Then
		Items.FormDigitalSignatureCommandsGroup.Visible = DigitalSigning;
		Items.FormEncryptionCommandsGroup.Visible = Encryption;
		
		If IsListForm Then
			Items.ListContextMenuDigitalSignatureCommandsGroup.Visible = DigitalSigning;
			Items.ListContextMenuEncryptionCommandsGroup.Visible = Encryption;
		EndIf;
	EndIf;
	
	If DigitalSigning AND Encryption Then
		Title = NStr("ru = 'Электронная подпись и шифрование'; en = 'Digital signature and encryption'; pl = 'Podpis cyfrowy i szyfrowanie';de = 'Digitale Signatur und Verschlüsselung';ro = 'Semnătura digitală și criptarea';tr = 'Dijital imza ve şifreleme'; es_ES = 'Firma digital y codificación'");
		Tooltip = NStr("ru = 'Наличие электронной подписи или шифрования'; en = 'Digital signature or encryption available.'; pl = 'Istnienie podpisu cyfrowego lub szyfrowania';de = 'Vorhandensein von digitaler Signatur oder Verschlüsselung';ro = 'Prezența semnăturii electronice sau criptării';tr = 'Elektronik imza veya şifrelerin varlığı'; es_ES = 'Existencia de la firma digital o la codificación'");
		Picture  = PictureLib["SignedEncryptedTitle"];
	ElsIf DigitalSigning Then
		Title = NStr("ru = 'Электронная подпись'; en = 'Digital signature'; pl = 'Podpis cyfrowy';de = 'Digitale Signatur';ro = 'Semnătură electronică';tr = 'Dijital imza'; es_ES = 'Firma digital'");
		Tooltip = NStr("ru = 'Наличие электронной подписи'; en = 'Digital signature available.'; pl = 'Obecność podpisu cyfrowego';de = 'Digitale Signatur Existenz';ro = 'Existența semnăturii digitale';tr = 'Dijital imza varlığı'; es_ES = 'Existencia de la firma digital'");
		Picture  = PictureLib["SignedWithDS"];
	Else // Encryption
		Title = NStr("ru = 'Шифрование'; en = 'Encryption'; pl = 'Szyfrowanie';de = 'Verschlüsselung';ro = 'Cifrare';tr = 'Şifreleme'; es_ES = 'Codificación'");
		Tooltip = NStr("ru = 'Наличие шифрования'; en = 'Encryption available.'; pl = 'Istnienie szyfrowania';de = 'Verschlüsselung Existenz';ro = 'Existența criptării';tr = 'Şifreleme varlığı'; es_ES = 'Existencia de la codificación'");
		Picture  = PictureLib["Encrypted"];
	EndIf;
	
	If IsListForm Then
		Items.ListSignedEncryptedPictureNumber.HeaderPicture = Picture;
		Items.ListSignedEncryptedPictureNumber.ToolTip = Tooltip;
	EndIf;
	
	If Not RowsPictureOnly Then
		Items.FormDigitalSignatureAndEncryptionCommandsGroup.Title = Title;
		Items.FormDigitalSignatureAndEncryptionCommandsGroup.ToolTip = Title;
		Items.FormDigitalSignatureAndEncryptionCommandsGroup.Picture  = Picture;
		
		If IsListForm Then
			Items.ListContextMenuDigitalSignatureAndEncryptionCommandsGroup.Title = Title;
			Items.ListContextMenuDigitalSignatureAndEncryptionCommandsGroup.ToolTip = Title;
			Items.ListContextMenuDigitalSignatureAndEncryptionCommandsGroup.Picture  = Picture;
		EndIf;
	EndIf;
	
	ModuleDigitalSignatureInternal = Common.CommonModule("DigitalSignatureInternal");
	ModuleDigitalSignatureInternal.RegisterSignaturesList(Form, "DigitalSignatures");
	
EndProcedure

// For internal use only.
Procedure MoveSignaturesCheckResults(SignaturesInForm, SignedFile) Export
	
	If Not Common.SubsystemExists("StandardSubsystems.DigitalSignature") Then
		Return;
	EndIf;
		
	ModuleDigitalSignatureInternal = Common.CommonModule("DigitalSignatureInternal");
	If Not ModuleDigitalSignatureInternal.DigitalSignatureAvailable(TypeOf(SignedFile)) Then
		Return;
	EndIf;
		
	ModuleDigitalSignature = Common.CommonModule("DigitalSignature");
	SignaturesInObject = ModuleDigitalSignature.SetSignatures(SignedFile);
	
	If SignaturesInForm.Count() <> SignaturesInObject.Count() Then
		Return; // If the object was changed, the test results are not transferred.
	EndIf;
	
	If SignaturesInForm.Count() = 0 Then
		Return;
	EndIf;
	
	Properties = New Structure("SignatureValidationDate, SignatureCorrect", Null, Null);
	FillPropertyValues(Properties, SignaturesInObject[0]);
	If Properties.SignatureValidationDate = Null
	 Or Properties.SignatureCorrect = Null Then
		Return; // If the object does not have check attributes, the check results are not transferred.
	EndIf;
	
	For Each Row In SignaturesInForm Do
		RowInObject = SignaturesInObject.Get(SignaturesInForm.IndexOf(Row));
		If Row.SignatureDate         <> RowInObject.SignatureDate
		 Or Row.Comment         <> RowInObject.Comment
		 Or Row.CertificateOwner <> RowInObject.CertificateOwner
		 Or Row.Thumbprint           <> RowInObject.Thumbprint
		 Or Row.SignatureSetBy <> RowInObject.SignatureSetBy Then
			Return; // If the object was changed, the test results are not transferred.
		EndIf;
	EndDo;
	
	For Each Row In SignaturesInForm Do
		RowInObject = SignaturesInObject.Get(SignaturesInForm.IndexOf(Row));
		FillPropertyValues(Properties, RowInObject);
		If Row.SignatureValidationDate = Properties.SignatureValidationDate
		   AND Row.SignatureCorrect        = Properties.SignatureCorrect Then
			Continue; // Do not set the modification if the test results match.
		EndIf;
		FillPropertyValues(Properties, Row);
		FillPropertyValues(RowInObject, Properties);
		ModuleDigitalSignature.UpdateSignature(SignedFile, RowInObject);
	EndDo;
	
EndProcedure

// Places the encrypted files in the database and checks the Encrypted flag to the file and all its versions.
//
// Parameters:
//  FileRef - CatalogRef.Files - file.
//  Encrypt - Boolean - if True, encrypt file, otherwise, decrypt it.
//  DataArrayToAddToBase - an array of structures.
//  UUID - UUID - a form UUID.
//  WorkingDirectoryName - String - a working directory.
//  FilesArrayInWorkingDirectoryToDelete - Array - files to be deleted from the register.
//  ThumbprintsArray  - Array - an array of certificate thumbprints used for encryption.
//
Procedure WriteEncryptionInformation(FileRef, Encrypt, DataArrayToStoreInDatabase, UUID, 
	WorkingDirectoryName, FilesArrayInWorkingDirectoryToDelete, ThumbprintsArray) Export
	
	BeginTransaction();
	Try
		CurrentVersionTextTempStorageAddress = "";
		MainFileTempStorageAddress      = "";
		For Each DataToWriteAtServer In DataArrayToStoreInDatabase Do
			
			If TypeOf(DataToWriteAtServer.VersionRef) <> Type("CatalogRef.FilesVersions") Then
				MainFileTempStorageAddress = DataToWriteAtServer.TempStorageAddress;
				Continue;
			EndIf;
			
			TempStorageAddress = DataToWriteAtServer.TempStorageAddress;
			VersionRef = DataToWriteAtServer.VersionRef;
			TempTextStorageAddress = DataToWriteAtServer.TempTextStorageAddress;
			
			If VersionRef = FileRef.CurrentVersion Then
				CurrentVersionTextTempStorageAddress = TempTextStorageAddress;
			EndIf;
			
			FullFileNameInWorkingDirectory = "";
			InWorkingDirectoryForRead = True; // not used
			InOwnerWorkingDirectory = True;
			FullFileNameInWorkingDirectory = FilesOperationsInternalServerCall.GetFullFileNameFromRegister(VersionRef, 
				WorkingDirectoryName, InWorkingDirectoryForRead, InOwnerWorkingDirectory);
				
			If Not IsBlankString(FullFileNameInWorkingDirectory) Then
				FilesArrayInWorkingDirectoryToDelete.Add(FullFileNameInWorkingDirectory);
			EndIf;
			
			FilesOperationsInternalServerCall.DeleteFromRegister(VersionRef);
			
			FileInfo = FilesOperationsClientServer.FileInfo("FileWithVersion");
			FileInfo.BaseName = VersionRef.FullDescr;
			FileInfo.Comment = VersionRef.Comment;
			FileInfo.TempFileStorageAddress = TempStorageAddress;
			FileInfo.ExtensionWithoutPoint = VersionRef.Extension;
			FileInfo.Modified = VersionRef.CreationDate;
			FileInfo.ModificationTimeUniversal = VersionRef.UniversalModificationDate;
			FileInfo.Size = VersionRef.Size;
			FileInfo.ModificationTimeUniversal = VersionRef.UniversalModificationDate;
			FileInfo.NewTextExtractionStatus = Enums.FileTextExtractionStatuses.NotExtracted;
			FileInfo.Encrypted = Encrypt;
			FileInfo.StoreVersions = False;
			UpdateFileVersion(FileRef, FileInfo, VersionRef, UUID);
			
			// For the option of storing files on hard drive (on the server), deleting the File from the temporary storage after receiving it.
			If Not IsBlankString(DataToWriteAtServer.FileAddress) AND IsTempStorageURL(DataToWriteAtServer.FileAddress) Then
				DeleteFromTempStorage(DataToWriteAtServer.FileAddress);
			EndIf;
			
		EndDo;
		
		DataLock = New DataLock;
		DataLockItem = DataLock.Add(Metadata.FindByType(TypeOf(FileRef)).FullName());
		DataLockItem.SetValue("Ref", FileRef);
		DataLock.Lock();
		
		FileObject = FileRef.GetObject();
		LockDataForEdit(FileRef, , UUID);
		
		FileObject.Encrypted = Encrypt;
		FileObject.TextStorage = New ValueStorage("");
		FileObject.TextExtractionStatus = Enums.FileTextExtractionStatuses.NotExtracted;
		
		// To write a previously signed object.
		FileObject.AdditionalProperties.Insert("WriteSignedObject", True);
		
		If Encrypt Then
			If Common.SubsystemExists("StandardSubsystems.DigitalSignature") Then
				ModuleDigitalSignatureInternal = Common.CommonModule("DigitalSignatureInternal");
				ModuleDigitalSignatureInternal.AddEncryptionCertificates(FileRef, ThumbprintsArray);
			EndIf;
		Else
			If Common.SubsystemExists("StandardSubsystems.DigitalSignature") Then
				ModuleDigitalSignatureInternal = Common.CommonModule("DigitalSignatureInternal");
				ModuleDigitalSignatureInternal.ClearEncryptionCertificates(FileRef);
			EndIf;
		EndIf;
		
		FileMetadata = Metadata.FindByType(TypeOf(FileRef));
		FullTextSearchUsing = Metadata.ObjectProperties.FullTextSearchUsing.Use;
		
		If Not Encrypt AND CurrentVersionTextTempStorageAddress <> "" Then
			
			If FileMetadata.FullTextSearch = FullTextSearchUsing Then
				TextExtractionResult = ExtractText(CurrentVersionTextTempStorageAddress);
				FileObject.TextExtractionStatus = TextExtractionResult.TextExtractionStatus;
				FileObject.TextStorage = TextExtractionResult.TextStorage;
			Else
				FileObject.TextExtractionStatus = Enums.FileTextExtractionStatuses.NotExtracted;
				FileObject.TextStorage = New ValueStorage("");
			EndIf;
			
		EndIf;
		
		FileMetadata = Metadata.FindByType(TypeOf(FileRef));
		AbilityToStoreVersions = Common.HasObjectAttribute("CurrentVersion", FileMetadata);
		If Not FileObject.StoreVersions Or (AbilityToStoreVersions AND Not ValueIsFilled(FileObject.CurrentVersion)) Then
			UpdateFileBinaryDataAtServer(FileObject, MainFileTempStorageAddress);
		EndIf;
		
		FileObject.Write();
		
		UnlockDataForEdit(FileRef, UUID);
		
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;
	
EndProcedure

Procedure CheckFileProcessed(FileRef, ProcedureName) Export
	
	InfobaseUpdate.CheckObjectProcessed(FileRef,,
		"FilesOperationsInternal.MoveDigitalSignaturesAndEncryptionCertificatesToInformationRegisters",
		ProcedureName);
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Accounting control.

// See AccountingAuditOverridable.OnDefineChecks 
Procedure OnDefineChecks(ChecksGroups, Checks) Export
	
	CheckSSL = Checks.Add();
	CheckSSL.GroupID          = "SystemChecks";
	CheckSSL.Description                 = NStr("ru='Поиск ссылок на несуществующие файлы в томах хранения'; en = 'Search for links to missing files in storage volumes'; pl = 'Wyszukiwanie linków do nieistniejących plików w woluminach przechowywania';de = 'Suche nach Links zu nicht existierenden Dateien auf Speichermedien';ro = 'Căutarea referințelor la fișierele inexistente în volumele de stocare';tr = 'Depolama birimlerinde varolmayan dosyalara bağlantılar bulma'; es_ES = 'Búsqueda de enlaces a los archivos inexistentes en los tomos de guardar'");
	CheckSSL.Reasons                      = NStr("ru='Файл был физически удален или перемещен на диске вследствие работы антивирусных программ,
		|непреднамеренных действий администратора и.т.д.'; 
		|en = 'The file was deleted or moved by antivirus software,
		|unintentional actions of the administrator, or similar reasons.'; 
		|pl = 'Plik został fizycznie usunięty lub przeniesiony na dysku w wyniku działania programów antywirusowych,
		|niezamierzonych działań administratora itp.';
		|de = 'Die Datei wurde physisch gelöscht oder auf der Festplatte verschoben, aufgrund von Antivirensoftware,
		|unbeabsichtigten Administratoraktionen usw.';
		|ro = 'Fișierul a fost șters fizic sau transferat pe disc în rezultatul lucrului programelor antivirus,
		|acțiunilor fără intenții ale administratorului etc.';
		|tr = 'Dosya, 
		|virüsten koruma programları, istenmeyen yönetici eylemleri vb. nedeniyle fiziksel olarak silinmiş veya disk üzerinde taşınmıştır.'; 
		|es_ES = 'El archivo ha sido eliminado físicamente o movido en el disco al funcionar los programas de antivirus,
		|acciones no premeditadas del administrador etc.'");
	CheckSSL.Recommendation                 = NStr("ru='• Пометить файл в программе на удаление;
		|• Или восстановить файл на диске в томе из резервной копии.'; 
		|en = '• Mark the file for deletion.
		|• Or restore the file in the volume on the hard drive from the backup.'; 
		|pl = '• Odznaczyć plik w programie do usuwania;
		|• Lub przywrócić plik na dysku na woluminie z kopii zapasowej.';
		|de = '• Markieren Sie die Datei im Programm zum Löschen;
		|• Oder stellen Sie die Datei auf der Festplatte im Datenträger von der Sicherungskopie wieder her.';
		|ro = '• Marcați la ștergere fișierul în program;
		|• Sau restabiliți fișierul pe dis în volum din copia de rezervă.';
		|tr = '* Silmek için programdaki dosyayı etiketleyin; 
		|* Veya yedekten birimdeki sürücüde dosyayı geri yükleyin.'; 
		|es_ES = '• Marcar el archivo para borrar en el programa;
		|• O restablecer el archivo en el disco en el tomo de la copia de respaldo.'");
	CheckSSL.ID                = "StandardSubsystems.ReferenceToNonexistingFilesInVolumeCheck";
	CheckSSL.CheckHandler           = "FilesOperationsInternal.ReferenceToNonexistingFilesInVolumeCheck";
	CheckSSL.AccountingChecksContext = "SystemChecks";
	CheckSSL.Disabled                    = True;
	
EndProcedure

// Checks non-existent files on the hard drive, in the case when attached files are stored in volumes.
//
Procedure ReferenceToNonexistingFilesInVolumeCheck(CheckSSL, CheckParameters) Export
	
	If Common.DataSeparationEnabled()
		Or Not GetFunctionalOption("StoreFilesInVolumesOnHardDrive") Then
		Return;
	EndIf;
	
	AvailableVolumes = AvailableVolumes(CheckParameters);
	If AvailableVolumes.Count() = 0 Then
		Return;
	EndIf;
	
	ModuleSaaS = Undefined;
	If Common.SubsystemExists("StandardSubsystems.SaaS") Then
		ModuleSaaS = Common.CommonModule("SaaS");
	EndIf;
	
	MetadataObjectKinds = New Array;
	MetadataObjectKinds.Add(Metadata.Catalogs);
	MetadataObjectKinds.Add(Metadata.Documents);
	MetadataObjectKinds.Add(Metadata.ChartsOfAccounts);
	MetadataObjectKinds.Add(Metadata.ChartsOfCharacteristicTypes);
	MetadataObjectKinds.Add(Metadata.Tasks);
	
	For Each MetadataObjectKind In MetadataObjectKinds Do
		For Each MetadataObject In MetadataObjectKind Do
			If ModuleSaaS <> Undefined 
				AND Not ModuleSaaS.IsSeparatedMetadataObject(MetadataObject.FullName()) Then
				Continue;
			EndIf;
			If Not CheckAttachedFilesObject(MetadataObject) Then
				Continue;
			EndIf;
			SearchRefsToNonExistentFilesInVolumes(MetadataObject, CheckParameters, AvailableVolumes);
		EndDo;
	EndDo;
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Extracting text for a full text search.

Procedure ExtractTextFromFiles() Export
	
	SetPrivilegedMode(True);
	
	If Not Common.IsWindowsServer() Then
		Return; // Text extraction is available only under Windows.
	EndIf;
	
	NameWithFileExtension = "";
	
	WriteLogEvent(
		NStr("ru = 'Файлы.Извлечение текста'; en = 'Files.Extract text'; pl = 'Pliki. Ekstrakcja tekstu';de = 'Dateien. Text extrahieren';ro = 'Fișiere.Extragerea textului';tr = 'Dosyalar. Metin özütleme'; es_ES = 'Archivos.Extracción del texto'",
		     Common.DefaultLanguageCode()),
		EventLogLevel.Information,
		,
		,
		NStr("ru = 'Начато регламентное извлечения текста'; en = 'Scheduled text extraction started'; pl = 'Rozpoczęto planową ekstrakcję tekstu';de = 'Die geplante Textextraktion wird gestartet';ro = 'Extracția reglementară a textului este pornită';tr = 'Zamanlanmış metin çıkarma işlemi başlatıldı'; es_ES = 'Extracción del texto programado está iniciada'"));
	
	Query = New Query(QueryTextToExtractText());
	FilesToExtractText = Query.Execute().Unload();
	
	For Each FileWithoutText In FilesToExtractText Do
		
		FileLocked = False;
		FileWithBinaryDataName = "";
		
		Try
			ExtractTextFromFile(FileWithoutText, FileLocked, FileWithBinaryDataName);
		Except
			If FileLocked Then
				WriteLogEvent(
					NStr("ru = 'Файлы.Извлечение текста'; en = 'Files.Extract text'; pl = 'Pliki. Ekstrakcja tekstu';de = 'Dateien. Text extrahieren';ro = 'Fișiere.Extragerea textului';tr = 'Dosyalar. Metin özütleme'; es_ES = 'Archivos.Extracción del texto'",
					     Common.DefaultLanguageCode()),
					EventLogLevel.Error,
					,
					,
					StringFunctionsClientServer.SubstituteParametersToString(
						NStr("ru = 'Не удалось выполнить регламентное извлечение текста из файла
						           |""%1""
						           |по причине:
						           |""%2"".'; 
						           |en = 'Cannot complete scheduled text extraction from file
						           |""%1.""
						           |Reason:
						           |%2'; 
						           |pl = 'Nie powiodło się planowe wyodrębnianie tekstu z pliku
						           |""%1""
						           |z powodu:
						           |""%2"".';
						           |de = 'Die routinemäßige Extraktion von Text aus der
						           |""%1""
						           |Datei war nicht möglich, aufgrund von:
						           |""%2"".';
						           |ro = 'Eșec la executarea extragerii reglementare a textului din fișierul
						           |""%1""
						           |din motivul:
						           |""%2"".';
						           |tr = '
						           |"
"%1Nedeniyle "
" dosyasının metni düzenli olarak ayıklayamadı: ""%2"".'; 
						           |es_ES = 'No se ha podido realizar la extracción del texto programada del archivo 
						           |""%1""
						           |a causa de:
						           |""%2"".'"),
						NameWithFileExtension,
						DetailErrorDescription(ErrorInfo()) ));
			EndIf;
		EndTry;
		
		If ValueIsFilled(FileWithBinaryDataName) Then
			File = New File(FileWithBinaryDataName);
			If File.Exist() Then
				Try
					DeleteFiles(FileWithBinaryDataName);
				Except
					WriteLogEvent(NStr("ru = 'Файлы.Извлечение текста'; en = 'Files.Extract text'; pl = 'Pliki. Ekstrakcja tekstu';de = 'Dateien. Text extrahieren';ro = 'Fișiere.Extragerea textului';tr = 'Dosyalar. Metin özütleme'; es_ES = 'Archivos.Extracción del texto'", Common.DefaultLanguageCode()),
						EventLogLevel.Error,,, DetailErrorDescription(ErrorInfo()));
				EndTry;
			EndIf;
		EndIf;
		
	EndDo;
	
	WriteLogEvent(
		NStr("ru = 'Файлы.Извлечение текста'; en = 'Files.Extract text'; pl = 'Pliki. Ekstrakcja tekstu';de = 'Dateien. Text extrahieren';ro = 'Fișiere.Extragerea textului';tr = 'Dosyalar. Metin özütleme'; es_ES = 'Archivos.Extracción del texto'",
		     Common.DefaultLanguageCode()),
		EventLogLevel.Information,
		,
		,
		NStr("ru = 'Закончено регламентное извлечение текста'; en = 'Scheduled text extraction completed'; pl = 'Planowana ekstrakcja teksu została zakończona';de = 'Geplante Textextraktion ist abgeschlossen';ro = 'Extracția reglementară a textului este finalizată';tr = 'Zamanlanmış metin çıkarma işlemi tamamlandı'; es_ES = 'Extracción del texto programado está finalizada'"));
	
EndProcedure

// Returns True if the file text is extracted on the server (not on the client).
//
// Returns:
//  Boolean. False if the text is not extracted on the server, in other words, it can and should be 
//                 extracted on the client.
//
Function ExtractTextFilesOnServer() Export
	
	SetPrivilegedMode(True);
	
	Return Constants.ExtractTextFilesOnServer.Get();
	
EndFunction

// Writes to the server the text extraction results that are the extracted text and the TextExtractionStatus.
Procedure RecordTextExtractionResult(FileOrVersionRef, ExtractionResult,
				TempTextStorageAddress) Export
				
	FileMetadata = Metadata.FindByType(TypeOf(FileOrVersionRef));
	FullTextSearchUsing = Metadata.ObjectProperties.FullTextSearchUsing.Use;
	
	DataLock = New DataLock;
	
	DataLockItem = DataLock.Add(FileMetadata.FullName());
	DataLockItem.SetValue("Ref", FileOrVersionRef);
	
	Owner = Common.ObjectAttributeValue(FileOrVersionRef, "FileOwner");
	DataLockItem = DataLock.Add(Metadata.FindByType(TypeOf(Owner)).FullName());
	DataLockItem.SetValue("Ref", Owner);
	
	BeginTransaction();
	Try
		DataLock.Lock();
		LockDataForEdit(FileOrVersionRef);
		
		FileOrVersionObject = FileOrVersionRef.GetObject();
		If FileOrVersionObject <> Undefined Then
			
			If Not IsBlankString(TempTextStorageAddress) Then
				If FileMetadata.FullTextSearch = FullTextSearchUsing Then
					TextExtractionResult = ExtractText(TempTextStorageAddress);
					FileOrVersionObject.TextExtractionStatus = TextExtractionResult.TextExtractionStatus;
					FileOrVersionObject.TextStorage = TextExtractionResult.TextStorage;
				Else
					FileOrVersionObject.TextExtractionStatus = Enums.FileTextExtractionStatuses.NotExtracted;
					FileOrVersionObject.TextStorage = New ValueStorage("");
				EndIf;
				DeleteFromTempStorage(TempTextStorageAddress);
			EndIf;
			
			If ExtractionResult = "NotExtracted" Then
				FileOrVersionObject.TextExtractionStatus = Enums.FileTextExtractionStatuses.NotExtracted;
			ElsIf ExtractionResult = "Extracted" Then
				FileOrVersionObject.TextExtractionStatus = Enums.FileTextExtractionStatuses.Extracted;
			ElsIf ExtractionResult = "FailedExtraction" Then
				FileOrVersionObject.TextExtractionStatus = Enums.FileTextExtractionStatuses.FailedExtraction;
			EndIf;
		
			OnWriteExtractedText(FileOrVersionObject);
		EndIf;
		
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Other functions.

Function ExtensionsListForPreview() Export
	
	// See also the PictureFormat enumerstion.
	ExtensionsForPreview = New ValueList;
	ExtensionsForPreview.Add("bmp");
	ExtensionsForPreview.Add("emf");
	ExtensionsForPreview.Add("gif");
	ExtensionsForPreview.Add("ico");
	ExtensionsForPreview.Add("icon");
	ExtensionsForPreview.Add("jpg");
	ExtensionsForPreview.Add("jpeg");
	ExtensionsForPreview.Add("png");
	ExtensionsForPreview.Add("tiff");
	ExtensionsForPreview.Add("tif");
	ExtensionsForPreview.Add("wmf");
	
	Return ExtensionsForPreview;
	
EndFunction

Function DeniedExtensionsList() Export
	
	DeniedExtensionsList = New ValueList;
	DeniedExtensionsList.Add("ade");
	DeniedExtensionsList.Add("adp");
	DeniedExtensionsList.Add("app");
	DeniedExtensionsList.Add("bas");
	DeniedExtensionsList.Add("bat");
	DeniedExtensionsList.Add("chm");
	DeniedExtensionsList.Add("class");
	DeniedExtensionsList.Add("cmd");
	DeniedExtensionsList.Add("com");
	DeniedExtensionsList.Add("cpl");
	DeniedExtensionsList.Add("crt");
	DeniedExtensionsList.Add("dll");
	DeniedExtensionsList.Add("exe");
	DeniedExtensionsList.Add("fxp");
	DeniedExtensionsList.Add("hlp");
	DeniedExtensionsList.Add("hta");
	DeniedExtensionsList.Add("ins");
	DeniedExtensionsList.Add("isp");
	DeniedExtensionsList.Add("jse");
	DeniedExtensionsList.Add("js");
	DeniedExtensionsList.Add("lnk");
	DeniedExtensionsList.Add("mda");
	DeniedExtensionsList.Add("mdb");
	DeniedExtensionsList.Add("mde");
	DeniedExtensionsList.Add("mdt");
	DeniedExtensionsList.Add("mdw");
	DeniedExtensionsList.Add("mdz");
	DeniedExtensionsList.Add("msc");
	DeniedExtensionsList.Add("msi");
	DeniedExtensionsList.Add("msp");
	DeniedExtensionsList.Add("mst");
	DeniedExtensionsList.Add("ops");
	DeniedExtensionsList.Add("pcd");
	DeniedExtensionsList.Add("pif");
	DeniedExtensionsList.Add("prf");
	DeniedExtensionsList.Add("prg");
	DeniedExtensionsList.Add("reg");
	DeniedExtensionsList.Add("scf");
	DeniedExtensionsList.Add("scr");
	DeniedExtensionsList.Add("sct");
	DeniedExtensionsList.Add("shb");
	DeniedExtensionsList.Add("shs");
	DeniedExtensionsList.Add("url");
	DeniedExtensionsList.Add("vb");
	DeniedExtensionsList.Add("vbe");
	DeniedExtensionsList.Add("vbs");
	DeniedExtensionsList.Add("wsc");
	DeniedExtensionsList.Add("wsf");
	DeniedExtensionsList.Add("wsh");
	
	Return DeniedExtensionsList;
	
EndFunction

Function PrepareSendingParametersStructure() Export
	
	Return New Structure("Recipient,Subject,Text", Undefined, "", "");
	
EndFunction

Procedure ScheduledFileSynchronizationWebdav(Parameters = Undefined, ResultAddress = Undefined) Export
	
	Common.OnStartExecuteScheduledJob(Metadata.ScheduledJobs.FileSynchronization);
	
	SetPrivilegedMode(True);
	DeleteUnsynchronizedFiles();
	
	Query = New Query;
	Query.Text = "SELECT DISTINCT
	               |	FileSynchronizationAccounts.Ref,
	               |	FileSynchronizationAccounts.Service
	               |FROM
	               |	InformationRegister.FileSynchronizationSettings AS FileSynchronizationSettings
	               |		LEFT JOIN Catalog.FileSynchronizationAccounts AS FileSynchronizationAccounts
	               |		ON FileSynchronizationSettings.Account = FileSynchronizationAccounts.Ref
	               |WHERE
	               |	NOT FileSynchronizationAccounts.DeletionMark
	               |	AND FileSynchronizationSettings.Synchronize";
	
	Result = Query.Execute().Unload();
	For each Selection In Result Do
		If IsBlankString(Selection.Service) Then
			Continue;
		EndIf;
		SynchronizeFilesWithCloudService(Selection.Ref);
	EndDo;
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// File exchange.

// Preparation of parameters and preliminary checks before creating a file initial image.
//
Function PrepareDataToCreateFileInitialImage(ParametersStructure) Export
	
	Result = New Structure("DataReady, ConfirmationRequired, QuestionText", True, False, "");
	
	FullWindowsFileInfobaseName 	= ParametersStructure.FullWindowsFileInfobaseName;
	FileInfobaseFullNameLinux 		= ParametersStructure.FileInfobaseFullNameLinux;
	WindowsVolumesFilesArchivePath = ParametersStructure.WindowsVolumesFilesArchivePath;
	PathToVolumeFilesArchiveLinux 	= ParametersStructure.PathToVolumeFilesArchiveLinux;
	
	VolumesFilesArchivePath = "";
	FullFileInfobaseName = "";
	
	HasFilesInVolumes = False;
	
	If FilesOperations.HasFileStorageVolumes() Then
		HasFilesInVolumes = HasFilesInVolumes();
	EndIf;
	
	If Common.IsWindowsServer() Then
		
		VolumesFilesArchivePath = WindowsVolumesFilesArchivePath;
		FullFileInfobaseName = FullWindowsFileInfobaseName;
		
		If Not Common.FileInfobase() Then
			If HasFilesInVolumes AND Not IsBlankString(VolumesFilesArchivePath) AND (Left(VolumesFilesArchivePath, 2) <> "\\"
				OR StrFind(VolumesFilesArchivePath, ":") <> 0) Then
				
				Common.MessageToUser(
					NStr("ru = 'Путь к архиву с файлами томов должен быть
					           |в формате UNC (\\servername\resource)'; 
					           |en = 'The path to the volume archive must have
					           |UNC format (\\server_name\resource).'; 
					           |pl = 'Ścieżka do archiwum z plikami woluminów musi być
					           |w formacie UNC (\\servername\resource)';
					           |de = 'Der Pfad zum Archiv der Volumendatei muss
					           |im UNC-Format sein (\\servername\resource).';
					           |ro = 'Calea spre arhiva cu fișierele volumelor trebuie să fie
					           |în format UNC (\\servername\resource)';
					           |tr = 'Birim dosyalarıyla arşiv yolu
					           | UNC biçiminde olmalıdır (\\servername\resource)'; 
					           |es_ES = 'La ruta al archivo con documentos de tomos debe ser
					           |en el formato UNC (\\servername\resource)'"),
					,
					"WindowsVolumesFilesArchivePath");
				Result.DataReady = False;
			EndIf;
			If Not IsBlankString(FullFileInfobaseName) AND (Left(FullFileInfobaseName, 2) <> "\\" OR StrFind(FullFileInfobaseName, ":") <> 0) Then
				Common.MessageToUser(
					NStr("ru = 'Путь к файловой базе должен быть
					           |в формате UNC (\\servername\resource)'; 
					           |en = 'The path to the file infobase must have
					           |UNC format (\\server_name\resource).'; 
					           |pl = 'Ścieżka do plików bazy musi być
					           |w formacie UNC (\\servername\resource)';
					           |de = 'Der Dateibasispfad muss
					           |im UNC-Format sein (\\servername\resource).';
					           |ro = 'Calea spre baza de tip fișier trebuie să fie
					           |în format UNC (\\servername\resource)';
					           |tr = 'Birim dosyalarını arşivleme yolu UNC biçiminde 
					           |olmalıdır (\\ servername \ resource)'; 
					           |es_ES = 'La ruta a la base de archivos debe ser
					           |en el formato UNC (\\servername\resource)'"),
					,
					"FullWindowsFileInfobaseName");
				Result.DataReady = False;
			EndIf;
		EndIf;
	Else
		VolumesFilesArchivePath = PathToVolumeFilesArchiveLinux;
		FullFileInfobaseName = FileInfobaseFullNameLinux;
	EndIf;
	
	If IsBlankString(FullFileInfobaseName) Then
		Common.MessageToUser(
			NStr("ru = 'Укажите полное имя файловой базы (файл 1cv8.1cd)'; en = 'Please provide the full name of the file infobase (1cv8.1cd file).'; pl = 'Określ pełną nazwę bazy plików (plik 1cv8.1cd)';de = 'Geben Sie einen vollständigen Namen der Dateibasis an (Datei 1cv8.1cd)';ro = 'Specificați numele complet al bazei de fișiere (fișierul 1cv8.1cd)';tr = 'Dosya tabanının tam adını belirtin (dosya 1cv8.1cd)'; es_ES = 'Especificar un nombre completo de la base de archivos (archivo 1cv8.1cd)'"),,
			"FullWindowsFileInfobaseName");
		Result.DataReady = False;
	ElsIf Result.DataReady Then
		InfobaseFile = New File(FullFileInfobaseName);
		
		If HasFilesInVolumes Then
			If IsBlankString(VolumesFilesArchivePath) Then
				Common.MessageToUser(
					NStr("ru = 'Укажите полное имя архива с файлами томов (файл *.zip)'; en = 'Please provide the full name of the archive with volume files (it is a *.zip file).'; pl = 'Określ pełną nazwę archiwum z plikami woluminów (plik *.zip)';de = 'Geben Sie einen vollständigen Namen eines Archivs mit Volumen-Dateien an (Datei * .zip)';ro = 'Specificați numele complet al arhivei cu fișierele volumelor (fișier *.zip)';tr = 'Birim dosyaları ile arşivin tam adını belirtin (dosya * .zip)'; es_ES = 'Especificar un nombre completo de un archivo con documentos del volumen (archivo *.zip)'"),, 
					"WindowsVolumesFilesArchivePath");
				Result.DataReady = False;
			Else
				File = New File(VolumesFilesArchivePath);
				
				If File.Exist() AND InfobaseFile.Exist() Then
					Result.QuestionText = StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = 'Файлы ""%1"" и ""%2"" уже существуют.
							           |Заменить существующие файлы?'; 
							           |en = 'Files ""%1"" and ""%2"" already exist.
							           |Do you want to overwrite them?'; 
							           |pl = 'Pliki ""%1"" oraz ""%2"" już istnieją.
							           |Zastąpić istniejące pliki?';
							           |de = 'Die Dateien ""%1"" und ""%2"" sind bereits vorhanden.
							           |Bestehende Dateien ersetzen?';
							           |ro = 'Fișierele ""%1"" și ""%2"" deja există.
							           |Înlocuiți fișierele existente?';
							           |tr = 'Dosyalar ""%1"" ve ""%2"" zaten mevcut. 
							           | Mevcut dosyalar değiştirilsin mi?'; 
							           |es_ES = 'Los archivos ""%1"" y ""%2"" ya existen.
							           |¿Reemplazar los archivos existentes?'"), VolumesFilesArchivePath, FullFileInfobaseName);
					Result.ConfirmationRequired = True;
				ElsIf File.Exist() Then
					Result.QuestionText = StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = 'Файл ""%1"" уже существует.
							           |Заменить существующий файл?'; 
							           |en = 'File ""%1"" already exists.
							           |Do you want to overwrite it?'; 
							           |pl = 'Plik ""%1"" już istnieje.
							           |Zastąpić istniejący plik?';
							           |de = 'Die Datei ""%1"" existiert bereits.
							           |Bestehende Datei ersetzen?';
							           |ro = 'Fișierul ""%1"" deja există.
							           |Înlocuiți fișierul existent?';
							           |tr = 'Dosya ""%1"" zaten mevcut.  
							           | Mevcut dosya değiştirilsin mi?'; 
							           |es_ES = 'El archivo ""%1"" ya existe.
							           |¿Reemplazar el archivo existente?'"), VolumesFilesArchivePath);
					Result.ConfirmationRequired = True;
				EndIf;
			EndIf;
		EndIf;
		
		If Result.DataReady Then
			If InfobaseFile.Exist() AND NOT Result.ConfirmationRequired Then
				Result.QuestionText = StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = 'Файл ""%1"" уже существует.
						           |Заменить существующий файл?'; 
						           |en = 'File ""%1"" already exists.
						           |Do you want to overwrite it?'; 
						           |pl = 'Plik ""%1"" już istnieje.
						           |Zastąpić istniejący plik?';
						           |de = 'Die Datei ""%1"" existiert bereits.
						           |Bestehende Datei ersetzen?';
						           |ro = 'Fișierul ""%1"" deja există.
						           |Înlocuiți fișierul existent?';
						           |tr = 'Dosya ""%1"" zaten mevcut.  
						           | Mevcut dosya değiştirilsin mi?'; 
						           |es_ES = 'El archivo ""%1"" ya existe.
						           |¿Reemplazar el archivo existente?'"), FullFileInfobaseName);
				Result.ConfirmationRequired = True;
			EndIf;
			
			// Create a temporary directory.
			DirectoryName = GetTempFileName();
			CreateDirectory(DirectoryName);
			
			// Creating a temporary file directory.
			FileDirectoryName = GetTempFileName();
			CreateDirectory(FileDirectoryName);
			
			// To pass a file directory path to the OnSendFileData handler.
			SaveSetting("FileExchange", "TempDirectory", FileDirectoryName);
			
			// Adding variables to the parameters that are required to create the initial image.
			ParametersStructure.Insert("DirectoryName", DirectoryName);
			ParametersStructure.Insert("FileDirectoryName", FileDirectoryName);
			ParametersStructure.Insert("HasFilesInVolumes", HasFilesInVolumes);
			ParametersStructure.Insert("VolumesFilesArchivePath", VolumesFilesArchivePath);
			ParametersStructure.Insert("FullFileInfobaseName", FullFileInfobaseName);
		EndIf;
	EndIf;
	
	Return Result;
	
EndFunction

// Create file initial image on the server.
//
Procedure CreateFileInitialImageAtServer(Parameters, StorageAddress) Export
	
	Try
		
		ConnectionString = "File=""" + Parameters.DirectoryName + """;"
						 + "Locale=""" + Parameters.Language + """;";
		ExchangePlans.CreateInitialImage(Parameters.Node, ConnectionString);  // Actual creation of the initial image.
		
		If Parameters.HasFilesInVolumes Then
			ZIP = New ZipFileWriter;
			ZIP.Open(Parameters.VolumesFilesArchivePath);
			
			TemporaryFiles = New Array;
			TemporaryFiles = FindFiles(Parameters.FileDirectoryName, GetAllFilesMask());
			
			For Each TempFile In TemporaryFiles Do
				If TempFile.IsFile() Then
					TemporaryFilePath = TempFile.FullName;
					ZIP.Add(TemporaryFilePath);
				EndIf;
			EndDo;
			
			ZIP.Write();
			
			DeleteFiles(Parameters.FileDirectoryName); // Deleting along with all the files inside.
		EndIf;
		
	Except
		
		DeleteFiles(Parameters.DirectoryName);
		Raise;
		
	EndTry;
	
	TemporaryInfobaseFilePath = Parameters.DirectoryName + "\1Cv8.1CD";
	MoveFile(TemporaryInfobaseFilePath, Parameters.FullFileInfobaseName);
	
	// clearing
	DeleteFiles(Parameters.DirectoryName);
	
EndProcedure

// Preparation of parameters and preliminary checks before creating a server initial image.
//
Function PrepareDataToCreateServerInitialImage(ParametersStructure) Export
	
	Result = New Structure("DataReady, ConfirmationRequired, QuestionText", True, False, "");
	
	WindowsVolumesFilesArchivePath = ParametersStructure.WindowsVolumesFilesArchivePath;
	PathToVolumeFilesArchiveLinux 	= ParametersStructure.PathToVolumeFilesArchiveLinux;
	VolumesFilesArchivePath        = "";
	
	HasFilesInVolumes = False;
	
	If FilesOperations.HasFileStorageVolumes() Then
		HasFilesInVolumes = HasFilesInVolumes();
	EndIf;
	
	If Common.IsWindowsServer() Then
		
		VolumesFilesArchivePath = WindowsVolumesFilesArchivePath;
		
		If HasFilesInVolumes Then
			If Not IsBlankString(VolumesFilesArchivePath)
			   AND (Left(VolumesFilesArchivePath, 2) <> "\\"
			 OR StrFind(VolumesFilesArchivePath, ":") <> 0) Then
				
				Common.MessageToUser(
					NStr("ru = 'Путь к архиву с файлами томов должен быть
					           |в формате UNC (\\servername\resource).'; 
					           |en = 'The path to the volume archive must have
					           |UNC format (\\server_name\resource).'; 
					           |pl = 'Ścieżka do archiwum z plikami woluminów musi być
					           |w formacie UNC (\\servername\resource).';
					           |de = 'Der Pfad zum Archiv der Volumendatei muss
					           |im UNC-Format (\\servername\resource) vorliegen.';
					           |ro = 'Calea spre arhiva cu fișierele volumelor trebuie să fie
					           |de formatul UNC (\\servername\resource).';
					           |tr = 'Birim dosyalarıyla arşiv yolu 
					           |UNC biçiminde olmalıdır (\\servername\resource).'; 
					           |es_ES = 'La ruta al archivo con documentos de tomos debe ser
					           |en el formato UNC (\\servername\resource)'"),
					,
					"WindowsVolumesFilesArchivePath");
				Result.DataReady = False;
			EndIf;
		EndIf;
		
	Else
		VolumesFilesArchivePath = PathToVolumeFilesArchiveLinux;
	EndIf;
	
	If Result.DataReady Then
		If HasFilesInVolumes AND IsBlankString(VolumesFilesArchivePath) Then
				Common.MessageToUser(
					NStr("ru = 'Укажите полное имя архива с файлами томов (файл *.zip)'; en = 'Please provide the full name of the archive with volume files (it is a *.zip file).'; pl = 'Określ pełną nazwę archiwum z plikami woluminów (plik *.zip)';de = 'Geben Sie einen vollständigen Namen eines Archivs mit Volumen-Dateien an (Datei * .zip)';ro = 'Specificați numele complet al arhivei cu fișierele volumelor (fișier *.zip)';tr = 'Birim dosyaları ile arşivin tam adını belirtin (dosya * .zip)'; es_ES = 'Especificar un nombre completo de un archivo con documentos del volumen (archivo *.zip)'"),
					,
					"WindowsVolumesFilesArchivePath");
				Result.DataReady = False;
		Else
			If HasFilesInVolumes Then
				File = New File(VolumesFilesArchivePath);
				If File.Exist() Then
					Result.QuestionText = StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = 'Файл ""%1"" уже существует.
							           |Заменить существующий файл?'; 
							           |en = 'File ""%1"" already exists.
							           |Do you want to overwrite it?'; 
							           |pl = 'Plik ""%1"" już istnieje.
							           |Zastąpić istniejący plik?';
							           |de = 'Die Datei ""%1"" existiert bereits.
							           |Bestehende Datei ersetzen?';
							           |ro = 'Fișierul ""%1"" deja există.
							           |Înlocuiți fișierul existent?';
							           |tr = 'Dosya ""%1"" zaten mevcut.  
							           | Mevcut dosya değiştirilsin mi?'; 
							           |es_ES = 'El archivo ""%1"" ya existe.
							           |¿Reemplazar el archivo existente?'"), VolumesFilesArchivePath);
					Result.ConfirmationRequired = True;
				EndIf;
			EndIf;
			
			// Create a temporary directory.
			DirectoryName = GetTempFileName();
			CreateDirectory(DirectoryName);
			
			// Creating a temporary file directory.
			FileDirectoryName = GetTempFileName();
			CreateDirectory(FileDirectoryName);
			
			// To pass a file directory path to the OnSendFileData handler.
			SaveSetting("FileExchange", "TempDirectory", FileDirectoryName);
			
			// Adding variables to the parameters that are required to create the initial image.
			ParametersStructure.Insert("HasFilesInVolumes", HasFilesInVolumes);
			ParametersStructure.Insert("FilePath", VolumesFilesArchivePath);
			ParametersStructure.Insert("DirectoryName", DirectoryName);
			ParametersStructure.Insert("FileDirectoryName", FileDirectoryName);
		EndIf;
	EndIf;
	
	Return Result;
	
EndFunction

// Create server initial image on the server.
//
Procedure CreateServerInitialImageAtServer(Parameters, ResultAddress) Export
	
	Try
		
		ExchangePlans.CreateInitialImage(Parameters.Node, Parameters.ConnectionString);
		
		If Parameters.HasFilesInVolumes Then
			ZIP = New ZipFileWriter;
			ZIPPath = Parameters.FilePath;
			ZIP.Open(ZIPPath);
			
			TemporaryFiles = New Array;
			TemporaryFiles = FindFiles(Parameters.FileDirectoryName, GetAllFilesMask());
			
			For Each TempFile In TemporaryFiles Do
				If TempFile.IsFile() Then
					TemporaryFilePath = TempFile.FullName;
					ZIP.Add(TemporaryFilePath);
				EndIf;
			EndDo;
			
			ZIP.Write();
			DeleteFiles(Parameters.FileDirectoryName); // Deleting along with all the files inside.
		EndIf;
		
	Except
		
		DeleteFiles(Parameters.DirectoryName);
		Raise;
		
	EndTry;
	
	// clearing
	DeleteFiles(Parameters.DirectoryName);
	
EndProcedure

// Adds files to volumes and sets references in FileVersions.
//
Procedure AddFilesToVolumes(WindowsArchivePath, PathToArchiveLinux) Export
	
	FullFileNameZip = "";
	If Common.IsWindowsServer() Then
		FullFileNameZip = WindowsArchivePath;
	Else
		FullFileNameZip = PathToArchiveLinux;
	EndIf;
	
	DirectoryName = GetTempFileName();
	CreateDirectory(DirectoryName);
	
	ZIP = New ZipFileReader(FullFileNameZip);
	ZIP.ExtractAll(DirectoryName, ZIPRestoreFilePathsMode.DontRestore);
	
	FilesPathsMap = New Map;
	
	For Each ZIPItem In ZIP.Items Do
		FullFilePath = DirectoryName + "\" + ZIPItem.Name;
		UUID = ZIPItem.BaseName;
		
		FilesPathsMap.Insert(UUID, FullFilePath);
	EndDo;
	
	FilesStorageTyoe = FilesStorageTyoe();
	BeginTransaction();
	Try
		AddFilesToVolumesWhenPlacing(FilesPathsMap, FilesStorageTyoe);
		
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;
		
	// Clearing recent change records.
	For Each ExchangePlan In Metadata.ExchangePlans Do
		ExchangePlanName      = ExchangePlan.Name;
		ExchangePlanManager = ExchangePlans[ExchangePlanName];
		
		ThisNode = ExchangePlanManager.ThisNode();
		Selection = ExchangePlanManager.Select();
		
		While Selection.Next() Do
			
			ExchangePlanObject = Selection.GetObject();
			If ExchangePlanObject.Ref <> ThisNode Then
				DeleteChangesRegistration(ExchangePlanObject.Ref);
			EndIf;
		EndDo;
		
	EndDo;
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Scheduled job handlers.

// TextExtraction scheduled job handler.
// Extracts text from files on the hard disk.
//
Procedure ExtractTextFromFilesAtServer() Export
	
	Common.OnStartExecuteScheduledJob(Metadata.ScheduledJobs.TextExtraction);
	
	ExtractTextFromFiles();
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Extracting text.

// Returns text for a query used to get files with unextracted text.
//
// Parameters:
//  GetAllFiles - Boolean - the initial value is False. If True, disables individual file selection.
//                     
//
// Returns:
//  String - a query text.
//
Function QueryTextToExtractText(GetAllFiles = False, AdditionalFields = False) Export
	
	// Generating the query text for all attached file catalogs
	QueryText = "";
	
	FilesTypes = Metadata.DefinedTypes.AttachedFile.Type.Types();
	
	TotalCatalogNames = New Array;
	
	For Each Type In FilesTypes Do
		FilesDirectoryMetadata = Metadata.FindByType(Type);
		DontUseFullTextSearch = Metadata.ObjectProperties.FullTextSearchUsing.DontUse;
		If FilesDirectoryMetadata.FullTextSearch = DontUseFullTextSearch Then
			Continue;
		EndIf;
		TotalCatalogNames.Add(FilesDirectoryMetadata.Name);
	EndDo;
	
	FilesNumberInSelection = Int(100 / TotalCatalogNames.Count());
	FilesNumberInSelection = ?(FilesNumberInSelection < 10, 10, FilesNumberInSelection);
	
	For each CatalogName In TotalCatalogNames Do
	
		If NOT IsBlankString(QueryText) Then
			QueryText = QueryText + "
				|
				|UNION ALL
				|
				|";
		EndIf;
		
		QueryText = QueryText + QueryTextForFilesWithUnextractedText(CatalogName,
			FilesNumberInSelection, GetAllFiles, AdditionalFields);
		EndDo;
		
	Return QueryText;
	
EndFunction

////////////////////////////////////////////////////////////////////////////////
// Updating an infobase.

// Moves ProhibitedFileExtensionList and OpenDocumentFileExtensionList constants.
Procedure MoveExtensionConstants() Export
	
	SetPrivilegedMode(True);
	
	If Not Common.DataSeparationEnabled() Then
		
		DeniedExtensionsList = Constants.DeniedExtensionsList.Get();
		Constants.DeniedDataAreaExtensionsList.Set(DeniedExtensionsList);
		
		FilesExtensionsListOpenDocument = Constants.FilesExtensionsListOpenDocument.Get();
		Constants.FilesExtensionsListDocumentDataAreas.Set(FilesExtensionsListOpenDocument);
		
	EndIf;	
	
EndProcedure	

////////////////////////////////////////////////////////////////////////////////
// Scanning

Function ScannerParametersInEnumerations(PermissionNumber, ChromaticityNumber, RotationNumber, PaperSizeNumber) Export 
	
	If PermissionNumber = 200 Then
		Permission = Enums.ScannedImageResolutions.dpi200;
	ElsIf PermissionNumber = 300 Then
		Permission = Enums.ScannedImageResolutions.dpi300;
	ElsIf PermissionNumber = 600 Then
		Permission = Enums.ScannedImageResolutions.dpi600;
	ElsIf PermissionNumber = 1200 Then
		Permission = Enums.ScannedImageResolutions.dpi1200;
	EndIf;
	
	If ChromaticityNumber = 0 Then
		Chromaticity = Enums.ImageColorDepths.Monochrome;
	ElsIf ChromaticityNumber = 1 Then
		Chromaticity = Enums.ImageColorDepths.Grayscale;
	ElsIf ChromaticityNumber = 2 Then
		Chromaticity = Enums.ImageColorDepths.Color;
	EndIf;
	
	If RotationNumber = 0 Then
		Rotation = Enums.PictureRotationOptions.NoRotation;
	ElsIf RotationNumber = 90 Then
		Rotation = Enums.PictureRotationOptions.Right90;
	ElsIf RotationNumber = 180 Then
		Rotation = Enums.PictureRotationOptions.Right180;
	ElsIf RotationNumber = 270 Then
		Rotation = Enums.PictureRotationOptions.Left90;
	EndIf;
	
	If PaperSizeNumber = 0 Then
		PaperSize = Enums.PaperSizes.NotDefined;
	ElsIf PaperSizeNumber = 11 Then
		PaperSize = Enums.PaperSizes.A3;
	ElsIf PaperSizeNumber = 1 Then
		PaperSize = Enums.PaperSizes.A4;
	ElsIf PaperSizeNumber = 5 Then
		PaperSize = Enums.PaperSizes.A5;
	ElsIf PaperSizeNumber = 6 Then
		PaperSize = Enums.PaperSizes.B4;
	ElsIf PaperSizeNumber = 2 Then
		PaperSize = Enums.PaperSizes.B5;
	ElsIf PaperSizeNumber = 7 Then
		PaperSize = Enums.PaperSizes.B6;
	ElsIf PaperSizeNumber = 14 Then
		PaperSize = Enums.PaperSizes.C4;
	ElsIf PaperSizeNumber = 15 Then
		PaperSize = Enums.PaperSizes.C5;
	ElsIf PaperSizeNumber = 16 Then
		PaperSize = Enums.PaperSizes.C6;
	ElsIf PaperSizeNumber = 3 Then
		PaperSize = Enums.PaperSizes.USLetter;
	ElsIf PaperSizeNumber = 4 Then
		PaperSize = Enums.PaperSizes.USLegal;
	ElsIf PaperSizeNumber = 10 Then
		PaperSize = Enums.PaperSizes.USExecutive;
	EndIf;
	
	Result = New Structure;
	Result.Insert("Permission", Permission);
	Result.Insert("Chromaticity", Chromaticity);
	Result.Insert("Rotation", Rotation);
	Result.Insert("PaperSize", PaperSize);
	Return Result;
	
EndFunction

////////////////////////////////////////////////////////////////////////////////
// Clear unused files

Procedure ClearExcessiveFiles(Parameters = Undefined, ResultAddress = Undefined) Export
	
	Common.OnStartExecuteScheduledJob(Metadata.ScheduledJobs.ExcessiveFilesClearing);
	
	SetPrivilegedMode(True);
	
	CleanupSettings = InformationRegisters.FilesClearingSettings.CurrentClearSettings();
	
	FilesClearingSettings = CleanupSettings.FindRows(New Structure("IsCatalogItemSetup", False));
	
	For Each Setting In FilesClearingSettings Do
		
		ExceptionsArray = New Array;
		DetailedSettings = CleanupSettings.FindRows(New Structure(
		"OwnerID, IsCatalogItemSetup",
			Setting.FileOwner,
			True));
		If DetailedSettings.Count() > 0 Then
			For Each ExceptionItem In DetailedSettings Do
				ExceptionsArray.Add(ExceptionItem.FileOwner);
				ClearUnusedFilesData(ExceptionItem);
			EndDo;
		EndIf;
		
		ClearUnusedFilesData(Setting, ExceptionsArray);
	EndDo;
	

EndProcedure

Function ExceptionItemsOnClearFiles() Export
	
	Return FilesSettings().DontClearFiles;
	
EndFunction

////////////////////////////////////////////////////////////////////////////////
// Configuration subsystems event handlers.

// See StandardSubsystemsServer.OnSendDataToSlave. 
Procedure OnSendDataToSlave(DataItem, ItemSending, InitialImageCreation, Recipient) Export
	
	WhenSendingFile(DataItem, ItemSending, InitialImageCreation, Recipient);
	
EndProcedure

// See StandardSubsystemsServer.OnSendDataToMaster. 
Procedure OnSendDataToMaster(DataItem, ItemSending, Recipient) Export
	
	WhenSendingFile(DataItem, ItemSending);
	
EndProcedure

// See StandardSubsystemsServer.OnReceiveDataFromSlave. 
Procedure OnReceiveDataFromSlave(DataItem, GetItem, SendBack, Sender) Export
	
	WhenReceivingFile(DataItem, GetItem, Sender);
	
EndProcedure

// See StandardSubsystemsServer.OnReceiveDataFromMaster. 
Procedure OnReceiveDataFromMaster(DataItem, GetItem, SendBack, Sender) Export
	
	WhenReceivingFile(DataItem, GetItem);
	
EndProcedure

// See CommonOverridable.OnAddRefsSearchExceptions. 
Procedure OnAddReferenceSearchExceptions(Array) Export
	
	Array.Add(Metadata.InformationRegisters.FilesInWorkingDirectory.FullName());
	Array.Add(Metadata.InformationRegisters.FilesInfo.FullName());
	
EndProcedure

// See ToDoListOverridable.OnDetermineToDoListHandlers 
Procedure OnFillToDoList(ToDoList) Export
	
	ModuleToDoListServer = Common.CommonModule("ToDoListServer");
	If Not AccessRight("Read", Metadata.Catalogs.Files)
		Or ModuleToDoListServer.UserTaskDisabled("FilesToEdit") Then
		Return;
	EndIf;
	
	LockedFilesCount = LockedFilesCount();
	
	// This procedure is only called when To-do list subsystem is available. Therefore, the subsystem 
	// availability check is redundant.
	Sections = ModuleToDoListServer.SectionsForObject(Metadata.Catalogs.Files.FullName());
	
	For Each Section In Sections Do
		
		EditedFilesID = "FilesToEdit" + StrReplace(Section.FullName(), ".", "");
		ToDoItem = ToDoList.Add();
		ToDoItem.ID  = EditedFilesID;
		ToDoItem.HasToDoItems       = LockedFilesCount > 0;
		ToDoItem.Presentation  = NStr("ru = 'Редактируемые файлы'; en = 'Locked files'; pl = 'Edytowane pliki';de = 'Dateien werden bearbeitet';ro = 'Fișiere editate';tr = 'Düzenlenen dosyalar'; es_ES = 'Archivos en edición'");
		ToDoItem.Count     = LockedFilesCount;
		ToDoItem.Important         = False;
		ToDoItem.Form          = "DataProcessor.FilesOperations.Form.FilesToEdit";
		ToDoItem.Owner       = Section;
		
	EndDo;
	
EndProcedure

// See BatchObjectModificationOverridable.OnDetermineObjectsWithEditableAttributes. 
Procedure OnDefineObjectsWithEditableAttributes(Objects) Export
	Objects.Insert(Metadata.Catalogs.FilesFolders.FullName(), "AttributesToEditInBatchProcessing");
	Objects.Insert(Metadata.Catalogs.Files.FullName(), "AttributesToEditInBatchProcessing");
	Objects.Insert(Metadata.Catalogs.FilesVersions.FullName(), "AttributesToEditInBatchProcessing");
	Objects.Insert(Metadata.Catalogs.FileStorageVolumes.FullName(), "AttributesToEditInBatchProcessing");
EndProcedure

// See ImportDataFromFileOverridable.OnDefineCatalogsForDataImport. 
Procedure OnDefineCatalogsForDataImport(CatalogsToImport) Export
	
	// File synchronization with cloud service.
	
	// Import to the FilesStorageVolumes is prohibited.
	TableRow = CatalogsToImport.Find(Metadata.Catalogs.FileStorageVolumes.FullName(), "FullName");
	If TableRow <> Undefined Then 
		CatalogsToImport.Delete(TableRow);
	EndIf;
	
EndProcedure

// See ScheduledJobsOverridable.OnDefineScheduledJobsSettings. 
Procedure OnDefineScheduledJobSettings(Dependencies) Export
	Dependence = Dependencies.Add();
	Dependence.ScheduledJob = Metadata.ScheduledJobs.TextExtraction;
	If Common.SubsystemExists("StandardSubsystems.FullTextSearch") Then
		ModuleFullTextSearchServer = Common.CommonModule("FullTextSearchServer");
		Dependence.FunctionalOption = ModuleFullTextSearchServer.UseFullTextSearchFunctionalOption();
	EndIf;
	Dependence.AvailableSaaS = False;
	
	Dependence = Dependencies.Add();
	Dependence.ScheduledJob = Metadata.ScheduledJobs.ExcessiveFilesClearing;
	Dependence.UseExternalResources = True;
	
	Dependence = Dependencies.Add();
	Dependence.ScheduledJob = Metadata.ScheduledJobs.FileSynchronization;
	Dependence.FunctionalOption = Metadata.FunctionalOptions.UseFileSync;
	Dependence.UseExternalResources = True;
EndProcedure

// See AccessManagementOverridable.OnFillListsWithAccessRestriction. 
Procedure OnFillListsWithAccessRestriction(Lists) Export
	
	Lists.Insert(Metadata.Catalogs.FilesVersions, True);
	Lists.Insert(Metadata.Catalogs.FilesFolders, True);
	Lists.Insert(Metadata.Catalogs.Files, True);
	
EndProcedure

// See AccessManagementOverridable.OnFillAvailableRightsForObjectsRightsSettings. 
Procedure OnFillAvailableRightsForObjectsRightsSettings(AvailableRights) Export
	
	////////////////////////////////////////////////////////////
	// Catalog.FilesFolders
	
	// Read folders and files right.
	Right = AvailableRights.Add();
	Right.RightsOwner  = Metadata.Catalogs.FilesFolders.FullName();
	Right.Name           = "Read";
	Right.Title     = NStr("ru = 'Чтение'; en = 'Read'; pl = 'Do odczytu';de = 'Lesen';ro = 'Citire';tr = 'Oku'; es_ES = 'Leer'");
	Right.ToolTip     = NStr("ru = 'Чтение папок и файлов'; en = 'Read folders and files.'; pl = 'Odczyt folderów i plików';de = 'Lesen von Ordnern und Dateien';ro = 'Citește folderele și fișierele';tr = 'Klasörleri ve dosyaları okuma'; es_ES = 'Leyendo carpetas y archivos'");
	Right.InitialValue = True;
	// Rights for standard access restriction templates.
	Right.ReadInTables.Add("*");
	
	// Change folders right
	Right = AvailableRights.Add();
	Right.RightsOwner  = Metadata.Catalogs.FilesFolders.FullName();
	Right.Name           = "FoldersModification";
	Right.Title     = NStr("ru = 'Изменение
	                                 |папок'; 
	                                 |en = 'Change
	                                 |folders'; 
	                                 |pl = 'Zmiana
	                                 |folderów';
	                                 |de = 'Ordner
	                                 |ändern';
	                                 |ro = 'Modificarea
	                                 |folderelor';
	                                 |tr = 'Klasörlerin 
	                                 |değişikliği'; 
	                                 |es_ES = 'Cambio
	                                 |de carpetas'");
	Right.ToolTip     = NStr("ru = 'Добавление, изменение и
	                                 |пометка удаления папок файлов'; 
	                                 |en = 'Add and change folders, and
	                                 |set deletion marks to file folders.'; 
	                                 |pl = 'Dodawanie, zmiana i
	                                 |oznaczanie usuwania folderów plików';
	                                 |de = 'Hinzufügen, Ändern und
	                                 |Markieren von Dateiordnern';
	                                 |ro = 'Adăugarea, modificarea și
	                                 |marcarea la ștergere a folderelor de fișiere';
	                                 |tr = 'Dosya klasörlerini ekleme, 
	                                 |değiştirme ve etiketleme'; 
	                                 |es_ES = 'Añadir, cambiar y
	                                 |marcar para borrar las carpetas de archivos'");
	// Rights that are required for this right.
	Right.RequiredRights.Add("Read");
	// Rights for standard access restriction templates.
	Right.ChangeInTables.Add(Metadata.Catalogs.FilesFolders.FullName());
	
	// Change files right
	Right = AvailableRights.Add();
	Right.RightsOwner  = Metadata.Catalogs.FilesFolders.FullName();
	Right.Name           = "FilesModification";
	Right.Title     = NStr("ru = 'Изменение
	                                 |файлов'; 
	                                 |en = 'Change 
	                                 |files'; 
	                                 |pl = 'Zmiana
	                                 |plików';
	                                 |de = 'Dateien
	                                 |ändern';
	                                 |ro = 'Modificarea
	                                 |fișierelor';
	                                 |tr = 'Dosyaları 
	                                 |değiştirme'; 
	                                 |es_ES = 'Cambio
	                                 |de archivos'");
	Right.ToolTip     = NStr("ru = 'Изменение файлов в папке'; en = 'Change files in a folder.'; pl = 'Zmiana pliku w folderze';de = 'Ändern Sie die Dateien im Ordner';ro = 'Schimbați fișierele în folder';tr = 'Klasördeki dosyaları değiştir'; es_ES = 'Cambiar los archivos en la carpeta'");
	// Rights that are required for this right.
	Right.RequiredRights.Add("Read");
	// Rights for standard access restriction templates.
	Right.ChangeInTables.Add("*");
	
	// Add files right
	Right = AvailableRights.Add();
	Right.RightsOwner  = Metadata.Catalogs.FilesFolders.FullName();
	Right.Name           = "AddFiles";
	Right.Title     = NStr("ru = 'Добавление
	                                 |файлов'; 
	                                 |en = 'Add
	                                 |files'; 
	                                 |pl = 'Dodawanie
	                                 |plików';
	                                 |de = 'Dateien
	                                 |hinzufügen                               ';
	                                 |ro = 'Adăugarea
	                                 |fișierelor';
	                                 |tr = 'Dosyaları 
	                                 | ekleme'; 
	                                 |es_ES = 'Añadir
	                                 |archivos'");
	Right.ToolTip     = NStr("ru = 'Добавление файлов в папку'; en = 'Add files to a folder.'; pl = 'Dodawanie plików do folderu';de = 'Dateien zum Ordner hinzufügen';ro = 'Adăugați fișiere în dosar';tr = 'Klasöre dosya ekle'; es_ES = 'Agregar los archivos a la carpeta'");
	// Rights that are required for this right.
	Right.RequiredRights.Add("FilesModification");
	
	// File deletion mark right.
	Right = AvailableRights.Add();
	Right.RightsOwner  = Metadata.Catalogs.FilesFolders.FullName();
	Right.Name           = "FilesDeletionMark";
	Right.Title     = NStr("ru = 'Пометка
	                                 |удаления'; 
	                                 |en = 'Deletion 
	                                 |mark'; 
	                                 |pl = 'Oznaczanie
	                                 |usunięcia';
	                                 |de = 'Markierung
	                                 |entfernen';
	                                 |ro = 'Marcaj la
	                                 |ștergere';
	                                 |tr = 'Silme 
	                                 |işareti'; 
	                                 |es_ES = 'Marcar para
	                                 |borrar'");
	Right.ToolTip     = NStr("ru = 'Пометка удаления файлов в папке'; en = 'Set deletion marks to files in a folder.'; pl = 'Znacznik usunięcia pliku w folderze';de = 'Dateilöschmarkierung im Ordner';ro = 'Marcaj de ștergere a fișierelor din dosar';tr = 'Klasördeki dosya silme işareti'; es_ES = 'Marca de borrado del archivo en la carpeta'");
	// Rights that are required for this right.
	Right.RequiredRights.Add("FilesModification");
	
	Right = AvailableRights.Add();
	Right.RightsOwner  = Metadata.Catalogs.FilesFolders.FullName();
	Right.Name           = "RightsManagement";
	Right.Title     = NStr("ru = 'Управление
	                                 |правами'; 
	                                 |en = 'Rights
	                                 |management'; 
	                                 |pl = 'Zarządzanie
	                                 |uprawnieniami';
	                                 |de = 'Rechte
	                                 |verwalten';
	                                 |ro = 'Administrarea
	                                 |drepturilor';
	                                 |tr = 'Haklar 
	                                 | yönetimi'; 
	                                 |es_ES = 'Gestión
	                                 |de derechos'");
	Right.ToolTip     = NStr("ru = 'Управление правами папки'; en = 'Manage folder rights.'; pl = 'Zarządzanie prawami folderu';de = 'Ordner Rechteverwaltung';ro = 'Administrarea dreptului dosarelor';tr = 'Klasör doğru yönetimi'; es_ES = 'Gestión de los derechos de la carpeta'");
	// Rights that are required for this right.
	Right.RequiredRights.Add("Read");
	
EndProcedure

// See AccessManagementOverridable.OnFillMetadataObjectsAccessRestrictionsKinds. 
Procedure OnFillMetadataObjectsAccessRestrictionKinds(Details) Export
	
	Details = Details + "
		|Catalog.FilesFolders.Read.RightsSettings.Catalog.FilesFolders
		|Catalog.FilesFolders.Update.RightsSettings.Catalog.FilesFolders
		|Catalog.Files.Read.RightsSettings.Catalog.FilesFolders
		|Catalog.Files.Update.RightsSettings.Catalog.FilesFolders
		|Catalog.Files.Update.ExternalUsers
		|Catalog.Files.Read.ExternalUsers
		|";
	
	FilesOwnersTypes = Metadata.DefinedTypes.FilesOwner.Type.Types();
	For Each OwnerType In FilesOwnersTypes Do
		
		OwnerMetadata = Metadata.FindByType(OwnerType);
		If OwnerMetadata = Undefined Then
			Continue;
		EndIf;
		
		FullOwnerName = OwnerMetadata.FullName();
		
		Details = Details + "
			|Catalog.FilesVersions.Read.Object." + FullOwnerName + "
			|Catalog.FilesVersions.Update.Object." + FullOwnerName + "
			|Catalog.Files.Read.Object." + FullOwnerName + "
			|Catalog.Files.Update.Object." + FullOwnerName + "
			|";
		
	EndDo;
	
EndProcedure

// See InfobaseUpdateSSL.OnAddUpdateHandlers. 
Procedure OnAddUpdateHandlers(Handlers) Export
	
	Handler = Handlers.Add();
	Handler.Version = "1.0.5.2"; // When updating to 1.0.5.2 the handler will start.
	Handler.Procedure = "FilesOperationsInternal.FillVersionNumberFromCatalogCode";
	
	Handler = Handlers.Add();
	Handler.Version = "1.0.5.2"; // When updating to 1.0.5.2 the handler will start.
	Handler.Procedure = "FilesOperationsInternal.FillFileStorageTypeInInfobase";
	
	Handler = Handlers.Add();
	Handler.Version = "1.0.5.7"; // When updating to 1.0.5.7 the handler will start.
	Handler.Procedure = "FilesOperationsInternal.ChangeIconIndex";
	
	Handler = Handlers.Add();
	Handler.Version = "1.0.6.3"; // When updating to 1.0.6.3 the handler will start.
	Handler.SharedData = True;
	Handler.Procedure = "FilesOperationsInternal.FillVolumePaths";
	
	Handler = Handlers.Add();
	Handler.Version = "1.0.7.1";
	Handler.Procedure = "FilesOperationsInternal.OverwriteAllFiles";
	
	Handler = Handlers.Add();
	Handler.Version = "1.1.2.2";
	Handler.Procedure = "FilesOperationsInternal.FillFileModificationDate";
	
	Handler = Handlers.Add();
	Handler.Version = "1.2.1.2";
	Handler.Procedure = "FilesOperationsInternal.MoveFilesFromInfobaseToInformationRegister";
	
	Handler = Handlers.Add();
	Handler.Version = "1.2.1.2";
	Handler.Procedure = "FilesOperationsInternal.FillLoanDate";
	
	Handler = Handlers.Add();
	Handler.Version = "2.1.1.6";
	Handler.Procedure = "FilesOperationsInternal.MoveExtensionConstants";
	
	Handler = Handlers.Add();
	Handler.Version = "2.2.1.15";
	Handler.Procedure = "FilesOperationsInternal.ReplaceRightsInFileFolderRightsSettings";
	
	Handler = Handlers.Add();
	Handler.Version = "2.4.1.1";
	Handler.SharedData = True;
	Handler.InitialFilling = True;
	Handler.Procedure = "FilesOperationsInternal.UpdateDeniedExtensionsList";
	Handler.ExecutionMode = "Seamless";
	
	Handler = Handlers.Add();
	Handler.Version = "2.4.1.1";
	Handler.InitialFilling = True;
	Handler.Procedure = "FilesOperationsInternal.UpdateProhibitedExtensionListInDataArea";
	Handler.ExecutionMode = "Seamless";
	
	If Common.SubsystemExists("StandardSubsystems.DigitalSignature") Then
		Handler = Handlers.Add();
		Handler.Version = "2.4.1.49";
		Handler.Comment =
			NStr("ru = 'Перенос электронных подписей и сертификатов шифрования
			           |из табличных частей в регистры сведений.'; 
			           |en = 'Move digital signatures and encryption certificates from
			           |tabular sections to information registers.'; 
			           |pl = 'Przenoszenie elektronicznych podpisów i certyfikatów szyfrowania
			           |z tabelarycznych części do rejestrów informacji.';
			           |de = 'Übertragung von digitalen Signaturen und Verschlüsselungszertifikaten
			           |von tabellarischen Teilen in Datenregistern.';
			           |ro = 'Transferul semnăturilor electronice și certificatelor de cifrare
			           |din secțiunile tabelare în registrele de date.';
			           |tr = 'Elektronik imzaları ve şifreleme sertifikalarını tablo 
			           |parçalarından bilgi kayıtlarına aktarma.'; 
			           |es_ES = 'El traslado de las firmas electrónicas y certificados de cifrado
			           |de las partes de tabla en el registro de información.'");
		Handler.ID = New UUID("d70f378a-41f5-4b0a-a1a7-f4ba27c7f91b");
		Handler.Procedure = "FilesOperationsInternal.MoveDigitalSignaturesAndEncryptionCertificatesToInformationRegisters";
		Handler.ExecutionMode = "Deferred";
		Handler.DeferredProcessingQueue = 1;
		Handler.UpdateDataFillingProcedure = "FilesOperationsInternal.RegisterObjectsToMoveDigitalSignaturesAndEncryptionCertificates";
		Handler.ObjectsToBeRead      = StrConcat(FullCatalogsNamesOfAttachedFiles(), ", ");
		Handler.ObjectsToChange    = ObjectsToModifyOnTransferDigitalSignaturesAndEncryptionResults() + "," + StrConcat(FullCatalogsNamesOfAttachedFiles(), ", ");
		Handler.CheckProcedure    = "InfobaseUpdate.DataUpdatedForNewApplicationVersion";
		Handler.ExecutionPriorities = InfobaseUpdate.HandlerExecutionPriorities();
		Priority = Handler.ExecutionPriorities.Add();
		Priority.Procedure = "InformationRegisters.BinaryFilesData.ProcessDataForMigrationToNewVersion";
		Priority.Order = "To";
		Priority = Handler.ExecutionPriorities.Add();
		Priority.Procedure = "InformationRegisters.FilesExist.ProcessDataForMigrationToNewVersion";
		Priority.Order = "Any";
		Priority = Handler.ExecutionPriorities.Add();
		Priority.Procedure = "InformationRegisters.FilesInfo.ProcessDataForMigrationToNewVersion";
		Priority.Order = "Any";
		Priority = Handler.ExecutionPriorities.Add();
		Priority.Procedure = "Catalogs.Files.ProcessDataForMigrationToNewVersion";
		Priority.Order = "Any";
	EndIf;
	
	Handler = Handlers.Add();
	Handler.Version = "2.4.1.50";
	Handler.Comment =
			NStr("ru = 'Перенос двоичных данных файлов в регистр сведений Двоичные данные файлов.'; en = 'Move binary file data to the ""Binary file data"" information register.'; pl = 'Przesyłanie plików danych binarnych do informacji o rejestrze Pliki danych binarnych.';de = 'Перенос двоичных данных файлов в регистр сведений Двоичные данные файлов.';ro = 'Transferul datelor binare ale fișierelor în registrul de informații Date binare ale fișierelor.';tr = 'İkili veri dosyalarını ikili veri dosyalarının kayıt bilgilerini aktarma.'; es_ES = 'Traslado de los datos binarios de archivos al registro de información Datos binarios de archivos.'");
	Handler.ID = New UUID("bb2c6a93-98b0-4a01-8793-6b82f316490e");
	Handler.Procedure = "InformationRegisters.BinaryFilesData.ProcessDataForMigrationToNewVersion";
	Handler.ExecutionMode = "Deferred";
	Handler.DeferredProcessingQueue = 2;
	Handler.UpdateDataFillingProcedure = "InformationRegisters.BinaryFilesData.RegisterDataToProcessForMigrationToNewVersion";
	Handler.ObjectsToBeRead      = "Catalog.FilesVersions";
	Handler.ObjectsToChange    = "Catalog.FilesVersions,InformationRegister.BinaryFilesData";
	Handler.ObjectsToLock   = "Catalog.Files, Catalog.FilesVersions";
	Handler.CheckProcedure    = "InfobaseUpdate.DataUpdatedForNewApplicationVersion";
	Handler.ExecutionPriorities = InfobaseUpdate.HandlerExecutionPriorities();
	Priority = Handler.ExecutionPriorities.Add();
	Priority.Procedure = "FilesOperationsInternal.MoveDigitalSignaturesAndEncryptionCertificatesToInformationRegisters";
	Priority.Order = "After";
	
	Handler = Handlers.Add();
	Handler.Version = "2.4.1.1";
	Handler.Comment =
			NStr("ru = 'Перенос информации о наличии файлов в регистр сведений Наличие файлов.'; en = 'Move file availability data to the ""Has files"" information register.'; pl = 'Przekazywanie informacji o obecności plików w informacji o rejestrze Obecność plików.';de = 'Übertragung von Informationen der Dateiverfügbarkeit in das Datenregister Verfügbarkeit von Dateien.';ro = 'Transferul informațiilor despre prezența fișierelor în registrul de date Prezența fișierelor.';tr = 'Kayıt bilgilerindeki dosyaların varlığı hakkında bilgi aktarımı Dosyaların varlığı.'; es_ES = 'Traslado de infirmación de presencia de archivos al registro d información Presencia de archivos.'");
	Handler.ID = New UUID("a84931bb-dfd5-4525-ab4a-1a0646e17334");
	Handler.Procedure = "InformationRegisters.FilesExist.ProcessDataForMigrationToNewVersion";
	Handler.ExecutionMode = "Deferred";
	Handler.UpdateDataFillingProcedure = "InformationRegisters.FilesExist.RegisterDataToProcessForMigrationToNewVersion";
	Handler.ObjectsToBeRead      = "Catalog.Files";
	Handler.ObjectsToChange    = "Catalog.Files,InformationRegister.FilesExist";
	Handler.ObjectsToLock   = "Catalog.Files";
	Handler.DeferredProcessingQueue = 3;
	Handler.CheckProcedure    = "InfobaseUpdate.DataUpdatedForNewApplicationVersion";
	Handler.ExecutionPriorities = InfobaseUpdate.HandlerExecutionPriorities();
	Priority = Handler.ExecutionPriorities.Add();
	Priority.Procedure = "FilesOperationsInternal.MoveDigitalSignaturesAndEncryptionCertificatesToInformationRegisters";
	Priority.Order = "Any";
	Priority = Handler.ExecutionPriorities.Add();
	Priority.Procedure = "InformationRegisters.FilesInfo.ProcessDataForMigrationToNewVersion";
	Priority.Order = "Any";
	Priority = Handler.ExecutionPriorities.Add();
	Priority.Procedure = "Catalogs.Files.ProcessDataForMigrationToNewVersion";
	Priority.Order = "Any";
	
	Handler = Handlers.Add();
	Handler.Version = "2.4.3.56";
	Handler.Comment =
			NStr("ru = 'Обновление универсальной даты и типа хранения элементов справочника Файлы.'; en = 'Update universal date and storage type for items of the ""Files"" catalog.'; pl = 'Zaktualizuj uniwersalną datę i typ przechowywania elementów katalogu Pliki.';de = 'Aktualisieren Sie das universelle Datum und den Speichertyp des Dateiverzeichnisses.';ro = 'Actualizarea datei universale și tipului de stocare a elementelor clasificatorului Fișiere.';tr = 'Genel tarih ve Dosyalar katalogu öğeleri depolama türünü güncelleştirme.'; es_ES = 'Actualización de la fecha universal y del tipo de guarda de elementos del catálogo Archivos.'");
	Handler.ID = New UUID("8b417c47-dd46-45ce-b59b-c675059c9020");
	Handler.Procedure = "Catalogs.Files.ProcessDataForMigrationToNewVersion";
	Handler.ExecutionMode = "Deferred";
	Handler.ObjectsToBeRead      = "Catalog.Files";
	Handler.ObjectsToChange    = "Catalog.Files";
	Handler.ObjectsToLock   = "Catalog.Files, Catalog.FilesVersions";
	Handler.DeferredProcessingQueue = 5;
	Handler.UpdateDataFillingProcedure = "Catalogs.Files.RegisterDataToProcessForMigrationToNewVersion";
	Handler.CheckProcedure    = "InfobaseUpdate.DataUpdatedForNewApplicationVersion";
	Handler.ExecutionPriorities = InfobaseUpdate.HandlerExecutionPriorities();
	Priority = Handler.ExecutionPriorities.Add();
	Priority.Procedure = "FilesOperationsInternal.MoveDigitalSignaturesAndEncryptionCertificatesToInformationRegisters";
	Priority.Order = "Any";
	Priority = Handler.ExecutionPriorities.Add();
	Priority.Procedure = "InformationRegisters.FilesExist.ProcessDataForMigrationToNewVersion";
	Priority.Order = "Any";
	Priority = Handler.ExecutionPriorities.Add();
	Priority.Procedure = "InformationRegisters.FilesInfo.ProcessDataForMigrationToNewVersion";
	Priority.Order = "Any";
	
	Handler = Handlers.Add();
	Handler.Version = "2.4.1.1";
	Handler.SharedData = True;
	Handler.Procedure = "FilesOperationsInternal.UpdateVolumePathLinux";
	Handler.ExecutionMode = "Seamless";
	
	Handler = Handlers.Add();
	Handler.Version = "3.0.2.46";
	Handler.Comment =
			NStr("ru = 'Перенос информации о файлах в регистр сведений Сведения о файлах.'; en = 'Move file data to the ""File properties"" information register.'; pl = 'Przenoszenie informacji o pliku do rejestru Informacji o plikach.';de = 'Übertragen von Informationen zu Dateien in das Dateiinformationsregister Dateiinformationen.';ro = 'Transferul informațiilor despre fișiere în registrul de date Informații despre fișiere.';tr = 'Dosyalar ile ilgili bilgilerin kayıt bilgi dosyası bilgisine aktarılması.'; es_ES = 'Traslado de información de archivos al registro de información Información de archivos.'");
	Handler.ID = New UUID("5137a43e-75aa-4a68-ba2f-525a3a646af8");
	Handler.Procedure = "InformationRegisters.FilesInfo.ProcessDataForMigrationToNewVersion";
	Handler.ExecutionMode = "Deferred";
	Handler.ObjectsToBeRead      = "Catalog.Files,InformationRegister.FilesInfo";
	Handler.ObjectsToChange    = "Catalog.Files,InformationRegister.FilesInfo";
	Handler.ObjectsToLock   = "Catalog.Files,InformationRegister.FilesInfo";
	Handler.DeferredProcessingQueue = 4;
	Handler.UpdateDataFillingProcedure = "InformationRegisters.FilesInfo.RegisterDataToProcessForMigrationToNewVersion";
	Handler.CheckProcedure    = "InfobaseUpdate.DataUpdatedForNewApplicationVersion";
	Handler.ExecutionPriorities = InfobaseUpdate.HandlerExecutionPriorities();
	Priority = Handler.ExecutionPriorities.Add();
	Priority.Procedure = "FilesOperationsInternal.MoveDigitalSignaturesAndEncryptionCertificatesToInformationRegisters";
	Priority.Order = "Any";
	Priority = Handler.ExecutionPriorities.Add();
	Priority.Procedure = "InformationRegisters.FilesExist.ProcessDataForMigrationToNewVersion";
	Priority.Order = "Any";
	Priority = Handler.ExecutionPriorities.Add();
	Priority.Procedure = "Catalogs.Files.ProcessDataForMigrationToNewVersion";
	Priority.Order = "Any";
	
	Handler = Handlers.Add();
	Handler.Procedure = "FilesOperationsInternal.InitialFilling";
	Handler.InitialFilling = True;
	Handler.ExecutionMode = "Seamless";
	
EndProcedure

// See CommonOverridable.OnAddMetadataObjectsRenaming. 
Procedure OnAddMetadataObjectsRenaming(Total) Export
	
	Library = "StandardSubsystems";
	
	OldName = "Role.FileFolderOperations";
	NewName  = "Role.AddEditFoldersAndFiles";
	Common.AddRenaming(Total, "2.4.1.1", OldName, NewName, Library);
	
EndProcedure

// See CommonOverridable.OnAddClientParameters. 
Procedure OnAddClientParameters(Parameters) Export
	
	If Not Common.SeparatedDataUsageAvailable() Then
		Return;
	EndIf;
	
	FilesOperationsSettings = FilesOperationsInternalCached.FilesOperationSettings();
	
	Parameters.Insert("PersonalFilesOperationsSettings", New FixedStructure(
		FilesOperationsSettings.PersonalSettings));
	
	Parameters.Insert("CommonFilesOperationsSettings", New FixedStructure(
		FilesOperationsSettings.CommonSettings));
	
EndProcedure

// See CommonOverridable.OnAddClientParametersOnStart. 
Procedure OnAddClientParametersOnStart(Parameters) Export
	
	If Not Common.SeparatedDataUsageAvailable() Then
		Return;
	EndIf;
	
	FilesOperationsSettings = FilesOperationsInternalCached.FilesOperationSettings();
	
	Parameters.Insert("PersonalFilesOperationsSettings", New FixedStructure(
		FilesOperationsSettings.PersonalSettings));
		
	LockedFilesCount = 0;
	If Common.SeparatedDataUsageAvailable() Then
		User = Users.AuthorizedUser();
		If TypeOf(User) = Type("CatalogRef.Users") Then
			LockedFilesCount = LockedFilesCount();
		EndIf;
	EndIf;
	
	Parameters.Insert("LockedFilesCount", LockedFilesCount);
	
EndProcedure

// See SafeModeManagerOverridable.OnFillPermissionsToAccessExternalResources. 
Procedure OnFillPermissionsToAccessExternalResources(PermissionsRequests) Export
	
	If GetFunctionalOption("StoreFilesInVolumesOnHardDrive") Then
		Catalogs.FileStorageVolumes.AddRequestsToUseExternalResourcesForAllVolumes(PermissionsRequests);
	EndIf;
	
EndProcedure

// See DataExportImportOverridable.OnFillCommonDataTypesThatDoNotRequireMappingRefsOnImport. 
Procedure OnFillCommonDataTypesThatDoNotRequireMappingRefsOnImport(Types) Export
	
	// During data export the references to the FileStorageVolumes catalog are cleared, and during data 
	// import the import is performed according to the volume settings of the infobase, to which the 
	// data is imported (not according to the volume settings of the infobase, from which the data is 
	// exported).
	Types.Add(Metadata.Catalogs.FileStorageVolumes);
	
EndProcedure

// See ReportsOptionsOverridable.CustomizeReportsOptions. 
Procedure OnSetUpReportsOptions(Settings) Export
	ModuleReportsOptions = Common.CommonModule("ReportsOptions");
	ModuleReportsOptions.CustomizeReportInManagerModule(Settings, Metadata.Reports.IrrelevantFilesVolume);
	ModuleReportsOptions.CustomizeReportInManagerModule(Settings, Metadata.Reports.VolumeIntegrityCheck);
EndProcedure

// See MonitoringCenterOverridable.OnCollectConfigurationStatisticsParameters. 
Procedure OnCollectConfigurationStatisticsParameters() Export
	
	If Not Common.SubsystemExists("StandardSubsystems.MonitoringCenter") Then
		Return;
	EndIf;
	
	ModuleMonitoringCenter = Common.CommonModule("MonitoringCenter");
	
	QueryText = 
		"SELECT
		|	COUNT(1) AS Count
		|FROM
		|	Catalog.FileSynchronizationAccounts AS FileSynchronizationAccounts";
	
	Query = New Query(QueryText);
	Selection = Query.Execute().Select();
	
	ModuleMonitoringCenter.WriteConfigurationObjectStatistics("Catalog.FileSynchronizationAccounts", Selection.Count());
	
EndProcedure

// See UsersOverridable.OnDefineRolesAssignment. 
Procedure OnDefineRoleAssignment(RolesAssignment) Export
	
	// BothForUsersAndExternalUsers.
	RolesAssignment.ForExternalUsersOnly.Add(
		Metadata.Roles.AddEditFoldersAndFilesByExternalUsers.Name);
	
EndProcedure

// See PropertyManagerOverridable.OnGetPredefinedPropertiesSets. 
Procedure OnGetPredefinedPropertiesSets(Sets) Export
	Set = Sets.Rows.Add();
	Set.Name = "Catalog_FilesFolders";
	Set.ID = New UUID("3f4bfd8d-b111-4416-8797-760b78f15910");
	
	Set = Sets.Rows.Add();
	Set.Name = "Catalog_Files";
	Set.ID = New UUID("f85ae5e1-0ff9-4c97-b2bb-d0996eacc6cf");
EndProcedure

// To migrate from SSL versions 2.3.7 and earlier. It connects the AttachedFiles and FilesOperations 
// subsystems.
//
Procedure OnDefineSubsystemsInheritance(DataExported, InheritingSubsystems) Export
	
	FilterByDeletedFiles = New Structure;
	FilterByDeletedFiles.Insert("Updated", True);
	FilterByDeletedFiles.Insert("DeletionMark", True);
	DeletedItems = DataExported.FindRows(FilterByDeletedFiles);
	InheritingSubsystems = New Array;
	For Each DeletedItem In DeletedItems Do
		If StrFind(DeletedItem.FullName, "Subsystem.StandardSubsystems.Subsystem.AttachedFiles") Then
			FilesOperationsString = DataExported.Find("Subsystem.StandardSubsystems.Subsystem.FilesOperations", "FullName");
			If FilesOperationsString <> Undefined Then
				InheritingSubsystems.Add(FilesOperationsString);
			EndIf;
			
			Break;
		EndIf;
	EndDo;
	
EndProcedure

#EndRegion

#Region Private

// Returns a path to a user working directory in settings.
//
// Returns:
//  String - directory name.
//
Function UserWorkingDirectory()
	
	SetPrivilegedMode(True);
	DirectoryName = Common.CommonSettingsStorageLoad("LocalFileCache", "PathToLocalFileCache");
	If DirectoryName = Undefined Then
		DirectoryName = "";
	EndIf;
	
	Return DirectoryName;
	
EndFunction

// Returns the URL to the file (to an attribute or temporary storage).
Function FileURL(FileRef, UUID) Export
	
	If IsFilesOperationsItem(FileRef) Then
		Return FilesOperationsInternalServerCall.GetURLToOpen(FileRef, UUID);
	EndIf;
	
	Return Undefined;
	
EndFunction

// On write subscription handler of the attached file.
//
Procedure OnWriteAttachedFileServer(FilesOwner, Source) Export
	
	SetPrivilegedMode(True);
	BeginTransaction();
	Try
	
		RecordChanged = False;
		
		DataLock = New DataLock;
		DataLockItem = DataLock.Add(Metadata.InformationRegisters.FilesExist.FullName());
		DataLockItem.SetValue("ObjectWithFiles", FilesOwner);
		DataLock.Lock();
		
		RecordManager = InformationRegisters.FilesExist.CreateRecordManager();
		RecordManager.ObjectWithFiles = FilesOwner;
		RecordManager.Read();
		
		If NOT ValueIsFilled(RecordManager.ObjectWithFiles) Then
			RecordManager.ObjectWithFiles = FilesOwner;
			RecordChanged = True;
		EndIf;
		
		If NOT RecordManager.HasFiles Then
			RecordManager.HasFiles = True;
			RecordChanged = True;
		EndIf;
		
		If IsBlankString(RecordManager.ObjectID) Then
			RecordManager.ObjectID = GetNextObjectID();
			RecordChanged = True;
		EndIf;
		
		If RecordChanged Then
			RecordManager.Write();
		EndIf;
		
		If Not Source.IsFolder Then
			RecordManager = InformationRegisters.FilesInfo.CreateRecordManager();
			FillPropertyValues(RecordManager, Source);
			RecordManager.File = Source;
			If Source.SignedWithDS AND Source.Encrypted Then
				RecordManager.SignedEncryptedPictureNumber = 2;
			ElsIf Source.Encrypted Then
				RecordManager.SignedEncryptedPictureNumber = 1;
			ElsIf Source.SignedWithDS Then
				RecordManager.SignedEncryptedPictureNumber = 0;
			Else
				RecordManager.SignedEncryptedPictureNumber = -1;
			EndIf;
			
			RecordManager.Write();
		EndIf;
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;
	
EndProcedure

// The internal function is used when creating the initial image.
// Always executed on the server.
//
Procedure CopyFileOnCreateInitialImage(FullPath, NewFilePath)
	
	Try
		// If the file is in the volume, copy it to the temporary directory (during the initial image generation).
		FileCopy(FullPath, NewFilePath);
		TempFile = New File(NewFilePath);
		TempFile.SetReadOnly(False);
	Except
		// Cannot register, possibly the file is not found.
		// The missing file can be restored later, so the exception is ignored in order not to stop the 
		// initial image creation.
	EndTry;
	
EndProcedure

// An internal function that stores binary file data to a value storage.
// 
//
Function PutBinaryDataInStorage(Volume, PathToFile, UUID)
	
	FullPath = FullVolumePath(Volume) + PathToFile;
	UUID = UUID;
	
	BinaryData = New BinaryData(FullPath);
	Return New ValueStorage(BinaryData);
	
EndFunction

Procedure ClearDataOnVersion(FileRef)
	
	FileNameWithPath = "";
	FileNameWithPathForDeletion = "";
	
	BeginTransaction();
	
	Try
		
		DataLock = New DataLock;
		DataLockItem = DataLock.Add(Metadata.FindByType(TypeOf(FileRef)).FullName());
		DataLockItem.SetValue("Ref", FileRef);
		DataLock.Lock();
		
		FileObject = FileRef.GetObject();
		
		CommentText = NStr("ru = 'Файл удален при очистке ненужных файлов.'; en = 'The file was cleaned up.'; pl = 'Plik usunięty podczas czyszczenia niepotrzebnych plików.';de = 'Datei wurde gelöscht, wenn nicht benötigte Dateien bereinigt wurden.';ro = 'Fișierul este șters la golirea fișierelor nedorite.';tr = 'Gereksiz dosyaları temizlerken dosya silinir.'; es_ES = 'El archivo ha sido eliminado al limpiar los archivos no necesarios.'")
			+ " " + Format(CurrentSessionDate(),"DLF=D") + Chars.LF;
		
		If FileObject.FileStorageType = Enums.FileStorageTypes.InVolumesOnHardDrive Then
			FileNameWithPath = FullVolumePath(FileObject.Volume) + FileObject.PathToFile;
			FileNameWithPathForDeletion = FileNameWithPath + ".del";
			FileOnHardDrive = New File(FileNameWithPath);
			If FileOnHardDrive.Exist() Then
				FileOnHardDrive.SetReadOnly(False);
				// Moving file to a temporary one.
				MoveFile(FileNameWithPath, FileNameWithPathForDeletion);
				FileObject.Volume = Catalogs.FileStorageVolumes.EmptyRef();
				FileObject.PathToFile = "";
				FileObject.Comment = CommentText + FileObject.Comment;
				FileObject.Write();
				FileObject.SetDeletionMark(True);
				// Deleting the temporary file, because file data was successfully updated.
				DeleteFiles(FileNameWithPathForDeletion);
			EndIf;
		Else
			
			SetPrivilegedMode(True);
			
			RecordSet = InformationRegisters.BinaryFilesData.CreateRecordSet();
			RecordSet.Filter.File.Set(FileRef);
			RecordSet.Read();
			If RecordSet.Count() > 0 Then
				
				FileObject.Comment = CommentText + FileObject.Comment;
				FileObject.Write();
				
				RecordSet.Clear();
				RecordSet.Write();
				
			EndIf;
			
			FileObject.SetDeletionMark(True);
			SetPrivilegedMode(False);
			
		EndIf;
		
		CommitTransaction();
		
	Except
		
		RollbackTransaction();
		
		If Not IsBlankString(FileNameWithPath) Then
			
			// Write an error to the event log.
			WriteLogEvent(NStr("ru = 'Очистка ненужных файлов'; en = 'Clean up obsolete files'; pl = 'Oczyszczenie niepotrzebnych plików';de = 'Unnötige Dateien bereinigen';ro = 'Golirea fișierelor nedorite';tr = 'Gereksiz dosyaları temizle'; es_ES = 'Limpiar archivos no necesarios'", Common.DefaultLanguageCode()),
				EventLogLevel.Error,, FileRef, DetailErrorDescription(ErrorInfo()));
			
			// Returning the file to its original place in case of an error.
			MoveFile(FileNameWithPathForDeletion, FileNameWithPath);
			
		EndIf;
		
	EndTry;
	
EndProcedure

Procedure ClearDataAboutFile(FileRef)
	
	FileNameWithPath = "";
	FileNameWithPathForDeletion = "";
	
	BeginTransaction();
	
	Try
		
		DataLock = New DataLock;
		DataLockItem = DataLock.Add(Metadata.FindByType(TypeOf(FileRef)).FullName());
		DataLockItem.SetValue("Ref", FileRef);
		DataLock.Lock();
		
		FileObject = FileRef.GetObject();
		
		DetailsText = NStr("ru = 'Файл удален при очистке ненужных файлов.'; en = 'The file was cleaned up.'; pl = 'Plik usunięty podczas czyszczenia niepotrzebnych plików.';de = 'Datei wurde gelöscht, wenn nicht benötigte Dateien bereinigt wurden.';ro = 'Fișierul este șters la golirea fișierelor nedorite.';tr = 'Gereksiz dosyaları temizlerken dosya silinir.'; es_ES = 'El archivo ha sido eliminado al limpiar los archivos no necesarios.'")
			+ " " + Format(CurrentSessionDate(),"DLF=D") + Chars.LF;
		
		If FileObject.FileStorageType = Enums.FileStorageTypes.InVolumesOnHardDrive Then
			FileNameWithPath = FullVolumePath(FileObject.Volume) + FileObject.PathToFile;
			FileNameWithPathForDeletion = FileNameWithPath + ".del";
			FileOnHardDrive = New File(FileNameWithPath);
			If FileOnHardDrive.Exist() Then
				FileOnHardDrive.SetReadOnly(False);
				// Moving file to a temporary one.
				MoveFile(FileNameWithPath, FileNameWithPathForDeletion);
				FileObject.Volume = Catalogs.FileStorageVolumes.EmptyRef();
				FileObject.PathToFile = "";
				FileObject.Details = DetailsText + FileObject.Details;
				FileObject.Write();
				FileObject.SetDeletionMark(True);
				// Deleting the temporary file, because file data was successfully updated.
				DeleteFiles(FileNameWithPathForDeletion);
			EndIf;
		Else
			DeleteRecordFromBinaryFilesDataRegister(FileRef);
			FileObject.Details = DetailsText + FileObject.Details;
			FileObject.Write();
			FileObject.SetDeletionMark(True);
			
		EndIf;
		
		CommitTransaction();
		
	Except
		
		RollbackTransaction();
		
		If Not IsBlankString(FileNameWithPath) Then
			
			// Write an error to the event log.
			WriteLogEvent(NStr("ru = 'Очистка ненужных файлов'; en = 'Clean up obsolete files'; pl = 'Oczyszczenie niepotrzebnych plików';de = 'Unnötige Dateien bereinigen';ro = 'Golirea fișierelor nedorite';tr = 'Gereksiz dosyaları temizle'; es_ES = 'Limpiar archivos no necesarios'", Common.DefaultLanguageCode()),
				EventLogLevel.Error,, FileRef, DetailErrorDescription(ErrorInfo()));
			
			// Returning the file to its original place in case of an error.
			MoveFile(FileNameWithPathForDeletion, FileNameWithPath);
			
		EndIf;
		
	EndTry;
	
EndProcedure

// To pass a file directory path to the OnSendFileData handler.
//
Procedure SaveSetting(ObjectKey, SettingsKey, Settings) 
	
	SetPrivilegedMode(True);
	CommonSettingsStorage.Save(ObjectKey, SettingsKey, Settings);
	
EndProcedure

// For internal use only.
//
Procedure WhenSendingFile(DataItem, ItemSending, Val InitialImageCreation = False, Recipient = Undefined)
	
	// For non-DIB exchanges, the normal exchange session algorithm is used, not the creation of the 
	// initial image, since the parameter CreateInitialImage that equals True means initial data export.
	If InitialImageCreation AND Recipient <> Undefined 
		AND Not IsDistributedInfobaseNode(Recipient.Ref) Then
		InitialImageCreation = False;
	EndIf;
	
	If ItemSending = DataItemSend.Delete
		OR ItemSending = DataItemSend.Ignore Then
		
		// No overriding for standard data processor.
		
	ElsIf TypeOf(DataItem) = Type("CatalogObject.FilesVersions") Then
		
		If InitialImageCreation Then
			
			If DataItem.FileStorageType = Enums.FileStorageTypes.InVolumesOnHardDrive Then
				
				If Recipient <> Undefined
					AND Recipient.AdditionalProperties.Property("AllocateFilesToInitialImage") Then
					
					// Placing the file data from a hard drive volume to an internal catalog attribute.
					PutFileInCatalogAttribute(DataItem);
					
				Else
					
					// Copying the file from a hard-disk volume to the directory used for initial image creation.
					FileDirectoryName = String(CommonSettingsStorage.Load("FileExchange", "TempDirectory"));
					
					FullPath = FullVolumePath(DataItem.Volume) + DataItem.PathToFile;
					UUID = DataItem.Ref.UUID();
					
					NewFilePath = CommonClientServer.GetFullFileName(
							FileDirectoryName,
							UUID);
					
					CopyFileOnCreateInitialImage(FullPath, NewFilePath);
					
				EndIf;
				
			Else
				
				// If the file is stored in the infobase, it will be exported as a part of VersionsStoredFiles 
				// information register during the initial image creation.
				
			EndIf;
			
		Else
			ProcessFileSendingByStorageType(DataItem);
			FillFilePathOnSend(DataItem);
		EndIf;
		
	ElsIf TypeOf(DataItem) = Type("InformationRegisterRecordSet.BinaryFilesData")
		AND Not InitialImageCreation Then
		
		// Exporting the register during the initial image creation only.
		ItemSending = DataItemSend.Ignore;
		
	ElsIf NOT InitialImageCreation 
		AND IsFilesOperationsItem(DataItem)
		AND TypeOf(DataItem) <> Type("CatalogObject.MetadataObjectIDs") Then
		// Catalog MetadataObjectIDs catalog can pass according to the IsFilesOperationsItem, but cannot be 
		// processed here.
		ProcessFileSendingByStorageType(DataItem);
	EndIf;
	
EndProcedure

// For internal use only.
//
Procedure WhenReceivingFile(DataItem, GetItem, Sender = Undefined)
	
	ProcessReceivedFiles = False;
	If GetItem = DataItemReceive.Ignore Then
		
		// No overriding for standard data processor.
		
	ElsIf TypeOf(DataItem) = Type("CatalogObject.Files") Then
		
		If GetFileProhibited(DataItem) Then
			GetItem = DataItemReceive.Ignore;
			Return;
		EndIf;
		ProcessReceivedFiles = True;
		
	ElsIf TypeOf(DataItem) = Type("CatalogObject.FilesVersions")
		Or (IsFilesOperationsItem(DataItem)
			AND TypeOf(DataItem) <> Type("CatalogObject.MetadataObjectIDs")) Then
		
		// Catalog MetadataObjectIDs catalog can pass according to the IsFilesOperationsItem, but cannot be 
		// processed here.
		If GetFileVersionProhibited(DataItem) Then
			GetItem = DataItemReceive.Ignore;
			Return;
		EndIf;
		ProcessReceivedFiles = True;
		
	EndIf;
	
	If ProcessReceivedFiles Then
		
		If Sender <> Undefined AND ExchangePlans.IsChangeRecorded(Sender.Ref, DataItem) Then
				// Object collision (changes are registered both on the master node and on the subordinate one).
				GetItem = DataItemReceive.Ignore;
				Return;
		EndIf;
			
		// Deleting existing files from volumes, because once a file is received, it is stored to a volume 
		// or an infobase even if its earlier version is already stored there.
		If NOT DataItem.IsNew() Then
			
			FileVersion = Common.ObjectAttributesValues(DataItem.Ref, "FileStorageType, Volume, PathToFile");
			
			If FileVersion.FileStorageType = Enums.FileStorageTypes.InVolumesOnHardDrive Then
				
				OldPathInVolume = FullVolumePath(FileVersion.Volume) + FileVersion.PathToFile;
				
				DeleteFileInVolume(OldPathInVolume);
				
			EndIf;
			
		EndIf;
		
		BinaryData = DataItem.FileStorage.Get();
		If FilesStorageTyoe() = Enums.FileStorageTypes.InVolumesOnHardDrive Then
			
			// An item with storage in the database is received upon exchange, but the destination base stores items in volumes.
			// Placing a file in the volume from an internal attribute and changing FileStorageType to InVolumesOnHardDrive.
			MetadataType = Metadata.FindByType(TypeOf(DataItem));
			If Common.HasObjectAttribute("FileOwner", MetadataType) Then
				// This is the file catalog.
				VersionNumber = "";
			Else
				// This is a catalog of file versions.
				VersionNumber = DataItem.VersionNumber;
			EndIf;
			
			If BinaryData = Undefined Then
				
				DataItem.Volume = Undefined;
				DataItem.PathToFile = Undefined;
				
				ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
							NStr("ru = 'Не удалось добавить файл ""%1"" ни в один из томов, т.к. он отсутствует.
								|Возможно, файл удален антивирусной программой.
								|Обратитесь к администратору.'; 
								|en = 'Cannot add file ""%1"" to a volume because the file is missing.
								|The file might have been deleted by antivirus software.
								|Please contact the administrator.'; 
								|pl = 'Nie udało się dodać pliku ""%1"" do żadnego z woluminów ponieważ go brakuje.
								|Plik może być usunięty przez oprogramowanie antywirusowe.
								|Skontaktuj się z administratorem.';
								|de = 'Die Datei ""%1"" konnte keinem der Volumes hinzugefügt werden, da sie fehlt.
								|Die Datei wurde möglicherweise von einem Antivirenprogramm gelöscht.
								|Bitte wenden Sie sich an den Administrator.';
								|ro = 'Eșec la adăugarea fișierului ""%1"" în careva din volume, deoarece el lipsește.
								|Posibil, fișierul este șters de programul antivirus.
								|Adresați-vă administratorului.';
								|tr = 'Birimlerden hiçbirine ""%1"" dosyası eksik olduğundan dolayı eklenemedi. 
								|Dosya virüsten koruma programı tarafından silinmiş olabilir. 
								|Lütfen sistem yöneticinize başvurun.'; 
								|es_ES = 'No se ha podido añadir el archivo ""%1"" en ninguno de los tomos porque está ausente.
								|Es posible que el archivo haya sido eliminado por el programa antivirus.
								|Diríjase al administrador.'"),
								DataItem.Description + "." + DataItem.Extension);
				
				WriteLogEvent(NStr("ru = 'Файлы.Добавление файла в том'; en = 'Files.Add file to volume'; pl = 'Pliki.Dodanie pliku do woluminu';de = 'Dateien. Hinzufügen einer Datei zum Volumen';ro = 'Fișiere.Adăugarea fișierului în volum';tr = 'Dosyalar. Dosyanın birime eklenmesi'; es_ES = 'Archivos.Añadir el archivo al tomo'", Common.DefaultLanguageCode()),
					EventLogLevel.Error, MetadataType, DataItem.Ref, ErrorText);
				
			Else
				
				FileInfo = AddFileToVolume(BinaryData,
					DataItem.UniversalModificationDate, DataItem.Description, DataItem.Extension,
					VersionNumber, FilePathOnGetHasFlagEncrypted(DataItem)); 
				DataItem.Volume = FileInfo.Volume;
				DataItem.PathToFile = FileInfo.PathToFile;
				
			EndIf;
			
			DataItem.FileStorageType = Enums.FileStorageTypes.InVolumesOnHardDrive;
			DataItem.FileStorage = New ValueStorage(Undefined);
			
		Else
			
			If TypeOf(BinaryData) = Type("BinaryData") Then
				DataItem.AdditionalProperties.Insert("FileBinaryData", BinaryData);
			EndIf;
			
			DataItem.FileStorage = New ValueStorage(Undefined);
			DataItem.Volume = Catalogs.FileStorageVolumes.EmptyRef();
			DataItem.PathToFile = "";
			DataItem.FileStorageType = Enums.FileStorageTypes.InInfobase;
			
		EndIf;
		
	EndIf;
	
EndProcedure

Procedure FillFilePathOnSend(DataItem)
	
	If TypeOf(DataItem) <> Type("CatalogObject.FilesVersions") Then
		DataItem.PathToFile = "";
		Return;
	EndIf;
	
	DataEncrypted = Common.ObjectAttributeValue(DataItem.Owner, "Encrypted");
	DataItem.PathToFile = ?(DataEncrypted, ".p7m", "");
	
EndProcedure

Function FilePathOnGetHasFlagEncrypted(DataItem)
	
	If TypeOf(DataItem) <> Type("CatalogObject.FilesVersions") Then
		Return DataItem.Encrypted;
	EndIf;
	
	Return StrEndsWith(DataItem.PathToFile, ".p7m");
	
EndFunction

// Returns True if it is the metadata item, related to the FilesOperations subsystem.
//
Function IsFilesOperationsItem(DataItem)
	
	DataItemType = TypeOf(DataItem);
	If DataItemType = Type("ObjectDeletion") Then
		Return False;
	EndIf;
	
	ItemMetadata = DataItem.Metadata();
	
	Return Common.IsCatalog(ItemMetadata)
		AND (Metadata.DefinedTypes.AttachedFileObject.Type.ContainsType(DataItemType)
			OR (Metadata.DefinedTypes.AttachedFile.Type.ContainsType(DataItemType)));
	
EndFunction

// Writes binary file data to the infobase.
//
// Parameters:
//  AttachedFile - Reference - a reference to the attached file.
//  BinaryData     - BinaryData to be written.
//
Procedure WriteFileToInfobase(Val AttachedFile, Val BinaryData) Export
	
	SetPrivilegedMode(True);
	
	RecordManager                     = InformationRegisters.BinaryFilesData.CreateRecordManager();
	RecordManager.File                = AttachedFile;
	RecordManager.FileBinaryData = New ValueStorage(BinaryData, New Deflation(9));
	RecordManager.Write(True);
	
EndProcedure

// Returns new object ID.
//  To receive a new ID it selects the last object ID
// from the AttachmentExistence register, increases its value by one unit and returns the result.
// 
//
// Returns:
//  Row (10) - a new object ID.
//
Function GetNextObjectID() Export
	
	// Calculating new object ID.
	Result = "0000000000"; // Matching the length of ObjectID resource
	
	QueryText =
	"SELECT TOP 1
	|	FilesExist.ObjectID AS ObjectID
	|FROM
	|	InformationRegister.FilesExist AS FilesExist
	|
	|ORDER BY
	|	ObjectID DESC";
	
	Query = New Query;
	Query.Text = QueryText;
	
	Selection = Query.Execute().Select();
	If Selection.Next() Then
		ID = Selection.ObjectID;
		
		If IsBlankString(ID) Then
			Return Result;
		EndIf;
		
		// The calculation rules used are similar to regular addition: when the current digit is filled, the 
		// next digit is incremented by one and the current digit is reset to zero.
		// 
		//  Valid digit values are characters
		// [0..9] and [a..z]. Thus, one digit can contain
		// 36 values.
		
		Position = 10; // 9- index of the 10th character
		While Position > 0 Do
			
			Char = Mid(ID, Position, 1);
			
			If Char = "z" Then
				ID = Left(ID, Position-1) + "0" + Right(ID, 10 - Position);
				Position = Position - 1;
				Continue;
				
			ElsIf Char = "9" Then
				NewChar = "a";
			Else
				NewChar = Char(CharCode(Char)+1);
			EndIf;
			
			ID = Left(ID, Position-1) + NewChar + Right(ID, 10 - Position);
			Break;
		EndDo;
		
		Result = ID;
	EndIf;
	
	Return Result;
	
EndFunction

// See FilesFunctionsInternalSaaS.UpdateTextExtractionQueueState 
Procedure UpdateTextExtractionQueueState(TextSource, TextExtractionState) Export
	
	If Common.SubsystemExists("StandardSubsystems.SaaS.FilesManagerSaaS") Then
		
		If Common.DataSeparationEnabled()
		   AND Common.SeparatedDataUsageAvailable() Then
			
			ModuleFilesManagerInternalSaaS = Common.CommonModule("FilesManagerInternalSaaS");
			ModuleFilesManagerInternalSaaS.UpdateTextExtractionQueueState(TextSource, TextExtractionState);
		EndIf;
		
	EndIf;
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Other procedures and functions.

Procedure UpdateDeniedExtensionsList() Export
	
	DeniedExtensionsToImportList = DeniedExtensionsList();
	
	DeniedExtensionsListInDatabase = Constants.DeniedExtensionsList.Get();
	DeniedExtensionsArray = StrSplit(DeniedExtensionsListInDatabase, " ");
	UpdateDeniedExtensionsList = False;
	For Each Extension In DeniedExtensionsToImportList Do
		If DeniedExtensionsArray.Find(Upper(Extension)) = Undefined Then
			UpdateDeniedExtensionsList = True;
			DeniedExtensionsArray.Add(Upper(Extension));
		EndIf;
	EndDo;
	DeniedExtensionsListInDatabase = StrConcat(DeniedExtensionsArray, " ");
	If UpdateDeniedExtensionsList Then
		Constants.DeniedExtensionsList.Set(DeniedExtensionsListInDatabase);
	EndIf;
	
EndProcedure

Procedure UpdateProhibitedExtensionListInDataArea() Export
	
	DeniedExtensionsToImportList = DeniedExtensionsList();
	
	UpdateDeniedDataAreaExtensionsList = False;
	DeniedDataAreaExtensionsList = Constants.DeniedDataAreaExtensionsList.Get();
	DeniedDataAreaExtensionsArray = StrSplit(DeniedDataAreaExtensionsList, " ");
	For Each Extension In DeniedExtensionsToImportList Do
		If DeniedDataAreaExtensionsArray.Find(Upper(Extension)) = Undefined Then
			DeniedDataAreaExtensionsArray.Add(Upper(Extension));
			UpdateDeniedDataAreaExtensionsList = True;
		EndIf;
	EndDo;
	DeniedDataAreaExtensionsList = StrConcat(DeniedDataAreaExtensionsArray, " ");
	If UpdateDeniedDataAreaExtensionsList Then
		Constants.DeniedDataAreaExtensionsList.Set(DeniedDataAreaExtensionsList);
	EndIf;
	
EndProcedure

// Returns the catalog name for the specified owner or raises an exception if multiple catalogs are 
// found.
// 
// Parameters:
//  FilesOwner  - Reference - an object for adding file.
//  CatalogName  - String. If this parameter is filled, it checks for the catalog among the file 
//                    owner storage catalogs.
//                    If it is not filled, returns the main catalog name.
//  Errortitle - String - an error title.
//                  - Undefined - do not raise an exception and return a blank string.
//  ParameterName    - String - name of the parameter used to determine the catalog name.
//  ErrorEnd - String - an error end (only for the case, when ParameterName = Undefined).
// 
Function FileStoringCatalogName(FilesOwner, CatalogName = "",
	ErrorTitle = Undefined, ErrorEnd = Undefined) Export
	
	DoNotRaiseException = (ErrorTitle = Undefined);
	CatalogNames = FileStorageCatalogNames(FilesOwner, DoNotRaiseException);
	
	If CatalogNames.Count() = 0 Then
		If DoNotRaiseException Then
			Return "";
		EndIf;
		
		Raise StringFunctionsClientServer.SubstituteParametersToString(
			ErrorTitle + Chars.LF
			+ NStr("ru = 'У владельца файлов ""%1"" типа ""%2""
			             |нет справочников для хранения файлов.'; 
			             |en = 'File owner ""%1"" of type ""%2""
			             |does not have file storage catalogs.'; 
			             |pl = 'U właściciela plików ""%1"" rodzaju ""%2""
			             |nie ma poradników do przechowywania plików.';
			             |de = 'Der Eigentümer der Datei ""%1"" des Typs ""%2""
			             | hat keine Verzeichnisse zum Speichern von Dateien.';
			             |ro = 'Titularul de fișiere ""%1"" de tipul ""%2""
			             |nu are clasificatoare pentru stocarea fișierelor.';
			             |tr = '""%1"" tip ""%2"" 
			             |dosyalarının sahibinin, dosyaları depolamak için dizinleri yok.'; 
			             |es_ES = 'El propietario de los archivos ""%1"" del tipo ""%2""
			             |no tiene catálogos para guardar archivos.'"),
			String(FilesOwner),
			String(TypeOf(FilesOwner)));
	EndIf;
	
	If ValueIsFilled(CatalogName) Then
		If CatalogNames[CatalogName] <> Undefined Then
			Return CatalogName;
		EndIf;
	
		If DoNotRaiseException Then
			Return "";
		EndIf;
		
		Raise StringFunctionsClientServer.SubstituteParametersToString(
			ErrorTitle + Chars.LF
			+ NStr("ru = 'У владельца файлов ""%1"" типа ""%2""
			             |нет справочника ""%3"" для хранения файлов.'; 
			             |en = 'File owner ""%1"" of type ""%2""
			             |does not have file storage catalog ""%3"".'; 
			             |pl = 'U właściciela plików ""%1"" rodzaju ""%2""
			             |nie ma poradnika ""%3"" do przechowywania plików.';
			             |de = 'Der Eigentümer der Datei ""%1"" des Typs ""%2""
			             |hat kein Verzeichnis ""%3"" zum Speichern von Dateien.';
			             |ro = 'Titularul de fișiere ""%1"" de tipul ""%2""
			             |nu are clasificatorul ""%3"" pentru stocarea fișierelor.';
			             |tr = '""%1"" tip ""%2"" 
			             |dosyalarının sahibinin, dosyaları depolamak için ""%3"" dizinleri yok.'; 
			             |es_ES = 'El propietario de los archivos ""%1"" del tipo ""%2""
			             |no tiene catálogo ""%3"" para guardar archivos.'"),
			String(FilesOwner),
			String(TypeOf(FilesOwner)),
			String(CatalogName));
	EndIf;
	
	DefaultCatalog = "";
	For each KeyAndValue In CatalogNames Do
		If KeyAndValue.Value = True Then
			DefaultCatalog = KeyAndValue.Key;
			Break;
		EndIf;
	EndDo;
	
	If ValueIsFilled(DefaultCatalog) Then
		Return DefaultCatalog;
	EndIf;
		
	If DoNotRaiseException Then
		Return "";
	EndIf;
	
	ErrorReasonTemplate = 
		NStr("ru = 'У владельца файлов ""%1"" типа ""%2""
			|не указан основной справочник для хранения файлов.'; 
			|en = 'File owner ""%1"" of type ""%2""
			|does not have a main file storage catalog.'; 
			|pl = 'Do przechowywania plików ""%1"" rodzaju ""%2""
			|nie określono głównego poradnika do przechowywania plików.';
			|de = 'Der Eigentümer der Datei ""%1"" des Typs ""%2""
			|hat nicht das Hauptverzeichnis für die Speicherung von Dateien.';
			|ro = 'La titularul de fișiere ""%1"" de tipul ""%2""
			|nu este indicat clasificatorul principal pentru stocarea fișierelor.';
			|tr = '"
" türündeki ""%1""  %2 dosya sahibinde dosyaların depolanacağı ana katalog belirtilmemiş.'; 
			|es_ES = 'Para el propietario de archivos ""%1"" del tipo ""%2""
			|no está indicado catálogo principal para guardar los archivos.'") + Chars.LF;
			
	ErrorReason = StringFunctionsClientServer.SubstituteParametersToString(
		ErrorReasonTemplate, String(FilesOwner), String(TypeOf(FilesOwner)));
		
	ErrorText = ErrorTitle + Chars.LF
		+ ErrorReason + Chars.LF
		+ ErrorEnd;
		
	Raise TrimAll(ErrorText);
	
EndFunction

// Returns the map of catalog names and Boolean values for the specified owner.
// 
// 
// Parameters:
//  FilesOwher - Reference - an object for adding file.
// 
Function FilesVersionsStorageCatalogsNames(FilesOwner, DoNotRaiseException = False)
	
	If TypeOf(FilesOwner) = Type("Type") Then
		FilesOwnerType = FilesOwner;
	Else
		FilesOwnerType = TypeOf(FilesOwner);
	EndIf;
	
	OwnerMetadata = Metadata.FindByType(FilesOwnerType);
	
	CatalogNames = New Map;
	StandardMainCatalogName = OwnerMetadata.Name + "AttachedFilesVersions";
	If Metadata.Catalogs.Find(StandardMainCatalogName) <> Undefined Then
		CatalogNames.Insert(StandardMainCatalogName, True);
	EndIf;
	
	If Metadata.DefinedTypes.FilesOwner.Type.ContainsType(FilesOwnerType) Then
		CatalogNames.Insert("FilesVersions", True);
	EndIf;
	
	DefaultCatalogIsSpecified = False;
	
	For each KeyAndValue In CatalogNames Do
		
		If Metadata.Catalogs.Find(KeyAndValue.Key) = Undefined Then
			
			Raise StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'Ошибка при определении имен справочников для хранения версий файлов.
				           |У владельца файлов типа ""%1""
				           |указан несуществующий справочник ""%2"".'; 
				           |en = 'Cannot determine a name of a file version storage catalog.
				           |Missing catalog ""%2""
				           |is assigned to the owner of files of ""%1"" type.'; 
				           |pl = 'Błąd przy ustalaniu nazw poradników do przechowywania wersji plików.
				           |U właściciela plików rodzaju ""%1""
				           |podano nieistniejący poradnik ""%2"".';
				           |de = 'Fehler bei der Definition von Verzeichnisnamen für das Speichern von Dateiversionen.
				           |Der Eigentümer des Dateityps ""%1""
				           | hat ein nicht existierendes Verzeichnis ""%2"".';
				           |ro = 'Eroare la determinarea numelor clasificatoarelor pentru a stoca versiunile fișierelor.
				           |La titularul fișierelor de tipul ""%1""
				           |este specificat clasificatorul inexistent ""%2"".';
				           |tr = 'Dosyaları depolamak için katalog adları belirlenirken bir hata oluştu. 
				           |"
" tür dosya sahibinde ""%1"" varolmayan %2 katalog belirtildi.'; 
				           |es_ES = 'Error al determinar los nombres de catálogos para guardar las versiones de archivos.
				           |Para el propietario de archivos del tipo ""%1""
				           |está indicado un catálogo inexistente ""%2"".'"),
				String(FilesOwnerType),
				String(KeyAndValue.Key));
				
		ElsIf Not StrEndsWith(KeyAndValue.Key, "AttachedFilesVersions") AND Not KeyAndValue.Key ="FilesVersions" Then
			
			Raise StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'Ошибка при определении имен справочников для хранения версий файлов.
				           |У владельца файлов типа ""%1""
				           |указано имя справочника ""%2""
				           |без окончания ""ВерсииПрисоединенныхФайлов"".'; 
				           |en = 'Cannot determine a name of a file version storage catalog.
				           |Catalog ""%2""
				           |that does not have the ""AttachedFilesVersions"" suffix
				           |is assigned to the file owner of ""%1"" type.'; 
				           |pl = 'Błąd przy ustalaniu nazw poradników do przechowywania wersji plików.
				           |U właściciela plików rodzaju ""%1""
				           |podano imię poradnika ""%2""
				           |bez zakończenia ""AttachedFilesVersions"".';
				           |de = 'Beim Bestimmen von Katalognamen für das Speichern von Dateiversionen ist ein Fehler aufgetreten.
				           |Der Dateibesitzer vom Typ ""%1""
				           | hat den Katalognamen ""%2"" 
				           |ohne die Endung ""AttachedFilesVersions"" angegeben.';
				           |ro = 'A apărut o eroare la stabilirea numelor de catalog pentru stocarea versiunilor de fișiere.
				           |Proprietarul de fișiere de tip ""%1""
				           |are""%2""numele de catalog specificat
				           |fără ca ""AttachedFilesVersions"" să se termine.';
				           |tr = 'Dosyaları depolamak için katalog adları belirlenirken bir hata oluştu. 
				           |"
" tür dosya sahibinde ""%1"" katalog 
				           |adı ""%2"" ""AttachedFilesVersions"" takısı olmadan belirtildi.'; 
				           |es_ES = 'Error al determinar los nombres de catálogos para guardar las versiones de archivos.
				           |Para el propietario de archivos del tipo ""%1""
				           |está indicado un nombre de catálogo ""%2""
				           |sin acabar ""AttachedFilesVersions"".'"),
				String(FilesOwnerType),
				String(KeyAndValue.Key));
			
		ElsIf KeyAndValue.Value = Undefined Then
			CatalogNames.Insert(KeyAndValue.Key, False);
			
		ElsIf KeyAndValue.Value = True Then
			If DefaultCatalogIsSpecified Then
				Raise StringFunctionsClientServer.SubstituteParametersToString(
					NStr("ru = 'Ошибка при определении имен справочников для хранения версий файлов.
					           |У владельца файлов типа ""%1""
					           |основной справочник версий указан более одного раза.'; 
					           |en = 'Cannot determine a name of a file version storage catalog.
					           |Multiple main catalogs are assigned to the owner of files of
					           |""%1"" type.'; 
					           |pl = 'Błąd przy ustalaniu nazw poradników do przechowywania wersji plików.
					           |U właściciela plików rodzaju ""%1""
					           |główny poradnik wersji jest podany więcej niż jeden raz.';
					           |de = 'Fehler bei der Definition von Verzeichnisnamen für das Speichern von Dateiversionen.
					           |Der Eigentümer des Dateityps ""%1""
					           | hat das Hauptverzeichnis der Version mehr als einmal.';
					           |ro = 'Eroare la determinarea numelor clasificatoarelor pentru a stoca versiunile de fișiere.
					           |La titularul fișierelor de tipul ""%1""
					           |clasificatorul principal este specificat mai mult de o dată.';
					           |tr = 'Dosyaları depolamak için katalog adları belirlenirken bir hata oluştu. 
					           | "
"tür dosya sahibi %1 ana katalog birden fazla kez belirtildi.'; 
					           |es_ES = 'Error al determinar los nombres de catálogos para guardar las versiones de archivos.
					           |Para el propietario de archivos del tipo ""%1""
					           |está indicado un catálogo principal de versiones más de una vez.'"),
					String(FilesOwnerType),
					String(KeyAndValue.Key));
			EndIf;
			DefaultCatalogIsSpecified = True;
		EndIf;
	EndDo;
	
	Return CatalogNames;
	
EndFunction

// Returns the catalog name for the specified owner or raises an exception if multiple catalogs are 
// found.
// 
// Parameters:
//  FilesOwner  - Reference - an object for adding file.
//  CatalogName  - String. If this parameter is filled, it checks for the catalog among the file 
//                    owner storage catalogs.
//                    If it is not filled, returns the main catalog name.
//  Errortitle - String - an error title.
//                  - Undefined - do not raise an exception and return a blank string.
//  ParameterName    - String - name of the parameter used to determine the catalog name.
//  ErrorEnd - String - an error end (only for the case, when ParameterName = Undefined).
// 
Function FilesVersionsStorageCatalogName(FilesOwner, CatalogName = "",
	ErrorTitle = Undefined, ErrorEnd = Undefined) Export
	
	DoNotRaiseException = (ErrorTitle = Undefined);
	CatalogNames = FilesVersionsStorageCatalogsNames(FilesOwner, DoNotRaiseException);
	
	If CatalogNames.Count() = 0 Then
		Return "";
	EndIf;
	
	DefaultCatalog = "";
	For each KeyAndValue In CatalogNames Do
		If KeyAndValue.Value = True Then
			DefaultCatalog = KeyAndValue.Key;
			Break;
		EndIf;
	EndDo;
	
	If ValueIsFilled(DefaultCatalog) Then
		Return DefaultCatalog;
	EndIf;
		
	If DoNotRaiseException Then
		Return "";
	EndIf;
	
	ErrorReasonTemplate = 
		NStr("ru = 'У владельца версий файлов ""%1""
			|не указан основной справочник для хранения версий файлов.'; 
			|en = 'File owner ""%1"" 
			|does not have a main file version storage catalog.'; 
			|pl = 'U właściciela wersji plików ""%1""
			|nie został określony podstawowy poradnik dla przechowywania wersji plików.';
			|de = 'Der Eigentümer der ""%1""
			| Version der Datei hat nicht das Hauptverzeichnis für die Speicherung der Versionen der Dateien.';
			|ro = 'La titularul versiunilor de fișiere ""%1""
			|nu este indicat clasificatorul principal pentru stocarea fișierelor.';
			|tr = '""%1""
			|Dosya sürüm sahibinin, dosya sürümlerini depolamak için ana katalogu belirtilmemiştir.'; 
			|es_ES = 'Para el propietario de las versiones de archivos ""%1""
			|no está indicado un catálogo principal para guardar las versiones de archivos.'") + Chars.LF;
			
	ErrorReason = StringFunctionsClientServer.SubstituteParametersToString(
		ErrorReasonTemplate, String(FilesOwner));
		
	ErrorText = ErrorTitle + Chars.LF
		+ ErrorReason + Chars.LF
		+ ErrorEnd;
		
	Raise TrimAll(ErrorText);
	
EndFunction

// Cancels file editing.
//
// Parameters:
//  AttachedFile - a Reference or an Object of the attached file that needs to be released.
//
Procedure UnlockFile(Val AttachedFile) Export
	
	BeginTransaction();
	Try
	
		If Catalogs.AllRefsType().ContainsType(TypeOf(AttachedFile)) Then
			DataLock              = New DataLock;
			DataLockItem       = DataLock.Add(Metadata.FindByType(TypeOf(AttachedFile)).FullName());
			DataLockItem.SetValue("Ref", AttachedFile);
			DataLock.Lock();
			FileObject = AttachedFile.GetObject();
		Else
			FileObject = AttachedFile;
		EndIf;
		
		If ValueIsFilled(FileObject.BeingEditedBy) Then
			FileObject.BeingEditedBy = Catalogs.Users.EmptyRef();
			FileObject.Write();
		EndIf;
		
		CommitTransaction();
		
	Except
		RollbackTransaction();
		Raise;
	EndTry;
	
EndProcedure

Function LockedFilesCount(Val FileOwner = Undefined, Val BeingEditedBy = Undefined) Export
	
	SetPrivilegedMode(True);
	
	Query = New Query;
	Query.Text = 
		"SELECT COUNT(1) AS Count
		|FROM
		|	InformationRegister.FilesInfo AS FilesInfo
		|WHERE
		|	FilesInfo.BeingEditedBy <> VALUE(Catalog.Users.EmptyRef)";
	
	If BeingEditedBy = Undefined Then 
		BeingEditedBy = Users.AuthorizedUser();
	EndIf;
		
	Query.Text = Query.Text + " AND FilesInfo.BeingEditedBy = &BeingEditedBy ";
	Query.SetParameter("BeingEditedBy", BeingEditedBy);
	
	If FileOwner <> Undefined Then 
		Query.Text = Query.Text + " AND FilesInfo.FileOwner = &FileOwner ";
		Query.SetParameter("FileOwner", FileOwner);
	EndIf;
	
	Selection = Query.Execute().Unload().UnloadColumn("Count");
	Return Selection[0];
	
EndFunction

// Stores encrypted file data to a storage and sets the Encrypted flag for the file.
//
// Parameters:
//  AttachedFile  - a reference to the attached file.
//  EncryptedData - structure with the following property:
//                          TempStorageAddress - String - an address of the encrypted binary data.
//  ThumbprintsArray    - an Array of Structures containing certificate thumbprints.
// 
Procedure Encrypt(Val AttachedFile, Val EncryptedData, Val ThumbprintsArray) Export
	
	BeginTransaction();
	Try
		If Catalogs.AllRefsType().ContainsType(TypeOf(AttachedFile)) Then
			DataLock = New DataLock;
			DataLockItem = DataLock.Add(Metadata.FindByType(TypeOf(AttachedFile)).FullName());
			DataLockItem.SetValue("Ref", AttachedFile);
			DataLock.Lock();
			AttachedFileObject = AttachedFile.GetObject();
		Else
			AttachedFileObject = AttachedFile;
		EndIf;
		
		If Common.SubsystemExists("StandardSubsystems.DigitalSignature") Then
			ModuleDigitalSignatureInternal = Common.CommonModule("DigitalSignatureInternal");
			ModuleDigitalSignatureInternal.AddEncryptionCertificates(AttachedFile, ThumbprintsArray);
		EndIf;
		
		AttributesValues = New Structure;
		AttributesValues.Insert("Encrypted", True);// Encrypted move to information register
		AttributesValues.Insert("TextStorage", New ValueStorage(""));
		UpdateFileBinaryDataAtServer(AttachedFileObject, EncryptedData.TempStorageAddress, AttributesValues);
		
		If Catalogs.AllRefsType().ContainsType(TypeOf(AttachedFile)) Then
			AttachedFileObject.Write();
		EndIf;
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;
	
EndProcedure

// Stores decrypted file data to a storage and removes the Encrypted flag from the file.
// 
// Parameters:
//  AttachedFile  - a reference to the attached file.
//  EncryptedData - structure with the following property:
//                          TempStorageAddress - String - an address of the decrypted binary data.
//
Procedure Decrypt(Val AttachedFile, Val DecryptedData) Export
	
	FullTextSearchUsing = Metadata.ObjectProperties.FullTextSearchUsing.Use;
	
	BeginTransaction();
	Try
		
		CatalogMetadata = Metadata.FindByType(TypeOf(AttachedFile));
		If Catalogs.AllRefsType().ContainsType(TypeOf(AttachedFile)) Then
			AttachedFileObject = AttachedFile.GetObject();
			DataLock = New DataLock;
			DataLockItem = DataLock.Add(CatalogMetadata.FullName());
			DataLockItem.SetValue("Ref", AttachedFile);
			DataLock.Lock();
		Else
			AttachedFileObject = AttachedFile;
		EndIf;
		
		If Common.SubsystemExists("StandardSubsystems.DigitalSignature") Then
			ModuleDigitalSignatureInternal = Common.CommonModule("DigitalSignatureInternal");
			ModuleDigitalSignatureInternal.ClearEncryptionCertificates(AttachedFile);
		EndIf;
		
		AttributesValues = New Structure;
		AttributesValues.Insert("Encrypted", False);
		
		BinaryData = GetFromTempStorage(DecryptedData.TempStorageAddress);
		If CatalogMetadata.FullTextSearch = FullTextSearchUsing Then
			TextExtractionResult = ExtractText(DecryptedData.TempTextStorageAddress, BinaryData,
				AttachedFile.Extension);
			AttachedFileObject.TextExtractionStatus = TextExtractionResult.TextExtractionStatus;
			AttributesValues.Insert("TextStorage", TextExtractionResult.ExtractedText);
		Else
			AttachedFileObject.TextExtractionStatus = Enums.FileTextExtractionStatuses.NotExtracted;
			AttributesValues.Insert("TextStorage", New ValueStorage(""));
		EndIf;
		
		UpdateFileBinaryDataAtServer(AttachedFileObject, BinaryData, AttributesValues);
		
		If Catalogs.AllRefsType().ContainsType(TypeOf(AttachedFile)) Then
			AttachedFileObject.Write();
		EndIf;
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;
	
EndProcedure

// Compares two items of data composition filter.
// Parameters:
//   Item1 - an item of the list conditional appearance.
//   Item2 - an item of the list conditional appearance.
//
// Returns:
//   Boolean - comparison result.
//
Function CompareFilterItems(Item1, Item2)
	
	If Item1.Use = Item2.Use
		AND TypeOf(Item1) = TypeOf(Item2) Then
		
		If TypeOf(Item1) = Type("DataCompositionFilterItem") Then
			If Item1.ComparisonType <> Item2.ComparisonType
				OR Item1.LeftValue <> Item2.LeftValue
				OR Item1.RightValue <> Item2.RightValue Then
				Return False;
			EndIf;
		Else
			
			ItemsCount = Item1.Items.Count();
			If Item1.GroupType <> Item2.GroupType
				OR ItemsCount <> Item2.Items.Count() Then
				Return False;
			EndIf;
			
			For Index = 0 To ItemsCount - 1 Do
				SubordinateItem1 = Item1.Items[Index];
				SubordinateItem2 = Item2.Items[Index];
				ItemsEqual = CompareFilterItems(SubordinateItem1, SubordinateItem2);
				
				If Not ItemsEqual Then
					Return ItemsEqual;
				EndIf;
			EndDo;
			
		EndIf;
	Else
		Return False;
	EndIf;
	
	Return True;
	
EndFunction

// Generates a report for files with errors.
//
// Parameters:
//   ArrayOfFilesNamesWithErrors - a string array of paths to files.
//
// Returns:
//   SpreadsheetDocument with a report.
//
Function FilesImportGenerateReport(ArrayOfFilesNamesWithErrors) Export
	
	Document = New SpreadsheetDocument;
	Template = Catalogs.Files.GetTemplate("ReportTemplate");
	
	AreaHeader = Template.GetArea("Title");
	AreaHeader.Parameters.Details = NStr("ru = 'Не удалось загрузить следующие файлы:'; en = 'Cannot upload the following files:'; pl = 'Nie można zaimportować następujących plików:';de = 'Folgende Dateien können nicht importiert werden:';ro = 'Nu se pot importa următoarele fișiere:';tr = 'Aşağıdaki dosyalar içe aktarılamıyor:'; es_ES = 'No se puede importar los siguientes archivos:'");
	Document.Put(AreaHeader);
	
	AreaRow = Template.GetArea("Row");

	For Each Selection In ArrayOfFilesNamesWithErrors Do
		AreaRow.Parameters.Name = Selection.FileName;
		AreaRow.Parameters.Error = Selection.Error;
		Document.Put(AreaRow);
	EndDo;
	
	Report = New SpreadsheetDocument;
	Report.Put(Document);

	Return Report;
	
EndFunction

// Fills the conditional appearance of the file list.
//
// Parameters:
//   List - a dynamic list.
//
Procedure FillConditionalAppearanceOfFilesList(List) Export
	
	DCConditionalAppearance = List.SettingsComposer.Settings.ConditionalAppearance;
	DCConditionalAppearance.UserSettingID = "MainAppearance";
	
	Item = DCConditionalAppearance.Items.Add();
	Item.Use = True;
	Item.Appearance.SetParameterValue("TextColor", StyleColors.InaccessibleCellTextColor);
	
	FilterGroup = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	
	Filter = FilterGroup.Items.Add(Type("DataCompositionFilterItem"));
	Filter.Use = True;
	Filter.ComparisonType = DataCompositionComparisonType.Filled;
	Filter.LeftValue = New DataCompositionField("BeingEditedBy");

	Filter = FilterGroup.Items.Add(Type("DataCompositionFilterItem"));
	Filter.Use = True;
	Filter.ComparisonType = DataCompositionComparisonType.Equal;
	Filter.LeftValue = New DataCompositionField("Internal");
	Filter.RightValue = False;
	
	If HasDuplicateItem(DCConditionalAppearance.Items, Item) Then
		DCConditionalAppearance.Items.Delete(Item);
	EndIf;
	
	Item = DCConditionalAppearance.Items.Add();
	Item.Use = True;
	Item.Appearance.SetParameterValue("TextColor", StyleColors.FileLockedByCurrentUser);
	
	FilterGroup = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	
	Filter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	Filter.Use = True;
	Filter.ComparisonType = DataCompositionComparisonType.Equal;
	Filter.LeftValue = New DataCompositionField("BeingEditedBy");
	Filter.RightValue = Users.AuthorizedUser();
	
	Filter = FilterGroup.Items.Add(Type("DataCompositionFilterItem"));
	Filter.Use = True;
	Filter.ComparisonType = DataCompositionComparisonType.Equal;
	Filter.LeftValue = New DataCompositionField("Internal");
	Filter.RightValue = False;
	
	If HasDuplicateItem(DCConditionalAppearance.Items, Item) Then
		DCConditionalAppearance.Items.Delete(Item);
	EndIf;
	
	Item = DCConditionalAppearance.Items.Add();
	Item.Use = True;
	Item.Appearance.SetParameterValue("TextColor", StyleColors.InaccessibleCellTextColor);
	
	Filter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	Filter.Use = True;
	Filter.ComparisonType = DataCompositionComparisonType.Equal;
	Filter.LeftValue = New DataCompositionField("Internal");
	Filter.RightValue = True;
	
	If HasDuplicateItem(DCConditionalAppearance.Items, Item) Then
		DCConditionalAppearance.Items.Delete(Item);
	EndIf;
	
EndProcedure

// Fills conditional appearance of the folder list.
//
// Parameters:
//   List - a dynamic list.
//
Procedure FillConditionalAppearanceOfFoldersList(Folders) Export
	
	DCConditionalAppearance = Folders.SettingsComposer.Settings.ConditionalAppearance;
	DCConditionalAppearance.UserSettingID = "MainAppearance";
	
	Item = DCConditionalAppearance.Items.Add();
	Item.Use = True;
	Item.Appearance.SetParameterValue("TextColor", StyleColors.InaccessibleCellTextColor);
	
	Filter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	Filter.Use = True;
	Filter.ComparisonType = DataCompositionComparisonType.Filled;
	
	Filter.ComparisonType = DataCompositionComparisonType.Equal;
	Filter.LeftValue = New DataCompositionField("FolderSynchronizationEnabled");
	Filter.RightValue = True;
	
	If HasDuplicateItem(DCConditionalAppearance.Items, Item) Then
		DCConditionalAppearance.Items.Delete(Item);
	EndIf;
	
EndProcedure

// If there is a duplicate item in the list conditional appearance.
// Parameters:
//   Items - an item array of the list conditional appearance.
//   SearchItem - an item of the list conditional appearance.
//
// Returns:
//   Boolean - has duplicate item.
//
Function HasDuplicateItem(Items, SearchItem)
	
	For Each Item In Items Do
		If Item <> SearchItem Then
			
			If Item.Appearance.Items.Count() <> SearchItem.Appearance.Items.Count() Then
				Continue;
			EndIf;
			
			DifferentItemFound = False;
			
			// Iterating all appearance items, and if there is at least one different, click Continue.
			ItemsCount = Item.Appearance.Items.Count();
			For Index = 0 To ItemsCount - 1 Do
				Item1 = Item.Appearance.Items[Index];
				Item2 = SearchItem.Appearance.Items[Index];
				
				If Item1.Use AND Item2.Use Then
					If Item1.Parameter <> Item2.Parameter OR Item1.Value <> Item2.Value Then
						DifferentItemFound = True;
						Break;
					EndIf;
				EndIf;
			EndDo;
			
			If DifferentItemFound Then
				Continue;
			EndIf;
			
			If Item.Filter.Items.Count() <> SearchItem.Filter.Items.Count() Then
				Continue;
			EndIf;
			
			// Iterating all filter items, and if there is at least one different, click Continue.
			ItemsCount = Item.Filter.Items.Count();
			For Index = 0 To ItemsCount - 1 Do
				Item1 = Item.Filter.Items[Index];
				Item2 = SearchItem.Filter.Items[Index];
				
				ItemsEqual = CompareFilterItems(Item1, Item2);
				If Not ItemsEqual Then
					DifferentItemFound = True;
					Break;
				EndIf;
				
			EndDo;
			
			If DifferentItemFound Then
				Continue;
			EndIf;
			
			// If you iterated all appearance and filter items and they are all the same, it is a duplicate.
			Return True;
			
		EndIf;
	EndDo;
	
	Return False;
	
EndFunction

// Executes PutInTempStorage (if the file is stored on the hard drive) and returns a URL of the file in the storage.
// Parameters:
//  VersionRef  - CatalogRef.FilesVersions - a file version.
//  FormID - a form UUID.
//
// Returns:
//   String - link.
Function GetTemporaryStorageURL(VersionRef, FormID = Undefined) Export
	Address = "";
	
	FileStorageType = VersionRef.FileStorageType;
	
	If FileStorageType = Enums.FileStorageTypes.InVolumesOnHardDrive Then
		If NOT VersionRef.Volume.IsEmpty() Then
			FullPath = FullVolumePath(VersionRef.Volume) + VersionRef.PathToFile; 
			Try
				BinaryData = New BinaryData(FullPath);
				Address = PutToTempStorage(BinaryData, FormID);
			Except
				// Record to the event log.
				ErrorMessage = GenerateErrorTextOfGetFileFromVolumeForAdministrator(
					ErrorInfo(), VersionRef.Owner);
				
				WriteLogEvent(
					NStr("ru = 'Файлы.Открытие файла'; en = 'Files.Open file'; pl = 'Pliki.Otwórz plik';de = 'Dateien. Datei öffnen';ro = 'Fișiere.Deschiderea fișierului';tr = 'Dosyalar.  Dosyayı aç'; es_ES = 'Archivo.Abrir el archivo'",
					     Common.DefaultLanguageCode()),
					EventLogLevel.Error,
					Metadata.Catalogs.Files,
					VersionRef.Owner,
					ErrorMessage);
				
				Raise ErrorFileNotFoundInFileStorage(
					VersionRef.FullDescr + "." + VersionRef.Extension);
			EndTry;
		EndIf;
	Else
		FileStorage = FilesOperations.FileFromInfobaseStorage(VersionRef);
		BinaryData = FileStorage.Get();
		Address = PutToTempStorage(BinaryData, FormID);
	EndIf;
	
	Return Address;
	
EndFunction

// Generates an error text for writing to the event log.
// Parameters:
//  FunctionErrorInformation  - ErrorInformation
//  FileRef  - CatalogRef.Files - a file.
//
// Returns:
//   String - an error description
//
Function GenerateErrorTextOfGetFileFromVolumeForAdministrator(FunctionErrorInfornation, FileRef) Export
	
	Return StringFunctionsClientServer.SubstituteParametersToString(
		NStr("ru = 'Ссылка на файл: ""%1"".
		           |""%2"".'; 
		           |en = 'File reference: %1.
		           |%2'; 
		           |pl = 'Link do pliku: ""%1"".
		           |""%2"".';
		           |de = 'Ref auf die Datei: ""%1"".
		           |""%2"".';
		           |ro = 'Referința la fișier: ""%1"". 
		           |""%2"".';
		           |tr = 'Dosya referansı: ""%1"". 
		           |""%2"".'; 
		           |es_ES = 'Referencia al archivo: ""%1"".
		           |""%2"".'"),
		GetURL(FileRef),
		DetailErrorDescription(FunctionErrorInfornation));
	
EndFunction

// Receives the value of the ShowSizeColumn setting.
// Returns:
//   Boolean - show size column.
//
Function GetShowSizeColumn() Export
	
	ShowSizeColumn = Common.CommonSettingsStorageLoad("ApplicationSettings", "ShowSizeColumn");
	If ShowSizeColumn = Undefined Then
		ShowSizeColumn = False;
		Common.CommonSettingsStorageSave("ApplicationSettings", "ShowSizeColumn", ShowSizeColumn);
	EndIf;
	
	Return ShowSizeColumn;
	
EndFunction

// Returns a standard error text.
Function ErrorFileNotFoundInFileStorage(FileName, SearchVolume = True, FileOwner = "") Export
	
	If SearchVolume Then
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Не удалось открыть файл:
				|%1
				|который присоединен к:
				|%2
				|по причине: двоичные данные файла были удалены. Возможно, файл очищен как ненужный или удален антивирусной программой.
				|Обратитесь к администратору.'; 
				|en = 'Cannot open file
				|%1
				|attached to
				|%2
				|because the binary file data is missing. The file might have been cleaned up or deleted by antivirus software.
				|Please contact the administrator.'; 
				|pl = 'Nie udało się otworzyć pliku:
				|%1
				|który jest przyłączony do:
				|%2
				|z powodu: dane binarne pliku zostały usunięte. Być może plik został wyczyszczony jak niepotrzebny lub usunięty przez program antywirusowy.
				|Skontaktuj się z administratorem.';
				|de = 'Die Datei konnte nicht geöffnet werden:
				|%1
				| die Datei ist angehängt an:
				|%2
				|weil: die Binärdaten der Datei wurden gelöscht. Die Datei wurde möglicherweise von einem Antivirenprogramm als nicht benötigt bereinigt oder gelöscht.
				|Wenden Sie sich an den Administrator.';
				|ro = 'Eșec la deschiderea fișierului:
				|%1
				|atașat la:
				|%2
				|din motivul: datele binare ale fișierului au fost șterse. Posibil, fișierul a fost golit ca nedorit sau șters de programul antivirus.
				|Adresați-vă administratorului.';
				|tr = '
				|%1
				| ''e ekli 
				|%2
				|dosya aşağıdaki nedenle açılamadı: dosyanın ikili verileri silindi. Dosya gereksiz veya virüsten koruma programı tarafından kaldırılmış olabilir.
				| Lütfen yöneticinize başvurun.'; 
				|es_ES = 'No se ha podido abrir el archivo:
				|%1
				|que ha sido conectado con:
				|%2
				|a causa de: los datos binarios del archivo han sido eliminados. Es posible que el archivo haya sido vaciado como inútil o haya sido eliminado por programa de antivirus.
				|Diríjase al administrador.'"),
			FileName,
			FileOwner);
			
	Else
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Не удалось открыть файл:
				|%1
				|который присоединен к:
				|%2
				|по причине: двоичные данные файла были удалены. Возможно, файл очищен как ненужный.
				|Обратитесь к администратору.'; 
				|en = 'Cannot open file
				|%1
				|attached to
				|%2
				|because the binary file data is missing. The file might have been cleaned up.
				|Please contact the administrator.'; 
				|pl = 'Nie udało się otworzyć pliku:
				|%1
				|który jest przyłączony do:
				|%2
				|z powodu: dane binarne pliku zostały usunięte. Być może plik został wyczyszczony jak niepotrzebny.
				|Skontaktuj się z administratorem.';
				|de = 'Die Datei konnte nicht geöffnet werden:
				|%1
				| die Datei ist angehängt an:
				|%2
				|weil: die Binärdaten der Datei wurden gelöscht. Die Datei wurde möglicherweise von einem Antivirenprogramm als nicht benötigt bereinigt.
				|Wenden Sie sich an den Administrator.';
				|ro = 'Eșec la deschiderea fișierului:
				|%1
				|atașat la:
				|%2
				|din motivul: datele binare ale fișierului au fost șterse. Posibil, fișierul a fost golit ca nedorit.
				|Adresați-vă administratorului.';
				|tr = '
				|%1
				| ''e ekli 
				|%2
				|dosya aşağıdaki nedenle açılamadı: dosyanın ikili verileri silindi. Dosya gereksiz olarak kaldırılmış olabilir.
				| Lütfen yöneticinize başvurun.'; 
				|es_ES = 'No se ha podido abrir el archivo:
				|%1
				|que ha sido conectado con:
				|%2
				|a causa de: los datos binarios del archivo han sido eliminados. Es posible que el archivo haya sido vaciado como inútil.
				|Diríjase al administrador.'"),
			FileName,
			FileOwner);
	EndIf;
	
	Return ErrorText;
	
EndFunction

// Returns number ascending. Take the previous value from the ScannedFilesNumbers information register.
// Parameters:
//   Owner - AnyRef - a file owner.
//
// Returns:
//   Number  - a new number for scanning.
//
Function GetNewNumberToScan(Owner) Export
	
	// Prepare a filter structure by dimensions.
	FilterStructure = New Structure;
	FilterStructure.Insert("Owner", Owner);
	
	BeginTransaction();
	Try
		Lock = New DataLock;
		LockItem = Lock.Add("InformationRegister.ScannedFilesNumbers");
		LockItem.SetValue("Owner", Owner);
		Lock.Lock();
	
		// Receive structure with the data of record resources.
		ResourcesStructure = InformationRegisters.ScannedFilesNumbers.Get(FilterStructure);
		
		// Receive the max number from the register.
		Number = ResourcesStructure.Number;
		Number = Number + 1; // increasing by 1
		
		SetSafeModeDisabled(True);
		SetPrivilegedMode(True);
		
		// Writing a new number to the register.
		RecordSet = InformationRegisters.ScannedFilesNumbers.CreateRecordSet();
		
		RecordSet.Filter.Owner.Set(Owner);
		
		NewRecord = RecordSet.Add();
		NewRecord.Owner = Owner;
		NewRecord.Number = Number;
		
		RecordSet.Write();
		
		SetPrivilegedMode(False);
		SetSafeModeDisabled(False);
		
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;
	
	Return Number;
	
EndFunction

// Defines if catalog metadata has the Internal optional attribute.
//
// Parameters:
//  CatalogName - String - a catalog name in metadata.
//
// Returns:
//  Boolean - there is the Internal attribute.
//
Function HasInternalAttribute(Val CatalogName) Export
	
	MetadataObject  = Metadata.Catalogs[CatalogName];
	AttributeInternal = MetadataObject.Attributes.Find("Internal");
	Return AttributeInternal <> Undefined;
	
EndFunction

// Adds data composition filter items to file dynamic lists.
//
// Parameters:
//	List - a dynamic list, where filter will be added.
//
Procedure AddFiltersToFilesList(List) Export
	
	CommonClientServer.AddCompositionItem(List.Filter, "Internal", DataCompositionComparisonType.NotEqual, 
		True, "HideInternal", True);
	
EndProcedure

// Changes visibility of attached file form items for external user work.
// External users have access only to common file information and its characteristics.
//
// Parameters:
//	Form - ManagedForm - a form, whose item visibility is changed.
//  IsListForm - Boolean - indicates that procedure is called from the list form.
//
Procedure ChangeFormForExternalUser(Form, Val IsListForm = False) Export
	
	Items = Form.Items;
	If IsListForm Then
		Items.ListAuthor.Visible = False;
		Items.ListEditing.Visible = False;
		Items.ListSignedEncryptedPictureNumber.Visible = False;
		If Items.Find("ListEditedBy") <> Undefined Then
			Items.ListEditedBy.Visible = False;
		EndIf;
	Else
		Items.FileCharacteristicsGroup.Visible = True;
		Items.AdditionalPageDataGroup.Visible = False;
		Items.FormDigitalSignatureAndEncryptionCommandsGroup.Visible = False;
	EndIf;
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// User settings

// Calculating ActionOnDoubleClick. If it is for the first time, setting the correct value.
//
// Returns:
//   String - action by double click.
//
Function ActionOnDoubleClick()
	
	HowToOpen = Common.CommonSettingsStorageLoad(
		"OpenFileSettings", "ActionOnDoubleClick");
	
	If HowToOpen = Undefined
	 OR HowToOpen = Enums.DoubleClickFileActions.EmptyRef() Then
		
		HowToOpen = Enums.DoubleClickFileActions.OpenFile;
		
		Common.CommonSettingsStorageSave(
			"OpenFileSettings", "ActionOnDoubleClick", HowToOpen);
	EndIf;
	
	If HowToOpen = Enums.DoubleClickFileActions.OpenFile Then
		Return "OpenFile";
	Else
		Return "OpenCard";
	EndIf;
	
EndFunction

// Calculating from the FilesVersionsComparisonMethod settings.
//
// Returns:
//   String - a file version comparison method.
//
Function FileVersionsComparisonMethod()
	
	ComparisonMethod = Common.CommonSettingsStorageLoad(
		"FileComparisonSettings", "FileVersionsComparisonMethod");
	
	If ComparisonMethod = Enums.FileVersionsComparisonMethods.MicrosoftOfficeWord Then
		Return "MicrosoftOfficeWord";
		
	ElsIf ComparisonMethod = Enums.FileVersionsComparisonMethods.OpenOfficeOrgWriter Then
		Return "OpenOfficeOrgWriter";
	Else
		Return Undefined;
	EndIf;
	
EndFunction

// Returns the setting Ask the editing mode when opening file.
// Returns:
//   Boolean -  ask the editing mode when opening file.
//
Function PromptForEditModeOnOpenFile()
	PromptForEditModeOnOpenFile = 
		Common.CommonSettingsStorageLoad("OpenFileSettings", "PromptForEditModeOnOpenFile");
	If PromptForEditModeOnOpenFile = Undefined Then
		PromptForEditModeOnOpenFile = True;
		Common.CommonSettingsStorageSave("OpenFileSettings", "PromptForEditModeOnOpenFile", PromptForEditModeOnOpenFile);
	EndIf;
	
	Return PromptForEditModeOnOpenFile;
EndFunction

////////////////////////////////////////////////////////////////////////////////
// File exchange support

// Internal functions. Deletes files from the server .
// 
Procedure DeleteFileInVolume(FileToDeleteName)
	
	// Deleting file
	TempFile = New File(FileToDeleteName);
	If TempFile.Exist() Then
		
		Try
			TempFile.SetReadOnly(False);
			DeleteFiles(FileToDeleteName);
		Except
			WriteLogEvent(
				NStr("ru = 'Файлы.Удаление файлов в томе'; en = 'Files.Delete files from volume'; pl = 'Pliki.Usuwanie plików w woluminie';de = 'Dateien.Löschen von Dateien in einem Volume';ro = 'Fișiere.Ștergerea fișierelor în volum';tr = 'Dosyalar.  Katalogtaki dosyaların silinmesi'; es_ES = 'Archivos.Eliminar archivos en el tomo'",
				     Common.DefaultLanguageCode()),
				EventLogLevel.Error,
				,
				,
				DetailErrorDescription(ErrorInfo()));
		EndTry;
		
	EndIf;
	
	// Deleting the file directory if the directory is empty after the file deletion
	Try
		FilesArrayInDirectory = FindFiles(TempFile.Path, GetAllFilesMask());
		If FilesArrayInDirectory.Count() = 0 Then
			DeleteFiles(TempFile.Path);
		EndIf;
	Except
		WriteLogEvent(
			NStr("ru = 'Файлы.Удаление файлов в томе'; en = 'Files.Delete files from volume'; pl = 'Pliki.Usuwanie plików w woluminie';de = 'Dateien.Löschen von Dateien in einem Volume';ro = 'Fișiere.Ștergerea fișierelor în volum';tr = 'Dosyalar.  Katalogtaki dosyaların silinmesi'; es_ES = 'Archivos.Eliminar archivos en el tomo'",
			     Common.DefaultLanguageCode()),
			EventLogLevel.Error,
			,
			,
			DetailErrorDescription(ErrorInfo()));
	EndTry;
	
EndProcedure

// Adds a file to volumes when the "Store initial image files" command is performed.
// Parameters:
//  FilesPathsMap - Map - a mapping of file UUID and a file path on the hard drive.
//  FileStorageTyep - Enums.FilesStorageTypes - a storage type of files.
Procedure AddFilesToVolumesWhenPlacing(FilesPathsMap, FileStorageType)
	
	Selection = Catalogs.FilesVersions.Select();
	
	While Selection.Next() Do
		
		Object = Selection.GetObject();
		
		If Object.FileStorageType <> Enums.FileStorageTypes.InVolumesOnHardDrive Then
			Continue;
		EndIf;
		
		UUID = String(Object.Ref.UUID());
		
		FullFilePathOnHardDrive = FilesPathsMap.Get(UUID);
		FullPathNew = "";
		
		If FullFilePathOnHardDrive = Undefined Then
			Continue;
		EndIf;
		
		FileStorage = Undefined;
		
		// In the destination base, the files must be stored in the infobase (even if they were stored in 
		// volumes in the source database).
		If FileStorageType = Enums.FileStorageTypes.InInfobase Then
			
			Object.FileStorageType = Enums.FileStorageTypes.InInfobase;
			Object.PathToFile = "";
			Object.Volume = Catalogs.FileStorageVolumes.EmptyRef();
			
			BinaryData = New BinaryData(FullFilePathOnHardDrive);
			FileStorage = New ValueStorage(BinaryData);
			
		Else // In the destination base files must be stored in volumes on the disk. Moving the unzipped file to the volume.
			
			FileInitial = New File(FullFilePathOnHardDrive);
			FullPathNew = FileInitial.Path + Object.Description + "." + Object.Extension;
			MoveFile(FullFilePathOnHardDrive, FullPathNew);
			
			// Add the file to a volume with sufficient free space.
			FileInfo = AddFileToVolume(FullPathNew, Object.UniversalModificationDate,
				Object.Description, Object.Extension, Object.VersionNumber, Object.Owner.Encrypted); 
			Object.Volume = FileInfo.Volume;
			Object.PathToFile = FileInfo.PathToFile;
			
		EndIf;
		
		Object.AdditionalProperties.Insert("FilePlacementInVolumes", True); // To pass the record of signed files.
		Object.Write();
		
		If FileStorageType = Enums.FileStorageTypes.InInfobase Then
			WriteFileToInfobase(Object.Ref, FileStorage);	
		EndIf;
		
		If NOT IsBlankString(FullPathNew) Then
			DeleteFiles(FullPathNew);
		EndIf;
		
	EndDo;
	
EndProcedure

// Deletes the registration of changes after placing them into volumes.
// Parameters:
//  ExchangePlanRef - ExchangePlan.Ref - an exchange plan.
Procedure DeleteChangesRegistration(ExchangePlanRef)
	
	ExchangePlans.DeleteChangeRecords(ExchangePlanRef, Metadata.Catalogs.FilesVersions);
	ExchangePlans.DeleteChangeRecords(ExchangePlanRef, Metadata.Catalogs.Files);
	ExchangePlans.DeleteChangeRecords(ExchangePlanRef, Metadata.InformationRegisters.BinaryFilesData);
	
EndProcedure

/////////////////////////////////////////////////////////////////////////////////////////
// Operations with encodings

// The function returns a table of encoding names.
// Returns:
//   Result (ValueList)
// - Value (String) - for example, "ibm852".
// - Presentation (String) - for example, "ibm852 (Central European DOS)".
//
Function Encodings() Export

	EncodingsList = New ValueList;
	
	EncodingsList.Add("ibm852",       NStr("ru = 'IBM852 (Центральноевропейская DOS)'; en = 'IBM852 (Central European DOS)'; pl = 'IBM852 (Europa Środkowa DOS)';de = 'IBM852 (Mitteleuropäische DOS)';ro = 'IBM852 (Central European DOS)';tr = 'IBM852 (Orta Avrupa DOS)'; es_ES = 'IBM852 (DOS centroeuropeo)'"));
	EncodingsList.Add("ibm866",       NStr("ru = 'IBM866 (Кириллица DOS)'; en = 'IBM866 (Cyrillic DOS)'; pl = 'IBM866 (Cyrylica DOS)';de = 'IBM866 (Kyrillische DOS)';ro = 'IBM866 (Cyrillic DOS)';tr = 'IBM866 (Kiril DOS)'; es_ES = 'IBM866 (DOS cirílico)'"));
	EncodingsList.Add("iso-8859-1",   NStr("ru = 'ISO-8859-1 (Западноевропейская ISO)'; en = 'ISO-8859-1 (Western European ISO)'; pl = 'ISO-8859-1 (Europa Zachodnia ISO)';de = 'ISO-8859-1 (Westeuropäische ISO)';ro = 'ISO-8859-1 (Vestul Europei ISO)';tr = 'ISO-8859-1 (Batı Avrupa ISO)'; es_ES = 'ISO-8859-1 (ISO europeo occidental)'"));
	EncodingsList.Add("iso-8859-2",   NStr("ru = 'ISO-8859-2 (Центральноевропейская ISO)'; en = 'ISO-8859-2 (Central European ISO)'; pl = 'ISO-8859-2 (Europa Środkowa ISO)';de = 'ISO-8859-2 (Zentraleuropäische ISO)';ro = 'ISO-8859-2 (Central European ISO)';tr = 'ISO-8859-2 (Orta Avrupa ISO)'; es_ES = 'ISO-8859-2 (ISO europeo central)'"));
	EncodingsList.Add("iso-8859-3",   NStr("ru = 'ISO-8859-3 (Латиница 3 ISO)'; en = 'ISO-8859-3 (Latin-3 ISO)'; pl = 'ISO-8859-3 (Łaciński 3 ISO)';de = 'ISO-8859-3 (Lateinisch 3 ISO)';ro = 'ISO-8859-3 (Latin 3 ISO)';tr = 'ISO-8859-3 (Latin 3 ISO)'; es_ES = 'ISO-8859-3 (ISO latino 3)'"));
	EncodingsList.Add("iso-8859-4",   NStr("ru = 'ISO-8859-4 (Балтийская ISO)'; en = 'ISO-8859-4 (Baltic ISO)'; pl = 'ISO-8859-4 (Bałtycki ISO)';de = 'ISO-8859-4 (Baltische ISO)';ro = 'ISO-8859-4 (Baltic ISO)';tr = 'ISO-8859-4 (Baltik ISO)'; es_ES = 'ISO-8859-4 (ISO báltico)'"));
	EncodingsList.Add("iso-8859-5",   NStr("ru = 'ISO-8859-5 (Кириллица ISO)'; en = 'ISO-8859-5 (Cyrillic ISO)'; pl = 'ISO-8859-5 (Cyrylica ISO)';de = 'ISO-8859-5 (Kyrillische ISO)';ro = 'ISO-8859-5 (Cyrillic ISO)';tr = 'ISO-8859-5 (Kiril ISO)'; es_ES = 'ISO-8859-5 (ISO Cirílico)'"));
	EncodingsList.Add("iso-8859-7",   NStr("ru = 'ISO-8859-7 (Греческая ISO)'; en = 'ISO-8859-7 (Greek ISO)'; pl = 'ISO-8859-7 (Grecki ISO)';de = 'ISO-8859-7 (Griechische ISO)';ro = 'ISO-8859-7 (Grecia ISO)';tr = 'ISO-8859-7 (Yunan ISO)'; es_ES = 'ISO-8859-7 (ISO Griego)'"));
	EncodingsList.Add("iso-8859-9",   NStr("ru = 'ISO-8859-9 (Турецкая ISO)'; en = 'ISO-8859-9 (Turkish ISO)'; pl = 'ISO-8859-9 (Turecki ISO)';de = 'ISO-8859-9 (Türkische ISO)';ro = 'ISO-8859-9 (Turcia ISO)';tr = 'ISO-8859-9 (Türkçe ISO)'; es_ES = 'ISO-8859-9 (ISO Turco)'"));
	EncodingsList.Add("iso-8859-15",  NStr("ru = 'ISO-8859-15 (Латиница 9 ISO)'; en = 'ISO-8859-15 (Latin-9 ISO)'; pl = 'ISO-8859-15 (Łaciński 9 ISO)';de = 'ISO-8859-15 (Lateinisch 9 ISO)';ro = 'ISO-8859-15 (Latin 9 ISO)';tr = 'ISO-8859-15 (Latin 9 ISO)'; es_ES = 'ISO-8859-15 (ISO 9 latino)'"));
	EncodingsList.Add("koi8-r",       NStr("ru = 'KOI8-R (Кириллица KOI8-R)'; en = 'KOI8-R (Cyrillic KOI8-R)'; pl = 'KOI8-R (Cyrylica KOI8-R)';de = 'KOI8-R (Kyrillisch KOI8-R)';ro = 'KOI8-R (Cyrillic KOI8-R)';tr = 'KOI8-R (Kiril KOI8-R)'; es_ES = 'KOI8-R (KOI8-R Cirílico)'"));
	EncodingsList.Add("koi8-u",       NStr("ru = 'KOI8-U (Кириллица KOI8-U)'; en = 'KOI8-U (Cyrillic KOI8-U)'; pl = 'KOI8-U (Cyrylica KOI8-U)';de = 'KOI8-U (Kyrillisch KOI8-U)';ro = 'KOI8-U (Cyrillic KOI8-U)';tr = 'KOI8-U (Kiril KOI8-U)'; es_ES = 'KOI8-U (KOI8-U Cirílico)'"));
	EncodingsList.Add("us-ascii",     NStr("ru = 'US-ASCII (США)'; en = 'US-ASCII (USA)'; pl = 'US-ASCII (USA)';de = 'US-ASCII (USA)';ro = 'US-ASCII (USA)';tr = 'US-ASCII (ABD)'; es_ES = 'US-ASCII (Estados Unidos)'"));
	EncodingsList.Add("utf-8",        NStr("ru = 'UTF-8 (Юникод UTF-8)'; en = 'UTF-8 (Unicode UTF-8)'; pl = 'UTF-8 (Unicode UTF-8)';de = 'UTF-8 (Unicode UTF-8)';ro = 'UTF-8 (Unicode UTF-8)';tr = 'UTF-8 (Unicode UTF-8)'; es_ES = 'UTF-8 (UTF-8 Unicode)'"));
	EncodingsList.Add("utf-8_WithoutBOM", NStr("ru = 'UTF-8 (Юникод UTF-8 без BOM)'; en = 'UTF-8 (Unicode UTF-8 without BOM)'; pl = 'UTF-8 (Unicode UTF-8 bez BOM)';de = 'UTF-8 (Unicode UTF-8 ohne BOM)';ro = 'UTF-8 (Unicode UTF-8 fără BOM)';tr = 'UTF-8 (Unicode UTF-8 BOM''suz)'; es_ES = 'UTF-8 (Unicode UTF-8 sin BOM)'"));
	EncodingsList.Add("windows-1250", NStr("ru = 'Windows-1250 (Центральноевропейская Windows)'; en = 'Windows-1250 (Central European Windows)'; pl = 'Windows-1250 (Europa Środkowa Windows)';de = 'Windows-1250 (Zentraleuropäisches Windows)';ro = 'Windows-1250 (Central European Windows)';tr = 'Windows-1250 (Orta Avrupa Windows)'; es_ES = 'Windows-1250 (Windows Europeo Central)'"));
	EncodingsList.Add("windows-1251", NStr("ru = 'windows-1251 (Кириллица Windows)'; en = 'Windows-1251 (Cyrillic Windows)'; pl = 'windows-1251 (Cyrylica Windows)';de = 'Windows-1251 (Kyrillisches Windows)';ro = 'Windows-1251 (Chirillic Windows)';tr = 'Windows-1251 (Kiril Windows)'; es_ES = 'Windows-1251 (Windows Cirílico)'"));
	EncodingsList.Add("windows-1252", NStr("ru = 'Windows-1252 (Западноевропейская Windows)'; en = 'Windows-1252 (Western European Windows)'; pl = 'Windows-1252 (Europa Zachodnia Windows)';de = 'Windows-1252 (Westeuropäisches Windows)';ro = 'Windows-1252 (Vestul Europei Windows)';tr = 'Windows-1252 (Batı Avrupa Windows)'; es_ES = 'Windows-1252 (Windows Europeo occidental)'"));
	EncodingsList.Add("windows-1253", NStr("ru = 'Windows-1253 (Греческая Windows)'; en = 'Windows-1253 (Greek Windows)'; pl = 'Windows-1253 (Grecki Windows)';de = 'Windows-1253 (Griechisches Windows)';ro = 'Windows-1253 (Grecia Windows)';tr = 'Windows-1253 (Yunan Windows)'; es_ES = 'Windows-1253 (Windows griego)'"));
	EncodingsList.Add("windows-1254", NStr("ru = 'Windows-1254 (Турецкая Windows)'; en = 'Windows-1254 (Turkish Windows)'; pl = 'Windows-1254 (Turecki Windows)';de = 'Windows-1254 (Türkisches Windows)';ro = 'Windows-1254 (Turcia Windows)';tr = 'Windows-1254 (Türkçe Windows)'; es_ES = 'Windows-1254 (Windows turco)'"));
	EncodingsList.Add("windows-1257", NStr("ru = 'Windows-1257 (Балтийская Windows)'; en = 'Windows-1257 (Baltic Windows)'; pl = 'Windows-1257 (Bałtycki Windows)';de = 'Windows-1257 (Baltisches Windows)';ro = 'Windows-1257 (Baltic Windows)';tr = 'Windows-1257 (Baltik Windows)'; es_ES = 'Windows-1257 (Windows báltico)'"));
	
	Return EncodingsList;

EndFunction

////////////////////////////////////////////////////////////////////////////////
// Auxiliary procedures and functions.

// Marks a file as editable.
//
// Parameters:
//  AttachedFile - a Reference or an Object of the attached file that needs to be marked.
//
Procedure LockFileForEditingServer(Val AttachedFile, User = Undefined) Export
	
	BeginTransaction();
	Try
		If Catalogs.AllRefsType().ContainsType(TypeOf(AttachedFile)) Then
			DataLock = New DataLock;
			DataLockItem = DataLock.Add(Metadata.FindByType(TypeOf(AttachedFile)).FullName());
			DataLockItem.SetValue("Ref", AttachedFile);
			DataLock.Lock();
			
			FileObject = AttachedFile.GetObject();
			FileObject.Lock();
		Else
			FileObject = AttachedFile;
		EndIf;
		
		If User = Undefined Then
			FileObject.BeingEditedBy = Users.AuthorizedUser();
		Else
			FileObject.BeingEditedBy = User;
		EndIf;
		FileObject.Write();
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;
	
EndProcedure

Procedure WriteFileDataToRegisterDuringExchange(Source)
	
	Var FileBinaryData;
	
	If Source.AdditionalProperties.Property("FileBinaryData", FileBinaryData) Then
		RecordSet = InformationRegisters.BinaryFilesData.CreateRecordSet();
		RecordSet.Filter.File.Set(Source.Ref);
		
		Record = RecordSet.Add();
		Record.File = Source.Ref;
		Record.FileBinaryData = New ValueStorage(FileBinaryData);
		
		RecordSet.DataExchange.Load = True;
		RecordSet.Write();
		
		Source.AdditionalProperties.Delete("FileBinaryData");
	EndIf;
	
EndProcedure

Function GetFileProhibited(DataItem)
	
	Return DataItem.IsNew()
	      AND Not CheckExtentionOfFileToDownload(DataItem.Extension, False);
	
EndFunction

Function GetFileVersionProhibited(DataItem)
	
	Return DataItem.IsNew()
	      AND Not CheckExtentionOfFileToDownload(DataItem.Extension, False);
	
EndFunction

Procedure ProcessFileSendingByStorageType(DataItem)
	
	If DataItem.FileStorageType = Enums.FileStorageTypes.InVolumesOnHardDrive Then
		
		// Placing the file data from a hard drive volume to an internal catalog attribute.
		PutFileInCatalogAttribute(DataItem);
		
	Else
		// Enums.FilesStorageTypes.InInfobase
		// If you can store file versions, binary data is taken from the current version.
		If DataItem.Metadata().Attributes.Find("CurrentVersion") <> Undefined
			AND ValueIsFilled(DataItem.CurrentVersion) Then
			BinaryDataSource = DataItem.CurrentVersion;
		Else
			BinaryDataSource = DataItem.Ref;
		EndIf;
		Try
			// Placing the file data from the infobase to an internal catalog attribute.
			AddressInTempStorage = GetTemporaryStorageURL(BinaryDataSource);
			DataItem.FileStorage = New ValueStorage(GetFromTempStorage(AddressInTempStorage), New Deflation(9));
		Except
			// Probably the file is not found. Do not interrupt data sending.
			WriteLogEvent(EventLogEventForExchange(), EventLogLevel.Error,,, DetailErrorDescription(ErrorInfo()));
			DataItem.FileStorage = New ValueStorage(Undefined);
		EndTry;
		
		DataItem.FileStorageType = Enums.FileStorageTypes.InInfobase;
		DataItem.PathToFile = "";
		DataItem.Volume = Catalogs.FileStorageVolumes.EmptyRef();
		
	EndIf;
	
EndProcedure

Procedure PutFileInCatalogAttribute(DataItem)
	
	Try
		// Placing the file data from a hard drive volume to an internal catalog attribute.
		DataItem.FileStorage = PutBinaryDataInStorage(DataItem.Volume, DataItem.PathToFile, DataItem.Ref.UUID());
	Except
		// Probably the file is not found. Do not interrupt data sending.
		WriteLogEvent(EventLogEventForExchange(), EventLogLevel.Error,,, DetailErrorDescription(ErrorInfo()));
		DataItem.FileStorage = New ValueStorage(Undefined);
	EndTry;
	
	DataItem.FileStorageType = Enums.FileStorageTypes.InInfobase;
	DataItem.PathToFile = "";
	DataItem.Volume = Catalogs.FileStorageVolumes.EmptyRef();
	
EndProcedure

// Returns array of attached files for the specified owner.
//
// Parameters:
//  FilesOwner - a reference to the owner of the attached files.
//
// Returns:
//  Array of references to the attached files.
//
Function AllSubordinateFiles(Val FilesOwner) Export
	
	SetPrivilegedMode(True);
	
	CatalogNames = FileStorageCatalogNames(FilesOwner);
	QueriesText = "";
	
	For each KeyAndValue In CatalogNames Do
		If ValueIsFilled(QueriesText) Then
			QueriesText = QueriesText + "
				|UNION ALL
				|
				|";
		EndIf;
		QueryText =
		"SELECT
		|	AttachedFiles.Ref
		|FROM
		|	&CatalogName AS AttachedFiles
		|WHERE
		|	AttachedFiles.FileOwner = &FilesOwner";
		QueryText = StrReplace(QueryText, "&CatalogName", "Catalog." + KeyAndValue.Key);
		QueriesText = QueriesText + QueryText;
	EndDo;
	
	Query = New Query(QueriesText);
	Query.SetParameter("FilesOwner", FilesOwner);
	
	Return Query.Execute().Unload().UnloadColumn("Ref");
	
EndFunction

// Returns a string constant for generating event log messages.
//
// Returns:
//   Row
//
Function EventLogEventForExchange() 
	
	Return NStr("ru = 'Файлы.Не удалось отправить файл при обмене данными'; en = 'Files.Cannot send file during data exchange'; pl = 'Pliki. Nie można wysłać pliku podczas wymiany danych';de = 'Dateien. Die Datei kann während des Datenaustauschs nicht gesendet werden';ro = 'Fișiere.Nu pot fi trimise în timpul schimbului de date';tr = 'Dosyalar. Veri değişimi sırasında dosya gönderilemiyor'; es_ES = 'Archivos.No se puede enviar el archivo durante el intercambio de datos'", Common.DefaultLanguageCode());
	
EndFunction

// Replaces the binary data of an infobase file with data in a temporary storage.
Procedure UpdateFileBinaryDataAtServer(Val AttachedFile,
	                                           Val FileAddressInBinaryDataTempStorage,
	                                           Val AttributesValues = Undefined)
	
	SetPrivilegedMode(True);
	IsRef = Catalogs.AllRefsType().ContainsType(TypeOf(AttachedFile));
	BeginTransaction();
	Try
		If IsRef Then
			DataLock = New DataLock;
			DataLockItem = DataLock.Add(Metadata.FindByType(TypeOf(AttachedFile)).FullName());
			DataLockItem.SetValue("Ref", AttachedFile);
			DataLock.Lock();
			
			LockDataForEdit(AttachedFile);
			
			FileObject = AttachedFile.GetObject();
			FileRef = AttachedFile;
		Else
			FileObject = AttachedFile;
			FileRef = FileObject.Ref;
		EndIf;
		
		If TypeOf(FileAddressInBinaryDataTempStorage) = Type("BinaryData") Then
			BinaryData = FileAddressInBinaryDataTempStorage;
		Else
			BinaryData = GetFromTempStorage(FileAddressInBinaryDataTempStorage);
		EndIf;
		
		FileObject.Changed = Users.AuthorizedUser();
		
		If TypeOf(AttributesValues) = Type("Structure") Then
			FillPropertyValues(FileObject, AttributesValues);
		EndIf;
		
		IsFileInInfobase = (FileObject.FileStorageType = Enums.FileStorageTypes.InInfobase);
		If IsFileInInfobase Then
			UpdateFileBinaryDataInInfobase(FileObject, FileRef, BinaryData);
		EndIf;
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;
	
	If Not IsFileInInfobase Then
		UpdateFileBinaryDataInVolume(FileObject, FileRef, BinaryData);
	EndIf;
	
EndProcedure

Procedure UpdateFileBinaryDataInInfobase(FileObject, FileRef, BinaryData)
	
	Try
		DataLock = New DataLock;
		DataLockItem = DataLock.Add(Metadata.InformationRegisters.BinaryFilesData.FullName());
		DataLockItem.SetValue("File", FileRef);
		DataLock.Lock();
		
		RecordManager = InformationRegisters.BinaryFilesData.CreateRecordManager();
		RecordManager.File = FileRef;
		RecordManager.Read();
		RecordManager.File = FileRef;
		RecordManager.FileBinaryData = New ValueStorage(BinaryData, New Deflation(9));
		RecordManager.Write();
		
		FileObject.Size = BinaryData.Size();
		FileObject.Write();
	Except
		WriteLogEvent(
		NStr("ru = 'Файлы.Обновление данных присоединенного файла в хранилище файлов'; en = 'Files.Update attached file data in file storage'; pl = 'Pliki. Aktualizowanie danych dołączonego pliku w magazynie plików';de = 'Dateien. Aktualisieren der angehängten Dateidaten im Dateispeicher';ro = 'Fișiere.Actualizarea datelor fișierelor atașate în spațiul de stocare a fișierelor';tr = 'Dosyalar. Ekli dosya verilerinin dosya deposunda güncellenmesi'; es_ES = 'Archivos.Actualizando los datos del archivo adjuntado en el almacenamiento de archivos'",
		Common.DefaultLanguageCode()),
		EventLogLevel.Error,
		,
		,
		DetailErrorDescription(ErrorInfo()));
		Raise;
	EndTry;
	
EndProcedure

Procedure UpdateFileBinaryDataInVolume(FileObject, FileRef, BinaryData)
	
	Try
		
		FullPath = FullVolumePath(FileObject.Volume) + FileObject.PathToFile;
		If Not IsBlankString(FullPath) Then
			
			FileOnHardDrive = New File(FullPath);
			If FileOnHardDrive.Exist() Then
				FileOnHardDrive.SetReadOnly(False);
				DeleteFiles(FullPath);
			EndIf;
			
		EndIf;
		
		FileInfo = AddFileToVolume(BinaryData, FileObject.UniversalModificationDate,
			FileObject.Description, FileObject.Extension,, FileObject.Encrypted);
		FileObject.PathToFile = FileInfo.PathToFile;
		FileObject.Volume = FileInfo.Volume;
		FileObject.Size = BinaryData.Size();
		FileObject.Write();
		
	Except
		ErrorInformation = ErrorInfo();
		WriteLogEvent(
			NStr("ru = 'Файлы.Запись файла на диск'; en = 'Files.Write file to hard drive'; pl = 'Pliki. Zapisywanie pliku na dysku';de = 'Dateien. Datei auf Festplatte schreiben';ro = 'Fișiere.Înregistrarea fișierului pe disc';tr = 'Dosyalar. Dosyanın diske yazılması'; es_ES = 'Archivos.Grabar el archivo en el disco'", Common.DefaultLanguageCode()),
			EventLogLevel.Error,
			Metadata.Catalogs[FileRef.Metadata().Name],
			FileRef,
			ErrorTextWhenSavingFileInVolume(DetailErrorDescription(ErrorInformation), FileRef));
		
		Raise ErrorTextWhenSavingFileInVolume(BriefErrorDescription(ErrorInformation), FileRef);
	EndTry;
	
EndProcedure

// Creates a version of the saved file to save to infobase.
//
// Parameters:
//   FileRef     - CatalogRef.Files - a file, for which a new version is created.
//   FileInfo - Structure - see FilesOperationsClientServer.FIleInfo in the FileWIthVersion mode. 
//
// Returns:
//   CatalogRef.FilesVersions - the created version.
//
Function CreateVersion(FileRef, FileInfo) Export
	
	HasRightsToObject = Common.ObjectAttributesValues(FileRef, "Ref", True);
	If HasRightsToObject = Undefined Then
		Return Undefined;
	EndIf;
	
	SetPrivilegedMode(True);
	
	If Not ValueIsFilled(FileInfo.ModificationTimeUniversal)
		Or FileInfo.ModificationTimeUniversal > CurrentUniversalDate() Then
		
		FileInfo.ModificationTimeUniversal = CurrentUniversalDate();
	EndIf;
	
	If Not ValueIsFilled(FileInfo.Modified)
		Or ToUniversalTime(FileInfo.Modified) > FileInfo.ModificationTimeUniversal Then
		
		FileInfo.Modified = CurrentSessionDate();
	EndIf;
	
	CheckExtentionOfFileToDownload(FileInfo.ExtensionWithoutPoint);
	
	Version = Catalogs.FilesVersions.CreateItem();
	
	If FileInfo.NewVersionVersionNumber = Undefined Then
		Version.VersionNumber = FindMaxVersionNumber(FileRef) + 1;
	Else
		Version.VersionNumber = FileInfo.NewVersionVersionNumber;
	EndIf;
	
	Version.Owner = FileRef;
	Version.UniversalModificationDate = FileInfo.ModificationTimeUniversal;
	Version.FileModificationDate = FileInfo.Modified;
	
	Version.Comment = FileInfo.NewVersionComment;
	
	If FileInfo.NewVersionAuthor = Undefined Then
		Version.Author = Users.AuthorizedUser();
	Else
		Version.Author = FileInfo.NewVersionAuthor;
	EndIf;
	
	If FileInfo.NewVersionCreationDate = Undefined Then
		Version.CreationDate = CurrentSessionDate();
	Else
		Version.CreationDate = FileInfo.NewVersionCreationDate;
	EndIf;
	
	Version.FullDescr = FileInfo.BaseName;
	Version.Size = FileInfo.Size;
	Version.Extension = CommonClientServer.ExtensionWithoutPoint(FileInfo.ExtensionWithoutPoint);
	
	FilesStorageTyoe = FilesStorageTyoe();
	Version.FileStorageType = FilesStorageTyoe;

	If FileInfo.RefToVersionSource <> Undefined Then // Creating file from template
		
		TemplateFilesStorageType = FileInfo.RefToVersionSource.FileStorageType;
		
		If TemplateFilesStorageType = Enums.FileStorageTypes.InInfobase AND FilesStorageTyoe = Enums.FileStorageTypes.InInfobase Then
			// Both template and the new File are in the base.
			// When creating a File from a template, the value storage is copied directly.
			BinaryData = FileInfo.TempFileStorageAddress.Get();
			
		ElsIf TemplateFilesStorageType = Enums.FileStorageTypes.InVolumesOnHardDrive AND FilesStorageTyoe = Enums.FileStorageTypes.InVolumesOnHardDrive Then
			//  If both template and the new File are on the hard drive, just copying the file.
			
			If Not FileInfo.RefToVersionSource.Volume.IsEmpty() Then
				FullTemplateFilePath = FullVolumePath(FileInfo.RefToVersionSource.Volume) 
					+ FileInfo.RefToVersionSource.PathToFile; 
				
				Info = AddFileToVolume(FullTemplateFilePath, FileInfo.ModificationTimeUniversal,
					FileInfo.BaseName, FileInfo.ExtensionWithoutPoint, Version.VersionNumber, FileInfo.Encrypted);
				Version.Volume = Info.Volume;
				Version.PathToFile = Info.PathToFile;
			EndIf;
			
		ElsIf TemplateFilesStorageType = Enums.FileStorageTypes.InInfobase AND FilesStorageTyoe = Enums.FileStorageTypes.InVolumesOnHardDrive Then
			// Template is in the base and the new FIle is on the hard drive.
			// In this case, the FileTempStorageAddress contains the ValueStorage with the file.
			Info = AddFileToVolume(FileInfo.TempFileStorageAddress.Get(),
				FileInfo.ModificationTimeUniversal, FileInfo.BaseName, FileInfo.ExtensionWithoutPoint,
				Version.VersionNumber, FileInfo.Encrypted);
			Version.Volume = Info.Volume;
			Version.PathToFile = Info.PathToFile;
			
		ElsIf TemplateFilesStorageType = Enums.FileStorageTypes.InVolumesOnHardDrive AND FilesStorageTyoe = Enums.FileStorageTypes.InInfobase Then
			// Template is on the hard drive, and the new File is in the base.
			If Not FileInfo.RefToVersionSource.Volume.IsEmpty() Then
				FullTemplateFilePath = FullVolumePath(FileInfo.RefToVersionSource.Volume) + FileInfo.RefToVersionSource.PathToFile; 
				BinaryData = New BinaryData(FullTemplateFilePath);
			EndIf;
			
		EndIf;
	Else // Creating the FIle object based on the selected file from the hard drive.
		
		BinaryData = GetFromTempStorage(FileInfo.TempFileStorageAddress);
		
		If Version.Size = 0 Then
			Version.Size = BinaryData.Size();
			CheckFileSizeForImport(Version);
		EndIf;
		
		If FilesStorageTyoe = Enums.FileStorageTypes.InVolumesOnHardDrive Then
			
			Info = AddFileToVolume(BinaryData,
				FileInfo.ModificationTimeUniversal, FileInfo.BaseName, FileInfo.ExtensionWithoutPoint,
				Version.VersionNumber); 
			Version.Volume = Info.Volume;
			Version.PathToFile = Info.PathToFile;
			
		EndIf;
		
	EndIf;
	
	Version.TextExtractionStatus = Enums.FileTextExtractionStatuses.NotExtracted;
	FullTextSearchUsing = Metadata.ObjectProperties.FullTextSearchUsing.Use;
	If Metadata.Catalogs.FilesVersions.FullTextSearch = FullTextSearchUsing Then
		If TypeOf(FileInfo.TempTextStorageAddress) = Type("ValueStorage") Then
			// When creating a File from a template, the value storage is copied directly.
			Version.TextStorage = FileInfo.TempTextStorageAddress;
			Version.TextExtractionStatus = Enums.FileTextExtractionStatuses.Extracted;
		ElsIf Not IsBlankString(FileInfo.TempTextStorageAddress) Then
			TextExtractionResult = ExtractText(FileInfo.TempTextStorageAddress);
			Version.TextStorage = TextExtractionResult.TextStorage;
			Version.TextExtractionStatus = TextExtractionResult.TextExtractionStatus;
		EndIf;
	EndIf;

	Version.Fill(Undefined);
	Version.Write();
	
	If FilesStorageTyoe = Enums.FileStorageTypes.InInfobase Then
		WriteFileToInfobase(Version.Ref, BinaryData);
	EndIf;
	
	Return Version.Ref;
	
EndFunction

// It will rename file on the hard drive for the FilesVersions catalog if FileStorageType = InVolumesOnHardDrive.
Procedure RenameVersionFileOnHardDrive(Version, OldDescription, NewDescription, 
	UUID = Undefined) Export
	
	If Version.Volume.IsEmpty() Then
		Return;
	EndIf;	
	
	BeginTransaction();
	Try
		
		DataLock = New DataLock;
		DataLockItem = DataLock.Add(Metadata.FindByType(TypeOf(Version)).FullName());
		DataLockItem.SetValue("Ref", Version);
		DataLock.Lock();
		
		VersionObject = Version.GetObject();
		LockDataForEdit(Version, , UUID);
		
		OldFullPath = FullVolumePath(Version.Volume) + Version.PathToFile; 
		
		FileOnHardDrive = New File(OldFullPath);
		FullPath = FileOnHardDrive.Path;
		NameWithoutExtension = FileOnHardDrive.BaseName;
		Extension = FileOnHardDrive.Extension;
		NewBaseName = StrReplace(NameWithoutExtension, OldDescription, NewDescription);
		
		NewFullPath = FullPath + NewBaseName + Extension;
		FullVolumePath = FullVolumePath(Version.Volume);
		NewPartialPath = Right(NewFullPath, StrLen(NewFullPath) - StrLen(FullVolumePath));
	
		MoveFile(OldFullPath, NewFullPath);
		VersionObject.PathToFile = NewPartialPath;
		VersionObject.Write();
		UnlockDataForEdit(Version, UUID);
		CommitTransaction();
	Except
		RollbackTransaction();
		UnlockDataForEdit(Version, UUID);
		Raise;
	EndTry;
	
EndProcedure

// Updates file properties without considering versions, which are binary data, text, modification 
// date, and also other optional properties.
//
Procedure RefreshFile(FileInfo, AttachedFile) Export
	
	CommonClientServer.CheckParameter("FilesOperations.FileBinaryData", "AttachedFile", 
		AttachedFile, Metadata.DefinedTypes.AttachedFile.Type);
	
	AttributesValues = New Structure;
	
	If FileInfo.Property("BaseName") AND ValueIsFilled(FileInfo.BaseName) Then
		AttributesValues.Insert("Description", FileInfo.BaseName);
	EndIf;
	
	If NOT FileInfo.Property("UniversalModificationDate")
		OR NOT ValueIsFilled(FileInfo.UniversalModificationDate)
		OR FileInfo.UniversalModificationDate > CurrentUniversalDate() Then
		
		// Filling current date in the universal time format.
		AttributesValues.Insert("UniversalModificationDate", CurrentUniversalDate());
	Else
		AttributesValues.Insert("UniversalModificationDate", FileInfo.UniversalModificationDate);
	EndIf;
	
	If FileInfo.Property("BeingEditedBy") Then
		AttributesValues.Insert("BeingEditedBy", FileInfo.BeingEditedBy);
	EndIf;
	
	If FileInfo.Property("Extension") Then
		AttributesValues.Insert("Extension", FileInfo.Extension);
	EndIf;
	
	If FileInfo.Property("Encoding")
		AND Not IsBlankString(FileInfo.Encoding) Then
		
		FilesOperationsInternalServerCall.WriteFileVersionEncoding(AttachedFile, FileInfo.Encoding);
		
	EndIf;
	
	BinaryData = GetFromTempStorage(FileInfo.FileAddressInTempStorage);
	
	FileMetadata = Metadata.FindByType(TypeOf(AttachedFile));
	FullTextSearchUsing = Metadata.ObjectProperties.FullTextSearchUsing.Use;
	If FileMetadata.FullTextSearch = FullTextSearchUsing Then
		TextExtractionResult = ExtractText(FileInfo.TempTextStorageAddress, BinaryData,
			AttachedFile.Extension);
		AttributesValues.Insert("TextExtractionStatus", TextExtractionResult.TextExtractionStatus);
		AttributesValues.Insert("TextStorage", TextExtractionResult.TextStorage);
	Else
		AttributesValues.Insert("TextExtractionStatus", Enums.FileTextExtractionStatuses.NotExtracted);
		AttributesValues.Insert("TextStorage", New ValueStorage(""));
	EndIf;
	
	UpdateFileBinaryDataAtServer(AttachedFile, BinaryData, AttributesValues);
	
EndProcedure

// Updates or creates a File version and returns a reference to the updated version (or False if the 
// file is not modified binary).
//
// Parameters:
//   FileRef     - CatalogRef.Files        - a file, for which a new version is created.
//   FileInfo - Structure                     - see FilesOperationsClientServer.FIleInfo in the 
//                                                    "FileWithVersion".
//   VersionRef   - CatalogRef.FilesVersions - a file version that needs to be updated.
//   UUIDOfForm                   - UUID - the UUID of the form that provides operation context.
//                                                    
//
// Returns:
//   CatalogRef.FilesVersions - created or modified version; it is Undefined if the file was not changed binary.
//
Function UpdateFileVersion(FileRef,
	FileInfo,
	VersionRef = Undefined,
	UUIDOfForm = Undefined,
	User = Undefined) Export
	
	HasSaveRight = AccessRight("SaveUserData", Metadata);
	HasRightsToObject = Common.ObjectAttributesValues(FileRef, "Ref", True);
	If HasRightsToObject = Undefined Then
		Return Undefined;
	EndIf;
	
	SetPrivilegedMode(True);
	
	ModificationTimeUniversal = FileInfo.ModificationTimeUniversal;
	If NOT ValueIsFilled(ModificationTimeUniversal)
		OR ModificationTimeUniversal > CurrentUniversalDate() Then
		ModificationTimeUniversal = CurrentUniversalDate();
	EndIf;
	
	ChangeTime = FileInfo.Modified;
	If NOT ValueIsFilled(ChangeTime)
		OR ToUniversalTime(ChangeTime) > ModificationTimeUniversal Then
		ChangeTime = CurrentSessionDate();
	EndIf;
	
	CheckExtentionOfFileToDownload(FileInfo.ExtensionWithoutPoint);
	
	CurrentVersionSize = 0;
	BinaryData = Undefined;
	CurrentVersionFileStorageType = Enums.FileStorageTypes.InInfobase;
	CurrentVersionVolume = Undefined;
	CurrentVersionFilePath = Undefined;
	ObjectMetadata = Metadata.FindByType(TypeOf(FileRef));
	AbilityToStoreVersions = Common.HasObjectAttribute("CurrentVersion", ObjectMetadata);
	FullTextSearchUsing = Metadata.ObjectProperties.FullTextSearchUsing.Use;
	
	VersionRefToCompareSize = VersionRef;
	If VersionRef <> Undefined Then
		VersionRefToCompareSize = VersionRef;
	ElsIf AbilityToStoreVersions AND ValueIsFilled(FileRef.CurrentVersion)Then
		VersionRefToCompareSize = FileRef.CurrentVersion;
	Else
		VersionRefToCompareSize = FileRef;
	EndIf;
	
	PreVersionEncoding = GetFileVersionEncoding(VersionRefToCompareSize);
	
	AttributesStructure = Common.ObjectAttributesValues(VersionRefToCompareSize, 
		"Size, FileStorageType, Volume, PathToFile");
	CurrentVersionSize = AttributesStructure.Size;
	CurrentVersionFileStorageType = AttributesStructure.FileStorageType;
	CurrentVersionVolume = AttributesStructure.Volume;
	CurrentVersionFilePath = AttributesStructure.PathToFile;
	
	FileStorage = Undefined;
	If FileInfo.Size = CurrentVersionSize Then
		PreviousVersionBinaryData = Undefined;
		
		If CurrentVersionFileStorageType = Enums.FileStorageTypes.InVolumesOnHardDrive Then
			If NOT CurrentVersionVolume.IsEmpty() Then
				FullPath = FullVolumePath(CurrentVersionVolume) + CurrentVersionFilePath; 
				PreviousVersionBinaryData = New BinaryData(FullPath);
			EndIf;
		Else
			FileStorage = FilesOperations.FileFromInfobaseStorage(VersionRefToCompareSize);
			PreviousVersionBinaryData = FileStorage.Get();
		EndIf;
		
		BinaryData = GetFromTempStorage(FileInfo.TempFileStorageAddress);
		
		If PreviousVersionBinaryData = BinaryData Then
			Return Undefined; // If the file is not changed binary, returning False.
		EndIf;
	EndIf;
	
	VersionLocked = False;
	Version = Undefined;
	
	If FileInfo.StoreVersions Then
		ErrorTitle = NStr("ru = 'Ошибка при записи новой версии присоединенных файлов.'; en = 'An error occurred when writing a new version of the attached files.'; pl = 'Błąd przy zapisie nowej wersji dołączonych plików.';de = 'Fehler beim Schreiben einer neuen Version von angehängten Dateien.';ro = 'Eroare la înregistrarea versiunii noi a fișierelor atașate.';tr = 'Eklenen dosyaların yeni sürümü kaydedilirken hata oluştu.'; es_ES = 'Error al guardar la nueva versión de los archivos adjuntos.'");
		ErrorEnd = NStr("ru = 'В этом случае запись версии файла невозможна.'; en = 'Cannot write the file version.'; pl = 'W tym przypadku zapis wersji pliku nie jest możliwy.';de = 'In diesem Fall kann die Dateiversion nicht aufgezeichnet werden.';ro = 'În acest caz fișierul nu poate fi înregistrat.';tr = 'Bu durumda dosya kaydedilemez.'; es_ES = 'En este caso es imposible guardar la versión del archivo.'");

		FileVersionsStorageCatalogName = FilesVersionsStorageCatalogName(
			TypeOf(FileRef.FileOwner), "", ErrorTitle, ErrorEnd);
			
		Version = Catalogs[FileVersionsStorageCatalogName].CreateItem();
		Version.ParentVersion = FileRef.CurrentVersion;
		Version.VersionNumber = FindMaxVersionNumber(FileRef) + 1;
	Else
		
		If VersionRef = Undefined Then
			Version = FileRef.CurrentVersion.GetObject();
		Else
			Version = VersionRef.GetObject();
		EndIf;
	
		LockDataForEdit(Version.Ref, , UUIDOfForm);
		VersionLocked = True;
		
		// Deleting file from the hard drive and replacing it with the new one.
		If Version.FileStorageType = Enums.FileStorageTypes.InVolumesOnHardDrive Then
			If NOT Version.Volume.IsEmpty() Then
				FullPath = FullVolumePath(Version.Volume) + Version.PathToFile; 
				FileOnHardDrive = New File(FullPath);
				If FileOnHardDrive.Exist() Then
					FileOnHardDrive.SetReadOnly(False);
					DeleteFiles(FullPath);
				EndIf;
				PathWithSubdirectory = FileOnHardDrive.Path;
				FilesArrayInDirectory = FindFiles(PathWithSubdirectory, GetAllFilesMask());
				If FilesArrayInDirectory.Count() = 0 Then
					DeleteFiles(PathWithSubdirectory);
				EndIf;
			EndIf;
		EndIf;
		
	EndIf;
	
	Version.Owner = FileRef;
	If User = Undefined Then
		Version.Author = Users.AuthorizedUser();
	Else
		Version.Author = User;
	EndIf;
	Version.UniversalModificationDate = ModificationTimeUniversal;
	Version.FileModificationDate = ChangeTime;
	Version.CreationDate = CurrentSessionDate();
	Version.Size = FileInfo.Size;
	Version.FullDescr = FileInfo.BaseName;
	Version.Description = FileInfo.BaseName;
	Version.Comment = FileInfo.Comment;
	Version.Extension = CommonClientServer.ExtensionWithoutPoint(FileInfo.ExtensionWithoutPoint);
	
	FilesStorageTyoe = FilesStorageTyoe();
	Version.FileStorageType = FilesStorageTyoe;
	
	If BinaryData = Undefined Then
		BinaryData = GetFromTempStorage(FileInfo.TempFileStorageAddress);
	EndIf;
	
	If Version.Size = 0 Then
		Version.Size = BinaryData.Size();
		CheckFileSizeForImport(Version);
	EndIf;
		
	If FilesStorageTyoe = Enums.FileStorageTypes.InInfobase Then
		
		// clearing fields
		Version.PathToFile = "";
		Version.Volume = Catalogs.FileStorageVolumes.EmptyRef();
	Else // hard drive storage
		
		FileEncrypted = False;
		If FileInfo.Encrypted <> Undefined Then
			FileEncrypted = FileInfo.Encrypted;
		EndIf;
		
		Info = AddFileToVolume(BinaryData,
			ModificationTimeUniversal, FileInfo.BaseName, Version.Extension,
			Version.VersionNumber, FileEncrypted); 
		Version.Volume        = Info.Volume;
		Version.PathToFile = Info.PathToFile;
		
	EndIf;
	
	If ObjectMetadata.FullTextSearch = FullTextSearchUsing Then
		TextExtractionResult = ExtractText(FileInfo.TempTextStorageAddress);
		Version.TextStorage = TextExtractionResult.TextStorage;
		Version.TextExtractionStatus = TextExtractionResult.TextExtractionStatus;
		If FileInfo.NewTextExtractionStatus <> Undefined Then
			Version.TextExtractionStatus = FileInfo.NewTextExtractionStatus;
		EndIf;
	Else
		Version.TextStorage = New ValueStorage("");
		Version.TextExtractionStatus = Enums.FileTextExtractionStatuses.NotExtracted;
	EndIf;
	
	Version.Fill(Undefined);
	Version.Write();
	
	If FilesStorageTyoe = Enums.FileStorageTypes.InInfobase Then
		WriteFileToInfobase(Version.Ref, BinaryData);
	EndIf;
	
	If VersionLocked Then
		UnlockDataForEdit(Version.Ref, UUIDOfForm);
	EndIf;
	
	FilesOperationsInternalServerCall.WriteFileVersionEncoding(Version.Ref, PreVersionEncoding);

	If HasSaveRight Then
		FileURL = GetURL(FileRef);
		UserWorkHistory.Add(FileURL);
	EndIf;
	
	Return Version.Ref;
	
EndFunction

// Substitutes the reference to the version in the File card.
//
// Parameters:
//   FileRef - CatalogRef.Files - a file, in which a version is created.
//   Version  - CatalogRef.FilesVersions - a file version.
//   TextTempStorageAddress - String - contains the address in the temporary storage, where the 
//                                           binary data with the text file, or the ValueStorage 
//                                           that directly contains the binary data with the text file are located.
//  UUID - a form UUID.
//
Procedure UpdateVersionInFile(FileRef,
								Version,
								Val TempTextStorageAddress,
								UUID = Undefined) Export
	
	FullTextSearchUsing = Metadata.ObjectProperties.FullTextSearchUsing.Use;
	
	BeginTransaction();
	Try
		
		CatalogMetadata = Metadata.FindByType(TypeOf(FileRef));
		
		DataLock = New DataLock;
		DataLockItem = DataLock.Add(CatalogMetadata.FullName());
		DataLockItem.SetValue("Ref", FileRef);
		DataLock.Lock();
		
		FileObject = FileRef.GetObject();
		
		LockDataForEdit(FileObject.Ref, , UUID);
		
		FileObject.CurrentVersion = Version.Ref;
		If CatalogMetadata.FullTextSearch = FullTextSearchUsing Then
			If TypeOf(TempTextStorageAddress) = Type("ValueStorage") Then
				// When creating a File from a template, the value storage is copied directly.
				FileObject.TextStorage = TempTextStorageAddress;
			Else
				TextExtractionResult = ExtractText(TempTextStorageAddress);
				FileObject.TextStorage = TextExtractionResult.TextStorage;
				FileObject.TextExtractionStatus = TextExtractionResult.TextExtractionStatus;
			EndIf;
		Else
			FileObject.TextExtractionStatus = Enums.FileTextExtractionStatuses.NotExtracted;
			FileObject.TextStorage = New ValueStorage("");
		EndIf;
		
		FileObject.Write();
		UnlockDataForEdit(FileObject.Ref, UUID);
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;
	
EndProcedure

// Finds the maximum version number for this File object. If there is no versions, then 0.
// Parameters:
//  FileRef  - CatalogRef.Files - a reference to the file.
//
// Returns:
//   Number  - max version number.
//
Function FindMaxVersionNumber(FileRef)
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	ISNULL(MAX(Versions.VersionNumber), 0) AS MaxNumber
	|FROM
	|	Catalog.FilesVersions AS Versions
	|WHERE
	|	Versions.Owner = &File";
	
	Query.Parameters.Insert("File", FileRef);
		
	Selection = Query.Execute().Select();
	If Selection.Next() Then
		
		If Selection.MaxNumber = Null Then
			Return 0;
		EndIf;
		
		Return Number(Selection.MaxNumber);
	EndIf;
	
	Return 0;
EndFunction

// Returns error message text containing a reference to the item of a file storage catalog.
// 
//
Function ErrorTextWhenSavingFileInVolume(Val ErrorMessage, Val File)
	
	Return StringFunctionsClientServer.SubstituteParametersToString(
		NStr("ru = 'Ошибка, при сохранении файла в томе:
		           |""%1"".
		           |
		           |Ссылка на файл: ""%2"".'; 
		           |en = 'Cannot save file to volume:
		           |""%1""
		           |
		           |Reference to file: ""%2"".'; 
		           |pl = 'Błąd podczas zapisywania pliku w woluminie:
		           |""%1"".
		           |
		           |Link do pliku: ""%2"".';
		           |de = 'Fehler beim Speichern einer Datei im Volume:
		           |""%1"".
		           |
		           |Dateiverweis: ""%2"".';
		           |ro = 'Eroare la salvarea fișierului în volum:
		           |""%1"".
		           |
		           |Referința la fișier: ""%2"".';
		           |tr = 'Dosya birimde 
		           | kaydedilirken bir hata oluştu: ""%1"". 
		           |
		           | Referans dosyası: ""%2""'; 
		           |es_ES = 'Error al guardar el archivo en el tomo:
		           |""%1"".
		           |
		           |Enlace al archivo: ""%2"".'"),
		ErrorMessage,
		GetURL(File) );
	
EndFunction

// Raises an exception if file has an invalid size for import.
Procedure CheckFileSizeForImport(File) Export
	
	CommonSettings = FilesOperationsInternalCached.FilesOperationSettings().CommonSettings;
	
	If TypeOf(File) = Type("File") Then
		Size = File.Size();
	Else
		Size = File.Size;
	EndIf;
	
	If Size > CommonSettings.MaxFileSize Then
	
		SizeInMB     = Size / (1024 * 1024);
		SizeInMBMax = CommonSettings.MaxFileSize / (1024 * 1024);
		
		If TypeOf(File) = Type("File") Then
			Name = File.Name;
		Else
			Name = CommonClientServer.GetNameWithExtension(
				File.FullDescr, File.Extension);
		EndIf;
		
		Raise StringFunctionsClientServer.SubstituteParametersToString(
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
			Name,
			FilesOperationsInternalClientServer.GetStringWithFileSize(SizeInMB),
			FilesOperationsInternalClientServer.GetStringWithFileSize(SizeInMBMax));
	EndIf;
	
EndProcedure

/////////////////////////////////////////////////////////////////////////////////////
// Event handlers of a file item form.

Procedure ItemFormOnCreateAtServer(Context, Cancel, StandardProcessing, Parameters, ReadOnly, CustomizeFormObject = False) Export
	
	Items = Context.Items;
	
	ColumnsArray = New Array;
	For Each ColumnDetails In Context.FormAttributeToValue("DigitalSignatures").Columns Do
		ColumnsArray.Add(ColumnDetails.Name);
	EndDo;
	
	If ValueIsFilled(Parameters.CopyingValue) Then
		InfobaseUpdate.CheckObjectProcessed(Parameters.CopyingValue);
		If Parameters.CreateMode = "FromTemplate" Then
			ObjectValue = FillFileDataByTemplate(Context, ObjectValue, Parameters, CustomizeFormObject)
		Else
			ObjectValue = FillFileDataFromCopy(Context, ObjectValue, Parameters, CustomizeFormObject);
		EndIf;
	Else
		If ValueIsFilled(Parameters.AttachedFile) Then
			ObjectValue = Parameters.AttachedFile.GetObject();
		Else
			ObjectValue = Parameters.Key.GetObject();
		EndIf;
		InfobaseUpdate.CheckObjectProcessed(ObjectValue, Context);
	EndIf;
	ObjectValue.Fill(Undefined);
	
	Context.CatalogName = ObjectValue.Metadata().Name;
	
	ErrorTitle = NStr("ru = 'Ошибка при настройке формы элемента присоединенных файлов.'; en = 'An error occurred when configuring the item form of attached files.'; pl = 'Błąd podczas konfiguracji formularzu elementu dołączonych plików.';de = 'Fehler beim Einrichten des Formulars des angehängten Dateielements.';ro = 'Eroare la setarea formei elementului fișierelor atașate.';tr = 'Ekli dosyaların unsur biçimi yapılandırırken bir hata oluştu.'; es_ES = 'Error al ajustar el formulario del elemento de los archivos adjuntos.'");
	ErrorEnd = NStr("ru = 'В этом случае настройка формы элемента невозможна.'; en = 'Cannot configure the item form.'; pl = 'W tym przypadku konfiguracja formularzu elementu nie jest możliwe.';de = 'In diesem Fall ist die Einstellung der Elementform nicht möglich.';ro = 'În acest caz, configurarea formei elementului este imposibilă.';tr = 'Bu durumda, unsur biçimi yapılandırılamaz.'; es_ES = 'En este caso es imposible ajustar el formulario del elemento.'");
	
	CanCreateFileVersions = TypeOf(ObjectValue.Ref) = Type("CatalogRef.Files");
	Context.CanCreateFileVersions = CanCreateFileVersions; 
	
	If CustomizeFormObject Then
		Items.StoreVersions0.Visible = CanCreateFileVersions;
		SetUpFormObject(ObjectValue, Context);
	Else
		ValueToFormData(ObjectValue, Context.Object);
		Items.StoreVersions.Visible = CanCreateFileVersions;
	EndIf;
	
	CryptographyOnCreateFormAtServer(Context, False);
	FillSignatureList(Context, Parameters.CopyingValue);
	FillEncryptionList(Context, Parameters.CopyingValue);
	
	CommonSettings = FilesOperationsInternalCached.FilesOperationSettings().CommonSettings;
	
	FileExtensionInList = FilesOperationsInternalClientServer.FileExtensionInList(
		CommonSettings.TestFilesExtensionsList, Context.Object.Extension);
	
	If FileExtensionInList Then
		If CanCreateFileVersions AND Context.Object.Property("CurrentVersion") AND ValueIsFilled(Context.Object.CurrentVersion) Then
			CurrentFileVersion = Context.Object.CurrentVersion;
		Else
			CurrentFileVersion = Context.Object.Ref;
		EndIf;
		If ValueIsFilled(CurrentFileVersion) Then
			
			EncodingValue = GetFileVersionEncoding(CurrentFileVersion);
			
			EncodingsList = Encodings();
			ListItem = EncodingsList.FindByValue(EncodingValue);
			If ListItem = Undefined Then
				Context.Encoding = EncodingValue;
			Else
				Context.Encoding = ListItem.Presentation;
			EndIf;
			
		EndIf;
		
		If Not ValueIsFilled(Context.Encoding) Then
			Context.Encoding = NStr("ru = 'По умолчанию'; en = 'Default'; pl = 'Domyślny';de = 'Standard';ro = 'Implicit';tr = 'Varsayılan'; es_ES = 'Por defecto'");
		EndIf;
		
	Else
		Context.Items.Encoding.Visible = False;
	EndIf;
	
	IsInternalFile = False;
	If HasInternalAttribute(Context.CatalogName) Then
		IsInternalFile = ObjectValue.Internal;
	EndIf;
	
	If IsInternalFile Then
		Context.ReadOnly = True;
	EndIf;
	
	Items.FormClose.Visible = IsInternalFile;
	Items.FormClose.DefaultButton = IsInternalFile;
	Items.ServiceFileNoteDecoration.Visible = IsInternalFile;
	
	If TypeOf(Context.CurrentUser) = Type("CatalogRef.ExternalUsers") Then
		ChangeFormForExternalUser(Context);
	EndIf;
	
	If GetFunctionalOption("UseFileSync") Then
		Context.FileToEditInCloud = FileToEditInCloud(Context.Object.Ref);
	EndIf;
	
	If ReadOnly
		OR NOT AccessRight("Update", Context.Object.Ref.Metadata()) Then
		SetChangeButtonsInvisible(Context.Items);
	EndIf;
	
	If NOT ReadOnly
		AND NOT Context.Object.Ref.IsEmpty() AND CustomizeFormObject Then
		LockDataForEdit(Context.Object.Ref, , Context.UUID);
	EndIf;
	
	OwnerType = TypeOf(ObjectValue.FileOwner);
	Context.Items.FileOwner.Title = OwnerType;
	
EndProcedure

Function FillFileDataByTemplate(Context, ObjectValue, Parameters, CustomizeFormObject)
	
	ObjectToCopy             = Parameters.CopyingValue.GetObject();
	Context.CopyingValue = Parameters.CopyingValue;
	
	ObjectValue = Catalogs[Parameters.FilesStorageCatalogName].CreateItem();
	
	FillPropertyValues(
		ObjectValue,
		ObjectToCopy,
		"Description,
		|Encrypted,
		|Details,
		|SignedWithDS,
		|Size,
		|Extension,
		|FileOwner,
		|TextStorage,
		|DeletionMark");
		
	ObjectValue.FileOwner                = Parameters.FileOwner;
	CreationDate                                = CurrentSessionDate();
	ObjectValue.CreationDate                 = CreationDate;
	ObjectValue.UniversalModificationDate = ToUniversalTime(CreationDate);
	ObjectValue.Author                        = Users.AuthorizedUser();
	ObjectValue.FileStorageType             = FilesStorageTyoe();
	ObjectValue.StoreVersions                = ?(Parameters.FilesStorageCatalogName = "Files",
		ObjectToCopy.StoreVersions, False);
	
	Return ObjectValue;
	
EndFunction

Function FillFileDataFromCopy(Context, ObjectValue, Parameters, CustomizeFormObject)

	ObjectToCopy = Parameters.CopyingValue.GetObject();
	Context.CopyingValue = Parameters.CopyingValue;
	
	MetadataObject = ObjectToCopy.Metadata();
	ObjectValue = Catalogs[MetadataObject.Name].CreateItem();
	
	AttributesToExclude = "Parent,Owner,LoanDate,Changed,Code,DeletionMark,BeingEditedBy,Volume,PredefinedDataName,Predefined,PathToFile,TextExtractionStatus";
	If MetadataObject.Attributes.Find("CurrentVersion") <> Undefined Then
		AttributesToExclude = AttributesToExclude + ",CurrentVersion";
	EndIf;
	
	FillPropertyValues(ObjectValue,ObjectToCopy, , AttributesToExclude);
	ObjectValue.Author            = Users.AuthorizedUser();
	ObjectValue.FileStorageType = FilesStorageTyoe();
	
	Return ObjectValue;
	
EndFunction

Procedure SetUpFormObject(Val NewObject, Context)
	
	NewObjectType = New Array;
	NewObjectType.Add(TypeOf(NewObject));
	NewAttribute = New FormAttribute("Object", New TypeDescription(NewObjectType));
	NewAttribute.StoredData = True;
	
	AttributesToAdd = New Array;
	AttributesToAdd.Add(NewAttribute);
	
	Context.ChangeAttributes(AttributesToAdd);
	Context.ValueToFormAttribute(NewObject, "Object");
	For each Item In Context.Items Do
		If TypeOf(Item) = Type("FormField")
			AND StrStartsWith(Item.DataPath, "PrototypeObject[0].")
			AND StrEndsWith(Item.Name, "0") Then
			
			ItemName = Left(Item.Name, StrLen(Item.Name) -1);
			
			If Context.Items.Find(ItemName) <> Undefined  Then
				Continue;
			EndIf;
			
			NewItem = Context.Items.Insert(ItemName, TypeOf(Item), Item.Parent, Item);
			NewItem.DataPath = "Object." + Mid(Item.DataPath, StrLen("PrototypeObject[0].") + 1);
			
			If Item.Type = FormFieldType.CheckBoxField Or Item.Type = FormFieldType.PictureField Then
				PropertiesToExclude = "Name, DataPath";
			Else
				PropertiesToExclude = "Name, DataPath, SelectedText, TypeLink";
			EndIf;
			FillPropertyValues(NewItem, Item, , PropertiesToExclude);
			Item.Visible = False;
		EndIf;
	EndDo;
	
	If Not NewObject.IsNew() Then
		Context.URL = GetURL(NewObject);
	EndIf;
	
EndProcedure

Procedure FillEncryptionList(Context, Val Source = Undefined) Export
	If Not ValueIsFilled(Source) Then
		Source = Context.Object;
	EndIf;
	
	Context.EncryptionCertificates.Clear();
	
	If Source.Encrypted Then
		
		If Common.SubsystemExists("StandardSubsystems.DigitalSignature") Then
			ModuleDigitalSignature = Common.CommonModule("DigitalSignature");
			EncryptionCertificates = ModuleDigitalSignature.EncryptionCertificates(Source.Ref);
			
			For Each EncryptionCertificate In EncryptionCertificates Do
				
				NewRow = Context.EncryptionCertificates.Add();
				NewRow.Presentation = EncryptionCertificate.Presentation;
				NewRow.Thumbprint = EncryptionCertificate.Thumbprint;
				NewRow.SequenceNumber = EncryptionCertificate.SequenceNumber;
				
				CertificateBinaryData = EncryptionCertificate.Certificate;
				If CertificateBinaryData <> Undefined Then
					
					NewRow.CertificateAddress = PutToTempStorage(
						CertificateBinaryData, Context.UUID);
				EndIf;
			EndDo;
		EndIf;
		
	EndIf;
	
	TitleText = NStr("ru = 'Разрешено расшифровывать'; en = 'Decryption allowed'; pl = 'Rozszyfrowywanie dozwolone';de = 'Entschlüsselung ist erlaubt';ro = 'Decriptarea este permisă';tr = 'Şifre çözme izni verildi'; es_ES = 'Descodificación permitida'");
	
	If Context.EncryptionCertificates.Count() <> 0 Then
		TitleText =TitleText + " (" + Format(Context.EncryptionCertificates.Count(), "NG=") + ")";
	EndIf;
	
	Context.Items.EncryptionCertificatesGroup.Title = TitleText;
	
EndProcedure

Procedure FillSignatureList(Context, Val Source = Undefined) Export
	If Not ValueIsFilled(Source) Then
		Source = Context.Object;
	EndIf;
	
	Context.DigitalSignatures.Clear();
	
	DigitalSignatures = DigitalSignaturesList(Source, Context.UUID);
	
	For Each FileDigitalSignature In DigitalSignatures Do
		
		NewRow = Context.DigitalSignatures.Add();
		FillPropertyValues(NewRow, FileDigitalSignature);
		
		FilesOperationsInternalClientServer.FillSignatureStatus(NewRow);
		
		CertificateBinaryData = FileDigitalSignature.Certificate.Get();
		If CertificateBinaryData <> Undefined Then 
			NewRow.CertificateAddress = PutToTempStorage(
				CertificateBinaryData, Context.UUID);
		EndIf;
		
	EndDo;
	
	TitleText = NStr("ru = 'Электронные подписи'; en = 'Digital signatures'; pl = 'Podpisy cyfrowe';de = 'Digitale Signaturen';ro = 'Semnături electronice';tr = 'Dijital imzalar'; es_ES = 'Firmas digitales'");
	
	If Context.DigitalSignatures.Count() <> 0 Then
		TitleText = TitleText + " (" + String(Context.DigitalSignatures.Count()) + ")";
	EndIf;
	
	Context.Items.DigitalSignaturesGroup.Title = TitleText;
	
EndProcedure

Function DigitalSignaturesList(Source, UUID)
	
	DigitalSignatures = New Array;
	
	If Source.SignedWithDS Then
		
		If Common.SubsystemExists("StandardSubsystems.DigitalSignature") Then
			
			ModuleDigitalSignature = Common.CommonModule("DigitalSignature");
			DigitalSignatures = ModuleDigitalSignature.SetSignatures(Source.Ref);
			
			For Each FileDigitalSignature In DigitalSignatures Do
				
				FileDigitalSignature.Insert("Object", Source.Ref);
				SignatureAddress = PutToTempStorage(FileDigitalSignature.Signature, UUID);
				FileDigitalSignature.Insert("SignatureAddress", SignatureAddress);
			EndDo;
	
		EndIf;
		
	EndIf;
	
	Return DigitalSignatures;
	
EndFunction

Function StgnaturesListToSend(Source, UUID, FileName)
	
	DigitalSignatures = New Array;
	
	If Common.SubsystemExists("StandardSubsystems.DigitalSignature") Then
		
		DigitalSignatures = DigitalSignaturesList(Source, UUID);
		DataFileNameContent = CommonClientServer.ParseFullFileName(FileName);
		
		ModuleDigitalSignatureInternalClientServer = Common.CommonModule("DigitalSignatureInternalClientServer");
		ModuleDigitalSignatureInternal             = Common.CommonModule("DigitalSignatureInternal");
		ModuleDigitalSignature                      = Common.CommonModule("DigitalSignature");
		
		SignatureFilesExtension = ModuleDigitalSignature.PersonalSettings().SignatureFilesExtension;
		
		For Each FileDigitalSignature In DigitalSignatures Do
			
			SignatureFileName = ModuleDigitalSignatureInternalClientServer.SignatureFileName(DataFileNameContent.BaseName,
				String(FileDigitalSignature.CertificateOwner), SignatureFilesExtension);
			FileDigitalSignature.Insert("FileName", SignatureFileName);
			
			DataByCertificate = ModuleDigitalSignatureInternal.DataByCertificate(FileDigitalSignature, UUID);
			FileDigitalSignature.Insert("CertificateAddress", DataByCertificate.CertificateAddress);
			
			CertificateFileName = ModuleDigitalSignatureInternalClientServer.CertificateFileName(DataFileNameContent.BaseName,
				String(FileDigitalSignature.CertificateOwner), DataByCertificate.CertificateExtension);
				
			FileDigitalSignature.Insert("CertificateFileName", CertificateFileName);
			
		EndDo;
	EndIf;
	
	Return DigitalSignatures;
	
EndFunction

Procedure SetChangeButtonsInvisible(Items)
	
	CommandsNames = GetObjectChangeCommandsNames();
	
	For each FormItem In Items Do
	
		If TypeOf(FormItem) <> Type("FormButton") Then
			Continue;
		EndIf;
		
		If CommandsNames.Find(FormItem.CommandName) <> Undefined Then
			FormItem.Visible = False;
		EndIf;
	EndDo;
	
EndProcedure

Function GetObjectChangeCommandsNames()
	
	CommandsNames = New Array;
	
	CommandsNames.Add("DigitallySignFile");
	CommandsNames.Add("AddDSFromFile");
	
	CommandsNames.Add("DeleteDigitalSignature");
	
	CommandsNames.Add("Edit");
	CommandsNames.Add("SaveChanges");
	CommandsNames.Add("EndEdit");
	CommandsNames.Add("Unlock");
	
	CommandsNames.Add("Encrypt");
	CommandsNames.Add("Decrypt");
	
	CommandsNames.Add("StandardCopy");
	CommandsNames.Add("UpdateFromFileOnHardDrive");
	
	CommandsNames.Add("StandardWrite");
	CommandsNames.Add("StandardWriteAndClose");
	CommandsNames.Add("StandardSetDeletionMark");
	
	Return CommandsNames;
	
EndFunction

Function FilesSettings() Export
	
	FilesSettings = New Structure;
	FilesSettings.Insert("DontClearFiles",            New Array);
	FilesSettings.Insert("DontSynchronizeFiles",   New Array);
	FilesSettings.Insert("DontOutputToInterface",      New Array);
	FilesSettings.Insert("DontCreateFilesByTemplate", New Array);
	FilesSettings.Insert("FilesWithoutFolders",             New Array);
	
	SSLSubsystemsIntegration.OnDefineFilesSynchronizationExceptionObjects(FilesSettings.DontSynchronizeFiles);
	FilesOperationsOverridable.OnDefineSettings(FilesSettings);
	
	Return FilesSettings;
	
EndFunction

Procedure GenerateFilesListToSendViaEmail(Result, FileAttachment, FormID) Export
	
	FileDataAndBinaryData = FilesOperations.FileData(FileAttachment, FormID);
	FileName      = CommonClientServer.GetNameWithExtension(FileDataAndBinaryData.Description, FileDataAndBinaryData.Extension);
	FileDetails = FileDetails(FileName, FileDataAndBinaryData.BinaryFileDataRef);
	Result.Add(FileDetails);
	
	If FileAttachment.SignedWithDS Then
		SignaturesList = StgnaturesListToSend(FileAttachment, FormID, FileName);
		For each FileDigitalSignature In SignaturesList Do
			FileDetails = FileDetails(FileDigitalSignature.FileName, FileDigitalSignature.SignatureAddress);
			Result.Add(FileDetails);
			
			If ValueIsFilled(FileDigitalSignature.CertificateAddress) Then
				FileDetails = FileDetails(FileDigitalSignature.CertificateFileName, FileDigitalSignature.CertificateAddress);
				Result.Add(FileDetails);
			EndIf;
		EndDo;
	EndIf;
	
EndProcedure

Function FileDetails(FileName, AddressInTempStorage)
	
	FileDetails = New Structure;
	FileDetails.Insert("Presentation",             FileName);
	FileDetails.Insert("AddressInTempStorage", AddressInTempStorage);
	
	Return FileDetails;
	
EndFunction


/////////////////////////////////////////////////////////////////////////////////////
// Clear unused files.

Procedure ClearUnusedFilesData(ClearingSetup, ExceptionsArray = Undefined)
	
	If ClearingSetup.Action = Enums.FilesCleanupOptions.DoNotClear Then
		Return;
	EndIf;
	
	If ExceptionsArray = Undefined Then
		ExceptionsArray = New Array;
	EndIf;
	
	OwnersTree = SelectDataByRule(ClearingSetup, ExceptionsArray);
	
	If OwnersTree.Rows.Count() = 0 Then
		Return;
	EndIf;
	
	For Each File In OwnersTree.Rows Do
		
		If ClearingSetup.IsFile Then
			
			If ClearingSetup.Action = Enums.FilesCleanupOptions.CleanUpFilesAndVersions Then
				FileForMark = File.FileRef.GetObject();
				// Skipping deletion if the file is locked for editing.
				If ValueIsFilled(FileForMark.BeingEditedBy) Then
					Continue;
				EndIf;
				FileForMark.SetDeletionMark(True);
			EndIf;
			
			For Each Version In File.Rows Do
				ClearDataOnVersion(Version.VersionRef);
			EndDo;
			
		Else
			ClearDataAboutFile(File.FileRef);
		EndIf;
		
	EndDo;

EndProcedure

Function SelectDataByRule(ClearingSetup, ExceptionsArray)
	
	SettingsComposer = New DataCompositionSettingsComposer;
	
	ClearByRule = ClearingSetup.ClearingPeriod = Enums.FilesCleanupPeriod.ByRule;
	If ClearByRule Then
		ComposerSettings = ClearingSetup.FilterRule.Get();
		If ComposerSettings <> Undefined Then
			SettingsComposer.LoadSettings(ClearingSetup.FilterRule.Get());
		EndIf;
	EndIf;
	
	DataCompositionSchema = New DataCompositionSchema;
	DataSource = DataCompositionSchema.DataSources.Add();
	DataSource.Name = "DataSource1";
	DataSource.DataSourceType = "Local";
	
	DataSet = DataCompositionSchema.DataSets.Add(Type("DataCompositionSchemaDataSetQuery"));
	DataSet.Name = "DataSet1";
	DataSet.DataSource = DataSource.Name;
	
	DataCompositionSchema.TotalFields.Clear();
	
	If ClearingSetup.IsCatalogItemSetup Then
		FileOwner = ClearingSetup.OwnerID;
		ExceptionItem = ClearingSetup.FileOwner;
	Else
		FileOwner = ClearingSetup.FileOwner;
		ExceptionItem = Undefined;
	EndIf;
	
	DataCompositionSchema.DataSets[0].Query = QueryTextToClearFiles(
		FileOwner,
		ClearingSetup,
		ExceptionsArray,
		ExceptionItem);
	
	Structure = SettingsComposer.Settings.Structure.Add(Type("DataCompositionGroup"));
	
	SelectedField = Structure.Selection.Items.Add(Type("DataCompositionSelectedField"));
	SelectedField.Field = New DataCompositionField("FileRef");
	
	If ClearingSetup.IsFile Then
	
		VersionsStructure = Structure.Structure.Add(Type("DataCompositionGroup"));
	
		SelectedField = VersionsStructure.Selection.Items.Add(Type("DataCompositionSelectedField"));
		SelectedField.Field = New DataCompositionField("VersionRef");
	
	EndIf;
	
	SettingsComposer.Initialize(New DataCompositionAvailableSettingsSource(DataCompositionSchema));
	
	Parameter = SettingsComposer.Settings.DataParameters.Items.Find("OwnerType");
	Parameter.Value = TypeOf(FileOwner.EmptyRefValue);
	Parameter.Use = True;
	
	Parameter = SettingsComposer.Settings.DataParameters.Items.Find("ClearingPeriod");
	If Parameter <> Undefined Then
		If ClearingSetup.ClearingPeriod = Enums.FilesCleanupPeriod.OverOneMonth Then
			ClearingPeriodValue = AddMonth(BegOfDay(CurrentSessionDate()), -1);
		ElsIf ClearingSetup.ClearingPeriod = Enums.FilesCleanupPeriod.OverOneYear Then
			ClearingPeriodValue = AddMonth(BegOfDay(CurrentSessionDate()), -12);
		ElsIf ClearingSetup.ClearingPeriod = Enums.FilesCleanupPeriod.OverSixMonths Then
			ClearingPeriodValue = AddMonth(BegOfDay(CurrentSessionDate()), -6);
		EndIf;
		Parameter.Value = ClearingPeriodValue;
		Parameter.Use = True;
	EndIf;
	
	CurrentDateParameter = SettingsComposer.Settings.DataParameters.Items.Find("CurrentDate");
	If CurrentDateParameter <> Undefined Then
		CurrentDateParameter.Value = CurrentSessionDate();
		CurrentDateParameter.Use = True;
	EndIf;
	
	If ExceptionsArray.Count() > 0 Then
		Parameter = SettingsComposer.Settings.DataParameters.Items.Find("ExceptionsArray");
		Parameter.Value = ExceptionsArray;
		Parameter.Use = True;
	EndIf;
	
	If ClearingSetup.IsCatalogItemSetup Then
		Parameter = SettingsComposer.Settings.DataParameters.Items.Find("ExceptionItem");
		Parameter.Value = ExceptionItem;
		Parameter.Use = True;
	EndIf;
	
	TemplateComposer = New DataCompositionTemplateComposer;
	DataCompositionProcessor = New DataCompositionProcessor;
	OutputProcessor = New DataCompositionResultValueCollectionOutputProcessor;
	ValuesTree = New ValueTree;
	
	DataCompositionTemplate = TemplateComposer.Execute(DataCompositionSchema, SettingsComposer.Settings, , , Type("DataCompositionValueCollectionTemplateGenerator"));
	DataCompositionProcessor.Initialize(DataCompositionTemplate);
	OutputProcessor.SetObject(ValuesTree);
	OutputProcessor.Output(DataCompositionProcessor);
	
	Return ValuesTree;
	
EndFunction

////////////////////////////////////////////////////////////////////////////////
// File synchronization

Procedure SetFilesSynchronizationScheduledJobParameter(Val ParameterName, Val ParameterValue) Export
	
	JobParameters = New Structure;
	JobParameters.Insert("Metadata", Metadata.ScheduledJobs.FileSynchronization);
	If Not Common.DataSeparationEnabled() Then
		JobParameters.Insert("MethodName", Metadata.ScheduledJobs.FileSynchronization.MethodName);
	EndIf;
	
	SetPrivilegedMode(True);
	
	JobsList = ScheduledJobsServer.FindJobs(JobParameters);
	If JobsList.Count() = 0 Then
		JobParameters.Insert(ParameterName, ParameterValue);
		ScheduledJobsServer.AddJob(JobParameters);
	Else
		JobParameters = New Structure(ParameterName, ParameterValue);
		For Each Job In JobsList Do
			ScheduledJobsServer.ChangeJob(Job, JobParameters);
		EndDo;
	EndIf;

EndProcedure

Function IsFilesFolder(OwnerObject) Export
	
	Return TypeOf(OwnerObject) = Type("CatalogRef.FilesFolders");
	
EndFunction

Function FileToEditInCloud(File)
	
	Query = New Query;
	Query.Text = 
		"SELECT TOP 1
		|	FilesSynchronizationWithCloudServiceStatuses.File
		|FROM
		|	InformationRegister.FilesSynchronizationWithCloudServiceStatuses AS FilesSynchronizationWithCloudServiceStatuses
		|WHERE
		|	FilesSynchronizationWithCloudServiceStatuses.File = &File";
	
	Query.SetParameter("File", File);
	
	QueryResult = Query.Execute();
	
	DetailedRecordsSelection = QueryResult.Select();
	
	While DetailedRecordsSelection.Next() Do
		Return True;
	EndDo;
	
	Return False;
	
EndFunction

Function OnDefineFilesSynchronizationExceptionObjects() Export
	
	Return FilesSettings().DontSynchronizeFiles;
	
EndFunction

Function QueryTextToSynchronizeFIles(FileOwner, SyncSetup, ExceptionsArray, ExceptionItem)
	
	ObjectType = FileOwner;
	OwnerTypePresentation = Common.ObjectKindByType(TypeOf(ObjectType.EmptyRefValue));
	FullFilesCatalogName = SyncSetup.FileOwnerType.FullName;
	FilesObjectMetadata = Metadata.FindByFullName(FullFilesCatalogName);
	HasAbilityToStoreVersions = Common.HasObjectAttribute("CurrentVersion", FilesObjectMetadata);
	
	QueryText = "";
	
	CatalogFiles = Common.MetadataObjectByID(SyncSetup.FileOwnerType, False);
	If TypeOf(CatalogFiles) <> Type("MetadataObject") Then
		Return "";
	EndIf;
	AbilityToCreateGroups = CatalogFiles.Hierarchical;
	
	If TypeOf(FileOwner) <> Type("CatalogRef.MetadataObjectIDs") Then
		CatalogFolders = Common.MetadataObjectByID(SyncSetup.OwnerID, False);
	Else
		CatalogFolders = Common.MetadataObjectByID(FileOwner, False);
	EndIf;
	If TypeOf(CatalogFolders) <> Type("MetadataObject") Then
		Return "";
	EndIf;
	
	If Not IsBlankString(QueryText) Then
		QueryText= QueryText + "
		|
		|UNION ALL
		|";
	EndIf;
	
	QueryText = QueryText + "SELECT
	|	CatalogFolders.Ref,";
	
	AddAvailableFilterFields(QueryText, ObjectType);
	
	QueryText = QueryText + "
	|	CatalogFiles.Ref AS FileRef,";
	
	If AbilityToCreateGroups Then
		
		QueryText = QueryText + "
		|	CASE WHEN CatalogFiles.IsFolder THEN
		|		CatalogFiles.Description
		|	ELSE
		|		CatalogFiles.Description + ""."" + CatalogFiles.Extension
		|	END AS Description,
		|	CatalogFiles.DeletionMark AS DeletionMark,
		|	CatalogFiles.FileOwner AS Parent,
		|	FALSE AS IsFolder,";
		
		FilterByFolders = "(CatalogFiles.IsFolder 
		| OR (NOT CatalogFiles.IsFolder AND CatalogFiles.SignedWithDS = FALSE AND CatalogFiles.Encrypted = FALSE)) ";
		
	Else
		
		QueryText = QueryText + "
		|	CatalogFiles.Description + ""."" + CatalogFiles.Extension AS Description,
		|	CatalogFiles.DeletionMark AS DeletionMark,
		|	CatalogFiles.FileOwner AS Parent,
		|	FALSE AS IsFolder,";
		
		FilterByFolders = " CatalogFiles.SignedWithDS = FALSE AND CatalogFiles.Encrypted = FALSE ";
		
	EndIf;
	
	QueryText = QueryText + "
	|	TRUE AS InInfobase,
	|	FALSE AS IsOnServer,
	|	UNDEFINED AS Changes,
	|	ISNULL(FilesSynchronizationWithCloudServiceStatuses.Href, """") AS Href,
	|	ISNULL(FilesSynchronizationWithCloudServiceStatuses.Etag, """") AS Etag,
	|	FALSE AS Processed,
	|	DATETIME(1, 1, 1, 0, 0, 0) AS SynchronizationDate,
	|	CAST("""" AS STRING(36)) AS UID1C,
	|	"""" AS ToHref,
	|	"""" AS ToEtag,
	|	"""" AS ParentServer,
	|	"""" AS ServerDescription,
	|	FALSE AS ModifiedAtServer,
	|	UNDEFINED AS Level,
	|	"""" AS ParentOrdering,
	|	" + ?(HasAbilityToStoreVersions, "TRUE", "FALSE") + " AS IsFile
	|FROM
	|	Catalog." + CatalogFiles.Name + " AS CatalogFiles
	|		LEFT JOIN InformationRegister.FilesSynchronizationWithCloudServiceStatuses AS FilesSynchronizationWithCloudServiceStatuses
	|		ON (FilesSynchronizationWithCloudServiceStatuses.File = CatalogFiles.Ref)
	|		LEFT JOIN " + OwnerTypePresentation+ "." + CatalogFolders.Name + " AS CatalogFolders
	|		ON (CatalogFiles.FileOwner = CatalogFolders.Ref)
	|WHERE
	|	" + FilterByFolders + " AND VALUETYPE(CatalogFiles.FileOwner) = &OwnerType";
	
	If ExceptionsArray.Count() > 0 Then
		QueryText = QueryText + "
			|	AND NOT CatalogFolders.Ref IN HIERARCHY (&ExceptionsArray)";
	EndIf;
	
	If ExceptionItem <> Undefined Then
		QueryText = QueryText + "
			|	AND CatalogFolders.Ref IN HIERARCHY (&ExceptionItem)";
	EndIf;
	
	QueryText = QueryText + "
	|UNION ALL
	|
	|SELECT
	|	CatalogFolders.Ref,";
	
	AddAvailableFilterFields(QueryText, ObjectType);
	
	QueryText = QueryText + "
	|	CatalogFolders.Ref,
	|	" + ?(OwnerTypePresentation = "Document",
		"CatalogFolders.Presentation", "CatalogFolders.Description") + ",
	|	CatalogFolders.DeletionMark,";
	
	If Common.IsCatalog(CatalogFolders) AND CatalogFolders.Hierarchical Then
		QueryText = QueryText + "
		|	CASE
		|		WHEN CatalogFolders.Parent = VALUE(Catalog." + CatalogFolders.Name + ".EmptyRef)
		|			THEN UNDEFINED
		|		ELSE CatalogFolders.Parent
		|	END,";
	Else
		QueryText = QueryText + "Undefined,";
	EndIf;
	
	QueryText = QueryText + "
	|	TRUE,
	|	TRUE,
	|	FALSE,
		|	UNDEFINED,
	|	ISNULL(FilesSynchronizationWithCloudServiceStatuses.Href, """"),
	|	"""",
	|	FALSE,
	|	DATETIME(1, 1, 1, 0, 0, 0),
	|	"""",
	|	"""",
	|	"""",
	|	"""",
	|	"""",
	|	FALSE, 
	|	UNDEFINED,
	|	"""",
	|	" + ?(HasAbilityToStoreVersions, "TRUE", "FALSE") + "
	|FROM
	|	" + OwnerTypePresentation + "." + CatalogFolders.Name + " AS CatalogFolders
	|		LEFT JOIN InformationRegister.FilesSynchronizationWithCloudServiceStatuses AS FilesSynchronizationWithCloudServiceStatuses
	|		ON (FilesSynchronizationWithCloudServiceStatuses.File = CatalogFolders.Ref
	|			AND FilesSynchronizationWithCloudServiceStatuses.Account = &Account)
	|		WHERE
	|			TRUE";
	
	If ExceptionsArray.Count() > 0 Then
		QueryText = QueryText + "
			|	AND NOT CatalogFolders.Ref IN HIERARCHY (&ExceptionsArray)";
	EndIf;
	
	If ExceptionItem <> Undefined Then
		QueryText = QueryText + "
			|	AND CatalogFolders.Ref IN HIERARCHY (&ExceptionItem)";
	
	EndIf;
		
	Return QueryText;
	
EndFunction

Function IsFilesOwner(OwnerObject)
	
	FilesTypesArray = Metadata.DefinedTypes.AttachedFilesOwner.Type.Types();
	Return FilesTypesArray.Find(TypeOf(OwnerObject)) <> Undefined;
	
EndFunction

Procedure AddAvailableFilterFields(QueryText, ObjectType)
	
	AllCatalogs = Catalogs.AllRefsType();
	AllDocuments = Documents.AllRefsType();
	
	If AllCatalogs.ContainsType(TypeOf(ObjectType.EmptyRefValue)) Then
		Catalog = Metadata.Catalogs[ObjectType.Name];
		For Each Attribute In Catalog.Attributes Do
			QueryText = QueryText + Chars.LF + "CatalogFolders." + Attribute.Name + " AS " + Attribute.Name +",";
		EndDo;
	ElsIf AllDocuments.ContainsType(TypeOf(ObjectType.EmptyRefValue)) Then
		Document = Metadata.Documents[ObjectType.Name];
		For Each Attribute In Document.Attributes Do
			If Attribute.Type.ContainsType(Type("Date")) Then
				QueryText = QueryText + Chars.LF + "DATEDIFF(" + Attribute.Name + ", &CurrentDate, DAY) AS DaysBeforeDeletionFrom" + Attribute.Name + ",";
			EndIf;
			QueryText = QueryText + Chars.LF + "CatalogFolders." + Attribute.Name + ",";
		EndDo;
	EndIf;
	
EndProcedure

// Checks if an HTTP request failed and throws an exception.
Function CheckHTTP1CException(Response, ServerAddress)
	Result = New Structure("Success, ErrorText, ErrorCode");
	
	If (Response.StatusCode >= 400) AND (Response.StatusCode <= 599) Then
		
		ErrorTemplate = NStr("ru = 'Не удалось синхронизировать файл по адресу %2, т.к. сервер вернул HTTP код: %1. %3'; en = 'Cannot synchronize the file at %2 as the server returned HTTP code %1. %3'; pl = 'Nie udało się zsynchronizować pliku z adresem %2, ponieważ serwer zwrócił kod HTTP : %1. %3';de = 'Die Datei konnte nicht mit der Adresse synchronisiert werden %2, da der Server den HTTP-Code zurückgab: %1. %3';ro = 'Eșec la sincronizarea fișierului la adresa %2, deoarece serverul a returnat codul HTTP: %1. %3';tr = 'Sunucu HTTP kodunu iade ettiği için %2 adreste dosya eşleştirilemedi: %1%3'; es_ES = 'No se ha podido sincronizar el archivo según la dirección %2, porque el servidor ha devuelto el código HTTP: %1. %3'");
		ErrorInformation = Response.GetBodyAsString();
		
		Result.Success = False;
		Result.ErrorCode = Response.StatusCode;
		Result.ErrorText = StringFunctionsClientServer.SubstituteParametersToString(ErrorTemplate, 
			Response.StatusCode, DecodeString(ServerAddress, StringEncodingMethod.URLInURLEncoding), ErrorInformation);
		
		Return Result;
		
	EndIf;
	
	Result.Success = True;
	Return Result;
	
EndFunction

// Performs the webdav protocol method.
Function PerformWebdavMethod(MethodName, Href, TitlesMap, ExchangeStructure, XMLQuery="", ProtocolText = Undefined)

	HrefStructure = URIStructureDecoded(Href);
	
	HTTP = CreateHTTPConnectionWebdav(HrefStructure, ExchangeStructure, 20);
	
	HTTPWebdavQuery = New HTTPRequest(HrefStructure.PathAtServer, TitlesMap);
	
	If ValueIsFilled(XMLQuery) Then
		HTTPWebdavQuery.SetBodyFromString(XMLQuery);
	EndIf;
	
	If ProtocolText<>Undefined Then
		ProtocolText = ProtocolText + ?(IsBlankString(ProtocolText), "", Chars.LF)
			+ MethodName + " " + Href + Chars.LF + Chars.LF + XMLQuery + Chars.LF;
	EndIf; 
	
	ExchangeStructure.Response = HTTP.CallHTTPMethod(MethodName, HTTPWebdavQuery);
	
	If ProtocolText <> Undefined Then
		ProtocolText = ProtocolText + ?(IsBlankString(ProtocolText), "", Chars.LF) + "HTTP RESPONSE "
			+ ExchangeStructure.Response.StatusCode + Chars.LF + Chars.LF;
		For each ResponseTitle In ExchangeStructure.Response.Headers Do
			ProtocolText = ProtocolText+ResponseTitle.Key + ": " + ResponseTitle.Value + Chars.LF;
		EndDo; 
		ProtocolText = ProtocolText + Chars.LF + ExchangeStructure.Response.GetBodyAsString() + Chars.LF;
	EndIf; 
	
	Return CheckHTTP1CException(ExchangeStructure.Response, Href);
	
EndFunction

// Updates the unique service attribute of the file on the webdav server.
Function UpdateFileUID1C(Href, UID1C, SynchronizationParameters)
	
	HTTPTitles                  = New Map;
	HTTPTitles["User-Agent"]   = "1C Enterprise 8.3";
	HTTPTitles["Content-type"] = "text/xml";
	HTTPTitles["Accept"]       = "text/xml";
	
	XMLQuery = "<?xml version=""1.0"" encoding=""utf-8""?>
				|<D:propertyupdate xmlns:D=""DAV:"" xmlns:U=""tsov.pro"">
				|  <D:set><D:prop>
				|    <U:UID1C>%1</U:UID1C>
				|  </D:prop></D:set>
				|</D:propertyupdate>";
	XMLQuery = StringFunctionsClientServer.SubstituteParametersToString(XMLQuery, UID1C);
	
	Return PerformWebdavMethod("PROPPATCH", Href, HTTPTitles, SynchronizationParameters, XMLQuery);
	
EndFunction

// Reads the unique service attribute of the file on the webdav server.
Function GetUID1C(Href, SynchronizationParameters)

	HTTPTitles                 = New Map;
	HTTPTitles["User-Agent"]   = "1C Enterprise 8.3";
	HTTPTitles["Content-type"] = "text/xml";
	HTTPTitles["Accept"]       = "text/xml";
	HTTPTitles["Depth"]        = "0";
	
	Result = PerformWebdavMethod("PROPFIND",Href,HTTPTitles,SynchronizationParameters,
					"<?xml version=""1.0"" encoding=""utf-8""?>
					|<D:propfind xmlns:D=""DAV:"" xmlns:U=""tsov.pro""><D:prop>
					|<U:UID1C />
					|</D:prop></D:propfind>");
	
	If Result.Success Then
		XmlContext = DefineXMLContext(SynchronizationParameters.Response.GetBodyAsString());
		
		FoundEtag = CalculateXPath("//*[local-name()='propstat'][contains(./*[local-name()='status'],'200 OK')]/*[local-name()='prop']/*[local-name()='UID1C']",XmlContext).IterateNext();
		If FoundEtag <> Undefined Then
			Return FoundEtag.TextContent;
		EndIf;
	Else
		WriteToEventLogOfFilesSynchronization(Result.ErrorText, SynchronizationParameters.Account, EventLogLevel.Error);
	EndIf;
	
	Return "";

EndFunction

// Checks if the webdav server supports user properties for the file.
Function CheckUID1CAbility(Href, UID1C, SynchronizationParameters)
	
	UpdateFileUID1C(Href, UID1C, SynchronizationParameters);
	Return ValueIsFilled(GetUID1C(Href, SynchronizationParameters));
	
EndFunction

// Runs MCKOL on the webdav server.
Function CallMKCOLMethod(Href, SynchronizationParameters)

	HTTPTitles               = New Map;
	HTTPTitles["User-Agent"] = "1C Enterprise 8.3";
	Return PerformWebdavMethod("MKCOL", Href, HTTPTitles, SynchronizationParameters);

EndFunction

// Runs DELETE on the webdav server.
Function CallDELETEMethod(Href, SynchronizationParameters)
	
	HrefWithoutSlash = EndWithoutSlash(Href);
	HTTPTitles               = New Map;
	HTTPTitles["User-Agent"] = "1C Enterprise 8.3";
	Return PerformWebdavMethod("DELETE", HrefWithoutSlash, HTTPTitles, SynchronizationParameters);
	
EndFunction

// Receives Etag of the file on the server.
Function GetEtag(Href, SynchronizationParameters)
	
	HTTPTitles                 = New Map;
	HTTPTitles["User-Agent"]   = "1C Enterprise 8.3";
	HTTPTitles["Content-type"] = "text/xml";
	HTTPTitles["Accept"]       = "text/xml";
	HTTPTitles["Depth"]        = "0";
	
	Result = PerformWebdavMethod("PROPFIND",Href,HTTPTitles,SynchronizationParameters,
					"<?xml version=""1.0"" encoding=""utf-8""?>
					|<D:propfind xmlns:D=""DAV:""><D:prop>
					|<D:getetag />
					|</D:prop></D:propfind>");
	
	If Result.Success Then
		
		XmlContext = DefineXMLContext(SynchronizationParameters.Response.GetBodyAsString());
		
		FoundEtag = CalculateXPath("//*[local-name()='propstat'][contains(./*[local-name()='status'],'200 OK')]/*[local-name()='prop']/*[local-name()='getetag']",XmlContext).IterateNext();
		
		If FoundEtag <> Undefined Then
			Return FoundEtag.TextContent;
		EndIf;
	
	Else
		WriteToEventLogOfFilesSynchronization(Result.ErrorText, SynchronizationParameters.Account, EventLogLevel.Error);
	EndIf;
	
	Return "";
	
EndFunction

// Initializes the HTTPConnection object.
Function CreateHTTPConnectionWebdav(HrefStructure, SynchronizationParameters, Timeout)
	
	InternetProxy = Undefined;
	If Common.SubsystemExists("StandardSubsystems.GetFilesFromInternet") Then
		ModuleNetworkDownload = Common.CommonModule("GetFilesFromInternet");
		InternetProxy = ModuleNetworkDownload.GetProxy("https");
	EndIf;
	
	SecureConnection = Undefined;
	If HrefStructure.Schema = "https" Then 
		SecureConnection = CommonClientServer.NewSecureConnection();
	EndIf;
	
	If Not ValueIsFilled(HrefStructure.Port) Then
		HTTP = New HTTPConnection(
			HrefStructure.Host,
			,
			SynchronizationParameters.Username,
			SynchronizationParameters.Password,
			InternetProxy,
			Timeout,
			SecureConnection);
	Else
		HTTP = New HTTPConnection(
			HrefStructure.Host,
			HrefStructure.Port,
			SynchronizationParameters.Username,
			SynchronizationParameters.Password,
			InternetProxy,
			Timeout,
			SecureConnection);
	EndIf;
	
	Return HTTP;
	
EndFunction

// Calls the GET method at the webdav server and returns the imported file address in the temporary storage.
Function CallGETMethod(Href, Etag, SynchronizationParameters, FileModificationDate = Undefined, FileLength = Undefined)

	Result = New Structure("Success, TempDataAddress, ErrorText");
	HrefStructure = URIStructureDecoded(Href);
	
	Timeout = ?(FileLength <> Undefined, CalculateTimeout(FileLength), 43200);
	HTTP = CreateHTTPConnectionWebdav(HrefStructure, SynchronizationParameters, Timeout);
	
	HTTPTitles               = New Map;
	HTTPTitles["User-Agent"] = "1C Enterprise 8.3";
	HTTPTitles["Accept"]     = "application/octet-stream";
	
	HTTPWebdavQuery = New HTTPRequest(HrefStructure.PathAtServer, HTTPTitles);
	
	SynchronizationParameters.Response = HTTP.Get(HTTPWebdavQuery);
	
	Result = CheckHTTP1CException(SynchronizationParameters.Response, Href);
	If NOT Result.Success Then
		Return Result;
	EndIf;
	
	FileWithBinaryData = SynchronizationParameters.Response.GetBodyAsBinaryData();
	
	Etag = ?(SynchronizationParameters.Response.Headers["ETag"] = Undefined, "", SynchronizationParameters.Response.Headers["ETag"]);
	FileModificationDate = ?(SynchronizationParameters.Response.Headers["Last-Modified"] = Undefined,CurrentUniversalDate(),RFC1123Date(SynchronizationParameters.Response.Headers["Last-Modified"]));
	FileLength = FileWithBinaryData.Size();
	
	TempDataAddress = PutToTempStorage(FileWithBinaryData);
	
	Result.Insert("ImportedFileAddress", TempDataAddress);
	Return Result;

EndFunction

// Places the file on the webdav server using the PUT method and returns the assigned etag to a variable.
Function CallPUTMethod(Href, FileRef, SynchronizationParameters, IsFile)
	
	FileWithBinaryData = FilesOperations.FileBinaryData(FileRef);
	
	HrefStructure = URIStructureDecoded(Href);
	
	Timeout = CalculateTimeout(FileWithBinaryData.Size());
	HTTP = CreateHTTPConnectionWebdav(HrefStructure, SynchronizationParameters, Timeout);
	
	HTTPTitles = New Map;
	HTTPTitles["User-Agent"]   = "1C Enterprise 8.3";
	HTTPTitles["Content-Type"] = "application/octet-stream";
	
	HTTPWebdavQuery = New HTTPRequest(HrefStructure.PathAtServer, HTTPTitles);
	
	HTTPWebdavQuery.SetBodyFromBinaryData(FileWithBinaryData);
	
	SynchronizationParameters.Response = HTTP.Put(HTTPWebdavQuery);
	
	CheckHTTP1CException(SynchronizationParameters.Response, Href);
	
	Return GetEtag(Href,SynchronizationParameters);
	
EndFunction

// Imports file from server, creating a new version.
Function ImportFileFromServer(FileParameters, IsFile = Undefined)
	
	FileName                 = FileParameters.FileName;
	Href                     = FileParameters.Href;
	Etag                     = FileParameters.Etag;
	FileModificationDate     = FileParameters.FileModificationDate;
	FileLength               = FileParameters.FileLength;
	OwnerObject           = FileParameters.OwnerObject;
	ExistingFileRef = FileParameters.ExistingFileRef;
	SynchronizationParameters   = FileParameters.SynchronizationParameters;
	
	
	EventText = NStr("ru = 'Загрузка файла с сервера: %1'; en = 'Upload file from server: %1'; pl = 'Pobieranie pliku z serwera: %1';de = 'Datei vom Server herunterladen: %1';ro = 'Încărcarea fișierului de pe server: %1';tr = 'Dosyanın sunucudan içe aktarılması: %1'; es_ES = 'Descargo del archivo del servidor: %1'");
	
	WriteToEventLogOfFilesSynchronization(StringFunctionsClientServer.SubstituteParametersToString(EventText, FileParameters.FileName), SynchronizationParameters.Account);
	
	ImportResult = CallGETMethod(Href, Etag, SynchronizationParameters, FileModificationDate, FileLength);
	
	If IsFile = Undefined Then
		IsFile = IsFilesOwner(FileParameters.OwnerObject);
	EndIf;
	
	If ImportResult.Success AND ImportResult.ImportedFileAddress <> Undefined Then
		
		ImportedFileAddress = ImportResult.ImportedFileAddress;
		
		FileNameStructure = New File(FileParameters.FileName);
		
		If ExistingFileRef = Undefined Then
			
			FileToAddParameters = New Structure;
			
			If StrStartsWith(OwnerObject.Metadata().FullName(), "Catalog") AND OwnerObject.IsFolder Then
				FileToAddParameters.Insert("GroupOfFiles", OwnerObject);
				FileOwner = OwnerObject.FileOwner;
			Else
				FileOwner = OwnerObject;
			EndIf;
			
			FileToAddParameters.Insert("FilesOwner", FileOwner);
			
			FileToAddParameters.Insert("Author", SynchronizationParameters.FilesAuthor);
			FileToAddParameters.Insert("BaseName", FileNameStructure.BaseName);
			FileToAddParameters.Insert("ExtensionWithoutPoint", CommonClientServer.ExtensionWithoutPoint(FileNameStructure.Extension));
			FileToAddParameters.Insert("Modified", ToLocalTime(FileModificationDate, SessionTimeZone()));
			FileToAddParameters.Insert("ModificationTimeUniversal", FileModificationDate);
			
			NewFile = FilesOperations.AppendFile(FileToAddParameters, ImportedFileAddress);
			
			LockFileForEditingServer(NewFile, SynchronizationParameters.FilesAuthor);
			
		Else
			
			Mode = ?(ExistingFileRef.StoreVersions, "FileWithVersion", "File");
			FileInfo = FilesOperationsClientServer.FileInfo(Mode);
			
			FileInfo.BaseName              = FileNameStructure.BaseName;
			FileInfo.TempFileStorageAddress = ImportedFileAddress;
			FileInfo.ExtensionWithoutPoint            = CommonClientServer.ExtensionWithoutPoint(FileNameStructure.Extension);	
			FileInfo.ModificationTimeUniversal   = FileModificationDate;
			
			If FileInfo.StoreVersions Then
				FileInfo.NewVersionAuthor          = SynchronizationParameters.FilesAuthor;
			EndIf;
			
			FilesOperationsInternalServerCall.SaveFileChanges(ExistingFileRef, FileInfo, True, "", "", False);
			
			NewFile = ExistingFileRef;
			
		EndIf;
		
		UID1CFile = String(NewFile.Ref.UUID());
		UpdateFileUID1C(Href, UID1CFile, SynchronizationParameters);
		
		RememberRefServerData(NewFile.Ref, Href, Etag, IsFile, OwnerObject, False, SynchronizationParameters.Account);
		
		MessageText = NStr("ru = 'Загружен файл из облачного сервиса: ""%1""'; en = 'File ""%1"" is uploaded from the cloud service.'; pl = 'Pobrany plik z usługi w chmurze: ""%1""';de = 'Datei, die vom Cloud-Service heruntergeladen wurde: ""%1"".';ro = 'Importat fișierul din cloud service: ""%1""';tr = 'Bulut hizmetinden dosya yüklendi: ""%1""'; es_ES = 'Archivo descargado del servicio de nube: ""%1""'");
		StatusForEventLog = EventLogLevel.Information;
	Else
		MessageText = NStr("ru = 'Не удалось загрузить файл ""%1"" из облачного сервиса по причине:'; en = 'Cannot upload file ""%1"" from the cloud service. Reason:'; pl = 'Nie udało się pobrać pliku ""%1"" z usługi w chmurze z powodu:';de = 'Der Download der Datei ""%1"" aus dem Cloud-Service konnte aus folgendem Grund nicht durchgeführt werden:';ro = 'Eșec la importul fișierului ""%1"" din cloud service din motivul:';tr = 'Dosya ""%1"" aşağıdaki nedenle bulut hizmetinden içe aktarılamadı:'; es_ES = 'No se ha podido descargar el archivo ""%1"" del servicio de nube a causa de:'") + " " + Chars.LF + ImportResult.ErrorText;
		StatusForEventLog = EventLogLevel.Error;
	EndIf;
	
	WriteToEventLogOfFilesSynchronization(StringFunctionsClientServer.SubstituteParametersToString(MessageText, FileName), SynchronizationParameters.Account, StatusForEventLog);
	
	Return NewFile;

EndFunction

// Writes an event into an event log.
Procedure WriteToEventLogOfFilesSynchronization(MessageText, Account, EventLogLevelToSet = Undefined)

	If EventLogLevelToSet = Undefined Then
		EventLogLevelToSet = EventLogLevel.Information;
	EndIf;

	WriteLogEvent(EventLogEventSynchronization(),
					EventLogLevelToSet,,
					Account,
					MessageText);
	
EndProcedure

Function EventLogEventSynchronization()
	
	Return NStr("ru = 'Синхронизация файлов с облачным сервисом'; en = 'Synchronize files with cloud service'; pl = 'Synchronizacja plików z serwisem w chmurze';de = 'Dateien mit dem Cloud-Service synchronisieren';ro = 'Sincronizarea fișierelor cu cloud service';tr = 'Dosyaları bulut hizmeti ile eşleştir'; es_ES = 'Sincronización de archivos con servicio de nube'", Common.DefaultLanguageCode());
	
EndFunction

// Returns date transformed to the Date type from the RFC 1123 format.
Function RFC1123Date(HTTPDateAsString)

	MonthsNames = "janfebmaraprmayjunjulaugsepoctnovdec";
	// rfc1123-date = wkday "," SP date1 SP time SP "GMT".
	FirstSpacePosition = StrFind(HTTPDateAsString, " ");//date comes from the first space to the second space.
	SubstringDate = Mid(HTTPDateAsString,FirstSpacePosition + 1);
	SubstringTime = Mid(SubstringDate, 13);
	SubstringDate = Left(SubstringDate, 11);
	FirstSpacePosition = StrFind(SubstringTime, " ");
	SubstringTime = Left(SubstringTime,FirstSpacePosition - 1);
	// date1 = 2DIGIT SP month SP 4DIGIT.
	SubstringDay = Left(SubstringDate, 2);
	SubstringMonth = Format(Int(StrFind(MonthsNames,Lower(Mid(SubstringDate,4,3))) / 3)+1, "ND=2; NZ=00; NLZ=");
	SubstringYear = Mid(SubstringDate, 8);
	// time = 2DIGIT ":" 2DIGIT ":" 2DIGIT.
	SubstringHour = Left(SubstringTime, 2);
	SubstringMinute = Mid(SubstringTime, 4, 2);
	SubstringSecond = Right(SubstringTime, 2);
	
	Return Date(SubstringYear + SubstringMonth + SubstringDay + SubstringHour + SubstringMinute + SubstringSecond);
	
EndFunction

// Reads basic status of the directory on the server. Used to check the connection.
Procedure ReadDirectoryParameters(CheckResult, HttpAddress, ExchangeStructure)

	HTTPAddressStructure = URIStructureDecoded(HttpAddress);
	ServerAddress = EncodeURIByStructure(HTTPAddressStructure);
	
	Try
		// receiving the directory
		HTTPTitles = New Map;
		HTTPTitles["User-Agent"]   = "1C Enterprise 8.3";
		HTTPTitles["Content-type"] = "text/xml";
		HTTPTitles["Accept"]       = "text/xml";
		HTTPTitles["Depth"]        = "0";
		
		Result = PerformWebdavMethod("PROPFIND", ServerAddress, HTTPTitles, ExchangeStructure,
						"<?xml version=""1.0"" encoding=""utf-8""?>
						|<D:propfind xmlns:D=""DAV:"" xmlns:U=""tsov.pro""><D:prop>
						|<D:quota-used-bytes /><D:quota-available-bytes />
						|</D:prop></D:propfind>"
						, CheckResult.ResultProtocol);
		
		If Result.Success = False Then
			CheckResult.Cancel = True;
			CheckResult.ErrorCode = Result.ErrorCode;
			CheckResult.ResultText = Result.ErrorText;
			WriteToEventLogOfFilesSynchronization(Result.ErrorText, ExchangeStructure.Account, EventLogLevel.Error);
			Return;
		EndIf;
		
		XMLDocumentContext = DefineXMLContext(ExchangeStructure.Response.GetBodyAsString());
		
		XPathResult = CalculateXPath("//*[local-name()='response']",XMLDocumentContext);
		
		FoundResponse = XPathResult.IterateNext();
		
		While FoundResponse <> Undefined Do
			
			FoundPropstat = CalculateXPath("./*[local-name()='propstat'][contains(./*[local-name()='status'],'200 OK')]/*[local-name()='prop']", XMLDocumentContext, FoundResponse).IterateNext();
			
			If FoundPropstat<>Undefined Then
				For each PropstatChildNode In FoundPropstat.ChildNodes Do
					If PropstatChildNode.LocalName = "quota-available-bytes" Then
						Try
							SizeInMegabytes = Round(Number(PropstatChildNode.TextContent)/1024/1024, 1);
						Except
							SizeInMegabytes = 0;
						EndTry;
						
						FreeSpaceInformation = NStr("ru = 'Свободное место : %1 Мб'; en = 'Free space: %1 MB'; pl = 'Wolna przestrzeń : %1 MB';de = 'Freier Platz: %1 MB';ro = 'Spațiu liber: %1 Mb';tr = 'Boş yer: %1 MB'; es_ES = 'Espacio libre: %1 Mb'");
						
						CheckResult.ResultText = CheckResult.ResultText + ?(IsBlankString(CheckResult.ResultText), "", Chars.LF)
							+ StringFunctionsClientServer.SubstituteParametersToString(FreeSpaceInformation, SizeInMegabytes);
					ElsIf PropstatChildNode.LocalName = "quota-used-bytes" Then
						Try
							SizeInMegabytes = Round(Number(PropstatChildNode.TextContent)/1024/1024, 1);
						Except
							SizeInMegabytes = 0;
						EndTry;
						
						OccupiedSpaceInformation = NStr("ru = 'Занято : %1 Мб'; en = 'Occupied: %1 MB'; pl = 'Zajęta przestrzeń : %1 MB';de = 'Belegt: %1 MB';ro = 'Ocupat: %1 Mb';tr = 'Dolu: %1 MB'; es_ES = 'Ocupado: %1 Mb'");
						
						CheckResult.ResultText = CheckResult.ResultText + ?(IsBlankString(CheckResult.ResultText), "", Chars.LF)
							+ StringFunctionsClientServer.SubstituteParametersToString(OccupiedSpaceInformation, SizeInMegabytes);
					EndIf; 
				EndDo; 
			EndIf; 
			
			FoundResponse = XPathResult.IterateNext();
			
		EndDo;
	
	Except
		ErrorDescription = ErrorDescription();
		CheckResult.ResultText = CheckResult.ResultText + ?(IsBlankString(CheckResult.ResultText), "", Chars.LF) + ErrorDescription;
		WriteToEventLogOfFilesSynchronization(ErrorDescription, ExchangeStructure.Account, EventLogLevel.Error);
		CheckResult.Cancel = True;
	EndTry; 
	
EndProcedure

// Returns URI structure
Function URIStructureDecoded(Val URIString)
	
	URIString = TrimAll(URIString);
	
	// Schema
	Schema = "";
	Position = StrFind(URIString, "://");
	If Position > 0 Then
		Schema = Lower(Left(URIString, Position - 1));
		URIString = Mid(URIString, Position + 3);
	EndIf;

	// Connection string and path on the server.
	ConnectionString = URIString;
	PathAtServer = "";
	Position = StrFind(ConnectionString, "/");
	If Position > 0 Then
		// First slash included
		PathAtServer = Mid(ConnectionString, Position);
		ConnectionString = Left(ConnectionString, Position - 1);
	EndIf;
		
	// User details and server name.
	AuthorizationString = "";
	ServerName = ConnectionString;
	Position = StrFind(ConnectionString, "@");
	If Position > 0 Then
		AuthorizationString = Left(ConnectionString, Position - 1);
		ServerName = Mid(ConnectionString, Position + 1);
	EndIf;
	
	// Username and password.
	Username = AuthorizationString;
	Password = "";
	Position = StrFind(AuthorizationString, ":");
	If Position > 0 Then
		Username = Left(AuthorizationString, Position - 1);
		Password = Mid(AuthorizationString, Position + 1);
	EndIf;
	
	// The host and port.
	Host = ServerName;
	Port = "";
	Position = StrFind(ServerName, ":");
	If Position > 0 Then
		Host = Left(ServerName, Position - 1);
		Port = Mid(ServerName, Position + 1);
	EndIf;
	
	Result = New Structure;
	Result.Insert("Schema", Lower(Schema));
	Result.Insert("Username", Username);
	Result.Insert("Password", Password);
	Result.Insert("ServerName", Lower(ServerName));
	Result.Insert("Host", Lower(Host));
	Result.Insert("Port", ?(IsBlankString(Port), Undefined, Number(Port)));
	Result.Insert("PathAtServer", DecodeString(EndWithoutSlash(PathAtServer),StringEncodingMethod.URLInURLEncoding)); 
	
	// A path on the server will always have the first but not the last slash, it is universal for files and folders.
	Return Result; 
	
EndFunction

// Returns URI, composed from a structure.
Function EncodeURIByStructure(Val URIStructure, IncludingPathAtServer = True)
	Result = "";
	
	// Protocol
	If Not IsBlankString(URIStructure.Schema) Then
		Result = Result + URIStructure.Schema + "://";
	EndIf;
	
	// Authorization
	If Not IsBlankString(URIStructure.Username) Then
		Result = Result + URIStructure.Username + ":" + URIStructure.Password + "@";
	EndIf;
		
	// Everything else
	Result = Result + URIStructure.Host;
	If ValueIsFilled(URIStructure.Port) Then
		Result = Result + ":" + ?(TypeOf(URIStructure.Port) = Type("Number"), Format(URIStructure.Port, "NG=0"), URIStructure.Port);
	EndIf;
	
	Result = Result + ?(IncludingPathAtServer, EndWithoutSlash(URIStructure.PathAtServer), "");
	
	// Always without the final slash
	Return Result; 
	
EndFunction

// Returns a string that is guaranteed to begin with a forward slash.
Function StartWithSlash(Val SourceString)
	Return ?(Left(SourceString,1)="/", SourceString, "/"+SourceString);
EndFunction 

// Returns a string that is guaranteed to end without a forward slash.
Function EndWithoutSlash(Val SourceString)
	Return ?(Right(SourceString,1)="/", Left(SourceString, StrLen(SourceString)-1), SourceString);
EndFunction

// Returns the result of comparing the tow URI paths, regardless of having the starting and final 
// forward slash, encoding of special characters, as well as the server address.
Function IsIdenticalURIPaths(URI1, URI2, SensitiveToRegister = True)
	
	// Ensures identity regardless of slashes and encoding.
	URI1Structure = URIStructureDecoded(URI1); 
	URI2Structure = URIStructureDecoded(URI2);
	If NOT SensitiveToRegister Then
		URI1Structure.PathAtServer = Lower(URI1Structure.PathAtServer);
		URI2Structure.PathAtServer = Lower(URI2Structure.PathAtServer);
	EndIf; 
	
	Return EncodeURIByStructure(URI1Structure,True) = EncodeURIByStructure(URI2Structure,True);
	
EndFunction

// Returns the file name according to Href.
Function FileNameByHref(Href)

	URI = EndWithoutSlash(Href);
	URILength = StrLen(URI);
	
	// Finding the last slash, after it the file name is located.
	
	For Cnt = 1 To URILength Do
		URISymbol = Mid(URI,URILength - Cnt + 1, 1);
		If URISymbol = "/" Then
			Return DecodeString(Mid(URI,URILength - Cnt + 2), StringEncodingMethod.URLEncoding);
		EndIf;
	EndDo;
	
	Return DecodeString(URI,StringEncodingMethod.URLEncoding);

EndFunction

// Saves data about Href and Etag of a file or folder to the database.
Procedure RememberRefServerData(
		Ref,
		Href,
		Etag,
		IsFile,
		FileOwner,
		IsFolder,
		Account = Undefined)

	RegisterRecord = InformationRegisters.FilesSynchronizationWithCloudServiceStatuses.CreateRecordManager();
	RegisterRecord.File                        = Ref;
	RegisterRecord.Href                        = Href;
	RegisterRecord.Etag                        = Etag;
	RegisterRecord.UUID1C   = ?(TypeOf(Ref) = Type("String"), "", Ref.UUID());
	RegisterRecord.IsFile                     = IsFile;
	RegisterRecord.IsFileOwner            = IsFolder;
	RegisterRecord.FileOwner               = FileOwner;
	RegisterRecord.Account               = Account;
	RegisterRecord.Synchronized             = False;
	RegisterRecord.SynchronizationDateStart     = CurrentSessionDate();
	RegisterRecord.SynchronizationDateCompletion = CurrentSessionDate() + 1800; // 30 minutes
	RegisterRecord.SessionNumber                 = InfoBaseSessionNumber();
	RegisterRecord.Write(True);
	
EndProcedure

// Saves data about Href and Etag of a file or folder to the database.
Procedure SetSynchronizationStatus(FileInfo, Account = Undefined)

	RegisterRecord = InformationRegisters.FilesSynchronizationWithCloudServiceStatuses.CreateRecordManager();
	RegisterRecord.File                        = FileInfo.FileRef;
	RegisterRecord.Href                        = FileInfo.ToHref;
	RegisterRecord.Etag                        = FileInfo.ToEtag;
	RegisterRecord.UUID1C   = FileInfo.FileRef.UUID();
	RegisterRecord.IsFile                     = FileInfo.IsFile;
	RegisterRecord.IsFileOwner            = FileInfo.IsFolder;
	RegisterRecord.FileOwner               = FileInfo.Parent;
	RegisterRecord.Synchronized             = FileInfo.Processed;
	RegisterRecord.SynchronizationDateStart     = CurrentSessionDate();
	RegisterRecord.SynchronizationDateCompletion = CurrentSessionDate();
	RegisterRecord.SessionNumber                 = InfoBaseSessionNumber();
	
	RegisterRecord.Account               = Account;
	
	RegisterRecord.Write(True);
	
EndProcedure

// Deletes data about Href and Etag of a file or folder to the database.
Procedure DeleteRefServerData(Ref, Account)

	RegisterSet = InformationRegisters.FilesSynchronizationWithCloudServiceStatuses.CreateRecordSet();
	RegisterSet.Filter.File.Set(Ref);
	RegisterSet.Filter.Account.Set(Account);
	RegisterSet.Write(True);

EndProcedure

// Defines xml context
Function DefineXMLContext(XMLText)
	
	ReadXMLText = New XMLReader;
	ReadXMLText.SetString(XMLText);
	DOMBuilderForXML = New DOMBuilder;
	DocumentDOMForXML = DOMBuilderForXML.Read(ReadXMLText);
	NamesResolverForXML = New DOMNamespaceResolver(DocumentDOMForXML);
	Return New Structure("DOMDocument,DOMDereferencer", DocumentDOMForXML, NamesResolverForXML); 
	
EndFunction

// Calculates xpath expression for xml context.
Function CalculateXPath(Expression, Context, ContextNode = Undefined)
	
	Return Context.DOMDocument.EvaluateXPathExpression(Expression,?(ContextNode=Undefined,Context.DOMDocument,ContextNode),Context.DOMDereferencer);
	
EndFunction

// Returns Href, calculated for a row from a file table by the search of all parents method.
Function CalculateHref(FilesRow,FilesTable)
	// Recursively collecting descriptions.
	FilesRowsFound = FilesTable.Find(FilesRow.Parent,"FileRef");
	If FilesRowsFound = Undefined Then
		Return ?(ValueIsFilled(FilesRow.Description), FilesRow.Description +"/","");
	Else
		Return CalculateHref(FilesRowsFound,FilesTable) + FilesRow.Description +"/";
	EndIf; 
EndFunction

// Returns a file table row by URI, while considering the possible different spelling of URI (for 
// example, encoded, relative or absolute, and so on).
Function FindRowByURI(SoughtURI, TableWithURI, URIColumn)

	For each TableRow In TableWithURI Do
		If IsIdenticalURIPaths(SoughtURI,TableRow[URIColumn]) Then
			Return TableRow;
		EndIf; 
	EndDo; 
	
	Return Undefined;
	
EndFunction

// The level of the file row is calculated by a recursive algorithm.
Function LevelRecursively(FilesRow,FilesTable)
	
	// Equals to the level in the database or on the server, depending on where it is less.
	FilesRowsFound = FilesTable.FindRows(New Structure("FileRef", FilesRow.Parent));
	AdditionCount = ?(FilesRowsFound.Count() = 0, 0, 1);
	For each FilesRowFound In FilesRowsFound Do
		AdditionCount = AdditionCount + LevelRecursively(FilesRowFound,FilesTable);
	EndDo;
	
	Return AdditionCount;
	
EndFunction

// The file level on the webdav server is calculated using a recursive algorithm.
Function RecursivelyLevelAtServer(FilesRow,FilesTable) 
	
	FilesRowsFound = FilesTable.FindRows(New Structure("FileRef", FilesRow.ParentServer));
	AdditionCount = ?(FilesRowsFound.Count() = 0, 0, 1);
	For each FilesRowFound In FilesRowsFound Do
		AdditionCount = AdditionCount + RecursivelyLevelAtServer(FilesRowFound, FilesTable);
	EndDo;
	
	Return AdditionCount;
	
EndFunction

// Calculates the levels of all rows in the file table.
Procedure CalculateLevelRecursively(FilesTable)
	FilesTable.Indexes.Add("FileRef");
	For each FilesRow In FilesTable Do
		
		If NOT ValueIsFilled(FilesRow.FileRef) Then
			Continue;
		EndIf;
		
		// Equals to the level in the database or on the server, depending on where it is less.
		LevelInBase    = LevelRecursively(FilesRow, FilesTable);
		LevelAtServer = RecursivelyLevelAtServer(FilesRow, FilesTable);
		If LevelAtServer = 0 Then
			FilesRow.Level            = LevelInBase;
			FilesRow.ParentOrdering = FilesRow.Parent;
		Else
			If LevelInBase <= LevelAtServer Then
				FilesRow.Level            = LevelInBase;
				FilesRow.ParentOrdering = FilesRow.Parent;
			Else
				FilesRow.Level            = LevelAtServer;
				FilesRow.ParentOrdering = FilesRow.ParentServer;
			EndIf;
		EndIf;
	EndDo;
	
EndProcedure

// When changing the server path to folder, you must replace the paths to the subordinate files, which is what this procedure does.
Procedure RecursivelyRefreshSUbordinateItemsRefs(FilesRow,val ToHref,val ToHref2,FilesTable)

	// Changing the root reference, it always has to be encoded.
	FilesRow.ToHref = StrReplace(
							DecodeString(EndWithoutSlash(FilesRow.ToHref), StringEncodingMethod.URLInURLEncoding),
							DecodeString(EndWithoutSlash(ToHref), StringEncodingMethod.URLInURLEncoding),
							DecodeString(EndWithoutSlash(ToHref2), StringEncodingMethod.URLInURLEncoding));
	
	FoundSubordinateRows = FilesTable.FindRows(New Structure("ParentServer", FilesRow.Ref));
	For each SubordinateRow In FoundSubordinateRows Do
		RecursivelyRefreshSUbordinateItemsRefs(SubordinateRow,ToHref,ToHref2,FilesTable);
	EndDo; 

EndProcedure

// Recursively imports the list of files from the server into the file table.
Procedure ImportFilesTreeRecursively(CurrentRowsOfFilesTree, HttpAddress, SynchronizationParameters, Cancel=False)

	HTTPAddressStructure   = URIStructureDecoded(HttpAddress);
	CloudServiceAddress = EncodeURIByStructure(HTTPAddressStructure, False);
	ServerAddress          = EncodeURIByStructure(HTTPAddressStructure);
	
	Try
		// Receiving the directory
		HTTPTitles = New Map;
		HTTPTitles["User-Agent"] = "1C Enterprise 8.3";
		HTTPTitles["Content-type"] = "text/xml";
		HTTPTitles["Accept"] = "text/xml";
		HTTPTitles["Depth"] = "1";
		
		Result = PerformWebdavMethod("PROPFIND", ServerAddress, HTTPTitles, SynchronizationParameters,
						"<?xml version=""1.0"" encoding=""utf-8""?>
						|<D:propfind xmlns:D=""DAV:"" xmlns:U=""tsov.pro""><D:prop>
						|<D:getetag /><U:UID1C /><D:resourcetype />
						|<D:getlastmodified /><D:getcontentlength />
						|</D:prop></D:propfind>");
		
		If Result.Success = False Then
			WriteToEventLogOfFilesSynchronization(Result.ErrorText, SynchronizationParameters.Account, EventLogLevel.Error);
			Return;
		EndIf;
		
		XMLDocumentContext = DefineXMLContext(SynchronizationParameters.Response.GetBodyAsString());
		
		XPathResult = CalculateXPath("//*[local-name()='response']", XMLDocumentContext);
		
		FoundResponse = XPathResult.IterateNext();
		
		While FoundResponse <> Undefined Do
			
			// There is always Href, otherwise, it is a critical error.
			FoundHref = CalculateXPath("./*[local-name()='href']", XMLDocumentContext, FoundResponse).IterateNext();
			If FoundHref = Undefined Then
				ErrorText = NStr("ru = 'Ошибка ответа от сервера: не найден HREF в %1'; en = 'The server returned an error: HREF is not found in %1.'; pl = 'Błąd odpowiedzi od serwera: nie znaleziono HREF w %1';de = 'Serverantwortfehler: HREF nicht gefunden in %1';ro = 'Eroarea răspunsului de la server: HREF nu a fost găsit în %1';tr = 'Sunucudan yanıt hatası: %1''de HREF bulunamadı'; es_ES = 'Error de la respuesta del servidor: no encontrado HREF en %1'");
				Raise StringFunctionsClientServer.SubstituteParametersToString(ErrorText, ServerAddress);
			EndIf; 
			
			HrefText = EndWithoutSlash(StartWithSlash(FoundHref.TextContent));
			
			If IsIdenticalURIPaths(CloudServiceAddress + HrefText, ServerAddress) Then
				FoundResponse = XPathResult.IterateNext();
				Continue;
			EndIf; 
			
			NewFilesTreeRow = CurrentRowsOfFilesTree.Add();
			// Always encoded
			NewFilesTreeRow.Href = CloudServiceAddress + HrefText;
			NewFilesTreeRow.FileName = FileNameByHref(NewFilesTreeRow.Href);
			NewFilesTreeRow.Etag = "";
			NewFilesTreeRow.UID1C = "";
			NewFilesTreeRow.IsFolder = Undefined;
			
			FoundPropstat = CalculateXPath("./*[local-name()='propstat'][contains(./*[local-name()='status'],'200 OK')]/*[local-name()='prop']", XMLDocumentContext, FoundResponse).IterateNext();
			
			If FoundPropstat <> Undefined Then
				For each PropstatChildNode In FoundPropstat.ChildNodes Do
					If PropstatChildNode.LocalName = "resourcetype" Then
						NewFilesTreeRow.IsFolder = CalculateXPath("./*[local-name()='collection']", XMLDocumentContext, PropstatChildNode).IterateNext() <> Undefined;
					ElsIf PropstatChildNode.LocalName = "UID1C" Then
						NewFilesTreeRow.UID1C = PropstatChildNode.TextContent;
					ElsIf PropstatChildNode.LocalName = "getetag" Then
						NewFilesTreeRow.Etag = PropstatChildNode.TextContent;
					ElsIf PropstatChildNode.LocalName = "getlastmodified" Then
						NewFilesTreeRow.ModificationDate = RFC1123Date(PropstatChildNode.TextContent);//UTC
					ElsIf PropstatChildNode.LocalName = "getcontentlength" Then
						NewFilesTreeRow.Length = Number(StrReplace(PropstatChildNode.TextContent," ",""));
					EndIf;
				EndDo;
			EndIf;
			
			// If there was no UID, we try to receive it separately, it is necessary, for example, for owncloud.
			If NOT ValueIsFilled(NewFilesTreeRow.UID1C) Then
				NewFilesTreeRow.UID1C = GetUID1C(NewFilesTreeRow.Href, SynchronizationParameters);
			EndIf;
			
			FoundResponse = XPathResult.IterateNext();
			
		EndDo;
	
	Except
		WriteToEventLogOfFilesSynchronization(ErrorDescription(), SynchronizationParameters.Account, EventLogLevel.Error);
		Cancel = True;
	EndTry;
	
	For each FilesTreeRow In CurrentRowsOfFilesTree Do
		If FilesTreeRow.IsFolder = True Then
			ImportFilesTreeRecursively(FilesTreeRow.Rows, FilesTreeRow.Href, SynchronizationParameters, Cancel);
		EndIf;
	EndDo;
	
EndProcedure

// Imports new folders and files from webdav server that are not yet in the database, and reflects them in the file table.
Procedure ImportNewAttachedFiles(FilesTreeRows, FilesTable, SynchronizationParameters, OwnerObject = Undefined)
	
	For each FilesTreeRow In FilesTreeRows Do
		
		If FilesTreeRow.IsFolder Then
			// The folder is determined first by UID1C if not found, by the old Href, since The UID can be lost 
			// when editing, and the new Href cannot be found in the base yet if the UID was lost when edited 
			// and the folder is moved to another folder (Href has changed), then it will be imported into the 
			// new folder card. Search by Href is justified, because it is unique for each folder on the file server.
			CurrentFilesFolder = Undefined;
			// Theoretically, you can also search files by Etag, but the question of duplicates will arise, therefore, do not look further.
			
			If Not IsBlankString(FilesTreeRow.UID1C) Then
			
				Query = New Query;
				Query.Text = 
					"SELECT TOP 1
					|	FilesSynchronizationWithCloudServiceStatuses.File AS Ref
					|FROM
					|	InformationRegister.FilesSynchronizationWithCloudServiceStatuses AS FilesSynchronizationWithCloudServiceStatuses
					|WHERE
					|	FilesSynchronizationWithCloudServiceStatuses.UUID1C = &UUID1C";
					
				Query.SetParameter("UUID1C", New UUID(FilesTreeRow.UID1C));
				QueryResult = Query.Execute();
				
				DetailedRecordsSelection = QueryResult.Select();
				
				While DetailedRecordsSelection.Next() Do
					CurrentFilesFolder = DetailedRecordsSelection;
				EndDo;
				
			EndIf;
			
			If (CurrentFilesFolder = Undefined) AND (FilesTable.Find(FilesTreeRow.Href, "Href") = Undefined) Then
				
				// It is a new folder on the server.
				// If a folder lies in the exchange directory root or in the root of metadata object being synchronized, it does not belong to owner object.
				// Such folders are ignored.
				If OwnerObject = Undefined
					Or TypeOf(OwnerObject) = Type("CatalogRef.MetadataObjectIDs") Then
					Continue;
				EndIf;
				
				// Checking if it is possible to store UID1C. If it is not, folder is not loaded.
				If NOT CheckUID1CAbility(FilesTreeRow.Href, String(New UUID), SynchronizationParameters) Then
					EventText = NStr("ru = 'Невозможно сохранение дополнительных свойств файла, он не будет загружен: %1'; en = 'Cannot download file %1 because an error occurred when saving its additional properties.'; pl = 'Nie można zapisać dodatkowych właściwości pliku, nie będzie on pobrany: %1';de = 'Es ist nicht möglich, zusätzliche Dateieigenschaften zu speichern, sie werden nicht geladen: %1';ro = 'Nu puteți salva proprietățile suplimentare ale fișierului, el nu va fi încărcat: %1';tr = 'Dosyanın ek özellikleri kaydedilemedi, dosya içe aktarılamaz: %1'; es_ES = 'Es imposible guardar las propiedades adicionales de los archivos, no será descargado: %1'");
					WriteToEventLogOfFilesSynchronization(StringFunctionsClientServer.SubstituteParametersToString(EventText, FilesTreeRow.FileName), SynchronizationParameters.Account);
					Continue;
				EndIf;
				
				Try
					
					CurrentFilesFolder = FilesOperationsInternalServerCall.CreateFilesFolder(FilesTreeRow.FileName, OwnerObject, SynchronizationParameters.FilesAuthor);
					
					FilesTreeRow.UID1C = String(CurrentFilesFolder.UUID());
					UpdateFileUID1C(FilesTreeRow.Href, FilesTreeRow.UID1C, SynchronizationParameters);
					
					NewFilesTableRow                    = FilesTable.Add();
					NewFilesTableRow.FileRef         = CurrentFilesFolder;
					NewFilesTableRow.DeletionMark    = False;
					NewFilesTableRow.Parent           = OwnerObject;
					NewFilesTableRow.IsFolder           = True;
					NewFilesTableRow.UID1C              = FilesTreeRow.UID1C;
					NewFilesTableRow.InInfobase          = True;
					NewFilesTableRow.IsOnServer      = True;
					NewFilesTableRow.ModifiedAtServer   = False;
					NewFilesTableRow.Changes          = CurrentFilesFolder;
					NewFilesTableRow.Href               = "";
					NewFilesTableRow.Etag               = "";
					NewFilesTableRow.ToHref             = FilesTreeRow.Href;
					NewFilesTableRow.ToEtag             = FilesTreeRow.Etag;
					NewFilesTableRow.ParentServer     = OwnerObject;
					NewFilesTableRow.Description       = FilesTreeRow.FileName;
					NewFilesTableRow.ServerDescription = FilesTreeRow.FileName;
					NewFilesTableRow.Processed          = True;
					NewFilesTableRow.IsFile            = True;
					
					RememberRefServerData(
						NewFilesTableRow.FileRef,
						NewFilesTableRow.ToHref,
						NewFilesTableRow.ToEtag,
						NewFilesTableRow.IsFile,
						NewFilesTableRow.Parent,
						NewFilesTableRow.IsFolder,
						SynchronizationParameters.Account);
					
					EventText = NStr("ru = 'Загружена папка с сервера:  %1'; en = 'Downloaded folder from server %1.'; pl = 'Pobrano folder z serwera: %1';de = 'Ein Ordner wurde vom Server heruntergeladen:  %1';ro = 'Importat folderul de pe server: %1';tr = 'Sunucudaki klasör içe aktarıldı: %1'; es_ES = 'Carpeta descargada del servidor: %1'");
					WriteToEventLogOfFilesSynchronization(StringFunctionsClientServer.SubstituteParametersToString(EventText, NewFilesTableRow.ServerDescription), SynchronizationParameters.Account);
					
				Except
					WriteToEventLogOfFilesSynchronization(ErrorDescription() ,SynchronizationParameters.Account);
				EndTry;
				
			Else
				// Updating ToHref
				PreviousFIlesTableRow = FilesTable.Find(CurrentFilesFolder.Ref, "FileRef");
				If PreviousFIlesTableRow <> Undefined Then
					PreviousFIlesTableRow.ToHref             = FilesTreeRow.Href;
					PreviousFIlesTableRow.ToEtag             = FilesTreeRow.Etag;
					PreviousFIlesTableRow.ParentServer     = OwnerObject;
					PreviousFIlesTableRow.ServerDescription = FilesTreeRow.FileName;
					PreviousFIlesTableRow.IsOnServer      = True;
					PreviousFIlesTableRow.ModifiedAtServer   = NOT IsIdenticalURIPaths(PreviousFIlesTableRow.ToHref,PreviousFIlesTableRow.Href);
				EndIf;
			EndIf;
			
			// Now it is a parent for subordinate rows.
			ImportNewAttachedFiles(FilesTreeRow.Rows, FilesTable, SynchronizationParameters, CurrentFilesFolder.Ref);
			
		Else 
			// This is a file
			// The file is determined first by UID1C. If it is not found, by the old Href, since The UID can be 
			// lost when editing, and the new Href cannot be found in the base yet if the UID was lost when 
			// edited and the file is moved to another folder (Href has changed), then it will be imported into 
			// the new file card. Search by Href is justified, because it is unique for each file on the file server.
			
			// The file will be skipped because the user added it to an incorrect folder that has no owner.
			If OwnerObject = Undefined
				Or TypeOf(OwnerObject) = Type("CatalogRef.MetadataObjectIDs") Then
				Continue;
			EndIf;
			
			CurrentFile = FindRowByURI(FilesTreeRow.Href, FilesTable, "Href");
			
			If (CurrentFile = Undefined) OR (FilesTable.Find(CurrentFile.FileRef ,"FileRef") = Undefined) Then
				// This is a new file on the server, importing it.
				If NOT CheckUID1CAbility(FilesTreeRow.Href, String(New UUID), SynchronizationParameters) Then
					EventText = NStr("ru = 'Невозможно сохранение дополнительных свойств файла, он не будет загружен: %1'; en = 'Cannot download file %1 because an error occurred when saving its additional properties.'; pl = 'Nie można zapisać dodatkowych właściwości pliku, nie będzie on pobrany: %1';de = 'Es ist nicht möglich, zusätzliche Dateieigenschaften zu speichern, sie werden nicht geladen: %1';ro = 'Nu puteți salva proprietățile suplimentare ale fișierului, el nu va fi încărcat: %1';tr = 'Dosyanın ek özellikleri kaydedilemedi, dosya içe aktarılamaz: %1'; es_ES = 'Es imposible guardar las propiedades adicionales de los archivos, no será descargado: %1'");
					WriteToEventLogOfFilesSynchronization(StringFunctionsClientServer.SubstituteParametersToString(EventText, FilesTreeRow.FileName), SynchronizationParameters.Account, EventLogLevel.Error);
					Continue;
				EndIf;
				
				Try
					
					FileParameters = New Structure;
					FileParameters.Insert("FileName",                 FilesTreeRow.FileName);
					FileParameters.Insert("Href",                     FilesTreeRow.Href);
					FileParameters.Insert("Etag",                     FilesTreeRow.Etag);
					FileParameters.Insert("FileModificationDate",     FilesTreeRow.ModificationDate);
					FileParameters.Insert("FileLength",               FilesTreeRow.Length);
					FileParameters.Insert("ForUser",          SynchronizationParameters.FilesAuthor);
					FileParameters.Insert("OwnerObject",           OwnerObject);
					FileParameters.Insert("ExistingFileRef", Undefined);
					FileParameters.Insert("SynchronizationParameters",   SynchronizationParameters);
					ExistingFileRef = ImportFileFromServer(FileParameters);
					
					FilesTreeRow.UID1C = String(ExistingFileRef.Ref.UUID());
					
					NewFilesTableRow                    = FilesTable.Add();
					NewFilesTableRow.FileRef         = ExistingFileRef;
					NewFilesTableRow.DeletionMark    = False;
					NewFilesTableRow.Parent           = OwnerObject;
					NewFilesTableRow.IsFolder           = False;
					NewFilesTableRow.UID1C              = FilesTreeRow.UID1C;
					NewFilesTableRow.InInfobase          = False;
					NewFilesTableRow.IsOnServer      = True;
					NewFilesTableRow.ModifiedAtServer   = False;
					NewFilesTableRow.Href               = "";
					NewFilesTableRow.Etag               = "";
					NewFilesTableRow.ToHref             = FilesTreeRow.Href;
					NewFilesTableRow.ToEtag             = FilesTreeRow.Etag;
					NewFilesTableRow.ParentServer     = OwnerObject;
					NewFilesTableRow.Description       = FilesTreeRow.FileName;
					NewFilesTableRow.ServerDescription = FilesTreeRow.FileName;
					NewFilesTableRow.Processed          = True;
					NewFilesTableRow.IsFile            = True;
					
				Except
					WriteToEventLogOfFilesSynchronization(ErrorDescription(), SynchronizationParameters.Account, EventLogLevel.Error);
				EndTry;
				
			Else
				// Updating ToHref
				PreviousFIlesTableRow                    = FilesTable.Find(CurrentFile.FileRef,"FileRef");
				PreviousFIlesTableRow.ToHref             = FilesTreeRow.Href;
				PreviousFIlesTableRow.ToEtag             = FilesTreeRow.Etag;
				PreviousFIlesTableRow.ParentServer     = OwnerObject;
				PreviousFIlesTableRow.ServerDescription = FilesTreeRow.FileName;
				PreviousFIlesTableRow.IsOnServer      = True;
				PreviousFIlesTableRow.ModifiedAtServer   = NOT IsIdenticalURIPaths(PreviousFIlesTableRow.ToHref, PreviousFIlesTableRow.Href);
			EndIf;
			
		EndIf;
		
	EndDo;
	
EndProcedure

Procedure FillDataFromCloudService(FilesTreeRows, FilesTable, SynchronizationParameters, OwnerObject = Undefined)
	
	For each FilesTreeRow In FilesTreeRows Do
		
		If FilesTreeRow.IsFolder = True Then //folders
			// The folder is determined first by UID1C if not found, by the old Href, since The UID can be lost 
			// when editing, and the new Href cannot be found in the base yet if the UID was lost when edited 
			// and the folder is moved to another folder (Href has changed), then it will be imported into the 
			// new folder card. Search by Href is justified, because it is unique for each folder on the file server.
			CurrentFilesFolder = Undefined;
			// Theoretically, you can also search files by Etag, but the question of duplicates will arise, therefore, do not look further.
			
			If Not IsBlankString(FilesTreeRow.UID1C) Then
			
				Query = New Query;
				Query.Text = 
					"SELECT
					|	FilesSynchronizationWithCloudServiceStatuses.File
					|FROM
					|	InformationRegister.FilesSynchronizationWithCloudServiceStatuses AS FilesSynchronizationWithCloudServiceStatuses
					|WHERE
					|	FilesSynchronizationWithCloudServiceStatuses.UUID1C = &UUID1C";
					
				Query.SetParameter("UUID1C", New UUID(FilesTreeRow.UID1C));
				
				QueryResult = Query.Execute();
				
				DetailedRecordsSelection = QueryResult.Select();
				
				
				While DetailedRecordsSelection.Next() Do
					CurrentFilesFolder = DetailedRecordsSelection.File;
				EndDo;
				
			EndIf;
			
			If CurrentFilesFolder = Undefined Then
				CurrentFilesFolder = FindRowByURI(FilesTreeRow.Href, FilesTable, "Href");// can be marked for deletion, then it has no Href and it will not be found.
			EndIf; 
			
			If CurrentFilesFolder = Undefined OR FilesTable.Find(CurrentFilesFolder.Ref, "FileRef") = Undefined Then
				Continue;
			EndIf;
			
			If (CurrentFilesFolder <> Undefined) OR (FilesTable.Find(CurrentFilesFolder.Ref,"FileRef") <> Undefined) Then
				PreviousFIlesTableRow = FilesTable.Find(CurrentFilesFolder.Ref, "FileRef");
				
				PreviousFIlesTableRow.ToHref = FilesTreeRow.Href;
				PreviousFIlesTableRow.ToEtag = FilesTreeRow.Etag;
				PreviousFIlesTableRow.ParentServer = OwnerObject;
				PreviousFIlesTableRow.ServerDescription = FilesTreeRow.FileName;
				PreviousFIlesTableRow.IsOnServer = True;
				PreviousFIlesTableRow.ModifiedAtServer = NOT IsIdenticalURIPaths(PreviousFIlesTableRow.ToHref,PreviousFIlesTableRow.Href);
			EndIf; 
			// Now it is a parent for subordinate rows.
			FillDataFromCloudService(FilesTreeRow.Rows, FilesTable, SynchronizationParameters, CurrentFilesFolder.Ref);
			
		Else 
			// This is a file
			// The file is determined first by UID1C. If it is not found, by the old Href, since The UID can be 
			// lost when editing, and the new Href cannot be found in the base yet if the UID was lost when 
			// edited and the file is moved to another folder (Href has changed), then it will be imported into 
			// the new file card. Search by Href is justified, because it is unique for each file on the file server.
			
			CurrentFile = FindRowByURI(FilesTreeRow.Href, FilesTable, "Href");
			
			If (CurrentFile <> Undefined) AND (FilesTable.Find(CurrentFile.FileRef,"FileRef") <> Undefined) Then
				// Updating ToHref
				PreviousFIlesTableRow = FilesTable.Find(CurrentFile.FileRef,"FileRef");
				PreviousFIlesTableRow.ToHref = FilesTreeRow.Href;
				PreviousFIlesTableRow.ToEtag = FilesTreeRow.Etag;
				PreviousFIlesTableRow.ParentServer = OwnerObject;
				PreviousFIlesTableRow.ServerDescription = FilesTreeRow.FileName;
				PreviousFIlesTableRow.IsOnServer = True;
				PreviousFIlesTableRow.ModifiedAtServer = NOT IsIdenticalURIPaths(PreviousFIlesTableRow.ToHref,PreviousFIlesTableRow.Href);
			EndIf; 
			
		EndIf; 
		
	EndDo; 
	
EndProcedure

// Prepares an exchange structure containing values for the duration of the exchange session.
Function MainSynchronizationObjects(Account)

	ReturnStructure = New Structure("ServerAddressStructure, Response, Username, Password");
	Query = New Query;
	Query.Text = "SELECT
	               |	FileSynchronizationAccounts.Ref AS Account,
	               |	FileSynchronizationAccounts.Service AS ServerAddress,
	               |	FileSynchronizationAccounts.RootDirectory AS RootDirectory,
	               |	FileSynchronizationAccounts.FilesAuthor AS FilesAuthor
	               |FROM
	               |	Catalog.FileSynchronizationAccounts AS FileSynchronizationAccounts
	               |WHERE
	               |	FileSynchronizationAccounts.Ref = &Ref
	               |	AND FileSynchronizationAccounts.DeletionMark = FALSE";
	
	Query.SetParameter("Ref", Account);
	
	Result = Query.Execute().Unload();
	
	If Result.Count() = 0 Then
		Return Undefined;
	EndIf;
	
	For each ResultColumn In Result.Columns Do
		ReturnStructure.Insert(ResultColumn.Name,Result[0][ResultColumn.Name]);
	EndDo; 
	
	If Not IsBlankString(ReturnStructure.RootDirectory) Then
		ReturnStructure.ServerAddress = ReturnStructure.ServerAddress + "/" + ReturnStructure.RootDirectory;
	EndIf;
	
	If IsBlankString(ReturnStructure.FilesAuthor) Then
		ReturnStructure.FilesAuthor = Account;
	EndIf;
	
	ReturnStructure.ServerAddressStructure = URIStructureDecoded(ReturnStructure.ServerAddress);
	
	SetPrivilegedMode(True);
	ReturnStructure.Username =  Common.ReadDataFromSecureStorage(Account, "Username");
	ReturnStructure.Password = Common.ReadDataFromSecureStorage(Account);
	SetPrivilegedMode(False);
	
	Return ReturnStructure;

EndFunction

Procedure SynchronizeFilesWithCloudService(Account)
	
	SynchronizationParameters = MainSynchronizationObjects(Account);
	
	If SynchronizationParameters = Undefined Then
		Return;
	EndIf;
	
	EventText = NStr("ru = 'Начало синхронизации файлов с облачным сервисом.'; en = 'File synchronization with cloud service started.'; pl = 'Rozpocznij synchronizację plików z usługą w chmurze.';de = 'Starten Sie die Synchronisierung von Dateien mit dem Cloud-Service.';ro = 'Începutul sincronizării fișierelor cu cloud service.';tr = 'Dosyaları bulut hizmeti ile eşleşme başlangıcı'; es_ES = 'Inicio de la sincronización de archivos con el servicio de nube.'");
	WriteToEventLogOfFilesSynchronization(EventText, SynchronizationParameters.Account);
	
	ExecuteFilesSynchronizationWithCloudService(SynchronizationParameters);
	
	EventText = NStr("ru = 'Завершена синхронизация файлов с облачным сервисом'; en = 'File synchronization with cloud service completed'; pl = 'Synchronizacja plików z usługą w chmurze została zakończona';de = 'Die Synchronisation der Dateien mit dem Cloud-Service ist abgeschlossen.';ro = 'Sincronizarea fișierelor cu cloud service este finalizată';tr = 'Dosyaları bulut hizmeti ile eşleşmesi tamamlanmıştır'; es_ES = 'Sincronización de archivos con el servicio de nube terminada'");
	WriteToEventLogOfFilesSynchronization(EventText, SynchronizationParameters.Account);

EndProcedure

Procedure ExecuteFilesSynchronizationWithCloudService(SynchronizationParameters)
	
	ServerFilesTree = GenerateStructureOfServerFilesTree();
	ServerAddress        = EncodeURIByStructure(SynchronizationParameters.ServerAddressStructure);
	
	Cancel = False;
	SynchronizationCompleted = True;
	
	// Root record about the synchronization start
	RememberRefServerData("", "", "", False, Undefined, False, SynchronizationParameters.Account);
	
	ImportFilesTreeRecursively(ServerFilesTree.Rows, ServerAddress, SynchronizationParameters, Cancel);
	
	If Cancel = True Then
		
		EventText = NStr("ru = 'Не удалось загрузить структуру файлов с сервера, синхронизация не выполнена.'; en = 'Cannot synchronize the files because an error occurred when uploading the file structure from the server.'; pl = 'Nie można załadować struktury plików z serwera, synchronizacja nie powiodła się.';de = 'Die Dateistruktur konnte nicht vom Server geladen werden, die Synchronisation wird nicht durchgeführt.';ro = 'Eșec la încărcarea structurii fișierelor de pe server, sincronizarea nu este executată.';tr = 'Dosyaların yapısı sunucudan içe aktarılamadı, eşleşme yapılmadı.'; es_ES = 'No se ha podido descargar la estructura de archivos del servidor, sincronización no realizada.'");
		WriteToEventLogOfFilesSynchronization(EventText, SynchronizationParameters.Account, EventLogLevel.Error);
		Return;
		
	EndIf;
	
	// Comparing it with the file tree in the system, synchronization by UUID.
	FilesTable = SelectDataByRules(SynchronizationParameters.Account);
	
	For each TableRow In FilesTable Do
		TableRow.UID1C = String(TableRow.FileRef.UUID());
	EndDo;
	
	// Looping through the tree, importing and adding missing ones at the base to the table, and filling attributes from the server according to the old ones.
	ImportNewAttachedFiles(ServerFilesTree.Rows, FilesTable, SynchronizationParameters);
	
	CalculateLevelRecursively(FilesTable);
	FilesTable.Indexes.Add("FileRef");
	
	FilesTable.Sort("Level, ParentOrdering, IsFolder DESC");
	FilesTableIteration(FilesTable, SynchronizationParameters, ServerAddress);
	
	FilesTable.Sort("Level DESC, ParentOrdering, IsFolder DESC");
	FilesTableIteration(FilesTable, SynchronizationParameters, ServerAddress, True);
	
	WriteSynchronizationResult(SynchronizationParameters.Account, SynchronizationCompleted);
	
EndProcedure

Procedure FilesTableIteration(FilesTable, SynchronizationParameters, ServerAddress, IsFilesDeletion = False)
	
	For Each TableRow In FilesTable Do
		
		If TableRow.Processed Then
			SetSynchronizationStatus(TableRow, SynchronizationParameters.Account);
			Continue;
		EndIf;
		
		UpdateFileSynchronizationStatus = False;
		
		CreatedNewInBase            = (NOT ValueIsFilled(TableRow.Href)) AND (NOT ValueIsFilled(TableRow.ToHref));
		
		ModifiedInBase                = ValueIsFilled(TableRow.Changes);// something has changed
		ModifiedContentAtServer = ValueIsFilled(TableRow.ToEtag) AND (TableRow.Etag <> TableRow.ToEtag);// content has changed
		ModifiedAtServer            = ModifiedContentAtServer OR TableRow.ModifiedAtServer;// name, subordination or content has changed
		
		DeletedInBase                 = TableRow.DeletionMark;
		DeletedAtServer             = ValueIsFilled(TableRow.Href) AND NOT ValueIsFilled(TableRow.ToHref);
		
		BeginTransaction();
		
		Try
			
			If IsFilesDeletion Then
				If DeletedAtServer AND NOT DeletedInBase Then
					UpdateFileSynchronizationStatus = DeleteFileInCloudService(SynchronizationParameters, TableRow);
				EndIf;
			Else
				
				If CreatedNewInBase AND NOT DeletedInBase Then
					// Import file to the cloud server
					UpdateFileSynchronizationStatus = CreateFileInCloudService(ServerAddress, SynchronizationParameters, TableRow, FilesTable);
					
				ElsIf (ModifiedInBase OR ModifiedAtServer) AND NOT (DeletedInBase OR DeletedAtServer) Then
					
					If ModifiedAtServer AND NOT ModifiedInBase Then
						UpdateFileSynchronizationStatus = ModifyFileInCloudService(ModifiedContentAtServer, UpdateFileSynchronizationStatus, SynchronizationParameters, TableRow);
					EndIf;
					
				EndIf;
				
			EndIf;
			
			If UpdateFileSynchronizationStatus Then
				// Writing updates to the information register of statuses.
				If TableRow.DeletionMark Then
					// Deleting the last Href not to identify it again.
					DeleteRefServerData(TableRow.FileRef,  SynchronizationParameters.Account);
				Else
					SetSynchronizationStatus(TableRow, SynchronizationParameters.Account);
				EndIf;
			EndIf;
			
			CommitTransaction();
		Except
			RollbackTransaction();
			TableRow.SynchronizationDate = CurrentSessionDate();
			SetSynchronizationStatus(TableRow, SynchronizationParameters.Account);
			
			SynchronizationCompleted = False;
			ErrorText = StringFunctionsClientServer.SubstituteParametersToString(NStr("ru='Не удалось синхронизировать файл ""%1"" по причине:'; en = 'Cannot synchronize file ""%1"". Reason:'; pl = 'Nie udało się zsynchronizować pliku ""%1"" z powodu:';de = 'Die Datei ""%1"" konnte aus diesem Grund nicht synchronisiert werden:';ro = 'Eșec la sincronizarea fișierului ""%1"" din motivul:';tr = 'Dosya ""%1"" aşağıdaki nedenle eşleşmedi:'; es_ES = 'No se ha podido sincronizar el archivo ""%1"" a causa de:'"), String(TableRow.FileRef))
				+ Chars.LF + DetailErrorDescription(ErrorInfo());
			WriteToEventLogOfFilesSynchronization(ErrorText, SynchronizationParameters.Account, EventLogLevel.Error);
		EndTry;
		
	EndDo;
	
EndProcedure

Procedure WriteSynchronizationResult(Account, Val SynchronizationCompleted)
	
	RecordSet = InformationRegisters.FilesSynchronizationWithCloudServiceStatuses.CreateRecordSet();
	RecordSet.Filter.File.Set("", True);
	RecordSet.Filter.Account.Set(Account, True);
	RecordSet.Read();
	If RecordSet.Count() > 0 Then
		Record                             = RecordSet.Get(0);
		Record.SynchronizationDateCompletion = CurrentSessionDate();
		Record.Synchronized             = SynchronizationCompleted;
		RecordSet.Write();
	EndIf;

EndProcedure

Function GenerateStructureOfServerFilesTree()
	
	ServerFilesTree = New ValueTree;
	ServerFilesTree.Columns.Add("Href");
	ServerFilesTree.Columns.Add("UID1C");
	ServerFilesTree.Columns.Add("Etag");
	ServerFilesTree.Columns.Add("FileName");
	ServerFilesTree.Columns.Add("IsFolder");
	ServerFilesTree.Columns.Add("ModificationDate");
	ServerFilesTree.Columns.Add("Length");
	Return ServerFilesTree;
	
EndFunction

Function ModifyFileInCloudService(Val ModifiedContentAtServer, UpdateFileSynchronizationStatus, Val SynchronizationParameters, Val TableRow)
	
	// importing from the server
	If TableRow.IsFolder Then
		// It is possible to track renaming.
		TableRowObject                 = TableRow.FileRef.GetObject();
		TableRowObject.Description    = TableRow.ServerDescription;
		TableRowObject.Parent        = Undefined;
		TableRowObject.DeletionMark = False;
		TableRowObject.Write();
		
		TableRow.Description    = TableRow.ServerDescription;
		TableRow.Changes       = TableRow.FileRef;
		TableRow.Parent        = TableRow.ParentServer;
		TableRow.DeletionMark = False;
		
	Else
		
		FileNameStructure = New File(TableRow.ServerDescription);
		NewFileExtension = CommonClientServer.ExtensionWithoutPoint(FileNameStructure.Extension);
		// Importing only if the content has changed, that is, Etag, otherwise, updating attributes.
		If ModifiedContentAtServer OR (NewFileExtension <> TableRow.FileRef.Extension) Then
			
			FileParameters = New Structure;
			FileParameters.Insert("FileName",                 TableRow.ServerDescription);
			FileParameters.Insert("Href",                     TableRow.ToHref);
			FileParameters.Insert("Etag",                     TableRow.ToEtag);
			FileParameters.Insert("FileModificationDate",     Undefined);
			FileParameters.Insert("FileLength",               Undefined);
			FileParameters.Insert("ForUser",          SynchronizationParameters.FilesAuthor);
			FileParameters.Insert("OwnerObject",           TableRow.Parent);
			FileParameters.Insert("ExistingFileRef", TableRow.FileRef);
			FileParameters.Insert("SynchronizationParameters",   SynchronizationParameters);
			
			ImportFileFromServer(FileParameters, TableRow.IsFile);
			
		EndIf;
		
		TableRowObject                 = TableRow.FileRef.GetObject();
		TableRowObject.Description    = FileNameStructure.BaseName;
		TableRowObject.DeletionMark = False;
		TableRowObject.Write();
		
		TableRow.Description    = TableRow.ServerDescription;
		TableRow.Changes       = TableRow.FileRef;
		TableRow.Parent        = TableRow.ParentServer;
		TableRow.DeletionMark = False;
		
	EndIf;
	
	TableRow.Processed = True;
	TableRow.SynchronizationDate = CurrentSessionDate();
	
	EventText = NStr("ru = 'Обновлен объект в базе: %1'; en = 'Object %1 updated in the infobase'; pl = 'Zaktualizowany obiekt bazy danych: %1';de = 'Aktualisiertes Objekt in der Datenbank: %1';ro = 'Actualizat obiectul în bază: %1';tr = 'Veritabanındaki nesne güncellendi: %1'; es_ES = 'Objeto actualizado en la base: %1'");
	WriteToEventLogOfFilesSynchronization(StringFunctionsClientServer.SubstituteParametersToString(EventText, TableRow.Description), SynchronizationParameters.Account);
	
	Return True;
	
EndFunction

Function DeleteFileInCloudService(Val SynchronizationParameters, Val TableRow)
	
	Var EventText;
	
	If Not ValueIsFilled(TableRow.FileRef) Then
		Return False;
	EndIf;
	
	If Not IsRefToFile(TableRow.FileRef) Then
		TableRow.Processed = True;
		Return False;
	EndIf;
	
	BeginTransaction();
	Try
		
		UnlockFile(TableRow.FileRef);
		TableRow.FileRef.GetObject().SetDeletionMark(True, False);
		CommitTransaction();
		
	Except
		
		RollbackTransaction();
		EventText = NStr("ru = 'Не удалено в базе: %1'; en = 'Item %1 is not deleted from the infobase'; pl = 'Nieusunięte w bazie danych: %1';de = 'Nicht aus der Datenbank gelöscht: %1';ro = 'Eșec la ștergere în bază: %1';tr = 'Veritananında silinmedi: %1'; es_ES = 'No eliminado en la base: %1'");
		WriteToEventLogOfFilesSynchronization(StringFunctionsClientServer.SubstituteParametersToString(EventText, TableRow.Description), SynchronizationParameters.Account);
		Return False;
		
	EndTry;
	
	TableRow.DeletionMark = True;
	TableRow.Changes       = TableRow.FileRef;
	TableRow.Processed       = True;
	TableRow.SynchronizationDate  = CurrentSessionDate();
	
	EventText = NStr("ru = 'Удалено в базе: %1'; en = 'Item %1 deleted from the infobase'; pl = 'Usunięte w bazie danych: %1';de = 'Aus der Datenbank gelöscht: %1';ro = 'Șterse în bază: %1';tr = 'Veritabanında silindi: %1'; es_ES = 'Eliminado en la base: %1'");
	WriteToEventLogOfFilesSynchronization(StringFunctionsClientServer.SubstituteParametersToString(EventText, TableRow.Description), SynchronizationParameters.Account);
	
	Return True;

EndFunction

Function IsFile(File)
		
	Return Not IsFilesFolder(File);
	
EndFunction

Function IsRefToFile(OwnerObject)
	
	FilesTypesArray = Metadata.DefinedTypes.AttachedFile.Type.Types();
	Return FilesTypesArray.Find(TypeOf(OwnerObject)) <> Undefined;
	
EndFunction

Function CalculateTimeout(Size)
	
	Timeout = Int(Size / 8192); // size in megabytes * 128
	If Timeout < 10 Then
		Return 10;
	ElsIf Timeout > 43200 Then
		Return 43200;
	EndIf;
	
	Return Timeout;
	
EndFunction

Function CreateFileInCloudService(Val ServerAddress, Val SynchronizationParameters, Val TableRow, Val FilesTable)
	
	// sending the new one to server
	TableRow.Description = CommonClientServer.ReplaceProhibitedCharsInFileName(TableRow.Description, "-");
	TableRow.ToHref       = EndWithoutSlash(ServerAddress) + StartWithSlash(EndWithoutSlash(CalculateHref(TableRow,FilesTable)));
	
	If Common.ObjectIsFolder(TableRow.FileRef) Then
		CallMKCOLMethod(TableRow.ToHref, SynchronizationParameters);
	ElsIf TableRow.IsFolder Then
		CallMKCOLMethod(TableRow.ToHref, SynchronizationParameters);
	Else
		TableRow.ToEtag = CallPUTMethod(TableRow.ToHref, TableRow.FileRef, SynchronizationParameters, TableRow.IsFile);
	EndIf;
	
	UpdateFileUID1C(TableRow.ToHref, TableRow.UID1C, SynchronizationParameters);
	
	TableRow.ParentServer     = TableRow.Parent;
	TableRow.ServerDescription = TableRow.Description;
	TableRow.IsOnServer      = True;
	TableRow.Processed          = True;
	TableRow.SynchronizationDate  = CurrentSessionDate();
	
	ObjectIsFolder = Common.ObjectIsFolder(TableRow.FileRef);
	If Not TableRow.IsFile
		AND Not TableRow.IsFolder
		AND Not ObjectIsFolder Then
		If Common.ObjectAttributeValue(TableRow.FileRef, "BeingEditedBy") <> SynchronizationParameters.FilesAuthor Then
			LockFileForEditingServer(TableRow.FileRef, SynchronizationParameters.FilesAuthor);
		EndIf;
	ElsIf Not TableRow.IsFolder AND Not ObjectIsFolder Then
		FileData = FilesOperationsInternalServerCall.FileData(TableRow.FileRef);
		FilesOperationsInternalServerCall.LockFile(FileData, , , SynchronizationParameters.FilesAuthor);
	EndIf;
	
	EventText = NStr("ru = 'Создан объект в облачном сервисе %1'; en = 'Object %1 created in cloud service'; pl = 'Utworzono obiekt w usłudze chmurowej %1';de = 'Ein Objekt im Cloud-Service angelegt %1';ro = 'Obiectul în cloud service %1 este creat';tr = 'Bulut hizmetinde nesne oluşturuldu %1'; es_ES = 'Se ha creado un objeto en el servicio de nube %1'");
	WriteToEventLogOfFilesSynchronization(StringFunctionsClientServer.SubstituteParametersToString(EventText, TableRow.Description), SynchronizationParameters.Account);
	
	Return True;
	
EndFunction

Function SelectDataByRules(Account, Synchronize = TRUE)
	
	SynchronizationSettingQuiery = New Query;
	SynchronizationSettingQuiery.Text = 
	"SELECT
	|	FileSynchronizationSettings.FileOwner AS FileOwner,
	|	FileSynchronizationSettings.FileOwnerType AS FileOwnerType,
	|	MetadataObjectIDs.Ref AS OwnerID,
	|	CASE
	|		WHEN VALUETYPE(MetadataObjectIDs.Ref) <> VALUETYPE(FileSynchronizationSettings.FileOwner)
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS IsCatalogItemSetup,
	|	FileSynchronizationSettings.FilterRule AS FilterRule,
	|	FileSynchronizationSettings.IsFile AS IsFile,
	|	FileSynchronizationSettings.Account AS Account,
	|	FileSynchronizationSettings.Synchronize AS Synchronize
	|FROM
	|	InformationRegister.FileSynchronizationSettings AS FileSynchronizationSettings
	|		LEFT JOIN Catalog.MetadataObjectIDs AS MetadataObjectIDs
	|		ON (VALUETYPE(FileSynchronizationSettings.FileOwner) = VALUETYPE(MetadataObjectIDs.EmptyRefValue))
	|WHERE
	|	FileSynchronizationSettings.Account = &Account";
	
	SynchronizationSettingQuiery.SetParameter("Account", Account);
	SynchronizationSettings = SynchronizationSettingQuiery.Execute().Unload();
	
	FilesTable = Undefined;
	
	For Each Setting In SynchronizationSettings Do
		
		CatalogFiles = Common.MetadataObjectByID(Setting.FileOwnerType, False);
		If TypeOf(CatalogFiles) <> Type("MetadataObject") Then
			Continue;
		EndIf;
		If NOT Common.MetadataObjectAvailableByFunctionalOptions(CatalogFiles) Then
			Continue;
		EndIf;
		
		FilesTree = SelectDataBySynchronizationRule(Setting);
		If FilesTree = Undefined Then
			Continue;
		EndIf;
		
		If FilesTable = Undefined Then
			
			FilesTable = New ValueTable;
			For Each Column In FilesTree.Columns Do
				FilesTable.Columns.Add(Column.Name);
			EndDo;
			
			FilesTable.Columns.Add("Synchronize", New TypeDescription("Number"));
			
		EndIf;
		
		If Setting.IsCatalogItemSetup Then
			RootDirectory = Setting.OwnerID;
		Else
			RootDirectory = Setting.FileOwner;
		EndIf;
		
		For Each FilesRow In FilesTree.Rows Do
			
			NewRow = FilesTable.Add();
			NewRow.Synchronize = ?(Setting.Synchronize, 1, 0);
			FillPropertyValues(NewRow, FilesRow);
			
			If NewRow.FileRef = Undefined Then
				NewRow.FileRef = RootDirectory;
			EndIf;
			
			If ValueIsFilled(FilesRow.FileRef) Then
				
				FileMetadata = FilesRow.FileRef.Metadata();
				If Metadata.Catalogs.Contains(FileMetadata)
					AND FileMetadata.Hierarchical Then
				
					FileParent = Common.ObjectAttributeValue(FilesRow.FileRef, "Parent");
					If ValueIsFilled(FileParent) Then
						NewRow.Parent = FileParent;
					EndIf;
					
				EndIf;
				
			EndIf;
			
			If Not ValueIsFilled(NewRow.Parent) Then
				NewRow.Parent = RootDirectory;
			EndIf;
			
		EndDo;
		
	EndDo;
	
	ColumnsNames = New Array;
	For Each Column In FilesTable.Columns Do
		If Column.Name <> "Synchronize" Then
			ColumnsNames.Add(Column.Name);
		EndIf;
	EndDo;
	
	GroupingColumns = StrConcat(ColumnsNames, ",");
	FilesTable.GroupBy(GroupingColumns, "Synchronize");
	FilesTable.Sort("Synchronize" + ?(Not Synchronize, " Desc", ""));
	
	RowsToDelete = New Array;
	UnsynchronizedOwners = New Array;
	For Each Row In FilesTable Do
		
		If (Synchronize
			AND Row.Synchronize > 0)
			Or (Not Synchronize
			AND Row.Synchronize = 0) Then
			
			Break;
			
		EndIf;
		
		RowsToDelete.Add(Row);
		If Not Synchronize
			AND UnsynchronizedOwners.Find(Row.Parent) = Undefined Then
			
			UnsynchronizedOwners.Add(Row.Parent);
			
		EndIf;
		
	EndDo;
	
	For Each Row In RowsToDelete Do
		FilesTable.Delete(Row);
	EndDo;
	
	OwnersTable = FilesTable.Copy(, "Parent");
	OwnersTable.GroupBy("Parent");
	
	If Synchronize Then
		ObjectsToSynchronize = OwnersTable.UnloadColumn("Parent");
	Else
		
		ObjectsToSynchronize = New Array;
		For Each OwnerRow In OwnersTable Do
			
			If UnsynchronizedOwners.Find(OwnerRow.Parent) = Undefined Then
				ObjectsToSynchronize.Add(OwnerRow.Parent);
			EndIf;
			
		EndDo;
		
	EndIf;
	
	Query = New Query;
	Query.Text = 
	"SELECT DISTINCT
	|	CASE
	|		WHEN VALUETYPE(FileSynchronizationSettings.FileOwner) = TYPE(Catalog.MetadataObjectIDs)
	|			THEN FileSynchronizationSettings.FileOwner
	|		ELSE MetadataObjectIDs.Ref
	|	END AS FileRef,
	|	FileSynchronizationSettings.IsFile AS IsFile,
	|	FileSynchronizationSettings.Account AS Account,
	|	FileSynchronizationSettings.FileOwner AS FileOwner,
	|	FileSynchronizationSettings.FileOwnerType AS FileOwnerType
	|INTO TTVirtualRootFolders
	|FROM
	|	InformationRegister.FileSynchronizationSettings AS FileSynchronizationSettings
	|		LEFT JOIN Catalog.MetadataObjectIDs AS MetadataObjectIDs
	|		ON (VALUETYPE(FileSynchronizationSettings.FileOwner) = VALUETYPE(MetadataObjectIDs.EmptyRefValue))
	|WHERE
	|	FileSynchronizationSettings.Synchronize = &Synchronize
	|	AND FileSynchronizationSettings.Account = &Account
	|
	|INDEX BY
	|	Account
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TTVirtualRootFolders.FileRef AS FileRef,
	|	TTVirtualRootFolders.IsFile AS IsFile,
	|	FALSE AS DeletionMark,
	|	TRUE AS IsFolder,
	|	TRUE AS InInfobase,
	|	FALSE AS IsOnServer,
	|	FALSE AS Processed,
	|	FALSE AS ModifiedAtServer,
	|	FilesSynchronizationWithCloudServiceStatuses.Href AS Href,
	|	FilesSynchronizationWithCloudServiceStatuses.Etag AS Etag,
	|	FilesSynchronizationWithCloudServiceStatuses.UUID1C AS UUID1C,
	|	TTVirtualRootFolders.FileOwner AS FileOwner,
	|	TTVirtualRootFolders.FileOwnerType AS FileOwnerType
	|FROM
	|	TTVirtualRootFolders AS TTVirtualRootFolders
	|		LEFT JOIN InformationRegister.FilesSynchronizationWithCloudServiceStatuses AS FilesSynchronizationWithCloudServiceStatuses
	|		ON TTVirtualRootFolders.Account = FilesSynchronizationWithCloudServiceStatuses.Account
	|			AND TTVirtualRootFolders.FileRef = FilesSynchronizationWithCloudServiceStatuses.File
	|WHERE
	|	TTVirtualRootFolders.FileRef IN (&FilesOwners)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|DROP TTVirtualRootFolders";
		
	Query.SetParameter("Account", Account);
	Query.SetParameter("Synchronize", Synchronize);
	Query.SetParameter("FilesOwners", ObjectsToSynchronize);
	QueryResult = Query.Execute();
	
	DetailedRecordsSelection = QueryResult.Select();
	
	VirtualFoldersArray = New Array;
	
	While DetailedRecordsSelection.Next() Do
		If VirtualFoldersArray.Find(DetailedRecordsSelection.FileRef) <> Undefined Then
			Continue;
		EndIf;
		VirtualFoldersArray.Add(DetailedRecordsSelection.FileRef);
		VirtualRootFolderString = FilesTable.Add();
		FillPropertyValues(VirtualRootFolderString, DetailedRecordsSelection);
		VirtualRootFolderString.Description = StrReplace(DetailedRecordsSelection.FileRef.Synonym, ":", "");
	EndDo;
	
	Return FilesTable;
	
EndFunction

Function SelectDataBySynchronizationRule(SyncSetup)
	
	SettingsComposer = New DataCompositionSettingsComposer;
	
	ComposerSettings = SyncSetup.FilterRule.Get();
	If ComposerSettings <> Undefined Then
		SettingsComposer.LoadSettings(SyncSetup.FilterRule.Get());
	EndIf;
	
	DataCompositionSchema = New DataCompositionSchema;
	DataSource = DataCompositionSchema.DataSources.Add();
	DataSource.Name = "DataSource1";
	DataSource.DataSourceType = "Local";
	
	DataSet = DataCompositionSchema.DataSets.Add(Type("DataCompositionSchemaDataSetQuery"));
	DataSet.Name = "DataSet1";
	DataSet.DataSource = DataSource.Name;
	
	DataCompositionSchema.TotalFields.Clear();
	
	If SyncSetup.IsCatalogItemSetup Then
		FileOwner = SyncSetup.OwnerID;
		ExceptionItem = SyncSetup.FileOwner;
	Else
		FileOwner = SyncSetup.FileOwner;
		ExceptionItem = Undefined;
	EndIf;
	
	ExceptionsArray = New Array;
	QueryText = QueryTextToSynchronizeFIles(FileOwner, SyncSetup, ExceptionsArray, 
		ExceptionItem);
	If IsBlankString(QueryText) Then
		Return Undefined;
	EndIf;
			
	DataCompositionSchema.DataSets[0].Query = QueryText;
		
	Structure = SettingsComposer.Settings.Structure.Add(Type("DataCompositionGroup"));
	
	SelectedField = Structure.Selection.Items.Add(Type("DataCompositionSelectedField"));
	SelectedField.Field = New DataCompositionField("FileRef");
	
	SelectedField = Structure.Selection.Items.Add(Type("DataCompositionSelectedField"));
	SelectedField.Field = New DataCompositionField("Description");
	
	SelectedField = Structure.Selection.Items.Add(Type("DataCompositionSelectedField"));
	SelectedField.Field = New DataCompositionField("DeletionMark");
	
	SelectedField = Structure.Selection.Items.Add(Type("DataCompositionSelectedField"));
	SelectedField.Field = New DataCompositionField("Parent");
	
	SelectedField = Structure.Selection.Items.Add(Type("DataCompositionSelectedField"));
	SelectedField.Field = New DataCompositionField("IsFolder");
	
	SelectedField = Structure.Selection.Items.Add(Type("DataCompositionSelectedField"));
	SelectedField.Field = New DataCompositionField("InInfobase");
	
	SelectedField = Structure.Selection.Items.Add(Type("DataCompositionSelectedField"));
	SelectedField.Field = New DataCompositionField("IsOnServer");
	
	SelectedField = Structure.Selection.Items.Add(Type("DataCompositionSelectedField"));
	SelectedField.Field = New DataCompositionField("Changes");
	
	SelectedField = Structure.Selection.Items.Add(Type("DataCompositionSelectedField"));
	SelectedField.Field = New DataCompositionField("Href");
	
	SelectedField = Structure.Selection.Items.Add(Type("DataCompositionSelectedField"));
	SelectedField.Field = New DataCompositionField("Etag");
	
	SelectedField = Structure.Selection.Items.Add(Type("DataCompositionSelectedField"));
	SelectedField.Field = New DataCompositionField("Processed");
	
	SelectedField = Structure.Selection.Items.Add(Type("DataCompositionSelectedField"));
	SelectedField.Field = New DataCompositionField("SynchronizationDate");
	
	SelectedField = Structure.Selection.Items.Add(Type("DataCompositionSelectedField"));
	SelectedField.Field = New DataCompositionField("UID1C");
	
	SelectedField = Structure.Selection.Items.Add(Type("DataCompositionSelectedField"));
	SelectedField.Field = New DataCompositionField("ToHref");
	
	SelectedField = Structure.Selection.Items.Add(Type("DataCompositionSelectedField"));
	SelectedField.Field = New DataCompositionField("ToEtag");
	
	SelectedField = Structure.Selection.Items.Add(Type("DataCompositionSelectedField"));
	SelectedField.Field = New DataCompositionField("ParentServer");
	
	SelectedField = Structure.Selection.Items.Add(Type("DataCompositionSelectedField"));
	SelectedField.Field = New DataCompositionField("ServerDescription");
	
	SelectedField = Structure.Selection.Items.Add(Type("DataCompositionSelectedField"));
	SelectedField.Field = New DataCompositionField("ModifiedAtServer");
	
	SelectedField = Structure.Selection.Items.Add(Type("DataCompositionSelectedField"));
	SelectedField.Field = New DataCompositionField("Level");
	
	SelectedField = Structure.Selection.Items.Add(Type("DataCompositionSelectedField"));
	SelectedField.Field = New DataCompositionField("ParentOrdering");
	
	SelectedField = Structure.Selection.Items.Add(Type("DataCompositionSelectedField"));
	SelectedField.Field = New DataCompositionField("IsFile");
	
	SettingsComposer.Initialize(New DataCompositionAvailableSettingsSource(DataCompositionSchema));
	
	Parameter = SettingsComposer.Settings.DataParameters.Items.Find("Account");
	Parameter.Value = SyncSetup.Account;
	Parameter.Use = True;
	
	Parameter = SettingsComposer.Settings.DataParameters.Items.Find("OwnerType");
	Parameter.Value = TypeOf(FileOwner.EmptyRefValue);
	Parameter.Use = True;
	
	If ExceptionsArray.Count() > 0 Then
		Parameter = SettingsComposer.Settings.DataParameters.Items.Find("ExceptionsArray");
		Parameter.Value = ExceptionsArray;
		Parameter.Use = True;
	EndIf;
	
	If SyncSetup.IsCatalogItemSetup Then
		Parameter = SettingsComposer.Settings.DataParameters.Items.Find("ExceptionItem");
		Parameter.Value = ExceptionItem;
		Parameter.Use = True;
	EndIf;
	
	TemplateComposer         = New DataCompositionTemplateComposer;
	DataCompositionProcessor = New DataCompositionProcessor;
	OutputProcessor           = New DataCompositionResultValueCollectionOutputProcessor;
	ValuesTree            = New ValueTree;
	
	DataCompositionTemplate = TemplateComposer.Execute(DataCompositionSchema, SettingsComposer.Settings,
		, , Type("DataCompositionValueCollectionTemplateGenerator"));
	DataCompositionProcessor.Initialize(DataCompositionTemplate);
	OutputProcessor.SetObject(ValuesTree);
	OutputProcessor.Output(DataCompositionProcessor);
	
	Return ValuesTree;
	
EndFunction

Procedure ExecuteConnectionCheck(Account, CheckResult) Export 

	CheckResult = New Structure("ResultText, ResultProtocol, Cancel, ErrorCode","","",False);
	
	SynchronizationParameters = MainSynchronizationObjects(Account);
	
	ServerAddress = EncodeURIByStructure(SynchronizationParameters.ServerAddressStructure);
	
	EventText = NStr("ru = 'Начата проверка синхронизации файлов'; en = 'File synchronization check started'; pl = 'Rozpoczęto sprawdzanie synchronizacji plików';de = 'Dateisynchronisationsprüfung gestartet';ro = 'Verificarea sincronizării fișierelor este începută';tr = 'Dosya eşleşmesinin doğrulanması başladı'; es_ES = 'Prueba de sincronización de archivos empezada'") + " " + Account.Description;
	WriteToEventLogOfFilesSynchronization(EventText, SynchronizationParameters.Account);
	
	ReadDirectoryParameters(CheckResult,ServerAddress, SynchronizationParameters);
	
	EventText = NStr("ru = 'Завершена проверка синхронизации файлов'; en = 'File synchronization check completed'; pl = 'Kontrola synchronizacji plików zakończona';de = 'Dateisynchronisationsprüfung abgeschlossen';ro = 'Verificarea sincronizării fișierelor este finalizată';tr = 'Dosya eşleşmesinin doğrulanması tamamlandı'; es_ES = 'Prueba de sincronización de archivos finalizada'") + " " + Account.Description;
	WriteToEventLogOfFilesSynchronization(EventText, SynchronizationParameters.Account);

EndProcedure

Procedure UnlockLockedFilesBackground(CallParameters, AddressInStorage) Export
	DeleteUnsynchronizedFiles();
EndProcedure

Procedure DeleteUnsynchronizedFiles()
	
	Query = New Query;
	Query.Text = 
	"SELECT
	|	FileSynchronizationAccounts.Ref AS Account
	|FROM
	|	Catalog.FileSynchronizationAccounts AS FileSynchronizationAccounts
	|		LEFT JOIN InformationRegister.FileSynchronizationSettings AS FileSynchronizationSettings
	|		ON (FileSynchronizationSettings.Account = FileSynchronizationAccounts.Ref)
	|		LEFT JOIN InformationRegister.FilesSynchronizationWithCloudServiceStatuses AS FilesSynchronizationWithCloudServiceStatuses
	|		ON (FilesSynchronizationWithCloudServiceStatuses.Account = FileSynchronizationAccounts.Ref)
	|WHERE
	|	(FileSynchronizationAccounts.DeletionMark
	|			OR FileSynchronizationSettings.Synchronize <> TRUE)
	|	AND FilesSynchronizationWithCloudServiceStatuses.Account IS NOT NULL 
	|
	|GROUP BY
	|	FileSynchronizationAccounts.Ref";
	
	QueryResult = Query.Execute();
	
	SelectionAccount = QueryResult.Select();
	
	While SelectionAccount.Next() Do
		DeleteAccountUnsynchronizedFiles(SelectionAccount.Account);
	EndDo;
	
EndProcedure

// Releasing files captured by user accounts marked for deletion or with synchronization settings disabled.
//
Procedure DeleteAccountUnsynchronizedFiles(Account = Undefined)
	
	SynchronizationParameters = MainSynchronizationObjects(Account);
	
	If SynchronizationParameters = Undefined Then
		Return;
	EndIf;
	
	ServerAddress = EncodeURIByStructure(SynchronizationParameters.ServerAddressStructure);
	
	EventText = NStr("ru = 'Начало освобождения файлов, захваченных облачным сервисом.'; en = 'Releasing files locked by the cloud service started.'; pl = 'Początek wydania plików przechwyconych przez usługę w chmurze.';de = 'Beginn der Freigabe der vom Cloud-Service erfassten Dateien.';ro = 'Începutul lansării fișierelor ocupate de serviciul cloud.';tr = 'Bulut hizmeti tarafından meşgul edilen dosyaları serbest bırakma başlangıcı.'; es_ES = 'Inicio de liberación de archivos, capturados por el servicio de nube.'");
	WriteToEventLogOfFilesSynchronization(EventText, SynchronizationParameters.Account);
	
	Try
		
		ServerFilesTree = New ValueTree;
		ServerFilesTree.Columns.Add("Href");
		ServerFilesTree.Columns.Add("UID1C");
		ServerFilesTree.Columns.Add("Etag");
		ServerFilesTree.Columns.Add("FileName");
		ServerFilesTree.Columns.Add("IsFolder");
		ServerFilesTree.Columns.Add("ModificationDate");
		ServerFilesTree.Columns.Add("Length");
		
		Cancel = False;
		ImportFilesTreeRecursively(ServerFilesTree.Rows, ServerAddress, SynchronizationParameters, Cancel);
		If Cancel = True Then
			ErrorText = NStr("ru = 'При загрузке структуры файлов с сервера произошла ошибка, синхронизация не выполнена.'; en = 'Cannot synchronize the files because an error occurred when uploading the file structure from the server.'; pl = 'Wystąpił błąd podczas ładowania struktury plików z serwera, synchronizacja nie powiodła się.';de = 'Beim Laden der Dateistruktur vom Server ist ein Fehler aufgetreten, die Synchronisation wird nicht durchgeführt.';ro = 'La importul structurii fișierelor de pe server s-a produs eroare, sincronizarea nu este executată.';tr = 'Dosyaların yapısı sunucudan içe aktarılırken bir hata oluştu, eşleşme yapılamadı.'; es_ES = 'Al descargar la estructura del servidor se ha producido un error, sincronización no realizada.'");
			Raise ErrorText;
		EndIf;
		
		// Comparing it with the file tree in the system, synchronization by UUID.
		FilesTable = SelectDataByRules(Account, False);
		
		If FilesTable <> Undefined Then
		
			CalculateLevelRecursively(FilesTable);
			FilesTable.Sort("IsFolder ASC, Level DESC, ParentOrdering DESC");
			// Looping through the table and deciding what to do with files and folders.
			For Each TableRow In FilesTable Do
				
				If TableRow.Processed Then
					Continue;
				EndIf;
				
				BeginTransaction();
				
				Try
					
					If ValueIsFilled(TableRow.Href) Then
						// deleting on the server
						CallDELETEMethod(TableRow.Href, SynchronizationParameters);
						
						EventText = NStr("ru = 'Удален объект в облачном сервисе %1'; en = 'Object deleted in cloud service %1'; pl = 'Usunięto obiekt w usłudze chmurowej %1';de = 'Das Objekt im Cloud-Service wurde entfernt %1';ro = 'Obiectul în cloud service %1 este șters';tr = 'Bulun hizmetimdeki nesne silindi %1'; es_ES = 'Objeto eliminado en el servicio de nube %1'");
						WriteToEventLogOfFilesSynchronization(StringFunctionsClientServer.SubstituteParametersToString(EventText, TableRow.ServerDescription), SynchronizationParameters.Account);
					EndIf;
					
					TableRow.ParentServer = Undefined;
					TableRow.ServerDescription = "";
					TableRow.IsOnServer = False;
					TableRow.Processed = True;
					
					If Not TableRow.IsFolder Then
						UnlockFile(TableRow.FileRef);
					EndIf;
					
					// Deleting the last Href not to identify it again.
					DeleteRefServerData(TableRow.FileRef, Account);
					CommitTransaction();
					
				Except
					RollbackTransaction();
					WriteToEventLogOfFilesSynchronization(ErrorDescription(), SynchronizationParameters.Account, EventLogLevel.Error);
				EndTry;
				
			EndDo;
		EndIf;
		
	Except
		WriteToEventLogOfFilesSynchronization(ErrorDescription(), SynchronizationParameters.Account, EventLogLevel.Error);
	EndTry;
	
	EventText = NStr("ru = 'Завершено освобождения файлов, захваченных облачным сервисом'; en = 'Releasing files locked by the cloud service completed'; pl = 'Zakończono wydawanie plików przechwyconych przez usługę w chmurze';de = 'Die Freigabe von Dateien aus dem Cloud-Service ist abgeschlossen';ro = 'Este finalizată lansarea fișierelor ocupate de serviciul cloud';tr = 'Bulut hizmeti tarafından meşgul edilen dosyaları serbest bırakma tamamlandı.'; es_ES = 'Final de liberación de archivos, capturados por el servicio de nube'");
	WriteToEventLogOfFilesSynchronization(EventText, SynchronizationParameters.Account);
	
EndProcedure

Function EventLogFilterData(Account) Export
	
	Filter = New Structure;
	Filter.Insert("EventLogEvent", EventLogEventSynchronization());
	
	Query = New Query;
	Query.Text = "SELECT
	|	FilesSynchronizationWithCloudServiceStatuses.SessionNumber AS SessionNumber,
	|	FilesSynchronizationWithCloudServiceStatuses.SynchronizationDateStart AS SynchronizationDateStart,
	|	FilesSynchronizationWithCloudServiceStatuses.SynchronizationDateCompletion AS SynchronizationDateCompletion
	|FROM
	|	InformationRegister.FilesSynchronizationWithCloudServiceStatuses AS FilesSynchronizationWithCloudServiceStatuses
	|WHERE
	|	FilesSynchronizationWithCloudServiceStatuses.File = """"
	|	AND FilesSynchronizationWithCloudServiceStatuses.Account = &Account";
	
	Query.SetParameter("Account", Account);
	
	QueryResult = Query.Execute().Select();
	
	If QueryResult.Next() Then
		
		SessionsList = New ValueList;
		SessionsList.Add(QueryResult.SessionNumber);
		
		Filter.Insert("Data", Account);
		Filter.Insert("StartDate",                 QueryResult.SynchronizationDateStart);
		Filter.Insert("EndDate",              QueryResult.SynchronizationDateCompletion);
		Filter.Insert("Session",                      SessionsList);
	
	EndIf;
	
	Return Filter;
	
EndFunction

Function SynchronizationInfo(FileOwner = Undefined) Export
	
	Query = New Query;
	Query.Text = "SELECT TOP 1
		|	FilesSynchronizationWithCloudServiceStatuses.Account AS Account,
		|	FilesSynchronizationWithCloudServiceStatuses.SynchronizationDateStart AS SynchronizationDate,
		|	FilesSynchronizationWithCloudServiceStatuses.SessionNumber AS SessionNumber,
		|	FilesSynchronizationWithCloudServiceStatuses.Synchronized AS Synchronized,
		|	FilesSynchronizationWithCloudServiceStatuses.SynchronizationDateCompletion AS SynchronizationDateCompletion,
		|	FilesSynchronizationWithCloudServiceStatuses.Href AS Href,
		|	FilesSynchronizationWithCloudServiceStatuses.Account.Description AS AccountDescription,
		|	FilesSynchronizationWithCloudServiceStatuses.Account.Service AS Service
		|FROM
		|	InformationRegister.FilesSynchronizationWithCloudServiceStatuses AS FilesSynchronizationWithCloudServiceStatuses
		|		LEFT JOIN InformationRegister.FilesSynchronizationWithCloudServiceStatuses AS CloudServiceFileSynchronizationStatusesRoot
		|		ON FilesSynchronizationWithCloudServiceStatuses.Account = CloudServiceFileSynchronizationStatusesRoot.Account
		|			AND (CloudServiceFileSynchronizationStatusesRoot.File = """""""")
		|WHERE
		|	FilesSynchronizationWithCloudServiceStatuses.File = &File";
	
	Query.SetParameter("File", FileOwner);
	Table = Query.Execute().Unload();
	
	While Table.Count() > 0  Do
		Result = Common.ValueTableRowToStructure(Table[0]);
		Return Result;
	EndDo;
	
	Return New Structure();
	
EndFunction

Procedure UpdateVolumePathLinux() Export
	
	SetPrivilegedMode(True);
	
	Query = New Query;
	Query.Text = 
		"SELECT
		|	FileStorageVolumes.Ref
		|FROM
		|	Catalog.FileStorageVolumes AS FileStorageVolumes
		|WHERE
		|	FileStorageVolumes.FullPathLinux LIKE ""%/\""";
	
	Selection = Query.Execute().Select();
	
	While Selection.Next() Do
		
		BeginTransaction();
		Try
			DataLock = New DataLock;
			DataLockItem = DataLock.Add(Metadata.Catalogs.FileStorageVolumes.FullName());
			DataLockItem.SetValue("Ref", Selection.Ref);
			DataLock.Lock();
			Volume = Selection.Ref.GetObject();
			Volume.FullPathLinux = StrReplace(Volume.FullPathLinux , "/\", "/");
			Volume.Write();
			CommitTransaction();
		Except
			RollbackTransaction();
			MessageText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'Не удалось обработать том хранения файлов: %1 по причине:
				|%2'; 
				|en = 'Cannot process file storage volume %1. Reason:
				|%2'; 
				|pl = 'Nie udało się przetworzyć wolumin przechowywania plików: %1 z powodu:
				|%2';
				|de = 'Das Datei-Speichervolumen konnte nicht verarbeitet werden: %1 aus dem Grund:
				|%2';
				|ro = 'Eșec la procesarea volumului de stocare a fișierelor: %1 din motivul: 
				|%2';
				|tr = 'Dosya depolama birimi işlenemedi: %1 aşağıdaki nedenle: 
				|%2'; 
				|es_ES = 'No se ha podido procesar el tomo de guardar de archivos: %1 a causa de: 
				|%2'"), 
				Selection.Ref, DetailErrorDescription(ErrorInfo()));
			WriteLogEvent(InfobaseUpdate.EventLogEvent(), EventLogLevel.Warning,
				Selection.Ref.Metadata(), Selection.Ref, MessageText);
		EndTry;
		
	EndDo;
	
EndProcedure

// Returns the flag showing whether the node belongs to DIB exchange plan.
//
// Parameters:
//  InfobaseNode - ExchangePlanRef - an exchange plan node that requires receiving the function value.
// 
// Returns:
//   True - the node belongs to DIB exchange plan. Otherwise, False.
//
Function IsDistributedInfobaseNode(Val InfobaseNode)
	
	Return FilesOperationsInternalCached.IsDistributedInfobaseNode(
		InfobaseNode.Metadata().FullName());
	
EndFunction

#Region AccountingAudit
////////////////////////////////////////////////////////////////////////////////
// Accounting control.

Procedure SearchRefsToNonExistentFilesInVolumes(MetadataObject, CheckParameters, AvailableVolumes)
	
	ModuleAccountingAudit = Common.CommonModule("AccountingAudit");
	
	Attributes = MetadataObject.Attributes;
	
	QueryText =
	"SELECT TOP 1000
	|	MetadataObject.Ref AS ObjectWithIssue,
	|	&OwnerField AS Owner,
	|	REFPRESENTATION(MetadataObject.Ref) AS File,
	|	REFPRESENTATION(MetadataObject.Volume) AS Volume,
	|	MetadataObject.PathToFile AS PathToFile,
	|	FileStorageVolumes.FullPathLinux AS FullPathLinux,
	|	FileStorageVolumes.FullPathWindows AS FullPathWindows
	|FROM
	|	&MetadataObject AS MetadataObject
	|		INNER JOIN Catalog.FileStorageVolumes AS FileStorageVolumes
	|		ON MetadataObject.Volume = FileStorageVolumes.Ref
	|WHERE
	|	MetadataObject.Ref > &Ref
	|	AND MetadataObject.FileStorageType = VALUE(Enum.FileStorageTypes.InVolumesOnHardDrive)
	|	AND MetadataObject.Volume IN(&AvailableVolumes)
	|
	|ORDER BY
	|	MetadataObject.Ref";
	
	FullName    = MetadataObject.FullName();
	QueryText = StrReplace(QueryText, "&MetadataObject", FullName);
	If FullName = "Catalog.FilesVersions" Then
		QueryText = StrReplace(QueryText, "&OwnerField", "REFPRESENTATION(MetadataObject.Owner) ");
	Else
		QueryText = StrReplace(QueryText, "&OwnerField", "Undefined ");
	EndIf;
	
	Query = New Query(QueryText);
	Query.SetParameter("Ref",        Catalogs.FileStorageVolumes.EmptyRef());
	Query.SetParameter("AvailableVolumes", AvailableVolumes);
	
	Result = Query.Execute().Unload();
	
	While Result.Count() > 0 Do
		
		For Each ResultString In Result Do
			
			PathToFile = "";
			If Common.IsLinuxServer() Then
				PathToFile = ResultString.FullPathLinux + ResultString.PathToFile;
			Else
				PathToFile = ResultString.FullPathWindows + ResultString.PathToFile;
			EndIf;
			
			If Not ValueIsFilled(PathToFile) Then
				Continue;
			EndIf;
			
			CheckedFile = New File(PathToFile);
			If CheckedFile.Exist() Then
				Continue;
			EndIf;
				
			ObjectRef = ResultString.ObjectWithIssue;
			
			If ResultString.Owner <> Undefined Then
				IssueSummary = StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = 'Версия ""%1"" файла ""%2"" не существует в томе ""%3"".'; en = 'Cannot find version ""%1"" of file ""%2"" in volume ""%3.""'; pl = 'Wersja ""%1"" pliku ""%2"" nie istnieje w woluminie ""%3"".';de = 'Die Version ""%1"" der Datei ""%2"" existiert nicht im Volume ""%3"".';ro = 'Versiunea ""%1"" fișierului ""%2"" nu există în volum ""%3"".';tr = '""%1"" dosyanın ""%2"" sürümü ""%3"" biriminde mevcut değil.'; es_ES = 'La versión ""%1"" del archivo ""%2"" no existe en el tomo ""%3"".'"),
					ResultString.File, ResultString.Owner, ResultString.Volume);
			Else
				IssueSummary = StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = 'Файл ""%1"" не существует в томе ""%2"".'; en = 'Cannot find file ""%1"" in volume ""%2.""'; pl = 'Plik ""%1"" nie istnieje w woluminie ""%2"".';de = 'Die Datei ""%1"" existiert nicht im Volume ""%2"".';ro = 'Fișierul ""%1"" nu există în volumul ""%2"".';tr = 'Dosya ""%1"" ""%2"" biriminde mevcut değil.'; es_ES = 'El archivo ""%1"" no existe en el tomo ""%2"".'"),
					ResultString.File, ResultString.Volume);
			EndIf;
			
			Issue = ModuleAccountingAudit.IssueDetails(ObjectRef, CheckParameters);
			
			Issue.IssueSummary = IssueSummary;
			If Attributes.Find("EmployeeResponsible") <> Undefined Then
				Issue.Insert("EmployeeResponsible", Common.ObjectAttributeValue(ObjectRef, "EmployeeResponsible"));
			EndIf;
			
			ModuleAccountingAudit.WriteIssue(Issue, CheckParameters);

		EndDo;
		
		Query.SetParameter("Ref", ResultString.ObjectWithIssue);
		Result = Query.Execute().Unload();
		
	EndDo;
	
EndProcedure

Function CheckAttachedFilesObject(MetadataObject)
	
	If StrEndsWith(MetadataObject.Name, "AttachedFiles") Or MetadataObject.FullName() = "Catalog.FilesVersions" Then
		Attributes = MetadataObject.Attributes;
		If Attributes.Find("PathToFile") <> Undefined AND Attributes.Find("Volume") <> Undefined Then
			Return True;
		Else
			Return False;
		EndIf;
	Else
		Return False;
	EndIf;
	
EndFunction

Function AvailableVolumes(CheckParameters)
	
	AvailableVolumes = New Array;
	
	Query = New Query(
		"SELECT
		|	FileStorageVolumes.Ref AS VolumeRef,
		|	FileStorageVolumes.Description AS VolumePresentation,
		|	CASE
		|		WHEN &IsLinuxServer
		|			THEN FileStorageVolumes.FullPathLinux
		|		ELSE FileStorageVolumes.FullPathWindows
		|	END AS FullPath
		|FROM
		|	Catalog.FileStorageVolumes AS FileStorageVolumes");
	
	Query.SetParameter("IsLinuxServer", Common.IsLinuxServer());
	
	Result = Query.Execute().Select();
	While Result.Next() Do
		
		If Not VolumeAvailable(Result.VolumeRef, Result.VolumePresentation, Result.FullPath, CheckParameters) Then
			Continue;
		EndIf;
		
		AvailableVolumes.Add(Result.VolumeRef);
		
	EndDo;
	
	Return AvailableVolumes;
	
EndFunction

Function VolumeAvailable(Volume, VolumePresentation, Path, CheckParameters)
	
	If IsBlankString(Path) Then
		
		IssueSummary = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'У тома хранения файлов ""%1"" не задан путь к сетевому каталогу. Сохранение файлов в него невозможно.'; en = 'Cannot save files to file storage volume ""%1"" because it does not have a path to network directory.'; pl = 'W woluminie przechowywania plików ""%1"" nie określono ścieżkę do sieciowego katalogu. Zapisywanie plików w niego jest niemożliwe.';de = 'Das Datei-Speichervolumen ""%1"" hat keinen Pfad zum Netzwerkverzeichnis. Es ist nicht möglich, Dateien darin zu speichern.';ro = 'La volumul de stocare a fișierelor ""%1"" nu este specificată calea spre catalogul de rețea. Fișierele nu pot fi salvate în el.';tr = 'Dosya depolama birimin ""%1"" ağ kataloğu kısayolu bulunamadı.  Dosyaların depolanması mümkün değil.'; es_ES = 'Para el tomo de guarda de archivos ""%1"" no está especificada la ruta al catálogo de red. Is imposible guardar los archivos en él.'"), 
			VolumePresentation);
		WriteVolumeIssue(Volume, IssueSummary, CheckParameters);
		Return False;
		
	EndIf;
		
	TestDirectoryName = Path + "CheckAccess" + GetPathSeparator();
	
	Try
		CreateDirectory(TestDirectoryName);
		DeleteFiles(TestDirectoryName);
	Except
		
		IssueSummary = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Том хранения файлов ""%1"" недоступен по причине: 
				|%2
				|
				|Указанный сетевой каталог мог быть отключен или к нему отсутствуют права доступа.
				|Невозможна работа со всеми файлами, хранящимися в этом томе.'; 
				|en = 'File storage volume ""%1"" is unavailable. Reason: 
				|%2
				|
				|The specified network directory is unavailable or you do not have enough access rights.
				|Cannot access the files stored in the volume.'; 
				|pl = 'Wolumin przechowywania plików ""%1"" jest niedostępny z powodu: 
				|%2
				|
				|Podany w folder sieciowy mógł być wyłączony lub brak do niego prawa dostępu.
				|Nie jest możliwa praca ze wszystkimi plikami znajdującymi się w tym woluminie.';
				|de = 'Datei-Speichervolumen ""%1"" ist nicht verfügbar, da: 
				|%2
				|
				|Das angegebene Netzwerkverzeichnis möglicherweise deaktiviert wurde oder keine Zugriffsrechte darauf hat.
				|Es ist nicht möglich, mit allen in diesem Volume gespeicherten Dateien zu arbeiten.';
				|ro = 'Volumul de stocare a fișierelor ""%1"" nu este accesibil din motivul: 
				|%2
				|
				|Catalogul de rețea indicat putea fi dezactivat sau lipsesc drepturile de acces la el.
				|Lucrul cu toate fișierele stocate în acest volum nu este posibil.';
				|tr = 'Dosya depolama birimi ""%1"" nedeniyle kullanılamaz: 
				|%2
				|
				|belirtilen ağ dizini devre dışı bırakılabilir veya erişim hakları yoktur. 
				|Bu birimde depolanan tüm dosyalarla çalışmak imkansızdır.'; 
				|es_ES = 'El tomo de guarda de archivos ""%1"" no está disponible a causa de: 
				|%2
				|
				|Puede que el catálogo de red indicado haya sido desconectado o no haya derechos de acceso.
				|Es imposible usar todos los archivos guardados en este tomo.'"),
				Path, BriefErrorDescription(ErrorInfo()));
		IssueSummary = IssueSummary + Chars.LF;
		WriteVolumeIssue(Volume, IssueSummary, CheckParameters);
		Return False;
		
	EndTry;
	
	Return True;
	
EndFunction

Procedure WriteVolumeIssue(Volume, IssueSummary, CheckParameters)
	
	ModuleAccountingAudit = Common.CommonModule("AccountingAudit");
	
	Issue = ModuleAccountingAudit.IssueDetails(Volume, CheckParameters);
	Issue.IssueSummary = IssueSummary;
	ModuleAccountingAudit.WriteIssue(Issue, CheckParameters);
	
EndProcedure

#EndRegion

#Region TextExtraction
////////////////////////////////////////////////////////////////////////////////
// Extracting text for a full text search.

Function QueryTextForFilesWithUnextractedText(CatalogName, FilesNumberInSelection,
	GetAllFiles, AdditionalFields)
	
	If AdditionalFields Then
		QueryText =
		"SELECT TOP 1
		|	Files.Ref AS Ref,
		|	ISNULL(InformationRegisterFIleEncodings.Encoding, """") AS Encoding,
		|	Files.Extension AS Extension,
		|	Files.Description AS Description
		|FROM
		|	&CatalogName AS Files
		|		LEFT JOIN InformationRegister.FilesEncoding AS InformationRegisterFIleEncodings
		|		ON (InformationRegisterFIleEncodings.File = Files.Ref)
		|WHERE
		|	Files.TextExtractionStatus IN (
		|		VALUE(Enum.FileTextExtractionStatuses.NotExtracted),
		|		VALUE(Enum.FileTextExtractionStatuses.EmptyRef))";
	Else
		QueryText =
		"SELECT TOP 1
		|	Files.Ref AS Ref,
		|	ISNULL(InformationRegisterFIleEncodings.Encoding, """") AS Encoding
		|FROM
		|	&CatalogName AS Files
		|		LEFT JOIN InformationRegister.FilesEncoding AS InformationRegisterFIleEncodings
		|		ON (InformationRegisterFIleEncodings.File = Files.Ref)
		|WHERE
		|	Files.TextExtractionStatus IN (
		|		VALUE(Enum.FileTextExtractionStatuses.NotExtracted),
		|		VALUE(Enum.FileTextExtractionStatuses.EmptyRef))";
	EndIf;
	
	If Common.SubsystemExists("StandardSubsystems.DigitalSignature") Then
		If CatalogName = "FilesVersions" Then
			QueryText = QueryText + "
				|	AND NOT Files.Owner.Encrypted";
		Else
			QueryText = QueryText + "
				|	AND NOT Files.Encrypted";
		EndIf;
	EndIf;
	
	QueryText = StrReplace(QueryText, "TOP 1", ?(
		GetAllFiles,
		"",
		"TOP " + Format(FilesNumberInSelection, "NG=; NZ=")));
	
	QueryText = StrReplace(QueryText, "&CatalogName", "Catalog." + CatalogName);
	
	Return QueryText;
	
EndFunction

// Gets a full path to file on the hard drive.
// Parameters:
//  ObjectRef - CatalogRef.FilesVersions.
//                 CatalogRef.*AttachedFiles.
//
// Returns:
//   String - a full path to the file on the hard drive.
Function FileWithBinaryDataName(ObjectRef) 
	
	FullFileName = "";
	
	If ObjectRef.FileStorageType = Enums.FileStorageTypes.InInfobase Then
		
		FileStorage = FilesOperations.FileFromInfobaseStorage(ObjectRef);
		FileBinaryData = FileStorage.Get();
		
		If TypeOf(FileBinaryData) <> Type("BinaryData") Then
			Return "";
		EndIf;
		
		FullFileName = GetTempFileName(ObjectRef.Extension);
		FileBinaryData.Write(FullFileName);
	Else
		If NOT ObjectRef.Volume.IsEmpty() Then
			FullFileName = FullVolumePath(ObjectRef.Volume) + ObjectRef.PathToFile;
		EndIf;
	EndIf;
	
	Return FullFileName;
	
EndFunction

// Writes the extracted text.
//
// Parameters:
//  CurrentVersion  - CatalogRef.FilesVersions - a file version.
//
Procedure OnWriteExtractedText(CurrentVersion, FileLocked = True)
	
	// Write it if it is not a version.
	If Common.HasObjectAttribute("FileOwner", Metadata.FindByType(TypeOf(CurrentVersion))) Then
		InfobaseUpdate.WriteData(CurrentVersion);
		Return;
	EndIf;
	
	File = CurrentVersion.Owner;
	CurrentFileVersion = Common.ObjectAttributeValue(File, "CurrentVersion");
	If CurrentFileVersion = CurrentVersion.Ref Then
		Try
			LockDataForEdit(File);
		Except
			FileLocked = False;
			Raise;
		EndTry;
	EndIf;
	
	InfobaseUpdate.WriteData(CurrentVersion);
	
	If CurrentFileVersion = CurrentVersion.Ref Then
		FileObject = File.GetObject();
		FileObject.TextStorage = CurrentVersion.TextStorage;
		InfobaseUpdate.WriteData(FileObject);
	EndIf;
	
EndProcedure

// Extracts a text from a temporary storage or from binary data and returns extraction status.
Function ExtractText(Val TempTextStorageAddress, Val BinaryData = Undefined, Val Extension = Undefined) Export
	
	Result = New Structure("TextExtractionStatus, TextStorage");
	
	If IsTempStorageURL(TempTextStorageAddress) Then
		ExtractedText = RowFromTempStorage(TempTextStorageAddress);
		Result.TextExtractionStatus = Enums.FileTextExtractionStatuses.Extracted;
		Result.TextStorage = New ValueStorage(ExtractedText, New Deflation(9));
		Return Result;
	EndIf;
		
	If ExtractTextFilesOnServer() Then
		Result.TextExtractionStatus = Enums.FileTextExtractionStatuses.NotExtracted;
		Result.TextStorage = New ValueStorage("");
		Return Result; // The text will be extracted earlier in the scheduled job.
	EndIf;
	
	If Not Common.IsWindowsServer() Or BinaryData = Undefined Then
		Result.TextExtractionStatus = Enums.FileTextExtractionStatuses.NotExtracted;
		Result.TextStorage = New ValueStorage("");
		Return Result;
	EndIf;
	
	// The text is extracted right away, not in the scheduled job.
	TempFileName = GetTempFileName(Extension);
	BinaryData.Write(TempFileName);
	Result = ExtractTextFromFileOnHardDrive(TempFileName);
	Try
		DeleteFiles(TempFileName);
	Except
		WriteLogEvent(NStr("ru = 'Файлы.Извлечение текста'; en = 'Files.Extract text'; pl = 'Pliki. Ekstrakcja tekstu';de = 'Dateien. Text extrahieren';ro = 'Fișiere.Extragerea textului';tr = 'Dosyalar. Metin özütleme'; es_ES = 'Archivos.Extracción del texto'",	Common.DefaultLanguageCode()),
			EventLogLevel.Error,,, DetailErrorDescription(ErrorInfo()));
	EndTry;
	Return Result;
		
EndFunction

Function ExtractTextFromFileOnHardDrive(Val FileName, Val Encoding = Undefined) Export
	
	ExtractedText = "";
	Result = New Structure("TextExtractionStatus, TextStorage");
	Result.TextExtractionStatus = Enums.FileTextExtractionStatuses.FailedExtraction;
	
	Try
		File = New File(FileName);
		If Not File.Exist() Then
			Return Result;
		EndIf;
	Except
		Return Result;
	EndTry;
	
	Cancel = False;
	CommonSettings = FilesOperationsInternalCached.FilesOperationSettings().CommonSettings;
	
	FileNameExtension =
		CommonClientServer.GetFileNameExtension(FileName);
	
	FileExtensionInList = FilesOperationsInternalClientServer.FileExtensionInList(
		CommonSettings.TestFilesExtensionsList, FileNameExtension);
	
	If FileExtensionInList Then
		
		ExtractedText = FilesOperationsInternalClientServer.ExtractTextFromTextFile(
			FileName, Encoding, Cancel);
			
	Else
	
		Try
			Extracting = New TextExtraction(FileName);
			ExtractedText = Extracting.GetText();
		Except
			// If there is no handler to extract the text, this is not an error but a normal scenario. It is a normal case.
			ExtractedText = "";
			Cancel = True;
		EndTry;
		
		If IsBlankString(ExtractedText) Then
			
			FileNameExtension =
				CommonClientServer.GetFileNameExtension(FileName);
			
			FileExtensionInList = FilesOperationsInternalClientServer.FileExtensionInList(
				CommonSettings.FilesExtensionsListOpenDocument, FileNameExtension);
			
			If FileExtensionInList Then
				ExtractedText = FilesOperationsInternalClientServer.ExtractOpenDocumentText(FileName, Cancel);
			EndIf;
			
		EndIf;
		
	EndIf;
	
	If Not Cancel Then
		Result.TextExtractionStatus = Enums.FileTextExtractionStatuses.Extracted;
		Result.TextStorage = New ValueStorage(ExtractedText, New Deflation(9));
	EndIf;
	
	Return Result;
	
EndFunction

// Receives a row from a temporary storage (transfer from client to server, done via temporary 
// storage).
//
Function RowFromTempStorage(TempTextStorageAddress)
	
	If IsBlankString(TempTextStorageAddress) Then
		Return "";
	EndIf;
	
	TempFileName = GetTempFileName();
	GetFromTempStorage(TempTextStorageAddress).Write(TempFileName);
	
	TextFile = New TextReader(TempFileName, TextEncoding.UTF8);
	Text = TextFile.Read();
	TextFile.Close();
	
	Try
		DeleteFiles(TempFileName);
	Except
		WriteLogEvent(NStr("ru = 'Файлы.Извлечение текста'; en = 'Files.Extract text'; pl = 'Pliki. Ekstrakcja tekstu';de = 'Dateien. Text extrahieren';ro = 'Fișiere.Extragerea textului';tr = 'Dosyalar. Metin özütleme'; es_ES = 'Archivos.Extracción del texto'",	Common.DefaultLanguageCode()),
			EventLogLevel.Error,,,	DetailErrorDescription(ErrorInfo()));
	EndTry;
	
	Return Text;
	
EndFunction

Procedure ExtractTextFromFile(FileWithoutText, FileLocked, FileWithBinaryDataName)
	
	DataLock = New DataLock;
	DataLockItem = DataLock.Add(Metadata.FindByType(TypeOf(FileWithoutText.Ref)).FullName());
	DataLockItem.SetValue("Ref", FileWithoutText.Ref);
	Owner = Common.ObjectAttributeValue(FileWithoutText.Ref, "FileOwner");
	DataLockItem = DataLock.Add(Metadata.FindByType(TypeOf(Owner)).FullName());
	DataLockItem.SetValue("Ref", Owner);
	
	BeginTransaction();
	Try
		DataLock.Lock();
		LockDataForEdit(FileWithoutText.Ref, FileWithBinaryDataName);
		FileLocked = True;
		
		FileObject = FileWithoutText.Ref.GetObject();
		If FileObject <> Undefined Then
			
			NameWithFileExtension = FileObject.Description + "." + FileObject.Extension;
			If IsFilesOperationsItem(FileObject.Ref) Then
				ObjectMetadata = Metadata.FindByType(TypeOf(FileObject.Ref));
				AbilityToStoreVersions = Common.HasObjectAttribute("CurrentVersion", ObjectMetadata);
				If AbilityToStoreVersions AND ValueIsFilled(FileObject.CurrentVersion.Ref) Then
					FileWithBinaryDataName = FileWithBinaryDataName(FileObject.CurrentVersion.Ref);
				Else
					FileWithBinaryDataName = FileWithBinaryDataName(FileObject.Ref);
				EndIf;
			EndIf;
			
			TextExtractionResult = ExtractTextFromFileOnHardDrive(FileWithBinaryDataName, FileWithoutText.Encoding);
			FileObject.TextExtractionStatus = TextExtractionResult.TextExtractionStatus;
			FileObject.TextStorage = TextExtractionResult.TextStorage;
			
			OnWriteExtractedText(FileObject, FileLocked);
			
			If FileObject.FileStorageType <> Enums.FileStorageTypes.InInfobase Then
				FileWithBinaryDataName = "";
			EndIf;
			
		EndIf;
		
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;
	
EndProcedure

#EndRegion

#Region EventsSubscriptionsHandlers
////////////////////////////////////////////////////////////////////////////////
// Event subscription handlers.

// The "on write" file version subscription.
//
Procedure FilesVersionsOnWrite(Source, Cancel) Export
	
	If Source.DataExchange.Load Then
		WriteFileDataToRegisterDuringExchange(Source);
		Return;
	EndIf;
	
	If Source.AdditionalProperties.Property("FileRenaming") Then
		Return;
	EndIf;
	
	If Source.AdditionalProperties.Property("FileConversion") Then
		Return;
	EndIf;
	
	// Copying attributes from version to file.
	CurrentVersion = Source;
	If Not CurrentVersion.Ref.IsEmpty() Then
	
		FileRef = Source.Owner;
		
		FileAttributes = Common.ObjectAttributesValues(FileRef, 
			"PictureIndex, Size, CreationDate, Changed, Extension, Volume, PathToFile, UniversalModificationDate");
			
			If FileAttributes.Size <> CurrentVersion.Size 
				OR FileAttributes.CreationDate <> CurrentVersion.CreationDate
				OR FileAttributes.Extension <> CurrentVersion.Extension
				OR FileAttributes.Volume <> CurrentVersion.Volume
				OR FileAttributes.PathToFile <> CurrentVersion.PathToFile 
				OR FileAttributes.PictureIndex <> CurrentVersion.PictureIndex
				OR FileAttributes.UniversalModificationDate <> CurrentVersion.FileModificationDate Then
				BeginTransaction();
				Try
					DataLock = New DataLock;
					DataLockItem = DataLock.Add(Metadata.FindByType(TypeOf(FileRef)).FullName());
					DataLockItem.SetValue("Ref", FileRef);
					DataLock.Lock();
					FileObject = FileRef.GetObject();
					// Changing the picture index, it is possible that the version has appeared or the version picture index has changed.
					FileObject.PictureIndex = CurrentVersion.PictureIndex;
					
					// Copying attributes to speed up the restriction work at the level of records.
					FileObject.Size           = CurrentVersion.Size;
					FileObject.CreationDate     = CurrentVersion.CreationDate;
					FileObject.Changed          = CurrentVersion.Author;
					FileObject.Extension       = CurrentVersion.Extension;
					FileObject.Volume              = CurrentVersion.Volume;
					FileObject.PathToFile       = CurrentVersion.PathToFile;
					FileObject.FileStorageType = CurrentVersion.FileStorageType;
					FileObject.UniversalModificationDate = CurrentVersion.UniversalModificationDate;
					
					If Source.AdditionalProperties.Property("WriteSignedObject") Then
						FileObject.AdditionalProperties.Insert("WriteSignedObject",
							Source.AdditionalProperties.WriteSignedObject);
					EndIf;
					
					FileObject.Write();
					CommitTransaction();
				Except
					RollbackTransaction();
					Raise;
				EndTry;
			EndIf;
		
	EndIf;
	
	UpdateTextExtractionQueueState(Source.Ref, Source.TextExtractionStatus);
	
EndProcedure

// Subscription handler of the "before delete attached file" event.
Procedure BeforeDeleteAttachedFileServer(Val Ref,
                                                   Val FilesOwner,
                                                   Val Volume,
                                                   Val FileStorageType,
                                                   Val PathToFile) Export
	
	SetPrivilegedMode(True);
	
	If FilesOwner <> Undefined AND Not OwnerHasFiles(FilesOwner, Ref) Then
		
		BeginTransaction();
		Try
			DataLock = New DataLock;
			DataLockItem = DataLock.Add(Metadata.InformationRegisters.FilesExist.FullName());
			DataLockItem.SetValue("ObjectWithFiles", FilesOwner);
			DataLock.Lock();
			
			RecordManager = InformationRegisters.FilesExist.CreateRecordManager();
			RecordManager.ObjectWithFiles = FilesOwner;
			RecordManager.Read();
			If RecordManager.Selected() Then
				RecordManager.HasFiles = False;
				RecordManager.Write();
			EndIf;
			CommitTransaction();
		Except
			RollbackTransaction();
			Raise;
		EndTry;
		
	EndIf;
	
	If FileStorageType = Enums.FileStorageTypes.InVolumesOnHardDrive AND NOT Volume.IsEmpty() Then
		FullPath = FullVolumePath(Volume) + PathToFile;
		DeleteFileInVolume(FullPath);
	EndIf;
	
EndProcedure

// Checks the the current user right when using the limit for a folder or file.
// 
// 
// Parameters:
//  Right        - a right name.
//  RightsOwner - CatalogRef.FilesFolders, CatalogRef.Files,
//                 <reference to the owner>.
//
Function HasRight(Right, RightsOwner) Export
	
	If Not IsFilesFolder(RightsOwner) Then
		Return True; 
	EndIf;
	
	If Common.SubsystemExists("StandardSubsystems.AccessManagement") Then
		ModuleAccessManagement = Common.CommonModule("AccessManagement");
		
		If NOT ModuleAccessManagement.HasRight(Right, RightsOwner) Then
			Return False;
		EndIf;
	EndIf;
	
	Return True;
	
EndFunction

// Handler of the "Processing attached file filling check" attached file subscription.
//
Procedure AttachedFileFillingCheckDataProcessor(Source, Cancel) Export
	
	If Source.AdditionalProperties.Property("DeferredWriting")
		AND FilesOperations.FileBinaryData(Source.Ref, False) = Undefined Then
		
		Cancel = True;
		
	EndIf;
	
EndProcedure

Function OwnerHasFiles(Val FilesOwner, Val ExceptionFile = Undefined)
	
	SetPrivilegedMode(True);
	
	Query = New Query;
	Query.Parameters.Insert("FilesOwner", FilesOwner);
	
	QueryText =
	"SELECT
	|	AttachedFiles.Ref
	|FROM
	|	&CatalogName AS AttachedFiles
	|WHERE
	|	AttachedFiles.FileOwner = &FilesOwner";
	
	If ExceptionFile <> Undefined Then
		QueryText = QueryText + "
			|	AND AttachedFiles.Ref <> &Ref";
		
		Query.Parameters.Insert("Ref", ExceptionFile);
	EndIf;
	
	CatalogNames = FileStorageCatalogNames(FilesOwner);
	
	For each KeyAndValue In CatalogNames Do
		Query.Text = StrReplace(
			QueryText, "&CatalogName", "Catalog." + KeyAndValue.Key);
		
		If NOT Query.Execute().IsEmpty() Then
			Return True;
		EndIf;
	EndDo;
	
	Return False;
	
EndFunction

#EndRegion

#Region InfobaseUpdate

// Initial filling of the FilesOperations subsystem.
Procedure InitialFilling() Export
	
	TemplatesFolder = Catalogs.FilesFolders.Templates.GetObject();
	TemplatesFolder.Description = NStr("ru = 'Шаблоны файлов'; en = 'File templates'; pl = 'Szablony plików';de = 'Dateivorlagen';ro = 'Șabloanele fișierelor';tr = 'Dosya Şablonları'; es_ES = 'Modelos de archivos'");
	InfobaseUpdate.WriteObject(TemplatesFolder);
	
EndProcedure

// Fills in the VersionNumber(Number) from the Code(String) data in the FilesVersions.
Procedure FillVersionNumberFromCatalogCode() Export
	
	SetPrivilegedMode(True);
	
	Query = New Query;
	Query.Text = 
	"SELECT
	|	FilesVersions.Ref,
	|	FilesVersions.DeletionMark,
	|	FilesVersions.Code,
	|	FilesVersions.VersionNumber,
	|	FilesVersions.Owner.DeletionMark AS OwnerMarkedForDeletion,
	|	FilesVersions.Owner.CurrentVersion
	|FROM
	|	Catalog.FilesVersions AS FilesVersions";

	Selection = Query.Execute().Select();
	While Selection.Next() Do
		
		If Selection.VersionNumber = 0 Then 
			
			TypesDetails = New TypeDescription("Number");
			CodeNumber = TypesDetails.AdjustValue(Selection.Code);
			If CodeNumber <> 0 Then
				Object = Selection.Ref.GetObject();
				Object.VersionNumber = CodeNumber;
				
				// Correcting the situation that used to be acceptable, but now is not: the active version is marked for deletion, but the owner
				// - no.
				If Selection.DeletionMark = True AND Selection.OwnerMarkedForDeletion = False AND Selection.CurrentVersion = Selection.Ref Then
					Object.DeletionMark = False;
				EndIf;
				
				InfobaseUpdate.WriteData(Object);
			EndIf
			
		EndIf;
		
	EndDo;
	
EndProcedure

// Fills in the FileStorageType in the FilesVersions catalog by the InBase value.
Procedure FillFileStorageTypeInInfobase() Export
	
	SetPrivilegedMode(True);
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	FilesVersions.Ref
	|FROM
	|	Catalog.FilesVersions AS FilesVersions";
	
	Selection = Query.Execute().Select();
	While Selection.Next() Do
		Object = Selection.Ref.GetObject();
		
		If Object.FileStorageType.IsEmpty() Then
			Object.FileStorageType = Enums.FileStorageTypes.InInfobase;
			InfobaseUpdate.WriteData(Object);
		EndIf;
		
	EndDo;
	
EndProcedure

// In the FilesVersions and Files catalog it increases PictureIndex two times.
Procedure ChangeIconIndex() Export
	
	SetPrivilegedMode(True);
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	FilesVersions.Ref
	|FROM
	|	Catalog.FilesVersions AS FilesVersions";

	Selection = Query.Execute().Select();
	While Selection.Next() Do
		Object = Selection.Ref.GetObject();
		Object.DataExchange.Load = True;
		Object.PictureIndex = FilesOperationsInternalClientServer.GetFileIconIndex(Object.Extension);
		InfobaseUpdate.WriteData(Object);
	EndDo;
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	Files.Ref
	|FROM
	|	Catalog.Files AS Files";

	Selection = Query.Execute().Select();
	While Selection.Next() Do
		Object = Selection.Ref.GetObject();
		Object.DataExchange.Load = True;
		Object.PictureIndex = Object.CurrentVersion.PictureIndex;
		Object.Write();
	EndDo;
	
EndProcedure

// Called when updating to 1.0.6.3 and fills in the paths of FilesStorageVolumes.
Procedure FillVolumePaths() Export
	
	SetPrivilegedMode(True);
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	FileStorageVolumes.Ref
	|FROM
	|	Catalog.FileStorageVolumes AS FileStorageVolumes";

	Selection = Query.Execute().Select();
	While Selection.Next() Do
		Object = Selection.Ref.GetObject();
		Object.FullPathLinux = Object.FullPathWindows;
		InfobaseUpdate.WriteData(Object);
	EndDo;
	
EndProcedure

// Rewrites all items in the Files catalog.
Procedure OverwriteAllFiles() Export
	
	SetPrivilegedMode(True);
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	Files.Ref
	|FROM
	|	Catalog.Files AS Files";
	
	Selection = Query.Execute().Select();
	While Selection.Next() Do
		Object = Selection.Ref.GetObject();
		Object.Write();
	EndDo;
	
EndProcedure

// In the FilesVersions catalog fills in the FileModificationDate from the creation date.
Procedure FillFileModificationDate() Export
	
	SetPrivilegedMode(True);
	
	Query = New Query;
	Query.Text = 
		"SELECT
		|	FilesVersions.Ref
		|FROM
		|	Catalog.FilesVersions AS FilesVersions";

	Selection = Query.Execute().Select();
	While Selection.Next() Do
		
		Object = Selection.Ref.GetObject();
		
		If Object.FileModificationDate = Date("00010101000000") Then
			Object.FileModificationDate = Object.CreationDate;
			Object.Write();
		EndIf;
		
	EndDo;
	
	OverwriteAllFiles(); // To transfer values from the FileModificationDate from version to file.
	
EndProcedure

// Deletes record in the StoredVersionsFiles
//
// Parameters:
//   File - a reference to file.
//
Procedure DeleteRecordFromBinaryFilesDataRegister(File) Export
	
	SetPrivilegedMode(True);
	
	RecordSet = InformationRegisters.BinaryFilesData.CreateRecordSet();
	RecordSet.Filter.File.Set(File);
	RecordSet.Write();
	
EndProcedure

// Transfers the binary file from FileStorage of the FilesVersions to the StoredFilesVersions information register.
Procedure MoveFilesFromInfobaseToInformationRegister() Export
	
	SetPrivilegedMode(True);
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	FilesVersions.Ref
	|FROM
	|	Catalog.FilesVersions AS FilesVersions
	|WHERE
	|	FilesVersions.FileStorageType = &FileStorageType";
		
	Query.SetParameter("FileStorageType", Enums.FileStorageTypes.InInfobase);	

	Selection = Query.Execute().Select();
	While Selection.Next() Do
		
		Object = Selection.Ref.GetObject();
		
		DataToStorage = Object.FileStorage.Get();
		If TypeOf(DataToStorage) = Type("BinaryData") Then
			WriteFileToInfobase(Selection.Ref, Object.FileStorage);
			Object.FileStorage = New ValueStorage(""); // clearing the value
			InfobaseUpdate.WriteData(Object);
		EndIf;
		
	EndDo;
	
EndProcedure

// Fills in the LoanDate field with the current field.
Procedure FillLoanDate() Export
	
	SetPrivilegedMode(True);
	
	LoanDate = CurrentSessionDate();
	
	Query = New Query;
	Query.Text = 
		"SELECT
		|	Files.Ref
		|FROM
		|	Catalog.Files AS Files";
	
	Selection = Query.Execute().Select();
	While Selection.Next() Do
		If ValueIsFilled(Selection.Ref.BeingEditedBy) Then
			Object = Selection.Ref.GetObject();
			// To write a previously signed object.
			Object.AdditionalProperties.Insert("WriteSignedObject", True);
			Object.LoanDate = LoanDate;
			InfobaseUpdate.WriteData(Object);
		EndIf;
	EndDo;
	
EndProcedure

// Renames old rights to new ones.
Procedure ReplaceRightsInFileFolderRightsSettings() Export
	
	If NOT Common.SubsystemExists("StandardSubsystems.AccessManagement") Then
		Return;
	EndIf;
	
	ModuleAccessManagement = Common.CommonModule("AccessManagement");
	
	ReplacementTable = ModuleAccessManagement.TableOfRightsReplacementInObjectsRightsSettings();
	
	Row = ReplacementTable.Add();
	Row.OwnersType = Catalogs.FilesFolders.EmptyRef();
	Row.OldName = "ReadFoldersAndFiles";
	Row.NewName  = "Read";
	
	Row = ReplacementTable.Add();
	Row.OwnersType = Catalogs.FilesFolders.EmptyRef();
	Row.OldName = "AddFoldersAndFiles";
	Row.NewName  = "AddFiles";
	
	Row = ReplacementTable.Add();
	Row.OwnersType = Catalogs.FilesFolders.EmptyRef();
	Row.OldName = "FoldersAndFilesEdit";
	Row.NewName  = "FilesModification";
	
	Row = ReplacementTable.Add();
	Row.OwnersType = Catalogs.FilesFolders.EmptyRef();
	Row.OldName = "FoldersAndFilesEdit";
	Row.NewName  = "FoldersModification";
	
	Row = ReplacementTable.Add();
	Row.OwnersType = Catalogs.FilesFolders.EmptyRef();
	Row.OldName = "FolderAndFileDeletionMark";
	Row.NewName  = "FilesDeletionMark";
	
	ModuleAccessManagement.ReplaceRightsInObjectsRightsSettings(ReplacementTable);
	
EndProcedure

// Receives the number of versions with non-extracted text.
Procedure GetUnextractedTextVersionCount(AdditionalParameters, AddressInTempStorage) Export
	
	FilesCount = 0;
	
	FilesTypes = Metadata.DefinedTypes.AttachedFile.Type.Types();
	
	For Each Type In FilesTypes Do
		
		FilesDirectoryMetadata = Metadata.FindByType(Type);
		
		Query = New Query;
		
		QueryText = 
			"SELECT
			|	ISNULL(COUNT(Files.Ref), 0) AS FilesCount
			|FROM
			|	&CatalogName AS Files
			|WHERE
			|	Files.TextExtractionStatus IN (VALUE(Enum.FileTextExtractionStatuses.NotExtracted), VALUE(Enum.FileTextExtractionStatuses.EmptyRef))";
	
		If Common.SubsystemExists("StandardSubsystems.DigitalSignature") Then
			If Type = Type("CatalogRef.FilesVersions") Then
				QueryText = QueryText + "
					|	AND NOT Files.Owner.Encrypted";
			Else
				QueryText = QueryText + "
					|	AND NOT Files.Encrypted";
			EndIf;
		EndIf;
	
		QueryText = StrReplace(QueryText, "&CatalogName", "Catalog." + FilesDirectoryMetadata.Name);
		Query.Text = QueryText;
		
		Selection = Query.Execute().Select();
		If Selection.Next() Then
			FilesCount = FilesCount + Selection.FilesCount;
		EndIf
		
	EndDo;
	
	PutToTempStorage(FilesCount, AddressInTempStorage);
	
EndProcedure

// Registers objects that need update of records in the registry at the InfobaseUpdate exchange plan.
// 
//
Procedure RegisterObjectsToMoveDigitalSignaturesAndEncryptionCertificates(Parameters) Export
	
	TwoTabularSectionsQueryText =
	"SELECT
	|	Files.Ref AS Ref
	|FROM
	|	ObjectsTable AS Files
	|WHERE
	|	(TRUE IN
	|				(SELECT TOP 1
	|					TRUE
	|				FROM
	|					TabularSectionDeleteEncryptionCertificates AS DeleteEncryptionCertificates
	|				WHERE
	|					DeleteEncryptionCertificates.Ref = Files.Ref)
	|			OR TRUE IN
	|				(SELECT TOP 1
	|					TRUE
	|				FROM
	|					TabularSectionDeleteDigitalSignatures AS DeleteDigitalSignatures
	|				WHERE
	|					DeleteDigitalSignatures.Ref = Files.Ref))";
	
	TabularSectionsDeleteEncryptionResultsQueryText =
	"SELECT
	|	Files.Ref AS Ref
	|FROM
	|	ObjectsTable AS Files
	|WHERE
	|	TRUE IN
	|			(SELECT TOP 1
	|				TRUE
	|			FROM
	|				TabularSectionDeleteEncryptionCertificates AS DeleteEncryptionCertificates
	|			WHERE
	|				DeleteEncryptionCertificates.Ref = Files.Ref)";
	
	TabularSectionsDeleteDigitalSignaturesQueryText =
	"SELECT
	|	Files.Ref AS Ref
	|FROM
	|	ObjectsTable AS Files
	|WHERE
	|	TRUE IN
	|			(SELECT TOP 1
	|				TRUE
	|			FROM
	|				TabularSectionDeleteDigitalSignatures AS DeleteDigitalSignatures
	|			WHERE
	|				DeleteDigitalSignatures.Ref = Files.Ref)";
	
	Query = New Query;
	FullCatalogsNames = FullCatalogsNamesOfAttachedFiles();
	
	For Each FullName In FullCatalogsNames Do
		MetadataObject = Metadata.FindByFullName(FullName);
		
		HasTabularSectionDeleteEncryptionResults =
			MetadataObject.TabularSections.Find("DeleteEncryptionCertificates") <> Undefined;
		
		HasTabularSectionDeleteDigitalSignatures =
			MetadataObject.TabularSections.Find("DeleteDigitalSignatures") <> Undefined;
		
		If HasTabularSectionDeleteEncryptionResults AND HasTabularSectionDeleteDigitalSignatures Then
			CurrentQueryText = TwoTabularSectionsQueryText;
			
		ElsIf HasTabularSectionDeleteEncryptionResults Then
			CurrentQueryText = TabularSectionsDeleteEncryptionResultsQueryText;
			
		ElsIf HasTabularSectionDeleteDigitalSignatures Then
			CurrentQueryText = TabularSectionsDeleteDigitalSignaturesQueryText;
		Else 
			Continue;
		EndIf;
		
		If ValueIsFilled(Query.Text) Then
			Query.Text = Query.Text + "
			|
			|UNION ALL
			|
			|";
		EndIf;
		
		CurrentQueryText = StrReplace(CurrentQueryText, "ObjectsTable", FullName);
		
		CurrentQueryText = StrReplace(CurrentQueryText,
			"TabularSectionDeleteEncryptionCertificates", FullName + ".DeleteEncryptionCertificates");
		
		CurrentQueryText = StrReplace(CurrentQueryText,
			"TabularSectionDeleteDigitalSignatures", FullName + ".DeleteDigitalSignatures");
		
		Query.Text = Query.Text + CurrentQueryText;
	EndDo;
	
	RefsArray = Query.Execute().Unload().UnloadColumn("Ref"); 
	
	InfobaseUpdate.MarkForProcessing(Parameters, RefsArray);
	
EndProcedure

Procedure MoveDigitalSignaturesAndEncryptionCertificatesToInformationRegisters(Parameters) Export
	
	ProcessingCompleted = True;
	
	FullCatalogsNames = FullCatalogsNamesOfAttachedFiles();
	
	For Each FullCatalogName In FullCatalogsNames Do
		MoveDigitalSignaturesAndEncryptionCertificatesToInformationRegistersForTable(Parameters,
			FullCatalogName, ProcessingCompleted);
	EndDo;
	
	Parameters.ProcessingCompleted = ProcessingCompleted;
	
EndProcedure

// Allows you to move items of the DeleteDigitalSignatures and DeleteEncryptionCertificates tabular 
// sections to the DigitalSignatures and EncryptionCertificates information registers.
//
// Parameters:
//  UpdateParameters        - Structure - structure of deferred update handler parameters.
//
//  FullMetadataObjectName - String - a full name of metadata object, from which tabular section data is moved.
//                                        DeleteDigitalSignatures and DeleteEncryptionCertificates.
//  ProcessingCompleted         - Boolean - True if all data is processed when updating the infobase.
//
Procedure MoveDigitalSignaturesAndEncryptionCertificatesToInformationRegistersForTable(UpdateParameters, FullMetadataObjectName, ProcessingCompleted)
	
	MetadataObject = Metadata.FindByFullName(FullMetadataObjectName);
	
	If MetadataObject = Undefined Then
		Raise NStr("ru = 'Не указан объект для обработки электронных подписей и сертификатов шифрования.'; en = 'An object for processing digital signatures and encryption certificates is not specified.'; pl = 'Nie jest określony obiekt do obsługi podpisów elektronicznych i certyfikatów szyfrowania.';de = 'Das Objekt zur Verarbeitung von digitalen Signaturen und Verschlüsselungszertifikaten ist nicht spezifiziert.';ro = 'Nu este indicat obiectul pentru procesarea semnăturilor electronice și certificatelor de cifrare.';tr = 'E-imzaları ve şifreleme sertifikalarını işlemek için nesne belirtilmedi.'; es_ES = 'No está indicado un objeto de procesar las firmas electrónicas y los certificados de cifrado.'");
	EndIf;
	
	HasTabularSectionOfDigitalSignature = MetadataObject.TabularSections.Find("DeleteDigitalSignatures") <> Undefined;
	HasTabularSectionOfEncryptionCertificate = MetadataObject.TabularSections.Find("DeleteEncryptionCertificates") <> Undefined;
	
	ReferencesSelection = InfobaseUpdate.SelectRefsToProcess(UpdateParameters.Queue, FullMetadataObjectName);
	
	ObjectsProcessed = 0;
	ObjectsWithIssues = 0;
	
	RefsArray = New Array;
	
	BeginTransaction();
	Try
		While ReferencesSelection.Next() Do
			RefsArray.Add(ReferencesSelection.Ref);
		EndDo;
		
		If HasTabularSectionOfDigitalSignature Then
			MoveDigitalSignatureDataToInformationRegister(RefsArray,
				FullMetadataObjectName, MetadataObject);
		EndIf;
		
		If HasTabularSectionOfEncryptionCertificate Then
			MoveCertificatesDataToInformationRegister(RefsArray, FullMetadataObjectName);
		EndIf;
		
		For Each ObjectWithDigitalSignature In RefsArray Do
			InfobaseUpdate.MarkProcessingCompletion(ObjectWithDigitalSignature);
		EndDo;
		ObjectsProcessed = RefsArray.Count();
		
		CommitTransaction();
	Except
		RollbackTransaction();
		// If you cannot process an object, try again.
		ObjectsWithIssues = ObjectsWithIssues + RefsArray.Count();
		
		MessageText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Не удалось обработать объект: %1 по причине:
			           |%2'; 
			           |en = 'Cannot process object %1. Reason:
			           |%2'; 
			           |pl = 'Nie udało się przetworzyć obiekt: %1 z powodu:
			           |%2';
			           |de = 'Das Objekt konnte nicht verarbeitet werden: %1 aus folgendem Grund:
			           |%2';
			           |ro = 'Eșec la procesarea obiectului: %1 din motivul: 
			           |%2';
			           |tr = 'Nesne aşağıdaki nedenle işlenemedi: 
			           |%2 %1'; 
			           |es_ES = 'No se ha podido procesar el objeto: %1 a causa de:
			           |%2'"),
			MetadataObject,
			DetailErrorDescription(ErrorInfo()));
		
		WriteLogEvent(InfobaseUpdate.EventLogEvent(),
			EventLogLevel.Warning, MetadataObject, , MessageText);
	EndTry;
	
	If Not InfobaseUpdate.DataProcessingCompleted(UpdateParameters.Queue, FullMetadataObjectName) Then
		ProcessingCompleted = False;
	EndIf;
	
	If ObjectsProcessed = 0 AND ObjectsWithIssues <> 0 Then
		MessageText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Процедуре ПеренестиЭлектронныеПодписиИСертификатыШифрованияВРегистрыСведений не удалось обработать некоторые объекты (пропущены): %1'; en = 'The MoveDigitalSignaturesAndEncryptionCertificatesToInformationRegisters procedure cannot process some objects (skipped): %1.'; pl = 'Procedurze MoveDigitalSignaturesAndEncryptionCertificatesToInformationRegisters nie udało się opracować niektóre obiekty (pominięte): %1';de = 'Die Prozedur MoveDigitalSignaturesAndEncryptionCertificatesToInformationRegisters kann einige Objekte nicht verarbeiten (übersprungen): %1';ro = 'Procedura MoveDigitalSignaturesAndEncryptionCertificatesToInformationRegisters nu poate procesa unele obiecte (omis): %1';tr = 'MoveDigitalSignaturesAndEncryptionCertificatesToInformationRegisters işlemi bazı nesneleri işleyemedi (atlatıldı): %1'; es_ES = 'El procedimiento MoveDigitalSignaturesAndEncryptionCertificatesToInformationRegisters no ha podido procesar unos objetos (saltados): %1'"),
			ObjectsWithIssues);
		Raise MessageText;
	Else
		WriteLogEvent(InfobaseUpdate.EventLogEvent(),
			EventLogLevel.Information,
			MetadataObject,
			,
			StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'Процедура ПеренестиЭлектронныеПодписиИСертификатыШифрованияВРегистрыСведений обработала очередную порцию объектов: %1'; en = 'The MoveDigitalSignaturesAndEncryptionCertificatesToInformationRegisters procedure has processed objects: %1.'; pl = 'Procedura MoveDigitalSignaturesAndEncryptionCertificatesToInformationRegisters opracowała kolejną porcję obiektów: %1';de = 'Die Prozedur MoveDigitalSignaturesAndEncryptionCertificatesToInformationRegisters hat Objekte verarbeitet: %1';ro = 'Procedura MoveDigitalSignaturesAndEncryptionCertificatesToInformationRegisters a procesat obiecte: %1';tr = 'MoveDigitalSignaturesAndEncryptionCertificatesToInformationRegisters işlemi sıradaki nesne partisini işledi: %1'; es_ES = 'El procedimiento MoveDigitalSignaturesAndEncryptionCertificatesToInformationRegisters ha procesado una porción de objetos: %1'"),
				ObjectsProcessed));
	EndIf;
	
EndProcedure

// For the MoveDigitalSignaturesAndEncryptionCertificatesToInformationRegistersForTable procedure.
Procedure MoveDigitalSignatureDataToInformationRegister(ObjectsArray, FullMetadataObjectName, MetadataObject)
	
	SetPrivilegedMode(True);
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	TabularSectionDigitalSignatures.Ref AS SignedObject,
	|	TabularSectionDigitalSignatures.SignatureDate,
	|	TabularSectionDigitalSignatures.SignatureFileName,
	|	TabularSectionDigitalSignatures.Comment,
	|	TabularSectionDigitalSignatures.CertificateOwner,
	|	TabularSectionDigitalSignatures.Thumbprint,
	|	TabularSectionDigitalSignatures.Signature,
	|	TabularSectionDigitalSignatures.SignatureSetBy,
	|	TabularSectionDigitalSignatures.LineNumber AS SequenceNumber,
	|	TabularSectionDigitalSignatures.Certificate, 
	|	TabularSectionDigitalSignatures.SignatureCorrect AS SignatureCorrect,
	|	TabularSectionDigitalSignatures.SignatureValidationDate AS SignatureValidationDate
	|FROM
	|	" + FullMetadataObjectName + ".DeleteDigitalSignatures AS TabularSectionDigitalSignatures
	|WHERE
	|	TabularSectionDigitalSignatures.Ref IN(&ObjectsArray)
	|TOTALS
	|	BY SignedObject";
	
	If MetadataObject = Metadata.Catalogs.FilesVersions Then
		Query.Text = StrReplace(Query.Text,
			"TabularSectionDigitalSignatures.Ref AS SignedObject",
			"TabularSectionDigitalSignatures.Ref.Owner AS SignedObject");
	EndIf;
	
	TSAttributes = MetadataObject.TabularSections.DeleteDigitalSignatures.Attributes;
	
	If TSAttributes.Find("SignatureCorrect") = Undefined Then
		Query.Text = StrReplace(Query.Text, "TabularSectionDigitalSignatures.SignatureCorrect", "FALSE");
	EndIf;
	
	If TSAttributes.Find("SignatureValidationDate") = Undefined Then
		Query.Text = StrReplace(Query.Text, "TabularSectionDigitalSignatures.SignatureValidationDate", "Undefined");
	EndIf;
	
	Query.SetParameter("ObjectsArray", ObjectsArray);
	DataExported = Query.Execute().Unload(QueryResultIteration.ByGroups);
	
	For Each Row In DataExported.Rows Do
		If Not ValueIsFilled(Row.SignedObject) Then
			Continue;
		EndIf;
		RecordSet = InformationRegisters["DigitalSignatures"].CreateRecordSet();
		RecordSet.Filter.SignedObject.Set(Row.SignedObject);
		For Each Substring In Row.Rows Do
			FillPropertyValues(RecordSet.Add(), Substring);
		EndDo;
		// A parallel update with a non-standard mark of data processing execution is used.
		RecordSet.DataExchange.Load = True;
		RecordSet.AdditionalProperties.Insert("DisableObjectChangeRecordMechanism");
		RecordSet.DataExchange.Recipients.AutoFill = False;
		RecordSet.Write();
	EndDo;
	
EndProcedure

// For the MoveDigitalSignaturesAndEncryptionCertificatesToInformationRegistersForTable procedure.
Procedure MoveCertificatesDataToInformationRegister(ObjectsArray, FullMetadataObjectName)
	
	SetPrivilegedMode(True);
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	TabularSectionEncryptionCertificates.Ref AS EncryptedObject,
	|	TabularSectionEncryptionCertificates.Thumbprint,
	|	TabularSectionEncryptionCertificates.Certificate,
	|	TabularSectionEncryptionCertificates.LineNumber AS SequenceNumber,
	|	TabularSectionEncryptionCertificates.Presentation
	|FROM
	|	" + FullMetadataObjectName + ".DeleteEncryptionCertificates AS TabularSectionEncryptionCertificates
	|WHERE
	|	TabularSectionEncryptionCertificates.Ref IN(&ObjectsArray)
	|TOTALS
	|	BY EncryptedObject";
	
	Query.SetParameter("ObjectsArray", ObjectsArray);
	
	DataExported = Query.Execute().Unload(QueryResultIteration.ByGroups);
	
	For Each Row In DataExported.Rows Do
		RecordSet = InformationRegisters["EncryptionCertificates"].CreateRecordSet();
		RecordSet.Filter.EncryptedObject.Set(Row.EncryptedObject);
		For Each Substring In Row.Rows Do
			FillPropertyValues(RecordSet.Add(), Substring);
		EndDo;
		// A parallel update with a non-standard mark of data processing execution is used.
		RecordSet.DataExchange.Load = True;
		RecordSet.AdditionalProperties.Insert("DisableObjectChangeRecordMechanism");
		RecordSet.DataExchange.Recipients.AutoFill = False;
		RecordSet.Write();
	EndDo;
	
EndProcedure

Function FullCatalogsNamesOfAttachedFiles()
	
	Array = New Array;
	
	For Each AttachedFileType In Metadata.DefinedTypes.AttachedFile.Type.Types() Do
		FullName = Metadata.FindByType(AttachedFileType).FullName();
		If StrEndsWith(Upper(FullName), Upper("AttachedFilesVersions")) Then
			Continue;
		EndIf;
		Array.Add(Metadata.FindByType(AttachedFileType).FullName());
	EndDo;
	
	If Array.Find("Catalog.Files") = Undefined Then
		Array.Add("Catalog.Files");
	EndIf;
	
	If Array.Find("Catalog.FilesVersions") = Undefined Then
		Array.Add("Catalog.FilesVersions");
	EndIf;
	
	Return Array;
	
EndFunction

Function ObjectsToModifyOnTransferDigitalSignaturesAndEncryptionResults()
	
	Return Metadata.InformationRegisters["DigitalSignatures"].FullName() + ", "
	      + Metadata.InformationRegisters["EncryptionCertificates"].FullName();
	
EndFunction

#EndRegion

#EndRegion
