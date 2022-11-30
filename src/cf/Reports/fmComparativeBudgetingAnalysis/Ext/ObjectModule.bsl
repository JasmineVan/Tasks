
////////////////////////////////////////////////////////////////////////////////
// ПЕРЕМЕННЫЕ МОДУЛЯ

Var IndicatorSet Export;

Var OutputDepartmentBalanceUnit Export;			//Признак, если группировки по колонкам включают и вывод БалансоваяЕдиница и вывод Подразделений
Var DepartmentHierarchyWithoutBalanceUnit Export;		//Признак вывода Подразделений в Иерархии без вывода БалансоваяЕдиница
Var DepartmentHierarchyWithBalanceUnit Export;		//Признак вывода Подразделений в Иерархии с выводом БалансоваяЕдиница


Procedure GenerateReport(Result = Undefined, DetailsData = Undefined, CompositionSchemeAddress) Export
	
	//Очистим поле табличного документа
	Result.Clear();
	
	Template = GetCommonTemplate("fmStandardReportCommonAreas");
	AreaTitle        = Template.GetArea("AreaTitle");
	// Текст заголовка
	ReportTitle = NStr("en='Comparative analysis in budgeting';ru='Сравнительный анализ бюджетирования'"); // Заголовок?
	
	AreaTitle.Parameters.ReportTitle = ReportTitle;
	Result.Put(AreaTitle);
	
	//Сохраним пользовательские отборы
	Filters = SettingsComposer.Settings.Filter.Items;
	
	TemplateComposer = New DataCompositionTemplateComposer;


	//если вид отчета "Стандартное представление", то используем макет "ОтчетОбщий" и выводим стандартный отчет прибылей и убытков
	CurDataCompositionScheme 	= ThisObject.GetTemplate("TemplateStructurePresentationClassic");
	
	// Флаг по добавлению отклонений
	AddDeviations = ComparedData.Count() > 1;
	
	// Формирование текста запроса в зависимости от вида отчета.
	QueryText = FormQueryTextForDCS();
	
	// Если текст сформирован
	If NOT IsBlankString(QueryText) Then
		
		// Заменяем текст запроса в макете
		CurDataCompositionScheme.DataSets[0].Query = QueryText;
		
		// Находим вычисляемое поле периода в макете.
		PeriodCalculatedFields =	CurDataCompositionScheme.CalculatedFields.Find("Period");
		QuarterCalculatedFields =	CurDataCompositionScheme.CalculatedFields.Find("GroupQuarter");
		YearCalculatedFields = 		CurDataCompositionScheme.CalculatedFields.Find("GroupYear");
		
		// Формируем для него выражение вычисления
		PeriodFieldExpression =		"Format(Period, NStr(""ru = 'L = ''ru''; DF = ''MMMM yyyy''; DE = '' '' '; en = 'L = ''en''; DF = ''MMMM yyyy''; DE = '' '' '""))";
		FieldExpressionQuarter =		"Format(Period, ""DF = 'q """"Quarter"""" yyyy """"y.""""'; DE = ' ' "")";
		FieldExpressionYear =			"Format(Period, ""DF = 'yyyy """"y.""""'; 				DE = ' ' "")";
		
		// Добавим выбранное поле в группу для вывода в отчет.
		CurDefaultChioce =	CurDataCompositionScheme.DefaultSettings.Selection;
		//Счетчик = 1;
		CnIndicator = 0;
		// Обходим ТЧ ресурсов.
		For Each Indicator In Indicators Do
			If Indicator.Use = False Then
				Continue;
			EndIf;
			CnIndicator = CnIndicator + 1;
			Counter = 1;
			If Indicator.Indicator = "AmountMan" Then
				StrIndicator = "Amount";
				StrIndicatorHeader = NStr("en='man.';ru='упр.'");
			ElsIf Indicator.Indicator = "CurrencyAmount" Then
				StrIndicator = "CurAmount";	
				StrIndicatorHeader = NStr("en='curr.';ru='вал.'");
			EndIf;
			For Each CurComparedData In ComparedData Do
			// Стандартное представление и по структуре.
				
				// Имя поля ресурса.
				FieldName = StrIndicator+String(Counter);
				
				SelectedField =				CurDefaultChioce.Items.Add(Type("DataCompositionSelectedField"));
				SelectedField.Field =		New DataCompositionField(FieldName);
				//ВыбранноеПоле.Расположение = РасположениеПоляКомпоновкиДанных.Вертикально; 
				
				// Формирование заголовка поля.
				FieldTitle = TrimAll(CurComparedData.PlanningScenario.Description)+" "+StrIndicatorHeader;
				If CurComparedData.PlanningScenario.ScenarioType = Enums.fmBudgetingScenarioTypes.Plan Then
					If Constants.fmBudgetVersioning.Get()=Enums.fmBudgetVersioning.EveryMonth Then
						FieldTitle = FieldTitle +" ("+Format(CurComparedData.VersionPeriod,"DF='MMMM yyyy'")+")";
					ElsIf Constants.fmBudgetVersioning.Get()=Enums.fmBudgetVersioning.EveryDay Then
						FieldTitle = FieldTitle +" ("+Format(CurComparedData.VersionPeriod,"DF='dd.MM.yyyy'")+")";
					EndIf;
				Else
					FormImitation = New Structure("AvailableReportPeriods",fmReportsServerCall.GetAvailableReportPeriods());
					PeriodPresentation = fmReportsClientServer.GetReportPeroidRepresentation(PeriodType, CurComparedData.BeginOfPeriod, CurComparedData.EndOfPeriod, FormImitation);
					FieldTitle = FieldTitle +" ("+PeriodPresentation+")";
				EndIf;
				SelectedField.Title = FieldTitle;
				
				// Добавляем очередной ресурс в коллекцию полей набора данных и устанавливаем ему оформление.
				DataCompositionSchemaDataSetField = CurDataCompositionScheme.DataSets[0].Fields.Add(Type("DataCompositionSchemaDataSetField"));
				DataCompositionSchemaDataSetField.Field =			FieldName;
				DataCompositionSchemaDataSetField.DataPath =		FieldName;
				DataCompositionSchemaDataSetField.Title =		FieldName;
				DataCompositionSchemaDataSetField.Appearance.SetParameterValue("MarkNegatives",True);
				DataCompositionSchemaDataSetField.Appearance.SetParameterValue("HorizontalAlign",HorizontalAlign.Right);
				
				// Удаляем поле итога, если такое уже было.
				FoundTotalField = CurDataCompositionScheme.TotalFields.Find(FieldName);
				If NOT FoundTotalField = Undefined Then
					CurDataCompositionScheme.TotalFields.Delete(FoundTotalField);
				EndIf;
				
				// Формирование поля итога для очередного ресурса
				If NOT ValueIsFilled(ViewFormat) Then
					FormatFrom = "";
				ElsIf  ViewFormat=Enums.fmRoundMethods.WithoutRound Then
					FormatFrom = "ND=15; NFD=2";	
				Else
					Rounds = New Map();
					Rounds.Insert(PredefinedValue("Enum.fmRoundMethods.EmptyRef"), "0");
					Rounds.Insert(PredefinedValue("Enum.fmRoundMethods.WithoutRound"), "0");
					Rounds.Insert(PredefinedValue("Enum.fmRoundMethods.Unit"), "0");
					Rounds.Insert(PredefinedValue("Enum.fmRoundMethods.Ten"), "1");
					Rounds.Insert(PredefinedValue("Enum.fmRoundMethods.Hundred"), "2");
					Rounds.Insert(PredefinedValue("Enum.fmRoundMethods.Thousand"), "3");
					Rounds.Insert(PredefinedValue("Enum.fmRoundMethods.TenThousands"), "4");
					Rounds.Insert(PredefinedValue("Enum.fmRoundMethods.HundredThousands"), "5");
					Rounds.Insert(PredefinedValue("Enum.fmRoundMethods.Million"), "6");
					FormatFrom =  "NFD=0; NS="+(Rounds[ViewFormat]);
				EndIf;

				TotalField = CurDataCompositionScheme.TotalFields.Add();
				TotalField.DataPath = FieldName;
				TotalField.Expression = "Format(SUM("+FieldName+"), """+FormatFrom+""")";
				FormatString = FormatFrom;
				SetDataSetFieldsFormat(DataCompositionSchema.DataSets[0], FieldName, FormatString);
				////////////////////////////////////
				// ОТКЛОНЕНИЯ
				If AddDeviations AND Counter > 1 Then
					For Each CurDeviation In Deviations Do
						If CurDeviation.Use Then
							
							If Indicator.Indicator = "AmountMan" Then
								DeviationFieldName = CurDeviation.Field+String(Counter);
							ElsIf Indicator.Indicator = "CurrencyAmount" Then
								DeviationFieldName = "Cur"+CurDeviation.Field+String(Counter);	
							EndIf;

							
							SelectedField =				CurDefaultChioce.Items.Add(Type("DataCompositionSelectedField"));
							SelectedField.Field =		New DataCompositionField(DeviationFieldName);
							
							// Формирование заголовка поля.
							SelectedField.Title = GetDeviationColumnTitle(CurDeviation.Field);
							
							// Добавляем очередной ресурс в коллекцию полей набора данных и устанавливаем ему оформление.
							DataCompositionSchemaDataSetField = CurDataCompositionScheme.DataSets[0].Fields.Add(Type("DataCompositionSchemaDataSetField"));
							DataCompositionSchemaDataSetField.Field =			DeviationFieldName;
							DataCompositionSchemaDataSetField.DataPath =		DeviationFieldName;
							DataCompositionSchemaDataSetField.Title =		DeviationFieldName;
							DataCompositionSchemaDataSetField.Appearance.SetParameterValue("MarkNegatives",True);
							DataCompositionSchemaDataSetField.Appearance.SetParameterValue("HorizontalAlign",HorizontalAlign.Right);
							
							// Удаляем поле итога, если такое уже было.
							FoundTotalField = CurDataCompositionScheme.TotalFields.Find(DeviationFieldName);
							If NOT FoundTotalField = Undefined Then
								CurDataCompositionScheme.TotalFields.Delete(FoundTotalField);
							EndIf;
							
							// Формирование поля итога для очередного ресурса
							TotalField = CurDataCompositionScheme.TotalFields.Add();
							TotalField.DataPath = DeviationFieldName;
							TotalField.Expression = GetDeviationTotalFieldExpression(CurDeviation.Field,Counter,?(Indicator.Indicator = "AmountMan",False,True));
							
						EndIf;
					EndDo;
				EndIf;
				////////////////////////////////////
				
				// Формирование вычисляемого поля периода, добавление условия по очередному ресурсу.
				If Counter > 1 AND CnIndicator = 1  Then
					PeriodFieldExpression = 	PeriodFieldExpression +	"+ "", "" + Format(DATEADD(&BeginOfPeriod"+String(Counter)+", ""Month"", (Month(Period) - Month(&BeginOfPeriod1) + (Year(Period) - Year(&BeginOfPeriod1))*12)), NStr(""ru = 'L = ''ru''; DF = ''MMMM yyyy''; DE = '' '' '; en = 'L = ''en''; DF = ''MMMM yyyy''; DE = '' '' '""))";
					FieldExpressionQuarter = 	FieldExpressionQuarter +	"+ "", "" + Format(DATEADD(&BeginOfPeriod"+String(Counter)+", ""Month"", (Month(Period) - Month(&BeginOfPeriod1) + (Year(Period) - Year(&BeginOfPeriod1))*12)), ""DF='q """"Quarter"""" yyyy """"y.""""'; DE = ' ' "")";
					FieldExpressionYear =		FieldExpressionYear +		"+ "", "" + Format(DATEADD(&BeginOfPeriod"+String(Counter)+", ""Month"", (Month(Period) - Month(&BeginOfPeriod1) + (Year(Period) - Year(&BeginOfPeriod1))*12)), ""DF='yyyy """"y.""""'; DE = ' ' "")";
				EndIf;
				
			Counter = Counter + 1;
			EndDo;
		EndDo; //по показателям
		// Устанавливаем выражение для поля периода.
		If NOT PeriodCalculatedFields = Undefined Then
			PeriodCalculatedFields.Expression =	PeriodFieldExpression;
		EndIf;
		If NOT QuarterCalculatedFields = Undefined Then
			QuarterCalculatedFields.Expression =	FieldExpressionQuarter;
		EndIf;
		If NOT YearCalculatedFields = Undefined Then
			YearCalculatedFields.Expression =		FieldExpressionYear;
		EndIf;
		
	EndIf;
	
	// инициализация схемы компоновки отчета
	DataCompositionSchema = CurDataCompositionScheme;
	
	Settings 				= DataCompositionSchema.DefaultSettings;
	//установка макета оформления
	If OutputTotals Then
		fmReportsClientServer.SetOutputParamters(Settings, "HorizontalOverallPlacement", DataCompositionTotalPlacement.Begin);
	Else
		fmReportsClientServer.SetOutputParamters(Settings, "HorizontalOverallPlacement", DataCompositionTotalPlacement.None);
	EndIf;
	
	SettingsComposer.LoadSettings(Settings);
	
	// Установка параметров СКД.
	AddSetDCSParameters();
	
	fmReportsServerCall.CopyComposerFilter(Filters, SettingsComposer.Settings.Filter.Items);
	
	SetStructureForReportOutput();
		
	Settings = SettingsComposer.Settings;
	
	
	CompositionDetailsData = New DataCompositionDetailsData;
	
	CompositionTemplate = TemplateComposer.Execute(DataCompositionSchema, Settings, CompositionDetailsData);
	
	
	//инициализация процессора СКД
	DataCompositionProcessor = New DataCompositionProcessor;
	DataCompositionProcessor.Initialize(CompositionTemplate,, CompositionDetailsData, True);
	
	//инициализация процессора вывода
	OutputProcessor = New DataCompositionResultSpreadsheetDocumentOutputProcessor;
	OutputProcessor.SetDocument(Result);
	
	OutputProcessor.BeginOutput();
	HeadIsOutput = False;
	ResultItem = DataCompositionProcessor.Next();
	While NOT ResultItem = Undefined Do
		If NOT HeadIsOutput AND ResultItem.ParameterValues.Count()>0 Then
			HeadIsOutput = True;
			//Зафиксируем шапку
			Result.FixedTop = Result.TableHeight;
		EndIf;
		OutputProcessor.OutputItem(ResultItem);
		ResultItem = DataCompositionProcessor.Next();
	EndDo;
	OutputProcessor.EndOutput();
	
	// Определение количества
	Result.FixedLeft = 1;
	//поместим данные расшифровки во временное хранилище
	DetailsData = PutToTempStorage(CompositionDetailsData, New UUID);
	CompositionSchemeAddress = PutToTempStorage(DataCompositionSchema, New UUID);
	
EndProcedure

 Function FormQueryTextForDCS()
	
	AddDeviations = (ComparedData.Count() > 1);
	
	QueryText = "";
	If InfoStructure <> Catalogs.fmInfoStructures.EmptyRef() Then // по структуре
		
		ResourcesForTotalTable = "";				// Текст вычисления ресурсов итоговой таблицы
		ResourcesForTotalTableSelected = ""; 	// Текст выбранных ресурсов для итоговой таблицы
		QueryForNextResource = "";			// Текст запроса-объединения для всех ресурсов
		TotalTableResources = "";				// Текст получения ресурсов итоговой таблицы
		TotalTableResourcesSelected = "";		// Текст выбранных ресурсов в итоговой таблице
		
		// Неизменяемая часть запроса
		QueryText = "SELECT
		|	NestedQuery.Ref AS Ref,
		|	NestedQuery.Analytics AS Analytics
		|INTO FinancialReportStructureIndicators
		|FROM
		|	(SELECT
		|		FinancialReportStructureIndicators.Ref AS Ref,
		|		fmItemGroupsItems.Item AS Analytics
		|	FROM
		|		Catalog.fmItemGroups.Items AS fmItemGroupsItems
		|			LEFT JOIN Catalog.fmInfoStructuresSections.SectionStructureData AS FinancialReportStructureIndicators
		|			ON (FinancialReportStructureIndicators.Analytics = fmItemGroupsItems.Ref)
		|	WHERE
		|		FinancialReportStructureIndicators.Ref.Owner = &ReportVariant
		|		AND NOT FinancialReportStructureIndicators.Ref.DeletionMark
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		fmInfoStructuresSectionsSectionStructureData.Ref,
		|		fmInfoStructuresSectionsSectionStructureData.Analytics
		|	FROM
		|		Catalog.fmInfoStructuresSections.SectionStructureData AS fmInfoStructuresSectionsSectionStructureData
		|	WHERE
		|		NOT fmInfoStructuresSectionsSectionStructureData.Analytics Refs Catalog.fmItemGroups
		|		AND fmInfoStructuresSectionsSectionStructureData.Ref.Owner = &ReportVariant
		|		AND NOT fmInfoStructuresSectionsSectionStructureData.Ref.DeletionMark) AS NestedQuery
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	FinancialReportStructureIndicators.Ref AS Ref,
		|	FinancialReportStructureIndicators.Analytics AS Analytics
		|INTO FinancialReportStructureIndicatorsWithEmptyString
		|FROM
		|	FinancialReportStructureIndicators AS FinancialReportStructureIndicators
		|
		|Group by
		|	FinancialReportStructureIndicators.Ref,
		|	FinancialReportStructureIndicators.Analytics
		|
		|UNION ALL
		|
		|SELECT
		|	FinancialReportStructure.Ref,
		|	Value(Catalog.fmIncomesAndExpensesItems.EmptyRef)
		|FROM
		|	Catalog.fmInfoStructuresSections AS FinancialReportStructure
		|WHERE
		|	FinancialReportStructure.IsBlankString
		|	AND FinancialReportStructure.Owner = &ReportVariant
		|	AND NOT FinancialReportStructure.DeletionMark
		|;
		|
		|///////////////////////////////////////////////////////////////////////////////
		|%QueryForNextResource%
		|;
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	IncomesExpensesTurnoversGlue.Period AS Period,
		|	IncomesExpensesTurnoversGlue.Scenario AS Scenario,
		|	IncomesExpensesTurnoversGlue.Project AS Project,
		|	IncomesExpensesTurnoversGlue.Department AS Department,
		|	IncomesExpensesTurnoversGlue.BalanceUnit AS BalanceUnit,
		|	IncomesExpensesTurnoversGlue.Item AS Item,
		|	CASE 
		|	WHEN IncomesExpensesTurnoversGlue.Analytics1 = Undefined Then NULL
		|	Else IncomesExpensesTurnoversGlue.Analytics1
		|	END AS Analytics1,	
		|	CASE 
		|	WHEN IncomesExpensesTurnoversGlue.Analytics2 = Undefined Then NULL
		|	Else IncomesExpensesTurnoversGlue.Analytics2
		|	END AS Analytics2,
        |	CASE 
		|	WHEN IncomesExpensesTurnoversGlue.Analytics3 = Undefined Then NULL
		|	Else IncomesExpensesTurnoversGlue.Analytics3
		|	END AS Analytics3,
		|	IncomesExpensesTurnoversGlue.Currency AS Currency,
		|	SUM(IncomesExpensesTurnoversGlue.AmountTurnover) AS AmountTurnover,
		|	SUM(IncomesExpensesTurnoversGlue.CurrencyAmountTurnover) AS CurrencyAmountTurnover,
		|	SUM(IncomesExpensesTurnoversGlue.PreliminaryBudgetTurnover) AS PreliminaryBudgetTurnover,
		|	SUM(IncomesExpensesTurnoversGlue.PreliminaryBudgetCurTurnover) AS PreliminaryBudgetCurTurnover
		|INTO TTIncomesExpensesPlanTurnoversJoined
		|FROM
		|	TTIncomesExpensesTurnoversGlue AS IncomesExpensesTurnoversGlue
		|Group by
		|	IncomesExpensesTurnoversGlue.Analytics1,
		|	IncomesExpensesTurnoversGlue.Analytics2,
		|	IncomesExpensesTurnoversGlue.Analytics3,
		|	IncomesExpensesTurnoversGlue.Currency,
		|	IncomesExpensesTurnoversGlue.Item,
		|	IncomesExpensesTurnoversGlue.Department,
		|	IncomesExpensesTurnoversGlue.Project,
		|	IncomesExpensesTurnoversGlue.BalanceUnit,
		|	IncomesExpensesTurnoversGlue.Period,
		|	IncomesExpensesTurnoversGlue.Scenario
		|;
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT ALLOWED
		|	ISNULL(IncomesExpensesPlanTurnoversJoined.Period, DATETIME(1, 1, 1, 0, 0, 0)) AS Period,
		|	ISNULL(IncomesExpensesPlanTurnoversJoined.Department, Value(Catalog.fmDepartments.EmptyRef)) AS Departments,
		|	ISNULL(IncomesExpensesPlanTurnoversJoined.Project, Value(Catalog.fmProjects.EmptyRef)) AS Project,
		|	ISNULL(IncomesExpensesPlanTurnoversJoined.Item, Value(Catalog.fmIncomesAndExpensesItems.EmptyRef)) AS IncomesExpensesItem,
		|	IncomesExpensesPlanTurnoversJoined.Analytics1 AS Analytics1,
		|	IncomesExpensesPlanTurnoversJoined.Analytics2 AS Analytics2,
		|	IncomesExpensesPlanTurnoversJoined.Analytics3 AS Analytics3,
		|	IncomesExpensesPlanTurnoversJoined.Currency AS Currency,
		|	FinancialReportStructureIndicatorsWithEmptyString.Ref AS Ref,
		|	ISNULL(IncomesExpensesPlanTurnoversJoined.BalanceUnit, Value(Catalog.fmBalanceUnits.EmptyRef)) AS BalanceUnit,
		|	%ResourcesForTotalTable%
		|INTO TotalTable
		|{SELECT
		|	Period,
		|	Departments.* AS Departments,
		|	Project.* AS Project,
		|	Analytics1.* AS Analytics1,
		|	Analytics2.* AS Analytics2,
		|	Analytics3.* AS Analytics3,
		|	Currency.* AS Currency,
		|	IncomesExpensesItem.* AS Item,
		|	Ref.* AS Section,
		|	BalanceUnit.* AS BalanceUnit,
		|	%ResourcesForTotalTableSelected%}
		|FROM
		|	FinancialReportStructureIndicatorsWithEmptyString AS FinancialReportStructureIndicatorsWithEmptyString
		|		LEFT JOIN TTIncomesExpensesPlanTurnoversJoined AS IncomesExpensesPlanTurnoversJoined
		|		ON  FinancialReportStructureIndicatorsWithEmptyString.Analytics = IncomesExpensesPlanTurnoversJoined.Item
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	TotalTable.Departments AS Departments,
		|	TotalTable.Project AS Project,
		|	TotalTable.Analytics1 AS Analytics1,
		|	TotalTable.Analytics2 AS Analytics2,
		|	TotalTable.Analytics3 AS Analytics3,
		|	TotalTable.Currency AS Currency,
		|	TotalTable.IncomesExpensesItem AS IncomesExpensesItem,
		|	TotalTable.Ref AS Ref,
		|	TotalTable.BalanceUnit AS BalanceUnit,
		|	TotalTable.Period AS Period,
		|	%TotalTableResources%
		|{SELECT
		|	Departments.* AS Departments,
		|	Project.* AS Project,
		|	Analytics1.* AS Analytics1,
		|	Analytics2.* AS Analytics2,
		|	Analytics3.* AS Analytics3,
		|	Currency.* AS Currency,
		|	IncomesExpensesItem.* AS Item,
		|	Ref.* AS Section,
		|	BalanceUnit.* AS BalanceUnit,
		|	Period,
		|	%TotalTableResourcesSelected%}
		|FROM
		|	TotalTable AS TotalTable
		|WHERE
		|	NOT TotalTable.Period = DATETIME(1, 1, 1, 0, 0, 0)";
		
		Counter = 1;
		CompDataCount = ComparedData.Count();
		For Each CurComparedData In ComparedData Do
			Comma = ?(Counter=1,"",",");
			If ValueIsFilled(CurComparedData.PlanningScenario) Then
				ResourcesForTotalTable = ResourcesForTotalTable + Comma + "
				|ISNULL(CASE WHEN IncomesExpensesPlanTurnoversJoined.Scenario = ""ComparedData"+String(Counter)+""" Then
				|IncomesExpensesPlanTurnoversJoined.AmountTurnover
				|Else 0 END, 0) AS Indicator"+String(Counter)+",
				|ISNULL(CASE WHEN IncomesExpensesPlanTurnoversJoined.Scenario = ""ComparedData"+String(Counter)+""" Then
				|IncomesExpensesPlanTurnoversJoined.CurrencyAmountTurnover
				|Else 0 END, 0) AS CurIndicator"+String(Counter)+"
				|";
				
				ResourcesForTotalTableSelected = ResourcesForTotalTableSelected 
				+ Comma + "Indicator"+String(Counter)+" AS Amount"+String(Counter);
				ResourcesForTotalTableSelected = ResourcesForTotalTableSelected 
				+ "," + "CurIndicator"+String(Counter)+" AS CurAmount"+String(Counter);
				
				If CurComparedData.PlanningScenario.ScenarioType = Enums.fmBudgetingScenarioTypes.Plan
					AND (Constants.fmBudgetVersioning.Get() = Enums.fmBudgetVersioning.EveryDay OR Constants.fmBudgetVersioning.Get() = Enums.fmBudgetVersioning.EveryMonth) Then
					VersionCondition = "
					|WHERE   
					|	 IncomesExpensesPlanTurnovers.VersionPeriod <= &VersionPeriod"+String(Counter)+"
					|";
				Else
					VersionCondition = "";
				EndIf;
				QueryForNextResource = QueryForNextResource + ?(Counter=1,""," UNION ALL ") + "
					|SELECT "+?(Counter = 1,"ALLOWED","")+"
					|	IncomesExpensesPlanTurnovers.Department AS Department,
					|	IncomesExpensesPlanTurnovers.Project AS Project,
					|	IncomesExpensesPlanTurnovers.Analytics1 AS Analytics1,
					|	IncomesExpensesPlanTurnovers.Analytics2 AS Analytics2,
					|	IncomesExpensesPlanTurnovers.Analytics3 AS Analytics3,
					|	IncomesExpensesPlanTurnovers.Currency AS Currency,
					|	IncomesExpensesPlanTurnovers.BalanceUnit AS BalanceUnit,
					|	"+?(Counter = 1,"IncomesExpensesPlanTurnovers.Period","DATEADD(&BeginOfPeriod1, Month, Month(IncomesExpensesPlanTurnovers.Period) - Month(&BeginOfPeriod"+String(Counter)+") + (Year(IncomesExpensesPlanTurnovers.Period) - Year(&BeginOfPeriod"+String(Counter)+")) * 12)")+" AS Period,
					|	""ComparedData"+String(Counter)+""" AS Scenario,
					|	IncomesExpensesPlanTurnovers.Item AS Item,
					|	CASE
					|		WHEN &ConsiderBudgetsNotInAgreement
					|			Then IncomesExpensesPlanTurnovers.AmountTurnover + IncomesExpensesPlanTurnovers.NotAgreedAmountTurnover
					|			Else IncomesExpensesPlanTurnovers.AmountTurnover
					|	END AS AmountTurnover,
					|	CASE
					|		WHEN &ConsiderBudgetsNotInAgreement
					|			Then IncomesExpensesPlanTurnovers.CurrencyAmountTurnover + IncomesExpensesPlanTurnovers.NotAgreedCurrencyAmountTurnover
					|			Else IncomesExpensesPlanTurnovers.CurrencyAmountTurnover
					|	END AS CurrencyAmountTurnover,
					|	IncomesExpensesPlanTurnovers.NotAgreedAmountTurnover AS PreliminaryBudgetTurnover,
					|	IncomesExpensesPlanTurnovers.NotAgreedCurrencyAmountTurnover AS PreliminaryBudgetCurTurnover,
					|	IncomesExpensesPlanTurnovers.OperationType AS OperationType
					|"+?(Counter = 1,"INTO TTIncomesExpensesTurnoversGlue","")+"
					|FROM
					|	AccumulationRegister.fmIncomesAndExpenses.Turnovers(
					|		&BeginOfPeriod"+String(Counter)+",
					|		&EndOfPeriod"+String(Counter)+",
					|		Month,
					|		Scenario = &PlanningScenario"+String(Counter)+"
					|			AND OperationType IN (&Operations)) AS IncomesExpensesPlanTurnovers
					|"+VersionCondition;
					
										
				
				TotalTableResources = TotalTableResources + Comma
				+ " TotalTable.Indicator"+String(Counter)+" AS Indicator"+String(Counter);
				TotalTableResources = TotalTableResources + ","
				+ " TotalTable.CurIndicator"+String(Counter)+" AS CurIndicator"+String(Counter);
				TotalTableResourcesSelected = TotalTableResourcesSelected + Comma
				+ " Indicator"+String(Counter)+" AS Amount"+String(Counter);
				TotalTableResourcesSelected = TotalTableResourcesSelected + ","
				+ " CurIndicator"+String(Counter)+" AS CurAmount"+String(Counter);
				
				If AddDeviations Then
					
					
					TotalTableResources = TotalTableResources + ","
					+ " TotalTable.Indicator"+String(Counter)+" - TotalTable.Indicator1 AS Deviation"+String(Counter);
					//вал
					TotalTableResources = TotalTableResources + ","
					+ " TotalTable.CurIndicator"+String(Counter)+" - TotalTable.CurIndicator1 AS CurDeviation"+String(Counter);
					
					TotalTableResources = TotalTableResources + ","
					+ " CASE WHEN TotalTable.Indicator1 = 0 
					| Then 0 
					| Else(1-(TotalTable.Indicator"+String(Counter)+")/TotalTable.Indicator1)*-100 END
					| AS DeviationRel"+String(Counter);
					TotalTableResources = TotalTableResources + ","
					+ " CASE WHEN TotalTable.Indicator1 = 0 
					| Then 0 
					| Else((TotalTable.Indicator"+String(Counter)+")/TotalTable.Indicator1)*100 END
					| AS Execution"+String(Counter);
					TotalTableResourcesSelected = TotalTableResourcesSelected + ","
					+ " Deviation"+String(Counter)+" AS Deviation"+String(Counter);
					TotalTableResourcesSelected = TotalTableResourcesSelected + ","
					+ " DeviationRel"+String(Counter)+" AS DeviationRel"+String(Counter);
					TotalTableResourcesSelected = TotalTableResourcesSelected + ","
					+ " Execution"+String(Counter)+" AS Execution"+String(Counter);
					//вал
					TotalTableResources = TotalTableResources + ","
					+ " CASE WHEN TotalTable.CurIndicator1 = 0 
					| Then 0 
					| Else(1-(TotalTable.CurIndicator"+String(Counter)+")/TotalTable.CurIndicator1)*-100 END
					| AS CurDeviationRel"+String(Counter);
					TotalTableResources = TotalTableResources + ","
					+ " CASE WHEN TotalTable.CurIndicator1 = 0 
					| Then 0 
					| Else((TotalTable.CurIndicator"+String(Counter)+")/TotalTable.CurIndicator1)*100 END
					| AS CurExecution"+String(Counter);
					TotalTableResourcesSelected = TotalTableResourcesSelected + ","
					+ " CurDeviation"+String(Counter)+" AS CurDeviation"+String(Counter);
					TotalTableResourcesSelected = TotalTableResourcesSelected + ","
					+ " CurDeviationRel"+String(Counter)+" AS CurDeviationRel"+String(Counter);
					TotalTableResourcesSelected = TotalTableResourcesSelected + ","
					+ " CurExecution"+String(Counter)+" AS CurExecution"+String(Counter);
				EndIf;
				
			EndIf; // Если заполнен сценарий
			
			Counter = Counter + 1;
		EndDo; // Таблица "СравниваемыеДанные"
		
		QueryText = StrReplace(QueryText,"%ResourcesForTotalTable%",			ResourcesForTotalTable);
		QueryText = StrReplace(QueryText,"%ResourcesForTotalTableSelected%",	ResourcesForTotalTableSelected);
		QueryText = StrReplace(QueryText,"%QueryForNextResource%",			QueryForNextResource);
		QueryText = StrReplace(QueryText,"%TotalTableResources%",				TotalTableResources);
		QueryText = StrReplace(QueryText,"%TotalTableResourcesSelected%",	TotalTableResourcesSelected);
		
		If InfoStructure.StructureType = Enums.fmInfoStructureTypes.CashflowBudget Then
			QueryText = StrReplace(QueryText,"fmIncomesAndExpensesItems","fmCashflowItems");
			QueryText = StrReplace(QueryText,"fmIncomesAndExpenses","fmCashflowBudget");
		EndIf;	
	Else // СТАНДАРТНОЕ ПРЕДСТАВЛЕНИЕ
		
		
		ResourcesForTotalTable = "";				// Текст вычисления ресурсов итоговой таблицы
		ResourcesForTotalTableSelected = ""; 	// Текст выбранных ресурсов для итоговой таблицы
		QueryForNextResource = "";			// Текст запроса-объединения для всех ресурсов
		TotalTableResources = "";				// Текст получения ресурсов итоговой таблицы
		TotalTableResourcesSelected = "";		// Текст выбранных ресурсов в итоговой таблице
		
		// Неизменяемая часть запроса
		QueryText = "
		|SELECT
		|fmInfoStructuresSections.Ref AS Ref,
		|fmInfoStructuresSections.StructureSectionType AS StructureSectionType
		|INTO FinancialReportStructureIndicators
		|FROM
		|	Catalog.fmInfoStructuresSections AS fmInfoStructuresSections
		|WHERE
		|	fmInfoStructuresSections.Owner = &ReportVariant
		|;
		|///////////////////////////////////////////////////////////////////////////////
		|%QueryForNextResource%
		|;
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	IncomesExpensesTurnoversGlue.Period AS Period,
		|	IncomesExpensesTurnoversGlue.Scenario AS Scenario,
		|	IncomesExpensesTurnoversGlue.Project AS Project,
		|	IncomesExpensesTurnoversGlue.Department AS Department,
		|	IncomesExpensesTurnoversGlue.BalanceUnit AS BalanceUnit,
		|	IncomesExpensesTurnoversGlue.Item AS Item,
		|	CASE 
		|	WHEN IncomesExpensesTurnoversGlue.Analytics1 = Undefined Then NULL
		|	Else IncomesExpensesTurnoversGlue.Analytics1
		|	END AS Analytics1,	
		|	CASE 
		|	WHEN IncomesExpensesTurnoversGlue.Analytics2 = Undefined Then NULL
		|	Else IncomesExpensesTurnoversGlue.Analytics2
		|	END AS Analytics2,
        |	CASE 
		|	WHEN IncomesExpensesTurnoversGlue.Analytics3 = Undefined Then NULL
		|	Else IncomesExpensesTurnoversGlue.Analytics3
		|	END AS Analytics3,
		|	IncomesExpensesTurnoversGlue.Currency AS Currency,
		|	SUM(IncomesExpensesTurnoversGlue.AmountTurnover) AS AmountTurnover,
		|	SUM(IncomesExpensesTurnoversGlue.CurrencyAmountTurnover) AS CurrencyAmountTurnover,
		|	SUM(IncomesExpensesTurnoversGlue.PreliminaryBudgetTurnover) AS PreliminaryBudgetTurnover,
		|	SUM(IncomesExpensesTurnoversGlue.PreliminaryBudgetCurTurnover) AS PreliminaryBudgetCurTurnover,
		|	IncomesExpensesTurnoversGlue.OperationType AS OperationType
		|INTO TTIncomesExpensesPlanTurnoversJoined
		|FROM
		|	TTIncomesExpensesTurnoversGlue AS IncomesExpensesTurnoversGlue
		|Group by
		|	IncomesExpensesTurnoversGlue.Analytics1,
		|	IncomesExpensesTurnoversGlue.Analytics2,
		|	IncomesExpensesTurnoversGlue.Analytics3,
		|	IncomesExpensesTurnoversGlue.Currency,
		|	IncomesExpensesTurnoversGlue.Item,
		|	IncomesExpensesTurnoversGlue.Department,
		|	IncomesExpensesTurnoversGlue.Project,
		|	IncomesExpensesTurnoversGlue.BalanceUnit,
		|	IncomesExpensesTurnoversGlue.Period,
		|	IncomesExpensesTurnoversGlue.Scenario,
		|	IncomesExpensesTurnoversGlue.OperationType
		|;
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT ALLOWED
		|	ISNULL(IncomesExpensesPlanTurnoversJoined.Period, DATETIME(1, 1, 1, 0, 0, 0)) AS Period,
		|	ISNULL(IncomesExpensesPlanTurnoversJoined.Department, Value(Catalog.fmDepartments.EmptyRef)) AS Departments,
		|	ISNULL(IncomesExpensesPlanTurnoversJoined.Project, Value(Catalog.fmProjects.EmptyRef)) AS Project,
		|	ISNULL(IncomesExpensesPlanTurnoversJoined.Item, Value(Catalog.fmIncomesAndExpensesItems.EmptyRef)) AS IncomesExpensesItem,
		|	IncomesExpensesPlanTurnoversJoined.Analytics1 AS Analytics1,
		|	IncomesExpensesPlanTurnoversJoined.Analytics2 AS Analytics2,
		|	IncomesExpensesPlanTurnoversJoined.Analytics3 AS Analytics3,
		|	IncomesExpensesPlanTurnoversJoined.Currency AS Currency,
		|	FinancialReportStructureIndicators.Ref AS Ref,
		|	ISNULL(IncomesExpensesPlanTurnoversJoined.BalanceUnit, Value(Catalog.fmBalanceUnits.EmptyRef)) AS BalanceUnit,
		|	%ResourcesForTotalTable%
		|INTO TotalTable
		|{SELECT
		|	Period,
		|	Departments.* AS Departments,
		|	Project.* AS Project,
		|	Analytics1.* AS Analytics1,
		|	Analytics2.* AS Analytics2,
		|	Analytics3.* AS Analytics3,
		|	Currency.* AS Currency,
		|	IncomesExpensesItem.* AS Item,
		|	Ref.* AS Section,
		|	BalanceUnit.* AS BalanceUnit,
		|	%ResourcesForTotalTableSelected%}
		|FROM
		|		FinancialReportStructureIndicators AS FinancialReportStructureIndicators
		|	LEFT JOIN TTIncomesExpensesPlanTurnoversJoined AS IncomesExpensesPlanTurnoversJoined
		|	ON (FinancialReportStructureIndicators.StructureSectionType = IncomesExpensesPlanTurnoversJoined.OperationType)
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	TotalTable.Departments AS Departments,
		|	TotalTable.Project AS Project,
		|	TotalTable.Analytics1 AS Analytics1,
		|	TotalTable.Analytics2 AS Analytics2,
		|	TotalTable.Analytics3 AS Analytics3,
		|	TotalTable.Currency AS Currency,
		|	TotalTable.IncomesExpensesItem AS IncomesExpensesItem,
		|	TotalTable.Ref AS Ref,
		|	TotalTable.BalanceUnit AS BalanceUnit,
		|	TotalTable.Period AS Period,
		|	%TotalTableResources%
		|{SELECT
		|	Departments.* AS Departments,
		|	Project.* AS Project,
		|	Analytics1.* AS Analytics1,
		|	Analytics2.* AS Analytics2,
		|	Analytics3.* AS Analytics3,
		|	Currency.* AS Currency,
		|	IncomesExpensesItem.* AS Item,
		|	Ref.* AS Section,
		|	BalanceUnit.* AS BalanceUnit,
		|	Period,
		|	%TotalTableResourcesSelected%}
		|FROM
		|	TotalTable AS TotalTable
		|WHERE
		|	NOT TotalTable.Period = DATETIME(1, 1, 1, 0, 0, 0)";
		
		Counter = 1;
		CompDataCount = ComparedData.Count();
		For Each CurComparedData In ComparedData Do
			Comma = ?(Counter=1,"",",");
			If ValueIsFilled(CurComparedData.PlanningScenario) Then
				ResourcesForTotalTable = ResourcesForTotalTable + Comma + "
				|ISNULL(CASE WHEN IncomesExpensesPlanTurnoversJoined.Scenario = ""ComparedData"+String(Counter)+""" Then
				|IncomesExpensesPlanTurnoversJoined.AmountTurnover
				|Else 0 END, 0) AS Indicator"+String(Counter)+",
				|ISNULL(CASE WHEN IncomesExpensesPlanTurnoversJoined.Scenario = ""ComparedData"+String(Counter)+""" Then
				|IncomesExpensesPlanTurnoversJoined.CurrencyAmountTurnover
				|Else 0 END, 0) AS CurIndicator"+String(Counter)+"
				|";
				
				ResourcesForTotalTableSelected = ResourcesForTotalTableSelected 
				+ Comma + "Indicator"+String(Counter)+" AS Amount"+String(Counter);
				ResourcesForTotalTableSelected = ResourcesForTotalTableSelected 
				+ "," + "CurIndicator"+String(Counter)+" AS CurAmount"+String(Counter);

				
				If CurComparedData.PlanningScenario.ScenarioType = Enums.fmBudgetingScenarioTypes.Plan
					AND (Constants.fmBudgetVersioning.Get() = Enums.fmBudgetVersioning.EveryDay OR Constants.fmBudgetVersioning.Get() = Enums.fmBudgetVersioning.EveryMonth) Then
					VersionCondition = "
					|WHERE   
					|	 IncomesExpensesPlanTurnovers.VersionPeriod <= &VersionPeriod"+String(Counter)+"
					|";
				Else
					VersionCondition = "";
				EndIf;
				QueryForNextResource = QueryForNextResource + ?(Counter=1,""," UNION ALL ") + "
					|SELECT "+?(Counter = 1,"ALLOWED","")+"
					|	IncomesExpensesPlanTurnovers.Department AS Department,
					|	IncomesExpensesPlanTurnovers.Project AS Project,
					|	IncomesExpensesPlanTurnovers.Analytics1 AS Analytics1,
					|	IncomesExpensesPlanTurnovers.Analytics2 AS Analytics2,
					|	IncomesExpensesPlanTurnovers.Analytics3 AS Analytics3,
					|	IncomesExpensesPlanTurnovers.Currency AS Currency,
					|	IncomesExpensesPlanTurnovers.BalanceUnit AS BalanceUnit,
					|	"+?(Counter = 1,"IncomesExpensesPlanTurnovers.Period","DATEADD(&BeginOfPeriod1, Month, Month(IncomesExpensesPlanTurnovers.Period) - Month(&BeginOfPeriod"+String(Counter)+") + (Year(IncomesExpensesPlanTurnovers.Period) - Year(&BeginOfPeriod"+String(Counter)+")) * 12)")+" AS Period,
					|	""ComparedData"+String(Counter)+""" AS Scenario,
					|	IncomesExpensesPlanTurnovers.Item AS Item,
					|	CASE
					|		WHEN &ConsiderBudgetsNotInAgreement
					|			Then IncomesExpensesPlanTurnovers.AmountTurnover + IncomesExpensesPlanTurnovers.NotAgreedAmountTurnover
					|			Else IncomesExpensesPlanTurnovers.AmountTurnover
					|	END AS AmountTurnover,
					|	CASE
					|		WHEN &ConsiderBudgetsNotInAgreement
					|			Then IncomesExpensesPlanTurnovers.CurrencyAmountTurnover + IncomesExpensesPlanTurnovers.NotAgreedCurrencyAmountTurnover
					|			Else IncomesExpensesPlanTurnovers.CurrencyAmountTurnover
					|	END AS CurrencyAmountTurnover,
					|	IncomesExpensesPlanTurnovers.NotAgreedAmountTurnover AS PreliminaryBudgetTurnover,
					|	IncomesExpensesPlanTurnovers.NotAgreedCurrencyAmountTurnover AS PreliminaryBudgetCurTurnover,
					|	CASE
					|		WHEN IncomesExpensesPlanTurnovers.OperationType = VALUE(Enum.fmBudgetFlowOperationTypes.InnerIncomes)
					|			Then VALUE(Enum.fmBudgetFlowOperationTypes.Incomes)
					|		WHEN IncomesExpensesPlanTurnovers.OperationType = VALUE(Enum.fmBudgetFlowOperationTypes.InnerExpenses)
					|			Then VALUE(Enum.fmBudgetFlowOperationTypes.Expenses)
					|			Else IncomesExpensesPlanTurnovers.OperationType
					|	END AS OperationType
					|"+?(Counter = 1,"INTO TTIncomesExpensesTurnoversGlue","")+"
					|FROM
					|	AccumulationRegister.fmIncomesAndExpenses.Turnovers(
					|		&BeginOfPeriod"+String(Counter)+",
					|		&EndOfPeriod"+String(Counter)+",
					|		Month,
					|		Scenario = &PlanningScenario"+String(Counter)+"
					|			AND OperationType IN (&Operations)) AS IncomesExpensesPlanTurnovers
					|"+VersionCondition;
					
										
				
				TotalTableResources = TotalTableResources + Comma
				+ " TotalTable.Indicator"+String(Counter)+" AS Indicator"+String(Counter);
				TotalTableResources = TotalTableResources + ","
				+ " TotalTable.CurIndicator"+String(Counter)+" AS CurIndicator"+String(Counter);
				TotalTableResourcesSelected = TotalTableResourcesSelected + Comma
				+ " Indicator"+String(Counter)+" AS Amount"+String(Counter);
				TotalTableResourcesSelected = TotalTableResourcesSelected + ","
				+ " CurIndicator"+String(Counter)+" AS CurAmount"+String(Counter);
				
				If AddDeviations Then
					
					
					TotalTableResources = TotalTableResources + ","
					+ " TotalTable.Indicator"+String(Counter)+" - TotalTable.Indicator1 AS Deviation"+String(Counter);
					//вал
					TotalTableResources = TotalTableResources + ","
					+ " TotalTable.CurIndicator"+String(Counter)+" - TotalTable.CurIndicator1 AS CurDeviation"+String(Counter);
					
					TotalTableResources = TotalTableResources + ","
					+ " CASE WHEN TotalTable.Indicator1 = 0 
					| Then 0 
					| Else(1-(TotalTable.Indicator"+String(Counter)+")/TotalTable.Indicator1)*-100 END
					| AS DeviationRel"+String(Counter);
					TotalTableResources = TotalTableResources + ","
					+ " CASE WHEN TotalTable.Indicator1 = 0 
					| Then 0 
					| Else((TotalTable.Indicator"+String(Counter)+")/TotalTable.Indicator1)*100 END
					| AS Execution"+String(Counter);
					TotalTableResourcesSelected = TotalTableResourcesSelected + ","
					+ " Deviation"+String(Counter)+" AS Deviation"+String(Counter);
					TotalTableResourcesSelected = TotalTableResourcesSelected + ","
					+ " DeviationRel"+String(Counter)+" AS DeviationRel"+String(Counter);
					TotalTableResourcesSelected = TotalTableResourcesSelected + ","
					+ " Execution"+String(Counter)+" AS Execution"+String(Counter);
					//вал
					TotalTableResources = TotalTableResources + ","
					+ " CASE WHEN TotalTable.CurIndicator1 = 0 
					| Then 0 
					| Else(1-(TotalTable.CurIndicator"+String(Counter)+")/TotalTable.CurIndicator1)*-100 END
					| AS CurDeviationRel"+String(Counter);
					TotalTableResources = TotalTableResources + ","
					+ " CASE WHEN TotalTable.CurIndicator1 = 0 
					| Then 0 
					| Else((TotalTable.CurIndicator"+String(Counter)+")/TotalTable.CurIndicator1)*100 END
					| AS CurExecution"+String(Counter);
					TotalTableResourcesSelected = TotalTableResourcesSelected + ","
					+ " CurDeviation"+String(Counter)+" AS CurDeviation"+String(Counter);
					TotalTableResourcesSelected = TotalTableResourcesSelected + ","
					+ " CurDeviationRel"+String(Counter)+" AS CurDeviationRel"+String(Counter);
					TotalTableResourcesSelected = TotalTableResourcesSelected + ","
					+ " CurExecution"+String(Counter)+" AS CurExecution"+String(Counter);

				EndIf;
				
			EndIf; // Если заполнен сценарий
			
			Counter = Counter + 1;
		EndDo; // Таблица "СравниваемыеДанные"
		
		QueryText = StrReplace(QueryText,"%ResourcesForTotalTable%",			ResourcesForTotalTable);
		QueryText = StrReplace(QueryText,"%ResourcesForTotalTableSelected%",	ResourcesForTotalTableSelected);
		QueryText = StrReplace(QueryText,"%QueryForNextResource%",			QueryForNextResource);
		QueryText = StrReplace(QueryText,"%TotalTableResources%",				TotalTableResources);
		QueryText = StrReplace(QueryText,"%TotalTableResourcesSelected%",	TotalTableResourcesSelected);
		
		If InfoStructure.StructureType = Enums.fmInfoStructureTypes.CashflowBudget Then
			QueryText = StrReplace(QueryText,"fmIncomesAndExpensesItems","fmCashflowItems");
			QueryText = StrReplace(QueryText,"fmIncomesAndExpenses","fmCashflowBudget");
		EndIf;	

	EndIf; // По структуре или без структуры
	
	Return QueryText;
	
