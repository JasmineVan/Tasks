///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Public

////////////////////////////////////////////////////////////////////////////////
// Add, change, and get contact information.

// Returns a table containing contact information for multiple objects.
//
// Parameters:
//    ReferencesOrObjects - Array - contact information owners.
//    ContactInformationTypes - Array, EnumRef.ContactInformationTypes - if types are specified, 
//        only contact information of these types is got.
//    ContactInformationKinds - Array, CatalogRef.ContactInformationKinds   - if kinds are specified, 
//                               only contact information of these kinds is returned.
//    Date                     - Date - an optional parameter, a date, from which contact 
//                              information is recorded, it is used for storing contact information change history.
//                              If the owner stores the change history, an exception is thrown if 
//                              the parameter does not match the date.
//
// Returns:
//  ValueTable - a table with object contact information that contains the following columns:
//    * ReferencesOrObjects - Reference - a contact information owner.
//    * Kind              - CatalogRef.ContactInformationKinds - a contact information kind.
//    * Type              - EnumRef.ContactInformationTypes - a contact information type.
//    * Value         - String - contact information in the internal JSON format.
//    * Presentation    - String - a contact information presentation.
//    * Date             - Date - a date, from which contact information record is valid.
//    * TableSectionRowID - Number - a row ID of this tabular section.
//    * FieldsValues    - String - an obsolete XML file matching the ContactInformation or Address XDTO packages. 
//                                  For backward compatibility.
//
Function ObjectsContactInformation(ReferencesOrObjects, Val ContactInformationTypes = Undefined, Val ContactInformationKinds = Undefined, Date = Undefined) Export
	
	Query = New Query;
	Query.TempTablesManager = New TempTablesManager;
	
	If TypeOf(ContactInformationTypes) = Type("EnumRef.ContactInformationTypes") Then
		ContactInformationTypes = CommonClientServer.ValueInArray(ContactInformationTypes);
	EndIf;
	
	If TypeOf(ContactInformationKinds) = Type("CatalogRef.ContactInformationKinds") Then
		ContactInformationKinds = CommonClientServer.ValueInArray(ContactInformationKinds);
	EndIf;
	
	CreateContactInformationTemporaryTable(Query.TempTablesManager, ReferencesOrObjects, ContactInformationTypes, ContactInformationKinds, Date);
	
	If TypeOf(Date) = Type("Date") Then
		ValidFrom = "ContactInformation.ValidFrom";
	Else
		ValidFrom = "DATETIME(1, 1, 1, 0, 0, 0)";
	EndIf;
	
	Query.Text =
	"SELECT
	|	ContactInformation.Object AS Object,
	|	ContactInformation.Kind AS Kind,
	|	ContactInformation.Type AS Type,
	|	ContactInformation.FieldsValues AS FieldsValues,
	|	ContactInformation.Value AS Value,
	|	ContactInformation.TabularSectionRowID AS TabularSectionRowID,
	|	" + ValidFrom +" AS Date,
	|	ContactInformation.Presentation AS Presentation
	|FROM
	|	TTContactInformation AS ContactInformation";
	
	Result = Query.Execute().Unload();
	For each ContactInformationRow In Result Do
		If IsBlankString(ContactInformationRow.Value)
			 AND ValueIsFilled(ContactInformationRow.FieldsValues) Then
			ContactInformationRow.Value = ContactInformationInJSON(ContactInformationRow.FieldsValues, ContactInformationRow.Type);
		EndIf;
	EndDo;
	
	Return Result;
	
EndFunction

// Returns a table that contains an object contact information.
// The behavior when a contact information presentation was returned is now considered obsolete and 
// is kept for backward compatibility. To get a contact information presentation, use the 
// ObjectContactInformationPresentation function instead.
//
// Parameters:
//  ReferenceOrObject - AnyRef, Object - Reference or object - a contact information owner (company, 
//                                            counterparty, partner, and so on).
//  ContactInformationKind - CatalogRef.ContactInformationKinds - an optional parameter, a filter by contact information kind.
//  Date                     - Date - a date, from which contact information record is valid.
//                             If an owner object allows storing the contact information change 
//                             history (the ValidFrom column is available in the ContactInformation 
//                             tabular section), a date must be passed, otherwise, an exception will be thrown.
//  OnlyPresentation - Boolean - if True, it returns only a presentation, otherwise, a value table.
//                                      To get a presentation, use the ObjectContactInformationPresentation function.
// 
// Returns:
//  ValueTable - a table with object contact information that contains the following columns:
//    * ReferencesOrObjects - Reference - a contact information owner.
//    * Kind              - CatalogRef.ContactInformationKinds - a contact information kind.
//    * Type              - EnumRef.ContactInformationTypes - a contact information type.
//    * Value         - String - contact information in the internal JSON format.
//    * Presentation    - String - a contact information presentation.
//    * Date             - Date - a date, from which contact information record is valid.
//    * TableSectionRowID - Number - a row ID of this tabular section.
//    * FieldsValues    - String - an obsolete XML file matching the ContactInformation or Address XDTO packages. 
//                                  For backward compatibility.
//
Function ObjectContactInformation(ReferenceOrObject, ContactInformationKind = Undefined, Date = Undefined, OnlyPresentation = True) Export
	
	ObjectType = TypeOf(ReferenceOrObject);
	If NOT Common.IsReference(ObjectType) Then
		ObjectMetadata = Metadata.FindByType(ObjectType);
		Result = NewContactInformation();
		If ObjectMetadata <> Undefined 
			AND ObjectMetadata.TabularSections.Find("ContactInformation") <> Undefined Then
			
			For each ContactInformationRow In ReferenceOrObject.ContactInformation Do
				If ContactInformationKind = Undefined 
					OR ContactInformationRow.Kind = ContactInformationKind Then
					NewRow = Result.Add();
					FillPropertyValues(NewRow, ContactInformationRow);
					If IsBlankString(NewRow.Value)
						 AND ValueIsFilled(NewRow.FieldsValues) Then
							NewRow.Value = ContactInformationInJSON(NewRow.FieldsValues, ContactInformationRow.Type);
					EndIf;
					NewRow.Object = ReferenceOrObject;
				EndIf;
			EndDo;
			
		EndIf;
		
		If OnlyPresentation Then
			If Result.Count() > 0 Then
				Return Result[0].Presentation;
			EndIf;
			Return "";
		EndIf;
		
		Return Result;
		
	EndIf;
	
	If OnlyPresentation Then
		// Left for backward compatibility.
		ObjectsArray = New Array;
		ObjectsArray.Add(ReferenceOrObject.Ref);
		
		If NOT ValueIsFilled(ContactInformationKind) Then
			Return "";
		EndIf;
		
		ObjectContactInformation = ObjectsContactInformation(ObjectsArray,, ContactInformationKind, Date);
		
		If ObjectContactInformation.Count() > 0 Then
			Return ObjectContactInformation[0].Presentation;
		EndIf;
		
		Return "";
	Else
		ReferencesOrObjects = New Array;
		ReferencesOrObjects.Add(ReferenceOrObject);
		
		If TypeOf(ContactInformationKind) = Type("CatalogRef.ContactInformationKinds") Then
			ContactInformationKinds = New Array;
			ContactInformationKinds.Add(ContactInformationKind);
			ContactInformationTypes = New Array;
			ContactInformationTypes.Add(Common.ObjectAttributeValue(ContactInformationKind, "Type"));
		Else
			ContactInformationKinds = Undefined;
		EndIf;
		
		Return ObjectsContactInformation(ReferencesOrObjects, ContactInformationTypes, ContactInformationKinds, Date);
	EndIf;
	
EndFunction

// Returns a presentation of object contact information.
//
// Parameters:
//  ReferenceOrObject         - Arbitrary - a contact information owner.
//  ContactInformationKind - CatalogRef.ContactInformationKinds - a contact information kind.
//  Separator             - String - a separator that is added to a presentation between contact information records.
//                                     By default, this is a comma followed by a space; to exclude a 
//                                     space, use the WithoutSpaces flag of the AdditionalParameters parameter.
//  Date                    - Date - a date, from which contact information record is valid. If 
//                                   contact information stores change history, the date is to be passed.
//  AdditionalParameters - Structure - optional parameters for generating a contact information presentation.
//   * OnlyFirst         - Boolean - if True, only presentation of the main (first) contact 
//                                     information record returns. Default value is False.
//   * WithoutSpaces          - Boolean - if True, a space is not added automatically after the separator.
//                                     Default value is False.
// 
// Returns:
//  String - a generated contact information presentation.
//
Function ObjectContactInformationPresentation(ReferenceOrObject, ContactInformationKind, Separator = ",", Date = Undefined, AdditionalParameters = Undefined) Export
	
	OnlyFirst = False;
	WithoutSpaces = False;
	If TypeOf(AdditionalParameters) = Type("Structure") Then
		If AdditionalParameters.Property("OnlyFirst") Then
			OnlyFirst = AdditionalParameters.OnlyFirst;
		EndIf;
		If AdditionalParameters.Property("WithoutSpaces") Then
			WithoutSpaces = AdditionalParameters.WithoutSpaces;
		EndIf;
	EndIf;
	SeparatorInPresentation = ?(WithoutSpaces, Separator, Separator + " ");
	
	FirstPass         = True;
	ContactInformation = ObjectContactInformation(ReferenceOrObject, ContactInformationKind, Date, False);
	
	If TypeOf(ContactInformation) = Type("ValueTable") Then
		
		For each ContactInformationRecord In ContactInformation Do
			If FirstPass Then
				Presentation = ContactInformationRecord.Presentation;
				If OnlyFirst Then
					Return Presentation;
				EndIf;
				FirstPass = False;
			Else
				Presentation = Presentation + SeparatorInPresentation + ContactInformationRecord.Presentation;
			EndIf;
		EndDo;
		
	Else
		
		Presentation = ContactInformation;
		
	EndIf;
	
	Return Presentation;
	
EndFunction

// Generates a new contact information table.
//
// Parameters:
//  ObjectColumn - Boolean - if True, the table will contain the Object column.
//                           It is necessary if you need to store contact information for multiple objects.
// 
// Returns:
//  ValueTable - a table with the following columns:
//       * Object        - AnyRef - a contact information owner.
//       * Kind           - CatalogRef.ContactInformationKinds - a contact information kind.
//       * Type           - EnumRef.ContactInformationTypes - a contact information type.
//       * Value      - String - a JSON file matching a contact information structure.
//       * FieldsValues - String - an XML file matching XDTO package ContactInformation or Address.
//       * Presentation - String - a contact information presentation.
//       * Date          - Date   - a date, from which contact information record is valid.
//       * TableSectionRowID - Number - a row ID of this tabular section.
//
Function NewContactInformation(ObjectColumn = True) Export
	
	ContactInformation = New ValueTable;
	TypesDetailsString1500 = New TypeDescription("String",, New StringQualifiers(1500));
	
	If ObjectColumn Then
		ContactInformation.Columns.Add("Object");
	EndIf;
	
	ContactInformation.Columns.Add("Presentation",                     TypesDetailsString1500);
	ContactInformation.Columns.Add("FieldsValues",                     New TypeDescription("String"));
	ContactInformation.Columns.Add("Value",                          New TypeDescription("String"));
	ContactInformation.Columns.Add("Kind",                               New TypeDescription("CatalogRef.ContactInformationKinds"));
	ContactInformation.Columns.Add("Type",                               New TypeDescription("EnumRef.ContactInformationTypes"));
	ContactInformation.Columns.Add("Date",                              New TypeDescription("Date"));
	ContactInformation.Columns.Add("TabularSectionRowID", New TypeDescription("Number"));
	
	Return ContactInformation;
	
EndFunction

// Adds contact information to an object by presentation or JSON file.
//
// Parameters:
//  ReferenceOrObject          - Arbitrary - a reference or an object of an owner containing contact information.
//                                            For references, after adding contact information, the owner is recorded.
//                                            If the object is passed, the contact information is added without being recorded.
//                                            To save changes, it is necessary to record the object separately.
//  ValueOrPresentation - String - a presentation, JSON, or XML file matching XDTO package 
//                                      ContactInformation or Address.
//  ContactInformationKind - CatalogRef.ContactInformationKinds - a kind of contact information being added.
//  Date                     - Date - a date, from which contact information will be recorded.
//                                       Required for contact information, for which the change history is stored.
//                                       If the value is not specified, the current session date is taken.
//  Replace                 - Boolean - if True (by default), all contact information of the passed 
//                                      contact information kind will be replaced.
//                                      If False, a record will be added. If the contact information 
//                                      kind does not allow entering multiple values and object 
//                                      contact information already contains a record, the record will not be added.
//
Procedure AddContactInformation(ReferenceOrObject, ValueOrPresentation, ContactInformationKind, Date = Undefined, Replace = True) Export
	
	If Common.IsReference(TypeOf(ReferenceOrObject)) Then
		Object = ReferenceOrObject.GetObject();
		Write = True;
	Else
		Object = ReferenceOrObject;
		Write = False;
	EndIf;
	
	ContactInformation                  = Object.ContactInformation;
	IsXMLContactInformation           = ContactsManagerClientServer.IsXMLContactInformation(ValueOrPresentation);
	IsJSONContactInformation          = ContactsManagerClientServer.IsJSONContactInformation(ValueOrPresentation);
	IsContactInformationInJSONStructure = TypeOf(ValueOrPresentation) = Type("Structure");
	ContactInformationKindProperties      = Common.ObjectAttributesValues(ContactInformationKind, "Type, StoreChangeHistory");
	
	ObjectMetadata = Metadata.FindByType(TypeOf(Object));
	If ObjectMetadata = Undefined
		Or ObjectMetadata.TabularSections.Find("ContactInformation") = Undefined Then
		Raise NStr("ru = 'Добавление контактной информации невозможно, у объекта нет таблицы с контактной информацией.'; en = 'Cannot add contact information. The object does not have a contact information table.'; pl = 'Dodawanie informacji kontaktowych nie jest możliwe, obiekt nie ma tabeli z danymi kontaktowymi.';de = 'Das Hinzufügen von Kontaktinformationen ist nicht möglich, das Objekt hat keine Tabelle mit Kontaktinformationen.';ro = 'Adăugarea informațiilor de contact este imposibilă, obiectul nu are tabel cu informații de contact.';tr = 'Iletişim bilgileri eklenemez, nesnenin iletişim bilgileri olan tablosu yok.'; es_ES = 'Es imposible añadir la información de contacto, el objeto no tiene tablas con la información de contacto.'");;
	EndIf;
	
	If IsContactInformationInJSONStructure Then
		
		ContactInformationObject = ValueOrPresentation;
		Value = ContactsManagerInternal.ToJSONStringStructure(ValueOrPresentation);
		FieldsValues = ContactInformationToXML(Value);
		Presentation = ContactInformationObject.Value;
		
	Else
		
		If IsXMLContactInformation Then
			
			FieldsValues = ValueOrPresentation;
			Value = ContactInformationInJSON(ValueOrPresentation, ContactInformationKindProperties.Type);
			ContactInformationObject = ContactsManagerInternal.JSONToContactInformationByFields(Value, ContactInformationKindProperties.Type);
			Presentation = ContactInformationObject.Value;
			
		ElsIf IsJSONContactInformation Then
			
			Value = ValueOrPresentation;
			FieldsValues = ContactInformationToXML(Value,, ContactInformationKindProperties.Type);
			ContactInformationObject = ContactsManagerInternal.JSONToContactInformationByFields(Value, ContactInformationKindProperties.Type);
			Presentation = ContactInformationPresentation(ValueOrPresentation, ContactInformationKind);
		
		Else
			ContactInformationObject = ContactsManagerInternal.ContactsByPresentation(ValueOrPresentation, ContactInformationKindProperties.Type);
			Value = ContactsManagerInternal.ToJSONStringStructure(ContactInformationObject);
			FieldsValues = ContactInformationToXML(Value);
			Presentation = ValueOrPresentation;
			
		EndIf;
		
	EndIf;
	
	If Replace Then
		FoundRows = FindContactInformationStrings(ContactInformationKind, Date, ContactInformation);
		For Each TabularSectionRow In FoundRows Do
			ContactInformation.Delete(TabularSectionRow);
		EndDo;
		ContactInformationRow = ContactInformation.Add();
	Else
		If MultipleValuesInputProhibited(ContactInformationKind, ContactInformation, Date) Then
			If IsXMLContactInformation Then
				ContactInformationRow = Object.ContactInformation.Find(ValueOrPresentation, "FieldsValues");
			ElsIf IsJSONContactInformation Then
				ContactInformationRow = Object.ContactInformation.Find(ValueOrPresentation, "Value");
			Else
				ContactInformationRow = Object.ContactInformation.Find(ValueOrPresentation, "Presentation");
			EndIf;
			If ContactInformationRow <> Undefined Then
				Return; // Only one value of this contact information kind is allowed.
			EndIf;
		EndIf;
		ContactInformationRow = ContactInformation.Add();
	EndIf;
	
	ContactInformationRow.Value      = Value;
	ContactInformationRow.Presentation = Presentation;
	ContactInformationRow.FieldsValues = FieldsValues;
	ContactInformationRow.Kind           = ContactInformationKind;
	ContactInformationRow.Type           = ContactInformationKindProperties.Type ;
	If ContactInformationKindProperties.StoreChangeHistory AND ValueIsFilled(Date) Then
		ContactInformationRow.ValidFrom = Date;
	EndIf;
	
	FillContactInformationTechnicalFields(ContactInformationRow, ContactInformationObject, ContactInformationKindProperties.Type);
	
	If Write Then
		Object.Write();
	EndIf;
	
EndProcedure

// Adds or changes contact information for multiple contact information owners.
//
// Parameters:
//  ContactInformation - ValueTable - a table containing contact information
//                                           See column details in the NewContactInformation function.
//                                           Warning! If a reference is specified in the Object 
//                                           column, the owner is recorded after adding contact information.
//                                           If the Object column contains an object of the contact 
//                                           information owner, objects are to be saved separately in order to save changes.
//  Replace             - Boolean - if True (by default), all contact information of the passed 
//                                   contact information kind will be replaced.
//                                   If False, a record will be added. If the contact information 
//                                   kind does not allow entering multiple values and object contact 
//                                   information already contains a record, the record will not be added.
//
Procedure SetObjectsContactInformation(ContactInformation, Replace = True) Export
	
	If ContactInformation.Count() = 0 Then
		Return;
	EndIf;
	
	ContactInformationOwners = New Map;
	For each ContactInformationRow In ContactInformation Do
		ContactInformationParameters = ContactInformationOwners[ContactInformationRow.Object];
		If ContactInformationParameters = Undefined Then
			ObjectMetadata = Metadata.FindByType(TypeOf(ContactInformationRow.Object));
			If ObjectMetadata = Undefined
				Or ObjectMetadata.TabularSections.Find("ContactInformation") = Undefined Then
				Raise NStr("ru = 'Добавление контактной информации невозможно, у объекта нет таблицы с контактной информацией.'; en = 'Cannot add contact information. The object does not have a contact information table.'; pl = 'Dodawanie informacji kontaktowych nie jest możliwe, obiekt nie ma tabeli z danymi kontaktowymi.';de = 'Das Hinzufügen von Kontaktinformationen ist nicht möglich, das Objekt hat keine Tabelle mit Kontaktinformationen.';ro = 'Adăugarea informațiilor de contact este imposibilă, obiectul nu are tabel cu informații de contact.';tr = 'Iletişim bilgileri eklenemez, nesnenin iletişim bilgileri olan tablosu yok.'; es_ES = 'Es imposible añadir la información de contacto, el objeto no tiene tablas con la información de contacto.'");;
			EndIf;
			
			ContactInformationParameters = New Structure;
			IsRef = Common.RefTypeValue(ContactInformationRow.Object);
			ContactInformationParameters.Insert("IsReference", IsRef);
			ContactInformationParameters.Insert("Periodic", ObjectMetadata.TabularSections.ContactInformation.Attributes.Find("ValidFrom") <> Undefined);
			
			ContactInformationOwners.Insert(ContactInformationRow.Object, ContactInformationParameters);
		EndIf;
		
		RestoreEmptyValuePresentation(ContactInformationRow);
		
	EndDo;
	
	For each ContactInformationOwner In ContactInformationOwners Do
		Filter = New Structure("Object", ContactInformationOwner.Key);
		ObjectContactInformationRows = ContactInformation.FindRows(Filter);
		
		If ContactInformationOwner.Value["IsReference"] Then
			Object = ContactInformationOwner.Key.GetObject();
		Else
			Object = ContactInformationOwner.Key;
		EndIf;
		
		If Replace Then
			Object.ContactInformation.Clear();
		EndIf;
		
		For each ObjectContactInformationRow In ObjectContactInformationRows Do
			
			StoreChangeHistory = ContactInformationOwner.Value["Periodic"] AND ObjectContactInformationRow.Kind.StoreChangeHistory;
			
			If Replace Then
				
				If MultipleValuesInputProhibited(ObjectContactInformationRow.Kind, Object.ContactInformation, ObjectContactInformationRow.Date) Then
					Continue;
				EndIf;
				ContactInformationRow = Object.ContactInformation.Add();
				
			Else
				
				Filter = New Structure();
				Filter.Insert("Kind", ObjectContactInformationRow.Kind);
				
				If StoreChangeHistory Then
					Filter.Insert("ValidFrom", ObjectContactInformationRow.Date);
					FoundRows = Object.ContactInformation.FindRows(Filter);
				ElsIf ValueIsFilled(ObjectContactInformationRow.Value) Then
					Filter.Insert("Value", ObjectContactInformationRow.Value);
					FoundRows = Object.ContactInformation.FindRows(Filter);
				Else
					Filter.Insert("FieldsValues", ObjectContactInformationRow.FieldsValues);
					FoundRows = Object.ContactInformation.FindRows(Filter);
				EndIf;
				
				If NOT StoreChangeHistory
					 AND MultipleValuesInputProhibited(ObjectContactInformationRow.Kind, Object.ContactInformation, ObjectContactInformationRow.Date)
					 OR FoundRows.Count() > 0 Then
						Continue;
				EndIf;
				
				ContactInformationRow = Object.ContactInformation.Add();
			EndIf;
			
			FillObjectContactInformationFromString(ObjectContactInformationRow, StoreChangeHistory, ContactInformationRow);
		EndDo;
		
		If ContactInformationOwner.Value["IsReference"] Then
			Object.Write();
		EndIf;
		
	EndDo;
	
EndProcedure

// Adds or changes contact information for the contact information owner.
//
// Parameters:
//  ReferenceOrObject      - Arbitrary    - a reference or an object of a contact information owner.
//                                           For references, after adding contact information, the owner is recorded.
//                                           If the object is passed, the contact information is added without being recorded.
//                                           To save changes, it is necessary to record the object separately.
//  ContactInformation - ValueTable - a table containing contact information
//                                           See column details in the NewContactInformation function.
//                                           Warning! If a blank value table is passed and the 
//                                           replacement mode is set, all contact information of the contact information owner will be cleared.
//  Replace             - Boolean - if True (by default), all contact information of the passed 
//                                           contact information kind will be replaced.
//                                           If False, a record will be added. If the contact 
//                                           information kind does not allow entering multiple 
//                                           values and object contact information already contains a record, the record will not be added.
//
Procedure SetObjectContactInformation(ReferenceOrObject, Val ContactInformation, Replace = True) Export
	
	IsRef = Common.RefTypeValue(ReferenceOrObject);
	Object =?(IsRef, ReferenceOrObject.GetObject(), ReferenceOrObject);
	
	If TypeOf(ReferenceOrObject) <> Type("FormDataStructure") Then
		ObjectMetadata = Metadata.FindByType(TypeOf(ReferenceOrObject));
	Else
		ObjectMetadata = Metadata.FindByType(TypeOf(ReferenceOrObject.Ref));
	EndIf;
	
	If ObjectMetadata = Undefined
		Or ObjectMetadata.TabularSections.Find("ContactInformation") = Undefined Then
		Raise NStr("ru = 'Добавление контактной информации невозможно, у объекта нет таблицы с контактной информацией.'; en = 'Cannot add contact information. The object does not have a contact information table.'; pl = 'Dodawanie informacji kontaktowych nie jest możliwe, obiekt nie ma tabeli z danymi kontaktowymi.';de = 'Das Hinzufügen von Kontaktinformationen ist nicht möglich, das Objekt hat keine Tabelle mit Kontaktinformationen.';ro = 'Adăugarea informațiilor de contact este imposibilă, obiectul nu are tabel cu informații de contact.';tr = 'Iletişim bilgileri eklenemez, nesnenin iletişim bilgileri olan tablosu yok.'; es_ES = 'Es imposible añadir la información de contacto, el objeto no tiene tablas con la información de contacto.'");;
	EndIf;
	
	// Clearing contact information using a blank table.
	If ContactInformation.Count() = 0 Then
		If Replace Then
			Object.ContactInformation.Clear();
			If IsRef Then
				Object.Write();
			EndIf;
		EndIf;
		Return;
	EndIf;
	
	Periodic = ObjectMetadata.TabularSections.ContactInformation.Attributes.Find("ValidFrom") <> Undefined;
	WithoutTabularSectionID = ObjectMetadata.TabularSections.ContactInformation.Attributes.Find("TabularSectionRowID") = Undefined;
	
	For each ContactInformationRow In ContactInformation Do
		RestoreEmptyValuePresentation(ContactInformationRow);
	EndDo;
	
	If Replace Then
		
		For each ObjectContactInformationRow In ContactInformation Do
			
			FilterDate = ?(Periodic, ObjectContactInformationRow.Date, Undefined);
			FoundRows = FindContactInformationStrings(ObjectContactInformationRow.Kind, FilterDate, Object.ContactInformation);
			
			For each Row In FoundRows Do
				Object.ContactInformation.Delete(Row);
			EndDo;
			
		EndDo;
		
	EndIf;
	
	For each ObjectContactInformationRow In ContactInformation Do
		
		StoreChangeHistory = Periodic AND ObjectContactInformationRow.Kind.StoreChangeHistory;
		
		If Replace Then
			
			TabularSectionRowID = ?(WithoutTabularSectionID, Undefined, ObjectContactInformationRow.TabularSectionRowID);
			If MultipleValuesInputProhibited(ObjectContactInformationRow.Kind, Object.ContactInformation, ObjectContactInformationRow.Date, TabularSectionRowID) Then
				Continue;
			EndIf;
			ContactInformationRow = Object.ContactInformation.Add();
			
		Else
			
			Filter = New Structure();
			Filter.Insert("Kind", ObjectContactInformationRow.Kind);
			
			If StoreChangeHistory Then
				Filter.Insert("ValidFrom", ObjectContactInformationRow.Date);
				FoundRows = Object.ContactInformation.FindRows(Filter);
			ElsIf ValueIsFilled(ObjectContactInformationRow.Value) Then
				Filter.Insert("Value", ObjectContactInformationRow.Value);
				FoundRows = Object.ContactInformation.FindRows(Filter);
			Else
				Filter.Insert("FieldsValues", ObjectContactInformationRow.FieldsValues);
				FoundRows = Object.ContactInformation.FindRows(Filter);
			EndIf;
			
			If NOT StoreChangeHistory
				 AND MultipleValuesInputProhibited(ObjectContactInformationRow.Kind, Object.ContactInformation, ObjectContactInformationRow.Date)
				 OR FoundRows.Count() > 0 Then
					Continue;
			EndIf;
			
			ContactInformationRow = Object.ContactInformation.Add();
			
		EndIf;
		
		FillObjectContactInformationFromString(ObjectContactInformationRow, StoreChangeHistory, ContactInformationRow);
		
	EndDo;
	
	If IsRef Then
		Object.Write();
	EndIf;
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Contact information management from other subsystems.

// Converts incoming contact information formats into the internal JSON format.
//
// Parameters:
//    ContactInformation - String - a string in the XML format. The structure of the XML document 
//                                    matches the ContactInformation or Address XDTO package (for addresses containing fields with specific national characteristics).
//                                    If a string is passed in the JSON format, the return value 
//                                    will match the string.
//                         - Structure - see ContactsManagerClientServer. ContactInformationStructureByType.
//                                       see AddressManager.AddressFields (for addresses containing  
//                                       fields with specific national characteristics), see  
//                                       AddressManagerClientServer.ContactInformationStructureByType (for other types of contact information containing fields with specific national characteristics).
//    ExpectedKind - CatalogRef.ContactInformationKinds, EnumRef.ContactInformationTypes - used to 
//                   determine a contact information type if it cannot be determined from the passed 
//                   contact information in the ContactInformation parameter.
//
// Returns:
//     String - contact information in the internal JSON format.
//              See fields and their details in ContactsManagerClientServer. NewContactInformationDetails.
//              See additional fields for a configuration that supports national specificities in  AddressManagerClientServer.NewContactInformationDetails.
//
Function ContactInformationInJSON(Val ContactInformation, Val ExpectedKind = Undefined) Export
	
	If ContactsManagerClientServer.IsJSONContactInformation(ContactInformation) Then
		Return ContactInformation;
	EndIf;
	
	ContactInformationByFields = ContactsManagerInternal.ContactInformationToJSONStructure(ContactInformation, ExpectedKind,,  False);
	Return ContactsManagerInternal.ToJSONStringStructure(ContactInformationByFields);
	
EndFunction

// Converts all incoming contact information formats to XML.
//
// Parameters:
//    FieldsValues - String, Structure, Map, ValueList - details of contact information fields.
//                    XML must match XDTO package ContactInformation or Address.
//                    Structure, Map, ValueList must contain fields in accordance with the stucture
//                    of XDTO packages ContactInformation or Address (for a configuration with support of local specifics).
//    Presentation - String - a contact information presentation. Used if it is impossible to 
//                    determine a presentation based on the FieldsValues parameter (the Presentation field is missing).
//    ExpectedKind  - CatalogRef.ContactInformationKinds, EnumRef.ContactInformationTypes - 
//                    used to determine a type if it is impossible to determine it by the FieldsValues field.
//
// Returns:
//     String - contact information in the XML format matching the structure of the XDTO packages ContactInformation and Address.
//
Function ContactInformationToXML(Val FieldsValues, Val Presentation = "", Val ExpectedKind = Undefined) Export
	
	Result = ContactsManagerInternal.TransformContactInformationXML(New Structure(
		"FieldsValues, Presentation, ContactInformationKind",
	FieldsValues, Presentation, ExpectedKind));
	Return Result.XMLData;
	
EndFunction

// Returns a contact information type.
//
// Parameters:
//    ContactInformation - String - contact information as an XML matching the structure of
//                                    the ContactInformation and Address XDTO packages.
//
// Returns:
//    EnumRef.ContactInformationTypes - matching type.
//
Function ContactInformationType(Val ContactInformation) Export
	
	If ContactsManagerClientServer.IsJSONContactInformation(ContactInformation) Then
		
		ContactInformationAsStructure = ContactsManagerInternal.JSONStringToStructure(ContactInformation);
		If TypeOf(ContactInformationAsStructure) = Type("Structure") AND ContactInformationAsStructure.Property("type") Then
			Return Enums.ContactInformationTypes[ContactInformationAsStructure.type];
		EndIf;
	
	EndIf;
	
	Return ContactsManagerInternal.ContactInformationType(ContactInformation);
EndFunction

// Converts a presentation of contacts into the internal JSON format.
//
// Correct conversion is not guaranteed for the addresses entered in free form.
//
//  Parameters:
//      Presentatin - String - a string presentation of contact information displayed to a user.
//      ExpectedKind  - CatalogRef.ContactInformationKinds, EnumRef.ContactInformationTypes,
//                      Structure - a kind or a type of contact information.
//
// Returns:
//      String - contact information in the JSON format.
//
Function ContactsByPresentation(Presentation, ExpectedKind) Export
	
	Return ContactsManagerInternal.ToJSONStringStructure(
		ContactsManagerInternal.ContactsByPresentation(Presentation, ExpectedKind));
	
EndFunction

// Returns a presentation of a contact information (an address, a phone, an email, and so on).
//
// Parameters:
//    ContactInformation - String     - a JSON or XML string of contact information matching XDTO package
//                         ContactInformation or Address
//                         - XDTODataObject - the ContactInformation or Address XDTO object.
//                         - Structure  - contact information broken down by fields, which is received by the
//                                        AddressInfo or PhoneInfo functions.
//    ContactInformationKind - Structure - additional parameters that affect generation of an address presentation:
//      * IncludeCountryInPresentation - Boolean - an address country will be included in the presentation.
//      * AddressFormat                 - String - FIAS or ARCA options.
//                                                If set to "ARCA", the address presentation does 
//                                                not include values of county and city district levels.
//
// Returns:
//    String - a contact information presentation.
//
Function ContactInformationPresentation(Val ContactInformation, Val ContactInformationKind = Undefined) Export
	
	Return ContactsManagerInternal.ContactInformationPresentation(ContactInformation, ContactInformationKind);
	
EndFunction

// Evaluates that the address was entered in free form.
//
//  Parameters:
//      ContactInformation - String - a JSON or XML string of contact information matching XDTO packages
//                                      ContactInformation or Address.
//
//  Returns:
//      Boolean - a new value.
//
Function AddressEnteredInFreeFormat(Val ContactInformation) Export
	
	If ContactsManagerClientServer.IsXMLContactInformation(ContactInformation) Then
		JSONContactInformation = ContactInformationInJSON(ContactInformation);
		ContactInformation = ContactsManagerInternal.JSONToContactInformationByFields(JSONContactInformation, Enums.ContactInformationTypes.Address);
	ElsIf ContactsManagerClientServer.IsJSONContactInformation(ContactInformation) Then
		ContactInformation = ContactsManagerInternal.JSONToContactInformationByFields(ContactInformation, Enums.ContactInformationTypes.Address);
	EndIf;
	
	Return ContactsManagerClientServer.IsAddressInFreeForm(ContactInformation.AddressType);
	
EndFunction

// Returns contact information comment.
//
// Parameters:
//  ContactInformation - String - a JSON or XML string or XDTO object matching XDTO packages
//                                   ContactInformation or Address.
//
// Returns:
//  String - a contact information comment or a blank string if the parameter value is not contact 
//           information.
//
Function ContactInformationComment(ContactInformation) Export
	
	If IsBlankString(ContactInformation) Then
		Return "";
	EndIf;

	If ContactsManagerClientServer.IsXMLContactInformation(ContactInformation) Then
		ContactInformationAsStructure = ContactsManagerInternal.ContactInformationToJSONStructure(ContactInformation);
	ElsIf ContactsManagerClientServer.IsJSONContactInformation(ContactInformation) Then
		ContactInformationAsStructure = ContactsManagerInternal.JSONStringToStructure(ContactInformation);
	Else
		ContactInformationToXML = ContactInformationToXML(ContactInformation);
		ContactInformationAsStructure = ContactsManagerInternal.ContactInformationToJSONStructure(ContactInformationToXML);
	EndIf;
	
	If ContactInformationAsStructure.Property("Comment") Then
		Return ContactInformationAsStructure.Comment;
	EndIf;
	
	Return "";
	
