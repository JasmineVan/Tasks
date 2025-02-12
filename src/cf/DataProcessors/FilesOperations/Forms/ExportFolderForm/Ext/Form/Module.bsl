﻿///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region EventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.ExportFolder <> Undefined Then
		WhatToSave = Parameters.ExportFolder;
	EndIf;
	
	If Common.SubsystemExists("StandardSubsystems.DigitalSignature") Then
		ModuleDigitalSignature = Common.CommonModule("DigitalSignature");
		
		EncryptedFilesExtension =
			ModuleDigitalSignature.PersonalSettings().EncryptedFilesExtension;
	Else
		EncryptedFilesExtension = "p7m";
	EndIf;
	
	FilesStorageCatalogName       = Parameters.FilesStorageCatalogName;
	FileVersionsStorageCatalogName = Parameters.FileVersionsStorageCatalogName;
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	// Setting "My documents" as an export folder.
	// folder used to export last time.
	FolderForExport = FilesOperationsInternalClient.DumpDirectory();
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure FolderForExportOpen(Item, StandardProcessing)
	
	StandardProcessing = False;
	If Not IsBlankString(Item.EditText) Then
		FileSystemClient.OpenExplorer(Item.EditText);
	EndIf;
	
EndProcedure

&AtClient
Procedure FolderForExportStartChoice(Item, ChoiceData, StandardProcessing)
	
	// Open the window of saving folder selecion.
	StandardProcessing = False;
	SelectFile = New FileDialog(FileDialogMode.ChooseDirectory);
	SelectFile.Multiselect = False;
	SelectFile.Directory = Item.EditText;
	If SelectFile.Choose() Then
		FolderForExport = SelectFile.Directory + GetPathSeparator();
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandHandlers

&AtClient
Procedure SaveFolder()
	
	If IsBlankString(FolderForExport) Or FolderForExport = GetPathSeparator() Then
		ShowMessageBox(, NStr("ru = 'Необходимо указать папку.'; en = 'Please select a folder.'; pl = 'Określ folder.';de = 'Geben Sie den Ordner an.';ro = 'Specificați folderul.';tr = 'Klasörü belirleyin.'; es_ES = 'Especificar la carpeta.'"));
		Return;
	EndIf;
	
	If NOT StrEndsWith(FolderForExport, GetPathSeparator()) Then
		FolderForExport = FolderForExport + GetPathSeparator();
	EndIf;
	
	// Checking if the dump directory exists. Create it if it does not.
	DumpDirectory = New File(FolderForExport);
	
	If Not DumpDirectory.Exist() Then
		ShowMessageBox(, StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Папка ""%1"" не найдена.
			           |Выберите другую папку.'; 
			           |en = 'Folder ""%1"" is not found.
			           |Please select another folder.'; 
			           |pl = 'Folder ""%1"" nie został znaleziony.
			           |Wybierz inny folder.';
			           |de = 'Ordner ""%1"" nicht gefunden.
			           |Wählen Sie einen anderen Ordner aus.';
			           |ro = 'Folderul ""%1"" nu a fost găsit.
			           |Selectați alt folder.';
			           |tr = 'Klasör ""%1"" bulunamadı. 
			           | Başka klasör seçin.'; 
			           |es_ES = 'Carpeta ""%1"" no encontrada.
			           |Seleccione otra carpeta.'"),
			FolderForExport));
		Return;
	EndIf;
	
	FullExportPath = FolderForExport + String(WhatToSave) + GetPathSeparator();
	If TransliterateFileAndFolderNames Then
		FullExportPath = StringFunctionsClientServer.LatinString(FullExportPath);
	EndIf;
	
	// If exported folder does not exist, create it.
	DumpDirectory = New File(FullExportPath);
	If Not DumpDirectory.Exist() Then
		ErrorText = "";
		Try
			CreateDirectory(FullExportPath);
			If Not DumpDirectory.Exist() Then
				Raise NStr("ru = 'После успешного создания подпапка не найдена.'; en = 'The created subfolder is not found.'; pl = 'Po pomyślnym utworzeniu podfolder nie znaleziono.';de = 'Nach erfolgreicher Erstellung wurde kein Unterordner gefunden.';ro = 'După crearea cu succes subfolderul nu a fost găsit.';tr = 'Başarı ile oluşturulan alt klasör bulunamadı.'; es_ES = 'Al crear con éxito la subcarpeta no encontrada.'");
			EndIf;
		Except
			ErrorInformation = ErrorInfo();
			ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'Не удалось создать подпапку ""%1"" в папке ""%2"" по причине:
				           |%3'; 
				           |en = 'Cannot create subfolder ""%1"" in folder ""%2"". Reason: 
				           |%3'; 
				           |pl = 'Nie udało się utworzyć podfolder ""%1"" w folderze ""%2"" z powodu:
				           |%3';
				           |de = 'Es konnte kein Unterordner ""%1"" im Ordner ""%2"" aus dem folgenden Grund erstellt werden:
				           |%3';
				           |ro = 'Eșec la crearea subfolderului ""%1"" în folderul ""%2"" din motivul:
				           |%3';
				           |tr = 'Aşağıdaki nedenle ""%1"" klasöründe ""%2"" alt klasör oluşturulamadı: 
				           |%3'; 
				           |es_ES = 'No se ha podido crear una subcarpeta ""%1"" en la carpeta ""%2"" a causa de: 
				           |%3'"),
				String(WhatToSave),
				FolderForExport,
				BriefErrorDescription(ErrorInformation));
		EndTry;
		If ErrorText <> "" Then
			ShowMessageBox(, ErrorText);
			Return;
		EndIf;
	EndIf;
	
	// Receiving the list of exported files.
	GenerateFilesTree(WhatToSave);
	
	// After that start exporting
	Handler = New NotifyDescription("SaveDirectoryCompletion", ThisObject);
	ProcessFilesTree(Handler, FilesTree, FullExportPath, WhatToSave, Undefined);
