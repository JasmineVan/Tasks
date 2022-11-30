
#Region FormEventsHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	FillMaps();
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("Object", Object);
	AdditionalParameters.Insert("ItemNameForPlacement", "GroupAdditionalAttributes");
	// en script begin
	//PropertyManagement.OnCreateAtServer(ЭтаФорма, ДополнительныеПараметры);
	// en script end
	
	NewLine = TSAttributes.Add();
	NewLine.Attribute = "Analytics1";
	NewLine.Attribute = GetSynonym(NewLine, NameSynonymMap);
	
	NewLine = TSAttributes.Add();
	NewLine.Attribute = "Analytics2";
	NewLine.Attribute = GetSynonym(NewLine, NameSynonymMap);
	
	NewLine = TSAttributes.Add();
	NewLine.Attribute = "Analytics3";
	NewLine.Attribute = GetSynonym(NewLine, NameSynonymMap);
	
	NewLine = TSAttributes.Add();
	NewLine.Attribute = "Item";
	NewLine.Attribute = GetSynonym(NewLine, NameSynonymMap);
	
	NewLine = TSAttributes.Add();
	NewLine.Attribute = "BalanceUnit";
	NewLine.Attribute = GetSynonym(NewLine, NameSynonymMap);
	
	NewLine = TSAttributes.Add();
	NewLine.Attribute = "Department";
	NewLine.Attribute = GetSynonym(NewLine, NameSynonymMap);
	
	NewLine = TSAttributes.Add();
	NewLine.AttributeBalanceUnit = "CorBalanceUnit";
	NewLine.AttributeBalanceUnit = GetSynonym(NewLine, NameSynonymMap);
	
	NewLine = TSAttributes.Add();
	NewLine.AttributeBalanceUnit = "BalanceUnit";
	NewLine.AttributeBalanceUnit = GetSynonym(NewLine, NameSynonymMap);
	
	NewLine = TSAttributes.Add();
	NewLine.AttributeDepartments = "Department";
	NewLine.AttributeDepartments = GetSynonym(NewLine, NameSynonymMap);
	
	NewLine = TSAttributes.Add();
	NewLine.AttributeDepartments = "CorDepartment";
	NewLine.AttributeDepartments = GetSynonym(NewLine, NameSynonymMap);
	
	Query = New Query;
	Query.Text = "SELECT ALLOWED
	               |	EntriesTemplates.AccountDr AS AccountDr,
	               |	EntriesTemplates.AccountCr AS AccountCr,
	               |	EntriesTemplates.AmountCalculationRatio AS AmountCalculationRatio,
	               |	EntriesTemplates.OperationType AS OperationType,
	               |	EntriesTemplates.BalanceUnit AS BalanceUnit,
	               |	EntriesTemplates.ExtDimensionDr1 AS ExtDimensionDr1,
	               |	EntriesTemplates.ExtDimensionDr2 AS ExtDimensionDr2,
	               |	EntriesTemplates.ExtDimensionDr3 AS ExtDimensionDr3,
	               |	EntriesTemplates.ExtDimensionCr1 AS ExtDimensionCr1,
	               |	EntriesTemplates.ExtDimensionCr2 AS ExtDimensionCr2,
	               |	EntriesTemplates.ExtDimensionCr3 AS ExtDimensionCr3,
	               |	EntriesTemplates.DepartmentDr AS DepartmentDr,
	               |	EntriesTemplates.DepartmentCr AS DepartmentCr,
	               |	EntriesTemplates.FinancialResultDr AS FinancialResultDr,
	               |	EntriesTemplates.FinancialResultCr AS FinancialResultCr
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
	               |	TTEntriesTemplates.OperationType AS OperationType,
	               |	TTEntriesTemplates.BalanceUnit AS BalanceUnit,
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
	               |	) AS ExtDimensionTypes1,
	               |	TTEntriesTemplates.DepartmentDr AS DepartmentDr,
	               |	TTEntriesTemplates.DepartmentCr AS DepartmentCr,
	               |	fmBudgeting.FinancialResults AS FinancialResultDr,
	               |	fmBudgeting1.FinancialResults AS FinancialResultCr
	               |FROM
	               |	TTEntriesTemplates AS TTEntriesTemplates,
	               |	ChartOfAccounts.fmBudgeting AS fmBudgeting,
	               |	ChartOfAccounts.fmBudgeting AS fmBudgeting1
	               |WHERE
	               |	fmBudgeting.Ref = TTEntriesTemplates.AccountDr
	               |	AND fmBudgeting1.Ref = TTEntriesTemplates.AccountCr";
	Query.TempTablesManager = New TempTablesManager;
	TSUnloading = Object.EntriesTemplates.Unload();
	Query.SetParameter("EntriesTemplates", TSUnloading);
	QueryResult = Query.Execute().Unload();
	RowIndex = 0;
	For Each String In TSUnloading Do
		
		For Index = 1 To 3 Do
			String["ExtDimensionDr"+Index] = GetSynonym(String["ExtDimensionDr"+Index], NameSynonymMap);
			String["ExtDimensionCr"+Index] = GetSynonym(String["ExtDimensionCr"+Index], NameSynonymMap);
		EndDo;
		String.BalanceUnit = GetSynonym(String.BalanceUnit, NameSynonymMap);
		
		ExtDimensionTypes = QueryResult[RowIndex].ExtDimensionTypes;
		ExtDimensionTypes1 = QueryResult[RowIndex].ExtDimensionTypes1;
		Index = 1;
		For Each ExtDimensionType In ExtDimensionTypes Do
			String["AnalyticsTypeDr"+Index] = ExtDimensionType.ExtDimensionType;
			Index = Index +1;
		EndDo;
		Index = 1;
		For Each ExtDimensionType In ExtDimensionTypes1 Do
			String["AnalyticsTypeCr"+Index] = ExtDimensionType.ExtDimensionType1;
			Index = Index +1;
		EndDo;
		String.FinancialResultDr = QueryResult[RowIndex].AccountDr.FinancialResults;
		String.FinancialResultCr = QueryResult[RowIndex].AccountCr.FinancialResults;
		RowIndex = RowIndex+1;
		EndDo;
	Object.EntriesTemplates.Load(TSUnloading);
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	ChoiceList = Items.EntriesTemplatesOperationType.ChoiceList;
	Items.EntriesTemplatesOperationType.ListChoiceMode = True;
	ChoiceList.Clear();
	ChoiceList.Add(PredefinedValue("Enum.fmBudgetOperationTypes.IncomesAndExpenses"));
	ChoiceList.Add(PredefinedValue("Enum.fmBudgetOperationTypes.InternalSettlements"));
	
	ChoiceList = Items.ItemType.ChoiceList;
	ChoiceList.Clear();
	ChoiceList.Add(PredefinedValue("Enum.fmBudgetFlowOperationTypes.Incomes"));
	ChoiceList.Add(PredefinedValue("Enum.fmBudgetFlowOperationTypes.Expenses"));
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	// Подсистема "Свойства"
	// en script begin
	//Если PropertyManagementClient.ProcessNofifications(ЭтаФорма, ИмяСобытия, Параметр) Тогда
	//	ОбновитьЭлементыДополнительныхРеквизитов();
	//КонецЕсли;
	// en script end
EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, RecordParameters)
	// Обработчик подсистемы "Свойства"
	// en script begin
	//PropertyManagement.BeforeWriteAtServer(ЭтаФорма, ТекущийОбъект);
	// en script end
	
	// Чистим ТЧ.
	CurrentObject.EntriesTemplates.Clear();
	
	// Переносим табличные настройки в ТЧ.
	For Each CurRow In Object.EntriesTemplates Do
		NewLine = CurrentObject.EntriesTemplates.Add();
		FillPropertyValues(NewLine, CurRow);
		For Index = 1 To 3 Do
			NewLine["ExtDimensionDr"+Index] = GetName(NewLine["ExtDimensionDr"+Index], SynonymNameMap);
			NewLine["ExtDimensionCr"+Index] = GetName(NewLine["ExtDimensionCr"+Index], SynonymNameMap);
		EndDo;
		NewLine.BalanceUnit = GetName(NewLine.BalanceUnit, SynonymNameMap);
	EndDo;
	
EndProcedure

#EndRegion

#Region ProceduresAndFunctionsOfCommonUse

&AtServer
Procedure RefreshAdditionalAttributesItems()
	// en script begin
	//PropertyManagement.UpdateAdditionalAttributeItems(ЭтаФорма, РеквизитФормыВЗначение("Объект"));
	// en script end
EndProcedure

