
#Region ProceduresAndFunctionsOfCommonUse

// Функция возвращает значение по умолчанию для передаваемого пользователя и настройки.
//
// Параметры:
//  Настройка    - Строка - вид настройки, значение по умолчанию которой необходимо получить
//  Пользователь - СправочникСсылка.Пользователи - пользователь программы, настройка которого
//				   запрашивается, если параметр не передается настройка возвращается для текущего пользователя.
//
// Возвращаемое значение:
//  Значение по умолчанию для настройки.
//
Function GetDefaultValue(Setting, User = Undefined) Export
	
	If Upper(Setting) = Upper("fmReflectIFRSByDefault") Then
		EmptyValue = False;
	Else
		EmptyValue = Undefined;
	EndIf;
	
	If Upper(Setting) = Upper("fmReflectBudgetingByDefault") Then
		EmptyValue = False;
	Else
		EmptyValue = Undefined;
	EndIf;
	
	If Upper(Setting) = Upper("MainProject") Then
		EmptyValue = Catalogs.fmProjects.EmptyRef();
	ElsIf Upper(Setting) = Upper("MainBalanceUnit") Then
		EmptyValue = Catalogs.fmBalanceUnits.EmptyRef();
	ElsIf Upper(Setting) = Upper("MainScenario") Then
		EmptyValue = Catalogs.fmBudgetingScenarios.EmptyRef();
	ElsIf Upper(Setting) = Upper("MainDepartment") Then
		EmptyValue = Catalogs.fmDepartments.EmptyRef();
	EndIf;
	
	SettingValue = CommonSettingsStorage.Load(Upper(Setting),,, User);
	
	Return ?(SettingValue = Undefined, EmptyValue, SettingValue);
	
EndFunction // ПолучитьЗначениеПоУмолчанию()

// Процедура записывает значение по умолчанию для передаваемого пользователя и настройки.
//
// Параметры:
//  Настройка    - Строка - вид настройки
//  Значение     - значение настройки
//  Пользователь - СправочникСсылка.Пользователи - пользователь программы, для которого устанавливается настройка.
//
// Возвращаемое значение:
//  Нет
//
Procedure SetDefaultValue(Setting, Value, User = Undefined) Export
	
	CommonSettingsStorage.Save(Upper(Setting),, Value,, User);
	
EndProcedure // УстановитьЗначениеПоУмолчанию()

// Функция обработчик "ЕстьОбщийРеквизитВДокументе" 
//
Function IsCommonAttributeInDocument(AttributeName, DocumentMetadata) Export
	
	Return Metadata.CommonAttributes[AttributeName].Content.Find(DocumentMetadata).Use = Metadata.ObjectProperties.CommonAttributeUse.Use;
	
EndFunction

// Функция обработчик "ЕстьНезаполненныйОбщийРеквизитДокумента" 
//
Function IsNotFilledDocumentCommonAttribute(AttributeName, DocumentObject, DocumentMetadata) Export

	Result =
		IsCommonAttributeInDocument(AttributeName, DocumentMetadata)
		AND NOT ValueIsFilled(DocumentObject[AttributeName]);

	Return Result;

EndFunction

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

//Процедура проверяет правильность заполнения статей.
Procedure FillCheckProcessing(Source, Cancel, CheckingAttributes) Export
	
	//Определим для какого типа статьи производится проверка.
	ArrayWithoutDuplicates = New Array;
	If TypeOf(Source) = Type("CatalogObject.fmCashflowItems") Then
		AnalyticsType = "fmAnalyticsType";
		Templates = "fmEntriesTemplates";
	ElsIf TypeOf(Source) = Type("CatalogObject.fmIncomesAndExpensesItems") Then
		AnalyticsType = "AnalyticsType";
		Templates = "EntriesTemplates";
	EndIf;
	AccountDr = "AccountDr";
	AccountCr = "AccountCr";
	//Проверим правильность заполнения типов аналитик для статьи.
	//В структуре аналитик не должно быть висячих аналитик.
	For Num =2 To 3 Do
		PreviousNum = Num-1;
		If ValueIsFilled(Source[AnalyticsType+PreviousNum]) Then
			ArrayWithoutDuplicates.Add(Source[AnalyticsType+PreviousNum]);
		EndIf;
		If ValueIsFilled(Source[AnalyticsType+Num]) AND NOT ValueIsFilled(Source[AnalyticsType+PreviousNum]) Then
			CommonClientServer.MessageToUser(NStr("en='It is forbidden to leave blank analytics between filled!';ru='Запрещено оставлять незаполненные аналитики между заполненными!'"), Source, AnalyticsType+PreviousNum, , Cancel);
		EndIf;
		If NOT (ArrayWithoutDuplicates.Find(Source[AnalyticsType+Num]) = Undefined) Then
			CommonClientServer.MessageToUser(NStr("en='There can be no duplicate analytics types';ru='Не может быть повторяющихся типов аналитик'"), Source, AnalyticsType+Num, , Cancel);
		EndIf;
	EndDo;
	
	//Проверим правильность заполнения шаблонов проводк для выбранной статьи.
	//Варианты проверок:
	//1.Заполнен один из счетов и он не забалансовый.
	//2.Не заполнен ни один из счетов.
	For Each String In Source[Templates] Do
		If NOT ValueIsFilled(String[AccountDr]) AND ValueIsFilled(String[AccountCr]) Then
			If NOT String[AccountCr].OffBalance Then
				CommonClientServer.MessageToUser(StrTemplate(NStr("en='Credit account %1 is not off-balance, it is necessary to fill the debit account';ru='Счет кредита %1 не является забалансовым, необходимо заполнить счет дебета'"), String[AccountCr]),,,, Cancel);
			EndIf;
		EndIf;
		If ValueIsFilled(String[AccountDr]) AND NOT ValueIsFilled(String[AccountCr]) Then
			If NOT String[AccountDr].OffBalance Then
				CommonClientServer.MessageToUser(StrTemplate(NStr("en='Debit account %1 is not off-balance, it is necessary to fill the credit account';ru='Счет дебета %1 не является забалансовым, необходимо заполнить счет кредита'"), String[AccountDr]),,,, Cancel);
			EndIf;
		EndIf;
		If NOT ValueIsFilled(String[AccountDr]) AND NOT ValueIsFilled(String[AccountCr]) Then
			WarningText = NStr("en='None of accounts is fill';ru='Не заполнен ни один из счетов'");
			CommonClientServer.MessageToUser(WarningText,,,, Cancel);
		EndIf;
	EndDo;
