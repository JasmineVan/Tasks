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
	
	FieldList = Parameters.FieldList;
	
EndProcedure

#EndRegion

#Region FormCommandHandlers

&AtClient
Procedure Apply(Command)
	
	Cancel = False;
	
	MarkedListItemArray = CommonClientServer.MarkedItems(FieldList);
	
	If MarkedListItemArray.Count() = 0 Then
		
		NString = NStr("ru = 'Следует указать хотя бы одно поле'; en = 'Select one or more fields'; pl = 'Trzeba wskazać chociażby jedno pole';de = 'Geben Sie mindestens ein Feld an';ro = 'Trebuie să indicați cel puțin un câmp';tr = 'En az bir alanı tanımlayın'; es_ES = 'Especificar como mínimo un campo'");
		
		CommonClient.MessageToUser(NString,,"FieldList",, Cancel);
		
	ElsIf MarkedListItemArray.Count() > MaxUserFields() Then
		
		// The value must not exceed the specified number.
		MessageString = NStr("ru = 'Уменьшите количество полей (можно выбирать не более [FieldsCount] полей)'; en = 'Reduce the number of fields (you can select no more than [FieldsCount] fields)'; pl = 'Zmniejszcie ilość pól (można wybierać nie więcej [FieldsCount] pól)';de = 'Reduzieren der Anzahl der Felder (Sie können nicht mehr als [FieldsCount] Felder auswählen)';ro = 'Reduceți numărul de câmpuri (puteți selecta nu mai mult de [FieldsCount] câmpuri)';tr = 'Alan sayısını azaltın (en fazla [FieldsCount] alan seçin)'; es_ES = 'Reducir el número de campos (se puede seleccionar no más de [FieldsCount] campos)'");
		MessageString = StrReplace(MessageString, "[FieldsCount]", String(MaxUserFields()));
		CommonClient.MessageToUser(MessageString,,"FieldList",, Cancel);
		
	EndIf;
	
	If Not Cancel Then
		
		NotifyChoice(FieldList.Copy());
		
	EndIf;
	
EndProcedure

&AtClient
Procedure Cancel(Command)
	
	NotifyChoice(Undefined);
	
EndProcedure

#EndRegion

#Region Private

&AtClient
Function MaxUserFields()
	
	Return DataExchangeClient.MaxCountOfObjectsMappingFields();
	
EndFunction

#EndRegion
