///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Public

////////////////////////////////////////////////////////////////////////////////
// Procedures and functions to perform accounting checks and get their results.

// Executes the indicated accounting check with the specified parameters.
//
// Parameters:
//   Check                   -  CatalogRef.AccountingCheckRules, String - a rule of a check that 
//                                 will be executed or a string ID of the specified rule.
//   CheckExecutionParameters - Structure, Array - arbitrary additional check parameters that 
//                                 clarify what and how exactly to check.
//                                 See AccountingAudit.CheckExecutionParameters. 
//     - Structure - one execution parameter:
//       * Property1 - AnyRef, Boolean, Number, String, Date - the first parameter value.
//       * Property2 - AnyRef, Boolean, Number, String, Date - the second parameter value.
//       * Property3 - AnyRef, Boolean, Number, String, Date - the third parameter value.
//       ...                                              
//     - Array - several check parameters (array elements of the Structure type, as described above).
//
// Example:
//   1. Check = AccountingAudit.CheckByID("CheckRefIntegrity");
//      AccountingAudit.RunCheck(Check);
//   2. CheckExecutionParameters = New Array;
//      Parameter1 = AccountingAudit.CheckExecutionParameters("MonthEndClosing", Company1, MonthToClose);
//      CheckExecutionParameters(Parameter1);
//      Parameter2 = AccountingAudit.CheckExecutionParameters("MonthEndClosing", Company2, MonthToClose);
//      CheckExecutionParameters.Add(Parameter2);
//      RunCheck("CheckDocumentsPosting", CheckExecutionParameters);
//
Procedure ExecuteCheck(Val CheckSSL, Val CheckExecutionParameters = Undefined) Export
	
	If TypeOf(CheckSSL) = Type("String") Then
		CheckToExecute = CheckByID(CheckSSL);
		If CheckToExecute.IsEmpty() Then
			Raise StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'Проверка ведения учета с идентификатором ""%1"" не существует (см. КонтрольВеденияУчетаПереопределяемый.ПриОпределенииПроверок)'; en = 'The accounting check with ID %1 does not exist (see AccountingAuditOverridable.OnDefineChecks).'; pl = 'The accounting check with ID %1 does not exist (see AccountingAuditOverridable.OnDefineChecks).';de = 'The accounting check with ID %1 does not exist (see AccountingAuditOverridable.OnDefineChecks).';ro = 'The accounting check with ID %1 does not exist (see AccountingAuditOverridable.OnDefineChecks).';tr = 'The accounting check with ID %1 does not exist (see AccountingAuditOverridable.OnDefineChecks).'; es_ES = 'The accounting check with ID %1 does not exist (see AccountingAuditOverridable.OnDefineChecks).'"),
				CheckSSL);
		EndIf;
	Else
		CommonClientServer.CheckParameter("AccountingAudit.ExecuteCheck", "CheckSSL",
			CheckSSL, Type("CatalogRef.AccountingCheckRules"));
		CheckToExecute = CheckSSL;
	EndIf;
	
	If CheckExecutionParameters <> Undefined Then
		CheckCheckExecutionParameters(CheckExecutionParameters, "AccountingAudit.ExecuteCheck");
	EndIf;
		
	AccountingAuditInternal.ExecuteCheck(CheckToExecute, CheckExecutionParameters);
	
EndProcedure

// Executes checks by a given context - a common flag that links a package of checks.
// If the specified flag is set for a group of checks, all checks of this group are executed.
// In this case, the presence (or absence) of the specified flag in the check itself does not matter.
// Checks with the Usage check box set to False are ignored.
//
// Parameters:
//    AccountingChecksContext - DefinedType.AccountingChecksContext - the context of the executed checks.
//
// Example:
//    AccountingAudit.PerformChecksInContext(Enumerations.BusinessTransactions.MonthEndClosing);
//
Procedure ExecuteChecksInContext(AccountingChecksContext) Export
	
	CommonClientServer.CheckParameter("AccountingAudit.ExecuteChecksInContext",
		"AccountingChecksContext", AccountingChecksContext,
		Metadata.DefinedTypes.AccountingChecksContext.Type);
	
	ChecksByContext = AccountingAuditInternal.ChecksByContext(AccountingChecksContext);
	
	For Each CheckSSL In ChecksByContext Do
		ExecuteCheck(CheckSSL);
	EndDo;
	
EndProcedure

// Sums up the detected issue amount for the specified check kind.
//
// Parameters:
//   ChecksKind                - CatalogRef.ChecksKinds - a reference to a check kind.
//                              - String - a string ID of the Property1 check kind.
//                              - Array - string IDs of the Property1...PropertyN check kind.
//   SearchByExactMap - Boolean - regulates accuracy capabilities. If True, the search is conducted 
//                                by the passed properties for equality, other properties must be equal
//                                Undefined (tabular section of additional properties has to be blank).
//                                If False, other property values can be arbitrary, the main thing 
//                                is that the corresponding properties need to be equal to the structure properties. Default value is True.
//
// Returns:
//  Structure - a summary:
//    * Count - Number - a total number of the issues found.
//    * HasErrors - Boolean - indicates whether the detected issues include issues with the Error severity.
//
// Example:
//   1) Result = SummaryInformationOnChecksKinds("SystemChecks");
//   2) ChecksKind = New Array;
//      ChecksKind.Add("MonthEndClosing");
//      ChecksKind.Add(Company);
//      ChecksKind.Add(ClosingMonth);
//      Result = SummaryInformationOnChecksKinds(ChecksKind);
//
Function SummaryInformationOnChecksKinds(ChecksKind, SearchByExactMap = True) Export
	
	ProcedureName = "AccountingAudit.SummaryInformationOnChecksKinds";
	CommonClientServer.CheckParameter(ProcedureName, "ChecksKind", ChecksKind, AccountingAuditInternal.TypeDetailsCheckKind());
	CommonClientServer.CheckParameter(ProcedureName, "SearchByExactMap", SearchByExactMap, Type("Boolean"));
	
	Return AccountingAuditInternal.SummaryInformationOnChecksKinds(ChecksKind, SearchByExactMap);
	
