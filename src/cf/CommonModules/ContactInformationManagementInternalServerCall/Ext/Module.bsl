///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Private

// Parses contact information presentation and returns an XML string containing parsed field values.
//
//  Parameters:
//      Text - String - a contact information presentation.
//      ExpectedType - CatalogRef.ContactInformationKinds, EnumRef.ContactInformationTypes - to 
//                     control types.
//
//  Returns:
//      String - JSON
//
Function ContactsByPresentation(Val Text, Val ExpectedKind) Export
	Return ContactsManager.ContactsByPresentation(Text, ExpectedKind);
EndFunction

// Returns a composition string from a contact information value.
//
//  Parameters:
//      XMLData - String - XML of contact information data.
//
//  Returns:
//      String - content
//      Undefined - if a composition value has a complex type.
//
Function ContactInformationCompositionString(Val XMLData) Export;
	Return ContactsManagerInternal.ContactInformationCompositionString(XMLData);
EndFunction

// Converts all incoming contact information formats to XML.
//
Function TransformContactInformationXML(Val Data) Export
	Return ContactsManagerInternal.TransformContactInformationXML(Data);
EndFunction

// Returns the found reference or creates a new country record and returns a reference to it.
//
Function WorldCountryByClassifierData(Val CountryCode) Export
	
	Return ContactsManager.WorldCountryByCodeOrDescription(CountryCode);
	
EndFunction

// Fills in a collection with references to found or created country records.
//
Procedure WorldCountriesCollectionByClassifierData(Collection) Export
	
	For Each KeyValue In Collection Do
		Collection[KeyValue.Key] =  ContactsManager.WorldCountryByCodeOrDescription(KeyValue.Value.Code);
	EndDo;
	
EndProcedure

// Fills in the list of address options upon automatic completion by the text entered by the user.
//
Procedure AddressAutoComplete(Val Text, ChoiceData) Export
	
	ContactsManagerInternal.AddressAutoComplete(Text, ChoiceData);
	
EndProcedure

#EndRegion
