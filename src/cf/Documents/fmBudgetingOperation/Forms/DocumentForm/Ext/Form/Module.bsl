
&AtClient
Var RecordRowID;

#Region FormEventsHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Key.IsEmpty() Then
		SetDocumentState("UnwrittenDocument");
		AssembleFormAtServer(Parameters.CopyingValue);
		FillRecords(Parameters.FillingValues);
	EndIf;

	//При открытии из журнала проводок активизируем выбранную строку
	If ValueIsFilled(Parameters.ParameterCurrentRow) Then
		Items.fmBudgeting.CurrentRow  = Parameters.ParameterCurrentRow-1;
	EndIf;
	
	CurrencyMan = Constants.fmCurrencyOfManAccounting.Get();
	Items.fmBudgetingGroupAmountContent.Title = StrTemplate(NStr("en='Amount in %1';ru='Сумма в %1'"), TrimAll(CurrencyMan)); 
	
	SetConditionalAppearance();
	
EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)
	
	AssembleFormAtServer(CurrentObject.Ref);
	SetDocumentState();
	
EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, RecordParameters)
	
	For Each RegisterRow In Registers Do
		If RegisterRow.HasAttribute Then
			RecordSet = FormAttributeToValue(RegisterRow.Name + "RecordSet");
			RecordTable = RecordSet.Unload();
			CurrentObject.RegisterRecords[RegisterRow.Name].Load(RecordTable);
			RegisterRow.Write = True;
		EndIf;
	EndDo;
	
EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, RecordParameters)
	
	FillTablesAddedColumns();
	
	SetDocumentState();
	
EndProcedure

&AtClient
Procedure AfterWrite(RecordParameters)

	Notify("fmBudgetingOperationChange");

EndProcedure

#EndRegion

#Region FormHeaderItemsEventsHandlers

&AtClient
Procedure BalanceUnitOnChange(Item)

	If fmBudgetingRecordSet.Count() > 0 Then
		QueryText = NStr("en='The departments specified in postings will be cleared. Do you want to continue?';ru='Указанные в проводках подразделения будут очищены. "
"Продолжить?'");
		Notification = New NotifyDescription("QueryBalanceUnitOnChangeEnd", ThisObject);
		ShowQueryBox(Notification, QueryText, QuestionDialogMode.YesNo, , DialogReturnCode.Yes);
	Else
		BalanceUnitOnChangeAtServer();
	EndIf;

EndProcedure

&AtClient
Procedure DateOnChange(Item)
	If fmBudgetingRecordSet.Count() > 0 Then
		QueryText = NStr("en='The departments specified in postings will be cleared. Do you want to continue?';ru='Указанные в проводках подразделения будут очищены. "
"Продолжить?'");
		Notification = New NotifyDescription("QueryBalanceUnitOnChangeEnd", ThisObject);
		ShowQueryBox(Notification, QueryText, QuestionDialogMode.YesNo, , DialogReturnCode.Yes);
	Else
		DateOnChangeAtServer();
	EndIf;

	If BegOfDay(Object.DATE) = BegOfDay(CurrentDocumentDate) Then
		// Изменение времени не влияет на поведение документа.
		CurrentDocumentDate = Object.DATE;
		Return;
	EndIf;

	// Запомним новую дату документа.
	CurrentDocumentDate = Object.DATE;
	 
EndProcedure

#EndRegion

#Region EventHandlersOfTableItemsOfBudgetingForm
&AtClient
Procedure fmBudgetingOnStartEdit(Item, NewLine, Copy)
	
	CurrentData = Items.fmBudgeting.CurrentData;
	RowID      = Items.fmBudgeting.CurrentRow;
	
	If RowID <> RecordRowID Then
	
		FormFields = New Structure("ExtDimension1, ExtDimension2, ExtDimension3",
			"fmBudgetingExtDimensionDr1", "fmBudgetingExtDimensionDr2", "fmBudgetingExtDimensionDr3");
		fmBudgetingClientServer.OnAccountChoice(CurrentData.AccountDr, ThisObject, FormFields, Undefined, True);
	
		FormFields = New Structure("ExtDimension1, ExtDimension2, ExtDimension3",
			"fmBudgetingExtDimensionCr1", "fmBudgetingExtDimensionCr2", "fmBudgetingExtDimensionCr3");
		fmBudgetingClientServer.OnAccountChoice(CurrentData.AccountCr, ThisObject, FormFields, Undefined, True);
		
		ChangeChoiceParametersOfExtDimensionFields(ThisObject, "", False);
		
		RecordRowID = RowID;
	
	EndIf;
	
	// Сначала выполняем общие действия для всех регистров
	Attached_RegisterTableOnStartEdit(Item, NewLine, Copy);
	

EndProcedure

&AtClient
Procedure fmBudgetingBeforeEditEnd(Item, NewLine, EditCancel, Cancel)

	RecalculateOperationAmount(ThisObject);

EndProcedure

&AtClient
Procedure fmBudgetingAfterDeleteRow(Item)

	RecalculateOperationAmount(ThisObject);

EndProcedure

&AtClient
Procedure fmBudgetingAccountDrOnChange(Item)

	ProcessAccountChanging(ThisObject, "Dr");

EndProcedure

&AtClient
Procedure fmBudgetingAccountCrOnChange(Item)

	ProcessAccountChanging(ThisObject, "Cr");

EndProcedure

&AtClient
Procedure fmBudgetingCurrencyDrOnChange(Item)

	AmountCalculation(True);

EndProcedure

&AtClient
Procedure fmBudgetingCurrencyAmountDrOnChange(Item)
	
	AmountCalculation(True);
	RecalculateOperationAmount(ThisObject);
	
EndProcedure

&AtClient
Procedure fmBudgetingCurrencyCrOnChange(Item)

	CurrentData = Items.fmBudgeting.CurrentData;

	If ValueIsFilled(CurrentData.AccountDr) Then
		AccountPropereties = fmBudgetingServerCallCached.GetAccountProperties(CurrentData.AccountDr);
		If AccountPropereties.Currency Then
			Return; // Если оба счета валютные, сумма пересчитывается при изменении счета Дт
		EndIf;
	EndIf;

	AmountCalculation(False);

