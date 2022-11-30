
// Процедура установки типа и доступности субконто в зависимости от выбранного счета.
//
Procedure OnAccountChoice(Account, Form, FormFields, FiledsTitles = Undefined, IsTable = False) Export
	
	AccountData = fmBudgetingServerCallCached.GetAccountProperties(Account);
	
	For Index = 1 To 3 Do
		If Index <= AccountData.ExtDimensionCount Then
			If IsTable Then
				If FormFields.Property("ExtDimension" + Index) Then
					Form.Items[FormFields["ExtDimension" + Index]].TypeRestriction = AccountData["ExtDimensionType" + Index + "ValueType"];
				EndIf;
			Else
				If NOT FiledsTitles = Undefined AND FiledsTitles.Property("ExtDimension" + Index) Then
					Form[FiledsTitles["ExtDimension" + Index]] = AccountData["ExtDimensionType" + Index + "Description"] + ":";
				EndIf;
				If FormFields.Property("ExtDimension" + Index) Then
					Form.Items[FormFields["ExtDimension" + Index]].Enabled     = True;
					Form.Items[FormFields["ExtDimension" + Index]].Title = AccountData["ExtDimensionType" + Index + "Description"];
				EndIf;
			EndIf;
		Else 
			// Ничего делать не надо, т.к. не доступные поля будут скрыты
			If NOT IsTable Then
				If NOT FiledsTitles = Undefined AND FiledsTitles.Property("ExtDimension" + Index) Then
					Form[FiledsTitles["ExtDimension" + Index]] = "";
				EndIf;
				If FormFields.Property("ExtDimension" + Index) Then
					Form.Items[FormFields["ExtDimension" + Index]].Enabled     = False;
					Form.Items[FormFields["ExtDimension" + Index]].Title = "";
				EndIf;
			EndIf;
		EndIf;
	EndDo;
	
	 If NOT IsTable Then
		If NOT FiledsTitles = Undefined AND FiledsTitles.Property("Project") Then
			Form[FiledsTitles["Project"]] = "";
		EndIf;
		If FormFields.Property("Project") Then
			Form.Items[FormFields["Project"]].Enabled = AccountData.AccountingByProjects;
			Form.Items[FormFields["Project"]].Title = "";
		EndIf;
	EndIf;
	
	If NOT IsTable Then
		If NOT FiledsTitles = Undefined AND FiledsTitles.Property("Department") Then
			Form[FiledsTitles["Department"]] = "";
		EndIf;
		If FormFields.Property("Department") Then
			Form.Items[FormFields["Department"]].Enabled = AccountData.FinancialResults;
			Form.Items[FormFields["Department"]].Title = "";
		EndIf;
	EndIf;
	If NOT IsTable Then
		If NOT FiledsTitles = Undefined AND FiledsTitles.Property("Item") Then
			Form[FiledsTitles["Item"]] = "";
		EndIf;
		If FormFields.Property("Item") Then
			Form.Items[FormFields["Item"]].Enabled = AccountData.FinancialResults;
			Form.Items[FormFields["Item"]].Title = "";
		EndIf;
	EndIf;

	
EndProcedure

// Процедура установки типа и доступности субконто в зависимости от выбранного счета.
//
Procedure OnAccountChange(Account, Object, ObjectFields, IsTable = False) Export
	
	AccountData = fmBudgetingServerCallCached.GetAccountProperties(Account);
	
	For Index = 1 To 3 Do
		If ObjectFields.Property("ExtDimension" + Index) Then
			If Index <= AccountData.ExtDimensionCount Then
				Object[ObjectFields["ExtDimension" + Index]] = AccountData["ExtDimensionType" + Index + "ValueType"].AdjustValue(Object[ObjectFields["ExtDimension" + Index]]);
			Else 
				Object[ObjectFields["ExtDimension" + Index]] = Undefined;
			EndIf;
		EndIf;
	EndDo;
	
	If IsTable Then
		SetExtDimensionAvailability(Account, Object, ObjectFields);
	EndIf;	
	
	If ObjectFields.Property("Project") Then
		If NOT AccountData.AccountingByProjects Then
			Object[ObjectFields.Project] = Undefined;
		EndIf;
	EndIf;
	
	If ObjectFields.Property("Department") Then
		If NOT AccountData.FinancialResults Then
			Object[ObjectFields.Department] = Undefined;
		EndIf;
	EndIf;
	If ObjectFields.Property("Item") Then
		If NOT AccountData.FinancialResults Then
			Object[ObjectFields.Item] = Undefined;
		EndIf;
	EndIf;

	
