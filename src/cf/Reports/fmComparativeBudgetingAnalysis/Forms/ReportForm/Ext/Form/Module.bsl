
////////////////////////////////////////////////////////////////////////////////
//// ПРОЦЕДУРЫ И ФУНКЦИИ ОБЩЕГО НАЗНАЧЕНИЯ

&AtClient
Function GetDeniedFields(Mode = "") Export
	
	FileldList = New Array;
	
	FileldList.Add("UserFields");
	FileldList.Add("DataParameters");
	FileldList.Add("SystemFields");
	FileldList.Add("Period");
	
	//если сводная таблица, добавляем в доступные отборы счет
	FileldList.Add("Account");	
	
	If Mode = "CASE" Then
		For Each AvailableField In Report.SettingsComposer.Settings.SelectionAvailableFields.Items Do
			If AvailableField.Resource Then
				FileldList.Add(String(AvailableField.Field));
			EndIf;
		EndDo;
	EndIf;
	
	If Mode = "CASE" Then
		FileldList.Add("BalanceBegOfPeriod");
		FileldList.Add("PeriodTurnovers");
		FileldList.Add("BalanceEndOfPeriod");
		If NOT ValueIsFilled(Report.InfoStructure) Then
			FileldList.Add("Item");
		EndIf;
	ElsIf Mode = "Filter" Then
		fmReportsClient.AddResourceFiledsDeniedFields(ThisForm, FileldList);
	EndIf;
	
	Return New FixedArray(FileldList);
	
EndFunction

&AtClientAtServerNoContext
//Процедура, обновляющая текст заголовка формы
//
Procedure RefreshTitleText(Form, VariantDescription = "")
	
	Report = Form.Report;
	
	ReportTitle = NStr("en='Comparative analysis in budgeting';ru='Сравнительный анализ бюджетирования'") ;
	
	If NOT IsBlankString(VariantDescription) Then
		
		ReportTitle = ReportTitle + StrTemplate(NStr("en='(Report variant: ""%1"")';ru=' (Вариант отчета: ""%1"")'"), VariantDescription);
	EndIf;
	
	Form.Title = ReportTitle;

EndProcedure //ОбновитьТекстЗаголовка()

&AtServer
//Обработка нажатия на кнопку "Сформировать отчет"
//
Procedure GenerateReportAtServer()

	If NOT CheckFilling() Then 
		Return;
	EndIf;

	ThisReport = FormAttributeToValue("Report");
	ThisReport.GenerateReport(Result, DetailsData, CompositionSchemeAddress);

	fmReportsClientServer.SetState(ThisForm, True);

EndProcedure //СформироватьОтчетНаСервере()

&AtClientAtServerNoContext
//Процедура обновляет представление периода
//
Procedure FormManagement(Form)
	
	Report	= Form.Report;
	Items= Form.Items;
	
	If Report.ComparedData.Count() > 0 Then
		Form.PeriodType = fmReportsClientServer.GetPeriodType(Report.ComparedData[0].BeginOfPeriod, Report.ComparedData[0].EndOfPeriod, Form);
	Else
		Form.PeriodType = fmReportsClientServer.GetPeriodType(DATE("00010101"), DATE("00010101"), Form);
	EndIf;
	
	Report.PeriodType = Form.PeriodType;
	Form.Period1     = fmReportsClientServer.GetReportPeroidRepresentation(Form.PeriodType, Report.BeginOfPeriod1, Report.EndOfPeriod1, Form);
	Form.Period2     = fmReportsClientServer.GetReportPeroidRepresentation(Form.PeriodType, Report.BeginOfPeriod2, Report.EndOfPeriod2, Form);
	
	If Form.BudgetVersioning = PredefinedValue("Enum.fmBudgetVersioning.EveryDay") Then
		VersionFormat = "L=en; DF='dd MMMM yyyy ''y.'''";
	Else
		VersionFormat = "L=en; DF='MMMM yyyy'";
	EndIf;

	For Each CurCompData In Report.ComparedData Do
		CurCompData.Period     = fmReportsClientServer.GetReportPeroidRepresentation(Form.PeriodType, CurCompData.BeginOfPeriod, CurCompData.EndOfPeriod, Form);
		CurCompData.Version     = Format(CurCompData.VersionPeriod,VersionFormat);
		ScenarioType = GetScenarioType(CurCompData.PlanningScenario);
		CurCompData.VersionAvailability = ?(ScenarioType = PredefinedValue("Enum.fmBudgetingScenarioTypes.Fact"),False,True);
	EndDo;
	Items.ComparedDataVersion.Visible = ?(NOT ValueIsFilled(Form.BudgetVersioning)OR Form.BudgetVersioning=PredefinedValue("Enum.fmBudgetVersioning.DontUse"),False,True);
	
	Form.Items.Deviations.Enabled = (Report.ComparedData.Count()>1);
	
EndProcedure //УправлениеФормой()

&AtClient
Procedure ChooseReportArbitraryPeriod(Form, BeginOfPeriod, EndOfPeriod, MinimumPeriodicity, PeriodNumber, CurComparedData = Undefined, IsPeriodicityChange=False) 
	
	If MinimumPeriodicity = Undefined Then
		MinimumPeriodicity = Form.AvailableReportPeriods.Day;
	EndIf;
	
	If NOT IsPeriodicityChange Then
		
		FormParameters = New Structure("BeginOfPeriod, EndOfPeriod, MinimumPeriod, PeriodType", 
		BeginOfPeriod, EndOfPeriod, Form.AvailableReportPeriods.Day, "PeriodType");
		PeriodSetting = OpenFormModal("CommonForm.ArbitraryPeriodChoice", FormParameters, Form);
		
		If PeriodSetting = Undefined Then
			Return;
		EndIf;
		
		BeginOfPeriod = PeriodSetting.BeginOfPeriod;
		EndOfPeriod  = EndOfDay(PeriodSetting.EndOfPeriod);
		
	EndIf;
	
	If CurComparedData = Undefined Then
		
		If NOT PeriodNumber = 2 Then
			Form.PeriodType = fmReportsClientServer.GetPeriodType(BeginOfPeriod, EndOfPeriod, Form);
		Else
			Form.PeriodType = fmReportsClientServer.GetPeriodType(Form.Report.BeginOfPeriod1, Form.Report.EndOfPeriod1, Form);
		EndIf;
		If PeriodNumber = 2 Then
			Form.Period2     = fmReportsClientServer.GetReportPeroidRepresentation(Form.PeriodType, 
			PeriodSetting.BeginOfPeriod, PeriodSetting.EndOfPeriod, Form);
			CheckPeriodsCompatibility(ThisForm, Form.Report.BeginOfPeriod1, Form.Report.EndOfPeriod1, BeginOfPeriod, EndOfPeriod);
			
		Else
			Form.Period1     = fmReportsClientServer.GetReportPeroidRepresentation(Form.PeriodType, 
			PeriodSetting.BeginOfPeriod, PeriodSetting.EndOfPeriod, Form);
		EndIf;
		
	Else
		CurComparedData.Period = fmReportsClientServer.GetReportPeroidRepresentation(Form.PeriodType, 
		BeginOfPeriod, EndOfPeriod, Form);
	EndIf;
	
