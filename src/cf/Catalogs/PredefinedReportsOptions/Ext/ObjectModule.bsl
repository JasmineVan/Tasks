///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure BeforeWrite(Cancel)
	If AdditionalProperties.Property("PredefinedObjectsFilling") Then
		CheckPredefinedReportOptionFilling(Cancel);
	EndIf;
	If DataExchange.Load Then
		Return;
	EndIf;
	If Not AdditionalProperties.Property("PredefinedObjectsFilling") Then
		Raise NStr("ru = 'Запись в справочник ""Предопределенные варианты отчетов"" запрещена. Его данные заполняются автоматически.'; en = 'Cannot write to ""Predefined report options"" catalog. It is populated automatically.'; pl = 'Zapisywanie do katalogu ""Предопределенные варианты отчетов"" jest zabroniona. Jego dane są wypełniane automatycznie.';de = 'Der Eintrag in das Verzeichnis ""Vordefinierte Varianten von Berichten"" ist verboten. Seine Daten werden automatisch ausgefüllt.';ro = 'Înregistrarea în clasificatorul ""Variante predefinite ale rapoartelor"" este interzisă. Datele lui se completează automat.';tr = '""Önceden tanımlanmış rapor seçenekleri"" dizinine yazma yasaktır. Verileri otomatik olarak doldurulur.'; es_ES = 'Está prohibido guardar en el catálogo ""Variantes de informes predeterminadas"". Sus datos se rellenan automáticamente.'");
	EndIf;
EndProcedure

// Basic checks of data of predefined report options. 
Procedure CheckPredefinedReportOptionFilling(Cancel)
	
	If DeletionMark Then
		Return;
	EndIf;
	If ValueIsFilled(Report) Then
		Return;
	EndIf;
		
	Raise NStr("ru = 'Не заполнено поле ""Отчет""'; en = 'Report field is required.'; pl = 'Nie wypełniono pola ""Отчет""';de = 'Das Feld ""Bericht"" ist nicht ausgefüllt';ro = 'Câmpul ""Raport"" nu este completat';tr = '""Rapor"" alanı doldurulmadı'; es_ES = 'El campo ""Informe"" no rellenado'");
	
EndProcedure

#EndRegion

#Else
Raise NStr("ru = 'Недопустимый вызов объекта на клиенте.'; en = 'Invalid object call on the client.'; pl = 'Niedozwolone wezwanie obiektu na kliencie.';de = 'Unzulässiger Objektaufruf auf dem Client.';ro = 'Apel inadmisibil al obiectului pe client.';tr = 'İstemcide kabul edilmeyen nesne çağrısı.'; es_ES = 'Llamada no disponible del objeto en el cliente.'");
#EndIf