EndProcedure

&AtClient
Procedure fmBudgetingCurrencyAmountCrOnChange(Item)
	
	CurrentData = Items.fmBudgeting.CurrentData;
	If ValueIsFilled(CurrentData.AccountDr) Then
		AccountPropereties = fmBudgetingServerCallCached.GetAccountProperties(CurrentData.AccountDr);
		If AccountPropereties.Currency Then
			Return; // Если оба счета валютные, сумма пересчитывается при изменении счета Дт
		EndIf;
	EndIf;
	
	AmountCalculation(False);
	RecalculateOperationAmount(ThisObject);
	
EndProcedure

&AtClient
Procedure fmBudgetingAmounOnChange(Item)
	
	AmountCalculation();
	RecalculateOperationAmount(ThisObject);
	
EndProcedure

&AtClient
Procedure fmBudgetingExtDimensionDr1OnChange(Item)
	
	ChangeChoiceParametersOfExtDimensionFields(ThisObject, "Dr");
	
EndProcedure

&AtClient
Procedure fmBudgetingExtDimensionDr2OnChange(Item)
	
	ChangeChoiceParametersOfExtDimensionFields(ThisObject, "Dr");
	
EndProcedure

&AtClient
Procedure fmBudgetingExtDimensionCr1OnChange(Item)
	
	ChangeChoiceParametersOfExtDimensionFields(ThisObject, "Cr");
	
EndProcedure

&AtClient
Procedure fmBudgetingExtDimensionCr2OnChange(Item)
	
	ChangeChoiceParametersOfExtDimensionFields(ThisObject, "Cr");
	
EndProcedure

#EndRegion

#Region EventHandlersOfTableItemsOfFormUniversal

// Общая процедура для всех регистров. Устанавливает период и организацию в добавляемых строках.
//
&AtClient
Procedure Attached_RegisterTableOnStartEdit(Item, NewLine, Copy)
	
	If Item.CurrentData.Property("Period") Then
		Item.CurrentData.Period = Object.DATE;
	EndIf;

	If NewLine
			AND NOT Copy
			AND Item.CurrentData.Property("BalanceUnit")
			AND ValueIsFilled(Object.BalanceUnit) Then
		Item.CurrentData.BalanceUnit = Object.BalanceUnit;
	EndIf;
	

EndProcedure

#EndRegion

#Region FormCommandsHandlers

&AtClient
Procedure SwitchRecordActivities(Command)

	If Object.DeletionMark Then
		ShowMessageBox( , 
			NStr("en='The operation is marked for deletion, so the activity cannot be switched."
"Uncheck the deletion mark.';ru='Операция помечена на удаление, поэтому переключить активность нельзя."
"Снимите пометку удаления.'"));
		Return;
	EndIf;
	
	SwitchRecordActivitiesAtServer();

EndProcedure

#EndRegion

#Region ServiceProceduresAdFunctions

#Region AttributesChanging

&AtServer
Procedure BalanceUnitOnChangeAtServer()
	
	
	For Each Entry In fmBudgetingRecordSet Do
		
		If ValueIsFilled(Entry.DepartmentDr) Then
			fmBudgeting.BalanceUnitDepartmentCompatible(Object.BalanceUnit, Entry.DepartmentDr, Object.DATE, "Department");
		EndIf;
		
		If ValueIsFilled(Entry.DepartmentCr) Then
			fmBudgeting.BalanceUnitDepartmentCompatible(Object.BalanceUnit, Entry.DepartmentCr, Object.DATE, "Department");
		EndIf;
		
	EndDo;
	
	CurrentBalanceUnit = Object.BalanceUnit;
	
EndProcedure

&AtServer
Procedure DateOnChangeAtServer()
	
	
	For Each Entry In fmBudgetingRecordSet Do
		
		//
		If ValueIsFilled(Entry.DepartmentDr) Then
			fmBudgeting.BalanceUnitDepartmentCompatible(Object.BalanceUnit, Entry.DepartmentDr, Object.DATE, "Department");
		EndIf;
		
		If ValueIsFilled(Entry.DepartmentCr) Then
			fmBudgeting.BalanceUnitDepartmentCompatible(Object.BalanceUnit, Entry.DepartmentCr, Object.DATE, "Department");
		EndIf;
		
	EndDo;
	
	
EndProcedure


&AtClientAtServerNoContext
Function GetParameterList(Form, CurrentData, TemplateObjectFieldName, AccountFieldName)

	ParametersList = New Structure("BalanceUnit,AnAccount,BalancesTurnovers",
	Form.Object.BalanceUnit, CurrentData[AccountFieldName], "Cr");
	ContractTypes = New TypeDescription("CatalogRef.fmCounterpartyContracts");
	For IndexOf = 1 To 3 Do
		FieldName    = StrReplace(TemplateObjectFieldName, "%Index%", IndexOf);
		FieldData = CurrentData[FieldName];
		FiledType    = TypeOf(FieldData);
		If FiledType = Type("CatalogRef.fmCounterparties") Then
			ParametersList.Insert("Counterparty", FieldData);
		ElsIf ContractTypes.Types().Find(FiledType) <> Undefined Then
			ParametersList.Insert("CounterpartyContract", FieldData);
		ElsIf FiledType = Type("CatalogRef.fmProducts") Then
			ParametersList.Insert("Products", FieldData);
		ElsIf FiledType = Type("CatalogRef.fmWarehouses") Then
			ParametersList.Insert("Warehouse", FieldData);
		EndIf;
	EndDo;

	Return ParametersList;

EndFunction

