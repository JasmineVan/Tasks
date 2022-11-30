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
	
	If Object.Ref.IsEmpty() Then
		
		If Parameters.Property("CurrencyCode") Then
			Object.Code = Parameters.CurrencyCode;
		EndIf;
		
		If Parameters.Property("ShortDescription") Then
			Object.Description = Parameters.ShortDescription;
		EndIf;
		
		If Parameters.Property("DescriptionFull") Then
			Object.DescriptionFull = Parameters.DescriptionFull;
		EndIf;
		
		If Parameters.Property("Importing") AND Parameters.Importing Then
			Object.RateSource = Enums.RateSources.DownloadFromInternet;
		Else 
			Object.RateSource = Enums.RateSources.ManualInput;
		EndIf;
		
		If Parameters.Property("AmountInWordsParameters") Then
			Object.AmountInWordsParameters = Parameters.AmountInWordsParameters;
		EndIf;
		
	EndIf;
	
	ProcessingExchangeRatesImport = Metadata.DataProcessors.Find("ImportCurrenciesRates");
	If ProcessingExchangeRatesImport <> Undefined Then
		HasAmountInWordsParametersForm = ProcessingExchangeRatesImport.Forms.Find("CurrencyInWordsParameters") <> Undefined;
	EndIf;
	
	Items.CurrencyRateImportedFromInternet.Visible = ProcessingExchangeRatesImport <> Undefined;
	SetItemsAvailability(ThisObject);
	
	If Common.IsMobileClient() Then
		Items.RateCalculationFormula.ToolTipRepresentation = ToolTipRepresentation.ShowBottom;
		Items.MainCurrency.TitleLocation = FormItemTitleLocation.Auto;
		Items.HeaderGroup.ItemsAndTitlesAlign =
			ItemsAndTitlesAlignVariant.ItemsRightTitlesLeft;
	EndIf;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

////////////////////////////////////////////////////////////////////////////////
// Basic Additional Data page.

&AtClient
Procedure BaseCurrencyStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	PrepareSubordinateCurrencyChoiceData(ChoiceData, Object.Ref);
	
EndProcedure

&AtClient
Procedure CurrencyRateOnChange(Item)
	SetItemsAvailability(ThisObject);
EndProcedure

&AtClient
Procedure AmountInWordsParametersClick(Item)
	
	NotifyDescription = New NotifyDescription("OnChangeCurrencyParametersInWords", ThisObject);
	If HasAmountInWordsParametersForm Then
		OpeningParameters = New Structure;
		OpeningParameters.Insert("ReadOnly", ReadOnly);
		OpeningParameters.Insert("AmountInWordsParameters", Object.AmountInWordsParameters);
		AmountInWordsParametersFormName = "DataProcessor.ImportCurrenciesRates.Form.CurrencyInWordsParameters";
		OpenForm(AmountInWordsParametersFormName, OpeningParameters, ThisObject, , , , NotifyDescription);
	Else
		ShowInputString(NotifyDescription, Object.AmountInWordsParameters, NStr("ru = 'Параметры прописи валюты'; en = 'Parameters for writing amounts in words'; pl = 'Parametry waluta słownie';de = 'Aufzeichnungsparameter';ro = 'Parametrii de scriere cu litere';tr = 'Miktarları kelime olarak yazmak için parametreler'; es_ES = 'Parámetros de escribir las cantidades en palabras'"));
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

&AtServerNoContext
Procedure PrepareSubordinateCurrencyChoiceData(ChoiceData, Ref)
	
	// Prepares a selection list for a subordinate currency excluding the subordinate currency itself.
	// 
	
	ChoiceData = New ValueList;
	
	Query = New Query;
	
	Query.Text = 
	"SELECT
	|	Currencies.Ref AS Ref,
	|	Currencies.DescriptionFull AS DescriptionFull,
	|	Currencies.Description AS Description
	|FROM
	|	Catalog.Currencies AS Currencies
	|WHERE
	|	Currencies.Ref <> &Ref
	|	AND Currencies.MainCurrency = VALUE(Catalog.Currencies.EmptyRef)
	|
	|ORDER BY
	|	Currencies.DescriptionFull";
	
	Query.Parameters.Insert("Ref", Ref);
	
	Selection = Query.Execute().Select();
	
	While Selection.Next() Do
		ChoiceData.Add(Selection.Ref, Selection.DescriptionFull + " (" + Selection.Description + ")");
	EndDo;
	
EndProcedure

&AtClientAtServerNoContext
Procedure SetItemsAvailability(Form)
	Items = Form.Items;
	Object = Form.Object;
	Items.IncreaseByGroup.Enabled = Object.RateSource = PredefinedValue("Enum.RateSources.MarkupForOtherCurrencyRate");
	Items.RateCalculationFormula.Enabled = Object.RateSource = PredefinedValue("Enum.RateSources.CalculationByFormula");
EndProcedure

&AtClient
Procedure OnChangeCurrencyParametersInWords(Result, AdditionalParameters) Export
	If Result = Undefined Then
		Return;
	EndIf;
	
	Object.AmountInWordsParameters = Result;
	Modified = True;
EndProcedure

#EndRegion