EndProcedure

&AtClient
Procedure SaveDirectoryCompletion(Result, ExecutionParameters) Export
	If Result.Success = True Then
		PathToSave = FolderForExport;
		CommonServerCall.CommonSettingsStorageSave("ExportFolderName", "ExportFolderName",  PathToSave);
		
		ShowUserNotification(NStr("ru = 'Экспорт папки'; en = 'Export folder'; pl = 'Eksport folderu';de = 'Ordner exportieren';ro = 'Export dosar';tr = 'Klasörü dışa aktar'; es_ES = 'Exportar carpeta'"),,
		             StringFunctionsClientServer.SubstituteParametersToString(
		               NStr("ru = 'Успешно завершен экспорт папки ""%1""
		                          |в папку на диске ""%2"".'; 
		                          |en = 'Folder ""%1""
		                          |is downloaded to folder ""%2"" on the hard drive.'; 
		                          |pl = 'Został pomyślnie zakończony eksport folderu ""%1""
		                          |do folderu na dysku ""%2"".';
		                          |de = 'Export des Ordners ""%1""
		                          |in einen Ordner auf der Festplatte ""%2"" erfolgreich abgeschlossen.';
		                          |ro = 'Exportul folderului ""%1""
		                          |în folderul pe disc ""%2"" este finalizat cu succes.';
		                          |tr = '""%1"" klasörü diskteki "
" klasörüne %2başarı ile aktarıldı.'; 
		                          |es_ES = 'La carpeta ""%1""
		                          |se ha exportado con éxito en la carpeta en el disco ""%2"".'"),
		               String(WhatToSave), String(FolderForExport) ) );
		
		Close();
	EndIf;
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure GenerateFilesTree(FolderParent)
	
	Query = New Query;
	QueryText =
	"SELECT ALLOWED
	|	Files.FileOwner AS Folder,
	|	Files.FileOwner.Description AS FolderDescription,
	|	&CurrentVersion AS CurrentVersion,
	|	Files.Description AS FullDescr,
	|	Files.Extension AS Extension,
	|	Files.Size AS Size,
	|	Files.UniversalModificationDate AS UniversalModificationDate,
	|	Files.Ref,
	|	Files.DeletionMark,
	|	Files.Encrypted
	|FROM
	|	Catalog.Files AS Files
	|WHERE
	|	Files.FileOwner IN HIERARCHY(&Ref)
	|	AND Files.DeletionMark = FALSE
	|TOTALS BY
	|	Folder HIERARCHY";
	Query.Parameters.Insert("Ref", FolderParent);
	
	If Not IsBlankString(FilesStorageCatalogName) Then
		
		QueryText = StrReplace(QueryText, "Files", FilesStorageCatalogName);
		QueryText = StrReplace(QueryText, "&CurrentVersion", FilesStorageCatalogName + ".Ref");
		QueryText = StrReplace(QueryText, "FileOwner", "Parent");
		
	Else
		
		CurrentVersionChoice = "CASE
		|		WHEN Files.CurrentVersion = VALUE(Catalog.FilesVersions.EmptyRef)
		|			THEN Files.Ref
		|		ELSE ISNULL(Files.CurrentVersion, VALUE(Catalog.FilesVersions.EmptyRef))
		|	END";
		
		QueryText = StrReplace(QueryText, "&CurrentVersion", CurrentVersionChoice);
		
	EndIf;
	
	Query.Text = QueryText;
	Result = Query.Execute();
	
	ExportedTable = Result.Unload(QueryResultIteration.ByGroupsWithHierarchy);
	If TransliterateFileAndFolderNames AND ExportedTable.Rows.Count() > 0 Then
		RootFolderForExport = ExportedTable.Rows[0];
		RootFolderForExport.FolderDescription = StringFunctionsClientServer.LatinString(RootFolderForExport.FolderDescription);
		RootFolderForExport.FullDescr = StringFunctionsClientServer.LatinString(RootFolderForExport.FullDescr);
		RootFolderForExport.Extension = StringFunctionsClientServer.LatinString(RootFolderForExport.Extension);
		ChangeNamesOfFilesAndFolders(RootFolderForExport);
	EndIf;
	
	ValueToFormAttribute(ExportedTable, "FilesTree");
	
EndProcedure

// A recursive function that actually exports files to a local hard drive.
//
// Parameters:
//   ResultHandler - NotifyDescription, Structure, Undefined - description of the procedure that 
//                          gets the method result.
//   FilesTable - TreeFormData - FormDataTreeItem - a value tree with exported files.
//   BaseSavingDirectory - String - a row with the folder name, to which files are saved.
//                 It recreates the folder structure (as in the file tree) if necessary.
//                 
//   ParentFolder - CatalogRef.FilesFolders - items to save.
//   CommonParameters - Structure -
//       * ForAllFiles - Boolean -
//                 True: the user chose the action when overwriting the file and checked "For all".
//                  Do not ask more questions.
//                 False: ask a question in every time a file that has the same name as in the 
//                 infobase exists on the hard drive.
//       * BaseAction - DialogReturnCode - when performing one action for all conflicts when writing 
//                 a file (parameter ForAllFiles = True) the action specified by this parameter is 
//                 performed).
//                 
//                 .Yes - rewrite.
//                 .Skip - skip file.
//                 .Abort - abort export.
//
// Returns:
//   Structure - result.
//       * Success - Boolean - True - can continue export or export is completed successfully.
//                         False - action is completed with errors or export is completed with errors.
//
&AtClient
Procedure ProcessFilesTree(ResultHandler, FilesTable, BaseSaveDirectory, ParentFolder, CommonParameters)
	
	If CommonParameters = Undefined Then
		CommonParameters = New Structure;
		CommonParameters.Insert("BaseAction", DialogReturnCode.Ignore);
		CommonParameters.Insert("ForAllFiles", False);
		CommonParameters.Insert("NotMetFolderToBeExportedYet", True);
	EndIf;
	
	ExecutionParameters = New Structure;
	ExecutionParameters.Insert("ResultHandler", ResultHandler);
	ExecutionParameters.Insert("FilesTable", FilesTable);
	ExecutionParameters.Insert("BaseSaveDirectory", BaseSaveDirectory);
	ExecutionParameters.Insert("ParentFolder", ParentFolder);
	ExecutionParameters.Insert("CommonParameters", CommonParameters);
	
	// Result parameters.
	ExecutionParameters.Insert("Success", False);
	
	// Parameters for the loop.
	ExecutionParameters.Insert("Items", ExecutionParameters.FilesTable.GetItems());
	ExecutionParameters.Insert("UBound", ExecutionParameters.Items.Count()-1);
	ExecutionParameters.Insert("IndexOf",   -1);
	ExecutionParameters.Insert("LoopStartRequired", True);
	FilesOperationsInternalClient.RegisterHandlerDetails(
		ExecutionParameters,
		ThisObject,
		"IterateFileTree2");
	
	// Variables.
	ExecutionParameters.Insert("WritingFile", Undefined);
	
	// Loop start.
	ProcessFilesTreeLoopStart(ExecutionParameters);
EndProcedure

&AtClient
Procedure ProcessFilesTreeLoopStart(ExecutionParameters)
	If ExecutionParameters.LoopStartRequired Then
		If ExecutionParameters.AsynchronousDialog.Open Then
			Return; // If one more dialog box was opened, a loop start is not required.
		EndIf;
		ExecutionParameters.IndexOf = ExecutionParameters.IndexOf + 1;
		ExecutionParameters.LoopStartRequired = False;
	Else
		Return; // Loop is already started.
	EndIf;
	
	For Index = ExecutionParameters.IndexOf To ExecutionParameters.UBound Do
		ExecutionParameters.WritingFile = ExecutionParameters.Items[Index];
		ExecutionParameters.IndexOf = Index;
		ProcessFilesTree1(ExecutionParameters);
		If ExecutionParameters.AsynchronousDialog.Open Then
			Return; // Loop pause. Stack is being cleared.
		EndIf;
	EndDo;
	
	ExecutionParameters.Success = True;
	FilesOperationsInternalClient.ReturnResult(ExecutionParameters.ResultHandler, ExecutionParameters);
EndProcedure

&AtClient
Procedure ProcessFilesTree1(ExecutionParameters)
	If ExecutionParameters.CommonParameters.NotMetFolderToBeExportedYet = True Then
		If ExecutionParameters.WritingFile.Folder = WhatToSave Then
			ExecutionParameters.CommonParameters.NotMetFolderToBeExportedYet = False;
		EndIf;
	EndIf;
	
	If ExecutionParameters.CommonParameters.NotMetFolderToBeExportedYet = True Then
		
		FilesOperationsInternalClient.RegisterHandlerDetails(
			ExecutionParameters,
			ThisObject,
			"IterateFileTree2");
		
		ProcessFilesTree(
			ExecutionParameters,
			ExecutionParameters.WritingFile,
			ExecutionParameters.BaseSaveDirectory,
			ExecutionParameters.WritingFile.Folder,
			ExecutionParameters.CommonParameters);
		
		If ExecutionParameters.AsynchronousDialog.Open Then
			Return; // Loop pause. Stack is being cleared.
		EndIf;
		
		IterateFileTree2(ExecutionParameters.AsynchronousDialog.ResultWhenNotOpen, ExecutionParameters);
		Return;
	EndIf;
	
	ProcessFilesTree3(ExecutionParameters);
EndProcedure

&AtClient
Procedure IterateFileTree2(Result, ExecutionParameters) Export
	If ExecutionParameters.AsynchronousDialog.Open Then
		ExecutionParameters.LoopStartRequired = True;
		ExecutionParameters.AsynchronousDialog.Open = False;
	EndIf;
	
	If Result.Success <> True Then
		ExecutionParameters.Success = False;
		ExecutionParameters.LoopStartRequired = False; // Loop restart is not required.
		FilesOperationsInternalClient.ReturnResult(ExecutionParameters.ResultHandler, ExecutionParameters);
		Return;
	EndIf;
	
	ProcessFilesTreeLoopStart(ExecutionParameters);
EndProcedure

&AtClient
Procedure ProcessFilesTree3(ExecutionParameters)
	// Generate a path to directory and go further. Create directories.
	ExecutionParameters.Insert("SaveFileBaseDirectory", ExecutionParameters.BaseSaveDirectory);
	If ExecutionParameters.WritingFile.Folder <> WhatToSave
		AND ExecutionParameters.WritingFile.CurrentVersion = Undefined
		AND ExecutionParameters.WritingFile.Folder <> ExecutionParameters.ParentFolder Then
		ExecutionParameters.SaveFileBaseDirectory = (
			ExecutionParameters.SaveFileBaseDirectory
			+ ExecutionParameters.WritingFile.FolderDescription
			+ GetPathSeparator());
	EndIf;
	
	// Checking if the base directory exists and create if it does not.
	Folder = New File(ExecutionParameters.SaveFileBaseDirectory);
	If Not Folder.Exist() Then
		ProcessFilesTree4(ExecutionParameters);
		Return;
	EndIf;
	
	ProcessFilesTree6(ExecutionParameters);
EndProcedure

&AtClient
Procedure ProcessFilesTree4(ExecutionParameters)
	ErrorText = "";
	Try
		CreateDirectory(ExecutionParameters.SaveFileBaseDirectory);
	Except
		ErrorText = NStr("ru = 'Ошибка создания папки ""%1"":'; en = 'Cannot create folder ""%1"":'; pl = 'Wystąpił błąd podczas tworzenia folderu ""%1"":';de = 'Beim Erstellen des Ordners ""%1"" ist ein Fehler aufgetreten:';ro = 'A apărut o eroare la crearea directorului ""%1"":';tr = '""%1"" Klasörü oluşturulurken bir hata oluştu:'; es_ES = 'Ha ocurrido un error al crear la carpeta ""%1"":'");
		ErrorText = StrReplace(ErrorText, "%1", ExecutionParameters.SaveFileBaseDirectory);
		ErrorText = ErrorText + Chars.LF + Chars.LF + BriefErrorDescription(ErrorInfo());
	EndTry;
	
	If ErrorText <> "" Then
		FilesOperationsInternalClient.PrepareHandlerForDialog(ExecutionParameters);
		Handler = New NotifyDescription("ProcessFilesTree5", ThisObject, ExecutionParameters);
		ShowQueryBox(Handler, ErrorText, QuestionDialogMode.AbortRetryIgnore, , DialogReturnCode.Retry);
		Return;
	EndIf;
	
	ProcessFilesTree6(ExecutionParameters);
EndProcedure

&AtClient
Procedure ProcessFilesTree5(Response, ExecutionParameters) Export
	If ExecutionParameters.AsynchronousDialog.Open Then
		ExecutionParameters.LoopStartRequired = True;
		ExecutionParameters.AsynchronousDialog.Open = False;
	EndIf;
	
	If Response = DialogReturnCode.Abort Then
		// Just exit with an error.
		ExecutionParameters.Success = False;
		ExecutionParameters.LoopStartRequired = False; // Loop restart is not required.
		FilesOperationsInternalClient.ReturnResult(ExecutionParameters.ResultHandler, ExecutionParameters);
		Return;
	ElsIf Response = DialogReturnCode.Ignore Then
		// Skipping this row of the tree and proceed to other actions.
		ExecutionParameters.Success = True;
		ExecutionParameters.LoopStartRequired = False; // Loop restart is not required.
		FilesOperationsInternalClient.ReturnResult(ExecutionParameters.ResultHandler, ExecutionParameters);
		Return;
	EndIf;
	
	// Trying to create a folder again.
	ProcessFilesTree4(ExecutionParameters);
EndProcedure

&AtClient
Procedure ProcessFilesTree6(ExecutionParameters)
	// Only if there is at least one file in this folder.
	SubordinateItems = ExecutionParameters.WritingFile.GetItems();
	If SubordinateItems.Count() > 0 Then
		
		FilesOperationsInternalClient.RegisterHandlerDetails(
			ExecutionParameters,
			ThisObject,
			"IterateFileTree7");
		
		ProcessFilesTree(
			ExecutionParameters,
			ExecutionParameters.WritingFile,
			ExecutionParameters.SaveFileBaseDirectory,
			ExecutionParameters.WritingFile.Folder,
			ExecutionParameters.CommonParameters);
		
		If ExecutionParameters.AsynchronousDialog.Open Then
			Return; // Loop pause. Stack is being cleared.
		EndIf;
		
		IterateFileTree7(ExecutionParameters.AsynchronousDialog.ResultWhenNotOpen, ExecutionParameters);
		Return;
	EndIf;
	
	ProcessFilesTree8(ExecutionParameters);
EndProcedure

&AtClient
Procedure IterateFileTree7(Result, ExecutionParameters) Export
	If ExecutionParameters.AsynchronousDialog.Open Then
		ExecutionParameters.LoopStartRequired = True;
		ExecutionParameters.AsynchronousDialog.Open = False;
	EndIf;
	
	If Result.Success <> True Then
		ExecutionParameters.Success = False;
		ExecutionParameters.LoopStartRequired = False;
		FilesOperationsInternalClient.ReturnResult(ExecutionParameters.ResultHandler, ExecutionParameters);
		Return;
	EndIf;
	
	// Continue processing the item.
	ProcessFilesTree8(ExecutionParameters);
	
	// Restart loop if an asynchronous dialog box was opened.
	ProcessFilesTreeLoopStart(ExecutionParameters);
EndProcedure

&AtClient
Procedure ProcessFilesTree8(ExecutionParameters)
	If (ExecutionParameters.WritingFile.CurrentVersion <> Undefined
		AND ExecutionParameters.WritingFile.CurrentVersion.IsEmpty()) Or ExecutionParameters.WritingFile.CurrentVersion = Undefined Then
		// This is an item of Files catalog without a file. Skip it.
		Return;
	EndIf;
	
	// Writing file to the base directory.
	ExecutionParameters.Insert("FileNameWithExtension", Undefined);
	ExecutionParameters.FileNameWithExtension = CommonClientServer.GetNameWithExtension(
		ExecutionParameters.WritingFile.FullDescr,
		ExecutionParameters.WritingFile.Extension);
	
	If ExecutionParameters.WritingFile.Encrypted Then
		ExecutionParameters.FileNameWithExtension = ExecutionParameters.FileNameWithExtension + "." + EncryptedFilesExtension;
	EndIf;
	ExecutionParameters.Insert("FullFileName", ExecutionParameters.SaveFileBaseDirectory + ExecutionParameters.FileNameWithExtension);
	
	ExecutionParameters.Insert("Result", Undefined);
	ProcessFilesTree9(ExecutionParameters);
EndProcedure

&AtClient
Procedure ProcessFilesTree9(ExecutionParameters)
	ExecutionParameters.Insert("FileOnHardDrive", New File(ExecutionParameters.FullFileName));
	If ExecutionParameters.FileOnHardDrive.Exist() AND ExecutionParameters.FileOnHardDrive.IsDirectory() Then
		QuestionText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Вместо файла
			           |""%1""
			           |существует папка с таким же именем.
			           |
			           |Повторить экспорт этого файла?'; 
			           |en = 'A file named
			           |""%1""
			           |is found instead of a folder.
			           |
			           |Do you want to download the file again?'; 
			           |pl = 'Zamiast pliku
			           |""%1""
			           |istnieje folder z takim imieniem.
			           |
			           |Powtórzyć eksport tego pliku?';
			           |de = 'Es gibt einen Ordner mit dem gleichen Namen anstelle der Datei
			           |""%1""
			           |.
			           |
			           |Möchten Sie diese Datei erneut exportieren?';
			           |ro = 'În schimbul fișierului
			           |""%1""
			           |există folderul cu același nule.
			           |
			           |Repetați exportul acestui fișier?';
			           |tr = '"
" adlı dosya yerine 
			           |aynı ada %1 sahip klasör var. 
			           |
			           |Dosya yeniden gönderilsin mi?'; 
			           |es_ES = 'En vez del archivo
			           |""%1""
			           |existe una carpeta con el mismo nombre.
			           |
			           |¿Volver a exportar este archivo?'"),
			ExecutionParameters.FullFileName);
		FilesOperationsInternalClient.PrepareHandlerForDialog(ExecutionParameters);
		Handler = New NotifyDescription("ProcessFilesTree10", ThisObject, ExecutionParameters);
		ShowQueryBox(Handler, QuestionText, QuestionDialogMode.RetryCancel, , DialogReturnCode.Cancel);
		Return;
	EndIf;
	
	// There is no file, proceed to the next step.
	ExecutionParameters.Result = DialogReturnCode.Retry;
	ProcessFilesTree11(ExecutionParameters);
