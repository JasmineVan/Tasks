///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Variables

Var RegistersProperties; // ValueTable, each table row stores a register info whose recorder is an owner document.
                         // 
Var Notes; // ValueTable, each table row stores a note text, for numbered rows of the vertical report option.
                  // 

#EndRegion

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
//       ReportsClientServer.DefaultReportSettings().
//
Procedure DefineFormSettings(Form, OptionKey, Settings) Export
	
	Settings.SelectAndEditOptionsWithoutSavingAllowed = True;
	Settings.HideBulkEmailCommands                              = True;
	Settings.ControlItemsPlacementParameters           = ControlItemsPlacementParameters();
	
	Settings.Events.OnCreateAtServer               = True;
	Settings.Events.BeforeImportSettingsToComposer = True;
	Settings.Events.BeforeLoadVariantAtServer    = True;
	Settings.Events.OnDefineSelectionParameters     = True;
	
	Settings.GenerateImmediately = True;
	
EndProcedure

// Called before importing new settings. Used to change composition schema.
//   For example, if the report schema depends on the option key or report parameters.
//   For the schema changes to take effect, call the ReportsServer.EnableSchema() method.
//
// Parameters:
//   Context - Arbitrary -
//       Parameters of the context, in which the report is used.
//       Used to pass the ReportsServer.EnableSchema() method in the parameters.
//   SchemaKey - String -
//       An ID of the current settings composer schema.
//       It is not filled in by default. The composer is initialized based on the main schema.
//       It is used for optimization to reinitialize the composer as rarely as possible.
//       It is possible not to use it if reinitialization is running unconditionally.
//   OptionKey - String, Undefined - 
//       Predefined report option name or UUID of a custom report option.
//       Undefined when called for a detail option or without context.
//   Settings - DataCompositionSettings, Undefined -
//       Report option settings that will be imported into the settings composer after it is initialized.
//       Undefined when option settings do not need to be imported (already imported earlier).
//   UserSettings - DataCompositionUserSettings, Undefined -
//       User settings that will be imported into the settings composer after it is initialized.
//       Undefined when user settings do not need to be imported (already imported earlier).
//
// Call options:
//   If SchemaKey <> "1" Then
//   	SchemaKey = "1";
//   	DCSchema = GetCommonTemplate("MyCommonCompositionSchema");
//   	ReportsServer.EnableSchema(ThisObject, Context, DCSchema, SchemaKey);
//   EndIf; - a report composer is initialized based on the schema from common templates.
//   If ValueType(NewDCUserSettings) = Type("DataCompositionUserSettings") Then
//   	FullMetadataObjectName = "";
//   	For Each DCItem From NewDCUserSettings.Items Do
//   		If ValueType(DCItem) = Type("DataCompositionSettingsParameterValue") Then
//   			ParameterName = String(DCItem.Parameter);
//   			If ParameterName = "MetadataObject" Then
//   				FullMetadataObjectName = DCItem.Value;
//   			EndIf;
//   		EndIf;
//   	EndDo;
//   	If SchemaKey <> FullMetadataObjectName Then
//   		SchemaKey = FullMetadataObjectName;
//   		DCSchema = New DataCompositionSchema;
//   		ReportsServer.EnableSchema(ThisObject, Context, DCSchema, SchemaKey);
//   	EndIf;
//   EndIf; - a schema depends on the parameter value that is displayed in the report user settings.
//
Procedure BeforeImportSettingsToComposer(Context, SchemaKey, OptionKey, Settings, UserSettings) Export
	
	If TypeOf(Settings) <> Type("DataCompositionSettings") Then
		Settings = SettingsComposer.Settings;
	EndIf;
	
	If TypeOf(UserSettings) <> Type("DataCompositionUserSettings") Then 
		UserSettings = SettingsComposer.UserSettings;
	EndIf;
	
	ReportParameters = ReportParameters(Settings, UserSettings);
	
	If ReportParameters.OwnerDocument = Undefined Then
		Raise NStr("ru = 'Отчет о движениях документа не предназначен для рассылки.'; en = 'Document register records report is not intended for distribution.'; pl = 'Document register records report is not intended for distribution.';de = 'Document register records report is not intended for distribution.';ro = 'Document register records report is not intended for distribution.';tr = 'Document register records report is not intended for distribution.'; es_ES = 'Document register records report is not intended for distribution.'");
	EndIf;
	
	If SchemaKey = OptionKey Then
		Return;
	EndIf;
	
	SchemaKey = OptionKey;
	
	GetRegistersProperties(Context, ReportParameters.OwnerDocument);
	
	AddRecordsCountResource(DataCompositionSchema);
	
	RegistersList = RegistersList();
	SelectedRegistersList = SelectedRegistersList(RegistersList, Settings, UserSettings);
	
	FoundParameter = DataCompositionSchema.Parameters.Find("RegistersList");
	FoundParameter.SetAvailableValues(RegistersList);
	
	ReportsServer.AttachSchema(ThisObject, Context, DataCompositionSchema, SchemaKey);
	
	ParametersValues = New Structure;
	ParametersValues.Insert("OwnerDocument", ReportParameters.OwnerDocument);
	ParametersValues.Insert("RegistersList", SelectedRegistersList);
	
	SetDataParameters(Settings, ParametersValues, UserSettings);
	
	If OptionKey = "Main" Then
		PrepareHorizontalOption(ReportParameters.OwnerDocument, Settings);
	ElsIf OptionKey = "Additional" Then
		PrepareVerticalOption(ReportParameters.OwnerDocument, Settings);
	EndIf;
	
	SetConditionalAppearance(Settings);
	
EndProcedure

// See ReportsOverridable.OnCreateAtServer. 
Procedure OnCreateAtServer(Form, Cancel, StandardProcessing) Export
	
	If Form.Parameters.VariantPresentation = "Details" Then
		Raise NStr("ru = 'Выбранное действие в данном отчете не доступно.'; en = 'The selected action is not available in this report.'; pl = 'The selected action is not available in this report.';de = 'The selected action is not available in this report.';ro = 'The selected action is not available in this report.';tr = 'The selected action is not available in this report.'; es_ES = 'The selected action is not available in this report.'");
	EndIf;
	
	If Form.Parameters.Property("OwnerDocument") Then
		DataParametersStructure = New Structure("OwnerDocument", Form.Parameters.OwnerDocument);
		SetDataParameters(SettingsComposer.Settings, DataParametersStructure);
	ElsIf Not Form.Parameters.Property("CommandParameter") Then
		Raise NStr("ru = 'Для начала работы с отчетом необходимо воспользоваться соответствующей командой в форме интересующего документа.'; en = 'To start using the report, select a matching command in the document form.'; pl = 'To start using the report, select a matching command in the document form.';de = 'To start using the report, select a matching command in the document form.';ro = 'To start using the report, select a matching command in the document form.';tr = 'To start using the report, select a matching command in the document form.'; es_ES = 'To start using the report, select a matching command in the document form.'");
	EndIf;
	DocumentOwner = Form.Parameters.CommandParameter;
	If Not ValueIsFilled(DocumentOwner) Then
		Raise NStr("ru = 'Для начала работы с отчетом необходимо воспользоваться соответствующей командой в форме интересующего документа.'; en = 'To start using the report, select a matching command in the document form.'; pl = 'To start using the report, select a matching command in the document form.';de = 'To start using the report, select a matching command in the document form.';ro = 'To start using the report, select a matching command in the document form.';tr = 'To start using the report, select a matching command in the document form.'; es_ES = 'To start using the report, select a matching command in the document form.'");
	EndIf;
	
	DataParametersStructure = New Structure("OwnerDocument", DocumentOwner);
	SetDataParameters(SettingsComposer.Settings, DataParametersStructure);
	Form.PurposeUseKey = DocumentOwner.Metadata().FullName();
	
EndProcedure

// See ReportsOverridable.OnDefineChoiceParameters. 
Procedure OnDefineSelectionParameters(Form, SettingProperties) Export
	
	If RegistersProperties = Undefined
		Or RegistersProperties.Count() = 0
		Or SettingProperties.DCField <> New DataCompositionField("DataParameters.RegistersList") Then
		Return;
	EndIf;
	
	SettingProperties.RestrictSelectionBySpecifiedValues = True;
	SettingProperties.ValuesForSelection = RegistersList();
	
EndProcedure

// See ReportsOverridable.BeforeLoadVariantAtServer. 
Procedure BeforeLoadVariantAtServer(Form, Settings) Export
	
	FoundParameter = SettingsComposer.Settings.DataParameters.Items.Find("OwnerDocument");
	If FoundParameter = Undefined Then
		Return;
	EndIf;
	
	DocumentOwner = FoundParameter.Value;
	If Not ValueIsFilled(DocumentOwner) Then 
		Return;
	EndIf;
	
	SetDataParameters(Settings, New Structure("OwnerDocument", DocumentOwner));
	
EndProcedure

// End StandardSubsystems.ReportsOptions

#EndRegion

#EndRegion

#Region EventHandlers

Procedure OnComposeResult(ResultDocument, DetailsData, StandardProcessing)
	
	StandardProcessing = False;
	
	FoundParameter = SettingsComposer.Settings.DataParameters.Items.Find("OwnerDocument");
	If FoundParameter = Undefined
		Or Not ValueIsFilled(FoundParameter.Value) Then
		Return;
	EndIf;
	
	DocumentOwner = FoundParameter.Value;
	
	HeaderTemplate                              = GetTemplate("Title");
	HeaderArea                            = HeaderTemplate.GetArea("AreaHeader");
	HeaderArea.Parameters.DocumentRefSSL = String(DocumentOwner);
	EmptyArea                               = HeaderTemplate.GetArea("EmptyArea");
	
	HeaderArea.CurrentArea.Details = DocumentOwner;
	
	ResultDocument.Put(EmptyArea);
	ResultDocument.Put(HeaderArea);
	ResultDocument.Put(EmptyArea);
	
	Settings = SettingsComposer.GetSettings();
	
	GetRegistersProperties(Settings, DocumentOwner);
	
	FoundParameter = Settings.DataParameters.Items.Find("RegistersList");
	If FoundParameter <> Undefined
		AND Not FoundParameter.Use Then 
		
		FoundParameter.Use = True;
		FoundParameter.Value = RegistersList();
		
	EndIf;
	
	RestoreFilterByRegistersGroups(Settings);
	
	TemplateComposer = New DataCompositionTemplateComposer;
	CompositionTemplate   = TemplateComposer.Execute(DataCompositionSchema, Settings, DetailsData);
	
	CompositionProcessor = New DataCompositionProcessor;
	CompositionProcessor.Initialize(CompositionTemplate, , DetailsData, True);
	
	OutputProcessor = New DataCompositionResultSpreadsheetDocumentOutputProcessor;
	OutputProcessor.SetDocument(ResultDocument);
	
	OutputProcessor.Output(CompositionProcessor);
	
	RegisterResult(Settings, ResultDocument, DocumentOwner);
	
EndProcedure

#EndRegion

#Region Private

#Region DCSGeneration

#Region DataPreparation

Function ReportDataSets(DocumentOwner, AdditionalNumbering = False)
	
	DataSets = New Array;
	
	For Each RegisterProperties In RegistersProperties Do
		
		DataSet = Undefined;
		RegisterMetadata = Metadata.FindByFullName(RegisterProperties.FullRegisterName);
		
		If RegisterProperties.RegisterType = "Accumulation"
			Or RegisterProperties.RegisterType = "Information" Then
			
			DataSet = DataSetForInfoAccumulationRegister(RegisterProperties, RegisterMetadata, AdditionalNumbering);
			
		ElsIf RegisterProperties.RegisterType = "Accounting" Then
			
			DataSet = DataSetForAccountingRegister(RegisterProperties, RegisterMetadata);
			
		ElsIf RegisterProperties.RegisterType = "Calculation" Then
			
			DataSet = DataSetForCalculationRegister(RegisterProperties, RegisterMetadata, AdditionalNumbering);
			
		EndIf;
		
		If DataSet <> Undefined Then
			DataSets.Add(DataSet);
		EndIf;
		
	EndDo;
	
	DocumentRecordsReportOverridable.OnPrepareDataSet(DocumentOwner, DataSets);
	
	Return DataSets;
	
EndFunction

