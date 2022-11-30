
#Region ProceduresAndFunctionsOfCommonUse

// Возвращает массив, по которому следует расшифровать отчет
Function GetDetailsFieldsArray(Details, DetailsData, CurrentReport = Undefined, IncludeResources = False) Export
	
	DetailsFieldsArray = New Array;
	
	If TypeOf(Details) <> Type("DataCompositionDetailsID") 
	   AND TypeOf(Details) <> Type("DataCompositionDetailsData") Then
		Return DetailsFieldsArray;
	EndIf;
	
	If CurrentReport = Undefined Then
		CurrentReport = DetailsData;
	EndIf;
	
	// Добавим поля родительских группировок
	AddParents(DetailsData.Items[Details], CurrentReport, DetailsFieldsArray, IncludeResources);
	
	Count = DetailsFieldsArray.Count();
	For Index = 1 To Count Do
		ReverseIndex = Count - Index;
		For IndexInside = 0 To ReverseIndex - 1 Do
			If DetailsFieldsArray[ReverseIndex].Field = DetailsFieldsArray[IndexInside].Field Then
				DetailsFieldsArray.Delete(ReverseIndex);
				Break;
			EndIf;
		EndDo;
	EndDo;
	
	// Добавим отбор, установленный в отчете
	For Each FilterItem In CurrentReport.Settings.Filter.Items Do
		If NOT FilterItem.Use Then
			Continue;
		EndIf;
		DetailsFieldsArray.Add(FilterItem);
	EndDo;
	
	Return DetailsFieldsArray;
	
EndFunction

// Функция обработчик события "ДобавитьРодителей" 
//
Function AddParents(DetailsItem, CurrentReport, DetailsFieldsArray, IncludeResources = False)  Export
	
	If TypeOf(DetailsItem) = Type("DataCompositionFieldDetailsItem") Then
		For Each Field In DetailsItem.GetFields() Do
			AvailableField = GetAvailableFieldByDataCompositionAvailableField(New DataCompositionField(Field.Field), CurrentReport);
			If AvailableField = Undefined Then
				Continue;
			EndIf;
			If NOT IncludeResources AND AvailableField.Resource Then
				Continue;
			EndIf;
			DetailsFieldsArray.Add(Field);
		EndDo;
	EndIf;
	For Each Parent In DetailsItem.GetParents() Do
		AddParents(Parent, CurrentReport, DetailsFieldsArray, IncludeResources);
	EndDo;
	
EndFunction

// Возвращает доступное поле по полю компоновки
Function GetAvailableFieldByDataCompositionAvailableField(DataCompositionField, SearchArea) Export
	
	If TypeOf(DataCompositionField) = Type("String") Then
		SearchField = New DataCompositionField(DataCompositionField);
	Else
		SearchField = DataCompositionField;
	EndIf;
	
	If TypeOf(SearchArea) = Type("DataCompositionSettingsComposer")
	 OR TypeOf(SearchArea) = Type("DataCompositionDetailsData")
	 OR TypeOf(SearchArea) = Type("DataCompositionNestedObjectSettings") Then
		Return SearchArea.Settings.SelectionAvailableFields.FindField(SearchField);
	Else
		Return SearchArea.FindField(SearchField);
	EndIf;
	
EndFunction

// Процедура обработчик "ПриСохраненииПользовательскихНастроекНаСервере" 
//
Procedure OnSaveUserSettingsAtServer(ReportForm, Settings, SaveAttributesOnly = False) Export
	
	ReportObject = ReportForm.FormAttributeToValue("Report");
	
	ReportMetadata = ReportObject.Metadata();
	
	If NOT SaveAttributesOnly Then
		CurrentSettings = ReportObject.SettingsComposer.Settings;
		
		// Очистка пользовательских настроек
		CurrentSettings.Filter.UserSettingID              = "";
		CurrentSettings.Order.UserSettingID            = "";
		CurrentSettings.ConditionalAppearance.UserSettingID = "";
		CurrentSettings.Selection.UserSettingID              = "";
		
		// Установка пользовательских настроек
		CurrentSettings.Filter.UserSettingID              = "Filter";
		CurrentSettings.Order.UserSettingID            = "Order";
		CurrentSettings.ConditionalAppearance.UserSettingID = "ConditionalAppearance";
		CurrentSettings.Selection.UserSettingID              = "CASE";
	EndIf;

	// Сохранение реквизитов отчета
	AdditionalProperties = New Structure;
	For Each Attribute In ReportMetadata.Attributes Do
		If Attribute.Name <> "DetailsMode" Then
			AdditionalProperties.Insert(Attribute.Name, ReportObject[Attribute.Name]);
		EndIf;
	EndDo;
	For Each Attribute In ReportMetadata.TabularSections Do
		AdditionalProperties.Insert(Attribute.Name, ReportObject[Attribute.Name].Unload());
	EndDo;
	
	FormAttributes = ReportForm.GetAttributes();
	If NOT SaveAttributesOnly Then
		// Сохранение реквизитов формы
		If FormAttributeExists(ReportForm, "PutHeader") Then
			AdditionalProperties.Insert("PutHeader", ReportForm.PutHeader);
		EndIf;
		If FormAttributeExists(ReportForm, "PutFooter") Then
			AdditionalProperties.Insert("PutFooter", ReportForm.PutFooter);
		EndIf;
		If FormAttributeExists(ReportForm, "AppearanceTemplate") Then
			AdditionalProperties.Insert("AppearanceTemplate", ReportForm.AppearanceTemplate);
		EndIf;
	EndIf;
	
	If FormAttributeExists(ReportForm, "HideSettingsWhileGenerateReport") Then
		AdditionalProperties.Insert("HideSettingsWhileGenerateReport", ReportForm.HideSettingsWhileGenerateReport);
	EndIf;
	
	If FormItemExists(ReportForm, "GroupSettingsPanel") Then
		If Settings.AdditionalProperties.Property("SettingsPanelIsHiddenAutomatically")
			AND Settings.AdditionalProperties.SettingsPanelIsHiddenAutomatically = True Then
			AdditionalProperties.Insert("SettingsPanelVisible", True);
		Else
			AdditionalProperties.Insert("SettingsPanelVisible", ReportForm.Items.GroupSettingsPanel.Visible);
		EndIf;
	EndIf;
	
	Settings.AdditionalProperties.Insert("ReportData", New ValueStorage(AdditionalProperties));
	
EndProcedure

