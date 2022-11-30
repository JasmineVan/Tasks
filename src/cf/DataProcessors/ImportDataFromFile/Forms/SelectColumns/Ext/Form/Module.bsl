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
	
	ColumnsList = Parameters.ColumnsList;
	ColumnsList.SortByPresentation();
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure ColumnsListSelection(Item, RowSelected, Field, StandardProcessing)
	ColumnsList.FindByID(RowSelected).Check = NOT ColumnsList.FindByID(RowSelected).Check;
EndProcedure

&AtClient
Procedure ColumnsListOnStartEdit(Item, NewRow, Clone)
	Row = ColumnsList.FindByID(Items.ColumnsList.CurrentRow);
	If StrStartsWith(Row.Value, "ContactInformation_") Then
		For Each ColumnInformation In ColumnsList Do
			If StrStartsWith(ColumnInformation.Value, "AdditionalAttribute_") Then
				ColumnInformation.Check = False;
			EndIf;
		EndDo;
	ElsIf StrStartsWith(Row.Value, "AdditionalAttribute_") Then
		For Each ColumnInformation In ColumnsList Do
			If StrStartsWith(ColumnInformation.Value, "ContactInformation_") Then
				ColumnInformation.Check = False;
			EndIf;
		EndDo;
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandHandlers

&AtClient
Procedure Choice(Command)
	Close(ColumnsList);
EndProcedure

#EndRegion
