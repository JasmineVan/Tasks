///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Internal

// OnOpen form event handler the form input fields to open attribute value input fields in different languages.
//
// Parameters:
//  Object - FormDataCollection - Object on the form.
//  Item - FormField - a form item for which the input form will be opened in different languages.
//  AttributeName - String - an attribute name for which the input form will be opened in different languages.
//  StandardProcessing - Boolean - indicates a standard (system) event processing execution.
//
Procedure OnOpen(Object, Item, AttributeName, StandardProcessing) Export
	
	StandardProcessing = False;
	
	FormParameters = New Structure;
	FormParameters.Insert("Presentations",   Object.Presentations);
	FormParameters.Insert("Ref",          Object.Ref);
	FormParameters.Insert("AttributeName",    AttributeName);
	FormParameters.Insert("CurrentValue", Item.EditText);
	FormParameters.Insert("ReadOnly",  Item.ReadOnly);
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("Object", Object);
	AdditionalParameters.Insert("AttributeName", AttributeName);
	
	Notification = New NotifyDescription("AfterInputStringsInDifferentLanguages", LocalizationClient, AdditionalParameters);
	OpenForm("CommonForm.InputInMultipleLanguages", FormParameters,,,,, Notification);
	
EndProcedure

#EndRegion

#Region Private

Procedure AfterInputStringsInDifferentLanguages(Result, AdditionalParameters) Export
	
	If TypeOf(Result) <> Type("Structure") Then
		Return;
	EndIf;
	
	Object = AdditionalParameters.Object;
	
	For each Presentation In Result.ValuesInDifferentLanguages Do
		Filter = New Structure("LanguageCode", Presentation.LanguageCode);
		FoundRows = Object.Presentations.FindRows(Filter);
		If FoundRows.Count() > 0 Then
			If IsBlankString(Presentation.AttributeValue) 
				AND StrCompare(Result.DefaultLanguage, Presentation.LanguageCode) <> 0 Then
					Object.Presentations.Delete(FoundRows[0]);
				Continue;
			EndIf;
			PresentationsRow = FoundRows[0];
		Else
			PresentationsRow = Object.Presentations.Add();
			PresentationsRow.LanguageCode = Presentation.LanguageCode;
		EndIf;
		PresentationsRow[AdditionalParameters.AttributeName] = Presentation.AttributeValue;
		
	EndDo;
	
	If Result.Property("StringInCurrentLanguage") Then
		Object[AdditionalParameters.AttributeName] = Result.StringInCurrentLanguage;
	EndIf;
	
EndProcedure

#EndRegion