// Процедура обработчик "ПриЗагрузкеПользовательскихНастроекНаСервере" 
//
Procedure OnLoadUserSettingsAtServer(ReportForm, Settings, LoadAttributesOnly = False) Export

	If Settings = Undefined Then
		// Установка настроек по умолчанию
		// en script begin
		//БухгалтерскиеОтчетыВызовСервера.УстановитьНастройкиПоУмолчанию(ФормаОтчета);		
		// en script end
	Else 
		// Восстановление сохраненных настроек
		If Settings.AdditionalProperties.Property("ReportData") Then
			AdditionalProperties = Settings.AdditionalProperties.ReportData.Get();
			For Each StructureItem In AdditionalProperties Do
				// Восстановление реквизитов отчета
				If ReportForm.Report.Property(StructureItem.Key) Then
					If TypeOf(StructureItem.Value) = Type("ValueTable") Then
						ReportForm.Report[StructureItem.Key].Load(StructureItem.Value);
					ElsIf StructureItem.Key <> "DetailsMode" Then
						ReportForm.Report[StructureItem.Key] = StructureItem.Value;
					EndIf;
				EndIf;
				
				If NOT LoadAttributesOnly Then
					// Восстановление реквизитов формы
					If StructureItem.Key = "PutHeader" Then
						ReportForm.PutHeader = StructureItem.Value;
					ElsIf StructureItem.Key = "PutFooter" Then
						ReportForm.PutFooter = StructureItem.Value;
					ElsIf StructureItem.Key = "AppearanceTemplate" Then
						ReportForm.AppearanceTemplate = StructureItem.Value;
						fmReportsClientServer.SetOutputParamters(
							ReportForm.Report.SettingsComposer.Settings, 
							"AppearanceTemplate", ReportForm.AppearanceTemplate);
					EndIf;
				EndIf;
				If StructureItem.Key = "HideSettingsWhileGenerateReport" Then
					ReportForm.HideSettingsWhileGenerateReport = StructureItem.Value;		
				EndIf;
				If StructureItem.Key = "SettingsPanelVisible" Then
					If FormItemExists(ReportForm, "SettingsPanel") Then
						fmReportsClientServer.ChangeButtonTitleSettingsPanel(
							ReportForm.Items.SettingsPanel, AdditionalProperties.SettingsPanelVisible);
					EndIf;
					If FormItemExists(ReportForm, "GroupSettingsPanel") Then
 						ReportForm.Items.GroupSettingsPanel.Visible = AdditionalProperties.SettingsPanelVisible;
					EndIf;
				EndIf;
				//Если ФормаОтчета
			EndDo;
		EndIf;
		If NOT LoadAttributesOnly Then
			CurrentSettings = ReportForm.Report.SettingsComposer.Settings;
			
			// Установка пользовательских настроек
			CurrentSettings.Filter.UserSettingID              = "Filter";
			CurrentSettings.Order.UserSettingID            = "Order";
			CurrentSettings.ConditionalAppearance.UserSettingID = "ConditionalAppearance";
			CurrentSettings.Selection.UserSettingID              = "CASE";
			
			// Перенос пользовательских настроек в основные
			ReportForm.Report.SettingsComposer.LoadUserSettings(Settings);
			ReportForm.Report.SettingsComposer.LoadSettings(ReportForm.Report.SettingsComposer.GetSettings());
			
			// Очистка пользовательских настроек
			CurrentSettings = ReportForm.Report.SettingsComposer.Settings;
			CurrentSettings.Filter.UserSettingID              = "";
			CurrentSettings.Order.UserSettingID            = "";
			CurrentSettings.ConditionalAppearance.UserSettingID = "";
			CurrentSettings.Selection.UserSettingID              = "";
		EndIf;		
	EndIf;
	
	If FormAttributeExists(ReportForm, "MinimumPeriodType") Then
		MinimumPeriodType = ReportForm.MinimumPeriodType;
	Else
		MinimumPeriodType = Undefined;
	EndIf;
	
	If FormAttributeExists(ReportForm, "PeriodType") Then
		ReportForm.PeriodType = fmPeriodChoiceClientServer.GetPeriodType(
			ReportForm.Report.BeginOfPeriod, ReportForm.Report.EndOfPeriod, MinimumPeriodType);
	EndIf;
	
EndProcedure

// Функция обработчик "ЕстьРеквизитФормы" 
//
Function FormAttributeExists(Form, AttributeName) 
	
	For Each FormAttribute In Form.GetAttributes() Do
		If Upper(FormAttribute.Name) = Upper(AttributeName) Then
			Return True;
		EndIf;
	EndDo;
	
	Return False;
	
EndFunction

// Функция обработчик "ЕстьЭлементФормы" 
//
Function FormItemExists(Form, ItemName)
	
	Return Form.Items.Find(ItemName) <> Undefined;
	
EndFunction

// Процедура обработчик "ДобавитьОтборПоОрганизации" 
//
Procedure AddFilterByCompany(ReportParameters, SettingsComposer, ToUserSettings = True) Export
	
	If ValueIsFilled(ReportParameters.Company) Then
		If TypeOf(ReportParameters.Company) = Type("ValueList") Then 
			NewFilter = fmReportsClientServer.AddFilter(SettingsComposer, "Company", ReportParameters.Company, DataCompositionComparisonType.InList, ReportParameters.Company.Count() > 0, ToUserSettings);
		Else
			NewFilter = fmReportsClientServer.AddFilter(SettingsComposer, "Company", ReportParameters.Company, DataCompositionComparisonType.Equal, , ToUserSettings);
		EndIf;
		NewFilter.Presentation = "###FilterByCompany###"; 
	EndIf;
	
EndProcedure

// Процедура обработчик "ДобавитьОтборПоБалансоваяЕдиница" 
//
Procedure AddFilterByBalanceUnit(ReportParameters, SettingsComposer, ToUserSettings = True) Export
	
	If ValueIsFilled(ReportParameters.BalanceUnit) Then
		NewFilter = fmReportsClientServer.AddFilter(SettingsComposer, "BalanceUnit", ReportParameters.BalanceUnit, DataCompositionComparisonType.Equal, , ToUserSettings);
		NewFilter.Presentation = "###FilterByBalanceUnit###"; 
	EndIf;
	
EndProcedure

// Процедура обработчик "ДобавитьОтборПоБалансоваяЕдиница" 
//
Procedure AddFilterByScenario(ReportParameters, SettingsComposer, ToUserSettings = True) Export
	
	If ValueIsFilled(ReportParameters.Scenario) Then
		NewFilter = fmReportsClientServer.AddFilter(SettingsComposer, "Scenario", ReportParameters.Scenario, DataCompositionComparisonType.Equal, , ToUserSettings);
		NewFilter.Presentation = "###FilterByScenario###"; 
	EndIf;
	
EndProcedure

