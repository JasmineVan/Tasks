
#Region Rarus

Function ReportSupportsUniversalSettings(ReportName) Export
	
	ReportList = New Array;
	ReportList.Add("fmExtDimensionAnalysisIFRS");
	ReportList.Add("fmAccountAnalysisIFRS");
	ReportList.Add("fmExtDimensionCardIFRS");
	ReportList.Add("fmAccountCardIFRS");
	ReportList.Add("fmTurnoverBalanceSheetIFRS");
	ReportList.Add("fmAccountTurnoverBalanceSheetIFRS");
	ReportList.Add("fmTurnoversBetweenExtDimensionsIFRS");
	ReportList.Add("fmAccountTurnoversIFRS");
	ReportList.Add("fmPostingReportIFRS");
	ReportList.Add("fmConsolidatedAccountTransactionsIFRS");
	ReportList.Add("fmChessListIFRS");
	
	Return ReportList.Find(ReportName) <> Undefined;
	
EndFunction

Procedure SwitchCurrentPeriodChoicePage(PeriodType, Pages, PagesParameters = Undefined) Export
	
	If PagesParameters = Undefined Then
		PagesParameters = New Structure;
		PagesParameters.Insert("ArbitraryPeriod", "GroupArbitraryPeriod");
		PagesParameters.Insert("PeriodByTypes"     , "GroupPeriodByTypes");
		PagesParameters.Insert("Day"              , "GroupDay");
	EndIf;
	
	If PeriodType = PredefinedValue("Enum.fmAvailableReportPeriods.ArbitraryPeriod") Then
		Pages.CurrentPage = Pages.ChildItems[PagesParameters.ArbitraryPeriod];
	ElsIf PeriodType = PredefinedValue("Enum.fmAvailableReportPeriods.Day") Then
		Pages.CurrentPage = Pages.ChildItems[PagesParameters.Day];
	Else
		Pages.CurrentPage = Pages.ChildItems[PagesParameters.PeriodByTypes];
	EndIf;
	
EndProcedure

// Удаляет элемент отбора динамического списка
//
// Параметры:
// Список  - обрабатываемый динамический список,
// ИмяПоля - имя поля компоновки, отбор по которому нужно удалить.
//
Procedure DeleteFilterListItem(List, FieldName, ComparisonType = Undefined) Export
	
	ItemsForDeleting = New Array;
	
	FilterItems = List.Filter.Items;
	CompositionField = New DataCompositionField(FieldName);
	For Each FilterItem In FilterItems Do
		If TypeOf(FilterItem) = Type("DataCompositionFilterItem")
			AND FilterItem.LeftValue = CompositionField 
			AND (ComparisonType = Undefined OR FilterItem.ComparisonType = ComparisonType) Then
			ItemsForDeleting.Add(FilterItem);
		EndIf;
	EndDo;
	
	For Each FilterItemForDeletion In ItemsForDeleting Do
		FilterItems.Delete(FilterItemForDeletion);
	EndDo;
	
EndProcedure // УдалитьЭлементОтбораСписка()

// Устанавливает элемент отбор динамического списка
//
// Параметры:
// Список			- обрабатываемый динамический список,
// ИмяПоля			- имя поля компоновки, отбор по которому нужно установить,
// ВидСравнения		- вид сравнения отбора, по умолчанию - Равно,
// ПравоеЗначение 	- значение отбора.
//
Procedure SetListFilterItem(List, FieldName, RightValue, ComparisonType = Undefined, Presentation = "") Export
	
	FilterItem = List.Filter.Items.Add(Type("DataCompositionFilterItem"));
	FilterItem.LeftValue  = New DataCompositionField(FieldName);	
	FilterItem.ComparisonType   = ?(ComparisonType = Undefined, DataCompositionComparisonType.Equal, ComparisonType);
	FilterItem.Use  = True;
	FilterItem.RightValue = RightValue;
	FilterItem.Presentation  = Presentation;
	
EndProcedure // УстановитьЭлементОтбораСписка()

