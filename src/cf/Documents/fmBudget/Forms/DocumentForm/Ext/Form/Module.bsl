
////////////////////////////////////////////////////////////////////////////////
// ОБЩИЕ ПРОЦЕДУРЫ И ФУНКЦИИ

&AtServer
// Процедура формирования дерева бюджета.
// 
Procedure FillBudgetTree()
	
	BudgetTree.Clear();
	
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
	                      |	BudgetsData.Analytics1 AS Analytics1,
	                      |	BudgetsData.Analytics2 AS Analytics2,
	                      |	BudgetsData.Analytics3 AS Analytics3,
	                      |	BudgetsData.RecordType AS RecordType,
	                      |	BudgetsData.LineNumber AS LineNumber,
	                      |	BudgetsData.VersionPeriod AS VersionPeriod,
	                      |	CAST(BudgetsData.Comment AS String(1024)) AS Comment
	                      |INTO TTBudgetsData
	                      |FROM
	                      |	&BudgetsData AS BudgetsData");
	Query.TempTablesManager = New TempTablesManager;
	Query.SetParameter("BudgetsData", Object.BudgetsData.Unload());
	Query.SetParameter("RoundMethod", ?(ValueIsFilled(StructureInputFormat), StructureInputFormat, ConstantInputFormat));
	Query.Execute();
		
	Query.Text = "SELECT
	               |	TTBudgetsData.RecordType AS RecordType,
	               |	TTBudgetsData.Item AS Item,
	               |	TTBudgetsData.Period AS Period,
	               |	TTBudgetsData.VersionPeriod AS VersionPeriod,
	               |	TTBudgetsData.Analytics1 AS Analytics1,
	               |	TTBudgetsData.Analytics2 AS Analytics2,
	               |	TTBudgetsData.Analytics3 AS Analytics3,
	               |	TTBudgetsData.Comment AS Comment
	               |INTO CommentsVT
	               |FROM
	               |	TTBudgetsData AS TTBudgetsData
	               |WHERE
	               |	TTBudgetsData.VersionPeriod <= &CurrentVersion
	               |	AND TTBudgetsData.Comment <> """"
	               |;
	               |
	               |////////////////////////////////////////////////////////////////////////////////
	               |SELECT
	               |	CommentsTable.RecordType AS RecordType,
	               |	CommentsTable.Item AS Item,
	               |	CommentsTable.Period AS Period,
	               |	MAX(CommentsTable.VersionPeriod) AS VersionPeriod,
	               |	CommentsTable.Analytics1 AS Analytics1,
	               |	CommentsTable.Analytics2 AS Analytics2,
	               |	CommentsTable.Analytics3 AS Analytics3
	               |INTO CommentsVersionsTable
	               |FROM
	               |	CommentsVT AS CommentsTable
	               |
	               |GROUP BY
	               |	CommentsTable.Item,
	               |	CommentsTable.Analytics1,
	               |	CommentsTable.Analytics2,
	               |	CommentsTable.Analytics3,
	               |	CommentsTable.Period,
	               |	CommentsTable.RecordType
	               |;
	               |
	               |////////////////////////////////////////////////////////////////////////////////
	               |SELECT
	               |	CommentsTable.RecordType AS RecordType,
	               |	CommentsTable.Item AS Item,
	               |	CommentsTable.Period AS Period,
	               |	CommentsTable.Analytics1 AS Analytics1,
	               |	CommentsTable.Analytics2 AS Analytics2,
	               |	CommentsTable.Analytics3 AS Analytics3,
	               |	CommentsTable.Comment AS Comment,
	               |	CommentsTable.VersionPeriod AS CommentVersion
	               |INTO CommentsTable
	               |FROM
	               |	CommentsVersionsTable AS CommentsVersionsTable
	               |		LEFT JOIN CommentsVT AS CommentsTable
	               |		ON CommentsVersionsTable.RecordType = CommentsTable.RecordType
	               |			AND CommentsVersionsTable.Item = CommentsTable.Item
	               |			AND CommentsVersionsTable.Period = CommentsTable.Period
	               |			AND CommentsVersionsTable.VersionPeriod = CommentsTable.VersionPeriod
	               |			AND CommentsVersionsTable.Analytics1 = CommentsTable.Analytics1
	               |			AND CommentsVersionsTable.Analytics2 = CommentsTable.Analytics2
	               |			AND CommentsVersionsTable.Analytics3 = CommentsTable.Analytics3
	               |;
	               |
	               |////////////////////////////////////////////////////////////////////////////////
	               |DROP CommentsVT
	               |;
	               |
	               |////////////////////////////////////////////////////////////////////////////////
	               |DROP CommentsVersionsTable
	               |;
	               |
	               |////////////////////////////////////////////////////////////////////////////////
	               |SELECT
	               |	TTBudgetsData.RecordType AS RecordType,
	               |	TTBudgetsData.Item AS Item,
	               |	TTBudgetsData.Period AS Period,
	               |	MIN(TTBudgetsData.LineNumber) AS LineNumber,
	               |	SUM(TTBudgetsData.Amount) AS Amount,
	               |	TTBudgetsData.Analytics1 AS Analytics1,
	               |	TTBudgetsData.Analytics2 AS Analytics2,
	               |	TTBudgetsData.Analytics3 AS Analytics3
	               |INTO TTCollapsedBudgetDataWithBlankValues
	               |FROM
	               |	TTBudgetsData AS TTBudgetsData
	               |WHERE
	               |	TTBudgetsData.VersionPeriod <= &CurrentVersion
	               |
	               |GROUP BY
	               |	TTBudgetsData.Analytics1,
	               |	TTBudgetsData.Analytics2,
	               |	TTBudgetsData.Analytics3,
	               |	TTBudgetsData.RecordType,
	               |	TTBudgetsData.Item,
	               |	TTBudgetsData.Period
	               |;
	               |
	               |////////////////////////////////////////////////////////////////////////////////
	               |DROP TTBudgetsData
	               |;
	               |
	               |////////////////////////////////////////////////////////////////////////////////
	               |SELECT
	               |	TTCollapsedBudgetDataWithBlankValues.RecordType AS RecordType,
	               |	TTCollapsedBudgetDataWithBlankValues.Item AS Item,
	               |	TTCollapsedBudgetDataWithBlankValues.Period AS Period,
	               |	TTCollapsedBudgetDataWithBlankValues.Amount AS Amount,
	               |	TTCollapsedBudgetDataWithBlankValues.LineNumber AS LineNumber,
	               |	TTCollapsedBudgetDataWithBlankValues.Analytics1 AS Analytics1,
	               |	TTCollapsedBudgetDataWithBlankValues.Analytics2 AS Analytics2,
	               |	TTCollapsedBudgetDataWithBlankValues.Analytics3 AS Analytics3
	               |INTO TTCollapsedBudgetData
	               |FROM
	               |	TTCollapsedBudgetDataWithBlankValues AS TTCollapsedBudgetDataWithBlankValues
	               |WHERE
	               |	TTCollapsedBudgetDataWithBlankValues.Amount <> 0
	               |;
	               |
	               |////////////////////////////////////////////////////////////////////////////////
	               |DROP TTCollapsedBudgetDataWithBlankValues
	               |;
	               |
	               |////////////////////////////////////////////////////////////////////////////////
	               |SELECT
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
	               |	AND NOT SectionStructureData.Analytics REFS Catalog.fmItemGroups
	               |	AND SectionStructureData.Ref.StructureSectionType <> VALUE(Enum.fmBudgetFlowOperationTypes.EmptyRef)
	               |	AND NOT SectionStructureData.Ref.DeletionMark
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
	               |	AND SectionStructureData.Ref.StructureSectionType <> VALUE(Enum.fmBudgetFlowOperationTypes.EmptyRef)
	               |	AND SectionStructureData.Analytics REFS Catalog.fmItemGroups
	               |	AND NOT SectionStructureData.Ref.DeletionMark
	               |;
	               |
	               |////////////////////////////////////////////////////////////////////////////////
	               |SELECT
	               |	Structure.Ref AS Section,
	               |	Structure.Parent AS SectionParent,
	               |	CASE
	               |		WHEN Structure.ByFormula
	               |			THEN UNDEFINED
	               |		ELSE ISNULL(StructureIndicators.Analytics, UNDEFINED)
	               |	END AS Analytics,
	               |	ISNULL(StructureIndicators.Analytics1, UNDEFINED) AS Analytics1,
	               |	ISNULL(StructureIndicators.Analytics2, UNDEFINED) AS Analytics2,
	               |	ISNULL(StructureIndicators.Analytics3, UNDEFINED) AS Analytics3,
	               |	Structure.Order AS Order,
	               |	StructureIndicators.Order AS AnalyticsOrder,
	               |	Structure.ItalicFont AS ItalicFont,
	               |	CAST(Structure.TextColor AS STRING(1024)) AS TextColor,
	               |	Structure.BoldFont AS BoldFont
	               |INTO TT_Structure
	               |FROM
	               |	Catalog.fmInfoStructuresSections AS Structure
	               |		LEFT JOIN TTItemGrouping AS StructureIndicators
	               |		ON Structure.Ref = StructureIndicators.Ref
	               |WHERE
	               |	Structure.Owner = &Owner
	               |	AND Structure.StructureSectionType <> VALUE(Enum.fmBudgetFlowOperationTypes.EmptyRef)
	               |	AND NOT Structure.DeletionMark
	               |
	               |GROUP BY
	               |	Structure.Ref,
	               |	Structure.Parent,
	               |	CASE
	               |		WHEN Structure.ByFormula
	               |			THEN UNDEFINED
	               |		ELSE ISNULL(StructureIndicators.Analytics, UNDEFINED)
	               |	END,
	               |	ISNULL(StructureIndicators.Analytics1, UNDEFINED),
	               |	ISNULL(StructureIndicators.Analytics2, UNDEFINED),
	               |	ISNULL(StructureIndicators.Analytics3, UNDEFINED),
	               |	Structure.Order,
	               |	StructureIndicators.Order,
	               |	CAST(Structure.TextColor AS STRING(1024)),
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
	               |	CAST(Structure.TextColor AS STRING(1024)) AS TextColor,
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
	               |			THEN 0
	               |		ELSE TTCollapsedBudgetData.Amount
	               |	END AS Resource_Amount,
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
	               |	ISNULL(TT_OutOfStructureData.Item, UNDEFINED) AS Analytics,
	               |	ISNULL(TT_OutOfStructureData.Analytics1, UNDEFINED) AS Analytics1,
	               |	ISNULL(TT_OutOfStructureData.Analytics2, UNDEFINED) AS Analytics2,
	               |	ISNULL(TT_OutOfStructureData.Analytics3, UNDEFINED) AS Analytics3,
	               |	TT_OutOfStructureWithPeriods.Order AS Order,
	               |	ISNULL(TT_OutOfStructureData.LineNumber, 0) AS AnalyticsOrder,
	               |	TT_OutOfStructureWithPeriods.Period AS Period,
	               |	SUM(ISNULL(TT_OutOfStructureData.Resource_Amount, 0)) AS Resource_Amount,
	               |	TT_OutOfStructureWithPeriods.TextColor AS TextColor,
	               |	TT_OutOfStructureWithPeriods.ItalicFont AS ItalicFont,
	               |	TT_OutOfStructureWithPeriods.BoldFont AS BoldFont,
	               |	CASE
	               |		WHEN ISNULL(TT_OutOfStructureData.Resource_Amount, UNDEFINED) = UNDEFINED
	               |			THEN FALSE
	               |		ELSE TRUE
	               |	END AS Edit
	               |INTO TT_OutOfStructureDataByStructure
	               |FROM
	               |	TT_OutOfStructureWithPeriods AS TT_OutOfStructureWithPeriods
	               |		LEFT JOIN TT_OutOfStructureData AS TT_OutOfStructureData
	               |		ON (TT_OutOfStructureData.RecordType = TT_OutOfStructureWithPeriods.OperationType)
	               |			AND (TT_OutOfStructureData.Period = TT_OutOfStructureWithPeriods.Period)
	               |
	               |GROUP BY
	               |	TT_OutOfStructureWithPeriods.Section,
	               |	TT_OutOfStructureWithPeriods.SectionParent,
	               |	ISNULL(TT_OutOfStructureData.Item, UNDEFINED),
	               |	ISNULL(TT_OutOfStructureData.Analytics1, UNDEFINED),
	               |	ISNULL(TT_OutOfStructureData.Analytics2, UNDEFINED),
	               |	ISNULL(TT_OutOfStructureData.Analytics3, UNDEFINED),
	               |	TT_OutOfStructureWithPeriods.Order,
	               |	ISNULL(TT_OutOfStructureData.LineNumber, 0),
	               |	TT_OutOfStructureWithPeriods.Period,
	               |	TT_OutOfStructureWithPeriods.ItalicFont,
	               |	TT_OutOfStructureWithPeriods.TextColor,
	               |	TT_OutOfStructureWithPeriods.BoldFont,
	               |	CASE
	               |		WHEN ISNULL(TT_OutOfStructureData.Resource_Amount, UNDEFINED) = UNDEFINED
	               |			THEN FALSE
	               |		ELSE TRUE
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
	               |	TT_StructureWithPeriods.Italic AS Italic,
	               |	TT_StructureWithPeriods.TextColor AS TextColor,
	               |	TT_StructureWithPeriods.Bold AS Bold,
	               |	TT_StructureWithPeriods.Section.StructureSectionType AS RecordType,
	               |	CASE
	               |		WHEN TT_StructureWithPeriods.Analytics = UNDEFINED
	               |			THEN FALSE
	               |		ELSE TRUE
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
	               |			THEN 0
	               |		ELSE TTCollapsedBudgetData.Amount
	               |	END,
	               |	TT_StructureWithPeriods.Italic,
	               |	TT_StructureWithPeriods.TextColor,
	               |	TT_StructureWithPeriods.Bold,
	               |	TT_StructureWithPeriods.Section.StructureSectionType,
	               |	TRUE
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
	               |GROUP BY
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
	               |			THEN 0
	               |		ELSE TTCollapsedBudgetData.Amount
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
	               |	TTDataTableWithoutGrouping.Italic AS Italic,
	               |	TTDataTableWithoutGrouping.TextColor AS TextColor,
	               |	TTDataTableWithoutGrouping.Bold AS Bold,
	               |	TTDataTableWithoutGrouping.Edit AS Edit,
	               |	TTDataTableWithoutGrouping.RecordType AS RecordType,
	               |	ISNULL(CommentsTable.Comment, """") AS Comment
	               |INTO TTDataTableNotCollapsed
	               |FROM
	               |	TTDataTableWithoutGrouping AS TTDataTableWithoutGrouping
	               |		LEFT JOIN CommentsTable AS CommentsTable
	               |		ON TTDataTableWithoutGrouping.RecordType = CommentsTable.RecordType
	               |			AND TTDataTableWithoutGrouping.Analytics = CommentsTable.Item
	               |			AND TTDataTableWithoutGrouping.Period = CommentsTable.Period
	               |			AND TTDataTableWithoutGrouping.Analytics1 = CommentsTable.Analytics1
	               |			AND TTDataTableWithoutGrouping.Analytics2 = CommentsTable.Analytics2
	               |			AND TTDataTableWithoutGrouping.Analytics3 = CommentsTable.Analytics3
	               |
	               |GROUP BY
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
	               |	TTDataTableWithoutGrouping.Italic,
	               |	TTDataTableWithoutGrouping.TextColor,
	               |	TTDataTableWithoutGrouping.Bold,
	               |	TTDataTableWithoutGrouping.Edit,
	               |	TTDataTableWithoutGrouping.RecordType,
	               |	CommentsTable.Comment
	               |
	               |UNION ALL
	               |
	               |SELECT
	               |	TTDataTableWithoutGrouping.Section,
	               |	TTDataTableWithoutGrouping.SectionParent,
	               |	UNDEFINED,
	               |	UNDEFINED,
	               |	UNDEFINED,
	               |	UNDEFINED,
	               |	TTDataTableWithoutGrouping.Order,
	               |	TTDataTableWithoutGrouping.AnalyticsOrder,
	               |	TTDataTableWithoutGrouping.Period,
	               |	0,
	               |	TTDataTableWithoutGrouping.Italic,
	               |	TTDataTableWithoutGrouping.TextColor,
	               |	TTDataTableWithoutGrouping.Bold,
	               |	FALSE,
	               |	TTDataTableWithoutGrouping.Section.StructureSectionType,
	               |	""""
	               |FROM
	               |	TTDataTableWithoutGrouping AS TTDataTableWithoutGrouping
	               |WHERE
	               |	TTDataTableWithoutGrouping.Analytics <> UNDEFINED
	               |
	               |GROUP BY
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
	               |	UNDEFINED,
	               |	UNDEFINED,
	               |	UNDEFINED,
	               |	TTDataTableWithoutGrouping.Order,
	               |	TTDataTableWithoutGrouping.AnalyticsOrder,
	               |	TTDataTableWithoutGrouping.Period,
	               |	0,
	               |	TTDataTableWithoutGrouping.Italic,
	               |	TTDataTableWithoutGrouping.TextColor,
	               |	TTDataTableWithoutGrouping.Bold,
	               |	FALSE,
	               |	TTDataTableWithoutGrouping.Section.StructureSectionType,
	               |	""""
	               |FROM
	               |	TTDataTableWithoutGrouping AS TTDataTableWithoutGrouping
	               |WHERE
	               |	TTDataTableWithoutGrouping.Analytics1 <> UNDEFINED
	               |
	               |GROUP BY
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
	               |	UNDEFINED,
	               |	UNDEFINED,
	               |	TTDataTableWithoutGrouping.Order,
	               |	TTDataTableWithoutGrouping.AnalyticsOrder,
	               |	TTDataTableWithoutGrouping.Period,
	               |	0,
	               |	TTDataTableWithoutGrouping.Italic,
	               |	TTDataTableWithoutGrouping.TextColor,
	               |	TTDataTableWithoutGrouping.Bold,
	               |	FALSE,
	               |	TTDataTableWithoutGrouping.Section.StructureSectionType,
	               |	""""
	               |FROM
	               |	TTDataTableWithoutGrouping AS TTDataTableWithoutGrouping
	               |WHERE
	               |	TTDataTableWithoutGrouping.Analytics2 <> UNDEFINED
	               |
	               |GROUP BY
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
	               |	UNDEFINED,
	               |	TTDataTableWithoutGrouping.Order,
	               |	TTDataTableWithoutGrouping.AnalyticsOrder,
	               |	TTDataTableWithoutGrouping.Period,
	               |	0,
	               |	TTDataTableWithoutGrouping.Italic,
	               |	TTDataTableWithoutGrouping.TextColor,
	               |	TTDataTableWithoutGrouping.Bold,
	               |	FALSE,
	               |	TTDataTableWithoutGrouping.Section.StructureSectionType,
	               |	""""
	               |FROM
	               |	TTDataTableWithoutGrouping AS TTDataTableWithoutGrouping
	               |WHERE
	               |	TTDataTableWithoutGrouping.Analytics3 <> UNDEFINED
	               |
	               |GROUP BY
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
	               |DROP CommentsTable
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
	               |	MIN(TTDataTableNotCollapsed.AnalyticsOrder) AS AnalyticsOrder,
	               |	TTDataTableNotCollapsed.Period AS Period,
	               |	SUM(TTDataTableNotCollapsed.Resource_Amount) AS Resource_Amount,
	               |	TTDataTableNotCollapsed.Italic AS Italic,
	               |	TTDataTableNotCollapsed.TextColor AS TextColor,
	               |	TTDataTableNotCollapsed.Bold AS Bold,
	               |	MIN(TTDataTableNotCollapsed.Edit) AS Edit,
	               |	TTDataTableNotCollapsed.RecordType AS RecordType,
	               |	TTDataTableNotCollapsed.Comment AS Comment
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
	               |	TTDataTableNotCollapsed.Order,
	               |	TTDataTableNotCollapsed.Comment
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
	               |	MIN(DataTableTT.AnalyticsOrder) AS AnalyticsOrder
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
		Query.SetParameter("OutOfStructure"				, ?(ValueIsFilled(Object.InfoStructure), Catalogs.fmInfoStructures.OutOfStructureCF, Catalogs.fmInfoStructures.WithoutStructureCF));
	EndIf;
	Query.SetParameter("BeginOfPlanningPeriod"	, Object.BeginOfPeriod);
	Query.SetParameter("Department"				, Object.Department);
	Query.SetParameter("CurrentVersion"		, CurrentVersion);
	If NOT ValueIsFilled(CurrentVersion) Then
		Query.Text = StrReplace(Query.Text, "<=", ">=");
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
	MaximumRowID = RowID;
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
	               |	TTHierarchyVTID.RowID AS RowID,
	               |	DataTableTT.Comment AS Comment
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
	               |	DataTableTT.Bold
	               |;
	               |
	               |////////////////////////////////////////////////////////////////////////////////
	               |DROP DataTableTT";
	
	Result = Query.ExecuteBatch();
	DataVT = Result[2].Unload();
	HierarchyVT = Result[3].Unload();
	VTConditionalAppearance = Result[5].Unload();
	
	DetailsDataObject = Undefined;
	DCSchema				= Documents.fmBudget.GetTemplate("TreeDCS");
	
	DCSettings		= DCSchema.DefaultSettings;
	If ColumnGroup Then
		DCSettings.Structure[0].Columns[0].Use = True;
	Else
		DCSettings.Structure[0].Columns[1].Use = True;
		If Object.Scenario.PlanningPeriodicity = Enums.fmPlanningPeriodicity.Quarter Then
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
	
	TemporaryModule.BudgetTreeIteration(BudgetTree, InitialDataVTAddress, UUID, DetailsDataObject, SearchColumnsRow, ViewFormat, EditFormat, Resources.Count(), New Color(251, 245, 158));
	
	// Для дальнейшего получения вертикальных и горизонтальных итогов сформируем таблицу.
	GenerateEdgeTable();
	ExecuteFullIterationOfBudgetTree();
	
