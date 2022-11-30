
#Region FormEventsHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	If Parameters.Property("StructureVersion") Then
		StructureVersion = Parameters.StructureVersion;
	Else
		StructureVersion = fmBudgeting.ReturnDepartmentStructureActualVersion(); //Справочники.уфВерсииСтруктурПодразделений.ПустаяСсылка();
	EndIf;
	FormUpdateVersionsButtons();
	Items.GroupCreatedVersions.Title = String(StructureVersion);
	LanguageCode = NStr("en='en';ru='ru'");
	If Parameters.Property("Key") Then
		RebuildTreeAtServer(,,Parameters.Key);
	Else
		RebuildTreeAtServer();
	EndIf;
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	Items.ShowMarkerDepartments.Check = IncludeMarkedDepertments;
	For Each Item In DepartmentTreeMain.GetItems() Do
		Items.DepartmentTreeMain.Expand(Item.GetID());
		If ValueIsFilled(CurrentRowID) Then
			Items.DepartmentTreeMain.CurrentRow = CurrentRowID;
		EndIf;
	EndDo;
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	If EventName = "DepartmentInfoChange" Then
		//в параметре передается структура - ссылка, родитель, владелец
		RebuildTreeAtServer();
	ElsIf EventName = "NewHierarchyVersionCreated" Then
		NewStructureVersionRecordProcessing(Parameter);
	EndIf;
EndProcedure


#EndRegion

#Region FormItemsEventsHandlers

&AtClient
Procedure DepartmentTreeMainChoice(Item, SelectedRow, Field, StandardProcessing)
	NotifyChoice(Item.CurrentData.Department);
EndProcedure

&AtClient
Procedure DepartmentTreeMainBeforeDeleteRow(Item, Cancel)
	Cancel = True;
	DeleteDepartmentFromStructure(Undefined);
EndProcedure

&AtClient
Procedure DepartmentTreeMainDrag(Item, DragParameters, StandardProcessing, String, Field)
	StandardProcessing = False;
	MovedDepartmentID = DragParameters.Value[0];
	MovedTreeItem = ?(MovedDepartmentID = Undefined, Undefined, DepartmentTreeMain.FindByID(MovedDepartmentID));
	MovedDepartment = MovedTreeItem.Department;
	IDDestination = String;
	TreeItemDestination = ?(IDDestination = Undefined, Undefined, DepartmentTreeMain.FindByID(IDDestination));
	If TreeItemDestination = Undefined Then
		DepartmentDestination = PredefinedValue("Catalog.fmDepartments.EmptyRef");
	Else
		DepartmentDestination = TreeItemDestination.Department;
	EndIf;
	ParentChangeAtServer(MovedDepartment, DepartmentDestination);
EndProcedure

&AtClient
Procedure DepartmentTreeMainDepartmentOpening(Item, StandardProcessing)
	TreeCurData = Items.DepartmentTreeMain.CurrentData;
	If NOT TreeCurData = Undefined Then
		StandardProcessing = False;
		SelValue = TreeCurData.Department;
		If TypeOf(SelValue) = Type("CatalogRef.fmDepartments") Then
			FormParameters = New Structure;
			FormParameters.Insert("Key", SelValue);
			//получим родителя в дереве
			ItemParent = TreeCurData.GetParent();
			If NOT ItemParent = Undefined Then
				DepParent = ItemParent.Department;
			EndIf;
			FormParameters.Insert("Parent", DepParent);
			FormParameters.Insert("StructureVersion", StructureVersion);
			OpenForm("Catalog.fmDepartments.ObjectForm", FormParameters,ThisForm,,,,,FormWindowOpeningMode.LockOwnerWindow);
		EndIf;
	EndIf;
EndProcedure

&AtClient
Procedure DepartmentTreeMainBeforeRowChange(Item, Cancel)
	Cancel = True;
	ChangeCurrentDepartment(Undefined);
EndProcedure

#EndRegion

#Region CommandHandlers

