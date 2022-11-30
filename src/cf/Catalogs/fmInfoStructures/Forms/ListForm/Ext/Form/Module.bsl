
#Region FormEventsHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	// Добавим условное оформление для дерева подразделений
	If Constants.fmDepartmentStructuresBinding.Get() Then
		Items.DepartmentTree.Visible = True;
		Items.GroupCommandBar.Visible = True;
	EndIf;
	DepartmentsColoring = Catalogs.fmDepartmentTypes.GetSettings();
	For Each Item In DepartmentsColoring Do
		AddConditionalAppearanceItemColor("DepartmentTree", ConditionalAppearance, "DepartmentTree.DepartmentType",, Item.DepartmentType, Item.Color, "TextColor");
	EndDo;
	AddConditionalAppearanceItemColor("DepartmentTree", ConditionalAppearance, "DepartmentTree.DepartmentType",, Catalogs.fmDepartmentTypes.EmptyRef(), WebColors.LightGray, "TextColor");
	// Сгруппируем виды отчетов по типу
	GroupField = List.Group.Items.Add(Type("DataCompositionGroupField"));
	GroupField.Use = True;
	GroupField.Field = New DataCompositionField("StructureType");
	CurUser = Users.CurrentUser();
	UpdateBindingTreeAtServer();
	Items.DepartmentTreeSave.Enabled 				= AreChanges;
	ActualVersionForPeriod = fmBudgeting.ReturnDepartmentStructureActualVersion();
EndProcedure

&AtClient
Procedure OnClose(Shutdown)
	If Shutdown Then
		Return;
	EndIf;
	AskQuestionSaveChanges();
EndProcedure

#EndRegion

#Region FormItemsEventsHandlers

&AtClient
Procedure DepartmentTreeApplyOnChange(Item)
	CurData = Items.List.CurrentRow;
	If NOT CurData = Undefined
		AND TypeOf(CurData) = Type("CatalogRef.fmInfoStructures") Then
		TreeCurData = Items.DepartmentTree.CurrentData;
		If NOT TreeCurData = Undefined Then
			TreeCurData.Use = TreeCurData.Use % 2;
			If TreeCurData.Use Then
				AddValueInInfoStructureCommonTable(CurData, TreeCurData.Department, TreeCurData.Parent);
			Else
				DeleteValueFromInfoStructureCommonTable(CurData, TreeCurData.Department);
				TreeCurData.ApplyByDefault = False;
				Items.DepartmentTreeApplyByDefault.Check = False;
			EndIf;
			AskQuestion = False;
			If TreeCurData.Use Then
				ChildrenFlagIsNotSet = False;
				ChildrenFlagIsNotSet(TreeCurData.GetItems(), ChildrenFlagIsNotSet);
				If ChildrenFlagIsNotSet Then
					AskQuestion = True;
				EndIf;
			Else
				ChildrenFlagIsSet = False;
				ChildrenFlagIsSet(TreeCurData.GetItems(), ChildrenFlagIsSet);
				If ChildrenFlagIsSet Then
					AskQuestion = True;
				EndIf;
			EndIf;
			If NOT AskQuestion Then
				AskQuestion = False;
				ParentsArray = New Array;
				SetMarksDown(TreeCurData, CurData, ParentsArray);
				DeleteByParentsArray(ParentsArray, CurData);
				AreChanges 										= True;
				Items.DepartmentTreeSave.Enabled 	= AreChanges;
				SetMarksUp(TreeCurData);
			Else
				If TreeCurData.Use Then
					QueryText = NStr("en='Do you want to select a check box for subsidiaries?';ru='Установить флаг для дочерних подразделений?'");
				Else
					QueryText = NStr("en='Do you want to unselect the subsidiaries?';ru='Снять флаг для дочерних подразделений?'");
				EndIf;
				AddPar = New Structure;
				AddPar.Insert("CurData", CurData);
				AddPar.Insert("TreeCurData", TreeCurData);
				NotifyDescription = New NotifyDescription("DepartmentTreeApplyOnChange_End", ThisObject, AddPar);
				ShowQueryBox(NotifyDescription, QueryText, QuestionDialogMode.YesNo);
			EndIf;
		Else
			AreChanges 										= True;
			Items.DepartmentTreeSave.Enabled 	= AreChanges;
		EndIf;
	Else
		AreChanges 										= True;
		Items.DepartmentTreeSave.Enabled 	= AreChanges;
	EndIf;
EndProcedure //ДеревоПодразделенийПрименятьПриИзменении()

&AtClient
Procedure ListOnActivateRow(Item)
	If NOT Items.List.CurrentRow = InfoStructure_Old Then
		If Items.DepartmentTree.Visible Then
			AttachIdleHandler("Attached_IdleHandlerListOnActivateRow", 0.1, True);
		EndIf;
	EndIf;
	InfoStructure_Old = Items.List.CurrentRow;
EndProcedure

#EndRegion

#Region FormCommandsHandlers

