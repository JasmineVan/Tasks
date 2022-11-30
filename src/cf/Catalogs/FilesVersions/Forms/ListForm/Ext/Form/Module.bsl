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
	
	// Appearance of items marked for deletion.
	ConditionalAppearanceItem = List.ConditionalAppearance.Items.Add();
	
	AppearanceColorItem = ConditionalAppearanceItem.Appearance.Items.Find("TextColor");
	AppearanceColorItem.Value = Metadata.StyleItems.InaccessibleCellTextColor.Value;
	AppearanceColorItem.Use = True;
	
	DataFilterItem = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	DataFilterItem.LeftValue  = New DataCompositionField("DeletionMark");
	DataFilterItem.ComparisonType   = DataCompositionComparisonType.Equal;
	DataFilterItem.RightValue = True;
	DataFilterItem.Use  = True;
	
	If Common.IsMobileClient() Then
		Items.ListComment.Visible = False;
	EndIf;
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If EventName = "Write_File"
	   AND Parameter.Property("Event")
	   AND (    Parameter.Event = "EditFinished"
	      OR Parameter.Event = "VersionSaved") Then
		
		Items.List.Refresh();
	EndIf;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure ListChoice(Item, RowSelected, Field, StandardProcessing)
	
	StandardProcessing = False;
	FileData = FilesOperationsInternalServerCall.FileDataToOpen(FileOwner(RowSelected), RowSelected, UUID);
	FilesOperationsInternalClient.OpenFileVersion(Undefined, FileData, UUID);
	
EndProcedure

&AtClient
Procedure ListBeforeAddRow(Item, Cancel, Clone, Parent, Folder)
	
	Cancel = True;
	
EndProcedure

&AtClient
Procedure ListBeforeDelete(Item, Cancel)
	
	FileData = FilesOperationsInternalServerCall.FileData(Items.List.CurrentRow);
	If FileData.CurrentVersion = Items.List.CurrentRow Then
		ShowMessageBox(, NStr("ru = 'Активную версию нельзя удалить.'; en = 'Cannot delete the active version.'; pl = 'Nie można usunąć aktywnej wersji.';de = 'Aktive Version kann nicht gelöscht werden.';ro = 'Versiunea activă nu poate fi ștearsă.';tr = 'Aktif sürüm silinemez.'; es_ES = 'Versión del archivo no puede borrarse.'"));
		Cancel = True;
	EndIf;
	
EndProcedure

&AtClient
Procedure ListBeforeChangeRow(Item, Cancel)
	Cancel = True;
	OpenFileCard();
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure OpenFileCard()
	
	CurrentData = Items.List.CurrentData;
	If CurrentData <> Undefined Then 
		
		Version = CurrentData.Ref;
		
		FormOpenParameters = New Structure("Key", Version);
		OpenForm("DataProcessor.FilesOperations.Form.AttachedFileVersion", FormOpenParameters);
		
	EndIf;
	
EndProcedure

&AtServerNoContext
Function FileOwner(SelectedRow)
	Return SelectedRow.Owner;
EndFunction


#EndRegion