&AtClient
Function FormList(Attribute)
	// Соберем список выбора для реквизита.
	// Возможность выбора есть только из тех, что еще не использованы.
	AttributeList = New ValueList();
	For Index = 1 To 3 Do
		If Attribute = "EntriesTemplatesExtDimensionDr"+Index OR Attribute = "EntriesTemplatesExtDimensionCr"+Index Then
			For Each CurRow In TSAttributes Do
				If ValueIsFilled(CurRow.Attribute) Then
					AttributeList.Add(CurRow.Attribute, CurRow.Attribute);
				EndIf;
			EndDo;
		Break;
		ElsIf Attribute = "EntriesTemplatesBalanceUnit" Then
			For Each CurRow In TSAttributes Do
				If ValueIsFilled(CurRow.AttributeBalanceUnit) Then
					AttributeList.Add(CurRow.AttributeBalanceUnit, CurRow.AttributeBalanceUnit);
				EndIf;
			EndDo;
			Break;
		ElsIf Attribute = "EntriesTemplatesDepartmentDr" OR Attribute = "EntriesTemplatesDepartmentCr" Then
			For Each CurRow In TSAttributes Do
				If ValueIsFilled(CurRow.AttributeDepartments) Then
					AttributeList.Add(CurRow.AttributeDepartments, CurRow.AttributeDepartments);
				EndIf;
			EndDo;
			Break;
		EndIf;
	EndDo;
	Return AttributeList;
EndFunction

&AtClient
Procedure CheckTypesMap(ExtDimension, AccountExtDimensions, CurrentData, Name)
	For Index = 1 To 3 Do
		If Name = "EntriesTemplatesExtDimensionDr"+Index OR Name = "EntriesTemplatesExtDimensionCr"+Index Then
			If ValueIsFilled(CurrentData[ExtDimension+Index]) Then
				If CurrentData[ExtDimension+Index] = "Analytics 1" Then
					If Object.AnalyticsType1 <> AccountExtDimensions["ExtDimension"+Index] Then
						CommonClientServer.MessageToUser(StrTemplate(NStr("en='Extra dimension %1 cannot take value of Dimension 1';ru='Субконто %1 не может принимать значение Аналитики 1'"), Index));
						//ТекущиеДанные[Субконто+Индекс] = Неопределено;
						Return;
					EndIf;
				ElsIf CurrentData[ExtDimension+Index] = "Analytics 2" Then
					If Object.AnalyticsType2 <> AccountExtDimensions["ExtDimension"+Index] Then
						CommonClientServer.MessageToUser(StrTemplate(NStr("ru = 'Субконто %1 не может принимать значение Аналитики 2"), Index));
						//ТекущиеДанные[Субконто+Индекс] = Неопределено;
						Return;
					EndIf;
				ElsIf CurrentData[ExtDimension+Index] = "Analytics 3" Then
					If Object.AnalyticsType3 <> AccountExtDimensions["ExtDimension"+Index] Then
						CommonClientServer.MessageToUser(StrTemplate(NStr("ru = 'Субконто %1 не может принимать значение Аналитики 3"), Index));
						//ТекущиеДанные[Субконто+Индекс] = Неопределено;
						Return;
					EndIf;
				Else
					CheckAtServer(AccountExtDimensions["ExtDimension"+Index], Index, CurrentData[ExtDimension+Index]);
					Return;
				EndIf;
			EndIf;
		EndIf;
	EndDo;
EndProcedure

&AtServer
Procedure CheckAtServer(ExtDimension, Index, Value)
	If Value = "Balance Unit" OR Value = "Cor. Balance Unit" Then
		If ExtDimension.ValueType <> New TypeDescription("CatalogRef.fmBalanceUnits") Then
			CommonClientServer.MessageToUser(StrTemplate(NStr("en='Extra dimension %1 cannot take value %2';ru='Субконто %1 не может принимать значение %2'"), Index, Value));
		EndIf;
	ElsIf Value = "Item" Then
		If ExtDimension.ValueType <> New TypeDescription("CatalogRef.fmCashflowItems") Then
			If ExtDimension.ValueType <> New TypeDescription("CatalogRef.fmIncomesAndExpensesItems") Then
				CommonClientServer.MessageToUser(StrTemplate(NStr("en='Extra dimension %1 cannot take value %2';ru='Субконто %1 не может принимать значение %2'"), Index, Value));
			EndIf;
		EndIf;
	ElsIf Value = "Department" OR Value = "Cor. Department" Then
		If ExtDimension.ValueType <> New TypeDescription("CatalogRef.fmDepartments") Then
			CommonClientServer.MessageToUser(StrTemplate(NStr("en='Extra dimension %1 cannot take value %2';ru='Субконто %1 не может принимать значение %2'"), Index, Value));
		EndIf;
	EndIf;
