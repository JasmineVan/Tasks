///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

#Region ForCallsFromOtherSubsystems

// StandardSubsystems.ReportsOptions

// The settings of the common report form of the "Reports options" subsystem.
//
// Parameters:
//   Form - ManagedForm, Undefined - a report form or a report settings form.
//       Undefined when called without a context.
//   OptionKey - String, Undefined - a name of a predefined report option or a UUID of a 
//       user-defined report option.
//       Undefined when called without a context.
//   Settings - Structure - see the return value of
//       ReportsClientServer.GetDefaultReportSettings().
//
Procedure DefineFormSettings(Form, OptionKey, Settings) Export
	
	Settings.SelectAndEditOptionsWithoutSavingAllowed = True;
	Settings.HideBulkEmailCommands                              = True;
	Settings.GenerateImmediately                                   = True;
	
	Settings.Events.OnCreateAtServer               = True;
	Settings.Events.BeforeImportSettingsToComposer = True;
	Settings.Events.BeforeLoadVariantAtServer    = True;
	
EndProcedure

// This procedure is called in the OnLoadVariantAtServer event handler of a report form after executing the form code.
//
// Parameters:
//   Form - ManagedForm - a report form.
//   Cancel - Boolean - passed from the OnCreateAtServer standard handler parameters "as it is".
//   StandardProcessing - Boolean - passed from the OnCreateAtServer standard handler parameters "as it is".
//
Procedure OnCreateAtServer(Form, Cancel, StandardProcessing) Export
	
	FormParameters = Form.Parameters;
	If FormParameters.Property("ObjectRef") Then
		
		ProcedureName = "AccountingAuditClient.OpenObjectIssuesReport";
		CommonClientServer.CheckParameter(ProcedureName, "Form", Form, Type("ManagedForm"));
		CommonClientServer.CheckParameter(ProcedureName, "ObjectWithIssue", FormParameters.ObjectRef, Common.AllRefsTypeDetails());
		CommonClientServer.CheckParameter(ProcedureName, "StandardProcessing", StandardProcessing, Type("Boolean"));
		
		DataParametersStructure = New Structure("Context", FormParameters.ObjectRef);
		SetDataParameters(SettingsComposer.Settings, DataParametersStructure);
		
	ElsIf FormParameters.Property("ContextData") Then
		
		If TypeOf(FormParameters.ContextData) = Type("Structure") Then
			
			ContextData  = FormParameters.ContextData;
			SelectedRows = ContextData.SelectedRows;
			
			If SelectedRows.Count() > 0 Then
				
				ObjectsWithIssues = AccountingAuditInternal.ObjectsWithIssues(ContextData.SelectedRows);
				
				If ObjectsWithIssues.Count() = 0 Then
					Cancel = True;
				Else
					
					ProblemObjectsList = New ValueList;
					ProblemObjectsList.LoadValues(ObjectsWithIssues);
					
					DataParametersStructure = New Structure("Context", ProblemObjectsList);
					SetDataParameters(SettingsComposer.Settings, DataParametersStructure);
					
				EndIf;
				
			EndIf;
			
		EndIf;
		
	ElsIf FormParameters.Property("RefsArray") Then
		
		RefsArray = FormParameters.RefsArray;
		If RefsArray.Count() > 0 Then
			
			ProblemObjectsList = New ValueList;
			ProblemObjectsList.LoadValues(RefsArray);
			
			DataParametersStructure = New Structure("Context", ProblemObjectsList);
			SetDataParameters(SettingsComposer.Settings, DataParametersStructure);
			
		EndIf;
		
	ElsIf FormParameters.Property("CheckKind") Then
		
		CommonClientServer.CheckParameter("AccountingAuditClient.OpenIssuesReport", "CheckKind", 
			FormParameters.CheckKind, AccountingAuditInternal.TypeDetailsCheckKind());
		
		DetailedInformationOnChecksKinds = AccountingAudit.DetailedInformationOnChecksKinds(FormParameters.CheckKind);
		If DetailedInformationOnChecksKinds.Count() = 0 Then
			Cancel = True;
		Else
			SettingsComposer.Settings.AdditionalProperties.Insert("IssuesList", PrepareChecksList(CommonClientServer.CollapseArray(
				DetailedInformationOnChecksKinds.UnloadColumn("CheckRule"))));
		EndIf;
		
	ElsIf FormParameters.Property("CommandParameter") Then
		
		If TypeOf(FormParameters.CommandParameter) = Type("Array") AND FormParameters.CommandParameter.Count() > 0 Then
			SettingsComposer.Settings.AdditionalProperties.Insert("IssuesList", PrepareChecksList(FormParameters.CommandParameter));
		EndIf;
		
	EndIf;
	
EndProcedure