EndProcedure

// Процедура установки доступности субконто в зависимости от выбранного счета.
//
Procedure SetExtDimensionAvailability(Account, Object, ObjectFields) Export
	
	AccountData = fmBudgetingServerCallCached.GetAccountProperties(Account);
	
	For Index = 1 To 3 Do
		If ObjectFields.Property("ExtDimension" + Index) Then
			Object[ObjectFields["ExtDimension" + Index] + "Enabled"] = (Index <= AccountData.ExtDimensionCount);
		EndIf;
	EndDo;
	
	If ObjectFields.Property("Project") Then 
		Object[ObjectFields["Project"] + "Enabled"] = AccountData.AccountingByProjects;
	EndIf;
	
	If ObjectFields.Property("Department") Then 
		Object[ObjectFields["Department"] + "Enabled"] = AccountData.FinancialResults;
	EndIf;
	
	If ObjectFields.Property("Item") Then 
		Object[ObjectFields["Item"] + "Enabled"] = AccountData.FinancialResults;
	EndIf;

	
	If ObjectFields.Property("Currency") Then 
		Object[ObjectFields["Currency"] + "Enabled"] = AccountData.Currency;
	EndIf;
	
	If ObjectFields.Property("Currency") Then
		Object[ObjectFields["Currency"] + "Enabled"] = AccountData.Currency;
	EndIf;
	
	
EndProcedure

// Процедура ИзменитьПараметрыВыбораПолейСубконто
//
Procedure ChangeChoiceParametersOfExtDimensionFields(Form, Object, TemplateObjectFieldName, TemplateFormItemName, ParametersList) Export
		
	ParametersArray = New Array();
	For Index = 1 To 3 Do
		ObjectFieldName   = StrReplace(TemplateObjectFieldName  , "%Index%", Index);
		FormItemName = StrReplace(TemplateFormItemName, "%Index%", Index);
		
		If TypeOf(Object[ObjectFieldName]) = Type("CatalogRef.fmCounterpartyContracts") Then
			
			If ParametersList.Property("Company") Then
				ParametersArray.Add(New ChoiceParameter("Filter.Company", ParametersList.Company));
			EndIf;
			
			If ParametersList.Property("Counterparty") Then
				ParametersArray.Add(New ChoiceParameter("Filter.Owner", ParametersList.Counterparty));
			EndIf;
			
		EndIf;

		If ParametersArray.Count() > 0 Then
			ChoiceParameters = New FixedArray(ParametersArray);
			Form.Items[FormItemName].ChoiceParameters = ChoiceParameters;
		EndIf;
		
	EndDo;

EndProcedure

