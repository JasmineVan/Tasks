
// Копирует элементы из одной коллекции в другую
//
// Параметры:
//	ПриемникЗначения	- коллекция элементов КД, куда копируются параметры
//	ИсточникЗначения	- коллекция элементов КД, откуда копируются параметры
//	ОчищатьПриемник		- признак необходимости очистки приемника (Булево, по умолчанию: истина)
//
Procedure CopyItems(ValueDest, ValueSource, ClearSource = True) Export
	
	If TypeOf(ValueSource) = Type("DataCompositionConditionalAppearance")
		OR TypeOf(ValueSource) = Type("DataCompositionUserFieldsCaseVariants")
		OR TypeOf(ValueSource) = Type("DataCompositionAppearanceFields")
		OR TypeOf(ValueSource) = Type("DataCompositionDataParameterValues") Then
		CreateByType = False;
	Else
		CreateByType = True;
	EndIf;
	ItemsDestination = ValueDest.Items;
	ItemsSource = ValueSource.Items;
	If ClearSource Then
		ItemsDestination.Clear();
	EndIf;
	
	For Each SourceItem In ItemsSource Do
		
		If TypeOf(SourceItem) = Type("DataCompositionOrderItem") Then
			// Элементы порядка добавляем в начало
			Index = ItemsSource.IndexOf(SourceItem);
			DestItem = ItemsDestination.Insert(Index, TypeOf(SourceItem));
		Else
			If CreateByType Then
				DestItem = ItemsDestination.Add(TypeOf(SourceItem));
			Else
				DestItem = ItemsDestination.Add();
			EndIf;
		EndIf;
		
		FillPropertyValues(DestItem, SourceItem);
		// В некоторых коллекциях необходимо заполнить другие коллекции
		If TypeOf(ItemsSource) = Type("DataCompositionConditionalAppearanceItemCollection") Then
			CopyItems(DestItem.Fields, SourceItem.Fields);
			CopyItems(DestItem.Filter, SourceItem.Filter);
			FillItems(DestItem.Appearance, SourceItem.Appearance); 
		ElsIf TypeOf(ItemsSource)	= Type("DataCompositionUserFieldCaseVariantCollection") Then
			CopyItems(DestItem.Filter, SourceItem.Filter);
		EndIf;
		
		// В некоторых элементах коллекции необходимо заполнить другие коллекции
		If TypeOf(SourceItem) = Type("DataCompositionFilterItemGroup") Then
			CopyItems(DestItem, SourceItem);
		ElsIf TypeOf(SourceItem) = Type("DataCompositionSelectedFieldGroup") Then
			CopyItems(DestItem, SourceItem);
		ElsIf TypeOf(SourceItem) = Type("DataCompositionUserFieldCase") Then
			CopyItems(DestItem.Variants, SourceItem.Variants);
		ElsIf TypeOf(SourceItem) = Type("DataCompositionUserFieldExpression") Then
			DestItem.SetDetailRecordExpression (SourceItem.GetDetailRecordExpression());
			DestItem.SetTotalRecordExpression(SourceItem.GetTotalRecordExpression());
			DestItem.SetDetailRecordExpressionPresentation(SourceItem.GetDetailRecordExpressionPresentation ());
			DestItem.SetTotalRecordExpressionPresentation(SourceItem.GetTotalRecordExpressionPresentation ());
		EndIf;
		
	EndDo;
	
EndProcedure

// Заполняет одну коллекцию элементов на основании другой
//
// Параметры:
//	ПриемникЗначения	- коллекция элементов КД, куда копируются параметры
//	ИсточникЗначения	- коллекция элементов КД, откуда копируются параметры
//	ПервыйУровень		- уровень структуры коллекции элементов КД для копирования параметров
//
Procedure FillItems(ValueDest, ValueSource, FirstLevel = Undefined) Export
	
	If TypeOf(ValueDest) = Type("DataCompositionParameterValueCollection") Then
		ValueCollection = ValueSource;
	Else
		ValueCollection = ValueSource.Items;
	EndIf;
	
	For Each SourceItem In ValueCollection Do
		If FirstLevel = Undefined Then
			DestItem = ValueDest.FindParameterValue(SourceItem.Parameter);
		Else
			DestItem = FirstLevel.FindParameterValue(SourceItem.Parameter);
		EndIf;
		If DestItem = Undefined Then
			Continue;
		EndIf;
		FillPropertyValues(DestItem, SourceItem);
		If TypeOf(SourceItem) = Type("DataCompositionParameterValue") Then
			If SourceItem.NestedParameterValues.Count() <> 0 Then
				FillItems(DestItem.NestedParameterValues, SourceItem.NestedParameterValues, ValueDest);
			EndIf;
		EndIf;
	EndDo;
	
EndProcedure

// Добавляет в коллекцию оформляемых полей компоновки данных новое поле
//
// Параметры:
//	КоллекцияОформляемыхПолей 	- коллекция оформляемых полей КД
//	ИмяПоля						- Строка - имя поля
//
// Возвращаемое значение:
//	ОформляемоеПолеКомпоновкиДанных - созданное поле
//
// Пример:
// 	Форма.УсловноеОформление.Элементы[0].Поля
//
Function AddAppearanceField(AppearanceFieldCollection, FieldName) Export
	
	ItemField 		= AppearanceFieldCollection.Items.Add();
	ItemField.Field 	= New DataCompositionField(FieldName);

	Return ItemField;
	
EndFunction

// Добавляет в коллекцию отбора новую группу указанного типа.
//
// Параметры:
//	КоллекцияЭлементовОтбора - КоллекцияЭлементовОтбораКомпоновкиДанных 
//	ТипГруппы - ГруппаЭлементовОтбораКомпоновкиДанных - ГруппаИ или ГруппаИли
//
// Возвращаемое значение:
//	ГруппаЭлементовОтбораКомпоновкиДанных - добавленная группа
//
Function AddFilterGroup(FilterItemCollection, GroupType) Export

	FilterItemType			 = FilterItemCollection.Add(Type("DataCompositionFilterItemGroup"));
	FilterItemType.GroupType  = GroupType;
	
	Return FilterItemType;

EndFunction