EndProcedure

&AtClient
Procedure CheckPeriodsCompatibility(ThisForm, BeginOfPeriod1, EndOfPeriod1, BeginOfPeriod2, EndOfPeriod2)
	DifferenceDaysInFirstPeriod = (BegOfDay(EndOfPeriod1)-BegOfDay(BeginOfPeriod1))/(60*60*24);
	DifferenceDaysInSecondPeriod = (BegOfDay(EndOfPeriod2)-BegOfDay(BeginOfPeriod2))/(60*60*24);
	If Round(DifferenceDaysInFirstPeriod / 30) <> Round(DifferenceDaysInSecondPeriod / 30) Then
		Message(NStr("en='The periods of comparison should be similar in a month quantity.';ru='Периоды сравнения должны быть сопоставимы по количеству месяцев!'"));
		
		ChooseReportArbitraryPeriod(ThisForm, BeginOfPeriod2, EndOfPeriod2, AvailableReportPeriods.Day, 2);
		
		RefreshTitleText(ThisForm, ReportVariantDescription);
		
		fmReportsClientServer.SetState(ThisForm);
	EndIf;
EndProcedure

&AtServer
//Функция, возвращающая путь к данным ресурсов текущей схемы компоновки данных(Тип элементов - Строка)
//
Function GetResourcesAtServer()
	
	CompositionSchema = GetFromTempStorage(CompositionSchemeAddress);
	ResourcesArray = New Array;
	For Each Item In CompositionSchema.TotalFields Do
		ResourcesArray.Add(Item.DataPath);
	EndDo;
	Return ResourcesArray;
	
EndFunction //ПолучитьРесурсыНаСервере()

&AtServer
//Процедура, формирующая список группировок отчета
//
Procedure AddGroups(Structure, FileldList, ShowTablesGroups = True)
	
	For Each StructureItem In Structure Do
		If TypeOf(StructureItem) = Type("DataCompositionTable") Then
			AddGroups(StructureItem.Rows, FileldList);
			AddGroups(StructureItem.Columns, FileldList);
		ElsIf TypeOf(StructureItem) = Type("DataCompositionChart") Then
			AddGroups(StructureItem.Series, FileldList);
			AddGroups(StructureItem.Points, FileldList);
		Else
			If StructureItem.Use Then
				FileldList.Add(StructureItem);
			EndIf;
			If ShowTablesGroups Then
				AddGroups(StructureItem.Structure, FileldList);
			EndIf;
		EndIf;
	EndDo;
	
EndProcedure //ДобавитьГруппировки()

&AtServer
// Процедура обработчик "ВычислитьСуммуВыделенныхЯчеекТабличногоДокументаВКонтекстеНаСервере". 
//
Procedure SumSelectedSpreadsheetDocumentCells()
	
	AmountField = fmReportsServerCall.EvalAmountOfSpreadsheetDocumentSelectedCells(
		Result, SelectedAreaCache);
	
EndProcedure

&AtClient
Procedure Attached_ResultOnActivateAreaAttached()
	
	NecessaryToCalculateAtServer = False;
	fmReportsClient.EvalAmountOfSpreadsheetDocumentSelectedCells(
		AmountField, Result, SelectedAreaCache, NecessaryToCalculateAtServer);
	
	If NecessaryToCalculateAtServer Then
		SumSelectedSpreadsheetDocumentCells();
	EndIf;
	
	DetachIdleHandler("Attached_ResultOnActivateAreaAttached");
	
EndProcedure

&AtClient
Procedure PeriodTypeChangeProcessing(Form, BeginOfPeriod, EndOfPeriod, MinimumPeriodicity, PeriodNumber, CurCompData = Undefined) Export
	
	If Form.PeriodType = Form.AvailableReportPeriods.ArbitraryPeriod Then
		ChooseReportArbitraryPeriod(Form, BeginOfPeriod, EndOfPeriod, MinimumPeriodicity, PeriodNumber, CurCompData, True);
	Else
		If ValueIsFilled(BeginOfPeriod) Then
			BeginOfPeriod = fmReportsClientServer.ReportBegOfPeriod(Form.PeriodType, BeginOfPeriod, Form);
			EndOfPeriod  = fmReportsClientServer.ReportEndOfPeriod(Form.PeriodType, BeginOfPeriod, Form);
		Else
			BeginOfPeriod = Undefined;
			EndOfPeriod  = Undefined;
		EndIf;
		
		List = fmReportsClientServer.GetPeriodList(BeginOfPeriod, Form.PeriodType, Form);
		ListItem = List.FindByValue(BeginOfPeriod);
		If ListItem <> Undefined Then
			If CurCompData = Undefined Then
				If PeriodNumber = 2 Then
					Form.Period2 = ListItem.Presentation;
				Else
					Form.Period1 = ListItem.Presentation;
				EndIf;
			Else
				CurCompData.Period = ListItem.Presentation;
			EndIf;
		EndIf;
		
	EndIf;
	
EndProcedure


////////////////////////////////////////////////////////////////////////////////
// ПРОЦЕДУРЫ - ДЕЙСТВИЯ КОМАНДНЫХ ПАНЕЛЕЙ ФОРМЫ

&AtClient
//Обработчик события нажатия на кнопку "Сформировать отчет"
//
Procedure GenerateReport(Command)
	
	ClearMessages();
	GenerateReportAtServer();
	
	//Когда отчет сформирован, открываем доступность кнопки "Сводная таблица в Excel"
	
EndProcedure //СформироватьОтчет()

&AtClient
//Обработчик события нажатия на кнопку "Настройки"
//
Procedure SettingsPanel(Command)
	
	Items.GroupSettingsPanel.Visible = NOT Items.GroupSettingsPanel.Visible;
	fmReportsClientServer.ChangeButtonTitleSettingsPanel(
		Items.SettingsPanel, Items.GroupSettingsPanel.Visible);
	