Function DataSetForInfoAccumulationRegister(RegisterProperties, RegisterMetadata, AdditionalNumbering)
	
	DataSet = New Structure;
	DataSet.Insert("Dimensions",              New Structure);
	DataSet.Insert("Resources",                New Structure);
	DataSet.Insert("Attributes",              New Structure);
	DataSet.Insert("StandardAttributes",   New Structure);
	DataSet.Insert("FullRegisterName",      RegisterProperties.GroupName);
	DataSet.Insert("RegisterName",            RegisterProperties.RegisterName);
	DataSet.Insert("RegisterType",            RegisterProperties.RegisterType);
	DataSet.Insert("RegisterKindPresentation", RegisterProperties.RegisterKindPresentation);
	DataSet.Insert("RegisterPresentation",  RegisterProperties.RegisterPresentation);
	
	If AdditionalNumbering Then
		DataSet.Insert("Numerator", New Structure);
	EndIf;
	
	DataSet.StandardAttributes = FieldsPresentationNames(RegisterMetadata.StandardAttributes, "LineNumber, Recorder");
	DataSet.Dimensions            = FieldsPresentationNames(RegisterMetadata.Dimensions);
	DataSet.Resources              = FieldsPresentationNames(RegisterMetadata.Resources);
	DataSet.Attributes            = FieldsPresentationNames(RegisterMetadata.Attributes);
	
	SelectionFields = "";
	AddFields(SelectionFields, DataSet.StandardAttributes, RegisterMetadata);
	AddFields(SelectionFields, DataSet.Dimensions, RegisterMetadata, "Dimensions");
	AddFields(SelectionFields, DataSet.Resources, RegisterMetadata, "Resources");
	AddFields(SelectionFields, DataSet.Attributes, RegisterMetadata, "Attributes");
	
	If AdditionalNumbering Then
	
		DataSet.Numerator = FieldsNumbers(DataSet);
		AddFieldsNumbers(SelectionFields, DataSet.Numerator);
	
	EndIf;
	
	If TrimAll(Right(SelectionFields, 2)) = "," Then
		SelectionFields = Left(SelectionFields, StrLen(SelectionFields) - 2);
	EndIf;
	
	QueryText =
	"SELECT ALLOWED
	|	1 AS RegisterRecordCount,
	|	""&RegisterName"" AS RegisterName,
	|	&Fields
	|FROM
	|	&CurrentTable AS CurrentTable
	|WHERE
	|	&QueryCondition
	|{WHERE
	|	(&CompositionCondition)}";
	
	QueryText = StrReplace(QueryText, "&RegisterName", RegisterProperties.GroupName);
	QueryText = StrReplace(QueryText, "&Fields", SelectionFields);
	QueryText = StrReplace(QueryText, "&CurrentTable", RegisterProperties.FullRegisterName);
	QueryText = StrReplace(QueryText, "&QueryCondition", RegisterProperties.RecorderFieldName + " = &OwnerDocument");
	QueryText = StrReplace(QueryText, "&CompositionCondition", """" + RegisterProperties.GroupName + """ IN (&RegistersList)");
	
	DataSet.Insert("QueryText", QueryText);
	
	Return DataSet;
	
EndFunction

Function DataSetForAccountingRegister(RegisterProperties, RegisterMetadata)
	
	DataSet = New Structure;
	DataSet.Insert("StandardAttributes",   New Structure);
	DataSet.Insert("Dimensions",              New Structure);
	DataSet.Insert("Resources",                New Structure);
	DataSet.Insert("ResourcesDr",              New Structure);
	DataSet.Insert("ResourcesCr",              New Structure);
	DataSet.Insert("ExtDimensions",               New Structure);
	DataSet.Insert("ExtDimensionsDr",             New Structure);
	DataSet.Insert("ExtDimensionsCr",             New Structure);
	DataSet.Insert("DimensionsDr",            New Structure);
	DataSet.Insert("DimensionsCr",            New Structure);
	DataSet.Insert("Attributes",              New Structure);
	DataSet.Insert("FullRegisterName",      RegisterProperties.GroupName);
	DataSet.Insert("RegisterName",            RegisterProperties.RegisterName);
	DataSet.Insert("RegisterType",            RegisterProperties.RegisterType);
	DataSet.Insert("RegisterKindPresentation", RegisterProperties.RegisterKindPresentation);
	DataSet.Insert("RegisterPresentation",  RegisterProperties.RegisterPresentation);
	
	MaxExtDimensionCount = RegisterMetadata.ChartOfAccounts.MaxExtDimensionCount;
	ObjectCorresppondence         = RegisterMetadata.Correspondence;
	
	LocalizationDebit    = NStr("ru = 'Дт'; en = 'Dr'; pl = 'Dr';de = 'Dr';ro = 'Dr';tr = 'Dr'; es_ES = 'Dr'");
	LocalizationCredit   = NStr("ru = 'Кт'; en = 'Cr'; pl = 'Cr';de = 'Cr';ro = 'Cr';tr = 'Cr'; es_ES = 'Cr'");
	LocalizationExtDimension = NStr("ru = 'Субконто'; en = 'ExtDimension'; pl = 'ExtDimension';de = 'ExtDimension';ro = 'ExtDimension';tr = 'ExtDimension'; es_ES = 'ExtDimension'");
	LocalizationAccount     = NStr("ru = 'Счет'; en = 'Account'; pl = 'Account';de = 'Account';ro = 'Account';tr = 'Account'; es_ES = 'Account'");
	
	StandardAttributesOfExclusion = "LineNumber, Recorder, Account";
	For ExtDimensionIndex = 1 To MaxExtDimensionCount Do
		ExtDimensionIndexRow =  Format(ExtDimensionIndex, "NG=0");
		StandardAttributesOfExclusion = StandardAttributesOfExclusion 
			+ ", " + "ExtDimensionType" + ExtDimensionIndexRow + ", ExtDimensions" + ExtDimensionIndexRow;
	EndDo;
	
	DataSet.StandardAttributes = FieldsPresentationNames(RegisterMetadata.StandardAttributes,
		StandardAttributesOfExclusion);
	DataSet.Attributes            = FieldsPresentationNames(RegisterMetadata.Attributes,
		StandardAttributesOfExclusion);
	
	Resources = RegisterMetadata.Resources;
	For Each Resource In Resources Do
	
		If Resource.Balance Or Not ObjectCorresppondence Then
	
			DataSet.Resources.Insert(Resource.Name, Resource.Presentation());
	
		Else
	
			DataSet.ResourcesDr.Insert(Resource.Name + "Dr", Resource.Presentation() + " " + LocalizationDebit);
			DataSet.ResourcesCr.Insert(Resource.Name + "Cr", Resource.Presentation() + " " + LocalizationCredit);
	
		EndIf;
	
	EndDo;
	
	For ExtDimensionIndex = 1 To MaxExtDimensionCount Do
	
		If ObjectCorresppondence Then
	
			IndexAsString = Format(ExtDimensionIndex, "NG=0");
			
			DataSet.ExtDimensionsDr.Insert("ExtDimensionsDr" + IndexAsString,
				LocalizationExtDimension + " " + LocalizationDebit + " " + IndexAsString);
			DataSet.ExtDimensionsCr.Insert("ExtDimensionsCr" + IndexAsString,
				LocalizationExtDimension + " " + LocalizationCredit + " " + IndexAsString);
	
		Else
	
			DataSet.ExtDimensions.Insert("ExtDimensions" + IndexAsString, LocalizationExtDimension + " " + IndexAsString);
	
		EndIf;
		
	EndDo;
	
	If ObjectCorresppondence Then
		
		DataSet.DimensionsDr.Insert("AccountDr", LocalizationAccount + " " +LocalizationDebit);
		DataSet.DimensionsCr.Insert("AccountCr", LocalizationAccount + " " + LocalizationCredit);
	
	Else
	
		DimensionText = DimensionText + ?(ValueIsFilled(DimensionText), ", ", "") + "Account";
		DataSet.Dimensions.Insert("Account", LocalizationAccount);
	
	EndIf;
	
	Dimensions = RegisterMetadata.Dimensions;
	For Each Dimension In Dimensions Do
	
		If Dimension.Balance Or Not ObjectCorresppondence Then
	
			DataSet.Dimensions.Insert(Dimension.Name, Dimension.Presentation());
	
		Else
	
			DataSet.DimensionsDr.Insert(Dimension.Name + "Dr", Dimension.Presentation() + " " + LocalizationDebit);
			DataSet.DimensionsCr.Insert(Dimension.Name + "Cr", Dimension.Presentation() + " " + LocalizationCredit);
	
		EndIf;
	
	EndDo;
	
	SelectionFields = "";
	AddFields(SelectionFields, DataSet.StandardAttributes, RegisterMetadata);
	AddFields(SelectionFields, DataSet.Attributes, RegisterMetadata, "Attributes");
	AddFields(SelectionFields, DataSet.Dimensions, RegisterMetadata, "Dimensions");
	AddFields(SelectionFields, DataSet.DimensionsDr, RegisterMetadata);
	AddFields(SelectionFields, DataSet.DimensionsCr, RegisterMetadata);
	AddFields(SelectionFields, DataSet.Resources, RegisterMetadata, "Resources");
	AddFields(SelectionFields, DataSet.ResourcesDr, RegisterMetadata);
	AddFields(SelectionFields, DataSet.ResourcesCr, RegisterMetadata);
	AddFields(SelectionFields, DataSet.ExtDimensions, RegisterMetadata, "ExtDimensions");
	AddFields(SelectionFields, DataSet.ExtDimensionsDr, RegisterMetadata);
	AddFields(SelectionFields, DataSet.ExtDimensionsCr, RegisterMetadata);
	
	If TrimAll(Right(SelectionFields, 2)) = "," Then
		SelectionFields = Left(SelectionFields, StrLen(SelectionFields) - 2);
	EndIf;
	
	QueryText =
	"SELECT ALLOWED
	|	1 AS RegisterRecordCount,
	|	""&RegisterName"" AS RegisterName,
	|	&Fields
	|FROM
	|	&CurrentTable AS CurrentTable
	|WHERE
	|	&QueryCondition
	|{WHERE
	|	(&CompositionCondition)}";
	
	QueryText = StrReplace(QueryText, "&RegisterName", RegisterProperties.GroupName);
	QueryText = StrReplace(QueryText, "&Fields", SelectionFields);
	QueryText = StrReplace(QueryText, "&CurrentTable", "AccountingRegister." + RegisterProperties.RegisterName
		+ ".RecordsWithExtDimensions(, , " + RegisterProperties.RecorderFieldName + " = &OwnerDocument)");
	QueryText = StrReplace(QueryText, "&QueryCondition", RegisterProperties.RecorderFieldName + " = &OwnerDocument");
	QueryText = StrReplace(QueryText, "&CompositionCondition", """" + RegisterProperties.GroupName + """ IN (&RegistersList)");
	
	DataSet.Insert("QueryText", QueryText);
	
	Return DataSet;
	
EndFunction

Function DataSetForCalculationRegister(RegisterProperties, RegisterMetadata, AdditionalNumbering)
	
	DataSet = New Structure;
	DataSet.Insert("Dimensions",              New Structure);
	DataSet.Insert("Resources",                New Structure);
	DataSet.Insert("Attributes",              New Structure);
	DataSet.Insert("StandardAttributes",   New Structure);
	DataSet.Insert("FullRegisterName",      RegisterProperties.GroupName);
	DataSet.Insert("RegisterName",            RegisterProperties.RegisterName);
	DataSet.Insert("RegisterType",            RegisterProperties.RegisterType);
	DataSet.Insert("RegisterKindPresentation", RegisterProperties.RegisterKindPresentation);
	DataSet.Insert("RegisterPresentation",  RegisterProperties.RegisterPresentation);
	
	If AdditionalNumbering Then
		DataSet.Insert("Numerator", New Structure);
	EndIf;
	
	For Each Attribute In RegisterMetadata.StandardAttributes Do
		DataSet.StandardAttributes.Insert(Attribute.Name, Attribute.Presentation());
	EndDo;
	
	DataSet.Dimensions = FieldsPresentationNames(RegisterMetadata.Dimensions);
	DataSet.Resources   = FieldsPresentationNames(RegisterMetadata.Resources);
	DataSet.Attributes = FieldsPresentationNames(RegisterMetadata.Attributes);
	
	SelectionFields = "";
	AddFields(SelectionFields, DataSet.StandardAttributes, RegisterMetadata);
	AddFields(SelectionFields, DataSet.Dimensions, RegisterMetadata, "Dimensions");
	AddFields(SelectionFields, DataSet.Resources, RegisterMetadata, "Resources");
	AddFields(SelectionFields, DataSet.Attributes, RegisterMetadata, "Attributes");
	
	If AdditionalNumbering Then
		
		DataSet.Numerator = FieldsNumbers(DataSet);
		AddFieldsNumbers(SelectionFields, DataSet.Numerator);
		
	EndIf;
	
	If TrimAll(Right(SelectionFields, 2)) = "," Then
		SelectionFields = Left(SelectionFields, StrLen(SelectionFields) - 2);
	EndIf;
	
	QueryText =
	"SELECT ALLOWED
	|	1 AS RegisterRecordCount,
	|	""&RegisterName"" AS RegisterName,
	|	&Fields
	|FROM
	|	&CurrentTable AS CurrentTable
	|WHERE
	|	&QueryCondition
	|{WHERE
	|	(&CompositionCondition)}";
	
	QueryText = StrReplace(QueryText, "&RegisterName", RegisterProperties.GroupName);
	QueryText = StrReplace(QueryText, "&Fields", SelectionFields);
	QueryText = StrReplace(QueryText, "&CurrentTable", RegisterProperties.FullRegisterName);
	QueryText = StrReplace(QueryText, "&QueryCondition", RegisterProperties.RecorderFieldName + " = &OwnerDocument");
	QueryText = StrReplace(QueryText, "&CompositionCondition", """" + RegisterProperties.GroupName + """ IN (&RegistersList)");
	
	DataSet.Insert("QueryText", QueryText);
	
	Return DataSet;
	
EndFunction

Procedure AddFieldsNumbers(FieldsNumbersText, Numerators)
	
	For Each Numerator In Numerators Do
		FieldsNumbersText = FieldsNumbersText + ?(ValueIsFilled(FieldsNumbersText), ", ", "") + Numerator.Value + " As "
			+ Numerator.Key;
	EndDo;
	
EndProcedure

#EndRegion

#Region HorizontalOption

Function PrepareHorizontalOption(DocumentOwner, Settings)
	
	If RegistersProperties.Count() = 0 Then 
		Return DataCompositionSchema;
	EndIf;
	
	DataSets = ReportDataSets(DocumentOwner);
	DataSetsItems = DataCompositionSchema.DataSets["Main"].Items;
	
	SetIndex = 0;
	For Each DataSet In DataSets Do
	
		SetIndex = SetIndex + 1;
		SetName = "RequestBy" + DataSet.FullRegisterName;
		DataSetItem = DataSetsItems.Find(SetName);
	
		If DataSetItem = Undefined Then
	
			DataSetItem = DataSetsItems.Add(Type("DataCompositionSchemaDataSetQuery"));
			DataSetItem.Name = SetName;
			DataSetItem.DataSource = "DataSource1";
			DataSetItem.Query = DataSet.QueryText;
	
			RedefineDSCTemplate(DataCompositionSchema, SetIndex, DataSet.RegisterType,
				DataSet.RegisterKindPresentation, DataSet.RegisterName);
	
		EndIf;
	
		PrepareHorizontalOptionOfDataSet(Settings, DataSet, DataSetItem);
		
	EndDo;
	
	HideParametersAndFilters(Settings);
	
	Return DataCompositionSchema;
	
EndFunction

Procedure PrepareHorizontalOptionOfDataSet(DCSettings, DataItem, DCDataSet)
	
	If DataItem.RegisterType = "Accumulation" Or DataItem.RegisterType = "Information" Then
		
		PrepareHorizontalOptionOfAccumulationAndInfoRegisters_Horizontal(DCSettings, DCDataSet, DataItem);
		
	ElsIf DataItem.RegisterType = "Accounting" Then
		
		PrepareHorizontalOptionOfAccountingRegisters(DCSettings, DCDataSet, DataItem);
		
	ElsIf DataItem.RegisterType = "Calculation" Then
		
		PrepareHorizontalOptionOfCalculationRegisters(DCSettings, DCDataSet, DataItem);
		
	EndIf;
	
EndProcedure

Procedure PrepareHorizontalOptionOfAccumulationAndInfoRegisters_Horizontal(DCSettings, DCDataSet, DataItem)
	
	RegisterKind            = DataItem.RegisterType;
	RegisterKindPresentation = DataItem.RegisterKindPresentation;
	RegisterName            = DataItem.RegisterName;
	RegisterPresentation  = DataItem.RegisterPresentation;
	
	StandardAttributesStructure = DataItem.StandardAttributes;
	DimensionStructure             = DataItem.Dimensions;
	ResourcesStructure              = DataItem.Resources;
	AttributesStructure            = DataItem.Attributes;
	
	UserHeader = StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = 'Регистр %1 %2'; en = '%1 %2 register'; pl = '%1 %2 register';de = '%1 %2 register';ro = '%1 %2 register';tr = '%1 %2 register'; es_ES = '%1 %2 register'"),
		Lower(RegisterKindPresentation), RegisterPresentation);
	
	DetailedRecordsGroup = 
		AddStructureItem(DCSettings, "Register" + RegisterKind + "_" + RegisterName, UserHeader);
	
	If StandardAttributesStructure.Count() > 0 Then
		
		GroupParameters = New Structure;
		GroupParameters.Insert("NameOfGroup",                    "StandardAttributes");
		GroupParameters.Insert("SelectedGroupLocation",  Undefined);
		GroupParameters.Insert("SelectedGroupEmpty",         False);
		GroupParameters.Insert("SelectedGroupPresentation", NStr("ru = 'Стандартные реквизиты'; en = 'Standard attributes'; pl = 'Standard attributes';de = 'Standard attributes';ro = 'Standard attributes';tr = 'Standard attributes'; es_ES = 'Standard attributes'"));
		
		PlaceDSCFieldsGroup(StandardAttributesStructure, DCDataSet, DetailedRecordsGroup, GroupParameters, RegisterKind, RegisterName);
	
	EndIf;
	
	If DimensionStructure.Count() > 0 Then
		
		GroupParameters = New Structure;
		GroupParameters.Insert("NameOfGroup",                    "Dimensions");
		GroupParameters.Insert("SelectedGroupLocation",  Undefined);
		GroupParameters.Insert("SelectedGroupEmpty",         False);
		GroupParameters.Insert("SelectedGroupPresentation", NStr("ru = 'Измерения'; en = 'Dimensions'; pl = 'Dimensions';de = 'Dimensions';ro = 'Dimensions';tr = 'Dimensions'; es_ES = 'Dimensions'"));
		
		PlaceDSCFieldsGroup(DimensionStructure, DCDataSet, DetailedRecordsGroup, GroupParameters, RegisterKind, RegisterName);
	
	EndIf;
	
	If ResourcesStructure.Count() > 0 Then
		
		GroupParameters = New Structure;
		GroupParameters.Insert("NameOfGroup",                    "Resources");
		GroupParameters.Insert("SelectedGroupLocation",  Undefined);
		GroupParameters.Insert("SelectedGroupEmpty",         False);
		GroupParameters.Insert("SelectedGroupPresentation", NStr("ru = 'Ресурсы'; en = 'Resources'; pl = 'Resources';de = 'Resources';ro = 'Resources';tr = 'Resources'; es_ES = 'Resources'"));
		
		PlaceDSCFieldsGroup(ResourcesStructure, DCDataSet, DetailedRecordsGroup, GroupParameters, RegisterKind, RegisterName);
	
	EndIf;
	
	If AttributesStructure.Count() > 0 Then
		
		GroupParameters = New Structure;
		GroupParameters.Insert("NameOfGroup",                    "Attributes");
		GroupParameters.Insert("SelectedGroupLocation",  Undefined);
		GroupParameters.Insert("SelectedGroupEmpty",         False);
		GroupParameters.Insert("SelectedGroupPresentation", NStr("ru = 'Реквизиты'; en = 'Attributes'; pl = 'Attributes';de = 'Attributes';ro = 'Attributes';tr = 'Attributes'; es_ES = 'Attributes'"));
		
		PlaceDSCFieldsGroup(AttributesStructure, DCDataSet, DetailedRecordsGroup, GroupParameters, RegisterKind, RegisterName);
	
	EndIf;

EndProcedure

Procedure PrepareHorizontalOptionOfCalculationRegisters(DCSettings, DCDataSet, DataItem)
	
	RegisterKind            = "Calculation";
	RegisterKindPresentation = NStr("ru = 'Расчета'; en = 'Calculation'; pl = 'Calculation';de = 'Calculation';ro = 'Calculation';tr = 'Calculation'; es_ES = 'Calculation'");
	RegisterName            = DataItem.RegisterName;
	RegisterPresentation  = DataItem.RegisterPresentation;
	
	StandardAttributesStructure = DataItem.StandardAttributes;
	DimensionStructure             = DataItem.Dimensions;
	ResourcesStructure              = DataItem.Resources;
	AttributesStructure            = DataItem.Attributes;
	
	UserHeader = StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = 'Регистр %1 %2'; en = '%1 %2 register'; pl = '%1 %2 register';de = '%1 %2 register';ro = '%1 %2 register';tr = '%1 %2 register'; es_ES = '%1 %2 register'"),
		Lower(RegisterKindPresentation), RegisterPresentation);
	
	DetailedRecordsGroup = AddStructureItem(DCSettings,
		"Register" + RegisterKind + "_" + RegisterName, UserHeader);
	
	If StandardAttributesStructure.Count() > 0 Then
		
		GroupParameters = New Structure;
		GroupParameters.Insert("NameOfGroup",                    "StandardAttributes");
		GroupParameters.Insert("SelectedGroupLocation",  DataCompositionFieldPlacement.Horizontally);
		GroupParameters.Insert("SelectedGroupEmpty",         False);
		GroupParameters.Insert("SelectedGroupPresentation", "");
		
		PlaceDSCFieldsGroup(StandardAttributesStructure, DCDataSet, DetailedRecordsGroup, GroupParameters, RegisterKind, RegisterName);
	
	EndIf;
	
	If DimensionStructure.Count() > 0 Then
		
		GroupParameters = New Structure;
		GroupParameters.Insert("NameOfGroup",                    "Dimensions");
		GroupParameters.Insert("SelectedGroupLocation",  Undefined);
		GroupParameters.Insert("SelectedGroupEmpty",         False);
		GroupParameters.Insert("SelectedGroupPresentation", NStr("ru = 'Измерения'; en = 'Dimensions'; pl = 'Dimensions';de = 'Dimensions';ro = 'Dimensions';tr = 'Dimensions'; es_ES = 'Dimensions'"));
		
		PlaceDSCFieldsGroup(DimensionStructure, DCDataSet, DetailedRecordsGroup, GroupParameters, RegisterKind, RegisterName);
		
	EndIf;
	
	If ResourcesStructure.Count() > 0 Then
		
		GroupParameters = New Structure;
		GroupParameters.Insert("NameOfGroup",                    "Resources");
		GroupParameters.Insert("SelectedGroupLocation",  Undefined);
		GroupParameters.Insert("SelectedGroupEmpty",         False);
		GroupParameters.Insert("SelectedGroupPresentation", NStr("ru = 'Ресурсы'; en = 'Resources'; pl = 'Resources';de = 'Resources';ro = 'Resources';tr = 'Resources'; es_ES = 'Resources'"));
		
		PlaceDSCFieldsGroup(ResourcesStructure, DCDataSet, DetailedRecordsGroup, GroupParameters, RegisterKind, RegisterName);
		
	EndIf;
	
	If AttributesStructure.Count() > 0 Then
		
		GroupParameters = New Structure;
		GroupParameters.Insert("NameOfGroup",                    "Attributes");
		GroupParameters.Insert("SelectedGroupLocation",  Undefined);
		GroupParameters.Insert("SelectedGroupEmpty",         False);
		GroupParameters.Insert("SelectedGroupPresentation", NStr("ru = 'Реквизиты'; en = 'Attributes'; pl = 'Attributes';de = 'Attributes';ro = 'Attributes';tr = 'Attributes'; es_ES = 'Attributes'"));
		
		PlaceDSCFieldsGroup(AttributesStructure, DCDataSet, DetailedRecordsGroup, GroupParameters, RegisterKind, RegisterName);
		
	EndIf;
	
EndProcedure

#EndRegion

#Region VerticalOption

Function PrepareVerticalOption(DocumentOwner, Settings)
	
	If RegistersProperties.Count() = 0 Then 
		Return DataCompositionSchema;
	EndIf;
	
	DataSets = ReportDataSets(DocumentOwner, True);
	DataSetsItems = DataCompositionSchema.DataSets["Main"].Items;
	
	SetIndex = 0;
	For Each DataSet In DataSets Do
	
		SetIndex = SetIndex + 1;
		SetName = "RequestBy" + DataSet.FullRegisterName;
		DataSetItem = DataSetsItems.Find(SetName);
	
		If DataSetItem = Undefined Then
	
			DataSetItem = DataSetsItems.Add(Type("DataCompositionSchemaDataSetQuery"));
			DataSetItem.Name = SetName;
			DataSetItem.DataSource = "DataSource1";
	
			DataSetItem.Query = DataSet.QueryText;
	
			RedefineDSCTemplate(DataCompositionSchema, SetIndex, DataSet.RegisterType,
				DataSet.RegisterKindPresentation, DataSet.RegisterName);
	
		EndIf;
	
		PrepareVerticalOptionOfDataSet(Settings, DataSet, DataSetItem);
	
	EndDo;
	
	HideParametersAndFilters(Settings);
	
	Return DataCompositionSchema;
	
EndFunction

Procedure PrepareVerticalOptionOfDataSet(DCSettings, DataSet, DCDataSet)
	
	If DataSet.RegisterType = "Accumulation" Or DataSet.RegisterType = "Information" Then
	
		PrepareVerticalOptionOfAccumulationAndInfoRegisters(DCSettings, DCDataSet, DataSet);
	
	ElsIf DataSet.RegisterType = "Accounting" Then
	
		PrepareHorizontalOptionOfAccountingRegisters(DCSettings, DCDataSet, DataSet);
	
	ElsIf DataSet.RegisterType = "Calculation" Then
	
		PrepareVerticalOptionOfCalculationRegisters(DCSettings, DCDataSet, DataSet);
	
	EndIf;
	
EndProcedure

Procedure PrepareVerticalOptionOfAccumulationAndInfoRegisters(DCSettings, DCDataSet, DataItem)
	
	RegisterKind            = DataItem.RegisterType;
	RegisterKindPresentation = DataItem.RegisterKindPresentation;
	RegisterName            = DataItem.RegisterName;
	RegisterPresentation  = DataItem.RegisterPresentation;
	
	StandardAttributesStructure = DataItem.StandardAttributes;
	DimensionStructure             = DataItem.Dimensions;
	ResourcesStructure              = DataItem.Resources;
	AttributesStructure            = DataItem.Attributes;
	NumeratorStructure            = DataItem.Numerator; 
	
	Title = StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = 'Регистр %1 %2'; en = '%1 %2 register'; pl = '%1 %2 register';de = '%1 %2 register';ro = '%1 %2 register';tr = '%1 %2 register'; es_ES = '%1 %2 register'"),
		Lower(RegisterKindPresentation), RegisterPresentation);
	DetailedRecordsGroup = AddStructureItem(DCSettings, "Register" + RegisterKind + "_" + RegisterName, Title);
	
	If NumeratorStructure.Count() > 0 Then
	
		GroupParameters = New Structure;
		GroupParameters.Insert("NameOfGroup",                    "Numerator");
		GroupParameters.Insert("SelectedGroupLocation",  DataCompositionFieldPlacement.Vertically);
		GroupParameters.Insert("SelectedGroupEmpty",         False);
		GroupParameters.Insert("SelectedGroupPresentation", "№CurrentDocumentDCSOutputItemGroup");
		
		PlaceDSCFieldsGroup(NumeratorStructure, DCDataSet, DetailedRecordsGroup, GroupParameters, RegisterKind, RegisterName);
	
	EndIf;
	
	If StandardAttributesStructure.Count() > 0 Then
	
		GroupParameters = New Structure;
		GroupParameters.Insert("NameOfGroup",                    "StandardAttributes");
		GroupParameters.Insert("SelectedGroupLocation",  DataCompositionFieldPlacement.Vertically);
		GroupParameters.Insert("SelectedGroupEmpty",         False);
		GroupParameters.Insert("SelectedGroupPresentation", NStr("ru = 'Стандартные реквизиты'; en = 'Standard attributes'; pl = 'Standard attributes';de = 'Standard attributes';ro = 'Standard attributes';tr = 'Standard attributes'; es_ES = 'Standard attributes'"));
		
		PlaceDSCFieldsGroup(StandardAttributesStructure, DCDataSet, DetailedRecordsGroup, GroupParameters, RegisterKind, RegisterName);
	
	EndIf;
	
	If DimensionStructure.Count() > 0 Then
	
		GroupParameters = New Structure;
		GroupParameters.Insert("NameOfGroup",                    "Dimensions");
		GroupParameters.Insert("SelectedGroupLocation",  DataCompositionFieldPlacement.Vertically);
		GroupParameters.Insert("SelectedGroupEmpty",         False);
		GroupParameters.Insert("SelectedGroupPresentation", NStr("ru = 'Измерения'; en = 'Dimensions'; pl = 'Dimensions';de = 'Dimensions';ro = 'Dimensions';tr = 'Dimensions'; es_ES = 'Dimensions'"));
		
		PlaceDSCFieldsGroup(DimensionStructure, DCDataSet, DetailedRecordsGroup, GroupParameters, RegisterKind, RegisterName);
	
	EndIf;
	
	If ResourcesStructure.Count() > 0 Then
	
		GroupParameters = New Structure;
		GroupParameters.Insert("NameOfGroup",                    "Resources");
		GroupParameters.Insert("SelectedGroupLocation",  DataCompositionFieldPlacement.Vertically);
		GroupParameters.Insert("SelectedGroupEmpty",         False);
		GroupParameters.Insert("SelectedGroupPresentation", NStr("ru = 'Ресурсы'; en = 'Resources'; pl = 'Resources';de = 'Resources';ro = 'Resources';tr = 'Resources'; es_ES = 'Resources'"));
		
		PlaceDSCFieldsGroup(ResourcesStructure, DCDataSet, DetailedRecordsGroup, GroupParameters, RegisterKind, RegisterName);
	
	EndIf;
	
	If AttributesStructure.Count() > 0 Then
	
		GroupParameters = New Structure;
		GroupParameters.Insert("NameOfGroup",                    "Attributes");
		GroupParameters.Insert("SelectedGroupLocation",  DataCompositionFieldPlacement.Vertically);
		GroupParameters.Insert("SelectedGroupEmpty",         False);
		GroupParameters.Insert("SelectedGroupPresentation", NStr("ru = 'Реквизиты'; en = 'Attributes'; pl = 'Attributes';de = 'Attributes';ro = 'Attributes';tr = 'Attributes'; es_ES = 'Attributes'"));
		
		PlaceDSCFieldsGroup(AttributesStructure, DCDataSet, DetailedRecordsGroup, GroupParameters, RegisterKind, RegisterName);
	
	EndIf;
	