EndProcedure
	
&AtServer
Procedure FillMaps()
	
	// Заполним из метаданных соответствие имени реквизита его синониму.
	// Заполним из метаданных соответствие синонима реквизита его имени.
	NameSynonymMap = New Structure();
	SynonymNameMap = New Structure();
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

&AtClientAtServerNoContext
Function GetSynonym(CurRow, NameSynonymMap)
	If TypeOf(CurRow) = Type("String") Then
		AttributeName = CurRow;
	Else
		If ValueIsFilled(CurRow.Attribute) Then
			AttributeName = CurRow.Attribute;
		ElsIf ValueIsFilled(CurRow.AttributeBalanceUnit) Then
			AttributeName = CurRow.AttributeBalanceUnit;
		ElsIf ValueIsFilled(CurRow.AttributeDepartments) Then
			AttributeName = CurRow.AttributeDepartments;
		EndIf;
	EndIf;
	
	Try
		Return NameSynonymMap[AttributeName];
	Except
		If TypeOf(CurRow) = Type("String") Then
			Return AttributeName;
		EndIf;
	EndTry;
EndFunction

&AtClientAtServerNoContext
Function GetName(CurRow, SynonymNameMap)
	If TypeOf(CurRow)=Type("String") Then
		AttributeSynonym = fmBudgetingClientServer.DeleteSymbols(CurRow);
	Else
		AttributeSynonym = fmBudgetingClientServer.DeleteSymbols(CurRow.BalanceUnit);
	EndIf;
	Try
		Return SynonymNameMap[AttributeSynonym];
	Except
		Return CurRow;
	EndTry;
EndFunction

&AtClient
Procedure RepresentList(Item)
	RebuildList();
	For Index = 1 To 3 Do
		If (Item.CurrentItem.Name = ("EntriesTemplatesExtDimensionDr"+Index)
			OR Item.CurrentItem.Name = ("EntriesTemplatesExtDimensionCr"+Index)
			OR Item.CurrentItem.Name = "EntriesTemplatesBalanceUnit" 
			OR Item.CurrentItem.Name = "EntriesTemplatesDepartmentCr"
			OR Item.CurrentItem.Name = "EntriesTemplatesDepartmentDr") Then
			CurRow = Items.EntriesTemplates.CurrentData;
			ValueList = FormList(Item.CurrentItem.Name).UnloadValues();
			Items[Item.CurrentItem.Name].ChoiceList.LoadValues(ValueList);
		EndIf;
	EndDo;
EndProcedure

&AtClient
Procedure RebuildList()
	CurRow = Items.EntriesTemplates.CurrentData;
	If CurRow.OperationType = PredefinedValue("Enum.fmBudgetOperationTypes.IncomesAndExpenses") Then
		CurRow.BalanceUnit = GetSynonym("BalanceUnit", NameSynonymMap);
		DeletionRow = TSAttributes.FindRows(New Structure("Attribute", "Cor. Balance Unit"));
		For Each String In DeletionRow Do
			TSAttributes.Delete(String);
		EndDo;
		DeletionRow = TSAttributes.FindRows(New Structure("Attribute", "Cor. Department"));
		For Each String In DeletionRow Do
			TSAttributes.Delete(String);
		EndDo;
		OperationTypeCurrentValue = CurRow.OperationType;
	ElsIf CurRow.OperationType = PredefinedValue("Enum.fmBudgetOperationTypes.InternalSettlements") Then
		If OperationTypeCurrentValue <> CurRow.OperationType Then
			If ValueIsFilled(OperationTypeCurrentValue) Then
				CurRow.BalanceUnit = GetSynonym("BalanceUnit", NameSynonymMap);
			EndIf;
			OperationTypeCurrentValue = CurRow.OperationType;
			NewLine = TSAttributes.Add();
			NewLine.Attribute = "CorBalanceUnit";
			NewLine.Attribute = GetSynonym(NewLine, NameSynonymMap);
			
			NewLine = TSAttributes.Add();
			NewLine.Attribute = "CorDepartment";
			NewLine.Attribute = GetSynonym(NewLine, NameSynonymMap);
		EndIf;
	EndIf;
