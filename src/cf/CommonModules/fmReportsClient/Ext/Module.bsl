
#Region DataCompositionSchemaProcessing

Procedure AddResourceFiledsDeniedFields(Form, FileldList) Export
	
	For Each IndicatorName In Form.IndicatorSet Do
		If Form.Report["Indicator" + IndicatorName] Then 
			If IndicatorName = "Control" Then
				Continue;
			EndIf;
			BalanceType = "";
			If Form.Report.Property("ExtendedBalance") Then
				If TypeOf(Form.Report.ExtendedBalance) = Type("Boolean") Then
					If Form.Report.ExtendedBalance Then
						BalanceType = "";
					Else
						BalanceType = "Extended";
					EndIf;
				EndIf;
			EndIf;
			FileldList.Add("BalanceBegOfPeriod." + IndicatorName + "Opening" + BalanceType + "BalanceDr");
			FileldList.Add("BalanceBegOfPeriod." + IndicatorName + "Opening" + BalanceType + "BalanceCr");
			FileldList.Add("BalanceEndOfPeriod." + IndicatorName + "Closing" + BalanceType + "BalanceDr");
			FileldList.Add("BalanceEndOfPeriod." + IndicatorName + "Closing" + BalanceType + "BalanceCr");
		Else
			FileldList.Add("BalanceBegOfPeriod." + IndicatorName + "OpeningBalanceDr");
			FileldList.Add("BalanceBegOfPeriod." + IndicatorName + "OpeningBalanceCr");
			FileldList.Add("PeriodTurnovers." + IndicatorName + "DrTurnover");
			FileldList.Add("PeriodTurnovers." + IndicatorName + "CrTurnover");
			FileldList.Add("BalanceEndOfPeriod." + IndicatorName + "ClosingBalanceDr");
			FileldList.Add("BalanceEndOfPeriod." + IndicatorName + "ClosingBalanceCr");
			FileldList.Add("BalanceBegOfPeriod." + IndicatorName + "OpeningExtendedBalanceDr");
			FileldList.Add("BalanceBegOfPeriod." + IndicatorName + "OpeningExtendedBalanceCr");
			FileldList.Add("BalanceEndOfPeriod." + IndicatorName + "ClosingExtendedBalanceDr");
			FileldList.Add("BalanceEndOfPeriod." + IndicatorName + "ClosingExtendedBalanceCr");
		EndIf;
	EndDo;
		
EndProcedure

Procedure GroupingByRowsBeforeAdd(Form, Item, Cancel, Copy, Parent, Group) Export
	
	FormParameters = New Structure;
	FormParameters.Insert("DataCompositionSchema", Form.DataCompositionSchema);
	FormParameters.Insert("Mode"          , "Group");
	FormParameters.Insert("DeniedFields", Form.GetDeniedFields("Group"));
	FormParameters.Insert("CurrentRow"  , Undefined);
	SelectedFieldParameters = OpenFormModal("CommonForm.fmAvailableFieldChoiceForm", FormParameters);
	
	If TypeOf(SelectedFieldParameters) = Type("Structure") Then
		NewLine = Form.Report.GroupingByRows.Add();
		NewLine.Use = True;
		NewLine.Field          = SelectedFieldParameters.Field;
		NewLine.Presentation = SelectedFieldParameters.Title;
	EndIf;
	
	Cancel = True;
	
EndProcedure

Procedure GroupingByRowsBeforeChange(Form, Item, Cancel) Export
	
	If Item.CurrentItem = Form.Items.GroupingByRowsRepresentation Then
		FormParameters = New Structure;
		FormParameters.Insert("DataCompositionSchema", Form.DataCompositionSchema);
		FormParameters.Insert("Mode"          , "Group");
		FormParameters.Insert("DeniedFields", Form.GetDeniedFields("Group"));
		FormParameters.Insert("CurrentRow"  , Item.CurrentData.Field);
		SelectedFieldParameters = OpenFormModal("CommonForm.fmAvailableFieldChoiceForm", FormParameters);
		
		If TypeOf(SelectedFieldParameters) = Type("Structure") Then
			NewLine = Item.CurrentData;
			NewLine.Use = True;
			NewLine.Field          = SelectedFieldParameters.Field;
			NewLine.Presentation = SelectedFieldParameters.Title;
		EndIf;
		
		Cancel = True;
	EndIf;
	