EndProcedure

Procedure PrepareVerticalOptionOfCalculationRegisters(DCSettings, DCDataSet, DataItem)
	
	RegisterKind            = "Calculation";
	RegisterKindPresentation = NStr("ru = 'Расчета'; en = 'Calculation'; pl = 'Calculation';de = 'Calculation';ro = 'Calculation';tr = 'Calculation'; es_ES = 'Calculation'");
	RegisterName            = DataItem.RegisterName;
	RegisterPresentation  = DataItem.RegisterPresentation;
	
	StandardAttributesStructure = DataItem.StandardAttributes;
	DimensionStructure             = DataItem.Dimensions;
	ResourcesStructure              = DataItem.Resources;
	AttributesStructure            = DataItem.Attributes;
	NumeratorStructure            = DataItem.Numerator;
	
	UserHeader = StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = 'Регистр %1 %2'; en = '%1 %2 register'; pl = '%1 %2 register';de = '%1 %2 register';ro = '%1 %2 register';tr = '%1 %2 register'; es_ES = '%1 %2 register'"),
		Lower(RegisterKindPresentation), RegisterPresentation);
	
	DetailedRecordsGroup = AddStructureItem(DCSettings, "Register" + RegisterKind + "_" + RegisterName,
		UserHeader);
	
	If NumeratorStructure.Count() > 0 Then
		
		GroupParameters = New Structure;
		GroupParameters.Insert("NameOfGroup",                    "Numerator");
		GroupParameters.Insert("SelectedGroupLocation",  DataCompositionFieldPlacement.Vertically);
		GroupParameters.Insert("SelectedGroupEmpty",         False);
		GroupParameters.Insert("SelectedGroupPresentation", "№CurrentDocumentDCSOutputItemGroup");
		
		PlaceDSCFieldsGroup(NumeratorStructure, DCDataSet, DetailedRecordsGroup, GroupParameters, RegisterKind, RegisterName);
		
	EndIf;
	
	If StandardAttributesStructure.Count() > 0 Then
		
		GroupParameters = New Structure;
		GroupParameters.Insert("NameOfGroup",                    "StandardAttributes");
		GroupParameters.Insert("SelectedGroupLocation",  DataCompositionFieldPlacement.Vertically);
		GroupParameters.Insert("SelectedGroupEmpty",         False);
		GroupParameters.Insert("SelectedGroupPresentation", NStr("ru = 'Стандартные реквизиты'; en = 'Standard attributes'; pl = 'Standard attributes';de = 'Standard attributes';ro = 'Standard attributes';tr = 'Standard attributes'; es_ES = 'Standard attributes'"));
		
		PlaceDSCFieldsGroup(StandardAttributesStructure, DCDataSet, DetailedRecordsGroup, GroupParameters, RegisterKind, RegisterName);
		
	EndIf;
	
	If DimensionStructure.Count() > 0 Then
		
		GroupParameters = New Structure;
		GroupParameters.Insert("NameOfGroup",                    "Dimensions");
		GroupParameters.Insert("SelectedGroupLocation",  DataCompositionFieldPlacement.Vertically);
		GroupParameters.Insert("SelectedGroupEmpty",         False);
		GroupParameters.Insert("SelectedGroupPresentation", NStr("ru = 'Измерения'; en = 'Dimensions'; pl = 'Dimensions';de = 'Dimensions';ro = 'Dimensions';tr = 'Dimensions'; es_ES = 'Dimensions'"));
		
		PlaceDSCFieldsGroup(DimensionStructure, DCDataSet, DetailedRecordsGroup, GroupParameters, RegisterKind, RegisterName);
		
	EndIf;
	
	If ResourcesStructure.Count() > 0 Then
		
		GroupParameters = New Structure;
		GroupParameters.Insert("NameOfGroup",                    "Resources");
		GroupParameters.Insert("SelectedGroupLocation",  DataCompositionFieldPlacement.Vertically);
		GroupParameters.Insert("SelectedGroupEmpty",         False);
		GroupParameters.Insert("SelectedGroupPresentation", NStr("ru = 'Ресурсы'; en = 'Resources'; pl = 'Resources';de = 'Resources';ro = 'Resources';tr = 'Resources'; es_ES = 'Resources'"));
		
		PlaceDSCFieldsGroup(ResourcesStructure, DCDataSet, DetailedRecordsGroup, GroupParameters, RegisterKind, RegisterName);
		
	EndIf;
	
	If AttributesStructure.Count() > 0 Then
		
		GroupParameters = New Structure;
		GroupParameters.Insert("NameOfGroup",                    "Attributes");
		GroupParameters.Insert("SelectedGroupLocation",  DataCompositionFieldPlacement.Vertically);
		GroupParameters.Insert("SelectedGroupEmpty",         False);
		GroupParameters.Insert("SelectedGroupPresentation", NStr("ru = 'Реквизиты'; en = 'Attributes'; pl = 'Attributes';de = 'Attributes';ro = 'Attributes';tr = 'Attributes'; es_ES = 'Attributes'"));
		
		PlaceDSCFieldsGroup(AttributesStructure, DCDataSet, DetailedRecordsGroup, GroupParameters, RegisterKind, RegisterName);
		
	EndIf;
	