// Called before importing new settings. Used to change composition schema.
//   For example, if the report schema depends on the option key or report parameters.
//   For the schema changes to take effect, call the ReportsServer.EnableSchema() method.
//
// Parameters:
//   Context - Arbitrary -
//       The context parameters where the report is used.
//       Used to pass the ReportsServer.EnableSchema() method in the parameters.
//   SchemaKey - String -
//       An ID of the current setting composer schema.
//       It is not filled in by default (that means, the composer is initialized according to the main schema).
//       Used for optimization, to reinitialize composer as rarely as possible.
//       It is possible not to use it if the initialization is running unconditionally.
//   OptionKey - String, Undefined - 
//       predefined report option name or UUID of a custom one.
//       Undefined when called for a detail option or without context.
//   NewDCSettings - DataCompositionSettings, Undefined -
//       Settings for the report option that will be imported into the settings composer after it is initialized.
//       Undefined when option settings do not need to be imported (already imported earlier).
//   NewDCUserSettings - DataCompositionUserSettings, Undefined -
//       User settings that will be imported into the settings composer after it is initialized.
//       Undefined when user settings do not need to be imported (already imported earlier).
//
// Call options:
//   If SchemaKey <> "1" Then
//   	SchemaKey = "1";
//   	DCSchema = GetCommonTemplate("MyCommonCompositionSchema");
//   	ReportsServer.EnableSchema(ThisObject, Context, DCSchema, SchemaKey);
//   EndIf; - a report composer is initialized based on the schema from common templates.
//   If ValueType(NewDCSettings) = Type("DataCompositionUserSettings") Then
//   	FullMetadataObjectName = "";
//   	For Each DCItem From NewDCUserSettings.Items Loop
//   		If ValueType(DCItem) = Type("DataCompositionSettingsParameterValue") Then
//   			ParameterName = String(DCItem.Parameter);
//   			If ParameterName = "MetadataObject" Then
//   				FullMetadataObjectName = DCItem.Value;
//   			EndIf.
//   		EndIf.
//   	EndDo;
//   	If SchemaKey <> FullMetadataObjectName Then
//   		SchemaKey = FullMetadataObjectName;
//   		DCSchema = New DataCompositionSchema;
//   		ReportsServer.EnableSchema(ThisObject, Context, DCSchema, SchemaKey);
//   	EndIf.
//   EndIf; - a schema depends on the parameter value that is displayed in the report user settings.
//
Procedure BeforeImportSettingsToComposer(Context, SchemaKey, OptionKey, NewDCSettings, NewDCUserSettings) Export
	
	ParameterOutputResponsibleEmployee = SettingsComposer.Settings.DataParameters.FindParameterValue(New DataCompositionParameter("OutputResponsibleEmployee"));
	If ParameterOutputResponsibleEmployee <> Undefined AND NewDCUserSettings <> Undefined Then
		Setting = NewDCUserSettings.Items.Find(ParameterOutputResponsibleEmployee.UserSettingID);
		If Setting <> Undefined Then
			HideGroupByResponsiblePersons(NewDCSettings, Setting);
		EndIf;
	EndIf;
	
	If SchemaKey <> "1" Then
		SchemaKey = "1";
		ReportsServer.AttachSchema(ThisObject, Context, DataCompositionSchema, SchemaKey);
	EndIf;
	
EndProcedure

// This procedure is called in the OnLoadVariantAtServer event handler of a report form after executing the form code.
// For more detailed description go to the syntax assistant, namely, to the extension section of the 
// report managed form.
//
// Parameters:
//   Form - ManagedForm - a report form.
//   NewDCSettings - DataCompositionSettings - settings to load into the settings composer.
//
Procedure BeforeLoadVariantAtServer(Form, NewDCSettings) Export
	
	DSCParameter         = New DataCompositionParameter("Context");
	DSCParameterContext = SettingsComposer.Settings.DataParameters.Items.Find(DSCParameter);
	
	If DSCParameterContext <> Undefined Then
		Context = DSCParameterContext.Value;
	EndIf;
	
	If ValueIsFilled(Context) Then
		SetDataParameters(NewDCSettings, New Structure("Context", Context));
	EndIf;
	
	SetLocalizedParameters(NewDCSettings);
	
	AdditionalProperties = SettingsComposer.Settings.AdditionalProperties;
	If AdditionalProperties.Property("IssuesList") Then
		SetFilterByIssuesList(NewDCSettings.Filter, DataCompositionComparisonType.InList, AdditionalProperties.IssuesList);
	EndIf;
	
EndProcedure

// End StandardSubsystems.ReportsOptions

#EndRegion

#EndRegion

#Region EventHandlers

Procedure OnComposeResult(ResultDocument, DetailsData, StandardProcessing)
	
	StandardProcessing = False;
	
	AccountingChecks = AccountingAuditInternalCached.AccountingChecks();
	
	DCSettings       = SettingsComposer.GetSettings();
	TemplateComposer = New DataCompositionTemplateComposer;
	
	CompositionTemplate   = TemplateComposer.Execute(DataCompositionSchema, DCSettings, DetailsData);
	
	CompositionProcessor = New DataCompositionProcessor;
	CompositionProcessor.Initialize(CompositionTemplate, New Structure("ExternalTable", AccountingChecks.Validation), DetailsData, True);
	
	OutputProcessor = New DataCompositionResultSpreadsheetDocumentOutputProcessor;
	OutputProcessor.SetDocument(ResultDocument);
	
	OutputProcessor.Output(CompositionProcessor);
	
	CompleteReadyTemplate(ResultDocument, ReportStructureNotChanged());
	
EndProcedure

#EndRegion

#Region Private

#Region ShowDCS

Procedure CompleteReadyTemplate(DocumentResult, ReportStructureNotChanged)
	
	CompleteHeader(DocumentResult, ReportStructureNotChanged);
	
	RedefineShowTotals(DocumentResult, ReportStructureNotChanged);
	
	EnterSolutionsHyperlinks(DocumentResult);
	
EndProcedure

