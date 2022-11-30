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
	
	If ReportForm.ReportSettings.FullName <> "Report.AccountingCheckResults" Then
		Return;
	EndIf;
		
	Details = Area.Details;
	If TypeOf(Details) = Type("Structure") Then
		
		StandardProcessing = False;
		If Details.Property("Purpose") Then
			If Details.Purpose = "FixIssues" Then
				ResolveIssue(ReportForm, Details);
			ElsIf Details.Purpose = "OpenListForm" Then
				OpenProblemList(ReportForm, Details);
			EndIf;
		EndIf;
		
	EndIf;
		
EndProcedure

// Opens a report form with a filter by issues that impede the normal update of the infobase.
// 
//
//  Parameters:
//     Form                - ManagedForm - a managed form of a problem object.
//     StandardProcessing - Boolean - a flag indicating whether the standard (system) event 
//                            processing is executed is passed to this parameter.
//
// Example:
//    ModuleAccountingAuditInternalClient.OpenIssuesReportFromUpdateProcessing(ThisObject, StandardProcessing);
//
Procedure OpenIssuesReportFromUpdateProcessing(Form, StandardProcessing) Export
	
	StandardProcessing = False;
	OpenIssuesReport("SystemChecks");
	
EndProcedure

// See AccountingAuditClient.OpenIssuesReport 
Procedure OpenIssuesReport(ChecksKind) Export
	
	FormParameters = New Structure;
	FormParameters.Insert("CheckKind", ChecksKind);
	
	OpenForm("Report.AccountingCheckResults.Form", FormParameters);
	
EndProcedure

#EndRegion

#Region Private

// Opens a form for interactive user actions to resolve an issue.
//
// Parameters:
//   Form       - ManagedForm - the AccountingAuditResult report form.
//   Details - Structure - additional information to correct an issue:
//      * Purpose - String - a string ID of the details purpose.
//      * CheckID          - String - a string check ID.
//      * GoToCorrectionHandler - String - a name of the export client procedure handler for 
//                                                   correcting an issue or a full name of the form being opened.
//      * CheckKind                    - CatalogRef.ChecksKinds - a check kind that narrows the area 
//                                         of issue correction.
//
Procedure ResolveIssue(Form, Details)
	
	PatchParameters = New Structure;
	PatchParameters.Insert("CheckID", Details.CheckID);
	PatchParameters.Insert("CheckKind",           Details.CheckKind);
	
	GoToCorrectionHandler = Details.GoToCorrectionHandler;
	If StrStartsWith(GoToCorrectionHandler, "CommonForm.") Or StrFind(GoToCorrectionHandler, ".Form") > 0 Then
		OpenForm(GoToCorrectionHandler, PatchParameters, Form);
	Else
		CorrectionHandler = StringFunctionsClientServer.SplitStringIntoSubstringsArray(GoToCorrectionHandler, ".");
		
		ModuleCorrectionHandler  = CommonClient.CommonModule(CorrectionHandler[0]);
		ProcedureName = CorrectionHandler[1];
		
		ExecuteNotifyProcessing(New NotifyDescription(ProcedureName, ModuleCorrectionHandler), PatchParameters);
	EndIf;
	
EndProcedure

// Opens a list form (in case of a register - with the problem record set).
//
// Parameters:
//   Form                          - ManagedForm - a report form.
//   Details - Structure - the structure containing the data for correcting the issue of the cell of 
//                 the report on the details of accounting check results.
//      * Purpose         - String - a purpose string ID of the decryption.
//      * FullObjectName   - String - a full metadata object name.
//      * Filter              - Structure - a filter as a list.
//
Procedure OpenProblemList(Form, Details)
	
	UserSettings = New DataCompositionUserSettings;
	CompositionFilter           = UserSettings.Items.Add(Type("DataCompositionFilter"));
	
	RegisterForm = GetForm(Details.FullObjectName + ".ListForm", , Form);
	
	For Each SetFilterItem In Details.Filter Do
		
		FilterItem                = CompositionFilter.Items.Add(Type("DataCompositionFilterItem"));
		FilterItem.LeftValue  = New DataCompositionField(SetFilterItem.Key);
		FilterItem.RightValue = SetFilterItem.Value;
		FilterItem.ComparisonType   = DataCompositionComparisonType.Equal;
		FilterItem.Use  = True;
		
		FilterParameters = New Structure;
		FilterParameters.Insert("Field",          SetFilterItem.Key);
		FilterParameters.Insert("Value",      SetFilterItem.Value);
		FilterParameters.Insert("ComparisonType",  DataCompositionComparisonType.Equal);
		FilterParameters.Insert("Use", True);
		
		AdditionalParameters = New Structure;
		AdditionalParameters.Insert("ToUserSettings", True);
		AdditionalParameters.Insert("ReplaceCurrent",       True);
		
		AddFilter(RegisterForm.List.SettingsComposer, FilterParameters, AdditionalParameters);
		
	EndDo;
	
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