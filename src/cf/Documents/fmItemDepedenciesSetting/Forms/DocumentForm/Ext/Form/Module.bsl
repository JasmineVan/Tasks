
#Region ProceduresAndFunctionsOfCommonUse

&AtClientAtServerNoContext
Function GenerateURLText(Object, ItemsSettings)
	If NOT ValueIsFilled(Object.Item) Then
		Return NStr("en='Select item';ru='Select статью'");
	EndIf;
	AnalyticsURL = "";
	For Num=1 To 3 Do
		If ValueIsFilled(Object["Analytics"+Num]) Then
			AnalyticsURL = AnalyticsURL + StrTemplate(NStr("en='Dimension%1 = ""%2"";%3';ru='Аналитика%1 = ""%2"";%3'"), Num, TrimAll(Object["Analytics"+Num]), Chars.LF);
		EndIf;
	EndDo;
	If NOT ValueIsFilled(AnalyticsURL) Then
		ItemSetting = ItemsSettings.FindRows(New Structure("Item", Object.Item));
		If NOT AnalyticsAreKnown(ItemSetting, Object) OR HasAnalytics(ItemSetting) Then
			AnalyticsURL = NStr("en='<Set up filter by dimensions>';ru='<Настроить отбор по аналитикам>'");
		Else
			AnalyticsURL = NStr("en='No analytics';ru='Аналитики отсутствуют'");
		EndIf;
	EndIf;
	Return AnalyticsURL;
EndFunction

&AtClientAtServerNoContext
Function AnalyticsAreKnown(ItemSetting, Object)
	If ItemSetting.Count()=0 Then
		Return False;
	Else
		If ItemSetting[0].ItemAnalyticsCount>0 Then
			Return True;
		Else
			Return False;
		EndIf;
	EndIf;
EndFunction

&AtClientAtServerNoContext
Function HasAnalytics(ItemSetting)
	If ItemSetting.Count()=0 Then
		Return False;
	Else
		For Num=1 To 3 Do
			If ValueIsFilled(ItemSetting[0]["AnalyticsType"+Num]) Then
				Return True;
			EndIf;
		EndDo;
		Return False;
	EndIf;
EndFunction

&AtClient
Function GenerateFillingText(NewLine)
	// Сформируем текст настроек отбора считывания.
	FillingText="";
	If NOT ValueIsFilled(NewLine.Item) Then
		FillingText = NStr("en='Specify an item';ru='Укажите статью'");
	Else
		ItemSetting = ItemsSettings.FindRows(New Structure("Item", NewLine.Item));
		AnalyticsAreKnown = AnalyticsAreKnown(ItemSetting, Object);
		For Num=1 To 3 Do
			If AnalyticsAreKnown AND ValueIsFilled(ItemSetting[0]["AnalyticsType"+Num])Then
				If NewLine["DependentAnalyticsFillingVariant"+Num]=PredefinedValue("Enum.fmDependentAnalyticsFillingVariants.DontFill") Then
					FillingText = FillingText + StrTemplate(NStr("en='Dimension %1 is not to filled in;%2';ru='Аналитика %1 не заполнять;%2'"), Num, Chars.LF);
				ElsIf NewLine["DependentAnalyticsFillingVariant"+Num]=PredefinedValue("Enum.fmDependentAnalyticsFillingVariants.FixedValue") Then
					FillingText = FillingText + StrTemplate(NStr("en='Dimension %1 = ""%2""%3';ru='Аналитика %1 = ""%2""%3'"), Num, ?(ValueIsFilled(NewLine["Analytics"+Num]), TrimAll(NewLine["Analytics"+Num]), "<Empty Value>"),Chars.LF);
				Else
					FillingText = FillingText + StrTemplate(NStr("en='Dimension %1 shall be taken from %2;%3';ru='Аналитика %1 взять из %2;%3'"), Num,  Lower(TrimAll(NewLine["DependentAnalyticsFillingVariant"+Num])),Chars.LF);
				EndIf;
			EndIf;
		EndDo;
	EndIf;
	Return FillingText;