EndProcedure

#EndRegion

#Region ReportStructureGeneration

Procedure PrepareHorizontalOptionOfAccountingRegisters(DCSettings, DCDataSet, DataItem)
	
	RegisterKind            = "Accounting";
	RegisterKindPresentation = NStr("ru = 'Бухгалтерии'; en = 'Accounting department'; pl = 'Accounting department';de = 'Accounting department';ro = 'Accounting department';tr = 'Accounting department'; es_ES = 'Accounting department'");
	RegisterName            = DataItem.RegisterName;
	RegisterPresentation  = DataItem.RegisterPresentation;
	
	StandardAttributesStructure = DataItem.StandardAttributes;
	DimensionStructure             = DataItem.Dimensions;
	DimensionsStructureDr           = DataItem.DimensionsDr;
	DimensionsStructureCr           = DataItem.DimensionsCr;
	ResourcesStructure              = DataItem.Resources;
	ResourcesStructureDr            = DataItem.ResourcesDr;
	ResourcesStructureCr            = DataItem.ResourcesCr;
	ExtDimensionStructure              = DataItem.ExtDimensions;
	ExtDimensionStructureDr            = DataItem.ExtDimensionsDr;
	ExtDimensionStructureCr            = DataItem.ExtDimensionsCr;
	AttributesStructure            = DataItem.Attributes;
	
	UserHeader = StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = 'Регистр %1 %2'; en = '%1 %2 register'; pl = '%1 %2 register';de = '%1 %2 register';ro = '%1 %2 register';tr = '%1 %2 register'; es_ES = '%1 %2 register'"),
		Lower(RegisterKindPresentation), RegisterPresentation);
	
	DetailedRecordsGroup = AddStructureItem(DCSettings,
		"Register" + RegisterKind + "_" + RegisterName, UserHeader);
	
	If StandardAttributesStructure.Count() > 0 Then
		
		GroupParameters = New Structure;
		GroupParameters.Insert("NameOfGroup",                    "StandardAttributes");
		GroupParameters.Insert("SelectedGroupLocation",  DataCompositionFieldPlacement.Vertically);
		GroupParameters.Insert("SelectedGroupEmpty",         True);
		GroupParameters.Insert("SelectedGroupPresentation", "");
		
		PlaceDSCFieldsGroup(StandardAttributesStructure, DCDataSet, DetailedRecordsGroup, GroupParameters, RegisterKind, RegisterName);
	
	EndIf;
	
	If DimensionStructure.Count() > 0 Then
	
		GroupParameters = New Structure;
		GroupParameters.Insert("NameOfGroup",                    "Dimensions");
		GroupParameters.Insert("SelectedGroupLocation",  Undefined);
		GroupParameters.Insert("SelectedGroupEmpty",         True);
		GroupParameters.Insert("SelectedGroupPresentation", "");
		
		PlaceDSCFieldsGroup(DimensionStructure, DCDataSet, DetailedRecordsGroup, GroupParameters, RegisterKind, RegisterName);
	
	EndIf;
	
	If DimensionsStructureDr.Count() > 0 Then
	
		GroupParameters = New Structure;
		GroupParameters.Insert("NameOfGroup",                    "DimensionsDr");
		GroupParameters.Insert("SelectedGroupLocation",  DataCompositionFieldPlacement.Vertically);
		GroupParameters.Insert("SelectedGroupEmpty",         True);
		GroupParameters.Insert("SelectedGroupPresentation", "");
		
		PlaceDSCFieldsGroup(DimensionsStructureDr, DCDataSet, DetailedRecordsGroup, GroupParameters, RegisterKind, RegisterName);
	
	EndIf;
	
	If ExtDimensionStructure.Count() > 0 Then
	
		GroupParameters = New Structure;
		GroupParameters.Insert("NameOfGroup",                    "ExtDimensions");
		GroupParameters.Insert("SelectedGroupLocation",  DataCompositionFieldPlacement.Vertically);
		GroupParameters.Insert("SelectedGroupEmpty",         True);
		GroupParameters.Insert("SelectedGroupPresentation", "");
		
		PlaceDSCFieldsGroup(ExtDimensionStructure, DCDataSet, DetailedRecordsGroup, GroupParameters, RegisterKind, RegisterName);
	
	EndIf;
	
	If ExtDimensionStructureDr.Count() > 0 Then
	
		GroupParameters = New Structure;
		GroupParameters.Insert("NameOfGroup",                    "ExtDimensionsDr");
		GroupParameters.Insert("SelectedGroupLocation",  DataCompositionFieldPlacement.Vertically);
		GroupParameters.Insert("SelectedGroupEmpty",         True);
		GroupParameters.Insert("SelectedGroupPresentation", "");
		
		PlaceDSCFieldsGroup(ExtDimensionStructureDr, DCDataSet, DetailedRecordsGroup, GroupParameters, RegisterKind, RegisterName);
	
	EndIf;
	
	If ResourcesStructureDr.Count() > 0 Then
	
		GroupParameters = New Structure;
		GroupParameters.Insert("NameOfGroup",                    "ResourcesDr");
		GroupParameters.Insert("SelectedGroupLocation",  DataCompositionFieldPlacement.Vertically);
		GroupParameters.Insert("SelectedGroupEmpty",         True);
		GroupParameters.Insert("SelectedGroupPresentation", "");
		
		PlaceDSCFieldsGroup(ResourcesStructureDr, DCDataSet, DetailedRecordsGroup, GroupParameters, RegisterKind, RegisterName);
	
	EndIf;
	
	If DimensionsStructureCr.Count() > 0 Then
	
		GroupParameters = New Structure;
		GroupParameters.Insert("NameOfGroup",                    "DimensionsCr");
		GroupParameters.Insert("SelectedGroupLocation",  DataCompositionFieldPlacement.Vertically);
		GroupParameters.Insert("SelectedGroupEmpty",         True);
		GroupParameters.Insert("SelectedGroupPresentation", "");
		
		PlaceDSCFieldsGroup(DimensionsStructureCr, DCDataSet, DetailedRecordsGroup, GroupParameters, RegisterKind, RegisterName);
	
	EndIf;
	
	If ExtDimensionStructureCr.Count() > 0 Then
	
		GroupParameters = New Structure;
		GroupParameters.Insert("NameOfGroup",                    "ExtDimensionsCr");
		GroupParameters.Insert("SelectedGroupLocation",  DataCompositionFieldPlacement.Vertically);
		GroupParameters.Insert("SelectedGroupEmpty",         True);
		GroupParameters.Insert("SelectedGroupPresentation", "");
		
		PlaceDSCFieldsGroup(ExtDimensionStructureCr, DCDataSet, DetailedRecordsGroup, GroupParameters, RegisterKind, RegisterName);
	
	EndIf;
	
	If ResourcesStructureCr.Count() > 0 Then
	
		GroupParameters = New Structure;
		GroupParameters.Insert("NameOfGroup",                    "ResourcesCr");
		GroupParameters.Insert("SelectedGroupLocation",  DataCompositionFieldPlacement.Vertically);
		GroupParameters.Insert("SelectedGroupEmpty",         True);
		GroupParameters.Insert("SelectedGroupPresentation", "");
		
		PlaceDSCFieldsGroup(ResourcesStructureCr, DCDataSet, DetailedRecordsGroup, GroupParameters, RegisterKind, RegisterName);
	
	EndIf;
	
	If ResourcesStructure.Count() > 0 Then
	
		GroupParameters = New Structure;
		GroupParameters.Insert("NameOfGroup",                    "Resources");
		GroupParameters.Insert("SelectedGroupLocation",  Undefined);
		GroupParameters.Insert("SelectedGroupEmpty",         True);
		GroupParameters.Insert("SelectedGroupPresentation", "");
		
		PlaceDSCFieldsGroup(ResourcesStructure, DCDataSet, DetailedRecordsGroup, GroupParameters, RegisterKind, RegisterName);
	
	EndIf;
	
	If AttributesStructure.Count() > 0 Then
	
		GroupParameters = New Structure;
		GroupParameters.Insert("NameOfGroup",                    "Attributes");
		GroupParameters.Insert("SelectedGroupLocation",  Undefined);
		GroupParameters.Insert("SelectedGroupEmpty",         True);
		GroupParameters.Insert("SelectedGroupPresentation", "");
		
		PlaceDSCFieldsGroup(AttributesStructure, DCDataSet, DetailedRecordsGroup, GroupParameters, RegisterKind, RegisterName);
	
	EndIf;
	
