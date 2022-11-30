
Procedure OnCreateAtServer(Form) Export
	
	FormNameArray = StringFunctionsClientServer.SplitStringIntoSubstringsArray(Form.FormName, ".");
	Items = Form.Items;
	
	// Добавим реквизиты в Catalog уфСтатьиДвиженияДенежныхСредств.
	If FormNameArray[0] = "Catalog" AND FormNameArray[1] = "fmCashflowItems" AND FormNameArray[3] = "ItemForm" Then
		
		//ПроверитьЗащиту();
		//Если NOT ПроверитьБитМаски(1) Тогда
		//	Сообщить(НСтр("ru = 'Функционал подсистемы <Бюджетирование> NOT активирован.
		//	|По вопросам демонстрации AND приобретения
		//	|обращаться +7-495-231-20-02 или fm@rarus.ru'"));
		//	Возврат;
		//КонецЕсли;
		
		FormPagesGroup = Items.Add("fmPagesGroup", Type("FormGroup"), Form);
		FormPagesGroup.Type = FormGroupType.Pages;
		
		Item = Items.Add("fmBudgetingGroup", Type("FormGroup"), Items.fmPagesGroup);
		Item.Type = FormGroupType.Page;
		Item.Group = ChildFormItemsGroup.Vertical;
		Item.Title = "Budgeting";
		
		Item = Items.Add("fmAnalyticsTypesGroup", Type("FormGroup"), Items.fmBudgetingGroup);
		Item.Type = FormGroupType.UsualGroup;
		Item.Group = ChildFormItemsGroup.Vertical;
		Item.Title = "Types Analytics";
		Item.ShowTitle = True;
		
		Item = Items.Add("AnalyticsType1", Type("FormField"), Items.fmAnalyticsTypesGroup);
		Item.Type = FormFieldType.InputField;
		Item.DataPath = "Object.fmAnalyticsType1";
		Item.ClearButton = True;
		
		Item = Items.Add("AnalyticsType2", Type("FormField"), Items.fmAnalyticsTypesGroup);
		Item.Type = FormFieldType.InputField;
		Item.DataPath = "Object.fmAnalyticsType2";
		Item.ClearButton = True;
		
		Item = Items.Add("AnalyticsType3", Type("FormField"), Items.fmAnalyticsTypesGroup);
		Item.Type = FormFieldType.InputField;
		Item.DataPath = "Object.fmAnalyticsType3";
		Item.ClearButton = True;
		
		Item = Items.Add("fmGroupOther", Type("FormGroup"), Items.fmBudgetingGroup);
		Item.Type = FormGroupType.UsualGroup;
		Item.Group = ChildFormItemsGroup.Vertical;
		Item.Title = "Other";
		Item.ShowTitle = True;
		
		Item = Items.Add("ItemType", Type("FormField"), Items.fmGroupOther);
		Item.Type = FormFieldType.InputField;
		Item.DataPath = "Object.fmItemType";
		Item.ClearButton = True;
		Item.ListChoiceMode = True;
		ChoiceList = Item.ChoiceList;
		ChoiceList.Add(PredefinedValue("Enum.fmBudgetFlowOperationTypes.Inflow"));
		ChoiceList.Add(PredefinedValue("Enum.fmBudgetFlowOperationTypes.Outflow"));
		
		Item = Items.Add("tmEntriesTemplatesGroup",Type("FormGroup"), Items.fmPagesGroup);
		Item.Type = FormGroupType.Page;
		Item.Group = ChildFormItemsGroup.Vertical;
		Item.Title = "Templates Entries";
		
		//ТЧ шаблоны.
		TabularSection = Items.Add("EntriesTemplates", Type("FormTable"), Items.tmEntriesTemplatesGroup);
		TabularSection.DataPath = "Object.fmEntriesTemplates";
		Items.EntriesTemplates.SetAction("OnActivateCell", "OnActivateCellEntriesTemplates");
		Items.EntriesTemplates.SetAction("OnStartEdit", "EntriesTemplatesOnStartEdit");
		
		TabularSectionAccountDr = Items.Add("LineNumber", Type("FormField"), TabularSection);
		TabularSectionAccountDr.Type = FormFieldType.InputField;
		TabularSectionAccountDr.DataPath = "Object.fmEntriesTemplates.LineNumber";
		
		FormColumnGroupDr = Items.Add("fmColumnGroupDr", Type("FormGroup"), TabularSection);
		FormColumnGroupDr.Type = FormGroupType.ColumnGroup;
		
		FormColumnGroupCr = Items.Add("fmColumnGroupCr", Type("FormGroup"), TabularSection);
		FormColumnGroupCr.Type = FormGroupType.ColumnGroup;
		
		//Дебетовая сторона.
		TabularSectionAccountDr = Items.Add("AccountDr", Type("FormField"), FormColumnGroupDr);
		TabularSectionAccountDr.Type = FormFieldType.InputField;
		TabularSectionAccountDr.DataPath = "Object.fmEntriesTemplates.AccountDr";
		Items.AccountDr.SetAction("OnChange", "EntriesTemplatesAccountDrOnChange");
		
		TabularSectionAccountDr = Items.Add("fmEntriesTemplatesExtDimensionDr1", Type("FormField"), FormColumnGroupDr);
		TabularSectionAccountDr.Type = FormFieldType.InputField;
		TabularSectionAccountDr.DataPath = "Object.fmEntriesTemplates.ExtDimensionDr1";
		TabularSectionAccountDr.ShowInHeader = False;
		TabularSectionAccountDr.DropListButton = True;
		TabularSectionAccountDr.TextEdit = False;
		Items.fmEntriesTemplatesExtDimensionDr1.SetAction("OnChange", "EntriesTemplatesExtDimensionDrOnChange");
		Items.fmEntriesTemplatesExtDimensionDr1.SetAction("StartChoice", "EntriesTemplateChooseFromListStart");
		
		TabularSectionAccountDr = Items.Add("fmEntriesTemplatesExtDimensionDr2", Type("FormField"), FormColumnGroupDr);
		TabularSectionAccountDr.Type = FormFieldType.InputField;
		TabularSectionAccountDr.DataPath = "Object.fmEntriesTemplates.ExtDimensionDr2";
		TabularSectionAccountDr.ShowInHeader = False;
		TabularSectionAccountDr.DropListButton = True;
		TabularSectionAccountDr.TextEdit = False;
		Items.fmEntriesTemplatesExtDimensionDr2.SetAction("OnChange", "EntriesTemplatesExtDimensionDrOnChange");
		Items.fmEntriesTemplatesExtDimensionDr2.SetAction("StartChoice", "EntriesTemplateChooseFromListStart");
		
		TabularSectionAccountDr = Items.Add("fmEntriesTemplatesExtDimensionDr3", Type("FormField"), FormColumnGroupDr);
		TabularSectionAccountDr.Type = FormFieldType.InputField;
		TabularSectionAccountDr.DataPath = "Object.fmEntriesTemplates.ExtDimensionDr3";
		TabularSectionAccountDr.ShowInHeader = False;
		TabularSectionAccountDr.DropListButton = True;
		TabularSectionAccountDr.TextEdit = False;
		Items.fmEntriesTemplatesExtDimensionDr3.SetAction("OnChange", "EntriesTemplatesExtDimensionDrOnChange");
		Items.fmEntriesTemplatesExtDimensionDr3.SetAction("StartChoice", "EntriesTemplateChooseFromListStart");
		
		//Кредитовая сторона.
		TabularSectionAccountCr = Items.Add("AccountCr", Type("FormField"), FormColumnGroupCr);
		TabularSectionAccountCr.Type = FormFieldType.InputField;
		TabularSectionAccountCr.DataPath = "Object.fmEntriesTemplates.AccountCr";
		Items.AccountCr.SetAction("OnChange", "EntriesTemplatesAccountCrOnChange");
		
		TabularSectionAccountCr = Items.Add("fmEntriesTemplatesExtDimensionCr1", Type("FormField"), FormColumnGroupCr);
		TabularSectionAccountCr.Type = FormFieldType.InputField;
		TabularSectionAccountCr.DataPath = "Object.fmEntriesTemplates.ExtDimensionCr1";
		TabularSectionAccountCr.ShowInHeader = False;
		TabularSectionAccountCr.DropListButton = True;
		TabularSectionAccountCr.TextEdit = False;
		Items.fmEntriesTemplatesExtDimensionCr1.SetAction("OnChange", "EntriesTemplatesExtDimensionCrOnChange");
		Items.fmEntriesTemplatesExtDimensionCr1.SetAction("StartChoice", "EntriesTemplateChooseFromListStart");
		
		TabularSectionAccountCr = Items.Add("fmEntriesTemplatesExtDimensionCr2", Type("FormField"), FormColumnGroupCr);
		TabularSectionAccountCr.Type = FormFieldType.InputField;
		TabularSectionAccountCr.DataPath = "Object.fmEntriesTemplates.ExtDimensionCr2";
		TabularSectionAccountCr.ShowInHeader = False;
		TabularSectionAccountCr.DropListButton = True;
		TabularSectionAccountCr.TextEdit = False;
		Items.fmEntriesTemplatesExtDimensionCr2.SetAction("OnChange", "EntriesTemplatesExtDimensionCrOnChange");
		Items.fmEntriesTemplatesExtDimensionCr2.SetAction("StartChoice", "EntriesTemplateChooseFromListStart");
		
		TabularSectionAccountCr = Items.Add("fmEntriesTemplatesExtDimensionCr3", Type("FormField"), FormColumnGroupCr);
		TabularSectionAccountCr.Type = FormFieldType.InputField;
		TabularSectionAccountCr.DataPath = "Object.fmEntriesTemplates.ExtDimensionCr3";
		TabularSectionAccountCr.ShowInHeader = False;
		TabularSectionAccountCr.DropListButton = True;
		TabularSectionAccountCr.TextEdit = False;
		Items.fmEntriesTemplatesExtDimensionCr3.SetAction("OnChange", "EntriesTemplatesExtDimensionCrOnChange");
		Items.fmEntriesTemplatesExtDimensionCr3.SetAction("StartChoice", "EntriesTemplateChooseFromListStart");
		
		TabularSectionAmountRatio = Items.Add("AmountRatio", Type("FormField"), TabularSection);
		TabularSectionAmountRatio.Type = FormFieldType.InputField;
		TabularSectionAmountRatio.DataPath = "Object.fmEntriesTemplates.AmountCalculationRatio";
		
		TSColumns = New Array;
		TSColumns.Add(New FormAttribute("fmAnalyticsTypeDr1", New TypeDescription("ChartOfCharacteristicTypesRef.fmAnalyticsTypes"), "Object.fmEntriesTemplates"));
		TSColumns.Add(New FormAttribute("fmAnalyticsTypeDr2", New TypeDescription("ChartOfCharacteristicTypesRef.fmAnalyticsTypes"), "Object.fmEntriesTemplates"));
		TSColumns.Add(New FormAttribute("fmAnalyticsTypeDr3", New TypeDescription("ChartOfCharacteristicTypesRef.fmAnalyticsTypes"), "Object.fmEntriesTemplates"));
		TSColumns.Add(New FormAttribute("fmAnalyticsTypeCr1", New TypeDescription("ChartOfCharacteristicTypesRef.fmAnalyticsTypes"), "Object.fmEntriesTemplates"));
		TSColumns.Add(New FormAttribute("fmAnalyticsTypeCr2", New TypeDescription("ChartOfCharacteristicTypesRef.fmAnalyticsTypes"), "Object.fmEntriesTemplates"));
		TSColumns.Add(New FormAttribute("fmAnalyticsTypeCr3", New TypeDescription("ChartOfCharacteristicTypesRef.fmAnalyticsTypes"), "Object.fmEntriesTemplates"));
		
		Form.ChangeAttributes(TSColumns);
		SetConditionalAppearance(Form);
		
	EndIf;
	
