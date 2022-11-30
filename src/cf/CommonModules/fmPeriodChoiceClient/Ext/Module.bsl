
////////////////////////////////////////////////////////////////////////////////
// Функции и процедуры обеспечения выбора периода.
//  
////////////////////////////////////////////////////////////////////////////////

#Region ProgramInterface

// Устанавливает значения периода и его представление.
//
// Параметры:
//  Элемент      - ПолеФормы - элемент формы, с которым связано событие.
//  ВидПериода   - ПеречислениеСсылка.уфДоступныеПериодыОтчета - кратность периода.
//  НачалоПериода - Дата - нижняя граница периода.
//  КонецПериода - Дата - верхняя граница периода.
//  Период       - Строка - см. ВыборПериодаКлиентСервер.ПолучитьПредставлениеПериодаОтчета().
//
Procedure PeriodTypeOnChange(Item, VAL PeriodType, BeginOfPeriod, EndOfPeriod, Period) Export
	
	If PeriodType <> PredefinedValue("Enum.fmAvailableReportPeriods.ArbitraryPeriod") Then
		If ValueIsFilled(BeginOfPeriod) Then
			BeginOfPeriod = fmPeriodChoiceClientServer.ReportBegOfPeriod(PeriodType, BeginOfPeriod);
			EndOfPeriod  = fmPeriodChoiceClientServer.ReportEndOfPeriod(PeriodType, BeginOfPeriod);
		Else
			BeginOfPeriod = Undefined;
			EndOfPeriod  = Undefined;
		EndIf;
		
		List = fmPeriodChoiceClientServer.GetPeriodList(BeginOfPeriod, PeriodType);
		ListItem = List.FindByValue(BeginOfPeriod);
		If ListItem <> Undefined Then
			Period = ListItem.Presentation;
		Else
			Period = Undefined;
		EndIf;
	EndIf;
	
EndProcedure

// Устанавливает значения периода при изменении представления.
//
// Параметры:
//  Элемент      - ПолеФормы - элемент формы, с которым связано событие.
//  Период       - Строка - см. ВыборПериодаКлиентСервер.ПолучитьПредставлениеПериодаОтчета().
//  НачалоПериода - Дата - нижняя граница периода.
//  КонецПериода - Дата - верхняя граница периода.
//
Procedure PeriodOnChange(Item, VAL Period, BeginOfPeriod, EndOfPeriod) Export
	
	If IsBlankString(Period) Then
		BeginOfPeriod = Undefined;
		EndOfPeriod  = Undefined;
	EndIf;
	
EndProcedure

// Отображает выбор периода из выпадающего списка.
//
// Параметры:
//  Форма        - УправляемаяФорма - где происходит выбор.
//  Элемент      - ПолеФормы - элемент формы, с которым связано событие.
//  СтандартнаяОбработка - Булево - признак стандартной (системной) обработки события.
//  ВидПериода   - ПеречислениеСсылка.уфДоступныеПериодыОтчета - кратность периода.
//  Период       - Строка - см. ВыборПериодаКлиентСервер.ПолучитьПредставлениеПериодаОтчета().
//  НачалоПериода - Дата - нижняя граница периода.
//  КонецПериода - Дата - верхняя граница периода.
// 
Procedure PeriodStartChoice(Form, Item, StandardProcessing, PeriodType, BeginOfPeriod, ExecutedNotification) Export
	
	If BeginOfPeriod = '00010101' Then
		BeginOfPeriod = fmPeriodChoiceClientServer.ReportBegOfPeriod(PeriodType, CurrentDate()); // Дата сеанса не используется.
	EndIf;
	
	StandardProcessing = False;
	
	SelectReportPeriod(Form, Item, PeriodType, BeginOfPeriod, ExecutedNotification);
	
EndProcedure

// Устанавливает значения периода.
//
// Параметры:
//  Элемент      - ПолеФормы - элемент формы, с которым связано событие.
//  ВыбранноеЗначение - Дата - начало выбранного периода.
//  СтандартнаяОбработка - Булево - признак стандартной (системной) обработки события.
//  ВидПериода   - ПеречислениеСсылка.уфДоступныеПериодыОтчета - кратность периода.
//  Период       - Строка - см. ВыборПериодаКлиентСервер.ПолучитьПредставлениеПериодаОтчета().
//  НачалоПериода - Дата - нижняя граница периода.
//  КонецПериода - Дата - верхняя граница периода.
// 
Procedure PeriodChoiceProcessing(Item, ChosenValue, StandardProcessing, PeriodType, Period, BeginOfPeriod, EndOfPeriod) Export
	
	If TypeOf(ChosenValue) = Type("DATE") Then
		BeginOfPeriod = fmPeriodChoiceClientServer.ReportBegOfPeriod(PeriodType, ChosenValue);
		EndOfPeriod  = fmPeriodChoiceClientServer.ReportEndOfPeriod(PeriodType, ChosenValue);
		
		ChosenValue = fmPeriodChoiceClientServer.GetReportPeroidRepresentation(
			PeriodType, BeginOfPeriod, EndOfPeriod);
			
		Period = ChosenValue;
		StandardProcessing = False;
	EndIf;
	
EndProcedure