EndProcedure

Procedure GroupingByColumnsBeforeAdd(Form, Item, Cancel, Copy, Parent, Group) Export
	
	FormParameters = New Structure;
	FormParameters.Insert("DataCompositionSchema", Form.DataCompositionSchema);
	FormParameters.Insert("Mode"          , "Group");
	FormParameters.Insert("DeniedFields", Form.GetDeniedFields("Group"));
	FormParameters.Insert("CurrentRow"  , Undefined);
	SelectedFieldParameters = OpenFormModal("CommonForm.fmAvailableFieldChoiceForm", FormParameters);
	
	If TypeOf(SelectedFieldParameters) = Type("Structure") Then
		NewLine = Form.Report.GroupingByColumns.Add();
		NewLine.Use = True;
		NewLine.Field          = SelectedFieldParameters.Field;
		NewLine.Presentation = SelectedFieldParameters.Title;
	EndIf;
	
	Cancel = True;
	
EndProcedure

Procedure GroupingByColumnsBeforeChange(Form, Item, Cancel) Export
	
	If Item.CurrentItem = Form.Items.GroupingByColumnsRepresentation Then
		FormParameters = New Structure;
		FormParameters.Insert("DataCompositionSchema", Form.DataCompositionSchema);
		FormParameters.Insert("Mode"          , "Group");
		FormParameters.Insert("DeniedFields", Form.GetDeniedFields("Group"));
		FormParameters.Insert("CurrentRow"  , Item.CurrentData.Field);
		SelectedFieldParameters = OpenFormModal("CommonForm.fmAvailableFieldChoiceForm", FormParameters);
		
		If TypeOf(SelectedFieldParameters) = Type("Structure") Then
			NewLine = Item.CurrentData;
			NewLine.Use = True;
			NewLine.Field          = SelectedFieldParameters.Field;
			NewLine.Presentation = SelectedFieldParameters.Title;
		EndIf;
		
		Cancel = True;
	EndIf;
	
EndProcedure

#EndRegion

#Region FunctionsForEvaluationOfAutoAmountsInStandardReports

Function NecessaryToUpdateAmount(Result, SelectedAreaCache)
	Var SelectedAreaAddressStructure;
	
	SelectedAreas    = Result.SelectedAreas;
	SelectedCount = SelectedAreas.Count();
	
	If SelectedCount = 0 Then
		SelectedAreaCache = New Structure();
		Return True;
	EndIf;
	
	ReturnValue = False;
	If TypeOf(SelectedAreaCache) <> Type("Structure") Then
		SelectedAreaCache = New Structure();
		ReturnValue = True;
	ElsIf SelectedAreas.Count() <> SelectedAreaCache.Count() Then
		SelectedAreaCache = New Structure();
		ReturnValue = True;
	Else
		For AreaIndex = 0 To SelectedCount - 1 Do
			SelectedArea = SelectedAreas[AreaIndex];
			AreaName = StrReplace(SelectedArea.Name, ":", "_");
			SelectedAreaCache.Property(AreaName, SelectedAreaAddressStructure);
			
			// не нашли нужную область в кэше, поэтому переинициализируем кэш
			If TypeOf(SelectedAreaAddressStructure) <> Type("Structure") Then
				SelectedAreaCache = New Structure();
				ReturnValue = True;
				Break;
			EndIf;
		EndDo;
	EndIf;
	
	For AreaIndex = 0 To SelectedCount - 1 Do
		SelectedArea = SelectedAreas[AreaIndex];
		
		// Если тек. область - рисунок, то пропускаем ее и переходим к следующей
		If TypeOf(SelectedArea) = Type("SpreadsheetDocumentDrawing") Then
			Continue;
		EndIf;
		
		AreaName = StrReplace(SelectedArea.Name, ":", "_");
		
		SelectedAreaCache.Property(AreaName, SelectedAreaAddressStructure);
		If TypeOf(SelectedAreaAddressStructure) <> Type("Structure") Then
			SelectedAreaAddressStructure = New Structure("Top, Bottom, Left, Right", 0, 0, 0, 0);
			SelectedAreaCache.Insert(AreaName, SelectedAreaAddressStructure);
			ReturnValue = True;
		EndIf;
		
		If SelectedAreaAddressStructure.Top <> SelectedArea.Top
			OR SelectedAreaAddressStructure.Bottom <> SelectedArea.Bottom
			OR SelectedAreaAddressStructure.Left <> SelectedArea.Left
			OR SelectedAreaAddressStructure.Right <> SelectedArea.Right Then
				SelectedAreaAddressStructure = New Structure("Top, Bottom, Left, Right",
					SelectedArea.Top, SelectedArea.Bottom, SelectedArea.Left, SelectedArea.Right);
				SelectedAreaCache.Insert(AreaName, SelectedAreaAddressStructure);
				ReturnValue = True;
		EndIf;
		
	EndDo;
	
	Return ReturnValue;
	