EndProcedure

Procedure SetConditionalAppearance(ThisObject)
	
	ThisObject.ConditionalAppearance.Items.Clear();
	
	For Counter = 1 To 3 Do
		
		CAItem = ThisObject.ConditionalAppearance.Items.Add();
		
		fmDataCompositionClientServer.AddAppearanceField(CAItem.Fields, "fmEntriesTemplatesExtDimensionCr" + Counter);

		CommonClientServer.AddCompositionItem(CAItem.Filter,
			"Object.fmEntriesTemplates.fmAnalyticsTypeCr" + Counter, DataCompositionComparisonType.NotFilled);
		
		CommonClientServer.AddCompositionItem(CAItem.Filter,
			"Object.fmEntriesTemplates.AccountCr", DataCompositionComparisonType.Filled);

		CAItem.Appearance.SetParameterValue("Visible", False);
		
		
		CAItem = ThisObject.ConditionalAppearance.Items.Add();
		
		fmDataCompositionClientServer.AddAppearanceField(CAItem.Fields, "fmEntriesTemplatesExtDimensionDr" + Counter);
		CommonClientServer.AddCompositionItem(CAItem.Filter,
			"Object.fmEntriesTemplates.fmAnalyticsTypeDr" + Counter, DataCompositionComparisonType.NotFilled);
		CommonClientServer.AddCompositionItem(CAItem.Filter,
			"Object.fmEntriesTemplates.AccountDr", DataCompositionComparisonType.Filled);
		
		CAItem.Appearance.SetParameterValue("Visible", False);
		
		CAItem = ThisObject.ConditionalAppearance.Items.Add();
		
		fmDataCompositionClientServer.AddAppearanceField(CAItem.Fields, "fmEntriesTemplatesExtDimensionCr" + Counter);

		CommonClientServer.AddCompositionItem(CAItem.Filter,
			"Object.fmEntriesTemplates.AccountCr", DataCompositionComparisonType.NotFilled);

		CAItem.Appearance.SetParameterValue("Visible", False);
		
		
		
		CAItem = ThisObject.ConditionalAppearance.Items.Add();
		
		fmDataCompositionClientServer.AddAppearanceField(CAItem.Fields, "fmEntriesTemplatesExtDimensionDr" + Counter);

		CommonClientServer.AddCompositionItem(CAItem.Filter,
			"Object.fmEntriesTemplates.AccountDr", DataCompositionComparisonType.NotFilled);
		
		CAItem.Appearance.SetParameterValue("Visible", False);
		
		CAItem = ThisObject.ConditionalAppearance.Items.Add();
		
		fmDataCompositionClientServer.AddAppearanceField(CAItem.Fields, "fmEntriesTemplatesExtDimensionCr" + Counter);

		CommonClientServer.AddCompositionItem(CAItem.Filter,
			"Object.fmEntriesTemplates.fmAnalyticsTypeCr" + Counter, DataCompositionComparisonType.Filled);

		CommonClientServer.AddCompositionItem(CAItem.Filter,
			"Object.fmEntriesTemplates.ExtDimensionCr" + Counter, DataCompositionComparisonType.NotFilled);

		CAItem.Appearance.SetParameterValue("TextColor", New Color(128, 128, 128));

		CAItem.Appearance.SetParameterValue("Text", NStr("en='<...>';ru='<...>'"));
		
		
		
		CAItem = ThisObject.ConditionalAppearance.Items.Add();

		fmDataCompositionClientServer.AddAppearanceField(CAItem.Fields, "fmEntriesTemplatesExtDimensionDr" + Counter);

		CommonClientServer.AddCompositionItem(CAItem.Filter,
			"Object.fmEntriesTemplates.fmAnalyticsTypeDr" + Counter, DataCompositionComparisonType.Filled);

		CommonClientServer.AddCompositionItem(CAItem.Filter,
			"Object.fmEntriesTemplates.ExtDimensionDr" + Counter, DataCompositionComparisonType.NotFilled);

		CAItem.Appearance.SetParameterValue("TextColor", New Color(128, 128, 128));

		CAItem.Appearance.SetParameterValue("Text", NStr("en='<...>';ru='<...>'"));
	EndDo;

EndProcedure

