///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Private

// Determines the availability of the AddressClassifier subsystem and the availability of records about states in the
// AddressObjects information register.
//
// Returns:
//  FixedMap - with the following fields:
//   * ClassifierAvailable   - Boolean - the classifier is available over a web service.
//   * UseImportedItems - Boolean - shows whether a classifier is imported to the application.
//
Function AddressClassifierAvailabilityInfo() Export
	
	Result = New Structure;
	Result.Insert("ClassifierAvailable",   False);
	Result.Insert("UseImportedItems", False);
	
	ClassifierPresent = Common.SubsystemExists("StandardSubsystems.AddressClassifier");
	If Not ClassifierPresent Then
		Return Result;
	EndIf;
	
	ModuleAddressClassifierInternal = Common.CommonModule("AddressClassifierInternal");
	AddressInfoAvailabilityInfo = ModuleAddressClassifierInternal.AddressInfoAvailabilityInfo();
	
	Return AddressInfoAvailabilityInfo;
	
EndFunction

// Returns an enumeration value of contact information kind type.
//
//  Parameters:
//    InformationKind - CatalogRef.ContactInformationKinds, Structure - a data source.
//
Function ContactInformationKindType(Val InformationKind) Export
	Result = Undefined;
	
	Type = TypeOf(InformationKind);
	If Type = Type("EnumRef.ContactInformationTypes") Then
		Result = InformationKind;
	ElsIf Type = Type("CatalogRef.ContactInformationKinds") Then
		Result = Common.ObjectAttributeValue(InformationKind, "Type");
	ElsIf InformationKind <> Undefined Then
		Data = New Structure("Type");
		FillPropertyValues(Data, InformationKind);
		Result = Data.Type;
	EndIf;
	
	Return Result;
EndFunction

Function ContactInformationKindsDescriptions() Export
	
	Result = New Map;
	For each Language In Metadata.Languages Do
		Descriptions = New Map;
		ContactInformationManagementOverridable.OnGetContactInformationKindsDescriptions(Descriptions, Language.LanguageCode);
		Result[Language.LanguageCode] = Descriptions;
	EndDo;
	
	Return New FixedMap(Result);
	
EndFunction

// Returns a list of predefined contact information kinds.
//
// Returns:
//  FixedMap - with the following fields:
//   * Key - String - a predefined kind name.
//   * Value - CatalogRef.ContactInformationKinds - a reference to an item of the ContactInformationKinds catalog.
Function ContactInformationKindsByName() Export
	
	Kinds = New Map;
	PredefinedKinds = ContactsManager.PredefinedContactInformationKinds();
	
	For each PredefinedKind In PredefinedKinds Do
		Kinds.Insert(PredefinedKind.Name, PredefinedKind.Ref);
	EndDo;
	
	Return New FixedMap(Kinds);
	
EndFunction


#EndRegion
