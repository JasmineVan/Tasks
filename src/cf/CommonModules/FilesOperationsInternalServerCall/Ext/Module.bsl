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

Procedure UpdateAttachedFile(Val AttachedFile, Val FileInfo) Export
	
	FilesOperations.RefreshFile(AttachedFile, FileInfo);
	
EndProcedure

// See the AddAttachedFile function in the FilesOperations module.
Function AppendFile(FileParameters,
                     Val FileAddressInTempStorage,
                     Val TempTextStorageAddress = "",
                     Val Details = "") Export
	
	Return FilesOperations.AppendFile(
		FileParameters,
		FileAddressInTempStorage,
		TempTextStorageAddress,
		Details);
	
EndFunction

// Receives file data and its binary data.
//
// Parameters:
//  FileOrVersionRef - CatalogRef.Files, CatalogRef.FilesVersions - a file or a file version.
//  SignatureAddress - an URL, containing the signature file address in a temporary storage.
//  FormID  - UUID - a form UUID.
//
// Returns:
//   Structure - FileData and the file itself as BinaryData and file signature as BinaryData.
//
Function FileDataAndBinaryData(FileOrVersionRef, SignatureAddress = Undefined, FormID = Undefined) Export
	
	ObjectMetadata = Metadata.FindByType(TypeOf(FileOrVersionRef));
	IsFilesCatalog = Common.HasObjectAttribute("FileOwner", ObjectMetadata);
	AbilityToStoreVersions = Common.HasObjectAttribute("CurrentVersion", ObjectMetadata);
	If AbilityToStoreVersions AND ValueIsFilled(FileOrVersionRef.CurrentVersion) Then
		VersionRef = FileOrVersionRef.CurrentVersion;
		FileData = FileData(FileOrVersionRef, VersionRef);
	ElsIf IsFilesCatalog Then
		VersionRef = FileOrVersionRef;
		FileData = FileData(FileOrVersionRef);
	Else
		VersionRef = FileOrVersionRef;
		FileData = FileData(FileOrVersionRef.Owner, VersionRef);
	EndIf;
	
	BinaryData = Undefined;
	
	FileStorageType = VersionRef.FileStorageType;
	If FileStorageType = Enums.FileStorageTypes.InVolumesOnHardDrive Then
		If NOT VersionRef.Volume.IsEmpty() Then
			FullPath = FilesOperationsInternal.FullVolumePath(VersionRef.Volume) + VersionRef.PathToFile; 
			Try
				BinaryData = New BinaryData(FullPath);
			Except
				// Record to the event log.
				ErrorMessage = FilesOperationsInternal.GenerateErrorTextOfGetFileFromVolumeForAdministrator(
					ErrorInfo(), VersionRef.Owner);
				
				WriteLogEvent(
					NStr("ru = 'Файлы.Открытие файла'; en = 'Files.Open file'; pl = 'Pliki.Otwórz plik';de = 'Dateien. Datei öffnen';ro = 'Fișiere.Deschiderea fișierului';tr = 'Dosyalar.  Dosyayı aç'; es_ES = 'Archivo.Abrir el archivo'",
					     Common.DefaultLanguageCode()),
					EventLogLevel.Error,
					Metadata.Catalogs.Files,
					VersionRef.Owner,
					ErrorMessage);
				
				Raise FilesOperationsInternal.ErrorFileNotFoundInFileStorage(
					VersionRef.FullDescr + "." + VersionRef.Extension);
			EndTry;
		EndIf;
	Else
		FileStorage = FilesOperations.FileFromInfobaseStorage(VersionRef);
		BinaryData = FileStorage.Get();
	EndIf;

	SignatureBinaryData = Undefined;
	If SignatureAddress <> Undefined Then
		SignatureBinaryData = GetFromTempStorage(SignatureAddress);
	EndIf;
	
	If FormID <> Undefined Then
		BinaryData = PutToTempStorage(BinaryData, FormID);
	EndIf;
	
	ReturnStructure = New Structure("FileData, BinaryData, SignatureBinaryData",
		FileData, BinaryData, SignatureBinaryData);
	
	Return ReturnStructure;
EndFunction

// Create a folder of files.
//
// Parameters:
//   Name - String - a folder name
//   Parent - DefinedType.AttachedFilesOwner - a parent folder.
//   User - CatalogRef.Users - a person responsible for a folder.
//   FilesGroup - DefinedTYpe.AttachedFile - a group (for hierarchical file catalogs).
//   WorkingDirectory - String - a folder working directory in file system.
//
// Returns:
//   CatalogRef.FilesFolders.
//
Function CreateFilesFolder(Name, Parent, User = Undefined, GroupOfFiles = Undefined, WorkingDirectory = Undefined) Export
	
	If IsDirectoryFiles(Parent) Then
		Folder = Catalogs.FilesFolders.CreateItem();
		Folder.EmployeeResponsible = ?(User <> Undefined, User, Users.AuthorizedUser());
		Folder.Parent = Parent;
	Else
		
		Folder = Catalogs[FilesOperationsInternal.FileStoringCatalogName(Parent)].CreateFolder();
		If TypeOf(Folder.Ref) = TypeOf(Parent) Then
			Folder.Parent = ?(GroupOfFiles = Undefined, Parent, GroupOfFiles);
			Folder.FileOwner = Common.ObjectAttributeValue(Parent, "FileOwner");
		Else
			Folder.Parent = GroupOfFiles;
			Folder.FileOwner = Parent;
		EndIf;
		
		Folder.Author = ?(User <> Undefined, User, Users.AuthorizedUser());
		
	EndIf;
	Folder.Description = Name;
	Folder.CreationDate = CurrentSessionDate();
	Folder.Fill(Undefined);
	Folder.Write();
	
	If ValueIsFilled(WorkingDirectory) Then
		SaveFolderWorkingDirectory(Folder.Ref, WorkingDirectory);
	EndIf;
	
	Return Folder.Ref;
	
EndFunction

// Creates a file in the database together with its version.
//
// Parameters:
//   Owner       - CatalogRef.FilesFolders, AnyRef - it will be set to the FileOwner attribute of 
//                    the created file.
//   FileInfo - Structure - see FilesOperationsClientServer.FIleInfo in the FileWIthVersion mode. 
//
// Returns:
//    CatalogRef.Files - a created file.
//
Function CreateFileWithVersion(FileOwner, FileInfo) Export
	
	BeginTransaction();
	Try
	
		// Creating a file card in the database.
		FileRef = CreateFile(FileOwner, FileInfo);
		Version = Catalogs.FilesVersions.EmptyRef();
		If FileInfo.StoreVersions Then
			// Creating a saved file version to save to the File card.
			Version = FilesOperationsInternal.CreateVersion(FileRef, FileInfo);
			// Inserting the reference to the version to the File card.
		EndIf;
		FilesOperationsInternal.UpdateVersionInFile(FileRef, Version, FileInfo.TempTextStorageAddress);
		
		If FileInfo.Encoding <> Undefined Then
			WriteFileVersionEncoding(
				?(Version = Catalogs.FilesVersions.EmptyRef(), FileRef, Version), FileInfo.Encoding);
		EndIf;
		
		HasSaveRight = AccessRight("SaveUserData", Metadata);
		If FileInfo.WriteToHistory AND HasSaveRight Then
			FileURL = GetURL(FileRef);
			UserWorkHistory.Add(FileURL);
		EndIf;
		
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;
	
	FilesOperationsOverridable.OnCreateFile(FileRef);
	
	Return FileRef;
	
EndFunction

// Releases the file.
//
// Parameters:
//   FileData - Structure - see FileData. 
//   UUID - UUID - a form UUID.
//
Procedure UnlockFile(FileData, UUID = Undefined) Export
	
	BeginTransaction();
	Try
		DataLock = New DataLock;
		DataLockItem = DataLock.Add(Metadata.FindByType(TypeOf(FileData.Ref)).FullName());
		DataLockItem.SetValue("Ref", FileData.Ref);
		DataLock.Lock();
		
		FileObject = FileData.Ref.GetObject();
		
		LockDataForEdit(FileObject.Ref, , UUID);
		FileObject.BeingEditedBy = Catalogs.Users.EmptyRef();
		FileObject.LoanDate = Date("00010101000000");
		FileObject.Write();
		UnlockDataForEdit(FileObject.Ref, UUID);
		
		FilesOperationsOverridable.OnUnlockFile(FileData, UUID);
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;
	
EndProcedure

Function UnlockFiles(Val Files) Export
	
	For Each AttachedFile In Files Do
		FilesOperationsInternal.UnlockFile(AttachedFile);
	EndDo;
	Return FilesOperationsInternal.LockedFilesCount();
	
EndFunction

// Locks a file for a checkout.
//
// Parameters:
//  FileData  - a structure with file data.
//  ErrorString - a string, where the error  reason is returned (for example, "File is locked by 
//                 other user").
//  UUID - a form UUID.
//
// Returns:
//   Boolean  - shows whether the operation is performed successfully.
//
Function LockFile(FileData, ErrorRow = "", UUID = Undefined, User = Undefined) Export
	
	ErrorRow = "";
	FilesOperationsOverridable.OnAttemptToLockFile(FileData, ErrorRow);
	If Not IsBlankString(ErrorRow) Then
		Return False;
	EndIf;
	
	BeginTransaction();
	Try
		DataLock = New DataLock;
		DataLockItem = DataLock.Add(Metadata.FindByType(TypeOf(FileData.Ref)).FullName());
		DataLockItem.SetValue("Ref", FileData.Ref);
		DataLock.Lock();
		
		FileObject = FileData.Ref.GetObject();
		
		LockDataForEdit(FileObject.Ref, , UUID);
		If User = Undefined Then
			FileObject.BeingEditedBy = Users.AuthorizedUser();
		Else
			FileObject.BeingEditedBy = User;
		EndIf;
		FileObject.LoanDate = CurrentSessionDate();
		FileObject.Write();
		UnlockDataForEdit(FileObject.Ref, UUID);
		
		CurrentVersionURL = FileData.CurrentVersionURL;
		OwnerWorkingDirectory = FileData.OwnerWorkingDirectory;
		
		FileData = FileData(FileData.Ref, ?(FileData.Version = FileData.Ref, Undefined, FileData.Version));
		FileData.CurrentVersionURL = CurrentVersionURL;
		FileData.OwnerWorkingDirectory = OwnerWorkingDirectory;
		
		FilesOperationsOverridable.OnLockFile(FileData, UUID);
		
		CommitTransaction();
		
	Except
		RollbackTransaction();
		Raise;
	EndTry;
	
	Return True;
	
EndFunction

// THe function returns the structure containing various info on the file and version.
//
// Parameters:
//  FileOrVersionRef  - CatalogRef.Files, CatalogRef.FilesVersions - a file or a file version.
//
// Returns:
//   Structure - a structure with file data.
//
Function FileData(FileRef, VersionRef = Undefined, FormID = Undefined, Val RaiseException = True) Export
	
	HasRightsToObject = Common.ObjectAttributesValues(FileRef, "Ref", True);
	
	If HasRightsToObject = Undefined Then
		Return Undefined;
	EndIf;
	InfobaseUpdate.CheckObjectProcessed(FileRef);
	
	FileObject = FileRef.GetObject();
	
	FileData = New Structure;
	FileData.Insert("Ref", FileObject.Ref);
	FileData.Insert("BeingEditedBy", FileObject.BeingEditedBy);
	FileData.Insert("Owner", FileObject.FileOwner);
	
	FileObjectMetadata = Metadata.FindByType(TypeOf(FileRef));
	
	If Common.HasObjectAttribute("CurrentVersion", FileObjectMetadata) AND ValueIsFilled(FileRef.CurrentVersion) Then
		CurrentFileVersion = FileObject.CurrentVersion;
		// Without the ability to store versions.
	Else
		CurrentFileVersion = FileRef;
	EndIf;
	
	If VersionRef <> Undefined Then
		FileData.Insert("Version", VersionRef);
	Else
		FileData.Insert("Version", CurrentFileVersion);
	EndIf;
	
	FileData.Insert("CurrentVersion", CurrentFileVersion);
	FileData.Insert("StoreVersions", FileObject.StoreVersions);
	FileData.Insert("DeletionMark", FileObject.DeletionMark);
	FileData.Insert("Encrypted", FileObject.Encrypted);
	FileData.Insert("SignedWithDS", FileObject.SignedWithDS);
	FileData.Insert("LoanDate", FileObject.LoanDate);
	
	If VersionRef = Undefined Then
		FileData.Insert("BinaryFileDataRef",
			PutToTempStorage(FilesOperations.FileBinaryData(FileRef, RaiseException), FormID));
		FileData.Insert("URL", GetURL(FileRef));
		FileData.Insert("CurrentVersionAuthor", FileRef.Changed);
		FileData.Insert("Encoding", FilesOperations.FileEncoding(FileRef, FileObject.Extension));
	Else
		FileData.Insert("BinaryFileDataRef",
			PutToTempStorage(FilesOperations.FileBinaryData(VersionRef, RaiseException), FormID));
		FileData.Insert("URL", GetURL(FileObject.Ref));
		FileData.Insert("CurrentVersionAuthor", VersionRef.Author);
		FileData.Insert("Encoding", FilesOperations.FileEncoding(VersionRef, FileObject.Extension));
	EndIf;
	
	If FileData.Encrypted Then
		
		If Common.SubsystemExists("StandardSubsystems.DigitalSignature") Then
			ModuleDigitalSignature = Common.CommonModule("DigitalSignature");
			EncryptionCertificatesArray = ModuleDigitalSignature.EncryptionCertificates(FileData.Ref);
		Else
			EncryptionCertificatesArray = Undefined;
		EndIf;
		
		FileData.Insert("EncryptionCertificatesArray", EncryptionCertificatesArray);
		
	EndIf;
	
	FileData.Insert("Internal", False);
	If CommonClientServer.HasAttributeOrObjectProperty(FileObject, "Internal") Then
		FileData.Internal = FileObject.Internal;
	EndIf;
	
	FilesOperationsInternal.FillAdditionalFileData(FileData, FileObject, VersionRef);
	
	Return FileData;
	