EndProcedure //ПанельНастроек()

&AtClient
Function SelectReportPeriod(Form, Item, StandardProcessing, BeginOfPeriod, MinimumPeriod=Undefined, MaximumPeriod=Undefined,PeriodName="Period")
	
	CurPeriodType = ?(PeriodName="Version",Form.AvailableReportPeriods.Month,Form.PeriodType);
	List = fmReportsClientServer.GetPeriodList(BeginOfPeriod, CurPeriodType, Form, MinimumPeriod, MaximumPeriod);
	If List.Count() = 0 Then
		StandardProcessing = False;
		Return Undefined;
	EndIf;
	
	ListItem = List.FindByValue(BeginOfPeriod);
	SelectedPeriod = Form.ChooseFromList(List, Item, ListItem);
	
	If SelectedPeriod = Undefined Then
		Return Undefined;
	EndIf;
	
	IndexOf = List.IndexOf(SelectedPeriod);
	If (IndexOf = 0 OR IndexOf = List.Count() - 1) AND MaximumPeriod=Undefined Then
		SelectedPeriod = SelectReportPeriod(Form, Item, StandardProcessing, SelectedPeriod.Value,,,PeriodName);
	EndIf;
	
	Return SelectedPeriod;
	
EndFunction


////////////////////////////////////////////////////////////////////////////////
// ПРОЦЕДУРЫ - ОБРАБОТЧИКИ СОБЫТИЙ ЭЛЕМЕНТОВ ФОРМЫ

&AtClient
//Обработчик события при изменении вида периода
//
Procedure PeriodTypeOnChange(Item)
	
	For Each CurCompData In Report.ComparedData Do
		PeriodTypeChangeProcessing(ThisForm, CurCompData.BeginOfPeriod, CurCompData.EndOfPeriod, 
		AvailableReportPeriods.Day, 1, CurCompData);
	EndDo;
	
	RefreshTitleText(ThisForm, ReportVariantDescription);
	
	fmReportsClientServer.SetState(ThisForm);
	
	Report.PeriodType = ThisForm.PeriodType;
	
EndProcedure //ВидПериодаПриИзменении()


////////////////////////////////////////////////////////////////////////////////
// ПРОЦЕДУРЫ - ОБРАБОТЧИКИ СОБЫТИЙ ФОРМЫ

&AtServer
Procedure OnCreateAtServer(Form, Cancel, StandardProcessing)
	
	BudgetVersioning = Constants.fmBudgetVersioning.Get();
	Items.PeriodType.ListChoiceMode = True;
	AvailableReportPeriods = fmReportsServerCall.GetAvailableReportPeriods();
	fmReportsServerCall.GetAvailablePeriodList(AvailableReportPeriods.Month,
		Items.PeriodType.ChoiceList,
		AvailableReportPeriods.Month);
	
	PeriodType = Items.PeriodType.ChoiceList[0].Value;
	
	ReportObject = FormAttributeToValue("Report");
	ThisForm.IndicatorSet = New FixedArray(ReportObject.IndicatorSet);
	
	If NOT ValueIsFilled(ThisForm.DataCompositionSchema) Then
		ThisForm.DataCompositionSchema = PutToTempStorage(ReportObject.DataCompositionSchema, ThisForm.UUID);
	EndIf;
	
	SetDefaultSettingsAtServer(); // обязательно после вызова ОткрытИзРасшифровки()
	
	FormManagement(ThisForm);
	
EndProcedure //ПриСозданииНаСервере()

Procedure FillGroups(ClearGroups = False)
	
	If ClearGroups = True Then
		Report.GroupingByRows.Clear();
		Report.GroupingByColumns.Clear();
		Report.Deviations.Clear();
	EndIf;
	
	AddGroupingRow("Rows", "BalanceUnit", NStr("en='Balance unit';ru='Баланс. единица'"), "WithoutGroups", NStr("en='Without groups';ru='Без групп'"), False);
	AddGroupingRow("Rows", "Departments", NStr("en='Department';ru='Подразделение'"), "WithoutGroups", NStr("en='Without groups';ru='Без групп'"), True);
	AddGroupingRow("Rows", "Item", NStr("en='Item';ru='Статья'"), "WithoutGroups", NStr("en='Without groups';ru='Без групп'"), True);
	AddGroupingRow("Rows", "Analytics1", NStr("en='Dimension 1';ru='Аналитика 1'"), "WithoutGroups", NStr("en='Without groups';ru='Без групп'"), False);
	AddGroupingRow("Rows", "Analytics2", NStr("en='Dimension 2';ru='Аналитика 2'"), "WithoutGroups", NStr("en='Without groups';ru='Без групп'"), False);
	AddGroupingRow("Rows", "Analytics3", NStr("en='Dimension 3';ru='Аналитика 3 '"), "WithoutGroups", NStr("en='Without groups';ru='Без групп'"), False);
	If Constants.fmProjectAccounting.Get() Then
		AddGroupingRow("Rows", "Project", NStr("en='Project';ru='Проект'"), "WithoutGroups", NStr("en='Without groups';ru='Без групп'"), ?(ValueIsFilled(ProjectFromDetails), True, False));
	EndIf;
	AddGroupingRow("Rows", "Currency", NStr("en='Currency';ru='Валюта'"), "WithoutGroups", NStr("en='Without groups';ru='Без групп'"), False);
	AddGroupingRow("Rows", "GroupYear", NStr("en='Year';ru='Год'"), "WithoutGroups", NStr("en='Without groups';ru='Без групп'"), False);
	AddGroupingRow("Rows", "GroupQuarter", NStr("en='Quarter';ru='Квартал'"), "WithoutGroups", NStr("en='Without groups';ru='Без групп'"), False);
	AddGroupingRow("Rows", "Period", NStr("en='Month';ru='Месяц'"), "WithoutGroups", NStr("en='Without groups';ru='Без групп'"), False);
	
	AddGroupingRow("Columns", "BalanceUnit", NStr("en='Balance unit';ru='Баланс. единица'"), "WithoutGroups", NStr("en='Without groups';ru='Без групп'"), False);
	AddGroupingRow("Columns", "Departments", NStr("en='Department';ru='Подразделение'"), "WithoutGroups", NStr("en='Without groups';ru='Без групп'"), False);
	AddGroupingRow("Columns", "Item", NStr("en='Item';ru='Статья'"), "WithoutGroups", NStr("en='Without groups';ru='Без групп'"), False);
	AddGroupingRow("Columns", "Analytics1", NStr("en='Dimension 1';ru='Аналитика 1'"), "WithoutGroups", NStr("en='Without groups';ru='Без групп'"), False);
	AddGroupingRow("Columns", "Analytics2", NStr("en='Dimension 2';ru='Аналитика 2'"), "WithoutGroups", NStr("en='Without groups';ru='Без групп'"), False);
	AddGroupingRow("Columns", "Analytics3", NStr("en='Dimension 3';ru='Аналитика 3'"), "WithoutGroups", NStr("en='Without groups';ru='Без групп'"), False);
	If Constants.fmProjectAccounting.Get() Then
		AddGroupingRow("Columns", "Project", NStr("en='Project';ru='Проект'"), "WithoutGroups", NStr("en='Without groups';ru='Без групп'"), False);
	EndIf;
	AddGroupingRow("Columns", "Currency", NStr("en='Currency';ru='Валюта'"), "WithoutGroups", NStr("en='Without groups';ru='Без групп'"), False);
	AddGroupingRow("Columns", "GroupYear", NStr("en='Year';ru='Год'"), "WithoutGroups", NStr("en='Without groups';ru='Без групп'"), False);
	AddGroupingRow("Columns", "GroupQuarter", NStr("en='Quarter';ru='Квартал'"), "WithoutGroups", NStr("en='Without groups';ru='Без групп'"), False);
	AddGroupingRow("Columns", "Period", NStr("en='Month';ru='Месяц'"), "WithoutGroups", NStr("en='Without groups';ru='Без групп'"), True);
	
	//Отклонения
	AddGroupingRow("Deviations", "DeviationRel", NStr("en='Deviation, %';ru='Отклонение, %'"));
	AddGroupingRow("Deviations", "Deviation", NStr("en='Deviation, abs.';ru='Отклонение, абс.'"));
	AddGroupingRow("Deviations", "Execution", NStr("en='Implementation, %';ru='Исполнение, %'"));
	
