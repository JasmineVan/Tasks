
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// ПРОЦЕДУРЫ И ФУНКЦИИ ОБЩЕГО НАЗНАЧЕНИЯ

&AtServer
Procedure SettingsGenerating(DCSettings, VTConditionalAppearance)
	
	// УСЛОВНОЕ ОФОРМЛЕНИЕ
	For Each RowForCA In VTConditionalAppearance Do
		If RowForCA.Italic OR RowForCA.Bold OR NOT IsBlankString(RowForCA.TextColor) Then
			CAItem = DCSettings.ConditionalAppearance.Items.Add();
			AppearanceColorItem = CAItem.Appearance.Items.Find("Font");
			AppearanceColorItem.Value = New Font(,,RowForCA.Bold,RowForCA.Italic);
			AppearanceColorItem.Use = True;
			If NOT IsBlankString(RowForCA.TextColor) Then
				//Цвет текста
				ReaderXML 										= New XMLReader;
				ObjectTypeXDTO									= XDTOFactory.Type("http://v8.1c.ru/8.1/data/ui","Color");
				ReaderXML.SetString(RowForCA.TextColor);
				ObjectXDTO										= XDTOFactory.ReadXML(ReaderXML, ObjectTypeXDTO);
				Serializer									= New XDTOSerializer(XDTOFactory);
				CurTextColor					= Serializer.ReadXDTO(ObjectXDTO);
				
				TextColorItem = CAItem.Appearance.Items.Find("TextColor");
				TextColorItem.Value = CurTextColor;
				TextColorItem.Use = True;
			EndIf;
			fmReportsClientServer.AddFilter(CAItem.Filter, "Section", RowForCA.Section);
			fmReportsClientServer.AddFilter(CAItem.Filter, "IsSection", True);
		EndIf;
	EndDo;
	
EndProcedure

&AtServer
Function PrepareTable()
	
	DataTab = GetFromTempStorage(TabDataAddress);
	DataTab.Clear();
	ResourceName = StrReplace(Object.CurrentIndicator, " ", "");
	
	// Обход Исходной ТЗ
	InitialDataVT = GetFromTempStorage(InitialDataVTAddress);
	For Each CurRowInitial In InitialDataVT Do
		// Если Редактирование - то мы находимся в "листе" дерева. 
		// Именно он и является элементом с данными, а не с итогами по группировкам или по формуле.
		If CurRowInitial.Edit AND ValueIsFilled(CurRowInitial["Resource_"+ResourceName]) Then
			NewRowPlan = DataTab.Add();
			NewRowPlan.Period = CurRowInitial.Period;
			NewRowPlan.RecordType = CurRowInitial.RecordType;
			NewRowPlan.Item = CurRowInitial.Analytics;
			NewRowPlan.Analytics1 = CurRowInitial.Analytics1;
			NewRowPlan.Analytics2 = CurRowInitial.Analytics2;
			NewRowPlan.Analytics3 = CurRowInitial.Analytics3;
			NewRowPlan.Edit = True;
			NewRowPlan[ResourceName] = CurRowInitial["Resource_"+ResourceName];
		EndIf;
	EndDo;
	
	VTDataTable = DataTab.Copy();
	VTDataTable.Columns.Item.Name = "Analytics";
	For Each CurResource In Resources Do
		VTDataTable.Columns[CurResource.Value].Name = "Resource_"+CurResource.Value;
	EndDo;
	Return PutToTempStorage(VTDataTable);
	
EndFunction

&AtServer
Function FillSourceIndicators()
	
	IndicatorList = New ValueList;
	IndicatorList.Add("Amount", NStr("en='Amount';ru='Amount'"));
	
	//Элементы.ПоказательИсточника.СписокВыбора.Очистить();
	//Для Каждого ЭлементСпискаПоказателей Из СписокПоказателей Цикл
	//	Элементы.ПоказательИсточника.СписокВыбора.Добавить(ЭлементСпискаПоказателей.Значение, ЭлементСпискаПоказателей.Представление);
	//КонецЦикла;
	
	If IndicatorList.FindByValue(Object.SourceIndicator)=Undefined Then
		Object.SourceIndicator = Object.CurrentIndicator;
	EndIf;
	
EndFunction

&AtServer
Procedure FillPeriods()
	
	// Заполним периоды.
	Periods.Clear();
	If ValueIsFilled(Object.CurScenario) AND ValueIsFilled(Object.BeginOfPeriod) Then
		PeriodsTable = fmBudgeting.PeriodsTable(Object.CurScenario, Object.BeginOfPeriod);
		For Each CurRow In PeriodsTable Do
			Periods.Add(CurRow.BeginOfPeriod, CurRow.PeriodPresentation);
		EndDo;
	EndIf;
	
EndProcedure // ЗаполнитьПериоды()

