
#Region ProceduresAndFunctionsOfCommonUse

// Процедура добавляет значения элементов из одного списка, в другой.
// Параметры:
//	Список - список приемник
//	СписокДобавить - список источник.
Procedure AddListInList(List,ListAdd) Export 

	For Each Item In ListAdd Do
		AddInList(List,Item.Value);
	EndDo; 

EndProcedure

// Добавляет значение в список
// Параметры:
//	Список - список значений, в который добавляем значение
//	Значение - значение для добавления.
Procedure AddInList(List,Value) Export

	If List.FindByValue(Value) = Undefined Then
	
		List.Add(Value);
	
	EndIf;

EndProcedure

Procedure AddConditionalAppearanceItem(FormTree = Undefined, ConditionalAppearance, FieldName = Undefined, ComparisonType = Undefined, RightValue, Color, AppearanceItem) Export
	If TypeOf(ConditionalAppearance) = Type("DataCompositionConditionalAppearanceItem") Then
		ConditionalAppearanceItem = ConditionalAppearance;
	Else
		ConditionalAppearanceItem = ConditionalAppearance.Items.Add();
	EndIf;
	
	If NOT FieldName = Undefined Then
		If ComparisonType = Undefined Then
			_ComparisonType= DataCompositionComparisonType.Equal;
		Else
			_ComparisonType = ComparisonType;
		EndIf;
		DataFilterItem = CommonClientServer.AddCompositionItem(ConditionalAppearanceItem.Filter, FieldName, _ComparisonType, RightValue);
	EndIf;
	
	AppearanceColorItem = ConditionalAppearanceItem.Appearance.Items.Find(AppearanceItem);
	AppearanceColorItem.Value 		= Color;
	AppearanceColorItem.Use 	= True;
	
	If NOT FormTree = Undefined Then
		FieldItem = ConditionalAppearanceItem.Fields.Items.Add();
		FieldItem.Field 						= New DataCompositionField(FormTree);
		FieldItem.Use				= True;
	EndIf;
EndProcedure

// Удаляет повторяющиеся элементы массива.
//
// Параметры:
//  ОбрабатываемыйМассив - Массив - элементы произвольных типов, из которых удаляются неуникальные.
//  НеИспользоватьНеопределено - Булево - если Истина, то все значения Неопределено удаляются из массива.
//  АнализироватьСсылкиКакИдентификаторы - Булево - если Истина, то для ссылок вызывается функция УникальныйИдентификатор()
//                                                  и уникальность определяется по строкам-идентификаторам.
//
// Возвращаемое значение:
//   Массив      - элементы ОбрабатываемыйМассив после удаления лишних.
//
Function DeleteDuplicatedArrayItems(ProcessingArray, DontUseUndefined = False, AnalyzeRefsAsIDs = False) Export

	If TypeOf(ProcessingArray) <> Type("Array") Then
		Return ProcessingArray;
	EndIf;
	
	AlreadyInArray = New Map;
	If AnalyzeRefsAsIDs Then   // сравниваем ссылки как строки-уникальные идентификаторы
		
		RefTypesDescription = fmCommonUseServerCall.AllRefsTypeDescription();
		
	 	WasUndefined = False;
		ArrayItemsCount = ProcessingArray.Count();

		For ReverseIndex = 1 To ArrayItemsCount Do
			
			ArrayItem = ProcessingArray[ArrayItemsCount - ReverseIndex];
			ItemType = TypeOf(ArrayItem);
			If ArrayItem = Undefined Then
				If WasUndefined OR DontUseUndefined Then
					ProcessingArray.Delete(ArrayItemsCount - ReverseIndex);
				Else
					WasUndefined = True;
				EndIf;
				Continue;
			ElsIf RefTypesDescription.ContainsType(ItemType) Then

				ItemID = String(ArrayItem.UUID());

			Else

				ItemID = ArrayItem;

			EndIf;

			If AlreadyInArray[ItemID] = True Then
				ProcessingArray.Delete(ArrayItemsCount - ReverseIndex);
			Else
				AlreadyInArray[ItemID] = True;
			EndIf;
			
		EndDo;

	Else
		
		ItemIndex = 0;
		ItemsCount = ProcessingArray.Count();
		While ItemIndex < ItemsCount Do
			
			ArrayItem = ProcessingArray[ItemIndex];
			If DontUseUndefined AND ArrayItem = Undefined
			 OR AlreadyInArray[ArrayItem] = True Then      // удаляем, переходя к следующему
			 
				ProcessingArray.Delete(ItemIndex);
				ItemsCount = ItemsCount - 1;
				
			Else   // запоминаем, переходя к следующему
				
				AlreadyInArray.Insert(ArrayItem, True);
				ItemIndex = ItemIndex + 1;
				
			EndIf;
			
		EndDo;
		
	EndIf;

	Return ProcessingArray;