// Процедура изменяет параметры выбора для ПоляВвода управляемой формы:
//
// Параметры:
//	ЭлементФормыСчет - ПолеВвода управляемой формы, для которого изменяется параметр выбора 
//  МассивСчетов                 - <Массив> ИЛИ <Неопределено> - счета, которыми нужно ограничить список. 
//	                                   Если не заполнено - ограничения не будет
//  ОтборПоПризнакуВалютный      - <Булево> ИЛИ <Неопределено> - Значение для установки 
//                                     соответсвтующего параметра выбора. 
//                                     Если неопределено, параметр выбора не устанавливается.
//  ОтборПоПризнкуЗабалансовый   - <Булево> ИЛИ <Неопределено> - Значение для установки 
//                                     соответсвтующего параметра выбора. 
//                                     Если неопределено, параметр выбора не устанавливается.
//  ОтборПоПризнакуСчетГруппа    - <Булево> ИЛИ <Неопределено> - Значение для установки 
//                                     соответсвтующего параметра выбора. 
//                                     Если неопределено, параметр выбора не устанавливается.
//
//
Procedure ChangeAccountChoiceParameters(FormItemAccount, AccountsArray, FilterByCurrencyFlag = Undefined, FilterByOffBalanceFlag = Undefined, FilterByItemGroupFlag = False) Export

	FiltersArray = New Array;
	If FilterByItemGroupFlag <> Undefined Then
		FiltersArray.Add(New ChoiceParameter("Filter.DontUse", FilterByItemGroupFlag));
	EndIf; 
	
	If FilterByCurrencyFlag <> Undefined Then
		FiltersArray.Add(New ChoiceParameter("Filter.Currency", FilterByCurrencyFlag));
	EndIf; 
	
	If FilterByOffBalanceFlag <> Undefined Then
		FiltersArray.Add(New ChoiceParameter("Filter.OffBalance", FilterByOffBalanceFlag));
	EndIf; 
	
	If AccountsArray <> Undefined AND AccountsArray.Count() > 0 Then
		FiltersArray.Add(New ChoiceParameter("Filter.Ref", New FixedArray(AccountsArray)));
	EndIf; 

	ChoiceParameters = New FixedArray(FiltersArray);
	FormItemAccount.ChoiceParameters = ChoiceParameters;
	
EndProcedure

Procedure SetInitialPropertiesOfTableExtDimensions(Table, SetParameters) Export
	
	For Each TableRow In Table Do
		
		SetAvailabilityOfRowExtDimension(TableRow, SetParameters);
		
	EndDo;
	
EndProcedure

Procedure SetAvailabilityOfRowExtDimension(TableRow, SetParameters)
	
	ObjectFields  = SetParameters.ObjectFields;
	
	AccountData = fmBudgetingServerCallCached.GetAccountProperties(TableRow[ObjectFields.AnAccount]);
	
	For Index = 1 To 3 Do
		If ValueIsFilled(ObjectFields["ExtDimension" + Index]) Then
			ExtDimensionValueType = AccountData["ExtDimensionType" + Index + "ValueType"];
			TableRow[ObjectFields["ExtDimension" + Index] + "Enabled"] = AccountData.ExtDimensionCount >= Index
				AND NOT MustHideExtDimension(SetParameters.HideExtDimension, ExtDimensionValueType);
		EndIf;
	EndDo;
	If ObjectFields.Property("ProjectAvailability") Then
		TableRow[ObjectFields.ProjectAvailability] = AccountData.AccountingByProjects;
	ElsIf ValueIsFilled(ObjectFields.Project) Then
		TableRow[ObjectFields.Project + "Enabled"] = AccountData.AccountingByProjects;
	EndIf;

	If ObjectFields.Property("DepartmentAvailability") Then
		TableRow[ObjectFields.DepartmentAvailability] = AccountData.FinancialResults;
	ElsIf ValueIsFilled(ObjectFields.Department) Then
		TableRow[ObjectFields.Department + "Enabled"] = AccountData.FinancialResults;
	EndIf;
	
	If ObjectFields.Property("ItemAvailability") Then
		TableRow[ObjectFields.ItemAvailability] = AccountData.FinancialResults;
	ElsIf ValueIsFilled(ObjectFields.Item) Then
		TableRow[ObjectFields.Item + "Enabled"] = AccountData.FinancialResults;
	EndIf;
	
	If ObjectFields.Property("Currency")
		AND ValueIsFilled(ObjectFields.Currency) Then
		TableRow[ObjectFields.Currency] = AccountData.Currency;
	EndIf;
	
	