EndProcedure

Procedure AddGroupingRow(Purpose, FieldName, FieldPresentation, GroupType=Undefined, GroupTypePresentation=Undefined, Use = True)
	
	If Purpose = "Rows" Then
		
		TS = Report.GroupingByRows;
	ElsIf Purpose = "Columns" Then
		
		TS = Report.GroupingByColumns;
	ElsIf Purpose = "Deviations" Then
	
		TS = Report.Deviations;
	EndIf;
	
	Rows = TS.FindRows(New Structure("Field", FieldName));
	String = ?(Rows.Count() > 0, Rows[0], Undefined);
	AddRow = (String = Undefined);
	
	If AddRow Then
		
		String = TS.Add();
		String.Use= Use;
		
	EndIf;
	
	String.Field			= FieldName;
	String.Presentation= FieldPresentation;
	If NOT GroupTypePresentation = Undefined Then
		String.GroupType= GroupTypePresentation;
	EndIf;
	
EndProcedure // ДобавитьСтрокуГруппировки()

&AtClient
Procedure BeforeClose(Cancel, StandardProcessing)
	ThisForm.VariantModified = False;
	ThisForm.UserSettingsModified = True;
EndProcedure //ПередЗакрытием()

&AtServer
// Процедура обработчик "ПриСохраненииПользовательскихНастроекНаСервере" 
//
Procedure OnSaveUserSettingsAtServer(Settings)
	
	fmReportsServerCall.OnSaveUserSettingsAtServer(ThisForm, Settings);
	
EndProcedure

&AtServer
// Процедура обработчик "ПриЗагрузкеПользовательскихНастроекНаСервере" 
//
Procedure OnLoadUserSettingsAtServer(Settings)
	
	fmReportsServerCall.OnLoadUserSettingsAtServer(ThisForm, Settings);
	
	RefreshTitleText(ThisForm);
	
	FormManagement(ThisForm);
	
	If NOT ValueIsFilled(JobID) Then
		fmReportsClientServer.SetSpreadsheetDocumentFieldState(Items.Result, "Irrelevance");
	EndIf;
	
EndProcedure


&AtServer
// Процедура обработчик "ПриЗагрузкеВариантаНаСервере" 
//
Procedure OnLoadVariantAtServer(Settings)
	
	// en script begin
	//БухгалтерскиеОтчетыВызовСервера.УстановитьНастройкиПоУмолчанию(ЭтаФорма);
	// en script end
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// ПРОЦЕДУРЫ - ОБРАБОТЧИКИ СОБЫТИЙ ЭЛЕМЕНТОВ ГРУППЫ "ОСНОВНЫЕ НАСТРОЙКИ"


&AtClient
//Обработчик события начало выбора вида отчета
//
Procedure InfoStructureStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	
	ChoiceForm = GetForm("Catalog.fmInfoStructures.ChoiceForm",, Item);

	FilterItem = fmReportsClientServer.AddFilter(ChoiceForm.List.Filter, "StructureType", Report.StructureType);
	FilterItem.ViewMode = DataCompositionSettingsItemViewMode.Auto;

	ChoiceForm.Open();
	
EndProcedure //СтруктураСведенийНачалоВыбора()


&AtClient
//Обработчик события перед началом добавления отбора
//
Procedure FilterBeforeAddRow(Item, Cancel, Copy, Parent, Group)
	
	fmReportsClient.FilterBeforeAddRow(ThisForm, Item, Cancel, Copy, Parent, Group);
	
EndProcedure //ОтборыПередНачаломДобавления()

&AtClient
//Обработчик события перед началом изменения отбора
//
Procedure FiltersBeforeRowChange(Item, Cancel)
	
	fmReportsClient.FiltersBeforeRowChange(ThisForm, Item, Cancel);
	
EndProcedure //ОтборыПередНачаломДобавления()

&AtClient
//Обработчик события при изменении отбора
//
Procedure FiltersOnChange(Item)
	
	RefreshTitleText(ThisForm, ReportVariantDescription);
	
EndProcedure //ОтборыПередНачаломДобавления()

&AtClient
//Обработчик события при изменении ТЧ Группировка по строкам
//
Procedure GroupingByRowsOnChange(Item)
	
	fmReportsClientServer.SetState(ThisForm);

EndProcedure //ГруппировкаПоСтрокамПриИзменении()

