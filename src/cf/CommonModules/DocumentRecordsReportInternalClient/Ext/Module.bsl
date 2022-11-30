///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Internal

// Handler for double click, clicking Enter, or a hyperlink in a report form spreadsheet document.
// See "Form field extension for a spreadsheet document field.Choice" in Syntax Assistant.
//
// Parameters:
//   ReportForm          - ManagedForm - a report form.
//   Item              - FormField        - a spreadsheet document.
//   Area              - SpreadsheetDocumentCellsArea - a selected value.
//   StandardProcessing - Boolean - indicates that event is processed in a standard way.
//
Procedure SpreadsheetDocumentSelectionHandler(ReportForm, Item, Area, StandardProcessing) Export
	
	If ReportForm.ReportSettings.FullName = "Report.DocumentRegisterRecords" Then
		
		If Area.AreaType = SpreadsheetDocumentCellAreaType.Rectangle
			AND TypeOf(Area.Details) = Type("Structure") Then
			OpenRegisterFormFromRecordsReport(ReportForm, Area.Details, StandardProcessing);
		EndIf;
		
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

// Open the register form with filter by recorder
//
// Parameters:
//   ReportForm – ManagedForm - a report form.
//   Details - Structure - a structure with properties.
//      * RegisterKind - contains the Accumulations, Info, Accounting or Settlement registers.
//      * RegisterName - contains a name of a register as metadata object.
//      * Recorder - contains a reference to a document recorder for which you need to make a filter 
//                      in the opened register form.
//   StandardProcessing - Boolean - a flag of standard (system) event processing execution.
//
Procedure OpenRegisterFormFromRecordsReport(ReportForm, Details, StandardProcessing)

	StandardProcessing = False;
	
	UserSettings    = New DataCompositionUserSettings;
	Filter                        = UserSettings.Items.Add(Type("DataCompositionFilter"));
	FilterItem                = Filter.Items.Add(Type("DataCompositionFilterItem"));
	FilterItem.LeftValue  = New DataCompositionField(Details.RecorderFieldName);
	FilterItem.RightValue = Details.Recorder;
	FilterItem.ComparisonType   = DataCompositionComparisonType.Equal;
	FilterItem.Use  = True;
	
	RegisterFormName = StringFunctionsClientServer.SubstituteParametersToString("Register%1.%2.ListForm",
		Details.RegisterType, Details.RegisterName);
	
	RegisterForm = GetForm(RegisterFormName);
	
	FilterParameters = New Structure;
	FilterParameters.Insert("Field",          Details.RecorderFieldName);
	FilterParameters.Insert("Value",      Details.Recorder);
	FilterParameters.Insert("ComparisonType",  DataCompositionComparisonType.Equal);
	FilterParameters.Insert("Use", True);
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("ToUserSettings", True);
	AdditionalParameters.Insert("ReplaceCurrent",       True);
	
	AddFilter(RegisterForm.List.SettingsComposer, FilterParameters, AdditionalParameters);
	
	RegisterForm.Open();
	
EndProcedure

// Adds a filter to the collection of the composer filters or group of selections
//
// Parameters:
//   StructureItem        - DataCompositionSettingsComposer, DataCompositionSettings - a data composition structure item.
//   FilterParameters         - Structure - it contains  data composition filter parameters.
//     * Field                - String - a field name, by which a filter is added.
//     * Value            - Arbitrary - a filter value of data composition (Undefined by default).
//     * ComparisonType        - DataCompositionComparisonType - a comparison type of data composition (Undefined by default).
//     * Usage       - Boolean - indicates that filter is used (True by default).
//   AdditionalParameters - Structure - contains additional parameters, listed below:
//     * ToUserSettings - Boolean - a flag of adding to data composition user settings (False by default).
//     * ReplaceExistingItem       - Boolean - a flag of complete replacement of existing filter by field (True by default).
//
// Returns:
//   DataCompositionFilterItem - an added filter.
//
Function AddFilter(StructureItem, FilterParameters, AdditionalParameters = Undefined)
	
	If AdditionalParameters = Undefined Then
		AdditionalParameters = New Structure;
		AdditionalParameters.Insert("ToUserSettings", False);
		AdditionalParameters.Insert("ReplaceCurrent",       True);
	Else
		If Not AdditionalParameters.Property("ToUserSettings") Then
			AdditionalParameters.Insert("ToUserSettings", False);
		EndIf;
		If Not AdditionalParameters.Property("ReplaceCurrent") Then
			AdditionalParameters.Insert("ReplaceCurrent", True);
		EndIf;
	EndIf;
	
	If TypeOf(FilterParameters.Field) = Type("String") Then
		NewField = New DataCompositionField(FilterParameters.Field);
	Else
		NewField = FilterParameters.Field;
	EndIf;
	
	If TypeOf(StructureItem) = Type("DataCompositionSettingsComposer") Then
		Filter = StructureItem.Settings.Filter;
		
		If AdditionalParameters.ToUserSettings Then
			For Each SettingItem In StructureItem.UserSettings.Items Do
				If SettingItem.UserSettingID =
					StructureItem.Settings.Filter.UserSettingID Then
					Filter = SettingItem;
				EndIf;
			EndDo;
		EndIf;
	
	ElsIf TypeOf(StructureItem) = Type("DataCompositionSettings") Then
		Filter = StructureItem.Filter;
	Else
		Filter = StructureItem;
	EndIf;
	
	FilterItem = Undefined;
	If AdditionalParameters.ReplaceCurrent Then
		For each Item In Filter.Items Do
	
			If TypeOf(Item) = Type("DataCompositionFilterItemGroup") Then
				Continue;
			EndIf;
	
			If Item.LeftValue = NewField Then
				FilterItem = Item;
			EndIf;
	
		EndDo;
	EndIf;
	
	If FilterItem = Undefined Then
		FilterItem = Filter.Items.Add(Type("DataCompositionFilterItem"));
	EndIf;
	FilterItem.Use  = FilterParameters.Use;
	FilterItem.LeftValue  = NewField;
	FilterItem.ComparisonType   = ?(FilterParameters.ComparisonType = Undefined, DataCompositionComparisonType.Equal,
		FilterParameters.ComparisonType);
	FilterItem.RightValue = FilterParameters.Value;
	
	Return FilterItem;
	
EndFunction

#EndRegion