EndFunction

// Устанавливает элемент отбор динамического списка
//
// Параметры:
//   Список         - обрабатываемый динамический список.
//   ИмяПоля        - имя поля компоновки, отбор по которому нужно установить.
//   ВидСравнения   - вид сравнения отбора, по умолчанию - Равно.
//   ПравоеЗначение - значение отбора.
//
Procedure SetListFilterItem(List, FieldName, RightValue, ComparisonType = Undefined, Presentation = "") Export
	
	FilterItem = List.Filter.Items.Add(Type("DataCompositionFilterItem"));
	FilterItem.LeftValue  = New DataCompositionField(FieldName);	
	FilterItem.ComparisonType   = ?(ComparisonType = Undefined, DataCompositionComparisonType.Equal, ComparisonType);
	FilterItem.Use  = True;
	FilterItem.RightValue = RightValue;
	FilterItem.Presentation  = Presentation;
	
EndProcedure

// Изменяет элемент отбора динамического списка.
//
// Параметры:
// Список         - обрабатываемый динамический список.
// ИмяПоля        - имя поля компоновки, отбор по которому нужно установить.
// ПравоеЗначение - значение отбора, по умолчанию - Неопределено.
// Использование  - признак использования отбора, по умолчанию - Ложь.
// ВидСравнения   - вид сравнения отбора, по умолчанию - Равно.
//
Procedure ChangeListFilterItem(List, FieldName, RightValue = Undefined, Use = False, ComparisonType = Undefined) Export
	
	DeleteFilterGroupItems(
		List.SettingsComposer.Settings.Filter, 
		FieldName);
	SetFilterItem(
		List.SettingsComposer.Settings.Filter, 
		FieldName, 
		RightValue, 
		ComparisonType, 
		DataCompositionSettingsItemViewMode.QuickAccess, 
		Use); 
		
EndProcedure 

// Удалить элементы отбора с заданным именем поля или представлением.
//
// Параметры:
//  ОбластьУдаления - КоллекцияЭлементовОтбораКомпоновкиДанных - контейнер с элементами и группами отбора,
//                                                               например, Список.Отбор или группа в отборе..
//  ИмяПоля         - Строка - имя поля компоновки (не используется для групп).
//  Представление   - Строка - представление поля компоновки.
//
Procedure DeleteFilterGroupItems(VAL DeletionArea, VAL FieldName = Undefined, VAL Presentation = Undefined) Export
	
	If ValueIsFilled(FieldName) Then
		SearchValue = New DataCompositionField(FieldName);
		SearchMode = 1;
	Else
		SearchMode = 2;
		SearchValue = Presentation;
	EndIf;
	
	ItemsArray = New Array;
	
	FindRecursively(DeletionArea.Items, ItemsArray, SearchMode, SearchValue);
	
	For Each Item In ItemsArray Do
		If Item.Parent = Undefined Then
			DeletionArea.Items.Delete(Item);
		Else
			Item.Parent.Items.Delete(Item);
		EndIf;
	EndDo;
	
EndProcedure