EndFunction

Function GetFileData(Val AttachedFile,
                            Val FormID = Undefined,
                            Val GetBinaryDataRef = True,
                            Val ForEditing = False) Export
	
	Return FilesOperations.FileData(AttachedFile, 
                    FormID,
                    GetBinaryDataRef,
                    ForEditing);
EndFunction

Function FileDataToPrint(Val AttachedFile, Val FormID = Undefined) Export
	
	FileData = GetFileData(AttachedFile, FormID);
	Extension = Lower(FileData.Extension);
	If Extension = "mxl" Then
		FileBinaryData = GetFromTempStorage(FileData.BinaryFileDataRef);
		TempFileName = GetTempFileName();
		FileBinaryData.Write(TempFileName);
		SpreadsheetDocument = New SpreadsheetDocument;
		SpreadsheetDocument.Read(TempFileName);
		SafeModeSet = SafeMode() <> False;
		
		If TypeOf(SafeModeSet) = Type("String") Then
			SafeModeSet = True;
		EndIf;
	
		If Not SafeModeSet Then
			DeleteFiles(TempFileName);
		EndIf;
		FileData.Insert("SpreadsheetDocument", SpreadsheetDocument);
	EndIf;
	
	Return FileData;
	
EndFunction

// THe function returns the structure containing various info on the file and version.
Function FileDataToOpen(FileRef, VersionRef, FormID = Undefined,
	OwnerWorkingDirectory = Undefined, FilePreviousURL = Undefined) Export
	
	HasRightsToObject = Common.ObjectAttributesValues(FileRef, "Ref", True);
	
	If HasRightsToObject = Undefined Then
		Return Undefined;
	EndIf;
	
	If FilePreviousURL <> Undefined Then
		If NOT IsBlankString(FilePreviousURL) AND IsTempStorageURL(FilePreviousURL) Then
			DeleteFromTempStorage(FilePreviousURL);
		EndIf;
	EndIf;
	
	FileRef = FileRef;
	VersionRef = VersionRef;
	If Not ValueIsFilled(VersionRef) 
		AND Common.HasObjectAttribute("CurrentVersion", Metadata.FindByType(TypeOf(FileRef)))
		AND ValueIsFilled(FileRef.CurrentVersion) Then
		
		VersionRef = FileRef.CurrentVersion;
		
	EndIf;
	FileData = FileData(FileRef, VersionRef, FormID);
	
	If OwnerWorkingDirectory = Undefined Then
		OwnerWorkingDirectory = FolderWorkingDirectory(FileData.Owner);
	EndIf;
	FileData.Insert("OwnerWorkingDirectory", OwnerWorkingDirectory);
	
	If FileData.OwnerWorkingDirectory <> "" Then
		FileName = CommonClientServer.GetNameWithExtension(
			FileData.FullVersionDescription, FileData.Extension);
		FullFileNameInWorkingDirectory = OwnerWorkingDirectory + FileName;
		FileData.Insert("FullFileNameInWorkingDirectory", FullFileNameInWorkingDirectory);
	EndIf;
	
	FileStorageType = FileData.Version.FileStorageType;
	
	If FileStorageType = Enums.FileStorageTypes.InVolumesOnHardDrive AND FileData.Version <> Undefined Then
		
		SetPrivilegedMode(True);
		
		FileDataVolume = Catalogs.FileStorageVolumes.EmptyRef();
		FileDataFilePath = "";
		FileDataVolume = FileData.Version.Volume;
		FileDataFilePath = FileData.Version.PathToFile;
		
		If NOT FileDataVolume.IsEmpty() Then
			FullPath = FilesOperationsInternal.FullVolumePath(FileDataVolume) + FileDataFilePath; 
			Try
				BinaryData = New BinaryData(FullPath);
				// Working with the current version only. To work with the non-current version, receive a reference at the GetURLToOpen.
				FileData.CurrentVersionURL = PutToTempStorage(BinaryData, FormID);
			Except
				// Record to the event log.
				RefToFile = ?(FileRef <> Undefined, FileRef, VersionRef);
				ErrorMessage = FilesOperationsInternal.GenerateErrorTextOfGetFileFromVolumeForAdministrator(
					ErrorInfo(), RefToFile);
				
				WriteLogEvent(
					NStr("ru = 'Файлы.Открытие файла'; en = 'Files.Open file'; pl = 'Pliki.Otwórz plik';de = 'Dateien. Datei öffnen';ro = 'Fișiere.Deschiderea fișierului';tr = 'Dosyalar.  Dosyayı aç'; es_ES = 'Archivo.Abrir el archivo'",
					     Common.DefaultLanguageCode()),
					EventLogLevel.Error,
					Metadata.Catalogs.Files,
					FileRef,
					ErrorMessage);
				
				If IsDirectoryFiles(FileData.Owner) Then
					OwnerPresentation = FullFolderPath(FileData.Owner);
				Else
					OwnerPresentation = FileData.Owner;
				EndIf;
				FileOwnerPresentation = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("ru = 'Присоединен к %1 : %2'; en = 'Attached to %1: %2'; pl = 'Dołączony do %1 : %2';de = 'Angehängt an %1 : %2';ro = 'Atașat la %1 : %2';tr = 'Aşağıdaki ile bağlı %1: %2'; es_ES = 'Conectado con %1 : %2'"),
					String(TypeOf(FileData.Owner)),
					OwnerPresentation);
				
				Raise FilesOperationsInternal.ErrorFileNotFoundInFileStorage(
					FileData.FullVersionDescription + "." + FileData.Extension,
					,
					FileOwnerPresentation);
			EndTry;
		EndIf;
	EndIf;
	
	FilePreviousURL = FileData.CurrentVersionURL;
	
	Return FileData;
	
EndFunction

Function ImageFieldUpdateData(FileRef, DataGetParameters) Export
	
	FileData = ?(ValueIsFilled(FileRef), GetFileData(FileRef, DataGetParameters), Undefined);
	
	UpdateData = New Structure;
	UpdateData.Insert("FileData",   FileData);
	UpdateData.Insert("TextColor",    StyleColors.NotSelectedPictureTextColor);
	UpdateData.Insert("FileCorrupt", False);
	
	If FileData <> Undefined
		AND GetFromTempStorage(FileData.BinaryFileDataRef) = Undefined Then
		
		UpdateData.FileCorrupt = True;
		UpdateData.TextColor    = StyleColors.ErrorNoteText;
		
	EndIf;
	
	Return UpdateData;
	
EndFunction

#Region ObsoleteProceduresAndFunctions

// Obsolete. Use FilesOperations.DefiineAttachedFileForm.
Procedure DetermineAttachedFileForm(Source,
                                                      FormKind,
                                                      Parameters,
                                                      SelectedForm,
                                                      AdditionalInformation,
                                                      StandardProcessing) Export
	
	FilesOperations.DetermineAttachedFileForm(Source,
		FormKind,
		Parameters,
		SelectedForm,
		AdditionalInformation,
		StandardProcessing);
		
EndProcedure

#EndRegion

#EndRegion

#Region Private

// Saves the path to the user's working directory to the settings.
//
// Parameters:
//  DirectoryName - String - a file directory name.
//
Procedure SetUserWorkingDirectory(DirectoryName) Export
	
	SetPrivilegedMode(True);
	CommonServerCall.CommonSettingsStorageSave(
		"LocalFileCache", "PathToLocalFileCache", DirectoryName,,, True);
	
EndProcedure

Function IsDirectoryFiles(FilesOwner) Export
	
	Return FilesOperationsInternal.FileStoringCatalogName(FilesOwner) = "Files";
	
EndFunction

Function FileStoringCatalogName(FilesOwner) Export
	
	Return FilesOperationsInternal.FileStoringCatalogName(FilesOwner);
	
EndFunction

// Creates a file in the infobase.
//
// Parameters:
//   Owner       - CatalogRef.FilesFolders, AnyRef - it will be set to the FileOwner attribute of 
//                    the created file.
//   FileInfo - Structure - see FilesOperationsClientServer.FIleInfo in the File mode. 
//
// Returns:
//    CatalogRef.Files - a created file.
//
Function CreateFile(Val Owner, Val FileInfo)
	
	File = Catalogs[FileInfo.FilesStorageCatalogName].CreateItem();
	File.FileOwner = Owner;
	File.Description = FileInfo.BaseName;
	File.Author = ?(FileInfo.Author <> Undefined, FileInfo.Author, Users.AuthorizedUser());
	File.CreationDate = CurrentSessionDate();
	File.Details = FileInfo.Comment;
	File.PictureIndex = FilesOperationsInternalClientServer.GetFileIconIndex(Undefined);
	File.StoreVersions = FileInfo.StoreVersions;
	
	FullTextSearchUsing = Metadata.ObjectProperties.FullTextSearchUsing.Use;
	If Metadata.Catalogs[FileInfo.FilesStorageCatalogName].FullTextSearch = FullTextSearchUsing Then
	
		If TypeOf(FileInfo.TempTextStorageAddress) = Type("ValueStorage") Then
			// When creating a File from a template, the value storage is copied directly.
			File.TextStorage = FileInfo.TempTextStorageAddress;
		ElsIf Not IsBlankString(FileInfo.TempTextStorageAddress) Then
			TextExtractionResult = FilesOperationsInternal.ExtractText(FileInfo.TempTextStorageAddress); 
			File.TextStorage = TextExtractionResult.TextStorage;
			File.TextExtractionStatus = TextExtractionResult.TextExtractionStatus;
		EndIf;
		
	Else
		File.TextStorage = New ValueStorage("");
		File.TextExtractionStatus = Enums.FileTextExtractionStatuses.NotExtracted;
	EndIf;
	
	File.Fill(Undefined);
	File.Write();
	Return File.Ref;
	