EndProcedure // ЗаполнитьДеревоБюджетов()

&AtServer
// Процедура формирования дерева бюджета.
// 
Procedure FillInnerSettlements()
	
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
	                      |	BudgetsData.Analytics1 AS Analytics1,
	                      |	BudgetsData.Analytics2 AS Analytics2,
	                      |	BudgetsData.Analytics3 AS Analytics3,
	                      |	BudgetsData.CorDepartment AS CorDepartment,
	                      |	BudgetsData.LineNumber AS LineNumber,
	                      |	BudgetsData.VersionPeriod AS VersionPeriod
	                      |INTO TTBudgetsData
	                      |FROM
	                      |	&BudgetsData AS BudgetsData");
	Query.TempTablesManager = New TempTablesManager;
	Query.SetParameter("BudgetsData", Object.BudgetsData.Unload());
	Query.SetParameter("RoundMethod", ConstantInputFormat);
	Query.Execute();
	
	Query.Text = "SELECT
	               |	TTBudgetsData.Item AS Item,
	               |	TTBudgetsData.Period AS Period,
	               |	MIN(TTBudgetsData.LineNumber) AS LineNumber,
	               |	SUM(TTBudgetsData.Amount) AS Amount,
	               |	TTBudgetsData.Analytics1 AS Analytics1,
	               |	TTBudgetsData.Analytics2 AS Analytics2,
	               |	TTBudgetsData.Analytics3 AS Analytics3,
	               |	TTBudgetsData.CorDepartment AS CorDepartment
	               |INTO TTBudgetsDataCollapsed
	               |FROM
	               |	TTBudgetsData AS TTBudgetsData
	               |WHERE
	               |	TTBudgetsData.VersionPeriod <= &CurrentVersion
	               |
	               |Group By
	               |	TTBudgetsData.Analytics1,
	               |	TTBudgetsData.Analytics2,
	               |	TTBudgetsData.Analytics3,
	               |	TTBudgetsData.CorDepartment,
	               |	TTBudgetsData.Item,
	               |	TTBudgetsData.Period
	               |;
	               |
	               |////////////////////////////////////////////////////////////////////////////////
	               |DROP TTBudgetsData
	               |;
	               |
	               |////////////////////////////////////////////////////////////////////////////////
	               |SELECT
	               |	TTBudgetsDataCollapsed.Item AS Item,
	               |	TTBudgetsDataCollapsed.Period AS Period,
	               |	TTBudgetsDataCollapsed.LineNumber AS LineNumber,
	               |	TTBudgetsDataCollapsed.Amount AS Amount,
	               |	TTBudgetsDataCollapsed.Analytics1 AS Analytics1,
	               |	TTBudgetsDataCollapsed.Analytics2 AS Analytics2,
	               |	TTBudgetsDataCollapsed.Analytics3 AS Analytics3,
	               |	TTBudgetsDataCollapsed.CorDepartment AS CorDepartment,
	               |	fmIncomesAndExpensesItems.AnalyticsType1.ValueType AS AnalyticsType1,
	               |	fmIncomesAndExpensesItems.AnalyticsType2.ValueType AS AnalyticsType2,
	               |	fmIncomesAndExpensesItems.AnalyticsType3.ValueType AS AnalyticsType3,
	               |	fmIncomesAndExpensesItems.AnalyticsType1 <> VALUE(ChartOfCharacteristicTypes.fmAnalyticsTypes.EmptyRef) AS AnalyticsType1Filled,
	               |	fmIncomesAndExpensesItems.AnalyticsType2 <> VALUE(ChartOfCharacteristicTypes.fmAnalyticsTypes.EmptyRef) AS AnalyticsType2Filled,
	               |	fmIncomesAndExpensesItems.AnalyticsType3 <> VALUE(ChartOfCharacteristicTypes.fmAnalyticsTypes.EmptyRef) AS AnalyticsType3Filled
	               |FROM
	               |	TTBudgetsDataCollapsed AS TTBudgetsDataCollapsed
	               |		LEFT JOIN Catalog.fmIncomesAndExpensesItems AS fmIncomesAndExpensesItems
	               |		ON TTBudgetsDataCollapsed.Item = fmIncomesAndExpensesItems.Ref
	               |WHERE
	               |	TTBudgetsDataCollapsed.Amount <> 0
	               |;
	               |
	               |////////////////////////////////////////////////////////////////////////////////
	               |DROP TTBudgetsDataCollapsed";
	Query.SetParameter("CurrentVersion", CurrentVersion);
	If NOT ValueIsFilled(CurrentVersion) Then
		Query.Text = StrReplace(Query.Text, "<=", ">=");
	EndIf;
	InternalSettlements.Load(Query.Execute().Unload());
	
EndProcedure