&AtClient
//Обработчик события перед началом добавления ТЧ Группировка по строкам
//
Procedure GroupingByRowsBeforeAdd(Item, Cancel, Copy, Parent, Group)
	
	fmReportsClient.GroupingByRowsBeforeAdd(ThisForm, Item, Cancel, Copy, Parent, Group);
	
EndProcedure //ГруппировкаПоСтрокамПередНачаломДобавления()

&AtClient
//Обработчик события перед начало изменения ТЧ Группировка по строкам
//
Procedure GroupingByRowsBeforeChange(Item, Cancel)
	
	fmReportsClient.GroupingByRowsBeforeChange(ThisForm, Item, Cancel);
	
EndProcedure //ГруппировкаПоСтрокамПередНачаломИзменения()

&AtClient
//Обработчик события начала выбора типа группировки в ТЧ Группировка по строкам
//
Procedure GroupingByRowsGroupTypeStartChoice(Item, ChoiceData, StandardProcessing)
	
	CurrentRow = Items.GroupingByRows.CurrentData;
	
	Item.ChoiceList.Clear();
	
	If CurrentRow.Field = "Departments" OR CurrentRow.Field = "Project" Then
		Item.ChoiceList.Add("Without groups", NStr("en='Without groups';ru='Без групп'"));
		Item.ChoiceList.Add("With groups", NStr("en='With groups';ru='C группами'"));
	Else
		Item.ChoiceList.Add("Without groups", NStr("en='Without groups';ru='Без групп'"));
	EndIf;

EndProcedure //ГруппировкаПоСтрокамТипГруппировкиНачалоВыбора()

&AtClient
//Обработчик события при изменении флага использования ТЧ Группировка по строкам
//
Procedure GroupingByRowsUseOnChange(Item)
	
	//Невозможен выбор одинаковых сущностей по строкам и колонкам
	CurrentRow = Items.GroupingByRows.CurrentData;
	ChangedField = CurrentRow.Field;
	
	If CurrentRow.Use Then
		Filter = New Structure;
		Filter.Insert("Field", ChangedField);
		FoundRows = Report.GroupingByColumns.FindRows(Filter);
		For Each String In FoundRows Do
			String.Use = False;
		EndDo;
	EndIf;
	
EndProcedure //ГруппировкаПоСтрокамИспользованиеПриИзменении()

&AtClient
// Процедура обработчик команды "ГруппировкаПоСтрокамСнятьФлажки" 
//
Procedure GroupingByRowsResetFlags(Command)
	
	For Each TableRow In Report.GroupingByRows Do
		TableRow.Use = False;
	EndDo;
	
	fmReportsClientServer.SetState(ThisForm);
	
EndProcedure

&AtClient
// Процедура обработчик команды "ГруппировкаПоСтрокамУстановитьФлажки" 
//
Procedure GroupingByRowsSetFlags(Command)
	
	For Each TableRow In Report.GroupingByRows Do
		TableRow.Use = True;
	EndDo;
	
	fmReportsClientServer.SetState(ThisForm);
	
EndProcedure

&AtClient
//Обработчик события при изменении ТЧ Группировка по колонкам
//
Procedure GroupingByColumnsOnChange(Item)
	
	fmReportsClientServer.SetState(ThisForm);
	
EndProcedure //ГруппировкаПоКолонкамПриИзменении()

&AtClient
//Обработчик события перед началом добавления ТЧ Группировка по колонкам
//
Procedure GroupingByColumnsBeforeAdd(Item, Cancel, Copy, Parent, Group)
	
	fmReportsClient.GroupingByColumnsBeforeAdd(ThisForm, Item, Cancel, Copy, Parent, Group);
	
EndProcedure //ГруппировкаПоКолонкамПередНачаломДобавления()

&AtClient
//Обработчик события перед началом изменения ТЧ Группировка по колонкам
//
Procedure GroupingByColumnsBeforeChange(Item, Cancel)
	
	fmReportsClient.GroupingByColumnsBeforeChange(ThisForm, Item, Cancel);
	
EndProcedure //ГруппировкаПоКолонкамПередНачаломИзменения()

&AtClient
//Обработчик события начала выбора типа группировки ТЧ Группировка по колонкам
//
Procedure GroupingByColumnsGroupTypeStartChoice(Item, ChoiceData, StandardProcessing)
	
	CurrentRow = Items.GroupingByColumns.CurrentData;
	
	Item.ChoiceList.Clear();
		
	If CurrentRow.Field = "Departments" OR CurrentRow.Field = "Project" Then
		Item.ChoiceList.Add("Without groups");
		Item.ChoiceList.Add("With groups");
	Else
		Item.ChoiceList.Add("Without groups");
	EndIf;

EndProcedure //ГруппировкаПоКолонкамТипГруппировкиНачалоВыбора()

&AtClient
//Обработчик события флага использования ТЧ Группировка по колонкам
//
Procedure GroupingByColumnsUseOnChange(Item)
	
	//Невозможен выбор одинаковых сущностей по строкам и колонкам
	CurrentRow = Items.GroupingByColumns.CurrentData;
	ChangedField = CurrentRow.Field;
	
	If CurrentRow.Use Then
		Filter = New Structure;
		Filter.Insert("Field", ChangedField);
		FoundRows = Report.GroupingByRows.FindRows(Filter);
		For Each String In FoundRows Do
			String.Use = False;
		EndDo;
	EndIf;
	
EndProcedure //ГруппировкаПоКолонкамИспользованиеПриИзменении()

&AtClient
// Процедура обработчик команды "ГруппировкаПоКолонкамСнятьФлажки" 
//
Procedure GroupingByColumnsResetFlags(Command)
	
	For Each TableRow In Report.GroupingByColumns Do
		TableRow.Use = False;
	EndDo;
	
	fmReportsClientServer.SetState(ThisForm);
	
EndProcedure

&AtClient
// Процедура обработчик команды "ГруппировкаПоКолонкамУстановитьФлажки" 
//
Procedure GroupingByColumnsSetFlags(Command)
	
	For Each TableRow In Report.GroupingByColumns Do
		TableRow.Use = True;
	EndDo;
	
	fmReportsClientServer.SetState(ThisForm);
	
EndProcedure


////////////////////////////////////////////////////////////////////////////////
// ПРОЦЕДУРЫ - ОБРАБОТЧИКИ СОБЫТИЙ, СВЯЗАННЫХ С РАСШИФРОВКОЙ

