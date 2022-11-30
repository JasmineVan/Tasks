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
	
	Items.Currencies.ChoiceMode = Parameters.ChoiceMode;
	
	RateDate = BegOfDay(CurrentSessionDate());
	List.SettingsComposer.Settings.AdditionalProperties.Insert("RateDate", RateDate);
	
	EditableFields = New Array;
	EditableFields.Add("Rate");
	EditableFields.Add("Repetition");
	List.SetRestrictionsForUseInGroup(EditableFields);
	List.SetRestrictionsForUseInOrder(EditableFields);
	List.SetRestrictionsForUseInFilter(EditableFields);
	
	CurrenciesChangeAvailable = AccessRight("Update", Metadata.InformationRegisters.ExchangeRates);
	CurrenciesImportAvailable = Metadata.DataProcessors.Find("ImportCurrenciesRates") <> Undefined AND CurrenciesChangeAvailable;
	
	Items.FormPickFromClassifier.Visible = CurrenciesImportAvailable;
	Items.FormImportExchangeRates.Visible = CurrenciesImportAvailable;
	If Not CurrenciesImportAvailable Then
		If CurrenciesChangeAvailable Then
			Items.CreateCurrency.Title = NStr("ru = 'Создать'; en = 'Create'; pl = 'Utworzyć';de = 'Erstellen';ro = 'Actualizare';tr = 'Oluştur'; es_ES = 'Crear'");
		EndIf;
		Items.Create.Type = FormGroupType.ButtonGroup;
	EndIf;
	
EndProcedure

&AtClient
Procedure ChoiceProcessing(SelectionResult, ChoiceSource)
	
	Items.Currencies.Refresh();
	Items.Currencies.CurrentRow = SelectionResult;
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If EventName = "Write_CurrencyRates"
		Or EventName = "Write_CurrencyRateImport" Then
		Items.Currencies.Refresh();
	EndIf;
	
EndProcedure

#EndRegion

#Region CurrencyFormTableItemsEventHandlers

&AtServerNoContext
Procedure CurrenciesOnGetDataAtServer(ItemName, Settings, Rows)
	
	Var RateDate;
	
	If Not Settings.AdditionalProperties.Property("RateDate", RateDate) Then
		Return;
	EndIf;
	
	Query = New Query;
	Query.Text =
		"SELECT
		|	ExchangeRates.Currency AS Currency,
		|	ExchangeRates.Rate AS Rate,
		|	ExchangeRates.Repetition AS Repetition
		|FROM
		|	InformationRegister.ExchangeRates.SliceLast(&EndOfPeriod, Currency IN (&Currencies)) AS ExchangeRates";
	Query.SetParameter("Currencies", Rows.GetKeys());
	Query.SetParameter("EndOfPeriod", RateDate);
	
	Selection = Query.Execute().Select();
	While Selection.Next() Do
		ListLine = Rows[Selection.Currency];
		ListLine.Data["Rate"] = Selection.Rate;
		If Selection.Repetition <> 1 Then 
			Note = StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = 'руб. за %1 %2'; en = 'rub. for %1 %2'; pl = 'zł za %1 %2';de = 'Rub. für %1 %2';ro = 'lei pentru %1 %2';tr = '%1%2için Ruble'; es_ES = 'rublos por %1 %2'"), 
				Selection.Repetition, ListLine.Data["Description"]);
			ListLine.Data["Repetition"] = Note;
		EndIf;
	EndDo;
	
EndProcedure

#EndRegion

#Region FormCommandHandlers

&AtClient
Procedure PickFromClassifier(Command)
	
	PickingFormName = "DataProcessor.ImportCurrenciesRates.Form.PickCurrenciesFromClassifier";
	OpenForm(PickingFormName, , ThisObject);
	
EndProcedure

&AtClient
Procedure ImportCurrenciesRates(Command)
	
	ImportFormName = "DataProcessor.ImportCurrenciesRates.Form";
	FormParameters = New Structure("OpeningFromList");
	OpenForm(ImportFormName, FormParameters);
	
EndProcedure

#EndRegion
