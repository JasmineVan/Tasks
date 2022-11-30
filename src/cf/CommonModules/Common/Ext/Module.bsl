///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Public

#Region UserNotification

// ACC:142-disable 4 optional parameters for compatibility with the CommonClientServer.InformUser 
// obsolete procedure.

// Generates and displays the message that can relate to a form item.
//
// Parameters:
//  UserMessageText - String - a mesage text.
//  DataKey - AnyRef - the infobase record key or object that message refers to.
//  Field - String - a form attribute description.
//  DataPath - String - a data path (a path to a form attribute).
//  Cancel - Boolean - an output parameter. Always True.
//
// Example:
//
//  1. Showing the message associated with the object attribute near the managed form field
//  CommonClient.InformUser(
//   NStr("en = 'Error message.'"), ,
//   "FieldInFormAttributeObject",
//   "Object");
//
//  An alternative variant of using in the object form module
//  CommonClient.InformUser(
//   NStr("en = 'Error message.'"), ,
//   "Object.FieldInFormAttributeObject");
//
//  2. Showing a message for the form attribute, next to the managed form field:
//  CommonClient.InformUser(
//   NStr("en = 'Error message.'"), ,
//   "FormAttributeName");
//
//  3. To display a message associated with an infobase object:
//  CommonClient.InformUser(
//   NStr("en = 'Error message.'"), InfobaseObject, "Responsible person",,Cancel);
//
//  4. To display a message from a link to an infobase object:
//  CommonClient.InformUser(
//   NStr("en = 'Error message.'"), Reference, , , Cancel);
//
//  Scenarios of incorrect using:
//   1. Passing DataKey and DataPath parameters at the same time.
//   2. Passing a value of an illegal type to the DataKey parameter.
//   3. Specifying a reference without specifying a field (and/or a data path).
//
Procedure MessageToUser( 
	Val MessageToUserText,
	Val DataKey = Undefined,
	Val Field = "",
	Val DataPath = "",
	Cancel = False) Export
	
	IsObject = False;
	
	If DataKey <> Undefined
		AND XMLTypeOf(DataKey) <> Undefined Then
		
		ValueTypeAsString = XMLTypeOf(DataKey).TypeName;
		IsObject = StrFind(ValueTypeAsString, "Object.") > 0;
	EndIf;
	
	CommonInternalClientServer.MessageToUser(
		MessageToUserText,
		DataKey,
		Field,
		DataPath,
		Cancel,
		IsObject);
	
EndProcedure

// ACC:142-enable

// Returns the code of the default configuration language, for example, "en".
//
// Returns:
//  String - language code.
//
Function DefaultLanguageCode() Export
	
	Return Metadata.DefaultLanguage.LanguageCode;
	
EndFunction

#EndRegion

#Region InfobaseData

////////////////////////////////////////////////////////////////////////////////
// Common procedures and functions to manage infobase data.

// Returns a structure containing attribute values retrieved from the infobase using the object reference.
// It is recommended that you use it instead of referring to object attributes via the point from 
// the reference to an object for quick reading of separate object attributes from the database.
//
// To read attribute values regardless of current user rights, enable privileged mode.
// 
//
// Parameters:
//  Ref - AnyRef - the object whose attribute values will be read.
//            - String - full name of the predefined item whose attribute values will be read.
//  Attributes - String - attribute names separated with commas, formatted according to structure 
//                       requirements.
//                       Example: "Code, Description, Parent".
//            - Structure - FixedStructure - keys are field aliases used for resulting structure 
//                       keys, values (optional) are field names. If a value is empty, it is 
//                       considered equal to the key.
//                       If key is defined but the value is not specified, the field name is retrieved from the key.
//            - Array - FixedArray - attribute names formatted according to structure property 
//                       requirements.
//  SelectAllowedItems - Boolean - if True, user rights are considered when executing the object query.
//                                if there is a restriction at the record level, all attributes will 
//                                return with the Undefined value. If there are insufficient rights to work with the table, an exception will appear.
//                                if False, an exception is raised if the user has no rights to 
//                                access the table or any attribute.
//
// Returns:
//  Structure - contains names (keys) and values of the requested attributes.
//            - if a blank string is passed to Attributes, a blank structure returns.
//            - if a blank reference is passed to Ref, a structure matching names of Undefined 
//              attributes returns.
//            - if a reference to nonexisting object (invalid reference) is passed to Ref, all 
//              attributes return as Undefined.
//
Function ObjectAttributesValues(Ref, Val Attributes, SelectAllowedItems = False) Export
	
	// If the name of a predefined item is passed.
	If TypeOf(Ref) = Type("String") Then 
		
		FullNameOfPredefinedItem = Ref;
		
		// Calculating reference from the predefined item name.
		// - Performs additional check of predefined item data. Must be executed in advance.
		Try
			Ref = PredefinedItem(FullNameOfPredefinedItem);
		Except
			ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Неверный первый параметр Ссылка в функции ОбщегоНазначения.ЗначенияРеквизитовОбъекта:
			           |%1'; 
			           |en = 'Invalid value of the Ref parameter, function Common.ObjectAttributesValues:
			           |%1.'; 
			           |pl = 'Błędny pierwszy parametr Link w funkcji Common.ObjectAttributesValues:
			           |%1';
			           |de = 'Falscher erster Parameter der Referenz in der Funktion Common.ObjectAttributesValues:
			           |%1';
			           |ro = 'Primul parametru incorect Linkul în funcția Common.ObjectAttributesValues:
			           |%1';
			           |tr = 'Common.ObjectAttributesValues işlevinde Referans adlı birinci parametre yanlış: 
			           |%1'; 
			           |es_ES = 'El primer parámetro Enlace es incorrecto en la función Common.ObjectAttributesValues:
			           |%1'"), BriefErrorDescription(ErrorInfo()));
			Raise ErrorText;
		EndTry;
		
		// Parsing the full name of the predefined item.
		FullNameParts = StrSplit(FullNameOfPredefinedItem, ".");
		FullMetadataObjectName = FullNameParts[0] + "." + FullNameParts[1];
		
		// If the predefined item is not created in the infobase, check access to the object.
		// In other scenarios, access check is performed during the query.
		If Ref = Undefined Then 
			ObjectMetadata = Metadata.FindByFullName(FullMetadataObjectName);
			If Not AccessRight("Read", ObjectMetadata) Then 
				Raise StringFunctionsClientServer.SubstituteParametersToString(
						NStr("ru = 'Недостаточно прав для работы с таблицей ""%1""'; en = 'Insufficient rights to access table %1.'; pl = 'Nie wystarczające uprawnienia do pracy z tabelą ""%1""';de = 'Unzureichende Rechte für die Arbeit mit der Tabelle ""%1""';ro = 'Drepturi insuficiente pentru lucrul cu tabelul ""%1""';tr = '""%1"" tablosu ile çalışma hakları yetersiz'; es_ES = 'Insuficientes derechos para usar la tabla ""%1""'"), FullMetadataObjectName);
			EndIf;
		EndIf;
		
	Else // If a reference is passed.
		
		Try
			FullMetadataObjectName = Ref.Metadata().FullName(); 
		Except
			Raise 
				NStr("ru = 'Неверный первый параметр Ссылка в функции ОбщегоНазначения.ЗначенияРеквизитовОбъекта: 
				           |- Значение должно быть ссылкой или именем предопределенного элемента'; 
				           |en = 'Invalid value of the Ref parameter, function Common.ObjectAttributesValues:
				           |The value must contain predefined item name or reference.'; 
				           |pl = 'Błędny pierwszy parametr Link w funkcji Common.ObjectAttributesValues: 
				           |- Wartość powinna być linkiem lub nazwą predefiniowanego elementu';
				           |de = 'Falscher erster Parameter der Referenz in der Funktion Common.ObjectAttributesValues:
				           |- Der Wert muss eine Referenz oder der Name eines vordefinierten Elements sein';
				           |ro = 'Primul parametru incorect Referința în funcția Common.ObjectAttributesValues: 
				           |- Valoarea trebuie să fie referință sau nume de element predefinit';
				           |tr = 'Geçersiz ilk parametre Common.ObjectAttributesValues işlevinde referans: 
				           |- değer bir referans veya önceden tanımlanmış öğenin adı olmalıdır'; 
				           |es_ES = 'El primer parámetro Enlace es incorrecto en la función Common.ObjectAttributesValues:
				           |- El valor debe ser enlace o nombre del elemento predeterminado'");
		EndTry;
		
	EndIf;
	
	// Parsing the attributes if the second parameter is String.
	If TypeOf(Attributes) = Type("String") Then
		If IsBlankString(Attributes) Then
			Return New Structure;
		EndIf;
		
		// Trimming whitespaces.
		Attributes = StrReplace(Attributes, " ", "");
		// Converting the parameter to a field array.
		Attributes = StrSplit(Attributes, ",");
	EndIf;
	
	// Converting the attributes to the unified format.
	FieldsStructure = New Structure;
	If TypeOf(Attributes) = Type("Structure")
		Or TypeOf(Attributes) = Type("FixedStructure") Then
		
		FieldsStructure = Attributes;
		
	ElsIf TypeOf(Attributes) = Type("Array")
		Or TypeOf(Attributes) = Type("FixedArray") Then
		
		For Each Attribute In Attributes Do
			
			Try
				FieldAlias = StrReplace(Attribute, ".", "");
				FieldsStructure.Insert(FieldAlias, Attribute);
			Except 
				// If the alias is not a key.
				
				// Searching for field availability error.
				Result = FindObjectAttirbuteAvailabilityError(FullMetadataObjectName, Attributes);
				If Result.Error Then 
					Raise StringFunctionsClientServer.SubstituteParametersToString(
						NStr("ru = 'Неверный второй параметр Реквизиты в функции ОбщегоНазначения.ЗначенияРеквизитовОбъекта: %1'; en = 'Invalid value of the Attributes parameter, function Common.ObjectAttributesValues: %1.'; pl = 'Błędny drugi parametr Atrybuty we funkcji Common.ObjectAttributesValues: %1';de = 'Falscher zweiter Parameter Details in der Funktion Common.ObjectAttributesValues: %1';ro = 'Al doilea parametru incorect Atribute în funcția Common.ObjectAttributesValues: %1';tr = 'Common.ObjectAttributesValues işlevinde Özellikler adlı ikinci parametre yanlış: %1'; es_ES = 'El segundo parámetro Enlace es incorrecto en la función Common.ObjectAttributesValues:%1'"),
						Result.ErrorDescription);
				EndIf;
				
				// Cannot identify the error. Forwarding the original error.
				Raise;
			
			EndTry;
		EndDo;
	Else
		Raise StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Неверный тип второго параметра Реквизиты в функции ОбщегоНазначения.ЗначенияРеквизитовОбъекта: %1'; en = 'Invalid value type for the Attributes parameter, function Common.ObjectAttributesValues: %1.'; pl = 'Błędny rodzaj drugiego parametru Atrybuty we funkcji Common.ObjectAttributesValues: %1';de = 'Falscher zweiter Parametertyp Details in der Funktion Common.ObjectAttributesValues: %1';ro = 'Tip incorect al parametrului al doilea Atribute în funcția Common.ObjectAttributesValues: %1';tr = 'Common.ObjectAttributesValues işlevinde Özellikler adlı ikinci parametre türü yanlış:%1'; es_ES = 'Tipo incorrecto del segundo parámetro Requisitos en la función Common.ObjectAttributesValues:%1'"), 
			String(TypeOf(Attributes)));
	EndIf;
	
	// Preparing the result (will be redefined after the query).
	Result = New Structure;
	
	// Generating the text of query for the selected fields.
	FieldQueryText = "";
	For each KeyAndValue In FieldsStructure Do
		
		FieldName = ?(ValueIsFilled(KeyAndValue.Value),
						KeyAndValue.Value,
						KeyAndValue.Key);
		FieldAlias = KeyAndValue.Key;
		
		FieldQueryText = 
			FieldQueryText + ?(IsBlankString(FieldQueryText), "", ",") + "
			|	" + FieldName + " AS " + FieldAlias;
		
		
		// Adding the field by its alias to the return value.
		Result.Insert(FieldAlias);
		
	EndDo;
	
	// If the predefined item is missing from the infobase.
	// - the result will reflect that the item is unavailable or pass an empty reference.
	If Ref = Undefined Then 
		Return Result;
	EndIf;
	
	QueryText = 
		"SELECT ALLOWED
		|&FieldQueryText
		|FROM
		|	&FullMetadataObjectName AS Table
		|WHERE
		|	Table.Ref = &Ref";
	
	If Not SelectAllowedItems Then 
		QueryText = StrReplace(QueryText, "ALLOWED", "");
	EndIf;
	
	QueryText = StrReplace(QueryText, "&FieldQueryText", FieldQueryText);
	QueryText = StrReplace(QueryText, "&FullMetadataObjectName", FullMetadataObjectName);
	
	// Executing the query.
	Query = New Query;
	Query.SetParameter("Ref", Ref);
	Query.Text = QueryText;
	
	Try
		Selection = Query.Execute().Select();
	Except
		
		// If the attributes were passed as a string, they are already converted to array.
		// If the attributes were passed as an array, no additional conversion is needed.
		// If the attributes were passed as a structure, conversion to array is needed.
		// Otherwise, an exception would be raised.
		If Type("Structure") = TypeOf(Attributes) Then
			Attributes = New Array;
			For each KeyAndValue In FieldsStructure Do
				FieldName = ?(ValueIsFilled(KeyAndValue.Value),
							KeyAndValue.Value,
							KeyAndValue.Key);
				Attributes.Add(FieldName);
			EndDo;
		EndIf;
		
		// Searching for field availability error.
		Result = FindObjectAttirbuteAvailabilityError(FullMetadataObjectName, Attributes);
		If Result.Error Then 
			Raise StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'Неверный второй параметр Реквизиты в функции ОбщегоНазначения.ЗначенияРеквизитовОбъекта: %1'; en = 'Invalid value of the Attributes parameter, function Common.ObjectAttributesValues: %1.'; pl = 'Błędny drugi parametr Atrybuty we funkcji Common.ObjectAttributesValues: %1';de = 'Falscher zweiter Parameter Details in der Funktion Common.ObjectAttributesValues: %1';ro = 'Al doilea parametru incorect Atribute în funcția Common.ObjectAttributesValues: %1';tr = 'Common.ObjectAttributesValues işlevinde Özellikler adlı ikinci parametre yanlış: %1'; es_ES = 'El segundo parámetro Enlace es incorrecto en la función Common.ObjectAttributesValues:%1'"), 
				Result.ErrorDescription);
		EndIf;
		
		// Cannot identify the error. Forwarding the original error.
		Raise;
		
	EndTry;
	
	// Filling in attributes.
	If Selection.Next() Then
		FillPropertyValues(Result, Selection);
	EndIf;
	
	Return Result;
	
EndFunction

// Returns attribute values retrieved from the infobase using the object reference.
// It is recommended that you use it instead of referring to object attributes via the point from 
// the reference to an object for quick reading of separate object attributes from the database.
//
// To read attribute values regardless of current user rights, enable privileged mode.
// 
//
// Parameters:
//  Ref - AnyRef - the object whose attribute values will be read.
//            - String - full name of the predefined item whose attribute values will be read.
//  AttributeName - String - the name of the attribute.
//  SelectAllowedItems - Boolean - if True, user rights are considered when executing the object query.
//                                If a record-level restriction is set, return Undefined.
//                                if the user has no rights to access the table, an exception is raised.
//                                if False, an exception is raised if the user has no rights to 
//                                access the table or any attribute.
//
// Returns:
//  Arbitrary - depends on the type of the read atrribute value.
//               - if a blank reference is passed to Ref, return Undefined.
//               - if a reference to a nonexisting object (invalid reference) is passed to Ref, 
//                 return Undefined.
//
Function ObjectAttributeValue(Ref, AttributeName, SelectAllowedItems = False) Export
	
	If IsBlankString(AttributeName) Then 
		Raise 
			NStr("ru = 'Неверный второй параметр ИмяРеквизита в функции ОбщегоНазначения.ЗначениеРеквизитаОбъекта: 
			           |- Имя реквизита должно быть заполнено'; 
			           |en = 'Invalid value of the AttributeName parameter, function Common.ObjectAttributeValue:
			           |The parameter cannot be empty.'; 
			           |pl = 'Błędny drugi parametr AttributeName w funkcji Common.ObjectAttributeValue: 
			           |- Nazwa atrybutu powinna być wypełniona';
			           |de = 'Falscher zweiter Parameter AttributeName in der Funktion Common.ObjectAttributeValue: 
			           |- Der Name der Requisiten muss ausgefüllt werden';
			           |ro = 'Parametrul doi incorect AttributeName în funcția Common.ObjectAttributeValue: 
			           |- Numele atributului trebuie să fie completat';
			           |tr = 'Common.ObjectAttributeValue işlevinde AttributeName adlı ikinci parametre türü yanlış: 
			           | - Özellik adı doldurulmalıdır'; 
			           |es_ES = 'El segundo parámetro AttributeName es incorrecto en la función Common.ObjectAttributeValue:
			           |- Nombre del requisito debe estar rellenado'");
	EndIf;
	
	Result = ObjectAttributesValues(Ref, AttributeName, SelectAllowedItems);
	Return Result[StrReplace(AttributeName, ".", "")];
	
EndFunction 

// Returns attribute values that were read from the infobase for several objects.
// It is recommended that you use it instead of referring to object attributes via the point from 
// the reference to an object for quick reading of separate object attributes from the database.
//
// To read attribute values regardless of current user rights, enable privileged mode.
// 
//
// Parameters:
//  Refs - Array, FixedArray - references to objects of the same type.
//                    All values of the array must be references to objects of the same type.
//                    If the array is blank, a blank map is returned.
//  Attributes - String - the attributes names, comma-separated, in a format that meets the 
//                       requirements to the structure properties. Example: "Code, Description, Parent".
//            - Array - FixedArray - attribute names formatted according to structure property 
//                       requirements.
//  SelectAllowedItems - Boolean - if True, user rights are considered when executing the object query.
//                                excluding any object from the selection also excludes it from the 
//                                result.
//                                if False, an exception is raised if the user has no rights to 
//                                access the table or any attribute.
//
// Returns:
//  Map - list of objects and their attribute values:
//   * Key - AnyRef - reference to the object.
//   * Value - Structure - values of the attributes:
//    ** Key - String - attribute name.
//    ** Value - Arbitrary - attribute value.
// 
Function ObjectsAttributesValues(References, Val Attributes, SelectAllowedItems = False) Export
	
	If TypeOf(Attributes) = Type("Array") Or TypeOf(Attributes) = Type("FixedArray") Then
		Attributes = StrConcat(Attributes, ",");
	EndIf;
	
	If IsBlankString(Attributes) Then 
		Raise 
			NStr("ru = 'Неверный второй параметр Реквизиты в функции ОбщегоНазначения.ЗначенияРеквизитовОбъектов: 
			           |- Поле объекта должно быть указано'; 
			           |en = 'Invalid value of the Attributes parameter, function Common.ObjectsAttributesValues:
			           |The object field must be specified.'; 
			           |pl = 'Błędny drugi parametr Atrybuty we funkcji Common.ObjectsAttributesValues: 
			           |- Pole obiektu powinno być podane';
			           |de = 'Falscher zweiter Parameter Details in der Funktion Common.ObjectsAttributesValues: 
			           |- Das Objektfeld sollte angegeben werden';
			           |ro = 'Parametrul doi incorect Atribute în funcția Common.ObjectsAttributesValues: 
			           |- Câmpul obiectului trebuie să fie indicat';
			           |tr = 'Common.ObjectsAttributesValues işlevinde Özellik adlı ikinci parametre yanlıştır: 
			           |- Nesne alanı belirtilmelidir'; 
			           |es_ES = 'El segundo parámetro Requisitos es incorrecto en la función Common.ObjectsAttributesValues:
			           |- Campo del objeto debe estar indicado'");
	EndIf;
	
	If StrFind(Attributes, ".") <> 0 Then 
		Raise 
			NStr("ru = 'Неверный второй параметр Реквизиты в функции ОбщегоНазначения.ЗначенияРеквизитовОбъектов: 
			           |- Обращение через точку не поддерживается'; 
			           |en = 'Invalid value of the Attributes parameter, function Common.ObjectsAttributesValues:
			           |Access properties using dot notation is not supported.'; 
			           |pl = 'Błędny drugi parametr Atrybuty we funkcji Common.ObjectsAttributesValues:  
			           |- Zwrot przez kropkę nie jest obsługiwany';
			           |de = 'Falscher zweiter Parameter Details in der Funktion Common.ObjectsAttributesValues: 
			           |- Die Kontaktaufnahme über einen Punkt wird nicht unterstützt';
			           |ro = 'Parametrul doi incorect Atribute în funcția Common.ObjectsAttributesValues: 
			           |- Adresarea prin punct nu este susținută';
			           |tr = 'Common.ObjectsAttributesValues işlevinde Özellik adlı ikinci parametre yanlıştır: 
			           | - Nokta üzerinden başvuru desteklenmiyor'; 
			           |es_ES = 'El segundo parámetro Requisitos es incorrecto en la función Common.ObjectsAttributesValues:
			           |- Llamada a través del punto no se admite'");
	EndIf;
	
	AttributesValues = New Map;
	If References.Count() = 0 Then
		Return AttributesValues;
	EndIf;
	
	FirstRef = References[0];
	
	Try
		FullMetadataObjectName = FirstRef.Metadata().FullName();
	Except
		Raise 
			NStr("ru = 'Неверный первый параметр Ссылки в функции ОбщегоНазначения.ЗначенияРеквизитовОбъектов: 
			           |- Значения массива должны быть ссылками'; 
			           |en = 'Invalid value of the Refs parameter, Common.ObjectsAttributesValues:
			           |The array values must be of the Ref type.'; 
			           |pl = 'Błędny pierwszy parametr Linku w funkcji Common.ObjectsAttributesValues:
			           |- Wartości tablicy powinny być linkami';
			           |de = 'Falscher erster Parameter Referenz in der Funktion Common.ObjectsAttributesValues: 
			           |- Array-Werte sollten Referenzen sein';
			           |ro = 'Primul parametru incorect Referința în funcția Common.ObjectsAttributesValues: 
			           |- Valorile mulțimii trebuie să fie referințe';
			           |tr = 'Common.ObjectsAttributesValues işlevinde Referans adlı ikinci parametre yanlıştır: 
			           | - Küme değerleri referans olmalıdır'; 
			           |es_ES = 'El primer parámetro Enlaces es incorrecto en la función Common.ObjectsAttributesValues: 
			           |-Valores de matriz deben ser enlaces'");
	EndTry;
	
	QueryText =
		"SELECT ALLOWED
		|	Ref AS Ref,
		|	&Attributes
		|FROM
		|	&FullMetadataObjectName AS Table
		|WHERE
		|	Table.Ref IN (&References)";
	
	If Not SelectAllowedItems Then 
		QueryText = StrReplace(QueryText, "ALLOWED", "");
	EndIf;
	
	QueryText = StrReplace(QueryText, "&Attributes", Attributes);
	QueryText = StrReplace(QueryText, "&FullMetadataObjectName", FullMetadataObjectName);
	
	Query = New Query;
	Query.SetParameter("References", References);
	Query.Text = QueryText;
	
	Try
		Selection = Query.Execute().Select();
	Except
		
		// Trimming whitespaces.
		Attributes = StrReplace(Attributes, " ", "");
		// Converting the parameter to a field array.
		Attributes = StrSplit(Attributes, ",");
		
		// Searching for field availability error.
		Result = FindObjectAttirbuteAvailabilityError(FullMetadataObjectName, Attributes);
		If Result.Error Then 
			Raise StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'Неверный второй параметр Реквизиты в функции ОбщегоНазначения.ЗначенияРеквизитовОбъектов: %1'; en = 'Invalid value of the Attributes parameter, function Common.ObjectsAttributesValues: %1.'; pl = 'Błędny drugi parametr Atrybuty we funkcji Common.ObjectsAttributesValues: %1';de = 'Falscher zweiter Parameter Details in der Funktion Common.ObjectsAttributesValues: %1';ro = 'Al doilea parametru incorect Atribute în funcția Common.ObjectsAttributesValues: %1';tr = 'Common.ObjectsAttributesValues işlevinde Özellikler adlı ikinci parametre yanlış: %1'; es_ES = 'El segundo parámetro Requisitos es incorrecto en la función Common.ObjectsAttributesValues: %1'"), 
				Result.ErrorDescription);
		EndIf;
		
		// Cannot identify the error. Forwarding the original error.
		Raise;
		
	EndTry;
	
	While Selection.Next() Do
		Result = New Structure(Attributes);
		FillPropertyValues(Result, Selection);
		AttributesValues[Selection.Ref] = Result;
	EndDo;
	
	Return AttributesValues;
	
EndFunction

// Returns values of the attribute that was read from the infobase for several objects.
// It is recommended that you use it instead of referring to object attributes via the point from 
// the reference to an object for quick reading of separate object attributes from the database.
//
// To read attribute values regardless of current user rights, enable privileged mode.
// 
//
// Parameters:
//  RefArray       - Array - arrays of references to objects of the same type.
//                                All values of the array must be references to objects of the same type.
//  AttributeName - String - for example, "Code".
//  SelectAllowedItems - Boolean - if True, user rights are considered when executing the object query.
//                                excluding any object from the selection also excludes it from the 
//                                result.
//                                if False, an exception is raised if the user has no rights to 
//                                access the table or any attribute.
//
// Returns:
//  Map - Key - reference to the object, Value - the read attribute value.
//      * Key - reference to an object.
//      * Value - the read attribute value.
// 
Function ObjectsAttributeValue(RefsArray, AttributeName, SelectAllowedItems = False) Export
	
	If IsBlankString(AttributeName) Then 
		Raise NStr("ru = 'Неверный второй параметр ИмяРеквизита в функции ОбщегоНазначения.ЗначениеРеквизитаОбъектов: 
		                             |- Имя реквизита должно быть заполнено'; 
		                             |en = 'Invalid value of the AttributeName parameter, function Common.ObjectsAttributeValue:
		                             |The parameter cannot be empty.'; 
		                             |pl = 'Błędny drugi parametr AttributeName w funkcji Common.ObjectsAttributeValue:  
		                             |- Nazwa atrybutu powinna być wypełniona';
		                             |de = 'Falscher zweiter Parameter DetailName in der Funktion Common.ObjectsAttributeValue: \
		                             |- Der Name der Requisiten muss ausgefüllt werden';
		                             |ro = 'Parametrul doi incorect AttributeName în funcția Common.ObjectsAttributeValue: 
		                             |- Numele atributului trebuie să fie completat';
		                             |tr = 'Common.ObjectsAttributeValue işlevinde AttributeName adlı ikinci parametre yanlış: 
		                             | - Özellik adı doldurulmalıdır'; 
		                             |es_ES = 'El segundo parámetro AttributeName es incorrecto en la función Common.ObjectsAttributeValue:
		                             |- Nombre de requisito debe estar rellenado'");
	EndIf;
	
	AttributesValues = ObjectsAttributesValues(RefsArray, AttributeName, SelectAllowedItems);
	For each Item In AttributesValues Do
		AttributesValues[Item.Key] = Item.Value[AttributeName];
	EndDo;
		
	Return AttributesValues;
	
EndFunction

// Returns a reference to the predefined item by its full name.
// Only the following objects can contain predefined objects:
//   - catalogs,
//   - charts of characteristic types,
//   - charts of accounts,
//   - charts of calculation types.
// After changing the list of predefined items, it is recommended that you run
// the UpdateCachedValues() method to clear the cache for Cached modules in the current session.
//
// Parameters:
//   PredefinedItemFullName - String - full path to the predefined item including the name.
//     The format is identical to the PredefinedValue() global context function.
//     Example:
//       "Catalog.ContactInformationKinds.UserEmail"
//       "ChartOfAccounts.SelfFinancing.Materials"
//       "ChartOfCalculationTypes.Accruals.SalaryPayments".
//
// Returns:
//   AnyRef - reference to the predefined item.
//   Undefined - if the predefined item exists in metadata but not in the infobase.
//
Function PredefinedItem(PredefinedItemFullName) Export
	
	If CommonInternalClientServer.UseStandardGettingPredefinedItemFunction(
		PredefinedItemFullName) Then 
		
		Return PredefinedValue(PredefinedItemFullName);
	EndIf;
	
	PredefinedItemFields = CommonInternalClientServer.PredefinedItemNameByFields(PredefinedItemFullName);
	
	PredefinedValues = StandardSubsystemsCached.RefsByPredefinedItemsNames(
		PredefinedItemFields.FullMetadataObjectName);
	
	Return CommonInternalClientServer.PredefinedItem(
		PredefinedItemFullName, PredefinedItemFields, PredefinedValues);
	
EndFunction

// Checks posting status of the passed documents and returns the unposted documents.
// 
//
// Parameters:
//  Documents - Array - documents to check.
//
// Returns:
//  Array - unposted documents.
//
Function CheckDocumentsPosting(Val Documents) Export
	
	Result = New Array;
	
	QueryTemplate = 	
		"SELECT
		|	SpecifiedTableAlias.Ref AS Ref
		|FROM
		|	&DocumentName AS SpecifiedTableAlias
		|WHERE
		|	SpecifiedTableAlias.Ref IN(&DocumentsArray)
		|	AND NOT SpecifiedTableAlias.Posted";
	
	UnionAllText =
		"
		|
		|UNION ALL
		|
		|";
		
	DocumentNames = New Array;
	For Each Document In Documents Do
		DocumentMetadata = Document.Metadata();
		If DocumentNames.Find(DocumentMetadata.FullName()) = Undefined
			AND Metadata.Documents.Contains(DocumentMetadata)
			AND DocumentMetadata.Posting = Metadata.ObjectProperties.Posting.Allow Then
				DocumentNames.Add(DocumentMetadata.FullName());
		EndIf;
	EndDo;
	
	QueryText = "";
	For Each DocumentName In DocumentNames Do
		If Not IsBlankString(QueryText) Then
			QueryText = QueryText + UnionAllText;
		EndIf;
		SubqueryText = StrReplace(QueryTemplate, "&DocumentName", DocumentName);
		QueryText = QueryText + SubqueryText;
	EndDo;
		
	Query = New Query;
	Query.Text = QueryText;
	Query.SetParameter("DocumentsArray", Documents);
	
	If Not IsBlankString(QueryText) Then
		Result = Query.Execute().Unload().UnloadColumn("Ref");
	EndIf;
	
	Return Result;
	
EndFunction

// Attempts to post the documents.
//
// Parameters:
//   Documents - Array - documents to post.
//
// Returns:
//   Array - array of structures with the following properties:
//      * Ref - DocumentRef - document that could not be posted.
//      * ErrorDescription - String         - the text of a posting error.
//
Function PostDocuments(Documents) Export
	
	UnpostedDocuments = New Array;
	
	For Each DocumentRef In Documents Do
		
		ExecutedSuccessfully = False;
		DocumentObject = DocumentRef.GetObject();
		If DocumentObject.CheckFilling() Then
			PostingMode = DocumentPostingMode.Regular;
			If DocumentObject.Date >= BegOfDay(CurrentSessionDate())
				AND DocumentRef.Metadata().RealTimePosting = Metadata.ObjectProperties.RealTimePosting.Allow Then
					PostingMode = DocumentPostingMode.RealTime;
			EndIf;
			Try
				DocumentObject.Write(DocumentWriteMode.Posting, PostingMode);
				ExecutedSuccessfully = True;
			Except
				ErrorPresentation = BriefErrorDescription(ErrorInfo());
			EndTry;
		Else
			ErrorPresentation = NStr("ru = 'Поля документа не заполнены.'; en = 'Document fields cannot be empty.'; pl = 'Pola dokumentu nie są wypełnione.';de = 'Dokumentfelder sind nicht ausgefüllt.';ro = 'Câmpurile documentului nu sunt completate.';tr = 'Belge alanları doldurulmadı.'; es_ES = 'Campos del documento no están poblados.'");
		EndIf;
		
		If Not ExecutedSuccessfully Then
			UnpostedDocuments.Add(New Structure("Ref,ErrorDescription", DocumentRef, ErrorPresentation));
		EndIf;
		
	EndDo;
	
	Return UnpostedDocuments;
	
EndFunction 

// Checks whether there are references to the object in the infobase
// When called in a shared session, does not find references in separated areas.
//
// Parameters:
//  RefOrRefsArray - AnyRef, Array - an object or a list of objects.
//  SearchInInternalObjects - Boolean - if True, exceptions defined during configuration development 
//      are ignored while searching for references.
//      For more details on exceptions during reference search, see CommonOverridable.
//      OnAddReferenceSearchExceptions. 
//
// Returns:
//  Boolean - True if any references to the object are found.
//
Function RefsToObjectFound(Val RefOrRefArray, Val SearchInInternalObjects = False) Export
	
	If TypeOf(RefOrRefArray) = Type("Array") Then
		RefsArray = RefOrRefArray;
	Else
		RefsArray = New Array;
		RefsArray.Add(RefOrRefArray);
	EndIf;
	
	SetPrivilegedMode(True);
	UsageInstances = FindByRef(RefsArray);
	SetPrivilegedMode(False);
	
	// UsageInstances - ValueTable - where:
	// * Ref - AnyRef - the reference to analyze.
	// * Data - Arbitrary - the data that contains the reference to analyze.
	// * Metadata - MetadataObject - metadata for the found data.
	
	If Not SearchInInternalObjects Then
		RefSearchExclusions = RefSearchExclusions();
		Exceptions = New Array;
		
		For Each UsageInstance In UsageInstances Do
			If IsInternalData(UsageInstance, RefSearchExclusions) Then
				Exceptions.Add(UsageInstance);
			EndIf;
		EndDo;
		
		For Each UsageInstance In Exceptions Do
			UsageInstances.Delete(UsageInstance);
		EndDo;
	EndIf;
	
	Return UsageInstances.Count() > 0;
	
EndFunction

// Replaces references in all data. There is an option to delete all unused references after the replacement.
// References are replaced in transactions by the object to be changed and its relations but not by the analyzing reference.
// When called in a shared session, does not find references in separated areas.
//
// Parameters:
//   ReplacementPairs - Map - replacement pairs.
//       * Key     - AnyRef - a reference to be replaced.
//       * Value - AnyRef - a reference to use as a replacement.
//       Self-references and empty search references are ignored.
//   
//   Parameters - Structure - Optional. Replacement parameters.
//       
//       * DeletionMethod - String - optional. What to do with the duplicate after a successful replacement.
//           ""                - default. Do nothing.
//           "Mark"         - mark for deletion.
//           "Directly" - delete directly.
//       
//       * ConsiderAppliedRules - Boolean - optional. ReplacementPairs parameter check mode.
//           True - default. Check each replacement pair by calling
//                    the CanReplaceItems function from the manager module.
//           False   - do not check the replacement pairs.
//       
//       * ConsiderBusinessLogic - Boolean - optional. Usage count record mode when substituting originals for duplicates.
//           True - default. The duplicate usage instances are written in mode DataExchange.Import = False.
//           False   - the duplicate usage instances are written in mode DataExchange.Import = True.
//       
//       * ReplacePairsInTransaction - Boolean - optional. Defines transaction size.
//           True - default. Transaction covers all the instances of a duplicate. Can be very 
//                    resource-demanding in case of a large number of usage instances.
//           False   - use a separate transaction to replace each usage instance.
//       
//       * WriteInPrivilegedMode - Boolean - optional. A flag that shows whether privileged mode must be set.
//           False   - default value. Write with the current rights.
//           True - write in privileged mode.
//
// Returns:
//   ValueTable - unsuccessful replacements (errors).
//       * Reference - AnyRef - a reference that was replaced.
//       * ErrorObject - Arbitrary - object that has caused an error.
//       * ErrorObjectPresentation - String - string representation of an error object.
//       * ErrorType - String - an error type:
//           "LockError" - some objects were locked during the reference processing.
//           "DataChanged" - data was changed by another user during the processing.
//           "WritingError"      - cannot write the object, or the CanReplaceItems method returned a failure.
//           "DeletionError"    - cannot delete the object.
//           "UnknownData" - unexpected data was found during the replacement process. The replacement failed.
//       * ErrorText - String - a detailed error description.
//
Function ReplaceReferences(Val ReplacementPairs, Val Parameters = Undefined) Export
	
	StringType = New TypeDescription("String");
	
	ReplacementErrors = New ValueTable;
	ReplacementErrors.Columns.Add("Ref");
	ReplacementErrors.Columns.Add("ErrorObject");
	ReplacementErrors.Columns.Add("ErrorObjectPresentation", StringType);
	ReplacementErrors.Columns.Add("ErrorType", StringType);
	ReplacementErrors.Columns.Add("ErrorText", StringType);
	
	ReplacementErrors.Indexes.Add("Ref");
	ReplacementErrors.Indexes.Add("Ref, ErrorObject, ErrorType");
	
	Result = New Structure;
	Result.Insert("HasErrors", False);
	Result.Insert("Errors", ReplacementErrors);
	
	// Default values.
	ExecutionParameters = New Structure;
	ExecutionParameters.Insert("DeleteDirectly",     False);
	ExecutionParameters.Insert("MarkForDeletion",         False);
	ExecutionParameters.Insert("IncludeBusinessLogic",       True);
	ExecutionParameters.Insert("WriteInPrivilegedMode",    False);
	ExecutionParameters.Insert("TakeAppliedRulesIntoAccount", False);
	ReplacePairsInTransaction = True;
	
	// Passed values.
	ParameterValue = CommonClientServer.StructureProperty(Parameters, "DeletionMethod");
	If ParameterValue = "Directly" Then
		ExecutionParameters.DeleteDirectly = True;
		ExecutionParameters.MarkForDeletion     = False;
	ElsIf ParameterValue = "Check" Then
		ExecutionParameters.DeleteDirectly = False;
		ExecutionParameters.MarkForDeletion     = True;
	EndIf;
	
	ParameterValue = CommonClientServer.StructureProperty(Parameters, "IncludeBusinessLogic");
	If TypeOf(ParameterValue) = Type("Boolean") Then
		ExecutionParameters.IncludeBusinessLogic = ParameterValue;
	EndIf;
	
	ParameterValue = CommonClientServer.StructureProperty(Parameters, "ReplacePairsInTransaction");
	If TypeOf(ParameterValue) = Type("Boolean") Then
		ReplacePairsInTransaction = ParameterValue;
	EndIf;
	
	ParameterValue = CommonClientServer.StructureProperty(Parameters, "WriteInPrivilegedMode");
	If TypeOf(ParameterValue) = Type("Boolean") Then
		ExecutionParameters.WriteInPrivilegedMode = ParameterValue;
	EndIf;
	
	ParameterValue = CommonClientServer.StructureProperty(Parameters, "TakeAppliedRulesIntoAccount");
	If TypeOf(ParameterValue) = Type("Boolean") Then
		ExecutionParameters.TakeAppliedRulesIntoAccount = ParameterValue;
	EndIf;
	
	If ReplacementPairs.Count() = 0 Then
		Return Result.Errors;
	EndIf;
	
	Duplicates = New Array;
	For Each KeyValue In ReplacementPairs Do
		Duplicate = KeyValue.Key;
		Original = KeyValue.Value;
		If Duplicate = Original Or Duplicate.IsEmpty() Then
			Continue; // Not replacing self-references and empty references.
		EndIf;
		Duplicates.Add(Duplicate);
		// Skipping intermediate replacements to avoid building a graph (if A->B and B->C, replacing A->C).
		OriginalOriginal = ReplacementPairs[Original];
		HasOriginalOriginal = (OriginalOriginal <> Undefined AND OriginalOriginal <> Duplicate AND OriginalOriginal <> Original);
		If HasOriginalOriginal Then
			While HasOriginalOriginal Do
				Original = OriginalOriginal;
				OriginalOriginal = ReplacementPairs[Original];
				HasOriginalOriginal = (OriginalOriginal <> Undefined AND OriginalOriginal <> Duplicate AND OriginalOriginal <> Original);
			EndDo;
			ReplacementPairs.Insert(Duplicate, Original);
		EndIf;
	EndDo;
	
	If ExecutionParameters.TakeAppliedRulesIntoAccount AND SubsystemExists("StandardSubsystems.DuplicateObjectDetection") Then
		ModuleDuplicateObjectsDetection = CommonModule("DuplicateObjectDetection");
		Errors = ModuleDuplicateObjectsDetection.CheckCanReplaceItems(ReplacementPairs, Parameters);
		For Each KeyValue In Errors Do
			Duplicate = KeyValue.Key;
			Original = ReplacementPairs[Duplicate];
			ErrorText = KeyValue.Value;
			Reason = ReplacementErrorDescription("WritingError", Original, SubjectString(Original), ErrorText);
			RegisterReplacementError(Result, Duplicate, Reason);
			
			Index = Duplicates.Find(Duplicate);
			If Index <> Undefined Then
				Duplicates.Delete(Index); // skipping the problem item.
			EndIf;
		EndDo;
	EndIf;
	
	SearchTable = UsageInstances(Duplicates);
	
	// Replacements for each object reference are executed in the following order: "Constant", "Object", "Set".
	// Blank row in this column is also a flag indicating that the replacement is not needed or already done.
	SearchTable.Columns.Add("ReplacementKey", StringType);
	SearchTable.Indexes.Add("Ref, ReplacementKey");
	SearchTable.Indexes.Add("Data, ReplacementKey");
	
	// Auxiliary data
	SearchTable.Columns.Add("DestinationRef");
	SearchTable.Columns.Add("Processed", New TypeDescription("Boolean"));
	
	// Defining the processing order and validating items that can be handled.
	Count = Duplicates.Count();
	For Number = 1 To Count Do
		ReverseIndex = Count - Number;
		Duplicate = Duplicates[ReverseIndex];
		MarkupResult = MarkUsageInstances(ExecutionParameters, Duplicate, ReplacementPairs[Duplicate], SearchTable);
		If Not MarkupResult.Success Then
			// Unknown replacement types are found, skipping the reference to prevent data incoherence.
			Duplicates.Delete(ReverseIndex);
			For Each Error In MarkupResult.MarkupErrors Do
				ErrorObjectPresentation = SubjectString(Error.Object);
				RegisterReplacementError(Result, Duplicate,
					ReplacementErrorDescription("UnknownData", Error.Object, ErrorObjectPresentation, Error.Text));
			EndDo;
		EndIf;
	EndDo;
	
	ExecutionParameters.Insert("ReplacementPairs",      ReplacementPairs);
	ExecutionParameters.Insert("SuccessfulReplacements", New Map);
	
	If SubsystemExists("StandardSubsystems.AccessManagement") Then
		ModuleAccessManagement = CommonModule("AccessManagement");
		ModuleAccessManagement.DisableAccessKeysUpdate(True);
	EndIf;
	
	Try
		If ReplacePairsInTransaction Then
			For Each Duplicate In Duplicates Do
				ReplaceRefUsingSingleTransaction(Result, Duplicate, ExecutionParameters, SearchTable);
			EndDo;
		Else
			ReplaceRefsUsingShortTransactions(Result, ExecutionParameters, Duplicates, SearchTable);
		EndIf;
		
		If SubsystemExists("StandardSubsystems.AccessManagement") Then
			ModuleAccessManagement = CommonModule("AccessManagement");
			ModuleAccessManagement.DisableAccessKeysUpdate(False);
		EndIf;
		
	Except
		If SubsystemExists("StandardSubsystems.AccessManagement") Then
			ModuleAccessManagement = CommonModule("AccessManagement");
			ModuleAccessManagement.DisableAccessKeysUpdate(False);
		EndIf;
		Raise;
	EndTry;
	
	Return Result.Errors;
EndFunction

// Retrieves all places where references are used.
// If any of the references is not used, it will not be presented in the result table.
// When called in a shared session, does not find references in separated areas.
//
// Parameters:
//     RefSet     - Array - references whose usage instances are to be found.
//     ResultAddress - String - an optional address in the temporary storage where the replacement 
//                                result copy will be stored.
// 
// Returns:
//     ValueTable - contains the following columns:
//       * Ref - AnyRef - the reference to analyze.
//       * Data - Arbitrary - the data that contains the reference to analyze.
//       * Metadata - MetadataObject - metadata for the found data.
//       * DataPresentation - String - presentation of the data containing the reference.
//       * RefType - Type - the type of reference to analyze.
//       * AuxiliaryData - Boolean - True if the data is used by the reference as auxiliary data 
//           (leading dimension, or covered by the OnAddReferenceSearchExceptions exception).
//       * IsInternalData - Boolean - the data is covered by the OnAddReferenceSearchExceptions exception.
//
Function UsageInstances(Val RefSet, Val ResultAddress = "") Export
	
	UsageInstances = New ValueTable;
	
	SetPrivilegedMode(True);
	UsageInstances = FindByRef(RefSet);
	SetPrivilegedMode(False);
	
	// UsageInstances - ValueTable - where:
	// * Ref - AnyRef - the reference to analyze.
	// * Data - Arbitrary - the data that contains the reference to analyze.
	// * Metadata - MetadataObject - metadata for the found data.
	
	UsageInstances.Columns.Add("DataPresentation", New TypeDescription("String"));
	UsageInstances.Columns.Add("RefType");
	UsageInstances.Columns.Add("UsageInstanceInfo");
	UsageInstances.Columns.Add("AuxiliaryData", New TypeDescription("Boolean"));
	UsageInstances.Columns.Add("IsInternalData", New TypeDescription("Boolean"));
	
	UsageInstances.Indexes.Add("Ref");
	UsageInstances.Indexes.Add("Data");
	UsageInstances.Indexes.Add("AuxiliaryData");
	UsageInstances.Indexes.Add("Ref, AuxiliaryData");
	
	RecordKeysType = RecordKeysTypeDetails();
	AllRefsType = AllRefsTypeDetails();
	
	SequenceMetadata = Metadata.Sequences;
	ConstantMetadata = Metadata.Constants;
	DocumentMetadata = Metadata.Documents;
	
	RefSearchExclusions = RefSearchExclusions();
	
	RegisterDimensionCache = New Map;
	
	For Each UsageInstance In UsageInstances Do
		DataType = TypeOf(UsageInstance.Data);
		
		IsInternalData = IsInternalData(UsageInstance, RefSearchExclusions);
		IsAuxiliaryData = IsInternalData;
		
		If DocumentMetadata.Contains(UsageInstance.Metadata) Then
			Presentation = String(UsageInstance.Data);
			
		ElsIf ConstantMetadata.Contains(UsageInstance.Metadata) Then
			Presentation = UsageInstance.Metadata.Presentation() + " (" + NStr("ru = 'константа'; en = 'constant'; pl = 'stała';de = 'konstante ';ro = 'constant';tr = 'sabit'; es_ES = 'constante'") + ")";
			
		ElsIf SequenceMetadata.Contains(UsageInstance.Metadata) Then
			Presentation = UsageInstance.Metadata.Presentation() + " (" + NStr("ru = 'последовательность'; en = 'sequence'; pl = 'sekwencja';de = 'Sequenz';ro = 'secvenţă';tr = 'sıra'; es_ES = 'secuencia'") + ")";
			
		ElsIf DataType = Undefined Then
			Presentation = String(UsageInstance.Data);
			
		ElsIf AllRefsType.ContainsType(DataType) Then
			ObjectMetaPresentation = New Structure("ObjectPresentation");
			FillPropertyValues(ObjectMetaPresentation, UsageInstance.Metadata);
			If IsBlankString(ObjectMetaPresentation.ObjectPresentation) Then
				MetaPresentation = UsageInstance.Metadata.Presentation();
			Else
				MetaPresentation = ObjectMetaPresentation.ObjectPresentation;
			EndIf;
			Presentation = String(UsageInstance.Data);
			If Not IsBlankString(MetaPresentation) Then
				Presentation = Presentation + " (" + MetaPresentation + ")";
			EndIf;
			
		ElsIf RecordKeysType.ContainsType(DataType) Then
			Presentation = UsageInstance.Metadata.RecordPresentation;
			If IsBlankString(Presentation) Then
				Presentation = UsageInstance.Metadata.Presentation();
			EndIf;
			
			DimensionsDetails = "";
			For Each KeyValue In RecordSetDimensionsDetails(UsageInstance.Metadata, RegisterDimensionCache) Do
				Value = UsageInstance.Data[KeyValue.Key];
				Details = KeyValue.Value;
				If UsageInstance.Ref = Value Then
					If Details.Master Then
						IsAuxiliaryData = True;
					EndIf;
				EndIf;
				ValueFormat = Details.Format; 
				DimensionsDetails = DimensionsDetails + ", " + Details.Presentation + " """ 
					+ ?(ValueFormat = Undefined, String(Value), Format(Value, ValueFormat)) + """";
			EndDo;
			
			DimensionsDetails = Mid(DimensionsDetails, 3);
			If Not IsBlankString(DimensionsDetails) Then
				Presentation = Presentation + " (" + DimensionsDetails + ")";
			EndIf;
			
		Else
			Presentation = String(UsageInstance.Data);
			
		EndIf;
		
		UsageInstance.DataPresentation = Presentation;
		UsageInstance.AuxiliaryData = IsAuxiliaryData;
		UsageInstance.IsInternalData = IsInternalData;
		UsageInstance.RefType = TypeOf(UsageInstance.Ref);
	EndDo;
	
	If Not IsBlankString(ResultAddress) Then
		PutToTempStorage(UsageInstances, ResultAddress);
	EndIf;
	
	Return UsageInstances;
EndFunction

// Returns an exception when searching for object usage locations.
//
// Returns:
//   Map - reference search exceptions by metadata objects.
//       * Key - MetadataObject - the metadata object to apply exceptions to.
//       * Value - String, Array - descriptions of excluded attributes.
//           If "*", all the metadata object attributes are excluded.
//           If a string array, contains the relative names of the excluded attributes.
//
Function RefSearchExclusions() Export
	
	SearchExceptionsIntegration = New Array;
	
	SSLSubsystemsIntegration.OnAddReferenceSearchExceptions(SearchExceptionsIntegration);
	
	SearchExceptions = New Array;
	CommonOverridable.OnAddReferenceSearchExceptions(SearchExceptions);
	
	CommonClientServer.SupplementArray(SearchExceptions, SearchExceptionsIntegration);
	
	Result = New Map;
	For Each SearchException In SearchExceptions Do
		// Defining the full name of the attribute and the metadata object that owns the attribute.
		If TypeOf(SearchException) = Type("String") Then
			FullName          = SearchException;
			SubstringsArray     = StrSplit(FullName, ".");
			SubstringCount = SubstringsArray.Count();
			MetadataObject   = Metadata.FindByFullName(SubstringsArray[0] + "." + SubstringsArray[1]);
		Else
			MetadataObject   = SearchException;
			FullName          = MetadataObject.FullName();
			SubstringsArray     = StrSplit(FullName, ".");
			SubstringCount = SubstringsArray.Count();
			If SubstringCount > 2 Then
				While True Do
					Parent = MetadataObject.Parent();
					If TypeOf(Parent) = Type("ConfigurationMetadataObject") Then
						Break;
					Else
						MetadataObject = Parent;
					EndIf;
				EndDo;
			EndIf;
		EndIf;
		// Registration.
		If SubstringCount < 4 Then
			Result.Insert(MetadataObject, "*");
		Else
			PathsToAttributes = Result.Get(MetadataObject);
			If PathsToAttributes = "*" Then
				Continue; // The whole metadata object is excluded.
			ElsIf PathsToAttributes = Undefined Then
				PathsToAttributes = New Array;
				Result.Insert(MetadataObject, PathsToAttributes);
			EndIf;
			// The attribute format:
			//   "<MOType>.<MOName>.<TabularSectionOrAttributeType>.<TabularPartOrAttributeName>[.<AttributeType>.<TabularPartName>]".
			//   Examples:
			//     "InformationRegister.ObjectVersions.Attribute.VersionAuthor",
			//     "Document._DemoSalesOrder.TabularPart.SalesProformaInvoice.Attribute.ProformaInvoice",
			//     "ChartOfCalculationTypes._DemoWages.StandardTabularSection.BaseCalculationTypes.StandardAttribute.CalculationType".
			// The relative path to an attribute must conform to query condition text format:
			//   "<TabularPartOrAttributeName>[.<TabularPartAttributeName>]".
			If SubstringCount = 4 Then
				RelativePathToAttribute = SubstringsArray[3];
			Else
				RelativePathToAttribute = SubstringsArray[3] + "." + SubstringsArray[5];
			EndIf;
			PathsToAttributes.Add(RelativePathToAttribute);
		EndIf;
	EndDo;
	Return Result;
	
EndFunction

#EndRegion

#Region ConditionCalls

////////////////////////////////////////////////////////////////////////////////
// Procedures and functions for calling optional subsystems.

// Returns True if the "functional" subsystem exists in the configuration.
// Intended for calling optional subsystems (conditional calls).
//
// A subsystem is considered functional if its "Include in command interface" check box is cleared.
//
// Parameters:
//  FullSubsystemName - String - the full name of the subsystem metadata object without the 
//                        "Subsystem." part, case-sensitive.
//                        Example: "StandardSubsystems.ReportOptions".
//
// Example:
//  If Common.SubsystemExists("StandardSubsystems.ReportOptions") Then
//  	ModuleReportOptions = Common.CommonModule("ReportOptions");
//  	ModuleReportOptions.<Method name>();
//  EndIf.
//
// Returns:
//  Boolean - True if exists.
//
Function SubsystemExists(FullSubsystemName) Export
	
	SubsystemsNames = StandardSubsystemsCached.SubsystemsNames();
	Return SubsystemsNames.Get(FullSubsystemName) <> Undefined;
	
EndFunction

// Returns a reference to a common module or manager module by name.
//
// Parameters:
//  Name - String - name of a common module.
//
// Returns:
//  CommonModule, ObjectManagerModule - a common module.
//
// Example:
//	If Common.SubsystemExists("StandardSubsystems.ConfigurationUpdate") Then
//		ModuleSoftwareUpdate = Common.CommonModule("ConfigurationUpdate");
//		ModuleSoftwareUpdate.<Method name>();
//	EndIf.
//
//	If Common.SubsystemExists("StandardSubsystems.FullTextSearch") then
//		ModuleFullTextSearchServer = Common.CommonModule("FullTextSearchServer").
//		ModuleFullTextSearchServer.<Method name>();
//	EndIf.
//
Function CommonModule(Name) Export
	
	If Metadata.CommonModules.Find(Name) <> Undefined Then
		// ACC:488-disable CalculateInSafeMode is not used, to avoid calling CommonModule recursively.
		SetSafeMode(True);
		Module = Eval(Name);
		// ACC:488-enable
	ElsIf StrOccurrenceCount(Name, ".") = 1 Then
		Return ServerManagerModule(Name);
	Else
		Module = Undefined;
	EndIf;
	
	If TypeOf(Module) <> Type("CommonModule") Then
		Raise StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Общий модуль ""%1"" не найден.'; en = 'Common module %1 is not found.'; pl = 'Nie znaleziono wspólnego modułu ""%1"".';de = 'Gemeinsames Modul ""%1"" wurde nicht gefunden.';ro = 'Modulul comun ""%1"" nu a fost găsit.';tr = 'Ortak modül ""%1"" bulunamadı.'; es_ES = 'Módulo común ""%1"" no se ha encontrado.'"),
			Name);
	EndIf;
	
	Return Module;
	
EndFunction

#EndRegion

#Region CurrentEnvironment

////////////////////////////////////////////////////////////////////////////////
// The details functions of the current client application environment and operating system.

// Returns True if the client application is running on Windows.
//
// Returns:
//  Boolean - False if no client application is available.
//
Function IsWindowsClient() Export
	
	SetPrivilegedMode(True);
	
	IsWindowsClient = StandardSubsystemsServer.ClientParametersAtServer().Get("IsWindowsClient");
	
	If IsWindowsClient = Undefined Then
		Return False; // No client application
	EndIf;
	
	Return IsWindowsClient;
	
EndFunction

// Returns True if the session runs on a Windows server.
//
// Returns:
//  Boolean - True if the server runs on Windows.
//
Function IsWindowsServer() Export
	
	SystemInformation = New SystemInfo;
	Return SystemInformation.PlatformType = PlatformType.Windows_x86 
		Or SystemInformation.PlatformType = PlatformType.Windows_x86_64;
	
EndFunction

// Returns True if the client application is running on Linux.
//
// Returns:
//  Boolean - False if no client application is available.
//
Function IsLinuxClient() Export
	
	SetPrivilegedMode(True);
	
	IsLinuxClient = StandardSubsystemsServer.ClientParametersAtServer().Get("IsLinuxClient");
	
	If IsLinuxClient = Undefined Then
		Return False; // No client application
	EndIf;
	
	Return IsLinuxClient;
	
EndFunction

// Returns True if the current session runs on a Linux server.
//
// Returns:
//  Boolean - True if the server runs on Linux.
//
Function IsLinuxServer() Export
	
	SystemInfo = New SystemInfo;
	Return SystemInfo.PlatformType = PlatformType.Linux_x86 
		Or SystemInfo.PlatformType = PlatformType.Linux_x86_64;
	
EndFunction

// Returns True if the client application runs on OS X.
//
// Returns:
//  Boolean - False if no client application is available.
//
Function IsOSXClient() Export
	
	SetPrivilegedMode(True);
	
	IsOSXClient = StandardSubsystemsServer.ClientParametersAtServer().Get("IsOSXClient");
	
	If IsOSXClient = Undefined Then
		Return False; // No client application
	EndIf;
	
	Return IsOSXClient;
	
EndFunction

// Returns True if the client application is a web client.
//
// Returns:
//  Boolean - False if no client application is available.
//
Function IsWebClient() Export
	
	SetPrivilegedMode(True);
	IsWebClient = StandardSubsystemsServer.ClientParametersAtServer().Get("IsWebClient");
	
	If IsWebClient = Undefined Then
		Return False; // No client application
	EndIf;
	
	Return IsWebClient;
	
EndFunction

// Returns True if the client application is a mobile client.
//
// Returns:
//  Boolean - False if no client application is available.
//
Function IsMobileClient() Export
	
	SetPrivilegedMode(True);
	
	IsMobileClient = StandardSubsystemsServer.ClientParametersAtServer().Get("IsMobileClient");
	
	If IsMobileClient = Undefined Then
		Return False; // No client application
	EndIf;
	
	Return IsMobileClient;
	
EndFunction

// Returns True if a client application is connected to the infobase through a web server.
//
// Returns:
//  Boolean - True if the application is connected.
//
Function ClientConnectedOverWebServer() Export
	
	SetPrivilegedMode(True);
	
	InfobaseConnectionString = StandardSubsystemsServer.ClientParametersAtServer().Get("InfobaseConnectionString");
	
	If InfobaseConnectionString = Undefined Then
		Return False; // No client application
	EndIf;
	
	Return StrFind(Upper(InfobaseConnectionString), "WS=") = 1;
	
EndFunction

// Returns True if debug mode is enabled.
//
// Returns:
//  Boolean - True if debug mode is enabled.
//
Function DebugMode() Export
	
	ApplicationStartupParameter = SessionParameters.ClientParametersAtServer.Get("LaunchParameter");
	Return StrFind(ApplicationStartupParameter, "DebugMode") > 0;
	
EndFunction

// Returns the amount of RAM available to the client application.
//
// Returns:
//  Number - the number of GB of RAM, with tenths-place accuracy.
//  Undefined - no client application is available, meaning CurrentRunMode() = Undefined.
//
Function RAMAvailableForClientApplication() Export
	
	SetPrivilegedMode(True);
	AvailableMemorySize = SessionParameters.ClientParametersAtServer.Get("RAM");
	Return AvailableMemorySize;
	
EndFunction

// Determines the infobase mode: file (True) or client/server (False).
// This function uses the InfobaseConnectionString parameter. You can specify this parameter explicitly.
//
// Parameters:
//  InfobaseConnectionString - String - the parameter is applied if you need to check a connection 
//                 string for another infobase.
//
// Returns:
//  Boolean - True if it is a file infobase.
//
Function FileInfobase(Val InfobaseConnectionString = "") Export
	
	If IsBlankString(InfobaseConnectionString) Then
		InfobaseConnectionString =  InfoBaseConnectionString();
	EndIf;
	Return StrFind(Upper(InfobaseConnectionString), "FILE=") = 1;
	
EndFunction 

// Returns True if the infobase is connected to 1C:Fresh.
//
// Returns:
//  Boolean - indicates a standalone workstation.
//
Function IsStandaloneWorkplace() Export
	
	If SubsystemExists("StandardSubsystems.DataExchange") Then
		ModuleDataExchangeServer = CommonModule("DataExchangeServer");
		Return ModuleDataExchangeServer.IsStandaloneWorkplace();
	EndIf;
	
	Return False;
	
EndFunction

// Determines whether this infobase is a subordinate node of a distributed infobase (DIB).
// 
//
// Returns:
//  Boolean - True if the infobase is a subordinate DIB node.
//
Function IsSubordinateDIBNode() Export
	
	SetPrivilegedMode(True);
	
	Return ExchangePlans.MasterNode() <> Undefined;
	
EndFunction

// Determines whether this infobase is a subordinate node of a distributed infobase (DIB) with 
// filter.
//
// Returns:
//  Boolean - True if the infobase is a subordinate DIB node with filter.
//
Function IsSubordinateDIBNodeWithFilter() Export
	
	SetPrivilegedMode(True);
	
	If ExchangePlans.MasterNode() <> Undefined
		AND SubsystemExists("StandardSubsystems.DataExchange") Then
		CommonModuleDataExchangeServer = CommonModule("DataExchangeServer");
		If CommonModuleDataExchangeServer.ExchangePlanPurpose(ExchangePlans.MasterNode().Metadata().Name) = "DIBWithFilter" Then
			Return True;
		EndIf;
	EndIf;
	
	Return False;
	
EndFunction

// Returns True if update is required for the subordinate DIB node infobase configuration.
// Always False for the master node.
//
// Returns:
//  Boolean - True if required.
//
Function SubordinateDIBNodeConfigurationUpdateRequired() Export
	
	Return IsSubordinateDIBNode() AND ConfigurationChanged();
	
EndFunction

// Returns the data separation mode flag (conditional separation).
// 
// 
// Returns False if the configuration does not support data separation mode (does not contain 
// attributes to share).
//
// Returns:
//  Boolean - True if separation is enabled,
//         - False is separation is disabled or not supported.
//
Function DataSeparationEnabled() Export
	
	If SubsystemExists("StandardSubsystems.SaaS") Then
		ModuleSaaS = CommonModule("SaaS");
		Return ModuleSaaS.DataSeparationEnabled();
	Else
		Return False;
	EndIf;
	
EndFunction

// Returns a flag indicating whether separated data (included in the separators) can be accessed.
// The flag is session-specific, but can change its value if data separation is enabled on the 
// session run. So, check the flag right before addressing the shared data.
// 
// Returns True if the configuration does not support data separation mode (does not contain 
// attributes to share).
//
// Returns:
//   Boolean - True if separation is not supported or disabled or separation is enabled and 
//                    separators are set.
//          - False if separation is enabled and separators are not set.
//
Function SeparatedDataUsageAvailable() Export
	
	If SubsystemExists("StandardSubsystems.SaaS") Then
		ModuleSaaS = CommonModule("SaaS");
		Return ModuleSaaS.SeparatedDataUsageAvailable();
	Else
		Return True;
	EndIf;
	
EndFunction

// Returns infobase publishing URL that is used to generate direct links to infobase objects for 
// internet users.
// For example, if you send a link in an email, the recipient will be able to open the object in the 
// application simply by clicking on the link.
// 
// Returns:
//   String - the infobase address specified in the "Internet address" administration panel setting. 
//            It is stored in the InfobasePublicationURL constant.
//            Example: "http://1c-dn.com/database".
//
// Example: 
//  LocalInfobasePublishingURL() + "/" + e1cib/app/DataProcessor.ExportProjectData";
//  Returns a direct link to open the ExportProjectData data processor.
//
Function InfobasePublicationURL() Export
	
	SetPrivilegedMode(True);
	
	Return Constants.InfobasePublicationURL.Get();
	
EndFunction

// Returns infobase publishing URL that is used to generate direct links to infobase objects for 
// local network users.
// For example, if you send a link in an email, the recipient will be able to open the object in the 
// application simply by clicking on the link.
// 
// Returns:
//   String - the infobase address specified in the "Local address" administration panel setting. It 
//            is stored in the LocalInfobasePublicationURL constant.
//            Example: "http://localserver/base".
//
// Example: 
//  LocalInfobasePublishingURL() + "/" + e1cib/app/DataProcessor.ExportProjectData";
//  Returns a direct link to open the ExportProjectData data processor.
//
Function LocalInfobasePublishingURL() Export
	
	SetPrivilegedMode(True);
	
	Return Constants.LocalInfobasePublishingURL.Get();
	
EndFunction

// Generates the application access address for the specified user.
//
// Parameters:
//  User - String - user's sign-in name.
//  Password - String - user's sign-in password.
//  IBPublicationType - String - publication used by the user to access the application:
//                           "OnInternet" or "OnLocalNetwork".
//
// Returns:
//  String, Undefined - application access address, or Undefined if no address is specified.
Function AuthorizationAddress(User, Password, IBPublicationType) Export
	
	Result = "";
	
	If Lower(IBPublicationType) = Lower("InInternet") Then
		Result = InfobasePublicationURL();
	ElsIf Lower(IBPublicationType) = Lower("InLocalNetwork") Then
		Result = LocalInfobasePublishingURL();
	EndIf;
	
	If IsBlankString(Result) Then
		Return Undefined;
	EndIf;
	
	If Not StrEndsWith(Result, "/") Then
		Result = Result + "/";
	EndIf;
	
	Result = Result + "?n=" + EncodeString(User, StringEncodingMethod.URLEncoding);
	If ValueIsFilled(Password) Then
		Result = Result + "&p=" + EncodeString(Password, StringEncodingMethod.URLEncoding);
	EndIf;
	
	Return Result;
	
EndFunction

// Returns the configuration revision number.
// The revision number is two first digits of a full configuration version.
// Example: revision number for version 1.2.3.4 is 1.2.
//
// Returns:
//  String - configuration revision number.
//
Function ConfigurationRevision() Export
	
	Result = "";
	ConfigurationVersion = Metadata.Version;
	
	Position = StrFind(ConfigurationVersion, ".");
	If Position > 0 Then
		Result = Left(ConfigurationVersion, Position);
		ConfigurationVersion = Mid(ConfigurationVersion, Position + 1);
		Position = StrFind(ConfigurationVersion, ".");
		If Position > 0 Then
			Result = Result + Left(ConfigurationVersion, Position - 1);
		Else
			Result = "";
		EndIf;
	EndIf;
	
	If IsBlankString(Result) Then
		Result = Metadata.Version;
	EndIf;
	
	Return Result;
	
EndFunction

// Common subsystem parameters.
//
// See CommonOverridable.OnDefineCommonBaseFunctionalityParameters 
//
// Returns:
//  Structure - structure with the following properties:
//      * PersonalSettingsFormName            - String - name of the form for editing personal settings.
//                                                           Previously, it used to be defined in
//                                                           CommonOverridable.PersonalSettingsFormName.
//      * AskConfirmationOnExit - Boolean - True by default. If False, the exit confirmation is not 
//                                                                  requested when exiting the 
//                                                                  application, if it is not 
//                                                                  clearly enabled in the personal application settings.
//      * MinPlatformVersion - String - a minimal platform version required to start the program.
//                                                           The application startup on the platform version earlier than the specified one will be unavailable.
//                                                           For example, "8.3.6.1650".
//      * RecommendedPlatformVersion - String - a recommended platform version for the application startup.
//                                                           For example, "8.3.8.2137".
//      * DisableMetadataObjectsIDs - Boolean - disables completing the MetadataObjectIDs and 
//              ExtensionObjectsIDs catalogs, as well as the export/import procedure for DIB nodes.
//              For partial embedding certain library functions into the configuration without enabling support.
//      * RecommendedRAM - Number - amount of memory in gigabytes, recommended for the application.
//                                                      
//    Obsolete. Use MinimumPlatformVersion and RecommendedPlatformVersion properties instead:
//      * MinPlatformVersion    - String - the full platform version required to start the application.
//                                                           For example, "8.3.4.365".
//                                                           Previously, it used to be defined in
//                                                           CommonOverridable.GetMinRequiredPlatformVersion
//      * MustExit               - Boolean - False by default.
//
Function CommonCoreParameters() Export
	
	CommonParameters = New Structure;
	CommonParameters.Insert("PersonalSettingsFormName", "");
	CommonParameters.Insert("AskConfirmationOnExit", True);
	CommonParameters.Insert("DisableMetadataObjectsIDs", False);
	CommonParameters.Insert("RecommendedRAM", 2);
	CommonParameters.Insert("MinPlatformVersion", "8.3.12.1412");
	CommonParameters.Insert("RecommendedPlatformVersion", "8.3.12.1412");
	// Obsolete. Use MinPlatformVersion and RecommendedPlatformVersion properties instead:
	CommonParameters.Insert("MinPlatformVersion", "");
	CommonParameters.Insert("MustExit", False); // Aborting startup if the current version is earlier than the minimum version.
	
	CommonOverridable.OnDetermineCommonCoreParameters(CommonParameters);
	
	Min   = CommonParameters.MinPlatformVersion;
	Recommended = CommonParameters.RecommendedPlatformVersion;
	If Not IsBlankString(Min)
		AND Not IsBlankString(Recommended)
		AND CommonClientServer.CompareVersions(Min, Recommended) > 0 Then
		MessageText = NStr("ru = 'Минимальная версия платформы ""1С:Предприятие 8"" указана выше рекомендуемой.
			|Минимальная версия - ""%1"", рекомендуемая версия - ""%2"".'; 
			|en = 'The minimum 1C:Enterprise version is greater than the recommended version.
			|Minimum version:%1, recommended version:%2.'; 
			|pl = 'Minimalna wersja platformy ""1C:Enterprise 8"" jest wskazana wyższa od zalecanej.
			|Minimalna wersja - ""%1"", zalecana wersja - ""%2"".';
			|de = 'Die Mindestversion der Plattform ""1C:Enterprise 8"" ist oberhalb der empfohlenen Version angegeben.
			|Die minimale Version ist ""%1"", die empfohlene Version ist ""%2"".';
			|ro = 'Versiunea minimă a platformei ""1С:Enterprise 8"" este indicată mai sus de cea recomandată.
			|Versiunea minimă - ""%1"", versiunea recomandată - ""%2"".';
			|tr = '""1C:İşletme 8"" platformun minimum sürümü önerilenden daha yüksek olarak belirtilmiştir. 
			| Minimum sürüm - ""%1"" , önerilen sürüm - ""%2"".'; 
			|es_ES = 'La versión mínima de la plataforma ""1C:Enterprise 8"" está indicada superior que la recomendada.
			|La versión mínima - ""%1"", la versión recomendada - ""%2"".'");
		Raise StringFunctionsClientServer.SubstituteParametersToString(
			MessageText,
			CommonParameters.MinPlatformVersion,
			CommonParameters.RecommendedPlatformVersion);
	EndIf;
	
	// Backward compatibility.
	MinPlatformVersion = CommonParameters.MinPlatformVersion;
	If ValueIsFilled(MinPlatformVersion) Then
		If CommonParameters.MustExit Then
			CommonParameters.MinPlatformVersion   = MinPlatformVersion;
			CommonParameters.RecommendedPlatformVersion = "";
		Else
			CommonParameters.RecommendedPlatformVersion = MinPlatformVersion;
			CommonParameters.MinPlatformVersion   = "";
		EndIf;
	Else
		SystemInfo = New SystemInfo;
		ActualVersion             = SystemInfo.AppVersion;
		If CommonClientServer.CompareVersions(Min, ActualVersion) > 0 Then
			CommonParameters.MinPlatformVersion = Min;
			CommonParameters.MustExit = True;
		Else
			CommonParameters.MinPlatformVersion = Recommended;
			CommonParameters.MustExit = False;
		EndIf;
	EndIf;
	
	Return CommonParameters;
	
EndFunction

// Returns descriptions of all configuration libraries, including the configuration itself.
// 
//
// Returns:
//  Array - an array of structures with the following properties:
//     * Name                 - String - a subsystem name (for example, StandardSubsystems).
//     * OnlineSupportID - String - a unique application name in online support services.
//     * Version              - String - version number in a four-digit format (for example, "2.1.3.1").
//     * IsConfiguration                - Boolean - indicates that this subsystem is the main configuration.
//
Function SubsystemsDetails() Export
	Result = New Array;
	SubsystemsDetails = StandardSubsystemsCached.SubsystemsDetails();
	For Each SubsystemDetails In SubsystemsDetails.ByNames Do
		Parameters = New Structure;
		Parameters.Insert("Name");
		Parameters.Insert("OnlineSupportID");
		Parameters.Insert("Version");
		Parameters.Insert("IsConfiguration");
		
		FillPropertyValues(Parameters, SubsystemDetails.Value);
		Result.Add(Parameters);
	EndDo;
	
	Return Result;
EndFunction

// Returns ID of the main configuration online support.
//
// Returns:
//  String - a unique application name in online support services.
//
Function ConfigurationOnlineSupportID() Export
	SubsystemsDetails = StandardSubsystemsCached.SubsystemsDetails();
	For Each SubsystemDetails In SubsystemsDetails.ByNames Do
		If SubsystemDetails.Value.IsConfiguration Then
			Return SubsystemDetails.Value.OnlineSupportID;
		EndIf;
	EndDo;
EndFunction

#EndRegion

#Region Dates

////////////////////////////////////////////////////////////////////////////////
// Functions to work with dates considering the session timezone

// Convert a local date to the "YYYY-MM-DDThh:mm:ssTZD" format (ISO 8601).
//
// Parameters:
//  LocalDate - Date - a date in the session time zone.
// 
// Returns:
//   String - the date sting presentation.
//
Function LocalDatePresentationWithOffset(LocalDate) Export
	
	Offset = StandardTimeOffset(SessionTimeZone());
	Return CommonInternalClientServer.LocalDatePresentationWithOffset(LocalDate, Offset);
	
EndFunction

// Returns a string presentation of a time period between the passed dates or between the passed 
// date and the current session date.
//
// Parameters:
//  BeginTime - Date - starting point of the time period.
//  EndTime - Date - ending point of the time period; if not specified, the current session date is used instead.
//
// Returns:
//  String - a time period presentation.
//
Function TimeIntervalString(StartTime, EndTime = Undefined) Export
	
	If EndTime = Undefined Then
		EndTime = CurrentSessionDate();
	ElsIf StartTime > EndTime Then
		Raise NStr("ru = 'Дата окончания интервала не может быть меньше даты начала.'; en = 'The end date cannot be earlier than the start date.'; pl = 'Data zakończenia nie może być wcześniejsza od daty rozpoczęcia.';de = 'Das Enddatum darf nicht vor dem Startdatum liegen.';ro = 'Data de sfârșit nu poate fi mai mare decât data de început.';tr = 'Bitiş tarihi, başlangıç tarihinden önce olamaz.'; es_ES = 'La fecha del fin no puede ser anterior a la fecha del inicio.'");
	EndIf;
	
	IntervalValue = EndTime - StartTime;
	IntervalValueInDays = Int(IntervalValue/60/60/24);
	
	If IntervalValueInDays > 365 Then
		IntervalDetails = NStr("ru = 'более года'; en = 'more than a year'; pl = 'ponad rok';de = 'mehr als ein Jahr';ro = 'mai mult de un an';tr = 'bir yıldan fazla'; es_ES = 'más de un año'");
	ElsIf IntervalValueInDays > 31 Then
		IntervalDetails = NStr("ru = 'более месяца'; en = 'more than a month'; pl = 'ponad miesiąc';de = 'mehr als ein Monat';ro = 'mai mult de o lună';tr = 'bir aydan fazla'; es_ES = 'más de un mes'");
	ElsIf IntervalValueInDays >= 1 Then
		IntervalDetails = Format(IntervalValueInDays, "NFD=0") + " "
			+ UsersInternalClientServer.IntegerSubject(IntervalValueInDays,
				"", NStr("ru = 'день,дня,дней,,,,,,0'; en = 'day,days,,,0'; pl = 'dzień, dni,,,0';de = 'Tag, Tag, Tage ,,,,,, 0';ro = 'zi,zile,zile,,,,,,0';tr = 'gün, gün, gün,,,,,,0'; es_ES = 'día,días,,,0'"));
	Else
		IntervalDetails = NStr("ru = 'менее одного дня'; en = 'less than a day'; pl = 'mniej niż jeden dzień';de = 'weniger als ein Tag';ro = 'mai puțin de o zi';tr = 'bir günden az'; es_ES = 'menos de un día'");
	EndIf;
	
	Return IntervalDetails;
	
EndFunction

////////////////////////////////////////////////////////////////////////////////
// Working date functions.

// Save user working date settings.
//
// Parameters:
//	NewWorkingDate - Date - the date to be set as a working date for the user.
//	Username - String - name of the user, for whom the working date is set.
//		If not set, the current user working date will be set.
//			
Procedure SetUserWorkingDate(NewWorkingDate, Username = Undefined) Export

	ObjectKey = Upper("WorkingDate");
	
	CommonSettingsStorageSave(ObjectKey, "", NewWorkingDate, , Username);

EndProcedure

// Returns the user working date settings value.
//
// Parameters:
//	Username - String - name of the user whose working date is requested.
//		If not set, the current user working date will be set.
//
// Returns:
//	Date - user working date setting value, or a blank date if no settings are found.
//
Function UserWorkingDate(Username = Undefined) Export

	ObjectKey = Upper("WorkingDate");

	Result = CommonSettingsStorageLoad(ObjectKey, "", '0001-01-01', , Username);
	
	If TypeOf(Result) <> Type("Date") Then
		Result = '0001-01-01';
	EndIf;
	
	Return Result;
	
EndFunction

// Returns the user working date settings value or the current session date if the user working date 
// is not set.
//
// Parameters:
//	Username - String - name of the user whose working date is requested.
//		If not set, the current user working date will be set.
//
// Returns:
//	Date - a user working date setting value, or the current session date if no settings are found.
//
Function CurrentUserDate(Username = Undefined) Export

	Result = UserWorkingDate(Username);
	
	If NOT ValueIsFilled(Result) Then
		Result = CurrentSessionDate();
	EndIf;
	
	Return BegOfDay(Result);
	
EndFunction

#EndRegion

#Region Data

////////////////////////////////////////////////////////////////////////////////
// Common procedures and functions for applied types and value collections.

// Returns the enumeration value name string by its reference.
//
// Parameters:
//  Value - EnumRef - the value whose enumeration name is sought.
//
// Returns:
//  String - the name of the enumeration value.
//
Function EnumValueName(Value) Export
	
	MetadataObject = Value.Metadata();
	
	ValueIndex = Enums[MetadataObject.Name].IndexOf(Value);
	
	Return MetadataObject.EnumValues[ValueIndex].Name;
	
EndFunction 

// Deletes AttributeArray elements that match object attribute names from the 
// NoncheckableAttributeArray array.
// The procedure is intended to be used in FillCheckProcessing event handlers.
//
// Parameters:
//  AttributeArray              - Array - collection of the object attribute names.
//  NotCheckedAttributeArray - Array - collection of the object attribute names that are not checked.
//
Procedure DeleteNotCheckedAttributesFromArray(AttributesArray, NotCheckedAttributeArray) Export
	
	For Each ArrayElement In NotCheckedAttributeArray Do
	
		SequenceNumber = AttributesArray.Find(ArrayElement);
		If SequenceNumber <> Undefined Then
			AttributesArray.Delete(SequenceNumber);
		EndIf;
	
	EndDo;
	
EndProcedure

// Converts a value table to a structure array.
// Can be used to pass data to a client if the value table contains only those values that can be 
// passed from the server to a client.
// 
//
// The resulting array contains structures that duplicate value table row structures.
// 
//
// It is recommended that you do not use this procedure to convert value tables with a large number 
// of rows.
//
// Parameters:
//  ValueTable - ValueTable - the original value table.
//
// Returns:
//  Array - collection of the table rows expressed as structures.
//
Function ValueTableToArray(ValueTable) Export
	
	Array = New Array();
	StructureString = "";
	CommaRequired = False;
	For Each Column In ValueTable.Columns Do
		If CommaRequired Then
			StructureString = StructureString + ",";
		EndIf;
		StructureString = StructureString + Column.Name;
		CommaRequired = True;
	EndDo;
	For Each Row In ValueTable Do
		NewRow = New Structure(StructureString);
		FillPropertyValues(NewRow, Row);
		Array.Add(NewRow);
	EndDo;
	Return Array;

EndFunction

// Converts a value table row to a structure.
// Structure properties and their values correspond to the columns of the passed row.
//
// Parameters:
//  ValueTableRow - ValueTableRow - the value table row.
//
// Returns:
//  Structure - the converted value table row.
//
Function ValueTableRowToStructure(ValueTableRow) Export
	
	Structure = New Structure;
	For each Column In ValueTableRow.Owner().Columns Do
		Structure.Insert(Column.Name, ValueTableRow[Column.Name]);
	EndDo;
	
	Return Structure;
	
EndFunction

// Creates a structure containing names and values of dimensions, resources, and attributes passed 
// from information register record manager.
//
// Parameters:
//  RecordManager    - InformationRegisterRecordManager - the record manager that must pass the structure.
//  RegisterMetadata - MetadataObject - the information register metadata.
//
// Returns:
//  Structure - a collection of dimensions, resources, and attributes passed to the record manager.
//
Function StructureByRecordManager(RecordManager, RegisterMetadata) Export
	
	RecordAsStructure = New Structure;
	
	If RegisterMetadata.InformationRegisterPeriodicity <> Metadata.ObjectProperties.InformationRegisterPeriodicity.Nonperiodical Then
		RecordAsStructure.Insert("Period", RecordManager.Period);
	EndIf;
	For Each Field In RegisterMetadata.Dimensions Do
		RecordAsStructure.Insert(Field.Name, RecordManager[Field.Name]);
	EndDo;
	For Each Field In RegisterMetadata.Resources Do
		RecordAsStructure.Insert(Field.Name, RecordManager[Field.Name]);
	EndDo;
	For Each Field In RegisterMetadata.Attributes Do
		RecordAsStructure.Insert(Field.Name, RecordManager[Field.Name]);
	EndDo;
	
	Return RecordAsStructure;
	
EndFunction

// Creates an array and fills it with values from the column of the object that can be iterated 
// using For each... From operator.
//
// Parameters:
//  RowCollection           - ValueTable,
//                             ValueTree,
//                             ValueList,
//                             TabularSection,
//                             Map,
//                             Structure - a collection whose column must be exported to an array.
//                                         And other objects that can be iterated using For each... 
//                                         From... Do operator.
//  ColumnName - String - the name of the collection field whose values must be exported.
//  UniqueValuesOnly - Boolean - if True, only unique values will be added to the array.
//                                      
//
// Returns:
//  Array - the column values.
//
Function UnloadColumn(RowsCollection, ColumnName, UniqueValuesOnly = False) Export

	ArrayOfValues = New Array;
	
	UniqueValues = New Map;
	
	For each CollectionRow In RowsCollection Do
		Value = CollectionRow[ColumnName];
		If UniqueValuesOnly AND UniqueValues[Value] <> Undefined Then
			Continue;
		EndIf;
		ArrayOfValues.Add(Value);
		UniqueValues.Insert(Value, True);
	EndDo; 
	
	Return ArrayOfValues;
	
EndFunction

// Converts XML text into a structure with value tables. The function creates table columns based on 
// the XML description.
//
// XML schema:
// <?xml version="1.0" encoding="utf-8"?>
//  <xs:schema attributeFormDefault="unqualified" elementFormDefault="qualified" xmlns:xs="http://www.w3.org/2001/XMLSchema">
//   <xs:element name="Items">
//    <xs:complexType>
//     <xs:sequence>
//      <xs:element maxOccurs="unbounded" name="Item">
//       <xs:complexType>
//        <xs:attribute name="Code" type="xs:integer" use="required" />
//        <xs:attribute name="Name" type="xs:string" use="required" />
//        <xs:attribute name="Socr" type="xs:string" use="required" />
//        <xs:attribute name="Index" type="xs:string" use="required" />
//       </xs:complexType>
//      </xs:element>
//     </xs:sequence>
//    <xs:attribute name="Description" type="xs:string" use="required" />
//    <xs:attribute name="Columns" type="xs:string" use="required" />
//   </xs:complexType>
//  </xs:element>
// </xs:schema>
//
// Parameters:
//  XML - String, ReadXML - text in XML or ReadXML format.
//
// Returns:
//  Structure - with the following properties:
//   * TableName - String - a table name.
//   * Data - ValueTable - the table converted from XML.
//
// Example:
//   ClassifierTable = ReadXMLToTable(
//     DataProcessors.ImportCurrenciesRates.GetTemplate("CurrencyClassifier").GetText()).Data;
//
Function ReadXMLToTable(Val XML) Export
	
	If TypeOf(XML) <> Type("XMLReader") Then
		Read = New XMLReader;
		Read.SetString(XML);
	Else
		Read = XML;
	EndIf;
	
	// Reading the first node and checking it.
	If Not Read.Read() Then
		Raise NStr("ru = 'Пустой XML'; en = 'The XML file is empty.'; pl = 'Pusty XML';de = 'Leeres XML';ro = 'XML gol';tr = 'Boş XML'; es_ES = 'XML vacío'");
	ElsIf Read.Name <> "Items" Then
		Raise NStr("ru = 'Ошибка в структуре XML'; en = 'XML file format error.'; pl = 'Wystąpił błąd w strukturze XML';de = 'In der XML-Struktur ist ein Fehler aufgetreten';ro = 'Eroare în structura XML';tr = 'XML yapısında bir hata oluştu'; es_ES = 'Ha ocurrido un error en la estructura XML'");
	EndIf;
	
	// Getting table details and creating the table.
	TableName = Read.GetAttribute("Description");
	ColumnNames = StrReplace(Read.GetAttribute("Columns"), ",", Chars.LF);
	Columns = StrLineCount(ColumnNames);
	
	ValueTable = New ValueTable;
	For Cnt = 1 To Columns Do
		ValueTable.Columns.Add(StrGetLine(ColumnNames, Cnt), New TypeDescription("String"));
	EndDo;
	
	// Filling the table with values.
	While Read.Read() Do
		
		If Read.NodeType = XMLNodeType.EndElement AND Read.Name = "Items" Then
			Break;
		ElsIf Read.NodeType <> XMLNodeType.StartElement Then
			Continue;
		ElsIf Read.Name <> "Item" Then
			Raise NStr("ru = 'Ошибка в структуре XML'; en = 'XML file format error.'; pl = 'Wystąpił błąd w strukturze XML';de = 'In der XML-Struktur ist ein Fehler aufgetreten';ro = 'Eroare în structura XML';tr = 'XML yapısında bir hata oluştu'; es_ES = 'Ha ocurrido un error en la estructura XML'");
		EndIf;
		
		newRow = ValueTable.Add();
		For Cnt = 1 To Columns Do
			ColumnName = StrGetLine(ColumnNames, Cnt);
			newRow[Cnt-1] = Read.GetAttribute(ColumnName);
		EndDo;
		
	EndDo;
	
	// Filling the resulting value table
	Result = New Structure;
	Result.Insert("TableName", TableName);
	Result.Insert("Data", ValueTable);
	
	Return Result;
	
EndFunction

// Compares two row collections (ValueTable, ValueTree, and so on) that can be iterated using For 
// each... From... Do operator.
// Both collections must meet the following requirements:
//  - can be iterated using For each... From... Do operator
//  - contain all columns listed in ColumnNames
//  (if ColumnNames is not filled, the second collection must contain all columns of the first collection)
//  Compares arrays as well.
//
// Parameters:
//  RowsCollection1 - ValueTable,
//                    ValueTree,
//                    ValueList,
//                    TabularSection,
//                    Map,
//                    Array,
//                    FixedArray,
//                    Structure - a collection meeting the above requirements.
//                                And other objects that can be iterated using For each... From... 
//                                Do operator.
//  RowsCollection2 - ValueTable,
//                    ValueTree,
//                    ValueList,
//                    TabularSection,
//                    Map,
//                    Array,
//                    FixedArray,
//                    Structure - a collection meeting the above requirements.
//                                And other objects that can be iterated using For each... From... 
//                                Do operator.
//  ColumnsNames - String - (optional) the names of columns used for comparison, comma-separated.
//                          This parameter is optional for collections that allow retrieving their column names automatically:
//                          ValueTable, ValuesList, Map, Structure.
//                          If not specified, comparison is performed by columns of the first collection.
//                          For collections of other types, this parameter is mandatory.
//  ExcludingColumns - String - names of columns not included in the comparison.
//  UseRowOrder - Boolean - if True, the collections are considered identical only if they contain 
//                      the same rows in the same order.
//
// Returns:
//  Boolean - True if the collections are identical.
//
Function IdenticalCollections(RowsCollection1, RowsCollection2, Val ColumnNames = "", Val ExcludingColumns = "", 
	UseRowOrder = False) Export
	
	CollectionType = TypeOf(RowsCollection1);
	ArraysCompared = (CollectionType = Type("Array") Or CollectionType = Type("FixedArray"));
	
	ColumnsToCompare = Undefined;
	If Not ArraysCompared Then
		ColumnsToCompare = ColumnsToCompare(RowsCollection1, ColumnNames, ExcludingColumns);
	EndIf;
	
	If UseRowOrder Then
		Return SequenceSensitiveToCompare(RowsCollection1, RowsCollection2, ColumnsToCompare);
	ElsIf ArraysCompared Then // Using a simplified algorithm for arrays.
		Return CompareArrays(RowsCollection1, RowsCollection2);
	Else
		Return SequenceIgnoreSensitiveToCompare(RowsCollection1, RowsCollection2, ColumnsToCompare);
	EndIf;
	
EndFunction

// Compares data of a complex structure taking nesting into account.
//
// Parameters:
//  Data1 - Structure, FixedStructure,
//            Map, FixedMap,
//            Array, FixedArray,
//            ValueStorage, ValueTable,
//            String, Number, Boolean - data to compare.
//
//  Data2 - Arbitrary - the same types as the Data1 parameter types.
//
// Returns:
//  Boolean - True if the types match.
//
Function DataMatch(Data1, Data2) Export
	
	If TypeOf(Data1) <> TypeOf(Data2) Then
		Return False;
	EndIf;
	
	If TypeOf(Data1) = Type("Structure")
	 OR TypeOf(Data1) = Type("FixedStructure") Then
		
		If Data1.Count() <> Data2.Count() Then
			Return False;
		EndIf;
		
		For each KeyAndValue In Data1 Do
			PreviousValue = Undefined;
			
			If NOT Data2.Property(KeyAndValue.Key, PreviousValue)
			 OR NOT DataMatch(KeyAndValue.Value, PreviousValue) Then
			
				Return False;
			EndIf;
		EndDo;
		
		Return True;
		
	ElsIf TypeOf(Data1) = Type("Map")
	      OR TypeOf(Data1) = Type("FixedMap") Then
		
		If Data1.Count() <> Data2.Count() Then
			Return False;
		EndIf;
		
		NewMapKeys = New Map;
		
		For each KeyAndValue In Data1 Do
			NewMapKeys.Insert(KeyAndValue.Key, True);
			PreviousValue = Data2.Get(KeyAndValue.Key);
			
			If NOT DataMatch(KeyAndValue.Value, PreviousValue) Then
				Return False;
			EndIf;
		EndDo;
		
		For each KeyAndValue In Data2 Do
			If NewMapKeys[KeyAndValue.Key] = Undefined Then
				Return False;
			EndIf;
		EndDo;
		
		Return True;
		
	ElsIf TypeOf(Data1) = Type("Array")
	      OR TypeOf(Data1) = Type("FixedArray") Then
		
		If Data1.Count() <> Data2.Count() Then
			Return False;
		EndIf;
		
		Index = Data1.Count()-1;
		While Index >= 0 Do
			If NOT DataMatch(Data1.Get(Index), Data2.Get(Index)) Then
				Return False;
			EndIf;
			Index = Index - 1;
		EndDo;
		
		Return True;
		
	ElsIf TypeOf(Data1) = Type("ValueTable") Then
		
		If Data1.Count() <> Data2.Count() Then
			Return False;
		EndIf;
		
		If Data1.Columns.Count() <> Data2.Columns.Count() Then
			Return False;
		EndIf;
		
		For each Column In Data1.Columns Do
			If Data2.Columns.Find(Column.Name) = Undefined Then
				Return False;
			EndIf;
			
			Index = Data1.Count()-1;
			While Index >= 0 Do
				If NOT DataMatch(Data1[Index][Column.Name], Data2[Index][Column.Name]) Then
					Return False;
				EndIf;
				Index = Index - 1;
			EndDo;
		EndDo;
		
		Return True;
		
	ElsIf TypeOf(Data1) = Type("ValueStorage") Then
	
		If NOT DataMatch(Data1.Get(), Data2.Get()) Then
			Return False;
		EndIf;
		
		Return True;
	EndIf;
	
	Return Data1 = Data2;
	
EndFunction

// Records data of the Structure, Map, and Array types taking nesting into account.
//
// Parameters:
//  Data - Structure, Map, Array - the collections, whose values are primitive types, value storages, 
//           or cannot be changed. The following value types are supported:
//           Boolean, String, Number, Date, Undefined, UUID, Null, Type,
//           ValueStorage, CommonModule, MetadataObject, XDTOValueType, XDTOObjectType,
//           AnyRef.
//
//  RaiseException - Boolean - the default value is True. If it is False and there is data that 
//                                cannot be fixed, no exception is raised but as much data as 
//                                possible is fixed.
//
// Returns:
//  FixedStructure, FixedMap, FixedArray - fixed data similar to the one passed in the Data 
//  parameter.
// 
Function FixedData(Data, RaiseException = True) Export
	
	If TypeOf(Data) = Type("Array") Then
		Array = New Array;
		
		For each Value In Data Do
			
			If TypeOf(Value) = Type("Structure")
			 OR TypeOf(Value) = Type("Map")
			 OR TypeOf(Value) = Type("Array") Then
				
				Array.Add(FixedData(Value, RaiseException));
			Else
				If RaiseException Then
					CheckFixedData(Value, True);
				EndIf;
				Array.Add(Value);
			EndIf;
		EndDo;
		
		Return New FixedArray(Array);
		
	ElsIf TypeOf(Data) = Type("Structure")
	      OR TypeOf(Data) = Type("Map") Then
		
		If TypeOf(Data) = Type("Structure") Then
			Collection = New Structure;
		Else
			Collection = New Map;
		EndIf;
		
		For each KeyAndValue In Data Do
			Value = KeyAndValue.Value;
			
			If TypeOf(Value) = Type("Structure")
			 OR TypeOf(Value) = Type("Map")
			 OR TypeOf(Value) = Type("Array") Then
				
				Collection.Insert(
					KeyAndValue.Key, FixedData(Value, RaiseException));
			Else
				If RaiseException Then
					CheckFixedData(Value, True);
				EndIf;
				Collection.Insert(KeyAndValue.Key, Value);
			EndIf;
		EndDo;
		
		If TypeOf(Data) = Type("Structure") Then
			Return New FixedStructure(Collection);
		Else
			Return New FixedMap(Collection);
		EndIf;
		
	ElsIf RaiseException Then
		CheckFixedData(Data);
	EndIf;
	
	Return Data;
	
EndFunction

// Calculates the checksum for arbitrary data using the specified algorithm.
//
// Parameters:
//  Data - Arbitrary - the data to serialize.
//  Algorithm - HashFunction - an algorithm to calculate the checksum. The default algorithm is MD5.
// 
// Returns:
//  String - the checksum. 32 bytes, no whitespaces.
//
Function CheckSumString(Val Data, Val Algorithm = Undefined) Export
	
	If Algorithm = Undefined Then
		Algorithm = HashFunction.MD5;
	EndIf;
	
	DataHashing = New DataHashing(Algorithm);
	If TypeOf(Data) <> Type("String") AND TypeOf(Data) <> Type("BinaryData") Then
		Data = ValueToXMLString(Data);
	EndIf;
	DataHashing.Append(Data);
	
	If TypeOf(DataHashing.HashSum) = Type("BinaryData") Then 
		Result = StrReplace(DataHashing.HashSum, " ", "");
	ElsIf TypeOf(DataHashing.HashSum) = Type("Number") Then
		Result = Format(DataHashing.HashSum, "NG=");
	EndIf;
	
	Return Result;
	
EndFunction

// Trims a string to the specified length. The trimmed part is hashed to ensure the result string is 
// unique. Checks an input string and, unless it fits the limit, converts its end into a unique 32 
// symbol string using MD5 algorithm.
// 
//
// Parameters:
//  String - String - the input string of arbitrary length.
//  MaxLength - Number - the maximum valid string length. The minimum value is 32.
//                               
// 
// Returns:
//   String - a string within the maximum length limit.
//
Function TrimStringUsingChecksum(String, MaxLength) Export
	CommonClientServer.Validate(MaxLength >= 32, NStr("ru = 'Параметр МаксимальнаяДлина не может быть меньше 32'; en = 'The MaxLength parameter cannot be less than 32.'; pl = 'Parametr MaxLength nie może być mniejszy niż 32';de = 'Der Parameter MaxLength darf nicht kleiner als 32 sein';ro = 'Parametrul MaxLength nu poate fi mai mic decât 32';tr = 'MaxLength parametresi 32''den az olamaz'; es_ES = 'El parámetro MaxLength no puede ser menor que 32.'"),
		"Common.TrimStringUsingChecksum");
	
	Result = String;
	If StrLen(String) > MaxLength Then
		Result = Left(String, MaxLength - 32);
		DataHashing = New DataHashing(HashFunction.MD5);
		DataHashing.Append(Mid(String, MaxLength - 32 + 1));
		Result = Result + StrReplace(DataHashing.HashSum, " ", "");
	EndIf;
	Return Result;
EndFunction

// Creates a complete recursive copy of a structure, map, array, list, or value table consistent 
// with the child item type. For object-type values (for example, CatalogObject or DocumentObject), 
// the procedure returns references to the source objects instead of copying the content.
//
// Parameters:
//  Source - Structure, FixedStructure,
//             Map, FixedMap,
//             Array, FixedArray,
//             ValueList - an object that needs to be copied.
//  FixData - Boolean, Undefined - if it is True, then fix, if it is False, remove the fixing, if it 
//                          is Undefined, do not change.
//
// Returns:
//  Structure, FixedStructure,
//  Map, FixedMap,
//  Array, FixedArray,
//  ValueList - a copy of the object passed in the Source parameter.
//
Function CopyRecursive(Source, FixData = Undefined) Export
	
	Var Target;
	
	SourceType = TypeOf(Source);
	
	If SourceType = Type("ValueTable") Then
		Return Source.Copy();
	EndIf;
	
	If SourceType = Type("Structure")
		Or SourceType = Type("FixedStructure") Then
		Target = CopyStructure(Source, FixData);
	ElsIf SourceType = Type("Map")
		Or SourceType = Type("FixedMap") Then
		Target = CopyMap(Source, FixData);
	ElsIf SourceType = Type("Array")
		Or SourceType = Type("FixedArray") Then
		Target = CopyArray(Source, FixData);
	ElsIf SourceType = Type("ValueList") Then
		Target = CopyValueList(Source, FixData);
	Else
		Target = Source;
	EndIf;
	
	Return Target;
	
EndFunction

// Returns subject details in the string format.
// 
// Parameters:
//  ReferenceToSubject - AnyRef - a reference object.
//
// Returns:
//   String - the subject presentation.
// 
Function SubjectString(ReferenceToSubject) Export
	
	Result = "";
	
	If ReferenceToSubject = Undefined Or ReferenceToSubject.IsEmpty() Then
		Result = NStr("ru = 'не задан'; en = 'not specified'; pl = 'nieokreślony';de = 'keine angabe';ro = 'nespecificat';tr = 'belirtilmemiş'; es_ES = 'no especificado'");
	ElsIf Metadata.Documents.Contains(ReferenceToSubject.Metadata()) Or Metadata.Enums.Contains(ReferenceToSubject.Metadata()) Then
		Result = String(ReferenceToSubject);
	Else	
		ObjectPresentation = ReferenceToSubject.Metadata().ObjectPresentation;
		If IsBlankString(ObjectPresentation) Then
			ObjectPresentation = ReferenceToSubject.Metadata().Presentation();
		EndIf;
		Result = StringFunctionsClientServer.SubstituteParametersToString("%1 (%2)", String(ReferenceToSubject), ObjectPresentation);
	EndIf;
	
	Return Result;
	
EndFunction

#EndRegion

#Region DynamicList

// Creates a dynamic list property structure to call SetDynamicListProperties().
//
// Returns:
//  Structure - any field can be Undefined if it is not set:
//     * QueryText - String - the new query text.
//     * MainTable - String - the name of the main table.
//     * DynamicDataRead - Boolean - a flag indicating whether dynamic reading is used.
//
Function DynamicListPropertiesStructure() Export
	
	Return New Structure("QueryText, MainTable, DynamicDataRead");
	
EndFunction

// Sets the query text, primary table, or dynamic reading from a dynamic list.
// To avoid low performance, set these properties within the same call of this procedure.
//
// Parameters:
//  List - FormTable - a form item of the dynamic list whose properties are to be set.
//  ParametersStructure - Structure - see DynamicListPropertiesStructure(). 
//
Procedure SetDynamicListProperties(List, ParametersStructure) Export
	
	Form = List.Parent;
	ManagedFormType = Type("ManagedForm");
	
	While TypeOf(Form) <> ManagedFormType Do
		Form = Form.Parent;
	EndDo;
	
	DynamicList = Form[List.DataPath];
	QueryText = ParametersStructure.QueryText;
	
	If Not IsBlankString(QueryText) Then
		DynamicList.QueryText = QueryText;
	EndIf;
	
	MainTable = ParametersStructure.MainTable;
	
	If Not IsBlankString(MainTable) Then
		DynamicList.MainTable = MainTable;
	EndIf;
	
	DynamicDataRead = ParametersStructure.DynamicDataRead;
	
	If TypeOf(DynamicDataRead) = Type("Boolean") Then
		DynamicList.DynamicDataRead = DynamicDataRead;
	EndIf;
	
EndProcedure

#EndRegion

#Region ExternalConnection

////////////////////////////////////////////////////////////////////////////////
// Procedures and functions for managing external connections.

// Returns the CLSID of the COM class for working with 1C:Enterprise 8 through a COM connection.
//
// Parameters:
//  COMConnectorName - String - the name of the COM class for working with 1C:Enterprise 8 through a COM connection.
//
// Returns:
//  String - the CLSID string presentation.
//
Function COMConnectorID(Val COMConnectorName) Export
	
	If COMConnectorName = "v83.COMConnector" Then
		Return "181E893D-73A4-4722-B61D-D604B3D67D47";
	EndIf;
	
	ExceptionText = StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = 'На задан CLSID для класса %1'; en = 'The CLSID for class %1 is not specified.'; pl = 'Nie jest określony CLSID dla klasy %1';de = 'CLSID ist nicht für Klasse %1 angegeben';ro = 'CLSID nu este specificat pentru clasa %1';tr = 'CLSID %1 sınıf için belirtilmemiş'; es_ES = 'CLSID no está especificado para la clase %1'"), COMConnectorName);
	Raise ExceptionText;
	
EndFunction

// Establishes an external infobase connection with the passed parameters and returns a pointer to 
// the connection.
// 
// Parameters:
//  Parameters - Structure - see CommonClientServer.ParametersStructureForExternalConnection 
// 
// Returns:
//  Structure - connection details:
//    * Connection - COMObject, Undefined - if the connection is established, returns a COM object reference. Otherwise, returns Undefined.
//    * BriefErrorDescription - String - a brief error description;
//    * DetailedErrorDescription - String - a detailed error details;
//    * ErrorAttachingAddIn - Boolean - a COM connection error flag.
//
Function EstablishExternalConnectionWithInfobase(Parameters) Export
	
	ConnectionUnavailable = IsLinuxServer();
	BriefErrorDescription = NStr("ru = 'Прямое подключение к информационной базе недоступно на сервере под управлением ОС Linux.'; en = 'Servers on Linux do not support direct infobase connections.'; pl = 'Bezpośrednie połączenie z bazą informacyjną na serwerze pod OS Linux nie jest dostępne.';de = 'Direkte Verbindung zur Infobase auf einem Server unter Betriebssystem Linux ist nicht verfügbar.';ro = 'Conectarea directă la baza de date pe serverul gestionat de SO Linux nu este disponibilă.';tr = 'Linux OS kapsamında bir sunucudaki veritabanına doğrudan bağlantı mevcut değildir.'; es_ES = 'Conexión directa a la infobase en un servidor bajo OS Linux no está disponible.'");
	
	Return CommonInternalClientServer.EstablishExternalConnectionWithInfobase(Parameters, ConnectionUnavailable, BriefErrorDescription);
	
EndFunction

#EndRegion

#Region Metadata

////////////////////////////////////////////////////////////////////////////////
// Metadata object type definition functions.

// Reference data types.

// Checks whether the metadata object belongs to the Document common  type.
//
// Parameters:
//  MetadataObject - MetadataObject - object to compare against Document type.
// 
// Returns:
//   Boolean - True if the object is a document.
//
Function IsDocument(MetadataObject) Export
	
	Return Metadata.Documents.Contains(MetadataObject);
	
EndFunction

// Checks whether the metadata object belongs to the Catalog common type.
//
// Parameters:
//  MetadataObject - MetadataObject - object to compare against the specified type.
// 
// Returns:
//   Boolean - True if the object is a catalog.
//
Function IsCatalog(MetadataObject) Export
	
	Return Metadata.Catalogs.Contains(MetadataObject);
	
EndFunction

// Checks whether the metadata object belongs to the Enumeration common  type.
//
// Parameters:
//  MetadataObject - MetadataObject - object to compare against the specified type.
// 
// Returns:
//   Boolean - True if the object is an enumeration.
//
Function IsEnum(MetadataObject) Export
	
	Return Metadata.Enums.Contains(MetadataObject);
	
EndFunction

// Checks whether the metadata object belongs to the Exchange Plan common type.
//
// Parameters:
//  MetadataObject - MetadataObject - object to compare against the specified type.
// 
// Returns:
//   Boolean - True if the object is an exchange plan.
//
Function IsExchangePlan(MetadataObject) Export
	
	Return Metadata.ExchangePlans.Contains(MetadataObject);
	
EndFunction

// Checks whether the metadata object belongs to the Chart of Characteristic Types common type.
//
// Parameters:
//  MetadataObject - MetadataObject - object to compare against the specified type.
// 
// Returns:
//   Boolean - True if the object is a chart of characteristic types.
//
Function IsChartOfCharacteristicTypes(MetadataObject) Export
	
	Return Metadata.ChartsOfCharacteristicTypes.Contains(MetadataObject);
	
EndFunction

// Checks whether the metadata object belongs to the Business Process common type.
//
// Parameters:
//  MetadataObject - MetadataObject - object to compare against the specified type.
// 
// Returns:
//   Boolean - True if the object is a business process.
//
Function IsBusinessProcess(MetadataObject) Export
	
	Return Metadata.BusinessProcesses.Contains(MetadataObject);
	
EndFunction

// Checks whether the metadata object belongs to the Task common type.
//
// Parameters:
//  MetadataObject - MetadataObject - object to compare against the specified type.
// 
// Returns:
//   Boolean - True if the object is a task.
//
Function IsTask(MetadataObject) Export
	
	Return Metadata.Tasks.Contains(MetadataObject);
	
EndFunction

// Checks whether the metadata object belongs to the Chart of Accounts common type.
//
// Parameters:
//  MetadataObject - MetadataObject - object to compare against the specified type.
// 
// Returns:
//   Boolean - True if the object is a chart of accounts.
//
Function IsChartOfAccounts(MetadataObject) Export
	
	Return Metadata.ChartsOfAccounts.Contains(MetadataObject);
	
EndFunction

// Checks whether the metadata object belongs to the Chart of Calculation Types common type.
//
// Parameters:
//  MetadataObject - MetadataObject - object to compare against the specified type.
// 
// Returns:
//   Boolean - True if the object is a chart of calculation types.
//
Function IsChartOfCalculationTypes(MetadataObject) Export
	
	Return Metadata.ChartsOfCalculationTypes.Contains(MetadataObject);
	
EndFunction

// Registers

// Checks whether the metadata object belongs to the Information Register common type.
//
// Parameters:
//  MetadataObject - MetadataObject - object to compare against the specified type.
// 
// Returns:
//   Boolean - True if the object is an information register.
//
Function IsInformationRegister(MetadataObject) Export
	
	Return Metadata.InformationRegisters.Contains(MetadataObject);
	
EndFunction

// Checks whether the metadata object belongs to the Accumulation Register common type.
//
// Parameters:
//  MetadataObject - MetadataObject - object to compare against the specified type.
// 
// Returns:
//   Boolean - True if the object is an accumulation register.
//
Function IsAccumulationRegister(MetadataObject) Export
	
	Return Metadata.AccumulationRegisters.Contains(MetadataObject);
	
EndFunction

// Checks whether the metadata object belongs to the Accounting Register common type.
//
// Parameters:
//  MetadataObject - MetadataObject - object to compare against the specified type.
// 
// Returns:
//   Boolean - True if the object is an accounting register.
//
Function IsAccountingRegister(MetadataObject) Export
	
	Return Metadata.AccountingRegisters.Contains(MetadataObject);
	
EndFunction

// Checks whether the metadata object belongs to the Calculation Register common type.
//
// Parameters:
//  MetadataObject - MetadataObject - object to compare against the specified type.
// 
// Returns:
//   Boolean - True if the object is a calculation register.
//
Function IsCalculationRegister(MetadataObject) Export
	
	Return Metadata.CalculationRegisters.Contains(MetadataObject);
	
EndFunction

// Constants

// Checks whether the metadata object belongs to the Constant common type.
//
// Parameters:
//  MetadataObject - MetadataObject - object to compare against the specified type.
// 
// Returns:
//   Boolean - True if the object is a constant.
//
Function IsConstant(MetadataObject) Export
	
	Return Metadata.Constants.Contains(MetadataObject);
	
EndFunction

// Document journals

// Checks whether the metadata object belongs to the Document Journal common type.
//
// Parameters:
//  MetadataObject - MetadataObject - object to compare against the specified type.
// 
// Returns:
//   Boolean - True if the object is a document journal.
//
Function IsDocumentJournal(MetadataObject) Export
	
	Return Metadata.DocumentJournals.Contains(MetadataObject);
	
EndFunction

// Sequences

// Checks whether the metadata object belongs to the Sequences common type.
//
// Parameters:
//  MetadataObject - MetadataObject - object to compare against the specified type.
// 
// Returns:
//   Boolean - True if the object is a sequence.
//
Function IsSequence(MetadataObject) Export
	
	Return Metadata.Sequences.Contains(MetadataObject);
	
EndFunction

// ScheduledJobs

// Checks whether the metadata object belongs to the Scheduled Jobs common type.
//
// Parameters:
//  MetadataObject - MetadataObject - object to compare against the specified type.
// 
// Returns:
//   Boolean - True if the object is a scheduled job.
//
Function IsScheduledJob(MetadataObject) Export
	
	Return Metadata.ScheduledJobs.Contains(MetadataObject);
	
EndFunction

// Common

// Checks whether the metadata object belongs to the register type.
//
// Parameters:
//  MetadataObject - MetadataObject - object to compare against the specified type.
// 
// Returns:
//    Boolean - True if the object is a register.
//
Function IsRegister(MetadataObject) Export
	
	Return Metadata.AccountingRegisters.Contains(MetadataObject)
		Or Metadata.AccumulationRegisters.Contains(MetadataObject)
		Or Metadata.CalculationRegisters.Contains(MetadataObject)
		Or Metadata.InformationRegisters.Contains(MetadataObject);
		
EndFunction

// Checks whether the metadata object belongs to the reference type.
//
// Parameters:
//  MetadataObject - MetadataObject - object to compare against the specified type.
// 
// Returns:
//   Boolean - True if the object is a reference type object.
//
Function IsRefTypeObject(MetadataObject) Export
	
	MetadataObjectName = MetadataObject.FullName();
	Position = StrFind(MetadataObjectName, ".");
	If Position > 0 Then 
		BaseTypeName = Left(MetadataObjectName, Position - 1);
		Return BaseTypeName = "Catalog"
			Or BaseTypeName = "Document"
			Or BaseTypeName = "BusinessProcess"
			Or BaseTypeName = "Task"
			Or BaseTypeName = "ChartOfAccounts"
			Or BaseTypeName = "ExchangePlan"
			Or BaseTypeName = "ChartOfCharacteristicTypes"
			Or BaseTypeName = "ChartOfCalculationTypes";
	Else
		Return False;
	EndIf;
	
EndFunction

////////////////////////////////////////////////////////////////////////////////
// Procedures and functions for operations with types, metadata objects, and their string presentations.

// Returns names of attributes for an object of the specified type.
//
// Parameters:
//  Ref - AnyRef - a reference to a database item to use with the function.
//  Type - Type - attribute value type.
// 
// Returns:
//  String - a comma-separated string of configuration metadata object attributes.
//
// Example:
//  CompanyAttributes = Common.AttributeNamesByType (Document.Ref, Type("CatalogRef.Companies"));
//
Function AttributeNamesByType(Ref, Type) Export
	
	Result = "";
	ObjectMetadata = Ref.Metadata();
	
	For Each Attribute In ObjectMetadata.Attributes Do
		If Attribute.Type.ContainsType(Type) Then
			Result = Result + ?(IsBlankString(Result), "", ", ") + Attribute.Name;
		EndIf;
	EndDo;
	
	Return Result;
EndFunction

// Returns a base type name by the passed metadata object value.
//
// Parameters:
//  MetadataObject - MetadataObject - a metadata object whose base type is to be determined.
// 
// Returns:
//  String - name of the base type for the passed metadata object value.
//
// Example:
//  BaseTypeName = Common.BaseTypeNameByMetadataObject(Metadata.Catalogs.Products); = "Catalogs".
//
Function BaseTypeNameByMetadataObject(MetadataObject) Export
	
	If Metadata.Documents.Contains(MetadataObject) Then
		Return "Documents";
		
	ElsIf Metadata.Catalogs.Contains(MetadataObject) Then
		Return "Catalogs";
		
	ElsIf Metadata.Enums.Contains(MetadataObject) Then
		Return "Enums";
		
	ElsIf Metadata.InformationRegisters.Contains(MetadataObject) Then
		Return "InformationRegisters";
		
	ElsIf Metadata.AccumulationRegisters.Contains(MetadataObject) Then
		Return "AccumulationRegisters";
		
	ElsIf Metadata.AccountingRegisters.Contains(MetadataObject) Then
		Return "AccountingRegisters";
		
	ElsIf Metadata.CalculationRegisters.Contains(MetadataObject) Then
		Return "CalculationRegisters";
		
	ElsIf Metadata.ExchangePlans.Contains(MetadataObject) Then
		Return "ExchangePlans";
		
	ElsIf Metadata.ChartsOfCharacteristicTypes.Contains(MetadataObject) Then
		Return "ChartsOfCharacteristicTypes";
		
	ElsIf Metadata.BusinessProcesses.Contains(MetadataObject) Then
		Return "BusinessProcesses";
		
	ElsIf Metadata.Tasks.Contains(MetadataObject) Then
		Return "Tasks";
		
	ElsIf Metadata.ChartsOfAccounts.Contains(MetadataObject) Then
		Return "ChartsOfAccounts";
		
	ElsIf Metadata.ChartsOfCalculationTypes.Contains(MetadataObject) Then
		Return "ChartsOfCalculationTypes";
		
	ElsIf Metadata.Constants.Contains(MetadataObject) Then
		Return "Constants";
		
	ElsIf Metadata.DocumentJournals.Contains(MetadataObject) Then
		Return "DocumentJournals";
		
	// rarus fm begin
	ElsIf Metadata.Reports.Contains(MetadataObject) Then
		Return "Reports";
	// rarus fm end
		
	ElsIf Metadata.Sequences.Contains(MetadataObject) Then
		Return "Sequences";
		
	ElsIf Metadata.ScheduledJobs.Contains(MetadataObject) Then
		Return "ScheduledJobs";
		
	ElsIf Metadata.CalculationRegisters.Contains(MetadataObject.Parent())
		AND MetadataObject.Parent().Recalculations.Find(MetadataObject.Name) = MetadataObject Then
		Return "Recalculations";
		
	Else
		
		Return "";
		
	EndIf;
	
EndFunction

// Returns an object manager by the passed full name of a metadata object.
// Restriction: does not process business process route points.
//
// Parameters:
//  FullName - String - full name of a metadata object. Example: "Catalog.Company".
//
// Returns:
//  CatalogManager, DocumentManager, DataProcessorManager, InformationRegisterManager - an object manager.
// 
// Example:
//  CatalogManager= Common.ObjectManagerByFullName("Catalog.Companies");
//  EmptyRef = CatalogManager.EmptyRef();
//
Function ObjectManagerByFullName(FullName) Export
	Var MOClass, MetadataObjectName, Manager;
	
	NameParts = StrSplit(FullName, ".");
	
	If NameParts.Count() >= 2 Then
		MOClass = NameParts[0];
		MetadataObjectName  = NameParts[1];
	EndIf;
	
	If      Upper(MOClass) = "EXCHANGEPLAN" Then
		Manager = ExchangePlans;
		
	ElsIf Upper(MOClass) = "CATALOG" Then
		Manager = Catalogs;
		
	ElsIf Upper(MOClass) = "DOCUMENT" Then
		Manager = Documents;
		
	ElsIf Upper(MOClass) = "DOCUMENTJOURNAL" Then
		Manager = DocumentJournals;
		
	ElsIf Upper(MOClass) = "ENUM" Then
		Manager = Enums;
		
	ElsIf Upper(MOClass) = "REPORT" Then
		Manager = Reports;
		
	ElsIf Upper(MOClass) = "DATAPROCESSOR" Then
		Manager = DataProcessors;
		
	ElsIf Upper(MOClass) = "CHARTOFCHARACTERISTICTYPES" Then
		Manager = ChartsOfCharacteristicTypes;
		
	ElsIf Upper(MOClass) = "CHARTOFACCOUNTS" Then
		Manager = ChartsOfAccounts;
		
	ElsIf Upper(MOClass) = "CHARTOFCALCULATIONTYPES" Then
		Manager = ChartsOfCalculationTypes;
		
	ElsIf Upper(MOClass) = "INFORMATIONREGISTER" Then
		Manager = InformationRegisters;
		
	ElsIf Upper(MOClass) = "ACCUMULATIONREGISTER" Then
		Manager = AccumulationRegisters;
		
	ElsIf Upper(MOClass) = "ACCOUNTINGREGISTER" Then
		Manager = AccountingRegisters;
		
	ElsIf Upper(MOClass) = "CALCULATIONREGISTER" Then
		If NameParts.Count() = 2 Then
			// Calculation register
			Manager = CalculationRegisters;
		Else
			SubordinateMOClass = NameParts[2];
			SubordinateMOName = NameParts[3];
			If Upper(SubordinateMOClass) = "RECALCULATION" Then
				// Recalculation
				Try
					Manager = CalculationRegisters[MetadataObjectName].Recalculations;
					MetadataObjectName = SubordinateMOName;
				Except
					Manager = Undefined;
				EndTry;
			EndIf;
		EndIf;
		
	ElsIf Upper(MOClass) = "BUSINESSPROCESS" Then
		Manager = BusinessProcesses;
		
	ElsIf Upper(MOClass) = "TASK" Then
		Manager = Tasks;
		
	ElsIf Upper(MOClass) = "CONSTANT" Then
		Manager = Constants;
		
	ElsIf Upper(MOClass) = "SEQUENCE" Then
		Manager = Sequences;
	EndIf;
	
	If Manager <> Undefined Then
		Try
			Return Manager[MetadataObjectName];
		Except
			Manager = Undefined;
		EndTry;
	EndIf;
	
	Raise StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = 'Неизвестный тип объекта метаданных ""%1""'; en = 'Invalid metadata object type: %1.'; pl = 'Nieznany typ obiektu metadanych %1';de = 'Unbekannter Metadaten-Objekttyp ""%1""';ro = 'Tip necunoscut al obiectului de metadate ""%1""';tr = 'Bilinmeyen meta veri nesne türü ""%1""'; es_ES = 'Tipo del objeto de metadatos desconocido ""%1""'"), FullName);
	
EndFunction

// Returns an object manager by the passed object reference.
// Restriction: does not process business process route points.
// See also: Common.ObjectManagerByFullName.
//
// Parameters:
//  Ref - AnyRef - an object whose manager is sought.
//
// Returns:
//  CatalogManager, DocumentManager, DataProcessorManager, InformationRegisterManager - an object manager.
//
// Example:
//  CatalogManager = Common.ObjectManagerByRef(RefToCompany);
//  EmptyRef = CatalogManager.EmptyRef();
//
Function ObjectManagerByRef(Ref) Export
	
	ObjectName = Ref.Metadata().Name;
	RefType = TypeOf(Ref);
	
	If Catalogs.AllRefsType().ContainsType(RefType) Then
		Return Catalogs[ObjectName];
		
	ElsIf Documents.AllRefsType().ContainsType(RefType) Then
		Return Documents[ObjectName];
		
	ElsIf BusinessProcesses.AllRefsType().ContainsType(RefType) Then
		Return BusinessProcesses[ObjectName];
		
	ElsIf ChartsOfCharacteristicTypes.AllRefsType().ContainsType(RefType) Then
		Return ChartsOfCharacteristicTypes[ObjectName];
		
	ElsIf ChartsOfAccounts.AllRefsType().ContainsType(RefType) Then
		Return ChartsOfAccounts[ObjectName];
		
	ElsIf ChartsOfCalculationTypes.AllRefsType().ContainsType(RefType) Then
		Return ChartsOfCalculationTypes[ObjectName];
		
	ElsIf Tasks.AllRefsType().ContainsType(RefType) Then
		Return Tasks[ObjectName];
		
	ElsIf ExchangePlans.AllRefsType().ContainsType(RefType) Then
		Return ExchangePlans[ObjectName];
		
	ElsIf Enums.AllRefsType().ContainsType(RefType) Then
		Return Enums[ObjectName];
	Else
		Return Undefined;
	EndIf;
	
EndFunction

// Checking whether the passed type is a reference data type.
// Returns False for Undefined type.
//
// Parameters:
//  TypeToCheck - Type - a reference type to check.
//
// Returns:
//  Boolean - True if the type is a reference type.
//
Function IsReference(TypeToCheck) Export
	
	Return TypeToCheck <> Type("Undefined") AND AllRefsTypeDetails().ContainsType(TypeToCheck);
	
EndFunction

// Checks whether the infobase record exists by its reference.
//
// Parameters:
//  RefToCheck - AnyRef - a value of an infobase reference.
// 
// Returns:
//  Boolean - True if exists.
//
Function RefExists(RefToCheck) Export
	
	QueryText = "
	|SELECT TOP 1
	|	1
	|FROM
	|	[TableName]
	|WHERE
	|	Ref = &Ref
	|";
	
	QueryText = StrReplace(QueryText, "[TableName]", TableNameByRef(RefToCheck));
	
	Query = New Query;
	Query.Text = QueryText;
	Query.SetParameter("Ref", RefToCheck);
	
	SetPrivilegedMode(True);
	
	Return NOT Query.Execute().IsEmpty();
	
EndFunction

// Returns a metadata object kind name by the passed object reference.
// Restriction: does not process business process route points.
// See also: ObjectKindByType.
//
// Parameters:
//  Ref - AnyRef - an object of the kind to search for.
//
// Returns:
//  String - a metadata object kind name. For example: "Catalog", "Document".
// 
Function ObjectKindByRef(Ref) Export
	
	Return ObjectKindByType(TypeOf(Ref));
	
EndFunction 

// Returns a metadata object kind name by the passed object type.
// Restriction: does not process business process route points.
// See also: ObjectKindByRef.
//
// Parameters:
//  ObjectType - Type - an applied object type defined in the configuration.
//
// Returns:
//  String - a metadata object kind name. For example: "Catalog", "Document".
// 
Function ObjectKindByType(ObjectType) Export
	
	If Catalogs.AllRefsType().ContainsType(ObjectType) Then
		Return "Catalog";
	
	ElsIf Documents.AllRefsType().ContainsType(ObjectType) Then
		Return "Document";
	
	ElsIf BusinessProcesses.AllRefsType().ContainsType(ObjectType) Then
		Return "BusinessProcess";
	
	ElsIf ChartsOfCharacteristicTypes.AllRefsType().ContainsType(ObjectType) Then
		Return "ChartOfCharacteristicTypes";
	
	ElsIf ChartsOfAccounts.AllRefsType().ContainsType(ObjectType) Then
		Return "ChartOfAccounts";
	
	ElsIf ChartsOfCalculationTypes.AllRefsType().ContainsType(ObjectType) Then
		Return "ChartOfCalculationTypes";
	
	ElsIf Tasks.AllRefsType().ContainsType(ObjectType) Then
		Return "Task";
	
	ElsIf ExchangePlans.AllRefsType().ContainsType(ObjectType) Then
		Return "ExchangePlan";
	
	ElsIf Enums.AllRefsType().ContainsType(ObjectType) Then
		Return "Enum";
	
	Else
		Raise StringFunctionsClientServer.SubstituteParametersToString(NStr("ru='Неверный тип значения параметра (%1)'; en = 'Invalid parameter value type: %1.'; pl = 'Nieprawidłowy typ wartości parametru (%1)';de = 'Falscher Typ des Parameterwerts (%1)';ro = 'Tip incorect al valorii parametrului (%1)';tr = 'Parametre değeri tipi yanlış (%1)'; es_ES = 'Tipo incorrecto del valor del parámetro (%1)'"), String(ObjectType));
	
	EndIf;
	
EndFunction

// Returns full metadata object name by the passed reference value.
//
// Parameters:
//  Ref - AnyRef - an object whose infobase table name is sought.
// 
// Returns:
//  String - the full name of the metadata object for the specified object. For example, "Catalog.Products".
//
Function TableNameByRef(Ref) Export
	
	Return Ref.Metadata().FullName();
	
EndFunction

// Checks whether the value is a reference type value.
//
// Parameters:
//  Value - Arbitrary - a value to check.
//
// Returns:
//  Boolean - True if the value is a reference type value.
//
Function RefTypeValue(Value) Export
	
	Return IsReference(TypeOf(Value));
	
EndFunction

// Checks whether the object is an item group.
//
// Parameters:
//  Object - AnyRef, Object - an object to check.
//
// Returns:
//  Boolean - True if the object is an item group.
//
Function ObjectIsFolder(Object) Export
	
	If RefTypeValue(Object) Then
		Ref = Object;
	Else
		Ref = Object.Ref;
	EndIf;
	
	ObjectMetadata = Ref.Metadata();
	
	If IsCatalog(ObjectMetadata) Then
		
		If NOT ObjectMetadata.Hierarchical
		 OR ObjectMetadata.HierarchyType
		     <> Metadata.ObjectProperties.HierarchyType.HierarchyFoldersAndItems Then
			
			Return False;
		EndIf;
		
	ElsIf NOT IsChartOfCharacteristicTypes(ObjectMetadata) Then
		Return False;
		
	ElsIf NOT ObjectMetadata.Hierarchical Then
		Return False;
	EndIf;
	
	If Ref <> Object Then
		Return Object.IsFolder;
	EndIf;
	
	Return ObjectAttributeValue(Ref, "IsFolder") = True;
	
EndFunction

// Returns a reference corresponding to the metadata object to be used in the database.
// See also: Common.MetadataObjectIDs.
//
//  The following metadata objects are supported:
// - Subsystems (you must program the renaming rule).
// - Roles (you must program the renaming rule).
// - ExchangePlans
// - Constants
// - Catalogs
// - Documents
// - DocumentJournals
// - Reports
// - DataProcessors
// - ChartsOfCharacteristicTypes
// - ChartsOfAccounts
// - ChartsOfCalculationTypes
// - InformationRegisters
// - AccumulationRegisters
// - AccountingRegisters
// - CalculationRegisters
// - BusinessProcesses
// - Tasks
// 
// Parameters:
//  MetadataObjectDetails - MetadataObject - a configuration metadata object.
//                            - Type - a valid type for Metadata.FindByType();
//                            - String - the valid full name of a metadata object to use in the 
//                              Metadata.FindByFullName() function.
// Returns:
//  CatalogRef.MetadataObjectIDs, CatalogRef.ExtensionObjectIDs - a reference.
//  
// Example:
//  ID = Common.MetadataObjectID(TypeOf(Ref));
//  ID = Common.MetadataObjectID(MetadataObject);
//  ID = Common.MetadataObjectID("Catalog.Companies");
//
Function MetadataObjectID(MetadataObjectDetails) Export
	
	Return Catalogs.MetadataObjectIDs.MetadataObjectID(MetadataObjectDetails);
	
EndFunction

// Returns references corresponding to the metadata objects to be used in the database.
// See also: Common.MetadataObjectID.
//
//  The following metadata objects are supported:
// - Subsystems (you must program the renaming rule).
// - Roles (you must program the renaming rule).
// - ExchangePlans
// - Constants
// - Catalogs
// - Documents
// - DocumentJournals
// - Reports
// - DataProcessors
// - ChartsOfCharacteristicTypes
// - ChartsOfAccounts
// - ChartsOfCalculationTypes
// - InformationRegisters
// - AccumulationRegisters
// - AccountingRegisters
// - CalculationRegisters
// - BusinessProcesses
// - Tasks
// 
// Parameters:
//  MetadataObjectsDetails - Array - an array with the values like:
//    * MetadataObject - a configuration metadata object.
//    * String - the valid full name of a metadata object to use in the Metadata.FindByFullName() 
//               function.
//    * Type - a type that can be used in Metadata.FindByType().
//
// Returns:
//  Map with the following properties:
//    * Key - String - a full name of the metadata object.
//    * Value - CatalogRef.MetadataObjectIDs,
//                 CatalogRef.ExtensionObjectIDs - the found ID.
// Example:
//  FullNames = New Array;
//  FullNames.Add(Metadata.Catalogs.Currencies.FullName());
//  FullNames.Add(Metadata.InformationRegisters.CurrencyRates.FullName());
//  IDs = Common.MetadataObjectIDs(FullNames);
//
Function MetadataObjectIDs(MetadataObjectsDetails) Export
	
	Return Catalogs.MetadataObjectIDs.MetadataObjectIDs(MetadataObjectsDetails);
	
EndFunction

// Returns a metadata object by ID.
//
// Parameters:
//  ID - CatalogRef.MetadataObjectIDs,
//                  CatalogRef.ExtensionObjectIDs - the IDs of metadata objects in an application or 
//                    an extension.
//
//  RaiseException - Boolean - if True, when metadata object does not exist or it is unavailable, it 
//                    returns
//                    Null or Undefined instead of raising an exception.
//
// Returns:
//  MetadataObject - the metadata object with the specified ID.
//
//  Null is returned when RaiseException = False. Null means there is no metadata object with this 
//    ID (the ID is invalid).
//
//  Undefined is returned when RaiseException = False. Undefined means the ID is valid, but the 
//    session fails to get the MetadataObject.
//    For configuration extensions, that means the extension had been installed, but was not 
//    attached, or the configuration was not restarted, or attaching the extension failed.
//    For the configuration, that means the new session contains the object and the current session 
//    does not contain it.
//
Function MetadataObjectByID(ID, RaiseException = True) Export
	
	Return Catalogs.MetadataObjectIDs.MetadataObjectByID(ID,
		RaiseException);
	
EndFunction

// Returns metadata objects with the specified IDs.
//
// Parameters:
//  IDs - Array - of the following values:
//                     * Value - CatalogRef.MetadataObjectIDs,
//                                  CatalogRef.ExtensionObjectIDs - the IDs of metadata objects in 
//                                    an application or an extension.
//
//  RaiseException - Boolean - if True, when metadata object does not exist or it is unavailable, it 
//                    returns
//                    Null or Undefined instead of raising an exception.
//
// Returns:
//  Map with the following properties:
//   * Key     - CatalogRef.MetadataObjectsIDs,
//                CatalogRef.ExtensionObjectsIDs - the passed ID.
//   * Value - MetadataObject - the metadata object with this ID.
//              - Null is returned when RaiseException = False. Null means there is no metadata 
//                  object with this ID (the ID is invalid).
//              - Undefined is returned when RaiseException = False. Undefined means the ID is valid, 
//                  but the session fails to get the MetadataObject.
//                  For configuration extensions, that means the extension had been installed, but 
//                  was not attached, or the configuration was not restarted, or attaching the extension failed.
//                  For the configuration, that means the new session contains the object and the 
//                  current session does not contain it.
//
Function MetadataObjectsByIDs(IDs, RaiseException = True) Export
	
	Return Catalogs.MetadataObjectIDs.MetadataObjectsByIDs(IDs,
		RaiseException);
	
EndFunction

// Determines whether the metadata object is available by functional options.
//
// Parameters:
//   MetadataObject - MetadataObject, String - metadata object to check.
//
// Returns:
//   Boolean - True if the object is available.
//
Function MetadataObjectAvailableByFunctionalOptions(Val MetadataObject) Export
	If MetadataObject = Undefined Then
		Return False;
	EndIf;
	If TypeOf(MetadataObject) <> Type("String") Then
		FullName = MetadataObject.FullName();
	Else
		FullName = MetadataObject;
	EndIf;
	Return StandardSubsystemsCached.ObjectsEnabledByOption().Get(FullName) <> False;
EndFunction

// During migration to the specified configuration version, stores the metadata object renaming details
// to the Totals structure, which is passed to the CommonOverridable.OnAddMetadataObjectsRenaming 
// procedure.
// 
// Parameters:
//   Total - Structure - see CommonOverridable.OnAddMetadataObjectsRenaming. 
//   IBVersion                - String    - the destination configuration version. For example, "2.1.
//                                         2.14".
//   PreviousFullName         - String - the source full name of the metadata object to rename. For 
//                                         example, "Subsystem._DemoSubsystems".
//   NewFullName          - String    - the new metadata object name. For example, "Subsystem.
//                                         _DemoServiceSubsystems".
//   LibraryID - String - an internal ID of the library that contains IBVersion.
//                                         Not required for the base configuration.
//                                         For example, "StandardSubsystems", as specified in 
//                                         InfobaseUpdateSSL.OnAddSubsystem.
// Example:
//	Common.AddRenaming(Total, "2.1.2.14",
//		"Subsystem._DemoSubsystems",
//		"Subsystem.DemoServiceSubsystems");
//
Procedure AddRenaming(Total, IBVersion, PreviousFullName, NewFullName, LibraryID = "") Export
	
	Catalogs.MetadataObjectIDs.AddRenaming(Total,
		IBVersion, PreviousFullName, NewFullName, LibraryID);
	
EndProcedure

// Returns a string presentation of the type.
// For reference types, returns a string in format "CatalogRef.ObjectName" or "DocumentRef.ObjectName".
// For any other types, converts the type to string. Example: "Number".
//
// Parameters:
//  Type - type - a type whose presentation is sought.
//
// Returns:
//  String - a type presentation.
//
Function TypePresentationString(Type) Export
	
	Presentation = "";
	
	If IsReference(Type) Then
	
		FullName = Metadata.FindByType(Type).FullName();
		ObjectName = StrSplit(FullName, ".")[1];
		
		If Catalogs.AllRefsType().ContainsType(Type) Then
			Presentation = "CatalogRef";
		
		ElsIf Documents.AllRefsType().ContainsType(Type) Then
			Presentation = "DocumentRef";
		
		ElsIf BusinessProcesses.AllRefsType().ContainsType(Type) Then
			Presentation = "BusinessProcessRef";
		
		ElsIf ChartsOfCharacteristicTypes.AllRefsType().ContainsType(Type) Then
			Presentation = "ChartOfCharacteristicTypesRef";
		
		ElsIf ChartsOfAccounts.AllRefsType().ContainsType(Type) Then
			Presentation = "ChartOfAccountsRef";
		
		ElsIf ChartsOfCalculationTypes.AllRefsType().ContainsType(Type) Then
			Presentation = "ChartOfCalculationTypesRef";
		
		ElsIf Tasks.AllRefsType().ContainsType(Type) Then
			Presentation = "TaskRef";
		
		ElsIf ExchangePlans.AllRefsType().ContainsType(Type) Then
			Presentation = "ExchangePlanRef";
		
		ElsIf Enums.AllRefsType().ContainsType(Type) Then
			Presentation = "EnumRef";
		
		EndIf;
		
		Result = ?(Presentation = "", Presentation, Presentation + "." + ObjectName);
		
	Else
		
		Result = String(Type);
		
	EndIf;
	
	Return Result;
	
EndFunction

//  Returns a value table with the required property information for all attributes of a metadata object.
// Gets property values of standard and custom attributes (custom attributes are the attributes created in Designer mode).
//
// Parameters:
//  MetadataObject  - MetadataObject - an object whose attribute property values are sought.
//                      Example: Metadata.Document.Invoice
//  Properties - String - comma-separated attribute properties whose values to be retrieved.
//                      Example: "Name, Type, Synonym, Tooltip".
//
// Returns:
//  ValueTable - required property information for all attributes of the metadata object.
//
Function ObjectPropertiesDetails(MetadataObject, Properties) Export
	
	PropertiesArray = StrSplit(Properties, ",");
	
	// Function return value.
	ObjectPropertyDetailsTable = New ValueTable;
	
	// Adding fields to the value table according to the names of the passed properties.
	For Each PropertyName In PropertiesArray Do
		ObjectPropertyDetailsTable.Columns.Add(TrimAll(PropertyName));
	EndDo;
	
	// Filling table rows with metadata object attribute values.
	For Each Attribute In MetadataObject.Attributes Do
		FillPropertyValues(ObjectPropertyDetailsTable.Add(), Attribute);
	EndDo;
	
	// Filling table rows with standard metadata object attribute properties.
	For Each Attribute In MetadataObject.StandardAttributes Do
		FillPropertyValues(ObjectPropertyDetailsTable.Add(), Attribute);
	EndDo;
	
	Return ObjectPropertyDetailsTable;
	
EndFunction

// Returns a flag indicating whether the attribute is a standard attribute.
//
// Parameters:
//  StandardAttributes - StandardAttributeDescriptions - the type and value describe a collection of 
//                                                         settings for various standard attributes;
//  AttributeName         - String - an attribute to check whether it is a standard attribute or not.
//                                  
// 
// Returns:
//   Boolean - True if the attribute is a standard attribute.
//
Function IsStandardAttribute(StandardAttributes, AttributeName) Export
	
	For Each Attribute In StandardAttributes Do
		If Attribute.Name = AttributeName Then
			Return True;
		EndIf;
	EndDo;
	Return False;
	
EndFunction

// Checks whether the attribute with the passed name exists among the object attributes.
//
// Parameters:
//  AttributeName - String - attribute name.
//  MetadataObject - MetadataObject - an object to search for the attribute.
//
// Returns:
//  Boolean - True if the attribute is found.
//
Function HasObjectAttribute(AttributeName, ObjectMetadata) Export

	Return NOT (ObjectMetadata.Attributes.Find(AttributeName) = Undefined);

EndFunction

// Checks whether the type description contains only one value type and it is equal to the specified 
// type.
//
// Parameters:
//   TypeDetails - TypesDetails - a type collection to check.
//   ValueType  - Type - a type to check.
//
// Returns:
//   Boolean - True if the types match.
//
// Example:
//  If Common.TypeDetailsContainsType(ValueTypeProperties, Type("Boolean") Then
//    // Displaying the field as a check box.
//  EndIf.
//
Function TypeDetailsContainsType(TypeDetails, ValueType) Export
	
	If TypeDetails.Types().Count() = 1
	   AND TypeDetails.Types().Get(0) = ValueType Then
		Return True;
	EndIf;
	
	Return False;
	
EndFunction

// Creates a TypesDetails object that contains the String type.
//
// Parameters:
//  StringLength - Number - string length.
//
// Returns:
//  TypesDetails - description of the String type.
//
Function StringTypeDetails(StringLength) Export

	Array = New Array;
	Array.Add(Type("String"));

	StringQualifier = New StringQualifiers(StringLength, AllowedLength.Variable);

	Return New TypeDescription(Array, , StringQualifier);

EndFunction

// Creates a TypesDetails object that contains the Number type.
//
// Parameters:
//  NumberOfDigits - Number - the total number of digits in a number (both in the integer part and 
//                        the fractional part).
//  DigitsInFractionalPart - Number - number of digits in the fractional part.
//  NumberSign - AllowedSign - allowed sign of the number.
//
// Returns:
//  TypesDetails - description of Number type.
Function TypeDescriptionNumber(NumberOfDigits, DigitsInFractionalPart = 0, NumberSign = Undefined) Export

	If NumberSign = Undefined Then
		NumberQualifier = New NumberQualifiers(NumberOfDigits, DigitsInFractionalPart);
	Else
		NumberQualifier = New NumberQualifiers(NumberOfDigits, DigitsInFractionalPart, NumberSign);
	EndIf;

	Return New TypeDescription("Number", NumberQualifier);

EndFunction

// Creates a TypesDetails object that contains the Date type.
//
// Parameters:
//  DateParts - DateParts - a set of Date type value usage options.
//
// Returns:
//  TypesDetails - description of Date type.
Function DateTypeDetails(DateParts) Export

	Array = New Array;
	Array.Add(Type("Date"));

	DateQualifier = New DateQualifiers(DateParts);

	Return New TypeDescription(Array, , , DateQualifier);

EndFunction

// Returns a type description that includes all configuration reference types.
//
// Returns:
//  TypesDescription - all reference types in the configuration.
//
Function AllRefsTypeDetails() Export
	
	Return StandardSubsystemsCached.AllRefsTypeDetails();
	
EndFunction

#EndRegion

#Region SettingsStorage

////////////////////////////////////////////////////////////////////////////////
// Saving, reading, and deleting settings from storages.

// Saves a setting to the common settings storage as the Save method of 
// StandardSettingsStorageManager or SettingsStorageManager.<Storage name> object. Setting keys 
// exceeding 128 characters are supported by hashing the key part that exceeds 96 characters.
// 
// If the SaveUserData right is not granted, data save fails and no error is raised.
//
// Parameters:
//   ObjectKey - String - see the Syntax Assistant.
//   SettingsKey - String - see the Syntax Assistant.
//   Settings - Arbitrary - see the Syntax Assistant.
//   SettingsDescription - SettingsDescription - see the Syntax Assistant.
//   UserName - String - see the Syntax Assistant.
//   UpdateCachedValues - Boolean - the flag that indicates whether to execute the method.
//
Procedure CommonSettingsStorageSave(ObjectKey, SettingsKey, Settings,
			SettingsDetails = Undefined,
			Username = Undefined,
			UpdateCachedValues = False) Export
	
	StorageSave(CommonSettingsStorage,
		ObjectKey,
		SettingsKey,
		Settings,
		SettingsDetails,
		Username,
		UpdateCachedValues);
	
EndProcedure

// Saves settings to the common settings storage as the Save method of 
// StandardSettingsStorageManager or SettingsStorageManager.<Storage name> object. Setting keys 
// exceeding 128 characters are supported by hashing the key part that exceeds 96 characters.
// 
// If the SaveUserData right is not granted, data save fails and no error is raised.
// 
// Parameters:
//   MultipleSettings - Array of the following values:
//     * Value - Structure - with the following properties:
//         * Object - String - see the ObjectKey parameter in the Syntax Assistant.
//         * Setting - String - see the SettingsKey parameter in the Syntax Assistant.
//         * Value - Arbitrary - see the Settings parameter in the Syntax Assistant.
//
//   UpdateCachedValues - Boolean - the flag that indicates whether to execute the method.
//
Procedure CommonSettingsStorageSaveArray(MultipleSettings,
			UpdateCachedValues = False) Export
	
	If Not AccessRight("SaveUserData", Metadata) Then
		Return;
	EndIf;
	
	For Each Item In MultipleSettings Do
		CommonSettingsStorage.Save(Item.Object, SettingsKey(Item.Settings), Item.Value);
	EndDo;
	
	If UpdateCachedValues Then
		RefreshReusableValues();
	EndIf;
	
EndProcedure

// Loads a setting from the general settings storage as the Load method, 
// StandardSettingsStorageManager objects, or SettingsStorageManager.<Storage name>. The setting key 
// supports more than 128 characters by hashing the part that exceeds 96 characters.
// 
// If no settings are found, returns the default value.
// If the SaveUserData right is not granted, the default value is returned and no error is raised.
//
// References to database objects that do not exist are cleared from the return value:
// - The returned reference is replaced by the default value.
// - The references are deleted from the data of Array type.
// - Key is not changed for the data of Structure or Map types, and value is set to Undefined.
// - Recursive analysis of values in the data of Array, Structure, Map types is performed.
//
// Parameters:
//   ObjectKey - String - see the Syntax Assistant.
//   SettingsKey - String - see the Syntax Assistant.
//   DefaultValue - Arbitrary - a value that is returned if no settings are found.
//                                             If not specified, returns Undefined.
//   SettingsDescription - SettingsDescription - see the Syntax Assistant.
//   UserName - String - see the Syntax Assistant.
//
// Returns:
//   Arbitrary - see the Syntax Assistant.
//
Function CommonSettingsStorageLoad(ObjectKey, SettingsKey, DefaultValue = Undefined, 
			SettingsDetails = Undefined, Username = Undefined) Export
	
	Return StorageLoad(CommonSettingsStorage,
		ObjectKey,
		SettingsKey,
		DefaultValue,
		SettingsDetails,
		Username);
	
EndFunction

// Removes a setting from the general settings storage as the Remove method, 
// StandardSettingsStorageManager objects, or SettingsStorageManager.<Storage name>. The setting key 
// supports more than 128 characters by hashing the part that exceeds 96 characters.
// 
// If the SaveUserData right is not granted, no data is deleted and no error is raised.
//
// Parameters:
//   ObjectKey - String, Undefined - see the Syntax Assistant.
//   SettingsKey - String, Undefined - see the Syntax Assistant.
//   UserName - String, Undefined - see the Syntax Assistant.
//
Procedure CommonSettingsStorageDelete(ObjectKey, SettingsKey, Username) Export
	
	StorageDelete(CommonSettingsStorage,
		ObjectKey,
		SettingsKey,
		Username);
	
EndProcedure

// Saves a setting to the system settings storage as the Save method of 
// StandardSettingsStorageManager object. Setting keys exceeding 128 characters are supported by 
// hashing the key part that exceeds 96 characters.
// If the SaveUserData right is not granted, data save fails and no error is raised.
//
// Parameters:
//   ObjectKey - String - see the Syntax Assistant.
//   SettingsKey - String - see the Syntax Assistant.
//   Settings - Arbitrary - see the Syntax Assistant.
//   SettingsDescription - SettingsDescription - see the Syntax Assistant.
//   UserName - String - see the Syntax Assistant.
//   UpdateCachedValues - Boolean - the flag that indicates whether to execute the method.
//
Procedure SystemSettingsStorageSave(ObjectKey, SettingsKey, Settings,
			SettingsDetails = Undefined,
			Username = Undefined,
			UpdateCachedValues = False) Export
	
	StorageSave(SystemSettingsStorage, 
		ObjectKey,
		SettingsKey,
		Settings,
		SettingsDetails,
		Username,
		UpdateCachedValues);
	
EndProcedure

// Loads a setting from the system settings storage as the Load method or the 
// StandardSettingsStorageManager object. The setting key supports more than 128 characters by 
// hashing the part that exceeds 96 characters.
// If no settings are found, returns the default value.
// If the SaveUserData right is not granted, the default value is returned and no error is raised.
//
// The return value clears references to a non-existent object in the database, namely:
// - The returned reference is replaced by the default value.
// - The references are deleted from the data of Array type.
// - Key is not changed for the data of Structure or Map types, and value is set to Undefined.
// - Recursive analysis of values in the data of Array, Structure, Map types is performed.
//
// Parameters:
//   ObjectKey - String - see the Syntax Assistant.
//   SettingsKey - String - see the Syntax Assistant.
//   DefaultValue - Arbitrary - a value that is returned if no settings are found.
//                                             If not specified, returns Undefined.
//   SettingsDescription - SettingsDescription - see the Syntax Assistant.
//   UserName - String - see the Syntax Assistant.
//
// Returns:
//   Arbitrary - see the Syntax Assistant.
//
Function SystemSettingsStorageLoad(ObjectKey, SettingsKey, DefaultValue = Undefined, 
			SettingsDetails = Undefined, Username = Undefined) Export
	
	Return StorageLoad(SystemSettingsStorage,
		ObjectKey,
		SettingsKey,
		DefaultValue,
		SettingsDetails,
		Username);
	
EndFunction

// Removes a setting from the system settings storage as the Remove method or the 
// StandardSettingsStorageManager object. The setting key supports more than 128 characters by 
// hashing the part that exceeds 96 characters.
// If the SaveUserData right is not granted, no data is deleted and no error is raised.
//
// Parameters:
//   ObjectKey - String, Undefined - see the Syntax Assistant.
//   SettingsKey - String, Undefined - see the Syntax Assistant.
//   UserName - String, Undefined - see the Syntax Assistant.
//
Procedure SystemSettingsStorageDelete(ObjectKey, SettingsKey, Username) Export
	
	StorageDelete(SystemSettingsStorage,
		ObjectKey,
		SettingsKey,
		Username);
	
EndProcedure

// Saves a setting to the form data settings storage as the Save method of 
// StandardSettingsStorageManager or SettingsStorageManager.<Storage name> object. Setting keys 
// exceeding 128 characters are supported by hashing the key part that exceeds 96 characters.
// 
// If the SaveUserData right is not granted, data save fails and no error is raised.
//
// Parameters:
//   ObjectKey - String - see the Syntax Assistant.
//   SettingsKey - String - see the Syntax Assistant.
//   Settings - Arbitrary - see the Syntax Assistant.
//   SettingsDescription - SettingsDescription - see the Syntax Assistant.
//   UserName - String - see the Syntax Assistant.
//   UpdateCachedValues - Boolean - the flag that indicates whether to execute the method.
//
Procedure FormDataSettingsStorageSave(ObjectKey, SettingsKey, Settings,
			SettingsDetails = Undefined,
			Username = Undefined, 
			UpdateCachedValues = False) Export
	
	StorageSave(FormDataSettingsStorage,
		ObjectKey,
		SettingsKey,
		Settings,
		SettingsDetails,
		Username,
		UpdateCachedValues);
	
EndProcedure

// Retrieves the setting from the form data settings storage using the Load method for 
// StandardSettingsStorageManager or SettingsStorageManager.<Storage name> objects. Setting keys 
// exceeding 128 characters are supported by hashing the key part that exceeds 96 characters.
// 
// If no settings are found, returns the default value.
// If the SaveUserData right is not granted, the default value is returned and no error is raised.
//
// References to database objects that do not exist are cleared from the return value:
// - The returned reference is replaced by the default value.
// - The references are deleted from the data of Array type.
// - Key is not changed for the data of Structure or Map types, and value is set to Undefined.
// - Recursive analysis of values in the data of Array, Structure, Map types is performed.
//
// Parameters:
//   ObjectKey - String - see the Syntax Assistant.
//   SettingsKey - String - see the Syntax Assistant.
//   DefaultValue - Arbitrary - a value that is returned if no settings are found.
//                                             If not specified, returns Undefined.
//   SettingsDescription - SettingsDescription - see the Syntax Assistant.
//   UserName - String - see the Syntax Assistant.
//
// Returns:
//   Arbitrary - see the Syntax Assistant.
//
Function FormDataSettingsStorageLoad(ObjectKey, SettingsKey, DefaultValue = Undefined, 
			SettingsDetails = Undefined, Username = Undefined) Export
	
	Return StorageLoad(FormDataSettingsStorage,
		ObjectKey,
		SettingsKey,
		DefaultValue,
		SettingsDetails, 
		Username);
	
EndFunction

// Deletes the setting from the form data settings storage using the Delete method for 
// StandardSettingsStorageManager or SettingsStorageManager.<Storage name> objects. Setting keys 
// exceeding 128 characters are supported by hashing the key part that exceeds 96 characters.
// 
// If the SaveUserData right is not granted, no data is deleted and no error is raised.
//
// Parameters:
//   ObjectKey - String, Undefined - see the Syntax Assistant.
//   SettingsKey - String, Undefined - see the Syntax Assistant.
//   UserName - String, Undefined - see the Syntax Assistant.
//
Procedure FormDataSettingsStorageDelete(ObjectKey, SettingsKey, Username) Export
	
	StorageDelete(FormDataSettingsStorage,
		ObjectKey,
		SettingsKey,
		Username);
	
EndProcedure

#EndRegion

#Region XMLSerialization

// Converts (serializes) a value to an XML string.
// Only objects that support serialization (see the Syntax Assistant) can be converted.
// See also ValueFromXMLString.
//
// Parameters:
//  Value - Arbitrary - a value to serialize into an XML string.
//
// Returns:
//  String - an XML string.
//
Function ValueToXMLString(Value) Export
	
	XMLWriter = New XMLWriter;
	XMLWriter.SetString();
	XDTOSerializer.WriteXML(XMLWriter, Value, XMLTypeAssignment.Explicit);
	
	Return XMLWriter.Close();
EndFunction

// Converts (deserializes) an XML string into a value.
// See also ValueToXMLString.
//
// Parameters:
//  XMLString - String - an XML string with a serialized object.
//
// Returns:
//  Arbitrary - the value extracted from an XML string.
//
Function ValueFromXMLString(XMLString) Export
	
	XMLReader = New XMLReader;
	XMLReader.SetString(XMLString);
	
	Return XDTOSerializer.ReadXML(XMLReader);
EndFunction

// Returns an XML presentation of the XDTO object.
//
// Parameters:
//  XDTODataObject - XDTODataObject - an object that requires XML presentation to be generated.
//  Factory - XDTOFactory - the factory used for generating the XML presentation.
//                             If the parameter is not specified, the global XDTO factory is used.
//
// Returns:
//   String - the XML presentation of the XDTO object.
//
Function XDTODataObjectToXMLString(Val XDTODataObject, Val Factory = Undefined) Export
	
	XDTODataObject.Validate();
	
	If Factory = Undefined Then
		Factory = XDTOFactory;
	EndIf;
	
	Record = New XMLWriter();
	Record.SetString();
	Factory.WriteXML(Record, XDTODataObject, , , , XMLTypeAssignment.Explicit);
	
	Return Record.Close();
	
EndFunction

// Generates an XDTO object by the XML presentation.
//
// Parameters:
//  XMLString - String - the XML presentation of the XDTO object.
//  Factory - XDTOFactory - the factory used for generating the XDTO object.
//                          If the parameter is not specified, the global XDTO factory is used.
//
// Returns:
//  XDTODataObject - an XDTO object.
//
Function XDTODataObjectFromXMLString(Val XMLString, Val Factory = Undefined) Export
	
	If Factory = Undefined Then
		Factory = XDTOFactory;
	EndIf;
	
	Read = New XMLReader();
	Read.SetString(XMLString);
	
	Return Factory.ReadXML(Read);
	
EndFunction

#EndRegion

#Region WebServices

// Returns a parameter structure for the CreateWSProxy function.
//
// Returns:
//  Structure - a collection of parameters. See CreateWSProxy(). 
//
Function WSProxyConnectionParameters() Export
	Result = New Structure;
	Result.Insert("WSDLAddress");
	Result.Insert("NamespaceURI");
	Result.Insert("ServiceName");
	Result.Insert("EndpointName", "");
	Result.Insert("UserName");
	Result.Insert("Password");
	Result.Insert("Timeout", 0);
	Result.Insert("Location");
	Result.Insert("UseOSAuthentication", False);
	Result.Insert("ProbingCallRequired", False);
	Result.Insert("SecureConnection", Undefined);
	Return Result;
EndFunction

// Constructor of the WSProxy object.
//
// It differs from New WSProxy constructor as follows:
//  - WSDefinitions constructor is embedded.
//  - WSDL file caching is supported.
//  - Configuring InternetProxy is not required (but used automatically if configured).
//  - Quick service availability check is supported.
//
// Parameters:
//  PassedParameters - Structure - connection settings (the WSProxyConnectionParameters function is required):
//   * WSDLAddress - String - the wsdl location.
//   * NamespaceURI - String - URI of the web service namespace.
//   * ServiceName - String - the service name.
//   * EndpointName - String - (optional) if not specified, it is generated from template <ServiceName>Soap.
//   * UserName - String - (optional) a user name for server authorization.
//   * Password - String - (optional) a user password.
//   * Timeout - Number - (optional) the timeout for operations that are run through the proxy.
//   * Location - String - (optional) the actual service address. Used if the actual server address 
//                                             does not match the WSDL file address.
//   * UseOSAuthentication - Boolean - (optional) enables NTLM or Negotiate authorization on the 
//                                             server.
//   * ProbingCallRequired - Boolean - (optional) checks the service availability. The web service 
//                                             must support this function.
//   * SecureConnection - OpenSSLSecureConnection, Undefined - (optional) secure connection 
//                                                                                parameters.
//
// Returns:
//  WSProxy - WSProxy object.
//
Function CreateWSProxy(PassedParameters) Export
	
	CommonClientServer.CheckParameter("CreateWSProxy", "Parameters", PassedParameters, Type("Structure"),
		New Structure("WSDLAddress,NamespaceURI,ServiceName", Type("String"), Type("String"), Type("String")));
		
	ConnectionParameters = WSProxyConnectionParameters();
	FillPropertyValues(ConnectionParameters, PassedParameters);
	
	ProbingCallRequired = ConnectionParameters.ProbingCallRequired;
	Timeout = ConnectionParameters.Timeout;
	
	If ProbingCallRequired AND Timeout <> Undefined AND Timeout > 20 Then
		ConnectionParameters.Timeout = 7;
		WSProxyPing = InformationRegisters.ProgramInterfaceCache.InnerWSProxy(ConnectionParameters);
		Try
			WSProxyPing.Ping();
		Except
			
			EndpointAddress = WSProxyPing.Endpoint.Location;
			
			ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'Не удалось проверить доступность web-сервиса
				           |%1
				           |по причине:
				           |%2'; 
				           |en = 'Cannot check availability of the web service
				           |%1.
				           |Reason:
				           |%2.'; 
				           |pl = 'Nie można sprawdzić dostępności serwisu www
				           |%1
				           |z powodu:
				           |%2';
				           |de = 'Eine Überprüfung der Verfügbarkeit des Webservice
				           |%1
				           |war aus diesem Grund nicht möglich:
				           |%2';
				           |ro = 'Eșec la verificarea disponibilității serviciului-web 
				           |%1
				           |din motivul:
				           |%2';
				           |tr = 'Web sitenin erişimi aşağıdaki nedenle kontrol edilemedi 
				           |%1
				           |: 
				           |%2'; 
				           |es_ES = 'No se ha podido comprobar la disponibilidad del servicio web 
				           |%1
				           |a causa de:
				           |%2'"),
				ConnectionParameters.WSDLAddress,
				BriefErrorDescription(ErrorInfo()));
			
			If SubsystemExists("StandardSubsystems.GetFilesFromInternet") Then
				ModuleNetworkDownload = CommonModule("GetFilesFromInternet");
				DiagnosticsResult = ModuleNetworkDownload.ConnectionDiagnostics(EndpointAddress);
				
				ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("ru = '%1
					           |Результат диагностики:
					           |%2'; 
					           |en = '%1
					           |Diagnostics result:
					           |%2'; 
					           |pl = '%1
					           |Wynik diagnostyczny:
					           |%2';
					           |de = '%1
					           |Diagnoseergebnis:
					           |%2';
					           |ro = '%1
					           |Rezultatul diagnosticului:
					           |%2';
					           |tr = '%1
					           |Tanı sonuçları: 
					           |%2'; 
					           |es_ES = '%1
					           |Resultado de diagnóstica:
					           |%2'"),
					DiagnosticsResult.ErrorDescription);
			EndIf;
			
			WriteLogEvent(NStr("ru = 'WSПрокси'; en = 'WSProxy'; pl = 'WSProxy';de = 'WSProxy';ro = 'WSProxy';tr = 'WSProxy'; es_ES = 'WSProxy'", DefaultLanguageCode()),
				EventLogLevel.Error,,, ErrorText);
			Raise ErrorText;
		EndTry;
		ConnectionParameters.Timeout = Timeout;
	EndIf;
	
	Return InformationRegisters.ProgramInterfaceCache.InnerWSProxy(ConnectionParameters);
	
EndFunction

/////////////////////////////////////////////////////////////////////////////////
// Interface versioning.

// Returns version numbers of interfaces in a remote system accessed over web service.
// Ensures full backwards compatibility against any API modifications, based on explicit versioning.
//  For example, you could specify that a new function is only available if the API used is later 
// than a specific version.
//
// For traffic economy purposes, API version information is cached daily when under heavy traffic 
// conditions. To clear the cache before the daily timeout, delete the corresponding records from 
// the ProgramInterfaceCache information register.
//
// Parameters:
//  Address - String - address of InterfaceVersion web service.
//  User - String - name of a web service user.
//  Password - String - password of a web service user.
//  Interface - String - name of the queried interface. Example: "FileTransferService".
//
// Returns:
//   FixedArray - array of strings where each string contains a presentation of an interface version number. 
//                         Example: "1.0.2.1".
//
// Example:
//	  Versions = GetInterfaceVersions("http://vsrvx/sm", "smith",, "FileTransferService");
//
//    The obsolete option is also supported for backward compatibility reason:
//	  ConnectionParameters = New Structure;
//	  ConnectionParameters.Insert("URL", "http://vsrvx/sm");
//	  ConnectionParameters.Insert("UserName", "smith");
//	  ConnectionParameters.Insert("Password", "");
//	  Versions = GetInterfaceVersions(ConnectionParameters, "FileTransferService");
//
Function GetInterfaceVersions(Val Address, Val User, Val Password = Undefined, Val Interface = Undefined) Export
	
	If TypeOf(Address) = Type("Structure") Then // For backward compatibility
		ConnectionParameters = Address;
		InterfaceName = User;
	Else
		ConnectionParameters = New Structure;
		ConnectionParameters.Insert("URL", Address);
		ConnectionParameters.Insert("UserName", User);
		ConnectionParameters.Insert("Password", Password);
		InterfaceName = Interface;
	EndIf;
	
	If Not ConnectionParameters.Property("URL") 
		Or Not ValueIsFilled(ConnectionParameters.URL) Then
		
		Raise(NStr("ru = 'Не задан URL сервиса.'; en = 'The service URL is not set.'; pl = 'Nie określono adresu URL serwisu.';de = 'URL des Dienstes ist nicht angegeben.';ro = 'Adresa URL a serviciului nu este specificată.';tr = 'Hizmetin URL''si belirlenmemiş.'; es_ES = 'URL del servicio no está especificado.'"));
	EndIf;
	
	ReceivingParameters = New Array;
	ReceivingParameters.Add(ConnectionParameters);
	ReceivingParameters.Add(InterfaceName);
	
	Return InformationRegisters.ProgramInterfaceCache.VersionCacheData(
		InformationRegisters.ProgramInterfaceCache.VersionCacheRecordID(ConnectionParameters.URL, InterfaceName), 
		Enums.APICacheDataTypes.InterfaceVersions, 
		ReceivingParameters,
		True);
	
EndFunction

// Returns version numbers of interfaces in a remote system accessed over external connection.
// Ensures full backwards compatibility against any API modifications, based on explicit versioning.
//  For example, you could specify that a new function is only available if the API used is later 
// than a specific version.
//
// Parameters:
//   ExternalConnection - COMObject - an external connection used to access a remote system.
//   InterfaceName     - String    - name of the queried interface, for example: FileTransferService.
//
// Returns:
//   FixedArray - array of strings where each string contains a presentation of an interface version number. 
//                         For example: "1.0.2.1".
//
// Example:
//  Versions = Common.GetInterfaceVersionsViaExternalConnection(ExternalConnection, "FileTransferService");
//
Function GetInterfaceVersionsViaExternalConnection(ExternalConnection, Val InterfaceName) Export
	Try
		XMLInterfaceVersions = ExternalConnection.StandardSubsystemsServer.SupportedVersions(InterfaceName);
	Except
		MessageString = NStr("ru = 'Корреспондент не поддерживает версионирование программных интерфейсов.
			|Описание ошибки: %1'; 
			|en = 'The other infobase that participates in data exchange does not support versioning of application interfaces.
			|Error description:%1'; 
			|pl = 'Korespondent nie obsługuje wersjonowanie interfejsów programowych.
			|Opis błędu: %1';
			|de = 'Der Korrespondent unterstützt nicht die Versionierung von Programmschnittstellen.
			|Beschreibung des Fehlers: %1';
			|ro = 'Corespondentul nu susține versionarea interfețelor de program.
			|Descrierea erorii: %1';
			|tr = 'Muhabir yazılım arayüzleri sürümü desteklemiyor. 
			|Hata açıklaması:%1'; 
			|es_ES = 'El correspondiente no soporta el versionado de las interfaces de programa.
			|Descripción de error: %1'");
		MessageString = StringFunctionsClientServer.SubstituteParametersToString(MessageString, DetailErrorDescription(ErrorInfo()));
		WriteLogEvent(NStr("ru = 'Получение версий интерфейса'; en = 'Getting interface versions'; pl = 'Odbieranie wersji interfejsu';de = 'Erhalten Sie Schnittstellenversionen';ro = 'Obținerea versiunii de interfață';tr = 'Arayüz sürümlerini al'; es_ES = 'Recibir las versiones de la interfaz'", DefaultLanguageCode()),
			EventLogLevel.Error, , , MessageString);
		
		Return New FixedArray(New Array);
	EndTry;
	
	Return New FixedArray(ValueFromXMLString(XMLInterfaceVersions));
EndFunction

// Deletes records from cache of interface versions that contain the specified substring in their IDs.
// For example, a name of obsolete interface can be specified as the substring.
//
// Parameters:
//  IDSearchSubstring - String - ID search substring.
//                                            Cannot contain the following characters: % _ [.
//
Procedure DeleteVersionCacheRecords(Val IDSearchSubstring) Export
	
	BeginTransaction();
	Try
		
		Lock = New DataLock;
		Lock.Add("InformationRegister.ProgramInterfaceCache");
		Lock.Lock();
		SearchSubstring = GenerateSearchQueryString(IDSearchSubstring);
		
		QueryText =
			"SELECT
			|	CacheTable.ID AS ID,
			|	CacheTable.DataType AS DataType
			|FROM
			|	InformationRegister.ProgramInterfaceCache AS CacheTable
			|WHERE
			|	CacheTable.ID LIKE ""%" + SearchSubstring + "%""
			|		ESCAPE ""~""";
		
		Query = New Query(QueryText);
		Result = Query.Execute();
		Selection = Result.Select();
		While Selection.Next() Do
			
			Record = InformationRegisters.ProgramInterfaceCache.CreateRecordManager();
			Record.ID = Selection.ID;
			Record.DataType = Selection.DataType;
			
			Record.Delete();
			
		EndDo;
		
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;
	
EndProcedure

#EndRegion

#Region SecureDataStorage

////////////////////////////////////////////////////////////////////////////////
// Password storage management procedures and functions.

// Writes confidential data to a secure storage.
// The calling script must enable privileged mode.
//
// Users (except administrators) cannot read data from the secure storage. The code can only read 
// the data related to it, and only in context of confidential data reading and writing.
// 
//
// Parameters:
//  Owner - ExchangePlanRef, CatalogRef, String - a reference to the infobase object representing 
//             the object that owns the password, or a string containing up to 128 characters.
//             For objects of other types, use a reference to metadata item of that kind in the 
//             MetadataObjectIDs catalog or a string key accounting to subsystem names as owner.
//             
//             For SSL, the code looks as follows:
//               Owner = Common.MetadataObjectID("InformationRegister.AddressObjects");
//             If one storage is sufficient for SSL subsystem:
//               Owner = "StandardSubsystems.AccessManagement";
//             if multiple storages are required for an SSL subsystem:
//               Owner = "StandardSubsystems.AccessManagement.<Clarification>";
//
//  Data  - Arbitrary - data to save to the secure storage. Undefined - deletes all data.
//             To delete data by key, use the DeleteDataFromSecureStorage procedure instead.
//  Key - String - a key of the settings to be saved. The default value is "Password".
//                           The key must meet the rules that apply to IDs:
//                           * The key must begin with a letter or underscore character (_).
//                           * The key may contain letters, digits, and underscore characters (_).
//
// Example:
//  Procedure OnWriteAtServer(Cancel, CurrentObject, WriteParameters)
//      If CurrentUserCanChangePassword Then
//          SetPrivilegedMode(True);
//          Common.WriteDataToSecureStorage(CurrentObject.Ref, Username, "Username");
//          Common.WriteDataToSecureStorage(CurrentObject.Ref, Password);
//          SetPrivilegedMode(False);
//      EndIf.
//  EndProcedure
//
Procedure WriteDataToSecureStorage(Owner, Data, varKey = "Password") Export
	
	CommonClientServer.Validate(ValueIsFilled(Owner),
		StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Недопустимое значение параметра %1 в %2.
			           |параметр должен содержать ссылку; передано значение: %3 (тип %4).'; 
			           |en = 'Invalid value of the %1 parameter, %2.
			           |The value must be of the Ref type. The passed value is %3 (type: %4).'; 
			           |pl = 'Niedopuszczalna wartość parametrów %1 w %2.
			           |parametr powinien zawierać link; przekazano wartość: %3 (typ %4).';
			           |de = 'Ungültiger Parameterwert %1 in%2.
			           |Parameter muss eine Referenz enthalten. übertragener Wert: %3 (Typ %4).';
			           |ro = 'Valoare inadmisibilă a parametrului %1 în %2.
			           |parametru trebuie să conțină referința; este transmisă valoarea: %3 (tipul %4).';
			           |tr = 'Geçersiz parametre değeri %1''de %4parametre %2bir başvuru içermelidir; aktarılan değer:
			           | (tür%3).'; 
			           |es_ES = 'Valor del parámetro no admitido %1 en %2.
			           |el parámetro debe contener un enlace; valor transmitido: %3 (tipo %4).'"),
			"Owner", "Common.WriteDataToSecureStorage", Owner, TypeOf(Owner)));
			
	CommonClientServer.Validate(TypeOf(varKey) = Type("String"),
		StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Недопустимое значение параметра %1 в %2.
			           |параметр должен содержать строку; передано значение: %3 (тип %4).'; 
			           |en = 'Invalid value of the %1 parameter, %2.
			           |The value must be of the String type. The passed value is %3 (type: %4).'; 
			           |pl = 'Niedopuszczalna wartość parametrów %1 w %2.
			           |parametr powinien zawierać wiersz; przekazano wartość: %3 (typ %4).';
			           |de = 'Ein ungültiger Parameterwert %1 in %2.
			           | Parameter muss eine Zeichenkette enthalten; der übergebene Wert ist: %3 (Typ %4).';
			           |ro = 'Valoare inadmisibilă a parametrului %1 în %2.
			           |parametru trebuie să conțină rândul; este transmisă valoarea: %3 (tipul %4).';
			           |tr = 'Geçersiz parametre değeri %1''de %4parametre %2bir satır içermelidir; aktarılan değer:
			           | (tür%3).'; 
			           |es_ES = 'Valor del parámetro no admitido %1 en %2.
			           |el parámetro debe contener una línea; valor transmitido: %3 (tipo %4).'"),
			"Key", "Common.WriteDataToSecureStorage", varKey, TypeOf(varKey)));
	
	IsDataArea = DataSeparationEnabled() AND SeparatedDataUsageAvailable();
	If IsDataArea Then
		SafeDataStorage = InformationRegisters.SafeDataAreaDataStorage.CreateRecordManager();
	Else
		SafeDataStorage = InformationRegisters.SafeDataStorage.CreateRecordManager();
	EndIf;
	
	SafeDataStorage.Owner = Owner;
	SafeDataStorage.Read();
	If Data <> Undefined Then
		If SafeDataStorage.Selected() Then
			DataToSave = SafeDataStorage.Data.Get();
			If TypeOf(DataToSave) <> Type("Structure") Then
				DataToSave = New Structure();
			EndIf;
			DataToSave.Insert(varKey, Data);
			DataForValueStorage = New ValueStorage(DataToSave, New Deflation(6));
			SafeDataStorage.Data = DataForValueStorage;
			SafeDataStorage.Write();
		Else
			DataToSave = New Structure(varKey, Data);
			DataForValueStorage = New ValueStorage(DataToSave, New Deflation(6));
			SafeDataStorage.Data = DataForValueStorage;
			SafeDataStorage.Owner = Owner;
			SafeDataStorage.Write();
		EndIf;
	Else
		SafeDataStorage.Delete();
	EndIf;
	
EndProcedure

// Retrieves data from a secure storage.
// The calling script must enable privileged mode.
//
// Users (except administrators) cannot read data from the secure storage. The code can only read 
// the data related to it, and only in context of confidential data reading and writing.
// 
//
// Parameters:
//  Owner    - ExchangePlanRef, CatalogRef, String - a reference to the infobase object representing 
//                  the object that owns the password, or a string containing up to 128 characters.
//  Keys       - String - contains a comma-separated list of saved data item names.
//  CommonData - Boolean - True if getting data from common data in separated mode in SaaS mode.
// 
// Returns:
//  Arbitrary, Structure, Undefined - data from the secure storage. If single key is specified, its 
//                            value is returned, otherwise a structure is returned.
//                            If no data is available - Undefined.
//
// Example:
//	Procedure OnReadAtServer(CurrentObject)
//		
//		If CurrentUserCanChangePassword Then
//			SetPrivilegedMode(True);
//			Username  = Common.ReadDataFromSecureStorage(CurrentObject.Ref, "Username");
//			Password  = Common.ReadDataFromSecureStorage(CurrentObject.Ref);
//			SetPrivilegedMode(False);
//		Else
//			Items.UsernameAndPasswordGroup.Visibility= False;
//		EndIf.
//		
//	EndProcedure
//
Function ReadDataFromSecureStorage(Owner, Keys = "Password", SharedData = Undefined) Export
	
	CommonClientServer.Validate(ValueIsFilled(Owner),
		StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Недопустимое значение параметра %1 в %2.
			           |параметр должен содержать ссылку; передано значение: %3 (тип %4).'; 
			           |en = 'Invalid value of the %1 parameter, %2.
			           |The value must be of the Ref type. The passed value is %3 (type: %4).'; 
			           |pl = 'Niedopuszczalna wartość parametrów %1 w %2.
			           |parametr powinien zawierać link; przekazano wartość: %3 (typ %4).';
			           |de = 'Ungültiger Parameterwert %1 in%2.
			           |Parameter muss eine Referenz enthalten. übertragener Wert: %3 (Typ %4).';
			           |ro = 'Valoare inadmisibilă a parametrului %1 în %2.
			           |parametru trebuie să conțină referința; este transmisă valoarea: %3 (tipul %4).';
			           |tr = 'Geçersiz parametre değeri %1''de %4parametre %2bir başvuru içermelidir; aktarılan değer:
			           | (tür%3).'; 
			           |es_ES = 'Valor del parámetro no admitido %1 en %2.
			           |el parámetro debe contener un enlace; valor transmitido: %3 (tipo %4).'"),
			"Owner", "Common.ReadDataFromSecureStorage", Owner, TypeOf(Owner)));
	
	If DataSeparationEnabled()
			AND SeparatedDataUsageAvailable() Then
		If SharedData = True Then
			SecureDataStorageName = "SafeDataStorage";
		Else
			SecureDataStorageName = "SafeDataAreaDataStorage";
		EndIf;
	Else
		SecureDataStorageName = "SafeDataStorage";
		
	EndIf;
	Result = DataFromSecureStorage(Owner, SecureDataStorageName, Keys);
	
	If Result <> Undefined AND Result.Count() = 1 Then
		Return ?(Result.Property(Keys), Result[Keys], Undefined);
	EndIf;
	
	Return Result;

EndFunction

// Deletes confidential data from a secure storage.
// The calling script must enable privileged mode.
//
// Users (except administrators) cannot read data from the secure storage. The code can only read 
// the data related to it, and only in context of confidential data reading and writing.
// 
//
// Parameters:
//  Owner - ExchangePlanRef, CatalogRef, String - a reference to the infobase object representing 
//               the object that owns the password, or a string containing up to 128 characters.
//  Keys    - String - contains a comma-separated list of deleted data item names.
//               Undefined - deletes all data.
//
// Example:
//	Procedure beforeDelete(Cancel)
//		
//		// Skipping the DataExchange.Import property check because it is necessary to delete data
//		// from the secure storage even if the object is deleted during data exchange.
//		
//		SetPrivilegedMode(True);
//		Common.DeleteDataFromSecureStorage(Ref);
//		SetPrivilegedMode(False);
//		
//	EndProcedure
//
Procedure DeleteDataFromSecureStorage(Owner, Keys = Undefined) Export
	
	CommonClientServer.Validate(ValueIsFilled(Owner),
		StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Недопустимое значение параметра %1 в %2.
			           |параметр должен содержать ссылку; передано значение: %3 (тип %4).'; 
			           |en = 'Invalid value of the %1 parameter, %2.
			           |The value must be of the Ref type. The passed value is %3 (type: %4).'; 
			           |pl = 'Niedopuszczalna wartość parametrów %1 w %2.
			           |parametr powinien zawierać link; przekazano wartość: %3 (typ %4).';
			           |de = 'Ungültiger Parameterwert %1 in%2.
			           |Parameter muss eine Referenz enthalten. übertragener Wert: %3 (Typ %4).';
			           |ro = 'Valoare inadmisibilă a parametrului %1 în %2.
			           |parametru trebuie să conțină referința; este transmisă valoarea: %3 (tipul %4).';
			           |tr = 'Geçersiz parametre değeri %1''de %4parametre %2bir başvuru içermelidir; aktarılan değer:
			           | (tür%3).'; 
			           |es_ES = 'Valor del parámetro no admitido %1 en %2.
			           |el parámetro debe contener un enlace; valor transmitido: %3 (tipo %4).'"),
			"Owner", "Common.DeleteDataFromSecureStorage", Owner, TypeOf(Owner)));
	
	If DataSeparationEnabled() AND SeparatedDataUsageAvailable() Then
		SafeDataStorage = InformationRegisters.SafeDataAreaDataStorage.CreateRecordManager();
	Else
		SafeDataStorage = InformationRegisters.SafeDataStorage.CreateRecordManager();
	EndIf;
	
	SafeDataStorage.Owner = Owner;
	SafeDataStorage.Read();
	If TypeOf(SafeDataStorage.Data) = Type("ValueStorage") Then
		DataToSave = SafeDataStorage.Data.Get();
		If Keys <> Undefined AND TypeOf(DataToSave) = Type("Structure") Then
			KeysList = StrSplit(Keys, ",", False);
			If SafeDataStorage.Selected() AND KeysList.Count() > 0 Then
				For each KeyToDelete In KeysList Do
					If DataToSave.Property(KeyToDelete) Then
						DataToSave.Delete(KeyToDelete);
					EndIf;
				EndDo;
				DataForValueStorage = New ValueStorage(DataToSave, New Deflation(6));
				SafeDataStorage.Data = DataForValueStorage;
				SafeDataStorage.Write();
				Return;
			EndIf;
		EndIf;
	EndIf;
	
	SafeDataStorage.Delete();
	
EndProcedure

#EndRegion

#Region Clipboard

////////////////////////////////////////////////////////////////////////////////
// Procedures and functions for internal clipboard management.

// Copies the selected tabular section rows to the internal clipboard so that they can be retrieved 
// using RowsFromClipboard.
//
// Parameters:
//  TabularSection   - FormDataCollection - a tabular section whose rows need to be placed to the 
//                                            internal clipboard.
//  SelectedRows - Array - an array of IDs for selected rows.
//  Source         - String - an arbitrary string ID (for example, name of the object whose tabular 
//                              section rows are to be copied to the internal clipboard).
//
Procedure CopyRowsToClipboard(TabularSection, SelectedRows, Source = Undefined) Export
	
	If SelectedRows = Undefined Then
		Return;
	EndIf;
	
	ValueTable = TabularSection.Unload();
	ValueTable.Clear();
	
	ColumnsToDelete = New Array;
	ColumnsToDelete.Add("SourceLineNumber");
	ColumnsToDelete.Add("LineNumber");
	
	For Each ColumnName In ColumnsToDelete Do
		Column = ValueTable.Columns.Find(ColumnName);
		If Column = Undefined Then
			Continue;
		EndIf;
		
		ValueTable.Columns.Delete(Column);
	EndDo;
	
	For Each RowID In SelectedRows Do
		RowToCopy = TabularSection.FindByID(RowID);
		FillPropertyValues(ValueTable.Add(), RowToCopy);
	EndDo;
	
	CopyToClipboard(ValueTable, Source);
	
EndProcedure

// Copies temporary data to the clipboard. To get the data, use RowsFromClipboard.
//
// Parameters:
//  Data           - Arbitrary - the data to be copied to the clipboard.
//  Source         - String - an arbitrary ID string (for example, name of the object whose tabular 
//                                    section rows are to be copied to the internal clipboard).
//
Procedure CopyToClipboard(Data, Source = Undefined) Export
	
	CurrentClipboard = SessionParameters.Clipboard;
	
	If ValueIsFilled(CurrentClipboard.Data) Then
		Address = CurrentClipboard.Data;
	Else
		Address = New UUID;
	EndIf;
	
	DataToStorage = PutToTempStorage(Data, Address);
	
	ClipboardStructure = New Structure;
	ClipboardStructure.Insert("Source", Source);
	ClipboardStructure.Insert("Data", DataToStorage);
	
	SessionParameters.Clipboard = New FixedStructure(ClipboardStructure);
	
EndProcedure

// Gets the tabular section rows that were copied to the clipboard with CopyRowsToClipboard.
//
// Returns:
//  Structure - with the following properties:
//     * Data   - Arbitrary - data retrieved from the internal clipboard.
//                                 For example, ValueTable when calling CopyRowsToClipboard.
//     * Soruce - String       - the object related to the data.
//                                 Undefined if it was not specified in the data copied to the clipboard.
//
Function RowsFromClipboard() Export
	
	Result = New Structure;
	Result.Insert("Source", Undefined);
	Result.Insert("Data", Undefined);
	
	If EmptyClipboard() Then
		Return Result;
	EndIf;
	
	CurrentClipboard = SessionParameters.Clipboard;
	Result.Source = CurrentClipboard.Source;
	Result.Data = GetFromTempStorage(CurrentClipboard.Data);
	
	Return Result;
EndFunction

// Checks whether the clipboard has any data saved.
//
// Parameters:
//  Source - String - if this parameter is passed, a check is made to determine whether the internal 
//             clipboard with this key contains data.
//             The default value is Undefined.
// Returns:
//  Boolean - True if empty.
//
Function EmptyClipboard(Source = Undefined) Export
	
	CurrentClipboard = SessionParameters.Clipboard;
	SourceIdentical = True;
	If Source <> Undefined Then
		SourceIdentical = (Source = CurrentClipboard.Source);
	EndIf;
	Return (Not SourceIdentical Or Not ValueIsFilled(CurrentClipboard.Data));
	
EndFunction

#EndRegion

#Region ExternalCodeSecureExecution

////////////////////////////////////////////////////////////////////////////////
// Supporting security profiles in a configuration where connecting external modules with the 
// disabled safe mode is not allowed.
//

// Executes the export procedure by the name with the configuration privilege level.
// To enable the security profile for calling the Execute() operator, the safe mode with the 
// security profile of the infobase is used (if no other safe mode was set in stack previously).
// 
//
// Parameters:
//  MethodName  - String - the name of the export procedure in format:
//                       <object name>.<procedure name>, where <object name> is a common module or 
//                       object manager module.
//  Parameters  - Array - the parameters are passed to <ExportProcedureName>
//                        according to the array item order.
// 
// Example:
//  Parameters = New Array();
//  Parameters.Add("1");
//  Common.ExecuteConfigurationMethod("MyCommonModule.MyProcedure", Parameters);
//
Procedure ExecuteConfigurationMethod(Val MethodName, Val Parameters = Undefined) Export
	
	CheckConfigurationProcedureName(MethodName);
	
	If SubsystemExists("StandardSubsystems.SecurityProfiles") Then
		ModuleSafeModeManager = CommonModule("SafeModeManager");
		If ModuleSafeModeManager.UseSecurityProfiles()
			AND Not ModuleSafeModeManager.SafeModeSet() Then
			
			InfobaseProfile = ModuleSafeModeManager.InfobaseSecurityProfile();
			If ValueIsFilled(InfobaseProfile) Then
				
				SetSafeMode(InfobaseProfile);
				If SafeMode() = True Then
					SetSafeMode(False);
				EndIf;
				
			EndIf;
			
		EndIf;
	EndIf;
	
	ParametersString = "";
	If Parameters <> Undefined AND Parameters.Count() > 0 Then
		For Index = 0 To Parameters.UBound() Do 
			ParametersString = ParametersString + "Parameters[" + Index + "],";
		EndDo;
		ParametersString = Mid(ParametersString, 1, StrLen(ParametersString) - 1);
	EndIf;
	
	Execute MethodName + "(" + ParametersString + ")";
	
EndProcedure

// Executes the export procedure of the 1C:Enterprise language object by name.
// To enable the security profile for calling the Execute() operator, the safe mode with the 
// security profile of the infobase is used (if no other safe mode was set in stack previously).
// 
//
// Parameters:
//  Object - Arbitrary - 1C:Enterprise language object that contains the methods (for example, DataProcessorObject).
//  MethodName - String       - the name of export procedure of the data processor object module.
//  Parameters - Array       - the parameters are passed to <ProcedureName>
//                             according to the array item order.
//
Procedure ExecuteObjectMethod(Val Object, Val MethodName, Val Parameters = Undefined) Export
	
	// Method name validation.
	Try
		Test = New Structure(MethodName, MethodName);
		If Test = Undefined Then 
			Raise NStr("ru = 'Синтетический тест'; en = 'Synthetic testing'; pl = 'Test syntetyczny';de = 'Synthetischer Test';ro = 'Test sintetic';tr = 'Sentetik metin'; es_ES = 'Test sintético'");
		EndIf;
	Except
		Raise StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru='Некорректное значение параметра ИмяМетода (%1) в ОбщегоНазначения.ВыполнитьМетодОбъекта'; en = 'Invalid value of the MethodName parameter (%1), Common.ExecuteObjectMethod.'; pl = 'Nieprawidłowa wartość parametru MethodName (%1) do Common.ExecuteObjectMethod';de = 'Falscher Parameterwert MethodName (%1) in Common.ExecuteObjectMethod';ro = 'Valoare incorectă a parametrului MethodName (%1) în Common.ExecuteObjectMethod';tr = 'Common.ExecuteObjectMethod ''de MethodName parametresinin geçersiz değeri (%1)'; es_ES = 'Valor inválido del parámetro MethodName (%1) en Common.ExecuteObjectMethod.'"), MethodName);
	EndTry;
	
	If SubsystemExists("StandardSubsystems.SecurityProfiles") Then
		ModuleSafeModeManager = CommonModule("SafeModeManager");
		If ModuleSafeModeManager.UseSecurityProfiles()
			AND Not ModuleSafeModeManager.SafeModeSet() Then
			
			ModuleSafeModeManager = CommonModule("SafeModeManager");
			InfobaseProfile = ModuleSafeModeManager.InfobaseSecurityProfile();
			
			If ValueIsFilled(InfobaseProfile) Then
				
				SetSafeMode(InfobaseProfile);
				If SafeMode() = True Then
					SetSafeMode(False);
				EndIf;
				
			EndIf;
			
		EndIf;
	EndIf;
	
	ParametersString = "";
	If Parameters <> Undefined AND Parameters.Count() > 0 Then
		For Index = 0 To Parameters.UBound() Do 
			ParametersString = ParametersString + "Parameters[" + Index + "],";
		EndDo;
		ParametersString = Mid(ParametersString, 1, StrLen(ParametersString) - 1);
	EndIf;
	
	Execute "Object." + MethodName + "(" + ParametersString + ")";
	
EndProcedure

// Executes an arbitrary algorithm in the 1C:Enterprise script, setting the safe mode of script 
// execution and the safe mode of data separation for all separators of the configuration.
// 
//
// Parameters:
//  Algorithm  - String - the algorithm in the 1C:Enterprise language.
//   Parameters - Arbitrary - the algorithm context.
//    To address the context in the algorithm text, use "Parameters" name.
//    For example, expression "Parameters.Value1 = Parameters.Value2" addresses values
//    Value1 and Value2 that were passed to Parameters as properties.
//
// Example:
//
//  Parameters = New Structure;
//  Parameters.Insert("Value1", 1);
//    Parameters.Insert("Value2", 10);
//  Common.ExecuteInSafeMode("Parameters.Value1 = Parameters.Value2", Parameters);
//
Procedure ExecuteInSafeMode(Val Algorithm, Val Parameters = Undefined) Export
	
	SetSafeMode(True);
	
	If SubsystemExists("StandardSubsystems.SaaS") Then
		ModuleSaaS = CommonModule("SaaS");
		SeparatorArray = ModuleSaaS.ConfigurationSeparators();
	Else
		SeparatorArray = New Array;
	EndIf;
	
	For Each SeparatorName In SeparatorArray Do
		
		SetDataSeparationSafeMode(SeparatorName, True);
		
	EndDo;
	
	Execute Algorithm;
	
EndProcedure

// Evaluates the passed expression, setting the safe mode of script execution and the safe mode of 
// data separation for all separators of the configuration.
//
// Parameters:
//  Expression - String - an expression in the 1C:Enterprise language.
//  Parameters - Arbitrary - the context required to calculate the expression.
//    To address the context in the expression text, use "Parameters" name.
//    For example, expression "Parameters.Value1 = Parameters.Value2" addresses values
//    Value1 and Value2 that were passed to Parameters as properties.
//
// Returns:
//   Arbitrary - the result of the expression calculation.
//
// Example:
//
//  // Example 1
//  Parameters = New Structure;
//  Parameters.Insert("Value1", 1);
//    Parameters.Insert("Value2", 10);
//  Result = Common.ExecuteInSafeMode("Parameters.Value1 = Parameters.Value2", Parameters);
//
//  // Example 1
//  Result = Common.ExecuteInSafeMode("StandardSubsystemsServer.LibraryVersion()");
//
Function CalculateInSafeMode(Val Expression, Val Parameters = Undefined) Export
	
	SetSafeMode(True);
	
	If SubsystemExists("StandardSubsystems.SaaS") Then
		ModuleSaaS = CommonModule("SaaS");
		SeparatorArray = ModuleSaaS.ConfigurationSeparators();
	Else
		SeparatorArray = New Array;
	EndIf;
	
	For Each SeparatorName In SeparatorArray Do
		
		SetDataSeparationSafeMode(SeparatorName, True);
		
	EndDo;
	
	Return Eval(Expression);
	
EndFunction

// Returns the description of the unsafe action protection feature with disabled warnings.
// The function will not raise a compiler error if security warnings are not implemented on platform 
// level.
//
// Returns:
//  UnsafeOperationProtectionDescription - with the UnsafeOperationWarnings property value set to False.
//
Function ProtectionWithoutWarningsDetails() Export
	
	ProtectionDetails = New UnsafeOperationProtectionDescription;
	ProtectionDetails.UnsafeOperationWarnings = False;
	
	Return ProtectionDetails;
	
EndFunction

#EndRegion

#Region Queries

// Prepares a string for further use as a query search template.
// All special symbols are escaped.
//
// Parameters:
//  SearchString - String - an arbitrary string.
//
// Returns:
//  String - string prepared for the purpose of searching the query for data.
//
Function GenerateSearchQueryString(Val SearchString) Export
	
	ResultingSearchString = SearchString;
	ResultingSearchString = StrReplace(ResultingSearchString, "~", "~~");
	ResultingSearchString = StrReplace(ResultingSearchString, "%", "~%");
	ResultingSearchString = StrReplace(ResultingSearchString, "_", "~_");
	ResultingSearchString = StrReplace(ResultingSearchString, "[", "~[");
	ResultingSearchString = StrReplace(ResultingSearchString, "-", "~-");
	
	Return ResultingSearchString;
	
EndFunction

// Returns a query text fragment that is used as a separator between queries.
//
// Returns:
//  String - query separator.
//
Function QueryBatchSeparator() Export
	
	Return "
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|";
		
EndFunction

#EndRegion

#Region Miscellaneous

// Performs actions before continuing to execute the scheduled job handler.
//
// For example, checks whether a scheduled job handler can be executed.
// If the administrator has not disabled the execution of scheduled jobs before an infobase update 
// is completed, the handler execution must be stopped.
//
// Parameters:
//  ScheduledJob - MetadataObject.ScheduledJob - the scheduled job the method was called from.
//     Required to be passed for checking availability by functional options.
//    
//
Procedure OnStartExecuteScheduledJob(ScheduledJob = Undefined) Export
	
	SetPrivilegedMode(True);
	Catalogs.ExtensionsVersions.RegisterExtensionsVersionUsage();
	SetPrivilegedMode(False);
	
	If InformationRegisters.ApplicationParameters.UpdateRequired() Then
		Raise
			NStr("ru = 'Вход в программу временно невозможен в связи с обновлением на новую версию.
			           |Рекомендуется запрещать выполнение регламентных заданий на время обновления.'; 
			           |en = 'The application is temporarily unavailable due to version update.
			           |It is recommended that you prohibit execution of scheduled jobs for the duration of the update.'; 
			           |pl = 'Wejście do aplikacji jest tymczasowo niemożliwe z powodu aktualizacji do nowej wersji.
			           |Zaleca się, zakaz wykonywania zaplanowanych zadań podczas aktualizacji.';
			           |de = 'Der Zugang zur Anwendung ist aufgrund der Aktualisierung der neuen Version vorübergehend nicht möglich. 
			           |Es wird empfohlen, die Ausführung der geplanten Jobs während des Updates zu verbieten.';
			           |ro = 'Intrarea în aplicație este temporar imposibilă din cauza actualizării cu versiunea nouă.
			           |Este recomandat să interziceți executarea sarcinilor reglementare în timpul actualizării.';
			           |tr = 'Yeni sürümde yapılan güncellemeden dolayı uygulamaya giriş geçici olarak imkansızdır. 
			           |Güncelleme sırasında planlanan işlerin yürütülmesinin yasaklanması tavsiye edilir.'; 
			           |es_ES = 'Entrada en la aplicación resulta temporalmente imposible debido a la actualización para la nueva versión.
			           |Se recomienda prohibir la ejecución de las tareas programadas durante la actualización.'");
	EndIf;
	
	SetPrivilegedMode(True);
	
	If Not DataSeparationEnabled()
	   AND ExchangePlans.MasterNode() = Undefined
	   AND ValueIsFilled(Constants.MasterNode.Get()) Then
		
		Raise
			NStr("ru = 'Вход в программу временно невозможен до восстановления связи с главным узлом.
			           |Рекомендуется запрещать выполнение регламентных заданий на время восстановления.'; 
			           |en = 'The application is temporarily unavailable until connection to the master node is restored.
			           |It is recommended that you prohibit execution of scheduled jobs until the connection is restored.'; 
			           |pl = 'Zalogowanie się do aplikacji jest tymczasowo niedostępne przed przywróceniem połączenia z głównym węzłem.
			           |Zaleca się zakaz wykonywania zaplanowanych zadań w czasie przywracania.';
			           |de = 'Die Anmeldung bei der Anwendung ist vorübergehend vor der Wiederherstellung der Verbindung mit dem Hauptknoten nicht möglich. Es wird empfohlen, 
			           |die Ausführung der geplanten Jobs bei der Wiederherstellung zu verbieten.';
			           |ro = 'Intrarea în aplicație este temporar imposibilă până la restabilirea conexiunii cu nodul principal.
			           |Este recomandat să interziceți executarea sarcinilor reglementare în timpul restaurării.';
			           |tr = 'Uygulamaya giriş, ana ünite ile bağlantının geri yüklenmesinden önce geçici olarak kullanılamıyor. 
			           | Yenilenme zamanında planlanan işlerin yapılmasının yasaklanması tavsiye edilir.'; 
			           |es_ES = 'Inicio de sesión en la aplicación no está temporalmente disponible antes de restaurar la conexión con el nodo principal.
			           |Se recomienda prohibir la ejecución de las tareas programadas para el tiempo de la restauración.'");
	EndIf;
	
	If ScheduledJob <> Undefined
		AND SubsystemExists("StandardSubsystems.ScheduledJobs") Then
		
		ModuleWorkLockWithExternalResources = CommonModule("ExternalResourcesOperationsLock");
		ModuleWorkLockWithExternalResources.OnStartExecuteScheduledJob(ScheduledJob);
		
		ModuleScheduledJobsInternal = CommonModule("ScheduledJobsInternal");
		Available = ModuleScheduledJobsInternal.ScheduledJobAvailableByFunctionalOptions(ScheduledJob);
		
		If Not Available Then
			Jobs = ScheduledJobsServer.FindJobs(New Structure("Metadata", ScheduledJob));
			For Each Job In Jobs Do
				ScheduledJobsServer.ChangeJob(Job.UUID,
					New Structure("Use", False));
			EndDo;
			Raise
				NStr("ru = 'Регламентное задание недоступно по функциональным опциям или
				           |не поддерживает работу в текущем режиме работы программы.
				           |Выполнение прервано. Задание отключено.'; 
				           |en = 'The scheduled job is unavailable due to functional option values
				           |or is not supported in the current application run mode.
				           |The scheduled job execution is canceled and the job is disabled.'; 
				           |pl = 'Zadanie reglamentowane jest niedostępne wg opcji funkcjonalnych lub
				           |nie obsługuje pracę w bieżącym trybie pracy programu.
				           |Wykonanie przerwano. Zadanie jest odłączone.';
				           |de = 'Die Routineaufgabe ist je nach funktionalen Optionen nicht verfügbar oder
				           |unterstützt keine Arbeit im aktuellen Modus des Programms.
				           |Ausführung abgebrochen. Der Job ist deaktiviert.';
				           |ro = 'Sarcina reglementară este inaccesibilă conform opțiunilor funcționale sau
				           |nu susține lucrul în regimul de lucru curent al aplicației.
				           |Executarea este întreruptă. Sarcina este dezactivată.';
				           |tr = 'Rutin görev işlevsel seçenekler için kullanılamaz veya 
				           |programın geçerli çalışma modunda çalışmasını desteklemez. 
				           |Yürütme kesildi. Görev devre dışı.'; 
				           |es_ES = 'La tarea programada no está disponible por opciones funcionales o
				           |no admite el uso en el modo actual del programa.
				           |La ejecución ha sido interrumpida. Tarea desactivada.'");
		EndIf;
	EndIf;
	
EndProcedure

// Resets session parameters to Not set.
// 
// Parameters:
//  ParametersToClear - String - names of comma-separated session parameters to be cleared.
//  Exceptions - String - names of comma-separated session parameters that are not supposed to be cleared.
//
Procedure ClearSessionParameters(ParametersToClear = "", Exceptions = "") Export
	
	ExceptionsArray = StrSplit(Exceptions, ",");
	ArrayOfParametersToClear = StrSplit(ParametersToClear, ",", False);
	
	If ArrayOfParametersToClear.Count() = 0 Then
		For Each SessionParameter In Metadata.SessionParameters Do
			If ExceptionsArray.Find(SessionParameter.Name) = Undefined Then
				ArrayOfParametersToClear.Add(SessionParameter.Name);
			EndIf;
		EndDo;
	EndIf;
	
	Index = ArrayOfParametersToClear.Find("ClientParametersAtServer");
	If Index <> Undefined Then
		ArrayOfParametersToClear.Delete(Index);
	EndIf;
	
	Index = ArrayOfParametersToClear.Find("InstalledExtensions");
	If Index <> Undefined Then
		ArrayOfParametersToClear.Delete(Index);
	EndIf;
	
	SessionParameters.Clear(ArrayOfParametersToClear);
	
EndProcedure

// Checks whether the passed spreadsheet document fits a single page in the print layout.
//
// Parameters:
//  SpreadsheetDoc - SpreadsheetDocument - spreadsheet document.
//  AreasToOutput - Array, SpreadsheetDocument - an array of tables, or a spreadsheet document.
//  ResultOnError - Boolean - a result to return when an error occurs.
//
// Returns:
//   Boolean - flag indicating whether the passed documents fit the page.
//
Function SpreadsheetDocumentFitsPage(SpreadsheetDocument, AreasToOutput, ResultOnError = True) Export

	Try
		Return SpreadsheetDocument.CheckPut(AreasToOutput);
	Except
		Return ResultOnError;
	EndTry;

EndFunction 

// Saves personal user settings related to the Core subsystem.
// To receive settings, use the following functions:
//  - CommonClient.SuggestFileSystemExtensionInstallation(),
//  - StandardSubsystemsServer.AskConfirmationOnExit().
// 
// Parameters:
//	Setting - Structure - a collection of settings:
//	 * RemindAboutFileSystemExtensionInstallation - Boolean - the flag indicating whether to notify 
//                                                               users on extension installation.
//	 * AskConfirmationOnExit - Boolean - the flag indicating whether to ask confirmation before the user exits the application.
//
Procedure SavePersonalSettings(Settings) Export
	
	If Settings.Property("RemindAboutFileSystemExtensionInstallation") Then
		ClientParametersAtServer = SessionParameters.ClientParametersAtServer;
		If ClientParametersAtServer.Get("IsWebClient") Then
			ClientID = ClientParametersAtServer.Get("ClientID");
			CommonSettingsStorageSave(
				"ApplicationSettings/SuggestFileSystemExtensionInstallation",
				ClientID, Settings.RemindAboutFileSystemExtensionInstallation);
		EndIf;
	EndIf;
	
	If Settings.Property("AskConfirmationOnExit") Then
		CommonSettingsStorageSave("UserCommonSettings",
			"AskConfirmationOnExit",
			Settings.AskConfirmationOnExit);
	EndIf;
	
EndProcedure

// Distributes the amount according to the specified distribution ratios.
// 
//
// See CommonClientServer.DistributeAmountInProportionToCoefficients 
//
// Parameters:
//  AmountToDistribute - Number  - the amount to distribute. If set to 0, returns Undefined.
//                                 If set to a negative value, absolute value is calculated and then its sign is inverted.
//  Coefficients        - Array - distribution coefficients. All coefficients must be positive, or all coefficients must be negative.
//  Accuracy            - Number  - rounding accuracy during distribution. Optional.
//
// Returns:
//  Array - array whose dimension is equal to the number of coefficients, contains amounts according 
//           to the coefficient weights (from the array of coefficients).
//           If distribution cannot be performed (for example, number of coefficients = 0, or some 
//           coefficients are negative, or total coefficient weight = 0), returns Undefined.
//           
//
// Example:
//
//	Coefficients = New Array;
//	Coefficients.Add(1);
//	Coefficients.Add(2);
//	Result = CommonClientServer.DistributeAmountInProportionToCoefficients(1, Coefficients);
//	// Result = [0.33, 0.67]
//
Function DistributeAmountInProportionToCoefficients(
		Val AmountToDistribute, Coefficients, Val Accuracy = 2) Export
	
	Return CommonClientServer.DistributeAmountInProportionToCoefficients(
		AmountToDistribute, Coefficients, Accuracy);
	
EndFunction

// Fills an attribute for a form of the FormDataTree type.
//
// Parameters:
//  TreeItemCollection - FormDataTree - required attribute.
//  ValueTree - ValueTree - data to fill.
// 
Procedure FillFormDataTreeItemCollection(TreeItemsCollection, ValuesTree) Export
	
	For Each Row In ValuesTree.Rows Do
		
		TreeItem = TreeItemsCollection.Add();
		
		FillPropertyValues(TreeItem, Row);
		
		If Row.Rows.Count() > 0 Then
			
			FillFormDataTreeItemCollection(TreeItem.GetItems(), Row);
			
		EndIf;
		
	EndDo;
	
EndProcedure

// Connects an add-in based on Native API and COM technologies.
// The add-inn must be stored in the configuration template in as a ZIP file.
//
// Parameters:
//  ID - String - the add-in identification code.
//  FullTemplateName - String - full name of the configuration template that stores the ZIP file.
//
// Returns:
//  AddIn, Undefined - an instance of the add-in or Undefined if failed to create one.
//
// Example:
//
//  AttachableModule = Common.AttachAddInFromTemplate(
//      "CNameDecl",
//      "CommonTemplate.FullNameDeclensionComponent");
//
//  If AttachableModule <> Undefined Then
//            // AttachableModule contains the instance of the attached add-in.
//  EndIf.
//
//  AttachableModule = Undefined;
//
Function AttachAddInFromTemplate(ID, FullTemplateName) Export

	AttachableModule = Undefined;
	
	If Not TemplateExists(FullTemplateName) Then 
		Raise StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Не удалось подключить внешнюю компоненту ""%1"" на сервере
			           |из %2
			           |по причине:
			           |Подключение на сервере не из макета запрещено'; 
			           |en = 'Cannot attach add-in ""%1"" on the server
			           |from %2.
			           |Reason:
			           |On the server, add-ins can only be attached from templates.'; 
			           |pl = 'Podłączenie do komponentu zewnętrznego nie powiodło się ""%1"" na serwerze
			           |z %2
			           |z powodu:
			           |Podłączenie na serwerze nie z makiety jest zabronione';
			           |de = 'Die Verbindung der externen Komponente ""%1"" auf dem Server
			           |konnte aus%2
			           |folgendem Grund nicht hergestellt werden:
			           |Die Verbindung auf dem Server ist vom Layout aus nicht erlaubt';
			           |ro = 'Eșec la conectarea componentei externe ""%1"" pe serverul
			           |din %2
			           |din motivul:
			           |Conectarea pe server nu din machetă este interzisă';
			           |tr = 'Harici bir bileşeni ""%1"" 
			           |sunucuya 
			           |bağlanamıyor çünkü: %2maketten olmayan sunucu bağlantısı yasak
			           |'; 
			           |es_ES = 'No se ha podido conectar un componente externo ""%1"" en el servidor 
			           |de %2
			           |a causa de:
			           |Conexión en el servidor no de la plantilla está prohibida'"),
			ID,
			FullTemplateName);
	EndIf;
	
	Location = FullTemplateName;
	SymbolicName = ID + "SymbolicName";
	
	If AttachAddIn(Location, SymbolicName) Then
		
		Try
			AttachableModule = New("AddIn." + SymbolicName + "." + ID);
			If AttachableModule = Undefined Then 
				Raise NStr("ru = 'Оператор Новый вернул Неопределено'; en = 'The New operator returned Undefined.'; pl = 'Operator Nowy zwrócił Nieokreślone';de = 'Operator Neu zurückgegeben Undefiniert';ro = 'Operatorul Nou a returnat Nedefinit';tr = 'Operatör Yeni iade etti Belirsiz'; es_ES = 'Operador Nuevo ha devuelto No determinado'");
			EndIf;
		Except
			AttachableModule = Undefined;
			ErrorText = BriefErrorDescription(ErrorInfo());
		EndTry;
		
		If AttachableModule = Undefined Then
			
			ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'Не удалось создать объект внешней компоненты ""%1"", подключенной на сервере
				           |из макета ""%2"",
				           |по причине:
				           |%3'; 
				           |en = 'Cannot create an object for add-in ""%1"" that was attached on the server
				           |from template ""%2.""
				           |Reason:
				           |%3'; 
				           |pl = 'Nie udało się utworzyć  obiekt komponentów zewnętrznych ""%1"", podłączonych na serwerze
				           |z makiety ""%2"",
				           |z powodu:
				           |%3';
				           |de = 'Ein Objekt der externen Komponente ""%1"", das aus dem Layout ""%2"" mit dem Server
				           | verbunden ist, konnte aus 
				           |diesem Grund nicht erstellt werden:
				           |%3';
				           |ro = 'Eșec la crearea obiectului componentei externe ""%1"" conectate pe serverul
				           |din macheta ""%2"",
				           |din motivul:
				           |%3';
				           |tr = '%1 sunucuda bağlanan "
" harici bileşenin nesnesi ""%2"" maketten oluşturulamadı, 
				           | nedeni: 
				           |%3'; 
				           |es_ES = 'No se ha podido crear un objeto del componente externo ""%1"" conectado en el servidor
				           |de la plantilla ""%2""
				           |a causa de:
				           |%3'"),
				ID,
				Location,
				ErrorText);
			
			WriteLogEvent(
				NStr("ru = 'Подключение внешней компоненты на сервере'; en = 'Attaching add-in on the server'; pl = 'Podłączenie komponentów zewnętrznych na serwerze';de = 'Verbinden einer externen Komponente mit dem Server';ro = 'Conectarea componentei externe pe server';tr = 'Harici bileşenin sunucuda bağlantı'; es_ES = 'Conexión del componente externo en el servidor'",
					DefaultLanguageCode()),
				EventLogLevel.Error,,,
				ErrorText);
			
		EndIf;
		
	Else
		
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Не удалось подключить внешнюю компоненту ""%1"" на сервере
			           |из макета ""%2""
			           |по причине:
			           |Метод ПодключитьВнешнююКомпоненту вернул Ложь.'; 
			           |en = 'Cannot attach add-in ""%1"" on the server
			           |from template ""%2.""
			           |Reason:
			           |Method AttachAddInSSL returned False.'; 
			           |pl = 'Podłączenie do komponentu zewnętrznego nie powiodło się ""%1"" na serwerze
			           |z makiety ""%2""
			           |z powodu:
			           |Metoda Метод AttachAddInSSL wrócił Falsz.';
			           |de = 'Die externe Komponente ""%1"" auf dem Server 
			           | aus dem Layout""%2""
			           | konnte nicht verbunden werden, da:
			           |die AttachAddInSSL hat False zurückgegeben.';
			           |ro = 'Eșec la conectarea componentei externe ""%1"" pe serverul
			           |din macheta ""%2"",
			           |din motivul:
			           |Metoda AttachAddInSSL a returnat Ложь.';
			           |tr = '
			           | sunucunun ""%1"" harici bileşeni ""%2""
			           | nedenle bağlanamadı: 
			           |Yöntem AttachAddInSSL iade etti Yanlış.'; 
			           |es_ES = 'No se ha podido crear un objeto del componente externo ""%1"" conectado en el servidor
			           |de la plantilla ""%2""
			           |a causa de:
			           |Method AttachAddInSSL ha devuelto Falso.'"),
			ID,
			Location);
		
		WriteLogEvent(
			NStr("ru = 'Подключение внешней компоненты на сервере'; en = 'Attaching add-in on the server'; pl = 'Podłączenie komponentów zewnętrznych na serwerze';de = 'Verbinden einer externen Komponente mit dem Server';ro = 'Conectarea componentei externe pe server';tr = 'Harici bileşenin sunucuda bağlantı'; es_ES = 'Conexión del componente externo en el servidor'",
				DefaultLanguageCode()),
			EventLogLevel.Error,,,
			ErrorText);
		
	EndIf;
	
	Return AttachableModule;
	
EndFunction

#EndRegion

#Region ObsoleteProceduresAndFunctions

// Obsolete. Use CommonClientServer.SupplementArray with UniqueValuesOnly set to True.
// 
//
// Populates the destination array with unique value elements from the source array.
// If the destination array contains an element with the same value, the element is not added.
//
// Parameters:
//  DestinationArray - Array - an array to be populated with unique values.
//  SourceArray - Array - the array of elements that are sent to the destination array.
// 
Procedure FillArrayWithUniqueValues(DestinationArray, SourceArray) Export
	
	CommonClientServer.SupplementArray(DestinationArray, SourceArray, True);
	
EndProcedure

// Obsolete. Use ObjectPropertyDetailsTable instead.
// Returns a value table with the required property information for all attributes of a metadata object.
// Gets property values of standard and custom attributes (custom attributes are the attributes created in Designer mode).
//
// Parameters:
//  MetadataObject  - MetadataObject - an object whose attribute property values are sought.
//                      Example: Metadata.Document.Invoice
//  Properties - String - comma-separated attribute properties whose values to be retrieved.
//                      Example: "Name, Type, Synonym, Tooltip".
//
// Returns:
//  ValueTable - required property information for all attributes of the metadata object.
//
Function GetObjectPropertyInfoTable(MetadataObject, Properties) Export
	
	Return ObjectPropertiesDetails(MetadataObject, Properties);
	
EndFunction

// Obsolete. Use RefSearchExceptions instead.
// Returns links search exceptions on object delete.
//
// Returns:
//   Map - reference search exceptions by metadata objects.
//       * Key - MetadataObject - the metadata object to apply exceptions to.
//       * Value - String, Array - descriptions of excluded attributes.
//           If "*", all the metadata object attributes are excluded.
//           If a string array, contains the relative names of the excluded attributes.
//
Function GetOverallRefSearchExceptionList() Export
	
	Return RefSearchExclusions();
	
EndFunction

// Obsolete. Use CreateWSProxy instead.
//
// Returns the WSProxy object created with the passed parameters.
//
// Parameters:
//  WSDLAddress - String - the wsdl location.
//  NamespaceURI - String - URI of the web service namespace.
//  ServiceName - String - the service name.
//  EndpointName - String - if not specified, it is generated from template <ServiceName>Soap.
//  Username - String - the username used to sign in to a server.
//  Password - String - the sign in user password.
//  Timeout - Number - the timeout for operations executed over the proxy.
//  ProbingCallRequired - Boolean - (optional) check service availability (the web service must 
//                                     support this command).
//
// Returns:
//  WSProxy - WSProxy object.
//
Function WSProxy(Val WSDLAddress,
	Val NamespaceURI,
	Val ServiceName,
	Val EndpointName = "",
	Val Username,
	Val Password,
	Val Timeout = 0,
	Val ProbingCallRequired = False) Export
	
	ConnectionParameters = WSProxyConnectionParameters();
	ConnectionParameters.WSDLAddress = WSDLAddress;
	ConnectionParameters.NamespaceURI = NamespaceURI;
	ConnectionParameters.ServiceName = ServiceName;
	ConnectionParameters.EndpointName = EndpointName;
	ConnectionParameters.UserName = Username;
	ConnectionParameters.Password = Password;
	ConnectionParameters.Timeout = Timeout;
	
	Return CreateWSProxy(ConnectionParameters);
	
EndFunction

// Obsolete. Use ObjectsPresentationsDeclension.Decline instead.
//
// The function declines the passed phrase.
// Only for Windows.
//
// Parameters:
//  FullName   - String - a name, middle name, and last name in the nominative case to be declined.
//                   
//  Case - Number - the case the full name to be declined for:
//                   1 - Nominative
//                   2 - Genitive
//                   3 - Dative
//                   4 - Accusative
//                   5 - Instrumental
//                   6 - Prepositional
//  Result - String - the parameter contains the result of the declination.
//                       If the full name cannot be declined with the function's algorithm, the full name is returned.
//  Gender - Number - a person's gender: 1 - male, 2 - female.
//
// Returns:
//   Boolean - True if the full name is declined.
//
Function Decline(Val FullName, Case, Result, Gender = Undefined) Export
	
	If SubsystemExists("StandardSubsystems.ObjectPresentationDeclension") Then
		ModuleObjectsPresentationsDeclension = CommonModule("ObjectPresentationDeclension");
		
		Result = ModuleObjectsPresentationsDeclension.DeclineFullName(FullName, Case, , Gender);
		If ValueIsFilled(Result) Then
			Return True;
		Else
			Result = FullName;
			Return False;
		EndIf; 
			
	EndIf;
	
	Raise NStr("ru = 'Для вызова ОбщегоНазначения.Просклонять необходима подсистема «Склонение представлений объектов».'; en = 'A Common.Decline method call requires the ""Object presentation declension"" subsystem.'; pl = 'Dla wywołania Common.Decline niezbędny jest podsystem «Deklinacja prezentacji obiektu».';de = 'Um die Common.Decline aufzurufen. Für die Deklination ist das Subsystem ""Deklination von Objektdarstellungen"" erforderlich.';ro = 'Pentru apelarea Common.Decline este necesar subsistemul ”Declinarea prezentărilor obiectelor”.';tr = 'Common.Decline çağrısı için ""Nesne görünümlerin çekimi"" alt sistemi gereklidir.'; es_ES = 'Una llamada al método Common.Decline requiere el subsistema ""Declinación de presentación de objeto"".'");
	
EndFunction

// Obsolete. Use CommonClientServer.CommentPicture instead.
//
// Gets a picture to display on a page with a comment.
// 
//
// Parameters:
//  Comment - String - the comment text.
//
// Returns:
//  Picture - the picture to display on the comment page.
//
Function GetCommentPicture(Comment) Export
	Return CommonClientServer.CommentPicture(Comment);
EndFunction

// Obsolete. Use the CommonSettingsStorageSave function instead.
Procedure CommonSettingsStorageSaveArrayAndUpdateCachedValues(StructuresArray) Export
	
	CommonSettingsStorageSaveArray(StructuresArray, True);
	
EndProcedure

// Obsolete. Use the CommonSettingsStorageSave function instead.
Procedure CommonSettingsStorageSaveAndUpdateCachedValues(ObjectKey, SettingsKey, Value) Export
	
	CommonSettingsStorageSave(ObjectKey, SettingsKey, Value,,,True);
	
EndProcedure

// Obsolete. Use the SetExclusiveMode(True) platform method.
Procedure LockIB(Val CheckNoOtherSessions = True) Export
	
	If Not DataSeparationEnabled() 
		Or Not SeparatedDataUsageAvailable() Then
		
		If Not ExclusiveMode() Then
			SetExclusiveMode(True);
		EndIf;
	Else
		If SubsystemExists("StandardSubsystems.SaaS") Then
			ModuleSaaS = CommonModule("SaaS");
			ModuleSaaS.LockCurrentDataArea(CheckNoOtherSessions);
		Else
			Raise(NStr("ru = 'Подсистема ""Работа в модели сервиса"" не доступна'; en = 'The ""SaaS"" subsystem is unavailable.'; pl = 'Podsystem ""Operacje SaaS"" nie jest dostępny';de = 'Subsystem ""SaaS-Manager"" ist nicht verfügbar';ro = 'Subsistemul ""Lucrul în modelul serviciului"" nu este disponibil';tr = 'Alt sistem ""SaaS işlemleri"" mevcut değil'; es_ES = 'Subsistema ""Operaciones SaaS"" no está disponible'"));
		EndIf;
	EndIf;
		
EndProcedure

// Obsolete. Use the SetExclusiveMode(False) platform method.
Procedure UnlockIB() Export
	
	If Not DataSeparationEnabled() 
		Or Not SeparatedDataUsageAvailable() Then
		
		If ExclusiveMode() Then
			SetExclusiveMode(False);
		EndIf;
	Else
		If SubsystemExists("StandardSubsystems.SaaS") Then
			ModuleSaaS = CommonModule("SaaS");
			ModuleSaaS.UnlockCurrentDataArea();
		Else
			Raise(NStr("ru = 'Подсистема ""Работа в модели сервиса"" не доступна'; en = 'The ""SaaS"" subsystem is unavailable.'; pl = 'Podsystem ""Operacje SaaS"" nie jest dostępny';de = 'Subsystem ""SaaS-Manager"" ist nicht verfügbar';ro = 'Subsistemul ""Lucrul în modelul serviciului"" nu este disponibil';tr = 'Alt sistem ""SaaS işlemleri"" mevcut değil'; es_ES = 'Subsistema ""Operaciones SaaS"" no está disponible'"));
		EndIf;
	EndIf;
	
EndProcedure

// Obsolete. Please use SaaS.SetSessionSeparation.
Procedure SetSessionSeparation(Val Usage, Val DataArea = Undefined) Export
	
	If SubsystemExists("StandardSubsystems.SaaS") Then
		ModuleSaaS = CommonModule("SaaS");
		ModuleSaaS.SetSessionSeparation(Usage, DataArea);
	EndIf;
	
EndProcedure

// Obsolete. Please use SaaS.SessionSeparatorValue.
Function SessionSeparatorValue() Export
	
	If Not DataSeparationEnabled() Then
		Return 0;
	EndIf;
	
	If SubsystemExists("StandardSubsystems.SaaS") Then
		ModuleSaaS = CommonModule("SaaS");
		Return ModuleSaaS.SessionSeparatorValue();
	EndIf;
	
EndFunction

// Obsolete. Instead, use
//   Common.DataSeparationEnabled()
// And Common.CanUseSeparatedData().
//
Function SessionSeparatorUsage() Export
	
	If Not DataSeparationEnabled() Then
		Return False;
	EndIf;
	
	If SubsystemExists("StandardSubsystems.SaaS") Then
		ModuleSaaS = CommonModule("SaaS");
		Return ModuleSaaS.SessionSeparatorUsage();
	EndIf;
	
EndFunction

// Obsolete. An utility constant (must not be changed unless from the Service Technology library).
Procedure SetInfobaseDataSeparationParameters(Val EnableDataSeparation = False) Export
	
	If EnableDataSeparation Then
		Constants.UseSeparationByDataAreas.Set(True);
	Else
		Constants.UseSeparationByDataAreas.Set(False);
	EndIf;
	
EndProcedure

// Obsolete. Please use SaaS.WriteAuxiliaryData.
Procedure WriteAuxiliaryData(AuxiliaryDataObject) Export
	
	If SubsystemExists("StandardSubsystems.SaaS") Then
		ModuleSaaS = CommonModule("SaaS");
		ModuleSaaS.WriteAuxiliaryData(AuxiliaryDataObject);
	Else
		AuxiliaryDataObject.Write();
	EndIf;
	
EndProcedure

// Obsolete. Please use SaaS.DeleteAuxiliaryData.
Procedure DeleteAuxiliaryData(AuxiliaryDataObject) Export
	
	If SubsystemExists("StandardSubsystems.SaaS") Then
		ModuleSaaS = CommonModule("SaaS");
		ModuleSaaS.DeleteAuxiliaryData(AuxiliaryDataObject);
	Else
		AuxiliaryDataObject.Delete();
	EndIf;
	
EndProcedure

// Obsolete. Please use SaaS.IsSeparatedMetadataObject().
// Returns a flag that shows whether the metadata object is used in common separators.
//
// Parameters:
//  MetadataObject - String, MetadataObject - if the metadata object is a string,  the function 
//                     calls the CommonCached module.
//  Separator - String - the name of the common separator that is checked if it separates the metadata object.
//
// Returns:
//  Boolean - True if the metadata object is used in at least one common separator.
//
Function IsSeparatedMetadataObject(Val MetadataObject, Val Separator = Undefined) Export
	
	If SubsystemExists("StandardSubsystems.SaaS") Then
		ModuleSaaS = CommonModule("SaaS");
		Return ModuleSaaS.IsSeparatedMetadataObject(MetadataObject, Separator);
	Else
		Return True;
	EndIf;
	
EndFunction

// Obsolete. Clones the XDTO object.
//
// Parameters:
//  Factory - XDTOFactory - the factory that created the initial object.
//  Object - XDTODataObject - the object to be cloned.
//
// Returns:
//  XDTOObject - a copy of the original XDTO object.
//
Function CopyXDTO(Val Factory, Val Object) Export
	
	Record = New XMLWriter;
	Record.SetString();
	Factory.WriteXML(Record, Object, , , , XMLTypeAssignment.Explicit);
	
	XMLPresentation = Record.Close();
	
	Read = New XMLReader;
	Read.SetString(XMLPresentation);
	
	Return Factory.ReadXML(Read, Object.Type());
	
EndFunction

// Obsolete. Returns XML presentation of the XDTO type.
//
// Parameters:
//  XDTOType - XDTOObjectType, XDTOValueType - XDTO type whose XML presentation will be retrieved.
//   XML presentation.
//
// Returns:
//  String - XML presentation of the XDTO type.
//
Function XDTOTypePresentation(XDTOType) Export
	
	Return XDTOSerializer.XMLString(New XMLExpandedName(XDTOType.NamespaceURI, XDTOType.Name))
	
EndFunction

// Obsolete. Returns a value for identification of the Information registers type.
//
// Returns:
//  String - a type name.
//
Function InformationRegistersTypeName() Export
	
	Return "InformationRegisters";
	
EndFunction

// Obsolete. Returns a value for identification of the Accumulation registers type.
//
// Returns:
//  String - a type name.
//
Function AccumulationRegistersTypeName() Export
	
	Return "AccumulationRegisters";
	
EndFunction

// Obsolete. Returns a value for identification of the Accounting registers type.
//
// Returns:
//  String - a type name.
//
Function AccountingRegistersTypeName() Export
	
	Return "AccountingRegisters";
	
EndFunction

// Obsolete. Returns a value for identification of the Calculation registers type.
//
// Returns:
//  String - a type name.
//
Function CalculationRegistersTypeName() Export
	
	Return "CalculationRegisters";
	
EndFunction

// Obsolete. Returns a value for identification of the Documents type.
//
// Returns:
//  String - a type name.
//
Function DocumentsTypeName() Export
	
	Return "Documents";
	
EndFunction

// Obsolete. Returns a value for identification of the Catalogs type.
//
// Returns:
//  String - a type name.
//
Function CatalogsTypeName() Export
	
	Return "Catalogs";
	
EndFunction

// Obsolete. Returns a value for identifying the Enumeration data type.
//
// Returns:
//  String - a type name.
//
Function EnumsTypeName() Export
	
	Return "Enums";
	
EndFunction

// Obsolete. Returns a value for identification of the Reports type.
//
// Returns:
//  String - a type name.
//
Function ReportsTypeName() Export
	
	Return "Reports";
	
EndFunction

// Obsolete. Returns a value for identification of the Data processors type.
//
// Returns:
//  String - a type name.
//
Function DataProcessorsTypeName() Export
	
	Return "DataProcessors";
	
EndFunction

// Obsolete. Returns a value for identification of the Exchange plans type.
//
// Returns:
//  String - a type name.
//
Function ExchangePlansTypeName() Export
	
	Return "ExchangePlans";
	
EndFunction

// Obsolete. Returns a value for identification of the Charts of characteristic types type.
//
// Returns:
//  String - a type name.
//
Function ChartsOfCharacteristicTypesTypeName() Export
	
	Return "ChartsOfCharacteristicTypes";
	
EndFunction

// Obsolete. Returns a value for identification of the Business processes type.
//
// Returns:
//  String - "BusinessProcesses".
//
Function BusinessProcessesTypeName() Export
	
	Return "BusinessProcesses";
	
EndFunction

// Obsolete. Returns a value for identification of the Tasks type.
//
// Returns:
//  String - a type name.
//
Function TasksTypeName() Export
	
	Return "Tasks";
	
EndFunction

// Obsolete. Checks whether the metadata object belongs to the Charts of accounts type.
//
// Returns:
//  String - a type name.
//
Function ChartsOfAccountsTypeName() Export
	
	Return "ChartsOfAccounts";
	
EndFunction

// Obsolete. Returns a value for identification of the Charts of calculation types type.
//
// Returns:
//  String - a type name.
//
Function ChartsOfCalculationTypesTypeName() Export
	
	Return "ChartsOfCalculationTypes";
	
EndFunction

// Obsolete. Returns a value for identification of the Constants type.
//
// Returns:
//  String - a type name.
//
Function ConstantsTypeName() Export
	
	Return "Constants";
	
EndFunction

// Obsolete. Returns a value for identification of the Document journals type.
//
// Returns:
//  String - a type name.
//
Function DocumentJournalsTypeName() Export
	
	Return "DocumentJournals";
	
EndFunction

// Obsolete. Returns a value for identification of the Sequences type.
//
// Returns:
//  String - a type name.
//
Function SequencesTypeName() Export
	
	Return "Sequences";
	
EndFunction

// Obsolete. Returns a value for identification of the Scheduled jobs type.
//
// Returns:
//  String - a type name.
//
Function ScheduledJobsTypeName() Export
	
	Return "ScheduledJobs";
	
EndFunction

// Obsolete. Returns a value for identification of the Recalculations type.
//
// Returns:
//  String - a type name.
//
Function RecalculationsTypeName() Export
	
	Return "Recalculations";
	
EndFunction

// Obsolete. Please use FileSystem.CreateTemporaryDirectory
// Creates a temporary directory. If a temporary directory is not required anymore, deleted it with 
// the Common.DeleteTemporaryDirectory procedure.
//
// Parameters:
//   Extension - String - the temporary directory extension that contains the directory designation 
//                         and its subsystem.
//                         It is recommended that you use only Latin characters in this parameter.
//
// Returns:
//   String - the full path to the directory, including path separators.
//
Function CreateTemporaryDirectory(Val Extension = "") Export
	
	Return FileSystem.CreateTemporaryDirectory(Extension);
	
EndFunction

// Obsolete. Please use FileSystem.DeleteTemporaryDirectory
// Deletes the temporary directory and its content if possible.
// If a temporary directory cannot be deleted (for example, if it is busy), the procedure is 
// completed and the warning is added to the event log.
//
// This procedure is for using with the Common.CreateTemporaryDirectory procedure after a temporary 
// directory is not required anymore.
//
// Parameters:
//   PathToDirectory - String - the full path to a temporary directory.
//
Procedure DeleteTemporaryDirectory(Val PathToDirectory) Export
	
	FileSystem.DeleteTemporaryDirectory(PathToDirectory);
	
EndProcedure

// Obsolete. Checks for the platform features that notify users about unsafe actions.
//
// Returns:
//  Boolean - if True, the unsafe action protection feature is on.
//
Function HasUnsafeActionProtection() Export
	
	Return True;
	
EndFunction

// Obsolete. Creates and returns an instance of a report or data processor by the passed full name of a metadata object.
//
// Parameters:
//  FullName - String - full name of a metadata object. Example: "Report.BusinessProcesses".
//
// Returns:
//  ReportObject, DataProcessorObject - an instance of a report or data processor.
// 
Function ObjectByFullName(FullName) Export
	RowsArray = StrSplit(FullName, ".");
	
	If RowsArray.Count() >= 2 Then
		Kind = Upper(RowsArray[0]);
		Name = RowsArray[1];
	Else
		Raise StrReplace(NStr("ru = 'Некорректное полное имя отчета или обработки ""%1"".'; en = 'Invalid full name of a report or data processor: ""%1.""'; pl = 'Nieprawidłowa pełna nazwa raportu lub procesora danych: ""%1.""';de = 'Falscher vollständiger Bericht oder Verarbeitungsname ""%1"".';ro = 'Denumire completă incorectă a raportului sau a procesării ""%1"".';tr = 'Rapor veya işleme tam adı ""%1"" yanlıştır.'; es_ES = 'Nombre completo incorrecto del informe o el procesador de datos ""%1"".'"), "%1", FullName);
	EndIf;
	
	If Kind = "REPORT" Then
		Return Reports[Name].Create();
	ElsIf Kind = "DATAPROCESSOR" Then
		Return DataProcessors[Name].Create();
	Else
		Raise StrReplace(NStr("ru = '""%1"" не является отчетом или обработкой.'; en = '""%1"" is not a report or data processor.'; pl = '""%1"" nie jest sprawozdaniem lub przetwarzaniem.';de = '""%1"" ist kein Bericht oder eine Verarbeitung.';ro = '""%1"" nu este raport sau procesare.';tr = '""%1"" rapor veya veri işlemcisi değildir.'; es_ES = '""%1"" no es un informe o un procesador de datos.'"), "%1", FullName);
	EndIf;
EndFunction

#EndRegion

#EndRegion

#Region Internal

// Exports the query into an XML string, which you can pass to the Query console.
//   To pass the query and all its parameters to the Query console, call the function in the window.
//   «Eval expression»(Shift + F9), copy the resulting XML to the "Query text" field
//   of the query console and run the "Fill from XML" command in the "More" menu.
//   For details, see the Query console help.
//
// Parameters:
//   Query - Query - Query to be exported as an XML string.
//
// Returns:
//   String - an XML-formatted string, which can extracted using the Common.ValueFromXMLString method.
//       The result of extracting is an object of the Structure type with the following fields:
//       * Text     - String - the query text.
//       * Parameters - Structure - the query parameters.
//
Function QueryToXMLString(Query) Export
	Structure = New Structure("Text, Parameters");
	FillPropertyValues(Structure, Query);
	Return ValueToXMLString(Structure);
EndFunction

#EndRegion

#Region Private

#Region InfobaseData

#Region AttributesValues

// Searching for expressions to be checked in metadata object attributes.
// 
// Parameters:
//  MetadataObjectFullName - String - object full name.
//  ExpressionsToCheck - Array - field names or metadata object expressions to check.
// 
// Returns:
//  Structure - Check result.
//  * Error - Boolean - the flag indicating whether an error is found.
//  * ErrorDescription - String - the descriptions of errors that are found.
//
// Example:
//  
// Attributes = New Array;
// Attributes.Add("Number");
// Attributes.Add("Currency.FullDescription");
//
// Result = Common.FindObjectAttirbuteAvailabilityError("Document._DemoSalesOrder", Attributes);
//
// If Result.Error Then
//     CallException Result.ErrorDescription;
// EndIf.
//
Function FindObjectAttirbuteAvailabilityError(FullMetadataObjectName, ExpressionsToCheck)
	
	ObjectMetadata = Metadata.FindByFullName(FullMetadataObjectName);
	
	If ObjectMetadata = Undefined Then 
		Return New Structure("Error, ErrorDescription", True, 
			StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'Ошибка получения метаданных ""%1""'; en = 'Cannot get metadata ""%1""'; pl = 'Błąd pobierania metadanych ""%1""';de = 'Fehler beim Abrufen von Metadaten ""%1""';ro = 'Eroare de obținere a datelor ""%1""';tr = '""%1"" metaveri elde etme hatası'; es_ES = 'Error de recibir los metadatos ""%1""'"), FullMetadataObjectName));
	EndIf;

	// Allowing calls from an external data processor or extension in safe mode.
	// On metadata check, the data on schema source fields availability is not classified.
	SetSafeModeDisabled(True);
	SetPrivilegedMode(True);
	
	Schema = New QuerySchema;
	Package = Schema.QueryBatch.Add(Type("QuerySchemaSelectQuery"));
	Operator = Package.Operators.Get(0);
	
	Source = Operator.Sources.Add(FullMetadataObjectName, "Table");
	ErrorText = "";
	
	For Each CurrentExpression In ExpressionsToCheck Do
		
		If Not QuerySchemaSourceFieldAvailable(Source, CurrentExpression) Then 
			ErrorText = ErrorText + Chars.LF + StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = '- Поле объекта ""%1"" не найдено'; en = '- The ""%1"" object field not found.'; pl = '- Pole obiektu ""%1"" nie znaleziono';de = '- Objektfeld ""%1"" nicht gefunden';ro = '- Câmpul obiectului ""%1"" nu a fost găsit';tr = '- ""%1"" Nesnenin alanı bulunamadı.'; es_ES = '- Campo del objeto ""%1"" no encontrado'"), CurrentExpression);
		EndIf;
		
	EndDo;
		
	Return New Structure("Error, ErrorDescription", Not IsBlankString(ErrorText), ErrorText);
	
EndFunction

// It is used in FindObjectAttirbuteAvailabilityError.
// It checks whether the field of the expression being checked is available in the source of the query schema operator.
//
Function QuerySchemaSourceFieldAvailable(OperatorSource, ExpressToCheck)
	
	FieldNameParts = StrSplit(ExpressToCheck, ".");
	AvailableFields = OperatorSource.Source.AvailableFields;
	
	CurrentFieldNamePart = 0;
	While CurrentFieldNamePart < FieldNameParts.Count() Do 
		
		CurrentField = AvailableFields.Find(FieldNameParts.Get(CurrentFieldNamePart)); 
		
		If CurrentField = Undefined Then 
			Return False;
		EndIf;
		
		// Incrementing the next part of the field name and the relevant field availability list.
		CurrentFieldNamePart = CurrentFieldNamePart + 1;
		AvailableFields = CurrentField.Fields;
		
	EndDo;
	
	Return True;
	
EndFunction

#EndRegion

#Region ReplaceReferences

Function MarkUsageInstances(Val ExecutionParameters, Val Ref, Val DestinationRef, Val SearchTable)
	SetPrivilegedMode(True);
	
	// Setting the order of known objects and checking whether there are unidentified ones.
	Result = New Structure;
	Result.Insert("UsageInstances", SearchTable.FindRows(New Structure("Ref", Ref)));
	Result.Insert("MarkupErrors",     New Array);
	Result.Insert("Success",              True);
	
	For Each UsageInstance In Result.UsageInstances Do
		If UsageInstance.IsInternalData Then
			Continue; // Skipping dependent data.
		EndIf;
		
		Information = TypeInformation(UsageInstance.Metadata, ExecutionParameters);
		If Information.Kind = "CONSTANT" Then
			UsageInstance.ReplacementKey = "Constant";
			UsageInstance.DestinationRef = DestinationRef;
			
		ElsIf Information.Kind = "SEQUENCE" Then
			UsageInstance.ReplacementKey = "Sequence";
			UsageInstance.DestinationRef = DestinationRef;
			
		ElsIf Information.Kind = "INFORMATIONREGISTER" Then
			UsageInstance.ReplacementKey = "InformationRegister";
			UsageInstance.DestinationRef = DestinationRef;
			
		ElsIf Information.Kind = "ACCOUNTINGREGISTER"
			Or Information.Kind = "ACCUMULATIONREGISTER"
			Or Information.Kind = "CALCULATIONREGISTER" Then
			UsageInstance.ReplacementKey = "RecordKey";
			UsageInstance.DestinationRef = DestinationRef;
			
		ElsIf Information.Reference Then
			UsageInstance.ReplacementKey = "Object";
			UsageInstance.DestinationRef = DestinationRef;
			
		Else
			// Unknown object for reference replacement.
			Result.Success = False;
			Text = StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = 'Замена ссылок в ""%1"" не поддерживается.'; en = 'Replacement of references in ""%1"" is not supported.'; pl = 'Wymiana linków w ""%1"" nie jest obsługiwana.';de = 'Das Ersetzen von Links in ""%1"" wird nicht unterstützt.';ro = 'Înlocuirea referințelor în ""%1"" nu este susținută.';tr = '""%1"" ''de referansların değişimi desteklenmiyor.'; es_ES = 'Reemplazo de los enlaces en ""%1"" no se admite.'"), Information.FullName);
			ErrorDescription = New Structure("Object, Text", UsageInstance.Data, Text);
			Result.MarkupErrors.Add(ErrorDescription);
		EndIf;
		
	EndDo;
	
	Return Result;
EndFunction

Procedure ReplaceRefsUsingShortTransactions(Result, Val ExecutionParameters, Val Duplicates, Val SearchTable)
	
	// Main data processor loop.
	RefFilter = New Structure("Ref, ReplacementKey");
	For Each Duplicate In Duplicates Do
		HadErrors = Result.HasErrors;
		Result.HasErrors = False;
		
		RefFilter.Ref = Duplicate;
		
		RefFilter.ReplacementKey = "Constant";
		UsageInstances = SearchTable.FindRows(RefFilter);
		For Each UsageInstance In UsageInstances Do
			ReplaceInConstant(Result, UsageInstance, ExecutionParameters, True);
		EndDo;
		
		RefFilter.ReplacementKey = "Object";
		UsageInstances = SearchTable.FindRows(RefFilter);
		For Each UsageInstance In UsageInstances Do
			ReplaceInObject(Result, UsageInstance, ExecutionParameters, True);
		EndDo;
		
		RefFilter.ReplacementKey = "RecordKey";
		UsageInstances = SearchTable.FindRows(RefFilter);
		For Each UsageInstance In UsageInstances Do
			ReplaceInSet(Result, UsageInstance, ExecutionParameters, True);
		EndDo;
		
		RefFilter.ReplacementKey = "Sequence";
		UsageInstances = SearchTable.FindRows(RefFilter);
		For Each UsageInstance In UsageInstances Do
			ReplaceInSet(Result, UsageInstance, ExecutionParameters, True);
		EndDo;
		
		RefFilter.ReplacementKey = "InformationRegister";
		UsageInstances = SearchTable.FindRows(RefFilter);
		For Each UsageInstance In UsageInstances Do
			ReplaceInInformationRegister(Result, UsageInstance, ExecutionParameters, True);
		EndDo;
		
		If Not Result.HasErrors Then
			ExecutionParameters.SuccessfulReplacements.Insert(Duplicate, ExecutionParameters.ReplacementPairs[Duplicate]);
		EndIf;
		Result.HasErrors = Result.HasErrors Or HadErrors;
		
	EndDo;
	
	// Final procedures.
	If ExecutionParameters.DeleteDirectly Then
		DeleteRefsNotExclusive(Result, Duplicates, ExecutionParameters, True);
		
	ElsIf ExecutionParameters.MarkForDeletion Then
		DeleteRefsNotExclusive(Result, Duplicates, ExecutionParameters, False);
		
	Else
		// Searching for new items.
		RepeatSearchTable = UsageInstances(Duplicates);
		AddModifiedObjectReplacementResults(Result, RepeatSearchTable);
	EndIf;
	
EndProcedure

Procedure ReplaceRefUsingSingleTransaction(Result, Val Duplicate, Val ExecutionParameters, Val SearchTable)
	SetPrivilegedMode(True);
	
	BeginTransaction();
	Try
		// 1. Locking all usage instances.
		ActionState = "LockError";
		Lock = New DataLock;
		
		UsageInstances = SearchTable.FindRows(New Structure("Ref", Duplicate));
		LockUsageInstances(ExecutionParameters, Lock, UsageInstances);
		Lock.Lock();
		ActionState = "";

		SetPrivilegedMode(False);
		
		// 2. Replacing everywhere till the first errors.
		Result.HasErrors = False;
		
		For Each UsageInstance In UsageInstances Do
			
			If UsageInstance.ReplacementKey = "Constant" Then
				ReplaceInConstant(Result, UsageInstance, ExecutionParameters, False);
			ElsIf UsageInstance.ReplacementKey = "Object" Then
				ReplaceInObject(Result, UsageInstance, ExecutionParameters, False);
			ElsIf UsageInstance.ReplacementKey = "Sequence" Then
				ReplaceInSet(Result, UsageInstance, ExecutionParameters, False);
			ElsIf UsageInstance.ReplacementKey = "RecordKey" Then
				ReplaceInSet(Result, UsageInstance, ExecutionParameters, False);
			ElsIf UsageInstance.ReplacementKey = "InformationRegister" Then
				ReplaceInInformationRegister(Result, UsageInstance, ExecutionParameters, False);
			EndIf;
			
			If Result.HasErrors Then
				RollbackTransaction();
				Return;
			EndIf;
			
		EndDo;
		
		// 3. Delete.
		ReplacementsToProcess = New Array;
		ReplacementsToProcess.Add(Duplicate);
		
		If ExecutionParameters.DeleteDirectly Then
			DeleteRefsNotExclusive(Result, ReplacementsToProcess, ExecutionParameters, True);
			
		ElsIf ExecutionParameters.MarkForDeletion Then
			DeleteRefsNotExclusive(Result, ReplacementsToProcess, ExecutionParameters, False);
			
		Else
			// Searching for new items.
			RepeatSearchTable = UsageInstances(ReplacementsToProcess);
			AddModifiedObjectReplacementResults(Result, RepeatSearchTable);
		EndIf;
		
		If Result.HasErrors Then
			RollbackTransaction();
			Return;
		EndIf;
		
		ExecutionParameters.SuccessfulReplacements.Insert(Duplicate, ExecutionParameters.ReplacementPairs[Duplicate]);
		CommitTransaction();
		
	Except
		RollbackTransaction();
		If ActionState = "LockError" Then
			ErrorPresentation = DetailErrorDescription(ErrorInfo());
			Error = StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = 'Не удалось заблокировать все места использования %1:'; en = 'Cannot lock all usage instances of %1:'; pl = 'Nie udało się zablokować wszystkie miejsca wykorzystania %1:';de = 'Es war nicht möglich, alle Einsatzorte zu blockieren %1:';ro = 'Eșec la blocarea tuturor locurilor de utilizare %1:';tr = 'Tüm kullanım yerleri kilitlenemiyor %1:'; es_ES = 'No se puede bloquear todas las ubicaciones de uso %1:'") 
				+ Chars.LF + ErrorPresentation, Duplicate);
			RegisterReplacementError(Result, Duplicate, 
				ReplacementErrorDescription("LockError", Undefined, Undefined, Error));
		Else
			Raise;	
		EndIf;
	EndTry
	
EndProcedure

Procedure ReplaceInConstant(Result, Val UsageInstance, Val WriteParameters, Val InnerTransaction = True)
	
	SetPrivilegedMode(True);
	
	Data = UsageInstance.Data;
	Meta   = UsageInstance.Metadata;
	
	DataPresentation = String(Data);
	
	// Performing all replacement of the data in the same time.
	Filter = New Structure("Data, ReplacementKey", Data, "Constant");
	RowsToProcess = UsageInstance.Owner().FindRows(Filter);
	// Marking as processed.
	For Each Row In RowsToProcess Do
		Row.ReplacementKey = "";
	EndDo;

	ActionState = "";
	Error = "";
	If InnerTransaction Then
		BeginTransaction();
	EndIf;
	
	Try
		If InnerTransaction Then
			Lock = New DataLock;
			Lock.Add(Meta.FullName());
			Try
				Lock.Lock();
			Except
				Error = StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = 'Не удалось заблокировать константу %1'; en = 'Cannot lock the constant %1.'; pl = 'Nie można zablokować stałej %1';de = 'Kann nicht konstant sperren %1';ro = 'Eșec la blocarea constantei %1';tr = '%1Sabit kilitlenemedi'; es_ES = 'No se puede bloquear el constante %1'"), 
					DataPresentation);
				ActionState = "LockError";
				Raise;
			EndTry;
		EndIf;	
	
		Manager = Constants[Meta.Name].CreateValueManager();
		Manager.Read();
		
		ReplacementPerformed = False;
		For Each Row In RowsToProcess Do
			If Manager.Value = Row.Ref Then
				Manager.Value = Row.DestinationRef;
				ReplacementPerformed = True;
			EndIf;
		EndDo;
		
		If Not ReplacementPerformed Then
			If InnerTransaction Then
				RollbackTransaction();
			EndIf;	
			Return;
		EndIf;	
		 
		// Attempting to save.
		If Not WriteParameters.WriteInPrivilegedMode Then
			SetPrivilegedMode(False);
		EndIf;
		
		Try
			WriteObject(Manager, WriteParameters);
		Except
			ErrorDescription = BriefErrorDescription(ErrorInfo());
			Error = StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = 'Не удалось записать %1 по причине: %2'; en = 'Cannot save %1. Reason: %2'; pl = 'Nie można zapisać %1z powodu: %2';de = 'Kann nicht schreiben %1 wegen: %2';ro = 'Eșec la înregistrarea %1 din motivul: %2';tr = '%1Nedeniyle kaydedilemez: %2'; es_ES = 'No se puede grabar %1 debido a: %2'"), 
				DataPresentation, ErrorDescription);
			ActionState = "WritingError";
			Raise;
		EndTry;
		
		If Not WriteParameters.WriteInPrivilegedMode Then
			SetPrivilegedMode(True);
		EndIf;
			
		If InnerTransaction Then
			CommitTransaction();
		EndIf;	
	Except
		If InnerTransaction Then
			RollbackTransaction();
		EndIf;	
		WriteLogEvent(RefReplacementEventLogMessageText(), EventLogLevel.Error,
			Meta,, DetailErrorDescription(ErrorInfo()));
		If ActionState = "WritingError" Then
			For Each Row In RowsToProcess Do
				RegisterReplacementError(Result, Row.Ref, 
					ReplacementErrorDescription("WritingError", Data, DataPresentation, Error));
			EndDo;
		Else		
			RegisterReplacementError(Result, Row.Ref, 
				ReplacementErrorDescription(ActionState, Data, DataPresentation, Error));
		EndIf;		
	EndTry;
	
EndProcedure

Procedure ReplaceInObject(Result, Val UsageInstance, Val ExecutionParameters, Val InnerTransaction = True)
	
	SetPrivilegedMode(True);
	
	Data = UsageInstance.Data;
	
	// Performing all replacement of the data in the same time.
	Filter = New Structure("Data, ReplacementKey", Data, "Object");
	RowsToProcess = UsageInstance.Owner().FindRows(Filter);
	
	DataPresentation = SubjectString(Data);
	ActionState = "";
	ErrorText = "";
	If InnerTransaction Then
		BeginTransaction();
	EndIf;
	
	Try
		
		If InnerTransaction Then
			Lock = New DataLock;
			LockUsageInstance(ExecutionParameters, Lock, UsageInstance);
			Try
				Lock.Lock();
			Except
				ActionState = "LockError";
				ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("ru = 'Не удалось заблокировать объект ""%1"":
					|%2'; 
					|en = 'Cannot lock object %1:
					|%2'; 
					|pl = 'Zablokowanie obiektu nie powiodło się ""%1"":
					|%2';
					|de = 'Das Objekt ""%1"" konnte nicht gesperrt werden:
					|%2';
					|ro = 'Eșec la blocarea obiectului ""%1"":
					|%2';
					|tr = '""%1"" nesne kilitlenemedi: 
					|%2'; 
					|es_ES = 'No se ha podido bloquear el objeto ""%1"":
					|%2'"),
					DataPresentation,
					BriefErrorDescription(ErrorInfo()));
				Raise;
			EndTry;
		EndIf;
		
		WritingObjects = ModifiedObjectsOnReplaceInObject(ExecutionParameters, UsageInstance, RowsToProcess);
		
		// Attempting to save. The object goes last.
		If Not ExecutionParameters.WriteInPrivilegedMode Then
			SetPrivilegedMode(False);
		EndIf;
		
		Try
			If ExecutionParameters.IncludeBusinessLogic Then
				// First writing iteration without the control to fix loop references.
				NewExecutionParameters = CopyRecursive(ExecutionParameters);
				NewExecutionParameters.IncludeBusinessLogic = False;
				For Each KeyValue In WritingObjects Do
					WriteObject(KeyValue.Key, NewExecutionParameters);
				EndDo;
				// Second writing iteration with the control.
				NewExecutionParameters.IncludeBusinessLogic = True;
				For Each KeyValue In WritingObjects Do
					WriteObject(KeyValue.Key, NewExecutionParameters);
				EndDo;
			Else
				// Writing without the business logic control.
				For Each KeyValue In WritingObjects Do
					WriteObject(KeyValue.Key, ExecutionParameters);
				EndDo;
			EndIf;
		Except
			ActionState = "WritingError";
			ErrorDescription = BriefErrorDescription(ErrorInfo());
			ErrorText = StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = 'Не удалось записать %1 по причине: %2'; en = 'Cannot save %1. Reason: %2'; pl = 'Nie można zapisać %1z powodu: %2';de = 'Kann nicht schreiben %1 wegen: %2';ro = 'Eșec la înregistrarea %1 din motivul: %2';tr = '%1Nedeniyle kaydedilemez: %2'; es_ES = 'No se puede grabar %1 debido a: %2'"), 
				DataPresentation, ErrorDescription);
			Raise;
		EndTry;
		
		If InnerTransaction Then
			CommitTransaction();
		EndIf;
		
	Except
		If InnerTransaction Then
			RollbackTransaction();
		EndIf;
		Information = ErrorInfo();
		WriteLogEvent(RefReplacementEventLogMessageText(), EventLogLevel.Error,
			UsageInstance.Metadata,,	DetailErrorDescription(Information));
		Error = ReplacementErrorDescription(ActionState, Data, DataPresentation, ErrorText);
		If ActionState = "WritingError" Then
			For Each Row In RowsToProcess Do
				RegisterReplacementError(Result, Row.Ref, Error);
			EndDo;
		Else	
			RegisterReplacementError(Result, UsageInstance.Ref, Error);
		EndIf;
	EndTry;
	
	// Marking as processed.
	For Each Row In RowsToProcess Do
		Row.ReplacementKey = "";
	EndDo;
	
EndProcedure

Procedure ReplaceInSet(Result, Val UsageInstance, Val ExecutionParameters, Val InnerTransaction = True)
	SetPrivilegedMode(True);
	
	Data = UsageInstance.Data;
	Meta   = UsageInstance.Metadata;
	
	DataPresentation = String(Data);
	
	// Performing all replacement of the data in the same time.
	Filter = New Structure("Data, ReplacementKey");
	FillPropertyValues(Filter, UsageInstance);
	RowsToProcess = UsageInstance.Owner().FindRows(Filter);
	
	SetDetails = RecordKeyDetails(Meta);
	RecordSet = SetDetails.RecordSet;
	
	ReplacementPairs = New Map;
	For Each Row In RowsToProcess Do
		ReplacementPairs.Insert(Row.Ref, Row.DestinationRef);
	EndDo;
	
	// Marking as processed.
	For Each Row In RowsToProcess Do
		Row.ReplacementKey = "";
	EndDo;
	
	ActionState = "";
	Error = "";
	If InnerTransaction Then
		BeginTransaction();
	EndIf;
	
	Try
		
		If InnerTransaction Then
			// Locking and preparing the set.
			Lock = New DataLock;
			For Each KeyValue In SetDetails.MeasurementList Do
				DimensionType = KeyValue.Value;
				Name          = KeyValue.Key;
				Value     = Data[Name];
				
				For Each Row In RowsToProcess Do
					CurrentRef = Row.Ref;
					If DimensionType.ContainsType(TypeOf(CurrentRef)) Then
						Lock.Add(SetDetails.LockSpace).SetValue(Name, CurrentRef);
					EndIf;
				EndDo;
				
				RecordSet.Filter[Name].Set(Value);
			EndDo;
			
			Try
				Lock.Lock();
			Except
				Error = StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = 'Не удалось заблокировать набор %1'; en = 'Cannot lock record set %1.'; pl = 'Nie można zablokować zestawu %1';de = 'Satz kann nicht gesperrt werden %1';ro = 'Eșec la blocarea setului %1';tr = '%1Küme kilitlenemedi'; es_ES = 'No se puede bloquear el conjunto %1'"), 
					DataPresentation);
				ActionState = "LockError";
				Raise;
			EndTry;
			
		EndIf;	
			
		RecordSet.Read();
		ReplaceInRowCollection("RecordSet", "RecordSet", RecordSet, RecordSet, SetDetails.FieldList, ReplacementPairs);
		
		If RecordSet.Modified() Then
			If InnerTransaction Then
				RollbackTransaction();
			EndIf;
			Return;
		EndIf;	

		If Not ExecutionParameters.WriteInPrivilegedMode Then
			SetPrivilegedMode(False);
		EndIf;
		
		Try
			WriteObject(RecordSet, ExecutionParameters);
		Except
			ErrorDescription = BriefErrorDescription(ErrorInfo());
			Error = StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = 'Не удалось записать %1 по причине: %2'; en = 'Cannot save %1. Reason: %2'; pl = 'Nie można zapisać %1z powodu: %2';de = 'Kann nicht schreiben %1 wegen: %2';ro = 'Eșec la înregistrarea %1 din motivul: %2';tr = '%1Nedeniyle kaydedilemez: %2'; es_ES = 'No se puede grabar %1 debido a: %2'"), 
				DataPresentation, ErrorDescription);
			ActionState = "WritingError";
			Raise;
		EndTry;
		
		If Not ExecutionParameters.WriteInPrivilegedMode Then
			SetPrivilegedMode(True);
		EndIf;
		
		If InnerTransaction Then
			CommitTransaction();
		EndIf;
		
	Except
		If InnerTransaction Then
			RollbackTransaction();
		EndIf;
		Information = ErrorInfo();
		WriteLogEvent(RefReplacementEventLogMessageText(), EventLogLevel.Error,
			Meta,, DetailErrorDescription(Information));
		Error = ReplacementErrorDescription(ActionState, Data, DataPresentation, Error);
		If ActionState = "WritingError" Then
			For Each Row In RowsToProcess Do
				RegisterReplacementError(Result, Row.Ref, Error);
			EndDo;
		Else	
			RegisterReplacementError(Result, UsageInstance.Ref, Error);
		EndIf;	
	EndTry;
	
EndProcedure

Procedure ReplaceInInformationRegister(Result, Val UsageInstance, Val ExecutionParameters, Val InnerTransaction = True)
	
	If UsageInstance.Processed Then
		Return;
	EndIf;
	UsageInstance.Processed = True;
	
	// If the duplicate is specified in set dimensions, two record sets are used:
	//     DuplicateRecordSet - reads old values (by old dimensions) and deletes old values.
	//     OriginalRecordSet - reads actual values (by new dimensions) and writes new values.
	//     Data of duplicates and originals are merged by the rules:
	//         Original object data has the priority.
	//         If the original has no data, the data is received from the duplicate.
	//     The original set is written and the duplicate set is deleted.
	//
	// If the duplicate is not specified in a set dimensions, one record sets is used:
	//     DuplicateRecordSet - reads old values and writes new values.
	//
	// In both cases, reference in resources and attributes are replaced.
	
	SetPrivilegedMode(True);
	
	Duplicate    = UsageInstance.Ref;
	Original = UsageInstance.DestinationRef;
	
	RegisterMetadata = UsageInstance.Metadata;
	RegisterRecordKey = UsageInstance.Data;
	
	Information = TypeInformation(RegisterMetadata, ExecutionParameters);
	
	TwoSetsRequired = False;
	For Each KeyValue In Information.Dimensions Do
		DuplicateDimensionValue = RegisterRecordKey[KeyValue.Key];
		If DuplicateDimensionValue = Duplicate
			Or ExecutionParameters.SuccessfulReplacements[DuplicateDimensionValue] = Duplicate Then
			TwoSetsRequired = True; // Duplicate is specified in dimensions.
			Break;
		EndIf;
	EndDo;
	
	Manager = ObjectManagerByFullName(Information.FullName);
	DuplicateRecordSet = Manager.CreateRecordSet();
	
	If TwoSetsRequired Then
		OriginalDimensionValues = New Structure;
		OriginalRecordSet = Manager.CreateRecordSet();
	EndIf;
	
	If InnerTransaction Then
		BeginTransaction();
	EndIf;
	
	Try
		If InnerTransaction Then
			Lock = New DataLock;
			DuplicateLock = Lock.Add(Information.FullName);
			If TwoSetsRequired Then
				OriginalLock = Lock.Add(Information.FullName);
			EndIf;
		EndIf;
		
		For Each KeyValue In Information.Dimensions Do
			DuplicateDimensionValue = RegisterRecordKey[KeyValue.Key];
			
			// To solve the problem of uniqueness, replacing old record key dimension values for new ones.
			//   
			//   Map of old and current provides SuccessfulReplacements.
			//   Map data is actual at the current point in time as it is updated only after processing a next 
			//   couple and committing the transaction.
			NewDuplicateDimensionValue = ExecutionParameters.SuccessfulReplacements[DuplicateDimensionValue];
			If NewDuplicateDimensionValue <> Undefined Then
				DuplicateDimensionValue = NewDuplicateDimensionValue;
			EndIf;
			
			DuplicateRecordSet.Filter[KeyValue.Key].Set(DuplicateDimensionValue);
			
			If InnerTransaction Then // Replacement in the pair and lock for the replacement.
				DuplicateLock.SetValue(KeyValue.Key, DuplicateDimensionValue);
			EndIf;
			
			If TwoSetsRequired Then
				If DuplicateDimensionValue = Duplicate Then
					OriginalDimensionValue = Original;
				Else
					OriginalDimensionValue = DuplicateDimensionValue;
				EndIf;
				
				OriginalRecordSet.Filter[KeyValue.Key].Set(OriginalDimensionValue);
				OriginalDimensionValues.Insert(KeyValue.Key, OriginalDimensionValue);
				
				If InnerTransaction Then // Replacement in the pair and lock for the replacement.
					OriginalLock.SetValue(KeyValue.Key, OriginalDimensionValue);
				EndIf;
			EndIf;
		EndDo;
		
		// Setting lock.
		If InnerTransaction Then
			Try
				Lock.Lock();
			Except
				// Error type: LockForRegister.
				Raise;
			EndTry;
		EndIf;
		
		// The source.
		DuplicateRecordSet.Read();
		If DuplicateRecordSet.Count() = 0 Then // Nothing to write.
			If InnerTransaction Then
				RollbackTransaction(); // Replacement is not required.
			EndIf;
			Return;
		EndIf;
		DuplicateRecord = DuplicateRecordSet[0];
		
		// The destination.
		If TwoSetsRequired Then
			// Writing to a set with other dimensions.
			OriginalRecordSet.Read();
			If OriginalRecordSet.Count() = 0 Then
				OriginalRecord = OriginalRecordSet.Add();
				FillPropertyValues(OriginalRecord, DuplicateRecord);
				FillPropertyValues(OriginalRecord, OriginalDimensionValues);
			Else
				OriginalRecord = OriginalRecordSet[0];
			EndIf;
		Else
			// Writing to the source.
			OriginalRecordSet = DuplicateRecordSet;
			OriginalRecord = DuplicateRecord; // The zero record set case is processed above.
		EndIf;
		
		// Substituting the original for duplicate in resource and attributes.
		For Each KeyValue In Information.Resources Do
			AttributeValueInOriginal = OriginalRecord[KeyValue.Key];
			If AttributeValueInOriginal = Duplicate Then
				OriginalRecord[KeyValue.Key] = Original;
			EndIf;
		EndDo;
		For Each KeyValue In Information.Attributes Do
			AttributeValueInOriginal = OriginalRecord[KeyValue.Key];
			If AttributeValueInOriginal = Duplicate Then
				OriginalRecord[KeyValue.Key] = Original;
			EndIf;
		EndDo;
		
		If Not ExecutionParameters.WriteInPrivilegedMode Then
			SetPrivilegedMode(False);
		EndIf;
		
		// Deleting the duplicate data.
		If TwoSetsRequired Then
			DuplicateRecordSet.Clear();
			Try
				WriteObject(DuplicateRecordSet, ExecutionParameters);
			Except
				// Error type: DeleteDuplicateSet.
				Raise;
			EndTry;
		EndIf;
		
		// Writing original object data.
		If OriginalRecordSet.Modified() Then
			Try
				WriteObject(OriginalRecordSet, ExecutionParameters);
			Except
				// Error type: WriteOriginalSet.
				Raise;
			EndTry;
		EndIf;
		
		If InnerTransaction Then
			CommitTransaction();
		EndIf;
	Except
		If InnerTransaction Then
			RollbackTransaction();
		EndIf;
		RegisterErrorInTable(Result, Duplicate, Original, RegisterRecordKey, Information, 
			"LockForRegister", ErrorInfo());
	EndTry
	
EndProcedure

Function ModifiedObjectsOnReplaceInObject(ExecutionParameters, UsageInstance, RowsToProcess)
	Data = UsageInstance.Data;
	SequencesDetails = SequencesDetails(UsageInstance.Metadata);
	RegisterRecordsDetails            = RegisterRecordsDetails(UsageInstance.Metadata);
	
	SetPrivilegedMode(True);
	
	// Returning modified processed objects.
	Modified = New Map;
	
	// Reading
	Details = ObjectDetails(Data.Metadata());
	Try
		Object = Data.GetObject();
	Except
		// Has already been processed with errors.
		Object = Undefined;
	EndTry;
	
	If Object = Undefined Then
		Return Modified;
	EndIf;
	
	For Each RegisterRecordDetails In RegisterRecordsDetails Do
		RegisterRecordDetails.RecordSet.Filter.Recorder.Set(Data);
		RegisterRecordDetails.RecordSet.Read();
	EndDo;
	
	For Each SequenceDetails In SequencesDetails Do
		SequenceDetails.RecordSet.Filter.Recorder.Set(Data);
		SequenceDetails.RecordSet.Read();
	EndDo;
	
	// Replacing all at once.
	ReplacementPairs = New Map;
	For Each UsageInstance In RowsToProcess Do
		ReplacementPairs.Insert(UsageInstance.Ref, UsageInstance.DestinationRef);
	EndDo;
	
	// Attributes
	For Each KeyValue In Details.Attributes Do
		Name = KeyValue.Key;
		DestinationRef = ReplacementPairs[ Object[Name] ];
		If DestinationRef <> Undefined Then
			RegisterReplacement(Object, Object[Name], DestinationRef, "Attributes", Name);
			Object[Name] = DestinationRef;
		EndIf;
	EndDo;
	
	// Standard attributes.
	For Each KeyValue In Details.StandardAttributes Do
		Name = KeyValue.Key;
		DestinationRef = ReplacementPairs[ Object[Name] ];
		If DestinationRef <> Undefined Then
			RegisterReplacement(Object, Object[Name], DestinationRef, "StandardAttributes", Name);
			Object[Name] = DestinationRef;
		EndIf;
	EndDo;
		
	// Tabular sections
	For Each Item In Details.TabularSections Do
		ReplaceInRowCollection(
			"TabularSections",
			Item.Name,
			Object,
			Object[Item.Name],
			Item.FieldList,
			ReplacementPairs);
	EndDo;
	
	// Standard tabular section.
	For Each Item In Details.StandardTabularSections Do
		ReplaceInRowCollection(
			"StandardTabularSections",
			Item.Name,
			Object,
			Object[Item.Name],
			Item.FieldList,
			ReplacementPairs);
	EndDo;
		
	// RegisterRecords
	For Each RegisterRecordDetails In RegisterRecordsDetails Do
		ReplaceInRowCollection(
			"RegisterRecords",
			RegisterRecordDetails.LockSpace,
			RegisterRecordDetails.RecordSet,
			RegisterRecordDetails.RecordSet,
			RegisterRecordDetails.FieldList,
			ReplacementPairs);
	EndDo;
	
	// Sequences
	For Each SequenceDetails In SequencesDetails Do
		ReplaceInRowCollection(
			"Sequences",
			SequenceDetails.LockSpace,
			SequenceDetails.RecordSet,
			SequenceDetails.RecordSet,
			SequenceDetails.FieldList,
			ReplacementPairs);
	EndDo;
	
	For Each RegisterRecordDetails In RegisterRecordsDetails Do
		If RegisterRecordDetails.RecordSet.Modified() Then
			Modified.Insert(RegisterRecordDetails.RecordSet, False);
		EndIf;
	EndDo;
	
	For Each SequenceDetails In SequencesDetails Do
		If SequenceDetails.RecordSet.Modified() Then
			Modified.Insert(SequenceDetails.RecordSet, False);
		EndIf;
	EndDo;
	
	// The object goes last in case a reposting is required.
	If Object.Modified() Then
		Modified.Insert(Object, Details.CanBePosted);
	EndIf;
	
	Return Modified;
EndFunction

Procedure RegisterReplacement(Object, DuplicateRef, OriginalRef, AttributeKind, AttributeName, Index = Undefined, ColumnName = Undefined)
	Structure = New Structure("AdditionalProperties");
	FillPropertyValues(Structure, Object);
	If TypeOf(Structure.AdditionalProperties) <> Type("Structure") Then
		Return;
	EndIf;
	AuxProperties = Object.AdditionalProperties;
	AuxProperties.Insert("ReferenceReplacement", True);
	CompletedReplacements = CommonClientServer.StructureProperty(AuxProperties, "CompletedReplacements");
	If CompletedReplacements = Undefined Then
		CompletedReplacements = New Array;
		AuxProperties.Insert("CompletedReplacements", CompletedReplacements);
	EndIf;
	ReplacementDetails = New Structure;
	ReplacementDetails.Insert("DuplicateRef", DuplicateRef);
	ReplacementDetails.Insert("OriginalRef", OriginalRef);
	ReplacementDetails.Insert("AttributeKind", AttributeKind);
	ReplacementDetails.Insert("AttributeName", AttributeName);
	ReplacementDetails.Insert("IndexOf", Index);
	ReplacementDetails.Insert("ColumnName", ColumnName);
	CompletedReplacements.Add(ReplacementDetails);
EndProcedure

Procedure DeleteRefsNotExclusive(Result, Val RefsList, Val ExecutionParameters, Val DeleteDirectly)
	
	SetPrivilegedMode(True);
	
	ToDelete = New Array;
	
	LocalTransaction = Not TransactionActive();
	If LocalTransaction Then
		BeginTransaction();
	EndIf;
	
	Try
		For Each Ref In RefsList Do
			Information = TypeInformation(TypeOf(Ref), ExecutionParameters);
			Lock = New DataLock;
			Lock.Add(Information.FullName).SetValue("Ref", Ref);
			Try
				Lock.Lock();
				ToDelete.Add(Ref);
			Except
				RegisterErrorInTable(Result, Ref, Undefined, Ref, Information, 
					"DataLockForDuplicateDeletion", ErrorInfo());
			EndTry;
		EndDo;
		
		SearchTable = UsageInstances(ToDelete);
		Filter = New Structure("Ref");
		
		For Each Ref In ToDelete Do
			RefPresentation = SubjectString(Ref);
			
			Filter.Ref = Ref;
			UsageInstances = SearchTable.FindRows(Filter);
			
			Index = UsageInstances.UBound();
			While Index >= 0 Do
				If UsageInstances[Index].AuxiliaryData Then
					UsageInstances.Delete(Index);
				EndIf;
				Index = Index - 1;
			EndDo;
			
			If UsageInstances.Count() > 0 Then
				AddModifiedObjectReplacementResults(Result, UsageInstances);
				Continue; // Cannot delete the object because other objects refer to it.
			EndIf;
			
			Object = Ref.GetObject();
			If Object = Undefined Then
				Continue; // Has already been deleted.
			EndIf;
			
			If Not ExecutionParameters.WriteInPrivilegedMode Then
				SetPrivilegedMode(False);
			EndIf;
			
			Try
				If DeleteDirectly Then
					ProcessObjectWithMessageInterception(Object, "DirectDeletion", Undefined, ExecutionParameters);
				Else
					ProcessObjectWithMessageInterception(Object, "DeletionMark", Undefined, ExecutionParameters);
				EndIf;
			Except
				ErrorText = NStr("ru = 'Ошибка удаления'; en = 'Deletion error.'; pl = 'Usunięcie nie powiodło się';de = 'Entfernung fehlgeschlagen';ro = 'Eroare de ștergere';tr = 'Kaldırma başarısız oldu'; es_ES = 'Eliminación ha fallado'")
					+ Chars.LF
					+ TrimAll(BriefErrorDescription(ErrorInfo()));
				ErrorDescription = ReplacementErrorDescription("DeletionError", Ref, RefPresentation, ErrorText);
				RegisterReplacementError(Result, Ref, ErrorDescription);
			EndTry;
			
			If Not ExecutionParameters.WriteInPrivilegedMode Then
				SetPrivilegedMode(True);
			EndIf;
		EndDo;
		
		If LocalTransaction Then
			CommitTransaction();
		EndIf;
	Except
		If LocalTransaction Then
			RollbackTransaction();
		EndIf;
	EndTry;
	
EndProcedure

Procedure AddModifiedObjectReplacementResults(Result, RepeatSearchTable)
	
	Filter = New Structure("ErrorType, Ref, ErrorObject", "");
	For Each Row In RepeatSearchTable Do
		Test = New Structure("AuxiliaryData", False);
		FillPropertyValues(Test, Row);
		If Test.AuxiliaryData Then
			Continue;
		EndIf;
		
		Data = Row.Data;
		Ref = Row.Ref;
		
		DataPresentation = String(Data);
		
		Filter.ErrorObject = Data;
		Filter.Ref       = Ref;
		If Result.Errors.FindRows(Filter).Count() > 0 Then
			Continue; // Error on this issue has already been recorded.
		EndIf;
		RegisterReplacementError(Result, Ref, 
			ReplacementErrorDescription("DataChanged", Data, DataPresentation,
			NStr("ru = 'Заменены не все места использования. Возможно места использования были добавлены или изменены другим пользователем.'; en = 'Some of the instances were not replaced. Probably these instances were added or edited by other users.'; pl = 'Zostały zmienione nie wszystkie miejsca wykorzystania. Możliwie, że miejsca wykorzystania były dodane lub zmienione przez innego użytkownika.';de = 'Nicht alle Standorte wurden ersetzt. Möglicherweise wurden die Verwendungsorte von einem anderen Benutzer hinzugefügt oder geändert.';ro = 'Nu toate locurile de utilizare au fost înlocuite. Locurile de utilizare posibile au fost adăugate sau modificate de alt utilizator.';tr = 'Tüm kullanım yerleri değiştirilmedi. Kullanım yerleri eklenmiş veya başka bir kullanıcı tarafından değiştirilmiş olabilir.'; es_ES = 'Se han cambiado no todos los lugares del uso. Es posible que los lugares de uso hayan sido añadidos o cambiados por otro usuario.'")));
	EndDo;
	
EndProcedure

Procedure LockUsageInstances(ExecutionParameters, Lock, UsageInstances)
	
	For Each UsageInstance In UsageInstances Do
		
		LockUsageInstance(ExecutionParameters, Lock, UsageInstance);
		
	EndDo;
	
EndProcedure

Procedure LockUsageInstance(ExecutionParameters, Lock, UsageInstance)
	
	If UsageInstance.ReplacementKey = "Constant" Then
		
		Lock.Add(UsageInstance.Metadata.FullName());
		
	ElsIf UsageInstance.ReplacementKey = "Object" Then
		
		ObjectRef     = UsageInstance.Data;
		ObjectMetadata = UsageInstance.Metadata;
		
		// The object.
		Lock.Add(ObjectMetadata.FullName()).SetValue("Ref", ObjectRef);
		
		// Register records by recorder.
		RegisterRecordsDetails = RegisterRecordsDetails(ObjectMetadata);
		For Each Item In RegisterRecordsDetails Do
			Lock.Add(Item.LockSpace + ".RecordSet").SetValue("Recorder", ObjectRef);
		EndDo;
		
		// Sequences.
		SequencesDetails = SequencesDetails(ObjectMetadata);
		For Each Item In SequencesDetails Do
			Lock.Add(Item.LockSpace).SetValue("Recorder", ObjectRef);
		EndDo;
		
	ElsIf UsageInstance.ReplacementKey = "Sequence" Then
		
		ObjectRef     = UsageInstance.Data;
		ObjectMetadata = UsageInstance.Metadata;
		
		SequencesDetails = SequencesDetails(ObjectMetadata);
		For Each Item In SequencesDetails Do
			Lock.Add(Item.LockSpace).SetValue("Recorder", ObjectRef);
		EndDo;
		
	ElsIf UsageInstance.ReplacementKey = "RecordKey"
		Or UsageInstance.ReplacementKey = "InformationRegister" Then
		
		Information = TypeInformation(UsageInstance.Metadata, ExecutionParameters);
		DuplicateType = UsageInstance.RefType;
		OriginalType = TypeOf(UsageInstance.DestinationRef);
		
		For Each KeyValue In Information.Dimensions Do
			DimensionType = KeyValue.Value.Type;
			If DimensionType.ContainsType(DuplicateType) Then
				DataLockByDimension = Lock.Add(Information.FullName);
				DataLockByDimension.SetValue(KeyValue.Key, UsageInstance.Ref);
			EndIf;
			If DimensionType.ContainsType(OriginalType) Then
				DataLockByDimension = Lock.Add(Information.FullName);
				DataLockByDimension.SetValue(KeyValue.Key, UsageInstance.DestinationRef);
			EndIf;
		EndDo;
		
	EndIf;
	
EndProcedure

Function RegisterRecordsDetails(Val Meta)
	// Can be cached by Meta.
	
	RegisterRecordsDetails = New Array;
	If Not Metadata.Documents.Contains(Meta) Then
		Return RegisterRecordsDetails;
	EndIf;
	
	For Each RegisterRecord In Meta.RegisterRecords Do
		
		If Metadata.AccumulationRegisters.Contains(RegisterRecord) Then
			RecordSet = AccumulationRegisters[RegisterRecord.Name].CreateRecordSet();
			ExcludeFields = "Active, LineNumber, Period, Recorder"; 
			
		ElsIf Metadata.InformationRegisters.Contains(RegisterRecord) Then
			RecordSet = InformationRegisters[RegisterRecord.Name].CreateRecordSet();
			ExcludeFields = "Active, RecordType, LineNumber, Period, Recorder"; 
			
		ElsIf Metadata.AccountingRegisters.Contains(RegisterRecord) Then
			RecordSet = AccountingRegisters[RegisterRecord.Name].CreateRecordSet();
			ExcludeFields = "Active, RecordType, LineNumber, Period, Recorder"; 
			
		ElsIf Metadata.CalculationRegisters.Contains(RegisterRecord) Then
			RecordSet = CalculationRegisters[RegisterRecord.Name].CreateRecordSet();
			ExcludeFields = "Active, EndOfBasePeriod, BegOfBasePeriod, LineNumber, ActionPeriod,
			                |EndOfActionPeriod, BegOfActionPeriod, RegistrationPeriod, Recorder, ReversingEntry,
			                |ActualActionPeriod";
		Else
			// Unknown type.
			Continue;
		EndIf;
		
		// Reference type fields and candidate dimensions.
		Details = FieldListsByType(RecordSet, RegisterRecord.Dimensions, ExcludeFields);
		If Details.FieldList.Count() = 0 Then
			// No need to process.
			Continue;
		EndIf;
		
		Details.Insert("RecordSet", RecordSet);
		Details.Insert("LockSpace", RegisterRecord.FullName() );
		
		RegisterRecordsDetails.Add(Details);
	EndDo;	// Register record metadata.
	
	Return RegisterRecordsDetails;
EndFunction

Function SequencesDetails(Val Meta)
	
	SequencesDetails = New Array;
	If Not Metadata.Documents.Contains(Meta) Then
		Return SequencesDetails;
	EndIf;
	
	For Each Sequence In Metadata.Sequences Do
		If Not Sequence.Documents.Contains(Meta) Then
			Continue;
		EndIf;
		
		TableName = Sequence.FullName();
		
		// List of fields and dimensions
		Details = FieldListsByType(TableName, Sequence.Dimensions, "Recorder");
		If Details.FieldList.Count() > 0 Then
			
			Details.Insert("RecordSet",           Sequences[Sequence.Name].CreateRecordSet());
			Details.Insert("LockSpace", TableName + ".Records");
			Details.Insert("Dimensions",              New Structure);
			
			SequencesDetails.Add(Details);
		EndIf;
		
	EndDo;
	
	Return SequencesDetails;
EndFunction

Function ObjectDetails(Val Meta)
	// Can be cached by Meta.
	
	AllRefsType = AllRefsTypeDetails();
	
	Candidates = New Structure("Attributes, StandardAttributes, TabularSections, StandardTabularSections");
	FillPropertyValues(Candidates, Meta);
	
	ObjectDetails = New Structure;
	
	ObjectDetails.Insert("Attributes", New Structure);
	If Candidates.Attributes <> Undefined Then
		For Each MetaAttribute In Candidates.Attributes Do
			If DescriptionTypesOverlap(MetaAttribute.Type, AllRefsType) Then
				ObjectDetails.Attributes.Insert(MetaAttribute.Name);
			EndIf;
		EndDo;
	EndIf;
	
	ObjectDetails.Insert("StandardAttributes", New Structure);
	If Candidates.StandardAttributes <> Undefined Then
		ToExclude = New Structure("Ref");
		
		For Each MetaAttribute In Candidates.StandardAttributes Do
			Name = MetaAttribute.Name;
			If Not ToExclude.Property(Name) AND DescriptionTypesOverlap(MetaAttribute.Type, AllRefsType) Then
				ObjectDetails.Attributes.Insert(MetaAttribute.Name);
			EndIf;
		EndDo;
	EndIf;
	
	ObjectDetails.Insert("TabularSections", New Array);
	If Candidates.TabularSections <> Undefined Then
		For Each MetaTable In Candidates.TabularSections Do
			
			FieldsList = New Structure;
			For Each MetaAttribute In MetaTable.Attributes Do
				If DescriptionTypesOverlap(MetaAttribute.Type, AllRefsType) Then
					FieldsList.Insert(MetaAttribute.Name);
				EndIf;
			EndDo;
			
			If FieldsList.Count() > 0 Then
				ObjectDetails.TabularSections.Add(New Structure("Name, FieldList", MetaTable.Name, FieldsList));
			EndIf;
		EndDo;
	EndIf;
	
	ObjectDetails.Insert("StandardTabularSections", New Array);
	If Candidates.StandardTabularSections <> Undefined Then
		For Each MetaTable In Candidates.StandardTabularSections Do
			
			FieldsList = New Structure;
			For Each MetaAttribute In MetaTable.StandardAttributes Do
				If DescriptionTypesOverlap(MetaAttribute.Type, AllRefsType) Then
					FieldsList.Insert(MetaAttribute.Name);
				EndIf;
			EndDo;
			
			If FieldsList.Count() > 0 Then
				ObjectDetails.StandardTabularSections.Add(New Structure("Name, FieldList", MetaTable.Name, FieldsList));
			EndIf;
		EndDo;
	EndIf;
	
	ObjectDetails.Insert("CanBePosted", Metadata.Documents.Contains(Meta));
	Return ObjectDetails;
EndFunction

Function RecordKeyDetails(Val Meta)
	// Can be cached by Meta.
	
	TableName = Meta.FullName();
	
	// Candidate reference type fields and a dimension set.
	KeyDetails = FieldListsByType(TableName, Meta.Dimensions, "Period, Recorder");
	
	If Metadata.InformationRegisters.Contains(Meta) Then
		RecordSet = InformationRegisters[Meta.Name].CreateRecordSet();
	
	ElsIf Metadata.AccumulationRegisters.Contains(Meta) Then
		RecordSet = AccumulationRegisters[Meta.Name].CreateRecordSet();
	
	ElsIf Metadata.AccountingRegisters.Contains(Meta) Then
		RecordSet = AccountingRegisters[Meta.Name].CreateRecordSet();
	
	ElsIf Metadata.CalculationRegisters.Contains(Meta) Then
		RecordSet = CalculationRegisters[Meta.Name].CreateRecordSet();
	
	ElsIf Metadata.Sequences.Contains(Meta) Then
		RecordSet = Sequences[Meta.Name].CreateRecordSet();
	
	Else
		RecordSet = Undefined;
	
	EndIf;
	
	KeyDetails.Insert("RecordSet", RecordSet);
	KeyDetails.Insert("LockSpace", TableName);
	
	Return KeyDetails;
EndFunction

Function DescriptionTypesOverlap(Val Details1, Val Details2)
	
	For Each Type In Details1.Types() Do
		If Details2.ContainsType(Type) Then
			Return True;
		EndIf;
	EndDo;
	
	Return False;
EndFunction

// Returns a description by the table name or by the record set.
Function FieldListsByType(Val DataSource, Val MetaDimensions, Val ExcludeFields)
	// Can be cached.
	
	Details = New Structure;
	Details.Insert("FieldList",     New Structure);
	Details.Insert("DimensionStructure", New Structure);
	Details.Insert("MasterDimentionList",   New Structure);
	
	ControlType = AllRefsTypeDetails();
	ToExclude = New Structure(ExcludeFields);
	
	DataSourceType = TypeOf(DataSource);
	
	If DataSourceType = Type("String") Then
		// The source is the table name. The fields are received with a query.
		Query = New Query("SELECT * FROM " + DataSource + " WHERE FALSE");
		FieldSource = Query.Execute();
	Else
		// The source is a record set.
		FieldSource = DataSource.UnloadColumns();
	EndIf;
	
	For Each Column In FieldSource.Columns Do
		Name = Column.Name;
		If Not ToExclude.Property(Name) AND DescriptionTypesOverlap(Column.ValueType, ControlType) Then
			Details.FieldList.Insert(Name);
			
			// Checking for a master dimension.
			Meta = MetaDimensions.Find(Name);
			If Meta <> Undefined Then
				Details.DimensionStructure.Insert(Name, Meta.Type);
				Test = New Structure("Master", False);
				FillPropertyValues(Test, Meta);
				If Test.Master Then
					Details.MasterDimentionList.Insert(Name, Meta.Type);
				EndIf;
			EndIf;
			
		EndIf;
		
	EndDo;
	
	Return Details;
EndFunction

Procedure ReplaceInRowCollection(CollectionKind, CollectionName, Object, Collection, Val FieldsList, Val ReplacementPairs)
	WorkingCollection = Collection.Unload();
	Modified = False;
	
	For Each Row In WorkingCollection Do
		
		For Each KeyValue In FieldsList Do
			Name = KeyValue.Key;
			DestinationRef = ReplacementPairs[ Row[Name] ];
			If DestinationRef <> Undefined Then
				RegisterReplacement(Object, Row[Name], DestinationRef, CollectionKind, CollectionName, WorkingCollection.IndexOf(Row), Name);
				Row[Name] = DestinationRef;
				Modified = True;
			EndIf;
		EndDo;
		
	EndDo;
	
	If Modified Then
		Collection.Load(WorkingCollection);
	EndIf;
EndProcedure

Procedure ProcessObjectWithMessageInterception(Val Object, Val Action, Val WriteMode, Val WriteParameters)
	
	// Saving the current messages before the exception.
	PreviousMessages = GetUserMessages(True);
	ReportAgain    = CurrentRunMode() <> Undefined;
	
	Try
		
		Object.DataExchange.Load = Not WriteParameters.IncludeBusinessLogic;
		
		If Action = "Write" Then
			
			If WriteMode = Undefined Then
				Object.Write();
			Else
				Object.Write(WriteMode);
			EndIf;
			
		ElsIf Action = "DeletionMark" Then
			
			ObjectMetadata = Object.Metadata();
			
			If IsCatalog(ObjectMetadata)
				Or IsChartOfCharacteristicTypes(ObjectMetadata)
				Or IsChartOfAccounts(ObjectMetadata) Then 
				
				Object.SetDeletionMark(True, False);
				
			Else
				Object.SetDeletionMark(True);
				
			EndIf;
			
		ElsIf Action = "DirectDeletion" Then
			
			Object.Delete();
			
		EndIf;
		
	Except
		// Intercepting all reported error messages and merging them into a single exception text.
		ExceptionText = "";
		For Each Message In GetUserMessages(False) Do
			ExceptionText = ExceptionText + Chars.LF + Message.Text;
		EndDo;
		
		// Reporting the previous message.
		If ReportAgain Then
			ReportDeferredMessages(PreviousMessages);
		EndIf;
		
		If ExceptionText = "" Then
			Raise;
		Else
			Raise TrimAll(BriefErrorDescription(ErrorInfo()) + Chars.LF + TrimAll(ExceptionText));
		EndIf;
	EndTry;
	
	If ReportAgain Then
		ReportDeferredMessages(PreviousMessages);
	EndIf;
	
EndProcedure

Procedure ReportDeferredMessages(Val Messages)
	
	For Each Message In Messages Do
		Message.Message();
	EndDo;
	
EndProcedure

Procedure WriteObject(Val Object, Val WriteParameters)
	
	ObjectMetadata = Object.Metadata();
	
	If IsDocument(ObjectMetadata) Then
		ProcessObjectWithMessageInterception(Object, "Write", DocumentWriteMode.Write, WriteParameters);
		Return;
	EndIf;
	
	// Checking for loop references.
	ObjectProperties = New Structure("Hierarchical, ExtDimensionTypes, Owners", False, Undefined, New Array);
	FillPropertyValues(ObjectProperties, ObjectMetadata);
	
	// Checking the parent.
	If ObjectProperties.Hierarchical Or ObjectProperties.ExtDimensionTypes <> Undefined Then 
		
		If Object.Parent = Object.Ref Then
			Raise StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'При записи ""%1"" возникает циклическая ссылка в иерархии.'; en = 'Writing ""%1"" causes an infinite loop in the hierarchy.'; pl = 'Podczas zapisu ""%1"" powstaje odnośnik cykliczny w hierarchii.';de = 'Beim Schreiben von ""%1"" erscheint eine zyklische Referenz in der Hierarchie.';ro = 'Referința circulară în ierarhie apare la înregistrarea ""%1"".';tr = '%1kaydı esnasında hiyerarşide dairesel referans oluşur.'; es_ES = 'Al guardar ""%1"" aparece un enlace cíclico en la jerarquía.'"),
				String(Object));
			EndIf;
			
	EndIf;
	
	// Checking the owner.
	If ObjectProperties.Owners.Count() > 1 AND Object.Owner = Object.Ref Then
		Raise StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'При записи ""%1"" возникает циклическая ссылка в подчинении.'; en = 'Writing ""%1"" causes an infinite loop in the subordination.'; pl = 'Podczas zapisu ""%1"" powstaje odnośnik cykliczny w podporządkowaniu.';de = 'Beim Schreiben von ""%1"" erscheint eine zyklische Referenz in der untergeordneten Ebene.';ro = 'Referința circulară în subordonare apare la înregistrarea ""%1"".';tr = '%1kaydı esnasında alt sıralamada dairesel referans oluşur.'; es_ES = 'Al guardar ""%1"" aparece un enlace cíclico en la subordinación.'"),
			String(Object));
	EndIf;
	
	// For sequences, the Update right can be absent even in the FullAdministrator role.
	If IsSequence(ObjectMetadata)
		AND Not AccessRight("Update", ObjectMetadata)
		AND Users.IsFullUser(,, False) Then
		
		SetPrivilegedMode(True);
	EndIf;
	
	// Only writing.
	ProcessObjectWithMessageInterception(Object, "Write", Undefined, WriteParameters);
EndProcedure

Function RefReplacementEventLogMessageText()
	
	Return NStr("ru='Поиск и удаление ссылок'; en = 'Searching for references and deleting them'; pl = 'Wyszukiwanie i usunięcie linków';de = 'Links suchen und löschen';ro = 'Căutarea și ștergerea referințelor';tr = 'Referansları ara ve sil'; es_ES = 'Búsqueda y eliminación de enlaces'", DefaultLanguageCode());
	
EndFunction

Procedure RegisterReplacementError(Result, Val Ref, Val ErrorDescription)
	
	Result.HasErrors = True;
	
	String = Result.Errors.Add();
	String.Ref = Ref;
	String.ErrorObjectPresentation = ErrorDescription.ErrorObjectPresentation;
	String.ErrorObject               = ErrorDescription.ErrorObject;
	String.ErrorText                = ErrorDescription.ErrorText;
	String.ErrorType                  = ErrorDescription.ErrorType;
	
EndProcedure

Function ReplacementErrorDescription(Val ErrorType, Val ErrorObject, Val ErrorObjectPresentation, Val ErrorText)
	Result = New Structure;
	
	Result.Insert("ErrorType",                  ErrorType);
	Result.Insert("ErrorObject",               ErrorObject);
	Result.Insert("ErrorObjectPresentation", ErrorObjectPresentation);
	Result.Insert("ErrorText",                ErrorText);
	
	Return Result;
EndFunction

Procedure RegisterErrorInTable(Result, Duplicate, Original, Data, Information, ErrorType, ErrorInformation)
	Result.HasErrors = True;
	
	WriteLogEvent(
		RefReplacementEventLogMessageText(),
		EventLogLevel.Error,
		,
		,
		DetailErrorDescription(ErrorInformation));
	
	FullDataPresentation = String(Data) + " (" + Information.ItemPresentation + ")";
	
	Error = Result.Errors.Add();
	Error.Ref       = Duplicate;
	Error.ErrorObject = Data;
	Error.ErrorObjectPresentation = FullDataPresentation;
	
	If ErrorType = "LockForRegister" Then
		NewTemplate = NStr("ru = 'Не удалось начать редактирование %1: %2'; en = 'Cannot start editing %1: %2'; pl = 'Nie udało się rozpocząć edycję %1: %2';de = 'Die Bearbeitung konnte nicht gestartet werden %1:%2';ro = 'Eșec la începutul editării %1: %2';tr = 'Düzenleme başlatılamadı %1: %2'; es_ES = 'No se ha podido empezar a editar %1: %2'");
		Error.ErrorType = "LockError";
	ElsIf ErrorType = "DataLockForDuplicateDeletion" Then
		NewTemplate = NStr("ru = 'Не удалось начать удаление: %2'; en = 'Cannot start deletion: %2'; pl = 'Nie udało się rozpocząć usunięcie: %2';de = 'Deinstallation kann nicht gestartet werden: %2';ro = 'Eșec la începutul ștergerii: %2';tr = 'Silme başlayamadı: %2'; es_ES = 'No se ha podido empezar a eliminar: %2'");
		Error.ErrorType = "LockError";
	ElsIf ErrorType = "DeleteDuplicateSet" Then
		NewTemplate = NStr("ru = 'Не удалось очистить сведения о дубле в %1: %2'; en = 'Cannot clear duplicate''s details in %1: %2'; pl = 'Nie udało się oczyścić informacje o duplikacie w %1: %2';de = 'Fehler beim Löschen doppelter Informationen in %1: %2';ro = 'Eșec la golirea informațiilor despre duplicat în %1: %2';tr = '%1''de kopya bilgisi silinemedi: %2'; es_ES = 'No se ha podido eliminar la información del duplicado en %1: %2'");
		Error.ErrorType = "WritingError";
	ElsIf ErrorType = "WriteOriginalSet" Then
		NewTemplate = NStr("ru = 'Не удалось обновить сведения в %1: %2'; en = 'Cannot update additional data in %1: %2'; pl = 'Nie można zaktualizować dodatkowych danych %1: %2';de = 'Die Informationen in %1 konnten nicht aktualisiert werden: %2';ro = 'Eșec la actualizarea informațiilor în %1: %2';tr = '%1''de bilgiler güncellenemedi: %2'; es_ES = 'No se ha podido actualizar la información en %1: %2'");
		Error.ErrorType = "WritingError";
	Else
		NewTemplate = ErrorType + " (%1): %2";
		Error.ErrorType = ErrorType;
	EndIf;
	
	NewTemplate = NewTemplate + Chars.LF + Chars.LF + NStr("ru = 'Подробности в журнале регистрации.'; en = 'See the event log for details.'; pl = 'Szczegóły w Dzienniku zdarzeń';de = 'Siehe Details im Protokoll.';ro = 'Detalii vezi în Registrul logare.';tr = 'Ayrıntılar için olay günlüğüne bakın.'; es_ES = 'Ver detalles en el registro.'");
	
	BriefPresentation = BriefErrorDescription(ErrorInformation);
	Error.ErrorText = StringFunctionsClientServer.SubstituteParametersToString(NewTemplate, FullDataPresentation, BriefPresentation);
	
EndProcedure

// Generates details on the metadata object type: full name, presentations, kind, and so on.
Function TypeInformation(FullNameOrMetadataOrType, Cache)
	FirstParameterType = TypeOf(FullNameOrMetadataOrType);
	If FirstParameterType = Type("String") Then
		MetadataObject = Metadata.FindByFullName(FullNameOrMetadataOrType);
	Else
		If FirstParameterType = Type("Type") Then // Search for the metadata object.
			MetadataObject = Metadata.FindByType(FullNameOrMetadataOrType);
		Else
			MetadataObject = FullNameOrMetadataOrType;
		EndIf;
	EndIf;
	FullName = Upper(MetadataObject.FullName());
	
	TypesInformation = CommonClientServer.StructureProperty(Cache, "TypesInformation");
	If TypesInformation = Undefined Then
		TypesInformation = New Map;
		Cache.Insert("TypesInformation", TypesInformation);
	Else
		Information = TypesInformation.Get(FullName);
		If Information <> Undefined Then
			Return Information;
		EndIf;
	EndIf;
	
	Information = New Structure("FullName, ItemPresentation, ListPresentation,
	|Kind, Reference, Technical, Separated,
	|Hierarchical,
	|HasSubordinate, SubordinateItemNames,
	|Dimensions, Attributes, Resources");
	TypesInformation.Insert(FullName, Information);
	
	// Fill in basic information.
	Information.FullName = FullName;
	
	// Item and list presentations.
	StandardProperties = New Structure("ObjectPresentation, ExtendedObjectPresentation, ListPresentation, ExtendedListPresentation");
	FillPropertyValues(StandardProperties, MetadataObject);
	If ValueIsFilled(StandardProperties.ObjectPresentation) Then
		Information.ItemPresentation = StandardProperties.ObjectPresentation;
	ElsIf ValueIsFilled(StandardProperties.ExtendedObjectPresentation) Then
		Information.ItemPresentation = StandardProperties.ExtendedObjectPresentation;
	Else
		Information.ItemPresentation = MetadataObject.Presentation();
	EndIf;
	If ValueIsFilled(StandardProperties.ListPresentation) Then
		Information.ListPresentation = StandardProperties.ListPresentation;
	ElsIf ValueIsFilled(StandardProperties.ExtendedListPresentation) Then
		Information.ListPresentation = StandardProperties.ExtendedListPresentation;
	Else
		Information.ListPresentation = MetadataObject.Presentation();
	EndIf;
	
	// Kind and its properties.
	Information.Kind = Left(Information.FullName, StrFind(Information.FullName, ".")-1);
	If Information.Kind = "CATALOG"
		Or Information.Kind = "DOCUMENT"
		Or Information.Kind = "ENUM"
		Or Information.Kind = "CHARTOFCHARACTERISTICTYPES"
		Or Information.Kind = "CHARTOFACCOUNTS"
		Or Information.Kind = "CHARTOFCALCULATIONTYPES"
		Or Information.Kind = "BUSINESSPROCESS"
		Or Information.Kind = "TASK"
		Or Information.Kind = "EXCHANGEPLAN" Then
		Information.Reference = True;
	Else
		Information.Reference = False;
	EndIf;
	
	If Information.Kind = "CATALOG"
		Or Information.Kind = "CHARTOFCHARACTERISTICTYPES" Then
		Information.Hierarchical = MetadataObject.Hierarchical;
	ElsIf Information.Kind = "CHARTOFACCOUNTS" Then
		Information.Hierarchical = True;
	Else
		Information.Hierarchical = False;
	EndIf;
	
	Information.HasSubordinate = False;
	If Information.Kind = "CATALOG"
		Or Information.Kind = "CHARTOFCHARACTERISTICTYPES"
		Or Information.Kind = "EXCHANGEPLAN"
		Or Information.Kind = "CHARTOFACCOUNTS"
		Or Information.Kind = "CHARTOFCALCULATIONTYPES" Then
		For Each Catalog In Metadata.Catalogs Do
			If Catalog.Owners.Contains(MetadataObject) Then
				If Information.HasSubordinate = False Then
					Information.HasSubordinate = True;
					Information.SubordinateItemNames = New Array;
				EndIf;
				Information.SubordinateItemNames.Add(Catalog.FullName());
			EndIf;
		EndDo;
	EndIf;
	
	If Information.FullName = "CATALOG.METADATAOBJECTIDS"
		Or Information.FullName = "CATALOG.PREDEFINEDREPORTSOPTIONS" Then
		Information.Technical = True;
		Information.Separated = False;
	Else
		Information.Technical = False;
		If Not Cache.Property("SaaSModel") Then
			Cache.Insert("SaaSModel", DataSeparationEnabled());
			If Cache.SaaSModel Then
				
				If SubsystemExists("StandardSubsystems.SaaS") Then
					ModuleSaaS = CommonModule("SaaS");
					MainDataSeparator = ModuleSaaS.MainDataSeparator();
					AuxiliaryDataSeparator = ModuleSaaS.AuxiliaryDataSeparator();
				Else
					MainDataSeparator = Undefined;
					AuxiliaryDataSeparator = Undefined;
				EndIf;
				
				Cache.Insert("InDataArea", DataSeparationEnabled() AND SeparatedDataUsageAvailable());
				Cache.Insert("MainDataSeparator",        MainDataSeparator);
				Cache.Insert("AuxiliaryDataSeparator", AuxiliaryDataSeparator);
			EndIf;
		EndIf;
		If Cache.SaaSModel Then
			If SubsystemExists("StandardSubsystems.SaaS") Then
				ModuleSaaS = CommonModule("SaaS");
				IsSeparatedMetadataObject = ModuleSaaS.IsSeparatedMetadataObject(MetadataObject);
			Else
				IsSeparatedMetadataObject = True;
			EndIf;
			Information.Separated = IsSeparatedMetadataObject;
		EndIf;
	EndIf;
	
	Information.Dimensions = New Structure;
	Information.Attributes = New Structure;
	Information.Resources = New Structure;
	
	AttributesKinds = New Structure("StandardAttributes, Attributes, Dimensions, Resources");
	FillPropertyValues(AttributesKinds, MetadataObject);
	For Each KeyAndValue In AttributesKinds Do
		Collection = KeyAndValue.Value;
		If TypeOf(Collection) = Type("MetadataObjectCollection") Then
			WhereToWrite = ?(Information.Property(KeyAndValue.Key), Information[KeyAndValue.Key], Information.Attributes);
			For Each Attribute In Collection Do
				WhereToWrite.Insert(Attribute.Name, AttributeInformation(Attribute));
			EndDo;
		EndIf;
	EndDo;
	If Information.Kind = "INFORMATIONREGISTER"
		AND MetadataObject.InformationRegisterPeriodicity <> Metadata.ObjectProperties.InformationRegisterPeriodicity.Nonperiodical Then
		AttributeInformation = New Structure("Master, Presentation, Format, Type, DefaultValue, FillFromFillingValue");
		AttributeInformation.Master = False;
		AttributeInformation.FillFromFillingValue = False;
		If MetadataObject.InformationRegisterPeriodicity = Metadata.ObjectProperties.InformationRegisterPeriodicity.RecorderPosition Then
			AttributeInformation.Type = New TypeDescription("PointInTime");
		ElsIf MetadataObject.InformationRegisterPeriodicity = Metadata.ObjectProperties.InformationRegisterPeriodicity.Second Then
			AttributeInformation.Type = New TypeDescription("Date", , , New DateQualifiers(DateFractions.DateTime));
		Else
			AttributeInformation.Type = New TypeDescription("Date", , , New DateQualifiers(DateFractions.Date));
		EndIf;
		Information.Dimensions.Insert("Period", AttributeInformation);
	EndIf;
	
	Return Information;
EndFunction

Function AttributeInformation(AttributeMetadata)
	// StandardAttributeDetails
	// MetadataObject: Dimension
	// MetadataObject: Resource
	// MetadataObject: Attribute
	Information = New Structure("Master, Presentation, Format, Type, DefaultValue, FillFromFillingValue");
	FillPropertyValues(Information, AttributeMetadata);
	Information.Presentation = AttributeMetadata.Presentation();
	If Information.FillFromFillingValue = True Then
		If TypeOf(AttributeMetadata) = Type("StandardAttributeDescription")
			Or TypeOf(AttributeMetadata) = Type("MetadataObject") Then
			VarStandardAttributeDetails = AttributeMetadata;
			Information.DefaultValue = VarStandardAttributeDetails.FillValue;
		Else
			Information.DefaultValue = AttributeMetadata.FillingValue;
		EndIf;
	Else
		Information.DefaultValue = AttributeMetadata.Type.AdjustValue();
	EndIf;
	Return Information;
EndFunction

Function IsInternalData(UsageInstance, RefSearchExclusions)
	
	SearchException = RefSearchExclusions[UsageInstance.Metadata];
	
	// The data can be either a reference or a register record key.
	
	If SearchException = Undefined Then
		Return (UsageInstance.Ref = UsageInstance.Data); // Excluding self-reference.
	ElsIf SearchException = "*" Then
		Return True; // Excluding everything.
	Else
		For Each AttributePath In SearchException Do
			// If any exceptions are specified.
			
			// Relative path to the attribute:
			//   "<TabularPartOrAttributeName>[.<TabularPartAttributeName>]".
			
			If IsReference(TypeOf(UsageInstance.Data)) Then 
				
				// Checking whether the excluded path data contains the reference.
				
				FullMetadataObjectName = UsageInstance.Metadata.FullName();
				
				QueryText = 
					"SELECT
					|	TRUE
					|FROM
					|	&FullMetadataObjectName AS Table
					|WHERE
					|	&AttributePath = &RefToCheck
					|	AND Table.Ref = &Ref";
				
				QueryText = StrReplace(QueryText, "&FullMetadataObjectName", FullMetadataObjectName);
				QueryText = StrReplace(QueryText, "&AttributePath", AttributePath);
				
				Query = New Query;
				Query.Text = QueryText;
				Query.SetParameter("RefToCheck", UsageInstance.Ref);
				Query.SetParameter("Ref", UsageInstance.Data);
				
				Result = Query.Execute();
				
				If Not Result.IsEmpty() Then 
					Return True;
				EndIf;
				
			Else 
				
				DataBuffer = New Structure(AttributePath);
				FillPropertyValues(DataBuffer, UsageInstance.Data);
				If DataBuffer[AttributePath] = UsageInstance.Ref Then 
					Return True;
				EndIf;
				
			EndIf;
			
		EndDo;
	EndIf;
	
	Return False;
	
EndFunction

#EndRegion

#Region UsageInstances

Function RecordKeysTypeDetails()
	
	TypesToAdd = New Array;
	For Each Meta In Metadata.InformationRegisters Do
		TypesToAdd.Add(Type("InformationRegisterRecordKey." + Meta.Name));
	EndDo;
	For Each Meta In Metadata.AccumulationRegisters Do
		TypesToAdd.Add(Type("AccumulationRegisterRecordKey." + Meta.Name));
	EndDo;
	For Each Meta In Metadata.AccountingRegisters Do
		TypesToAdd.Add(Type("AccountingRegisterRecordKey." + Meta.Name));
	EndDo;
	For Each Meta In Metadata.CalculationRegisters Do
		TypesToAdd.Add(Type("CalculationRegisterRecordKey." + Meta.Name));
	EndDo;
	
	Return New TypeDescription(TypesToAdd); 
EndFunction

Function RecordSetDimensionsDetails(Val RegisterMetadata, RegisterDimensionCache)
	
	DimensionsDetails = RegisterDimensionCache[RegisterMetadata];
	If DimensionsDetails <> Undefined Then
		Return DimensionsDetails;
	EndIf;
	
	// Period and recorder, if any.
	DimensionsDetails = New Structure;
	
	DimensionData = New Structure("Master, Presentation, Format, Type", False);
	
	If Metadata.InformationRegisters.Contains(RegisterMetadata) Then
		// There might be a period.
		MetaPeriod = RegisterMetadata.InformationRegisterPeriodicity; 
		Periodicity = Metadata.ObjectProperties.InformationRegisterPeriodicity;
		
		If MetaPeriod = Periodicity.RecorderPosition Then
			DimensionData.Type           = Documents.AllRefsType();
			DimensionData.Presentation = NStr("ru='Регистратор'; en = 'Recorder'; pl = 'Dokument';de = 'Recorder';ro = 'Registrator';tr = 'Kayıt'; es_ES = 'Registrador'");
			DimensionData.Master       = True;
			DimensionsDetails.Insert("Recorder", DimensionData);
			
		ElsIf MetaPeriod = Periodicity.Year Then
			DimensionData.Type           = New TypeDescription("Date");
			DimensionData.Presentation = NStr("ru='Период'; en = 'Period'; pl = 'Okres';de = 'Zeitraum';ro = 'Perioadă';tr = 'Dönem'; es_ES = 'Período'");
			DimensionData.Format        = NStr("ru = 'ДФ=''yyyy ""г.""''; ДП=''Дата не задана'''; en = 'DF=''yyyy''; DE=''No date set'''; pl = 'DF=''yyyy ""г.""''; ДП=''Data nie jest ustawiona''';de = 'DF=''yyyy ""g.""''; DP=''Datum nicht festgelegt''';ro = 'DF=''yyyy ""г.""''; ДП=''Data nu este indicată''';tr = 'DF=''yyyy ""yıl.""''; DP=''Tarih belirlenmedi'''; es_ES = 'DF=''yyyy ""г.""''; ДП=''Fecha no establecida'''");
			DimensionsDetails.Insert("Period", DimensionData);
			
		ElsIf MetaPeriod = Periodicity.Day Then
			DimensionData.Type           = New TypeDescription("Date");
			DimensionData.Presentation = NStr("ru='Период'; en = 'Period'; pl = 'Okres';de = 'Zeitraum';ro = 'Perioadă';tr = 'Dönem'; es_ES = 'Período'");
			DimensionData.Format        = NStr("ru = 'ДЛФ=D; ДП=''Дата не задана'''; en = 'DLF=D; DE=''No date set'''; pl = 'DLF=D; ДП=''Data nie jest ustawiona''';de = 'DLF=D; DP=''Datum nicht festgelegt''';ro = 'DLF=D; ДП=''Data nu este indicată''';tr = 'DLF=D; DP=''Tarih belirlenmedi'''; es_ES = 'DLF=D; ДП=''Fecha no establecida'''");
			DimensionsDetails.Insert("Period", DimensionData);
			
		ElsIf MetaPeriod = Periodicity.Quarter Then
			DimensionData.Type           = New TypeDescription("Date");
			DimensionData.Presentation = NStr("ru='Период'; en = 'Period'; pl = 'Okres';de = 'Zeitraum';ro = 'Perioadă';tr = 'Dönem'; es_ES = 'Período'");
			DimensionData.Format        =  NStr("ru = 'ДФ=''к """"квартал """"yyyy """"г.""""''; ДП=''Дата не задана'''; en = 'DF=''""""Q""""q yyyy''; DE=''No date set'''; pl = 'DF=''к """"kwartał """"yyyy """"г.""""''; ДП=''Data nie jest ustawiona''';de = 'DF=""bis """"Quartal""""yyyy """"g.""''''; DP=''Datum nicht festgelegt''';ro = 'DF=''к """"квартал """"yyyy """"г.""""''; ДП=''Data nu este indicată''';tr = 'DF=''k """"üç ay """"yyyy """"yıl.""""''; DP=''Tarih belirlenmedi'''; es_ES = 'DF=''к """"trimestre """"yyyy """"г.""""''; ДП=''Fecha no establecida'''");
			DimensionsDetails.Insert("Period", DimensionData);
			
		ElsIf MetaPeriod = Periodicity.Month Then
			DimensionData.Type           = New TypeDescription("Date");
			DimensionData.Presentation = NStr("ru='Период'; en = 'Period'; pl = 'Okres';de = 'Zeitraum';ro = 'Perioadă';tr = 'Dönem'; es_ES = 'Período'");
			DimensionData.Format        = NStr("ru = 'ДФ=''ММММ yyyy """"г.""""''; ДП=''Дата не задана'''; en = 'DF=''MMMM yyyy''; DE=''No date set'''; pl = 'DF=''ММММ yyyy """"г.""""''; ДП=''Data nie jest ustawiona''';de = 'DF=''MMMM yyyy """"g.""""; DP=''Datum nicht festgelegt''';ro = 'DF=''ММММ yyyy """"г.""""''; ДП=''Data nu este indicată''';tr = 'DF=''MMMM yyyy """"yıl.""""''; DP=''Tarih belirlenmedi'''; es_ES = 'DF=''ММММ yyyy """"г.""""''; ДП=''Fecha no establecida'''");
			DimensionsDetails.Insert("Period", DimensionData);
			
		ElsIf MetaPeriod = Periodicity.Second Then
			DimensionData.Type           = New TypeDescription("Date");
			DimensionData.Presentation = NStr("ru='Период'; en = 'Period'; pl = 'Okres';de = 'Zeitraum';ro = 'Perioadă';tr = 'Dönem'; es_ES = 'Período'");
			DimensionData.Format        = NStr("ru = 'ДЛФ=DT; ДП=''Дата не задана'''; en = 'DLF=DT; DE=''No date set'''; pl = 'DLF=DT; DE=''Data nie jest ustawiona''';de = 'DLF=DT; DP=''Datum nicht festgelegt''';ro = 'ДЛФ=DT; ДП=''Data nu este indicată''';tr = 'DLF=DT; DP=''Tarih belirlenmedi'''; es_ES = 'ДЛФ=DT; ДП=''Fecha no establecida'''");
			DimensionsDetails.Insert("Period", DimensionData);
			
		EndIf;
		
	Else
		DimensionData.Type           = Documents.AllRefsType();
		DimensionData.Presentation = NStr("ru='Регистратор'; en = 'Recorder'; pl = 'Dokument';de = 'Recorder';ro = 'Registrator';tr = 'Kayıt'; es_ES = 'Registrador'");
		DimensionData.Master       = True;
		DimensionsDetails.Insert("Recorder", DimensionData);
		
	EndIf;
	
	// All dimensions.
	For Each MetaDimension In RegisterMetadata.Dimensions Do
		DimensionData = New Structure("Master, Presentation, Format, Type");
		DimensionData.Type           = MetaDimension.Type;
		DimensionData.Presentation = MetaDimension.Presentation();
		DimensionData.Master       = MetaDimension.Master;
		DimensionsDetails.Insert(MetaDimension.Name, DimensionData);
	EndDo;
	
	RegisterDimensionCache[RegisterMetadata] = DimensionsDetails;
	Return DimensionsDetails;
	
EndFunction

#EndRegion

#EndRegion

#Region ConditionCalls

// Returns a server manager module by object name.
Function ServerManagerModule(Name)
	ObjectFound = False;
	
	NameParts = StrSplit(Name, ".");
	If NameParts.Count() = 2 Then
		
		KindName = Upper(NameParts[0]);
		ObjectName = NameParts[1];
		
		If KindName = Upper("Constants") Then
			If Metadata.Constants.Find(ObjectName) <> Undefined Then
				ObjectFound = True;
			EndIf;
		ElsIf KindName = Upper("InformationRegisters") Then
			If Metadata.InformationRegisters.Find(ObjectName) <> Undefined Then
				ObjectFound = True;
			EndIf;
		ElsIf KindName = Upper("AccumulationRegisters") Then
			If Metadata.AccumulationRegisters.Find(ObjectName) <> Undefined Then
				ObjectFound = True;
			EndIf;
		ElsIf KindName = Upper("AccountingRegisters") Then
			If Metadata.AccountingRegisters.Find(ObjectName) <> Undefined Then
				ObjectFound = True;
			EndIf;
		ElsIf KindName = Upper("CalculationRegisters") Then
			If Metadata.CalculationRegisters.Find(ObjectName) <> Undefined Then
				ObjectFound = True;
			EndIf;
		ElsIf KindName = Upper("Catalogs") Then
			If Metadata.Catalogs.Find(ObjectName) <> Undefined Then
				ObjectFound = True;
			EndIf;
		ElsIf KindName = Upper("Documents") Then
			If Metadata.Documents.Find(ObjectName) <> Undefined Then
				ObjectFound = True;
			EndIf;
		ElsIf KindName = Upper("Reports") Then
			If Metadata.Reports.Find(ObjectName) <> Undefined Then
				ObjectFound = True;
			EndIf;
		ElsIf KindName = Upper("DataProcessors") Then
			If Metadata.DataProcessors.Find(ObjectName) <> Undefined Then
				ObjectFound = True;
			EndIf;
		ElsIf KindName = Upper("BusinessProcesses") Then
			If Metadata.BusinessProcesses.Find(ObjectName) <> Undefined Then
				ObjectFound = True;
			EndIf;
		ElsIf KindName = Upper("DocumentJournals") Then
			If Metadata.DocumentJournals.Find(ObjectName) <> Undefined Then
				ObjectFound = True;
			EndIf;
		ElsIf KindName = Upper("Tasks") Then
			If Metadata.Tasks.Find(ObjectName) <> Undefined Then
				ObjectFound = True;
			EndIf;
		ElsIf KindName = Upper("ChartsOfAccounts") Then
			If Metadata.ChartsOfAccounts.Find(ObjectName) <> Undefined Then
				ObjectFound = True;
			EndIf;
		ElsIf KindName = Upper("ExchangePlans") Then
			If Metadata.ExchangePlans.Find(ObjectName) <> Undefined Then
				ObjectFound = True;
			EndIf;
		ElsIf KindName = Upper("ChartsOfCharacteristicTypes") Then
			If Metadata.ChartsOfCharacteristicTypes.Find(ObjectName) <> Undefined Then
				ObjectFound = True;
			EndIf;
		ElsIf KindName = Upper("ChartsOfCalculationTypes") Then
			If Metadata.ChartsOfCalculationTypes.Find(ObjectName) <> Undefined Then
				ObjectFound = True;
			EndIf;
		EndIf;
		
	EndIf;
	
	If Not ObjectFound Then
		Raise StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Объект метаданных ""%1"" не найден,
			           |либо для него не поддерживается получение модуля менеджера.'; 
			           |en = 'Metadata object ""%1"" is not found
			           |or it does not support getting manager modules.'; 
			           |pl = 'Obiekt metadanych ""%1"" nie znaleziono,
			           |albo dla niego nie jest obsługiwane otrzymanie modułu menedżera.';
			           |de = 'Das Metadatenobjekt ""%1"" wird nicht gefunden 
			           |oder es wird nicht unterstützt, um das Manager-Modul zu empfangen.';
			           |ro = 'Obiectul de metadate ""%1"" nu a fost găsit,
			           |sau pentru el nu este susținută obținerea modulului managerului.';
			           |tr = '""%1"" Meta veri nesnesi bulunamadı 
			           |veya yönetici modül alımı bunun için desteklenmiyor.'; 
			           |es_ES = 'El objeto de metadatos ""%1"" no encontrado,
			           |o el recibo del módulo de gerente no se admite para él.'"),
			Name);
	EndIf;
	
	// ACC:488-disable CalculateInSafeMode is not used, to avoid calling CommonModule recursively.
	SetSafeMode(True);
	Module = Eval(Name);
	// ACC:488-enable
	
	Return Module;
EndFunction

#EndRegion

#Region Data

Function ColumnsToCompare(Val RowsCollection, Val ColumnsNames, Val ExcludingColumns)
	
	If IsBlankString(ColumnsNames) Then
		
		CollectionType = TypeOf(RowsCollection);
		IsValueList = (CollectionType = Type("ValueList"));
		IsValueTable = (CollectionType = Type("ValueTable"));
		IsKeyAndValueCollection = (CollectionType = Type("Map"))
			Or (CollectionType = Type("Structure"))
			Or (CollectionType = Type("FixedMap"))
			Or (CollectionType = Type("FixedStructure"));
		
		ColumnsToCompare = New Array;
		If IsValueTable Then
			For Each Column In RowsCollection.Columns Do
				ColumnsToCompare.Add(Column.Name);
			EndDo;
		ElsIf IsValueList Then
			ColumnsToCompare.Add("Value");
			ColumnsToCompare.Add("Picture");
			ColumnsToCompare.Add("Check");
			ColumnsToCompare.Add("Presentation");
		ElsIf IsKeyAndValueCollection Then
			ColumnsToCompare.Add("Key");
			ColumnsToCompare.Add("Value");
		Else	
			Raise StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'Для коллекции типа %1 необходимо указать имена полей, по которым производится сравнение в ОбщегоНазначения.КоллекцииИдентичны'; en = 'For collections of the %1 type, the Common.CollectionsIdentical function requires names of the fields to compare.'; pl = 'Podaj nazwy pól do porównania dla kolekcji typu %1 w Common.CollectionsIdentical';de = 'Für eine Typensammlung %1 müssen die Namen der Felder angegeben werden, anhand derer der Vergleich in Common.CollectionsIdentical durchgeführt wird';ro = 'Pentru colecția de tipul %1 trebuie să specificați numele câmpurilor pentru comparație în Common.CollectionsIdentical';tr = '%1Tür koleksiyonu için Common.CollectionsIdentical karşılaştırılacak alan adlarını belirtin '; es_ES = 'Para colección del tipo %1 es necesario indicar los nombres de campos por los que se hace la comparación en Common.CollectionsIdentical'"),
				CollectionType);
		EndIf;
	Else
		ColumnsToCompare = StrSplit(StrReplace(ColumnsNames, " ", ""), ",");
	EndIf;
	
	// Removing excluded columns
	If Not IsBlankString(ExcludingColumns) Then
		ExcludingColumns = StrSplit(StrReplace(ExcludingColumns, " ", ""), ",");
		ColumnsToCompare = CommonClientServer.ArraysDifference(ColumnsToCompare, ExcludingColumns);
	EndIf;	
	Return ColumnsToCompare;

EndFunction

Function SequenceSensitiveToCompare(Val RowsCollection1, Val RowsCollection2, Val ColumnsToCompare)
	
	CollectionType = TypeOf(RowsCollection1);
	ArraysCompared = (CollectionType = Type("Array") Or CollectionType = Type("FixedArray"));
	
	// Iterating both collections in parallel.
	Collection1RowNumber = 0;
	For Each Collection1Row In RowsCollection1 Do
		// Searching for the same row in the second collection.
		Collection2RowNumber = 0;
		HasCollection2Rows = False;
		For Each Collection2Row In RowsCollection2 Do
			HasCollection2Rows = True;
			If Collection2RowNumber = Collection1RowNumber Then
				Break;
			EndIf;
			Collection2RowNumber = Collection2RowNumber + 1;
		EndDo;
		If Not HasCollection2Rows Then
			// Second collection has no rows.
			Return False;
		EndIf;
		// Comparing field values for two rows.
		If ArraysCompared Then
			If Collection1Row <> Collection2Row Then
				Return False;
			EndIf;
		Else
			For Each ColumnName In ColumnsToCompare Do
				If Collection1Row[ColumnName] <> Collection2Row[ColumnName] Then
					Return False;
				EndIf;
			EndDo;
		EndIf;
		Collection1RowNumber = Collection1RowNumber + 1;
	EndDo;
	
	Collection1RowCount = Collection1RowNumber;
	
	// Calculating rows in the second collection.
	Collection2RowCount = 0;
	For Each Collection2Row In RowsCollection2 Do
		Collection2RowCount = Collection2RowCount + 1;
	EndDo;
	
	// If the first collection has no rows, he second collection must have no rows as well.
	// 
	If Collection1RowCount = 0 Then
		For Each Collection2Row In RowsCollection2 Do
			Return False;
		EndDo;
		Collection2RowCount = 0;
	EndIf;
	
	// Number of rows must be equal in both collections.
	If Collection1RowCount <> Collection2RowCount Then
		Return False;
	EndIf;
	
	Return True;
	
EndFunction

Function SequenceIgnoreSensitiveToCompare(Val RowsCollection1, Val RowsCollection2, Val ColumnsToCompare)
	
	// Accumulating compared rows in the first collection to ensure the following:
	//  - The search for identical rows is only performed once.
	//  - All accumulated rows exist in the second collection.
	
	FilterRows = New ValueTable;
	FilterParameters = New Structure;
	For Each ColumnName In ColumnsToCompare Do
		FilterRows.Columns.Add(ColumnName);
		FilterParameters.Insert(ColumnName);
	EndDo;
	
	HasCollection1Rows = False;
	For Each FIlterRow In RowsCollection1 Do
		
		FillPropertyValues(FilterParameters, FIlterRow);
		If FilterRows.FindRows(FilterParameters).Count() > 0 Then
			// The row with such field values is already checked.
			Continue;
		EndIf;
		FillPropertyValues(FilterRows.Add(), FIlterRow);
		
		// Calculating the number of such rows in the first collection.
		Collection1RowsFound = 0;
		For Each Collection1Row In RowsCollection1 Do
			RowFits = True;
			For Each ColumnName In ColumnsToCompare Do
				If Collection1Row[ColumnName] <> FIlterRow[ColumnName] Then
					RowFits = False;
					Break;
				EndIf;
			EndDo;
			If RowFits Then
				Collection1RowsFound = Collection1RowsFound + 1;
			EndIf;
		EndDo;
		
		// Calculating the number of such rows in the second collection.
		Collection2RowsFound = 0;
		For Each Collection2Row In RowsCollection2 Do
			RowFits = True;
			For Each ColumnName In ColumnsToCompare Do
				If Collection2Row[ColumnName] <> FIlterRow[ColumnName] Then
					RowFits = False;
					Break;
				EndIf;
			EndDo;
			If RowFits Then
				Collection2RowsFound = Collection2RowsFound + 1;
				// If the number of rows in the second collection is greater then the number of rows in the first 
				// one, the collections are not equal.
				If Collection2RowsFound > Collection1RowsFound Then
					Return False;
				EndIf;
			EndIf;
		EndDo;
		
		// The number of rows must be equal for both collections.
		If Collection1RowsFound <> Collection2RowsFound Then
			Return False;
		EndIf;
		
		HasCollection1Rows = True;
		
	EndDo;
	
	// If the first collection has no rows, he second collection must have no rows as well.
	// 
	If Not HasCollection1Rows Then
		For Each Collection2Row In RowsCollection2 Do
			Return False;
		EndDo;
	EndIf;
	
	// Checking that all accumulated rows exist in the second collection.
	For Each Collection2Row In RowsCollection2 Do
		FillPropertyValues(FilterParameters, Collection2Row);
		If FilterRows.FindRows(FilterParameters).Count() = 0 Then
			Return False;
		EndIf;
	EndDo;
	Return True;
	
EndFunction		

Function CompareArrays(Val Array1, Val Array2)
	
	If Array1.Count() <> Array2.Count() Then
		Return False;
	EndIf;
	
	For Each Item In Array1 Do
		If Array2.Find(Item) = Undefined Then
			Return False;
		EndIf;
	EndDo;
	
	Return True;
	
EndFunction		

Procedure CheckFixedData(Data, DataInFixedTypeValue = False)
	
	DataType = TypeOf(Data);
	
	If DataType = Type("ValueStorage")
	 OR DataType = Type("FixedArray")
	 OR DataType = Type("FixedStructure")
	 OR DataType = Type("FixedMap") Then
		
		Return;
	EndIf;
	
	If DataInFixedTypeValue Then
		
		If DataType = Type("Boolean")
		 OR DataType = Type("String")
		 OR DataType = Type("Number")
		 OR DataType = Type("Date")
		 OR DataType = Type("Undefined")
		 OR DataType = Type("UUID")
		 OR DataType = Type("Null")
		 OR DataType = Type("Type")
		 OR DataType = Type("ValueStorage")
		 OR DataType = Type("CommonModule")
		 OR DataType = Type("MetadataObject")
		 OR DataType = Type("XDTOValueType")
		 OR DataType = Type("XDTOObjectType")
		 OR IsReference(DataType) Then
			
			Return;
		EndIf;
	EndIf;
	
	Raise StringFunctionsClientServer.SubstituteParametersToString(
		NStr("ru = 'Ошибка в функции ФиксированныеДанные общего модуля ОбщегоНазначения.
		           |Данные типа ""%1"" не могут быть зафиксированы.'; 
		           |en = 'Error occurred in the Common.FixedData function.
		           |Cannot fix data of the %1 type.'; 
		           |pl = 'Błąd w funkcji FixedData ogólnego modułu Common.
		           |Dane typu ""%1"" nie mogą być zarejestrowane.';
		           |de = 'Fehler in der Funktion FixedData des allgemeinen Moduls Common.
		           |Daten des Typs ""%1"" können nicht behoben werden.';
		           |ro = 'Eroare în funcția FixedData a modulului comun Common.
		           |Datele de tipul ""%1"" nu pot fi fixate.';
		           |tr = 'Common ortak modülünün FixedData işlevinde bir hata oluştu. ""%1"" türün verileri 
		           |kaydedilemez.'; 
		           |es_ES = 'Error en la función FixedData del módulo Common.
		           |Datos del ""%1"" tipo no pueden arreglarse.'"),
		String(DataType) );
	
EndProcedure

#Region CopyRecursive

Function CopyStructure(SourceStructure, FixData)
	
	ResultingStructure = New Structure;
	
	For Each KeyAndValue In SourceStructure Do
		ResultingStructure.Insert(KeyAndValue.Key, CopyRecursive(KeyAndValue.Value, FixData));
	EndDo;
	
	If FixData = True 
		Or FixData = Undefined
		AND TypeOf(SourceStructure) = Type("FixedStructure") Then 
		
		Return New FixedStructure(ResultingStructure);
	EndIf;
	
	Return ResultingStructure;
	
EndFunction

Function CopyMap(SourceMap, FixData)
	
	ResultingMap = New Map;
	
	For Each KeyAndValue In SourceMap Do
		ResultingMap.Insert(KeyAndValue.Key, CopyRecursive(KeyAndValue.Value, FixData));
	EndDo;
	
	If FixData = True 
		Or FixData = Undefined
		AND TypeOf(SourceMap) = Type("FixedMap") Then 
		Return New FixedMap(ResultingMap);
	EndIf;
	
	Return ResultingMap;
	
EndFunction

Function CopyArray(SourceArray, FixData)
	
	ResultingArray = New Array;
	
	For Each Item In SourceArray Do
		ResultingArray.Add(CopyRecursive(Item, FixData));
	EndDo;
	
	If FixData = True 
		Or FixData = Undefined
		AND TypeOf(SourceArray) = Type("FixedArray") Then 
		Return New FixedArray(ResultingArray);
	EndIf;
	
	Return ResultingArray;
	
EndFunction

Function CopyValueList(SourceList, FixData)
	
	ResultingList = New ValueList;
	
	For Each ListItem In SourceList Do
		ResultingList.Add(
			CopyRecursive(ListItem.Value, FixData), 
			ListItem.Presentation, 
			ListItem.Check, 
			ListItem.Picture);
	EndDo;
	
	Return ResultingList;
	
EndFunction

#EndRegion

#EndRegion

#Region AddIns

// Checking extension and configuration metadata for the template.
//
// Parameters:
//  FullTemplateName - String - template's full name.
//
// Returns:
//  Boolean - indicates whether the template exists.
//
Function TemplateExists(FullTemplateName)
	
	Template = Metadata.FindByFullName(FullTemplateName);
	If TypeOf(Template) = Type("MetadataObject") Then 
		
		Pattern = New Structure("TemplateType");
		FillPropertyValues(Pattern, Template);
		TemplateType = Undefined;
		If Pattern.Property("TemplateType", TemplateType) Then 
			Return TemplateType <> Undefined;
		EndIf;
		
	EndIf;
	
	Return False;
	
EndFunction

#EndRegion

#Region SettingsStorage

Procedure StorageSave(StorageManager, ObjectKey, SettingsKey, Settings,
			SettingsDetails, Username, UpdateCachedValues)
	
	If Not AccessRight("SaveUserData", Metadata) Then
		Return;
	EndIf;
	
	StorageManager.Save(ObjectKey, SettingsKey(SettingsKey), Settings,
		SettingsDetails, Username);
	
	If UpdateCachedValues Then
		RefreshReusableValues();
	EndIf;
	
EndProcedure

Function StorageLoad(StorageManager, ObjectKey, SettingsKey, DefaultValue,
			SettingsDetails, Username)
	
	Result = Undefined;
	
	If AccessRight("SaveUserData", Metadata) Then
		Result = StorageManager.Load(ObjectKey, SettingsKey(SettingsKey),
			SettingsDetails, Username);
	EndIf;
	
	If Result = Undefined Then
		Result = DefaultValue;
	Else
		SetPrivilegedMode(True);
		If DeleteInvalidRefs(Result) Then
			Result = DefaultValue;
		EndIf;
	EndIf;
	
	Return Result;
	
EndFunction

// Deletes dead references from a variable.
//
// Parameters:
//   RefOrCollection - AnyReference, Arbitrary - An object or collection to be cleaned up.
//
// Returns:
//   Boolean:
//       * True - If the RefOrCollection of a reference type and the object are not found in the infobase.
//       * False - If the RefOrCollection of a reference type or the object are found in the infobase.
//
Function DeleteInvalidRefs(RefOrCollection)
	
	Type = TypeOf(RefOrCollection);
	
	If Type = Type("Undefined")
		Or Type = Type("Boolean")
		Or Type = Type("String")
		Or Type = Type("Number")
		Or Type = Type("Date") Then // Optimization - frequently used primitive types.
		
		Return False; // Not a reference.
		
	ElsIf Type = Type("Array") Then
		
		Count = RefOrCollection.Count();
		For Number = 1 To Count Do
			ReverseIndex = Count - Number;
			Value = RefOrCollection[ReverseIndex];
			If DeleteInvalidRefs(Value) Then
				RefOrCollection.Delete(ReverseIndex);
			EndIf;
		EndDo;
		
		Return False; // Not a reference.
		
	ElsIf Type = Type("Structure")
		Or Type = Type("Map") Then
		
		For Each KeyAndValue In RefOrCollection Do
			Value = KeyAndValue.Value;
			If DeleteInvalidRefs(Value) Then
				RefOrCollection.Insert(KeyAndValue.Key, Undefined);
			EndIf;
		EndDo;
		
		Return False; // Not a reference.
		
	ElsIf Documents.AllRefsType().ContainsType(Type)
		Or Catalogs.AllRefsType().ContainsType(Type)
		Or Enums.AllRefsType().ContainsType(Type)
		Or ChartsOfCharacteristicTypes.AllRefsType().ContainsType(Type)
		Or ChartsOfAccounts.AllRefsType().ContainsType(Type)
		Or ChartsOfCalculationTypes.AllRefsType().ContainsType(Type)
		Or ExchangePlans.AllRefsType().ContainsType(Type)
		Or BusinessProcesses.AllRefsType().ContainsType(Type)
		Or Tasks.AllRefsType().ContainsType(Type) Then
		// Reference type except BusinessProcessRoutePointRef.
		
		If RefOrCollection.IsEmpty() Then
			Return False; // Blank reference.
		ElsIf ObjectAttributeValue(RefOrCollection, "Ref") = Undefined Then
			RefOrCollection = Undefined;
			Return True; // Dead reference.
		Else
			Return False; // The object is found.
		EndIf;
		
	Else
		
		Return False; // Not a reference.
		
	EndIf;
	
EndFunction

Procedure StorageDelete(StorageManager, ObjectKey, SettingsKey, Username)
	
	If AccessRight("SaveUserData", Metadata) Then
		StorageManager.Delete(ObjectKey, SettingsKey(SettingsKey), Username);
	EndIf;
	
EndProcedure

// Returns a settings key string with the length within 128 character limit.
// If the string exceeds 128 characters, the part after 96 characters is ignored and MD5 hash sum 
// (32 characters long) is returned instead.
//
// Parameters:
//  String - String -  string of any number of characters.
//
// Returns:
//  String - must not exceed 128 characters.
//
Function SettingsKey(Val Row)
	Return TrimStringUsingChecksum(Row, 128);
EndFunction

#EndRegion

#Region SecureDataStorage

Function DataFromSecureStorage(Owner, SecureDataStorageName, varKey)
	
	Result = New Structure(varKey);
	
	Query = New Query;
	Query.Text = 
	"SELECT
	|	SafeDataStorage.Data AS Data
	|FROM
	|	InformationRegister." + SecureDataStorageName + " AS SafeDataStorage
	|WHERE
	|	SafeDataStorage.Owner = &Owner";
	
	Query.SetParameter("Owner", Owner);
	QueryResult = Query.Execute().Select();
	
	If QueryResult.Next() Then
		If ValueIsFilled(QueryResult.Data) Then
			SavedData = QueryResult.Data.Get();
			If ValueIsFilled(SavedData) Then
				FillPropertyValues(Result, SavedData);
			EndIf;
		EndIf;
	EndIf;
	
	Return Result;
EndFunction

#EndRegion

#Region ExternalCodeSecureExecution

// Checks whether the passed ProcedureName is the name of a configuration export procedure.
// Can be used for checking whether the passed string does not contain an arbitrary algorithm in the 
// 1C:Enterprise in-built language before using it in the Execute and Evaluate operators upon the 
// dynamic call of the configuration code methods.
//
// If the passed string is not a procedure name, an exception is generated.
//
// It is intended to be called from ExecuteConfigurationMethod procedure.
//
// Parameters:
//   ProcedureName - String - the export procedure name to be checked.
//
Procedure CheckConfigurationProcedureName(Val ProcedureName)
	
	NameParts = StrSplit(ProcedureName, ".");
	If NameParts.Count() <> 2 AND NameParts.Count() <> 3 Then
		Raise StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Неправильный формат параметра ИмяПроцедуры (передано значение: ""%1"") в ОбщегоНазначения.ВыполнитьМетодКонфигурации'; en = 'Invalid format of ProcedureName parameter (passed value: ""%1"") in Common.ExecuteConfigurationMethod.'; pl = 'Nieprawidłowe ustawienie parametru ProcedureName (przekazał wartość: ""%1"")do Common.ExecuteConfigurationMethod';de = 'Falsches Format des Parameters ProcedureName (übergeben den Wert: ""%1"") in Common.ExecuteConfigurationMethod';ro = 'Format incorect al parametrului ProcedureName (a fost transmisă valoarea: ""%1"") în Common.ExecuteConfigurationMethod';tr = 'Common.ExecuteConfigurationMethod ''de ProcedureName parametresinin biçimi yanlıştır (""%1"" değeri aktarıldı)'; es_ES = 'Formato incorrecto del parámetro ProcedureName (ha trasmitido el valor: ""%1"") en Common.ExecuteConfigurationMethod.'"), ProcedureName);
	EndIf;
	
	ObjectName = NameParts[0];
	If NameParts.Count() = 2 AND Metadata.CommonModules.Find(ObjectName) = Undefined Then
		Raise StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Неправильный формат параметра ИмяПроцедуры (передано значение: ""%1"") в ОбщегоНазначения.ВыполнитьМетодКонфигурации:
				|Не найден общий модуль ""%2"".'; 
				|en = 'Invalid format of ProcedureName parameter (passed value: ""%1"") in Common.ExecuteConfigurationMethod.
				|Common module ""%2"" is not found.'; 
				|pl = 'Niepoprawny format parametrów ProcedureName (przekazano wartość: ""%1"") do Common.ExecuteConfigurationMethod:
				|Nie jest znaleziony ogólny moduł ""%2"".';
				|de = 'Falsches Format des Parameters ProcedureName (übergeben den Wert: ""%1"") in Common.ExecuteConfigurationMethod:
				|Kein gemeinsames Modul ""%2"" gefunden';
				|ro = 'Format incorect al parametrului ProcedureName (a fost transmisă valoarea: ""%1"") în Common.ExecuteConfigurationMethod:
				|Nu a fost găsit modulul comun ""%2"".';
				|tr = 'Common.ExecuteConfigurationMethod ''de ProcedureName parametresinin biçimi yanlıştır (""%1"" değeri aktarıldı): 
				| ""%2"" Ortak modül bulunamadı.'; 
				|es_ES = 'Formato incorrecto del parámetro ProcedureName (transmitido el valor: ""%1"") en Common.ExecuteConfigurationMethod:
				|No se ha encontrado el módulo común ""%2"".'"),
			ProcedureName,
			ObjectName);
	EndIf;
	
	If NameParts.Count() = 3 Then
		FullObjectName = NameParts[0] + "." + NameParts[1];
		Try
			Manager = ObjectManagerByName(FullObjectName);
		Except
			Manager = Undefined;
		EndTry;
		If Manager = Undefined Then
			Raise StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'Неправильный формат параметра ИмяПроцедуры (передано значение: ""%1"") в ОбщегоНазначения.ВыполнитьМетодКонфигурации:
				           |Не найден менеджер объекта ""%2"".'; 
				           |en = 'Invalid format of ProcedureName parameter (passed value: ""%1"") in Common.ExecuteConfigurationMethod:
				           |Manager of ""%2"" object is not found.'; 
				           |pl = 'Niepoprawny format parametrów ProcedureName (przekazano wartość: ""%1"") do Common.ExecuteConfigurationMethod:
				           |Nie jest znaleziony menedżer obiektu ""%2"".';
				           |de = 'Falsches Format des Parameters ProcedureName (übergeben den Wert: ""%1"") in Common.ExecuteConfigurationMethod:
				           |Der Manager des Objekts ""%2"" wurde nicht gefunden.';
				           |ro = 'Format incorect al parametrului ProcedureName (a fost transmisă valoarea: ""%1"") în Common.ExecuteConfigurationMethod:
				           |Nu a fost găsit managerul obiectului ""%2"".';
				           |tr = 'Common.ExecuteConfigurationMethod ''de ProcedureName parametresinin biçimi yanlıştır (""%1"" değeri aktarıldı): 
				           | ""%2"" Nesne yöneticisi bulunamadı.'; 
				           |es_ES = 'Formato incorrecto del parámetro ProcedureName (transmitido el valor: ""%1"") en Common.ExecuteConfigurationMethod:
				           |No se ha encontrado el gerente del objeto ""%2"".'"),
				ProcedureName,
				FullObjectName);
		EndIf;
	EndIf;
	
	ObjectMethodName = NameParts[NameParts.UBound()];
	TempStructure = New Structure;
	Try
		// Checking whether the ProcedureName is a valid ID.
		// For example: MyProcedure.
		TempStructure.Insert(ObjectMethodName);
	Except
		WriteLogEvent(NStr("ru = 'Безопасное выполнение метода'; en = 'Executing method in safe mode'; pl = 'Bezpieczne wykonanie metody';de = 'Das Verfahren wird sicher durchgeführt';ro = 'Executarea securizată a metodei';tr = 'Yöntem güvenli bir şekilde gerçekleştirildi'; es_ES = 'Método se ha realizado de forma segura'", DefaultLanguageCode()),
			EventLogLevel.Error, , , DetailErrorDescription(ErrorInfo()));
		Raise StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Неправильный формат параметра ИмяПроцедуры (передано значение: ""%1"") в ОбщегоНазначения.ВыполнитьМетодКонфигурации:
			           |Имя метода ""%2"" не соответствует требованиям образования имен процедур и функций.'; 
			           |en = 'Invalid format of ProcedureName parameter (passed value: ""%1"") in Common.ExecuteConfigurationMethod.
			           |Method name %2 does not comply with the procedure and function naming convention.'; 
			           |pl = 'Niepoprawny format parametrów ProcedureName (przekazano wartość: ""%1"") do Common.ExecuteConfigurationMethod:
			           |Nazwa metody ""%2"" nie odpowiada wymaganiom tworzenia nazw procedur i funkcji.';
			           |de = 'Falsches Format des Parameters ProcedureName (übergeben den Wert: ""%1"") in Common.ExecuteConfigurationMethod:
			           |Der Name der Methode ""%2"" erfüllt nicht die Anforderungen an die Bildung von Prozedur- und Funktionsnamen.';
			           |ro = 'Format incorect al parametrului ProcedureName (a fost transmisă valoarea: ""%1"") în Common.ExecuteConfigurationMethod:
			           |Numele metodei ""%2"" nu corespunde cerințelor de formare a numelor procedurilor și funcțiilor.';
			           |tr = 'Common.ExecuteConfigurationMethod ''de ProcedureName parametresinin biçimi yanlıştır (""%1"" değeri aktarıldı): 
			           | ""%2"" Yöntem adı prosedür ve işlev isimlerini oluşturma gereksinimlerine uygun değildir.'; 
			           |es_ES = 'Formato incorrecto del parámetro ProcedureName (transmitido el valor: ""%1"") en Common.ExecuteConfigurationMethod:
			           |Nombre del método ""%2"" o corresponde a las exigencias de generar los nombres de los procedimientos y funciones.'"),
			ProcedureName, ObjectMethodName);
	EndTry;
	
EndProcedure

// Returns an object manager by name.
// Restriction: does not process business process route points.
//
// Parameters:
//  Name - String - name, for example Catalog, Catalogs, or Catalog.Companies.
//
// Returns:
//  CatalogsManager, CatalogManager, DocumentsManager, DocumentManager, ...
// 
Function ObjectManagerByName(Name)
	Var MOClass, MetadataObjectName, Manager;
	
	NameParts = StrSplit(Name, ".");
	
	If NameParts.Count() > 0 Then
		MOClass = Upper(NameParts[0]);
	EndIf;
	
	If NameParts.Count() > 1 Then
		MetadataObjectName = NameParts[1];
	EndIf;
	
	If      MOClass = "EXCHANGEPLAN"
	 Or      MOClass = "EXCHANGEPLANS" Then
		Manager = ExchangePlans;
		
	ElsIf MOClass = "CATALOG"
	      Or MOClass = "CATALOGS" Then
		Manager = Catalogs;
		
	ElsIf MOClass = "DOCUMENT"
	      Or MOClass = "DOCUMENTS" Then
		Manager = Documents;
		
	ElsIf MOClass = "DOCUMENTJOURNAL"
	      Or MOClass = "DOCUMENTJOURNALS" Then
		Manager = DocumentJournals;
		
	ElsIf MOClass = "ENUM"
	      Or MOClass = "ENUMS" Then
		Manager = Enums;
		
	ElsIf MOClass = "COMMONMODULE"
	      Or MOClass = "COMMONMODULES" Then
		
		Return CommonModule(MetadataObjectName);
		
	ElsIf MOClass = "REPORT"
	      Or MOClass = "REPORTS" Then
		Manager = Reports;
		
	ElsIf MOClass = "DATAPROCESSOR"
	      Or MOClass = "DATAPROCESSORS" Then
		Manager = DataProcessors;
		
	ElsIf MOClass = "CHARTOFCHARACTERISTICTYPES"
	      Or MOClass = "CHARTSOFCHARACTERISTICTYPES" Then
		Manager = ChartsOfCharacteristicTypes;
		
	ElsIf MOClass = "CHARTOFACCOUNTS"
	      Or MOClass = "CHARTSOFACCOUNTS" Then
		Manager = ChartsOfAccounts;
		
	ElsIf MOClass = "CHARTOFCALCULATIONTYPES"
	      Or MOClass = "CHARTSOFCALCULATIONTYPES" Then
		Manager = ChartsOfCalculationTypes;
		
	ElsIf MOClass = "INFORMATIONREGISTER"
	      Or MOClass = "INFORMATIONREGISTERS" Then
		Manager = InformationRegisters;
		
	ElsIf MOClass = "ACCUMULATIONREGISTER"
	      Or MOClass = "ACCUMULATIONREGISTERS" Then
		Manager = AccumulationRegisters;
		
	ElsIf MOClass = "ACCOUNTINGREGISTER"
	      Or MOClass = "ACCOUNTINGREGISTERS" Then
		Manager = AccountingRegisters;
		
	ElsIf MOClass = "CALCULATIONREGISTER"
	      Or MOClass = "CALCULATIONREGISTERS" Then
		
		If NameParts.Count() < 3 Then
			// Calculation register
			Manager = CalculationRegisters;
		Else
			SubordinateMOClass = Upper(NameParts[2]);
			If NameParts.Count() > 3 Then
				SubordinateMOName = NameParts[3];
			EndIf;
			If SubordinateMOClass = "RECALCULATION"
			 Or SubordinateMOClass = "RECALCULATIONS" Then
				// Recalculation
				Try
					Manager = CalculationRegisters[MetadataObjectName].Recalculations;
					MetadataObjectName = SubordinateMOName;
				Except
					Manager = Undefined;
				EndTry;
			EndIf;
		EndIf;
		
	ElsIf MOClass = "BUSINESSPROCESS"
	      Or MOClass = "BUSINESSPROCESSES" Then
		Manager = BusinessProcesses;
		
	ElsIf MOClass = "TASK"
	      Or MOClass = "TASKS" Then
		Manager = Tasks;
		
	ElsIf MOClass = "CONSTANT"
	      Or MOClass = "CONSTANTS" Then
		Manager = Constants;
		
	ElsIf MOClass = "SEQUENCE"
	      Or MOClass = "SEQUENCES" Then
		Manager = Sequences;
	EndIf;
	
	If Manager <> Undefined Then
		If ValueIsFilled(MetadataObjectName) Then
			Try
				Return Manager[MetadataObjectName];
			Except
				Manager = Undefined;
			EndTry;
		Else
			Return Manager;
		EndIf;
	EndIf;
	
	Raise StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = 'Не удалось получить менеджер для объекта ""%1""'; en = 'Cannot get a manager for object %1.'; pl = 'Nie udało się pobrać menedżera obiektu ""%1""';de = 'Kann den Manager für Objekt ""%1"" nicht empfangen';ro = 'Eșec la obținerea managerului pentru obiectul ""%1""';tr = 'Nesne ""%1"" için yönetici alınamıyor'; es_ES = 'No se puede recibir un gestor para el objeto ""%1""'"), Name);
	
EndFunction

#EndRegion

#EndRegion
