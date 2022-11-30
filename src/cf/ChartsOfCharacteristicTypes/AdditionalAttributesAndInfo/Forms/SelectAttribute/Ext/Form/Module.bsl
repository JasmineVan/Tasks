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
	
	AttributesTable = GetFromTempStorage(Parameters.ObjectAttributes);
	ValueToFormAttribute(AttributesTable, "ObjectAttributes");
EndProcedure

#EndRegion

#Region FormCommandHandlers

&AtClient
Procedure SelectCommand(Command)
	SelectItemAndClose();
EndProcedure

&AtClient
Procedure CancelCommand(Command)
	Close();
EndProcedure

&AtClient
Procedure ObjectAttributesChoice(Item, RowSelected, Field, StandardProcessing)
	SelectItemAndClose();
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure SelectItemAndClose()
	SelectedRow = Items.ObjectAttributes.CurrentData;
	ChoiceParameters = New Structure;
	ChoiceParameters.Insert("Attribute", SelectedRow.Attribute);
	ChoiceParameters.Insert("Presentation", SelectedRow.Presentation);
	ChoiceParameters.Insert("ValueType", SelectedRow.ValueType);
	ChoiceParameters.Insert("ChoiceMode", SelectedRow.ChoiceMode);
	
	Notify("Properties_ObjectAttributeSelection", ChoiceParameters);
	
	Close();
EndProcedure

#EndRegion