
#Region ProceduresAndFunctionsOfCommonUse

&AtClient
Procedure ExpandTree()
	Filter = New Structure;
	Filter.Insert("Version", StructureVersion);
	StringArray = ExpandedNodesTree.FindRows(Filter);
	For Each Node In StringArray Do
		If ValueIsFilled(Node.Department) Then
			If NOT DepartmentTreeMain.FindByID(Node.ID) = Undefined Then
				Items.DepartmentTreeMain.Expand(Node.ID, False);
			EndIf;
		EndIf;
	EndDo;
	If ValueIsFilled(CurrentRowID) Then
		Items.DepartmentTreeMain.CurrentRow = CurrentRowID;
	EndIf;
	If StringArray.Count() = 0 Then
		ExpandFirstLevel();
	EndIf;
EndProcedure

&AtClient
Procedure ExpandFirstLevel()
	FirstLevelItems = DepartmentTreeMain.GetItems();
	For Each TreeFirstLevelRow In FirstLevelItems Do
		//добавим строку в таблицу развернутых
		RowID = TreeFirstLevelRow.GetID();
		NRowExpNodes = ExpandedNodesTree.Add();
		NRowExpNodes.Version = StructureVersion;
		NRowExpNodes.Department = TreeFirstLevelRow.Department;
		NRowExpNodes.ID = RowID;
		//и развернем
		Items.DepartmentTreeMain.Expand(RowID, False);
	EndDo;
EndProcedure

&AtServer
Procedure ChangeColorAtServer(ChosenValue)
	If TypeOf(ChosenValue) = Type("Structure") Then
		WithChildren = ChosenValue.WithChildren;
		SetType = ChosenValue.SetType;
		CurDepartment = ChosenValue.CurDepartment;
		If NOT WithChildren Then
			//меняем тип только тек подразделения
			CurDepObject = CurDepartment.GetObject();
			CurDepObject.DepartmentType = SetType;
			//ТекПодрОбъект.ВерсияСтруктуры = ВерсияСтруктуры;
			//ТекПодрОбъект.Родитель = уфБюджетирование.РодительПодразделенияПоВерсии(ТекПодрОбъект.Ссылка, ВерсияСтруктуры);
			If CurDepObject.DeletionMark Then
				WarnText = StrTemplate(NStr("en='Department %1 is marked for deletion. For this reason, the color will not be updated in the list';ru='Подразделение %1 помечено на удаление. Цвет не будет обновлен в списке'"), String(CurDepObject));
				CommonClientServer.MessageToUser(WarnText);
			EndIf;
			Try
				CurDepObject.Write();
			Except
				CommonClientServer.MessageToUser(ErrorDescription());
			EndTry;
		ElsIf ValueIsFilled(Items.DepartmentTreeMain.CurrentRow) Then
			//меняем только то, что видим, поэтому будем брать внутренние элементы через дерево на форме
			TreeAttributeItem = DepartmentTreeMain.FindByID(Items.DepartmentTreeMain.CurrentRow);
			ChangedDepartmentsArray = New Array;
			ChangedDepartmentsArray.Add(TreeAttributeItem.Department);
			Child = TreeAttributeItem.GetItems();
			//3й параметр - пропускаем помеченные на удаление элементы
			ChangedDepartmentsArray = GetChildrenInLoop(ChangedDepartmentsArray, Child, True); 
			For Each oDepartment In ChangedDepartmentsArray Do
				If oDepartment.DeletionMark Then
					WarnText = StrTemplate(NStr("en='Department %1 is marked for deletion. For this reason, the color will not be updated in the list';ru='Подразделение %1 помечено на удаление. Цвет не будет обновлен в списке'"), String(oDepartment));
					CommonClientServer.MessageToUser(WarnText);
				EndIf;
				CurDepObject = oDepartment.GetObject();
				CurDepObject.DepartmentType = SetType;
				//ТекПодрОбъект.ВерсияСтруктуры = ВерсияСтруктуры;
				//ТекПодрОбъект.Родитель = уфБюджетирование.РодительПодразделенияПоВерсии(ТекПодрОбъект.Ссылка, ВерсияСтруктуры);
				Try
					CurDepObject.Write();
				Except
					CommonClientServer.MessageToUser(ErrorDescription());
				EndTry;
			EndDo;
		EndIf;
	EndIf;
EndProcedure

&AtClient
Procedure ChangeDepartmentsColor_End(Sel, AddPar) Export
	If ValueIsFilled(Sel) Then
		If NOT ValueIsFilled(Sel.SetType) Then
			Return;
		EndIf;
		RefreshColorOnForm(Sel);
	EndIf;
EndProcedure

&AtClient
Procedure RefreshColorOnForm(ChosenValue)
	If ValueIsFilled(ChosenValue) Then
		ChangeColorAtServer(ChosenValue);
	EndIf;
	RebuildTreeAtServer();
	ExpandTree();
EndProcedure

