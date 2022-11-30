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
	If NOT PerformanceMonitorInternal.SubsystemExists("StandardSubsystems.Core") Then
		ThisObject.Items.ImportFile.ChoiceButton = False;
		SSLAvailable = False;
	Else
		SSLAvailable = True;
	EndIf;
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure SelectFileToImportSuggested(FileSystemExtensionAttached, AdditionalParameters) Export
	
	If FileSystemExtensionAttached Then
		
		SelectFile = New FileDialog(FileDialogMode.Open);
		SelectFile.Multiselect = False;
		SelectFile.Title = NStr("ru = 'Выберите файл импорта замеров'; en = 'Select measurement import file'; pl = 'Select measurement import file';de = 'Select measurement import file';ro = 'Select measurement import file';tr = 'Select measurement import file'; es_ES = 'Select measurement import file'");
		SelectFile.Filter = "Files import measurements (*.zip)|*.zip";
		
		NotifyDescription = New NotifyDescription("EndSelectFileDialog", ThisObject, Undefined);
		FileSystemClient.ShowSelectionDialog(NotifyDescription, SelectFile);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure FileToImportStartChoice(Item, ChoiceData, StandardProcessing)
	
	If SSLAvailable Then
		NotifyDescription = New NotifyDescription("SelectFileToImportSuggested", ThisObject, Undefined);
		ModuleFileSystemClient = Eval("FileSystemClient");
		If TypeOf(ModuleFileSystemClient) = Type("CommonModule") Then
			ModuleFileSystemClient.AttachFileOperationsExtension(NotifyDescription);
		EndIf;
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandHandlers

&AtClient
Procedure Import(Command)
	File = New File(ImportFile);
	File.BeginCheckingExistence(New NotifyDescription("ImportAfterExistenceCheck", ThisObject));
EndProcedure

&AtClient
Procedure ImportAfterExistenceCheck(Exists, AdditionalParameters) Export
	If Not Exists Then 
		Message = New UserMessage();
    	Message.Text = NStr("ru = 'Выберите файл для импорта.'; en = 'Select file to import.'; pl = 'Select file to import.';de = 'Select file to import.';ro = 'Select file to import.';tr = 'Select file to import.'; es_ES = 'Select file to import.'");
    	Message.Field = "ImportFile";
    	Message.Message();
		Return;
	EndIf;
	BinaryData = New BinaryData(ImportFile);
    StorageAddress = PutToTempStorage(BinaryData, ThisObject.UUID);
    ExecuteImportAtServer(ImportFile, StorageAddress);	
EndProcedure

#EndRegion

#Region Private

&AtServerNoContext
Procedure ExecuteImportAtServer(FileName, StorageAddress)
	PerformanceMonitor.LoadPerformanceMonitorFile(FileName, StorageAddress);
EndProcedure                                                                     

&AtClient
Procedure EndSelectFileDialog(SelectedFiles, AdditionalParameters) Export
    
    If SelectedFiles <> Undefined Then
		ImportFile = SelectedFiles[0];
	EndIf;
		
EndProcedure

#EndRegion