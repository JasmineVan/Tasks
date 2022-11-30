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
		Raise NStr("ru = 'Справочник ""Предопределенные варианты отчетов"" изменяется только при автоматическом заполнении его данных.'; en = 'Predefined report options catalog is modified only during automatic population.'; pl = 'Katalog ""Predefiniowane opcje sprawozdania"" zmienia się tylko wtedy, gdy dane są wypełniane automatycznie.';de = 'Der Katalog ""Vordefinierte Berichtsoptionen"" wird nur geändert, wenn Daten automatisch ausgefüllt werden.';ro = 'Catalogul ""Opțiuni de rapoarte predefinite"" se modifică numai atunci când datele sunt completate automat.';tr = '""Önceden tanımlanmış rapor seçenekleri"" kataloğu, sadece veri otomatik olarak doldurulduğunda değiştirilir.'; es_ES = 'El catálogo de las ""Opciones del informe predefinido"" se ha cambiado solo cuando los datos están rellenados automáticamente.'");
	EndIf;
EndProcedure

// Basic checks of data of predefined report options. 
Procedure CheckPredefinedReportOptionFilling(Cancel)
	If DeletionMark Then
		Return;
	ElsIf Not ValueIsFilled(Report) Then
		Raise StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = 'Не заполнено поле ""%1""'; en = 'Field %1 is required.'; pl = 'Pole ""%1"" nie jest wypełnione';de = 'Das Feld ""%1"" ist nicht ausgefüllt';ro = 'Câmpul ""%1"" nu este completat';tr = '""%1"" alanı doldurulmadı.'; es_ES = 'El ""%1"" campo no está rellenado'"), "Report");
	Else
		Return;
	EndIf;
EndProcedure

#EndRegion

#Else
Raise NStr("ru = 'Недопустимый вызов объекта на клиенте.'; en = 'Invalid object call on the client.'; pl = 'Niedozwolone wezwanie obiektu na kliencie.';de = 'Unzulässiger Objektaufruf auf dem Client.';ro = 'Apel inadmisibil al obiectului pe client.';tr = 'İstemcide kabul edilmeyen nesne çağrısı.'; es_ES = 'Llamada no disponible del objeto en el cliente.'");
#EndIf