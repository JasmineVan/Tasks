
#If Server OR ThickClientOrdinaryApplication OR ExternalConnection Then

Procedure FillPredefinedValuesIncomesAndExpenses() Export
	
	CatObjectWithout = Catalogs.fmInfoStructures.WithoutStructureIE.GetObject();
	CatObjectWithout.StructureType = Enums.fmInfoStructureTypes.IncomesAndExpensesBudget;
	CatObjectWithout.BudgetTotalType = Enums.fmBudgetTotalType.ByMonthes;
	CatObjectWithout.Write();
	
	CatObjectOut = Catalogs.fmInfoStructures.OutOfStructureIE.GetObject();
	CatObjectOut.StructureType = Enums.fmInfoStructureTypes.IncomesAndExpensesBudget;
	CatObjectOut.BudgetTotalType = Enums.fmBudgetTotalType.ByMonthes;
	CatObjectOut.Write();
	
	NewIncome = Catalogs.fmInfoStructuresSections.CreateItem();
	NewIncome.Owner = CatObjectWithout.Ref;
	NewIncome.Description = NStr("en='INCOME';ru='ДОХОДЫ'");
	NewIncome.StructureSectionType = Enums.fmBudgetFlowOperationTypes.Incomes;
	NewIncome.Order = 1;
	NewIncome.BoldFont = True;
	NewIncome.Write();
	
	NewExpence = Catalogs.fmInfoStructuresSections.CreateItem();
	NewExpence.Owner = CatObjectWithout.Ref;
	NewExpence.Description = NStr("en='EXPENSES';ru='РАСХОДЫ'");
	NewExpence.StructureSectionType = Enums.fmBudgetFlowOperationTypes.Expenses;
	NewExpence.Order = 2;
	NewExpence.BoldFont = True;
	NewExpence.Write();
	
	OutOfStr = Catalogs.fmInfoStructuresSections.CreateItem();
	OutOfStr.Owner = CatObjectOut.Ref;
	OutOfStr.Description = NStr("en='OUT OF STRUCTURE';ru='ВНЕ СТРУКТУРЫ'");
	OutOfStr.Order = 1;
	OutOfStr.IsBlankString = True;
	OutOfStr.BoldFont = True;
	OutOfStr.Write();
	
	IncomeOutOfStr = Catalogs.fmInfoStructuresSections.CreateItem();
	IncomeOutOfStr.Owner = CatObjectOut.Ref;
	IncomeOutOfStr.Parent = OutOfStr.Ref;
	IncomeOutOfStr.Description = NStr("en='INCOME';ru='ДОХОДЫ'");
	IncomeOutOfStr.StructureSectionType = Enums.fmBudgetFlowOperationTypes.Incomes;
	IncomeOutOfStr.Order = 2;
	IncomeOutOfStr.BoldFont = True;
	IncomeOutOfStr.Write();
	
	ExpenceOutOfStr = Catalogs.fmInfoStructuresSections.CreateItem();
	ExpenceOutOfStr.Owner = CatObjectOut.Ref;
	ExpenceOutOfStr.Parent = OutOfStr.Ref;
	ExpenceOutOfStr.Description = NStr("en='EXPENSES';ru='РАСХОДЫ'");
	ExpenceOutOfStr.StructureSectionType = Enums.fmBudgetFlowOperationTypes.Expenses;
	ExpenceOutOfStr.Order = 3;
	ExpenceOutOfStr.BoldFont = True;
	ExpenceOutOfStr.Write();
	
EndProcedure

Procedure FillPredefinedValuesCashflow() Export
	
	CatObjectWithout = Catalogs.fmInfoStructures.WithoutStructureCF.GetObject();
	CatObjectWithout.StructureType = Enums.fmInfoStructureTypes.CashflowBudget;
	CatObjectWithout.BudgetTotalType = Enums.fmBudgetTotalType.ByMonthes;
	CatObjectWithout.Write();
	
	CatObjectOut = Catalogs.fmInfoStructures.OutOfStructureCF.GetObject();
	CatObjectOut.StructureType = Enums.fmInfoStructureTypes.CashflowBudget;
	CatObjectOut.BudgetTotalType = Enums.fmBudgetTotalType.ByMonthes;
	CatObjectOut.Write();
	
	NewInflow = Catalogs.fmInfoStructuresSections.CreateItem();
	NewInflow.Owner = CatObjectWithout.Ref;
	NewInflow.Description = NStr("en='INFLOW';ru='ПРИТОК'");
	NewInflow.StructureSectionType = Enums.fmBudgetFlowOperationTypes.Inflow;
	NewInflow.Order = 1;
	NewInflow.BoldFont = True;
	NewInflow.Write();
	
	NewOutflow = Catalogs.fmInfoStructuresSections.CreateItem();
	NewOutflow.Owner = CatObjectWithout.Ref;
	NewOutflow.Description = NStr("en='OUTFLOW';ru='ОТТОК'");
	NewOutflow.StructureSectionType = Enums.fmBudgetFlowOperationTypes.Outflow;
	NewOutflow.Order = 2;
	NewOutflow.BoldFont = True;
	NewOutflow.Write();
	
	OutOfStr = Catalogs.fmInfoStructuresSections.CreateItem();
	OutOfStr.Owner = CatObjectOut.Ref;
	OutOfStr.Description = NStr("en='OUT OF STRUCTURE';ru='ВНЕ СТРУКТУРЫ'");
	OutOfStr.Order = 1;
	OutOfStr.IsBlankString = True;
	OutOfStr.BoldFont = True;
	OutOfStr.Write();
	
	InflowOutOfStr = Catalogs.fmInfoStructuresSections.CreateItem();
	InflowOutOfStr.Owner = CatObjectOut.Ref;
	InflowOutOfStr.Parent = OutOfStr.Ref;
	InflowOutOfStr.Description = NStr("en='INFLOW';ru='ПРИТОК'");
	InflowOutOfStr.StructureSectionType = Enums.fmBudgetFlowOperationTypes.Inflow;
	InflowOutOfStr.Order = 2;
	InflowOutOfStr.BoldFont = True;
	InflowOutOfStr.Write();
	
	OutflowOutOfStr = Catalogs.fmInfoStructuresSections.CreateItem();
	OutflowOutOfStr.Owner = CatObjectOut.Ref;
	OutflowOutOfStr.Parent = OutOfStr.Ref;
	OutflowOutOfStr.Description = NStr("en='OUTFLOW';ru='ОТТОК'");
	OutflowOutOfStr.StructureSectionType = Enums.fmBudgetFlowOperationTypes.Outflow;
	OutflowOutOfStr.Order = 3;
	OutflowOutOfStr.BoldFont = True;
	OutflowOutOfStr.Write();
	
EndProcedure

#EndIf
