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
	
	If Not Parameters.Property("ArrayOfValues") Then // Return if there are no attributes with the date type.
		Return;
	EndIf;
	
	HasOnlyOneAttribute = Parameters.ArrayOfValues.Count() = 1;
	
	For Each Attribute In Parameters.ArrayOfValues Do
		Items.DateTypeAttribute.ChoiceList.Add(Attribute.Value, Attribute.Presentation);
		If HasOnlyOneAttribute Then
			DateTypeAttribute = Attribute.Value;
		EndIf;
	EndDo;
	
	If Common.IsMobileClient() Then
		Items.IntervalException.TitleLocation = FormItemTitleLocation.Top;
		Items.DateTypeAttribute.TitleLocation = FormItemTitleLocation.Top;
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandHandlers

&AtClient
Procedure OK(Command)
	
	If IntervalException = 0 Then
		CommonClient.MessageToUser(NStr("ru='Количество дней не может быть равно 0.'; en = 'Please specify a nonzero number of days.'; pl = 'Ilość dni nie może wynosić 0.';de = 'Die Anzahl der Tage darf nicht gleich 0 sein.';ro = 'Numărul de zile nu poate fi egal cu 0.';tr = 'Gün sayısı 0 olamaz.'; es_ES = 'La cantidad de días no puede ser igual a 0.'"),,, "IntervalException");
		Return;
	EndIf;
	
	If Not ValueIsFilled(DateTypeAttribute) Then
		CommonClient.MessageToUser(NStr("ru='Необходимо заполнить условия очистки файлов.'; en = 'Please fill in the cleanup conditions.'; pl = 'Konieczne jest wypełnienie warunków czyszczenia plików.';de = 'Es ist notwendig, die Bedingungen für die Reinigung der Dateien auszufüllen.';ro = 'Trebuie să completați condițiile de golire a fișierelor.';tr = 'Dosyaları temizleme şartları doldurulmalıdır.'; es_ES = 'Es necesario rellenar las condiciones de vaciar los archivos.'"),,, "DateTypeAttribute");
		Return;
	EndIf;
	
	ResultingStructure = New Structure();
	ResultingStructure.Insert("IntervalException", IntervalException);
	ResultingStructure.Insert("DateTypeAttribute", DateTypeAttribute);
	
	NotifyChoice(ResultingStructure);

EndProcedure

#EndRegion