EndFunction

Procedure AddSetDCSParameters()
	
	Counter = 1;
	For Each CurComparedData In ComparedData Do
		
		CurSwithPlanFact = CurComparedData.PlanningScenario.ScenarioType;
		
		// Если в тек. строке фактический сценарий, то по нему не должно быть ограничения по периоду версии,
		// поэтому берем начало тек. месяца в качестве параметра(версии больше, чем начало тек. месяца быть не может)
		If CurSwithPlanFact = Enums.fmBudgetingScenarioTypes.Fact Then
			CurParameterVersionPeriod = BegOfMonth(CurrentDate());
		Else
			CurParameterVersionPeriod = CurComparedData.VersionPeriod;
		EndIf;
		fmReportsClientServer.SetParameter(SettingsComposer, "BeginOfPeriod"+String(Counter),			BegOfDay(CurComparedData.BeginOfPeriod));
		fmReportsClientServer.SetParameter(SettingsComposer, "EndOfPeriod"+String(Counter),			EndOfDay(CurComparedData.EndOfPeriod));
		fmReportsClientServer.SetParameter(SettingsComposer, "PlanningScenario"+String(Counter),	CurComparedData.PlanningScenario);
		fmReportsClientServer.SetParameter(SettingsComposer, "VersionPeriod"+String(Counter),			CurParameterVersionPeriod);
		fmReportsClientServer.SetParameter(SettingsComposer, "BudgetingSection"+String(Counter),	CurSwithPlanFact);
		
		Counter = Counter + 1;
	EndDo;
	
	//Параметр "Периодичность"
	If ValueIsFilled(PeriodType) Then
		fmReportsClientServer.SetParameter(SettingsComposer, "PeriodType", PeriodType);
	Else
		fmReportsClientServer.SetParameter(SettingsComposer, "PeriodType", Enums.fmAvailableReportPeriods.Month);
	EndIf;
	
	//Параметр "ВариантОтчета"
	If ValueIsFilled(InfoStructure) Then
		fmReportsClientServer.SetParameter(SettingsComposer, "ReportVariant", InfoStructure);
	Else
		If StructureType = Enums.fmInfoStructureTypes.IncomesAndExpensesBudget Then
			fmReportsClientServer.SetParameter(SettingsComposer, "ReportVariant", Catalogs.fmInfoStructures.WithoutStructureIE);
		Else
			fmReportsClientServer.SetParameter(SettingsComposer, "ReportVariant", Catalogs.fmInfoStructures.WithoutStructureCF);
		EndIf;
	EndIf;
	//С учетом несогласованных бюджетов
	fmReportsClientServer.SetParameter(SettingsComposer, "ConsiderBudgetsNotInAgreement", ConsiderBudgetsNotInAgreement);
	
	//ФорматОтображения
	ParameterViewFormat = SettingsComposer.Settings.DataParameters.Items.Find("ViewFormat");
	If ParameterViewFormat <> Undefined Then
		ParameterViewFormat.Value = ViewFormat;
		ParameterViewFormat.Use = True;
	EndIf;
	
	//ПредставлениеБалансоваяЕдиницаПодр
	ParameterPresentationBalanceUnitDep = SettingsComposer.Settings.DataParameters.Items.Find("PresentationBalanceUnitDep");
	If ParameterPresentationBalanceUnitDep <> Undefined Then
		ParameterPresentationBalanceUnitDep.Value = PresentationBalanceUnitDep;
		ParameterPresentationBalanceUnitDep.Use = True;
	EndIf;
	
	//Переключатель валюта
	fmReportsClientServer.SetParameter(SettingsComposer, "SwitchCurrency",  "Functional accounting currency");
	//Флаг учитывать операции распределения
	fmReportsClientServer.SetParameter(SettingsComposer, "ConsiderInternalSettlements", ConsiderInternalSettlements);
	
	//Флаг учитывать операции распределения
	Operations = New Array;
	If StructureType = Enums.fmInfoStructureTypes.CashflowBudget Then
		Operations.Add(Enums.fmBudgetFlowOperationTypes.Inflow);
		Operations.Add(Enums.fmBudgetFlowOperationTypes.Outflow);
	Else	
		Operations.Add(Enums.fmBudgetFlowOperationTypes.Incomes);
		Operations.Add(Enums.fmBudgetFlowOperationTypes.Expenses);
		If ConsiderInternalSettlements Then
			Operations.Add(Enums.fmBudgetFlowOperationTypes.InnerIncomes);
			Operations.Add(Enums.fmBudgetFlowOperationTypes.InnerExpenses);
		EndIf;
	EndIf;
	fmReportsClientServer.SetParameter(SettingsComposer, "Operations", Operations);
	
