
// <Описание функции>
//
Function BeginOfPeriod(DATE, PeriodType)

	If PeriodType = Enums.fmAvailableReportPeriods.Year Then
		Return BegOfYear(DATE);
	ElsIf PeriodType = Enums.fmAvailableReportPeriods.Quarter Then
		Return BegOfQuarter(DATE);
	ElsIf PeriodType = Enums.fmAvailableReportPeriods.Month Then
		Return BegOfMonth(DATE);
	Else
		Return DATE;
	EndIf;
	
EndFunction // НачалоПериода()

// <Описание функции>
//
Function EndOfPeriod(DATE, PeriodType)

	If PeriodType = Enums.fmAvailableReportPeriods.Year Then
		Return EndOfYear(DATE);
	ElsIf PeriodType = Enums.fmAvailableReportPeriods.Quarter Then
		Return EndOfQuarter(DATE);
	ElsIf PeriodType = Enums.fmAvailableReportPeriods.Month Then
		Return EndOfMonth(DATE);
	Else
		Return DATE;
	EndIf;
	
EndFunction // КонецПериода()

// <Описание функции>
//
Function MonthInPeriod(PeriodType)

	If PeriodType = Enums.fmAvailableReportPeriods.Year Then
		Return 12;
	ElsIf PeriodType = Enums.fmAvailableReportPeriods.Quarter Then
		Return 3;
	ElsIf PeriodType = Enums.fmAvailableReportPeriods.Month Then
		Return 1;
	Else
		Return 0;
	EndIf;
	
EndFunction // КонецПериода()


////////////////////////////////////////////////////////////////////////////////
// ЭКСПОРТНЫЕ МЕТОДЫ

