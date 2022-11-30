
// Процедура устанавливает субконто на счете. Если такое субконто на счете
// отсутствует, то ничего не делается.
//
// Параметры:
//		Счет - Счет, к которому относится субконто
//		Субконто - набор субконто
//		Номер или имя устанавливаемого субконто
//		Значение субконто - значение устанавливаемого субконто.
//
Procedure SetSubconto(Account, ExtDimension, ExtDimensionName, ExtDimensionValue, Inform = False, Title = "", AccountExtDimensionKinds = Undefined) Export
	If Account = Undefined OR Account.IsEmpty() Then
		Return;
	EndIf;
	If AccountExtDimensionKinds = Undefined Then
		AccountExtDimensionKinds = Account.ExtDimensionTypes;
	EndIf;
	If TypeOf(ExtDimensionName) = Type("Number") Then
		If ExtDimensionName > AccountExtDimensionKinds.Count() Then
			Return;
		EndIf;
		ExtDimType = AccountExtDimensionKinds[ExtDimensionName - 1].ExtDimensionType;
	Else
		ExtDimType = ChartsOfCharacteristicTypes.fmAnalyticsTypes[ExtDimensionName];
		If AccountExtDimensionKinds.Find(ExtDimType) = Undefined Then
			If Inform Then
				CommonClientServer.MessageToUser(StrTemplate(NStr("en='Extra dimension type <%1> for account ""%2 (%3)"" is not defined.';ru='Вид субконто <%1> для счета ""%2 (%3)"" не определен.'"), ExtDimType, Account.Code, Account.Description));
			EndIf;
			Return;
		EndIf;
	EndIf;
	If ExtDimType.ValueType.ContainsType(TypeOf(ExtDimensionValue)) Then
		ExtDimension.Insert(ExtDimType, ExtDimensionValue);
	ElsIf Inform Then
		CommonClientServer.MessageToUser(StrTemplate(NStr("en='Incorrect value ""%1"" for dimension type <%2>';ru='Неверное значение ""%1"" для вида субконто <%2>'"), ExtDimensionValue, ExtDimType));
	EndIf;
EndProcedure // УстановитьСубконто()

