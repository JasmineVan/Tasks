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

	ConditionalAppearance.Items.Clear();
	FilesOperationsInternal.FillConditionalAppearanceOfFilesList(List);
	FilesOperationsInternal.FillConditionalAppearanceOfFoldersList(Folders);
	FilesOperationsInternal.AddFiltersToFilesList(List);
	
	Items.ShowServiceFiles.Visible = Users.IsFullUser();
	
	If Parameters.Property("Folder") AND Parameters.Folder <> Undefined Then
		InitialFolder = Parameters.Folder;
	Else
		InitialFolder = Common.FormDataSettingsStorageLoad("Files", "CurrentFolder");
		If InitialFolder = Undefined Then // An attempt to import settings, saved in the previous versions.
			InitialFolder = Common.FormDataSettingsStorageLoad("FileStorage", "CurrentFolder");
		EndIf;
	EndIf;
	
	If InitialFolder = Catalogs.FilesFolders.EmptyRef() Or InitialFolder = Undefined Then
		InitialFolder = Catalogs.FilesFolders.Templates;
	EndIf;
	
	If Parameters.Property("SendOptions") Then
		SendOptions = Parameters.SendOptions;
	Else
		SendOptions = FilesOperationsInternal.PrepareSendingParametersStructure();
	EndIf;
	
	Items.Folders.CurrentRow = InitialFolder;
	
	CurrentUser = Users.AuthorizedUser();
	If TypeOf(CurrentUser) = Type("CatalogRef.ExternalUsers") Then
		FilesOperationsInternal.ChangeFormForExternalUser(ThisObject, True);
	EndIf;
	
	List.Parameters.SetParameterValue(
		"Owner", InitialFolder);
	List.Parameters.SetParameterValue(
		"CurrentUser", CurrentUser);
		
	EmptyUsers = New Array;
	EmptyUsers.Add(Undefined);
	EmptyUsers.Add(Catalogs.Users.EmptyRef());
	EmptyUsers.Add(Catalogs.ExternalUsers.EmptyRef());
	EmptyUsers.Add(Catalogs.FileSynchronizationAccounts.EmptyRef());
	List.Parameters.SetParameterValue(
		"EmptyUsers",  EmptyUsers);
	
	ShowSizeColumn = FilesOperationsInternal.GetShowSizeColumn();
	If ShowSizeColumn = False Then
		Items.ListCurrentVersionSize.Visible = False;
	EndIf;
	
	UseHierarchy = True;
	SetHierarchy(UseHierarchy);
	
	OnChangeUseSignOrEncryptionAtServer();
	
	FillPropertyValues(ThisObject, FolderRightsSettings(Items.Folders.CurrentRow));
	
	If ClientApplication.CurrentInterfaceVariant() = ClientApplicationInterfaceVariant.Version8_2 Then
		Items.FormChange.Visible = False;
		Items.FormChange82.Visible = True;
	EndIf;
	
	UsePreview = Common.CommonSettingsStorageLoad(
		"Files",
		"Preview");
	
	If UsePreview <> Undefined Then
		Preview = UsePreview;
		Items.FileDataURL.Visible = UsePreview;
		Items.Preview.Check = UsePreview;
	EndIf;
	
	PreviewEnabledExtensions = FilesOperationsInternal.ExtensionsListForPreview();
	
	Items.CloudServiceNoteGroup.Visible = False;
	UseFileSync = GetFunctionalOption("UseFileSync");
	
	Items.FoldersContextMenuSyncSettings.Visible = AccessRight("Edit", Metadata.Catalogs.FileSynchronizationAccounts);
	Items.Compare.Visible = Not Common.IsLinuxClient()
		AND Not Common.IsWebClient();
	
	UniversalDate = CurrentSessionDate();
	List.Parameters.SetParameterValue("SecondsToLocalTime",
		ToLocalTime(UniversalDate, SessionTimeZone()) - UniversalDate);
		
	If Common.IsMobileClient() Then
		Items.Folders.TitleLocation = FormItemTitleLocation.Auto;
		Items.FormCreateSubmenu.Representation = ButtonRepresentation.Picture;
		Items.FormCreateFromScanner.Title = NStr("ru = 'С камеры устройства...'; en = 'From device camera...'; pl = 'Z kamery urządzenia...';de = 'Von der Kamera des Geräts...';ro = 'De pe camera dispozitivului...';tr = 'Kameradan ...'; es_ES = 'Desde cámara del dispositivo...'");
	EndIf;
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	Items.FormCreateFromScanner.Visible = FilesOperationsInternalClient.ScanCommandAvailable();
	
	SetFileCommandsAvailability();
	
#If MobileClient Then
	SetFoldersTreeTitle();
#EndIf
	
EndProcedure

&AtClient
Procedure OnClose(Exit)
	
	If Exit Then
		Return;
	EndIf;
	OnCloseAtServer();
	StandardSubsystemsClient.SetClientParameter(
		"LockedFilesCount", LockedFilesCount);
	
EndProcedure

&AtServer
Procedure OnCloseAtServer()
	
	LockedFilesCount = FilesOperationsInternal.LockedFilesCount();
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If Upper(EventName) = Upper("Write_ConstantsSet")
		AND (Upper(Source) = Upper("UseDigitalSignature")
		Or Upper(Source) = Upper("UseEncryption")) Then
		
		AttachIdleHandler("OnChangeSigningOrEncryptionUsage", 0.3, True);
		Return;
	ElsIf EventName = "Write_FilesFolders" Then
		Items.Folders.Refresh();
		Items.List.Refresh();
		
		If Source <> Undefined Then
			Items.Folders.CurrentRow = Source;
		EndIf;
	ElsIf EventName = "Write_File"
		AND TypeOf(Source) <> Type("Array") Then
		
		Items.List.Refresh();
		If TypeOf(Parameter) = Type("Structure")
			AND Parameter.Property("File") Then
			Items.List.CurrentRow = Parameter.File;
		ElsIf Source <> Undefined Then
			Items.List.CurrentRow = Source;
		EndIf;
		
	EndIf;
	
	SetFileCommandsAvailability();
	
EndProcedure

&AtClient
Procedure ChoiceProcessing(SelectedValue, ChoiceSource)
	
	If Upper(ChoiceSource.FormName) = Upper("Catalog.FilesFolders.Form.ChoiceForm") Then
		
		If SelectedValue = Undefined Then
			Return;
		EndIf;
		
		SelectedRows = Items.List.SelectedRows;
		FilesOperationsInternalClient.MoveFilesToFolder(SelectedRows, SelectedValue);
		
		For Each SelectedRow In SelectedRows Do
			Notify("Write_File", New Structure("Event", "FileDataChanged"), SelectedRow);
		EndDo;
		
		Items.List.Refresh();
		
	EndIf;
	
EndProcedure

&AtServer
Procedure OnLoadDataFromSettingsAtServer(Settings)
	
	SetHierarchy(Settings["UseHierarchy"]);
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure DecorationSynchronizationDateURLProcessing(Item, FormattedStringURL, StandardProcessing)
	
	If FormattedStringURL = "OpenJournal" Then
		
		StandardProcessing = False;
		FilterParameters      = EventLogFilterData(Items.Folders.CurrentData.Account);
		EventLogClient.OpenEventLog(FilterParameters, ThisObject);
		
	EndIf;
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersList

&AtClient
Procedure ListChoice(Item, RowSelected, Field, StandardProcessing)
	If TypeOf(RowSelected) = Type("DynamicalListGroupRow") Then
		Return;
	EndIf;
	
	StandardProcessing = False;
	
	HowToOpen = FilesOperationsInternalClient.PersonalFilesOperationsSettings().ActionOnDoubleClick;
	
	If HowToOpen = "OpenCard" Then
		ShowValue(, RowSelected);
		Return;
	EndIf;
	
	FileData = FilesOperationsInternalServerCall.FileDataToOpen(RowSelected,
		Undefined, UUID, Undefined, FilePreviousURL);
	
	HandlerParameters = New Structure;
	HandlerParameters.Insert("FileData", FileData);
	Handler = New NotifyDescription("ListSelectionAfterEditModeChoice", ThisObject, HandlerParameters);
	
	FilesOperationsInternalClient.SelectModeAndEditFile(Handler, FileData, Not FileData.Internal);
	
EndProcedure