Procedure CopyComposerFilter(Source, Receiver) Export
	
	For Each FilterItem In Source Do
		If TypeOf(FilterItem) = Type("DataCompositionFilterItem") Then
			FillPropertyValues(Receiver.Add(Type("DataCompositionFilterItem")), FilterItem);
		Else
			NewGroup = Receiver.Add(Type("DataCompositionFilterItemGroup"));
			FillPropertyValues(NewGroup, FilterItem);
			CopyComposerFilter(FilterItem.Items, NewGroup.Items);
		EndIf;
	EndDo;

EndProcedure //СкопироватьОтборКомпоновщика()

// Возвращает сумму выделенных ячеек табличного документа.
//
// Параметры:
//	Результат - ТабличныйДокумент - Табличный документ, содержащий ячейки для суммирования.
//	КэшВыделеннойОбласти - Структура - Содержит ячейки выделенной области.
//
// Возвращаемое значение:
//	Число - Сумма значений ячеек.
//
Function EvalAmountOfSpreadsheetDocumentSelectedCells(VAL Result, SelectedAreaCache) Export
	
	Amount = 0;
	For Each KeyAndValue In SelectedAreaCache Do
		SelectedAreaAddressStructure = KeyAndValue.Value;
		fmReportsClientServer.EvalCellsAmount(Amount, SelectedAreaAddressStructure, Result);
	EndDo;
	
	SelectedAreaCache.Insert("Amount", Amount);
	
	Return Amount;
	
EndFunction

#EndRegion

#Region ProceduresAndFunctionsOfUnivarsalReportsProcessing

// Функция определяет, доступен ли элемент отбора с указанным именем для изменения имени, удаления, переименования
// используется в формах настройки отчетов на базе Построителя Отчетов для того, чтобы не удалить в форме
// настройки отбор, связанный с "быстрым отбором", находящимся на основной форме.
//
// Параметры:
//	ИмяЭлементаОтбора               - строка, содержит имя элемента отбора.
//	СтруктураСвязиЭлементовСДанными - структура, возвращаемая в один из параметров методом 
//                                    отУстановитьСвязьПолейБыстрогоОтбораНаФорме.
//
Function FilterIsLinkedWithData(FilterItemName, ItemsLinkStructure) Export

	If ItemsLinkStructure.Property("SettingsFlag"+FilterItemName)
		OR ItemsLinkStructure.Property("ComparisonTypeField"+FilterItemName)
		OR ItemsLinkStructure.Property("SettingField"+FilterItemName)
		OR ItemsLinkStructure.Property("SettingFieldFrom"+FilterItemName)
		OR ItemsLinkStructure.Property("SettingFieldTo"+FilterItemName) Then

		Return True;

	Else

		Return False;

	EndIf;

EndFunction //отОтборСвязанСДанными()

