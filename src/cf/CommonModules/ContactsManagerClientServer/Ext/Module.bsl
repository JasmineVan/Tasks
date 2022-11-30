///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Public

// Generates a string presentation of a phone number.
//
// Parameters:
//    CountryCode     - String - a country code.
//    CityCode     - String - a city code.
//    PhoneNumber - String - a phone number.
//    Extension    - String - an extension.
//    Comment   - String - a comment.
//
// Returns:
//   - String - a phone presentation.
//
Function GeneratePhonePresentation(CountryCode, CityCode, PhoneNumber, Extension, Comment) Export
	
	Presentation = TrimAll(CountryCode);
	If Not IsBlankString(Presentation) AND Not StrStartsWith(Presentation, "+") Then
		Presentation = "+" + Presentation;
	EndIf;
	
	If Not IsBlankString(CityCode) Then
		Presentation = Presentation + ?(IsBlankString(Presentation), "", " ") + "(" + TrimAll(CityCode) + ")";
	EndIf;
	
	If Not IsBlankString(PhoneNumber) Then
		Presentation = Presentation + ?(IsBlankString(Presentation), "", " ") + TrimAll(PhoneNumber);
	EndIf;
	
	If NOT IsBlankString(Extension) Then
		Presentation = Presentation + ?(IsBlankString(Presentation), "", ", ") + "ext. " + TrimAll(Extension);
	EndIf;
	
	If NOT IsBlankString(Comment) Then
		Presentation = Presentation + ?(IsBlankString(Presentation), "", ", ") + TrimAll(Comment);
	EndIf;
	
	Return Presentation;
	
EndFunction

// Returns a flag indicating whether a contact information data string is in XML format.
//
// Parameters:
//     Text - String - a string to check.
//
// Returns:
//     Boolean -  a check result.
//
Function IsXMLContactInformation(Val Text) Export
	
	Return TypeOf(Text) = Type("String") AND StrStartsWith(TrimL(Text), "<");
	
EndFunction

// Returns a flag indicating whether a contact information data string is in JSON format.
//
// Parameters:
//     Text - String - a string to check.
//
// Returns:
//     Boolean -  a check result.
//
Function IsJSONContactInformation(Val Text) Export
	
	Return TypeOf(Text) = Type("String") AND StrStartsWith(TrimL(Text), "{");
	
EndFunction

// Text that is displayed in the contact information field when contact information is empty and 
// displayed as a hyperlink.
// 
// Returns:
//  String - a text that is displayed in the contact information field.
//
Function BlankAddressTextAsHyperlink() Export
	Return NStr("ru = 'Заполнить'; en = 'Fill in'; pl = 'Wypełnij wg';de = 'Ausfüllen';ro = 'Completați';tr = 'Doldur'; es_ES = 'Rellenar'");
EndFunction

// Determines whether information is entered in the contact information field when it is displayed as a hyperlink.
//
// Parameters:
//  Value - String - a contact information value.
// 
// Returns:
//  Boolean  - if True, the contact information field is filled in.
//
Function ContactsFilledIn(Value) Export
	Return TrimAll(Value) <> BlankAddressTextAsHyperlink();
EndFunction

#Region ObsoleteProceduresAndFunctions

