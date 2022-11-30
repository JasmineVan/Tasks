
#Region ProgramInterface

// Возвращает курс валюты на дату.
//
// Параметры:
//   Валюта    - СправочникСсылка.Валюты - Валюта, для которой получается курс.
//   ДатаКурса - Дата - Дата, на которую получается курс.
//   КурсыВалютБюджетирования - Булево - Источник курса валют.
//
// Возвращаемое значение: 
//   Структура - Параметры курса.
//       * Курс      - Число - Курс валюты на указанную дату.
//       * Кратность - Число - Кратность валюты на указанную дату.
//       * Валюта    - СправочникСсылка.Валюты - Ссылка валюты.
//       * ДатаКурса - Дата - Дата получения курса.
//
Function GetBudgetingCurrencyRate(Currency, RateDate, BudgetingCurrencyRates=False) Export
	
	If BudgetingCurrencyRates Then
		DocumentCurrencyRate = InformationRegisters.fmBudgetingCurrencyRates.GetLast(RateDate, New Structure("Currency", Currency));
		CurrencyRatesOfManAccounting = InformationRegisters.fmBudgetingCurrencyRates.GetLast(RateDate, New Structure("Currency", Constants.fmCurrencyOfManAccounting.Get()));
	Else
		DocumentCurrencyRate = CurrencyRateOperations.GetCurrencyRate(Currency, RateDate);
		CurrencyRatesOfManAccounting = CurrencyRateOperations.GetCurrencyRate(Constants.fmCurrencyOfManAccounting.Get(), RateDate);
	EndIf;
	
	DocumentCurrencyRate.Insert("Currency",    Currency);
	DocumentCurrencyRate.Insert("RateDate", RateDate);
	Try
		DocumentCurrencyRate.Rate = (CurrencyRatesOfManAccounting.Rate / CurrencyRatesOfManAccounting.Repetition) / (DocumentCurrencyRate.Rate / DocumentCurrencyRate.Repetition);
	Except
		DocumentCurrencyRate.Rate = 1;
	EndTry;
	DocumentCurrencyRate.Repetition = 1;
	
	Return DocumentCurrencyRate;
	
EndFunction

// Функция пересчитывает Сумму из ВалютаНач и возвращает значение Сумма в ВалютаКон.
// в параметрах ПоКурсуВалютыНач и ПоКурсуВалютыНач могут передаваться либо сами курсы либо даты.
//
// Параметры:
//	ЧислСумма        - Число 			- Сумма для пересчета
//	ВалютаНач        - СправочникСсылка - Начальная валюта в которой сумма для пересчета
//	ПоКурсуВалютыНач - Число, Дата		- Курс валюты или дата курса
//	ВалютаКон        - СправочникСсылка - Конечная валюта в которую надо пересчитать сумму
//	ПоКурсуВалютыКон - Число, Дата		- Курс валюты или дата курса
//	РежимОкр         - РежимОкругления  - Режим округления суммы при пересчете.
//
// Возвращаемое значение:
//	ЧислоРезультат   - Число - Сумма после пересчета.
//
Function Conversion(VAL NumAmount, CurrencyInit, ByCurrencyInitRate, CurrencyFin, ByCurrencyFinRate, VAL RndMode=Undefined) Export
	
	Try
		If CurrencyInit=CurrencyFin AND ByCurrencyInitRate=ByCurrencyFinRate Then
			Return NumAmount;
		EndIf;
	Except
	EndTry; 

	ValType=TypeOf(ByCurrencyInitRate);
	If ValType=Type("Number") Then CurrencyRateInit=ByCurrencyInitRate;
	ElsIf (ValType=Type("DATE")) OR (ValType=Type("PointInTime")) OR (ValType=Type("Boundary")) Then 
		RateSt=InformationRegisters.CurrencyRates.GetLast(ByCurrencyInitRate,New Structure("Currency",CurrencyInit));
		Try
			CurrencyRateInit=RateSt.Rate/?(RateSt.Repetition=0,1,RateSt.Repetition);
		Except
			CurrencyRateInit=0;
		EndTry;
	Else 
		CommonClientServer.MessageToUser(NStr("en='Invalid parameter type at converting currency!(1)';ru='Неверный тип параметра при пересчете валюты!(1)'"));
		Return NumAmount;
	EndIf;

	ValType=TypeOf(ByCurrencyFinRate);
	If ValType=Type("Number") Then CurrencyRateFin=ByCurrencyFinRate;
	ElsIf (ValType=Type("DATE")) OR (ValType=Type("PointInTime")) OR (ValType=Type("Boundary")) Then 
		RateSt=InformationRegisters.CurrencyRates.GetLast(ByCurrencyFinRate,New Structure("Currency",CurrencyFin));
		Try
			CurrencyRateFin=RateSt.Rate/?(RateSt.Repetition=0,1,RateSt.Repetition);
		Except
			CurrencyRateFin=0;
		EndTry;
	Else
		CommonClientServer.MessageToUser(NStr("en='Invalid parameter type at converting currency!(2)';ru='Неверный тип параметра при пересчете валюты!(2)'"));
		Return NumAmount;
	EndIf;

	If (CurrencyRateInit*CurrencyRateFin)=0 Then		
		CommonClientServer.MessageToUser(StrTemplate(NStr("en='Zero currency rate was detected while currency converting. %1';ru='При пересчете валюты обнаружен нулевой курс валюты. %1'"), TrimAll(?(CurrencyRateInit=0,CurrencyInit,CurrencyFin))));
		Return NumAmount;
	EndIf;
	If CurrencyRateFin=0 Then
		Return 0;
	Else
		If CurrencyRateInit<>CurrencyRateFin Then
			NumberResult=NumAmount*CurrencyRateInit/CurrencyRateFin;
			If RndMode<>Undefined Then
				NumberResult=Round(NumberResult,2,RndMode);
			Else
				NumberResult=Round(NumberResult,2);
			EndIf; 
			Return NumberResult;
		EndIf;
	EndIf;

	Return NumAmount;	
	
