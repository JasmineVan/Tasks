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
//   Settings - Structure -
//       
//       * GenerateImmediately - Boolean - the default value for the "Generate immediately" check box.
//           If the check box is enabled, the report will be generated:
//             - After opening;
//             - After selecting user settings;
//             - After selecting another report option.
//       
//       * OutputSelectedCellTotal - Boolean - If True, the report will contain the autosum field.
//       
//       * ParametersPeriodicityMap - Map - restriction of the selection list of the StandardPeriod fields.
//           ** Key - DataCompositionParameter - a report parameter name to which restrictions are applied.
//           ** Value - EnumRef.AvailableReportPeriods - the report period bottom limit.
//       
//       * Print - Structure - default print settings of a spreadsheet document.
//           ** TopMargin - Number - the top margin for printing (in millimeters).
//           ** LeftMargin  - Number - the left margin for printing (in millimeters).
//           ** BottomMargin  - Number - the bottom margin for printing (in millimeters).
//           ** RightMargin - Number - the right margin for printing (in millimeters).
//           ** PageOrientation - PageOrientation - "Portrait" or "Landscape".
//           ** FitToPage - Boolean - automatically scale to page size.
//           ** PrintScale - Number - image scale (percentage).
//       
//       * Events - Structure - events that have handlers defined in the report object module.
//           
//           ** OnCreateAtServer - Boolean - if True, then the event handler must be defined in the 
//               report object module according to the following template:
//               
//               // Called in the event handler of the report form after executing the form code.
//               //
//               // Parameters:
//               //   Form - ManagedForm - a report form.
//               //   Cancel - passed from the handler parameters "as it is".
//               //   StandardProcessing - passed from the handler parameters "as it is".
//               //
//               // See also:
//               //   "ManagedForm.OnCreateAtServer" in Syntax Assistant.
//               //
//               // Example 1 - Adding a command with a handler to  ReportsClientOverridable.CommandHandler:
//               //\Command = From.Commands.Add("MySpecialCommand");
//               //	Command.Action  = "Attachable_Command";
//               //	Command.Header = NStr("en = 'MyCommand...'");
//               //	
//               //	Button = Form.Items.Add(Command.Name, Type("FormButton"), Form.Items.<SubmenuName>);
//               //	Button.CommandName = Command.Name;
//               //	
//               //	Form.ConstantCommands.Add(CommandCreate.Name);
//               //
//               Procedure OnCreateAtServer(Form, Cancel, StandardProcessing) Export
//               	// Handling an event.
//               EndProcedure
//           
//           ** BeforeLoadOptionAtServer - Boolean - if True, then the event handler must be defined 
//               in the report object module according to the following template:
//               
//               // Called in the event handler of the report form after executing the form code.
//               //
//               // Parameters:
//               //   Form - ManagedForm - a report form.
//               //   NewDCSettings - DataCompositionSettings - settings to load into the settings composer.
//               //
//               // See also:
//               //   "Managed form extension for reports.OnLoadOptionAtServer" in Syntax Assistant.
//               //
//               Procedure BeforeLoadOptionAtServer(Form, NewDCSettings) Export
//               	// Handling an event.
//               EndProcedure
//           
//           ** OnLoadOptionAtServer - Boolean - if True, then the event handler must be defined in 
//               the report object module according to the following template:
//               
//               // Called in the event handler of the report form after executing the form code.
//               //
//               // Parameters:
//               //   Form - ManagedForm - a report form.
//               //   NewDCSettings - DataCompositionSettings - settings to load into the settings composer.
//               //
//               // See also:
//               //   "Managed form extension for reports.OnLoadOptionAtServer" in Syntax Assistant.
//               //
//               Procedure OnLoadOptionAtServer(Form, NewDCSettings) Export
//               	// Handling an event.
//               EndProcedure
//           
//           ** OnLoadUserSettingsAtServer - Boolean - if True, then the event handler must be 
//               defined in the report object module according to the following template:
//               
//               // Called in the event handler of the report form after executing the form code.
//               //
//               // Parameters:
//               //   Form - ManagedForm - a report form.
//               //   NewDataCompositionUserSettings - DataCompositionUserSettings -
//               //       User settings to be imported to the settings composer.
//               //
//               // See also:
//               //   "Managed form extension for reports.OnLoadUserSettingsAtServer"
//               //    in Syntax Assistant.
//               //
//               Procedure OnLoadUserSettingsAtServer(Form, NewDataCompositionUserSettings) Export
//               	// Handling an event.
//               EndProcedure
//           
//           ** BeforeFillQuickSettingsPanel - Boolean - If True, define the event handler in the 
//               report object module using the following template:
//               
//               // The procedure is called before refilling the report form settings panel.
//               //
//               // Parameters:
//               //   Form - ManagedForm - a report form.
//               //   FillingParameters - Structure - parameters to be loaded to the report.
//               //
//               Procedure BeforeFillQuickSettingsPanel(Form, FillingParameters) Export
//               	// Handling an event.
//               EndProcedure
//           
//           ** AfterFillQuickSettingsPanel - Boolean - if True, then the event handler must be 
//               defined in the report object module according to the following template:
//               
//               // The procedure is called after refilling the report form settings panel.
//               //
//               // Parameters:
//               //   Form - ManagedForm - a report form.
//               //   FillingParameters - Structure - parameters to be loaded to the report.
//               //
//               Procedure AfterFillQuickSettingsPanel(Form, FillingParameters) Export
//               	// Handling an event.
//               EndProcedure
//           
//           ** ContextServerCall - Boolean - If True, define the event handler in the report object 
//               module using the following template:
//               
//               // Context server call handler.
//               //   Allows to execute a context server call from the client common module when you need it.
//               //   For example, from ReportsClientOverridable.CommandHandler().
//               //
//               // Parameters:
//               //   Form  - ManagedForm
//               //   Key      - String    - a key of the operation to be executed in the context call.
//               //   Parameters - Structure - server call parameters.
//               //   Result - Structure - the result of server operations, it is returned to the client.
//               //
//               // See also:
//               //   CommonForm.ReportForm.ExecuteContextServerCall().
//               //
//               Procedure ContextServerCall(Form, Key, Parameters, Result) Export
//               	// Handling an event.
//               EndProcedure
//           
//           ** OnDefineChoiceParameters - Boolean - if True, then the event handler must be defined 
//               in the report object module according to the following template:
//               
//               // The procedure is called in the report form before outputting the setting.
//               //   See more in ReportsOverridable.OnDefineChoiceParameters(). 
//               //
//               Procedure OnDefineChoiceParameters(Form, SettingProperties) Export
//               	// Handling an event.
//               EndProcedure
//           
//           ** AddMetadataObjectsLinks - Boolean - if True, then the event handler must be defined 
//               in the report object module according to the following template:
//               
//               // Additional links of the report settings.
//               //   See more in ReportsOverridable.SupplementMetadateObjectsConnections(). 
//               //
//               Procedure SupplementMetadateObjectsConnections(MetadataObjectsLinks) Export
//               	// Handling an event.
//               EndProcedure
//
Procedure DefineFormSettings(Form, OptionKey, Settings) Export
	Settings.Events.OnCreateAtServer = True;
	Settings.Events.BeforeLoadVariantAtServer = True;
	Settings.Events.BeforeImportSettingsToComposer = True;
	Settings.Events.OnDefineSelectionParameters = True;
	Settings.Events.OnDefineSettingsFormItemsProperties = True;
	
	Settings.ImportSchemaAllowed = True;
	Settings.EditSchemaAllowed = True;
	Settings.RestoreStandardSchemaAllowed = True;
	
	Settings.ImportSettingsOnChangeParameters = Reports.UniversalReport.ImportSettingsOnChangeParameters();
