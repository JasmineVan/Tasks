
#Region FormEventsHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	SavedStructureType = Object.StructureType;
	If ValueIsFilled(Parameters.CopyingValue) Then
		CopiedInfoStructure = Parameters.CopyingValue;
	Else
		CopiedInfoStructure = Catalogs.fmInfoStructures.EmptyRef();
	EndIf;
	ClearFillingTreeAtServer();
	//сначала заполняем дерево справа, чтобы могли из левого убрать дублирующие элементы
	FillPresentationTree();
	FillSourcesItemsTree();
	RefreshConditionalAppearance();
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	ChageOperationTypeChoiceList();
EndProcedure

&AtClient
Procedure BeforeWrite(Cancel, RecordParameters)
	ExpandedNodesList.Clear();
	SaveExpandedNodesList(StructurePresentationTree.GetItems());
	ErrorString = CheckOnFillingErrors();
	If NOT ErrorString = Undefined Then
		CommonClientServer.MessageToUser(StrTemplate(NStr("en='It is impossible to save the document. In the structure, there is a repeating item - <%1>';ru='Запись невозможна. В структуре повторяющаяся статья - <%1>'"), String(ErrorString)),,,, Cancel);
	EndIf;
	If NOT fmBudgeting.ViewAndInputAllowedCombination(Object.EditFormat, Object.ViewFormat) Then
		CommonClientServer.MessageToUser(NStr("en='The editing format cannot be larger than the display format.';ru='Формат редактирования не может быть больше, чем формат отображения!'"), , "Object.EditFormat", , Cancel);
		Object.ViewFormat = Object.EditFormat;
	EndIf;
EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, RecordParameters)
	CopyStructuresTreeInCatalog();
	RefreshConditionalAppearance();
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	If EventName = "ItemChoiceFromCatalog" Then
		If TypeOf(Parameter) = Type("Structure") Then
			If Parameter.Property("ChoiceValue") Then
				
				ChoiceValue = Parameter.ChoiceValue;
				CurRow = Items.StructurePresentationTree.CurrentRow;
				TreeCurData = StructurePresentationTree.FindByID(CurRow);
				TreeCurData.Analytics = Parameter.ChoiceValue;
				If TypeOf(ChoiceValue) = Type("CatalogRef.fmIncomesAndExpensesItems")
					OR TypeOf(ChoiceValue) = Type("CatalogRef.fmCashflowItems") Then
					//ТипыАналитик = уфБюджетирование.ПолучитьТипыАналитик(ЗначениеВыбора);
					If NOT Items.StructurePresentationTree.CurrentData.IsFormulaItem Then //проверка при добавлении в формульный элемент не нужна
						If ItemIsInStructureTree(ChoiceValue) Then
							CommonClientServer.MessageToUser(NStr("en='This item is already in the structure.';ru='Эта статья уже присутствует в структуре!'"));
							Return;
						EndIf;
					EndIf;
					//Если ТипЗнч(ЗначениеВыбора) = Тип("СправочникСсылка.уфСтатьиДоходовИРасходов") Тогда 
					//	ДДС = Ложь;
					//ИначеЕсли ТипЗнч(ЗначениеВыбора) = Тип("СправочникСсылка.уфСтатьиДвиженияДенежныхСредств") Тогда
					//	ДДС = Истина;
					//КонецЕсли;
					AnalyticsTypes = fmBudgeting.GetCustomAnalyticsSettings(ChoiceValue);
					TreeCurData.AnalyticsType1 = AnalyticsTypes.AnalyticsType1;
					TreeCurData.AnalyticsType2 = AnalyticsTypes.AnalyticsType2;
					TreeCurData.AnalyticsType3 = AnalyticsTypes.AnalyticsType3;
					If ValueIsFilled(AnalyticsTypes.AnalyticsType1) Then
						Items.AddItem.Enabled = True;
					EndIf;
				Else
					Items.StructurePresentationTree.CurrentItem.TypeRestriction = New TypeDescription(Items.StructurePresentationTree.CurrentItem.TypeRestriction,"String");
					GetParentInLoop(TreeCurData.GetParent(),1);
				EndIf;
				TreeCurData.Group = Parameter.ChoiceValue;
				TreeCurData.GroupParent = TreeCurData.GetParent().Group;
				TreeCurData.Ref = Parameter.ChoiceValue;
				TreeCurData.ItemCode = ReturnItemCode(Parameter.ChoiceValue);
				If TreeCurData.IsFormulaItem Then
					TreeCurData.FormulaString = Parameter.ChoiceValue;
				EndIf;
				MaxNumberBO = DefineMaximunmNumberBO(TreeCurData.GetParent().GetItems());//ДеревоПредставленияСтруктуры.ПолучитьЭлементы());
				TreeCurData.Order = MaxNumberBO + 1;
				AddChangedOrDeletedItemsInList();
			EndIf;
		EndIf;
	EndIf;
	RefreshTreeFillingOfFillingItems();
EndProcedure

&AtClient
Procedure ChoiceProcessing(ChosenValue, ChoiceSource)
	//Вставить содержимое обработчика
	If TypeOf(ChosenValue) = Type("CatalogRef.fmIncomesAndExpensesItems") OR TypeOf(ChosenValue) = Type("CatalogRef.fmCashflowItems") Then
		DeletedItem = Items.StructurePresentationTree.CurrentData.GetItems();
		If DeletedItem.Count() > 0 Then
			DeletedItem.Delete(0);
		EndIf;
	EndIf;
EndProcedure

#EndRegion

#Region FormItemsEventsHandlers

&AtClient
Procedure StructurePresentationTreeGroupStartChoice(Item, ChoiceData, StandardProcessing)
	Item.DropListButton = True;
	Item.TypeRestriction = New TypeDescription(Item.TypeRestriction,,"String");
EndProcedure

&AtClient
Procedure MovementOperationTypeOnChange(Item)
	// Вставить содержимое обработчика.
	Parent = Items.StructurePresentationTree.CurrentData.GetParent();
	If Parent = Undefined Then
		QueryText = NStr("en='The operation type will be changed for the entire branch. Do you want to continue?';ru='Изменение вида операции будет произведено для всей ветки. Продолжить?'");
		ShowQueryBox(New NotifyDescription("MovementOperationTypeOnChangeEnd", ThisObject), QueryText, QuestionDialogMode.YesNo);
	Else
		CommonClientServer.MessageToUser(NStr("en='You cannot change the operation type of subordinate sections';ru='Запрещено менять вид операции у подчиненных разделов'"));
		MovementOperationType = Items.StructurePresentationTree.CurrentData.StructureSectionType;
		Return;
	EndIf;
EndProcedure

&AtClient
Procedure StructurePresentationTreeGroupChoiceProcessing(Item, ChosenValue, StandardProcessing)
	PassedParameter = New Structure;
	PassedParameter.Insert("ChoiceValue", ChosenValue);
	NotificationProcessing("ItemChoiceFromCatalog", PassedParameter, Undefined);
EndProcedure

&AtClient
Procedure StructurePresentationTreeGroupOpening(Item, StandardProcessing)
	StandardProcessing = False;
	ShowValue(,CurrentItem.CurrentData.Analytics);
EndProcedure

&AtClient
Procedure SwitchStructureTypeOnChange(Item)
	QueryText = NStr("en='Changing the structure type will clear the entire structure tree. Do you want to continue?';ru='Изменение типа структуры приведет к очистке дерева структур. Продолжить?'");
	ShowQueryBox(New NotifyDescription("SwitchStructureTypeOnChangeEnd", ThisObject), QueryText, QuestionDialogMode.YesNo);
EndProcedure

&AtClient
Procedure GroupColorOnChange(Item)
	ChangeAppearanceItemClient(,,True);
	AddChangedOrDeletedItemsInList(,,False);
EndProcedure

&AtClient
Procedure FillingItemsTreeSelection(Item, SelectedRow, Field, StandardProcessing)
	//при двойном щелчке открываем элемент справочника
	TreeCurData = FillingItemsTree.FindByID(SelectedRow);
	If NOT TreeCurData = Undefined Then
		SelValue = TreeCurData.Group;
		If TypeOf(SelValue) = Type("CatalogRef.fmIncomesAndExpensesItems") OR TypeOf(SelValue) = Type("CatalogRef.fmItemGroups") OR TypeOf(SelValue) = Type("CatalogRef.fmCashflowItems") Then
			ShowValue(, SelValue);
		EndIf;
	EndIf;
EndProcedure

&AtClient
Procedure StructurePresentationTreeAfterDeleteRow(Item)
	RefreshTreeFillingOfFillingItems();
	ThisForm.Modified = True;
EndProcedure

&AtClient
Procedure StructurePresentationTreeBeforeDeleteRow(Item, Cancel)
	Cancel = True;
	DeleteCurrentItemInStructure();
EndProcedure

&AtClient
Procedure StructurePresentationTreeOnChange(Item)
	AddChangedOrDeletedItemsInList();
	ThisForm.Modified = True;
EndProcedure

&AtClient
Procedure StructurePresentationTreeBeforeAddRow(Item, Cancel, Copy, Parent, Group)
	CurRow = Items.StructurePresentationTree.CurrentData;
	If (CurRow = Undefined) 
		OR (CurRow.IsFormulaItem AND NOT CurRow.GroupType = New TypeDescription("String"))
		OR NOT Items.AddStructureSection.Enabled Then
			Cancel = True;
			Return;
	EndIf;
EndProcedure

&AtClient
Procedure StructurePresentationTreeSelection(Item, SelectedRow, Field, StandardProcessing)
	CurRow = StructurePresentationTree.FindByID(SelectedRow);
	Parent = CurRow.GetParent();
	If NOT (Parent = Undefined) Then
		If Parent.GroupType = New TypeDescription("CatalogRef.fmItemGroups") OR CurRow.GroupType = New TypeDescription("CatalogRef.fmItemGroups") Then
			StandardProcessing = False;
			ShowValue(,CurRow.Analytics);
		Else
			SetAvailabilityOfGroupFieldButton(SelectedRow);
		EndIf;
	Else
		SetAvailabilityOfGroupFieldButton(SelectedRow);
	EndIf;
EndProcedure

&AtClient
Procedure StructurePresentationTreeOnActivateRow(Item)
	//подхватим цвет и обновим элемент на форме
	CurRow = Item.CurrentData;
	If ValueIsFilled(CurRow.StructureSectionType) Then
		MovementOperationType = CurRow.StructureSectionType;
	Else
		Items.MovementOperationType.Enabled = False;
		MovementOperationType = Undefined;
	EndIf;
	Child = CurRow.GetItems();
	Current = Item.CurrentRow;
	Parent = CurRow.GetParent();
	If CurRow = Undefined Then
		Return;
	EndIf;
	If Parent = Undefined Then
		Items.MovementOperationType.Enabled = True;
	Else
		Items.MovementOperationType.Enabled = False;
	EndIf;
	Items.DeleteStructureItem.Enabled = True;
	Items.MoveUp.Enabled = True;
	Items.MoveDown.Enabled = True;
	If (CurRow.GroupType = New TypeDescription("CatalogRef.fmInfoStructuresSections")) AND NOT CurRow.IsFormulaItem Then
		GroupColor = GetColorFromCatalog(CurRow.TextColor);
		//перепишем покнопочно, т.к. при изменении доступности целиком командной панели, неявно шло обращение к серверу
		Items.MakeBold.Enabled = True;
		Items.MakeItalic.Enabled = True;
		Items.MakeBold.Check = CurRow.BoldFont;
		Items.MakeItalic.Check = CurRow.ItalicFont;
		Items.AddStructureSection.Enabled = True;
		Items.GroupColor.Enabled = True;
		//если не типизированный конечно
		If NOT CurRow.FixedSection OR NOT CurRow.GroupParent = "" AND NOT Object.StructureType = PredefinedValue("Enum.fmInfoStructureTypes.IncomesAndExpensesBudget") AND NOT Object.StructureType = PredefinedValue("Enum.fmInfoStructureTypes.CashflowBudget") Then
			Items.AddItem.Enabled = True;
		Else
			Items.AddItem.Enabled = False;
		EndIf;
		If Item.CurrentItem <> Undefined Then
			Item.CurrentItem.TypeRestriction = New TypeDescription("String");
		EndIf;
		Items.AddSubsection.Enabled = True;
	ElsIf (CurRow.GroupType = New TypeDescription("CatalogRef.fmInfoStructuresSections")
	OR CurRow.GroupType = New TypeDescription("CatalogRef.fmIncomesAndExpensesItems")
	OR CurRow.GroupType = New TypeDescription("CatalogRef.fmCashflowItems")) AND CurRow.IsFormulaItem Then //элементы формульной ТЧ
		Items.MakeBold.Enabled = False;
		Items.MakeItalic.Enabled = False;
		Items.AddItem.Enabled = False;
		Items.DeleteStructureItem.Enabled = True;
		Items.MoveUp.Enabled = False;
		Items.MoveDown.Enabled = False;
	ElsIf CurRow.GroupType = New TypeDescription("String") AND CurRow.IsFormulaItem Then    //стоим на "+" или "-"
		Items.MakeBold.Enabled = False;
		Items.MakeItalic.Enabled = False;
		Items.AddItem.Enabled = True;
		Items.DeleteStructureItem.Enabled = False;
		Items.MoveUp.Enabled = False;
		Items.MoveDown.Enabled = False;
	ElsIf CurRow.GroupType = New TypeDescription("CatalogRef.fmIncomesAndExpensesItems")
	OR CurRow.GroupType = New TypeDescription("CatalogRef.fmCashflowItems")
	OR CurRow.GroupType = New TypeDescription("CatalogRef.fmItemGroups") Then
		//Переопределим тип элемента.
		If CurRow.GroupType = New TypeDescription("CatalogRef.fmCashflowItems") Then
			Item.CurrentItem.TypeRestriction = New TypeDescription("CatalogRef.fmCashflowItems");
		ElsIf CurRow.GroupType = New TypeDescription("CatalogRef.fmIncomesAndExpensesItems") Then
			Item.CurrentItem.TypeRestriction = New TypeDescription("CatalogRef.fmIncomesAndExpensesItems");
		EndIf;
		If ValueIsFilled(CurRow.GroupParent) Then
			ItemParent = Items.StructurePresentationTree.CurrentData.GetParent();
		EndIf;
		If NOT ValueIsFilled(CurRow.AnalyticsType1) Then //РодительСтатьи.ТипГруппировки = Новый ОписаниеТипов("СправочникСсылка.уфГруппыСтатей") ИЛИ 
			Items.AddItem.Enabled = False;
		Else
			Items.AddItem.Enabled = True;
		EndIf;
		Items.MakeBold.Enabled = False;
		Items.MakeItalic.Enabled = False;
		Items.DeleteStructureItem.Enabled = True;
		Items.GroupColor.Enabled = False;
		Items.AddStructureSection.Enabled = True;
		Items.AddSubsection.Enabled = False;
	ElsIf NOT ValueIsFilled(CurRow.GroupType) AND ValueIsFilled(Parent.Analytics) Then
		If TypeOf(CurRow.Analytics) <> Type("CatalogRef.fmIncomesAndExpensesItems") AND TypeOf(CurRow.Analytics) <> Type("CatalogRef.fmCashflowItems") Then
			GetParentInLoop(Parent, 1);
			Items.AddSubsection.Enabled = False;
		EndIf;
		Items.MakeBold.Enabled = False;
		Items.MakeItalic.Enabled = False;
		Items.GroupColor.Enabled = False;
	EndIf;
	SetAvailabilityOfGroupFieldButton(Current);
EndProcedure

&AtClient
Procedure StructurePresentationTreeDragCheck(Item, DragParameters, StandardProcessing, String, Field)
	StandardProcessing = False;
	CancelAction = False;
	If String = Undefined Then
		DragParameters.Action = DragAction.Cancel;
		Return;
	EndIf;
	If TypeOf(DragParameters.Value[0]) <> Type("Number") Then
		For Each SourceRow In DragParameters.Value Do
			Source = SourceRow;
			//для Внешнийового отчета есть отдельный случай добавления вне группировки
			Receiver = ThisForm.StructurePresentationTree.FindByID(String);
			If Receiver.GroupType = New TypeDescription("CatalogRef.fmInfoStructuresSections") AND Receiver.IsFormulaItem
				AND NOT (TypeOf(Source.Group) = Type("CatalogRef.fmItemGroups") OR TypeOf(Source.Group) = Type("EnumRef.fmBudgetFlowOperationTypes")) Then
				//когда перемещаем на уровень формульной ТЧ, то добавляем в родителя, т.е. в + или -
				Receiver = Receiver.GetParent();
			ElsIf (TypeOf(Receiver.Group) = Type("CatalogRef.fmIncomesAndExpensesItems") OR TypeOf(Receiver.Group) = Type("CatalogRef.fmCashflowItems")) AND NOT Receiver.IsFormulaItem Then
				//перемещаем в родителя
				Receiver = Receiver.GetParent();
				If TypeOf(Receiver.Group) = Type("CatalogRef.fmItemGroups") Then
					CancelAction = True;
				EndIf;
				//можно
			ElsIf TypeOf(Receiver.Group) = Type("CatalogRef.fmItemGroups") Then
				//перемещаем в родителя
				Receiver = Receiver.GetParent();
			ElsIf Receiver.FixedSection AND TypeOf(Source.Group) = Type("EnumRef.fmBudgetFlowOperationTypes") Then
				//можно
			EndIf;
		EndDo;
	Else
		For Each SourceRow In DragParameters.Value Do
			Source = ThisForm.StructurePresentationTree.FindByID(SourceRow);
			//для Внешнийового отчета есть отдельный случай добавления вне группировки
			Receiver = ThisForm.StructurePresentationTree.FindByID(String);
			If TypeOf(Source.Group) = Type("CatalogRef.fmIncomesAndExpensesItems")
				OR TypeOf(Source.Group) = Type("CatalogRef.fmCashflowItems")
				OR TypeOf(Source.Group) = Type("CatalogRef.fmItemGroups")
				OR Source.GroupType = New TypeDescription("CatalogRef.fmInfoStructuresSections") Then
				If Source.IsFormulaItem AND NOT Receiver.IsFormulaItem Then
					//выносить обратно в структуру из формульной тч нельзя
					CancelAction = True;
				EndIf;
				If Receiver.IsFormulaItem Then
					CancelAction = True;
				EndIf;
				If Receiver.IsFormulaItem AND TypeOf(Source.Group) = Type("CatalogRef.fmItemGroups") Then
					CancelAction = True;
				EndIf;
				//если в типе бюджет ДиР хотим перетащить эл-т ДОХОДЫ или РАСХОДЫ, запретим это
				If (Object.StructureType = PredefinedValue("Enum.fmInfoStructureTypes.IncomesAndExpensesBudget") OR Object.StructureType = PredefinedValue("Enum.fmInfoStructureTypes.CashflowBudget")) AND Source.GroupType = New TypeDescription("CatalogRef.fmInfoStructuresSections") AND NOT Source.IsFormulaItem AND Source.GroupParent = "" AND Source.GetParent() = Undefined Then
					CancelAction = True;
				EndIf;
				If Receiver.GroupType = New TypeDescription("CatalogRef.fmInfoStructuresSections") AND NOT Receiver.IsFormulaItem Then
					//перемещаем в эту группировку только если она не типизированная
					If Receiver.ByFormula AND Object.StructureType <> PredefinedValue("Enum.fmInfoStructureTypes.IncomesAndExpensesBudget") AND Object.StructureType <> PredefinedValue("Enum.fmInfoStructureTypes.CashflowBudget") Then
						CancelAction = True;
					EndIf;
				ElsIf Receiver.GroupType = New TypeDescription("CatalogRef.fmInfoStructuresSections") AND Receiver.IsFormulaItem Then
					Receiver = Receiver.GetParent();
				ElsIf TypeOf(Receiver.Group) = Type("CatalogRef.fmIncomesAndExpensesItems") OR TypeOf(Receiver.Group) = Type("CatalogRef.fmCashflowItems") OR TypeOf(Receiver.Group) = Type("CatalogRef.fmItemGroups") Then
					//перемещаем в родителя
					Receiver = Receiver.GetParent();
					If TypeOf(Receiver.Group) = Type("CatalogRef.fmItemGroups") Then
						CancelAction = True;
					EndIf;
				ElsIf  Receiver.FixedSection AND Source.GroupType = New TypeDescription("CatalogRef.fmInfoStructuresSections") Then
					//можно
				ElsIf Receiver.IsFormulaItem AND Receiver.GroupType = New TypeDescription("String") Then
					//добавлять в "+" или "-" можно
				Else
					CancelAction = True;
				EndIf;
			Else
				CancelAction = True;
			EndIf;
		EndDo;
	EndIf;
	If CancelAction Then
		DragParameters.Action = DragAction.Cancel;
	Else
		DragParameters.Action = DragAction.Copy;
	EndIf;
EndProcedure