EndProcedure

&AtClient
Procedure ProcessFilesTree10(Response, ExecutionParameters) Export
	If ExecutionParameters.AsynchronousDialog.Open Then
		ExecutionParameters.LoopStartRequired = True;
		ExecutionParameters.AsynchronousDialog.Open = False;
	EndIf;
	
	If Response = DialogReturnCode.Retry Then
		// Ignore this file.
		ProcessFilesTree9(ExecutionParameters);
		Return;
	EndIf;
	
	// Continue processing the item.
	ExecutionParameters.Result = DialogReturnCode.Cancel;
	ProcessFilesTree11(ExecutionParameters);
	
	// Restart loop if an asynchronous dialog box was opened.
	ProcessFilesTreeLoopStart(ExecutionParameters);
EndProcedure

&AtClient
Procedure ProcessFilesTree11(ExecutionParameters)
	If ExecutionParameters.Result = DialogReturnCode.Cancel Then
		// Ignoring the file named like a folder.
		Return;
	EndIf;
	
	ExecutionParameters.Result = DialogReturnCode.No;
	
	// Asking what to do with the current file.
	If ExecutionParameters.FileOnHardDrive.Exist() Then
		
		// If the file has R|O and the change time is less than in the infobase, simply rewrite it.
		If  ExecutionParameters.FileOnHardDrive.GetReadOnly()
			AND ExecutionParameters.FileOnHardDrive.GetModificationUniversalTime() <= ExecutionParameters.WritingFile.UniversalModificationDate Then
			ExecutionParameters.Result = DialogReturnCode.Yes;
		Else
			If Not ExecutionParameters.CommonParameters.ForAllFiles Then
				MessageText = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("ru = 'В папке ""%1""
					           |существует файл ""%2""
					           |размер существующего файла = %3 байт, дата изменения %4.
					           |размер сохраняемого файла = %5 байт, дата изменения %6.
					           |
					           |Заменить существующий файл файлом из хранилища файлов?'; 
					           |en = 'Folder ""%1""
					           |contains file ""%2"".
					           |The existing file size is %3 bytes, last modified on %4.
					           |The stored file size is %5 bytes, last modified on %6.
					           |
					           |Do you want to overwrite the existing file with the file from the storage?'; 
					           |pl = 'W folderze ""%1""
					           |istnieje plik ""%2""
					           |rozmiar istniejącego pliku = %3 bajtów, data zmiany%4.
					           |rozmiar zapisywanego pliku = %5 bajtów, data zmiany %6.
					           |
					           |Zastąpić istniejący plik plikiem z repozytorium plików?';
					           |de = 'Im Ordner ""%1""
					           |befindet sich eine Datei ""%2""
					           |der Größe einer vorhandenen Datei = %3Bytes, Datum der Änderung %4.
					           |Größe der gespeicherten Datei = %5 Bytes, Datum der Änderung %6.
					           |
					           |Eine bestehende Datei durch eine Datei aus dem Dateispeicher ersetzen?';
					           |ro = 'Folderul ""%1""
					           |conține fișierul ""%2""
					           |, dimensiunea fișierului existent =%3 biți, data modificării este %4.
					           |dimensiunea fișierului salvat =%5 biți, data modificării este %6.
					           |
					           |Înlocuiți fișierul existent cu un fișier din storagele fișierelor?';
					           |tr = 'Klasör  ""%1"" zaten ""
					           | "" %3 dosyasını içermektedir, mevcut dosyanın boyutu = 
					           |bayt, değiştirilen tarih %2 .  %4 kaydedilmiş dosyanın boyutu =
					           | bayt, değiştirildiği tarih %5. %6
					           |
					           |Varolan dosya dosya deposundan bir dosya ile değiştirilsin mi?'; 
					           |es_ES = 'En la carpeta ""%1""
					           |existe un archivo ""%2""
					           |el tamaño del archivo existente = %3 bytes, fecha de modificación %4.
					           |tamaño del archivo guardado = %5bytes, fecha de modificación %6.
					           |
					           |¿Reemplazar el archivo existente con el archivo del almacenamiento de archivos?'"),
					ExecutionParameters.SaveFileBaseDirectory,
					ExecutionParameters.FileNameWithExtension,
					ExecutionParameters.FileOnHardDrive.Size(),
					ToLocalTime(ExecutionParameters.FileOnHardDrive.GetModificationUniversalTime()),
					ExecutionParameters.WritingFile.Size,
					ToLocalTime(ExecutionParameters.WritingFile.UniversalModificationDate));
				
				ParametersStructure = New Structure;
				ParametersStructure.Insert("MessageText",   MessageText);
				ParametersStructure.Insert("ApplyForAll", ExecutionParameters.CommonParameters.ForAllFiles);
				ParametersStructure.Insert("BaseAction",  String(ExecutionParameters.CommonParameters.BaseAction));
				
				FilesOperationsInternalClient.PrepareHandlerForDialog(ExecutionParameters);
				Handler = New NotifyDescription("ProcessFilesTree12", ThisObject, ExecutionParameters);
				
				OpenForm("DataProcessor.FilesOperations.Form.FileExists", ParametersStructure, , , , , Handler);
				Return;
			EndIf;
			
			ExecutionParameters.Result = ExecutionParameters.CommonParameters.BaseAction;
			ProcessFilesTree13(ExecutionParameters);
			Return;
		EndIf;
	EndIf;
	
	// If there is no file, do not ask.
	ExecutionParameters.Result = DialogReturnCode.Yes;
	ProcessFilesTree14(ExecutionParameters);
