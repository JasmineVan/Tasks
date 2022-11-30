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
	
	If Not ValueIsFilled(Record.SourceRecordKey) Then
		Record.Period = CurrentSessionDate();
	EndIf;
	
	FillCurrency();

	CurrencySelectionAvailable = Not Parameters.FillingValues.Property("Currency") AND Not ValueIsFilled(Parameters.Key);
	Items.CurrencyLabel.Visible = Not CurrencySelectionAvailable;
	Items.CurrencyList.Visible = CurrencySelectionAvailable;
	
	WindowOptionsKey = ?(CurrencySelectionAvailable, "WithCurrencyChoice", "NoCurrencyChoice");
	
EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)
	
	// StandardSubsystems.PeriodClosingDates
	If Common.SubsystemExists("StandardSubsystems.PeriodClosingDates") Then
		ModulePeriodClosingDates = Common.CommonModule("PeriodClosingDates");
		ModulePeriodClosingDates.ObjectOnReadAtServer(ThisObject, CurrentObject);
	EndIf;
	// End StandardSubsystems.PeriodClosingDates
	
EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)
	Notify("Write_CurrencyRates", WriteParameters, Record);
EndProcedure

&AtServer
Procedure FillCheckProcessingAtServer(Cancel, CheckedAttributes)
	
	If Not CurrencySelectionAvailable Then
		AttributesToExclude = New Array;
		AttributesToExclude.Add("CurrencyList");
		Common.DeleteNotCheckedAttributesFromArray(CheckedAttributes, AttributesToExclude);
	EndIf;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure CurrencyOnChange(Item)
	Record.Currency = CurrencyList;
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure FillCurrency()
	
	Query = New Query;
	Query.Text = 
	"SELECT
	|	Currencies.Ref AS Ref,
	|	Currencies.Description AS AlphabeticCode,
	|	Currencies.DescriptionFull AS Description
	|FROM
	|	Catalog.Currencies AS Currencies
	|WHERE
	|	Currencies.DeletionMark = FALSE
	|
	|ORDER BY
	|	Description";
	
	CurrencySelection = Query.Execute().Select();
	
	While CurrencySelection.Next() Do
		CurrencyPresentation = StringFunctionsClientServer.SubstituteParametersToString("%1 (%2)", CurrencySelection.Description, CurrencySelection.AlphabeticCode);
		Items.CurrencyList.ChoiceList.Add(CurrencySelection.Ref, CurrencyPresentation);
		If CurrencySelection.Ref = Record.Currency Then
			CurrencyLabel = CurrencyPresentation;
			CurrencyList = Record.Currency;
		EndIf;
	EndDo;
	
EndProcedure

#EndRegion