&AtServer
//Функция возвращает массив полей, связанных с расшифровкой, это могут быть БалансоваяЕдиница, Подразделения, Статья затрат, Период и ресурсы(в качестве ресурсов выступают
//формульные элементы справочника "Структура финансового отчета" для режима шахматки по структуре) и фиксированные разделы "Доходы", "Расходы", "Прочие доходы",
//"Прочие расходы", "Прибыль" для стандартной шахматки и Сводной таблицы
//
Function GetFieldsType(Details, DetailsData)
	
	ObjectData = New Structure;
	ObjectData.Insert("DetailsData", GetFromTempStorage(DetailsData));
	
	DataCompositionDetailsFieldsValuesArray = fmReportsServerCall.GetDetailsFieldsArray(Details, ObjectData.DetailsData, , False);
	
	FieldsArray = New Array;
	For Each Item In DataCompositionDetailsFieldsValuesArray Do
		If TypeOf(Item) = Type("DataCompositionDetailsFieldValue") Then
			FieldsStructure = New Structure;
			FieldsStructure.Insert("Field", Item.Field);
			FieldsStructure.Insert("Value", Item.Value);
			FieldsArray.Add(FieldsStructure);
		EndIf;
	EndDo;
	
	Return FieldsArray;

EndFunction //ПолучитьМассивПолей()

&AtClient
//Обработчик события обработки расшифровки табличного поля Результат
//
Procedure DetailsProcessingResult(Item, Details, StandardProcessing)

	Var SelectedAction, ActionParameter;
	
	//Запретим стандартную обработку расшифровки
	StandardProcessing = False;
	
	FieldsArray = GetFieldsType(Details,DetailsData);
	
	SectionField = Undefined;
	DetailsPeriod = Undefined;
	DetailsBalanceUnit = Undefined;
	DetailsDepartment = Undefined;
	DetailsItem = Undefined;
	
	For Each Item In FieldsArray Do
		
		If Item.Field = "Section" Then
			Return;
		EndIf;
		ShowValue( , Item.Value);
		Break;
	EndDo;
	
EndProcedure //РезультатОбработкаРасшифровки()

/////////////////////////////////////////////////////////////////////////////////
// ПРОЦЕДУРЫ - ОБРАБОТЧИКИ СОБЫТИЙ ПОЛЯ ТАБЛИЧНОГО ДОКУМЕНТА

&AtClient
Procedure ResultOnActivateArea(Item)
	
	If TypeOf(Result.SelectedAreas) = Type("SpreadsheetDocumentSelectedAreas") Then
		WaitingInterval = ?(GetClientConnectionSpeed() = ClientConnectionSpeed.Low, 1, 0.2);
		AttachIdleHandler("Attached_ResultOnActivateAreaAttached", WaitingInterval, True);
	EndIf;
	
EndProcedure

&AtClient
Procedure Attached_OpenExternalReportForm()
	
	FormParameters = GenerateFormParameters();
	OpenForm("ExternalReport."+ExternalReportName+".Form",FormParameters,,"ExternalReportUniqueKey", Window);

EndProcedure

&AtClient
Function GenerateFormParameters()
	
	FormParameters = New Structure;
	FormParameters.Insert("ExternalReportName", ExternalReportName);
	
	Return FormParameters;
	
EndFunction

&AtClient
Procedure PeriodTypeChoiceProcessing(Item, ChosenValue, StandardProcessing)
	Report.PeriodType = ChosenValue;
EndProcedure

&AtClient
Procedure DefaultSettings(Command)
	
	ThisForm.CurrentVariantKey	= "";
	SetDefaultSettingsAtServer();
	FormManagement(ThisForm);
	
EndProcedure

&AtServer
Procedure SetDefaultSettingsAtServer()
	
	ThisForm.ReportVariantDescription	= "";
	
	ReportObject = FormAttributeToValue("Report");
	Report.PresentationBalanceUnitDep = "Description";
	Report.OutputTotals = True;
	_CurrentDate = CurrentDate();
	Report.BeginOfPeriod1= BegOfMonth(_CurrentDate);
	Report.BeginOfPeriod = Report.BeginOfPeriod1;
	Report.BeginOfPeriod2= BegOfMonth(_CurrentDate);
	Report.EndOfPeriod1	= EndOfMonth(_CurrentDate);
	Report.EndOfPeriod	= Report.EndOfPeriod1;
	Report.EndOfPeriod2	= EndOfMonth(_CurrentDate);
	
	RefreshTitleText(ThisForm, ReportVariantDescription);
	
	//Заполним на форме значения реквизитов "Функциональная валюта учета" и "Валюта бюджетирования"
	ConstantValueFunctionalAccountingCurrency = Constants.fmCurrencyOfManAccounting.Get();
	FunctionalAccountingCurrency = "<" + ConstantValueFunctionalAccountingCurrency + ">";
	
	Report.StructureType = Enums.fmInfoStructureTypes.IncomesAndExpensesBudget;	
	
	If ValueIsFilled(Report.InfoStructure) Then
		Report.StructureType = Report.InfoStructure.StructureType;
	EndIf;	
	Report.ConsiderInternalSettlements = False;
	
	// Заполнение ТЧ По умолчанию
	Report.ComparedData.Clear();
	
	NewCompData = Report.ComparedData.Add();
	NewCompData.PlanningScenario = Catalogs.fmBudgetingScenarios.Plan;
	NewCompData.BeginOfPeriod = Report.BeginOfPeriod1;
	NewCompData.EndOfPeriod = Report.EndOfPeriod1;
	If ThisForm.BudgetVersioning = Enums.fmBudgetVersioning.EveryDay Then
		NewCompData.VersionPeriod = CurrentDate();
	ElsIf ThisForm.BudgetVersioning = Enums.fmBudgetVersioning.EveryMonth Then
		NewCompData.VersionPeriod = BegOfMonth(CurrentDate());
	EndIf;
	
	NewCompData = Report.ComparedData.Add();
	NewCompData.PlanningScenario = Catalogs.fmBudgetingScenarios.Actual;
	NewCompData.BeginOfPeriod = Report.BeginOfPeriod2;
	NewCompData.EndOfPeriod = Report.EndOfPeriod2;
	If ThisForm.BudgetVersioning = Enums.fmBudgetVersioning.EveryDay Then
		NewCompData.VersionPeriod = CurrentDate();
	ElsIf ThisForm.BudgetVersioning = Enums.fmBudgetVersioning.EveryMonth Then
		NewCompData.VersionPeriod = BegOfMonth(CurrentDate());
	EndIf;
	
	Report.BeginOfPeriod1 = Undefined;
	Report.BeginOfPeriod2 = Undefined;
	Report.EndOfPeriod1 = Undefined;
	Report.EndOfPeriod2 = Undefined;
	
	FillGroups(True);
	
	Report.Indicators.Clear();
	
	NewIndicator = Report.Indicators.Add();
	NewIndicator.Indicator    = "AmountMan";
	NewIndicator.Presentation = NStr("en='Amount in management accounting currency';ru='Сумма в валюте упр. учета'");
	NewIndicator.Use = True;
	
	NewIndicator = Report.Indicators.Add();
	NewIndicator.Indicator    = "CurrencyAmount";
	NewIndicator.Presentation = NStr("en='Amount in operation currency';ru='Сумма в валюте операции'");
	NewIndicator.Use = False;
	
	ViewFormat();
	