// Устанавливает произвольные отборы динамического списка
//
// Параметры:
// Список        - обрабатываемый динамический список,
// ПараметрыОткрытияФормы - структура, должна содержать элемент "укфОтбор" с типом
//                структура или массив структур. Структура должна содержать поля
//                "ИмяПоля", "ВидСравнения", "Значение", "Представление", "Доступность" (Булево)
//                (обязательно только "ИмяПоля").
//
Procedure SetArbitraryListFilters(List, FormOpenParameters) Export
	
	If NOT FormOpenParameters.Property("fmFilter") Then 
		Return;
	EndIf;
	
	Filter = FormOpenParameters.fmFilter;
	
	If TypeOf(Filter) = Type("Structure") AND Filter.Property("FieldName") Then 
		
		DeleteFilterListItem(List, Filter.FieldName, Filter.ComparisonType);
		
		FilterItem = List.Filter.Items.Add(Type("DataCompositionFilterItem"));
		FilterItem.LeftValue    = New DataCompositionField(Filter.FieldName);
		FilterItem.ComparisonType     = ?(Filter.Property("ComparisonType"), Filter.ComparisonType, DataCompositionComparisonType.Equal);
		FilterItem.Use    = True;
		FilterItem.RightValue   = ?(Filter.Property("Value"), Filter.Value, Undefined);
		FilterItem.Presentation    = ?(Filter.Property("Presentation"), Filter.Presentation, "");
		FilterItem.ViewMode = ?(Filter.Property("Enabled") AND Filter.Enabled, DataCompositionSettingsItemViewMode.QuickAccess, DataCompositionSettingsItemViewMode.Inaccessible);
		
	ElsIf TypeOf(Filter) = Type("Array") Then 
		
		For Each CurFilter In Filter Do
			
			If TypeOf(CurFilter) <> Type("Structure") AND NOT CurFilter.Property("FieldName") Then 
				Continue;
			EndIf;
			
			DeleteFilterListItem(List, CurFilter.FieldName, CurFilter.ComparisonType);
			
			FilterItem = List.Filter.Items.Add(Type("DataCompositionFilterItem"));
			FilterItem.LeftValue    = New DataCompositionField(CurFilter.FieldName);
			FilterItem.ComparisonType     = ?(CurFilter.Property("ComparisonType"), CurFilter.ComparisonType, DataCompositionComparisonType.Equal);
			FilterItem.Use    = True;
			FilterItem.RightValue   = ?(CurFilter.Property("Value"), CurFilter.Value, Undefined);
			FilterItem.Presentation    = ?(CurFilter.Property("Presentation"), CurFilter.Presentation, "");
			FilterItem.ViewMode = ?(CurFilter.Property("Enabled") AND CurFilter.Enabled, DataCompositionSettingsItemViewMode.QuickAccess, DataCompositionSettingsItemViewMode.Inaccessible);
			
		EndDo;
		
	EndIf;
	
EndProcedure // УстановитьПроизвольныеОтборыСписка()

Procedure BalanceUnitOnChange(Form) Export 
	
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

// Добавляет отбор в коллекцию отборов компоновщика или группы отборов
//
// Параметры:
//		ЭлементСтруктуры - элемент структуры
//		Поле             - имя поля, по которому добавляется отбор
//		Значение         - значение отбора
//		ВидСравнения     - вид сравнений компоновки данных (по умолчанию: вид сравнения)
//		Использование    - признак использования отбора (по умолчанию: истина)
//
Function AddFilter(StructureItem, VAL Field, Value, ComparisonType = Undefined, Use = True, ToUserSettings = False) Export
	
	If TypeOf(Field) = Type("String") Then
		Field = New DataCompositionField(Field);
	EndIf;
	
	If TypeOf(StructureItem) = Type("DataCompositionSettingsComposer") Then
		Filter = StructureItem.Settings.Filter;
		
		If ToUserSettings Then
			For Each SettingItem In StructureItem.UserSettings.Items Do	
				If SettingItem.UserSettingID = StructureItem.Settings.Filter.UserSettingID Then
					Filter = SettingItem;
				EndIf;
			EndDo;
		EndIf;
	ElsIf TypeOf(StructureItem) = Type("DataCompositionSettings") Then
		Filter = StructureItem.Filter;
	Else
		Filter = StructureItem;
	EndIf;
		
	If ComparisonType = Undefined Then
		ComparisonType = DataCompositionComparisonType.Equal;
	EndIf;
	
	NewItem = Filter.Items.Add(Type("DataCompositionFilterItem"));
	NewItem.Use  = Use;
	NewItem.LeftValue  = Field;
	NewItem.ComparisonType   = ComparisonType;
	NewItem.RightValue = Value;
	
	Return NewItem;
	
EndFunction

