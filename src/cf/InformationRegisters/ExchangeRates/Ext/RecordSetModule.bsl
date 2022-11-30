///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Variables

Var ErrorInRateCalculationByFormula;

#EndRegion

#Region EventHandlers

// The dependent currency rates are controlled while writing.
//
Procedure OnWrite(Cancel, Replacing)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	If AdditionalProperties.Property("DisableDependentCurrenciesControl") Then
		Return;
	EndIf;
		
	AdditionalProperties.Insert("DependentCurrencies", New Map);
	
	If Count() > 0 Then
		UpdateSubordinateCurrenciesRates();
	Else
		DeleteDependentCurrencyRates();
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

// Finds all dependent currencies and changes their rate.
//
Procedure UpdateSubordinateCurrenciesRates()
	
	DependentCurrency = Undefined;
	AdditionalProperties.Property("UpdateSubordinateCurrencyRate", DependentCurrency);
	
	For Each BaseCurrencyRecord In ThisObject Do

		If DependentCurrency <> Undefined Then // Only the given currency's rate must be updated.
			BlockDependentCurrencyRate(DependentCurrency, BaseCurrencyRecord.Period); 
		Else	
			DependentCurrencies = CurrencyRateOperations.DependentCurrenciesList(BaseCurrencyRecord.Currency, AdditionalProperties);
			For Each DependentCurrency In DependentCurrencies Do
				BlockDependentCurrencyRate(DependentCurrency, BaseCurrencyRecord.Period); 
			EndDo;
		EndIf;
		
	EndDo;
	
	For Each BaseCurrencyRecord In ThisObject Do

		If DependentCurrency <> Undefined Then // Only the given currency's rate must be updated.
			UpdatedPeriods = Undefined;
			If Not AdditionalProperties.Property("UpdatedPeriods", UpdatedPeriods) Then
				UpdatedPeriods = New Map;
				AdditionalProperties.Insert("UpdatedPeriods", UpdatedPeriods);
			EndIf;
			// The rate is not updated more than once over the same period of time.
			If UpdatedPeriods[BaseCurrencyRecord.Period] = Undefined Then
				UpdateSubordinateCurrencyRate(DependentCurrency, BaseCurrencyRecord); 
				UpdatedPeriods.Insert(BaseCurrencyRecord.Period, True);
			EndIf;
		Else	// Refresh the rate for all dependent currencies.
			DependentCurrencies = CurrencyRateOperations.DependentCurrenciesList(BaseCurrencyRecord.Currency, AdditionalProperties);
			For Each DependentCurrency In DependentCurrencies Do
				UpdateSubordinateCurrencyRate(DependentCurrency, BaseCurrencyRecord); 
			EndDo;
		EndIf;
		
	EndDo;
	
EndProcedure

Procedure BlockDependentCurrencyRate(DependentCurrency, BaseCurrencyPeriod)
	
	Lock = New DataLock;
	LockItem = Lock.Add("InformationRegister.ExchangeRates");
	LockItem.SetValue("Currency", DependentCurrency.Ref);
	If ValueIsFilled(BaseCurrencyPeriod) Then
		LockItem.SetValue("Period", BaseCurrencyPeriod);
	EndIf;
	Lock.Lock();
	
EndProcedure
	
Procedure UpdateSubordinateCurrencyRate(DependentCurrency, BaseCurrencyRecord)
	
	RecordSet = InformationRegisters.ExchangeRates.CreateRecordSet();
	RecordSet.Filter.Currency.Set(DependentCurrency.Ref, True);
	RecordSet.Filter.Period.Set(BaseCurrencyRecord.Period, True);
	
	WriteCurrencyRate = RecordSet.Add();
	WriteCurrencyRate.Currency = DependentCurrency.Ref;
	WriteCurrencyRate.Period = BaseCurrencyRecord.Period;
	If DependentCurrency.RateSource = Enums.RateSources.MarkupForOtherCurrencyRate Then
		WriteCurrencyRate.Rate = BaseCurrencyRecord.Rate + BaseCurrencyRecord.Rate * DependentCurrency.Markup / 100;
		WriteCurrencyRate.Repetition = BaseCurrencyRecord.Repetition;
	Else // by formula
		Rate = CurrencyRateByFormula(DependentCurrency.Ref, DependentCurrency.RateCalculationFormula, BaseCurrencyRecord.Period);
		If Rate <> Undefined Then
			WriteCurrencyRate.Rate = Rate;
			WriteCurrencyRate.Repetition = 1;
		EndIf;
	EndIf;
		
	RecordSet.AdditionalProperties.Insert("DisableDependentCurrenciesControl");
	RecordSet.AdditionalProperties.Insert("SkipPeriodClosingCheck");
	
	If WriteCurrencyRate.Rate > 0 Then
		RecordSet.Write();
	EndIf;
	
EndProcedure	

