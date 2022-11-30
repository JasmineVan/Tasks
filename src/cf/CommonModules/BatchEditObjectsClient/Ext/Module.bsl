///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This software and its documentation are distributed under the terms of 
// Attribution 4.0 International license (CC BY 4.0).
// You can view license text at
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Public

// Opens a dialog for batch editing of attributes for objects selected in a list.
//
// Parameters:
//  ListItem  - FormTable       - a form item that contains the list.
//  ListAttribute - DynamicList - a form attribute that contains the list.
//
Procedure ChangeSelectedItems(ListItem, Val ListAttribute = Undefined) Export
	
	If ListAttribute = Undefined Then
		Form = ListItem.Parent;
		While TypeOf(Form) <> Type("ManagedForm") Do
			Form = Form.Parent;
		EndDo;
		
		Try
			ListAttribute = Form.List;
		Except
			ListAttribute = Undefined;
		EndTry;
	EndIf;
	
	SelectedRows = ListItem.SelectedRows;
	
	FormParameters = New Structure("ObjectsArray", New Array);
	If TypeOf(ListAttribute) = Type("DynamicList") Then
		FormParameters.Insert("SettingsComposer", ListAttribute.SettingsComposer);
	EndIf;
	
	For Each SelectedRow In SelectedRows Do
		If TypeOf(SelectedRow) = Type("DynamicalListGroupRow") Then
			Continue;
		EndIf;
		
		CurrentRow = ListItem.RowData(SelectedRow);
		If CurrentRow <> Undefined Then
			FormParameters.ObjectsArray.Add(CurrentRow.Ref);
		EndIf;
	EndDo;
	
	If FormParameters.ObjectsArray.Count() = 0 Then
		ShowMessageBox(, NStr("ru = 'Команда не может быть выполнена для указанного объекта.'; en = 'Cannot run the command for the object.'; pl = 'Polecenie nie może być wykonane dla określonego obiektu.';de = 'Der Befehl kann für das angegebene Objekt nicht ausgeführt werden.';ro = 'Comanda nu poate fi executată pentru obiectul indicat.';tr = 'Belirtilen nesne için komut çalıştırılamaz.'; es_ES = 'No se puede ejecutar el comando para el objeto especificado.'"));
		Return;
	EndIf;
		
	OpenForm("DataProcessor.BatchEditAttributes.Form", FormParameters);
	
EndProcedure

#EndRegion
