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
	
	If Not ValueIsFilled(Parameters.DirectoryOnHardDrive) Then
		Raise NStr("ru='Обработка не предназначена для непосредственного использования.'; en = 'The data processor cannot be opened manually.'; pl = 'Opracowanie nie jest przeznaczone do bezpośredniego użycia.';de = 'Der Datenprozessor ist nicht für den direkten Gebrauch bestimmt.';ro = 'Procesarea nu este destinată pentru utilizare nemijlocită.';tr = 'Veri işlemcisi doğrudan kullanım için uygun değildir.'; es_ES = 'Procesador de datos no está destinado al uso directo.'");
	EndIf;
	
	GroupOfFiles = Parameters.GroupOfFiles;
	Directory = Parameters.DirectoryOnHardDrive;
	FolderForAdding = Parameters.FolderForAdding;
	FolderToAddAsString = Common.SubjectString(FolderForAdding);
	DirectoriesChoice = True;
	StoreVersions = FilesOperationsInternalServerCall.IsDirectoryFiles(FolderForAdding);
	Items.StoreVersions.Visible = StoreVersions;
	
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

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure SelectedDirectoryStartChoice(Item, ChoiceData, StandardProcessing)
	// Code is called only from IE or thin client, check on the web client is not required.
	Mode = FileDialogMode.ChooseDirectory;
	
	OpenFileDialog = New FileDialog(Mode);
	
	OpenFileDialog.Directory = Directory;
	OpenFileDialog.FullFileName = "";
	Filter = NStr("ru = 'Все файлы(*.*)|*.*'; en = 'All files (*.*)|*.*'; pl = 'Wszystkie pliki(*.*)|*.*';de = 'Alle Dateien (*.*)|*.*';ro = 'Toate fișierele (*.*)|*.*';tr = 'Tüm dosyalar (*. *) | *. *'; es_ES = 'Todos archivos (*.*)|*.*'");
	OpenFileDialog.Filter = Filter;
	OpenFileDialog.Multiselect = False;
	OpenFileDialog.Title = NStr("ru = 'Выберите каталог'; en = 'Select directory'; pl = 'Wybierz folder';de = 'Wählen Sie das Verzeichnis aus';ro = 'Selectați directorul';tr = 'Dizini seçin'; es_ES = 'Seleccionar el directorio'");
	If OpenFileDialog.Choose() Then
		
		If DirectoriesChoice = True Then 
			
			Directory = OpenFileDialog.Directory;
			
		EndIf;
		
	EndIf;
		
	StandardProcessing = False;
EndProcedure

#EndRegion

#Region FormCommandHandlers

&AtClient
Procedure ImportExecute()
	
	If IsBlankString(Directory) Then
		
		CommonClient.MessageToUser(
			NStr("ru = 'Не выбран каталог для импорта.'; en = 'Please select a directory to upload.'; pl = 'Nie wybrano katalogu do importu.';de = 'Katalog zum Importieren ist nicht ausgewählt.';ro = 'Catalogul pentru import nu este selectat.';tr = 'İçe aktarım kataloğu seçilmedi.'; es_ES = 'Catálogo para importación no se ha seleccionado.'"), , "Directory");
		Return;
		
	EndIf;
	
	If FolderForAdding.IsEmpty() Then
		CommonClient.MessageToUser(
			NStr("ru = 'Укажите папку.'; en = 'Please select a folder.'; pl = 'Określ folder.';de = 'Geben Sie den Ordner an.';ro = 'Specificați folderul.';tr = 'Klasörü belirleyin.'; es_ES = 'Especificar la carpeta.'"), , "FolderForAdding");
		Return;
	EndIf;
	
	SelectedFiles = New ValueList;
	SelectedFiles.Add(Directory);
	
	Handler = New NotifyDescription("ImportCompletion", ThisObject);
	
	ExecutionParameters = FilesOperationsInternalClient.FilesImportParameters();
	ExecutionParameters.ResultHandler          = Handler;
	ExecutionParameters.Owner                      = FolderForAdding;
	ExecutionParameters.SelectedFiles                = SelectedFiles; 
	ExecutionParameters.Comment                   = Details;
	ExecutionParameters.StoreVersions                 = StoreVersions;
	ExecutionParameters.DeleteFilesAfterAdd   = DeleteFilesAfterAdd;
	ExecutionParameters.Recursively                    = True;
	ExecutionParameters.FormID            = UUID;
	ExecutionParameters.Encoding                     = FileTextEncoding;
	ExecutionParameters.GroupOfFiles                  = GroupOfFiles;
	FilesOperationsInternalClient.ExecuteFilesImport(ExecutionParameters);
	
EndProcedure

&AtClient
Procedure ImportCompletion(Result, ExecutionParameters) Export
	If Result = Undefined Then
		Return;
	EndIf;
	
	Close();
	Notify("Write_FilesFolders", New Structure, Result.FolderForAddingCurrent);
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

#EndRegion