&AtServer
Procedure RebuildTreeAtServer(AccordingSearch = False, StrSearchParam = Undefined, ChosenValue = Undefined)
	DepartmentTreeMain.GetItems().Clear();
	If NOT StructureVersion.IsEmpty() Then
		If NOT ValueIsFilled(StructureVersion.DateValidUntil) Then
			DATE = DATE('39991231') 
		Else
			DATE = StructureVersion.DateValidUntil;
		EndIf;
	Else
		DATE = CurrentSessionDate();
	EndIf;
	StrParameters = New Structure;
	StrParameters.Insert("StructureVersionForBuilding", StructureVersion);
	StrParameters.Insert("HeaderPeriodEnd", DATE);
	StrParameters.Insert("LimitByAccessGroups", False);
	StrParameters.Insert("IncludeMarkedDepertments", IncludeMarkedDepertments);
	StrParameters.Insert("OutputTree", True);
	If AccordingSearch Then
		StrParameters.Insert("SearchAttribute", StrSearchParam.SearchAttribute);
		StrParameters.Insert("SearchValue", StrSearchParam.SearchValue);
		StrParameters.Insert("SearchMethod", StrSearchParam.SearchMethod);
		If  StrSearchParam.Property("RootDepartment") Then
			StrParameters.Insert("RootDepartment", StrSearchParam.RootDepartment);
		EndIf;
	EndIf;
	StructureMaximumVersion = fmBudgeting.ReturnDepartmentStructureActualVersion();
	DepartmentTreeMainVT = fmBudgeting.DepartmentCommonTree(StrParameters);
	DepartmentsIDs = New Map;
	BuildDepartmentTreeMain(DepartmentTreeMain, DepartmentTreeMainVT, DepartmentsIDs, ChosenValue, StructureMaximumVersion);
	DepartmentsIDsStorageAddress = PutToTempStorage(DepartmentsIDs, New UUID);
	//очистим условное оформление и заново раскрасим подразделения
	ConditionalAppearance.Items.Clear();
	Catalogs.fmDepartments.ColorTreeItems(ConditionalAppearance, "DepartmentTreeMain", "DepartmentTreeMain.DepartmentType", "DepartmentTreeMain.Department");
EndProcedure

&AtServer
Procedure BuildDepartmentTreeMain(TreeOnForm, TreeVT, DepartmentsIDs, ChosenValue = Undefined, StructureMaximumVersion)
	
	For Each Item In TreeVT.Rows Do
		RowDestination = TreeOnForm.GetItems().Add();
		RowDestination.Department 				= Item.Department;
		RowDestination.DepartmentType 			= Item.DepartmentType;
		RowDestination.ManageType 			= Item.ManageType;
		RowDestination.Code			 			= Item.Code;
		RowDestination.Parent		 			= Item.Parent;
		RowDestination.PictureIndex		 		= ?(Item.DeletionMark, 3, 2);
		RowDestination.BalanceUnit						= Item.BalanceUnit;
		RowDestination.Responsible				= Item.Responsible;
		IDOfRow = RowDestination.GetID();
		DepartmentsIDs.Insert(RowDestination.Department, IDOfRow);
		//обновим идентификатор в таблице развернутых узлов
		
		If StructureVersion = StructureMaximumVersion Then
			ChangedItems = Item.Department.GetObject();
			ChangedItems.DepartmentType 			= Item.DepartmentType;
			ChangedItems.Parent					= Item.Department.Parent;
			ChangedItems.StructureVersion			= StructureVersion;
			ChangedItems.Write();
		EndIf;
		
		Filter = New Structure;
		Filter.Insert("Version", StructureVersion);
		Filter.Insert("Department", Item.Department);
		StringArray = ExpandedNodesTree.FindRows(Filter);
		For Each ArrItem In StringArray Do
			ArrItem.ID = IDOfRow;
		EndDo;
		BuildDepartmentTreeMain(RowDestination, Item, DepartmentsIDs , ChosenValue,StructureMaximumVersion);
		If NOT ChosenValue = Undefined Then
			If Item.Department = ChosenValue.Ref Then
				CurrentRowID = RowDestination.GetID();
			EndIf;
		EndIf;
	EndDo;
	If StructureVersion = StructureMaximumVersion Then
		//ЭтаФорма.ТолькоПросмотр = Ложь;
		Items.GroupLeftCommands.Enabled = True;
		Items.DepartmentTreeMain.ReadOnly = False;
		Items.ChangeDepartmentsType.Enabled = True;
	Else
		//ЭтаФорма.ТолькоПросмотр = Истина;
		Items.GroupLeftCommands.Enabled = False;
		Items.DepartmentTreeMain.ReadOnly = True;
		Items.ChangeDepartmentsType.Enabled = False;
	EndIf;
EndProcedure

&AtClient
Procedure DeleteMarkedDepartmentsInVersion_End(UserReturnCode, Parameter) Export
	If UserReturnCode = DialogReturnCode.Yes Then
		DeleteMarkedServer();
	EndIf;
	ExpandTree();
EndProcedure