EndProcedure

Function AddDataSetField(DataSet, Field, Title, DataPath = Undefined)
	
	If DataPath = Undefined Then
		DataPath = Field;
	EndIf;
	
	DataSetField             = DataSet.Fields.Add(Type("DataCompositionSchemaDataSetField"));
	DataSetField.Field        = Field;
	DataSetField.Title   = Title;
	DataSetField.DataPath = DataPath;
	Return DataSetField;
	
EndFunction

Function AddSelectedField(Destination, DCNameOrField, Title = "") Export
	
	If TypeOf(Destination) = Type("DataCompositionSettingsComposer") Then
		SelectedDCFields = Destination.Settings.Selection;
	ElsIf TypeOf(Destination) = Type("DataCompositionSettings") Or TypeOf(Destination) = Type("DataCompositionGroup") Then
		SelectedDCFields = Destination.Selection;
	Else
		SelectedDCFields = Destination;
	EndIf;
	
	If TypeOf(DCNameOrField) = Type("String") Then
		DCField = New DataCompositionField(DCNameOrField);
	Else
		DCField = DCNameOrField;
	EndIf;
	
	SelectedDCField      = SelectedDCFields.Items.Add(Type("DataCompositionSelectedField"));
	SelectedDCField.Field = DCField;
	
	If Title <> "" Then
		SelectedDCField.Title = Title;
	EndIf;
	
	Return SelectedDCField;
	
EndFunction

Function AddSelectedFieldGroup(Destination, DCNameOrField, Title = "", Location = Undefined)
	
	If TypeOf(Destination) = Type("DataCompositionSettingsComposer") Then
		SelectedDCFields = Destination.Settings.Selection;
	ElsIf TypeOf(Destination) = Type("DataCompositionSettings") Or TypeOf(Destination) = Type("DataCompositionGroup") Then
		SelectedDCFields = Destination.Selection;
	Else
		SelectedDCFields = Destination;
	EndIf;
	
	If TypeOf(DCNameOrField) = Type("String") Then
		DCField = New DataCompositionField(DCNameOrField);
	Else
		DCField = DCNameOrField;
	EndIf;
	
	SelectedDCField      = SelectedDCFields.Items.Add(Type("DataCompositionSelectedFieldGroup"));
	SelectedDCField.Field = DCField;
	
	If Location <> Undefined Then
		SelectedDCField.Placement = Location;
	EndIf;
	
	If Title <> "" Then
		SelectedDCField.Title = Title;
	EndIf;
	
	Return SelectedDCField;
	
EndFunction

Procedure AddRecordsCountResource(Schema)
	
	RecordsCountField = Schema.TotalFields.Find("RegisterRecordCount");
	If RecordsCountField <> Undefined Then
		Return;
	EndIf;
	
	TotalField = Schema.TotalFields.Add();
	TotalField.Groups.Add("RegisterName");
	TotalField.DataPath = "RegisterRecordCount";
	TotalField.Expression = "Sum(RegisterRecordCount)";
	
EndProcedure

#EndRegion

#Region OtherProceduresAndFunctions

Procedure SpecifySettings(Group, Settings)

	For Each SettingItem In Settings Do
	
		Setting = Group.OutputParameters.Items.Find(SettingItem.Key);
		If Setting <> Undefined Then
			SetOutputParameter(Group, SettingItem.Key, SettingItem.Value);
		EndIf;
	
	EndDo;
	
EndProcedure

