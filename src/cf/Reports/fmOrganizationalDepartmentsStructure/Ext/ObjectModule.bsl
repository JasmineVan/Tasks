
////////////////////////////////////////////////////////////////////////////////
// ПЕРЕМЕННЫЕ МОДУЛЯ

Var ReportExecutionParameters; // Структура выполнения отчета, втчи для отслеживания изменений

Var QueryByDepartments;

//Перем СоответствиеРаскраски;

Var SDLineAbsence;

Var OutputFinancialResult;

Var DepartmentTree;

Var WhiteColor;

Var OutputAreasCache; // Переменная для кэширования областей вывода

Var DepartmentTypes;
Var DepartmentsColoring;
Var SavedOutputAreas;

Var ExpandedNodes;	// информация о развёрнутых узлах
Var Departments;	// накопленные подразделения во время сбора дерева

Var AddReportParameters;
Var IndexcAreaExpand; // = 6
Var CompanyDescription;


////////////////////////////////////////////////////////////////////////////////
// ЭКСПОРТНЫЕ ПРОЦЕДУРЫ И ФУНКЦИИ

Function GetDepartmentTypesMap(Period = Undefined, Department = Undefined, InHierarchy = False) 

	TypesMap = New Map;

	Query = New Query;
	Query.Text = 
		"SELECT
		|	Departments.Ref AS Department,
		|	ISNULL(DepartmentsStateSliceLast.DepartmentType, Value(Catalog.fmDepartmentTypes.EmptyRef)) AS DepartmentType
		|FROM
		|	Catalog.fmDepartments AS Departments
		|		LEFT JOIN InformationRegister.fmDepartmentsState.SliceLast({Period}, {ConditionDepartmentRegister}) AS DepartmentsStateSliceLast
		|		ON (DepartmentsStateSliceLast.Department = Departments.Ref)
		|{ConditionDepartmentCatalog}";

	Query.Text = StrReplace(Query.Text, "{Period}", ?(Period = Undefined, "", "&Period"));
	Query.SetParameter("Period", Period);

	If NOT (Department = Undefined
		OR Department = Catalogs.fmDepartments.EmptyRef()) Then

		Query.Text = StrReplace(Query.Text, "{ConditionDepartmentRegister}", "Department IN" + ?(InHierarchy, " HIERARCHY", "") + "(&Department)");
		Query.Text = StrReplace(Query.Text, "{ConditionDepartmentCatalog}", "WHERE
			|	Ref IN" + ?(InHierarchy, " HIERARCHY", "") + "(&Department)");

		Query.SetParameter("Department", Department);

	Else

		Query.Text = StrReplace(Query.Text, "{ConditionDepartmentRegister}", "");
		Query.Text = StrReplace(Query.Text, "{ConditionDepartmentCatalog}", "");
	EndIf;


	Result = Query.Execute();

	SelectionDetails = Result.SELECT();

	While SelectionDetails.Next() Do
		TypesMap.Insert(SelectionDetails.Department, SelectionDetails.DepartmentType);
	EndDo;

	Return TypesMap;

EndFunction // ПолучитьСоответствиеВидовПодразделений()

Function GetCatalogItemColoring(Period = Undefined, TextColor = False, Department = Undefined, InHierarchy = False, StructureVersion = Undefined)
	ColoringMap 	= New Map;
	TypesMap 	= New Map;
	
	EmptyDepartmentType = Catalogs.fmDepartmentTypes.EmptyRef();
	
	Query = New Query;
	Query.Text = "SELECT
	               |	fmDepartmentTypes.Ref AS DepartmentType,
	               |	fmDepartmentTypes.Color AS Color
	               |FROM
	               |	Catalog.fmDepartmentTypes AS fmDepartmentTypes";
	
	TypesSettings = Query.Execute().Unload();
	
	TypesMap.Insert(EmptyDepartmentType, New Color(255, 255, 255));
	
	For Each Setting In TypesSettings Do
		If ValueIsFilled(Setting["Color" + ?( TextColor, "Text", "")]) Then
			XMLReader = New XMLReader;
			ObjectTypeXDTO	= XDTOFactory.Type("http://v8.1c.ru/8.1/data/ui","Color");
			XMLReader.SetString(Setting["Color" + ?( TextColor, "Text", "")]);
			ObjectXDTO			=	XDTOFactory.ReadXML(XMLReader, ObjectTypeXDTO);
			Serializer		= New XDTOSerializer(XDTOFactory);
			Color = Serializer.ReadXDTO(ObjectXDTO);
		Else
			Color = New Color(255, 255, 255);
		EndIf;
		TypesMap.Insert(Setting.DepartmentType, Color);
	EndDo; 

	
	 // Обращаемся к регистру иерархия подразделений
	TreeParameters = New Structure;
	TreeParameters.Insert("StructureVersionForBuilding", StructureVersion);
	TreeParameters.Insert("RootDepartment",        Department);
	TreeParameters.Insert("OutputTree",               False);
	
	DepartmentTableInHierarchy = fmBudgeting.DepartmentCommonTree(TreeParameters);
	DepartmentListInHierarchy = DepartmentTableInHierarchy.UnloadColumn("Department");
	//Добавим в список дочерних подразделений всех уровней анализируемое подразделение
	DepartmentListInHierarchy.Add(Department);
	
	Query = New Query();
	Query.Text = "SELECT
				   |	DepartmentHierarchy.Department,
				   |	Departments.Color AS IndividualColor,
				   |	Departments.SetColor AS SetIndColor,
				   |	DepartmentsStateSliceLast.DepartmentType
				   |FROM
				   |	InformationRegister.fmDepartmentHierarchy AS DepartmentHierarchy
				   |		LEFT JOIN InformationRegister.fmDepartmentsState.SliceLast({Period}, {ConditionDepartmentRegister}) AS DepartmentsStateSliceLast
				   |		ON DepartmentHierarchy.Department = DepartmentsStateSliceLast.Department
				   |		LEFT JOIN Catalog.fmDepartments AS Departments
				   |		ON DepartmentHierarchy.Department = Departments.Ref
			   	   |WHERE
				   |	DepartmentHierarchy.StructureVersion = &StructureVersion
				   |	{ConditionDepartmentCatalog}";
	
	Query.SetParameter("StructureVersion", StructureVersion);
	
	Query.Text = StrReplace(Query.Text, "{Period}", ?(Period = Undefined, "", "&Period"));
	Query.SetParameter("Period", Period);

	If NOT (Department = Undefined
		OR Department = Catalogs.fmDepartments.EmptyRef()) Then
		
		Query.Text = StrReplace(Query.Text, "{ConditionDepartmentRegister}", "Department IN (&DepartmentListInHierarchy)");
		Query.Text = StrReplace(Query.Text, "{ConditionDepartmentCatalog}", "AND DepartmentHierarchy.Department IN (&DepartmentListInHierarchy)");
		Query.SetParameter("DepartmentListInHierarchy", DepartmentListInHierarchy);
    Else
    	Query.Text = StrReplace(Query.Text, "{ConditionDepartmentRegister}", "");
		Query.Text = StrReplace(Query.Text, "{ConditionDepartmentCatalog}", "");
	EndIf;
	
	Result = Query.Execute();
	
	SelectionDetails = Result.SELECT();

	XMLReader = New XMLReader;
	ObjectTypeXDTO	= XDTOFactory.Type("http://v8.1c.ru/8.1/data/ui","Color");

	ColoringMap.Insert(Catalogs.fmDepartments.EmptyRef(), New Color(255, 255, 255));

	While SelectionDetails.Next() Do
		
		Color = Undefined;
		
		If SelectionDetails.SetIndColor Then
			
			If ValueIsFilled(SelectionDetails.IndividualColor) Then
				
				XMLReader.SetString(SelectionDetails.IndividualColor);
				ObjectXDTO			=	XDTOFactory.ReadXML(XMLReader, ObjectTypeXDTO);
				Serializer		= New XDTOSerializer(XDTOFactory);
				Color = Serializer.ReadXDTO(ObjectXDTO);
			Else
				Color = TypesMap[EmptyDepartmentType];
			EndIf;
			
		Else
			
			MapKey = ?(SelectionDetails.DepartmentType = NULL, EmptyDepartmentType, SelectionDetails.DepartmentType);
			If NOT TypesMap.Get(MapKey) = Undefined Then
				Color = TypesMap[MapKey];
			Else
				Color = TypesMap[EmptyDepartmentType];
			EndIf;

		EndIf;

		ColoringMap.Insert(SelectionDetails.Department, Color);
	EndDo;

	Return ColoringMap;

EndFunction // ПолучитьРаскраскуЭлементовСправочника()

Procedure GenerateOrgStructureReport(SpreadsheetFieldTree = Undefined, AddressExecutionParameters, Cancel = False) Export
	
	//Сообщить(Строка(ТекущаяДата()) + " начало"); //отладка
	
	//#Область ПроверкаИСчитываниеПараметровВыполненияОтчета
	ReportExecutionParameters = GetFromTempStorage(AddressExecutionParameters);
	If NOT TypeOf(ReportExecutionParameters) = Type("Structure") Then
		// Обязательный параметр
		Raise NStr("en='Error occurred while sending parameters for report execution';ru='Ошибка передачи параметров при выполнении отчета'");
	EndIf;

	If NOT ReportExecutionParameters.Property("ExpandedNodesAddress") Then
		// Обязательный параметр
		Raise NStr("en='Error occurred while sending parameters for report execution';ru='Ошибка передачи параметров при выполнении отчета'");
	Else

		ExpandedNodesAddress = ReportExecutionParameters.ExpandedNodesAddress;
	EndIf;

	OutputAreaAddress = Undefined;
	If ReportExecutionParameters.Property("OutputAreaAddress") Then
		OutputAreaAddress = ReportExecutionParameters.OutputAreaAddress;
	EndIf;

	GenerateForWebClient = False;
	If ReportExecutionParameters.Property("GenerateForWebClient") Then
		GenerateForWebClient = ReportExecutionParameters.GenerateForWebClient;
	EndIf;

	If ReportExecutionParameters.Property("DepartmentTree") Then
		DepartmentTree = ReportExecutionParameters.DepartmentTree;
	EndIf;

	RootDepartment = Undefined;
	If ReportExecutionParameters.Property("RootDepartment") Then
		RootDepartment = ReportExecutionParameters.RootDepartment;
	EndIf;

	Expand = False;
	If ReportExecutionParameters.Property("Expand") Then
		Expand = ReportExecutionParameters.Expand;
	EndIf;

	Collapse = False;
	If ReportExecutionParameters.Property("Collapse") Then
		Collapse = ReportExecutionParameters.Collapse;
	EndIf;
	
	StructureVersion = Undefined;
	If ReportExecutionParameters.Property("StructureVersion") Then
		StructureVersion = ReportExecutionParameters.StructureVersion;
	EndIf;
	 
	ConnectionLineTypeChange = ReportExecutionParameters.Property("ConnectionLineTypeChange");

	FullReportRegeneration = ReportExecutionParameters.Property("FullReportRegeneration");

	//#КонецОбласти

	//#Область ФормированиеСтруктурыДерева
	If DepartmentTree = Undefined Then

		DepartmentTree = New ValueTree;
		DepartmentTree.Columns.Add("Department");
		DepartmentTree.Columns.Add("Code");
		DepartmentTree.Columns.Add("Description");
		DepartmentTree.Columns.Add("FinResCurrentOrder",	New TypeDescription("Number", New NumberQualifiers(20, 2)));
		DepartmentTree.Columns.Add("AreaWidth",	New TypeDescription("Number", New NumberQualifiers(4)));			//ширина для прорисовки в дереве иерархии
		DepartmentTree.Columns.Add("HorLineWidth",	New TypeDescription("Number", New NumberQualifiers(4)));
		DepartmentTree.Columns.Add("ChildNodes",	New TypeDescription("Number", New NumberQualifiers(2)));
	//	ДеревоПодразделений.Колонки.Добавить("ДочернихУзловУДочерних",	Новый ОписаниеТипов("Число", Новый КвалификаторыЧисла(2)));	//ширина для прорисовки в дереве иерархии
		DepartmentTree.Columns.Add("NodeWidth",		New TypeDescription("Number", New NumberQualifiers(2)));			//ширина элемент с соед узлом, +/- и самой областью наименования ╟|+|хабахаба|
		DepartmentTree.Columns.Add("Expanded",		New TypeDescription("Boolean")); 
		DepartmentTree.Columns.Add("DepartmentType",New TypeDescription("CatalogRef.fmDepartmentTypes"));
		DepartmentTree.Columns.Add("ExpansionLevel",New TypeDescription("Number"), New NumberQualifiers(5));			// актуально для строк дерева, находящихся после корня
		DepartmentTree.Columns.Add("BranchDepartment",New TypeDescription("CatalogRef.fmDepartments"));			// подразделение 2-го уровня в выводимом дереве, которому подчиняется ветвь

	//	Если ИнфоМенеджер Тогда
		DepartmentTree.Columns.Add("Manager", New TypeDescription("CatalogRef.Users"));
	//	КонецЕсли;

		DepartmentTree.Columns.Add("Color", New TypeDescription("Color"));
		
		DepartmentTree.Columns.Add("DeletionMark", New TypeDescription("Boolean"));
	//#КонецОбласти

		ReportExecutionParameters.Insert("DepartmentTree", DepartmentTree);

	Else

		//Если Развернуть Или Свернуть Тогда // не надо перечитывать заново, т.к. вся необходимая структура уже ранее считана
		//	ДеревоПодразделений.Строки.Очистить();
		//КонецЕсли;
	EndIf;

	If DepartmentTree.Rows.Count() = 0 Then
		FullReportRegeneration = True;
	EndIf;


	If NOT TypeOf(OutputAreasCache) = Type("Structure") Then

		OutputAreasCache = New Structure;
	EndIf;

	ReportEndOfPeriod = StructureVersion.DateValidUntil;

	DepartmentTypes = GetDepartmentTypesMap(ReportEndOfPeriod, RootDepartment, True);

	DepartmentsColoring			= Undefined;
	If FullReportRegeneration // ПОЛУЧЕНИЕ РАСКРАСКИ ТОЛЬКО ПО НЕОБХОДИМОСТИ
		OR ReportExecutionParameters.Property("EventDepartment") Then
		
		DepartmentsColoring = GetCatalogItemColoring(ReportEndOfPeriod,, RootDepartment, True, StructureVersion);
		
	EndIf;
	
	
	//////////////////////////////////////////////////////////////
	ExpandedNodes = GetFromTempStorage(ExpandedNodesAddress);	
	If NOT TypeOf(ExpandedNodes) = Type("Array") Then
		
		ExpandedNodes = New Array;
		PutToTempStorage(ExpandedNodes, ExpandedNodesAddress);
		
	ElsIf Collapse Then
		
		ExpandedNodes.Clear();
	EndIf;
	
	SavedOutputAreas = Undefined;
	If IsTempStorageURL(OutputAreaAddress) Then

		SavedOutputAreas = GetFromTempStorage(OutputAreaAddress); // получение соответствия
		If NOT TypeOf(SavedOutputAreas) = Type("Map") Then
			
			SavedOutputAreas = New Map;
		Else

			If Collapse 
				OR Expand 
				OR FullReportRegeneration
				OR ConnectionLineTypeChange Then

				SavedOutputAreas.Clear();
				PutToTempStorage(SavedOutputAreas, OutputAreaAddress);
			EndIf;

		EndIf;

	EndIf;

	///////////////////////////////////////////////////////////////////////
	OutputRoot = True;

	Query = New Query();
	Query.Text = "SELECT
	               |	DepartmentHierarchy.Department AS Ref
	               |FROM
	               |	InformationRegister.fmDepartmentHierarchy AS DepartmentHierarchy
	               |WHERE
	               |	DepartmentHierarchy.DepartmentParent = Value(Catalog.fmDepartments.EmptyRef)
	               |	AND DepartmentHierarchy.StructureVersion = &StructureVersion
	               |	AND NOT DepartmentHierarchy.DeletionMark";
				   
	Query.SetParameter("StructureVersion", StructureVersion);

	Result = Query.Execute();

	SelectionDetails = Result.SELECT();
	
	Root = Catalogs.fmDepartments.EmptyRef();
	If SelectionDetails.Count() > 1 Then
		// остается как есть
		OutputRoot = NOT Department.IsEmpty();
		
	ElsIf SelectionDetails.Count() = 1 Then
		
		SelectionDetails.Next();
		Root = SelectionDetails.Ref;
		
	Else
		
		OutputRoot = False; // если в справочнике нет подразделений, то корень не выводится
	EndIf;

	Departments = New Array;
	////////////////////////////////////////////
	
	Parent = ?(ValueIsFilled(RootDepartment), RootDepartment, Root);

	CompanyDescription = "";
	
	DepartmentType = DepartmentTypes[Parent];
	
	If FullReportRegeneration Then
		
		DepartmentTree.Rows.Clear();

		// В корневое подразделение выводится код\наименование комапании, либо общее наименование компании из константы
		NewTreeRow				= DepartmentTree.Rows.Add();
		NewTreeRow.Department	= Parent;
		NewTreeRow.Expanded		= True;
		NewTreeRow.Code			= ?(ValueIsFilled(Parent), TrimAll(Parent.Code),		CompanyDescription);
		NewTreeRow.Description	= ?(ValueIsFilled(Parent), Parent.Description,		CompanyDescription);

		NewTreeRow.DepartmentType	= DepartmentType;

			NewTreeRow.Color = DepartmentsColoring[NewTreeRow.Department];
		

		
		// Пометку удаления будем вытягивать из РС Иерархия подразделений
		Query = New Query();
		Query.Text = "SELECT
		|	DepartmentHierarchy.Department AS Ref,
		|	DepartmentHierarchy.DeletionMark
		|FROM
		|	InformationRegister.fmDepartmentHierarchy AS DepartmentHierarchy
		|WHERE
		|	DepartmentHierarchy.StructureVersion = &StructureVersion
		|	AND DepartmentHierarchy.Department = &Department";
		
		Query.SetParameter("StructureVersion", StructureVersion);
		Query.SetParameter("Department",   Parent);
		Selection = Query.Execute().SELECT();
		If Selection.Next() Then
			NewTreeRow.DeletionMark = Selection.DeletionMark;
		Else
			NewTreeRow.DeletionMark = Parent.DeletionMark;
		EndIf;
		Level = 1;
		//////////////////////////////////////////////////////
		// ФОРМИРОВАНИЕ СТРУКТУРЫ ДЕРЕВА
		//ОбходДерева(НоваяСтрокаДерева, Родитель, Уровень,//,
		//	//РазвернутыеУзлы, Подразделения, ВидыПодразделений,
		//	//РаскраскаПодразделений, НаименованияЦветовПодразделений, 
		//	Развернуть//,
		//	//СохраненныеОбластиВывода
		//);
		TreeWalker(NewTreeRow, Parent, Level,
			Expand
			);
		//////////////////////////////////////////////////////

		////Подчиненных = 0;
		//ВычислитьПерсонал(ДеревоПодразделений, Подразделения);
		////НоваяСтрокаДерева.СотрудниковВклПодчинение = НоваяСтрокаДерева.Сотрудников + Подчиненных;
		
	ElsIf ReportExecutionParameters.Property("EventDepartment") Then
		
		//////////////////////////////////////////////////////////////////////////////////////////////////////////////
		// получение списка подраздлений, которые надо перечитать
		DepartmentList = New Array;
		If TypeOf(ReportExecutionParameters.EventDepartment) = Type("CatalogRef.fmDepartments") Then
			
			DepartmentList.Add(ReportExecutionParameters.EventDepartment);
			
		ElsIf TypeOf(ReportExecutionParameters.EventDepartment) = Type("Array") Then
			
			DepartmentList = ReportExecutionParameters.EventDepartment;
		Else
			
			Raise NStr("en='Invalid transfer of parameters';ru='Не верная передача параметров'");
		EndIf;
		
		////////////////////////////////////////////////////////////////////////
		// ОЧИСТКА КЭШИРОВАННЫХ ОБЛАСТЕЙ ВЫВОДА, КОТОРЫЕ НАДО ПЕРЕРИСОВАТЬ 
		OutputAreas = GetFromTempStorage(OutputAreaAddress);
		
		ProcessedRowsArray = New Array;// массив строк, по которым происходит пересчет сведений у родителей
		
		//////////////////////////////////////////////////////////////////////////////////////////////////////////////
		// чтение подразделений по списку
		For Each ItemDepartment In DepartmentList Do
			
			TreeRowEvent = DepartmentTree.Rows.Find(ItemDepartment, "Department", True);
			
			If TreeRowEvent = Undefined Then
				// возможно, подразделение, которое находится вне области вывода по текущему отбору
				Continue;
			EndIf;
			
			//МассивОбработанныхСтрок.Добавить(СтрокаДереваСобытие);
			
			If ReportExecutionParameters.Property("MovementPurpose") 
				AND ReportExecutionParameters.MovementPurpose = ItemDepartment Then
				
				TreeRowEvent.Expanded = True;
			Else
				
				TreeRowEvent.Expanded = ( NOT ExpandedNodes.Find(TreeRowEvent.Department) = Undefined );
			EndIf;
			
			
			//Если СтрокаДереваСобытие.Развернут И ПараметрыВыполненияОтчета.Свойство("ОбновлениеВетви") Тогда
			If ReportExecutionParameters.Property("BranchRefresh") Then
				TreeRowEvent.Rows.Clear();
			EndIf;
			
			//Если СтрокаДереваСобытие.Развернут И СтрокаДереваСобытие.Строки.Количество() = 0 Тогда
			If TreeRowEvent.Rows.Count() = 0 Then
				
				//ОбходДерева(СтрокаДереваСобытие, СтрокаДереваСобытие.Подразделение, СтрокаДереваСобытие.Уровень() + 1,
				//	//РазвернутыеУзлы, Подразделения, ВидыПодразделений,
				//	//РаскраскаПодразделений, НаименованияЦветовПодразделений, 
				//	Развернуть//,
				//	//	СохраненныеОбластиВывода
				//	);
				TreeWalker(TreeRowEvent, TreeRowEvent.Department, TreeRowEvent.Level() + 1,
					Expand
					);
				
			EndIf;
				
			////Подчиненных = 0;
			//ВычислитьПерсонал(СтрокаДереваСобытие, Подразделения);
			////СтрокаДереваСобытие.СотрудниковВклПодчинение = СтрокаДереваСобытие.Сотрудников + Подчиненных;
			
			////////////////////////////////////////////////////////////////////////
			// ОЧИСТКА КЭШИРОВАННЫХ ОБЛАСТЕЙ ВЫВОДА, КОТОРЫЕ НАДО ПЕРЕРИСОВАТЬ 
			If NOT OutputAreas[TreeRowEvent.BranchDepartment] = Undefined Then
				
				OutputAreas.Delete(TreeRowEvent.BranchDepartment);
			EndIf;
			
		EndDo;
		
		PutToTempStorage(OutputAreas, OutputAreaAddress);
		
		// ПЕРЕСЧЕТ СЛУЖЕБНОЙ ИНФОРМАЦИИ И ИНФОРМАЦИИ О СОТРУДНИКАХ - для каждой ветви на самый верх
		If ReportExecutionParameters.Property("BranchRefresh") Then
			
			For Each ProcessedRow In ProcessedRowsArray Do
				
				Try
					
					ParentRow = ProcessedRow.Parent;
				Except
					
					Continue;
				EndTry;
				
				While NOT ParentRow = Undefined Do
					
					ParentRow.ChildNodes = 0;
					// РАСЧЕТ СОТРУДНИКОВ КОРНЯ
					//РодительскаяСтрока.СотрудниковВклПодчинение = РодительскаяСтрока.Сотрудников;
					For Each ChildRow In ParentRow.Rows Do
						
						//РодительскаяСтрока.СотрудниковВклПодчинение = РодительскаяСтрока.СотрудниковВклПодчинение + ДочерняяСтрока.СотрудниковВклПодчинение;
						ParentRow.ChildNodes = ParentRow.ChildNodes + 1;
					EndDo;
					
					ParentRow = ParentRow.Parent;
				EndDo;
				
			EndDo;
		EndIf;
		
	ElsIf Expand Then
		
		TreeRows = DepartmentTree.Rows.FindRows(New Structure("Expanded", False), True);
		For Each TreeRow In TreeRows Do
			
			TreeRow.Expanded = True;
			
			If ExpandedNodes.Find(TreeRow.Department) = Undefined
				AND TreeRow.Rows.Count() > 0 Then
				
				ExpandedNodes.Add(TreeRow.Department);
			EndIf;
		EndDo;
		
	ElsIf Collapse Then
		
		TreeRows = DepartmentTree.Rows.FindRows(New Structure("Expanded", True), True);
		For Each TreeRow In TreeRows Do
			
			TreeRow.Expanded = False;
		EndDo;
		//! массив развернутых узлов очищен ранее
		
	EndIf;
	
	///////////////////////////////////////////////////////////////////////////
	OutputFinancialResult = BudgetingFRFlag;
	
	If OutputFinancialResult AND Departments.Count() = 0 Then
		
		OutputDepartments(DepartmentTree, Departments);
	EndIf;
	
	ColorFillRefresh = ReportExecutionParameters.Property("ColorFillRefresh");
	
	TitleHeight = 0;
	/////////////////////////////////////////////////////////////////////////////////////////////
	//
	// ВЫВОД ДЕРЕВА
	//
	OutputStructureTree(SpreadsheetFieldTree, DepartmentTree, OutputRoot, GenerateForWebClient, OutputAreaAddress, TitleHeight, ColorFillRefresh);
	//
	/////////////////////////////////////////////////////////////////////////////////////////////
	If ReportExecutionParameters.Property("FullReportRegeneration") Then
		ReportExecutionParameters.Delete("FullReportRegeneration");
	EndIf;
	If ReportExecutionParameters.Property("EventDepartment") Then
		ReportExecutionParameters.Delete("EventDepartment");
	EndIf;
	If ReportExecutionParameters.Property("ConnectionLineTypeChange") Then
		ReportExecutionParameters.Delete("ConnectionLineTypeChange");
	EndIf;
	If ReportExecutionParameters.Property("BranchRefresh") Then
		ReportExecutionParameters.Delete("BranchRefresh"); // когда изменены данные о подразделении или добавлено новое
	EndIf;
	If ReportExecutionParameters.Property("ColorFillRefresh") Then
		ReportExecutionParameters.Delete("ColorFillRefresh");
	EndIf;
	If ReportExecutionParameters.Property("MovementPurpose") Then
		ReportExecutionParameters.Delete("MovementPurpose");
	EndIf;
	If ReportExecutionParameters.Property("PositioningByCode") Then
		ReportExecutionParameters.Delete("PositioningByCode");
	EndIf;
	
	PutToTempStorage(ReportExecutionParameters, AddressExecutionParameters);
	
	SpreadsheetFieldTree.FixedTop = TitleHeight;
	
	//Сообщить(Строка(ТекущаяДата()) + " окончание"); //отладка
	
EndProcedure // СформироватьОтчетОргСтруктуры()


//////////////////////////////////////////////////////////////////////////////////
//// ПРОЦЕДУРЫ И ФУНКЦИИ ОБЩЕГО НАЗНАЧЕНИЯ

Procedure TreeWalker(DepartmentTree, Parent, Level,
		Expand = False
		)

	ReportEndOfPeriod = StructureVersion.DateValidUntil;
	
	
	FRTree = Undefined;
	If BudgetingFRFlag Then
		ParametersStructure = New Structure;
		If ValueIsFilled(Department) Then
			ParametersStructure.Insert("RootDepartment",        Department);
		Else
			ParametersStructure.Insert("RootDepartment",        Undefined);
		EndIf;
		ParametersStructure.Insert("StructureVersionForBuilding", StructureVersion);
		ParametersStructure.Insert("HeaderPeriodEnd",            EndOfMonth(ReportEndOfPeriod));
		ParametersStructure.Insert("OutputTree",               False);
		
		
		//1409
		_DepartmentsVT = fmBudgeting.DepartmentCommonTree(ParametersStructure);
		_Departments = _DepartmentsVT.UnloadColumn("Department");
		_Departments.Add(Department);
		
		FRTree = GetFinancialResultBudgeting(DepartmentTree, _Departments, True, _DepartmentsVT);
	EndIf;
	
	DepartmentTable = TemporaryModule.GetDepartmentTree(ThisObject, DepartmentTree, FRTree, IncludeMarkedOnDeletion, StructureVersion);
	
	For Each DepartmentTableRow In DepartmentTable Do
		DepartmentTableRow.Code = TrimAll(DepartmentTableRow.Code);
	EndDo; 
	
	/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	
	_DepartmentTree = New ValueTree;
	_DepartmentTree.Columns.Add("Department",		New TypeDescription("CatalogRef.fmDepartments",, New StringQualifiers(36)));
	_DepartmentTree.Columns.Add("Code",				New TypeDescription("String",, New StringQualifiers(25)));
	_DepartmentTree.Columns.Add("Description",		New TypeDescription("String",, New StringQualifiers(100)));
	_DepartmentTree.Columns.Add("DepartmentType",	New TypeDescription("CatalogRef.fmDepartmentTypes"));
	
	_DepartmentTree.Columns.Add("Manager",		New TypeDescription("CatalogRef.Users"));
	
	_DepartmentTree.Columns.Add("ParentCode",	New TypeDescription("String",, New StringQualifiers(25)));
	_DepartmentTree.Columns.Add("Level",		New TypeDescription("Number"));
	_DepartmentTree.Columns.Add("Parent",		New TypeDescription("CatalogRef.fmDepartments",, New StringQualifiers(36)));
	
	_DepartmentTree.Columns.Add("DeletionMark",New TypeDescription("Boolean"));
	
	
	_DepartmentTree.Columns.Add("FinResCurrentOrder",		New TypeDescription("Number", New NumberQualifiers(22, 2)));
	//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	
	//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	QueryForLinkStartExpression = New Query;
	QueryForLinkStartExpression.TempTablesManager = New TempTablesManager;
	QueryForLinkStartExpression.Text = "SELECT
	|	DepartmentHierarchy.ParentCode AS ParentCode,
	|	DepartmentHierarchy.Level
	|INTO TemporaryTotal
	|FROM
	|	&DepartmentHierarchyTable AS DepartmentHierarchy
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
	|	Level";
	
	QueryForLinkStartExpression.SetParameter("DepartmentHierarchyTable", DepartmentTable);
	VT = QueryForLinkStartExpression.Execute().Unload();
	
	
	//СхемаКомпоновкиДанных.СвязиНаборовДанных[0].НачальноеВыражение = """"+Строка(ТЗ[0].КодРодителя)+"""";
	//СхемаКомпоновкиДанных.СвязиНаборовДанных[0].НачальноеВыражение = """"+СокрЛП(Родитель.Код)+"""";
	DepartmentTreeSource = GetDepartmentTree(
		DepartmentTable, 
		_DepartmentTree.Columns, 
		"""" + ?(ValueIsFilled(Parent), Parent.Code, String(VT[0].ParentCode)) + """");
		
	/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	
	CombineTrees(DepartmentTreeSource, DepartmentTree, Expand);
	
	// Если строка дерева, то заполнить сопуствующую информацию
	If TypeOf(DepartmentTree) = Type("ValueTreeRow") Then
		
		TableRows = DepartmentTable.FindRows(New Structure("Department", DepartmentTree.Department));
		If TableRows.Count() > 0 Then
			
			DepartmentTree.Manager			= TableRows[0].Manager;
			DepartmentTree.FinResCurrentOrder= TableRows[0].FinResCurrentOrder;
		EndIf;
		
		DepartmentTree.ChildNodes = 0;
		// РАСЧЕТ СОТРУДНИКОВ КОРНЯ
		For Each RootSubrow In DepartmentTree.Rows Do
			
			DepartmentTree.ChildNodes = DepartmentTree.ChildNodes + 1;
		EndDo;
		
		
	EndIf;
		
EndProcedure // ОбходДерева3()

Procedure CombineTrees(SourceTree, RecieverTree, Expand = False)
	
	For Each RowSourceTree In SourceTree.Rows Do
		
		RowRecieverTree = RecieverTree.Rows.Add();
		FillPropertyValues(RowRecieverTree, RowSourceTree);
		
		Departments.Add(RowSourceTree.Department);
		
		If Expand Then
			
			RowRecieverTree.Expanded = True;
			ExpandedNodes.Add(RowRecieverTree.Department);
		Else
			
			RowRecieverTree.Expanded = (NOT ExpandedNodes.Find(RowRecieverTree.Department) = Undefined);
		EndIf;
		
		Cached = False;
		If NOT SavedOutputAreas = Undefined Then
			
			Cached = NOT (SavedOutputAreas[RowRecieverTree.Department] = Undefined);
		EndIf;
		
		RowRecieverTree.Color = DepartmentsColoring[RowRecieverTree.Department];
		
		////////////////////////////////////////////////////////////
		If RowRecieverTree.Level() = 1 Then
		
			RowRecieverTree.BranchDepartment = RowSourceTree.Department;
		Else
		
			RowRecieverTree.BranchDepartment = RowRecieverTree.Parent.BranchDepartment;
		EndIf;
		
		//Если СтрокаДеревоПриёмник.Развернут
		//	И Не Кэширован Тогда
			
			CombineTrees(RowSourceTree, RowRecieverTree, Expand);
			
				
		//КонецЕсли;
		
		RowRecieverTree.ChildNodes = RowSourceTree.Rows.Count();
		
	EndDo;
	
EndProcedure // ОбходДерева3()

// Выводит дерево состава
// без параметров
Procedure OutputStructureTree(Tab, DepartmentTree, OutputRoot = True, GenerateForWebClient = False, OutputAreaAddress = Undefined, TitleHeight = 0, AppearanceRefresh = False) Export

	// В ДАННОЙ ПРОЦЕДУРЕ ВЫВОДИТСЯ ТОЛЬКО "КОРЕНЬ" И ГОРИЗОНТЕЛЬНАЯ ЛИНИЯ.
	// ЗАТЕМ ВЫЗЫВАЕТСЯ МЕТОД ВЫВОДА ДОЧЕРНИХ ЭЛЕМЕНТОВ.

	//Таб.Очистить();
	Tab = New SpreadsheetDocument;

	ResultDocument = New SpreadsheetDocument;
	Template = ThisObject.GetTemplate("StructureTree");

	AddReportParameters = GetFromTempStorage(AdditionalReportParameters);

	WhiteColor = New Color(255, 255, 255);
	
	If DepartmentTree.Rows.Count() = 0 Then
		Return;
	EndIf;

	ResultDocument.Clear();

	SDLineAbsence	= New Line(SpreadsheetDocumentCellLineType.None);
	
	AreaRoot		= Template.GetArea("Items|Body");
	ConnectionArea	= AreaRoot.Area("ConnectionArea_rlsp");
	ConnectionArea.RightBorder = SDLineAbsence;
	
	AreaBody		= Template.GetArea("Items|Body");

	TreeRow = DepartmentTree.Rows[0];

	RootItemLength	= AreaRoot.TableWidth;		//Длинна "квадратика" корня в колоноках
	ItemLength		= AreaBody.TableWidth;		//Длинна "квадратика" подразделения в колоноках
	ItemMiddle	= Int(ItemLength / 2);


	// Заполняется соответствие цветов раскраски подразделений для построения отчета
	Query = New Query;
	Query.Text = "SELECT
	               |	fmDepartmentTypes.Ref AS DepartmentType,
	               |	fmDepartmentTypes.Color AS ColorXDTO
	               |FROM
	               |	Catalog.fmDepartmentTypes AS fmDepartmentTypes";
	
	TypesSettings = Query.Execute().Unload();
	TypesSettings.Columns.Add("Color");
	TypesSettings.Columns.Add("TextColor");
	
	
	For Each Setting In TypesSettings Do
		If ValueIsFilled(Setting.ColorXDTO) Then
			XMLReader = New XMLReader;
			ObjectTypeXDTO	= XDTOFactory.Type("http://v8.1c.ru/8.1/data/ui","Color");
			XMLReader.SetString(Setting.ColorXDTO);
			ObjectXDTO			=	XDTOFactory.ReadXML(XMLReader, ObjectTypeXDTO);
			Serializer		= New XDTOSerializer(XDTOFactory);
			Color = Serializer.ReadXDTO(ObjectXDTO);
		Else
			Color = New Color(255, 255, 255);
		EndIf;
		Setting.Color = Color;
	EndDo; 

	//НастройкиВидов = РегистрыСведений.НастройкиВидовПодразделений.ПолучитьНастройки();


	SavedOutputAreas = Undefined;
	If IsTempStorageURL(OutputAreaAddress) Then

		SavedOutputAreas = GetFromTempStorage(OutputAreaAddress); // получение соответствия
	EndIf;


	//#Область РасчетДлиныГлавнойГорЛинии

	//!!! Вычисление длины горизонтальной линии для её последующего вывода
	// складывается из длинны элементов и развернутости подчинённых им элементов
	MainHorLineLength = 0;

	ItemsCount = TreeRow.Rows.Count();

	For Each TreeSubrow In TreeRow.Rows Do

		RowIndex = TreeRow.Rows.IndexOf(TreeSubrow);

		If RowIndex = ItemsCount - 1 Then
			//Последний элемент не учитывать т.к. после него расчет длины гор. линии не актуален
			Break;
		EndIf;

		MainHorLineLength = MainHorLineLength + ItemLength; //сама длина элемента

		ParametersStructure = Undefined;
		If NOT SavedOutputAreas = Undefined Then
			ParametersStructure = SavedOutputAreas[TreeSubrow.Department];
		EndIf;

		If NOT ParametersStructure = Undefined Then

			NestingLevel = ParametersStructure.NestingLevel;
		Else

			//теперь надо вытащить информацию о максимальном уровне вложенности для данной строки с учетом свертки
			NestingLevel = MaxTreeNestingLevel(TreeSubrow,);
			TreeSubrow.ExpansionLevel = NestingLevel;
		EndIf;

		// и по этому кол-ву ур-ней прибавиьт 2 ячейки
		MainHorLineLength = MainHorLineLength + (NestingLevel * 2);

		If //ИндексСтроки > 0 И
			NestingLevel = 0 Then

			// добавление разделенительного отступа после элемента, если у него не раскрыты подчиненные
			MainHorLineLength = MainHorLineLength + 1;
		EndIf;
		
	EndDo;
	
	//Вывод заголовка
	AreaTitle 	= Template.GetArea("Title");
	AreaTitle.Parameters.Title = NStr("en='Organizational structure';ru='Организационная структура подразделений'");
	Tab.Put(AreaTitle);
	
	If OutputRoot Then

		SDRoot = New SpreadsheetDocument;
		
		For InfoInd = 1 To (IndexcAreaExpand - 1) Do // 1 основная информация, 2 - Менеджер(опционально), 3-цвет текстом(опционально)

			If InfoInd = 1 Then
				// чтобы сработал основной шаг
				AreaIndent 	= Template.GetArea("Items|Indent");

			ElsIf InfoInd = 2
				AND InfoManager Then

				AreaIndent 	= Template.GetArea("AddInfoManager|Indent"); // переопределен

				
			ElsIf InfoInd = 4
				AND OutputFinancialResult Then

				AreaIndent 	= Template.GetArea("AreaFinRes|Indent"); // переопределен

			Else

				Continue;
			EndIf;

			// Первым стандартно выводится отступ
			SDRoot.Put(AreaIndent);

			If InfoInd = 1 Then

				// ВЫВОД ПРОБЕЛОВ ПЕРЕД "КОРНЕВЫМ" ЭЛЕМЕНТМ
				RootPosition = Int((MainHorLineLength - RootItemLength) / 2);

				If ItemsCount > 0 Then
					// Если элементов более одного, необходимо вывести отступов на половину длины элемента 
					// до верхней соединительной линии первого подчиненного
					RootPosition = RootPosition + ItemMiddle;

				EndIf;

			EndIf;

			// Вывод необходимого числа отступов перед самим корнем
			For Ind=1 To RootPosition Do

				
				SDRoot.Join(AreaIndent);
			EndDo;

			// Вывод квадрата корня
			If InfoInd = 1 Then

				AreaRoot.Parameters.Description = TreeRow[DepPresentation];

				// установка параметров размещения текста
				//ИменованнаяОбласть = ОбластьКорень.Область("ЭлементКорень");
				NamedArea = AreaRoot.Area("Item");
				NamedArea.TextPlacement = ?( WrapDepartmentDescription,
					SpreadsheetDocumentTextPlacementType.Wrap,
					SpreadsheetDocumentTextPlacementType.Cut );

				NamedArea.Font		= AddReportParameters.DescriptionAreaTextFont;
				NamedArea.TextColor	= AddReportParameters.DescriptionAreaTextColor;

				//Параметр расшифровки
				AreaRoot.Parameters.Department = TreeRow.Department;

			ElsIf InfoInd = 2
				AND InfoManager Then

				// Вывод сведений о менеджере
				//ОбластьКорень = Макет.ПолучитьОбласть("ДопИнфоМенеджер|Корень");
				AreaRoot = Template.GetArea("AddInfoManager|Body");
				AreaRoot.Parameters.Manager = TreeRow.Manager;
				
				AreaRoot.Areas.AreaAddInfoManager.Font	= AddReportParameters.ManagerAreaTextFont;
				AreaRoot.Areas.AreaAddInfoManager.TextColor	= AddReportParameters.ManagerAreaColorText;
				
			ElsIf InfoInd = 4
				AND OutputFinancialResult Then

				AreaRoot = Template.GetArea("AreaFinRes|Body");

				AreaRoot.Areas.FR_N.Font		= AddReportParameters.FRAreaTextFont;
				AreaRoot.Areas.FR_N.TextColor	= AddReportParameters.FRAreaTextColor;
	
				//Вывод финансового результата для корня дерева

				FinResult = TreeRow.FinResCurrentOrder;
				If FinResult <> Undefined Then
					
						
					AreaRoot.Parameters.FinResCurrent = Format(FinResult,FormatStringOfReportsAmounts(MonetaryIndicator)); 
					
					ParametersStructure = New Structure;
					ParametersStructure.Insert("Department",    TreeRow.Department);
					ParametersStructure.Insert("DepartmentType", TreeRow.DepartmentType);
					ParametersStructure.Insert("Amount",            FinResult);

					AreaRoot.Parameters.FinResultDetails = ParametersStructure;

				EndIf;

			EndIf;

			SetAreaColor(AreaRoot, TreeRow);
			/////////////////////////////////////
			
			
			// ВЫВОД САМОГО КОРНЕВОГО "ЭЛЕМЕНТА"
			SDRoot.Join(AreaRoot);
			
		EndDo;
		// КОРЕНЬ ВЫВЕДЕН
		
		// завершающая сплошная линия снизу
		SDRoot.Areas[AreaRoot.Areas[AreaRoot.Areas.Count()-1].Name].BottomBorder = New Line(SpreadsheetDocumentCellLineType.Solid, 1);
		
		
		Tab.Join(SDRoot);
		
		///////////////////////////////////////////////////////////////////////////
		// ВЫВОД "КОРОБКИ" СОЗДАНИЯ КОРНЕВОГО ПОДРАЗДЛЕЛЕНИЯ
		//Если ЭтотОбъект.Подразделение.Пустая() Тогда
		//	Если ЭтотОбъект.ВерсияСтруктуры = уфБюджетирование.ВернутьАктуальнуюВерсиюСтруктурыПодразделений() Тогда
		//		Коробка = Новый ТабличныйДокумент;
		//		ВывестиОбластьСозданияКорневогоПодразделения(Коробка, Макет);
		//		
		//		Таб.Присоединить(Коробка);
		//	КонецЕсли;
		//КонецЕсли;
		///////////////////////////////////////////////////////////////////////////
	
	EndIf;
	
	
	
	//Таб.Вывести(ДокументРезультат);
	
	ResultDocument.Clear();
	
	AreaIndent		= Template.GetArea("RootHorizontal|Indent");
	AreaNodeBranching= Template.GetArea("RootHorizontal|ConnectionWithRoot");
	AreaNodeHorLine	= Template.GetArea("RootHorizontal|MainLine");
	
	
	//#Область ВыводГлавнойГоризонтальнойЛинии
	//////////////////////////////////////////////
	// ВЫВОД ГЛАВНОЙ ГОРИЗОНТАЛЬНОЙ ЛИНИИ

	If MainHorLineLength > 0 Then

		ResultDocument.Put(AreaIndent);

		If ItemsCount > 0 Then
			For Counter = 1 To ItemMiddle Do
				ResultDocument.Join(AreaIndent);
			EndDo;
		EndIf;

		SchemaMiddle = Int(MainHorLineLength / 2);
		For Ind = 1 To MainHorLineLength Do

			If Ind = SchemaMiddle 
				AND OutputRoot Then
				GenerateLineType(AreaNodeBranching, "ConnectionWithRoot");
				ResultDocument.Join(AreaNodeBranching);
			Else
				GenerateLineType(AreaNodeHorLine, "MainLine");
				ResultDocument.Join(AreaNodeHorLine);
			EndIf;

		EndDo;

		Tab.Put(ResultDocument);
		// ГЛАВНАЯ ГОРИЗОНТАЛЬНАЯ ЛИНИЯ ВЫВЕДЕНА

	Else
		// если у корневого элемента только один дочерний элемент, то выводить горизонтальную линию не требуется
	EndIf;

	//#КонецОбласти

	////////////////////////////////////////////

	/////////////////////////////////////////////
	// ВЫВОД ДОЧЕРНИХ ЭЛЕМЕНТОВ НИЖЕ ПЕРВОГО УРОВНЯ

	DLLevels = New Map();


	ExpandedDepartmentsInFirst		= 0;
	MaximumExpandedDepartments	= 0; // для вывода линий отступа самого первого элемента второго уровня, чтобы высота строк во всей схеме вниз по иерархии была одинакова
	For Each TreeSubrow In TreeRow.Rows Do

		ItemIndex = TreeRow.Rows.IndexOf(TreeSubrow);

		If NOT SavedOutputAreas = Undefined Then

			StoredValue = SavedOutputAreas[TreeSubrow.Department];
			If NOT StoredValue = Undefined Then

				CurrentExpansion = StoredValue.CurrentExpansion;

			Else

				CurrentExpansion = 0;
				ExpandedDepartments(TreeSubrow, CurrentExpansion);

				SavedOutputAreas.Insert(TreeSubrow.Department,
						New Structure("SD, NestingLevel, CurrentExpansion",,, CurrentExpansion));

			EndIf;

		Else

			CurrentExpansion = 0;
			ExpandedDepartments(TreeSubrow, CurrentExpansion);

		EndIf;

		If ItemIndex = 0 Then
			ExpandedDepartmentsInFirst = CurrentExpansion;
		EndIf;

		MaximumExpandedDepartments = Max( MaximumExpandedDepartments, CurrentExpansion );

	EndDo;
	// найден максимальный уровень раскрытия после 2го уровня( главная гор..линия )

	//Если предыдущий элемент раскрыт, то стандартный пробел не выводится для визуальной компактности структуры 
	WereChangesInAreas = False;

	ChildLevels = New Array;
	SecondLevelItem = TreeRow.Rows.Count();
	For Each TreeSubrow In TreeRow.Rows Do

		ItemIndex = TreeRow.Rows.IndexOf(TreeSubrow);

		IndentOutput = 1; // отступ только справа - по-умолчанию.
		If ItemIndex = 0 Then

			// Если элемент первый по очереди и он:
			IndentOutput = ?(TreeSubrow.Expanded
				AND TreeSubrow.ChildNodes > 0,
				-1,	// раскрыт		- выводится толька отступ слева
				2);	// не раскрыт	- выводится отступ слева и справа

		ElsIf ItemIndex = TreeRow.Rows.Count() - 1 Then

			// Если элемент последний, то
			IndentOutput = 0; // отступы не выводятся вовсе
		EndIf;

		ChildLevels.Clear();

		RowSpreadsheetDocument = Undefined;
		If NOT SavedOutputAreas = Undefined Then

			StoredValue = SavedOutputAreas[TreeSubrow.Department];
			If NOT StoredValue = Undefined Then
				RowSpreadsheetDocument = StoredValue.SD;
			EndIf;

		EndIf;


		If RowSpreadsheetDocument = Undefined Then

			RowSpreadsheetDocument = New SpreadsheetDocument;

			OutputTreeRow(TreeSubrow, Template, RowSpreadsheetDocument, DLLevels, ChildLevels, IndentOutput, GenerateForWebClient);

			If (NOT SavedOutputAreas = Undefined) Then

				OutputStructure = SavedOutputAreas[TreeSubrow.Department];
				OutputStructure.SD					= RowSpreadsheetDocument;
				OutputStructure.NestingLevel	= TreeSubrow.ExpansionLevel;

				WereChangesInAreas = True;

			EndIf;

		Else	// Табличный документ не нужно перефорировывать и он сохранён в хранилище

			// Надо обновить результат
			For Each Area In RowSpreadsheetDocument.Areas Do
				
				If NOT AppearanceRefresh Then // когда изменены настройки оформления
					Break; 
				EndIf;

				If Area.Name = "Expansion" Then
					Continue;
				EndIf;

				If Left(Area.Name, 7) = "Item" Then
					
					DepartmentCode = StrReplace(Area.Name, "Item_", "");
					TreeRowWithFR = DepartmentTree.Rows.Find(DepartmentCode, "Code", True);
					
					Area.Text		= TreeRowWithFR[DepPresentation];
					Area.Font		= AddReportParameters.DescriptionAreaTextFont;
					Area.TextColor	= AddReportParameters.DescriptionAreaTextColor;
					
					
					SetAreaColor(Area, TreeRowWithFR);
					
				ElsIf Left(Area.Name, 3) = "FR_" Then

					FRText = "";
					If OutputFinancialResult Then

						DepartmentCode = StrReplace(Area.Name, "FR_", "");
						TreeRowWithFR = DepartmentTree.Rows.Find(DepartmentCode, "Code", True);
						
						If NOT TreeRowWithFR = Undefined Then
							FRText =  Format(TreeRowWithFR.FinResCurrentOrder,FormatStringOfReportsAmounts(MonetaryIndicator));								
						EndIf;

						Area.Font		= AddReportParameters.FRAreaTextFont;
						Area.TextColor	= AddReportParameters.FRAreaTextColor;
						
						SetAreaColor(Area, TreeRowWithFR);
					EndIf;

					Area.Text = FRText;

				ElsIf Left(Area.Name, 22) = "AreaAddInfoManager" Then
					
					Area.Font		= AddReportParameters.ManagerAreaTextFont;
					Area.TextColor	= AddReportParameters.ManagerAreaColorText;
					
					DepartmentCode = StrReplace(Area.Name, "AreaAddInfoManager_", "");
					TreeRowWithFR = DepartmentTree.Rows.Find(DepartmentCode, "Code", True);
					
					SetAreaColor(Area, TreeRowWithFR);
					
				EndIf;
			EndDo;
			
		EndIf;

		//////////////////////////////////////////////////////////////////////////////////////////////////////////
		//	Первый элемент (со всей его развернутой структурой) выведен, и теперь надо добавить отступы вниз. чтобы высота всех элементов,
		//	раскрытых ниже и правее была одинакова, а не выставлялась по автовысоте табличного документа
		If SecondLevelItem > 1
			AND ItemIndex = 0 
			AND MaximumExpandedDepartments > 0 Then

			AddedIndents = MaximumExpandedDepartments - ExpandedDepartmentsInFirst; //Самый макс уровень раскрытия - ур. раскрытия текущего
			If AddedIndents > 0 Then

				AddIndentsToBottom(AddedIndents, RowSpreadsheetDocument, Template);

				If (NOT SavedOutputAreas = Undefined) Then

					OutputStructure = SavedOutputAreas[TreeSubrow.Department];
					OutputStructure.CurrentExpansion = OutputStructure.CurrentExpansion + AddedIndents;
						//Новый Структура("ТД, УровнейВложенности",
						//	ТабличныйДокументСтроки, ПодстрокаДерева.УровнейРаскрытия));

					WereChangesInAreas = True;

				EndIf;

			EndIf;
		EndIf;
		///////////////////////////////////////////////////////////////////////////////////////////////////////////
		
		If SecondLevelItem > 1 Then
			// перевод на новую строку уже сделан ранее
			Tab.Join(RowSpreadsheetDocument); 
		Else
			// если подразделение только одно, то перевода еще не было
			Tab.Put(RowSpreadsheetDocument);
		EndIf;
		
	EndDo;
	
	// ВЫВОД "КОРОБКИ" СОЗДАНИЯ КОРНЕВОГО ПОДРАЗДЛЕЛЕНИЯ
	//Если Не ВыводитьКорень 
	//	И Подразделение.Пустая() 
	//	И РольДоступна("ПолныеПрава") Тогда
	//	
	//	Коробка = Новый ТабличныйДокумент;
	//	ВывестиОбластьСозданияКорневогоПодразделения(Коробка, Макет);
	//		
	//	Таб.Присоединить(Коробка);
	//КонецЕсли;

	If WereChangesInAreas Then

		PutToTempStorage(SavedOutputAreas, OutputAreaAddress); // получение соответствия
	EndIf;


EndProcedure // ВывестиДеревоСостава()

//обход дерева и вывод элементов
//Выводить отступ: -1 - отступ слева, 0 - не выводить, 1 - отступ справа
Procedure OutputTreeRow(TreeRow, Template, Tab, DLLevels, ChildLevels_, OutputIndent = False, GenerateForWebClient = False)

	TreeRowLevel = TreeRow.Level();
	
	//////////////////////////////////////////////////////////////////////////////
	// определение, является ли ответственный подразделения совместителем
	ResponsibleCompetitor = False;
	If InfoManager AND 
		NOT IsBlankString(TreeRow.Manager) Then
		
		_RowParent = TreeRow.Parent;
		While NOT _RowParent = Undefined Do
			
			If _RowParent.Manager =  TreeRow.Manager Then
				
				ResponsibleCompetitor = True;
				Break;
				
			Else
				
				_RowParent = _RowParent.Parent;
			EndIf;
			
		EndDo; 
		
	EndIf;
	//////////////////////////////////////////////////////////////////////////////
	
	//ОбластьРисунки	= Макет.ПолучитьОбласть("Элементы|Рисунки");
	AreaPictures = GetOutputAreaCache(Template, "Items|Pictures");

	For InfoInd = 1 To IndexcAreaExpand Do // 1 основная информация, 2 - Менеджер(опционально), 3-цвет текстом(опционально)

		If InfoInd = 1
			//И УровеньСтрокиДерева = 1 
			Then

		//	// только для элементов под главной чертой
		//	ИмяСекцииДопИнфо = "ШапкаЭлементы";

		//ИначеЕсли ИндИнфо = 2 Тогда

			SectionNameAddInfo = "Items";

		ElsIf InfoInd = 2
			AND InfoManager Then

			SectionNameAddInfo = "AddInfoManager";
			
			
		ElsIf InfoInd = 4
			AND OutputFinancialResult Then

			SectionNameAddInfo = "AreaFinRes";

		ElsIf InfoInd = IndexcAreaExpand Then

			SectionNameAddInfo = "Expansion";

		Else

			Continue;
		EndIf;

		//ОбластьОтступ	= Макет.ПолучитьОбласть(ИмяСекцииДопИнфо + "|Отступ");
		AreaIndent = GetOutputAreaCache(Template, SectionNameAddInfo + "|Indent");

		If TreeRowLevel > 1 Then

			// 1. ВЫВОД СОЕДИНИТЕЛЬНЫХ ЛИНИЙ И ОТСТУПОВ ПО ПОРЯДКУ

			If OutputIndent = -1
				OR OutputIndent = 2 Then

				Tab.Put(AreaIndent);

			//#Область ВыводОбязательногоОтступаПередСоединительнымиЛиниями
				Tab.Join(AreaIndent); // Вывод обязательного отступа перед выводом соединительных линий
			Else
				Tab.Put(AreaIndent); // Вывод обязательного отступа перед выводом соединительных линий
			EndIf;
			//#КонецОбласти


			//Если УровеньСтрокиДерева >= 2 Тогда

				// 1.1. СНАЧАЛА ВЫВОДЯТСЯ СОЕДИНЕНИЯ МЕЖДУ РОДИТЕЛЯМИ И РОДИТЕЛЯМИ ВЕРХНИХ УРОВНЕЙ, ЕСЛИ НЕОБХОДИМО (|, |-, Отступы)
				For Each DLLevel In DLLevels Do

					If TreeRowLevel > DLLevel.Key Then

						If DLLevel.Value > 0 Then

							AreaName = "ConnectionBetweenUpperNodes";
							//Область = Макет.ПолучитьОбласть(ИмяСекцииДопИнфо + "|" + ИмяОбласти);
							Area = GetOutputAreaCache(Template, SectionNameAddInfo + "|" + AreaName);
							GenerateLineType(Area, AreaName);
							Tab.Join(Area);

						Else

							Tab.Join(AreaIndent);
						EndIf;

						// СТАНДАРТНЫЙ ОТСТУП
						Tab.Join(AreaIndent);

					EndIf;

				EndDo;

				// 1.2. ПОТОМ ВЫВОДЯТСЯ СОЕДИНЕНИЯ МЕЖДУ ЭЛЕМЕНТАМИ ТЕКУЩЕГО УРОВНЯ
				If ( TreeRow.Parent.Rows.IndexOf(TreeRow) =  TreeRow.Parent.ChildNodes - 1 )
					OR ( TreeRow.Level() = 1 ) Then

					AreaName = "FinalNodeConnection";
					// Информация подчиненным узлам (спУровни), если они есть, о том, что родитель вышестоящем уровне N является последним,
					// после него не идут элементы, и на уровне N не надо выводить соединительную вертикальную черту
					DLLevels.Insert(TreeRow.Level(), 0);
				Else

					AreaName = "IntermediateNodeConnection";
					// Информация подчиненным узлам (спУровни), если они есть, о том, что родитель на вышестоящем уровне N является не последним,
					// после него так же идут элементы, и на уровне N надо вывести соединительную вертикальную черту
					DLLevels.Insert(TreeRow.Level(), 1);  
				EndIf;

				//Область = Макет.ПолучитьОбласть(ИмяСекцииДопИнфо + "|" + ИмяОбласти);
				Area = GetOutputAreaCache(Template, SectionNameAddInfo + "|" + AreaName);

				GenerateLineType(Area, AreaName);

				Tab.Join(Area);

			//КонецЕсли;

		EndIf;


		AreaName = "Body";

		//Область = Макет.ПолучитьОбласть(ИмяСекцииДопИнфо + "|" + ИмяОбласти);
		Area = GetOutputAreaCache(Template, SectionNameAddInfo + "|" + AreaName);

		If InfoInd = 1 Then // дальше определяется основная информация бласти подразделения
			
			//ОтсутствиеЛинииТД = Новый Линия(ТипЛинииЯчейкиТабличногоДокумента.НетЛинии);

			ConnectionArea = Area.Area("ConnectionArea_rlsp");
			If TreeRowLevel > 1 Then
			// для строк дерева уровня более первого(ниже горизонтальных ячеек) линия соединения с главное горизонтальной линией не выводится.
				ConnectionArea.RightBorder = SDLineAbsence;
			Else
				GenerateLineType(Area, AreaName);
			EndIf;

			// установка параметров размещения текста
			NamedArea = Area.Area("Item");
			NamedArea.TextPlacement = ?( WrapDepartmentDescription,
				SpreadsheetDocumentTextPlacementType.Wrap,
				SpreadsheetDocumentTextPlacementType.Cut );
				

			NamedArea.Font		= AddReportParameters.DescriptionAreaTextFont;
			NamedArea.TextColor	= AddReportParameters.DescriptionAreaTextColor;

			///////////////////////////////////////
			Area.Parameters.Description = TreeRow[DepPresentation];
			Area.Areas.Item.Name = "Item_" + TreeRow.Code;

			//Параметр расшифровки
			Area.Parameters.Department = TreeRow.Department;

		ElsIf InfoInd = 2 Then // определяется опциональная информация области менеджера

			NewAreaName = "AreaAddInfoManager_" + TreeRow.Code;
			Area.Parameters.Manager = ?(ResponsibleCompetitor, "(","") + TreeRow.Manager + ?(ResponsibleCompetitor, ")","");
			Area.Areas.AreaAddInfoManager.Name = NewAreaName; // В любом случае именованной ячейке надо задать уникальное имя д. последующего вывода в неё ФР
			Area.Areas[NewAreaName].Font		= AddReportParameters.ManagerAreaTextFont;
			Area.Areas[NewAreaName].TextColor	= AddReportParameters.ManagerAreaColorText;
			
		ElsIf InfoInd = 4
			AND OutputFinancialResult Then

			//Вывод финансового результата
			Area.Areas.FR_N.Font		= AddReportParameters.FRAreaTextFont;
			Area.Areas.FR_N.TextColor	= AddReportParameters.FRAreaTextColor;

			NewAreaName ="FR_" + TreeRow.Code;
			Area.Areas.FR_N.Name = NewAreaName; // В любом случае именованной ячейке надо задать уникальное имя д. последующего вывода в неё ФР

			FinResult = TreeRow.FinResCurrentOrder;
			If FinResult <> Undefined Then
				Area.Parameters.FinResCurrent = Format(FinResult,FormatStringOfReportsAmounts(MonetaryIndicator));
				ParametersStructure = New Structure;
				ParametersStructure.Insert("Department",		TreeRow.Department);
				ParametersStructure.Insert("DepartmentType",	TreeRow.DepartmentType);
				ParametersStructure.Insert("Amount",				FinResult);

				Area.Parameters.FinResultDetails = ParametersStructure;
			EndIf;

		ElsIf InfoInd = IndexcAreaExpand
			//И СтрокаДерева.ДочернихУзлов > 0 
			Then

			///////////////////////////////////////
			// ВЫВОД КАРТИНКИ УЗЛА
			//Если СтрокаДерева.ДочернихУзлов > 0 Тогда
			GenerateGroupPicture(Area, AreaPictures, TreeRow, GenerateForWebClient);

		EndIf;


		/////////////////////////////////////
		// ОПРЕДЕЛЕНИЕ ЦВЕТА ФОНА, ЕСЛИ НАДО
		If NOT InfoInd = IndexcAreaExpand Then

			SetAreaColor(Area, TreeRow);
		EndIf;
		/////////////////////////////////////

		If TreeRowLevel > 1 Then

			Tab.Join(Area);
		Else

			If NOT OutputIndent = 0 Then

				If OutputIndent = -1
					OR OutputIndent = 2 Then

					// Вывод отсупа слева
					Tab.Put(AreaIndent);
				EndIf;

				If OutputIndent = -1
					OR OutputIndent = 2 Then

					//Вывод самого элемента узла
					Tab.Join(Area);
				Else

					Tab.Put(Area);
				EndIf;

				If OutputIndent = 1
					OR OutputIndent = 2 Then

					// Вывод отсупа справа
					Tab.Join(AreaIndent);
				EndIf;

			Else

				// обычный вывод области без отступов
				Tab.Put(Area);
			EndIf;
	
		EndIf;

		If InfoInd = 1 Then

			Area.Areas["Item_" + TreeRow.Code].Name = "Item"; // Возврат кэшированной области старого имени после вывода

		ElsIf InfoInd = 2 Then

			Area.Areas[NewAreaName].Name = "AreaAddInfoManager"; // Возврат кэшированной области старого имени после вывода
			
			
		ElsIf InfoInd = 4 AND OutputFinancialResult Then
			
			Area.Areas[NewAreaName].Name = "FR_N"; // Возврат кэшированной области старого имени после вывода

		ElsIf InfoInd = IndexcAreaExpand AND NOT GenerateForWebClient Then

			If TreeRow.ChildNodes = 0 Then
				Area.Drawings.DeletePicture.Name = "Picture";
				DeletedPicture = Tab.Drawings.DeletePicture;
				Tab.Drawings.Delete(DeletedPicture);
			EndIf;

		EndIf;

	EndDo;

	IndexesInLevelForDeletionArray = New Array;

	// если для данного узла нет признака вывода дочерних элементов то производится выход из процедуры
	If NOT TreeRow.Expanded Then

		Return;
	EndIf;

	For Each String In TreeRow.Rows Do

		CurrentLevel = String.Level();
		// Если элемент не последний в структуре, то даём знак уровням ниже, что на данном уровне для них есть продолжение и линия должна быть выведена
		If TreeRow.Rows.IndexOf(String) <> TreeRow.ChildNodes - 1 Then

			ChildLevels_.Add(CurrentLevel);
		EndIf;

		OutputTreeRow(String, Template, Tab, DLLevels, ChildLevels_, OutputIndent, GenerateForWebClient);

		// после того как все уровни ниже обработаны, надо удалить информацию о данном уровне и уровнях ниже,
		// чтобы они не фигурировали в иерархии следющего элемента
		IndexesInLevelForDeletionArray.Clear();
		For Each ChildLevel_ In ChildLevels_ Do

			If ChildLevel_ >= CurrentLevel Then
				IndexesInLevelForDeletionArray.Add(ChildLevels_.Find(ChildLevel_));
			EndIf;

		EndDo;

		For Each Index In IndexesInLevelForDeletionArray Do
			ChildLevels_.Delete(Index);
		EndDo;

	EndDo;

EndProcedure // ВывестиСтрокуДерева()

Function MaxTreeNestingLevel(TreeRow, MaxLevel = 0)

	If NOT TreeRow.Expanded 
		OR TreeRow.ChildNodes = 0 Then

		Return MaxLevel;
	EndIf;

	HasChild = False;
	For Each TreeSubrow In TreeRow.Rows Do

		MaxLevel =  Max(TreeSubrow.Level() - 1, MaxLevel);

		//если это конечный элемент иерархии, то его не стоит рассматривать для расчета актуальных уровней вложенности
		If TreeSubrow.ChildNodes > 0 Then
			HasChild = True;
			//МаксУровень =  Макс(ПодстрокаДерева.Уровень() - 1, МаксУровень);
			MaxLevel =  Max(MaxLevel, MaxTreeNestingLevel(TreeSubrow, MaxLevel));
		EndIf;
	EndDo;

	If NOT HasChild
		AND MaxLevel = 0 Then

		// если уровень развернут, но дочерние не имеют своих дочерних, то просто увеличить уровень
		MaxLevel = MaxLevel + 1;
	EndIf;

	Return MaxLevel;

EndFunction //МаксУровеньВложенностиСтрокиДерева()

Function GetFinancialResultBudgeting(DepartmentTree, Departments, InTable = False, DepartmentsVTFromTree)
	
	SecHRowManager = New TempTablesManager;
	
	//1409
	//создадим вт Подразделение-Родитель для корректного получения родителя по версии
	DepartmentsVTFromTreeParents = DepartmentsVTFromTree.Copy(, "Department, Parent");	
	
	Query = New Query();
	Query.TempTablesManager = SecHRowManager;
	Query.Text = "SELECT
	               |	VTSubparent.Department AS Department,
	               |	VTSubparent.Parent AS Parent
	               |INTO TTDepartmentTableParent
	               |	FROM &VTSubparent AS VTSubparent";
	Query.SetParameter("VTSubparent", DepartmentsVTFromTreeParents);			   
	Query.Execute();
	
	DepartmentsMap = New Map;
	
	
	If BudgetingFRFlag Then

		Query = New Query();
		Query.TempTablesManager = SecHRowManager;
		Query.Text = "SELECT ALLOWED
		               |	IncomesExpensesPlanTurnovers.Department AS Department,
		               |	IncomesExpensesPlanTurnovers.AmountTurnover AS Amount,
		               |	IncomesExpensesPlanTurnovers.Period AS Period
		               |INTO TotalTable
		               |FROM
		               |	AccumulationRegister.fmIncomesAndExpenses.Turnovers(
		               |			&BeginOfPeriod,
		               |			&EndOfPeriod,
		               |			Month,
		               |			Scenario = &Scenario
		               |				AND (OperationType = Value(Enum.fmBudgetFlowOperationTypes.Incomes)
		               |					OR OperationType = Value(Enum.fmBudgetFlowOperationTypes.InnerIncomes))
		               |				AND Department IN (&Departments)) AS IncomesExpensesPlanTurnovers
		               |
		               |UNION ALL
		               |
		               |SELECT
		               |	IncomesExpensesPlanTurnovers.Department,
		               |	-IncomesExpensesPlanTurnovers.AmountTurnover,
		               |	IncomesExpensesPlanTurnovers.Period
		               |FROM
		               |	AccumulationRegister.fmIncomesAndExpenses.Turnovers(
		               |			&BeginOfPeriod,
		               |			&EndOfPeriod,
		               |			Month,
		               |			Scenario = &Scenario
		               |				AND (OperationType = Value(Enum.fmBudgetFlowOperationTypes.Expenses)
		               |					OR OperationType = Value(Enum.fmBudgetFlowOperationTypes.InnerExpenses))
		               |				AND Department IN (&Departments)) AS IncomesExpensesPlanTurnovers
		               |;
		               |
		               |////////////////////////////////////////////////////////////////////////////////
		               |SELECT
		               |	TotalTable.Department AS Department,
		               |	SUM(TotalTable.Amount) AS Amount
		               |FROM
		               |	TotalTable AS TotalTable
		               |
		               |GROUP BY
		               |	TotalTable.Department
		               |;
		               |
		               |////////////////////////////////////////////////////////////////////////////////
		               |DROP TotalTable";

		Query.SetParameter("BeginOfPeriod",        BeginningOfBudgetingPeriod);
		Query.SetParameter("EndOfPeriod",         EndOfDay(EndOfBudgetingPeriod));
		Query.SetParameter("Scenario",             Scenario);
		Query.SetParameter("Departments",        Departments);

		QueryResult = Query.Execute();
		
		If InTable Then
			
			Return QueryResult.Unload();
		Else
			
			Selection = QueryResult.SELECT();
			While Selection.Next() Do
				DepartmentsMap.Insert(Selection.Department, Selection.Amount);
			EndDo;
		EndIf;

	EndIf;
	
	SecHRowManager.Close();

	//Возврат СоответствиеПодразделений;
	
	FilterStructure	 	= New Structure("Department");

	For Each ItemDepartment In Departments Do
		FinRes = 0;

		FilterStructure.Department 	= ItemDepartment;

		FR = DepartmentsMap[ItemDepartment];
		FinRes = ?( NOT FR = Undefined, FR, 0 );

		StringArray = DepartmentTree.Rows.FindRows(FilterStructure, True);
		If StringArray.Count() > 0 Then
			StringArray[0]["FinResCurrentOrder"] = FinRes;
		EndIf;
			
	EndDo;

	Return True;

EndFunction // ПолучитьФинансовыйРезультатБюджетирование()

Procedure DepartmentTreeIterationForGettingFRWithChildren(DepartmentTree, DepartmentsMap, ParentDepartment, InTable = False, FRTree = Undefined)
	
	For Each TreeRow In DepartmentTree Do
		If NOT TreeRow.Department = ParentDepartment Then
			
			If InTable Then
				
				FillPropertyValues(FRTree.Add(), TreeRow);
			Else
				
				DepartmentsMap.Insert(TreeRow.Department, TreeRow.Amount);
			EndIf;
		EndIf;
		DepartmentTreeIterationForGettingFRWithChildren(TreeRow.Rows, DepartmentsMap, TreeRow.Department);
	EndDo;
	
EndProcedure //ОбходДереваПодразделенийДляПолученияФРСДочками()

Procedure FillCheckProcessing(Cancel, CheckingAttributes)

	// проверка заполенния в случае построения отчета для бюджетирования
	If BudgetingFRFlag Then
		CheckingAttributes.Add("Scenario");
	EndIf;

EndProcedure

Procedure GenerateLineType(SDArea, AreaName)

//	ДопПараметры = ПолучитьИзВременногоХранилища(ДополнительныеПараметрыОтчета);
	If TypeOf(AddReportParameters) = Type("Structure")
		AND AddReportParameters.Property("ConnectionLine") Then

		ConnectionLine = AddReportParameters.ConnectionLine;
	Else

		ConnectionLine = New Line(SpreadsheetDocumentCellLineType.ThinDashed, 1);
	EndIf;


	If AreaName = "Body" Then

		NamedArea = SDArea.Area("ConnectionArea_rlsp");
		NamedArea.RightBorder = ConnectionLine;

	Else

		For Each Area In SDArea.Areas Do
			If TypeOf(Area) = Type("SpreadsheetDocumentRange") Then
				If Area.TopBorder.LineType <> SpreadsheetDocumentCellLineType.None Then
					Area.TopBorder = ConnectionLine;
				EndIf;
				If Area.RightBorder.LineType <> SpreadsheetDocumentCellLineType.None Then
					Area.RightBorder = ConnectionLine;
				EndIf;
				If Area.BottomBorder.LineType <> SpreadsheetDocumentCellLineType.None Then
					Area.BottomBorder = ConnectionLine;
				EndIf;
				If Area.LeftBorder.LineType <> SpreadsheetDocumentCellLineType.None Then
					Area.LeftBorder = ConnectionLine;
				EndIf;
			EndIf;
		EndDo;

	EndIf;

EndProcedure // СформироватьТипЛинии()

Procedure SetAreaColor(Area, TreeRow, FillIndependently = False)

	If TypeOf(Area) = Type("SpreadsheetDocumentRange") Then
		
		If Find(Area.Name, "_rlsp") = 0 Then
			
			// УСТАНОВКА ЦВЕТА ФОНА
			If TreeRow.DeletionMark Then
				
				Area.BackColor = WebColors.Gainsboro;
				
			ElsIf (ColorFill = 0 OR FillIndependently) AND
				NOT TreeRow.Color = Undefined Then
				
				Area.BackColor = TreeRow.Color;
			Else
				
				Area.BackColor = WebColors.White;
			EndIf;
			
			// УСТАНОВКА ЦВЕТА ТЕКСТА
			If Area.BackColor = WebColors.Black  Then
				
				Area.TextColor = WhiteColor;
			EndIf;
			
		EndIf;
		
	ElsIf TypeOf(Area) = Type("SpreadsheetDocument") Then
		
		For Each SDArea In Area.Areas Do

			If Find(SDArea.Name, "_rlsp") = 0 Then
				
				// УСТАНОВКА ЦВЕТА ФОНА
				If TreeRow.DeletionMark Then
					
					SDArea.BackColor = WebColors.Gainsboro;
					
				ElsIf ( ColorFill = 0  OR FillIndependently ) AND
					NOT TreeRow.Color = Undefined Then
					
					SDArea.BackColor = TreeRow.Color;
				Else
					
					SDArea.BackColor = WebColors.White;
				EndIf;
				
				// УСТАНОВКА ЦВЕТА ТЕКСТА
				If SDArea.BackColor = WebColors.Black Then
					
					SDArea.TextColor = WhiteColor;
				EndIf;
				
			EndIf;
			
		EndDo;
		
	EndIf;

EndProcedure

Procedure AddIndentsToBottom(AddedIndents, SpreadsheetDocument, Template)

	For IndentInd = 1 To AddedIndents Do 

		For InfoInd = 1 To IndexcAreaExpand Do // 1 основная информация, 2 - Менеджер(опционально), 3-цвет текстом(опционально)

			If InfoInd = 1 Then

				SectionNameAddInfo = "Items";

			ElsIf InfoInd = 2
				AND InfoManager Then

				SectionNameAddInfo = "AddInfoManager";
				
			ElsIf InfoInd = 4
				AND OutputFinancialResult Then
				
				SectionNameAddInfo = "AreaFinRes";
				
			ElsIf InfoInd = IndexcAreaExpand Then
				
				SectionNameAddInfo = "Expansion"; 
				
			Else

				Continue;
			EndIf;

			//ОбластьОтступ = Макет.ПолучитьОбласть(ИмяСекцииДопИнфо + "|Отступ");
			AreaIndent = GetOutputAreaCache(Template, SectionNameAddInfo + "|Indent");

			SpreadsheetDocument.Put(AreaIndent);

		EndDo;

	EndDo;

EndProcedure

Procedure ExpandedDepartments(TreeRow, Expanded = 0)

	If NOT TreeRow.Expanded Then
		Return;
	EndIf;

	For Each TreeSubrow In TreeRow.Rows Do

		Expanded = Expanded + 1;
		
		If TreeSubrow.Expanded Then

			ExpandedDepartments(TreeSubrow, Expanded);
		EndIf;
	EndDo;

EndProcedure // РаскрытоПодразделений()

Procedure GenerateGroupPicture(Area, AreaPictures, TreeRow, GenerateForWebClient = False);

	If GenerateForWebClient Then

		Area.Drawings.Clear();
		If TreeRow.ChildNodes > 0 Then

			Area.Parameters.NodePresentation = ?( TreeRow.Expanded, "-", "+" );
			DetailsStructure = New Structure("Openned, TreeRow, BranchDepartment", TreeRow.Expanded, TreeRow.Department, TreeRow.BranchDepartment);
			Area.Parameters.Node = DetailsStructure;
		Else
			
			Area.Parameters.NodePresentation = ""; // иначе не выводить что л.
		EndIf;

	Else

		If TreeRow.ChildNodes > 0 Then

			For Each Picture In Area.Drawings Do
				
				Picture.Picture = AreaPictures.Drawings["PictureGroup" + ?( TreeRow.Expanded, "Openned", "Closed")].Picture;
				//Рисунок.Имя = "Рисунок" + СтрокаДерева.Код;
				DetailsStructure = New Structure("Openned, TreeRow, BranchDepartment", TreeRow.Expanded, TreeRow.Department, TreeRow.BranchDepartment);
				Picture.Details = DetailsStructure;
				//Новый Структура("Открыт, СтрокаДерева", СтрокаДерева.Развернут, СтрокаДерева.Подразделение);
				//Рисунок.Расшифровка = СтрокаДерева.Подразделение; //Область.Параметры.Расшифровка;

				Break;

			EndDo;

		Else

			Area.Drawings.Picture.Name = "DeletePicture";
		EndIf;

	EndIf;

EndProcedure

Procedure OutputDepartments(VAL Tree, Departments)

	For Each String In Tree.Rows Do

		Departments.Add(String.Department);
		If String.Expanded Then
			OutputDepartments(String, Departments)
		EndIf;

	EndDo;

EndProcedure // ВыведенныеПодразделения()

// <Описание функции>
//
// Параметры
//  <Параметр1>  - <Тип.Вид> - <описание параметра>
//                 <продолжение описания параметра>
//  <Параметр2>  - <Тип.Вид> - <описание параметра>
//                 <продолжение описания параметра>
//
// Возвращаемое значение:
//   <Тип.Вид>   - <описание возвращаемого значения>
//
Function GetOutputAreaCache(Template, AreaName, StorageSeparator = "_")

	If IsBlankString(AreaName) Then
		Return Undefined;
	EndIf;

	_AreaName = StrReplace(AreaName, "|", StorageSeparator);
	If NOT OutputAreasCache.Property(_AreaName) Then
		Area = Template.GetArea(AreaName);
		OutputAreasCache.Insert(_AreaName, Area);
	Else
		Area = OutputAreasCache[_AreaName];
	EndIf;

	Return Area;

EndFunction // ПолучитьОбластьВыводаКэш()

Function GetLastApprovedPeriod() Export
	
	SetPrivilegedMode(True);
	
	Query = New Query;
	Query.Text = 
		"SELECT TOP 2
		|	MAX(CASE
		|			WHEN InputIncomesAndExpensesInfo.Scenario.PlanningPeriod = Value(Enum.fmPlanningPeriod.Year)
		|				Then EndOfPeriod(InputIncomesAndExpensesInfo.BeginOfPeriod, Year)
		|			WHEN InputIncomesAndExpensesInfo.Scenario.PlanningPeriod = Value(Enum.fmPlanningPeriod.Quarter)
		|				Then EndOfPeriod(InputIncomesAndExpensesInfo.BeginOfPeriod, Quarter)
		|			Else EndOfPeriod(InputIncomesAndExpensesInfo.BeginOfPeriod, Quarter)
		|		END) AS ApprovedPeriod,
		|	BeginOfPeriod(InputIncomesAndExpensesInfo.BeginOfPeriod, Year) AS Year
		|FROM
		|	Document.fmBudget AS InputIncomesAndExpensesInfo
		|WHERE
		|	InputIncomesAndExpensesInfo.Posted
		|
		|GROUP BY
		|	BeginOfPeriod(InputIncomesAndExpensesInfo.BeginOfPeriod, Year)
		|
		|ORDER BY
		|	Year DESC";
	
	Result = Query.Execute();
	
	SetPrivilegedMode(False);
	
	SelectionDetails = Result.SELECT();
	
	LastAPCount = SelectionDetails.Count();
	If LastAPCount > 0 Then
	
		ApprovedPeriod = Undefined;
		While SelectionDetails.Next() Do
	
			ApprovedPeriod = SelectionDetails.ApprovedPeriod;
		EndDo;
	
		Return ApprovedPeriod
	
	Else
		
		Return '00010101';
	EndIf;
	
EndFunction // ПолучитьПоследнийУтвержденныйПериод()

Function GetInfoAboutTreeRow(Department, AddressExecutionParameters) Export
	
	ReportExecutionParameters = GetFromTempStorage(AddressExecutionParameters);
	
	If ReportExecutionParameters.Property("DepartmentTree") Then
		
		TreeRows = ReportExecutionParameters.DepartmentTree.Rows.FindRows( New Structure("Department", Department), True );
		
		If TypeOf(TreeRows) = Type("Array")
			AND TreeRows.Count() > 0 Then
			
			Return New Structure("BranchDepartment, DeletionMark", 
				TreeRows[0].BranchDepartment, TreeRows[0].DeletionMark);
		Else
			
			Return Undefined;
		EndIf;
		
	Else
		
		Return Undefined;
	EndIf;
	
EndFunction // ПолучитьИнформациюОСтрокеДерева()

Procedure OutputRootDepartmentCreationArea(SpreadsheetDocument, Template)
	
	// ВЫВОД ОТСТУПА
	AreaIndent 	= Template.GetArea("Items|Indent");
	
	// Первым стандартно выводится отступ
	SpreadsheetDocument.Put(AreaIndent);
	
	// ВЫВОД "КОРОБКИ"
	AreaRoot = Template.GetArea("Items|Body");
	// скрытие хвоста сверху
	ConnectionArea	= AreaRoot.Area("ConnectionArea_rlsp");
	ConnectionArea.RightBorder = SDLineAbsence;
	AreaRoot.Parameters.Description = NStr("en='Create root';ru='Создать корневое'");
	
	SpreadsheetDocument.Join(AreaRoot);
	// отрисовка нижней границы "коробки"
	BoxArea = SpreadsheetDocument.Areas[AreaRoot.Areas[AreaRoot.Areas.Count()-1].Name];
	BoxArea.BottomBorder = New Line(SpreadsheetDocumentCellLineType.Solid, 1);
	BoxArea.Comment.Text = NStr("ru = 'Создать новое корневое Department'; en = 'Create a new root unit'");
	BoxArea.Details = "CreateNewRoot";
	
EndProcedure // ВывестиОбластьСозданияКорневогоПодразделения()

Function GetDepartmentTree(DepartmentTable, TreeColumns, InitialLinkValue = "")
	
	Try
		
		Schema = GetTemplate("DepartmentTreeIH");
		Schema.DataSetLinks[0].StartExpression = InitialLinkValue;
		
	Except
		
		Schema = New DataCompositionSchema;
		
		DataSource = Schema.DataSources.Add();
		DataSource.DataSourceType = "Local";
		DataSource.Name = "DataSource1";
		
		DataSet					= Schema.DataSets.Add(Type("DataCompositionSchemaDataSetObject"));
		DataSet.Name				= "Departments";
		DataSet.DataSource	= "DataSource1";
		DataSet.ObjectName		= "DepartmentTable";
		
		For Each Column In TreeColumns Do
			SetField = DataSet.Fields.Add(Type("DataCompositionSchemaDataSetField"));
			SetField.Field			= Column.Name;
			SetField.DataPath	= Column.Name;
			SetField.ValueType	= Column.ValueType;
		EndDo;
		
		DCStructure = Schema.DefaultSettings.Structure;
		DCStructure.Clear();
		
		DCGroup = DCStructure.Add(Type("DataCompositionGroup"));
		DCGroup.GroupFields.Items.Add(Type("DataCompositionGroupField"));
		
		For Each Column In TreeColumns Do
			
			DCSelectedField = DCGroup.Selection.Items.Add(Type("DataCompositionSelectedField"));
			DCSelectedField.Field = New DataCompositionField(Column.Name);
		EndDo;
		
		////////////////////////////////////////////////////////////////
		// СВЯЗИ НАБОРОВ
		DSLink = Schema.DataSetLinks.Add();
		DSLink.SourceDataSet = "Departments";
		DSLink.DestinationDataSet = "Departments";
		
		DSLink.SourceExpression = "Code";
		DSLink.DestinationExpression = "ParentCode";
		
		DSLink.StartExpression = InitialLinkValue;
		
		DSLink.Required = True;
		
	EndTry;
	
	
	/////////////////////////////////////////////////////////////////////////////////////////////////////////////
	_Settings = Schema.DefaultSettings;
	
	_SettingsComposer = New DataCompositionSettingsComposer;
	_SettingsComposer.Initialize(New DataCompositionAvailableSettingsSource(Schema));
	_SettingsComposer.LoadSettings(_Settings);
	
	Settings = _SettingsComposer.Settings;
	/////////////////////////////////////////////////////////////////////////////////////////////////////////////
	
	TemplateComposer = New DataCompositionTemplateComposer;
	CompositionTemplate = TemplateComposer.Execute(Schema, Settings,,, Type("DataCompositionValueCollectionTemplateGenerator"));
	
	ExternalDataSets = New Structure("DepartmentTable", DepartmentTable);
	
	//инициализация процессора СКД
	DataCompositionProcessor = New DataCompositionProcessor;
	DataCompositionProcessor.Initialize(CompositionTemplate, ExternalDataSets);
	
	Result = New ValueTree;
	
	//инициализация процессора вывода
	OutputProcessor = New DataCompositionResultValueCollectionOutputProcessor;
	OutputProcessor.SetObject(Result);
	OutputProcessor.Output(DataCompositionProcessor);
	
	Return Result;
	
EndFunction // ПолучитьДеревоПодразделений()

Function FormatStringOfReportsAmounts(ViewFormat = Undefined) Export

	If NOT ValueIsFilled(ViewFormat) Then
		FormatFrom = "";
	//без округления
	ElsIf  ViewFormat=3 Then
		FormatFrom = "ND=15; NFD=2";	
	Else
		Rounds = New Map();
		//тысяча 1
		Rounds.Insert(1, "3");
		//единица 2
		Rounds.Insert(2, "0");
		FormatFrom =  "NFD=0; NS="+(Rounds[ViewFormat]);
	EndIf;
	FormatFrom = FormatFrom +"; NN="+NegativeNumbersPresentation;
	Return FormatFrom;

EndFunction //ФорматированиеСуммыОтчетов()

IndexcAreaExpand = 6;