EndFunction

// Вычисляет суммы выделенных ячеек табличного документа.
//
// Параметры:
//	ПолеСумма - Число - Сумма ячеек.
//	Результат - ТабличныйДокумент - Табличный документ с ячейками.
//	КэшВыделеннойОбласти - Структура - Содержит ранее рассчитанные значения ячеек.
//	НеобходимоВычислятьНаСервере - Булево - Признак того, что необходим вызов сервера.
//
// Возвращаемое значение:
//  Булево - Признак того, что необходим вызов сервера (то же значение, что и НеобходимоВычислятьНаСервере).
//
Function EvalAmountOfSpreadsheetDocumentSelectedCells(AmountField, Result, SelectedAreaCache, NecessaryToCalculateAtServer = Undefined) Export
	
	NecessaryToCalculateAtServer = False;
	
	If NecessaryToUpdateAmount(Result, SelectedAreaCache) Then
		AmountField = 0;
		SelectedAreasCount = SelectedAreaCache.Count();
		If SelectedAreasCount = 0      // Ничего не выделено.
			OR SelectedAreaCache.Property("T") Then // Выделен весь табличный документ (Ctrl+A).
			SelectedAreaCache.Insert("Amount", 0);
		ElsIf SelectedAreasCount = 1 Then
			// Если выделено небольшое количество ячеек, то получим сумму на клиенте.
			For Each KeyAndValue In SelectedAreaCache Do
				SelectedAreaAddressStructure = KeyAndValue.Value;
			EndDo;
			
			VerticalAreaSize   = SelectedAreaAddressStructure.Bottom   - SelectedAreaAddressStructure.Top;
			HorizontalAreaSize = SelectedAreaAddressStructure.Right - SelectedAreaAddressStructure.Left;
			
			// В некоторых отчетах показатели (да и аналитика на которую может встать пользователь)
			// выводятся в "объединенных" ячейках - не желательно в этом случае делать серверный вызов.
			// Выделенная область из 10 ячеек закрывает все такие случае и скорее всего всегда будет доступна на клиенте.
			// Максимум, может быть сделан один неявный серверный вызов.
			EvalAtClient = (VerticalAreaSize + HorizontalAreaSize) < 12;
			If EvalAtClient Then
				AmountInCells = 0;
				fmReportsClientServer.EvalCellsAmount(AmountInCells, SelectedAreaAddressStructure, Result);
				AmountField = AmountInCells;
				SelectedAreaCache.Insert("Amount", AmountField);
			Else
				// Если ячеек много, то лучше вычислим сумму ячеек на сервере за один вызов,
				// т.к. неявных серверных вызовов может быть гораздо больше.
				NecessaryToCalculateAtServer = True;
			EndIf;
		Else
			// Вычислим сумму ячеек на сервере.
			NecessaryToCalculateAtServer = True;
		EndIf;
	Else	
		AmountField = SelectedAreaCache.Amount;
	EndIf;
	
	Return NecessaryToCalculateAtServer;
	
