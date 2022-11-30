
#If Server OR ThickClientOrdinaryApplication OR ExternalConnection Then

Function PrintDepartmentList(DepartmentTreeMain, ExpandedNodesTree, WithHierarchy) Export
	DataTree = FormDataToValue(DepartmentTreeMain, Type("ValueTree"));
	Table = New ValueTable;
	Table.Columns.Add("Department",    New TypeDescription("CatalogRef.fmDepartments"));
	Table.Columns.Add("DepartmentType", New TypeDescription("CatalogRef.fmDepartmentTypes"));
	Table.Columns.Add("Code",              New TypeDescription("String"));
	Table.Columns.Add("ParentCode",      New TypeDescription("String"));
	Table.Columns.Add("Parent",         New TypeDescription("CatalogRef.fmDepartments"));
	DataTable = UnloadValueTreeToValueTable(DataTree, Table);
	ExpendedNodesArray = ExpandedNodesTree.UnloadColumn("Department");
	If WithHierarchy Then
		Query = New Query();
		Query.Text = "SELECT
		|	DataTable.Department,
		|	DataTable.DepartmentType,
		|	DataTable.Code,
		|	DataTable.ParentCode,
		|	DataTable.Parent
		|INTO DataTableTT
		|FROM
		|	&DataTable AS DataTable
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	DataTableTT.Department,
		|	DataTableTT.DepartmentType,
		|	DataTableTT.Code,
		|	DataTableTT.ParentCode,
		|	DataTableTT.Parent
		|FROM
		|	DataTableTT AS DataTableTT
		|WHERE
		|	DataTableTT.Department IN HIERARCHY(&ExpendedNodesArray)
		|";
		Query.SetParameter("DataTable",          DataTable);
		Query.SetParameter("ExpendedNodesArray", ExpendedNodesArray);
	Else
		Query = New Query();
		Query.Text = "SELECT
		|	DataTable.Department,
		|	DataTable.DepartmentType,
		|	DataTable.Code,
		|	DataTable.ParentCode,
		|	DataTable.Parent
		|INTO DataTableTT
		|FROM
		|	&DataTable AS DataTable
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	DataTableTT.Department,
		|	DataTableTT.DepartmentType,
		|	DataTableTT.Code,
		|	DataTableTT.ParentCode,
		|	DataTableTT.Parent
		|FROM
		|	DataTableTT AS DataTableTT
		|WHERE
		|	(DataTableTT.Department IN (&ExpendedNodesArray)
		|			OR DataTableTT.Parent IN (&ExpendedNodesArray))";
		Query.SetParameter("DataTable",          DataTable);
		Query.SetParameter("ExpendedNodesArray", ExpendedNodesArray);
	EndIf;
	
	DataTable = Query.Execute().Unload();
	
	Result = New SpreadsheetDocument;
	
	CompositionSchema = GetTemplate("Tree");
	
	ConditionalAppearance = CompositionSchema.DefaultSettings.ConditionalAppearance;
	ColorTreeItems(ConditionalAppearance, , "DepartmentType", "Department");
	
	TemplateComposer = New DataCompositionTemplateComposer;
	CompositionTemplate = TemplateComposer.Execute(CompositionSchema, CompositionSchema.DefaultSettings);
	
	ExternalDataSet = New Structure("DataTable", DataTable);
	
	CompositionProcessor = New DataCompositionProcessor;
	CompositionProcessor.Initialize(CompositionTemplate, ExternalDataSet);
	
	OutputProcessor = New DataCompositionResultSpreadsheetDocumentOutputProcessor;
	OutputProcessor.SetDocument(Result);
	OutputProcessor.Output(CompositionProcessor);
	
	Return Result;
EndFunction 