&AtClient
Procedure ListBeforeAddRow(Item, Cancel, Clone, Parent, Folder)
	
	If Items.Folders.CurrentRow = Undefined Then
		Cancel = True;
		Return;
	EndIf; 
	
	If Items.Folders.CurrentRow.IsEmpty() Then
		Cancel = True;
		Return;
	EndIf; 
	
	FileOwner = Items.Folders.CurrentRow;
	BasisFile = Items.List.CurrentRow;
	
	Cancel = True;
	
	If Clone Then
		FilesOperationsClient.CopyFile(FileOwner, BasisFile);
	Else
		FilesOperationsInternalClient.AppendFile(Undefined, FileOwner, ThisObject, 2, True);
	EndIf;
	
EndProcedure

&AtClient
Procedure ListDragCheck(Item, DragParameters, StandardProcessing, Row, Field)
	
	StandardProcessing = False;
	If FilesBeingEditedInCloudService Then
		DragParameters.Action = DragAction.Cancel;
		DragParameters.Value = Undefined;
	EndIf;
	
EndProcedure

&AtClient
Procedure ListDrag(Item, DragParameters, StandardProcessing, Row, Field)
	StandardProcessing = False;
	DragToFolder(Undefined, DragParameters.Value, DragParameters.Action);
EndProcedure

&AtClient
Procedure ListOnActivateRow(Item)
	
	If Items.List.CurrentData <> Undefined Then
		URL = GetURL(Items.List.CurrentData.Ref);
	EndIf;
	IdleHandlerSetFileCommandsAccessibility();
	
EndProcedure

&AtClient
Procedure ListOnChange(Item)
	
	Notify("Write_File", New Structure("Event", "FileDataChanged"), Item.SelectedRows);
	
EndProcedure

#EndRegion

#Region FolderFormTableItemsEventHandlers

&AtClient
Procedure FoldersOnActivateRow(Item)
	
	AttachIdleHandler("SetCommandsAvailabilityOnChangeFolder", 0.1, True);
	
	If UseFileSync Then
		AttachIdleHandler("SetFilesSynchronizationNoteVisibility", 0.1, True);
	EndIf;
	
#If MobileClient Then
	AttachIdleHandler("SetFoldersTreeTitle", 0.1, True);
	CurrentItem = Items.List;
#EndIf
	
EndProcedure

&AtClient
Procedure FoldersDragCheck(Item, DragParameters, StandardProcessing, Row, Field)
	StandardProcessing = False;
EndProcedure

&AtClient
Procedure FoldersDrag(Item, DragParameters, StandardProcessing, Row, Field)
	StandardProcessing = False;
	DragToFolder(Row, DragParameters.Value, DragParameters.Action);
EndProcedure

&AtClient
Procedure FoldersOnChange(Item)
	Items.List.Refresh();
EndProcedure

#EndRegion

#Region FormCommandHandlers

&AtClient
Procedure ImportFilesExecute()
	
	Handler = New NotifyDescription("ImportFilesAfterExtensionInstalled", ThisObject);
	FilesOperationsInternalClient.ShowFileSystemExtensionInstallationQuestion(Handler);
	
EndProcedure

&AtClient
Procedure FolderImport(Command)
	
	Handler = New NotifyDescription("ImportFolderAfterExtensionInstalled", ThisObject);
	FilesOperationsInternalClient.ShowFileSystemExtensionInstallationQuestion(Handler);
	
EndProcedure

&AtClient
Procedure FolderExportExecute()
	
	FormParameters = New Structure;
	FormParameters.Insert("ExportFolder", Items.Folders.CurrentRow);
	
	Handler = New NotifyDescription("ExportFolderAfterInstallExtension", ThisObject, FormParameters);
	FilesOperationsInternalClient.ShowFileSystemExtensionInstallationQuestion(Handler);
	
EndProcedure

&AtClient
Procedure AddFile(Command)
	
	FilesOperationsInternalClient.AddFileFromFileSystem(Items.Folders.CurrentRow, ThisObject);
	
EndProcedure

&AtClient
Procedure AddFileByTemplate(Command)
	
	AddingOptions = New Structure;
	AddingOptions.Insert("ResultHandler",                    Undefined);
	AddingOptions.Insert("FileOwner",                           Items.Folders.CurrentRow);
	AddingOptions.Insert("OwnerForm",                           ThisObject);
	AddingOptions.Insert("DontOpenCardAfterCreateFromFIle", True);
	FilesOperationsInternalClient.AddBasedOnTemplate(AddingOptions);
	
EndProcedure

&AtClient
Procedure AddFileFromScanner(Command)
	
	AddingOptions = New Structure;
	AddingOptions.Insert("ResultHandler", Undefined);
	AddingOptions.Insert("FileOwner", Items.Folders.CurrentRow);
	AddingOptions.Insert("OwnerForm", ThisObject);
	AddingOptions.Insert("DontOpenCardAfterCreateFromFIle", True);
	AddingOptions.Insert("IsFile", True);
	FilesOperationsInternalClient.AddFromScanner(AddingOptions);
	
EndProcedure

&AtClient
Procedure CreateFolderExecute()
	
	NewFolderParameters = New Structure("Parent", Items.Folders.CurrentRow);
	OpenForm("Catalog.FilesFolders.ObjectForm", NewFolderParameters, Items.Folders);
	
EndProcedure

&AtClient
Procedure UseHierarchy(Command)
	
	UseHierarchy = Not UseHierarchy;
	If UseHierarchy AND (Items.List.CurrentData <> Undefined) Then 
		
		If Items.List.CurrentData.Property("FileOwner") Then 
			Items.Folders.CurrentRow = Items.List.CurrentData.FileOwner;
		Else
			Items.Folders.CurrentRow = Undefined;
		EndIf;	
		
		List.Parameters.SetParameterValue("Owner", Items.Folders.CurrentRow);
	EndIf;	
	SetHierarchy(UseHierarchy);
	
EndProcedure

&AtClient
Procedure OpenFileExecute()
	
	If Not FileCommandsAvailable() Then 
		Return;
	EndIf;
	
	FileData = FilesOperationsInternalServerCall.FileDataToOpen(Items.List.CurrentRow, 
		Undefined, UUID, Undefined, FilePreviousURL);
	FilesOperationsClient.OpenFile(FileData, False);
	
EndProcedure

&AtClient
Procedure Edit(Command)
	
	If Not FileCommandsAvailable() Then 
		Return;
	EndIf;
	
	Handler = New NotifyDescription("SetFileCommandsAvailability", ThisObject);
	FilesOperationsInternalClient.EditWithNotification(Handler, Items.List.CurrentRow);
	
EndProcedure

&AtClient
Function FileCommandsAvailable()
	
	Return FilesOperationsInternalClient.FileCommandsAvailable(Items);
	
EndFunction

&AtClient
Procedure EndEdit(Command)
	
	FilesArray = New Array;
	For Each ListItem In Items.List.SelectedRows Do
		RowData = Items.List.RowData(ListItem);
		
		If NOT RowData.FileBeingEdited
			OR NOT RowData.CurrentUserEditsFile Then
			Continue;
		EndIf;
		FilesArray.Add(RowData.Ref);
	EndDo;
	
	If FilesArray.Count() > 1 Then
		FormParameters = New Structure;
		FormParameters.Insert("FilesArray",                     FilesArray);
		FormParameters.Insert("CanCreateFileVersions", True);
		FormParameters.Insert("BeingEditedBy",                      RowData.BeingEditedBy);
		
		OpenForm("DataProcessor.FilesOperations.Form.FormFinishEditing", FormParameters, ThisObject);
	ElsIf FilesArray.Count() = 1 Then
		Handler = New NotifyDescription("SetFileCommandsAvailability", ThisObject);
		FileUpdateParameters = FilesOperationsInternalClient.FileUpdateParameters(Handler, RowData.Ref, UUID);
		FilesOperationsInternalClient.EndEditAndNotify(FileUpdateParameters);
	EndIf;
	
EndProcedure

&AtClient
Procedure Lock(Command)
	
	If NOT FileCommandsAvailable() Then
		Return;
	EndIf;
	
	FilesCount = Items.List.SelectedRows.Count();
	
	If FilesCount = 1 Then
		Handler = New NotifyDescription("SetFileCommandsAvailability", ThisObject);
		FilesOperationsInternalClient.LockWithNotification(Handler, Items.List.CurrentRow);
	ElsIf FilesCount > 1 Then
		FilesArray = New Array;
		For Each ListItem In Items.List.SelectedRows Do
			RowData = Items.List.RowData(ListItem);
			
			If ValueIsFilled(RowData.BeingEditedBy) Then
				Continue;
			EndIf;
			FilesArray.Add(RowData.Ref);
		EndDo;
		Handler = New NotifyDescription("SetFileCommandsAvailability", ThisObject, FilesArray);
		FilesOperationsInternalClient.LockWithNotification(Handler, FilesArray);
	EndIf;
	