&AtClient
Procedure StandardChoiceForm(Command)
	FormParameters = New Structure;
	FormParameters.Insert("StructureVersion",StructureVersion);
	FormParameters.Insert("Key", Items.DepartmentTreeMain.CurrentData.Department);
	OpenForm("Catalog.fmDepartments.Form.ChoiceForm",FormParameters,ThisForm.FormOwner);
	ThisForm.Close();
EndProcedure

&AtClient
Procedure CopyDepartment(Command)
	CurDepartmentRef = Items.DepartmentTreeMain.CurrentData;
	FormParameters = New Structure;
	FormParameters.Insert("Description",CurDepartmentRef.Department);
	FormParameters.Insert("DepartmentType",CurDepartmentRef.DepartmentType);
	FormParameters.Insert("Responsible",CurDepartmentRef.Responsible);
	FormParameters.Insert("BalanceUnit",CurDepartmentRef.BalanceUnit);
	FormParameters.Insert("StructureVersion", StructureVersion);
	OpenForm("Catalog.fmDepartments.Form.ItemForm",FormParameters);
EndProcedure

&AtClient
Procedure AddDepartment(Command)
	If Items.DepartmentTreeMain.CurrentRow = Undefined Then
		FormParameters = New Structure;
		FormParameters.Insert("Parent", PredefinedValue("Catalog.fmDepartments.EmptyRef"));
		FormParameters.Insert("StructureVersion", StructureVersion);
		OpenForm("Catalog.fmDepartments.ObjectForm", FormParameters);
	Else
		CurDepartmentRef = Items.DepartmentTreeMain.CurrentData.Department;
		FormParameters = New Structure;
		FormParameters.Insert("Parent", CurDepartmentRef);
		FormParameters.Insert("StructureVersion", StructureVersion);
		OpenForm("Catalog.fmDepartments.ObjectForm", FormParameters);
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
		OpenForm("Catalog.fmDepartments.ObjectForm", FormParameters);
	EndIf;
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
			PassParameters.Insert("CurDepartmentCode", TreeCurData.Department.Code);
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
Procedure StructureVersionUpdate(Command)
	Filter = New Structure;
	Filter.Insert("Description", Command.Name);
	StringArray = ButtonsToVersionsMapTable.FindRows(Filter);
	If NOT StringArray.Count() = 0 Then
		StructureVersion = StringArray[0].Version;
	EndIf;
	If StructureVersion.IsEmpty() Then
		OpenForm("Catalog.fmDepartmentsStructuresVersions.ObjectForm");
	Else
		Items.GroupCreatedVersions.ChildItems[Command.Name].Picture = PictureLib.fmOperationExecutedSuccessfully; 
		Items.GroupCreatedVersions.ChildItems.Find(Command.Name).Picture = PictureLib.fmOperationExecutedSuccessfully;
		Items.SubmenuSwitchVersions.Title = StringArray[0].Presentation;
		RebuildFormItems();
	EndIf;
EndProcedure

&AtClient
Procedure RefreshColorPresentation(Command)
	RebuildTreeAtServer();
EndProcedure

&AtClient
Procedure ShowMarkerDepartments(Command)
	IncludeMarkedDepertments = NOT IncludeMarkedDepertments;
	Items.ShowMarkerDepartments.Check = IncludeMarkedDepertments;
	RebuildTreeAtServer();
EndProcedure