Procedure CompleteHeader(DocumentResult, ReportStructureNotChanged)
	
	If ReportStructureNotChanged Then
		
		FirstRow    = 0;
		LastRow = 0;
		
		TableHeight = DocumentResult.TableHeight;
		
		For RowsIndex = 1 To TableHeight Do
			
			AreaName = "R" + Format(RowsIndex, "NG=0");
			Area    = DocumentResult.Area(AreaName);
			
			If StrFind(Area.Text, "[TitleHidden]") <> 0 Then
				If FirstRow = 0 Then
					FirstRow = RowsIndex;
				EndIf;
				LastRow = LastRow + 1;
			EndIf;
			
		EndDo;
		
		If FirstRow = 0 AND LastRow = 0 Then
			Return;
		EndIf;
		
		DocumentResult.DeleteArea(DocumentResult.Area("R" + Format(FirstRow, "NG=0") + ":R" + Format(FirstRow + LastRow - 1, "NG=0")),
			SpreadsheetDocumentShiftType.Vertical);
		
		DocumentResult.FixedTop = FirstRow - 1;
		
	Else
		
		TableWidth = DocumentResult.TableWidth;
		TableHeight = DocumentResult.TableHeight;
		
		For RowsIndex = 1 To TableHeight Do
		
			For ColumnsIndex = 1 To TableWidth Do
			
				AreaName = "R" + Format(RowsIndex, "NG=0") + "C" + Format(ColumnsIndex, "NG=0");
				Area    = DocumentResult.Area(AreaName);
				
				If StrFind(Area.Text, "[TitleHidden]") <> 0 Then
					Area.Text = StrReplace(Area.Text, "[TitleHidden]", "");
				EndIf;
				
			EndDo;
			
		EndDo;
		
	EndIf
	
EndProcedure

Procedure RedefineShowTotals(DocumentResult, ReportStructureNotChanged)
	
	If Not ReportStructureNotChanged Then
		Return;
	EndIf;
	
	TableWidth = DocumentResult.TableWidth;
	TableHeight = DocumentResult.TableHeight;
	
	For RowsIndex = 1 To TableHeight Do
		
		For ColumnsIndex = 1 To TableWidth Do
			
			AreaName = "R" + Format(RowsIndex, "NG=0") + "C" + Format(ColumnsIndex, "NG=0");
			Area    = DocumentResult.Area(AreaName);
			
			If TrimAll(Upper(Area.Text)) = NStr("ru = 'ИТОГО'; en = 'TOTAL'; pl = 'TOTAL';de = 'TOTAL';ro = 'TOTAL';tr = 'TOTAL'; es_ES = 'TOTAL'") Then
				Area.BackColor = New Color(255, 250, 217);
				Break;
			EndIf;
			
		EndDo;
		
		AreaName   = "R" + Format(RowsIndex, "NG=0") + "C1";
		Area      = DocumentResult.Area(AreaName);
		AreaText = TrimAll(Upper(Area.Text));
		
		If AreaText =    NStr("ru = 'ОШИБКА'; en = 'ERROR'; pl = 'ERROR';de = 'ERROR';ro = 'ERROR';tr = 'ERROR'; es_ES = 'ERROR'")
			Or AreaText = NStr("ru = 'ВОЗМОЖНЫЕ ПРИЧИНЫ'; en = 'POSSIBLE CAUSES'; pl = 'POSSIBLE CAUSES';de = 'POSSIBLE CAUSES';ro = 'POSSIBLE CAUSES';tr = 'POSSIBLE CAUSES'; es_ES = 'POSSIBLE CAUSES'")
			Or AreaText = NStr("ru = 'РЕКОМЕНДАЦИИ'; en = 'RECOMMENDATIONS'; pl = 'RECOMMENDATIONS';de = 'RECOMMENDATIONS';ro = 'RECOMMENDATIONS';tr = 'RECOMMENDATIONS'; es_ES = 'RECOMMENDATIONS'")
			Or AreaText = NStr("ru = 'РЕШЕНИЕ'; en = 'SOLUTION'; pl = 'SOLUTION';de = 'SOLUTION';ro = 'SOLUTION';tr = 'SOLUTION'; es_ES = 'SOLUTION'") Then
			
			For ColumnsIndex = 3 To TableWidth Do
				ResourcesAreaName    = "R" + Format(RowsIndex, "NG=0") + "C" + Format(ColumnsIndex, "NG=0");
				ResourcesArea       = DocumentResult.Area(ResourcesAreaName);
				ResourcesArea.Text = "";
			EndDo;
			
		EndIf;
		
	EndDo;
	
EndProcedure