EndProcedure

&AtClient
Procedure ComparedDataVersionPeriodOnChange(Item)
	
	CurData = Items.ComparedData.CurrentData;
	If NOT CurData = Undefined Then
		CurColumnName = StrReplace(Item.Name,Item.Parent.Name,"");
		If IsBlankString(CurData[CurColumnName]) Then
			If CurColumnName =		"Version" Then
				CurData.VersionPeriod =	Undefined;
			ElsIf CurColumnName =	"Period" Then
				CurData.BeginOfPeriod =	Undefined;
				CurData.EndOfPeriod =	Undefined;
			EndIf;
		EndIf;
	EndIf;
	fmReportsClientServer.SetState(ThisForm);
	
EndProcedure

&AtClient
Procedure ComparedDataVersionStartChoice(Item, ChoiceData, StandardProcessing)
	
	NotifyDescription = New NotifyDescription("VersionPeriodPresentationStartChoiceEnd", ThisObject);
	If ThisForm.BudgetVersioning = PredefinedValue("Enum.fmBudgetVersioning.EveryDay") Then
		FormParameters = New Structure("BeginOfPeriod, EndOfPeriod", Items.ComparedData.CurrentData.VersionPeriod, Items.ComparedData.CurrentData.VersionPeriod);
	
		OpenForm("CommonForm.StandardPeriodChoiceDay", FormParameters, ThisObject,,,, NotifyDescription);
	ElsIf ThisForm.BudgetVersioning = PredefinedValue("Enum.fmBudgetVersioning.EveryMonth") Then
		fmPeriodChoiceClient.PeriodStartChoice(
		ThisObject, 
		Item, 
		StandardProcessing, 
		PredefinedValue("Enum.fmAvailableReportPeriods.Month"), 
		Items.ComparedData.CurrentData.VersionPeriod, 
		NotifyDescription);
	EndIf;
	fmReportsClientServer.SetState(ThisForm);
	
EndProcedure

&AtClient
Procedure VersionPeriodPresentationStartChoiceEnd(PeriodStructure, AdditionalParameters) Export
	
	// Установим полученный период
	If PeriodStructure <> Undefined Then
		If ThisForm.BudgetVersioning = PredefinedValue("Enum.fmBudgetVersioning.EveryDay") Then
			VersionFormat = "L=en; DF='dd MMMM yyyy ''y.'''";
		Else
			VersionFormat = "L=en; DF='MMMM yyyy'";
		EndIf;
		Items.ComparedData.CurrentData.Version = Format(PeriodStructure.BeginOfPeriod,VersionFormat);
		Items.ComparedData.CurrentData.VersionPeriod = BegOfDay(PeriodStructure.BeginOfPeriod);
	EndIf;
	
	Modified = True;
	
EndProcedure

&AtClient
Procedure ComparedDataPeriodStartChoice(Item, ChoiceData, StandardProcessing)
	
	If ThisForm.PeriodType = ThisForm.AvailableReportPeriods.ArbitraryPeriod Then
		PeriodSettingDialog = New StandardPeriodEditDialog();
		PeriodSettingDialog.Period.StartDate = Items.ComparedData.CurrentData.BeginOfPeriod;
		PeriodSettingDialog.Period.EndDate = Items.ComparedData.CurrentData.EndOfPeriod;
		PeriodSettingDialog.Show(New NotifyDescription("ArbitraryPeriodChoiceEnd", ThisObject, New Structure("PeriodSettingDialog", PeriodSettingDialog)));
	Else
		NotifyDescription = New NotifyDescription("PeriodPresentationStartChoiceEnd", ThisObject);
		fmPeriodChoiceClient.PeriodStartChoice(
		ThisObject, 
		Item, 
		StandardProcessing, 
		PeriodType, 
		Items.ComparedData.CurrentData.BeginOfPeriod, 
		NotifyDescription);
	EndIf;
	fmReportsClientServer.SetState(ThisForm);
	
EndProcedure


&AtClient
Procedure ArbitraryPeriodChoiceEnd(Period, AdditionalParameters) Export
	
	PeriodSettingDialog = AdditionalParameters.PeriodSettingDialog;
	If Period <> Undefined Then 
		Items.ComparedData.CurrentData.Period = fmReportsClientServer.GetReportPeroidRepresentation(ThisForm.PeriodType, 
			BegOfDay(PeriodSettingDialog.Period.StartDate), EndOfDay(PeriodSettingDialog.Period.EndDate), ThisForm);
		Items.ComparedData.CurrentData.BeginOfPeriod = PeriodSettingDialog.Period.StartDate;
		Items.ComparedData.CurrentData.EndOfPeriod  = PeriodSettingDialog.Period.EndDate;
	EndIf;
	
EndProcedure

&AtClient
Procedure PeriodPresentationStartChoiceEnd(PeriodStructure, AdditionalParameters) Export
	
	// Установим полученный период
	If PeriodStructure <> Undefined Then
		Items.ComparedData.CurrentData.Period = fmReportsClientServer.GetReportPeroidRepresentation(ThisForm.PeriodType, 
			BegOfDay(PeriodStructure.BeginOfPeriod), EndOfDay(PeriodStructure.EndOfPeriod), ThisForm);
		//Элементы.СравниваемыеДанные.ТекущиеДанные.Период = СтруктураПериода.Период;
		Items.ComparedData.CurrentData.BeginOfPeriod = BegOfDay(PeriodStructure.BeginOfPeriod);
		Items.ComparedData.CurrentData.EndOfPeriod = EndOfDay(PeriodStructure.EndOfPeriod);
	
	EndIf;
	
	Modified = True;
	
EndProcedure