&AtServer
Procedure FillData(CurrentObject)
	
	// Определим КорБалансоваяЕдиница по КорПодразделениям.
	Query = New Query("SELECT ALLOWED
	|	DepartmentsStateSliceLast.Department AS Department,
	|	DepartmentsStateSliceLast.BalanceUnit AS BalanceUnit,
	|	&FillData AS Period
	|FROM
	|	InformationRegister.fmDepartmentsState.SliceLast(&FillData, Department IN (&Departments)) AS DepartmentsStateSliceLast
	|
	|UNION ALL
	|
	|SELECT
	|	DepartmentsState.Department,
	|	DepartmentsState.BalanceUnit,
	|	DepartmentsState.Period
	|FROM
	|	InformationRegister.fmDepartmentsState AS DepartmentsState
	|WHERE
	|	DepartmentsState.Period > &FillData
	|	AND DepartmentsState.Department IN(&Departments)
	|	AND DepartmentsState.Period <= &DepartmentsHistoryBoundary
	|
	|ORDER BY
	|	Department,
	|	Period");
	Departments = InternalSettlements.Unload().UnloadColumn("CorDepartment");
	fmCommonUseServerCall.DeleteDuplicatedArrayItems(Departments);
	Query.SetParameter("Departments", Departments);
	Query.SetParameter("FillData", Object.BeginOfPeriod);
	Query.SetParameter("DepartmentsHistoryBoundary", Periods[Periods.Count()-1].Value);
	MapDepartmentsBalanceUnit = Query.Execute().Unload();
	RowSearchStructure = New Structure("Department");
	
	If ScenarioType=Enums.fmBudgetingScenarioTypes.Plan 
	AND (BudgetVersioning=Enums.fmBudgetVersioning.EveryDay
	OR BudgetVersioning=Enums.fmBudgetVersioning.EveryMonth) Then
		
		// Сделаем копию и инвертируем знак для дальнейшего сворачивания.
		BudgetsData = CurrentObject.BudgetsData.Unload();
		ActualCommentsTable = BudgetsData.CopyColumns("Period, VersionPeriod, CorDepartment, CorBalanceUnit, RecordType, Item, Analytics1, Analytics2, Analytics3, Comment");

		// Для плана используем версионирование при необходимости.
		For Each CurRow In BudgetsData Do
			For Each CurResourceName In Resources Do
				CurRow[CurResourceName.Value] = -CurRow[CurResourceName.Value];
			EndDo;
		EndDo;
		
		If Object.OperationType=Enums.fmBudgetOperationTypes.InternalSettlements Then
			// Обход счетов.
			For Each CurRowInitial In InternalSettlements Do
				NewRowPlan = BudgetsData.Add();
				NewRowPlan.Period = CurRowInitial.Period;
				NewRowPlan.Item = CurRowInitial.Item;
				NewRowPlan.CorDepartment = CurRowInitial.CorDepartment;
				NewRowPlan.Analytics1 = CurRowInitial.Analytics1;
				NewRowPlan.Analytics2 = CurRowInitial.Analytics2;
				NewRowPlan.Analytics3 = CurRowInitial.Analytics3;
				For Each CurResourceName In Resources Do
					NewRowPlan[CurResourceName.Value] = fmBudgeting.TransformNumber(CurRowInitial[CurResourceName.Value], "", ConstantInputFormat, False);
				EndDo;
			EndDo;
		Else
			// Обход Исходной ТЗ
			InitialDataVT = GetFromTempStorage(InitialDataVTAddress);
			For Each CurRowInitial In InitialDataVT Do
				// Если Редактирование - то мы находимся в "листе" дерева. 
				// Именно он и является элементом с данными, а не с итогами по группировкам или по формуле.
				If CurRowInitial.Edit Then
					NewRowPlan = BudgetsData.Add();
					NewRowPlan.Period = CurRowInitial.Period;
					NewRowPlan.RecordType = CurRowInitial.RecordType;
					NewRowPlan.Item = CurRowInitial.Analytics;
					NewRowPlan.Analytics1 = CurRowInitial.Analytics1;
					NewRowPlan.Analytics2 = CurRowInitial.Analytics2;
					NewRowPlan.Analytics3 = CurRowInitial.Analytics3;
					For Each CurResourceName In Resources Do
						NewRowPlan[CurResourceName.Value] = fmBudgeting.TransformNumber(CurRowInitial["Resource_"+CurResourceName.Value], StructureInputFormat, ConstantInputFormat, False);
					EndDo;
					If ValueIsFilled(CurRowInitial.Comment)
						AND CurRowInitial.CommentVersion = Object.ActualVersion Then
						NRow = ActualCommentsTable.Add();
						NRow.Period = CurRowInitial.Period;
						NRow.VersionPeriod = Object.ActualVersion;
						NRow.RecordType = CurRowInitial.RecordType;
						NRow.Item = CurRowInitial.Analytics;
						NRow.Analytics1 = CurRowInitial.Analytics1;
						NRow.Analytics2 = CurRowInitial.Analytics2;
						NRow.Analytics3 = CurRowInitial.Analytics3;
						NRow.Comment = CurRowInitial.Comment;
					EndIf;	
				EndIf;
			EndDo;
		EndIf;
		
		// Свернем данные для определения разницы.
		SumColumns = "";
		For Each CurResourceName In Resources Do
			SumColumns = SumColumns + CurResourceName.Value + ", ";
		EndDo;
		SumColumns = Left(SumColumns, StrLen(SumColumns)-2);
		BudgetsData.GroupBy("Period, RecordType, Item, Analytics1, Analytics2, Analytics3, CorDepartment", SumColumns);
		TempBudgetsData = CurrentObject.BudgetsData.Unload();
		For Each CurRow In BudgetsData Do
			
			// Проверяем, есть ли какие-то данные.
			IsData = False;
			For Each CurResourceName In Resources Do
				If CurRow[CurResourceName.Value] <> 0 Then
					IsData = True;
					Break;
				EndIf;
			EndDo;
			
			// Если есть данные, то переносим их в выходную таблицу.
			If IsData Then
				NewLine = TempBudgetsData.Add();
				FillPropertyValues(NewLine, CurRow);
				NewLine.VersionPeriod = Object.ActualVersion;
				// Заполненеие реквизита КорБалансоваяЕдиница.
				RowSearchStructure.Department = CurRow.CorDepartment;
				MapRows = MapDepartmentsBalanceUnit.FindRows(RowSearchStructure);
				For Each MapRow In MapRows Do
					If MapRow.Period <= NewLine.Period Then
						NewLine.CorBalanceUnit = MapRow.BalanceUnit;
					Else
						Break;
					EndIf;
				EndDo;
			EndIf;
			
		EndDo;
		
		//добавим комментарий
		QueryWithCommnts = New Query;
		QueryWithCommnts.TempTablesManager = New TempTablesManager;
		QueryWithCommnts.SetParameter("VTOfBudgetsData",TempBudgetsData);
		QueryWithCommnts.SetParameter("VTOfActualComments",ActualCommentsTable);
		QueryWithCommnts.SetParameter("VTOfDocumentComments",CurrentObject.BudgetsData.Unload());
		
		QueryWithCommnts.Text = "SELECT
		                             |	VT.Item AS Item,
		                             |	VT.Period AS Period,
		                             |	VT.RecordType AS RecordType,
		                             |	VT.CorDepartment AS CorDepartment,
		                             |	VT.CorBalanceUnit AS CorBalanceUnit,
		                             |	VT.VersionPeriod AS VersionPeriod,
		                             |	VT.Analytics1 AS Analytics1,
		                             |	VT.Analytics2 AS Analytics2,
		                             |	VT.Analytics3 AS Analytics3,
		                             |	VT.Amount AS Amount
		                             |INTO ttBudgetsDataNotRolled
		                             |FROM
		                             |	&VTOfBudgetsData AS VT
		                             |;
		                             |
		                             |////////////////////////////////////////////////////////////////////////////////
		                             |SELECT
		                             |	ttBudgetsDataNotRolled.Item AS Item,
		                             |	ttBudgetsDataNotRolled.Period AS Period,
		                             |	ttBudgetsDataNotRolled.RecordType AS RecordType,
		                             |	ttBudgetsDataNotRolled.CorDepartment AS CorDepartment,
		                             |	ttBudgetsDataNotRolled.CorBalanceUnit AS CorBalanceUnit,
		                             |	ttBudgetsDataNotRolled.VersionPeriod AS VersionPeriod,
		                             |	ttBudgetsDataNotRolled.Analytics1 AS Analytics1,
		                             |	ttBudgetsDataNotRolled.Analytics2 AS Analytics2,
		                             |	ttBudgetsDataNotRolled.Analytics3 AS Analytics3,
		                             |	SUM(ttBudgetsDataNotRolled.Amount) AS Amount
		                             |INTO ttBudgetsData
		                             |FROM
		                             |	ttBudgetsDataNotRolled AS ttBudgetsDataNotRolled
		                             |
		                             |GROUP BY
		                             |	ttBudgetsDataNotRolled.Analytics1,
		                             |	ttBudgetsDataNotRolled.CorBalanceUnit,
		                             |	ttBudgetsDataNotRolled.Analytics2,
		                             |	ttBudgetsDataNotRolled.Analytics3,
		                             |	ttBudgetsDataNotRolled.Period,
		                             |	ttBudgetsDataNotRolled.RecordType,
		                             |	ttBudgetsDataNotRolled.Item,
		                             |	ttBudgetsDataNotRolled.CorDepartment,
		                             |	ttBudgetsDataNotRolled.VersionPeriod
		                             |;
		                             |
		                             |////////////////////////////////////////////////////////////////////////////////
		                             |DROP ttBudgetsDataNotRolled
		                             |;
		                             |
		                             |////////////////////////////////////////////////////////////////////////////////
		                             |SELECT
		                             |	VTDocumentComments.RecordType AS RecordType,
		                             |	VTDocumentComments.Item AS Item,
		                             |	VTDocumentComments.Period AS Period,
		                             |	VTDocumentComments.VersionPeriod AS VersionPeriod,
		                             |	VTDocumentComments.Analytics1 AS Analytics1,
		                             |	VTDocumentComments.Analytics2 AS Analytics2,
		                             |	VTDocumentComments.Analytics3 AS Analytics3,
		                             |	VTDocumentComments.Comment AS Comment
		                             |INTO VTOfDocumentComments
		                             |FROM
		                             |	&VTOfDocumentComments AS VTDocumentComments
		                             |;
		                             |
		                             |////////////////////////////////////////////////////////////////////////////////
		                             |SELECT
		                             |	BudgetsData.Item AS Item,
		                             |	BudgetsData.Period AS Period,
		                             |	BudgetsData.RecordType AS RecordType,
		                             |	BudgetsData.CorDepartment AS CorDepartment,
		                             |	BudgetsData.CorBalanceUnit AS CorBalanceUnit,
		                             |	BudgetsData.VersionPeriod AS VersionPeriod,
		                             |	BudgetsData.Analytics1 AS Analytics1,
		                             |	BudgetsData.Analytics2 AS Analytics2,
		                             |	BudgetsData.Analytics3 AS Analytics3,
		                             |	VTOfDocumentComments.Comment AS Comment,
		                             |	BudgetsData.Amount AS Amount
		                             |INTO ttBudgetsDataWithComment
		                             |FROM
		                             |	ttBudgetsData AS BudgetsData
		                             |		LEFT JOIN VTOfDocumentComments AS VTOfDocumentComments
		                             |		ON BudgetsData.Item = VTOfDocumentComments.Item
		                             |			AND BudgetsData.Period = VTOfDocumentComments.Period
		                             |			AND BudgetsData.RecordType = VTOfDocumentComments.RecordType
		                             |			AND BudgetsData.Analytics1 = VTOfDocumentComments.Analytics1
		                             |			AND BudgetsData.Analytics2 = VTOfDocumentComments.Analytics2
		                             |			AND BudgetsData.Analytics3 = VTOfDocumentComments.Analytics3
		                             |			AND BudgetsData.VersionPeriod = VTOfDocumentComments.VersionPeriod
		                             |;
		                             |
		                             |////////////////////////////////////////////////////////////////////////////////
		                             |DROP ttBudgetsData
		                             |;
		                             |
		                             |////////////////////////////////////////////////////////////////////////////////
		                             |DROP VTOfDocumentComments
		                             |;
		                             |
		                             |////////////////////////////////////////////////////////////////////////////////
		                             |SELECT
		                             |	CommentsVT.Period AS Period,
		                             |	CommentsVT.Item AS Item,
		                             |	CommentsVT.RecordType AS RecordType,
		                             |	CommentsVT.CorDepartment AS CorDepartment,
		                             |	CommentsVT.CorBalanceUnit AS CorBalanceUnit,
		                             |	CommentsVT.Analytics1 AS Analytics1,
		                             |	CommentsVT.Analytics2 AS Analytics2,
		                             |	CommentsVT.Analytics3 AS Analytics3,
		                             |	CommentsVT.Comment AS Comment,
		                             |	CommentsVT.VersionPeriod AS VersionPeriod
		                             |INTO ActualCommentsTable
		                             |FROM
		                             |	&VTOfActualComments AS CommentsVT
		                             |;
		                             |
		                             |////////////////////////////////////////////////////////////////////////////////
		                             |SELECT
		                             |	BudgetsDataWithComment.RecordType AS RecordType,
		                             |	BudgetsDataWithComment.Item AS Item,
		                             |	BudgetsDataWithComment.Period AS Period,
		                             |	BudgetsDataWithComment.VersionPeriod AS VersionPeriod,
		                             |	BudgetsDataWithComment.CorDepartment AS CorDepartment,
		                             |	BudgetsDataWithComment.CorBalanceUnit AS CorBalanceUnit,
		                             |	BudgetsDataWithComment.Analytics1 AS Analytics1,
		                             |	BudgetsDataWithComment.Analytics2 AS Analytics2,
		                             |	BudgetsDataWithComment.Analytics3 AS Analytics3,
		                             |	ISNULL(ActualCommentsTable.Comment, BudgetsDataWithComment.Comment) AS Comment,
		                             |	BudgetsDataWithComment.Amount AS Amount
		                             |INTO ttBudgetsDataActual
		                             |FROM
		                             |	ttBudgetsDataWithComment AS BudgetsDataWithComment
		                             |		LEFT JOIN ActualCommentsTable AS ActualCommentsTable
		                             |		ON BudgetsDataWithComment.Item = ActualCommentsTable.Item
		                             |			AND BudgetsDataWithComment.Period = ActualCommentsTable.Period
		                             |			AND BudgetsDataWithComment.RecordType = ActualCommentsTable.RecordType
		                             |			AND BudgetsDataWithComment.VersionPeriod = ActualCommentsTable.VersionPeriod
		                             |			AND BudgetsDataWithComment.Analytics1 = ActualCommentsTable.Analytics1
		                             |			AND BudgetsDataWithComment.Analytics2 = ActualCommentsTable.Analytics2
		                             |			AND BudgetsDataWithComment.Analytics3 = ActualCommentsTable.Analytics3
		                             |
		                             |UNION ALL
		                             |
		                             |SELECT
		                             |	ActualCommentsTable.RecordType,
		                             |	ActualCommentsTable.Item,
		                             |	ActualCommentsTable.Period,
		                             |	ActualCommentsTable.VersionPeriod,
		                             |	ActualCommentsTable.CorDepartment,
		                             |	ActualCommentsTable.CorBalanceUnit,
		                             |	ActualCommentsTable.Analytics1,
		                             |	ActualCommentsTable.Analytics2,
		                             |	ActualCommentsTable.Analytics3,
		                             |	ActualCommentsTable.Comment,
		                             |	0
		                             |FROM
		                             |	ActualCommentsTable AS ActualCommentsTable
		                             |;
		                             |
		                             |////////////////////////////////////////////////////////////////////////////////
		                             |DROP ttBudgetsDataWithComment
		                             |;
		                             |
		                             |////////////////////////////////////////////////////////////////////////////////
		                             |DROP ActualCommentsTable
		                             |;
		                             |
		                             |////////////////////////////////////////////////////////////////////////////////
		                             |SELECT
		                             |	BudgetsDataActual.RecordType AS RecordType,
		                             |	BudgetsDataActual.Item AS Item,
		                             |	BudgetsDataActual.Period AS Period,
		                             |	BudgetsDataActual.VersionPeriod AS VersionPeriod,
		                             |	BudgetsDataActual.CorDepartment AS CorDepartment,
		                             |	BudgetsDataActual.CorBalanceUnit AS CorBalanceUnit,
		                             |	BudgetsDataActual.Analytics1 AS Analytics1,
		                             |	BudgetsDataActual.Analytics2 AS Analytics2,
		                             |	BudgetsDataActual.Analytics3 AS Analytics3,
		                             |	CAST(BudgetsDataActual.Comment AS STRING(1024)) AS Comment,
		                             |	SUM(BudgetsDataActual.Amount) AS Amount
		                             |FROM
		                             |	ttBudgetsDataActual AS BudgetsDataActual
		                             |
		                             |GROUP BY
		                             |	BudgetsDataActual.RecordType,
		                             |	BudgetsDataActual.Item,
		                             |	BudgetsDataActual.Period,
		                             |	BudgetsDataActual.VersionPeriod,
		                             |	BudgetsDataActual.CorDepartment,
		                             |	BudgetsDataActual.CorBalanceUnit,
		                             |	BudgetsDataActual.Analytics1,
		                             |	BudgetsDataActual.Analytics2,
		                             |	BudgetsDataActual.Analytics3,
		                             |	CAST(BudgetsDataActual.Comment AS STRING(1024))";
		
		CurrentObject.BudgetsData.Load(QueryWithCommnts.Execute().Unload());
				
	Else
		
		CurrentObject.BudgetsData.Clear();
		If Object.OperationType=Enums.fmBudgetOperationTypes.InternalSettlements Then
			// Обход счетов.
			For Each CurRowInitial In InternalSettlements Do
				// Проверяем, есть ли какие-то данные.
				IsData = False;
				For Each CurResourceName In Resources Do
					If CurRowInitial[CurResourceName.Value] <> 0 Then
						IsData = True;
						Break;
					EndIf;
				EndDo;
				If NOT IsData Then 
					Continue; 
				EndIf;
				NewRowPlan = CurrentObject.BudgetsData.Add();
				NewRowPlan.Period = CurRowInitial.Period;
				NewRowPlan.VersionPeriod = Object.ActualVersion;
				NewRowPlan.Item = CurRowInitial.Item;
				NewRowPlan.CorDepartment = CurRowInitial.CorDepartment;
				// Заполненеие реквизита КорБалансоваяЕдиница.
				RowSearchStructure.Department = CurRowInitial.CorDepartment;
				MapRows = MapDepartmentsBalanceUnit.FindRows(RowSearchStructure);
				For Each MapRow In MapRows Do
					If MapRow.Period <= NewRowPlan.Period Then
						NewRowPlan.CorBalanceUnit = MapRow.BalanceUnit;
					Else
						Break;
					EndIf;
				EndDo;
				NewRowPlan.Analytics1 = CurRowInitial.Analytics1;
				NewRowPlan.Analytics2 = CurRowInitial.Analytics2;
				NewRowPlan.Analytics3 = CurRowInitial.Analytics3;
				For Each CurResourceName In Resources Do
					NewRowPlan[CurResourceName.Value] = fmBudgeting.TransformNumber(CurRowInitial[CurResourceName.Value], "", ConstantInputFormat, False);
				EndDo;
			EndDo;
		Else
			// Обход Исходной ТЗ
			InitialDataVT = GetFromTempStorage(InitialDataVTAddress);
			For Each CurRowInitial In InitialDataVT Do
				// Если Редактирование - то мы находимся в "листе" дерева. 
				// Именно он и является элементом с данными, а не с итогами по группировкам или по формуле.
				If CurRowInitial.Edit Then
					// Проверяем, есть ли какие-то данные.
					IsData = False;
					For Each CurResourceName In Resources Do
						If CurRowInitial["Resource_"+CurResourceName.Value] <> 0 Then
							IsData = True;
							Break;
						EndIf;
					EndDo;
					If NOT IsData Then 
						Continue; 
					EndIf;
					NewRowPlan = CurrentObject.BudgetsData.Add();
					NewRowPlan.Period = CurRowInitial.Period;
					NewRowPlan.VersionPeriod = Object.ActualVersion;
					NewRowPlan.RecordType = CurRowInitial.RecordType;
					NewRowPlan.Item = CurRowInitial.Analytics;
					NewRowPlan.Analytics1 = CurRowInitial.Analytics1;
					NewRowPlan.Analytics2 = CurRowInitial.Analytics2;
					NewRowPlan.Analytics3 = CurRowInitial.Analytics3;
					For Each CurResourceName In Resources Do
						NewRowPlan[CurResourceName.Value] = fmBudgeting.TransformNumber(CurRowInitial["Resource_"+CurResourceName.Value], StructureInputFormat, ConstantInputFormat, False);
					EndDo;
					NewRowPlan.Comment = CurRowInitial.Comment;
				EndIf;
			EndDo;
		EndIf;
	EndIf;
	DetermineAnalyticsTypes();
EndProcedure // ЗаполнитьДанные()

&AtServer
Procedure DetermineAnalyticsTypes()
	//Определим типы аналитик для каждой из существующих статей в ТЧ документа.
	Query = New Query("SELECT ALLOWED
	                      |	BudgetsData.Item AS Item,
	                      |	BudgetsData.Period AS Period,
	                      |	BudgetsData.Amount AS Amount,
	                      |	BudgetsData.CorItem AS CorItem,
	                      |	BudgetsData.CorDepartment AS CorDepartment,
	                      |	BudgetsData.Analytics1 AS Analytics1,
	                      |	BudgetsData.Analytics2 AS Analytics2,
	                      |	BudgetsData.Analytics3 AS Analytics3,
	                      |	BudgetsData.RecordType AS RecordType,
	                      |	BudgetsData.LineNumber AS LineNumber,
	                      |	BudgetsData.CorBalanceUnit AS CorBalanceUnit,
	                      |	BudgetsData.CorProject AS CorProject,
	                      |	BudgetsData.VersionPeriod AS VersionPeriod
	                      |INTO TTBudgetsData
	                      |FROM
	                      |	&BudgetsData AS BudgetsData
	                      |
	                      |INDEX BY
	                      |	Item
	                      |;
	                      |
	                      |////////////////////////////////////////////////////////////////////////////////
	                      |SELECT
	                      |	TTBudgetsData.Item AS Item,
	                      |	TTBudgetsData.Period AS Period,
	                      |	TTBudgetsData.Amount AS Amount,
	                      |	TTBudgetsData.CorItem AS CorItem,
	                      |	TTBudgetsData.CorDepartment AS CorDepartment,
	                      |	TTBudgetsData.Analytics1 AS Analytics1,
	                      |	TTBudgetsData.Analytics2 AS Analytics2,
	                      |	TTBudgetsData.Analytics3 AS Analytics3,
	                      |	TTBudgetsData.RecordType AS RecordType,
	                      |	TTBudgetsData.LineNumber AS LineNumber,
	                      |	TTBudgetsData.VersionPeriod AS VersionPeriod,
	                      |	TTBudgetsData.CorBalanceUnit AS CorBalanceUnit,
	                      |	TTBudgetsData.CorProject AS CorProject,
	                      |	{Catalog}.{fm}AnalyticsType1.ValueType AS AnalyticsType1,
	                      |	{Catalog}.{fm}AnalyticsType2.ValueType AS AnalyticsType2,
	                      |	{Catalog}.{fm}AnalyticsType3.ValueType AS AnalyticsType3,
	                      |	{Catalog}.{fm}AnalyticsType1 <> VALUE(ChartOfCharacteristicTypes.fmAnalyticsTypes.EmptyRef) AS AnalyticsType1Filled,
	                      |	{Catalog}.{fm}AnalyticsType2 <> VALUE(ChartOfCharacteristicTypes.fmAnalyticsTypes.EmptyRef) AS AnalyticsType2Filled,
	                      |	{Catalog}.{fm}AnalyticsType3 <> VALUE(ChartOfCharacteristicTypes.fmAnalyticsTypes.EmptyRef) AS AnalyticsType3Filled
	                      |FROM
	                      |	TTBudgetsData AS TTBudgetsData
	                      |		LEFT JOIN Catalog.{Catalog} AS {Catalog}
	                      |		ON TTBudgetsData.Item = {Catalog}.Ref
	                      |;
	                      |
	                      |////////////////////////////////////////////////////////////////////////////////
	                      |DROP TTBudgetsData");
	Query.TempTablesManager = New TempTablesManager;
	Query.SetParameter("BudgetsData", Object.BudgetsData.Unload());
	If Object.OperationType = Enums.fmBudgetOperationTypes.IncomesAndExpenses OR Object.OperationType = Enums.fmBudgetOperationTypes.InternalSettlements Then
		Query.Text = StrReplace(Query.Text,"{Catalog}","fmIncomesAndExpensesItems");
		Query.Text = StrReplace(Query.Text,"{fm}","");
	ElsIf Object.OperationType = Enums.fmBudgetOperationTypes.Cashflows Then
		Query.Text = StrReplace(Query.Text,"{Catalog}","fmCashflowItems");
		Query.Text = StrReplace(Query.Text,"{fm}","fm");
	EndIf;
	QueryResult = Query.Execute().Unload();
	Object.BudgetsData.Load(QueryResult);
EndProcedure

// Заполняет реквизит представлением месяца, хранящегося в другом реквизите.
//
// Параметры:
//		РедактируемыйОбъект
//		ПутьРеквизита - Строка, путь к реквизиту, содержащего дату.
//		ПутьРеквизитаПредставления - Строка, путь к реквизиту в который помещается представление месяца.
//
&AtServer
Procedure FillMonthByDate(EditedObject, AttributePath, AttributePathPresentation)
	Value = CommonClientServer.GetFormAttributeByPath(EditedObject, AttributePath);
	CommonClientServer.SetFormAttributeByPath(EditedObject, AttributePathPresentation, Format(Value, "L=en_US; DF='MMMM yyyy'"));
EndProcedure

&AtServer
Procedure FillCurrencyRates()
	fmCurrencyRatesProcessing.FormTableOfCurrencyRates(Object.CurrencyRates, Object.Currency, Object.BeginOfPeriod, Object.Scenario);
EndProcedure

&AtServer
Procedure FormManagement()
	
	Items.PageBudgetTree.Visible = False;
	Items.PageTable.Visible = False;
	Items.PageInternalSettlements.Visible = False;
	Items.FormPreview.Visible = False;
	Items.BudgetsDataCorDepartment.Visible = False;
	Items.BudgetsDataBalanceUnit.Visible = False;
	Items.BudgetsDataRecordType.Visible = False;
	If Object.OperationType = Enums.fmBudgetOperationTypes.IncomesAndExpenses Then
		Items.BudgetsDataItem.TypeRestriction = New TypeDescription("CatalogRef.fmIncomesAndExpensesItems");
		Items.PageBudgetTree.Visible = NOT SpeadsheetView;
		Items.PageTable.Visible = SpeadsheetView;
		Items.FormPreview.Visible = NOT SpeadsheetView;
		Items.BudgetsDataRecordType.Visible = True;
	ElsIf Object.OperationType = Enums.fmBudgetOperationTypes.Cashflows Then
		Items.BudgetsDataItem.TypeRestriction = New TypeDescription("CatalogRef.fmCashflowItems");
		Items.PageBudgetTree.Visible = NOT SpeadsheetView;
		Items.PageTable.Visible = SpeadsheetView;
		Items.FormPreview.Visible = NOT SpeadsheetView;
		Items.BudgetsDataRecordType.Visible = True;
	ElsIf Object.OperationType = Enums.fmBudgetOperationTypes.InternalSettlements Then
		Items.BudgetsDataItem.TypeRestriction = New TypeDescription("CatalogRef.fmIncomesAndExpensesItems");
		Items.PageInternalSettlements.Visible = NOT SpeadsheetView;
		Items.PageTable.Visible = SpeadsheetView;
		Items.BudgetsDataCorDepartment.Visible = True;
		Items.BudgetsDataBalanceUnit.Visible = True;
	EndIf;
	
	// Версионирование работает только для плана и при включении.
	Items.VersionSubmenu.Visible = False;
	If ScenarioType=Enums.fmBudgetingScenarioTypes.Plan 
	AND (BudgetVersioning=Enums.fmBudgetVersioning.EveryDay
	OR BudgetVersioning=Enums.fmBudgetVersioning.EveryMonth) Then
		Items.VersionSubmenu.Visible = NOT SpeadsheetView;
	EndIf;
	
	// Если документ создан автаматически распределением, то временно запрещено редактирование.
	ReadOnly = Object.Allocation;
	Items.InternalSettlements.Visible = NOT Object.Allocation;
	
EndProcedure

&AtServer
Procedure FillPeriods()
	
	// Заполним периоды.
	Periods.Clear();
	If ValueIsFilled(Object.Scenario) AND ValueIsFilled(Object.BeginOfPeriod) Then
		PeriodsTable = fmBudgeting.PeriodsTable(Object.Scenario, Object.BeginOfPeriod);
		For Each CurRow In PeriodsTable Do
			Periods.Add(CurRow.BeginOfPeriod, CurRow.PeriodPresentation);
		EndDo;
	EndIf;
	
	// Заполним таблицу кварталов.
	If Object.InfoStructure.BudgetTotalType=Enums.fmBudgetTotalType.ByMonthesAndQuaters
	AND Object.Scenario.PlanningPeriodicity = Enums.fmPlanningPeriodicity.Month
	AND Object.Scenario.PlanningPeriod = Enums.fmPlanningPeriod.Year
	AND Object.BeginOfPeriod = BegOfQuarter(Object.BeginOfPeriod) Then
		ColumnGroup = True;
		For Each CurPeriod In Periods Do
			If Periods.IndexOf(CurPeriod)%3=0 Then
				NewQuarter = Quarters.Add();
				NewQuarter.Period = CurPeriod.Value;
				NewQuarter.ColumnNumber = 4+Periods.IndexOf(CurPeriod)+Int(Periods.IndexOf(CurPeriod)/3);
			EndIf;
		EndDo;
	Else
		ColumnGroup = False;
		Quarters.Clear();
	EndIf;
	
EndProcedure

&AtServer
Procedure FillResources()
	// Для возможности расширения количества ресурсов.
	Resources.Clear();
	Resources.Add("Amount", NStr("en='Amount';ru='Сумма'"));
EndProcedure

&AtServer
Procedure FillVersions()
	
	Query = New Query;
	Query.Text = "SELECT ALLOWED
	               |	BudgetsData.VersionPeriod AS VersionPeriod
	               |FROM
	               |	Document.fmBudget.BudgetsData AS BudgetsData
	               |WHERE
	               |	BudgetsData.Ref = &Ref
	               |	AND NOT BudgetsData.VersionPeriod = &EmptyDate
	               |
	               |GROUP BY
	               |	BudgetsData.VersionPeriod
	               |
	               |ORDER BY
	               |	BudgetsData.VersionPeriod DESC";
	
	Query.SetParameter("EmptyDate", DATE("00010101000000"));
	Query.SetParameter("Ref",				Object.Ref);
	
	VersionsDates = Query.Execute().Unload();
	
	// Очистим версии
	ItemsToDelete = New Array();
	For Each CurItem In Items.VersionSubmenu.ChildItems Do
		ItemsToDelete.Add(CurItem);
	EndDo;
	For Each CurItem In ItemsToDelete Do
		Items.Delete(CurItem);
	EndDo;
	CommandsToDelete = New Array();
	For Each CurCommand In Commands Do
		If NOT Find(CurCommand.Name, "IndicatorsVersion")=0 AND NOT CurCommand.Name="IndicatorsVersion" Then
			CommandsToDelete.Add(CurCommand);
		EndIf;
	EndDo;
	For Each CurCommand In CommandsToDelete Do
		Commands.Delete(CurCommand);
	EndDo;
	
	// Версионирование работает только для плана и при включении.
	If NOT (ScenarioType=Enums.fmBudgetingScenarioTypes.Plan
	AND (BudgetVersioning=Enums.fmBudgetVersioning.EveryDay
	OR BudgetVersioning=Enums.fmBudgetVersioning.EveryMonth)) Then
		Object.ActualVersion = DATE("00010101");
		CurrentVersion = DATE("00010101");
		Return;
	EndIf;
	
	// Проверка по версионированию.
	If BudgetVersioning=Enums.fmBudgetVersioning.EveryMonth Then
		CurrentVersion = BegOfMonth(CurrentSessionDate());
		VersionDateFormat = "L=en_US; DF='MMMM yyyy'";
	Else
		CurrentVersion = CurrentSessionDate();
		VersionDateFormat = "L=en_US; DF='dd MMMM yyyy'";
	EndIf;
	
	// Проверка по согласованию.
	If fmProcessManagement.AgreeDocument(Object.Department, ChartsOfCharacteristicTypes.fmAgreeDocumentTypes.fmBudget, fmProcessManagement.AgreementCheckDate(Object))
	AND NOT fmProcessManagement.GetDocumentState(Object.Ref, Object.ActualVersion)=Catalogs.fmDocumentState.Approved
	AND ValueIsFilled(Object.ActualVersion) Then
		CurrentVersion = Object.ActualVersion;
	EndIf;
	
	If CurrentVersion>Object.ActualVersion Then
		Object.ActualVersion = CurrentVersion;
	Else
		CurrentVersion = Object.ActualVersion;
	EndIf;
	
	Items.VersionSubmenu.Title = StrTemplate(NStr("ru = 'Текущая версия бюджета <%1>';en='Current version of budget <%1>'"), Format(CurrentVersion, VersionDateFormat));
	
	NewCommand = Commands.Add("IndicatorsVersion"+Format(CurrentVersion, "DF=yyyyMMdd"));
	NewCommand.Action = "IndicatorsVersion";
	NewButton = Items.Add("Version_"+Format(CurrentVersion, "DF=yyyyMMdd"), Type("FormButton"), Items.VersionSubmenu);
	NewButton.Title = "<" + Format(CurrentVersion, VersionDateFormat)+">";
	NewButton.Visible = True;
	NewButton.CommandName = NewCommand.Name;
	For Each CurRow In VersionsDates Do
		If NOT CurRow.VersionPeriod = CurrentVersion Then
			NewCommand = Commands.Add("IndicatorsVersion"+Format(CurRow.VersionPeriod, "DF=yyyyMMdd"));
			NewCommand.Action = "IndicatorsVersion";
			NewButton = Items.Add("Version_"+Format(CurRow.VersionPeriod, "DF=yyyyMMdd"), Type("FormButton"), Items.VersionSubmenu);
			NewButton.Title = "<" + Format(CurRow.VersionPeriod, VersionDateFormat)+">";
			NewButton.Visible = True;
			NewButton.CommandName = NewCommand.Name;
		EndIf;
	EndDo;
	
EndProcedure

&AtServerNoContext
Function CheckGetAddParameters(Details, DetailsData, NameCommand, OperationType)
	
	ParametersStructure = New Structure("Cancel, FullName, AnalyticsName", False, "");
	
	// Получение объекта данных расшифровки.
	DetailsDataObject = GetFromTempStorage(DetailsData);
	DetailsFields = DetailsDataObject.Items[Details].GetFields();
	Section			= DetailsFields.Find("Section");
	// Проверим наличие раздела для области.
	If Section=Undefined Then
		CommonClientServer.MessageToUser(NStr("en='It is impossible to add a row for the selected area.';ru='Добавление строки для выделенной области невозможно!'"), , , , ParametersStructure.Cancel);
	EndIf;
	
	// Опредеделим имя текущей аналитики.
	AnalyticsName = DetailsFields.Find("AnalyticsName").Value;
	If AnalyticsName="Section" Then
		ParametersStructure.AnalyticsName = "Analytics";
	ElsIf NameCommand="AddChild" Then
		If AnalyticsName="Analytics" Then
			ParametersStructure.AnalyticsName = "Analytics1";
		ElsIf AnalyticsName="Analytics1" Then
			ParametersStructure.AnalyticsName = "Analytics2";
		ElsIf AnalyticsName="Analytics2" OR AnalyticsName="Analytics3" Then
			ParametersStructure.AnalyticsName = "Analytics3";
		EndIf;
	Else
		ParametersStructure.AnalyticsName = AnalyticsName;
	EndIf;
	
	// Сохраним значения аналитик.
	ParametersStructure.Insert("CommandName", NameCommand);
	ParametersStructure.Insert("Analytics", DetailsFields.Find("Analytics").Value);
	ParametersStructure.Insert("Analytics1", DetailsFields.Find("Analytics1").Value);
	ParametersStructure.Insert("Analytics2", DetailsFields.Find("Analytics2").Value);
	ParametersStructure.Insert("Analytics3", DetailsFields.Find("Analytics3").Value);
	
	// Проверим, что работаем в рамках ВНЕ СТРУКТУРЫ или БЕЗ СТРУКТУРЫ или ПО СТРУКТУРЕ но добавляем аналитику.
	InfoStructure = Section.Value.Owner;
	If NOT ((InfoStructure = Catalogs.fmInfoStructures.WithoutStructureIE OR InfoStructure = Catalogs.fmInfoStructures.WithoutStructureCF)
	OR (InfoStructure = Catalogs.fmInfoStructures.OutOfStructureIE AND ValueIsFilled(Section.Value.StructureSectionType))
	OR (InfoStructure = Catalogs.fmInfoStructures.OutOfStructureCF AND ValueIsFilled(Section.Value.StructureSectionType))
	OR (NOT (InfoStructure = Catalogs.fmInfoStructures.WithoutStructureIE OR InfoStructure = Catalogs.fmInfoStructures.WithoutStructureCF) AND NOT ParametersStructure.AnalyticsName = "Analytics")) Then
		CommonClientServer.MessageToUser(NStr("en='It is impossible to add a row for the selected area.';ru='Добавление строки для выделенной области невозможно!'"), , , , ParametersStructure.Cancel);
		Return ParametersStructure;
	EndIf;
	
	If ParametersStructure.AnalyticsName="Analytics1" OR ParametersStructure.AnalyticsName="Analytics2" OR ParametersStructure.AnalyticsName="Analytics3" Then
		Prefix = ?(OperationType=Enums.fmBudgetOperationTypes.Cashflows, "fm", "");
		Try
			ParametersStructure.FullName = Metadata.FindByType(DetailsFields.Find("Analytics").Value[Prefix+"AnalyticsType"+Right(ParametersStructure.AnalyticsName, 1)].ValueType.Types()[0]).FullName();
		Except
			// Значит аналитка не определена!
		EndTry;
	ElsIf OperationType=Enums.fmBudgetOperationTypes.IncomesAndExpenses Then
		ParametersStructure.FullName = "Catalog.fmIncomesAndExpensesItems";
	ElsIf OperationType=Enums.fmBudgetOperationTypes.Cashflows Then
		ParametersStructure.FullName = "Catalog.fmCashflowItems";
	EndIf;
	
	Return ParametersStructure;
	
EndFunction

&AtServer
Procedure SettingsGenerating(DCSettings, VTConditionalAppearance)
	
	// УСЛОВНОЕ ОФОРМЛЕНИЕ
	For Each RowForCA In VTConditionalAppearance Do
		If RowForCA.Italic OR RowForCA.Bold OR NOT IsBlankString(RowForCA.TextColor) Then
			CAItem = DCSettings.ConditionalAppearance.Items.Add();
			AppearanceColorItem = CAItem.Appearance.Items.Find("Font");
			AppearanceColorItem.Value = New Font( , , RowForCA.Bold, RowForCA.Italic);
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
Function ProcessAreaContentChangeAtServer(DetailsID, NewValue)
	
	// Получение данных расшифровки.
	DetailsDataObject = GetFromTempStorage(DetailsData);
	
	// Создание структуры для поиска строки по ячейке в исходной ТЗ и поиск имени ресурса в текущей ячейке.
	FS = New Structure(SearchColumnsRow);
	
	// Получение полей расшифровки для текущей ячейки.
	DetailsFieldValues = DetailsDataObject.Items[DetailsID].GetFields();
	ResourceName = "";
	For Each DetailsFieldValue In DetailsFieldValues Do
		If Find(DetailsFieldValue.Field, "Resource_") Then
			ResourceName = DetailsFieldValue.Field;
			DetailsFieldValue.Value = NewValue;
		EndIf;
		If Find(SearchColumnsRow, DetailsFieldValue.Field) Then
			FS[DetailsFieldValue.Field] = DetailsFieldValue.Value;
		EndIf;
	EndDo;
	
	// Основные параметры лежат в 1-ой колонке, строка должна делиться без остатка на количество ресурсов.
	CurrentArea = Items.BudgetTree.CurrentArea;
	CurTop = DetermineTopCoord(CurrentArea.Top, Resources.Count());
	CurrentArea = BudgetTree.Area(CurTop, 1, CurTop, 1);
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
			ExecutePartialIterationOfBudgetsTree(ResourceName, FoundRow);
		EndIf;
	EndIf;
	
	// Сохраним в расшифровках новое значение.
	Try
		DetailsParentsValues	= DetailsDataObject.Items[DetailsID].GetParents();
	Except
		DetailsParentsValues	= Undefined;
	EndTry;
	NewDetailItem			= DetailsDataObject.Items.Add(Type("DataCompositionFieldDetailsItem"), DetailsParentsValues, DetailsFieldValues);
	
	// Зависимые статьи.
	For Each DetailsFieldValue In DetailsFieldValues Do
		If NOT Find(SearchColumnsRow, DetailsFieldValue.Field) Then
			FS.Insert(DetailsFieldValue.Field, DetailsFieldValue.Value);
		EndIf;
	EndDo;
	CalculateDependentItemsServer(FS, DetailsDataObject);
	
	InitialDataVTAddress = PutToTempStorage(InitialDataVT, UUID);
	
	Return NewDetailItem.ID;
	
EndFunction

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

&AtServer
Function PreparePredictionParameters(Prediction=True);
	
	// Сформируем структуру параметров.
	ParametersStructure = New Structure("CurScenario, BeginOfPeriod, InfoStructure, Department, OperationType", Object.Scenario, Object.BeginOfPeriod, Object.InfoStructure, Object.Department, Object.OperationType);
	ParametersStructure.Insert("ItemsList", New ValueList());
	// Возьмем статьи из структуры сведений.
	If ValueIsFilled(Object.InfoStructure) Then
		Query = New Query("SELECT
                      |	SectionStructureData.Analytics AS Item
                      |FROM
                      |	Catalog.fmInfoStructuresSections.SectionStructureData AS SectionStructureData
                      |WHERE
                      |	SectionStructureData.Ref.Owner = &InfoStructure
                      |	AND NOT SectionStructureData.Analytics Refs Catalog.fmItemGroups
                      |	AND SectionStructureData.Ref.StructureSectionType <> Value(Enum.fmBudgetFlowOperationTypes.EmptyRef)
                      |	AND NOT SectionStructureData.Ref.DeletionMark
                      |
                      |UNION ALL
                      |
                      |SELECT
                      |	ItemGroupsItem.Item
                      |FROM
                      |	Catalog.fmInfoStructuresSections.SectionStructureData AS SectionStructureData
                      |		LEFT JOIN Catalog.fmItemGroups.Items AS ItemGroupsItem
                      |		ON SectionStructureData.Analytics = ItemGroupsItem.Ref
                      |WHERE
                      |	SectionStructureData.Ref.Owner = &InfoStructure
                      |	AND SectionStructureData.Ref.StructureSectionType <> Value(Enum.fmBudgetFlowOperationTypes.EmptyRef)
                      |	AND SectionStructureData.Analytics Refs Catalog.fmItemGroups
                      |	AND NOT SectionStructureData.Ref.DeletionMark");
		Query.SetParameter("InfoStructure", Object.InfoStructure);
		ParametersStructure.ItemsList.LoadValues(Query.Execute().Unload().UnloadColumn("Item"));
	EndIf;
	
	// Подготовить курсы валют для передачи.
	ParametersStructure.Insert("CurrencyRates", PutToTempStorage(Object.CurrencyRates.Unload(), UUID));
	
	// Определим прогнозирование или копирование.
	ParametersStructure.Insert("Prediction", Prediction);
	
	// Передадим предыдущие параметры заполнения, если они есть.
	ParametersStructure.Insert("FillingParameters", FillingParameters);
	
	Return ParametersStructure;
	
EndFunction

&AtServer
Procedure ShowPredictionResult(DataTableAddress, Indicator)
	
	// Получим таблицу из хранилища.
	DataTable = GetFromTempStorage(DataTableAddress);
	InitialDataVT = GetFromTempStorage(InitialDataVTAddress);
	// Удалим строки результирующей таблицы, которые были пересчитаны по ключу "период + статья + аналитики + вид движения + период версии".
	For Each CurRow In DataTable Do
		SearchStructure = New Structure("Period, Analytics, Analytics1, Analytics2, Analytics3, RecordType");
		FillPropertyValues(SearchStructure, CurRow);
		FoundRows = InitialDataVT.FindRows(SearchStructure);
		For Each FoundCurRow In FoundRows Do
			InitialDataVT.Delete(FoundCurRow);
		EndDo;
		NewLine = InitialDataVT.Add();
		FillPropertyValues(NewLine, CurRow);
	EndDo;
	InitialDataVTAddress = PutToTempStorage(InitialDataVT, UUID);
	
	// Сохраним данные для дальнейшего перестроения дерева.
	FillData(Object);
	
	// Заполним дерево на основании новой таблицы.
	FillBudgetTree();

EndProcedure

&AtServer
Function GenerateStateTitle()
	
	If ScenarioType=Enums.fmBudgetingScenarioTypes.Plan Then
		If BudgetVersioning=Enums.fmBudgetVersioning.EveryMonth Then
			Return StrTemplate(NStr("en=' <%1> budget version status:';ru='Состояние версии бюджета <%1>:'"), Format(CurrentVersion, "L=en_US; DF='MMMM yyyy'"));
		ElsIf BudgetVersioning=Enums.fmBudgetVersioning.EveryDay Then
			Return StrTemplate(NStr("en=' <%1> budget version status:';ru='Состояние версии бюджета <%1>:'"), Format(CurrentVersion, "L=en_US; DF='dd MMMM yyyy'"));
		Else
			Return NStr("en='Budget status:';ru='Состояние бюджета:'");
		EndIf;
	Else
		Return NStr("en='Budget status:';ru='Состояние бюджета:'");
	EndIf;
	
EndFunction

&AtServer
Procedure FillItemsDependencies()
	
	ItemsDependencies.Clear();
	
	// Используется система приоритетов для комбинации Статья + Сценарий + Подразделение + БалансоваяЕдиница:
	// 8 - совпадает сценарий , совпадает подразделение и совпадает БалансоваяЕдиница.
	// 7 - не совпадает сценарий , совпадает подразделение и совпадает БалансоваяЕдиница.
	// 6 - совпадает сценарий , совпадает подразделение и не совпадает БалансоваяЕдиница.
	// 5 - не совпадает сценарий , совпадает подразделение и не совпадает БалансоваяЕдиница.
	// 4 - совпадает сценарий , не совпадает подразделение и совпадает БалансоваяЕдиница.
	// 3 - не совпадает сценарий , не совпадает подразделение и совпадает БалансоваяЕдиница.
	// 2 - совпадает сценарий , не совпадает подразделение и не совпадает БалансоваяЕдиница.
	// 1 - не совпадает сценарий , не совпадает подразделение и не совпадает БалансоваяЕдиница.
	Query = New Query("SELECT ALLOWED
	                      |	fmItemsDependencies.Item AS Item,
	                      |	fmItemsDependencies.DependentItem AS DependentItem,
	                      |	fmItemsDependencies.Analytics1 AS Analytics1,
	                      |	fmItemsDependencies.Analytics2 AS Analytics2,
	                      |	fmItemsDependencies.Analytics3 AS Analytics3,
	                      |	fmItemsDependencies.DependentAnalytics1 AS DependentAnalytics1,
	                      |	fmItemsDependencies.DependentAnalytics2 AS DependentAnalytics2,
	                      |	fmItemsDependencies.DependentAnalytics3 AS DependentAnalytics3,
	                      |	fmItemsDependencies.DependentAnalyticsFillingVariant1 AS DependentAnalyticsFillingVariant1,
	                      |	fmItemsDependencies.DependentAnalyticsFillingVariant2 AS DependentAnalyticsFillingVariant2,
	                      |	fmItemsDependencies.DependentAnalyticsFillingVariant3 AS DependentAnalyticsFillingVariant3,
	                      |	fmItemsDependencies.Percent AS Percent,
	                      |	fmItemsDependencies.AlloctionByPeriodsProfile AS AlloctionByPeriodsProfile,
	                      |	fmItemsDependencies.AlloctionByPeriodsProfile.Periods.(
	                      |		Fraction AS Fraction,
	                      |		PeriodNumber AS PeriodNumber,
	                      |		LineNumber AS LineNumber
	                      |	) AS AlloctionByPeriodsProfilePeriods,
	                      |	fmItemsDependencies.RecordType AS RecordType,
	                      |	fmItemsDependencies.OperationType AS OperationType,
	                      |	1 AS Priority
	                      |FROM
	                      |	InformationRegister.fmItemsDependencies AS fmItemsDependencies
	                      |WHERE
	                      |	fmItemsDependencies.BalanceUnit = Value(Catalog.fmBalanceUnits.EmptyRef)
	                      |	AND fmItemsDependencies.Department = Value(Catalog.fmDepartments.EmptyRef)
	                      |	AND fmItemsDependencies.Scenario = Value(Catalog.fmBudgetingScenarios.EmptyRef)
	                      |	AND fmItemsDependencies.OperationType IN(&OperationType)
	                      |
	                      |UNION ALL
	                      |
	                      |SELECT
	                      |	fmItemsDependencies.Item,
	                      |	fmItemsDependencies.DependentItem,
	                      |	fmItemsDependencies.Analytics1,
	                      |	fmItemsDependencies.Analytics2,
	                      |	fmItemsDependencies.Analytics3,
	                      |	fmItemsDependencies.DependentAnalytics1,
	                      |	fmItemsDependencies.DependentAnalytics2,
	                      |	fmItemsDependencies.DependentAnalytics3,
	                      |	fmItemsDependencies.DependentAnalyticsFillingVariant1,
	                      |	fmItemsDependencies.DependentAnalyticsFillingVariant2,
	                      |	fmItemsDependencies.DependentAnalyticsFillingVariant3,
	                      |	fmItemsDependencies.Percent,
	                      |	fmItemsDependencies.AlloctionByPeriodsProfile,
	                      |	fmItemsDependencies.AlloctionByPeriodsProfile.Periods.(
	                      |		Fraction,
	                      |		PeriodNumber,
	                      |		LineNumber
	                      |	),
	                      |	fmItemsDependencies.RecordType,
	                      |	fmItemsDependencies.OperationType,
	                      |	2
	                      |FROM
	                      |	InformationRegister.fmItemsDependencies AS fmItemsDependencies
	                      |WHERE
	                      |	fmItemsDependencies.BalanceUnit = Value(Catalog.fmBalanceUnits.EmptyRef)
	                      |	AND fmItemsDependencies.Department = Value(Catalog.fmDepartments.EmptyRef)
	                      |	AND fmItemsDependencies.Scenario = &Scenario
	                      |	AND fmItemsDependencies.OperationType IN(&OperationType)
	                      |
	                      |UNION ALL
	                      |
	                      |SELECT
	                      |	fmItemsDependencies.Item,
	                      |	fmItemsDependencies.DependentItem,
	                      |	fmItemsDependencies.Analytics1,
	                      |	fmItemsDependencies.Analytics2,
	                      |	fmItemsDependencies.Analytics3,
	                      |	fmItemsDependencies.DependentAnalytics1,
	                      |	fmItemsDependencies.DependentAnalytics2,
	                      |	fmItemsDependencies.DependentAnalytics3,
	                      |	fmItemsDependencies.DependentAnalyticsFillingVariant1,
	                      |	fmItemsDependencies.DependentAnalyticsFillingVariant2,
	                      |	fmItemsDependencies.DependentAnalyticsFillingVariant3,
	                      |	fmItemsDependencies.Percent,
	                      |	fmItemsDependencies.AlloctionByPeriodsProfile,
	                      |	fmItemsDependencies.AlloctionByPeriodsProfile.Periods.(
	                      |		Fraction,
	                      |		PeriodNumber,
	                      |		LineNumber
	                      |	),
	                      |	fmItemsDependencies.RecordType,
	                      |	fmItemsDependencies.OperationType,
	                      |	3
	                      |FROM
	                      |	InformationRegister.fmItemsDependencies AS fmItemsDependencies
	                      |WHERE
	                      |	fmItemsDependencies.BalanceUnit = &BalanceUnit
	                      |	AND fmItemsDependencies.Department = Value(Catalog.fmDepartments.EmptyRef)
	                      |	AND fmItemsDependencies.Scenario = Value(Catalog.fmBudgetingScenarios.EmptyRef)
	                      |	AND fmItemsDependencies.OperationType IN(&OperationType)
	                      |
	                      |UNION ALL
	                      |
	                      |SELECT
	                      |	fmItemsDependencies.Item,
	                      |	fmItemsDependencies.DependentItem,
	                      |	fmItemsDependencies.Analytics1,
	                      |	fmItemsDependencies.Analytics2,
	                      |	fmItemsDependencies.Analytics3,
	                      |	fmItemsDependencies.DependentAnalytics1,
	                      |	fmItemsDependencies.DependentAnalytics2,
	                      |	fmItemsDependencies.DependentAnalytics3,
	                      |	fmItemsDependencies.DependentAnalyticsFillingVariant1,
	                      |	fmItemsDependencies.DependentAnalyticsFillingVariant2,
	                      |	fmItemsDependencies.DependentAnalyticsFillingVariant3,
	                      |	fmItemsDependencies.Percent,
	                      |	fmItemsDependencies.AlloctionByPeriodsProfile,
	                      |	fmItemsDependencies.AlloctionByPeriodsProfile.Periods.(
	                      |		Fraction,
	                      |		PeriodNumber,
	                      |		LineNumber
	                      |	),
	                      |	fmItemsDependencies.RecordType,
	                      |	fmItemsDependencies.OperationType,
	                      |	4
	                      |FROM
	                      |	InformationRegister.fmItemsDependencies AS fmItemsDependencies
	                      |WHERE
	                      |	fmItemsDependencies.BalanceUnit = &BalanceUnit
	                      |	AND fmItemsDependencies.Department = Value(Catalog.fmBudgetingScenarios.EmptyRef)
	                      |	AND fmItemsDependencies.Scenario = &Scenario
	                      |	AND fmItemsDependencies.OperationType IN(&OperationType)
	                      |
	                      |UNION ALL
	                      |
	                      |SELECT
	                      |	fmItemsDependencies.Item,
	                      |	fmItemsDependencies.DependentItem,
	                      |	fmItemsDependencies.Analytics1,
	                      |	fmItemsDependencies.Analytics2,
	                      |	fmItemsDependencies.Analytics3,
	                      |	fmItemsDependencies.DependentAnalytics1,
	                      |	fmItemsDependencies.DependentAnalytics2,
	                      |	fmItemsDependencies.DependentAnalytics3,
	                      |	fmItemsDependencies.DependentAnalyticsFillingVariant1,
	                      |	fmItemsDependencies.DependentAnalyticsFillingVariant2,
	                      |	fmItemsDependencies.DependentAnalyticsFillingVariant3,
	                      |	fmItemsDependencies.Percent,
	                      |	fmItemsDependencies.AlloctionByPeriodsProfile,
	                      |	fmItemsDependencies.AlloctionByPeriodsProfile.Periods.(
	                      |		Fraction,
	                      |		PeriodNumber,
	                      |		LineNumber
	                      |	),
	                      |	fmItemsDependencies.RecordType,
	                      |	fmItemsDependencies.OperationType,
	                      |	5
	                      |FROM
	                      |	InformationRegister.fmItemsDependencies AS fmItemsDependencies
	                      |WHERE
	                      |	fmItemsDependencies.BalanceUnit = Value(Catalog.fmBalanceUnits.EmptyRef)
	                      |	AND fmItemsDependencies.Department = &Department
	                      |	AND fmItemsDependencies.Scenario = Value(Catalog.fmBudgetingScenarios.EmptyRef)
	                      |	AND fmItemsDependencies.OperationType IN(&OperationType)
	                      |
	                      |UNION ALL
	                      |
	                      |SELECT
	                      |	fmItemsDependencies.Item,
	                      |	fmItemsDependencies.DependentItem,
	                      |	fmItemsDependencies.Analytics1,
	                      |	fmItemsDependencies.Analytics2,
	                      |	fmItemsDependencies.Analytics3,
	                      |	fmItemsDependencies.DependentAnalytics1,
	                      |	fmItemsDependencies.DependentAnalytics2,
	                      |	fmItemsDependencies.DependentAnalytics3,
	                      |	fmItemsDependencies.DependentAnalyticsFillingVariant1,
	                      |	fmItemsDependencies.DependentAnalyticsFillingVariant2,
	                      |	fmItemsDependencies.DependentAnalyticsFillingVariant3,
	                      |	fmItemsDependencies.Percent,
	                      |	fmItemsDependencies.AlloctionByPeriodsProfile,
	                      |	fmItemsDependencies.AlloctionByPeriodsProfile.Periods.(
	                      |		Fraction,
	                      |		PeriodNumber,
	                      |		LineNumber
	                      |	),
	                      |	fmItemsDependencies.RecordType,
	                      |	fmItemsDependencies.OperationType,
	                      |	6
	                      |FROM
	                      |	InformationRegister.fmItemsDependencies AS fmItemsDependencies
	                      |WHERE
	                      |	fmItemsDependencies.BalanceUnit = Value(Catalog.fmBalanceUnits.EmptyRef)
	                      |	AND fmItemsDependencies.Department = &Department
	                      |	AND fmItemsDependencies.Scenario = &Scenario
	                      |	AND fmItemsDependencies.OperationType IN(&OperationType)
	                      |
	                      |UNION ALL
	                      |
	                      |SELECT
	                      |	fmItemsDependencies.Item,
	                      |	fmItemsDependencies.DependentItem,
	                      |	fmItemsDependencies.Analytics1,
	                      |	fmItemsDependencies.Analytics2,
	                      |	fmItemsDependencies.Analytics3,
	                      |	fmItemsDependencies.DependentAnalytics1,
	                      |	fmItemsDependencies.DependentAnalytics2,
	                      |	fmItemsDependencies.DependentAnalytics3,
	                      |	fmItemsDependencies.DependentAnalyticsFillingVariant1,
	                      |	fmItemsDependencies.DependentAnalyticsFillingVariant2,
	                      |	fmItemsDependencies.DependentAnalyticsFillingVariant3,
	                      |	fmItemsDependencies.Percent,
	                      |	fmItemsDependencies.AlloctionByPeriodsProfile,
	                      |	fmItemsDependencies.AlloctionByPeriodsProfile.Periods.(
	                      |		Fraction,
	                      |		PeriodNumber,
	                      |		LineNumber
	                      |	),
	                      |	fmItemsDependencies.RecordType,
	                      |	fmItemsDependencies.OperationType,
	                      |	7
	                      |FROM
	                      |	InformationRegister.fmItemsDependencies AS fmItemsDependencies
	                      |WHERE
	                      |	fmItemsDependencies.BalanceUnit = &BalanceUnit
	                      |	AND fmItemsDependencies.Department = &Department
	                      |	AND fmItemsDependencies.Scenario = Value(Catalog.fmBudgetingScenarios.EmptyRef)
	                      |	AND fmItemsDependencies.OperationType IN(&OperationType)
	                      |
	                      |UNION ALL
	                      |
	                      |SELECT
	                      |	fmItemsDependencies.Item,
	                      |	fmItemsDependencies.DependentItem,
	                      |	fmItemsDependencies.Analytics1,
	                      |	fmItemsDependencies.Analytics2,
	                      |	fmItemsDependencies.Analytics3,
	                      |	fmItemsDependencies.DependentAnalytics1,
	                      |	fmItemsDependencies.DependentAnalytics2,
	                      |	fmItemsDependencies.DependentAnalytics3,
	                      |	fmItemsDependencies.DependentAnalyticsFillingVariant1,
	                      |	fmItemsDependencies.DependentAnalyticsFillingVariant2,
	                      |	fmItemsDependencies.DependentAnalyticsFillingVariant3,
	                      |	fmItemsDependencies.Percent,
	                      |	fmItemsDependencies.AlloctionByPeriodsProfile,
	                      |	fmItemsDependencies.AlloctionByPeriodsProfile.Periods.(
	                      |		Fraction,
	                      |		PeriodNumber,
	                      |		LineNumber
	                      |	),
	                      |	fmItemsDependencies.RecordType,
	                      |	fmItemsDependencies.OperationType,
	                      |	8
	                      |FROM
	                      |	InformationRegister.fmItemsDependencies AS fmItemsDependencies
	                      |WHERE
	                      |	fmItemsDependencies.BalanceUnit = &BalanceUnit
	                      |	AND fmItemsDependencies.Department = &Department
	                      |	AND fmItemsDependencies.Scenario = &Scenario
	                      |	AND fmItemsDependencies.OperationType IN(&OperationType)");
	Query.SetParameter("BalanceUnit", Object.BalanceUnit);
	Query.SetParameter("Scenario", Object.Scenario);
	Query.SetParameter("Department", Object.Department);
	OperationType = New Array;
	If Object.OperationType = Enums.fmBudgetOperationTypes.IncomesAndExpenses Then
		OperationType.Add(Enums.fmDependenciesSettingOperationTypes.IncomesAndExpensesBudget);
		OperationType.Add(Enums.fmDependenciesSettingOperationTypes.IncomesAndExpensesInCashflowBudget);
	ElsIf Object.OperationType = Enums.fmBudgetOperationTypes.Cashflows Then
		OperationType.Add(Enums.fmDependenciesSettingOperationTypes.CashflowBudget);
		OperationType.Add(Enums.fmDependenciesSettingOperationTypes.CashflowInIncomesAndExpensesBudget);
	EndIf;
	Query.SetParameter("OperationType", OperationType);
	
	Selection = Query.Execute().SELECT();
	While Selection.Next() Do
		NewLine = ItemsDependencies.Add();
		FillPropertyValues(NewLine, Selection, , "AlloctionByPeriodsProfilePeriods");
		If ValueIsFilled(Selection.AlloctionByPeriodsProfile) Then
			AlloctionByPeriodsProfilePeriods = Selection.AlloctionByPeriodsProfilePeriods.Unload();
			For Each CurPeriod In AlloctionByPeriodsProfilePeriods Do
				NewRowPeriod = NewLine.AlloctionByPeriodsProfilePeriods.Add();
				FillPropertyValues(NewRowPeriod, CurPeriod);
			EndDo;
		EndIf;
	EndDo;
	
EndProcedure

&AtServer
Procedure CalculateDependentItemsServer(CurRow, DetailsDataObject)
	
	// Проверка наличия зависимых статей в целом.
	If ItemsDependencies.Count()=0 Then Return; EndIf;
	
	DependentData = New ValueTable;
	DependentData.Columns.Add("Period", New TypeDescription("DATE", New DateQualifiers(DateFractions.DATE)));
	DependentData.Columns.Add("Item", New TypeDescription("CatalogRef.fmIncomesAndExpensesItems, CatalogRef.fmCashflowItems"));
	DependentData.Columns.Add("Analytics1", Metadata.ChartsOfCharacteristicTypes.fmAnalyticsTypes.Type);
	DependentData.Columns.Add("Analytics2", Metadata.ChartsOfCharacteristicTypes.fmAnalyticsTypes.Type);
	DependentData.Columns.Add("Analytics3", Metadata.ChartsOfCharacteristicTypes.fmAnalyticsTypes.Type);
	DependentData.Columns.Add("RecordType", New TypeDescription("EnumRef.fmBudgetFlowOperationTypes"));
	DependentData.Columns.Add("Amount", New TypeDescription("Number", New NumberQualifiers(17, 2)));
	
	// Найдем зависимые статьи.
	FoundDependencies = ItemsDependencies.FindRows(New Structure("Item", CurRow.Analytics));
	If FoundDependencies.Count() <> 0 Then 
		
		PlanningPeriodicity = Object.Scenario.PlanningPeriodicity;
		
		// Определим настройки зависимых статей.
		ItemsArray = New Array();
		For Each DependentItem In FoundDependencies Do
			ItemsArray.Add(DependentItem.DependentItem);
		EndDo;
		ItemsSettings = fmBudgeting.GetCustomAnalyticsSettings(ItemsArray);
		
		For Each CurDependence In FoundDependencies Do
			
			// Отбор зависимостей по значениям аналитик.
			If NOT (NOT ValueIsFilled(CurDependence.Analytics1) OR CurDependence.Analytics1=CurRow.Analytics1) Then
				Continue;
			ElsIf NOT (NOT ValueIsFilled(CurDependence.Analytics2) OR CurDependence.Analytics2=CurRow.Analytics2) Then
				Continue;
			ElsIf NOT (NOT ValueIsFilled(CurDependence.Analytics3) OR CurDependence.Analytics3=CurRow.Analytics3) Then
				Continue;
			EndIf;
			
			For Each DependentItemSetting In ItemsSettings Do
				If DependentItemSetting.Item = CurDependence.DependentItem Then
					ItemSetting = DependentItemSetting;
					Break;
				EndIf;
			EndDo;
			
			If ValueIsFilled(CurDependence.AlloctionByPeriodsProfile) Then
				For Each CurPeriod In CurDependence.AlloctionByPeriodsProfilePeriods Do
					NewLine = DependentData.Add();
					NewLine.Period = fmBudgeting.AddInterval(CurRow.Period, PlanningPeriodicity, CurPeriod.PeriodNumber);
					NewLine.RecordType = CurDependence.RecordType;
					NewLine.Item = CurDependence.DependentItem;
					NewLine.Amount = CurRow.Resource_Amount * (CurDependence.Percent/100) * (CurPeriod.Fraction/CurDependence.AlloctionByPeriodsProfilePeriods.Total("Fraction"));
					For Index = 1 To 3 Do
						If CurDependence["DependentAnalyticsFillingVariant"+Index]=Enums.fmDependentAnalyticsFillingVariants.FixedValue Then
							If ValueIsFilled(CurDependence["DependentAnalytics"+Index]) AND ValueIsFilled(ItemSetting["AnalyticsType"+Index]) Then
								If TypeOf(CurDependence["DependentAnalytics"+Index])=ItemSetting["AnalyticsType"+Index].Types()[0] Then
									NewLine["Analytics"+Index]=CurDependence["DependentAnalytics"+Index];
								Else
									CommonClientServer.MessageToUser(StrTemplate(NStr("en = 'Value ""%1"" of type ""%2"" cannot be set as a value ""Analytics ""%3"""" for the item ""%4"" , expected type ""%5""!'"), TrimAll(CurDependence["DependentAnalytics"+Index]), TrimAll(TypeOf(CurDependence["DependentAnalytics"+Index])), Index, TrimAll(NewLine.Item), TrimAll(ItemSetting["AnalyticsType"+Index].Types()[0])));
									Return;
								EndIf;
							EndIf;
						ElsIf NOT CurDependence["DependentAnalyticsFillingVariant"+Index]=Enums.fmDependentAnalyticsFillingVariants.DontFill Then
							AnalyticsValue=CurRow[StrReplace(String(CurDependence["DependentAnalyticsFillingVariant"+Index]), " ", "")];
							If ValueIsFilled(AnalyticsValue) AND ValueIsFilled(ItemSetting["AnalyticsType"+Index]) Then
								If TypeOf(AnalyticsValue)=ItemSetting["AnalyticsType"+Index].Types()[0] Then
									NewLine["Analytics"+Index]=AnalyticsValue;
								Else
									CommonClientServer.MessageToUser(StrTemplate(NStr("en = 'Value ""%1"" of type ""%2"" cannot be set as a value ""Analytics ""%3"""" for the item ""%4"" , expected type ""%5""!'"), TrimAll(AnalyticsValue), TypeOf(AnalyticsValue), Index, TrimAll(NewLine.Item), TrimAll(ItemSetting["AnalyticsType"+Index].Types()[0])));
									Return;
								EndIf;
							EndIf;
						EndIf;
					EndDo;
				EndDo;
			Else
				NewLine = DependentData.Add();
				NewLine.Period = CurRow.Period;
				NewLine.RecordType = CurDependence.RecordType;
				NewLine.Item = CurDependence.DependentItem;
				NewLine.Amount = CurRow.Resource_Amount * (CurDependence.Percent/100);
				For Index = 1 To 3 Do
					If CurDependence["DependentAnalyticsFillingVariant"+Index]=Enums.fmDependentAnalyticsFillingVariants.FixedValue Then
						If ValueIsFilled(CurDependence["DependentAnalytics"+Index]) AND ValueIsFilled(ItemSetting["AnalyticsType"+Index]) Then
							If TypeOf(CurDependence["DependentAnalytics"+Index])=ItemSetting["AnalyticsType"+Index].Types()[0] Then
								NewLine["Analytics"+Index]=CurDependence["DependentAnalytics"+Index];
							Else
								CommonClientServer.MessageToUser(StrTemplate(NStr("en = 'Value ""%1"" of type ""%2"" cannot be set as a value ""Analytics ""%3"""" for the item ""%4"" , expected type ""%5""!'"), TrimAll(CurDependence["DependentAnalytics"+Index]), TrimAll(TypeOf(CurDependence["DependentAnalytics"+Index])), Index, TrimAll(NewLine.Item), TrimAll(ItemSetting["AnalyticsType"+Index].Types()[0])));
								Return;
							EndIf;
						EndIf;
					ElsIf NOT CurDependence["DependentAnalyticsFillingVariant"+Index]=Enums.fmDependentAnalyticsFillingVariants.DontFill Then
						AnalyticsValue=CurRow[StrReplace(String(CurDependence["DependentAnalyticsFillingVariant"+Index]), " ", "")];
						If ValueIsFilled(AnalyticsValue) AND ValueIsFilled(ItemSetting["AnalyticsType"+Index]) Then
							If TypeOf(AnalyticsValue) =ItemSetting["AnalyticsType"+Index].Types()[0] Then
								NewLine["Analytics"+Index]=AnalyticsValue;
							Else
								CommonClientServer.MessageToUser(StrTemplate(NStr("en = 'Value ""%1"" of type ""%2"" cannot be set as a value ""Analytics ""%3"""" for the item ""%4"" , expected type ""%5""!'"), TrimAll(AnalyticsValue), TypeOf(AnalyticsValue), Index, TrimAll(NewLine.Item), TrimAll(ItemSetting["AnalyticsType"+Index].Types()[0])));
								Return;
							EndIf;
						EndIf;
					EndIf;
				EndDo;
			EndIf;
		EndDo;
	EndIf;
	
	// Создадим ТЗ с данными для дальнейшего определения координат зависимых данных.
	InitialData = New ValueTable;
	InitialData.Columns.Add("Period", New TypeDescription("DATE", New DateQualifiers(DateFractions.DATE)));
	InitialData.Columns.Add("Analytics", New TypeDescription("CatalogRef.fmIncomesAndExpensesItems, CatalogRef.fmCashflowItems"));
	InitialData.Columns.Add("Analytics1", Metadata.ChartsOfCharacteristicTypes.fmAnalyticsTypes.Type);
	InitialData.Columns.Add("Analytics2", Metadata.ChartsOfCharacteristicTypes.fmAnalyticsTypes.Type);
	InitialData.Columns.Add("Analytics3", Metadata.ChartsOfCharacteristicTypes.fmAnalyticsTypes.Type);
	InitialData.Columns.Add("RecordType", New TypeDescription("EnumRef.fmBudgetFlowOperationTypes"));
	InitialData.Columns.Add("CoordColumn_Amount", New TypeDescription("Number", New NumberQualifiers(10, 0)));
	InitialData.Columns.Add("CoordRow_Amount", New TypeDescription("Number", New NumberQualifiers(10, 0)));
	InitialData.Columns.Add("LineNumber", New TypeDescription("Number", New NumberQualifiers(15, 0)));
	LineNumber = 0;
	InitialDataVT = GetFromTempStorage(InitialDataVTAddress);
	For Each String In InitialDataVT Do
		If String.Edit Then
			NewLine = InitialData.Add();
			FillPropertyValues(NewLine, String);
			NewLine.LineNumber = LineNumber;
		EndIf;
		LineNumber = LineNumber + 1;
	EndDo;
	
	// Необходимо разделить данные на:
	// 1. Данные, которые уже отображены в дереве
	// 2. Данные, которые могут быть отражены в дереве бюджета:
	// 2.1 в структуре
	// 2.2 вне структуры
	// 3. Данные, которые не могут быть отражены:
	// 3.1 относящиеся к другому виду операции
	// 3.2 выходят за период документа
	Query = New Query("SELECT
	                      |	InitialData.Period AS Period,
	                      |	InitialData.LineNumber AS LineNumber,
	                      |	InitialData.RecordType AS RecordType,
	                      |	InitialData.Analytics AS Item,
	                      |	InitialData.Analytics1 AS Analytics1,
	                      |	InitialData.Analytics2 AS Analytics2,
	                      |	InitialData.Analytics3 AS Analytics3,
	                      |	InitialData.CoordColumn_Amount AS CoordColumn_Amount,
	                      |	InitialData.CoordRow_Amount AS CoordRow_Amount
	                      |INTO TTInitialData
	                      |FROM
	                      |	&InitialData AS InitialData
	                      |;
	                      |
	                      |////////////////////////////////////////////////////////////////////////////////
	                      |SELECT
	                      |	DependentData.Period AS Period,
	                      |	DependentData.RecordType AS RecordType,
	                      |	DependentData.Item AS Item,
	                      |	DependentData.Amount AS Amount,
	                      |	DependentData.Analytics1 AS Analytics1,
	                      |	DependentData.Analytics2 AS Analytics2,
	                      |	DependentData.Analytics3 AS Analytics3
	                      |INTO TTDependentData
	                      |FROM
	                      |	&DependentData AS DependentData
	                      |;
	                      |
	                      |////////////////////////////////////////////////////////////////////////////////
	                      |SELECT
	                      |	TTDependentData.Period AS Period,
	                      |	TTDependentData.RecordType AS RecordType,
	                      |	TTDependentData.Item AS Item,
	                      |	TTDependentData.Amount AS Amount,
	                      |	TTDependentData.Analytics1 AS Analytics1,
	                      |	TTDependentData.Analytics2 AS Analytics2,
	                      |	TTDependentData.Analytics3 AS Analytics3,
	                      |	TTInitialData.LineNumber AS LineNumber,
	                      |	TTInitialData.CoordColumn_Amount AS CoordColumn_Amount,
	                      |	TTInitialData.CoordRow_Amount AS CoordRow_Amount
	                      |FROM
	                      |	TTInitialData AS TTInitialData
	                      |		INNER JOIN TTDependentData AS TTDependentData
	                      |		ON TTInitialData.Period = TTDependentData.Period
	                      |			AND TTInitialData.RecordType = TTDependentData.RecordType
	                      |			AND TTInitialData.Item = TTDependentData.Item
	                      |			AND TTInitialData.Analytics1 = TTDependentData.Analytics1
	                      |			AND TTInitialData.Analytics2 = TTDependentData.Analytics2
	                      |			AND TTInitialData.Analytics3 = TTDependentData.Analytics3
	                      |;
	                      |
	                      |////////////////////////////////////////////////////////////////////////////////
	                      |DROP TTInitialData
	                      |;
	                      |
	                      |////////////////////////////////////////////////////////////////////////////////
	                      |DROP TTDependentData");
	
	Query.SetParameter("InitialData", InitialData);
	Query.SetParameter("DependentData", DependentData);
	Query.SetParameter("Periods", Periods);
	RecordTypes = New Array();
	If Object.OperationType=Enums.fmBudgetOperationTypes.IncomesAndExpenses Then
		RecordTypes.Add(Enums.fmBudgetFlowOperationTypes.Incomes);
		RecordTypes.Add(Enums.fmBudgetFlowOperationTypes.Expenses);
	Else
		RecordTypes.Add(Enums.fmBudgetFlowOperationTypes.Inflow);
		RecordTypes.Add(Enums.fmBudgetFlowOperationTypes.Outflow);
	EndIf;
	Query.SetParameter("RecordTypes", RecordTypes);
	
	// Данные, которые уже отображены в дереве
	DataInTree = Query.Execute().Unload();
	For Each String In DataInTree Do
		
		CurRow = InitialDataVT[String.LineNumber];
		CurRow.Resource_Amount = String.Amount;
		BudgetTree.Area(String.CoordRow_Amount, String.CoordColumn_Amount).Value = String.Amount;
		
		// Получение полей расшифровки для текущей ячейки.
		DetailsID = BudgetTree.Area(String.CoordRow_Amount, String.CoordColumn_Amount).Details;
		DetailsFieldValues = DetailsDataObject.Items[DetailsID].GetFields();
		For Each DetailsFieldValue In DetailsFieldValues Do
			If DetailsFieldValue.Field="Resource_Amount" Then
				DetailsFieldValue.Value=String.Amount;
				Break;
			EndIf;
		EndDo;
		
		// Сохраним в расшифровках новое значение.
		Try
			DetailsParentsValues	= DetailsDataObject.Items[DetailsID].GetParents();
		Except
			DetailsParentsValues	= Undefined;
		EndTry;
		NewDetailItem			= DetailsDataObject.Items.Add(Type("DataCompositionFieldDetailsItem"), DetailsParentsValues, DetailsFieldValues);
		BudgetTree.Area(String.CoordRow_Amount, String.CoordColumn_Amount).Details = NewDetailItem.ID;
		
		// Выполним частичный пересчет итогов дерева.
		ExecutePartialIterationOfBudgetsTree("Resource_Amount", CurRow);
		
	EndDo;
	
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
	DataTable.Columns.Add("Formula", New TypeDescription("String",,,, New StringQualifiers(500)));
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
	
	Query.SetParameter("SectionTable",DataTable);
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
			ParentRow = EdgeTable.FindRows(New Structure("InitialNode", Selection.FinalNote));
			If NOT ParentRow.Count()=0 Then
				ParentRow[0].IsSection = True;
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
							CurrentArea = BudgetTree.Area(ResourceRowNumber,QuartersColumns.Get(Quarter.Key));
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
					CurrentArea = BudgetTree.Area(ResourceRowNumber,3);
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
			CurrentArea = BudgetTree.Area(LineNumber,ColumnNumber);
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


////////////////////////////////////////////////////////////////////////////////
// ОБРАБОТЧИКИ СОБЫТИЙ ФОРМЫ

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If NOT ValueIsFilled(Object.Ref) AND Constants.fmDepartmentStructuresBinding.Get() Then
		Object.InfoStructure = fmBudgeting.GetBasicStructure(Object.Department, Object.OperationType);
	EndIf;
	
	FillMonthByDate(ThisForm, "Object.BeginOfPeriod", "BegOfPeriodAsString");
	FillPeriods();
	FillResources();
	FillItemsDependencies();
	
	// Заполнение реквизитов формы.
	ScenarioType = Object.Scenario.ScenarioType;
	ViewFormat = fmBudgeting.FormViewFormat(Object.InfoStructure);
	EditFormat = fmBudgeting.FormEditFormat(Object.InfoStructure);
	ConstantInputFormat = Constants.fmEditFormat.Get();
	StructureInputFormat = Object.InfoStructure.EditFormat;
	BudgetVersioning = Constants.fmBudgetVersioning.Get();
	DepartmentStructuresBinding = Constants.fmDepartmentStructuresBinding.Get();
	
	// Строка с именами колонок, по которым осуществляется поиск строки в таблице исходных данных.
	SearchColumnsRow = "Section, Analytics, Analytics1, Analytics2, Analytics3, Period";
	
	Items.LabelCurrency.Title = StrTemplate(NStr("en='Document currency: <%1>';ru='Валюта документа: <%1>'"), String(Object.Currency));
	Items.LabelStructure.Title = StrTemplate(NStr("en='Structure: <%1>';ru='Структура: <%1>'"), ?(ValueIsFilled(Object.InfoStructure), String(Object.InfoStructure), NStr("en='Without structure';ru='Без структуры'")));
	FormManagement();
	
	FillVersions();
	If Object.OperationType=Enums.fmBudgetOperationTypes.InternalSettlements Then
		FillInnerSettlements();
	Else
		FillBudgetTree();
	EndIf;
	
	// Настройки формы по функционалу согласованию.
	fmProcessManagement.SetAgreementViewOnForm(ThisForm);
	
	// Сохраним доступность кнопок.
	AgreeAvailabilityForm = Items.AgreeForm.Enabled;
	AgreementAvailability = Items.Agreement.Enabled;
	Items.LabelState.Title = GenerateStateTitle();
	CurState = fmProcessManagement.GetDocumentState(Object.Ref, CurrentVersion);
	If NOT ValueIsFilled(CurState) Then
		CurState = Catalogs.fmDocumentState.Prepared;
	EndIf;
	Items.CurState.Title = TrimAll(CurState);
	
	// Настройка печати.
	BudgetTree.PageOrientation = PageOrientation.Landscape;
	BudgetTree.FitToPage = True;
	BudgetTree.TopMargin = 0;
	BudgetTree.LeftMargin = 0;
	BudgetTree.BottomMargin = 0;
	BudgetTree.RightMargin = 0;
	
EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)
	
	FillingParameters = CurrentObject.FillingParameters.Get();
	
EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, RecordParameters)
	
	If Object.Allocation Then
		CommonClientServer.MessageToUser(NStr("en='On-line editing of documents received by allocation is not permitted.';ru='Запрещено интерактивное изменение документов, полученных путем распределения!'"), , , , Cancel);
	EndIf;
	
	If NOT SpeadsheetView Then
		FillData(CurrentObject);
	EndIf;
	
	// Сохраним параметры заполнения.
	CurrentObject.FillingParameters = New ValueStorage(FillingParameters);
	
	If RecordParameters.Property("Agreement") Then 
		CurrentObject.AdditionalProperties.Insert("Agreement", True);
	EndIf;
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	// Вызывается при закрытии формы "ФормаКурсовВалют".
	If EventName = "CurrencyRatesFormIsClosed" Then
		//Если были изменения в форме курсов валют, то обновим ТЧ "КурсыВалют"
		Object.CurrencyRates.Clear();
		For Each Item In Parameter.CurrencyRates Do
			NewLine = Object.CurrencyRates.Add();
			NewLine.Period = Item.Period;
			NewLine.Rate = Item.Rate;
			NewLine.Repetition = Item.Repetition;
		EndDo;
		Object.Currency = Parameter.Currency;
		Items.LabelCurrency.Title = NStr("en='Document currency: <';ru='Валюта документа: <'") + String(Object.Currency)+">";
		Modified = True;
	ElsIf EventName = "PredictionResult" AND Source=ThisForm Then
		If Parameter.Prediction Then
			FillingParameters = Parameter.FillingParameters;
		EndIf;
		ShowPredictionResult(Parameter.DataTableAddress, Parameter.FillingParameters.CurrentIndicator);
	EndIf;

EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, RecordParameters)
	DetermineAnalyticsTypes();
EndProcedure

&AtServer
Procedure OnWriteAtServer(Cancel, CurrentObject, RecordParameters)
	If NOT HasAgreement OR NOT RecordParameters.Property("Agreement") Then
		fmProcessManagement.SetDocumentState(CurrentObject.Ref, CurState, Object.ActualVersion, Cancel);
	EndIf;
EndProcedure


////////////////////////////////////////////////////////////////////////////////
// ОБРАБОТЧИКИ СОБЫТИЙ ЭЛЕМЕНТОВ ФОРМЫ

&AtClient
Procedure LabelCurrencyClick(Item)
	
	FormParameters = New Structure;
	FormParameters.Insert("CurrencyRates",                 Object.CurrencyRates);
	FormParameters.Insert("Scenario",                   Object.Scenario);
	FormParameters.Insert("BeginOfPeriod",              Object.BeginOfPeriod);
	FormParameters.Insert("Currency",                     Object.Currency);
	OpenForm("Document.fmBudget.Form.CurrencyRatesForm", FormParameters, , , , , , FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure ScenarioOnChange(Item)
	ScenarioOnChangeServer();
EndProcedure

&AtServer
Procedure ScenarioOnChangeServer()
	ScenarioType = Object.Scenario.ScenarioType;
	FillCurrencyRates();
	FillPeriods();
	FillItemsDependencies();
	Object.BudgetsData.Clear();
	InternalSettlements.Clear();
	FillVersions();
	FormManagement();
	If NOT Object.OperationType=Enums.fmBudgetOperationTypes.InternalSettlements Then
		FillBudgetTree();
	EndIf;
	// Настройки формы по функционалу согласованию.
	fmProcessManagement.SetAgreementViewOnForm(ThisForm);
	
	// Сохраним доступность кнопок.
	AgreeAvailabilityForm = Items.AgreeForm.Enabled;
	AgreementAvailability = Items.Agreement.Enabled;
	Items.LabelState.Title = GenerateStateTitle();
EndProcedure

&AtClient
Procedure BalanceUnitOnChange(Item)
	BalanceUnitOnChangeServer();
EndProcedure

&AtServer
Procedure BalanceUnitOnChangeServer()
	fmBudgeting.BalanceUnitDepartmentCompatible(Object.BalanceUnit, Object.Department, Object.BeginOfPeriod, "Department");
	FillItemsDependencies();
EndProcedure

&AtClient
Procedure DepartmentOnChange(Item)
	DepartmentOnChangeServer();
EndProcedure

&AtServer
Procedure DepartmentOnChangeServer()
	fmBudgeting.BalanceUnitDepartmentCompatible(Object.BalanceUnit, Object.Department, Object.BeginOfPeriod, "BalanceUnit");
	FillItemsDependencies();
	If Constants.fmDepartmentStructuresBinding.Get() Then
		InfoStructure = fmBudgeting.GetBasicStructure(Object.Department, Object.OperationType);
		If ValueIsFilled(InfoStructure) Then
			Object.InfoStructure = InfoStructure;
			Items.LabelStructure.Title = StrTemplate(NStr("en='Structure: <%1>';ru='Структура: <%1>'"), String(Object.InfoStructure));
			If (Object.OperationType=Enums.fmBudgetOperationTypes.IncomesAndExpenses OR Object.OperationType=Enums.fmBudgetOperationTypes.Cashflows)
			AND NOT SpeadsheetView Then
				ViewFormat = fmBudgeting.FormViewFormat(Object.InfoStructure);
				EditFormat = fmBudgeting.FormEditFormat(Object.InfoStructure);
				StructureInputFormat = Object.InfoStructure.EditFormat;
				FillPeriods();
				FillBudgetTree();
			EndIf;
		EndIf;
	EndIf;
	// Настройки формы по функционалу согласованию.
	fmProcessManagement.SetAgreementViewOnForm(ThisForm);
	
	// Сохраним доступность кнопок.
	AgreeAvailabilityForm = Items.AgreeForm.Enabled;
	AgreementAvailability = Items.Agreement.Enabled;
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

&AtClient
Procedure BudgetTreeAreaContentOnChange(Item, Region)
	Region.Details = ProcessAreaContentChangeAtServer(Region.Details, Region.Value);
EndProcedure

&AtClient
Procedure OperationTypeOnChange(Item)
	OperationTypeOnChangeServer();
EndProcedure

&AtServer
Procedure OperationTypeOnChangeServer()
	FormManagement();
	If Constants.fmDepartmentStructuresBinding.Get() Then
		Object.InfoStructure = fmBudgeting.GetBasicStructure(Object.Department, Object.OperationType);
	Else
		Object.InfoStructure = Catalogs.fmInfoStructures.EmptyRef();
	EndIf;
	Items.LabelStructure.Title = StrTemplate(NStr("en='Structure: <%1>';ru='Структура: <%1>'"), ?(ValueIsFilled(Object.InfoStructure), String(Object.InfoStructure), NStr("en='Without structure';ru='Без структуры'")));
	Object.BudgetsData.Clear();
	If Object.OperationType=Enums.fmBudgetOperationTypes.InternalSettlements Then
		FillInnerSettlements();
	Else
		FillBudgetTree();
	EndIf;
	FillItemsDependencies();
EndProcedure

&AtClient
Procedure SpeadsheetView(Command)
	// Пометку меняем в первую очередь.
	Items.FormatTabularView.Check = NOT Items.FormatTabularView.Check;
	SpeadsheetView = Items.FormatTabularView.Check;
	TabularViewServer();
EndProcedure

&AtServer
Procedure TabularViewServer()
	FormManagement();
	If SpeadsheetView Then
		FillData(Object);
	Else
		If Object.OperationType=Enums.fmBudgetOperationTypes.InternalSettlements Then
			FillInnerSettlements();
		Else
			FillBudgetTree();
		EndIf;
	EndIf;
EndProcedure

&AtClient
Procedure IndicatorsVersion(Command)
	CurrentVersion = DATE(Right(Command.Name, 8));
	IndicatorsVersionServer();
EndProcedure

&AtServer
Procedure IndicatorsVersionServer()
	
	Items.VersionSubmenu.Title = NStr("en='Current budget version <';ru='Текущая версия бюджета <'") + Format(CurrentVersion, VersionDateFormat)+">";
	If Object.OperationType=Enums.fmBudgetOperationTypes.InternalSettlements Then
		FillInnerSettlements();
	Else
		FillBudgetTree();
	EndIf;
	ReadOnly = Object.ActualVersion<>CurrentVersion;
	Items.AddCommentBudgetTree.Enabled = Not ReadOnly;
	Items.LabelState.Title = GenerateStateTitle();
	
	If CurrentVersion=Object.ActualVersion Then
		Items.AgreeForm.Enabled = AgreeAvailabilityForm;
		Items.Agreement.Enabled = AgreementAvailability;
		Items.CurState.Title = TrimAll(CurState);
		Items.CurState.Hyperlink = True;
	Else
		Items.AgreeForm.Enabled = False;
		Items.Agreement.Enabled = False;
		Items.CurState.Title = TrimAll(fmProcessManagement.GetDocumentState(Object.Ref, CurrentVersion));
		Items.CurState.Hyperlink = HasAgreement;
	EndIf;
	
EndProcedure

&AtClient
Procedure Add(Command)
	
	CurrentArea = Items.BudgetTree.CurrentArea;
	If CurrentArea = Undefined Then
		CommonClientServer.MessageToUser(NStr("en='It is impossible to add a row for the selected area.';ru='Добавление строки для выделенной области невозможно!'"));
		Return;
	EndIf;
	
	// Параметры лежат в 1-ой колонке, строка должна делиться без остатка на количество ресурсов.
	CurTop = DetermineTopCoord(CurrentArea.Top, Resources.Count());
	CurrentArea = BudgetTree.Area(CurTop, 1, CurTop, 1);
	
	// Проверка наличия расшифровки, иначе не добавить строку.
	If CurrentArea.Details=Undefined Then
		CommonClientServer.MessageToUser(NStr("en='It is impossible to add a row for the selected area.';ru='Добавление строки для выделенной области невозможно!'"));
		Return;
	EndIf;
	
	CurParameters = CheckGetAddParameters(CurrentArea.Details, DetailsData, Command.Name, Object.OperationType);
	If NOT CurParameters.Cancel Then
		If ValueIsFilled(CurParameters.FullName) Then
			OpenForm(CurParameters.FullName+".ChoiceForm", , ThisForm, , , , New NotifyDescription("AnalyticsChoiceEnd", ThisForm, CurParameters), FormWindowOpeningMode.LockOwnerWindow);
		Else
			CommonClientServer.MessageToUser(NStr("en='The dimension is not defined.';ru='Аналитика не определена!'"));
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure AnalyticsChoiceEnd(Result, AddParameters) Export
	If NOT Result = Undefined Then
		SearchStructure = New Structure("Analytics, Analytics1, Analytics2, Analytics3");
		FillPropertyValues(SearchStructure, AddParameters);
		SearchStructure[AddParameters.AnalyticsName]=Result;
		AnalyticsChoiceEndServer(Result, AddParameters, SearchStructure);
	EndIf;
EndProcedure

&AtServer
Procedure AnalyticsChoiceEndServer(Result, AddParameters, SearchStructure)
	InitialDataVT = GetFromTempStorage(InitialDataVTAddress);
	FoundRows = InitialDataVT.FindRows(SearchStructure);
	If FoundRows.Count() Then
		MessageText = NStr("en='The selected dimension ""%1"" has already been specified!';ru='Выбранная аналитика ""%1"" уже указана!'");
		MessageText = StringFunctionsClientServer.SubstituteParametersToString(MessageText, TrimAll(Result));
		CommonClientServer.MessageToUser(MessageText);
	Else
		AddRowAtServer(Result, AddParameters);
	EndIf;
EndProcedure

&AtClient
Procedure StructureChoiceEnd(Result, AdditionalParameters) Export
	If TypeOf(Result) = Type("CatalogRef.fmInfoStructures") Then
		Object.InfoStructure = Result;
		Items.LabelStructure.Title = StrTemplate(NStr("en='Structure: <%1>';ru='Структура: <%1>'"), ?(ValueIsFilled(Object.InfoStructure), String(Object.InfoStructure), NStr("en='Without structure';ru='Без структуры'")));
		Modified = True;
		StructureChoiceEndServer();
	EndIf;
EndProcedure

&AtServer
Procedure StructureChoiceEndServer()
	ViewFormat = fmBudgeting.FormViewFormat(Object.InfoStructure);
	EditFormat = fmBudgeting.FormEditFormat(Object.InfoStructure);
	StructureInputFormat = Object.InfoStructure.EditFormat;
	FillPeriods();
	FillBudgetTree();
EndProcedure

&AtServer
Procedure AddRowAtServer(Analytics, AddParameters)
	
	CurrentArea = Items.BudgetTree.CurrentArea;
	
	// После добавления строки нужно будет сдвинуть координаты ячеек, находящихся ниже на это количество строк.
	Shift = Resources.Count();
	
	CurrentArea = Items.BudgetTree.CurrentArea;
	// Параметры лежат в 1-ой колонке, строка должна делиться без остатка на количество ресурсов.
	CurTop = DetermineTopCoord(CurrentArea.Top, Resources.Count());
	CurrentArea = BudgetTree.Area(CurTop, 1, CurTop, 1);
	
	// Получение объекта данных расшифровки.
	DetailsDataObject = GetFromTempStorage(DetailsData);
	DetailsFields = DetailsDataObject.Items[CurrentArea.Details].GetFields();
	Section			= DetailsFields.Find("Section");
	SectionParent = DetailsFields.Find("SectionParent").Value;
	InfoStructure = Section.Value.Owner;
	RowID = "D" + Format(MaximumRowID, "ND=29; NLZ=; NG=");
	MaximumRowID = MaximumRowID + 1;
	
	// Структура поиска родительской строки для вставки.
	SearchStructure = New Structure(SearchColumnsRow);
	SearchStructure.Section			= Section.Value;
	SearchStructure.Period = Object.BeginOfPeriod;
	FillPropertyValues(SearchStructure, AddParameters);
	SearchStructure[AddParameters.AnalyticsName] = Undefined;
	InitialDataVT = GetFromTempStorage(InitialDataVTAddress);
	RowParent = InitialDataVT.FindRows(SearchStructure)[0];
	
	// Получим макет для вывода.
	AreaTemplate				= Documents.fmBudget.GetTemplate("TreeAreaTemplate");	// Макет области для вставки строки.
	GroupArea			= AreaTemplate.Area("Group"+Shift);	// Область с представлением статьи.
	Indent = 0;
	CurSectionParent = Section.Value;
	While ValueIsFilled(CurSectionParent) Do
		Indent = Indent + 2;
		CurSectionParent = CurSectionParent.Parent;
	EndDo;
	If AddParameters.AnalyticsName="Analytics1" Then
		Indent = Indent + 2;
	ElsIf AddParameters.AnalyticsName="Analytics2" Then
		Indent = Indent + 4;
	ElsIf AddParameters.AnalyticsName="Analytics3" Then
		Indent = Indent + 6;
	EndIf;
	GroupArea.Text	= String(Analytics);// Замена имени области
	GroupArea.Indent = Indent;
	For Each CurResource In Resources Do
		AreaResource			= AreaTemplate.Area("Resource"+String(Shift)+Resources.IndexOf(CurResource));	// Область с представлением статьи.
		AreaResource.Text		= CurResource.Presentation;					// Замена имени области
	EndDo;
	
	AreaNewString			= AreaTemplate.Area("Row" + Shift);	// Вставляемая строка.
	// Получение родительский ячейки. Вставка новой строки будет происходить ниже этой ячейки.
	CoordinateRow	= RowParent["CoordRow_" + Resources[Shift-1].Value] + 1;
	AreaParent = BudgetTree.Area(CoordinateRow, 1, CoordinateRow, 1);
	// Вставляем новую строку.
	BudgetTree.InsertArea(AreaNewString, AreaParent, SpreadsheetDocumentShiftType.Vertical);
	NewArea = BudgetTree.Area(CoordinateRow, 1, CoordinateRow, 1);
	// Создадим расшифровку для новой строки.
	DetailsFieldValues = New DataCompositionDetailsFieldValues();
	// Аналитика.
	DetailsFieldValue = DetailsFieldValues.Add();
	DetailsFieldValue.Field = "Analytics";
	DetailsFieldValue.Value = ?(DetailsFieldValue.Field=AddParameters.AnalyticsName, Analytics, RowParent.Analytics);
	// Аналитик1.
	DetailsFieldValue = DetailsFieldValues.Add();
	DetailsFieldValue.Field = "Analytics1";
	DetailsFieldValue.Value = ?(DetailsFieldValue.Field=AddParameters.AnalyticsName, Analytics, RowParent.Analytics1);
	// Аналитик1.
	DetailsFieldValue = DetailsFieldValues.Add();
	DetailsFieldValue.Field = "Analytics2";
	DetailsFieldValue.Value = ?(DetailsFieldValue.Field=AddParameters.AnalyticsName, Analytics, RowParent.Analytics2);
	// Аналитик3.
	DetailsFieldValue = DetailsFieldValues.Add();
	DetailsFieldValue.Field = "Analytics3";
	DetailsFieldValue.Value = ?(DetailsFieldValue.Field=AddParameters.AnalyticsName, Analytics, RowParent.Analytics3);
	// Раздел.
	DetailsFieldValue = DetailsFieldValues.Add();
	DetailsFieldValue.Field = "Section";
	DetailsFieldValue.Value = RowParent.Section;
	// Родитель раздела.
	DetailsFieldValue = DetailsFieldValues.Add();
	DetailsFieldValue.Field = "SectionParent";
	DetailsFieldValue.Value = RowParent.SectionParent;
	// ВидДвижения.
	DetailsFieldValue = DetailsFieldValues.Add();
	DetailsFieldValue.Field = "RecordType";
	DetailsFieldValue.Value = RowParent.RecordType;
	// Порядок.
	DetailsFieldValue = DetailsFieldValues.Add();
	DetailsFieldValue.Field = "Order";
	DetailsFieldValue.Value = RowParent.Order;
	// Редактирование.
	DetailsFieldValue = DetailsFieldValues.Add();
	DetailsFieldValue.Field = "Edit";
	DetailsFieldValue.Value = True;
	// ИмяАналитики.
	DetailsFieldValue = DetailsFieldValues.Add();
	DetailsFieldValue.Field = "AnalyticsName";
	DetailsFieldValue.Value = AddParameters.AnalyticsName;
	// Ид родителя.
	DetailsFieldValue = DetailsFieldValues.Add();
	DetailsFieldValue.Field = "ParentID";
	DetailsFieldValue.Value = RowParent.RowID;
	// Ид Строки.
	DetailsFieldValue = DetailsFieldValues.Add();
	DetailsFieldValue.Field = "RowID";
	DetailsFieldValue.Value = RowID;
	
	Try
		DetailsParentsValues	= DetailsDataObject.Items[NewArea.Details].GetParents();
	Except
		DetailsParentsValues	= Undefined;
	EndTry;
	NewDetailItem			= DetailsDataObject.Items.Add(Type("DataCompositionFieldDetailsItem"), DetailsParentsValues, DetailsFieldValues);
	NewArea.Details	= NewDetailItem.ID;
	
	If AddParameters.CommandName="AddChild" AND NOT AddParameters.AnalyticsName="Analytics" Then
		// Получение родительский ячейки. Вставка новой строки будет происходить ниже этой ячейки.
		CoordinateRowParent = RowParent["CoordRow_" + Resources[0].Value];
		AreaParent = BudgetTree.Area(CoordinateRowParent, 1, CoordinateRowParent, 1);
		// Получение данных расшифровки.
		CurParentDetailsFields = DetailsDataObject.Items[AreaParent.Details].GetFields();
		Edit = CurParentDetailsFields.Find("Edit");
		Edit.Value = False;
		Try
			DetailsParentsValues	= DetailsDataObject.Items[AreaParent.Details].GetParents();
		Except
			DetailsParentsValues	= Undefined;
		EndTry;
		NewDetailItem			= DetailsDataObject.Items.Add(Type("DataCompositionFieldDetailsItem"), DetailsParentsValues, CurParentDetailsFields);
		AreaParent.Details	= NewDetailItem.ID;
	EndIf;
	
	// Добавление колонок в макет и строк в исходную ТЗ.
	CurArea = BudgetTree.Area(CoordinateRow, 4);
	// Вставляемая область-колонка.
	AreaNewColumn = AreaTemplate.Area("Column" + Shift + "|Column");
	AreaNewColumnTotal = AreaTemplate.Area("Column" + Shift + "|ColumnTotal");
	For Each CurPeriod In Periods Do
		
		If ColumnGroup AND (Periods.IndexOf(CurPeriod)%3=0) Then
			// Вставляем новую колонку групировку.
			BudgetTree.InsertArea(AreaNewColumnTotal, CurArea);
			CurArea = BudgetTree.Area(CoordinateRow, 5+Periods.IndexOf(CurPeriod)+?(ColumnGroup, Int(Periods.IndexOf(CurPeriod)/3), 0));
		EndIf;
		
		// Вставляем новую колонку.
		BudgetTree.InsertArea(AreaNewColumn, CurArea);
		CurArea = BudgetTree.Area(CoordinateRow, 5+Periods.IndexOf(CurPeriod)+?(ColumnGroup, Int(Periods.IndexOf(CurPeriod)/3)+1, 0));
		// Вставляем новую строку в ТЗ.
		NewLine			= InitialDataVT.Add();
		FillPropertyValues(NewLine, RowParent);
		NewLine[AddParameters.AnalyticsName] = Analytics;
		NewLine.Period	= CurPeriod.Value;
		NewLine.Section	= RowParent.Section;
		NewLine.RecordType	= RowParent.RecordType;
		NewLine.SectionParent	= RowParent.SectionParent;
		NewLine.Order = RowParent.Order;
		NewLine.RowID = RowID;
		NewLine.ParentID = RowParent.RowID;
		For Each CurResourceName In Resources Do
			NewLine["CoordRow_"+CurResourceName.Value] = RowParent["CoordRow_"+CurResourceName.Value] + Shift;
			NewLine["CoordColumn_"+CurResourceName.Value] = 4+Periods.IndexOf(CurPeriod)+?(ColumnGroup, Int(Periods.IndexOf(CurPeriod)/3)+1, 0);
			CurValue = 0;
			If AddParameters.CommandName="AddChild" AND NOT AddParameters.AnalyticsName="Analytics" Then
				// Получим родительскую область и запретим редактирование.
				CurParentArea = BudgetTree.Area(NewLine["CoordRow_"+CurResourceName.Value]-Shift, NewLine["CoordColumn_"+CurResourceName.Value]);
				// Получение данных расшифровки.
				CurParentDetailsFields = DetailsDataObject.Items[CurParentArea.Details].GetFields();
				CurValue = CurParentDetailsFields.Find("Resource_"+CurResourceName.Value).Value;
				CurParentArea.Protection = True;
				CurParentArea.BackColor			= WebColors.White;
				Try
					DetailsParentsValues	= DetailsDataObject.Items[CurParentArea.Details].GetParents();
				Except
					DetailsParentsValues	= Undefined;
				EndTry;
				NewDetailItem			= DetailsDataObject.Items.Add(Type("DataCompositionFieldDetailsItem"), DetailsParentsValues, CurParentDetailsFields);
				CurParentArea.Details	= NewDetailItem.ID;
			EndIf;
			
			// Текущая ячейка.
			CurrentAreaNew = BudgetTree.Area(NewLine["CoordRow_"+CurResourceName.Value], NewLine["CoordColumn_"+CurResourceName.Value], NewLine["CoordRow_"+CurResourceName.Value], NewLine["CoordColumn_"+CurResourceName.Value]);
			If CurrentAreaNew.Details = Undefined Then
				Continue;
			EndIf;
			
			// Создадим расшифровку для каждой новой ячейки.
			DetailsFieldValues = New DataCompositionDetailsFieldValues();
			// Ресурс.
			DetailsFieldValue = DetailsFieldValues.Add();
			DetailsFieldValue.Field = "Resource_"+CurResourceName.Value;
			DetailsFieldValue.Value = CurValue;
			// Период.
			DetailsFieldValue = DetailsFieldValues.Add();
			DetailsFieldValue.Field = "Period";
			DetailsFieldValue.Value = CurPeriod.Value;
			
			// Для каждой ячейки у которой были данные расшифровки необходимо создать новый элемент расшифровки и поместить измененные значения полей.
			NewDetailItem			= DetailsDataObject.Items.Add(Type("DataCompositionFieldDetailsItem"), Undefined, DetailsFieldValues);
			CurrentAreaNew.Value	= CurValue;
			CurrentAreaNew.Details	= NewDetailItem.ID;
			CurrentAreaNew.Format	= ViewFormat;
			CurrentAreaNew.EditFormat	= EditFormat;
			
		EndDo;
		
	EndDo;
	
	// Определим необходимость группировки в макете.
	AreRowsInSection = False;
	CurAnalyticsValue = SearchStructure[AddParameters.AnalyticsName];
	SearchStructure.Delete(AddParameters.AnalyticsName);
	SearchStructure.Insert("Edit", True);
	If AddParameters.AnalyticsName="Analytics" Then
		SearchStructure.Delete("Analytics1");
		SearchStructure.Delete("Analytics2");
		SearchStructure.Delete("Analytics3");
	ElsIf AddParameters.AnalyticsName="Analytics1" Then
		SearchStructure.Delete("Analytics2");
		SearchStructure.Delete("Analytics3");
	ElsIf AddParameters.AnalyticsName="Analytics2" Then
		SearchStructure.Delete("Analytics3");
	EndIf;
	FoundRows = InitialDataVT.FindRows(SearchStructure);
	For Each CurRow In FoundRows Do
		If CurRow[AddParameters.AnalyticsName]<>CurAnalyticsValue Then
			AreRowsInSection = True;
			Break;
		EndIf;
	EndDo;
	
	// Группировка в случае, если это первая строка.
	If NOT AreRowsInSection Then
		BudgetTree.Area(CoordinateRow, , CoordinateRow+Shift-1).Group();
	EndIf;
	
	// Поработали с данными расшифровки, вернем их обратно.
	DetailsData = PutToTempStorage(DetailsDataObject, UUID);
	
	// Сохраним значения новой строки для расчета итогов.
	NewLineStructure = New Structure();
	For Each CurColumn In InitialDataVT.Columns Do
		NewLineStructure.Insert(CurColumn.Name, NewLine[CurColumn.Name]);
	EndDo;
	
	// Перезаполним таблицу на основании макета.
	InitialDataVT.Clear();
	DetailsFieldsRow = SearchColumnsRow + ", RowID, ParentID";
	
	// Обход каждой ячейки табличного документа.
	For AreaRow = 2 To BudgetTree.TableHeight Do
		For AreaColumn = 1 To BudgetTree.TableWidth Do
			
			CurrentArea = BudgetTree.Area(AreaRow, AreaColumn, AreaRow, AreaColumn);
			
			If CurrentArea.Details = Undefined Then
				Continue;
			EndIf;
			
			// Получение структуры значений расшифровки.
			DetailsTotalValues = DetailsDataObject.Items[CurrentArea.Details].GetFields();
			
			// Если в расшифровке есть ресурс.
			// Часть параметров лежит в 1-ой колонке, строка должна делиться без остатка на количество ресурсов.
			If AreaColumn=1 AND (AreaRow-2)%Resources.Count()=0 Then
				
				CurEdit = False;
				CurRecordType = Enums.fmBudgetFlowOperationTypes.EmptyRef();
				CurSectionParent = Catalogs.fmInfoStructuresSections.EmptyRef();
				
				// Заполняем структуру с аналитиками, которая соответсвтует текущей ячейке.
				FS = New Structure(DetailsFieldsRow);
				For Each DetailsFieldValue In DetailsTotalValues Do
					If DetailsFieldValue.Field="Analytics" OR DetailsFieldValue.Field="Section"
					OR DetailsFieldValue.Field="Analytics1" OR DetailsFieldValue.Field="Analytics2" OR DetailsFieldValue.Field="Analytics3"
					OR DetailsFieldValue.Field="RowID" OR DetailsFieldValue.Field="ParentID" Then
						FS[DetailsFieldValue.Field] = DetailsFieldValue.Value;
					EndIf;
					If DetailsFieldValue.Field="Edit" Then
						CurEdit = DetailsFieldValue.Value;
					EndIf;
					If DetailsFieldValue.Field="RecordType" Then
						CurRecordType = DetailsFieldValue.Value;
					EndIf;
					If DetailsFieldValue.Field="Order" Then
						CurOrder = DetailsFieldValue.Value;
					EndIf;
					If DetailsFieldValue.Field="SectionParent" Then
						CurSectionParent = DetailsFieldValue.Value;
					EndIf;
				EndDo;
				
			ElsIf DetailsTotalValues.Find("Resource_Amount") <> Undefined Then
				
				// Если в расшифровке есть ресурс.
				CurResourceName = "";
				For Each DetailsFieldValue In DetailsTotalValues Do
					If DetailsFieldValue.Field="Period" Then
						FS[DetailsFieldValue.Field] = DetailsFieldValue.Value;
					EndIf;
					If Find(DetailsFieldValue.Field, "Resource_") Then
						CurResourceName = DetailsFieldValue.Field;
					EndIf;
				EndDo;
				
				If DetailsTotalValues.Count() Then
					AllNulls = True;
					For Each DetailsFieldValue In DetailsTotalValues Do
						If FS.Property(DetailsFieldValue.Field) AND FS[DetailsFieldValue.Field] <> NULL Then
							AllNulls = False;
						EndIf;
					EndDo;
					// Значения полей расшифровки есть, но они не заполнены.
					If AllNulls Then
						Continue;
					EndIf;
				EndIf;
				
				// Поиск группировки квартал в родительских, если найдена, значит редактировать такую ячейку нельзя.
				ParentDetails = DetailsDataObject.Items[CurrentArea.Details].GetParents();
				If ParentDetails.Count() Then
					ParentFieldsValues = DetailsDataObject.Items[ParentDetails[0].ID].GetFields();
					For Each CurParentFieldValue In ParentFieldsValues Do
						If Find(CurParentFieldValue.Field, "Quarter") Then
							CurrentArea.Details = Undefined;
							Break;
						EndIf;
					EndDo;
					If CurrentArea.Details = Undefined Then
						Continue;
					EndIf;
				EndIf;
				
				// Создадим новую строку ТЗ.
				CurNewRow = InitialDataVT.Add();
				FillPropertyValues(CurNewRow, FS);
				CurNewRow["CoordColumn_"+StrReplace(CurResourceName, "Resource_", "")] = AreaColumn;
				CurNewRow["CoordRow_"+StrReplace(CurResourceName, "Resource_", "")] = AreaRow;
				CurNewRow[CurResourceName] = CurrentArea.Value;
				CurNewRow.SectionParent = CurSectionParent;
				CurNewRow.Edit = CurEdit;
				CurNewRow.RecordType = CurRecordType;
				CurNewRow.Order = CurOrder;
				
			EndIf;
			
		EndDo;
	EndDo;
	
	InitialDataVTAddress = PutToTempStorage(InitialDataVT, UUID);
	
	// Дополним Таблицу ребер новыми значениями и обновим значение по дереву.
	GenerateEdgeTable(False, NewLineStructure);
	ExecutePartialIterationOfBudgetsTreeByRow(NewLineStructure);
	
EndProcedure

&AtClient
Procedure Delete(Command)
	
	CurrentArea = Items.BudgetTree.CurrentArea;
	If CurrentArea = Undefined Then
		CommonClientServer.MessageToUser(NStr("en='You cannot delete a row of the selected area.';ru='Удаление строки для выделенной области невозможно!'"));
		Return;
	EndIf;
	// Проверка наличия расшифровки, иначе не добавить строку.
	Try
		CurrentAreaDetails = CurrentArea.Details;
	Except
		CurrentAreaDetails = Undefined;
	EndTry;
	If CurrentAreaDetails=Undefined Then
		CommonClientServer.MessageToUser(NStr("en='You cannot delete a row of the selected area.';ru='Удаление строки для выделенной области невозможно!'"));
		Return;
	EndIf;
	DeleteRowAtServer();
	
EndProcedure

&AtServer
Procedure DeleteRowAtServer()
	
	// Получение данных расшифровки.
	DetailsDataObject = GetFromTempStorage(DetailsData);
	
	CurrentArea = Items.BudgetTree.CurrentArea;
	// Основные параметры лежат в 1-ой колонке, строка должна делиться без остатка на количество ресурсов.
	CurTop = DetermineTopCoord(CurrentArea.Top, Resources.Count());
	CurrentArea = BudgetTree.Area(CurTop, 1, CurTop, 1);
	
	// Получение полей расшифровки для текущей ячейки.
	FS = New Structure(SearchColumnsRow);
	Edit = False;
	AnalyticsName = "";
	DetailsFieldValues = DetailsDataObject.Items[CurrentArea.Details].GetFields();
	For Each DetailsFieldValue In DetailsFieldValues Do
		If Find(SearchColumnsRow, DetailsFieldValue.Field) Then
			FS[DetailsFieldValue.Field] = DetailsFieldValue.Value;
		EndIf;
		If DetailsFieldValue.Field="Edit" Then
			Edit = DetailsFieldValue.Value;
		EndIf;
		If DetailsFieldValue.Field="AnalyticsName" Then
			AnalyticsName = DetailsFieldValue.Value;
		EndIf;
	EndDo;
	FS.Delete("Period");
	
	// Проверим возможность редактирования.
	If AnalyticsName="Section" Then
		CommonClientServer.MessageToUser(NStr("en='You cannot delete a row of the selected area.';ru='Удаление строки для выделенной области невозможно!'"));
		Return;
	EndIf;
	InfoStructure = FS.Section.Owner;
	If NOT (InfoStructure = Catalogs.fmInfoStructures.WithoutStructureIE OR InfoStructure = Catalogs.fmInfoStructures.OutOfStructureIE
	OR InfoStructure = Catalogs.fmInfoStructures.WithoutStructureCF OR InfoStructure = Catalogs.fmInfoStructures.OutOfStructureCF) 
	AND NOT (AnalyticsName="Analytics1" OR AnalyticsName="Analytics2" OR AnalyticsName="Analytics3") Then
		CommonClientServer.MessageToUser(NStr("en='You cannot delete a row of the selected area.';ru='Удаление строки для выделенной области невозможно!'"));
		Return;
	EndIf;
	
	InitialDataVT = GetFromTempStorage(InitialDataVTAddress);
	If AnalyticsName="Analytics" Then
		FS.Delete("Analytics1");
		FS.Delete("Analytics2");
		FS.Delete("Analytics3");
		FoundRows = InitialDataVT.FindRows(FS);
		// Удалим данные по удаляемой области.
		For Each CurRow In FoundRows Do
			InitialDataVT.Delete(CurRow);
		EndDo;
	Else
		AnalyticsNum = Number(Right(AnalyticsName, 1));
		CurSS = New Structure(New FixedStructure(FS));
		For Num=AnalyticsNum To 3 Do
			CurSS.Delete("Analytics"+Num);
		EndDo;
		FoundRows = InitialDataVT.FindRows(CurSS);
		// Проанализируем данные по удаляемой области.
		IsAnalytics=False;
		For Each CurRow In FoundRows Do
			If CurRow.Edit AND CurRow[AnalyticsName]<>FS[AnalyticsName] Then
				IsAnalytics=True;
				Break;
			EndIf;
		EndDo;
		If IsAnalytics Then
			For Each CurRow In FoundRows Do
				If CurRow.Edit AND CurRow[AnalyticsName]=FS[AnalyticsName] Then
					InitialDataVT.Delete(CurRow);
				EndIf;
			EndDo;
		Else
			For Each CurRow In FoundRows Do
				If CurRow.Edit Then
					For Num=AnalyticsNum To 3 Do
						CurRow["Analytics"+Num]=Undefined;
					EndDo;
				EndIf;
			EndDo;
		EndIf;
	EndIf;
	
	InitialDataVTAddress = PutToTempStorage(InitialDataVT, UUID);
	
	// Перестроим дерево.
	FillData(Object);
	FillBudgetTree();
	
EndProcedure

&AtClient
Procedure CopyValue(Command)
	
	CurrentArea = Items.BudgetTree.CurrentArea;
	If CurrentArea = Undefined Then
		CommonClientServer.MessageToUser(NStr("en='Adopting values is not available for the selected area!';ru='Копирование значения для выделенной области невозможно!'"));
		Return;
	EndIf;
	// Проверка наличия расшифровки.
	If CurrentArea.Details=Undefined Then
		CommonClientServer.MessageToUser(NStr("en='Adopting values is not available for the selected area!';ru='Копирование значения для выделенной области невозможно!'"));
		Return;
	EndIf;
	
	CopyAllPeriodsServer();
	
EndProcedure

&AtServer
Procedure CopyAllPeriodsServer()
	
	CurrentArea = Items.BudgetTree.CurrentArea;
	CurrentAreaValue = CurrentArea.Value;
	
	// Получение данных расшифровки.
	DetailsDataObject = GetFromTempStorage(DetailsData);
	
	// Получение полей расшифровки для текущей ячейки.
	DetailsFieldValues = DetailsDataObject.Items[CurrentArea.Details].GetFields();
	
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
	PeriodValue = FS.Period;
	
	// Основные параметры лежат в 1-ой колонке, строка должна делиться без остатка на количество ресурсов.
	Edit = False;
	CurTop = DetermineTopCoord(CurrentArea.Top, Resources.Count());
	CurrentArea = BudgetTree.Area(CurTop, 1, CurTop, 1);
	ParametersDetailsFieldValues = DetailsDataObject.Items[CurrentArea.Details].GetFields();
	For Each DetailsFieldValue In ParametersDetailsFieldValues Do
		If Find(SearchColumnsRow, DetailsFieldValue.Field) Then
			FS[DetailsFieldValue.Field] = DetailsFieldValue.Value;
		EndIf;
		If DetailsFieldValue.Field="Edit" Then
			Edit = DetailsFieldValue.Value;
		EndIf;
	EndDo;
	PeriodValue = FS.Period;
	FS.Delete("Period");
	
	// Проверим возможность редактирования для области.
	If NOT Edit Then
		CommonClientServer.MessageToUser(NStr("en='Adopting values is not available for the selected area!';ru='Копирование значения для выделенной области невозможно!'"));
		Return;
	EndIf;
	
	// Структура поиска строки.
	InitialDataVT = GetFromTempStorage(InitialDataVTAddress);
	String = InitialDataVT.FindRows(FS);
	For Each CurRow In String Do
		If CurRow.Period > PeriodValue Then
			CurRow[ResourceName] = CurrentAreaValue;
			BudgetTree.Area(CurRow[StrReplace(ResourceName, "Resource_", "CoordRow_")], CurRow[StrReplace(ResourceName, "Resource_", "CoordColumn_")]).Value = CurrentAreaValue;
			// Получение полей расшифровки для текущей ячейки.
			DetailsID = BudgetTree.Area(CurRow[StrReplace(ResourceName, "Resource_", "CoordRow_")], CurRow[StrReplace(ResourceName, "Resource_", "CoordColumn_")]).Details;
			DetailsFieldValues = DetailsDataObject.Items[DetailsID].GetFields();
			For Each DetailsFieldValue In DetailsFieldValues Do
				If DetailsFieldValue.Field=ResourceName Then
					DetailsFieldValue.Value=CurrentAreaValue;
					Break;
				EndIf;
			EndDo;
			// Сохраним в расшифровках новое значение.
			Try
				DetailsParentsValues	= DetailsDataObject.Items[DetailsID].GetParents();
			Except
				DetailsParentsValues	= Undefined;
			EndTry;
			NewDetailItem			= DetailsDataObject.Items.Add(Type("DataCompositionFieldDetailsItem"), DetailsParentsValues, DetailsFieldValues);
			BudgetTree.Area(CurRow[StrReplace(ResourceName, "Resource_", "CoordRow_")], CurRow[StrReplace(ResourceName, "Resource_", "CoordColumn_")]).Details = NewDetailItem.ID;
			CalculateDependentItemsServer(CurRow, DetailsDataObject);
		EndIf;
	EndDo;
	
	If String.Count() > 0 Then
		FoundRow = String[0];
		ExecutePartialIterationOfBudgetsTreeByRow(FoundRow,ResourceName);
	EndIf;
	
	InitialDataVTAddress = PutToTempStorage(InitialDataVT, UUID);
	
EndProcedure

&AtClient
Procedure LabelStructureClick(Item)
	If DepartmentStructuresBinding Then
		ParametersStructure = New Structure("Department, StructureType", Object.Department);
		If Object.OperationType=PredefinedValue("Enum.fmBudgetOperationTypes.IncomesAndExpenses") Then
			ParametersStructure.StructureType=PredefinedValue("Enum.fmInfoStructureTypes.IncomesAndExpensesBudget")
		Else
			ParametersStructure.StructureType=PredefinedValue("Enum.fmInfoStructureTypes.CashflowBudget")
		EndIf;
		ParametersStructure.Insert("Key", Object.InfoStructure);
		OpenForm("Catalog.fmInfoStructures.Form.ChoiceFormBinding", ParametersStructure, ThisForm, , , , New NotifyDescription("StructureChoiceEnd", ThisForm), FormWindowOpeningMode.LockOwnerWindow);
	Else
		ParametersStructure = New Structure("StructureType");
		If Object.OperationType=PredefinedValue("Enum.fmBudgetOperationTypes.IncomesAndExpenses") Then
			ParametersStructure.StructureType=PredefinedValue("Enum.fmInfoStructureTypes.IncomesAndExpensesBudget")
		Else
			ParametersStructure.StructureType=PredefinedValue("Enum.fmInfoStructureTypes.CashflowBudget")
		EndIf;
		ParametersStructure.Insert("Key", Object.InfoStructure);
		OpenForm("Catalog.fmInfoStructures.ChoiceForm", ParametersStructure, ThisForm, , , , New NotifyDescription("StructureChoiceEnd", ThisForm), FormWindowOpeningMode.LockOwnerWindow);
	EndIf;
EndProcedure

&AtClient
Procedure InternalSettlementsPeriodOnChange(Item)
	CurRow = Items.InternalSettlements.CurrentData;
	CurRow.Period = BegOfMonth(CurRow.Period);
	If Periods.FindByValue(CurRow.Period)=Undefined Then
		CurRow.Period = DATE("00010101");
		CommonClientServer.MessageToUser(NStr("en='The selected period is not included in the specified interval!';ru='Выбранный период не входит в заданный интервал!'"));
	EndIf;
EndProcedure

&AtClient
Procedure FillPrediction(Command)
	OpenForm("DataProcessor.fmPredictionCopy.Form", PreparePredictionParameters(), ThisForm, UUID);
EndProcedure

&AtClient
Procedure FillCopy(Command)
	OpenForm("DataProcessor.fmPredictionCopy.Form", PreparePredictionParameters(False), ThisForm, UUID);
EndProcedure

&AtClient
Procedure BudgetsDataOnActivateRow(Item)
	If NOT Items.BudgetsData.CurrentData = Undefined Then
		For Index = 1 To 3 Do
			If ValueIsFilled(Items.BudgetsData.CurrentData["AnalyticsType"+Index]) Then
				Items["BudgetsDataAnalytics"+Index].TypeRestriction = Items.BudgetsData.CurrentData["AnalyticsType"+Index];
			EndIf;
		EndDo;
	EndIf;
EndProcedure

&AtClient
Procedure BudgetsDataItemOnChange(Item)
	CurRow = Items.BudgetsData.CurrentData;
	AnalyticsTypes = fmBudgeting.GetCustomAnalyticsSettings(CurRow.Item);
	For Index =1 To 3 Do
		If AnalyticsTypes["AnalyticsType"+Index] <> Undefined Then
			Items.BudgetsData.CurrentData["AnalyticsType"+Index] = AnalyticsTypes["AnalyticsType"+Index];
			Items["BudgetsDataAnalytics"+Index].TypeRestriction = AnalyticsTypes["AnalyticsType"+Index];
			Items.BudgetsData.CurrentData["AnalyticsType"+Index+"Filled"] = True;
		Else
			Items.BudgetsData.CurrentData["AnalyticsType"+Index] = EmptyType;
			Items["BudgetsDataAnalytics"+Index].TypeRestriction = EmptyType;
			Items.BudgetsData.CurrentData["AnalyticsType"+Index+"Filled"] = False;
		EndIf;
		CurRow["Analytics"+Index] = Undefined;
	EndDo;
EndProcedure

&AtClient
Procedure InternalSettlementsOnActivateRow(Item)
	If NOT Items.InternalSettlements.CurrentData = Undefined Then
		For Index = 1 To 3 Do
			If ValueIsFilled(Items.InternalSettlements.CurrentData["AnalyticsType"+Index]) Then
				Items["InternalSettlementsAnalytics"+Index].TypeRestriction = Items.InternalSettlements.CurrentData["AnalyticsType"+Index];
			EndIf;
		EndDo;
	EndIf;
EndProcedure

&AtClient
Procedure InternalSettlementsItemOnChange(Item)
	CurRow = Items.InternalSettlements.CurrentData;
	AnalyticsTypes = fmBudgeting.GetCustomAnalyticsSettings(CurRow.Item);
	For Index =1 To 3 Do
		If AnalyticsTypes["AnalyticsType"+Index] <> Undefined Then
			Items.InternalSettlements.CurrentData["AnalyticsType"+Index] = AnalyticsTypes["AnalyticsType"+Index];
			Items["InternalSettlementsAnalytics"+Index].TypeRestriction = AnalyticsTypes["AnalyticsType"+Index];
			Items.InternalSettlements.CurrentData["AnalyticsType"+Index+"Filled"] = True;
		Else
			Items.InternalSettlements.CurrentData["AnalyticsType"+Index] = EmptyType;
			Items["InternalSettlementsAnalytics"+Index].TypeRestriction = EmptyType;
			Items.InternalSettlements.CurrentData["AnalyticsType"+Index+"Filled"] = False;
		EndIf;
		CurRow["Analytics"+Index] = Undefined;
	EndDo;
EndProcedure


//////////////////////////////////////////////////////////////////////////////////
//// ПРОЦЕДУРЫ - ОБРАБОТЧИКИ СОБЫТИЙ КОМАНД СОГЛАСОВАНИЯ

&AtClient
Procedure Agree(Command)
	fmProcessManagementClient.AgreementButtonClickHandler(ThisForm, Command);
EndProcedure

&AtClient
// Процедура обработчик команды "СогласоватьСКомментарием" 
//
Procedure AgreeWithComment(Command)
	fmProcessManagementClient.AgreementButtonClickHandler(ThisForm, Command);
EndProcedure

&AtClient
Procedure Reject(Command)
	fmProcessManagementClient.RejectionButtonClickHandler(ThisForm, Command);
EndProcedure

&AtClient
// Процедура обработчик команды "ОтклонитьСКомментарием" 
//
Procedure RejectWithComment(Command)
	fmProcessManagementClient.RejectionButtonClickHandler(ThisForm, Command);
EndProcedure

&AtClient
Procedure CurStateClick(Item)
	If HasAgreement Then
		FormParameters = New Structure();
		FormParameters.Insert("RefToDocument", Object.Ref);
		FormParameters.Insert("Version", CurrentVersion);
		OpenForm("Report.fmRoutePassMap.Form.Form", FormParameters, ThisForm, , , , , FormWindowOpeningMode.LockOwnerWindow);
	Else
		FormParameters = New Structure();
		FormParameters.Insert("Key", CurState);
		OpenForm("Catalog.fmDocumentState.ChoiceForm", FormParameters, ThisForm, , , , New NotifyDescription("CurStateClickEnd", ThisObject), FormWindowOpeningMode.LockOwnerWindow);
	EndIf;
EndProcedure

&AtClient
Procedure CurStateClickEnd(Result, AddParameters) Export
	If NOT Result=Undefined Then
		CurState = Result;
		Items.CurState.Title = TrimAll(CurState);
		Modified = True;
	EndIf;
EndProcedure

///////////////////////////////////////////////////////////////////////////////
// Редактирование месяца строкой.

&AtServer
Procedure BegOfPeriodOnChangeServer()
	FillCurrencyRates();
	FillPeriods();
	fmBudgeting.BalanceUnitDepartmentCompatible(Object.BalanceUnit, Object.Department, Object.BeginOfPeriod, "Department");
	Object.BudgetsData.Clear();
	InternalSettlements.Clear();
	If NOT Object.OperationType=Enums.fmBudgetOperationTypes.InternalSettlements Then
		FillBudgetTree();
	EndIf;
	// Настройки формы по функционалу согласованию.
	fmProcessManagement.SetAgreementViewOnForm(ThisForm);
	
	// Сохраним доступность кнопок.
	AgreeAvailabilityForm = Items.AgreeForm.Enabled;
	AgreementAvailability = Items.Agreement.Enabled;
EndProcedure

&AtClient
Procedure BegOfPeriodAsStringOnChange(Item)
	fmCommonUseClient.MonthInputOnChange(ThisForm, "Object.BeginOfPeriod", "BegOfPeriodAsString", Modified);
	BegOfPeriodOnChangeServer();
EndProcedure

&AtClient
Procedure BegOfPeriodAsStringStartChoice(Item, ChoiceData, StandardProcessing)
	Notification = New NotifyDescription("BegOfPeriodAsStringStartChoiceEnd", ThisObject);
	fmCommonUseClient.MonthInputStartChoice(ThisForm, ThisForm, "Object.BeginOfPeriod", "BegOfPeriodAsString", , Notification);
EndProcedure

&AtClient
Procedure BegOfPeriodAsStringStartChoiceEnd(ValueSelected, AdditionalParameters) Export
	BegOfPeriodOnChangeServer();
EndProcedure

&AtClient
Procedure BegOfPeriodAsStringTuning(Item, Direction, StandardProcessing)
	fmCommonUseClient.MonthInputTuning(ThisForm, "Object.BeginOfPeriod", "BegOfPeriodAsString", Direction, Modified);
	BegOfPeriodOnChangeServer();
EndProcedure

&AtClient
Procedure BegOfPeriodAsStringAutoComplete(Item, Text, ChoiceData, Waiting, StandardProcessing)
	fmCommonUseClient.MonthInputTextAutoComplete(Text, ChoiceData, StandardProcessing);
EndProcedure

&AtClient
Procedure BegOfPeriodAsStringTextEditEnd(Item, Text, ChoiceData, StandardProcessing)
	fmCommonUseClient.MonthInputTextEditEnd(Text, ChoiceData, StandardProcessing);
EndProcedure

&AtClient
Procedure AddCommentBudgetTree(Command)
	
	CurrentArea = Items.BudgetTree.CurrentArea;
	// Проверка защиты области.
	If CurrentArea.Protection Then
		CommonClientServer.MessageToUser(NStr("en='It is impossible to add comments for the selected area.';ru='Добавление комментария для выделенной области невозможно!'"));
		Return;
	EndIf;
	
	CellCurentParameters = GetCellDetails(CurrentArea.Details);
	
	If NOT CellCurentParameters = Undefined Then
		OpenForm(
			"CommonForm.fmCommentForm", 
			New Structure(
				"Comment",
				CurrentArea.Comment.Text),,,,,
			New NotifyDescription("CommentInput_End", ThisForm, CellCurentParameters),
				FormWindowOpeningMode.LockOwnerWindow);
	EndIf;

EndProcedure

&AtServer
Function GetCellDetails(DetailsID)
	
	// Получение данных расшифровки.
	DetailsDataObject = GetFromTempStorage(DetailsData);
	
	// Создание структуры для поиска строки по ячейке в исходной ТЗ и поиск имени ресурса в текущей ячейке.
	DetailsFieldsStructure = New Structure(SearchColumnsRow);
	
	// Получение полей расшифровки для текущей ячейки.
	DetailsFieldValues = DetailsDataObject.Items[DetailsID].GetFields();
	For Each DetailsFieldValue In DetailsFieldValues Do
		If Find(SearchColumnsRow, DetailsFieldValue.Field) Then
			DetailsFieldsStructure[DetailsFieldValue.Field] = DetailsFieldValue.Value;
		EndIf;
	EndDo;
	
	// Основные параметры лежат в 1-ой колонке, строка должна делиться без остатка на количество ресурсов.
	CurrentArea = Items.BudgetTree.CurrentArea;
	CurTop = DetermineTopCoord(CurrentArea.Top, Resources.Count());
	CurrentArea = BudgetTree.Area(CurTop, 1, CurTop, 1);
	ParametersDetailsFieldValues = DetailsDataObject.Items[CurrentArea.Details].GetFields();
	For Each DetailsFieldValue In ParametersDetailsFieldValues Do
		If Find(SearchColumnsRow, DetailsFieldValue.Field) Then
			DetailsFieldsStructure[DetailsFieldValue.Field] = DetailsFieldValue.Value;
		EndIf;
	EndDo;
	
	Return DetailsFieldsStructure;
	
EndFunction

&AtClient
Procedure CommentInput_End(Comment, CellParameters) Export
	
	If NOT Comment = Undefined Then
		SDArea = Items.BudgetTree.CurrentArea;
		SDArea.Comment.Text = Comment;
		If NOT CellParameters = Undefined Then
			CommentInput_EndServer(Comment, CellParameters, InitialDataVTAddress, Object.ActualVersion, UUID);
			Modified = True;
		EndIf;
	EndIf;
	
EndProcedure // ВводКомментария_Завершение()

&AtServerNoContext
Procedure CommentInput_EndServer(Comment, CellParameters, InitialDataVTAddress, ActualVersion, UUID)
	
	// Поиск строки по ячейке в исходной ТЗ.
	InitialDataVT = GetFromTempStorage(InitialDataVTAddress);
	FoundRows = InitialDataVT.FindRows(CellParameters);
	If FoundRows.Count() Then
		FoundRow = FoundRows[0];
		FoundRow["Comment"] = Comment;
		FoundRow["CommentVersion"] = ActualVersion;
	EndIf;
	InitialDataVTAddress = PutToTempStorage(InitialDataVT, UUID);
EndProcedure // ВводКомментария_ЗавершениеСервер()