EndFunction

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
Function RefreshFileObject(FileRef,
	FileInfo,
	VersionRef = Undefined,
	UUIDOfForm = Undefined,
	User = Undefined)
	
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
	
	FilesOperationsInternal.CheckExtentionOfFileToDownload(FileInfo.ExtensionWithoutPoint);
	
	CurrentVersionSize = 0;
	BinaryData = Undefined;
	CurrentVersionFileStorageType = Enums.FileStorageTypes.InInfobase;
	CurrentVersionVolume = Undefined;
	CurrentVersionFilePath = Undefined;
	
	CatalogMetadata = Metadata.FindByType(TypeOf(FileRef));
	CatalogSupportsPossibitityToStoreVersions = Common.HasObjectAttribute("CurrentVersion", CatalogMetadata);
	
	VersionRefToCompareSize = VersionRef;
	If VersionRef <> Undefined Then
		VersionRefToCompareSize = VersionRef;
	ElsIf CatalogSupportsPossibitityToStoreVersions AND ValueIsFilled(FileRef.CurrentVersion) Then
		VersionRefToCompareSize = FileRef.CurrentVersion;
	Else
		VersionRefToCompareSize = FileRef;
	EndIf;
	
	PreVersionEncoding = FilesOperationsInternal.GetFileVersionEncoding(VersionRefToCompareSize);
	
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
				FullPath = FilesOperationsInternal.FullVolumePath(CurrentVersionVolume) + CurrentVersionFilePath; 
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
	
	If VersionRef = Undefined Then
		Version = FileRef.GetObject();
	EndIf;
	
	LockDataForEdit(Version.Ref, , UUIDOfForm);
	VersionLocked = True;
	
	// Deleting file from the hard drive and replacing it with the new one.
	If Version.FileStorageType = Enums.FileStorageTypes.InVolumesOnHardDrive Then
		If NOT Version.Volume.IsEmpty() Then
			FullPath = FilesOperationsInternal.FullVolumePath(Version.Volume) + Version.PathToFile; 
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
	
	If User = Undefined Then
		Version.Changed = Users.AuthorizedUser();
	Else
		Version.Changed = User;
	EndIf;
	Version.UniversalModificationDate = ModificationTimeUniversal;
	Version.Size                       = FileInfo.Size;
	Version.Description                 = FileInfo.BaseName;
	Version.Details                     = FileInfo.Comment;
	Version.Extension                   = CommonClientServer.ExtensionWithoutPoint(FileInfo.ExtensionWithoutPoint);
	
	FilesStorageTyoe = FilesOperationsInternal.FilesStorageTyoe();
	Version.FileStorageType = FilesStorageTyoe;
	
	If BinaryData = Undefined Then
		BinaryData = GetFromTempStorage(FileInfo.TempFileStorageAddress);
	EndIf;
	
	If FilesStorageTyoe = Enums.FileStorageTypes.InInfobase Then
		
		FileStorage = New ValueStorage(BinaryData);
			
		If Version.Size = 0 Then
			FileBinaryData = FileStorage.Get();
			Version.Size = FileBinaryData.Size();
			
			FilesOperationsInternal.CheckFileSizeForImport(Version);
		EndIf;
		
		// clearing fields
		Version.PathToFile = "";
		Version.Volume = Catalogs.FileStorageVolumes.EmptyRef();
	Else // hard drive storage
		
		If Version.Size = 0 Then
			Version.Size = BinaryData.Size();
			FilesOperationsInternal.CheckFileSizeForImport(Version);
		EndIf;
		
		FileEncrypted = False;
		If FileInfo.Encrypted <> Undefined Then
			FileEncrypted = FileInfo.Encrypted;
		EndIf;
		
		Info = FilesOperationsInternal.AddFileToVolume(BinaryData,
			ModificationTimeUniversal, FileInfo.BaseName, Version.Extension,
			"", FileEncrypted); 
		Version.Volume = Info.Volume;
		Version.PathToFile = Info.PathToFile;
		FileStorage = New ValueStorage(Undefined); // clearing the ValueStorage
		
	EndIf;
	
	FullTextSearchUsing = Metadata.ObjectProperties.FullTextSearchUsing.Use;
	If CatalogMetadata.FullTextSearch = FullTextSearchUsing Then
		
		If FileInfo.TempTextStorageAddress <> Undefined Then
			If FilesOperationsInternal.ExtractTextFilesOnServer() Then
				Version.TextExtractionStatus = Enums.FileTextExtractionStatuses.NotExtracted;
			Else
				TextExtractionResult = FilesOperationsInternal.ExtractText(FileInfo.TempTextStorageAddress); 
				Version.TextStorage = TextExtractionResult.TextStorage;
				Version.TextExtractionStatus = TextExtractionResult.TextExtractionStatus;
			EndIf;
		Else
			Version.TextExtractionStatus = Enums.FileTextExtractionStatuses.NotExtracted;
		EndIf;
		
		If FileInfo.NewTextExtractionStatus <> Undefined Then
			Version.TextExtractionStatus = FileInfo.NewTextExtractionStatus;
		EndIf;
		
	Else
		Version.TextExtractionStatus = Enums.FileTextExtractionStatuses.NotExtracted;
	EndIf;
	
	If Version.Size = 0 Then
		If FilesStorageTyoe = Enums.FileStorageTypes.InInfobase Then
			FileBinaryData = FileStorage.Get();
			Version.Size = FileBinaryData.Size();
		EndIf;
	EndIf;
	
	Version.Fill(Undefined);
	Version.Write();
	
	If FilesStorageTyoe = Enums.FileStorageTypes.InInfobase Then
		WriteFileToInfobase(Version.Ref, FileStorage);
	EndIf;
	
	If VersionLocked Then
		UnlockDataForEdit(Version.Ref, UUIDOfForm);
	EndIf;
	
	WriteFileVersionEncoding(Version.Ref, PreVersionEncoding);

	If HasSaveRight Then
		FileURL = GetURL(FileRef);
		UserWorkHistory.Add(FileURL);
	EndIf;
	
	Return Version.Ref;
	
EndFunction

// Updates or creates a file version and unlocks it.
//
// Parameters:
//   FileData                  - Structure - a structure with file data.
//   FileInfo               - Structure - see FilesOperationsClientServer.FIleInfo in the  FileWithVersion mode.
//   DontChangeRecordInWorkingDirectory - Boolean  - do not change record the FilesInWorkingDirectory information register.
//   FullFilePath             - String    - specified if DontChangeRecordInWorkingDirectory = False.
//   UserWorkingDirecrtory   - String    - it is specified if DontChangeFilesInWorkingDirectory = False.
//   UUIDOfForm  - UUID - a unique form ID.
//
// Returns:
//   Boolean - True if the version is created (and file is binary changed).
//
Function SaveChangesAndUnlockFile(FileData, FileInfo,
	DontChangeRecordInWorkingDirectory, FullFilePath, UserWorkingDirectory, 
	UUIDOfForm = Undefined) Export
	
	FileDataCurrent = FileData(FileData.Ref);
	If Not FileDataCurrent.CurrentUserEditsFile AND NOT FileToSynchronizeByCloudService(FileData.Ref) Then
		Raise NStr("ru = 'Файл не занят текущим пользователем'; en = 'The file is not locked by the current user.'; pl = 'Plik nie jest zajęty przez bieżącego użytkownika';de = 'Die Datei wird vom aktuellen Benutzer nicht verwendet';ro = 'Fișierul nu este utilizat de utilizatorul curent';tr = 'Dosya geçerli kullanıcı tarafından kullanılmıyor'; es_ES = 'Archivo no está utilizado por el usuario actual'");
	EndIf;
	
	BeginTransaction();
	Try
		PreviousVersion = FileData.CurrentVersion;
		FileInfo.Encrypted = FileData.Encrypted;
		FileInfo.Encoding  = FileData.Encoding;
		
		If TypeOf(FileData.Ref) = Type("CatalogRef.Files") Then
			NewVersion = FilesOperationsInternal.UpdateFileVersion(FileData.Ref, FileInfo,, UUIDOfForm);
		Else
			NewVersion = RefreshFileObject(FileData.Ref, FileInfo,, UUIDOfForm);
		EndIf;
		
		If NewVersion <> Undefined Then
			If FileInfo.StoreVersions Then
				FilesOperationsInternal.UpdateVersionInFile(FileData.Ref, NewVersion, FileInfo.TempTextStorageAddress, UUIDOfForm);
			Else
				UpdateTextInFile(FileData.Ref, FileInfo.TempTextStorageAddress, UUIDOfForm);
			EndIf;
			FileData.CurrentVersion = NewVersion;
		EndIf;
			
		UnlockFile(FileData, UUIDOfForm);
		
		If FileInfo.Encoding <> Undefined Then
			If Not ValueIsFilled(FilesOperationsInternal.GetFileVersionEncoding(FileData.CurrentVersion)) Then
				WriteFileVersionEncoding(FileData.CurrentVersion, FileInfo.Encoding);
			EndIf;
		EndIf;
		
		If NewVersion <> Undefined AND NOT Common.IsWebClient() AND Not DontChangeRecordInWorkingDirectory Then
			DeleteVersionAndPutFileInformationIntoRegister(PreviousVersion, NewVersion,
				FullFilePath, UserWorkingDirectory, FileData.OwnerWorkingDirectory <> "");
		EndIf;
		
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;
	
	Return NewVersion <> Undefined;
	
EndFunction

// Receives file data and then updates or creates a File version and unlocks it.
// It is necessary for cases, when the FileData is missing on the client (for reasons of saving client-server calls).
//
// Parameters:
//   FileRef       - CatalogRef.Files - a file where a version is updated.
//   FileInfo   - Structure - see FilesOperationsClientServer.FIleInfo in the FileWithVersion mode. 
//   FullFilePath             - String
//   UserWorkingDirectory   - String
//   UUIDOfForm  - UUID - a unique form ID.
//
// Returns:
//   Structure - with the following properties:
//     * Success     - Boolean    - True if the version is created (and file is binary changed).
//     * FileData - Structure - a structure with file data.
//
Function SaveChangesAndUnlockFileByRef(FileRef, FileInfo, 
	FullFilePath, UserWorkingDirectory, UUIDOfForm = Undefined) Export
	
	FileData = FileData(FileRef);
	VersionCreated = SaveChangesAndUnlockFile(FileData, FileInfo, False, FullFilePath, UserWorkingDirectory,
		UUIDOfForm);
	Return New Structure("Success,FileData", VersionCreated, FileData);
	
EndFunction

// It is designed to save file changes without unlocking it.
//
// Parameters:
//   FileData                  - Structure - a structure with file data.
//   FileInfo               - Structure - see FilesOperationsClientServer.FIleInfo in the  FileWithVersion mode.
//   DontChangeRecordInWorkingDirectory - Boolean  - do not change record the FilesInWorkingDirectory information register.
//   RelativeFilePath      - String    - a relative path without a working directory path, for example,
//                                              "А1/Order.doc"; Specified if DontChangeRecordInWorkingDirectory =
//                                              False.
//   FullFilePath             - String    - a path on the client in the working directory. It is specified if
//                                              DontChangeRecordInWorkingDirectory = False.
//   InUserWorkingDirectory    - Boolean    - file is in the user working directory.
//   UUIDOfForm  - UUID - a unique form ID.
//
// Returns:
//   Boolean  - True if the version is created (and file is binary changed).
//
Function SaveFileChanges(FileRef, FileInfo, 
	DontChangeRecordInWorkingDirectory, RelativeFilePath, FullFilePath, InOwnerWorkingDirectory,
	UUIDOfForm = Undefined) Export
	
	FileDataCurrent = FileData(FileRef);
	If Not FileDataCurrent.CurrentUserEditsFile AND NOT FileToSynchronizeByCloudService(FileRef) Then
		Raise NStr("ru = 'Файл не занят текущим пользователем'; en = 'The file is not locked by the current user.'; pl = 'Plik nie jest zajęty przez bieżącego użytkownika';de = 'Die Datei wird vom aktuellen Benutzer nicht verwendet';ro = 'Fișierul nu este utilizat de utilizatorul curent';tr = 'Dosya geçerli kullanıcı tarafından kullanılmıyor'; es_ES = 'Archivo no está utilizado por el usuario actual'");
	EndIf;
	
	CurrentVersion = FileDataCurrent.CurrentVersion;
	
	BeginTransaction();
	Try
		
		OldVersion = ?(FileInfo.StoreVersions, FileRef.CurrentVersion, FileRef);
		FileInfo.Encrypted = FileDataCurrent.Encrypted;
		
		If TypeOf(FileRef.Ref) = Type("CatalogRef.Files") Then
			NewVersion = FilesOperationsInternal.UpdateFileVersion(FileRef.Ref, FileInfo,, UUIDOfForm, FileInfo.NewVersionAuthor);
		Else
			NewVersion = RefreshFileObject(FileRef.Ref, FileInfo,, UUIDOfForm);
		EndIf;
		
		If NewVersion <> Undefined Then
			CurrentVersion = NewVersion;
			If FileInfo.StoreVersions Then
				FilesOperationsInternal.UpdateVersionInFile(FileRef, NewVersion, FileInfo.TempTextStorageAddress, UUIDOfForm);
				
				If NOT Common.IsWebClient() AND Not DontChangeRecordInWorkingDirectory Then
					DeleteFromRegister(OldVersion);
					WriteFullFileNameToRegister(NewVersion, RelativeFilePath, False, InOwnerWorkingDirectory);
				EndIf;
				
			Else
				UpdateTextInFile(FileRef, FileInfo.TempTextStorageAddress, UUIDOfForm);
			EndIf;
			
		EndIf;
		
		If FileInfo.Encoding <> Undefined Then
			If Not ValueIsFilled(FilesOperationsInternal.GetFileVersionEncoding(CurrentVersion)) Then
				WriteFileVersionEncoding(CurrentVersion, FileInfo.Encoding);
			EndIf;
		EndIf;
		
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;
	
	Return NewVersion <> Undefined;
	