&AtClientAtServerNoContext
Procedure ChangeChoiceParametersOfExtDimensionFields(Form, DrCr = "", ClearLinkedExtDimensions = True)
	
	RowID = Form.Items.fmBudgeting.CurrentRow;
	If RowID = Undefined Then
		Return;
	EndIf;
	TableRow = Form.fmBudgetingRecordSet.FindByID(RowID);
	
	If DrCr <> "Cr" Then
		
		DocumentParameters = GetParameterList(Form, TableRow, "ExtDimensionDr%Index%", "AccountDr");
		
		If ClearLinkedExtDimensions Then
			TableRowExtDimensionValue = TableRow;
		Else
			TableRowExtDimensionValue = New Structure("ExtDimensionDr1,ExtDimensionDr2,ExtDimensionDr3");
			FillPropertyValues(TableRowExtDimensionValue, TableRow);
		EndIf;
		
		fmBudgetingClientServer.ChangeChoiceParametersOfExtDimensionFields(
			Form, TableRowExtDimensionValue, "ExtDimensionDr%Index%", "fmBudgetingExtDimensionDr%Index%", DocumentParameters);
			
	EndIf;
	If DrCr <> "Dr" Then
		
		DocumentParameters = GetParameterList(Form, TableRow, "ExtDimensionCr%Index%", "AccountCr");
		
		If ClearLinkedExtDimensions Then
			TableRowExtDimensionValue = TableRow;
		Else
			TableRowExtDimensionValue = New Structure("ExtDimensionCr1,ExtDimensionCr2,ExtDimensionCr3");
			FillPropertyValues(TableRowExtDimensionValue, TableRow);
		EndIf;
		
		fmBudgetingClientServer.ChangeChoiceParametersOfExtDimensionFields(
			Form, TableRowExtDimensionValue, "ExtDimensionCr%Index%", "fmBudgetingExtDimensionCr%Index%", DocumentParameters);
			
	EndIf;

EndProcedure

&AtClientAtServerNoContext
Procedure ProcessAccountChanging(Form, DrCr)

	RowID = Form.Items.fmBudgeting.CurrentRow;
	If RowID = Undefined Then
		Return;
	EndIf;
	TableRow = Form.fmBudgetingRecordSet.FindByID(RowID);
	
	FormFields = New Structure("ExtDimension1,ExtDimension2,ExtDimension3,Department,Item,Project");
	FormFields.ExtDimension1 = "fmBudgetingExtDimension" + DrCr + "1";
	FormFields.ExtDimension2 = "fmBudgetingExtDimension" + DrCr + "2";
	FormFields.ExtDimension3 = "fmBudgetingExtDimension" + DrCr + "3";
	FormFields.ExtDimension3 = "fmBudgetingDepartment" + DrCr;
	FormFields.ExtDimension3 = "fmBudgetingItem" + DrCr;
	FormFields.ExtDimension3 = "fmBudgetingProject" + DrCr;
	fmBudgetingClientServer.OnAccountChoice(TableRow["Account" + DrCr], Form, FormFields, Undefined, True);
	
	ObjectFields = New Structure("ExtDimension1,ExtDimension2,ExtDimension3,Project,Department,Item,Currency,BalanceUnit");
	ObjectFields.ExtDimension1      = "ExtDimension" + DrCr + "1";
	ObjectFields.ExtDimension2      = "ExtDimension" + DrCr + "2";
	ObjectFields.ExtDimension3      = "ExtDimension" + DrCr + "3";
	ObjectFields.Department  = "Department" + DrCr;
	ObjectFields.Item         = "Item" + DrCr;
	ObjectFields.Project         = "Project" + DrCr;
	ObjectFields.Currency       = "Currency" + DrCr;
	ObjectFields.BalanceUnit    = Form.Object.BalanceUnit;
	fmBudgetingClientServer.OnAccountChange(TableRow["Account" + DrCr], TableRow, ObjectFields, True);
	
	ChangeChoiceParametersOfExtDimensionFields(Form, DrCr);
	
	
EndProcedure

&AtClientAtServerNoContext
Procedure SetTypeOfRecordResources(Form, DrCr)

	RowID = Form.Items.fmBudgeting.CurrentRow;
	If RowID = Undefined Then
		Return;
	EndIf;
	TableRow = Form.fmBudgetingRecordSet.FindByID(RowID);
		
	AmountDescription      = New TypeDescription("Number", New NumberQualifiers(15, 2));
	
	AccountData = fmBudgetingServerCallCached.GetAccountProperties(TableRow["Account"+DrCr]);
	
	If AccountData.Currency Then
		TableRow["CurrencyAmount"+DrCr] = AmountDescription.AdjustValue(TableRow["CurrencyAmount"+DrCr]);
	Else
		TableRow["CurrencyAmount"+DrCr] = NULL;
	EndIf;
		
EndProcedure

&AtServer
Procedure FillTablesAddedColumns()

	ObjectFieldsDr = New Structure(
		"ExtDimension1, ExtDimension2, ExtDimension3, Project, Department, Item, Currency",
		"ExtDimensionDr1", "ExtDimensionDr2", "ExtDimensionDr3", "ProjectDr", "DepartmentDr", "ItemDr", "CurrencyDr");
	ObjectFieldsCr = New Structure(
		"ExtDimension1, ExtDimension2, ExtDimension3, Project, Department, Item, Currency",
		"ExtDimensionCr1", "ExtDimensionCr2", "ExtDimensionCr3", "ProjectCr", "DepartmentCr", "ItemCr", "CurrencyCr");

	For Each Entry In fmBudgetingRecordSet Do
		fmBudgetingClientServer.SetExtDimensionAvailability(Entry.AccountDr, Entry, ObjectFieldsDr);
		fmBudgetingClientServer.SetExtDimensionAvailability(Entry.AccountCr, Entry, ObjectFieldsCr);
	EndDo;
	
EndProcedure


#EndRegion

#Region RecordsFilling