&AtServer
Procedure DeleteDepartmentFromStructureServer(TreeCurRow, InAll, UnmarkOnDeletion)
	If InAll Then
		TreeAttributeItem = DepartmentTreeMain.FindByID(TreeCurRow);
		Query = New Query;
		Query.Text = "SELECT
			               |	fmDepartmentHierarchy.Department AS Department,
			               |	fmDepartmentHierarchy.StructureVersion AS StructureVersion,
			               |	fmDepartmentHierarchy.DepartmentParent AS DepartmentParent
			               |FROM
			               |	InformationRegister.fmDepartmentHierarchy AS fmDepartmentHierarchy
			               |WHERE
			               |	(fmDepartmentHierarchy.Department = &Department
			               |			OR fmDepartmentHierarchy.DepartmentParent IN HIERARCHY (&DepartmentParent))
			               |TOTALS BY
			               |	StructureVersion";
			
			Query.SetParameter("Department",TreeAttributeItem.Department);
			Query.SetParameter("DepartmentParent",TreeAttributeItem.Department);
			SelectionByGroups = Query.Execute().SELECT(QueryResultIteration.ByGroups,"StructureVersion");
			DeletedArray = New Array;
			While SelectionByGroups.Next() Do
				Selection = SelectionByGroups.SELECT();
				While Selection.Next() Do
					IRRecordSet = InformationRegisters.fmDepartmentHierarchy.CreateRecordSet();
					IRRecordSet.Filter.Department.Set(Selection.Department);
					IRRecordSet.Filter.StructureVersion.Set(Selection.StructureVersion);
					IRRecordSet.Read();
					If UnmarkOnDeletion Then
						IRRecordSet[0].DeletionMark = False;
					Else
						IRRecordSet[0].DeletionMark = True;
					EndIf;
					IRRecordSet.Write();
					If NOT ValueIsFilled(DeletedArray.Find(Selection.Department)) Then
						DeletedArray.Add(Selection.Department);
					EndIf;
				EndDo;
			EndDo;
			For Each Item In DeletedArray Do
				DeletedDepartment = Catalogs.fmDepartments.FindByDescription(Item).GetObject();
				If UnmarkOnDeletion Then
					DeletedDepartment.DeletionMark = False;
				Else
					DeletedDepartment.DeletionMark = True;
				EndIf;
				DeletedDepartment.Write();
			EndDo;
		RebuildTreeAtServer();
	Else
		TreeAttributeItem = DepartmentTreeMain.FindByID(TreeCurRow);
		DeletedDepartmentsArray = New Array;
		DeletedDepartmentsArray.Add(TreeAttributeItem.Department);
		Child = TreeAttributeItem.GetItems();
		DeletedDepartmentsArray = GetChildrenInLoop(DeletedDepartmentsArray, Child); 
		For Each DeletedDep In DeletedDepartmentsArray Do
			IRRecordSet = InformationRegisters.fmDepartmentHierarchy.CreateRecordSet();
			IRRecordSet.Filter.StructureVersion.Set(StructureVersion);
			IRRecordSet.Filter.Department.Set(DeletedDep);
			IRRecordSet.Read();
			If UnmarkOnDeletion Then
				IRRecordSet[0].DeletionMark = False;
			Else
				IRRecordSet[0].DeletionMark = True;
			EndIf;
			IRRecordSet.Write();
		EndDo;
		RebuildTreeAtServer();
	EndIf;
EndProcedure

&AtServer
Procedure DeleteMarkedServer()
	Query = New Query;
	Query.Text = "SELECT
	               |	DepartmentHierarchy.Department AS Department,
	               |	DepartmentHierarchy.DepartmentParent AS DepartmentParent,
	               |	DepartmentHierarchy.StructureVersion AS StructureVersion,
	               |	DepartmentHierarchy.DeletionMark AS DeletionMark
	               |FROM
	               |	InformationRegister.fmDepartmentHierarchy AS DepartmentHierarchy
	               |TOTALS BY
	               |	Department";

	SelectionByGroups = Query.Execute().SELECT(QueryResultIteration.ByGroups,"Department");
	DeletedArray = New Array;
	While SelectionByGroups.Next() Do
		Selection = SelectionByGroups.SELECT();
		FullyMarked = True;
		While Selection.Next() Do
			If Selection.DeletionMark = True Then
				RegisterRS = InformationRegisters.fmDepartmentHierarchy.CreateRecordSet();
				RegisterRS.Filter.Department.Set(Selection.Department);
				RegisterRS.Filter.DepartmentParent.Set(Selection.DepartmentParent);
				RegisterRS.Filter.StructureVersion.Set(Selection.StructureVersion);
				RegisterRS.Read();
				RegisterRS.Clear();
				RegisterRS.Write();
			Else
				FullyMarked = False;
			EndIf;
		EndDo;
		If NOT ValueIsFilled(DeletedArray.Find(SelectionByGroups.Department)) AND FullyMarked Then
			DeletedArray.Add(SelectionByGroups.Department);
		EndIf;
	EndDo;
	For Each Item In DeletedArray Do
		RegisterRS = InformationRegisters.fmDepartmentHierarchy.CreateRecordSet();
		RegisterRS.Filter.Department.Set(Item);
		RegisterRS.Read();
		
		If NOT ValueIsFilled(RegisterRS) Then
			State = InformationRegisters.fmDepartmentsState.CreateRecordSet();
			State.Filter.Department.Set(Item);
			State.Read();
			State.Clear();
			State.Write();
			
			DeletedDepartment = Catalogs.fmDepartments.FindByDescription(Item).GetObject();
			DeletedDepartment.Delete();
		EndIf;
	EndDo;
	RebuildTreeAtServer();