// Функция возвращает значение параметра компоновки данных
//
// Параметры:
//  Настройки - Пользовательские настройки СКД, Настройки СКД, Компоновщик настроек
//  Параметр - имя параметра СКД для которого нужно вернуть значение параметра
Function GetParameter(Settings, Parameter) Export
	
	ParameterValue = Undefined;
	ParameterField = ?(TypeOf(Parameter) = Type("String"), New DataCompositionParameter(Parameter), Parameter);
	
	If TypeOf(Settings) = Type("DataCompositionSettings") Then
		ParameterValue = Settings.DataParameters.FindParameterValue(ParameterField);
	ElsIf TypeOf(Settings) = Type("DataCompositionUserSettings") Then
		For Each SettingItem In Settings.Items Do
			If TypeOf(SettingItem) = Type("DataCompositionSettingsParameterValue") AND SettingItem.Parameter = ParameterField Then
				ParameterValue = SettingItem;
				Break;
			EndIf;
		EndDo;
	ElsIf TypeOf(Settings) = Type("DataCompositionSettingsComposer") Then
		For Each SettingItem In Settings.UserSettings.Items Do
			If TypeOf(SettingItem) = Type("DataCompositionSettingsParameterValue") AND SettingItem.Parameter = ParameterField Then
				ParameterValue = SettingItem;
				Break;
			EndIf;
		EndDo;
		If ParameterValue = Undefined Then
			ParameterValue = Settings.Settings.DataParameters.FindParameterValue(ParameterField);
		EndIf;
	ElsIf TypeOf(Settings) = Type("DataCompositionDetailsData") Then
		ParameterValue = Settings.Settings.DataParameters.FindParameterValue(ParameterField);
	ElsIf TypeOf(Settings) = Type("DataCompositionParameterValueCollection") Then
		ParameterValue = Settings.Find(ParameterField);
	ElsIf TypeOf(Settings) = Type("DataCompositionAppearance") Then
		ParameterValue = Settings.FindParameterValue(ParameterField);
	EndIf;
	
	Return ParameterValue;
	
EndFunction

// Функция устанавливает значение параметра компоновки данных
//
// Параметры:
//		Настройки     - Пользовательские настройки СКД, Настройки СКД, Компоновщик настроек
//		Параметр      - имя параметра СКД для которого нужно вернуть значение параметра
//      Значение      - значение параметра
//		Использование - Признак использования параметра. По умолчанию всегда принимается равным истине.
//
Function SetParameter(Settings, Parameter, Value, Use = True) Export
	
	ParameterValue = GetParameter(Settings, Parameter);
	
	If ParameterValue <> Undefined Then
		ParameterValue.Use = Use;
		ParameterValue.Value      = Value;
	EndIf;
	
	Return ParameterValue;
	
EndFunction

// Устанавливает параметр вывода компоновщика настроек или настройки СКД.
//
// Параметры:
//	КомпоновщикНастроекГруппировка - КомпоновщикНастроекКомпоновкиДанных - Компоновщик настроек или настройка/группировка СКД.
//	ИмяПараметра - Строка - Имя параметра СКД.
//	Значение - Произвольный - Значение параметра вывода СКД.
//	Использование - Признак использования параметра. По умолчанию всегда принимается равным истине.
//
// Возвращаемое значение:
//	ЗначениеПараметраКомпоновкиДанных - Параметр вывода.
//
Function SetOutputParamters(Setting, ParameterName, Value, Use = True) Export
	
	ParameterValue = GetOutputParameter(Setting, ParameterName);
	
	If ParameterValue <> Undefined Then
		ParameterValue.Use = Use;
		ParameterValue.Value      = Value;
	EndIf;
	
	Return ParameterValue;
	
EndFunction

// Получает параметр вывода компоновщика настроек или настройки СКД.
//
// Параметры:
// 	КомпоновщикНастроекГруппировка - КомпоновщикНастроекКомпоновкиДанных - Компоновщик настроек 
//		или настройка/группировка СКД.
//  ИмяПараметра - Строка - Имя параметра СКД.
//
// Возвращаемое значение:
//	ЗначениеПараметраКомпоновкиДанных - Параметр вывода.
//
Function GetOutputParameter(Setting, ParameterName) Export
	
	ParametersArray   = StringFunctionsClientServer.SplitStringIntoSubstringsArray(ParameterName, ".");
	NestingLevel = ParametersArray.Count();
	
	If NestingLevel > 1 Then
		ParameterName = ParametersArray[0];		
	EndIf;
	
	If TypeOf(Setting) = Type("DataCompositionSettingsComposer") Then
		ParameterValue = Setting.Settings.OutputParameters.FindParameterValue(New DataCompositionParameter(ParameterName));
	Else
		ParameterValue = Setting.OutputParameters.FindParameterValue(New DataCompositionParameter(ParameterName));
	EndIf;
	
	If NestingLevel > 1 Then
		For Index = 1 To NestingLevel - 1 Do
			ParameterName = ParameterName + "." + ParametersArray[Index];
			ParameterValue = ParameterValue.NestedParameterValues.Find(ParameterName); 
		EndDo;
	EndIf;
	
	Return ParameterValue;  
	
EndFunction

// Устанавливает заголовок кнопки отображения / скрытия панели настроек отчета.
//
// Параметры:
//	Кнопка - КнопкаФормы - Кнопка отображения / скрытия панели настроек.
//	ВидимостьПанелиНастроек - Булево - Признак видимости кнопки.
//
Procedure ChangeButtonTitleSettingsPanel(Button, SettingsPanelVisible) Export
	
	If SettingsPanelVisible Then
		Button.Title = NStr("en='Hide settings';ru='Скрыть настройки'");
	Else
		Button.Title = NStr("en='Show settings';ru='Показать настройки'");
	EndIf;
		