EndFunction // СформироватьТекстОтбора()

&AtServer
Procedure FillAnalyticsTypes()
	// Настройки статей ТЧ.
	ItemsList = New Array();
	CashflowItem = False;
	For Each CurRow In Object.DependentItems Do
		If ValueIsFilled(CurRow.Item) Then
			ItemsList.Add(CurRow.Item);
		EndIf;
	EndDo;
	Settings = fmBudgeting.GetCustomAnalyticsSettings(ItemsList);
	ItemsSettings.Clear();
	For Each CurRow In Settings Do
		NewLine = ItemsSettings.Add();
		FillPropertyValues(NewLine, CurRow);
		NewLine.ItemAnalyticsCount = CurRow.Count;
	EndDo;
	// Настройка статьи шапки.
	If ValueIsFilled(Object.Item) Then
		ItemSetting = fmBudgeting.GetCustomAnalyticsSettings(Object.Item);
		If NOT ItemSetting=Undefined Then
			NewLine = ItemsSettings.Add();
			FillPropertyValues(NewLine, ItemSetting);
			NewLine.ItemAnalyticsCount = ItemSetting.Count;
		EndIf;
	EndIf;
EndProcedure

&AtClient
Procedure ChangeType()
	If Object.OperationType = PredefinedValue("Enum.fmDependenciesSettingOperationTypes.IncomesAndExpensesBudget") Then
		
		Items.Item.TypeRestriction = New TypeDescription("CatalogRef.fmIncomesAndExpensesItems");
		Items.DependentItemsItem.TypeRestriction = New TypeDescription("CatalogRef.fmIncomesAndExpensesItems");
		
	ElsIf Object.OperationType = PredefinedValue("Enum.fmDependenciesSettingOperationTypes.CashflowBudget") Then
		
		Items.Item.TypeRestriction = New TypeDescription("CatalogRef.fmCashflowItems");
		Items.DependentItemsItem.TypeRestriction = New TypeDescription("CatalogRef.fmCashflowItems");
		
	ElsIf Object.OperationType = PredefinedValue("Enum.fmDependenciesSettingOperationTypes.IncomesAndExpensesInCashflowBudget") Then
		
		Items.Item.TypeRestriction = New TypeDescription("CatalogRef.fmIncomesAndExpensesItems");
		Items.DependentItemsItem.TypeRestriction = New TypeDescription("CatalogRef.fmCashflowItems");
		
	ElsIf Object.OperationType = PredefinedValue("Enum.fmDependenciesSettingOperationTypes.CashflowInIncomesAndExpensesBudget") Then
		
		Items.Item.TypeRestriction = New TypeDescription("CatalogRef.fmCashflowItems");
		Items.DependentItemsItem.TypeRestriction = New TypeDescription("CatalogRef.fmIncomesAndExpensesItems");
		
	EndIf;
	
	ChoiceList = Items.DependentItemsMovementOperationType.ChoiceList;
	ChoiceList.Clear();
	If Object.OperationType = PredefinedValue("Enum.fmDependenciesSettingOperationTypes.CashflowBudget") 
		OR Object.OperationType = PredefinedValue("Enum.fmDependenciesSettingOperationTypes.IncomesAndExpensesInCashflowBudget") Then
		ChoiceList.Add(PredefinedValue("Enum.fmBudgetFlowOperationTypes.Inflow"));
		ChoiceList.Add(PredefinedValue("Enum.fmBudgetFlowOperationTypes.Outflow"));
	ElsIf Object.OperationType = PredefinedValue("Enum.fmDependenciesSettingOperationTypes.IncomesAndExpensesBudget") 
		OR Object.OperationType = PredefinedValue("Enum.fmDependenciesSettingOperationTypes.CashflowInIncomesAndExpensesBudget") Then
		ChoiceList.Add(PredefinedValue("Enum.fmBudgetFlowOperationTypes.Incomes"));
		ChoiceList.Add(PredefinedValue("Enum.fmBudgetFlowOperationTypes.Expenses"));
	EndIf;