EndFunction

// Sets a new comment for contact information.
//
// Parameters:
//   ContactInformation - String, XDTOObject - a JSON or XML string of contact information matching 
//                                               XDTO packages ContactInformation or Address.
//   Comment          - String             - a new comment value.
//
Procedure SetContactInformationComment(ContactInformation, Val Comment) Export
	
	IsString = TypeOf(ContactInformation) = Type("String");
	
	If ContactsManagerClientServer.IsJSONContactInformation(ContactInformation) Then
		
		ContactInformationAsStructure = ContactsManagerInternal.JSONStringToStructure(ContactInformation);
		
		If TypeOf(ContactInformationAsStructure) = Type("Structure") AND ContactInformationAsStructure.Property("comment") Then
			ContactInformationAsStructure.comment = Comment;
			ContactInformation = ContactsManagerInternal.ToJSONStringStructure(ContactInformationAsStructure);
		EndIf;
		
		Return;
		
	ElsIf IsString AND Not ContactsManagerClientServer.IsXMLContactInformation(ContactInformation) Then
		// The previous format of field values, no comment.
		Return;
	EndIf;
	
	XDTODataObject = ?(IsString, ContactsManagerInternal.ContactsFromXML(ContactInformation), ContactInformation);
	XDTODataObject.Comment = Comment;
	If IsString Then
		ContactInformation = ContactsManagerInternal.XDTOContactsInXML(XDTODataObject);
	EndIf;
	
EndProcedure

// Returns information about the address country.
// If the passed string does not contain information on the address, an exception is thrown.
// If an empty string is passed, an empty structure is returned.
// If the country is not found in the catalog but it is found in the ARCC, the Ref field of the result is blank.
// If the country is found neither in the address nor in the ARCC, only the Description field is filled in.
//
// Parameters:
//    Address - Structure, String - an address in a JSON format or an XML string matching XDTO 
//                                packages ContactInformation or Address.
//
// Returns:
//    Structure - address country details. Contains fields:
//        * Ref             - CatalogRef.WorldCountries, Undefined - a reference to the country catalog item.
//        * Description - String - a country description.
//        * Code - String - a country code.
//        * FullDescription - String - a full description of the country.
//        * CodeAlpha2          - String - a two-character alpha-2 country code.
//        * CodeAlpha3          - String - a three-character alpha-3 country code.
//
Function ContactInformationAddressCountry(Val Address) Export
	
	Result = New Structure("Ref, Code, Description, DescriptionFull, CodeAlpha2, CodeAlpha3");
	
	If TypeOf(Address) = Type("String") Then
		
		If IsBlankString(Address) Then
			Return Result;
		EndIf;
	
		If ContactsManagerClientServer.IsXMLContactInformation(Address) Then
			Address = ContactInformationInJSON(Address, Enums.ContactInformationTypes.Address);
		EndIf;
		
		Address = ContactsManagerInternal.JSONToContactInformationByFields(Address, Enums.ContactInformationTypes.Address);
		
	ElsIf TypeOf(Address) <> Type("Structure") Then
		
		Raise NStr("ru = 'Невозможно определить страну, ожидается адрес.'; en = 'Cannot recognize country. Address expected.'; pl = 'Nie można ustalić państwa, oczekiwanie adresu.';de = 'Land kann nicht ermittelt werden; Adresse ausstehend.';ro = 'Țara nu poate fi determinată, lipsește adresa.';tr = 'Ülke belirlenemiyor; adres bekleniyor.'; es_ES = 'No se puede determinar el país; dirección pendiente.'");
		
	EndIf;
	
	Result.Description = TrimAll(Address.Country);
	CountryData = WorldCountryData(, Result.Description);
	Return ?(CountryData = Undefined, Result, CountryData);
	
EndFunction

// Returns a domain of the network address for a web link or an email address.
//
// Parameters:
//    ContactInformation - String - a JSON or XML string of contact information matching XDTO package ContactInformation.
//
// Returns:
//    String - an address domain.
//
Function ContactInformationAddressDomain(Val ContactInformation) Export
	
	If IsBlankString(ContactInformation) Then
		Return "";
	EndIf;
	
	If ContactsManagerClientServer.IsXMLContactInformation(ContactInformation) Then
		ContactInformationAsStructure = ContactsManagerInternal.ContactInformationToJSONStructure(ContactInformation);
	ElsIf ContactsManagerClientServer.IsJSONContactInformation(ContactInformation) Then
		ContactInformationAsStructure = ContactsManagerInternal.JSONStringToStructure(ContactInformation);
	EndIf;
	
	If ContactInformationAsStructure.Property("Type") AND ContactInformationAsStructure.Property("Value") Then
		
		AddressDomain = TrimAll(ContactInformationAsStructure.Value);
		If ContactInformationTypeByDescription(ContactInformationAsStructure.Type) = Enums.ContactInformationTypes.WebPage Then
			
			Position = StrFind(AddressDomain, "://");
			If Position > 0 Then
				AddressDomain = Mid(AddressDomain, Position + 3);
			EndIf;
			Position = StrFind(AddressDomain, "/");
			Return ?(Position = 0, AddressDomain, Left(AddressDomain, Position - 1));
			
		ElsIf ContactInformationTypeByDescription(ContactInformationAsStructure.Type) = Enums.ContactInformationTypes.EmailAddress Then
			
			Position = StrFind(AddressDomain, "@");
			Return ?(Position = 0, AddressDomain, Mid(AddressDomain, Position + 1));
			
		EndIf;
		
	EndIf;
	
	Raise NStr("ru = 'Невозможно определить домен, ожидается электронная почта или веб-ссылка.'; en = 'Cannot recognize domain. Email address or URL expected.'; pl = 'Nie można określić domeny; oczekiwanie wiadomości e-mail lub łącza internetowego.';de = 'Domain kann nicht ermittelt werden; E-Mail oder Web-Link ausstehend.';ro = 'Domeniul nu poate fi determinat, se așteaptă e-mail sau linkul web.';tr = 'Alan belirlenemiyor; e-posta veya web-link bekleniyor.'; es_ES = 'No se puede determinar el dominio; correo electrónico o enlace web pendientes.'");
EndFunction

// Returns information about a phone or a fax number.
//
// Parameters:
//  ContactInformation - String - a phone in the internal JSON or XML format matching the 
//                                  XDTO package ContactInformation.
//                       - Undefined - Constructor, returns a list of blank phone fields.
//
// Returns:
//  Structure - phone information:
//    * Presentation - String - a phone presentation.
//    * CountryCode     - String - a country code. For example, +7.
//    * CityCode     - String - a city code. For example, 495.
//    * PhoneNumber - String - a phone number.
//    * Extension    - String - an extension.
//    * Comment   - String - a comment to the phone number.
//
Function InfoAboutPhone(ContactInformation = Undefined) Export
	
	Result               = ContactsManagerClientServer.PhoneFieldStructure();
	If ContactInformation = Undefined Then
		Return Result;
	EndIf;
	
	PhoneByFields         = ContactsManagerInternal.ContactInformationToJSONStructure(ContactInformation, Enums.ContactInformationTypes.Phone);
	
	Result.Presentation = String(PhoneByFields.Value);
	Result.CountryCode     = String(PhoneByFields.CountryCode);
	Result.CityCode     = String(PhoneByFields.AreaCode);
	Result.PhoneNumber = String(PhoneByFields.Number);
	Result.Extension    = String(PhoneByFields.ExtNumber);
	Result.Comment   = String(PhoneByFields.Comment);
	
	Return Result;
	
EndFunction

// Returns a string containing a phone number without an area code and an extension.
//
// Parameters:
//    ContactInformation - String - a JSON or XML string of contact information matching XDTO package ContactInformation.
//
// Returns:
//    String - a phone number.
//
Function ContactInformationPhoneNumber(Val ContactInformation) Export
	
	If IsBlankString(ContactInformation) Then
		Return "";
	EndIf;
	
	If ContactsManagerClientServer.IsXMLContactInformation(ContactInformation) Then
		ContactInformationAsStructure = ContactsManagerInternal.ContactInformationToJSONStructure(ContactInformation);
	ElsIf ContactsManagerClientServer.IsJSONContactInformation(ContactInformation) Then
		ContactInformationAsStructure = ContactsManagerInternal.JSONToContactInformationByFields(ContactInformation, Enums.ContactInformationTypes.Phone);
	EndIf;
	
	If ContactInformationAsStructure.Property("Number") Then
		
		Return TrimAll(ContactInformationAsStructure.Number);
		
	EndIf;
	
	Raise NStr("ru = 'Невозможно определить номер, ожидается телефона или факс.'; en = 'Cannot recognize number. Phone or fax number expected.'; pl = 'Nie można określić numeru; oczekiwanie telefonu lub  faksu.';de = 'Nummer kann nicht ermittelt werden; Telefonanruf oder Fax anstehend.';ro = 'Numărul nu poate fi determinat, se așteaptă telefon sau fax.';tr = 'Numara belirlenemiyor, telefon veya faks bekleniyor.'; es_ES = 'No se puede determinar el número; llamada telefónica o fax pendientes.'");
	
EndFunction

// Compares two instances of contact information.
//
// Parameters:
//    Data1 - XTDOObject - an object with contact information.
//            - String - contact information in XML format.
//            - Structure - contact information details. The following fields are expected:
//                 * FieldsValues - String, Structure, ValueList, Map - contact information fields.
//                 * Presentation - String - a presentation. Used when presentation cannot be 
//                                            extracted from FieldsValues (the Presentation field is not available).
//                 * Comment - String - a comment. Used when a comment cannot be extracted from 
//                                          FieldsValues.
//                 * ContactInformationKind - CatalogRef.ContactInformationKinds,
//                                             EnumRef.ContactInformationTypes, Structure - used 
//                                             when a type cannot be extracted from FieldsValues.
//    Data2 - XTDOObject, String, Structure - similar to Data1.
//
// Returns:
//     ValueTable: - a table of different fields with the following columns:
//        * Path      - String - XPath identifying a different value. The "ContactInformationType" value
//                               means that passed contact information sets have different types.
//        * Details - String - details of a different attribute in terms of the subject field.
//        * Value1 - String - a value matching the object passed in the Data1 parameter.
//        * Value2 - String - a value matching the object passed in Data2 parameter.
//
Function ContactInformationDifferences(Val Data1, Val Data2) Export
	Return ContactsManagerInternal.ContactInformationDifferences(Data1, Data2);
EndFunction