EndProcedure

// Вычисляет сумму выделенных ячеек табличного документа.
//
// Параметры:
//	Сумма - Число - Сумма значений ячеек.
//	СтруктураАдресВыделеннойОбласти - Структура - Содержит ячейки выделенной области.
//	Результат - ТабличныйДокумент - Табличный документ, содержащий ячейки для суммирования.
//
Procedure EvalCellsAmount(Amount, SelectedAreaAddressStructure, Result) Export
	
	NumberType = New TypeDescription("Number");
	For RowIndex = SelectedAreaAddressStructure.Top To SelectedAreaAddressStructure.Bottom Do
		If RowIndex = 0 Then // Выделена колонка отчета (без ограничений), суммы из нее получить нельзя.
			Continue;
		EndIf;
		
		For ColumnIndex = SelectedAreaAddressStructure.Left To SelectedAreaAddressStructure.Right Do
			If ColumnIndex = 0 Then // Выделена строка отчета (без ограничений), суммы из нее получить нельзя.
				Continue;
			EndIf;
			
			Cell = Result.Area(RowIndex, ColumnIndex, RowIndex, ColumnIndex);
			If Cell.Visible = True Then
				If Cell.ContainsValue AND TypeOf(Cell.Value) = Type("Number") Then
					Amount = Amount + Cell.Value;
				ElsIf ValueIsFilled(Cell.Text) Then
					TextInCell = TrimAll(Cell.Text);
					
					// Удалим знак "+" перед числом. Используется в Платежном календаре.
					If Left(TextInCell, 1) = "+" Then
						TextInCell = Mid(TextInCell, 2);
					EndIf;
					
					// Разделим текст, включая пустые строки. Хотя бы одно значение (пустое) в массиве будет всегда.
					StringParts  = StrSplit(TextInCell, " ");
					NumberInCell = NumberType.AdjustValue(StringParts[0]);
					Amount        = Amount + NumberInCell;
				EndIf;
			EndIf;
		EndDo;
	EndDo;
	
EndProcedure

// Возвращает значение указанного свойства поля структуры.
//
// Параметры:
//	ЭлементСтруктура - КомпоновщикНастроекКомпоновкиДанных, Произвольный - Структура, в которой хранится поле.
//	Поле - Произвольный - Поле, для которого определяется значение свойства.
//	Свойство - Строка - Имя свойства, значение которого требуется получить.
//
// Возвращаемое значение:
//	Произвольный - Значение запрашиваемого свойства поля либо Неопределено.
//
Function GetFieldProperty(StructureItem, Field, Property = "Title") Export
	
	If TypeOf(StructureItem) = Type("DataCompositionSettingsComposer") Then
		Collection = StructureItem.Settings.SelectionAvailableFields;
	Else
		Collection = StructureItem;
	EndIf;
	
	FieldAsString = String(Field);
	BracePosition = StrFind(FieldAsString, "[");
	Ending = "";
	Title = "";
	If BracePosition > 0 Then
		Ending = Mid(FieldAsString, BracePosition);
		FieldAsString = Left(FieldAsString, BracePosition - 2);
	EndIf;
	
	StringArray = StringFunctionsClientServer.SplitStringIntoSubstringsArray(FieldAsString, ".");
	
	If NOT IsBlankString(Ending) Then
		StringArray.Add(Ending);
	EndIf;
	
	AvailableFields = Collection.Items;
	SearchField = "";
	For Index = 0 To StringArray.Count() - 1 Do
		SearchField = SearchField + ?(Index = 0, "", ".") + StringArray[Index];
		AvailableField = AvailableFields.Find(SearchField);
		If AvailableField <> Undefined Then
			AvailableFields = AvailableField.Items;
		EndIf;
	EndDo;
	
	If AvailableField <> Undefined Then
		If Property = "AvailableField" Then
			Result = AvailableField;
		Else
			Result = AvailableField[Property]; 
		EndIf;
	Else
		Result = Undefined;
	EndIf;
	
	Return Result;
	
EndFunction

#EndRegion

#Region ProceduresAndFunctionOfPeriodProcessing