// Obsolete. Use ContactsManager.ContactInformationPresentation instead
// Generates a presentation with the specified kind for the address input form.
//
// Parameters:
//    AddressStructure  - Structure - an address as a structure.
//                                   See structure details in the AddressManager.AddressInfo function.
//                                   See details of the previous structure version in the AddressManager.PreviousContactInformationXMLStructure function.
//    Presentation    - String    - an address presentation.
//    KindDescription - String - a kind description.
//
// Returns:
//    String - an address presentation with kind.
//
Function GenerateAddressPresentation(AddressStructure, Presentation, KindDescription = Undefined) Export
	
	Presentation = "";
	
	If TypeOf(AddressStructure) <> Type("Structure") Then
		Return Presentation;
	EndIf;
	
	FIASFormat = AddressStructure.Property("County");
	
	If AddressStructure.Property("Country") Then
		Presentation = AddressStructure.Country;
	EndIf;
	
	AddressPresentationByStructure(AddressStructure, "IndexOf", Presentation);
	AddressPresentationByStructure(AddressStructure, "State", Presentation, "StateShortForm", FIASFormat);
	AddressPresentationByStructure(AddressStructure, "County", Presentation, "CountyShortForm", FIASFormat);
	AddressPresentationByStructure(AddressStructure, "District", Presentation, "DistrictShortForm", FIASFormat);
	AddressPresentationByStructure(AddressStructure, "City", Presentation, "CityShortForm", FIASFormat);
	AddressPresentationByStructure(AddressStructure, "CityDistrict", Presentation, "CityDistrictShortForm", FIASFormat);
	AddressPresentationByStructure(AddressStructure, "Locality", Presentation, "LocalityShortForm", FIASFormat);
	AddressPresentationByStructure(AddressStructure, "Territory", Presentation, "TerritoryShortForm", FIASFormat);
	AddressPresentationByStructure(AddressStructure, "Street", Presentation, "StreetShortForm", FIASFormat);
	AddressPresentationByStructure(AddressStructure, "AdditionalTerritory", Presentation, "AdditionalTerritoryShortForm", FIASFormat);
	AddressPresentationByStructure(AddressStructure, "AdditionalTerritoryItem", Presentation, "AdditionalTerritoryItemShortForm", FIASFormat);
	
	If AddressStructure.Property("Building") Then
		SupplementAddressPresentation(TrimAll(ValueByStructureKey("Number", AddressStructure.Building)), ", " + ValueByStructureKey("BuildingType", AddressStructure.Building) + " ", Presentation);
	Else
		SupplementAddressPresentation(TrimAll(ValueByStructureKey("House", AddressStructure)), ", " + ValueByStructureKey("HouseType", AddressStructure) + " ", Presentation);
	EndIf;
	
	If AddressStructure.Property("BuildingUnits") Then
		For each BuildingUnit In AddressStructure.BuildingUnits Do
			SupplementAddressPresentation(TrimAll(ValueByStructureKey("Number", BuildingUnit )), ", " + ValueByStructureKey("BuildingUnitType", BuildingUnit)+ " ", Presentation);
		EndDo;
	Else
		SupplementAddressPresentation(TrimAll(ValueByStructureKey("BuildingUnit", AddressStructure)), ", " + ValueByStructureKey("BuildingUnitType", AddressStructure)+ " ", Presentation);
	EndIf;
	
	If AddressStructure.Property("Premises") Then
		For each Premise In AddressStructure.Premises Do
			SupplementAddressPresentation(TrimAll(ValueByStructureKey("Number", Premise)), ", " + ValueByStructureKey("PremiseType", Premise)+ " ", Presentation);
		EndDo;
	Else
		SupplementAddressPresentation(TrimAll(ValueByStructureKey("Apartment", AddressStructure)), ", " + ValueByStructureKey("ApartmentType", AddressStructure) + " ", Presentation);
	EndIf;
	
	KindDescription = ValueByStructureKey("KindDescription", AddressStructure);
	PresentationWithKind = KindDescription + ": " + Presentation;
	
	Return PresentationWithKind;
	
EndFunction

// Obsolete. To get an address, use AddressManager.AddressInfo instead. To get a phone or fax 
// structure, use ContactsManager.PhoneInfo instead.
// Returns contact information structure by type.
//
// Parameters:
//  CIType - EnumRef.ContactInformationTypes - a contact information type.
//  AddressFormat - String - not used, left for backward compatibility.
// 
// Returns:
//  Structure - a blank contact information structure, keys - field names and field values.
//
Function ContactInformationStructureByType(CIType, AddressFormat = Undefined) Export
	
	If CIType = PredefinedValue("Enum.ContactInformationTypes.Address") Then
		Return AddressFieldsStructure();
	ElsIf CIType = PredefinedValue("Enum.ContactInformationTypes.Phone") Then
		Return PhoneFieldStructure();
	Else
		Return New Structure;
	EndIf;
	
EndFunction

#EndRegion

#EndRegion

#Region Internal