EndProcedure

// See ReportsOverridable.OnCreateAtServer. 
Procedure OnCreateAtServer(Form, Cancel, StandardProcessing) Export
	EditOptionsAllowed = CommonClientServer.StructureProperty(
		Form.ReportSettings, "EditOptionsAllowed", False);
	
	If EditOptionsAllowed Then
		Form.ReportSettings.Insert("SettingsFormAdvancedMode", 1);
	EndIf;
EndProcedure

// See ReportsOverridable.OnDefineChoiceParameters. 
Procedure OnDefineSelectionParameters(Form, SettingProperties) Export
	AvailableValues = CommonClientServer.StructureProperty(
		SettingsComposer.Settings.AdditionalProperties, "AvailableValues", New Structure);
	
	Try
		ValuesForSelection = CommonClientServer.StructureProperty(
			AvailableValues, StrReplace(SettingProperties.DCField, "DataParameters.", ""));
	Except
		ValuesForSelection = Undefined;
	EndTry;
	
	If ValuesForSelection <> Undefined Then 
		SettingProperties.RestrictSelectionBySpecifiedValues = True;
		SettingProperties.ValuesForSelection = ValuesForSelection;
	EndIf;
EndProcedure

// This procedure is called in the OnLoadVariantAtServer event handler of a report form after executing the form code.
// See "Managed form extension for reports.BeforeLoadOptionAtServer" in Syntax Assistant.
//
// Parameters:
//   Form - ManagedForm - a report form.
//   Settings - DataCompositionSettings - settings to import into the settings composer.
//
Procedure BeforeLoadVariantAtServer(Form, Settings) Export
	CurrentSchemaKey = Undefined;
	Schema = Undefined;
	
	IsImportedSchema = False;
	
	If TypeOf(Settings) = Type("DataCompositionSettings") Or Settings = Undefined Then
		If Settings = Undefined Then
			AdditionalSettingsProperties = SettingsComposer.Settings.AdditionalProperties;
		Else
			AdditionalSettingsProperties = Settings.AdditionalProperties;
		EndIf;
		
		If Form.ReportFormType = ReportFormType.Main
			AND (Form.DetailsMode
			Or (Form.CurrentVariantKey <> "Main"
			AND Form.CurrentVariantKey <> "Main")) Then 
			
			AdditionalSettingsProperties.Insert("ReportInitialized", True);
		EndIf;
		
		SchemaBinaryData = CommonClientServer.StructureProperty(
			AdditionalSettingsProperties, "DataCompositionSchema");
		
		If TypeOf(SchemaBinaryData) = Type("BinaryData") Then
			IsImportedSchema = True;
			CurrentSchemaKey = BinaryDataHash(SchemaBinaryData);
			Schema = Reports.UniversalReport.ExtractSchemaFromBinaryData(SchemaBinaryData);
		EndIf;
	EndIf;
	
	If IsImportedSchema Then
		SchemaKey = CurrentSchemaKey;
		ReportsServer.AttachSchema(ThisObject, Form, Schema, SchemaKey);
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
//       It is used for optimization to reinitialize the composer as rarely as possible).
//       It is possible not to use it if the initialization is running unconditionally.
//   OptionKey - String, Undefined - 
//       predefined report option name or UUID of a custom one.
//       Undefined when called for a details option or without context.
//   Settings - DataCompositionSettings, Undefined -
//       Settings for the report option that will be imported into the settings composer after it is initialized.
//       Undefined when option settings do not need to be imported (already imported earlier).
//   UserSettings - DataCompositionUserSettings, Undefined -
//       User settings that will be imported into the settings composer after it is initialized.
//       Undefined when user settings do not need to be imported (already imported earlier).
//
// Example:
//  // The report composer is initialized based on the schema from common templates:
//	If SchemaKey <> "1" Then
//		SchemaKey = "1";
//		DCSchema = GetCommonTemplate("MyCommonCompositionSchema");
//		ReportsServer.EnableSchema(ThisObject, Context, DCSchema, SchemaKey);
//	EndIf;
//
//  // The schema depends on the parameter value that is displayed in the report user settings:
//	If ValueType(NewDCSettings) = Type("DataCompositionUserSettings") Then
//		MetadataObjectName = "";
//		For Each DCItem From NewDCUserSettings.Items Loop
//			If ValueType(DCItem) = Type("DataCompositionSettingsParameterValue") Then
//				ParameterName = String(DCItem.Parameter);
//				If ParameterName = "MetadataObject" Then
//					MetadataObjectName = DCItem.Value;
//				EndIf;
//			EndIf;
//		EndDo;
//		If SchemaKey <> MetadataObjectName Then
//			SchemaKey = MetadataObjectName;
//			DCSchema = New DataCompositionSchema;
//			// Filling the schema...
//			ReportsServer.EnableSchema(ThisObject, Context, DCSchema, SchemaKey);
//		EndIf;
//	EndIf;
//
Procedure BeforeImportSettingsToComposer(Context, SchemaKey, OptionKey, Settings, UserSettings) Export
	CurrentSchemaKey = Undefined;
	
	If Settings = Undefined Then 
		Settings = SettingsComposer.Settings;
	EndIf;
	
	IsImportedSchema = False;
	SchemaBinaryData = CommonClientServer.StructureProperty(
		Settings.AdditionalProperties, "DataCompositionSchema");
	
	If TypeOf(SchemaBinaryData) = Type("BinaryData") Then
		CurrentSchemaKey = BinaryDataHash(SchemaBinaryData);
		If CurrentSchemaKey <> SchemaKey Then
			Schema = Reports.UniversalReport.ExtractSchemaFromBinaryData(SchemaBinaryData);
			IsImportedSchema = True;
		EndIf;
	EndIf;
	
	AvailableValues = Undefined;
	FixedParameters = Reports.UniversalReport.FixedParameters(
		Settings, UserSettings, AvailableValues);
	
	If CurrentSchemaKey = Undefined Then 
		CurrentSchemaKey = FixedParameters.MetadataObjectType
			+ "/" + FixedParameters.MetadataObjectName
			+ "/" + FixedParameters.TableName;
		CurrentSchemaKey = Common.TrimStringUsingChecksum(CurrentSchemaKey, 100);
		
		If CurrentSchemaKey <> SchemaKey Then
			SchemaKey = "";
			Schema = Reports.UniversalReport.DataCompositionSchema(FixedParameters);
		EndIf;
	EndIf;
	
	If CurrentSchemaKey <> Undefined AND CurrentSchemaKey <> SchemaKey Then
		SchemaKey = CurrentSchemaKey;
		ReportsServer.AttachSchema(ThisObject, Context, Schema, SchemaKey);
		
		If IsImportedSchema Then
			Reports.UniversalReport.SetStandardImportedSchemaSettings(
				ThisObject, SchemaBinaryData, Settings, UserSettings);
		Else
			Reports.UniversalReport.CustomizeStandardSettings(
				ThisObject, FixedParameters, Settings, UserSettings);
		EndIf;
		
		If TypeOf(Context) = Type("ManagedForm") Then
			// Call an overridable module.
			ReportsOverridable.BeforeLoadVariantAtServer(Context, Settings);
			BeforeLoadVariantAtServer(Context, Settings);
		EndIf;
	Else
		Reports.UniversalReport.SetFixedParameters(
			ThisObject, FixedParameters, Settings, UserSettings);
	EndIf;
	
	SettingsComposer.Settings.AdditionalProperties.Insert("AvailableValues", AvailableValues);
