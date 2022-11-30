///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Internal

// See InfobaseUpdateSSL.OnAddUpdateHandlers. 
Procedure OnAddUpdateHandlers(Handlers) Export
	
	If HasChangesOfAccountingChecksParameters() Then
		Handler = Handlers.Add();
		Handler.Version          = "*";
		Handler.ExecutionMode = "Deferred";
		Handler.ID   = New UUID("c17ea385-6085-471f-ab94-219ec30a5a38");
		Handler.Comment     = NStr("ru = 'Обновляются правила проверки учета в соответствие с изменениями в новой версии программы.
			|До завершения обработки часть проверок ведения учета будет недоступна.'; 
			|en = 'Updating the accounting check rules to reflect the changes in the new version of the application.
			|Some of the accounting checks are not available until the update is complete.'; 
			|pl = 'Updating the accounting check rules to reflect the changes in the new version of the application.
			|Some of the accounting checks are not available until the update is complete.';
			|de = 'Updating the accounting check rules to reflect the changes in the new version of the application.
			|Some of the accounting checks are not available until the update is complete.';
			|ro = 'Updating the accounting check rules to reflect the changes in the new version of the application.
			|Some of the accounting checks are not available until the update is complete.';
			|tr = 'Updating the accounting check rules to reflect the changes in the new version of the application.
			|Some of the accounting checks are not available until the update is complete.'; 
			|es_ES = 'Updating the accounting check rules to reflect the changes in the new version of the application.
			|Some of the accounting checks are not available until the update is complete.'");
		Handler.Procedure       = "AccountingAuditInternal.UpdateAuxiliaryRegisterDataByConfigurationChanges";
	EndIf;
	
	Handler = Handlers.Add();
	Handler.Version                              = "3.0.1.25";
	Handler.ID                       = New UUID("4a240e04-87df-4c10-9f7f-97969c61e84f");
	Handler.Procedure                           = "InformationRegisters.AccountingCheckResults.ProcessDataForMigrationToNewVersion";
	Handler.ExecutionMode                     = "Deferred";
	Handler.UpdateDataFillingProcedure = "InformationRegisters.AccountingCheckResults.RegisterDataToProcessForMigrationToNewVersion";
	Handler.DeferredProcessingQueue          = 1;
	Handler.ObjectsToBeRead                     = "InformationRegister.AccountingCheckResults";
	Handler.ObjectsToChange                   = "InformationRegister.AccountingCheckResults";
	Handler.ObjectsToLock                  = "InformationRegister.AccountingCheckResults";
	Handler.ExecutionPriorities                = InfobaseUpdate.HandlerExecutionPriorities();
	Handler.CheckProcedure                   = "InfobaseUpdate.DataUpdatedForNewApplicationVersion";
	Handler.Comment                         = 
		NStr("ru = 'Начальное заполнение признака ИгнорироватьПроблему и расчет контрольных сумм в регистре сведений ""Результаты проверки учета"" для повышение производительности.'; en = 'Initial filling of the IgnoreIssue attribute and calculation of checksums in the Accounting Check Results information register in order to increase performance.'; pl = 'Initial filling of the IgnoreIssue attribute and calculation of checksums in the Accounting Check Results information register in order to increase performance.';de = 'Initial filling of the IgnoreIssue attribute and calculation of checksums in the Accounting Check Results information register in order to increase performance.';ro = 'Initial filling of the IgnoreIssue attribute and calculation of checksums in the Accounting Check Results information register in order to increase performance.';tr = 'Initial filling of the IgnoreIssue attribute and calculation of checksums in the Accounting Check Results information register in order to increase performance.'; es_ES = 'Initial filling of the IgnoreIssue attribute and calculation of checksums in the Accounting Check Results information register in order to increase performance.'");
	
	Handler = Handlers.Add();
	Handler.Version                              = "3.0.1.195";
	Handler.ID                       = New UUID("fcd45d27-8e5d-45dd-9648-deff60825ae1");
	Handler.Procedure                           = "Catalogs.AccountingCheckRules.ProcessDataForMigrationToNewVersion";
	Handler.ExecutionMode                     = "Deferred";
	Handler.UpdateDataFillingProcedure = "Catalogs.AccountingCheckRules.RegisterDataToProcessForMigrationToNewVersion";
	Handler.DeferredProcessingQueue          = 1;
	Handler.ObjectsToBeRead                     = "Catalog.AccountingCheckRules";
	Handler.ObjectsToChange                   = "Catalog.AccountingCheckRules";
	Handler.ObjectsToLock                  = "Catalog.AccountingCheckRules";
	Handler.ExecutionPriorities                = InfobaseUpdate.HandlerExecutionPriorities();
	Handler.CheckProcedure                   = "InfobaseUpdate.DataUpdatedForNewApplicationVersion";
	Handler.Comment                         = NStr("ru = 'Отключение автоматического запуска системных проверок в подсистеме контроля ведения учета.'; en = 'Disabling automatic running of system checks in the accounting audit subsystem.'; pl = 'Disabling automatic running of system checks in the accounting audit subsystem.';de = 'Disabling automatic running of system checks in the accounting audit subsystem.';ro = 'Disabling automatic running of system checks in the accounting audit subsystem.';tr = 'Disabling automatic running of system checks in the accounting audit subsystem.'; es_ES = 'Disabling automatic running of system checks in the accounting audit subsystem.'");
	
EndProcedure

// See ToDoListOverridable.OnDetermineToDoListHandlers 
Procedure OnFillToDoList(ToDoList) Export
	
	If Not SubsystemAvailable() Then
		Return;
	EndIf;
	
	CheckKind = CheckKind("SystemChecks");
	Issues    = SummaryInformationOnChecksKinds(CheckKind);
	
	ModuleToDoListServer = Common.CommonModule("ToDoListServer");
	Sections                 = ModuleToDoListServer.SectionsForObject("Report.AccountingCheckResults");
	
	For Each Section In Sections Do
		ToDoItem = ToDoList.Add();
		ToDoItem.ID  = "AccountingAudit" + StrReplace(Section.FullName(), ".", "_");
		ToDoItem.HasToDoItems       = Issues.Count > 0;
		ToDoItem.Important         = Issues.HasErrors;
		ToDoItem.Owner       = Section;
		ToDoItem.Presentation  = NStr("ru = 'Некорректные данные'; en = 'Invalid data'; pl = 'Invalid data';de = 'Invalid data';ro = 'Invalid data';tr = 'Invalid data'; es_ES = 'Invalid data'");
		ToDoItem.Count     = Issues.Count;
		ToDoItem.FormParameters = New Structure("CheckKind", CheckKind);
		ToDoItem.Form          = "Report.AccountingCheckResults.Form";
	EndDo;
	
EndProcedure

// See ExportImportDataOverridable.OnFillTypesExcludedFromExportImport. 
Procedure OnFillTypesExcludedFromExportImport(Types) Export
	
	// The accounting check results will be generated again upon the next check, that is why you do not 
	// need to export and import them.
	Types.Add(Metadata.InformationRegisters.AccountingCheckResults);
	
EndProcedure

// See AccountingAuditOverridable.OnGetTemplatesList. 
Procedure OnGetTemplateList(JobTemplates) Export
	
	JobTemplates.Add("AccountingCheck");
	
EndProcedure

// See AccessManagementOverridable.OnFillListsWithAccessRestriction. 
Procedure OnFillListsWithAccessRestriction(Lists) Export
	
	Lists.Insert(Metadata.InformationRegisters.AccountingCheckResults, True);
	
EndProcedure

// Updates components of the systematic accounting checks upon configuration change.
// 
// Parameters:
//  HasChanges - Boolean - return value. True if data is changed; otherwise, it is not changed.
//                           
//
Procedure UpdateAccountingChecksParameters(HasChanges = Undefined) Export
	
	SetPrivilegedMode(True);
	
	SystemChecksHashing = ChecksHash();
	
	BeginTransaction();
	Try
		HasCurrentChanges = False;
		
		StandardSubsystemsServer.UpdateApplicationParameter(
			"StandardSubsystems.AccountingAudit.SystemChecks",
			SystemChecksHashing, HasCurrentChanges);
		
		StandardSubsystemsServer.AddApplicationParameterChanges(
			"StandardSubsystems.AccountingAudit.SystemChecks",
			?(HasCurrentChanges, New FixedStructure("HasChanges", True), New FixedStructure()));
		
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;
	
	If HasCurrentChanges Then
		HasChanges = True;
	EndIf;
	
EndProcedure

Function SystemCheckIssues() Export
	
	SummaryInformationOnChecksKinds = SummaryInformationOnChecksKinds("SystemChecks");
	Return SummaryInformationOnChecksKinds.Count > 0;
	
EndFunction

#EndRegion

#Region Private

// See AccountingAudit.SummaryInformationOnChecksKinds. 
Function SummaryInformationOnChecksKinds(ChecksKind, SearchByExactMap = True) Export
	
	SummaryInformation = New Structure;
	SummaryInformation.Insert("Count", 0);
	SummaryInformation.Insert("HasErrors", False);
	
	ChecksKinds = New Array;
	
	If TypeOf(ChecksKind) = Type("CatalogRef.ChecksKinds") Then
		ChecksKinds.Add(ChecksKind);
	ElsIf TypeOf(ChecksKind) = Type("String") Then
		CheckExecutionParameters = CheckExecutionParameters(ChecksKind);
		ChecksKinds = ChecksKinds(CheckExecutionParameters, SearchByExactMap);
	Else
		CheckExecutionParameters = CheckExecutionParametersFromArray(ChecksKind);
		ChecksKinds = ChecksKinds(CheckExecutionParameters, SearchByExactMap);
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
	|	AccountingCheckResults.CheckRule.DeletionMark = FALSE
	|	AND NOT AccountingCheckResults.IgnoreIssue
	|	AND AccountingCheckResults.CheckKind IN (&ChecksKinds)");
	
	Query.SetParameter("ChecksKinds", ChecksKinds);
	Result = Query.Execute().Select();
	Result.Next();
	
	FillPropertyValues(SummaryInformation, Result);
	Return SummaryInformation;
	
EndFunction

// See AccountingAudit.DetailedInformationOnChecksKinds. 
Function DetailedInformationOnChecksKinds(ChecksKind, SearchByExactMap = True) Export
	
	DetailedInformation        = New ValueTable;
	DetailedInformationColumns = DetailedInformation.Columns;
	DetailedInformationColumns.Add("ObjectWithIssue",         Common.AllRefsTypeDetails());
	DetailedInformationColumns.Add("IssueSeverity",         New TypeDescription("EnumRef.AccountingIssueSeverity"));
	DetailedInformationColumns.Add("CheckRule",          New TypeDescription("CatalogRef.AccountingCheckRules"));
	DetailedInformationColumns.Add("CheckKind",              New TypeDescription("CatalogRef.ChecksKinds"));
	DetailedInformationColumns.Add("IssueSummary",        New TypeDescription("String"));
	DetailedInformationColumns.Add("EmployeeResponsible",            New TypeDescription("CatalogRef.Users"));
	DetailedInformationColumns.Add("Detected",                 New TypeDescription("Date"));
	DetailedInformationColumns.Add("AdditionalInformation", New TypeDescription("ValueStorage"));
	
	ChecksKinds = New Array;
	
	If TypeOf(ChecksKind) = Type("CatalogRef.ChecksKinds") Then
		ChecksKinds.Add(ChecksKind);
	ElsIf TypeOf(ChecksKind) = Type("String") Then
		CheckExecutionParameters = CheckExecutionParameters(ChecksKind);
		ChecksKinds = ChecksKinds(CheckExecutionParameters, SearchByExactMap);
	Else
		CheckExecutionParameters = CheckExecutionParametersFromArray(ChecksKind);
		ChecksKinds = ChecksKinds(CheckExecutionParameters, SearchByExactMap);
	EndIf;
	
	If ChecksKinds.Count() = 0 Then
		Return DetailedInformation;
	EndIf;
	
	Query = New Query(
	"SELECT ALLOWED
	|	AccountingCheckResults.ObjectWithIssue AS ObjectWithIssue,
	|	AccountingCheckResults.CheckRule AS CheckRule,
	|	AccountingCheckResults.IssueSeverity AS IssueSeverity,
	|	AccountingCheckResults.CheckKind AS CheckKind,
	|	AccountingCheckResults.IssueSummary AS IssueSummary,
	|	AccountingCheckResults.EmployeeResponsible AS EmployeeResponsible,
	|	AccountingCheckResults.Detected AS Detected,
	|	AccountingCheckResults.AdditionalInformation AS AdditionalInformation
	|FROM
	|	InformationRegister.AccountingCheckResults AS AccountingCheckResults
	|WHERE
	|	AccountingCheckResults.CheckRule.DeletionMark = FALSE
	|	AND NOT AccountingCheckResults.IgnoreIssue
	|	AND AccountingCheckResults.CheckKind IN(&ChecksKinds)");
	
	Query.SetParameter("ChecksKinds", ChecksKinds);
	Result = Query.Execute();
	
	If Not Result.IsEmpty() Then
		DetailedInformation = Result.Unload();
	EndIf;
	
	Return DetailedInformation;
	
EndFunction

// See AccountingAudit.ChecksKinds. 
Function ChecksKinds(ChecksKind, SearchByExactMap = True) Export
	
	If TypeOf(ChecksKind) = Type("CatalogRef.ChecksKinds") Then
		Result = New Array;
		Result.Add(ChecksKind);
		Return Result;
	EndIf;
	
	If TypeOf(ChecksKind) = Type("String") Then
		CheckExecutionParameters = CheckExecutionParameters(ChecksKind);
	ElsIf TypeOf(ChecksKind) = Type("Array") Then
		CheckExecutionParameters = CheckExecutionParametersFromArray(ChecksKind);
	Else
		CheckExecutionParameters = ChecksKind;
	EndIf;
	
	If TypeOf(CheckExecutionParameters) = Type("Structure") Then
		Return CheckKindRegularSearch(CheckExecutionParameters, SearchByExactMap);
		
	ElsIf TypeOf(CheckExecutionParameters) = Type("Array") Then
		
		If CheckExecutionParameters.Count() > PropertiesCount() Then
			Return CheckKindExtendedSearch(CheckExecutionParameters, CheckExecutionParameters.Count());
		Else
			Return CheckKindRegularSearch(CheckExecutionParameters, SearchByExactMap);
		EndIf;
		
	EndIf;
	
	Return New Array;
	
EndFunction

// See AccountingAudit.CheckKind. 
Function CheckKind(Val CheckExecutionParameters, Val SearchOnly = False) Export
	
	If TypeOf(CheckExecutionParameters) = Type("String") Then
		CheckExecutionParameters = CheckExecutionParameters(CheckExecutionParameters);
	EndIf;
	
	BeginTransaction();
	Try
		Lock = ChecksKindsLock(CheckExecutionParameters);
		Lock.Lock();
		
		If CheckExecutionParameters.Count() - 1 > PropertiesCount() Then
			CheckKindArray = CheckKindExtendedSearch(CheckExecutionParameters, PropertiesCount());
		Else
			CheckKindArray = CheckKindRegularSearch(CheckExecutionParameters);
		EndIf;
		
		If CheckKindArray.Count() = 0 Then
			If SearchOnly Then
				CheckKind = Catalogs.ChecksKinds.EmptyRef();
			Else
				CheckKind = NewCheckKind(CheckExecutionParameters);
			EndIf;
		Else
			CheckKind = CheckKindArray.Get(0);
		EndIf;
		
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;
	
	Return CheckKind;
	
EndFunction

// Searches for a check kind by the passed parameters.
//
// Parameters:
//   CheckExecutionParameters - Structure - see AccountingAudit.CheckExecutionParameters. 
//   PropertiesCount           - Number - a number of properties, by which the search is performed.
//
// Returns:
//   CatalogRef.ChecksKinds - a catalog item, or an empty reference if the search returned no results.
//
Function CheckKindExtendedSearch(CheckExecutionParameters, PropertiesCount)
	
	Query = New Query(
	"SELECT
	|	ChecksKinds.Ref AS CheckKind
	|INTO TT_ChecksKinds
	|FROM
	|	Catalog.ChecksKinds AS ChecksKinds
	|WHERE
	|	&Condition
	|
	|GROUP BY
	|	ChecksKinds.Ref
	|
	|HAVING
	|	COUNT(ChecksKinds.ObjectProperties.Ref) = &ThresholdValue
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ChecksKindsObjectProperties.Ref AS CheckKind,
	|	ChecksKindsObjectProperties.PropertyValue AS PropertyValue,
	|	ChecksKindsObjectProperties.PropertyName AS PropertyName
	|FROM
	|	TT_ChecksKinds AS TT_ChecksKinds
	|		INNER JOIN Catalog.ChecksKinds.ObjectProperties AS ChecksKindsObjectProperties
	|		ON TT_ChecksKinds.CheckKind = ChecksKindsObjectProperties.Ref
	|
	|ORDER BY
	|	CheckKind");
	
	ConditionsText           = " True ";
	ParametersCount   = CheckExecutionParameters.Count() - 1;
	Query.SetParameter("ThresholdValue", ParametersCount - PropertiesCount);
	
	For Index = 1 To PropertiesCount Do
		
		Property  = "Property" + Format(Index, "NG=0");
		Value  = CheckExecutionParameters[Property];
		
		ConditionsText = ConditionsText + " AND " + Property + " = &" + Property;
		Query.SetParameter(Property, Value);
		
	EndDo;
	
	Query.Text = StrReplace(Query.Text, "&Condition", ConditionsText);
	Result = Query.Execute().Unload();
	
	TransposedTable = New ValueTable;
	TableColumns           = TransposedTable.Columns;
	TableColumns.Add("CheckKind", New TypeDescription("CatalogRef.ChecksKinds"));
	
	SearchStructure = New Structure;
	SearchIndex    = "";
	
	For ThresholdIndex = PropertiesCount + 1 To ParametersCount Do
		
		ColumnName   = "Property" + Format(ThresholdIndex, "NG=0");
		SearchIndex = SearchIndex + ?(ValueIsFilled(SearchIndex), ", ", "") + ColumnName;
		TableColumns.Add(ColumnName);
		
		SearchStructure.Insert(ColumnName, CheckExecutionParameters[ColumnName]);
		
	EndDo;
	
	CurrentCheckKind = Undefined;
	For Each ResultString In Result Do
		
		If CurrentCheckKind <> ResultString.CheckKind Then
			
			CurrentCheckKind = ResultString.CheckKind;
			NewRow = TransposedTable.Add();
			NewRow.CheckKind = CurrentCheckKind;
			
		EndIf;
		
		NewRow[ResultString.PropertyName] = ResultString.PropertyValue;
		
	EndDo;
	
	If TransposedTable.Count() > 1000 Then
		TransposedTable.Indexes.Add(SearchIndex);
	EndIf;
	
	FoundRows     = TransposedTable.FindRows(SearchStructure);
	ChecksKindsArray = New Array;
	For Each FoundRow In FoundRows Do
		ChecksKindsArray.Add(FoundRow.CheckKind);
	EndDo;
	
	Return ChecksKindsArray;
	
EndFunction

// In order to avoid conflicts when called from different scheduled jobs, locks the CheckKinds 
// catalog by the passed check execution parameters.
//
// Parameters:
//   CheckExecutionParameters - Structure - see AccountingAudit.CheckExecutionParameters. 
//
// Returns:
//   DataLock  - a lock object of the ChecksKinds catalog.
//
Function ChecksKindsLock(CheckExecutionParameters)
	
	DataLock = New DataLock;
	DataLockItem = DataLock.Add("Catalog.ChecksKinds");
	
	If CheckExecutionParameters.Count() - 1 > PropertiesCount() Then
		Index = 1;
		For Each SearchParameter In CheckExecutionParameters Do
			DataLockItem.SetValue("Property" + Format(Index, "NG=0"), SearchParameter.Value);
			Index = Index + 1;
		EndDo;
	EndIf;
	
	Return DataLock;
	
EndFunction

// Searches for a check kind by the passed parameters.
//
// Parameters:
//   CheckExecutionParameters - Structure - see AccountingAudit.CheckExecutionParameters. 
//   SearchByExactMap - Boolean - if True, search is performed by the passed parameters for equality, 
//                                other properties need to be equal
//                                Undefined (tabular section of additional properties has to be blank).
//                                If False, other property values can be arbitrary, the main thing 
//                                is that the corresponding properties need to be equal to the structure properties. Default value is True.
//
// Returns:
//   CatalogRef.ChecksKinds - a catalog item, or an empty reference if the search returned no results.
//
Function CheckKindRegularSearch(CheckExecutionParameters, SearchByExactMap = True)
	
	Query = New Query(
	"SELECT
	|	ChecksKinds.Ref AS CheckKind
	|FROM
	|	Catalog.ChecksKinds AS ChecksKinds
	|WHERE
	|	&Condition
	|
	|GROUP BY
	|	ChecksKinds.Ref
	|
	|HAVING
	|	COUNT(ChecksKinds.ObjectProperties.Ref) = 0");
	
	ConditionsText         = " True ";
	ParametersCount = CheckExecutionParameters.Count() - 1;
	PropertiesCount    = PropertiesCount();
	
	For Index = 1 To PropertiesCount Do
		
		Property = "Property" + Format(Index, "NG=0");
		If Index > ParametersCount Then
			If SearchByExactMap Then
				ConditionsText = ConditionsText + " AND " + Property + " = Undefined";
			EndIf;
		Else
			Value     = CheckExecutionParameters[Property];
			
			ConditionsText = ConditionsText + " AND " + Property + " = &" + Property;
			Query.SetParameter(Property, Value);
		EndIf;
		
	EndDo;
	
	Query.Text = StrReplace(Query.Text, "&Condition", ConditionsText);
	Result = Query.Execute().Unload();
	
	Return Result.UnloadColumn("CheckKind");
	
EndFunction

// Creates a ChecksKinds catalog item based on the specified parameters.
//
// Parameters:
//   CheckExecutionParameters - Structure - see AccountingAudit.CheckExecutionParameters. 
//
// Returns:
//    CatalogRef.ChecksKinds - the created catalog item.
//
Function NewCheckKind(CheckExecutionParameters)
	
	AccountingChecks = AccountingAuditInternalCached.AccountingChecks();
	ChecksGroups = AccountingChecks.ChecksGroups;
	ChecksGroup = ChecksGroups.Find(CheckExecutionParameters.Description, "ID");
	
	NewCheckKind = Catalogs.ChecksKinds.CreateItem();
	If ChecksGroup = Undefined Then
		NewCheckKind.Description = CheckExecutionParameters.Description;
	Else
		NewCheckKind.Description = ChecksGroup.Description;
	EndIf;
	PropertiesCount    = PropertiesCount();
	ParametersCount = CheckExecutionParameters.Count() - 1;
	
	If PropertiesCount > ParametersCount Then
		For Index = 1 To ParametersCount Do
			PropertyName = "Property" + Format(Index, "NG=0");
			NewCheckKind[PropertyName] = CheckExecutionParameters[PropertyName];
		EndDo;
	Else
		For Index = 1 To ParametersCount Do
			PropertyName = "Property" + Format(Index, "NG=0");
			If Index <= PropertiesCount Then
				NewCheckKind[PropertyName] = CheckExecutionParameters[PropertyName];
			Else
				FillPropertyValues(NewCheckKind.ObjectProperties.Add(),
					New Structure("PropertyName, PropertyValue", PropertyName, CheckExecutionParameters[PropertyName]));
			EndIf;
		EndDo;
	EndIf;
	
	NewCheckKind.Write();
	
	Return NewCheckKind.Ref;
	
EndFunction

// The number of properties in the ChecksKinds catalog header.
// 
// Returns:
//   Number - value 5.
//
Function PropertiesCount()
	
	Return 5;
	
EndFunction

// See AccountingAuditOverridable.OnDefineSettings. 
Function GlobalSettings() Export
	
	Settings = New Structure;
	Settings.Insert("IssuesIndicatorPicture",    PictureLib.Warning);
	Settings.Insert("IssuesIndicatorNote",   Undefined);
	Settings.Insert("IssuesIndicatorHyperlink", Undefined);
	
	AccountingAuditOverridable.OnDefineSettings(Settings);
	
	Return Settings;
	
EndFunction

// Returns an array of objects with issues. Maximum reduced to increase performance.
//
//  Parameters:
//    RowsKeys - Array - an array that contains all keys of the dynamic list rows.
//
//  Return value - an array from AnyRef - an array of problem objects.
//
Function ObjectsWithIssues(RowsKeys) Export
	
	CurrentUserFullAccess = Users.IsFullUser();
	
	Query = New Query(
	"SELECT DISTINCT
	|	AccountingCheckResults.ObjectWithIssue AS ObjectWithIssue
	|FROM
	|	InformationRegister.AccountingCheckResults AS AccountingCheckResults
	|WHERE
	|	AccountingCheckResults.ObjectWithIssue IN(&ObjectsList)
	|	AND NOT AccountingCheckResults.IgnoreIssue");
	Query.SetParameter("ObjectsList", RowsKeys);
	
	If Not CurrentUserFullAccess Then
		SetPrivilegedMode(True);
	EndIf;
	
	ObjectsWithIssues = Query.Execute().Unload().UnloadColumn("ObjectWithIssue");
	
	If Not CurrentUserFullAccess Then
		SetPrivilegedMode(False);
	EndIf;
	
	Return ObjectsWithIssues;
	
EndFunction

// See the AccountingAudit.IssueDetails. 
Function IssueDetails(ObjectWithIssue, CheckParameters) Export
	
	Result = New Structure;
	Result.Insert("ObjectWithIssue",         ObjectWithIssue);
	Result.Insert("CheckRule",          CheckParameters.CheckSSL);
	Result.Insert("IssueSeverity",         CheckParameters.IssueSeverity);
	Result.Insert("IssueSummary",        "");
	Result.Insert("UniqueKey",         New UUID);
	Result.Insert("Detected",                 CurrentSessionDate());
	Result.Insert("AdditionalInformation", New ValueStorage(Undefined));
	Result.Insert("EmployeeResponsible",            Undefined);
	Result.Insert("CheckKind",              ?(CheckParameters.CheckExecutionParameters.Count() = 1,
		CheckKind(CheckParameters.CheckExecutionParameters[0]), Undefined));
	Return Result;
	
EndFunction

// See the AccountingAudit.WriteIssue. 
Procedure WriteIssue(CheckError, CheckParameters = Undefined) Export
	
	If CheckParameters <> Undefined AND IsLastCheckIteration(CheckParameters) Then
		Return;
	EndIf;
	
	If Not ValueIsFilled(CheckError.CheckKind) Then
		Raise StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'При записи проблемы по проверке ""%1"" не указан вид проверки.'; en = 'Check type is not specified when writing the issue for the  ""%1"" check.'; pl = 'Check type is not specified when writing the issue for the  ""%1"" check.';de = 'Check type is not specified when writing the issue for the  ""%1"" check.';ro = 'Check type is not specified when writing the issue for the  ""%1"" check.';tr = 'Check type is not specified when writing the issue for the  ""%1"" check.'; es_ES = 'Check type is not specified when writing the issue for the  ""%1"" check.'"), 
				CheckError.CheckRule);
	EndIf;
	
	ObjectWithIssue    = CheckError.ObjectWithIssue;
	AttributesCollection = ObjectWithIssue.Metadata().Attributes;
	
	AccountingAuditOverridable.BeforeWriteIssue(CheckError, ObjectWithIssue, AttributesCollection);
	
	CheckError.Insert("Checksum", IssueChecksum(CheckError));
	If ThisIssueIgnored(CheckError.Checksum) Then
		Return;
	EndIf;
	
	RecordSet = InformationRegisters.AccountingCheckResults.CreateRecordSet();
	Filter = RecordSet.Filter;
	Filter.ObjectWithIssue.Set(ObjectWithIssue);
	Filter.CheckRule.Set(CheckError.CheckRule);
	Filter.CheckKind.Set(CheckError.CheckKind);
	Filter.UniqueKey.Set(CheckError.UniqueKey);
	
	NewRecord = RecordSet.Add();
	FillPropertyValues(NewRecord, CheckError);
	
	RecordSet.Write();
	
EndProcedure

// See AccountingAudit.IgnoreIssue. 
Procedure IgnoreIssue(IssueDetails, Value) Export
	
	BeginTransaction();
	Try
		DataLock        = New DataLock;
		DataLockItem = DataLock.Add("InformationRegister.AccountingCheckResults");
		DataLockItem.SetValue("ObjectWithIssue", IssueDetails.ObjectWithIssue);
		DataLockItem.SetValue("CheckRule", IssueDetails.CheckRule);
		DataLockItem.SetValue("CheckKind", IssueDetails.CheckKind);
		DataLock.Lock();
		
		Checksum = IssueChecksum(IssueDetails);
		
		Query = New Query(
		"SELECT
		|	AccountingCheckResults.IgnoreIssue AS IgnoreIssue,
		|	AccountingCheckResults.ObjectWithIssue AS ObjectWithIssue,
		|	AccountingCheckResults.CheckRule AS CheckRule,
		|	AccountingCheckResults.CheckKind AS CheckKind,
		|	AccountingCheckResults.AdditionalInformation AS AdditionalInformation
		|FROM
		|	InformationRegister.AccountingCheckResults AS AccountingCheckResults
		|WHERE
		|	AccountingCheckResults.Checksum = &Checksum");
		
		Query.SetParameter("Checksum", Checksum);
		Result = Query.Execute();
		If Result.IsEmpty() Then
			RollbackTransaction();
			Return;
		EndIf;
		
		PassedAddInfoChecksum = "";
		If IssueDetails.Property("AdditionalInformation") Then
			PassedAddInfoChecksum = Common.CheckSumString(IssueDetails.AdditionalInformation);
		EndIf;
		
		Selection = Result.Select();
		While Selection.Next() Do
			
			If ValueIsFilled(PassedAddInfoChecksum) Then
				
				FoundAddInfoChecksum  = Common.CheckSumString(Selection.AdditionalInformation);
				If FoundAddInfoChecksum <> PassedAddInfoChecksum Then
					Continue;
				EndIf;
				
			EndIf;
			
			If Selection.IgnoreIssue <> Value Then
				
				RecordSet = InformationRegisters.AccountingCheckResults.CreateRecordSet();
				RecordSet.Filter.ObjectWithIssue.Set(Selection.ObjectWithIssue);
				RecordSet.Filter.CheckRule.Set(Selection.CheckRule);
				RecordSet.Filter.CheckKind.Set(Selection.CheckKind);
				RecordSet.Read();
				
				Record = RecordSet.Get(0);
				Record.IgnoreIssue = Value;
				RecordSet.Write();
				
			EndIf;
			
		EndDo;
		
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;
	
EndProcedure

// Returns check parameters for the passed scheduled job ID.
//
//  Parameters
//    ScheduledJobID - String - a field to connect to the current background job.
//
//  Return value - a structure with properties, Undefined:
//       * ID - String - a check string ID.
//
Function CheckByScheduledJobIDParameters(ScheduledJobID)
	
	Query = New Query(
	"SELECT TOP 1
	|	AccountingCheckRules.ID AS ID
	|FROM
	|	Catalog.AccountingCheckRules AS AccountingCheckRules
	|WHERE
	|	AccountingCheckRules.ScheduledJobID = &ScheduledJobID
	|	AND AccountingCheckRules.Use");
	
	Query.SetParameter("ScheduledJobID", String(ScheduledJobID));
	Result = Query.Execute().Select();
	
	If Not Result.Next() Then
		Return Undefined;
	Else
		
		ReturnStructure = New Structure;
		ReturnStructure.Insert("ID", Result.ID);
		
		Return ReturnStructure;
		
	EndIf;
	
EndFunction

#Region ChecksCatalogUpdate

// Updates auxiliary data that partially depends on the configuration.
//
Procedure UpdateAuxiliaryRegisterDataByConfigurationChanges(Parameters = Undefined) Export
	
	BeginTransaction();
	Try
		Lock = New DataLock;
		Lock.Add("Catalog.AccountingCheckRules");
		Lock.Lock();
		
		UpdateCatalogAuxiliaryDataByConfigurationChanges();
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;
	
EndProcedure

Function HasChangesOfAccountingChecksParameters() Export
	
	SetPrivilegedMode(True);
	LastChanges = StandardSubsystemsServer.ApplicationParameterChanges(
		"StandardSubsystems.AccountingAudit.SystemChecks");
	Return LastChanges = Undefined Or LastChanges.Count() > 0;
	
EndFunction

Procedure AddChecksGroups(ChecksGroups)
	
	For Each ChecksGroup In ChecksGroups Do
		
		ChecksGroupByID = AccountingAudit.CheckByID(ChecksGroup.ID);
		
		If Not ValueIsFilled(ChecksGroupByID) Then
			ChecksGroupObject = Catalogs.AccountingCheckRules.CreateFolder();
		Else
			
			If ChecksGroupByID.AccountingCheckIsChanged Then
				Continue;
			EndIf;
			
			ChecksGroupObject = ChecksGroupByID.GetObject();
			If ChecksGroupByID.DeletionMark Then
				ChecksGroupObject.SetDeletionMark(False);
			EndIf;
			
		EndIf;
		
		FillPropertyValues(ChecksGroupObject, ChecksGroup);
		
		CheckGroupParent        = AccountingAudit.CheckByID(ChecksGroup.GroupID);
		ChecksGroupObject.Parent = CheckGroupParent;
		
		If ValueIsFilled(CheckGroupParent) Then
			ChecksGroupObject.AccountingChecksContext = Common.ObjectAttributeValue(CheckGroupParent, "AccountingChecksContext");
		Else
			ChecksGroupObject.AccountingChecksContext = ChecksGroup.AccountingChecksContext;
		EndIf;
		
		InfobaseUpdate.WriteData(ChecksGroupObject);
		
	EndDo;
	
	Query = New Query(
	"SELECT
	|	ChecksGroups.ID AS ID,
	|	ChecksGroups.Description AS Description
	|INTO TT_ChecksGroups
	|FROM
	|	&ChecksGroups AS ChecksGroups
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	AccountingCheckRules.Ref AS Ref
	|FROM
	|	Catalog.AccountingCheckRules AS AccountingCheckRules
	|		LEFT JOIN TT_ChecksGroups AS TT_ChecksGroups
	|		ON AccountingCheckRules.ID = TT_ChecksGroups.ID
	|WHERE
	|	TT_ChecksGroups.Description IS NULL
	|	AND AccountingCheckRules.IsFolder
	|	AND NOT AccountingCheckRules.Predefined
	|	AND NOT AccountingCheckRules.AccountingCheckIsChanged");
	
	Query.TempTablesManager = New TempTablesManager;
	Query.SetParameter("ChecksGroups", ChecksGroups);
	
	Result = Query.Execute().Select();
	While Result.Next() Do
		ChecksGroupObject = Result.Ref.GetObject();
		ChecksGroupObject.SetDeletionMark(True);
	EndDo;
	
	Query.TempTablesManager.Close();
	
EndProcedure

Procedure AddChecks(Checks)
	
	For Each CheckSSL In Checks Do
		
		CheckByID = AccountingAudit.CheckByID(CheckSSL.ID);
		If Not ValueIsFilled(CheckByID) Then
			
			CheckObject = Catalogs.AccountingCheckRules.CreateItem();
			CheckObject.RunMethod = Enums.CheckMethod.ByCommonSchedule;
			CheckObject.IssueSeverity = Enums.AccountingIssueSeverity.Error;
			
		Else
			
			If CheckByID.AccountingCheckIsChanged Then
				Continue;
			EndIf;
			
			CheckObject = CheckByID.GetObject();
			If CheckByID.DeletionMark Then
				CheckObject.SetDeletionMark(False);
			EndIf;
			
		EndIf;
		
		FillPropertyValues(CheckObject, CheckSSL);
		
		CheckParent        = AccountingAudit.CheckByID(CheckSSL.GroupID);
		CheckObject.Parent = CheckParent;
		
		If ValueIsFilled(CheckParent) Then
			CheckObject.AccountingChecksContext = Common.ObjectAttributeValue(CheckParent, "AccountingChecksContext");
		Else
			CheckObject.AccountingChecksContext = CheckSSL.AccountingChecksContext;
		EndIf;
		
		CheckObject.Use = Not CheckSSL.Disabled;
		
		If ValueIsFilled(CheckSSL.IssuesLimit) Then
			CheckObject.IssuesLimit = CheckSSL.IssuesLimit;
		Else
			CheckObject.IssuesLimit = 1000;
		EndIf;
		
		If ValueIsFilled(CheckSSL.CheckStartDate) Then
			CheckObject.CheckStartDate = CheckSSL.CheckStartDate;
		EndIf;
		
		InfobaseUpdate.WriteData(CheckObject);
	EndDo;
	
	Query = New Query(
	"SELECT
	|	Validation.ID AS ID,
	|	Validation.Description AS Description
	|INTO TT_Checks
	|FROM
	|	&Validation AS Validation
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	AccountingCheckRules.Ref AS Ref
	|FROM
	|	Catalog.AccountingCheckRules AS AccountingCheckRules
	|		LEFT JOIN TT_Checks AS TT_Checks
	|		ON AccountingCheckRules.ID = TT_Checks.ID
	|WHERE
	|	TT_Checks.Description IS NULL
	|	AND NOT AccountingCheckRules.IsFolder
	|	AND NOT AccountingCheckRules.Predefined
	|	AND NOT AccountingCheckRules.AccountingCheckIsChanged");
	
	Query.TempTablesManager = New TempTablesManager;
	Query.SetParameter("Validation", Checks);
	
	Result = Query.Execute().Select();
	While Result.Next() Do
		CheckObject = Result.Ref.GetObject();
		CheckObject.SetDeletionMark(True);
	EndDo;
	
	Query.TempTablesManager.Close();
	
EndProcedure

Procedure UpdateCatalogAuxiliaryDataByConfigurationChanges()
	
	SetPrivilegedMode(True);
	AccountingChecks = AccountingAuditInternalCached.AccountingChecks();
	SpecifiedItemsUniquenessCheck(AccountingChecks.ChecksGroups, AccountingChecks.Validation);
	AddChecksGroups(AccountingChecks.ChecksGroups);
	AddChecks(AccountingChecks.Validation);
	
EndProcedure

Procedure SpecifiedItemsUniquenessCheck(ChecksGroups, Checks)
	
	Query = New Query(
	"SELECT
	|	Description AS Description,
	|	ID AS ID
	|INTO TT_ChecksGroups
	|FROM
	|	&ChecksGroups AS ChecksGroups
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Description AS Description,
	|	ID AS ID
	|INTO TT_Checks
	|FROM
	|	&Validation AS Validation
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TT_ChecksGroups.Description AS Description,
	|	TT_ChecksGroups.ID AS ID
	|INTO TT_CommonTable
	|FROM
	|	TT_ChecksGroups AS TT_ChecksGroups
	|
	|UNION ALL
	|
	|SELECT
	|	TT_Checks.Description,
	|	TT_Checks.ID
	|FROM
	|	TT_Checks AS TT_Checks
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TT_CommonTable.ID AS ID
	|INTO TT_GroupByID
	|FROM
	|	TT_CommonTable AS TT_CommonTable
	|
	|GROUP BY
	|	TT_CommonTable.ID
	|
	|HAVING
	|	COUNT(TT_CommonTable.ID) > 1
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TT_CommonTable.Description AS Description,
	|	TT_CommonTable.ID AS ID
	|FROM
	|	TT_GroupByID AS TT_GroupByID
	|		INNER JOIN TT_CommonTable AS TT_CommonTable
	|		ON TT_GroupByID.ID = TT_CommonTable.ID
	|
	|ORDER BY
	|	ID
	|TOTALS BY
	|	ID");
	
	Query.TempTablesManager = New TempTablesManager;
	Query.SetParameter("ChecksGroups", ChecksGroups);
	Query.SetParameter("Validation",       Checks);
	
	ExceptionText = "";
	Result       = Query.Execute().Select(QueryResultIteration.ByGroups);
	
	While Result.Next() Do
		
		ExceptionText = ExceptionText + ?(ValueIsFilled(ExceptionText), Chars.LF, "")
			+ StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = 'Дублирующийся идентификатор: ""%1""'; en = 'Duplicate ID: ""%1""'; pl = 'Duplicate ID: ""%1""';de = 'Duplicate ID: ""%1""';ro = 'Duplicate ID: ""%1""';tr = 'Duplicate ID: ""%1""'; es_ES = 'Duplicate ID: ""%1""'"), Result.ID);
			
		DetailedResult = Result.Select();
		While DetailedResult.Next() Do
			ExceptionText = ExceptionText + Chars.LF + "- " + DetailedResult.Description;
		EndDo;
		
	EndDo;
	
	Query.TempTablesManager.Close();
	
	If ValueIsFilled(ExceptionText) Then
		Raise StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = 'В процедуре КонтрольВеденияУчетаПереопределяемый.ПриОпределенииПроверок у следующих проверок совпадают идентификаторы:
		|%1'; 
		|en = 'In AccountingAuditOverridable.OnDefineChecks procedure, the following checks have identical IDs:
		|%1'; 
		|pl = 'In AccountingAuditOverridable.OnDefineChecks procedure, the following checks have identical IDs:
		|%1';
		|de = 'In AccountingAuditOverridable.OnDefineChecks procedure, the following checks have identical IDs:
		|%1';
		|ro = 'In AccountingAuditOverridable.OnDefineChecks procedure, the following checks have identical IDs:
		|%1';
		|tr = 'In AccountingAuditOverridable.OnDefineChecks procedure, the following checks have identical IDs:
		|%1'; 
		|es_ES = 'In AccountingAuditOverridable.OnDefineChecks procedure, the following checks have identical IDs:
		|%1'"), ExceptionText);
	EndIf;
	
EndProcedure

// Generates hash of checks table to compare with the previous hash stored in the infobase 
// (InformationRegister.ApplicationParameters).
// Hash is generated as follows: check tables are generated (future items of the
// AccountingCheckRules catalog) with check groups (future groups of the specified catalog) as of 
// the current moment (the moment of infobase update). Next, an array of structures is generated, on 
// the basis of which a fixed map is calculated, from which, in turn, the hash sum is calculated.
//
// Returns:
//     FixedMap - a hash sum.
//
Function ChecksHash()
	
	ChecksData = New Map;
	
	AccountingChecks = AccountingAuditInternalCached.AccountingChecks();
	HashArray           = New Array;
	
	For Each AccountingChecksItem In AccountingChecks Do
		
		ChecksItemValue = AccountingChecksItem.Value;
		ChecksItemColumns  = ChecksItemValue.Columns;
		
		For Each ChecksItemRow In ChecksItemValue Do
			
			StringStructure = New Structure;
			
			For Each ChecksItemColumn In ChecksItemColumns Do
				StringStructure.Insert(ChecksItemColumn.Name, ChecksItemRow[ChecksItemColumn.Name]);
			EndDo;
			
			If StringStructure.Count() > 0 Then
				HashArray.Add(StringStructure);
			EndIf;
			
		EndDo;
		
	EndDo;
	
	ChecksData.Insert(Common.CheckSumString(New FixedArray(HashArray)));
	
	Return New FixedMap(ChecksData);
	
EndFunction

#EndRegion

#Region ChecksToSupply

// Checks reference integrity.
//
Procedure CheckReferenceIntegrity(CheckSSL, CheckParameters) Export
	
	CheckedRefs = New Map;
	
	CheckExecutionParameters = ReadParameters(CheckParameters.CheckExecutionParameters);
	If CheckExecutionParameters <> Undefined Then
		If CheckExecutionParameters.ValidationArea = "Registers" Then
			FindDeadRefsInRegisters(CheckExecutionParameters.MetadataObject, CheckParameters, CheckedRefs);
		Else
			FindDeadRefs(CheckExecutionParameters.MetadataObject, CheckParameters, CheckedRefs);
		EndIf;
		
		Return;
	EndIf;
	
	For Each MetadataKind In MetadataObjectsRefKinds() Do
		For Each MetadataObject In MetadataKind Do
			FindDeadRefs(MetadataObject, CheckParameters, CheckedRefs);
		EndDo;
	EndDo;
	
	For Each MetadataKind In RegistersAsMetadataObjects() Do
		For Each MetadataObject In MetadataKind Do
			FindDeadRefsInRegisters(MetadataObject, CheckParameters, CheckedRefs);
		EndDo;
	EndDo;
	
EndProcedure

// Checks filling of required attributes.
//
Procedure CheckUnfilledRequiredAttributes(CheckSSL, CheckParameters) Export
	
	CheckExecutionParameters = ReadParameters(CheckParameters.CheckExecutionParameters);
	If CheckExecutionParameters <> Undefined Then
		If CheckExecutionParameters.ValidationArea = "Registers" Then
			FindNotFilledRequiredAttributesInRegisters(CheckExecutionParameters.MetadataObject, CheckParameters);
		Else
			FindNotFilledRequiredAttributes(CheckExecutionParameters.MetadataObject, CheckParameters);
		EndIf;
		
		Return;
	EndIf;
	
	For Each MetadataKind In MetadataObjectsRefKinds() Do
		
		For Each MetadataObject In MetadataKind Do
			If IsSharedMetadataObject(MetadataObject.FullName()) Then
				Continue;
			EndIf;
			If Not Common.MetadataObjectAvailableByFunctionalOptions(MetadataObject) Then
				Continue;
			EndIf;
			FindNotFilledRequiredAttributes(MetadataObject, CheckParameters);
		EndDo;
		
	EndDo;
	
	For Each MetadataKind In RegistersAsMetadataObjects() Do
		For Each MetadataObject In MetadataKind Do
			If IsSharedMetadataObject(MetadataObject.FullName()) Then
				Continue;
			EndIf;
			If Not Common.MetadataObjectAvailableByFunctionalOptions(MetadataObject) Then
				Continue;
			EndIf;
			FindNotFilledRequiredAttributesInRegisters(MetadataObject, CheckParameters);
		EndDo;
	EndDo;
	
EndProcedure

// Performs a check for circular references.
//
Procedure CheckCircularRefs(CheckSSL, CheckParameters) Export
	
	For Each MetadataKind In MetadataObjectsRefKinds() Do
		For Each MetadataObject In MetadataKind Do
			If IsSharedMetadataObject(MetadataObject.FullName()) Then
				Continue;
			EndIf;
			If Not HasHierarchy(MetadataObject.StandardAttributes) Then
				Continue;
			EndIf;
			FindCircularRefs(MetadataObject, CheckParameters);
		EndDo;
	EndDo;
	
EndProcedure

Procedure FixInfiniteLoopInBackgroundJob(Val CheckParameters, StorageAddress = Undefined) Export
	
	CheckSSL = CheckByID(CheckParameters.CheckID);
	If Not ValueIsFilled(CheckSSL) Then
		Return;
	EndIf;
	
	CorrectCircularRefsProblem(CheckSSL);
	
EndProcedure

// Checks if there are missing predefined items.
//
Procedure CheckMissingPredefinedItems(CheckSSL, CheckParameters) Export
	
	// Clearing the cache before calling the CommonClientServer.PredefinedItem function.
	RefreshReusableValues();
	
	MetadataObjectKinds = New Array;
	MetadataObjectKinds.Add(Metadata.Catalogs);
	MetadataObjectKinds.Add(Metadata.ChartsOfCharacteristicTypes);
	MetadataObjectKinds.Add(Metadata.ChartsOfAccounts);
	MetadataObjectKinds.Add(Metadata.ChartsOfCalculationTypes);
	
	For Each MetadataKind In MetadataObjectKinds Do
		For Each MetadataObject In MetadataKind Do
			If MetadataObject.PredefinedDataUpdate = Metadata.ObjectProperties.PredefinedDataUpdate.DontAutoUpdate Then
				Continue;
			EndIf;
			FindMissingPredefinedItems(MetadataObject, CheckParameters);
		EndDo;
	EndDo;
	
EndProcedure

// Checks if there are duplicate predefined items.
//
Procedure CheckDuplicatePredefinedItems(CheckSSL, CheckParameters) Export
	
	MetadataObjectKinds = New Array;
	MetadataObjectKinds.Add(Metadata.Catalogs);
	MetadataObjectKinds.Add(Metadata.ChartsOfCharacteristicTypes);
	MetadataObjectKinds.Add(Metadata.ChartsOfAccounts);
	MetadataObjectKinds.Add(Metadata.ChartsOfCalculationTypes);
	
	For Each MetadataKind In MetadataObjectKinds Do
		
		If MetadataKind.Count() = 0 Then
			Continue;
		EndIf;
		
		FindPredefinedItemsDuplicates(MetadataKind, CheckParameters);
		
	EndDo;
	
EndProcedure

// Checks if there are missing predefined exchange plan nodes.
//
Procedure CheckPredefinedExchangePlanNodeAvailability(CheckSSL, CheckParameters) Export
	
	MetadataExchangePlans = Metadata.ExchangePlans;
	For Each MetadataExchangePlan In MetadataExchangePlans Do
		
		If ExchangePlans[MetadataExchangePlan.Name].ThisNode() <> Undefined Then
			Continue;
		EndIf;
		
		Issue = IssueDetails(Common.MetadataObjectID(MetadataExchangePlan.FullName()), CheckParameters);
		Issue.IssueSummary = StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = 'В плане обмена ""%1"" отсутствует предопределенный узел (ЭтотУзел() = Неопределено).'; en = 'Predefined node is missing from exchange plan ""%1"" (ThisNode() = Undefined).'; pl = 'Predefined node is missing from exchange plan ""%1"" (ThisNode() = Undefined).';de = 'Predefined node is missing from exchange plan ""%1"" (ThisNode() = Undefined).';ro = 'Predefined node is missing from exchange plan ""%1"" (ThisNode() = Undefined).';tr = 'Predefined node is missing from exchange plan ""%1"" (ThisNode() = Undefined).'; es_ES = 'Predefined node is missing from exchange plan ""%1"" (ThisNode() = Undefined).'"), MetadataExchangePlan.Name);
		WriteIssue(Issue, CheckParameters);
		
	EndDo;
	
EndProcedure

#EndRegion

#Region UserErrorsIndication

// Places an error indicator group on the managed form.
//
// Parameters:
//  ManagedForm     - ManagedForm - an object form, on which you need to place the indicator group.
//  NamesUniqueKey - String - a string unique key of items added to a form. It is required to 
//                         minimize the risks of intersection with existing items.
//  GroupParentName    - String, Undefined - a string name of the form group, in whose context an 
//                         indicator group is to be placed. If undefined, the managed form acts as 
//                         the context. If the form does not have such an item, an exception is 
//                         generated.
//  OutputAtBottom        - Boolean - defines the location of the added group that informs of an 
//                         error. If set to True, the group will be added to the end of the 
//                         collection of the parent group subordinate items.
//                          Otherwise, the group will be located right behind the main object form 
//                         command bar.
//
Function PlaceErrorIndicatorGroup(ManagedForm, NamesUniqueKey, GroupParentName = Undefined, OutputAtBottom = False) Export
	
	FormAllItems = ManagedForm.Items;
	
	If GroupParentName = Undefined Then
		PlaceContext = ManagedForm;
	Else
		GroupParent = FormAllItems.Find(GroupParentName);
		If GroupParent = Undefined Then
			Raise StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = 'Не найдена группа формы: ""%1""'; en = 'Form group not found: ""%1""'; pl = 'Form group not found: ""%1""';de = 'Form group not found: ""%1""';ro = 'Form group not found: ""%1""';tr = 'Form group not found: ""%1""'; es_ES = 'Form group not found: ""%1""'"), GroupParentName);
		Else
			PlaceContext = GroupParent;
		EndIf;
	EndIf;
	
	ErrorIndicatorGroup = FormAllItems.Add("ErrorIndicatorGroup_" + NamesUniqueKey, Type("FormGroup"), PlaceContext);
	ErrorIndicatorGroup.Type                      = FormGroupType.UsualGroup;
	ErrorIndicatorGroup.ShowTitle      = False;
	ErrorIndicatorGroup.Group              = ChildFormItemsGroup.AlwaysHorizontal;
	ErrorIndicatorGroup.HorizontalStretch = True;
	ErrorIndicatorGroup.BackColor                 = StyleColors.MasterFieldBackground;
	
	ContextSubordinateItems = PlaceContext.ChildItems;
	If OutputAtBottom Then
		FormAllItems.Move(ErrorIndicatorGroup, PlaceContext);
	Else
		If ContextSubordinateItems.Count() > 0 Then
			FormAllItems.Move(ErrorIndicatorGroup, PlaceContext, ContextSubordinateItems.Get(0));
		EndIf;
	EndIf;
	
	Return ErrorIndicatorGroup;
	
EndFunction

// Fills the error indicator group that was placed earlier with items that identify the presence of 
//   errors and allow you to go to the report on these errors.
//
// Parameters
//  ManagedForm             - ManagedForm - an object form where the indicator group is placed.
//  ErrorIndicatorGroup       - FormGroup - a managed form group, on which the decoration items will 
//                                 be located, which will identify the presence of errors with the 
//                                 ability to go to the report.
//  NamesUniqueKey         - String - a string unique key of added to the form items. It is required 
//                                 to minimize the risks of intersection with existing items.
//  IssuesIndicatorPicture    - Picture, Undefined - a picture that identifies issues that the current object has.
//                                 Can be overridden by the end developer - adding a parameter when calling is enough.
//  CommonStringIndicator         - FormattedString - a common string that indicates the presence of errors. 
//                                 It consists of an explanatory text and a hyperlink that opens the report on the object issues.
//
Procedure FillErrorIndicatorGroup(ManagedForm, ErrorIndicatorGroup, NamesUniqueKey,
	MainRowIndicator, IssuesIndicatorPicture = Undefined) Export
	
	ManagedFormItems = ManagedForm.Items;
	
	ErrorIndicatorPicture = ManagedFormItems.Add("DecorationPicture_" + NamesUniqueKey, Type("FormDecoration"), ErrorIndicatorGroup);
	ErrorIndicatorPicture.Type            = FormDecorationType.Picture;
	ErrorIndicatorPicture.Picture       = ?(IssuesIndicatorPicture = Undefined, PictureLib.Warning, IssuesIndicatorPicture);
	ErrorIndicatorPicture.PictureSize = PictureSize.RealSize;
	
	LabelDecoration = ManagedFormItems.Add("DecorationLabel_" + NamesUniqueKey, Type("FormDecoration"), ErrorIndicatorGroup);
	LabelDecoration.Type                   = FormDecorationType.Label;
	LabelDecoration.Title             = MainRowIndicator;
	LabelDecoration.VerticalAlign = ItemVerticalAlign.Center;
	LabelDecoration.SetAction("URLProcessing", "Attachable_OpenIssueReport");
	
EndProcedure

// Generates a common string that indicates the existence of errors. It consists of an explanatory 
// text and a hyperlink that opens the report on the object issues.
//
// Parameters
//  ManagedForm             - ManagedForm - an object form where the indicator group is placed.
//  ObjectRef               - AnyRef - a reference to the object, by which errors were found.
//  ObjectIssuesCount   - Number - a quantity of the found object issues.
//  IssuesIndicatorNote - String, Undefined - a string that identifies issues that the current object has.
//                                 Can be overridden by the end developer - adding a parameter when calling is enough.
//  IssuesIndicatorHyperlink - String, Undefined - the string representing the hyperlink that opens 
//                                 and generates a report on the issues of the current object.
//
Function GenerateCommonStringIndicator(ManagedForm, ObjectRef, IssuesCountByObject,
	IssuesIndicatorNote = Undefined, IssuesIndicatorHyperlink = Undefined) Export
	
	TextRef = "Main";
	
	If IssuesIndicatorNote <> Undefined Then
		NoteLabel = IssuesIndicatorNote
	Else
		NoteLabel = StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = 'С этим %1'; en = 'This %1'; pl = 'This %1';de = 'This %1';ro = 'This %1';tr = 'This %1'; es_ES = 'This %1'"), ObjectPresentationByType(ObjectRef));
	EndIf;
	
	If IssuesIndicatorHyperlink <> Undefined Then
		Hyperlink = IssuesIndicatorHyperlink;
	Else
		Hyperlink = StringFunctionsClientServer.SubstituteParametersToString(NStr("ru='есть проблемы (%1)'; en = 'has issues (%1)'; pl = 'has issues (%1)';de = 'has issues (%1)';ro = 'has issues (%1)';tr = 'has issues (%1)'; es_ES = 'has issues (%1)'"), Format(IssuesCountByObject, "NG=0"));
	EndIf;
	
	Return New FormattedString(NoteLabel + " ", New FormattedString(Hyperlink, , , , TextRef));
	
EndFunction

// See AccountingAuditOverridable.OnDetermineIndicationGroupParameters. 
Procedure OnDetermineIndicationGroupParameters(IndicationGroupParameters, RefType) Export
	
	IndicationGroupParameters.Insert("GroupParentName", Undefined);
	IndicationGroupParameters.Insert("OutputAtBottom",     False);
	
EndProcedure

// See AccountingAuditOverridable.OnDetermineIndicationColumnParameters. 
Procedure OnDetermineIndicatiomColumnParameters(IndicationColumnParameters, FullName) Export
	
	IndicationColumnParameters.Insert("TitleLocation", FormItemTitleLocation.None);
	IndicationColumnParameters.Insert("Width",             2);
	IndicationColumnParameters.Insert("OutputLast",  False);
	
EndProcedure

#EndRegion

#Region ChecksExecute

// See the AccountingAudit.RunCheck. 
Procedure ExecuteCheck(CheckSSL, CheckExecutionParameters = Undefined) Export
	
	If TypeOf(CheckSSL) = Type("String") Then
		CheckToExecute = AccountingAudit.CheckByID(CheckSSL);
	Else
		CheckToExecute = CheckSSL;
	EndIf;
	
	If Not InfobaseUpdate.ObjectProcessed(CheckToExecute).Processed Then
		Return;
	EndIf;
	
	CheckExecutionParametersSpecified = CheckExecutionParameters <> Undefined;
	CheckParameters = PrepareCheckParameters(CheckToExecute, CheckExecutionParameters);
	If CheckRunning(CheckParameters.ScheduledJobID) Then
		Return;
	EndIf;
	
	AccountingChecks = AccountingAuditInternalCached.AccountingChecks();
	Checks             = AccountingChecks.Validation;
	CheckString       = Checks.Find(CheckParameters.ID, "ID");
	If CheckString = Undefined Then 
		Raise StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Проверка ведения учета с идентификатором ""%1"" не существует (см. КонтрольВеденияУчетаПереопределяемый.ПриОпределенииПроверок)'; en = 'The accounting check with ID %1 does not exist (see AccountingAuditOverridable.OnDefineChecks).'; pl = 'The accounting check with ID %1 does not exist (see AccountingAuditOverridable.OnDefineChecks).';de = 'The accounting check with ID %1 does not exist (see AccountingAuditOverridable.OnDefineChecks).';ro = 'The accounting check with ID %1 does not exist (see AccountingAuditOverridable.OnDefineChecks).';tr = 'The accounting check with ID %1 does not exist (see AccountingAuditOverridable.OnDefineChecks).'; es_ES = 'The accounting check with ID %1 does not exist (see AccountingAuditOverridable.OnDefineChecks).'"), 
				CheckParameters.ID);
	EndIf;
		
	If CheckString.NoCheckHandler Then
		Return;
	EndIf;
	
	If Not CheckExecutionParametersSpecified Then
		ClearPreviousCheckResults(CheckToExecute, CheckParameters.CheckExecutionParameters);
	EndIf;
	
	ModulePerformanceMonitor = Undefined;
	If Common.SubsystemExists("StandardSubsystems.PerformanceMonitor") Then
		ModulePerformanceMonitor = Common.CommonModule("PerformanceMonitor");
		MeasurementDetails = ModulePerformanceMonitor.StartTimeConsumingOperationMeasurement(CheckParameters.ID);
	EndIf;
	
	HandlerParameters = New Array;
	HandlerParameters.Add(CheckToExecute);
	HandlerParameters.Add(CheckParameters);
	Common.ExecuteConfigurationMethod(CheckString.CheckHandler, HandlerParameters);
	
	If ModulePerformanceMonitor <> Undefined Then
		ModulePerformanceMonitor.EndTimeConsumingOperationMeasurement(MeasurementDetails, 0);
	EndIf;
	
EndProcedure

// AccountingCheck scheduled job handler. Designed to process the background startup of application 
// checks.
//
//   Parameters:
//       ScheduledJobID - String, Undefined - a string ID of the scheduled job.
//
Procedure CheckAccounting(ScheduledJobID = Undefined) Export
	
	Common.OnStartExecuteScheduledJob(Metadata.ScheduledJobs.AccountingCheck);
	
	If ScheduledJobID <> Undefined Then
		
		CheckParameters = CheckByScheduledJobIDParameters(ScheduledJobID);
		If CheckParameters <> Undefined Then
			ExecuteCheck(CheckParameters.ID);
		EndIf;
		
	Else
		
		Query = New Query(
		"SELECT
		|	AccountingCheckRules.ID AS ID
		|FROM
		|	Catalog.AccountingCheckRules AS AccountingCheckRules
		|WHERE
		|	AccountingCheckRules.RunMethod = VALUE(Enum.CheckMethod.ByCommonSchedule)
		|	AND AccountingCheckRules.Use");
		
		Result = Query.Execute().Select();
		While Result.Next() Do
			ExecuteCheck(Result.ID);
		EndDo;
		
	EndIf;
	
EndProcedure

// Executes several checks by the passed parameters.
//
// Parameters:
//   CheckParameters - Array - items like Structure, see parameter.
//                                CheckParameters in AccountingAudit.IssueDetails
//   StorageAddress - String - a temporary storage address to place a result.
//
Procedure ExecuteChecksInBackgroundJob(Val CheckParameters, StorageAddress = Undefined) Export
	
	ParametersArray = CheckParameters.ParametersArray;
	For Each CheckParameters In ParametersArray Do
		ExecuteCheck(CheckParameters.ID);
	EndDo;
	
EndProcedure

// See AccountingAuditOverridable.CheckByID. 
Function CheckByID(ID) Export
	
	Query = New Query(
	"SELECT TOP 1
	|	AccountingCheckRules.Ref AS CheckSSL
	|FROM
	|	Catalog.AccountingCheckRules AS AccountingCheckRules
	|WHERE
	|	AccountingCheckRules.ID = &ID
	|	AND NOT AccountingCheckRules.DeletionMark");
	
	Query.SetParameter("ID", ID);
	Result = Query.Execute().Select();
	
	If Not Result.Next() Then
		Return Catalogs.AccountingCheckRules.EmptyRef();
	Else
		Return Result.CheckSSL;
	EndIf;
	
EndFunction

// See AccountingAuditOverridable.PerformChecksInContext. 
Function ChecksByContext(AccountingChecksContext) Export
	
	Query = New Query(
	"SELECT
	|	""SelectionParentlessItemsConsideringContext"" AS QueryPurpose,
	|	VALUE(Catalog.AccountingCheckRules.EmptyRef) AS Parent,
	|	AccountingCheckRules.Ref AS CheckSSL
	|FROM
	|	Catalog.AccountingCheckRules AS AccountingCheckRules
	|WHERE
	|	NOT AccountingCheckRules.IsFolder
	|	AND AccountingCheckRules.Use
	|	AND AccountingCheckRules.Parent = VALUE(Catalog.AccountingCheckRules.EmptyRef)
	|	AND AccountingCheckRules.AccountingChecksContext = &AccountingChecksContext
	|
	|UNION ALL
	|
	|SELECT
	|	""SelectGroupsConsideringContext"",
	|	AccountingCheckRules.Parent,
	|	AccountingCheckRules.Ref
	|FROM
	|	Catalog.AccountingCheckRules AS AccountingCheckRules
	|WHERE
	|	AccountingCheckRules.IsFolder
	|	AND AccountingCheckRules.AccountingChecksContext = &AccountingChecksContext
	|
	|UNION ALL
	|
	|SELECT
	|	""SelectionItemsWithParentsIgnoringContext"",
	|	AccountingCheckRules.Parent,
	|	AccountingCheckRules.Ref
	|FROM
	|	Catalog.AccountingCheckRules AS AccountingCheckRules
	|WHERE
	|	NOT AccountingCheckRules.IsFolder
	|	AND AccountingCheckRules.Use
	|	AND AccountingCheckRules.Parent <> VALUE(Catalog.AccountingCheckRules.EmptyRef)");
	
	Query.SetParameter("AccountingChecksContext", AccountingChecksContext);
	AllChecks = Query.Execute().Unload();
	
	Result  = New Array;
	ParentChecks = AllChecks.Copy(AllChecks.FindRows(
		New Structure("QueryPurpose", "SelectGroupsConsideringContext")), "Parent, CheckSSL");
	
	For Each ResultString In AllChecks Do
		
		If ResultString.QueryPurpose = "SelectionParentlessItemsConsideringContext"
			Or (ResultString.QueryPurpose = "SelectionItemsWithParentsIgnoringContext"
			AND ParentChecks.Find(ResultString.Parent) <> Undefined) Then
			Result.Add(ResultString.CheckSSL);
		EndIf;
		
	EndDo;
	
	Return CommonClientServer.CollapseArray(Result);
	
EndFunction

// See AccountingAudit.CheckExecutionParameters. 
Function CheckExecutionParameters(Val Property1, Val Property2 = Undefined, Val Property3 = Undefined,
	Val Property4 = Undefined, Val Property5 = Undefined, Val AdditionalProperties = Undefined) Export
	
	PropertiesCount             = PropertiesCount();
	LastValuableParameterFound = False;
	
	For Index = 2 To PropertiesCount Do
		If Index = 2 Then
			ParameterValue = Property2;
		ElsIf Index = 3 Then
			ParameterValue = Property3;
		ElsIf Index = 4 Then
			ParameterValue = Property4;
		ElsIf Index = 5 Then
			ParameterValue = Property5;
		EndIf;
		If ParameterValue = Undefined Then
			If Not LastValuableParameterFound Then
				LastValuableParameterFound = True;
			EndIf;
		Else
			If LastValuableParameterFound Then
				Raise NStr("ru = 'Параметры выполнения проверки заданы не по порядку в КонтрольВеденияУчета.ПараметрыВыполненияПроверки.'; en = 'The check parameters in AccountingAudit.CheckExecutionParameters are not in correct order.'; pl = 'The check parameters in AccountingAudit.CheckExecutionParameters are not in correct order.';de = 'The check parameters in AccountingAudit.CheckExecutionParameters are not in correct order.';ro = 'The check parameters in AccountingAudit.CheckExecutionParameters are not in correct order.';tr = 'The check parameters in AccountingAudit.CheckExecutionParameters are not in correct order.'; es_ES = 'The check parameters in AccountingAudit.CheckExecutionParameters are not in correct order.'");
			EndIf;
		EndIf;
	EndDo;
	
	If AdditionalProperties <> Undefined AND Property5 = Undefined Then
		Raise NStr("ru = 'Параметры выполнения проверки заданы не по порядку в КонтрольВеденияУчета.ПараметрыВыполненияПроверки.'; en = 'The check parameters in AccountingAudit.CheckExecutionParameters are not in correct order.'; pl = 'The check parameters in AccountingAudit.CheckExecutionParameters are not in correct order.';de = 'The check parameters in AccountingAudit.CheckExecutionParameters are not in correct order.';ro = 'The check parameters in AccountingAudit.CheckExecutionParameters are not in correct order.';tr = 'The check parameters in AccountingAudit.CheckExecutionParameters are not in correct order.'; es_ES = 'The check parameters in AccountingAudit.CheckExecutionParameters are not in correct order.'");
	EndIf;
	
	AllParameters = New Array;
	AllParameters.Add(Property1);
	For Index = 2 To PropertiesCount Do
		
		If Index = 2 Then
			PropertyValue = Property2;
		ElsIf Index = 3 Then
			PropertyValue = Property3;
		ElsIf Index = 4 Then
			PropertyValue = Property4;
		ElsIf Index = 5 Then
			PropertyValue = Property5;
		EndIf;
		If PropertyValue = Undefined Then
			Break;
		EndIf;
		AllParameters.Add(PropertyValue);
		
	EndDo;
	
	If AdditionalProperties <> Undefined Then
		CommonClientServer.SupplementArray(AllParameters, AdditionalProperties); 
	EndIf;
	
	Return CheckExecutionParametersFromArray(AllParameters);
	
EndFunction

Function CheckExecutionParametersFromArray(Val Parameters)
	
	CheckKindDescription = "";
	Index = 1;
	Result = New Structure;
	
	For Each CurrentParameter In Parameters Do
		
		CommonClientServer.CheckParameter("AccountingAudit.CheckExecutionParameters", 
			"Property" + Format(Index, "NG=0"), CurrentParameter, ExpectedPropertiesTypesOfChecksKinds());
			
		CheckKindDescription = CheckKindDescription + ?(ValueIsFilled(CheckKindDescription), ", ", "") 
			+ Format(CurrentParameter, "DLF=D; NG=0");
		Result.Insert("Property" + Format(Parameters.Find(CurrentParameter) + 1, "NG=0"), CurrentParameter);
		
		Index = Index + 1;
		
	EndDo;
	
	Result.Insert("Description", CheckKindDescription);
	Return Result;

EndFunction

#EndRegion

#Region RefIntegrityControl

Procedure FindDeadRefs(MetadataObject, CheckParameters, CheckedRefs)
	
	RefAttributes = ObjectRefAttributes(MetadataObject);
	If RefAttributes.Count() = 0 Then
		Return;
	EndIf;
	
	Query = New Query;
	HasRestrictionByDate = ValueIsFilled(CheckParameters.CheckStartDate) 
		AND (Common.IsDocument(MetadataObject) Or Common.IsTask(MetadataObject) 
			Or Common.IsBusinessProcess(MetadataObject));
			
	If HasRestrictionByDate Then
		QueryText = 
		"SELECT TOP 1000
		|	MetadataObject.Ref AS ObjectWithIssue,
		|	&RefAttributes
		|	,&TabularSectionsAttributes
		|FROM
		|	&MetadataObject AS MetadataObject
		|WHERE
		|	MetadataObject.Ref > &Ref
		|	AND MetadataObject.Date > &CheckStartDate
		|
		|ORDER BY
		|	MetadataObject.Ref";
		Query.SetParameter("CheckStartDate", CheckParameters.CheckStartDate);
	Else
		QueryText = 
		"SELECT TOP 1000
		|	MetadataObject.Ref AS ObjectWithIssue,
		|	&RefAttributes
		|	,&TabularSectionsAttributes
		|FROM
		|	&MetadataObject AS MetadataObject
		|WHERE
		|	MetadataObject.Ref > &Ref
		|
		|ORDER BY
		|	MetadataObject.Ref";
	EndIf;
	
	QueryText = StrReplace(QueryText, "&MetadataObject", MetadataObject.FullName());
	QueryText = StrReplace(QueryText, "&RefAttributes", StrConcat(RefAttributes, ","));
	
	ObjectTabularSectionsAttributes = ObjectTabularSectionsRefAttributes(MetadataObject);
	If ObjectTabularSectionsAttributes.Count() > 0 Then
		Template = "MetadataObject.%1.(%2) AS %1";
		QueryTabularSections = "";
		For Each TabularSectionAttributes In ObjectTabularSectionsAttributes Do
			TabularSectionName    = TabularSectionAttributes.Key;
			AttributesString      = StrConcat(TabularSectionAttributes.Value, ",");
			FilledTemplate    = StringFunctionsClientServer.SubstituteParametersToString(
				Template,
				TabularSectionName,
				AttributesString);
			
			If ValueIsFilled(QueryTabularSections) Then
				QueryTabularSections = QueryTabularSections + "," + Chars.LF + FilledTemplate;
			Else
				QueryTabularSections = FilledTemplate;
			EndIf;
		EndDo;
		QueryText = StrReplace(QueryText, "&TabularSectionsAttributes", QueryTabularSections);
	Else
		QueryText = StrReplace(QueryText, ",&TabularSectionsAttributes", "");
	EndIf;
	
	Query.Text = QueryText;
	Query.SetParameter("Ref", "");
	Result = Query.Execute().Unload();
	
	MaximumCount = MaxCheckedRefsCount();
	HasEmployeeResponsible = MetadataObject.Attributes.Find("EmployeeResponsible") <> Undefined;
	
	While Result.Count() > 0 Do
		
		For Each ResultString In Result Do
			
			IssueSummary = "";
			
			ObjectRef = ResultString.ObjectWithIssue;
			For Index = 1 To Result.Columns.Count() - 1 Do
				RefToCheck = ResultString[Index];
				If IsDeadRef(RefToCheck, CheckedRefs) Then
					IssueSummary = IssueSummary + ?(ValueIsFilled(IssueSummary), Chars.LF, "")
						+ StringFunctionsClientServer.SubstituteParametersToString(
							NStr("ru='У объекта ""%1"" в реквизите ""%2"" указана ссылка на несуществующий элемент: ""%3"".'; en = 'Attribute ""%2"" of object ""%1"" references an item that does not exist: ""%3"".'; pl = 'Attribute ""%2"" of object ""%1"" references an item that does not exist: ""%3"".';de = 'Attribute ""%2"" of object ""%1"" references an item that does not exist: ""%3"".';ro = 'Attribute ""%2"" of object ""%1"" references an item that does not exist: ""%3"".';tr = 'Attribute ""%2"" of object ""%1"" references an item that does not exist: ""%3"".'; es_ES = 'Attribute ""%2"" of object ""%1"" references an item that does not exist: ""%3"".'"), 
							ObjectRef, 
							Result.Columns[Index].Name, 
							RefToCheck);
				EndIf;
			EndDo;
			
			If CheckedRefs.Count() >= MaximumCount Then
				CheckedRefs.Clear();
			EndIf;
			
			If ObjectTabularSectionsAttributes.Count() > 0 Then
				For Each TabularSectionAttributes In ObjectTabularSectionsAttributes Do
					
					ObjectTabularSection = ResultString[TabularSectionAttributes.Key];
					CurrentRowNumber = 1;
					
					For Each TSRow In ObjectTabularSection Do
						For Each CurrentColumn In ObjectTabularSection.Columns Do
							TabularSectionAttributeName = CurrentColumn.Name;
							DataToCheck = TSRow[TabularSectionAttributeName];
							If IsDeadRef(DataToCheck, CheckedRefs) Then
								IssueSummary = IssueSummary + ?(ValueIsFilled(IssueSummary), Chars.LF, "")
									+ StringFunctionsClientServer.SubstituteParametersToString(
										NStr("ru = 'У объекта ""%1"" в реквизите ""%2"" табличной части ""%3"" (строка № %4) указана ссылка на несуществующий элемент: ""%5"".'; en = 'Attribute ""%2"" of tabular section ""%3"" of object ""%1"" (line ""%4) references an item that does not exist: ""%5"".'; pl = 'Attribute ""%2"" of tabular section ""%3"" of object ""%1"" (line ""%4) references an item that does not exist: ""%5"".';de = 'Attribute ""%2"" of tabular section ""%3"" of object ""%1"" (line ""%4) references an item that does not exist: ""%5"".';ro = 'Attribute ""%2"" of tabular section ""%3"" of object ""%1"" (line ""%4) references an item that does not exist: ""%5"".';tr = 'Attribute ""%2"" of tabular section ""%3"" of object ""%1"" (line ""%4) references an item that does not exist: ""%5"".'; es_ES = 'Attribute ""%2"" of tabular section ""%3"" of object ""%1"" (line ""%4) references an item that does not exist: ""%5"".'"),
										ObjectRef, TabularSectionAttributeName, StrReplace(TabularSectionAttributes.Key, TabularSectionAttributeName, ""), 
										CurrentRowNumber, DataToCheck);
							EndIf;
						EndDo;
						CurrentRowNumber = CurrentRowNumber + 1;
					EndDo;
					
					If CheckedRefs.Count() >= MaximumCount Then
						CheckedRefs.Clear();
					EndIf;
					
				EndDo;
			EndIf;
			
			If IsBlankString(IssueSummary) Then
				Continue;
			EndIf;
			
			Issue = IssueDetails(ObjectRef, CheckParameters);
			Issue.IssueSummary = NStr("ru = 'Нарушена ссылочная целостность:'; en = 'Reference integrity violation:'; pl = 'Reference integrity violation:';de = 'Reference integrity violation:';ro = 'Reference integrity violation:';tr = 'Reference integrity violation:'; es_ES = 'Reference integrity violation:'") + Chars.LF + IssueSummary;
			If HasEmployeeResponsible Then
				Issue.EmployeeResponsible = Common.ObjectAttributeValue(ObjectRef, "EmployeeResponsible");
			EndIf;
			WriteIssue(Issue, CheckParameters);
			
		EndDo;
		
		Query.SetParameter("Ref", ResultString.ObjectWithIssue);
		Result = Query.Execute().Unload();
		
	EndDo;
	
EndProcedure

Function ObjectRefAttributes(MetadataObject)
	
	Result = New Array;
	
	For Each StandardAttribute In MetadataObject.StandardAttributes Do
		If StandardAttribute.Name = "Ref" Or StandardAttribute.Name = "RoutePoint" Then
			Continue;
		EndIf;
		If Not ContainsRefType(StandardAttribute) Then
			Continue;
		EndIf;
		Result.Add(StandardAttribute.Name);
	EndDo;
	
	For Each Attribute In MetadataObject.Attributes Do
		If ContainsRefType(Attribute) Then
			Result.Add(Attribute.Name);
		EndIf;
	EndDo;
	
	If Common.IsTask(MetadataObject) Then
		
		AddressingAttributes = MetadataObject.AddressingAttributes;
		For Each AddressingAttribute In AddressingAttributes Do
			If ContainsRefType(AddressingAttribute) Then
				Result.Add(AddressingAttribute.Name);
			EndIf;
		EndDo;
		
	EndIf;
	
	Return Result;
	
EndFunction

Function ObjectTabularSectionsRefAttributes(MetadataObject)
	
	Result = New Map;
	For Each TabularSection In MetadataObject.TabularSections Do
		Attributes = New Array;
		For Each TabularSectionAttribute In TabularSection.Attributes Do
			If ContainsRefType(TabularSectionAttribute) Then
				If TabularSectionAttribute.Name = "RoutePoint" Then
					Continue;
				EndIf;
				Attributes.Add(TabularSectionAttribute.Name);
			EndIf;
		EndDo;
		Result.Insert(TabularSection.Name, Attributes);
	EndDo;
	
	Return Result;
	
EndFunction

Function IsDeadRef(DataToCheck, CheckedRefs) 
	
	If Not ValueIsFilled(DataToCheck) Then
		Return False;
	EndIf;
	
	IsDeadRef = CheckedRefs[DataToCheck];
	If IsDeadRef = False Then
		Return False;
	EndIf;
	
	If TypeOf(DataToCheck) = Type("Number") Then
		Return False;
	EndIf;
	
	If TypeOf(DataToCheck) = Type("Boolean") Then
		Return False;
	EndIf;
	
	If TypeOf(DataToCheck) = Type("String") Then
		Return False;
	EndIf;
	
	If TypeOf(DataToCheck) = Type("Date") Then
		Return False;
	EndIf;
	
	If TypeOf(DataToCheck) = Type("UUID") Then
		Return False;
	EndIf;
	
	If TypeOf(DataToCheck) = Type("ValueStorage") Then
		Return False;
	EndIf;
	
	If Not Common.RefTypeValue(DataToCheck) Then
		Return False;
	EndIf;
	
	If IsDeadRef = Undefined Then
		IsDeadRef = Not Common.RefExists(DataToCheck);
		CheckedRefs[DataToCheck] = IsDeadRef;
	EndIf;
	
	Return IsDeadRef;
	
EndFunction

Function MaxCheckedRefsCount()
	
	Return 100000;
	
EndFunction	

#Region RefIntegrityControlInRegisters

Procedure FindDeadRefsInRegisters(MetadataObject, CheckParameters, CheckedRefs)
	
	If MetadataObject.Dimensions.Count() = 0 Then
		Return;
	EndIf;
	
	If Common.IsAccumulationRegister(MetadataObject) Then
		FindDeadRefsInAccumulationRegisters(MetadataObject, CheckParameters, CheckedRefs);
	ElsIf Common.IsInformationRegister(MetadataObject) Then
		FindDeadRefsInInformationRegisters(MetadataObject, CheckParameters, CheckedRefs);
	ElsIf Common.IsAccountingRegister(MetadataObject) Then
		FindDeadRefsInAccountingRegisters(MetadataObject, CheckParameters, ExtDimensionTypes(MetadataObject), CheckedRefs);
	ElsIf Common.IsCalculationRegister(MetadataObject) Then
		FindDeadRefsInCalculationRegisters(MetadataObject, CheckParameters, CheckedRefs);
	EndIf;
	
EndProcedure

Procedure FindDeadRefsInAccumulationRegisters(MetadataObject, CheckParameters, CheckedRefs)
	
	MaximumCount = MaxCheckedRefsCount();
	
	FullName         = MetadataObject.FullName();
	RegisterAttributes = RegisterRefAttributes(MetadataObject);
	
	QueryText =
	"SELECT TOP 1000
	|	MetadataObject.Recorder AS RecorderAttributeRef,
	|	REFPRESENTATION(MetadataObject.Recorder) AS RecorderPresentation,
	|	MetadataObject.Period AS Period
	|FROM
	|	&MetadataObject AS MetadataObject
	|WHERE
	|	MetadataObject.Period > &CheckStartDate
	|
	|GROUP BY
	|	MetadataObject.Period,
	|	MetadataObject.Recorder
	|
	|ORDER BY
	|	MetadataObject.Period";
	
	QueryText = StrReplace(QueryText, "&MetadataObject", FullName);
	
	Query = New Query(QueryText);
	Query.SetParameter("CheckStartDate", CheckParameters.CheckStartDate);
	Result = Query.Execute().Unload();
	
	RegisterManager = Common.ObjectManagerByFullName(FullName);
	
	While Result.Count() > 0 Do
		
		For Each ResultString In Result Do
			
			CurrentRecordSet = RegisterManager.CreateRecordSet();
			CurrentRecordSet.Filter.Recorder.Set(ResultString.RecorderAttributeRef);
			CurrentRecordSet.Read();
			
			ProblemRecordsNumbers = "";
			For Each CurrentRecord In CurrentRecordSet Do
				For Each AttributeName In RegisterAttributes Do
					If IsDeadRef(CurrentRecord[AttributeName], CheckedRefs) Then
						ProblemRecordsNumbers = ProblemRecordsNumbers + ?(ValueIsFilled(ProblemRecordsNumbers), ", ", "")
							+ Format(CurrentRecordSet.IndexOf(CurrentRecord) + 1, "NG=0");
					EndIf;
				EndDo;
			EndDo;
			
			If CheckedRefs.Count() >= MaximumCount Then
				CheckedRefs.Clear();
			EndIf;
			
			If IsBlankString(ProblemRecordsNumbers) Then
				Continue;
			EndIf;
			
			Issue = IssueDetails(Common.MetadataObjectID(MetadataObject), CheckParameters);
			Issue.IssueSummary = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'У регистра накопления ""%1"" в записях с номерами %2 по регистратору ""%3"" указаны ссылки на несуществующие данные.'; en = 'Records ""%2"" in recorder ""%3"" for accumulation register ""%1"" reference data that does not exist.'; pl = 'Records ""%2"" in recorder ""%3"" for accumulation register ""%1"" reference data that does not exist.';de = 'Records ""%2"" in recorder ""%3"" for accumulation register ""%1"" reference data that does not exist.';ro = 'Records ""%2"" in recorder ""%3"" for accumulation register ""%1"" reference data that does not exist.';tr = 'Records ""%2"" in recorder ""%3"" for accumulation register ""%1"" reference data that does not exist.'; es_ES = 'Records ""%2"" in recorder ""%3"" for accumulation register ""%1"" reference data that does not exist.'"),
				MetadataObject.Presentation(), ProblemRecordsNumbers, ResultString.RecorderPresentation);
				
			AdditionalInformation = New Structure;
			AdditionalInformation.Insert("Recorder", ResultString.RecorderAttributeRef);
			Issue.AdditionalInformation = New ValueStorage(AdditionalInformation);
			
			WriteIssue(Issue, CheckParameters);
			
		EndDo;
		
		Query.SetParameter("CheckStartDate", ResultString.Period);
		Result = Query.Execute().Unload();
		
	EndDo;
	
EndProcedure

Procedure FindDeadRefsInInformationRegisters(MetadataObject, CheckParameters, CheckedRefs)
	
	If MetadataObject.WriteMode = Metadata.ObjectProperties.RegisterWriteMode.RecorderSubordinate Then
		FindDeadRefsInSubordinateInformationRegisters(MetadataObject, CheckParameters, CheckedRefs);
	ElsIf MetadataObject.InformationRegisterPeriodicity <> Metadata.ObjectProperties.InformationRegisterPeriodicity.Nonperiodical Then
		FindDeadRefsInIndependentPeriodicalInformationRegisters(MetadataObject, CheckParameters, CheckedRefs);
	Else
		FindDeadRefsInIndependentNonPeriodicalInformationRegisters(MetadataObject, CheckParameters, CheckedRefs);
	EndIf;
	
EndProcedure

Procedure FindDeadRefsInSubordinateInformationRegisters(MetadataObject, CheckParameters, CheckedRefs)
	
	MaximumCount = MaxCheckedRefsCount();
	FullName         = MetadataObject.FullName();
	RegisterAttributes = RegisterRefAttributes(MetadataObject);
	
	ThisRegisterPeriodical = MetadataObject.InformationRegisterPeriodicity <> Metadata.ObjectProperties.InformationRegisterPeriodicity.Nonperiodical;
	If ThisRegisterPeriodical Then
		
		Query = New Query(
		"SELECT TOP 1000
		|	MetadataObject.Recorder AS RecorderAttributeRef,
		|	REFPRESENTATION(MetadataObject.Recorder) AS RecorderPresentation,
		|	MetadataObject.Period AS Period
		|FROM
		|	&MetadataObject AS MetadataObject
		|WHERE
		|	MetadataObject.Period > &CheckStartDate
		|
		|GROUP BY
		|	MetadataObject.Period,
		|	MetadataObject.Recorder
		|
		|ORDER BY
		|	MetadataObject.Period");
		
		Query.SetParameter("CheckStartDate", CheckParameters.CheckStartDate);
		
	Else
		
		Query = New Query(
		"SELECT TOP 1000
		|	MetadataObject.Recorder AS RecorderAttributeRef,
		|	REFPRESENTATION(MetadataObject.Recorder) AS RecorderPresentation
		|FROM
		|	&MetadataObject AS MetadataObject
		|WHERE
		|	MetadataObject.Recorder > &Recorder
		|
		|GROUP BY
		|	MetadataObject.Recorder
		|
		|ORDER BY
		|	MetadataObject.Recorder");
		
		Query.SetParameter("Recorder", "");
		
	EndIf;
	
	Query.Text = StrReplace(Query.Text, "&MetadataObject", FullName);
	Result    = Query.Execute().Unload();
	
	RegisterManager = Common.ObjectManagerByFullName(FullName);
	
	While Result.Count() > 0 Do
		
		For Each ResultString In Result Do
			
			CurrentRecordSet = RegisterManager.CreateRecordSet();
			CurrentRecordSet.Filter.Recorder.Set(ResultString.RecorderAttributeRef);
			CurrentRecordSet.Read();
			
			ProblemRecordsNumbers = "";
			For Each CurrentRecord In CurrentRecordSet Do
				For Each AttributeName In RegisterAttributes Do
					If IsDeadRef(CurrentRecord[AttributeName], CheckedRefs) Then
						ProblemRecordsNumbers = ProblemRecordsNumbers + ?(ValueIsFilled(ProblemRecordsNumbers), ", ", "")
							+ Format(CurrentRecordSet.IndexOf(CurrentRecord) + 1, "NG=0");
					EndIf;
				EndDo;
			EndDo;
			
			If CheckedRefs.Count() >= MaximumCount Then
				CheckedRefs.Clear();
			EndIf;
			
			If IsBlankString(ProblemRecordsNumbers) Then
				Continue;
			EndIf;
			
			Issue = IssueDetails(Common.MetadataObjectID(MetadataObject), CheckParameters);
			Issue.IssueSummary = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'У регистра сведений ""%1"" в записях с номерами %2 по регистратору ""%3"" указаны ссылки на несуществующие данные.'; en = 'Records ""%2"" in recorder ""%3"" for information register ""%1"" reference data that does not exist.'; pl = 'Records ""%2"" in recorder ""%3"" for information register ""%1"" reference data that does not exist.';de = 'Records ""%2"" in recorder ""%3"" for information register ""%1"" reference data that does not exist.';ro = 'Records ""%2"" in recorder ""%3"" for information register ""%1"" reference data that does not exist.';tr = 'Records ""%2"" in recorder ""%3"" for information register ""%1"" reference data that does not exist.'; es_ES = 'Records ""%2"" in recorder ""%3"" for information register ""%1"" reference data that does not exist.'"),
				MetadataObject.Presentation(), ProblemRecordsNumbers, ResultString.RecorderPresentation);
				
			AdditionalInformation = New Structure;
			AdditionalInformation.Insert("Recorder", ResultString.RecorderAttributeRef);
			Issue.AdditionalInformation = New ValueStorage(AdditionalInformation);
			
			WriteIssue(Issue, CheckParameters);
			
		EndDo;
		
		If ThisRegisterPeriodical Then
			Query.SetParameter("CheckStartDate", ResultString.Period);
		Else
			Query.SetParameter("Recorder", ResultString.RecorderAttributeRef);
		EndIf;
		
		Result = Query.Execute().Unload();
		
	EndDo;
	
EndProcedure

Procedure FindDeadRefsInIndependentPeriodicalInformationRegisters(MetadataObject, CheckParameters, CheckedRefs)
	
	MaximumCount = MaxCheckedRefsCount();
	IndependentRegisterInformation = IndependentRegisterInformation(MetadataObject);
	SelectionFields         = IndependentRegisterInformation.SelectionFields;
	RegisterInformation = IndependentRegisterInformation.RegisterInformation;
	
	ConditionByDimensions = "";
	OrderFields = "Period";
	Dimensions          = MetadataObject.Dimensions;
	
	For Each Dimension In Dimensions Do
		ConditionByDimensions = ConditionByDimensions + ?(ValueIsFilled(ConditionByDimensions), " AND ", "") + Dimension.Name + " >= &" + Dimension.Name;
		OrderFields = OrderFields + ?(ValueIsFilled(OrderFields), ", ", "") + Dimension.Name;
	EndDo;
	
	QueryText =
	"SELECT TOP 1000
	|	MetadataObject.Period AS Period,
	|	&SelectionFields AS SelectionFields
	|FROM
	|	&MetadataObject AS MetadataObject
	|WHERE
	|	MetadataObject.Period > &Period
	|	AND &Condition
	|	ORDER BY &OrderFields";
	
	QueryText = StrReplace(QueryText, "&OrderFields", OrderFields);
	QueryText = StrReplace(QueryText, "&SelectionFields AS SelectionFields", SelectionFields);
	QueryText = StrReplace(QueryText, "&MetadataObject", MetadataObject.FullName());
	
	FirstQueryText = StrReplace(QueryText, "&Condition", "True");
	QueryTextWithCondition = StrReplace(QueryText, "&Condition", ConditionByDimensions);
	
	Query = New Query(FirstQueryText);
	Query.SetParameter("Period", CheckParameters.CheckStartDate);
	Result = Query.Execute().Unload();
	IsFirstPass = True;
	
	While Result.Count() > 0 Do
		
		// The last record is already checked at the previous iteration.
		If Not IsFirstPass AND Result.Count() = 1 Then 
			Break;
		EndIf;
		
		For Each ResultString In Result Do
			
			If Not IsFirstPass AND Result.IndexOf(ResultString) = 0 Then
				Continue;
			EndIf;
			
			For Each AttributeInformation In RegisterInformation Do
				
				CurrentRef = ResultString[AttributeInformation.MetadataName + AttributeInformation.MetadataTypeInNominativeCase + "Ref"];
				If Not IsDeadRef(CurrentRef, CheckedRefs) Then
					Continue;
				EndIf;
				
				AdditionalInformation = New Structure;
				AdditionalInformation.Insert("Period", ResultString.Period);
				For Each Dimension In Dimensions Do
					DimensionRef = ResultString[Dimension.Name + "DimensionRef"];
					AdditionalInformation.Insert(Dimension.Name, DimensionRef);
				EndDo;
				
				Issue = IssueDetails(Common.MetadataObjectID(MetadataObject), CheckParameters);
				Issue.IssueSummary = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("ru='У регистра сведений ""%1"" в %2, по комбинации измерений ""%3"" указана ссылка на несуществующий элемент: ""%4"".'; en = 'Information register ""%1"" in ""%2"", combination of dimensions ""%3"", references an item that does not exist: ""%4"".'; pl = 'Information register ""%1"" in ""%2"", combination of dimensions ""%3"", references an item that does not exist: ""%4"".';de = 'Information register ""%1"" in ""%2"", combination of dimensions ""%3"", references an item that does not exist: ""%4"".';ro = 'Information register ""%1"" in ""%2"", combination of dimensions ""%3"", references an item that does not exist: ""%4"".';tr = 'Information register ""%1"" in ""%2"", combination of dimensions ""%3"", references an item that does not exist: ""%4"".'; es_ES = 'Information register ""%1"" in ""%2"", combination of dimensions ""%3"", references an item that does not exist: ""%4"".'"),
					MetadataObject.Presentation(), AttributeInformation.MetadataTypeInInstrumentalCase,
					OrderFields, 
					ResultString[AttributeInformation.MetadataName + AttributeInformation.MetadataTypeInNominativeCase + "Presentation"]);
				Issue.AdditionalInformation = New ValueStorage(AdditionalInformation);
				WriteIssue(Issue, CheckParameters);
				
			EndDo;
			
			If CheckedRefs.Count() >= MaximumCount Then
				CheckedRefs.Clear();
			EndIf;
			
		EndDo;
		
		If IsFirstPass Then
			IsFirstPass = False;
			Query.Text = QueryTextWithCondition;
		EndIf;
		
		Query.SetParameter("Period", ResultString["Period"]);
		For Each Dimension In Dimensions Do
			Query.SetParameter(Dimension.Name, ResultString[Dimension.Name + "DimensionRef"]);
		EndDo;
		Result = Query.Execute().Unload();
		
	EndDo;
	
EndProcedure

Procedure FindDeadRefsInIndependentNonPeriodicalInformationRegisters(MetadataObject, CheckParameters, CheckedRefs)
	
	MaximumCount = MaxCheckedRefsCount();
	IndependentRegisterInformation = IndependentRegisterInformation(MetadataObject);
	SelectionFields         = IndependentRegisterInformation.SelectionFields;
	RegisterInformation = IndependentRegisterInformation.RegisterInformation;
	
	ConditionByDimensions = "";
	OrderFields  = "";
	
	For Each Dimension In MetadataObject.Dimensions Do
		ConditionByDimensions = ConditionByDimensions + ?(ValueIsFilled(ConditionByDimensions), " AND ", "") + Dimension.Name + " >= &" + Dimension.Name;
		OrderFields  = OrderFields + ?(ValueIsFilled(OrderFields), ", ", "") + Dimension.Name;
	EndDo;
	
	QueryText =
	"SELECT TOP 1000
	|	&SelectionFields AS SelectionFields
	|FROM
	|	&MetadataObject AS MetadataObject
	|WHERE
	|	&Condition
	|
	|ORDER BY
	|	&OrderFields";
	
	QueryText = StrReplace(QueryText, "&OrderFields", OrderFields);
	QueryText = StrReplace(QueryText, "&SelectionFields AS SelectionFields", SelectionFields);
	QueryText = StrReplace(QueryText, "&MetadataObject", MetadataObject.FullName());
	
	FirstQueryText   = StrReplace(QueryText, "&Condition", "True");
	QueryTextWithCondition = StrReplace(QueryText, "&Condition", ConditionByDimensions);
	
	Query = New Query(FirstQueryText);
	
	Result       = Query.Execute().Unload();
	IsFirstPass = True;
	
	While Result.Count() > 0 Do
		
		// The last record is already checked at the previous iteration.
		If Not IsFirstPass AND Result.Count() = 1 Then
			Break;
		EndIf;
		
		For Each ResultString In Result Do
			
			If Not IsFirstPass AND Result.IndexOf(ResultString) = 0 Then
				Continue;
			EndIf;
			
			For Each AttributeInformation In RegisterInformation Do
				
				CurrentRef = ResultString[AttributeInformation.MetadataName + AttributeInformation.MetadataTypeInNominativeCase + "Ref"];
				If Not IsDeadRef(CurrentRef, CheckedRefs) Then
					Continue;
				EndIf;
				
				AdditionalInformation = New Structure;
				For Each Dimension In MetadataObject.Dimensions Do
					DimensionRef = ResultString[Dimension.Name + "DimensionRef"];
					AdditionalInformation.Insert(Dimension.Name, DimensionRef);
				EndDo;
				
				Issue = IssueDetails(Common.MetadataObjectID(MetadataObject), CheckParameters);
				Issue.IssueSummary = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("ru='У регистра сведений ""%1"" в %2, по комбинации измерений ""%3"" указана ссылка на несуществующий элемент: ""%4"".'; en = 'Information register ""%1"" in ""%2"", combination of dimensions ""%3"", references an item that does not exist: ""%4"".'; pl = 'Information register ""%1"" in ""%2"", combination of dimensions ""%3"", references an item that does not exist: ""%4"".';de = 'Information register ""%1"" in ""%2"", combination of dimensions ""%3"", references an item that does not exist: ""%4"".';ro = 'Information register ""%1"" in ""%2"", combination of dimensions ""%3"", references an item that does not exist: ""%4"".';tr = 'Information register ""%1"" in ""%2"", combination of dimensions ""%3"", references an item that does not exist: ""%4"".'; es_ES = 'Information register ""%1"" in ""%2"", combination of dimensions ""%3"", references an item that does not exist: ""%4"".'"),
					MetadataObject.Presentation(), AttributeInformation.MetadataTypeInInstrumentalCase,
					OrderFields, 
					ResultString[AttributeInformation.MetadataName + AttributeInformation.MetadataTypeInNominativeCase + "Presentation"]);
				Issue.AdditionalInformation = New ValueStorage(AdditionalInformation);
				WriteIssue(Issue, CheckParameters);
				
			EndDo;
			
		EndDo;
		
		If CheckedRefs.Count() >= MaximumCount Then
			CheckedRefs.Clear();
		EndIf;
		
		If IsFirstPass Then
			IsFirstPass = False;
			Query.Text = QueryTextWithCondition;
		EndIf;
		
		For Each Dimension In MetadataObject.Dimensions Do
			Query.SetParameter(Dimension.Name, ResultString[Dimension.Name + "DimensionRef"]);
		EndDo;
		
		Result = Query.Execute().Unload();
		
	EndDo;
	
EndProcedure

Procedure FindDeadRefsInAccountingRegisters(MetadataObject, CheckParameters, ExtDimensionTypes, CheckedRefs)
	
	MaximumCount = MaxCheckedRefsCount();
	FullName                      = MetadataObject.FullName();
	
	RefAttributes = New Array;
	
	If Not MetadataObject.Correspondence Then
		RefAttributes.Add("Account");
	Else
		RefAttributes.Add("AccountDr");
		RefAttributes.Add("AccountCr");
	EndIf;
		
	For Each Dimension In MetadataObject.Dimensions Do
		
		If Not ContainsRefType(Dimension) Then
			Continue;
		EndIf;
		
		If Dimension.Balance Or Not MetadataObject.Correspondence Then
			RefAttributes.Add(Dimension.Name);
		Else
			RefAttributes.Add(Dimension.Name + "Dr");
			RefAttributes.Add(Dimension.Name + "Cr");
		EndIf;
		
	EndDo;
	
	For Each Attribute In MetadataObject.Attributes Do
		If Not ContainsRefType(Attribute) Then
			Continue;
		EndIf;
		RefAttributes.Add(Attribute.Name);
	EndDo;
	
	Query = New Query(
	"SELECT TOP 1000
	|	MetadataObject.Recorder AS RecorderAttributeRef,
	|	REFPRESENTATION(MetadataObject.Recorder) AS RecorderPresentation,
	|	MetadataObject.Period AS Period
	|FROM
	|	&MetadataObject AS MetadataObject
	|
	|GROUP BY
	|	MetadataObject.Period,
	|	MetadataObject.Recorder
	|
	|ORDER BY
	|	MetadataObject.Period");
	
	Query.Text = StrReplace(Query.Text, "&MetadataObject", FullName + ".RecordsWithExtDimensions(, , Period > &CheckStartDate, , )");
	Query.SetParameter("CheckStartDate", CheckParameters.CheckStartDate);
	Result = Query.Execute().Unload();
	
	RegisterManager = Common.ObjectManagerByFullName(FullName);
	
	While Result.Count() > 0 Do
		
		For Each ResultString In Result Do
			
			CurrentRecordSet = RegisterManager.CreateRecordSet();
			CurrentRecordSet.Filter.Recorder.Set(ResultString.RecorderAttributeRef);
			CurrentRecordSet.Read();
			
			ProblemRecordsNumbers = "";
			For Each CurrentRecord In CurrentRecordSet Do
				
				ObjectsToCheck = New Array;
				
				For Each ExtDimensionType In ExtDimensionTypes Do
					If Not MetadataObject.Correspondence Then
						ObjectsToCheck.Add(CurrentRecord.ExtDimensions[ExtDimensionType]);
					Else
						ObjectsToCheck.Add(CurrentRecord.ExtDimensionsDr[ExtDimensionType]);
						ObjectsToCheck.Add(CurrentRecord.ExtDimensionsCr[ExtDimensionType]);
					EndIf;
				EndDo;
				
				For Each AttributeName In RefAttributes Do
					ObjectsToCheck.Add(CurrentRecord[AttributeName]);
				EndDo;
				
				For Each ObjectToCheck In ObjectsToCheck Do
					If IsDeadRef(ObjectToCheck, CheckedRefs) Then
						ProblemRecordsNumbers = ProblemRecordsNumbers + ?(ValueIsFilled(ProblemRecordsNumbers), ", ", "")
							+ Format(CurrentRecordSet.IndexOf(CurrentRecord) + 1, "NG=0");
					EndIf;	
				EndDo;
				
			EndDo;
			
			If CheckedRefs.Count() >= MaximumCount Then
				CheckedRefs.Clear();
			EndIf;
			
			If IsBlankString(ProblemRecordsNumbers) Then
				Continue;
			EndIf;
			
			Issue = IssueDetails(Common.MetadataObjectID(MetadataObject), CheckParameters);
			Issue.IssueSummary = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'У регистра бухгалтерии ""%1"" в записях с номерами %2 по регистратору ""%3"" указаны ссылки на несуществующие данные.'; en = 'Records ""%2"" in recorder ""%3"" for accounting register ""%1"" reference data that does not exist.'; pl = 'Records ""%2"" in recorder ""%3"" for accounting register ""%1"" reference data that does not exist.';de = 'Records ""%2"" in recorder ""%3"" for accounting register ""%1"" reference data that does not exist.';ro = 'Records ""%2"" in recorder ""%3"" for accounting register ""%1"" reference data that does not exist.';tr = 'Records ""%2"" in recorder ""%3"" for accounting register ""%1"" reference data that does not exist.'; es_ES = 'Records ""%2"" in recorder ""%3"" for accounting register ""%1"" reference data that does not exist.'"),
				MetadataObject.Presentation(), ProblemRecordsNumbers, ResultString.RecorderPresentation);
				
			AdditionalInformation = New Structure;
			AdditionalInformation.Insert("Recorder", ResultString.RecorderAttributeRef);
			Issue.AdditionalInformation = New ValueStorage(AdditionalInformation);
			
			WriteIssue(Issue, CheckParameters);
			
		EndDo;
		
		Query.SetParameter("CheckStartDate", ResultString.Period);
		Result = Query.Execute().Unload();
		
	EndDo;
	
EndProcedure

Procedure FindDeadRefsInCalculationRegisters(MetadataObject, CheckParameters, CheckedRefs)
	
	MaximumCount = MaxCheckedRefsCount();
	FullName         = MetadataObject.FullName();
	RegisterAttributes = RegisterRefAttributes(MetadataObject);
	
	Query = New Query(
	"SELECT TOP 1000
	|	MetadataObject.Recorder AS RecorderAttributeRef,
	|	REFPRESENTATION(MetadataObject.Recorder) AS RecorderPresentation,
	|	MetadataObject.RegistrationPeriod AS Period
	|FROM
	|	&MetadataObject AS MetadataObject
	|WHERE
	|	MetadataObject.RegistrationPeriod > &CheckStartDate
	|
	|GROUP BY
	|	MetadataObject.RegistrationPeriod,
	|	MetadataObject.Recorder
	|
	|ORDER BY
	|	MetadataObject.RegistrationPeriod");
	
	Query.Text = StrReplace(Query.Text, "&MetadataObject", FullName);
	Query.SetParameter("CheckStartDate", CheckParameters.CheckStartDate);
	Result = Query.Execute().Unload();
	
	RegisterManager = Common.ObjectManagerByFullName(FullName);
	
	While Result.Count() > 0 Do
		
		For Each ResultString In Result Do
			
			CurrentRecordSet = RegisterManager.CreateRecordSet();
			CurrentRecordSet.Filter.Recorder.Set(ResultString.RecorderAttributeRef);
			CurrentRecordSet.Read();
			
			ProblemRecordsNumbers = "";
			For Each CurrentRecord In CurrentRecordSet Do
				For Each AttributeName In RegisterAttributes Do
					CurrentRef = CurrentRecord[AttributeName];
					If IsDeadRef(CurrentRef, CheckedRefs) Then
						ProblemRecordsNumbers = ProblemRecordsNumbers + ?(ValueIsFilled(ProblemRecordsNumbers), ", ", "")
							+ Format(CurrentRecordSet.IndexOf(CurrentRecord) + 1, "NG=0");
					EndIf;	
				EndDo;
			EndDo;
			
			If CheckedRefs.Count() >= MaximumCount Then
				CheckedRefs.Clear();
			EndIf;
			
			If IsBlankString(ProblemRecordsNumbers) Then
				Continue;
			EndIf;
			
			Issue = IssueDetails(Common.MetadataObjectID(MetadataObject), CheckParameters);
			
			Issue.IssueSummary = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'У регистра расчета ""%1"" в записях с номерами %2 по регистратору ""%3"" указаны ссылки на несуществующие данные.'; en = 'Records ""%2"" in recorder ""%3"" for calculation register ""%1"" reference data that does not exist.'; pl = 'Records ""%2"" in recorder ""%3"" for calculation register ""%1"" reference data that does not exist.';de = 'Records ""%2"" in recorder ""%3"" for calculation register ""%1"" reference data that does not exist.';ro = 'Records ""%2"" in recorder ""%3"" for calculation register ""%1"" reference data that does not exist.';tr = 'Records ""%2"" in recorder ""%3"" for calculation register ""%1"" reference data that does not exist.'; es_ES = 'Records ""%2"" in recorder ""%3"" for calculation register ""%1"" reference data that does not exist.'"),
				MetadataObject.Presentation(), ProblemRecordsNumbers, ResultString.RecorderPresentation);
				
			AdditionalInformation = New Structure;
			AdditionalInformation.Insert("Recorder", ResultString.RecorderAttributeRef);
			Issue.AdditionalInformation = New ValueStorage(AdditionalInformation);
			
			WriteIssue(Issue, CheckParameters);
			
		EndDo;
		
		Query.SetParameter("CheckStartDate", ResultString.Period);
		Result = Query.Execute().Unload();
		
	EndDo;
	
EndProcedure

Function RegisterRefAttributes(MetadataObject)
	
	Dimensions = MetadataObject.Dimensions;
	Attributes = MetadataObject.Attributes;
	
	Result = New Array;
	
	For Each Attribute In Attributes Do
		If ContainsRefType(Attribute) Then
			Result.Add(Attribute.Name);
		EndIf;
	EndDo;
	
	If Common.IsCalculationRegister(MetadataObject) Then
		
		For Each Dimension In Dimensions Do
			If ContainsRefType(Dimension) Then
				Result.Add(Dimension.Name);
			EndIf;
		EndDo;
		
		StandardAttributes = MetadataObject.StandardAttributes;
		For Each StandardAttribute In StandardAttributes Do
			If StandardAttribute.Name = "Recorder" Or Not ContainsRefType(StandardAttribute) Then
				Continue;
			EndIf;
			Result.Add(StandardAttribute.Name);
		EndDo;
		
	ElsIf Common.IsInformationRegister(MetadataObject) Or Common.IsAccumulationRegister(MetadataObject) Then
		
		For Each Dimension In Dimensions Do
			If ContainsRefType(Dimension) Then
				Result.Add(Dimension.Name);
			EndIf;
		EndDo;
		
		Resources = MetadataObject.Resources;
		For Each Resource In Resources Do
			If ContainsRefType(Resource) Then
				Result.Add(Resource.Name);
			EndIf;
		EndDo;
		
	EndIf;
	
	Return Result;
	
EndFunction

Function ContainsRefType(Attribute)
	
	AttributeTypes = Attribute.Type.Types();
	For Each CurrentType In AttributeTypes Do
		If Common.IsReference(CurrentType) Then
			Return True;
		EndIf;
	EndDo;
	
	Return False;
	
EndFunction

Function ExtDimensionTypes(MetadataObject)
	
	ExtDimensionTypesMetadataObject = MetadataObject.ChartOfAccounts.ExtDimensionTypes;
	If Not ContainsRefType(ExtDimensionTypesMetadataObject) Then
		Return New Array;
	EndIf;
		
	Query = New Query(
	"SELECT
	|	ChartOfCharacteristicTypes.Ref AS ExtDimensionType
	|FROM
	|	&ChartOfCharacteristicTypes AS ChartOfCharacteristicTypes");
	
	Query.Text = StrReplace(Query.Text, "&ChartOfCharacteristicTypes", MetadataObject.ChartOfAccounts.ExtDimensionTypes.FullName());
	Return Query.Execute().Unload().UnloadColumn("ExtDimensionType");
	
EndFunction

Function IndependentRegisterInformation(MetadataObject, GetDimensions = True, GetResources = True, GetAttributes = True)
	
	RegisterInformation = New ValueTable;
	RegisterInformation.Columns.Add("MetadataTypeInNominativeCase", New TypeDescription("String", , , , New StringQualifiers(16)));
	RegisterInformation.Columns.Add("MetadataTypeInInstrumentalCase", New TypeDescription("String", , , , New StringQualifiers(16)));
	RegisterInformation.Columns.Add("MetadataName",                    New TypeDescription("String", , , , New StringQualifiers(128)));
	
	SelectionFields = "";
	
	If GetDimensions Then
		Dimensions = MetadataObject.Dimensions;
		For Each Dimension In Dimensions Do
			DimensionName = Dimension.Name;
			SelectionFields  = SelectionFields + ?(ValueIsFilled(SelectionFields), ",", "") + DimensionName + " AS " + DimensionName
				+ "DimensionRef,RefPresentation(" + DimensionName + ") AS " + DimensionName + "DimensionPresentation";
			FillPropertyValues(RegisterInformation.Add(),
				New Structure("MetadataTypeInNominativeCase, MetadataTypeInInstrumentalCase, MetadataName", 
					"Dimension", NStr("ru = 'измерении'; en = 'dimension'; pl = 'dimension';de = 'dimension';ro = 'dimension';tr = 'dimension'; es_ES = 'dimension'"), DimensionName));
		EndDo;
	EndIf;
	
	If GetResources Then
		Resources = MetadataObject.Resources;
		For Each Resource In Resources Do
			ResourceName  = Resource.Name;
			SelectionFields = SelectionFields + ?(ValueIsFilled(SelectionFields), ",", "") + ResourceName + " AS " + ResourceName
				+ "ResourceRef,RefPresentation(" + ResourceName + ") AS " + ResourceName + "ResourcePresentation";
			FillPropertyValues(RegisterInformation.Add(),
				New Structure("MetadataTypeInNominativeCase, MetadataTypeInInstrumentalCase, MetadataName", 
					"Resource", NStr("ru = 'ресурсе'; en = 'resource'; pl = 'resource';de = 'resource';ro = 'resource';tr = 'resource'; es_ES = 'resource'"), ResourceName));
		EndDo;
	EndIf;
	
	If GetAttributes Then
		Attributes = MetadataObject.Attributes;
		For Each Attribute In Attributes Do
			AttributeName = Attribute.Name;
			SelectionFields = SelectionFields + ?(ValueIsFilled(SelectionFields), ",", "") + AttributeName + " AS " + AttributeName
				+ "AttributeRef,RefPresentation(" + AttributeName + ") AS " + AttributeName + "AttributePresentation";
			FillPropertyValues(RegisterInformation.Add(),
				New Structure("MetadataTypeInNominativeCase, MetadataTypeInInstrumentalCase, MetadataName", 
					"Attribute", NStr("ru = 'реквизите'; en = 'attribute'; pl = 'attribute';de = 'attribute';ro = 'attribute';tr = 'attribute'; es_ES = 'attribute'"), AttributeName));
		EndDo;
	EndIf;
		
	Return New Structure("RegisterInformation, SelectionFields", RegisterInformation, SelectionFields);
	
EndFunction

#EndRegion

#EndRegion

#Region CheckRequiredAttributesFilling

Procedure FindNotFilledRequiredAttributes(MetadataObject, CheckParameters)
	
	ModulePerformanceMonitor = Undefined;
	If Common.SubsystemExists("StandardSubsystems.PerformanceMonitor") Then
		ModulePerformanceMonitor = Common.CommonModule("PerformanceMonitor");
	EndIf;
	
	FullName = MetadataObject.FullName();
	Attributes = MetadataObject.Attributes;
	
	QueryText = 
	"SELECT TOP 1000
	|	MetadataObject.Ref AS ObjectWithIssue
	|FROM
	|	&MetadataObject AS MetadataObject
	|WHERE
	|	MetadataObject.Ref > &Ref
	|
	|ORDER BY
	|	MetadataObject.Ref";
	
	QueryText = StrReplace(QueryText, "&MetadataObject", FullName);
	Query       = New Query(QueryText);
	Query.SetParameter("Ref", "");
	
	Result = Query.Execute().Unload();
	
	DataCountTotal = 0;
	RestrictionByDate     = CheckParameters.CheckStartDate;
	While Result.Count() > 0 Do
		
		If ModulePerformanceMonitor <> Undefined Then
			MeasurementDetails = ModulePerformanceMonitor.StartTimeConsumingOperationMeasurement(CheckParameters.ID + "." + FullName);
		EndIf;
		
		For Each ResultString In Result Do
			
			ObjectRef = ResultString.ObjectWithIssue;
			
			If ValueIsFilled(RestrictionByDate)
				AND Common.IsDocument(MetadataObject)
				AND Common.ObjectAttributeValue(ObjectRef, "Date") < RestrictionByDate Then
				Continue;
			EndIf;
			
			If Common.IsDocument(MetadataObject) AND Not Common.ObjectAttributeValue(ObjectRef, "Posted") Then
				Continue;
			EndIf;
			
			If Common.IsExchangePlan(MetadataObject) AND ObjectRef.ThisNode Then
				Continue;
			EndIf;
			
			ObjectToCheck = ObjectRef.GetObject();
			If ObjectToCheck.CheckFilling() Then
				Continue;
			EndIf;
			
			Issue = IssueDetails(ObjectRef, CheckParameters);
			
			Issue.IssueSummary = NStr("ru = 'Не заполнены реквизиты, обязательные к заполнению:'; en = 'Mandatory attributes are not filled:'; pl = 'Mandatory attributes are not filled:';de = 'Mandatory attributes are not filled:';ro = 'Mandatory attributes are not filled:';tr = 'Mandatory attributes are not filled:'; es_ES = 'Mandatory attributes are not filled:'") + Chars.LF + ObjectFillingErrors();
			If Attributes.Find("EmployeeResponsible") <> Undefined Then
				Issue.Insert("EmployeeResponsible", Common.ObjectAttributeValue(ObjectRef, "EmployeeResponsible"));
			EndIf;
			
			WriteIssue(Issue, CheckParameters);
			
		EndDo;
		
		DataCountTotal = DataCountTotal + Result.Count();
		If ModulePerformanceMonitor <> Undefined Then
			ModulePerformanceMonitor.EndTimeConsumingOperationMeasurement(MeasurementDetails, DataCountTotal);
		EndIf;
		
		Query.SetParameter("Ref", ResultString.ObjectWithIssue);
		Result = Query.Execute().Unload();
		
	EndDo;
	
EndProcedure

Procedure FindNotFilledRequiredAttributesInRegisters(MetadataObject, CheckParameters)
	
	If MetadataObject.Dimensions.Count() = 0 Then
		Return;
	EndIf;
	
	If Common.IsInformationRegister(MetadataObject) Then
		
		If MetadataObject.WriteMode = Metadata.ObjectProperties.RegisterWriteMode.RecorderSubordinate Then
			If MetadataObject.InformationRegisterPeriodicity <> Metadata.ObjectProperties.InformationRegisterPeriodicity.Nonperiodical Then
				FindNotFilledRequiredAttributesInSubordinatePeriodicalRegisters(MetadataObject, CheckParameters);
			Else
				FindNotFilledRequiredAttributesInSubordinateNonPeriodicalRegisters(MetadataObject, CheckParameters);
			EndIf;
		Else	
			If MetadataObject.InformationRegisterPeriodicity <> Metadata.ObjectProperties.InformationRegisterPeriodicity.Nonperiodical Then
				FindNotFilledRequiredAttributesInIndependentPeriodicalInformationRegisters(MetadataObject, CheckParameters);
			Else
				FindNotFilledRequiredAttributesInIndependentNonPeriodicalInformationRegisters(MetadataObject, CheckParameters);
			EndIf;
		EndIf;
		
	ElsIf Common.IsAccumulationRegister(MetadataObject)
		Or Common.IsAccountingRegister(MetadataObject)
		Or Common.IsCalculationRegister(MetadataObject) Then
		
		FindNotFilledRequiredAttributesInSubordinateNonPeriodicalRegisters(MetadataObject, CheckParameters);
		
	EndIf;
	
EndProcedure

Procedure FindNotFilledRequiredAttributesInSubordinatePeriodicalRegisters(MetadataObject, CheckParameters)
	
	ModulePerformanceMonitor = Undefined;
	If Common.SubsystemExists("StandardSubsystems.PerformanceMonitor") Then
		ModulePerformanceMonitor = Common.CommonModule("PerformanceMonitor");
	EndIf;
	
	FullName = MetadataObject.FullName();
	If Common.IsCalculationRegister(MetadataObject) Then
		
		Query = New Query(
		"SELECT TOP 1000
		|	MetadataObject.Recorder AS RecorderAttributeRef,
		|	REFPRESENTATION(MetadataObject.Recorder) AS RecorderPresentation,
		|	MetadataObject.RegistrationPeriod AS Period
		|FROM
		|	&MetadataObject AS MetadataObject
		|WHERE
		|	MetadataObject.RegistrationPeriod > &CheckStartDate
		|
		|GROUP BY
		|	MetadataObject.RegistrationPeriod,
		|	MetadataObject.Recorder
		|
		|ORDER BY
		|	MetadataObject.RegistrationPeriod");
		
		Query.Text = StrReplace(Query.Text, "&MetadataObject", FullName);
		Query.SetParameter("CheckStartDate", CheckParameters.CheckStartDate);
		
	ElsIf Common.IsAccountingRegister(MetadataObject) Then
		
		Query = New Query(
		"SELECT TOP 1000
		|	MetadataObject.Recorder AS RecorderAttributeRef,
		|	REFPRESENTATION(MetadataObject.Recorder) AS RecorderPresentation,
		|	MetadataObject.Period AS Period
		|FROM
		|	&MetadataObject AS MetadataObject
		|
		|GROUP BY
		|	MetadataObject.Period,
		|	MetadataObject.Recorder
		|
		|ORDER BY
		|	MetadataObject.Period");
		
		Query.Text = StrReplace(Query.Text, "&MetadataObject", 
			FullName + ".RecordsWithExtDimensions(, , Period > &CheckStartDate AND Recorder > &Recorder, , )");
		Query.SetParameter("CheckStartDate", CheckParameters.CheckStartDate);
		
	Else
		
		Query = New Query(
		"SELECT TOP 1000
		|	MetadataObject.Recorder AS RecorderAttributeRef,
		|	REFPRESENTATION(MetadataObject.Recorder) AS RecorderPresentation,
		|	MetadataObject.Period AS Period
		|FROM
		|	&MetadataObject AS MetadataObject
		|WHERE
		|	MetadataObject.Period > &CheckStartDate
		|
		|GROUP BY
		|	MetadataObject.Period,
		|	MetadataObject.Recorder
		|
		|ORDER BY
		|	MetadataObject.Period");
		
		Query.Text = StrReplace(Query.Text, "&MetadataObject", FullName);
		Query.SetParameter("CheckStartDate", CheckParameters.CheckStartDate);
		
	EndIf;
	
	Result        = Query.Execute().Unload();
	RegisterManager = Common.ObjectManagerByFullName(FullName);
	DataCountTotal = 0;
	
	While Result.Count() > 0 Do
		
		If ModulePerformanceMonitor <> Undefined Then
			MeasurementDetails = ModulePerformanceMonitor.StartTimeConsumingOperationMeasurement(CheckParameters.ID + "." + FullName);
		EndIf;
		
		For Each ResultString In Result Do
			
			CurrentRecordSet = RegisterManager.CreateRecordSet();
			CurrentRecordSet.Filter.Recorder.Set(ResultString.RecorderAttributeRef);
			CurrentRecordSet.Read();
			
			If CurrentRecordSet.CheckFilling() Then
				Continue;
			EndIf;
				
			AdditionalInformation = New Structure;
			AdditionalInformation.Insert("Recorder", ResultString.RecorderAttributeRef);
			
			Issue = IssueDetails(Common.MetadataObjectID(MetadataObject), CheckParameters);
			
			Issue.IssueSummary = StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = 'У записи с полями:
				|%1,
				|обнаружены незаполненные данные, обязательные к заполнению: %2'; 
				|en = 'Mandatory data is not filled for record with fields:
				|%1
				|: %2'; 
				|pl = 'Mandatory data is not filled for record with fields:
				|%1
				|: %2';
				|de = 'Mandatory data is not filled for record with fields:
				|%1
				|: %2';
				|ro = 'Mandatory data is not filled for record with fields:
				|%1
				|: %2';
				|tr = 'Mandatory data is not filled for record with fields:
				|%1
				|: %2'; 
				|es_ES = 'Mandatory data is not filled for record with fields:
				|%1
				|: %2'"),
				" • " + NStr("ru = 'Регистратор:'; en = 'Recorder:'; pl = 'Recorder:';de = 'Recorder:';ro = 'Recorder:';tr = 'Recorder:'; es_ES = 'Recorder:'") + " = """ + ResultString.RecorderPresentation, Chars.LF + ObjectFillingErrors());
			Issue.AdditionalInformation = New ValueStorage(AdditionalInformation);
			
			WriteIssue(Issue, CheckParameters);
			
		EndDo;
		
		DataCountTotal = DataCountTotal + Result.Count();
		
		If ModulePerformanceMonitor <> Undefined Then
			ModulePerformanceMonitor.EndTimeConsumingOperationMeasurement(MeasurementDetails, DataCountTotal);
		EndIf;
		
		Query.SetParameter("CheckStartDate", ResultString.Period);
		Result = Query.Execute().Unload();
		
	EndDo;
	
EndProcedure

Procedure FindNotFilledRequiredAttributesInSubordinateNonPeriodicalRegisters(MetadataObject, CheckParameters)
	
	ModulePerformanceMonitor = Undefined;
	If Common.SubsystemExists("StandardSubsystems.PerformanceMonitor") Then
		ModulePerformanceMonitor = Common.CommonModule("PerformanceMonitor");
	EndIf;
	
	FullName = MetadataObject.FullName();
	
	Query = New Query(
	"SELECT TOP 1000
	|	MetadataObject.Recorder AS RecorderAttributeRef,
	|	REFPRESENTATION(MetadataObject.Recorder) AS RecorderPresentation
	|FROM
	|	&MetadataObject AS MetadataObject
	|WHERE
	|	MetadataObject.Recorder > &Recorder
	|
	|GROUP BY
	|	MetadataObject.Recorder
	|
	|ORDER BY
	|	MetadataObject.Recorder");
	
	Query.Text = StrReplace(Query.Text, "&MetadataObject", FullName);
	Query.SetParameter("Recorder", "");
	
	Result        = Query.Execute().Unload();
	RegisterManager = Common.ObjectManagerByFullName(FullName);
	
	DataCountTotal = 0;
	While Result.Count() > 0 Do
		
		If ModulePerformanceMonitor <> Undefined Then
			MeasurementDetails = ModulePerformanceMonitor.StartTimeConsumingOperationMeasurement(CheckParameters.ID + "." + FullName);
		EndIf;
		For Each ResultString In Result Do
			
			CurrentRecordSet = RegisterManager.CreateRecordSet();
			CurrentRecordSet.Filter.Recorder.Set(ResultString.RecorderAttributeRef);
			CurrentRecordSet.Read();
			
			If CurrentRecordSet.CheckFilling() Then
				Continue;
			EndIf;
			
			AdditionalInformation = New Structure;
			AdditionalInformation.Insert("Recorder", ResultString.RecorderAttributeRef);
			
			Issue = IssueDetails(Common.MetadataObjectID(MetadataObject), CheckParameters);
			
			Issue.IssueSummary = StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = 'У записи с полями:
				|%1,
				|обнаружены незаполненные данные, обязательные к заполнению: %2'; 
				|en = 'Mandatory data is not filled for record with fields:
				|%1
				|: %2'; 
				|pl = 'Mandatory data is not filled for record with fields:
				|%1
				|: %2';
				|de = 'Mandatory data is not filled for record with fields:
				|%1
				|: %2';
				|ro = 'Mandatory data is not filled for record with fields:
				|%1
				|: %2';
				|tr = 'Mandatory data is not filled for record with fields:
				|%1
				|: %2'; 
				|es_ES = 'Mandatory data is not filled for record with fields:
				|%1
				|: %2'"),
				" • " + NStr("ru = 'Регистратор:'; en = 'Recorder:'; pl = 'Recorder:';de = 'Recorder:';ro = 'Recorder:';tr = 'Recorder:'; es_ES = 'Recorder:'") + " = """ + ResultString.RecorderPresentation, Chars.LF + ObjectFillingErrors());
			Issue.AdditionalInformation = New ValueStorage(AdditionalInformation);
			
			WriteIssue(Issue, CheckParameters);
			
		EndDo;
		
		DataCountTotal = DataCountTotal + Result.Count();
		If ModulePerformanceMonitor <> Undefined Then
			ModulePerformanceMonitor.EndTimeConsumingOperationMeasurement(MeasurementDetails, DataCountTotal);
		EndIf;
		
		Query.SetParameter("Recorder", ResultString.RecorderAttributeRef);
		Result = Query.Execute().Unload();
		
	EndDo;
	
EndProcedure

Procedure FindNotFilledRequiredAttributesInIndependentNonPeriodicalInformationRegisters(MetadataObject, CheckParameters)
	
	ModulePerformanceMonitor = Undefined;
	If Common.SubsystemExists("StandardSubsystems.PerformanceMonitor") Then
		ModulePerformanceMonitor = Common.CommonModule("PerformanceMonitor");
	EndIf;
	
	FullName           = MetadataObject.FullName();
	RegisterManager    = Common.ObjectManagerByFullName(FullName);
	ConditionByDimensions = "";
	OrderFields  = "";
	Dimensions           = MetadataObject.Dimensions;
	
	For Each Dimension In Dimensions Do
		ConditionByDimensions = ConditionByDimensions + ?(ValueIsFilled(ConditionByDimensions), " AND ", "") + Dimension.Name + " >= &" + Dimension.Name;
		OrderFields  = OrderFields + ?(ValueIsFilled(OrderFields), ", ", "") + Dimension.Name;
	EndDo;
	
	SelectionFields = IndependentRegisterInformation(MetadataObject, True, False, False).SelectionFields;
	
	QueryText =
	"SELECT TOP 1000
	|	&SelectionFields AS SelectionFields
	|FROM
	|	&MetadataObject AS MetadataObject
	|WHERE
	|	&Condition
	|
	|ORDER BY
	|	&OrderFields";
	
	QueryText = StrReplace(QueryText, "&OrderFields", OrderFields);
	QueryText = StrReplace(QueryText, "&SelectionFields AS SelectionFields", SelectionFields);
	QueryText = StrReplace(QueryText, "&MetadataObject", MetadataObject.FullName());
	
	FirstQueryText   = StrReplace(QueryText, "&Condition", "True");
	QueryTextWithCondition = StrReplace(QueryText, "&Condition", ConditionByDimensions);
	
	Query = New Query(FirstQueryText);
	Result = Query.Execute().Unload();
	
	IsFirstPass = True;
	DataCountTotal = 0;
	While Result.Count() > 0 Do
		
		// The last record is already checked at the previous iteration.
		If Not IsFirstPass AND Result.Count() = 1 Then
			Break;
		EndIf;
		
		If ModulePerformanceMonitor <> Undefined Then
			MeasurementDetails = ModulePerformanceMonitor.StartTimeConsumingOperationMeasurement(CheckParameters.ID + "." + FullName);
		EndIf;
		
		For Each ResultString In Result Do
			
			If Not IsFirstPass AND Result.IndexOf(ResultString) = 0 Then
				Continue;
			EndIf;
			
			CurrentRecordSet = RegisterManager.CreateRecordSet();
			CurrentSetFilter = CurrentRecordSet.Filter;
			
			RecordSetFilterPresentation = "";
			For Each Dimension In Dimensions Do
				
				DimensionName      = Dimension.Name;
				DimensionValue = ResultString[DimensionName + "DimensionRef"];
				If Not ValueIsFilled(DimensionValue) Then
					Continue;
				EndIf;
				
				CurrentSetFilter[DimensionName].Set(DimensionValue);
				
				RecordSetFilterPresentation = RecordSetFilterPresentation + ?(ValueIsFilled(RecordSetFilterPresentation), Chars.LF, "")
					+ " • " + DimensionName + " = """ + ResultString[DimensionName + "DimensionPresentation"] + """";
				
			EndDo;
			CurrentRecordSet.Read();
			
			If CurrentRecordSet.CheckFilling() Then
				Continue;
			EndIf;
			
			AdditionalInformation = New Structure;
			For Each Dimension In Dimensions Do
				DimensionRef = ResultString[Dimension.Name + "DimensionRef"];
				AdditionalInformation.Insert(Dimension.Name, DimensionRef);
			EndDo;
			
			Issue = IssueDetails(Common.MetadataObjectID(MetadataObject), CheckParameters);
			
			Issue.IssueSummary        = StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = 'У записи с полями:
				|%1,
				|обнаружены незаполненные данные, обязательные к заполнению: %2'; 
				|en = 'Mandatory data is not filled for record with fields:
				|%1
				|: %2'; 
				|pl = 'Mandatory data is not filled for record with fields:
				|%1
				|: %2';
				|de = 'Mandatory data is not filled for record with fields:
				|%1
				|: %2';
				|ro = 'Mandatory data is not filled for record with fields:
				|%1
				|: %2';
				|tr = 'Mandatory data is not filled for record with fields:
				|%1
				|: %2'; 
				|es_ES = 'Mandatory data is not filled for record with fields:
				|%1
				|: %2'"), RecordSetFilterPresentation, Chars.LF + ObjectFillingErrors());
			Issue.AdditionalInformation = New ValueStorage(AdditionalInformation);
			
			WriteIssue(Issue, CheckParameters);
			
		EndDo;
		
		If IsFirstPass Then
			IsFirstPass = False;
			Query.Text = QueryTextWithCondition;
		EndIf;
		
		For Each Dimension In Dimensions Do
			Query.SetParameter(Dimension.Name, ResultString[Dimension.Name + "DimensionRef"]);
		EndDo;
		
		DataCountTotal = DataCountTotal + Result.Count();
		If ModulePerformanceMonitor <> Undefined Then
			ModulePerformanceMonitor.EndTimeConsumingOperationMeasurement(MeasurementDetails, DataCountTotal);
		EndIf;
		
		Result = Query.Execute().Unload();
		
	EndDo;
	
EndProcedure

Procedure FindNotFilledRequiredAttributesInIndependentPeriodicalInformationRegisters(MetadataObject, CheckParameters)
	
	ModulePerformanceMonitor = Undefined;
	If Common.SubsystemExists("StandardSubsystems.PerformanceMonitor") Then
		ModulePerformanceMonitor = Common.CommonModule("PerformanceMonitor");
	EndIf;
	
	FullName          = MetadataObject.FullName();
	RegisterManager   = Common.ObjectManagerByFullName(FullName);
	ConditionByDimensions = "";
	OrderFields = "Period";
	Dimensions          = MetadataObject.Dimensions;
	
	For Each Dimension In Dimensions Do
		ConditionByDimensions = ConditionByDimensions + ?(ValueIsFilled(ConditionByDimensions), " AND ", "") + Dimension.Name + " >= &" + Dimension.Name;
		OrderFields = OrderFields + ?(ValueIsFilled(OrderFields), ", ", "") + Dimension.Name;
	EndDo;
	
	SelectionFields = IndependentRegisterInformation(MetadataObject, True, False, False).SelectionFields;
	
	QueryText =
	"SELECT TOP 1000
	|	MetadataObject.Period AS Period,
	|	&SelectionFields AS SelectionFields
	|FROM
	|	&MetadataObject AS MetadataObject
	|WHERE
	|	MetadataObject.Period >= &Period
	|	AND &Condition
	|ORDER BY &OrderFields";
	
	QueryText = StrReplace(QueryText, "&OrderFields", OrderFields);
	QueryText = StrReplace(QueryText, "&SelectionFields AS SelectionFields", SelectionFields);
	QueryText = StrReplace(QueryText, "&MetadataObject", MetadataObject.FullName());
	FirstQueryText = StrReplace(QueryText, "&Condition", "True");
	QueryTextWithCondition = StrReplace(QueryText, "&Condition", ConditionByDimensions);
	
	Query = New Query(FirstQueryText);
	Query.SetParameter("Period", CheckParameters.CheckStartDate);
	
	Result = Query.Execute().Unload();
	IsFirstPass = True;
	
	DataCountTotal = 0;
	While Result.Count() > 0 Do
		
		// The last record is already checked at the previous iteration.
		If Not IsFirstPass AND Result.Count() = 1 Then
			Break;
		EndIf;
		
		If ModulePerformanceMonitor <> Undefined Then
			MeasurementDetails = ModulePerformanceMonitor.StartTimeConsumingOperationMeasurement(CheckParameters.ID + "." + FullName);
		EndIf;
		
		For Each ResultString In Result Do
			
			CurrentRecordSet = RegisterManager.CreateRecordSet();
			CurrentSetFilter = CurrentRecordSet.Filter;
			
			RecordSetFilterPresentation = StringFunctionsClientServer.SubstituteParametersToString(" • %1 = ""%2""",
				NStr("ru = 'Период'; en = 'Period'; pl = 'Period';de = 'Period';ro = 'Period';tr = 'Period'; es_ES = 'Period'"), ResultString.Period);
			For Each Dimension In Dimensions Do
				
				DimensionName      = Dimension.Name;
				DimensionValue = ResultString[DimensionName + "DimensionRef"];
				If Not ValueIsFilled(DimensionValue) Then
					Continue;
				EndIf;
				
				CurrentSetFilter[DimensionName].Set(DimensionValue);
				
				RecordSetFilterPresentation = RecordSetFilterPresentation + Chars.LF
					+ " • " + DimensionName + " = """ + ResultString[DimensionName + "DimensionPresentation"] + """";
				
			EndDo;
			CurrentRecordSet.Read();
			
			If CurrentRecordSet.CheckFilling() Then
				Continue;
			EndIf;
			IssueSummary = ObjectFillingErrors();
			
			RecordSetStructure = New Structure;
			RecordSetStructure.Insert("Period", ResultString.Period);
			For Each Dimension In Dimensions Do
				DimensionRef = ResultString[Dimension.Name + "DimensionRef"];
				RecordSetStructure.Insert(Dimension.Name, DimensionRef);
			EndDo;
			
			Issue = IssueDetails(Common.MetadataObjectID(MetadataObject), CheckParameters);
			
			Issue.IssueSummary        = StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = 'У записи с полями:
				|%1,
				|обнаружены незаполненные данные, обязательные к заполнению: %2'; 
				|en = 'Mandatory data is not filled for record with fields:
				|%1
				|: %2'; 
				|pl = 'Mandatory data is not filled for record with fields:
				|%1
				|: %2';
				|de = 'Mandatory data is not filled for record with fields:
				|%1
				|: %2';
				|ro = 'Mandatory data is not filled for record with fields:
				|%1
				|: %2';
				|tr = 'Mandatory data is not filled for record with fields:
				|%1
				|: %2'; 
				|es_ES = 'Mandatory data is not filled for record with fields:
				|%1
				|: %2'"), RecordSetFilterPresentation, Chars.LF + IssueSummary);
			Issue.AdditionalInformation = New ValueStorage(RecordSetStructure);
			WriteIssue(Issue, CheckParameters);
			
		EndDo;
		
		If IsFirstPass Then
			IsFirstPass = False;
			Query.Text = QueryTextWithCondition;
		EndIf;
		
		Query.SetParameter("Period", ResultString.Period);
		For Each Dimension In Dimensions Do
			Query.SetParameter(Dimension.Name, ResultString[Dimension.Name + "DimensionRef"]);
		EndDo;
		
		DataCountTotal = DataCountTotal + Result.Count();
		If ModulePerformanceMonitor <> Undefined Then
			ModulePerformanceMonitor.EndTimeConsumingOperationMeasurement(MeasurementDetails, DataCountTotal);
		EndIf;
		
		Result = Query.Execute().Unload();
		
	EndDo;
	
EndProcedure

#EndRegion

#Region CheckCircularRefs

Procedure FindCircularRefs(MetadataObject, CheckParameters)
	
	FullName = MetadataObject.FullName();
	Attributes = MetadataObject.Attributes;
	
	QueryText = 
	"SELECT TOP 1000
	|	MetadataObject.Ref AS ObjectWithIssue,
	|	REFPRESENTATION(MetadataObject.Ref) AS Presentation,
	|	MetadataObject.Parent AS Parent
	|FROM
	|	&MetadataObject AS MetadataObject
	|WHERE
	|	MetadataObject.Ref > &Ref
	|
	|ORDER BY
	|	MetadataObject.Ref";
	
	QueryText = StrReplace(QueryText, "&MetadataObject", FullName);
	
	Query = New Query(QueryText);
	Query.SetParameter("Ref", "");
	
	Result = Query.Execute().Unload();
	
	CheckedItems = New Map;
	While Result.Count() > 0 Do
		
		For Each ResultString In Result Do
			
			ObjectRef = ResultString.ObjectWithIssue;
			If CheckedItems[ObjectRef] <> Undefined Then
				Continue;
			EndIf;
			
			ItemsToCheck = New Array;
			If CheckLevelsLooping(ObjectRef, ResultString.Parent, ItemsToCheck) Then
				
				Path = "";
				Presentations = Common.ObjectsAttributesValues(ItemsToCheck, New Structure("Presentation", "RefPresentation(Ref)"));
				For Each LoopItem In ItemsToCheck Do
					Path = Path + ?(ValueIsFilled(Path), " -> ", "") + Presentations[LoopItem].Value;
					CheckedItems[LoopItem] = True;
				EndDo;
				
				ObjectPresentation = ResultString.Presentation;
				If ValueIsFilled(Path) Then
					IssueSummary = ObjectPresentation + " -> " + Path + " -> " + ObjectPresentation;
				Else
					IssueSummary = ObjectPresentation + " -> " + ObjectPresentation;
				EndIf;
				
				Issue = IssueDetails(ObjectRef, CheckParameters);
				
				Issue.IssueSummary = IssueSummary;
				If Attributes.Find("EmployeeResponsible") <> Undefined Then
					Issue.Insert("EmployeeResponsible", Common.ObjectAttributeValue(ObjectRef, "EmployeeResponsible"));
				EndIf;
				
				WriteIssue(Issue, CheckParameters);
				
			EndIf;
			
		EndDo;
		
		Query.SetParameter("Ref", ResultString.ObjectWithIssue);
		Result = Query.Execute().Unload();
		
	EndDo;
	
EndProcedure

Function CheckLevelsLooping(Val ObjectRef, Val CurrentParent, Val AllItems)
	
	While ValueIsFilled(CurrentParent) Do
		If ObjectRef = CurrentParent Then
			Return True;
		EndIf;
		AllItems.Add(CurrentParent);
		CurrentParent = Common.ObjectAttributeValue(CurrentParent, "Parent");
	EndDo;	
	Return False;
	
EndFunction

Function HasHierarchy(StandardAttributes)
	
	HasHierarchy = False;
	For Each StandardAttribute In StandardAttributes Do
		If StandardAttribute.Name = "Parent" Then
			HasHierarchy = True;
			Break;
		EndIf;
	EndDo;
	
	Return HasHierarchy;
	
EndFunction

// Corrects circular references as follows: the one that has more terminal subordinate items remains 
// a parent.
//
// Parameters:
//   Check - CatalogRef.AccountingCheckRules - a check, whose found issues are corrected using this 
//              method.
//
Procedure CorrectCircularRefsProblem(CheckSSL)
	
	DescendantsTable = New ValueTable;
	DescendantsTable.Columns.Add("LoopItem");
	DescendantsTable.Columns.Add("ChildrenCount", New TypeDescription("Number"));
	
	Query = New Query(
	"SELECT
	|	AccountingCheckResults.ObjectWithIssue AS ObjectWithIssue
	|FROM
	|	InformationRegister.AccountingCheckResults AS AccountingCheckResults
	|WHERE
	|	NOT AccountingCheckResults.IgnoreIssue
	|	AND AccountingCheckResults.CheckRule = &CheckRule");
	
	Query.SetParameter("CheckRule", CheckSSL);
	Result = Query.Execute().Select();
	
	While Result.Next() Do
		
		ProblemObjectRef = Result.ObjectWithIssue;
		Parent = Common.ObjectAttributeValue(ProblemObjectRef, "Parent");
		
		ItemsToCheck = New Array;
		If Not CheckLevelsLooping(ProblemObjectRef, Parent, ItemsToCheck) Then
			Continue;
		EndIf;
			
		LoopLastObject = ItemsToCheck[ItemsToCheck.Count() - 1];
		
		FirstLoopChildrenCount = ChildItemsCount(ProblemObjectRef, Parent);
		SecondLoopChildrenCount = ChildItemsCount(LoopLastObject, Parent);
		
		ObjectWithIssue = ?(FirstLoopChildrenCount > SecondLoopChildrenCount, ProblemObjectRef, LoopLastObject);
		ObjectWithIssue = ObjectWithIssue.GetObject();
		ObjectWithIssue.Parent = Common.ObjectManagerByFullName(ProblemObjectRef.Metadata().FullName()).EmptyRef();
		ObjectWithIssue.DataExchange.Load = True;
		ObjectWithIssue.Write();
		
	EndDo;
	
EndProcedure

Function ChildItemsCount(ObjectRef, SelectionExclusion, Val InitialValue = 0)
	
	ChildrenCount = InitialValue;
	
	QueryText =
	"SELECT
	|	MetadataObject.Ref AS Ref
	|FROM
	|	&MetadataObject AS MetadataObject
	|WHERE
	|	MetadataObject.Parent = &Parent
	|	AND MetadataObject.Ref <> &SelectionExclusion";
	
	QueryText = StrReplace(QueryText, "&MetadataObject", ObjectRef.Metadata().FullName());
	
	Query = New Query(QueryText);
	Query.SetParameter("Parent",          ObjectRef);
	Query.SetParameter("SelectionExclusion", SelectionExclusion);
	Result = Query.Execute();
	
	If Not Result.IsEmpty() Then
		DataExported        = Result.Unload();
		ChildrenCount = ChildrenCount + DataExported.Count();
		For Each DescendantItem In DataExported Do
			ChildrenCount = ChildItemsCount(DescendantItem.Ref, SelectionExclusion, ChildrenCount);
		EndDo;
	EndIf;
	Return ChildrenCount;
	
EndFunction

#EndRegion

#Region CheckNoPredefinedItems

Procedure FindMissingPredefinedItems(MetadataObject, CheckParameters)
	
	FullName                = MetadataObject.FullName();
	PredefinedItems = MetadataObject.GetPredefinedNames();
	For Each PredefinedItem In PredefinedItems Do
		
		If StrStartsWith(Upper(PredefinedItem), "DELETE") Then
			Continue;
		EndIf;
		
		FoundItem = Common.PredefinedItem(FullName + "." + PredefinedItem);
		If FoundItem <> Undefined Then
			Continue;
		EndIf;
			
		Issue = IssueDetails(Common.MetadataObjectID(MetadataObject), CheckParameters);
		Issue.IssueSummary = StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = 'Предопределенный элемент ""%1"" отсутствует в информационной базе.'; en = 'Predefined item ""%1"" missing in information database.'; pl = 'Predefined item ""%1"" missing in information database.';de = 'Predefined item ""%1"" missing in information database.';ro = 'Predefined item ""%1"" missing in information database.';tr = 'Predefined item ""%1"" missing in information database.'; es_ES = 'Predefined item ""%1"" missing in information database.'"), PredefinedItem);
		WriteIssue(Issue, CheckParameters);
		
	EndDo;
	
EndProcedure

#EndRegion

#Region CheckDuplicatePredefinedItems

Procedure FindPredefinedItemsDuplicates(MetadataKind, CheckParameters)
	
	Packages        = "";
	PackagesTemplate =
	"SELECT
	|	""&Table"" AS FullName,
	|	&OtherFields
	|FROM
	|	&Table AS Table
	|WHERE Table.Predefined
	|
	|GROUP BY
	|	Table.PredefinedDataName
	|
	|HAVING
	|	COUNT(DISTINCT Table.Ref) > 1";
	
	Selections       = "";
	SelectionTemplate =
	"SELECT
	|	&TemporaryTableFields,
	|	RefPresentation(Table.Ref) AS DuplicateItemRef
	|FROM
	|	&Table AS Table
	|		INNER JOIN (SELECT ""&TempTable"") AS TempTable
	|		ON &ConnectionConditions";
	
	QueryParameters = New Structure;
	
	For Each MetadataObject In MetadataKind Do
		
		If MetadataObject.PredefinedDataUpdate = Metadata.ObjectProperties.PredefinedDataUpdate.DontAutoUpdate Then
			Continue;
		EndIf;
		
		FullName           = MetadataObject.FullName();
		TempTableName = "TT_" + StrReplace(FullName, ".", "");
		
		PackagesTemplateItem = StrReplace(PackagesTemplate, "&OtherFields",
			"Table.PredefinedDataName AS PredefinedDataName INTO " + TempTableName);
		PackagesTemplateItem = StrReplace(PackagesTemplateItem, "&Table", FullName);
		
		Packages = Packages + ?(ValueIsFilled(Packages), ";", "") + PackagesTemplateItem;
		
		ParameterSuffix      = StrReplace(FullName, ".", "_");
		SelectionTemplateItem = StrReplace(SelectionTemplate, "&TemporaryTableFields",
			"&ObjectWithIssue" + ParameterSuffix + " AS ObjectWithIssue, TempTable.PredefinedDataName AS PredefinedDataName");
		
		QueryParameters.Insert("ObjectWithIssue" + ParameterSuffix, Common.MetadataObjectID(FullName));
		
		SelectionTemplateItem = StrReplace(SelectionTemplateItem, "&Table", FullName);
		SelectionTemplateItem = StrReplace(SelectionTemplateItem, "(SELECT ""&TempTable"")", TempTableName);
		SelectionTemplateItem = StrReplace(SelectionTemplateItem, "&ConnectionConditions",
			"Table.PredefinedDataName = TempTable.PredefinedDataName");
		
		Selections = Selections + ?(ValueIsFilled(Selections), " UNION ALL ", "") + SelectionTemplateItem;
		
	EndDo;
	
	If Not ValueIsFilled(Packages) Then
		Return;
	EndIf;
   
	Query = New Query(Packages + ";" + Selections + " TOTALS BY ObjectWithIssue, PredefinedDataName");
	Query.TempTablesManager = New TempTablesManager;
	
	For Each QueryParameter In QueryParameters Do
		Query.SetParameter(QueryParameter.Key, QueryParameter.Value);
	EndDo;
	
	CommonResult = Query.Execute().Select(QueryResultIteration.ByGroups);
	
	While CommonResult.Next() Do
		
		IssueSummary                 = "";
		ResultByPredefinedItemName = CommonResult.Select(QueryResultIteration.ByGroups);
		
		While ResultByPredefinedItemName.Next() Do
			
			PredefinedDataName = ResultByPredefinedItemName.PredefinedDataName;
			
			If StrStartsWith(Upper(PredefinedDataName), "DELETE") Then
				Continue;
			EndIf;
			
			IssueSummary = IssueSummary + ?(ValueIsFilled(IssueSummary), Chars.LF, "")
				+ NStr("ru = 'Имя предопределенного элемента:'; en = 'Name of the predefined item:'; pl = 'Name of the predefined item:';de = 'Name of the predefined item:';ro = 'Name of the predefined item:';tr = 'Name of the predefined item:'; es_ES = 'Name of the predefined item:'") + " """ + PredefinedDataName + """"
				+ Chars.LF + NStr("ru = 'Ссылки на предопределенный элемент:'; en = 'References to the predefined item:'; pl = 'References to the predefined item:';de = 'References to the predefined item:';ro = 'References to the predefined item:';tr = 'References to the predefined item:'; es_ES = 'References to the predefined item:'");
				
			DetailedRecords = ResultByPredefinedItemName.Select();
			While DetailedRecords.Next() Do
				IssueSummary = IssueSummary + ?(ValueIsFilled(IssueSummary), Chars.LF, "")
					+ " • """ + DetailedRecords.DuplicateItemRef + """";
			EndDo;
			
		EndDo;
		
		If Not ValueIsFilled(IssueSummary) Then
			Continue;
		EndIf;
		
		Issue = IssueDetails(CommonResult.ObjectWithIssue, CheckParameters);
		Issue.IssueSummary = IssueSummary;
		WriteIssue(Issue, CheckParameters);
		
	EndDo;
	
	Query.TempTablesManager.Close();
	
EndProcedure

#EndRegion

#Region OtherProceduresAndFunctions

Function ReadParameters(CheckExecutionParameters)
	Result = New Structure("FullName, MetadataObject, ValidationArea");
	If CheckExecutionParameters.Count() <> 1 Then
		Return Undefined;
	EndIf;
	
	ParametersStructure = CheckExecutionParameters[0];
	If TypeOf(ParametersStructure) <> Type("Structure") Then
		Return Undefined;
	EndIf;
	
	If ParametersStructure.Property1 <> "ObjectToCheck" Then
		Return Undefined;
	EndIf;
	
	Result.FullName = ParametersStructure.Property2;
	
	If StandardSubsystemsServer.IsRegisterTable(Result.FullName) Then
		Result.ValidationArea = "Registers";
	Else
		Result.ValidationArea = "RefObjects";
	EndIf;
	Result.MetadataObject = Metadata.FindByFullName(Result.FullName);
	
	Return Result;
EndFunction

Function ObjectWithIssuePresentation(ObjectWithIssue, ProblemObjectPresentation, AdditionalInformation) Export
	
	Result = ProblemObjectPresentation + " (" + ObjectWithIssue.Metadata().Presentation() + ")";
	If TypeOf(ObjectWithIssue) <> Type("CatalogRef.MetadataObjectIDs") Then
		Return Result;
	EndIf;
	
	Result = String(ObjectWithIssue) + "<ListDetails>" + Chars.LF + ObjectWithIssue.FullName;
	If Not Common.IsRegister(Metadata.FindByFullName(ObjectWithIssue.FullName)) Then
		Return Result;
	EndIf;
		
	SetStructure  = AdditionalInformation.Get();
	If TypeOf(SetStructure) <> Type("Structure") Then
		Return Result;
	EndIf;
	
	For Each SetItem In SetStructure Do
		
		FilterValue    = SetItem.Value;
		FilterValueType = TypeOf(FilterValue);
		TypeInformation   = "";
		
		If FilterValueType = Type("Number") Then
			TypeInformation = "Number";
		ElsIf FilterValueType = Type("String") Then
			TypeInformation = "String";
		ElsIf FilterValueType = Type("Boolean") Then
			TypeInformation = "Boolean";
		ElsIf FilterValueType = Type("Date") Then
			TypeInformation = "Date";
		ElsIf Common.IsReference(FilterValueType) Then
			TypeInformation = FilterValue.Metadata().FullName();
		EndIf;
		
		Result = Result + Chars.LF + String(SetItem.Key) + "~~~" + TypeInformation + "~~~" + String(XMLString(FilterValue));
		
	EndDo;
	
	Return Result;
	
EndFunction

// See AccountingAudit.SubsystemAvailable. 
Function SubsystemAvailable() Export
	
	Return AccessRight("View", Metadata.InformationRegisters.AccountingCheckResults);
	
EndFunction

Function IsSharedMetadataObject(FullName)
	
	If Common.SubsystemExists("StandardSubsystems.SaaS") Then
		
		ModuleSaaS = Common.CommonModule("SaaS");
		Return Not ModuleSaaS.IsSeparatedMetadataObject(FullName);
		
	EndIf;
	
	Return False;
	
EndFunction

Function ObjectFillingErrors()
	
	IssueSummary = "";
	For Each UserMessage In GetUserMessages(True) Do
		IssueSummary = IssueSummary + ?(ValueIsFilled(IssueSummary), Chars.LF, "") + UserMessage.Text;
	EndDo;
	
	Return ?(IsBlankString(IssueSummary), NStr("ru = 'Для подробной информации необходимо открыть форму объекта.'; en = 'For more information, open the object form.'; pl = 'For more information, open the object form.';de = 'For more information, open the object form.';ro = 'For more information, open the object form.';tr = 'For more information, open the object form.'; es_ES = 'For more information, open the object form.'"), IssueSummary);
	
EndFunction

Function CheckRunning(ScheduledJobID)
	
	Result = False;
	If ValueIsFilled(ScheduledJobID) Then
		Job = BackgroundJobs.FindByUUID(New UUID(ScheduledJobID));
		If Job <> Undefined AND Job.State = BackgroundJobState.Active Then
			Result = True;
		EndIf;
	EndIf;
	
	Return Result;
	
EndFunction

// Prepares the data required to perform an accounting check.
//
// Parameters:
//     Check - CatalogRef.AccountingCheckRules - a check, whose parameters need to be prepared.
//                
//     CheckExecutionParameters - Structure, Array - arbitrary additional check parameters that 
//                                   clarify what and how exactly to check.
//       - Structure - one execution parameter. See the property composition at AccountingAudit. CheckExecutionParameters.
//       - Array - several check parameters (array elements of the Structure type, as described above).
//
// Returns:
//   Structure - see the CheckParameters parameter in the AccountingAudit.IssueDetails.
//
Function PrepareCheckParameters(Val CheckSSL, Val CheckExecutionParameters)
	
	CheckParameters = Common.ObjectAttributesValues(CheckSSL, "CheckStartDate, ID,
		|ScheduledJobID, IssuesLimit, Description, IssueSeverity, RunMethod,
		|AccountingChecksContext, AccountingCheckContextClarification");
	
	If Not CheckParameters.Property("CheckWasStopped") Then
		CheckParameters.Insert("CheckWasStopped", False);
	EndIf;
	If Not CheckParameters.Property("ManualStart") Then
		CheckParameters.Insert("ManualStart", True);
	EndIf;
	
	CheckParameters.Insert("CheckSSL",            CheckSSL);
	CheckParameters.Insert("GlobalSettings", GlobalSettings());
	CheckParameters.Insert("CheckIteration",    1);
	
	If CheckExecutionParameters = Undefined Then
		ChecksGroup = Common.ObjectAttributeValue(CheckSSL, "Parent");
		If ChecksGroup <> Undefined AND Not ChecksGroup.IsEmpty() Then
			CheckID = Common.ObjectAttributeValue(ChecksGroup, "ID");
		Else
			CheckID = CheckParameters.ID;
		EndIf;
		CheckExecutionParameters = New Array;
		CheckExecutionParameters.Add(CheckExecutionParameters(CheckID));
	EndIf;	
	CheckParameters.Insert("CheckExecutionParameters", CheckExecutionParameters);
	
	Return CheckParameters;
	
EndFunction

// See AccountingAudit.ClearPreviousChecksResults. 
Procedure ClearPreviousCheckResults(CheckSSL, CheckExecutionParameters) Export
	
	For Each CheckExecutionParameter In CheckExecutionParameters Do
		
		CheckKind = CheckKind(CheckExecutionParameter, True);
		If Not ValueIsFilled(CheckKind) Then
			Continue;
		EndIf;
		
		Set = InformationRegisters.AccountingCheckResults.CreateRecordSet();
		Set.Filter.CheckRule.Set(CheckSSL);
		Set.Filter.CheckKind.Set(CheckKind);
		Set.Filter.IgnoreIssue.Set(False);
		Set.Write();
		
	EndDo;
	
EndProcedure

// Checks whether the number of the allowed limit check iterations is exceeded.
//
// Parameters:
//   CheckParameters - Structure - see the CheckParameters parameter in AccountingAudit.IssueDetails.
//
// Returns:
//   Boolean - indicates whether the last iteration has been reached or not.
//
Function IsLastCheckIteration(CheckParameters)
	
	IsLastIteration = False;
	
	If CheckParameters.IssuesLimit <> 0 Then
		If CheckParameters.CheckIteration > CheckParameters.IssuesLimit Then
			IsLastIteration = True;
		Else
			CheckParameters.Insert("CheckIteration", CheckParameters.CheckIteration + 1);
		EndIf;
	EndIf;
	
	Return IsLastIteration;
	
EndFunction

// Returns a metadata object kind string presentation by the object type.
// Restriction: does not process business process route points.
//
// Parameters:
//  ObjectRef - AnyRef - a reference to a problem object.
//
// Returns:
//  String - metadata object kind presentation. For example: "Catalog", "Document".
//
Function ObjectPresentationByType(ObjectRef)
	
	ObjectType = TypeOf(ObjectRef);
	
	If Catalogs.AllRefsType().ContainsType(ObjectType) Then
		
		Return NStr("ru = 'элементом справочника'; en = 'catalog item'; pl = 'catalog item';de = 'catalog item';ro = 'catalog item';tr = 'catalog item'; es_ES = 'catalog item'");
	
	ElsIf Documents.AllRefsType().ContainsType(ObjectType) Then
		Return NStr("ru = 'документом'; en = 'document'; pl = 'document';de = 'document';ro = 'document';tr = 'document'; es_ES = 'document'");
	
	ElsIf BusinessProcesses.AllRefsType().ContainsType(ObjectType) Then
		Return NStr("ru = 'бизнес процессом'; en = 'business process'; pl = 'business process';de = 'business process';ro = 'business process';tr = 'business process'; es_ES = 'business process'");
	
	ElsIf ChartsOfCharacteristicTypes.AllRefsType().ContainsType(ObjectType) Then
		Return NStr("ru = 'планом видов характеристик'; en = 'chart of characteristic types'; pl = 'chart of characteristic types';de = 'chart of characteristic types';ro = 'chart of characteristic types';tr = 'chart of characteristic types'; es_ES = 'chart of characteristic types'");
	
	ElsIf ChartsOfAccounts.AllRefsType().ContainsType(ObjectType) Then
		Return NStr("ru = 'планом счетов'; en = 'chart of accounts'; pl = 'chart of accounts';de = 'chart of accounts';ro = 'chart of accounts';tr = 'chart of accounts'; es_ES = 'chart of accounts'");
	
	ElsIf ChartsOfCalculationTypes.AllRefsType().ContainsType(ObjectType) Then
		Return NStr("ru = 'планом видов расчета'; en = 'chart of calculation types'; pl = 'chart of calculation types';de = 'chart of calculation types';ro = 'chart of calculation types';tr = 'chart of calculation types'; es_ES = 'chart of calculation types'");
	
	ElsIf Tasks.AllRefsType().ContainsType(ObjectType) Then
		Return NStr("ru = 'задачей'; en = 'task'; pl = 'task';de = 'task';ro = 'task';tr = 'task'; es_ES = 'task'");
	
	ElsIf ExchangePlans.AllRefsType().ContainsType(ObjectType) Then
		Return NStr("ru = 'планом обмена'; en = 'exchange plan'; pl = 'exchange plan';de = 'exchange plan';ro = 'exchange plan';tr = 'exchange plan'; es_ES = 'exchange plan'");
	
	ElsIf Enums.AllRefsType().ContainsType(ObjectType) Then
		Return NStr("ru = 'перечислением'; en = 'enumeration'; pl = 'enumeration';de = 'enumeration';ro = 'enumeration';tr = 'enumeration'; es_ES = 'enumeration'");
	
	Else
		Raise StringFunctionsClientServer.SubstituteParametersToString(NStr("ru='Неверный тип значения параметра (%1)'; en = 'Invalid parameter value type (%1)'; pl = 'Invalid parameter value type (%1)';de = 'Invalid parameter value type (%1)';ro = 'Invalid parameter value type (%1)';tr = 'Invalid parameter value type (%1)'; es_ES = 'Invalid parameter value type (%1)'"), String(ObjectType));
	
	EndIf;
	
EndFunction

// Returns the String, Array, and CatalogRef.ChecksKinds types to check the parameters of methods 
// working with the check kinds.
//
// Returns:
//    Array - object types.
//
Function TypeDetailsCheckKind() Export
	
	TypesArray = New Array;
	TypesArray.Add(Type("String"));
	TypesArray.Add(Type("Array"));
	TypesArray.Add(Type("CatalogRef.ChecksKinds"));
	
	Return TypesArray;
	
EndFunction

// Returns allowed parameter types of the check.
//
// Returns:
//    Structure - see AccountingAuditInternal.PrepareCheckParameters. 
//
Function CheckParametersPropertiesExpectedTypes() Export
	
	PropertiesTypesToExpect = New Structure;
	PropertiesTypesToExpect.Insert("IssueSeverity",                  Type("EnumRef.AccountingIssueSeverity"));
	PropertiesTypesToExpect.Insert("GlobalSettings",               Type("Structure"));
	PropertiesTypesToExpect.Insert("CheckStartDate",                Type("Date"));
	PropertiesTypesToExpect.Insert("ID",                     Type("String"));
	PropertiesTypesToExpect.Insert("ScheduledJobID", Type("String"));
	PropertiesTypesToExpect.Insert("CheckIteration",                  Type("Number"));
	PropertiesTypesToExpect.Insert("IssuesLimit",                      Type("Number"));
	PropertiesTypesToExpect.Insert("Description",                      Type("String"));
	PropertiesTypesToExpect.Insert("CheckSSL",                          Type("CatalogRef.AccountingCheckRules"));
	
	Return PropertiesTypesToExpect;
	
EndFunction

// Returns allowed parameter types of check kinds. See the PropertyN attributes of the ChecksKinds catalog.
//
// Returns:
//   TypesDetails - all reference types as well as the Boolean, String, Number, and Date types.
//
Function ExpectedPropertiesTypesOfChecksKinds() Export
	
	TypesArray = New Array;
	TypesArray.Add(Type("Boolean"));
	TypesArray.Add(Type("String"));
	TypesArray.Add(Type("Date"));
	TypesArray.Add(Type("Number"));
	
	Return New TypeDescription(Common.AllRefsTypeDetails(), TypesArray);
	
EndFunction

// Returns allowed property types of issue description.
//
// Parameters:
//   IssueFullDetails          - Boolean - it affects the composition of return value properties.
//
// Returns:
//    Issue                       - Structure - an issue property types:
//        * ObjectWithIssue - AnyRef - a reference to the object that is the Source of issues.
//        * CheckRule          - CatalogRef.AccountingCheckRules - a reference to the executed check.
//        * CheckKind              - CatalogRef.ChecksKinds - a reference to a check kind.
//                                     
//        * IssueSummary        - String - a string summary of the found issue.
//        * UniqueKey - UUID - an issue unique key.
//                                     It is returned if IssueFullDetails = True.
//        * IssueSeverity         - EnumRef.AccountingIssueSeverity - an accounting issue severity.
//                                     "Information", "Warning", "Error", and "UsefulTip".
//                                     It is returned if IssueFullDetails = True.
//        * ResponsiblePerson            - CatalogRef.Users - it is filled in if it is possible to 
//                                     identify a person responsible for the problematic object.
//                                     It is returned if IssueFullDetails = True.
//        * IgnoreIssue     - Boolean - a flag of ignoring an issue. If the value is True, the 
//                                     subsystem ignores the record about an issue.
//                                     It is returned if IssueFullDetails = True.
//        * AdditionalInformation - ValueStorage - a service property with additional information 
//                                     related to the detected issue.
//                                     It is returned if IssueFullDetails = True.
//        * Detected                 - Date - server time of the issue identification.
//                                     It is returned if IssueFullDetails = True.
//
Function IssueDetailsPropertiesTypesToExpect(Val IssueFullDetails = True) Export
	
	PropertiesTypesToExpect = New Structure;
	PropertiesTypesToExpect.Insert("ObjectWithIssue",  Common.AllRefsTypeDetails());
	PropertiesTypesToExpect.Insert("CheckRule",   Type("CatalogRef.AccountingCheckRules"));
	PropertiesTypesToExpect.Insert("CheckKind",       Type("CatalogRef.ChecksKinds"));
	PropertiesTypesToExpect.Insert("IssueSummary", Type("String"));
	
	If IssueFullDetails Then
		PropertiesTypesToExpect.Insert("IssueSeverity",         Type("EnumRef.AccountingIssueSeverity"));
		PropertiesTypesToExpect.Insert("Detected",                 Type("Date"));
		PropertiesTypesToExpect.Insert("UniqueKey",         Type("UUID"));
		PropertiesTypesToExpect.Insert("AdditionalInformation", Type("ValueStorage"));
		ResponsiblePersonTypes = New Array;
		ResponsiblePersonTypes.Add(Type("CatalogRef.Users"));
		ResponsiblePersonTypes.Add(Type("Undefined"));
		PropertiesTypesToExpect.Insert("EmployeeResponsible", ResponsiblePersonTypes);
	EndIf;
	
	Return PropertiesTypesToExpect;
	
EndFunction

Function MetadataObjectsRefKinds()
	
	Result = New Array;
	Result.Add(Metadata.Catalogs);
	Result.Add(Metadata.Documents);
	Result.Add(Metadata.ExchangePlans);
	Result.Add(Metadata.ChartsOfCharacteristicTypes);
	Result.Add(Metadata.ChartsOfAccounts);
	Result.Add(Metadata.ChartsOfCalculationTypes);
	Result.Add(Metadata.BusinessProcesses);
	Result.Add(Metadata.Tasks);
	Return Result;
	
EndFunction

Function RegistersAsMetadataObjects()
	
	Result = New Array;
	Result.Add(Metadata.AccountingRegisters);
	Result.Add(Metadata.AccumulationRegisters);
	Result.Add(Metadata.CalculationRegisters);
	Result.Add(Metadata.InformationRegisters);
	Return Result;
	
EndFunction

#Region IgnoreIssuesInternal

// Generates the ProblemObject, CheckRule, and CheckKind dimensions checksum and the 
// IssueClarification resource by the MD5 algorithm.
//
// Parameters:
//   Issue - Structure - see the AccountingAudit.WriteIssue parameter.
//
// Returns:
//    String - a dimension checksum of the check result register: ProblemObject,
//             CheckRule, CheckKind, and the IssueSummary resource by the MD5 algorithm.
//
Function IssueChecksum(Issue) Export
	
	IssueStructure = New Structure("ObjectWithIssue, CheckRule, CheckKind, IssueSummary");
	FillPropertyValues(IssueStructure, Issue);
	Return Common.CheckSumString(IssueStructure);
	
EndFunction

// Returns True if an issue was ignored.
//
// Parameters:
//   Checksum - String - a register record checksum by the MD5 algorithm.
//
Function ThisIssueIgnored(Checksum)
	
	Query = New Query(
	"SELECT TOP 1
	|	AccountingCheckResults.ObjectWithIssue AS ObjectWithIssue
	|FROM
	|	InformationRegister.AccountingCheckResults AS AccountingCheckResults
	|WHERE
	|	AccountingCheckResults.Checksum = &Checksum
	|	AND AccountingCheckResults.IgnoreIssue");
	
	Query.SetParameter("Checksum", Checksum);
	Return Not Query.Execute().IsEmpty();
	
EndFunction

#EndRegion

#EndRegion

#EndRegion