Procedure LoadTemplateOnReadAtServer(CurrentObject, SettingsTree, LoadSettings, NameSynonymMap, SynonymNameMap) Export
	
	//ПроверитьЗащиту();
	//Если NOT ПроверитьБитМаски(1) Тогда
	//	ВызватьИсключение НСтр("ru = 'Функционал подсистемы <Бюджетирование> NOT активирован.
	//	|По вопросам демонстрации и приобретения
	//	|обращаться +7-495-231-20-02 или fm@rarus.ru'");
	//КонецЕсли;
	
	// Заполним дерево строками по-умолчанию.
	CurItems = SettingsTree.Rows;
	Rows = CurItems.Add();
	Rows.Attribute = NStr("en='Rows';ru='Строки'");
	Rows.PredefinedRow = True;
	Columns = CurItems.Add();
	Columns.Attribute = NStr("en='Columns';ru='Columns'");
	Columns.PredefinedRow = True;
	Resources = CurItems.Add();
	Resources.Attribute = NStr("en='Resources';ru='Ресурсы'");
	Resources.PredefinedRow = True;
	
	For Each CurRow In CurrentObject.LoadSettings Do
		If CurRow.ReadMethod = Enums.fmReadMethods.DontRead
		OR CurRow.ReadMethod = Enums.fmReadMethods.FixedValue
		OR CurRow.ReadMethod = Enums.fmReadMethods.Cell Then
			// Настройки для таблицы.
			NewLine = LoadSettings.Add();
			FillPropertyValues(NewLine, CurRow);
			NewLine.TypeRestriction = CurRow.ValueType.Get();
			If NewLine.Attribute = "Scenario" OR NewLine.Attribute = "Department" OR NewLine.Attribute = "Project"
			OR NewLine.Attribute = "Item" OR NewLine.Attribute = "CorDepartment" OR NewLine.Attribute = "Currency" Then
				NewLine.SynchronizationIsAvailable = True;
			EndIf;
			NewLine.Attribute = GetSynonym(NewLine, NameSynonymMap);
		Else
			// Настройки для дерева.
			If CurRow.ReadMethod = Enums.fmReadMethods.Row Then
				AddRowInTree(CurRow, Rows, NameSynonymMap, SynonymNameMap);
			ElsIf CurRow.ReadMethod = Enums.fmReadMethods.Column Then
				AddRowInTree(CurRow, Columns, NameSynonymMap, SynonymNameMap);
			Else
				AddRowInTree(CurRow, Resources, NameSynonymMap, SynonymNameMap);
			EndIf;
		EndIf;
	EndDo;
	
EndProcedure

Procedure LoadTemplateBeforeWriteAtServer(CurrentObject, SettingsTree, LoadSettings, SynonymNameMap, Cancel) Export
	
	//ПроверитьЗащиту();
	//Если NOT ПроверитьБитМаски(1) Тогда
	//	ВызватьИсключение НСтр("ru = 'Функционал подсистемы <Бюджетирование> NOT активирован.
	//	|По вопросам демонстрации AND приобретения
	//	|обращаться +7-495-231-20-02 или fm@rarus.ru'");
	//КонецЕсли;
	
	// Чистим ТЧ.
	CurrentObject.LoadSettings.Clear();
	
	// Переносим табличные настройки в ТЧ.
	For Each CurRow In LoadSettings Do
		NewLine = CurrentObject.LoadSettings.Add();
		FillPropertyValues(NewLine, CurRow);
		NewLine.Attribute = GetName(NewLine, SynonymNameMap);
		NewLine.ValueType = New ValueStorage(CurRow.TypeRestriction, New Deflation(9));
	EndDo;
	
	// Перенесем дерево в ТЧ.
	For Each CurRow In SettingsTree.Rows Do
		If CurRow.Attribute = NStr("en='Rows';ru='Строки'") Then
			ReadMethod = PredefinedValue("Enum.fmReadMethods.Row");
		ElsIf CurRow.Attribute = NStr("en='Columns';ru='Columns'") Then
			ReadMethod = PredefinedValue("Enum.fmReadMethods.Column");
		Else
			ReadMethod = PredefinedValue("Enum.fmReadMethods.Resource");
		EndIf;
		SaveTree(CurRow, ReadMethod, CurrentObject, SynonymNameMap, Cancel);
	EndDo;
	
EndProcedure

Procedure LoadTemplateOnCreateAtServer(SettingsTree, LoadSettings, CopyingValue, NameSynonymMap, SynonymNameMap) Export
	
	//ПроверитьЗащиту();
	//Если NOT ПроверитьБитМаски(1) Тогда
	//	ВызватьИсключение НСтр("ru = 'Функционал подсистемы <Бюджетирование> NOT активирован.
	//	|По вопросам демонстрации AND приобретения
	//	|обращаться +7-495-231-20-02 или fm@rarus.ru'");
	//КонецЕсли;
	
	// Заполним дерево строками по-умолчанию.
	CurItems = SettingsTree.Rows;
	Rows = CurItems.Add();
	Rows.Attribute = NStr("en='Rows';ru='Строки'");
	Rows.PredefinedRow = True;
	Columns = CurItems.Add();
	Columns.Attribute = NStr("en='Columns';ru='Columns'");
	Columns.PredefinedRow = True;
	Resources = CurItems.Add();
	Resources.Attribute = NStr("en='Resources';ru='Ресурсы'");
	Resources.PredefinedRow = True;
	
	If NOT ValueIsFilled(CopyingValue) Then
		
		// Реквизиты.
		NewLine = LoadSettings.Add();
		NewLine.ReadMethod = Enums.fmReadMethods.FixedValue;
		NewLine.TypeRestriction = New TypeDescription("CatalogRef.fmBudgetingScenarios");
		NewLine.SynchronizationIsAvailable = True;
		NewLine.Attribute = GetSynonym("Scenario", NameSynonymMap);
		NewLine.Sheet = NStr("en='Sheet1';ru='Лист1'");
		
		NewLine = LoadSettings.Add();
		NewLine.ReadMethod = Enums.fmReadMethods.FixedValue;
		NewLine.TypeRestriction = New TypeDescription("CatalogRef.fmDepartments");
		NewLine.SynchronizationIsAvailable = True;
		NewLine.Attribute = GetSynonym("Department", NameSynonymMap);
		NewLine.Sheet = NStr("en='Sheet1';ru='Лист1'");
		
		NewLine = LoadSettings.Add();
		NewLine.ReadMethod = Enums.fmReadMethods.FixedValue;
		NewLine.TypeRestriction = New TypeDescription("DATE", , , New DateQualifiers(DateFractions.DATE));
		NewLine.Attribute = GetSynonym("BeginOfPeriod", NameSynonymMap);
		NewLine.Sheet = NStr("en='Sheet1';ru='Лист1'");
		
		NewLine = LoadSettings.Add();
		NewLine.ReadMethod = Enums.fmReadMethods.FixedValue;
		NewLine.TypeRestriction = New TypeDescription("EnumRef.fmBudgetOperationTypes");
		NewLine.Attribute = GetSynonym("OperationType", NameSynonymMap);
		NewLine.Sheet = NStr("en='Sheet1';ru='Лист1'");
		
		NewLine = LoadSettings.Add();
		NewLine.ReadMethod = Enums.fmReadMethods.FixedValue;
		NewLine.TypeRestriction = New TypeDescription("CatalogRef.Currencies");
		NewLine.SynchronizationIsAvailable = True;
		NewLine.Attribute = GetSynonym("Currency", NameSynonymMap);
		NewLine.Sheet = NStr("en='Sheet1';ru='Лист1'");
		
		If Constants.fmProjectAccounting.Get() Then
			NewLine = LoadSettings.Add();
			NewLine.ReadMethod = Enums.fmReadMethods.FixedValue;
			NewLine.TypeRestriction = New TypeDescription("CatalogRef.fmProjects");
			NewLine.SynchronizationIsAvailable = True;
			NewLine.Attribute = GetSynonym("Project", NameSynonymMap);
			NewLine.Sheet = NStr("en='Sheet1';ru='Лист1'");
		EndIf;
		
	Else
		
		For Each CurRow In CopyingValue.LoadSettings Do
			If CurRow.ReadMethod = Enums.fmReadMethods.DontRead
			OR CurRow.ReadMethod = Enums.fmReadMethods.FixedValue
			OR CurRow.ReadMethod = Enums.fmReadMethods.Cell Then
				// Настройки для таблицы.
				NewLine = LoadSettings.Add();
				FillPropertyValues(NewLine, CurRow);
				NewLine.TypeRestriction = CurRow.ValueType.Get();
				If NewLine.Attribute = "Scenario" OR NewLine.Attribute = "Department" OR NewLine.Attribute = "Project"
				OR NewLine.Attribute = "Item" OR NewLine.Attribute = "CorDepartment" OR NewLine.Attribute = "Currency" Then
					NewLine.SynchronizationIsAvailable = True;
				EndIf;
				NewLine.Attribute = GetSynonym(NewLine, NameSynonymMap);
			Else
				// Настройки для дерева.
				If CurRow.ReadMethod = Enums.fmReadMethods.Row Then
					AddRowInTree(CurRow, Rows, NameSynonymMap, SynonymNameMap);
				ElsIf CurRow.ReadMethod = Enums.fmReadMethods.Column Then
					AddRowInTree(CurRow, Columns, NameSynonymMap, SynonymNameMap);
				Else
					AddRowInTree(CurRow, Resources, NameSynonymMap, SynonymNameMap);
				EndIf;
			EndIf;
		EndDo;
		
	EndIf;
	