&AtClient
Procedure SetRegisterListEnd(ClosingResult, AdditionalParameters) Export
	
	UserActionsResult = ClosingResult;
	
	// Обработаем результат действий пользователя
	If TypeOf(UserActionsResult) = Type("ValueList")
	   AND UserActionsResult.Count() <> 0 Then
	   
		Modified = True;
		ApplyRegisterListSetting(UserActionsResult);
		
	EndIf;
	
EndProcedure

#EndRegion

#Region FormPainting

&AtServer
Procedure SetConditionalAppearance()
	
	ConditionalAppearance.Items.Clear();


	// Субконто
	For Counter = 1 To 3 Do

		// Видимость СубконтоДт

		CAItem = ConditionalAppearance.Items.Add();

		fmDataCompositionClientServer.AddAppearanceField(CAItem.Fields, "fmBudgetingExtDimensionDr" + Counter);

		CommonClientServer.AddCompositionItem(CAItem.Filter,
			"fmBudgetingRecordSet.ExtDimensionDr" + Counter + "Enabled", DataCompositionComparisonType.Equal, False);

		CAItem.Appearance.SetParameterValue("Visible", False);


		// Выделение не заполненного СубконтоДт

		CAItem = ConditionalAppearance.Items.Add();

		fmDataCompositionClientServer.AddAppearanceField(CAItem.Fields, "fmBudgetingExtDimensionDr" + Counter);

		CommonClientServer.AddCompositionItem(CAItem.Filter,
			"fmBudgetingRecordSet.ExtDimensionDr" + Counter + "Enabled", DataCompositionComparisonType.Equal, True);

		CommonClientServer.AddCompositionItem(CAItem.Filter,
			"fmBudgetingRecordSet.ExtDimensionDr" + Counter, DataCompositionComparisonType.NotFilled);

		CAItem.Appearance.SetParameterValue("TextColor", StyleColors.fmBlankExtDimension);

		CAItem.Appearance.SetParameterValue("Text", NStr("en='<...>';ru='<...>'"));
		

		// Видимость СубконтоКт

		CAItem = ConditionalAppearance.Items.Add();

		fmDataCompositionClientServer.AddAppearanceField(CAItem.Fields, "fmBudgetingExtDimensionCr" + Counter);

		CommonClientServer.AddCompositionItem(CAItem.Filter,
			"fmBudgetingRecordSet.ExtDimensionCr" + Counter + "Enabled", DataCompositionComparisonType.Equal, False);

		CAItem.Appearance.SetParameterValue("Visible", False);
		

		// Выделение не заполненного СубконтоКт
		
		CAItem = ConditionalAppearance.Items.Add();

		fmDataCompositionClientServer.AddAppearanceField(CAItem.Fields, "fmBudgetingExtDimensionCr" + Counter);

		CommonClientServer.AddCompositionItem(CAItem.Filter,
			"fmBudgetingRecordSet.ExtDimensionCr" + Counter + "Enabled", DataCompositionComparisonType.Equal, True);

		CommonClientServer.AddCompositionItem(CAItem.Filter,
			"fmBudgetingRecordSet.ExtDimensionCr" + Counter, DataCompositionComparisonType.NotFilled);

		CAItem.Appearance.SetParameterValue("TextColor", StyleColors.fmBlankExtDimension);

		CAItem.Appearance.SetParameterValue("Text", NStr("en='<...>';ru='<...>'"));
		
	EndDo;
	
	// ПроектДт

	CAItem = ConditionalAppearance.Items.Add();

	fmDataCompositionClientServer.AddAppearanceField(CAItem.Fields, "fmBudgetingProjectDr");

	CommonClientServer.AddCompositionItem(CAItem.Filter,
		"fmBudgetingRecordSet.ProjectDrEnabled", DataCompositionComparisonType.Equal, True);

	CommonClientServer.AddCompositionItem(CAItem.Filter,
		"fmBudgetingRecordSet.ProjectDr", DataCompositionComparisonType.NotFilled);

	CAItem.Appearance.SetParameterValue("TextColor", StyleColors.fmBlankExtDimension);

	CAItem.Appearance.SetParameterValue("Text", NStr("en='<...>';ru='<...>'"));
	

	// ПодразделениеДт

	CAItem = ConditionalAppearance.Items.Add();

	fmDataCompositionClientServer.AddAppearanceField(CAItem.Fields, "fmBudgetingDepartmentDr");

	CommonClientServer.AddCompositionItem(CAItem.Filter,
		"fmBudgetingRecordSet.DepartmentDrEnabled", DataCompositionComparisonType.Equal, True);

	CommonClientServer.AddCompositionItem(CAItem.Filter,
		"fmBudgetingRecordSet.DepartmentDr", DataCompositionComparisonType.NotFilled);

	CAItem.Appearance.SetParameterValue("TextColor", StyleColors.fmBlankExtDimension);

	CAItem.Appearance.SetParameterValue("Text", NStr("en='<...>';ru='<...>'"));
	
	// СтатьяДт

	CAItem = ConditionalAppearance.Items.Add();

	fmDataCompositionClientServer.AddAppearanceField(CAItem.Fields, "fmBudgetingItemDr");

	CommonClientServer.AddCompositionItem(CAItem.Filter,
		"fmBudgetingRecordSet.ItemDrEnabled", DataCompositionComparisonType.Equal, True);

	CommonClientServer.AddCompositionItem(CAItem.Filter,
		"fmBudgetingRecordSet.ItemDr", DataCompositionComparisonType.NotFilled);

	CAItem.Appearance.SetParameterValue("TextColor", StyleColors.fmBlankExtDimension);

	CAItem.Appearance.SetParameterValue("Text", NStr("en='<...>';ru='<...>'"));

	// уфБюджетированиеПрооектДт

	CAItem = ConditionalAppearance.Items.Add();

	fmDataCompositionClientServer.AddAppearanceField(CAItem.Fields, "fmBudgetingProjectDr");

	CommonClientServer.AddCompositionItem(CAItem.Filter,
		"fmBudgetingRecordSet.ProjectDrEnabled", DataCompositionComparisonType.Equal, False);

	CAItem.Appearance.SetParameterValue("Visible", False);

	// уфБюджетированиеПодразделениеДт

	CAItem = ConditionalAppearance.Items.Add();

	fmDataCompositionClientServer.AddAppearanceField(CAItem.Fields, "fmBudgetingDepartmentDr");

	CommonClientServer.AddCompositionItem(CAItem.Filter,
		"fmBudgetingRecordSet.DepartmentDrEnabled", DataCompositionComparisonType.Equal, False);

	CAItem.Appearance.SetParameterValue("Visible", False);

	
	// уфБюджетированиеСтатьяДт

	CAItem = ConditionalAppearance.Items.Add();

	fmDataCompositionClientServer.AddAppearanceField(CAItem.Fields, "fmBudgetingItemDr");

	CommonClientServer.AddCompositionItem(CAItem.Filter,
		"fmBudgetingRecordSet.ItemDrEnabled", DataCompositionComparisonType.Equal, False);

	CAItem.Appearance.SetParameterValue("Visible", False);

	// ПроектКт

	CAItem = ConditionalAppearance.Items.Add();

	fmDataCompositionClientServer.AddAppearanceField(CAItem.Fields, "fmBudgetingProjectCr");

	CommonClientServer.AddCompositionItem(CAItem.Filter,
		"fmBudgetingRecordSet.ProjectCrEnabled", DataCompositionComparisonType.Equal, True);

	CommonClientServer.AddCompositionItem(CAItem.Filter,
		"fmBudgetingRecordSet.ProjectCr", DataCompositionComparisonType.NotFilled);

	CAItem.Appearance.SetParameterValue("TextColor", StyleColors.fmBlankExtDimension);

	CAItem.Appearance.SetParameterValue("Text", NStr("en='<...>';ru='<...>'"));


	// уфБюджетированиеПроектКт

	CAItem = ConditionalAppearance.Items.Add();

	fmDataCompositionClientServer.AddAppearanceField(CAItem.Fields, "fmBudgetingProjectCr");

	CommonClientServer.AddCompositionItem(CAItem.Filter,
		"fmBudgetingRecordSet.ProjectCrEnabled", DataCompositionComparisonType.Equal, False);

	CAItem.Appearance.SetParameterValue("Visible", False);
	
	// ПодразделениеКт

	CAItem = ConditionalAppearance.Items.Add();

	fmDataCompositionClientServer.AddAppearanceField(CAItem.Fields, "fmBudgetingDepartmentCr");

	CommonClientServer.AddCompositionItem(CAItem.Filter,
		"fmBudgetingRecordSet.DepartmentCrEnabled", DataCompositionComparisonType.Equal, True);

	CommonClientServer.AddCompositionItem(CAItem.Filter,
		"fmBudgetingRecordSet.DepartmentCr", DataCompositionComparisonType.NotFilled);

	CAItem.Appearance.SetParameterValue("TextColor", StyleColors.fmBlankExtDimension);

	CAItem.Appearance.SetParameterValue("Text", NStr("en='<...>';ru='<...>'"));


	// уфБюджетированиеПодразделениеКт

	CAItem = ConditionalAppearance.Items.Add();

	fmDataCompositionClientServer.AddAppearanceField(CAItem.Fields, "fmBudgetingDepartmentCr");

	CommonClientServer.AddCompositionItem(CAItem.Filter,
		"fmBudgetingRecordSet.DepartmentCrEnabled", DataCompositionComparisonType.Equal, False);

	CAItem.Appearance.SetParameterValue("Visible", False);

	// СтатьяКт

	CAItem = ConditionalAppearance.Items.Add();

	fmDataCompositionClientServer.AddAppearanceField(CAItem.Fields, "fmBudgetingItemCr");

	CommonClientServer.AddCompositionItem(CAItem.Filter,
		"fmBudgetingRecordSet.ItemCrEnabled", DataCompositionComparisonType.Equal, True);

	CommonClientServer.AddCompositionItem(CAItem.Filter,
		"fmBudgetingRecordSet.ItemCr", DataCompositionComparisonType.NotFilled);

	CAItem.Appearance.SetParameterValue("TextColor", StyleColors.fmBlankExtDimension);

	CAItem.Appearance.SetParameterValue("Text", NStr("en='<...>';ru='<...>'"));


	// уфБюджетированиеСтатьяКт

	CAItem = ConditionalAppearance.Items.Add();

	fmDataCompositionClientServer.AddAppearanceField(CAItem.Fields, "fmBudgetingItemCr");

	CommonClientServer.AddCompositionItem(CAItem.Filter,
		"fmBudgetingRecordSet.ItemCrEnabled", DataCompositionComparisonType.Equal, False);

	CAItem.Appearance.SetParameterValue("Visible", False);
	//Валюта

	CAItem = ConditionalAppearance.Items.Add();


	CommonClientServer.AddCompositionItem(CAItem.Filter,
		"fmBudgetingRecordSet.CurrencyDrEnabled", DataCompositionComparisonType.Equal, True);

	CAItem.Appearance.SetParameterValue("Visible", False);



	// уфБюджетированиеВалютаДт, уфБюджетированиеВалютнаяСуммаДт

	CAItem = ConditionalAppearance.Items.Add();

	fmDataCompositionClientServer.AddAppearanceField(CAItem.Fields, "fmBudgetingCurrencyDr");
	fmDataCompositionClientServer.AddAppearanceField(CAItem.Fields, "fmBudgetingCurrencyAmountDr");

	CommonClientServer.AddCompositionItem(CAItem.Filter,
		"fmBudgetingRecordSet.CurrencyDrEnabled", DataCompositionComparisonType.Equal, False);

	CAItem.Appearance.SetParameterValue("Visible", False);


	// уфБюджетированиеВалютаКт, уфБюджетированиеВалютнаяСуммаКт

	CAItem = ConditionalAppearance.Items.Add();

	fmDataCompositionClientServer.AddAppearanceField(CAItem.Fields, "fmBudgetingCurrencyCr");
	fmDataCompositionClientServer.AddAppearanceField(CAItem.Fields, "fmBudgetingCurrencyAmountCr");

	CommonClientServer.AddCompositionItem(CAItem.Filter,
		"fmBudgetingRecordSet.CurrencyCrEnabled", DataCompositionComparisonType.Equal, False);

	CAItem.Appearance.SetParameterValue("Visible", False);

