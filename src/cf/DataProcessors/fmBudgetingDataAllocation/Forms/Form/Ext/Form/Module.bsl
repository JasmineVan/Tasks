
////////////////////////////////////////////////////////////////////////////////
// ПРОЦЕДУРЫ И ФУНКЦИИ ОБЩЕГО НАЗНАЧЕНИЯ

&AtServer
Procedure DistributeServer()
	
	If NOT CheckFilling() Then 
		Return;
	EndIf;
	
	ThisDataProcessor = FormAttributeToValue("Object");
	ThisDataProcessor.DistributeIncomesAndExpenses();
	ValueToFormAttribute(ThisDataProcessor, "Object");
	
EndProcedure // Распределить()

&AtServer
Procedure CallFillByScenario()
	Object.BudgetsDistributionSteps.Load(TemporaryModule.CallFillByScenario(Object.DistributionScenario));
	Items.StepsChoice.Enabled = NOT Object.BudgetsDistributionSteps.Count() = 0;
EndProcedure

//Процедура, устанавливающая флажки "Активность" ТЧ ШагиРаспределенияБюджетов в Истина
//
&AtClient
Procedure SetFlags()
	For Each Item In Object.BudgetsDistributionSteps Do
		Item.Active = True;
	EndDo;
EndProcedure // УстановитьФлажки()

//Процедура, устанавливающая флажки "Активность" ТЧ ШагиРаспределенияБюджетов в Ложь
//
&AtClient
Procedure ResetFlags()
	For Each Item In Object.BudgetsDistributionSteps Do
		Item.Active = False;
	EndDo;
EndProcedure //СнятьФлажкиНаСервере()

//Функция, возвращающая порядок шага закрытия, на котором установлен пользовательский курсор (текущая строка)
//
&AtServer
Function GetCurrentRowStep(BudgetDistributionStep)
	Return BudgetDistributionStep.Order;
EndFunction //ПолучитьШагТекущейСтроки()

//Процедура, устанавливающая активность шагов в Истина для шагов из выбранного диапазона
//
&AtServer
Procedure SetSelectedFlagsAtServer(BeginStep, EndStep)
	
	// Сначала все флажки сбросим в Ложь
	For Each Item In Object.BudgetsDistributionSteps Do
		Item.Active = False;
	EndDo;
	
	//Затем установим флаг в Истина те шаги закрытия, для которых порядок входит в выбранный нами диапазон
	For Counter = BeginStep To EndStep Do
		For Each Item In Object.BudgetsDistributionSteps Do
			If Counter = Item.BudgetDistributionStep.Order Then
				Item.Active = True;
			EndIf;
		EndDo;
	EndDo;
	
EndProcedure //УстановитьВыбранныеФлажкиНаСервере()


////////////////////////////////////////////////////////////////////////////////
// КОМАНДЫ ФОРМЫ

&AtClient
Procedure Distribute(Command)
	DistributeServer();
EndProcedure

&AtClient
Procedure CancelDistribution(Command)
	ShowQueryBox(New NotifyDescription("CancelDistributionEnd", ThisForm), NStr("en='Are you sure you want to cancel the allocation?';ru='Отменить распределение?'"), QuestionDialogMode.YesNo);
EndProcedure

&AtClient
Procedure CancelDistributionEnd(Result, Parameters) Export
	If Result = DialogReturnCode.No Then
		Return;
	EndIf;
	CancelDistributionServer();
EndProcedure

// <Описание процедуры>
//
&AtServer
Procedure CancelDistributionServer()

	If NOT CheckFilling() Then 
		Return;
	EndIf;
	
	ThisDataProcessor = FormAttributeToValue("Object");
	ThisDataProcessor.CancelDistribution();
	ValueToFormAttribute(ThisDataProcessor, "Object");
	
EndProcedure // ОтменитьРаспределениеСервер()

//Обработчик события нажатия на кнопку "Установить флажки"
//
&AtClient
Procedure CommandSetFlags(Command)
	SetFlags();