EndProcedure

Function GetDeviationTotalFieldExpression(DeviationFieldName,LineNumber = Undefined,CurrencyDeviation)
	
	If LineNumber = Undefined Then
		FieldName = DeviationFieldName;
	Else
		FieldName = DeviationFieldName + String(LineNumber);
	EndIf;
	If NOT ValueIsFilled(ViewFormat) Then
		FormatFrom = "";
	ElsIf  ViewFormat=Enums.fmRoundMethods.WithoutRound Then
		FormatFrom = "ND=15; NFD=2";	
	Else
		Rounds = New Map();
		Rounds.Insert(PredefinedValue("Enum.fmRoundMethods.EmptyRef"), "0");
		Rounds.Insert(PredefinedValue("Enum.fmRoundMethods.WithoutRound"), "0");
		Rounds.Insert(PredefinedValue("Enum.fmRoundMethods.Unit"), "0");
		Rounds.Insert(PredefinedValue("Enum.fmRoundMethods.Ten"), "1");
		Rounds.Insert(PredefinedValue("Enum.fmRoundMethods.Hundred"), "2");
		Rounds.Insert(PredefinedValue("Enum.fmRoundMethods.Thousand"), "3");
		Rounds.Insert(PredefinedValue("Enum.fmRoundMethods.TenThousands"), "4");
		Rounds.Insert(PredefinedValue("Enum.fmRoundMethods.HundredThousands"), "5");
		Rounds.Insert(PredefinedValue("Enum.fmRoundMethods.Million"), "6");
		FormatFrom =  "NFD=0; NS="+(Rounds[ViewFormat]);
	EndIf;

	Expression = "";
	If DeviationFieldName = "Deviation" Then
		If CurrencyDeviation Then
			Expression = "
			|Format(SUM(Cur"+FieldName+"), """+FormatFrom+""")";
		Else	
			Expression = "
			|Format(SUM("+FieldName+"), """+FormatFrom+""")";
		EndIf;

	ElsIf DeviationFieldName = "DeviationRel" Then
		If CurrencyDeviation Then
			Expression = "CASE WHEN SUM(CurAmount1) = 0 Then 0 Else 
			| Format((1-(SUM(CurAmount"+String(LineNumber)+") / SUM(CurAmount1)))*-100,""ND=15; NFD=2"") END";
		Else
			Expression = "CASE WHEN SUM(Amount1) = 0 Then 0 Else 
			| Format((1-(SUM(Amount"+String(LineNumber)+") / SUM(Amount1)))*-100,""ND=15; NFD=2"") END";

		EndIf;
		
	ElsIf DeviationFieldName = "Execution" Then
		If CurrencyDeviation Then
			Expression = "CASE WHEN SUM(CurAmount1) = 0 Then 0 Else 
			| Format(((SUM(CurAmount"+String(LineNumber)+") / SUM(CurAmount1)))*100,""ND=15; NFD=2"") END";
		Else
			Expression = "CASE WHEN SUM(Amount1) = 0 Then 0 Else 
			| Format(((SUM(Amount"+String(LineNumber)+") / SUM(Amount1)))*100,""ND=15; NFD=2"") END";
			
		EndIf;
	EndIf;
	
	Return Expression;
	
