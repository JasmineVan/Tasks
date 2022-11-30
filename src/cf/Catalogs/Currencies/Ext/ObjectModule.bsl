///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	If RateSource = Enums.RateSources.CalculationByFormula Then
		QueryText =
		"SELECT
		|	Currencies.Description AS AlphabeticCode
		|FROM
		|	Catalog.Currencies AS Currencies
		|WHERE
		|	Currencies.RateSource = VALUE(Enum.RateSources.MarkupForOtherCurrencyRate)
		|
		|UNION ALL
		|
		|SELECT
		|	Currencies.Description
		|FROM
		|	Catalog.Currencies AS Currencies
		|WHERE
		|	Currencies.RateSource = VALUE(Enum.RateSources.CalculationByFormula)";
		
		Query = New Query(QueryText);
		DependentCurrencies = Query.Execute().Unload().UnloadColumn("AlphabeticCode");
		
		For Each Currency In DependentCurrencies Do
			If StrFind(RateCalculationFormula, Currency) > 0 Then
				Cancel = True;
			EndIf;
		EndDo;
	EndIf;
	
	If ValueIsFilled(MainCurrency.MainCurrency) Then
		Cancel = True;
	EndIf;
	
	If Cancel Then
		Common.MessageToUser(
			NStr("ru = 'Курс валюты можно связать только с курсом независимой валюты.'; en = 'An exchange rate can only be linked to the rate of an independent currency.'; pl = 'Kursy wymiany mogą być powiązane wyłącznie z kursem niezależnej waluty.';de = 'Wechselkurse können nur mit der Rate der unabhängigen Währung verknüpft werden.';ro = 'Cursurile de schimb pot fi legate numai de cursul monedei independente.';tr = 'Döviz kurları sadece bağımsız para birimine bağlanabilir.'; es_ES = 'Tipos de cambio pueden estar vinculados solo al tipo de la moneda independiente.'"));
	EndIf;
	
	If RateSource <> Enums.RateSources.MarkupForOtherCurrencyRate Then
		AttributesToExclude = New Array;
		AttributesToExclude.Add("MainCurrency");
		AttributesToExclude.Add("Markup");
		Common.DeleteNotCheckedAttributesFromArray(CheckedAttributes, AttributesToExclude);
	EndIf;
	
	If RateSource <> Enums.RateSources.CalculationByFormula Then
		AttributesToExclude = New Array;
		AttributesToExclude.Add("RateCalculationFormula");
		Common.DeleteNotCheckedAttributesFromArray(CheckedAttributes, AttributesToExclude);
	EndIf;
	
	If Not IsNew()
		AND RateSource = Enums.RateSources.MarkupForOtherCurrencyRate
		AND CurrencyRateOperations.DependentCurrenciesList(Ref).Count() > 0 Then
		Common.MessageToUser(
			NStr("ru = 'Валюта не может быть подчиненной, так как она является основной для других валют.'; en = 'The currency cannot be subordinate because it is used as the base currency for other currencies.'; pl = 'Waluta nie może być podrzędna, ponieważ jest walutą główną dla innych walut.';de = 'Die Währung kann nicht untergeordnet sein, da sie die Hauptwährung für andere Währungen ist.';ro = 'Moneda nu poate fi subordonată, deoarece este principală pentru alte valute.';tr = 'Para birimi, diğer para birimleri için ana birim olduğundan dolayı ikincil olamaz.'; es_ES = 'La moneda no puede ser subordinada, porque es la principal para otras monedas.'"));
		Cancel = True;
	EndIf;
	
EndProcedure

Procedure BeforeWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	RateImportedFromInternet = RateSource = Enums.RateSources.DownloadFromInternet;
	RateDependsOnOtherCurrency = RateSource = Enums.RateSources.MarkupForOtherCurrencyRate;
	RateCalculatedByFormula = RateSource = Enums.RateSources.CalculationByFormula;
	
	If IsNew() Then
		If RateDependsOnOtherCurrency Or RateCalculatedByFormula Then
			AdditionalProperties.Insert("UpdateRates");
		EndIf;
		AdditionalProperties.Insert("IsNew");
		AdditionalProperties.Insert("ScheduleCopyCurrencyRates");
	Else
		PreviousValues = Common.ObjectAttributesValues(Ref, "Code,RateSource,MainCurrency,Markup,RateCalculationFormula");
		
		RateSourceChanged = PreviousValues.RateSource <> RateSource;
		CurrencyCodeChanged = PreviousValues.Code <> Code;
		BaseCurrencyChanged = PreviousValues.MainCurrency <> MainCurrency;
		IncreaseByValueChanged = PreviousValues.Markup <> Markup;
		FormulaChanged = PreviousValues.RateCalculationFormula <> RateCalculationFormula;
		
		If (RateDependsOnOtherCurrency AND (BaseCurrencyChanged Or IncreaseByValueChanged Or RateSourceChanged))
			Or (RateCalculatedByFormula AND (FormulaChanged Or RateSourceChanged)) Then
			AdditionalProperties.Insert("UpdateRates");
		EndIf;
		
		If RateImportedFromInternet AND (RateSourceChanged Or CurrencyCodeChanged) Then
			AdditionalProperties.Insert("ScheduleCopyCurrencyRates");
		EndIf;
	EndIf;
	
	If RateSource <> Enums.RateSources.MarkupForOtherCurrencyRate Then
		MainCurrency = Catalogs.Currencies.EmptyRef();
		Markup = 0;
	EndIf;
	
	If RateSource <> Enums.RateSources.CalculationByFormula Then
		RateCalculationFormula = "";
	EndIf;
	