&AtClient
Procedure ResetFlags(Command)
	CurData	= Items.List.CurrentRow;
	If TypeOf(CurData) = Type("CatalogRef.fmInfoStructures") Then
		If NOT DepartmentTree.GetItems().Count() = 0 Then
			SetTreeFlags(DepartmentTree.GetItems(), CurData, False);
		EndIf;
		Filter = New Structure;
		Filter.Insert("InfoStructure", CurData);
		RowsArrayForDeletion = CommonFormInfoStructureTable.FindRows(Filter);
		For Each Item In RowsArrayForDeletion Do
			CommonFormInfoStructureTable.Delete(Item);
		EndDo;
	EndIf;
	AreChanges										= True;
	Items.DepartmentTreeSave.Enabled 	= AreChanges;
EndProcedure //СнятьФлажки()

&AtClient
Procedure SetFlags(Command)
	CurData 	= Items.List.CurrentRow;
	If TypeOf(CurData) = Type("CatalogRef.fmInfoStructures") Then
		If NOT DepartmentTree.GetItems().Count() = 0 Then
			SetTreeFlags(DepartmentTree.GetItems(), CurData, True);
		EndIf;
	EndIf;
	AreChanges 										= True;
	Items.DepartmentTreeSave.Enabled 	= AreChanges;
EndProcedure //УстановитьФлажки()

&AtClient
Procedure ApplyByDefault(Command)
	DepartmentTreeCurData = Items.DepartmentTree.CurrentData;
	If NOT DepartmentTreeCurData = Undefined Then
		CurDepartment = DepartmentTreeCurData.Department;
		CurParent = DepartmentTreeCurData.Parent;
	EndIf;
	CurData = Items.List.CurrentRow;
	PreviousRowValue = CurData;
	If NOT CurData = Undefined 
		AND TypeOf(CurData) = Type("CatalogRef.fmInfoStructures")
		AND NOT CurDepartment = Undefined Then
		// Проверим, есть ли уже для текущей структуры сведений запись по умолчанию
		Filter = New Structure;
		Filter.Insert("InfoStructure", CurData);
		Filter.Insert("Department",     CurDepartment);
		Rows = CommonFormInfoStructureTable.FindRows(Filter);
		If NOT Rows.Count() = 0 Then
			For Each Item In Rows Do
				If Item.ApplyByDefault Then
					Item.ApplyByDefault = False;
					Items.DepartmentTreeApplyByDefault.Check = False;
					DepartmentTreeCurData.ApplyByDefault = False;
				Else
					Set = False;
					// Проверим, есть ли уже для текущего подразделения структура сценария по умолчанию,
					// если есть, то спросим пользователя, желает ли он смены пользователя по умолчанию
					Filter = New Structure;
					Filter.Insert("StructureType",         StructureType);
					Filter.Insert("Department",        CurDepartment);
					Filter.Insert("ApplyByDefault", True);
					ResetRows = CommonFormInfoStructureTable.FindRows(Filter);
					If NOT ResetRows.Count() = 0 Then
						QueryText = NStr("en='This department has a default data structure. Do you want to continue changing the setting?';ru='Для текущего подразделения уже имеется структура сведений по умолчанию. Продолжить изменение настройки?'");
						AddPar = New Structure;
						AddPar.Insert("Item", Item);
						AddPar.Insert("ResetRows", ResetRows);
						AddPar.Insert("DoIteration", True);
						AddPar.Insert("DepartmentTreeCurData", DepartmentTreeCurData);
						AddPar.Insert("CurDepartment", CurDepartment);
						AddPar.Insert("InfoStructureCommonTableRow", Undefined);
						NotifyDescription = New NotifyDescription("SetApplyByDefault_End", ThisObject, AddPar);
						ShowQueryBox(NotifyDescription, QueryText, QuestionDialogMode.YesNo);
					Else
						Item.ApplyByDefault = True;
						Items.DepartmentTreeApplyByDefault.Check = True;
						Set = True;
						If Set Then
							DepartmentTreeCurData.ApplyByDefault = True;
							Items.DepartmentTreeApplyByDefault.Check = True;
						EndIf;
					EndIf;
					
				EndIf;
			EndDo;
		Else
			//ОбходДереваДляУстановкиИспользования(ДеревоПодразделений.ПолучитьЭлементы(), ТекПодразделение, ТекСтруктураСведений, СтрокаОбщейТаблицыСтруктурыСведений);
			InfoStructureCommonTableRow = CommonFormInfoStructureTable.Add();
			InfoStructureCommonTableRow.StructureType 		= StructureType;
			InfoStructureCommonTableRow.InfoStructure 	= CurData;
			InfoStructureCommonTableRow.Department 		= CurDepartment;
			InfoStructureCommonTableRow.Parent 			= CurParent;
			//после перехода на ф3
			Set = False;
			// Проверим, есть ли уже для текущего подразделения структура сценария по умолчанию,
			// если есть, то спросим пользователя, желает ли он смены пользователя по умолчанию
			Filter = New Structure;
			Filter.Insert("StructureType",         StructureType);
			Filter.Insert("Department",        CurDepartment);
			Filter.Insert("ApplyByDefault", True);
			ResetRows = CommonFormInfoStructureTable.FindRows(Filter);
			If NOT ResetRows.Count() = 0 Then
				QueryText = NStr("en='This department has a default data structure. Do you want to continue changing the setting?';ru='Для текущего подразделения уже имеется структура сведений по умолчанию. Продолжить изменение настройки?'");
				AddPar = New Structure;
				AddPar.Insert("Item", InfoStructureCommonTableRow);
				AddPar.Insert("ResetRows", ResetRows);
				AddPar.Insert("DoIteration", True);
				AddPar.Insert("DepartmentTreeCurData", DepartmentTreeCurData);
				AddPar.Insert("CurDepartment", CurDepartment);
				AddPar.Insert("InfoStructureCommonTableRow", InfoStructureCommonTableRow);
				NotifyDescription = New NotifyDescription("SetApplyByDefault_End", ThisObject, AddPar);
				ShowQueryBox(NotifyDescription, QueryText, QuestionDialogMode.YesNo);
			Else
				InfoStructureCommonTableRow.ApplyByDefault = True;
				Items.DepartmentTreeApplyByDefault.Check = True;
				TreeIterationForUseSetting(DepartmentTree.GetItems(), CurDepartment);
				DepartmentTreeCurData.ApplyByDefault = True;
				Items.DepartmentTreeApplyByDefault.Check = True;
			EndIf;
		EndIf;
	EndIf;
	AreChanges = True;
	ArePrimaryChanges = True;
	Items.DepartmentTreeSave.Enabled = AreChanges;