EndFunction

Function GetDeviationColumnTitle(DeviationFieldName)
	
	Title = "";
	If DeviationFieldName = "Deviation" Then
		Title = NStr("en='Deviation, abs.';ru='Отклонение, абс.'");
	ElsIf DeviationFieldName = "DeviationRel" Then
		Title = NStr("en='Deviation, %';ru='Отклонение, %'");
	ElsIf DeviationFieldName = "Execution" Then
		Title = NStr("en='Implementation, %';ru='Исполнение, %'");
	EndIf;
	Return Title;
	
EndFunction

Procedure SetStructureForReportOutput()
	
	Structure = SettingsComposer.Settings.Structure.Add(Type("DataCompositionTable"));
	//Установим группировки отчета по строкам
	SetReportGroups(Structure.Rows, GroupingByRows, "Rows");
	//Установим группировки отчета по колонкам
	SetReportGroups(Structure.Columns, GroupingByColumns, "Columns");

EndProcedure

// Процедура, устанавливающая группировки в структуре в зависимости от выбранных на форме полей группировок
//
Procedure SetReportGroups(VAL TableStructure, Group, GroupType)
	
	//Для строк установим фиксированную группировку "Раздел" с типом группировки "Иерархия"
	If GroupType = "Rows" Then
		TableStructure = TableStructure.Add();
 		GroupField = TableStructure.GroupFields.Items.Add(Type("DataCompositionGroupField"));
		GroupField.Use = True;
		GroupField.Field = New DataCompositionField("Section");
		GroupField.GroupType = DataCompositionGroupType.Hierarchy;
		TableStructure.Selection.Items.Add(Type("DataCompositionAutoSelectedField"));
		TableStructure.Order.Items.Add(Type("DataCompositionAutoOrderItem"));
		
		//цвет текста
		Query = New Query;
		Query.Text = "SELECT
		|	fmInfoStructuresSections.Ref AS Section,
		|	fmInfoStructuresSections.ItalicFont AS Italic,
		|	fmInfoStructuresSections.TextColor AS TextColor,
		|	fmInfoStructuresSections.BoldFont AS Bold
		|FROM
		|	Catalog.fmInfoStructuresSections AS fmInfoStructuresSections
		|WHERE
		|	fmInfoStructuresSections.Owner = &Structure";
		Query.SetParameter("Structure",InfoStructure);
		SectionsAppearance = Query.Execute().Unload();
		
		For Each RowAppearance In SectionsAppearance Do
			If RowAppearance.Italic OR RowAppearance.Bold OR NOT IsBlankString(RowAppearance.TextColor) Then
				//Курсив, если реквизит соответствующего раздела "Курсив" равен Истина
				NewConditionalAppearanceItem 					= TableStructure.ConditionalAppearance.Items.Add();
				NewConditionalAppearanceItem.Use 		= True;
				
				NewDataCompositionAppearanceField 				= NewConditionalAppearanceItem.Fields.Items.Add();
				NewDataCompositionAppearanceField.Use 	= True;
				NewDataCompositionAppearanceField.Field 			= New DataCompositionField("Section");
				NewFilterItem 									= NewConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
				NewFilterItem.LeftValue 					= New DataCompositionField("Section");
				NewFilterItem.Use 					= True;
				NewFilterItem.RightValue 					= RowAppearance.Section;
				
				NewConditionalAppearanceItem.Appearance.Items[5].Use 	= True;
				NewConditionalAppearanceItem.Appearance.Items[5].Value 		= New Font( , 9, RowAppearance.Bold, RowAppearance.Italic);
				If NOT IsBlankString(RowAppearance.TextColor) Then
					//Цвет текста
					ReaderXML 										= New XMLReader;
					ObjectTypeXDTO									= XDTOFactory.Type("http://v8.1c.ru/8.1/data/ui","Color");
					ReaderXML.SetString(RowAppearance.TextColor);
					ObjectXDTO										= XDTOFactory.ReadXML(ReaderXML, ObjectTypeXDTO);
					Serializer									= New XDTOSerializer(XDTOFactory);
					CurTextColor					= Serializer.ReadXDTO(ObjectXDTO);
					TextColorItem = NewConditionalAppearanceItem.Appearance.Items.Find("TextColor");
					TextColorItem.Value = CurTextColor;
					TextColorItem.Use = True;
				EndIf;

				
			EndIf;
		EndDo;
		TableStructure = TableStructure.Structure;
	EndIf;
	
	For Each SelectedGroupField In Group Do
		If SelectedGroupField.Use Then
			
			//Если выводим группировку с типом иерархии "С группами", то сделаем дополнительную группировку "Детальные записи"
			//без выбранных полей для вывода слева колонки итогов
			If SelectedGroupField.GroupType = "With groups" Then
				DetailRecords = TableStructure.Add();
				DetailRecords.Use = True;
			EndIf;
			
			//Добавим остальные группировки
			TableStructure = TableStructure.Add();
			GroupField = TableStructure.GroupFields.Items.Add(Type("DataCompositionGroupField"));
			GroupField.Use = True;
			GroupField.Field = New DataCompositionField(SelectedGroupField.Field);
			If SelectedGroupField.GroupType = "With groups" Then
				GroupField.GroupType = DataCompositionGroupType.Hierarchy;
				TableStructure.OutputParameters.Items[8].Use = True;
				TableStructure.OutputParameters.Items[8].Value = DataCompositionTotalPlacement.None;
			ElsIf SelectedGroupField.GroupType = "Only groups" Then
				GroupField.GroupType = DataCompositionGroupType.HierarchyOnly;
			Else
				GroupField.GroupType = DataCompositionGroupType.Items;
			EndIf;
			TableStructure.Selection.Items.Add(Type("DataCompositionAutoSelectedField"));
			TableStructure.Order.Items.Add(Type("DataCompositionAutoOrderItem"));
			//Не будем выводить пустые статьи затрат
			If SelectedGroupField.Field = "Item" Then
				NewFilter = TableStructure.Filter.Items.Add(Type("DataCompositionFilterItem"));
				NewFilter.Use = True;
				NewFilter.ComparisonType = DataCompositionComparisonType.NotEqual;
				NewFilter.LeftValue = New DataCompositionField("Item");
				NewFilter.RightValue = Catalogs.fmIncomesAndExpensesItems.EmptyRef();
				TableStructure.OutputParameters.Items[12].Use = True;
				TableStructure.OutputParameters.Items[12].Value 		= DataCompositionTextOutputType.DontOutput;
			EndIf;
			//Не будем выводить пустые подразделения
			If SelectedGroupField.Field = "Departments" Then
				NewFilter = TableStructure.Filter.Items.Add(Type("DataCompositionFilterItem"));
				NewFilter.Use = True;
				NewFilter.ComparisonType = DataCompositionComparisonType.NotEqual;
				NewFilter.LeftValue = New DataCompositionField("Departments");
				NewFilter.RightValue = Catalogs.fmDepartments.EmptyRef();
				TableStructure.OutputParameters.Items[12].Use = True;
				TableStructure.OutputParameters.Items[12].Value 		= DataCompositionTextOutputType.DontOutput;
			EndIf;
			//Не будем выводить пустые БалансоваяЕдиница
			If SelectedGroupField.Field = "BalanceUnit" Then
				NewFilter = TableStructure.Filter.Items.Add(Type("DataCompositionFilterItem"));
				NewFilter.Use = True;
				NewFilter.ComparisonType = DataCompositionComparisonType.NotEqual;
				NewFilter.LeftValue = New DataCompositionField("BalanceUnit");
				NewFilter.RightValue = Catalogs.fmBalanceUnits.EmptyRef();
				TableStructure.OutputParameters.Items[12].Use = True;
				TableStructure.OutputParameters.Items[12].Value 		= DataCompositionTextOutputType.DontOutput;
			EndIf;
			TableStructure = TableStructure.Structure;
		EndIf;
	EndDo;
		