EndProcedure

Function SetParametersOfExtDimensionPropertiesByTemplate(FormExtDimension, FormDepartment, ObjectExtDimension, ObjectDepartment, ObjectAccount) Export
	
	Result = NewSetParametersOfExtDimensionProperties();
	
	If NOT IsBlankString(FormExtDimension) Then
		For Index = 1 To 3 Do
			Result.FormFields["ExtDimension" + Index] = FormExtDimension + Index;
		EndDo;
	EndIf;
	If NOT IsBlankString(FormDepartment) Then
		Result.FormFields.Department = FormDepartment;
	EndIf;
	
	If NOT IsBlankString(ObjectExtDimension) Then
		For Index = 1 To 3 Do
			Result.ObjectFields["ExtDimension" + Index] = ObjectExtDimension + Index;
		EndDo;
	EndIf;
	If NOT IsBlankString(ObjectDepartment) Then
		Result.ObjectFields.Department = ObjectDepartment;
	EndIf;
	If NOT IsBlankString(ObjectAccount) Then
		Result.ObjectFields.AnAccount = ObjectAccount;
	EndIf;
	
	Return Result;
	
EndFunction

Function NewSetParametersOfExtDimensionProperties() Export
	
	Result = New Structure;
	
	FormFields = New Structure;
	FormFields.Insert("ExtDimension1");
	FormFields.Insert("ExtDimension2");
	FormFields.Insert("ExtDimension3");
	FormFields.Insert("Project");
	FormFields.Insert("Department");
	FormFields.Insert("Item");
	Result.Insert("FormFields", FormFields);
	
	ObjectFields = New Structure;
	ObjectFields.Insert("AnAccount", "AnAccount");
	ObjectFields.Insert("ExtDimension1");
	ObjectFields.Insert("ExtDimension2");
	ObjectFields.Insert("ExtDimension3");
	ObjectFields.Insert("Project");
	ObjectFields.Insert("Department");
	ObjectFields.Insert("Item");
	Result.Insert("ObjectFields", ObjectFields);
	
	AddAttributes = New Structure;
	Result.Insert("AddAttributes", AddAttributes);
	
	Result.Insert("DefaultValues", New Map); // См. также ПредопределенныеЗначенияСубконтоПоУмолчанию()
	
	Result.Insert("HideExtDimension", True);
	
	Return Result;
	
EndFunction

Procedure SetInitialPropertiesOfRowExtDimension(Form, TableRow, SetParameters) Export
	
	SetPropertiesOfRowExtDimension(Form, TableRow, SetParameters);
	
	ObjectData = SetDataOfExtDimensionParameters(TableRow, SetParameters);
	
	SetExtDimensionChoiceParameters(Form, TableRow, SetParameters, ObjectData);
	
EndProcedure

Procedure SetPropertiesOfRowExtDimension(Form, TableRow, SetParameters)
	
	Items = Form.Items;
	
	ObjectFields = SetParameters.ObjectFields;
	FormFields   = SetParameters.FormFields;
	
	AccountData = fmBudgetingServerCallCached.GetAccountProperties(TableRow[ObjectFields.AnAccount]);
	
	For Index = 1 To AccountData.ExtDimensionCount Do
		If ValueIsFilled(FormFields["ExtDimension" + Index]) Then
			ExtDimensionField = Items[FormFields["ExtDimension" + Index]];
			ExtDimensionField.InputHint = AccountData["ExtDimensionType" + Index + "Description"];
			ExtDimensionField.TypeRestriction = AccountData["ExtDimensionType" + Index + "ValueType"];
		EndIf;
	EndDo;
	
EndProcedure