EndProcedure

&AtClient
Procedure Save(Command)
	SaveAtClient();
EndProcedure

&AtClient
Procedure Refresh(Command)
	UpdateBindingTreeAtServer();
EndProcedure

#EndRegion

#Region ProceduresAndFunctionsOfCommonUse

&AtClient
Procedure SetApplyByDefault_End(Response, Parameter) Export
	
	DepartmentTreeCurData = Parameter.DepartmentTreeCurData;
	CurDepartment= Parameter.CurDepartment;
	InfoStructureCommonTableRow = Parameter.InfoStructureCommonTableRow;

	DoIteration = Parameter.DoIteration;
	Set = False;
	Item = Parameter.Item;
	ResetRows = Parameter.ResetRows;
	If Response = DialogReturnCode.Yes Then
		For Each RowByDefault In ResetRows Do
			RowByDefault.ApplyByDefault = False;
		EndDo;
		Item.ApplyByDefault = True;
		Items.DepartmentTreeApplyByDefault.Check = True;
		Set = True;
	EndIf;
	If NOT DoIteration Then
		If Set Then
			DepartmentTreeCurData.ApplyByDefault = True;
			Items.DepartmentTreeApplyByDefault.Check = True;
		EndIf;
	Else
		If Set Then
			TreeIterationForUseSetting(DepartmentTree.GetItems(), CurDepartment);
			DepartmentTreeCurData.ApplyByDefault = True;
			Items.DepartmentTreeApplyByDefault.Check = True;
		Else
			CommonFormInfoStructureTable.Delete(InfoStructureCommonTableRow);
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure Attached_IdleHandlerListOnActivateRow()
	// Получим значение текущей строки
	AskQuestionSaveChanges();
	If NOT AreChanges Then
		RebulidTree();
	EndIf;
EndProcedure //Подключаемый_ОбработчикОжиданияСписокПриАктивизацииСтроки()

&AtServer
Procedure SetFlagsState(TreeRows)
	For Each TreeRow In TreeRows Do
		FilterTrue = New Structure;
		FilterTrue.Insert("Apply", True);
		FoundRowsArrayTrue = TreeRow.Rows.FindRows(FilterTrue, True);
		FilterFalse = New Structure;
		FilterFalse.Insert("Apply", False);
		FoundRowsArrayFalse = TreeRow.Rows.FindRows(FilterFalse, True);
		If NOT FoundRowsArrayTrue.Count() = 0
			AND NOT FoundRowsArrayFalse.Count() = 0 Then
			TreeRow.Use = 2;
		ElsIf NOT FoundRowsArrayTrue.Count() = 0
			AND FoundRowsArrayFalse.Count() = 0 Then
			If TreeRow.Apply Then
				TreeRow.Use = 1;
			Else
				TreeRow.Use = 2;
			EndIf;
		Else
			TreeRow.Use = TreeRow.Apply;
		EndIf;
		SetFlagsState(TreeRow.Rows);
	EndDo;
EndProcedure