EndProcedure

&AtClient
Procedure ProcessFilesTree12(Result, ExecutionParameters) Export
	If ExecutionParameters.AsynchronousDialog.Open Then
		ExecutionParameters.LoopStartRequired = True;
		ExecutionParameters.AsynchronousDialog.Open = False;
	EndIf;
	
	ExecutionParameters.Result = Result.ReturnCode;
	ExecutionParameters.CommonParameters.ForAllFiles = Result.ApplyForAll;
	ExecutionParameters.CommonParameters.BaseAction = ExecutionParameters.Result;
	
	// Continue processing the item.
	ProcessFilesTree13(ExecutionParameters);
	
	// Restart loop if an asynchronous dialog box was opened.
	ProcessFilesTreeLoopStart(ExecutionParameters);
EndProcedure

&AtClient
Procedure ProcessFilesTree13(ExecutionParameters)
	If ExecutionParameters.Result = DialogReturnCode.Abort Then
		// Aborting export.
		ExecutionParameters.Success = False;
		ExecutionParameters.LoopStartRequired = False; // Loop restart is not required.
		FilesOperationsInternalClient.ReturnResult(ExecutionParameters.ResultHandler, ExecutionParameters);
		Return;
	ElsIf ExecutionParameters.Result = DialogReturnCode.Ignore Then
		// Skipping this file.
		Return;
	EndIf;
	
	// Writing file to the file system if it is possible.
	If ExecutionParameters.Result <> DialogReturnCode.Yes Then
		Return;
	EndIf;
	
	ProcessFilesTree14(ExecutionParameters);
