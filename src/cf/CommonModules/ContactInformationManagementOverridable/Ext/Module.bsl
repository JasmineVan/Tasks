///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Public

// Gets descriptions of contact information kinds in different languages.
//
// Parameters:
//  Description - Map - a presentation of a contact information kind in the passed language:
//     * Key     - String - a name of a contact information kind. For example, _DemoPartnerAddress.
//     * Value - String - a description of a contact information kind for the passed language code.
//  LanguageCode - String - a language code. For example, "en".
//
// Example:
//  Descriptions["_DemoPartnerAddress"] = NStr("ru='Адрес'; en='Address';", LanguageCode);
//
Procedure OnGetContactInformationKindsDescriptions(Descriptions, LanguageCode) Export
	
	
	
EndProcedure

#EndRegion