EndFunction //Пересчет

Procedure FormTableOfCurrencyRates(CurrencyRates, Currency, BeginOfPeriod, Scenario) Export
	
	CurrencyRates.Clear();
	
	If ValueIsFilled(Scenario) AND ValueIsFilled(Currency) AND ValueIsFilled(BeginOfPeriod) Then
		
		ManAccountingCurrency = Constants.fmCurrencyOfManAccounting.Get();
		ScenarioBudgetingCurrencyRates = Scenario.BudgetingCurrencyRates;
		
		//Получим таблицу периодов.
		PeriodsTable = fmBudgeting.PeriodsTable(Scenario, BeginOfPeriod);
		
		//Получим курсы
		For Each CurRow In PeriodsTable Do
			NewLine = CurrencyRates.Add();
			NewLine.Period = CurRow.BeginOfPeriod;
			If Currency = ManAccountingCurrency Then
				NewLine.Rate = 1;
				NewLine.Repetition = 1;
			Else
				CurrencyRate = fmCurrencyRatesProcessing.GetBudgetingCurrencyRate(Currency, CurRow.BeginOfPeriod, ScenarioBudgetingCurrencyRates);
				NewLine.Rate = CurrencyRate.Rate;
				NewLine.Repetition = CurrencyRate.Repetition;
			EndIf;
		EndDo;
		
	EndIf;
	
EndProcedure

// Проверяет наличие установленного курса и кратности валюты на 1 января 1980 года.
// В случае отсутствия устанавливает курс и кратность равными единице.
//
// Параметры:
//
Procedure CheckRateCorrectness() Export
	
	Currency = Constants.ComplianceAccountingCurrency.Get();
	RateDate = DATE("19800101");
	RateStructure = InformationRegisters.fmBudgetingCurrencyRates.GetLast(RateDate, New Structure("Currency", Currency));
	
	If (RateStructure.Rate = 0) OR (RateStructure.Repetition = 0) Then
		RecordSet = InformationRegisters.fmBudgetingCurrencyRates.CreateRecordSet();
		RecordSet.Filter.Currency.Set(Currency);
		RecordSet.Filter.Period.Set(RateDate);
		Record = RecordSet.Add();
		Record.Currency = Currency;
		Record.Period = RateDate;
		Record.Rate = 1;
		Record.Repetition = 1;
		RecordSet.AdditionalProperties.Insert("MissChangeProhibitionCheck");
		RecordSet.Write();
	EndIf;
	
EndProcedure

#EndRegion