EndProcedure

#EndRegion

#Region FormItemsEventsHandlers

&AtClient
Procedure EntriesTemplatesOnStartEdit(Item, NewLine, Copy)
	If NewLine AND NOT Copy Then
		Item.CurrentData.OperationType = PredefinedValue("Enum.fmBudgetOperationTypes.IncomesAndExpenses");
		Item.CurrentData.AmountCalculationRatio = 1;
		Item.CurrentData.BalanceUnit = GetSynonym("BalanceUnit", NameSynonymMap);
	EndIf;
EndProcedure

&AtClient
Procedure EntriesTemplatesAccountDrOnChange(Item)
	CurRow = Items.EntriesTemplates.CurrentData;
	AnalyticsTypes = fmBudgeting.GetAccountExtDimension(CurRow.AccountDr);
	Index = 1;
	For Each It1 In AnalyticsTypes Do
		If TypeOf(It1.Value) <> Type("Boolean") Then
			CurRow["AnalyticsTypeDr"+Index] = It1.Value;
			CurRow["ExtDimensionDr"+Index] = Undefined;
			Index = Index+1;
		ElsIf It1.Value Then
			CurRow.DepartmentDr = "Department";
			CurRow.FinancialResultDr = True;
		Else
			CurRow.FinancialResultDr = False;
		EndIf;
	EndDo;
EndProcedure

&AtClient
Procedure EntriesTemplatesAccountCrOnChange(Item)
	CurRow = Items.EntriesTemplates.CurrentData;
	AnalyticsTypes = fmBudgeting.GetAccountExtDimension(CurRow.AccountCr);
	Index = 1;
	For Each It1 In AnalyticsTypes Do
		If TypeOf(It1.Value) <> Type("Boolean") Then
			CurRow["AnalyticsTypeCr"+Index] = It1.Value;
			CurRow["ExtDimensionCr"+Index] = Undefined;
			Index = Index+1;
		ElsIf It1.Value Then
			CurRow.FinancialResultCr = True;
			CurRow.DepartmentCr = "Department";
		Else
			CurRow.FinancialResultCr = False;
		EndIf;
	EndDo;
EndProcedure

&AtClient
Procedure EntriesTemplateOnActivateCell(Item)
	If Item.CurrentData <> Undefined Then
		RepresentList(Item);
	EndIf;
EndProcedure

&AtClient
Procedure EntriesTemplateOperationTypeOnChange(Item)
	CurRow = Items.EntriesTemplates.CurrentData;
	For Index = 1 To 3 Do
		CurRow["ExtDimensionDr"+Index] = Undefined;
		CurRow["ExtDimensionCr"+Index] = Undefined;
	EndDo;
	If ValueIsFilled(CurRow.DepartmentCr) Then
		CurRow.DepartmentCr = "Department";
	EndIf;
	If ValueIsFilled(CurRow.DepartmentDr) Then
		CurRow.DepartmentDr = "Department";
	EndIf;
	RebuildList();
EndProcedure

&AtClient
Procedure EntriesTemplatesExtDimensionDrOnChange(Item)
	CurrentData = Items.EntriesTemplates.CurrentData;
	AccountExtDimensions = fmBudgeting.GetAccountExtDimension(CurrentData.AccountDr);
	CheckTypesMap("ExtDimensionDr", AccountExtDimensions, CurrentData, Item.Name);
EndProcedure

&AtClient
Procedure EntriesTemplatesExtDimensionCrOnChange(Item)
	CurrentData = Items.EntriesTemplates.CurrentData;
	AccountExtDimensions = fmBudgeting.GetAccountExtDimension(CurrentData.AccountCr);
	CheckTypesMap("ExtDimensionCr", AccountExtDimensions, CurrentData, Item.Name);
EndProcedure

&AtClient
Procedure EntriesTemplateChooseFromListStart(Item, StandardProcessing)
	RepresentList(Item);
EndProcedure

&AtClient
Procedure EntriesTemplateDepartmentStartListChoice(Item, StandardProcessing)
	RepresentList(Item);
EndProcedure

#EndRegion