&AtClient
Procedure DeleteDepartmentFromStructure(Command)
	TreeCurRow = Items.DepartmentTreeMain.CurrentRow;
	If TreeCurRow = Undefined Then
		CommonClientServer.MessageToUser(NStr("en='You should select a deletable department.';ru='Необходимо выбрать удаляемое подразделение'"));
	Else
		TreeAttributeItem = DepartmentTreeMain.FindByID(TreeCurRow);
		If TreeAttributeItem = Undefined Then
			Return;
		EndIf;
		If TreeAttributeItem.GetParent() = Undefined Then
			Parent = PredefinedValue("Catalog.fmDepartments.EmptyRef");
		Else
			Parent = TreeAttributeItem.GetParent().Department; 
		EndIf;
		ButtonsList = New ValueList;
		ButtonsList.Add(DialogReturnCode.Yes, NStr("en='Yes';ru='Да'"));
		ButtonsList.Add(DialogReturnCode.Cancel, NStr("en='No';ru='Нет'"));
		If fmBudgeting.CurDepartmentIsMarkedOnDeletion(TreeAttributeItem.Department, Parent, StructureVersion) Then
			Check = True;
			QueryText = NStr("en='Do you want to unmark the ""Department"" for deletion?';ru='Снять с ""Подразделение"" пометку на удаление?'");
			QueryText = StrReplace(QueryText, "Department" , Items.DepartmentTreeMain.CurrentData.Department); 
			AddPar = New Structure("TreeCurRow", TreeCurRow);
			AddPar.Insert("Check",Check);
			NotifyDescription = New NotifyDescription("DeleteDepartmentFormStructureAdd_End", ThisObject, AddPar);
			ShowQueryBox(NotifyDescription, QueryText,ButtonsList);
		Else
			Check = False;
			QueryText = NStr("en='Do you really want to mark the ""Department"" for deletion?';ru='Пометить ""Подразделение"" на удаление?'");
			QueryText = StrReplace(QueryText, "Department" , Items.DepartmentTreeMain.CurrentData.Department); 
			AddPar = New Structure("TreeCurRow", TreeCurRow);
			AddPar.Insert("Check",Check);
			NotifyDescription = New NotifyDescription("DeleteDepartmentFormStructureAdd_End", ThisObject, AddPar);
			ShowQueryBox(NotifyDescription, QueryText,ButtonsList);
		EndIf;
	EndIf;
EndProcedure

&AtClient
Procedure ChooseDepartment(Command)
	CurItem = CurrentItem.CurrentData.Department;
	If ValueIsFilled(CurItem) Then
		NotifyChoice(CurItem);
	Else
		Return;
	EndIf;
EndProcedure

#EndRegion

#Region ProceduresAndFunctionsOfCommonUse

&AtServer
Procedure RebuildFormItems()
	RebuildTreeAtServer();
	FormUpdateVersionsButtons();
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
Procedure RebuildTreeAtServer(AccordingSearch = False, StrSearchParam = Undefined, Key =Undefined)
	DepartmentTreeMain.GetItems().Clear();
	If NOT StructureVersion.IsEmpty() Then
		DATE = StructureVersion.DateValidUntil;
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
	DepartmentTreeMainVT = fmBudgeting.DepartmentCommonTree(StrParameters);//,, ВидИерархии,,,,, ВерсияСтруктуры, Ложь, Дата, Истина);
	DepartmentsIDs = New Map;
	BuildDepartmentTreeMain(DepartmentTreeMain, DepartmentTreeMainVT, DepartmentsIDs,Key);
	DepartmentsIDsStorageAddress = PutToTempStorage(DepartmentsIDs, New UUID);
	//очистим условное оформление и заново раскрасим подразделения
	ConditionalAppearance.Items.Clear();
	Catalogs.fmDepartments.ColorTreeItems(ConditionalAppearance, "DepartmentTreeMain", "DepartmentTreeMain.DepartmentType", "DepartmentTreeMain.Department");
EndProcedure

&AtServer
Procedure BuildDepartmentTreeMain(TreeOnForm, TreeVT, DepartmentsIDs,Key = Undefined)
	For Each Item In TreeVT.Rows Do
		RowDestination = TreeOnForm.GetItems().Add();
		RowDestination.Department				= Item.Department;
		RowDestination.DepartmentType			= Item.DepartmentType;
		IDOfRow = RowDestination.GetID();
		DepartmentsIDs.Insert(RowDestination.Department, IDOfRow);
		BuildDepartmentTreeMain(RowDestination, Item, DepartmentsIDs ,Key);
		If Item.Department = Key Then
			CurrentRowID = RowDestination.GetID();
		EndIf;
	EndDo;