Procedure FindRecursively(ItemCollection, ItemsArray, SearchMode, SearchValue)
	
	For Each FilterItem In ItemCollection Do
		
		If TypeOf(FilterItem) = Type("DataCompositionFilterItem") Then
			
			If SearchMode = 1 Then
				If FilterItem.LeftValue = SearchValue Then
					ItemsArray.Add(FilterItem);
				EndIf;
			ElsIf SearchMode = 2 Then
				If FilterItem.Presentation = SearchValue Then
					ItemsArray.Add(FilterItem);
				EndIf;
			EndIf;
		Else
			
			FindRecursively(FilterItem.Items, ItemsArray, SearchMode, SearchValue);
			
			If SearchMode = 2 AND FilterItem.Presentation = SearchValue Then
				ItemsArray.Add(FilterItem);
			EndIf;
			
		EndIf;
		
	EndDo;
	
EndProcedure

// Добавить или заменить существующий элемент отбора.
//
// Параметры:
//  ОбластьПоискаДобавления - КоллекцияЭлементовОтбораКомпоновкиДанных - контейнер с элементами и группами отбора,
//                                     например, Список.Отбор или группа в отборе.
//  ИмяПоля                 - Строка - имя поля компоновки данных (заполняется всегда).
//  ПравоеЗначение          - произвольный - сравниваемое значение.
//  ВидСравнения            - ВидСравненияКомпоновкиДанных - вид сравнения.
//  Представление           - Строка - представление элемента компоновки данных.
//  Использование           - Булево - использование элемента.
//  РежимОтображения        - РежимОтображенияЭлементаНастройкиКомпоновкиДанных - режим отображения.
//  ИдентификаторПользовательскойНастройки - Строка - см. ОтборКомпоновкиДанных.ИдентификаторПользовательскойНастройки
//                                                    в синтакс-помощнике.
//
Procedure SetFilterItem(AddSearchArea,
								VAL FieldName,
								VAL RightValue = Undefined,
								VAL ComparisonType = Undefined,
								VAL Presentation = Undefined,
								VAL Use = Undefined,
								VAL ViewMode = Undefined,
								VAL UserSettingID = Undefined) Export
	
	ChangedCount = ChangeFilterItems(AddSearchArea, FieldName, Presentation,
							RightValue, ComparisonType, Use, ViewMode, UserSettingID);
	
	If ChangedCount = 0 Then
		If ComparisonType = Undefined Then
			If TypeOf(RightValue) = Type("Array")
				OR TypeOf(RightValue) = Type("FixedArray")
				OR TypeOf(RightValue) = Type("ValueList") Then
				ComparisonType = DataCompositionComparisonType.InList;
			Else
				ComparisonType = DataCompositionComparisonType.Equal;
			EndIf;
		EndIf;
		If ViewMode = Undefined Then
			ViewMode = DataCompositionSettingsItemViewMode.Inaccessible;
		EndIf;
		AddCompositionItem(AddSearchArea, FieldName, ComparisonType,
								RightValue, Presentation, Use, ViewMode, UserSettingID);
	EndIf;
	
EndProcedure