&AtClient
Procedure StructurePresentationTreeDrag(Item, DragParameters, StandardProcessing, String, Field)
	ThisForm.Modified = True;
	ThisForm.CurrentItem = Items.StructurePresentationTree;
	If TypeOf(DragParameters.Value[0]) <> Type("Number") Then
		StandardProcessing = False;
		AttributeSourceTree = ThisForm["FillingItemsTree"];
		AttributeTree = ThisForm["StructurePresentationTree"];
		IDDestination = String;
		Receiver = ?(IDDestination = Undefined, Undefined, AttributeTree.FindByID(IDDestination)); //данные формы элемент дерева
		ArrayIDSource = DragParameters.Value;
		For Each IDSource In ArrayIDSource Do 
			//поскольку множественный выбора убрали, этот цикл сработает лишь 1 раз
			If IDSource.IsFolder Then
				CommonClientServer.MessageToUser(NStr("en='It is forbidden to move group of elements';ru='Запрещено перемещать группы элементов'"));
				Return;
			EndIf;
			Source = IDSource; 
			If NOT Receiver = Undefined Then
				If Receiver.FixedSection AND (TypeOf(Source.Group) = Type("CatalogRef.fmIncomesAndExpensesItems") OR TypeOf(Source.Group) = Type("CatalogRef.fmItemGroups") OR TypeOf(Source.Group) = Type("CatalogRef.fmCashflowItems")) Then
					CommonClientServer.MessageToUser(NStr("en='The items can be moved only to structure items.';ru='Статьи можно перемещать только в элементы структуры!'"));
					Continue;
				EndIf;
			Else
				If TypeOf(Source.Group) = Type("CatalogRef.fmIncomesAndExpensesItems") OR TypeOf(Source.Group) = Type("CatalogRef.fmItemGroups") OR TypeOf(Source.Group) = Type("CatalogRef.fmCashflowItems") Then
					CommonClientServer.MessageToUser(NStr("ru = 'Статьи нельзя перемещать на уровень корневых элементов!'; en = 'Items can't be moved on the level of root groups!'"));
					Continue;
				EndIf;
			EndIf;
			If NOT Receiver = Undefined Then
				DestinationParent = Receiver;
				If Object.StructureType = PredefinedValue("Enum.fmInfoStructureTypes.IncomesAndExpensesBudget") OR Object.StructureType = PredefinedValue("Enum.fmInfoStructureTypes.CashflowBudget") Then
					While NOT (DestinationParent.GroupParent = "" AND DestinationParent.GroupType = New TypeDescription("CatalogRef.fmInfoStructuresSections")) Do
						DestinationParent = DestinationParent.GetParent();
					EndDo;
				Else
					While NOT DestinationParent.FixedSection Do
						DestinationParent = DestinationParent.GetParent();
					EndDo;
				EndIf;
				If DestinationParent.StructureSectionType = PredefinedValue("Enum.fmBudgetFlowOperationTypes.Incomes")
				OR DestinationParent.StructureSectionType = PredefinedValue("Enum.fmBudgetFlowOperationTypes.Inflow") Then
					IncomesAndExpenses = 0;
				Else
					IncomesAndExpenses = 1;
				EndIf;
				FirstParent = ?(Receiver.GetParent() = Undefined, Undefined, Receiver.GetParent().Group);
				DestinationRow = Receiver;
				If Receiver.IsFormulaItem AND NOT Receiver.GroupType = New TypeDescription("String") Then
					DestinationRow = Receiver.GetParent();
				EndIf;
				ExecuteRowInStructureTransfer(Source,Source.Group, DestinationRow, IncomesAndExpenses);
			EndIf;
		EndDo;
	Else
		StandardProcessing = False;
		ArrayIDSource = DragParameters.Value;
		For Each IDSource In ArrayIDSource Do 
			Source = ThisForm.StructurePresentationTree.FindByID(IDSource);//ПараметрыПеретаскивания.Значение);
			Receiver = ThisForm.StructurePresentationTree.FindByID(String);
			If NOT Receiver = Undefined Then
				IsTransferAvailable = CheckTransferAvailable(Source, Receiver);
				If NOT IsTransferAvailable Then
					Return;
				EndIf;
				//еще пару проверок на типы источников и приемников
				If Source.GroupType = New TypeDescription("CatalogRef.fmIncomesAndExpensesItems")
					OR Source.GroupType = New TypeDescription("CatalogRef.fmItemGroups")
					OR Source.GroupType = New TypeDescription("CatalogRef.fmInfoStructuresSections")
					OR Source.GroupType = New TypeDescription("CatalogRef.fmCashflowItems")Then
					If Receiver.GroupType = New TypeDescription("CatalogRef.fmInfoStructuresSections") AND NOT Receiver.IsFormulaItem Then
						//перемещаем в эту группировку только если она не типизированная
						DestinationRow = Receiver;
						NewR = TransferTreeBranchInStructure(ThisForm.StructurePresentationTree, DestinationRow, Source);
					ElsIf Receiver.GroupType = New TypeDescription("CatalogRef.fmIncomesAndExpensesItems") OR Receiver.GroupType = New TypeDescription("CatalogRef.fmItemGroups") OR Receiver.GroupType = New TypeDescription("CatalogRef.fmCashflowItems")Then
						If Receiver.IsFormulaItem Then
							//копируем в формульную строку-родителя
							Receiver = Receiver.GetParent();
							NewR = CopyTreeBranchInStructureInFormula(ThisForm.StructurePresentationTree, Receiver, Source, Source.IsFormulaItem);
						Else
							//перемещаем в родителя
							Receiver = Receiver.GetParent();
							NewR = TransferTreeBranchInStructure(ThisForm.StructurePresentationTree, Receiver, Source);
						EndIf;
					ElsIf Receiver.FixedSection AND Source.GroupType = New TypeDescription("CatalogRef.fmInfoStructuresSections") Then
						NewR = TransferTreeBranchInStructure(ThisForm.StructurePresentationTree, Receiver, Source);
					ElsIf Receiver.IsFormulaItem Then
						If NOT Receiver.GroupType = New TypeDescription("String") Then
							Receiver = Receiver.GetParent();
						EndIf;
						NewR = CopyTreeBranchInStructureInFormula(ThisForm.StructurePresentationTree, Receiver, Source, Source.IsFormulaItem);
					EndIf;
				Else
					Return;
				EndIf;
			EndIf;
		EndDo;
		If NOT NewR = Undefined Then
			Items.StructurePresentationTree.CurrentRow = NewR.GetID();
		EndIf;
	EndIf;
EndProcedure

&AtClient
Procedure StructurePresentationTreeGroupTextEditEnd(Item, Text, ChoiceData, StandardProcessing)
	ThisForm.Modified = True;
	CurData = Items.StructurePresentationTree.CurrentData;
	If CurData.GroupType = New TypeDescription("CatalogRef.fmIncomesAndExpensesItems") OR CurData.GroupType = New TypeDescription("CatalogRef.fmCashflowItems") OR NOT ValueIsFilled(CurData.GroupType) Then
		Return
	EndIf;
	CurData.GroupType = New TypeDescription("CatalogRef.fmInfoStructuresSections");
	CurRow = Items.StructurePresentationTree.CurrentRow;
	CurTreeItem = ThisForm.StructurePresentationTree.FindByID(CurRow);
	ItemParent = CurTreeItem;
	CurrentParent = CurTreeItem.GetParent();
	If NOT ItemParent = Undefined Then
		If Object.StructureType = PredefinedValue("Enum.fmInfoStructureTypes.IncomesAndExpensesBudget") OR Object.StructureType = PredefinedValue("Enum.fmInfoStructureTypes.CashflowBudget") Then
			While NOT (ItemParent.GroupParent = "" AND ItemParent.GroupType = New TypeDescription("CatalogRef.fmInfoStructuresSections")) Do
				ItemParent = ItemParent.GetParent();
			EndDo;
		Else
			While NOT ItemParent.FixedSection Do
				ItemParent = ItemParent.GetParent();
			EndDo;
		EndIf;
	EndIf;
	If Object.StructureType = PredefinedValue("Enum.fmInfoStructureTypes.IncomesAndExpensesBudget") Then
		StructureSectionType = PredefinedValue("Enum.fmBudgetFlowOperationTypes.Incomes");
	ElsIf Object.StructureType = PredefinedValue("Enum.fmInfoStructureTypes.CashflowBudget") Then
		StructureSectionType = PredefinedValue("Enum.fmBudgetFlowOperationTypes.Inflow");
	EndIf;
	If CurrentParent = Undefined AND NOT ValueIsFilled(CurData.StructureSectionType) Then
		ItemParent = Undefined;
	EndIf;
	CurData.StructureSectionType = ?(ItemParent = Undefined, StructureSectionType, ItemParent.StructureSectionType);
	//не забудем пройтись по формульным элементам с пустой ссылкой и подредактировать наименования и у них
	RefreshFormulaRowsDescriptions(CurData.Group, Text, StructurePresentationTree.GetItems());
	CurData.Group = Text;
	CurData.BoldFont = True;
	If CurrentParent = Undefined Then
		//РЕДАКТИРОВАНИЕ ПОРЯДКА
		If CurData.Order = 0 Then
			Count = StructurePresentationTree.GetItems().Count();
			If Count = 1 Then
				CurData.Order = 0;
			Else
				CurData.Order = Count - 1;
			EndIf;
		EndIf;
		//ТекДанные.Порядок = 0;
	Else
		//РЕДАКТИРОВАНИЕ ПОРЯДКА
		If CurData.Order = 0 Then
			Count = CurrentParent.GetItems().Count();
			If Count = 1 Then
				CurData.Order = 0;
			Else
				CurData.Order = Count - 1;
			EndIf;
		EndIf;
		//МаксНомерПП = ОпределитьМаксимальныйНомерПП(ТекЭлементДерева.ПолучитьРодителя().ПолучитьЭлементы());//ДеревоПредставленияСтруктуры.ПолучитьЭлементы());
		//ТекДанные.Порядок = МаксНомерПП + 1;
	EndIf;
	Items.AddStructureSection.Enabled = True;
	Items.AddItem.Enabled = True;
	Items.MakeBold.Enabled = True;
	Items.MakeItalic.Enabled = True;
	AddChangedOrDeletedItemsInList();
	RefreshConditionalAppearance();
EndProcedure

&AtClient
Procedure StructurePresentationTreeByFormulaOnChange(Item)
	CurData = Items.StructurePresentationTree.CurrentData;
	CurRowNumber = Items.StructurePresentationTree.CurrentRow;
	AttributeCurRow = ThisForm.StructurePresentationTree.FindByID(CurRowNumber);
	HasChildren = ?(AttributeCurRow.GetItems().Count() > 0, True, False);
	If CurData.ByFormula AND Object.StructureType <> PredefinedValue("Enum.fmInfoStructureTypes.IncomesAndExpensesBudget") AND Object.StructureType <> PredefinedValue("Enum.fmInfoStructureTypes.CashflowBudget") Then
		//выставляем галочку
		If HasChildren Then
			QueryText = NStr("en='The structure section data of the structure item will be removed. Are you sure you want to continue?';ru='ДанныеРазделаСтруктуры элемента структуры будут очищены. Продолжить?'");
			ShowQueryBox(New NotifyDescription("StructurePresentationTreeByFormulaOnChangeEnd1", ThisObject, New Structure("CurRowNumber, CurData, QueryText, AttributeCurRow", CurRowNumber, CurData, QueryText, AttributeCurRow)), QueryText, QuestionDialogMode.OKCancel);
			Return;
		Else
			If AttributeCurRow.GroupType = New TypeDescription("CatalogRef.fmIncomesAndExpensesItems") OR AttributeCurRow.GroupType = New TypeDescription("CatalogRef.fmCashflowItems") Then
				//если статья в группе статей, не дадим ставить галочку, т.к. это запрещено
				ItemParent = AttributeCurRow.GetParent();
				If ItemParent.GroupType = New TypeDescription("CatalogRef.fmItemGroups") Then
					CommonClientServer.MessageToUser(NStr("en=""Before transforming the item into the formula's element, it should be carried out of the item group"";ru='Прежде чем сделать из статьи формульный элемент, нужно вынести ее за пределы группы статей'"));
					AttributeCurRow.ByFormula = False;
					Return;
				EndIf;
				AttributeCurRow.GroupType = New TypeDescription("CatalogRef.fmInfoStructuresSections");
				AttributeCurRow.Analytics = Undefined;
				AttributeCurRow.Ref = Undefined;
				AttributeCurRow.UID = New UUID;
				SetAvailabilityOfGroupFieldButton(CurRowNumber);
				//ЭтаФорма.ОбновитьОтображениеДанных();
			EndIf;
			//без спроса добавляем 2 строки
			FixedRowPlus = AttributeCurRow.GetItems().Add();
			FixedRowPlus.Group = "(plus)";//"+";
			FixedRowPlus.PictureIndex = 2;
			FixedRowPlus.StructureSectionType = AttributeCurRow.StructureSectionType;
			FixedRowPlus.GroupParent = AttributeCurRow.Group;
			FixedRowPlus.GroupType = New TypeDescription("String");
			FixedRowPlus.IsFormulaItem = True;
			FixedRowPlus.ByFormula = True;
			FixedRowPlus.FormulaMinus = False;
			FixedRowMinus = AttributeCurRow.GetItems().Add();
			FixedRowMinus.Group = "(minus)";//"-";
			FixedRowMinus.PictureIndex = 1;
			FixedRowMinus.StructureSectionType = AttributeCurRow.StructureSectionType;
			FixedRowMinus.GroupParent = AttributeCurRow.Group;
			FixedRowMinus.GroupType = New TypeDescription("String");
			FixedRowMinus.IsFormulaItem = True;
			FixedRowMinus.ByFormula = True;
			FixedRowMinus.FormulaMinus = True;
			Items.AddStructureSection.Enabled = False;
			Items.AddItem.Enabled = False;
		EndIf;
		StructurePresentationTreeByFormulaOnChangeFragment1(AttributeCurRow);
	Else
		QueryText = NStr("en='The structure section data of the structure item will be removed. Are you sure you want to continue?';ru='ДанныеРазделаСтруктуры элемента структуры будут очищены. Продолжить?'");
		ShowQueryBox(New NotifyDescription("StructurePresentationTreeByFormulaOnChangeEnd", ThisObject, New Structure("CurData, AttributeCurRow", CurData, AttributeCurRow)), QueryText, QuestionDialogMode.OKCancel);
	EndIf;
EndProcedure

#EndRegion

#Region FormCommandsHandlers

&AtClient
Procedure MoveUp(Command)
	CurRowNumber = Items.StructurePresentationTree.CurrentRow;
	CurData = Items.StructurePresentationTree.CurrentData;
	CurGroup = CurData.Group;
	If CurData.FixedSection Then
		Return;
	EndIf;
	//перемещаем только в пределах одного родителя
	AttributeCurRow = ThisForm.StructurePresentationTree.FindByID(CurRowNumber);
	RowParent  = AttributeCurRow.GetParent();
	If RowParent = Undefined Then
		ItemsInBranch =  StructurePresentationTree.GetItems();
	Else
		ItemsInBranch =  RowParent.GetItems();
	EndIf;
	//ЭлементыВВетке =  РодительТекСтроки.ПолучитьЭлементы();
	CurrentItemIndex = ItemsInBranch.IndexOf(AttributeCurRow);
	Try
		PreviousAttributeRow = ItemsInBranch.Get(CurrentItemIndex - 1);
		//ПредыдущаяСтрокаРеквизита = ЭтаФорма.ДеревоПредставленияСтруктуры.НайтиПоИдентификатору(НомерТекСтроки - 1); 
		PreviousRowParent = PreviousAttributeRow.GetParent();
	Except 
		Return;
	EndTry;
	//меняем порядок
	PreviousOrder = PreviousAttributeRow.Order;
	CurrentOrder = AttributeCurRow.Order;
	PreviousAttributeRow.Order = CurrentOrder;
	AttributeCurRow.Order = PreviousOrder;
	//и перестроим дерево согласно новому порядку
	If RowParent = Undefined Then
		RowCount = StructurePresentationTree.GetItems();
	Else
		RowCount = RowParent.GetItems();
	EndIf;
	MovedIndex = RowCount.IndexOf(AttributeCurRow);
	Try
		RowCount.Move(MovedIndex, -1);
	Except EndTry;
	
	StringArray = New Array;
	StringArray.Add(AttributeCurRow);
	StringArray.Add(PreviousAttributeRow);
	AddChangedOrDeletedItemsInList(StringArray,,False);
EndProcedure

&AtClient
Procedure MoveDown(Command)
	CurRowNumber = Items.StructurePresentationTree.CurrentRow;
	CurData = Items.StructurePresentationTree.CurrentData;
	CurGroup = CurData.Group;
	If CurData.FixedSection Then
		Return;
	EndIf;
	AttributeCurRow = ThisForm.StructurePresentationTree.FindByID(CurRowNumber);
	RowParent  = AttributeCurRow.GetParent();
	If RowParent = Undefined Then
		ItemsInBranch =  StructurePresentationTree.GetItems();
	Else
		ItemsInBranch =  RowParent.GetItems();
	EndIf;
	//ЭлементыВВетке =  РодительТекСтроки.ПолучитьЭлементы();
	CurrentItemIndex = ItemsInBranch.IndexOf(AttributeCurRow);
	Try
		NextAttributeRow = ItemsInBranch.Get(CurrentItemIndex + 1);	
		//ПредыдущаяСтрокаРеквизита = ЭтаФорма.ДеревоПредставленияСтруктуры.НайтиПоИдентификатору(НомерТекСтроки - 1); 
		NextRowParent = NextAttributeRow.GetParent();
	Except 
		Return;
	EndTry;
	//меняем порядок
	NextOrder = NextAttributeRow.Order;
	CurrentOrder = AttributeCurRow.Order;
	NextAttributeRow.Order = CurrentOrder;
	AttributeCurRow.Order = NextOrder;	
	//и перестроим дерево согласно новому порядку
	If RowParent = Undefined Then
		RowCount = StructurePresentationTree.GetItems();
	Else
		RowCount = RowParent.GetItems();
	EndIf;
	MovedIndex = RowCount.IndexOf(AttributeCurRow);
	Try
		RowCount.Move(MovedIndex, 1);
	Except EndTry;
	
	StringArray = New Array;
	StringArray.Add(AttributeCurRow);
	StringArray.Add(NextAttributeRow);
	AddChangedOrDeletedItemsInList(StringArray,,False);
EndProcedure

&AtClient
Procedure AddStructureSection(Command)
	//если мы стоим на формульной строке структуры, то нельзя добавить, только встав на + или -
	ParentCurRow = Items.StructurePresentationTree.CurrentRow;
	
	ParentTreeData = StructurePresentationTree.FindByID(ParentCurRow);
	If ParentTreeData.ByFormula AND Object.StructureType <> PredefinedValue("Enum.fmInfoStructureTypes.IncomesAndExpensesBudget") AND Object.StructureType <> PredefinedValue("Enum.fmInfoStructureTypes.CashflowBudget") AND (ParentTreeData.GroupType = New TypeDescription("CatalogRef.fmInfoStructuresSections")) Then
		ErrorText = NStr("en='You should select row ""+"" or ""-"" with a mouse';ru='Необходимо мышкой выделить строку ""+"" или ""-"" '"); 
		CommonClientServer.MessageToUser(ErrorText);
		Return;
	EndIf;
	
	CurrentData = Items.StructurePresentationTree.CurrentData;
	CurrentItemParent = CurrentData.GetParent();
	If Command.Name = "AddStructureSection" Then
		
		If CurrentItemParent = Undefined Then
			TreeItems = StructurePresentationTree.GetItems();
		Else
			TreeItems = CurrentItemParent.GetItems();
		EndIf;
		NewItem = TreeItems.Add();
		
	ElsIf Command.Name = "AddSubsection" Then
		
		Items.StructurePresentationTree.AddRow();
		CurRow = Items.StructurePresentationTree.CurrentRow;
		NewItem = StructurePresentationTree.FindByID(CurRow);
		
	EndIf;
	
	CurRow = Items.StructurePresentationTree.CurrentRow;
	Items.StructurePresentationTree.CurrentItem = Items.StructurePresentationTreeGroup;
	
	If TypeOf(CurrentData.Analytics) = Type("CatalogRef.fmIncomesAndExpensesItems") Then
		Items.StructurePresentationTree.CurrentItem.TypeRestriction = New TypeDescription("CatalogRef.fmIncomesAndExpensesItems");
		NewItem.GroupType = New TypeDescription("CatalogRef.fmIncomesAndExpensesItems");
	ElsIf TypeOf(CurrentData.Analytics) = Type("CatalogRef.fmCashflowItems") Then
		Items.StructurePresentationTree.CurrentItem.TypeRestriction = New TypeDescription("CatalogRef.fmCashflowItems");
		NewItem.GroupType = New TypeDescription("CatalogRef.fmCashflowItems");
	ElsIf TypeOf(CurrentData.Analytics) = Type("CatalogRef.fmItemGroups") Then
		If Object.StructureType = PredefinedValue("Enum.fmInfoStructureTypes.IncomesAndExpensesBudget") Then
			Items.StructurePresentationTree.CurrentItem.TypeRestriction = New TypeDescription("CatalogRef.fmIncomesAndExpensesItems");
			NewItem.GroupType = New TypeDescription("CatalogRef.fmIncomesAndExpensesItems");
		ElsIf Object.StructureType = PredefinedValue("Enum.fmInfoStructureTypes.CashflowBudget") Then
			Items.StructurePresentationTree.CurrentItem.TypeRestriction = New TypeDescription("CatalogRef.fmCashflowItems");
			NewItem.GroupType = New TypeDescription("CatalogRef.fmCashflowItems");
		EndIf;
	ElsIf ValueIsFilled(CurrentData.Analytics) Then
		TypesArray = New Array();
		TypesArray.Add(TypeOf(CurrentData.Analytics));
		Items.StructurePresentationTree.CurrentItem.TypeRestriction = New TypeDescription(TypesArray);
	Else
		Items.StructurePresentationTree.CurrentItem.TypeRestriction = New TypeDescription("String");
		NewItem.GroupType = New TypeDescription("CatalogRef.fmInfoStructuresSections");
	EndIf;
	
	SetAvailabilityOfGroupFieldButton(CurRow);
	CurrentItemParent = NewItem.GetParent();
	If CurrentItemParent = Undefined Then
		NewItem.GroupParent = "";
		Items.StructurePresentationTree.CurrentItem.ChoiceButton = False;
	Else
		NewItem.GroupParent = CurrentItemParent.Group;
		NewItem.StructureSectionType = CurrentItemParent.StructureSectionType;
		//также проставим признак формульной строки, если родитель + или -
		If CurrentItemParent.IsFormulaItem Then
			GroupParentPlusMinus = CurrentItemParent.GetParent();
			NewItem.GroupParent = GroupParentPlusMinus.Group;
			NewItem.ByFormula = True;
			Items.StructurePresentationTree.CurrentItem.ChoiceButton = True;
		Else
			Try
				Items.StructurePresentationTree.CurrentItem.ChoiceButton = False;
			Except EndTry;
		EndIf;
		NewItem.IsFormulaItem = CurrentItemParent.IsFormulaItem;
		NewItem.FormulaMinus = CurrentItemParent.FormulaMinus;
	EndIf;
	//установим новой группировке новый УИД
	NewItem.UID = New UUID;
	Items.StructurePresentationTree.CurrentRow = NewItem.GetID();
	Items.StructurePresentationTree.CurrentItem = Items.StructurePresentationTreeGroup;
	ThisForm.CurrentItem = Items.StructurePresentationTree.CurrentItem;
	Items.StructurePresentationTree.ChangeRow();
	
	AddChangedOrDeletedItemsInList();
EndProcedure

&AtClient
Procedure MakeBold(Command)
	Items.MakeBold.Check = NOT Items.MakeBold.Check;
	ChangeAppearanceItemClient(True,,);
	AddChangedOrDeletedItemsInList(,,False);
EndProcedure

&AtClient
Procedure MakeItalic(Command)
	Items.MakeItalic.Check = NOT Items.MakeItalic.Check;
	ChangeAppearanceItemClient(, True, );
	AddChangedOrDeletedItemsInList(,,False);