EndProcedure //УстановитьГруппировкиОтчета()

Procedure FillCheckProcessing(Cancel, CheckingAttributes)
		
	Counter = 1;
	For Each CurCompData In ComparedData Do
		If NOT ValueIsFilled(CurCompData.BeginOfPeriod) OR NOT ValueIsFilled(CurCompData.EndOfPeriod) Then
			Cancel = True;
			CommonClientServer.MessageToUser(StrTemplate(NStr("en='The ""Period"" column in row <%1>  of the comparable data list is not filled in. ';ru='Не заполнена колонка ""Период"" в строке <%1> списка сравниваемых данных!'"), Counter));
		EndIf;
		Counter = Counter + 1;
	EndDo;
	
	// Проверка сопоставимости произвольных периодов
	If PeriodType = Enums.fmAvailableReportPeriods.ArbitraryPeriod 
		AND ComparedData.Count() Then
		
		DifferenceDaysInFirstPeriod = (BegOfDay(ComparedData[0].EndOfPeriod)-BegOfDay(ComparedData[0].BeginOfPeriod))/(60*60*24);
		Counter = 1;
		For Each CurCompData In ComparedData Do
			DifferenceDaysInSecondPeriod = (BegOfDay(CurCompData.EndOfPeriod)-BegOfDay(CurCompData.BeginOfPeriod))/(60*60*24);
			If Round(DifferenceDaysInFirstPeriod / 30) <> Round(DifferenceDaysInSecondPeriod / 30) Then
				CommonClientServer.MessageToUser(StrTemplate(NStr("en='The period in <%1>  row of the comparable data list is not similar in the months number.';ru='Период в строке <%1> списка сравниваемых данных не сопоставим по количеству месяцев!'"), Counter));
				Cancel = True;
			EndIf;
			Counter = Counter + 1;
		EndDo;
		
	EndIf;
	