&AtServer
Procedure AddDepartmentTree(CurStructure, AddParametersStructure)
	UpdateBindingTreeAtServer();
	DepartmentTree.GetItems().Clear();
	TreeParameters = New Structure;
	TreeParameters.Insert("OutputTree",                           True);
	TreeParameters.Insert("InfoStructure",                        CurStructure);
	TreeParameters.Insert("InfoStructures",                        CommonFormInfoStructureTable.Unload());
	TreeParameters.Insert("StructureVersionForBuilding",             ActualVersionForPeriod);
	TreeParameters.Insert("HeaderPeriodEnd",                        EndOfMonth(CurrentSessionDate()));
	AvailableDepartmentsTree = fmBudgeting.DepartmentCommonTree(TreeParameters);
	AvailableDepartmentsTree.Columns.Add("Use", New TypeDescription("Number"));
	SetFlagsState(AvailableDepartmentsTree.Rows);
	ValueToFormAttribute(AvailableDepartmentsTree, "DepartmentTree");
	TreeItems = DepartmentTree.GetItems();
	If NOT TreeItems.Count() = 0 Then
		ID = TreeItems[0].GetID();
		Items.DepartmentTree.CurrentRow = ID;
	EndIf;
EndProcedure //ДобавитьДеревоПодразделений()

&AtClient
Procedure SetTreeFlags(TreeRows, CurInfoStructure, FlagValue)
	For Each Item In TreeRows Do
		If FlagValue Then
			If Item.Use = 0 OR Item.Use = 2 Then
				Item.Use = FlagValue;
				AddValueInInfoStructureCommonTable(CurInfoStructure, Item.Department, Item.Parent);
			EndIf;
		Else
			If Item.Use = 1 OR Item.Use = 2 Then
				Item.Use = FlagValue;
			EndIf;
		EndIf;
		SetTreeFlags(Item.GetItems(), CurInfoStructure, FlagValue);
	EndDo;
EndProcedure //УстановитьФлажкиДерева()

&AtClient
Procedure AddValueInInfoStructureCommonTable(InfoStructure, Department, Parent)
	NewLine = CommonFormInfoStructureTable.Add();
	NewLine.StructureType		= StructureType;
	NewLine.InfoStructure 	= InfoStructure;
	NewLine.Department		= Department;
	NewLine.Parent			= Parent;
EndProcedure //ДобавитьЗначениеВОбщуюТаблицуСтруктурыСведений()

&AtServerNoContext
Function GetStructureType(InfoStructure)
	Return InfoStructure.StructureType;
EndFunction //ПолучитьТипСтруктуры()

&AtClient
Procedure DepartmentTreeApplyOnChange_End(Response, Parameter) Export
	CurData = Parameter.CurData;
	TreeCurData = Parameter.TreeCurData;
	If Response = DialogReturnCode.Yes Then
		ParentsArray = New Array;
		SetMarksDown(TreeCurData, CurData, ParentsArray);
		DeleteByParentsArray(ParentsArray, CurData);
	Else
		If TreeCurData.Use = 1 Then
			TreeCurData.Use = 2;
		EndIf;
	EndIf;
	AreChanges										= True;
	Items.DepartmentTreeSave.Enabled 	= AreChanges;
	SetMarksUp(TreeCurData);
EndProcedure

&AtClient
Procedure SetMarksUp(CurrentData)
	Parent = CurrentData.GetParent();
	If Parent <> Undefined Then
		AllTrue = True;
		NotAllFalse = False;
		Children = Parent.GetItems();
		For Each Child In Children Do
			AllTrue = AllTrue AND (Child.Use = 1) AND Parent.Use = 1;
			NotAllFalse = NotAllFalse OR Boolean(Child.Use);
		EndDo;
		If AllTrue Then
			Parent.Use = 1;
		ElsIf NotAllFalse Then
			Parent.Use = 2;
		Else
			//проверим в таблице признак у родителя
			Filter = New Structure;
			Filter.Insert("InfoStructure", Items.List.CurrentRow);
			Filter.Insert("Department",          Parent.Department);
			RowsArrayWithSet = CommonFormInfoStructureTable.FindRows(Filter);
			If RowsArrayWithSet.Count() = 0 Then
				Parent.Use = 0;
			Else
				Parent.Use = 2;
			EndIf;
		EndIf;
		SetMarksUp(Parent);
	EndIf;
EndProcedure //ПроставитьПометкиВверх()

&AtClient
Procedure SetMarksDown(CurrentData, CurInfoStructure, ParentsArray)
	Children = CurrentData.GetItems();
	Value = CurrentData.Use;
	If NOT Value AND NOT CurrentData.GetItems().Count() = 0 Then
		ParentsArray.Add(CurrentData.Department);
	EndIf;
	For Each Child In Children Do
		Child.Use = Value;
		If Value Then
			AddValueInInfoStructureCommonTable(CurInfoStructure, Child.Department, CurrentData.Department);
		Else
			Child.ApplyByDefault = False;
		EndIf;
		SetMarksDown(Child, CurInfoStructure, ParentsArray);
	EndDo;
EndProcedure //ПроставитьПометкиВниз()

&AtClient
Procedure ChildrenFlagIsNotSet(Tree, ChildrenFlagIsNotSet)
	For Each Item In Tree Do
		If NOT Item.Use Then
			ChildrenFlagIsNotSet = True;
			Break;
		Else
			ChildrenFlagIsNotSet(Item.GetItems(), ChildrenFlagIsNotSet);
		EndIf;
	EndDo;
EndProcedure