// Возвращает рассчитанное значение финансового показателя.
// 
// Параметры: 
//  Показатель – Строка или фин. показатель – код или непосредственно фин. показатель, который необходимо рассчитать.
//  СтруктураПараметров – Структура – структура, содержащая устанавливаемые фильтры для расчета показателя.
//  СтруктураОкругления – Структура – структура, содержащая параметры округления показателя.
//  СтркутураДопПараметов - Структура – структура дополнительных параметров. 
// 
// Возвращаемое значение: 
//  Число - значение рассчитанного финансового показателя, в случае возникновения ошибок - возвращаемое значение 0.
Function CalculateFinIndicatorValue(Indicator, ParametersStructure = Undefined, RoundStructure  = Undefined, AddParametersStructure = Undefined) Export
	
	If TypeOf(Indicator) = Type("String") Then
		// Найдем фин показатель по значению реквизита КодВОтчете
		FinIndicator = Catalogs.fmFinancialIndicators.FindByAttribute("CodeInReport", Indicator);
		If FinIndicator.IsEmpty() Then
			// В случае отсутствия в базе показателя возвращаем 0.
			CommonClientServer.MessageToUser(StrTemplate(NStr("ru = ''Финансовый показатель с кодом: <%1> отсутствует в базе. Возвращаемое значение 0'"), Indicator));
			Return 0;
		EndIf;
	Else
		FinIndicator = Indicator;
	EndIf;
	
	// если установлен параметр Отключить, то возвращаем 0
	If FinIndicator.Disable Then
		CommonClientServer.MessageToUser(StrTemplate(NStr("en='Used indicator <%1> is disabled. Return value 0';ru='Используемый показатель <%1> отключен. Возвращаемое значение 0'"), TrimAll(FinIndicator)));
		Return 0;
	EndIf;	
	
	FinancialIndicatorType = FinIndicator.FinancialIndicatorType;
	// Если показатель является группой, то просуммируем значение всех входящих в него элементов.
	If FinIndicator.IsFolder Then
		Selection = Catalogs.fmFinancialIndicators.SelectHierarchically(FinIndicator);
		Result = 0;
		While Selection.Next() Do
			If NOT Selection.IsFolder Then
				Result = Result + CalculateFinIndicatorValue(Selection.CodeInReport, ParametersStructure, RoundStructure, AddParametersStructure);
			EndIf;	
		EndDo;	
		Return Result;
		
	ElsIf FinancialIndicatorType = Enums.fmFinancialIndicatorTypes.CalculationOnAnotherIndicators Then
		FormulaString = FinIndicator.Formula;
		Length = StrLen(FormulaString);
		
		OperandTable = New ValueTable();
		OperandTable.Columns.Add("Operand");
		
		CurNum = 1;
		// найдем в строке с формулой коды финансовых показателей
		While CurNum <= Length Do
			If Mid(FormulaString, CurNum, 1) = "[" Then
				NewLine = OperandTable.Add();
				NewLine.Operand = "";
				CurNum = CurNum + 1;
				While Mid(FormulaString, CurNum, 1) <> "]" Do
					NewLine.Operand = NewLine.Operand + Mid(FormulaString, CurNum, 1);
					CurNum = CurNum + 1;
				EndDo;	
			EndIf;
			CurNum = CurNum + 1;
		EndDo;
		
		// расчитаем значения показателей из формулы и подставим их значения в формулу
		For Each CurRow In OperandTable Do
			FormulaString = StrReplace(FormulaString, "[" + CurRow.Operand + "]", "(" + Format(CalculateFinIndicatorValue(CurRow.Operand, ParametersStructure, RoundStructure, AddParametersStructure), "NZ=; NG=") + ")");  
		EndDo;
		
		FormulaString = "Result = " + FormulaString + "; ";
		FormulaString = StrReplace(FormulaString, ",", ".");
		
		// рассчитаем формулу
		Result = 0;
		Try
			Execute(FormulaString);
			Return Result; 
		Except
			CommonClientServer.MessageToUser(StrTemplate(NStr("en='Error of indicator calculation <%1>. Return value 0. %2';ru='Ошибка при расчета показателя <%1>. Возвращаемое значение 0. %2'"), TrimAll(FinIndicator), ErrorDescription()));
			Return 0;			
		EndTry;
		
	ElsIf FinancialIndicatorType = Enums.fmFinancialIndicatorTypes.EvalInBuiltInLanguage Then	
		
		// рассчитаем значение фин показателя 
		FinIndicatorValue = 0;
		EvalAlgorithm = FinIndicator.EvalAlgorithm;
		
		// Установим необходимые фильтры для расчета значения показателя из переданной структуры.
		If ParametersStructure <> Undefined Then
			For Each CurParameter In ParametersStructure Do
				EvalAlgorithm = StrReplace(EvalAlgorithm, "$" + CurParameter.Key, "ParametersStructure." + CurParameter.Key);
			EndDo;
		Else
			// в случае отсутствия параметров заменим их на пустые значения
			EvalAlgorithm = StrReplace(EvalAlgorithm, "$Company", "Catalogs.fmCompanies.EmptyRef()");
			EvalAlgorithm = StrReplace(EvalAlgorithm, "$BeginOfPeriod", "DATE(""00010101000000"")");
			EvalAlgorithm = StrReplace(EvalAlgorithm, "$EndOfPeriod", "DATE(""00010101000000"")");
		EndIf;
		
		Try
			Execute(EvalAlgorithm);
			
			// округлим при необходимости рассчитываемый показатель
			If FinIndicator.DontRound OR RoundStructure = Undefined Then
				Return FinIndicatorValue;
			Else
				Return (Round(FinIndicatorValue / RoundStructure.MeasurementUnit, 0, ?(RoundStructure.OneAndHalfAsTwo, 1, 0)) * RoundStructure.MeasurementUnit);
			EndIf;
			
			Return FinIndicatorValue; 
		Except
			CommonClientServer.MessageToUser(StrTemplate(NStr("en='Error of indicator calculation <%1>. Return value 0. %2';ru='Ошибка при расчета показателя <%1>. Возвращаемое значение 0. %2'"), TrimAll(FinIndicator), ErrorDescription()));
			Return 0;
		EndTry;
		
	Else
		
		// Вычислим значение фин. показателя при помощи сохраненого отбора на СКД.
		// Получим исходные данные.
		AccountingRegisterName = FinIndicator.AccountingRegisterName;
		ReportType = FinIndicator.ReportType;
		If ReportType = Enums.fmUniversalReportTypes.FinancialReports Then
			Resource = FinIndicator.Resource;
		Else
			AddParametersStructure.Property("Resource", Resource);
		EndIf;
		// Если выводим не в валюте МСФО, то необходимо обработать ресурс "Сумма" и заменить на "СуммаДоп".
		If NOT AddParametersStructure = Undefined AND AddParametersStructure.Property("InIFRSCurrency") AND NOT AddParametersStructure.InIFRSCurrency
		AND AccountingRegisterName = "fmInternational" AND Left(Resource, 5) = "Amount" Then
			Resource = StrReplace(Resource, "Amount", "AddAmount");
		EndIf;
		
		// Создадим схему для отработки отбора.
		Schema = New DataCompositionSchema;
		DataSource = Schema.DataSources.Add();
		DataSource.Name = "DataSource1";
		DataSource.DataSourceType = "Local";
		DataSetQuery = Schema.DataSets.Add(Type("DataCompositionSchemaDataSetQuery"));
		DataSetQuery.Name = "DataSet1";
		DataSetQuery.DataSource= "DataSource1";
		
		// Соберем текст запрос для СКД, в зависимости от значения фин показателя используем разные виртуальные таблицы регистра бухгалтерии.
		QueryText = "SELECT ALLOWED RequiredRegister." + Resource + " AS " + Resource + " ";
		If ReportType = Enums.fmUniversalReportTypes.AnalyticalReport Then
			// добавим измерения колонки в выбранные строки.
			For Each CurDimension In AddParametersStructure.ColumnGrouping Do
				QueryText = QueryText + ", RequiredRegister." + CurDimension.Field + " AS ColumnAnalytics";
			EndDo;
			// добавим измерения строки в выбранные строки.
			For Each CurDimension In AddParametersStructure.Groups Do
				QueryText = QueryText + ", RequiredRegister." + CurDimension.Field + " AS RowAnalytics" + CurDimension.LineNumber;
			EndDo;
		EndIf;
		If FinancialIndicatorType = Enums.fmFinancialIndicatorTypes.AccountingRegisterBalances Then
			QueryText = QueryText + "
			|FROM
			|	AccountingRegister." + AccountingRegisterName + ".Balances AS RequiredRegister";
		ElsIf FinancialIndicatorType = Enums.fmFinancialIndicatorTypes.AccountingRegisterTurnovers Then
			QueryText = QueryText + "
			|FROM
			|	AccountingRegister." + AccountingRegisterName + ".Turnovers AS RequiredRegister";
		EndIf;
		DataSetQuery.Query = QueryText;
		
		// Прочитаем сохраненные правила.
		ReaderXML = New XMLReader();
		DataCompositionSettingsXML = FinIndicator.FilterSettings.Get();
		ReaderXML.SetString(DataCompositionSettingsXML);
		DataCompositionSettingsRules = XDTOSerializer.ReadXML(ReaderXML);
		
		// Скопируем прочитанные правила в настройки компоновки данных, подходщей для нашей схемы.
		DCSettingsComposer = New DataCompositionSettingsComposer;
		DCSettingsComposer.Initialize(New DataCompositionAvailableSettingsSource(Schema));
		DataCompositionSettings = DCSettingsComposer.GetSettings();
		fmDataCompositionClientServer.CopyItems(DataCompositionSettings.Filter, DataCompositionSettingsRules.Filter);
		
		// Проанализируем доп. параметры.
		If ParametersStructure <> Undefined Then
			
			// Проанализируем вид показателя, вид остатка  и добавим при необходимости параметр период.
			If FinancialIndicatorType = Enums.fmFinancialIndicatorTypes.AccountingRegisterBalances Then
				If FinIndicator.BalanceType = Enums.fmBalanceTypes.ClosingBalance Then
					ParametersStructure.Insert("Period", ParametersStructure.EndOfPeriod);
				Else
					ParametersStructure.Insert("Period", ParametersStructure.BeginOfPeriod);
				EndIf;
			EndIf;
			
			// Установим необходимые фильтры для расчета значения показателя из переданной структуры.
			For Each CurParameter In ParametersStructure Do
				If CurParameter.Value <> Undefined Then
					If CurParameter.Key = "Period" OR CurParameter.Key = "BeginOfPeriod" OR CurParameter.Key = "EndOfPeriod" Then
						For Each CurDCSParameter In DataCompositionSettings.DataParameters.Items Do
							If CurDCSParameter.Parameter = New DataCompositionParameter(CurParameter.Key) Then
								CurDCSParameter.Value = CurParameter.Value;
								CurDCSParameter.Use = True;
							EndIf;
						EndDo;
					Else
						FilterItem = DataCompositionSettings.Filter.Items.Add(Type("DataCompositionFilterItem"));
						FilterItem.LeftValue = New DataCompositionField(CurParameter.Key);
						If CurParameter.Key = "Account" Then
							FilterItem.ComparisonType = DataCompositionComparisonType.InHierarchy;
						Else
							If TypeOf(CurParameter.Value) = Type("ValueList") Then
								// Если список пуст, значит по всем организациям отбор происходит.
								If CurParameter.Value.Count() = 0 Then
									FilterItem.ComparisonType = DataCompositionComparisonType.NotInList;
								Else
									FilterItem.ComparisonType = DataCompositionComparisonType.InList;
								EndIf;
							Else
								FilterItem.ComparisonType = DataCompositionComparisonType.Equal;
							EndIf;
						EndIf;
						FilterItem.RightValue = CurParameter.Value;
					EndIf;
				EndIf;
			EndDo;
		EndIf;
		
		// Если валютный ресурс, то добавим отбор по валюте.
		If Left(Resource, 8) = "Currency" AND AddParametersStructure.Property("Currency") Then
			FilterItem = DataCompositionSettings.Filter.Items.Add(Type("DataCompositionFilterItem"));
			FilterItem.LeftValue = New DataCompositionField("Currency");
			FilterItem.ComparisonType = DataCompositionComparisonType.Equal;
			FilterItem.RightValue = AddParametersStructure.Currency;
		EndIf;
		
		// Добавим необходимые выбранные поля.
		SelectedField = DataCompositionSettings.Selection.Items.Add(Type("DataCompositionSelectedField"));
		SelectedField.Field = New DataCompositionField(Resource);
		GroupDetailedRecords = DataCompositionSettings.Structure.Add(Type("DataCompositionGroup"));
		GroupField = GroupDetailedRecords.GroupFields.Items.Add(Type("DataCompositionGroupField"));
		GroupField.Use = True;
		SelectedGroupField = GroupDetailedRecords.Selection.Items.Add(Type("DataCompositionSelectedField"));
		SelectedGroupField.Field = New DataCompositionField(Resource);
		If ReportType = Enums.fmUniversalReportTypes.AnalyticalReport Then
			// добавим измерения колонки в выбранные строки.
			For Each CurDimension In AddParametersStructure.ColumnGrouping Do
				SelectedField = DataCompositionSettings.Selection.Items.Add(Type("DataCompositionSelectedField"));
				SelectedField.Field = New DataCompositionField("ColumnAnalytics");
				SelectedField.Title = CurDimension.Presentation;
				SelectedGroupField = GroupDetailedRecords.Selection.Items.Add(Type("DataCompositionSelectedField"));
				SelectedGroupField.Field = New DataCompositionField("ColumnAnalytics");
				SelectedGroupField.Title = CurDimension.Presentation;
			EndDo;
			// добавим измерения строки в выбранные строки.
			For Each CurDimension In AddParametersStructure.Groups Do
				SelectedField = DataCompositionSettings.Selection.Items.Add(Type("DataCompositionSelectedField"));
				SelectedField.Field = New DataCompositionField("RowAnalytics" + CurDimension.LineNumber);
				SelectedField.Title = CurDimension.Presentation;
				SelectedGroupField = GroupDetailedRecords.Selection.Items.Add(Type("DataCompositionSelectedField"));
				SelectedGroupField.Field = New DataCompositionField("RowAnalytics" + CurDimension.LineNumber);
				SelectedGroupField.Title = CurDimension.Presentation;
			EndDo;
		EndIf;

		// Применим настройку компоновки данных к схеме.
		TemplateComposer = New DataCompositionTemplateComposer;
		CompositionTemplate = TemplateComposer.Execute(Schema, DataCompositionSettings, , , Type("DataCompositionValueCollectionTemplateGenerator"));
		
		// инициализация процессора СКД
		DataCompositionProcessor = New DataCompositionProcessor;
		DataCompositionProcessor.Initialize(CompositionTemplate);
		// инициализация процессора вывода
		OutputProcessor = New DataCompositionResultValueCollectionOutputProcessor;
		Result = New ValueTable;
		OutputProcessor.SetObject(Result);
		OutputProcessor.Output(DataCompositionProcessor);
		
		If ReportType = Enums.fmUniversalReportTypes.FinancialReports Then
			// возвращаем первое значение результата запроса, если оно есть
			If Result.Count()>0 Then
				IndicatorValue = Result[0][Resource];
				// округлим при необходимости рассчитываемый показатель
				If FinIndicator.DontRound OR RoundStructure = Undefined Then
					Return IndicatorValue;
				Else
					Return (Round(IndicatorValue / RoundStructure.MeasurementUnit, 0, ?(RoundStructure.OneAndHalfAsTwo, 1, 0)) * RoundStructure.MeasurementUnit);
				EndIf;	
			Else
				Return 0;
			EndIf;
		Else
			Result.Columns[Resource].Name = "Indicator";
			Return Result;
		EndIf;
		
	EndIf;
	
