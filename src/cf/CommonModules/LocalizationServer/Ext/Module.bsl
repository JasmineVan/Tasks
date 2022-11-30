///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Internal

// Returns metadata by the configuration language code.
//
// Parameters:
//   LanguageCode - String - a language code, for example "en" (as it is set in LanguageCode property of metadata MetadataObject: Language).
//
// Returns:
//   MetadataObject: Language - if it is found by the passed language code, otherwise Undefined.
//   
Function LanguageByCode(Val LanguageCode) Export
	For each Language In Metadata.Languages Do
		If Language.LanguageCode = LanguageCode Then
			Return Language;
		EndIf;	
	EndDo;
	Return Undefined;
EndFunction	

// It is called from the OnCreateAtServer object form handler to display the open button for 
// localized items. When pushing this button, the attribute value input form in different languages is opened.
//
// Parameters:
//  LocalizedFormItems - InputField, Array - form items where it is required to output the open button.
//
Procedure OnCreateAtServer(LocalizedFormItems) Export
	
	If Metadata.Languages.Count() < 2 Then
		Return;
	EndIf;
	
	If TypeOf(LocalizedFormItems) = Type("Array") Then
		For each LocalizedItem In LocalizedFormItems Do
			LocalizedItem.OpenButton = True;
		EndDo;
	Else
		LocalizedFormItems.OpenButton = True;
	EndIf;
	
EndProcedure

// It is called from the OnReadAtSerevr object form handler to fill in the form attribute values 
// depending on the language that is used when the user is working.
//
// Parameters:
//  Form         - ManagedForm - an object form.
//  CurrentObject - Arbitrary - an object received in OnReadAtServer form handler.
//
Procedure OnReadAtServer(Form, CurrentObject) Export
	
	CurrentObject.OnReadPresentationsAtServer();
	Form.ValueToFormAttribute(CurrentObject, "Object");
	
EndProcedure

// It is called from the object module to set values of localized object attributes depending on the 
// language that is used when the user is working.
//
// Parameters:
//  Object - Arbitrary - a data object.
//
Procedure OnReadPresentationsAtServer(Object) Export
	
	If CurrentLanguage() = Metadata.DefaultLanguage Then
		Return;
	EndIf;
	
	For each Attribute In Object.Metadata().TabularSections.Presentations.Attributes Do
		
		If StrCompare(Attribute.Name, "LanguageCode") = 0 Then
			Continue;
		EndIf;
		
		AttributeName = Attribute.Name;
		
		Filter = New Structure();
		Filter.Insert("LanguageCode", Metadata.DefaultLanguage.LanguageCode);
		FoundRows = Object.Presentations.FindRows(Filter);
	
		If FoundRows.Count() > 0 Then
			Presentation = FoundRows[0];
		Else
			Presentation = Object.Presentations.Add();
			Presentation.LanguageCode = Metadata.DefaultLanguage.LanguageCode;
		EndIf;
		Presentation[AttributeName] = Object[AttributeName];
		
		Filter = New Structure();
		Filter.Insert("LanguageCode", CurrentLanguage().LanguageCode);
		FoundRows = Object.Presentations.FindRows(Filter);
		
		If FoundRows.Count() > 0 AND ValueIsFilled(FoundRows[0][AttributeName]) Then
			Object[AttributeName] = FoundRows[0][AttributeName];
		EndIf;
		
	EndDo;
	
EndProcedure

// It is called from the BeforeWriteAtServer object form or while the application object recording 
// to set values of form attributes depending on the language that is used when the user is working.
//
// Parameters:
//  CurrentObject - Arbitrary - object to be written.
//
Procedure BeforeWriteAtServer(CurrentObject) Export
	
	If CurrentLanguage() = Metadata.DefaultLanguage Then
		Return;
	EndIf;
	
	Attributes = New Array;
	For each Attribute In CurrentObject.Ref.Metadata().TabularSections.Presentations.Attributes Do
		If StrCompare(Attribute.Name, "LanguageCode") = 0 Then
			Continue;
		EndIf;
		
		Attributes.Add(Attribute.Name);
	EndDo;
	
	Filter = New Structure();
	Filter.Insert("LanguageCode", CurrentLanguage().LanguageCode);
	FoundRows = CurrentObject.Presentations.FindRows(Filter);
	
	If FoundRows.Count() > 0 Then
		Presentation = FoundRows[0];
	Else
		Presentation = CurrentObject.Presentations.Add();
		Presentation.LanguageCode = CurrentLanguage().LanguageCode;
	EndIf;
	
	For each AttributeName In Attributes Do
		Presentation[AttributeName] = CurrentObject[AttributeName];
	EndDo;
	
	Filter.LanguageCode = Metadata.DefaultLanguage.LanguageCode;
	FoundRows = CurrentObject.Presentations.FindRows(Filter);
	If FoundRows.Count() > 0 Then
		For each AttributeName In Attributes Do
			CurrentObject[AttributeName] = FoundRows[0][AttributeName];
		EndDo;
		CurrentObject.Presentations.Delete(FoundRows[0]);
	EndIf;
	
	CurrentObject.Presentations.GroupBy("LanguageCode", StrConcat(Attributes, ","));
	
EndProcedure

#EndRegion