EndProcedure

Procedure AddRowInTree(CurRow, TreeRow, NameSynonymMap, SynonymNameMap);
	
	// Добавим новую строку в дерево AND скопируем значения.
	If NOT TreeRow.PredefinedRow AND CurRow.ParentAttribute<>GetName(TreeRow, SynonymNameMap) Then
		CurParent = TreeRow.Parent;
		CurItems = CurParent.Rows;
		NewLine = CurItems.Add();
		NewLine.FlatSetting = True;
	Else
		CurItems = TreeRow.Rows;
		NewLine = CurItems.Add();
	EndIf;
	
	FillPropertyValues(NewLine, CurRow);
	NewLine.Attribute = GetSynonym(NewLine, NameSynonymMap);
	
	// В зависимости от способа считывания присвоим разные значения в НомColumnsСтроки
	If CurRow.ReadMethod = Enums.fmReadMethods.Row Then
		NewLine.ColumnRowNum = CurRow.ColumnNum;
		If NOT NewLine.FlatSetting Then
			NewLine.FiltersSettings = GenerateFilterText(NewLine);
			NewLine.EndConditions = GenerateConditionsText(NewLine);
			NewLine.BeginConditions = GenerateConditionsText(NewLine, True);
		EndIf;
	ElsIf CurRow.ReadMethod = Enums.fmReadMethods.Column Then
		NewLine.ColumnRowNum = CurRow.RowNum;
		If NOT NewLine.FlatSetting Then
			NewLine.FiltersSettings = GenerateFilterText(NewLine);
			NewLine.EndConditions = GenerateConditionsText(NewLine);
			NewLine.BeginConditions = GenerateConditionsText(NewLine, True);
		EndIf;
	Else
		// У ресурса есть только ном колонки.
		NewLine.IsResource = True;
	EndIf;
	
	// Тип получим из хранилищ.
	NewLine.TypeRestriction = CurRow.ValueType.Get();
	
	// Настройки синхронизации 
	NewLine.SynchronizationIsAvailable = ?(ValueIsFilled(CurRow.SynchronizationMethod), True, False);
	
	TreeRow = NewLine;
	
EndProcedure // AddСтрокуВДерево()

Function DeleteSymbols(VAL String)
	
	// Массив символов, подлежащих удалению.
	SymbolArray = New Array();
	SymbolArray.Add(" ");
	SymbolArray.Add(".");
	SymbolArray.Add(",");
	SymbolArray.Add("&");
	
	// Уберем ненужные символы.
	For Each CurSymbol In SymbolArray Do
		String = StrReplace(String, CurSymbol, "")
	EndDo;
	
	Return String;
	
EndFunction // УбратьСимволы()

Function GetName(CurRow, SynonymNameMap)
	If TypeOf(CurRow)=Type("String") Then
		AttributeSynonym = DeleteSymbols(CurRow);
	ElsIf ValueIsFilled(CurRow.TSName) Then
		AttributeSynonym = CurRow.TSName + DeleteSymbols(CurRow.Attribute);
	Else
		AttributeSynonym = DeleteSymbols(CurRow.Attribute);
	EndIf;
	Try
		Return SynonymNameMap[AttributeSynonym];
	Except
		Try
			Return StrReplace(AttributeSynonym, CurRow.TSName, "");
		Except
			Return CurRow;
		EndTry;
	EndTry;
EndFunction // ПолучитьСиноним()

Function GetSynonym(CurRow, NameSynonymMap)
	If TypeOf(CurRow) = Type("String") Then
		AttributeName = CurRow;
	Else 
		If ValueIsFilled(CurRow.TSName) Then
			AttributeName = CurRow.TSName + CurRow.Attribute;
		Else
			AttributeName = CurRow.Attribute;
		EndIf;
	EndIf;
	Try
		Return NameSynonymMap[AttributeName];
	Except
		If TypeOf(CurRow) = Type("String") Then
			Return AttributeName;
		Else
			Return StrReplace(AttributeName, CurRow.TSName, "");
		EndIf;
	EndTry;
EndFunction // ПолучитьСиноним()

Procedure SaveTree(String, ReadMethod, CurrentObject, SynonymNameMap, Cancel)
	For Each CurRow In String.Rows Do
		// Выполним проверку заполнения строки дерева.
		If ReadMethod = Enums.fmReadMethods.Column OR ReadMethod = Enums.fmReadMethods.Row Then
			If NOT ValueIsFilled(CurRow.ColumnRowNum) Then
				CommonClientServer.MessageToUser(NStr("ru = 'Не указано ""№ колнки/строки"" для настроек ""'; en = 'Not specified ""№ column/row"" for the setting ""'")+CurRow.Attribute+"", , , , Cancel);
			EndIf;
			If NOT CurRow.FlatSetting Then
				If NOT ValueIsFilled(CurRow.SpanBegin) Then
					CommonClientServer.MessageToUser(NStr("ru = 'Не указано ""Начало диапазона"" для настроек ""'; en = 'Not specified ""Beginning of range"" for the setting ""'")+CurRow.Attribute+"", , , , Cancel);
				EndIf;
				If NOT ValueIsFilled(CurRow.SpanEnd) AND NOT CurRow.ConditionByValue AND NOT CurRow.ConditionByIndent AND NOT CurRow.ConditionByTextColor AND NOT CurRow.ConditionByBackColor AND NOT CurRow.ConditionByFont Then
					CommonClientServer.MessageToUser(NStr("ru = 'Необходимо указать ""Конец диапозона"" или настроить условия окончания для настроек ""'; en = '""End of range"" or condition of ending must be specified for the setting ""'")+CurRow.Attribute+"", , , , Cancel);
				EndIf;
			EndIf;
		EndIf;
		NewLine = CurrentObject.LoadSettings.Add();
		FillPropertyValues(NewLine, CurRow);
		NewLine.Attribute = GetName(NewLine, SynonymNameMap);
		CurParent = CurRow.Parent;
		If NOT CurParent.PredefinedRow Then
			NewLine.ParentAttribute = GetName(CurParent, SynonymNameMap);
		EndIf;
		NewLine.ReadMethod = ReadMethod;
		NewLine.Sheet = CurrentObject.DefaultSheet;
		NewLine.ValueType = New ValueStorage(CurRow.TypeRestriction, New Deflation(9));
		If ReadMethod = Enums.fmReadMethods.Row Then
			NewLine.ColumnNum = CurRow.ColumnRowNum;
		ElsIf ReadMethod = Enums.fmReadMethods.Column Then
			NewLine.RowNum = CurRow.ColumnRowNum;
		EndIf;
		SaveTree(CurRow, ReadMethod, CurrentObject, SynonymNameMap, Cancel);
	EndDo;
EndProcedure // СохранитьДерево()

Function GenerateFilterText(NewLine)
	// Сформируем текст настроек отбора считывания.
	FilterText = NStr("ru = 'Настроены фильтры'; en = 'Configured filters'");
	If NewLine.ConditionByBackColor Then
		FilterText = FilterText + NStr("en=' by background color,';ru=' по цвету фона,'");
	EndIf;
	If NewLine.TextColorFilter Then
		FilterText = FilterText + NStr("en=' by text color,';ru=' по цвету текста,'");
	EndIf;
	If NewLine.FontFilter Then
		FilterText = FilterText + NStr("en=' by font,';ru=' по шрифту,'");
	EndIf;
	If NewLine.FilterByIndent Then
		FilterText = FilterText + NStr("en=' by indent,';ru=' по отступу,'");
	EndIf;
	If NewLine.FilterByValue Then
		FilterText = FilterText + NStr("en=' by value,';ru=' по значению,'");
	EndIf;
	If FilterText = NStr("ru = 'Настроены Filters'; en = 'Configured filters'") Then 
		FilterText = NStr("ru = 'Настроить Filters'; en = 'Configure filters'");
	Else
		FilterText = Left(FilterText, StrLen(FilterText)-1);
	EndIf;
	Return FilterText;