Procedure ColorTreeItems(ConditionalAppearance, Tree, DepartmentType, Department) Export
	
	DepartmentsColoring = Catalogs.fmDepartmentTypes.GetSettings();
	For Each Item In DepartmentsColoring Do
		fmCommonUseClientServer.AddConditionalAppearanceItem(Tree, ConditionalAppearance, DepartmentType,, Item.DepartmentType, Item.Color, "BackColor");
	EndDo;
	fmCommonUseClientServer.AddConditionalAppearanceItem(Tree, ConditionalAppearance, DepartmentType,, Catalogs.fmDepartmentTypes.EmptyRef(), WebColors.LightGray, "BackColor");
	
	//В условное оформление включим индивидуальный цвет оформления, установленного для подразделения
	//Получим все подразделения, для которых установлен индивидуальный цвет оформления
	Query = New Query();
	Query.Text = "SELECT
	               |	Departments.Ref AS Department,
	               |	Departments.Color
	               |FROM
	               |	Catalog.fmDepartments AS Departments
	               |WHERE
	               |	Departments.SetColor";
	
	Unloading = Query.Execute().Unload();
	
	For Each Item In Unloading Do
		FieldColor = New Color(255, 255, 255);
		//Прочтаем индивидуальный цвет
		If NOT Item.Color = "" Then
			XMLReader 		= New XMLReader;
			ObjectTypeXDTO	= XDTOFactory.Type("http://v8.1c.ru/8.1/data/ui","Color");
			XMLReader.SetString(Item.Color);
			ObjectXDTO		=	XDTOFactory.ReadXML(XMLReader, ObjectTypeXDTO);
			Serializer	=	New XDTOSerializer(XDTOFactory);
			FieldColor		=	Serializer.ReadXDTO(ObjectXDTO);
		EndIf;
		//Добавим условное оформление по индивидуальному цвету
		If NOT FieldColor = New Color(255, 255, 255) Then
			fmCommonUseClientServer.AddConditionalAppearanceItem(Tree, ConditionalAppearance, Department,, Item.Department, FieldColor, "BackColor");
		EndIf;
	EndDo;
	
EndProcedure

Function GetState(Department, VAL Period = Undefined) Export
	ResultStructure = New Structure("Period, Recorder, DepartmentType, BalanceUnit, Responsible",
		'00010101', Undefined, Catalogs.fmDepartmentTypes.EmptyRef(), Catalogs.fmBalanceUnits.EmptyRef(), Catalogs.Users.EmptyRef());
	If Department = Catalogs.fmDepartments.EmptyRef() Then
		Return ResultStructure; 
	EndIf; 
	lPeriod = ?(Period = Undefined, CurrentSessionDate(), Period);
	SliceResult = InformationRegisters.fmDepartmentsState.SliceLast(lPeriod, New Structure("Department", Department));
	If SliceResult.Count() > 0 Then
		FillPropertyValues(ResultStructure, SliceResult[0]);
	EndIf;
	Return ResultStructure;
EndFunction

Function GetDepartmentType(Department, DATE) Export
	ParentDepartmentType = Department.DepartmentType;
	DepartmentType = Catalogs.fmDepartmentTypes.EmptyRef();
	Query = New Query();
	Query.Text = "SELECT
	|	DepartmentsStateSliceLast.DepartmentType
	|FROM
	|	InformationRegister.fmDepartmentsState.SliceLast(&DATE, Department = &Department) AS DepartmentsStateSliceLast";
	Query.SetParameter("DATE", DATE);
	If TypeOf(Department) = Type("CatalogRef.fmDepartments") Then
		Query.SetParameter("Department", Department);
	Else
		Query.SetParameter("Department", Department[0]);
	EndIf;
	Selection = Query.Execute().SELECT();
	If Selection.Next() Then
		DepartmentType = Selection.DepartmentType;
	EndIf;
	Return DepartmentType;
EndFunction

Function UnloadValueTreeToValueTable(Tree, Table = Undefined) Export

	If Table = Undefined Then
		Table = New ValueTable;
		For Each Column In Tree.Columns Do
			Table.Columns.Add(Column.Name, Column.ValueType);
		EndDo;
	EndIf;
	
	For Each TreeRow In Tree.Rows Do
		NewLine = Table.Add();
		NewLine.Department 		= TreeRow.Department;
		NewLine.DepartmentType 	= TreeRow.DepartmentType;
		NewLine.Code 			= TreeRow.Code;
		If TreeRow.Parent = Undefined Then
			NewLine.ParentCode = "";
			NewLine.Parent = Catalogs.fmDepartments.EmptyRef();
		Else
			NewLine.Parent 	= TreeRow.Parent.Department;
			NewLine.ParentCode = TreeRow.Parent.Code;
		EndIf;
		UnloadValueTreeToValueTable(TreeRow, Table);
	EndDo;
	Return Table;

EndFunction
#EndIf