EndProcedure

// Выполняет установку отбора по указанному БалансоваяЕдиница в динамических списках.
// Вызывать необходимо из обработчика формы ПриСозданииНаСервере.
// Если в форму при открытии был передан отбор по БалансоваяЕдиница, то функция не будет выполнена.
//
// Параметры
//  Форма          - УправляемаяФорма  - форма, в которой необходимо установить отбор
//  ИмяСписка      - Строка - имя реквизита формы типа ДинамическийСписок.
//  ИмяРеквизита   - Строка - имя поля-организации в динамическом списке.
//  ЗначениеОтбора - СправочникСсылка.БалансоваяЕдиница, СписокЗначений, Массив - значение отбора.
//                   Если значение не задано, то будет подставлена основная организация из
//                   настроек пользователя.
//
// Возвращаемое значение:
//   СправочникСсылка.БалансоваяЕдиница - Если отбор установлен, то вернет значение отбора.
//
Function SetFilterByMainBalanceUnit(Form, ListName = "List", AttributeName = "BalanceUnit", FilterValue = Undefined) Export
		
	If Form.Parameters.Property("Filter") AND Form.Parameters.Filter.Property(AttributeName) Then
		// Если значение отбора передается в параметрах формы - берем его оттуда, параметр при этом удаляем
		MainBalanceUnit = Form.Parameters.Filter[AttributeName];
		Form.Parameters.Filter.Delete(AttributeName);
	ElsIf TypeOf(FilterValue) = Type("CatalogRef.fmBalanceUnits") 
	OR TypeOf(FilterValue) = Type("ValueList") 
	OR TypeOf(FilterValue) = Type("Array") Then
		MainBalanceUnit = FilterValue;
	Else
		MainBalanceUnit = fmCommonUseServer.GetDefaultValue("MainBalanceUnit")
	EndIf;
	
	If TypeOf(MainBalanceUnit) = Type("CatalogRef.fmBalanceUnits") Then
		FilterComparisonType = DataCompositionComparisonType.Equal;
	Else
		FilterComparisonType = DataCompositionComparisonType.InList;
	EndIf;
	
	FilterUse = ValueIsFilled(MainBalanceUnit);
	
	ViewMode = DataCompositionSettingsItemViewMode.QuickAccess;
	
	CommonClientServer.SetDynamicListFilterItem(
	Form[ListName], AttributeName, MainBalanceUnit, FilterComparisonType, , FilterUse, ViewMode);
	
	Return MainBalanceUnit;
	
EndFunction

// Заменяет отбор, установленный пользователем в сохраненной настройке списка, на отбор, установленный программно при создании формы списка.
// Вызывается при восстановлении пользовательских настроек динамического списка
// из обработчика списка ПередЗагрузкойПользовательскихНастроекНаСервере.
//
// Параметры:
//  Список      - ДинамическийСписок - Динамический список, для которого устанавливается отбор.
//  Настройки   - ПользовательскиеНастройкиКомпоновкиДанных - Восстанавливаемые настройки списка.
//  ИмяОтбора   - Строка - Имя элемента отбора.
//
Procedure RestoreListFilter(List, Settings, FilterName) Export

	Filters = fmCommonUseClientServer.FindFilterGroupsAndItems(
		List.SettingsComposer.Settings.Filter, FilterName);
	
	If Filters.Count() = 0 Then
		Return;
	EndIf;
	
	FilterItem = Filters[0];
	SettingID = FilterItem.UserSettingID;
	
	For Each SettingsItem In Settings.Items Do
		If TypeOf(SettingsItem) = Type("DataCompositionFilterItem") 
			AND SettingsItem.UserSettingID = SettingID Then
			SettingsItem.RightValue = FilterItem.RightValue;
			SettingsItem.Use  = FilterItem.Use;
			Break;
		EndIf;
	EndDo;

EndProcedure

#EndRegion