EndProcedure

#EndRegion

#Region FormEventsHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	// Получим настройки для всех статей.
	FillAnalyticsTypes();
	AnalyticsURL = GenerateURLText(Object, ItemsSettings);
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	//Если Параметры.Ключ.Пустая() Тогда
	//	Элементы.Статья.ОграничениеТипа = Новый ОписаниеТипов("СправочникСсылка.уфСтатьиДоходовИРасходов");
	//	Элементы.ЗависимыеСтатьиСтатья.ОграничениеТипа = Новый ОписаниеТипов("СправочникСсылка.уфСтатьиДоходовИРасходов");
	//КонецЕсли;
	ChangeType();
	For Each CurRow In Object.DependentItems Do
		CurRow.FillingSettings = GenerateFillingText(CurRow);
	EndDo;
EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, RecordParameters)
	If RecordParameters.WriteMode = DocumentWriteMode.Posting AND Object.DependentItems.Count()=0 Then
		CommonClientServer.MessageToUser(NStr("en='Dependent cash flow items are not specified. ';ru='Не указаны зависимые статьи ДДС!'"), ,NStr("en='Object.DependentItems';ru='Object.DependentItems'"), , Cancel);
	EndIf;
EndProcedure

&AtClient
Procedure AfterWrite(RecordParameters)
	For Each CurRow In Object.DependentItems Do
		CurRow.FillingSettings = GenerateFillingText(CurRow);
	EndDo;
EndProcedure

&AtClient
Procedure ChoiceProcessing(ChosenValue, ChoiceSource)
	CurRow = Items.DependentItems.CurrentData;
	If NOT ChosenValue = Undefined Then
		FillPropertyValues(CurRow, ChosenValue);
		CurRow.FillingSettings = GenerateFillingText(CurRow);
	EndIf;
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	If EventName = "CashflowAnalytics" Then
		CurRow = Items.DependentItems.CurrentData;
		If NOT Parameter = Undefined Then
			FillPropertyValues(CurRow, Parameter);
			CurRow.FillingSettings = GenerateFillingText(CurRow);
		EndIf;
	ElsIf EventName = "IEAnalytics" Then
		If NOT Parameter=Undefined Then
			ItemSetting = ItemsSettings.FindRows(New Structure("Item", Object.Item));
			Object.Analytics1 = Parameter.Analytics1;
			Object.Analytics2 = Parameter.Analytics2;
			Object.Analytics3 = Parameter.Analytics3;
			AnalyticsURL = GenerateURLText(Object, ItemsSettings);
		EndIf;
	EndIf;
EndProcedure

#EndRegion

#Region FormItemsEventsHandlers

&AtClient
Procedure DependentItemsSelection(Item, SelectedRow, Field, StandardProcessing)
	If Field.Name = "DependentItemsFillingSetting" Then
		StandardProcessing = False;
		If ValueIsFilled(CurrentItem.CurrentData.FillingSettings) Then
			CurRow = Items.DependentItems.CurrentData;
			If ValueIsFilled(CurRow.Item) Then
				ItemSetting = ItemsSettings.FindRows(New Structure("Item", CurRow.Item));
				ParametersStructure = New Structure("Analytics1, Analytics2, Analytics3, DependentAnalyticsFillingVariant1, DependentAnalyticsFillingVariant2, DependentAnalyticsFillingVariant3");
				FillPropertyValues(ParametersStructure, CurRow.Item);
				ParametersStructure.Insert("Item", ItemSetting);
				ItemSettingArray = New Array();
				If ItemSetting.Count()>0 Then
					ItemSettingStructure = New Structure("Item, AnalyticsType1, AnalyticsType2, AnalyticsType3, ItemAnalyticsCount");
					FillPropertyValues(ItemSettingStructure, ItemSetting[0]);
					ItemSettingArray.Add(ItemSettingStructure);
				EndIf;
				ParametersStructure.Insert("ItemSetting", ItemSettingArray);
				ParametersStructure.Insert("AnalyticsAreKnown", AnalyticsAreKnown(ItemSetting, Object));
				Modified = True;
				FillPropertyValues(ParametersStructure, CurRow);
				OpenForm("Document.fmItemDepedenciesSetting.Form.AnalyticsSettingFormCashflow", ParametersStructure, ThisForm);
			Else
				CommonClientServer.MessageToUser(NStr("en='Specify an item!';ru='Укажите статью !'"), Object.Ref, "DependentItemsItem");
			EndIf;
		EndIf;
	EndIf;