EndProcedure

&AtClient
Procedure ProcessFilesTree14(ExecutionParameters)
	ExecutionParameters.FileOnHardDrive = New File(ExecutionParameters.FullFileName);
	If ExecutionParameters.FileOnHardDrive.Exist() Then
		// Unchecking R|O to be able to delete file.
		ExecutionParameters.FileOnHardDrive.SetReadOnly(False);
		
		// Always delete and then generate again.
		ErrorInformation = Undefined;
		Try
			DeleteFiles(ExecutionParameters.FullFileName);
		Except
			ErrorInformation = ErrorInfo();
		EndTry;
		
		If ErrorInformation <> Undefined Then
			ProcessFilesTree15(ErrorInformation, ExecutionParameters);
			Return;
		EndIf;
	EndIf;
	
	// Writing file again.
	FileAddressToOpen = FilesOperationsInternalServerCall.GetURLToOpen(
		ExecutionParameters.WritingFile.CurrentVersion,
		UUID);
	
	Try
		FilesToGet  = New Array;
		FileToPass = New TransferableFileDescription();
		ReceivedFiles  = New Array;

		FileToPass.Location = FileAddressToOpen;
		FileToPass.Name      = ExecutionParameters.FullFileName;
		FilesToGet.Add(FileToPass);
		
		GetFiles(FilesToGet, ReceivedFiles, ExecutionParameters.SaveFileBaseDirectory, False);
	Except
		ErrorInformation = ErrorInfo();
	EndTry;
	If ErrorInformation <> Undefined Then
		ProcessFilesTree15(ErrorInformation, ExecutionParameters);
		Return;
	EndIf;
		
	If ReceivedFiles.Count() = 0 
		Or IsBlankString(ReceivedFiles[0].Name) Then
		// File was not received.
		Return;
	EndIf;
	
	// For the option of storing files on hard drive (on the server), deleting the file from the temporary storage after receiving it.
	If IsTempStorageURL(FileAddressToOpen) Then
		DeleteFromTempStorage(FileAddressToOpen);
	EndIf;
	
	ExecutionParameters.FileOnHardDrive = New File(ExecutionParameters.FullFileName);
	
	Try
		// Creating a readonly file.
		ExecutionParameters.FileOnHardDrive.SetReadOnly(True);
		// Setting the modification time as in the infobase.
		ExecutionParameters.FileOnHardDrive.SetModificationUniversalTime(
			ExecutionParameters.WritingFile.UniversalModificationDate);
	Except
		ErrorInformation = ErrorInfo();
	EndTry;
	
	If ErrorInformation <> Undefined Then
		ProcessFilesTree15(ErrorInformation, ExecutionParameters);
		Return;
	EndIf;
	