EndProcedure

&AtClient
Procedure ExpandAllSourceTree(Command)
	ExpandAllTreeItems(FillingItemsTree.GetItems(), "FillingItemsTree");
EndProcedure

&AtClient
Procedure CollapseAllInStructure(Command)
	CollapseAllTreeItems(StructurePresentationTree.GetItems(), "StructurePresentationTree");
EndProcedure

&AtClient
Procedure ExpandAllInStructure(Command)
	ExpandAllTreeItems(StructurePresentationTree.GetItems(), "StructurePresentationTree");
EndProcedure

&AtClient
Procedure RefreshSourcesTree(Command)
	RefreshAtServer();
	//ЭтаФорма.ОбновитьОтображениеДанных();
EndProcedure

&AtClient
Procedure CollapseAllSourceTree(Command)
	CollapseAllTreeItems(FillingItemsTree.GetItems(), "FillingItemsTree");
EndProcedure

&AtClient
Procedure AddItemInStructure(Command)
	ParentCurRow = Items.StructurePresentationTree.CurrentRow;
	If ParentCurRow = Undefined Then
		ErrorText = NStr("en='Specify a row where you want to add an item';ru='Укажите строку, в которую хотите добавить статью'"); 
		CommonClientServer.MessageToUser(ErrorText);
		Return;
	EndIf;
	ParentTreeData = StructurePresentationTree.FindByID(ParentCurRow);
	If ParentTreeData.ByFormula AND Object.StructureType <> PredefinedValue("Enum.fmInfoStructureTypes.IncomesAndExpensesBudget") AND Object.StructureType <> PredefinedValue("Enum.fmInfoStructureTypes.CashflowBudget") AND (ParentTreeData.GroupType = New TypeDescription("CatalogRef.fmInfoStructuresSections")) Then
		ErrorText = NStr("en='You should select row ""+"" or ""-"" with a mouse';ru='Необходимо мышкой выделить строку ""+"" или ""-"" '"); 
		CommonClientServer.MessageToUser(ErrorText);
		Return;
	EndIf;
	If ParentTreeData = Undefined Then
		NRow = StructurePresentationTree.GetItems().Add();
	Else
		NRow = ParentTreeData.GetItems().Add();
	EndIf;
	TreeData = NRow;
	ParentTreeDataForSearch = ParentTreeData;
	IndexOf = 1;
	If ValueIsFilled(ParentTreeDataForSearch.Analytics) Then
		While TypeOf(ParentTreeDataForSearch.Analytics) <> Type("CatalogRef.fmIncomesAndExpensesItems") AND TypeOf(ParentTreeDataForSearch.Analytics) <> Type("CatalogRef.fmCashflowItems") AND TypeOf(ParentTreeDataForSearch.Analytics) <> Type("CatalogRef.fmItemGroups") Do
			ParentTreeDataForSearch = ParentTreeDataForSearch.GetParent();
			IndexOf = IndexOf+1;
		EndDo;
	EndIf;
	If ValueIsFilled(ParentTreeDataForSearch["AnalyticsType"+IndexOf]) Then
		Items.StructurePresentationTree.CurrentItem.TypeRestriction = New TypeDescription(ParentTreeDataForSearch["AnalyticsType"+IndexOf],"String");
		If IndexOf <> 3 AND ValueIsFilled(ParentTreeDataForSearch["AnalyticsType"+(IndexOf+1)]) Then
			Items.AddItem.Enabled = True;
		EndIf;
	ElsIf Object.StructureType = PredefinedValue("Enum.fmInfoStructureTypes.CashflowBudget") Then
		Items.StructurePresentationTree.CurrentItem.TypeRestriction = New TypeDescription("CatalogRef.fmCashflowItems, String");
		TreeData.GroupType = New TypeDescription("CatalogRef.fmCashflowItems");
	ElsIf Object.StructureType = PredefinedValue("Enum.fmInfoStructureTypes.IncomesAndExpensesBudget") Then
		Items.StructurePresentationTree.CurrentItem.TypeRestriction = New TypeDescription("CatalogRef.fmIncomesAndExpensesItems, String");
		TreeData.GroupType = New TypeDescription("CatalogRef.fmIncomesAndExpensesItems");
	EndIf;
	TreeData.GroupParent = ParentTreeData.Group;
	TreeData.StructureSectionType = ParentTreeData.StructureSectionType;
	//также проставим признак формульной строки, если родитель + или -
	If ParentTreeData.IsFormulaItem Then
		GroupParentPlusMinus = ParentTreeData.GetParent();
		TreeData.GroupParent = GroupParentPlusMinus.Group;
		TreeData.ByFormula = True;
	EndIf;
	TreeData.IsFormulaItem = ParentTreeData.IsFormulaItem;
	If NOT Items.StructurePresentationTree.CurrentItem.Name = "StructurePresentationTreeGroup" Then
		Items.StructurePresentationTree.CurrentItem = Items.StructurePresentationTreeGroup;
	EndIf;
	Items.StructurePresentationTree.CurrentRow = NRow.GetID();
	Items.StructurePresentationTree.CurrentItem = Items.StructurePresentationTreeGroup;
	ThisForm.CurrentItem = Items.StructurePresentationTree.CurrentItem;
	Items.StructurePresentationTree.ChangeRow();
EndProcedure

&AtClient
Procedure DeleteStructureItem(Command)
	DeleteCurrentItemInStructure();
EndProcedure

#EndRegion

#Region ProceduresAndFunctionsOfCommonUse

&AtClient
Procedure ChageOperationTypeChoiceList()
	ChoiceList = Items.MovementOperationType.ChoiceList;
	ChoiceList.Clear();
	If Object.StructureType = PredefinedValue("Enum.fmInfoStructureTypes.IncomesAndExpensesBudget") Then
		ChoiceList.Add(PredefinedValue("Enum.fmBudgetFlowOperationTypes.Incomes"));
		ChoiceList.Add(PredefinedValue("Enum.fmBudgetFlowOperationTypes.Expenses"));
	ElsIf Object.StructureType = PredefinedValue("Enum.fmInfoStructureTypes.CashflowBudget") Then
		ChoiceList.Add(PredefinedValue("Enum.fmBudgetFlowOperationTypes.Inflow"));
		ChoiceList.Add(PredefinedValue("Enum.fmBudgetFlowOperationTypes.Outflow"));
	EndIf;
EndProcedure

&AtClient
Procedure MovementOperationTypeStartChoice(Item, ChoiceData, StandardProcessing)
	StandardProcessing = False;
EndProcedure

&AtClient
Procedure MovementOperationTypeOnChangeEnd(QueryResult, AdditionalParameters) Export
	If QueryResult = DialogReturnCode.Yes Then
		ChangedItem = Items.StructurePresentationTree.CurrentData;
		ChangedItem.StructureSectionType = MovementOperationType;
		Items.StructurePresentationTree.ChangeRow();
		IterateBranchItems(ChangedItem.GetItems());
		AddChangedOrDeletedItemsInList();
	EndIf;
EndProcedure

&AtClient
Procedure IterateBranchItems(ChangesRow)
	For Each String In ChangesRow Do
		If String.GroupType = New TypeDescription("CatalogRef.fmIncomesAndExpensesItems") 
			OR String.GroupType = New TypeDescription("CatalogRef.fmCashflowItems")
			OR String.GroupType = New TypeDescription("CatalogRef.fmInfoStructuresSections")
			OR String.GroupType = New TypeDescription("CatalogRef.fmItemGroups")Then
			String.StructureSectionType = MovementOperationType;
			Items.StructurePresentationTree.ChangeRow();
			IterateBranchItems(String.GetItems());
		Else
			Continue;
		EndIf;
	EndDo;
EndProcedure

&AtServer
Procedure AddFormulasWithContentToChangedListRecursively(IDChanged)
	
	StructureTree = FormAttributeToValue("StructurePresentationTree");
	
	P = New Structure;
	P.Insert("UID", IDChanged);
	P.Insert("IsFormulaItem", True);
	StringsInFormulas = StructureTree.Rows.FindRows(P, True);
	For Each FoundRow In StringsInFormulas Do
		FormulaParentUID = FoundRow.Parent.Parent.UID;
		ChangedItemsListStr.Add(FormulaParentUID);
	EndDo;
	
EndProcedure

&AtServer
Procedure AddFormulasWithContentToChangedList(IDChanged, RefreshDependentFormulas = True)
	
	If NOT RefreshDependentFormulas Then
		Return;
	EndIf;
	
	StructureTree = FormAttributeToValue("StructurePresentationTree");
	///найдем ветку в дереве и всех ее родителей, т.к. если родители присутствуют в формульной ветке, их также нужно перезаписать
	P = New Structure;
	P.Insert("UID", IDChanged);
	P.Insert("IsFormulaItem", False);
	StringsInFormulas = StructureTree.Rows.FindRows(P, True);
	
	For Each FoundRow In StringsInFormulas Do
		//в этот цикл зайдем единожды
		RowParentUID = IDChanged;
		ParentCurRow = FoundRow;
		While NOT ParentCurRow = Undefined Do 
			AddFormulasWithContentToChangedListRecursively(ParentCurRow.UID);
			ParentCurRow = ParentCurRow.Parent;
		EndDo;
	EndDo;
	
EndProcedure

//для сохранения только измененных элементов структуры
&AtClient
Procedure AddChangedOrDeletedItemsInList(StringArray = Undefined, IsDeletion = False, RefreshDependentFormulas = True)
	
	If StringArray = Undefined Then
		StringArray = Items.StructurePresentationTree.SelectedRows;
	EndIf;
	
	For Each SelectedRow In StringArray Do
		
		If TypeOf(SelectedRow) = Type("Number") Then
			SelRowNumber = SelectedRow;
			SelectedRowData = StructurePresentationTree.FindByID(SelRowNumber);
		Else
			SelectedRowData = SelectedRow;
		EndIf;
		
		If SelectedRowData.GroupType = New TypeDescription("CatalogRef.fmInfoStructuresSections") Then
			If IsDeletion Then
				If SelectedRowData.IsFormulaItem Then 
					ChangedRowUID = SelectedRowData.GetParent().GetParent().UID;
					If ChangedItemsListStr.FindByValue(ChangedRowUID) = Undefined Then
						ChangedItemsListStr.Add(ChangedRowUID);
						AddFormulasWithContentToChangedList(ChangedRowUID,RefreshDependentFormulas);
					EndIf;
				Else
					RowToDeleteRef = SelectedRowData.Ref;
					If DeletedItemsListStr.FindByValue(RowToDeleteRef) = Undefined AND NOT RowToDeleteRef = PredefinedValue("Catalog.fmInfoStructuresSections.EmptyRef") Then
						DeletedItemsListStr.Add(RowToDeleteRef);
					EndIf;
				EndIf;
			Else
				If SelectedRowData.IsFormulaItem Then
					ChangedRowUID = SelectedRowData.GetParent().GetParent().UID;
				Else
					ChangedRowUID = SelectedRowData.UID;
				EndIf;
				If ChangedItemsListStr.FindByValue(ChangedRowUID) = Undefined Then
					ChangedItemsListStr.Add(ChangedRowUID);
					AddFormulasWithContentToChangedList(ChangedRowUID, RefreshDependentFormulas);
				EndIf;
			EndIf;
		ElsIf SelectedRowData.GroupType = New TypeDescription("CatalogRef.fmCashflowItems") 
			OR SelectedRowData.GroupType = New TypeDescription("CatalogRef.fmItemGroups")
			OR SelectedRowData.GroupType = New TypeDescription("CatalogRef.fmIncomesAndExpensesItems")
			OR NOT ValueIsFilled(SelectedRowData.GroupType) Then
			ParentIt = SelectedRowData.GetParent();
			While ParentIt.GroupType <> New TypeDescription("CatalogRef.fmInfoStructuresSections") Do
				ParentIt = ParentIt.GetParent();
			EndDo;
			ChangedRowUID = ParentIt.UID;
			If ChangedItemsListStr.FindByValue(ChangedRowUID) = Undefined Then
				If ParentIt.GroupType = New TypeDescription("CatalogRef.fmItemGroups") Then
					ChangedItemsListStr.Add(ParentIt.GetParent().UID);
					AddFormulasWithContentToChangedList(ParentIt.GetParent().UID, RefreshDependentFormulas);
				Else
					ChangedItemsListStr.Add(ChangedRowUID);
					AddFormulasWithContentToChangedList(ChangedRowUID, RefreshDependentFormulas);
				EndIf;
			EndIf;
		EndIf;
	EndDo;
	
EndProcedure

&AtClient
Procedure ChangeAppearanceItemClient(ChangeBold = False, ChangeItalic = False, ChangeColor = False)
	CurRow = Items.StructurePresentationTree.CurrentData;
	If ChangeBold Then
		CurRow.BoldFont = NOT CurRow.BoldFont;
	ElsIf ChangeItalic Then
		CurRow.ItalicFont = NOT CurRow.ItalicFont;
	ElsIf ChangeColor Then
		CurRow.TextColor = ReturnChangeCurRowColor(GroupColor);
	EndIf;
	RefreshConditionalAppearance();
EndProcedure

&AtServerNoContext
Function ReturnChangeCurRowColor(GroupColor)
	Serializer = New XDTOSerializer(XDTOFactory);
	ObjectXDTO = Serializer.WriteXDTO(GroupColor);
	RecordXML = New XMLWriter;
	RecordXML.SetString();
	XDTOFactory.WriteXML(RecordXML, ObjectXDTO);
	Return RecordXML.Close();
EndFunction

&AtServer
Procedure ClearFillingTreeAtServer()
	TTree = FormAttributeToValue("FillingItemsTree");
	TTree.Rows.Clear();
	ValueToFormAttribute(TTree, "FillingItemsTree");
EndProcedure

&AtServer
Procedure ClearStructuresItemsTreeAtServer()
	
	TTree = FormAttributeToValue("StructurePresentationTree");
	TTree.Rows.Clear();
	//для типов отчета 1 и 2 добавим фиксированные строки
	If Object.StructureType = Enums.fmInfoStructureTypes.IncomesAndExpensesBudget Then
		
		//ДОХОДЫ
		StructureTreeNewRow = TTree.Rows.Add();
		StructureTreeNewRow.Group = NStr("en='INCOME';ru='ДОХОДЫ'");
		StructureTreeNewRow.GroupType = New TypeDescription("CatalogRef.fmIncomesAndExpensesItems");
		StructureTreeNewRow.StructureSectionType = Enums.fmBudgetFlowOperationTypes.Incomes;
		StructureTreeNewRow.UID = New UUID;
		StructureTreeNewRow.BoldFont = True;
		StructureTreeNewRow.GroupParent = "";
		
		//РАСХОДЫ
		StructureTreeNewRow = TTree.Rows.Add();
		StructureTreeNewRow.Group = NStr("en='EXPENSES';ru='РАСХОДЫ'");
		StructureTreeNewRow.GroupType = New TypeDescription("CatalogRef.fmIncomesAndExpensesItems");
		StructureTreeNewRow.StructureSectionType = Enums.fmBudgetFlowOperationTypes.Expenses;
		StructureTreeNewRow.UID = New UUID;
		StructureTreeNewRow.BoldFont = True;
		StructureTreeNewRow.GroupParent = "";
		
	ElsIf Object.StructureType = Enums.fmInfoStructureTypes.CashflowBudget Then
		//ДОХОДЫ
		StructureTreeNewRow = TTree.Rows.Add();
		StructureTreeNewRow.Group = NStr("en='INFLOW';ru='ПРИТОК'");
		StructureTreeNewRow.GroupType = New TypeDescription("CatalogRef.fmCashflowItems");
		StructureTreeNewRow.StructureSectionType = Enums.fmBudgetFlowOperationTypes.Inflow;
		StructureTreeNewRow.UID = New UUID;
		StructureTreeNewRow.BoldFont = True;
		StructureTreeNewRow.GroupParent = "";
		
		//РАСХОДЫ
		StructureTreeNewRow = TTree.Rows.Add();
		StructureTreeNewRow.Group = NStr("en='OUTFLOW';ru='ОТТОК'");
		StructureTreeNewRow.GroupType = New TypeDescription("CatalogRef.fmCashflowItems");
		StructureTreeNewRow.StructureSectionType = Enums.fmBudgetFlowOperationTypes.Outflow;
		StructureTreeNewRow.UID = New UUID;
		StructureTreeNewRow.BoldFont = True;
		StructureTreeNewRow.GroupParent = "";
	EndIf;
	
	ValueToFormAttribute(TTree, "StructurePresentationTree");
	
EndProcedure

&AtServer
Procedure FillPresentationTree()
	
	TreeObject = New ValueTree;
	TypesArray = New Array;
	TypesArray.Add(Type("String"));
	TypesArray.Add(Type("CatalogRef.fmIncomesAndExpensesItems"));
	TypesArray.Add(Type("CatalogRef.fmCashflowItems"));
	TypesArray.Add(Type("CatalogRef.fmItemGroups"));
	TypesArray.Add(Type("CatalogRef.fmInfoStructuresSections"));
	TreeObject.Columns.Add("Group");
	TreeObject.Columns.Add("ItemCode", New TypeDescription("String"));
	TreeObject.Columns.Add("ByFormula", New TypeDescription("Boolean"));
	TreeObject.Columns.Add("Order", New TypeDescription("Number"));
	TreeObject.Columns.Add("NumberPresentation", New TypeDescription("String"));
	TreeObject.Columns.Add("IsBlankString", New TypeDescription("Boolean"));
	TreeObject.Columns.Add("StructureSectionType", New TypeDescription("EnumRef.fmBudgetFlowOperationTypes"));
	TreeObject.Columns.Add("ItalicFont", New TypeDescription("Boolean"));
	TreeObject.Columns.Add("TextColor", New TypeDescription("String"));
	TreeObject.Columns.Add("BoldFont", New TypeDescription("Boolean"));
	TreeObject.Columns.Add("OutputDepartmentName", New TypeDescription("Boolean"));
	TreeObject.Columns.Add("Analytics");
	TreeObject.Columns.Add("AnalyticsType1", New TypeDescription("TypeDescription"));
	TreeObject.Columns.Add("AnalyticsType2", New TypeDescription("TypeDescription"));
	TreeObject.Columns.Add("AnalyticsType3", New TypeDescription("TypeDescription"));
	TreeObject.Columns.Add("Source", New TypeDescription("CatalogRef.fmInfoStructuresSections"));
	TreeObject.Columns.Add("FormulaMinus", New TypeDescription("Boolean"));
	TreeObject.Columns.Add("GroupType", New TypeDescription("TypeDescription"));
	TreeObject.Columns.Add("FixedSection", New TypeDescription("Boolean"));
	TreeObject.Columns.Add("Ref", New TypeDescription(TypesArray));
	TypesArrayF = New Array;
	TypesArrayF.Add(Type("CatalogRef.fmIncomesAndExpensesItems"));
	TypesArrayF.Add(Type("CatalogRef.fmCashflowItems"));
	TypesArrayF.Add(Type("CatalogRef.fmInfoStructuresSections"));
	TreeObject.Columns.Add("FormulaString", New TypeDescription(TypesArrayF));
	TreeObject.Columns.Add("IsFormulaItem", New TypeDescription("Boolean"));
	TreeObject.Columns.Add("GroupParent", New TypeDescription("String"));
	TreeObject.Columns.Add("ExpandedBeforeClose", New TypeDescription("Boolean"));
	TreeObject.Columns.Add("PictureIndex", New TypeDescription("Number"));
	TreeObject.Columns.Add("UID", New TypeDescription("UUID"));
	
	If Object.StructureType = Enums.fmInfoStructureTypes.IncomesAndExpensesBudget Then
		If (NOT ValueIsFilled(Object.Ref) OR Object.Ref.StructureType <> Object.StructureType)
		AND NOT ValueIsFilled(CopiedInfoStructure) Then
			//добавим фиксированные строки ДОХОДЫ, РАСХОДЫ, ВКЛАД и наполним их, если есть чем
			//ДОХОДЫ
			StructureTreeNewRow = TreeObject.Rows.Add();
			StructureTreeNewRow.Group = NStr("en='INCOME';ru='ДОХОДЫ'");
			StructureTreeNewRow.GroupType = New TypeDescription("CatalogRef.fmInfoStructuresSections");
			StructureTreeNewRow.UID = New UUID;
			StructureTreeNewRow.StructureSectionType = Enums.fmBudgetFlowOperationTypes.Incomes;
			StructureTreeNewRow.GroupParent = "";
			StructureTreeNewRow.BoldFont = True;
			//РЕДАКТИРОВАНИЕ ПОРЯДКА
			StructureTreeNewRow.Order = 0;
			//РАСХОДЫ
			StructureTreeNewRow = TreeObject.Rows.Add();
			StructureTreeNewRow.Group = NStr("en='EXPENSES';ru='РАСХОДЫ'");
			StructureTreeNewRow.GroupType = New TypeDescription("CatalogRef.fmInfoStructuresSections");
			StructureTreeNewRow.UID = New UUID;
			StructureTreeNewRow.StructureSectionType = Enums.fmBudgetFlowOperationTypes.Expenses;
			StructureTreeNewRow.GroupParent = "";
			StructureTreeNewRow.BoldFont = True;
			//РЕДАКТИРОВАНИЕ ПОРЯДКА
			StructureTreeNewRow.Order = 1;
		EndIf;
		FillInnerStructureItems(TreeObject, Undefined);
	ElsIf Object.StructureType = Enums.fmInfoStructureTypes.CashflowBudget Then
		If (NOT ValueIsFilled(Object.Ref) OR Object.Ref.StructureType <> Object.StructureType)
		AND NOT ValueIsFilled(CopiedInfoStructure) Then
			//ПРИТОК
			StructureTreeNewRow = TreeObject.Rows.Add();
			StructureTreeNewRow.Group = NStr("en='INFLOW';ru='ПРИТОК'");
			StructureTreeNewRow.GroupType = New TypeDescription("CatalogRef.fmInfoStructuresSections");
			StructureTreeNewRow.UID = New UUID;
			StructureTreeNewRow.StructureSectionType = Enums.fmBudgetFlowOperationTypes.Inflow;
			StructureTreeNewRow.GroupParent = "";
			StructureTreeNewRow.BoldFont = True;
			//РЕДАКТИРОВАНИЕ ПОРЯДКА
			StructureTreeNewRow.Order = 0;
			//ОТТОК
			StructureTreeNewRow = TreeObject.Rows.Add();
			StructureTreeNewRow.Group = NStr("en='OUTFLOW';ru='ОТТОК'");
			StructureTreeNewRow.GroupType = New TypeDescription("CatalogRef.fmInfoStructuresSections");
			StructureTreeNewRow.UID = New UUID;
			StructureTreeNewRow.StructureSectionType = Enums.fmBudgetFlowOperationTypes.Outflow;
			StructureTreeNewRow.GroupParent = "";
			StructureTreeNewRow.BoldFont = True;
			//РЕДАКТИРОВАНИЕ ПОРЯДКА
			StructureTreeNewRow.Order = 1;
		EndIf;
		FillInnerStructureItems(TreeObject, Undefined);
	EndIf;
	TreeObject.Rows.Sort("Order Asc", True);
	ValueToFormAttribute(TreeObject, "StructurePresentationTree");