EndFunction //РассчитатьЗначениеФинПоказателя(ФинПоказатель)

// Возвращает массив измерений в зависимости от регистра бухгалтерии и вида показателя.
// 
// Параметры: 
//  ИмяРегистраБухгалтерии – Строка – имя регистра бухгалтерии.
//  ВидФинансовогоПоказателя – Перечисление – вид фин. показателя.
// 
// Возвращаемое значение: 
//  Массив
Function GetDimensionArray(AccountingRegisterName, FinancialIndicatorType) Export
	
	DimensionArray = New Array();
	DimensionArray.Add("Account");
	If FinancialIndicatorType = Enums.fmFinancialIndicatorTypes.AccountingRegisterTurnovers Then
		DimensionArray.Add("CorAccount");
	EndIf;
	For Counter = 1 To Metadata.ChartsOfAccounts[AccountingRegisterName].MaxExtDimensionCount Do
		DimensionArray.Add("ExtDimension" + Counter);
		If FinancialIndicatorType = Enums.fmFinancialIndicatorTypes.AccountingRegisterTurnovers Then
			DimensionArray.Add("CorExtDimension" + Counter);
		EndIf;
	EndDo;
	For Counter=0 To Metadata.AccountingRegisters[AccountingRegisterName].Dimensions.Count()-1 Do
		DimensionArray.Add(Metadata.AccountingRegisters[AccountingRegisterName].Dimensions.Get(Counter).Name);
		If NOT Metadata.AccountingRegisters[AccountingRegisterName].Dimensions.Get(Counter).Balance 
			AND FinancialIndicatorType = Enums.fmFinancialIndicatorTypes.AccountingRegisterTurnovers Then
			DimensionArray.Add(Metadata.AccountingRegisters[AccountingRegisterName].Dimensions.Get(Counter).Name + "Cor");
		EndIf;
	EndDo;
	
	Return DimensionArray;
	
