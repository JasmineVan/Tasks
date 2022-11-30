
&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("CurrencyRates") Then
		For Each Item In Parameters.CurrencyRates Do
			NewLine = CurrencyRates.Add();
			NewLine.Period					= Item.Period;
			NewLine.Rate 					= Item.Rate;
			NewLine.Repetition 				= Item.Repetition;
		EndDo;
	EndIf;
	
	If Parameters.Property("Currency") Then
		DocumentCurrency = Parameters.Currency;
	EndIf;
	
	If Parameters.Scenario.PlanningPeriodicity=Enums.fmPlanningPeriodicity.Quarter Then
		If InfoBaseUsers.CurrentUser().Language = Metadata.Languages.Russian Then
			Items.CurrencyRatesPeriod.Format = "DF='K ""квартал"" yyyy ""г.""'";
		Else
			Items.CurrencyRatesPeriod.Format = "DF='K ""quarter"" yyyy '";
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure SaveAndClose(Command)
	
	HasErrors = False;
	For Each Item In CurrencyRates Do
		If Item.Rate = 0 OR Item.Repetition = 0 Then
			CommonClientServer.MessageToUser(NStr("en='The currency rate and conversion factor cannot have zero values. Period:';ru='Курс и кратность не могут иметь нулевые значения. Период:'") + " <" + Item.Period + ">. " + NStr("ru = 'Table курсов NOT может быть сохранена.'; en = 'Course table wouldn't be saved'"), , , , HasErrors);
		EndIf;
	EndDo;
	
	If NOT ValueIsFilled(DocumentCurrency) Then
		CommonClientServer.MessageToUser(NStr("en='The document currency is not specified.';ru='Не указана валюта документа!'"), , "DocumentCurrency", , HasErrors);
	EndIf;
	
	If NOT HasErrors Then
		ParametersStructure = New Structure;
		ParametersStructure.Insert("CurrencyRates", CurrencyRates);
		ParametersStructure.Insert("Currency", DocumentCurrency);
		Notify("CurrencyRatesFormIsClosed", ParametersStructure);
		Close();
	EndIf;
	
EndProcedure

&AtClient
Procedure Fill(Command)
	If NOT ValueIsFilled(DocumentCurrency) Then
		CommonClientServer.MessageToUser(NStr("en='The document currency is not specified.';ru='Не указана валюта документа!'"), , "DocumentCurrency");
	Else
		FormingTableOfCurrencyRatesAtServer();
	EndIf;
EndProcedure

&AtServer
Procedure FormingTableOfCurrencyRatesAtServer()
	fmCurrencyRatesProcessing.FormTableOfCurrencyRates(CurrencyRates, DocumentCurrency, Parameters.BeginOfPeriod, Parameters.Scenario);
EndProcedure

&AtClient
Procedure DocumentCurrencyOnChange(Item)
	If ValueIsFilled(DocumentCurrency) Then
		FormingTableOfCurrencyRatesAtServer();
	EndIf;
EndProcedure