EndFunction // СформироватьТекстОтбора()

Function GenerateConditionsText(NewLine, BeginConditions=False)
	// Сформируем текст настроек отбора считывания.
	Text = ?(BeginConditions, NStr("en='Start-of-import routine conditions customized';ru='Настроены условия начала'"), NStr("en='End-of-import routine conditions customized';ru='Настроены условия окончания'"));
	If ?(BeginConditions, NewLine.ConditionBeginByBackColor, NewLine.ConditionByBackColor) Then
		Text = Text + NStr("en=' by background color,';ru=' по цвету фона,'");
	EndIf;
	If ?(BeginConditions, NewLine.ConditionBeginByTextColor, NewLine.ConditionByTextColor) Then
		Text = Text + NStr("en=' by text color,';ru=' по цвету текста,'");
	EndIf;
	If ?(BeginConditions, NewLine.ConditionBeginByFont, NewLine.ConditionByFont) Then
		Text = Text + NStr("en=' by font,';ru=' по шрифту,'");
	EndIf;
	If ?(BeginConditions, NewLine.ConditionBeginByIndent, NewLine.ConditionByIndent) Then
		Text = Text + NStr("en=' by indent,';ru=' по отступу,'");
	EndIf;
	If ?(BeginConditions, NewLine.ConditionBeginByValue, NewLine.ConditionByValue) Then
		Text = Text + NStr("en=' by value,';ru=' по значению,'");
	EndIf;
	If Text = ?(BeginConditions, NStr("en='Start-of-import routine conditions customized';ru='Настроены условия начала'"), NStr("en='End-of-import routine conditions customized';ru='Настроены условия окончания'")) Then 
		Text = ?(BeginConditions, NStr("en='Configure start conditions';ru='Настроить условия начала'"), NStr("en='Configure end conditions';ru='Настроить условия окончания'"));
	Else
		Text = Left(Text, StrLen(Text)-1);
	EndIf;
	Return Text;
EndFunction // СформироватьТекстУсловий()

