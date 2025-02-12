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
	
	// Filling in the format list.
	For Each SaveFormat In PrintManagement.SpreadsheetDocumentSaveFormatsSettings() Do
		SelectedSaveFormats.Add(String(SaveFormat.SpreadsheetDocumentFileType), String(SaveFormat.Ref), False, SaveFormat.Picture);
	EndDo;
	SelectedSaveFormats[0].Check = True; // By default, only the first format from the list is selected.
	
	// Filling the selection list for attaching files to an object.
	For Each PrintObject In Parameters.PrintObjects Do
		If CanAttachFilesToObject(PrintObject.Value) Then
			Items.SelectedObject.ChoiceList.Add(PrintObject.Value);
		EndIf;
	EndDo;
	
	// Default save location.
	SavingOption = "SaveToFolder";
	
	// Visibility setting
	IsWebClient = Common.IsWebClient();
	HasOpportunityToAttach = Items.SelectedObject.ChoiceList.Count() > 0;
	Items.SelectFileSaveLocation.Visible = Not IsWebClient Or HasOpportunityToAttach;
	Items.SavingOption.Visible = HasOpportunityToAttach;
	If Not HasOpportunityToAttach Then
		Items.FolderToSaveFiles.TitleLocation = FormItemTitleLocation.Top;
	EndIf;
	Items.FolderToSaveFiles.Visible = Not IsWebClient;
	
	// The default object for attaching files.
	If HasOpportunityToAttach Then
		SelectedObject = Items.SelectedObject.ChoiceList[0].Value;
	EndIf;
	Items.SelectedObject.ReadOnly = Items.SelectedObject.ChoiceList.Count() = 1;
	
	If Common.IsMobileClient() Then
		CommandBarLocation = FormCommandBarLabelLocation.Auto;
		Items.SaveButton.Representation = ButtonRepresentation.Picture;
	EndIf;
	
EndProcedure

&AtServer
Procedure BeforeLoadDataFromSettingsAtServer(Settings)
	
	SaveFormatsFromSettings = Settings["SelectedSaveFormats"];
	If SaveFormatsFromSettings <> Undefined Then
		For Each SelectedFormat In SelectedSaveFormats Do 
			FormatFromSettings = SaveFormatsFromSettings.FindByValue(SelectedFormat.Value);
			If FormatFromSettings <> Undefined Then
				SelectedFormat.Check = FormatFromSettings.Check;
			EndIf;
		EndDo;
		Settings.Delete("SelectedSaveFormats");
	EndIf;
	
	If Items.SelectedObject.ChoiceList.Count() = 0 Then
		SaveOptionSetting = Settings["SavingOption"];
		If SaveOptionSetting <> Undefined Then
			Settings.Delete("SavingOption");
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	SetSaveLocationPage();
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure SaveOptionOnChange(Item)
	SetSaveLocationPage();
	ClearMessages();
EndProcedure

&AtClient
Procedure FolderToSaveFilesStartChoice(Item, ChoiceData, StandardProcessing)
	
	FileSystemClient.SelectDirectory(New NotifyDescription("FolderToSaveFilesSelectionCompletion", ThisObject));
	
EndProcedure

// Handler of saved files directory selection completion.
//  See FileDialog.Show() in the Syntax Assistant. 
//
&AtClient
Procedure FolderToSaveFilesSelectionCompletion(Folder, AdditionalParameters) Export 
	If Not IsBlankString(Folder) Then 
		SelectedFolder = Folder;
		ClearMessages();
	EndIf;
EndProcedure

&AtClient
Procedure SelectedObjectCleanup(Item, StandardProcessing)
	StandardProcessing = False;
EndProcedure

#EndRegion

#Region FormCommandHandlers

&AtClient
Procedure Save(Command)
	
	#If Not WebClient Then
	If SavingOption = "SaveToFolder" AND IsBlankString(SelectedFolder) Then
		CommonClient.MessageToUser(NStr("ru = 'Необходимо указать папку.'; en = 'Specify a folder.'; pl = 'Określ folder.';de = 'Geben Sie den Ordner an.';ro = 'Specificați folderul.';tr = 'Klasörü belirleyin.'; es_ES = 'Especificar la carpeta.'"),,"SelectedFolder");
		Return;
	EndIf;
	#EndIf
		
	SaveFormats = New Array;
	
	For Each SelectedFormat In SelectedSaveFormats Do
		If SelectedFormat.Check Then
			SaveFormats.Add(SelectedFormat.Value);
		EndIf;
	EndDo;
	
	If SaveFormats.Count() = 0 Then
		ShowMessageBox(,NStr("ru = 'Необходимо указать как минимум один из предложенных форматов.'; en = 'Specify at least one of the suggested formats.'; pl = 'Wybierz co najmniej jeden z podanych formatów.';de = 'Geben Sie mindestens eines der angegebenen Formate an.';ro = 'Specificați cel puțin unul dintre formatele propuse.';tr = 'Verilen formatların en az birini belirleyin.'; es_ES = 'Especificar como mínimo uno de los formatos dados.'"));
		Return;
	EndIf;
	
	SelectionResult = New Structure;
	SelectionResult.Insert("PackToArchive", PackToArchive);
	SelectionResult.Insert("SaveFormats", SaveFormats);
	SelectionResult.Insert("SavingOption", SavingOption);
	SelectionResult.Insert("FolderForSaving", SelectedFolder);
	SelectionResult.Insert("ObjectForAttaching", SelectedObject);
	SelectionResult.Insert("TransliterateFilesNames", TransliterateFilesNames);

	NotifyChoice(SelectionResult);
	
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure SetSaveLocationPage()
	
	#If WebClient Then
	Items.SelectedObject.Enabled = SavingOption = "Join";
	#Else
	If SavingOption = "Join" Then
		Items.SaveLocationsGroup.CurrentPage = Items.AttachToObjectPage;
	Else
		Items.SaveLocationsGroup.CurrentPage = Items.SaveToFolderPage;
	EndIf;
	#EndIf
	
EndProcedure

&AtServer
Function CanAttachFilesToObject(ObjectRef)
	CanAttach = Undefined;
	
	If Common.SubsystemExists("StandardSubsystems.FilesOperations") Then
		ModuleFilesOperations = Common.CommonModule("AttachedFiles");
		CanAttach = ModuleFilesOperations.CanAttachFilesToObject(ObjectRef);
	EndIf;
	
	If CanAttach = Undefined Then
		CanAttach = False;
	EndIf;
	
	Return CanAttach;
EndFunction

#EndRegion