Procedure EnterSolutionsHyperlinks(DocumentResult)
	
	TableWidth = DocumentResult.TableWidth;
	TableHeight = DocumentResult.TableHeight;
	
	For RowsIndex = 1 To TableHeight Do
		
		For ColumnsIndex = 1 To TableWidth Do
			
			AreaName   = "R" + Format(RowsIndex, "NG=0") + "C" + Format(ColumnsIndex, "NG=0");
			Area      = DocumentResult.Area(AreaName);
			AreaText = Area.Text;
			
			If StrStartsWith(AreaText, "%") AND StrEndsWith(AreaText, "%") Then
				
				AreaText      = TrimAll(StrReplace(AreaText, "%", ""));
				SplitRow = StrSplit(AreaText, ",");
				
				If SplitRow.Count() <> 3 Then
					Continue;
				EndIf;
				
				GoToCorrectionHandler = SplitRow.Get(1);
				If Not ValueIsFilled(GoToCorrectionHandler) Then
					Area.Text = "";
					Continue;
				EndIf;
				
				CheckKind = Catalogs.ChecksKinds.GetRef(New UUID(SplitRow.Get(2)));
				
				DetailsStructure = New Structure;
				
				DetailsStructure.Insert("Purpose",                     "FixIssues");
				DetailsStructure.Insert("CheckID",          SplitRow.Get(0));
				DetailsStructure.Insert("GoToCorrectionHandler", GoToCorrectionHandler);
				DetailsStructure.Insert("CheckKind",                    CheckKind);
				
				Area.Details = DetailsStructure;
				
				ReportsServer.OutputHyperlink(Area, DetailsStructure, NStr("ru = 'Выполнить исправление'; en = 'Fix issue'; pl = 'Fix issue';de = 'Fix issue';ro = 'Fix issue';tr = 'Fix issue'; es_ES = 'Fix issue'"));
				
			ElsIf StrFind(AreaText, "<ListDetails>") <> 0 Then
				
				DetailsStructure = New Structure;
				DetailsStructure.Insert("Purpose", "OpenListForm");
				
				RecordSetFilter = New Structure;
				SeparatedText   = StrSplit(AreaText, Chars.LF);
				
				For Each TextItem In SeparatedText Do
					
					If SeparatedText.Find(TextItem) = 0 Then
						Continue;
					ElsIf SeparatedText.Find(TextItem) = 1 Then
						DetailsStructure.Insert("FullObjectName", TextItem);
						Continue;
					EndIf;
					
					SeparatedTextItem = StrSplit(TextItem, "~~~", False);
					If SeparatedTextItem.Count() <> 3 Then
						Continue;
					EndIf;
					
					FilterName             = SeparatedTextItem.Get(0);
					FilterValueType     = SeparatedTextItem.Get(1);
					FilterValueAsString = SeparatedTextItem.Get(2);
					
					If FilterValueType = "Number" Or FilterValueType = "String" 
						Or FilterValueType = "Boolean" Or FilterValueType = "Date" Then
						
						FilterValue = XMLValue(Type(FilterValueType), FilterValueAsString);
						
					ElsIf Common.IsEnum(Metadata.FindByFullName(FilterValueType)) Then
						
						FilterValue = XMLValue(Type(StrReplace(FilterValueType, "Enum", "EnumRef")), FilterValueAsString);
						
					Else
						
						ObjectManager = Common.ObjectManagerByFullName(FilterValueType);
						If ObjectManager = Undefined Then
							Continue;
						EndIf;
						FilterValue = ObjectManager.GetRef(New UUID(FilterValueAsString));
						
					EndIf;
					
					RecordSetFilter.Insert(FilterName, FilterValue);
					
				EndDo;
				DetailsStructure.Insert("Filter", RecordSetFilter);
				
				Area.Details = DetailsStructure;
				
				If SeparatedText.Count() <> 0 Then
					Area.Text = StrReplace(SeparatedText.Get(0), "<ListDetails>", "");
				EndIf;
				
			EndIf;
			
		EndDo;
		
	EndDo;
	
EndProcedure

Function PrepareChecksList(ChecksArray)
	
	ChecksList = New ValueList;
	FirstItem  = ChecksArray.Get(0);
	
	If Not Common.RefTypeValue(FirstItem) Then
		ChecksList.LoadValues(ChecksArray);
	Else
		QueryText =
		"SELECT
		|	Table.Ref AS Ref,
		|	PRESENTATION(Table.Ref) AS RefPresentation
		|FROM
		|	&Table AS Table
		|WHERE
		|	Table.Ref IN(&RefsArray)";
		
		QueryText = StrReplace(QueryText, "&Table", FirstItem.Metadata().FullName());
		Query       = New Query(QueryText);
		Query.SetParameter("RefsArray", ChecksArray);
		
		QueryResult = Query.Execute().Unload();
		For Each ResultItem In QueryResult Do
			ChecksList.Add(ResultItem.Ref, ResultItem.RefPresentation);
		EndDo;
		
		Query = Undefined;
	EndIf;
	
	Return ChecksList;
	
EndFunction

#EndRegion

#Region DCSApplicationSettings

Procedure SetDataParameters(DCSettings, ParametersStructure)
	
	DataParameters = DCSettings.DataParameters.Items;
	
	For Each Parameter In ParametersStructure Do
	
		CurrentParameter   = New DataCompositionParameter(Parameter.Key);
		CurrentDCSParameter = DataParameters.Find(CurrentParameter);
	
		If CurrentDCSParameter <> Undefined Then
	
			CurrentDCSParameter.Use = True;
			CurrentDCSParameter.Value      = Parameter.Value;
	
		Else
	
			DataParameter               = DCSettings.DataParameters.Items.Add();
			DataParameter.Use = True;
			DataParameter.Value      = Parameter.Value;
			DataParameter.Parameter      = New DataCompositionParameter(Parameter.Key);
	
		EndIf;
	
	EndDo;
	
EndProcedure

