
#Region ProceduresAndFunctionsOfCommonUse

&AtServer
Procedure SetConditionalAppearance()
	
	ConditionalAppearance.Items.Clear();

	// Субконто
	For Counter = 1 To 3 Do

		// Видимость СубконтоДт

		CAItem = ConditionalAppearance.Items.Add();

		fmDataCompositionClientServer.AddAppearanceField(CAItem.Fields, "ListExtDimensionDr" + Counter);

		CommonClientServer.AddCompositionItem(CAItem.Filter,
			"List.ExtDimensionTypeDr" + Counter, DataCompositionComparisonType.NotFilled);

		CAItem.Appearance.SetParameterValue("Visible", False);


		// Выделение незаполненного СубконтоДт

		CAItem = ConditionalAppearance.Items.Add();

		fmDataCompositionClientServer.AddAppearanceField(CAItem.Fields, "ListExtDimensionDr" + Counter);

		CommonClientServer.AddCompositionItem(CAItem.Filter,
			"List.ExtDimensionTypeDr" + Counter, DataCompositionComparisonType.Filled);

		CommonClientServer.AddCompositionItem(CAItem.Filter,
			"List.ExtDimensionDr" + Counter, DataCompositionComparisonType.NotFilled);

		CAItem.Appearance.SetParameterValue("TextColor", New Color(128, 128, 128));

		CAItem.Appearance.SetParameterValue("Text", NStr("en='<...>';ru='<...>'"));
		

		// Видимость СубконтоКт

		CAItem = ConditionalAppearance.Items.Add();

		fmDataCompositionClientServer.AddAppearanceField(CAItem.Fields, "ListExtDimensionCr" + Counter);

		CommonClientServer.AddCompositionItem(CAItem.Filter,
			"List.ExtDimensionTypeCr" + Counter, DataCompositionComparisonType.NotFilled);

		CAItem.Appearance.SetParameterValue("Visible", False);
		

		// Выделение незаполненного СубконтоКт
		
		CAItem = ConditionalAppearance.Items.Add();

		fmDataCompositionClientServer.AddAppearanceField(CAItem.Fields, "ListExtDimensionCr" + Counter);

		CommonClientServer.AddCompositionItem(CAItem.Filter,
			"List.ExtDimensionTypeCr" + Counter, DataCompositionComparisonType.Filled);

		CommonClientServer.AddCompositionItem(CAItem.Filter,
			"List.ExtDimensionCr" + Counter, DataCompositionComparisonType.NotFilled);

		CAItem.Appearance.SetParameterValue("TextColor", New Color(128, 128, 128));

		CAItem.Appearance.SetParameterValue("Text", NStr("en='<...>';ru='<...>'"));
		
	EndDo;
	
	//////////////////////
	// Сценарий, БалансоваяЕдиница
	CAItem = ConditionalAppearance.Items.Add();

	fmDataCompositionClientServer.AddAppearanceField(CAItem.Fields, "Scenario");
	
	CommonClientServer.AddCompositionItem(CAItem.Filter,
		"List.Scenario", DataCompositionComparisonType.NotFilled);
	
	CAItem.Appearance.SetParameterValue("TextColor", New Color(128, 128, 128));

	CAItem.Appearance.SetParameterValue("Text", NStr("en='<...>';ru='<...>'"));
	
	
	CAItem = ConditionalAppearance.Items.Add();

	fmDataCompositionClientServer.AddAppearanceField(CAItem.Fields, "BalanceUnit");
	
	CommonClientServer.AddCompositionItem(CAItem.Filter,
		"List.BalanceUnit", DataCompositionComparisonType.NotFilled);

	CAItem.Appearance.SetParameterValue("TextColor", New Color(128, 128, 128));

	CAItem.Appearance.SetParameterValue("Text", NStr("en='<...>';ru='<...>'"));

	// Незаполненное ПодразделениеДт, СтатьяДт и ФинансовыйРезультатДт

	CAItem = ConditionalAppearance.Items.Add();

	fmDataCompositionClientServer.AddAppearanceField(CAItem.Fields, "ListDepartmentDr");
	
	CommonClientServer.AddCompositionItem(CAItem.Filter,
		"List.FinResDr", DataCompositionComparisonType.Equal, True);

	CommonClientServer.AddCompositionItem(CAItem.Filter,
		"List.DepartmentDr", DataCompositionComparisonType.NotFilled);
	
	CAItem.Appearance.SetParameterValue("TextColor", New Color(128, 128, 128));

	CAItem.Appearance.SetParameterValue("Text", NStr("en='<...>';ru='<...>'"));

	
	
	CAItem = ConditionalAppearance.Items.Add();
	
	fmDataCompositionClientServer.AddAppearanceField(CAItem.Fields, "ItemDr");
	
	CommonClientServer.AddCompositionItem(CAItem.Filter,
		"List.FinResDr", DataCompositionComparisonType.Equal, True);

	CommonClientServer.AddCompositionItem(CAItem.Filter,
		"List.ItemDr",DataCompositionComparisonType.NotFilled);
	
	CAItem.Appearance.SetParameterValue("TextColor", New Color(128, 128, 128));
	
	CAItem.Appearance.SetParameterValue("Text", NStr("en='<...>';ru='<...>'"));
	
	
	// Видимость ПодразделенияДт и СтатьяДт
	
	CAItem = ConditionalAppearance.Items.Add();

	fmDataCompositionClientServer.AddAppearanceField(CAItem.Fields, "ListDepartmentDr");
	
	fmDataCompositionClientServer.AddAppearanceField(CAItem.Fields, "ItemDr");
	
	
	CommonClientServer.AddCompositionItem(CAItem.Filter,
		"List.FinResDr", DataCompositionComparisonType.Equal, False);

	CAItem.Appearance.SetParameterValue("Visible", False);
	
	

	// Незаполненное ПодразделениеКт и СтатьяКт

	CAItem = ConditionalAppearance.Items.Add();

	fmDataCompositionClientServer.AddAppearanceField(CAItem.Fields, "ListDepartmentCr");
	
	fmDataCompositionClientServer.AddAppearanceField(CAItem.Fields, "ItemCr");

	CommonClientServer.AddCompositionItem(CAItem.Filter,
		"List.FinResCr", DataCompositionComparisonType.Equal, True);

	CommonClientServer.AddCompositionItem(CAItem.Filter,
		"List.DepartmentCr", DataCompositionComparisonType.NotFilled);
	
	CommonClientServer.AddCompositionItem(CAItem.Filter,
		"List.ItemCr",DataCompositionComparisonType.NotFilled);

	CAItem.Appearance.SetParameterValue("TextColor", New Color(128, 128, 128));

	CAItem.Appearance.SetParameterValue("Text", NStr("en='<...>';ru='<...>'"));


	// Видимость ПодразделениеКт и СтатьяКт

	CAItem = ConditionalAppearance.Items.Add();

	fmDataCompositionClientServer.AddAppearanceField(CAItem.Fields, "ListDepartmentCr");
	
	fmDataCompositionClientServer.AddAppearanceField(CAItem.Fields, "ItemCr");

	CommonClientServer.AddCompositionItem(CAItem.Filter,
		"List.FinResCr", DataCompositionComparisonType.Equal, False);

	CAItem.Appearance.SetParameterValue("Visible", False);

	// ВалютаДт

	CAItem = ConditionalAppearance.Items.Add();

	CommonClientServer.AddCompositionItem(CAItem.Filter,
		"List.AccountDrCurrency", DataCompositionComparisonType.Equal, True);

	CAItem.Appearance.SetParameterValue("Visible", False);


	// ВалютаКт

	CAItem = ConditionalAppearance.Items.Add();

	CommonClientServer.AddCompositionItem(CAItem.Filter,
		"List.AccountCrCurrency", DataCompositionComparisonType.Equal, True);

	CAItem.Appearance.SetParameterValue("Visible", False);


	// СписокВалютаДт, СписокВалютнаяСуммаДт

	CAItem = ConditionalAppearance.Items.Add();

	fmDataCompositionClientServer.AddAppearanceField(CAItem.Fields, "ListCurrencyDr");
	
	fmDataCompositionClientServer.AddAppearanceField(CAItem.Fields, "ListCurrencyAmountDr");

	CommonClientServer.AddCompositionItem(CAItem.Filter,
		"List.AccountDrCurrency", DataCompositionComparisonType.Equal, False);

	CAItem.Appearance.SetParameterValue("Visible", False);


	// СписокВалютаКт, СписокВалютнаяСуммаКт

	CAItem = ConditionalAppearance.Items.Add();

	fmDataCompositionClientServer.AddAppearanceField(CAItem.Fields, "ListCurrencyCr");
	
	fmDataCompositionClientServer.AddAppearanceField(CAItem.Fields, "ListCurrencyAmountCr");

	CommonClientServer.AddCompositionItem(CAItem.Filter,
		"List.AccountCrCurrency", DataCompositionComparisonType.Equal, False);

	CAItem.Appearance.SetParameterValue("Visible", False);