&AtServer
// Процедура обработчик "ЗаполнитьДеревоБюджетов" 
// 
Procedure FillBudgetTree()
	
	BudgetTree.Clear();
	
	Resources.Clear();
	If Parameters.Prediction Then
		Resources.Add("InitialAmount", NStr("en='Source';ru='Источник'"));
		Resources.Add("Delta", NStr("en='Delta';ru='Дельта'"));
	EndIf;
	Resources.Add("Amount");
	
	Query = New Query("SELECT ALLOWED
	                      |	BudgetsData.Item AS Item,
	                      |	BudgetsData.Period AS Period,
	                      |	CASE
	                      |		WHEN &RoundMethod = Value(Enum.fmRoundMethods.WithoutRound)
	                      |				OR &RoundMethod = Value(Enum.fmRoundMethods.EmptyRef)
	                      |			Then BudgetsData.Amount
	                      |		WHEN &RoundMethod = Value(Enum.fmRoundMethods.One)
	                      |			Then CAST(BudgetsData.Amount AS Number(15, 0))
	                      |		WHEN &RoundMethod = Value(Enum.fmRoundMethods.Ten)
	                      |			Then CAST(BudgetsData.Amount / 10 AS Number(15, 0))
	                      |		WHEN &RoundMethod = Value(Enum.fmRoundMethods.Hundred)
	                      |			Then CAST(BudgetsData.Amount / 100 AS Number(15, 0))
	                      |		WHEN &RoundMethod = Value(Enum.fmRoundMethods.Thousand)
	                      |			Then CAST(BudgetsData.Amount / 1000 AS Number(15, 0))
	                      |		WHEN &RoundMethod = Value(Enum.fmRoundMethods.TenThousands)
	                      |			Then CAST(BudgetsData.Amount / 10000 AS Number(15, 0))
	                      |		WHEN &RoundMethod = Value(Enum.fmRoundMethods.HundredThousands)
	                      |			Then CAST(BudgetsData.Amount / 100000 AS Number(15, 0))
	                      |		WHEN &RoundMethod = Value(Enum.fmRoundMethods.Million)
	                      |			Then CAST(BudgetsData.Amount / 1000000 AS Number(15, 0))
	                      |	END AS Amount,
	                      |	CASE
	                      |		WHEN &RoundMethod = Value(Enum.fmRoundMethods.WithoutRound)
	                      |				OR &RoundMethod = Value(Enum.fmRoundMethods.EmptyRef)
	                      |			Then BudgetsData.InitialAmount
	                      |		WHEN &RoundMethod = Value(Enum.fmRoundMethods.One)
	                      |			Then CAST(BudgetsData.InitialAmount AS Number(15, 0))
	                      |		WHEN &RoundMethod = Value(Enum.fmRoundMethods.Ten)
	                      |			Then CAST(BudgetsData.InitialAmount / 10 AS Number(15, 0))
	                      |		WHEN &RoundMethod = Value(Enum.fmRoundMethods.Hundred)
	                      |			Then CAST(BudgetsData.InitialAmount / 100 AS Number(15, 0))
	                      |		WHEN &RoundMethod = Value(Enum.fmRoundMethods.Thousand)
	                      |			Then CAST(BudgetsData.InitialAmount / 1000 AS Number(15, 0))
	                      |		WHEN &RoundMethod = Value(Enum.fmRoundMethods.TenThousands)
	                      |			Then CAST(BudgetsData.InitialAmount / 10000 AS Number(15, 0))
	                      |		WHEN &RoundMethod = Value(Enum.fmRoundMethods.HundredThousands)
	                      |			Then CAST(BudgetsData.InitialAmount / 100000 AS Number(15, 0))
	                      |		WHEN &RoundMethod = Value(Enum.fmRoundMethods.Million)
	                      |			Then CAST(BudgetsData.InitialAmount / 1000000 AS Number(15, 0))
	                      |	END AS InitialAmount,
	                      |	CASE
	                      |		WHEN &RoundMethod = Value(Enum.fmRoundMethods.WithoutRound)
	                      |				OR &RoundMethod = Value(Enum.fmRoundMethods.EmptyRef)
	                      |			Then BudgetsData.Delta
	                      |		WHEN &RoundMethod = Value(Enum.fmRoundMethods.One)
	                      |			Then CAST(BudgetsData.Delta AS Number(15, 0))
	                      |		WHEN &RoundMethod = Value(Enum.fmRoundMethods.Ten)
	                      |			Then CAST(BudgetsData.Delta / 10 AS Number(15, 0))
	                      |		WHEN &RoundMethod = Value(Enum.fmRoundMethods.Hundred)
	                      |			Then CAST(BudgetsData.Delta / 100 AS Number(15, 0))
	                      |		WHEN &RoundMethod = Value(Enum.fmRoundMethods.Thousand)
	                      |			Then CAST(BudgetsData.Delta / 1000 AS Number(15, 0))
	                      |		WHEN &RoundMethod = Value(Enum.fmRoundMethods.TenThousands)
	                      |			Then CAST(BudgetsData.Delta / 10000 AS Number(15, 0))
	                      |		WHEN &RoundMethod = Value(Enum.fmRoundMethods.HundredThousands)
	                      |			Then CAST(BudgetsData.Delta / 100000 AS Number(15, 0))
	                      |		WHEN &RoundMethod = Value(Enum.fmRoundMethods.Million)
	                      |			Then CAST(BudgetsData.Delta / 1000000 AS Number(15, 0))
	                      |	END AS Delta,
	                      |	BudgetsData.Analytics1 AS Analytics1,
	                      |	BudgetsData.Analytics2 AS Analytics2,
	                      |	BudgetsData.Analytics3 AS Analytics3,
	                      |	BudgetsData.RecordType AS RecordType,
	                      |	BudgetsData.LineNumber AS LineNumber
	                      |INTO TTCollapsedBudgetData
	                      |FROM
	                      |	&BudgetsData AS BudgetsData");
	Query.TempTablesManager = New TempTablesManager;
	CurDataTable = GetFromTempStorage(TabDataAddress).Copy();
	CurDataTable.Columns.Add("LineNumber", New TypeDescription("Number", , , New NumberQualifiers(12, 0)));
	Num=0;
	For Each CurRow In CurDataTable Do
		CurRow.LineNumber = Num;
		Num=Num+1;
	EndDo;
	Query.SetParameter("BudgetsData", CurDataTable);
	Query.SetParameter("RoundMethod", ?(ValueIsFilled(StructureInputFormat), StructureInputFormat, ConstantInputFormat));
	Query.Execute();
		
	Query.Text = "SELECT
	               |	VTPeriods.Period AS Period
	               |INTO TT_Periods
	               |FROM
	               |	&VTPeriods AS VTPeriods
	               |;
	               |
	               |////////////////////////////////////////////////////////////////////////////////
	               |SELECT
	               |	SectionStructureData.Ref AS Ref,
	               |	SectionStructureData.Analytics AS Analytics,
	               |	SectionStructureData.Analytics1 AS Analytics1,
	               |	SectionStructureData.Analytics2 AS Analytics2,
	               |	SectionStructureData.Analytics3 AS Analytics3,
	               |	SectionStructureData.LineNumber AS Order
	               |INTO TTItemGrouping
	               |FROM
	               |	Catalog.fmInfoStructuresSections.SectionStructureData AS SectionStructureData
	               |WHERE
	               |	SectionStructureData.Ref.Owner = &Owner
	               |	AND NOT SectionStructureData.Analytics Refs Catalog.fmItemGroups
	               |	AND SectionStructureData.Ref.StructureSectionType <> Value(Enum.fmBudgetFlowOperationTypes.EmptyRef)
	               |
	               |UNION ALL
	               |
	               |SELECT
	               |	SectionStructureData.Ref,
	               |	ItemGroupsItem.Item,
	               |	SectionStructureData.Analytics1,
	               |	SectionStructureData.Analytics2,
	               |	SectionStructureData.Analytics3,
	               |	SectionStructureData.LineNumber + ItemGroupsItem.LineNumber / 1000
	               |FROM
	               |	Catalog.fmInfoStructuresSections.SectionStructureData AS SectionStructureData
	               |		LEFT JOIN Catalog.fmItemGroups.Items AS ItemGroupsItem
	               |		ON SectionStructureData.Analytics = ItemGroupsItem.Ref
	               |WHERE
	               |	SectionStructureData.Ref.Owner = &Owner
	               |	AND SectionStructureData.Ref.StructureSectionType <> Value(Enum.fmBudgetFlowOperationTypes.EmptyRef)
	               |	AND SectionStructureData.Analytics Refs Catalog.fmItemGroups
	               |;
	               |
	               |////////////////////////////////////////////////////////////////////////////////
	               |SELECT
	               |	Structure.Ref AS Section,
	               |	Structure.Parent AS SectionParent,
	               |	CASE
	               |		WHEN Structure.ByFormula
	               |			Then Undefined
	               |		Else ISNULL(StructureIndicators.Analytics, Undefined)
	               |	END AS Analytics,
	               |	ISNULL(StructureIndicators.Analytics1, Undefined) AS Analytics1,
	               |	ISNULL(StructureIndicators.Analytics2, Undefined) AS Analytics2,
	               |	ISNULL(StructureIndicators.Analytics3, Undefined) AS Analytics3,
	               |	Structure.Order AS Order,
	               |	StructureIndicators.Order AS AnalyticsOrder,
	               |	Structure.ItalicFont AS ItalicFont,
	               |	CAST(Structure.TextColor AS String(1024)) AS TextColor,
	               |	Structure.BoldFont AS BoldFont
	               |INTO TT_Structure
	               |FROM
	               |	Catalog.fmInfoStructuresSections AS Structure
	               |		LEFT JOIN TTItemGrouping AS StructureIndicators
	               |		ON Structure.Ref = StructureIndicators.Ref
	               |WHERE
	               |	Structure.Owner = &Owner
	               |	AND Structure.StructureSectionType <> Value(Enum.fmBudgetFlowOperationTypes.EmptyRef)
	               |	AND NOT Structure.DeletionMark
	               |
	               |Group BY
	               |	Structure.Ref,
	               |	Structure.Parent,
	               |	CASE
	               |		WHEN Structure.ByFormula
	               |			Then Undefined
	               |		Else ISNULL(StructureIndicators.Analytics, Undefined)
	               |	END,
	               |	ISNULL(StructureIndicators.Analytics1, Undefined),
	               |	ISNULL(StructureIndicators.Analytics2, Undefined),
	               |	ISNULL(StructureIndicators.Analytics3, Undefined),
	               |	Structure.Order,
	               |	StructureIndicators.Order,
	               |	CAST(Structure.TextColor AS String(1024)),
	               |	Structure.ItalicFont,
	               |	Structure.BoldFont
	               |;
	               |
	               |////////////////////////////////////////////////////////////////////////////////
	               |DROP TTItemGrouping
	               |;
	               |
	               |////////////////////////////////////////////////////////////////////////////////
	               |SELECT
	               |	TT_Structure.Section AS Section,
	               |	TT_Structure.SectionParent AS SectionParent,
	               |	TT_Structure.Analytics AS Analytics,
	               |	TT_Structure.Analytics1 AS Analytics1,
	               |	TT_Structure.Analytics2 AS Analytics2,
	               |	TT_Structure.Analytics3 AS Analytics3,
	               |	TT_Structure.Order AS Order,
	               |	TT_Structure.AnalyticsOrder AS AnalyticsOrder,
	               |	TT_Periods.Period AS Period,
	               |	TT_Structure.ItalicFont AS Italic,
	               |	TT_Structure.BoldFont AS Bold,
	               |	TT_Structure.TextColor AS TextColor
	               |INTO TT_StructureWithPeriods
	               |FROM
	               |	TT_Periods AS TT_Periods,
	               |	TT_Structure AS TT_Structure
	               |;
	               |
	               |////////////////////////////////////////////////////////////////////////////////
	               |SELECT
	               |	Structure.Ref AS Section,
	               |	Structure.Parent AS SectionParent,
	               |	Structure.StructureSectionType AS OperationType,
	               |	Structure.Order + 10000 AS Order,
	               |	Structure.ItalicFont AS ItalicFont,
	               |	CAST(Structure.TextColor AS String(1024)) AS TextColor,
	               |	Structure.BoldFont AS BoldFont,
	               |	TT_Periods.Period AS Period
	               |INTO TT_OutOfStructureWithPeriods
	               |FROM
	               |	Catalog.fmInfoStructuresSections AS Structure,
	               |	TT_Periods AS TT_Periods
	               |WHERE
	               |	Structure.Owner = &OutOfStructure
	               |	AND NOT Structure.DeletionMark
	               |;
	               |
	               |////////////////////////////////////////////////////////////////////////////////
	               |SELECT
	               |	TTCollapsedBudgetData.Item AS Item,
	               |	TTCollapsedBudgetData.Analytics1 AS Analytics1,
	               |	TTCollapsedBudgetData.Analytics2 AS Analytics2,
	               |	TTCollapsedBudgetData.Analytics3 AS Analytics3,
	               |	TTCollapsedBudgetData.LineNumber AS LineNumber,
	               |	TT_Periods.Period AS Period,
	               |	CASE
	               |		WHEN TTCollapsedBudgetData.Period <> TT_Periods.Period
	               |			Then 0
	               |		Else TTCollapsedBudgetData.Amount
	               |	END AS Resource_Amount,
	               |	CASE
	               |		WHEN TTCollapsedBudgetData.Period <> TT_Periods.Period
	               |			Then 0
	               |		Else TTCollapsedBudgetData.InitialAmount
	               |	END AS Resource_InitialAmount,
	               |	CASE
	               |		WHEN TTCollapsedBudgetData.Period <> TT_Periods.Period
	               |			Then 0
	               |		Else TTCollapsedBudgetData.Delta
	               |	END AS Resource_Delta,
	               |	TTCollapsedBudgetData.RecordType AS RecordType
	               |INTO TT_OutOfStructureData
	               |FROM
	               |	TTCollapsedBudgetData AS TTCollapsedBudgetData
	               |		LEFT JOIN TT_Structure AS TT_Structure
	               |		ON TTCollapsedBudgetData.Item = TT_Structure.Analytics,
	               |	TT_Periods AS TT_Periods
	               |WHERE
	               |	TT_Structure.Analytics IS NULL
	               |;
	               |
	               |////////////////////////////////////////////////////////////////////////////////
	               |DROP TT_Periods
	               |;
	               |
	               |////////////////////////////////////////////////////////////////////////////////
	               |DROP TT_Structure
	               |;
	               |
	               |////////////////////////////////////////////////////////////////////////////////
	               |SELECT
	               |	TT_OutOfStructureWithPeriods.Section AS Section,
	               |	TT_OutOfStructureWithPeriods.SectionParent AS SectionParent,
	               |	ISNULL(TT_OutOfStructureData.Item, Undefined) AS Analytics,
	               |	ISNULL(TT_OutOfStructureData.Analytics1, Undefined) AS Analytics1,
	               |	ISNULL(TT_OutOfStructureData.Analytics2, Undefined) AS Analytics2,
	               |	ISNULL(TT_OutOfStructureData.Analytics3, Undefined) AS Analytics3,
	               |	TT_OutOfStructureWithPeriods.Order AS Order,
	               |	ISNULL(TT_OutOfStructureData.LineNumber, 0) AS AnalyticsOrder,
	               |	TT_OutOfStructureWithPeriods.Period AS Period,
	               |	Sum(ISNULL(TT_OutOfStructureData.Resource_Amount, 0)) AS Resource_Amount,
	               |	Sum(ISNULL(TT_OutOfStructureData.Resource_InitialAmount, 0)) AS Resource_InitialAmount,
	               |	Sum(ISNULL(TT_OutOfStructureData.Resource_Delta, 0)) AS Resource_Delta,
	               |	TT_OutOfStructureWithPeriods.TextColor AS TextColor,
	               |	TT_OutOfStructureWithPeriods.ItalicFont AS ItalicFont,
	               |	TT_OutOfStructureWithPeriods.BoldFont AS BoldFont,
	               |	CASE
	               |		WHEN ISNULL(TT_OutOfStructureData.Resource_Amount, Undefined) = Undefined
	               |			Then False
	               |		Else True
	               |	END AS Edit
	               |INTO TT_OutOfStructureDataByStructure
	               |FROM
	               |	TT_OutOfStructureWithPeriods AS TT_OutOfStructureWithPeriods
	               |		LEFT JOIN TT_OutOfStructureData AS TT_OutOfStructureData
	               |		ON (TT_OutOfStructureData.RecordType = TT_OutOfStructureWithPeriods.OperationType)
	               |			AND (TT_OutOfStructureData.Period = TT_OutOfStructureWithPeriods.Period)
	               |
	               |Group BY
	               |	TT_OutOfStructureWithPeriods.Section,
	               |	TT_OutOfStructureWithPeriods.SectionParent,
	               |	ISNULL(TT_OutOfStructureData.Item, Undefined),
	               |	ISNULL(TT_OutOfStructureData.Analytics1, Undefined),
	               |	ISNULL(TT_OutOfStructureData.Analytics2, Undefined),
	               |	ISNULL(TT_OutOfStructureData.Analytics3, Undefined),
	               |	TT_OutOfStructureWithPeriods.Order,
	               |	ISNULL(TT_OutOfStructureData.LineNumber, 0),
	               |	TT_OutOfStructureWithPeriods.Period,
	               |	TT_OutOfStructureWithPeriods.ItalicFont,
	               |	TT_OutOfStructureWithPeriods.TextColor,
	               |	TT_OutOfStructureWithPeriods.BoldFont,
	               |	CASE
	               |		WHEN ISNULL(TT_OutOfStructureData.Resource_Amount, Undefined) = Undefined
	               |			Then False
	               |		Else True
	               |	END
	               |;
	               |
	               |////////////////////////////////////////////////////////////////////////////////
	               |DROP TT_OutOfStructureWithPeriods
	               |;
	               |
	               |////////////////////////////////////////////////////////////////////////////////
	               |DROP TT_OutOfStructureData
	               |;
	               |
	               |////////////////////////////////////////////////////////////////////////////////
	               |SELECT
	               |	TT_StructureWithPeriods.Section AS Section,
	               |	TT_StructureWithPeriods.SectionParent AS SectionParent,
	               |	TT_StructureWithPeriods.Analytics AS Analytics,
	               |	TT_StructureWithPeriods.Analytics1 AS Analytics1,
	               |	TT_StructureWithPeriods.Analytics2 AS Analytics2,
	               |	TT_StructureWithPeriods.Analytics3 AS Analytics3,
	               |	TT_StructureWithPeriods.Order AS Order,
	               |	TT_StructureWithPeriods.AnalyticsOrder AS AnalyticsOrder,
	               |	TT_StructureWithPeriods.Period AS Period,
	               |	ISNULL(TTCollapsedBudgetData.Amount, 0) AS Resource_Amount,
	               |	ISNULL(TTCollapsedBudgetData.InitialAmount, 0) AS Resource_InitialAmount,
	               |	ISNULL(TTCollapsedBudgetData.Delta, 0) AS Resource_Delta,
	               |	TT_StructureWithPeriods.Italic AS Italic,
	               |	TT_StructureWithPeriods.TextColor AS TextColor,
	               |	TT_StructureWithPeriods.Bold AS Bold,
	               |	TT_StructureWithPeriods.Section.StructureSectionType AS RecordType,
	               |	CASE
	               |		WHEN TT_StructureWithPeriods.Analytics = Undefined
	               |			Then False
	               |		Else True
	               |	END AS Edit
	               |INTO TTDataTableWithoutGrouping
	               |FROM
	               |	TT_StructureWithPeriods AS TT_StructureWithPeriods
	               |		LEFT JOIN TTCollapsedBudgetData AS TTCollapsedBudgetData
	               |		ON TT_StructureWithPeriods.Analytics = TTCollapsedBudgetData.Item
	               |			AND TT_StructureWithPeriods.Analytics1 = TTCollapsedBudgetData.Analytics1
	               |			AND TT_StructureWithPeriods.Analytics2 = TTCollapsedBudgetData.Analytics2
	               |			AND TT_StructureWithPeriods.Analytics3 = TTCollapsedBudgetData.Analytics3
	               |			AND TT_StructureWithPeriods.Period = TTCollapsedBudgetData.Period
	               |
	               |
	               |UNION ALL
	               |
	               |SELECT
	               |	TT_StructureWithPeriods.Section,
	               |	TT_StructureWithPeriods.SectionParent,
	               |	TTCollapsedBudgetData.Item,
	               |	TTCollapsedBudgetData.Analytics1,
	               |	TTCollapsedBudgetData.Analytics2,
	               |	TTCollapsedBudgetData.Analytics3,
	               |	TT_StructureWithPeriods.Order,
	               |	9999 + TTCollapsedBudgetData.LineNumber,
	               |	TT_StructureWithPeriods.Period,
	               |	CASE
	               |		WHEN TTCollapsedBudgetData.Period <> TT_StructureWithPeriods.Period
	               |			Then 0
	               |		Else TTCollapsedBudgetData.Amount
	               |	END,
	               |	CASE
	               |		WHEN TTCollapsedBudgetData.Period <> TT_StructureWithPeriods.Period
	               |			Then 0
	               |		Else TTCollapsedBudgetData.InitialAmount
	               |	END,
	               |	CASE
	               |		WHEN TTCollapsedBudgetData.Period <> TT_StructureWithPeriods.Period
	               |			Then 0
	               |		Else TTCollapsedBudgetData.Delta
	               |	END,
	               |	TT_StructureWithPeriods.Italic,
	               |	TT_StructureWithPeriods.TextColor,
	               |	TT_StructureWithPeriods.Bold,
	               |	TT_StructureWithPeriods.Section.StructureSectionType,
	               |	True
	               |FROM
	               |	TTCollapsedBudgetData AS TTCollapsedBudgetData
	               |		LEFT JOIN TT_StructureWithPeriods AS TT_StructureWithPeriods
	               |		ON TTCollapsedBudgetData.Item = TT_StructureWithPeriods.Analytics
	               |WHERE
	               |	NOT (TTCollapsedBudgetData.Item, TTCollapsedBudgetData.Analytics1, TTCollapsedBudgetData.Analytics2, TTCollapsedBudgetData.Analytics3) IN
	               |				(SELECT
	               |					TT_StructureWithPeriods.Analytics,
	               |					TT_StructureWithPeriods.Analytics1,
	               |					TT_StructureWithPeriods.Analytics2,
	               |					TT_StructureWithPeriods.Analytics3
	               |				FROM
	               |					TT_StructureWithPeriods AS TT_StructureWithPeriods)
	               |	AND NOT TT_StructureWithPeriods.Section IS NULL
	               |
	               |Group BY
	               |	TT_StructureWithPeriods.Italic,
	               |	TT_StructureWithPeriods.SectionParent,
	               |	TTCollapsedBudgetData.Analytics3,
	               |	TTCollapsedBudgetData.Analytics1,
	               |	TTCollapsedBudgetData.Analytics2,
	               |	TT_StructureWithPeriods.Bold,
	               |	TT_StructureWithPeriods.Period,
	               |	TT_StructureWithPeriods.Section,
	               |	CASE
	               |		WHEN TTCollapsedBudgetData.Period <> TT_StructureWithPeriods.Period
	               |			Then 0
	               |		Else TTCollapsedBudgetData.Amount
	               |	END,
	               |	CASE
	               |		WHEN TTCollapsedBudgetData.Period <> TT_StructureWithPeriods.Period
	               |			Then 0
	               |		Else TTCollapsedBudgetData.InitialAmount
	               |	END,
	               |	CASE
	               |		WHEN TTCollapsedBudgetData.Period <> TT_StructureWithPeriods.Period
	               |			Then 0
	               |		Else TTCollapsedBudgetData.Delta
	               |	END,
	               |	TTCollapsedBudgetData.Item,
	               |	TT_StructureWithPeriods.TextColor,
	               |	TT_StructureWithPeriods.Order,
	               |	TT_StructureWithPeriods.Section.StructureSectionType,
	               |	9999 + TTCollapsedBudgetData.LineNumber
	               |
	               |UNION ALL
	               |
	               |SELECT
	               |	TT_OutOfStructureDataByStructure.Section,
	               |	TT_OutOfStructureDataByStructure.SectionParent,
	               |	TT_OutOfStructureDataByStructure.Analytics,
	               |	TT_OutOfStructureDataByStructure.Analytics1,
	               |	TT_OutOfStructureDataByStructure.Analytics2,
	               |	TT_OutOfStructureDataByStructure.Analytics3,
	               |	TT_OutOfStructureDataByStructure.Order,
	               |	TT_OutOfStructureDataByStructure.AnalyticsOrder,
	               |	TT_OutOfStructureDataByStructure.Period,
	               |	TT_OutOfStructureDataByStructure.Resource_Amount,
	               |	TT_OutOfStructureDataByStructure.Resource_InitialAmount,
	               |	TT_OutOfStructureDataByStructure.Resource_Delta,
	               |	TT_OutOfStructureDataByStructure.ItalicFont,
	               |	TT_OutOfStructureDataByStructure.TextColor,
	               |	TT_OutOfStructureDataByStructure.BoldFont,
	               |	TT_OutOfStructureDataByStructure.Section.StructureSectionType,
	               |	TT_OutOfStructureDataByStructure.Edit
	               |FROM
	               |	TT_OutOfStructureDataByStructure AS TT_OutOfStructureDataByStructure
	               |;
	               |
	               |////////////////////////////////////////////////////////////////////////////////
	               |DROP TTCollapsedBudgetData
	               |;
	               |
	               |////////////////////////////////////////////////////////////////////////////////
	               |DROP TT_OutOfStructureDataByStructure
	               |;
	               |
	               |////////////////////////////////////////////////////////////////////////////////
	               |DROP TT_StructureWithPeriods
	               |;
	               |
	               |////////////////////////////////////////////////////////////////////////////////
	               |SELECT
	               |	TTDataTableWithoutGrouping.Section AS Section,
	               |	TTDataTableWithoutGrouping.SectionParent AS SectionParent,
	               |	TTDataTableWithoutGrouping.Analytics AS Analytics,
	               |	TTDataTableWithoutGrouping.Analytics1 AS Analytics1,
	               |	TTDataTableWithoutGrouping.Analytics2 AS Analytics2,
	               |	TTDataTableWithoutGrouping.Analytics3 AS Analytics3,
	               |	TTDataTableWithoutGrouping.Order AS Order,
	               |	TTDataTableWithoutGrouping.AnalyticsOrder AS AnalyticsOrder,
	               |	TTDataTableWithoutGrouping.Period AS Period,
	               |	TTDataTableWithoutGrouping.Resource_Amount AS Resource_Amount,
	               |	TTDataTableWithoutGrouping.Resource_InitialAmount AS Resource_InitialAmount,
	               |	TTDataTableWithoutGrouping.Resource_Delta AS Resource_Delta,
	               |	TTDataTableWithoutGrouping.Italic AS Italic,
	               |	TTDataTableWithoutGrouping.TextColor AS TextColor,
	               |	TTDataTableWithoutGrouping.Bold AS Bold,
	               |	TTDataTableWithoutGrouping.Edit AS Edit,
	               |	TTDataTableWithoutGrouping.RecordType AS RecordType
	               |INTO TTDataTableNotCollapsed
	               |FROM
	               |	TTDataTableWithoutGrouping AS TTDataTableWithoutGrouping
	               |
	               |Group BY
	               |	TTDataTableWithoutGrouping.Section,
	               |	TTDataTableWithoutGrouping.SectionParent,
	               |	TTDataTableWithoutGrouping.Analytics,
	               |	TTDataTableWithoutGrouping.Analytics1,
	               |	TTDataTableWithoutGrouping.Analytics2,
	               |	TTDataTableWithoutGrouping.Analytics3,
	               |	TTDataTableWithoutGrouping.Order,
	               |	TTDataTableWithoutGrouping.AnalyticsOrder,
	               |	TTDataTableWithoutGrouping.Period,
	               |	TTDataTableWithoutGrouping.Resource_Amount,
	               |	TTDataTableWithoutGrouping.Resource_InitialAmount,
	               |	TTDataTableWithoutGrouping.Resource_Delta,
	               |	TTDataTableWithoutGrouping.Italic,
	               |	TTDataTableWithoutGrouping.TextColor,
	               |	TTDataTableWithoutGrouping.Bold,
	               |	TTDataTableWithoutGrouping.Edit,
	               |	TTDataTableWithoutGrouping.RecordType
	               |
	               |UNION ALL
	               |
	               |SELECT
	               |	TTDataTableWithoutGrouping.Section,
	               |	TTDataTableWithoutGrouping.SectionParent,
	               |	Undefined,
	               |	Undefined,
	               |	Undefined,
	               |	Undefined,
	               |	TTDataTableWithoutGrouping.Order,
	               |	TTDataTableWithoutGrouping.AnalyticsOrder,
	               |	TTDataTableWithoutGrouping.Period,
	               |	0,
	               |	0,
	               |	0,
	               |	TTDataTableWithoutGrouping.Italic,
	               |	TTDataTableWithoutGrouping.TextColor,
	               |	TTDataTableWithoutGrouping.Bold,
	               |	False,
	               |	TTDataTableWithoutGrouping.Section.StructureSectionType
	               |FROM
	               |	TTDataTableWithoutGrouping AS TTDataTableWithoutGrouping
	               |WHERE
	               |	TTDataTableWithoutGrouping.Analytics <> Undefined
	               |
	               |Group BY
	               |	TTDataTableWithoutGrouping.Section,
	               |	TTDataTableWithoutGrouping.SectionParent,
	               |	TTDataTableWithoutGrouping.Order,
	               |	TTDataTableWithoutGrouping.AnalyticsOrder,
	               |	TTDataTableWithoutGrouping.Period,
	               |	TTDataTableWithoutGrouping.Italic,
	               |	TTDataTableWithoutGrouping.TextColor,
	               |	TTDataTableWithoutGrouping.Bold,
	               |	TTDataTableWithoutGrouping.Section.StructureSectionType
	               |
	               |UNION ALL
	               |
	               |SELECT
	               |	TTDataTableWithoutGrouping.Section,
	               |	TTDataTableWithoutGrouping.SectionParent,
	               |	TTDataTableWithoutGrouping.Analytics,
	               |	Undefined,
	               |	Undefined,
	               |	Undefined,
	               |	TTDataTableWithoutGrouping.Order,
	               |	TTDataTableWithoutGrouping.AnalyticsOrder,
	               |	TTDataTableWithoutGrouping.Period,
	               |	0,
	               |	0,
	               |	0,
	               |	TTDataTableWithoutGrouping.Italic,
	               |	TTDataTableWithoutGrouping.TextColor,
	               |	TTDataTableWithoutGrouping.Bold,
	               |	False,
	               |	TTDataTableWithoutGrouping.Section.StructureSectionType
	               |FROM
	               |	TTDataTableWithoutGrouping AS TTDataTableWithoutGrouping
	               |WHERE
	               |	TTDataTableWithoutGrouping.Analytics1 <> Undefined
	               |
	               |Group BY
	               |	TTDataTableWithoutGrouping.Section,
	               |	TTDataTableWithoutGrouping.SectionParent,
	               |	TTDataTableWithoutGrouping.Analytics,
	               |	TTDataTableWithoutGrouping.Order,
	               |	TTDataTableWithoutGrouping.AnalyticsOrder,
	               |	TTDataTableWithoutGrouping.Period,
	               |	TTDataTableWithoutGrouping.Italic,
	               |	TTDataTableWithoutGrouping.TextColor,
	               |	TTDataTableWithoutGrouping.Bold,
	               |	TTDataTableWithoutGrouping.Section.StructureSectionType
	               |
	               |UNION ALL
	               |
	               |SELECT
	               |	TTDataTableWithoutGrouping.Section,
	               |	TTDataTableWithoutGrouping.SectionParent,
	               |	TTDataTableWithoutGrouping.Analytics,
	               |	TTDataTableWithoutGrouping.Analytics1,
	               |	Undefined,
	               |	Undefined,
	               |	TTDataTableWithoutGrouping.Order,
	               |	TTDataTableWithoutGrouping.AnalyticsOrder,
	               |	TTDataTableWithoutGrouping.Period,
	               |	0,
	               |	0,
	               |	0,
	               |	TTDataTableWithoutGrouping.Italic,
	               |	TTDataTableWithoutGrouping.TextColor,
	               |	TTDataTableWithoutGrouping.Bold,
	               |	False,
	               |	TTDataTableWithoutGrouping.Section.StructureSectionType
	               |FROM
	               |	TTDataTableWithoutGrouping AS TTDataTableWithoutGrouping
	               |WHERE
	               |	TTDataTableWithoutGrouping.Analytics2 <> Undefined
	               |
	               |Group BY
	               |	TTDataTableWithoutGrouping.Section,
	               |	TTDataTableWithoutGrouping.SectionParent,
	               |	TTDataTableWithoutGrouping.Analytics,
	               |	TTDataTableWithoutGrouping.Analytics1,
	               |	TTDataTableWithoutGrouping.Order,
	               |	TTDataTableWithoutGrouping.AnalyticsOrder,
	               |	TTDataTableWithoutGrouping.Period,
	               |	TTDataTableWithoutGrouping.Italic,
	               |	TTDataTableWithoutGrouping.TextColor,
	               |	TTDataTableWithoutGrouping.Bold,
	               |	TTDataTableWithoutGrouping.Section.StructureSectionType
	               |
	               |UNION ALL
	               |
	               |SELECT
	               |	TTDataTableWithoutGrouping.Section,
	               |	TTDataTableWithoutGrouping.SectionParent,
	               |	TTDataTableWithoutGrouping.Analytics,
	               |	TTDataTableWithoutGrouping.Analytics1,
	               |	TTDataTableWithoutGrouping.Analytics2,
	               |	Undefined,
	               |	TTDataTableWithoutGrouping.Order,
	               |	TTDataTableWithoutGrouping.AnalyticsOrder,
	               |	TTDataTableWithoutGrouping.Period,
	               |	0,
	               |	0,
	               |	0,
	               |	TTDataTableWithoutGrouping.Italic,
	               |	TTDataTableWithoutGrouping.TextColor,
	               |	TTDataTableWithoutGrouping.Bold,
	               |	False,
	               |	TTDataTableWithoutGrouping.Section.StructureSectionType
	               |FROM
	               |	TTDataTableWithoutGrouping AS TTDataTableWithoutGrouping
	               |WHERE
	               |	TTDataTableWithoutGrouping.Analytics3 <> Undefined
	               |
	               |Group BY
	               |	TTDataTableWithoutGrouping.Section,
	               |	TTDataTableWithoutGrouping.SectionParent,
	               |	TTDataTableWithoutGrouping.Analytics,
	               |	TTDataTableWithoutGrouping.Analytics1,
	               |	TTDataTableWithoutGrouping.Analytics2,
	               |	TTDataTableWithoutGrouping.Order,
	               |	TTDataTableWithoutGrouping.AnalyticsOrder,
	               |	TTDataTableWithoutGrouping.Period,
	               |	TTDataTableWithoutGrouping.Italic,
	               |	TTDataTableWithoutGrouping.TextColor,
	               |	TTDataTableWithoutGrouping.Bold,
	               |	TTDataTableWithoutGrouping.Section.StructureSectionType
	               |;
	               |
	               |////////////////////////////////////////////////////////////////////////////////
	               |DROP TTDataTableWithoutGrouping
	               |;
	               |
	               |////////////////////////////////////////////////////////////////////////////////
	               |SELECT
	               |	TTDataTableNotCollapsed.Section AS Section,
	               |	TTDataTableNotCollapsed.SectionParent AS SectionParent,
	               |	TTDataTableNotCollapsed.Analytics AS Analytics,
	               |	TTDataTableNotCollapsed.Analytics1 AS Analytics1,
	               |	TTDataTableNotCollapsed.Analytics2 AS Analytics2,
	               |	TTDataTableNotCollapsed.Analytics3 AS Analytics3,
	               |	TTDataTableNotCollapsed.Order AS Order,
	               |	Min(TTDataTableNotCollapsed.AnalyticsOrder) AS AnalyticsOrder,
	               |	TTDataTableNotCollapsed.Period AS Period,
	               |	Sum(TTDataTableNotCollapsed.Resource_Amount) AS Resource_Amount,
	               |	Sum(TTDataTableNotCollapsed.Resource_InitialAmount) AS Resource_InitialAmount,
	               |	Sum(TTDataTableNotCollapsed.Resource_Delta) AS Resource_Delta,
	               |	TTDataTableNotCollapsed.Italic AS Italic,
	               |	TTDataTableNotCollapsed.TextColor AS TextColor,
	               |	TTDataTableNotCollapsed.Bold AS Bold,
	               |	Min(TTDataTableNotCollapsed.Edit) AS Edit,
	               |	TTDataTableNotCollapsed.RecordType AS RecordType
	               |INTO DataTableTT
	               |FROM
	               |	TTDataTableNotCollapsed AS TTDataTableNotCollapsed
	               |
	               |GROUP BY
	               |	TTDataTableNotCollapsed.Analytics3,
	               |	TTDataTableNotCollapsed.RecordType,
	               |	TTDataTableNotCollapsed.Bold,
	               |	TTDataTableNotCollapsed.SectionParent,
	               |	TTDataTableNotCollapsed.TextColor,
	               |	TTDataTableNotCollapsed.Italic,
	               |	TTDataTableNotCollapsed.Analytics2,
	               |	TTDataTableNotCollapsed.Section,
	               |	TTDataTableNotCollapsed.Analytics1,
	               |	TTDataTableNotCollapsed.Analytics,
	               |	TTDataTableNotCollapsed.Period,
	               |	TTDataTableNotCollapsed.Order
	               |;
	               |
	               |////////////////////////////////////////////////////////////////////////////////
	               |DROP TTDataTableNotCollapsed
	               |;
	               |
	               |////////////////////////////////////////////////////////////////////////////////
	               |SELECT
	               |	DataTableTT.Section AS Section,
	               |	DataTableTT.SectionParent AS SectionParent,
	               |	DataTableTT.Analytics AS Analytics,
	               |	DataTableTT.Analytics1 AS Analytics1,
	               |	DataTableTT.Analytics2 AS Analytics2,
	               |	DataTableTT.Analytics3 AS Analytics3,
	               |	DataTableTT.Order AS Order,
	               |	Min(DataTableTT.AnalyticsOrder) AS AnalyticsOrder
	               |FROM
	               |	DataTableTT AS DataTableTT
	               |
	               |GROUP BY
	               |	DataTableTT.Section,
	               |	DataTableTT.SectionParent,
	               |	DataTableTT.Analytics,
	               |	DataTableTT.Analytics1,
	               |	DataTableTT.Analytics2,
	               |	DataTableTT.Analytics3,
	               |	DataTableTT.Order";
	
	// Создадим ТЗ на основе списка периодов для использования в запросе.
	VTPeriods = New ValueTable;
	VTPeriods.Columns.Add("Period", New TypeDescription("DATE"));
	For Each CurPeriod In Periods Do
		NRow = VTPeriods.Add();
		NRow.Period = CurPeriod.Value;
	EndDo;
	
	// Установка параметров запроса.
	Query.SetParameter("VTPeriods"					, VTPeriods);
	Query.SetParameter("Owner"					, ?(ValueIsFilled(Object.InfoStructure), Object.InfoStructure, Catalogs.fmInfoStructures.EmptyRef()));
	If Object.OperationType=Enums.fmBudgetOperationTypes.IncomesAndExpenses Then
		Query.SetParameter("OutOfStructure"				, ?(ValueIsFilled(Object.InfoStructure), Catalogs.fmInfoStructures.OutOfStructureIE, Catalogs.fmInfoStructures.WithoutStructureIE));
	Else
		Query.SetParameter("OutOfStructure"				, ?(ValueIsFilled(Object.InfoStructure), Catalogs.fmInfoStructures.OutOfStructureCashflow, Catalogs.fmInfoStructures.WithoutStructureCashflow));
	EndIf;
	
	HierarchyVT = Query.Execute().Unload();
	HierarchyVT.Columns.Add("RowID", New TypeDescription("String",, New StringQualifiers(30, AllowedLength.Variable)));
	HierarchyVT.Columns.Add("IsSection", New TypeDescription("Boolean"));
	HierarchyVT.Columns.Add("Presentation", New TypeDescription("String",, New StringQualifiers(0, AllowedLength.Variable)));
	HierarchyVT.Columns.Add("AnalyticsName", New TypeDescription("String",, New StringQualifiers(30, AllowedLength.Variable)));
	RowID = 1;
	For Each CurRow In HierarchyVT Do
		If ValueIsFilled(CurRow.Analytics3) Then
			CurRow.Presentation = String(CurRow.Analytics3);
			CurRow.AnalyticsName = "Analytics3";
		ElsIf ValueIsFilled(CurRow.Analytics2) Then
			CurRow.Presentation = String(CurRow.Analytics2);
			CurRow.AnalyticsName = "Analytics2";
		ElsIf ValueIsFilled(CurRow.Analytics1) Then
			CurRow.Presentation = String(CurRow.Analytics1);
			CurRow.AnalyticsName = "Analytics1";
		ElsIf ValueIsFilled(CurRow.Analytics) Then
			CurRow.Presentation = String(CurRow.Analytics);
			CurRow.AnalyticsName = "Analytics";
		Else
			CurRow.Presentation = String(CurRow.Section);
			CurRow.AnalyticsName = "Section";
			CurRow.IsSection = True;
		EndIf;
		CurRow.RowID = "C" + Format(RowID, "ND=29; NLZ=; NG="); // 1й знак "С" + число из 29 символов с лид. нулями;
		RowID = RowID + 1;
	EndDo;
	Query.Text = "SELECT ALLOWED
	|	HierarchyVT.Analytics AS Analytics,
	|	HierarchyVT.Analytics1 AS Analytics1,
	|	HierarchyVT.Analytics2 AS Analytics2,
	|	HierarchyVT.Analytics3 AS Analytics3,
	|	HierarchyVT.Presentation AS Presentation,
	|	HierarchyVT.RowID AS RowID,
	|	HierarchyVT.Order AS Order,
	|	HierarchyVT.AnalyticsOrder AS AnalyticsOrder,
	|	HierarchyVT.IsSection AS IsSection,
	|	HierarchyVT.AnalyticsName AS AnalyticsName,
	|	HierarchyVT.Section AS Section,
	|	HierarchyVT.SectionParent AS SectionParent
	|INTO TTHierarchyVT
	|FROM
	|	&HierarchyVT AS HierarchyVT";
	Query.SetParameter("HierarchyVT", HierarchyVT);
	Query.Execute();
	Query.Text = "SELECT ALLOWED
	               |	HierarchyVT.Analytics AS Analytics,
	               |	HierarchyVT.Analytics1 AS Analytics1,
	               |	HierarchyVT.Analytics2 AS Analytics2,
	               |	HierarchyVT.Analytics3 AS Analytics3,
	               |	HierarchyVT.Presentation AS Presentation,
	               |	HierarchyVT.RowID AS RowID,
	               |	HierarchyVT.Order AS Order,
	               |	HierarchyVT.AnalyticsOrder AS AnalyticsOrder,
	               |	HierarchyVT.IsSection AS IsSection,
	               |	HierarchyVT.AnalyticsName AS AnalyticsName,
	               |	HierarchyVT.Section AS Section,
	               |	HierarchyVT.SectionParent AS SectionParent,
	               |	ISNULL(HierarchyVT2.RowID, """") AS ParentID
	               |INTO TTHierarchyVTID
	               |FROM
	               |	TTHierarchyVT AS HierarchyVT
	               |		LEFT JOIN TTHierarchyVT AS HierarchyVT2
	               |		ON HierarchyVT.SectionParent = HierarchyVT2.Section
	               |			AND (HierarchyVT.Analytics = Undefined)
	               |			AND (HierarchyVT2.Analytics = Undefined)
	               |WHERE
	               |	HierarchyVT.Analytics = Undefined
	               |
	               |UNION ALL
	               |
	               |SELECT
	               |	HierarchyVT.Analytics,
	               |	HierarchyVT.Analytics1,
	               |	HierarchyVT.Analytics2,
	               |	HierarchyVT.Analytics3,
	               |	HierarchyVT.Presentation,
	               |	HierarchyVT.RowID,
	               |	HierarchyVT.Order,
	               |	HierarchyVT.AnalyticsOrder,
	               |	HierarchyVT.IsSection,
	               |	HierarchyVT.AnalyticsName,
	               |	HierarchyVT.Section,
	               |	HierarchyVT.SectionParent,
	               |	HierarchyVT2.RowID
	               |FROM
	               |	TTHierarchyVT AS HierarchyVT
	               |		INNER JOIN TTHierarchyVT AS HierarchyVT2
	               |		ON HierarchyVT.Section = HierarchyVT2.Section
	               |			AND (HierarchyVT.Analytics <> Undefined)
	               |			AND (HierarchyVT.Analytics1 = Undefined)
	               |			AND (HierarchyVT2.Analytics = Undefined)
	               |
	               |UNION ALL
	               |
	               |SELECT
	               |	HierarchyVT.Analytics,
	               |	HierarchyVT.Analytics1,
	               |	HierarchyVT.Analytics2,
	               |	HierarchyVT.Analytics3,
	               |	HierarchyVT.Presentation,
	               |	HierarchyVT.RowID,
	               |	HierarchyVT.Order,
	               |	HierarchyVT.AnalyticsOrder,
	               |	HierarchyVT.IsSection,
	               |	HierarchyVT.AnalyticsName,
	               |	HierarchyVT.Section,
	               |	HierarchyVT.SectionParent,
	               |	HierarchyVT2.RowID
	               |FROM
	               |	TTHierarchyVT AS HierarchyVT
	               |		INNER JOIN TTHierarchyVT AS HierarchyVT2
	               |		ON HierarchyVT.Section = HierarchyVT2.Section
	               |			AND HierarchyVT.Analytics = HierarchyVT2.Analytics
	               |			AND (HierarchyVT.Analytics1 <> Undefined)
	               |			AND (HierarchyVT.Analytics2 = Undefined)
	               |			AND (HierarchyVT2.Analytics1 = Undefined)
	               |
	               |UNION ALL
	               |
	               |SELECT
	               |	HierarchyVT.Analytics,
	               |	HierarchyVT.Analytics1,
	               |	HierarchyVT.Analytics2,
	               |	HierarchyVT.Analytics3,
	               |	HierarchyVT.Presentation,
	               |	HierarchyVT.RowID,
	               |	HierarchyVT.Order,
	               |	HierarchyVT.AnalyticsOrder,
	               |	HierarchyVT.IsSection,
	               |	HierarchyVT.AnalyticsName,
	               |	HierarchyVT.Section,
	               |	HierarchyVT.SectionParent,
	               |	HierarchyVT2.RowID
	               |FROM
	               |	TTHierarchyVT AS HierarchyVT
	               |		INNER JOIN TTHierarchyVT AS HierarchyVT2
	               |		ON HierarchyVT.Section = HierarchyVT2.Section
	               |			AND HierarchyVT.Analytics = HierarchyVT2.Analytics
	               |			AND HierarchyVT.Analytics1 = HierarchyVT2.Analytics1
	               |			AND (HierarchyVT.Analytics2 <> Undefined)
	               |			AND (HierarchyVT.Analytics3 = Undefined)
	               |			AND (HierarchyVT2.Analytics2 = Undefined)
	               |
	               |UNION ALL
	               |
	               |SELECT
	               |	HierarchyVT.Analytics,
	               |	HierarchyVT.Analytics1,
	               |	HierarchyVT.Analytics2,
	               |	HierarchyVT.Analytics3,
	               |	HierarchyVT.Presentation,
	               |	HierarchyVT.RowID,
	               |	HierarchyVT.Order,
	               |	HierarchyVT.AnalyticsOrder,
	               |	HierarchyVT.IsSection,
	               |	HierarchyVT.AnalyticsName,
	               |	HierarchyVT.Section,
	               |	HierarchyVT.SectionParent,
	               |	HierarchyVT2.RowID
	               |FROM
	               |	TTHierarchyVT AS HierarchyVT
	               |		INNER JOIN TTHierarchyVT AS HierarchyVT2
	               |		ON HierarchyVT.Section = HierarchyVT2.Section
	               |			AND HierarchyVT.Analytics = HierarchyVT2.Analytics
	               |			AND HierarchyVT.Analytics1 = HierarchyVT2.Analytics1
	               |			AND HierarchyVT.Analytics2 = HierarchyVT2.Analytics2
	               |			AND (HierarchyVT.Analytics3 <> Undefined)
	               |			AND (HierarchyVT2.Analytics3 = Undefined)
	               |;
	               |
	               |////////////////////////////////////////////////////////////////////////////////
	               |DROP TTHierarchyVT
	               |;
	               |
	               |////////////////////////////////////////////////////////////////////////////////
	               |SELECT ALLOWED
	               |	DataTableTT.Period AS Period,
	               |	DataTableTT.Edit AS Edit,
	               |	DataTableTT.RecordType AS RecordType,
	               |	DataTableTT.Resource_Amount AS Resource_Amount,
	               |	DataTableTT.Resource_InitialAmount AS Resource_InitialAmount,
	               |	DataTableTT.Resource_Delta AS Resource_Delta,
	               |	TTHierarchyVTID.RowID AS RowID
	               |FROM
	               |	DataTableTT AS DataTableTT
	               |		LEFT JOIN TTHierarchyVTID AS TTHierarchyVTID
	               |		ON DataTableTT.Section = TTHierarchyVTID.Section
	               |			AND DataTableTT.Analytics = TTHierarchyVTID.Analytics
	               |			AND DataTableTT.Analytics1 = TTHierarchyVTID.Analytics1
	               |			AND DataTableTT.Analytics2 = TTHierarchyVTID.Analytics2
	               |			AND DataTableTT.Analytics3 = TTHierarchyVTID.Analytics3
	               |;
	               |
	               |////////////////////////////////////////////////////////////////////////////////
	               |SELECT ALLOWED
	               |	TTHierarchyVTID.Analytics AS Analytics,
	               |	TTHierarchyVTID.Analytics1 AS Analytics1,
	               |	TTHierarchyVTID.Analytics2 AS Analytics2,
	               |	TTHierarchyVTID.Analytics3 AS Analytics3,
	               |	TTHierarchyVTID.Presentation AS Presentation,
	               |	TTHierarchyVTID.RowID AS RowID,
	               |	TTHierarchyVTID.Order AS Order,
	               |	TTHierarchyVTID.AnalyticsOrder AS AnalyticsOrder,
	               |	TTHierarchyVTID.IsSection AS IsSection,
	               |	TTHierarchyVTID.AnalyticsName AS AnalyticsName,
	               |	TTHierarchyVTID.Section AS Section,
	               |	TTHierarchyVTID.SectionParent AS SectionParent,
	               |	TTHierarchyVTID.ParentID AS ParentID
	               |FROM
	               |	TTHierarchyVTID AS TTHierarchyVTID
	               |;
	               |
	               |////////////////////////////////////////////////////////////////////////////////
	               |DROP TTHierarchyVTID
	               |;
	               |
	               |////////////////////////////////////////////////////////////////////////////////
	               |SELECT
	               |	DataTableTT.Section AS Section,
	               |	DataTableTT.Italic AS Italic,
	               |	DataTableTT.TextColor AS TextColor,
	               |	DataTableTT.Bold AS Bold
	               |FROM
	               |	DataTableTT AS DataTableTT
	               |
	               |GROUP BY
	               |	DataTableTT.Section,
	               |	DataTableTT.Italic,
	               |	DataTableTT.TextColor,
	               |	DataTableTT.Bold";
	
	Result = Query.ExecuteBatch();
	DataVT = Result[2].Unload();
	HierarchyVT = Result[3].Unload();
	VTConditionalAppearance = Result[5].Unload();
	
	DetailsDataObject = Undefined;
	DCSchema				= DataProcessors.fmPredictionCopy.GetTemplate("TreeDCS");;
	
	DCSettings		= DCSchema.DefaultSettings;
	If ColumnGroup Then
		DCSettings.Structure[0].Columns[0].Use = True;
	Else
		DCSettings.Structure[0].Columns[1].Use = True;
		If Object.CurScenario.PlanningPeriodicity = Enums.fmPlanningPeriodicity.Quarter Then
			If InfoBaseUsers.CurrentUser().Language = Metadata.Languages.Russian Then
				DCSchema.DataSets.DataVT.Fields[1].Appearance.Items[12].Value = "DF='K ""Quarter"" yyyy ""y.""'";
			Else
				DCSchema.DataSets.DataVT.Fields[1].Appearance.Items[12].Value = "DF='K ""quarter"" yyyy '";
			EndIf;
		EndIf;
	EndIf;
	
	// Настроим вывод необходимых ресурсов.
	For Each CurResource In Resources Do
		NewResource = DCSettings.Selection.Items.Add(Type("DataCompositionSelectedField"));
		NewResource.Use = True;
		NewResource.Field = New DataCompositionField("Resource_" + CurResource.Value);
		NewResource.Title = CurResource.Presentation;
	EndDo;
	
	// Доработка настроек.
	SettingsGenerating(DCSettings, VTConditionalAppearance);
	
	TemplateComposer	= New DataCompositionTemplateComposer;
	CompositionTemplate		= TemplateComposer.Execute(DCSchema, DCSettings, DetailsDataObject, , );
	
	// Инициализация процессора СКД
	DataCompositionProcessor = New DataCompositionProcessor;
	DataCompositionProcessor.Initialize(CompositionTemplate, New Structure("HierarchyTable, DataTable", HierarchyVT, DataVT), DetailsDataObject);
	// Инициализация процессора вывода
	OutputProcessor = New DataCompositionResultSpreadsheetDocumentOutputProcessor;
	OutputProcessor.SetDocument(BudgetTree);
	OutputProcessor.BeginOutput();
	DCResultItem = DataCompositionProcessor.Next();
	While DCResultItem <> Undefined Do
		// Вывести элемент результата компоновки отчета в документ.
		OutputProcessor.OutputItem(DCResultItem);
		// Получает следующий элемент результата компоновки.
		DCResultItem = DataCompositionProcessor.Next();
	EndDo;
	// Указание объекту о том, что вывод результата завершен.
	OutputProcessor.EndOutput();
	
	// Запомнить данные расшифровки.
	DetailsData = PutToTempStorage(DetailsDataObject, UUID);
	
	TemporaryModule.BudgetingPredictionTreeIterationCopy(BudgetTree, InitialDataVTAddress, UUID, DetailsDataObject, Query, SearchColumnsRow, ViewFormat, EditFormat, Resources.Count(), New Color(251, 245, 158));
	
	// Для дальнейшего получения вертикальных и горизонтальных итогов сформируем таблицу.
	GenerateEdgeTable();
	ExecuteFullIterationOfBudgetTree();
	
EndProcedure // ЗаполнитьДерево()

&AtServer
Function GetSettingsOfComplexFilter()
	Return FilterSettings.GetSettings();
EndFunction

&AtServer
Procedure DoForecastingServer()
	
	// Настроим соответствия для округлений.
	Rounds = New Map();
	Rounds.Insert(PredefinedValue("Enum.fmRoundMethods.EmptyRef"), 2);
	Rounds.Insert(PredefinedValue("Enum.fmRoundMethods.WithoutRound"), 2);
	Rounds.Insert(PredefinedValue("Enum.fmRoundMethods.One"), 0);
	Rounds.Insert(PredefinedValue("Enum.fmRoundMethods.Ten"), -1);
	Rounds.Insert(PredefinedValue("Enum.fmRoundMethods.Hundred"), -2);
	Rounds.Insert(PredefinedValue("Enum.fmRoundMethods.Thousand"), -3);
	Rounds.Insert(PredefinedValue("Enum.fmRoundMethods.TenThousands"), -4);
	Rounds.Insert(PredefinedValue("Enum.fmRoundMethods.HundredThousands"), -5);
	Rounds.Insert(PredefinedValue("Enum.fmRoundMethods.Million"), -6);
	
	// Сформируем таблицу сответствий дат.
	DatesMap = New ValueTable();
	DatesMap.Columns.Add("InitialDate", New TypeDescription("DATE"));
	DatesMap.Columns.Add("DATE", New TypeDescription("DATE"));
	CurDate = Object.PeriodFrom;
	Offset=0;
	InitialPeriodsCount = fmBudgetingClientServer.PeriodCount(Object.SourcePeriodFrom, Object.SourcePeriodTo, CurrentPeriodicity);
	PeriodCount = fmBudgetingClientServer.PeriodCount(Object.PeriodFrom, Object.PeriodTo, CurrentPeriodicity);
	PeriodProportion = InitialPeriodsCount/PeriodCount;
	While CurDate <= Object.PeriodTo Do
		CurInitailDate = fmBudgeting.AddInterval(Object.SourcePeriodFrom, CurrentPeriodicity, Offset);
		While CurInitailDate <= Object.SourcePeriodTo Do
			NewMap = DatesMap.Add();
			NewMap.InitialDate = CurInitailDate;
			NewMap.DATE = CurDate;
			CurInitailDate = fmBudgeting.AddInterval(CurInitailDate, CurrentPeriodicity, PeriodCount);
		EndDo;
		Offset=Offset+1;
		CurDate = fmBudgeting.AddInterval(CurDate, CurrentPeriodicity, 1);
	EndDo;
	
	// Поместим таблицу соответствия дат во временную ТЗ для дальнейшей работы с ней.
	QueryText = "SELECT
	              |	DatesMap.InitialDate,
	              |	DatesMap.DATE
	              |INTO DatesMap
	              |FROM
	              |	&DatesMap AS DatesMap
	              |;
	              |
	              |////////////////////////////////////////////////////////////////////////////////
	              |SELECT ALLOWED
	              |	fmIncomesAndExpensesTurnovers.Item,
	              |	fmIncomesAndExpensesTurnovers.Analytics1,
	              |	fmIncomesAndExpensesTurnovers.Analytics2,
	              |	fmIncomesAndExpensesTurnovers.Analytics3,
	              |	fmIncomesAndExpensesTurnovers.OperationType AS RecordType,
	              |	Sum(fmIncomesAndExpensesTurnovers.$Resource) AS $Resource,
	              |	$Periodicity(DatesMap.DATE) AS Periodicity
	              |FROM
	              |	AccumulationRegister.fmIncomesAndExpenses.Turnovers(
	              |			&BeginOfPeriod,
	              |			&EndOfPeriod,
	              |			$Periodicity,
	              |			Scenario = &Scenario
	              |				AND OperationType IN (&OperationType)
	              |				AND Department = &Department) AS fmIncomesAndExpensesTurnovers
	              |		LEFT JOIN DatesMap AS DatesMap
	              |		ON fmIncomesAndExpensesTurnovers.Period = DatesMap.InitialDate
	              |WHERE
	              |	fmIncomesAndExpensesTurnovers.$Resource <> 0
	              |
	              |GROUP BY
	              |	fmIncomesAndExpensesTurnovers.Item,
	              |	fmIncomesAndExpensesTurnovers.Analytics1,
	              |	fmIncomesAndExpensesTurnovers.Analytics2,
	              |	fmIncomesAndExpensesTurnovers.Analytics3,
	              |	fmIncomesAndExpensesTurnovers.OperationType,
	              |	$Periodicity(DatesMap.DATE)
	              |;
	              |
	              |////////////////////////////////////////////////////////////////////////////////
	              |SELECT ALLOWED
	              |	Count(DISTINCT fmIncomesAndExpensesTurnovers.Period) AS PeriodCount,
	              |	$Periodicity(DatesMap.DATE) AS Period,
	              |	Sum(fmIncomesAndExpensesTurnovers.$Resource) AS $Resource
	              |FROM
	              |	AccumulationRegister.fmIncomesAndExpenses.Turnovers(
	              |			&BeginOfPeriod,
	              |			&EndOfPeriod,
	              |			$Periodicity,
	              |			Scenario = &Scenario
	              |				AND OperationType IN (&OperationType)
	              |				AND Department = &Department) AS fmIncomesAndExpensesTurnovers
	              |		LEFT JOIN DatesMap AS DatesMap
	              |		ON fmIncomesAndExpensesTurnovers.Period = DatesMap.InitialDate
	              |WHERE
	              |	fmIncomesAndExpensesTurnovers.$Resource <> 0
	              |
	              |GROUP BY
	              |	$Periodicity(DatesMap.DATE)
	              |;
	              |
	              |////////////////////////////////////////////////////////////////////////////////
	              |DROP DatesMap";
	Query = New Query;
	Query.TempTablesManager = New TempTablesManager;
	Query.SetParameter("DatesMap", DatesMap);
	Query.SetParameter("Scenario", Object.ScenarioSource);
	Query.SetParameter("Department", Object.Department);
	OperationTypes = New ValueList();
	If Object.OperationType=Enums.fmBudgetOperationTypes.IncomesAndExpenses Then
		OperationTypes.Add(Enums.fmBudgetFlowOperationTypes.Incomes);
		OperationTypes.Add(Enums.fmBudgetFlowOperationTypes.Expenses);
	Else
		OperationTypes.Add(Enums.fmBudgetFlowOperationTypes.Inflow);
		OperationTypes.Add(Enums.fmBudgetFlowOperationTypes.Outflow);
		QueryText = StrReplace(QueryText, "fmIncomesAndExpenses", "fmCashflowBudget");
	EndIf;
	Query.SetParameter("OperationType", OperationTypes);
	Query.SetParameter("BeginOfPeriod", Object.SourcePeriodFrom);
	Query.SetParameter("EndOfPeriod", ?(CurrentPeriodicity=Enums.fmPlanningPeriodicity.Month, EndOfMonth(Object.SourcePeriodTo), EndOfQuarter(Object.SourcePeriodTo)));
	QueryText = StrReplace(QueryText, "$Periodicity", String(CurrentPeriodicity));
	QueryText = StrReplace(QueryText, "$Resource", StrReplace(Object.SourceIndicator, " ", "")+"Turnover");
	Query.Text = QueryText;
	Result = Query.ExecuteBatch();
	Selection = Result[1].SELECT();
	PeriodsTable = Result[2].Unload();
	
	DataTab = New ValueTable;
	DataTab.Columns.Add("Period", New TypeDescription("DATE", New DateQualifiers(DateFractions.DATE)));
	DataTab.Columns.Add("Item", New TypeDescription("CatalogRef.fmIncomesAndExpensesItems, CatalogRef.fmCashflowItems"));
	DataTab.Columns.Add("Analytics1", Metadata.ChartsOfCharacteristicTypes.fmAnalyticsTypes.Type);
	DataTab.Columns.Add("Analytics2", Metadata.ChartsOfCharacteristicTypes.fmAnalyticsTypes.Type);
	DataTab.Columns.Add("Analytics3", Metadata.ChartsOfCharacteristicTypes.fmAnalyticsTypes.Type);
	DataTab.Columns.Add("RecordType", New TypeDescription("EnumRef.fmBudgetFlowOperationTypes"));
	DataTab.Columns.Add("Amount", New TypeDescription("Number", New NumberQualifiers(17, 2)));
	DataTab.Columns.Add("InitialAmount", New TypeDescription("Number", New NumberQualifiers(17, 2)));
	DataTab.Columns.Add("Delta", New TypeDescription("Number", New NumberQualifiers(17, 2)));
	DataTab.Columns.Add("Edit", New TypeDescription("Boolean"));
	
	While Selection.Next() Do
		NewLine = DataTab.Add();
		FillPropertyValues(NewLine, Selection);
		If CurrentPeriodicity=Enums.fmPlanningPeriodicity.Month Then
			РАЗНОСТЬДАТ = Selection.Periodicity-Month(Object.PeriodFrom);
			If РАЗНОСТЬДАТ<0 Then РАЗНОСТЬДАТ = РАЗНОСТЬДАТ + PeriodCount; EndIf;
			NewLine.Period = AddMonth(Object.PeriodFrom, РАЗНОСТЬДАТ);
		Else
			VarDate = Selection.Periodicity-Round(Month(Object.PeriodFrom)/3, 0)-1;
			If VarDate<0 Then VarDate = VarDate + PeriodCount; EndIf;
			NewLine.Period = AddMonth(Object.PeriodFrom, VarDate*3);
		EndIf;
		CurAmount = Selection[StrReplace(Object.SourceIndicator, " ", "")+"Turnover"];
		// Произведем валютный пересчет.
		TSRowCurrencyRates = Object.CurrencyRates.FindRows(New Structure("Period", NewLine.Period));
		If NOT TSRowCurrencyRates.Count()=0 AND (NOT TSRowCurrencyRates[0].Rate = 0) AND (NOT TSRowCurrencyRates[0].Repetition = 0) Then
			CurRowRate 			= TSRowCurrencyRates[0].Rate;
			CurRowRepetition 		= TSRowCurrencyRates[0].Repetition;
			//В противном случае используем курс и кратность на текущую дату из РС "Курсы валют бюджетирование"
		Else
			CurRowRate 			= 1;
			CurRowRepetition 		= 1;
		EndIf;
		CurAmount = CurAmount * CurRowRate / CurRowRepetition;
		// Проведем усреднение данных.
		If Object.IgnorePeriodsWithoutData Then
			CurPeriod = PeriodsTable.FindRows(New Structure("Period", Selection.Periodicity));
			If CurPeriod.Count()=0 OR CurPeriod[0].PeriodCount=0 Then
				DataTab.Delete(NewLine);
				Continue;
			Else
				CurAmount = CurAmount / CurPeriod[0].PeriodCount;
			EndIf;
		Else
			CurAmount = CurAmount / PeriodProportion;
		EndIf;
		NewLine.InitialAmount = Round(CurAmount, Rounds[Object.RoundMethod]);
		// Рассчитаем данные.
		IncreaseRate = ?(Object.IncreasePercent>0, Object.IncreasePercent/100+1, 1 - -Object.IncreasePercent/100);
		SeasonalityRate = ?(Object.SeasonalityPercent>0, Object.SeasonalityPercent/100+1, 1 - -Object.SeasonalityPercent/100);
		TotalRate = IncreaseRate * SeasonalityRate;
		If Object.IncreaseParametersApplication="Absolute value at first" Then
			CurAmount = (CurAmount + Object.IncreaseAbsoluteValue) * TotalRate;
		Else
			CurAmount = CurAmount * TotalRate + Object.IncreaseAbsoluteValue;
		EndIf;
		// Округлим итоговые данные данные.
		NewLine[StrReplace(Object.CurrentIndicator, " ", "")] = Round(CurAmount, Rounds[Object.RoundMethod]);
		NewLine.Delta = NewLine[StrReplace(Object.CurrentIndicator, " ", "")] - NewLine.InitialAmount;
	EndDo;
	
	// Прогоним при необходимости финальную таблицу через произвольные отборы.
	If NOT FilterSettings.Settings.Filter.Items.Count()=0 AND Parameters.Prediction Then
		Schema = DataProcessors.fmPredictionCopy.GetTemplate("FilterSettingSchema");
		// Получим настройку отбора и перенесем ее в нашу схему.
		CompositionSettings = Schema.SettingVariants[0].Settings;
		FilterCompositionSettings = FilterSettings.GetSettings();
		For Each CurFilter In FilterCompositionSettings.Filter.Items Do
			NewFilter = CompositionSettings.Filter.Items.Add(TypeOf(CurFilter));
			FillPropertyValues(NewFilter, CurFilter);
		EndDo;
		//Сгенерируем макет компоновки данных при помощи компоновщика макета
		TemplateComposer = New DataCompositionTemplateComposer;
		CompositionTemplate = TemplateComposer.Execute(Schema, CompositionSettings, , , Type("DataCompositionValueCollectionTemplateGenerator"));
		//Создадим и инициализируем процессор компоновки
		CompositionProcessor = New DataCompositionProcessor;
		ExternalDataSets = New Structure("DataTable", DataTab);
		CompositionProcessor.Initialize(CompositionTemplate, ExternalDataSets);
		//Создадим и инициализируем процессор вывода результата	в таблицу значений.
		OutputProcessor = New DataCompositionResultValueCollectionOutputProcessor;
		ResultingVT = New ValueTable;
		OutputProcessor.SetObject(ResultingVT);
		OutputProcessor.BeginOutput();
		OutputProcessor.Output(CompositionProcessor, True);
		DataTab.Clear();
		For Each CurRow In ResultingVT Do
			NewLine = DataTab.Add();
			FillPropertyValues(NewLine, CurRow);
		EndDo;
	EndIf;
	
	// Подставим результирующую статью и свернем данные при необходимости.
	If ValueIsFilled(Object.ForecastingItem) Then
		For Each CurRow In DataTab Do
			CurRow.Item = Object.ForecastingItem;
		EndDo;
		DataTab.Collapse("Period, Item, Analytics1, Analytics2, Analytics3, RecordType", "Delta, InitialAmount, Amount");
	EndIf;
	
	TabDataAddress = PutToTempStorage(DataTab, UUID);
	
	// Выведем таблицу в дерево.
	FillBudgetTree();
	
EndProcedure

&AtServerNoContext
Function DetermineTopCoord(VAL CurTop, ResourcesCount)
	While True Do
		If (CurTop-2)%ResourcesCount=0 Then
			Break;
		EndIf;
		CurTop=CurTop-1;
	EndDo;
	Return CurTop;
EndFunction

#Region VerticalHorizontalRecalculation

// Сформировать таблицу ребер по исходной таблице.
//
&AtServer
Procedure GenerateEdgeTable(FullUpdate = True, NewLine = Undefined)
	
	// Подготовим общие параметры.
	SQ = New StringQualifiers(250);
	Array = New Array;
	Array.Add(Type("String"));
	TypeDescriptionS = New TypeDescription(Array, , SQ);
	
	DataTable = New ValueTable;
	DataTable.Columns.Add("Section",New TypeDescription("CatalogRef.fmInfoStructuresSections"));
	DataTable.Columns.Add("SectionParent",New TypeDescription("CatalogRef.fmInfoStructuresSections"));
	DataTable.Columns.Add("Analytics",New TypeDescription("CatalogRef.fmIncomesAndExpensesItems, CatalogRef.fmCashflowItems"));
	DataTable.Columns.Add("Analytics1", Metadata.ChartsOfCharacteristicTypes.fmAnalyticsTypes.Type);
	DataTable.Columns.Add("Analytics2", Metadata.ChartsOfCharacteristicTypes.fmAnalyticsTypes.Type);
	DataTable.Columns.Add("Analytics3", Metadata.ChartsOfCharacteristicTypes.fmAnalyticsTypes.Type);
	DataTable.Columns.Add("RowID", TypeDescriptionS);
	DataTable.Columns.Add("ParentID", TypeDescriptionS);
	DataTable.Columns.Add("Formula", New TypeDescription("String",,,, New StringQualifiers(1000)));
	DataTable.Columns.Add("Edit",New TypeDescription("Boolean"));
	
	InitialDataVT = GetFromTempStorage(InitialDataVTAddress);
	
	If FullUpdate OR NewLine = Undefined Then
		// Выгрузим таблицу исходных данных для запроса.
		For Each CurRow In InitialDataVT Do
			DataTableRow = DataTable.Add();
			DataTableRow.Section = CurRow.Section;
			DataTableRow.SectionParent = CurRow.SectionParent;
			DataTableRow.Analytics = CurRow.Analytics;
			DataTableRow.Analytics1 = CurRow.Analytics1;
			DataTableRow.Analytics2 = CurRow.Analytics2;
			DataTableRow.Analytics3= CurRow.Analytics3;
			DataTableRow.RowID = CurRow.RowID;
			DataTableRow.ParentID = CurRow.ParentID;
			DataTableRow.Formula = CurRow.Formula;
			DataTableRow.Edit = CurRow.Edit;
		EndDo;
	Else
		// Представим новую строку как строку таблицы.
		DataTableRow = DataTable.Add();
		DataTableRow.Section = NewLine.Section;
		DataTableRow.SectionParent = NewLine.SectionParent;
		DataTableRow.Analytics = NewLine.Analytics;
		DataTableRow.Analytics1 = NewLine.Analytics1;
		DataTableRow.Analytics2 = NewLine.Analytics2;
		DataTableRow.Analytics3= NewLine.Analytics3;
		DataTableRow.RowID = NewLine.RowID;
		DataTableRow.ParentID = NewLine.ParentID;
		DataTableRow.Formula = NewLine.Formula;
		DataTableRow.Edit = True;
	EndIf;
	
	// Получим таблицу уникальных строк.
	Query = New Query;
	Query.Text = "SELECT
	               |	SectionTable.Section AS Section,
	               |	SectionTable.SectionParent AS SectionParent,
	               |	SectionTable.Analytics AS Analytics,
	               |	SectionTable.Analytics1 AS Analytics1,
	               |	SectionTable.Analytics2 AS Analytics2,
	               |	SectionTable.Analytics3 AS Analytics3,
	               |	SectionTable.ParentID AS ParentID,
	               |	SectionTable.RowID AS RowID,
	               |	SectionTable.Edit AS Edit,
	               |	SectionTable.Formula AS Formula
	               |INTO SectionTable
	               |FROM
	               |	&SectionTable AS SectionTable
	               |;
	               |
	               |////////////////////////////////////////////////////////////////////////////////
	               |SELECT
	               |	TT_SectionTable.Section AS Section,
	               |	TT_SectionTable.SectionParent AS SectionParent,
	               |	TT_SectionTable.Analytics AS Analytics,
	               |	TT_SectionTable.Analytics1 AS Analytics1,
	               |	TT_SectionTable.Analytics2 AS Analytics2,
	               |	TT_SectionTable.Analytics3 AS Analytics3,
	               |	TT_SectionTable.ParentID AS ParentID,
	               |	TT_SectionTable.RowID AS RowID,
	               |	TT_SectionTable.Edit AS Edit,
	               |	TT_SectionTable.Formula AS Formula
	               |INTO TT_SectionTable
	               |FROM
	               |	SectionTable AS TT_SectionTable
	               |
	               |GROUP BY
	               |	TT_SectionTable.Section,
	               |	TT_SectionTable.SectionParent,
	               |	TT_SectionTable.Analytics,
	               |	TT_SectionTable.Analytics1,
	               |	TT_SectionTable.Analytics2,
	               |	TT_SectionTable.Analytics3,
	               |	TT_SectionTable.ParentID,
	               |	TT_SectionTable.RowID,
	               |	TT_SectionTable.Edit,
	               |	TT_SectionTable.Formula
	               |;
	               |
	               |////////////////////////////////////////////////////////////////////////////////
	               |DROP SectionTable
	               |;
	               |
	               |////////////////////////////////////////////////////////////////////////////////
	               |SELECT
	               |	SectionTable.RowID AS InitialNode,
	               |	SectionTable.ParentID AS FinalNote,
	               |	SectionTable.Formula AS Formula,
	               |	NOT SectionTable.Edit AS IsSection,
	               |	False AS SkipInCalculations,
	               |	SectionTable.Analytics3 AS Analytics,
	               |	SectionTable.Analytics2 AS Section
	               |INTO TableForCollapse
	               |FROM
	               |	TT_SectionTable AS SectionTable
	               |WHERE
	               |	NOT SectionTable.Analytics3 = Undefined
	               |
	               |UNION ALL
	               |
	               |SELECT
	               |	SectionTable.RowID,
	               |	SectionTable.ParentID,
	               |	SectionTable.Formula,
	               |	NOT SectionTable.Edit,
	               |	False,
	               |	SectionTable.Analytics2,
	               |	SectionTable.Analytics1
	               |FROM
	               |	TT_SectionTable AS SectionTable
	               |WHERE
	               |	NOT SectionTable.Analytics2 = Undefined
	               |
	               |UNION ALL
	               |
	               |SELECT
	               |	SectionTable.RowID,
	               |	SectionTable.ParentID,
	               |	SectionTable.Formula,
	               |	NOT SectionTable.Edit,
	               |	False,
	               |	SectionTable.Analytics1,
	               |	SectionTable.Analytics
	               |FROM
	               |	TT_SectionTable AS SectionTable
	               |WHERE
	               |	NOT SectionTable.Analytics1 = Undefined
	               |
	               |UNION ALL
	               |
	               |SELECT
	               |	SectionTable.RowID,
	               |	SectionTable.ParentID,
	               |	SectionTable.Formula,
	               |	NOT SectionTable.Edit,
	               |	fmInfoStructuresSections.IsBlankString,
	               |	SectionTable.Analytics,
	               |	SectionTable.Section
	               |FROM
	               |	TT_SectionTable AS SectionTable
	               |		LEFT JOIN Catalog.fmInfoStructuresSections AS fmInfoStructuresSections
	               |		ON SectionTable.Section = fmInfoStructuresSections.Ref
	               |WHERE
	               |	NOT SectionTable.Analytics = Undefined
	               |
	               |UNION ALL
	               |
	               |SELECT
	               |	SectionTable.RowID,
	               |	SectionTable.ParentID,
	               |	SectionTable.Formula,
	               |	True,
	               |	fmInfoStructuresSections.IsBlankString,
	               |	SectionTable.Section,
	               |	SectionTable.SectionParent
	               |FROM
	               |	TT_SectionTable AS SectionTable
	               |		LEFT JOIN Catalog.fmInfoStructuresSections AS fmInfoStructuresSections
	               |		ON SectionTable.SectionParent = fmInfoStructuresSections.Ref
	               |WHERE
	               |	NOT SectionTable.SectionParent = Value(Catalog.fmInfoStructuresSections.EmptyRef)
	               |
	               |UNION ALL
	               |
	               |SELECT
	               |	SectionTable.RowID,
	               |	SectionTable.ParentID,
	               |	SectionTable.Formula,
	               |	True,
	               |	False,
	               |	SectionTable.SectionParent,
	               |	SectionTable.Section
	               |FROM
	               |	TT_SectionTable AS SectionTable
	               |WHERE
	               |	SectionTable.SectionParent = Value(Catalog.fmInfoStructuresSections.EmptyRef)
	               |;
	               |
	               |////////////////////////////////////////////////////////////////////////////////
	               |SELECT
	               |	TableForCollapse.InitialNode AS InitialNode,
	               |	TableForCollapse.FinalNote AS FinalNote,
	               |	TableForCollapse.Formula AS Formula,
	               |	MAX(TableForCollapse.IsSection) AS IsSection,
	               |	TableForCollapse.SkipInCalculations AS SkipInCalculations,
	               |	TableForCollapse.Analytics,
	               |	TableForCollapse.Section
	               |FROM
	               |	TableForCollapse AS TableForCollapse
	               |
	               |GROUP BY
	               |	TableForCollapse.InitialNode,
	               |	TableForCollapse.FinalNote,
	               |	TableForCollapse.Formula,
	               |	TableForCollapse.SkipInCalculations,
	               |	TableForCollapse.Analytics,
	               |	TableForCollapse.Section
	               |;
	               |
	               |////////////////////////////////////////////////////////////////////////////////
	               |DROP TT_SectionTable
	               |;
	               |
	               |////////////////////////////////////////////////////////////////////////////////
	               |DROP TableForCollapse";
	
	Query.SetParameter("SectionTable", DataTable);
	QueryResult = Query.Execute();
	
	If QueryResult.IsEmpty() Then
		Return;
	EndIf;
	
	Selection = QueryResult.SELECT();
	
	// Подготовим необходимые параметры для отборов.
	TableForFilters = New ValueTable;
	TableForFilters.Columns.Add("InitialNode", TypeDescriptionS);
	TableForFilters.Columns.Add("FinalNote", TypeDescriptionS);
	TableForFilters.Columns.Add("Formula");
	TableForFilters.Columns.Add("IsSection");
	TableForFilters.Columns.Add("InitialNodeInRow");
	TableForFilters.Columns.Add("FinalNodeInRow");
	TableForFilters.Columns.Add("SkipInCalculations");
	TableForFilters.Columns.Add("ParameterInitialNode");
	TableForFilters.Columns.Add("ParameterFinalNode");

	// Для корректной обработки формул создадим соответствие ссылке строке.
	ItemsToRowsMap = New Map;
	
	If FullUpdate Then
		EdgeTable.Clear();
		Counter = 1;
	Else
		ItemsToRowsMap = GetFromTempStorage(NodeMapStorageAddress);
		Counter = ItemsToRowsMap.Count() + 1;
	EndIf;
	
	// Заполним временную таблицу для дальнейших отборов и работе с ней.
	While Selection.Next() Do
		TableRow = TableForFilters.Add();
		TableRow.InitialNode = Selection.InitialNode;
		TableRow.FinalNote = Selection.FinalNote;
		TableRow.SkipInCalculations = Selection.SkipInCalculations;
		TableRow.IsSection = Selection.IsSection;
		TableRow.InitialNodeInRow = GetMapValues(ItemsToRowsMap,Selection.InitialNode,Counter);
		TableRow.FinalNodeInRow = GetMapValues(ItemsToRowsMap,Selection.FinalNote,Counter);
		TableRow.Formula = Selection.Formula;
		TableRow.ParameterInitialNode = Selection.Analytics;
		TableRow.ParameterFinalNode = Selection.Section;
		If NOT FullUpdate Then
			RowParent = EdgeTable.FindRows(New Structure("InitialNode", Selection.FinalNote));
			If NOT RowParent.Count()=0 Then
				RowParent[0].IsSection = True;
			EndIf;
			Break;
		EndIf;
	EndDo;
	
	NodeMapStorageAddress = PutToTempStorage(ItemsToRowsMap, UUID);
	
	// Т.к. все необходимые нам данные мы отправили в таблицу для отборов, то переберем ее. 
	For Each CurRow In TableForFilters Do
		// Заполним по конечному узлу.
		If ValueIsFilled(CurRow.FinalNote) Then 
			FilterByRow = New Structure("InitialNode,FinalNote,Formula",CurRow.InitialNode, CurRow.FinalNote, CurRow.Formula);
			FoundEdgeTableRowsArray = EdgeTable.FindRows(FilterByRow);
			If FoundEdgeTableRowsArray.Count() = 0 Then
				EdgeRow = EdgeTable.Add();
				FillPropertyValues(EdgeRow, CurRow);
			EndIf;
		EndIf;
		
		// Добавим значениями по формуле.
		If CurRow.IsSection AND ValueIsFilled(CurRow.Formula) Then
			
			Formula = CurRow.Formula;
			
			// Получим массив элементов из формулы.
			ItemsArray = ConvertFormulaToArray(Formula);
			
			FilterByInitialNode = New Structure("InitialNodeInRow");
			FilterByFinalNode = New Structure("FinalNodeInRow");
			
			For Each FormulaItem In ItemsArray Do
				PresentInTable = False;
				FilterByInitialNode.InitialNodeInRow = FormulaItem;
				FoundRowsArray = TableForFilters.FindRows(FilterByInitialNode);
				If FoundRowsArray.Count() > 0 Then 
					PresentInTable = True;
					FormulaParameter = FoundRowsArray[0].ParameterInitialNode;
				Else
					FilterByFinalNode.FinalNodeInRow = FormulaItem;
					FoundRowsArray = TableForFilters.FindRows(FilterByFinalNode);
					If FoundRowsArray.Count() > 0 Then 
						PresentInTable = True;
						FormulaParameter = FoundRowsArray[0].ParameterFinalNode;
					EndIf;
				EndIf;
				
				If PresentInTable Then
					EdgeRow = EdgeTable.Add();
					EdgeRow.InitialNode = FormulaParameter;
					EdgeRow.FinalNote = CurRow.InitialNode;
					EdgeRow.Formula = Formula;
					EdgeRow.IsSection = False;
					EdgeRow.InitialNodeInRow = FormulaItem;
					EdgeRow.FinalNodeInRow = CurRow.InitialNodeInRow;
				EndIf;
				
			EndDo;
		EndIf;
	EndDo;
	EdgeTable.Sort("FinalNote");
EndProcedure

// Процедура - Выполнить полный обход дерева бюджетов
//
&AtServer
Procedure ExecuteFullIterationOfBudgetTree()
	
	// Подготовим параметры.
	ScannedNodesArray = New Array;
	AdditionalParameters = PrepareDataForFullIteration();
	
	// Обходим все основные верхушки дерева бюджета.
	SectionsParentsArray = AdditionalParameters.SectionsArray;
	For Each Section In SectionsParentsArray Do
		
		PrepareScannedNodesArray(ScannedNodesArray,Section, False);
		
	EndDo;
	// Обход массива рассмотренных узлов в порядке получения конечных вершин.
	ScannedNodesArrayIteration(ScannedNodesArray, AdditionalParameters.PeriodsArray, AdditionalParameters.ResourcesArray);
	
EndProcedure

// Процедура - Обновить значения разделов.
//
// Параметры:
//  Ресурс			 - Строка - Имя элемента изменяемой колонки. Пример "Ресурс_Бюджет".
//  ТекущиеДанные	 - ДанныеФормыКоллекция - Изменяемая строка ТЗ.
//
&AtServer
Procedure ExecutePartialIterationOfBudgetsTree(Resource, CurrentData)
	
	// Выберем текущую строку.
	If ValueIsFilled(CurrentData.Analytics3) Then
		CurrentRow = CurrentData.RowID;
	ElsIf ValueIsFilled(CurrentData.Analytics2) Then
		CurrentRow = CurrentData.RowID;
	ElsIf ValueIsFilled(CurrentData.Analytics1) Then
		CurrentRow = CurrentData.RowID;
	ElsIf ValueIsFilled(CurrentData.Analytics) Then
		CurrentRow = CurrentData.RowID;
	ElsIf ValueIsFilled(CurrentData.Section) Then
		CurrentRow = CurrentData.RowID;
	Else
		Return;
	EndIf;
	
	// Подготовим параметры
	PeriodsArray = New Array;
	PeriodsArray.Add(CurrentData.Period);
	
	ResourcesArray = New Array;
	ResourcesArray.Add(Resource);
	
	ScannedNodesArray = New Array;
	
	// Обойдем дерево и сформируем массив рассмотренных узлов.
	PrepareScannedNodesArray(ScannedNodesArray,CurrentRow, True);
	
	// Обойдем массив рассмотренных узлов в верном порядке.
	ScannedNodesArrayIteration(ScannedNodesArray, PeriodsArray, ResourcesArray);
	
EndProcedure

// Процедура - Выполнить частичный обход дерева бюджетов по строке
//
// Параметры:
//  ТекущиеДанные	 - ДанныеФормыКоллекция	 - Строка ТЗ.
//  Ресурс			 - Строка - Имя элемента изменяемой колонки. Пример "Ресурс_Бюджет".
//
&AtServer
Procedure ExecutePartialIterationOfBudgetsTreeByRow(CurrentData, Resource = "")
	
	// Выберем текущую строку.
	If ValueIsFilled(CurrentData.Analytics3) Then
		CurrentRow = CurrentData.RowID;
	ElsIf ValueIsFilled(CurrentData.Analytics2) Then
		CurrentRow = CurrentData.RowID;
	ElsIf ValueIsFilled(CurrentData.Analytics1) Then
		CurrentRow = CurrentData.RowID;
	ElsIf ValueIsFilled(CurrentData.Analytics) Then
		CurrentRow = CurrentData.RowID;
	ElsIf ValueIsFilled(CurrentData.Section) Then
		CurrentRow = CurrentData.RowID;
	Else
		Return;
	EndIf;
	
	// Подготовим параметры
	ScannedNodesArray = New Array;
	ResourceIsKnown = NOT IsBlankString(Resource);
	AdditionalParameters = PrepareDataForFullIteration(False,True,(NOT ResourceIsKnown));
	
	If ResourceIsKnown Then 
		AdditionalParameters.ResourcesArray.Add(Resource);
	EndIf;
	
	// Обойдем дерево и сформируем массив рассмотренных узлов.
	PrepareScannedNodesArray(ScannedNodesArray,CurrentRow, True);
	
	// Обойдем массив рассмотренных узлов в верном порядке.
	ScannedNodesArrayIteration(ScannedNodesArray, AdditionalParameters.PeriodsArray, AdditionalParameters.ResourcesArray);
	
EndProcedure

// Функция - Получить родителей разделов из ТЗИсходных данных
// 
// Возвращаемое значение:
//  Массив - Массив всех верхушек дерева бюджетирования.
//
&AtServer
Function PrepareDataForFullIteration(GetSectionsArray = True, GetPeriodsArray = True,GetResourcesArray = True)
	
	// Подготовим параметры.
	SectionsArray = New Array;
	PeriodsArray = New Array;
	ResourcesArray = New Array;
	
	// Получим таблицу исходных данных	
	If GetSectionsArray Then
		
		SQ = New StringQualifiers(250);
		Array = New Array;
		Array.Add(Type("String"));
		TypeDescriptionS = New TypeDescription(Array, , SQ);
		
		// Выгрузим таблицу ребер для получения верхних уровней разделов.
		VTOfEdges = New ValueTable;
		VTOfEdges.Columns.Add("FinalNote", TypeDescriptionS);
		VTOfEdges.Columns.Add("InitialNode", TypeDescriptionS);
		
		For Each CurRow In EdgeTable Do
			If NOT ValueIsFilled(CurRow.InitialNode) Then
				NewLine = VTOfEdges.Add();
				NewLine.InitialNode = CurRow.InitialNode;
				NewLine.FinalNote = CurRow.FinalNote;
			EndIf;
		EndDo;
		
		// Получим родителей всех разделов.
		Query = New Query;
		Query.Text = "SELECT
		|	EdgeTable.FinalNote AS Section
		|INTO TT_Sections
		|FROM
		|	&EdgeTable AS EdgeTable
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	TT_Sections.Section AS Section
		|FROM
		|	TT_Sections AS TT_Sections
		|
		|GROUP BY
		|	TT_Sections.Section";
		
		Query.SetParameter("EdgeTable", EdgeTable.Unload());
		
		QueryResult = Query.Execute();
		
		// Заполним массив разделов по которым будем спускаться вниз.
		If NOT QueryResult.IsEmpty() Then
			Selection = QueryResult.SELECT();
			While Selection.Next() Do
				SectionsArray.Add(Selection.Section);
			EndDo;
		EndIf;
	EndIf;
	
	If GetPeriodsArray Then
		// Сформируем массив периодов.
		For Each Period In Periods Do
			If ValueIsFilled(Period.Value) Then
				PeriodsArray.Add(Period.Value);
			EndIf;
		EndDo;
	EndIf;
	
	If GetResourcesArray Then
		// Сформируем массив ресурсов.
		For Each Resource In Resources Do
			If ValueIsFilled(Resource.Value) Then
				ResourcesArray.Add("Resource_" + Resource.Value);
			EndIf;
		EndDo;
	EndIf;
	
	// Сформируем структуру результата.
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("SectionsArray",SectionsArray);
	AdditionalParameters.Insert("PeriodsArray",PeriodsArray);
	AdditionalParameters.Insert("ResourcesArray",ResourcesArray);
	Return AdditionalParameters;
	
EndFunction

// Процедура - Подготовить массив рассмотренных узлов
//
// Параметры:
//  МассивРассмотренныхУзлов - Массив - Массив рассмотренных узлов.
//  ТекущаяСтрока			 - Произвольный - Текущая строка аналитика/раздел.
//  ЧастичныйОбход			 - Булево - Признак необходимости обхода родителей потомков.
//
&AtServer
Procedure PrepareScannedNodesArray(ScannedNodesArray, CurrentRow, PartialIteration = True)
	
	// Подготовим параметры
	QueueForIteration = New Array;
	ScannedChildrenArray = New Array;
	UnknownNodes = New Map;
	
	// Добавим первый элемент в очередь и приступим к исследованию.
	AddInArray(QueueForIteration,CurrentRow,False);
	While NOT QueueForIteration.Count() = 0 Do
		
		// Возьмем новую строку из очереди.
		CurrentRow = TakeFromArray(QueueForIteration);
		
		// Проверим можно или нужно ли ее рассматривать дальше.
		CurrentRowIsScanned = NOT (ScannedNodesArray.Find(CurrentRow) = Undefined);
		If NOT ValueIsFilled(CurrentRow) OR CurrentRowIsScanned Then
			Continue;
		EndIf;
		
		// Для потомков не будем рассматривать родителей (обходяться только при полном обходе, т.е. ЧастичныйОбход=Ложь)
		IsChild = NOT (UnknownNodes.Get(CurrentRow) = Undefined);
		If NOT IsChild Then
			
			// Найдем всех родителей и обработаем их.
			ParentRowsArray = EdgeTable.FindRows(New Structure("InitialNode",CurrentRow));
			
			//Заполним очередь родителями
			For Each Parent In ParentRowsArray Do
				AddInArray(QueueForIteration,Parent.FinalNote,False);
			EndDo;
		EndIf;
		
		// Обойдем текущий узел.
		GraphNodeIteration(CurrentRow, ScannedNodesArray, QueueForIteration, UnknownNodes, ScannedChildrenArray, PartialIteration, IsChild);
	
	EndDo;
EndProcedure

// Процедура - Обход строки
//
// Параметры:
//  ТекущаяСтрока				 - Ссылка - Обрабатываемый элемент.
//  МассивРассмотренныхУзлов	 - Массив - Массив узлов, которые уже были рассмотренны.
//  ОчередьДляОбхода			 - Массив - Массив узлов, которых еще только предстоит рассмотреть.
//  НеизвестныеУзлы				 - Соответствие - Список потомков, которые еще не рассмотрели. 
//  МассивРассмотренныхПотомков	 - Массив - Массив потомков, которые уже были рассмотренны.
//  ЧастичныйОбход				 - Булево - Признак полного обхода
//  ЯвляетсяПотомком			 - Булево - Признак того, что текущий узел потомок.
//
&AtServer
Procedure GraphNodeIteration(CurrentRow, ScannedNodesArray,QueueForIteration,
							UnknownNodes, ScannedChildrenArray, PartialIteration = False, IsChild = False)
	
	UnknownChildrenCounter = 0;
	// Подготовим массив потомков.
	ChildrenArray = EdgeTable.FindRows(New Structure("FinalNote",CurrentRow));
		For Each Child In ChildrenArray Do
	
		// Если он раздел и не рассчитывался, тогда добавим его в очередь. 
		If ValueIsFilled(Child.InitialNode) 
			AND ((ScannedNodesArray.Find(Child.InitialNode) = Undefined) 
			AND (ScannedChildrenArray.Find(Child.InitialNode) = Undefined)) Then 
			If Child.IsSection Then
				// Разрешим хранить дубли в очереди для потомков.
				If QueueForIteration.Find(Child.InitialNode) = Undefined Then
					AddInArray(QueueForIteration,Child.InitialNode,True);
				Else
					QueueForIteration.Insert(0, Child.InitialNode);
				EndIf;
				
				// При частичном обходе отключим получение родителей, для неизвестных узлов.
				If PartialIteration AND UnknownNodes.Get(Child.InitialNode) = Undefined Then
					UnknownNodes.Insert(Child.InitialNode, True);
				EndIf;
				
				UnknownChildrenCounter = UnknownChildrenCounter + 1;
				Continue;
			ElsIf NOT PartialIteration Then
				// При полном обходе важно обойти и аналитику.
				ScannedNodesArray.Add(Child.InitialNode);
			EndIf;
		EndIf;
	EndDo;
	
	
	// Проверим возможность занесения в рассмотренные.
	If UnknownChildrenCounter = 0 Then
		If IsChild Then
			UnknownNodes.Delete(CurrentRow);
			ScannedChildrenArray.Add(CurrentRow);
		Else
			ScannedNodesArray.Add(CurrentRow);
		EndIf;
	Else
		// Отложим проверку - сначала обойдем потомков.
		AddInArray(QueueForIteration,CurrentRow,False, UnknownChildrenCounter);
	EndIf;

EndProcedure

// Процедура - Обход массива рассмотренных узлов
//
// Параметры:
//  МассивРассмотренныхУзлов - Массив - Массив рассмотренных узлов в специальном порядке.
//
&AtServer
Procedure ScannedNodesArrayIteration(ScannedNodesArray,PeriodsArray, ResourcesArray)
	
	// Подготовим параметры
	GroupRow = Undefined;
	EmptyAnalytics = Undefined;
	SQ = New StringQualifiers(250);
	Array = New Array;
	Array.Add(Type("String"));
	TypeDescriptionS = New TypeDescription(Array, , SQ);
	
	// Подготовим 3 таблицы.
	
	//Выгрузку таблицы с исходными данными + ключем связи.
	InitialDataTable = PrepareInitialDataTable();
	
	// Таблицу для отборов с группировками по разделам.
	FiltersTable = New ValueTable;
	
	// Таблицу для отборов с группировками по аналитикам.
	FiltersByAnalyticsTable = New ValueTable;
	
	// Заполним таблицы отборов колонками.
	TablesArray = New Array;
	TablesArray.Add(FiltersTable);
	TablesArray.Add(FiltersByAnalyticsTable);
	For Each CurTable In TablesArray Do
		CurTable.Columns.Add("GroupLevel",New TypeDescription("Number"));
		CurTable.Columns.Add("RowID",TypeDescriptionS);
		CurTable.Columns.Add("Period", New TypeDescription("DATE"));
		CurTable.Columns.Add("InitialNodeInRow", New TypeDescription("String",,,, New StringQualifiers(100)));
		CurTable.Columns.Add("Formula",New TypeDescription("String",,,, New StringQualifiers(500)));
		// Тип отбора: 1 - Группировка, 2 - Потомок группировки, 3 - аналитика.
		CurTable.Columns.Add("FilterType",New TypeDescription("Number"));
	EndDo;
	
	// Установим счетчик уровня группировки.
	GroupLevel = 1;
	
	// Обойдем Массив для расчета
	For Each CurrentGroup In ScannedNodesArray Do
		// Проверим тип для заполнения разных таблиц отборов.
		
		InitialNodesArray = EdgeTable.FindRows(New Structure("InitialNode", CurrentGroup));
		If InitialNodesArray.Count() Then
			IsSection = InitialNodesArray[0].IsSection;
		Else
			IsSection = True;
		EndIf;
		
		If IsSection Then
			
			// Получим потомков для формирования итоговой формулы.
			ChildrenArray = EdgeTable.FindRows(New Structure("FinalNote,SkipInCalculations", CurrentGroup,False));
			ChildrenExist = (ChildrenArray.Count() > 0);
			
			If ChildrenExist Then
				CurrentFormula = ChildrenArray[0].Formula;
				// Соберем формулу.
				If CurrentFormula = "Amount" OR IsBlankString(CurrentFormula) Then
					CurrentFormula = "0";
					For Each Child In ChildrenArray Do
						If ValueIsFilled(Child.InitialNode) Then
							CurrentFormula = CurrentFormula + "+[" + Child.InitialNodeInRow + "]";
						EndIf;
					EndDo;
				EndIf;
			Else
				CurrentFormula = "";
			EndIf;
			
			// Обойдем периоды.
			For Each Period In PeriodsArray Do
				// Добавим отбор по периоду.
				NewFilterRow = FiltersTable.Add();
				NewFilterRow.RowID = CurrentGroup;
				NewFilterRow.Period = Period;
				NewFilterRow.FilterType = 1;
				NewFilterRow.GroupLevel = GroupLevel;
				
				// Если нашли, то возьмем формулу.
				If ChildrenExist Then
					
					NewFilterRow.Formula = CurrentFormula;
					// Добавим строки потомков в таблоицу отборов.
					For Each Child In ChildrenArray Do
						If ValueIsFilled(Child.InitialNode) Then
							NewFilterRow = FiltersTable.Add();
							NewFilterRow.RowID = Child.InitialNode;
							NewFilterRow.Period = Period;
							NewFilterRow.InitialNodeInRow = Child.InitialNodeInRow;
							NewFilterRow.Formula = "";
							NewFilterRow.FilterType = 2;
							NewFilterRow.GroupLevel = GroupLevel;
						EndIf;
					EndDo;
				EndIf;
			EndDo;
			
		Else
			// Добавим отбор по аналитике.
			NewFilterRow = FiltersByAnalyticsTable.Add();
			NewFilterRow.RowID = CurrentGroup;
			NewFilterRow.FilterType = 3;
			NewFilterRow.GroupLevel = GroupLevel;
		EndIf;

		GroupLevel = GroupLevel + 1;
	EndDo;

	// Подготовим запрос.
	Query = New Query;
	Query.SetParameter("FiltersTable", FiltersTable);
	Query.SetParameter("InitialDataVT", InitialDataTable);
	Query.SetParameter("EmptyDate", DATE('00010101'));
	Query.SetParameter("EmptySection", Undefined);

	////////////////////////////////
	// Выполним вертикальный расчет.
	ExecuteVerticalTotalsCalculation(Query, ResourcesArray);
	
	////////////////////////////////
	// Выполним горизонтальный расчет.
	ExecuteHorizontalTotalsCalculation(Query, FiltersByAnalyticsTable, ResourcesArray);
	
EndProcedure

&AtServer
Procedure ExecuteVerticalTotalsCalculation(Query, ResourcesArray)
	
	QueryText = 
	"SELECT
	|	FiltersTable.RowID AS RowID,
	|	FiltersTable.Period AS Period,
	|	FiltersTable.InitialNodeInRow AS InitialNodeInRow,
	|	FiltersTable.Formula AS Formula,
	|	FiltersTable.FilterType AS FilterType,
	|	FiltersTable.GroupLevel AS GroupLevel
	|INTO TT_TableWithFilters
	|FROM
	|	&FiltersTable AS FiltersTable
	|
	|INDEX BY
	|	RowID,
	|	Period
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	InitialDataVT.RowID AS RowID,
	|	InitialDataVT.Period AS Period,
	|	InitialDataVT.LinkKey AS LinkKey
	|INTO InitialDataVT
	|FROM
	|	&InitialDataVT AS InitialDataVT
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TT_VTOfInitialData.RowID AS RowID,
	|	TT_VTOfInitialData.Period AS Period,
	|	TT_VTOfInitialData.LinkKey AS LinkKey
	|INTO TT_VTOfInitialData
	|FROM
	|	InitialDataVT AS TT_VTOfInitialData
	|
	|INDEX BY
	|	RowID,
	|	Period
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|DROP InitialDataVT
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TT_TableWithFilters.InitialNodeInRow AS InitialNodeInRow,
	|	TT_TableWithFilters.Formula AS Formula,
	|	ISNULL(TT_VTOfInitialData.LinkKey, 0) AS LinkKey,
	|	TT_TableWithFilters.FilterType AS FilterType,
	|	TT_TableWithFilters.Period AS Period,
	|	TT_TableWithFilters.GroupLevel AS GroupLevel
	|INTO TT_WithoutCollapse
	|FROM
	|	TT_TableWithFilters AS TT_TableWithFilters
	|		LEFT JOIN TT_VTOfInitialData AS TT_VTOfInitialData
	|		ON TT_TableWithFilters.RowID = TT_VTOfInitialData.RowID
	|			AND TT_TableWithFilters.Period = TT_VTOfInitialData.Period
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|DROP TT_VTOfInitialData
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|DROP TT_TableWithFilters
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TT_WithoutCollapse.InitialNodeInRow AS InitialNodeInRow,
	|	TT_WithoutCollapse.Formula AS Formula,
	|	MAX(TT_WithoutCollapse.LinkKey) AS LinkKey,
	|	TT_WithoutCollapse.FilterType AS FilterType,
	|	TT_WithoutCollapse.Period AS Period,
	|	TT_WithoutCollapse.GroupLevel AS GroupLevel
	|FROM
	|	TT_WithoutCollapse AS TT_WithoutCollapse
	|
	|GROUP BY
	|	TT_WithoutCollapse.InitialNodeInRow,
	|	TT_WithoutCollapse.Formula,
	|	TT_WithoutCollapse.FilterType,
	|	TT_WithoutCollapse.Period,
	|	TT_WithoutCollapse.GroupLevel
	|
	|ORDER BY
	|	GroupLevel
	|TOTALS BY
	|	GroupLevel,
	|	Period
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|DROP TT_WithoutCollapse";
	
	Query.Text = QueryText;
	
	QueryResult = Query.Execute();
	If NOT QueryResult.IsEmpty() Then
		
		GroupSelection = QueryResult.SELECT(QueryResultIteration.ByGroups);
		InitialDataVT = GetFromTempStorage(InitialDataVTAddress);
		
		// Обход на уровне группировок.
		While GroupSelection.Next() Do
			
			SelectionByPeriods = GroupSelection.SELECT(QueryResultIteration.ByGroups);
			
			GroupRow = Undefined;
			While SelectionByPeriods.Next() Do
				Selection = SelectionByPeriods.SELECT();
				
				// Инициализация параметров.
				ChildrenRowsMapFromVTOfInitialData = New Map;
				MainRowKey = 0;
				CurrentFormula = "";
				
				// Обход на уровне строк.
				While Selection.Next() Do
					// Если это родитель, то запомним ее ключ.
					If Selection.FilterType = 1 Then
						MainRowKey = Selection.LinkKey;
						CurrentFormula = Selection.Formula;
					ElsIf Selection.FilterType = 2 Then
						//Добавим строку для дальнейших вычислений.
						ChildrenRowsMapFromVTOfInitialData.Insert(Selection.InitialNodeInRow, InitialDataVT[Selection.LinkKey]);
					Else
						MainRowKey = Selection.LinkKey;
						CurrentFormula = Selection.Formula;
						Break;
					EndIf;
				EndDo;
				
				// Получим строку группировки для последующей записи в нее найденного значения.
				GroupRow = InitialDataVT[MainRowKey];
				
				For Each Resource In ResourcesArray Do
					// Получим формулу для расчета значения.
					FormulaForCalculations = CurrentFormula;
					If ValueIsFilled(FormulaForCalculations) Then
						For Each ChildRowFromVT In ChildrenRowsMapFromVTOfInitialData Do
							ResourceValue = Format(ChildRowFromVT.Value[Resource],"NDS=.; NZ=0; NG=0");
							FormulaForCalculations = StrReplace(FormulaForCalculations,"["+ChildRowFromVT.Key+"]",ResourceValue);
						EndDo;
						
						// Подчистим формулу от не найденных потомков.
						While StrFind(FormulaForCalculations,"[") > 0 Do
							OpenBracketNumber = StrFind(CurrentFormula,"[");
							CloseBracketNumber = StrFind(CurrentFormula,"]");
							If CloseBracketNumber > 0 Then
								FormulaForCalculations = StrReplace(FormulaForCalculations,Mid(FormulaForCalculations,OpenBracketNumber, CloseBracketNumber-OpenBracketNumber),"0");
							EndIf;
						EndDo;
					Else
						// Если формулы нет, то просто берем значение по ресурсу.
						FormulaForCalculations = Format(GroupRow[Resource],"NDS=.; NZ=0; NG=0");
					EndIf;
					
					// Выполним расчет строки.
					If ExecuteValueCalculation(GroupRow, Resource, FormulaForCalculations, True) Then
						Break;
					EndIf;
				EndDo;
				
			EndDo;
		EndDo;
	EndIf;
EndProcedure

&AtServer
Procedure ExecuteHorizontalTotalsCalculation(Query, FiltersByAnalyticsTable, ResourcesArray)
	
	// Подготовим параметры.
	NumberTypeDescription = New TypeDescription("Number", , , New NumberQualifiers(17, 2));
	CalculateQuarters = (Quarters.Count() > 0); 
	
	ValuesByQuarters = New Map;
	QuartersColumns = New Map;
	For Each Quarter In Quarters Do
		QuartersColumns.Insert(Quarter.Period, Quarter.ColumnNumber);
		ValuesByQuarters.Insert(Quarter.Period,0);
	EndDo;
	
	// Сформируем таблицу периодов.
	PeriodsTable = New ValueTable;
	PeriodsTable.Columns.Add("Period", New TypeDescription("DATE"));
	For Each CurRow In Periods Do
		NewLine = PeriodsTable.Add();
		NewLine.Period = CurRow.Value;
	EndDo;
	
	QueryText = 
	"SELECT
	|	FiltersTable.GroupLevel AS GroupLevel,
	|	FiltersTable.RowID AS RowID
	|INTO FiltersTable
	|FROM
	|	&FiltersTable AS FiltersTable
	|WHERE
	|	NOT FiltersTable.FilterType = 2
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	FiltersTable.GroupLevel AS GroupLevel,
	|	FiltersTable.RowID AS RowID
	|INTO TT_TableWithFiltersByAnalytics
	|FROM
	|	&FiltersByAnalyticsTable AS FiltersTable
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TT_TableWithFilters.GroupLevel AS GroupLevel,
	|	TT_TableWithFilters.RowID AS RowID
	|INTO TT_TableWithFilters
	|FROM
	|	FiltersTable AS TT_TableWithFilters
	|
	|GROUP BY
	|	TT_TableWithFilters.GroupLevel,
	|	TT_TableWithFilters.RowID
	|
	|UNION ALL
	|
	|SELECT
	|	TT_TableWithFiltersByAnalytics.GroupLevel,
	|	TT_TableWithFiltersByAnalytics.RowID
	|FROM
	|	TT_TableWithFiltersByAnalytics AS TT_TableWithFiltersByAnalytics
	|
	|GROUP BY
	|	TT_TableWithFiltersByAnalytics.GroupLevel,
	|	TT_TableWithFiltersByAnalytics.RowID
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|DROP TT_TableWithFiltersByAnalytics
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|DROP FiltersTable
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	PeriodsTable.Period AS Period
	|INTO TT_Periods
	|FROM
	|	&PeriodsTable AS PeriodsTable
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TT_Periods.Period AS Period,
	|	TT_TableWithFilters.GroupLevel AS GroupLevel,
	|	TT_TableWithFilters.RowID AS RowID
	|INTO TT_FiltersWithPeriods
	|FROM
	|	TT_TableWithFilters AS TT_TableWithFilters,
	|	TT_Periods AS TT_Periods
	|
	|INDEX BY
	|	RowID,
	|	Period
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|DROP TT_TableWithFilters
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TT_VTOfInitialData.RowID AS RowID,
	|	TT_VTOfInitialData.Period AS Period,
	|	TT_VTOfInitialData.LinkKey AS LinkKey
	|INTO TT_VTOfInitialData
	|FROM
	|	&InitialDataVT AS TT_VTOfInitialData
	|
	|INDEX BY
	|	RowID,
	|	Period
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TT_FiltersWithPeriods.GroupLevel AS GroupLevel,
	|	ISNULL(TT_VTOfInitialData.LinkKey, 0) AS LinkKey,
	|	TT_VTOfInitialData.Period AS Period
	|INTO TT_WithoutCollapse
	|FROM
	|	TT_FiltersWithPeriods AS TT_FiltersWithPeriods
	|		LEFT JOIN TT_VTOfInitialData AS TT_VTOfInitialData
	|		ON TT_FiltersWithPeriods.RowID = TT_VTOfInitialData.RowID
	|			AND TT_FiltersWithPeriods.Period = TT_VTOfInitialData.Period
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|DROP TT_VTOfInitialData
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|DROP TT_FiltersWithPeriods
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TT_WithoutCollapse.GroupLevel AS GroupLevel,
	|	MAX(TT_WithoutCollapse.LinkKey) AS LinkKey,
	|	TT_WithoutCollapse.Period AS Period
	|FROM
	|	TT_WithoutCollapse AS TT_WithoutCollapse
	|WHERE
	|	NOT TT_WithoutCollapse.Period = &EmptyDate
	|
	|GROUP BY
	|	TT_WithoutCollapse.GroupLevel,
	|	TT_WithoutCollapse.Period
	|TOTALS BY
	|	GroupLevel
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|DROP TT_WithoutCollapse";
	Query.SetParameter("PeriodsTable", PeriodsTable);
	Query.SetParameter("FiltersByAnalyticsTable", FiltersByAnalyticsTable);
	
	Query.Text = QueryText;
	QueryResult = Query.Execute();
	
	If NOT QueryResult.IsEmpty() Then
		
		GroupSelection = QueryResult.SELECT(QueryResultIteration.ByGroups);
		InitialDataVT = GetFromTempStorage(InitialDataVTAddress);
		
		// Обход на уровне группировок.
		While GroupSelection.Next() Do
			SelectionByPeriods = GroupSelection.SELECT(QueryResultIteration.ByGroups);
			
			// Соберем массив строк по всем периодам.
			GroupsArray = New Array;
			While SelectionByPeriods.Next() Do
				GroupsArray.Add(InitialDataVT[SelectionByPeriods.LinkKey]);
			EndDo;
			
			If GroupsArray.Count() > 0 Then
				InitialTableRow = GroupsArray[0];
				For Each Resource In ResourcesArray Do
					ResourceRowNumber = InitialTableRow[StrReplace(Resource, "Resource_", "CoordRow_")];
					If ResourceRowNumber = 0 Then
						Continue;
					EndIf;
					
					Overall = 0;
					If CalculateQuarters Then
						
						// Обнуляем показатели массива кварталов.
						For Each Quarter In ValuesByQuarters Do
							ValuesByQuarters.Insert(Quarter.Key,0);
						EndDo;
						
						// Заполним данные по кварталу.
						For Each GroupRow In GroupsArray Do
							QuarterPeriod = BegOfQuarter(GroupRow.Period);
							ValuesByQuarters.Insert(QuarterPeriod, ValuesByQuarters[QuarterPeriod] + GroupRow[Resource]);
						EndDo;
						
						// Отобразить в Табличном документе результаты.
						For Each Quarter In ValuesByQuarters Do
							QuarterValue = Quarter.Value;
							CurrentArea = BudgetTree.Region(ResourceRowNumber,QuartersColumns.Get(Quarter.Key));
							CurrentArea.ContainsValue = True;
							CurrentArea.ValueType		= NumberTypeDescription;
							CurrentArea.Format = ViewFormat;
							CurrentArea.EditFormat = EditFormat;
							CurrentArea.Value = QuarterValue;
							Overall = Overall + QuarterValue;
						EndDo;
						
					Else
						// Заполним данные по итогу.
						For Each GroupRow In GroupsArray Do
							Overall = Overall + GroupRow[Resource];
						EndDo;
					EndIf;
					
					// Отобразим итоговое значение.
					CurrentArea = BudgetTree.Region(ResourceRowNumber,3);
					CurrentArea.ContainsValue = True;
					CurrentArea.ValueType		= NumberTypeDescription;
					CurrentArea.Format = ViewFormat;
					CurrentArea.EditFormat = EditFormat;
					CurrentArea.Value = Overall;
				EndDo;
			EndIf;
			
		EndDo;
	EndIf;	
EndProcedure

&AtServer
Function PrepareInitialDataTable()
	
	// Подготовим общие параметры.
	SQ = New StringQualifiers(250);
	Array = New Array;
	Array.Add(Type("String"));
	TypeDescriptionS = New TypeDescription(Array, , SQ);
	
	InitialDataTable = New ValueTable;
	InitialDataTable.Columns.Add("Section", New TypeDescription("CatalogRef.fmInfoStructuresSections"));
	InitialDataTable.Columns.Add("SectionParent", New TypeDescription("CatalogRef.fmInfoStructuresSections"));
	InitialDataTable.Columns.Add("Analytics", New TypeDescription("CatalogRef.fmIncomesAndExpensesItems, CatalogRef.fmCashflowItems"));
	InitialDataTable.Columns.Add("Analytics1", Metadata.ChartsOfCharacteristicTypes.fmAnalyticsTypes.Type);
	InitialDataTable.Columns.Add("Analytics2", Metadata.ChartsOfCharacteristicTypes.fmAnalyticsTypes.Type);
	InitialDataTable.Columns.Add("Analytics3", Metadata.ChartsOfCharacteristicTypes.fmAnalyticsTypes.Type);
	InitialDataTable.Columns.Add("Period", New TypeDescription("DATE"));
	InitialDataTable.Columns.Add("LinkKey", New TypeDescription("Number"));
	InitialDataTable.Columns.Add("RowID",TypeDescriptionS);
	
	InitialDataVT = GetFromTempStorage(InitialDataVTAddress);
	For Each CurRow In InitialDataVT Do
		NewLine = InitialDataTable.Add();
		NewLine.Section = CurRow.Section;
		NewLine.SectionParent = CurRow.SectionParent;
		NewLine.Analytics = CurRow.Analytics;
		NewLine.Analytics1 = CurRow.Analytics1;
		NewLine.Analytics2 = CurRow.Analytics2;
		NewLine.Analytics3 = CurRow.Analytics3;
		NewLine.Period = CurRow.Period;
		NewLine.LinkKey = InitialDataVT.IndexOf(CurRow);
		NewLine.RowID = CurRow.RowID;
	EndDo;
	Return InitialDataTable;
EndFunction

// Процедура - Добавить в массив
//
// Параметры:
//  Массив	 - Массив - Массив куда нужно добавить элемент.
//  Значение - Произвольный - Значение, которое следует добавить.
//  ВНачало	 - Булево - Порядок добавления (в начало или в конец).
//  ПорядковыйНомер	 - Число - В случае если добавлять необходимо не в начало, то можно указать порядковый номер.
//
&AtClientAtServerNoContext
Procedure AddInArray(Array,Value,ToBegin= True, SerialNumber = -1)
	// Сделаем проверку на дубль.
	If NOT Array.Find(Value) = Undefined Then
		Return;
	EndIf;
	
	If ToBegin Then
		Array.Insert(0,Value);
	ElsIf SerialNumber = -1 Then
		Array.Add(Value);
	Else 
		Array.Insert(SerialNumber,Value);
	EndIf;
	
EndProcedure

// Взять из элемент из массива, при этом и удалить его.
//
// Параметры:
//  Массив	 - Массив - Массив от куда следует взять элемент.
// 
// Возвращаемое значение:
//  Произвольный - Значение, которое следует взять из массива.
//
&AtClientAtServerNoContext
Function TakeFromArray(Array)
	If Array.Count()=0 Then
		Return Undefined;
	Else
		Value=Array[0];
		Array.Delete(0);
		Return Value;
	EndIf;
EndFunction

// Функция - Преобразовать формулу в массив
//
// Параметры:
//  СтрокаФормула	 - Строка - Формула которую следует распарсить.
// 
// Возвращаемое значение:
//  Массив - Массив параметров, которые удалось получить.
//
&AtServerNoContext
Function ConvertFormulaToArray(StringFormula)
	// Разберем форматную строку
	ItemsArray = New Array;
	InitialPosition = 0;
	FinalPosition = 0;
	Key = "";
	Value = "";
	For Counter = 1 To StrLen(StringFormula) Do
		If Mid(StringFormula,Counter,1) = "[" Then
			InitialPosition = Counter;
			ParameterName = "";
		ElsIf Mid(StringFormula,Counter,1) = "]" Then
			FinalPosition = Counter;
			Parameter = Mid(StringFormula,InitialPosition+1,FinalPosition-InitialPosition-1);
			If NOT IsBlankString(Parameter) Then
				ItemsArray.Add(Parameter);
			EndIf;
		EndIf;
	EndDo;
	
	Return ItemsArray;
EndFunction

// Функция - Получить значение соответствия
//
// Параметры:
//  СоответствиеЭлементовСтрокам - Соответствие - Соответствие ссылок их строковым представлениям.
//  Ключ						 - Ссылка - Значение, которое следует преобразовать.
//  Счетчик						 - Число - Счетчик уникальных адресов.
// 
// Возвращаемое значение:
//  Ссылка - Значение по ключу.
//
&AtServerNoContext
Function GetMapValues(ItemsToRowsMap,Key, Counter = 1)
	ItemValue = ItemsToRowsMap.Get(Key);
	If ItemValue = Undefined Then
		ItemValue = Format(Counter,"NG=0");
		ItemsToRowsMap.Insert(Key,ItemValue); 
		Counter = Counter + 1;
	EndIf;
	Return ItemValue;
EndFunction

// Процедура - Выполнить расчет значения
//
// Параметры:
//  СтрокаГруппировки	 - ДанныеФормыКоллекция - Строка ТЗ Исходных данных.
//  Ресурс				 - Строка - Наименование ресурса.
//  НужноОбновитьТД		 - Булево - Признак необходимости обновления табличного документа.
//  Отказ				 - Булево - Признак ошибки при решении.
//
&AtServer
Function ExecuteValueCalculation(GroupRow, Resource, RightPart = "0", NeedToRefreshSD = False, Cancel = False)
	Try
		// Пытаемся выполнить формулу.
		Execute("GroupRow."+Resource + " = " + RightPart);
		
		If NeedToRefreshSD Then
			// Исправим значение в табличном документе
			LineNumber = GroupRow[StrReplace(Resource, "Resource_", "CoordRow_")];
			ColumnNumber = GroupRow[StrReplace(Resource, "Resource_", "CoordColumn_")];
			CurrentArea = BudgetTree.Region(LineNumber,ColumnNumber);
			CurrentArea.ContainsValue = True;
			CurrentArea.Value = GroupRow[Resource];
			CurrentArea.Format = ViewFormat;
			CurrentArea.EditFormat = EditFormat;
		EndIf;
	Except
		// Что то пошло не так как хотелось.
		Cancel = True;
	EndTry;
	Return Cancel;
EndFunction

#EndRegion


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// ПРОЦЕДУРЫ ОБРАБОТЧИКИ СОБЫТИЙ ФОРМЫ

&AtClient
Procedure OnOpen(Cancel)
	
	If CloseOnOpen Then
		ShowMessageBox(,NStr("en='No interactive work with this form!';ru='Интерактивный вызов запрещён!'"));
		Close();
	EndIf;
	
	fmPeriodChoiceClient.FillPeriodList(ThisObject, Items.PeriodFrom, PeriodType, BegOfMonth(Object.PeriodFrom));
	fmPeriodChoiceClient.FillPeriodList(ThisObject, Items.PeriodTo, PeriodType, BegOfMonth(Object.PeriodTo));
	fmPeriodChoiceClient.FillPeriodList(ThisObject, Items.SourcePeriodFrom, PeriodType, BegOfMonth(Object.SourcePeriodFrom));
	fmPeriodChoiceClient.FillPeriodList(ThisObject, Items.SourcePeriodTo, PeriodType, BegOfMonth(Object.SourcePeriodTo));
	
EndProcedure

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("Prediction") Then
		IsForecasting = Parameters.Prediction;
	EndIf;
	
	// Строка с именами колонок, по которым осуществляется поиск строки в таблице исходных данных.
	SearchColumnsRow = "Section, Analytics, Analytics1, Analytics2, Analytics3, Period";
	ConstantInputFormat = Constants.fmEditFormat.Get();
	
	If Parameters.Property("CurScenario") Then
		
		// Обязательные параметры.
		Object.CurScenario = Parameters.CurScenario;
		CurrentPeriod = Object.CurScenario.PlanningPeriod;
		CurrentPeriodicity = Object.CurScenario.PlanningPeriodicity;
		Object.BeginOfPeriod = Parameters.BeginOfPeriod;
		Object.InfoStructure = Parameters.InfoStructure;
		Object.OperationType = Parameters.OperationType;
		ViewFormat = fmBudgeting.FormViewFormat(Object.InfoStructure);
		EditFormat = fmBudgeting.FormEditFormat(Object.InfoStructure);
		StructureInputFormat = Object.InfoStructure.EditFormat;
		
		// Настроим произвольный отбор по схеме.
		FilterTemplate = DataProcessors.fmPredictionCopy.GetTemplate("FilterSettingSchema");
		If Object.OperationType=Enums.fmBudgetOperationTypes.Cashflows Then
			FilterTemplate.DataSets.DataTable.Fields[0].ValueType = New TypeDescription("CatalogRef.fmCashflowItems");
		EndIf;
		SettingsAddress = PutToTempStorage(FilterTemplate, UUID);
		FilterSettings.Initialize(New DataCompositionAvailableSettingsSource(SettingsAddress));
		
		// Курсы валют
		Object.CurrencyRates.Load(GetFromTempStorage(Parameters.CurrencyRates));
		
		// Настроим выбор показателя прогнозирования.
		IndicatorList = New ValueList;
		IndicatorList.Add("Amount", NStr("en='Amount';ru='Amount'"));
		
		//Элементы.ТекущийПоказатель.СписокВыбора.Очистить();
		//Для Каждого ЭлементСпискаПоказателей Из СписокПоказателей Цикл
		//	Элементы.ТекущийПоказатель.СписокВыбора.Добавить(ЭлементСпискаПоказателей.Значение, ЭлементСпискаПоказателей.Представление);
		//КонецЦикла;

		If Parameters.Property("FillingParameters") AND TypeOf(Parameters.FillingParameters)=Type("Structure") AND Parameters.Prediction Then
			// Заполняем из параметров последнего заполнения.
			Object.ScenarioSource = Parameters.FillingParameters.ScenarioSource;
			Object.IncreasePercent = Parameters.FillingParameters.IncreasePercent;
			Object.SeasonalityPercent = Parameters.FillingParameters.SeasonalityPercent;
			Object.SourceIndicator = Parameters.FillingParameters.SourceIndicator;
			Object.IgnorePeriodsWithoutData = Parameters.FillingParameters.IgnorePeriodsWithoutData;
			Object.IncreaseAbsoluteValue = Parameters.FillingParameters.IncreaseAbsoluteValue;
			Object.PeriodFrom = Parameters.FillingParameters.PeriodFrom;
			Object.PeriodTo = Parameters.FillingParameters.PeriodTo;
			Object.SourcePeriodFrom = Parameters.FillingParameters.SourcePeriodFrom;
			Object.SourcePeriodTo = Parameters.FillingParameters.SourcePeriodTo;
			Object.IncreaseParametersApplication = Parameters.FillingParameters.IncreaseParametersApplication;
			Object.Department = Parameters.FillingParameters.DepartmentSource;
			FilterSettings.LoadSettings(Parameters.FillingParameters.ComplexFilter);
			If NOT IndicatorList.FindByValue(Parameters.FillingParameters.CurrentIndicator)=Undefined Then
				Object.CurrentIndicator = Parameters.FillingParameters.CurrentIndicator;
			Else
				Object.CurrentIndicator = IndicatorList[0].Value;
			EndIf;
			Object.ForecastingItem = Parameters.FillingParameters.ForecastingItem;
			Object.RoundMethod = Parameters.FillingParameters.RoundMethod;
		Else
			// Продублируем текущий сценарий в сценарий истоник.
			Object.CurrentIndicator = IndicatorList[0].Value;
			If Parameters.Prediction Then
				Object.ScenarioSource = Catalogs.fmBudgetingScenarios.Actual;
				Object.SourceIndicator = "Amount";
			Else
				Object.ScenarioSource = Object.CurScenario;
				Object.SourceIndicator = Object.CurrentIndicator;
			EndIf;
			Object.IncreasePercent = 0;
			Object.SeasonalityPercent = 0;
			Object.IncreaseParametersApplication = "Сначала абсолютное Value";
			Object.Department = Parameters.Department;
			If NOT Parameters.Prediction Then
				Object.RoundMethod = Enums.fmRoundMethods.WithoutRound;
			EndIf;
			Object.PeriodFrom = Object.BeginOfPeriod;
			Object.PeriodTo = ?(CurrentPeriod=PredefinedValue("Enum.fmPlanningPeriod.Year"), AddMonth(Object.BeginOfPeriod, 11), AddMonth(Object.BeginOfPeriod, 2));
			If CurrentPeriodicity=Enums.fmPlanningPeriodicity.Quarter Then
				Object.PeriodTo = BegOfQuarter(Object.PeriodTo);
			EndIf;
			Object.SourcePeriodFrom = ?(CurrentPeriod=PredefinedValue("Enum.fmPlanningPeriod.Year"), AddMonth(Object.PeriodFrom, -12), AddMonth(Object.PeriodFrom, -3));
			Object.SourcePeriodTo = ?(CurrentPeriod=PredefinedValue("Enum.fmPlanningPeriod.Year"), AddMonth(Object.SourcePeriodFrom, 11), AddMonth(Object.SourcePeriodFrom, 2));
			If CurrentPeriodicity=Enums.fmPlanningPeriodicity.Quarter Then
				Object.SourcePeriodTo = BegOfQuarter(Object.SourcePeriodTo);
			EndIf;
			If Parameters.ItemsList.Count()>0 Then
				NewFilter = FilterSettings.Settings.Filter.Items.Add(Type("DataCompositionFilterItem"));
				NewFilter.LeftValue = New DataCompositionField("Item");
				NewFilter.ComparisonType = DataCompositionComparisonType.InList;
				NewFilter.RightValue = Parameters.ItemsList;
			EndIf;
		EndIf;
		Object.RoundMethod = ?(ValueIsFilled(Object.RoundMethod), Object.RoundMethod, fmBudgeting.GetEditFormat(Object.InfoStructure));
			
		FillPeriods();
		If Object.InfoStructure.BudgetTotalType=Enums.fmBudgetTotalType.ByMonthesAndQuaters
		AND Object.CurScenario.PlanningPeriodicity = Enums.fmPlanningPeriodicity.Month
		AND Object.CurScenario.PlanningPeriod = Enums.fmPlanningPeriod.Year
		AND Object.BeginOfPeriod = BegOfQuarter(Object.BeginOfPeriod) Then
			ColumnGroup = True;
			For Each CurPeriod In Periods Do
				If Periods.IndexOf(CurPeriod)%3=0 Then
					NewQuarter = Quarters.Add();
					NewQuarter.Period = CurPeriod.Value;
					NewQuarter.ColumnNumber = 4+Periods.IndexOf(CurPeriod)+Int(Periods.IndexOf(CurPeriod)/3);
				EndIf;
			EndDo;
		EndIf;
		
		FillSourceIndicators();
		
		// Заполним лужебные реквизиты формы для сценариев.
		SourcePeriod = Object.ScenarioSource.PlanningPeriod;
		SourcePeriodicity = Object.ScenarioSource.PlanningPeriodicity;
		
		// Если текущая периодичность планирования месяц, то нельзя выбирать сценарий с периодчностью квартал.
		If CurrentPeriodicity=Enums.fmPlanningPeriodicity.Month Then
			Array = New Array();
			Array.Add(PredefinedValue("Enum.fmPlanningPeriodicity.Month"));
			ParametersArray = New Array();
			ParametersArray.Add(New ChoiceParameter("Filter.PlanningPeriodicity", New FixedArray(Array)));
			Items.ScenarioSource.ChoiceParameters = New FixedArray(ParametersArray);
		EndIf;
		
		// Настроим элементы форм в зависимости от копирования или прогнозирования.
		If CurrentPeriod=PredefinedValue("Enum.fmPlanningPeriod.Quarter") Then
			PeriodPresentation = Format(Object.BeginOfPeriod, "DF='K ""Quarter"" yyyy ""y.""'");
		ElsIf CurrentPeriod=PredefinedValue("Enum.fmPlanningPeriod.Year") Then
			PeriodPresentation = Format(Object.BeginOfPeriod, "DF='yyyy ""y.""'");
		EndIf;
		// Сформируем заголовок
		If Parameters.Prediction Then
			Title = NStr("en='Scenario forecasting <';ru='Прогнозирование сценария <'") + Object.CurScenario + NStr("en='> for period ';ru='> за период '") + PeriodPresentation;
		Else
			Title = NStr("en='Copying scenario <';ru='Копирование сценария <'") + Object.CurScenario + NStr("en='> for period ';ru='> за период '") + PeriodPresentation;
			Items.GroupForecastingPeriod.Visible = False;
			Items.GroupArbitraryFilter.Visible = False;
			Items.ForecastingItem.Visible = False;
			Items.LabelStretch.Visible = True;
			Items.GroupPeriodSetting.Title = NStr("en='Copying period setting';ru='Настройка периода копирования'");
			Items.PeriodFrom.Title = NStr("en='Copying period';ru='Период копирования'");
			//Элементы.ТекущийПоказатель.Заголовок = НСтр("en='Copying indicator';ru='Показатель копирования'");
			Items.FormExecute.Title = NStr("en='Copy';ru='Copy'");
		EndIf;
		
		If Object.OperationType=Enums.fmBudgetOperationTypes.IncomesAndExpenses Then
			Items.ForecastingItem.TypeRestriction = New TypeDescription("CatalogRef.fmIncomesAndExpensesItems");
		Else
			Items.ForecastingItem.TypeRestriction = New TypeDescription("CatalogRef.fmCashflowItems");
		EndIf;
		
		DocumentCurrency = TrimAll(Object.DocumentCurrency);
		
		AvailableReportPeriods = fmReportsServerCall.GetAvailableReportPeriods();
		If CurrentPeriodicity=Enums.fmPlanningPeriodicity.Month Then
			PeriodType=Enums.fmAvailableReportPeriods.Month;
		Else
			PeriodType=Enums.fmAvailableReportPeriods.Quarter;
		EndIf;
		PeriodFrom     = fmReportsClientServer.GetReportPeroidRepresentation(PeriodType, 
		Object.PeriodFrom, Object.PeriodTo, ThisForm);
		PeriodTo     = fmReportsClientServer.GetReportPeroidRepresentation(PeriodType, 
		Object.PeriodTo, Object.PeriodTo, ThisForm);
		SourcePeriodFrom     = fmReportsClientServer.GetReportPeroidRepresentation(PeriodType, 
		Object.SourcePeriodFrom, Object.SourcePeriodTo, ThisForm);
		SourcePeriodTo     = fmReportsClientServer.GetReportPeroidRepresentation(PeriodType, 
		Object.SourcePeriodTo, Object.SourcePeriodTo, ThisForm);
		
	Else
		CloseOnOpen=True;
	EndIf;
	
EndProcedure

&AtClient
Procedure ScenarioSourceOnChange(Item)
	
	ScenarioSourceOnChangeServer();
	
	fmPeriodChoiceClient.FillPeriodList(ThisObject, Items.PeriodFrom, PeriodType, BegOfMonth(Object.PeriodFrom));
	fmPeriodChoiceClient.FillPeriodList(ThisObject, Items.PeriodTo, PeriodType, BegOfMonth(Object.PeriodTo));
	fmPeriodChoiceClient.FillPeriodList(ThisObject, Items.SourcePeriodFrom, PeriodType, BegOfMonth(Object.SourcePeriodFrom));
	fmPeriodChoiceClient.FillPeriodList(ThisObject, Items.SourcePeriodTo, PeriodType, BegOfMonth(Object.SourcePeriodTo));

EndProcedure

&AtServer
Procedure ScenarioSourceOnChangeServer()
	SourcePeriod = Object.ScenarioSource.PlanningPeriod;
	SourcePeriodicity = Object.ScenarioSource.PlanningPeriodicity;
	FillSourceIndicators();
EndProcedure

&AtClient
Procedure DoForecasting(Command)
	// Проверка на кратность периодов.
	PeriodCount = fmBudgetingClientServer.PeriodCount(Object.PeriodFrom, Object.PeriodTo, CurrentPeriodicity);
	InitialPeriodsCount = fmBudgetingClientServer.PeriodCount(Object.SourcePeriodFrom, Object.SourcePeriodTo, CurrentPeriodicity);
	DivisionRemainder = InitialPeriodsCount % PeriodCount;
	If NOT DivisionRemainder=0 Then
		CommonClientServer.MessageToUser(NStr("en='The number of planning periods must be a multiple of the number of original periods.';ru='Количество периодов планирования должно быть кратным количеству исходных периодов!'"));
		Return;
	EndIf;
	// Проверка на сценарий.
	If NOT ValueIsFilled(Object.ScenarioSource) Then
		CommonClientServer.MessageToUser(NStr("en='The ""Source scenario"" is not specified.';ru='Не указан ""Сценарий источник""!'"), , "Object.ScenarioSource");
		Return;
	EndIf;
	// Проверка на подразделение.
	If NOT ValueIsFilled(Object.Department) Then
		CommonClientServer.MessageToUser(NStr("en='The ""Source department"" is not specified.';ru='Не указано ""Подразделение источник""!'"), , "Object.Department");
		Return;
	EndIf;
	DoForecastingServer();
	Items.GroupPages.CurrentPage = Items.GroupResult;
EndProcedure

&AtClient
Procedure Save(Command)
	// Сохраним параметры последнего заполнения.
	FillingParameters = New Structure();
	FillingParameters.Insert("ScenarioSource", Object.ScenarioSource);
	FillingParameters.Insert("IncreasePercent", Object.IncreasePercent);
	FillingParameters.Insert("SeasonalityPercent", Object.SeasonalityPercent);
	FillingParameters.Insert("IncreaseAbsoluteValue", Object.IncreaseAbsoluteValue);
	FillingParameters.Insert("ScenarioSource", Object.ScenarioSource);
	FillingParameters.Insert("CurrentIndicator", Object.CurrentIndicator);
	FillingParameters.Insert("PeriodFrom", Object.PeriodFrom);
	FillingParameters.Insert("PeriodTo", Object.PeriodTo);
	FillingParameters.Insert("SourcePeriodFrom", Object.SourcePeriodFrom);
	FillingParameters.Insert("SourcePeriodTo", Object.SourcePeriodTo);
	FillingParameters.Insert("IncreaseParametersApplication", Object.IncreaseParametersApplication);
	FillingParameters.Insert("IgnorePeriodsWithoutData", Object.IgnorePeriodsWithoutData);
	FillingParameters.Insert("RoundMethod", Object.RoundMethod);
	FillingParameters.Insert("SourceIndicator", Object.SourceIndicator);
	FillingParameters.Insert("ComplexFilter", GetSettingsOfComplexFilter());
	FillingParameters.Insert("ForecastingItem", Object.ForecastingItem);
	FillingParameters.Insert("DepartmentSource", Object.Department);
	ReturnStructure = New Structure("FillingParameters, DataTableAddress, Prediction", FillingParameters, PrepareTable(), Parameters.Prediction);
	Notify("PredictionResult", ReturnStructure, FormOwner);
	Close();
EndProcedure

&AtClient
Procedure PeriodFromOnStartChoiceFromList(Item, StandardProcessing)
	CurPeriodFrom = Object.PeriodFrom;
	fmReportsClient.PeriodStartListChoice(ThisForm, Object.PeriodFrom, Undefined,
		Item, StandardProcessing, "PeriodFrom", Object.BeginOfPeriod, ?(CurrentPeriod=PredefinedValue("Enum.fmPlanningPeriod.Year"), EndOfMonth(AddMonth(Object.BeginOfPeriod, 11)), AddMonth(Object.BeginOfPeriod, 2)));
	// Выполним проверку выбранного значения.
	PeriodCount = fmBudgeting.PeriodCount(Object.PeriodFrom, Object.PeriodTo, CurrentPeriodicity);
	If PeriodCount=-1 Then
		Object.PeriodFrom = CurPeriodFrom;
		PeriodFrom = fmReportsClientServer.GetReportPeroidRepresentation(PeriodType, 
			Object.PeriodFrom, Object.PeriodFrom, ThisForm);
		CommonClientServer.MessageToUser(NStr("en='The start of the planning horizon may not exceed the end of the planning horizon.';ru='Начало периода планирования не может превышать окончание периода планирования!'"));
		Return;
	EndIf;
EndProcedure

&AtClient
Procedure PeriodToOnStartChoiceFromList(Item, StandardProcessing)
	CurPeriodTo = Object.PeriodTo;
	fmReportsClient.PeriodStartListChoice(ThisForm, Object.PeriodTo, Undefined,
		Item, StandardProcessing, "PeriodTo", Object.BeginOfPeriod, ?(CurrentPeriod=PredefinedValue("Enum.fmPlanningPeriod.Year"), EndOfMonth(AddMonth(Object.BeginOfPeriod, 11)), AddMonth(Object.BeginOfPeriod, 2)));
	// Выполним проверку выбранного значения.
	PeriodCount = fmBudgeting.PeriodCount(Object.PeriodFrom, Object.PeriodTo, CurrentPeriodicity);
	If PeriodCount=-1 Then
		Object.PeriodTo = CurPeriodTo;
		PeriodTo     = fmReportsClientServer.GetReportPeroidRepresentation(PeriodType, Object.PeriodTo, Object.PeriodTo, ThisForm);
		CommonClientServer.MessageToUser(NStr("en='The start of the planning horizon may not exceed the end of the planning horizon.';ru='Начало периода планирования не может превышать окончание периода планирования!'"));
		Return;
	EndIf;
EndProcedure

&AtClient
Procedure SourcePeriodFromOnStartChoiceFromList(Item, StandardProcessing)
	CurSourcePeriodFrom = Object.SourcePeriodFrom;
	fmReportsClient.PeriodStartListChoice(ThisForm, Object.SourcePeriodFrom, Undefined,
		Item, StandardProcessing, "SourcePeriodFrom", DATE("00010101"));
EndProcedure

&AtClient
Procedure SourcePeriodToOnStartChoiceFromList(Item, StandardProcessing)
	CurSourcePeriodTo = Object.SourcePeriodTo;
	fmReportsClient.PeriodStartListChoice(ThisForm, Object.SourcePeriodTo, Undefined,
		Item, StandardProcessing, "SourcePeriodTo", DATE("00010101"));
	// Выполним проверку выбранного значения.
	InitialPeriodsCount = fmBudgeting.PeriodCount(Object.SourcePeriodFrom, Object.SourcePeriodTo, CurrentPeriodicity);
	If InitialPeriodsCount=-1 Then
		Object.SourcePeriodTo = CurSourcePeriodTo;
		SourcePeriodTo = fmReportsClientServer.GetReportPeroidRepresentation(PeriodType, 
			Object.SourcePeriodTo, Object.SourcePeriodTo, ThisForm);
		CommonClientServer.MessageToUser(NStr("en='The period start of the planning source may not exceed the end period of the  planning source.';ru='Начало периода источника планирования не может превышать окончание периода источника планирования!'"));
		Return;
	EndIf;
EndProcedure

&AtClient
Procedure BudgetTreeChoice(Item, Region, StandardProcessing)
	If Region.Protection Then
		// Возможно открытие статьи.
		If Region.Left=1 AND Region.Right=1 AND NOT Region.Details=Undefined Then
			Analytics = GetAnalyticsFromDetails(Region.Details, DetailsData);
			If ValueIsFilled(Analytics) Then
				ShowValue(, Analytics);
			EndIf;
		EndIf;
		StandardProcessing = False;
	EndIf;
EndProcedure

&AtServerNoContext
Function GetAnalyticsFromDetails(DetailsID, DetailsData)
	
	// Получение данных расшифровки.
	DetailsDataObject = GetFromTempStorage(DetailsData);
	
	// Получение полей расшифровки для текущей ячейки.
	DetailsFieldValues = DetailsDataObject.Items[DetailsID].GetFields();
	
	// Создание структуры для поиска строки по ячейке в исходной ТЗ и поиск имени ресурса в текущей ячейке.
	For Each DetailsFieldValue In DetailsFieldValues Do
		If DetailsFieldValue.Field="AnalyticsName" AND ValueIsFilled(DetailsFieldValue.Value) Then
			For Each DetailsFieldCurValue In DetailsFieldValues Do
				If DetailsFieldCurValue.Field=DetailsFieldValue.Value
				AND NOT TypeOf(DetailsFieldCurValue.Value)=Type("CatalogRef.fmInfoStructuresSections") Then
					Return DetailsFieldCurValue.Value;
				EndIf;
			EndDo;
		EndIf;
	EndDo;
	
	Return Undefined;
	
EndFunction

&AtClient
Procedure BudgetTreeOnChangeAreaContentEvent(Item, Region)
	ProcessAreaContentChangeAtServer(Region.Details, Region.Value);
EndProcedure

&AtServer
Procedure ProcessAreaContentChangeAtServer(DetailsID, NewValue)
	
	// Получение данных расшифровки.
	DetailsDataObject = GetFromTempStorage(DetailsData);
	
	// Получение полей расшифровки для текущей ячейки.
	DetailsFieldValues = DetailsDataObject.Items[DetailsID].GetFields();
	
	// Создание структуры для поиска строки по ячейке в исходной ТЗ и поиск имени ресурса в текущей ячейке.
	ResourceName = "";
	FS = New Structure(SearchColumnsRow);
	For Each DetailsFieldValue In DetailsFieldValues Do
		If Find(SearchColumnsRow, DetailsFieldValue.Field) Then
			FS[DetailsFieldValue.Field] = DetailsFieldValue.Value;
		EndIf;
		If Find(DetailsFieldValue.Field, "Resource_") Then
			ResourceName = DetailsFieldValue.Field;
		EndIf;
	EndDo;
	
	// Основные параметры лежат в 1-ой колонке, строка должна делиться без остатка на количество ресурсов.
	CurrentArea = Items.BudgetTree.CurrentArea;
	CurTop = DetermineTopCoord(CurrentArea.Top, Resources.Count());
	CurrentArea = BudgetTree.Region(CurTop, 1, CurTop, 1);
	ParametersDetailsFieldValues = DetailsDataObject.Items[CurrentArea.Details].GetFields();
	For Each DetailsFieldValue In ParametersDetailsFieldValues Do
		If Find(SearchColumnsRow, DetailsFieldValue.Field) Then
			FS[DetailsFieldValue.Field] = DetailsFieldValue.Value;
		EndIf;
	EndDo;
	
	// Поиск строки по ячейке в исходной ТЗ.
	InitialDataVT = GetFromTempStorage(InitialDataVTAddress);
	FoundRows = InitialDataVT.FindRows(FS);
	If FoundRows.Count() Then
		FoundRow = FoundRows[0];
		If NOT IsBlankString(ResourceName) Then
			// Установка нового значения.
			FoundRow[ResourceName] = NewValue;
			If Parameters.Prediction Then
				FoundRow.Resource_Delta = NewValue - FoundRow.Resource_InitialAmount;
				BudgetTree.Region(FoundRow.CoordRow_Delta, FoundRow.CoordColumn_Delta).Value = FoundRow.Resource_Delta;
			EndIf;
			ExecutePartialIterationOfBudgetsTree(ResourceName, FoundRow);
		EndIf;
	EndIf;
	InitialDataVTAddress = PutToTempStorage(InitialDataVT, UUID);
	
EndProcedure

&AtClient
Procedure PeriodChoiceProcessingLocal(Item, ChosenValue, StandardProcessing, PeriodType, Period, BeginOfPeriod, EndOfPeriod, Form = Undefined) Export
	
	If NOT Form = Undefined Then
		List = fmPeriodChoiceClientServer.GetPeriodList(BeginOfPeriod, PeriodType);
		If List.Count() = 0 Then
			Return;
		EndIf;
		//сперва проверим, не года ли мы выбрали:
		
		IndexOf = 0;
		For Each ChListIt In List Do
			If ChListIt.Value = ChosenValue Then
				Break;
			EndIf;
			IndexOf = IndexOf + 1;
		EndDo;
		
		If IndexOf = 0 OR IndexOf = List.Count() - 1 Then
			StandardProcessing = False;
			ChooseReportPeriodChoiceProcessingLocal(Form, Item, PeriodType, ChosenValue);
		Else
			If TypeOf(ChosenValue) = Type("DATE") Then
				BeginOfPeriod = fmPeriodChoiceClientServer.ReportBegOfPeriod(PeriodType, ChosenValue);
				EndOfPeriod  = fmPeriodChoiceClientServer.ReportEndOfPeriod(PeriodType, ChosenValue);
				
				ChoosenValueAsDate = ChosenValue;
				
				ChosenValue = fmPeriodChoiceClientServer.GetReportPeroidRepresentation(
					PeriodType, BeginOfPeriod, EndOfPeriod);
					
				If Item.Name = "PeriodFrom" Then
					Object.PeriodFrom = ChoosenValueAsDate;
					PeriodFrom = ChosenValue;
				ElsIf Item.Name = "PeriodTo" Then
					Object.PeriodTo = ChoosenValueAsDate;
					PeriodTo = ChosenValue;
				ElsIf Item.Name = "SourcePeriodFrom" Then
					Object.SourcePeriodFrom = ChoosenValueAsDate;
					SourcePeriodFrom = ChosenValue;
				ElsIf Item.Name = "SourcePeriodTo" Then
					Object.SourcePeriodTo = ChoosenValueAsDate;
					SourcePeriodTo = ChosenValue;
				EndIf;
				StandardProcessing = False;
			EndIf;
			
			fmPeriodChoiceClient.FillPeriodList(Form, Item, PeriodType, BeginOfPeriod);
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure ChooseReportPeriodChoiceProcessingLocal(Form, Item, PeriodType, BeginOfPeriod) 
	
	List = fmPeriodChoiceClientServer.GetPeriodList(BeginOfPeriod, PeriodType);
	If List.Count() = 0 Then
		StandardProcessing = False;
		Return;
	EndIf;
	
	ListItem = List.FindByValue(BeginOfPeriod);
	
	AddPar = New Structure;
	AddPar.Insert("PeriodType", PeriodType);
	AddPar.Insert("Form", Form);
	AddPar.Insert("List", List);
	AddPar.Insert("Item", Item);
	
	NotDesc = New NotifyDescription("ChooseReportPeriodChoiceProcessingLocal_End", ThisObject, AddPar);

	Form.ShowChooseFromList(NotDesc, List, Item, ListItem);
	
EndProcedure

&AtClient
Procedure ChooseReportPeriodChoiceProcessingLocal_End(SelectedPeriod, AddPar) Export
	
	PeriodType = AddPar.PeriodType;
	Form = AddPar.Form;
	List = AddPar.List;
	Item = AddPar.Item;
	
	If SelectedPeriod = Undefined Then
		Return;
	EndIf;
	
	IndexOf = List.IndexOf(SelectedPeriod);
	If IndexOf = 0 OR IndexOf = List.Count() - 1 Then
		ChooseReportPeriodChoiceProcessingLocal(Form, Item, PeriodType, SelectedPeriod.Value);
	EndIf;
	
	ChosenValue = SelectedPeriod.Value;
	
	If TypeOf(ChosenValue) = Type("DATE") Then
		BeginOfPeriod = fmPeriodChoiceClientServer.ReportBegOfPeriod(PeriodType, ChosenValue);
		EndOfPeriod  = fmPeriodChoiceClientServer.ReportEndOfPeriod(PeriodType, ChosenValue);
		
		ChoosenValueAsDate = ChosenValue;
		
		ChosenValue = fmPeriodChoiceClientServer.GetReportPeroidRepresentation(
			PeriodType, BeginOfPeriod, EndOfPeriod);
			
		If Item.Name = "PeriodFrom" Then
			Object.PeriodFrom = ChoosenValueAsDate;
			PeriodFrom = ChosenValue;
		ElsIf Item.Name = "PeriodTo" Then
			Object.PeriodTo = ChoosenValueAsDate;
			PeriodTo = ChosenValue;
		ElsIf Item.Name = "SourcePeriodFrom" Then
			Object.SourcePeriodFrom = ChoosenValueAsDate;
			SourcePeriodFrom = ChosenValue;
		ElsIf Item.Name = "SourcePeriodTo" Then
			Object.SourcePeriodTo = ChoosenValueAsDate;
			SourcePeriodTo = ChosenValue;
		EndIf;
	EndIf;
	
	fmPeriodChoiceClient.FillPeriodList(Form, Item, PeriodType, BeginOfPeriod);
	
EndProcedure

&AtClient
Function SelectReportPeriod(Form, Item, StandardProcessing, PeriodType, BeginOfPeriod)
	
	List = fmPeriodChoiceClientServer.GetPeriodList(BeginOfPeriod, PeriodType);
	If List.Count() = 0 Then
		StandardProcessing = False;
		Return Undefined;
	EndIf;
	
	ListItem = List.FindByValue(BeginOfPeriod);
	SelectedPeriod = Form.ChooseFromList(List, Item, ListItem);
	
	If SelectedPeriod = Undefined Then
		Return Undefined;
	EndIf;
	
	IndexOf = List.IndexOf(SelectedPeriod);
	If IndexOf = 0 OR IndexOf = List.Count() - 1 Then
		SelectedPeriod = SelectReportPeriod(Form, Item, StandardProcessing, PeriodType, SelectedPeriod.Value);
	EndIf;
	
	Return SelectedPeriod;
	
EndFunction

&AtClient
Procedure PeriodFromChoiceProcessing(Item, ChosenValue, StandardProcessing)
	
	PeriodChoiceProcessingLocal(
		Item, ChosenValue, StandardProcessing,
		PeriodType, PeriodFrom, BegOfMonth(Object.PeriodFrom), EndOfMonth(Object.PeriodFrom), ThisObject);
		
	fmPeriodChoiceClient.FillPeriodList(ThisObject, Items.PeriodFrom, PeriodType, BegOfMonth(Object.PeriodFrom));
	
EndProcedure

&AtClient
Procedure PeriodToChoiceProcessing(Item, ChosenValue, StandardProcessing)
	
	PeriodChoiceProcessingLocal(
		Item, ChosenValue, StandardProcessing,
		PeriodType, PeriodTo, BegOfMonth(Object.PeriodTo), EndOfMonth(Object.PeriodTo), ThisObject);
		
	fmPeriodChoiceClient.FillPeriodList(ThisObject, Items.PeriodTo, PeriodType, BegOfMonth(Object.PeriodTo));
	
EndProcedure

&AtClient
Procedure SourcePeriodFromChoiceProcessing(Item, ChosenValue, StandardProcessing)
	
	PeriodChoiceProcessingLocal(
		Item, ChosenValue, StandardProcessing,
		PeriodType, SourcePeriodFrom, BegOfMonth(Object.SourcePeriodFrom), EndOfMonth(Object.SourcePeriodFrom), ThisObject);
		
	fmPeriodChoiceClient.FillPeriodList(ThisObject, Items.SourcePeriodFrom, PeriodType, BegOfMonth(Object.SourcePeriodFrom));
	
EndProcedure

&AtClient
Procedure SourcePeriodToChoiceProcessing(Item, ChosenValue, StandardProcessing)
	
	PeriodChoiceProcessingLocal(
		Item, ChosenValue, StandardProcessing,
		PeriodType, SourcePeriodTo, BegOfMonth(Object.SourcePeriodTo), EndOfMonth(Object.SourcePeriodTo), ThisObject);
		
	fmPeriodChoiceClient.FillPeriodList(ThisObject, Items.SourcePeriodTo, PeriodType, BegOfMonth(Object.SourcePeriodTo));
	
EndProcedure