EndFunction

// Returns detailed information about detected issues of one or several check kinds of interest.
//
// Parameters:
//   ChecksKind                - CatalogRef.ChecksKinds - a reference to a check kind.
//                              - String - a string ID of the Property1 check kind.
//                              - Array - string IDs of the Property1...PropertyN check kind.
//   SearchByExactMatch - Boolean - if True, the check kind is determined by the exact match of all 
//                                property values in the ChecksKind parameter (see example 2).
//                                If False, the check kind is determined both by the specified 
//                                property values and by any values of the unspecified properties in the ViewCheck parameter (see example 3).
//
// Returns:
//   ValueTable - detected issues:
//     * ObjectWithIssue - AnyRef - a reference to object, which the issue is connected to.
//     * IssueSeverity         - EnumRef.AccountingIssueSeverity - an accounting issue severity.
//                                  "Information", "Warning", "Error", ''UsefulTip", and "ImportantInformation".
//     * CheckRule          - CatalogRef.AccountingCheckRules - an executed check with issue details.
//     * ChecksKind             - CatalogRef.ChecksKinds - a check kind.
//     * IssueSummary        - String - a text summary of the found issue.
//     * ResponsiblePerson            - CatalogRef.Users - it is filled in if the checking algorithm 
//                                  identified a specific person responsible for the detected issue.
//     * Detected                 - Date - date and time of detecting an issue.
//     * AdditionalInformation - ValueStorage - arbitrary additional information related to the 
//                                  found issue.
//
// Example:
//   1) Result = DetailedInformationOnChecksKinds("SystemChecks");
//   2) ChecksKind = New Array;
//      ChecksKind.Add("MonthEndClosing");
//      ChecksKind.Add(Company);
//      ChecksKind.Add(ClosingMonth);
//      Result = DetailedInformationOnChecksKinds(ChecksKind);
//   3) Select all month-end closing issues by all periods for the specified company:
//      ChecksKind = New Array;
//      ChecksKind.Add("MonthEndClosing");
//      ChecksKind.Add(Company);
//      Result = DetailedInformationOnChecksKinds(ChecksKind, False);
//
Function DetailedInformationOnChecksKinds(ChecksKind, SearchByExactMap = True) Export
	
	ProcedureName = "AccountingAudit.DetailedInformationOnChecksKinds";
	CommonClientServer.CheckParameter(ProcedureName, "ChecksKind", ChecksKind, AccountingAuditInternal.TypeDetailsCheckKind());
	CommonClientServer.CheckParameter(ProcedureName, "SearchByExactMap", SearchByExactMap, Type("Boolean"));
	
	Return AccountingAuditInternal.DetailedInformationOnChecksKinds(ChecksKind, SearchByExactMap);
	
EndFunction

// Returns a check to the passed ID.
//
// Parameters:
//   ID - String - a check string ID. For example, "CheckRefIntegrity".
//
// Returns:
//   CatalogRef.AccountingCheckRules - a reference to a check or a blank reference if a check with 
//      such ID does not exist.
//
Function CheckByID(ID) Export
	
	CommonClientServer.CheckParameter("AccountingAudit.CheckByID", "ID", ID, Type("String"));
	Return AccountingAuditInternal.CheckByID(ID);
	
EndFunction

