
#If Server OR ThickClientOrdinaryApplication OR ExternalConnection Then

#Region VariableDescription

Var RateCalculationByFormulaError;

#EndRegion

#Region EventsHandlers

// При записи контролируются курсы подчиненных валют.
//
Procedure OnWrite(Cancel, Replacement)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	If AdditionalProperties.Property("DisableSubordinateCurrenciesControl") Then
		Return;
	EndIf;
		
	AdditionalProperties.Insert("DependentCurriencies", New Map);
	
	// rarud fm begin
	//If Count() > 0 Then
	//	UpdateSubordinateCurrenciesRates();
	//Else
	//	DeleteSubordinateCurrenciesRates();
	//EndIf;
	// rarud fm end
	
EndProcedure

#EndRegion

#Region ServiceProceduresAdFunctions

// Находит все зависимые валюты и изменяет их курс.
//
Procedure UpdateSubordinateCurrenciesRates()
	
	DependentCurrency = Undefined;
	AdditionalProperties.Property("UpdateSubordinateCurrencyRate", DependentCurrency);
	If DependentCurrency <> Undefined Then
		DependentCurrency = fmCommonUseServerCall.ObjectAttributeValues(DependentCurrency, 
			"Ref,Markup,RateSettingMethod,RateCalculationFormula");
	EndIf;
	
	For Each MainCurrencyRecord In ThisObject Do

		If DependentCurrency <> Undefined Then // Нужно обновить курс только указанной валюты.
			UpdatedPeriods = Undefined;
			If NOT AdditionalProperties.Property("UpdatedPeriods", UpdatedPeriods) Then
				UpdatedPeriods = New Map;
				AdditionalProperties.Insert("UpdatedPeriods", UpdatedPeriods);
			EndIf;
			// Повторно не обновляем курс за один и тот же период.
			If UpdatedPeriods[MainCurrencyRecord.Period] = Undefined Then
				UpdateSubordinateCurrencyRate(DependentCurrency, MainCurrencyRecord); 
				UpdatedPeriods.Insert(MainCurrencyRecord.Period, True);
			EndIf;
		Else	// Обновить курс всех зависимых валют.
			DependentCurriencies = CurrencyRateOperations.GetDependentCurrencyList(MainCurrencyRecord.Currency, AdditionalProperties);
			For Each DependentCurrency In DependentCurriencies Do
				UpdateSubordinateCurrencyRate(DependentCurrency, MainCurrencyRecord); 
			EndDo;
		EndIf;
		
	EndDo;
	
EndProcedure

Procedure UpdateSubordinateCurrencyRate(DependentCurrency, MainCurrencyRecord)
	
	RecordSet = InformationRegisters.fmBudgetingCurrencyRates.CreateRecordSet();
	RecordSet.Filter.Currency.Set(DependentCurrency.Ref, True);
	RecordSet.Filter.Period.Set(MainCurrencyRecord.Period, True);
	
	CurrenciesRatesRecord = RecordSet.Add();
	CurrenciesRatesRecord.Currency = DependentCurrency.Ref;
	CurrenciesRatesRecord.Period = MainCurrencyRecord.Period;
	If DependentCurrency.RateSettingMethod = Enums.CurrencyRateSettingMethod.AnotherCurrencyRateMarkup Then
		CurrenciesRatesRecord.Rate = MainCurrencyRecord.Rate + MainCurrencyRecord.Rate * DependentCurrency.Markup / 100;
		CurrenciesRatesRecord.Repetition = MainCurrencyRecord.Repetition;
	Else // по формуле
		Rate = CurrencyRateByFormula(DependentCurrency.Ref, DependentCurrency.RateCalculationFormula, MainCurrencyRecord.Period);
		If Rate <> Undefined Then
			CurrenciesRatesRecord.Rate = Rate;
			CurrenciesRatesRecord.Repetition = 1;
		EndIf;
	EndIf;
		
	RecordSet.AdditionalProperties.Insert("DisableSubordinateCurrenciesControl");
	RecordSet.AdditionalProperties.Insert("MissChangeProhibitionCheck");
	
	If CurrenciesRatesRecord.Rate > 0 Then
		RecordSet.Write();
	EndIf;
	
