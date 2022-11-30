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
	
	For Each FileRef In Parameters.FilesArray Do
		NewItem = SelectedFiles.Add();
		NewItem.Ref = FileRef;
		NewItem.PictureIndex = FileRef.PictureIndex;
	EndDo;
	
	CanCreateFileVersions = Parameters.CanCreateFileVersions;
	BeingEditedBy = Parameters.BeingEditedBy;
	
	Items.StoreVersions.Visible = CanCreateFileVersions;
	
	PersonalFilesOperationsSettings = FilesOperations.FilesOperationSettings();
	Items.DeleteFilesFromMainDirectory.Visible = PersonalFilesOperationsSettings.ConfirmOnDeleteFilesFromLocalCache;
	DeleteFilesFromMainDirectory = PersonalFilesOperationsSettings.DeleteFileFromLocalFileCacheOnCompleteEdit;
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	StoreVersions = True;
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
Procedure EndEdit()
	
	FilesArray = New Array;
	For Each ListItem In SelectedFiles Do
		FilesArray.Add(ListItem.Ref);
	EndDo;
	
	FilesUpdateParameters = New Structure;
	FilesUpdateParameters.Insert("FilesArray",                     FilesArray);
	FilesUpdateParameters.Insert("CanCreateFileVersions", CanCreateFileVersions);
	FilesUpdateParameters.Insert("StoreVersions", StoreVersions);
	If Not CanCreateFileVersions Then
		FilesUpdateParameters.Insert("CreateNewVersion", False);
	EndIf;
	FilesUpdateParameters.Insert("CurrentUserEditsFile", True);
	FilesUpdateParameters.Insert("ResultHandler",               Undefined);
	FilesUpdateParameters.Insert("FormID",                 UUID);
	FilesUpdateParameters.Insert("BeingEditedBy",                        BeingEditedBy);
	FilesUpdateParameters.Insert("VersionComment",                 Comment);
	FilesUpdateParameters.Insert("ShowNotification",               False);
	FilesUpdateParameters.Insert("DeleteFileFromLocalFileCacheOnCompleteEdit2", DeleteFilesFromMainDirectory);
	
	FilesOperationsInternalClient.FinishEditByRefsWithNotification(FilesUpdateParameters);
	Close();
EndProcedure

#EndRegion