EndProcedure

&AtClient
Procedure Unlock(Command)
	
	If Not FileCommandsAvailable() Then 
		Return;
	EndIf;
	
	FilesOperationsInternalClient.UnlockFiles(Items.List);
	SetFileCommandsAvailability();
	
EndProcedure

&AtClient
Procedure SaveChanges(Command)
	
	If Not FileCommandsAvailable() Then 
		Return;
	EndIf;
	
	Handler = New NotifyDescription("SetFileCommandsAvailability", ThisObject);
	
	FilesOperationsInternalClient.SaveFileChangesWithNotification(
		Handler,
		Items.List.CurrentRow,
		UUID);
	
EndProcedure

&AtClient
Procedure OpenFileDirectory(Command)
	
	If Not FileCommandsAvailable() Then 
		Return;
	EndIf;
	
	FileData = FilesOperationsInternalServerCall.FileDataToOpen(Items.List.CurrentRow,
		Undefined, UUID, Undefined, FilePreviousURL);
	FilesOperationsClient.OpenFileDirectory(FileData);
	
EndProcedure

&AtClient
Procedure SaveAs(Command)
	
	If Not FileCommandsAvailable() Then 
		Return;
	EndIf;
	
	FileData = FilesOperationsInternalServerCall.FileDataToSave(
		Items.List.CurrentRow, , UUID);
	FilesOperationsInternalClient.SaveAs(Undefined, FileData, UUID);
	
EndProcedure

&AtClient
Procedure UpdateFromFileOnHardDrive(Command)
	
	If Not FileCommandsAvailable() Then 
		Return;
	EndIf;
	
	FileData = FilesOperationsInternalServerCall.FileDataAndWorkingDirectory(Items.List.CurrentRow);
	FilesOperationsInternalClient.UpdateFromFileOnHardDriveWithNotification(Undefined, FileData, UUID);
	
EndProcedure

&AtClient
Procedure ListBeforeChangeRow(Item, Cancel)
	Cancel = True;
	
	FormOpenParameters = New Structure("Key, SendOptions", Item.CurrentRow, SendOptions);
	OpenForm("Catalog.Files.Form.ItemForm", FormOpenParameters);
	
EndProcedure

&AtClient
Procedure MoveToFolder(Command)
	
	If Not FileCommandsAvailable() Then 
		Return;
	EndIf;
	
	FormParameters = New Structure;
	FormParameters.Insert("Title",    NStr("ru = 'Выбор папки'; en = 'Select folder'; pl = 'Wybór folderu';de = 'Ordnerauswahl';ro = 'Alegeți un dosar';tr = 'Klasör seçimi'; es_ES = 'Selección de carpeta'"));
	FormParameters.Insert("CurrentFolder", Items.Folders.CurrentRow);
	FormParameters.Insert("ChoiceMode",  True);
	
	OpenForm("Catalog.FilesFolders.ChoiceForm", FormParameters, ThisObject);
	
EndProcedure

&AtClient
Procedure Sign(Command)
	
	NotifyDescription      = New NotifyDescription("SignCompletion", ThisObject);
	AdditionalParameters = New Structure("ResultProcessing", NotifyDescription);
	FilesOperationsClient.SignFile(Items.List.CurrentRow, UUID, AdditionalParameters);
	
EndProcedure

&AtClient
Procedure Encrypt(Command)
	
	If Not FileCommandsAvailable() Then 
		Return;
	EndIf;
	
	ObjectRef = Items.List.CurrentRow;
	FileData = FilesOperationsInternalServerCall.GetFileDataAndVersionsCount(ObjectRef);
	
	HandlerParameters = New Structure;
	HandlerParameters.Insert("FileData", FileData);
	HandlerParameters.Insert("ObjectRef", ObjectRef);
	Handler = New NotifyDescription("EncryptAfterEncryptAtClient", ThisObject, HandlerParameters);
	
	FilesOperationsInternalClient.Encrypt(Handler, FileData, UUID);
	
EndProcedure

&AtClient
Procedure Decrypt(Command)
	
	If Not FileCommandsAvailable() Then 
		Return;
	EndIf;
	
	ObjectRef = Items.List.CurrentRow;
	FileData = FilesOperationsInternalServerCall.GetFileDataAndVersionsCount(ObjectRef);
	
	HandlerParameters = New Structure;
	HandlerParameters.Insert("FileData", FileData);
	HandlerParameters.Insert("ObjectRef", ObjectRef);
	Handler = New NotifyDescription("DecryptAfterDecryptAtClient", ThisObject, HandlerParameters);
	
	FilesOperationsInternalClient.Decrypt(
		Handler,
		FileData.Ref,
		UUID,
		FileData);
	
EndProcedure

&AtClient
Procedure AddSignatureFromFile(Command)
	
	If Not FileCommandsAvailable() Then 
		Return;
	EndIf;
	
	FilesOperationsInternalClient.AddSignatureFromFile(
		Items.List.CurrentRow,
		UUID,
		New NotifyDescription("SetFileCommandsAvailability", ThisObject));
	
EndProcedure

&AtClient
Procedure SaveWithSignature(Command)
	
	If Not FileCommandsAvailable() Then 
		Return;
	EndIf;
	
	FilesOperationsInternalClient.SaveFileWithSignature(
		Items.List.CurrentRow, UUID);
	
EndProcedure

&AtClient
Procedure Update(Command)
	
	Items.Folders.Refresh();
	Items.List.Refresh();
	
	AttachIdleHandler("SetCommandsAvailabilityOnChangeFolder", 0.1, True);
	
EndProcedure

&AtClient
Procedure Send(Command)
	
	OnSendFilesViaEmail(SendOptions, Items.List.SelectedRows, Items.Folders.CurrentData.Ref , UUID);
	
	FilesOperationsInternalClient.SendFilesViaEmail(
		Items.List.SelectedRows, UUID, SendOptions, True);
	
EndProcedure

&AtClient
Procedure PrintFiles(Command)
	
	If Not FileCommandsAvailable() Then 
		Return;
	EndIf;
	
	If Not CommonClient.IsWindowsClient() Then 
		ShowMessageBox(, NStr("ru = 'Печать файлов возможна только в Windows.'; en = 'Printing files is available only on Windows.'; pl = 'Drukowanie plików jest możliwe tylko w Windows.';de = 'Dateien können nur unter Windows gedruckt werden.';ro = 'Fișierele pot fi imprimate numai în Windows.';tr = 'Dosya yalnızca Windows''ta yazdırılabilir.'; es_ES = 'Es posible imprimir los archivos solo en Windows.'"));
		Return;
	EndIf;
	
	SelectedRows = Items.List.SelectedRows;
	If SelectedRows.Count() > 0 Then
		FilesOperationsClient.PrintFiles(SelectedRows, ThisObject.UUID);
	EndIf;
	
EndProcedure

&AtClient
Procedure Preview(Command)
	
	Preview = Not Preview;
	Items.Preview.Check = Preview;
	SetPreviewVisibility(Preview);
	SavePreviewOption("Files", Preview);
	
	#If WebClient Then
	UpdatePreview();
	#EndIf
	
EndProcedure

&AtClient
Procedure SyncSettings(Command)
	
	SyncSetup = SynchronizationSettingsParameters(Items.Folders.CurrentData.Ref);
	
	If ValueIsFilled(SyncSetup.Account) Then
		ValueType = Type("InformationRegisterRecordKey.FileSynchronizationSettings");
		WriteParameters = New Array(1);
		WriteParameters[0] = SyncSetup;
		
		RecordKey = New(ValueType, WriteParameters);
	
		WriteParameters = New Structure;
		WriteParameters.Insert("Key", RecordKey);
	Else
		SyncSetup.Insert("IsFile", True);
		WriteParameters = SyncSetup;
	EndIf;
	
	OpenForm("InformationRegister.FileSynchronizationSettings.Form.SimpleRecordFormSettings", WriteParameters, ThisObject);
	