EndFunction

// Updates a text portion from a file in the file card.
//
// Parameters:
//   FileRef - CatalogRef.Files - a file, in which a version is created.
//   TextTempStorageAddress - String - contains the address in the temporary storage, where the 
//                                           binary data with the text file, or the ValueStorage 
//                                           that directly contains the binary data with the text file are located.
//  UUID - a form UUID.
//
Procedure UpdateTextInFile(FileRef,
                              Val TempTextStorageAddress,
                              UUID = Undefined)
	
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
		
		If CatalogMetadata.FullTextSearch = FullTextSearchUsing Then
			TextExtractionResult = FilesOperationsInternal.ExtractText(TempTextStorageAddress);
			FileObject.TextExtractionStatus = TextExtractionResult.TextExtractionStatus;
			FileObject.TextStorage = TextExtractionResult.TextStorage;
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

// Creates a new file similarly to the specified one and returns a reference to it.
// Parameters:
//  SourceFile  - CatalogRef.Files - the existing file.
//  NewFileOwner - AnyRef - a file owner.
//
// Returns:
//   CatalogRef.Files - a new file.
//
Function CopyFile(SourceFile, NewFileOwner)
	
	If SourceFile = Undefined Or SourceFile.IsEmpty() Then
		Return Undefined;
	EndIf;
	
	ObjectManager = Common.ObjectManagerByRef(SourceFile);
	NewFile = SourceFile.Copy();
	FileCopyRef = ObjectManager.GetRef();
	NewFile.SetNewObjectRef(FileCopyRef);
	NewFile.FileOwner = NewFileOwner.Ref;
	NewFile.BeingEditedBy = Catalogs.Users.EmptyRef();
	
	NewFile.TextStorage = New ValueStorage(SourceFile.TextStorage.Get());
	NewFile.FileStorage  = New ValueStorage(SourceFile.FileStorage.Get());
	
	BinaryData = FilesOperations.FileBinaryData(SourceFile);
	BinaryDataInValueStorage = New ValueStorage(BinaryData);
	NewFile.FileStorageType = FilesOperationsInternal.FilesStorageTyoe();
	
	If FilesOperationsInternal.FilesStorageTyoe() = Enums.FileStorageTypes.InInfobase Then
		
		WriteFileToInfobase(FileCopyRef, BinaryDataInValueStorage);
		
	Else
		// Add the file to a volume with sufficient free space.
		FileInfo = FilesOperationsInternal.AddFileToVolume(BinaryData, NewFile.UniversalModificationDate,
		NewFile.Description, NewFile.Extension);
		NewFile.PathToFile = FileInfo.PathToFile;
		NewFile.Volume = FileInfo.Volume;
	EndIf;
	NewFile.Write();
	
	If NewFile.StoreVersions Then
		
		FileInfo = FilesOperationsClientServer.FileInfo("FileWithVersion");
		FileInfo.BaseName = NewFile.Description;
		FileInfo.Size = NewFile.CurrentVersion.Size;
		FileInfo.ExtensionWithoutPoint = NewFile.CurrentVersion.Extension;
		FileInfo.TempFileStorageAddress = BinaryDataInValueStorage;
		FileInfo.TempTextStorageAddress = NewFile.CurrentVersion.TextStorage;
		FileInfo.RefToVersionSource = NewFile.CurrentVersion;
		FileInfo.Encrypted = NewFile.Encrypted;
		Version = FilesOperationsInternal.CreateVersion(NewFile.Ref, FileInfo);
		FilesOperationsInternal.UpdateVersionInFile(NewFile.Ref, Version, NewFile.CurrentVersion.TextStorage);
		
	EndIf;
	
	If Common.SubsystemExists("StandardSubsystems.DigitalSignature") Then
		
		ModuleDigitalSignatureInternal = Common.CommonModule("DigitalSignatureInternal");
		DigitalSignatureAvailable = ModuleDigitalSignatureInternal.DigitalSignatureAvailable(TypeOf(SourceFile));
		If DigitalSignatureAvailable Then
			
			ModuleDigitalSignature = Common.CommonModule("DigitalSignature");
			
			If SourceFile.SignedWithDS Then
				
				FileObject = NewFile.GetObject();
				FileObject.SignedWithDS = True;
				FileObject.Write();

				DigitalSignaturesOfInitialFile = ModuleDigitalSignature.SetSignatures(SourceFile);
				For Each DS In DigitalSignaturesOfInitialFile Do
					RecordManager = InformationRegisters["DigitalSignatures"].CreateRecordManager();
					RecordManager.SignedObject = NewFile;
					FillPropertyValues(RecordManager, DS);
					RecordManager.Write(True);
				EndDo;
				
			EndIf;
			
			If SourceFile.Encrypted Then
				
				FileObject = NewFile.GetObject();
				FileObject.Encrypted = True;
				
				DigitalSignaturesOfInitialFile = ModuleDigitalSignature.EncryptionCertificates(SourceFile);
				For Each Certificate In DigitalSignaturesOfInitialFile Do
					RecordManager = InformationRegisters["EncryptionCertificates"].CreateRecordManager();
					RecordManager.EncryptedObject = NewFile;
					FillPropertyValues(RecordManager, Certificate);
					RecordManager.Write(True);
				EndDo;
				// To write a previously signed object.
				FileObject.AdditionalProperties.Insert("WriteSignedObject", True);
				FileObject.Write();
				
			EndIf;
		EndIf;
	EndIf;
	
	FilesOperationsOverridable.FillFileAtributesFromSourceFile(NewFile, SourceFile);
	
	Return NewFile;
	
EndFunction

// Moves the File into other folder.
//
// Parameters:
//  FileData  - a structure with file data.
//  Folder - CatalogRef.FilesFolders - a reference to the folder, to which you need ot move the file.
//
Procedure MoveFileSSL(FileData, Folder) 
	
	BeginTransaction();
	Try
		DataLock = New DataLock;
		DataLockItem = DataLock.Add(Metadata.FindByType(TypeOf(FileData.Ref)).FullName());
		DataLockItem.SetValue("Ref", FileData.Ref);
		DataLock.Lock();	
		FileObject = FileData.Ref.GetObject();
		FileObject.Lock();
		FileObject.FileOwner = Folder;
		FileObject.Write();
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;
	
EndProcedure

// Moves Files into other folder.
//
// Parameters:
//  ObjectsRef - Array - an array of file references.
//  Folder - CatalogRef.FilesFolders - a reference to the folder, to which you need ot move the files.
//
Function MoveFiles(ObjectsRef, Folder) Export 
	
	FilesData = New Array;
	
	For Each FileRef In ObjectsRef Do
		MoveFileSSL(FileRef, Folder);
		FileData = FileData(FileRef);
		FilesData.Add(FileData);
	EndDo;
	
	Return FilesData;
	
EndFunction

// Receives EditedByCurrentUser in the privileged mode.
// Parameters:
//  VersionRef  - CatalogRef.FilesVersions - a file version.
//
// Returns:
//   Boolean - True if a file is edited by the current user.
//
Function GetEditedByCurrentUser(VersionRef) Export
	
	SetPrivilegedMode(True);
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	Files.BeingEditedBy AS BeingEditedBy
	|FROM
	|	Catalog.Files AS Files
	|		INNER JOIN Catalog.FilesVersions AS FilesVersions
	|		ON (TRUE)
	|WHERE
	|	FilesVersions.Ref = &Version
	|	AND Files.Ref = FilesVersions.Owner";
	
	Query.Parameters.Insert("Version", VersionRef);
	
	Selection = Query.Execute().Select();
	If Selection.Next() Then
		EditedByCurrentUser = (Selection.BeingEditedBy = Users.AuthorizedUser());
		Return EditedByCurrentUser;
	EndIf;
	
	Return False;
	
EndFunction

// Gets file data and performs a checkout. To reduce the number of client/server calls, GetFileData 
// and LockFile are combined into a single function.
// Parameters:
//  FileRef  - CatalogRef.Files - a file.
//  FileData  - Structure - a structure with file data.
//  ErrorString - a string, where the error  reason is returned (for example, "File is locked by 
//                 other user").
//  UUID - a form UUID.
//
// Returns:
//   Boolean  - shows whether the operation is performed successfully.
//
Function GetFileDataAndLockFile(FileRef, FileData, ErrorRow, UUID = Undefined) Export

	FileData = FileData(FileRef);

	ErrorRow = "";
	If NOT FilesOperationsClientServer.WhetherPossibleLockFile(FileData, ErrorRow) Then
		Return False;
	EndIf;	
	
	If Not ValueIsFilled(FileData.BeingEditedBy) Then
		
		ErrorRow = "";
		If Not LockFile(FileData, ErrorRow, UUID) Then 
			Return False;
		EndIf;
	EndIf;
	
	Return True;
	
EndFunction

// Receives FileData for files and places it into FileDataArray.
//  FilesArray - an array of file references.
//  FileDataArray - an array of structures with file data.
//
Procedure GetDataForFilesArray(Val FilesArray, FileDataArray) Export
	
	For Each File In FilesArray Do
		FileData = FileData(File);
		FileDataArray.Add(FileData);
	EndDo;
	
EndProcedure

// Gets file data for opening and performs a checkout. To reduce the number of client/server calls, 
// FileDataToOpen and LockFile are combined into a single function.
// Parameters:
//  FileRef  - CatalogRef.Files - a file.
//  FileData  - Structure - a structure with file data.
//  ErrorString - a string, where the error  reason is returned (for example, "File is locked by 
//                 other user").
//  UUID - a form UUID.
//  OwnerWorkingDirectory - String - a working directory of the file owner.
//
// Returns:
//   Boolean  - shows whether the operation is performed successfully.
//
Function GetFileDataToOpenAndLockFile(FileRef,
	FileData,
	ErrorRow,
	UUID = Undefined,
	OwnerWorkingDirectory = Undefined,
	VersionRef = Undefined) Export

	FileData = FileDataToOpen(FileRef, VersionRef, UUID, OwnerWorkingDirectory);

	ErrorRow = "";
	If NOT FilesOperationsClientServer.WhetherPossibleLockFile(FileData, ErrorRow) Then
		Return False;
	EndIf;
	
	If Not ValueIsFilled(FileData.BeingEditedBy) Then
		
		ErrorRow = "";
		If Not LockFile(FileData, ErrorRow, UUID) Then 
			Return False;
		EndIf;
	EndIf;
	
	Return True;
EndFunction

// Executes PutInTempStorage (if the file is stored on the hard drive) and returns a URL of the file in the storage.
// Parameters:
//   VersionRef - a file version.
//  FormID - a form UUID.
//
// Returns:
//   String  - URL in the temporary storage.
//
Function GetURLToOpen(VersionRef, FormID = Undefined) Export
	
	HasRightsToObject = Common.ObjectAttributesValues(VersionRef, "Ref", True);
	
	If HasRightsToObject = Undefined Then
		Return Undefined;
	EndIf;
	
	Return PutToTempStorage(FilesOperations.FileBinaryData(VersionRef));
	
EndFunction

// Executes FileData and calculates OwnerWorkingDirectory.
//
// Parameters:
//  FileOrVersionRef     - CatalogRef.Files, CatalogRef.FilesVersions - a file or a file version.
//  UserWorkingDirectory - String - the user working directory is returned in it.
//
// Returns:
//   Structure - a structure with file data.
//
Function FileDataAndWorkingDirectory(FileOrVersionRef, OwnerWorkingDirectory = Undefined) Export
	
	FileData = FileData(FileOrVersionRef);
	FileMetadata = Metadata.FindByType(TypeOf(FileOrVersionRef));
	AbilityToStoreVersions = False;
	If Common.HasObjectAttribute("FileOwner", FileMetadata) Then 
		FileRef = FileOrVersionRef;
		VersionRef = Undefined;
		AbilityToStoreVersions = Common.HasObjectAttribute("CurrentVersion", FileMetadata);
	Else
		FileRef = Undefined;
		VersionRef = FileOrVersionRef;
	EndIf;
	
	If OwnerWorkingDirectory = Undefined Then
		OwnerWorkingDirectory = FolderWorkingDirectory(FileData.Owner);
	EndIf;
	FileData.Insert("OwnerWorkingDirectory", OwnerWorkingDirectory);
	
	If FileData.OwnerWorkingDirectory <> "" Then
		
		FullFileNameInWorkingDirectory = "";
		DirectoryName = ""; // Path to a local cache is not used here.
		InWorkingDirectoryForRead = True; // not used
		InOwnerWorkingDirectory = True;
		
		If VersionRef <> Undefined Then
			FullFileNameInWorkingDirectory = GetFullFileNameFromRegister(VersionRef, DirectoryName, InWorkingDirectoryForRead, InOwnerWorkingDirectory);
		ElsIf AbilityToStoreVersions AND ValueIsFilled(FileRef.CurrentVersion) Then
			FullFileNameInWorkingDirectory = GetFullFileNameFromRegister(FileRef.CurrentVersion, DirectoryName, InWorkingDirectoryForRead, InOwnerWorkingDirectory);
		Else
			FullFileNameInWorkingDirectory = GetFullFileNameFromRegister(FileRef, DirectoryName, InWorkingDirectoryForRead, InOwnerWorkingDirectory);
		EndIf;
		
		FileData.Insert("FullFileNameInWorkingDirectory", FullFileNameInWorkingDirectory);
	EndIf;
	
	Return FileData;
