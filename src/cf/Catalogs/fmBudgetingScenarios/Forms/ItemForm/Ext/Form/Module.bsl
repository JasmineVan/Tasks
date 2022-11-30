
#Region FormEventsHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	If Object.Predefined Then
		Items.ScenarioType.ReadOnly = True;
	EndIf;
	Items.BudgetingCurrencyRates.Visible = Object.ScenarioType=Enums.fmBudgetingScenarioTypes.Plan;
EndProcedure

&AtClient
Procedure ScenarioTypesOnChange(Item)
	ScenarioTypesOnChangeServer();
EndProcedure

&AtServer
Procedure ScenarioTypesOnChangeServer()
	Object.BudgetingCurrencyRates = False;
	Items.BudgetingCurrencyRates.Visible = Object.ScenarioType=Enums.fmBudgetingScenarioTypes.Plan;
EndProcedure

#EndRegion