EndProcedure //ОбработкаПроверкиЗаполнения()

//Процедура, выполняющая отчет в таблицу значений
//
Procedure FormResultTable(ResultTable = Undefined, DataCompositionSchema = Undefined) Export

	//Уберем существующие группировки компоновщика настроек и создаим детальные записи (т.к система не дает выгружать данные в коллекцию значений таблицу)
	SettingsComposer.Settings.Structure[0].Use = False;
	SetStructureForReportOutputDetalRecords();
	
	//Выполним компоновку макета
	TemplateComposer = New DataCompositionTemplateComposer;
	CompositionTemplate = TemplateComposer.Execute(DataCompositionSchema, SettingsComposer.Settings,,, Type("DataCompositionValueCollectionTemplateGenerator"));
	
	//Инициализируем процессор компоновки
	CompositionProcessor = New DataCompositionProcessor;
	CompositionProcessor.Initialize(CompositionTemplate,,, True);
	
	//Вывод результата в таблицу значений
	ValueCollectionOutputProcessor = New DataCompositionResultValueCollectionOutputProcessor;
	ValueCollectionOutputProcessor.SetObject(ResultTable);
	ValueCollectionOutputProcessor.Output(CompositionProcessor, True);

EndProcedure //СформироватьТаблицуРезультата()