EndFunction

// Makes GetFileData and calculates the number of file versions.
// Parameters:
//  FileRef  - CatalogRef.Files - a file.
//
// Returns:
//   Structure - a structure with file data.
//
Function GetFileDataAndVersionsCount(FileRef) Export
	
	FileData = FileData(FileRef);
	VersionsCount = GetVersionsCount(FileRef);
	FileData.Insert("VersionsCount", VersionsCount);
	
	Return FileData;
	
EndFunction

// Unlocking File with receiving data.
// Parameters:
//  FileRef  - CatalogRef.Files - a file.
//  FileData  - a structure with file data.
//  UUID - a form UUID.
//
Procedure GetFileDataAndUnlockFile(FileRef, FileData, UUID = Undefined) Export
	
	FileData = FileData(FileRef);
	UnlockFile(FileData, UUID);
	
EndProcedure

// To save file changes without unlocking it.
//
// Parameters:
//   FileRef                   - Structure - a structure with file data.
//   FileInfo               - Structure - see FilesOperationsClientServer.FIleInfo in the  FileWithVersion mode.
//   RelativeFilePath      - String    - a relative path without a working directory path, for example,
//                                              "А1/Order.doc"; Specified if DontChangeRecordInWorkingDirectory =
//                                              False.
//   FullFilePath             - String    - a path on the client in the working directory. It is specified if
//                                              DontChangeRecordInWorkingDirectory = False.
//   InUserWorkingDirectory    - Boolean    - file is in the user working directory.
//   UUIDOfForm  - UUID - a unique form ID.
//
// Returns:
//   Structure - with the following properties:
//     * Success     - Boolean    - True if the version is created (and file is binary changed).
//     * FileData - Structure - a structure with file data.
//
Function GetFileDataAndSaveFileChanges(FileRef, FileInfo, 
	RelativeFilePath, FullFilePath, InOwnerWorkingDirectory,
	UUIDOfForm = Undefined) Export
	
	FileData = FileData(FileRef);
	If Not FileData.CurrentUserEditsFile Then
		Raise NStr("ru = 'Файл не занят текущим пользователем'; en = 'The file is not locked by the current user.'; pl = 'Plik nie jest zajęty przez bieżącego użytkownika';de = 'Die Datei wird vom aktuellen Benutzer nicht verwendet';ro = 'Fișierul nu este utilizat de utilizatorul curent';tr = 'Dosya geçerli kullanıcı tarafından kullanılmıyor'; es_ES = 'Archivo no está utilizado por el usuario actual'");
	EndIf;
	
	VersionCreated = SaveFileChanges(FileRef, FileInfo, 
		False, RelativeFilePath, FullFilePath, InOwnerWorkingDirectory,
		UUIDOfForm);
	Return New Structure("Success,FileData", VersionCreated, FileData);	
	
EndFunction

// Receives the synthetic working directory of the folder on the hard drive (it can come from the parent folder).
// Parameters:
//  FolderRef  - CatalogRef.FilesFolders - a file owner.
//
// Returns:
//   String  - a working directory.
//
Function FolderWorkingDirectory(FolderRef) Export
	
	If Not IsDirectoryFiles(FolderRef) Then
		Return ""
	EndIf;
	
	SetPrivilegedMode(True);
	
	WorkingDirectory = "";
	
	// Prepare a filter structure by dimensions.
	
	FilterStructure = New Structure;
	FilterStructure.Insert("Folder", FolderRef);
	FilterStructure.Insert("User", Users.AuthorizedUser());
	
	// Receive structure with the data of record resources.
	ResourcesStructure = InformationRegisters.FileWorkingDirectories.Get(FilterStructure);
	
	// Getting a path from the register
	WorkingDirectory = ResourcesStructure.Path;
	
	If NOT IsBlankString(WorkingDirectory) Then
		// Adding a slash mark at the end if it is not there.
		WorkingDirectory = CommonClientServer.AddLastPathSeparator(WorkingDirectory);
	EndIf;
	
	Return WorkingDirectory;
	
EndFunction

// Saves a folder working directory to the information register.
// Parameters:
//  FolderRef  - CatalogRef.FilesFolders - a file owner.
//  OwnerWorkingDirectory - String - a working directory of the folder owner.
//
Procedure SaveFolderWorkingDirectory(FolderRef, FolderWorkingDirectory) Export
	
	SetPrivilegedMode(True);
	
	RecordSet = InformationRegisters.FileWorkingDirectories.CreateRecordSet();
	
	RecordSet.Filter.Folder.Set(FolderRef);
	RecordSet.Filter.User.Set(Users.AuthorizedUser());
	
	NewRecord = RecordSet.Add();
	NewRecord.Folder = FolderRef;
	NewRecord.User = Users.AuthorizedUser();
	NewRecord.Path = FolderWorkingDirectory;
	
	RecordSet.Write();
	
EndProcedure

// Saves a folder working directory to the information register and replaces paths in the 
// FilesInWorkingDirectory information register.
//
// Parameters:
//  FolderRef  - CatalogRef.FilesFolders - a file owner.
//  FolderWorkingDirectory - String - a folder working directory.
//  DirectoryNamePreviousValue - a previous value of the working directory.
//
Procedure SaveFolderWorkingDirectoryAndReplacePathsInRegister(FolderRef,
                                                        FolderWorkingDirectory,
                                                        DirectoryNamePreviousValue) Export
	
	SaveFolderWorkingDirectory(FolderRef, FolderWorkingDirectory);
	
	// Changing paths in the FilesInWorkingDirectory information register below.
	SetPrivilegedMode(True);
	
	ListForChange = New Array;
	CurrentUser = Users.AuthorizedUser();
	
	// Finding a record in the information register for each record and taking the Version and EditedBy fields from there.
	QuieryToRegister = New Query;
	QuieryToRegister.SetParameter("User", CurrentUser);
	QuieryToRegister.SetParameter("Path", DirectoryNamePreviousValue + "%");
	QuieryToRegister.Text =
	"SELECT
	|	FilesInWorkingDirectory.File AS File,
	|	FilesInWorkingDirectory.Path AS Path,
	|	FilesInWorkingDirectory.Size AS Size,
	|	FilesInWorkingDirectory.PutFileInWorkingDirectoryDate AS PutFileInWorkingDirectoryDate,
	|	FilesInWorkingDirectory.ForReading AS ForReading
	|FROM
	|	InformationRegister.FilesInWorkingDirectory AS FilesInWorkingDirectory
	|WHERE
	|	FilesInWorkingDirectory.User = &User
	|	AND FilesInWorkingDirectory.InOwnerWorkingDirectory = TRUE
	|	AND FilesInWorkingDirectory.Path LIKE &Path";
	
	QueryResult = QuieryToRegister.Execute(); 
	
	Selection = QueryResult.Select();
	While Selection.Next() Do
		
		NewPath = Selection.Path;
		NewPath = StrReplace(NewPath, DirectoryNamePreviousValue, FolderWorkingDirectory);
		
		RecordStructure = New Structure;
		RecordStructure.Insert("File",                         Selection.File);
		RecordStructure.Insert("Path",                         NewPath);
		RecordStructure.Insert("Size",                       Selection.Size);
		RecordStructure.Insert("PutFileInWorkingDirectoryDate", Selection.PutFileInWorkingDirectoryDate);
		RecordStructure.Insert("ForReading",                     Selection.ForReading);
		
		ListForChange.Add(RecordStructure);
		
	EndDo;
	
	For Each RecordStructure In ListForChange Do
		
		InOwnerWorkingDirectory = True;
		WriteRecordStructureToRegister(
			RecordStructure.File,
			RecordStructure.Path,
			RecordStructure.Size,
			RecordStructure.PutFileInWorkingDirectoryDate,
			RecordStructure.ForReading,
			InOwnerWorkingDirectory);
		
	EndDo;
	
EndProcedure

// After changing the path, write it again with the same values of other fields.
// Parameters:
//  Version - CatalogRef.FilesVersions - a version.
//  Path - String - a relative path inside the working directory.
//  Size  - file size in bytes.
//  PutFileInWorkingDirectoryDate - a date of putting the file to the working directory.
//  ForRead - Boolean - a file is placed for reading.
//  InOwnerWorkingDirectory - Boolean - a file is in owner working directory (not in the main working directory).
//
Procedure WriteRecordStructureToRegister(File,
                                          Path,
                                          Size,
                                          PutFileInWorkingDirectoryDate,
                                          ForReading,
                                          InOwnerWorkingDirectory)
	
	HasRightsToObject = Common.ObjectAttributesValues(File, "Ref", True);
	
	If HasRightsToObject = Undefined Then
		Return;
	EndIf;
	
	SetPrivilegedMode(True);
	
	// Create a record set.
	RecordSet = InformationRegisters.FilesInWorkingDirectory.CreateRecordSet();
	
	RecordSet.Filter.File.Set(File);
	RecordSet.Filter.User.Set(Users.AuthorizedUser());

	NewRecord = RecordSet.Add();
	NewRecord.File = File;
	NewRecord.Path = Path;
	NewRecord.Size = Size;
	NewRecord.PutFileInWorkingDirectoryDate = PutFileInWorkingDirectoryDate;
	NewRecord.User = Users.AuthorizedUser();

	NewRecord.ForReading = ForReading;
	NewRecord.InOwnerWorkingDirectory = InOwnerWorkingDirectory;
	
	RecordSet.Write();
	
EndProcedure

// Clears a folder working directory at the information register.
// Parameters:
//  FolderRef  - CatalogRef.FilesFolders - a file owner.
//
Procedure CleanUpWorkingDirectory(FolderRef) Export
	SetPrivilegedMode(True);
	
	RecordSet = InformationRegisters.FileWorkingDirectories.CreateRecordSet();
	
	RecordSet.Filter.Folder.Set(FolderRef);
	RecordSet.Filter.User.Set(Users.AuthorizedUser());
	
	// Do not add records into the set to clear everything.
	RecordSet.Write();
	
	// Clearing working directories for child folders.
	Query = New Query;
	Query.Text =
	"SELECT
	|	FilesFolders.Ref AS Ref
	|FROM
	|	Catalog.FilesFolders AS FilesFolders
	|WHERE
	|	FilesFolders.Parent = &Ref";
	
	Query.SetParameter("Ref", FolderRef);
	
	Result = Query.Execute();
	Selection = Result.Select();
	While Selection.Next() Do
		CleanUpWorkingDirectory(Selection.Ref);
	EndDo;
	
EndProcedure