&AtClient
Procedure ChildrenFlagIsSet(Tree, ChildrenFlagIsSet)
	For Each Item In Tree Do
		If Item.Use Then
			ChildrenFlagIsSet = True;
			Break;
		Else
			ChildrenFlagIsSet(Item.GetItems(), ChildrenFlagIsSet);
		EndIf;
	EndDo;
EndProcedure

&AtServer
Procedure DeleteByParentsArray(ParentsArray, CurInfoStructure)
	For Each Item In ParentsArray Do
		DeleteValuesByParentFromInfoStructureCommonTable(CurInfoStructure, Item);
	EndDo;
EndProcedure

&AtClient
Procedure DeleteValueFromInfoStructureCommonTable(InfoStructure, Department)
	Filter = New Structure;
	Filter.Insert("InfoStructure", InfoStructure);
	Filter.Insert("Department",     Department);
	RowsArrayForDeletion = CommonFormInfoStructureTable.FindRows(Filter);
	For Each Item In RowsArrayForDeletion Do
		CommonFormInfoStructureTable.Delete(Item);
	EndDo;
EndProcedure //УдалитьЗначениеИзОбщейТаблицыСтруктурыСведений()

&AtServer
Procedure DeleteValuesByParentFromInfoStructureCommonTable(InfoStructure, Parent)
	Filter = New Structure;
	Filter.Insert("InfoStructure", InfoStructure);
	Filter.Insert("Parent",          Parent);

	RowsArrayForDeletion = CommonFormInfoStructureTable.FindRows(Filter);
	For Each Item In RowsArrayForDeletion Do
		CommonFormInfoStructureTable.Delete(Item);
	EndDo;
EndProcedure //УдалитьЗначениеИзОбщейТаблицыСтруктурыСведений()

&AtServerNoContext
Procedure AddConditionalAppearanceItemColor(FormTree, ConditionalAppearance, FieldName = Undefined, ComparisonType = Undefined, RightValue, Color, AppearanceItem)
	If TypeOf(ConditionalAppearance) = Type("DataCompositionConditionalAppearanceItem") Then
		ConditionalAppearanceItem = ConditionalAppearance;
	Else
		ConditionalAppearanceItem = ConditionalAppearance.Items.Add();
	EndIf;
	If NOT FieldName = Undefined Then
		If ComparisonType = Undefined Then
			_ComparisonType= DataCompositionComparisonType.Equal;
		Else
			_ComparisonType = ComparisonType;
		EndIf;
		DataFilterItem = CommonClientServer.AddCompositionItem(ConditionalAppearanceItem.Filter, FieldName, _ComparisonType, RightValue);
	EndIf;
	AppearanceColorItem = ConditionalAppearanceItem.Appearance.Items.Find(AppearanceItem);
	AppearanceColorItem.Value			= Color;
	AppearanceColorItem.Use	= True;
	FieldItem = ConditionalAppearanceItem.Fields.Items.Add();
	FieldItem.Field						= New DataCompositionField(FormTree);
	FieldItem.Use				= True;
EndProcedure //ДобавитьЭлементУсловногоОформления()

&AtClient
Procedure TreeIterationForUseSetting(TreeRows, Department)
	For Each Item In TreeRows Do
		If Item.Department = Department Then
			Item.Use = True;
		Break;
		Else
			TreeIterationForUseSetting(Item.GetItems(), Department);
		EndIf;
	EndDo;
EndProcedure //ОбходДереваДляУстановкиИспользования()

&AtClient
Procedure SaveAtClient()
	WroteSuccessfully = WriteAtServer();
	If WroteSuccessfully Then
		// Если не выбрано ни одно подразделение и записываем в регистр, то сообщаем пользователю, что регистр по текущей структуре сведений будет очищен
		CurData = Items.List.CurrentData;
		If NOT CurData = Undefined
			AND TypeOf(CurData) = Type("CatalogRef.fmInfoStructures") Then
			DepartmentsAreSelected = False;
			TreeIterationDepartmentsSelection(DepartmentTree.GetItems(), DepartmentsAreSelected);
			If NOT DepartmentsAreSelected Then
				WarningText = NStr("en='No department is selected. In the ""Information structures of data input/output"" information register, there will be no record according to structure <%1>. ';ru='Не выбрано ни одного подразделения. В РС ""Структуры сведений для ввода и вывода данных"" не будет ни одной записи по структуре <%1>.'");
				WarningText = StringFunctionsClientServer.SubstituteParametersToString(WarningText, CurData);
				CommonClientServer.MessageToUser(WarningText);
			EndIf;
		EndIf;
		Modified	= False;
		AreChanges		= False;
		ArePrimaryChanges = False;
		Items.DepartmentTreeSave.Enabled	= AreChanges;
	EndIf;
EndProcedure