EndProcedure

&AtServer
Procedure FillInnerStructureItems(TreeSectionRow, IncomesAndExpenses)
	If ValueIsFilled(Object.Ref) OR NOT CopiedInfoStructure.IsEmpty() Then
		//здесь проверить порядок выводимых в отчет разделов в соотв. с константами!!
		//пока делаю с сортировкой по полю порядок
		Query = New Query;
		Query.Text = "SELECT
		|	fmInfoStructuresSections.Ref AS Group1,
		|	fmInfoStructuresSections.Ref AS RefForUID,
		|	fmInfoStructuresSections.ByFormula,
		|	fmInfoStructuresSections.Parent,
		|	fmInfoStructuresSections.Description,
		|	fmInfoStructuresSections.Order,
		|	fmInfoStructuresSections.BoldFont,
		|	fmInfoStructuresSections.IsBlankString,
		|	fmInfoStructuresSections.StructureSectionType,
		|	fmInfoStructuresSections.ItalicFont,
		|	fmInfoStructuresSections.TextColor,
		|	fmInfoStructuresSections.OutputDepartmentName,
		|	fmInfoStructuresSections.DeletionMark,
		|	CASE
		|		WHEN &IsCopy
		|			Then Value(Catalog.fmInfoStructuresSections.EmptyRef)
		|		Else fmInfoStructuresSections.Ref
		|	END AS Ref
		|FROM
		|	Catalog.fmInfoStructuresSections AS fmInfoStructuresSections
		|WHERE
		|	fmInfoStructuresSections.Owner = &StructureType"
		+  ?(IncomesAndExpenses = Undefined, "", "
		|	AND fmInfoStructuresSections.StructureSectionType = &StructureSectionType")
		+ "
		|	AND fmInfoStructuresSections.Ref <> &IsEmpty
		|	AND fmInfoStructuresSections.DeletionMark = False
		|
		|ORDER BY
		|	fmInfoStructuresSections.Order
		|TOTALS BY
		|	Group1 Hierarchy";
		If NOT CopiedInfoStructure.IsEmpty() Then
			Query.SetParameter("StructureType", CopiedInfoStructure);
		Else
			Query.SetParameter("StructureType", Object.Ref);
		EndIf;
		If NOT IncomesAndExpenses = Undefined Then
			Query.SetParameter("StructureSectionType", IncomesAndExpenses);
		EndIf;
		Query.SetParameter("IsCopy", NOT CopiedInfoStructure.IsEmpty());
		Query.SetParameter("IsEmpty", Catalogs.fmInfoStructuresSections.EmptyRef());
		Unloading = Query.Execute().Unload(QueryResultIteration.ByGroupsWithHierarchy);
		Unloading.Columns.Group1.Name = "Group";
		FillHierarchyOfStructurePresentation(Unloading.Rows, TreeSectionRow, IncomesAndExpenses, NOT CopiedInfoStructure.IsEmpty());
		
	EndIf;
EndProcedure

&AtServer
Procedure FillHierarchyOfStructurePresentation(TreeRows, TreeSectionRow, IncomesAndExpenses, IsCopy = False)
	For Each LoadRow In TreeRows Do
		Selection = LoadRow;
		If Selection.DeletionMark Then  //т.к. иначе попадут в дерево строки , помеченные на удаление с непомеченными на удаление дочерними
			Continue;
		EndIf;
		If NOT Selection.Parent = Undefined Then
			If Selection.Group = Selection.Parent.Group Then
				//избавляемся от дублей
				Continue;
			EndIf;
		EndIf;
		StructureTreeNewRow = TreeSectionRow.Rows.Add();
		FillPropertyValues(StructureTreeNewRow, Selection);
		StructureTreeNewRow.PictureIndex = 0;
		StructureTreeNewRow.Group = String(Selection.Group);
		
		If IncomesAndExpenses = Undefined AND NOT Object.StructureType = Enums.fmInfoStructureTypes.IncomesAndExpensesBudget AND NOT Object.StructureType = Enums.fmInfoStructureTypes.CashflowBudget Then
			StructureTreeNewRow.GroupParent = "";
		ElsIf Object.StructureType = Enums.fmInfoStructureTypes.IncomesAndExpensesBudget OR Object.StructureType = Enums.fmInfoStructureTypes.CashflowBudget Then
			If ValueIsFilled(Selection.Parent) Then
				StructureTreeNewRow.GroupParent = String(Selection.Parent.Group);
			Else
				StructureTreeNewRow.GroupParent = "";
			EndIf;
		Else
			If NOT ValueIsFilled(Selection.Parent) Then
				StructureTreeNewRow.GroupParent = Upper(String(IncomesAndExpenses));
			Else
				StructureTreeNewRow.GroupParent = String(Selection.Parent.Group);
			EndIf;
		EndIf;
		
		StructureTreeNewRow.GroupType = New TypeDescription("CatalogRef.fmInfoStructuresSections");
		
		//присваиваем УИД по ссылке!
		StructureTreeNewRow.UID = Selection.RefForUID.UUID();	
		
		If IsCopy Then
			If ChangedItemsListStr.FindByValue(StructureTreeNewRow.UID) = Undefined Then
				ChangedItemsListStr.Add(StructureTreeNewRow.UID);
			EndIf;
		EndIf;
		
		//для формульных элементов структуры чуть другой подход
		If Selection.ByFormula AND Object.StructureType <> Enums.fmInfoStructureTypes.IncomesAndExpensesBudget AND Object.StructureType <> Enums.fmInfoStructureTypes.CashflowBudget Then
			
			VTFormulas = Selection.Group.Formula;
			////отсортируем таблицу так, чтобы сперва стояли строки с плюсом, затем с минусом
			//ТЗФормул.Сортировать("Минус Возр");
			//добавим 2 фиксированные строки  с + и с -
			FixedRowPlus = StructureTreeNewRow.Rows.Add();
			FixedRowPlus.Group = "(plus)";//"+";
			FixedRowPlus.PictureIndex = 2;
			FixedRowPlus.StructureSectionType = StructureTreeNewRow.StructureSectionType;
			FixedRowPlus.GroupParent = StructureTreeNewRow.Group;
			FixedRowPlus.GroupType = New TypeDescription("String");
			FixedRowPlus.IsFormulaItem = True;
			FixedRowPlus.ByFormula = True;
			FixedRowPlus.FormulaMinus = False;
			
			FixedRowMinus = StructureTreeNewRow.Rows.Add();
			FixedRowMinus.Group = "(minus)";//"-";
			FixedRowMinus.PictureIndex = 1;
			FixedRowMinus.StructureSectionType = StructureTreeNewRow.StructureSectionType;
			FixedRowMinus.GroupParent = StructureTreeNewRow.Group;
			FixedRowMinus.GroupType = New TypeDescription("String");
			FixedRowMinus.IsFormulaItem = True;
			FixedRowMinus.ByFormula = True;
			FixedRowMinus.FormulaMinus = True;
			
			If VTFormulas.Count() > 0 Then
				For Each StringFormula In VTFormulas Do
					
					If StringFormula.Minus Then
						NewFormulaRow = FixedRowMinus.Rows.Add();
						NewFormulaRow.GroupParent = StructureTreeNewRow.Group//"-";
					Else
						NewFormulaRow = FixedRowPlus.Rows.Add();
						NewFormulaRow.GroupParent = StructureTreeNewRow.Group//"+";
					EndIf;
					
					If TypeOf(StringFormula.String) = Type("CatalogRef.fmInfoStructuresSections") Then
						NewFormulaRow.GroupType = New TypeDescription("CatalogRef.fmInfoStructuresSections");
					ElsIf TypeOf(StringFormula.String) = Type("CatalogRef.fmIncomesAndExpensesItems") Then
						NewFormulaRow.GroupType = New TypeDescription("CatalogRef.fmIncomesAndExpensesItems");
						NewFormulaRow.ItemCode = StringFormula.String.Code;
					ElsIf TypeOf(StringFormula.String) = Type("CatalogRef.fmCashflowItems") Then
						NewFormulaRow.GroupType = New TypeDescription("CatalogRef.fmCashflowItems");
						NewFormulaRow.ItemCode = StringFormula.String.Code;
					EndIf;
					
					FillPropertyValues(NewFormulaRow, Selection);
					If TypeOf(StringFormula.String) = Type("CatalogRef.fmInfoStructuresSections") Then
						NewFormulaRow.ItalicFont= StringFormula.String.ItalicFont;
						NewFormulaRow.TextColor = StringFormula.String.TextColor;
						NewFormulaRow.BoldFont = StringFormula.String.BoldFont;
					EndIf;
					NewFormulaRow.StructureSectionType = StructureTreeNewRow.StructureSectionType;
					NewFormulaRow.Group = String(StringFormula.String);
					NewFormulaRow.GroupParent = StructureTreeNewRow.Group;
					NewFormulaRow.PictureIndex = 0;
					If NOT (NOT CopiedInfoStructure.IsEmpty() AND (TypeOf(StringFormula.String) = Type("CatalogRef.fmInfoStructuresSections"))) Then
						NewFormulaRow.FormulaString = StringFormula.String;
						NewFormulaRow.Ref = StringFormula.String;
					EndIf;
					NewFormulaRow.UID = StringFormula.String.UUID();
					NewFormulaRow.FormulaMinus = StringFormula.Minus;
					NewFormulaRow.IsFormulaItem = True;
					NewFormulaRow.ByFormula = True;
				EndDo;
			EndIf;
			
		Else
			
			TSWithReportStructurePr = Selection.Group.SectionStructureData;
			If TSWithReportStructurePr.Count() > 0 Then
				//****************не забыть для другоих видов отчетов сделать!! могут быть не просто статьи!!!
				For Each RowItem In TSWithReportStructurePr Do
					Substring = StructureTreeNewRow.Rows.Find(RowItem.Analytics);
					If ValueIsFilled(Substring) Then
						NewSubstring = Substring;
					Else
						NewSubstring = StructureTreeNewRow.Rows.Add();
					EndIf;
					If TypeOf(RowItem.Analytics) = Type("CatalogRef.fmItemGroups") Then
						//сначала добавим саму группу, а потом визуально прилепим статьи, недоступные для пользователя
						//НоваяПодстрока = НоваяСтрокаДереваСтруктуры.Строки.Добавить();
						FillPropertyValues(NewSubstring, Selection);
						FillPropertyValues(NewSubstring, RowItem);
						NewSubstring.PictureIndex = 0;
						NewSubstring.Group = RowItem.Analytics;//?????????????
						NewSubstring.GroupParent = StructureTreeNewRow.Group;
						NewSubstring.GroupType = New TypeDescription("CatalogRef.fmItemGroups");
						
						Query = New Query;
						Query.Text = "SELECT TOP 1
						               |	fmItemGroupsItems.Item AS Item
						               |FROM
						               |	Catalog.fmItemGroups.Items AS fmItemGroupsItems
						               |WHERE
						               |	fmItemGroupsItems.Ref = &ItemsGroup";
						Query.SetParameter("ItemsGroup", RowItem.Analytics);
						Selection = Query.Execute().SELECT();
						While Selection.Next() Do
							If TypeOf(Selection.Item) = Type("CatalogRef.fmIncomesAndExpensesItems") Then
								NewSubstring.AnalyticsType1 = Selection.Item.AnalyticsType1.ValueType;
								NewSubstring.AnalyticsType2 = Selection.Item.AnalyticsType2.ValueType;
								NewSubstring.AnalyticsType3 = Selection.Item.AnalyticsType3.ValueType;
							ElsIf TypeOf(Selection.Item) = Type("CatalogRef.fmCashflowItems") Then
								NewSubstring.AnalyticsType1 = Selection.Item.fmAnalyticsType1.ValueType;
								NewSubstring.AnalyticsType2 = Selection.Item.fmAnalyticsType2.ValueType;
								NewSubstring.AnalyticsType3 = Selection.Item.fmAnalyticsType3.ValueType;
							EndIf;
						EndDo;
						For IndexOf = 1 To 3 Do
							If ValueIsFilled(RowItem["Analytics"+IndexOf]) Then
								AnalyticsString = NewSubstring.Rows.Add();
								AnalyticsString.Analytics = RowItem["Analytics"+IndexOf];
								AnalyticsString.ItemCode = RowItem["Analytics"+IndexOf].Code;
								AnalyticsString.GroupParent = NewSubstring.Group;
								AnalyticsString.Group = RowItem["Analytics"+IndexOf];
								NewSubstring = AnalyticsString;
							EndIf;
						EndDo;
					Else
						FillPropertyValues(NewSubstring, Selection);
						FillPropertyValues(NewSubstring, RowItem);
						NewSubstring.PictureIndex = 0;
						NewSubstring.Group = RowItem.Analytics;
						NewSubstring.GroupParent = StructureTreeNewRow.Group;
						If Object.StructureType = Enums.fmInfoStructureTypes.IncomesAndExpensesBudget Then
							NewSubstring.GroupType = New TypeDescription("CatalogRef.fmIncomesAndExpensesItems");
						ElsIf Object.StructureType = Enums.fmInfoStructureTypes.CashflowBudget Then
							NewSubstring.GroupType = New TypeDescription("CatalogRef.fmCashflowItems");
						EndIf;
						NewSubstring.ItemCode = RowItem.Analytics.Code;
						If TypeOf(RowItem.Analytics) = Type("CatalogRef.fmIncomesAndExpensesItems") Then
							NewSubstring.AnalyticsType1 = RowItem.Analytics.AnalyticsType1.ValueType;
							NewSubstring.AnalyticsType2 = RowItem.Analytics.AnalyticsType2.ValueType;
							NewSubstring.AnalyticsType3 = RowItem.Analytics.AnalyticsType3.ValueType;
						ElsIf TypeOf(RowItem.Analytics) = Type("CatalogRef.fmCashflowItems") Then
							NewSubstring.AnalyticsType1 = RowItem.Analytics.fmAnalyticsType1.ValueType;
							NewSubstring.AnalyticsType2 = RowItem.Analytics.fmAnalyticsType2.ValueType;
							NewSubstring.AnalyticsType3 = RowItem.Analytics.fmAnalyticsType3.ValueType;
						EndIf;
						For IndexOf = 1 To 3 Do
							If ValueIsFilled(RowItem["Analytics"+IndexOf]) Then
								SearchSubstring = NewSubstring.Rows.Find(RowItem["Analytics"+IndexOf]);
								If ValueIsFilled(SearchSubstring) Then
									AnalyticsString = SearchSubstring;
								Else
									AnalyticsString = NewSubstring.Rows.Add();
								EndIf;
								AnalyticsString.Analytics = RowItem["Analytics"+IndexOf];
								AnalyticsString.ItemCode = RowItem["Analytics"+IndexOf].Code;
								AnalyticsString.GroupParent = NewSubstring.Group;
								AnalyticsString.Group = RowItem["Analytics"+IndexOf];
								NewSubstring = AnalyticsString;
							EndIf;
						EndDo;
					EndIf;
				EndDo;
			EndIf;
		EndIf;
		FillHierarchyOfStructurePresentation(LoadRow.Rows, StructureTreeNewRow, IncomesAndExpenses, IsCopy);
	EndDo;
EndProcedure

&AtClient
Procedure DeleteRowFromSource(TreeRowSource)
	RowparentSource = TreeRowSource.GetParent();
	If NOT RowparentSource = Undefined Then
		RowparentSource.GetItems().Delete(TreeRowSource);
	EndIf;
EndProcedure

&AtServer
Procedure FillSourcesItemsTree()
	
	TreeObject = New ValueTree;
	TypesArray = New Array;
	TypesArray.Add(Type("String"));
	TypesArray.Add(Type("CatalogRef.fmIncomesAndExpensesItems"));
	TypesArray.Add(Type("CatalogRef.fmItemGroups"));
	TypesArray.Add(Type("CatalogRef.fmCashflowItems"));
	TypesArray.Add(Type("EnumRef.fmBudgetFlowOperationTypes"));
	TreeObject.Columns.Add("Group", New TypeDescription(TypesArray));
	TreeObject.Columns.Add("ItemCode", New TypeDescription("String"));
	TreeObject.Columns.Add("PictureIndex", New TypeDescription("Number"));
	TreeObject.Columns.Add("ExpandedBeforeRebuild", New TypeDescription("Boolean"));
	TreeObject.Columns.Add("IsFolder", New TypeDescription("Boolean"));
	
	//возьмем еще дерево слева для сравнения, чтобы смотреть на его развернутые узлы
	TreeLeft = FormAttributeToValue("FillingItemsTree", Type("ValueTree"));
	
	//получим массив статей для исключения из левого дерева
	ExcludedItemsList = New ValueList;
	TreeRight = FormAttributeToValue("StructurePresentationTree", Type("ValueTree"));
	ExcludedItemsList = GetItemsListInPresentationTree(TreeRight.Rows, ExcludedItemsList);
	
	//дерево состоит из статей ДиР
	NewRowIAE = TreeObject.Rows.Add();
	//
	If Object.StructureType = Enums.fmInfoStructureTypes.CashflowBudget Then
		NewRowIAE.PictureIndex = 7;
		NewRowIAE.Group = NStr("en='Cash flow items';ru='Статьи ДДС'");
		
		Query = New Query;
		Query.Text = "SELECT
		               |	fmCashflowItems.Ref AS Group1,
		               |	fmCashflowItems.Code AS ItemCode
		               |FROM
		               |	Catalog.fmCashflowItems AS fmCashflowItems
		               |WHERE
		               |	NOT fmCashflowItems.Ref IN (&ExcludedItemsList)
		               |	AND NOT fmCashflowItems.DeletionMark
		               |
		               |ORDER BY
		               |	fmCashflowItems.IsFolder,
		               |	fmCashflowItems.Description
		               |TOTALS BY
		               |	Group1 Hierarchy";
	ElsIf Object.StructureType = Enums.fmInfoStructureTypes.IncomesAndExpensesBudget Then
		NewRowIAE.Group = NStr("en='Income and expenses items';ru='Статьи доходов и расходов'");
		NewRowIAE.PictureIndex = 7;
		Query = New Query;
		Query.Text = "SELECT
		|	fmIncomesAndExpensesItems.Ref AS Group1,
		|	fmIncomesAndExpensesItems.Code AS ItemCode
		|FROM
		|	Catalog.fmIncomesAndExpensesItems AS fmIncomesAndExpensesItems
		|WHERE
		|	NOT fmIncomesAndExpensesItems.DeletionMark
		|	AND NOT fmIncomesAndExpensesItems.Ref IN (&ExcludedItemsList)
		|ORDER BY
		|	fmIncomesAndExpensesItems.IsFolder,
		|	fmIncomesAndExpensesItems.Description
		|TOTALS BY
		|	Group1 Hierarchy";
		
	EndIf;
	
	Query.SetParameter("ExcludedItemsList", ExcludedItemsList);
	ItemsUnloadTreeIAE = Query.Execute().Unload(QueryResultIteration.ByGroupsWithHierarchy);
	ItemsUnloadTreeIAE.Columns.Group1.Name = "Group";
	For Each RowSource In ItemsUnloadTreeIAE.Rows Do
		CopyTreeNode(NewRowIAE.Rows, RowSource, True);
	EndDo;
	
	//получим массив групп статей для исключения из левого дерева
	ExcludedItemGroupsList = New ValueList;
	ExcludedItemGroupsList = GetItemGroupsListInPresentationTree(TreeRight.Rows, ExcludedItemGroupsList);
	
	//групп статей ДиР
	NewRowIAE = TreeObject.Rows.Add();
	If Object.StructureType = Enums.fmInfoStructureTypes.CashflowBudget Then
		NewRowIAE.Group = NStr("en='Cash flow groups';ru='Группы ДДС'");
	ElsIf Object.StructureType = Enums.fmInfoStructureTypes.IncomesAndExpensesBudget Then
		NewRowIAE.Group = NStr("en='Income and expenses item groups';ru='Группы статей доходов и расходов'");
	EndIf;
	
	NewRowIAE.PictureIndex = 7;
	Query = New Query;
	Query.Text = "SELECT
	               |	fmItemGroups.Ref AS Group1,
	               |	fmItemGroups.Code AS ItemCode
	               |FROM
	               |	Catalog.fmItemGroups AS fmItemGroups
	               |WHERE
	               |	NOT fmItemGroups.Ref IN (&ExcludedList)
	               |	AND fmItemGroups.ItemType = &ItemType
	               |	AND NOT fmItemGroups.DeletionMark
	               |TOTALS BY
	               |	Group1 Hierarchy";
	If Object.StructureType = Enums.fmInfoStructureTypes.CashflowBudget Then
		Query.SetParameter("ItemType",Enums.fmBudgetOperationTypes.Cashflows);
	ElsIf Object.StructureType = Enums.fmInfoStructureTypes.IncomesAndExpensesBudget Then
		Query.SetParameter("ItemType",Enums.fmBudgetOperationTypes.IncomesAndExpenses);
	EndIf;
	
	Query.SetParameter("ExcludedList", ExcludedItemGroupsList);
	ItemGroupsUnloadTreeIAE = Query.Execute().Unload(QueryResultIteration.ByGroupsWithHierarchy);
	ItemGroupsUnloadTreeIAE.Columns.Group1.Name = "Group";
	
	For Each RowSource In ItemGroupsUnloadTreeIAE.Rows Do
		CopyTreeNode(NewRowIAE.Rows, RowSource, True, True);
	EndDo;
	ValueToFormAttribute(TreeObject, "FillingItemsTree");
	Items.FillingItemsTreeGroup.ReadOnly = True;
	
EndProcedure

&AtServer
Function GetItemsListInPresentationTree(LevelRows, ListForFilling)
	
	For Each RowItem In LevelRows Do
		
		If (RowItem.GroupType = New TypeDescription("CatalogRef.fmIncomesAndExpensesItems") OR RowItem.GroupType = New TypeDescription("CatalogRef.fmCashflowItems")) AND NOT RowItem.IsFormulaItem Then
			ListForFilling.Add(RowItem.Analytics);
		EndIf;
		
		IntermediateList = GetItemsListInPresentationTree(RowItem.Rows, ListForFilling);
		
	EndDo;
	
	Return ListForFilling;
	
EndFunction

&AtServer
Function GetItemGroupsListInPresentationTree(LevelRows, ListForFilling)
	
	For Each RowItem In LevelRows Do
		
		If RowItem.GroupType = New TypeDescription("CatalogRef.fmItemGroups") AND NOT RowItem.IsFormulaItem Then
			ListForFilling.Add(RowItem.Analytics);
		EndIf;
		
		IntermediateList = GetItemGroupsListInPresentationTree(RowItem.Rows, ListForFilling);
		
	EndDo;
	
	Return ListForFilling;
	
EndFunction

&AtServer
Procedure CopyTreeNode(DestinationRows, NodeSource, HierarchyWithItems, ItemsGroup = False)
	NewLine = DestinationRows.Add();
	FillPropertyValues(NewLine, NodeSource);
	
	//настроим картинку строки
	If (TypeOf(NodeSource.Group) = Type("CatalogRef.fmIncomesAndExpensesItems") ) OR (TypeOf(NodeSource.Group) = Type("CatalogRef.fmCashflowItems")) Then
		If NodeSource.Group.Predefined Then
			NewLine.PictureIndex = 5;
		ElsIf NodeSource.Group.IsFolder Then
			NewLine.PictureIndex = 0;
			NewLine.IsFolder = True;
		Else
			NewLine.PictureIndex = 3;
		EndIf;
	ElsIf TypeOf(NodeSource.Group) = Type("CatalogRef.fmItemGroups") Then
		NewLine.PictureIndex = 0;
	EndIf;
	
	//для группы статей добавим еще и статьи в нее входщие
	If ItemsGroup Then
		Query = New Query;
		Query.Text = "SELECT
		|	fmItemGroupsItems.Item AS Group1,
		|	fmItemGroupsItems.Item.Code AS ItemCode
		|FROM
		|	Catalog.fmItemGroups.Items AS fmItemGroupsItems
		|WHERE
		|	fmItemGroupsItems.Ref = &ItemsGroup";
		
		Query.SetParameter("ItemsGroup", NodeSource.Group);
		ItemsList = Query.Execute().Unload();
		ItemsList.Columns.Group1.Name = "Group";
		For Each RowItem In ItemsList Do
			CopyTreeNode(NewLine.Rows, RowItem, True);
		EndDo;
	EndIf;
	
	If TypeOf(NodeSource) = Type("ValueTableRow") Then
		Return
	EndIf;
	
	For Each It In NodeSource.Rows Do
		//Если (ТипЗнч(эл.Группировка) = Тип("СправочникСсылка.уфСтатьиДоходовИРасходов") И ПереключательТипСтруктуры =ПолучитьПеречислениеБюджетДиР()) ИЛИ (ТипЗнч(эл.Группировка) = Тип("СправочникСсылка.уфСтатьиДвиженияДенежныхСредств") И ПереключательТипСтруктуры =ПолучитьПеречислениеБюджетДДС()) Тогда
		If HierarchyWithItems Then
			If NOT It.Group = It.Parent.Group Then
				CopyTreeNode (NewLine.Rows, It, HierarchyWithItems, ItemsGroup);
			EndIf;
		Else
			CopyTreeNode (NewLine.Rows, It, HierarchyWithItems, ItemsGroup);
		EndIf;
		//КонецЕсли;
	EndDo; 
	
	
EndProcedure

&AtServer
Procedure RefreshAtServer()
	ClearFillingTreeAtServer();
	FillSourcesItemsTree();
EndProcedure

&AtClient
Procedure CollapseAllTreeItems(TreeItems, FormTreeTitle)
	
	For Each Item In TreeItems Do
		CollapseAllTreeItems(Item.GetItems(), FormTreeTitle);
		ID = Item.GetID();
		Items[FormTreeTitle].Collapse(ID);
		//СвернутьВсеЭлементыДерева(Элемент.ПолучитьЭлементы(), НазваниеДереваФормы)
	EndDo;
	
EndProcedure

&AtClient
Procedure ExpandAllTreeItems(TreeItems, FormTreeTitle)
	For Each Item In TreeItems Do
		ID = Item.GetID();
		Items[FormTreeTitle].Expand(ID, False);
		ExpandAllTreeItems(Item.GetItems(), FormTreeTitle)
	EndDo;
EndProcedure

&AtServer
Procedure RefreshConditionalAppearance()
	ConditionalAppearance.Items.Clear();
	TreeFromForm = FormAttributeToValue("StructurePresentationTree", Type("ValueTree"));
	
	//теперь назначим УО дереву исходных данных.
	CAItem = ConditionalAppearance.Items.Add();
	AppearanceField = CAItem.Fields.Items.Add();
	AppearanceField.Field = New DataCompositionField("FillingItemsTreeGroup");
	FilterItem = CAItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	FilterItem.LeftValue = New DataCompositionField("FillingItemsTree.Group.");
	FilterItem.ComparisonType = DataCompositionComparisonType.InList;
	AppearanceList = New ValueList;
	AppearanceList.Add(NStr("en='Income and expenses items';ru='Статьи доходов и расходов'"));
	AppearanceList.Add(NStr("en='Income and expenses item groups';ru='Группы статей доходов и расходов'"));
	AppearanceList.Add(NStr("en='Cash flow items';ru='Статьи ДДС'"));
	AppearanceList.Add(NStr("en='Cash flow groups';ru='Группы ДДС'"));
	AppearanceList.Add(NStr("en='Typed groupings';ru='Типизированные группировки'"));
	FilterItem.RightValue = AppearanceList;
	CAItem.Appearance.SetParameterValue("Font", New Font(,10, True, False));
	
	//и УО для флагов дерева справа.
	//1
	CAItem2 = ConditionalAppearance.Items.Add();
	AppearanceField2 = CAItem2.Fields.Items.Add();
	AppearanceField2.Field = New DataCompositionField("StructurePresentationTreeByFormula");
	
	FilterItem2 = CAItem2.Filter.Items.Add(Type("DataCompositionFilterItem"));
	FilterItem2.LeftValue = New DataCompositionField("StructurePresentationTree.FixedSection");
	FilterItem2.ComparisonType = DataCompositionComparisonType.Equal;
	FilterItem2.RightValue = True;
	
	CAItem2.Appearance.SetParameterValue("ReadOnly", True);
	
	//2
	CAItem3 = ConditionalAppearance.Items.Add();
	
	FilterItem3 = CAItem3.Filter.Items.Add(Type("DataCompositionFilterItem"));
	FilterItem3.LeftValue = New DataCompositionField("StructurePresentationTree.GroupType");
	FilterItem3.ComparisonType = DataCompositionComparisonType.Equal;
	FilterItem3.RightValue = New TypeDescription("CatalogRef.fmIncomesAndExpensesItems");
	
	CAItem3.Appearance.SetParameterValue("ReadOnly", True);
	
	//2.1
	CAItem3 = ConditionalAppearance.Items.Add();
	
	FilterItem3 = CAItem3.Filter.Items.Add(Type("DataCompositionFilterItem"));
	FilterItem3.LeftValue = New DataCompositionField("StructurePresentationTree.GroupType");
	FilterItem3.ComparisonType = DataCompositionComparisonType.Equal;
	FilterItem3.RightValue = New TypeDescription("CatalogRef.fmCashflowItems");
	
	CAItem3.Appearance.SetParameterValue("ReadOnly", True);
	//3
	CAItem4 = ConditionalAppearance.Items.Add();
	AppearanceField2_4 = CAItem4.Fields.Items.Add();
	AppearanceField2_4.Field = New DataCompositionField("StructurePresentationTreeByFormula");
	
	FilterItem4 = CAItem4.Filter.Items.Add(Type("DataCompositionFilterItem"));
	FilterItem4.LeftValue = New DataCompositionField("StructurePresentationTree.GroupType");
	FilterItem4.ComparisonType = DataCompositionComparisonType.Equal;
	FilterItem4.RightValue = New TypeDescription("CatalogRef.fmItemGroups");
	
	CAItem4.Appearance.SetParameterValue("ReadOnly", True);
	
	//для группировок с типом строка, т.е. "+" или "-" также не будем выводить эти флаги. 
	CAItem6 = ConditionalAppearance.Items.Add();
	AppearanceField6 = CAItem6.Fields.Items.Add();
	AppearanceField6.Field = New DataCompositionField("StructurePresentationTreeByFormula");
	AppearanceField6_2 = CAItem6.Fields.Items.Add();
	AppearanceField6_2.Field = New DataCompositionField("StructurePresentationTreeShowWith");
	
	FilterItem6 = CAItem6.Filter.Items.Add(Type("DataCompositionFilterItem"));
	FilterItem6.LeftValue = New DataCompositionField("StructurePresentationTree.IsFormulaItem");
	FilterItem6.ComparisonType = DataCompositionComparisonType.Equal;
	FilterItem6.RightValue = True;
	
	//ЭлементУО6.Оформление.УстановитьЗначениеПараметра("ТолькоПросмотр", Истина);
	CAItem6.Appearance.SetParameterValue("Show", False);
	
	//дальше не будем показывать лишние флаги.
	
	//**** не показываем для статей ДиР и ДДС.
	CAItem21 = ConditionalAppearance.Items.Add();
	
	FilterItem21 = CAItem21.Filter.Items.Add(Type("DataCompositionFilterItem"));
	FilterItem21.LeftValue = New DataCompositionField("StructurePresentationTree.GroupType");
	FilterItem21.ComparisonType = DataCompositionComparisonType.Equal;
	FilterItem21.RightValue = New TypeDescription("CatalogRef.fmIncomesAndExpensesItems");
	CAItem21.Appearance.SetParameterValue("Show", False);
	
	CAItem22 = ConditionalAppearance.Items.Add();
	
	FilterItem21 = CAItem21.Filter.Items.Add(Type("DataCompositionFilterItem"));
	FilterItem21.LeftValue = New DataCompositionField("StructurePresentationTree.GroupType");
	FilterItem21.ComparisonType = DataCompositionComparisonType.Equal;
	FilterItem21.RightValue = New TypeDescription("CatalogRef.fmCashflowItems");
	CAItem21.Appearance.SetParameterValue("Show", False);
	
	
	//**** не показываем значения флагов для групп статей.
	CAItem61 = ConditionalAppearance.Items.Add();
	
	FilterItem61 = CAItem61.Filter.Items.Add(Type("DataCompositionFilterItem"));
	FilterItem61.LeftValue = New DataCompositionField("StructurePresentationTree.GroupType");
	FilterItem61.ComparisonType = DataCompositionComparisonType.Equal;
	FilterItem61.RightValue = New TypeDescription("CatalogRef.fmItemGroups");
	CAItem61.Appearance.SetParameterValue("Show", False);
	
	//**** у формульных строк - элементов структуры не доступен флаг open group in reports.
	CAItem62 = ConditionalAppearance.Items.Add();
	
	FilterItem62 = CAItem62.Filter.Items.Add(Type("DataCompositionFilterItem"));
	FilterItem62.LeftValue = New DataCompositionField("StructurePresentationTree.ByFormula");
	FilterItem62.ComparisonType = DataCompositionComparisonType.Equal;
	FilterItem62.RightValue = True;
	CAItem62.Appearance.SetParameterValue("ReadOnly", True);
	
	//видимость колонки по формуле убрать для бюджета доходов-расходов.
	CAItem7 = ConditionalAppearance.Items.Add();
	AppearanceField7 = CAItem7.Fields.Items.Add();
	AppearanceField7.Field = New DataCompositionField("StructurePresentationTreeByFormula");
	
	FilterItem7 = CAItem7.Filter.Items.Add(Type("DataCompositionFilterItem"));
	FilterItem7.LeftValue = New DataCompositionField("Object.StructureType");
	FilterItem7.ComparisonType = DataCompositionComparisonType.Equal;
	FilterItem7.RightValue = Enums.fmInfoStructureTypes.IncomesAndExpensesBudget;
	
	CAItem7.Appearance.SetParameterValue("Visible", False);
	
	//видимость колонки по формуле убрать для бюджета ДДС.
	CAItem7 = ConditionalAppearance.Items.Add();
	AppearanceField7 = CAItem7.Fields.Items.Add();
	AppearanceField7.Field = New DataCompositionField("StructurePresentationTreeByFormula");
	
	FilterItem7 = CAItem7.Filter.Items.Add(Type("DataCompositionFilterItem"));
	FilterItem7.LeftValue = New DataCompositionField("Object.StructureType");
	FilterItem7.ComparisonType = DataCompositionComparisonType.Equal;
	FilterItem7.RightValue = Enums.fmInfoStructureTypes.CashflowBudget;
	
	CAItem7.Appearance.SetParameterValue("Visible", False);
	
	//если тип группировки статья или группа статей, то мы их не выделяем жирным и КурсивныйШрифтным либо цветным.
	CAItem14 = ConditionalAppearance.Items.Add();
	AppearanceField14 = CAItem14.Fields.Items.Add();
	AppearanceField14.Field = New DataCompositionField("StructurePresentationTreeGroup");
	FilterItem14 = CAItem14.Filter.Items.Add(Type("DataCompositionFilterItem"));
	FilterItem14.LeftValue = New DataCompositionField("StructurePresentationTree.GroupType");
	FilterItem14.ComparisonType = DataCompositionComparisonType.Equal;
	FilterItem14.RightValue = New TypeDescription("CatalogRef.fmIncomesAndExpensesItems");
	CAItem14.Appearance.SetParameterValue("TextColor", New Color(0,0,0)); //черный
	
	CAItem15 = ConditionalAppearance.Items.Add();
	AppearanceField15 = CAItem15.Fields.Items.Add();
	AppearanceField15.Field = New DataCompositionField("StructurePresentationTreeGroup");
	FilterItem15 = CAItem15.Filter.Items.Add(Type("DataCompositionFilterItem"));
	FilterItem15.LeftValue = New DataCompositionField("StructurePresentationTree.GroupType");
	FilterItem15.ComparisonType = DataCompositionComparisonType.Equal;
	FilterItem15.RightValue = New TypeDescription("CatalogRef.fmItemGroups");
	CAItem15.Appearance.SetParameterValue("TextColor", New Color(0,0,0)); //черный
	
	
	CAItem16 = ConditionalAppearance.Items.Add();
	AppearanceField16 = CAItem16.Fields.Items.Add();
	AppearanceField16.Field = New DataCompositionField("StructurePresentationTreeGroup");
	FilterItem16 = CAItem16.Filter.Items.Add(Type("DataCompositionFilterItem"));
	FilterItem16.LeftValue = New DataCompositionField("StructurePresentationTree.GroupType");
	FilterItem16.ComparisonType = DataCompositionComparisonType.Equal;
	FilterItem16.RightValue = New TypeDescription("CatalogRef.fmCashflowItems");
	CAItem16.Appearance.SetParameterValue("TextColor", New Color(0,0,0)); //черный
	//колонку "раскрывать группу" прячем для видов отчетов типа ДиР
	//РазвернутьФиксированныеГруппировкиКлиент();
	AssignToEveryCARow(TreeFromForm.Rows);
	
EndProcedure

//процедура устанавливает условное оформление дереву представления структуры
&AtServer
Procedure AssignToEveryCARow(OneLevelTreeRows)
	For Each NextGroup In OneLevelTreeRows Do
		GroupType = NextGroup.GroupType; 
		If GroupType = New TypeDescription("CatalogRef.fmInfoStructuresSections") AND NOT NextGroup.IsFormulaItem Then
			CAItem = ConditionalAppearance.Items.Add();
			AppearanceField = CAItem.Fields.Items.Add();
			AppearanceField.Field = New DataCompositionField("StructurePresentationTreeGroup");
			FilterItem = CAItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
			FilterItem.LeftValue = New DataCompositionField("StructurePresentationTree.UID");
			FilterItem.ComparisonType = DataCompositionComparisonType.Equal;
			FilterItem.RightValue = NextGroup.UID;
			If NOT NextGroup.TextColor = "" Then
				FieldColor = GetAppearanceColor(NextGroup.TextColor);
				CAItem.Appearance.SetParameterValue("TextColor", FieldColor);
			EndIf;
			CAItem.Appearance.SetParameterValue("Font", New Font(,10,NextGroup.BoldFont, NextGroup.ItalicFont));
		ElsIf GroupType = New TypeDescription("String") Then
			If (NextGroup.Group = "INCOMES" OR NextGroup.Group = "EXPENSES" OR NextGroup.Group = "DEPOSIT" OR 
				NextGroup.Group = "Additional Information" OR NextGroup.Group = "SUMMARY INFORMATION" OR
				NextGroup.Group = "INFLOWS" OR NextGroup.Group = "OUTFLOWS" OR NextGroup.Group = "CONTRIBUTION")
				AND NextGroup.FixedSection Then
				
				CAItem = ConditionalAppearance.Items.Add();
				AppearanceField = CAItem.Fields.Items.Add();
				AppearanceField.Field = New DataCompositionField("StructurePresentationTreeGroup");
				FilterItem = CAItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
				FilterItem.LeftValue = New DataCompositionField("StructurePresentationTree.Group");
				FilterItem.ComparisonType = DataCompositionComparisonType.Equal;
				FilterItem.RightValue = NextGroup.Group;
			EndIf;
		EndIf;
		AssignToEveryCARow(NextGroup.Rows);
	EndDo;
EndProcedure

&AtServerNoContext
Function GetAppearanceColor(ColorFromConditionalAppearance)
	ReaderXML 		= New XMLReader;
	ObjectTypeXDTO	= XDTOFactory.Type("http://v8.1c.ru/8.1/data/ui","Color");
	ReaderXML.SetString(ColorFromConditionalAppearance);
	ObjectXDTO		=	XDTOFactory.ReadXML(ReaderXML, ObjectTypeXDTO);
	Serializer	=	New XDTOSerializer(XDTOFactory);
	Return	Serializer.ReadXDTO(ObjectXDTO);
EndFunction

&AtServerNoContext
Function GetColorFromCatalog(TextColor) 
	If NOT TextColor = "" Then
		ReaderXML 		= New XMLReader;
		ObjectTypeXDTO	= XDTOFactory.Type("http://v8.1c.ru/8.1/data/ui","Color");
		ReaderXML.SetString(TextColor);
		ObjectXDTO		=	XDTOFactory.ReadXML(ReaderXML, ObjectTypeXDTO);
		Serializer	=	New XDTOSerializer(XDTOFactory);
		Return	Serializer.ReadXDTO(ObjectXDTO);
	Else
		Return New Color(0,0,0);
	EndIf;
EndFunction

&AtServer
Function CheckChildItemsOnItemPresence(SeacrhItem, UIDSearch)
	StructureTree = FormAttributeToValue("StructurePresentationTree");
	SearchStr = New Structure;
	SearchStr.Insert("UID", UIDSearch);
	SearchStr.Insert("FixedSection", False);
	RowsWithUID = StructureTree.Rows.FindRows(SearchStr, True);
	IsItem = False;
	FindChildItemsWithItemRecursively(StructureTree, RowsWithUID, SeacrhItem, UIDSearch, IsItem);
	If IsItem Then
		Return True;
	EndIf;
	Return False;
EndFunction

&AtServer
Procedure FindChildItemsWithItemRecursively(StructureTree, RowsWithUID, SeacrhItem, UIDSearch, IsItem)
	For Each UIDString In RowsWithUID Do
		//в найденных проверяем вложенные элементы
		If UIDString.Analytics = SeacrhItem Then
			//поиск прекращаем
			IsItem =  True;
			Break;
		Else
			For Each ChildRow In UIDString.Rows Do 
				SearchStr = New Structure;
				SearchStr.Insert("UID", ChildRow.UID);
				SearchStr.Insert("FixedSection", False);
				SearchStr.Insert("IsFormulaItem", False);
				If ChildRow.UID = New UUID("00000000-0000-0000-0000-000000000000") AND (ChildRow.GroupType = New TypeDescription("CatalogRef.fmIncomesAndExpensesItems") OR ChildRow.GroupType = New TypeDescription("CatalogRef.fmItemGroups") OR ChildRow.GroupType = New TypeDescription("CatalogRef.fmCashflowItems")) Then 
					If ChildRow.Analytics = SeacrhItem Then
						IsItem = True;
						Break;
					EndIf;
					Continue;
				ElsIf ChildRow.UID = New UUID("00000000-0000-0000-0000-000000000000") AND ChildRow.GroupType = New TypeDescription("String") Then 
					//в формульных + и - идем глубже по элементам
					For Each FRow In ChildRow.Rows Do
						SearchStr = New Structure;
						SearchStr.Insert("UID", FRow.UID);
						SearchStr.Insert("FixedSection", False);
						SearchStr.Insert("IsFormulaItem", False);
						NextSearch = StructureTree.Rows.FindRows(SearchStr, True);
						FindChildItemsWithItemRecursively(StructureTree, NextSearch, SeacrhItem, FRow.UID, IsItem);
					EndDo;
				Else
					NextSearch = StructureTree.Rows.FindRows(SearchStr, True);
					FindChildItemsWithItemRecursively(StructureTree, NextSearch, SeacrhItem, ChildRow.UID, IsItem);
				EndIf;
			EndDo;
		EndIf;
	EndDo;
EndProcedure

&AtClient 
Function TransferTreeBranchInStructure(AttributeTree, Receiver, Source, RefreshOrder = True)
	
	Var NewLine, ReverseIndex, ChildRowsCount;
	
	// Источник может быть уже перенесен
	// Это происходит если выделены несколько элементов
	// одной и той же ветви дерева на разных уровнях иерархии
	If Source = Undefined Then
		Return Undefined;
	EndIf;
	If Receiver = Undefined Then 
		NewLine = StructurePresentationTree.GetItems().Add();
	Else
		NewLine = Receiver.GetItems().Add();
	EndIf;
	If RefreshOrder Then
		//проставим порядок как максимальный на текущем уровне 
		CurRow = Items.StructurePresentationTree.CurrentRow;
		TreeCurData = StructurePresentationTree.FindByID(CurRow);
		If Receiver = Undefined Then 
			MaxNumberBO = DefineMaximunmNumberBO(StructurePresentationTree.GetItems());//ДеревоПредставленияСтруктуры.ПолучитьЭлементы());
		Else
			MaxNumberBO = DefineMaximunmNumberBO(Receiver.GetItems());//ДеревоПредставленияСтруктуры.ПолучитьЭлементы());
		EndIf;
		NewLine.Order = MaxNumberBO + 1;
	EndIf;
	
	FillPropertyValues(NewLine, Source);
	
	If RefreshOrder Then
		NewLine.Order = MaxNumberBO + 1;
	EndIf;
	
	
	If Receiver = Undefined Then
		NewLine.StructureSectionType = Undefined;
		NewLine.GroupParent = "";
	Else
		NewLine.StructureSectionType = Receiver.StructureSectionType;
		NewLine.GroupParent = Receiver.Group;
	EndIf;
	
	ChanArray = New Array;
	ChanArray.Add(NewLine);
	ChanArray.Add(Source);
	AddChangedOrDeletedItemsInList(ChanArray);
	
	ChildRowsCount = Source.GetItems().Count();
	For ReverseIndex = 1 To ChildRowsCount Do
		ChildRow = Source.GetItems()[0];
		// [КолПодчиненныхСтрок - ОбратныйИндекс];
		TransferTreeBranchInStructure(AttributeTree, NewLine, ChildRow, False);
	EndDo;
	
	Parent = Source.GetParent();
	If Parent = Undefined Then
		StructurePresentationTree.GetItems().Delete(Source);
	Else
		Parent.GetItems().Delete(Source);
	EndIf;
	
	Return NewLine;
	
EndFunction

&AtClient
Function CopyTreeBranchInStructureInFormula(AttributeTree, Receiver, Source, DeleteFromSource)
	
	Var NewLine, ReverseIndex, ChildRowsCount;
	
	// Источник может быть уже перенесен
	// Это происходит если выделены несколько элементов
	// одной и той же ветви дерева на разных уровнях иерархии
	If Source = Undefined Then
		Return Undefined;
	EndIf;
	
	NewLine = Receiver.GetItems().Add();
	
	MaxNumberBO = DefineMaximunmNumberBO(Receiver.GetItems());//ДеревоПредставленияСтруктуры.ПолучитьЭлементы());
	//НоваяСтрока.Порядок = МаксНомерПП + 1;
	
	FillPropertyValues(NewLine, Source);
	NewLine.Order = MaxNumberBO + 1;
	//НоваяСтрока.Родитель = Приемник	
	NewLine.PictureIndex = 0;
	NewLine.StructureSectionType = Receiver.StructureSectionType;
	NewLine.GroupParent = Receiver.GetParent().Group;
	NewLine.IsFormulaItem = True;
	NewLine.ByFormula = True;
	If NOT Source.Ref = Undefined Then
		If Source.IsFormulaItem Then
			NewLine.FormulaString = Source.FormulaString;
		ElsIf Source.GroupType = New TypeDescription("CatalogRef.fmIncomesAndExpensesItems") OR Source.GroupType = New TypeDescription("CatalogRef.fmCashflowItems") Then
			NewLine.FormulaString = Source.Analytics;
			NewLine.ItemCode = ReturnItemCode(Source.Analytics);
		Else
			NewLine.FormulaString = Source.Ref;
		EndIf;
	Else
		NewLine.FormulaString = Source.Group;
	EndIf;
	If Receiver.GetParent().Group = "(minus)" OR Receiver.Group = "(minus)" Then
		NewLine.FormulaMinus = True;
	Else
		NewLine.FormulaMinus = False;
	EndIf;
	
	ChanArray = New Array;
	ChanArray.Add(Receiver.GetParent());
	AddChangedOrDeletedItemsInList(ChanArray);
	
	//копирование аналогично переносу, только из источника строку не удаляем и внутренние реКурсивныйШрифтно не копируем
	If DeleteFromSource Then
		Source.GetParent().GetItems().Delete(Source);
	EndIf;
	
	Return NewLine;
	
EndFunction

&AtClient
Function CheckTransferAvailable(TransferedItem, VAL NewParent)
	
	While NOT NewParent = Undefined Do
		If TransferedItem = NewParent Then
			Return False;
		EndIf;
		NewParent = NewParent.GetParent();
	EndDo;
	
	Return True;
	
EndFunction

&AtClient
Procedure ExecuteRowInStructureTransfer(SourceTreeRow,SourceItem, DestinationRow, IncomesAndExpenses)
	CurRow = Items.StructurePresentationTree.CurrentRow;
	TreeCurData = DestinationRow;//ДеревоПредставленияСтруктуры.НайтиПоИдентификатору(ТекСтрока);
	//МаксНомерПП = ОпределитьМаксимальныйНомерПП(ТекДанныеДерева.ПолучитьРодителя().ПолучитьЭлементы());//ДеревоПредставленияСтруктуры.ПолучитьЭлементы());
	MaxNumberBO = 0;
	TransferedSuccessfully = False;
	If TypeOf(SourceItem) = Type("CatalogRef.fmIncomesAndExpensesItems") OR TypeOf(SourceItem) = Type("CatalogRef.fmCashflowItems") Then
		
		If DestinationRow.FixedSection Then
			//статьи не добавляем непосредственно в фиксированные разделы
			Return;
		ElsIf DestinationRow.GroupType = New TypeDescription("CatalogRef.fmIncomesAndExpensesItems") OR DestinationRow.GroupType = New TypeDescription("CatalogRef.fmCashflowItems") Then
			//добавляем статью к тому же родителю (если у него еще такой нет)
			MaxNumberBO = DefineMaximunmNumberBO(TreeCurData.GetParent().GetItems());
			ParentToAdd = DestinationRow.GetParent();
			NRow = AddRowItemInStructure(ParentToAdd, SourceItem, MaxNumberBO);
		ElsIf DestinationRow.GroupType = New TypeDescription("CatalogRef.fmInfoStructuresSections") Then
			If DestinationRow.IsFormulaItem Then
				MaxNumberBO = DefineMaximunmNumberBO(TreeCurData.GetParent().GetItems());
				NRow = AddRowItemInStructure(DestinationRow.GetParent(), SourceItem, MaxNumberBO);
			Else
				MaxNumberBO = DefineMaximunmNumberBO(TreeCurData.GetItems());
				NRow = AddRowItemInStructure(DestinationRow, SourceItem, MaxNumberBO);
			EndIf;
		ElsIf DestinationRow.IsFormulaItem Then
			If DestinationRow.GroupType = New TypeDescription("String") Then
				MaxNumberBO = DefineMaximunmNumberBO(TreeCurData.GetItems());
				NRow = AddRowItemInStructure(DestinationRow, SourceItem, MaxNumberBO);
			Else
				MaxNumberBO = DefineMaximunmNumberBO(TreeCurData.GetParent().GetItems());
				NRow = AddRowItemInStructure(DestinationRow.GetParent(), SourceItem, MaxNumberBO);
			EndIf;
		EndIf;
		
		If NOT NRow = Undefined Then
			Items.StructurePresentationTree.CurrentRow = NRow.GetID();
			TransferedSuccessfully = True;
		EndIf;
		
	ElsIf TypeOf(SourceItem) = Type("CatalogRef.fmItemGroups") Then
		//добавим в ТЧ тсатьи
		If DestinationRow.FixedSection Then
			//статьи не добавляем непосредственно в фиксированные разделы
			Return;
		ElsIf DestinationRow.GroupType = New TypeDescription("CatalogRef.fmIncomesAndExpensesItems") OR DestinationRow.GroupType = New TypeDescription("CatalogRef.fmCashflowItems")Then
			//добавляем статью к тому же родителю (если у него еще такой нет)
			MaxNumberBO = DefineMaximunmNumberBO(TreeCurData.GetParent().GetItems());
			ParentToAdd = DestinationRow.GetParent();
			NRow = AddRowItemInStructure(ParentToAdd, SourceItem, MaxNumberBO);
			ParentToAdd = NRow;
		ElsIf DestinationRow.GroupType = New TypeDescription("CatalogRef.fmInfoStructuresSections") Then
			MaxNumberBO = DefineMaximunmNumberBO(TreeCurData.GetItems());
			NRow = AddRowItemInStructure(DestinationRow, SourceItem, MaxNumberBO);
			ParentToAdd = NRow;
		EndIf;
		
		If NOT NRow = Undefined Then
			Items.StructurePresentationTree.CurrentRow = NRow.GetID();
			TransferedSuccessfully = True;
		EndIf;
		
	ElsIf TypeOf(SourceItem) = Type("EnumRef.fmBudgetFlowOperationTypes") Then
		
		If DestinationRow = Undefined Then
			//это Внешнийовый отчет
			NewStructureRow = StructurePresentationTree.GetItems().Add();
			MaxNumberBO = DefineMaximunmNumberBO(StructurePresentationTree.GetItems());
		Else
			If DestinationRow.FixedSection Then
				StrItems = DestinationRow.GetItems();
				NewStructureRow = StrItems.Add();
				MaxNumberBO = DefineMaximunmNumberBO(DestinationRow.GetItems());
			ElsIf DestinationRow.GroupType = New TypeDescription("CatalogRef.fmIncomesAndExpensesItems") OR DestinationRow.GroupType = New TypeDescription("CatalogRef.fmCashflowItems") OR DestinationRow.GroupType = New TypeDescription("CatalogRef.fmItemGroups") Then
				//ищем родителя и добавляем в него
				ParentIt = DestinationRow.GetParent();
				StrItems = ParentIt.GetItems();
				NewStructureRow = StrItems.Add();
				MaxNumberBO = DefineMaximunmNumberBO(DestinationRow.GetParent().GetItems());
			ElsIf DestinationRow.GroupType = New TypeDescription("CatalogRef.fmInfoStructuresSections") AND NOT DestinationRow.IsFormulaItem Then
				StrItems = DestinationRow.GetItems();
				NewStructureRow = StrItems.Add();
				MaxNumberBO = DefineMaximunmNumberBO(DestinationRow.GetItems());
			ElsIf DestinationRow.GroupType = New TypeDescription("CatalogRef.fmInfoStructuresSections") AND DestinationRow.IsFormulaItem Then
				ParentIt = DestinationRow.GetParent();
				StrItems = ParentIt.GetItems();
				NewStructureRow = StrItems.Add();
				MaxNumberBO = DefineMaximunmNumberBO(DestinationRow.GetParent().GetItems());
			ElsIf DestinationRow.IsFormulaItem Then
				StrItems = DestinationRow.GetItems();
				NewStructureRow = StrItems.Add();
				MaxNumberBO = DefineMaximunmNumberBO(DestinationRow.GetItems());
			EndIf;
		EndIf;
		
		If NewStructureRow = Undefined Then
			Return;
		EndIf;
		
		//Элементы.ДеревоПредставленияСтруктуры.ТекущаяСтрока = НоваяСтрокаСтруктуры;
		
		//и теперь заполняем реквизиты новой строки
		NewStructureRow.Group = String(SourceItem);
		If DestinationRow = Undefined Then
			NewStructureRow.GroupParent = "";
		Else
			If DestinationRow.GetParent() = Undefined Then
				NewStructureRow.GroupParent = "";
			Else
				NewStructureRow.GroupParent = String(DestinationRow.GetParent().Group);
			EndIf;
		EndIf;
		If IncomesAndExpenses = Undefined Then
			NewStructureRow.StructureSectionType = Undefined;
		Else
			If Object.StructureType=PredefinedValue("Enum.fmInfoStructureTypes.IncomesAndExpensesBudget") Then
				NewStructureRow.StructureSectionType = ?(IncomesAndExpenses = 0, PredefinedValue("Enum.fmBudgetFlowOperationTypes.Incomes"), PredefinedValue("Enum.fmBudgetFlowOperationTypes.Expenses"));
			Else
				NewStructureRow.StructureSectionType = ?(IncomesAndExpenses = 0, PredefinedValue("Enum.fmBudgetFlowOperationTypes.Inflow"), PredefinedValue("Enum.fmBudgetFlowOperationTypes.Outflow"));
			EndIf;
		EndIf;
		
		If NOT DestinationRow = Undefined Then
			If DestinationRow.IsFormulaItem Then
				NewStructureRow.FormulaMinus = DestinationRow.FormulaMinus;
				NewStructureRow.FormulaString = SourceItem;
			EndIf;
		EndIf;
		
		//перенесем еще и цвет и жирность в дерево справа
		If SourceItem = PredefinedValue("Enum.fmBudgetFlowOperationTypes.Accounts") 
			OR SourceItem = PredefinedValue("Enum.fmBudgetFlowOperationTypes.PassUpFromYellow") Then
			//жёлтый
			GroupColor = New Color(255,165,0);
		ElsIf SourceItem = PredefinedValue("Enum.fmBudgetFlowOperationTypes.PassUpFromRed") 
			OR SourceItem = PredefinedValue("Enum.fmBudgetFlowOperationTypes.AccountsOfRed") Then
			//красный
			GroupColor = New Color(255,0,0);
		ElsIf SourceItem = PredefinedValue("Enum.fmBudgetFlowOperationTypes.PassUpFromGreen") Then
			//зелёный
			GroupColor = New Color(0,100,0);
		ElsIf SourceItem = PredefinedValue("Enum.fmBudgetFlowOperationTypes.PassUpFromBlue") Then
			//синий
			GroupColor = New Color(0,0,255);
		Else
			GroupColor = New Color(0,0,0);
		EndIf;
		
		//жирность
		NewStructureRow.BoldFont = True;
		
		//задаём цвет группировки		
		NewStructureRow.TextColor = ReturnChangeCurRowColor(GroupColor);
		
		NewStructureRow.IsFormulaItem = ?(DestinationRow = Undefined, False, DestinationRow.IsFormulaItem);
		NewStructureRow.Order = MaxNumberBO + 1;
		NewStructureRow.GroupType = New TypeDescription("CatalogRef.fmInfoStructuresSections");
		
		NewStructureRow.UID = New UUID;
		TransferedSuccessfully = True;
		Items.StructurePresentationTree.CurrentRow = NewStructureRow.GetID();
		//ОбновитьОтображениеДанных();
		RefreshConditionalAppearance();
	EndIf;
	
	If TransferedSuccessfully Then
		//удаляем строку из источника
		DeleteRowFromSource(SourceTreeRow);
	EndIf;
EndProcedure

&AtServerNoContext
Function ReturnGroupItemsArray(ItemsGroup)
	
	Query = New Query;
	Query.Text = "SELECT TOP 1
	               |	ClosingItemsGroupsItems.Item AS Item
	               |FROM
	               |	Catalog.fmItemGroups.Items AS ClosingItemsGroupsItems
	               |WHERE
	               |	ClosingItemsGroupsItems.Ref = &ItemsGroup";
	Query.SetParameter("ItemsGroup", ItemsGroup);
	Unloading = Query.Execute().Unload();
	//ТипыАналитики = уфБюджетирование.ПолучитьТипыАналитик(Выгрузка[0].Статья);
	//Если ТипЗнч(Выгрузка[0].Статья) = Тип("СправочникСсылка.уфСтатьиДоходовИРасходов") Тогда 
	//	ДДС = Ложь;
	//ИначеЕсли ТипЗнч(Выгрузка[0].Статья) = Тип("СправочникСсылка.уфСтатьиДвиженияДенежныхСредств") Тогда
	//	ДДС = Истина;
	//КонецЕсли;
	AnalyticsTypes = fmBudgeting.GetCustomAnalyticsSettings(Unloading[0].Item);
	Return AnalyticsTypes;
	
EndFunction

&AtClient
Function DefineMaximunmNumberBO(TreeRows, MaxNumberBO = 0)
	
	For Each String In TreeRows Do
		MaxNumberBO = ?(String.Order > MaxNumberBO, String.Order, MaxNumberBO);
		
	EndDo;
	
	Return MaxNumberBO;
	
EndFunction

&AtClient
Function AddRowItemInStructure(ParentToAdd, SourceItem, MaxNumberBO)
	
	NewTreeIt = Undefined;
	If ParentToAdd = Undefined Then
		Return Undefined;
	EndIf;
	
	ItemItems = ParentToAdd.GetItems();
	If TypeOf(SourceItem) <> Type("CatalogRef.fmItemGroups") Then
		//Аналитики = уфБюджетирование.ПолучитьТипыАналитик(ЭлементИсточника); //Пусть возвращает структуру
		//Если ТипЗнч(ЭлементИсточника) = Тип("СправочникСсылка.уфСтатьиДоходовИРасходов") Тогда 
		//	ДДС = Ложь;
		//ИначеЕсли ТипЗнч(ЭлементИсточника) = Тип("СправочникСсылка.уфСтатьиДвиженияДенежныхСредств") Тогда
		//	ДДС = Истина;
		//КонецЕсли;
		Analytics = fmBudgeting.GetCustomAnalyticsSettings(SourceItem);
	Else
		GroupAnalytics = ReturnGroupItemsArray(SourceItem);
	EndIf;
	NewTreeIt = ItemItems.Add();
	FillPropertyValues(NewTreeIt, ParentToAdd);
	NewTreeIt.PictureIndex = 0;
	NewTreeIt.Group = SourceItem;
	NewTreeIt.GroupParent = ParentToAdd.Group;
	NewTreeIt.UID = New UUID();
	If TypeOf(SourceItem) = Type("CatalogRef.fmIncomesAndExpensesItems") Then
		NewTreeIt.GroupType = New TypeDescription("CatalogRef.fmIncomesAndExpensesItems");
		NewTreeIt.Ref = SourceItem;
		NewTreeIt.ItemCode = ReturnItemCode(SourceItem);
		NewTreeIt.AnalyticsType1 = Analytics.AnalyticsType1;
		NewTreeIt.AnalyticsType2 = Analytics.AnalyticsType2;
		NewTreeIt.AnalyticsType3 = Analytics.AnalyticsType3;
		//Добавить
	ElsIf TypeOf(SourceItem) = Type("CatalogRef.fmItemGroups") Then
		NewTreeIt.GroupType = New TypeDescription("CatalogRef.fmItemGroups");
		NewTreeIt.Ref = SourceItem;
		NewTreeIt.ItemCode = ReturnItemCode(SourceItem);
		NewTreeIt.AnalyticsType1 = GroupAnalytics.AnalyticsType1;
		NewTreeIt.AnalyticsType2 = GroupAnalytics.AnalyticsType2;
		NewTreeIt.AnalyticsType3 = GroupAnalytics.AnalyticsType3;
	ElsIf TypeOf(SourceItem) = Type("CatalogRef.fmCashflowItems") Then
		NewTreeIt.GroupType = New TypeDescription("CatalogRef.fmCashflowItems");
		NewTreeIt.Ref = SourceItem;
		NewTreeIt.ItemCode = ReturnItemCode(SourceItem);
		NewTreeIt.AnalyticsType1 = Analytics.AnalyticsType1;
		NewTreeIt.AnalyticsType2 = Analytics.AnalyticsType2;
		NewTreeIt.AnalyticsType3 = Analytics.AnalyticsType3;
	EndIf;
	If NewTreeIt.IsFormulaItem Then
		NewTreeIt.FormulaString = SourceItem;
		NewTreeIt.FormulaMinus = ParentToAdd.FormulaMinus;
	EndIf;
	NewTreeIt.Analytics = SourceItem;
	NewTreeIt.Order = MaxNumberBO + 1;
	
	NodeID = ParentToAdd.GetID();	
	Items.StructurePresentationTree.Expand(NodeID);
	
	ChanArray = New Array;
	ChanArray.Add(ParentToAdd);
	AddChangedOrDeletedItemsInList(ChanArray);
	
	Return NewTreeIt;
EndFunction

&AtServerNoContext
Function ReturnItemCode(Item)
	Return Common.ObjectAttributeValue(Item, "Code");//статья.Код;
EndFunction

&AtClient
Function CopyTreeRow(Receiver, Source)
	
	Var NewLine, ReverseIndex, ChildRowsCount;
	
	// Источник может быть уже перенесен 
	// Это происходит если выделены несколько элементов 
	// одной и той же ветви дерева на разных уровнях иерархии 
	If Source = Undefined Then
		Return Undefined;
	EndIf;
	
	If NOT Receiver = Undefined Then
		NewLine = Receiver.GetItems().Add();
	EndIf;
	
	FillPropertyValues(NewLine, Source);
	
	ChildRowsCount = Source.GetItems().Count();
	
	For ReverseIndex = 1 To ChildRowsCount Do
		ChildRow = Source.GetItems()[ChildRowsCount - ReverseIndex];
		CopyTreeRow(NewLine, ChildRow);
	EndDo;
	
	Return NewLine;
	
EndFunction

&AtClient
Procedure DeleteCurrentItemInStructure()
	
	CurRow = Items.StructurePresentationTree.CurrentRow;
	If CurRow = Undefined Then 
		Return;
	EndIf;
	
	CancelDeletion = False;
	DeletedRow = "";
	SelectedArray = Items.StructurePresentationTree.SelectedRows;
	For Each SelectedRow In SelectedArray Do
		SelRowNumber = SelectedRow;
		SelectedRowData = StructurePresentationTree.FindByID(SelRowNumber);
		If SelectedRowData.FixedSection Then
			CommonClientServer.MessageToUser(NStr("en='You cannot delete a fixed section.';ru='Нельзя удалять фиксированный раздел!'"));
			CancelDeletion = True;
		EndIf;
		If SelectedRowData.GroupType = New TypeDescription("String") AND SelectedRowData.IsFormulaItem Then
			CommonClientServer.MessageToUser(NStr("en='You cannot delete groupings (plus), (minus).';ru='Нельзя удалять группировки <+> и <->!'"));
			CancelDeletion = True;
		EndIf;
		
		Parent = SelectedRowData.GetParent();
		DeletedRow = DeletedRow + SelectedRowData.Group + ", "
	EndDo;
	
	If CancelDeletion Then
		Return;
	EndIf;
	
	CurData = Items.StructurePresentationTree.CurrentData;
	
	IDCurStructureItem = ThisForm.StructurePresentationTree.FindByID(CurRow);
	Parent = IDCurStructureItem.GetParent();
	
	ShowQueryBox(New NotifyDescription("DeleteCurrentItemInStructureEnd", ThisObject), NStr("en='Do you want to delete the structure row(s)?';ru='Удалить строку(строки) структуры '") + "<" + DeletedRow + "> ?" , QuestionDialogMode.YesNo);
	
EndProcedure

&AtClient
Procedure DeleteCurrentItemInStructureEnd(QueryResult, AdditionalParameters) Export
	
	If QueryResult = DialogReturnCode.Yes Then
		//перед удалением запомним индекс элемента в коллекции
		
		AddChangedOrDeletedItemsInList(, True);
		
		//отсортируем строки по убыванию индексов чтобы корректно удалять
		SelRowsArray = Items.StructurePresentationTree.SelectedRows;
		SelRowsList = New ValueList;
		For Each SelectedRow In SelRowsArray Do
			SelRowsList.Add(SelectedRow);
		EndDo;
		SelRowsList.SortByValue(SortDirection.DESC);
		SelRowsArray = SelRowsList.UnloadValues();
		
		For Each SelectedRow In SelRowsArray Do
			
			SelRowNumber = SelectedRow;
			SelectedRowData = StructurePresentationTree.FindByID(SelRowNumber);
			IDCurStructureItem = SelectedRowData;
			Parent = SelectedRowData.GetParent();
			If Parent = Undefined Then
				OneLevelItems = StructurePresentationTree.GetItems();
			Else
				OneLevelItems = Parent.GetItems();
			EndIf;
			DeletedIndex = OneLevelItems.IndexOf(IDCurStructureItem);
			//теперь найдем ближайшую снизу, потом сверху
			Try
				Lower = OneLevelItems.Get(DeletedIndex + 1);
			Except 
				Lower = Undefined;
			EndTry;
			
			Try
				Upper = OneLevelItems.Get(DeletedIndex - 1);
			Except
				Upper = Undefined;
			EndTry;
			
			If Parent = Undefined Then
				StructurePresentationTree.GetItems().Delete(IDCurStructureItem);
			Else
				Parent.GetItems().Delete(IDCurStructureItem);
			EndIf;
		EndDo;
		
		If NOT Lower = Undefined Then
			Items.StructurePresentationTree.CurrentRow = Lower.GetID();
		ElsIf NOT Upper = Undefined Then
			Items.StructurePresentationTree.CurrentRow = Upper.GetID();
		Else
			If Parent = Undefined Then
				Items.StructurePresentationTree.CurrentRow = Undefined;
			Else
				Items.StructurePresentationTree.CurrentRow = Parent.GetID();
			EndIf;
		EndIf;
	Else
		Return
	EndIf;
	RefreshTreeFillingOfFillingItems();
	ThisForm.Modified = True;
EndProcedure

&AtServer
Function ItemIsInStructureTree(Item)
	StructureTree = FormAttributeToValue("StructurePresentationTree");
	RowItemsDoubles = StructureTree.Rows.Find(Item, "Ref", True);
	If RowItemsDoubles = Undefined Then
		Return False;
	Else
		//предусмотрим ситуацию, когда статья присутствует только в формульных элементах, 
		//в таком случае ее необходимо позволять добавлять
		AllFormulas = True;
		If TypeOf(RowItemsDoubles) = Type("ValueTreeRow") Then
			//одна строка найдена
			If NOT RowItemsDoubles.IsFormulaItem Then
				AllFormulas = False;
			EndIf;
		Else
			//массив строк
			For Each SingleDoublesRow In RowItemsDoubles Do
				If NOT SingleDoublesRow.IsFormulaItem Then
					AllFormulas = False;
				EndIf;
			EndDo;
		EndIf;
		
		If AllFormulas Then
			Return False;
		Else
			Return True;
		EndIf;
	EndIf;
EndFunction

&AtClient
Procedure RefreshFormulaRowsDescriptions(OldDescription, NewDescription, RowsLevel)
	For Each String In RowsLevel Do
		If String.Group = OldDescription AND String.IsFormulaItem AND NOT ValueIsFilled(String.FormulaString) AND String.GroupType = New TypeDescription("CatalogRef.fmInfoStructuresSections") Then
			String.Group = NewDescription;
		EndIf;
		RefreshFormulaRowsDescriptions(OldDescription, NewDescription, String.GetItems());		
	EndDo;
EndProcedure

&AtServer
Function CopyStructuresTreeInCatalog()
	//на этом этапе у нас уже есть ссылка объекта - Вид отчета
	
	StructureTree = FormAttributeToValue("StructurePresentationTree");
	
	//1. Добавим в структуру новые элементы спр структуры
	AddNewStructureItems(Catalogs.fmInfoStructuresSections.EmptyRef(), StructureTree.Rows);
	
	//2. Пометим на удаление удаленные элементы структуры
	MarkExcludedStructureItemsForDeletion(StructureTree);
	
	//3. Выстроим иерархию структуры по-новому
	ChangeStructuresItemsHierarchyAndTheirAttributesServer(StructureTree.Rows, Catalogs.fmInfoStructuresSections.EmptyRef(), StructureTree, New UUID);
	
	//4. Обновим УИДы у элементов структур
	UpdateUIDs(StructureTree.Rows);
	
	ValueToFormAttribute(StructureTree, "StructurePresentationTree");
EndFunction

&AtServer
Procedure UpdateUIDs(TreeRowPresentation)
	For Each TreeRow In TreeRowPresentation Do
		If TreeRow.GroupType = New TypeDescription("CatalogRef.fmInfoStructuresSections") Then
			TreeRow.UID = TreeRow.Ref.UUID();
		EndIf;
		UpdateUIDs(TreeRow.Rows);
	EndDo;
EndProcedure

&AtServer
Procedure MarkExcludedStructureItemsForDeletion(StructureTree)
	//получим дерево структуры существующее
	Query = New Query;
	Query.Text = "SELECT
	|	fmInfoStructuresSections.Ref AS Ref
	|FROM
	|	Catalog.fmInfoStructuresSections AS fmInfoStructuresSections
	|WHERE
	|	fmInfoStructuresSections.Owner = &StructureType
	|	AND fmInfoStructuresSections.Ref <> &IsEmpty
	|	AND fmInfoStructuresSections.DeletionMark = False
	|
	|ORDER BY
	|	fmInfoStructuresSections.Order
	|TOTALS BY
	|	Ref Hierarchy";
	Query.SetParameter("StructureType", Object.Ref);
	Query.SetParameter("IsEmpty", Catalogs.fmInfoStructuresSections.EmptyRef());
	Unloading = Query.Execute().Unload(QueryResultIteration.ByGroupsWithHierarchy);
	IterateTreeAndMarkRecursively(StructureTree, Unloading.Rows);
EndProcedure

&AtServer
Procedure IterateTreeAndMarkRecursively(StructureTree, ExistingRowTree)
	
	For Each LoadRow In ExistingRowTree Do
		
		If NOT LoadRow.Parent = Undefined Then
			If LoadRow.Ref = LoadRow.Parent.Ref Then
				//избавляемся от дублей
				Continue;
			EndIf;
		EndIf;
		
		//найдем строку в создаваемой структуре
		FoundRow = StructureTree.Rows.Find(LoadRow.Ref, "Ref", True);
		If FoundRow = Undefined OR ?(LoadRow.Ref.Parent = Undefined, False, LoadRow.Ref.Parent.DeletionMark) Then
			//из новой структуры эту строку исключили, пометим элемент на удаление
			CatObject = LoadRow.Ref.GetObject();
			CatObject.DeletionMark = True;
			CatObject.Write();
		EndIf;
		
		IterateTreeAndMarkRecursively(StructureTree, LoadRow.Rows);
		
	EndDo;
	
EndProcedure

&AtServer
Procedure AddNewStructureItems(Parent, Rows)
	
	For Each String In Rows Do
		If NOT ValueIsFilled(String.Ref) AND String.GroupType = New TypeDescription("CatalogRef.fmInfoStructuresSections") AND NOT String.IsFormulaItem Then
			NewStrIt = Catalogs.fmInfoStructuresSections.CreateItem();
			FillPropertyValues(NewStrIt, String);
			NewStrIt.Parent = Parent;
			If NOT String.Parent = Undefined Then
				If String.Parent.Ref = Undefined Then
					NewStrIt.Parent = Catalogs.fmInfoStructuresSections.EmptyRef();
				Else
					NewStrIt.Parent = String.Parent.Ref;
				EndIf;
			EndIf;
			If Parent = Undefined Then
				NewStrIt.Parent = Catalogs.fmInfoStructuresSections.EmptyRef();
			EndIf;
			NewStrIt.ByFormula = False;
			NewStrIt.Owner = Object.Ref;
			NewStrIt.Description = String.Group;
			NewStrIt.Write();
			//не забудем теперь в реквизит справочника записать новую ссылка
			String.Ref = NewStrIt.Ref; 
			AddNewStructureItems(NewStrIt.Ref, String.Rows)
		Else
			AddNewStructureItems(String.Ref, String.Rows)
		EndIf;
	EndDo;
EndProcedure

&AtServer
Procedure ChangeStructuresItemsHierarchyAndTheirAttributesServer(StructureTreeRows, Parent, StructureTree, ParentUID)
	
	ClearInners = True;
	//ПропуститьСодержимоеСтруктуры = Ложь;
	For Each TreeRow In StructureTreeRows Do
		If TreeRow.GroupType = New TypeDescription("CatalogRef.fmInfoStructuresSections") AND NOT (TreeRow.ByFormula AND Object.StructureType <> Enums.fmInfoStructureTypes.IncomesAndExpensesBudget AND Object.StructureType <> Enums.fmInfoStructureTypes.CashflowBudget) AND NOT TreeRow.IsFormulaItem Then
			If NOT TreeRow.Ref = Undefined AND ChangedItemsListStr.FindByValue(TreeRow.UID) <> Undefined Then
				If NOT TreeRow.Ref.IsEmpty() Then
					Try
						CatObject = TreeRow.Ref.GetObject();
						FillPropertyValues(CatObject, TreeRow);
						CatObject.Parent = Parent;//переопределяем родителя.
						CatObject.Owner = Object.Ref;
						CatObject.Description = TreeRow.Group;
						CatObject.SectionStructureData.Clear();
						//***
						RefreshStructureItemsIndicatorsTS(CatObject, TreeRow);
						//СпрОбъект.ПропуститьПередЗаписью = Истина;
						//***
						CatObject.Write();
					Except
						RowText = NStr("en='Failed to write item %Item%';ru='Не удалось записать статью %Статья%'");
						RowText = StrReplace(RowText,"%Item%",TreeRow.Group);
						CommonClientServer.MessageToUser(RowText);
					EndTry;
				EndIf;
			EndIf;
			
			ChangeStructuresItemsHierarchyAndTheirAttributesServer(TreeRow.Rows, TreeRow.Ref, StructureTree, TreeRow.UID)
			
		ElsIf TreeRow.GroupType = New TypeDescription("CatalogRef.fmInfoStructuresSections") AND TreeRow.ByFormula AND Object.StructureType <> Enums.fmInfoStructureTypes.IncomesAndExpensesBudget AND Object.StructureType <> Enums.fmInfoStructureTypes.CashflowBudget AND NOT TreeRow.IsFormulaItem Then
			//циклично не идем, просто обрабатываем этот элемент и продолжаем
			If NOT TreeRow.Ref = Undefined AND ChangedItemsListStr.FindByValue(TreeRow.UID) <> Undefined Then
				If NOT TreeRow.Ref.IsEmpty() Then
					Try 
						CatObject = TreeRow.Ref.GetObject();
						FillPropertyValues(CatObject, TreeRow);	
						//восстановим признак По формуле для элемента структуры
						CatObject.ByFormula = True;
						CatObject.Parent = Parent;  //переопределяем родителя
						CatObject.Owner = Object.Ref;
						CatObject.Description = TreeRow.Group;
						
						//обработаем формульную ТЧ
						CatObject.Formula.Clear();
						ItemsPlusMinus = TreeRow.Rows;
						For Each ItemPlusMinus In ItemsPlusMinus Do
							FormulaItems = ItemPlusMinus.Rows;
							For Each FormItem In FormulaItems Do
								NewFormulaString = CatObject.Formula.Add();
								//
								If FormItem.FormulaString = Undefined Then
									//в первую очередь ищем в дереве наш УИД
									FilterStr = New Structure;
									FilterStr.Insert("Group", FormItem.Group);
									FilterStr.Insert("UID", FormItem.UID);
									FilterStr.Insert("IsFormulaItem", False);
									FilterStr.Insert("GroupType", New TypeDescription("CatalogRef.fmInfoStructuresSections"));
									StringArray = StructureTree.Rows.FindRows(FilterStr, True);
									If NOT StringArray.Count() = 0 Then
										FoundRow = StringArray[0];
										FormItem.FormulaString = FoundRow.Ref;	
										FormItem.Ref = FoundRow.Ref;
									Else
										//ищем по наименования - КРАЙНИЙ СЛУЧАЙ!!!
										Query = New Query;
										Query.Text = "SELECT
										|	fmInfoStructuresSections.Ref
										|FROM
										|	Catalog.fmInfoStructuresSections AS fmInfoStructuresSections
										|WHERE
										|	fmInfoStructuresSections.Owner = &ReportType
										|	AND fmInfoStructuresSections.Description = &Description";
										Query.SetParameter("ReportType", Object.Ref);
										Query.SetParameter("Description", FormItem.Group);
										Result = Query.Execute().SELECT();
										If Result.Next() Then
											FormItem.FormulaString = Result.Ref;	
											FormItem.Ref = Result.Ref;
										EndIf;
									EndIf;
									///
								EndIf;
								//
								NewFormulaString.String = FormItem.FormulaString;    //или ФормулаСтрока???????????????
								NewFormulaString.Minus = FormItem.FormulaMinus;
							EndDo;
						EndDo;
						
						RefreshStructureItemsIndicatorsTS(CatObject, TreeRow);
						CatObject.SkipBeforeWrite = True;
						CatObject.Write();
					Except
						RowText = NStr("en='Failed to write item %Item%';ru='Не удалось записать статью %Статья%'");
						RowText = StrReplace(RowText,"%Item%",TreeRow.Group);
						CommonClientServer.MessageToUser(RowText);
					EndTry;
				EndIf;
			EndIf;
			
		ElsIf TreeRow.GroupType = New TypeDescription("CatalogRef.fmIncomesAndExpensesItems")
			OR TreeRow.GroupType = New TypeDescription("CatalogRef.fmItemGroups")
			OR TreeRow.GroupType = New TypeDescription("CatalogRef.fmCashflowItems")Then
			//если спустились до статей, то дальше не зацикливаемся, просто переносим все "пачкой" в элемент структуры
			//найдем элемент, куда заливаем ТЧ
			If NOT Parent.Ref = Undefined AND ChangedItemsListStr.FindByValue(ParentUID) <> Undefined Then //И НЕ ПропуститьСодержимоеСтруктуры Тогда
				If NOT Parent.Ref.IsEmpty() Then
					Try
						CatObject = Parent.Ref.GetObject();
						
						//ТекущаяСтруктура = СпрОбъект.Наименование;
						If ClearInners Then
							CatObject.SectionStructureData.Clear();
							ClearInners = False;
						EndIf;
						//Для каждого СтрокаПоказателей Из СтрокиДереваСтруктуры Цикл
							If TreeRow.GroupType = New TypeDescription("CatalogRef.fmIncomesAndExpensesItems") 
								OR TreeRow.GroupType = New TypeDescription("CatalogRef.fmItemGroups")
								OR TreeRow.GroupType = New TypeDescription("CatalogRef.fmCashflowItems") Then 
									FirstLevelAnalyticsRows = TreeRow.Rows;
									If ValueIsFilled(FirstLevelAnalyticsRows) Then
										For Each CurrentAnalytics In FirstLevelAnalyticsRows Do
											SecondLevelAnalyticsRows = CurrentAnalytics.Rows;
											If ValueIsFilled(SecondLevelAnalyticsRows) Then
												For Each CurrentAnalytics1 In SecondLevelAnalyticsRows Do
													ThirdLevelAnalyticsRows = CurrentAnalytics1.Rows;
													If ValueIsFilled(ThirdLevelAnalyticsRows) Then
														For Each CurrentAnalytics2 In SecondLevelAnalyticsRows Do
															NewIndicatorsRow = CatObject.SectionStructureData.Add();
															FillPropertyValues(NewIndicatorsRow, TreeRow);
															NewIndicatorsRow["Analytics1"] = CurrentAnalytics.Analytics;
															NewIndicatorsRow["Analytics2"] = CurrentAnalytics1.Analytics;
															NewIndicatorsRow["Analytics3"] = CurrentAnalytics2.Analytics;
															RefreshStructureItemsIndicatorsTS(CatObject, TreeRow);
														EndDo;
													Else
														NewIndicatorsRow = CatObject.SectionStructureData.Add();
														FillPropertyValues(NewIndicatorsRow, TreeRow);
														NewIndicatorsRow["Analytics1"] = CurrentAnalytics.Analytics;
														NewIndicatorsRow["Analytics2"] = CurrentAnalytics1.Analytics;
														RefreshStructureItemsIndicatorsTS(CatObject, TreeRow);
													EndIf;
												EndDo;
											Else
												NewIndicatorsRow = CatObject.SectionStructureData.Add();
												FillPropertyValues(NewIndicatorsRow, TreeRow);
												NewIndicatorsRow["Analytics1"] = CurrentAnalytics.Analytics;
												RefreshStructureItemsIndicatorsTS(CatObject, TreeRow);
											EndIf;
										EndDo;
										CatObject.Write();
									Else
										NewIndicatorsRow = CatObject.SectionStructureData.Add();
										FillPropertyValues(NewIndicatorsRow, TreeRow);
										RefreshStructureItemsIndicatorsTS(CatObject, TreeRow);
										//СпрОбъект.ПропуститьПередЗаписью = Истина;
										CatObject.Write();
									EndIf;
								ElsIf TreeRow.GroupType = New TypeDescription("CatalogRef.fmInfoStructuresSections") Then
									If NOT TreeRow.Ref.IsEmpty() Then
										Try
											CatObject = TreeRow.Ref.GetObject();
											FillPropertyValues(CatObject, TreeRow);
											CatObject.Parent = Parent;//переопределяем родителя.
											CatObject.Owner = Object.Ref;
											CatObject.Description = TreeRow.Group;
											CatObject.SectionStructureData.Clear();
											//***
											RefreshStructureItemsIndicatorsTS(CatObject, TreeRow);
											//СпрОбъект.ПропуститьПередЗаписью = Истина;
											//***
											CatObject.Write();
										Except
											RowText = NStr("en='Failed to write item %Item%';ru='Не удалось записать статью %Статья%'");
											RowText = StrReplace(RowText,"%Item%",TreeRow.Group);
											CommonClientServer.MessageToUser(RowText);
										EndTry;
									EndIf;
							EndIf;
						//КонецЦикла;
					Except
						RowText = NStr("en='Failed to write item %Item%';ru='Не удалось записать статью %Статья%'");
						RowText = StrReplace(RowText,"%Item%", TreeRow.Group);
						CommonClientServer.MessageToUser(RowText);
					EndTry;
					
					For Each NewRow In StructureTreeRows Do
						
						If NewRow.GroupType = New TypeDescription("CatalogRef.fmInfoStructuresSections") AND NOT (NewRow.ByFormula AND Object.StructureType <> Enums.fmInfoStructureTypes.IncomesAndExpensesBudget AND Object.StructureType <> Enums.fmInfoStructureTypes.CashflowBudget) AND NOT NewRow.IsFormulaItem Then
							If NOT NewRow.Ref = Undefined AND ChangedItemsListStr.FindByValue(NewRow.UID) <> Undefined Then
								If NOT NewRow.Ref.IsEmpty() Then
									Try 
										CatObject = NewRow.Ref.GetObject();
										FillPropertyValues(CatObject, NewRow);	
										CatObject.Parent = Parent;  //переопределяем родителя
										CatObject.Owner = Object.Ref;
										CatObject.Description = NewRow.Group;
										CatObject.SectionStructureData.Clear();
										//***
										RefreshStructureItemsIndicatorsTS(CatObject, NewRow);
										//СпрОбъект.ПропуститьПередЗаписью = Истина;
										//***
										CatObject.Write();
									Except
										RowText = NStr("en='Failed to write item %Item%';ru='Не удалось записать статью %Статья%'");
										RowText = StrReplace(RowText,"%Item%",NewRow.Group);
										CommonClientServer.MessageToUser(RowText);
									EndTry;
								EndIf;
							EndIf;
							
							ChangeStructuresItemsHierarchyAndTheirAttributesServer(NewRow.Rows, NewRow.Ref, StructureTree, NewRow.UID)
							
						ElsIf NewRow.GroupType = New TypeDescription("CatalogRef.fmInfoStructuresSections") AND NewRow.ByFormula AND Object.StructureType <> Enums.fmInfoStructureTypes.IncomesAndExpensesBudget AND Object.StructureType <> Enums.fmInfoStructureTypes.CashflowBudget AND NOT NewRow.IsFormulaItem Then
							//циклично не идем, просто обрабатываем этот элемент и продолжаем
							If NOT NewRow.Ref = Undefined Then
								If NOT NewRow.Ref.IsEmpty() AND ChangedItemsListStr.FindByValue(NewRow.UID) <> Undefined Then
									Try
										CatObject = NewRow.Ref.GetObject();
										FillPropertyValues(CatObject, NewRow);
										//восстановим признак По формуле для элемента структуры
										CatObject.ByFormula = True;
										CatObject.Parent = Parent;//переопределяем родителя
										CatObject.Owner = Object.Ref;
										CatObject.Description = NewRow.Group;
										
										//обработаем формульную ТЧ
										CatObject.Formula.Clear();
										ItemsPlusMinus = NewRow.Rows;
										For Each ItemPlusMinus In ItemsPlusMinus Do
											FormulaItems = ItemPlusMinus.Rows;
											For Each FormItem In FormulaItems Do
												NewFormulaString = CatObject.Formula.Add();
												If FormItem.FormulaString = Undefined Then
													//в первую очередь ищем в дереве наш УИД
													FilterStr = New Structure;
													FilterStr.Insert("Group", FormItem.Group);
													FilterStr.Insert("UID", FormItem.UID);
													FilterStr.Insert("IsFormulaItem", False);
													FilterStr.Insert("GroupType", New TypeDescription("CatalogRef.fmInfoStructuresSections"));
													StringArray = StructureTree.Rows.FindRows(FilterStr, True);
													If NOT StringArray.Count() = 0 Then
														FoundRow = StringArray[0];
														FormItem.FormulaString = FoundRow.Ref;	
														FormItem.Ref = FoundRow.Ref;
													Else
														//ищем по наименования - КРАЙНИЙ СЛУЧАЙ!!!
														Query = New Query;
														Query.Text = "SELECT
														|	fmInfoStructuresSections.Ref
														|FROM
														|	Catalog.fmInfoStructuresSections AS fmInfoStructuresSections
														|WHERE
														|	fmInfoStructuresSections.Owner = &ReportType
														|	AND fmInfoStructuresSections.Description = &Description";
														Query.SetParameter("ReportType", Object.Ref);
														Query.SetParameter("Description", FormItem.Group);
														Result = Query.Execute().SELECT();
														If Result.Next() Then
															FormItem.FormulaString = Result.Ref;	
															FormItem.Ref = Result.Ref;
														EndIf;
													EndIf;
													///
												EndIf;
												//
												NewFormulaString.String = FormItem.FormulaString;    //или ФормулаСтрока???????????????
												NewFormulaString.Minus = FormItem.FormulaMinus;
											EndDo;
										EndDo;
										RefreshStructureItemsIndicatorsTS(CatObject, NewRow);
										//СпрОбъект.ПропуститьПередЗаписью = Истина;
										CatObject.Write();
									Except
										RowText = NStr("en='Failed to write item %Item%';ru='Не удалось записать статью %Статья%'");
										RowText = StrReplace(RowText, "%Item%", NewRow.Group);
										CommonClientServer.MessageToUser(RowText);
									EndTry;
								EndIf;
							EndIf;
						EndIf;
					EndDo;
					//ПропуститьСодержимоеСтруктуры = Истина;
					Continue;
				EndIf;
			EndIf;
		ElsIf TreeRow.FixedSection Then
			ChangeStructuresItemsHierarchyAndTheirAttributesServer(TreeRow.Rows, TreeRow.Ref, StructureTree, TreeRow.UID);
		EndIf;
	EndDo;
EndProcedure

&AtServer
Procedure RefreshStructureItemsIndicatorsTS(CatObject, RowInFormTree)
	
	//итоговая таблица показателей
	IndicatorsTable = New ValueTable;
	IndicatorsTable.Columns.Add("Analytics");
	IndicatorsTable.Columns.Add("Source");
	IndicatorsTable.Columns.Add("Minus");
	IndicatorsTable.Columns.Add("Order");
	
	If CatObject.ByFormula Then
		
		StructureTree = FormAttributeToValue("StructurePresentationTree");
		
		
		CatObject.SectionStructureData.Clear();
		
		FormulaItemsWithSign = New ValueTable;
		FormulaItemsWithSign.Columns.Add("Minus");
		FormulaItemsWithSign.Columns.Add("String");
		FormulaItemsWithSign.Columns.Add("Order");
		
		For Each Item In CatObject.Formula Do
			
			NewLine = FormulaItemsWithSign.Add();
			NewLine["Minus"] = Item.Minus;
			NewLine["String"] = Item.String;
			NewLine["Order"] = Item.Order;
			
		EndDo;
		
		For Each RowPlusMinus In RowInFormTree.Rows Do
			SectionStructureDataFill(FormulaItemsWithSign, IndicatorsTable, StructureTree, RowPlusMinus, RowPlusMinus.FormulaMinus);
		EndDo;
		
		//заполняем табличную часть "ДанныеРазделаСтруктуры"
		For Each TableItem In IndicatorsTable Do
			
			NewLine = CatObject.SectionStructureData.Add();
			
			NewLine.Analytics = TableItem["Analytics"];
			NewLine.Source = TableItem["Source"];
			NewLine.Order = TableItem["Order"];
			
		EndDo;
		
		
	EndIf;
	
EndProcedure

&AtServer
Function SectionStructureDataFill(FormulaTSItems, IndicatorsTable, StructureTree, RowInFormTree, MinusFromParentRow, Inversion = False)
	
	For Each NewRow In RowInFormTree.Rows Do
		//Если ОчереднаяСтрока.ТипГруппировки = Новый ОписаниеТипов("СправочникСсылка.уфРазделыСтруктурСведений") И ОчереднаяСтрока.ПоФормуле Тогда
		//	СтрокиПлюсМинус = ОчереднаяСтрока.Строки;
		//	Для каждого СтрокаПлюИлиМинус из СтрокиПлюсМинус Цикл
		//		СтрокиВлож = СтрокаПлюИлиМинус.Строки; 
		//		Для каждого ОчСтрока ИЗ СтрокиВлож Цикл
		//			ДанныеРазделаСтруктурыЗаполнить(ЭлементыТЧФормулы, ТаблицаПоказателей, ДеревоСтруктуры, ОчСтрока);	
		//		КонецЦикла;
		//	КонецЦикла;
		If NewRow.GroupType = New TypeDescription("CatalogRef.fmInfoStructuresSections") Then
			//смотрим вложенные строки
			//либо она формульная, либо нет
			IsFormula = False;
			
			//сперва найдем оригинальную строку в структуре
			FilterStr = New Structure;
			FilterStr.Insert("Group", NewRow.Group);
			FilterStr.Insert("UID", NewRow.UID);
			FilterStr.Insert("IsFormulaItem", False);
			FilterStr.Insert("GroupType", New TypeDescription("CatalogRef.fmInfoStructuresSections"));
			StringArray = StructureTree.Rows.FindRows(FilterStr, True);
			If StringArray.Count() = 0 Then
				FilterStr = New Structure;
				FilterStr.Insert("Group", NewRow.Group);
				FilterStr.Insert("IsFormulaItem", False);
				FilterStr.Insert("GroupType", New TypeDescription("CatalogRef.fmInfoStructuresSections"));
				StringArray = StructureTree.Rows.FindRows(FilterStr, True);
			EndIf;
			If StringArray = Undefined Then
				Continue;
			EndIf;
			
			FoundRow = StringArray[0];
			
			For Each NextR In FoundRow.Rows Do
				If NextR.GroupType = New TypeDescription("String") Then
					IsFormula = True;	
				EndIf;
			EndDo;
			
			
			If IsFormula Then
				RowsPlusMinus = FoundRow.Rows;
				For Each RowPlusOrMinus In RowsPlusMinus Do
					If MinusFromParentRow = False AND RowPlusOrMinus.FormulaMinus Then
						SectionStructureDataFill(FormulaTSItems, IndicatorsTable, StructureTree, RowPlusOrMinus, RowPlusOrMinus.FormulaMinus);	
					ElsIf MinusFromParentRow AND RowPlusOrMinus.FormulaMinus Then
						//минус на минус дадут плюс
						SectionStructureDataFill(FormulaTSItems, IndicatorsTable, StructureTree, RowPlusOrMinus, MinusFromParentRow, True);	
					Else
						SectionStructureDataFill(FormulaTSItems, IndicatorsTable, StructureTree, RowPlusOrMinus, MinusFromParentRow);//СтрокаПлюИлиМинус.ФормулаМинус);	
					EndIf;
				EndDo;
			Else
				
				//структура может быть подчинена, чтобы найти ее дочек, нужно искать такой элемент по всему дереву
				//СтрОтбора = Новый Структура;
				//СтрОтбора.Вставить("Группировка", ОчереднаяСтрока.Группировка);
				//СтрОтбора.Вставить("Ссылка", ОчереднаяСтрока.Ссылка);
				//СтрОтбора.Вставить("ЭтоФормульныйЭлемент", Ложь);
				//СтрОтбора.Вставить("ТипГруппировки", Новый ОписаниеТипов("СправочникСсылка.уфРазделыСтруктурСведений"));
				//МассивСтрок = ДеревоСтруктуры.Строки.НайтиСтроки(СтрОтбора, Истина);
				//НайдСтрока = МассивСтрок[0];
				//циклично идем по дочерним элементам структуры
				//здесь минус берем от высшей группировки, а не свой, своего может и не быть
				SectionStructureDataFill(FormulaTSItems, IndicatorsTable, StructureTree, FoundRow, MinusFromParentRow);
			EndIf;
		ElsIf NewRow.GroupType = New TypeDescription("CatalogRef.fmItemGroups") Then
			//идем внутрь, попадем тогда на статьи
			//Для каждого ОчСтрока Из ОчереднаяСтрока.Строки Цикл
			SectionStructureDataFill(FormulaTSItems, IndicatorsTable, StructureTree, NewRow, MinusFromParentRow);
			//КонецЦикла;
		ElsIf NewRow.GroupType = New TypeDescription("CatalogRef.fmIncomesAndExpensesItems") OR NewRow.GroupType = New TypeDescription("CatalogRef.fmCashflowItems") Then
			NewLine = IndicatorsTable.Add();
			NewLine["Analytics"] 	= ?(ValueIsFilled(NewRow.Analytics), NewRow.Analytics,NewRow.Ref); 
			NewLine["Source"] 	= Catalogs.fmInfoStructuresSections.EmptyRef();
			NewLine["Order"] 	= NewRow.Order;
		EndIf;
	EndDo;
	///////////////////////////////////////////////////
	
EndFunction

&AtClient
Procedure SwitchStructureTypeOnChangeEnd(QueryResult, AdditionalParameters) Export
	//очистим дерево справа
	If QueryResult = DialogReturnCode.Yes Then
		ChageOperationTypeChoiceList();
		ChangedItem = Items.StructurePresentationTree.CurrentData;
		ChangedItem.StructureSectionType = MovementOperationType;
		Items.StructurePresentationTree.ChangeRow();
		IterateBranchItems(ChangedItem.GetItems());
		AddChangedOrDeletedItemsInList();
		
		ClearStructuresItemsTreeAtServer();
		//перестроим группировки, поскольку изменен тип отчета
		ClearFillingTreeAtServer();
		FillPresentationTree();
		FillSourcesItemsTree();
		ExpandFirstLevel();
		RefreshConditionalAppearance();
	Else
		Object.StructureType = SavedStructureType;
	EndIf;
EndProcedure

&AtClient
Procedure ExpandFirstLevel()
	FirstLevelItems = FillingItemsTree.GetItems();
	For Each FirstLevelItem In FirstLevelItems Do
		IDOfRow = FirstLevelItem.GetID();
		Items.FillingItemsTree.Expand(IDOfRow,False);
	EndDo;
EndProcedure

&AtClient
Procedure SetAvailabilityOfGroupFieldButton(RowID)
	CurRow = StructurePresentationTree.FindByID(RowID);
	If ValueIsFilled(CurRow.Analytics) OR CurRow.GroupType = New TypeDescription("CatalogRef.fmIncomesAndExpensesItems")
		OR CurRow.GroupType = New TypeDescription("CatalogRef.fmCashflowItems") Then
		Items.StructurePresentationTreeGroup.DropListButton = True;
	EndIf;
	If CurRow.GroupType = New TypeDescription("CatalogRef.fmInfoStructuresSections") Then
		Items.StructurePresentationTreeGroup.TextEdit = True;
		Items.StructurePresentationTreeGroup.DropListButton = False;
		If CurRow.IsFormulaItem Then
			Items.StructurePresentationTreeGroup.ChoiceButton = True;
		Else
			Items.StructurePresentationTreeGroup.ChoiceButton = False;
		EndIf;
		Items.StructurePresentationTreeGroup.OpenButton = False;
	ElsIf CurRow.GroupType = New TypeDescription("CatalogRef.fmIncomesAndExpensesItems")
		OR CurRow.GroupType = New TypeDescription("CatalogRef.fmCashflowItems")
		OR CurRow.GroupType = New TypeDescription("CatalogRef.fmItemGroups")
		OR NOT ValueIsFilled(CurRow.GroupType) Then
		Items.StructurePresentationTreeGroup.ReadOnly = False;
		Items.StructurePresentationTreeGroup.ChoiceButton = True;
		Items.StructurePresentationTreeGroup.OpenButton = True;
	EndIf;
EndProcedure

//при нажатии на формулу будет выдано сначала предупреждение, а потом выполнены действия

&AtClient
Procedure StructurePresentationTreeByFormulaOnChangeEnd1(QueryResult, AdditionalParameters) Export
	
	CurRowNumber = AdditionalParameters.CurRowNumber;
	CurData = AdditionalParameters.CurData;
	QueryText = AdditionalParameters.QueryText;
	AttributeCurRow = AdditionalParameters.AttributeCurRow;
	
	
	If QueryResult = DialogReturnCode.OK Then
		//чистим все подчиненные элементы и обновляем дерево
		ChildItemsStructureIt = AttributeCurRow.GetItems();
		ChildItemsStructureIt.Clear();
		
		RefreshTreeFillingOfFillingItems();
		
		//и теперь создаем строки + и -
		FixedRowPlus = AttributeCurRow.GetItems().Add();
		FixedRowPlus.Group = "(plus)";//"+";
		FixedRowPlus.PictureIndex = 2;
		FixedRowPlus.StructureSectionType = AttributeCurRow.StructureSectionType;
		FixedRowPlus.GroupParent = AttributeCurRow.Group;
		FixedRowPlus.GroupType = New TypeDescription("String");
		FixedRowPlus.IsFormulaItem = True;
		FixedRowPlus.ByFormula = True;
		FixedRowPlus.FormulaMinus = False;
		
		FixedRowMinus = AttributeCurRow.GetItems().Add();
		FixedRowMinus.Group = "(minus)";//"-";
		FixedRowMinus.PictureIndex = 1;
		FixedRowMinus.StructureSectionType = AttributeCurRow.StructureSectionType;
		FixedRowMinus.GroupParent = AttributeCurRow.Group;
		FixedRowMinus.GroupType = New TypeDescription("String");
		FixedRowMinus.IsFormulaItem = True;
		FixedRowMinus.ByFormula = True;
		FixedRowMinus.FormulaMinus = True;
		
		//доступность кнопок добавления статьи и раздела
		Items.AddStructureSection.Enabled = False;
		Items.AddItem.Enabled = False;
	Else
		CurData.ByFormula = False;
	EndIf;
	
	StructurePresentationTreeByFormulaOnChangeFragment1(AttributeCurRow);
	
EndProcedure

&AtClient
Procedure StructurePresentationTreeByFormulaOnChangeFragment1(VAL AttributeCurRow)
	
	Var FormulaRowID;
	
	FormulaRowID = AttributeCurRow.GetID();
	Items.StructurePresentationTree.Expand(FormulaRowID);
	
EndProcedure

&AtClient
Procedure StructurePresentationTreeByFormulaOnChangeEnd(QueryResult, AdditionalParameters) Export
	
	CurData = AdditionalParameters.CurData;
	AttributeCurRow = AdditionalParameters.AttributeCurRow;
	
	
	If QueryResult = DialogReturnCode.OK Then
		//чистим все подчиненные элементы и обновляем дерево
		ChildItemsStructureIt = AttributeCurRow.GetItems();
		ChildItemsStructureIt.Clear();
		
		//доступность кнопок добавления статьи и раздела
		Items.AddStructureSection.Enabled = True;
		Items.AddItem.Enabled = True;
	Else
		CurData.ByFormula = True;
	EndIf;
	//Иначе
	//	//без спроса удаляем строки + и -
	//	
	//КонецЕсли;
	
EndProcedure

&AtServer
Function CheckOnFillingErrors()
	
	StructuresTree = FormAttributeToValue("StructurePresentationTree", Type("ValueTree"));
	FilterStr = New Structure;
	GroupFilter = New Structure;
	If Object.StructureType = Enums.fmInfoStructureTypes.CashflowBudget Then
		FilterStr.Insert("GroupType", New TypeDescription("CatalogRef.fmCashflowItems"));
	ElsIf Object.StructureType = Enums.fmInfoStructureTypes.IncomesAndExpensesBudget Then
		FilterStr.Insert("GroupType", New TypeDescription("CatalogRef.fmIncomesAndExpensesItems"));
	EndIf;
	GroupFilter.Insert("GroupType", New TypeDescription("CatalogRef.fmItemGroups"));
	StringArray = StructuresTree.Rows.FindRows(FilterStr, True);
	GroupArray = StructuresTree.Rows.FindRows(GroupFilter, True);
	ItemsTable = New ValueTable;
	ItemsTable.Columns.Add("Ref");
	ItemsTable.Columns.Add("Count", New TypeDescription("Number"));
	For Each RowFromArray In StringArray Do
		If RowFromArray.IsFormulaItem Then
			Continue;
		EndIf;
		NewLine = ItemsTable.Add();
		If NOT TypeOf(RowFromArray.Ref) = New TypeDescription("CatalogRef.fmIncomesAndExpensesItems") OR NOT TypeOf(RowFromArray.Ref) = New TypeDescription("CatalogRef.fmCashflowItems")Then
			NewLine.Ref = RowFromArray.Analytics;
		Else
			NewLine.Ref = RowFromArray.Ref;
		EndIf;
		NewLine.Count = 1;
	EndDo;
	
	ItemsTable.GroupBy("Ref", "Count");
	RepeatedRow = "";
	For Each VTRow In ItemsTable Do
		If VTRow.Count > 1 Then
			If RepeatedRow <> "" Then
				RepeatedRow = RepeatedRow + ", ";
			EndIf;
			RepeatedRow = RepeatedRow + String(VTRow.Ref);
		EndIf;
	EndDo;
	If RepeatedRow <> "" Then
		Return RepeatedRow;
	EndIf;
	
	Return Undefined;
	
EndFunction

&AtClient
Procedure SaveExpandedNodesList(TreeItems)
	
	For Each FormTreeRow In TreeItems Do
		
		//ИндексСтроки = ЭлементыДерева.Индекс(СтрокаДереваФормы);
		ID = FormTreeRow.GetID();
		ItExpanded = Items.StructurePresentationTree.Expanded(ID);
		If ItExpanded Then
			FormTreeRow.ExpandedBeforeClose = True;
			//СписокРазвернутыхУзлов.Добавить(Идентификатор);
		Else 
			FormTreeRow.ExpandedBeforeClose = False;
		EndIf;
		SaveExpandedNodesList(FormTreeRow.GetItems());
		
	EndDo;
	
EndProcedure

&AtClient
Procedure SaveExpandedNodesOfFillingItemsTree(TreeItems)
	For Each FormTreeRow In TreeItems Do
		ID = FormTreeRow.GetID();
		GroupTitle = FormTreeRow.Group;
		ItExpanded = Items.FillingItemsTree.Expanded(ID);
		If ItExpanded Then
			If ExpandedNodesList.FindByID(ID) = Undefined Then
				ExpandedNodesList.Add(,GroupTitle);
			EndIf;
		EndIf;
		SaveExpandedNodesOfFillingItemsTree(FormTreeRow.GetItems());
	EndDo;
EndProcedure

&AtClient
Procedure RefreshTreeFillingOfFillingItems()
	
	//проставим у каждой строки дерева признак развернутости
	SaveExpandedNodesOfFillingItemsTree(FillingItemsTree.GetItems());
	
	//перестроим дерево с учетом уже имеющихся строк со статьями, группами статей и группировками в правом дереве
 	FillSourcesItemsTree();
	
	//обновиим форму
	RefreshDataRepresentation();
	
	//развернем узлы дерева слева, как было до перестроения дерева
	ExpandFillingItemsTreeItemsByExpandFlag(FillingItemsTree.GetItems());
	
EndProcedure

&AtClient
Procedure ExpandFillingItemsTreeItemsByExpandFlag(TreeItems)
	For Each FormTreeRow In TreeItems Do
		ID = FormTreeRow.GetID();
		For Each Item In ExpandedNodesList Do
			If Item.Presentation = String(FormTreeRow.Group) Then
				Items.FillingItemsTree.Expand(ID, False);
			EndIf;
		EndDo;
		ExpandFillingItemsTreeItemsByExpandFlag(FormTreeRow.GetItems());
	EndDo;
EndProcedure

&AtServer
Procedure UnloadTreeInValueTable(Tree, Table)
	
	For Each TreeRow In Tree.Rows Do
		If (TreeRow.Group = NStr("en='INCOME';ru='ДОХОДЫ'")
			OR TreeRow.Group = NStr("en='EXPENSES';ru='РАСХОДЫ'")
			OR TreeRow.Group = NStr("en='EXTRAS';ru='ДОПОЛНИТЕЛЬНАЯ ИНФОРМАЦИЯ'")) AND TreeRow.FixedSection
			OR TreeRow.Group = TreeRow.GroupParent
			OR TreeRow.GroupType = New TypeDescription("CatalogRef.fmItemGroups") Then
		Else
			NewLine = Table.Add();
			FillPropertyValues(NewLine, TreeRow);
			If (NewLine.GroupParent = NStr("en='INCOME';ru='ДОХОДЫ'")
				OR NewLine.GroupParent = NStr("en='EXTRAS';ru='ДОПОЛНИТЕЛЬНАЯ ИНФОРМАЦИЯ'")
				OR NewLine.GroupParent = NStr("en='EXPENSES';ru='РАСХОДЫ'")) AND (Object.StructureType <> Enums.fmInfoStructureTypes.IncomesAndExpensesBudget) Then
				NewLine.GroupParent = "";
			EndIf;
			If ValueIsFilled(NewLine.Analytics) Then
				NewRow = TreeRow.Parent;
				While NOT NewRow.GroupType = New TypeDescription("CatalogRef.fmInfoStructuresSections") Do
					NewRow = NewRow.Parent;
				EndDo;
				NewLine.Group = NewRow.Group;
				If (NewRow.GroupParent = NStr("en='INCOME';ru='ДОХОДЫ'")
					OR NewRow.GroupParent = NStr("en='EXTRAS';ru='ДОПОЛНИТЕЛЬНАЯ ИНФОРМАЦИЯ'")
					OR NewRow.GroupParent = NStr("en='EXPENSES';ru='РАСХОДЫ'")) AND (Object.StructureType <> Enums.fmInfoStructureTypes.IncomesAndExpensesBudget) Then
					NewLine.GroupParent = "";
				Else
					NewLine.GroupParent = NewRow.GroupParent;
				EndIf;
			EndIf;
		EndIf;
		UnloadTreeInValueTable(TreeRow, Table);
	EndDo;
	
EndProcedure

&AtClient
Procedure GetParentInLoop(Parent, AnalyticsIndex)
	If TypeOf(Parent.Analytics) = Type("CatalogRef.fmIncomesAndExpensesItems") OR TypeOf(Parent.Analytics) = Type("CatalogRef.fmCashflowItems") OR TypeOf(Parent.Analytics) = Type("CatalogRef.fmItemGroups") Then
		If AnalyticsIndex <= 3 Then
			Items.AddItem.Enabled = False;
			Items.StructurePresentationTree.CurrentItem.TypeRestriction = New TypeDescription(Parent["AnalyticsType"+AnalyticsIndex]);
			If AnalyticsIndex = 3 Then
				Items.AddItem.Enabled = False;
			ElsIf ValueIsFilled(Parent["AnalyticsType"+(AnalyticsIndex+1)]) Then
				Items.AddItem.Enabled = True;
			EndIf;
		EndIf;
	Else
		Parent = Parent.GetParent();
		AnalyticsIndex = AnalyticsIndex +1;
		GetParentInLoop(Parent, AnalyticsIndex);
	EndIf;
EndProcedure

#EndRegion