// Details of contact information keys for storing its values in the JSON format.
// The keys list can be extended with fields in the same-name function of the AddressManagerClientServer common module.
//
// Parameters:
//  ContactInformationType  - EmunRef.ContactInformationTypes - a contact information type that 
//                             determines a composition of contact information fields.
//
// Returns:
//   Structure - contact information fields:
//     * Value - String - a contact information presentation.
//     * Comment - String - a comment.
//     * Type - String - a contact information type. See the value in Enum.ContactInformationTypes.Address.
//     Extended composition of fields for contact information type "Address":
//     * Country - String - a country name, for example, Russia.
//     * CountryCode - String - a country code.
//     * PostalCode- String - a postal code.
//     * Area - String - a state name.
//     * AreaType - String - a short form (type) of "state."
//     * City - String - a city name.
//     * CityType - String - a short form (type) of "city", for example, c.
//     * Street - String - a street name.
//     * StreetType - String - a short form (type) of "street", for example, st.
//     Extended composition of fields for contact information type "Phone":
//     * CountryCode - String - a country code.
//     * AreaCode - String - a state code.
//     * Number - String - a phone number.
//     * ExtNumber - String - an extension.
//
Function NewContactInformationDetails(Val ContactInformationType) Export
	
	If TypeOf(ContactInformationType) <> Type("EnumRef.ContactInformationTypes") Then
		ContactInformationType = "";
	EndIf;
	
	Result = New Structure;
	
	Result.Insert("Value",   "");
	Result.Insert("comment", "");
	Result.Insert("Type",    ContactInformationTypeToString(ContactInformationType));
	
	If ContactInformationType = PredefinedValue("Enum.ContactInformationTypes.Address") Then
		
		Result.Insert("country",     "");
		Result.Insert("addressType", AddressInFreeForm());
		Result.Insert("countryCode", "");
		Result.Insert("ZIPcode",     "");
		Result.Insert("area",        "");
		Result.Insert("areaType",    "");
		Result.Insert("city",        "");
		Result.Insert("cityType",    "");
		Result.Insert("street",      "");
		Result.Insert("streetType",  "");
		
	ElsIf ContactInformationType = PredefinedValue("Enum.ContactInformationTypes.Phone")
		Or ContactInformationType = PredefinedValue("Enum.ContactInformationTypes.Fax") Then
		
		Result.Insert("countryCode", "");
		Result.Insert("areaCode", "");
		Result.Insert("Number", "");
		Result.Insert("extNumber", "");
		
	ElsIf ContactInformationType = PredefinedValue("Enum.ContactInformationTypes.WebPage") Then
		
		Result.Insert("name", "");
		
	EndIf;
	
	Return Result;
	
EndFunction

#EndRegion

#Region Private

Function ContactInformationTypeToString(Val ContactInformationType)
	Result = New Map;
	Result.Insert(PredefinedValue("Enum.ContactInformationTypes.Address"), "Address");
	Result.Insert(PredefinedValue("Enum.ContactInformationTypes.Phone"), "Phone");
	Result.Insert(PredefinedValue("Enum.ContactInformationTypes.EmailAddress"), "EmailAddress");
	Result.Insert(PredefinedValue("Enum.ContactInformationTypes.Skype"), "Skype");
	Result.Insert(PredefinedValue("Enum.ContactInformationTypes.WebPage"), "WebPage");
	Result.Insert(PredefinedValue("Enum.ContactInformationTypes.Fax"), "Fax");
	Result.Insert(PredefinedValue("Enum.ContactInformationTypes.Other"), "Other");
	Result.Insert("", "");
	Return Result[ContactInformationType];
EndFunction

Function AddressInFreeForm() Export
	Return "FreeForm";
EndFunction

Function EEUAddress() Export
	Return "EEU";
EndFunction

Function ForeignAddress() Export
	Return "Foreign";
EndFunction

Function IsAddressInFreeForm(AddressType) Export
	Return StrCompare(AddressInFreeForm(), AddressType) = 0;
EndFunction

Function ConstructionOrPremiseValue(Type, Value) Export
	Return New Structure("type, number", Type, Value);
EndFunction

// Returns a blank address structure.
//
// Returns:
//    Structure - address, keys - field names and field values.
//
Function AddressFieldsStructure() Export
	
	AddressStructure = New Structure;
	AddressStructure.Insert("Presentation", "");
	AddressStructure.Insert("Country", "");
	AddressStructure.Insert("CountryDescription", "");
	AddressStructure.Insert("CountryCode","");
	
	Return AddressStructure;
	
EndFunction

#Region PrivateForWorkingWithXMLAddresses

// Returns structure with a description and a short form by value.
//
// Parameters:
//     Text - String - a full description.
//
// Returns:
//     Structure - a processing result.
//         * Description - String - a text part.
//         * ShortForm - String - a text part.
//
Function DescriptionShortForm(Val Text) Export
	Result = New Structure("Description, ShortForm");
	
	Parts = DescriptionsAndShortFormsSet(Text, True);
	If Parts.Count() > 0 Then
		FillPropertyValues(Result, Parts[0]);
	Else
		Result.Description = Text;
	EndIf;
	
	Return Result;
EndFunction