EndProcedure

&AtClient
Procedure DeleteDepartmentFromStructure_End(UserReturnCode, Parameter) Export
	TreeCurRow = Parameter.TreeCurRow;
	If UserReturnCode = DialogReturnCode.Yes Then
		DeleteDepartmentFromStructureServer(TreeCurRow, False, Parameter.Check);
	ElsIf UserReturnCode = DialogReturnCode.OK Then
		DeleteDepartmentFromStructureServer(TreeCurRow, True, Parameter.Check);
	EndIf;
	ExpandTree();
EndProcedure

&AtClient
Procedure DepartmentsSearch_End(SelSearchParam, AddPar) Export
	If NOT SelSearchParam = Undefined Then
		SearchAttribute = SelSearchParam.SearchAttribute; //"1"- наименование, "2" - код
		SearchValue = SelSearchParam.SearchValue;
		SearchMethod = SelSearchParam.SearchMethod; //1 - по началу строки, 2 - в любом месте строки, 3-точное соответствие
		Items.DepartmentTreeMain.Representation = TableRepresentation.List;
		RebuildTreeAtServer(True, SelSearchParam);
	EndIf;
EndProcedure

&AtServer
Procedure FormUpdateVersionsButtons()
	//предыдущей версией таблицы соответствий кнопок воспользуемся чтобы кнопки удалить, 
	For Each MapString In ButtonsToVersionsMapTable Do
		DeletedButton = ThisForm.Items.Find(MapString.Description);
		If NOT DeletedButton = Undefined Then
			ThisForm.Items.Delete(DeletedButton);
		EndIf;
		
		CachedItem = Items.GroupCreatedVersions.ChildItems.Find(MapString.Description);
		If NOT CachedItem = Undefined Then
			ThisForm.Items.Delete(CachedItem);
		EndIf;
		
		DeletedCommand = ThisForm.Commands.Find(MapString.Description);
		If NOT DeletedCommand = Undefined Then
			ThisForm.Commands.Delete(DeletedCommand);
		EndIf;
	EndDo;
	ButtonsToVersionsMapTable.Clear();
	Query = New Query;
	Query.Text = "SELECT
	|	DepartmentsStructuresVersions.ApprovalDate AS VersionApprovalDate,
	|	DepartmentsStructuresVersions.DateValidUntil,
	|	DepartmentsStructuresVersions.Ref,
	|	DepartmentsStructuresVersions.Description
	|FROM
	|	Catalog.fmDepartmentsStructuresVersions AS DepartmentsStructuresVersions
	|WHERE 
	|	NOT DepartmentsStructuresVersions.DeletionMark
	|
	|ORDER BY
	|	ApprovalDate DESC"; 
	VTExisting = Query.Execute().Unload();
	ButtonsTable = New ValueTable;
	ButtonsTable.Columns.Add("ButtonName");
	ButtonsTable.Columns.Add("Presentation");
	ButtonsTable.Columns.Add("Selected");
	For Each Item In VTExisting Do
		// Заполним таблицу кнопок
		ButtonsTableNewRow = ButtonsTable.Add();
		//имя кнопки будет состоять из имени версии + имени иерархии
		ButtonsTableNewRow.ButtonName 		= StrReplace(String(Item.Description) , " ", "");   //уберем запрещенные для имен кнопок символы
		ButtonsTableNewRow.ButtonName 		= StrReplace(ButtonsTableNewRow.ButtonName, "(", "");
		ButtonsTableNewRow.ButtonName 		= StrReplace(ButtonsTableNewRow.ButtonName, ")", "");
		ButtonsTableNewRow.ButtonName 		= StrReplace(ButtonsTableNewRow.ButtonName, ".", "");
		ButtonsTableNewRow.Presentation 	= Item.Description;
 		If Item.Ref = StructureVersion Then
			ButtonsTableNewRow.Selected 	= True;
		Else
			ButtonsTableNewRow.Selected 	= False;
		EndIf;
		// Заполним таблицу соответствий кнопок
		MapTableNewRow 					= ButtonsToVersionsMapTable.Add();
		MapTableNewRow.Description 	= ButtonsTableNewRow.ButtonName;
		MapTableNewRow.Version	 		= Item.Ref;
		MapTableNewRow.Presentation 	= Item.Description;
	EndDo;
	ButtonsTableNewRow = ButtonsTable.Add();
	ButtonsTableNewRow.ButtonName 		= "CreateNew";
	ButtonsTableNewRow.Presentation 	= NStr("en='Create new';ru='Создать новую'");
	ButtonsTableNewRow.Selected	= False;
	MapTableNewRow					= ButtonsToVersionsMapTable.Add();
	MapTableNewRow.Description		= ButtonsTableNewRow.ButtonName;
	MapTableNewRow.Version			= Catalogs.fmDepartmentsStructuresVersions.EmptyRef();
	MapTableNewRow.Presentation	= NStr("en='Create new';ru='Создать новую'");
	//и создадаим кнопки на форме
	For Each Item In ButtonsTable Do
		// Выведем непосредственно кнопки
		If Item.ButtonName = "CreateNew" Then
			Button = ThisForm.Items.Add(Item.ButtonName,Type("FormButton"),Items.NewVersionCreation);
		Else
			Button = ThisForm.Items.Add(Item.ButtonName,Type("FormButton"), Items.GroupCreatedVersions);
		EndIf;
		Command = ThisForm.Commands.Add(Item.ButtonName);
		Command.Action = "StructureVersionUpdate";
		Button.CommandName 	= Item.ButtonName;
		Button.Title 	= Item.Presentation;
		If Item.Selected Then
			Button.Picture = PictureLib.fmOperationExecutedSuccessfully;
			Items.SubmenuSwitchVersions.Title = Item.Presentation;
		EndIf;
	EndDo;