Function GetPeriodList(BeginOfPeriod, PeriodType, Form, MinimumPeriod=Undefined, MaximumPeriod=Undefined) Export

	LanguageCode = NStr("en='en';ru='ru'");

	PeriodList = New ValueList;
	If BeginOfPeriod = '00010101' Then
		Return New ValueList;
	Else
		BegOfPeriodValue = BeginOfPeriod;
	EndIf;
	
	If PeriodType = Form.AvailableReportPeriods.Year Then
		CurrentYear = Year(BegOfPeriodValue);
		PeriodList.Add(DATE(CurrentYear - 7, 1, 1), NStr("en='Pred. years';ru='Предыдущие года'"));
		For Counter = CurrentYear To CurrentYear + 6 Do
			PeriodList.Add(DATE(Counter, 1, 1), Format(Counter, "NG=0"));
		EndDo;
		PeriodList.Add(DATE(CurrentYear + 7, 1, 1), NStr("en='Next years';ru='Последующие года'"));
		
	ElsIf PeriodType = Form.AvailableReportPeriods.HalfYear Then
		StrLoc = NStr("en='-th half-year';ru=' полугодие'");
		CurrentYear = Year(BegOfPeriodValue);
		PeriodList.Add(DATE(CurrentYear - 1, 1, 1), Format(CurrentYear - 1, "NG=0") + "...");
		For Counter = CurrentYear To CurrentYear + 1 Do
			PeriodList.Add(DATE(Counter, 1, 1), "I" + StrLoc + " " + Format(Counter, "NG=0"));
			PeriodList.Add(DATE(Counter, 7, 1), "II" + StrLoc + " " + Format(Counter, "NG=0"));
		EndDo;
		PeriodList.Add(DATE(CurrentYear + 2, 1, 1), Format(CurrentYear + 2, "NG=0") + "...");
		
	ElsIf PeriodType = Form.AvailableReportPeriods.Quarter Then
		StrLoc = NStr("en='-th quarter';ru=' квартал'");
		CurrentYear = Year(BegOfPeriodValue);
		If MaximumPeriod=Undefined OR MinimumPeriod<DATE(CurrentYear - 1, 1, 1) Then
			PeriodList.Add(DATE(CurrentYear - 1, 1, 1), Format(CurrentYear - 1, "NG=0") + "...");
		EndIf;
		For Counter = CurrentYear To CurrentYear Do
			If MaximumPeriod=Undefined OR (MinimumPeriod<=DATE(Counter, 1, 1) AND MaximumPeriod>DATE(Counter, 1, 1)) Then
				PeriodList.Add(DATE(Counter, 1, 1), "I" + StrLoc + " " + Format(Counter, "NG=0"));
			EndIf;
			If MaximumPeriod=Undefined OR (MinimumPeriod<=DATE(Counter, 4, 1) AND MaximumPeriod>DATE(Counter, 4, 1)) Then
				PeriodList.Add(DATE(Counter, 4, 1), "II" + StrLoc + " " + Format(Counter, "NG=0"));
			EndIf;
			If MaximumPeriod=Undefined OR (MinimumPeriod<=DATE(Counter, 7, 1) AND MaximumPeriod>DATE(Counter, 7, 1)) Then
				PeriodList.Add(DATE(Counter, 7, 1), "III" + StrLoc + " "+ Format(Counter, "NG=0"));
			EndIf;
			If MaximumPeriod=Undefined OR (MinimumPeriod<=DATE(Counter, 10, 1) AND MaximumPeriod>DATE(Counter, 10, 1)) Then
				PeriodList.Add(DATE(Counter, 10, 1), "IV" + StrLoc + " " + Format(Counter, "NG=0"));
			EndIf;
		EndDo;
		If MaximumPeriod=Undefined OR MaximumPeriod>DATE(CurrentYear + 1, 1, 1) Then
			PeriodList.Add(DATE(CurrentYear + 1, 1, 1), Format(CurrentYear + 1, "NG=0") + "...");
		EndIf;
	ElsIf PeriodType = Form.AvailableReportPeriods.Month Then
		CurrentYear = Year(BegOfPeriodValue);
		If CurrentYear<2000 Then
			CurrentYear = CurrentYear + 2000;
		EndIf;
		If MaximumPeriod=Undefined OR MinimumPeriod<DATE(CurrentYear - 1, 1, 1) Then
			PeriodList.Add(DATE(CurrentYear - 1, 1, 1), Format(CurrentYear - 1, "NG=0") + "...");
		EndIf;
		For Counter = 1 To 12 Do
			If MaximumPeriod=Undefined OR (MinimumPeriod<=DATE(CurrentYear, Counter, 1) AND MaximumPeriod>=DATE(CurrentYear, Counter, 1)) Then
				PeriodList.Add(DATE(CurrentYear, Counter, 1), Format(DATE(CurrentYear, Counter, 1), "L=" + LanguageCode + "; DF='MMMM yyyy'"));
			EndIf;
		EndDo;
		If MaximumPeriod=Undefined OR MaximumPeriod>DATE(CurrentYear + 1, 1, 1) Then
			PeriodList.Add(DATE(CurrentYear + 1, 1, 1), Format(CurrentYear + 1, "NG=0") + "...");
		EndIf;
	
	ElsIf PeriodType = Form.AvailableReportPeriods.TenDays Then
		
		StrLoc = NStr("en='-th decade';ru=' дек.'");
		
		CurrentYear   = Year(BegOfPeriodValue);
		CurrentMonth = Month(BegOfPeriodValue);
		
		MonthCounter = ?(CurrentMonth - 4 < 1, 12 + CurrentMonth - 4, CurrentMonth - 4);
		YearCounter   = ?(CurrentMonth - 4 < 1, CurrentYear - 1       , CurrentYear);
		Counter = 6;
		
		Period = DATE(?(MonthCounter <> 1, YearCounter, YearCounter - 1), ?(MonthCounter > 1, MonthCounter - 1, 12), 1);
		PeriodList.Add(Period, Format(Period, "L=" + LanguageCode + "; DF='MMMM yyyy'") + "...");
		While Counter >0 Do
			PeriodList.Add(DATE(YearCounter, MonthCounter, 1),  "I" + StrLoc + " " + Lower(Format(DATE(YearCounter, MonthCounter, 1), "L=" + LanguageCode + "; DF='MMMM yyyy'")));
			PeriodList.Add(DATE(YearCounter, MonthCounter, 11), "II" + StrLoc + " " + Lower(Format(DATE(YearCounter, MonthCounter, 1), "L=" + LanguageCode + "; DF='MMMM yyyy'")));
			PeriodList.Add(DATE(YearCounter, MonthCounter, 21), "III" + StrLoc + " " + Lower(Format(DATE(YearCounter, MonthCounter, 1), "L=" + LanguageCode + "; DF='MMMM yyyy'")));
			MonthCounter = MonthCounter + 1;
			If MonthCounter > 12 Then
				YearCounter = YearCounter + 1;
				MonthCounter = 1;
			EndIf;
			Counter = Counter - 1;
		EndDo;
		PeriodList.Add(DATE(YearCounter, MonthCounter, 1), Format(DATE(YearCounter, MonthCounter, 1), "L=" + LanguageCode + "; DF='MMMM yyyy'") + "...");
		
	ElsIf PeriodType = Form.AvailableReportPeriods.Week Then
		BegOfWeek = BegOfWeek(BegOfPeriodValue) - 21 * 86400;
		
		PeriodList.Add(BegOfWeek - 7 * 86400, NStr("en='Pred. weeks.....';ru='Пред. недели ...'"));
		For Counter = 0 To 6 Do
			BOfWeek = BegOfWeek + 7 * Counter * 86400;  
			EOfWeek = EndOfWeek(BOfWeek);
			PeriodList.Add(BOfWeek, Format(BOfWeek, "DF=dd.MM") + " - " + Format(EOfWeek, "DF=dd.MM"));
		EndDo;
		PeriodList.Add(BegOfWeek + 7 * 86400, NStr("en='Next weeks....';ru='След. недели ...'") );
		
	ElsIf PeriodType = Form.AvailableReportPeriods.Day Then
		EndOfWeek   = EndOfWeek(BegOfPeriodValue);
		DayOfWeekDate = BegOfWeek(BegOfPeriodValue);
		
		PeriodList.Add(DayOfWeekDate - 86400, NStr("en='Pred. week';ru='Предыдущая неделя'"));
		
		While DayOfWeekDate < EndOfWeek Do
			WDay = WeekDay(DayOfWeekDate);
			
			PeriodList.Add(DayOfWeekDate, Format(DayOfWeekDate, "L=" + LanguageCode + "; DF='dd MMMM yyyy (ddd)'"));
			
			DayOfWeekDate = DayOfWeekDate + 86400;
		EndDo;
		
		PeriodList.Add(EndOfWeek + 1, NStr("en='Next week';ru='Следующая неделя'"));
	EndIf;
		
	Return PeriodList;
	
