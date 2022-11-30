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
	
	If Common.IsWebClient() Then
		Items.NowInLocalFileCache.Visible = False;
		Items.CleanUpWorkingDirectory.Visible = False;
	EndIf;
	
	FillParametersAtServer();
	
	If Common.IsMobileClient() Then
		CommandBarLocation = FormCommandBarLabelLocation.Auto;
		Items.CleanUpWorkingDirectory.Title = NStr("ru = 'Очистить'; en = 'Clear working directory'; pl = 'Wyczyścić';de = 'Gefiltertes Inventar löschen';ro = 'Golire';tr = 'Temizle'; es_ES = 'Borrar'");
		Items.UserWorkingDirectory.TitleLocation = FormItemTitleLocation.Top;
	EndIf;
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	If NOT FilesOperationsInternalClient.FileSystemExtensionAttached() Then
		StandardSubsystemsClient.SetFormStorageOption(ThisObject, True);
		AttachIdleHandler("ShowFileSystemExtensionRequiredMessageBox", 0.1, True);
		Cancel = True;
		Return;
	EndIf;
	
	UserWorkingDirectory = FilesOperationsInternalClient.UserWorkingDirectory();
	
	UpdateWorkDirectoryCurrentStatus();
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure UserWorkDirectoryChoiceStart(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	
	If NOT FilesOperationsInternalClient.FileSystemExtensionAttached() Then
		Return;
	EndIf;
	
	// Selecting a new path to a working directory.
	DirectoryName = UserWorkingDirectory;
	Title = NStr("ru = 'Выберите рабочий каталог'; en = 'Select working directory'; pl = 'Wybierz katalog roboczy';de = 'Wählen Sie ein Arbeitsverzeichnis aus';ro = 'Selectați directorul';tr = 'Çalışma dizini seç'; es_ES = 'Seleccione un catálogo de trabajo'");
	If Not FilesOperationsInternalClient.ChoosePathToWorkingDirectory(DirectoryName, Title, False) Then
		Return;
	EndIf;
	
	SetNewWorkDirectory(DirectoryName);
	
EndProcedure

&AtClient
Procedure LocalFilesCacheOnChangeMaxSize(Item)
	
	SaveParameters();
	
EndProcedure

&AtClient
Procedure ConfirmOnDeleteFromLocalFIlesCacheOnChange(Item)
	
	SaveParameters();
	
EndProcedure

&AtClient
Procedure DeleteFileFromLocalFilesCacheOnFinishEditOnChange(Item)
	
	If DeleteFileFromLocalFileCacheOnCompleteEdit Then
		Items.ConfirmOnDeleteFilesFromLocalCache.Enabled = True;
	Else
		Items.ConfirmOnDeleteFilesFromLocalCache.Enabled = False;
		ConfirmOnDeleteFilesFromLocalCache                      = False;
	EndIf;
	
	SaveParameters();
	
EndProcedure

#EndRegion

#Region FormCommandHandlers

&AtClient
Procedure ShowFileSystemExtensionRequiredMessageBox()
	
	StandardSubsystemsClient.SetFormStorageOption(ThisObject, False);
	FilesOperationsInternalClient.ShowFileSystemExtensionRequiredMessageBox(Undefined);
	
EndProcedure

&AtClient
Procedure FileListExecute()
	
	OpenForm("DataProcessor.FilesOperations.Form.FilesInMainWorkingDirectory", , ThisObject, , , ,
		New NotifyDescription("FilesListClose", ThisObject));
	
EndProcedure

&AtClient
Procedure CleanUpLocalFileCache(Command)
	
	QuestionText =
		NStr("ru = 'Из рабочего каталога будут удалены все файлы,
		           |кроме занятых для редактирования.
		           |
		           |Продолжить?'; 
		           |en = 'All files except for ones locked for editing
		           |will be deleted from the working directory.
		           |
		           |Do you want to continue?'; 
		           |pl = 'Z katalogu roboczego zostaną usunięte wszystkie pliki, 
		           |oprócz zajętych do edycji.
		           |
		           |Kontynuować?';
		           |de = 'Alle Dateien werden aus dem Arbeitsverzeichnis gelöscht,
		           |mit Ausnahme der Dateien, die zur Bearbeitung belegt sind.
		           |
		           |Fortfahren?';
		           |ro = 'Din director vor fi șterse toate fișierele,
		           |cu excepția celor ocupate pentru editare.
		           |
		           |Continuați?';
		           |tr = 'Çalışma dizininden, 
		           |düzenleme için kullanılan dosyalar hariç tüm dosyaları silinecektir. 
		           |
		           |Devam etmek istiyor musunuz?'; 
		           |es_ES = 'Del catálogo de trabajo serán eliminados todos los archivos
		           |excepto los que se usan para editar.
		           |
		           |¿Continuar?'");
	Handler = New NotifyDescription("ClearLocalFileCacheCompletionAfterAnswerQuestionContinue", ThisObject);
	ShowQueryBox(Handler, QuestionText, QuestionDialogMode.YesNo);
	
EndProcedure

&AtClient
Procedure DefaultPathToWorkingDirectory(Command)
	
	SetNewWorkDirectory(FilesOperationsInternalClient.SelectPathToUserDataDirectory());
	
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure SaveParameters()
	
	StructuresArray = New Array;
	
	Item = New Structure;
	Item.Insert("Object",    "LocalFileCache");
	Item.Insert("Settings", "PathToLocalFileCache");
	Item.Insert("Value",  UserWorkingDirectory);
	StructuresArray.Add(Item);
	
	Item = New Structure;
	Item.Insert("Object", "LocalFileCache");
	Item.Insert("Settings", "LocalFileCacheMaxSize");
	Item.Insert("Value", LocalFileCacheMaxSize * 1048576);
	StructuresArray.Add(Item);
	
	Item = New Structure;
	Item.Insert("Object", "LocalFileCache");
	Item.Insert("Settings", "DeleteFileFromLocalFileCacheOnCompleteEdit");
	Item.Insert("Value", DeleteFileFromLocalFileCacheOnCompleteEdit);
	StructuresArray.Add(Item);
	
	Item = New Structure;
	Item.Insert("Object", "LocalFileCache");
	Item.Insert("Settings", "ConfirmOnDeleteFilesFromLocalCache");
	Item.Insert("Value", ConfirmOnDeleteFilesFromLocalCache);
	StructuresArray.Add(Item);
	
	CommonServerCall.CommonSettingsStorageSaveArray(StructuresArray, True);
	
EndProcedure

&AtClient
Procedure ClearLocalFileCacheCompletionAfterAnswerQuestionContinue(Response, ExecutionParameters) Export
	
	If Response = DialogReturnCode.No Then
		Return;
	EndIf;
	
	Handler = New NotifyDescription("ClearLocalFileCacheCompletion", ThisObject);
	// ClearAll = True.
	FilesOperationsInternalClient.CleanUpWorkingDirectory(Handler, WorkingDirectoryFileSize, 0, True);
	
EndProcedure

&AtClient
Procedure ClearLocalFileCacheCompletion(Result, ExecutionParameters) Export
	
	UpdateWorkDirectoryCurrentStatus();
	
	ShowUserNotification(NStr("ru = 'Рабочий каталог'; en = 'Working directory'; pl = 'Katalog roboczy';de = 'Arbeitsverzeichnis';ro = 'Director de lucru';tr = 'Çalışma dizini'; es_ES = 'Directorio en marcha'"),, NStr("ru = 'Очистка рабочего каталога успешно завершена.'; en = 'The working directory is cleared.'; pl = 'Oczyszczenie katalogu roboczego zostało zakończone pomyślnie.';de = 'Die Reinigung des Arbeitsverzeichnisses ist erfolgreich abgeschlossen.';ro = 'Golirea directorului este finalizată cu succes.';tr = 'Çalışma dizinini temizleme başarıyla tamamlandı.'; es_ES = 'El catálogo de trabajo se ha terminado con éxito.'"));
	
EndProcedure

&AtClient
Procedure FilesListClose(Result, AdditionalParameters) Export
	
	UpdateWorkDirectoryCurrentStatus();
	
EndProcedure

&AtServer
Procedure FillParametersAtServer()
	
	DeleteFileFromLocalFileCacheOnCompleteEdit = Common.CommonSettingsStorageLoad(
		"LocalFileCache", "DeleteFileFromLocalFileCacheOnCompleteEdit");
	
	If DeleteFileFromLocalFileCacheOnCompleteEdit = Undefined Then
		DeleteFileFromLocalFileCacheOnCompleteEdit = False;
	EndIf;
	
	ConfirmOnDeleteFilesFromLocalCache = Common.CommonSettingsStorageLoad(
		"LocalFileCache", "ConfirmOnDeleteFilesFromLocalCache");
	
	If ConfirmOnDeleteFilesFromLocalCache = Undefined Then
		ConfirmOnDeleteFilesFromLocalCache = False;
	EndIf;
	
	MaxSize = Common.CommonSettingsStorageLoad(
		"LocalFileCache", "LocalFileCacheMaxSize");
	
	If MaxSize = Undefined Then
		MaxSize = 100*1024*1024; // 100 mb
		Common.CommonSettingsStorageSave(
			"LocalFileCache", "LocalFileCacheMaxSize", MaxSize);
	EndIf;
	LocalFileCacheMaxSize = MaxSize / 1048576;
	
	If DeleteFileFromLocalFileCacheOnCompleteEdit Then
		Items.ConfirmOnDeleteFilesFromLocalCache.Enabled = True;
	Else
		Items.ConfirmOnDeleteFilesFromLocalCache.Enabled = False;
		ConfirmOnDeleteFilesFromLocalCache                      = False;
	EndIf;
	
EndProcedure

&AtClient
Procedure UpdateWorkDirectoryCurrentStatus()
	
#If NOT WebClient Then
	FilesArray = FindFiles(UserWorkingDirectory, GetAllFilesMask());
	WorkingDirectoryFileSize = 0;
	TotalCount = 0;
	
	FilesOperationsInternalClient.GetFileListSize(
		UserWorkingDirectory,
		FilesArray,
		WorkingDirectoryFileSize,
		TotalCount); 
	
	WorkingDirectoryFileSize = WorkingDirectoryFileSize / 1048576;
#EndIf
	
EndProcedure

&AtClient
Procedure SetNewWorkDirectory(NewDirectory)
	
	If NewDirectory = UserWorkingDirectory Then
		Return;
	EndIf;
	
#If Not WebClient Then
	Handler = New NotifyDescription(
		"SetNewWorkDirectoryCompletion", ThisObject, NewDirectory);
	
	FilesOperationsInternalClient.MoveWorkingDirectoryContent(
		Handler, UserWorkingDirectory, NewDirectory);
#Else
	SetNewWorkDirectoryCompletion(-1, NewDirectory);
#EndIf
	
EndProcedure

&AtClient
Procedure SetNewWorkDirectoryCompletion(Result, NewDirectory) Export
	
	If Result <> -1 Then
		If Result <> True Then
			Return;
		EndIf;
	EndIf;
	
	UserWorkingDirectory = NewDirectory;
	
	SaveParameters();
	
EndProcedure

#EndRegion