// Finds a record in the FilesInWorkingDirectory information register by a path on the hard drive.
//
// Parameters:
//  FileName - a name of the file with a relative path (without a path to the working directory).
//
// Returns:
//  Structure with the following properties:
//    Version            - CatalogRef.FilesVersions - a found version.
//    PutDate     - a date of putting the file to the working directory.
//    File          - Ref - file owner.
//    VersionNumber       - Number - a version number.
//    InReadRegister - Boolean - the ForRead resource value.
//    InFileCodeRegister - Number. Here the file code is placed.
//    InFolderRegister    - CatalogRef.FilesFolders - a file folder.
//
Function FindInRegisterByPath(FileName) Export
	
	SetPrivilegedMode(True);
	
	FoundProperties = New Structure;
	FoundProperties.Insert("FileIsInRegister", False);
	FoundProperties.Insert("File", Catalogs.FilesVersions.EmptyRef());
	FoundProperties.Insert("PutFileDate");
	FoundProperties.Insert("Owner");
	FoundProperties.Insert("VersionNumber");
	FoundProperties.Insert("InRegisterForReading");
	FoundProperties.Insert("FileCodeInRegister");
	FoundProperties.Insert("InRegisterFolder");
	
	// Finding a record in the information register for each one by path and getting the field from there.
	// Version, Size, and PutFileInWorkingDirectoryDate.
	QuieryToRegister = New Query;
	QuieryToRegister.SetParameter("FileName", FileName);
	QuieryToRegister.SetParameter("User", Users.AuthorizedUser());
	QuieryToRegister.Text =
	"SELECT
	|	FilesInWorkingDirectory.File AS File,
	|	FilesInWorkingDirectory.PutFileInWorkingDirectoryDate AS PutFileDate,
	|	FilesInWorkingDirectory.ForReading AS InRegisterForReading,
	|	CASE
	|		WHEN VALUETYPE(FilesInWorkingDirectory.File) = TYPE(Catalog.FilesVersions)
	|			THEN FilesInWorkingDirectory.File.Owner
	|		ELSE FilesInWorkingDirectory.File
	|	END AS Owner,
	|	CASE
	|		WHEN VALUETYPE(FilesInWorkingDirectory.File) = TYPE(Catalog.FilesVersions)
	|			THEN FilesInWorkingDirectory.File.VersionNumber
	|		ELSE 0
	|	END AS VersionNumber,
	|	CASE
	|		WHEN VALUETYPE(FilesInWorkingDirectory.File) = TYPE(Catalog.FilesVersions)
	|			THEN FilesInWorkingDirectory.File.Owner.FileOwner
	|		ELSE FilesInWorkingDirectory.File.FileOwner
	|	END AS InRegisterFolder
	|FROM
	|	InformationRegister.FilesInWorkingDirectory AS FilesInWorkingDirectory
	|WHERE
	|	FilesInWorkingDirectory.Path = &FileName
	|	AND FilesInWorkingDirectory.User = &User";
	
	QueryResult = QuieryToRegister.Execute(); 
	
	If NOT QueryResult.IsEmpty() Then
		FoundProperties.FileIsInRegister = True;
		
		Selection = QueryResult.Select();
		Selection.Next();
		
		FillPropertyValues(FoundProperties, Selection);
	EndIf;
	
	Return FoundProperties;
	
EndFunction

// Finds information on FileVersions in the FilesInWorkingDirectory information register (a path to 
// the version file in a working directory and its status to read or to edit).
// Parameters:
//  Version - CatalogRef.FilesVersions - a version.
//  DirectoryName - a working directory path.
//  InWorkingdirectoryForRead - Boolean - a file is placed for reading.
//  InOwnerWorkingDirectory - Boolean - a file is in owner working directory (not in the main working directory).
//
Function GetFullFileNameFromRegister(Version,
                                         DirectoryName,
                                         InWorkingDirectoryForRead,
                                         InOwnerWorkingDirectory) Export
	
	HasRightsToObject = Common.ObjectAttributesValues(Version, "Ref", True);
	
	If HasRightsToObject = Undefined Then
		Return Undefined;
	EndIf;
	
	SetPrivilegedMode(True);
	
	FullFileName = "";
	
	// Prepare a filter structure by dimensions.
	FilterStructure = New Structure;
	FilterStructure.Insert("File", Version.Ref);

	FilterStructure.Insert("User", Users.AuthorizedUser());
	
	// Receive structure with the data of record resources.
	ResourcesStructure = InformationRegisters.FilesInWorkingDirectory.Get(FilterStructure);
	
	// Getting a path from the register
	FullFileName = ResourcesStructure.Path;
	InWorkingDirectoryForRead = ResourcesStructure.ForReading;
	InOwnerWorkingDirectory = ResourcesStructure.InOwnerWorkingDirectory;
	If FullFileName <> "" AND InOwnerWorkingDirectory = False Then
		FullFileName = DirectoryName + FullFileName;
	EndIf;
	
	Return FullFileName;
	
EndFunction

// Writing information about a file path to the FilesInWorkingDirectory information register.
// Parameters:
//  CurrentVersion - CatalogRef.FilesVersions - a version.
//  FullFileName - a name with its path in the working directory.
//  ForRead - Boolean - a file is placed for reading.
//  InOwnerWorkingDirectory - Boolean - a file is in owner working directory (not in the main working directory).
//
Procedure WriteFullFileNameToRegister(CurrentVersion,
                                         FullFileName,
                                         ForReading,
                                         InOwnerWorkingDirectory) Export
	
	SetPrivilegedMode(True);
	
	// Create a record set.
	RecordSet = InformationRegisters.FilesInWorkingDirectory.CreateRecordSet();
	
	RecordSet.Filter.File.Set(CurrentVersion.Ref);
	RecordSet.Filter.User.Set(Users.AuthorizedUser());

	NewRecord = RecordSet.Add();
	NewRecord.File = CurrentVersion.Ref;
	NewRecord.Path = FullFileName;
	NewRecord.Size = CurrentVersion.Size;
	NewRecord.PutFileInWorkingDirectoryDate = CurrentSessionDate();
	NewRecord.User = Users.AuthorizedUser();

	NewRecord.ForReading = ForReading;
	NewRecord.InOwnerWorkingDirectory = InOwnerWorkingDirectory;
	
	RecordSet.Write();
	
EndProcedure

// Delete a record about the specified version of the file from the FilesInWorkingDirectory information register.
// Parameters:
//  Version - CatalogRef.FilesVersions - a version.
//
Procedure DeleteFromRegister(File) Export
	
	HasRightsToObject = Common.ObjectAttributesValues(File, "Ref", True);
	If HasRightsToObject = Undefined Then
		Return;
	EndIf;
	
	SetPrivilegedMode(True);
	
	RecordSet = InformationRegisters.FilesInWorkingDirectory.CreateRecordSet();
	
	RecordSet.Filter.File.Set(File);
	RecordSet.Filter.User.Set(Users.AuthorizedUser());
	
	RecordSet.Write();
	
EndProcedure

// Delete all records from the FilesInWorkingDirectory information register except for the records 
// about files locked by the current user.
//
Procedure ClearAllExceptLocked() Export
	
	// Filtering all in the information register. Looping through and finding those ones that are not 
	//  locked by the current user and deleting all, considering that they have already been deleted on the hard drive.
	
	SetPrivilegedMode(True);
	
	ListDelete = New Array;
	CurrentUser = Users.AuthorizedUser();
	
	// Finding a record in the information register for each record and taking the Version and EditedBy fields from there.
	QuieryToRegister = New Query;
	QuieryToRegister.SetParameter("User", CurrentUser);
	QuieryToRegister.Text =
	"SELECT
	|	FilesInWorkingDirectory.File AS File,
	|	FilesInfo.BeingEditedBy AS BeingEditedBy
	|FROM
	|	InformationRegister.FilesInWorkingDirectory AS FilesInWorkingDirectory
	|		LEFT JOIN InformationRegister.FilesInfo AS FilesInfo
	|		ON FilesInWorkingDirectory.File = FilesInfo.File
	|WHERE
	|	FilesInWorkingDirectory.User = &User
	|	AND FilesInWorkingDirectory.InOwnerWorkingDirectory = FALSE";
	
	QueryResult = QuieryToRegister.Execute(); 
	
	If NOT QueryResult.IsEmpty() Then
		
		Selection = QueryResult.Select();
		While Selection.Next() Do
				
			If Selection.BeingEditedBy <> CurrentUser Then
				ListDelete.Add(Selection.File);
			EndIf;
			
		EndDo;
	EndIf;
	
	SetPrivilegedMode(True);
	For Each File In ListDelete Do
		// Create a record set.
		RecordSet = InformationRegisters.FilesInWorkingDirectory.CreateRecordSet();
		
		RecordSet.Filter.File.Set(File);
		RecordSet.Filter.User.Set(CurrentUser);
		
		RecordSet.Write();
	EndDo;
	
EndProcedure

// Delete a record about the previous version in the FilesInWorkingDirectory information register and write the new one.
// Parameters:
//  OldVersion - CatalogRef.FilesVersions - an old version.
//  NewVersion - CatalogRef.FilesVersions - a new version.
//  FullFileName - a name with its path in the working directory.
//  DirectoryName - a working directory path.
//  InOwnerWorkingDirectory - Boolean - a file is in owner working directory (not in the main working directory).
//
Procedure DeleteVersionAndPutFileInformationIntoRegister(OldVersion,
                                                       NewVersion,
                                                       FullFileName,
                                                       DirectoryName,
                                                       InOwnerWorkingDirectory)
	
	DeleteFromRegister(OldVersion);
	ForReading = True;
	PutFileInformationInRegister(NewVersion, FullFileName, DirectoryName, ForReading, 0, InOwnerWorkingDirectory);
	
EndProcedure

// Writing information about a file path to the FilesInWorkingDirectory information register.
//  Version - CatalogRef.FilesVersions - a version.
//  FullPath - String - a full file path.
//  DirectoryName - a working directory path.
//  ForRead - Boolean - a file is placed for reading.
//  FileSize  - file size in bytes.
//  InOwnerWorkingDirectory - Boolean - a file is in owner working directory (not in the main working directory).
//
Procedure PutFileInformationInRegister(Version,
                                         FullPath,
                                         DirectoryName,
                                         ForReading,
                                         FileSize,
                                         InOwnerWorkingDirectory) Export
	FullFileName = FullPath;
	
	If InOwnerWorkingDirectory = False Then
		If StrFind(FullPath, DirectoryName) = 1 Then
			FullFileName = Mid(FullPath, StrLen(DirectoryName) + 1);
		EndIf;
	EndIf;
	
	HasRightsToObject = Common.ObjectAttributesValues(Version, "Ref", True);
	
	If HasRightsToObject = Undefined Then
		Return;
	EndIf;
	
	SetPrivilegedMode(True);
	
	// Create a record set.
	RecordSet = InformationRegisters.FilesInWorkingDirectory.CreateRecordSet();
	
	RecordSet.Filter.File.Set(Version.Ref);
	RecordSet.Filter.User.Set(Users.AuthorizedUser());

	NewRecord = RecordSet.Add();
	NewRecord.File = Version.Ref;
	NewRecord.Path = FullFileName;

	If FileSize <> 0 Then
		NewRecord.Size = FileSize;
	Else
		NewRecord.Size = Version.Size;
	EndIf;

	NewRecord.PutFileInWorkingDirectoryDate = CurrentSessionDate();
	NewRecord.User = Users.AuthorizedUser();
	NewRecord.ForReading = ForReading;
	NewRecord.InOwnerWorkingDirectory = InOwnerWorkingDirectory;

	RecordSet.Write();
	
EndProcedure

// Sorts an array of structures by the Date field on the server, since there is no ValueTable on the thin client.
//
// Parameters:
//   StructuresArray - an array of file description structures.
//
Procedure SortStructuresArray(StructuresArray) Export
	
	FilesTable = New ValueTable;
	FilesTable.Columns.Add("Path");
	FilesTable.Columns.Add("Version");
	FilesTable.Columns.Add("Size");
	
	FilesTable.Columns.Add("PutFileInWorkingDirectoryDate", New TypeDescription("Date"));
	
	For Each Row In StructuresArray Do
		NewRow = FilesTable.Add();
		FillPropertyValues(NewRow, Row, "Path, Size, Version, PutFileInWorkingDirectoryDate");
	EndDo;
	
	// Sorting by date means that in the beginning there will be items, placed in the working directory long ago.
	FilesTable.Sort("PutFileInWorkingDirectoryDate Asc");  
	
	StructuresArrayReturn = New Array;
	
	For Each Row In FilesTable Do
		Record = New Structure;
		Record.Insert("Path", Row.Path);
		Record.Insert("Size", Row.Size);
		Record.Insert("Version", Row.Version);
		Record.Insert("PutFileInWorkingDirectoryDate", Row.PutFileInWorkingDirectoryDate);
		StructuresArrayReturn.Add(Record);
	EndDo;
	
	StructuresArray = StructuresArrayReturn;
	
EndProcedure