EndProcedure

Procedure OnWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	If IsBackgroundCurrencyExchangeRatesRecalculationRunning() Then
		Raise NStr("ru = 'Не удалось записать валюту, так как еще не завершился фоновый пересчет курсов.
			|Попробуйте записать валюту позже.'; 
			|en = 'Cannot record the currency, because the exchange rate calculation is running.
			|Try to record the currency later.'; 
			|pl = 'Nie można zapisać waluty, ponieważ kurs wymiany w tle nie został jeszcze ukończony.
			|Spróbuj zapisać walutę później.';
			|de = 'Es war nicht möglich, die Währung zu schreiben, da die Hintergrundneuberechnung der Kurse noch nicht abgeschlossen ist.
			|Versuchen Sie, die Währung später aufzuschreiben.';
			|ro = 'Eșec la înregistrarea valutei, deoarece nu s-a încheiat recalcularea pe fundal a ratelor valutare.
			|Încercați să înregistrați mai târziu.';
			|tr = 'Döviz kuru yeniden hesaplama henüz tamamlanmadığından para birimi kaydedilemedi.
			|Daha sonra para birimini kaydetmeyi deneyin.'; 
			|es_ES = 'No se ha podido guardar la divisa porque no se ha terminado el recuento de fondo de tipos de cambio.
			|Intente guardar la divisa más tarde.'");
	EndIf;
	
	If AdditionalProperties.Property("UpdateRates") Then
		StartBackgroundCurrencyExchangeRatesUpdate();
	Else
		CurrencyRateOperations.CheckCurrencyRateAvailabilityFor01_01_1980(Ref);
	EndIf;
	
	If AdditionalProperties.Property("ScheduleCopyCurrencyRates") Then
		ScheduleCopyCurrencyRates();
	EndIf;
	
EndProcedure

Function IsBackgroundCurrencyExchangeRatesRecalculationRunning()
	
	JobParameters = New Structure;
	JobParameters.Insert("Description", "CurrencyRateOperations.UpdateCurrencyRate");
	JobParameters.Insert("State", BackgroundJobState.Active);
	
	Return Common.FileInfobase() 
		AND BackgroundJobs.GetBackgroundJobs(JobParameters).Count() > 0;
		
EndFunction

Procedure StartBackgroundCurrencyExchangeRatesUpdate()
	
	CurrencyParameters = New Structure;
	CurrencyParameters.Insert("MainCurrency");
	CurrencyParameters.Insert("Ref");
	CurrencyParameters.Insert("Markup");
	CurrencyParameters.Insert("AdditionalProperties");
	CurrencyParameters.Insert("RateCalculationFormula");
	CurrencyParameters.Insert("RateSource");
	FillPropertyValues(CurrencyParameters, ThisObject);
	
	JobParameters = New Structure;
	JobParameters.Insert("Currency", CurrencyParameters);
	
	ExecutionParameters = TimeConsumingOperations.BackgroundExecutionParameters(New UUID());
	ExecutionParameters.WaitForCompletion = 0;
	ExecutionParameters.RunNotInBackground = InfobaseUpdate.InfobaseUpdateRequired();
	
	Result = TimeConsumingOperations.ExecuteInBackground("CurrencyRateOperations.UpdateCurrencyRate", JobParameters, ExecutionParameters);
	If Result.Status = "Error" Then
		Raise Result.BriefErrorPresentation;
	EndIf;

EndProcedure

Procedure ScheduleCopyCurrencyRates()
	
	Var ModuleCurrencyExchangeRatesInternalSaaS;
	
	If Common.DataSeparationEnabled()
		AND Common.SubsystemExists("StandardSubsystems.SaaS.CurrenciesSaaS") Then
		ModuleCurrencyExchangeRatesInternalSaaS = Common.CommonModule("CurrencyRatesInternalSaaS");
		ModuleCurrencyExchangeRatesInternalSaaS.ScheduleCopyCurrencyRates(ThisObject);
	EndIf;

EndProcedure

#EndRegion

#Else
Raise NStr("ru = 'Недопустимый вызов объекта на клиенте.'; en = 'Invalid object call on the client.'; pl = 'Niedozwolone wezwanie obiektu na kliencie.';de = 'Unzulässiger Objektaufruf auf dem Client.';ro = 'Apel inadmisibil al obiectului pe client.';tr = 'İstemcide kabul edilmeyen nesne çağrısı.'; es_ES = 'Llamada no disponible del objeto en el cliente.'");
#EndIf