EndProcedure

&AtServer
Procedure AssembleFormAtServer(RecordsDocument)

	CurrentDocumentDate = Object.DATE;
	CurrentBalanceUnit = Object.BalanceUnit;

	OperationMetadata = Object.Ref.Metadata();
	FillRegisterTable(OperationMetadata);
	RegistersWithRecords = New Array;
	
	SetDisplayInRegistersTable(RegistersWithRecords);
	CreateFormAttributes();
	ReadDocumentRecords(RecordsDocument);
	CreateFormItems();
	
	FillTablesAddedColumns();
	
EndProcedure

&AtServer
Procedure SetDocumentState(RowStatusPointing = Undefined)
	
	If RowStatusPointing = "UnwrittenDocument" Then
		DocumentState = 0;	
	ElsIf Object.DeletionMark Then
		DocumentState = 2;
	ElsIf NOT RecordActivities Then
		DocumentState = 11;
	Else
		DocumentState = 1;
	EndIf;
	
EndProcedure

&AtServer
Procedure FillRegisterTable(DocumentMetadata)

	Registers.Clear();
	For Each RegisterMetadata In DocumentMetadata.RegisterRecords Do
		
		RegisterRow     = Registers.Add();
		RegisterRow.Name = RegisterMetadata.Name;
		
		FullName    = RegisterMetadata.FullName();
		PointPosition = Find(FullName, ".");
		RegisterType  = Left(FullName, PointPosition - 1);

		RegisterRow.RegisterType = RegisterType;
		RegisterRow.Synonym     = RegisterMetadata.Synonym;
		
	EndDo;
	
	// Сначала показывается регистр бухгалтерии, затем регистры накопления, затем - сведений
	Registers.Sort("RegisterType, Synonym");