EndProcedure

&AtClient
Procedure DeleteDepartmentFormStructureAdd_End(UserReturnCode, Parameter) Export
	TreeCurRow = Parameter.TreeCurRow;
	If UserReturnCode = DialogReturnCode.Yes Then
		DeleteDepartmentFromStructureServer(TreeCurRow, Parameter.Check);
	EndIf;
	ExpandTree();
EndProcedure

&AtServer
Procedure DeleteDepartmentFromStructureServer(TreeCurRow, UnmarkOnDeletion)
	StructureMaximumVersion = fmBudgeting.ReturnDepartmentStructureActualVersion();
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
			If NOT UnmarkOnDeletion Then
				DeletedDepartment.DeletionMark = True;
			Else
				DeletedDepartment.DeletionMark = False;
			EndIf;
			DeletedDepartment.Write();
		EndDo;
	RebuildTreeAtServer();
EndProcedure

&AtServer
Procedure FormUpdateVersionsButtons()
	//предыдущей версией таблицы соответствий кнопок воспользуемся чтобы кнопки удалить, 
	For Each MapString In ButtonsToVersionsMapTable Do
		DeletedButton = ThisForm.Items.Find(MapString.Description);
		If NOT DeletedButton = Undefined Then
			ThisForm.Items.Delete(DeletedButton);
		EndIf;
		CachedItem = Items.SubmenuSwitchVersions.ChildItems.Find(MapString.Description);
		If NOT CachedItem = Undefined Then
			ThisForm.Items.Delete(CachedItem);
		EndIf;
		DeletedCommand = ThisForm.Commands.Find(MapString.Description);
		If NOT DeletedCommand = Undefined Then
			ThisForm.Commands.Delete(DeletedCommand);
		EndIf;
	EndDo;
	//затем почистим ее и создадим заново
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
	//ТаблицаСоответствияКнопокВерсиям.Очистить();
	For Each Item In VTExisting Do
		// Заполним таблицу кнопок
		ButtonsTableNewRow = ButtonsTable.Add();
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
		MapTableNewRow 					= ButtonsToVersionsMapTable.Add();
		MapTableNewRow.Description 	= ButtonsTableNewRow.ButtonName;
		MapTableNewRow.Version	 		= Item.Ref;
		MapTableNewRow.Presentation 	= Item.Description;
	EndDo;
	//также добавим кнопку создания новой структуры
	ButtonsTableNewRow = ButtonsTable.Add();
	ButtonsTableNewRow.ButtonName 		= "CreateNew";   //уберем запрещенные для имен кнопок символы
	ButtonsTableNewRow.Presentation 	= NStr("en='Create new';ru='Создать новую'");
	ButtonsTableNewRow.Selected 	= False;
	MapTableNewRow 					= ButtonsToVersionsMapTable.Add();
	MapTableNewRow.Description 	= ButtonsTableNewRow.ButtonName;
	MapTableNewRow.Version	 		= Catalogs.fmDepartmentsStructuresVersions.EmptyRef();
	MapTableNewRow.Presentation 	= NStr("en='Create new';ru='Создать новую'");
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
Procedure NewStructureVersionRecordProcessing(ParametersStructure)
	
	//после записи структуры нам нужно создать полную копию самой актуальной версии в РС Иерархия подразделений
	//1. определим самую актуальную версию
	NewVersionRef = ParametersStructure.NewVersionRef;
	VersionsToExcludeArray = New Array;
	VersionsToExcludeArray.Add(NewVersionRef);
	MaxStructureVersion = fmBudgeting.ReturnDepartmentStructureActualVersion(,, VersionsToExcludeArray);//ВернутьМаксимальнуюВерсию();
	
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
	
	//в шапке заменим выбранное значение версии
	StructureVersion = NewVersionRef;
	RebuildTreeAtServer();
EndProcedure

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

#EndRegion