EndFunction



#EndRegion

#Region DetailsOfStandardReports

// Процедура обработчик "ТабличноеПолеПоСчетамПредставлениеОчистка" 
//
Procedure TableFieldByAccountsRepresentationClear(ReportForm, ItemName, Item, StandardProcessing) Export
		
	ReportForm.Items[ItemName].CurrentData.ByExtDimensions    = StrReplace(ReportForm.Items[ItemName].CurrentData.ByExtDimensions, "+", "-");
	ReportForm.Items[ItemName].CurrentData.Presentation = "";
	
EndProcedure

// Обрабатывается выбор из списка действий расшифровки,
// производится открытие формы отчета или объекта.
//
// Параметры:
//  Результат - ЭлементСпискаЗначений - Выбранный пункт действий расшифровки.
//  ДополнительныеПараметры	- Структура - Дополнительные параметры, содержат Форму расшифровываемого отчета ФормаОтчета
// 		и структуру ЗаполняемыеНастройки, в которой указано какие настройки нужно заполнить по умолчанию.
//
Procedure ChooseFromMenuEnd(Result, AdditionalParameters) Export
	
	If Result <> Undefined Then
		If TypeOf(Result.Value) = Type("String") Then
			FormName = GetFormNameByDetailsID(Result.Value);

			FormParameters = New Structure;
			FormParameters.Insert("DetailsType",          1);
			FormParameters.Insert("SettingsAddress",           AdditionalParameters.ReportForm.DetailsData);
			FormParameters.Insert("GenerateOnOpen", True);
			FormParameters.Insert("DetailsID",           Result.Value);
			FormParameters.Insert("FilledSettings",    AdditionalParameters.FilledSettings);

			OpenForm(FormName, FormParameters,, True);
		Else
			ShowValue( , Result.Value);
		EndIf;
	EndIf;
	
EndProcedure

// Проверяет является ли выбранный пункт меню отчетом.
//
// Параметры:
//  Отчет	 - Структура, Объект, Неопределено	 - Значение выбранное из списка действий расшифровки.
// 
// Возвращаемое значение:
//   Булево - Истина, если это пункт расшифровки отчет, Ложь - в противном случае.
//
Function IsReport(Report)
	
	Return TypeOf(Report) = Type("Structure") AND Report.Property("ReportName");
	
EndFunction

// Определяет полный путь к форме отчета.
//
// Параметры:
//  ИДРасшифровки	 - Строка	 - Имя отчета, путь к форме которого нужно получить.
// 
// Возвращаемое значение:
//  Строка - Полный путь к форме указанного отчета.
//
Function GetFormNameByDetailsID(DetailsID)
	
	ObjectName = DetailsID;
	FormNameTemplate = "Report.%ObjectName%.Form.ReportForm";
	
	If DetailsID = "fmAccountTurnoversByDaysIFRS" 
		OR DetailsID = "fmAccountTurnoversByMonthsIFRS" Then
		ObjectName = "fmAccountTurnoversIFRS";
	EndIf;
	
	Return StrReplace(FormNameTemplate, "%ObjectName%", ObjectName);
	
EndFunction

// Процедура обработчик "ОрганизацияПриИзменении" 
//
Procedure CompanyOnChange(Form, Item) Export 
	
	Report = Form.Report;
	For Each FilterItem In Report.SettingsComposer.Settings.Filter.Items Do
		If TypeOf(FilterItem) = Type("DataCompositionFilterItem") AND FilterItem.Use Then
			If FilterItem.LeftValue = New DataCompositionField("Company") Then
				FilterItem.ComparisonType   = DataCompositionComparisonType.InList;
				FilterItem.RightValue = Report.Company; 
			EndIf;
		EndIf;
	EndDo;
	
EndProcedure