Procedure SetLocalizedParameters(DCSettings)
	
	DataParameters = DCSettings.DataParameters.Items;
	
	LocalizedParametersStructure = New Structure;
	LocalizedParametersStructure.Insert("LabelError",            NStr("ru = 'Ошибка'; en = 'Error'; pl = 'Error';de = 'Error';ro = 'Error';tr = 'Error'; es_ES = 'Error'"));
	LocalizedParametersStructure.Insert("LabelPossibleCauses",  NStr("ru = 'Возможные причины'; en = 'Possible causes'; pl = 'Possible causes';de = 'Possible causes';ro = 'Possible causes';tr = 'Possible causes'; es_ES = 'Possible causes'"));
	LocalizedParametersStructure.Insert("LabelRecommendations",      NStr("ru = 'Рекомендации'; en = 'Recommendations'; pl = 'Recommendations';de = 'Recommendations';ro = 'Recommendations';tr = 'Recommendations'; es_ES = 'Recommendations'"));
	LocalizedParametersStructure.Insert("LabelSolution",           NStr("ru = 'Решение'; en = 'Solution'; pl = 'Solution';de = 'Solution';ro = 'Solution';tr = 'Solution'; es_ES = 'Solution'"));
	LocalizedParametersStructure.Insert("ObjectsWithIssuesLabel", NStr("ru = 'Проблемные объекты'; en = 'Objects with issues'; pl = 'Objects with issues';de = 'Objects with issues';ro = 'Objects with issues';tr = 'Objects with issues'; es_ES = 'Objects with issues'"));
	
	For Each StructureItem In LocalizedParametersStructure Do
		
		CurrentDCSParameter = DataParameters.Find(New DataCompositionParameter(StructureItem.Key));
		If CurrentDCSParameter <> Undefined Then
			
			CurrentDCSParameter.Use = True;
			CurrentDCSParameter.Value      = StructureItem.Value;
			
		Else
			
			DataParameter               = DCSettings.DataParameters.Items.Add();
			DataParameter.Use = True;
			DataParameter.Value      = StructureItem.Value;
			DataParameter.Parameter      = New DataCompositionParameter(StructureItem.Key);
			
		EndIf;
			
	EndDo;
	
EndProcedure