EndProcedure

&AtClient
Procedure DependentItemsOnStartEdit(Item, NewLine, Copy)
	If NewLine AND NOT Copy Then
		CurRow = Items.DependentItems.CurrentData;
		CurRow.DependentAnalyticsFillingVariant1 = PredefinedValue("Enum.fmDependentAnalyticsFillingVariants.Analytics1");
		CurRow.DependentAnalyticsFillingVariant2 = PredefinedValue("Enum.fmDependentAnalyticsFillingVariants.Analytics2");
		CurRow.DependentAnalyticsFillingVariant3 = PredefinedValue("Enum.fmDependentAnalyticsFillingVariants.Analytics3");
		CurRow.Percent = 100;
		CurRow.FillingSettings = GenerateFillingText(CurRow);
		If Object.OperationType = PredefinedValue("Enum.fmDependenciesSettingOperationTypes.CashflowBudget") 
			OR Object.OperationType = PredefinedValue("Enum.fmDependenciesSettingOperationTypes.IncomesAndExpensesInCashflowBudget") Then
			CurRow.MovementOperationType = PredefinedValue("Enum.fmBudgetFlowOperationTypes.Inflow");
		ElsIf Object.OperationType = PredefinedValue("Enum.fmDependenciesSettingOperationTypes.IncomesAndExpensesBudget") 
			OR Object.OperationType = PredefinedValue("Enum.fmDependenciesSettingOperationTypes.CashflowInIncomesAndExpensesBudget") Then
			CurRow.MovementOperationType = PredefinedValue("Enum.fmBudgetFlowOperationTypes.Incomes");
		EndIf;
	EndIf;
EndProcedure

&AtClient
Procedure DependentItemsItemOnChange(Item)
	CurRow = Items.DependentItems.CurrentData;
	If ValueIsFilled(CurRow.Item) Then
		For IndexOf = 1 To 3 Do
			CurRow["Analytics"+IndexOf] = Undefined;
			CurRow["DependentAnalyticsFillingVariant" + IndexOf] = PredefinedValue("Enum.fmDependentAnalyticsFillingVariants.Analytics"+IndexOf);
		EndDo;
		ItemSetting = ItemsSettings.FindRows(New Structure("Item", CurRow.Item));
		If ItemSetting.Count()=0 Then
			ItemSetting = fmBudgeting.GetCustomAnalyticsSettings(CurRow.Item);
			If ItemSetting=Undefined Then
				AnalyticsAreKnown = AnalyticsAreKnown(New Array, Object);
				NewLine = New Structure("Item, AnalyticsType1, AnalyticsType2, AnalyticsType3, ItemAnalyticsCount");
			Else
				NewLine = ItemsSettings.Add();
				FillPropertyValues(NewLine, ItemSetting);
				NewLine.ItemAnalyticsCount = ItemSetting.Count;
				ArrayFromNewRow = New Array();
				ArrayFromNewRow.Add(NewLine);
				AnalyticsAreKnown = AnalyticsAreKnown(ArrayFromNewRow, Object);
			EndIf;
		Else
			AnalyticsAreKnown = AnalyticsAreKnown(ItemSetting, Object);
			NewLine = ItemSetting[0];
		EndIf;
		If AnalyticsAreKnown Then
			For Num=1 To 3 Do
				If ValueIsFilled(NewLine["AnalyticsType"+Num])
				AND NOT NewLine["AnalyticsType"+Num].Types()[0]=TypeOf(CurRow["Analytics"+Num]) Then
					CurRow["Analytics"+Num] = Undefined;
				EndIf;
			EndDo;
			If ValueIsFilled(NewLine.MovementOperationType) Then
				CurRow.MovementOperationType = NewLine.MovementOperationType;
			EndIf;
		EndIf;
		CurRow.FillingSettings = GenerateFillingText(CurRow);
	EndIf;
