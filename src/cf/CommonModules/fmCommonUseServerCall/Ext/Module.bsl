
#Region ServiceProgramInterface

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
		
		RefTypesDescription = AllRefsTypeDescription();
		
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

// Returns a type description that includes all configuration reference types.
//
Function AllRefsTypeDescription() Export
	
	Return New TypeDescription(New TypeDescription(New TypeDescription(New TypeDescription(New TypeDescription(
		New TypeDescription(New TypeDescription(New TypeDescription(New TypeDescription(
			   Catalogs.AllRefsType(),
			   Documents.AllRefsType().Types()
			), ExchangePlans.AllRefsType().Types()
			), Enums.AllRefsType().Types()
			), ChartsOfCharacteristicTypes.AllRefsType().Types()
			), ChartsOfAccounts.AllRefsType().Types()
			), ChartsOfCalculationTypes.AllRefsType().Types()
			), BusinessProcesses.AllRefsType().Types()
			), BusinessProcesses.RoutePointsAllRefsType().Types()
			), Tasks.AllRefsType().Types()
		);
	
EndFunction

// Returns a structure that contains attribute values read from the infobase by
// object reference.
// 
// If access to any of the attributes is denied, an exception is raised.
// To be able to read attribute values irrespective of current user rights, 
// turn privileged mode on.
// 
// Is not intended for retrieving empty reference attribute values.
//
// Parameters:
//  Ref        - AnyRef - reference to the object whose attribute values are retrieved.
//  Attributes - String - attribute names separated with commas, formatted according to
//               structure requirements 
//               Example: "Code, Description, Parent".
//             - Structure, FixedStructure -  keys are field aliases used for resulting
//               structure keys, values (optional) are field names. If a value is empty, it
//               is considered equal to the key.
//             - Array, FixedArray - attribute names formatted according to structure
//               property requirements.
//
// Returns:
//  Structure - contains names (keys) and values of the requested attributes.
//              If the string of the requested attributes is empty, an empty structure is returned.
//              If an empty reference is passed as the object reference, all return attribute
//              will be Undefined.
//
Function ObjectAttributeValues(Ref, Val Attributes) Export
	
	If TypeOf(Attributes) = Type("String") Then
		If IsBlankString(Attributes) Then
			Return New Structure;
		EndIf;
		Attributes = StringFunctionsClientServer.SplitStringIntoSubstringsArray(Attributes, ",", True);
	EndIf;
	
	AttributeStructure = New Structure;
	If TypeOf(Attributes) = Type("Structure") Or TypeOf(Attributes) = Type("FixedStructure") Then
		AttributeStructure = Attributes;
	ElsIf TypeOf(Attributes) = Type("Array") Or TypeOf(Attributes) = Type("FixedArray") Then
		For Each Attribute In Attributes Do
			AttributeStructure.Insert(StrReplace(Attribute, ".", ""), Attribute);
		EndDo;
	Else
		Raise StringFunctionsClientServer.SubstituteParametersToString(
			NStr("en = 'Invalid Attributes parameter type: %1'"),
			String(TypeOf(Attributes)));
	EndIf;
	
	FieldTexts = "";
	For Each KeyAndValue In AttributeStructure Do
		FieldName   = ?(ValueIsFilled(KeyAndValue.Value),
		              TrimAll(KeyAndValue.Value),
		              TrimAll(KeyAndValue.Key));
		
		Alias = TrimAll(KeyAndValue.Key);
		
		FieldTexts  = FieldTexts + ?(IsBlankString(FieldTexts), "", ",") + "" + FieldName + " AS " + Alias;
	EndDo;
	
	Query = New Query;
	Query.SetParameter("Ref", Ref);
	Query.Text =
	"SELECT
	|" + FieldTexts + " FROM " + Ref.Metadata().FullName() + " AS SpecifiedTableAlias
	| WHERE
	| SpecifiedTableAlias.Ref = &Ref
	|";
	Selection = Query.Execute().Select();
	Selection.Next();
	
	Result = New Structure;
	For Each KeyAndValue In AttributeStructure Do
		Result.Insert(KeyAndValue.Key);
	EndDo;
	FillPropertyValues(Result, Selection);
	
	Return Result;
	
EndFunction

// Deletes AttributeArray elements that match object attribute names from 
// the NoncheckableAttributeArray array.
// The procedure is intended to be used in FillCheckProcessing event handlers.
//
// Parameters:
// AttributeArray             - Array of String - contains names of object attributes;
// NoncheckableAttributeArray - Array of String - contains names of object attributes
//                              excluded from checking.
//
Procedure DeleteNoCheckAttributesFromArray(AttributeArray, NoncheckableAttributeArray) Export
	
	For Each ArrayElement In NoncheckableAttributeArray Do
	
		SequenceNumber = AttributeArray.Find(ArrayElement);
		If SequenceNumber <> Undefined Then
			AttributeArray.Delete(SequenceNumber);
		EndIf;
	
	EndDo;
	
EndProcedure

#EndRegion

////////////////////////////////////////////////////////////////////////////////
// ПРОЦЕДУРЫ И ФУНКЦИИ РАБОТЫ С ДИНАМИЧЕСКИМИ СПИСКАМИ

// Возвращает отборы динамического списка как значения заполнения при программном вводе новой строки в список
//
// Параметры:
//  КомпоновщикНастроек  - КомпоновщикНастроекДинамическогоСписка - компоновщик настроек списка
//
// Возвращаемое значение:
//   Структура   - значения отборов для заполнения нового элемента списка
//
Function FillingValuesOfDynamicList(VAL SettingsComposer) Export
	
	FillingValues = New Structure;
	
	ListSettings = SettingsComposer.GetSettings();
	AddFillingValues(ListSettings.Filter.Items, FillingValues);
	
	Return FillingValues;

EndFunction 

Procedure AddFillingValues(FilterCollection, FillingValues)

	For Each FilterItem In FilterCollection Do
	
		If TypeOf(FilterItem) = Type("DataCompositionFilterItem") 
			AND FilterItem.Use 
			AND FilterItem.ComparisonType = DataCompositionComparisonType.Equal Then
			
			FilterDescription = String(FilterItem.LeftValue);
			If StrFind(FilterDescription, ".") = 0 Then
				FillingValues.Insert(FilterDescription, FilterItem.RightValue);
			EndIf;
		ElsIf TypeOf(FilterItem) = Type("DataCompositionFilterItemGroup") 
			AND FilterItem.Use 
			AND FilterItem.GroupType <> DataCompositionFilterItemsGroupType.GroupNOT Then
			
			AddFillingValues(FilterItem.Items, FillingValues);
		EndIf;
	
	EndDo;

EndProcedure