EndProcedure

&AtClient
Procedure ProcessFilesTree15(ErrorInformation, ExecutionParameters)
	// For some reason there was a file error when writing a file and changing its attributes.
	// 
	QuestionText = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("ru = 'Ошибка записи файла
		           |""%1"".
		           |
		           |%2.'; 
		           |en = 'Cannot save file
		           |""%1"".
		           |
		           |%2.'; 
		           |pl = 'Błąd zapisu pliku
		           |""%1"".
		           |
		           |%2.';
		           |de = 'Fehler beim Schreiben der Datei
		           |""%1"".
		           |
		           |%2.';
		           |ro = 'Eroare la înregistrarea fișierului 
		           |""%1"".
		           |
		           |%2.';
		           |tr = '"
" Dosyası kaydedilirken bir %1 hata oluştu.
		           |
		           |%2'; 
		           |es_ES = 'Error de guardar el archivo
		           |""%1"".
		           |
		           |%2.'"),
		ExecutionParameters.FullFileName,
		BriefErrorDescription(ErrorInformation));
	
	FilesOperationsInternalClient.PrepareHandlerForDialog(ExecutionParameters);
	Handler = New NotifyDescription("ProcessFilesTree16", ThisObject, ExecutionParameters);
	
	ShowQueryBox(Handler, QuestionText, QuestionDialogMode.AbortRetryIgnore, , DialogReturnCode.Retry);