// The function changes FileOwner for the objects as Catalog.File, and returns True if successful.
// Parameters:
//  RefsToFilesArray - Array - an array of files.
//  NewFileOwner  - AnyRef - the new file owner.
//
// Returns:
//   Boolean  - shows whether the operation is performed successfully.
//
Function SetFileOwner(ArrayOfRefsToFiles, NewFileOwner) Export
	If ArrayOfRefsToFiles.Count() = 0 Or Not ValueIsFilled(NewFileOwner) Then
		Return False;
	EndIf;
	
	// Parent is the same, you do not have to do anything.
	If ArrayOfRefsToFiles.Count() > 0 AND (ArrayOfRefsToFiles[0].FileOwner = NewFileOwner) Then
		Return False;
	EndIf;
	
	BeginTransaction();
	Try
		Lock = New DataLock;
		For Each ReceivedFile In ArrayOfRefsToFiles Do
			LockItem = Lock.Add(Metadata.FindByType(TypeOf(ReceivedFile)).FullName());
			LockItem.SetValue("Ref",ReceivedFile);
		EndDo;
		Lock.Lock();
	
		For Each ReceivedFile In ArrayOfRefsToFiles Do
			FileObject = ReceivedFile.GetObject();
			FileObject.Lock();
			FileObject.FileOwner = NewFileOwner;
			FileObject.Write();
		EndDo;
	
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;
	
	Return True;
	
EndFunction

// The function changes the Parent property to objects of the Catalog.FilesFolders type. It returns 
// True if successful In the variable LoopFound it returns True if one of the folders is transferred to its child folder.
//
// Parameters:
//  RefsToFilesArray - Array - an array of files.
//  NewParent  - AnyRef - a new file owner.
//  LoopFound - Boolean - returns True if a loop is found.
//
// Returns:
//   Boolean  - shows whether the operation is performed successfully.
//
Function ChangeFoldersParent(ArrayOfRefsToFiles, NewParent, LoopFound) Export
	LoopFound = False;
	
	If ArrayOfRefsToFiles.Count() = 0 Then
		Return False;
	EndIf;
	
	// Parent is the same, you do not have to do anything.
	If ArrayOfRefsToFiles.Count() = 1 AND (ArrayOfRefsToFiles[0].Parent = NewParent) Then
		Return False;
	EndIf;
	
	If HasLoop(ArrayOfRefsToFiles, NewParent) Then
		LoopFound = True;
		Return False;
	EndIf;
	
	BeginTransaction();
	Try
		Lock = New DataLock;
		For Each ReceivedFile In ArrayOfRefsToFiles Do
			LockItem = Lock.Add(Metadata.FindByType(TypeOf(ReceivedFile)).FullName());
			LockItem.SetValue("Ref",ReceivedFile);
		EndDo;
		Lock.Lock();
	
		For Each ReceivedFile In ArrayOfRefsToFiles Do
			FileObject = ReceivedFile.GetObject();
			FileObject.Lock();
			FileObject.Parent = NewParent;
			FileObject.Write();
		EndDo;
	
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;
	
	Return True;
	
EndFunction

// Receives file data to open and reads from the common settings of FolderToSaveAs.
//
// Parameters:
//  FileOrVersionRef     - CatalogRef.Files, CatalogRef.FilesVersions - a file or a file version.
//  FormID      - UUID - a form UUID.
//  OwnerWorkingDirectory - String - a working directory of the file owner.
//
// Returns:
//   Structure - a structure with file data.
//
Function FileDataToSave(FileRef, VersionRef = Undefined, FormID = Undefined, OwnerWorkingDirectory = Undefined) Export

	FileData = FileDataToOpen(FileRef, VersionRef, FormID, OwnerWorkingDirectory);
	
	FolderForSaveAs = Common.CommonSettingsStorageLoad("ApplicationSettings", "FolderForSaveAs");
	FileData.Insert("FolderForSaveAs", FolderForSaveAs);

	Return FileData;
EndFunction

// Receives FileData and VersionURL of all subordinate files.
// Parameters:
//  FileRef - CatalogRef.Files - file.
//  FormID - a form UUID.
//
// Returns:
//   Array - an array of structures with file data.
Function FileDataAndURLOfAllFileVersions(FileRef, FormID) Export
	
	Query = New Query;
	Query.Text = 
		"SELECT ALLOWED
		|	FilesVersions.Ref AS Ref
		|FROM
		|	Catalog.FilesVersions AS FilesVersions
		|WHERE
		|	FilesVersions.Owner = &FileRef";
	
	Query.SetParameter("FileRef", FileRef);
	Result = Query.Execute();
	Selection = Result.Select();
	
	ReturnArray = New Array;
	While Selection.Next() Do
		
		VersionRef = Selection.Ref;
		FileData = FileData(FileRef, VersionRef);
		VersionURL = FilesOperationsInternal.GetTemporaryStorageURL(VersionRef, FormID);
		
		ReturnStructure = New Structure("FileData, VersionURL, VersionRef", 
			FileData, VersionURL, VersionRef);
		ReturnArray.Add(ReturnStructure);
	EndDo;
	
	// If versions are not stored, encrypting the file.
	If Not FileRef.StoreVersions Or Not ValueIsFilled(FileRef.CurrentVersion) Then
		FileData = FileData(FileRef);
		VersionURL = FilesOperationsInternal.GetTemporaryStorageURL(FileRef, FormID);
		
		ReturnStructure = New Structure("FileData, VersionURL, VersionRef", 
			FileData, VersionURL, FileRef);
		ReturnArray.Add(ReturnStructure);
	EndIf;
	
	Return ReturnArray;
EndFunction

// Adds a signature to the file version and marks the file as signed.
Procedure AddSignatureToFile(FileRef, SignatureProperties, FormID) Export
	
	AttributesStructure = Common.ObjectAttributesValues(FileRef, "BeingEditedBy, Encrypted");
	
	BeingEditedBy = AttributesStructure.BeingEditedBy;
	If ValueIsFilled(BeingEditedBy) Then
		Raise FilesOperationsInternalClientServer.FileUsedByAnotherProcessCannotBeSignedMessageString(FileRef);
	EndIf;
	
	Encrypted = AttributesStructure.Encrypted;
	If Encrypted Then
		ExceptionString = FilesOperationsInternalClientServer.EncryptedFileCannotBeSignedMessageString(FileRef);
		Raise ExceptionString;
	EndIf;
	
	If Not Common.SubsystemExists("StandardSubsystems.DigitalSignature") Then
		Return;
	EndIf;
	
	ModuleDigitalSignature = Common.CommonModule("DigitalSignature");
	ModuleDigitalSignature.AddSignature(FileRef, SignatureProperties, FormID);
	
EndProcedure

Procedure ShowTooltipsOnEditFiles(Value = Undefined) Export
	
	SetPrivilegedMode(True);
	If Value <> Undefined Then
		CommonServerCall.CommonSettingsStorageSave(
			"ApplicationSettings", "ShowTooltipsOnEditFiles", Value,,, True);
		RefreshReusableValues();
	EndIf;
	
EndProcedure

// Informative

// The function returns the number of Files locked by the current user by owner.
// 
// Parameters:
//  FileOwner  - AnyRef - file owner.
//
// Returns:
//   Number  - a number of locked files.
//
Function FilesLockedByCurrentUserCount(FileOwner) Export
	
	Return FilesOperationsInternal.LockedFilesCount(FileOwner);
	
EndFunction

// Receives the number of file versions.
// Parameters:
//  FileRef - CatalogRef.Files - file.
//
// Returns:
//   Number - the number of versions
Function GetVersionsCount(FileRef)
	
	SetPrivilegedMode(True);
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	COUNT(*) AS Count
	|FROM
	|	Catalog.FilesVersions AS FilesVersions
	|WHERE
	|	FilesVersions.Owner = &FileRef";
	
	Query.SetParameter("FileRef", FileRef);
	Selection = Query.Execute().Select();
	Selection.Next();
	
	Return Number(Selection.Count);
	
EndFunction

// Returns True if there is looping (if a folder is moved into its own child folder).
// Parameters:
//  RefsToFilesArray - Array - an array of files.
//  NewParent  - AnyRef - a new file owner.
//
// Returns:
//   Boolean  - has looping.
//
Function HasLoop(Val ArrayOfRefsToFiles, NewParent)
	
	If ArrayOfRefsToFiles.Find(NewParent) <> Undefined Then
		Return True; // found looping
	EndIf;
	
	Parent = NewParent.Parent;
	If Parent.IsEmpty() Then // got to root
		Return False;
	EndIf;
	
	If HasLoop(ArrayOfRefsToFiles, Parent) Then
		Return True; // found looping
	EndIf;
	
	Return False;
	
EndFunction

// Returns True if the specified item of the FilesFolders has a child node with this name.
//
// Parameters:
//  FolderName					 - String					     - a folder name.
//  Parent					 - DefinedType.AttachedFilesOwner	 - folder parent.
//  FirstFolderWithSameName	 - DefinedType.AttachedFilesOwner	 - the first found folder with the specified name.
// 
// Returns:
//  Boolean - has a child item with this name.
//
Function HasFolderWithThisName(FolderName, Parent, FirstFolderWithSameName) Export
	
	FirstFolderWithSameName = Catalogs.FilesFolders.EmptyRef();
	
	QueryToFolders = New Query;
	QueryToFolders.SetParameter("Description", FolderName);
	QueryToFolders.SetParameter("Parent", Parent);
	QueryToFolders.Text =
	"SELECT ALLOWED TOP 1
	|	FilesFolders.Ref AS Ref
	|FROM
	|	Catalog.FilesFolders AS FilesFolders
	|WHERE
	|	FilesFolders.Description = &Description
	|	AND FilesFolders.Parent = &Parent";
	
	If TypeOf(Parent) <> Type("CatalogRef.FilesFolders") Then
		FilesStorageCatalogName = FilesOperationsInternal.FileStoringCatalogName(Parent);
		QueryToFolders.Text = StrReplace(QueryToFolders.Text, ".FilesFolders", "." + FilesStorageCatalogName);
	EndIf;
	
	QueryResult = QueryToFolders.Execute(); 
	
	If NOT QueryResult.IsEmpty() Then
		QuerySelection = QueryResult.Unload();
		FirstFolderWithSameName = QuerySelection[0].Ref;
		Return True;
	EndIf;
	
	Return False;
	
EndFunction

Function FullFolderPath(Folder)
	
	FullPath = "";
	
	FolderParent = Common.ObjectAttributeValue(Folder.Ref, "Parent");
	
	If ValueIsFilled(FolderParent) Then
	
		FullPath = "";
		While ValueIsFilled(FolderParent) Do
			
			FullPath = String(FolderParent) + "\" + FullPath;
			FolderParent = Common.ObjectAttributeValue(FolderParent, "Parent");
			If Not ValueIsFilled(FolderParent) Then
				Break;
			EndIf;
			
		EndDo;
		
		FullPath = FullPath + String(Folder.Ref);
		
		If Not IsBlankString(FullPath) Then
			FullPath = """" + FullPath + """";
		EndIf;
	
	EndIf;
	
	Return FullPath;
	
EndFunction

Function FileToSynchronizeByCloudService(File)
	
	Query = New Query;
	Query.Text = 
		"SELECT TOP 1
		|	COUNT(FilesSynchronizationWithCloudServiceStatuses.File) AS File
		|FROM
		|	InformationRegister.FilesSynchronizationWithCloudServiceStatuses AS FilesSynchronizationWithCloudServiceStatuses
		|WHERE
		|	FilesSynchronizationWithCloudServiceStatuses.File = &File";
	
	Query.SetParameter("File", File);
	
	QueryResult = Query.Execute();
	If QueryResult.IsEmpty() Then
		Return False;
	EndIf;
	
	Return True;
	
EndFunction

Function AttachedFilesCount(FilesOwner, ReturnFilesData = False) Export
	
	OwnerFiles = New Structure;
	OwnerFiles.Insert("FilesCount", 0);
	OwnerFiles.Insert("FileData", Undefined);
	
	StorageCatalogName = FilesOperationsInternal.FileStoringCatalogName(FilesOwner);
	If ValueIsFilled(StorageCatalogName) Then
	
		QueryText = 
		"SELECT ALLOWED DISTINCT
		|	CatalogFilesStorage.Ref AS File
		|FROM
		|	&CatalogName AS CatalogFilesStorage
		|WHERE
		|	CatalogFilesStorage.FileOwner = &FileOwner
		|	AND &IsFolder = FALSE
		|	AND &Internal = FALSE";
		QueryText = StrReplace(QueryText, "&CatalogName", "Catalog." + StorageCatalogName);
		
		QueryText = StrReplace(QueryText, "&Internal",
			?(FilesOperationsInternal.HasInternalAttribute(StorageCatalogName),
			"CatalogFilesStorage.Internal", "FALSE"));
			
		QueryText = StrReplace(QueryText, "&IsFolder", 
			?(Metadata.Catalogs[StorageCatalogName].Hierarchical,
			"CatalogFilesStorage.IsFolder", "FALSE"));
			
		Query = New Query(QueryText);
		Query.SetParameter("FileOwner", FilesOwner);
		FilesTable = Query.Execute().Unload();
		FilesCount = FilesTable.Count();
		
		OwnerFiles.FilesCount = FilesCount;
		If FilesCount > 0 Then
			OwnerFiles.FileData = FileData(FilesTable[0].File, , , False);
		EndIf;
		
	EndIf;
	
	Return ?(ReturnFilesData, OwnerFiles, OwnerFiles.FilesCount);
	