EndProcedure

&AtServer
Procedure SetDisplayInRegistersTable(RegistersWithRecords)

	For Each RegisterRow In Registers Do
		
		If RegisterRow.Name = "fmBudgeting" Then
			RegisterRow.Representation = True;
		EndIf;

	EndDo;

EndProcedure

&AtServer
Procedure CreateFormAttributes()
	
	AttributesNames = New Array;
	For Each Attribute In GetAttributes() Do
		AttributesNames.Add(Attribute.Name);
	EndDo;
	AddedAttributes = New Array;
	DeletedAttributes   = New Array;
	
	For Each RegisterRow In Registers Do
		If RegisterRow.Name = "fmBudgeting" Then
			RegisterRow.HasAttribute = True;
			Continue;
		EndIf;
		AttributeName = RegisterRow.Name + "RecordSet";
		If (RegisterRow.Representation OR RegisterRow.Write)
			AND AttributesNames.Find(AttributeName) = Undefined Then
			AttributeType  = New TypeDescription(RegisterRow.RegisterType + "RecordSet." + RegisterRow.Name);
			NewAttribute = New FormAttribute(AttributeName, AttributeType, , , True);
			AddedAttributes.Add(NewAttribute);
		ElsIf NOT (RegisterRow.Representation OR RegisterRow.Write)
			AND AttributesNames.Find(AttributeName) <> Undefined Then
			DeletedAttributes.Add(AttributeName);
		EndIf;
		RegisterRow.HasAttribute = RegisterRow.Representation OR RegisterRow.Write;
	EndDo;
	
	If AddedAttributes.Count() > 0 
		OR DeletedAttributes.Count() > 0 Then
		ChangeAttributes(AddedAttributes, DeletedAttributes);
	EndIf;

EndProcedure 

&AtServer
Procedure ReadDocumentRecords(RecordsDocument)
	
	RecordActivities = True;
	
	For Each RegisterRow In Registers Do
		If RegisterRow.Representation Then
			AttributeName = RegisterRow.Name + "RecordSet";
			RecordSet = FormAttributeToValue(AttributeName);
			RecordSet.Filter.Recorder.Set(RecordsDocument);
			RecordSet.Read();
			ValueToFormAttribute(RecordSet, AttributeName);
			If RecordsDocument = Object.Ref Then
				RegisterRow.Write = ThisObject[AttributeName].Count() > 0;
				If RegisterRow.Write Then
					RecordActivities = RecordActivities AND ThisObject[AttributeName][0].Active;
				EndIf;
			EndIf;
		EndIf;
	EndDo;
	
EndProcedure 