EndProcedure

&AtClient
Procedure Compare(Command)
	SelectedRowsCount = Items.List.SelectedRows.Count();
	
	If SelectedRowsCount = 2 OR SelectedRowsCount = 1 Then
		If SelectedRowsCount = 2 Then
			Ref1 = Items.List.SelectedRows[0];
			Ref2 = Items.List.SelectedRows[1];
		ElsIf SelectedRowsCount = 1 Then
			Ref1 = Items.List.CurrentData.Ref;
			Ref2 = Items.List.CurrentData.ParentVersion;
		EndIf;
		
		Extension = Lower(Items.List.CurrentData.Extension);
		
		FilesOperationsInternalClient.CompareFiles(UUID, Ref1, Ref2, Extension);
		
	EndIf;
EndProcedure

&AtClient
Procedure ShowServiceFiles(Command)
	
	Items.ShowServiceFiles.Check = 
		FilesOperationsInternalClient.ShowServiceFilesClick(List);
	
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure ImportFilesAfterExtensionInstalled(Result, ExecutionParameters) Export
	If NOT Result Then
		FilesOperationsInternalClient.ShowFileSystemExtensionRequiredMessageBox(Undefined);
		Return;
	EndIf;
	
	OpenFileDialog = New FileDialog(FileDialogMode.Open);
	OpenFileDialog.FullFileName = "";
	OpenFileDialog.Filter = NStr("ru = 'Все файлы(*.*)|*.*'; en = 'All files (*.*)|*.*'; pl = 'Wszystkie pliki(*.*)|*.*';de = 'Alle Dateien (*.*)|*.*';ro = 'Toate fișierele (*.*)|*.*';tr = 'Tüm dosyalar (*. *) | *. *'; es_ES = 'Todos archivos (*.*)|*.*'");
	OpenFileDialog.Multiselect = True;
	OpenFileDialog.Title = NStr("ru = 'Выберите файлы'; en = 'Select files'; pl = 'Wybrać pliki';de = 'Dateien wählen';ro = 'Selectați fișiere';tr = 'Dosyaları seçin'; es_ES = 'Seleccionar archivos'");
	If Not OpenFileDialog.Choose() Then
		Return;
	EndIf;
	
	FileNamesArray = New Array;
	For Each FileName In OpenFileDialog.SelectedFiles Do
		FileNamesArray.Add(FileName);
	EndDo;
	
	FormParameters = New Structure;
	FormParameters.Insert("FolderForAdding", Items.Folders.CurrentRow);
	FormParameters.Insert("FileNamesArray",   FileNamesArray);
	
	OpenForm("DataProcessor.FilesOperations.Form.FilesImportForm", FormParameters);
EndProcedure

&AtClient
Procedure ImportFolderAfterExtensionInstalled(Result, ExecutionParameters) Export
	
	If NOT Result Then
		FilesOperationsInternalClient.ShowFileSystemExtensionRequiredMessageBox(Undefined);
		Return;
	EndIf;
	
	OpenFileDialog = New FileDialog(FileDialogMode.ChooseDirectory);
	OpenFileDialog.FullFileName = "";
	OpenFileDialog.Filter = NStr("ru = 'Все файлы(*.*)|*.*'; en = 'All files (*.*)|*.*'; pl = 'Wszystkie pliki(*.*)|*.*';de = 'Alle Dateien (*.*)|*.*';ro = 'Toate fișierele (*.*)|*.*';tr = 'Tüm dosyalar (*. *) | *. *'; es_ES = 'Todos archivos (*.*)|*.*'");
	OpenFileDialog.Multiselect = False;
	OpenFileDialog.Title = NStr("ru = 'Выберите каталог'; en = 'Select directory'; pl = 'Wybierz folder';de = 'Wählen Sie das Verzeichnis aus';ro = 'Selectați directorul';tr = 'Dizini seçin'; es_ES = 'Seleccionar el directorio'");
	If Not OpenFileDialog.Choose() Then
		Return;
	EndIf;
	
	FormParameters = New Structure;
	FormParameters.Insert("FolderForAdding", Items.Folders.CurrentRow);
	FormParameters.Insert("DirectoryOnHardDrive",     OpenFileDialog.Directory);
	
	OpenForm("DataProcessor.FilesOperations.Form.FolderImportForm", FormParameters);

EndProcedure

&AtClient
Procedure ExportFolderAfterInstallExtension(Result, FormParameters) Export
	
	If NOT Result Then
		FilesOperationsInternalClient.ShowFileSystemExtensionRequiredMessageBox(Undefined);
		Return;
	EndIf;
	
	OpenForm("DataProcessor.FilesOperations.Form.ExportFolderForm", FormParameters);
	
EndProcedure