&AtServer
Function WriteAtServer()
	WroteSuccessfully = True;
	// Получим записи из РС "уфСтруктурыСведенийДляВводаИВыводаДанных"
	Query = New Query();
	Query.Text = "SELECT
	|	fmBindingInfoStructuresToDepartments.InfoStructure,
	|	fmBindingInfoStructuresToDepartments.Department,
	|	fmBindingInfoStructuresToDepartments.ApplyByDefault
	|FROM
	|	InformationRegister.fmBindingInfoStructuresToDepartments AS fmBindingInfoStructuresToDepartments";
	
	RegisterRecordSet  = Query.Execute().Unload();
	
	// Получим общую таблицу структуры сведений, которая могла измениться во время работы пользователя (установка/снятие флажков напротив подразделений)
	InfoStructureCommonTable = New ValueTable;
	InfoStructureCommonTable.Columns.Add("InfoStructure",    New TypeDescription("CatalogRef.fmInfoStructures"));
	InfoStructureCommonTable.Columns.Add("Department",        New TypeDescription("CatalogRef.fmDepartments"));
	InfoStructureCommonTable.Columns.Add("ApplyByDefault", New TypeDescription("Boolean"));
	InfoStructureCommonTable.Columns.Add("Parent",             New TypeDescription("CatalogRef.fmDepartments"));
	
	For Each Item In CommonFormInfoStructureTable Do
		NewLine = InfoStructureCommonTable.Add();
		NewLine.InfoStructure 		= Item.InfoStructure;
		NewLine.Department 			= Item.Department;
		NewLine.ApplyByDefault 	= Item.ApplyByDefault;
		NewLine.Parent 				= Item.Parent;
	EndDo;
	
	// Соединим полученные две таблицы значений, получив изменения, которые нужно внести в РС "уфСтруктурыСведенийДляВводаИВыводаДанных"
	//(добавление подразделения или удаление из РС)
	Query = New Query();
	Query.TempTablesManager = New TempTablesManager;
	Query.Text = "SELECT
	               |	RegisterRecordSet.InfoStructure AS InfoStructure,
	               |	RegisterRecordSet.Department AS Department
	               |INTO TemporaryRegisterRecordSet
	               |FROM
	               |	&RegisterRecordSet AS RegisterRecordSet
	               |
	               |;
	               |
	               |////////////////////////////////////////////////////////////////////////////////
	               |SELECT
	               |	InfoStructureCommonTable.InfoStructure AS InfoStructure,
	               |	InfoStructureCommonTable.Department AS Department
	               |INTO TemporaryInfoStructureCommonTable
	               |FROM
	               |	&InfoStructureCommonTable AS InfoStructureCommonTable
	               |
	               |;
	               |
	               |////////////////////////////////////////////////////////////////////////////////
	               |SELECT
	               |	ISNULL(TemporaryRegisterRecordSet.InfoStructure, Value(Catalog.fmInfoStructures.EmptyRef)) AS InfoStructureDelete,
	               |	ISNULL(TemporaryRegisterRecordSet.Department, Value(Catalog.fmDepartments.EmptyRef)) AS DepartmentDelete,
	               |	ISNULL(TemporaryInfoStructureCommonTable.InfoStructure, Value(Catalog.fmInfoStructures.EmptyRef)) AS InfoStructureAdd,
	               |	ISNULL(TemporaryInfoStructureCommonTable.Department, Value(Catalog.fmDepartments.EmptyRef)) AS DepartmentAdd
	               |INTO TemporaryUnited
	               |FROM
	               |	TemporaryRegisterRecordSet AS TemporaryRegisterRecordSet
	               |		FULL JOIN TemporaryInfoStructureCommonTable AS TemporaryInfoStructureCommonTable
	               |		ON TemporaryRegisterRecordSet.InfoStructure = TemporaryInfoStructureCommonTable.InfoStructure
	               |			AND TemporaryRegisterRecordSet.Department = TemporaryInfoStructureCommonTable.Department
	               |;
	               |
	               |////////////////////////////////////////////////////////////////////////////////
	               |SELECT
	               |	TemporaryUnited.InfoStructureDelete,
	               |	TemporaryUnited.DepartmentDelete,
	               |	TemporaryUnited.InfoStructureAdd,
	               |	TemporaryUnited.DepartmentAdd
	               |FROM
	               |	TemporaryUnited AS TemporaryUnited
	               |WHERE
	               |	(TemporaryUnited.InfoStructureDelete = Value(Catalog.fmInfoStructures.EmptyRef)
	               |				AND TemporaryUnited.DepartmentDelete = Value(Catalog.fmDepartments.EmptyRef)
	               |			OR TemporaryUnited.InfoStructureAdd = Value(Catalog.fmInfoStructures.EmptyRef)
	               |				AND TemporaryUnited.DepartmentAdd = Value(Catalog.fmDepartments.EmptyRef))
	               |;
	               |
	               |////////////////////////////////////////////////////////////////////////////////
	               |DROP TemporaryRegisterRecordSet
	               |;
	               |
	               |////////////////////////////////////////////////////////////////////////////////
	               |DROP TemporaryInfoStructureCommonTable";
	
	Query.SetParameter("RegisterRecordSet",          RegisterRecordSet);
	Query.SetParameter("InfoStructureCommonTable", InfoStructureCommonTable);
	
	ChangesCommonTable = Query.Execute().Unload();
	
	FilterDelete = New Structure;
	FilterDelete.Insert("InfoStructureAdd", Catalogs.fmInfoStructures.EmptyRef());
	FilterDelete.Insert("DepartmentAdd",     Catalogs.fmDepartments.EmptyRef());
	
	FilterAdd = New Structure;
	FilterAdd.Insert("InfoStructureDelete", Catalogs.fmInfoStructures.EmptyRef());
	FilterAdd.Insert("DepartmentDelete",     Catalogs.fmDepartments.EmptyRef());
	
	// Строки, которые необходимо удалить из РС "уфСтруктурыСведенийДляВводаИВыводаДанных"
	RowsDelete 	= ChangesCommonTable.FindRows(FilterDelete);
	// Строки, которые необходимо добавить в РС "уфСтруктурыСведенийДляВводаИВыводаДанных"
	RowAdd 	= ChangesCommonTable.FindRows(FilterAdd);
	
	// Осуществим запись в РС
	InfoStructureRegisterForDataInputAndOutput = InformationRegisters.fmBindingInfoStructuresToDepartments;
	
	For Each Item In RowsDelete Do
		RecordSet = InformationRegisters.fmBindingInfoStructuresToDepartments.CreateRecordSet();
		RecordSet.Filter.InfoStructure.Set(Item.InfoStructureDelete);
		RecordSet.Filter.Department.Set(Item.DepartmentDelete);
		
		Try
			RecordSet.Write(True);
		Except
			WroteSuccessfully = False;
			CommonClientServer.MessageToUser(NStr("en='Failed to write it in the ""Information structures of data input/output"".';ru='Не удалось записать в РС ""Структуры сведений для ввода и вывода данных"".'"));
		EndTry;
	EndDo;
	If NOT RowAdd.Count() = 0 Then
		RecordSet = InformationRegisters.fmBindingInfoStructuresToDepartments.CreateRecordSet();
		For Each Item In RowAdd Do
			NewRecord = RecordSet.Add();
			NewRecord.InfoStructure 	= Item.InfoStructureAdd;
			NewRecord.Department 		= Item.DepartmentAdd;
		EndDo;
		Try
			RecordSet.Write(False);
		Except
			WroteSuccessfully = False;
			CommonClientServer.MessageToUser(NStr("en='Failed to write it in the ""Information structures of data input/output"".';ru='Не удалось записать в РС ""Структуры сведений для ввода и вывода данных""'"));
		EndTry;
	EndIf;