EndProcedure

&AtClient
Procedure AnalyticsURLClick(Item, StandardProcessing)
	StandardProcessing = False;
	If ValueIsFilled(Object.Item) AND NOT AnalyticsURL=NStr("en='No analytics';ru='Аналитики отсутствуют'") Then
		ItemSetting = ItemsSettings.FindRows(New Structure("Item", Object.Item));
		ItemSettingStructure = New Structure("Item, AnalyticsType1, AnalyticsType2, AnalyticsType3");
		If ItemSetting.Count()=0 Then
			ItemSettingStructure.Item = Object.Item;
		Else
			FillPropertyValues(ItemSettingStructure, ItemSetting[0]);
		EndIf;
		ParametersStructure = New Structure("Analytics1, Analytics2, Analytics3, ItemSetting, AnalyticsAreKnown", Object.Analytics1, Object.Analytics2, Object.Analytics3, ItemSettingStructure, AnalyticsAreKnown(ItemSetting, Object));
		OpenForm("Document.fmItemDepedenciesSetting.Form.AnalyticsSettingForm", ParametersStructure);
	EndIf;
EndProcedure

&AtClient
Procedure ItemOnChange(Item)
	If ValueIsFilled(Object.Item) Then
		For IndexOf = 1 To 3 Do
			Object["Analytics"+IndexOf] = Undefined;
		EndDo;
		ItemSetting = ItemsSettings.FindRows(New Structure("Item", Object.Item));
		If ItemSetting.Count()=0 Then
			//Если ТипЗнч(Объект.Статья) = Тип("СправочникСсылка.уфСтатьиДоходовИРасходов") Тогда
			//	СтатьяДДС = Ложь;
			//ИначеЕсли ТипЗнч(Объект.Статья) = Тип("СправочникСсылка.уфСтатьиДвиженияДенежныхСредств") Тогда
			//	СтатьяДДС = Истина;
			//КонецЕсли;
			ItemSetting = fmBudgeting.GetCustomAnalyticsSettings(Object.Item);
			If ItemSetting=Undefined Then
				AnalyticsAreKnown = AnalyticsAreKnown(New Array, Object);
				NewLine = New Structure("Item, AnalyticsType1, AnalyticsType2, AnalyticsType3, ItemAnalyticsCount");
			Else
				NewLine = ItemsSettings.Add();
				FillPropertyValues(NewLine, ItemSetting);
				NewLine.ItemAnalyticsCount = ItemSetting.Count;
				ArrayFromNewRow = New Array();
				ArrayFromNewRow.Add(NewLine);
				AnalyticsAreKnown = AnalyticsAreKnown(ArrayFromNewRow, Object);
			EndIf;
		Else
			AnalyticsAreKnown = AnalyticsAreKnown(ItemSetting, Object);
			NewLine = ItemSetting[0];
		EndIf;
		If AnalyticsAreKnown Then
			For Num=1 To 3 Do
				If ValueIsFilled(NewLine["AnalyticsType"+Num])
				AND NOT NewLine["AnalyticsType"+Num].Types()[0]=TypeOf(Object["Analytics"+Num]) Then
					Object["Analytics"+Num] = Undefined;
				EndIf;
			EndDo;
		EndIf;
		AnalyticsURL = GenerateURLText(Object, ItemsSettings);
	Else
		AnalyticsURL = GenerateURLText(Object, Undefined);
	EndIf;
EndProcedure

&AtClient
Procedure OperationTypeOnChange(Item)
	ChangeType();
	Object.Item = Undefined;
	Object.DependentItems.Clear();
	AnalyticsURL = GenerateURLText(Object, ItemsSettings);
EndProcedure

#EndRegion