Function SetDataOfExtDimensionParameters(Object, SetParameters) Export
	
	Result = New Structure;
	
	ObjectFields  = SetParameters.ObjectFields;
	AddAttributes = SetParameters.AddAttributes;
	
	ContractTypeDescription = New TypeDescription("CatalogRef.fmCounterpartyContracts");
	
	For Index = 1 To 3 Do
		If NOT ValueIsFilled(ObjectFields["ExtDimension" + Index]) Then
			Continue;
		EndIf;
		ExtDimensionValue = Object[ObjectFields["ExtDimension" + Index]];
		ExtDimensionType = TypeOf(ExtDimensionValue);
		If ExtDimensionType= Type("CatalogRef.fmCounterparties") Then
			Result.Insert("Counterparty", ExtDimensionValue);
		ElsIf ContractTypeDescription.ContainsType(ExtDimensionType) Then
			Result.Insert("CounterpartyContract", ExtDimensionValue);
		ElsIf ExtDimensionType = Type("CatalogRef.fmProducts") Then
			Result.Insert("Products", ExtDimensionValue);
		ElsIf ExtDimensionType = Type("CatalogRef.fmWarehouses") Then
			Result.Insert("Warehouse", ExtDimensionValue);
		EndIf;
	EndDo;
	Result.Insert("AnAccount", Object[ObjectFields.AnAccount]);
	
	If ObjectFields.Property("Company") Then
		Result.Insert("Company", Object[ObjectFields.Company]);
	EndIf;
	If ObjectFields.Property("BalanceUnit") Then
		Result.Insert("Company", Object[ObjectFields.BalanceUnit.Company]);
	EndIf;

	
	For Each AddAttribute In AddAttributes Do
		Result.Insert(AddAttribute.Key, AddAttribute.Value);
	EndDo;
	
	Return Result;
	
EndFunction

Procedure SetExtDimensionChoiceParameters(Form, Object, SetParameters, ObjectData)
	
	Items = Form.Items;
	
	ObjectFields = SetParameters.ObjectFields;
	FormFields   = SetParameters.FormFields;
	
	ParameterTypes = New Map;
	ParameterTypes.Insert(Type("CatalogRef.SettlementAccounts"), "SettlementAccount");
	ParameterTypes.Insert(Type("CatalogRef.CompanyDepartments"), "Department");
	ContractTypes = New TypeDescription("CatalogRef.fmCounterpartyContracts");
	For Each ContractType In ContractTypes.Types() Do
		ParameterTypes.Insert(ContractType, "Contract");
	EndDo;
	ParameterTypes.Insert(Type("CatalogRef.RegistrationsInTaxAuthority"), "RegistrationInFTSI");
	ParameterTypes.Insert(Type("CatalogRef.fmExtDimension"), "ExtDimension");
	ParameterTypes.Insert(Type("EnumRef.PaymentsTjStateBudgetTypes"), "PaymentsTjStateBudgetTypes");
	
	For Index = 1 To 3 Do
		If NOT ValueIsFilled(FormFields["ExtDimension" + Index])
			OR NOT ValueIsFilled(ObjectFields["ExtDimension" + Index]) Then
			Continue;
		EndIf;
		
		ExtDimensionType   = TypeOf(Object[ObjectFields["ExtDimension" + Index]]);
		ParameterType = ParameterTypes[ExtDimensionType];
		If ParameterType <> Undefined Then
			
			ParametersArray = New Array();
			If ParameterType = "Contract" Then
				If ObjectData.Property("Company") Then
					ParametersArray.Add(New ChoiceParameter("Filter.Company", ObjectData.Company));
				EndIf;
				If ObjectData.Property("BalanceUnit") Then
					ParametersArray.Add(New ChoiceParameter("Filter.Company", ObjectData.BalanceUnit.Company));
				EndIf;
				If ObjectData.Property("SettlementCurrency") Then
					ParametersArray.Add(New ChoiceParameter("Filter.SettlementCurrency", ObjectData.SettlementCurrency));
				EndIf;
				If ObjectData.Property("Counterparty") Then
					CounterpartyName = "Owner";
					ParametersArray.Add(New ChoiceParameter("Filter." + CounterpartyName, ObjectData.Counterparty));
				EndIf;
			ElsIf ParameterType = "SettlementAccount" Then
				If ObjectData.Property("Company") Then
					ParametersArray.Add(New ChoiceParameter("Filter.Owner", ObjectData.Company));
				EndIf;
			ElsIf ParameterType = "ExtDimension" AND ObjectData.Property("AnAccount") Then
				AccountPropereties = fmBudgetingServerCallCached.GetAccountProperties(ObjectData.AnAccount);
				ParametersArray.Add(New ChoiceParameter("Filter.Owner", AccountPropereties["ExtDimensionType" + Index]));
			ElsIf ParameterType = "PaymentsTjStateBudgetTypes"
				AND ObjectData.Property("AnAccount") Then
				ParametersArray.Add(New ChoiceParameter("Filter.AnAccount", ObjectData.AnAccount));
			EndIf;
			
			If ParametersArray.Count() > 0 Then
				ChoiceParameters = New FixedArray(ParametersArray);
				Items[FormFields["ExtDimension" + Index]].ChoiceParameters = ChoiceParameters;
			EndIf;
			
		EndIf;
		
	EndDo;
	