Function AddStructureItem(DCSettings, GroupName, UserHeader)
	
	GroupByRegister = DCSettings.Structure.Add(Type("DataCompositionGroup"));
	
	GroupByRegister.Name                                    = GroupName;
	GroupByRegister.UserSettingPresentation = UserHeader;
	GroupByRegister.Use                          = True;
	
	GroupByRegister.Selection.Items.Add(Type("DataCompositionAutoSelectedField"));
	GroupByRegister.Order.Items.Add(Type("DataCompositionAutoOrderItem"));
	
	HiseFilerInRegisterRecordsTable(GroupByRegister);
	
	RegisterGroupField = GroupByRegister.GroupFields.Items.Add(Type("DataCompositionGroupField"));
	
	RegisterGroupField.Use  = True;
	RegisterGroupField.Field           = New DataCompositionField("RegisterName");
	RegisterGroupField.GroupType = DataCompositionGroupType.Items;
	RegisterGroupField.AdditionType  = DataCompositionPeriodAdditionType.None;
	
	DetailedRecords = GroupByRegister.Structure.Add(Type("DataCompositionGroup"));
	DetailedRecords.Order.Items.Add(Type("DataCompositionAutoOrderItem"));
	DetailedRecords.Use = True;
	
	Return DetailedRecords;
	
EndFunction

Procedure PlaceDSCFieldsGroup(FieldsStructure, DCDataSet, DetailedRecordsGroup, GroupParameters, RegisterKind, RegisterName)
	
	If GroupParameters.SelectedGroupEmpty Then
		LocalNameOfGroup     = New DataCompositionField("");
		LocalPresentationOfGroup = "";
	Else
		LocalNameOfGroup           = GroupParameters.NameOfGroup;
		LocalPresentationOfGroup = GroupParameters.SelectedGroupPresentation;
	EndIf;
	
	Folder = AddSelectedFieldGroup(DetailedRecordsGroup, LocalNameOfGroup, LocalPresentationOfGroup,
		GroupParameters.SelectedGroupLocation);
	
	For Each StructureItem In FieldsStructure Do
	
		Name           = StructureItem.Key;
		Presentation = StructureItem.Value;
		NameOfGroup     = GroupParameters.NameOfGroup;
		
		If NameOfGroup <> "StandardAttributes" AND NameOfGroup <> "Numerator" AND NameOfGroup <> "DimensionsDr"
			AND NameOfGroup <> "DimensionsCr" AND NameOfGroup <> "ResourcesDr" AND NameOfGroup <> "ResourcesCr" AND NameOfGroup <> "ExtDimensionsDr"
			AND NameOfGroup <> "ExtDimensionsCr" AND NameOfGroup <> "ExtDimensions" Then
			
			If RegisterKind = "Accumulation" Then
				MetadataObject = Metadata.AccumulationRegisters[RegisterName][NameOfGroup][Name];
			ElsIf RegisterKind = "Information" Then
				MetadataObject = Metadata.InformationRegisters[RegisterName][NameOfGroup][Name];
			ElsIf RegisterKind = "Calculation" Then
				MetadataObject = Metadata.CalculationRegisters[RegisterName][NameOfGroup][Name];
			ElsIf RegisterKind = "Accounting" Then
				MetadataObject = Metadata.AccountingRegisters[RegisterName][NameOfGroup][Name];
			EndIf;
			
			If Not Common.MetadataObjectAvailableByFunctionalOptions(MetadataObject) Then
				Continue;
			EndIf;
			
		EndIf;
	
		AddDataSetField(DCDataSet, Name, Presentation);
		AddSelectedField(Folder, Name, Presentation);
	
	EndDo;
	
EndProcedure

Procedure AddFields(SelectionFieldsText, FieldsPresentationNames, DocumentRegisterRecord, CollectionName = "")
	
	For Each Field In FieldsPresentationNames Do
		
		If Not ValueIsFilled(CollectionName) 
			Or Common.MetadataObjectAvailableByFunctionalOptions(DocumentRegisterRecord[CollectionName][Field.Key]) Then
			
			SelectionFieldsText = SelectionFieldsText + ?(ValueIsFilled(SelectionFieldsText), ", ", "") + Field.Key;
		EndIf;
		
	EndDo;
	
EndProcedure

Function FieldsPresentationNames(RegisterFields, Val ExcludedFields = Undefined)
	
	If ExcludedFields <> Undefined Then
		ExcludedFields = StrSplit(ExcludedFields, ", ");
	Else
		ExcludedFields = New Array;
	EndIf;
	
	Result = New Structure;
	For Each RegisterField In RegisterFields Do
	
		If ExcludedFields.Find(RegisterField.Name) = Undefined Then
			Result.Insert(RegisterField.Name, RegisterField.Presentation());
		EndIf;
	
	EndDo;
	
	Return Result;
	
EndFunction

Function FieldsNumbers(DataSet)
	
	Result = New Structure;
	
	MaxNumber = Max(DataSet.StandardAttributes.Count(),
		DataSet.Dimensions.Count(),
		DataSet.Resources.Count(),
		DataSet.Attributes.Count());
			
	For Index = 1 To MaxNumber Do
		IndexAsString = Format(Index, "NG=0");
		Result.Insert("CurrentDocumentDCSOutputItemGroup" + IndexAsString, IndexAsString);
	EndDo;
	
	Return Result;
	
EndFunction

#EndRegion

#EndRegion

#Region ShowDCS

Procedure RegisterResult(Settings, DocumentResult, DocumentRecorder)
	
	FillNotes(Settings);
	
	FullRegisterName = Undefined;
	
	For RowNumber = 1 To DocumentResult.TableHeight Do
		
		For ColumnNumber = 1 To 2 Do // table header search in the first two columns
	
			AreaName = "R" + Format(RowNumber, "NG=0") + "C" + Format(ColumnNumber, "NG=0");
			Area    = DocumentResult.Area(AreaName);
			
			RegisterProperties = RegisterProperties(Area.Text);
			If RegisterProperties = Undefined Then
				Continue;
			EndIf;
			
			FullRegisterName = RegisterProperties.FullRegisterName;
			
			HeaderDetails = New Structure;
			HeaderDetails.Insert("RegisterType", RegisterProperties.RegisterKindPresentation);
			HeaderDetails.Insert("RegisterName", RegisterProperties.RegisterName);
			HeaderDetails.Insert("Recorder", DocumentRecorder);
			HeaderDetails.Insert("RecorderFieldName", RegisterProperties.RecorderFieldName);
			
			Area.Details  = HeaderDetails;
			ReportsServer.OutputHyperlink(Area, HeaderDetails, Area.Text);
			
			NotesBorder = 1;
			
			Break;
		EndDo;
		
		NumeratorAreaName = "R" + Format(RowNumber, "NG=0") + "C1";
		NumeratorArea    = DocumentResult.Area(NumeratorAreaName);
	
		If Not IsNumber(NumeratorArea.Text) Then
			
			If StrFind(NumeratorArea.Text, "№CurrentDocumentDCSOutputItemGroup") > 0 Then
				NumeratorArea.Text = "№";
				NumeratorArea.ColumnWidth = 5;
			EndIf;
			
			Continue;
		EndIf;
	
		NumeratorArea.Indent = 0;
		NumeratorArea.HorizontalAlign = HorizontalAlign.Left;

		If FullRegisterName = Undefined Then 
			Continue;
		EndIf;
		
		FoundNotes = Notes.FindRows(
			New Structure("FullRegisterName, Floor", FullRegisterName, NumeratorArea.Text));
		
		If FoundNotes.Count() = 0 Then 
			Continue;
		EndIf;
		
		NoteProperties = FoundNotes[0];
		
		StringHeight = NoteProperties.Height + 1;
		If NotesBorder = StringHeight Then
			
			NoteText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'В этой строке: %1'; en = 'In this line: %1'; pl = 'In this line: %1';de = 'In this line: %1';ro = 'In this line: %1';tr = 'In this line: %1'; es_ES = 'In this line: %1'"), NoteProperties.Comment + ".");
			
			NumeratorArea.Comment.Text = NoteText;
		Else
			NotesBorder = NotesBorder + 1;
		EndIf;
		
	EndDo;
	
EndProcedure

#EndRegion

#Region AppearanceSection

Procedure HideParametersAndFilters(DCSettings)
	
	Settings = New Structure;
	Settings.Insert("OutputFilter",           DataCompositionTextOutputType.DontOutput);
	Settings.Insert("OutputDataParameters", DataCompositionTextOutputType.DontOutput);
	SpecifySettings(DCSettings, Settings);
	
EndProcedure

Procedure HiseFilerInRegisterRecordsTable(GroupByRegister)
	
	Settings = New Structure;
	Settings.Insert("OutputFilter", DataCompositionTextOutputType.DontOutput);
	SpecifySettings(GroupByRegister, Settings);
	
EndProcedure

Procedure SetConditionalAppearance(Settings)
	
	AppearanceItems = Settings.ConditionalAppearance.Items;
	ApplyAppearanceNegativeNumbers(AppearanceItems);
	
	If RegistersProperties.Find("Balance", "AccumulationRegisterType") = Undefined Then 
		Return;
	EndIf;
	
	ApplyAppearanceRegisterRecordType(AppearanceItems, AccumulationRecordType.Receipt);
	ApplyAppearanceRegisterRecordType(AppearanceItems, AccumulationRecordType.Expense);
	
EndProcedure

Procedure ApplyAppearanceNegativeNumbers(AppearanceItems)
	
	Item = AppearanceItems.Add();
	
	FilterItem = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	FilterItem.LeftValue = New DataCompositionField("DataParameters.NegativeInRed");
	FilterItem.ComparisonType = DataCompositionComparisonType.Equal;
	FilterItem.RightValue = True;
	
	Item.Appearance.SetParameterValue("MarkNegatives", True);
	
	Item.ViewMode = DataCompositionSettingsItemViewMode.Inaccessible;
	Item.Use = True;
	
EndProcedure

Procedure ApplyAppearanceRegisterRecordType(AppearanceItems, RegisterRecordType)
	
	RegisterRecordTypeField = New DataCompositionField("RecordType");
	
	Item = AppearanceItems.Add();
	
	FilterItem = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	FilterItem.LeftValue = New DataCompositionField("DataParameters.HighlightAccumulationRecordKind");
	FilterItem.ComparisonType = DataCompositionComparisonType.Equal;
	FilterItem.RightValue = True;
	
	FilterItem = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	FilterItem.LeftValue = RegisterRecordTypeField;
	FilterItem.ComparisonType = DataCompositionComparisonType.Equal;
	FilterItem.RightValue = RegisterRecordType;
	
	FormattedFields = Item.Fields.Items;
	FormattedField = FormattedFields.Add();
	FormattedField.Field = RegisterRecordTypeField;
	
	Item.UseInHeader = DataCompositionConditionalAppearanceUse.DontUse;
	Item.UseInFieldsHeader = DataCompositionConditionalAppearanceUse.DontUse;
	
	If RegisterRecordType = AccumulationRecordType.Receipt Then 
		RegisterRecordKindColor = StyleColors.SuccessResultColor;
	Else
		RegisterRecordKindColor = StyleColors.NegativeTextColor;
	EndIf;
	
	Item.Appearance.SetParameterValue("TextColor", RegisterRecordKindColor);
	Item.Use = True;
	
EndProcedure

#EndRegion

#Region RegistersPropertiesGet