// Процедура обработчик "БалансоваяЕдиницаПриИзменении" 
//
Procedure BalanceUnitOnChange(Form, Item) Export 
	
	Report = Form.Report;
	For Each FilterItem In Report.SettingsComposer.Settings.Filter.Items Do
		If TypeOf(FilterItem) = Type("DataCompositionFilterItem") AND FilterItem.Use Then
			If FilterItem.LeftValue = New DataCompositionField("BalanceUnit") Then
				FilterItem.ComparisonType   = DataCompositionComparisonType.Equal;
				FilterItem.RightValue = Report.BalanceUnit; 
			EndIf;
		EndIf;
	EndDo;
	
EndProcedure

// Процедура обработчик "ОтборыПриИзменении" 
//
Procedure FiltersOnChange(Form, Item) Export
	
	Report = Form.Report;
	For Each FilterItem In Report.SettingsComposer.Settings.Filter.Items Do
		If TypeOf(FilterItem) = Type("DataCompositionFilterItem") AND FilterItem.Use Then
			If FilterItem.LeftValue = New DataCompositionField("Company") Then				
				
				If FilterItem.ComparisonType = DataCompositionComparisonType.Equal Then 
					Report.Company = FilterItem.RightValue;
				Else
					Report.Company = Undefined;
				EndIf; 
				
				Report.IncludeParticipatedDepartments = False;
				
			EndIf;
		EndIf;
	EndDo;
	
EndProcedure


Procedure FiltersBeforeRowChange(Form, Item, Cancel) Export
	
	If (Find(Item.CurrentItem.Name, "FilterLeftValue") > 0 AND TypeOf(Item.CurrentData.LeftValue) = Type("DataCompositionField")) Then
		FormParameters = New Structure;
		FormParameters.Insert("DataCompositionSchema", Form.DataCompositionSchema);
		FormParameters.Insert("Mode"                , "Filter");
		FormParameters.Insert("DeniedFields"      , Form.GetDeniedFields("Filter"));
		FormParameters.Insert("CurrentRow"        , Item.CurrentData.LeftValue);
		SelectedFieldParameters = OpenFormModal("CommonForm.fmAvailableFieldChoiceForm", FormParameters);
		
		If TypeOf(SelectedFieldParameters) = Type("Structure") Then
			
			CurrentRow = Form.Report.SettingsComposer.Settings.Filter.GetObjectByID(Item.CurrentRow);
			
			If Find(Item.CurrentItem.Name, "FilterLeftValue") > 0 Then 
				CurrentRow.LeftValue = New DataCompositionField(SelectedFieldParameters.Field);
			EndIf;
		EndIf;
		
		Cancel = True;
	EndIf;	
	
EndProcedure

// Процедура обработчик "ОтборыПередНачаломДобавления" 
//
Procedure FilterBeforeAddRow(Form, Item, Cancel, Copy, Parent, Group) Export
	
	Cancel = True;
	
	FormParameters = New Structure;
	FormParameters.Insert("DataCompositionSchema", Form.DataCompositionSchema);
	FormParameters.Insert("Mode"                , "Filter");
	FormParameters.Insert("DeniedFields"      , Form.GetDeniedFields("Filter"));
	FormParameters.Insert("CurrentRow"        , Undefined);
	SelectedFieldParameters = Undefined;

	OpenForm("CommonForm.fmAvailableFieldChoiceForm", FormParameters,,,,, New NotifyDescription("FilterBeforeAddRowEnd", ThisObject, New Structure("Form, Item", Form, Item)), FormWindowOpeningMode.LockWholeInterface);
	
EndProcedure