// Изменить элемент отбора с заданным именем поля или представлением.
//
// Параметры:
//  ОбластьПоиска - КоллекцияЭлементовОтбораКомпоновкиДанных - контейнер с элементами и группами отбора,
//                                                             например, Список.Отбор или группа в отборе.
//  ИмяПоля                 - Строка - имя поля компоновки данных (заполняется всегда).
//  Представление           - Строка - представление элемента компоновки данных.
//  ПравоеЗначение          - Произвольный - сравниваемое значение.
//  ВидСравнения            - ВидСравненияКомпоновкиДанных - вид сравнения.
//  Использование           - Булево - использование элемента.
//  РежимОтображения        - РежимОтображенияЭлементаНастройкиКомпоновкиДанных - режим отображения.
//  ИдентификаторПользовательскойНастройки - Строка - см. ОтборКомпоновкиДанных.ИдентификаторПользовательскойНастройки
//                                                    в синтакс-помощнике.
//
// Возвращаемое значение:
//  Число - количество измененных элементов.
//
Function ChangeFilterItems(SearchArea,
								VAL FieldName = Undefined,
								VAL Presentation = Undefined,
								VAL RightValue = Undefined,
								VAL ComparisonType = Undefined,
								VAL Use = Undefined,
								VAL ViewMode = Undefined,
								VAL UserSettingID = Undefined) Export
	
	If ValueIsFilled(FieldName) Then
		SearchValue = New DataCompositionField(FieldName);
		SearchMode = 1;
	Else
		SearchMode = 2;
		SearchValue = Presentation;
	EndIf;
	
	ItemsArray = New Array;
	
	FindRecursively(SearchArea.Items, ItemsArray, SearchMode, SearchValue);
	
	For Each Item In ItemsArray Do
		If FieldName <> Undefined Then
			Item.LeftValue = New DataCompositionField(FieldName);
		EndIf;
		If Presentation <> Undefined Then
			Item.Presentation = Presentation;
		EndIf;
		If Use <> Undefined Then
			Item.Use = Use;
		EndIf;
		If ComparisonType <> Undefined Then
			Item.ComparisonType = ComparisonType;
		EndIf;
		If RightValue <> Undefined Then
			Item.RightValue = RightValue;
		EndIf;
		If ViewMode <> Undefined Then
			Item.ViewMode = ViewMode;
		EndIf;
		If UserSettingID <> Undefined Then
			Item.UserSettingID = UserSettingID;
		EndIf;
	EndDo;
	
	Return ItemsArray.Count();
	
EndFunction

// Добавить элемент компоновки в контейнер элементов компоновки.
//
// Параметры:
//  ОбластьДобавления - КоллекцияЭлементовОтбораКомпоновкиДанных - контейнер с элементами и группами отбора,
//                                                                 например, Список.Отбор или группа в отборе.
//  ИмяПоля                 - Строка - имя поля компоновки данных (заполняется всегда).
//  ПравоеЗначение          - Произвольный - сравниваемое значение.
//  ВидСравнения            - ВидСравненияКомпоновкиДанных - вид сравнения.
//  Представление           - Строка - представление элемента компоновки данных.
//  Использование           - Булево - использование элемента.
//  РежимОтображения        - РежимОтображенияЭлементаНастройкиКомпоновкиДанных - режим отображения.
//  ИдентификаторПользовательскойНастройки - Строка - см. ОтборКомпоновкиДанных.ИдентификаторПользовательскойНастройки
//                                                    в синтакс-помощнике.
// Возвращаемое значение:
//  ЭлементОтбораКомпоновкиДанных - элемент компоновки.
//
Function AddCompositionItem(AddArea,
									VAL FieldName,
									VAL ComparisonType,
									VAL RightValue = Undefined,
									VAL Presentation  = Undefined,
									VAL Use  = Undefined,
									VAL ViewMode = Undefined,
									VAL UserSettingID = Undefined) Export
	
	Item = AddArea.Items.Add(Type("DataCompositionFilterItem"));
	Item.LeftValue = New DataCompositionField(FieldName);
	Item.ComparisonType = ComparisonType;
	
	If ViewMode = Undefined Then
		Item.ViewMode = DataCompositionSettingsItemViewMode.Inaccessible;
	Else
		Item.ViewMode = ViewMode;
	EndIf;
	
	If RightValue <> Undefined Then
		Item.RightValue = RightValue;
	EndIf;
	
	If Presentation <> Undefined Then
		Item.Presentation = Presentation;
	EndIf;
	
	If Use <> Undefined Then
		Item.Use = Use;
	EndIf;
	
	// Важно: установка идентификатора должна выполняться
	// в конце настройки элемента, иначе он будет скопирован
	// в пользовательские настройки частично заполненным.
	If UserSettingID <> Undefined Then
		Item.UserSettingID = UserSettingID;
	ElsIf Item.ViewMode <> DataCompositionSettingsItemViewMode.Inaccessible Then
		Item.UserSettingID = FieldName;
	EndIf;
	
	Return Item;
	
EndFunction