EndFunction

// Процедура генерирует код перемещаемого элемента (группы) справочника,
// а также код расположенного рядом элемента при интерактивном перемещении
// элемента в форме списка справочника.
// Записывает переставляемые элементы с измененными кодами.
// В случае сдвига группы элементов также изменяет коды вложенных в группу
// элементов.
//
// Параметры
//  Направление  – число – напрвление сдвига элемента,
//                 принимает значения:
//                      1 - при сдвиге вниз;
//                     -1 - при сдвиге вверх.
//
Procedure ChangeCode(Ref, Direction, CatalogName) Export
	
	CurrentCode    = Ref.Code;
	
	CodeList   = New ValueList;
	
	BudgetItems  = Catalogs[CatalogName];
	RowSelection  = BudgetItems.SELECT(Ref.Parent, Ref.Owner, , "Code DESC");
	
	While RowSelection.Next() Do
		CodeList.Add(RowSelection.Code);
	EndDo;
	
	If CodeList.Count() < 2  Then
		// На данном уровне имеется только один элемент или группа справочника.
		// Игнорируем действие пользователя.
		
		Return;
	EndIf; 
	
	SerialNumber = CodeList.IndexOf(CodeList.FindByValue(CurrentCode));
	
	If (SerialNumber = 0) AND (Direction < 0) Then
		
		// Попытка перемещения первого по порядку элемента вверх.
		ReplaceItemIndex = CodeList.Count() - 1;
		
	ElsIf (SerialNumber = CodeList.Count() - 1) AND (Direction > 0) Then
		
		// Попытка перемещения последнего по порядку элемента вниз.
		ReplaceItemIndex = 0;
		
	Else
		
		// в иных случаях
		ReplaceItemIndex = SerialNumber + Direction;
		
	EndIf;
	
	ReplaceItemCode     = CodeList.Get(ReplaceItemIndex).Value;
	
	ReplaceItemRef   = BudgetItems.FindByCode(ReplaceItemCode,,Ref.Parent, Ref.Owner);
	If ReplaceItemRef <> BudgetItems.EmptyRef() Then
		
		Try
			
			// Открываем транзакцию
			BeginTransaction();
			
			ThisObject = Ref.GetObject();
			
			// Промежуточная запись текущего элемента с уникальным кодом
			ThisObject.Code = "&&$##";
			ThisObject.Write();
			
			// записываем соседний элемент с кодом текущего
			ReplaceItem = ReplaceItemRef.GetObject();
			PreviousCode = ReplaceItem.Code;
			ReplaceItem.Code = CurrentCode;
			ReplaceItem.Write();
			
			// записываем текущий элемент с кодом соседнего
			ThisObject.Code = PreviousCode;
			ThisObject.Write();
			
			// Завершаем транзакцию
			CommitTransaction();
			
		Except
			CommonClientServer.MessageToUser(StrTemplate(NStr("en='Failed to write catalog item:%1';ru='Не удалось записать элемент справочника:%1'"),ErrorDescription()));
			
			Return;
		EndTry;
		
	EndIf;
	
EndProcedure // ИзменитьКод()

#EndRegion

#Region ProceduresAndFunctionOfPeriodProcessing

// Функция определяет границу периода, вторую, по отношению к переданному параметру
//
// Параметры
//  ПериодСсылка  - тип периода, ПеречислениеСсылка
//  НачалоПериода - Булево, если истина то определяем начало периода, иначе конец
//  ДатаПериода   - Дата, относительно которой будет определяться вторая граница.
//
// Возвращаемое значение:
//  Дата - вторая граница периода.
//
Function DeterminateSecondPeriodBound(PeriodRef, BeginOfPeriod, PeriodDate) Export

	If BeginOfPeriod Then
		PeriodDate = EndOfDay(PeriodDate);
	Else
		PeriodDate = BegOfDay(PeriodDate);
	EndIf; 
	
	If PeriodRef = Enums.Periodicity.Day Then
		If BeginOfPeriod Then
			Return (PeriodDate - 60*60*24 + 1);
		Else
			Return (PeriodDate + 60*60*24 - 1);
		EndIf; 

	ElsIf PeriodRef = Enums.Periodicity.Week Then

		If BeginOfPeriod Then
			Return (PeriodDate - 60*60*24*7 + 1);
		Else
			Return (PeriodDate + 60*60*24*7 - 1);
		EndIf; 

	ElsIf PeriodRef = Enums.Periodicity.Month Then

		If BeginOfPeriod Then
			Return AddMonth(PeriodDate, -1) + 1;
		Else
			Return AddMonth(PeriodDate, 1) - 1;
		EndIf; 

	ElsIf PeriodRef = Enums.Periodicity.Quarter Then

		If BeginOfPeriod Then
			Return AddMonth(PeriodDate, -3) + 1;
		Else
			Return AddMonth(PeriodDate, 3) - 1;
		EndIf; 

	ElsIf PeriodRef = Enums.Periodicity.Year Then

		If BeginOfPeriod Then
			Return AddMonth(PeriodDate, -12) + 1;
		Else
			Return AddMonth(PeriodDate, 12) - 1;
		EndIf; 

	Else

		Return '00010101000000';

	EndIf; 

EndFunction // КоличествоСекундПериода()

// Возвращает строковое представление произвольного значения перечисления.
// 
// Параметры: 
//  ЗначениеПеречисления – Перечисление – Произвольное значение перечисления.
// 
// Возвращаемое значение: 
//  Строка - строковое представление значения перечисления.
Function GetEnumNameByValue(EnumValue) Export
	
	Return TrimAll(EnumValue);
	
EndFunction //ПолучитьИмяПеречисленияПоЗначению()

// Возвращает результат сложения даты со значением перечисления Периодичность.
// 
// Параметры: 
//  Дата – Дата – дата, к которой необходимо прибавить период.
//	Период - Перечисление - периодичность, которую необходимо прибавить к дате.
// 
// Возвращаемое значение: 
//  Дата - результат сложения даты и периода.
Function AddToDate(DATE, Period)
	
	// величина суток в секундах
	Day = 60 * 60 * 24;
	
	If Period = Enums.Periodicity.Year Then
		Return AddMonth(DATE, 12);
	ElsIf Period = Enums.Periodicity.HalfYear Then
		Return AddMonth(DATE, 6);
	ElsIf Period = Enums.Periodicity.Month Then
		Return AddMonth(DATE, 1);
	ElsIf Period = Enums.Periodicity.Quarter Then
		Return AddMonth(DATE, 3);
	ElsIf Period = Enums.Periodicity.Day Then
		Return (DATE + Day);
	ElsIf Period = Enums.Periodicity.TenDays Then
		Return (DATE + Day * 10);
	ElsIf Period = Enums.Periodicity.Week Then
		Return (DATE + Day * 7);
	Else
		Return DATE;
	EndIf;	
	
