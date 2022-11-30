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
	
	MessageQuestion = Parameters.MessageQuestion;
	MessageTitle = Parameters.MessageTitle;
	Title = Parameters.Title;
	Files = Parameters.Files;
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersFiles

&AtClient
Procedure FilesChoice(Item, RowSelected, Field, StandardProcessing)
	
	StandardProcessing = False;
	FileRef = Files[RowSelected].Value;
	
	PersonalSettings = FilesOperationsInternalClient.PersonalFilesOperationsSettings();
	HowToOpen = PersonalSettings.ActionOnDoubleClick;
	If HowToOpen = "OpenCard" Then
		FormParameters = New Structure;
		FormParameters.Insert("Key", FileRef);
		OpenForm("Catalog.Files.ObjectForm", FormParameters, ThisObject);
		Return;
	EndIf;
	
	FileData = FilesOperationsInternalServerCall.FileDataToOpen(FileRef, Undefined,UUID);
	FilesOperationsInternalClient.OpenFileWithNotification(Undefined, FileData);
	
EndProcedure

#EndRegion
