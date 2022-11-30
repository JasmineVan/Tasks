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
	
	ErrorTitle = NStr("ru = 'Ошибка при настройке динамического списка присоединенных файлов.'; en = 'An error occurred when configuring the dynamic list of attached files.'; pl = 'Wystąpił błąd podczas konfigurowania dynamicznej listy załączonych plików.';de = 'Bei der Konfiguration der dynamischen Liste der angehängten Dateien ist ein Fehler aufgetreten.';ro = 'Eroare la configurarea listei dinamice a fișierelor atașate.';tr = 'Ekli dosyaların dinamik listesini yapılandırırken bir hata oluştu.'; es_ES = 'Ha ocurrido un error al configurar la lista dinámica de los archivos adjuntados.'");
	ErrorEnd = NStr("ru = 'В этом случае настройка динамического списка невозможна.'; en = 'Cannot configure the dynamic list.'; pl = 'W tym przypadku konfiguracja listy dynamicznej nie jest obsługiwana.';de = 'In diesem Fall wird die dynamische Listenkonfiguration nicht unterstützt.';ro = 'În acest caz, configurarea listei dinamice este imposibilă.';tr = 'Bu durumda, dinamik liste yapılandırılamaz.'; es_ES = 'En el caso la configuración de la lista dinámica no se admite.'");
	
	FileVersionsStorageCatalogName = FilesOperationsInternal.FilesVersionsStorageCatalogName(
		Parameters.File.FileOwner, "", ErrorTitle, ErrorEnd);
		
	If Not IsBlankString(FileVersionsStorageCatalogName) Then
		SetUpDynamicList(FileVersionsStorageCatalogName);
	EndIf;
	
	CommandCompareVisibility = 
		Not Common.IsLinuxClient() AND Not Common.IsWebClient();
	Items.FormCompare.Visible = CommandCompareVisibility;
	Items.ContextMenuListCompare.Visible = CommandCompareVisibility;
	
	FileCardUUID = Parameters.FileCardUUID;
	
	List.Parameters.SetParameterValue("Owner", Parameters.File);
	VersionOwner = Parameters.File;
	
	If Common.IsMobileClient() Then
		
		Items.FormOpenVersion.Picture = PictureLib.Magnifier;
		Items.FormOpenVersion.Representation = ButtonRepresentation.Picture;
		Items.ListComment.Visible = False;
		
	EndIf;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure MakeActiveExecute()
	
	CurrentData = Items.List.CurrentData;
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	NewActiveVersion = CurrentData.Ref;
	
	FileData = FilesOperationsInternalServerCall.FileData(CurrentData.Owner, CurrentData.Ref);
	
	If ValueIsFilled(FileData.BeingEditedBy) Then
		ShowMessageBox(, NStr("ru = 'Смена активной версии разрешена только для незанятых файлов.'; en = 'Cannot change the active version because the file is locked.'; pl = 'Zmiana aktywnej wersji jest dozwolona tylko dla nieużywanych plików.';de = 'Das Ändern der aktiven Version ist nur für unbenutzte Dateien erlaubt.';ro = 'Este permisă modificarea versiunii active numai pentru fișierele care nu sunt blocate.';tr = 'Aktif sürüm sadece kilitlenmeyen dosyalar için değiştirilebilir.'; es_ES = 'Está permitido cambiar la versión activa solo para los archivos que no están ocupados.'"));
	ElsIf FileData.SignedWithDS Then
		ShowMessageBox(, NStr("ru = 'Смена активной версии разрешена только для неподписанных файлов.'; en = 'Cannot change the active version because the file is signed.'; pl = 'Zmiana aktywnej wersji jest dozwolone tylko dla niepodpisanych plików.';de = 'Das Ändern der aktiven Version ist nur für unsignierte Dateien erlaubt.';ro = 'Este permisă modificarea versiunii active numai pentru fișierele care nu sunt semnate.';tr = 'Aktif sürüm sadece imzalanmayan dosyalar için değiştirilebilir.'; es_ES = 'Está permitido cambiar la versión activa solo para los archivos que no están firmados.'"));
	Else
		ChangeActiveFileVersion(NewActiveVersion);
		Notify("Write_File", New Structure("Event", "ActiveVersionChanged"), Parameters.File);
	EndIf;
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If EventName = "Write_File"
	   AND Parameter.Property("Event")
	   AND (    Parameter.Event = "EditFinished"
	      Or Parameter.Event = "VersionSaved") Then
		
		If Parameters.File = Source Then
			
			Items.List.Refresh();
			
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure ListChoice(Item, RowSelected, Field, StandardProcessing)
	
	StandardProcessing = False;
	CurrentData = Items.List.CurrentData;
	If CurrentData = Undefined Then 
		Return;
	EndIf;
	
	FileData = FilesOperationsInternalServerCall.FileDataToOpen(CurrentData.Owner, CurrentData.Ref, UUID);
	FilesOperationsInternalClient.OpenFileVersion(Undefined, FileData, UUID);
	
