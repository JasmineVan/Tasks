
#Region FormEventsHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest") Then // Возврат при получении формы для анализа.
		Return;
	EndIf;
	
	If NOT ValueIsFilled(Record.SourceRecordKey) Then
		Record.Period = CurrentSessionDate();
	EndIf;
	
	FillCurrency();

	CurrencyChoiceAvailable = NOT Parameters.FillingValues.Property("Currency") AND NOT ValueIsFilled(Parameters.Key);
	Items.CurrencyLabel.Visible = NOT CurrencyChoiceAvailable;
	Items.CurrencyList.Visible = CurrencyChoiceAvailable;
	
	WindowOptionsKey = ?(CurrencyChoiceAvailable, "WithCurrencyChoice", "WithoutCurrencyChoice");
	
EndProcedure

&AtServer
Procedure FillCheckProcessingAtServer(Cancel, CheckingAttributes)
	
	If NOT CurrencyChoiceAvailable Then
		ExcludingAttributes = New Array;
		ExcludingAttributes.Add("CurrencyList");
		fmCommonUseServerCall.DeleteNoCheckAttributesFromArray(CheckingAttributes, ExcludingAttributes);
	EndIf;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventsHandlers

&AtClient
Procedure CurrencyOnChange(Item)
	Record.Currency = CurrencyList;
EndProcedure

#EndRegion

#Region ServiceProceduresAdFunctions

&AtServer
Procedure FillCurrency()
	        
	Query = New Query;
	Query.Text = 
	"SELECT
	|	Currencies.Ref AS Ref,
	|	Currencies.Description AS SymbolCode,
	|	Currencies.DescriptionFull AS Description
	|FROM
	|	Catalog.Currencies AS Currencies
	|WHERE
	|	Currencies.DeletionMark = False
	|
	|ORDER BY
	|	Description";
	
	CurrencySelection = Query.Execute().SELECT();
	
	While CurrencySelection.Next() Do
		CurrencyPresentation = StringFunctionsClientServer.SubstituteParametersToString("%1 (%2)", CurrencySelection.Description, CurrencySelection.SymbolCode);
		Items.CurrencyList.ChoiceList.Add(CurrencySelection.Ref, CurrencyPresentation);
		If CurrencySelection.Ref = Record.Currency Then
			CurrencyLabel = CurrencyPresentation;
			CurrencyList = Record.Currency;
		EndIf;
	EndDo;
	
EndProcedure

#EndRegion
