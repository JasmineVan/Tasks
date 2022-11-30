
#If Server OR ThickClientOrdinaryApplication OR ExternalConnection Then
Procedure FillPredefinedValues() Export
	
	FactObject = Catalogs.fmBudgetingScenarios.Plan.GetObject();
	FactObject.ScenarioType = Enums.fmBudgetingScenarioTypes.Plan;
	FactObject.PlanningPeriodicity = Enums.fmPlanningPeriodicity.Month;
	FactObject.PlanningPeriod = Enums.fmPlanningPeriod.Year;
	FactObject.Write();

	PlanObject = Catalogs.fmBudgetingScenarios.Actual.GetObject();
	PlanObject.ScenarioType = Enums.fmBudgetingScenarioTypes.Fact;
	PlanObject.PlanningPeriodicity = Enums.fmPlanningPeriodicity.Month;
	PlanObject.PlanningPeriod = Enums.fmPlanningPeriod.Year;
	PlanObject.Write();
	
EndProcedure
#EndIf
