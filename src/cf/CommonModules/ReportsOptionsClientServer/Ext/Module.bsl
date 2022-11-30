///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Public

// ID that is used for the home page in the ReportsOptionsOverridable module.
//
// Returns:
//   String - an ID that is used for the home page in the ReportsOptionsOverridable module.
//
Function HomePageID() Export
	
	Return "Subsystems";
	
EndFunction

#EndRegion

#Region Internal

// Adds Key to Structure if it is missing.
//
// Parameters:
//   Structure - Structure    - a structure to be complemented.
//   Key      - String       - a property name.
//   Value  - Arbitrary - optional. Property value if it is missing in the structure.
//
Procedure AddKeyToStructure(Structure, varKey, Value = Undefined) Export
	If Not Structure.Property(varKey) Then
		Structure.Insert(varKey, Value);
	EndIf;
EndProcedure

#EndRegion

#Region Private

// Full subsystem name.
Function FullSubsystemName() Export
	Return "StandardSubsystems.ReportsOptions";
EndFunction

// Converts a search string to an array of words with unique values sorted by length descending.
Function ParseSearchStringIntoWordArray(SearchString) Export
	WordsAndTheirLength = New ValueList;
	StringLength = StrLen(SearchString);
	
	Word = "";
	WordLength = 0;
	QuotationMarkOpened = False;
	For CharNumber = 1 To StringLength Do
		CharCode = CharCode(SearchString, CharNumber);
		If CharCode = 34 Then // 34 - a double quotation mark (").
			QuotationMarkOpened = Not QuotationMarkOpened;
		ElsIf QuotationMarkOpened
			Or (CharCode >= 48 AND CharCode <= 57) // numbers
			Or (CharCode >= 65 AND CharCode <= 90) // Uppercase Latin characters
			Or (CharCode >= 97 AND CharCode <= 122) // Lowercase Latin characters
			Or (CharCode >= 1040 AND CharCode <= 1103) // Cyrillic characters
			Or CharCode = 95 Then // "_" character
			Word = Word + Char(CharCode);
			WordLength = WordLength + 1;
		ElsIf Word <> "" Then
			If WordsAndTheirLength.FindByValue(Word) = Undefined Then
				WordsAndTheirLength.Add(Word, Format(WordLength, "ND=3; NLZ="));
			EndIf;
			Word = "";
			WordLength = 0;
		EndIf;
	EndDo;
	
	If Word <> "" AND WordsAndTheirLength.FindByValue(Word) = Undefined Then
		WordsAndTheirLength.Add(Word, Format(WordLength, "ND=3; NLZ="));
	EndIf;
	
	WordsAndTheirLength.SortByPresentation(SortDirection.Desc);
	
	Return WordsAndTheirLength.UnloadValues();
EndFunction

// The function converts a report type into a string ID.
Function ReportByStringType(Val ReportType, Val Report = Undefined) Export
	TypeOfReportType = TypeOf(ReportType);
	If TypeOfReportType = Type("String") Then
		Return ReportType;
	ElsIf TypeOfReportType = Type("EnumRef.ReportTypes") Then
		If ReportType = PredefinedValue("Enum.ReportTypes.Internal") Then
			Return "Internal";
		ElsIf ReportType = PredefinedValue("Enum.ReportTypes.Extension") Then
			Return "Extension";
		ElsIf ReportType = PredefinedValue("Enum.ReportTypes.Additional") Then
			Return "Additional";
		ElsIf ReportType = PredefinedValue("Enum.ReportTypes.External") Then
			Return "External";
		Else
			Return Undefined;
		EndIf;
	Else
		If TypeOfReportType <> Type("Type") Then
			ReportType = TypeOf(Report);
		EndIf;
		If ReportType = Type("CatalogRef.MetadataObjectIDs") Then
			Return "Internal";
		ElsIf ReportType = Type("CatalogRef.ExtensionObjectIDs") Then
			Return "Extension";
		ElsIf ReportType = Type("String") Then
			Return "External";
		Else
			Return "Additional";
		EndIf;
	EndIf;
EndFunction

#EndRegion