// Generates a temporary table with contact information of multiple objects.
//
// Parameters:
//    TempTablesManager - TempTablesManager - a temporary table is created in the manager.
//     ContactInformationTemporaryTable with the following fields:
//     * Object - Ref - a contact information owner.
//     * Kind           - CatalogRef.ContactInformationKinds - a reference to a contact information kind.
//     * Type           - EnumRef.ContactInformationTypes - a contact information type.
//     * FieldsValues - String - an XML file matching the ContactInformation or Address XDTO data package.
//     * Presentation - String - a contact information presentation.
//    ObjectsArray - Array - contact information owners.
//    ContactInformationTypes - Array - if specified, a temporary table will contain only contact 
//                                        information of these types.
//    ContactInformationKinds - Array - if specified, a temporary table will contain only contact 
//                                        information of these kinds.
//    Date - Date - the date, from which contact information record is valid. It is used for storing 
//                                        the history of contact information changes. If the owner 
//                                        stores the change history, an exception is thrown if the parameter does not match the date.
//
Procedure CreateContactInformationTemporaryTable(TempTablesManager, ObjectsArray, ContactInformationTypes = Undefined, ContactInformationKinds = Undefined, Date = Undefined) Export
	
	If TypeOf(ObjectsArray) <> Type("Array") OR ObjectsArray.Count() = 0 Then
		Raise NStr("ru = 'Неверное значение для массива владельцев контактной информации.'; en = 'Invalid value for array of contact information owners.'; pl = 'Niepoprawna wartość dla tablicy właścicieli informacji kontaktowych.';de = 'Falscher Wert für die Anordnung der Kontaktinformation Eigentümer.';ro = 'Valoare incorectă pentru masivul titularilor informațiilor de contact.';tr = 'İletişim bilgisi sahiplerinin dizisi için yanlış değer.'; es_ES = 'Valor incorrecto para el conjunto de los propietarios de la información de contacto.'");
	EndIf;
	
	ObjectsGroupedByTypes = New Map;
	For each Ref In ObjectsArray Do
		ObjectType = TypeOf(Ref);
		FoundObject = ObjectsGroupedByTypes.Get(ObjectType);
		If FoundObject = Undefined Then
			RefSet = New Array;
			RefSet.Add(Ref);
			ObjectsGroupedByTypes.Insert(ObjectType, RefSet);
		Else
			FoundObject.Add(Ref);
		EndIf;
	EndDo;
	
	Query = New Query();
	QueryTextPreparingData = "";
	StringALLOWED = " ALLOWED ";
	TemporaryTableString = "INTO TTContactInformation";
	
	For each ObjectWithContactInformation In ObjectsGroupedByTypes Do
		ObjectMetadata = Metadata.FindByType(ObjectWithContactInformation.Key);
		If ObjectMetadata.TabularSections.Find("ContactInformation") = Undefined Then
			Raise  ObjectMetadata.Name + " " + NStr("ru = 'не содержит контактную информацию.'; en = 'does not contain contact information.'; pl = 'nie zawiera informacji kontaktowej.';de = 'enthält keine Kontaktinformationen.';ro = 'nu conține informații de contact.';tr = 'iletişim bilgileri içermemektedir.'; es_ES = 'no contiene información de contacto.'");
		EndIf;
		TableName = ObjectMetadata.Name;
		If ObjectMetadata.TabularSections.ContactInformation.Attributes.Find("ValidFrom") <> Undefined Then
			QueryTextPreparingData = QueryTextPreparingData + "SELECT ALLOWED
			|	ContactInformation.Ref AS Object,
			|	ContactInformation.Kind AS Kind,
			|	MAX(ContactInformation.ValidFrom) AS ValidFrom
			|INTO ContactInformationSlice" + TableName + "
			|FROM
			|	" + ObjectMetadata.FullName() + ".ContactInformation AS ContactInformation
			|WHERE
			|	ContactInformation.Ref IN (&ObjectsArray" + TableName + ")
			|	AND ContactInformation.ValidFrom <= &ValidFrom
			|	AND ContactInformation.Kind <> VALUE(Catalog.ContactInformationKinds.EmptyRef)
			|	AND ContactInformation.Type <> VALUE(Enum.ContactInformationTypes.EmptyRef)
			|
			|GROUP BY
			|	ContactInformation.Kind, ContactInformation.Ref
			|;"
		EndIf;
	EndDo;
	
	QueryText = "";
	For each ObjectWithContactInformation In ObjectsGroupedByTypes Do
		QueryText = QueryText + ?(NOT IsBlankString(QueryText), Chars.LF + " UNION ALL " + Chars.LF, "");
		ObjectMetadata = Metadata.FindByType(ObjectWithContactInformation.Key);
		TableName = ObjectMetadata.Name;
		
		HasTabularSectionRowID = ObjectMetadata.TabularSections.ContactInformation.Attributes.Find("TabularSectionRowID") <> Undefined;
		QueryTextTabularSectionRowID = "";
		If HasTabularSectionRowID Then
			QueryTextTabularSectionRowID = "ContactInformation.TabularSectionRowID AS TabularSectionRowID";
		Else
			QueryTextTabularSectionRowID = "0 AS TabularSectionRowID";
		EndIf;
		
		If ObjectMetadata.TabularSections.ContactInformation.Attributes.Find("ValidFrom") <> Undefined Then
			If TypeOf(Date) <> Type("Date") Then
				Raise NStr("ru = 'Для получения контактной информации, хранящей историю изменений,
					|требуется указывать дату, с которой действует запись контактной информации.'; 
					|en = 'To receive contact information that keeps change history,
					|specify the history start date.'; 
					|pl = 'Aby uzyskać informację kontaktową, przechowującą historię zmian,
					|należy podać datę, od której obowiązuje wpis informacji kontaktowej.';
					|de = 'Um Kontaktinformationen zu erhalten, die die Änderungshistorie speichern,
					|muss das Datum angegeben werden, an dem die Kontaktinformationen erfasst werden.';
					|ro = 'Pentru obținerea informațiilor de contact care stochează istoria modificărilor
					|trebuie să indicați data din care este valabilă înregistrarea informațiilor de contact.';
					|tr = 'Değişiklik geçmişini 
					|muhafaza eden iletişim bilgilerini almak için iletişim bilgilerinin kaydedildiği tarihi belirtmeniz gerekir.'; 
					|es_ES = 'Para recibir la información de contacto que guarda el historial de cambios,
					|se requiere indicar la fecha de la que la información de contacto está vigente.'");
			EndIf;
			
			FilterConditions = ?(ContactInformationKinds = Undefined, "", " ContactInformation.Kind IN (&ContactInformationKinds)");
			If IsBlankString(FilterConditions) Then
				ConditionAnd = "";
			Else
				ConditionAnd = " AND ";
			EndIf;
			FilterConditions = FilterConditions + ?(ContactInformationTypes = Undefined, "", ConditionAnd + " ContactInformation.Type IN (&ContactInformationTypes)");
			If NOT IsBlankString(FilterConditions) Then
				FilterConditions = " WHERE " + FilterConditions;
			EndIf;
			
			QueryText = QueryText + "SELECT " + StringALLOWED + "
			|	ContactInformation.Ref AS Object,
			|	ContactInformation.Kind AS Kind,
			|	ContactInformation.Type AS Type,
			|	ContactInformation.ValidFrom AS ValidFrom,
			|	ContactInformation.Presentation AS Presentation,
			|	ContactInformation.Value,
			|	ContactInformation.FieldsValues,
			|	" + QueryTextTabularSectionRowID + "
			|	" + TemporaryTableString + "
			|FROM
			|	ContactInformationSlice" + TableName + " AS ContactInformationSlice
			|		LEFT JOIN " + ObjectMetadata.FullName() + ".ContactInformation AS ContactInformation
			|		ON ContactInformationSlice.Kind = ContactInformation.Kind
			|			AND ContactInformationSlice.ValidFrom = ContactInformation.ValidFrom
			|			AND ContactInformationSlice.Object = ContactInformation.Ref " + FilterConditions;
		Else
			QueryText = QueryText + "SELECT " + StringALLOWED + "
			|	ContactInformation.Ref AS Object,
			|	ContactInformation.Kind AS Kind,
			|	ContactInformation.Type AS Type,
			|	DATETIME(1,1,1) AS ValidFrom,
			|	ContactInformation.Presentation AS Presentation,
			|	ContactInformation.Value,
			|	ContactInformation.FieldsValues AS FieldsValues,
			|	" + QueryTextTabularSectionRowID + "
			|	" + TemporaryTableString + "
			|FROM
			|	" + ObjectMetadata.FullName() + ".ContactInformation AS ContactInformation
			|WHERE
			| ContactInformation.Kind <> VALUE(Catalog.ContactInformationKinds.EmptyRef)
			| AND ContactInformation.Type <> VALUE(Enum.ContactInformationTypes.EmptyRef)
			| AND ContactInformation.Ref IN (&ObjectsArray" + TableName + ")
			|	" + ?(ContactInformationTypes = Undefined, "", "AND ContactInformation.Type IN (&ContactInformationTypes)") + "
			|	" + ?(ContactInformationKinds = Undefined, "", "AND ContactInformation.Kind IN (&ContactInformationKinds)") + "
			|";
		EndIf;
		StringALLOWED ="";
		TemporaryTableString = "";
		
		Query.SetParameter("ObjectsArray" + TableName, ObjectWithContactInformation.Value);
	EndDo;
	
	Query.Text = QueryTextPreparingData + QueryText;
	Query.TempTablesManager = TempTablesManager;
	
	Query.SetParameter("ValidFrom", Date);
	Query.SetParameter("ContactInformationTypes", ContactInformationTypes);
	Query.SetParameter("ContactInformationKinds", ContactInformationKinds);
	Query.Execute();
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Countries

// Returns country data from the countries catalog or from the ARCC.
//
// Parameters:
//    CountryCode    - String, Number - an ARCC country code. If not specified, search by code is not performed.
//    Description - String - a country name including an international name. If not specified, search by description is not performed.
//
// Returns:
//    Structure - country details. Contains fields:
//        * Ref             - CatalogRef.WorldCountries, Undefined - a matching item of the countries catalog.
//        * Description - String - a country description.
//        * Code - String - a country code.
//        * FullDescription - String - a full description of the country.
//        * CodeAlpha2          - String - a two-character alpha-2 country code.
//        * CodeAlpha3          - String - a three-character alpha-3 country code.
//        * EEUMember - Boolean - a EEU member country.
//        * InternationalDescription - String - an international description of a country
//    Undefined - the country is found neither in the address nor in the ARCC.
//
Function WorldCountryData(Val CountryCode = Undefined, Val Description = Undefined) Export
	Result = Undefined;
	
	If CountryCode = Undefined AND Description = Undefined Then
		Return Result;
	EndIf;
	
	SearchCondition = New Array;
	ClassifierFilter = New Structure;
	
	StandardizedCode = WorldCountryCode(CountryCode);
	If CountryCode <> Undefined Then
		SearchCondition.Add("Code=" + CheckQuotesInString(StandardizedCode));
		ClassifierFilter.Insert("Code", StandardizedCode);
	EndIf;
	
	If Description <> Undefined Then
		DescriptionTemplate = " (Description = %1 OR InternationalDescription = %1)";
		SearchCondition.Add(StringFunctionsClientServer.SubstituteParametersToString(DescriptionTemplate,
			CheckQuotesInString(Description)));
		
		ClassifierFilter.Insert("Description", Description);
	EndIf;
	SearchCondition = StrConcat(SearchCondition, " AND ");
	
	Result = New Structure;
	Result.Insert("Ref");
	Result.Insert("Code",                       "");
	Result.Insert("Description",              "");
	Result.Insert("DescriptionFull",        "");
	Result.Insert("InternationalDescription", "");
	Result.Insert("CodeAlpha2",                 "");
	Result.Insert("CodeAlpha3",                 "");
	Result.Insert("EEUMember",              False);
	
	QueryText = "SELECT TOP 1
	|	Ref, Code, Description, DescriptionFull,
	|	InternationalDescription, CodeAlpha2, CodeAlpha3, EEUMember
	|FROM
	|	Catalog.WorldCountries
	|WHERE
	|	&SearchCondition
	|ORDER BY
	|	Description";
	
	QueryText = StrReplace(QueryText, "&SearchCondition", SearchCondition);
	Query = New Query(QueryText);
	
	Selection = Query.Execute().Select();
	
	If Selection.Next() Then 
		FillPropertyValues(Result, Selection);
	Else
		
		If Metadata.CommonModules.Find("AddressManager") = Undefined Then
			Return Undefined;
		EndIf;
		
		ModuleAddressManager = Common.CommonModule("AddressManager");
		ClassifierData = ModuleAddressManager.ClassifierTable();
		DataRows = ClassifierData.FindRows(ClassifierFilter);
		If DataRows.Count() = 0 Then
			Return Undefined;
		Else
			FillPropertyValues(Result, DataRows[0]);
		EndIf;
		
	EndIf;
	
	Return Result;
	
EndFunction

// Returns a country data by code.
//
// Parameters:
//  Code     - String, Number - an ARCC country code.
//  CodeType - String - options: CountryCode (by default), Alpha2, and Alpha3.
// 
// Returns:
//  Structure - country details. Contains fields:
//     * Description - String - a country description.
//     * Code - String - a country code.
//     * FullDescription - String - a full description of the country.
//     * CodeAlpha2          - String - a two-character alpha-2 country code.
//     * CodeAlpha3          - String - a three-character alpha-3 country code.
//     * EEUMember - Boolean - a EEU member country.
//  Undefined - the country is found neither in the address nor in the ARCC.
//
Function WorldCountryClassifierDataByCode(Val Code, Val CodeType = "CountryCode") Export
	
	If Metadata.CommonModules.Find("AddressManager") = Undefined Then
		Return Undefined;
	EndIf;
	
	Result = New Structure;
	Result.Insert("Code",                       "");
	Result.Insert("Description",              "");
	Result.Insert("DescriptionFull",        "");
	Result.Insert("CodeAlpha2",                 "");
	Result.Insert("CodeAlpha3",                 "");
	Result.Insert("EEUMember",              False);
	
	ModuleAddressManager = Common.CommonModule("AddressManager");
	ClassifierData = ModuleAddressManager.ClassifierTable();
	
	If StrCompare(CodeType, "Alpha2") = 0 Then
		DataString = ClassifierData.Find(Upper(Code), "CodeAlpha2");
	ElsIf StrCompare(CodeType, "Alpha3") = 0 Then
		DataString = ClassifierData.Find(Upper(Code), "CodeAlpha3");
	Else
		DataString = ClassifierData.Find(WorldCountryCode(Code), "Code");
	EndIf;
	
	If DataString = Undefined Then
		Return Undefined
	EndIf;
	
	FillPropertyValues(Result, DataString);
	
	Return Result;
	
EndFunction

// Returns country data by country description.
//
// Parameters:
//    Description - String - a country description.
//
// Returns:
//    Structure - country details. Contains fields:
//       * Description - String - a country description.
//       * Code - String - a country code.
//       * FullDescription - String - a full description of the country.
//       * CodeAlpha2          - String - a two-character alpha-2 country code.
//       * CodeAlpha3          - String - a three-character alpha-3 country code.
//       * EEUMember - Boolean - a EEU member country.
//    Undefined - the country is not found in the classifier.
//
Function WorldCountryClassifierDataByDescription(Val Description) Export
	
	If Metadata.CommonModules.Find("AddressManager") = Undefined Then
		Return Undefined;
	EndIf;
	
	Result = New Structure;
	Result.Insert("Code",                       "");
	Result.Insert("Description",              "");
	Result.Insert("DescriptionFull",        "");
	Result.Insert("CodeAlpha2",                 "");
	Result.Insert("CodeAlpha3",                 "");
	Result.Insert("EEUMember",              False);
	
	ModuleAddressManager = Common.CommonModule("AddressManager");
	ClassifierData = ModuleAddressManager.ClassifierTable();
	
	DataString = ClassifierData.Find(Description, "Description");
	If DataString = Undefined Then
		Return Undefined;
	EndIf;
	
	FillPropertyValues(Result, DataString);
	
	Return Result;
	
EndFunction

// Returns a reference to the countries catalog item by code or description.
// If an item of the WorldCountries catalog is not found, it will be created based on filling data.
//
// Parameters:
//  CodeOrDescription - String    - a country code, code alpha2, code alpha3, or country description.
//  FillingData   - Structure - data for filling when creating a new item.
//                                   The structure keys match the attributes of the WorldCountries catalog.
// 
// Returns:
//  CatalogRef.WorldCountries - a reference to an item of the WorldCountries catalog.
//                                If several values are found, the first value will be returned.
//                                If no values are found, filling data is not specified, an empty reference will be returned.
//
Function WorldCountryByCodeOrDescription(CodeOrDescription, FillingData = Undefined) Export
	
	Query = New Query;
	Query.Text = 
	"SELECT
	|	WorldCountries.Ref AS Ref
	|FROM
	|	Catalog.WorldCountries AS WorldCountries
	|WHERE
	|	(WorldCountries.Code = &CodeOrDescription
	|			OR WorldCountries.CodeAlpha2 = &CodeOrDescription
	|			OR WorldCountries.CodeAlpha3 = &CodeOrDescription
	|			OR WorldCountries.Description = &CodeOrDescription
	|			OR WorldCountries.InternationalDescription = &CodeOrDescription
	|			OR WorldCountries.DescriptionFull = &CodeOrDescription)";
	
	Query.SetParameter("CodeOrDescription", CodeOrDescription);
	QueryResult = Query.Execute().Select();
	
	If QueryResult.Next() Then
		Return QueryResult.Ref;
	EndIf;
	
	If Metadata.CommonModules.Find("AddressManager") = Undefined Then
		Return Catalogs.WorldCountries.EmptyRef();
	EndIf;
	
	ModuleAddressManager = Common.CommonModule("AddressManager");
	ClassifierData = ModuleAddressManager.ClassifierTable();
	
	Query = New Query;
	Query.Text = "SELECT
	|	TableClassifier.Code,
	|	TableClassifier.CodeAlpha2,
	|	TableClassifier.CodeAlpha3,
	|	TableClassifier.Description,
	|	TableClassifier.DescriptionFull,
	|	TableClassifier.EEUMember,
	|	TableClassifier.NonRelevant
	|INTO TableClassifier
	|FROM
	|	&TableClassifier AS TableClassifier
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	WorldCountry.Code,
	|	WorldCountry.CodeAlpha2,
	|	WorldCountry.CodeAlpha3,
	|	WorldCountry.Description,
	|	WorldCountry.DescriptionFull,
	|	WorldCountry.EEUMember,
	|	WorldCountry.NonRelevant
	|FROM
	|	TableClassifier AS WorldCountry
	|WHERE
	|	(WorldCountry.Code = &CodeOrDescription
	|			OR WorldCountry.CodeAlpha2 = &CodeOrDescription
	|			OR WorldCountry.CodeAlpha3 = &CodeOrDescription
	|			OR WorldCountry.Description = &CodeOrDescription
	|			OR WorldCountry.DescriptionFull = &CodeOrDescription)";
	
	Query.SetParameter("TableClassifier", ClassifierData);
	Query.SetParameter("CodeOrDescription",   CodeOrDescription);
	QueryResult = Query.Execute().Select();
	
	If QueryResult.Next() Then
		FillingData = Common.ValueTableRowToStructure(QueryResult);
	EndIf;
	
	If FillingData = Undefined
		OR NOT FillingData.Property("Description")
		OR IsBlankString(FillingData.Description) Then
		Return Catalogs.WorldCountries.EmptyRef();
	EndIf;
	
	SetPrivilegedMode(True);
	CountryObject = Catalogs.WorldCountries.CreateItem();
	FillPropertyValues(CountryObject, FillingData);
	CountryObject.Write();
	
	Return CountryObject.Ref;
	
EndFunction

// Returns a list of the Eurasian Economic Union countries (EEU).
//
// Returns:
//  - ValueTable - a list of the Eurasian Economic Union countries (EEU).
//     * Ref             - CatalogRef.WorldCountries - a reference to an item of the WorldCountries catalog.
//     * Description - String - a country description.
//     * Code - String - a country code.
//     * FullDescription - String - a full description of the country.
//     * CodeAlpha2          - String - a two-character alpha-2 country code.
//     * CodeAlpha3          - String - a three-character alpha-3 country code.
Function EEUMemberCountries() Export
	
	Query = New Query;
	Query.Text = 
		"SELECT
		|	WorldCountries.Ref AS Ref,
		|	WorldCountries.Description AS Description,
		|	WorldCountries.Code AS Code,
		|	WorldCountries.DescriptionFull AS DescriptionFull,
		|	WorldCountries.InternationalDescription AS InternationalDescription,
		|	WorldCountries.CodeAlpha2 AS CodeAlpha2,
		|	WorldCountries.CodeAlpha3 AS CodeAlpha3
		|FROM
		|	Catalog.WorldCountries AS WorldCountries
		|WHERE
		|	WorldCountries.EEUMember = TRUE";
	
	EEUCountries = Query.Execute().Unload();
	
	If Metadata.CommonModules.Find("AddressManager") = Undefined Then
		Return EEUCountries;
	EndIf;
	
	ModuleAddressManager = Common.CommonModule("AddressManager");
	ClassifierData = ModuleAddressManager.ClassifierTable();
	
	For each Country In ClassifierData Do
		If Country.EEUMember Then
			Filter = New Structure();
			Filter.Insert("Description", Country.Description);
			Filter.Insert("Code", Country.Code);
			Filter.Insert("DescriptionFull", Country.DescriptionFull);
			Filter.Insert("CodeAlpha2", Country.CodeAlpha2);
			Filter.Insert("CodeAlpha3", Country.CodeAlpha3);
			FoundRows = EEUCountries.FindRows(Filter);
			If FoundRows.Count() = 0 Then
				NewRow = EEUCountries.Add();
				FillPropertyValues(NewRow, Filter);
			EndIf;
		EndIf;
	EndDo;
	
	Return EEUCountries;

EndFunction

// Determines whether a country is the Eurasian Economic Union member (EEU).
//
// Parameters:
//  Country - String - CatalogRef.WorldCountries - a country code, code alpha2, code alpha3, country 
//                  description, or a reference to an item of the Countries catalog.
// Returns:
//    Boolean - if True, a country is the EEU country member.
Function IsEEUMemberCountry(Country) Export
	
	If TypeOf(Country) = TypeOf(Catalogs.WorldCountries.EmptyRef()) Then
		Query = New Query;
		Query.Text = 
			"SELECT
			|	WorldCountries.EEUMember AS EEUMember
			|FROM
			|	Catalog.WorldCountries AS WorldCountries
			|WHERE
			|	WorldCountries.Ref = &Ref";
		
		Query.SetParameter("Ref", Country);
		
		QueryResult = Query.Execute();
		
		If NOT QueryResult.IsEmpty() Then
			ResultString = QueryResult.Select();
			If ResultString.Next() Then
				Return (ResultString.EEUMember = TRUE);
			EndIf;
		EndIf;
		
	Else
		FoundCountry =  WorldCountryByCodeOrDescription(Country);
		If ValueIsFilled(FoundCountry) Then
			Return FoundCountry.EEUMember;
		EndIf;
		
	EndIf;
	
	Return False;
	
EndFunction

////////////////////////////////////////////////////////////////////////////////
// Handlers of form events and object module called upon the subsystem integration.

// OnCreateAtServer form event handler.
// Called from the module of contact information owner object form upon the subsystem integration.
//
// Parameters:
//    Form - ManagedForm - an owner object form used for displaying contact information.
//    Object - Arbitrary - an owner object of contact information. If it is a reference, contact 
//                                          information will be received from the object by reference, otherwise, from the ContactInformation table of the object.
//    AdditionalParameters - Structure - see details of contact information settings in  ContactInformationParameters.
//                                          The previous name of the ItemForPlacementName parameter. 
//                                          Obsolete, use AdditionalParameters instead. The group, 
//                                          to which contact information items will be placed.
//    DeleteCITitleLocation - FormItemTitleLocation - obsolete, use AdditionalParameters instead.
//                                                             Can take the following values:
//                                                             FormItemTitleLocation.Top or
//                                                             FormItemTitleLocation.Left (by default).
//    DeleteExcludedKinds - Array  - obsolete, use AdditionalParameters instead.
//    DeleteDeferredInitialization - Array - obsolete, use AdditionalParameters instead.
//
Procedure OnCreateAtServer(Form, Object, AdditionalParameters = Undefined, DeleteCITitleLocation = "",
	Val DeleteExcludedKinds = Undefined, DeleteDeferredInitialization = False) Export
	
	PremiseType = Undefined;
	If TypeOf(AdditionalParameters) = Type("Structure") Then
		
		AdditionalParameters.Property("PremiseType", PremiseType);
		DeferredInitialization  = ?(AdditionalParameters.Property("DeferredInitialization"), AdditionalParameters.DeferredInitialization, False);
		CITitleLocation     = ?(AdditionalParameters.Property("CITitleLocation"), AdditionalParameters.CITitleLocation, "");
		ExcludedKinds          = ?(AdditionalParameters.Property("ExcludedKinds"), AdditionalParameters.ExcludedKinds, Undefined);
		HiddenKinds           = ?(AdditionalParameters.Property("HiddenKinds"), AdditionalParameters.HiddenKinds, Undefined);
		ItemForPlacementName = ?(AdditionalParameters.Property("ItemForPlacementName"), AdditionalParameters.ItemForPlacementName, "ContactInformationGroup");
		URLProcessing = ?(AdditionalParameters.Property("URLProcessing"), AdditionalParameters.URLProcessing, False);
	Else
		ItemForPlacementName = ?(AdditionalParameters = Undefined, "ContactInformationGroup", AdditionalParameters);
		DeferredInitialization  = DeleteDeferredInitialization;
		ExcludedKinds          = DeleteExcludedKinds;
		HiddenKinds           = Undefined;
		CITitleLocation     = DeleteCITitleLocation;
		URLProcessing = False;
	EndIf;
	
	If ExcludedKinds = Undefined Then
		ExcludedKinds = New Array;
	EndIf;
	
	If HiddenKinds = Undefined Then
		HiddenKinds = New Array;
	EndIf;
	
	AttributesToAdd = New Array;
	CheckContactInformationAttributesAvailability(Form, AttributesToAdd);
	
	// Caching of frequently used values
	ObjectRef             = Object.Ref;
	ObjectMetadata          = ObjectRef.Metadata();
	FullMetadataObjectName = ObjectMetadata.FullName();
	ObjectName                 = ObjectMetadata.Name;
	
	ContactInformationKindsGroup  = ObjectContactInformationKindsGroup(FullMetadataObjectName);
	ContactInformationUsed = Common.ObjectAttributeValue(ContactInformationKindsGroup, "Used");
	If ContactInformationUsed = False Then
		
		ContactInformationOutputParameters = New Structure();
		ContactInformationOutputParameters.Insert("ItemForPlacementName", ItemForPlacementName);
		ContactInformationOutputParameters.Insert("CITitleLocation", CITitleLocation);
		ContactInformationOutputParameters.Insert("DeferredInitialization", DeferredInitialization);
		ContactInformationOutputParameters.Insert("ExcludedKinds", ExcludedKinds);
		ContactInformationOutputParameters.Insert("HiddenKinds", HiddenKinds);
		ContactInformationOutputParameters.Insert("ObjectRef", ObjectRef);
		
		HideContactInformation(Form, AttributesToAdd, ContactInformationOutputParameters);
		Return;
	EndIf;
	
	ObjectAttributes           = ObjectMetadata.TabularSections.ContactInformation.Attributes;
	HasColumnValidFrom      = (ObjectAttributes.Find("ValidFrom") <> Undefined);
	HasColumnTabularSectionRowID = (ObjectAttributes.Find("TabularSectionRowID") <> Undefined);
	
	If Common.IsReference(TypeOf(Object)) Then
		QueryText = "SELECT
		|	ContactInformation.Presentation AS Presentation,
		|	ContactInformation.LineNumber AS LineNumber,
		|	ContactInformation.Kind AS Kind, 
		|	ContactInformationKinds.StoreChangeHistory AS StoreChangeHistory,
		|	ContactInformation.FieldsValues,
		|	ContactInformation.Value,
		|	"""" AS ValidFrom,
		|	0 AS TabularSectionRowID,
		|	FALSE AS IsHistoricalContactInformation
		|FROM
		|	Catalog.ContactInformationKinds AS ContactInformationKinds
		|		LEFT JOIN " +  FullMetadataObjectName + ".ContactInformation AS ContactInformation
		|		ON (ContactInformation.Kind = ContactInformationKinds.Ref)
		|WHERE
		|	ContactInformation.Ref = &Ref ORDER BY Kind, ValidFrom";
		
		If HasColumnTabularSectionRowID Then
			QueryText = StrReplace(QueryText, "0 AS TabularSectionRowID",
			"ISNULL(ContactInformation.TabularSectionRowID, 0) AS TabularSectionRowID");
		EndIf;
		
		If HasColumnValidFrom Then
			QueryText = StrReplace(QueryText, """"" AS ValidFrom", "ContactInformation.ValidFrom AS ValidFrom");
		EndIf;
		Query = New Query(QueryText);
		Query.SetParameter("Ref", ObjectRef);
		ContactInformation = Query.Execute().Unload();
	Else
		ContactInformation = Object.ContactInformation.Unload();
		
		If HasColumnValidFrom Then
			BooleanType = New TypeDescription("Boolean");
			ContactInformation.Columns.Add("StoreChangeHistory", BooleanType);
			ContactInformation.Columns.Add("IsHistoricalContactInformation", BooleanType);
			ContactInformation.Sort("Kind, ValidFrom");
			For each ContactInformationRow In ContactInformation Do
				ContactInformationRow.StoreChangeHistory = ContactInformationRow.Kind.StoreChangeHistory;
			EndDo;
		EndIf;
	EndIf;
	
	If HasColumnValidFrom Then
		PreviousKind = Undefined;
		For each ContactInformationRow In ContactInformation Do
			If ContactInformationRow.StoreChangeHistory
				AND (PreviousKind = Undefined OR PreviousKind <> ContactInformationRow.Kind) Then
				Filter = New Structure("Kind", ContactInformationRow.Kind);
				FoundRows = ContactInformation.FindRows(Filter);
				LastDate = FoundRows.Get(FoundRows.Count() - 1).ValidFrom;
				For each FoundRow In FoundRows Do
					If FoundRow.ValidFrom < LastDate Then
						FoundRow.IsHistoricalContactInformation = True;
					EndIf;
				EndDo;
				PreviousKind = ContactInformationRow.Kind;
			EndIf;
		EndDo;
		QueryTextHistoricalInformation = " ContactInformation.IsHistoricalContactInformation AS IsHistoricalContactInformation,
		|	ContactInformation.ValidFrom                  AS ValidFrom,";
	Else
		QueryTextHistoricalInformation = "FALSE AS IsHistoricalContactInformation,0 AS ValidFrom, ";
	EndIf;
	
	QueryText = " SELECT
	|	ContactInformation.Presentation               AS Presentation,
	|	ContactInformation.Value                    AS Value,
	|	ContactInformation.FieldsValues               AS FieldsValues,
	|	ContactInformation.LineNumber                 AS LineNumber, " + QueryTextHistoricalInformation + "
	|	ContactInformation.Kind                         AS Kind,
	|	0 AS TabularSectionRowID
	|INTO 
	|	ContactInformation
	|FROM
	|	&ContactInformationTable AS ContactInformation
	|INDEX BY
	|	Kind
	|;////////////////////////////////////////////////////////////////////////////////
	|
	|SELECT
	|	ContactInformationKinds.Ref                       AS Kind,
	|CASE
	|	WHEN ContactInformationKinds.PredefinedKindName <> """"
	|	THEN ContactInformationKinds.PredefinedKindName
	|	ELSE ContactInformationKinds.PredefinedDataName
	|END AS PredefinedKindName,
	|	ContactInformationKinds.Type                          AS Type,
	|	ContactInformationKinds.Mandatory       AS Mandatory,
	|	ContactInformationKinds.FieldKindOther                AS FieldKindOther,
	|	CASE
	|		WHEN &IsMainLanguage
	|		THEN ContactInformationKinds.Description
	|		ELSE CAST(ISNULL(PresentationContactInformationKinds.Description, ContactInformationKinds.Description) AS STRING(150))
	|	END AS Description,
	|	ContactInformationKinds.StoreChangeHistory      AS StoreChangeHistory,
	|	ContactInformationKinds.EditInDialogOnly AS EditInDialogOnly,
	|	ContactInformationKinds.IsFolder                    AS IsTabularSectionAttribute,
	|	ContactInformationKinds.AddlOrderingAttribute    AS AddlOrderingAttribute,
	|	ContactInformationKinds.InternationalAddressFormat    AS InternationalAddressFormat,
	|	ISNULL(ContactInformation.IsHistoricalContactInformation, FALSE)    AS IsHistoricalContactInformation,
	|	ISNULL(ContactInformation.Presentation, """")    AS Presentation,
	|	ISNULL(ContactInformation.FieldsValues, """")    AS FieldsValues,
	|	ISNULL(ContactInformation.Value, """")         AS Value,
	|	ISNULL(ContactInformation.ValidFrom, 0)          AS ValidFrom,
	|	ISNULL(ContactInformation.LineNumber, 0)         AS LineNumber,
	|	0 AS TabularSectionRowID,
	|	CAST("""" AS STRING(200))                        AS AttributeName,
	|	ContactInformationKinds.DeletionMark              AS DeletionMark,
	|	CAST("""" AS STRING)                             AS Comment
	|FROM
	|	Catalog.ContactInformationKinds AS ContactInformationKinds
	|LEFT JOIN
	|	ContactInformation AS ContactInformation
	|ON
	|	ContactInformationKinds.Ref = ContactInformation.Kind
	|LEFT JOIN Catalog.ContactInformationKinds.Presentations AS PresentationContactInformationKinds
	|ON PresentationContactInformationKinds.Ref = ContactInformationKinds.Ref
	|	AND PresentationContactInformationKinds.LanguageCode = &LanguageCode
	|WHERE
	|	ContactInformationKinds.Used
	|	AND ISNULL(ContactInformationKinds.Parent.Used, TRUE)
	|	AND (
	|		ContactInformationKinds.Parent = &CIKindsGroup
	|		OR ContactInformationKinds.Parent.Parent = &CIKindsGroup)
	|	AND ContactInformationKinds.Ref NOT IN (&HiddenKinds)
	|ORDER BY
	|	ContactInformationKinds.Ref HIERARCHY
	|";
	
	If HasColumnTabularSectionRowID Then
		QueryText = StrReplace(QueryText, "0 AS TabularSectionRowID",
		"ISNULL(ContactInformation.TabularSectionRowID, 0) AS TabularSectionRowID");
	EndIf;
	
	Query = New Query(QueryText);
	Query.SetParameter("ContactInformationTable", ContactInformation);
	Query.SetParameter("CIKindsGroup", ContactInformationKindsGroup);
	Query.SetParameter("Owner", ObjectRef);
	Query.SetParameter("HiddenKinds", HiddenKinds);
	Query.SetParameter("IsMainLanguage", CurrentLanguage() = Metadata.DefaultLanguage);
	Query.SetParameter("LanguageCode", CurrentLanguage().LanguageCode);
	
	SetPrivilegedMode(True);
	ContactInformation = Query.Execute().Unload(QueryResultIteration.ByGroupsWithHierarchy).Rows;
	SetPrivilegedMode(False);
	
	ContactInformationConvertionToJSON(ContactInformation);
	
	ContactInformation.Sort("AddlOrderingAttribute, LineNumber");
	GenerateContactInformationAttributes(Form, AttributesToAdd, ObjectName, ExcludedKinds, ContactInformation, DeferredInitialization, URLProcessing);
	
	ContactInformationParameters = ContactInformationOutputParameters(Form, ItemForPlacementName, CITitleLocation,
		DeferredInitialization, ExcludedKinds, HiddenKinds);
	ContactInformationParameters.Owner                     = ObjectRef;
	ContactInformationParameters.AddressParameters.PremiseType = PremiseType;
	ContactInformationParameters.URLProcessing = URLProcessing;
	
	// Value cache of all contact information kinds of the object.
	ContactInformationKindsData = ContactsManagerInternal.ContactsKindsData(
		ContactInformation.UnloadColumn("Kind"));
		
	Filter = New Structure("Type", Enums.ContactInformationTypes.Address);
	AddressesCount = ContactInformation.FindRows(Filter).Count();
	
	// Creating form items, filling in the attribute values.
	CreatedItems = Common.CopyRecursive(ExcludedKinds);
	PreviousKind = Undefined;
	
	For Each CIRow In ContactInformation Do
		
		If CIRow.IsTabularSectionAttribute Then
			CreateTabularSectionItems(Form, ObjectName, ItemForPlacementName, CIRow, ContactInformationKindsData);
			Continue;
		EndIf;
		
		If CIRow.DeletionMark AND IsBlankString(CIRow.FieldsValues) AND IsBlankString(CIRow.Value) Then
			Continue;
		EndIf;
		
		ItemIndex     = CreatedItems.Find(CIRow.Kind);
		StaticItem = ItemIndex <> Undefined;
		IsNewCIKind      = (CIRow.Kind <> PreviousKind);
		
		If DeferredInitialization Then
			
			AddAttributeToDetails(Form, CIRow, ContactInformationKindsData, IsNewCIKind,,
				StaticItem, ItemForPlacementName);
			If StaticItem Then
				CreatedItems.Delete(ItemIndex);
			EndIf;
			Continue;
		EndIf;
		
		AddAttributeToDetails(Form, CIRow, ContactInformationKindsData, IsNewCIKind,,
			NOT CIRow.IsHistoricalContactInformation, ItemForPlacementName);
		
		If StaticItem Then
			CreatedItems.Delete(ItemIndex);
		Else
			
			NextRow = ?(CreatedItems.Count() = 0, Undefined,
				DefineNextString(Form, ContactInformation, CIRow));
			
			If NOT CIRow.IsHistoricalContactInformation Then
				AddContactInformationRow(Form, CIRow, ItemForPlacementName, IsNewCIKind, AddressesCount, NextRow);
			EndIf;
			
		EndIf;
		
		If NOT CIRow.IsHistoricalContactInformation  Then
			PreviousKind = CIRow.Kind;
		EndIf;
		
	EndDo;
	
	UpdateConextMenu(Form, ItemForPlacementName);
	
	If Not DeferredInitialization 
		AND Form.ContactInformationParameters[ItemForPlacementName].ItemsToAddList.Count() > 0 Then
		AddAdditionalContactInformationFieldButton(Form, ItemForPlacementName);
	Else
		AddNoteOnFormSettingsReset(Form, ItemForPlacementName, DeferredInitialization);
	EndIf;
	
EndProcedure

// OnReadAtServer form event handler.
// Called from the module of contact information owner object form upon the subsystem integration.
//
// Parameters:
//    Form - ManagedForm - an owner object form used for displaying contact information.
//    Object - Arbitrary - an owner object of contact information.
//    ItemForPlacementName - String - a group, to which the contact information items will be placed.
//
Procedure OnReadAtServer(Form, Object, ItemForPlacementName = "ContactInformationGroup") Export
	
	FormAttributeList = Form.GetAttributes();
	
	FirstRun = True;
	For Each Attribute In FormAttributeList Do
		If Attribute.Name = "ContactInformationParameters" AND TypeOf(Form.ContactInformationParameters) = Type("Structure") Then
			FirstRun = False;
			Break;
		EndIf;
	EndDo;
	
	If FirstRun Then
		Return;
	EndIf;
	
	Parameters = FormContactInformationParameters(Form.ContactInformationParameters, ItemForPlacementName);
	
	ObjectRef = Object.Ref;
	ObjectMetadata = ObjectRef.Metadata();
	FullMetadataObjectName = ObjectMetadata.FullName();
	CIKindsGroupName = StrReplace(FullMetadataObjectName, ".", "");
	CIKindsGroup = ContactInformationKindByName(CIKindsGroupName);
	ItemForPlacementName = Parameters.GroupForPlacement;
	
	CITitleLocation = ?(ValueIsFilled(Parameters.TitleLocation), PredefinedValue(Parameters.TitleLocation), FormItemTitleLocation.Left);
	DeferredInitializationExecuted = Parameters.DeferredInitializationExecuted;
	DeferredInitialization = Parameters.DeferredInitialization AND Not DeferredInitializationExecuted;
	
	ContactInformationUsed = Common.ObjectAttributeValue(CIKindsGroup, "Used");
	If ContactInformationUsed = False Then
		AttributesToDeleteArray = Parameters.AddedAttributes;
	Else
		DeleteFormItemsAndCommands(Form, ItemForPlacementName);
		
		AttributesToDeleteArray = New Array;
		ObjectName = Object.Ref.Metadata().Name;
		
		StaticAttributes = Common.CopyRecursive(Parameters.ExcludedKinds);
		TabularSectionsNamesByCIKinds = Undefined;
		
		Filter = New Structure("ItemForPlacementName", ItemForPlacementName);
		ContactInformationAdditionalAttributesDetails = Form.ContactInformationAdditionalAttributesDetails.FindRows(Filter);
		For Each FormAttribute In ContactInformationAdditionalAttributesDetails Do
			
			If FormAttribute.IsTabularSectionAttribute Then
				
				If TabularSectionsNamesByCIKinds = Undefined Then
					Filter = New Structure("IsTabularSectionAttribute", True);
					TabularSectionCIKinds = Form.ContactInformationAdditionalAttributesDetails.Unload(Filter, "Kind");
					TabularSectionsNamesByCIKinds = TabularSectionsNamesByCIKinds(TabularSectionCIKinds, ObjectName);
				EndIf;
				
				TabularSectionName = TabularSectionsNamesByCIKinds[FormAttribute.Kind];
				AttributesToDeleteArray.Add("Object." + TabularSectionName + "." + FormAttribute.AttributeName);
				AttributesToDeleteArray.Add("Object." + TabularSectionName + "." + FormAttribute.AttributeName + "Value");
				
			ElsIf NOT FormAttribute.Property("IsHistoricalContactInformation")
				OR NOT FormAttribute.IsHistoricalContactInformation Then
				
				Index = StaticAttributes.Find(FormAttribute.Kind);
				
				If Index = Undefined Then // Attribute is created dynamically.
					If Not DeferredInitialization AND ValueIsFilled(FormAttribute.AttributeName) Then
						AttributesToDeleteArray.Add(FormAttribute.AttributeName);
					EndIf;
				Else
					StaticAttributes.Delete(Index);
				EndIf;
				
			EndIf;
		EndDo;
		For Each FormAttribute In ContactInformationAdditionalAttributesDetails Do
			Form.ContactInformationAdditionalAttributesDetails.Delete(FormAttribute);
		EndDo;
	EndIf;
	Form.ChangeAttributes(, AttributesToDeleteArray);
	
	AdditionalParameters = ContactInformationParameters();
	AdditionalParameters.ItemForPlacementName = ItemForPlacementName;
	AdditionalParameters.CITitleLocation = CITitleLocation;
	AdditionalParameters.ExcludedKinds = Parameters.ExcludedKinds;
	AdditionalParameters.HiddenKinds = Parameters.HiddenKinds;
	AdditionalParameters.DeferredInitialization = DeferredInitialization;
	OnCreateAtServer(Form, Object, AdditionalParameters);
	
	Parameters = FormContactInformationParameters(Form.ContactInformationParameters, ItemForPlacementName);
	Parameters.DeferredInitializationExecuted = DeferredInitializationExecuted;
	
EndProcedure

// AfterWriteAtServer form event handler.
// Called from the module of contact information owner object form upon the subsystem integration.
//
// Parameters:
//    Form - ManagedForm - an owner object form used for displaying contact information.
//    Object - Arbitrary - an owner object of contact information.
//
Procedure AfterWriteAtServer(Form, Object) Export
	
	ObjectName = Object.Ref.Metadata().Name;
	
	// Only for contact information of the tabular section.
	Filter = New Structure("IsTabularSectionAttribute", True);
	TabularSectionRows = Form.ContactInformationAdditionalAttributesDetails.Unload(Filter);
	TabularSectionsNamesByCIKinds = TabularSectionsNamesByCIKinds(TabularSectionRows, ObjectName);
	
	For Each TableRow In TabularSectionRows Do
		InformationKind = TableRow.Kind;
		AttributeName = TableRow.AttributeName;
		FormTabularSection = Form.Object[TabularSectionsNamesByCIKinds[InformationKind]];
		
		For Each FormTabularSectionRow In FormTabularSection Do
			
			Filter = New Structure;
			Filter.Insert("Kind", InformationKind);
			Filter.Insert("TabularSectionRowID", FormTabularSectionRow.TabularSectionRowID);
			FoundRows = Object.ContactInformation.FindRows(Filter);
			
			If FoundRows.Count() = 1 Then
				
				CIRow = FoundRows[0];
				FormTabularSectionRow[AttributeName] = CIRow.Presentation;
				FormTabularSectionRow[AttributeName + "Value"] = CIRow.Value;
				
			EndIf;
		EndDo;
	EndDo;
	
EndProcedure

// FillCheckProcessingAtServer form event handler.
// Called from the module of contact information owner object form upon the subsystem integration.
//
// Parameters:
//    Form - ManagedForm - an owner object form used for displaying contact information.
//    Object - CatalogObject, DocumentRef, FormStructureData - an owner object of contact information.
//    Cancel - Boolean - if True, errors were detected during the check.
//
Procedure FillCheckProcessingAtServer(Form, Object, Cancel) Export
	
	ObjectName = Object.Ref.Metadata().Name;
	ErrorsLevel = 0;
	PreviousKind = Undefined;
	
	TabularSectionsNamesByCIKinds = Undefined;
	
	For Each TableRow In Form.ContactInformationAdditionalAttributesDetails Do
		
		InformationKind = TableRow.Kind;
		InformationType = TableRow.Type;
		Comment   = TableRow.Comment;
		AttributeName  = TableRow.AttributeName;
		InformationKindProperty = Common.ObjectAttributesValues(InformationKind, "Mandatory, EditInDialogOnly");
		Mandatory = InformationKindProperty.Mandatory;
		
		If TableRow.IsTabularSectionAttribute Then
			
			If TabularSectionsNamesByCIKinds = Undefined Then
				Filter = New Structure("IsTabularSectionAttribute", True);
				TabularSectionCIKinds = Form.ContactInformationAdditionalAttributesDetails.Unload(Filter , "Kind");
				TabularSectionsNamesByCIKinds = TabularSectionsNamesByCIKinds(TabularSectionCIKinds, ObjectName);
			EndIf;
			
			TabularSectionName = TabularSectionsNamesByCIKinds[InformationKind];
			FormTabularSection = Form.Object[TabularSectionName];
			
			For Each FormTabularSectionRow In FormTabularSection Do
				
				Presentation = FormTabularSectionRow[AttributeName];
				Field = "Object." + TabularSectionName + "[" + (FormTabularSectionRow.LineNumber - 1) + "]." + AttributeName;
				
				If Mandatory AND IsBlankString(Presentation) AND Not InformationKind.DeletionMark Then
					
					Common.MessageToUser(
					StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = 'Поле ""%1"" не заполнено.'; en = 'Field ""%1"" is required.'; pl = 'Pole ""%1"" nie jest wypełnione.';de = 'Das ""%1"" Feld ist nicht ausgefüllt.';ro = 'Câmpul ""%1"" nu este completat.';tr = '""%1"" alanı doldurulmadı.'; es_ES = 'El ""%1"" campo no está rellenado.'"), InformationKind.Description),,Field);
					CurrentErrorsLevel = 2;
					
				Else
					
					Value = FormTabularSectionRow[AttributeName + "Value"];
					
					CurrentErrorsLevel = CheckContactInformationFilling(Presentation, Value, InformationKind,
						InformationType, AttributeName, , Field);
					
					FormTabularSectionRow[AttributeName] = Presentation;
					FormTabularSectionRow[AttributeName + "Value"] = Value;
					
				EndIf;
				
				ErrorsLevel = ?(CurrentErrorsLevel > ErrorsLevel, CurrentErrorsLevel, ErrorsLevel);
				
			EndDo;
			
		Else
			
			FormItem = Form.Items.Find(AttributeName);
			If FormItem = Undefined Or InformationKind.DeletionMark Then
				Continue; // Item was not created. Deferred initialization was not called.
			EndIf;
			
			If (InformationKindProperty.EditInDialogOnly 
				Or InformationType = Enums.ContactInformationTypes.WebPage)
				AND Not ContactsManagerClientServer.ContactsFilledIn(String(Form[AttributeName])) Then
				Presentation = "";
			Else
				Presentation = Form[AttributeName];
			EndIf;
			
			If InformationKind <> PreviousKind AND Mandatory AND IsBlankString(Presentation)
				AND Not HasOtherRowsFilledWithThisContactInformationKind(Form, TableRow, InformationKind) Then
				// And no other strings with data for contact information kinds with multiple values.
				
				Common.MessageToUser(
				StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = 'Поле ""%1"" не заполнено.'; en = 'Field ""%1"" is required.'; pl = 'Pole ""%1"" nie jest wypełnione.';de = 'Das ""%1"" Feld ist nicht ausgefüllt.';ro = 'Câmpul ""%1"" nu este completat.';tr = '""%1"" alanı doldurulmadı.'; es_ES = 'El ""%1"" campo no está rellenado.'"), InformationKind.Description),,, AttributeName);
				CurrentErrorsLevel = 2;
				
			Else
				
				CurrentErrorsLevel = CheckContactInformationFilling(Presentation, TableRow.Value,
					InformationKind, InformationType, AttributeName, Comment);
				
			EndIf;
			
			ErrorsLevel = ?(CurrentErrorsLevel > ErrorsLevel, CurrentErrorsLevel, ErrorsLevel);
			
		EndIf;
		
		PreviousKind = InformationKind;
		
	EndDo;
	
	If ErrorsLevel <> 0 Then
		Cancel = True;
	EndIf;
	
EndProcedure

// BeforeWriteAtServer form event handler.
// Called from the module of contact information owner object form upon the subsystem integration.
//
// Parameters:
//    Form - ManagedForm - an owner object form used for displaying contact information.
//    Object - CatalogObject, DocumentRef - an owner object of contact information.
//             FormStructureData - an object containing a tabular section with contact information. 
//                                    Supports hidden kinds of contact information only for already 
//                                    existing objects as it is impossible to set a reference for a new object.
//    Cancel - Boolean - if True, the object was not written as errors occurred while recording.
//
Procedure BeforeWriteAtServer(Form, Object, Cancel = False) Export
	
	ContactInformation = ContactInformationFromFormAttributes(Form, Object);
	
	IsMainObjectParameters  = True;
	ContactInformationParameters = Undefined;
	HiddenKinds                = New Array;
	
	DefineContactInformationParametersByOwner(Form, Object, ContactInformationParameters, IsMainObjectParameters, HiddenKinds);
	
	If Object.Ref.IsEmpty() AND TypeOf(Object) <> Type("FormDataStructure") Then
		
		If IsMainObjectParameters Then
			
			NewRef = Object.GetNewObjectRef();
			ObjectManager = Common.ObjectManagerByRef(Object.Ref);
			If NewRef = ObjectManager.EmptyRef() Then
				Object.SetNewObjectRef(ObjectManager.GetRef());
			EndIf;
			ContactInformationParameters.Owner = Object.GetNewObjectRef();
			
		Else
			Return;
		EndIf;
		
	EndIf;
	
	If HiddenKinds.Count() = 0 Then
		Object.ContactInformation.Clear();
	Else
		
		Index = Object.ContactInformation.Count() -1;
		While Index >= 0 Do
			TableRow = Object.ContactInformation.Get(Index);
			If HiddenKinds.Find(TableRow.Kind) = Undefined Then
				Object.ContactInformation.Delete(TableRow);
			EndIf;
			Index = Index - 1;
		EndDo;
		
	EndIf;
	
	SetObjectContactInformation(Object, ContactInformation);
	
EndProcedure

// Adds (deletes) an input field or a comment to a form, updating data.
// Called from the form module of the contact information owner object.
//
// Parameters:
//    Form - ManagedForm - an owner object form used for displaying contact information.
//    Object - Arbitrary - an owner object of contact information.
//    Result - Arbitrary - an optional internal attribute received from the previous event handler.
//
// Returns:
//    Undefined - a value is not used, backward compatibility.
//
Function UpdateContactInformation(Form, Object, Result = Undefined) Export
	
	If Result = Undefined Then
		Return Undefined;
	EndIf;
	
	If Result.Property("IsCommentAddition") Then
		ModifyComment(Form, Result.AttributeName, Result.ItemForPlacementName);
	ElsIf Result.Property("KindToAdd") Then
		AddContactInformationRow(Form, Result, Result.ItemForPlacementName);
	ElsIf Result.Property("ReorderItems") Then
		
		Filter = New Structure("AttributeName", Result.FirstItem);
		ContactInformationDetails = Form.ContactInformationAdditionalAttributesDetails;
		FirstItem = ContactInformationDetails.FindRows(Filter)[0];
		Filter = New Structure("AttributeName", Result.SecondItem);
		SecondItem = ContactInformationDetails.FindRows(Filter)[0];
		
		PropertiesToTransferList = "Comment,Presentation,Value";
		TemporaryBuffer = New Structure(PropertiesToTransferList);
		
		FillPropertyValues(TemporaryBuffer, FirstItem);
		FillPropertyValues(FirstItem, SecondItem, PropertiesToTransferList);
		FillPropertyValues(SecondItem, TemporaryBuffer);
		
		Form[Result.FirstItem] = FirstItem.Presentation;
		Form[Result.SecondItem] = SecondItem.Presentation;
		
		Form.Items[Result.FirstItem].ExtendedTooltip.Title = FirstItem.Comment;
		Form.Items[Result.SecondItem].ExtendedTooltip.Title = SecondItem.Comment;
		
	EndIf;
	
	If Result.Property("UpdateConextMenu") Then
		If Result.Property("ItemForPlacementName") Then
			UpdateConextMenu(Form, Result.ItemForPlacementName);
			
			If Result.Property("AttributeName") Then
				ContactInformationDetails = Form.ContactInformationAdditionalAttributesDetails;
				Filter = New Structure("AttributeName", Result.AttributeName);
				FoundRow = ContactInformationDetails.FindRows(Filter)[0];
				If ContactsManagerClientServer.IsJSONContactInformation(FoundRow.Value) Then
					ContactInformationByFields = ContactsManagerInternal.JSONStringToStructure(FoundRow.Value);
					ContactInformationByFields.Comment = ?(Result.Property("Comment"), Result.Comment, "");
					FoundRow.Value = ContactsManagerInternal.ToJSONStringStructure(ContactInformationByFields);
				EndIf;
			EndIf;
			
		Else
			For each PlacementItemName In Form.ContactInformationParameters Do
				UpdateConextMenu(Form, PlacementItemName.Key);
			EndDo;
		EndIf;
	EndIf;
	
	Return Undefined;
	
EndFunction

// FillingProcessing event subscription handler.
//
// Parameters:
//  Source             - Arbitrary - an object containing contact information.
//  FillingData - Structure - data with contact information to fill in the object.
//  FillingText      - String - not used.
//  StandardProcessing - Boolean - not used.
//
Procedure FillContactInformationProcessing(Source, FillingData, FillingText, StandardProcessing) Export
	
	ObjectContactInformationFillingProcessing(Source, FillingData);
	
EndProcedure

// The BeforeWrite event subscription handler for updating contact information for lists.
//
// Parameters:
//  Object - Arbitrary - an object containing contact information.
//  Cancel - Boolean - not used, backward compatibility.
//
Procedure ProcessingContactsUpdating(Object, Cancel) Export
	
	If Object.DataExchange.Load Then
		Return;
	EndIf;
	
	UpdateContactInformationForLists(Object);
	
EndProcedure

// FillingProcessing event subscription handler for documents.
//
// Parameters:
//  Source - Arbitrary - an object containing contact information.
//  FillingData - Structure - data with contact information to fill in the object.
//  FillingText - String, Undefined - filling data of the Description attribute.
//  StandardProcessing - Boolean - not used.
//
Procedure DocumentContactInformationFilling(Source, FillingData, FillingText, StandardProcessing) Export
	
	ObjectContactInformationFillingProcessing(Source, FillingData);
	
EndProcedure

// Executes deferred initialization of attributes and contact information items.
//
// Parameters:
//  Form                    - ManagedForm - an owner object form used for displaying contact information.
//  Object                   - Arbitrary - an owner object of contact information.
//  ItemForPlacementName - String - a group name where the contact information is placed.
//
Procedure ExecuteDeferredInitialization(Form, Object, ItemForPlacementName = "ContactInformationGroup") Export
	
	ContactInformationStub = Form.Items.Find("ContactInformationStub"); // temporary item
	If ContactInformationStub <> Undefined Then
		Form.Items.Delete(ContactInformationStub);
	EndIf;
	
	ContactInformationParameters = FormContactInformationParameters(Form.ContactInformationParameters, ItemForPlacementName);
	
	ContactInformationAdditionalAttributesDetails = Form.ContactInformationAdditionalAttributesDetails.Unload(, "Kind, Presentation, Value, Comment");
	Form.ContactInformationAdditionalAttributesDetails.Clear();
	
	CITitleLocation = ?(ValueIsFilled(ContactInformationParameters.TitleLocation), PredefinedValue(ContactInformationParameters.TitleLocation), FormItemTitleLocation.Left);
	OnCreateAtServer(Form, Object, ItemForPlacementName, CITitleLocation, ContactInformationParameters.ExcludedKinds);
	ContactInformationParameters = FormContactInformationParameters(Form.ContactInformationParameters, ItemForPlacementName);
	
	For Each ContactInformationKind In ContactInformationParameters.ExcludedKinds Do
		
		Filter = New Structure("Kind", ContactInformationKind);
		RowsArray = Form.ContactInformationAdditionalAttributesDetails.FindRows(Filter);
		
		If RowsArray.Count() > 0 Then
			SavedValue = ContactInformationAdditionalAttributesDetails.FindRows(Filter)[0];
			CurrentValue = RowsArray[0];
			FillPropertyValues(CurrentValue, SavedValue);
			Form[CurrentValue.AttributeName] = SavedValue.Presentation;
		EndIf;
	EndDo;
	
	If Form.Items.Find("EmptyDecorationContactInformation") <> Undefined Then
		Form.Items.EmptyDecorationContactInformation.Visible = False;
	EndIf;
	
	ContactInformationParameters.DeferredInitializationExecuted = True;
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Auxiliary functions and constructors.

// Returns a reference to a contact information kind.
// If a kind is not found by name, then the search is executed by names of predefined items.
//
// Parameters:
//  Name - String - a unique name of a contact information kind.
// 
// Returns:
//  CatalogRef.ContactInformationKinds - a reference to an item of the contact information kind catalog.
//
Function ContactInformationKindByName(Name) Export
	
	Kind = Undefined;
	If Not InfobaseUpdate.InfobaseUpdateInProgress() Then
		Kinds = ContactInformationManagementInternalCached.ContactInformationKindsByName();
		Kind = Kinds.Get(Name);
	Else
		Kinds = PredefinedContactInformationKinds(Name);
		If Kinds.Count() > 0 Then
			Kind = Kinds[0].Ref;
		EndIf;
	EndIf;
	
	If Kind <> Undefined Then
		Return Kind;
	EndIf;
	
	Return Catalogs.ContactInformationKinds[Name];
	
EndFunction

// Details of contact information parameters used in the OnCreateAtServer handler.
// 
// Returns:
//  Structure - contact information parameters.
//   * PostalCode                   - String - an address postal code.
//   * Country                   - String - an address country.
//   * PremiseType             - String - a description of premise type that will be set in the 
//                                         address input form. Apartment by default.
//   * ItemForPlacementName - String - a group, to which the contact information items will be placed.
//   * ExcludedKinds - Array - contact information kinds that will be created on the form during 
//                                deferred initialization only after the ContactsManager.ExecuteDeferredInitialization procedure is called.
//   * HiddenKinds - Array  - contact information kinds that do not need to be displayed on the form.
//   * DeferredInitialization  - Boolean - if True, generation of contact information fields on the form will be deferred.
//   * CITitleLocation     - FormItemTitleLocation - can take the following values:
//                                                             FormItemTitleLocation.Top or
//                                                             FormItemTitleLocation.Left (by default).
//
Function ContactInformationParameters() Export

	Result = New Structure;
	Result.Insert("PremiseType", "Apartment");
	Result.Insert("IndexOf", Undefined);
	Result.Insert("Country", Undefined);
	Result.Insert("DeferredInitialization", False);
	Result.Insert("CITitleLocation", "");
	Result.Insert("ExcludedKinds", Undefined);
	Result.Insert("HiddenKinds", Undefined);
	Result.Insert("ItemForPlacementName", "ContactInformationGroup");
	
	Return Result;

EndFunction 

////////////////////////////////////////////////////////////////////////////////
// Check and information about the address

// Checks contact information.
//
// Parameters:
//   Presentation - String - a contact information presentation. Used if it is impossible to 
//                           determine a presentation based on the FieldsValues parameter (the Presentation field is not available).
//   FieldsValues - String, Structure, Map, ValueList - details of contact information fields.
//   InformationKind  - CatalogRef.ContactInformationKinds - used to determine a type if it is 
//                                                               impossible to determine it by the FieldsValues parameter.
//   InformationType  - EnumRef.ContactInformationTypes - a contact information type.
//   AttributeName - String - an attribute name on the form.
//   Comment - String - a comment text.
//   AttributePath - String - an attribute path.
// 
// Returns:
//   Number - an error level, 0 - no errors.
//
Function ValidateContactInformation(Presentation, FieldsValues, InformationKind, InformationType,
	AttributeName, Comment = Undefined, AttributePath = "") Export
	
	SerializationText = ?(IsBlankString(FieldsValues), Presentation, FieldsValues);

	If ContactsManagerClientServer.IsXMLContactInformation(SerializationText) Then
		CIObject = ContactInformationInJSON(SerializationText);
	Else
		CIObject = FieldsValues;
	EndIf;
	
	// CheckSSL
	If InformationType = Enums.ContactInformationTypes.EmailAddress Then
		ErrorsLevel = EmailFIllingErrors(CIObject, InformationKind, AttributeName, AttributePath);
	ElsIf InformationType = Enums.ContactInformationTypes.Address Then
		ErrorsLevel = AddressFIllErrors(CIObject, InformationKind, AttributeName);
	ElsIf InformationType = Enums.ContactInformationTypes.Phone Then
		ErrorsLevel = PhoneFillingErrors(CIObject, InformationKind, AttributeName);
	ElsIf InformationType = Enums.ContactInformationTypes.Fax Then
		ErrorsLevel = PhoneFillingErrors(CIObject, InformationKind, AttributeName);
	ElsIf InformationType = Enums.ContactInformationTypes.WebPage Then
		ErrorsLevel = WebPageFillingErrors(CIObject, InformationKind, AttributeName);
	Else
		// No other checks are made.
		ErrorsLevel = 0;
	EndIf;
	
	Return ErrorsLevel;
	
EndFunction

////////////////////////////////////////////////////////////////////////////////
// Updating an infobase.

// Sets properties of a contact information group.
//
// Parameters:
//    Parameters - Structure - contains a structure with the following fields:
//        * Code    - String   - a code of a contact information kind to identify the item.
//        * Description - String   - a description of a contact information kind.
//        * Used - Boolean - indicates whether a contact information kind is used. Default value is True.
// Returns:
//   CatalogRef.ContactInformationKinds - a reference to the group.
//
Function SetContactInformationKindGroupProperties(Parameters) Export
	
	Object = ContactInformationKindObject(Parameters.Name, True);
	
	Object.PredefinedKindName = Parameters.Name;
	Object.Parent = Parameters.Group;
	Object.Used = Parameters.Used;
	
	If IsBlankString(Parameters.Description) Then
		
		Descriptions = ContactInformationManagementInternalCached.ContactInformationKindsDescriptions();
		For each Language In Metadata.Languages Do
			Presentation = Descriptions[Language.LanguageCode][TrimAll(Object.PredefinedKindName)];
			If ValueIsFilled(Presentation) Then
				If CurrentLanguage() = Metadata.DefaultLanguage Then
					Object.Description = Presentation;
				Else
					NewString = Object.Presentations.Add();
					NewString.LanguageCode     = Language.LanguageCode;
					NewString.Description = Presentation;
				EndIf;
			EndIf;
		EndDo;
	Else
		Object.Description = Parameters.Description;
	EndIf;
	
	InfobaseUpdate.WriteObject(Object);
	
	Return Object.Ref;
	
EndFunction

// Sets properties of a contact information kind.
// Note. When using the Order parameter, make sure that the assigned values are unique.
//  If any non-unique order values are identified in this same group after update, users cannot 
//  further edit order values.
//  Generally, it is recommended that you do not use this parameter (the order will not change) or set it to 0
//  (in this case, the order will be assigned automatically in the Item ordering subsystem upon the procedure execution).
//  To reassign several contact information kinds in a given relative order without moving them to 
//  the beginning of the list, you only need to call the procedure in sequence for each required contact information kind (with order value set to 0).
//  If a predefined contact information kind is added to the infobase, do not assign its order explicitly.
//
// Parameters:
//    Parameters - Structure - contains a structure with the following fields:
//        * Kind - CatalogRef.ContactInformationKinds, String   - a reference to the contact 
//                                                                      information kind or a predefined item ID.
//        * Type - EnumRef.ContactInformationTypes - a type of contact information or its ID.
//                                                                      
//        * Order - Number, Undefined - contact information kind order, a relative position in the 
//                                                                      list:
//                                                                          Undefined - do not reassign.
//                                                                          0 - assign automatically.
//                                                                          Number > 0 - assign the specified order.
//        * CanChangeEditingMethod - Boolean - True if you can change the editing method only in the 
//                                                                      dialog box, otherwise, False.
//        * EditInDialogOnly - Boolean                     - True if data can be edited in the dialog box only,
//                                                                      otherwise, False.
//        * Mandatory                                    - Boolean - True if the field is mandatory, 
//                                                                      otherwise, False.
//        * AllowMultipleValuesInput - Boolean - indicates whether additional input fields are used 
//                                                                      for this kind.
//        * DenyEditingByUser - Boolean - indicates that editing of contact information kind 
//                                                                      properties by a user is 
//                                                                      unavailable.
//        * StoreChangeHistory - Boolean -                          indicates whether the change 
//                                                                      history of a contact information kind is stored.
//                                                                      Default value is False.
//        * Used - Boolean -                                     indicates whether a contact information kind is used.
//                                                                      Default value is True.
//        * FieldKindOther - String - appearance of the Other type field. Possible values:
//                                                                      MultilineWide, SingleLineWide, SingleLineNarrow.
//                                                                      The default value is SingleLineWide.
//        * ValidationSettings - Structure, Undefined - validation settings of a contact information kind.
//            For the Address type - a structure containing the following fields:
//                * OnlyNationalAddres - Boolean - True if you can enter only local addresses.
//                * CheckValidity        - Boolean - True if it is required to prevent the user from 
//                                                          saving incorrect addresses.
//                * ProhibitInvalidEntry   - Boolean - obsolete. All passed values are ignored.
//                                                          To prevent users from saving incorrect 
//                                                          addresses, use the CheckValidity parameter instead.
//                * HideObsoleteAddress   - Boolean - if True, hide obsolete addresses during input 
//                                                          (only if OnlyNationalAddress = True).
//                * IncludeCountryInPresentation - Boolean - True if the country description must be 
//                                                          included in the address presentation.
//            For the EmailAddress type - a structure containing the following fields:
//                * CheckValidity - Boolean - True if it is required to prevent users from saving an 
//                                                          incorrect email address.
//                * ProhibitInvalidEntry   - Boolean - obsolete. All passed values are ignored.
//                                                          To prevent users from saving incorrect 
//                                                          addresses, use the CheckValidity parameter instead.
//            For any other types and default settings, Undefined is used.
//
Procedure SetContactInformationKindProperties(Parameters) Export
	
	If Not ValueIsFilled(Parameters.Kind) Then
		Object = ContactInformationKindObject(Parameters.Name);
	ElsIf TypeOf(Parameters.Kind) = Type("String") Then
		Object = ContactInformationKindObject(Parameters.Kind);
	Else
		Object = Parameters.Kind.GetObject();
	EndIf;
	
	FillPropertyValues(Object, Parameters, "Type, CanChangeEditMethod,
	|EditInDialogOnly, Mandatory, AllowMultipleValueInput,
	|DenayEditingByUser, Used, StoreChangeHistory ,InternationalAddressFormat");
	
	If IsBlankString(Parameters.Description) Then
		
		Descriptions = ContactInformationManagementInternalCached.ContactInformationKindsDescriptions();
		For each Language In Metadata.Languages Do
			Presentation = Descriptions[Language.LanguageCode][TrimAll(Object.PredefinedKindName)];
			If ValueIsFilled(Presentation) Then
				If CurrentLanguage() = Metadata.DefaultLanguage Then
					Object.Description = Presentation;
				Else
					NewString = Object.Presentations.Add();
					NewString.LanguageCode     = Language.LanguageCode;
					NewString.Description = Presentation;
				EndIf;
			EndIf;
		EndDo;
	Else
		Object.Description = Parameters.Description;
	EndIf;
	
	If ValueIsFilled(Parameters.Name) Then
		Object.PredefinedKindName = Parameters.Name;
	EndIf;
	
	If IsBlankString(Object.PredefinedKindName) Then
		Object.PredefinedKindName = Object.PredefinedDataName;
	EndIf;
	
	If IsBlankString(Object.Parent) Then
		Object.Parent = Parameters.Group;
	EndIf;
	Object.NameOfGroup = Common.ObjectAttributeValue(Object.Parent, "PredefinedKindName");
	
	If Parameters.Type = Enums.ContactInformationTypes.Other Then
		Object.FieldKindOther = Parameters.FieldKindOther;
	EndIf;
	
	ValidationSettings = Parameters.ValidationSettings;
	ValidateSettings = TypeOf(ValidationSettings) = Type("Structure");
	
	If ValidateSettings AND Parameters.Type = Enums.ContactInformationTypes.Address Then
		FillPropertyValues(Object, ValidationSettings);
	ElsIf ValidateSettings AND Parameters.Type = Enums.ContactInformationTypes.EmailAddress Then
		SetValidationAttributesValues(Object, ValidationSettings);
	ElsIf ValidateSettings AND Parameters.Type = Enums.ContactInformationTypes.Phone Then
		Object.PhoneWithExtension = ValidationSettings.PhoneWithExtension;
	Else
		SetValidationAttributesValues(Object);
	EndIf;
	
	Result = ContactsManagerInternal.CheckContactsKindParameters(Object);
	
	If Result.HasErrors Then
		Raise Result.ErrorText;
	EndIf;
	
	If Parameters.Order <> Undefined Then
		Object.AddlOrderingAttribute = Parameters.Order;
	EndIf;
	
	ValueUsedForGroup = Common.ObjectAttributeValue(Object.Parent, "Used");
	
	If ValueUsedForGroup = False AND Object.Used Then
		
		BeginTransaction();
		Try
			
			Lock = New DataLock;
			LockItem = Lock.Add("Catalog.ContactInformationKinds");
			LockItem.SetValue("Ref", Object.Parent.Ref);
			Lock.Lock();
			
			Parent = Object.Parent.GetObject();
			Parent.Used = True;
			InfobaseUpdate.WriteObject(Parent);
			
			InfobaseUpdate.WriteObject(Object);
			CommitTransaction();
		Except
			RollbackTransaction();
			Raise;
		EndTry;
		
	Else
		InfobaseUpdate.WriteObject(Object);
	EndIf;
	
EndProcedure

// Returns a structure of parameters of a contact information kind group.
//
// Parameters:
//    ContactInformationGroup - CatalogRef.ContactInformationKinds - a contact information group.
//
// Returns:
//    Structure - contains a structure with the following fields:
//        * Name          - String - a unique name of a contact information kind.
//        * Description - String - a description of a contact information kind.
//        * Group - CatalogRef.ContactInformationKinds - a reference to a group (parent) of a catalog item.
//        * Used - Boolean - indicates whether a contact information kind is used. Default value is True.
//
Function ContactInformationKindGroupParameters(ContactInformationGroup = Undefined) Export
	
	Result = ContactInformationKindCommonParametersDetails();
	
	If TypeOf(ContactInformationGroup ) = Type("CatalogRef.ContactInformationKinds") Then
		Values = Common.ObjectAttributesValues(ContactInformationGroup, "PredefinedKindName, PredefinedDataName, Parent, Description, Used");
		Result.Name = ?(ValueIsFilled(Values.PredefinedKindName), Values.PredefinedKindName, Values.PredefinedDataName);
		Result.Group = Values.Parent;
		Result.Description = Values.Description;
		Result.Used = Values.Used;
	EndIf;
	
	Return Result;
	
EndFunction

// Returns a structure of contact information kind parameters for a particular type.
// 
// Parameters:
//    ContactInformationKindOrType - EnumRef.ContactInformationTypes, String - a contact information type.
//                                  - CatalogRef.ContactInformationKinds - a contact information kind for
//                                  filling the ValidationSettings property.
//
// Returns:
//    Structure - contains a structure with the following fields:
//        * Name          - String - a unique name of a contact information kind.
//        * Description - String - a description of a contact information kind.
//        * Kind - CatalogRef.ContactInformationKinds, String   - a reference to the contact 
//                                                                      information kind or a predefined item ID.
//        * Group - CatalogRef.ContactInformationKinds - a reference to a group (parent) of a catalog item.
//        * Type - EnumRef.ContactInformationTypes - a type of contact information or its ID.
//        * Order - Number, Undefined - contact information kind order, a relative position in the list:
//                                          Undefined - do not reassign.
//                                          0 - assign automatically.
//                                          Number > 0 - assign the specified order.
//                                          Note. When using the Order parameter, make sure that the 
//                                          assigned values are unique. If any non-unique order 
//                                          values are identified in this same group after update, 
//                                          users cannot further edit order values. Generally, it is 
//                                          recommended that you do not use this parameter (the 
//                                          order will not change) or set it to 0 (in this case, the 
//                                          order will be assigned automatically in the Item ordering subsystem upon the procedure execution). 
//                                          To reassign several contact information kinds in a given 
//                                          relative order without moving them to the beginning of 
//                                          the list, you only need to call the procedure in sequence for each required contact information kind (with order value set to 0). 
//                                          If a predefined contact information kind is added to the 
//                                          infobase, do not assign its order explicitly.
//        * CanChangeEditingMethod - Boolean      - True if you can change the editing method only 
//                                                          in the dialog box, otherwise, False.
//        * EditInDialogOnly - Boolean           - True if data can be edited in the dialog box only,
//                                                          otherwise, False.
//        * StoreChangeHistory     - Boolean - indicates whether the contact information change history can be stored. 
//                                                 Storing the history is allowed if the EditInDialogOnly flag is True.
//                                                 There is no property if there is no the ValidFrom attribute in the tabular section.
//        * Mandatory                          - Boolean - True if the field is mandatory, otherwise, 
//                                                         False.
//        * AllowMultipleValuesInput - Boolean       - indicates whether additional input fields are 
//                                                         used for this kind.
//        * DenyEditingByUser - Boolean  - indicates that editing of contact information kind 
//                                                         properties by a user is unavailable.
//                                                         
//        * Used - Boolean -                        indicates whether a contact information kind is used.
//                                                         Default value is True.
//        * ValidationSettings - Structure, Undefined    - validation settings of a contact information kind.
//            For the Address type - a structure containing the following fields:
//                * OnlyNationalAddres - Boolean - True if you can enter only local addresses.
//                * CheckValidity - Boolean - True if it is required to prevent users from saving an 
//                                                          incorrect address (if OnlyNationalAddress = True).
//                * HideObsoleteAddress   - Boolean - if True, hide obsolete addresses during input 
//                                                          (only if OnlyNationalAddress = True).
//                * IncludeCountryInPresentation - Boolean - True if the country description must be 
//                                                          included in the address presentation.
//            For the EmailAddress type - a structure containing the following fields:
//                * CheckValidity - Boolean - True if it is required to prevent users from saving an 
//                                                          incorrect email address.
//            For any other types and default settings, Undefined is used.
//
Function ContactInformationKindParameters(ContactInformationKindOrType = Undefined) Export
	
	If TypeOf(ContactInformationKindOrType) = Type("CatalogRef.ContactInformationKinds") Then
		
		KindParameters = ParametersFromContactInformationKind(ContactInformationKindOrType);
		
	Else
		
		If TypeOf(ContactInformationKindOrType) = Type("String") Then
			TypeToSet = Enums.ContactInformationTypes[ContactInformationKindOrType];
		Else
			TypeToSet = ContactInformationKindOrType;
		EndIf;
		
		KindParameters = ContactInformationParametersDetails(TypeToSet);
	EndIf;
	
	Return KindParameters;
	
EndFunction

// Writes contact information from XML to the fields of the Object contact information tabular section.
//
// Parameters:
//    Object - AnyRef - a reference to the configuration object containing contact information tabular section.
//    Value - String - contact information in the internal JSON format.
//    InformationKind - Catalog.ContactInformationKinds - a reference to a contact information kind.
//    InformationType - Enum.ContactInformationTypes - a contact information type.
//    RowID - Number - a row ID of the tabular section.
//    Date - Date - the date, from which contact information record is valid. It is used for storing 
//                  the history of contact information changes.
Procedure WriteContactInformation(Object, Val Value, InformationKind, InformationType, RowID = 0, Date = Undefined) Export
	
	If IsBlankString(Value) Then
		Return;
	EndIf;
	
	If ContactsManagerClientServer.IsXMLContactInformation(Value) Then
		CIObject = ContactsManagerInternal.ContactInformationToJSONStructure(Value, InformationType);
	Else
		CIObject = ContactsManagerInternal.JSONToContactInformationByFields(Value, InformationType);
	EndIf;
	
	If Not ContactsManagerInternal.ContactsFilledIn(CIObject) Then
		Return;
	EndIf;
	
	NewRow = Object.ContactInformation.Add();
	NewRow.Presentation = CIObject.Value;
	NewRow.Value      = ContactsManagerInternal.ToJSONStringStructure(CIObject);
	NewRow.FieldsValues = ContactsManagerInternal.ContactsFromJSONToXML(CIObject, InformationType);
	NewRow.Kind           = InformationKind;
	NewRow.Type           = InformationType;
	If ValueIsFilled(Date) Then
		NewRow.ValidFrom    = Date;
	EndIf;
	
	If ValueIsFilled(RowID) Then
		NewRow.TabularSectionRowID = RowID;
	EndIf;
	
	// Filling in additional attributes of the tabular section.
	FillContactInformationTechnicalFields(NewRow, CIObject, InformationType);
	
EndProcedure

// Updates a contact information presentation in internal field KindForList that is used to display 
// it in dynamic lists and reports.
//
// Parameters:
//  Object - ObjectRef - a reference to the configuration object containing the contact information tabular section.
//
Procedure UpdateContactInformationForLists(Object = Undefined) Export
	
	If Object = Undefined Then
		ContactsManagerInternal.UpdateContactInformationForLists();
	Else
		If Object.Metadata().TabularSections.ContactInformation.Attributes.Find("KindForList") <> Undefined Then
			ContactsManagerInternal.UpdateCotactsForListsForObject(Object);
		EndIf;
	EndIf;
	
EndProcedure

// Executes deferred update of contact information for lists.
//
// Parameters:
//  Parameters    - Structure - parameters of the update handler.
//  BatchSize - Number - an optional parameter of batch size of data being processed in one startup.
//
Procedure UpdateContactsForListDeferred(Parameters, BatchSize = 1000) Export
	
	ObjectsWithKindForList = Undefined;
	Parameters.Property("ObjectsWithKindForList", ObjectsWithKindForList);
	
	If Parameters.ExecutionProgress.TotalObjectCount = 0 Then
		// calculating quantity
		Query = New Query;
		Query.Text = 
		"SELECT
		|	ContactInformationKinds.Ref,
		|CASE
		|	WHEN ContactInformationKinds.PredefinedKindName <> """"
		|	THEN ContactInformationKinds.PredefinedKindName
		|	ELSE ContactInformationKinds.PredefinedDataName
		|END AS PredefinedKindName
		|FROM
		|	Catalog.ContactInformationKinds AS ContactInformationKinds
		|WHERE
		|	ContactInformationKinds.IsFolder = TRUE";
		
		QueryResult = Query.Execute();
		DetailedRecordsSelection = QueryResult.Select();
		ObjectsWithKindForList = New Array;
		QueryText = "";
		Separator = "";
		
		QueryTemplate = "SELECT
		| COUNT(TableWithContactInformation.Ref) AS Count,
		| VALUETYPE(TableWithContactInformation.Ref) AS Ref
		|FROM
		| %1.%2 AS TableWithContactInformation
		| GROUP BY
		|	VALUETYPE(TableWithContactInformation.Ref)";
		
		While DetailedRecordsSelection.Next() Do
			If StrStartsWith(DetailedRecordsSelection.PredefinedKindName, "Catalog") Then
				ObjectName = Mid(DetailedRecordsSelection.PredefinedKindName, StrLen("Catalog") + 1);
				
				If Metadata.Catalogs.Find(ObjectName) <> Undefined Then
					ContactInformation = Metadata.Catalogs[ObjectName].TabularSections.ContactInformation;
					If ContactInformation.Attributes.Find("KindForList") <> Undefined Then
						QueryText = QueryText + Separator + StringFunctionsClientServer.SubstituteParametersToString(QueryTemplate, "Catalog", ObjectName);
						Separator = " UNION ALL ";
					EndIf;
				EndIf;
			ElsIf StrStartsWith(DetailedRecordsSelection.PredefinedKindName, "Document") Then
				ObjectName = Mid(DetailedRecordsSelection.PredefinedKindName, StrLen("Document") + 1);
				
				If Metadata.Documents.Find(ObjectName) <> Undefined Then
					ContactInformation = Metadata.Documents[ObjectName].TabularSections.ContactInformation;
					If ContactInformation.Attributes.Find("KindForList") <> Undefined Then
						QueryText = QueryText + Separator + StringFunctionsClientServer.SubstituteParametersToString(QueryTemplate, "Document", ObjectName);
						Separator = " UNION ALL ";
					EndIf;
				EndIf;
			EndIf;
		EndDo;
		
		If IsBlankString(QueryText) Then
			Parameters.ProcessingCompleted = False;
			Return;
		EndIf;
		Query = New Query(QueryText);
		QueryResult = Query.Execute().Select();
		Count = 0;
		ObjectsWithKindForList = New Array;
		While QueryResult.Next() Do
			Count = Count + QueryResult.Count;
			ObjectsWithKindForList.Add(QueryResult.Ref);
		EndDo;
		Parameters.ExecutionProgress.TotalObjectCount = Count;
		Parameters.Insert("ObjectsWithKindForList", ObjectsWithKindForList);
	EndIf;
	
	If ObjectsWithKindForList = Undefined OR ObjectsWithKindForList.Count() = 0 Then
		Return;
	EndIf;
	
	FullObjectNameWithKindForList = Metadata.FindByType(ObjectsWithKindForList.Get(0)).FullName();
	QueryText = " SELECT TOP " + Format(BatchSize, "NG=0") + "
	|	ContactInformation.Ref AS Ref
	|FROM
	|	" + FullObjectNameWithKindForList + ".ContactInformation AS ContactInformation
	|
	|GROUP BY
	|	ContactInformation.Ref
	|
	|HAVING
	|	SUM(CASE
	|			WHEN ContactInformation.KindForList = VALUE(Catalog.ContactInformationKinds.EmptyRef)
	|				THEN 0
	|				ELSE 1
	|		END) = 0";
	
	Query = New Query(QueryText);
	QueryResult = Query.Execute().Select();
	Count = QueryResult.Count();
	If Count > 0 Then
		While QueryResult.Next() Do
			Object = QueryResult.Ref.GetObject();
			UpdateContactInformationForLists(Object);
			InfobaseUpdate.WriteData(Object);
		EndDo;
		If Count < 1000 Then
			ObjectsWithKindForList.Delete(0);
		EndIf;
		Parameters.ExecutionProgress.ProcessedObjectsCount = Parameters.ExecutionProgress.ProcessedObjectsCount + Count;
	Else
		ObjectsWithKindForList.Delete(0);
	EndIf;
	
	If ObjectsWithKindForList.Count() > 0 Then
		Parameters.ProcessingCompleted = False;
	EndIf;
	
	Parameters.Insert("ObjectsWithKindForList", ObjectsWithKindForList);
	
EndProcedure

// Deletes information about the matching contact information kind catalog item and predefined value 
// that was marked as deleted. For a single call in update handlers of canceling predefined items of 
// the ContactInformationKinds catalog.
//
Procedure RemovePredefinedAttributeForContactInformationKinds() Export
	
	Query = New Query;
	Query.Text = 
	"SELECT
	|	ContactInformationKinds.Ref AS CIKind,
	|	ContactInformationKinds.PredefinedDataName AS PredefinedDataName,
	|	ISNULL(ContactInformationKinds.Parent.PredefinedDataName, """") AS Group,
	|	ContactInformationKinds.PredefinedKindName AS PredefinedKindName,
	|	ContactInformationKinds.Predefined AS Predefined
	|FROM
	|	Catalog.ContactInformationKinds AS ContactInformationKinds";
	
	ContactInformationKinds = Query.Execute().Unload();
	ContactInformationKinds.Indexes.Add("PredefinedKindName");
	
	For each Kind In ContactInformationKinds Do
		
		If Not Kind.Predefined Or Not StrStartsWith(Lower(Kind.PredefinedDataName), "delete") Then
			Continue;
		EndIf;
		
		PredefinedKindName = Mid(Kind.PredefinedDataName, StrLen("delete") + 1);
		If ContactInformationKinds.Find(PredefinedKindName, "PredefinedKindName") <> Undefined Then
			Continue;
		EndIf;
		
		CIKindObject = Kind.CIKind.GetObject();
		If Not CIKindObject.IsFolder Then
			CIKindObject.NameOfGroup = Mid(Kind.Group, StrLen("delete") + 1);
		EndIf;
		
		CIKindObject.PredefinedKindName = PredefinedKindName;
		CIKindObject.PredefinedDataName = "";
		InfobaseUpdate.WriteData(CIKindObject);
		
	EndDo;

	
EndProcedure

#Region ObsoleteProceduresAndFunctions

////////////////////////////////////////////////////////////////////////////////
// Backward compatibility.

// Obsolete. Use ContactsManager.ContactsByPresentation instead.
// Converts a contact information presentation into an XML string matching the structure
// of XDTO packages ContactInformation and Address.
// Correct conversion is not guaranteed for the addresses entered in free form.
//
//  Parameters:
//      Presentatin - String - a string presentation of contact information displayed to a user.
//      ExpectedKind  - CatalogRef.ContactInformationKinds, EnumRef.ContactInformationTypes,
//                      Structure - a kind or a type of contact information.
//
// Returns:
//      String - contact information in the XML format matching the structure of the XDTO packages ContactInformation and Address.
//
Function ContactsXMLByPresentation(Presentation, ExpectedKind) Export
	
	Return ContactsManagerInternal.XDTOContactsInXML(
	ContactsManagerInternal.XDTOContactsByPresentation(Presentation, ExpectedKind));
	
EndFunction

// Obsolete. Use AddressManager.PreviousContactInformationXMLFormat instead.
// Converts XML data to the previous contact information format.
//
// Parameters:
//    Data - String - contact information XML.
//    ShortFieldsComposition - Boolean - if False, fields missing in SSL versions earlier than 2.1.3 
//                                      are excluded from the fields composition.
//
// Returns:
//    String - a set of key-value pairs separated by line breaks.
//
Function PreviousContactInformationXMLFormat(Val Data, Val ShortFieldsComposition = False) Export
	
	If Metadata.CommonModules.Find("AddressManager") <> Undefined Then
		ModuleAddressManager = Common.CommonModule("AddressManager");
		Return ModuleAddressManager.PreviousContactInformationXMLFormat(Data, ShortFieldsComposition);
	EndIf;
	
	Return "";
	
EndFunction

// Obsolete. Use AddressManager.PreviousContactInformationXMLStructure instead.
// Converts data of a new contact information XML format to the structure of the old format.
//
// Parameters:
//   Data - String - contact information XML or a key-value pair.
//   ContactInformationKind - CatalogRef.ContactInformationKinds, Structure - contact information parameters.
//
// Returns:
//   Structure - a set of key-value pairs. Composition of properties for the address:
//        ** Country           - String - a text presentation of a country.
//        ** CountryCode - String - an ARCC country code.
//        ** PostalCode           - String - a postal code (only for local addresses).
//        ** State - String - a text presentation of the state (only for local addresses).
//        ** StateCode       - String - a local state code (only for local addresses).
//        ** StateShortForm - String - a short form of "state" (if OldFieldsComposition = False).
//        ** District - String - a text presentation of a district (only for local addresses).
//        ** DistrictShortForm - String - a short form of "district" (if OldFieldsComposition = False).
//        ** City - String - a text presentation of a city (only for local addresses).
//        ** CityShortForm - String - a short form of "city" (only for local addresses).
//        ** Locality  - String - a presentation of a locality (only for local addresses).
//        ** LocalityShortForm - String - a short form of "locality" (if OldFieldsComposition = False).
//        ** Street - String - a text presentation of a street (only for local addresses).
//        ** StreetShortForm - String - a short form of "street" (if OldFieldsComposition = False).
//        ** HouseType          - String - see AddressManagerClientServer. LocalAddressesAddressingObjectsTypes().
//        ** House - String - a text presentation of a house (only for local addresses).
//        ** BuildingUnitType       - String - see AddressManagerClientServer. LocalAddressesAddressingObjectsTypes().
//        ** BuildingUnit           - String - a building unit presentation (only for local addresses).
//        ** ApartmentType      - String - see AddressManagerClientServer. LocalAddressesAddressingObjectsTypes().
//        ** Apartment         - String - a text presentation of an apartment (only for local addresses).
//       Composition of properties for a phone:
//        ** CountryCode        - String - a country code. For example, +7.
//        ** CityCode        - String - a city code. For example, 495.
//        ** PhoneNumber    - String - a phone number.
//        ** Extension       - String - an extension.
//
Function PreviousContactInformationXMLStructure(Val Data, Val ContactInformationKind = Undefined) Export
	
	If Metadata.CommonModules.Find("AddressManager") <> Undefined Then
		ModuleAddressManager = Common.CommonModule("AddressManager");
		Return ModuleAddressManager.PreviousContactInformationXMLStructure(Data, ContactInformationKind);
	EndIf;
	
	Return New Structure;
	
EndFunction

// Obsolete. Use AddressManager.AddressInARCAFormat instead.
// Converts addresses of a new FIAS XML format to addresses of the ARCA format.
//
// Parameters:
//   Data - String - contact information XML or a key-value pair.
//
// Returns:
//   Structure - a set of key-value pairs. Composition of properties for the address:
//        ** Country           - String - a text presentation of a country.
//        ** CountryCode - String - an ARCC country code.
//        ** PostalCode           - String - a postal code (only for local addresses).
//        ** State - String - a text presentation of the state (only for local addresses).
//        ** StateCode       - String - a local state code (only for local addresses).
//        ** StateShortForm - String - a short form of "state" (if OldFieldsComposition = False).
//        ** District - String - a text presentation of a district (only for local addresses).
//        ** DistrictShortForm - String - a short form of "district" (if OldFieldsComposition = False).
//        ** City - String - a text presentation of a city (only for local addresses).
//        ** CityShortForm - String - a short form of "city" (only for local addresses).
//        ** Locality  - String - a presentation of a locality (only for local addresses).
//        ** LocalityShortForm - String - a short form of "locality" (if OldFieldsComposition = False).
//        ** Street - String - a text presentation of a street (only for local addresses).
//        ** StreetShortForm - String - a short form of "street" (if OldFieldsComposition = False).
//        ** HouseType          - String - see AddressManagerClientServer. LocalAddressesAddressingObjectsTypes.
//        ** House - String - a text presentation of a house (only for local addresses).
//        ** BuildingUnitType       - String - see AddressManagerClientServer. LocalAddressesAddressingObjectsTypes.
//        ** BuildingUnit           - String - a building unit presentation (only for local addresses).
//        ** ApartmentType      - String - see AddressManagerClientServer. LocalAddressesAddressingObjectsTypes.
//        ** Apartment         - String - a text presentation of an apartment (only for local addresses).
//        ** LocalAddress          - Boolean - if True, it is a local address.
//        ** Presentation    - String - a text presentation of an address.
//
Function AddressInARCAFormat(Val Data) Export
	
	If Metadata.CommonModules.Find("AddressManager") <> Undefined Then
		ModuleAddressManager = Common.CommonModule("AddressManager");
		Return ModuleAddressManager.AddressInARCAFormat(Data);
	EndIf;
	
	Return New Structure;
	
EndFunction

// Obsolete. Use AddressManager.AddressInfo instead.
// Returns address info as a structure of address parts and ARCA codes.
//
// Parameters:
//   Addresses                  - Array - XDTO objects or XML strings of contact information.
//   AdditionalParameters - Structure - contact information parameters.
//       * WithoutPresentations - Boolean - if True, the address presentation field will not be displayed.
//       * ARCACodes - Boolean - if True, it returns the structure with ARCA codes for all address parts.
//       * FullDescriptionOfShortForms - Boolean - if True, returns full description of address objects.
//       * DescriptionIncludesShortForm - Boolean - if True, the descriptions of address objects contain their short forms.
// Returns:
//   Array - contains structures array, structure content, see details of the AddressManager.AddressInfo function.
//
Function AddressesInfo(Addresses, AdditionalParameters = Undefined) Export
	
	If Metadata.CommonModules.Find("AddressManager") <> Undefined Then
		ModuleAddressManager = Common.CommonModule("AddressManager");
		Return ModuleAddressManager.AddressesInfo(Addresses, AdditionalParameters);
	EndIf;
	
	Return New Array;
	
EndFunction

// Obsolete. Use AddressManager.AddressInfo instead.
// Returns address info as a structure of address parts and ARCA codes.
//
// Parameters:
//   Address                  - String, XDTODataObject - an XDTO object or XML string of contact information.
//   AdditionalParameters - Structure - contact information parameters.
//       * WithoutPresentations - Boolean - if True, the address presentation field will not be displayed.
//       * ARCACodes - Boolean - if True, it returns the structure with ARCA codes for all address parts.
//       * FullDescriptionOfShortForms - Boolean - if True, returns full description of address objects.
//       * DescriptionIncludesShortForm - Boolean - if True, the descriptions of address objects contain their short forms.
// Returns:
//   Structure - a set of key-value pairs. Composition of properties for the address:
//        * Country           - String - a text presentation of a country.
//        * CountryCode - String - an ARCC country code.
//        * PostalCode           - String - a postal code.
//        * StateCode       - String - a code of a local state.
//        * State           - String - a text presentation of a local state.
//        * StateShortForm - String - a short form of "state".
//        * County            - String - a text presentation of county.
//        * CountyShortForm - String - a short form of "county."
//        * District            - String - a text presentation of a district.
//        * DistrictShortForm - String - a short form of "district."
//        * City            - String - a text presentation of a city.
//        * CityShortForm - String - a short form of "city."
//        * CityDistrict - String - a text presentation of a city district.
//        * CityDistrictShortForm - String - a short form of "city district."
//        * Locality - String - a text presentation of a locality.
//        * LocalityShortForm - String - a short form of "locality."
//        * Street            - String - a text presentation of a street.
//        * StreetShortForm - String - a short form of "street."
//        * AdditionalTerritory - String - a text presentation of an additional territory.
//        * AdditionalTerritoryShortForm - String - a short form of "additional territory."
//        * AdditionalTerritoryItem - String - a text presentation of an additional territory item.
//        * AdditionalTerritoryShortForm - String - a short form of "additional territory."
//        * Building - Structure - a structure with building address information.
//            ** BuildingType - String - an addressing object type of an RF address according to Order of FTS No. MMV-7-1/525 dated 08/31/2011.
//            ** Number - String  - a text presentation of a house number (only for local addresses).
//        * BuildingUnit - Array - contains structures (structure fields: BuildingUnitType and Number) that list address building units.
//        * Premises - Array - contains structures (structure fields: PremiseType and Number) that list address premises.
//        * ARCACodes           - Structure - ARCA codes if the ARCACodes parameter is set.
//           ** State          - String - an ARCA code of a state.
//           ** District           - String - an ARCA code of a district.
//           ** City           - String - an ARCA code of a city.
//           ** Locality - String - an ARCA code of a locality.
//           ** Street           - String - an ARCA code of a street.
//        * AdditionalCodes  - Structure - the following codes: RNCMT, RNCPS, IFTSICode, IFTSLECode, IFTSIAreaCode, and IFTSLEAreaCode.
Function AddressInfo(Address, AdditionalParameters = Undefined) Export
	
	If Metadata.CommonModules.Find("AddressManager") <> Undefined Then
		ModuleAddressManager = Common.CommonModule("AddressManager");
		Return ModuleAddressManager.AddressInfo(Address, AdditionalParameters);
	EndIf;
	
EndFunction

// Obsolete. Use AddressManager.ContactInformationAddressState instead.
// Returns a description of a local territorial entity for an address or a blank string if the territorial entity is not defined.
// If the passed string does not contain information on the address, an exception is thrown.
//
// Parameters:
//    XMLString - String - contact information XML.
//
// Returns:
//    String - a description
//
Function ContactInformationAddressState(Val XMLString) Export
	
	If Metadata.CommonModules.Find("AddressManager") <> Undefined Then
		ModuleAddressManager = Common.CommonModule("AddressManager");
		Return ModuleAddressManager.ContactInformationAddressState(XMLString);
	EndIf;
	
	Return "";
	
EndFunction

// Obsolete. Use AddressManager.ContactInformationAddressCity instead.
// Returns a city description for a local address and a blank string for a foreign address.
// If the passed string does not contain information on the address, an exception is thrown.
//
// Parameters:
//    XMLString - String - contact information XML.
//
// Returns:
//    String - a description
//
Function ContactInformationAddressCity(Val XMLString) Export
	
	If Metadata.CommonModules.Find("AddressManager") <> Undefined Then
		ModuleAddressManager = Common.CommonModule("AddressManager");
		Return ModuleAddressManager.ContactInformationAddressCity(XMLString);
	EndIf;
	
	Return "";
	
EndFunction

// Obsolete. Use ContactsManager.ObjectContactInformation instead.
// Gets values for a specified contact information type from an object.
//
// Parameters:
//    Ref                  - AnyRef - a reference to an owner object of contact information (a 
//                                            company, a counterparty, a partner, and so on).
//    ContactInformationType - EnumRef.ContactInformationTypes - the contact information type.
//
// Returns:
//    ValueTable - columns.
//        * Value - String - a string presentation of a value.
//        * Kind      - String - a presentation of a contact information kind.
//
Function ObjectContactInformationValues(Ref, ContactInformationType) Export
	
	ObjectsArray = New Array;
	ObjectsArray.Add(Ref);
	
	ObjectContactInformation = ObjectsContactInformation(ObjectsArray, ContactInformationType);
	
	Query = New Query;
	
	Query.SetParameter("ObjectContactInformation", ObjectContactInformation);
	
	Query.Text =
	"SELECT
	|	ObjectContactInformation.Presentation,
	|	ObjectContactInformation.Kind
	|INTO TTObjectContactInformation
	|FROM
	|	&ObjectContactInformation AS ObjectContactInformation
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ObjectContactInformation.Presentation AS Value,
	|	PRESENTATION(ObjectContactInformation.Kind) AS Kind
	|FROM
	|	TTObjectContactInformation AS ObjectContactInformation";
	
	Return Query.Execute().Unload();
	
EndFunction

// Obsolete. Use ContactsManager.ObjectContactInformation instead.
//  Returns values of all contact information of a particular kind for an owner object.
//
//  Parameters:
//    Ref                  - AnyRef - a reference to an owner object of contact information (a 
//                                              company, a counterparty, a partner, and so on).
//    ContactInformationKind - CatalogRef.ContactInformationKinds - the processing parameters.
//    Date                    - Date - an optional parameter, the date, from which contact 
//                                     information record is valid. It is used for storing the history of contact information changes.
//
//  Returns:
//      Value table - information. Columns:
//          * RowNumber     - Number     - a row number of the additional tabular section of the owner object.
//          * Presentation   - String    - a contact information presentation entered by a user.
//          * FieldsStructure  - Structure - information key-value pairs.
//
Function ObjectContactInformationTable(Ref, ContactInformationKind, Date = Undefined) Export
	
	ObjectMetadata = Ref.Metadata();
	
	Query = New Query;
	If ObjectMetadata.TabularSections.ContactInformation.Attributes.Find("ValidFrom") <> Undefined Then
		ValidFrom = ?(ValueIsFilled(Date), Date, CurrentSessionDate());
		QueryText = StringFunctionsClientServer.SubstituteParametersToString("SELECT ALLOWED 
		|	ContactInformation.Ref AS Object,
		|	ContactInformation.Kind AS Kind,
		|	MAX(ContactInformation.ValidFrom) AS ValidFrom
		|INTO ContactInformationSlice
		|FROM
		|	%1.ContactInformation AS ContactInformation
		|WHERE
		|	ContactInformation.Ref = &Ref
		|	AND ContactInformation.ValidFrom <= &ValidFrom
		|	AND ContactInformation.Kind <> VALUE(Catalog.ContactInformationKinds.EmptyRef)
		|	AND ContactInformation.Kind = &Kind
		|
		|GROUP BY
		|	ContactInformation.Kind,
		|	ContactInformation.Ref
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT ALLOWED
		|	ISNULL(ContactInformation.TabularSectionRowID, 0) AS LineNumber,
		|	ISNULL(ContactInformation.Presentation, "") AS Presentation,
		|	ISNULL(ContactInformation.FieldsValues, "")
		|FROM
		|	ContactInformationSlice AS ContactInformationSlice
		|		LEFT JOIN %1.ContactInformation AS ContactInformation
		|		ON ContactInformationSlice.Kind = ContactInformation.Kind
		|			AND ContactInformationSlice.ValidFrom = ContactInformation.ValidFrom
		|			AND ContactInformationSlice.Object = ContactInformation.Ref 
		|ORDER BY 
		| ContactInformation.TabularSectionRowID", ObjectMetadata.FullName());
		
		Query.SetParameter("ValidFrom", ValidFrom);
	Else
		QueryText = StringFunctionsClientServer.SubstituteParametersToString("SELECT 
		|	ContactInformation.TabularSectionRowID AS LineNumber,
		|	ContactInformation.Presentation                     AS Presentation,
		|	ContactInformation.FieldsValues                     AS FieldsValues
		|FROM
		|	%1.ContactInformation AS ContactInformation
		|WHERE
		|	ContactInformation.Ref = &Ref
		|	AND ContactInformation.Kind = &Kind
		|ORDER BY 
		| ContactInformation.TabularSectionRowID", ObjectMetadata.FullName());
		
	EndIf;
	
	Query.Text = QueryText;
	Query.SetParameter("Ref", Ref);
	Query.SetParameter("Kind", ContactInformationKind);
	
	Result = New ValueTable;
	Result.Columns.Add("LineNumber");
	Result.Columns.Add("Presentation");
	Result.Columns.Add("FieldsStructure");
	Result.Indexes.Add("LineNumber");
	
	Selection = Query.Execute().Select();
	While Selection.Next() Do
		DataString = Result.Add();
		FillPropertyValues(DataString, Selection, "LineNumber, Presentation");
		DataString.FieldsStructure = PreviousContactInformationXMLStructure(
		Selection.FieldsValues, ContactInformationKind);
	EndDo;
	
	Return  Result;
EndFunction

// Obsolete. Use ContactsManager.SetObjectsContactInformation instead.
// Fills in contact information for the objects.
//
// Parameters:
//  FillingData - ValueTable - describes objects to be filled in. Contains the following columns:
//     * Destination    - Arbitrary - a reference or an object whose contact information must be filled in.
//     * CIKind       - CatalogRef.ContactInformationKinds - a contact information kind filled in the destination.
//     * CIStructure - ValueList, String, Structure - data of contact information field values.
//     * RowKey - Structure - a filter for searching a row in a tabular section, where Key is a name 
//                                 of the column in the tabular section and Value is a filter value.
//  Date       - Date - an optional parameter, the date, from which contact information record is 
//                              valid. It is used for storing the history of contact information changes.
//                              If not specified, the current date will be set.
//
Procedure FillObjectsContactInformation(FillingData, Date = Undefined) Export
	
	PreviousDestination = Undefined;
	FillingData.Sort("Destination, CIKind");
	
	For Each FillString In FillingData Do
		
		Destination = FillString.Destination;
		If Common.IsReference(TypeOf(Destination)) Then
			Destination = Destination.GetObject();
		EndIf;
		
		If PreviousDestination <> Undefined AND PreviousDestination <> Destination Then
			If PreviousDestination.Ref = Destination.Ref Then
				Destination = PreviousDestination;
			Else
				PreviousDestination.Write();
			EndIf;
		EndIf;
		
		CIKind = FillString.CIKind;
		DestinationObjectName = Destination.Metadata().Name;
		TabularSectionName = TabularSectionNameByCIKind(CIKind, DestinationObjectName);
		
		If IsBlankString(TabularSectionName) Then
			FillTabularSectionContactInformation(Destination, CIKind, FillString.CIStructure,, Date);
		Else
			If TypeOf(FillString.RowKey) <> Type("Structure") Then
				Continue;
			EndIf;
			
			If FillString.RowKey.Property("LineNumber") Then
				TabularSectionRowsCount = Destination[TabularSectionName].Count();
				RowNumber = FillString.RowKey.LineNumber;
				If RowNumber > 0 AND RowNumber <= TabularSectionRowsCount Then
					TabularSectionRow = Destination[TabularSectionName][RowNumber - 1];
					FillTabularSectionContactInformation(Destination, CIKind, FillString.CIStructure, TabularSectionRow, Date);
				EndIf;
			Else
				TabularSectionRows = Destination[TabularSectionName].FindRows(FillString.RowKey);
				For each TabularSectionRow In TabularSectionRows Do
					FillTabularSectionContactInformation(Destination, CIKind, FillString.CIStructure, TabularSectionRow, Date);
				EndDo;
			EndIf;
		EndIf;
		
		PreviousDestination = Destination;
		
	EndDo;
	
	If PreviousDestination <> Undefined Then
		PreviousDestination.Write();
	EndIf;
	
EndProcedure

// Obsolete. Use ContactsManager.SetObjectContactInformation instead.
// Fills in contact information for an object.
//
// Parameters:
//  Destination    - Arbitrary - a reference or an object whose contact information must be filled in.
//  CIKind       - CatalogRef.ContactInformationKinds - a contact information kind filled in the destination.
//  CIStructure - Structure - a filled contact information structure.
//  RowKey - Structure - a filter for searching a row in a tabular section.
//    * Key - String - a column name in the tabular section.
//    * Value - String - a filter value.
//  Date        - Date - an optional parameter, the date, from which contact information record is 
//                       valid. It is used for storing the history of contact information changes.
//                       If not specified, the current date will be set.
//
Procedure FillObjectContactInformation(Destination, CIKind, CIStructure, RowKey = Undefined, Date = Undefined) Export
	
	FillingData = New ValueTable;
	FillingData.Columns.Add("Destination");
	FillingData.Columns.Add("CIKind");
	FillingData.Columns.Add("CIStructure");
	FillingData.Columns.Add("RowKey");
	
	FillString = FillingData.Add();
	FillString.Destination = Destination;
	FillString.CIKind = CIKind;
	FillString.CIStructure = CIStructure;
	FillString.RowKey = RowKey;
	
	FillObjectsContactInformation(FillingData, Date);
	
EndProcedure

// Obsolete. Use AddressManager.CheckAddress instead.
// Checks an address for compliance with address information requirements.
//
// Parameters:
//   AddressInXML                      - String - an XML string of contact information.
//   CheckParameters              - Structure, CatalogRef.ContactInformationKinds - address check flags:
//          OnlyNationalAddress - Boolean - an address is to be only local. Default value is True.
//          AddressFormat - String - the classifier used for validation: "ARCA" or "FIAS". Default value is "ARCA".
// Returns:
//   Structure - contains a structure with the following fields:
//        * Result    - String - a check result: Correct, NotChecked, or ConainsErrors.
//        * ErrorsList - ValueList - information on errors.
Function CheckAddress(Val AddressInXML, CheckParameters = Undefined) Export
	Return ContactsManagerInternal.CheckAddress(AddressInXML, CheckParameters);
EndFunction

// Obsolete. Use ContactInformationParameters instead.
// Details of contact information parameters used in the OnCreateAtServer handler.
// 
// Returns:
//  Structure - contact information parameters.
//   * PostalCode                   - String - an address postal code.
//   * Country                   - String - an address country.
//   * PremiseType             - String - a description of premise type that will be set in the 
//                                         address input form. Apartment by default.
//   * ItemForPlacementName - String - a group, to which the contact information items will be placed.
//   * ExcludedKinds - Array - contact information kinds that do not need to be displayed on the form.
//   * DeferredInitialization  - Boolean - if True, generation of contact information fields on the form will be deferred.
//   * CITitleLocation     -  FormItemTitleLocation - can take the following values:
//                                                             FormItemTitleLocation.Top or
//                                                             FormItemTitleLocation.Left (by default).
//
Function ContactsParameters() Export

	Result = New Structure;
	Result.Insert("PremiseType", "Apartment");
	Result.Insert("IndexOf", Undefined);
	Result.Insert("Country", Undefined);
	Result.Insert("DeferredInitialization", False);
	Result.Insert("CITitleLocation", "");
	Result.Insert("ExcludedKinds", Undefined);
	Result.Insert("ItemForPlacementName", "ContactInformationGroup");
	
	Return Result;

EndFunction 

#EndRegion

#EndRegion

#Region Internal

// Sets the availability of contact information items on the form.
//
// Parameters:
//    Form - ManagedForm - a form to pass.
//    Items - Map -  a list of contact information kinds for which access is set.
//        ** Key     - MetadataObject - a subsystem where a report or a report option is placed.
//        ** Value - Boolean           - if False, an item can only be viewed.
//
Procedure SetContactInformationItemAvailability(Form, Items, ItemForPlacementName = "ContactInformationGroup") Export
	For each Item In Items Do
		
		Filter = New Structure("Kind", Item.Key);
		FoundRows = Form.ContactInformationAdditionalAttributesDetails.FindRows(Filter);
		If FoundRows <> Undefined Then
			For Each FoundRow In FoundRows Do
				CIItem = Form.Items[FoundRow.AttributeName];
				CIItem.ReadOnly = NOT Item.Value;
			EndDo;
			// If an item can only be viewed, remove the option to add this item to the form.
			ContactInformationParameters = FormContactInformationParameters(Form.ContactInformationParameters, ItemForPlacementName);
			If NOT Item.Value Then
				For each ContextMenuItem In ContactInformationParameters.ItemsToAddList Do
					If ContextMenuItem.Value.Ref = Item.Key Then
						ContactInformationParameters.ItemsToAddList.Delete(ContextMenuItem);
						Continue;
					EndIf;
				EndDo;
			EndIf;
		EndIf;
		
	EndDo;
	
	If Form.Items.Find("ContactInformationAddInputField") <> Undefined Then
		ContactInformationParameters = FormContactInformationParameters(Form.ContactInformationParameters, ItemForPlacementName);
		If ContactInformationParameters.ItemsToAddList.Count() = 0 Then
			// Disabling the Add button as the context menu is empty.
			Form.Items.ContactInformationAddInputField.Enabled = False;
		EndIf;
	EndIf;
	
EndProcedure

// Adds contact information columns to the list of columns for data import.
//
// Parameters:
//  CatalogMetadata	 - MetadataObject - catalog metadata.
//  ColumnsInformation	 - ValueTable - template columns.
//
Procedure ColumnsForDataImport(CatalogMetadata, ColumnsInformation) Export
	
	If CatalogMetadata.TabularSections.Find("ContactInformation") = Undefined Then
		Return;
	EndIf;
	
	Position = ColumnsInformation.Count() + 1;
	
	ContactInformationKinds = ObjectContactInformationKinds(Catalogs[CatalogMetadata.Name].EmptyRef());
	
	For each ContactInformationKind In ContactInformationKinds Do
		ColumnName = "ContactInformation_" + StandardSubsystemsServer.TransformStringToValidColumnDescription(ContactInformationKind.Description);
		If ColumnsInformation.Find(ColumnName, "ColumnName") = Undefined Then
			ColumnsInfoRow = ColumnsInformation.Add();
			ColumnsInfoRow.ColumnName = ColumnName;
			ColumnsInfoRow.ColumnPresentation = ContactInformationKind.Presentation;
			ColumnsInfoRow.ColumnType = New TypeDescription("String");
			ColumnsInfoRow.Required = False;
			ColumnsInfoRow.Position = Position;
			ColumnsInfoRow.Group = NStr("ru = 'Контактная информация'; en = 'Contact information'; pl = 'Informacje kontaktowe';de = 'Kontakt Informationen';ro = 'Informații de contact';tr = 'İletişim bilgileri'; es_ES = 'Información de contacto'");
			ColumnsInfoRow.Visible = True;
			ColumnsInfoRow.Width = 30;
			Position = Position + 1;
		EndIf;
	EndDo;
	
EndProcedure

// Contact information kinds of an object.
//
// Parameters:
//  ContactInformationOwner - a reference to a contact information owner.
//                                 Object of a contact information owner.
//                                 FormStructureData (by type of property owner object).
// Returns:
//  ValueTable -  contact information kinds.
//
Function ObjectContactInformationKinds(ContactInformationOwner) Export
	
	If TypeOf(ContactInformationOwner) = Type("FormDataStructure") Then
		RefType = TypeOf(ContactInformationOwner.Ref)
		
	ElsIf Common.IsReference(TypeOf(ContactInformationOwner)) Then
		RefType = TypeOf(ContactInformationOwner);
	Else
		RefType = TypeOf(ContactInformationOwner.Ref)
	EndIf;
	
	CatalogMetadata = Metadata.FindByType(RefType);
	FullMetadataObjectName = CatalogMetadata.FullName();
	CIKindsGroupName = StrReplace(FullMetadataObjectName, ".", "");
	CIKindsGroup = Undefined;
	
	Query = New Query;
	Query.Text = "SELECT
	|	ContactInformationKinds.Ref AS Ref,
	|CASE
	|	WHEN ContactInformationKinds.PredefinedKindName <> """"
	|	THEN ContactInformationKinds.PredefinedKindName
	|	ELSE ContactInformationKinds.PredefinedDataName
	|END AS PredefinedKindName
	|FROM
	|	Catalog.ContactInformationKinds AS ContactInformationKinds
	|WHERE
	|	ContactInformationKinds.IsFolder = TRUE
	|	AND ContactInformationKinds.DeletionMark = FALSE
	|	AND ContactInformationKinds.Used = TRUE";
	
	QueryResult = Query.Execute().Select();
	While QueryResult.Next() Do 
		If StrCompare(QueryResult.PredefinedKindName, CIKindsGroupName) = 0 Then
			CIKindsGroup = QueryResult.Ref;
			Break;
		EndIf;
	EndDo;
	
	If NOT ValueIsFilled(CIKindsGroup) Then
		Return New ValueTable;
	EndIf;
	
	Query = New Query;
	Query.Text = 
	"SELECT
	|	ContactInformationKinds.Ref,
	|	ContactInformationKinds.Presentation,
	|	ContactInformationKinds.Description,
	|	ContactInformationKinds.AllowMultipleValueInput,
	|	ContactInformationKinds.AddlOrderingAttribute AS AddlOrderingAttribute,
	|	ContactInformationKinds.Type
	|FROM
	|	Catalog.ContactInformationKinds AS ContactInformationKinds
	|WHERE
	|	ContactInformationKinds.Parent = &CIKindsGroup
	|	AND ContactInformationKinds.DeletionMark = FALSE
	|	AND ContactInformationKinds.Used = TRUE
	|
	|ORDER BY
	|	AddlOrderingAttribute";
	
	Query.SetParameter("CIKindsGroup", CIKindsGroup);
	QueryResult = Query.Execute().Unload();
	Return QueryResult;
	
EndFunction

// Returns a contact information type.
//
// Parameters:
//    Description - String - a contact information type as a string.
//
// Returns:
//    EnumRef.ContactInformationTypes - matching type.
//
Function ContactInformationTypeByDescription(Val Description) Export
	Return Enums.ContactInformationTypes[Description];
EndFunction

#EndRegion

#Region Private

////////////////////////////////////////////////////////////////////////////////
// Initialization of items on the form of a contact information owner object.

Procedure DefineContactInformationParametersByOwner(Form, Object, ContactInformationParameters, IsMainObjectParameters, HiddenKinds)
	
	HiddenKinds = New Array;
	For each ContactInformationParameter In Form.ContactInformationParameters Do
		
		If ContactInformationParameter.Value.Owner = Object.Ref
			Or Form.ContactInformationParameters.Count() = 1 Then
				
				ContactInformationParameters = ContactInformationParameter.Value;
				HiddenKinds = ContactInformationParameters.HiddenKinds;
				Return;
		EndIf;
		
		IsMainObjectParameters = False;
		
	EndDo;

EndProcedure

Procedure GenerateContactInformationAttributes(Val Form, Val AttributesToAdd, Val ObjectName, Val ExcludedKinds,
	Val ContactInformation, Val DeferredInitialization, Val URLProcessing)
	
	String1500           = New TypeDescription("String", , New StringQualifiers(1500));
	FormattedString = New TypeDescription("FormattedString");
	
	GeneratedAttributes = Common.CopyRecursive(ExcludedKinds);
	PreviousKind      = Undefined;
	SequenceNumber    = 1;
	
	For Each ContactInformationObject In ContactInformation Do
		
		If ContactInformationObject.IsTabularSectionAttribute Then
			
			CIKindName = ContactInformationObject.PredefinedKindName;
			Position = StrFind(CIKindName, ObjectName);
			TabularSectionName = Mid(CIKindName, Position + StrLen(ObjectName));
			
			PreviousKind = Undefined;
			AttributeName = "";
			
			ContactInformationObject.Rows.Sort("AddlOrderingAttribute");
			
			For Each CIRow In ContactInformationObject.Rows Do
				
				CurrentKind = CIRow.Kind;
				If CurrentKind <> PreviousKind Then
					
					AttributeName = "ContactInformationField" + TabularSectionName + StrReplace(CurrentKind.UUID(), "-", "x")
						+ ContactInformationObject.Rows.IndexOf(CIRow);
					AttributesPath = "Object." + TabularSectionName;
					
					AttributesToAdd.Add(New FormAttribute(AttributeName, String1500, AttributesPath, CIRow.Description, True));
					AttributesToAdd.Add(New FormAttribute(AttributeName + "Value", New TypeDescription("String"), AttributesPath,, True));
					PreviousKind = CurrentKind;
					
				EndIf;
				
				CIRow.AttributeName = AttributeName;
				
			EndDo;
			
		Else
			
			If ContactInformationObject.IsHistoricalContactInformation Then
				AdjustContactInformation(Form, ContactInformationObject);
				Continue;
			EndIf;
			
			CurrentKind = ContactInformationObject.Kind;
			
			If CurrentKind <> PreviousKind Then
				PreviousKind = CurrentKind;
				SequenceNumber = 1;
			Else
				SequenceNumber = SequenceNumber + 1;
			EndIf;
			
			Index = GeneratedAttributes.Find(CurrentKind);
			If Index = Undefined Then
				ContactInformationObject.AttributeName = "ContactInformationField" + StrReplace(CurrentKind.UUID(), "-", "x")
					+ SequenceNumber;
				If Not DeferredInitialization Then
					
					AttributeType = String1500;
					If ContactInformationObject.Type = Enums.ContactInformationTypes.WebPage AND URLProcessing Then
						AttributeType = FormattedString;
					EndIf;
					
					AttributesToAdd.Add(
						New FormAttribute(ContactInformationObject.AttributeName, AttributeType,, ContactInformationObject.Description, True));
				EndIf;
			Else
				ContactInformationObject.AttributeName = "ContactInformationField" + ContactInformationObject.PredefinedKindName;
				GeneratedAttributes.Delete(Index);
			EndIf;
			
			AdjustContactInformation(Form, ContactInformationObject);
		EndIf;
	EndDo;
	
	// Adding new attributes
	If AttributesToAdd.Count() > 0 Then
		Form.ChangeAttributes(AttributesToAdd);
	EndIf;

EndProcedure

Procedure HideContactInformation(Val Form, Val AttributesToAdd, OutputParameters)
	
	If AttributesToAdd.Count() > 0 Then
		Form.ChangeAttributes(AttributesToAdd);
	EndIf;
	AddedAttributes = New Array;
	For Each AttributeToAdd In AttributesToAdd Do
		If IsBlankString(AttributeToAdd.Path) Then
			AddedAttributes.Add(AttributeToAdd.Name);
		EndIf;
	EndDo;
	
	ContactInformationParameters = ContactInformationOutputParameters(Form, OutputParameters.ItemForPlacementName,
		OutputParameters.CITitleLocation, OutputParameters.DeferredInitialization,
		OutputParameters.ExcludedKinds, OutputParameters.HiddenKinds);
		
	ContactInformationParameters.AddedAttributes = AddedAttributes;
	ContactInformationParameters.Owner             = OutputParameters.ObjectRef;
	
	If Not IsBlankString(OutputParameters.ItemForPlacementName) Then
		Form.Items[OutputParameters.ItemForPlacementName].Visible = False;
	EndIf;
	
EndProcedure

Procedure AddAdditionalContactInformationFieldButton(Val Form, Val ItemForPlacementName)
	
	Details = NStr("ru = 'Добавить дополнительное поле контактной информации'; en = 'Add an additional contact information field'; pl = 'Dodaj dodatkowe pole informacji kontaktowych';de = 'Fügen Sie ein zusätzliches Kontaktinformationsfeld hinzu';ro = 'Adăugați un câmp de informații suplimentare de contact';tr = 'Ek iletişim bilgileri alanı ekle'; es_ES = 'Añadir el campo de la información de contacto adicional'");
	CommandsGroup             = Folder("ContactInformationGroupAddInputField" + ItemForPlacementName, Form, Details, ItemForPlacementName);
	CommandsGroup.Representation = UsualGroupRepresentation.NormalSeparation;
	
	CommandName          = "ContactInformationAddInputField" + ItemForPlacementName;
	Command             = Form.Commands.Add(CommandName);
	Command.ToolTip   = Details;
	Command.Representation = ButtonRepresentation.PictureAndText;
	Command.Picture    = PictureLib.AddListItem;
	Command.Action    = "Attachable_ContactInformationExecuteCommand";
	
	Form.ContactInformationParameters[ItemForPlacementName].AddedItems.Add(CommandName, 9, True);
	
	Button             = Form.Items.Add(CommandName,Type("FormButton"), CommandsGroup);
	Button.Enabled = NOT Form.Items[ItemForPlacementName].ReadOnly;
	Button.Title   = NStr("ru = 'Добавить'; en = 'Add'; pl = '+ telefon, adres';de = '+ Telefon, Adresse';ro = '+ telefon, adresa';tr = '+ telefon, adres'; es_ES = '+ teléfono, dirección'");
	Command.ModifiesStoredData = True;
	Button.CommandName                 = CommandName;
	Form.ContactInformationParameters[ItemForPlacementName].AddedItems.Add(CommandName, 2, False);

EndProcedure

Procedure AddNoteOnFormSettingsReset(Val Form, Val ItemForPlacementName, Val DeferredInitialization)
	
	GroupForPlacement = Form.Items[ItemForPlacementName];
	// If there is deferred initialization and no items on the page, the platform hides the page, so you 
	// need to create a temporary item that will be deleted when you go to the page.
	If DeferredInitialization
		AND GroupForPlacement.Type = FormGroupType.Page 
		AND Form.Items.Find("ContactInformationStub") = Undefined Then
		
		PagesGroup = GroupForPlacement.Parent;
		PageHeader = ?(ValueIsFilled(GroupForPlacement.Title), GroupForPlacement.Title, GroupForPlacement.Name);
		PageGroupHeader = ?(ValueIsFilled(PagesGroup.Title), PagesGroup.Title, PagesGroup.Name);
		
		PlacementWarning = NStr("ru = 'Для отображения контактной информации необходимо разместить группу ""%1"" не первым элементом (после любой другой группы) в группе ""%2"" (меню Еще - Изменить форму).'; en = 'To show the contact information, move the ""%1"" group under any other item (not the first item) in the ""%2"" group (More—Change form).'; pl = 'Aby wyświetlić informację kontaktową należy umieścić grupę ""%1"" nie pierwszym elementem (po każdej innej grupie) w grupie ""%2"" (menu Więcej -Zmienić formularz).';de = 'Um Kontaktinformationen anzuzeigen, sollten Sie die Gruppe ""%1"" nicht als erstes Element (nach einer anderen Gruppe) in der Gruppe ""%2"" (Menü Mehr- Formular ändern) platzieren.';ro = 'Pentru afișarea informațiilor de contact trebuie să amplasați grupul ""%1"" nu ca primul element (după orice alt grup) în grupul ""%2"" (meniul Mai multe - Modifică forma).';tr = 'İletişim bilgileri görüntülemek için, ""%1""grubu ""%2"" grubunda (başka bir gruptan sonra) ilk öğe şeklinde yerleştirmemeniz gerekir (menü Daha fazla-Formu değiştirin).'; es_ES = 'Para visualizar la información de contacto es necesario colocar en el grupo ""%1"" no como el primer elemento (después del cualquier otro grupo) en el grupo ""%2"" (menú Más - Cambiar el formulario).'");
		PlacementWarning = StringFunctionsClientServer.SubstituteParametersToString(PlacementWarning,
		PageHeader, PageGroupHeader);
		TooltipText = NStr("ru = 'Также можно установить стандартные настройки формы:
		|   • в меню Еще выбрать пункт Изменить форму...;
		|   • в открывшейся форме ""Настройка формы"" в меню Еще выбрать пункт ""Установить стандартные настройки"".'; 
		|en = 'To restore a form to default settings, do the following:
		| • Select More actions menu, than select Change form.
		| • In the Customize form window that opens, select More actions, than select Use standard settings.'; 
		|pl = 'Można również ustawić domyślne ustawienia formularzu:
		|   • w menu Więcej wybrać punkt Zmienić formularz...;
		| • w otwartym formularzu ""Ustawienia formularza"" w menu Więcej wybrać opcję ""Ustaw domyślne ustawienia"".';
		|de = 'Sie können auch die Standardeinstellungen für das Formular festlegen:
		|  - im Menü Mehr, den Punkt ""Formular ändern"" wählen.... ;
		|  - im geöffneten Formular ""Formulareinstellung"" im Menü Mehr, den Punkt ""Standardeinstellungen einstellen"" wählen.';
		|ro = 'De asemenea puteți stabili setările standard ale formei:
		|   • în meniul Mai multe selectați punctul Modifică forma...;
		|   • în forma deschisă ""Setarea formei"" în meniul Mai multe selectați punctul ""Stabilire setările standard"".';
		|tr = 'Ayrıca standart biçim ayarları belirlenebilir:
		|   • Daha fazla menüsünde Biçim değiştir alt menüyü seçin...;
		|   • açılan formda ""Biçim ayarları"" ""Daha fazla menüsünde ""Standart ayarları belirle"" alt menüyü seçin.'; 
		|es_ES = 'Además se puede instalar los ajustes estándares del formulario:
		|   • en el menú Más hay que seleccionar el punto Cambiar el formulario...;
		|   • en el formulario que se abrirá ""Ajustes del formulario"" en el menú Más hay que seleccionar el punto ""Establecer los ajustes estándares"".'");
		
		Decoration = Form.Items.Add("ContactInformationStub", Type("FormDecoration"), GroupForPlacement);
		Decoration.Title              = PlacementWarning;
		Decoration.ToolTipRepresentation   = ToolTipRepresentation.Button;
		Decoration.ToolTip              = TooltipText;
		Decoration.TextColor             = StyleColors.ErrorNoteText;
		Decoration.AutoMaxHeight = False;
	EndIf;

EndProcedure

Function TitleLeft(Val CITitleLocation = Undefined)
	
	If ValueIsFilled(CITitleLocation) Then
		CITitleLocation = PredefinedValue(CITitleLocation);
	Else
		CITitleLocation = FormItemTitleLocation.Left;
	EndIf;
	
	Return (CITitleLocation = FormItemTitleLocation.Left);
	
EndFunction

Procedure ModifyComment(Form, AttributeName, ItemForPlacementName)
	
	ContactInformationParameters = FormContactInformationParameters(Form.ContactInformationParameters, ItemForPlacementName);
	If ContactInformationParameters.AddedItems.FindByValue(AttributeName) = Undefined Then
		Return;
	EndIf;
	
	ContactInformationDetails = Form.ContactInformationAdditionalAttributesDetails;
	
	Filter = New Structure("AttributeName", AttributeName);
	FoundRow = ContactInformationDetails.FindRows(Filter)[0];
	
	If ContactsManagerClientServer.IsJSONContactInformation(FoundRow.Value) Then
		ContactInformationByFields = ContactsManagerInternal.JSONStringToStructure(FoundRow.Value);
		ContactInformationByFields.Comment = FoundRow.Comment;
		FoundRow.Value = ContactsManagerInternal.ToJSONStringStructure(ContactInformationByFields);
	EndIf;
	
	InputField = Form.Items.Find(AttributeName);
	InputField.ExtendedToolTip.Title = FoundRow.Comment;
	
EndProcedure

Procedure AddContactInformationRow(Form, Result, ItemForPlacementName, IsNewCIKind = False, AddressesCount = Undefined, NextRow = Undefined)
	
	AddNewValue = TypeOf(Result) = Type("Structure");
	
	If AddNewValue Then
		Result.Property("ItemForPlacementName", ItemForPlacementName);
		
		KindToAdd = Result.KindToAdd;
		If TypeOf(KindToAdd)= Type("CatalogRef.ContactInformationKinds") Then
			CIKindInformation = Common.ObjectAttributesValues(KindToAdd, "Type, Description, EditInDialogOnly, FieldKindOther");
		Else
			CIKindInformation = KindToAdd;
			KindToAdd    = KindToAdd.Ref;
		EndIf;
	Else
		CIKindInformation = Result;
		KindToAdd    = Result.Kind;
	EndIf;
	
	ContactInformationTable = Form.ContactInformationAdditionalAttributesDetails;
	FilterByKind = New Structure("Kind, IsHistoricalContactInformation", KindToAdd, False);
	
	If AddNewValue Then
		
		FoundRows = ContactInformationTable.FindRows(FilterByKind);
		
		KindRowsCount = FoundRows.Count();
		If KindRowsCount > 0 Then
			LastRow = FoundRows.Get(KindRowsCount - 1);
			RowToAddIndex = ContactInformationTable.IndexOf(LastRow) + 1;
		Else
			RowToAddIndex = 0;
		EndIf;
		
		IsLastRow = False;
		If RowToAddIndex = ContactInformationTable.Count() Then
			IsLastRow = True;
		EndIf;
		
		NewRow  = ContactInformationTable.Insert(RowToAddIndex);
		AttributeName = StringFunctionsClientServer.SubstituteParametersToString("%1%2%3",
			"ContactInformationField",
			StrReplace(KindToAdd.UUID(), "-", "x"),
			KindRowsCount + 1);
		NewRow.AttributeName              = AttributeName;
		NewRow.Kind                       = KindToAdd;
		NewRow.Type                       = CIKindInformation.Type;
		NewRow.ItemForPlacementName  = ItemForPlacementName;
		NewRow.IsTabularSectionAttribute = False;
		
		ContactInformationParameters = FormContactInformationParameters(Form.ContactInformationParameters, ItemForPlacementName);
		URLProcessing = ContactInformationParameters.URLProcessing;
		
		If URLProcessing = True Then
			AttributeTypeDetails = New TypeDescription("FormattedString");
		Else
			AttributeTypeDetails = New TypeDescription("String", , New StringQualifiers(500));
		EndIf;
		
		AttributesToAddArray = New Array;
		AttributesToAddArray.Add(New FormAttribute(AttributeName, AttributeTypeDetails,, CIKindInformation.Description, True));
		Form.ChangeAttributes(AttributesToAddArray);
		
		HasComment = False;
		Mandatory = False;
	Else
		IsLastRow = NextRow = Undefined;
		AttributeName = CIKindInformation.AttributeName;
		HasComment = ValueIsFilled(CIKindInformation.Comment);
		Mandatory = CIKindInformation.Mandatory;
	EndIf;
	
	// Displaying form items
	StringGroup = Folder("Group" + AttributeName, Form, KindToAdd.Description, ItemForPlacementName);
	
	If Common.IsMobileClient() Then
		StringGroup.ShowTitle = True;
	EndIf;
	
	Parent = Parent(Form, ItemForPlacementName);
	If Not IsLastRow Then
		If NextRow = Undefined Then
			NextGroupName = "Group" + LastRow.AttributeName;
			If Form.Items.Find(NextGroupName) <> Undefined Then
				NextGroupIndex = Parent.ChildItems.IndexOf(Form.Items[NextGroupName]) + 1;
				NextGroup = Parent.ChildItems.Get(NextGroupIndex);
			EndIf;
		Else
			NameOfGroup = "Group" + NextRow.AttributeName;
			If Form.Items.Find(NameOfGroup) <> Undefined Then
				NextGroup = Form.Items[NameOfGroup];
			EndIf;
		EndIf;
		Form.Items.Move(StringGroup, Parent, NextGroup);
	ElsIf AddNewValue Then
		NextGroup = Form.Items[Result.CommandName].Parent;
		Form.Items.Move(StringGroup, Parent, NextGroup);
	EndIf;
	
	// Handling situations when multiple dynamic and static contact information is displayed on the form at the same time.
	NameOfNextGroupOfCurrentKind = "Group" + AttributeName;
	If Form.Items.Find(NameOfNextGroupOfCurrentKind) <> Undefined Then
		
		Filter = New Structure("AttributeName", AttributeName);
		FoundRowsOfCurrentKind = ContactInformationTable.FindRows(Filter);
		If FoundRowsOfCurrentKind.Count() > 0 Then
			CurrentKind = FoundRowsOfCurrentKind[0].Kind;
		EndIf;
		
		IndexOfPreviousKindGroup = Parent.ChildItems.IndexOf(Form.Items[NameOfNextGroupOfCurrentKind]) - 1;
		If IndexOfPreviousKindGroup >= 0 Then
			PreviousKindGroup = Parent.ChildItems.Get(IndexOfPreviousKindGroup);
			
			If PreviousKindGroup <> Undefined Then
			
			Filter = New Structure("AttributeName", StrReplace(PreviousKindGroup.Name, "Group", ""));
			FoundRowsOfPreviousKind = ContactInformationTable.FindRows(Filter);
			If FoundRowsOfPreviousKind.Count() > 0 Then
				PreviousKind = FoundRowsOfPreviousKind[0].Kind;
			EndIf;
			
			If CurrentKind <> PreviousKind Then
				IsNewCIKind = True;
			EndIf;
			EndIf;
		Else
			IsNewCIKind = True;
		EndIf;
	EndIf;
	
	InputField = GenerateInputField(Form, StringGroup, CIKindInformation, AttributeName, ItemForPlacementName, IsNewCIKind, Mandatory);
	
	If Common.IsMobileClient() Then
		InputField.TitleLocation = FormItemTitleLocation.None;
	EndIf;
	
	If HasComment Then
		InputField.ExtendedTooltip.Title              = CIKindInformation.Comment;
		InputField.ExtendedTooltip.AutoMaxWidth = False;
		InputField.ExtendedTooltip.MaxWidth     = InputField.Width;
		InputField.ExtendedTooltip.Width                 = InputField.Width;
	EndIf;
	
	If AddressesCount = Undefined Then
		FIlterByType = New Structure("Type", Enums.ContactInformationTypes.Address);
		AddressesCount = ContactInformationTable.FindRows(FIlterByType).Count();
	EndIf;
	
	CreateAction(Form, CIKindInformation, AttributeName, StringGroup, AddressesCount, HasComment, ItemForPlacementName);
	
	If Not IsNewCIKind Then
		If ContactInformationTable.Count() > 1 AND ContactInformationTable[0].Property("IsHistoricalContactInformation") Then
			MoveContextMenuItem(InputField, Form, 1, ItemForPlacementName);
			FoundRows = ContactInformationTable.FindRows(FilterByKind);
			If FoundRows.Count() > 1 Then
				PreviousString = FoundRows.Get(FoundRows.Count() - 2);
				MoveContextMenuItem(Form.Items[PreviousString.AttributeName], Form, - 1, ItemForPlacementName);
			EndIf;
		EndIf;
	EndIf;
	
	If AddNewValue Then
		Form.CurrentItem = Form.Items[AttributeName];
		If CIKindInformation.Type = Enums.ContactInformationTypes.Address
			AND CIKindInformation.EditInDialogOnly Then
			Result.Insert("AddressFormItem", AttributeName);
		EndIf;
	EndIf;
	
EndProcedure

Function GenerateInputField(Form, Parent, CIKindInformation, AttributeName, ItemForPlacementName,IsNewCIKind = False, Mandatory = False)
	
	ContactInformationParameters = FormContactInformationParameters(Form.ContactInformationParameters, ItemForPlacementName);
	URLProcessing = ContactInformationParameters.URLProcessing;
	
	TitleLeft = TitleLeft(ContactInformationParameters.TitleLocation);
	Item = Form.Items.Add(AttributeName, Type("FormField"), Parent);
	Item.DataPath = AttributeName;
	
	If CIKindInformation.EditInDialogOnly AND CIKindInformation.Type = Enums.ContactInformationTypes.Address Then
		Item.Type = FormFieldType.LabelField;
		Item.Hyperlink = True;
		Item.SetAction("Click", "Attachable_ContactInformationOnClick");
		If IsBlankString(Form[AttributeName]) Then
			Form[AttributeName] = ContactsManagerClientServer.BlankAddressTextAsHyperlink();
		EndIf;
		
	ElsIf CIKindInformation.Type = Enums.ContactInformationTypes.WebPage AND URLProcessing Then
		
		Item.Type = FormFieldType.LabelField;
		Item.SetAction("URLProcessing", "Attachable_ContactInformationURLProcessing");
		
		If TypeOf(CIKindInformation) <> Type("Structure") AND ContactsManagerClientServer.IsJSONContactInformation(CIKindInformation.Value) Then
			ContactInformation = ContactsManagerInternal.JSONToContactInformationByFields(CIKindInformation.Value, Enums.ContactInformationTypes.WebPage);
			WebsiteAddress    = ContactInformation.value;
			Presentation = ?(ContactInformation.Property("name") AND ValueIsFilled(ContactInformation.name), ContactInformation.name, CIKindInformation.Presentation);
		Else
			WebsiteAddress = "";
			Presentation = ContactsManagerClientServer.BlankAddressTextAsHyperlink();
		EndIf;
		
		Form[AttributeName] = ContactsManagerClientServer.WebsiteAddress(Presentation, WebsiteAddress);
		
	Else
		
		Item.Type = FormFieldType.InputField;
		Item.SetAction("Clearing",         "Attachable_ContactInformationClearing");
		
		If CIKindInformation.Type = Enums.ContactInformationTypes.Address Then
			Item.SetAction("AutoComplete",      "Attachable_ContactInformationAutoComplete");
			Item.SetAction("ChoiceProcessing", "Attachable_ContactInformationChoiceProcessing");
			
		EndIf;
		If Common.IsMobileClient() Then
			Item.MultiLine = True;
		EndIf;
		
	EndIf;
	
	Item.ToolTipRepresentation = ToolTipRepresentation.ShowBottom;
	Item.HorizontalStretch = False;
	Item.VerticalStretch = False;
	
	Item.TitleHeight = ?(Common.IsMobileClient(), 1, 2);
	
	If CIKindInformation.Type = Enums.ContactInformationTypes.Address Then
		Item.Width = 70;
	ElsIf CIKindInformation.Type = Enums.ContactInformationTypes.Other Then
		If CIKindInformation.FieldKindOther = "MultilineWide" Then
			Item.Height = 3;
			Item.Width = 70;
			Item.MultiLine = True;
		ElsIf CIKindInformation.FieldKindOther = "SingleLineWide" Then
			Item.Height = 1;
			Item.Width = 70;
			Item.MultiLine = False;
		Else // SingleLineNarrow
			Item.Height = 1;
			Item.Width = 35;
			Item.MultiLine = False;
		EndIf;
	Else
		Item.Width = 35;
	EndIf;
	
	If Not IsNewCIKind Then
		Item.HorizontalAlignInGroup = ItemHorizontalLocation.Right;
		Item.TitleTextColor = StyleColors.FormBackColor;
	EndIf;
	
	Item.TitleLocation = ?(TitleLeft, FormItemTitleLocation.Left, FormItemTitleLocation.Top);
	If TitleLeft Then
		Item.TitleLocation = FormItemTitleLocation.Left;
	Else
		Item.TitleLocation = FormItemTitleLocation.Top;
	EndIf;
	
	ContactInformationParameters.AddedItems.Add(AttributeName, 2, False);
	
	// Setting input field properties.
	If CIKindInformation.Type <> Enums.ContactInformationTypes.Other AND Not CIKindInformation.DeletionMark Then
		// Entering comment via context menu.
		CommandName = "ContextMenu" + AttributeName;
		Button = Form.Items.Add(CommandName,Type("FormButton"), Item.ContextMenu);
		Button.Title = NStr("ru = 'Ввести комментарий'; en = 'Enter comment'; pl = 'Wpisz komentarz';de = 'Geben Sie einen Kommentar ein';ro = 'Introduce comentariu';tr = 'Yorumu girin'; es_ES = 'Introducir un comentario'");
		Command = Form.Commands.Add(CommandName);
		Command.ToolTip = NStr("ru = 'Ввести комментарий'; en = 'Enter comment'; pl = 'Wpisz komentarz';de = 'Geben Sie einen Kommentar ein';ro = 'Introduce comentariu';tr = 'Yorumu girin'; es_ES = 'Introducir un comentario'");
		Command.Picture = PictureLib.Comment;
		Command.Action = "Attachable_ContactInformationExecuteCommand";
		Command.ModifiesStoredData = True;
		Button.CommandName = CommandName;
		
		ContactInformationParameters.AddedItems.Add(CommandName, 1);
		ContactInformationParameters.AddedItems.Add(CommandName, 9, True);
	EndIf;
	
	If CIKindInformation.StoreChangeHistory AND Not CIKindInformation.DeletionMark Then
		// Contact information history output via context menu.
		CommandName = "ContextMenuHistory" + AttributeName;
		Button = Form.Items.Add(CommandName, Type("FormButton"), Item.ContextMenu);
		Button.Title = NStr("ru = 'История изменений...'; en = 'Change history...'; pl = 'Historia zmian...';de = 'Der Verlauf der Änderung...';ro = 'Istoria modificărilor...';tr = 'Değişim geçmişi...'; es_ES = 'Historia de cambios...'");
		Command = Form.Commands.Add(CommandName);
		Command.Picture = PictureLib.ChangeHistory;
		Command.ToolTip = NStr("ru = 'Показывает историю изменения контактной информации'; en = 'Show contact information change history.'; pl = 'Pokazuje historię zmian informacji kontaktowej';de = 'Zeigt den Verlauf der Änderungen in den Kontaktinformationen an';ro = 'Arată istoria modificărilor informațiilor de contact';tr = 'Iletişim bilgilerin değişim geçmişini gösterir'; es_ES = 'Muestra el historial del cambio de la información de contacto'");
		Command.Action = "Attachable_ContactInformationExecuteCommand";
		Command.ModifiesStoredData = False;
		Button.CommandName = CommandName;
		
		ContactInformationParameters.AddedItems.Add(CommandName, 1);
		ContactInformationParameters.AddedItems.Add(CommandName, 9, True);
	EndIf;
	
	If CIKindInformation.Type = Enums.ContactInformationTypes.Address Then
		MapSeparatorGroup = Form.Items.Add("SubmenuSeparatorContextMaps" + AttributeName, Type("FormGroup"), Item.ContextMenu);
		MapSeparatorGroup.Type = FormGroupType.ButtonGroup;
		
		CommandName = "ContextMenuYandexMap" + AttributeName;
		Button = Form.Items.Add(CommandName,Type("FormButton"), MapSeparatorGroup);
		Button.Title = NStr("ru = 'Адрес на Яндекс.Картах'; en = 'Address on Yandex.Maps'; pl = 'Adres na Yandex Maps';de = 'Adresse auf Yandex. Karten';ro = 'Adresa pe Yandex.maps';tr = 'Yandex.Haritalardaki adres'; es_ES = 'Dirección en Yandex.Maps'");
		Command = Form.Commands.Add(CommandName);
		Command.Picture = PictureLib.YandexMaps;
		Command.ToolTip = NStr("ru = 'Показывает адрес на картах Яндекс.Карты'; en = 'Show address on Yandex.Maps.'; pl = 'Pokazuje adres na mapach Yandex.Mapy';de = 'Zeigt die Adresse auf Yandex.Karten';ro = 'Arată adresa pe hărțile Yandex.maps';tr = 'Yandex.Haritalarda adres görüntüler'; es_ES = 'Mostrar dirección en mapas Yandex.Maps'");
		Command.Action = "Attachable_ContactInformationExecuteCommand";
		Button.CommandName = CommandName;
		
		ContactInformationParameters.AddedItems.Add(CommandName, 1);
		ContactInformationParameters.AddedItems.Add(CommandName, 9, True);
		
		CommandName = "ContextMenuGoogleMap" + AttributeName;
		Button = Form.Items.Add(CommandName,Type("FormButton"), MapSeparatorGroup);
		Button.Title = NStr("ru = 'Адрес на Google Maps'; en = 'Address on Google Maps'; pl = 'Adres w Mapach Google';de = 'Adresse in Google Maps';ro = 'Adresați-vă pe Hărți Google';tr = 'Google Maps'' te adres'; es_ES = 'Dirección en Google Maps'");
		Command = Form.Commands.Add(CommandName);
		Command.Picture = PictureLib.GoogleMaps;
		Command.ToolTip = NStr("ru = 'Показывает адрес на карте Google Maps'; en = 'Show address on Google Maps'; pl = 'Pokaż adres w Mapach Google';de = 'Adresse in Google Maps anzeigen';ro = 'Arată adresa pe Google Maps';tr = 'Google Maps'' ta adresi göster'; es_ES = 'Mostrar la dirección en Google Maps'");
		Command.Action = "Attachable_ContactInformationExecuteCommand";
		Button.CommandName = CommandName;
		
		ContactInformationParameters.AddedItems.Add(CommandName, 1);
		ContactInformationParameters.AddedItems.Add(CommandName, 9, True);
		
		SeparatorButtonsGroup = Form.Items.Add("SubmenuSeparatorMaps" + AttributeName, Type("FormGroup"), Item.ContextMenu);
		SeparatorButtonsGroup.Type = FormGroupType.ButtonGroup;
		
		If Not CIKindInformation.DeletionMark Then
			// Fill in
			GroupAddressSubmenu = Form.Items.Add("ContextSubmenuCopyAddresses" + AttributeName, Type("FormGroup"), SeparatorButtonsGroup);
			GroupAddressSubmenu.Type = FormGroupType.Popup;
			GroupAddressSubmenu.Representation = ButtonRepresentation.Text;
			GroupAddressSubmenu.Title = NStr("ru='Заполнить'; en = 'Fill in'; pl = 'Wypełnij wg';de = 'Ausfüllen';ro = 'Completați';tr = 'Doldur'; es_ES = 'Rellenar'");
		EndIf;
		
	EndIf;
	
	If Mandatory AND IsNewCIKind AND Item.Type = FormFieldType.InputField Then
		Item.AutoMarkIncomplete = True;
	EndIf;
	
	// Editing in dialog
	If CanEditContactInformationTypeInDialog(CIKindInformation.Type) 
		AND Item.Type = FormFieldType.InputField Then
		
		Item.ChoiceButton = Not CIKindInformation.DeletionMark;
		If CIKindInformation.EditInDialogOnly Then
			Item.TextEdit = False;
			Item.BackColor = StyleColors.ContactInformationEditedInDialogColor;
		EndIf;
		Item.SetAction("StartChoice", "Attachable_ContactInformationStartChoice");
		
	EndIf;
	Item.SetAction("OnChange", "Attachable_ContactInformationOnChange");
	
	If CIKindInformation.DeletionMark Then
		
		Item.TitleFont       = New Font(,,,,, True);
		If Not CIKindInformation.EditInDialogOnly Then
			Item.ClearButton        = True;
			Item.TextEdit = False;
		Else
			Item.ReadOnly       = True;
		EndIf;
		
	EndIf;
	
	Return Item;
	
EndFunction

Procedure MoveContextMenuItem(PreviousItem, Form, Direction, ItemForPlacementName)
	
	If Direction > 0 Then
		CommandName = "ContextMenuUp" + PreviousItem.Name;
	Else
		CommandName = "ContextMenuDown" + PreviousItem.Name;
	EndIf;
	
	Command = Form.Commands.Add(CommandName);
	Button = Form.Items.Add(CommandName, Type("FormButton"), PreviousItem.ContextMenu);
	
	Command.Action = "Attachable_ContactInformationExecuteCommand";
	If Direction > 0 Then 
		CommandText = NStr("ru = 'Переместить вверх'; en = 'Move up'; pl = 'Przenieś do góry';de = 'Nach oben gehen';ro = 'Mutați în sus';tr = 'Yukarı taşı'; es_ES = 'Mover hacia arriba'");
		Button.Picture = PictureLib.MoveUp;
	Else
		CommandText = NStr("ru = 'Переместить вниз'; en = 'Move down'; pl = 'Przenieś w dół';de = 'Nach unten gehen';ro = 'Mutați în jos';tr = 'Aşağı taşı'; es_ES = 'Mover hacia abajo'");
		Button.Picture = PictureLib.MoveDown;
	EndIf;
	Button.Title = CommandText;
	Command.ToolTip = CommandText;
	Button.CommandName = CommandName;
	Command.ModifiesStoredData = True;
	Button.Enabled = True;
	ContactInformationParameters = FormContactInformationParameters(Form.ContactInformationParameters, ItemForPlacementName);
	ContactInformationParameters.AddedItems.Add(CommandName, 1);
	ContactInformationParameters.AddedItems.Add(CommandName, 9, True);
	
EndProcedure

// Removes separators from a phone number.
//
// Parameters:
//    PhoneNumber - String - a phone or fax number.
//
// Returns:
//     String - a phone or fax number without separators.
//
Function RemoveSeparatorsFromPhoneNumber(Val PhoneNumber)
	
	Pos = StrFind(PhoneNumber, ",");
	If Pos <> 0 Then
		PhoneNumber = Left(PhoneNumber, Pos-1);
	EndIf;
	
	PhoneNumber = StrReplace(PhoneNumber, "-", "");
	PhoneNumber = StrReplace(PhoneNumber, " ", "");
	PhoneNumber = StrReplace(PhoneNumber, "+", "");
	
	Return PhoneNumber;
	
EndFunction

Function Folder(NameOfGroup, Form, Title, ItemForPlacementName)
	
	Folder = Form.Items.Find(NameOfGroup);
	
	If Folder = Undefined Then
		Parent = Parent(Form, ItemForPlacementName);
		If Common.IsMobileClient() Then
			Parent.TitleFont = New Font(,, True);
		EndIf;
		Folder = Form.Items.Add(NameOfGroup, Type("FormGroup"), Parent);
		Folder.Type = FormGroupType.UsualGroup;
		Folder.Title = Title;
		Folder.ShowTitle = False;
		Folder.EnableContentChange = False;
		Folder.Representation = UsualGroupRepresentation.None;
		Folder.Group = ChildFormItemsGroup.AlwaysHorizontal;
		ContactInformationParameters = FormContactInformationParameters(Form.ContactInformationParameters, ItemForPlacementName);
		ContactInformationParameters.AddedItems.Add(NameOfGroup, 5);
	EndIf;
	
	Return Folder;
	
EndFunction

Procedure CheckContactInformationAttributesAvailability(Form, AttributesToAddArray)
	
	FormAttributeList = Form.GetAttributes();
	
	CreateContactInformationParameters = True;
	CreateContactInformationTable = True;
	For Each Attribute In FormAttributeList Do
		If Attribute.Name = "ContactInformationParameters" Then
			CreateContactInformationParameters = False;
		ElsIf Attribute.Name = "ContactInformationAdditionalAttributesDetails" Then
			CreateContactInformationTable = False;
		EndIf;
	EndDo;
	
	String500 = New TypeDescription("String", , New StringQualifiers(500));
	DetailsName = "ContactInformationAdditionalAttributesDetails";
	
	If CreateContactInformationTable Then
		
		// Creating a value table
		DetailsName = "ContactInformationAdditionalAttributesDetails";
		AttributesToAddArray.Add(New FormAttribute(DetailsName, New TypeDescription("ValueTable")));
		AttributesToAddArray.Add(New FormAttribute("AttributeName", String500, DetailsName));
		AttributesToAddArray.Add(New FormAttribute("Kind", New TypeDescription("CatalogRef.ContactInformationKinds"), DetailsName));
		AttributesToAddArray.Add(New FormAttribute("Type", New TypeDescription("EnumRef.ContactInformationTypes"), DetailsName));
		AttributesToAddArray.Add(New FormAttribute("Value", New TypeDescription("String"), DetailsName));
		AttributesToAddArray.Add(New FormAttribute("Presentation", String500, DetailsName));
		AttributesToAddArray.Add(New FormAttribute("Comment", New TypeDescription("String"), DetailsName));
		AttributesToAddArray.Add(New FormAttribute("IsTabularSectionAttribute", New TypeDescription("Boolean"), DetailsName));
		AttributesToAddArray.Add(New FormAttribute("IsHistoricalContactInformation", New TypeDescription("Boolean"), DetailsName));
		AttributesToAddArray.Add(New FormAttribute("ValidFrom", New TypeDescription("Date"), DetailsName));
		AttributesToAddArray.Add(New FormAttribute("StoreChangeHistory", New TypeDescription("Boolean"), DetailsName));
		AttributesToAddArray.Add(New FormAttribute("ItemForPlacementName", String500, DetailsName));
		AttributesToAddArray.Add(New FormAttribute("InternationalAddressFormat", New TypeDescription("Boolean"), DetailsName));
	Else
		TableAttributes = Form.GetAttributes("ContactInformationAdditionalAttributesDetails");
		AttributesToCreate = New Map;
		AttributesToCreate.Insert("ItemForPlacementName",            True);
		AttributesToCreate.Insert("StoreChangeHistory",             True);
		AttributesToCreate.Insert("ValidFrom",                          True);
		AttributesToCreate.Insert("IsHistoricalContactInformation", True);
		AttributesToCreate.Insert("Value",                            True);
		AttributesToCreate.Insert("InternationalAddressFormat",           True);
		
		For Each Attribute In TableAttributes Do
			If AttributesToCreate[Attribute.Name] <> Undefined Then
				AttributesToCreate[Attribute.Name] = False;
			EndIf;
		EndDo;
		
		If AttributesToCreate["Value"] Then
			AttributesToAddArray.Add(New FormAttribute("Value", New TypeDescription("String"), DetailsName));
		EndIf;
		
		If AttributesToCreate["InternationalAddressFormat"] Then
			AttributesToAddArray.Add(New FormAttribute("InternationalAddressFormat", New TypeDescription("Boolean"), DetailsName));
		EndIf;
		
		If AttributesToCreate["ItemForPlacementName"] Then
			AttributesToAddArray.Add(New FormAttribute("ItemForPlacementName", String500, DetailsName));
		EndIf;
		
		If AttributesToCreate["StoreChangeHistory"] Then
			AttributesToAddArray.Add(New FormAttribute("StoreChangeHistory", New TypeDescription("Boolean"), DetailsName));
		EndIf;
		
		If AttributesToCreate["ValidFrom"] Then
			AttributesToAddArray.Add(New FormAttribute("ValidFrom", New TypeDescription("Date"), DetailsName));
		EndIf;
		
		If AttributesToCreate["IsHistoricalContactInformation"] Then
			AttributesToAddArray.Add(New FormAttribute("IsHistoricalContactInformation", New TypeDescription("Boolean"), DetailsName));
		EndIf;
		
	EndIf;
	
	If CreateContactInformationParameters Then
		AttributesToAddArray.Add(New FormAttribute("ContactInformationParameters", New TypeDescription()));
	EndIf;
	
EndProcedure

Procedure SetValidationAttributesValues(Object, ValidationSettings = Undefined)
	
	Object.CheckValidity = ?(ValidationSettings = Undefined, False, ValidationSettings.CheckValidity);
	
	Object.OnlyNationalAddress = False;
	Object.IncludeCountryInPresentation = False;
	Object.HideObsoleteAddresses = False;
	
EndProcedure

Procedure AddAttributeToDetails(Form, ContactInformationRow, ContactInformationKindsData, IsNewCIKind,
	IsTabularSectionAttribute = False, FillAttributeValue = True, ItemForPlacementName = "ContactInformationGroup")
	
	NewRow = Form.ContactInformationAdditionalAttributesDetails.Add();
	NewRow.AttributeName  = ContactInformationRow.AttributeName;
	NewRow.Kind           = ContactInformationRow.Kind;
	NewRow.Type           = ContactInformationRow.Type;
	NewRow.ItemForPlacementName  = ItemForPlacementName;
	NewRow.IsTabularSectionAttribute = IsTabularSectionAttribute;
	
	If NewRow.Property("IsHistoricalContactInformation") Then
		NewRow.IsHistoricalContactInformation = ContactInformationRow.IsHistoricalContactInformation;
	EndIf;
	
	If NewRow.Property("ValidFrom") Then
		NewRow.ValidFrom = ContactInformationRow.ValidFrom;
	EndIf;
	
	If NewRow.Property("StoreChangeHistory") Then
		NewRow.StoreChangeHistory = ContactInformationRow.StoreChangeHistory;
	EndIf;
	
	If NewRow.Property("InternationalAddressFormat") Then
		NewRow.InternationalAddressFormat = ContactInformationRow.InternationalAddressFormat;
	EndIf;
	
	NewRow.Value      = ContactInformationRow.Value;
	NewRow.Presentation = ContactInformationRow.Presentation;
	NewRow.Comment   = ContactInformationRow.Comment;
	
	If FillAttributeValue AND Not IsTabularSectionAttribute Then
		If ContactInformationRow.Type = Enums.ContactInformationTypes.Address 
			AND ContactInformationRow.EditInDialogOnly
			AND IsBlankString(ContactInformationRow.Presentation) Then
			Form[ContactInformationRow.AttributeName] = ContactsManagerClientServer.BlankAddressTextAsHyperlink();
		Else
			Form[ContactInformationRow.AttributeName] = ContactInformationRow.Presentation;
		EndIf;
		
	EndIf;
	
	ContactInformationKindData = ContactInformationKindsData[ContactInformationRow.Kind];
	ContactInformationKindData.Insert("Ref", ContactInformationRow.Kind);
	
	If IsNewCIKind AND ContactInformationKindData.AllowMultipleValueInput AND Not IsTabularSectionAttribute AND Not ContactInformationKindData.DeletionMark Then
		ContactInformationParameters = FormContactInformationParameters(Form.ContactInformationParameters, ItemForPlacementName);
		ContactInformationParameters.ItemsToAddList.Add(ContactInformationKindData, ContactInformationRow.Kind.Description);
	EndIf;
	
EndProcedure

Procedure DeleteFormItemsAndCommands(Form, ItemForPlacementName)
	
	ContactInformationParameters = FormContactInformationParameters(Form.ContactInformationParameters, ItemForPlacementName);
	AddedItems = ContactInformationParameters.AddedItems;
	AddedItems.SortByPresentation();
	
	For Each ItemToRemove In AddedItems Do
		
		If ItemToRemove.Check Then
			Form.Commands.Delete(Form.Commands[ItemToRemove.Value]);
		Else
			Form.Items.Delete(Form.Items[ItemToRemove.Value]);
		EndIf;
		
	EndDo;
	
EndProcedure

// Returns the flag specifying whether contact information can be edited in a dialog.
//
// Parameters:
//    Type - EnumRef.ContactInformationTypes - a contact information type.
//
// Returns:
//    Boolean - indicates whether dialog edit is available.
//
Function CanEditContactInformationTypeInDialog(Type)
	
	If Type = Enums.ContactInformationTypes.Address Then
		Return True;
	ElsIf Type = Enums.ContactInformationTypes.Phone Then
		Return True;
	ElsIf Type = Enums.ContactInformationTypes.Fax Then
		Return True;
	Else
		Return False;
	EndIf;
	
EndFunction

// Returns a name of the document tabular section by contact information kind.
//
// Parameters:
//    CIKind      - CatalogRef.ContactInformationKinds - a contact information kind.
//    ObjectName - String - a full name of a metadata object.
//
// Returns:
//    String - a tabular section name or a blank string if a tabular section is not available.
//
Function TabularSectionNameByCIKind(CIKind, ObjectName)
	
	Query = New Query;
	Query.Text = "SELECT
	|CASE
	|	WHEN ContactInformationKinds.Parent.PredefinedKindName <> """"
	|	THEN ContactInformationKinds.Parent.PredefinedKindName
	|	ELSE ContactInformationKinds.Parent.PredefinedDataName
	|END AS ContactInformationKindName
	|FROM
	|	Catalog.ContactInformationKinds AS ContactInformationKinds
	|WHERE
	|	ContactInformationKinds.Ref = &Ref";
	
	Query.SetParameter("Ref", CIKind);
	QueryResult = Query.Execute().Select();
	
	If QueryResult.Next() Then
		Return Mid(QueryResult.ContactInformationKindName,
			StrFind(QueryResult.ContactInformationKindName, ObjectName) + StrLen(ObjectName));
	EndIf;
	
	Return "";
	
EndFunction

Procedure FillCIKindsTable(KindsTable, TreeBranch)
	
	For each KindRow In TreeBranch.Rows Do
		
			Folder = KindsTable.Add();
			Folder.Name          = KindRow.Name;
			Folder.Description = KindRow.Description;
			If KindRow.Parent <> Undefined Then
				Folder.Group    = TreeBranch.Description;
				Folder.NameOfGroup = TreeBranch.Name;
			EndIf;
			
			If KindRow.Rows.Count() > 0 Then
				FillCIKindsTable(KindsTable, KindRow);
			EndIf;
			
	EndDo;
		
EndProcedure

// Returns names of document tabular sections by contact information kind.
//
// Parameters:
//    ContactInformationKindsTable = ValueTable - a list of contact information kinds.
//     * Kind - CatalogRef.ContactInformationKinds - a contact information kind.
//    ObjectName                       - String - a full name of a metadata object.
//
// Returns:
//    Map - tabular section names or a blank string if a tabular section is not available.
//
Function TabularSectionsNamesByCIKinds(ContactInformationKindsTable, ObjectName)
	
	Query = New Query;
	Query.Text = "SELECT
	|	ContactInformationKinds.Kind AS CIKind
	|INTO CIKinds
	|FROM
	|	&ContactInformationKindsTable AS ContactInformationKinds
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	CASE
	|		WHEN ContactInformationKinds.Parent.PredefinedKindName <> """"
	|		THEN ContactInformationKinds.Parent.PredefinedKindName
	|		ELSE ContactInformationKinds.Parent.PredefinedDataName
	|	END AS TabularSectionName,
	|	CIKinds.CIKind AS ContactInformationKind
	|FROM
	|	CIKinds AS CIKinds
	|		LEFT JOIN Catalog.ContactInformationKinds AS ContactInformationKinds
	|		ON CIKinds.CIKind = ContactInformationKinds.Ref";
	
	Query.SetParameter("ContactInformationKindsTable", ContactInformationKindsTable);
	QueryResult = Query.Execute().Select();
	
	Result = New Map;
	While QueryResult.Next() Do
		
		If ValueIsFilled(QueryResult.TabularSectionName) Then
			TabularSectionName = Mid(QueryResult.TabularSectionName, StrFind(QueryResult.TabularSectionName, ObjectName) + StrLen(ObjectName));
		Else
			TabularSectionName = "";
		EndIf;
		
		Result.Insert(QueryResult.ContactInformationKind, TabularSectionName);
	EndDo;
	
	Return Result;
	
EndFunction

// Checks if the form contains filled CI rows of the same kind (except for the current one).
//
Function HasOtherRowsFilledWithThisContactInformationKind(Val Form, Val RowToValidate, Val ContactInformationKind)
	
	AllRowsOfThisKind = Form.ContactInformationAdditionalAttributesDetails.FindRows(
		New Structure("Kind", ContactInformationKind));
	
	For Each KindRow In AllRowsOfThisKind Do
		
		If KindRow <> RowToValidate Then
			Presentation = Form[KindRow.AttributeName];
			If Not IsBlankString(Presentation) Then 
				Return True;
			EndIf;
		EndIf;
		
	EndDo;
	
	Return False;
EndFunction

Procedure OutputUserMessage(MessageText, AttributeName, AttributeField)
	
	AttributeName = ?(IsBlankString(AttributeField), AttributeName, "");
	Common.MessageToUser(MessageText,, AttributeField, AttributeName);
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Filling the additional attributes of the "Contact information" tabular section.

Procedure ContactInformationConvertionToJSON(ContactInformation)
	
	// Conversion
	For Each CIRow In ContactInformation Do
		If IsBlankString(CIRow.Value) Then
			If ValueIsFilled(CIRow.FieldsValues) Then
				
				ContactInformationByFields = ContactsManagerInternal.ContactInformationToJSONStructure(CIRow.FieldsValues,
				CIRow.Type, CIRow.Presentation, False);
				CIRow.Value = ContactsManagerInternal.ToJSONStringStructure(ContactInformationByFields);
				
			ElsIf ValueIsFilled(CIRow.Presentation) Then
				
				CIRow.Value = ContactsByPresentation(CIRow.Presentation, CIRow.Type);
				
			EndIf;
		EndIf;
	EndDo;

EndProcedure

Procedure CreateTabularSectionItems(Val Form, Val ObjectName, ItemForPlacementName, 
	Val ContactInformationRow, Val ContactInformationKindsData)
	
	TabularSectionContactInformationKinds = New Array;
	For Each TabularSectionRow In ContactInformationRow.Rows Do
		TabularSectionContactInformationKinds.Add(TabularSectionRow.Kind);
	EndDo;
	TabularSectionContactInformationKindsData = ContactsManagerInternal.ContactsKindsData(
		TabularSectionContactInformationKinds);
	
	ContactInformationKindName = ContactInformationKindsData[ContactInformationRow.Kind].PredefinedKindName;
	If IsBlankString(ContactInformationKindName) Then
		ContactInformationKindName = ContactInformationKindsData[ContactInformationRow.Kind].PredefinedDataName;
	EndIf;
	Position = StrFind(ContactInformationKindName, ObjectName);
	TabularSectionName = Mid(ContactInformationKindName, Position + StrLen(ObjectName));
	PreviousTabularSectionKind = Undefined;
	
	For Each TabularSectionRow In ContactInformationRow.Rows Do
		
		TabularSectionContactInformationKind = TabularSectionRow.Kind;
		If TabularSectionContactInformationKind <> PreviousTabularSectionKind Then
			
			TabularSectionGroup = Form.Items[TabularSectionName + "ContactInformationGroup"];
			
			Item = Form.Items.Add(TabularSectionRow.AttributeName, Type("FormField"), TabularSectionGroup);
			Item.Type = FormFieldType.InputField;
			Item.DataPath = "Object." + TabularSectionName + "." + TabularSectionRow.AttributeName;
			
			If CanEditContactInformationTypeInDialog(TabularSectionRow.Type) Then
				Item.ChoiceButton = Not TabularSectionRow.DeletionMark;;
				If TabularSectionContactInformationKind.EditInDialogOnly Then
					Item.TextEdit = False;
				EndIf;
				
				Item.SetAction("StartChoice", "Attachable_ContactInformationStartChoice");
			EndIf;
			Item.SetAction("OnChange", "Attachable_ContactInformationOnChange");
			
			If TabularSectionRow.DeletionMark Then
				Item.Font = New Font(,,,,, True);
				Item.TextEdit = False;
			EndIf;
			
			If TabularSectionContactInformationKind.Mandatory Then
				Item.AutoMarkIncomplete = Not TabularSectionRow.DeletionMark;
			EndIf;
			
			Form.ContactInformationParameters[ItemForPlacementName].AddedItems.Add(TabularSectionRow.AttributeName,
				2, False);
			
			AddAttributeToDetails(Form, TabularSectionRow, TabularSectionContactInformationKindsData, False, True,, ItemForPlacementName);
			PreviousTabularSectionKind = TabularSectionContactInformationKind;
			
		EndIf;
		
		Filter = New Structure;
		Filter.Insert("TabularSectionRowID", TabularSectionRow.TabularSectionRowID);
		
		TableRows = Form.Object[TabularSectionName].FindRows(Filter);
		
		If TableRows.Count() = 1 Then
			TableRow = TableRows[0];
			TableRow[TabularSectionRow.AttributeName]                   = TabularSectionRow.Presentation;
			TableRow[TabularSectionRow.AttributeName + "Value"]      = TabularSectionRow.Value;
		EndIf;
	EndDo;

EndProcedure

Procedure FillContactInformationTechnicalFields(ContactInformationRow, Object, ContactInformationType)
	
	// Filling in additional attributes of the tabular section.
	If ContactInformationType = Enums.ContactInformationTypes.EmailAddress Then
		FillTabularSectionAttributesForEmailAddress(ContactInformationRow, Object);
		
	ElsIf ContactInformationType = Enums.ContactInformationTypes.Address Then
		FillTabularSectionAttributesForAddress(ContactInformationRow, Object);
		
	ElsIf ContactInformationType = Enums.ContactInformationTypes.Phone Then
		FillTabularSectionAttributesForPhone(ContactInformationRow, Object);
		
	ElsIf ContactInformationType = Enums.ContactInformationTypes.Fax Then
		FillTabularSectionAttributesForPhone(ContactInformationRow, Object);
		
	ElsIf ContactInformationType = Enums.ContactInformationTypes.WebPage Then
		FillTabularSectionAttributesForWebPage(ContactInformationRow, Object);
	EndIf;
	
EndProcedure

// Fills the additional attributes of the "Contact information" tabular section for an address.
//
// Parameters:
//    TabularSectionRow - TabularSectionRow - a row of the "Contact information" tabular section to be filled.
//    Source - XDTOObject - contact information.
//
Procedure FillTabularSectionAttributesForAddress(TabularSectionRow, Address)
	
	// Defaults
	TabularSectionRow.Country = "";
	TabularSectionRow.State = "";
	TabularSectionRow.City  = "";
	
	If Address.Property("Country") Then
		TabularSectionRow.Country =  Address.Country;
		
		If Metadata.DataProcessors.Find("AdvancedContactInformationInput") <> Undefined Then
			DataProcessors["AdvancedContactInformationInput"].FillExtendedTabularSectionAttributesForAddress(Address, TabularSectionRow);
		EndIf;
		
	EndIf;
	
EndProcedure

// Fills the additional attributes of the "Contact information" tabular section for an email address.
//
// Parameters:
//    TabularSectionRow - TabularSectionRow - a row of the "Contact information" tabular section to be filled.
//    Source - XDTOObject - contact information.
//
Procedure FillTabularSectionAttributesForEmailAddress(TabularSectionRow, Source)
	
	Result = CommonClientServer.ParseStringWithEmailAddresses(TabularSectionRow.Presentation, False);
	
	If Result.Count() > 0 Then
		TabularSectionRow.EMAddress = Result[0].Address;
		
		Pos = StrFind(TabularSectionRow.EMAddress, "@");
		If Pos <> 0 Then
			TabularSectionRow.ServerDomainName = Mid(TabularSectionRow.EMAddress, Pos+1);
		EndIf;
	EndIf;
	
EndProcedure

// Fills the additional attributes of the "Contact information" tabular section for phone and fax numbers.
//
// Parameters:
//    TabularSectionRow - TabularSectionRow - a row of the "Contact information" tabular section to be filled.
//    Source - XDTOObject - contact information.
//
Procedure FillTabularSectionAttributesForPhone(TabularSectionRow, Phone)
	
	If NOT ValueIsFilled(Phone) Then
		Return;
	EndIf;
	
	// Defaults
	TabularSectionRow.PhoneNumberWithoutCodes = "";
	TabularSectionRow.PhoneNumber         = "";
	
	CountryCode     = Phone.CountryCode;
	CityCode     = Phone.AreaCode;
	PhoneNumber = Phone.Number;
	
	If StrStartsWith(CountryCode, "+") Then
		CountryCode = Mid(CountryCode, 2);
	EndIf;
	
	Pos = StrFind(PhoneNumber, ",");
	If Pos <> 0 Then
		PhoneNumber = Left(PhoneNumber, Pos-1);
	EndIf;
	
	Pos = StrFind(PhoneNumber, Chars.LF);
	If Pos <> 0 Then
		PhoneNumber = Left(PhoneNumber, Pos-1);
	EndIf;
	
	TabularSectionRow.PhoneNumberWithoutCodes = RemoveSeparatorsFromPhoneNumber(PhoneNumber);
	TabularSectionRow.PhoneNumber         = RemoveSeparatorsFromPhoneNumber(String(CountryCode) + CityCode + PhoneNumber);
	
EndProcedure

// Fills the additional attributes of the "Contact information" tabular section for phone and fax numbers.
//
// Parameters:
//    TabularSectionRow - TabularSectionRow - a row of the "Contact information" tabular section to be filled.
//    Source - Structure, XDTOObject - contact information.
//
Procedure FillTabularSectionAttributesForWebPage(TabularSectionRow, Source)
	
// Defaults
	TabularSectionRow.ServerDomainName = "";
	PageAddress = "";
	
	If TypeOf(Source) = Type("Structure") Then
		
		If Source.Property("value") Then
			AddressAsString = Source.value;
		EndIf;
		
	Else
		
		PageAddress = Source.Content;
		Namespace = ContactsManagerInternal.Namespace();
		If PageAddress <> Undefined AND PageAddress.Type() = XDTOFactory.Type(Namespace, "Website") Then
			AddressAsString = PageAddress.Value;
		EndIf;
		
	EndIf;
	
	// Deleting the protocol
	Position = StrFind(AddressAsString, "://");
	ServerAddress = ?(Position = 0, AddressAsString, Mid(AddressAsString, Position + 3));
	
	TabularSectionRow.ServerDomainName = ServerAddress;
	
EndProcedure

// Fills contact information in the "Contact information" tabular section of the destination.
//
// Parameters:
//        * Destination    - Arbitrary - an object whose contact information must be filled in.
//        * CIKind       - CatalogRef.ContactInformationKinds - a contact information kind filled in 
//                                                                    the destination.
//        * CIStructure - ValueList, String, Structure - data of contact information field values.
//        * TabularSectionRow - TabularSectionRow, Undefined - destination data if contact 
//                                 information is filled in for a row.
//                                                                      Undefined if contact 
//                                                                      information is filled in for a destination.
//        * Date         - Date - a date, from which contact information is valid. It is used only 
//                                if the StoreChangeHistory flag is set for a CI kind.
//
Procedure FillTabularSectionContactInformation(Destination, CIKind, CIStructure, TabularSectionRow = Undefined, Date = Undefined)
	
	FilterParameters = New Structure;
	If TabularSectionRow <> Undefined Then
		FilterParameters.Insert("TabularSectionRowID", TabularSectionRow.TabularSectionRowID);
	EndIf;
	
	FilterParameters.Insert("Kind", CIKind);
	FoundCIRows = Destination.ContactInformation.FindRows(FilterParameters);
	If FoundCIRows.Count() = 0 Then
		CIRow = Destination.ContactInformation.Add();
		If TabularSectionRow <> Undefined Then
			CIRow.TabularSectionRowID = TabularSectionRow.TabularSectionRowID;
		EndIf;
	Else
		CIRow = FoundCIRows[0];
	EndIf;
	
	// Converting from any readable format to XML.
	FieldsValues = ContactInformationToXML(CIStructure, , CIKind);
	Presentation = ContactInformationPresentation(FieldsValues);
	
	CIRow.Type           = CIKind.Type;
	CIRow.Kind           = CIKind;
	CIRow.Presentation = Presentation;
	CIRow.FieldsValues = FieldsValues;
	
	If CIKind.StoreChangeHistory Then
		CIRow.ValidFrom = ?(ValueIsFilled(Date), Date, CurrentSessionDate());
	EndIf;
	
	FillContactInformationAdditionalAttributes(CIRow, Presentation, FieldsValues);
EndProcedure

// Validates email contact information and reports any errors.
//
// Parameters:
//     EMAddress      - Structure, String - contact information.
//     InformationKind - CatalogRef.ContactInformationKinds - a contact information kind with with validation settings.
//     AttributeName  - String - an optional attribute name used to link an error message.
//
// Returns:
//     Number - error level: 0 - no, 1 - non-critical, 2 - critical.
//
Function EmailFIllingErrors(EMAddress, InformationKind, Val AttributeName = "", AttributeField = "")
	
	If Not InformationKind.CheckValidity Then
		Return 0;
	EndIf;
	
	If Not ValueIsFilled(EMAddress) Then
		Return 0;
	EndIf;
	
	ErrorRow = "";
	Email = ContactsManagerInternal.JSONToContactInformationByFields(EMAddress, Enums.ContactInformationTypes.EmailAddress);
	
	Try
		Result = CommonClientServer.ParseStringWithEmailAddresses(Email.Value);
		If Result.Count() > 1 Then
			
			ErrorRow = NStr("ru = 'Допускается ввод только одного адреса электронной почты'; en = 'Only one email address is allowed'; pl = 'Możesz wpisać tylko jeden adres e-mail';de = 'Sie können nur eine E-Mail-Adresse eingeben';ro = 'Puteți introduce o singură adresă de e-mail';tr = 'Sadece bir e-posta adresini girebilirsiniz'; es_ES = 'Usted puede introducir sola la dirección de correo electrónico'");
			
		EndIf;
	Except
		ErrorRow = BriefErrorDescription(ErrorInfo());
	EndTry;
	
	If Not IsBlankString(ErrorRow) Then
		OutputUserMessage(ErrorRow, AttributeName, AttributeField);
		ErrorLevel = ?(InformationKind.CheckValidity, 2, 1);
	Else
		ErrorLevel = 0;
	EndIf;
	
	Return ErrorLevel;
	
EndFunction

// Fills the additional attributes of the "Contact information" tabular section row.
//
// Parameters:
//    CIRow      - TabularSectionRow - a Contact information row.
//    Presentation - String                     - a value presentation.
//    FieldsValues - ValueList, XDTOObject - field values.
//
Procedure FillContactInformationAdditionalAttributes(CIRow, Presentation, FieldsValues)
	
	If TypeOf(FieldsValues) = Type("XDTODataObject") Then
		CIObject = FieldsValues;
	Else
		CIObject = ContactsManagerInternal.ContactsFromXML(FieldsValues, CIRow.Kind);
	EndIf;
	
	InformationType = CIRow.Type;
	
	If InformationType = Enums.ContactInformationTypes.EmailAddress Then
		FillTabularSectionAttributesForEmailAddress(CIRow, CIObject);
		
	ElsIf InformationType = Enums.ContactInformationTypes.Address Then
		FillTabularSectionAttributesForAddress(CIRow, CIObject);
		
	ElsIf InformationType = Enums.ContactInformationTypes.Phone Then
		FillTabularSectionAttributesForPhone(CIRow, CIObject);
		
	ElsIf InformationType = Enums.ContactInformationTypes.Fax Then
		FillTabularSectionAttributesForPhone(CIRow, CIObject);
		
	ElsIf InformationType = Enums.ContactInformationTypes.WebPage Then
		FillTabularSectionAttributesForWebPage(CIRow, CIObject);
		
	EndIf;
	
EndProcedure

// Checks contact information.
//
Function CheckContactInformationFilling(Presentation, Value, InformationKind, InformationType,
	AttributeName, Comment = Undefined, AttributePath = "")
	
	If IsBlankString(Value) Then
		
		If IsBlankString(Presentation) Then
			Return 0;
		EndIf;
		
		EditInDialogOnly = Common.ObjectAttributeValue(InformationKind, "EditInDialogOnly");
		If EditInDialogOnly AND StrCompare(Presentation, ContactsManagerClientServer.BlankAddressTextAsHyperlink()) = 0 Then
			Return 0;
		EndIf;
		
		ContactInformation = ContactsManagerInternal.ContactsByPresentation(Presentation, InformationKind);
		Value = ?(TypeOf(ContactInformation) = Type("Structure"), ContactsManagerInternal.ToJSONStringStructure(ContactInformation), "");
		
	ElsIf ContactsManagerClientServer.IsXMLContactInformation(Value) Then
		
		Value = ContactInformationInJSON(Value, InformationKind);
		
	EndIf;
	
	// CheckSSL
	If InformationType = Enums.ContactInformationTypes.EmailAddress Then
		ErrorsLevel = EmailFIllingErrors(Value, InformationKind, AttributeName, AttributePath);
	ElsIf InformationType = Enums.ContactInformationTypes.Address Then
		ErrorsLevel = AddressFIllErrors(Value, InformationKind, AttributeName, AttributePath);
	ElsIf InformationType = Enums.ContactInformationTypes.Phone Then
		ErrorsLevel = PhoneFillingErrors(Value, InformationKind, AttributeName);
	ElsIf InformationType = Enums.ContactInformationTypes.Fax Then
		ErrorsLevel = PhoneFillingErrors(Value, InformationKind, AttributeName);
	ElsIf InformationType = Enums.ContactInformationTypes.WebPage Then
		ErrorsLevel = WebPageFillingErrors(Value, InformationKind, AttributeName);
	Else
		// No other checks are made.
		ErrorsLevel = 0;
	EndIf;
	
	Return ErrorsLevel;
	
EndFunction

// Getting and adjusting contact information
Procedure AdjustContactInformation(Form, CIRow)
	
	ConversionResult = New Structure;
	
	If IsBlankString(CIRow.Value) Then
		
		If IsBlankString(CIRow.Presentation) AND ValueIsFilled(CIRow.FieldsValues) Then
			CIRow.Presentation = ContactsManagerInternal.ContactInformationPresentation(CIRow.FieldsValues, CIRow.Kind);
		EndIf;
		
		Result = ContactsManagerInternal.ContactsFromXML(CIRow.FieldsValues, CIRow.Kind, ConversionResult, CIRow.Presentation);
		CIRow.Comment = ?(ValueIsFilled(Result.Comment), Result.Comment, "");
		
		If ConversionResult.Count() = 0 Then
			Return;
		EndIf;
			
		If Not ConversionResult.Property("InfoCorrected") OR ConversionResult.InfoCorrected = False Then
			Return;
		EndIf;
		
		If ConversionResult.InfoCorrected Then
			CIRow.FieldsValues = ContactsManagerInternal.XDTOContactsInXML(Result);
		EndIf;

		If ConversionResult.Property("ErrorText") Then
			Common.MessageToUser(ConversionResult.ErrorText, , CIRow.AttributeName);
		EndIf;
		
		Form.Modified = True;
		
	Else
		
		CIRow.Comment = ContactInformationComment(CIRow.Value);
		
		If IsBlankString(CIRow.Presentation) Then
			CIRow.Presentation = ContactInformationPresentation(CIRow.Value);
		EndIf;
		
	EndIf;
	
EndProcedure

// Validates address contact information and reports any errors. Returns the flag indicating that there are errors.
//
// Parameters:
//     Source - XDTOObject - contact information.
//     InformationKind - CatalogRef.ContactInformationKinds - a contact information kind with with validation settings.
//     AttributeName  - String - an optional attribute name used to link an error message.
//
// Returns:
//     Number - error level: 0 - no, 1 - non-critical, 2 - critical.
//
Function AddressFIllErrors(Source, InformationKind, AttributeName = "", AttributeField = "")
	
	If Not InformationKind.CheckValidity Then
		Return 0;
	EndIf;
	HasErrors = False;
	
	If NOT ContactsManagerInternal.IsNationalAddress(Source) Then
		Return 0;
	EndIf;
	
	If Metadata.DataProcessors.Find("AdvancedContactInformationInput") <> Undefined Then
		ErrorsList = DataProcessors["AdvancedContactInformationInput"].XDTOAddressFillingErrors(Source, InformationKind);
		For Each Item In ErrorsList Do
			OutputUserMessage(Item.Presentation, AttributeName, AttributeField);
			HasErrors = True;
		EndDo;
	EndIf;
	
	If HasErrors AND InformationKind.CheckValidity Then
		Return 2;
	ElsIf HasErrors Then
		Return 1;
	EndIf;
	
	Return 0;
EndFunction

// Validates phone contact information and reports any errors. Returns the flag indicating that there are errors.
//
// Parameters:
//     Source - XDTOObject - contact information.
//     InformationKind - CatalogRef.ContactInformationKinds - a contact information kind with with validation settings.
//     AttributeName  - String - an optional attribute name used to link an error message.
//
// Returns:
//     Number - error level: 0 - no, 1 - non-critical, 2 - critical.
//
Function PhoneFillingErrors(Source, InformationKind, AttributeName = "")
	Return 0;
EndFunction

// Validates web page contact information and reports any errors. Returns the flag indicating that there are errors.
//
// Parameters:
//     Source - XDTOObject - contact information.
//     InformationKind - CatalogRef.ContactInformationKinds - a contact information kind with with validation settings.
//     AttributeName  - String - an optional attribute name used to link an error message.
//
// Returns:
//     Number - error level: 0 - no, 1 - non-critical, 2 - critical.
//
Function WebPageFillingErrors(Source, InformationKind, AttributeName = "")
	Return 0;
EndFunction

Procedure ObjectContactInformationFillingProcessing(Object, Val FillingData)
	
	If TypeOf(FillingData) <> Type("Structure") Then
		Return;
	EndIf;
	
	// Description, if available in the destination object.
	Description = Undefined;
	If FillingData.Property("Description", Description)
		AND CommonClientServer.HasAttributeOrObjectProperty(Object, "Description") Then
		Object.Description = Description;
	EndIf;
	
	// Contact information table. It is filled in only if CI is not in another tabular section.
	ContactInformation = Undefined;
	If FillingData.Property("ContactInformation", ContactInformation) 
		AND CommonClientServer.HasAttributeOrObjectProperty(Object, "ContactInformation") Then
		
		If TypeOf(ContactInformation) = Type("ValueTable") Then
			TableColumns = ContactInformation.Columns;
		Else
			TableColumns = ContactInformation.UnloadColumns().Columns;
		EndIf;
		
		If TableColumns.Find("TabularSectionRowID") = Undefined Then
			
			For Each CIRow In ContactInformation Do
				NewCIRow = Object.ContactInformation.Add();
				FillPropertyValues(NewCIRow, CIRow, , "FieldsValues");
				NewCIRow.FieldsValues = ContactInformationToXML(CIRow.FieldsValues, CIRow.Presentation, CIRow.Kind);
			EndDo;
			
		EndIf;
		
	EndIf;
	
EndProcedure

Function Parent(Form, ItemForPlacementName)
	
	Return ?(IsBlankString(ItemForPlacementName), Form, Form.Items[ItemForPlacementName])
	
EndFunction

Function ContactInformationOutputParameters(Form, ItemForPlacementName, CITitleLocation, DeferredInitialization, ExcludedKinds, HiddenKinds)
	
	If TypeOf(Form.ContactInformationParameters) <> Type("Structure") Then
		Form.ContactInformationParameters = New Structure;
	EndIf;
	
	If Common.SubsystemExists("StandardSubsystems.SendSMSMessage") Then
		ModuleSMS  = Common.CommonModule("SendSMSMessage");
		CanSendSMSMessage = ModuleSMS.CanSendSMSMessage();
	Else
		CanSendSMSMessage = False;
	EndIf;
	
	ContactInformationParameters = New Structure;
	ContactInformationParameters.Insert("GroupForPlacement",              ItemForPlacementName);
	ContactInformationParameters.Insert("TitleLocation",               CITitleLocationValue(CITitleLocation));
	ContactInformationParameters.Insert("AddedAttributes",             New ValueList); 
	ContactInformationParameters.Insert("DeferredInitialization",          DeferredInitialization);
	ContactInformationParameters.Insert("ExcludedKinds",                  ExcludedKinds);
	ContactInformationParameters.Insert("DeferredInitializationExecuted", False);
	ContactInformationParameters.Insert("AddedItems",              New ValueList);
	ContactInformationParameters.Insert("ItemsToAddList",       New ValueList);
	ContactInformationParameters.Insert("CanSendSMSMessage",               CanSendSMSMessage);
	ContactInformationParameters.Insert("Owner",                         Undefined);
	ContactInformationParameters.Insert("URLProcessing",     False);
	ContactInformationParameters.Insert("HiddenKinds",                   HiddenKinds);
	
	AddressParameters = New Structure("PremiseType, Country, IndexOf", "Apartment");
	ContactInformationParameters.Insert("AddressParameters", AddressParameters);
	
	Form.ContactInformationParameters.Insert(ItemForPlacementName, ContactInformationParameters);
	Return Form.ContactInformationParameters[ItemForPlacementName];
	
EndFunction

Function ObjectContactInformationKindsGroup(Val FullMetadataObjectName)
	
	Return ContactInformationKindByName(StrReplace(FullMetadataObjectName, ".", ""));
	
EndFunction

// Returns contact information kinds by a name.
// If no name is specified, a full list of predefined kinds is returned by the application.
//
// Returns:
//  ValueTable  - contact information kinds.
//  * Name - String - a name of a contact information kind.
//  * Ref - CatalogRef.ContactInformationKinds - a reference to an item of the contact information kind catalog.
//
Function PredefinedContactInformationKinds(Name = "") Export
	
	QueryText = "SELECT
		|	ContactInformationKinds.PredefinedKindName AS Name,
		|	ContactInformationKinds.Ref AS Ref
		|FROM
		|	Catalog.ContactInformationKinds AS ContactInformationKinds
		|WHERE
		|	&Filter";
	
	Query = New Query();
	If ValueIsFilled(Name) Then
		QueryText = StrReplace(QueryText, "&Filter", "ContactInformationKinds.PredefinedKindName = &Name");
		Query.SetParameter("Name", Name);
	Else
		QueryText = StrReplace(QueryText, "&Filter", "ContactInformationKinds.PredefinedKindName <> """"");
	EndIf;
	
	Query.Text = QueryText;
	Return Query.Execute().Unload();
	
EndFunction

// Defines the title location value. To support localized configurations.
//
// Parameters:
//  CITitleLocation - String - title location in text presentation in the localization language.
// 
// Returns:
//  String - title location.
//
Function CITitleLocationValue(CITitleLocation)
	
	If FormItemTitleLocation.Left = CITitleLocation Then
		Return "FormItemTitleLocation.Left";
	ElsIf FormItemTitleLocation.Top = CITitleLocation Then
		Return "FormItemTitleLocation.Top";
	ElsIf FormItemTitleLocation.Bottom = CITitleLocation Then
		Return "FormItemTitleLocation.Bottom";
	ElsIf FormItemTitleLocation.Right = CITitleLocation Then
		Return "FormItemTitleLocation.Right";
	ElsIf FormItemTitleLocation.None = CITitleLocation Then
		Return "FormItemTitleLocation.None";
	ElsIf FormItemTitleLocation.Auto = CITitleLocation Then
		Return "FormItemTitleLocation.Auto";
	EndIf;
	
	Return "";
	
EndFunction

Procedure CreateAction(Form, ContactInformationKind, AttributeName, ActionGroup, AddressesCount, HasComment = False, ItemForPlacementName = "ContactInformationGroup")
	
	ContactInformationParameters = FormContactInformationParameters(Form.ContactInformationParameters, ItemForPlacementName);
	URLProcessing = ContactInformationParameters.URLProcessing;
	
	Type = ContactInformationKind.Type;
	CreateActionForType = New Map();
	If Not URLProcessing Then
		CreateActionForType.Insert(Enums.ContactInformationTypes.WebPage, True);
	EndIf;
	
	CreateActionForType.Insert(Enums.ContactInformationTypes.EmailAddress, True);
	CreateActionForType.Insert(Enums.ContactInformationTypes.Phone, True);
	CreateActionForType.Insert(Enums.ContactInformationTypes.Address, ?(AddressesCount > 1, True, False));
	CreateActionForType.Insert(Enums.ContactInformationTypes.Skype, True);
	
	If Type = Enums.ContactInformationTypes.EmailAddress Then
		If Common.SubsystemExists("StandardSubsystems.EmailOperations") Then
			ModuleEmailOperations = Common.CommonModule("EmailOperations");
			If NOT ModuleEmailOperations.CanSendEmails() Then
				CreateActionForType[Type] = False;
			EndIf;
		Else
			CreateActionForType[Type] = False;
		EndIf;
	ElsIf Type = Enums.ContactInformationTypes.Address AND ContactInformationKind.EditInDialogOnly Then
		CreateActionForType[Type] = False;
	EndIf;
	
	If CreateActionForType[Type] = True Then
		
		If Type = Enums.ContactInformationTypes.Address Then
			GroupTopLevelSubmenu = Form.Items.Add("CommandBar" + AttributeName, Type("FormGroup"), ActionGroup);
			GroupTopLevelSubmenu.Type = FormGroupType.CommandBar;
			
			SubmenuGroup = Form.Items.Add("Popup" + AttributeName, Type("FormGroup"), GroupTopLevelSubmenu);
			SubmenuGroup.Title = NStr("ru='Контактная информация'; en = 'Contact information'; pl = 'Informacja kontaktowa';de = 'Kontakte';ro = 'Contacte';tr = 'Bağlantılar'; es_ES = 'Contactos'");
			SubmenuGroup.Type = FormGroupType.Popup;
			SubmenuGroup.Picture = PictureLib.MenuAdditionalFunctions;
			SubmenuGroup.Representation = ButtonRepresentation.Picture;
			SubmenuGroup.HorizontalStretch = False;
			
			
			If Common.IsMobileClient() Then
				ActionGroup.ShowTitle = True;
				
				GroupTopLevelSubmenu.HorizontalStretch = False;
				GroupTopLevelSubmenu.Width = 5;
				GroupTopLevelSubmenu.HorizontalAlign = ItemHorizontalLocation.Right;
				GroupTopLevelSubmenu.GroupVerticalAlign = ItemVerticalAlign.Center;
			EndIf;
		
		Else
			SubmenuGroup = ActionGroup;
			
			// Action is available
			CommandName = "Command" + AttributeName;
			Command = Form.Commands.Add(CommandName);
			
			ContactInformationParameters.AddedItems.Add(CommandName, 9, True);
			Command.Representation = ButtonRepresentation.Picture;
			Command.Action = "Attachable_ContactInformationExecuteCommand";
			
			Item = Form.Items.Add(CommandName,Type("FormButton"), SubmenuGroup);
			
			If Common.IsMobileClient() Then
				Item.GroupVerticalAlign = ItemVerticalAlign.Center;
				Item.Width = 5;
			EndIf;
			
			ContactInformationParameters.AddedItems.Add(CommandName, 2);
			Item.CommandName = CommandName;
		EndIf;
		
		If Type = Enums.ContactInformationTypes.Address Then
			
			If Not ContactInformationKind.DeletionMark Then
				// Entering comment via context menu.
				CommandName = "ContextMenuSubmenu" + AttributeName;
				Button = Form.Items.Add(CommandName,Type("FormButton"), SubmenuGroup);
				Button.Title = NStr("ru = 'Ввести комментарий'; en = 'Enter comment'; pl = 'Wpisz komentarz';de = 'Geben Sie einen Kommentar ein';ro = 'Introduce comentariu';tr = 'Yorumu girin'; es_ES = 'Introducir un comentario'");
				Command = Form.Commands.Add(CommandName);
				Command.ToolTip = NStr("ru = 'Ввести комментарий'; en = 'Enter comment'; pl = 'Wpisz komentarz';de = 'Geben Sie einen Kommentar ein';ro = 'Introduce comentariu';tr = 'Yorumu girin'; es_ES = 'Introducir un comentario'");
				Command.Picture = PictureLib.Comment;
				Command.Action = "Attachable_ContactInformationExecuteCommand";
				Command.ModifiesStoredData = True;
				Button.CommandName = CommandName;
				
				ContactInformationParameters.AddedItems.Add(CommandName, 1);
				ContactInformationParameters.AddedItems.Add(CommandName, 9, True);
			EndIf;
			
			// Change history
			If ContactInformationKind.StoreChangeHistory AND Not ContactInformationKind.DeletionMark Then
				
				CommandName = "ContextMenuSubmenuHistory" + AttributeName;
				Button = Form.Items.Add(CommandName, Type("FormButton"), SubmenuGroup);
				Button.Title = NStr("ru = 'История изменений...'; en = 'Change history...'; pl = 'Historia zmian...';de = 'Der Verlauf der Änderung...';ro = 'Istoria modificărilor...';tr = 'Değişim geçmişi...'; es_ES = 'Historia de cambios...'");
				Command = Form.Commands.Add(CommandName);
				Command.Picture = PictureLib.ChangeHistory;
				Command.ToolTip = NStr("ru = 'Показывает историю изменения контактной информации'; en = 'Shows change history of contact information'; pl = 'Pokazuje historię zmian informacji kontaktowej';de = 'Zeigt den Verlauf der Änderungen in den Kontaktinformationen an';ro = 'Arată istoria modificărilor informațiilor de contact';tr = 'Iletişim bilgilerin değişim geçmişini gösterir'; es_ES = 'Muestra el historial del cambio de la información de contacto'");
				Command.Action = "Attachable_ContactInformationExecuteCommand";
				Command.ModifiesStoredData = False;
				Button.CommandName = CommandName;
				
				ContactInformationParameters.AddedItems.Add(CommandName, 1);
				ContactInformationParameters.AddedItems.Add(CommandName, 9, True);
			EndIf;
			
			// Setting input field properties.
			SeparatorGroup = Form.Items.Add("SubmenuSeparatorAddress" + AttributeName, Type("FormGroup"), SubmenuGroup);
			SeparatorGroup.Type = FormGroupType.ButtonGroup;
			
			CommandName = "YandexMapMenu" + AttributeName;
			Button = Form.Items.Add(CommandName,Type("FormButton"), SeparatorGroup);
			Button.Title = NStr("ru = 'Адрес на Яндекс.Картах'; en = 'Address on Yandex.Maps'; pl = 'Adres na Yandex Maps';de = 'Adresse auf Yandex. Karten';ro = 'Adresa pe Yandex.maps';tr = 'Yandex.Haritalardaki adres'; es_ES = 'Dirección en Yandex.Maps'");
			Command = Form.Commands.Add(CommandName);
			Command.Picture = PictureLib.YandexMaps;
			Command.ToolTip = NStr("ru = 'Показывает адрес на картах Яндекс.Карты'; en = 'Shows address on Yandex.Maps'; pl = 'Pokazuje adres na mapach Yandex.Mapy';de = 'Zeigt die Adresse auf Yandex.Karten';ro = 'Arată adresa pe hărțile Yandex.maps';tr = 'Yandex.Haritalarda adres görüntüler'; es_ES = 'Mostrar dirección en mapas Yandex.Maps'");
			Command.Action = "Attachable_ContactInformationExecuteCommand";
			Button.CommandName = CommandName;
			
			ContactInformationParameters.AddedItems.Add(CommandName, 1);
			ContactInformationParameters.AddedItems.Add(CommandName, 9, True);
			
			CommandName = "GoogleMapMenu" + AttributeName;
			Button = Form.Items.Add(CommandName,Type("FormButton"), SeparatorGroup);
			Button.Title = NStr("ru = 'Адрес на Google Maps'; en = 'Address on Google Maps'; pl = 'Adres w Mapach Google';de = 'Adresse in Google Maps';ro = 'Adresați-vă pe Hărți Google';tr = 'Google Maps'' te adres'; es_ES = 'Dirección en Google Maps'");
			Command = Form.Commands.Add(CommandName);
			Command.Picture = PictureLib.GoogleMaps;
			Command.ToolTip = NStr("ru = 'Показывает адрес на карте Google Maps'; en = 'Show address on Google Maps'; pl = 'Pokaż adres w Mapach Google';de = 'Adresse in Google Maps anzeigen';ro = 'Arată adresa pe Google Maps';tr = 'Google Maps'' ta adresi göster'; es_ES = 'Mostrar la dirección en Google Maps'");
			Command.Action = "Attachable_ContactInformationExecuteCommand";
			Button.CommandName = CommandName;
			
			ContactInformationParameters.AddedItems.Add(CommandName, 1);
			ContactInformationParameters.AddedItems.Add(CommandName, 9, True);
			
			If Not ContactInformationKind.DeletionMark Then
				
				SeparatorGroup = Form.Items.Add("SubmenuSeparator" + AttributeName, Type("FormGroup"), SeparatorGroup);
				SeparatorGroup.Type = FormGroupType.ButtonGroup;
				
				GroupAddressSubmenu = Form.Items.Add("SubmenuCopyAddresses" + AttributeName, Type("FormGroup"), SeparatorGroup);
				GroupAddressSubmenu.Type = FormGroupType.Popup;
				GroupAddressSubmenu.Representation = ButtonRepresentation.Text;
				GroupAddressSubmenu.Title = NStr("ru='Заполнить'; en = 'Fill in'; pl = 'Wypełnij wg';de = 'Ausfüllen';ro = 'Completați';tr = 'Doldur'; es_ES = 'Rellenar'");
			
			EndIf;
			
		ElsIf Type = Enums.ContactInformationTypes.EmailAddress Then
			
			Item.Title = NStr("ru = 'Написать письмо'; en = 'Create email'; pl = 'Napisz e-mail';de = 'Eine E-Mail schreiben';ro = 'Scrie scrisoare';tr = 'E-posta yazın'; es_ES = 'Escribir un correo electrónico'");
			Command.ToolTip = NStr("ru = 'Написать письмо'; en = 'Create email'; pl = 'Napisz e-mail';de = 'Eine E-Mail schreiben';ro = 'Scrie scrisoare';tr = 'E-posta yazın'; es_ES = 'Escribir un correo electrónico'");
			Command.Picture = PictureLib.SendEmail;
			
		ElsIf Type = Enums.ContactInformationTypes.WebPage Then
			
			Item.Title = NStr("ru = 'Перейти'; en = 'Navigate'; pl = 'Przejdź';de = 'Navigieren';ro = 'Navigare';tr = 'Geçiş yapın'; es_ES = 'Navegar'");
			Command.ToolTip = NStr("ru = 'Перейти по ссылке'; en = 'Follow the link'; pl = 'Kliknij URL';de = 'Klicken Sie auf URL';ro = 'Navigare pe link';tr = 'URL tıklayın'; es_ES = 'Hacer clic en URL'");
			Command.Picture = PictureLib.ContactInformationGoToURL;
			
		ElsIf Type = Enums.ContactInformationTypes.Phone Then
			If Form.ContactInformationParameters[ItemForPlacementName].CanSendSMSMessage Then
				Item.Title = NStr("ru = 'Позвонить или отправить SMS'; en = 'Make call or send text message'; pl = 'Zadzwoń lub wyślij SMS''a';de = 'Anrufen oder SMS senden';ro = 'Apel telefonic sau trimite SMS';tr = 'Ara veya SMS gönder'; es_ES = 'Llamar o enviar SMS'");
				Command.ToolTip = NStr("ru = 'Позвонить или отправить SMS'; en = 'Make call or send text message'; pl = 'Zadzwoń lub wyślij SMS''a';de = 'Anrufen oder SMS senden';ro = 'Apel telefonic sau trimite SMS';tr = 'Ara veya SMS gönder'; es_ES = 'Llamar o enviar SMS'");
				Command.Picture = PictureLib.CallOrSendSMS;
			Else
				Item.Title = NStr("ru = 'Позвонить'; en = 'Call'; pl = 'Zadzwoń';de = 'Anruf';ro = 'Apel';tr = 'Ara'; es_ES = 'Llamada'");
				Command.ToolTip = NStr("ru = 'Позвонить по телефону'; en = 'Make a phone call.'; pl = 'Zatelefonować';de = 'Telefonisch anrufen';ro = 'Apel telefonic';tr = 'Telefonla ara'; es_ES = 'Llamar por teléfono'");
				Command.Picture = PictureLib.MakeCall;
			EndIf;
			
		ElsIf Type = Enums.ContactInformationTypes.Skype Then
			Item.Title = NStr("ru = 'Skype'; en = 'Skype'; pl = 'Skype';de = 'Skype';ro = 'Skype';tr = 'Skype'; es_ES = 'Skype'");
			Command.ToolTip = NStr("ru = 'Skype'; en = 'Skype'; pl = 'Skype';de = 'Skype';ro = 'Skype';tr = 'Skype'; es_ES = 'Skype'");
			Command.Picture = PictureLib.Skype;
		EndIf;
		
	EndIf;
	
EndProcedure

Function FormContactInformationParameters(ContactInformationParameters, ItemForPlacementName)
	
	If NOT ValueIsFilled(ItemForPlacementName) OR NOT ContactInformationParameters.Property(ItemForPlacementName) Then
		For each FirstRecord In ContactInformationParameters Do
			Return FirstRecord.Value;
		EndDo;
		Return ContactInformationParameters;
	EndIf;
	
	Return ContactInformationParameters[ItemForPlacementName];
	
EndFunction

Function DefineNextString(Form, ContactInformation, CIRow)
	
	Position = ContactInformation.IndexOf(CIRow) + 1;
	While Position < ContactInformation.Count() Do
		NextRow = ContactInformation.Get(Position);
		If NextRow = Undefined Then
			Return Undefined;
		EndIf;
		If Form.Items.Find(NextRow.AttributeName) <> Undefined Then
			Return NextRow;
		EndIf;
		Position = Position + 1;
	EndDo;
	
	Return Undefined;
EndFunction

Function FindContactInformationStrings(ContactInformationKind, Date, ContactInformation)
	
	Filter = New Structure("Kind", ContactInformationKind);
	If ContactInformationKind.StoreChangeHistory Then
		Filter.Insert("ValidFrom", Date);
	EndIf;
	FoundRows = ContactInformation.FindRows(Filter);
	Return FoundRows;
	
EndFunction

Function MultipleValuesInputProhibited(ContactInformationKind, ContactInformation, Date, TabularSectionRowID = Undefined)
	
	If ContactInformationKind.AllowMultipleValueInput Then
		Return False;
	EndIf;
	
	Filter = New Structure("Kind", ContactInformationKind);
	
	If TabularSectionRowID <> Undefined Then
		Filter.Insert("TabularSectionRowID", TabularSectionRowID);
	EndIf;
	
	If ContactInformationKind.StoreChangeHistory Then
		Filter.Insert("ValidFrom", Date);
	EndIf;
	
	FoundRows = ContactInformation.FindRows(Filter);
	Return FoundRows.Count() > 0;
	
EndFunction

Procedure FillObjectContactInformationFromString(ObjectContactInformationRow, Periodic, ContactInformationRow)
	
	FillPropertyValues(ContactInformationRow, ObjectContactInformationRow);
	If Periodic Then
		ContactInformationRow.ValidFrom = ObjectContactInformationRow.Date;
	EndIf;
	
	If ValueIsFilled(ContactInformationRow.Value) Then
		ContactInformationObject = ContactsManagerInternal.JSONToContactInformationByFields(ContactInformationRow.Value, ObjectContactInformationRow.Type);
		FillContactInformationTechnicalFields(ContactInformationRow, ContactInformationObject, ObjectContactInformationRow.Type);
	EndIf;
	
EndProcedure

Procedure RestoreEmptyValuePresentation(ContactInformationRow)
	
	If IsBlankString(ContactInformationRow.Type) Then
		ContactInformationRow.Type = ContactInformationManagementInternalCached.ContactInformationKindType(
			ContactInformationRow.Kind);
	EndIf;
	
	// FieldsValues may be absent in a contact information string.
	FieldsInfo = New Structure("FieldsValues", Undefined);
	FillPropertyValues(FieldsInfo, ContactInformationRow);
	HasFieldsValues = (FieldsInfo.FieldsValues <> Undefined);
	
	EmptyPresentation = IsBlankString(ContactInformationRow.Presentation);
	EmptyValue      = IsBlankString(ContactInformationRow.Value);
	EmptyFieldsValues = ?(HasFieldsValues, IsBlankString(FieldsInfo.FieldsValues), True);
	
	AllFieldsEmpty = EmptyPresentation AND EmptyValue AND EmptyFieldsValues;
	AllFieldsFilled = Not EmptyPresentation AND Not EmptyValue AND NOT EmptyFieldsValues;
	
	If AllFieldsEmpty Or AllFieldsFilled Then
		Return;
	EndIf;
	
	If EmptyPresentation Then
		
		ContactInformationFormat = Common.ObjectAttributesValues(ContactInformationRow.Kind,
			"Type, IncludeCountryInPresentation, CheckByFIAS");
		
		If Metadata.CommonModules.Find("AddressManager") <> Undefined Then
			ModuleAddressManager = Common.CommonModule("AddressManager");
			ModuleAddressManager.DetermineContactInformationFormat(ContactInformationFormat);
		EndIf;
		
		ValuesSource = ?(EmptyFieldsValues, ContactInformationRow.Value, ContactInformationRow.FieldsValues);
		
		ContactInformationRow.Presentation = ContactsManagerInternal.ContactInformationPresentation(
			ValuesSource, ContactInformationFormat);
		
	EndIf;
	
	If EmptyValue Then
		
		If Not EmptyPresentation AND EmptyFieldsValues Then
			
			AddressByFields = ContactsManagerInternal.ContactsByPresentation(
				ContactInformationRow.Presentation, ContactInformationRow.Type);
			ContactInformationRow.Value = ContactsManagerInternal.ToJSONStringStructure(AddressByFields);
			
			If HasFieldsValues Then
				ContactInformationRow.FieldsValues = ContactsManagerInternal.ContactsFromJSONToXML(
					ContactInformationRow.Value, ContactInformationRow.Type);
			EndIf;
			
		ElsIf Not EmptyFieldsValues Then
			
			ContactInformationRow.Value = ContactInformationInJSON(ContactInformationRow.FieldsValues,
				ContactInformationRow.Type);
			
		EndIf;
	
	ElsIf EmptyFieldsValues AND HasFieldsValues Then
		
		ContactInformationRow.FieldsValues = ContactInformationToXML(ContactInformationRow.Value, 
			ContactInformationRow.Presentation, ContactInformationRow.Kind);
			
	EndIf;
	
EndProcedure

// Converts a country code to the standard format - a three-character string.
//
Function WorldCountryCode(Val CountryCode)
	
	If TypeOf(CountryCode)=Type("Number") Then
		Return Format(CountryCode, "ND=3; NZ=; NLZ=; NG=");
	EndIf;
	
	Return Right("000" + CountryCode, 3);
EndFunction

// Returns a string enclosed in quotes.
//
Function CheckQuotesInString(Val Row)
	Return """" + StrReplace(Row, """", """""") + """";
EndFunction

Procedure UpdateConextMenu(Form, ItemForPlacementName)
	
	ContactInformationParameters = Form.ContactInformationParameters[ItemForPlacementName];
	AllRows = Form.ContactInformationAdditionalAttributesDetails;
	FoundRows = AllRows.FindRows( 
		New Structure("Type, IsTabularSectionAttribute", Enums.ContactInformationTypes.Address, False));
		
	TotalCommands = 0;
	For Each CIRow In AllRows Do
		
		If TotalCommands > 50 Then // Restriction for a large number of addresses on the form
			Break;
		EndIf;
		
		If CIRow.Type <> Enums.ContactInformationTypes.Address Then
			Continue;
		EndIf;
		
		SubmenuCopyAddresses = Form.Items.Find("SubmenuCopyAddresses" + CIRow.AttributeName);
		ContextSubmenuCopyAddresses = Form.Items.Find("ContextSubmenuCopyAddresses" + CIRow.AttributeName);
		If SubmenuCopyAddresses <> Undefined AND ContextSubmenuCopyAddresses = Undefined Then
			Continue;
		EndIf;
			
		CommandsCountInSubmenu = 0;
		AddressesListInSubmenu = New Map();
		AddressesListInSubmenu.Insert(Upper(CIRow.Presentation), True);
		
		For Each Address In FoundRows Do
			
			If CommandsCountInSubmenu > 7 Then // Restriction for a large number of addresses on the form
				Break;
			EndIf;
			
			If Address.IsHistoricalContactInformation Or Address.AttributeName = CIRow.AttributeName Then
				Continue;
			EndIf;
			
			CommandName = "MenuSubmenuAddress" + CIRow.AttributeName + "_" + Address.AttributeName;
			Command = Form.Commands.Find(CommandName);
			If Command = Undefined Then
				Command = Form.Commands.Add(CommandName);
				Command.ToolTip = NStr("ru = 'Скопировать адрес'; en = 'Copy address'; pl = 'Skopiować adres';de = 'Adresse kopieren';ro = 'Copie adresa';tr = 'Adresi kopyala'; es_ES = 'Copiar la dirección'");
				Command.Action = "Attachable_ContactInformationExecuteCommand";
				Command.ModifiesStoredData = True;
				
				ContactInformationParameters.AddedItems.Add(CommandName, 9, True);
				CommandsCountInSubmenu = CommandsCountInSubmenu + 1;
			EndIf;
			
			AddressPresentation = ?(CIRow.InternationalAddressFormat,
				StringFunctionsClientServer.LatinString(Address.Presentation), Address.Presentation);
			
			If AddressesListInSubmenu[Upper(Address.Presentation)] <> Undefined Then
				AddressPresentation = "";
			Else
				AddressesListInSubmenu.Insert(Upper(Address.Presentation), True);
			EndIf;
			
			If SubmenuCopyAddresses <> Undefined Then
				AddButtonCopyAddress(Form, CommandName, 
					AddressPresentation, ContactInformationParameters, SubmenuCopyAddresses);
				EndIf;
				
			If ContextSubmenuCopyAddresses <> Undefined Then
				AddButtonCopyAddress(Form, CommandName, 
					AddressPresentation, ContactInformationParameters, ContextSubmenuCopyAddresses);
			EndIf;
			
		EndDo;
		TotalCommands = TotalCommands + CommandsCountInSubmenu;
	EndDo;
	
EndProcedure

Procedure AddButtonCopyAddress(Form, CommandName, ItemTitle, ContactInformationParameters, Submenu)
	
	ItemName = Submenu.Name + "_" + CommandName;
	Button = Form.Items.Find(ItemName);
	If Button = Undefined Then
		Button = Form.Items.Add(ItemName, Type("FormButton"), Submenu);
		Button.CommandName = CommandName;
		ContactInformationParameters.AddedItems.Add(ItemName, 1);
	EndIf;
	Button.Title = ItemTitle;
	Button.Visible = ValueIsFilled(ItemTitle);

EndProcedure

Function NewContactInformationDetails(Val Type) Export
	
	If Metadata.CommonModules.Find("AddressManagerClientServer") <> Undefined Then
		ModuleAddressManagerClientServer = Common.CommonModule("AddressManagerClientServer");
		Return ModuleAddressManagerClientServer.NewContactInformationDetails(Type);
	EndIf;
	
	Return ContactsManagerClientServer.NewContactInformationDetails(Type);
	
EndFunction

// Getting a deep object property. 
//
Function GetXDTOObjectAttribute(XTDOObject, XPath) Export
	
	// Line breaks are not expected in XPath.
	PropertyString = StrReplace(StrReplace(XPath, "/", Chars.LF), Chars.LF + Chars.LF, "/");
	
	PropertyCount = StrLineCount(PropertyString);
	If PropertyCount = 1 Then
		Result = XTDOObject.Get(PropertyString);
		If TypeOf(Result) = Type("XDTODataObject") Then 
			Return Result.Value;
		EndIf;
		Return Result;
	EndIf;
	
	Result = ?(PropertyCount = 0, Undefined, XTDOObject);
	For Index = 1 To PropertyCount Do
		Result = Result.Get(StrGetLine(PropertyString, Index));
		If Result = Undefined Then 
			Break;
		EndIf;
	EndDo;
	
	Return Result;
EndFunction

Function ContactInformationFromFormAttributes(Form, Object)
	
	ContactInformation = NewContactInformation(False);
	
	ObjectMetadata = Object.Ref.Metadata();
	MetadataObjectName = ObjectMetadata.Name;
	FullMetadataObjectName = ObjectMetadata.FullName();
	ContactInformationKindsGroup = ObjectContactInformationKindsGroup(FullMetadataObjectName);
	TabularSectionsNamesByCIKinds = Undefined;
	
	For Each TableRow In Form.ContactInformationAdditionalAttributesDetails Do
		
		AttributeName  = TableRow.AttributeName;
		
		Item = Form.Items.Find(AttributeName);
		If Item <> Undefined Then
			If Item.Type = FormFieldType.LabelField AND Item.Hyperlink Then
				If IsBlankString(TableRow.Presentation)
					OR TableRow.Presentation = ContactsManagerClientServer.BlankAddressTextAsHyperlink() Then
					Continue;
				EndIf;
			EndIf;
		EndIf;
		
		RestoreEmptyValuePresentation(TableRow);
		
		If TableRow.IsTabularSectionAttribute Then
			
			If TabularSectionsNamesByCIKinds = Undefined Then
				Filter = New Structure("IsTabularSectionAttribute", True);
				TabularSectionCIKinds = Form.ContactInformationAdditionalAttributesDetails.Unload(Filter, "Kind");
				TabularSectionsNamesByCIKinds = TabularSectionsNamesByCIKinds(TabularSectionCIKinds, MetadataObjectName);
			EndIf;
			
			TabularSectionName = TabularSectionsNamesByCIKinds[TableRow.Kind];
			FormTabularSection = Form.Object[TabularSectionName];
			For Each FormTabularSectionRow In FormTabularSection Do
				
				RowID = FormTabularSectionRow.GetID();
				FormTabularSectionRow.TabularSectionRowID = RowID;
				
				TabularSectionRow = Object[TabularSectionName][FormTabularSectionRow.LineNumber - 1];
				TabularSectionRow.TabularSectionRowID = RowID;
				
				Value = FormTabularSectionRow[AttributeName + "Value"];
				
				MoveContactInformationRecordFromFormToTable(ContactInformation, TableRow, Value, RowID);
				
			EndDo;
			
		Else
			
			If TableRow.Kind.Parent <> ContactInformationKindsGroup Then
				Continue;
			EndIf;
			
			MoveContactInformationRecordFromFormToTable(ContactInformation, TableRow, TableRow.Value);
			
		EndIf;
		
	EndDo;
	
	Return ContactInformation;
	
EndFunction

Procedure MoveContactInformationRecordFromFormToTable(ContactInformation, TableRow, Val Value, Val RowID = Undefined)
	
	If IsBlankString(Value) Then
		Return;
	EndIf;
	
	If ContactsManagerClientServer.IsXMLContactInformation(Value) Then
		CIObject = ContactsManagerInternal.ContactInformationToJSONStructure(Value, TableRow.Type);
	Else
		CIObject = ContactsManagerInternal.JSONToContactInformationByFields(Value, TableRow.Type);
	EndIf;
	
	If Not ContactsManagerInternal.ContactsFilledIn(CIObject) Then
		Return;
	EndIf;
	
	ContactInformationRow = ContactInformation.Add();
	
	ValidFrom = ?(TableRow.Property("ValidFrom"), TableRow.ValidFrom, Undefined);
	FillPropertyValues(ContactInformationRow, TableRow, "Kind,Type");
	
	ContactInformationRow.Presentation = CIObject.Value;
	ContactInformationRow.Value      = ContactsManagerInternal.ToJSONStringStructure(CIObject);
	ContactInformationRow.FieldsValues = ContactsManagerInternal.ContactsFromJSONToXML(CIObject, TableRow.Type);
	
	If ValueIsFilled(ValidFrom) Then
		ContactInformationRow.Date    = ValidFrom;
	EndIf;
	
	ContactInformationRow.TabularSectionRowID = RowID;
	
EndProcedure

// Contact information kinds

Function ParametersFromContactInformationKind(Val ContactInformationKind)
	
	Query = New Query;
	Query.Text = 
	"SELECT TOP 1
	|	ContactInformationKinds.Ref AS Ref,
	|	ContactInformationKinds.Parent AS Parent,
	|	ContactInformationKinds.IsFolder AS IsFolder,
	|	ContactInformationKinds.Description AS Description,
	|	ContactInformationKinds.OnlyNationalAddress AS OnlyNationalAddress,
	|	ContactInformationKinds.FieldKindOther AS FieldKindOther,
	|	ContactInformationKinds.IncludeCountryInPresentation AS IncludeCountryInPresentation,
	|	ContactInformationKinds.DenayEditingByUser AS DenayEditingByUser,
	|	ContactInformationKinds.Used AS Used,
	|	ContactInformationKinds.CanChangeEditMethod AS CanChangeEditMethod,
	|	ContactInformationKinds.Mandatory AS Mandatory,
	|	ContactInformationKinds.CheckValidity AS CheckValidity,
	|	ContactInformationKinds.AllowMultipleValueInput AS AllowMultipleValueInput,
	|	ContactInformationKinds.EditInDialogOnly AS EditInDialogOnly,
	|	ContactInformationKinds.AddlOrderingAttribute AS AddlOrderingAttribute,
	|	ContactInformationKinds.HideObsoleteAddresses AS HideObsoleteAddresses,
	|	ContactInformationKinds.PhoneWithExtension AS PhoneWithExtension,
	|	ContactInformationKinds.Type AS Type,
	|	ContactInformationKinds.StoreChangeHistory AS StoreChangeHistory,
	|	ContactInformationKinds.PredefinedKindName AS Name,
	|	ContactInformationKinds.InternationalAddressFormat AS InternationalAddressFormat
	|FROM
	|	Catalog.ContactInformationKinds AS ContactInformationKinds
	|WHERE
	|	ContactInformationKinds.Ref = &Ref";
	
	Query.SetParameter("Ref", ContactInformationKind);
	
	QueryResult = Query.Execute().Unload();
	
	If QueryResult.Count() = 0 Then
		ErrorTextTemplate = NStr("ru='При получении свойств контактной информации был передан неверный вид контактной информации. %1'; en = 'The incorrect kind of contact information was transferred when receiving the contact information properties.%1'; pl = 'Po otrzymaniu właściwości informacji kontaktowych została przesłano niewłaściwy rodzaj informacji kontaktowych. %1';de = 'Als die Eigenschaften der Kontaktinformationen ermittelt wurden, wurden die falschen Kontaktinformationen übertragen. %1';ro = 'La obținerea proprietăților informațiilor de contact a fost transmis tipul incorect al informațiilor de contact.%1';tr = 'İletişim bilgilerinin özelliklerini aldığınızda, iletişim bilgilerinin yanlış bir görünümü iletildi.%1'; es_ES = 'Al recibir las propiedades de información de contacto ha sido pasado un tipo incorrecto de información de contacto. %1'");
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(ErrorTextTemplate , String(ContactInformationKind));
		Raise ErrorText;
	EndIf;
	
	Type = QueryResult[0].Type;
	
	CurrentParameters = Common.ValueTableRowToStructure(QueryResult[0]);
	KindParameters = ContactInformationParametersDetails(Type);
	FillPropertyValues(KindParameters,CurrentParameters);
	
	If Type = Enums.ContactInformationTypes.Address Then
		
		FillPropertyValues(KindParameters.ValidationSettings, CurrentParameters, "IncludeCountryInPresentation,
		|CheckValidity,HideObsoleteAddresses,OnlyNationalAddress");
		
		If Metadata.CommonModules.Find("AddressManager") <> Undefined Then
			ModuleAddressManager = Common.CommonModule("AddressManager");
			ModuleAddressManager.SupplementAddressCheckSettings(KindParameters, ContactInformationKind);
		EndIf;
		
	ElsIf Type = Enums.ContactInformationTypes.EmailAddress Then
		KindParameters.ValidationSettings.CheckValidity = CurrentParameters.CheckValidity;
	ElsIf Type = Enums.ContactInformationTypes.Phone Then
		KindParameters.ValidationSettings.PhoneWithExtension = CurrentParameters.PhoneWithExtension;
	ElsIf Type = Enums.ContactInformationTypes.Other Then
		KindParameters.ValidationSettings.FieldKindOther = CurrentParameters.FieldKindOther;
	EndIf;
	
	KindParameters.Kind = QueryResult[0].Ref;
	
	Return KindParameters;
	
EndFunction

Function ContactInformationKindObject(Name, IsGroup = False)
	
	Query = New Query;
	Query.Text = 
	"SELECT TOP 1
	|	ContactInformationKinds.Ref AS Ref
	|FROM
	|	Catalog.ContactInformationKinds AS ContactInformationKinds
	|WHERE
	|	ContactInformationKinds.PredefinedKindName = &Name
	|	AND ContactInformationKinds.IsFolder = &IsFolder";
	
	Query.SetParameter("Name", Name);
	Query.SetParameter("IsFolder", IsGroup);
	
	QueryResult = Query.Execute();
	If Not QueryResult.IsEmpty() Then
		DetailedRecordsSelection = QueryResult.Unload();
		Ref = DetailedRecordsSelection[0].Ref;
		Return Ref.GetObject();
	EndIf;
	
	PredefinedItemsNames = Metadata.Catalogs.ContactInformationKinds.GetPredefinedNames();
	PredefinedItemName  = PredefinedItemsNames.Find(Name);
	
	If PredefinedItemName <> Undefined Then
		Object = Catalogs.ContactInformationKinds[Name].GetObject();
		Object.PredefinedKindName = Name;
		Return Object;
	EndIf;
	
	If IsGroup Then
		NewItem = Catalogs.ContactInformationKinds.CreateFolder();
	Else
		NewItem = Catalogs.ContactInformationKinds.CreateItem();
	EndIf;
	
	NewItem.PredefinedKindName = Name;
	
	Return NewItem;
	
EndFunction

// Returns details of contact information properties for the passed contact information type.
// The structure is used in update handlers when filling in contact information kinds or generating 
// opening parameters of the address or phone input form for the method used in OpenContactInformationForm.
// 
// Parameters:
//    ContactInformationType - EnumRef.ContactInformationTypes - a contact information type.
//
// Returns:
//   Structure - contains a structure with the following fields:
//     * Name          - String - a unique name of a contact information kind.
//     * Description - String - a description of a contact information kind.
//     * Kind - CatalogRef.ContactInformationKinds - a reference to a contact information kind.
//                                                         Default value - Catalog.ContactInformationKinds.EmptyRef.
//     * Type - EnumRef.ContactInformationTypes - a contact information type.
//     * Group - CatalogRef.ContactInformationKinds, Undefined - a reference to a group (parent) of a catalog item.
//                                                          Default value is Undefined.
//     * Useв - Boolean - if False, a contact information kind is not available for users.
//                               Such a kind is not displayed in forms and lists of contact information kinds.
//                               Default value is True.
//     * CanChangeEditingMethod - Boolean - indicates whether a user can change properties of a contact information kind.
//                                                    If False, properties of a contact information 
//                                                    kind form are view-only. Default value is False.
//     * EditInDialogOnly - if True, the form displays a hyperlink with a contact information 
//                                               presentation. Click it to open the form of the 
//                                               matching contact information type. The property is applicable only for contact information with the type:
//                                               Address, Phone, Fax, WebPage. Default value is False.
//     * StoreChangeHistory     - Boolean - indicates whether the contact information change history can be stored.
//                                              Storing the history is allowed if the 
//                                              EditInDialogOnly flag is True. The property is only applicable when the tabular section
//                                              ContactInformation contains the ValidFrom attribute. Default value
//                                              - False.
//     * Mandatory       - Boolean - if True, a value in the contact information field is mandatory.
//                                                Default value is False.
//     * AllowMultipleValuesInput - Boolean - indicates whether multiple value input is available for this kind.
//                                                  Default value is False.
//     * DenyEditingByUser - Boolean - indicates that editing of a contact information kind by a 
//                                                       user is unavailable. Default value is False.
//     * InternationalAddressFormat - Boolean - indicates that an address format is international.
//                                   If True, all addresses can be entered in international format only.
//                                   Default value is False.
//     * FieldKindOther             - String - defines the appearance of the Other type field on the form. Options:
//                                            MultilineWide, SingleLineWide, SingleLineNarrow. The 
//                                            property is applicable only for contact information with the type: Other. 
//                                            The default value for a contact information kind with the Other type is SingleLineWide, otherwise, a blank string.
//     * ValidationSettings - Structure, Undefined    - validation settings of a contact information kind. 
//         A composition of fields depends on a contact information type. For the Address type - a structure containing the following fields:
//                * OnlyNationalAddress      - Boolean - if True, you can enter only national 
//                                                          addresses. Changing the address country is not allowed.
//                * CheckValidity        - Boolean - if True, for national addresses, you can enter 
//                                                          only addresses broken down by fields being checked by
//                                                          FIAS. It is allowed to enter addresses 
//                                                          of other countries in free form if the OnlyNationalAddress property = False.
//                                                          Default value is False.
//                * IncludeCountryInPresentation - Boolean - if True, a country Description is 
//                                                          always added to an address presentation even when other address fields are blank.
//                                                          Default value is False
//                * SpecifyRNCMT              - Boolean - indicates whether manual input of an RNCMT code is available in the address input form.
//            For the EmailAddress type - a structure containing the following fields:
//                * CheckValidity        - Boolean - if True, a user cannot enter an incorrect email 
//                                                          address.
//                                                          Default value is False.
//            For the Phone type - a structure containing the following fields:
//                * PhoneWithExtension        - Boolean - if True, you can enter an extension in the 
//                                                          phone input form. Default value is True.
//            For other types, the default value is Undefined.
//
Function ContactInformationParametersDetails(Val ContactInformationType)
	
	KindParameters = ContactInformationKindCommonParametersDetails();
	
	KindParameters.Insert("Kind", Catalogs.ContactInformationKinds.EmptyRef());
	KindParameters.Insert("Order", Undefined);
	KindParameters.Insert("Type", ContactInformationType);
	KindParameters.Insert("CanChangeEditMethod",    False);
	KindParameters.Insert("EditInDialogOnly",         False);
	KindParameters.Insert("Mandatory",               False);
	KindParameters.Insert("AllowMultipleValueInput",      False);
	KindParameters.Insert("DenayEditingByUser", False);
	KindParameters.Insert("StoreChangeHistory",              False);
	KindParameters.Insert("InternationalAddressFormat",            False);
	
	FieldKindOther = ?(ContactInformationType = Enums.ContactInformationTypes.Other,
		"SingleLineWide", "");
	
	KindParameters.Insert("FieldKindOther", FieldKindOther);
	
	If ContactInformationType =  Enums.ContactInformationTypes.Address Then
		ValidationSettings = New Structure;
		ValidationSettings.Insert("OnlyNationalAddress",      False);
		ValidationSettings.Insert("CheckValidity",        False);
		ValidationSettings.Insert("IncludeCountryInPresentation", False);
		ValidationSettings.Insert("SpecifyRNCMT",               False);
		ValidationSettings.Insert("HideObsoleteAddresses",   False); // obsolete. Left for backward compatibility.
		ValidationSettings.Insert("CheckByFIAS",              True); // obsolete. Left for backward compatibility.
	ElsIf ContactInformationType = Enums.ContactInformationTypes.EmailAddress Then
		ValidationSettings = New Structure;
		ValidationSettings.Insert("CheckValidity",        False);
	ElsIf ContactInformationType =  Enums.ContactInformationTypes.Phone Then
		ValidationSettings = New Structure;
		ValidationSettings.Insert("PhoneWithExtension",    True);
	Else
		ValidationSettings = Undefined;
	EndIf;
	
	KindParameters.Insert("ValidationSettings", ValidationSettings);
	Return KindParameters;

EndFunction

Function ContactInformationKindCommonParametersDetails()
	
	KindParameters = New Structure;
	KindParameters.Insert("Name", "");
	KindParameters.Insert("Group", Undefined);
	KindParameters.Insert("Description", "");
	KindParameters.Insert("Used", True);
	
	Return KindParameters;
	
EndFunction

#EndRegion