&AtServer
Procedure CreateFormItems()
	
	Items.FormSwitchRecordActivities.Title = ?(RecordActivities, 
		NStr("en='Disable records activity';ru='Выключить активность движений'"), NStr("en='Enable records activity';ru='Включить активность движений'"));
	
	For Each RegisterRow In Registers Do
		
		If RegisterRow.Name = "fmBudgeting" Then
			Items.GroupBudgeting.Picture = ?(RecordActivities, 
				PictureLib.fmTransactionJournal, PictureLib.fmTransactionJournalInactive);
			Continue;
		EndIf;
		
		GroupName = "Group" + RegisterRow.Name;
		
		CurGroup = Items.Find(GroupName);
		If CurGroup = Undefined 
			AND RegisterRow.Representation Then

			//Найдем группу, перед которой будем вставлять новую группу
			NextGroup = Undefined;
			For Each String In Registers Do
				If String.RegisterType >= RegisterRow.RegisterType
					AND String.Synonym > RegisterRow.Synonym
					AND String.Painted Then
					NextGroup = Items["Group" + String.Name];
					Break;
				EndIf;
			EndDo;

			CurGroup = Items.Insert(GroupName, Type("FormGroup"), Items.RegistersPanel, NextGroup);
			
			CurGroup.Title      = RegisterRow.Synonym;
			RegisterRow.Painted = True;

			// На странице регистра создаем таблицу
			TableName = RegisterRow.Name;
			CurTable = Items.Find(TableName);
			If CurTable <> Undefined Then
				Items.Delete(CurTable);
			EndIf;
			CurTable = Items.Add(TableName, Type("FormTable"), CurGroup);
			TableDataPath = RegisterRow.Name + "RecordSet";
			CurTable.DataPath = TableDataPath;
			CurGroup.TitleDataPath = TableDataPath + ".LineCount";
			// Назначаем общий обработчик
			CurTable.SetAction("OnStartEdit", "Attached_RegisterTableOnStartEdit");
			
			If RegisterRow.RegisterType = "AccountingRegister" Then
				CurGroup.Picture = ?(RecordActivities, 
					PictureLib.TransactionJournal, PictureLib.TransactionJournalInactive);
			EndIf;

			RecordSetAttributes = ThisObject[TableDataPath].Unload(New Array);

			// Некоторые колонки не показываем
			RecordSetAttributes.Columns.Delete("Recorder");
			RecordSetAttributes.Columns.Delete("Active");

			If RecordSetAttributes.Columns.Find("PointInTime") <> Undefined Then
				RecordSetAttributes.Columns.Delete("PointInTime");
			EndIf;

			If RecordSetAttributes.Columns.Find("Period") <> Undefined Then
				RecordSetAttributes.Columns.Delete("Period");
			EndIf;

			If RecordSetAttributes.Columns.Find("BalanceUnit") <> Undefined Then
				RecordSetAttributes.Columns.Delete("BalanceUnit");
			EndIf;
			If RecordSetAttributes.Columns.Find("Scenario") <> Undefined Then
				RecordSetAttributes.Columns.Delete("Scenario");
			EndIf;


			If RecordSetAttributes.Columns.Find("InitialLineNumber") <> Undefined Then
				RecordSetAttributes.Columns.Delete("InitialLineNumber");
			EndIf;
			
			// Создаем колонки таблицы
			For Each AttributeColumn In RecordSetAttributes.Columns Do
				ColumnName = RegisterRow.Name + AttributeColumn.Name;
				CurColumn = Items.Find(ColumnName);
				If CurColumn = Undefined Then
					CurColumn = Items.Add(ColumnName, Type("FormField"), CurTable);
				EndIf;
				CurColumn.DataPath = CurTable.DataPath + "." + AttributeColumn.Name;
				CurColumn.Title   = AttributeColumn.Title;
				CurColumn.Type = FormFieldType.InputField;
				If AttributeColumn.Name = "LineNumber" Then
					CurColumn.Width = 2;
				ElsIf AttributeColumn.Name = "RecordType" Then
					CurColumn.Width = 15;
				EndIf;
				
				
			EndDo;

			SetChoiceParameterLinksOfRegisterListColumn(RegisterRow.Name);
			
		ElsIf CurGroup <> Undefined AND NOT RegisterRow.Representation Then
			
			Items.Delete(CurGroup);
			RegisterRow.Painted = False;
			
		EndIf;

	EndDo;

	//Если отображается не более одного регистра - прячем заголовок у панели регистров
	//Если Регистры.НайтиСтроки(Новый Структура("Отображение", Истина)).Количество() <= 1  Тогда
		Items.RegistersPanel.PagesRepresentation = FormPagesRepresentation.None;
	//Иначе
	//	Элементы.ПанельРегистров.ОтображениеСтраниц = ОтображениеСтраницФормы.ЗакладкиСверху;
	//КонецЕсли;

EndProcedure

&AtServer
Procedure ClearRecords()

	For Each RegisterRow In Registers Do
		If RegisterRow.HasAttribute Then
			ThisObject[RegisterRow.Name + "RecordSet"].Clear();
		EndIf;
	EndDo;

EndProcedure 

&AtServer
Procedure FillRecords(FillingValues)
	
	If NOT FillingValues.Property("fmBudgeting") Then
		Return;
	EndIf;
	
	For Each TransactionStructure In FillingValues.fmBudgeting Do
		
		NewTransaction = fmBudgetingRecordSet.Add();
		FillPropertyValues(NewTransaction, TransactionStructure);
		If NOT TransactionStructure.Property("Active") Then
			NewTransaction.Active = True;
		EndIf;
		
		Items.fmBudgeting.CurrentRow = NewTransaction.GetID();
		ProcessAccountChanging(ThisObject, "Dr");
		ProcessAccountChanging(ThisObject, "Cr");
		SetTypeOfRecordResources(ThisObject, "Dr");
		SetTypeOfRecordResources(ThisObject, "Cr");
		
	EndDo;
	
EndProcedure 

#EndRegion

#Region WorkWithTransactions