EndProcedure

// Функция определяет, нужно ли скрывать данное субконто
//
// Параметры:
//	СкрыватьСубконто - Булево - - Признак того, нужно ли для этой формы дополнительно скрывать субконто
//	ТипЗначенияСубконто - Описание типов. 
//
Function MustHideExtDimension(HideExtDimension, ExtDimensionValueType)
	
	If HideExtDimension Then
		Return ExtDimensionValueType = New TypeDescription("CatalogRef.ProductGroups");
	Else
		Return False;
	EndIf;
	
EndFunction

Procedure SetRowExtDimensionPropertiesOnChangeAccount(Form, TableRow, SetParameters) Export
	
	SetAvailabilityOfRowExtDimension(TableRow, SetParameters);
	
	SetPropertiesOfRowExtDimension(Form, TableRow, SetParameters);
	
	ObjectData = SetDataOfExtDimensionParameters(TableRow, SetParameters);
	
	SetExtDimensionChoiceParameters(Form, TableRow, SetParameters, ObjectData);
	
	
EndProcedure

Procedure SetRowExtDimensionPropertiesOnChangeExtDimension(Form, TableRow, ExtDimensionNumber, SetParameters) Export
	
	ObjectData = SetDataOfExtDimensionParameters(TableRow, SetParameters);
	
	SetExtDimensionChoiceParameters(Form, TableRow, SetParameters, ObjectData);
	
	ClearExtDimensionOnChangeExtDimension(TableRow, ExtDimensionNumber, SetParameters, ObjectData);
	
EndProcedure

Procedure ClearExtDimensionOnChangeExtDimension(Object, ExtDimensionNumber, SetParameters, ObjectData)
	
	ObjectFields  = SetParameters.ObjectFields;
	
	ExtDimensionTypesForClear   = New TypeDescription(New Array);
	
	For Index = ExtDimensionNumber + 1 To 3 Do
		
		If NOT ValueIsFilled(ObjectFields["ExtDimension" + Index]) Then
			Continue;
		EndIf;
		
		ExtDimensionName = ObjectFields["ExtDimension" + Index];
		ExtDimensionType = TypeOf(Object[ExtDimensionName]);
		
		If ValueIsFilled(Object[ExtDimensionName])
			AND ExtDimensionTypesForClear.ContainsType(ExtDimensionType) Then
			Object[ExtDimensionName] = New (ExtDimensionType);
		EndIf;
		
	EndDo;
	
EndProcedure

Procedure SetHeaderExtDimensionPropertiesOnChangeAccount(Form, Object, SetParameters) Export
	
	SetHeaderExtDimensionProperties(Form, Object, SetParameters);
	
	ObjectData = SetDataOfExtDimensionParameters(Object, SetParameters);
	
	SetExtDimensionChoiceParameters(Form, Object, SetParameters, ObjectData);
	
	