EndProcedure // КомандаУстановитьФлажки()

//Обработчик события нажатия на кнопку "Снять флажки"
//
&AtClient
Procedure CommandResetFlags(Command)
	ResetFlags();
EndProcedure // КомандаСнятьФлажки()

&AtClient
Procedure RereadSteps(Command)
	
	If ValueIsFilled(Object.DistributionScenario) Then
		If Object.BudgetsDistributionSteps.Count() > 0 Then
			ShowQueryBox(New NotifyDescription("RereadStepsEnd", ThisForm), NStr("en='The tabular section will be cleared before filling. Do you want to continue?';ru='Перед заполнением табличная часть будет очищена. Заполнить?'"), QuestionDialogMode.YesNo, , DialogReturnCode.Yes);
		Else
			CallFillByScenario();
			Items.StepsChoice.Enabled = NOT Object.BudgetsDistributionSteps.Count()=0;
		EndIf;
	Else
		CommonClientServer.MessageToUser(NStr("en='Before filling the tabular section, you need to select an ""Allocation scenario"".';ru='Перед заполнением табличной части необходимо выбрать ""Сценарий распределения""!'"));
	EndIf;
	
EndProcedure

&AtClient
Procedure RereadStepsEnd(Result, Parameters) Export
	
	If Result = DialogReturnCode.No Then
		Return;
	EndIf;
	CallFillByScenario();
	Items.StepsChoice.Enabled = NOT Object.BudgetsDistributionSteps.Count()=0;
	
EndProcedure