// Подбор при изменении представления периода.
//
// Параметры:
//  Элемент      - ПолеФормы - элемент формы, с которым связано событие.
//  Текст        - Строка - Строка текста, введенная в поле ввода.
//  ДанныеВыбора - СписокЗначений - значения, из которых происходил выбор.
//  Ожидание     - Число - Интервал в секундах после ввода текста. "0" означает формирование списка быстрого выбора.
//  СтандартнаяОбработка - Булево - признак стандартной (системной) обработки события.
//  ВидПериода   - ПеречислениеСсылка.уфДоступныеПериодыОтчета - кратность периода.
//  Период       - Строка - см. ВыборПериодаКлиентСервер.ПолучитьПредставлениеПериодаОтчета().
//  НачалоПериода - Дата - нижняя граница периода.
//  КонецПериода - Дата - верхняя граница периода.
// 
Procedure PeriodAutoComplete(Item, Text, ChoiceData, Waiting, StandardProcessing, PeriodType, Period, BeginOfPeriod, EndOfPeriod) Export
	
	ChoiceData = fmPeriodChoiceClientServer.ChooseReportPeriod(PeriodType, Text, 
		BeginOfPeriod, EndOfPeriod);
		
	StandardProcessing = False;
	
EndProcedure

// Подбор при изменении представления периода.
//
// Параметры:
//  Элемент      - ПолеФормы - элемент формы, с которым связано событие.
//  Текст        - Строка - Строка текста, введенная в поле ввода.
//  ДанныеВыбора - СписокЗначений - значения, из которых происходил выбор.
//  СтандартнаяОбработка - Булево - признак стандартной (системной) обработки события.
//  ВидПериода   - ПеречислениеСсылка.уфДоступныеПериодыОтчета - кратность периода.
//  Период       - Строка - см. ВыборПериодаКлиентСервер.ПолучитьПредставлениеПериодаОтчета().
//  НачалоПериода - Дата - нижняя граница периода.
//  КонецПериода - Дата - верхняя граница периода.
// 
Procedure PeriodTextEditEnd(Item, Text, ChoiceData, StandardProcessing, PeriodType, Period, BeginOfPeriod, EndOfPeriod) Export
	
	If IsBlankString(Text) Then
		Return;
	EndIf;
	
	ChoiceData = fmPeriodChoiceClientServer.ChooseReportPeriod(PeriodType, Text, 
		BeginOfPeriod, EndOfPeriod);
		
	StandardProcessing = False;	
	
EndProcedure

#EndRegion

#Region ServiceProceduresAdFunctions

Procedure SelectReportPeriod(Form, Item, PeriodType, BeginOfPeriod, ExecutedNotification)
	
	List = fmPeriodChoiceClientServer.GetPeriodList(BeginOfPeriod, PeriodType);
	If List.Count() = 0 Then
		Return;
	EndIf;
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("Form", Form);
	AdditionalParameters.Insert("List", List);
	AdditionalParameters.Insert("Item", Item);
	AdditionalParameters.Insert("PeriodType", PeriodType);
	AdditionalParameters.Insert("ExecutedNotification", ExecutedNotification);

	NotifyDescription = New NotifyDescription("ChooseReportPeriodEnd", ThisObject, AdditionalParameters);
	ListItem = List.FindByValue(BeginOfPeriod);
	
	Form.ShowChooseFromList(NotifyDescription, List, Item, ListItem);
	
EndProcedure

Procedure ChooseReportPeriodEnd(SelectedPeriod, AdditionalParameters) Export
	
	Form = AdditionalParameters.Form;
	List = AdditionalParameters.List;
	Item = AdditionalParameters.Item;
	PeriodType = AdditionalParameters.PeriodType;
	ExecutedNotification = AdditionalParameters.ExecutedNotification;
	
	If SelectedPeriod = Undefined Then
		Return;
	EndIf;
	
	Index = List.IndexOf(SelectedPeriod);
	If Index = 0 OR Index = List.Count() - 1 Then
		SelectReportPeriod(Form, Item, PeriodType, SelectedPeriod.Value, ExecutedNotification);
	Else
		ReturnChosenPeriodInForm(PeriodType, SelectedPeriod, ExecutedNotification);
	EndIf;
	
EndProcedure

Procedure ReturnChosenPeriodInForm(PeriodType, SelectedPeriod, ExecutedNotification)
	
	PeriodStructure = New Structure;
	PeriodStructure.Insert("PeriodType", PeriodType);
	PeriodStructure.Insert("Period", SelectedPeriod.Presentation);
	PeriodStructure.Insert("BeginOfPeriod", SelectedPeriod.Value);
	PeriodStructure.Insert("EndOfPeriod", fmPeriodChoiceClientServer.ReportEndOfPeriod(PeriodType, SelectedPeriod.Value));
	
	ExecuteNotifyProcessing(ExecutedNotification, PeriodStructure);
	
EndProcedure

Procedure FillPeriodList(Form, Item, PeriodType, BeginOfPeriod) Export
	
	If BeginOfPeriod = '00010101' Then
		BeginOfPeriod = fmPeriodChoiceClientServer.ReportBegOfPeriod(PeriodType, CurrentDate());
	EndIf;
	List = fmPeriodChoiceClientServer.GetPeriodList(BeginOfPeriod, PeriodType);
	If List.Count() = 0 Then
		Return;
	EndIf;
	
	Item.ChoiceList.Clear();
	
	Index = 0;
	For Each ListItm In List Do
		Item.ChoiceList.Insert(Index, ListItm.Value, ListItm.Presentation);
		Index = Index + 1;
	EndDo;
	
EndProcedure

#EndRegion