EndProcedure

Procedure SetHeaderExtDimensionProperties(Form, Object, SetParameters)
	
	Items = Form.Items;
	
	ObjectFields = SetParameters.ObjectFields;
	FormFields   = SetParameters.FormFields;
	
	AccountData = fmBudgetingServerCallCached.GetAccountProperties(Object[ObjectFields.AnAccount]);
	
	For Index = 1 To 3 Do
		If NOT ValueIsFilled(FormFields["ExtDimension" + Index]) Then
			Continue;
		EndIf;
		ExtDimensionField = Items[FormFields["ExtDimension" + Index]];
		ShowExtDimension = AccountData.ExtDimensionCount >= Index
			AND NOT MustHideExtDimension(SetParameters.HideExtDimension, AccountData["ExtDimensionType" + Index + "ValueType"]);
		ExtDimensionField.Visible = ShowExtDimension;
		If ShowExtDimension Then
			ExtDimensionField.Title = AccountData["ExtDimensionType" + Index + "Description"];
		EndIf;
	EndDo;
	
	If ValueIsFilled(FormFields.fProject) Then
		fieldProject = Items[FormFields.Project];
		fieldProject.Enabled = AccountData.AccountingByProjects;
	EndIf;
	
	If ValueIsFilled(FormFields.Department) Then
		fieldDepartment = Items[FormFields.Department];
		fieldDepartment.Enabled = AccountData.FinancialResults;
	EndIf;
	
	If ValueIsFilled(FormFields.Item) Then
		fieldItem = Items[FormFields.Item];
		fieldItem.Enabled = AccountData.FinancialResults;
	EndIf;
	
EndProcedure

Procedure SetInitialPropertiesOfHeaderExtDimension(Form, Object, SetParameters) Export
	
	SetHeaderExtDimensionProperties(Form, Object, SetParameters);
	
	ObjectData = SetDataOfExtDimensionParameters(Object, SetParameters);
	
	SetExtDimensionChoiceParameters(Form, Object, SetParameters, ObjectData);
	
EndProcedure

Procedure SetHeaderExtDimensionPropertiesOnChangeExtDimension(Form, Object, ExtDimensionNumber, SetParameters) Export
	
	ObjectData = SetDataOfExtDimensionParameters(Object, SetParameters);
	
	SetExtDimensionChoiceParameters(Form, Object, SetParameters, ObjectData);
	
	ClearExtDimensionOnChangeExtDimension(Object, ExtDimensionNumber, SetParameters, ObjectData);
	
EndProcedure

Function PeriodCount(BeginOfPeriod, EndOfPeriod, Periodicity) Export
	// Проверим период на вырожденность.
	If BeginOfPeriod>EndOfPeriod Then
		Return -1;
	EndIf;
	PeriodCount=0;
	NextPeriod = BeginOfPeriod;
	// Посчитаем количество периодов.
	While NextPeriod <= EndOfPeriod Do
		PeriodCount=PeriodCount+1;
		If Periodicity=PredefinedValue("Enum.fmPlanningPeriodicity.Month") Then
			NextPeriod = EndOfMonth(NextPeriod)+1;
		Else
			For Counter = 1 To 3 Do
				NextPeriod = EndOfMonth(NextPeriod)+1;
			EndDo;
		EndIf;
	EndDo;
	Return PeriodCount;
EndFunction

Function DeleteSymbols(VAL String) Export
	
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
	
EndFunction

Function GetSynonym(CurRow, NameSynonymMap) Export
	If TypeOf(CurRow) = Type("String") Then
		ИмяРеквизита = CurRow;
	Else
		If ValueIsFilled(CurRow.Attribute) Then
			ИмяРеквизита = CurRow.Attribute;
		ElsIf ValueIsFilled(CurRow.AttributeBalanceUnit) Then
			ИмяРеквизита = CurRow.AttributeBalanceUnit;
		EndIf;
	EndIf;
	
	Try
		Return NameSynonymMap[ИмяРеквизита];
	Except
		If TypeOf(CurRow) = Type("String") Then
			Return ИмяРеквизита;
		EndIf;
	EndTry;