EndProcedure

&AtClient
Procedure ProcessFilesTree16(Response, ExecutionParameters) Export
	If Response = DialogReturnCode.Abort Then
		// Just exit with an error.
		ExecutionParameters.Success = False;
		ExecutionParameters.LoopStartRequired = False; // Loop restart is not required.
		// False.
		FilesOperationsInternalClient.ReturnResult(ExecutionParameters.ResultHandler, ExecutionParameters);
		Return;
	ElsIf Response = DialogReturnCode.Ignore Then
		// Skipping this file and proceeding to the next step.
		Return;
	EndIf;
	
	// Trying to create a folder again.
	ProcessFilesTree14(ExecutionParameters);
EndProcedure

&AtServer
Procedure ChangeNamesOfFilesAndFolders(TreeItem)
	
	For Each FileOrFolder In TreeItem.Rows Do
		FileOrFolder.FolderDescription = StringFunctionsClientServer.LatinString(FileOrFolder.FolderDescription);
		FileOrFolder.FullDescr = StringFunctionsClientServer.LatinString(FileOrFolder.FullDescr);
		FileOrFolder.Extension = StringFunctionsClientServer.LatinString(FileOrFolder.Extension);
		ChangeNamesOfFilesAndFolders(FileOrFolder);
	EndDo;
	
EndProcedure;

#EndRegion