EndProcedure

&AtClient
Procedure OpenCard(Command)
	
	CurrentData = Items.List.CurrentData;
	If CurrentData <> Undefined Then 
		
		Version = CurrentData.Ref;
		
		FormOpenParameters = New Structure("Key", Version);
		OpenForm("DataProcessor.FilesOperations.Form.AttachedFileVersion", FormOpenParameters);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure ListBeforeDelete(Item, Cancel)
	
	Cancel = True;
	
EndProcedure

&AtClient
Procedure ListBeforeChangeRow(Item, Cancel)
	
	Cancel = True;
	
	CurrentData = Items.List.CurrentData;
	If CurrentData <> Undefined Then 
		
		Version = CurrentData.Ref;
		
		FormOpenParameters = New Structure("Key", Version);
		OpenForm("DataProcessor.FilesOperations.Form.AttachedFileVersion", FormOpenParameters);
		
	EndIf;
	
EndProcedure

// Compare two selected versions.
&AtClient
Procedure Compare(Command)
	
	SelectedRowsCount = Items.List.SelectedRows.Count();
	If SelectedRowsCount <> 2 AND SelectedRowsCount <> 1 Then
		ShowMessageBox(, NStr("ru='Для просмотра отличий необходимо выбрать две версии файла.'; en = 'To view the differences, select two file versions.'; pl = 'Aby wyświetlić różnice należy wybrać dwie wersje pliku.';de = 'Um die Unterschiede zu sehen, sollten Sie zwei Versionen der Datei auswählen.';ro = 'Pentru vizualizarea diferențelor trebuie să selectați două versiuni ale fișierului.';tr = 'Farklılıkları görüntülemek için dosyanın iki sürümü seçilmelidir.'; es_ES = 'Para ver las diferencias es necesario seleccionar dos versiones del archivo.'"));
		Return;
	EndIf;
		
	If SelectedRowsCount = 2 Then
		FirstFile = Items.List.SelectedRows[0];
		SecondFile = Items.List.SelectedRows[1];
	ElsIf SelectedRowsCount = 1 Then
		FirstFile = Items.List.CurrentData.Ref;
		SecondFile = Items.List.CurrentData.ParentVersion;
	EndIf;
	
	Extension = Lower(Items.List.CurrentData.Extension);
	FilesOperationsInternalClient.CompareFiles(UUID, FirstFile, SecondFile, Extension, VersionOwner);
	
EndProcedure

&AtClient
Procedure OpenVersion(Command)
	
	CurrentData = Items.List.CurrentData;
	If CurrentData = Undefined Then 
		Return;
	EndIf;
	
	FileData = FilesOperationsInternalServerCall.FileDataToOpen(CurrentData.Owner, CurrentData.Ref ,UUID);
	FilesOperationsInternalClient.OpenFileVersion(Undefined, FileData, UUID);
	
EndProcedure