EndProcedure

// It is called after defining form item properties connected to user settings.
// See ReportsServer.SettingsFormItemsProperties() 
// It allows to override properties for report personalization purposes.
//
// Parameters:
//  FormType - ReportFormType - see Syntax Assistant. 
//  ItemsProperties - Structure - see ReportsServer.SettingsFormItemsProperties(). 
//  UserSettings - DataCompositionUserSettingsItemCollection - items of current user settings that 
//                              affect the creation of linked form items.
//
Procedure OnDefineSettingsFormItemsProperties(FormType, ItemsProperties, UserSettings) Export 
	If FormType <> ReportFormType.Main Then 
		Return;
	EndIf;
	
	GroupProperties = ReportsServer.FormItemsGroupProperties();
	GroupProperties.Group = ChildFormItemsGroup.AlwaysHorizontal;
	ItemsProperties.Folders.Insert("FixedParameters", GroupProperties);
	
	FixedParameters = New Structure("Period, MetadataObjectType, MetadataObjectName, TableName");
	FieldWidth = New Structure("MetadataObjectType, MetadataObjectName, TableName", 20, 35, 20);
	
	For Each SettingItem In UserSettings Do 
		If TypeOf(SettingItem) <> Type("DataCompositionSettingsParameterValue")
			Or Not FixedParameters.Property(SettingItem.Parameter) Then 
			Continue;
		EndIf;
		
		FieldProperties = ItemsProperties.Fields.Find(
			SettingItem.UserSettingID, "SettingID");
		
		If FieldProperties = Undefined Then 
			Continue;
		EndIf;
		
		FieldProperties.GroupID = "FixedParameters";
		
		ParameterName = String(SettingItem.Parameter);
		If ParameterName <> "Period" Then 
			FieldProperties.TitleLocation = FormItemTitleLocation.None;
			FieldProperties.Width = FieldWidth[ParameterName];
			FieldProperties.HorizontalStretch = False;
		EndIf;
	EndDo;
EndProcedure

// End StandardSubsystems.ReportsOptions

#EndRegion

#EndRegion

#Region Private

// Returns binary data hash.
//
// Parameters:
//   BinaryData - BinaryData - data, from which hash is calculated.
//
Function BinaryDataHash(BinaryData)
	DataHashing = New DataHashing(HashFunction.MD5);
	DataHashing.Append(BinaryData);
	Return StrReplace(DataHashing.HashSum, " ", "") + "_" + Format(BinaryData.Size(), "NG=");
EndFunction

#EndRegion

#Else
Raise NStr("ru = 'Недопустимый вызов объекта на клиенте.'; en = 'Invalid object call on the client.'; pl = 'Niedozwolone wezwanie obiektu na kliencie.';de = 'Unzulässiger Objektaufruf auf dem Client.';ro = 'Apel inadmisibil al obiectului pe client.';tr = 'İstemcide kabul edilmeyen nesne çağrısı.'; es_ES = 'Llamada no disponible del objeto en el cliente.'");
#EndIf