//Обработчик события нажатия на кнопку "Выбрать шаги для закрытия" командной панели ТЧ ШагиАлгоритмаРасчета
//
&AtClient
Procedure ChooseSteps(Command)
	
	CurrentRowStep = 0;
	CurrentRow = Items.BudgetsDistributionSteps.CurrentData;
	If CurrentRow <> Undefined Then
		CurrentRowStep = GetCurrentRowStep(CurrentRow.BudgetDistributionStep);
	EndIf;
	
	AddParameters = New Structure("CurrentRowStep", CurrentRowStep);
	OpenForm("DataProcessor.fmBudgetingDataAllocation.Form.StepsForm", AddParameters, ThisForm, , , , New NotifyDescription("ChooseStepsEnd", ThisForm), FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure //ВыбратьШагиДляЗакрытия()

&AtClient
Procedure ChooseStepsEnd(Result, Parameters) Export
	If TypeOf(Result)=Type("Structure") Then
		SetSelectedFlagsAtServer(Result.BeginStep, Result.EndStep);
	EndIf;
EndProcedure


////////////////////////////////////////////////////////////////////////////////
// ПРОЦЕДУРЫ - ОБРАБОТЧИКИ СОБЫТИЙ ФОРМЫ

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	AvailableReportPeriods = fmReportsServerCall.GetAvailableReportPeriods();
	
	// Значения по-умолчанию.
	PeriodType = Items.PeriodType.ChoiceList[0].Value;
	Object.BeginOfPeriod = BegOfMonth(BegOfMonth(CurrentSessionDate())-1);
	Object.EndOfPeriod = EndOfMonth(Object.BeginOfPeriod);
	Object.BalanceUnit = fmCommonUseServer.GetDefaultValue("MainBalanceUnit");
	Object.BudgetingScenario = fmCommonUseServer.GetDefaultValue("MainScenario");
	BalanceUnitPeriodOnChangeServer();
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	PeriodTypeChangeProcessing(ThisForm, Object.BeginOfPeriod, Object.EndOfPeriod);
EndProcedure


////////////////////////////////////////////////////////////////////////////////
// ПРОЦЕДУРЫ - ОБРАБОТЧИКИ СОБЫТИЙ ЭЛЕМЕНТОВ ФОРМЫ

&AtClient
Procedure BalanceUnitOnChange(Item)
	BalanceUnitPeriodOnChangeServer();
EndProcedure

&AtServer
Procedure BalanceUnitPeriodOnChangeServer()
	If ValueIsFilled(Object.BalanceUnit) Then
		DefaultDistributionScenario = DefaultDistributionScenario(Object.BeginOfPeriod, Object.BalanceUnit);
		If ValueIsFilled(DefaultDistributionScenario) AND NOT Object.DistributionScenario=DefaultDistributionScenario Then
			Object.DistributionScenario = DefaultDistributionScenario;
			CallFillByScenario();
		EndIf;
	EndIf;
EndProcedure

&AtClient
Procedure DistributionScenarioOnChange(Item)
	CallFillByScenario();
EndProcedure

&AtServerNoContext
Function DefaultDistributionScenario(BeginOfPeriod, BalanceUnit)
	
	Query = New Query("SELECT ALLOWED
	                      |	fmDistributionScenariosBindingToBalanceUnitsSliceLast.DistributionScenario AS DistributionScenario
	                      |FROM
	                      |	InformationRegister.fmDistributionScenariosBinding.SliceLast(&Period, BalanceUnit = &BalanceUnit) AS fmDistributionScenariosBindingToBalanceUnitsSliceLast
	                      |
	                      |UNION ALL
	                      |
	                      |SELECT
	                      |	fmDistributionScenariosBindingToBalanceUnitsSliceLast.DistributionScenario
	                      |FROM
	                      |	InformationRegister.fmDistributionScenariosBinding.SliceLast(&Period, BalanceUnit = Value(Catalog.fmBalanceUnits.EmptyRef)) AS fmDistributionScenariosBindingToBalanceUnitsSliceLast");
	Query.SetParameter("Period", BeginOfPeriod);
	Query.SetParameter("BalanceUnit", BalanceUnit);
	Result = Query.Execute().SELECT();
	If Result.Next() Then
		Return Result.DistributionScenario;
	Else
		Return Catalogs.fmBudgetDistributionScenarios.EmptyRef();
	EndIf;
	
EndFunction

&AtClient
Procedure PeriodTypeOnChange(Item)
	PeriodTypeChangeProcessing(ThisForm, Object.BeginOfPeriod, Object.EndOfPeriod);
EndProcedure

&AtClient
Procedure PeriodTypeChangeProcessing(Form, BeginOfPeriod, EndOfPeriod) Export
	
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
		Form.Period = ListItem.Presentation;
	EndIf;
	
EndProcedure

&AtClient
Procedure PeriodTypeChoiceProcessing(Item, ChosenValue, StandardProcessing)
	PeriodType = ChosenValue;
EndProcedure

&AtClient
Procedure PeriodStartChoice(Item, ChoiceData, StandardProcessing)
	NotifyDescription = New NotifyDescription("PeriodPresentationStartChoiceEnd", ThisObject);
	fmPeriodChoiceClient.PeriodStartChoice(
	ThisObject, 
	Item, 
	StandardProcessing, 
	PeriodType, 
	Object.BeginOfPeriod, 
	NotifyDescription);
EndProcedure

&AtClient
Procedure PeriodPresentationStartChoiceEnd(PeriodStructure, AdditionalParameters) Export
	// Установим полученный период
	If PeriodStructure <> Undefined Then
		Period = fmReportsClientServer.GetReportPeroidRepresentation(PeriodType, 
			BegOfDay(PeriodStructure.BeginOfPeriod), EndOfDay(PeriodStructure.EndOfPeriod), ThisForm);
		Object.BeginOfPeriod = BegOfDay(PeriodStructure.BeginOfPeriod);
		Object.EndOfPeriod = EndOfDay(PeriodStructure.EndOfPeriod);
	EndIf;
EndProcedure

&AtClient
Procedure BudgetsDistributionStepsBudgetDistributionStepStartChoice(Item, ChoiceData, StandardProcessing)
	StandardProcessing=False;
EndProcedure