&AtClient
Procedure DragToFolder(FolderForAdding, DragValue, Action)
	If FolderForAdding = Undefined Then
		FolderForAdding = Items.Folders.CurrentRow;
		If FolderForAdding = Undefined Then
			Return;
		EndIf;
	EndIf;
	
	ValueType = TypeOf(DragValue);
	If ValueType = Type("File") Then
		If FolderForAdding.IsEmpty() Then
			Return;
		EndIf;
		If DragValue.IsFile() Then
			AddingOptions = New Structure;
			AddingOptions.Insert("ResultHandler", Undefined);
			AddingOptions.Insert("FullFileName", DragValue.FullName);
			AddingOptions.Insert("FileOwner", FolderForAdding);
			AddingOptions.Insert("OwnerForm", ThisObject);
			AddingOptions.Insert("NameOfFileToCreate", Undefined);
			AddingOptions.Insert("DontOpenCardAfterCreateFromFIle", True);
			FilesOperationsInternalClient.AddFormFileSystemWithExtension(AddingOptions);
		Else
			FileNamesArray = New Array;
			FileNamesArray.Add(DragValue.FullName);
			FilesOperationsInternalClient.OpenDragFormFromOutside(FolderForAdding, FileNamesArray);
		EndIf;
	ElsIf TypeOf(DragValue) = Type("Array") Then
		FolderIndex = DragValue.Find(FolderForAdding);
		If FolderIndex <> Undefined Then
			DragValue.Delete(FolderIndex);
		EndIf;
		
		If DragValue.Count() = 0 Then
			Return;
		EndIf;
		
		ValueType = TypeOf(DragValue[0]);
		If ValueType = Type("File") Then
			If FolderForAdding.IsEmpty() Then
				Return;
			EndIf;
			
			FileNamesArray = New Array;
			For Each ReceivedFile In DragValue Do
				FileNamesArray.Add(ReceivedFile.FullName);
			EndDo;
			FilesOperationsInternalClient.OpenDragFormFromOutside(FolderForAdding, FileNamesArray);
			
		ElsIf ValueType = Type("CatalogRef.Files") Then
			If FolderForAdding.IsEmpty() Then
				Return;
			EndIf;
			If Action = DragAction.Copy Then
				
				FilesOperationsInternalServerCall.CopyFiles(
					DragValue,
					FolderForAdding);
				
				Items.Folders.Refresh();
				Items.List.Refresh();
				
				If DragValue.Count() = 1 Then
					NotificationTitle = NStr("ru = 'Файл скопирован.'; en = 'File copied.'; pl = 'Plik został skopiowany.';de = 'Die Datei wird kopiert.';ro = 'Fișierul este copiat.';tr = 'Dosya kopyalandı.'; es_ES = 'Archivo se ha copiado.'");
					NotificationText = StringFunctionsClientServer.SubstituteParametersToString(
						NStr("ru = 'Файл ""%1""
						           |скопирован в папку ""%2""'; 
						           |en = 'File ""%1"" 
						           |is copied to folder ""%2"".'; 
						           |pl = 'Plik ""%1""
						           |został skopiowany do folderu ""%2""';
						           |de = 'Datei ""%1""
						           | in den Ordner ""%2"" kopiert';
						           |ro = 'Fișierul ""%1""
						           |a fost copiat în folderul ""%2""';
						           |tr = '""%1""
						           |dosya ""%2"" klasöre kopyalandı'; 
						           |es_ES = 'El archivo ""%1""
						           |ha sido copiado en la carpeta ""%2""'"),
						DragValue[0],
						String(FolderForAdding));
				Else
					NotificationTitle = NStr("ru = 'Файлы скопированы.'; en = 'Files copied.'; pl = 'Pliki zostały skopiowane.';de = 'Dateien werden kopiert.';ro = 'Fișierele sunt copiate.';tr = 'Dosyalar kopyalandı.'; es_ES = 'Archivos se han copiado.'");
					NotificationText = StringFunctionsClientServer.SubstituteParametersToString(
						NStr("ru = 'Файлы (%1 шт.) скопированы в папку ""%2""'; en = '%1 files are copied to folder ""%2.""'; pl = 'Pliki (%1 szt.) zostały skopiowane do folderu ""%2""';de = 'Dateien (%1 Stk.) wurden in den Ordner %2"" kopiert';ro = 'Fișierele (%1 buc) au fost copiate în dosarul ""%2""';tr = 'Dosyalar (%1 adet) ""%2""klasöre kopyalandı.'; es_ES = 'Archivos (%1 pcs) se han copiado en la carpeta ""%2""'"),
						DragValue.Count(),
						String(FolderForAdding));
				EndIf;
				ShowUserNotification(NotificationTitle, , NotificationText, PictureLib.Information32);
			Else
				
				OwnerIsSet = FilesOperationsInternalServerCall.SetFileOwner(DragValue, FolderForAdding);
				If OwnerIsSet <> True Then
					Return;
				EndIf;
				
				Items.Folders.Refresh();
				Items.List.Refresh();
				
				If DragValue.Count() = 1 Then
					NotificationTitle = NStr("ru = 'Файл перенесен.'; en = 'File moved.'; pl = 'Plik został przeniesiony';de = 'Die Datei wurde verschoben.';ro = 'Fișierul este mutat.';tr = 'Dosya taşındı.'; es_ES = 'Archivo se ha movido.'");
					NotificationText = StringFunctionsClientServer.SubstituteParametersToString(
						NStr("ru = 'Файл ""%1""
						           |перенесен в папку ""%2""'; 
						           |en = 'File ""%1"" 
						           |is moved to folder ""%2.""'; 
						           |pl = 'Plik ""%1""
						           |został przeniesiony do folderu ""%2""';
						           |de = 'Die Datei ""%1""
						           |wurde in den Ordner ""%2"" verschoben.';
						           |ro = 'Fișierul ""%1""
						           |a fost transferat în folderul ""%2""';
						           |tr = '""%1""
						           |dosya ""%2"" klasöre taşındı'; 
						           |es_ES = 'El archivo ""%1""
						           |ha sido movido en la carpeta ""%2""'"),
						String(DragValue[0]),
						String(FolderForAdding));
				Else
					NotificationTitle = NStr("ru = 'Файлы перенесены.'; en = 'Files moved.'; pl = 'Pliki zostały przeniesione';de = 'Dateien werden verschoben.';ro = 'Fișierele sunt mutate.';tr = 'Dosyalar taşındı.'; es_ES = 'Archivos se han movido.'");
					NotificationText = StringFunctionsClientServer.SubstituteParametersToString(
						NStr("ru = 'Файлы (%1 шт.) перенесены в папку ""%2""'; en = '%1 files are moved to folder ""%2.""'; pl = 'Pliki (%1 szt.) zostały przeniesione do folderu ""%2""';de = 'Dateien (%1 Stk.) wurden in den Ordner ""%2"" verschoben';ro = 'Fișiere (%1 buc) au fost mutate în dosarul ""%2""';tr = 'Dosyalar (%1 adet) ""%2""klasöre taşındı.'; es_ES = 'Archivos (%1 pcs) se han movido a la carpeta ""%2""'"),
						String(DragValue.Count()),
						String(FolderForAdding));
				EndIf;
				ShowUserNotification(NotificationTitle, , NotificationText, PictureLib.Information32);
			EndIf;
			
		ElsIf ValueType = Type("CatalogRef.FilesFolders") Then
			LoopFound = False;
			ParentChanged = FilesOperationsInternalServerCall.ChangeFoldersParent(DragValue, FolderForAdding, LoopFound);
			If ParentChanged <> True Then
				If LoopFound = True Then
					If DragValue.Count() = 1 Then
						MessageText = NStr("ru = 'Перемещение невозможно.
							|Папка ""%1"" является дочерней для перемещаемой папки ""%2"".'; 
							|en = 'Cannot move the folder.
							|The ""%1"" folder is subordinate to the ""%2"" folder that you want to move.'; 
							|pl = 'Przemieszczenie nie jest możliwe.
							|Folder ""%1"" jest podrzędny w stosunku do przemieszczanego folderu ""%2"".';
							|de = 'Eine Verschiebung ist unmöglich.
							|Der Ordner ""%1"" ist ein Unterordner für den zu verschiebenden Ordner ""%2"".';
							|ro = 'Transfer imposibil.
							|Folderul ""%1"" este afiliat pentru folderul transferat ""%2"".';
							|tr = 'Taşınamaz.  
							|Klasör ""%1"" taşınan ""%2"" klasörün alt klasörüdür.'; 
							|es_ES = 'Es imposible mover.
							|La carpeta ""%1"" es subordinada para la carpeta movida ""%2"".'");
					Else
						MessageText = NStr("ru = 'Перемещение невозможно.
							|Папка ""%1"" является дочерней для одной из перемещаемых папок.'; 
							|en = 'Cannot move the folder.
							|The ""%1"" folder is subordinate to one of the folders that you want to move.'; 
							|pl = 'Przemieszczenie nie jest możliwe.
							|Folder ""%1"" jest podrzędny w stosunku do jednego z przemieszczanych folderów.';
							|de = 'Eine Bewegung ist unmöglich.
							|Der Ordner ""%1"" ist ein Unterordner für einen der zu verschiebenden Ordner.';
							|ro = 'Transfer imposibil.
							|Folderul ""%1"" este afiliat pentru unul din folderele transferate.';
							|tr = 'Taşınamaz.  
							|Klasör ""%1"" taşınan klasörlerden birinin alt klasörüdür.'; 
							|es_ES = 'Es imposible mover.
							|La carpeta ""%1"" es subordinada para una de las carpetas movidas.'");
					EndIf;
					MessageText = StringFunctionsClientServer.SubstituteParametersToString(MessageText, FolderForAdding, DragValue[0]);
					ShowMessageBox(, MessageText);
				EndIf;
				Return;
			EndIf;
			
			Items.Folders.Refresh();
			Items.List.Refresh();
			
			If DragValue.Count() = 1 Then
				Items.Folders.CurrentRow = DragValue[0];
				NotificationTitle = NStr("ru = 'Папка перенесена.'; en = 'Folder moved.'; pl = 'Folder został przeniesiony';de = 'Der Ordner wurde verschoben.';ro = 'Dosarul este mutat.';tr = 'Klasör taşındı.'; es_ES = 'Carpeta se ha movido.'");
				NotificationText = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("ru = 'Папка ""%1""
					           |перенесена в папку ""%2""'; 
					           |en = 'Folder ""%1""
					           |is moved to folder ""%2.""'; 
					           |pl = 'Folder ""%1""
					           |został przeniesiony do folderu ""%2""';
					           |de = 'Der Ordner ""%1""
					           |wurde in den Ordner ""%2"" verschoben';
					           |ro = 'Folderul ""%1""
					           |a fost transferat în folderul ""%2""';
					           |tr = '""%1""
					           |klasör ""%2"" klasöre taşındı'; 
					           |es_ES = 'La carpeta ""%1""
					           |ha sido movida en la carpeta ""%2""'"),
					String(DragValue[0]),
					String(FolderForAdding));
			Else
				NotificationTitle = NStr("ru = 'Папки перенесены.'; en = 'Folders moved.'; pl = 'Foldery zostały przeniesione';de = 'Ordner werden verschoben.';ro = 'Folderele sunt mutate.';tr = 'Klasörler taşındı.'; es_ES = 'Carpetas se han movido.'");
				NotificationText = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("ru = 'Папки (%1 шт.) перенесены в папку ""%2""'; en = '%1 folders are moved to folder ""%2.""'; pl = 'Foldery (%1 szt.) zostały przeniesione do folderu ""%2""';de = 'Die Ordner (%1Stk.) werden in den Ordner %2"" verschoben';ro = 'Folderele (%1 elem.) au fost transferate în folderul ""%2""';tr = 'Klasörler (%1 adet) %2""klasöre taşındı.'; es_ES = 'Carpetas (%1 pcs.) se han movido a la carpeta ""%2""'"),
					String(DragValue.Count()),
					String(FolderForAdding));
			EndIf;
			ShowUserNotification(NotificationTitle, , NotificationText, PictureLib.Information32);
		EndIf;
	EndIf;
EndProcedure

&AtClient
Procedure EncryptAfterEncryptAtClient(Result, ExecutionParameters) Export
	If Not Result.Success Then
		Return;
	EndIf;
	
	WorkingDirectoryName = FilesOperationsInternalClient.UserWorkingDirectory();
	
	FilesArrayInWorkingDirectoryToDelete = New Array;
	
	EncryptServer(
		Result.DataArrayToStoreInDatabase,
		Result.ThumbprintsArray,
		FilesArrayInWorkingDirectoryToDelete,
		WorkingDirectoryName,
		ExecutionParameters.ObjectRef);
	
	FilesOperationsInternalClient.InformOfEncryption(
		FilesArrayInWorkingDirectoryToDelete,
		ExecutionParameters.FileData.Owner,
		ExecutionParameters.ObjectRef);
	
	SetFileCommandsAvailability();
	
EndProcedure

&AtServer
Procedure EncryptServer(DataArrayToStoreInDatabase, ThumbprintsArray, 
	FilesArrayInWorkingDirectoryToDelete,
	WorkingDirectoryName, ObjectRef)
	
	Encrypt = True;
	FilesOperationsInternal.WriteEncryptionInformation(
		ObjectRef,
		Encrypt,
		DataArrayToStoreInDatabase,
		Undefined,  // UUID
		WorkingDirectoryName,
		FilesArrayInWorkingDirectoryToDelete,
		ThumbprintsArray);
	
EndProcedure

&AtClient
Procedure DecryptAfterDecryptAtClient(Result, ExecutionParameters) Export
	
	If Result = False Or Not Result.Success Then
		Return;
	EndIf;
	
	WorkingDirectoryName = FilesOperationsInternalClient.UserWorkingDirectory();
	
	DecryptServer(
		Result.DataArrayToStoreInDatabase,
		WorkingDirectoryName,
		ExecutionParameters.ObjectRef);
	
	FilesOperationsInternalClient.InformOfDecryption(
		ExecutionParameters.FileData.Owner,
		ExecutionParameters.ObjectRef);
	
	SetFileCommandsAvailability();
	
EndProcedure

&AtServer
Procedure DecryptServer(DataArrayToStoreInDatabase, 
	WorkingDirectoryName, ObjectRef)
	
	Encrypt = False;
	ThumbprintsArray = New Array;
	FilesArrayInWorkingDirectoryToDelete = New Array;
	
	FilesOperationsInternal.WriteEncryptionInformation(
		ObjectRef,
		Encrypt,
		DataArrayToStoreInDatabase,
		Undefined,  // UUID
		WorkingDirectoryName,
		FilesArrayInWorkingDirectoryToDelete,
		ThumbprintsArray);
	
EndProcedure

&AtClient
Procedure SignCompletion(Result, ExecutionParameters) Export
	
	SetFileCommandsAvailability();
	
EndProcedure

&AtClient
Procedure SetCommandsAvailabilityOnChangeFolder()
	
	If Items.Folders.CurrentRow <> CurrentFolder Then
		CurrentFolder = Items.Folders.CurrentRow;
		FillPropertyValues(ThisObject, FolderRightsSettings(Items.Folders.CurrentRow));
		Items.FormCreateFolder.Enabled = FoldersModification;
		Items.FoldersContextMenuCreate.Enabled = FoldersModification;
		Items.FoldersContextMenuCopy.Enabled = FoldersModification;
		Items.FoldersContextMenuMarkForDeletion.Enabled = FoldersModification;
		Items.FoldersContextMenuMoveItem.Enabled = FoldersModification;
	EndIf;
	
	If Items.Folders.CurrentRow = Undefined Or Items.Folders.CurrentRow.IsEmpty() Then
		
		Items.FormCreateSubmenu.Enabled = False;
		
		Items.FormCreateFromFile.Enabled = False;
		Items.FormCreateFromTemplate.Enabled = False;
		Items.FormCreateFromScanner.Enabled = False;
		
		Items.FormCopy.Enabled = False;
		Items.ListContextMenuCopy.Enabled = False;
		
		Items.FormMarkForDeletion.Enabled = False;
		Items.ListContextMenuMarkForDeletion.Enabled = False;
		
		Items.ListContextMenuCreate.Enabled = False;
		
		Items.FormImportFiles.Enabled = False;
		Items.ListContextMenuImportFiles.Enabled = False;
		
		Items.FoldersContextMenuFolderImport.Enabled = False;
	Else
		Items.FormCreateSubmenu.Enabled = AddFiles AND Not FilesBeingEditedInCloudService;
		Items.FormCreateFromFile.Enabled = AddFiles AND Not FilesBeingEditedInCloudService;
		Items.FormCreateFromTemplate.Enabled = AddFiles AND Not FilesBeingEditedInCloudService;
		Items.FormCreateFromScanner.Enabled = AddFiles AND Not FilesBeingEditedInCloudService;
		Items.ListContextMenuCreate.Enabled = AddFiles AND Not FilesBeingEditedInCloudService;
		
		Items.FormCreateFolder.Enabled = Not FilesBeingEditedInCloudService;
		Items.FormImportFolder.Enabled = Not FilesBeingEditedInCloudService;
		Items.FormMoveToFolder.Enabled = Not FilesBeingEditedInCloudService;
		Items.FormRelease.Enabled = Not FilesBeingEditedInCloudService;
		Items.ListContextMenuMoveToFolder.Enabled = Not FilesBeingEditedInCloudService;
		Items.ListContextMenuUnlock.Enabled = Not FilesBeingEditedInCloudService;
		
		Items.FormCopy.Enabled = AddFiles AND Not FilesBeingEditedInCloudService;
	
		Items.ListContextMenuMarkForDeletion.Enabled = AddFiles AND Not FilesBeingEditedInCloudService;
		Items.FormMarkForDeletion.Enabled = AddFiles AND Not FilesBeingEditedInCloudService;
		
		Items.FormCopy.Enabled = AddFiles AND Not FilesBeingEditedInCloudService;
		Items.ListContextMenuCopy.Enabled = AddFiles AND Not FilesBeingEditedInCloudService;
		
		Items.FormMarkForDeletion.Enabled = FilesDeletionMark AND Not FilesBeingEditedInCloudService;
		Items.ListContextMenuMarkForDeletion.Enabled = FilesDeletionMark AND Not FilesBeingEditedInCloudService;
		
		Items.FormImportFiles.Enabled = AddFiles AND Not FilesBeingEditedInCloudService;
		Items.ListContextMenuImportFiles.Enabled = AddFiles  AND Not FilesBeingEditedInCloudService;
		
		Items.FoldersContextMenuFolderImport.Enabled = AddFiles AND Not FilesBeingEditedInCloudService;
	EndIf;
	
	If Items.Folders.CurrentRow <> Undefined Then
		AttachIdleHandler("FolderIdleHandlerOnActivateRow", 0.2, True);
	EndIf; 
	
EndProcedure

&AtClient
Procedure SetFilesSynchronizationNoteVisibility()
	
	FilesBeingEditedInCloudService = False;
	
	If Items.Folders.CurrentRow = Undefined Or Items.Folders.CurrentRow.IsEmpty() Then
		
		Items.CloudServiceNoteGroup.Visible = False;
		
	Else
		
		Items.CloudServiceNoteGroup.Visible = Items.Folders.CurrentData.FolderSynchronizationEnabled;
		FilesBeingEditedInCloudService = Items.Folders.CurrentData.FolderSynchronizationEnabled;
		
		If Items.Folders.CurrentData.FolderSynchronizationEnabled Then
			
			FolderAddressInCloudService = FilesOperationsInternalClientServer.AddressInCloudService(
				Items.Folders.CurrentData.AccountService, Items.Folders.CurrentData.Href);
				
			StringParts = New Array;
			StringParts.Add(NStr("ru = 'Работа с файлами этой папки ведется в облачном сервисе'; en = 'This folder is stored in cloud service'; pl = 'Praca z plikami tego folderu jest prowadzona w serwisie w chmurze';de = 'Dateien in diesem Ordner werden im Cloud-Service bearbeitet';ro = 'Lucrul cu fișierele acestui folder se desfășoară în cloud service';tr = 'Bu klasörün dosya yönetimi bulut hizmetinde gerçekleştirilir.'; es_ES = 'Operaciones con archivos de esta carpeta se realizan en el servicio de nube'"));
			StringParts.Add(" ");
			StringParts.Add(New FormattedString(Items.Folders.CurrentData.AccountDescription, , , , FolderAddressInCloudService));
			StringParts.Add(".  ");
			Items.NoteDecoration.Title = New FormattedString(StringParts);
			
			SynchronizationInfo = SynchronizationInfo(Items.Folders.CurrentData.Ref);
			If ValueIsFilled(SynchronizationInfo) Then
				Items.DecorationPictureSyncSettings.Visible  = NOT SynchronizationInfo.Synchronized;
				Items.DecorationSyncDate.ToolTipRepresentation = ?(SynchronizationInfo.Synchronized, ToolTipRepresentation.None, ToolTipRepresentation.Button);
				Items.DecorationSyncDate.Visible            = True;
				
				StringParts.Clear();
				StringParts.Add(NStr("ru = 'Синхронизировано'; en = 'Synchronized on'; pl = 'Synchronizuje się';de = 'Synchronisiert';ro = 'Are loc sincronizarea';tr = 'Senkronize edilmekte'; es_ES = 'Se está sincronizando'"));
				StringParts.Add(": ");
				StringParts.Add(New FormattedString(Format(SynchronizationInfo.SynchronizationDate, "DLF=DD"),,,, "OpenJournal"));
				Items.DecorationSyncDate.Title = New FormattedString(StringParts);
			Else
				
				Items.DecorationPictureSyncSettings.Visible  = False;
				Items.DecorationSyncDate.ToolTipRepresentation = ToolTipRepresentation.None;
				Items.DecorationSyncDate.Visible            = False;
			EndIf;
			
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure SetFoldersTreeTitle()
	
	Items.Folders.Title = ?(Items.Folders.CurrentData = Undefined, "",
		Items.Folders.CurrentData.Description);
	
EndProcedure

&AtServerNoContext
Function SynchronizationInfo(FileOwner)
	
	Return FilesOperationsInternal.SynchronizationInfo(FileOwner);
	
EndFunction

&AtClient
Procedure FolderIdleHandlerOnActivateRow()
	
	If Items.Folders.CurrentRow <> List.Parameters.Items.Find("Owner").Value Then
		// The right list and command availability by right settings are being updated.
		// The procedure of calling the OnActivateRow handler of the List table is performed by the platform.
		UpdateAndSaveFilesListParameters();
	Else
		// The procedure of calling the OnActivateRow handler of the List table is performed by the application.
		IdleHandlerSetFileCommandsAccessibility();
	EndIf;
	
EndProcedure

&AtServerNoContext
Function FolderRightsSettings(Folder)
	
	RightsSettings = New Structure;
	
	If NOT Common.SubsystemExists("StandardSubsystems.AccessManagement") Then
		Value = ValueIsFilled(Folder);
		RightsSettings.Insert("FoldersModification", True);
		RightsSettings.Insert("FilesModification", Value);
		RightsSettings.Insert("AddFiles", Value);
		RightsSettings.Insert("FilesDeletionMark", Value);
		Return RightsSettings;
	EndIf;
	
	ModuleAccessManagement = Common.CommonModule("AccessManagement");
	
	RightsSettings.Insert("FoldersModification",
		ModuleAccessManagement.HasRight("FoldersModification", Folder));
	
	RightsSettings.Insert("FilesModification",
		ModuleAccessManagement.HasRight("FilesModification", Folder));
	
	RightsSettings.Insert("AddFiles",
		ModuleAccessManagement.HasRight("AddFiles", Folder));
	
	RightsSettings.Insert("FilesDeletionMark",
		ModuleAccessManagement.HasRight("FilesDeletionMark", Folder));
	
	Return RightsSettings;
	
EndFunction

&AtServerNoContext
Function FileData(Val AttachedFile, Val FormID = Undefined, Val GetBinaryDataRef = True)
	
	Return FilesOperations.FileData(AttachedFile, FormID, GetBinaryDataRef);
	
EndFunction

&AtClient
Procedure IdleHandlerSetFileCommandsAccessibility()
	
	SetFileCommandsAvailability();
	
EndProcedure

&AtClient
Procedure SetFileCommandsAvailability(Result = Undefined, ExecutionParameters = Undefined) Export
	
	CurrentData = Items.List.CurrentData;
	If CurrentData <> Undefined
		AND TypeOf(Items.List.CurrentRow) <> Type("DynamicalListGroupRow") Then
		SetCommandsAvailability(CurrentData);
	Else
		MakeCommandsUnavailable();
	EndIf;
	AttachIdleHandler("UpdatePreview", 0.1, True);
	
EndProcedure

&AtClient
Procedure MakeCommandsUnavailable()
	
	Items.FormCommit.Enabled = False;
	Items.ListContextMenuFinishEditing.Enabled = False;
	
	Items.FormSaveChanges.Enabled = False;
	Items.ListContextMenuSaveChanges.Enabled = False;
	
	Items.FormRelease.Enabled = False;
	Items.ListContextMenuUnlock.Enabled = False;
	
	Items.FormLock.Enabled = False;
	Items.ListContextMenuLock.Enabled = False;
	
	Items.FormEdit.Enabled = False;
	Items.ListContextMenuEdit.Enabled = False;
	
	Items.FormMoveToFolder.Enabled = False;
	Items.ListContextMenuMoveToFolder.Enabled = False;
	
	Items.FormSign.Enabled = False;
	Items.ListContextMenuSign.Enabled = False;
	
	Items.FormSaveWithSignature.Enabled = False;
	Items.ListContextMenuSaveWithSignature.Enabled = False;
	
	Items.FormEncrypt.Enabled = False;
	Items.ListContextMenuEncrypt.Enabled = False;
	
	Items.FormDecrypt.Enabled = False;
	Items.ListContextMenuDecrypt.Enabled = False;
	
	Items.FormAddSignatureFromFile.Enabled = False;
	Items.ListContextMenuAddSignatureFromFile.Enabled = False;
	
	Items.FormUpdateFromFileOnHardDrive.Enabled = False;
	Items.ListContextMenuUpdateFromFileOnDisk.Enabled = False;
	
	Items.FormSaveAs.Enabled = False;
	Items.ListContextMenuSaveAs.Enabled = False;
	
	Items.FormOpenFileDirectory.Enabled = False;
	Items.ListContextMenuOpenFileDirectory.Enabled = False;
	
	Items.FormOpen.Enabled = False;
	Items.ListContextMenuOpen.Enabled = False;
	
	Items.Print.Enabled = False;
	Items.ListContextMenuPrint.Enabled = False;
	
	Items.Send.Enabled = False;
	
EndProcedure

&AtClient
Procedure SetCommandsAvailability(CommandsData)
	
	Internal   = CommandsData.Internal;
	Encrypted  = CommandsData.Encrypted;
	SignedWithDS  = CommandsData.SignedWithDS;
	EditedBy = CommandsData.BeingEditedBy;
	EditedByCurrentUser = CommandsData.CurrentUserEditsFile;
	
	EditedByAnother = ValueIsFilled(EditedBy) AND NOT EditedByCurrentUser;
	
	Items.FormCommit.Enabled                 = FilesModification AND EditedByCurrentUser;
	Items.ListContextMenuFinishEditing.Enabled = FilesModification AND EditedByCurrentUser;
	
	Items.FormSaveChanges.Enabled                 = FilesModification AND EditedByCurrentUser;
	Items.ListContextMenuSaveChanges.Enabled = FilesModification AND EditedByCurrentUser;
	
	Items.FormRelease.Enabled                 = FilesModification AND ValueIsFilled(EditedBy) AND Not FilesBeingEditedInCloudService;;
	Items.ListContextMenuUnlock.Enabled = FilesModification AND ValueIsFilled(EditedBy) AND Not FilesBeingEditedInCloudService;;
	
	Items.FormLock.Enabled                 = FilesModification AND Not ValueIsFilled(EditedBy) AND NOT SignedWithDS AND NOT Internal;
	Items.ListContextMenuLock.Enabled = FilesModification AND Not ValueIsFilled(EditedBy) AND NOT SignedWithDS AND NOT Internal;
	
	Items.FormEdit.Enabled                 = FilesModification AND NOT SignedWithDS AND NOT EditedByAnother AND NOT Internal;
	Items.ListContextMenuEdit.Enabled = FilesModification AND NOT SignedWithDS AND NOT EditedByAnother AND NOT Internal;
	
	Items.FormMoveToFolder.Enabled                 = FilesModification AND NOT SignedWithDS AND Not FilesBeingEditedInCloudService;
	Items.ListContextMenuMoveToFolder.Enabled = FilesModification AND NOT SignedWithDS AND Not FilesBeingEditedInCloudService;
	
	Items.FormSign.Enabled                 = FilesModification AND Not ValueIsFilled(EditedBy);
	Items.ListContextMenuSign.Enabled = FilesModification AND Not ValueIsFilled(EditedBy);
	
	Items.FormSaveWithSignature.Enabled                 = SignedWithDS;
	Items.ListContextMenuSaveWithSignature.Enabled = SignedWithDS;
	
	Items.FormEncrypt.Enabled                 = FilesModification AND Not ValueIsFilled(EditedBy) AND NOT Encrypted AND NOT Internal;
	Items.ListContextMenuEncrypt.Enabled = FilesModification AND Not ValueIsFilled(EditedBy) AND NOT Encrypted AND NOT Internal;
	
	Items.FormDecrypt.Enabled                 = FilesModification AND Encrypted;
	Items.ListContextMenuDecrypt.Enabled = FilesModification AND Encrypted;
	
	Items.FormAddSignatureFromFile.Enabled                 = FilesModification AND Not ValueIsFilled(EditedBy);
	Items.ListContextMenuAddSignatureFromFile.Enabled = FilesModification AND Not ValueIsFilled(EditedBy);
	
	Items.FormUpdateFromFileOnHardDrive.Enabled                 = FilesModification AND Not SignedWithDS AND Not FilesBeingEditedInCloudService;
	Items.ListContextMenuUpdateFromFileOnDisk.Enabled = FilesModification AND Not SignedWithDS AND Not FilesBeingEditedInCloudService;
	
	Items.FormSaveAs.Enabled                 = True;
	Items.ListContextMenuSaveAs.Enabled = True;
	
	Items.FormOpenFileDirectory.Enabled                 = True;
	Items.ListContextMenuOpenFileDirectory.Enabled = True;
	
	Items.FormOpen.Enabled                 = True;
	Items.ListContextMenuOpen.Enabled = True;
	
	Items.Print.Enabled                      = True;
	Items.ListContextMenuPrint.Enabled = True;
	
	Items.Send.Enabled                      = True;
	Items.ListContextMenuSend.Enabled = True;
	
EndProcedure

&AtServer
Procedure SetHierarchy(Mark)
	
	If Mark = Undefined Then 
		Return;
	EndIf;
	
	Items.FormUseHierarchy.Check = Mark;
	If Mark = True Then 
		Items.Folders.Visible = True;
	Else
		Items.Folders.Visible = False;
	EndIf;
	List.Parameters.SetParameterValue("UseHierarchy", Mark);
	
EndProcedure

&AtClient
Procedure ListSelectionAfterEditModeChoice(Result, ExecutionParameters) Export
	ResultOpen = "Open";
	ResultEdit = "Edit";
	
	If Result = ResultEdit Then
		Handler = New NotifyDescription("SelectionListAfterEditFile", ThisObject, ExecutionParameters);
		FilesOperationsInternalClient.EditFile(Handler, ExecutionParameters.FileData);
	ElsIf Result = ResultOpen Then
		FilesOperationsClient.OpenFile(ExecutionParameters.FileData, False);
	EndIf;
EndProcedure

&AtClient
Procedure SelectionListAfterEditFile(Result, ExecutionParameters) Export
	
	NotifyChanged(ExecutionParameters.FileData.Ref);
	
	SetFileCommandsAvailability();
	
EndProcedure

&AtClient
Procedure OnChangeSigningOrEncryptionUsage()
	
	OnChangeUseSignOrEncryptionAtServer();
	
EndProcedure

&AtServer
Procedure OnChangeUseSignOrEncryptionAtServer()
	
	FilesOperationsInternal.CryptographyOnCreateFormAtServer(ThisObject);
	
EndProcedure

&AtServerNoContext
Procedure SavePreviewOption(FileCatalogType, Preview)
	Common.CommonSettingsStorageSave(FileCatalogType, "Preview", Preview);
EndProcedure

&AtServerNoContext
Procedure OnSendFilesViaEmail(SendOptions, Val FilesToSend, FilesOwner, UUID)
	FilesOperationsOverridable.OnSendFilesViaEmail(SendOptions, FilesToSend, FilesOwner, UUID);
EndProcedure

&AtClient
Procedure SetPreviewVisibility(UsePreview)
	
	Items.FileDataURL.Visible = UsePreview;
	Items.Preview.Check = UsePreview;
	
EndProcedure

&AtClient
Procedure UpdatePreview()
	
	If Not Preview Then
		Return;
	EndIf;
	
	CurrentData = Items.List.CurrentData;
	If CurrentData <> Undefined AND PreviewEnabledExtensions.FindByValue(CurrentData.Extension) <> Undefined Then
		
		Try
			FileData = FilesOperationsInternalServerCall.FileDataToOpen(CurrentData.Ref, Undefined, UUID,, FileDataURL);
			FileDataURL = FileData.BinaryFileDataRef;
		Except
			// If the file does not exist, an exception will be called.
			FileDataURL         = Undefined;
			NonSelectedPictureText = NStr("ru = 'Предварительный просмотр недоступен по причине:'; en = 'Preview is not available. Reason:'; pl = 'Podgląd jest niedostępny z powodu:';de = 'Die Vorschau ist aus diesem Grund nicht verfügbar:';ro = 'Previzualizare inaccesibilă din motivul:';tr = 'Ön izleme aşağıdaki nedenle imkansız:'; es_ES = 'Vista previa no disponible a causa de:'") + Chars.LF + BriefErrorDescription(ErrorInfo());
		EndTry;
		
	Else
		
		FileDataURL         = Undefined;
		NonSelectedPictureText = NStr("ru = 'Нет данных для предварительного просмотра'; en = 'No data to preview'; pl = 'Brak danych do podglądu';de = 'Keine Vorschau-Daten';ro = 'Lipsesc datele pentru previzualizare';tr = 'Ön gösterilecek veri yok'; es_ES = 'No hay datos para la vista previa'");
		
	EndIf;
	
	If NOT ValueIsFilled(FileDataURL) Then
		Items.FileDataURL.NonselectedPictureText = NonSelectedPictureText;
	EndIf;
	
EndProcedure

&AtServer
Function SynchronizationSettingsParameters(FileOwner)
	
	FileOwnerType = Common.MetadataObjectID(Type("CatalogRef.Files"));
	
	Filter = New Structure(
	"FileOwner, FileOwnerType, Account",
		FileOwner,
		FileOwnerType,
		Catalogs.FileSynchronizationAccounts.EmptyRef());
	
	Query = New Query;
	Query.Text = 
		"SELECT
		|	FileSynchronizationSettings.FileOwner,
		|	FileSynchronizationSettings.FileOwnerType,
		|	FileSynchronizationSettings.Account
		|FROM
		|	InformationRegister.FileSynchronizationSettings AS FileSynchronizationSettings
		|WHERE
		|	FileSynchronizationSettings.FileOwner = &FileOwner
		|	AND FileSynchronizationSettings.FileOwnerType = &FileOwnerType";
	
	Query.SetParameter("FileOwner", FileOwner);
	Query.SetParameter("FileOwnerType", FileOwnerType);
	
	QueryResult = Query.Execute();
	
	DetailedRecordsSelection = QueryResult.Select();
	
	If DetailedRecordsSelection.Count() = 1 Then
		While DetailedRecordsSelection.Next() Do
			Filter.Account = DetailedRecordsSelection.Account;
		EndDo;
	EndIf;
	
	Return Filter;
	
EndFunction

&AtServer
Procedure UpdateAndSaveFilesListParameters()
	
	Common.FormDataSettingsStorageSave(
		"Files", 
		"CurrentFolder", 
		Items.Folders.CurrentRow);
	
	List.Parameters.SetParameterValue("Owner", Items.Folders.CurrentRow);
	
EndProcedure

&AtServerNoContext
Function EventLogFilterData(AccountService)
	Return FilesOperationsInternal.EventLogFilterData(AccountService);
EndFunction

#EndRegion