EndProcedure	

// Очищает курсы зависимых валют.
//
Procedure DeleteSubordinateCurrenciesRates()
	
	CurrencyOwner = Filter.Currency.Value;
	Period = Filter.Period;
	
	DependentCurrency = Undefined;
	If AdditionalProperties.Property("UpdateSubordinateCurrencyRate", DependentCurrency) Then
		DeleteCurenciesRates(DependentCurrency, Period);
	Else
		DependentCurriencies = CurrencyRateOperations.GetDependentCurrencyList(CurrencyOwner, AdditionalProperties);
		For Each DependentCurrency In DependentCurriencies Do
			DeleteCurenciesRates(DependentCurrency.Ref, Period);
		EndDo;
	EndIf;
	
EndProcedure

Procedure DeleteCurenciesRates(CurrencyRef, Period)
	RecordSet = InformationRegisters.fmBudgetingCurrencyRates.CreateRecordSet();
	RecordSet.Filter.Currency.Set(CurrencyRef);
	RecordSet.Filter.Period.Set(Period);
	RecordSet.AdditionalProperties.Insert("DisableSubordinateCurrenciesControl");
	RecordSet.Write();
EndProcedure
	
Function CurrencyRateByFormula(Currency, Formula, Period)
	QueryText =
	"SELECT
	|	Currencies.Description AS SymbolCode,
	|	ISNULL(CurrencyRatesSliceLast.Rate, 1) / ISNULL(CurrencyRatesSliceLast.Repetition, 1) AS Rate
	|FROM
	|	Catalog.Currencies AS Currencies
	|		LEFT JOIN InformationRegister.fmBudgetingCurrencyRates.SliceLast(&Period, ) AS CurrencyRatesSliceLast
	|		ON CurrencyRatesSliceLast.Currency = Currencies.Ref
	|WHERE
	|	Currencies.RateSettingMethod <> Value(Enum.CurrencyRateSettingMethod.AnotherCurrencyRateMarkup)
	|	AND Currencies.RateSettingMethod <> Value(Enum.CurrencyRateSettingMethod.CalculationByFormula)";
	
	Query = New Query(QueryText);
	Query.SetParameter("Period", Period);
	Expression = StrReplace(Formula, ",", ".");
	Selection = Query.Execute().SELECT();
	While Selection.Next() Do
		Expression = StrReplace(Expression, Selection.SymbolCode, Format(Selection.Rate, "NDS=.; NG=0"));
	EndDo;
	
	Try
		Result = Common.ExecuteInSafeMode(Expression);
	Except
		If RateCalculationByFormulaError = Undefined Then
			RateCalculationByFormulaError = New Map;
		EndIf;
		If RateCalculationByFormulaError[Currency] = Undefined Then
			RateCalculationByFormulaError.Insert(Currency, True);
			ErrorInfo = ErrorInfo();
			
			ErrorText = StringFunctionsClientServer.SubstituteParametersToString(NStr("en='Calculation of currency rate ""%1"" using formula ""%2"" is failed:';ru='Расчет курса валюты ""%1"" по формуле ""%2"" не выполнен:'",
				CommonClientServer.DefaultLanguageCode()), Currency, Formula);
				
			CommonClientServer.MessageToUser(ErrorText + Chars.LF + BriefErrorDescription(ErrorInfo), 
				Currency, "Object.RateCalculationFormula");
				
			If AdditionalProperties.Property("UpdateSubordinateCurrencyRate") Then
				Raise ErrorText + Chars.LF + BriefErrorDescription(ErrorInfo);
			Else
				WriteLogEvent(NStr("en='Currencies. Import currency exchange rates';ru='Валюты.Загрузка курсов валют'", CommonClientServer.DefaultLanguageCode()),
					EventLogLevel.Error, Currency.Metadata(), Currency, 
					ErrorText + Chars.LF + DetailErrorDescription(ErrorInfo));
			EndIf;
		EndIf;
		Result = Undefined;
	EndTry;
	
	Return Result;
EndFunction

#EndRegion

#EndIf







