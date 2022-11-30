///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

#Region ForCallsFromOtherSubsystems

// StandardSubsystems.BatchObjectsModification

// Returns the object attributes that are not recommended to be edited using batch attribute 
// modification data processor.
//
// Returns:
//  Array - a list of object attribute names.
Function AttributesToSkipInBatchProcessing() Export
	
	Result = New Array;
	Result.Add("*");
	Return Result;
	
EndFunction

// End StandardSubsystems.BatchObjectsModification

#EndRegion

#EndRegion

#Region EventHandlers

Procedure ChoiceDataGetProcessing(ChoiceData, Parameters, StandardProcessing)
	
	If Not StandardProcessing Then
		// Processed elsewhere.
		Return;
		
	ElsIf Not Parameters.Property("AllowClassifierData") Then
		// Default behavior, catalog picking only.
		Return;
		
	ElsIf True <> Parameters.AllowClassifierData Then
		// Picking from classifier is disabled. It is the default behavior.
		Return;
	EndIf;
	
	ContactsManagerInternal.ChoiceDataGetProcessing(ChoiceData, Parameters, StandardProcessing)
	
EndProcedure

#EndRegion

#Region Internal

// Gets country data from the countries catalog or from the country classifier.
// Use ContactsManager.WorldCountryData instead.
//
// Parameters:
//    CountryCode - String, Number - an ARCC country code. If not specified, search by code is not performed.
//    Description - String        - a country description. If not specified, search by description is not performed.
//
// Returns:
//    Structure - the following fields:
//          * Code                - String - an attribute of the found country.
//          * Description       - String - an attribute of the found country.
//          * DescriptionFull - String - an attribute of the found country.
//          * CodeAlpha2          - String - an attribute of the found country.
//          * CodeAlpha3          - String - an attribute of the found country.
//          * Reference             - CatalogRef.WorldCountries - an attribute of the found country.
//    Undefined - the country is not found.
//
Function WorldCountryData(Val CountryCode = Undefined, Val Description = Undefined) Export
	Return ContactsManager.WorldCountryData(CountryCode, Description);
EndFunction

// Gets country data from the country classifier.
// It is recommended that you use ContactsManager.WorldCountryClassifierDataByCodee instead.
//
// Parameters:
//    Code - String, Number - an ARCC country code.
//    CodeType - String - options: CountryCode (by default), Alpha2, and Alpha3.
//
// Returns:
//    Structure - the following fields:
//          * Code                - String - an attribute of the found country.
//          * Description       - String - an attribute of the found country.
//          * DescriptionFull - String - an attribute of the found country.
//          * CodeAlpha2          - String - an attribute of the found country.
//          * CodeAlpha3          - String - an attribute of the found country.
//    Undefined - the country is not found.
//
Function WorldCountryClassifierDataByCode(Val Code, CodeType = "CountryCode") Export
	Return ContactsManager.WorldCountryClassifierDataByCode(Code, CodeType);
EndFunction

// Gets country data from the country classifier.
// It is recommended that you use ContactsManager.WorldCountryClassifierDataByDescription instead.
//
// Parameters:
//    Description - String - a country description.
//
// Returns:
//    Structure - the following fields:
//          * Code                - String - an attribute of the found country.
//          * Description       - String - an attribute of the found country.
//          * DescriptionFull - String - an attribute of the found country.
//          * CodeAlpha2          - String - an attribute of the found country.
//          * CodeAlpha3          - String - an attribute of the found country.
//    Undefined - the country is not found.
//
Function WorldCountryClassifierDataByDescription(Val Description) Export
	Return ContactsManager.WorldCountryClassifierDataByDescription(Description);
EndFunction

#EndRegion

#Region Private

#Region InfobaseUpdate

// Registers countries for processing.
//
Procedure FillCountriesListToProcess(Parameters) Export
	
	ARCCValues = ContactsManager.EEUMemberCountries();
	
	NewRow                    = ARCCValues.Add();
	NewRow.Code                = "203";
	NewRow.Description       = NStr("ru='ЧЕШСКАЯ РЕСПУБЛИКА'; en = 'CZECH REPUBLIC'; pl = 'REPUBLIKA CZESKA';de = 'TSCHECHISCHE REPUBLIK';ro = 'REPUBLICA CEHĂ';tr = 'ÇEK CUMHURİYETİ'; es_ES = 'REPÚBLICA CHECA'");
	NewRow.CodeAlpha2          = "CZ";
	NewRow.CodeAlpha3          = "CZE";
	
	NewRow                    = ARCCValues.Add();
	NewRow.Code                = "270";
	NewRow.Description       = NStr("ru='ГАМБИЯ'; en = 'GAMBIA'; pl = 'GAMBIA';de = 'GAMBIA';ro = 'GAMBIA';tr = 'GAMBİYA'; es_ES = 'GAMBIA'");
	NewRow.CodeAlpha2          = "GM";
	NewRow.CodeAlpha3          = "GMB";
	NewRow.DescriptionFull = NStr("ru='Республика Гамбия'; en = 'Republic of the Gambia'; pl = 'Republika Gambia';de = 'Republik Gambia';ro = 'Republica Gambia';tr = 'Gambiya Cumhuriyeti'; es_ES = 'República de Gambia'");
	
	Query = New Query;
	Query.Text = "SELECT
		|	CountryList.Code AS Code,
		|	CountryList.Description AS Description,
		|	CountryList.CodeAlpha2 AS CodeAlpha2,
		|	CountryList.CodeAlpha3 AS CodeAlpha3,
		|	CountryList.DescriptionFull AS DescriptionFull
		|INTO CountryList
		|FROM
		|	&CountryList AS CountryList
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	WorldCountries.Ref AS Ref
		|FROM
		|	CountryList AS CountryList
		|		INNER JOIN Catalog.WorldCountries AS WorldCountries
		|		ON (WorldCountries.Code = CountryList.Code)
		|			AND (WorldCountries.Description = CountryList.Description)
		|			AND (WorldCountries.CodeAlpha2 = CountryList.CodeAlpha2)
		|			AND (WorldCountries.CodeAlpha3 = CountryList.CodeAlpha3)
		|			AND (WorldCountries.DescriptionFull = CountryList.DescriptionFull)";
	
	Query.SetParameter("CountryList", ARCCValues);
	QueryResult = Query.Execute().Unload();
	CountriesToProcess = QueryResult.UnloadColumn("Ref");
	
	InfobaseUpdate.MarkForProcessing(Parameters, CountriesToProcess);
	
