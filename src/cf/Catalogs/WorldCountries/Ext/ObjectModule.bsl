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
	If DataExchange.Load Or AdditionalProperties.Property("DoNotCheckUniqueness") Then
		Return;
	EndIf;
	
	If Not CheckFilling() Then
		Cancel = True;
	EndIf;
EndProcedure

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	Existing = ExistingItem();
	If Existing<>Undefined Then
		Cancel = True;
		Common.MessageToUser(Existing.ErrorDescription,, "Object.Description");
	EndIf;
	
EndProcedure

Procedure Filling(FillingData, FillingText, StandardProcessing)
	If FillingData<>Undefined Then
		FillPropertyValues(ThisObject, FillingData);
	EndIf;
EndProcedure

#EndRegion

#Region Private

// Controls item uniqueness in the infobase.
//
//  Returns:
//      Undefined - no errors.
//      Structure - infobase item details. Properties:
//          * ErrorDescription     - String - an error text.
//          * Code                - String - an attribute of an existing item.
//          * Description       - String - an attribute of an existing item.
//          * FullDescription - String - an attribute of an existing item.
//          * CodeAlpha2          - String - an attribute of an existing item.
//          * CodeAlpha3          - String - an attribute of an existing item.
//          * Reference             - CatalogRef.WorldCountries - an attribute of an existing item.
//
Function ExistingItem()
	
	Result = Undefined;
	
	// Skip non-numerical codes
	NumberType = New TypeDescription("Number", New NumberQualifiers(3, 0, AllowedSign.Nonnegative));
	If Code="0" Or Code="00" Or Code="000" Then
		SearchCode = "000";
	Else
		SearchCode = Format(NumberType.AdjustValue(Code), "ND=3; NFD=2; NZ=; NLZ=");
		If SearchCode="000" Then
			Return Result; // Not a number
		EndIf;
	EndIf;
		
	Query = New Query("
		|SELECT TOP 1
		|	Code                AS Code,
		|	Description       AS Description,
		|	DescriptionFull AS DescriptionFull,
		|	CodeAlpha2          AS CodeAlpha2,
		|	CodeAlpha3          AS CodeAlpha3,
		|	EEUMember       AS EEUMember,
		|	Ref             AS Ref
		|FROM
		|	Catalog.WorldCountries
		|WHERE
		|	Code=&Code 
		|	AND Ref <> &Ref
		|");
	Query.SetParameter("Ref", Ref);
	Query.SetParameter("Code",    SearchCode);
	
	QueryResult = Query.Execute();
	Selection = QueryResult.Select();
	If Selection.Next() Then
		Result = New Structure("ErrorDescription", 
			StringFunctionsClientServer.SubstituteParametersToString(NStr("ru='С кодом %1 уже существует страна %2. Измените код или используйте уже существующие данные.'; en = 'Code %1 already assigned to country %2. Change the code, or use the existing data.'; pl = 'Kod %1jest już przypisany do kraju %2. Wprowadź inny kod lub użyj istniejących danych.';de = 'Der Code %1 ist bereits dem Land zugewiesen%2. Geben Sie einen anderen Code ein oder verwenden Sie die vorhandenen Daten.';ro = 'Codul %1 este deja atribuit țării %2. Introduceți alt cod sau utilizați datele existente.';tr = 'Kod%1 zaten ülkeye atandı. %2Başka bir kod girin veya mevcut verileri kullanın.'; es_ES = 'Código %1 ya está asignado al país %2. Introducir otro código, o utilizar los datos existentes.'"),
			Code, Selection.Description));
		
		For Each Field In QueryResult.Columns Do
			Result.Insert(Field.Name, Selection[Field.Name]);
		EndDo;
	EndIf;
	
	Return Result;
EndFunction

#EndRegion

#Else
Raise NStr("ru = 'Недопустимый вызов объекта на клиенте.'; en = 'Invalid object call on the client.'; pl = 'Niedozwolone wezwanie obiektu na kliencie.';de = 'Unzulässiger Objektaufruf auf dem Client.';ro = 'Apel inadmisibil al obiectului pe client.';tr = 'İstemcide kabul edilmeyen nesne çağrısı.'; es_ES = 'Llamada no disponible del objeto en el cliente.'");
#EndIf