Procedure DistributeIncomesAndExpenses() Export
	
	// Что нужно для распределения
	// НачалоПериода должно соответствовать периоду планирования
	// ОкончаниеПериода должно соответствовать периоду планирования
	// Периодичность должна быть = МЕСЯЦ!
	
	// Определим версию бюджетов для распределения.
	If BudgetingScenario.ScenarioType=Enums.fmBudgetingScenarioTypes.Plan Then
		If Constants.fmBudgetVersioning.Get()=Enums.fmBudgetVersioning.EveryMonth Then
			DistributionVersion = BegOfMonth(CurrentSessionDate());
		Else
			DistributionVersion = BegOfDay(CurrentSessionDate());
		EndIf;
	Else
		DistributionVersion = DATE("00010101");
	EndIf;
	
	NoErrors = True;
	For Each NextStep In BudgetsDistributionSteps Do
		
		// Проверка активности шага.
		If NOT NextStep.Active Then Continue; EndIf;
		
		CurDistributionStep = NextStep.BudgetDistributionStep;
		If CurDistributionStep.StepType = Enums.fmBudgetAllocationStepTypes.DistributionBaseAssemble Then
			
			// Сбор базы.
			Query = New Query;
			Query.Text = "SELECT
			|	DistributionBases.Ref,
			|	DistributionBases.DistributionDepartment,
			|	DistributionBases.DistributionItem,
			|	DistributionBases.DistributionProject,
			|	BeginOfPeriod(DistributionBases.DATE, Month) AS BeginDate,
			|	EndOfPeriod(DistributionBases.EndDate, Month) AS EndDate
			|FROM
			|	Document.fmBudgetsDistributionBases AS DistributionBases
			|WHERE
			|	DistributionBases.BudgetDistributionStep = &BudgetDistributionStep
			|	AND NOT DistributionBases.DeletionMark
			|	AND DistributionBases.OperationType = Value(Enum.fmDistributionBaseOperationTypes.CalculatedBase)
			|	AND DistributionBases.DATE Between &BeginOfPeriod AND &EndOfPeriod
			|	AND DistributionBases.EndDate Between &BeginOfPeriod AND &EndOfPeriod
			|	AND DistributionBases.BalanceUnit = &BalanceUnit
			|	AND DistributionBases.DistributionBase = &DistributionBase
			|	AND DistributionBases.Scenario = &Scenario";
			
			Query.SetParameter("BeginOfPeriod", BeginOfPeriod);
			Query.SetParameter("EndOfPeriod", EndOfDay(EndOfPeriod) );
			Query.SetParameter("BalanceUnit", BalanceUnit);
			Query.SetParameter("DistributionBase", CurDistributionStep.DistributionBase);
			Query.SetParameter("BudgetDistributionStep", CurDistributionStep.Ref);
			Query.SetParameter("Scenario", CurDistributionStep.BudgetingScenario);
			Query.SetParameter("CurrentStepNumber", CurDistributionStep.Order);
			
			StepBatchResultBasesAssemble = Query.Execute();
			BasesDocumentsCreatedEarlier = StepBatchResultBasesAssemble.Unload();
			BasesDocumentsCreatedEarlier.Columns.Add("Processed", New TypeDescription("Boolean") );
			BasesDocumentsCreatedEarlier.Indexes.Add("DistributionItem, Processed, BeginDate, EndDate");
			
			// Параметры запроса базы.
			BaseQueryParameter = New Structure();
			BaseQueryParameter.Insert("BeginOfPeriod",BeginOfPeriod);
			BaseQueryParameter.Insert("EndOfPeriod", EndOfDay(EndOfPeriod) );
			BaseQueryParameter.Insert("BalanceUnit", BalanceUnit);
			BalanceDate = New Boundary(EndOfDay(EndOfPeriod), BoundaryType.Including);
			BaseQueryParameter.Insert("BalanceDate", BalanceDate);
			BaseHeader = New Structure("DistributionDepartment, DistributionProject, Scenario", 
				CurDistributionStep.DepartmentTurnover, Catalogs.fmProjects.EmptyRef(), CurDistributionStep.BudgetingScenario);
			ItemsFromStep = CurDistributionStep.ItemsTurnover.UnloadColumn("ItemTurnover");
			If ItemsFromStep.Count() = 0 Then
				ItemsFromStep.Add(Catalogs.fmIncomesAndExpensesItems.EmptyRef());
			EndIf;
			
			// Периоды
			PeriodsTable = New ValueTable;
			PeriodsTable.Columns.Add("BeginDate");
			PeriodsTable.Columns.Add("EndDate");
			If CurDistributionStep.DistributionBasePeriodicity = Enums.fmAvailableReportPeriods.Year Then
				NewLine = PeriodsTable.Add();
				NewLine.BeginDate = BeginOfPeriod;
				NewLine.EndDate = EndOfPeriod;
			Else
				NextBeginOfPeriod = BeginOfPeriod;
				LastBegOfPeriod = BeginOfPeriod(EndOfPeriod, CurDistributionStep.DistributionBasePeriodicity);
				While NextBeginOfPeriod <= LastBegOfPeriod Do
					NewLine = PeriodsTable.Add();
					NewLine.BeginDate = NextBeginOfPeriod;
					NewLine.EndDate = EndOfPeriod(NextBeginOfPeriod, CurDistributionStep.DistributionBasePeriodicity);
					NextBeginOfPeriod = AddMonth(NextBeginOfPeriod, MonthInPeriod(CurDistributionStep.DistributionBasePeriodicity));
				EndDo;
			EndIf;
			
			// список, в котором есть дата нач, дата ок.
			DocumentSearchStructure = New Structure("DistributionItem, Processed", , False);
			DocumentSearchStructureWithDates = New Structure("DistributionItem, Processed, BeginDate, EndDate", , False, , );
			
			// Ищем документ только по статье, "лишние" документы удаляем.
			For Each NextItem In ItemsFromStep Do
				
				DocumentSearchStructure.DistributionItem = NextItem;
				DocumentSearchStructureWithDates.DistributionItem = NextItem;
				
				// Цикл по периодам баз
				For Each NextPeriod In PeriodsTable Do
					
					FillPropertyValues(DocumentSearchStructureWithDates, NextPeriod, "BeginDate, EndDate");
					FoundRowsWithDates = BasesDocumentsCreatedEarlier.FindRows(DocumentSearchStructureWithDates);
					If FoundRowsWithDates.Count() <> 0 Then
						// Найден документ с учетом дат.
						BaseDocument = FoundRowsWithDates[0].Ref.GetObject();
						FoundRowsWithDates[0].Processed = True;
					Else
						// Не нашли. Поищем без учета дат.
						FoundRows = BasesDocumentsCreatedEarlier.FindRows(DocumentSearchStructure);
						If FoundRows.Count() = 0 Then
							BaseDocument = Documents.fmBudgetsDistributionBases.CreateDocument();
							BaseDocument.OperationType = Enums.fmDistributionBaseOperationTypes.CalculatedBase;
						Else
							BaseDocument = FoundRows[0].Ref.GetObject();
							FoundRows[0].Processed = True;
						EndIf;
						// Нашли, либо создали без учета дат: пропишем даты в шапку.
						BaseDocument.DATE = NextPeriod.BeginDate;
						BaseDocument.EndDate = NextPeriod.EndDate;
					EndIf;
					
					// С учетом дат.
					FillPropertyValues(BaseDocument, BaseHeader);
					BaseDocument.DistributionItem = NextItem;
					BaseDocument.BudgetDistributionStep = CurDistributionStep.Ref;
					BaseDocument.BalanceUnit = BalanceUnit;
					BaseDocument.DistributionBase = CurDistributionStep.DistributionBase;
					
					BaseQueryParameter.Insert("BaseBeginOfPeriod", NextPeriod.BeginDate);
					BaseQueryParameter.Insert("BaseEndOfPeriod", NextPeriod.EndDate);
					Try
						DataProcessors.fmBudgetingDataAllocation.FillDistributionBase(BaseDocument, BaseQueryParameter);
					Except
						CommonClientServer.MessageToUser(NStr("en='Error occurred while filling the base:';ru='Ошибка запроса заполнения базы: '") + CurDistributionStep.Ref + Chars.LF + ErrorDescription());
					EndTry;
					
					Try
						BaseDocument.Write(DocumentWriteMode.Posting);
					Except
						CommonClientServer.MessageToUser(StrTemplate(NStr("en='Failed to create allocation base <%1> due to: %2';ru='Не удалось создать базу распределения <%1> по причине: %2'"), CurDistributionStep.DistributionBase, ErrorDescription()));
					EndTry;
					
				EndDo;
				
			EndDo;
			
			FoundDocumentsToDeletion = BasesDocumentsCreatedEarlier.FindRows(New Structure("Processed", False));
			For Each NextRowToDeletion In FoundDocumentsToDeletion Do
				DocToDel = NextRowToDeletion.Ref.GetObject();
				DocToDel.SetDeletionMark(True);
			EndDo;
			
		Else
			
			// Шаги распределения
			StepItems = CurDistributionStep.ItemsTurnover.UnloadColumn("ItemTurnover");
			
			// Исполняем запрос, который возвратит:
			// 1. Документы-счета, в которые впишем строки. Если их нет, создадим.
			// 2. Бюджеты и подобранные к ним базы.
			Query = New Query;
			Query.SetParameter("BeginOfPeriod", BeginOfPeriod);
			Query.SetParameter("EndOfPeriod", EndOfPeriod);
			Query.SetParameter("DistributionVersion", DistributionVersion);
			Query.SetParameter("Scenario", BudgetingScenario);
			Query.SetParameter("Department", CurDistributionStep.DepartmentTurnover);
			Query.SetParameter("Item", StepItems);
			Query.SetParameter("RecordType", CurDistributionStep.BudgetSection);
			RecordTypes = New Array();
			RecordTypes.Add(CurDistributionStep.BudgetSection);
			If CurDistributionStep.BudgetSection=Enums.fmBudgetFlowOperationTypes.Incomes Then
				RecordTypes.Add(Enums.fmBudgetFlowOperationTypes.InnerIncomes);
			ElsIf CurDistributionStep.BudgetSection=Enums.fmBudgetFlowOperationTypes.Expenses Then
				RecordTypes.Add(Enums.fmBudgetFlowOperationTypes.InnerExpenses);
			EndIf;
			Query.SetParameter("RecordTypes", RecordTypes);
			Query.SetParameter("BalanceUnit", BalanceUnit);
			Query.SetParameter("DistributionBase", CurDistributionStep.DistributionBase);
			Query.SetParameter("CurrentStepNumber", CurDistributionStep.Order);
			Query.SetParameter("RecipientDepartment", CurDistributionStep.RecipientDepartment);
			StepProjects = New Array;
			EmptyProjectFilter = False;
			For Each ProjectFromStep In CurDistributionStep.ProjectsTurnover Do
				If NOT ValueIsFilled(ProjectFromStep.ProjectTurnover) Then
					EmptyProjectFilter = True;
				Else
					StepProjects.Add(ProjectFromStep.ProjectTurnover);
				EndIf;
			EndDo;
			Query.SetParameter("EmptyProjectFilter", EmptyProjectFilter);
			Query.SetParameter("Project", StepProjects);
			
			Query.Text = GetDistributionQueryText(CurDistributionStep, DistributionVersion);
			BathResult = Query.ExecuteBatch();
			
			// Документ-получатель
			// Очистим существующие распределения по проектам
			DocumentsSelection = BathResult[0].SELECT();
			DocumentsBudgetToPost = New Array;
			While DocumentsSelection.Next() Do
				
				DocumentObject = DocumentsSelection.Ref.GetObject();
				
				// Очистим строки со статьей-получателем
				RowsWithRecipientItem = DocumentObject.BudgetsData.FindRows(New Structure("AllocationStep, VersionPeriod", CurDistributionStep.Ref, DistributionVersion));
				For Each RowDel In RowsWithRecipientItem Do
					DocumentObject.BudgetsData.Delete(RowDel);
				EndDo;
				
				If RowsWithRecipientItem.Count() Then
					Try
						DocumentObject.Write(DocumentWriteMode.Posting);
					Except
						CommonClientServer.MessageToUser(NStr("en='Error occurred while clearing the current allocation:';ru='Ошибка при очистке существующего распределения: '") + ErrorDescription());
					EndTry;
				EndIf;
				
			EndDo;
			
			If CurDistributionStep.StepType = Enums.fmBudgetAllocationStepTypes.DistributionByBasesOnDepartments
			OR CurDistributionStep.StepType = Enums.fmBudgetAllocationStepTypes.DistributionByBasesOnProjects Then
				If BathResult[10].IsEmpty() Then
					MainBatchNumber = 8;
				Else
					MainBatchNumber = 13;
				EndIf;
			ElsIf CurDistributionStep.StepType = Enums.fmBudgetAllocationStepTypes.ReversalOfPreviousVersionsAllocation Then
				MainBatchNumber = 1;
			Else
				// Рекласс.
				MainBatchNumber = 5;
			EndIf;
			
			SelectionPeriods = BathResult[MainBatchNumber].SELECT(QueryResultIteration.ByGroups);
			While SelectionPeriods.Next() Do
				
				VersionSelection = SelectionPeriods.SELECT(QueryResultIteration.ByGroups);
				While VersionSelection.Next() Do
					DepartmentSelection = VersionSelection.SELECT(QueryResultIteration.ByGroups);
					While DepartmentSelection.Next() Do
						
						// Подразделение, с которого распределяем.
						CurDepartmentToDistribute = DepartmentSelection.Department;
						If NOT ValueIsFilled(CurDepartmentToDistribute) Then
							Continue;
						EndIf;
						
						SelectionProjects = DepartmentSelection.SELECT(QueryResultIteration.ByGroups);
						
						// Борьба с копейками при распределении на подразделения
						If CurDistributionStep.StepType = Enums.fmBudgetAllocationStepTypes.DistributionByBasesOnDepartments Then
							AccumulatedAmount = 0;
							MaxAmount = 0;
							RowWithMaxAmount = Undefined;
							AmountToDistribute = 0;
						EndIf;
						
						CurItem = Undefined;
						
						While SelectionProjects.Next() Do
							
							// Проект, с которого распределяем.
							CurProjectToDistribute = SelectionProjects.Project;
							
							// Найти/создать документ распеределения
							// Найти документ бюджет по соответствующему проекту, который поместим в переменную "ДокументОбъект".
							// Самое производительное с точки зрения работы с выборками - обойти руками выборку без функций поиска.
							NewCreated = False;
							
							// Ищем документ по подразделению, проекту, подлежащим распределению.
							DocumentsSelection.Reset();
							
							DocumentObject = Undefined;
							If DocumentsSelection.FindNext(New Structure("Department, Project",CurDepartmentToDistribute, CurProjectToDistribute ) ) Then
								DocumentObject = DocumentsSelection.Ref.GetObject();
							EndIf;
							
							If DocumentObject = Undefined Then
								
								// Создадим
								NewCreated = True;
								
								DocumentObject = Documents.fmBudget.CreateDocument();
								DocumentObject.Currency = Constants.fmCurrencyOfManAccounting.Get();
								DocumentObject.ActualVersion = DistributionVersion;
								DocumentObject.DATE = CurrentSessionDate();
								DocumentObject.Scenario = BudgetingScenario;
								DocumentObject.BeginOfPeriod = BeginOfPeriod;
								DocumentObject.OperationType = Enums.fmBudgetOperationTypes.InternalSettlements;
								DocumentObject.Department = CurDepartmentToDistribute;
								DocumentObject.BalanceUnit = BalanceUnit;
								DocumentObject.Project = CurProjectToDistribute;
								DocumentObject.Allocation = True;
								DocumentObject.Responsible = Users.CurrentUser();
								// ТЧ курсов
								fmCurrencyRatesProcessing.FormTableOfCurrencyRates(DocumentObject.CurrencyRates, DocumentObject.Currency, DocumentObject.BeginOfPeriod, DocumentObject.Scenario);
								
							EndIf;
							
							Selection = SelectionProjects.SELECT();
							While Selection.Next() Do
								
								If Selection.BaseDepartment = NULL Then
									CommonClientServer.MessageToUser(StrTemplate(NStr("en='While allocating the budget at step %1 as of %2, base value %3 was not found.';ru='При распределении бюджета на шаге %1 за %2 не найдено значение базы %3.'"), CurDistributionStep.Ref, PeriodPresentation(Selection.Period, EndOfMonth(Selection.Period)), CurDistributionStep.DistributionBase));
									NoErrors = False;
									Continue;
								EndIf;
								
								If CurDistributionStep.StepType = Enums.fmBudgetAllocationStepTypes.DistributionByBasesOnDepartments
								AND ValueIsFilled(CurDistributionStep.AggregationItem) AND CurItem <> Selection.Item Then
									
									// Накинуть копейки на строку.
									If AmountToDistribute <> AccumulatedAmount AND RowWithMaxAmount <> Undefined Then
										RowWithMaxAmount.Amount = RowWithMaxAmount.Amount + AmountToDistribute - AccumulatedAmount;
									EndIf;
									
									// Обнулить копейки
									AccumulatedAmount = 0;
									MaxAmount = 0;
									RowWithMaxAmount = Undefined;
									AmountToDistribute = 0;
									
									// Присвоить статью
									CurItem = Selection.Item;
									
								EndIf;
								
								ServiceRow = DocumentObject.BudgetsData.Add();
								ServiceRow.Period = Selection.Period;
								If ValueIsFilled(Selection.BaseDepartment) Then
									ServiceRow.CorDepartment = Selection.BaseDepartment;
									ServiceRow.CorBalanceUnit = ServiceRow.CorDepartment.BalanceUnit;
								Else
									ServiceRow.CorDepartment = Selection.Department;
									ServiceRow.CorBalanceUnit	= Selection.BalanceUnit;
								EndIf;
								
								ServiceRow.Item = Selection.Item;
								ServiceRow.Analytics1 = Selection.Analytics1;
								ServiceRow.Analytics2 = Selection.Analytics2;
								ServiceRow.Analytics3 = Selection.Analytics3;
								If CurDistributionStep.StepType = Enums.fmBudgetAllocationStepTypes.ReversalOfPreviousVersionsAllocation Then
									ServiceRow.CorItem = Selection.CorItem;
								ElsIf ValueIsFilled(CurDistributionStep.AggregationItem) Then
									ServiceRow.CorItem = CurDistributionStep.AggregationItem;
								Else
									ServiceRow.CorItem = Selection.Item;
								EndIf;
								If CurDistributionStep.StepType = Enums.fmBudgetAllocationStepTypes.DistributionByBasesOnDepartments Then
									ServiceRow.CorProject = Selection.Project;
								Else
									ServiceRow.CorProject = Selection.BaseProject;
								EndIf;
								If CurDistributionStep.StepType = Enums.fmBudgetAllocationStepTypes.ReversalOfPreviousVersionsAllocation Then
									ServiceRow.Amount = -Selection.AmountPart;
								Else
									ServiceRow.Amount = Selection.AmountPart;
								EndIf;
								
								// Борьба с копейками при распределении на подразделения
								CurAmount = ServiceRow.Amount;
								
								If Selection.OperationType=Enums.fmBudgetFlowOperationTypes.Expenses Then
									ServiceRow.RecordType = Enums.fmBudgetFlowOperationTypes.InnerExpenses;
								ElsIf Selection.OperationType=Enums.fmBudgetFlowOperationTypes.Incomes Then
									ServiceRow.RecordType = Enums.fmBudgetFlowOperationTypes.InnerIncomes;
								Else
									ServiceRow.RecordType = Selection.OperationType;
								EndIf;
								ServiceRow.AllocationStep = CurDistributionStep.Ref;
								ServiceRow.VersionPeriod = Selection.VersionPeriod;
								
								// Борьба с копейками при распределении на подразделения
								If CurDistributionStep.StepType = Enums.fmBudgetAllocationStepTypes.DistributionByBasesOnDepartments Then
									AccumulatedAmount = AccumulatedAmount + CurAmount;
									If CurAmount > MaxAmount Then
										MaxAmount = CurAmount;
										RowWithMaxAmount = ServiceRow;
									EndIf;
									AmountToDistribute = Selection.AmountTurnover;
								EndIf;
								
							EndDo;
								
							// Борьба с копейками при распределении на подразделения (отдельно для каждого периода)
							If CurDistributionStep.StepType = Enums.fmBudgetAllocationStepTypes.DistributionByBasesOnDepartments Then
								If AmountToDistribute <> AccumulatedAmount AND RowWithMaxAmount <> Undefined Then
									RowWithMaxAmount.Amount = RowWithMaxAmount.Amount + AmountToDistribute - AccumulatedAmount;
								EndIf;
							EndIf;
							
							// Проведем документ
							Try
								DocumentObject.Write(DocumentWriteMode.Posting);
							Except
								NoErrors = False;
								CommonClientServer.MessageToUser(NStr("en='Error occurred while writing allocation';ru='Ошибка записи распределения '") + ErrorDescription());
							EndTry;
							
						EndDo;
						
					EndDo;
					
				EndDo;
				
			EndDo;
			
			// Если нет исходных данных для бюджета, то новый документ - не записываем.
			// Существующий - записываем, чтобы обнулить составляющую по статье из шага.
			If BathResult[MainBatchNumber].IsEmpty() Then
				CommonClientServer.MessageToUser(StrTemplate(NStr("en='No initial data for the budget calculation is found step: %1 period: %2.';ru='Не найдено исходных данных для расчета бюджета шаг: %1 период: %2.'"), CurDistributionStep.Ref, PeriodPresentation(BeginOfPeriod, EndOfPeriod)));
				NoErrors = False;
			EndIf;
			
		EndIf; // Виды шагов
			
	EndDo;
	
	CommonClientServer.MessageToUser(NStr("en='Budget allocation is completed';ru='Распределение бюджета выполнено'") + ?(NoErrors = False, NStr("en=' with errors!';ru=' с ошибками!'"), "."));
	