EndFunction

Function GetName(CurRow, SynonymNameMap) Export
	If TypeOf(CurRow)=Type("String") Then
		AttributeSynonym = DeleteSymbols(CurRow);
	Else
		AttributeSynonym = DeleteSymbols(CurRow.BalanceUnit);
	EndIf;
	Try
		Return SynonymNameMap[AttributeSynonym];
	Except
		Return CurRow;
	EndTry;
EndFunction

Procedure RepresentList(Form, Item) Export
	Items = Form.Items;
	For Index = 1 To 3 Do
		If (Item.CurrentItem.Name = ("fmEntriesTemplatesExtDimensionDr"+Index)
			OR Item.CurrentItem.Name = ("fmEntriesTemplatesExtDimensionCr"+Index)) Then
			CurRow = Items.EntriesTemplates.CurrentData;
			ValueList = FormList(Item.CurrentItem.Name, Form.TSAttributes).UnloadValues();
			Items[Item.CurrentItem.Name].ChoiceList.LoadValues(ValueList);
		EndIf;
	EndDo;
EndProcedure

Function FormList(Attribute, TSAttributes)
	// Соберем список выбора для реквизита.
	// Возможность выбора есть только из тех, что еще не использованы.
	AttributeList = New ValueList();
	For Index = 1 To 3 Do
		If Attribute = "fmEntriesTemplatesExtDimensionDr"+Index OR Attribute = "fmEntriesTemplatesExtDimensionCr"+Index Then
			For Each CurRow In TSAttributes Do
				If ValueIsFilled(CurRow.Attribute) Then
					AttributeList.Add(CurRow.Attribute, CurRow.Attribute);
				EndIf;
			EndDo;
		EndIf;
	EndDo;
	Return AttributeList;
EndFunction

Procedure CheckTypesMap(Object, ExtDimension, AccountExtDimensions, CurrentData, Name) Export
	For Index = 1 To 3 Do
		If Name = "fmEntriesTemplatesExtDimensionDr"+Index OR Name = "fmEntriesTemplatesExtDimensionCr"+Index Then
			If ValueIsFilled(CurrentData[ExtDimension+Index]) Then
				If CurrentData[ExtDimension+Index] = "Analytics 1" Then
					If Object.fmAnalyticsType1 <> AccountExtDimensions["ExtDimension"+Index] Then
						CommonClientServer.MessageToUser(StrTemplate(NStr("ru='Субконто%1 не может принимать значение Аналитики 1';en='Extra dimension %1 cannot take the value of Dimension 1'"), Index));
						Return;
					EndIf;
				ElsIf CurrentData[ExtDimension+Index] = "Analytics 2" Then
					If Object.fmAnalyticsType2 <> AccountExtDimensions["ExtDimension"+Index] Then
						CommonClientServer.MessageToUser(StrTemplate(NStr("ru='Субконто%1 не может принимать значение Аналитики 2';en='Extra dimension %2 cannot take the value of Dimension 2'"), Index));
						Return;
					EndIf;
				ElsIf CurrentData[ExtDimension+Index] = "Analytics 3" Then
					If Object.fmAnalyticsType3 <> AccountExtDimensions["ExtDimension"+Index] Then
						CommonClientServer.MessageToUser(StrTemplate(NStr("ru='Субконто%1 не может принимать значение Аналитики 3';en='Extra dimension %3 cannot take the value of Dimension 3'"), Index));
						Return;
					EndIf;
				Else
					fmBudgeting.CheckAtServer(AccountExtDimensions["ExtDimension"+Index], Index, CurrentData[ExtDimension+Index]);
					Return;
				EndIf;
			EndIf;
		EndIf;
	EndDo;
EndProcedure