EndProcedure

Procedure UpdateWorldCountriesByCountryClassifier(Parameters) Export
	
	WorldCountryRef = InfobaseUpdate.SelectRefsToProcess(Parameters.Queue, "Catalog.WorldCountries");
	
	ObjectsWithIssuesCount = 0;
	ObjectsProcessed = 0;
	
	While WorldCountryRef.Next() Do
		Try
			
			ARCCData = ContactsManager.WorldCountryClassifierDataByCode(WorldCountryRef.Ref.Code);
			
			If ARCCData <> Undefined Then
				WorldCountry = WorldCountryRef.Ref.GetObject();
				FillPropertyValues(WorldCountry, ARCCData);
				InfobaseUpdate.WriteData(WorldCountry);
			EndIf;
			
			ObjectsProcessed = ObjectsProcessed + 1;
			
		Except
			// If cannot process a country, try again.
			ObjectsWithIssuesCount = ObjectsWithIssuesCount + 1;
			
			MessageText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'Не удалось обработать страну: %1 по причине: %2'; en = 'Cannot process country: %1. Reason: %2'; pl = 'Nie udało się przetworzyć kraju: %1 z powodu: %2';de = 'Das Land konnte nicht bearbeitet werden: %1 aus folgendem Grund: %2';ro = 'Eșec la procesarea țării: %1 din motivul: %2';tr = 'Ülke işlenemedi: %1 nedeni: %2'; es_ES = 'No se ha podido procesar el país %1 debido a: %2'"),
					WorldCountryRef.Ref, DetailErrorDescription(ErrorInfo()));
			WriteLogEvent(InfobaseUpdate.EventLogEvent(), EventLogLevel.Warning,
				Metadata.Catalogs.WorldCountries, WorldCountryRef.Ref, MessageText);
		EndTry;
	EndDo;
	
	Parameters.ProcessingCompleted = InfobaseUpdate.DataProcessingCompleted(Parameters.Queue, "Catalog.WorldCountries");
	
	If ObjectsProcessed = 0 AND ObjectsWithIssuesCount <> 0 Then
		MessageText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Процедуре ОбновитьСтраныМираПоОКСМ не удалось обработать некоторые страны мира(пропущены): %1'; en = 'The UpdateCountriesByClassifier procedure failed to process and skipped %1 countries.'; pl = 'Procedurze ZaktualizujPaństwaŚwiataWgOKSM nie udało się przetworzyć niektórych państw świata (pominięte): %1';de = 'Das Verfahren AktualisierungDerLänderDerWeltNachOKCM konnte für einige Länder der Welt nicht durchgeführt werden (weggelassen): %1';ro = 'Procedura ОбновитьСтраныМираПоОКСМ nu a putut procesa unele țări ale lumii (omise): %1';tr = 'UpdateCountriesByClassifier işlemi bazı ülkeleri işleyemedi (atlattı): %1'; es_ES = 'El procedimiento UpdateCountriesByClassifier no ha podido procesar algunos países del mundo(saltados): %1'"), 
				ObjectsWithIssuesCount);
		Raise MessageText;
	Else
		WriteLogEvent(InfobaseUpdate.EventLogEvent(), EventLogLevel.Information,
			Metadata.Catalogs.WorldCountries,,
				StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = 'Процедура ОбновитьСтраныМираПоОКСМ обработала очередную порцию стран мира: %1'; en = 'The UpdateCountriesByClassifier procedure has processed another %1 countries.'; pl = 'Procedura ZaktualizujPaństwaŚwiataWgOKSM przetworzyła kolejną partię państw świata: %1';de = 'Das Verfahren AktualisierungDerLänderDerWeltNachOKCM hat eine weitere Reihe von Ländern der Welt bearbeitet: %1';ro = 'Procedura ОбновитьСтраныМираПоОКСМ a procesat porțiunea de rând a țărilor lumii: %1';tr = 'UpdateCountriesByClassifier işlemi aşağıdaki ülkeleri işledi:%1'; es_ES = 'El procedimiento UpdateCountriesByClassifier ha procesado unos países del mundo: %1'"),
					ObjectsProcessed));
	EndIf;
	
EndProcedure

#EndRegion

#EndRegion

#EndIf

