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
	
	FillObjectsTypesList();
	
	If Not IsBlankString(Parameters.SelectedTypes) Then
		SelectedTypes = StrSplit(Parameters.SelectedTypes, ",", True);
		For Each SelectedType In SelectedTypes Do
			TypeFound = EditableObjects.FindByValue(SelectedType);
			If TypeFound <> Undefined Then
				EditableObjects.FindByValue(SelectedType).Check = True;
				Items.EditableObjects.CurrentRow = TypeFound.GetID();
			EndIf;
		EndDo;
	EndIf;
	
EndProcedure

#EndRegion

#Region EventHandlersOfSpreadsheetElementsFormsEditableObjects

&AtClient
Procedure EditableObjectsOnChanging(Item)
	UpdateSelectedCount();
EndProcedure

#EndRegion

#Region FormCommandHandlers

&AtClient
Procedure Select(Command)
	SelectObjectsAndCloseForm();
EndProcedure

&AtClient
Procedure EditableObjectsChoice(Item, RowSelected, Field, StandardProcessing)
	SelectObjectsAndCloseForm();
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure FillObjectsTypesList()
	DataProcessorObject = FormAttributeToValue("Object");
	DataProcessorObject.FillEditableObjectsCollection(EditableObjects, Parameters.ShowHiddenItems);
EndProcedure

&AtServerNoContext
Function SubordinateSubsystemsNames(ParentSubsystem)
	
	Names = New Map;
	
	For Each CurrentSubsystem In ParentSubsystem.Subsystems Do
		
		Names.Insert(CurrentSubsystem.Name, True);
		SubordinateItemNames = SubordinateSubsystemsNames(CurrentSubsystem);
		
		For each SubordinateItemName In SubordinateItemNames Do
			Names.Insert(CurrentSubsystem.Name + "." + SubordinateItemName.Key, True);
		EndDo;
	EndDo;
	
	Return Names;
	
EndFunction

&AtClient
Function SelectedItems()
	Result = New Array;
	For Each Item In EditableObjects Do
		If Item.Check Then
			Result.Add(Item.Value);
		EndIf;
	EndDo;
	Return Result;
EndFunction

&AtClient
Procedure SelectObjectsAndCloseForm()
	SelectedItems = SelectedItems();
	If SelectedItems.Count() = 0 Then
		SelectedItems.Add(Items.EditableObjects.CurrentData.Value);
	EndIf;
	Close(SelectedItems);
EndProcedure

&AtClient
Procedure UpdateSelectedCount()
	SelectButtonText = NStr("ru = 'Выбрать'; en = 'Select'; pl = 'Wybór';de = 'Auswählen';ro = 'Selectare';tr = 'Seç'; es_ES = 'Seleccionar'");
	SelectedCount = SelectedItems().Count();
	If SelectedCount > 0 Then
		SelectButtonText = SelectButtonText + " (" + SelectedCount + ")";
	EndIf;
	Items.FormSelect.Title = SelectButtonText;
EndProcedure

#EndRegion