EndProcedure

&AtServer
Function GetChildrenInLoop(DeletedDepartmentsArray, LevelChildren, SkipMarked = False)
	For Each ChildIt In LevelChildren Do
		If NOT (SkipMarked AND ChildIt.PictureIndex = 3) Then 
			DeletedDepartmentsArray.Add(ChildIt.Department);
		EndIf;
		GetChildrenInLoop(DeletedDepartmentsArray, ChildIt.GetItems());
	EndDo;
	Return DeletedDepartmentsArray; 
EndFunction

&AtServer
Procedure NewStructureVersionRecordProcessing(ParametersStructure)
//после записи структуры нам нужно создать полную копию самой актуальной версии в РС Иерархия подразделений
//1. определим самую актуальную версию
	NewVersionRef = ParametersStructure.NewVersionRef;

	VersionsToExcludeArray = New Array;
	VersionsToExcludeArray.Add(NewVersionRef);
	MaxStructureVersion = fmBudgeting.ReturnDepartmentStructureActualVersion(,VersionsToExcludeArray);//ВернутьМаксимальнуюВерсию();

	//2. запишем копию с новым измерением версии в РС
	RecordSetInitial = InformationRegisters.fmDepartmentHierarchy.CreateRecordSet();
	RecordSetInitial.Filter.StructureVersion.Set(MaxStructureVersion);
	RecordSetInitial.Read();
	TableInitial = RecordSetInitial.Unload();
	//заполняем новую версию в нашу ТЗ
	TableInitial.FillValues(NewVersionRef, "StructureVersion");

	RecordSetNew = InformationRegisters.fmDepartmentHierarchy.CreateRecordSet();
	RecordSetNew.Filter.StructureVersion.Set(NewVersionRef);
	RecordSetNew.Read();
	RecordSetNew.Load(TableInitial);
	RecordSetNew.Write();

	// rarus fm begin test

	For Each String In TableInitial Do
		NewItems = Catalogs.fmDepartments.FindByDescription(String.Department.Description).GetObject();
		NewItems.StructureVersion = NewVersionRef;
		NewItems.Write();
	EndDo;

	// rarus fm end test

	//в шапке заменим выбранное значение версии
	StructureVersion = NewVersionRef;
	RebuildTreeAtServer();
EndProcedure

&AtClient
// Процедура удаляет из таблицы "Таблица развернутых узлов" все раскрытые дочерние узлы узла, который сворачиваем
//(т.е. если сворачиваем какой-то узел, все его дочерние узлы также должны быть свернуты)
//
Procedure CheckChildNodes(NodeItems)
	For Each ChildNode In NodeItems Do
		Filter = New Structure;
		Filter.Insert("Version", StructureVersion);
		Filter.Insert("Department", ChildNode.Department);
		StringArray = ExpandedNodesTree.FindRows(Filter);
		For Each Item In StringArray Do
			ExpandedNodesTree.Delete(Item);
		EndDo;
		CheckChildNodes(ChildNode.GetItems());
	EndDo;
EndProcedure

&AtServer
Procedure ParentChangeAtServer(MovedDepartment, DepartmentDestination)
	ObjectSource = MovedDepartment.GetObject();
	ObjectSource.Parent = DepartmentDestination;
	Try
		ObjectSource.StructureVersion = StructureVersion;
		ObjectSource.Write();
	Except
		CommonClientServer.MessageToUser("ru = 'Ошибка записи'; en = 'Transfer error'");
		Return;
	EndTry;
	RebuildTreeAtServer();
EndProcedure

&AtServer
Procedure RebuildFormItems()
	RebuildTreeAtServer();
	FormUpdateVersionsButtons();
EndProcedure

&AtServer
Procedure WriteRefreshNewStructureVersion(Parameter)
	NewStructureVersionRecordProcessing(Parameter);
	FormUpdateVersionsButtons();
EndProcedure

#EndRegion


#Region ItemsHandlers

&AtClient
Procedure DepartmentTreeMainChoice(Item, SelectedRow, Field, StandardProcessing)
	TreeCurData = DepartmentTreeMain.FindByID(SelectedRow);
	If NOT TreeCurData = Undefined Then
		FormParameters = New Structure;
		FormParameters.Insert("Key", TreeCurData.Department);
		ItemParent = TreeCurData.GetParent();
		If NOT ItemParent = Undefined Then
			FormParameters.Insert("Parent", ItemParent.Department);
		EndIf;
		FormParameters.Insert("StructureVersion", StructureVersion);
		OpenForm("Catalog.fmDepartments.ObjectForm", FormParameters,ThisForm);
	EndIf;