// Найти элемент или группу отбора по заданному имени поля или представлению.
//
// Параметры:
//  ОбластьПоиска - ОтборКомпоновкиДанных, КоллекцияЭлементовОтбораКомпоновкиДанных,
//                  ГруппаЭлементовОтбораКомпоновкиДанных - контейнер
//                  с элементами и группами отбора, например Список.Отбор или группа в отборе.
//  ИмяПоля       - Строка - имя поля компоновки (не используется для групп).
//  Представление - Строка - представление поля компоновки.
//
// Возвращаемое значение:
//  Массив - коллекция отборов.
//
Function FindFilterGroupsAndItems(VAL SearchArea,
									VAL FieldName = Undefined,
									VAL Presentation = Undefined) Export
	
	If ValueIsFilled(FieldName) Then
		SearchValue = New DataCompositionField(FieldName);
		SearchMode = 1;
	Else
		SearchMode = 2;
		SearchValue = Presentation;
	EndIf;
	
	ItemsArray = New Array;
	
	FindRecursively(SearchArea.Items, ItemsArray, SearchMode, SearchValue);
	
	Return ItemsArray;
	
EndFunction

// Устанавливает свойство ИмяСвойства элемента формы с именем ИмяЭлемента в значение Значение.
// Применяется в тех случаях, когда элемент формы может не быть на форме из-за отсутствия прав у пользователя
// на объект, реквизит объекта или команду.
//
// Параметры:
//  ЭлементыФормы - ВсеЭлементФормы, ЭлементыФормы - коллекция элементов управляемой формы.
//  ИмяЭлемента   - Строка       - имя элемента формы.
//  ИмяСвойства   - Строка       - имя устанавливаемого свойства элемента формы.
//  Значение      - Произвольный - новое значение элемента.
// 
Procedure SetFormItemProperty(FormItems, ItemName, PropertyName, Value) Export
	
	FormItem = FormItems.Find(ItemName);
	If FormItem <> Undefined AND FormItem[PropertyName] <> Value Then
		FormItem[PropertyName] = Value;
	EndIf;
	
EndProcedure