EndFunction

Function GetReportPeroidRepresentation(PeriodType, BeginOfPeriod, EndOfPeriod, Form) Export
	
	If PeriodType = Form.AvailableReportPeriods.ArbitraryPeriod Then	
		If NOT ValueIsFilled(BeginOfPeriod) AND NOT ValueIsFilled(EndOfPeriod) Then
			Return "";
		Else
			Return Format(BeginOfPeriod, "DF=dd.MM.yy") + " - " + Format(EndOfPeriod, "DF=dd.MM.yy");
		EndIf;
	Else
		List = GetPeriodList(BeginOfPeriod, PeriodType, Form);
		
		ListItem = List.FindByValue(BeginOfPeriod);
		If ListItem <> Undefined Then
			Return ListItem.Presentation;
		Else
			Return "";
		EndIf;
	EndIf;
	
	Return "";
	
EndFunction

Function ReportBegOfPeriod(PeriodType, PeriodDate, Form) Export
	
	BeginOfPeriod = PeriodDate;
	
	If PeriodType = Form.AvailableReportPeriods.Year Then
		BeginOfPeriod = BegOfYear(PeriodDate);
		
	ElsIf PeriodType = Form.AvailableReportPeriods.HalfYear Then
		If Month(PeriodDate) > 6 Then
			BeginOfPeriod = DATE(Year(PeriodDate), 7, 1);
		Else
			BeginOfPeriod = DATE(Year(PeriodDate), 1, 1);
		EndIf;
		
	ElsIf PeriodType = Form.AvailableReportPeriods.Quarter Then
		BeginOfPeriod = BegOfQuarter(PeriodDate);
		
	ElsIf PeriodType = Form.AvailableReportPeriods.Month Then
		BeginOfPeriod = BegOfMonth(PeriodDate);
		
	ElsIf PeriodType = Form.AvailableReportPeriods.TenDays Then
		If Day(PeriodDate) <= 10 Then
			BeginOfPeriod = DATE(Year(PeriodDate), Month(PeriodDate), 1);
		ElsIf Day(PeriodDate) > 10 AND Day(PeriodDate) <= 20 Then
			BeginOfPeriod = DATE(Year(PeriodDate), Month(PeriodDate), 11);
		Else
			BeginOfPeriod = DATE(Year(PeriodDate), Month(PeriodDate), 21);
		EndIf;
		
	ElsIf PeriodType = Form.AvailableReportPeriods.Week Then
		BeginOfPeriod = BegOfWeek(PeriodDate);
		
	ElsIf PeriodType = Form.AvailableReportPeriods.Day Then
		BeginOfPeriod = BegOfDay(PeriodDate);
		
	EndIf;
		
	Return BeginOfPeriod;
	