// Splits text into words using the specified separators Default separators are space characters.
//
// Parameters:
//     Text       - String - a string to split.
//     Separators - String - an optional string of separator characters.
//
// Returns:
//     Array - strings and words
//
Function TextWords(Val Text, Val Separators = Undefined)
	
	WordBeginning = 0;
	State   = 0;
	Result   = New Array;
	
	For Position = 1 To StrLen(Text) Do
		CurrentChar = Mid(Text, Position, 1);
		IsSeparator = ?(Separators = Undefined, IsBlankString(CurrentChar), StrFind(Separators, CurrentChar) > 0);
		
		If State = 0 AND (Not IsSeparator) Then
			WordBeginning = Position;
			State   = 1;
		ElsIf State = 1 AND IsSeparator Then
			Result.Add(Mid(Text, WordBeginning, Position-WordBeginning));
			State = 0;
		EndIf;
	EndDo;
	
	If State = 1 Then
		Result.Add(Mid(Text, WordBeginning, Position-WordBeginning));    
	EndIf;
	
	Return Result;
EndFunction

// Splits comma-separated text.
//
// Parameters:
//     Text              - String - a text to separate.
//     ExtractShortForms - Boolean - an optional parameter.
//
// Returns:
//     Array - contains "Description, ShortForm" structures.
//
Function DescriptionsAndShortFormsSet(Val Text, Val ExtractShortForms = True)
	
	Result = New Array;
	For Each Part In TextWords(Text, ",") Do
		PartRow = TrimAll(Part);
		If IsBlankString(PartRow) Then
			Continue;
		EndIf;
		
		Position = ?(ExtractShortForms, StrLen(PartRow), 0);
		While Position > 0 Do
			If Mid(PartRow, Position, 1) = " " Then
				Result.Add(New Structure("Description, ShortForm",
					TrimAll(Left(PartRow, Position-1)), TrimAll(Mid(PartRow, Position))));
				Position = -1;
				Break;
			EndIf;
			Position = Position - 1;
		EndDo;
		If Position = 0 Then
			Result.Add(New Structure("Description, ShortForm", PartRow));
		EndIf;
		
	EndDo;
	
	Return Result;
EndFunction    

#EndRegion

#Region OtherPrivate

// Adds a string to an address presentation.
//
// Parameters:
//    Addition         - String - an address addition.
//    ConcatenationString - String - a concatenation string.
//    Presentation      - String - an address presentation.
//
Procedure SupplementAddressPresentation(Addition, ConcatenationString, Presentation)
	
	If Addition <> "" Then
		Presentation = Presentation + ConcatenationString + Addition;
	EndIf;
	
EndProcedure

// Returns a value string by structure property.
// 
// Parameters:
//    Key - String - a structure key.
//    Structure - Structure - a structure to pass.
//
// Returns:
//    Arbitrary - a value.
//    String       - a blank string if there is no value.
//
Function ValueByStructureKey(varKey, Structure)
	
	Value = Undefined;
	
	If Structure.Property(varKey, Value) Then 
		Return String(Value);
	EndIf;
	
	Return "";
	
EndFunction

Procedure AddressPresentationByStructure(AddressStructure, DescriptionKey, Presentation, ShortFormKey = "", AddShortForms = False, ConcatenationString = ", ")
	
	If AddressStructure.Property(DescriptionKey) Then
		Addition = TrimAll(AddressStructure[DescriptionKey]);
		If ValueIsFilled(Addition) Then
			If AddShortForms AND AddressStructure.Property(ShortFormKey) Then
				Addition = Addition + " " + TrimAll(AddressStructure[ShortFormKey]);
			EndIf;
			If ValueIsFilled(Presentation) Then
				Presentation = Presentation + ConcatenationString + Addition;
			Else
				Presentation = Addition;
			EndIf;
		EndIf;
	EndIf;
EndProcedure

// Returns a blank phone structure.
//
// Returns:
//    Sructure - Keys - field names and field values.
//
Function PhoneFieldStructure() Export
	
	PhoneStructure = New Structure;
	PhoneStructure.Insert("Presentation", "");
	PhoneStructure.Insert("CountryCode", "");
	PhoneStructure.Insert("CityCode", "");
	PhoneStructure.Insert("PhoneNumber", "");
	PhoneStructure.Insert("Extension", "");
	PhoneStructure.Insert("Comment", "");
	
	Return PhoneStructure;
	
EndFunction

Function WebsiteAddress(Val Presentation, Val Ref) Export
	
	If IsBlankString(Presentation) Or IsBlankString(Ref)  Then
		Presentation = BlankAddressTextAsHyperlink();
		Ref = WebsiteURL();
	EndIf;
	
	PresentationText = New FormattedString(Presentation,,,, Ref);
	
	PictureChange = New FormattedString(PictureLib.EditWebsiteAddress,,,, WebsiteURL());
	Return New FormattedString(PresentationText, "  ", PictureChange);

EndFunction

Function WebsiteURL() Export
	Return "e1cib/app/DataProcessor.ContactInformationInput.Form.Website";
EndFunction

#EndRegion

#EndRegion