Procedure GetRegistersProperties(Context, DocumentOwner = Undefined)
	
	GetRegistersPropertiesFromCache(Context);
	
	If RegistersProperties.Count() > 0
		Or DocumentOwner = Undefined Then 
		
		CacheRegistersProperties(RegistersProperties, Context);
		Return;
	EndIf;
	
	DocumentRegisterRecords = RegistersWithDocumentRecords(DocumentOwner);
	RecordsCount = RecordsCountByRecorder(DocumentOwner, DocumentRegisterRecords);
	
	For Each RegisterRecord In DocumentRegisterRecords Do
		
		RegisterMetadata = RegisterRecord.Key;
		
		RegisterProperties = RegistersProperties.Add();
		RegisterProperties.RecorderFieldName = RegisterRecord.Value;
		RegisterProperties.FullRegisterName = RegisterMetadata.FullName();
		RegisterProperties.GroupName = StrReplace(RegisterProperties.FullRegisterName, ".", "_");
		RegisterProperties.RegisterName = RegisterMetadata.Name;
		RegisterProperties.RegisterPresentation = RegisterMetadata.Presentation();
		RegisterProperties.RecordsCount = RecordsCount[RegisterProperties.GroupName];
		
		If Common.IsAccumulationRegister(RegisterMetadata) Then
			
			RegisterProperties.RegisterType = "Accumulation";
			RegisterProperties.RegisterKindPresentation = NStr("ru = 'Накопления'; en = 'Accumulations'; pl = 'Accumulations';de = 'Accumulations';ro = 'Accumulations';tr = 'Accumulations'; es_ES = 'Accumulations'");
			RegisterProperties.AccumulationRegisterType = RegisterMetadata.RegisterType;
			RegisterProperties.Priority = 1;
			
		ElsIf Common.IsInformationRegister(RegisterMetadata) Then
			
			RegisterProperties.RegisterType = "Information";
			RegisterProperties.RegisterKindPresentation = NStr("ru = 'Сведений'; en = 'Information'; pl = 'Information';de = 'Information';ro = 'Information';tr = 'Information'; es_ES = 'Information'");
			RegisterProperties.InformationRegisterPeriodicity = RegisterMetadata.InformationRegisterPeriodicity;
			RegisterProperties.InformationRegisterWriteMode = RegisterMetadata.WriteMode;
			RegisterProperties.Priority  = 2;
			
		ElsIf Common.IsAccountingRegister(RegisterMetadata) Then
			
			RegisterProperties.RegisterType = "Accounting";
			RegisterProperties.RegisterKindPresentation = NStr("ru = 'Бухгалтерии'; en = 'Accounting department'; pl = 'Accounting department';de = 'Accounting department';ro = 'Accounting department';tr = 'Accounting department'; es_ES = 'Accounting department'");
			RegisterProperties.Priority = 3;
			
		ElsIf Common.IsCalculationRegister(RegisterMetadata) Then
			
			RegisterProperties.RegisterType = "Calculation";
			RegisterProperties.RegisterKindPresentation = NStr("ru = 'Расчета'; en = 'Calculation'; pl = 'Calculation';de = 'Calculation';ro = 'Calculation';tr = 'Calculation'; es_ES = 'Calculation'");
			RegisterProperties.CalculationRegisterPeriodicity = RegisterMetadata.Periodicity;
			RegisterProperties.Priority = 4;
			
		EndIf;
		
		TableHeader = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Регистр %1 ""%2""'; en = '""%2"" %1 register'; pl = '""%2"" %1 register';de = '""%2"" %1 register';ro = '""%2"" %1 register';tr = '""%2"" %1 register'; es_ES = '""%2"" %1 register'"), TrimAll(RegisterProperties.RegisterKindPresentation), RegisterProperties.RegisterPresentation);
		
		RegisterProperties.TableHeader = Upper(TableHeader);
		
	EndDo;
	
	RegistersProperties.Sort("Priority, RegisterPresentation");
	
	CacheRegistersProperties(RegistersProperties, Context);
	
EndProcedure

Procedure GetRegistersPropertiesFromCache(Context)
	
	RegistersProperties = RegistersPropertiesPalette();
	
	If TypeOf(Context) = Type("ManagedForm") Then 
		
		RegistriesPropertiesAddress = CommonClientServer.StructureProperty(
			Context.ReportSettings, "RegistriesPropertiesAddress");
		
	ElsIf TypeOf(Context) = Type("DataCompositionSettings") Then 
		
		RegistriesPropertiesAddress = CommonClientServer.StructureProperty(
			Context.AdditionalProperties, "RegistriesPropertiesAddress");
	Else
		Return;
	EndIf;
	
	If Not IsTempStorageURL(RegistriesPropertiesAddress) Then 
		Return;
	EndIf;
	
	RegistersPropertiesFromCache = GetFromTempStorage(RegistriesPropertiesAddress);
	If TypeOf(RegistersPropertiesFromCache) = Type("ValueTable") Then 
		RegistersProperties = RegistersPropertiesFromCache;
	EndIf;
	
EndProcedure

Procedure CacheRegistersProperties(RegistersProperties, Context)
	
	RegistriesPropertiesAddress = PutToTempStorage(RegistersProperties);
	
	If TypeOf(Context) = Type("ManagedForm") Then 
		
		Context.ReportSettings.Insert("RegistriesPropertiesAddress", RegistriesPropertiesAddress);
		
	ElsIf TypeOf(Context) = Type("DataCompositionSettings") Then
		
		Context.AdditionalProperties.Insert("RegistriesPropertiesAddress", RegistriesPropertiesAddress);
		
	EndIf;
	
EndProcedure

Function RegistersPropertiesPalette()
	
	RegistersPropertiesPalette = New ValueTable;
	
	NumberDetails = New TypeDescription("Number");
	RowDetails = New TypeDescription("String");
	FlagDetails = New TypeDescription("Boolean");
	
	RegistersPropertiesPalette.Columns.Add("Priority", NumberDetails);
	RegistersPropertiesPalette.Columns.Add("FullRegisterName", RowDetails);
	RegistersPropertiesPalette.Columns.Add("GroupName", RowDetails);
	RegistersPropertiesPalette.Columns.Add("RegisterName", RowDetails);
	RegistersPropertiesPalette.Columns.Add("RegisterPresentation", RowDetails);
	RegistersPropertiesPalette.Columns.Add("RegisterType", RowDetails);
	RegistersPropertiesPalette.Columns.Add("AccumulationRegisterType", RowDetails);
	RegistersPropertiesPalette.Columns.Add("RegisterKindPresentation", RowDetails);
	RegistersPropertiesPalette.Columns.Add("CalculationRegisterPeriodicity", RowDetails);
	RegistersPropertiesPalette.Columns.Add("InformationRegisterPeriodicity", RowDetails);
	RegistersPropertiesPalette.Columns.Add("InformationRegisterWriteMode", RowDetails);
	RegistersPropertiesPalette.Columns.Add("RecorderFieldName", RowDetails);
	RegistersPropertiesPalette.Columns.Add("RecordsCount", NumberDetails);
	RegistersPropertiesPalette.Columns.Add("TableHeader", RowDetails);
	
	Return RegistersPropertiesPalette;
	
EndFunction

#EndRegion

#Region NotesGeneration

Procedure FillNotes(Settings)
	
	Notes = NotesPropertiesPalette();
	
	For Each RegisterProperties In RegistersProperties Do 
	
		SelectedFieldsGroups = New Array;
		Groupings = Settings.Structure;
		FindGroupRecursively(Groupings, SelectedFieldsGroups, RegisterProperties.GroupName);
		
		NumeratorField  = New DataCompositionField("Numerator");
		StringHeight = StringHeight(NumeratorField, SelectedFieldsGroups);
		
		For Index = 0 To StringHeight - 1 Do
		
			NoteText = "";
		
			For Each SelectedGroup In SelectedFieldsGroups Do
				If SelectedGroup.Field = NumeratorField Then
					Continue;
				EndIf;
		
				Title = "";
				If SelectedGroup.Title = NStr("ru = 'Стандартные реквизиты'; en = 'Standard attributes'; pl = 'Standard attributes';de = 'Standard attributes';ro = 'Standard attributes';tr = 'Standard attributes'; es_ES = 'Standard attributes'") Then
					Title = NStr("ru = 'Стандартный реквизит'; en = 'Standard attribute'; pl = 'Standard attribute';de = 'Standard attribute';ro = 'Standard attribute';tr = 'Standard attribute'; es_ES = 'Standard attribute'");
				ElsIf SelectedGroup.Title = NStr("ru = 'Измерения'; en = 'Dimensions'; pl = 'Dimensions';de = 'Dimensions';ro = 'Dimensions';tr = 'Dimensions'; es_ES = 'Dimensions'") Then
					Title = NStr("ru = 'Измерение'; en = 'Dimension'; pl = 'Dimension';de = 'Dimension';ro = 'Dimension';tr = 'Dimension'; es_ES = 'Dimension'");
				ElsIf SelectedGroup.Title = NStr("ru = 'Ресурсы'; en = 'Resources'; pl = 'Resources';de = 'Resources';ro = 'Resources';tr = 'Resources'; es_ES = 'Resources'") Then
					Title = NStr("ru = 'Ресурс'; en = 'Resource'; pl = 'Resource';de = 'Resource';ro = 'Resource';tr = 'Resource'; es_ES = 'Resource'");
				ElsIf SelectedGroup.Title = NStr("ru = 'Реквизиты'; en = 'Attributes'; pl = 'Attributes';de = 'Attributes';ro = 'Attributes';tr = 'Attributes'; es_ES = 'Attributes'") Then
					Title = NStr("ru = 'Реквизит'; en = 'Attribute'; pl = 'Attribute';de = 'Attribute';ro = 'Attribute';tr = 'Attribute'; es_ES = 'Attribute'");
				ElsIf SelectedGroup.Title = NStr("ru = 'Данные расчета'; en = 'Calculation data'; pl = 'Calculation data';de = 'Calculation data';ro = 'Calculation data';tr = 'Calculation data'; es_ES = 'Calculation data'") Then
					Title = NStr("ru = 'Данные расчета'; en = 'Calculation data'; pl = 'Calculation data';de = 'Calculation data';ro = 'Calculation data';tr = 'Calculation data'; es_ES = 'Calculation data'");
				EndIf;

				Items = SelectedGroup.Items;

				If Index <= Items.Count() - 1 Then
					SelectedField = Items[Index];
					If SelectedField.Use Then
						NoteText = NoteText
							+ ?(ValueIsFilled(NoteText), ", ", "")
							+ Items[Index].Title + " (" + Title + ")";
					EndIf;
				EndIf;
			EndDo;
			
			Note = Notes.Add();
			Note.FullRegisterName = RegisterProperties.FullRegisterName;
			Note.Comment = NoteText;
			Note.Floor = Format(Index + 1, "NG=0");
			Note.Height = StringHeight;
		
		EndDo;
	
	EndDo;
	
EndProcedure

Function NotesPropertiesPalette()
	
	NotesPropertiesPalette = New ValueTable;
	
	NumberDetails = New TypeDescription("Number");
	RowDetails = New TypeDescription("String");
	
	NotesPropertiesPalette.Columns.Add("FullRegisterName", RowDetails);
	NotesPropertiesPalette.Columns.Add("Comment", RowDetails);
	NotesPropertiesPalette.Columns.Add("Floor", RowDetails);
	NotesPropertiesPalette.Columns.Add("Height", NumberDetails);
	
	Return NotesPropertiesPalette;
	
EndFunction

Function StringHeight(NumeratorField, SelectedFieldsArray)
	
	StringHeight = 0;
	For Each SelectedGroup In SelectedFieldsArray Do
	
		If SelectedGroup.Field = NumeratorField Then
			Items = SelectedGroup.Items;
			For Each Item In Items Do
				If Item.Use Then
					StringHeight = StringHeight + 1;
				EndIf;
			EndDo;
		EndIf;
	
	EndDo;
	
	Return StringHeight;
	
EndFunction

#EndRegion

#Region OtherProceduresAndFunctions

Function RegistersWithDocumentRecords(Recorder, RegisterRecords = Undefined)
	
	If RegisterRecords = Undefined Then 
		RegisterRecords = Recorder.Metadata().RegisterRecords;
	EndIf;
	
	Result = New Map;
	For Each MetadataObjectRegister In RegisterRecords Do
		If Not AccessRight("View", MetadataObjectRegister) Then
			Continue;
		EndIf;
		
		Result.Insert(MetadataObjectRegister, "Recorder");
	EndDo;
	
	AdditionalRegisters = New Map;
	DocumentRecordsReportOverridable.OnDetermineRegistersWithRecords(Recorder, AdditionalRegisters);
	
	For Each AdditionalRegister In AdditionalRegisters Do
		If Not AccessRight("View", AdditionalRegister.Key) Then
			Continue;
		EndIf;
		Result.Insert(AdditionalRegister.Key, AdditionalRegister.Value);
	EndDo;
	
	Return Result;
	
EndFunction