&AtClient
Function TransactionDataStructure(CurrentData)

	TransactionStructure = New Structure("LineNumber,AccountDr,ProjectDr,DepartmentDr,ExtDimensionDr1,ExtDimensionDr2,ExtDimensionDr3,
		|CurrencyDr,CurrencyAmountDr,
		|AccountCr,ProjectCr,DepartmentCr,ExtDimensionCr1,ExtDimensionCr2,ExtDimensionCr3,
		|CurrencyCr,CurrencyAmountCr,
		|Amount,Content");
	FillPropertyValues(TransactionStructure, CurrentData);

	Return TransactionStructure;

EndFunction

&AtClientAtServerNoContext
Procedure RecalculateOperationAmount(Form)
	
	Form.Object.OperationAmount = Form.fmBudgetingRecordSet.Total("Amount");

EndProcedure

&AtServer
Procedure RecalculateAmountInRowAtServer(Entry, VAL DATE, VAL RecalculateAmountByRateDr = Undefined)
	
	If RecalculateAmountByRateDr = True Then
		Entry.Amount = RecalculateAmountByRate(Entry.CurrencyAmountDr, Entry.CurrencyDr, DATE);
	ElsIf RecalculateAmountByRateDr = False Then
		Entry.Amount = RecalculateAmountByRate(Entry.CurrencyAmountCr, Entry.CurrencyCr, DATE);
	EndIf;
	
	
EndProcedure

&AtClient
Procedure AmountCalculation(RecalculateAmountByRateDr = Undefined)
	
	If NOT ValueIsFilled(Object.BalanceUnit) Then
		Return;
	EndIf;
	
	CurrentData     = Items.fmBudgeting.CurrentData;
	TransactionStructure = TransactionDataStructure(CurrentData);
	
	RecalculateAmountInRowAtServer(TransactionStructure, Object.DATE, RecalculateAmountByRateDr);
	
	FillPropertyValues(Items.fmBudgeting.CurrentData, TransactionStructure);
	
EndProcedure



&AtServerNoContext
Function RecalculateAmountByRate(VAL CurrencyAmount, VAL Currency, VAL DATE)

	Amount =CurrencyRateOperations.ConvertToCurrency(CurrencyAmount, Currency, Constants.fmCurrencyOfManAccounting.Get(), DATE);
	Return Amount;

EndFunction


#EndRegion

#Region SettingRegisterList

&AtServer
Procedure ApplyRegisterListSetting(UserActionsResult)
	
	For Each ChangedRegister In UserActionsResult Do
		
		RegisterName = ChangedRegister.Value;
		
		SearchResult = Registers.FindRows(New Structure("Name", RegisterName));
		If SearchResult.Count() = 0 Then
			Continue;
		EndIf;
		RegisterRow = SearchResult[0];
		
		RegisterRow.Representation = ChangedRegister.Check;
		
		If NOT RegisterRow.Representation Then
			If RegisterRow.HasAttribute Then
				ThisObject[RegisterName + "RecordSet"].Clear();
			EndIf;
		EndIf;
		
	EndDo;
		
	CreateFormAttributes();
	CreateFormItems();

EndProcedure

#EndRegion

#Region Other

&AtServer
Procedure SwitchRecordActivitiesAtServer()
	
	NewActivity = NOT RecordActivities;
	
	For Each RegisterRow In Registers Do
		If NOT RegisterRow.HasAttribute Then
			Continue;
		EndIf;
		TableDataPath = RegisterRow.Name + "RecordSet";
		
		RecordSet = FormAttributeToValue(TableDataPath);
		RecordSet.SetActive(NewActivity);
		ValueToFormAttribute(RecordSet, TableDataPath);
		
		CurGroup = Items["Group" + RegisterRow.Name];
		If RegisterRow.RegisterType = "AccountingRegister" Then
			CurGroup.Picture = ?(NewActivity, 
				PictureLib.TransactionJournal, PictureLib.TransactionJournalInactive);
		ElsIf RegisterRow.RegisterType = "AccumulationRegister" Then
			CurGroup.Picture = ?(NewActivity, 
				PictureLib.AccumulationRegister, PictureLib.AccumulationRegisterInactive);
		ElsIf RegisterRow.RegisterType = "InformationRegister" Then
			CurGroup.Picture = ?(NewActivity, 
				PictureLib.InformationRegister, PictureLib.InformationRegisterInactive);
		EndIf;
		
	EndDo;
	
	FillTablesAddedColumns();
	
	Items.FormSwitchRecordActivities.Title = ?(NewActivity, 
		NStr("en='Disable records activity';ru='Выключить активность движений'"), NStr("en='Enable records activity';ru='Включить активность движений'"));
	
	RecordActivities = NewActivity;
	SetDocumentState();
	
EndProcedure

 
&AtServer
Procedure SetChoiceParameterLinksOfRegisterListColumn(RegisterName)
	
	ItemCounterparty         = Items.Find(RegisterName + "Counterparty");
	ItemCounterpartyContract = Items.Find(RegisterName + "CounterpartyContract");
	ItemPatent             = Items.Find(RegisterName + "Patent");
	
	If ItemCounterpartyContract <> Undefined Then
		ParametersLinkContract = New Array;
		ParametersLinkContract.Add(New ChoiceParameterLink("Filter.Company", "Object.BalanceUnit.Company"));		
		If ItemCounterparty <> Undefined Then			
			ParametersLinkContract.Add(New ChoiceParameterLink("Filter.Owner", "Items."+RegisterName+".CurrentData.Counterparty"));
		EndIf; 
		ItemCounterpartyContract.ChoiceParameterLinks = New FixedArray(ParametersLinkContract);
	EndIf; 

	If ItemPatent <> Undefined Then
		ParameterLinksPatent = New Array;
		ParameterLinksPatent.Add(New ChoiceParameterLink("Filter.Owner", "Object.BalanceUnit.Company"));
		ItemPatent.ChoiceParameterLinks = New FixedArray(ParameterLinksPatent);
	EndIf; 
	
EndProcedure // УстановитьСвязиПараметровВыбораКолонокСпискаРегистра()

&AtClient
Procedure QueryBalanceUnitOnChangeEnd(Result, AdditionalParameters) Export
	
	If Result = DialogReturnCode.Yes Then
		BalanceUnitOnChangeAtServer();
	Else
		Object.BalanceUnit = CurrentBalanceUnit;
	EndIf;
	
EndProcedure

&AtClient
Procedure fmBudgetingDepartmentCrOnChange(Item)
	CurrentData     = Items.fmBudgeting.CurrentData;
	fmBudgeting.BalanceUnitDepartmentCompatible(Object.BalanceUnit, CurrentData.DepartmentCr, Object.DATE, "Department");
EndProcedure

&AtClient
Procedure fmBudgetingDepartmentDrOnChange(Item)
	CurrentData     = Items.fmBudgeting.CurrentData;
	fmBudgeting.BalanceUnitDepartmentCompatible(Object.BalanceUnit, CurrentData.DepartmentDr, Object.DATE, "Department");
EndProcedure

#EndRegion

#EndRegion
