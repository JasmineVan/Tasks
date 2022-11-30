///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Private

// Opens an additional report form with the specified report option.
//
// Parameters:
//  Ref - CatalogRef.AdditionalReportsAndDataProcessors - an additional report reference.
//  OptionKey - String - a name of the additional report option.
//
Procedure OnAttachReport(OpeningParameters) Export
	ReportsOptions.OnAttachReport(OpeningParameters);
EndProcedure

// Gets an account extra dimension type by its number.
//
// Parameters:
//  Account - ChartOfAccountsRef - an account reference.
//  ExtDimensionNumber - Number - an extra dimension number.
//
// Returns:
//   TypesDetails - ExtDimension type.
//   Undefined - the flag that indicates whether extra dimension type cannot be received (there is no such extra dimension or no rights).
//
Function ExtDimensionType(Account, ExtDimensionNumber) Export
	If Account = Undefined Then 
		Return Undefined;
	EndIf;
	
	MetadataObject = Account.Metadata();
	If Not Metadata.ChartsOfAccounts.Contains(MetadataObject) Then
		Return Undefined;
	EndIf;
	Query = New Query;
	Query.SetParameter("Ref", Account);
	Query.SetParameter("LineNumber", ExtDimensionNumber);
	Query.Text = "
	|SELECT ALLOWED
	|	ChartOfAccountsExtDimensionTypes.ExtDimensionType.ValueType AS Type
	|FROM
	|	&FullTableName AS ChartOfAccountsExtDimensionTypes
	|WHERE
	|	ChartOfAccountsExtDimensionTypes.Ref = &Ref
	|	AND ChartOfAccountsExtDimensionTypes.LineNumber = &LineNumber";
	Query.Text = StrReplace(Query.Text, "&FullTableName", MetadataObject.FullName() + ".ExtDimensionTypes");
	Selection = Query.Execute().Select();
	If Not Selection.Next() Then
		Return Undefined;
	EndIf;
	Return Selection.Type;
EndFunction

#EndRegion