EndProcedure

&AtClient
Function GetDocument()
	
	CurData = Items.List.CurrentData;
	
	If CurData = Undefined Then
		CommonClientServer.MessageToUser(NStr("en='The document is not selected';ru='Не выбран документ'"));
		Return Undefined;
	EndIf;
	
	CurDocument = CurData.Recorder;
	If NOT ValueIsFilled(CurDocument) Then
		CommonClientServer.MessageToUser(NStr("en='The document is not selected';ru='Не выбран документ'"));
		Return Undefined;
	EndIf;
	
	Return CurDocument;
	
EndFunction

#EndRegion

#Region FormItemsEventsHandlers

&AtServer
Procedure ToggleEntriesActivityServer(Document)
	
	fmBudgeting.SwitchEntriesActivityBudgeting(Document);
	
	Items.List.Refresh();
	
EndProcedure

&AtClient
Procedure ToggleEntriesActivity(Command)
	
	CurDocument = GetDocument();
	
	If CurDocument <> Undefined Then
		
		ToggleEntriesActivityServer(CurDocument);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure ListChoice(Item, SelectedRow, Field, StandardProcessing)
	
	If TypeOf(Item.CurrentData.Recorder) = Type("DocumentRef.fmBudgetingOperation") Then
		
		StandardProcessing = False;
		FormParameters       = New Structure("ParameterCurrentRow,Key", 
			Item.CurrentData.LineNumber, Item.CurrentData.Recorder);
		OpenForm("Document.fmBudgetingOperation.ObjectForm", FormParameters);
		
	EndIf;
	
EndProcedure

#EndRegion

#Region FormEventsHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	fmCommonUseServer.SetFilterByMainBalanceUnit(ThisForm);
	
	SetConditionalAppearance();
	Items.GroupAmountContent.Title     = NStr("ru='Сумма в ';en='Amount in '") + Constants.fmCurrencyOfManAccounting.Get();

EndProcedure

&AtServer
Procedure ListBeforeLoadUserSettingsAtServer(Item, Settings)
	
	fmCommonUseServer.RestoreListFilter(List, Settings, "BalanceUnit");
	
EndProcedure

#EndRegion