EndProcedure

&AtClient
Procedure DepartmentTreeMainBeforeExpand(Item, String, Cancel)
	Node = DepartmentTreeMain.FindByID(String);
	Filter = New Structure;
	Filter.Insert("Version", StructureVersion); 
	Filter.Insert("Department",Node.Department);
	StringArray = ExpandedNodesTree.FindRows(Filter);
	If StringArray.Count() = 0 Then
		NewLine = ExpandedNodesTree.Add();
		NewLine.Version							= StructureVersion;
		NewLine.Department					= Node.Department;
		NewLine.ID					= String;
	Else
		StringArray[0].ID				= String;
	EndIf;
EndProcedure

&AtClient
Procedure DepartmentTreeMainBeforeCollapse(Item, String, Cancel)
	If Item.CurrentData = Undefined Then
		Cancel = True;
		Return;
	EndIf;
	Node = DepartmentTreeMain.FindByID(String);
	If NOT Node = Undefined Then
		Filter = New Structure;
		Filter.Insert("Version", StructureVersion);
		Filter.Insert("Department", Node.Department);
		StringArray = ExpandedNodesTree.FindRows(Filter);
		For Each Item In StringArray Do
			ExpandedNodesTree.Delete(Item);
		EndDo;
		CheckChildNodes(Node.GetItems());
	EndIf;
EndProcedure

&AtClient
Procedure DepartmentTreeMainDrag(Item, DragParameters, StandardProcessing, String, Field)
	StandardProcessing = False;
	MovedDepartmentID = DragParameters.Value; //строка
	MovedTreeItem = ?(MovedDepartmentID = Undefined, Undefined, DepartmentTreeMain.FindByID(MovedDepartmentID)); //данные формы элемент дерева
	MovedDepartment = MovedTreeItem.Department;
	IDDestination = String;
	TreeItemDestination = ?(IDDestination = Undefined, Undefined, DepartmentTreeMain.FindByID(IDDestination)); //данные формы элемент дерева
	If TreeItemDestination = Undefined Then
		DepartmentDestination = PredefinedValue("Catalog.fmDepartments.EmptyRef");
	Else
		DepartmentDestination = TreeItemDestination.Department;
	EndIf;
	ParentChangeAtServer(MovedDepartment, DepartmentDestination);
	ExpandTree();
EndProcedure

&AtClient
Procedure DepartmentTreeMainBeforeRowChange(Item, Cancel)
	Cancel = True;
	ChangeCurrentDepartment(Undefined);
EndProcedure

#EndRegion


#Region CommandHandlers

&AtClient
Procedure OutputListWithoutHierarchy(Command)
	TabDoc = ListPrintServer(False);
	TabDoc.ReadOnly 		= True;
	TabDoc.ShowGrid 		= True;
	TabDoc.ShowHeaders 	= True;
	TabDoc.Show();
EndProcedure

&AtClient
Procedure OutputListWithHierarchy(Command)
	TabDoc = ListPrintServer(True);
	TabDoc.ReadOnly		= True;
	TabDoc.ShowGrid		= True;
	TabDoc.ShowHeaders	= True;
	TabDoc.Show();
	TabDoc.ShowRowGroupLevel(1);
EndProcedure

&AtClient
Procedure AddDepartment(Command)
	If Items.DepartmentTreeMain.CurrentRow = Undefined Then
		FormParameters = New Structure;
		FormParameters.Insert("Parent", PredefinedValue("Catalog.fmDepartments.EmptyRef"));
		FormParameters.Insert("StructureVersion", StructureVersion);
		OpenForm("Catalog.fmDepartments.ObjectForm", FormParameters,ThisForm,,,,,FormWindowOpeningMode.Independent);
	Else
		CurDepartmentRef = Items.DepartmentTreeMain.CurrentData.Department;
		FormParameters = New Structure;
		FormParameters.Insert("Parent", CurDepartmentRef);
		FormParameters.Insert("StructureVersion", StructureVersion);
		OpenForm("Catalog.fmDepartments.ObjectForm", FormParameters,ThisForm,,,,,FormWindowOpeningMode.Independent);
	EndIf;
EndProcedure

&AtClient
Procedure ChangeCurrentDepartment(Command)
//открывает элемент справочника подразделения для редактирования
	If NOT Items.DepartmentTreeMain.CurrentRow = Undefined Then
		CurDepartmentRef = Items.DepartmentTreeMain.CurrentData.Department;
		FormParameters = New Structure;
		FormParameters.Insert("Key", CurDepartmentRef);
		CurRow = Items.DepartmentTreeMain.CurrentRow;
		CurTreeItem = ThisForm.DepartmentTreeMain.FindByID(CurRow);
		ItemParent = CurTreeItem.GetParent();
		If NOT ItemParent = Undefined Then
			DepParent = ItemParent.Department;
		EndIf;
		
		FormParameters.Insert("Parent", DepParent); 
		FormParameters.Insert("StructureVersion", StructureVersion);
		OpenForm("Catalog.fmDepartments.ObjectForm", FormParameters,,,,,,FormWindowOpeningMode.Independent);
	EndIf;