&AtClient
Procedure ComparedDataPlanningScenarioOnChange(Item)
	CurData = Items.ComparedData.CurrentData;
	If NOT CurData = Undefined Then
		If ValueIsFilled(CurData.PlanningScenario) Then
			If ThisForm.BudgetVersioning = PredefinedValue("Enum.fmBudgetVersioning.EveryDay") Then
				CurData.VersionPeriod = CurrentDate();
				CurData.Version		= Format(CurData.VersionPeriod,"L=en; DF='dd MMMM yyyy ''y.'''");
			ElsIf ThisForm.BudgetVersioning = PredefinedValue("Enum.fmBudgetVersioning.EveryMonth") Then
				CurData.VersionPeriod = BegOfMonth(CurrentDate());
				CurData.Version		= Format(CurData.VersionPeriod,"L=en; DF='MMMM yyyy'");
			EndIf;
			
			CurData.BeginOfPeriod =	fmReportsClientServer.ReportBegOfPeriod(PeriodType, BegOfMonth(CurrentDate()), ThisForm);
			CurData.EndOfPeriod  =	fmReportsClientServer.ReportEndOfPeriod(PeriodType, CurData.BeginOfPeriod, ThisForm);
			CurData.Period        =	fmReportsClientServer.GetReportPeroidRepresentation(PeriodType, CurData.BeginOfPeriod, CurData.EndOfPeriod, ThisForm);
			ScenarioType = GetScenarioType(CurData.PlanningScenario);
			CurData.VersionAvailability = ?(ScenarioType = PredefinedValue("Enum.fmBudgetingScenarioTypes.Fact"),False,True);
		EndIf;
	EndIf;
EndProcedure

&AtServerNoContext
Function GetScenarioType(VAL Scenario)
	
	Return Common.ObjectAttributeValue(Scenario, "ScenarioType");
	
EndFunction

&AtClient
Procedure DeviationsOnChange(Item)
	fmReportsClientServer.SetState(ThisForm);
EndProcedure

&AtClient
// Процедура обработчик команды "ОтклоненияСнятьФлажки" 
//
Procedure DeviationsResetFlags(Command)
	
	For Each TableRow In Report.Deviations Do
		TableRow.Use = False;
	EndDo;
	
	fmReportsClientServer.SetState(ThisForm);
	
EndProcedure

&AtClient
// Процедура обработчик команды "ОтклоненияУстановитьФлажки" 
//
Procedure DeviationsSetFlags(Command)
	
	For Each TableRow In Report.Deviations Do
		TableRow.Use = True;
	EndDo;
	
	fmReportsClientServer.SetState(ThisForm);
	
EndProcedure

&AtClient
Procedure ComparedDataOnChange(Item)
	Items.Deviations.Enabled = (Report.ComparedData.Count()>1);
EndProcedure

&AtClient
Procedure ConsiderBudgetsNotInAgreementOnChange(Item)
	fmReportsClientServer.SetState(ThisForm);
EndProcedure

//&НаСервере
Procedure ChangeSettings()
	ThisReport = FormAttributeToValue("Report");
	FilterTemplate = ThisReport.GetTemplate("TemplateStructurePresentationClassic");
	If Report.StructureType=Enums.fmInfoStructureTypes.CashflowBudget Then
		FilterTemplate.DataSets.DataSet1.Fields[6].ValueType = New TypeDescription("CatalogRef.fmCashflowItems");
	Else
		FilterTemplate.DataSets.DataSet1.Fields[6].ValueType = New TypeDescription("CatalogRef.fmIncomesAndExpensesItems");
	EndIf;
	SettingsAddress = PutToTempStorage(FilterTemplate, UUID);
	Report.SettingsComposer.Initialize(New DataCompositionAvailableSettingsSource(SettingsAddress));
	Report.SettingsComposer.Settings.Filter.Items.Clear();
	Report.InfoStructure = Catalogs.fmInfoStructures.EmptyRef();
EndProcedure

&AtClient
Procedure StructureTypeOnChange(Item)
	ChangeSettings();
EndProcedure

&AtClient
// Процедура обработчик команды "ПоказателиСнятьФлажки" 
//
Procedure IndicatorsResetFlags(Command)
	
	For Each TableRow In Report.Indicators Do
		TableRow.Use = False;
	EndDo;
	
	fmReportsClientServer.SetState(ThisForm);
	
EndProcedure

&AtClient
// Процедура обработчик команды "ПоказателиУстановитьФлажки" 
//
Procedure IndicatorsSetFlags(Command)
	
	For Each TableRow In Report.Indicators Do
		TableRow.Use = True;
	EndDo;
	
	fmReportsClientServer.SetState(ThisForm);
	
EndProcedure

&AtClient
Procedure FilterRightValueStartChoice(Item, ChoiceData, StandardProcessing)
	
	FilterItem = Report.SettingsComposer.Settings.Filter.GetObjectByID(Items.Filters.CurrentRow);
	Field               = Items.Filters.CurrentData.LeftValue;
	
	FiledType = fmReportsClientServer.GetFieldProperty(
		Report.SettingsComposer.Settings.Filter.FilterAvailableFields,
		Field,
		"Type");
		
EndProcedure

&AtClient
// Функция обработчик "ПолучитьПараметрыВыбораЗначенияОтбора" 
//
Function GetFilterValueChoiceParameters()
	
	ParametersList = New Structure;
	For Each FilterItem In Report.SettingsComposer.Settings.Filter.Items Do
		If TypeOf(FilterItem) = Type("DataCompositionFilterItem") AND FilterItem.Use Then
			If FilterItem.LeftValue = New DataCompositionField("Item")
				AND FilterItem.ComparisonType = DataCompositionComparisonType.Equal Then
				ParametersList.Insert("Item", FilterItem.RightValue);
			EndIf;
		EndIf;
	EndDo;
	Return ParametersList;
	
EndFunction

&AtServer
Procedure ViewFormat()
	Report.ViewFormat = "";
	If ValueIsFilled(Report.InfoStructure) Then
		If ValueIsFilled(Report.InfoStructure.ViewFormat) Then
			Report.ViewFormat = Report.InfoStructure.ViewFormat;
		EndIf;	
	EndIf;
	If NOT ValueIsFilled(Report.ViewFormat) Then	
		Report.ViewFormat = Constants.fmViewFormat.Get();
		If NOT ValueIsFilled(Report.ViewFormat) Then
			Report.ViewFormat = Enums.fmRoundMethods.WithoutRound;
		EndIf;
	EndIf;
EndProcedure

&AtClient
Procedure InfoStructureOnChange()
	ViewFormat();	
EndProcedure	