// Определим, были ли изменения ресурса "ПрименятьПоУмолчанию"
	If NOT RowsDelete.Count() = 0 OR NOT RowAdd.Count() = 0 Then
		Query = New Query();
		Query.Text = "SELECT
		|	fmBindingInfoStructuresToDepartments.InfoStructure,
		|	fmBindingInfoStructuresToDepartments.Department,
		|	fmBindingInfoStructuresToDepartments.ApplyByDefault
		|FROM
		|	InformationRegister.fmBindingInfoStructuresToDepartments AS fmBindingInfoStructuresToDepartments";
		
		RegisterRecordSet  = Query.Execute().Unload();
		
	EndIf;
	
	Query = New Query();
	Query.Text = "SELECT
	|	RegisterRecordSet.InfoStructure,
	|	RegisterRecordSet.Department,
	|	RegisterRecordSet.ApplyByDefault AS ApplyByDefaultRecordSet
	|INTO TemporaryRegisterRecordSet
	|FROM
	|	&RegisterRecordSet AS RegisterRecordSet
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	InfoStructureCommonTable.InfoStructure,
	|	InfoStructureCommonTable.Department,
	|	InfoStructureCommonTable.ApplyByDefault AS ApplyByDefaultCommonTable
	|INTO TemporaryInfoStructureCommonTable
	|FROM
	|	&InfoStructureCommonTable AS InfoStructureCommonTable
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TemporaryRegisterRecordSet.InfoStructure,
	|	TemporaryRegisterRecordSet.Department,
	|	TemporaryRegisterRecordSet.ApplyByDefaultRecordSet,
	|	TemporaryInfoStructureCommonTable.ApplyByDefaultCommonTable
	|INTO TemporaryTotal
	|FROM
	|	TemporaryRegisterRecordSet AS TemporaryRegisterRecordSet
	|		LEFT JOIN TemporaryInfoStructureCommonTable AS TemporaryInfoStructureCommonTable
	|		ON TemporaryRegisterRecordSet.InfoStructure = TemporaryInfoStructureCommonTable.InfoStructure
	|			AND TemporaryRegisterRecordSet.Department = TemporaryInfoStructureCommonTable.Department
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|DROP TemporaryRegisterRecordSet
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|DROP TemporaryInfoStructureCommonTable
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TemporaryTotal.InfoStructure,
	|	TemporaryTotal.Department,
	|	TemporaryTotal.ApplyByDefaultRecordSet,
	|	TemporaryTotal.ApplyByDefaultCommonTable
	|FROM
	|	TemporaryTotal AS TemporaryTotal
	|WHERE
	|	NOT TemporaryTotal.ApplyByDefaultRecordSet = TemporaryTotal.ApplyByDefaultCommonTable";
	
	Query.SetParameter("RegisterRecordSet",          RegisterRecordSet);
	Query.SetParameter("InfoStructureCommonTable", InfoStructureCommonTable);
	
	RowsChange = Query.Execute().Unload();
	
	For Each Item In RowsChange Do
		Record = InfoStructureRegisterForDataInputAndOutput.CreateRecordManager();
		Record.InfoStructure 	= Item.InfoStructure;
		Record.Department 		= Item.Department;
		Record.ApplyByDefault = Item.ApplyByDefaultCommonTable;
		Try
			Record.Write();
		Except
			WroteSuccessfully = False;
			CommonClientServer.MessageToUser(NStr("en='The informational register ""Inflows & Outflows data structure"" was not recorded.';ru='NOT удалось Write IN РС ""Структуры сведений For ввода AND вывода данных""Не удалось записать в РС ""Структуры сведений для ввода и вывода данных""'"));
		EndTry;
	EndDo;
	
	Return WroteSuccessfully;
	