Procedure SetFilterByIssuesList(DCSSettingsFilter, ComparisonType, FilterValue)
	
	FilterPresentation = "";
	For Each FilterListItem In FilterValue Do
		FilterPresentation = FilterPresentation + ?(ValueIsFilled(FilterPresentation), "; ", "") + Left(FilterListItem.Presentation, 25) + "...";
	EndDo;
	
	FilterItems = DCSSettingsFilter.Items;
	
	FilterItem                  = FilterItems.Add(Type("DataCompositionFilterItem"));
	FilterItem.LeftValue    = New DataCompositionField("CheckRule");
	FilterItem.ComparisonType     = ComparisonType;
	FilterItem.RightValue   = FilterValue;
	FilterItem.ViewMode = DataCompositionSettingsItemViewMode.Inaccessible;
	FilterItem.Presentation    = NStr("ru = 'Правило проверки В списке'; en = 'Check rule In list'; pl = 'Check rule In list';de = 'Check rule In list';ro = 'Check rule In list';tr = 'Check rule In list'; es_ES = 'Check rule In list'") + " """ + FilterPresentation + """";
	FilterItem.Use    = True;
	
EndProcedure

Procedure HideGroupByResponsiblePersons(NewDCSettings, Setting)
	
	If NewDCSettings <> Undefined Then
		GroupByReponsiblePersonColumns = FindGroup(NewDCSettings.Structure[0].Columns, "EmployeeResponsibleGrouping");
		ResponsiblePersonField                 = FindGroupField(NewDCSettings.Structure[0].Rows, "EmployeeResponsible");
		If ResponsiblePersonField <> Undefined Then
			ResponsiblePersonField.Use = Setting.Value;
		EndIf;
		If GroupByReponsiblePersonColumns <> Undefined Then
			GroupByReponsiblePersonColumns.State = ?(Setting.Value, DataCompositionSettingsItemState.Enabled,
				DataCompositionSettingsItemState.Disabled);
		EndIf;
	EndIf;
	
EndProcedure

Function FindGroup(Structure, FieldName)
	
	For each Item In Structure Do
		
		GroupFields = Item.GroupFields.Items;
		For Each Field In GroupFields Do
			
			If TypeOf(Field) = Type("DataCompositionAutoGroupField") Then
				Continue;
			EndIf;
			If Field.Field = New DataCompositionField(FieldName) Then
				Return Item;
			EndIf;
			
		EndDo;
		
		If Item.Structure.Count() = 0 Then
			Continue;
		Else
			Group = FindGroup(Item.Structure, FieldName);
		EndIf;
		
	EndDo;
	
	Return Group;
	
EndFunction

Function FindGroupField(Structure, FieldName)
	
	Group = FindGroup(Structure, FieldName);
	
	If Group = Undefined Then
		Return Undefined;
	EndIf;
	
	GroupFields = Group.GroupFields.Items;
	FoundField   = Undefined;
	
	For Each GroupField In GroupFields Do
		FieldToFind = New DataCompositionField(FieldName);
		If GroupField.Field = FieldToFind Then
			FoundField = GroupField;
		EndIf;
	EndDo;
	
	Return FoundField;
	
EndFunction

#EndRegion

Function ReportStructureNotChanged(InitialStructure = Undefined, FinalStructure = Undefined)
	
	InitialStructure = ReportStructureAsTree(DataCompositionSchema.DefaultSettings);
	FinalStructure = ReportStructureAsTree(SettingsComposer.Settings);
	Return TreesIdentical(InitialStructure, FinalStructure);
	
EndFunction

Function TreesIdentical(FirstTree, SecondTree, TreesIdentical = True, PropertiesToCompare = Undefined)
	
	If PropertiesToCompare = Undefined Then
		PropertiesToCompare = New Array;
		PropertiesToCompare.Add("Type");
		PropertiesToCompare.Add("Subtype");
		PropertiesToCompare.Add("HasStructure");
	EndIf;
	
	FirstTreeRows = FirstTree.Rows;
	SecondTreeRows = SecondTree.Rows;
	
	FirstTreeRowsCount  = FirstTreeRows.Count();
	SecondTreeRowsCount = SecondTreeRows.Count();
	
	If FirstTreeRowsCount <> SecondTreeRowsCount Then
		TreesIdentical = False;
	EndIf;
	
	For RowIndex = 0 To FirstTreeRowsCount - 1 Do
		
		FirstTreeCurrentRow = FirstTreeRows.Get(RowIndex);
		SecondTreeCurrentRow = SecondTreeRows.Get(RowIndex);
		
		For Each PropertyToCompare In PropertiesToCompare Do
			
			If FirstTreeCurrentRow[PropertyToCompare] <> SecondTreeCurrentRow[PropertyToCompare] Then
				TreesIdentical = False;
			EndIf;
			
		EndDo;
		
		If Not DataCompositionNodesSettingsIdentical(FirstTreeCurrentRow.DCNode, SecondTreeCurrentRow.DCNode) Then
			TreesIdentical = False;
		EndIf;
		
		TreesIdentical(FirstTreeCurrentRow, SecondTreeCurrentRow, TreesIdentical, PropertiesToCompare);
		
	EndDo;
	
	Return TreesIdentical;
	
EndFunction

Function DataCompositionNodesSettingsIdentical(DataCompositionFirstNode, DataCompositionSecondNode)
	
	If TypeOf(DataCompositionFirstNode) <> TypeOf(DataCompositionSecondNode) Then
		Return False;
	EndIf;
	
	If TypeOf(DataCompositionFirstNode) = Type("DataCompositionSettings") Then
		
		If Not SelectedFieldsIdentical(DataCompositionFirstNode, DataCompositionSecondNode) Then
			Return False;
		EndIf;
		
		If Not UserFieldsIdentical(DataCompositionFirstNode, DataCompositionSecondNode) Then
			Return False;
		EndIf;
		
	ElsIf TypeOf(DataCompositionFirstNode) = Type("DataCompositionTable") Then
		
		If Not CompositionTablesPropertiesIdentical(DataCompositionFirstNode, DataCompositionSecondNode) Then
			Return False;
		EndIf;
		
		If Not SelectedFieldsIdentical(DataCompositionFirstNode, DataCompositionSecondNode) Then
			Return False;
		EndIf;
		
	ElsIf TypeOf(DataCompositionFirstNode) = Type("DataCompositionTableStructureItemCollection") Then
		
		If Not ItemsCollectionsPropertiesOfDataCompositionTableStructureIdentical(DataCompositionFirstNode, DataCompositionSecondNode) Then
			Return False;
		EndIf;
		
	ElsIf TypeOf(DataCompositionFirstNode) = Type("DataCompositionTableGroup") Or TypeOf(DataCompositionFirstNode) = Type("DataCompositionGroup") Then
		
		If Not CompositionGroupsPropertiesIdentical(DataCompositionFirstNode, DataCompositionSecondNode) Then
			Return False;
		EndIf;
		
		If Not SelectedFieldsIdentical(DataCompositionFirstNode, DataCompositionSecondNode) Then
			Return False;
		EndIf;
		
		If Not CompositionGroupsFieldsIdentical(DataCompositionFirstNode, DataCompositionSecondNode) Then
			Return False;
		EndIf;
		
	EndIf;
	
	Return True;
	
EndFunction

Function SelectedFieldsIdentical(DataCompositionFirstNode, DataCompositionSecondNode)
	
	FirstNodeSelectedFields = DataCompositionFirstNode.Selection.Items;
	SecondNodeSelectedFields = DataCompositionSecondNode.Selection.Items;
	
	FirstNodeSelectedFieldsCount = FirstNodeSelectedFields.Count();
	SecondNodeSelectedFieldsCount = SecondNodeSelectedFields.Count();
	
	If FirstNodeSelectedFieldsCount <> SecondNodeSelectedFieldsCount Then
		Return False;
	EndIf;
	
	SelectedFieldsProperties = New Array;
	
	For Index = 0 To FirstNodeSelectedFieldsCount - 1 Do
		
		FirstCollectionCurrentRow = FirstNodeSelectedFields.Get(Index);
		SecondCollectionCurrentRow = SecondNodeSelectedFields.Get(Index);
		
		If TypeOf(FirstCollectionCurrentRow) <> TypeOf(SecondCollectionCurrentRow) Then
			Return False;
		EndIf;
		
		If TypeOf(FirstCollectionCurrentRow) = Type("DataCompositionAutoSelectedField") Then
			
			SelectedFieldsProperties.Add("Use");
			SelectedFieldsProperties.Add("Parent");
			
		ElsIf TypeOf(FirstCollectionCurrentRow) = Type("DataCompositionSelectedField") Then
			
			SelectedFieldsProperties.Add("Title");
			SelectedFieldsProperties.Add("Use");
			SelectedFieldsProperties.Add("Field");
			SelectedFieldsProperties.Add("ViewMode");
			SelectedFieldsProperties.Add("Parent");
			
		ElsIf TypeOf(FirstCollectionCurrentRow) = Type("DataCompositionSelectedFieldGroup") Then
			
			Return True;
			
		EndIf;
		
		If Not CompareEntitiesByProperties(FirstCollectionCurrentRow, SecondCollectionCurrentRow, SelectedFieldsProperties) Then
			Return False;
		EndIf;
		
	EndDo;
	
	Return True;
	
EndFunction

Function CompositionTablesPropertiesIdentical(FirstTable, SecondTable)
	
	CompositionTableProperties = New Array;
	CompositionTableProperties.Add("ID");
	CompositionTableProperties.Add("UserSettingID");
	CompositionTableProperties.Add("Name");
	CompositionTableProperties.Add("Use");
	CompositionTableProperties.Add("UserSettingPresentation");
	CompositionTableProperties.Add("ViewMode");
	
	If Not CompareEntitiesByProperties(FirstTable, SecondTable, CompositionTableProperties) Then
		Return False;
	EndIf;
	
	Return True;
	
EndFunction

Function CompositionGroupsPropertiesIdentical(FirstTable, SecondTable)
	
	CompositionTableProperties = New Array;
	CompositionTableProperties.Add("ID");
	CompositionTableProperties.Add("UserSettingID");
	CompositionTableProperties.Add("Name");
	CompositionTableProperties.Add("Use");
	CompositionTableProperties.Add("UserSettingPresentation");
	CompositionTableProperties.Add("ViewMode");
	CompositionTableProperties.Add("State");
	
	If Not CompareEntitiesByProperties(FirstTable, SecondTable, CompositionTableProperties) Then
		Return False;
	EndIf;
	
	Return True;
	
EndFunction

Function ItemsCollectionsPropertiesOfDataCompositionTableStructureIdentical(FirstCollection, SecondCollection)
	
	CollectionProperties = New Array;
	CollectionProperties.Add("UserSettingID");
	CollectionProperties.Add("UserSettingPresentation");
	CollectionProperties.Add("ViewMode");
	
	If Not CompareEntitiesByProperties(FirstCollection, SecondCollection, CollectionProperties) Then
		Return False;
	EndIf;
	
	Return True;
	
EndFunction

Function CompositionGroupsFieldsIdentical(FirstGroup, SecondGroup)
	
	FirstFieldsCollection = FirstGroup.GroupFields.Items;
	SecondFieldsCollection = SecondGroup.GroupFields.Items;
	
	FieldsCountInFirstCollection  = FirstFieldsCollection.Count();
	FieldsCountInSecondCollection = SecondFieldsCollection.Count();
	
	FieldsProperties = New Array;
	FieldsProperties.Add("Use");
	FieldsProperties.Add("EndOfPeriod");
	FieldsProperties.Add("BeginOfPeriod");
	FieldsProperties.Add("Field");
	FieldsProperties.Add("GroupType");
	FieldsProperties.Add("AdditionType");
	
	If FieldsCountInFirstCollection <> FieldsCountInSecondCollection Then
		Return False;
	EndIf;
	
	For Index = 0 To FieldsCountInFirstCollection - 1 Do
		
		FirstFieldCurrentRow = FirstFieldsCollection.Get(Index);
		SecondFieldCurrentRow = SecondFieldsCollection.Get(Index);
		
		If Not CompareEntitiesByProperties(FirstFieldCurrentRow, SecondFieldCurrentRow, FieldsProperties) Then
			Return False;
		EndIf;
		
	EndDo;
	
	Return True;
	
EndFunction

Function UserFieldsIdentical(FirstDCSettings, SecondDCSettings)
	
	If FirstDCSettings.UserFields.Items.Count() <> SecondDCSettings.UserFields.Items.Count() Then
		Return False;
	EndIf;
	
	Return True;
	
EndFunction

Function CompareEntitiesByProperties(FirstEntity, SecondEntity, Properties)
	
	For Each Property In Properties Do
		
		If IsException(FirstEntity, Property) Then
			Continue;
		EndIf;
		
		If FirstEntity[Property] <> SecondEntity[Property] Then
			Return False
		EndIf;
		
	EndDo;
	
	Return True;
	
EndFunction

Function IsException(FirstEntity, Property)
	
	If TypeOf(FirstEntity) = Type("DataCompositionTableGroup") Then
		
		If FirstEntity.Name = "EmployeeResponsible" AND Property = "State" Then
			Return True;
		EndIf;
		
	ElsIf TypeOf(FirstEntity) = Type("DataCompositionGroupField") Then
		
		If FirstEntity.Field = New DataCompositionField("EmployeeResponsible") AND Property = "Use" Then
			Return True;
		EndIf;
		
	EndIf;
	
	Return False;
	
EndFunction

Function ReportStructureAsTree(DCSettings)
	
	StructureTree       = StructureTree();
	RegisterOptionTreeNode(DCSettings, DCSettings, StructureTree.Rows);
	Return StructureTree;
	
EndFunction

Function StructureTree()
	
	StructureTree = New ValueTree;
	
	StructureTreeColumns = StructureTree.Columns;
	StructureTreeColumns.Add("DCNode");
	StructureTreeColumns.Add("AvailableDCSetting");
	StructureTreeColumns.Add("Type",                 New TypeDescription("String"));
	StructureTreeColumns.Add("Subtype",              New TypeDescription("String"));
	StructureTreeColumns.Add("HasStructure",       New TypeDescription("Boolean"));
	
	Return StructureTree;
	
EndFunction

Function RegisterOptionTreeNode(DCSettings, DCNode, TreeRowsSet, Subtype = "")
	
	TreeRow = TreeRowsSet.Add();
	TreeRow.DCNode = DCNode;
	TreeRow.Type    = SettingTypeAsString(TypeOf(DCNode));
	TreeRow.Subtype = Subtype;
	
	If StrFind("Settings, Group, ChartGroup, TableGroup", TreeRow.Type) <> 0 Then
		TreeRow.HasStructure = True;
	ElsIf StrFind("Table, Chart, NestedObjectSettings,
		|TableStructureItemCollection, ChartStructureItemCollection", TreeRow.Type) = 0 Then
		Return TreeRow;
	EndIf;
	
	If TreeRow.HasStructure Then
		For Each NestedItem In DCNode.Structure Do
			RegisterOptionTreeNode(DCSettings, NestedItem, TreeRow.Rows);
		EndDo;
	EndIf;
	
	If TreeRow.Type = "Table" Then
		RegisterOptionTreeNode(DCSettings, DCNode.Rows, TreeRow.Rows, "TableRows");
		RegisterOptionTreeNode(DCSettings, DCNode.Columns, TreeRow.Rows, "ColumnsTable");
	ElsIf TreeRow.Type = "Chart" Then
		RegisterOptionTreeNode(DCSettings, DCNode.Points, TreeRow.Rows, "ChartPoints");
		RegisterOptionTreeNode(DCSettings, DCNode.Series, TreeRow.Rows, "ChartSeries");
	ElsIf TreeRow.Type = "TableStructureItemCollection"
		Or TreeRow.Type = "ChartStructureItemCollection" Then
		For Each NestedItem In DCNode Do
			RegisterOptionTreeNode(DCSettings, NestedItem, TreeRow.Rows);
		EndDo;
	ElsIf TreeRow.Type = "NestedObjectSettings" Then
		RegisterOptionTreeNode(DCSettings, DCNode.Settings, TreeRow.Rows);
	EndIf;
	
	Return TreeRow;
	
EndFunction

Function SettingTypeAsString(Type) Export
	If Type = Type("DataCompositionSettings") Then
		Return "Settings";
	ElsIf Type = Type("DataCompositionNestedObjectSettings") Then
		Return "NestedObjectSettings";
	
	ElsIf Type = Type("DataCompositionFilter") Then
		Return "Filter";
	ElsIf Type = Type("DataCompositionFilterItem") Then
		Return "FilterItem";
	ElsIf Type = Type("DataCompositionFilterItemGroup") Then
		Return "FilterItemsGroup";
	
	ElsIf Type = Type("DataCompositionSettingsParameterValue") Then
		Return "SettingsParameterValue";
	
	ElsIf Type = Type("DataCompositionGroup") Then
		Return "Group";
	ElsIf Type = Type("DataCompositionGroupFields") Then
		Return "GroupFields";
	ElsIf Type = Type("DataCompositionGroupFieldCollection") Then
		Return "GroupFieldsCollection";
	ElsIf Type = Type("DataCompositionGroupField") Then
		Return "GroupField";
	ElsIf Type = Type("DataCompositionAutoGroupField") Then
		Return "AutoGroupField";
	
	ElsIf Type = Type("DataCompositionSelectedFields") Then
		Return "SelectedFields";
	ElsIf Type = Type("DataCompositionSelectedField") Then
		Return "SelectedField";
	ElsIf Type = Type("DataCompositionSelectedFieldGroup") Then
		Return "SelectedFieldsGroup";
	ElsIf Type = Type("DataCompositionAutoSelectedField") Then
		Return "AutoSelectedField";
	
	ElsIf Type = Type("DataCompositionOrder") Then
		Return "Order";
	ElsIf Type = Type("DataCompositionOrderItem") Then
		Return "OrderingItem";
	ElsIf Type = Type("DataCompositionAutoOrderItem") Then
		Return "AutoOrderItem";
	
	ElsIf Type = Type("DataCompositionConditionalAppearance") Then
		Return "ConditionalAppearance";
	ElsIf Type = Type("DataCompositionConditionalAppearanceItem") Then
		Return "ConditionalAppearanceItem";
	
	ElsIf Type = Type("DataCompositionSettingStructure") Then
		Return "SettingsStructure";
	ElsIf Type = Type("DataCompositionSettingStructureItemCollection") Then
		Return "SettingsStructureItemCollection";
	
	ElsIf Type = Type("DataCompositionTable") Then
		Return "Table";
	ElsIf Type = Type("DataCompositionTableGroup") Then
		Return "TableGroup";
	ElsIf Type = Type("DataCompositionTableStructureItemCollection") Then
		Return "TableStructureItemCollection";
	
	ElsIf Type = Type("DataCompositionChart") Then
		Return "Chart";
	ElsIf Type = Type("DataCompositionChartGroup") Then
		Return "ChartGroup";
	ElsIf Type = Type("DataCompositionChartStructureItemCollection") Then
		Return "ChartStructureItemCollection";
	
	ElsIf Type = Type("DataCompositionDataParameterValues") Then
		Return "DataParametersValues";
	
	Else
		Return "";
	EndIf;
EndFunction

#EndRegion

#Else
Raise NStr("ru = 'Недопустимый вызов объекта на клиенте.'; en = 'Invalid object call on the client.'; pl = 'Invalid object call on the client.';de = 'Invalid object call on the client.';ro = 'Invalid object call on the client.';tr = 'Invalid object call on the client.'; es_ES = 'Invalid object call on the client.'");
#EndIf