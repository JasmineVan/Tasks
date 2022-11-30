///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure FormGetProcessing(FormType, Parameters, SelectedForm, AdditionalInfo, StandardProcessing)
	
	#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then
		
		If Parameters <> Undefined AND Parameters.Property("OpenByScenario") Then
			StandardProcessing = False;
			InformationKind = Parameters.ContactInformationKind;
			SelectedForm = ContactInformationInputFormName(InformationKind);
			
			If SelectedForm = Undefined Then
				Raise NStr("ru = 'Not processed type addresses: """ + InformationKind + """'");
			EndIf;
		EndIf;
		
	#EndIf
	
EndProcedure

#EndRegion

#Region Private

// Returns a name of the form used to edit contact information type.
//
// Parameters:
//      InformationKind - EnumRef.ContactInformationTypes, CatalogRef.ContactInformationKinds - a 
//                      requested type.
//
// Returns:
//      String - a full name of the form.
//
Function ContactInformationInputFormName(Val InformationKind)
	
	InformationType = ContactInformationManagementInternalCached.ContactInformationKindType(InformationKind);
	
	AllTypes = "Enum.ContactInformationTypes.";
	If InformationType = PredefinedValue(AllTypes + "Address") Then
		
		If Metadata.DataProcessors.Find("AdvancedContactInformationInput") = Undefined Then
			Return "DataProcessor.ContactInformationInput.Form.FreeFormAddressInput";
		Else
			Return "DataProcessor.AdvancedContactInformationInput.Form.AddressInput";
		EndIf;
		
	ElsIf InformationType = PredefinedValue(AllTypes + "Phone") Then
		Return "DataProcessor.ContactInformationInput.Form.PhoneInput";
		
	ElsIf InformationType = PredefinedValue(AllTypes + "WebPage") Then
		Return "DataProcessor.ContactInformationInput.Form.Website";
		
	ElsIf InformationType = PredefinedValue(AllTypes + "Fax") Then
		Return "DataProcessor.ContactInformationInput.Form.PhoneInput";
		
	EndIf;
	
	Return Undefined;
	
EndFunction

#EndRegion

#EndIf