EndFunction //ДобавитьКДате()	

// Возвращает таблицу периодов, сформированных на основе входящий параметров.
// 
// Параметры: 
//  ДатаНач – Дата – дата, c которой начинается формирование периодов.
//  ДатаКон – Дата – дата, на которой заканчивается формирование периодов.
//	Периодичность - Перечисление - периодичность, с которой формируются результирующие периоды
//	Шаг - Перечисление - периодичность нарастания периода в пределах параметра Периодичность.
// 
// Возвращаемое значение: 
//  ТабРезультатов - таблица значений, содержащая сформированные периоды.
Function FormPeriods(DataBeg, DataEnd, Periodicity, Step) Export
	
	// сформируем формат возвращаемой таблицы
	ResultTable = New ValueTable();
	ResultTable.Columns.Add("DataBeg");
	ResultTable.Columns.Add("DataEnd");
	ResultTable.Columns.Add("PeriodDescription");	
	
	CurDate = DataBeg;
	PeriodicityCounter = 1;
	StepCounter = 1;
	While CurDate <= DataEnd Do
		// если шаг не заполнен, значит формируем простые периоды без нарастания
		If NOT ValueIsFilled(Step) Then
			NewLine =  ResultTable.Add();
			NewLine.DataBeg = CurDate;
			CurDate = AddToDate(CurDate, Periodicity);
			If BegOfYear(CurDate - 1) > BegOfYear(NewLine.DataBeg) Then
				PeriodicityCounter = 1;
			EndIf;	
			NewLine.DataEnd = ?(CurDate > DataEnd, DataEnd, CurDate - 1);
			NewLine.PeriodDescription = FormPeriodDescription(NewLine.DataBeg, NewLine.DataEnd, Periodicity, Step, PeriodicityCounter, StepCounter);
			PeriodicityCounter = PeriodicityCounter + 1;
		Else
			CurDateEnd = ?(Periodicity.IsEmpty(), DataEnd, AddToDate(CurDate, Periodicity));
			CurDateEnd = ?(CurDateEnd > DataEnd, DataEnd, CurDateEnd - 1);
			CurDateStep = CurDate;
			While CurDateStep <= CurDateEnd Do
				NewLine =  ResultTable.Add();
				NewLine.DataBeg = CurDate;
				CurDateStep = AddToDate(CurDateStep, Step);
				NewLine.DataEnd = ?(CurDateStep > CurDateEnd, CurDateEnd, CurDateStep - 1);
				NewLine.PeriodDescription = FormPeriodDescription(NewLine.DataBeg, NewLine.DataEnd, Periodicity, Step, PeriodicityCounter, StepCounter);
				StepCounter = StepCounter + 1;
			EndDo;
			StepCounter = 1;
			PeriodicityCounter = PeriodicityCounter + 1;
			CurDate = ?(Periodicity.IsEmpty(), DataEnd + 1, AddToDate(CurDate, Periodicity));		
		EndIf;
	EndDo;
	
	Return ResultTable;
		
EndFunction //СформироватьПериоды()