EndFunction

Function HasAccessRight(Right, Ref) Export
	
	Return AccessRight(Right, Ref.Metadata());
	
EndFunction

Function ImageAddingOptions(FilesOwner) Export
	
	AddingOptions = New Structure;
	AddingOptions.Insert("InsertRight", HasAccessRight("Insert", FilesOwner));
	AddingOptions.Insert("OwnerFiles" , AttachedFilesCount(FilesOwner, True));
	
	Return AddingOptions;
	
EndFunction

////////////////////////////////////////////////////////////////////////////////
// Updating an infobase.

// Creates new files by analogy with the specified ones.
// Parameters:
//  FilesArray  - Array - an array of files CatalogRef.Files - the existing files.
//  NewFileOwner - AnyRef - a file owner.
//
Procedure CopyFiles(FilesArray, NewFileOwner) Export
	
	For each File In FilesArray Do
		CopyFile(File, NewFileOwner);
	EndDo;
	
EndProcedure

// Writes FileStorage to the infobase.
//
// Parameters:
//   VersionRef - a reference to file version.
//   FileStorage - ValueStorage with file binary data that need to be written.
//
Procedure WriteFileToInfobase(VersionRef, FileStorage)
	
	SetPrivilegedMode(True);
	
	RecordManager = InformationRegisters.BinaryFilesData.CreateRecordManager();
	RecordManager.File = VersionRef;
	RecordManager.FileBinaryData = FileStorage;
	RecordManager.Write(True);
	
EndProcedure

// Checks the Encypted flag for the file.
Procedure CheckEncryptedFlag(FileRef, Encrypted, UUID = Undefined) Export
	
	BeginTransaction();
	Try
		DataLock = New DataLock;
		DataLockItem = DataLock.Add(Metadata.FindByType(TypeOf(FileRef)).FullName());
		DataLockItem.SetValue("Ref", FileRef);
		DataLock.Lock();
		
		FileObject = FileRef.GetObject();
		LockDataForEdit(FileRef, , UUID);
		
		FileObject.Encrypted = Encrypted;
		// To write a previously signed object.
		FileObject.AdditionalProperties.Insert("WriteSignedObject", True);
		FileObject.Write();
		UnlockDataForEdit(FileRef, UUID);
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;
	
EndProcedure

// Updates the size of the file and current version. It is required when importing the encrypted file via email.
Procedure UpdateSizeOfFileAndVersion(FileData, FileSize, UUID) Export
	
	BeginTransaction();
	Try
		
		VersionObject = FileData.Version.GetObject();
		VersionObject.Lock();
		VersionObject.Size = FileSize;
		// To write a previously signed object.
		VersionObject.AdditionalProperties.Insert("WriteSignedObject", True);
		VersionObject.Write();
		
		FileObject = FileData.Ref.GetObject();
		LockDataForEdit(FileObject.Ref, , UUID);
		// To write a previously signed object.
		FileObject.AdditionalProperties.Insert("WriteSignedObject", True);
		FileObject.Write();
		UnlockDataForEdit(FileObject.Ref, UUID);
		
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;
	
EndProcedure

// Writes the file version encoding.
//
// Parameters:
//   VersionRef - CatalogRef.FilesVersions - a reference to the file version.
//   Encoding - String - new encoding of the file version.
//
Procedure WriteFileVersionEncoding(VersionRef, Encoding) Export
	
	SetPrivilegedMode(True);
	
	RecordManager = InformationRegisters.FilesEncoding.CreateRecordManager();
	RecordManager.File = VersionRef;
	RecordManager.Encoding = Encoding;
	RecordManager.Write(True);
	
EndProcedure

// Writes the file version encoding.
//
// Parameters:
//   VersionRef - a reference to file version.
//   Encoding - an encoding row.
//   ExtractedText - a text, extracted from the file.
//
Procedure WriteFileVersionEncodingAndExtractedText(VersionRef, Encoding, ExtractedText) Export
	
	WriteFileVersionEncoding(VersionRef, Encoding);
	WriteTextExtractionResultOnWrite(VersionRef, Enums.FileTextExtractionStatuses.Extracted, 
		ExtractedText);
	
EndProcedure

// Writes to the server the text extraction results that are the extracted text and the TextExtractionStatus.
Procedure WriteTextExtractionResultOnWrite(VersionRef, ExtractionResult, TempTextStorageAddress)
	
	FileLocked = False;
	
	VersionMetadata = Metadata.FindByType(TypeOf(VersionRef));
	If Common.HasObjectAttribute("ParentVersion", VersionMetadata) Then
		File = VersionRef.Owner;
		
		If File.CurrentVersion = VersionRef Then
			
			Try
				LockDataForEdit(File);
				FileLocked = True;
			Except
				// Exception if the object is already locked, including the Lock method.
				Return;
			EndTry;
			
		EndIf;
	Else
		File = VersionRef;
	EndIf;
	
	FullTextSearchUsing = Metadata.ObjectProperties.FullTextSearchUsing.Use;
	
	BeginTransaction();
	Try
		VersionLock = New DataLock;
		DataLockItem = VersionLock.Add(Metadata.FindByType(TypeOf(VersionRef)).FullName());
		DataLockItem.SetValue("Ref", VersionRef);
		VersionLock.Lock();
		
		VersionObject = VersionRef.GetObject();
		
		If VersionMetadata.FullTextSearch = FullTextSearchUsing Then
			If Not IsBlankString(TempTextStorageAddress) Then
				
				If Not IsTempStorageURL(TempTextStorageAddress) Then
					VersionObject.TextStorage = New ValueStorage(TempTextStorageAddress, New Deflation(9));
					VersionObject.TextExtractionStatus = Enums.FileTextExtractionStatuses.Extracted;
				Else
					TextExtractionResult = FilesOperationsInternal.ExtractText(TempTextStorageAddress);
					VersionObject.TextStorage = TextExtractionResult.TextStorage;
					VersionObject.TextExtractionStatus = TextExtractionResult.TextExtractionStatus;
				EndIf;
				
			EndIf;
		Else
			VersionObject.TextStorage = New ValueStorage("");
			VersionObject.TextExtractionStatus = Enums.FileTextExtractionStatuses.NotExtracted;
		EndIf;
		
		If ExtractionResult = "NotExtracted" Then
			VersionObject.TextExtractionStatus = Enums.FileTextExtractionStatuses.NotExtracted;
		ElsIf ExtractionResult = "Extracted" Then
			VersionObject.TextExtractionStatus = Enums.FileTextExtractionStatuses.Extracted;
		ElsIf ExtractionResult = "FailedExtraction" Then
			VersionObject.TextExtractionStatus = Enums.FileTextExtractionStatuses.FailedExtraction;
		EndIf;
	
		// To write a previously signed object.
		VersionObject.AdditionalProperties.Insert("WriteSignedObject", True);
		VersionObject.Write();
		
		If TypeOf(File) = Type("CatalogRef.Files") Then
			FileToCompare = File.CurrentVersion;
		Else
			FileToCompare = VersionRef;
		EndIf;
		
		If FileToCompare = VersionRef Then
			FileLock = New DataLock;
			DataLockItem = FileLock.Add(Metadata.FindByType(TypeOf(File)).FullName());
			DataLockItem.SetValue("Ref", File);
			FileLock.Lock();
			
			FileObject = File.GetObject();
			FileObject.TextStorage = VersionObject.TextStorage;
			// To write a previously signed object.
			FileObject.AdditionalProperties.Insert("WriteSignedObject", True);
			FileObject.Write();
		EndIf;
		
		CommitTransaction();
	Except
		RollbackTransaction();
		
		If FileLocked Then
			UnlockDataForEdit(File);
		EndIf;
		
		Raise;
	EndTry;
	
	If FileLocked Then
		UnlockDataForEdit(File);
	EndIf;
	
EndProcedure

//////////////////////////////////////////////////////////////////////////////////////////////////
///// Common file functions
// See this procedure in the FilesOperationsInternal module.
Procedure RecordTextExtractionResult(FileOrVersionRef,
                                            ExtractionResult,
                                            TempTextStorageAddress) Export
	
	FilesOperationsInternal.RecordTextExtractionResult(
		FileOrVersionRef,
		ExtractionResult,
		TempTextStorageAddress);
	
EndProcedure

// For internal use only.
Procedure CheckSignatures(SourceData, RowsData) Export
	
	If Not Common.SubsystemExists("StandardSubsystems.DigitalSignature") Then
		Return;
	EndIf;
	ModuleDigitalSignature = Common.CommonModule("DigitalSignature");
	
	CryptoManager = ModuleDigitalSignature.CryptoManager("SignatureCheck");
	
	For each SignatureRow In RowsData Do
		ErrorDescription = "";
		SignatureCorrect = ModuleDigitalSignature.VerifySignature(CryptoManager,
			SourceData, SignatureRow.SignatureAddress, ErrorDescription, SignatureRow.SignatureDate);
		
		SignatureRow.SignatureValidationDate = CurrentSessionDate();
		SignatureRow.SignatureCorrect   = SignatureCorrect;
		SignatureRow.ErrorDescription = ErrorDescription;
		
		FilesOperationsInternalClientServer.FillSignatureStatus(SignatureRow);
	EndDo;
	
EndProcedure

// Enters the number to the ScannedFilesNumbers information register.
//
// Parameters:
//   Owner - AnyRef - a file owner.
//   NewNumber -  Number  - max number for scanning.
//
Procedure EnterMaxNumberToScan(Owner, NewNumber) Export
	
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
		If NewNumber <= Number Then // Somebody has already written the bigger number.
			RollbackTransaction();
			Return;
		EndIf;
		
		Number = NewNumber;
		SetPrivilegedMode(True);
		
		// Writing a new number to the register.
		RecordSet = InformationRegisters.ScannedFilesNumbers.CreateRecordSet();
		
		RecordSet.Filter.Owner.Set(Owner);
		
		NewRecord = RecordSet.Add();
		NewRecord.Owner = Owner;
		NewRecord.Number = Number;
		
		RecordSet.Write();
		
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;
	
EndProcedure

Function PutFilesInTempStorage(Parameters) Export
	
	Result = New Array;
	TempFolderName = GetTempFileName();
	CreateDirectory(TempFolderName);
	
	For Each FileAttachment In Parameters.FilesArray Do
		FilesOperationsInternal.GenerateFilesListToSendViaEmail(Result, FileAttachment, Parameters.FormID);
	EndDo;
	
	Return Result;
	
EndFunction

///////////////////////////////////////////////////////////////////////////////////
// Print the spreadsheet document with the digital signature stamp.

Function SpreadsheetDocumentWithStamp(RefToFile, Ref) Export
	
	FileData    = FilesOperations.FileData(RefToFile);
	TempFile = GetTempFileName(".mxl");
	BinaryData = GetFromTempStorage(FileData.BinaryFileDataRef);
	BinaryData.Write(TempFile);
	
	SpreadsheetDocument = New SpreadsheetDocument;
	SpreadsheetDocument.Read(TempFile);
	
	DeleteFiles(TempFile);
	
	ModuleDigitalSignature = Common.CommonModule("DigitalSignature");
	
	StampParameters = New Structure;
	StampParameters.Insert("MarkText", "");
	StampParameters.Insert("Logo");
	
	DigitalSignatures = ModuleDigitalSignature.SetSignatures(Ref);
	
	FileOwner = Common.ObjectAttributeValue(Ref, "FileOwner");
	
	FileInfo = New Structure;
	FileInfo.Insert("FileOwner", FileOwner);
	
	Stamps = New Array;
	For Each Signature In DigitalSignatures Do
		Certificate = Signature.Certificate;
		CryptoCertificate = New CryptoCertificate(Certificate.Get());
		FilesOperationsOverridable.OnPrintFileWithStamp(StampParameters, CryptoCertificate);
		
		Stamp = ModuleDigitalSignature.DigitalSignatureVisualizationStamp(CryptoCertificate,
			Signature.SignatureDate, StampParameters.MarkText, StampParameters.Logo);
		Stamps.Add(Stamp);
	EndDo;
	
	ModuleDigitalSignature.AddStampsToSpreadsheetDocument(SpreadsheetDocument, Stamps);
	
	Return SpreadsheetDocument;
EndFunction

#EndRegion