// Checks correctness of the passed string with email addresses.
//
// String format:
//  Z = UserName|[User Name] [<]user@mail_server[>], String = Z[<splitter*>Z]
// 
//  Note: splitter* is any address splitter.
//
// Parameters:
//  EmailAddressString - String - correct string with email addresses.
//
// Returns:
//  Structure
//  State - Boolean - flag that shows whether conversion completed successfully.
//          If conversion completed successfully it contains Value, which is an array of
//          structures with the following keys:
//           Address      - recipient email address;
//           Presentation - recipient name.
//          If conversion failed it contains ErrorMessage - String.
//
// IMPORTANT: The function returns an array of structures, where one field (any field)
//            can be empty. It can be used by various subsystems for mapping user names to
//            email addresses. Therefore it is necessary to check before sending whether email
//            address is filled.
//
Function SplitStringWithEmailAddresses(Val EmailAddressString, RaiseException = True) Export
	
	Result = New Array;
	
	ProhibitedChars = "!#$%^&*()+`~|\/=";
	
	ProhibitedCharsMessage = NStr("en = 'There is a prohibited character %1 in the email address %2'");
	MessageInvalidEmailFormat = NStr("en = 'Incorrect email address %1'");
	
	SubstringArray = StringFunctionsClientServer.SplitStringIntoSubstringsArray(EmailAddressString,";",True);
	SubstringArrayToProcess = New Array;
	
	For Each ArrayElement In SubstringArray Do
		If Find(ArrayElement,",") > 0 Then
			AdditionalSubstringArray = StringFunctionsClientServer.SplitStringIntoSubstringsArray(EmailAddressString);
			For Each AdditionalArrayElement In AdditionalSubstringArray Do
				SubstringArrayToProcess.Add(AdditionalArrayElement);
			EndDo;
		Else
			SubstringArrayToProcess.Add(ArrayElement);
		EndIf;
	EndDo;
	
	For Each AddressString In SubstringArrayToProcess Do
		
		Index = 1;              // Number of processed character.
		Accumulator = "";       // Character accumulator. After the end of analysis, it passes its 
		                        // value to the full name or to the mail address.
		AddresseeFullName = ""; // Variable that accumulates the addressee name.
		EmailAddress = "";      // Variable that accumulates the email address.
		// 1 - Generating the full name: any allowed characters of the addressee name are expected.
		// 2 - Generating the mail address: any allowed characters of the email address are
		//     expected.
		// 3 - Ending mail address generation: a splitter character or a space character are
		//     expected. 
		ParsingStage = 1; 
		
		While Index <= StrLen(AddressString) Do
			
			Char = Mid(AddressString, Index, 1);
			
			If Char = " " Then
				Index = ?((CommonClientServer.SkipSpaces(AddressString, Index, " ") - 1) > Index,
				CommonClientServer.SkipSpaces(AddressString, Index, " ") - 1,
				Index);
				If ParsingStage = 1 Then
					AddresseeFullName = AddresseeFullName + Accumulator + " ";
				ElsIf ParsingStage = 2 Then
					EmailAddress = Accumulator;
					ParsingStage = 3;
				EndIf;
				Accumulator = "";
			ElsIf Char = "@" Then
				If ParsingStage = 1 Then
					ParsingStage = 2;
					
					For PCSearchIndex = 1 to StrLen(Accumulator) Do
						If Find(ProhibitedChars, Mid(Accumulator, PCSearchIndex, 1)) > 0 And RaiseException Then
							Raise StringFunctionsClientServer.SubstituteParametersToString(
							 ProhibitedCharsMessage,Mid(Accumulator, PCSearchIndex, 1),AddressString);
						EndIf;
					EndDo;
					
					Accumulator = Accumulator + Char;
				ElsIf ParsingStage = 2 And RaiseException Then
					Raise StringFunctionsClientServer.SubstituteParametersToString(
					 MessageInvalidEmailFormat,AddressString);
				ElsIf ParsingStage = 3 And RaiseException Then
					Raise StringFunctionsClientServer.SubstituteParametersToString(
					 MessageInvalidEmailFormat,AddressString);
				EndIf;
			Else
				If ParsingStage = 2 Or ParsingStage = 3 Then
					If Find(ProhibitedChars, Char) > 0 And RaiseException Then
						Raise StringFunctionsClientServer.SubstituteParametersToString(
						 ProhibitedCharsMessage,Char,AddressString);
					EndIf;
				EndIf;
				
				Accumulator = Accumulator + Char;
			EndIf;
			
			Index = Index + 1;
		EndDo;
		
		If ParsingStage = 1 Then
			AddresseeFullName = AddresseeFullName + Accumulator;
		ElsIf ParsingStage = 2 Then
			EmailAddress = Accumulator;
		EndIf;
		
		If IsBlankString(EmailAddress) And (Not IsBlankString(AddresseeFullName)) And RaiseException Then
			Raise StringFunctionsClientServer.SubstituteParametersToString(
			 MessageInvalidEmailFormat,AddresseeFullName);
		ElsIf StrOccurrenceCount(EmailAddress,"@") <> 1 And RaiseException Then 
			Raise StringFunctionsClientServer.SubstituteParametersToString(
			 MessageInvalidEmailFormat,EmailAddress);
		EndIf;
		
		If Not (IsBlankString(AddresseeFullName) And IsBlankString(EmailAddress)) Then
			Result.Add(CommonClientServer.CheckAndPrepareEmailAddress(AddresseeFullName, EmailAddress));
		EndIf;
		
	EndDo;
	
	Return Result;
	
EndFunction

// Shifts a position marker while the current character is the SkippedChar.
// Returns number of marker position.
//
Function SkipChars(Val String,
                   Val CurrentIndex,
                   Val SkippedChar)
	
	Result = CurrentIndex;
	
	// Removes skipped characters, if any
	While CurrentIndex < StrLen(String) Do
		If Mid(String, CurrentIndex, 1) <> SkippedChar Then
			Return CurrentIndex;
		EndIf;
		CurrentIndex = CurrentIndex + 1;
	EndDo;
	
	Return CurrentIndex;
	
EndFunction

#EndRegion