// Returns the number of issues detected at the passed object.
//
// Parameters:
//   ObjectWithIssue - AnyRef - an object, for which you need to calculate the number of issues.
//
// Returns:
//   Number
//
Function IssuesCountByObject(ObjectWithIssue) Export
	
	CommonClientServer.CheckParameter("AccountingAudit.IssuesCountByObject", "ObjectWithIssue",
		ObjectWithIssue, Common.AllRefsTypeDetails());
	
	Query = New Query(
	"SELECT ALLOWED
	|	COUNT(*) AS Count
	|FROM
	|	InformationRegister.AccountingCheckResults AS AccountingCheckResults
	|WHERE
	|	AccountingCheckResults.ObjectWithIssue = &ObjectWithIssue
	|	AND NOT AccountingCheckResults.IgnoreIssue");
	Query.SetParameter("ObjectWithIssue", ObjectWithIssue);
	
	SetPrivilegedMode(True);
	Result = Query.Execute().Select();
	Return ?(Result.Next(), Result.Count, 0); 
	
EndFunction

// Calculates the number of issues detected by the passed check rule.
//
// Parameters:
//   CheckRule - CatalogRef.AccountingCheckRules - a rule, for which you need to calculate the 
//                     number of issues.
//
// Returns:
//   Number
//
Function IssuesCountByCheckRule(CheckRule) Export
	
	CommonClientServer.CheckParameter("AccountingAudit.IssuesCountByCheckRule", "CheckRule",
		CheckRule, Type("CatalogRef.AccountingCheckRules"));
	
	Query = New Query(
		"SELECT ALLOWED
		|	COUNT(*) AS Count
		|FROM
		|	InformationRegister.AccountingCheckResults AS AccountingCheckResults
		|WHERE
		|	AccountingCheckResults.CheckRule = &CheckRule
		|	AND NOT AccountingCheckResults.IgnoreIssue");
	Query.SetParameter("CheckRule", CheckRule);
	
	SetPrivilegedMode(True);
	Result = Query.Execute().Select();
	If Result.Next() Then
		IssuesCount = Result.Count;
	Else
		IssuesCount = 0;
	EndIf;
	
	Return IssuesCount;
	
EndFunction

// Generates check execution parameters for passing to the procedures and functions RunCheck, IssueDetails,
// CheckKind, and so on.
// The parameters contain a clarification for what exactly the check is required, for example, check 
// the month-end closing for a particular company during a specific period.
// The order of parameters is taken into consideration.
//
// Parameters:
//     Parameter1     - AnyRef, Boolean, Number, String, Date - the first check parameter.
//     Parameter2     - AnyRef, Boolean, Number, String, Date - the second check parameter.
//     Parameter3     - AnyRef, Boolean, Number, String, Date - the third check parameter.
//     Parameter4     - AnyRef, Boolean, Number, String, Date - the fourth check parameter.
//     Parameter5     - AnyRef, Boolean, Number, String, Date - the fifth check parameter.
//     OtherParameters - Array - other check parameters (items of the AnyRef, Boolean, Number, String, and Date types).
//
// Returns:
//    Structure - search parameters as:
//       * Description - String - a check kind presentation.
//       * Property1 - AnyRef, Boolean, Number, String, Date - the first check parameter.
//       * Property2 - AnyRef, Boolean, Number, String, Date - the second check parameter.
//       * Property3 - AnyRef, Boolean, Number, String, Date - the third check parameter.
//       ...                                              
//       * PropertyN - AnyRef, Boolean, Number, String, Date - the last parameter of the check kind.
//
// Example:
//     1. Parameters = CheckExecutionParameters("SystemChecks");
//     2. Parameters = CheckExecutionParameters("MonthEndClosing", CompanyRef, MonthToClose);
//
Function CheckExecutionParameters(Val Parameter1, Val Parameter2 = Undefined, Val Parameter3 = Undefined,
	Val Parameter4 = Undefined, Val Parameter5 = Undefined, Val OtherParameters = Undefined) Export
	
	Return AccountingAuditInternal.CheckExecutionParameters(Parameter1, Parameter2, Parameter3, Parameter4, Parameter5, OtherParameters);
	
EndFunction

// Clears previous check results, leaving only those issues that were ignored earlier (the 
// IgnoreIssue flag = True).
// The previous results are cleared automatically for non-parameter checks, and then the check algorithm is executed.
// For checks with parameters, preliminary clearing of the previous results need to be performed 
// explicitly using this procedure in the check algorithm itself. Otherwise, the same issue will be 
// registered multiple times with several consecutive check startups.
//
// Parameters:
//     Check                    - CatalogRef.AccountingCheckRules - a check, whose results need to 
//                                   be cleared.
//     CheckExecutionParameters - Structure - see AccountingAudit.CheckExecutionParameters. 
//                                 - Array    - several check parameters (array elements of the 
//                                               Structure type, as described above).
//
Procedure ClearPreviousCheckResults(Val CheckSSL, Val CheckExecutionParameters) Export
	
	CommonClientServer.CheckParameter("AccountingAudit.ClearPreviousCheckResults", "CheckSSL",
		CheckSSL, Type("CatalogRef.AccountingCheckRules"));
	CheckCheckExecutionParameters(CheckExecutionParameters, "AccountingAudit.ClearPreviousCheckResults");
	
	AccountingAuditInternal.ClearPreviousCheckResults(CheckSSL, CheckExecutionParameters);
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Procedures and functions to register accounting issues.

// Generates an issue description for the subsequent registration using the AccountingAudit.
// WriteIssue procedure in the check handler procedure.
//
// Parameters:
//   ObjectWithIssue - AnyRef - an object, which the issue is connected to.
//   CheckParameters - Structure - parameters of the check being performed, whose value needs to be 
//                                   taken from the similarly named parameter of the check handler procedure.
//     * Check         - CatalogRef.AccountingCheckRules - an executed check.
//     * CheckKind      - CatalogRef.ChecksKinds - a check kind.
//     * IssueSeverity   - EnumRef.AccountingIssueSeverity - a level of severity, with which you 
//                            need to register the found accounting issue:
//                            Information, Warning, Error, UsefulTip, or ImportantInformation.
//     * ID      - String - a string check ID.
//     * CheckStartDate - Date - a threshold date that indicates the boundary of the checked objects 
//                            (only for objects with a date). Do not check objects whose date is 
//                            less than the specified one. Not filled in by default (check all).
//     * IssuesLimit       - Number - a number of the checked objects.
//                            1000 by default. If 0 is specified, check all objects.
//     * CheckKind        - CatalogRef.ChecksKinds - a reference to a check kind.
//                            
//
// Returns:
//   Structure - issue details:
//     * ObjectWithIssue - AnyRef - a reference to the object that is the Source of issues.
//     * Check                 - CatalogRef.AccountingCheckRules - a reference to the executed check.
//                                  Taken from the CheckParameters structure.
//     * CheckKind              - CatalogRef.ChecksKinds - a reference to a check kind.
//                                   Taken from the CheckParameters passed structure
//     * IssueSeverity - CatalogRef.ChecksKinds - a reference to a check kind.
//                                   Taken from the CheckParameters structure.
//     * IssueSummary - String - an issue summary string. Not filled in by default.
//     * UniqueKey         - UUID - an issue unique key.
//     * Detected                 - Date - the moment when an issue was detected.
//     * AdditionalInformation - ValueStorage, Undefined - arbitrary additional information related 
//                                  to the found issue. Default value is Undefined.
//     * ResponsiblePerson            - CatalogRef.Users, Undefined - it is filled in if the 
//                                  problematic object has its own responsible person. Default value is Undefined.
//
// Example:
//  Issue = AccountingAudit.IssueDetails(DocumentWithIssue, CheckParameters);
//  Issue.CheckKind = CheckKind;
//  Issue.IssueSummary = StringFunctionsClientServer.SubstituteParametersToString(
//    NStr("en = 'There is an unpassed ""%2""'" document by the ""%1"" counterparty), Result.Counterparty,
//      DocumentWithIssue);
//  AccountingAudit.WriteIssue(Issue, CheckParameters);
//
Function IssueDetails(ObjectWithIssue, CheckParameters) Export
	
	ProcedureName = "AccountingAudit.IssueDetails";
	CommonClientServer.CheckParameter(ProcedureName, "ObjectWithIssue", ObjectWithIssue, 
		Common.AllRefsTypeDetails());
	CommonClientServer.CheckParameter(ProcedureName, "CheckParameters", CheckParameters, Type("Structure"), 
		AccountingAuditInternal.CheckParametersPropertiesExpectedTypes());
		
	Return AccountingAuditInternal.IssueDetails(ObjectWithIssue, CheckParameters);
	
EndFunction

// Saves the check result.
//
// Parameters:
//   Issue          - Structure - see AccountingAudit.IssueDetails. 
//   CheckParameters - Structure - see the CheckParameters parameter in AccountingAudit.IssueDetails.
//
Procedure WriteIssue(Issue, CheckParameters = Undefined) Export
	
	ProcedureName = "AccountingAudit.WriteIssue";
	CommonClientServer.CheckParameter(ProcedureName, "Issue", Issue, Type("Structure"), 
		AccountingAuditInternal.IssueDetailsPropertiesTypesToExpect());
	If CheckParameters <> Undefined Then
		CommonClientServer.CheckParameter(ProcedureName, "CheckParameters", CheckParameters, Type("Structure"), 
			AccountingAuditInternal.CheckParametersPropertiesExpectedTypes());
	EndIf;
	
	AccountingAuditInternal.WriteIssue(Issue, CheckParameters);
	
EndProcedure

// Sets or clears the flag of ignoring an accounting issue.
// When setting the Ignore parameter to True, an issue is no longer displayed to users in object 
// forms and report on the check results. For example, this is useful if a user has decided that the 
// detected issue is not significant or a user does not plan to tackle it.
// When reset to False, the issue becomes relevant again.
//
// Parameters:
//   IssueDetails             - Structure - issue details:
//     * ObjectWithIssue - AnyRef - a reference to object, which the issue is connected to.
//     * CheckRule          - CatalogRef.AccountingCheckRules - an executed check with issue details.
//     * ChecksKind             - CatalogRef.ChecksKinds - a check kind.
//     * IssueSummary        - String - a text summary of the found issue.
//     * AdditionalInformation - ValueStorage - additional information on the ignored issue.
//   Ignore - Boolean - a value set to the specified issue.
//
Procedure IgnoreIssue(Val IssueDetails, Val Ignore) Export
	
	ProcedureName = "AccountingAudit.IgnoreIssue";
	CommonClientServer.CheckParameter(ProcedureName, "Ignore", Ignore, Type("Boolean"));
	CommonClientServer.CheckParameter(ProcedureName, "IssueDetails", IssueDetails, Type("Structure"), 
		AccountingAuditInternal.IssueDetailsPropertiesTypesToExpect(False));
	
	AccountingAuditInternal.IgnoreIssue(IssueDetails, Ignore);
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Procedures and functions for embedding a subsystem in forms of configuration objects.

// In the list form, it displays a column with a picture informing that there are issues with objects in the rows.
// Called form the OnCreateAtServer event of the list form.
// The dynamic lists needs to have the main table determined.
//
// Parameters:
//   Form                  - ManagedForm - a list form.
//   ListsNames           - String - dynamic list names, separated with commas.
//   AdditionalProperties - Structure, Undefined - additional properties.
//      * ProblemIndicatorFieldID - String - a dynamic list field name that will be used to show an 
//                            object problem indicator.
//                            
//
Procedure OnCreateListFormAtServer(Form, ListsNames, AdditionalProperties = Undefined) Export
	
	ProcedureName = "AccountingAudit.OnCreateListFormAtServer";
	CommonClientServer.CheckParameter(ProcedureName, "Form", Form, Type("ManagedForm"));
	CommonClientServer.CheckParameter(ProcedureName, "ListsNames", ListsNames, Type("String"));
	ProblemIndicatorFieldID = Undefined;
	If AdditionalProperties <> Undefined Then
		CommonClientServer.CheckParameter(ProcedureName, "AdditionalProperties", AdditionalProperties, Type("Structure"));
		AdditionalProperties.Property("ProblemIndicatorFieldID", ProblemIndicatorFieldID);
	EndIf;
	
	If Not SubsystemAvailable() Then
		Return;
	EndIf;
	
	GlobalSettings = AccountingAuditInternal.GlobalSettings();
	NamesList          = StrSplit(ListsNames, ",");
	Items            = Form.Items;
	
	For Each ListName In NamesList Do
		FormTable = Items.Find(TrimAll(ListName));
		If FormTable = Undefined Then
			Continue;
		EndIf;
			
		CurrentList   = Form[FormTable.DataPath];
		MainTable = CurrentList.MainTable;
		If Not ValueIsFilled(MainTable) Then
			Continue;
		EndIf;
			
		QueryText = "";
		If CurrentList.CustomQuery Then
			QueryText = CurrentList.QueryText;
		Else
			SchemaToPerform               = FormTable.GetPerformingDataCompositionScheme();
			DynamicListDataSet = SchemaToPerform.DataSets.Find("DynamicListDataSet");
			If DynamicListDataSet <> Undefined Then
				CurrentList.CustomQuery = True;
				QueryText = DynamicListDataSet.Query;
			EndIf;
		EndIf;
		
		If Not ValueIsFilled(QueryText) Then
			Continue;
		EndIf;
			
		QueryStart = Left(QueryText, 7);
		If QueryStart <> "SELECT" Then
			Continue;
		EndIf;
		
		If ProblemIndicatorFieldID = Undefined Then
			ColumnName = "ErrorIndicator_" + Common.CheckSumString(Form.FormName + GetPathSeparator() + ListName);
		Else
			ColumnName = ProblemIndicatorFieldID;
		EndIf;
		
		SeparatedName = StrSplit(MainTable, ".");
		
		ComposerAdditionalProperties = CurrentList.SettingsComposer.Settings.AdditionalProperties;
		ComposerAdditionalProperties.Insert("IndicatorColumn",    ColumnName);
		ComposerAdditionalProperties.Insert("MetadataObjectKind", SeparatedName.Get(0));
		ComposerAdditionalProperties.Insert("MetadataObjectName", SeparatedName.Get(1));
		ComposerAdditionalProperties.Insert("ListName",            ListName);
		
		If ProblemIndicatorFieldID = Undefined Then
			DynamicListPropertiesStructure = Common.DynamicListPropertiesStructure();
			FieldToAdd = "	0 AS " + ColumnName + ",";
			QueryAsArray = StrSplit(QueryText, Chars.LF);
			QueryAsArray.Insert(1, FieldToAdd);
			DynamicListPropertiesStructure.QueryText = StrConcat(QueryAsArray, Chars.LF);
			Common.SetDynamicListProperties(FormTable, DynamicListPropertiesStructure);
		EndIf;
		
		IndicationColumnParameters = New Structure;
		
		AccountingAuditInternal.OnDetermineIndicatiomColumnParameters(IndicationColumnParameters, MainTable);
		AccountingAuditOverridable.OnDetermineIndicatiomColumnParameters(IndicationColumnParameters, MainTable);
		
		ErrorIndicatorColumn = Items.Add(ColumnName, Type("FormField"), FormTable);
		ErrorIndicatorColumn.Type                = FormFieldType.PictureField;
		ErrorIndicatorColumn.DataPath        = StringFunctionsClientServer.SubstituteParametersToString("%1.%2", ListName, ColumnName);
		ErrorIndicatorColumn.TitleLocation = IndicationColumnParameters.TitleLocation;
		ErrorIndicatorColumn.HeaderPicture      = GlobalSettings.IssuesIndicatorPicture;
		ErrorIndicatorColumn.ValuesPicture   = GlobalSettings.IssuesIndicatorPicture;
		ErrorIndicatorColumn.Title          = NStr("ru = 'Индикатор ошибки'; en = 'Error indicator'; pl = 'Error indicator';de = 'Error indicator';ro = 'Error indicator';tr = 'Error indicator'; es_ES = 'Error indicator'");
		
		ListColumns = FormTable.ChildItems;
		If ListColumns.Count() > 0 Then
			If IndicationColumnParameters.OutputLast Then
				Items.Move(ErrorIndicatorColumn, FormTable);
			Else
				Items.Move(ErrorIndicatorColumn, FormTable, ListColumns.Get(0));
			EndIf;
		EndIf;
		
		FormTable.SetAction("Selection", "Attachable_Selection");
		
	EndDo;
	
EndProcedure

// In the list form, it displays a column with a picture informing that there are issues with objects in the rows.
// Called from the OnGetDataAtServer event of the list form.
//
// Parameters:
//   Settings              - DataCompositionSettings - contains a copy of dynamic list full settings.
//   Rows                 - DynamicListRows - a collection contains data and design of all the rows 
//                            got in the list, except for the grouping rows.
//   KeyFieldName       - String - "Ref" or the specified column name that contains an object reference.
//   AdditionalProperties - Structure, Undefined - contains additional properties in case you need 
//                            to use them.
//
Procedure OnGetDataAtServer(Settings, Rows, KeyFieldName = "Ref", AdditionalProperties = Undefined) Export
	
	ProcedureName = "AccountingAudit.OnGetDataAtServer";
	CommonClientServer.CheckParameter(ProcedureName, "Settings", Settings, Type("DataCompositionSettings"));
	CommonClientServer.CheckParameter(ProcedureName, "Rows", Rows, Type("DynamicListRows"));
	CommonClientServer.CheckParameter(ProcedureName, "KeyFieldName", KeyFieldName, Type("String"));
	If AdditionalProperties <> Undefined Then
		CommonClientServer.CheckParameter(ProcedureName, "AdditionalProperties", AdditionalProperties, Type("Structure"));
	EndIf;
	
	If Not SubsystemAvailable() Then
		Return;
	EndIf;
	
	ComposerAdditionalProperties = Settings.AdditionalProperties;
	If ComposerAdditionalProperties.Property("IndicatorColumn") Then
		
		IndicatorColumn = Settings.AdditionalProperties.IndicatorColumn;
		
		If KeyFieldName = "Ref" Then
			RowsKeys = Rows.GetKeys();
		Else
			StartKeys = Rows.GetKeys();
			RowsKeys     = New Array;
			For Each StartKey In StartKeys Do
				RowsKeys.Add(StartKey[KeyFieldName]);
			EndDo;
		EndIf;
		
		ObjectsWithIssues = AccountingAuditInternal.ObjectsWithIssues(RowsKeys);
		
		For Each RowKey In RowsKeys Do
			
			ListLine = Rows[RowKey];
			If Not ListLine.Data.Property(IndicatorColumn) Then
				Continue;
			EndIf;
			
			CellText = ListLine.Appearance.Get(IndicatorColumn).FindParameterValue(New DataCompositionParameter("Text"));
			
			If ObjectsWithIssues.Find(RowKey) = Undefined Then
				ListLine.Data[IndicatorColumn] = 1;
				If CellText <> Undefined Then
					CellText.Value = 0;
				EndIf;
			Else
				ListLine.Data[IndicatorColumn] = 0;
				If CellText <> Undefined Then
					CellText.Value = 1;
				EndIf;
			EndIf;
			
		EndDo;
		
	EndIf;
	
EndProcedure

// Displays a group with a picture and a label in the form of an object, informing about issues with this object.
// Called from the OnReadAtServer event of the object form.
//
// Parameters:
//   Form         - ManagedForm - an object form.
//   CurrentObject - DocumentObject.DocumentName, CatalogObject.CatalogName,
//                         ExchangePlanObject.ExchangePlanName, ChartOfCharacteristicTypesObject.ChartOfCharacteristicTypesName,
//                         ChartOfAccountsObject.ChartOfAccountsName, ChartOfCalculationTypesObject.ChartOfCalculationTypesName,
//                         TaskObject.TaskName - an object that will be read.
//
Procedure OnReadAtServer(Form, CurrentObject) Export
	
	ProcedureName = "AccountingAudit.OnReadAtServer";
	CommonClientServer.CheckParameter(ProcedureName, "Form", Form, Type("ManagedForm"));
	CommonClientServer.CheckParameter(ProcedureName, "CurrentObject", CurrentObject, 
		AccountingAuditInternalCached.TypeDetailsAllObjects());
	
	If Not SubsystemAvailable() Then
		Return;
	EndIf;
	
	GlobalSettings        = AccountingAuditInternal.GlobalSettings();
	ObjectRef             = CurrentObject.Ref;
	ManagedFormItems   = Form.Items;
	IssuesCountByObject = IssuesCountByObject(ObjectRef);
	NamesUniqueKey       = Common.CheckSumString(ObjectRef.Metadata().FullName()
		+ GetPathSeparator() + Form.FormName);
		
	GroupDecoration = ManagedFormItems.Find("ErrorIndicatorGroup_" + NamesUniqueKey);
		
	If IssuesCountByObject = 0 Then
		
		If GroupDecoration <> Undefined Then
			ManagedFormItems.Delete(GroupDecoration);
		EndIf;
		Return;
	EndIf;
	
	IndicationGroupParameters = New Structure;
	AccountingAuditInternal.OnDetermineIndicationGroupParameters(IndicationGroupParameters, TypeOf(ObjectRef));
	AccountingAuditOverridable.OnDetermineIndicationGroupParameters(IndicationGroupParameters, TypeOf(ObjectRef));
	
	If GroupDecoration <> Undefined Then
		
		LabelDecoration = ManagedFormItems.Find("DecorationLabel_" + NamesUniqueKey);
		If LabelDecoration <> Undefined Then
			LabelDecoration.Title = AccountingAuditInternal.GenerateCommonStringIndicator(Form, ObjectRef, IssuesCountByObject,
				GlobalSettings.IssuesIndicatorNote, GlobalSettings.IssuesIndicatorHyperlink);
		EndIf;
		
	Else
		
		ErrorIndicatorGroup = AccountingAuditInternal.PlaceErrorIndicatorGroup(Form, NamesUniqueKey,
			IndicationGroupParameters.GroupParentName, IndicationGroupParameters.OutputAtBottom);
		
		MainRowIndicator = AccountingAuditInternal.GenerateCommonStringIndicator(Form, ObjectRef, IssuesCountByObject,
			GlobalSettings.IssuesIndicatorNote, GlobalSettings.IssuesIndicatorHyperlink);
		
		AccountingAuditInternal.FillErrorIndicatorGroup(Form, ErrorIndicatorGroup, NamesUniqueKey,
			MainRowIndicator, GlobalSettings.IssuesIndicatorPicture);
		
	EndIf;
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Other procedures and functions.

// Returns True if you have the rights to view accounting issues.
//
// Returns:
//   Boolean
//
Function SubsystemAvailable() Export
	
	Return AccountingAuditInternal.SubsystemAvailable();
	
EndFunction

// Returns check kinds by passed parameters.
//
// Parameters:
//   ChecksKinds                - String, Array - a string ID of a check kind (Property1), or an 
//                                array of IDs (Property1...PropertyN), or a reference to a check kind.
//   SearchByExactMap - Boolean - regulates accuracy capabilities. If True, the search is conducted 
//                                by the passed properties for equality, other properties must be equal
//                                Undefined (tabular section of additional properties has to be blank).
//                                If False, other property values can be arbitrary, the main thing 
//                                is that the corresponding properties need to be equal to the structure properties. Default value is True.
//
// Returns:
//   Array - CatalogRef.ChecksKinds items, or a blank array if the search returned no results.
//            When searching by exact map, the array contains a single element.
//
Function ChecksKinds(ChecksKind, SearchByExactMap = True) Export
	
	ProcedureName = "AccountingAudit.ChecksKinds";
	CommonClientServer.CheckParameter(ProcedureName, "ChecksKind", ChecksKind, AccountingAuditInternal.TypeDetailsCheckKind());
	CommonClientServer.CheckParameter(ProcedureName, "SearchByExactMap", SearchByExactMap, Type("Boolean"));
	
	Return AccountingAuditInternal.ChecksKinds(ChecksKind, SearchByExactMap);
	
EndFunction

// Returns an existing ChecksKinds catalog item or creates a new one to register or filter 
// accounting result records.
//
// Parameters:
//     CheckExecuteParameters - String, Structure - the information that identifies a check kind:
//                                 - String    - a string ID of a check kind (Property1).
//                                 - Structure - see AccountingAudit.CheckExecutionParameters. 
//     SearchOnly - Boolean - if True and a check kind with the specified parameters does not exist, 
//                   a blank reference is returned; if False, an item is created and a reference to it is returned.
//
// Returns:
//   CatalogRef.ChecksKinds - an existing catalog item or a newly created one.
//      If only the search was performed (the parameter SearchOnly = True) and the item was not 
//      found, a blank reference to the CatalogRef.ChecksKinds catalog is returned.
//
// Example:
//   CheckKind = AccountingAudit.CheckKind("SystemChecks");
//
Function CheckKind(Val CheckExecutionParameters, Val SearchOnly = False) Export
	
	AllowedTypes = New Array;
	AllowedTypes.Add(Type("String"));
	AllowedTypes.Add(Type("Structure"));
	CommonClientServer.CheckParameter("AccountingAudit.CheckKind",
		"CheckExecutionParameters", CheckExecutionParameters, AllowedTypes);
	If TypeOf(CheckExecutionParameters) = Type("Structure") Then
		CheckCheckExecutionParameter(CheckExecutionParameters, "AccountingAudit.CheckKind");
	EndIf;
	CommonClientServer.CheckParameter("AccountingAudit.CheckKind", "SearchOnly", SearchOnly, Type("Boolean"));
	
	Return AccountingAuditInternal.CheckKind(CheckExecutionParameters, SearchOnly);
	
EndFunction

#Region ObsoleteProceduresAndFunctions

// Obsolete. Use DetailedInformationOnChecksKinds instead.
// Returns detailed information about detected issues of the specified check kind.
//
// Parameters:
//   ChecksKind                - CatalogRef.ChecksKinds - a reference to a check kind.
//                              - String - a string ID of the Property1 check kind.
//                              - Array - string IDs of the Property1...PropertyN check kind.
//   SearchByExactMap - Boolean - regulates accuracy capabilities. If True, the search is conducted 
//                                by the passed properties for equality, other properties must be equal
//                                Undefined (tabular section of additional properties has to be blank).
//                                If False, other property values can be arbitrary, the main thing 
//                                is that the corresponding properties need to be equal to the structure properties. Default value is True.
//
// Returns:
//   ValueTable            - a table of issues:
//     * ObjectWithIssue - AnyRef - a reference to the object that is the Source of issues.
//     * CheckRule          - CatalogRef.AccountingCheckRules - a reference to the executed check.
//     * IssueSummary        - String - a string summary of the found issue.
//     * IssueSeverity         - EnumRef.AccountingIssueSeverity - an accounting issue severity.
//                                  "Information", "Warning", "Error", and "UsefulTip".
//     * ResponsiblePerson            - CatalogRef.Users - it is filled in if it is possible to 
//                                  identify a person responsible for the problematic object.
//     * AdditionalInformation - ValueStorage - a service property with additional information 
//                                  related to the detected issue.
//     * Detected                 - Date - server time of the issue identification.
//
// Example:
//   1) Result = DetailedInformationOnChecksKinds("SystemChecks");
//   2) ChecksKind = New Array;
//      ChecksKind.Add("MonthEndClosing");
//      ChecksKind.Add(Company);
//      ChecksKind.Add(ClosingMonth);
//      Result = DetailedInformationOnChecksKinds(ChecksKind);
//
Function DetailedInformationOnCheckKinds(ChecksKind, SearchByExactMap = True) Export
	
	ProcedureName = "AccountingAudit.DetailedInformationOnChecksKinds";
	CommonClientServer.CheckParameter(ProcedureName, "ChecksKind", ChecksKind, AccountingAuditInternal.TypeDetailsCheckKind());
	CommonClientServer.CheckParameter(ProcedureName, "SearchByExactMap", SearchByExactMap, Type("Boolean"));
	
	DetailedInformation = New ValueTable;
	ChecksKindsArray = New Array;
	
	If TypeOf(ChecksKind) = Type("CatalogRef.ChecksKinds") Then
		ChecksKindsArray.Add(ChecksKind);
	Else
		ChecksKindsArray = AccountingAuditInternal.ChecksKinds(ChecksKind, SearchByExactMap);
	EndIf;
	
	If ChecksKindsArray.Count() = 0 Then
		Return DetailedInformation;
	EndIf;
	
	Query = New Query(
	"SELECT ALLOWED
	|	AccountingCheckResults.ObjectWithIssue AS ObjectWithIssue,
	|	AccountingCheckResults.IssueSeverity AS IssueSeverity,
	|	AccountingCheckResults.CheckRule AS CheckRule,
	|	AccountingCheckResults.CheckKind AS CheckKind
	|FROM
	|	InformationRegister.AccountingCheckResults AS AccountingCheckResults
	|WHERE
	|	NOT AccountingCheckResults.IgnoreIssue
	|	AND AccountingCheckResults.CheckKind IN (&ChecksKindsArray)");
	
	Query.SetParameter("ChecksKindsArray", ChecksKindsArray);
	Result = Query.Execute();
	
	If Not Result.IsEmpty() Then
		DetailedInformation = Result.Unload();
	EndIf;
	
	Return DetailedInformation;
	
EndFunction

// Obsolete. Use SummaryInformationOnChecksKinds instead.
// Sums up the detected issue amount for the specified check kind.
//
// Parameters:
//   ChecksKind                - CatalogRef.ChecksKinds - a reference to a check kind.
//                              - String - a string ID of the Property1 check kind.
//                              - Array - string IDs of the Property1...PropertyN check kind.
//   SearchByExactMap - Boolean - regulates accuracy capabilities. If True, the search is conducted 
//                                by the passed properties for equality, other properties must be equal
//                                Undefined (tabular section of additional properties has to be blank).
//                                If False, other property values can be arbitrary, the main thing 
//                                is that the corresponding properties need to be equal to the structure properties. Default value is True.
//
// Returns:
//  Structure - a summary:
//    * Count - Number - a total number of the issues found.
//    * HasErrors - Boolean - indicates whether the detected issues include issues with the Error severity.
//
// Example:
//   1) Result = SummaryInformationOnChecksKinds("SystemChecks");
//   2) ChecksKind = New Array;
//      ChecksKind.Add("MonthEndClosing");
//      ChecksKind.Add(Company);
//      ChecksKind.Add(ClosingMonth);
//      Result = SummaryInformationOnChecksKinds(ChecksKind);
//
Function SummaryInformationOnCheckKinds(ChecksKind, SearchByExactMap = True) Export
	
	ProcedureName = "AccountingAudit.SummaryInformationOnChecksKinds";
	CommonClientServer.CheckParameter(ProcedureName, "ChecksKind", ChecksKind, AccountingAuditInternal.TypeDetailsCheckKind());
	CommonClientServer.CheckParameter(ProcedureName, "SearchByExactMap", SearchByExactMap, Type("Boolean"));
	
	SummaryInformation = New Structure;
	SummaryInformation.Insert("Count", 0);
	SummaryInformation.Insert("HasErrors", False);
	
	ChecksKindsArray = New Array;
	If TypeOf(ChecksKind) = Type("CatalogRef.ChecksKinds") Then
		ChecksKindsArray.Add(ChecksKind);
	Else
		ChecksKindsArray = AccountingAuditInternal.ChecksKinds(ChecksKind, SearchByExactMap);
		If ChecksKindsArray.Count() = 0 Then
			Return SummaryInformation;
		EndIf;
	EndIf;
	
	Query = New Query(
	"SELECT ALLOWED
	|	COUNT(*) AS Count,
	|	ISNULL(MAX(CASE
	|				WHEN AccountingCheckResults.IssueSeverity = VALUE(Enum.AccountingIssueSeverity.Error)
	|					THEN TRUE
	|				ELSE FALSE
	|			END), FALSE) AS HasErrors
	|FROM
	|	InformationRegister.AccountingCheckResults AS AccountingCheckResults
	|WHERE
	|	NOT AccountingCheckResults.IgnoreIssue
	|	AND AccountingCheckResults.CheckKind IN (&ChecksKindsArray)");
	
	Query.SetParameter("ChecksKindsArray", ChecksKindsArray);
	Result = Query.Execute().Select();
	Result.Next();
	
	FillPropertyValues(SummaryInformation, Result);
	
	Return SummaryInformation;
	
EndFunction

#EndRegion

#EndRegion

#Region Private

Procedure CheckCheckExecutionParameters(CheckExecutionParameters, ProcedureOrFunctionName)
	
	If TypeOf(CheckExecutionParameters) = Type("Structure") Then
		ExecutionParameters = New Array;
		ExecutionParameters.Add(CheckExecutionParameters);
		CheckExecutionParameters = ExecutionParameters;
	EndIf;	
	
	CommonClientServer.CheckParameter(ProcedureOrFunctionName, "CheckExecutionParameters",
		CheckExecutionParameters, Type("Array"));
	
	For Each CheckParameter In CheckExecutionParameters Do
		CheckCheckExecutionParameter(CheckParameter, ProcedureOrFunctionName);
	EndDo;

EndProcedure

Procedure CheckCheckExecutionParameter(CheckParameter, ProcedureOrFunctionName)
	
	CommonClientServer.CheckParameter(ProcedureOrFunctionName, "CheckExecutionParameters.Item",
		CheckParameter, Type("Structure"));
	For Each CurrentParameter In CheckParameter Do
		CommonClientServer.CheckParameter(ProcedureOrFunctionName,
		CurrentParameter.Key, CurrentParameter.Value, AccountingAuditInternal.ExpectedPropertiesTypesOfChecksKinds());
	EndDo;

EndProcedure

#EndRegion