Function GetDepartmentTree(Report, DepartmentTree, FRTree = Undefined, IncludingMarked = True, StructureVersion = Undefined) Export
	
	//ПроверитьЗащиту();
	//Если NOT ПроверитьБитМаски(1) Тогда
	//	ВызватьИсключение НСтр("ru = 'Функционал подсистемы <Бюджетирование> не активирован.
	//	|По вопросам демонстрации AND приобретения
	//	|обращаться +7-495-231-20-02 или fm@rarus.ru'");
	//КонецЕсли;
	
	Query = New Query();
	Query.TempTablesManager = New TempTablesManager; 
	Query.Text = "SELECT
	| DepartmentHierarchy.Department AS Department,
	| DepartmentHierarchy.Department.Description AS Description,
	| DepartmentHierarchy.Department.Code AS Code,
	| ISNULL(DepartmentHierarchy.DepartmentParent.Code, """") AS ParentCode,
	| DepartmentHierarchy.DepartmentParent AS Parent,
	| DepartmentHierarchy.Level AS Level,
	| DepartmentHierarchy.Department.SetColor AS SetIndColor,
	| DepartmentHierarchy.Department.Color AS ColorOrder,
	| DepartmentHierarchy.Department.DepartmentType AS DepartmentDepartmentType,
	| DepartmentHierarchy.DeletionMark AS DeletionMark
	|INTO DepartmentTable
	|FROM
	| InformationRegister.fmDepartmentHierarchy AS DepartmentHierarchy
	|WHERE
	|//{VersionFilter}
	|//{FilterByMarked}
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	| DepartmentHierarchy.Department AS Department,
	| DepartmentHierarchy.Description AS Description,
	| DepartmentHierarchy.Code AS Code,
	| DepartmentHierarchy.ParentCode AS ParentCode,
	| DepartmentHierarchy.Parent AS Parent,
	| DepartmentsStateSliceLast.DepartmentType AS DepartmentType,
	| DepartmentHierarchy.Level AS Level,
	| DepartmentHierarchy.DeletionMark AS DeletionMark
	| //{FieldsResponsible}
	|//{GettingFR}
	|FROM
	| DepartmentTable AS DepartmentHierarchy
	|  LEFT JOIN InformationRegister.fmDepartmentsState.SliceLast AS DepartmentsStateSliceLast
	|  ON DepartmentHierarchy.Department = DepartmentsStateSliceLast.Department
	| //{ConditionWithoutNotBudgeted}";
	
	If NOT StructureVersion = Undefined Then
		Query.Text = StrReplace(Query.Text, "//{VersionFilter}", "DepartmentHierarchy.StructureVersion = &StructureVersion");
		Query.SetParameter("StructureVersion", StructureVersion);
	EndIf;
	
	If NOT IncludingMarked = True  AND
		NOT Report.BudgetingFRFlag Then
		
		Query.Text = StrReplace(Query.Text, "//{FilterByMarked}", " AND NOT DepartmentHierarchy.DeletionMark");
	EndIf;
	
	If Report.InfoManager Then
		
		Query.Text = StrReplace(Query.Text, "//{FieldsResponsible}", ", DepartmentsStateSliceLast.Responsible AS Manager");
		
		Query.Text = StrReplace(Query.Text, "//{ResponsibleJoin}", " LEFT JOIN InformationRegister.Responsible.SliceLast(&SlicePeriodBegin, Item = VALUE(Catalog.ExpenditureItems.EmptyRef)) AS Responsible
		| ON DepartmentHierarchy.Department = Responsible.Department");
		
		Query.SetParameter("SlicePeriodBegin", Report.StructureVersion.ApprovalDate);
	Else
		
		Query.Text = StrReplace(Query.Text, "//{FieldsResponsible}", ", NULL AS Manager");
		
	EndIf;
	
	If Report.BudgetingFRFlag Then
		
		Query.Text = StrReplace(Query.Text, "//{GettingFR}", "INTO DepartmentsWithoutFR");
		
		Query.Execute();
		
		Query.SetParameter("FRTree", FRTree);
		Query.Text = "SELECT DISTINCT
		| FRTree.Department AS _Department,
		| FRTree.Amount
		|INTO FRTree
		|FROM
		| &FRTree AS FRTree
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		| *,
		| ISNULL(FRTree.Amount, 0) AS FinResCurrentOrder
		|FROM
		| DepartmentsWithoutFR AS DepartmentsWithoutFR
		|  LEFT JOIN FRTree AS FRTree
		|  ON DepartmentsWithoutFR.Department = FRTree._Department
		|//{FilterByMarked}
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|DROP FRTree";
		
		If NOT IncludingMarked = True Then
			
			// Вывод NOT помеченных на удаление подразделений или помеченных, но только тех, у которых есть финансовый результат
			Query.Text = StrReplace(Query.Text, "//{FilterByMarked}", "WHERE 
			| (NOT DepartmentsWithoutFR.DeletionMark
			| OR NOT ISNULL(FRTree.Amount, 0) = 0)");
		EndIf;
		
	Else
		Query.Text = StrReplace(Query.Text, "//{GettingFR}", ",0 AS FinResCurrentOrder");
	EndIf;
	
	DepartmentTable = Query.Execute().Unload();
	DepartmentTable.Indexes.Add("Code");
	DepartmentTable.Indexes.Add("ParentCode");
	
	Return DepartmentTable;
	
EndFunction // ПолучитьТаблицуПодразделений()

Procedure BudgetTreeIteration(BudgetTree, InitialDataVTAddress, UUID, DetailsDataObject, SearchColumnsRow, ViewFormat, EditFormat, ResourcesCount, BackColorEdt, BackColorAuto=Undefined) Export
	
	//ПроверитьЗащиту();
	//Если NOT ПроверитьБитМаски(1) Тогда
	//	ВызватьИсключение НСтр("ru = 'Функционал подсистемы <Бюджетирование> NOT активирован.
	//	|По вопросам демонстрации AND приобретения
	//	|обращаться +7-495-231-20-02 или fm@rarus.ru'");
	//КонецЕсли;
	
	DetailsFieldsRow = SearchColumnsRow + ", RowID, ParentID";
	
	// Пропишем заголовок для ресурсов.
	CurrentArea = BudgetTree.Area(1, 2, 1, 2);
	CurrentArea.Text = NStr("en='Resources';ru='Ресурсы'");
	
	InitialDataVT = New ValueTable();
	InitialDataVT.Columns.Add("Section", New TypeDescription("CatalogRef.fmInfoStructuresSections"));
	InitialDataVT.Columns.Add("SectionParent", New TypeDescription("CatalogRef.fmInfoStructuresSections"));
	InitialDataVT.Columns.Add("Analytics", New TypeDescription("CatalogRef.fmIncomesAndExpensesItems, CatalogRef.fmCashflowItems"));
	InitialDataVT.Columns.Add("Period", New TypeDescription("Date"));
	InitialDataVT.Columns.Add("Resource_Amount", New TypeDescription("Number"));
	InitialDataVT.Columns.Add("CoordColumn_Amount", New TypeDescription("Number"));
	InitialDataVT.Columns.Add("CoordRow_Amount", New TypeDescription("Number"));
	InitialDataVT.Columns.Add("RecordType", New TypeDescription("EnumRef.fmBudgetFlowOperationTypes"));
	InitialDataVT.Columns.Add("Formula", New TypeDescription("String",, New StringQualifiers(500, AllowedLength.Variable)));
	InitialDataVT.Columns.Add("Analytics1", Metadata.ChartsOfCharacteristicTypes.fmAnalyticsTypes.Type);
	InitialDataVT.Columns.Add("Analytics2", Metadata.ChartsOfCharacteristicTypes.fmAnalyticsTypes.Type);
	InitialDataVT.Columns.Add("Analytics3", Metadata.ChartsOfCharacteristicTypes.fmAnalyticsTypes.Type);
	InitialDataVT.Columns.Add("Edit", New TypeDescription("Boolean"));
	InitialDataVT.Columns.Add("Order", New TypeDescription("Number"));
	InitialDataVT.Columns.Add("RowID", New TypeDescription("String",, New StringQualifiers(36, AllowedLength.Variable)));
	InitialDataVT.Columns.Add("ParentID", New TypeDescription("String",, New StringQualifiers(36, AllowedLength.Variable)));
	InitialDataVT.Columns.Add("Comment", New TypeDescription("String"));
	InitialDataVT.Columns.Add("CommentVersion", New TypeDescription("Date"));
	
	// Обойдем ячейки табличного документа для сопоставления с ТЗ исходных данных.
	// Обход каждой ячейки табличного документа.
	For AreaRow = 2 To BudgetTree.TableHeight Do
		For AreaColumn = 1 To BudgetTree.TableWidth Do
			
			CurrentArea = BudgetTree.Area(AreaRow, AreaColumn, AreaRow, AreaColumn);
			If CurrentArea.Details = Undefined Then
				Continue;
			EndIf;
			
			// Получение структуры значений расшифровки.
			DetailsTotalValues = DetailsDataObject.Items[CurrentArea.Details].GetFields();
			
			// Часть параметров лежит в 1-ой колонке, строка должна делиться без остатка на количество ресурсов.
			If AreaColumn=1 AND (AreaRow-2)%ResourcesCount=0 Then
				
				CurEdit = False;
				CurRecordType = Enums.fmBudgetFlowOperationTypes.EmptyRef();
				CurSectionParent = Catalogs.fmInfoStructuresSections.EmptyRef();
				
				// Заполняем структуру для поиска в ТЗИсходных данных строки, которая соответсвтует текущей ячейке.
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
				CurComment = "";
				For Each DetailsFieldValue In DetailsTotalValues Do
					If DetailsFieldValue.Field="Period" Then
						FS[DetailsFieldValue.Field] = DetailsFieldValue.Value;
					EndIf;
					If Find(DetailsFieldValue.Field, "Resource_") Then
						CurResourceName = DetailsFieldValue.Field;
					EndIf;
					If DetailsFieldValue.Field="Comment" Then
						CurComment = DetailsFieldValue.Value;
					EndIf;
				EndDo;
				
				If DetailsTotalValues.Count() Then
					AllNulls = True;
					For Each DetailsFieldValue In DetailsTotalValues Do
						If FS.Property(DetailsFieldValue.Field) AND FS[DetailsFieldValue.Field] <> NULL Then
							AllNulls = False;
						EndIf;
					EndDo;
					// Значения полей расшифровки есть, но они NOT заполнены.
					If AllNulls Then
						// Удаление такой расшифровки.
						CurrentArea.Details = Undefined;
						If NOT BackColorAuto=Undefined Then
							CurrentArea.BackColor		= BackColorAuto;
						EndIf;
						Continue;
					EndIf;
				EndIf;
				
				// Поиск группировки квартал в родительских, если найдена, значит редактировать такую ячейку нельзя, удаление расшифровки.
				ParentDetails = DetailsDataObject.Items[CurrentArea.Details].GetParents();
				If ParentDetails.Count() Then
					ParentFieldsValues = DetailsDataObject.Items[ParentDetails[0].ID].GetFields();
					For Each CurParentFieldValue In ParentFieldsValues Do
						If Find(CurParentFieldValue.Field, "Quarter") Then
							CurrentArea.Details = Undefined;
							If NOT BackColorAuto=Undefined Then
								CurrentArea.BackColor		= BackColorAuto;
							EndIf;
							Break;
						EndIf;
					EndDo;
					If CurrentArea.Details = Undefined Then
						Continue;
					EndIf;
				EndIf;
				
				CurrentArea.ContainsValue	= True;
				CurrentArea.ValueType		= New TypeDescription("Number", , , New NumberQualifiers(17, 2));
				CurrentArea.Value = DetailsTotalValues.Find(CurResourceName).Value;
				CurrentArea.Format = ViewFormat;
				CurrentArea.EditFormat = EditFormat;
				
				// Если нет аналитики, значит ячейка NOT редактируется.
				If CurEdit Then
					// Делаем так, чтобы можно было редактировать текущую ячейку.
					CurrentArea.Protection		= False;
					CurrentArea.BackColor		= BackColorEdt;
					If ValueIsFilled(CurComment) Then
						CurrentArea.Comment.Text = CurComment;
					EndIf;
				ElsIf NOT BackColorAuto=Undefined Then
					CurrentArea.BackColor		= BackColorAuto;
				EndIf;
				
				// Запоминаем координаты ячейки в строке ТЗ.
				NewLine = InitialDataVT.Add();
				FillPropertyValues(NewLine, FS);
				NewLine["CoordColumn_"+StrReplace(CurResourceName, "Resource_", "")] = AreaColumn;
				NewLine["CoordRow_"+StrReplace(CurResourceName, "Resource_", "")] = AreaRow;
				NewLine[CurResourceName] = CurrentArea.Value;
				NewLine.SectionParent = CurSectionParent;
				NewLine.Edit = CurEdit;
				NewLine.RecordType = CurRecordType;
				NewLine.Order = CurOrder;
				NewLine.Comment = CurComment;
				
			EndIf;
			
		EndDo;
	EndDo;
	
	InitialDataVTAddress = PutToTempStorage(InitialDataVT, UUID);
	
EndProcedure

Procedure BudgetingPredictionTreeIterationCopy(BudgetTree, InitialDataVTAddress, UUID, DetailsDataObject, Query, SearchColumnsRow, ViewFormat, EditFormat, ResourcesCount, BackColorEdt, BackColorAuto=Undefined) Export
	
	//ПроверитьЗащиту();
	//Если NOT ПроверитьБитМаски(1) Тогда
	//	ВызватьИсключение НСтр("ru = 'Функционал подсистемы <Бюджетирование> NOT активирован.
	//	|По вопросам демонстрации AND приобретения
	//	|обращаться +7-495-231-20-02 или fm@rarus.ru'");
	//КонецЕсли;
	
	TempInitialDataVT = New ValueTable();
	TempInitialDataVT.Columns.Add("Section", New TypeDescription("CatalogRef.fmInfoStructuresSections"));
	TempInitialDataVT.Columns.Add("SectionParent", New TypeDescription("CatalogRef.fmInfoStructuresSections"));
	TempInitialDataVT.Columns.Add("Analytics", New TypeDescription("CatalogRef.fmIncomesAndExpensesItems, CatalogRef.fmCashflowItems"));
	TempInitialDataVT.Columns.Add("Period", New TypeDescription("Date"));
	TempInitialDataVT.Columns.Add("CoordRow_Amount", New TypeDescription("Number"));
	TempInitialDataVT.Columns.Add("CoordColumn_Amount", New TypeDescription("Number"));
	TempInitialDataVT.Columns.Add("CoordRow_InitialAmount", New TypeDescription("Number"));
	TempInitialDataVT.Columns.Add("CoordColumn_InitialAmount", New TypeDescription("Number"));
	TempInitialDataVT.Columns.Add("CoordRow_Delta", New TypeDescription("Number"));
	TempInitialDataVT.Columns.Add("CoordColumn_Delta", New TypeDescription("Number"));
	TempInitialDataVT.Columns.Add("Analytics1", Metadata.ChartsOfCharacteristicTypes.fmAnalyticsTypes.Type);
	TempInitialDataVT.Columns.Add("Analytics2", Metadata.ChartsOfCharacteristicTypes.fmAnalyticsTypes.Type);
	TempInitialDataVT.Columns.Add("Analytics3", Metadata.ChartsOfCharacteristicTypes.fmAnalyticsTypes.Type);
	TempInitialDataVT.Columns.Add("RowID", New TypeDescription("String",, New StringQualifiers(36, AllowedLength.Variable)));
	TempInitialDataVT.Columns.Add("ParentID", New TypeDescription("String",, New StringQualifiers(36, AllowedLength.Variable)));
	
	DetailsFieldsRow = SearchColumnsRow + ", RowID, ParentID";
	
	// Пропишем заголовок для ресурсов.
	CurrentArea = BudgetTree.Area(1, 2, 1, 2);
	CurrentArea.Text = NStr("en='Resources';ru='Ресурсы'");
	
	InitialDataVT = New ValueTable();
	InitialDataVT.Columns.Add("Section", New TypeDescription("CatalogRef.fmInfoStructuresSections"));
	InitialDataVT.Columns.Add("SectionParent", New TypeDescription("CatalogRef.fmInfoStructuresSections"));
	InitialDataVT.Columns.Add("Analytics", New TypeDescription("CatalogRef.fmIncomesAndExpensesItems, CatalogRef.fmCashflowItems"));
	InitialDataVT.Columns.Add("Period", New TypeDescription("Date"));
	InitialDataVT.Columns.Add("Resource_Amount", New TypeDescription("Number"));
	InitialDataVT.Columns.Add("Resource_InitialAmount", New TypeDescription("Number"));
	InitialDataVT.Columns.Add("Resource_Delta", New TypeDescription("Number"));
	InitialDataVT.Columns.Add("CoordRow_Amount", New TypeDescription("Number"));
	InitialDataVT.Columns.Add("CoordColumn_Amount", New TypeDescription("Number"));
	InitialDataVT.Columns.Add("CoordRow_InitialAmount", New TypeDescription("Number"));
	InitialDataVT.Columns.Add("CoordColumn_InitialAmount", New TypeDescription("Number"));
	InitialDataVT.Columns.Add("CoordRow_Delta", New TypeDescription("Number"));
	InitialDataVT.Columns.Add("CoordColumn_Delta", New TypeDescription("Number"));
	InitialDataVT.Columns.Add("RecordType", New TypeDescription("EnumRef.fmBudgetFlowOperationTypes"));
	InitialDataVT.Columns.Add("Formula", New TypeDescription("String",, New StringQualifiers(500, AllowedLength.Variable)));
	InitialDataVT.Columns.Add("Analytics1", Metadata.ChartsOfCharacteristicTypes.fmAnalyticsTypes.Type);
	InitialDataVT.Columns.Add("Analytics2", Metadata.ChartsOfCharacteristicTypes.fmAnalyticsTypes.Type);
	InitialDataVT.Columns.Add("Analytics3", Metadata.ChartsOfCharacteristicTypes.fmAnalyticsTypes.Type);
	InitialDataVT.Columns.Add("Edit", New TypeDescription("Boolean"));
	InitialDataVT.Columns.Add("Order", New TypeDescription("Number"));
	InitialDataVT.Columns.Add("AnalyticsOrder", New TypeDescription("Number"));
	InitialDataVT.Columns.Add("RowID", New TypeDescription("String",, New StringQualifiers(36, AllowedLength.Variable)));
	InitialDataVT.Columns.Add("ParentID", New TypeDescription("String",, New StringQualifiers(36, AllowedLength.Variable)));
	
	// Обойдем ячейки табличного документа для сопоставления с ТЗ исходных данных.
	// Обход каждой ячейки табличного документа.
	For AreaRow = 2 To BudgetTree.TableHeight Do
		For AreaColumn = 1 To BudgetTree.TableWidth Do
			
			CurrentArea = BudgetTree.Area(AreaRow, AreaColumn, AreaRow, AreaColumn);
			If CurrentArea.Details = Undefined Then
				Continue;
			EndIf;
			
			// Получение структуры значений расшифровки.
			DetailsTotalValues = DetailsDataObject.Items[CurrentArea.Details].GetFields();
			
			// Часть параметров лежит в 1-ой колонке, строка должна делиться без остатка на количество ресурсов.
			If AreaColumn=1 AND (AreaRow-2)%ResourcesCount=0 Then
				
				CurEdit = False;
				CurSectionParent = Catalogs.fmInfoStructuresSections.EmptyRef();
				
				// Заполняем структуру для поиска в ТЗИсходных данных строки, которая соответсвтует текущей ячейке.
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
					If DetailsFieldValue.Field="SectionParent" Then
						CurSectionParent = DetailsFieldValue.Value;
					EndIf;
				EndDo;
				
			ElsIf DetailsTotalValues.Find("Resource_Amount") <> Undefined
			OR DetailsTotalValues.Find("Resource_InitialAmount") <> Undefined
			OR DetailsTotalValues.Find("Resource_Delta") <> Undefined Then
				
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
					// Значения полей расшифровки есть, но они NOT заполнены.
					If AllNulls Then
						// Удаление такой расшифровки.
						CurrentArea.Details = Undefined;
						If NOT BackColorAuto=Undefined Then
							CurrentArea.BackColor = BackColorAuto;
						EndIf;
						Continue;
					EndIf;
				EndIf;
				
				// Поиск группировки квартал в родительских, если найдена, значит редактировать такую ячейку нельзя, удаление расшифровки.
				ParentDetails = DetailsDataObject.Items[CurrentArea.Details].GetParents();
				If ParentDetails.Count() Then
					ParentFieldsValues = DetailsDataObject.Items[ParentDetails[0].ID].GetFields();
					For Each CurParentFieldValue In ParentFieldsValues Do
						If Find(CurParentFieldValue.Field, "Quarter") Then
							CurrentArea.Details = Undefined;
							If NOT BackColorAuto=Undefined Then
								CurrentArea.BackColor = BackColorAuto;
							EndIf;
							Break;
						EndIf;
					EndDo;
					If CurrentArea.Details = Undefined Then
						Continue;
					EndIf;
				EndIf;
				
				CurrentArea.ContainsValue	= True;
				CurrentArea.ValueType		= New TypeDescription("Number", , , New NumberQualifiers(17, 2));
				CurrentArea.Value = DetailsTotalValues.Find(CurResourceName).Value;
				CurrentArea.Format = ViewFormat;
				CurrentArea.EditFormat = EditFormat;
				
				// Если нет аналитики, значит ячейка NOT редактируется.
				If CurEdit Then
					If NOT StrReplace(CurResourceName, "Resource_", "")="InitialAmount"
					AND NOT StrReplace(CurResourceName, "Resource_", "")="Delta" Then
						// Делаем так, чтобы можно было редактировать текущую ячейку.
						CurrentArea.Protection			= False;
						CurrentArea.BackColor			= BackColorEdt;
					ElsIf NOT BackColorAuto=Undefined Then
						CurrentArea.BackColor = BackColorAuto;
					EndIf;
				ElsIf NOT BackColorAuto=Undefined Then
					CurrentArea.BackColor = BackColorAuto;
				EndIf;
				
				// Запоминаем координаты ячейки в строке ТЗ.
				NewLine = TempInitialDataVT.Add();
				FillPropertyValues(NewLine, FS);
				NewLine.SectionParent = CurSectionParent;
				NewLine["CoordColumn_"+StrReplace(CurResourceName, "Resource_", "")] = AreaColumn;
				NewLine["CoordRow_"+StrReplace(CurResourceName, "Resource_", "")] = AreaRow;
				
			EndIf;
			
		EndDo;
	EndDo;
	
	Query.Text = "SELECT
	               |	TTDataTempTable.Section AS Section,
	               |	TTDataTempTable.SectionParent AS SectionParent,
	               |	TTDataTempTable.Analytics AS Analytics,
	               |	TTDataTempTable.Analytics1 AS Analytics1,
	               |	TTDataTempTable.Analytics2 AS Analytics2,
	               |	TTDataTempTable.Analytics3 AS Analytics3,
	               |	TTDataTempTable.RowID AS RowID,
	               |	TTDataTempTable.ParentID AS ParentID,
	               |	TTDataTempTable.Period AS Period,
	               |	TTDataTempTable.CoordColumn_Amount AS CoordColumn_Amount,
	               |	TTDataTempTable.CoordRow_Amount AS CoordRow_Amount,
	               |	TTDataTempTable.CoordRow_InitialAmount AS CoordRow_InitialAmount,
	               |	TTDataTempTable.CoordColumn_InitialAmount AS CoordColumn_InitialAmount,
	               |	TTDataTempTable.CoordRow_Delta AS CoordRow_Delta,
	               |	TTDataTempTable.CoordColumn_Delta AS CoordColumn_Delta
	               |INTO TTDataTempTable
	               |FROM
	               |	&TTDataTempTable AS TTDataTempTable";
	Query.SetParameter("TTDataTempTable", TempInitialDataVT);
	Query.Execute();
	
	Query.Text = "SELECT
	               |	TTDataTempTable.Section AS Section,
	               |	TTDataTempTable.SectionParent AS SectionParent,
	               |	TTDataTempTable.Analytics AS Analytics,
	               |	TTDataTempTable.Analytics1 AS Analytics1,
	               |	TTDataTempTable.Analytics2 AS Analytics2,
	               |	TTDataTempTable.Analytics3 AS Analytics3,
	               |	TTDataTempTable.RowID AS RowID,
	               |	TTDataTempTable.ParentID AS ParentID,
	               |	TTDataTempTable.Period AS Period,
	               |	SUM(TTDataTempTable.CoordColumn_Amount) AS CoordColumn_Amount,
	               |	SUM(TTDataTempTable.CoordRow_Amount) AS CoordRow_Amount,
	               |	SUM(TTDataTempTable.CoordRow_InitialAmount) AS CoordRow_InitialAmount,
	               |	SUM(TTDataTempTable.CoordColumn_InitialAmount) AS CoordColumn_InitialAmount,
	               |	SUM(TTDataTempTable.CoordRow_Delta) AS CoordRow_Delta,
	               |	SUM(TTDataTempTable.CoordColumn_Delta) AS CoordColumn_Delta
	               |INTO TTDataTempTableCollapsed
	               |FROM
	               |	TTDataTempTable AS TTDataTempTable
	               |
	               |GROUP BY
	               |	TTDataTempTable.Section,
	               |	TTDataTempTable.Period,
	               |	TTDataTempTable.SectionParent,
	               |	TTDataTempTable.RowID,
	               |	TTDataTempTable.ParentID,
	               |	TTDataTempTable.Analytics,
	               |	TTDataTempTable.Analytics1,
	               |	TTDataTempTable.Analytics2,
	               |	TTDataTempTable.Analytics3
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
	               |	DataTableTT.AnalyticsOrder AS AnalyticsOrder,
	               |	DataTableTT.Period AS Period,
	               |	DataTableTT.Resource_Amount AS Resource_Amount,
	               |	DataTableTT.Resource_InitialAmount AS Resource_InitialAmount,
	               |	DataTableTT.Resource_Delta AS Resource_Delta,
	               |	DataTableTT.RecordType AS RecordType,
	               |	DataTableTT.Edit AS Edit,
	               |	TTDataTempTableCollapsed.RowID AS RowID,
	               |	TTDataTempTableCollapsed.ParentID AS ParentID,
	               |	TTDataTempTableCollapsed.CoordColumn_Amount AS CoordColumn_Amount,
	               |	TTDataTempTableCollapsed.CoordRow_Amount AS CoordRow_Amount,
	               |	TTDataTempTableCollapsed.CoordRow_InitialAmount AS CoordRow_InitialAmount,
	               |	TTDataTempTableCollapsed.CoordColumn_InitialAmount AS CoordColumn_InitialAmount,
	               |	TTDataTempTableCollapsed.CoordRow_Delta AS CoordRow_Delta,
	               |	TTDataTempTableCollapsed.CoordColumn_Delta AS CoordColumn_Delta
	               |FROM
	               |	DataTableTT AS DataTableTT
	               |		LEFT JOIN TTDataTempTableCollapsed AS TTDataTempTableCollapsed
	               |		ON DataTableTT.Section = TTDataTempTableCollapsed.Section
	               |			AND DataTableTT.SectionParent = TTDataTempTableCollapsed.SectionParent
	               |			AND DataTableTT.Analytics = TTDataTempTableCollapsed.Analytics
	               |			AND DataTableTT.Analytics1 = TTDataTempTableCollapsed.Analytics1
	               |			AND DataTableTT.Analytics2 = TTDataTempTableCollapsed.Analytics2
	               |			AND DataTableTT.Analytics3 = TTDataTempTableCollapsed.Analytics3
	               |			AND DataTableTT.Period = TTDataTempTableCollapsed.Period
	               |;
	               |
	               |////////////////////////////////////////////////////////////////////////////////
	               |DROP DataTableTT
	               |;
	               |
	               |////////////////////////////////////////////////////////////////////////////////
	               |DROP TTDataTempTable
	               |;
	               |
	               |////////////////////////////////////////////////////////////////////////////////
	               |DROP TTDataTempTableCollapsed";
	
	QueryResult = Query.Execute().Select();
	While QueryResult.Next() Do
		NewRow = InitialDataVT.Add();
		FillPropertyValues(NewRow, QueryResult);
	EndDo;
	
	InitialDataVTAddress = PutToTempStorage(InitialDataVT, UUID);
	
EndProcedure

Procedure OnCreateAtServerDistributionSteps(Cancel) Export
	//ПроверитьЗащиту();
	//Если NOT ПроверитьБитМаски(2) Тогда
	//	Отказ=Истина;
	//	ВызватьИсключение НСтр("ru = 'Функционал подсистемы <Распределение> NOT активирован.
	//	|По вопросам демонстрации AND приобретения
	//	|обращаться +7-495-231-20-02 или fm@rarus.ru'");
	//КонецЕсли;
EndProcedure

Function CallFillByScenario(DistributionScenario) Export
	
	//ПроверитьЗащиту();
	//Если NOT ПроверитьБитМаски(2) Тогда
	//	Отказ=Истина;
	//	ВызватьИсключение НСтр("ru = 'Функционал подсистемы <Распределение> NOT активирован.
	//	|По вопросам демонстрации AND приобретения
	//	|обращаться +7-495-231-20-02 или fm@rarus.ru'");
	//КонецЕсли;
	
	Query = New Query();
	Query.Text = "SELECT
	               |	fmBudgetDistributionSteps.Active,
	               |	fmBudgetDistributionSteps.Ref AS BudgetDistributionStep
	               |FROM
	               |	Catalog.fmBudgetDistributionSteps AS fmBudgetDistributionSteps
	               |WHERE
	               |	fmBudgetDistributionSteps.Owner = &DistributionScenario
	               |	AND (NOT fmBudgetDistributionSteps.DeletionMark)
	               |	AND (NOT fmBudgetDistributionSteps.IsFolder)
	               |
	               |ORDER BY
	               |	fmBudgetDistributionSteps.Order";
	Query.SetParameter("DistributionScenario", DistributionScenario);
	Return Query.Execute().Unload();
	
EndFunction




