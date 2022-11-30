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
	
	CanAddFromClassifier = True;
	If Not AccessRight("Insert", Metadata.Catalogs.BusinessCalendars) Then
		CanAddFromClassifier = False;
	Else
		If Metadata.DataProcessors.Find("FillCalendarSchedules") = Undefined Then
			CanAddFromClassifier = False;
		EndIf;
	EndIf;
	
	Items.FormPickFromClassifier.Visible = CanAddFromClassifier;
	If Not CanAddFromClassifier Then
		CommonClientServer.SetFormItemProperty(Items, "CreateCalendar", "Title", NStr("ru = 'Создать'; en = 'Create'; pl = 'Utwórz';de = 'Erstellen';ro = 'Creare';tr = 'Oluştur'; es_ES = 'Crear'"));
		Items.Create.Type = FormGroupType.ButtonGroup;
	EndIf;
	
	CommonClientServer.SetFormItemProperty(Items, "CreateCalendar", "Representation", ButtonRepresentation.Text);
	
EndProcedure

&AtClient
Procedure ChoiceProcessing(SelectionResult, ChoiceSource)
	
	Items.List.Refresh();
	Items.List.CurrentRow = SelectionResult;
	
EndProcedure

#EndRegion

#Region FormCommandHandlers

&AtClient
Procedure PickFromClassifier(Command)
	
	PickingFormName = "DataProcessor.FillCalendarSchedules.Form.PickCalendarsFromClassifier";
	OpenForm(PickingFormName, , ThisObject);
	
EndProcedure

#EndRegion
