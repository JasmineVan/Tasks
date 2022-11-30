

#If Server OR ThickClientOrdinaryApplication OR ExternalConnection Then

#Region EventsHandlers

Procedure Posting(Cancel, PostingMode)
	
	ManAccountingCurrency = Constants.fmCurrencyOfManAccounting.Get();
	
	// Настройки по согласованию.
	MatchCurrentVersion = False;
	If Scenario.ScenarioType=Enums.fmBudgetingScenarioTypes.Plan
	AND NOT Allocation
	AND NOT fmProcessManagement.GetDocumentState(Ref, fmBudgeting.DetermineDocumentVersion(ThisObject))=Catalogs.fmDocumentState.Approved Then
		MatchCurrentVersion = fmProcessManagement.AgreeDocument(Department, ChartsOfCharacteristicTypes.fmAgreeDocumentTypes.fmBudget, fmProcessManagement.AgreementCheckDate(ThisObject));
	EndIf;
	
	Query = New Query;
	Query.Text = "SELECT ALLOWED
	               |	fmBudgetBudgetData.Ref.Department AS Department,
	               |	fmBudgetBudgetData.Ref.BalanceUnit,
	               |	fmBudgetBudgetData.Ref AS Ref,
	               |	fmBudgetBudgetData.LineNumber AS LineNumber,
	               |	fmBudgetBudgetData.Period AS Period,
	               |	fmBudgetBudgetData.AllocationStep,
	               |	fmBudgetBudgetData.AllocationStep.StepType AS StepType,
	               |	fmBudgetBudgetData.RecordType AS RecordType,
	               |	fmBudgetBudgetData.Item AS Item,
	               |	fmBudgetBudgetData.CorItem AS CorItem,
	               |	fmBudgetBudgetData.CorItem.AnalyticsType1.ValueType AS AnalyticsType1,
	               |	fmBudgetBudgetData.CorItem.AnalyticsType2.ValueType AS AnalyticsType2,
	               |	fmBudgetBudgetData.CorItem.AnalyticsType3.ValueType AS AnalyticsType3,
	               |	fmBudgetBudgetData.CorDepartment AS CorDepartment,
	               |	fmBudgetBudgetData.Amount AS Amount,
	               |	fmBudgetBudgetData.Analytics1 AS Analytics1,
	               |	fmBudgetBudgetData.Analytics2 AS Analytics2,
	               |	fmBudgetBudgetData.Analytics3 AS Analytics3,
	               |	fmBudgetBudgetData.VersionPeriod AS VersionPeriod,
	               |	fmBudgetBudgetData.CorBalanceUnit AS CorBalanceUnit,
	               |	fmBudgetBudgetData.CorProject AS CorProject,
	               |	EntriesTemplates.AccountDr AS AccountDr,
	               |	EntriesTemplates.AccountCr AS AccountCr,
	               |	ISNULL(EntriesTemplates.AmountCalculationRatio, 0) AS AmountCalculationRatio,
	               |	ISNULL(EntriesTemplates.AccountDr.Currency, False) AS AccountDrCurrency,
	               |	ISNULL(EntriesTemplates.AccountDr.FinancialResults, False) AS AccountDrFinancialResult,
	               |	ISNULL(EntriesTemplates.AccountDr.AccountingByProjects, False) AS AccountDrAccountingByProjects,
	               |	ISNULL(EntriesTemplates.AccountCr.Currency, False) AS AccountCrCurrency,
	               |	ISNULL(EntriesTemplates.AccountCr.FinancialResults, False) AS AccountCrFinancialResult,
	               |	EntriesTemplates.ExtDimensionDr1 AS ExtDimensionDr1,
	               |	EntriesTemplates.ExtDimensionDr2 AS ExtDimensionDr2,
	               |	EntriesTemplates.ExtDimensionDr3 AS ExtDimensionDr3,
	               |	EntriesTemplates.ExtDimensionCr1 AS ExtDimensionCr1,
	               |	EntriesTemplates.ExtDimensionCr2 AS ExtDimensionCr2,
	               |	EntriesTemplates.ExtDimensionCr3 AS ExtDimensionCr3,
	               |	{ExtDimension}
	               |	ISNULL(EntriesTemplates.AccountCr.AccountingByProjects, False) AS AccountCrAccountingByProjects
	               |INTO TTBudgetDataTemplates
	               |FROM
	               |	Document.fmBudget.BudgetsData AS fmBudgetBudgetData
	               |		LEFT JOIN Catalog.{Catalog}.{fm}EntriesTemplates AS EntriesTemplates
	               |			ON fmBudgetBudgetData.Item = EntriesTemplates.Ref
	               |WHERE
	               |	fmBudgetBudgetData.Ref = &Ref
	               |;
	               |
	               |////////////////////////////////////////////////////////////////////////////////
	               |SELECT
	               |	TTBudgetDataTemplates.Period AS Period,
	               |	TTBudgetDataTemplates.RecordType AS RecordType,
	               |	TTBudgetDataTemplates.OperationType AS OperationType,
	               |	TTBudgetDataTemplates.AllocationStep AS AllocationStep,
	               |	TTBudgetDataTemplates.StepType AS StepType,
	               |	TTBudgetDataTemplates.Item AS Item,
	               |	TTBudgetDataTemplates.CorItem AS CorItem,
	               |	TTBudgetDataTemplates.AnalyticsType1 AS AnalyticsType1,
	               |	TTBudgetDataTemplates.AnalyticsType2 AS AnalyticsType2,
	               |	TTBudgetDataTemplates.AnalyticsType3 AS AnalyticsType3,
	               |	TTBudgetDataTemplates.CorDepartment AS CorDepartment,
	               |	TTBudgetDataTemplates.Amount AS Amount,
	               |	TTBudgetDataTemplates.Analytics1 AS Analytics1,
	               |	TTBudgetDataTemplates.Analytics2 AS Analytics2,
	               |	TTBudgetDataTemplates.Analytics3 AS Analytics3,
	               |	TTBudgetDataTemplates.VersionPeriod AS VersionPeriod,
	               |	TTBudgetDataTemplates.Department,
	               |	TTBudgetDataTemplates.CorBalanceUnit AS CorBalanceUnit,
	               |	TTBudgetDataTemplates.CorProject AS CorProject,
	               |	fmBudgetingDr.ExtDimensionTypes.(
	               |		ExtDimensionType AS ExtDimensionType,
	               |		LineNumber AS LineNumber,
	               |		ExtDimensionType.ValueType AS ValueType
	               |	) AS ExtDimensionTypesDr,
	               |	fmBudgetingCr.ExtDimensionTypes.(
	               |		ExtDimensionType AS ExtDimensionType,
	               |		LineNumber AS LineNumber,
	               |		ExtDimensionType.ValueType AS ValueType
	               |	) AS ExtDimensionTypesCr,
	               |	TTBudgetDataTemplates.AccountDr AS AccountDr,
	               |	TTBudgetDataTemplates.AccountCr AS AccountCr,
	               |	TTBudgetDataTemplates.AmountCalculationRatio AS AmountCalculationRatio,
	               |	TTBudgetDataTemplates.AccountDrCurrency AS AccountDrCurrency,
	               |	TTBudgetDataTemplates.AccountDrFinancialResult AS AccountDrFinancialResult,
	               |	TTBudgetDataTemplates.AccountDrAccountingByProjects AS AccountDrAccountingByProjects,
	               |	TTBudgetDataTemplates.AccountCrCurrency AS AccountCrCurrency,
	               |	TTBudgetDataTemplates.AccountCrFinancialResult AS AccountCrFinancialResult,
	               |	TTBudgetDataTemplates.AccountCrAccountingByProjects AS AccountCrAccountingByProjects,
	               |	TTBudgetDataTemplates.ExtDimensionDr1 AS ExtDimensionDr1,
	               |	TTBudgetDataTemplates.ExtDimensionDr2 AS ExtDimensionDr2,
	               |	TTBudgetDataTemplates.ExtDimensionDr3 AS ExtDimensionDr3,
	               |	TTBudgetDataTemplates.ExtDimensionCr1 AS ExtDimensionCr1,
	               |	TTBudgetDataTemplates.ExtDimensionCr2 AS ExtDimensionCr2,
	               |	TTBudgetDataTemplates.ExtDimensionCr3 AS ExtDimensionCr3,
	               |	TTBudgetDataTemplates.BalanceUnit AS BalanceUnit,
	               |	TTBudgetDataTemplates.PathBalanceUnit AS PathBalanceUnit,
	               |	TTBudgetDataTemplates.LineNumber AS LineNumber
	               |FROM
	               |	TTBudgetDataTemplates AS TTBudgetDataTemplates
	               |		LEFT JOIN ChartOfAccounts.fmBudgeting AS fmBudgetingDr
	               |		ON TTBudgetDataTemplates.AccountDr = fmBudgetingDr.Ref
	               |		LEFT JOIN ChartOfAccounts.fmBudgeting AS fmBudgetingCr
	               |		ON TTBudgetDataTemplates.AccountCr = fmBudgetingCr.Ref
	               |TOTALS
	               |	MAX(Period),
	               |	MAX(RecordType),
	               |	MAX(Item),
	               |	MAX(CorItem),
	               |	MAX(CorDepartment),
	               |	MAX(Amount),
	               |	MAX(Analytics1),
	               |	MAX(Analytics2),
	               |	MAX(Analytics3),
	               |	MAX(VersionPeriod),
	               |	MAX(CorBalanceUnit),
	               |	MAX(Department),
	               |	MAX(OperationType),
	               |	MAX(AllocationStep),
	               |	MAX(StepType),
	               |	{Maximum}
	               |	MAX(CorProject)
	               |BY
	               |	LineNumber";
	Query.SetParameter("Ref",Ref);
	Query.SetParameter("OperationType", OperationType);
	If OperationType = Enums.fmBudgetOperationTypes.IncomesAndExpenses OR OperationType = Enums.fmBudgetOperationTypes.InternalSettlements Then
		Query.Text = StrReplace(Query.Text,"{Catalog}","fmIncomesAndExpensesItems");
		Query.Text = StrReplace(Query.Text,"{fm}","");
		Query.Text = StrReplace(Query.Text,"{ExtDimension}","EntriesTemplates.BalanceUnit AS PathBalanceUnit,
	                       |	EntriesTemplates.DepartmentDr AS PathDepartmentDr,
	                       |	EntriesTemplates.DepartmentCr AS PathDepartmentCr,
			               |	ISNULL(EntriesTemplates.OperationType, &OperationType) AS OperationType,");
		Query.Text = StrReplace(Query.Text,"{Maximum}","MAX(BalanceUnit),");
	ElsIf OperationType = Enums.fmBudgetOperationTypes.Cashflows Then
		Query.Text = StrReplace(Query.Text,"{Catalog}","fmCashflowItems");
		Query.Text = StrReplace(Query.Text,"{fm}","fm");
		Query.Text = StrReplace(Query.Text,"{ExtDimension}"," ""BalanceUnit"" AS PathBalanceUnit,
	               |	""Department"" AS PathDepartmentDr,
	               |	""Department"" AS PathDepartmentCr,
	               |	&OperationType AS OperationType,");
		Query.Text = StrReplace(Query.Text,"{Maximum}","");
	EndIf;
	IterationResult = Query.Execute().SELECT(QueryResultIteration.ByGroups);
	While IterationResult.Next() Do
		Selection = IterationResult.SELECT();
		CurCurrencyRate = CurrencyRates.Find(BegOfMonth(IterationResult.Period), "Period");
		If CurCurrencyRate=Undefined Then
			CurCurrencyRate = New Structure("Rate, Repetition", 1, 1);
		EndIf;
		While Selection.Next() Do
			If Selection.OperationType=OperationType AND (ValueIsFilled(Selection.AccountDr) OR ValueIsFilled(Selection.AccountCr)) Then
				Budgeting = RegisterRecords.fmBudgeting.Add();
				// Дебетовая сторона проводки
				Budgeting.AccountDr= Selection.AccountDr;
				
				For Index = 1 To 3 Do
					fmBudgeting.SetSubconto(Budgeting.AccountDr, Budgeting.ExtDimensionsDr, Index, Selection[Selection["ExtDimensionDr"+Index]],,, Selection.ExtDimensionTypesDr.Unload());
				EndDo;
				
				If Selection.AccountDrCurrency Then
					Budgeting.CurrencyDr = Currency;
					Budgeting.CurrencyAmountDr = Selection.Amount * Selection.AmountCalculationRatio;
				EndIf;
				If Selection.AccountDrAccountingByProjects Then
					Budgeting.ProjectDr = Project;
				EndIf;
				If Selection.AccountDrFinancialResult Then
					Budgeting.DepartmentDr = Selection[Selection.PathDepartmentDr];
					Budgeting.ItemDr = Selection.Item;
				EndIf;
				
				//Кредитовая сторона проводки
				Budgeting.AccountCr= Selection.AccountCr;
				
				For Index = 1 To 3 Do
					fmBudgeting.SetSubconto(Budgeting.AccountCr, Budgeting.ExtDimensionsCr, Index, Selection[Selection["ExtDimensionCr"+Index]],,, Selection.ExtDimensionTypesCr.Unload());
				EndDo;
				
				If Selection.AccountCrCurrency Then
					Budgeting.CurrencyCr = Currency;
					Budgeting.CurrencyAmountCr = Selection.Amount * Selection.AmountCalculationRatio;
				EndIf;
				If Selection.AccountCrAccountingByProjects Then
					Budgeting.ProjectCr = Project;
				EndIf;
				If Selection.AccountCrFinancialResult Then
					Budgeting.DepartmentCr = Selection[Selection.PathDepartmentCr];
					Budgeting.ItemCr = Selection.Item;
				EndIf;
				// Общие реквизиты проводки
				Budgeting.Period= Selection.Period;
				Budgeting.Scenario= Scenario;
				Budgeting.PrimaryDocument = Ref;
				Budgeting.BalanceUnit = Selection[Selection.PathBalanceUnit];
				Budgeting.Amount = (Selection.Amount * Selection.AmountCalculationRatio) / CurCurrencyRate.Rate/CurCurrencyRate.Repetition;
				
			EndIf;
		EndDo;
		
		If OperationType = Enums.fmBudgetOperationTypes.IncomesAndExpenses Then
			
			// Доходы и расходы.
			IncomesAndExpenses = RegisterRecords.fmIncomesAndExpenses;
			
			// Измерения.
			RecordRow = IncomesAndExpenses.Add();
			RecordRow.Period            = IterationResult.Period;
			RecordRow.BalanceUnit = BalanceUnit;
			RecordRow.Scenario          = Scenario;
			RecordRow.PrimaryDocument = Ref;
			RecordRow.Department     = Department;
			RecordRow.Project            = Project;
			RecordRow.Currency            = Currency;
			RecordRow.Item            = IterationResult.Item;
			RecordRow.Analytics1        = IterationResult.Analytics1;
			RecordRow.Analytics2        = IterationResult.Analytics2;
			RecordRow.Analytics3        = IterationResult.Analytics3;
			RecordRow.OperationType       = IterationResult.RecordType;
			RecordRow.VersionPeriod      = IterationResult.VersionPeriod;
			
			// Ресурсы.
			If MatchCurrentVersion AND RecordRow.VersionPeriod=ActualVersion Then
				RecordRow.NotAgreedCurrencyAmount            = IterationResult.Amount;
				RecordRow.NotAgreedAmount = IterationResult.Amount / (CurCurrencyRate.Rate / CurCurrencyRate.Repetition);
			Else
				RecordRow.CurrencyAmount            = IterationResult.Amount;
				RecordRow.Amount = IterationResult.Amount / (CurCurrencyRate.Rate / CurCurrencyRate.Repetition);
			EndIf;
			
			// Реквизиты.
			RecordRow.CorBalanceUnit = IterationResult.CorBalanceUnit;
			RecordRow.CorDepartment = IterationResult.CorDepartment;
			
		ElsIf OperationType = Enums.fmBudgetOperationTypes.Cashflows Then
			
			// Движения денежных средств.
			Cashflows = RegisterRecords.fmCashflowBudget;
			
			// Измерения.
			RecordRow = Cashflows.Add();
			RecordRow.Period            = IterationResult.Period;
			RecordRow.BalanceUnit = BalanceUnit;
			RecordRow.Scenario          = Scenario;
			RecordRow.PrimaryDocument = Ref;
			RecordRow.Department     = Department;
			RecordRow.Project            = Project;
			RecordRow.Currency            = Currency;
			RecordRow.Item            = IterationResult.Item;
			RecordRow.Analytics1        = IterationResult.Analytics1;
			RecordRow.Analytics2        = IterationResult.Analytics2;
			RecordRow.Analytics3        = IterationResult.Analytics3;
			RecordRow.OperationType       = IterationResult.RecordType;
			RecordRow.VersionPeriod      = IterationResult.VersionPeriod;
			
			// Ресурсы.
			If MatchCurrentVersion AND RecordRow.VersionPeriod=ActualVersion Then
				RecordRow.NotAgreedCurrencyAmount            = IterationResult.Amount;
				RecordRow.NotAgreedAmount = IterationResult.Amount / (CurCurrencyRate.Rate / CurCurrencyRate.Repetition);
			Else
				RecordRow.CurrencyAmount            = IterationResult.Amount;
				RecordRow.Amount = IterationResult.Amount / (CurCurrencyRate.Rate / CurCurrencyRate.Repetition);
			EndIf;
			
		ElsIf OperationType = Enums.fmBudgetOperationTypes.InternalSettlements Then
			
			// Внутренние взаиморасчеты.
			IncomesAndExpenses = RegisterRecords.fmIncomesAndExpenses;
			
			// Доходная часть подразделения.
			// Измерения.
			RecordRow = IncomesAndExpenses.Add();
			RecordRow.Period            = IterationResult.Period;
			RecordRow.BalanceUnit = BalanceUnit;
			RecordRow.Scenario          = Scenario;
			RecordRow.PrimaryDocument = Ref;
			RecordRow.Department     = Department;
			RecordRow.Project            = Project;
			RecordRow.Currency            = Currency;
			RecordRow.Item            = IterationResult.Item;
			RecordRow.Analytics1        = IterationResult.Analytics1;
			RecordRow.Analytics2        = IterationResult.Analytics2;
			RecordRow.Analytics3        = IterationResult.Analytics3;
			RecordRow.VersionPeriod      = IterationResult.VersionPeriod;
			If ValueIsFilled(IterationResult.RecordType) Then
				RecordRow.OperationType = IterationResult.RecordType;
			Else
				RecordRow.OperationType = Enums.fmBudgetFlowOperationTypes.InnerExpenses;
			EndIf;
			
			// Ресурсы.
			If MatchCurrentVersion AND RecordRow.VersionPeriod=ActualVersion Then
				RecordRow.NotAgreedCurrencyAmount            = -1 * IterationResult.Amount;
				RecordRow.NotAgreedAmount = -1 * (IterationResult.Amount / (CurCurrencyRate.Rate / CurCurrencyRate.Repetition));
			Else
				RecordRow.CurrencyAmount            = -1 * IterationResult.Amount;
				RecordRow.Amount = -1 * (IterationResult.Amount / (CurCurrencyRate.Rate / CurCurrencyRate.Repetition));
			EndIf;
			
			// Реквизиты.
			RecordRow.CorBalanceUnit = IterationResult.CorBalanceUnit;
			RecordRow.CorDepartment = IterationResult.CorDepartment;
			RecordRow.CorProject = IterationResult.CorProject;
			RecordRow.CorItem = IterationResult.CorItem;
			RecordRow.AllocationStep = IterationResult.AllocationStep;
			
			// Расходная часть кор. подразделения.
			// Для сторно не делается.
			If IterationResult.StepType = Enums.fmBudgetAllocationStepTypes.ReversalOfPreviousVersionsAllocation Then
				Continue;
			EndIf;
			
			// Измерения.
			RecordRow = IncomesAndExpenses.Add();
			RecordRow.Period            = IterationResult.Period;
			RecordRow.BalanceUnit = IterationResult.CorBalanceUnit;
			RecordRow.Scenario          = Scenario;
			RecordRow.PrimaryDocument = Ref;
			RecordRow.Department     = IterationResult.CorDepartment;
			RecordRow.Project            = IterationResult.CorProject;
			RecordRow.Currency            = Currency;
			If ValueIsFilled(IterationResult.CorItem) Then
				RecordRow.Item            = IterationResult.CorItem;
				Selection = IterationResult.SELECT();
				Selection.Next();
				If ValueIsFilled(Selection.AnalyticsType1) AND Selection.AnalyticsType1.Types()[0]=TypeOf(IterationResult.Analytics1) Then
					RecordRow.Analytics1 = IterationResult.Analytics1;
				EndIf;
				If ValueIsFilled(Selection.AnalyticsType2) AND Selection.AnalyticsType2.Types()[0]=TypeOf(IterationResult.Analytics2) Then
					RecordRow.Analytics2 = IterationResult.Analytics2;
				EndIf;
				If ValueIsFilled(Selection.AnalyticsType3) AND Selection.AnalyticsType3.Types()[0]=TypeOf(IterationResult.Analytics3) Then
					RecordRow.Analytics3 = IterationResult.Analytics3;
				EndIf;
			Else
				RecordRow.Item            = IterationResult.Item;
				RecordRow.Analytics1        = IterationResult.Analytics1;
				RecordRow.Analytics2        = IterationResult.Analytics2;
				RecordRow.Analytics3        = IterationResult.Analytics3;
			EndIf;
			RecordRow.VersionPeriod      = IterationResult.VersionPeriod;
			If ValueIsFilled(IterationResult.RecordType) Then
				RecordRow.OperationType = IterationResult.RecordType;
			Else
				RecordRow.OperationType = Enums.fmBudgetFlowOperationTypes.InnerExpenses;
			EndIf;
			
			// Ресурсы.
			If MatchCurrentVersion AND RecordRow.VersionPeriod=ActualVersion Then
				RecordRow.NotAgreedCurrencyAmount = IterationResult.Amount;
				RecordRow.NotAgreedAmount = IterationResult.Amount / (CurCurrencyRate.Rate / CurCurrencyRate.Repetition);
			Else
				RecordRow.CurrencyAmount = IterationResult.Amount;
				RecordRow.Amount = IterationResult.Amount / (CurCurrencyRate.Rate / CurCurrencyRate.Repetition);
			EndIf;
			
			// Реквизиты.
			RecordRow.CorBalanceUnit = BalanceUnit;
			RecordRow.CorDepartment = Department;
			RecordRow.CorProject = Project;
			RecordRow.CorItem = ?(ValueIsFilled(IterationResult.CorItem), IterationResult.Item, IterationResult.CorItem);
			RecordRow.AllocationStep = IterationResult.AllocationStep;
			
		EndIf;
		
	EndDo;
	
	RegisterRecords.fmBudgeting.Write = True;
	RegisterRecords.fmCashflowBudget.Write = True;
	RegisterRecords.fmIncomesAndExpenses.Write = True;
	
EndProcedure

Procedure OnCopy(CopyObject)
	
	DATE              = Common.CurrentUserDate();
	Responsible     = Users.CurrentUser();
	ActualVersion = DATE("00010101");
	
	BudgetVersioning = Constants.fmBudgetVersioning.Get();
	If Scenario.ScenarioType=Enums.fmBudgetingScenarioTypes.Plan
	AND (BudgetVersioning=Enums.fmBudgetVersioning.EveryMonth
	OR BudgetVersioning=Enums.fmBudgetVersioning.EveryDay) Then
		TempBudgetsData = BudgetsData.Unload();
		TempBudgetsData.GroupBy("Period, RecordType, Item, CorItem, CorDepartment, Analytics1, Analytics2, Analytics3, CorBalanceUnit, CorProject", "Amount");
		BudgetsData.Load(TempBudgetsData);
		For Each CurRow In BudgetsData Do
			If BudgetVersioning=Enums.fmBudgetVersioning.EveryMonth Then
				CurRow.VersionPeriod = BegOfMonth(CurrentSessionDate());
			Else
				CurRow.VersionPeriod = BegOfDay(CurrentSessionDate());
			EndIf;
		EndDo;
	EndIf;
	
EndProcedure

Procedure BeforeWrite(Cancel, WriteMode, PostingMode)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	// Заполним итоговые реквизиты
	TotalAmount 					= BudgetsData.Total("Amount");
	
EndProcedure

Procedure Filling(FillingData, FillingText, StandardProcessing)
	// en script begin
	//ЗаполнениеДокументов.Заполнить(ЭтотОбъект, ДанныеЗаполнения);
	Responsible = Users.CurrentUser();
	Scenario = Catalogs.fmBudgetingScenarios.Plan;
	// en script end
	Currency = Constants.fmCurrencyOfManAccounting.Get();
	BeginOfPeriod = EndOfYear(CurrentSessionDate())+1;
	// Курсы валют.
	fmCurrencyRatesProcessing.FormTableOfCurrencyRates(CurrencyRates, Currency, BeginOfPeriod, Scenario);
	fmBudgeting.BalanceUnitDepartmentCompatible(BalanceUnit, Department, BeginOfPeriod, "Department");
EndProcedure

Procedure FillCheckProcessing(Cancel, CheckingAttributes)
	If OperationType=Enums.fmBudgetOperationTypes.InternalSettlements Then
		DeletedAttributesArray = New Array();
		DeletedAttributesArray.Add("BudgetsData.RecordType");
		fmCommonUseServerCall.DeleteNoCheckAttributesFromArray(CheckingAttributes, DeletedAttributesArray);
	Else
		DeletedAttributesArray = New Array();
		DeletedAttributesArray.Add("BudgetsData.CorDepartment");
		fmCommonUseServerCall.DeleteNoCheckAttributesFromArray(CheckingAttributes, DeletedAttributesArray);
	EndIf;
EndProcedure

#EndRegion

#EndIf