EndProcedure

&AtClient
Procedure ChangeDepartmentsColor(Command)
	CurRow = Items.DepartmentTreeMain.CurrentRow;
	CurTreeItem = DepartmentTreeMain.FindByID(CurRow);
	If CurTreeItem = Undefined Then
		CommonClientServer.MessageToUser(NStr("en='You should select a row with a department.';ru='Необходимо выделить строку с подразделением'"));
		Return;
	EndIf;
	CurDepartment = CurTreeItem.Department;
	AddParameters = New Structure;
	Handler = New NotifyDescription("ChangeDepartmentsColor_End", ThisObject, AddParameters);
	OpenForm("Catalog.fmDepartments.Form.ChangeColorForm", New Structure("CurDepartment", CurDepartment),ThisForm,,,,Handler,FormWindowOpeningMode.Independent);
EndProcedure

&AtClient
Procedure RefreshColorPresentation(Command)
	RefreshColorOnForm(Undefined);
EndProcedure

&AtClient
Procedure FindDepartment(Command)
	CurRow = Items.DepartmentTreeMain.CurrentRow;
	PassParameters = New Structure;
	If NOT CurRow = Undefined Then
		TreeCurData = DepartmentTreeMain.FindByID(CurRow);
		ParentDepartment = TreeCurData.GetParent();
		If NOT TreeCurData = Undefined Then
			PassParameters.Insert("CurDepartment", TreeCurData.Department);
			PassParameters.Insert("CurDepartmentCode", TreeCurData.Code);
			PassParameters.Insert("CurColumn", Items.DepartmentTreeMain.CurrentItem.Name); //напр "ДеревоПодразделенийОсновноеПодразделение"
			If ParentDepartment = Undefined Then
				PassParameters.Insert("ParentDepartment", Undefined);	
			Else
				PassParameters.Insert("ParentDepartment", ParentDepartment.Department);	
			EndIf;
		EndIf;
	EndIf;
	NotifyAfterChoice = New NotifyDescription("DepartmentsSearch_End", ThisObject, New Structure);
	OpenForm("Catalog.fmDepartments.Form.DepartmentListSearchForm",PassParameters,ThisObject,,,,NotifyAfterChoice,FormWindowOpeningMode.LockOwnerWindow);
EndProcedure

&AtClient
Procedure ShowMarkerDepartments(Command)
	IncludeMarkedDepertments = NOT IncludeMarkedDepertments;
	Items.ShowMarkerDepartments.Check = IncludeMarkedDepertments;
	RebuildTreeAtServer();
	ExpandTree();
EndProcedure

&AtClient
Procedure DeleteDepartmentFromStructure(Command)
	TreeCurRow = Items.DepartmentTreeMain.CurrentRow;
	If TreeCurRow = Undefined Then
		CommonClientServer.MessageToUser(NStr("en='You should select a row with a department.';ru='Необходимо выделить строку с подразделением'"));
		Return;
	Else
		TreeAttributeItem = DepartmentTreeMain.FindByID(TreeCurRow);
		//определим, есть ли у элемента дерева пометка на удаление, в зависимости от этого будем задавать вопрос
		If TreeAttributeItem.GetParent() = Undefined Then
			Parent = PredefinedValue("Catalog.fmDepartments.EmptyRef");
		Else
			Parent = TreeAttributeItem.GetParent().Department; 
		EndIf;
		ButtonsList = New ValueList;
		ButtonsList.Add(DialogReturnCode.Yes, NStr("en='Yes';ru='Да'"));
		ButtonsList.Add(DialogReturnCode.OK, NStr("en='In all structures';ru='Во всех структурах'"));
		ButtonsList.Add(DialogReturnCode.Cancel, NStr("en='No';ru='Нет'"));
		If fmBudgeting.CurDepartmentIsMarkedOnDeletion(TreeAttributeItem.Department, Parent, StructureVersion) Then
			Check = True;
			QueryText = NStr("en='Do you want to unmark the ""Department"" for deletion?';ru='Снять с ""Подразделение"" пометку на удаление?'");
		Else
			Check = False;
			QueryText = NStr("en='Do you really want to mark the ""Department"" for deletion?';ru='Пометить ""Подразделение"" на удаление?'");
		EndIf;
		QueryText = StrReplace(QueryText, "Department" , Items.DepartmentTreeMain.CurrentData.Department); 
		AddPar = New Structure("TreeCurRow", TreeCurRow);
		AddPar.Insert("Check",Check);
		NotifyDescription = New NotifyDescription("DeleteDepartmentFromStructure_End", ThisObject, AddPar);
		ShowQueryBox(NotifyDescription, QueryText,ButtonsList);
	EndIf;
EndProcedure

