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
	
	If Parameters.FolderForAdding = Undefined Then
		Raise NStr("ru='Обработка не предназначена для непосредственного использования.'; en = 'The data processor cannot be opened manually.'; pl = 'Opracowanie nie jest przeznaczone do bezpośredniego użycia.';de = 'Der Datenprozessor ist nicht für den direkten Gebrauch bestimmt.';ro = 'Procesarea nu este destinată pentru utilizare nemijlocită.';tr = 'Veri işlemcisi doğrudan kullanım için uygun değildir.'; es_ES = 'Procesador de datos no está destinado al uso directo.'");
	EndIf;
	
	GroupOfFiles = Parameters.GroupOfFiles;
	FolderForAdding = Parameters.FolderForAdding;
	FolderToAddAsString = Common.SubjectString(FolderForAdding);
	StoreVersions = FilesOperationsInternalServerCall.IsDirectoryFiles(FolderForAdding);
	Items.StoreVersions.Visible = StoreVersions;
	
	If TypeOf(Parameters.FileNamesArray) = Type("Array") Then
		For Each FilePath In Parameters.FileNamesArray Do
			MovedFile = New File(FilePath);
			NewItem = SelectedFiles.Add();
			NewItem.Path = FilePath;
			NewItem.PictureIndex = FilesOperationsInternalClientServer.GetFileIconIndex(MovedFile.Extension);
		EndDo;
	EndIf;
	
EndProcedure

&AtClient
Procedure ChoiceProcessing(SelectedValue, ChoiceSource)
	If Upper(ChoiceSource.FormName) = Upper("DataProcessor.FilesOperations.Form.SelectEncoding") Then
		If TypeOf(SelectedValue) <> Type("Structure") Then
			Return;
		EndIf;
		FileTextEncoding = SelectedValue.Value;
		EncodingPresentation = SelectedValue.Presentation;
		SetCodingCommandPresentation(EncodingPresentation);
	EndIf;
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersSelectedFiles

&AtClient
Procedure SelectedFilesOnAddStart(Item, Cancel, Clone)
	Cancel = True;
EndProcedure

#EndRegion

#Region FormCommandHandlers

&AtClient
Procedure AddExecute()
	
	ClearMessages();
	
	FieldsNotFilled = False;
	
	If SelectedFiles.Count() = 0 Then
		CommonClient.MessageToUser(
			NStr("ru = 'Нет файлов для добавления.'; en = 'There are no files to add.'; pl = 'Brak plików do dodania.';de = 'Keine Dateien zum Hinzufügen';ro = 'Nu se adaugă fișiere.';tr = 'Eklenecek dosyalar yok.'; es_ES = 'No hay archivos para añadir.'"), , "SelectedFiles");
		FieldsNotFilled = True;
	EndIf;
	
	If FieldsNotFilled = True Then
		Return;
	EndIf;
	
	SelectedFileValueList = New ValueList;
	For Each ListLine In SelectedFiles Do
		SelectedFileValueList.Add(ListLine.Path);
	EndDo;
	
#If WebClient Then
	
	OperationArray = New Array;
	
	For Each ListLine In SelectedFiles Do
		CallDetails = New Array;
		CallDetails.Add("PutFiles");
		
		FilesToPut = New Array;
		Details = New TransferableFileDescription(ListLine.Path, "");
		FilesToPut.Add(Details);
		CallDetails.Add(FilesToPut);
		
		CallDetails.Add(Undefined); // not used
		CallDetails.Add(Undefined); // not used
		CallDetails.Add(False);         // Interactively = False
		
		OperationArray.Add(CallDetails);
	EndDo;
	
	If NOT RequestUserPermission(OperationArray) Then
		// User did not give a permission.
		Close();
		Return;
	EndIf;	
#EndIf	
	
	AddedFiles = New Array;
	
	HandlerParameters = New Structure;
	HandlerParameters.Insert("AddedFiles", AddedFiles);
	Handler = New NotifyDescription("AddExecuteCompletion", ThisObject, HandlerParameters);
	
	ExecutionParameters = FilesOperationsInternalClient.FilesImportParameters();
	ExecutionParameters.ResultHandler          = Handler;
	ExecutionParameters.Owner                      = FolderForAdding;
	ExecutionParameters.SelectedFiles                = SelectedFileValueList; 
	ExecutionParameters.Comment                   = Comment;
	ExecutionParameters.StoreVersions                 = StoreVersions;
	ExecutionParameters.DeleteFilesAfterAdd   = DeleteFilesAfterAdd;
	ExecutionParameters.Recursively                    = False;
	ExecutionParameters.FormID            = UUID;
	ExecutionParameters.AddedFiles              = AddedFiles;
	ExecutionParameters.Encoding                     = FileTextEncoding;
	ExecutionParameters.GroupOfFiles                  = GroupOfFiles;
	
	FilesOperationsInternalClient.ExecuteFilesImport(ExecutionParameters);
EndProcedure

&AtClient
Procedure SelectFilesExecute()
	
	Handler = New NotifyDescription("SelectFilesExecuteAfterInstallExtension", ThisObject);
	FilesOperationsInternalClient.ShowFileSystemExtensionInstallationQuestion(Handler);
	
EndProcedure

&AtClient
Procedure SelectEncoding(Command)
	FormParameters = New Structure;
	FormParameters.Insert("CurrentEncoding", FileTextEncoding);
	OpenForm("DataProcessor.FilesOperations.Form.SelectEncoding", FormParameters, ThisObject);
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SetCodingCommandPresentation(Presentation)
	
	Commands.SelectEncoding.Title = Presentation;
	
EndProcedure

&AtClient
Procedure AddExecuteCompletion(Result, ExecutionParameters) Export
	Close();
	
	Source = Undefined;
	AddedFilesCount = Result.AddedFiles.Count();
	If AddedFilesCount > 0 Then
		Source = Result.AddedFiles[AddedFilesCount - 1].FileRef;
	EndIf;
	Notify("Write_File", New Structure("IsNew", True), Source);
EndProcedure

&AtClient
Procedure SelectFilesExecuteAfterInstallExtension(ExtensionInstalled, ExecutionParameters) Export
	If Not ExtensionInstalled Then
		Return;
	EndIf;
	
	Mode = FileDialogMode.Open;
	
	OpenFileDialog = New FileDialog(Mode);
	OpenFileDialog.FullFileName = "";
	Filter = NStr("ru = 'Все файлы(*.*)|*.*'; en = 'All files (*.*)|*.*'; pl = 'Wszystkie pliki(*.*)|*.*';de = 'Alle Dateien (*.*)|*.*';ro = 'Toate fișierele (*.*)|*.*';tr = 'Tüm dosyalar (*. *) | *. *'; es_ES = 'Todos archivos (*.*)|*.*'");
	OpenFileDialog.Filter = Filter;
	OpenFileDialog.Multiselect = True;
	OpenFileDialog.Title = NStr("ru = 'Выберите файлы'; en = 'Select files'; pl = 'Wybrać pliki';de = 'Dateien wählen';ro = 'Selectați fișiere';tr = 'Dosyaları seçin'; es_ES = 'Seleccionar archivos'");
	If OpenFileDialog.Choose() Then
		SelectedFiles.Clear();
		
		FilesArray = OpenFileDialog.SelectedFiles;
		For Each FileName In FilesArray Do
			MovedFile = New File(FileName);
			NewItem = SelectedFiles.Add();
			NewItem.Path = FileName;
			NewItem.PictureIndex = FilesOperationsInternalClientServer.GetFileIconIndex(MovedFile.Extension);
		EndDo;
	EndIf;
	
EndProcedure

#EndRegion