EndFunction //ЗаписатьНаСервере()

&AtClient
Procedure TreeIterationDepartmentsSelection(TreeRows, DepartmentsAreSelected)
	For Each Item In TreeRows Do
		If Item.Use Then
			DepartmentsAreSelected = True;
			Break;
		Else
			TreeIterationDepartmentsSelection(Item.GetItems(), DepartmentsAreSelected);
		EndIf;
	EndDo;
EndProcedure //ОбходДереваВыборПодразделений()

&AtClient
Procedure AskQuestionSaveChanges()
	If AreChanges Then
		QueryText = NStr("en='Do you want to save changes in relationship between a structure and departments?';ru='Сохранить изменения связей между структурой и подразделениями?'");
		NotifyDescription = New NotifyDescription("AskQuestionSaveChanges_End", ThisObject);
		ShowQueryBox(NotifyDescription, QueryText, QuestionDialogMode.YesNo);
	EndIf;
EndProcedure

&AtClient
Procedure AskQuestionSaveChanges_End(Response, Parameter) Export
	If Response = DialogReturnCode.Yes Then
		SaveAtClient();
		RebulidTree();
	Else
		RebulidTree();
		AreChanges = False;
		Items.DepartmentTreeSave.Enabled = AreChanges;
	EndIf;
EndProcedure

&AtServer
Procedure UpdateBindingTreeAtServer()
	CommonFormInfoStructureTable.Clear();
	// Получим все данные РС "уфСтруктурыСведенийДляВводаИВыводаДанных"
	Query = New Query();
	Query.Text = "SELECT
	               |	fmBindingInfoStructuresToDepartments.InfoStructure AS InfoStructure,
	               |	fmBindingInfoStructuresToDepartments.Department AS Department,
	               |	fmBindingInfoStructuresToDepartments.ApplyByDefault AS ApplyByDefault,
	               |	fmBindingInfoStructuresToDepartments.InfoStructure.StructureType AS StructureType,
	               |	fmBindingInfoStructuresToDepartments.Department.Parent AS Parent
	               |FROM
	               |	InformationRegister.fmBindingInfoStructuresToDepartments AS fmBindingInfoStructuresToDepartments";
	RecordSetTable = Query.Execute().Unload();
	For Each Item In RecordSetTable Do
		NewLine = CommonFormInfoStructureTable.Add();
		NewLine.StructureType			= Item.StructureType;
		NewLine.InfoStructure		= Item.InfoStructure;
		NewLine.Department			= Item.Department;
		NewLine.ApplyByDefault 	= Item.ApplyByDefault;
		NewLine.Parent				= Item.Parent;
	EndDo;
EndProcedure

&AtClient
Procedure RebulidTree()
	CurData = Items.List.CurrentRow;
	If NOT CurData = Undefined
		AND TypeOf(CurData) = Type("CatalogRef.fmInfoStructures") Then
		StructureType = GetStructureType(CurData);
		AddParametersStructure = New Structure;
		AddParametersStructure.Insert("CurUser",CurUser);
		AddDepartmentTree(CurData, AddParametersStructure);
		For Each Item In DepartmentTree.GetItems() Do
			ID = Item.GetID();
			Items.DepartmentTree.Expand(ID);
		EndDo;
	Else
		DepartmentTree.GetItems().Clear();
	EndIf;
EndProcedure

&AtClient
Procedure DepartmentTreeOnActivateRow(Item)
	CurRow = Items.DepartmentTree.CurrentRow;
	If NOT CurRow = Undefined Then
		CurItem = DepartmentTree.FindByID(CurRow);
		If NOT CurItem = Undefined Then
			If CurItem.ApplyByDefault Then
				Items.DepartmentTreeApplyByDefault.Check = True;
			Else
				Items.DepartmentTreeApplyByDefault.Check = False;
			EndIf;
		EndIf;
	EndIf;
EndProcedure

#EndRegion