&AtClient
Procedure SaveAs(Command)
	
	CurrentData = Items.List.CurrentData;
	If CurrentData = Undefined Then 
		Return;
	EndIf;
	
	FileData = FilesOperationsInternalServerCall.FileDataToSave(CurrentData.Owner, CurrentData.Ref , UUID);
	FilesOperationsInternalClient.SaveAs(Undefined, FileData, UUID);
	
EndProcedure

&AtClient
Procedure ListBeforeAddRow(Item, Cancel, Clone, Parent, Folder)
	Cancel = True;
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure ChangeActiveFileVersion(Version)
	
	BeginTransaction();
	Try
		Lock = New DataLock;
		
		DataLockItem = Lock.Add(Metadata.FindByType(TypeOf(Version.Owner)).FullName());
		DataLockItem.SetValue("Ref", Version.Owner);
		
		DataLockItem = Lock.Add(Metadata.FindByType(TypeOf(Version)).FullName());
		DataLockItem.SetValue("Ref", Version);
		
		Lock.Lock();
		
		LockDataForEdit(Version.Owner, , FileCardUUID);
		LockDataForEdit(Version, , FileCardUUID);
		
		FileObject = Version.Owner.GetObject();
		If FileObject.SignedWithDS Then
			Raise NStr("ru = 'У подписанного файла нельзя изменять активную версию.'; en = 'Cannot change the active version because the file is signed.'; pl = 'U podpisanego pliku nie można zmieniać aktywną wersję.';de = 'Eine signierte Datei kann nicht mit der aktiven Version geändert werden.';ro = 'Nu puteți modifica versiunea activă la fișierul semnat.';tr = 'İmzalanan dosyanın aktif versiyonu değiştirilemez.'; es_ES = 'No se puede cambiar la versión activa del archivo firmado.'");
		EndIf;
		FileObject.CurrentVersion = Version;
		FileObject.TextStorage = Version.TextStorage;
		FileObject.Write();
		
		VersionObject = Version.GetObject();
		VersionObject.Write();
		
		UnlockDataForEdit(FileObject.Ref, FileCardUUID);
		UnlockDataForEdit(Version, FileCardUUID);
		
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;
	
	Items.List.Refresh();
	
EndProcedure

&AtServer
Procedure SetUpDynamicList(FileVersionsStorageCatalogName)
	
	ListProperties = Common.DynamicListPropertiesStructure();
	
	QueryText = 
		"SELECT ALLOWED
		|	FilesVersions.Code AS Code,
		|	FilesVersions.Size AS Size,
		|	FilesVersions.Comment AS Comment,
		|	FilesVersions.Author AS Author,
		|	FilesVersions.CreationDate AS CreationDate,
		|	FilesVersions.FullDescr AS FullDescr,
		|	FilesVersions.ParentVersion AS ParentVersion,
		|	CASE
		|		WHEN FilesVersions.DeletionMark
		|			THEN FilesVersions.PictureIndex + 1
		|		ELSE FilesVersions.PictureIndex
		|	END AS PictureIndex,
		|	FilesVersions.DeletionMark AS DeletionMark,
		|	FilesVersions.Owner AS Owner,
		|	FilesVersions.Ref AS Ref,
		|	CASE
		|		WHEN FilesVersions.Owner.CurrentVersion = FilesVersions.Ref
		|			THEN TRUE
		|		ELSE FALSE
		|	END AS IsCurrent,
		|	FilesVersions.Extension AS Extension,
		|	FilesVersions.VersionNumber AS VersionNumber
		|FROM
		|	Catalog." + FileVersionsStorageCatalogName + " AS FilesVersions
		|WHERE
		|	FilesVersions.Owner = &Owner";
	
	FullCatalogName = "Catalog." + FileVersionsStorageCatalogName;
	QueryText = StrReplace(QueryText, "&CatalogName", FullCatalogName);
	
	ListProperties.MainTable  = FullCatalogName;
	ListProperties.DynamicDataRead = True;
	ListProperties.QueryText = QueryText;
	Common.SetDynamicListProperties(Items.List, ListProperties);
	
EndProcedure

#EndRegion