// Clears rates for dependent currencies.
//
Procedure DeleteDependentCurrencyRates()
	
	CurrencyOwner = Filter.Currency.Value;
	Period = Filter.Period.Value;
	
	DependentCurrency = Undefined;
	If AdditionalProperties.Property("UpdateSubordinateCurrencyRate", DependentCurrency) Then
		BlockDependentCurrencyRate(DependentCurrency, Period);
		DeleteCurrencyRates(DependentCurrency, Period);
	Else
		DependentCurrencies = CurrencyRateOperations.DependentCurrenciesList(CurrencyOwner, AdditionalProperties);
		For Each DependentCurrency In DependentCurrencies Do
			BlockDependentCurrencyRate(DependentCurrency.Ref, Period); 
		EndDo;
		For Each DependentCurrency In DependentCurrencies Do
			DeleteCurrencyRates(DependentCurrency.Ref, Period);
		EndDo;
	EndIf;
	
EndProcedure

Procedure DeleteCurrencyRates(CurrencyRef, Period)
	RecordSet = InformationRegisters.ExchangeRates.CreateRecordSet();
	RecordSet.Filter.Currency.Set(CurrencyRef);
	RecordSet.Filter.Period.Set(Period);
	RecordSet.AdditionalProperties.Insert("DisableDependentCurrenciesControl");
	RecordSet.Write();
EndProcedure
	
Function CurrencyRateByFormula(Val Currency, Val Formula, Val Period)
	QueryText =
	"SELECT
	|	Currencies.Description AS AlphabeticCode,
	|	ISNULL(CurrencyRatesSliceLast.Rate, 1) / ISNULL(CurrencyRatesSliceLast.Repetition, 1) AS Rate
	|FROM
	|	Catalog.Currencies AS Currencies
	|		LEFT JOIN InformationRegister.ExchangeRates.SliceLast(&Period, ) AS CurrencyRatesSliceLast
	|		ON CurrencyRatesSliceLast.Currency = Currencies.Ref
	|WHERE
	|	Currencies.RateSource <> VALUE(Enum.RateSources.MarkupForOtherCurrencyRate)
	|	AND Currencies.RateSource <> VALUE(Enum.RateSources.CalculationByFormula)";
	
	Query = New Query(QueryText);
	Query.SetParameter("Period", Period);
	Expression = Formula;
	If StrFind(Expression, ".") = 0 Then
		Expression = StrReplace(Expression, ",", ".");
	EndIf;	
	Selection = Query.Execute().Select();
	While Selection.Next() Do
		Expression = StrReplace(Expression, Selection.AlphabeticCode, Format(Selection.Rate, "NDS=.; NG=0"));
	EndDo;
	
	Try
		Result = Common.CalculateInSafeMode(Expression);
	Except
		If ErrorInRateCalculationByFormula = Undefined Then
			ErrorInRateCalculationByFormula = New Map;
		EndIf;
		If ErrorInRateCalculationByFormula[Currency] = Undefined Then
			ErrorInRateCalculationByFormula.Insert(Currency, True);
			ErrorInformation = ErrorInfo();
			
			ErrorText = StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = 'Расчет курса валюты ""%1"" по формуле ""%2"" не выполнен:'; en = 'Cannot calculate the exchange rate for currency %1 by formula ""%2"".'; pl = 'Obliczenie kursu wymiany ""%1"" przy użyciu formuły ""%2"" nie zostało wykonane:';de = 'Berechnung des Wechselkurses ""%1"" mit Formel ""%2"" wird nicht ausgeführt:';ro = 'Calculul cursului de schimb ""%1"" folosind formula ""%2"" nu este executat:';tr = '""%1"" formülünü kullanarak ""%2"" döviz kurunun hesaplanması gerçekleştirilmedi:'; es_ES = 'Cálculo del tipo de cambio ""%1"" utilizando la fórmula ""%2"" no se ha ejecutado:'",
				Common.DefaultLanguageCode()), Currency, Formula);
				
			Common.MessageToUser(ErrorText + Chars.LF + BriefErrorDescription(ErrorInformation), 
				Currency, "Object.RateCalculationFormula");
				
			If AdditionalProperties.Property("UpdateSubordinateCurrencyRate") Then
				Raise ErrorText + Chars.LF + BriefErrorDescription(ErrorInformation);
			EndIf;
			
			WriteLogEvent(NStr("ru = 'Валюты.Загрузка курсов валют'; en = 'Currencies.Import currency exchange rates'; pl = 'Waluta.Import kursów wymiany walut';de = 'Währung. Wechselkurse importieren';ro = 'Valute.Procesul de import al ratelor valutare';tr = 'Para birimi. Döviz kuru içe aktarımı'; es_ES = 'Moneda.Importación de los tipos de cambio'", Common.DefaultLanguageCode()),
				EventLogLevel.Error, Currency.Metadata(), Currency, 
				ErrorText + Chars.LF + DetailErrorDescription(ErrorInformation));
		EndIf;
		Result = Undefined;
	EndTry;
	
	Return Result;
EndFunction

#EndRegion

#Else
Raise NStr("ru = 'Недопустимый вызов объекта на клиенте.'; en = 'Invalid object call on the client.'; pl = 'Niedozwolone wezwanie obiektu na kliencie.';de = 'Unzulässiger Objektaufruf auf dem Client.';ro = 'Apel inadmisibil al obiectului pe client.';tr = 'İstemcide kabul edilmeyen nesne çağrısı.'; es_ES = 'Llamada no disponible del objeto en el cliente.'");
#EndIf