EndProcedure // РаспределитьДоходыИРасходы()

// <Описание процедуры>
//
Procedure CancelDistribution() Export
	
	// Удаляем только то, что относится к версии.
	If BudgetingScenario.ScenarioType=Enums.fmBudgetingScenarioTypes.Plan Then
		If Constants.fmBudgetVersioning.Get()=Enums.fmBudgetVersioning.EveryMonth Then
			DistributionVersion = BegOfMonth(CurrentSessionDate());
		Else
			DistributionVersion = BegOfDay(CurrentSessionDate());
		EndIf;
	Else
		DistributionVersion = DATE("00010101");
	EndIf;
	
	For Each NextStep In BudgetsDistributionSteps Do
		
		// Проверка активности шага.
		If NOT NextStep.Active Then Continue; EndIf;
		
		CurDistributionStep = NextStep.BudgetDistributionStep;
		
		StepItems = CurDistributionStep.ItemsTurnover.UnloadColumn("ItemTurnover");
		
		Query = New Query;
		Query.SetParameter("BeginOfPeriod", BeginOfPeriod);
		Query.SetParameter("Scenario", BudgetingScenario);
		Query.SetParameter("Department", CurDistributionStep.DepartmentTurnover);
		
		Query.Text = "SELECT
		|	fmBudget.Ref,
		|	fmBudget.BeginOfPeriod,
		|	fmBudget.Posted,
		|	fmBudget.Department,
		|	fmBudget.OperationType
		|FROM
		|	Document.fmBudget AS fmBudget
		|WHERE
		|	fmBudget.Posted
		|	AND fmBudget.BeginOfPeriod = &BeginOfPeriod
		|	AND fmBudget.OperationType = Value(Enum.fmBudgetOperationTypes.InternalSettlements)
		|	AND fmBudget.Scenario = &Scenario
		|	AND fmBudget.Allocation
		|	AND fmBudget.Department = &Department";
		
		If CurDistributionStep.StepType = Enums.fmBudgetAllocationStepTypes.ReversalOfPreviousVersionsAllocation Then
			Query.Text = StrReplace(Query.Text, "AND fmBudget.Department = &Department", "");
		EndIf;
		
		// Выполним
		DocumentsSelection = Query.Execute().SELECT();
		While DocumentsSelection.Next() Do
			
			DocumentObject = DocumentsSelection.Ref.GetObject();
			
			// Очистим строки со статьей-получателем
			RowsWithRecipientItem = DocumentObject.BudgetsData.FindRows(New Structure("AllocationStep, VersionPeriod", CurDistributionStep.Ref, DistributionVersion));
			DocumentWasChanged = False;
			For Each RowDel In RowsWithRecipientItem Do
				DocumentObject.BudgetsData.Delete(RowDel);
				DocumentWasChanged = True;
			EndDo;
			
			If DocumentWasChanged Then
				Try
					DocumentObject.Write(DocumentWriteMode.Posting);
				Except
					NoErrors = False;
					CommonClientServer.MessageToUser(ErrorDescription());
				EndTry;
			EndIf;
			
		EndDo;
		
	EndDo;
	