// Процедура, устанавливающая в качестве структуры вывода детальные записи.
// Вызывается при формировании отчета в режиме "Сводная таблица" и при сохранении в сводную таблицу Эксель
//
Procedure SetStructureForReportOutputDetalRecords()
	
	DetailRecords = SettingsComposer.Settings.Structure.Add(Type("DataCompositionGroup"));
	DetailRecords.Use = True;
	
	AutoField = DetailRecords.Selection.Items.Add(Type("DataCompositionAutoSelectedField"));
	AutoField.Use = True;
	
EndProcedure //УстановитьСтруктуруДляВыводаОтчетаДетальныеЗаписи()

Procedure SetDataSetFieldsFormat(DataSetDCS, Fields, FormatString)

	If TypeOf(Fields) = Type("String") Then

		If NOT IsBlankString(Fields) Then

			TextFields = StrReplace( Fields, " ", "" );
			TextFields = StrReplace( TextFields, ",", Chars.LF );

			Text = New TextDocument;
			Text.SetText(TextFields);

			FormattingFields = New Array;
			For RowsCn = 1 To Text.LineCount() Do
				FieldFromText = Text.GetLine(RowsCn);
				If NOT IsBlankString(FieldFromText) Then
					FormattingFields.Add(TrimAll(FieldFromText));
				EndIf;
			EndDo;

		Else

			Return;
		EndIf;

	ElsIf TypeOf(Fields) = Type("Array") Then

		FormattingFields = Fields;
	Else

		Return;
	EndIf;

	For Each FormattingField In FormattingFields Do

		DataSetDCSField = DataSetDCS.Fields.Find(FormattingField);
		If NOT DataSetDCSField = Undefined Then
			fmReportsClientServer.SetParameter(DataSetDCSField.Appearance, "Format", FormatString);
		EndIf;

	EndDo;

EndProcedure // УстановитьФорматПолейНабораДанных()

IndicatorSet = New Array;












