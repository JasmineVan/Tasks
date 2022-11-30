///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Internal

// The function is called when receiving object or reference presentation depending on the language 
// that is used when the user is working.
//
// Parameters:
//  Data - Structure - contains the values of the fields from which presentation is generated.
//  Presentation        - String - formed presentation must be put in this parameter.
//  StandardProcessing - Boolean - a flag indicates whether the standard presentation is formed in this parameter.
//  AttributeName         - String - indicates in what attribute the presentation in the main language is stored.
//
Procedure PresentationGetProcessing(Data, Presentation, StandardProcessing, AttributeName = "Description") Export
	
	#If Server Or ThickClientOrdinaryApplication Or ThickClientManagedApplication Or ExternalConnection Then
		
	If CurrentLanguage() = Metadata.DefaultLanguage Or Not Data.Property("Ref") Or Data.Ref = Undefined Then
		Return;
	EndIf;
	
	QueryText = 
		"SELECT TOP 1
		|	Presentations.%2 AS Description
		|FROM
		|	%1.Presentations AS Presentations
		|WHERE
		|	Presentations.LanguageCode = &Language
		|	AND Presentations.Ref = &Ref";
	
	QueryText = StringFunctionsClientServer.SubstituteParametersToString(QueryText,
		Data.Ref.Metadata().FullName(), AttributeName);
		
	Query = New Query(QueryText);
	
	Query.SetParameter("Ref", Data.Ref);
	Query.SetParameter("Language",   CurrentLanguage().LanguageCode);
	
	QueryResult = Query.Execute();
	If Not QueryResult.IsEmpty() Then
		StandardProcessing = False;
		Presentation = QueryResult.Unload()[0].Description;
	EndIf;
	
#EndIf
	
EndProcedure

#EndRegion