EndFunction

Function ReportEndOfPeriod(PeriodType, PeriodDate, Form) Export
	
	EndOfPeriod = PeriodDate;
	
	If PeriodType = Form.AvailableReportPeriods.Year Then
		EndOfPeriod = EndOfYear(PeriodDate);
		
	ElsIf PeriodType = Form.AvailableReportPeriods.HalfYear Then
		If Month(PeriodDate) > 6 Then
			EndOfPeriod = EndOfYear(PeriodDate);
		Else
			EndOfPeriod = EndOfDay(DATE(Year(PeriodDate), 6, 30));
		EndIf;
		
	ElsIf PeriodType = Form.AvailableReportPeriods.Quarter Then
		EndOfPeriod = EndOfQuarter(PeriodDate);
		
	ElsIf PeriodType = Form.AvailableReportPeriods.Month Then
		EndOfPeriod = EndOfMonth(PeriodDate);
		
	ElsIf PeriodType = Form.AvailableReportPeriods.TenDays Then
		If Day(PeriodDate) <= 10 Then
			EndOfPeriod = EndOfDay(DATE(Year(PeriodDate), Month(PeriodDate), 10));
		ElsIf Day(PeriodDate) > 10 AND Day(PeriodDate) <= 20 Then
			EndOfPeriod = EndOfDay(DATE(Year(PeriodDate), Month(PeriodDate), 20));
		Else
			EndOfPeriod = EndOfMonth(PeriodDate);
		EndIf;
		
	ElsIf PeriodType = Form.AvailableReportPeriods.Week Then
		EndOfPeriod = EndOfWeek(PeriodDate);
		
	ElsIf PeriodType = Form.AvailableReportPeriods.Day Then
		EndOfPeriod = EndOfDay(PeriodDate);
		
	EndIf;
		
	Return EndOfPeriod;
	
EndFunction