Function RecordsCountByRecorder(Recorder, DocumentRegisterRecords)
	
	CalculatedCount = New Map;
	If DocumentRegisterRecords.Count() = 0 Then
		Return CalculatedCount;
	EndIf;
	
	QueryText = "";
	For Each RegisterRecord In DocumentRegisterRecords Do
		
		RegisterMetadata = RegisterRecord.Key;
		FullRegisterName = RegisterMetadata.FullName();
		
		QueryTextTemplate =
		"SELECT ALLOWED
		|	""&FullRegisterName"" AS FullRegisterName,
		|	COUNT(*) AS Count
		|FROM
		|	&CurrentTable AS CurrentTable
		|WHERE
		|	&Condition";
		
		ConditionText = StringFunctionsClientServer.SubstituteParametersToString("%1 = &OwnerDocument", RegisterRecord.Value);
		QueryTextTemplate = StrReplace(QueryTextTemplate, "&FullRegisterName", StrReplace(FullRegisterName, ".", "_"));
		QueryTextTemplate = StrReplace(QueryTextTemplate, "&Condition", ConditionText);
		QueryTextTemplate = StrReplace(QueryTextTemplate, "&CurrentTable", FullRegisterName);
		
		If ValueIsFilled(QueryText) Then
			QueryText = QueryText + " UNION ALL " + StrReplace(QueryTextTemplate, "SELECT ALLOWED", "SELECT");
		Else
			QueryText = QueryTextTemplate;
		EndIf;
		
	EndDo;
	
	Query = New Query(QueryText);
	Query.SetParameter("OwnerDocument", Recorder);
	Result = Query.Execute().Unload();
	
	For Each ResultString In Result Do
		CalculatedCount.Insert(ResultString.FullRegisterName, ResultString.Count);
	EndDo;
	
	DocumentRecordsReportOverridable.OnCalculateRecordsCount(Recorder, CalculatedCount);
	
	Return CalculatedCount;
	
EndFunction

Procedure RedefineDSCTemplate(DCSchema, SetIndex, RegisterKind, RegisterKindPresentation, RegisterName)
	
	SearchStructure = New Structure("RegisterType, RegisterName", RegisterKind, RegisterName);
	RegisterSettings = RegistersProperties.FindRows(SearchStructure);
	If RegisterSettings.Count() = 0 Then
		Return;
	EndIf;
		
	RegisterPresentation = RegisterSettings[0].RegisterPresentation;
	GroupHeader = StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = 'Регистр %1 ""%2""'; en = '""%2"" %1 register'; pl = '""%2"" %1 register';de = '""%2"" %1 register';ro = '""%2"" %1 register';tr = '""%2"" %1 register'; es_ES = '""%2"" %1 register'"),
		Lower(RegisterKindPresentation),RegisterPresentation);
	
	Template       = DCSchema.Templates.Add();
	Template.Name   = "Template" + Format(SetIndex + 1, "NG=0");
	Template.Template = New DataCompositionAreaTemplate;
	
	Parameter           = Template.Parameters.Add(Type("DataCompositionExpressionAreaParameter"));
	Parameter.Name       = "RecordsCount";
	Parameter.Expression = "RegisterRecordCount";
	
	GroupTemplate                = DCSchema.GroupTemplates.Add();
	GroupTemplate.GroupName = "Register" + RegisterKind + "_" + RegisterName;
	GroupTemplate.TemplateType      = DataCompositionAreaTemplateType.Header;
	GroupTemplate.Template          = "Template" + Format(SetIndex + 1, "NG=0");
	
	AreaTemplate = Template.Template;
	TemplateString = AreaTemplate.Add(Type("DataCompositionAreaTemplateTableRow"));
	Cell       = TemplateString.Cells.Add();
	
	CellAppearance = Cell.Appearance.Items;
	
	Font = CellAppearance.Find("Font");
	
	If Font <> Undefined Then
		Font.Value      = New Font("Arial", 14);
		Font.Use = True;
	EndIf;
	
	Placement = CellAppearance.Find("Placement");
	
	If Placement <> Undefined Then
		Placement.Value      = DataCompositionTextPlacementType.Wrap;
		Placement.Use = True;
	EndIf;
	
	DCArea          = Cell.Items.Add(Type("DataCompositionAreaTemplateField"));
	DCArea.Value = GroupHeader + " (";
	
	DCArea          = Cell.Items.Add(Type("DataCompositionAreaTemplateField"));
	DCArea.Value = New DataCompositionParameter(Parameter.Name);
	
	DCArea          = Cell.Items.Add(Type("DataCompositionAreaTemplateField"));
	DCArea.Value = ")";
		
EndProcedure

Function RegistersList()
	
	RegistersList = New ValueList;
	
	For Each RegisterProperties In RegistersProperties Do
		
		ItemPresentation = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Регистр %1 %2'; en = '%1 %2 register'; pl = '%1 %2 register';de = '%1 %2 register';ro = '%1 %2 register';tr = '%1 %2 register'; es_ES = '%1 %2 register'"),
			Lower(RegisterProperties.RegisterKindPresentation), RegisterProperties.RegisterPresentation);
			
		RegistersList.Add(RegisterProperties.GroupName, ItemPresentation);
	
	EndDo;
	
	Return RegistersList;
	
EndFunction

Function SelectedRegistersList(RegistersList, Settings, UserSettings)
	
	SettingItem = Settings.DataParameters.Items.Find("RegistersList");
	
	If SettingItem = Undefined Then 
		Return RegistersList;
	EndIf;
	
	UserSettingItem = UserSettings.Items.Find(
		SettingItem.UserSettingID);
	
	If UserSettingItem = Undefined Then 
		Return RegistersList;
	EndIf;
	
	If TypeOf(UserSettingItem.Value) = Type("ValueList")
		AND UserSettingItem.Value.Count() > 0 Then 
		Return UserSettingItem.Value;
	EndIf;
	
	If TypeOf(UserSettingItem.Value) <> Type("String")
		Or Not ValueIsFilled(UserSettingItem.Value) Then 
		Return RegistersList;
	EndIf;
	
	SelectedRegistersList = New ValueList;
	SelectedRegistersList.Add(UserSettingItem.Value);
	
	Return SelectedRegistersList;
	
EndFunction

Procedure SetDataParameters(Settings, ParametersValues, UserSettings = Undefined)
	
	DataParameters = Settings.DataParameters.Items;
	
	For Each ParameterValue In ParametersValues Do 
		
		DataParameter = DataParameters.Find(ParameterValue.Key);
		
		If DataParameter = Undefined Then
			DataParameter = DataParameters.Add();
			DataParameter.Parameter = New DataCompositionParameter(ParameterValue.Key);
		EndIf;
		
		DataParameter.Use = True;
		DataParameter.Value = ParameterValue.Value;
		
		If Not ValueIsFilled(DataParameter.UserSettingID)
			Or TypeOf(UserSettings) <> Type("DataCompositionUserSettings") Then 
			Continue;
		EndIf;
		
		MatchingParameter = UserSettings.Items.Find(
			DataParameter.UserSettingID);
		
		If MatchingParameter <> Undefined Then 
			FillPropertyValues(MatchingParameter, DataParameter, "Use, Value");
		EndIf;
		
	EndDo;
	
EndProcedure

Function IsNumber(Val ValueToCheck)
	
	If ValueToCheck = "0" Then
		Return True;
	EndIf;
	
	NumberDetails = New TypeDescription("Number");
	
	Return NumberDetails.AdjustValue(ValueToCheck) <> 0;
	
EndFunction

Function ControlItemsPlacementParameters()
	
	Settings         = New Array;
	Control = New Structure;
	
	Control.Insert("Field",                     "RegistersList");
	Control.Insert("HorizontalStretch", False);
	Control.Insert("AutoMaxWidth",   True);
	Control.Insert("Width",                   40);
	
	Settings.Add(Control);
	
	Result = New Structure();
	Result.Insert("DataParameters", Settings);
	
	Return Result;
	
EndFunction

Function SetOutputParameter(GroupSettingsComposer, ParameterName, Value)
	
	DSCParameter = New DataCompositionParameter(ParameterName);
	If TypeOf(GroupSettingsComposer) = Type("DataCompositionSettingsComposer") Then	
		ParameterValue = GroupSettingsComposer.Settings.OutputParameters.FindParameterValue(DSCParameter);
	Else
		ParameterValue = GroupSettingsComposer.OutputParameters.FindParameterValue(DSCParameter);
	EndIf;
	
	If ParameterValue <> Undefined Then
		ParameterValue.Use = True;
		ParameterValue.Value = Value;
	EndIf;
	
	Return ParameterValue;
	
EndFunction

Procedure FindGroupRecursively(ItemsCollection, SelectedFieldsArray, SearchValue)
	
	For each Item In ItemsCollection Do
		If TypeOf(Item) = Type("DataCompositionGroup") Then
			If Item.Name = SearchValue Then
				If Item.Structure.Count() > 0 Then
					DetailedRecords = Item.Structure[0];
					SelectedFields   = DetailedRecords.Selection.Items;
					For Each SelectedField In SelectedFields Do
						SelectedFieldsArray.Add(SelectedField);
					EndDo;
				EndIf;
			EndIf;
			FindGroupRecursively(Item.Structure, SelectedFieldsArray, SearchValue);
		ElsIf TypeOf(Item) = Type("DataCompositionTable") Then
			FindGroupRecursively(Item.Rows, SelectedFieldsArray, SearchValue);
			FindGroupRecursively(Item.Columns, SelectedFieldsArray, SearchValue);
		ElsIf TypeOf(Item) = Type("DataCompositionChart") Then
			FindGroupRecursively(Item.Series, SelectedFieldsArray, SearchValue);
			FindGroupRecursively(Item.Points, SelectedFieldsArray, SearchValue);
		EndIf;
	EndDo;
	
EndProcedure

Function ReportParameters(Settings, UserSettings)
	
	Result = New Structure("OwnerDocument");
	
	FoundParameter = Undefined;
	
	If TypeOf(UserSettings) = Type("DataCompositionUserSettings") Then
		For Each Item In UserSettings.Items Do
			If TypeOf(Item) = Type("DataCompositionSettingsParameterValue") Then
				ParameterName = String(Item.Parameter);
				If ParameterName = "OwnerDocument" Then
					FoundParameter = Item;
				EndIf;
			EndIf;
		EndDo;
	EndIf;
	
	If FoundParameter = Undefined Then
		FoundParameter = Settings.DataParameters.Items.Find("OwnerDocument");
	EndIf;
	
	If FoundParameter <> Undefined Then
		Result.OwnerDocument = FoundParameter.Value;
	EndIf;
	
	Return Result;
	
EndFunction

Function RegisterProperties(Val AreaText)
	
	AreaText = Upper(TrimAll(AreaText));
	If Not ValueIsFilled(AreaText) Then
		Return Undefined;
	EndIf;
		
	CountPosition = StrFind(AreaText, "(", SearchDirection.FromEnd);
	If CountPosition = 0 Then
		Return Undefined;
	EndIf;
	
	TableHeader = Left(AreaText, CountPosition - 2);
	
	Return RegistersProperties.Find(TableHeader, "TableHeader");
	
EndFunction

Procedure RestoreFilterByRegistersGroups(Settings)
	
	RegistersList = New ValueList;
	
	FoundParameter = Settings.DataParameters.Items.Find("RegistersList");
	If FoundParameter <> Undefined Then 
		
		If TypeOf(FoundParameter.Value) = Type("ValueList") Then 
			RegistersList = FoundParameter.Value;
		ElsIf FoundParameter.Value <> Undefined Then 
			RegistersList.Add(FoundParameter.Value);
		EndIf;
		
	EndIf;
	
	ReportStructure = Settings.Structure;
	For Each StructureItem In ReportStructure Do
		
		RegisterProperties = RegistersProperties.Find(StructureItem.Name, "GroupName");
		
		StructureItem.Use =
			RegistersList.FindByValue(StructureItem.Name) <> Undefined
			AND RegisterProperties.RecordsCount > 0;
		
		CommonClientServer.SetFilterItem(
			StructureItem.Filter,
			"RegisterName",
			StructureItem.Name,
			DataCompositionComparisonType.Equal,
			NStr("ru = 'Служебный отбор'; en = 'Service filter'; pl = 'Service filter';de = 'Service filter';ro = 'Service filter';tr = 'Service filter'; es_ES = 'Service filter'"),
			True,
			DataCompositionSettingsItemViewMode.Inaccessible);
		
	EndDo;
	
EndProcedure

#EndRegion

#EndRegion

#Else
Raise NStr("ru = 'Недопустимый вызов объекта на клиенте.'; en = 'Invalid object call on the client.'; pl = 'Invalid object call on the client.';de = 'Invalid object call on the client.';ro = 'Invalid object call on the client.';tr = 'Invalid object call on the client.'; es_ES = 'Invalid object call on the client.'");
#EndIf