EndProcedure // ОтменитьРаспределение()

// <Описание функции>
//
Function GetDistributionQueryText(CurDistributionStep, DistributionVersion)
	
	StepType = CurDistributionStep.StepType;
	StepItems = CurDistributionStep.ItemsTurnover.UnloadColumn("ItemTurnover");
	
	If StepType = Enums.fmBudgetAllocationStepTypes.ReversalOfPreviousVersionsAllocation Then
		
		QueryText = 
			"SELECT
			|	fmBudget.Ref,
			|	fmBudget.BeginOfPeriod,
			|	fmBudget.Posted,
			|	fmBudget.Department,
			|	fmBudget.Project AS Project,
			|	fmBudget.OperationType
			|FROM
			|	Document.fmBudget AS fmBudget
			|WHERE
			|	fmBudget.Posted
			|	AND fmBudget.BeginOfPeriod = &BeginOfPeriod
			|	AND fmBudget.OperationType = Value(Enum.fmBudgetOperationTypes.InternalSettlements)
			|	AND fmBudget.Scenario = &Scenario
			|	AND fmBudget.Allocation
			|	AND fmBudget.BalanceUnit = &BalanceUnit
			|;
			|
			|////////////////////////////////////////////////////////////////////////////////
			|SELECT
			|	BeginOfPeriod(fmIncomesAndExpenses.Period, Month) AS Period,
			|	fmIncomesAndExpenses.Department AS Department,
			|	fmIncomesAndExpenses.BalanceUnit,
			|	fmIncomesAndExpenses.OperationType,
			|	fmIncomesAndExpenses.Item AS Item,
			|	fmIncomesAndExpenses.Analytics1 AS Analytics1,
			|	fmIncomesAndExpenses.Analytics2 AS Analytics2,
			|	fmIncomesAndExpenses.Analytics3 AS Analytics3,
			|	fmIncomesAndExpenses.Project AS Project,
			|	&DistributionVersion AS VersionPeriod,
			|	SUM(fmIncomesAndExpenses.Amount) AS AmountTurnover,
			|	SUM(fmIncomesAndExpenses.Amount) AS AmountPart,
			|	fmIncomesAndExpenses.CorBalanceUnit,
			|	fmIncomesAndExpenses.CorDepartment AS BaseDepartment,
			|	fmIncomesAndExpenses.CorItem AS CorItem,
			|	fmIncomesAndExpenses.CorProject AS BaseProject
			|FROM
			|	AccumulationRegister.fmIncomesAndExpenses AS fmIncomesAndExpenses
			|WHERE
			|	fmIncomesAndExpenses.Period Between &BeginOfPeriod AND &EndOfPeriod
			|	AND fmIncomesAndExpenses.Scenario = &Scenario
			|	AND fmIncomesAndExpenses.BalanceUnit = &BalanceUnit
			|	AND fmIncomesAndExpenses.AllocationStep <> Value(Catalog.fmBudgetDistributionSteps.EmptyRef)
			|	AND fmIncomesAndExpenses.VersionPeriod < &DistributionVersion
			|
			|Group BY
			|	BeginOfPeriod(fmIncomesAndExpenses.Period, Month),
			|	fmIncomesAndExpenses.Department,
			|	fmIncomesAndExpenses.BalanceUnit,
			|	fmIncomesAndExpenses.OperationType,
			|	fmIncomesAndExpenses.Item,
			|	fmIncomesAndExpenses.Analytics1,
			|	fmIncomesAndExpenses.Analytics2,
			|	fmIncomesAndExpenses.Analytics3,
			|	fmIncomesAndExpenses.Project,
			|	fmIncomesAndExpenses.CorBalanceUnit,
			|	fmIncomesAndExpenses.CorDepartment,
			|	fmIncomesAndExpenses.CorItem,
			|	fmIncomesAndExpenses.CorProject
			|
			|HAVING
			|	SUM(fmIncomesAndExpenses.Amount) <> 0
			|
			|ORDER BY
			|	Period,
			|	Project
			|TOTALS BY
			|	Period,
			|	VersionPeriod,
			|	Department,
			|	Project";
		
		If NOT ValueIsFilled(DistributionVersion) Then
			QueryText = StrReplace(QueryText, "AND fmIncomesAndExpenses.VersionPeriod < &DistributionVersion", "");
		EndIf;
		
		Return QueryText;
		
	EndIf;
	
	QueryText = 
		"SELECT
		|	fmBudget.Ref,
		|	fmBudget.BeginOfPeriod,
		|	fmBudget.Posted,
		|	fmBudget.Department,
		|	fmBudget.Project,
		|	fmBudget.OperationType
		|FROM
		|	Document.fmBudget AS fmBudget
		|WHERE
		|	fmBudget.Posted
		|	AND fmBudget.BeginOfPeriod = &BeginOfPeriod
		|	AND fmBudget.OperationType = Value(Enum.fmBudgetOperationTypes.InternalSettlements)
		|	AND fmBudget.Scenario = &Scenario
		|	AND fmBudget.Allocation
		|	AND fmBudget.Department = &Department
		|
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	BeginOfPeriod(fmIncomesAndExpenses.Period, Month) AS Period,
		|	fmIncomesAndExpenses.Department AS Department,
		|	fmIncomesAndExpenses.BalanceUnit,
		|	&RecordType AS OperationType,
		|	fmIncomesAndExpenses.Item AS Item,
		|	fmIncomesAndExpenses.Analytics1 AS Analytics1,
		|	fmIncomesAndExpenses.Analytics2 AS Analytics2,
		|	fmIncomesAndExpenses.Analytics3 AS Analytics3,
		|	fmIncomesAndExpenses.Project AS Project,
		|	&DistributionVersion AS VersionPeriod,
		|	SUM(fmIncomesAndExpenses.Amount) AS AmountTurnover
		|INTO ToBeDistributed
		|FROM
		|	AccumulationRegister.fmIncomesAndExpenses AS fmIncomesAndExpenses
		|WHERE
		|	fmIncomesAndExpenses.Period Between &BeginOfPeriod AND &EndOfPeriod
		|	AND fmIncomesAndExpenses.Scenario = &Scenario
		|	AND fmIncomesAndExpenses.OperationType IN (&RecordTypes)
		|	AND fmIncomesAndExpenses.BalanceUnit = &BalanceUnit
		|	AND fmIncomesAndExpenses.Department = &Department
		|	AND fmIncomesAndExpenses.Item IN(&Item)
		|	AND (&EmptyProjectFilter AND fmIncomesAndExpenses.Project = Value(Catalog.fmProjects.EmptyRef) OR fmIncomesAndExpenses.Project IN(&Project))
		|	AND (fmIncomesAndExpenses.AllocationStep = Value(Catalog.fmBudgetDistributionSteps.EmptyRef) 	// Берем введенные руками бюджеты
		|	OR (fmIncomesAndExpenses.VersionPeriod < &DistributionVersion AND fmIncomesAndExpenses.AllocationStep <> Value(Catalog.fmBudgetDistributionSteps.EmptyRef))
		|	OR (fmIncomesAndExpenses.VersionPeriod = &DistributionVersion AND fmIncomesAndExpenses.AllocationStep <> Value(Catalog.fmBudgetDistributionSteps.EmptyRef) AND fmIncomesAndExpenses.AllocationStep.Order < &CurrentStepNumber)
		|	)
		|
		|Group BY
		|	BeginOfPeriod(fmIncomesAndExpenses.Period, Month),
		|	fmIncomesAndExpenses.Department,
		|	fmIncomesAndExpenses.BalanceUnit,
		|	fmIncomesAndExpenses.OperationType,
		|	fmIncomesAndExpenses.Item,
		|	fmIncomesAndExpenses.Analytics1,
		|	fmIncomesAndExpenses.Analytics2,
		|	fmIncomesAndExpenses.Analytics3,
		|	fmIncomesAndExpenses.Project
		|INDEX BY
		|	Period,
		|	Department,
		|	Item 
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	0 AS Digit
		|INTO DigitTab
		|
		|UNION
		|
		|SELECT
		|	1
		|
		|UNION
		|
		|SELECT
		|	2
		|
		|UNION
		|
		|SELECT
		|	3
		|
		|UNION
		|
		|SELECT
		|	4
		|
		|UNION
		|
		|SELECT
		|	5
		|
		|UNION
		|
		|SELECT
		|	6
		|
		|UNION
		|
		|SELECT
		|	7
		|
		|UNION
		|
		|SELECT
		|	8
		|
		|UNION
		|
		|SELECT
		|	9
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	DATEADD(&BeginOfPeriod, Month, DigitTab1.Digit + 10 * DigitTab2.Digit + 100 * DigitTab3.Digit) AS Month
		|INTO MonthesTab
		|FROM
		|	DigitTab AS DigitTab1,
		|	DigitTab AS DigitTab2,
		|	DigitTab AS DigitTab3
		|WHERE
		|	DATEADD(&BeginOfPeriod, Month, DigitTab1.Digit + 10 * DigitTab2.Digit + 100 * DigitTab3.Digit) <= &EndOfPeriod
		|
		|INDEX BY
		|	Month
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|DROP DigitTab
		|;
		|";
		
	If StepType = Enums.fmBudgetAllocationStepTypes.DistributionByBasesOnDepartments
	OR StepType = Enums.fmBudgetAllocationStepTypes.DistributionByBasesOnProjects Then
		
		QueryText = QueryText + 
			"SELECT
			|	DistributionBases.DateFrom,
			|	DistributionBases.DistributionBase,
			|	DistributionBases.BalanceUnit,
			|	DistributionBases.DistributionDepartment,
			|	DistributionBases.DistributionItem,
			|	DistributionBases.DistributionProject,
			|	DistributionBases.Department,
			|	DistributionBases.Project,
			|	DistributionBases.DateTo,
			|	DistributionBases.BaseValue
			|INTO BasesPreliminarily
			|FROM
			|	InformationRegister.fmBudgetsDistributionBases AS DistributionBases
			|WHERE
			|	DistributionBases.BalanceUnit = &BalanceUnit
			|	AND DistributionBases.DateFrom <= &EndOfPeriod
			|	AND DistributionBases.DistributionBase = &DistributionBase
			|	AND DistributionBases.DateTo >= &BeginOfPeriod
			|	AND DistributionBases.Scenario = Value(Catalog.fmBudgetingScenarios.EmptyRef)
			|;
			|
			|////////////////////////////////////////////////////////////////////////////////
			|SELECT
			|	BasesPreliminarily.DateFrom,
			|	BasesPreliminarily.DistributionDepartment,
			|	BasesPreliminarily.DistributionItem,
			|	BasesPreliminarily.DistributionProject,
			|	BasesPreliminarily.DateTo,
			|	SUM(BasesPreliminarily.BaseValue) AS BaseValue
			|INTO BasesTotals
			|FROM
			|	BasesPreliminarily AS BasesPreliminarily
			|
			|Group BY
			|	BasesPreliminarily.DateTo,
			|	BasesPreliminarily.DistributionDepartment,
			|	BasesPreliminarily.DateFrom,
			|	BasesPreliminarily.DistributionItem,
			|	BasesPreliminarily.DistributionProject
			|;
			|
			|////////////////////////////////////////////////////////////////////////////////
			|SELECT
			|	MonthesTab.Month AS Month,
			|	BasesPreliminarily.DateFrom,
			|	BasesPreliminarily.DateTo,
			|	BasesPreliminarily.DistributionDepartment AS DistributionDepartment,
			|	BasesPreliminarily.DistributionItem AS DistributionItem,
			|	BasesPreliminarily.DistributionProject AS DistributionProject,
			|	BasesPreliminarily.Department,
			|	BasesPreliminarily.Project,
			|	BasesPreliminarily.BaseValue,
			|	BasesTotals.BaseValue AS BasesTotal
			|INTO BasesByMonthes
			|FROM
			|	MonthesTab AS MonthesTab
			|		INNER JOIN BasesPreliminarily AS BasesPreliminarily
			|			INNER JOIN BasesTotals AS BasesTotals
			|			ON BasesPreliminarily.DateFrom = BasesTotals.DateFrom
			|				AND BasesPreliminarily.DateTo = BasesTotals.DateTo
			|				AND BasesPreliminarily.DistributionDepartment = BasesTotals.DistributionDepartment
			|				AND BasesPreliminarily.DistributionItem = BasesTotals.DistributionItem
			|				AND BasesPreliminarily.DistributionProject = BasesTotals.DistributionProject
			|		ON (BasesPreliminarily.DateFrom <= MonthesTab.Month)
			|			AND (BasesPreliminarily.DateTo >= MonthesTab.Month)
			|
			|INDEX BY
			|	Month,
			|	DistributionDepartment,
			|	DistributionItem,
			|	DistributionProject
			|;
			|
			|////////////////////////////////////////////////////////////////////////////////
			|SELECT
			|	ToBeDistributed.Period AS Period,
			|	ToBeDistributed.Department,
			|	ToBeDistributed.Project,
			|	ToBeDistributed.BalanceUnit,
			|	ToBeDistributed.OperationType,
			|	SUM(ToBeDistributed.AmountTurnover) AS AmountTurnover,
			|	BasesByMonthes.Department AS BaseDepartment,
			|	ToBeDistributed.Item AS Item,
			|	ToBeDistributed.Analytics1 AS Analytics1,
			|	ToBeDistributed.Analytics2 AS Analytics2,
			|	ToBeDistributed.Analytics3 AS Analytics3,
			|	BasesByMonthes.Project AS BaseProject,
			|	ToBeDistributed.VersionPeriod AS VersionPeriod,
			|	SUM(ToBeDistributed.AmountTurnover * ISNULL(BasesByMonthes.BaseValue, 0) / ISNULL(BasesByMonthes.BasesTotal, 1)) AS AmountPart
			|FROM
			|	ToBeDistributed AS ToBeDistributed
			|		LEFT JOIN BasesByMonthes AS BasesByMonthes
			|		ON ToBeDistributed.Period = BasesByMonthes.Month
			|			AND (ToBeDistributed.Department = BasesByMonthes.DistributionDepartment
			|				OR BasesByMonthes.DistributionDepartment = Value(Catalog.fmDepartments.EmptyRef))
			|			AND (ToBeDistributed.Item = BasesByMonthes.DistributionItem
			|				OR BasesByMonthes.DistributionItem = Value(Catalog.fmIncomesAndExpensesItems.EmptyRef))
			|
			|Group BY
			|	ToBeDistributed.Period,
			|	ToBeDistributed.Department,
			|	ToBeDistributed.Project,
			|	ToBeDistributed.Item,
			|	ToBeDistributed.Analytics1,
			|	ToBeDistributed.Analytics2,
			|	ToBeDistributed.Analytics3,
			|	ToBeDistributed.BalanceUnit,
			|	ToBeDistributed.OperationType,
			|	BasesByMonthes.Department,
			|	BasesByMonthes.Project,
			|	ToBeDistributed.VersionPeriod
			|
			|ORDER BY
			|	ToBeDistributed.Period,
			|	ToBeDistributed.VersionPeriod,
			|	ToBeDistributed.Department,
			|	ToBeDistributed.Item
			|TOTALS BY
			|	Period,
			|	VersionPeriod,
			|	ToBeDistributed.Department,
			|	ToBeDistributed.Project
			|;
			|
			|////////////////////////////////////////////////////////////////////////////////
			|SELECT
			|	fmBudgetsDistributionBases.DateFrom,
			|	fmBudgetsDistributionBases.DistributionBase,
			|	fmBudgetsDistributionBases.BalanceUnit,
			|	fmBudgetsDistributionBases.DistributionDepartment,
			|	fmBudgetsDistributionBases.DistributionItem,
			|	fmBudgetsDistributionBases.DistributionProject,
			|	fmBudgetsDistributionBases.Department,
			|	fmBudgetsDistributionBases.Project,
			|	fmBudgetsDistributionBases.DateTo,
			|	fmBudgetsDistributionBases.BaseValue
			|INTO BasesPreliminarilyScenario
			|FROM
			|	InformationRegister.fmBudgetsDistributionBases AS fmBudgetsDistributionBases
			|WHERE
			|	fmBudgetsDistributionBases.BalanceUnit = &BalanceUnit
			|	AND fmBudgetsDistributionBases.DateFrom <= &EndOfPeriod
			|	AND fmBudgetsDistributionBases.DistributionBase = &DistributionBase
			|	AND fmBudgetsDistributionBases.DateTo >= &BeginOfPeriod
			|	AND fmBudgetsDistributionBases.Scenario = &Scenario
			|;
			|
			|////////////////////////////////////////////////////////////////////////////////
			|SELECT
			|	fmBudgetsDistributionBases.DateFrom,
			|	fmBudgetsDistributionBases.DistributionBase,
			|	fmBudgetsDistributionBases.BalanceUnit,
			|	fmBudgetsDistributionBases.DistributionDepartment,
			|	fmBudgetsDistributionBases.DistributionItem,
			|	fmBudgetsDistributionBases.DistributionProject,
			|	fmBudgetsDistributionBases.Department,
			|	fmBudgetsDistributionBases.Project,
			|	fmBudgetsDistributionBases.DateTo,
			|	fmBudgetsDistributionBases.BaseValue
			|FROM
			|	BasesPreliminarilyScenario AS fmBudgetsDistributionBases
			|;
			|
			|////////////////////////////////////////////////////////////////////////////////
			|SELECT
			|	BasesPreliminarilyScenario.DateFrom,
			|	BasesPreliminarilyScenario.DistributionDepartment,
			|	BasesPreliminarilyScenario.DistributionItem,
			|	BasesPreliminarilyScenario.DistributionProject,
			|	BasesPreliminarilyScenario.DateTo,
			|	SUM(BasesPreliminarilyScenario.BaseValue) AS BaseValue
			|INTO BasesTotalsScenario
			|FROM
			|	BasesPreliminarilyScenario AS BasesPreliminarilyScenario
			|
			|Group BY
			|	BasesPreliminarilyScenario.DateTo,
			|	BasesPreliminarilyScenario.DistributionDepartment,
			|	BasesPreliminarilyScenario.DateFrom,
			|	BasesPreliminarilyScenario.DistributionItem,
			|	BasesPreliminarilyScenario.DistributionProject
			|;
			|
			|////////////////////////////////////////////////////////////////////////////////
			|SELECT
			|	MonthesTab.Month AS Month,
			|	BasesPreliminarilyScenario.DateFrom,
			|	BasesPreliminarilyScenario.DateTo,
			|	BasesPreliminarilyScenario.DistributionDepartment AS DistributionDepartment,
			|	BasesPreliminarilyScenario.DistributionItem AS DistributionItem,
			|	BasesPreliminarilyScenario.DistributionProject AS DistributionProject,
			|	BasesPreliminarilyScenario.Department,
			|	BasesPreliminarilyScenario.Project,
			|	BasesPreliminarilyScenario.BaseValue,
			|	BasesTotalsScenario.BaseValue AS BasesTotal
			|INTO BasesByMonthesScenario
			|FROM
			|	MonthesTab AS MonthesTab
			|		INNER JOIN BasesPreliminarilyScenario AS BasesPreliminarilyScenario
			|			INNER JOIN BasesTotalsScenario AS BasesTotalsScenario
			|			ON BasesPreliminarilyScenario.DateFrom = BasesTotalsScenario.DateFrom
			|				AND BasesPreliminarilyScenario.DateTo = BasesTotalsScenario.DateTo
			|				AND BasesPreliminarilyScenario.DistributionDepartment = BasesTotalsScenario.DistributionDepartment
			|				AND BasesPreliminarilyScenario.DistributionItem = BasesTotalsScenario.DistributionItem
			|				AND BasesPreliminarilyScenario.DistributionProject = BasesTotalsScenario.DistributionProject
			|		ON (BasesPreliminarilyScenario.DateFrom <= MonthesTab.Month)
			|			AND (BasesPreliminarilyScenario.DateTo >= MonthesTab.Month)
			|
			|INDEX BY
			|	Month,
			|	DistributionDepartment,
			|	DistributionItem,
			|	DistributionProject
			|;
			|
			|////////////////////////////////////////////////////////////////////////////////
			|SELECT
			|	ToBeDistributed.Period AS Period,
			|	ToBeDistributed.Department,
			|	ToBeDistributed.Project AS Project,
			|	ToBeDistributed.BalanceUnit,
			|	ToBeDistributed.OperationType,
			|	ToBeDistributed.Item AS Item,
			|	ToBeDistributed.Analytics1 AS Analytics1,
			|	ToBeDistributed.Analytics2 AS Analytics2,
			|	ToBeDistributed.Analytics3 AS Analytics3,
			|	SUM(ToBeDistributed.AmountTurnover) AS AmountTurnover,
			|	BasesByMonthesScenario.Department AS BaseDepartment,
			|	BasesByMonthesScenario.Project AS BaseProject,
			|	ToBeDistributed.VersionPeriod AS VersionPeriod,
			|	SUM(ToBeDistributed.AmountTurnover * ISNULL(BasesByMonthesScenario.BaseValue, 0) / ISNULL(BasesByMonthesScenario.BasesTotal, 1)) AS AmountPart
			|FROM
			|	ToBeDistributed AS ToBeDistributed
			|		LEFT JOIN BasesByMonthesScenario AS BasesByMonthesScenario
			|		ON ToBeDistributed.Period = BasesByMonthesScenario.Month
			|			AND (ToBeDistributed.Department = BasesByMonthesScenario.DistributionDepartment
			|				OR BasesByMonthesScenario.DistributionDepartment = Value(Catalog.fmDepartments.EmptyRef))
			|			AND (ToBeDistributed.Item = BasesByMonthesScenario.DistributionItem
			|				OR BasesByMonthesScenario.DistributionItem = Value(Catalog.fmIncomesAndExpensesItems.EmptyRef))
			|
			|Group BY
			|	ToBeDistributed.Period,
			|	ToBeDistributed.Department,
			|	ToBeDistributed.Project,
			|	ToBeDistributed.BalanceUnit,
			|	ToBeDistributed.OperationType,
			|	ToBeDistributed.Item,
			|	ToBeDistributed.Analytics1,
			|	ToBeDistributed.Analytics2,
			|	ToBeDistributed.Analytics3,
			|	BasesByMonthesScenario.Department,
			|	BasesByMonthesScenario.Project,
			|	ToBeDistributed.VersionPeriod
			|
			|ORDER BY
			|	ToBeDistributed.Period,
			|	ToBeDistributed.VersionPeriod,
			|	ToBeDistributed.Project,
			|	ToBeDistributed.Item
			|TOTALS BY
			|	Period,
			|	VersionPeriod,
			|	ToBeDistributed.Department,
			|	ToBeDistributed.Project
			|;
			|
			|////////////////////////////////////////////////////////////////////////////////
			|DROP BasesByMonthes
			|;
			|
			|////////////////////////////////////////////////////////////////////////////////
			|DROP BasesTotals
			|;
			|
			|////////////////////////////////////////////////////////////////////////////////
			|DROP BasesPreliminarily
			|;
			|
			|////////////////////////////////////////////////////////////////////////////////
			|DROP BasesByMonthesScenario
			|;
			|
			|////////////////////////////////////////////////////////////////////////////////
			|DROP BasesTotalsScenario
			|;
			|
			|////////////////////////////////////////////////////////////////////////////////
			|DROP BasesPreliminarilyScenario
			|;
			|";
			
	ElsIf StepType = Enums.fmBudgetAllocationStepTypes.Reclass Then
		
		QueryText = QueryText +
			"SELECT
			|	ToBeDistributed.Period AS Period,
			|	ToBeDistributed.Department,
			|	ToBeDistributed.BalanceUnit,
			|	ToBeDistributed.OperationType,
			|	ToBeDistributed.Item,
			|	ToBeDistributed.Analytics1,
			|	ToBeDistributed.Analytics2,
			|	ToBeDistributed.Analytics3,
			|	ToBeDistributed.AmountTurnover AS AmountTurnover,
			|	&RecipientDepartment AS BaseDepartment,
			|	ToBeDistributed.Project AS Project,
			|	ToBeDistributed.Project AS BaseProject,
			|	ToBeDistributed.VersionPeriod AS VersionPeriod,
			|	ToBeDistributed.AmountTurnover AS AmountPart
			|FROM
			|	ToBeDistributed AS ToBeDistributed
			|
			|ORDER BY
			|	ToBeDistributed.Period,
			|	ToBeDistributed.VersionPeriod,
			|	ToBeDistributed.Project
			|
			|TOTALS BY
			|	Period,
			|	VersionPeriod,
			|	ToBeDistributed.Department,
			|	Project
			|;
			|";
			
	EndIf;
	
	QueryText = QueryText + 
		"DROP ToBeDistributed
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|DROP MonthesTab
		|;";
		
	If StepItems.Count() = 0 Then
		QueryText = StrReplace(QueryText, "AND fmIncomesAndExpenses.Item IN(&Item)", "");
	EndIf;
	If CurDistributionStep.ProjectsTurnover.Count() = 0 Then
		QueryText = StrReplace(QueryText, "AND (&EmptyProjectFilter AND fmIncomesAndExpenses.Project = Value(Catalog.fmProjects.EmptyRef) OR fmIncomesAndExpenses.Project IN(&Project))", "");
	EndIf;
	If NOT ValueIsFilled(DistributionVersion) Then
		QueryText = StrReplace(QueryText, "fmIncomesAndExpenses.VersionPeriod < &DistributionVersion AND", "");
		QueryText = StrReplace(QueryText, "fmIncomesAndExpenses.VersionPeriod = &DistributionVersion AND", "");
	EndIf;
	
	Return QueryText;
	
EndFunction