Procedure FilterBeforeAddRowEnd(Result, AdditionalParameters) Export
	
	Form = AdditionalParameters.Form;
	Item = AdditionalParameters.Item;
	
	SelectedFieldParameters = Result;
	
	If TypeOf(SelectedFieldParameters) = Type("Structure") Then
		
		If Item.CurrentRow = Undefined Then
			CurrentRow = Undefined;
		Else
			CurrentRow = Form.Report.SettingsComposer.Settings.Filter.GetObjectByID(Item.CurrentRow);
		EndIf;
		
		If TypeOf(CurrentRow) = Type("DataCompositionFilterItemGroup") Then
			FilterItem = CurrentRow.Items.Add(Type("DataCompositionFilterItem"));
		ElsIf TypeOf(CurrentRow) = Type("DataCompositionFilterItem") Then
			If CurrentRow.Parent <> Undefined Then
				FilterItem = CurrentRow.Parent.Items.Add(Type("DataCompositionFilterItem"));
			Else
				FilterItem = Form.Report.SettingsComposer.Settings.Filter.Items.Add(Type("DataCompositionFilterItem"));
			EndIf;
		Else
			FilterItem = Form.Report.SettingsComposer.Settings.Filter.Items.Add(Type("DataCompositionFilterItem"));
		EndIf;
		
		FilterItem.LeftValue  = New DataCompositionField(SelectedFieldParameters.Field);
		FilterItem.ComparisonType = SelectedFieldParameters.ComparisonType;
		If String(SelectedFieldParameters.Field) = "Company" Then
			FilterItem.ComparisonType   = DataCompositionComparisonType.Equal;
			FilterItem.RightValue = Form.Report.Company;
		EndIf;
		
		Item.CurrentRow = Form.Report.SettingsComposer.Settings.Filter.GetIDByObject(FilterItem);
		
	EndIf;
	
EndProcedure

#EndRegion

#Region ProceduresAndFunctionOfPeriodProcessing

Procedure PeriodStartListChoice(Form, BeginOfPeriod, EndOfPeriod, Item, StandardProcessing, PeriodName="Period", MinimumPeriod=Undefined, MaximumPeriod=Undefined) Export
	
	If Form.PeriodType = Form.AvailableReportPeriods.ArbitraryPeriod Then
		//ВыбратьПроизвольныйПериодОтчета(Форма, НачалоПериода, КонецПериода, Форма.ДоступныеПериодыОтчета.День);
		StandardProcessing = False;
	Else
		If BeginOfPeriod = '00010101' Then
			BeginOfPeriod = fmReportsClientServer.ReportBegOfPeriod(Form.PeriodType, CurrentDate(), Form);
		EndIf;
		SelectedPeriod      = SelectReportPeriod(Form, Item, StandardProcessing, BeginOfPeriod, MinimumPeriod, MaximumPeriod);
		StandardProcessing = False;
		If SelectedPeriod = Undefined Then
			If MinimumPeriod=Undefined Then
				BeginOfPeriod = Undefined;
			EndIf;
			Return;
		EndIf;
		Form[PeriodName] = SelectedPeriod.Presentation;
		
		BeginOfPeriod = SelectedPeriod.Value;
		EndOfPeriod  = fmReportsClientServer.ReportEndOfPeriod(Form.PeriodType, SelectedPeriod.Value, Form);
	EndIf;
	
EndProcedure

Function SelectReportPeriod(Form, Item, StandardProcessing, BeginOfPeriod, MinimumPeriod=Undefined, MaximumPeriod=Undefined)
	
	List = fmReportsClientServer.GetPeriodList(BeginOfPeriod, Form.PeriodType, Form, MinimumPeriod, MaximumPeriod);
	If List.Count() = 0 Then
		StandardProcessing = False;
		Return Undefined;
	EndIf;
	
	ListItem = List.FindByValue(BeginOfPeriod);
	SelectedPeriod = Form.ChooseFromList(List, Item, ListItem);
	
	If SelectedPeriod = Undefined Then
		Return Undefined;
	EndIf;
	
	Index = List.IndexOf(SelectedPeriod);
	If (Index = 0 OR Index = List.Count() - 1) AND MaximumPeriod=Undefined Then
		SelectedPeriod = SelectReportPeriod(Form, Item, StandardProcessing, SelectedPeriod.Value);
	EndIf;
	
	Return SelectedPeriod;
	
EndFunction

Procedure PeriodOnChange(Form, BeginOfPeriod, EndOfPeriod, Item) Export
	
	If IsBlankString(Form.Period) Then
		BeginOfPeriod = Undefined;
		EndOfPeriod  = Undefined;
	EndIf;
	
EndProcedure


#EndRegion