// Возвращает текстовое представление периода в зависимости от входящих параметров.
// 
// Параметры: 
//  ДатаНач – Дата – дата, c которой начинается период.
//  ДатаКон – Дата – дата, на которой заканчивается период.
//	Периодичность - Перечисление - периодичность, с которой формируются результирующие периоды
//	Шаг - Перечисление - периодичность нарастания периода в пределах параметра Периодичность
//	СчетчикПериодичности - Число - номер периода
//	СчетчикШага - Число - номер шага.
// 
// Возвращаемое значение: 
//  Строка - строка, содержащая наименование периода.
Function FormPeriodDescription(VAL DataBeg,VAL DataEnd, Periodicity, Step, PeriodicityCounter, StepCounter)
	
	DataBeg = BegOfDay(DataBeg);
	DataEnd = EndOfDay(DataEnd);
	If ValueIsFilled(Step) AND ValueIsFilled(Periodicity) Then
		StepDescr = FormPeriodDescription(DataBeg, DataEnd, Enums.Periodicity.EmptyRef(), Step, PeriodicityCounter, StepCounter);
		PeriodDescr = FormPeriodDescription(DataBeg, DataEnd, Periodicity, Enums.Periodicity.EmptyRef(), PeriodicityCounter, StepCounter);
		Return StepDescr + " (" + PeriodDescr + ")";
	ElsIf ValueIsFilled(Periodicity) Then
		If Periodicity = Enums.Periodicity.Year Then
			Return StrTemplate(NStr("en='%1 year';ru='%1 год'"), Format(Year(DataBeg), "NG="));
		ElsIf Periodicity = Enums.Periodicity.HalfYear Then
			If DataBeg = BegOfYear(DataBeg) Then
				Return StrTemplate(NStr("en='1st half year of %1';ru='1-ое полугодие %1 года'"), Format(Year(DataBeg), "NG="));
			Else
				Return StrTemplate(NStr("en='2nd half year of %1';ru='2-ое полугодие %1 года'"), Format(Year(DataBeg), "NG="));
			EndIf;
		ElsIf Periodicity = Enums.Periodicity.Quarter Then 	
			If DataBeg = BegOfYear(DataBeg) Then
				Return StrTemplate(NStr("en='1st quarter %1 year';ru='1-ый квартал %1 года'"), Format(Year(DataBeg), "NG="));
			ElsIf DataEnd = EndOfYear(DataEnd) Then 
				Return StrTemplate(NStr("en='4th quarter %1 year';ru='4-ый квартал %1 года'"), Format(Year(DataBeg), "NG="));
			ElsIf DataBeg = AddMonth(BegOfYear(DataBeg), 3) Then
				Return StrTemplate(NStr("en='2nd quarter %1 year';ru='2-ой квартал %1 года'"), Format(Year(DataBeg), "NG="));
			ElsIf DataBeg = AddMonth(BegOfYear(DataBeg), 6) Then
				Return StrTemplate(NStr("en='3rd quarter %1 year';ru='3-ий квартал %1 года'"), Format(Year(DataBeg), "NG="));				
			EndIf;
		ElsIf Periodicity = Enums.Periodicity.Month Then
			Description = "";
			If Month(DataBeg) = 1 Then
				Description = NStr("en='January';ru='Январь'");
			ElsIf Month(DataBeg) = 2 Then
				Description = NStr("en='February';ru='Февраль'");
			ElsIf Month(DataBeg) = 3 Then
				Description = NStr("en='March';ru='Март'");
			ElsIf Month(DataBeg) = 4 Then
				Description = NStr("en='April';ru='Апрель'");
			ElsIf Month(DataBeg) = 5 Then
				Description = NStr("en='May';ru='Май'");
			ElsIf Month(DataBeg) = 6 Then
				Description = NStr("en='June';ru='Июнь'");
			ElsIf Month(DataBeg) = 7 Then
				Description = NStr("en='July';ru='Июль'");
			ElsIf Month(DataBeg) = 8 Then
				Description = NStr("en='August';ru='Август'");
			ElsIf Month(DataBeg) = 9 Then
				Description = NStr("en='September';ru='Сентябрь'");
			ElsIf Month(DataBeg) = 10 Then
				Description = NStr("en='October';ru='Октябрь'");
			ElsIf Month(DataBeg) = 11 Then
				Description = NStr("en='November';ru='Ноябрь'");
			ElsIf Month(DataBeg) = 12 Then
				Description = NStr("en='December';ru='Декабрь'");
			EndIf;					
				
			Return StrTemplate(NStr("en='%1 %2 year';ru='%1 %2 года'"), Description, Format(Year(DataBeg), "NG="));
		ElsIf Periodicity = Enums.Periodicity.Week Then
			Return StrTemplate(NStr("en='%1 week %2 year';ru='%1-ая неделя %2 года'"), String(PeriodicityCounter), Format(Year(DataBeg), "NG="));
		ElsIf Periodicity = Enums.Periodicity.TenDays Then
			Return StrTemplate(NStr("en='%1st decade %2 year';ru='%1-ая декада %2 года'"), String(PeriodicityCounter), Format(Year(DataBeg), "NG="));			
		ElsIf Periodicity = Enums.Periodicity.Day Then	
			Return StrTemplate(NStr("ru = '%1'"), Format(DataBeg, "DLF=DD"));
		EndIf;	
	ElsIf ValueIsFilled(Step) Then
		Description = "";
		If Step = Enums.Periodicity.Year Then
			If StepCounter = 1 Then
				Description = NStr("en='year';ru='год'");
			ElsIf StepCounter > 1 AND StepCounter < 5 Then
				Description = NStr("en='year';ru='года'");
			Else
				Description = NStr("en='years';ru='лет'");
			EndIf;				
		ElsIf Step = Enums.Periodicity.HalfYear Then
			If StepCounter = 1 Then
				Description = NStr("en='half a year';ru='полугодие'");
			ElsIf StepCounter > 1 AND StepCounter < 5 Then
				Description = NStr("en='half a year';ru='полугодия'");
			Else
				Description = NStr("en='half year';ru='полугодий'");
			EndIf;
		ElsIf Step = Enums.Periodicity.Quarter Then
			If StepCounter = 1 Then
				Description = NStr("en='quarter';ru='квартал'");
			ElsIf StepCounter > 1 AND StepCounter < 5 Then
				Description = NStr("en='quarter';ru='квартала'");
			Else
				Description = NStr("en='quarters';ru='кварталов'");
			EndIf;
		ElsIf Step = Enums.Periodicity.Month Then
			If StepCounter = 1 Then
				Description = NStr("en='a month';ru='месяц'");
			ElsIf StepCounter > 1 AND StepCounter < 5 Then
				Description = NStr("en='month';ru='месяца'");
			Else
				Description = NStr("en='months';ru='месяцев'");
			EndIf;
		ElsIf Step = Enums.Periodicity.TenDays Then
			If StepCounter = 1 Then
				Description = NStr("ru = 'декаду'");
			ElsIf StepCounter > 1 AND StepCounter < 5 Then
				Description = NStr("en='decades';ru='декады'");
			Else
				Description = NStr("ru = 'декад");
			EndIf;
		ElsIf Step = Enums.Periodicity.Week Then
			If StepCounter = 1 Then
				Description = NStr("en='a week';ru='неделю'");
			ElsIf StepCounter > 1 AND StepCounter < 5 Then
				Description = NStr("en='weeks';ru='недели'");
			Else
				Description = NStr("en='weeks';ru='недель'");
			EndIf;	
		ElsIf Step = Enums.Periodicity.Day Then
			If StepCounter = 1 Then
				Description = NStr("en='day';ru='день'");
			ElsIf StepCounter > 1 AND StepCounter < 5 Then
				Description = NStr("en='day';ru='дня'");
			Else
				Description = NStr("en='days';ru='дней'");
			EndIf;										
		EndIf;

		Return StrTemplate(NStr("en='For %1 %2';ru='За %1 %2'"), String(StepCounter), Description);
						
	EndIf;	
	
	Return "";
	
EndFunction //СформироватьНаименованиеПериода()	

Function GetAvailableReportPeriods() Export
	
	AvailableReportPeriods = New Structure;
	For Each EnumValue In Metadata.Enums.fmAvailableReportPeriods.EnumValues Do
		AvailableReportPeriods.Insert(
			EnumValue.Name, Enums.fmAvailableReportPeriods[EnumValue.Name]);
	EndDo;
	
	Return AvailableReportPeriods;
	
EndFunction

Procedure GetAvailablePeriodList(MinimumPeriod, PeriodList, DefaultValue = Undefined) Export
	
	If TypeOf(PeriodList) <> Type("ValueList") Then
		Return;
	EndIf;
	
	AvailablePeriodList = New ValueList;
	AvailablePeriodList.Add(Enums.fmAvailableReportPeriods.Day);
	AvailablePeriodList.Add(Enums.fmAvailableReportPeriods.Week);
	AvailablePeriodList.Add(Enums.fmAvailableReportPeriods.TenDays);
	AvailablePeriodList.Add(Enums.fmAvailableReportPeriods.Month);
	AvailablePeriodList.Add(Enums.fmAvailableReportPeriods.Quarter);
	AvailablePeriodList.Add(Enums.fmAvailableReportPeriods.HalfYear);
	AvailablePeriodList.Add(Enums.fmAvailableReportPeriods.Year);
	
	AvailablePeriodList.Add(Enums.fmAvailableReportPeriods.ArbitraryPeriod);
	
	ItemList = AvailablePeriodList.FindByValue(MinimumPeriod);
	If ItemList <> Undefined Then
		ItemIndex = AvailablePeriodList.IndexOf(ItemList);
		For Counter = ItemIndex To AvailablePeriodList.Count() - 1 Do
			Period = AvailablePeriodList.Get(Counter);
			PeriodList.Add(Period.Value, Period.Presentation);
		EndDo;
		If DefaultValue = Undefined Then
			DefaultValue = PeriodList[0].Value;
		EndIf;
	Else
		Return; 
	EndIf;
	
EndProcedure

#EndRegion