&AtClient
Procedure CancelSearch(Command)
	CurData = Items.DepartmentTreeMain.CurrentData;
	Items.DepartmentTreeMain.Representation = TableRepresentation.Tree;
	RebuildTreeAtServer();
	If NOT CurData.Department = Undefined Then
		//после отмены поиска встанем в дереве на подразделение, которое было выделено в найденных
		DepartmentsIDs = GetFromTempStorage(DepartmentsIDsStorageAddress);
		StringID = DepartmentsIDs[CurData.Department];
		If NOT StringID = Undefined Then
			Items.DepartmentTreeMain.CurrentRow = StringID; // позиционирование
			//Элементы.ДеревоПодразделенийОсновное.Обновить();
		EndIf;
	EndIf;
EndProcedure

&AtClient
Procedure DeleteMarkedDepartmentsInVersion(Command)
	QueryText = NStr("en='Are you sure you want to delete all departments marked for deletion?';ru='Удалить все помеченные на удаление подразделения?'");
	NotifyDescription = New NotifyDescription("DeleteMarkedDepartmentsInVersion_End", ThisObject);
	ShowQueryBox(NotifyDescription, QueryText, QuestionDialogMode.YesNo);
EndProcedure

&AtClient
Procedure StructureVersionUpdate(Command)
	// Найдем версию, соответствующую выбраннной по таблице соответствий
	Filter = New Structure;
	Filter.Insert("Description", Command.Name);
	StringArray = ButtonsToVersionsMapTable.FindRows(Filter);
	If NOT StringArray.Count() = 0 Then
		StructureVersion = StringArray[0].Version;
	EndIf;
	//теперь производим действия выбора версии
	If StructureVersion.IsEmpty() Then
		OpenForm("Catalog.fmDepartmentsStructuresVersions.ObjectForm");
	Else
		Items.GroupCreatedVersions.ChildItems[Command.Name].Picture = PictureLib.fmOperationExecutedSuccessfully; 
		Items.SubmenuSwitchVersions.Title = StringArray[0].Presentation;
		RebuildFormItems();
	EndIf;
	ExpandTree();
EndProcedure

&AtClient
Procedure StandardListForm(Command)
	FormParameters = New Structure;
	FormParameters.Insert("StructureVersion",StructureVersion);
	OpenForm("Catalog.fmDepartments.Form.ListForm",FormParameters,,,,,,FormWindowOpeningMode.Independent);
EndProcedure

&AtClient
Procedure CopyDepartment(Command)
	CurDepartmentRef = Items.DepartmentTreeMain.CurrentData;
	FormParameters = New Structure;
	FormParameters.Insert("Description",CurDepartmentRef.Department);
	FormParameters.Insert("DepartmentType",CurDepartmentRef.DepartmentType);
	FormParameters.Insert("ManageType",CurDepartmentRef.ManageType);
	FormParameters.Insert("Responsible",CurDepartmentRef.Responsible);
	FormParameters.Insert("BalanceUnit",CurDepartmentRef.BalanceUnit);
	FormParameters.Insert("StructureVersion", StructureVersion);
	OpenForm("Catalog.fmDepartments.Form.ItemForm",FormParameters,,,,,,FormWindowOpeningMode.Independent);
EndProcedure

#EndRegion


#Region PrintProceduresAndFunctions

&AtServer
Function ListPrintServer(WithHierarchy)
	Return Catalogs.fmDepartments.PrintDepartmentList(DepartmentTreeMain, ExpandedNodesTree.Unload(), WithHierarchy);
EndFunction

#EndRegion


#Region FormEventsHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	MaxStructureVersion = fmBudgeting.ReturnDepartmentStructureActualVersion();
	StructureVersion = MaxStructureVersion;
	If MaxStructureVersion = Undefined OR MaxStructureVersion.IsEmpty() Then
		Items.NewVersionCreation.Title = Catalogs.fmDepartmentsStructuresVersions.DefaultVersion; 
	EndIf;
	RebuildFormItems();
	Items.GroupCreatedVersions.Title = String(StructureVersion);
	LanguageCode = NStr("en='en';ru='ru'");
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	Items.ShowMarkerDepartments.Check = IncludeMarkedDepertments;
	ExpandTree();
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	If EventName = "DepartmentInfoChange" Then
		//в параметре передается структура - ссылка, родитель, владелец
		RebuildTreeAtServer(,,Parameter);
	ElsIf EventName = "NewHierarchyVersionCreated" Then
		WriteRefreshNewStructureVersion(Parameter);
	EndIf;
	ExpandTree();
EndProcedure

&AtClient
//Обработчки нажатия на кнопку "Организационная структура"
//
Procedure GenerateOrgStructureReport(Command)
	
	If NOT Items.DepartmentTreeMain.CurrentRow = Undefined Then
		CurDep = Items.DepartmentTreeMain.CurrentData.Department;
	Else
		CurDep = Undefined;
	EndIf;
	OpeningParameters = New Structure;
	OpeningParameters.Insert("StructureVersion",					StructureVersion);
	OpeningParameters.Insert("Department",						CurDep);
	OpeningParameters.Insert("GenerateOnOpen",	True);
	OpenForm("Report.fmOrganizationalDepartmentsStructure.Form.ReportForm", OpeningParameters);
	
EndProcedure //СформироватьОтчетОргСтруктуры()

#EndRegion