Function GetPeriodType(VAL BeginOfPeriod, VAL EndOfPeriod, Form) Export
	
	PeriodType = Form.AvailableReportPeriods.ArbitraryPeriod;
	If NOT ValueIsFilled(BeginOfPeriod) OR NOT ValueIsFilled(EndOfPeriod) Then
		PeriodType = Form.AvailableReportPeriods.ArbitraryPeriod;
	Else
		BeginOfPeriod = BegOfDay(BeginOfPeriod);
		EndOfPeriod  = EndOfDay(EndOfPeriod);
		If BeginOfPeriod = BegOfDay(BeginOfPeriod) AND EndOfPeriod = EndOfDay(BeginOfPeriod) Then
			PeriodType = Form.AvailableReportPeriods.Day;
		ElsIf BeginOfPeriod = BegOfWeek(BeginOfPeriod) AND EndOfPeriod = EndOfWeek(BeginOfPeriod) Then
			PeriodType = Form.AvailableReportPeriods.Week;
		ElsIf BeginOfPeriod = BegOfMonth(BeginOfPeriod) AND EndOfPeriod = EndOfMonth(BeginOfPeriod) Then
			PeriodType = Form.AvailableReportPeriods.Month;
		ElsIf BeginOfPeriod = BegOfQuarter(BeginOfPeriod) AND EndOfPeriod = EndOfQuarter(BeginOfPeriod) Then
			PeriodType = Form.AvailableReportPeriods.Quarter;
		ElsIf BeginOfPeriod = BegOfYear(BeginOfPeriod) AND EndOfPeriod = EndOfYear(BeginOfPeriod) Then
			PeriodType = Form.AvailableReportPeriods.Year;
		ElsIf BeginOfPeriod = DATE(Year(BeginOfPeriod), 1, 1) AND EndOfPeriod = DATE(Year(BeginOfPeriod), 5, 31, 23, 59, 59)
			OR BeginOfPeriod = DATE(Year(BeginOfPeriod), 6, 1) AND EndOfPeriod = DATE(Year(BeginOfPeriod), 12, 31, 23, 59, 59) Then
			PeriodType = Form.AvailableReportPeriods.HalfYear;
		ElsIf BeginOfPeriod = DATE(Year(BeginOfPeriod), Month(BeginOfPeriod), 1) 
			AND EndOfPeriod = DATE(Year(BeginOfPeriod), Month(BeginOfPeriod), 10, 23, 59, 59)
			OR BeginOfPeriod = DATE(Year(BeginOfPeriod), Month(BeginOfPeriod), 11) 
			AND EndOfPeriod = DATE(Year(BeginOfPeriod), Month(BeginOfPeriod), 20, 23, 59, 59)
			OR BeginOfPeriod = DATE(Year(BeginOfPeriod), Month(BeginOfPeriod), 1) 
			AND EndOfPeriod = EndOfMonth(BeginOfPeriod)	Then
			PeriodType = Form.AvailableReportPeriods.TenDays;
		EndIf;
	EndIf;
	
	Return PeriodType;
	
EndFunction

#EndRegion
////////////////////////////////////////////////////////////////////////////////

#Region ProceduresAndFunctionsOfReportStateProcessing

Procedure SetState(Form, DontUse = False) Export
	
	If DontUse Then
		Form.Items.Result.StatePresentation.Visible                      = False;
		Form.Items.Result.StatePresentation.AdditionalShowMode = AdditionalShowMode.DontUse;
	Else
		Form.Items.Result.StatePresentation.Visible                      = True;
		Form.Items.Result.StatePresentation.AdditionalShowMode = AdditionalShowMode.Irrelevance;
	EndIf;
	
EndProcedure

// Процедура управляет состояние поля табличного документа.
//
// Параметры:
//  ПолеТабличногоДокумента - ПолеФормы - поле формы с видом ПолеТабличногоДокумента,
//                            для которого необходимо установить состояние.
//  Состояние               - Строка - задает вид состояния.
//
Procedure SetSpreadsheetDocumentFieldState(SpreadsheetDocumentField, State = "DontUse") Export
	
	If TypeOf(SpreadsheetDocumentField) = Type("FormField") 
		AND SpreadsheetDocumentField.Type = FormFieldType.SpreadsheetDocumentField Then
		StatePresentation = SpreadsheetDocumentField.StatePresentation;
		If Upper(State) = "DONTUSE" Then
			StatePresentation.Visible                      = False;
			StatePresentation.AdditionalShowMode = AdditionalShowMode.DontUse;
			StatePresentation.Picture                       = New Picture;
			StatePresentation.Text                          = "";
		ElsIf Upper(State) = "IRRELEVANCE" Then
			StatePresentation.Visible                      = True;
			StatePresentation.AdditionalShowMode = AdditionalShowMode.Irrelevance;
			StatePresentation.Picture                       = New Picture;
			StatePresentation.Text                          = NStr("en='Report is not generated yet. Click ""Generate"" to get the report.';ru='Отчет не сформирован. Нажмите ""Сформировать"" для получения отчета.'");;
		ElsIf Upper(State) = "REPORTGENERATING" Then  
			StatePresentation.Visible                      = True;
			StatePresentation.AdditionalShowMode = AdditionalShowMode.Irrelevance;
			StatePresentation.Picture                       = PictureLib.fmLongActions48;
			StatePresentation.Text                          = NStr("en='Report is generated...';ru='Отчет формируется...'");
		Else
			Raise(NStr("en=""Invalid parameter value (parameter number '2')"";ru=""Недопустимое значение параметра (параметр номер '2')"""));
		EndIf;
	Else
		Raise(NStr("en=""Invalid parameter value (parameter number '1')"";ru=""Недопустимое значение параметра (параметр номер '1')"""));
	EndIf;
	
EndProcedure

#EndRegion