Function DepartmentCommonTree(TreeParameters) Export	
	StructureMaximumVersion = fmBudgeting.ReturnDepartmentStructureActualVersion();
	StructureVersionForBuilding 				= TreeParameters.StructureVersionForBuilding;
	HeaderPeriodBegin 							= ?(TreeParameters.Property("HeaderPeriodBegin"), TreeParameters.HeaderPeriodBegin, Undefined);
	HeaderPeriodEnd 							= ?(TreeParameters.Property("HeaderPeriodEnd"), TreeParameters.HeaderPeriodEnd, Undefined);
	IncludeMarkedDepertments 			= ?(TreeParameters.Property("IncludeMarkedDepertments"), TreeParameters.IncludeMarkedDepertments, False);
	RootDepartment 						= ?(TreeParameters.Property("RootDepartment"), TreeParameters.RootDepartment, Undefined);
	OutputTree 								= ?(TreeParameters.Property("OutputTree"), TreeParameters.OutputTree, True);
	InfoStructure 							= ?(TreeParameters.Property("InfoStructure"), TreeParameters.InfoStructure, Undefined);
	InfoStructures 							= ?(TreeParameters.Property("InfoStructures"), TreeParameters.InfoStructures, Undefined);
	
	If HeaderPeriodEnd = Undefined Then
		HeaderPeriodEnd = CurrentDate();
	EndIf;
	
	SearchAttribute 								= ?(TreeParameters.Property("SearchAttribute"), TreeParameters.SearchAttribute, Undefined);
	SearchValue 								= ?(TreeParameters.Property("SearchValue"), TreeParameters.SearchValue, Undefined);
	SearchMethod 								= ?(TreeParameters.Property("SearchMethod"), TreeParameters.SearchMethod, Undefined);
	
	Query = New Query;
	AvailableDepartmentsArray = Undefined;
	//Обратимся к РС "Иерархия подразделений" и получим все доступные подразделения, исходя из группы доступа
	Query.Text = "SELECT
	|	DepartmentHierarchy.Department
	|FROM
	|	InformationRegister.fmDepartmentHierarchy AS DepartmentHierarchy";
	
	vtDepartments = Query.Execute().Unload();
	AvailableDepartmentsArray = vtDepartments.UnloadColumn("Department");
	
	If NOT InfoStructure = Undefined Then
		Query = New Query("SELECT
		|	InfoStructures.InfoStructure,
		|	InfoStructures.Department,
		|	InfoStructures.ApplyByDefault
		|	INTO InfoStructures
		|FROM
		|	&InfoStructures AS InfoStructures
		|WHERE
		|	InfoStructures.InfoStructure = &InfoStructure");
		TTManager = New TempTablesManager;
		Query.TempTablesManager = TTManager;
		Query.SetParameter("InfoStructures", InfoStructures);
		Query.SetParameter("InfoStructure", InfoStructure);
		Query.Execute();
	EndIf;
	
	Query.Text = "SELECT
	|DepartmentHierarchy.Department AS Departments,
	|DepartmentHierarchy.Department.Description AS Description,
	|DepartmentHierarchy.Department.Code AS Code,
	|ISNULL(DepartmentHierarchy.DepartmentParent.Code, ""ParentCode"") AS ParentCode,
	|DepartmentHierarchy.DepartmentParent AS Parent,
	|DepartmentHierarchy.Level AS Level,
	|DepartmentHierarchy.Department.BalanceUnit AS BalanceUnit,
	|DepartmentHierarchy.Department.Responsible AS Responsible,
	|DepartmentHierarchy.Department.SetColor AS SetIndColor,
	|DepartmentHierarchy.DeletionMark AS DeletionMark,
	|DepartmentHierarchy.Department.ManageType AS ManageType,
	|DepartmentHierarchy.Department.DepartmentType AS DepartmentType1
	|INTO DepartmetTableExclType
	|FROM
	|InformationRegister.fmDepartmentHierarchy AS DepartmentHierarchy
	|//{СоединениеСФР}
	|WHERE
	|	True
	|{FilterByMarked}
	|{FilterByDepartments}
	|{FilterBySearchStructure}
	|{VersionFilter}
	|
	|;
	|
	|///////////////////////////////////////////////////////////////
	|SELECT
	|	DepartmentsStateSliceLast.Department,
	|	DepartmentsStateSliceLast.DepartmentType
	|INTO DepartmentTypes
	|FROM
	|	InformationRegister.fmDepartmentsState.SliceLast(&HeaderPeriodEnd, ) AS DepartmentsStateSliceLast
	|;
	|
	|/////////////////////////////////////////////////////////////////////
	|SELECT
	|	DepartmetTableExclType.Departments,
	|	DepartmetTableExclType.Description,
	|	DepartmetTableExclType.Code,
	|	DepartmetTableExclType.ParentCode,
	|	DepartmetTableExclType.Parent,
	|	DepartmetTableExclType.Level,
	|	DepartmetTableExclType.BalanceUnit,
	|	DepartmetTableExclType.Responsible AS Responsible,
	|	DepartmetTableExclType.SetIndColor,
	|	DepartmetTableExclType.DeletionMark,
	|	DepartmetTableExclType.ManageType,
	|	DepartmentTypes.DepartmentType AS DepartmentType1
	|INTO DepartmentTable
	|FROM
	|	DepartmetTableExclType AS DepartmetTableExclType
	|		LEFT JOIN DepartmentTypes AS DepartmentTypes
	|		ON DepartmetTableExclType.Departments = DepartmentTypes.Department
	|
	|INDEX BY
	|	DepartmentType1,
	|	ParentCode
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	_T.Code
	|INTO DepartmentsCodes
	|FROM
	|	DepartmentTable AS _T
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Total.Department,
	|	Total.Description,
	|	Total.Code,
	|	Total.ParentCode,
	|	Total.Parent,
	|	Total.DepartmentType,
	|	Total.ManageType,
	|	Total.DeletionMark,
	|	Total.Level,
	|	{InfoStructuresTotal}
	|	Total.BalanceUnit,
	|	Total.Responsible
	|FROM
	|	(SELECT
	|		DepartmentHierarchy.Departments AS Department,
	|		DepartmentHierarchy.ManageType AS ManageType,
	|		DepartmentHierarchy.Description AS Description,
	|		DepartmentHierarchy.Code AS Code,
	|		DepartmentHierarchy.BalanceUnit AS BalanceUnit,
	|		DepartmentHierarchy.Responsible AS Responsible,
	|		ISNULL(DepartmentsCodes.Code, ""ParentCode"") AS ParentCode,
	|		DepartmentHierarchy.Parent AS Parent,
	|		DepartmentHierarchy.DeletionMark AS DeletionMark,
	|		ISNULL(DepartmentTypesSettings.Ref, Value(Catalog.fmDepartmentTypes.EmptyRef)) AS DepartmentType,
	|		{InfoStructuresNested}
	|		DepartmentHierarchy.Level AS Level
	|	FROM
	|		DepartmentTable AS DepartmentHierarchy
	|			LEFT JOIN Catalog.fmDepartmentTypes AS DepartmentTypesSettings
	|			ON DepartmentHierarchy.DepartmentType1 = DepartmentTypesSettings.Ref
	|			LEFT JOIN DepartmentsCodes AS DepartmentsCodes
	|			ON DepartmentHierarchy.ParentCode = DepartmentsCodes.Code
	|		{InfoStructuresJoin}
	|		) AS Total
	|";
	
	If NOT InfoStructure = Undefined Then
		Query.Text = StrReplace(Query.Text, "{InfoStructuresTotal}", "Total.ApplyByDefault,
		|	Total.Apply,"
		);
		Query.Text = StrReplace(Query.Text, "{InfoStructuresNested}", "ISNULL(InfoStructures.ApplyByDefault, False) AS ApplyByDefault,
		|		CASE
		|			WHEN ISNULL(InfoStructures.Department, Undefined) = Undefined
		|				Then False
		|			Else True
		|		END AS Apply,");
		Query.Text = StrReplace(Query.Text, "{InfoStructuresJoin}", "LEFT JOIN InfoStructures AS InfoStructures
		|		ON DepartmentHierarchy.Departments = InfoStructures.Department");
		
	Else
		Query.Text = StrReplace(Query.Text, "{InfoStructuresTotal}",   "");
		Query.Text = StrReplace(Query.Text, "{InfoStructuresNested}",  "");
		Query.Text = StrReplace(Query.Text, "{InfoStructuresJoin}", "");
	EndIf;
	
	If ValueIsFilled(HeaderPeriodEnd) Then
		Query.SetParameter("HeaderPeriodEnd", EndOfYear(HeaderPeriodEnd));
	Else
		Query.SetParameter("HeaderPeriodEnd", DATE("39991231"));
	EndIf;
	
	If OutputTree Then
		DepartmentObject = New ValueTree;
	Else
		DepartmentObject = New ValueTable;
	EndIf;
	
	If NOT IncludeMarkedDepertments = True Then
		Query.Text = StrReplace(Query.Text, "{FilterByMarked}", "	AND (NOT DepartmentHierarchy.DeletionMark )"); 
	EndIf;
	
	If NOT AvailableDepartmentsArray = Undefined AND
		AvailableDepartmentsArray.Count() > 0 Then
		
		Query.Text = StrReplace(Query.Text, "{FilterByDepartments}", "	AND DepartmentHierarchy.Department IN(&AvailableDepartmentsArray)");
		AvailableDepartmentList = New ValueList();
		AvailableDepartmentList.LoadValues(AvailableDepartmentsArray);
		Query.SetParameter("AvailableDepartmentsArray",AvailableDepartmentList);
		
		If NOT StructureVersionForBuilding = Undefined Then
			Query.Text = StrReplace(Query.Text, "{VersionFilter}", "AND DepartmentHierarchy.StructureVersion = &Version");
		Else
			Query.Text = StrReplace(Query.Text, "{VersionFilter}", "");
		EndIf; 
	Else
		
		Return DepartmentObject;
	EndIf;
	
	//***поиск
	If RootDepartment = Undefined Then 
		If NOT SearchMethod = Undefined AND NOT SearchValue = Undefined Then 
			If SearchMethod = 1 Then 
				If SearchAttribute = "1" Then
					Query.Text = StrReplace(Query.Text, "{FilterBySearchStructure}", "AND DepartmentHierarchy.Department.Description LIKE """+ SearchValue + "%""");	
				ElsIf SearchAttribute = "2" Then
					Query.Text = StrReplace(Query.Text, "{FilterBySearchStructure}", "AND DepartmentHierarchy.Department.Code LIKE """+ SearchValue + "%""");	
				EndIf;
			ElsIf SearchMethod = 2 Then
				If SearchAttribute = "1" Then
					Query.Text = StrReplace(Query.Text, "{FilterBySearchStructure}", "AND DepartmentHierarchy.Department.Description LIKE ""%"+ SearchValue + "%""");	
				ElsIf SearchAttribute = "2" Then
					Query.Text = StrReplace(Query.Text, "{FilterBySearchStructure}", "AND DepartmentHierarchy.Department.Code LIKE ""%"+ SearchValue + "%""");	
				EndIf;
			ElsIf SearchMethod = 3 Then
				If SearchAttribute = "1" Then
					Query.Text = StrReplace(Query.Text, "{FilterBySearchStructure}", "AND DepartmentHierarchy.Department.Description = """+ SearchValue + """");	
				ElsIf SearchAttribute = "2" Then
					Query.Text = StrReplace(Query.Text, "{FilterBySearchStructure}", "AND DepartmentHierarchy.Department.Code = """+ SearchValue + """");	
				EndIf;
			EndIf;
		EndIf;
	EndIf;
	//***поиск
	
	If NOT StructureVersionForBuilding = Undefined Then
		Query.SetParameter("Version", StructureVersionForBuilding);
	EndIf;
	
	DepartmentHierarchyTable = Query.Execute().Unload();
	
	If NOT RootDepartment = Undefined Then
		QueryForLinkStartExpression = New Query;
		QueryForLinkStartExpression.Text = "SELECT
		|	DepartmentHierarchy.ParentCode AS ParentCode,
		|	DepartmentHierarchy.Level
		|INTO TemporaryTotal
		|FROM
		|	&DepartmentHierarchyTable AS DepartmentHierarchy
		|{FilterBySearchStructure}
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT TOP 1
		|	TemporaryTotal.ParentCode,
		|	TemporaryTotal.Level AS Level
		|FROM
		|	TemporaryTotal AS TemporaryTotal
		|
		|ORDER BY
		|	Level
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|DROP TemporaryTotal";
		
		If NOT SearchMethod = Undefined AND NOT SearchValue = Undefined Then 
			If SearchMethod = 1 Then 
				If SearchAttribute = "1" Then
					Query.Text = StrReplace(Query.Text, "{FilterBySearchStructure}", "WHERE DepartmentHierarchy.Department.Description LIKE """+ SearchValue + "%""");	
				ElsIf SearchAttribute = "2" Then
					Query.Text = StrReplace(Query.Text, "{FilterBySearchStructure}", "WHERE DepartmentHierarchy.Department.Code LIKE """+ SearchValue + "%""");	
				EndIf;
			ElsIf SearchMethod = 2 Then
				If SearchAttribute = "1" Then
					Query.Text = StrReplace(Query.Text, "{FilterBySearchStructure}", "WHERE DepartmentHierarchy.Department.Description LIKE ""%"+ SearchValue + "%""");	
				ElsIf SearchAttribute = "2" Then
					Query.Text = StrReplace(Query.Text, "{FilterBySearchStructure}", "WHERE DepartmentHierarchy.Department.Code LIKE ""%"+ SearchValue + "%""");	
				EndIf;
			ElsIf SearchMethod = 3 Then
				If SearchAttribute = "1" Then
					Query.Text = StrReplace(Query.Text, "{FilterBySearchStructure}", "WHERE DepartmentHierarchy.Department.Description = """+ SearchValue + """");	
				ElsIf SearchAttribute = "2" Then
					Query.Text = StrReplace(Query.Text, "{FilterBySearchStructure}", "WHERE DepartmentHierarchy.Department.Code = """+ SearchValue + """");	
				EndIf;
			EndIf;
		EndIf;
		
		
		QueryForLinkStartExpression.SetParameter("DepartmentHierarchyTable",DepartmentHierarchyTable);
		VT = QueryForLinkStartExpression.Execute().Unload();
		TemplateComposer = New DataCompositionTemplateComposer;
		If InfoStructure=Undefined Then
			DataCompositionSchema = Catalogs.fmDepartments.GetTemplate("DepartmentHierarchy");
		Else
			DataCompositionSchema = GetCommonTemplate("fmDepartmentTreeOnfoStructure");
		EndIf;
		Try
			DataCompositionSchema.DataSetLinks[0].StartExpression = """"+String(RootDepartment.Code)+"""";
		Except
		EndTry;
	Else
		TemplateComposer = New DataCompositionTemplateComposer;
		If InfoStructure=Undefined Then
		DataCompositionSchema = Catalogs.fmDepartments.GetTemplate("DepartmentHierarchy");
		Else
			DataCompositionSchema = GetCommonTemplate("fmDepartmentTreeOnfoStructure");
		EndIf;
	EndIf;
	
	Settings = DataCompositionSchema.DefaultSettings;
	
	SettingsComposer = New DataCompositionSettingsComposer;
	SettingsComposer.Initialize(New DataCompositionAvailableSettingsSource(DataCompositionSchema));
	SettingsComposer.LoadSettings(Settings);
	
	Settings = SettingsComposer.Settings;
	
	CompositionTemplate = TemplateComposer.Execute(DataCompositionSchema, Settings,,,Type("DataCompositionValueCollectionTemplateGenerator"));
	
	ExternalDataSet = New Structure("DepartmentHierarchyTable", DepartmentHierarchyTable);
	
	//инициализация процессора СКД
	DataCompositionProcessor = New DataCompositionProcessor;
	DataCompositionProcessor.Initialize(CompositionTemplate, ExternalDataSet);	
	
	//инициализация процессора вывода
	OutputProcessor = New DataCompositionResultValueCollectionOutputProcessor;
	OutputProcessor.SetObject(DepartmentObject);
	OutputProcessor.Output(DataCompositionProcessor); 
	
	Return DepartmentObject;
	
EndFunction

Function ReturnDepartmentStructureActualVersion(UpdateDate = Undefined, VersionListForException = Undefined) Export
	
	Query = New Query;
	Query.Text = "SELECT TOP 1
	|	DepartmentsStructuresVersions.ApprovalDate AS VersionApprovalDate,
	|	DepartmentsStructuresVersions.DateValidUntil AS DateValidUntil,
	|	DepartmentsStructuresVersions.Ref
	|FROM
	|	Catalog.fmDepartmentsStructuresVersions AS DepartmentsStructuresVersions
	|WHERE
	|	NOT DepartmentsStructuresVersions.DeletionMark
	|	{FilterByDate}
	|	{SelectionExcludingSomeVersions}
	|
	|ORDER BY
	|	ApprovalDate DESC";
	
	If UpdateDate = Undefined Then
		Query.Text = StrReplace(Query.Text, "{FilterByDate}", "");				   
	Else
		Query.Text = StrReplace(Query.Text, "{FilterByDate}", "AND DepartmentsStructuresVersions.ApprovalDate <= &UpdateDate");				   
		Query.SetParameter("UpdateDate", UpdateDate);
	EndIf;
	
	If VersionListForException = Undefined Then
		Query.Text = StrReplace(Query.Text, "{SelectionExcludingSomeVersions}", "");				   
	Else
		Query.Text = StrReplace(Query.Text, "{SelectionExcludingSomeVersions}", "AND NOT DepartmentsStructuresVersions.Ref IN (&VersionListForException)");				   
		Query.SetParameter("VersionListForException", VersionListForException);
	EndIf;
	
	SelectionOfExistingVersionsDates = Query.Execute().SELECT();
	If SelectionOfExistingVersionsDates.Next() Then
		Return SelectionOfExistingVersionsDates.Ref;
	Else
		Return Catalogs.fmDepartmentsStructuresVersions.EmptyRef();
	EndIf;
	
EndFunction

// Функция возвращает родителя переданного подразделения согласно версии структуры
//
Function DepartmentParentByVersion(Department, StructureVersion) Export
	
	If TypeOf(Department) = Type("CatalogRef.fmDepartments") Then
		Parent = Undefined;
		
		Query = New Query();
		Query.Text = "SELECT
		|	DepartmentHierarchy.DepartmentParent
		|FROM
		|	InformationRegister.fmDepartmentHierarchy AS DepartmentHierarchy
		|WHERE
		|	DepartmentHierarchy.Department = &Department
		|	AND DepartmentHierarchy.StructureVersion = &StructureVersion";
		
		Query.SetParameter("Department",   Department);
		Query.SetParameter("StructureVersion", StructureVersion);
		
		Selection = Query.Execute().SELECT();
		If Selection.Next() Then
			Parent = Selection.DepartmentParent;
		EndIf;
	ElsIf Department = Undefined Then
		Return Undefined;
	Else
		Parent = New Array;
		
		Query = New Query();
		Query.Text = "SELECT DISTINCT
		|	DepartmentHierarchy.DepartmentParent
		|FROM
		|	InformationRegister.fmDepartmentHierarchy AS DepartmentHierarchy
		|WHERE
		|	DepartmentHierarchy.Department IN(&Department)
		|	AND DepartmentHierarchy.StructureVersion = &StructureVersion";
		
		Query.SetParameter("Department",   Department);
		Query.SetParameter("StructureVersion", StructureVersion);
		
		Selection = Query.Execute().SELECT();
		While Selection.Next() Do
			Parent.Add(Selection.DepartmentParent);
		EndDo;
	EndIf;
	
	Return Parent;
	
EndFunction

//Функция формирует таблицу периодов по месяцам в рамках заданного интервала
//
Function PeriodsTable(Scenario, VAL BeginOfPeriod) Export
	
	//Получим периоды(по месяцам) для заданного интервала
	PeriodsTable = New ValueTable;
	PeriodsTable.Columns.Add("BeginOfPeriod", New TypeDescription("DATE"));
	PeriodsTable.Columns.Add("EndOfPeriod", New TypeDescription("DATE"));
	PeriodsTable.Columns.Add("PeriodPresentation", New TypeDescription("String"));
	
	For Num=1 To CalculatePeriodCount(Scenario.PlanningPeriod, Scenario.PlanningPeriodicity) Do
		NewLine = PeriodsTable.Add();
		NewLine.BeginOfPeriod = BeginOfPeriod;
		BeginOfPeriod = AddInterval(BeginOfPeriod, Scenario.PlanningPeriodicity);
		NewLine.EndOfPeriod = BeginOfPeriod-1;
		NewLine.PeriodPresentation = fmPeriodChoiceClientServer.GetReportPeroidRepresentation(Enums.fmAvailableReportPeriods[String(Scenario.PlanningPeriodicity)], NewLine.BeginOfPeriod, NewLine.EndOfPeriod);
	EndDo;
	
	Return PeriodsTable;

EndFunction

// Возвращает количество периодов между указанными датами
//
// Параметры
//  ДатаНачала, ДатаКонца: Дата  – границы интервала
//  Периодичность (Перечисления.Периодичность): периодичность планирования
//
// Возвращаемое значение:
//   КоличествоПериодов   – количество периодов в переданном интервале
//
Function CalculatePeriodCount(PlanningPeriod, PlanningPeriodicity) Export
	
	If PlanningPeriod = Enums.fmPlanningPeriod.Year 
	AND PlanningPeriodicity = Enums.fmPlanningPeriodicity.Quarter Then
		Return 4;
	ElsIf PlanningPeriod = Enums.fmPlanningPeriod.Year
	AND PlanningPeriodicity = Enums.fmPlanningPeriodicity.Month Then
		Return 12;
	ElsIf PlanningPeriod = Enums.fmPlanningPeriod.Quarter
	AND PlanningPeriodicity = Enums.fmPlanningPeriodicity.Quarter Then
		Return 1;
	ElsIf PlanningPeriod = Enums.fmPlanningPeriod.Quarter
	AND PlanningPeriodicity = Enums.fmPlanningPeriodicity.Month Then
		Return 3;
	Else
		// Исключительная ситуация
		Return 0;
	EndIf;
	
EndFunction // РассчитатьКоличествоПериодов()

// Периодичность (Перечисления.уфПериодичностьПланирования): периодичность планирования по сценарию.
// Дата (Дата): произвольная дата
// Смещение (число): определяет направление и количество периодов, в котором сдвигается дата
// Возвращаемое значение: дата, отстоящая от исходной на заданное количество периодов 
//
Function AddInterval(DATE, Periodicity, Offset=1) Export

	If Offset=0 Then
		NewPeriodDate=DATE;
	ElsIf Periodicity=Enums.fmPlanningPeriodicity.Month Then
		NewPeriodDate=AddMonth(DATE, Offset);
	ElsIf Periodicity=Enums.fmPlanningPeriodicity.Quarter Then
		NewPeriodDate=AddMonth(DATE, Offset*3);
	EndIf;

	Return NewPeriodDate;

EndFunction // ДобавитьИнтервал()

Function TransformNumber(Number, EditFormatStructure, EditFormatConstant, ViewMode=True) Export
	// Настроим соответствия для округлений.
	If ValueIsFilled(EditFormatStructure) Then
		RoundMethod = EditFormatStructure;
	Else
		RoundMethod = EditFormatConstant;
	EndIf;
	If RoundMethod=Enums.fmRoundMethods.WithoutRound OR NOT ValueIsFilled(RoundMethod) Then
		Return Number;
	EndIf;
	If RoundMethod=Enums.fmRoundMethods.One Then
		RoundedValue = 0;
	ElsIf RoundMethod=Enums.fmRoundMethods.Ten Then
		RoundedValue = -1;
	ElsIf RoundMethod=Enums.fmRoundMethods.Hundred Then
		RoundedValue = -2;
	ElsIf RoundMethod=Enums.fmRoundMethods.Thousand Then
		RoundedValue = -3;
	ElsIf RoundMethod=Enums.fmRoundMethods.TenThousands Then
		RoundedValue = -4;
	ElsIf RoundMethod=Enums.fmRoundMethods.HundredThousands Then
		RoundedValue = -5;
	ElsIf RoundMethod=Enums.fmRoundMethods.Million Then
		RoundedValue = -6;
	EndIf;
	Divider=1;
	For Num=1 To RoundedValue*-1 Do
		Divider=Divider*10;
	EndDo;
	If ViewMode Then
		Return Round(Number, RoundedValue)/Divider;
	Else
		Return Number*Divider;
	EndIf;
EndFunction // ПреобразоватьЧисло()

Procedure SwitchEntriesActivityBudgeting(Document) Export
	
	If Common.ObjectAttributeValue(Document, "DeletionMark") Then
		Return;
	EndIf;

	DocumentEntries = AccountingRegisters.fmBudgeting.CreateRecordSet();
	DocumentEntries.Filter.Recorder.Set(Document);
	DocumentEntries.Read();

	EntriesCount = DocumentEntries.Count();
	If NOT (EntriesCount = 0) Then
		
		// Определяем текущую активность проводок по первой проводке
		CurrentEntriesActivity = DocumentEntries[0].Active;

		// Инвертируем текущую активность проводок
		DocumentEntries.SetActive(NOT CurrentEntriesActivity);
		DocumentEntries.Write();

	EndIf;
		
EndProcedure

Function BalanceUnitDepartmentCompatible(BalanceUnit, Department, Period, BalanceUnitDepartment="") Export
	If ValueIsFilled(BalanceUnit) AND ValueIsFilled(Department) Then
		Result = InformationRegisters.fmDepartmentsState.GetLast(Period, New Structure("Department", Department));
		If Result.BalanceUnit=BalanceUnit Then
			Return True;
		Else
			MessageText = StrTemplate(NStr("en='Department <%1> does not refer to Balance unit <%2>  as of the period start date.';ru='Подразделение <%1> не относится к Балансовой единице <%2> на дату начала периода!'"), Department,  BalanceUnit);
			If BalanceUnitDepartment = "Department" Then
				Department = Catalogs.fmDepartments.EmptyRef();
			ElsIf BalanceUnitDepartment = "BalanceUnit" Then
				BalanceUnit = Catalogs.fmBalanceUnits.EmptyRef();
			EndIf;
			CommonClientServer.MessageToUser(MessageText, , ?(ValueIsFilled(BalanceUnitDepartment), "Object."+BalanceUnitDepartment, ""));
			Return False;
		EndIf;
	Else
		Return True;
	EndIf;
EndFunction

Function GetViewFormat(InfoStructure) Export
	If ValueIsFilled(InfoStructure) AND ValueIsFilled(InfoStructure.ViewFormat) Then
		Return InfoStructure.ViewFormat;
	Else
		Return Constants.fmViewFormat.Get();
	EndIf;
EndFunction

Function GetEditFormat(InfoStructure) Export
	If ValueIsFilled(InfoStructure) AND ValueIsFilled(InfoStructure.EditFormat) Then
		Return InfoStructure.EditFormat;
	Else
		Return Constants.fmEditFormat.Get();
	EndIf;
EndFunction

Function FormViewFormat(InfoStructure) Export
	ViewFormat = GetViewFormat(InfoStructure);
	EditFormat = GetEditFormat(InfoStructure);
	If NOT ValueIsFilled(ViewFormat) OR ViewFormat=Enums.fmRoundMethods.WithoutRound Then
		Return "";
	Else
		Rounds = New Map();
		Rounds.Insert(PredefinedValue("Enum.fmRoundMethods.EmptyRef"), "0");
		Rounds.Insert(PredefinedValue("Enum.fmRoundMethods.WithoutRound"), "0");
		Rounds.Insert(PredefinedValue("Enum.fmRoundMethods.One"), "0");
		Rounds.Insert(PredefinedValue("Enum.fmRoundMethods.Ten"), "1");
		Rounds.Insert(PredefinedValue("Enum.fmRoundMethods.Hundred"), "2");
		Rounds.Insert(PredefinedValue("Enum.fmRoundMethods.Thousand"), "3");
		Rounds.Insert(PredefinedValue("Enum.fmRoundMethods.TenThousands"), "4");
		Rounds.Insert(PredefinedValue("Enum.fmRoundMethods.HundredThousands"), "5");
		Rounds.Insert(PredefinedValue("Enum.fmRoundMethods.Million"), "6");
		Return "NFD=0; NS="+(Rounds[ViewFormat]-Rounds[EditFormat]);
	EndIf;
EndFunction

Function FormEditFormat(InfoStructure) Export
	EditFormat = GetEditFormat(InfoStructure);
	If NOT ValueIsFilled(EditFormat) OR EditFormat=Enums.fmRoundMethods.WithoutRound Then
		Return "";
	Else
		Return "NFD=0";
	EndIf;
EndFunction

Function ReturnParentLevelFromIR(ParentDepartment, StructureVersion) Export
	ParentRecordIntoIR = InformationRegisters.fmDepartmentHierarchy.CreateRecordSet();
	ParentRecordIntoIR.Filter.StructureVersion.Set(StructureVersion);
	ParentRecordIntoIR.Filter.Department.Set(ParentDepartment);
	ParentRecordIntoIR.Read();
	If ParentRecordIntoIR.Count() = 0 Then
		Return 0;
	Else
		Return ParentRecordIntoIR[0].Level;
	EndIf;
EndFunction

Function CurDepartmentIsMarkedOnDeletion(Department, dParent, StructureVersion) Export
	IRRecord = InformationRegisters.fmDepartmentHierarchy.CreateRecordManager();
	IRRecord.StructureVersion = StructureVersion;
	IRRecord.Department = Department;
	IRRecord.DepartmentParent = dParent;
	IRRecord.Read();
	If NOT IRRecord.Selected() Then
		Return False;
	Else
		Return IRRecord.DeletionMark;
	EndIf;
EndFunction

Function GetAccountExtDimension(Account) Export
	Structure = New Structure;
	Index = 1;
	For Each Item In Account.ExtDimensionTypes Do
		Structure.Insert("ExtDimension"+Index, Item.ExtDimensionType);
		Index = Index +1;
	EndDo;
	While Index <= 3 Do
		Structure.Insert("ExtDimension"+Index, Undefined);
		Index = Index +1;
	EndDo;
	Structure.Insert("FinancialResults", Account.FinancialResults);
	Return Structure;
EndFunction

// Процедура получения настроек произвольных аналитик
// Входящие параметры:
//    Статья - СправочникСсылка.уфСтатьиДоходовИРасходов или Массив из СправочникСсылка.уфСтатьиДоходовИРасходов - статьи, для которых получаем настройки (переопределяет подразделение).
//
// Возвращаемое значение:
//    Настроек нет и передавалась статья - Неопределено
//    Настроек нет и передавался массив статей - пустой массив
//    Настройки есть и передавалась статья - Структура - "Статья, ТипАналитики1, ТипАналитики2, ТипАналитики3" и др. настройки.
//    Настройки есть и передавался массив статей - Массив структур - см. выше.
//
Function GetCustomAnalyticsSettings(Item) Export
	
	// Результирующий массив с настройками.
	SettingsArray = New Array();
	QueryText = "SELECT ALLOWED
	               |	fmCashflowItems.Ref AS Ref,
	               |	fmCashflowItems.fmAnalyticsType1.ValueType AS AnalyticsType1,
	               |	fmCashflowItems.fmAnalyticsType2.ValueType AS AnalyticsType2,
	               |	fmCashflowItems.fmAnalyticsType3.ValueType AS AnalyticsType3,
	               |	fmCashflowItems.fmItemType AS MovementOperationType
	               |FROM
	               |	Catalog.fmCashflowItems AS fmCashflowItems
	               |WHERE
	               |	fmCashflowItems.Ref IN(&Items)
	               |
	               |UNION ALL
	               |
	               |SELECT
	               |	fmIncomesAndExpensesItems.Ref,
	               |	fmIncomesAndExpensesItems.AnalyticsType1.ValueType,
	               |	fmIncomesAndExpensesItems.AnalyticsType2.ValueType,
	               |	fmIncomesAndExpensesItems.AnalyticsType3.ValueType,
	               |	fmIncomesAndExpensesItems.ItemType
	               |FROM
	               |	Catalog.fmIncomesAndExpensesItems AS fmIncomesAndExpensesItems
	               |WHERE
	               |	fmIncomesAndExpensesItems.Ref IN(&Items)";
	
	Query = New Query(QueryText);
	Query.SetParameter("Items", Item);
	Result = Query.Execute().SELECT();
	While Result.Next() Do
		SettingStructure = New Structure();
		SettingStructure.Insert("Item", Result.Ref);
		Counter = 0;
		For Index = 1 To 3 Do
			If ValueIsFilled(Result["AnalyticsType"+Index]) Then
				Counter = Counter +1;
				SettingStructure.Insert("AnalyticsType"+Index, Result["AnalyticsType"+Index]);
			Else
				SettingStructure.Insert("AnalyticsType"+Index, Undefined);
			EndIf;
		EndDo;
		SettingStructure.Insert("Count", Counter);
		SettingStructure.Insert("MovementOperationType", Result.MovementOperationType);
		SettingsArray.Add(SettingStructure);
	EndDo;
	

	// Проанализируем полученные настройки для возврата результата.
	If SettingsArray.Count()=0 AND (TypeOf(Item)= Type("CatalogRef.fmCashflowItems") 
		OR TypeOf(Item)= Type("CatalogRef.fmIncomesAndExpensesItems")) Then
		Return Undefined;
	ElsIf SettingsArray.Count()=1 AND (TypeOf(Item)= Type("CatalogRef.fmCashflowItems")
		OR TypeOf(Item)= Type("CatalogRef.fmIncomesAndExpensesItems")) Then
		Return SettingsArray[0];
	Else
		Return SettingsArray;
	EndIf;
	
EndFunction // ПолучитьНастройкиПроизвольныхАналитик()

Function ViewAndInputAllowedCombination(EditFormat, ViewFormat) Export
	Rounds = GetRoundWeights();
	Return Rounds[EditFormat]<=Rounds[ViewFormat];
EndFunction

Function GetRoundWeights() Export
	Rounds = New Map();
	Rounds.Insert(PredefinedValue("Enum.fmRoundMethods.EmptyRef"), 0);
	Rounds.Insert(PredefinedValue("Enum.fmRoundMethods.WithoutRound"), 0);
	Rounds.Insert(PredefinedValue("Enum.fmRoundMethods.One"), 1);
	Rounds.Insert(PredefinedValue("Enum.fmRoundMethods.Ten"), 2);
	Rounds.Insert(PredefinedValue("Enum.fmRoundMethods.Hundred"), 3);
	Rounds.Insert(PredefinedValue("Enum.fmRoundMethods.Thousand"), 4);
	Rounds.Insert(PredefinedValue("Enum.fmRoundMethods.TenThousands"), 5);
	Rounds.Insert(PredefinedValue("Enum.fmRoundMethods.HundredThousands"), 6);
	Rounds.Insert(PredefinedValue("Enum.fmRoundMethods.Million"), 7);
	Return Rounds;
EndFunction

Function DetermineDocumentVersion(Ref) Export
	If TypeOf(Ref.Ref)=Type("DocumentRef.fmBudget") Then
		Return Ref.ActualVersion;
	Else
		Return DATE("00010101");
	EndIf;
EndFunction

Function GetBasicStructure(Department, OperationType) Export
	
	Query = New Query("SELECT ALLOWED
	                      |	fmBindingInfoStructuresToDepartments.InfoStructure AS InfoStructure,
	                      |	fmBindingInfoStructuresToDepartments.Department AS Department,
	                      |	fmBindingInfoStructuresToDepartments.ApplyByDefault AS ApplyByDefault
	                      |FROM
	                      |	InformationRegister.fmBindingInfoStructuresToDepartments AS fmBindingInfoStructuresToDepartments
	                      |WHERE
	                      |	fmBindingInfoStructuresToDepartments.Department = &Department
	                      |	AND fmBindingInfoStructuresToDepartments.ApplyByDefault
	                      |	AND fmBindingInfoStructuresToDepartments.InfoStructure.StructureType = &StructureType");
	Query.SetParameter("Department", Department);
	If OperationType=Enums.fmBudgetOperationTypes.IncomesAndExpenses Then
		Query.SetParameter("StructureType", Enums.fmInfoStructureTypes.IncomesAndExpensesBudget);
	Else
		Query.SetParameter("StructureType", Enums.fmInfoStructureTypes.CashflowBudget);
	EndIf;
	Result = Query.Execute().SELECT();
	If Result.Next() Then
		Return Result.InfoStructure;
	Else
		Return Catalogs.fmInfoStructures.EmptyRef();
	EndIf;
	
EndFunction

Procedure FillMaps(NameSynonymMap, SynonymNameMap) Export
	
	// Заполним из метаданных соответствие имени реквизита его синониму.
	// Заполним из метаданных соответствие синонима реквизита его имени.
	For Each CurAttribute In Metadata.Documents.fmBudget.TabularSections.BudgetsData.Attributes Do
		If ValueIsFilled(CurAttribute.Synonym) Then
			NameSynonymMap.Insert(CurAttribute.Name, CurAttribute.Synonym);
			SynonymNameMap.Insert(fmBudgetingClientServer.DeleteSymbols(CurAttribute.Synonym), CurAttribute.Name);
		EndIf;
	EndDo;
	For Each CurAttribute In Metadata.Documents.fmBudget.Attributes Do
		If ValueIsFilled(CurAttribute.Synonym) Then
			NameSynonymMap.Insert(CurAttribute.Name, CurAttribute.Synonym);
			SynonymNameMap.Insert(fmBudgetingClientServer.DeleteSymbols(CurAttribute.Synonym), CurAttribute.Name);
		EndIf;
	EndDo;
EndProcedure

Procedure OnCreateAtServerProcessTemplateEntriesTable(Object, TSAttributes) Export
	
	NameSynonymMap = New Structure();
	SynonymNameMap = New Structure();
	
	FillMaps(NameSynonymMap, SynonymNameMap);
	
	NewLine = TSAttributes.Add();
	NewLine.Attribute = "Analytics1";
	NewLine.Attribute = fmBudgetingClientServer.GetSynonym(NewLine, NameSynonymMap);
	
	NewLine = TSAttributes.Add();
	NewLine.Attribute = "Analytics2";
	NewLine.Attribute = fmBudgetingClientServer.GetSynonym(NewLine, NameSynonymMap);
	
	NewLine = TSAttributes.Add();
	NewLine.Attribute = "Analytics3";
	NewLine.Attribute = fmBudgetingClientServer.GetSynonym(NewLine, NameSynonymMap);
	
	NewLine = TSAttributes.Add();
	NewLine.Attribute = "Item";
	NewLine.Attribute = fmBudgetingClientServer.GetSynonym(NewLine, NameSynonymMap);
	
	NewLine = TSAttributes.Add();
	NewLine.Attribute = "BalanceUnit";
	NewLine.Attribute = fmBudgetingClientServer.GetSynonym(NewLine, NameSynonymMap);
	
	NewLine = TSAttributes.Add();
	NewLine.Attribute = "Department";
	NewLine.Attribute = fmBudgetingClientServer.GetSynonym(NewLine, NameSynonymMap);
	
	Query = New Query;
	Query.Text = "SELECT ALLOWED
	               |	EntriesTemplates.AccountDr AS AccountDr,
	               |	EntriesTemplates.AccountCr AS AccountCr,
	               |	EntriesTemplates.AmountCalculationRatio AS AmountCalculationRatio,
	               |	EntriesTemplates.ExtDimensionDr1 AS ExtDimensionDr1,
	               |	EntriesTemplates.ExtDimensionDr2 AS ExtDimensionDr2,
	               |	EntriesTemplates.ExtDimensionDr3 AS ExtDimensionDr3,
	               |	EntriesTemplates.ExtDimensionCr1 AS ExtDimensionCr1,
	               |	EntriesTemplates.ExtDimensionCr2 AS ExtDimensionCr2,
	               |	EntriesTemplates.ExtDimensionCr3 AS ExtDimensionCr3
	               |INTO TTEntriesTemplates
	               |FROM
	               |	&EntriesTemplates AS EntriesTemplates
	               |;
	               |
	               |////////////////////////////////////////////////////////////////////////////////
	               |SELECT
	               |	TTEntriesTemplates.AccountDr AS AccountDr,
	               |	TTEntriesTemplates.AccountCr AS AccountCr,
	               |	TTEntriesTemplates.AmountCalculationRatio AS AmountCalculationRatio,
	               |	TTEntriesTemplates.ExtDimensionDr1 AS ExtDimensionDr1,
	               |	TTEntriesTemplates.ExtDimensionDr2 AS ExtDimensionDr2,
	               |	TTEntriesTemplates.ExtDimensionDr3 AS ExtDimensionDr3,
	               |	TTEntriesTemplates.ExtDimensionCr1 AS ExtDimensionCr1,
	               |	TTEntriesTemplates.ExtDimensionCr2 AS ExtDimensionCr2,
	               |	TTEntriesTemplates.ExtDimensionCr3 AS ExtDimensionCr3,
	               |	fmBudgeting.ExtDimensionTypes.(
	               |		ExtDimensionType AS ExtDimensionType
	               |	) AS ExtDimensionTypes,
	               |	fmBudgeting1.ExtDimensionTypes.(
	               |		ExtDimensionType AS ExtDimensionType1
	               |	) AS ExtDimensionTypes1
	               |FROM
	               |	TTEntriesTemplates AS TTEntriesTemplates,
	               |	ChartOfAccounts.fmBudgeting AS fmBudgeting,
	               |	ChartOfAccounts.fmBudgeting AS fmBudgeting1
	               |WHERE
	               |	fmBudgeting.Ref = TTEntriesTemplates.AccountDr
	               |	AND fmBudgeting1.Ref = TTEntriesTemplates.AccountCr";
	Query.TempTablesManager = New TempTablesManager;
	TSUnloading = Object.fmEntriesTemplates.Unload();
	Query.SetParameter("EntriesTemplates", TSUnloading);
	QueryResult = Query.Execute().Unload();
	RowIndex = 0;
	For Each String In TSUnloading Do
		
		For Index = 1 To 3 Do
			String["ExtDimensionDr"+Index] = fmBudgetingClientServer.GetSynonym(String["ExtDimensionDr"+Index], NameSynonymMap);
			String["ExtDimensionCr"+Index] = fmBudgetingClientServer.GetSynonym(String["ExtDimensionCr"+Index], NameSynonymMap);
		EndDo;
		
		ExtDimensionTypes = QueryResult[RowIndex].ExtDimensionTypes;
		ExtDimensionTypes1 = QueryResult[RowIndex].ExtDimensionTypes1;
		Index = 1;
		For Each ExtDimensionType In ExtDimensionTypes Do
			String["fmAnalyticsTypeDr"+Index] = ExtDimensionType.ExtDimensionType;
			Index = Index +1;
		EndDo;
		Index = 1;
		For Each ExtDimensionType In ExtDimensionTypes1 Do
			String["fmAnalyticsTypeCr"+Index] = ExtDimensionType.ExtDimensionType1;
			Index = Index +1;
		EndDo;
		RowIndex = RowIndex+1;
	EndDo;
	Object.fmEntriesTemplates.Load(TSUnloading);
	
EndProcedure

Procedure BeforeWriteAtServerProcessTemplateEntriesTable(Object, CurrentObject) Export
	
	NameSynonymMap = New Structure();
	SynonymNameMap = New Structure();
	
	FillMaps(NameSynonymMap, SynonymNameMap);
	// Чистим ТЧ.
	CurrentObject.fmEntriesTemplates.Clear();
	
	// Переносим табличные настройки в ТЧ.
	For Each CurRow In Object.fmEntriesTemplates Do
		NewLine = CurrentObject.fmEntriesTemplates.Add();
		FillPropertyValues(NewLine, CurRow);
		For Index = 1 To 3 Do
			NewLine["ExtDimensionDr"+Index] = fmBudgetingClientServer.GetName(NewLine["ExtDimensionDr"+Index], SynonymNameMap);
			NewLine["ExtDimensionCr"+Index] = fmBudgetingClientServer.GetName(NewLine["ExtDimensionCr"+Index], SynonymNameMap);
		EndDo;
	EndDo;
	
EndProcedure

Procedure CheckAtServer(ExtDimension, Index, Value) Export
	If Value = "BalanceUnit" Then
		If ExtDimension.ValueType <> New TypeDescription("CatalogRef.fmBalanceUnits") Then
			CommonClientServer.MessageToUser(StrTemplate(NStr("en='Extra dimension %1 cannot take value %2';ru='Субконто %1 не может принимать значение %2'"), Index, Value));
		EndIf;
	ElsIf Value = "Item" Then
		If ExtDimension.ValueType <> New TypeDescription("CatalogRef.fmCashflowItems") Then
			If ExtDimension.ValueType <> New TypeDescription("CatalogRef.fmIncomesAndExpensesItems") Then
				CommonClientServer.MessageToUser(StrTemplate(NStr("en='Extra dimension %1 cannot take value %2';ru='Субконто %1 не может принимать значение %2'"), Index, Value));
			EndIf;
		EndIf;
	ElsIf Value = "Department" Then
		If ExtDimension.ValueType <> New TypeDescription("CatalogRef.fmDepartments") Then
			CommonClientServer.MessageToUser(StrTemplate(NStr("en='Extra dimension %1 cannot take value %2';ru='Субконто %1 не может принимать значение %2'"), Index, Value));
		EndIf;
	EndIf;
EndProcedure



