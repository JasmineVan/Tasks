///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Public

// Additional settings of a default report that determine:
//  * Indicates whether the report is generated upon opening.
//  * Attachable event handlers.
//  * Print settings.
//  * Using the estimates function.
//  * Rights.
//
// Returns:
//   Structure - report settings (additional properties) that are stored in the form data:
//       
//       * GenerateImmediately - Boolean - the default value for the "Generate immediately" check box.
//           When the check box is selected, the report will be generated after opening, after 
//           selecting user settings and selecting another report option.
//       
//       * OutputSelectedCellTotal - Boolean - If True, the report will contain the autosum field.
//       
//       * EditStructureAllowed - Boolean - if False, the Structure tab will be hidden in the report settings.
//           If True, the Structure tab is shown for reports on DSC: in the extended mode, but also 
//           in the simple mode, if flags of using groups are output in user settings.
//       
//       * EditOptionsAllowed - Boolean - if False, buttons of changing options of this report are locked.
//           If the current user does not have the SaveUserData and Add rights
//           of the ReportsOptions directory, it is forcefully set to False.
//
//       * SelectAndEditOptionsWithoutSavingAllowed - Boolean - if True, you can select and set up 
//           predefined report options without being able to save settings you made.
//            For example, it can be specified for context reports (open with parameters) that have 
//           several options.
//
//       * ControlItemsLocationParameters - Structure, Undefined - options:
//           - Undefined - default parameters of common report form controls.
//           - Structure - with setting names in the DataCompositionSettings collection of the 
//                         settings Property of DataCompositionSettingsComposer type:
//               ** Filter           - Array - the same as the next property has.
//               ** DataParameters - Structure - with the form field properties:
//                    *** Field                     - String - field name whose presentation is being set.
//                    *** HorizontalStretch - Boolean - form field property value.
//                    *** AutoMaxWidth   - Boolean - form field property value.
//                    *** Width                   - Boolean - form field property value.
//
//            An example of determining the described parameter:
//
//               SettingsArray              = New Array;
//               ControlItemSettings = New Structure;
//               ControlItemSettings.Insert("Field",                     "RegistersList");
//               ControlItemSettings.Insert("HorizontalStretch", False);
//               ControlItemSettings.Insert("AutoMaxWidth",   True);
//               ControlItemSettings.Insert("Width",                   40);
//
//               SettingsArray.Add(ControlItemSettings);
//
//               ControlItemsSettings = New Structure();
//               ControlItemsSettings.Insert("DataParameters", SettingsArray);
//
//               Return ControlItemsSettings;
//
//       * LoadSettingsOnChangeParameters - Array - a collection of data composition parameters 
//                                                    whose changing leads to regenerating.
//                                                    Data composition schemas.
//
//               // Example:
//               // 1. Initialization:
//               //	Procedure DefineFormSettings(Form, OptionKey, Settings) Export
//               //		Settings.LoadSettingsOnChangeParameters = Reports.UniversalReport.LoadSettingsOnChangeParameters().
//               //	EndProcedure
//
//               //	 Function LoadSettingsOnChangeParameters() Export
//               //		Parameters = New Array.
//               //		Parameters.Add(New DataCompositionParameter("MetadataObjectType")).
//               //		Parameters.Add(New DataCompositionParameter("MetadataObjectName")).
//               //		Parameters.Add(New DataCompositionParameter("TableName")).
//               //		
//               //		Return Parameters;
//               //	EndFunction
//
//               // 2. Use:
//               //	Procedure Attachable_SettingItem_OnChange(Item)
//               //		...
//               //		If ValueType(UserSettingItem) = Type("DataCompositionSettingsParameterValue")
//               //			And ReportSettings.LoadSettingsOnChangeParameters.Find(UserSettingItem.Parameter) <> Undefined Then
//               //			// Calling the method to regenerate data composition schema...
//               //		EndIf;
//
//       * HideBulkEmailCommands - Boolean - a check box that allows to hide bulk email commands to 
//           those reports, for which bulk email does not make sense.
//           True              - bulk email commands will be hidden,
//           False (default) - commands will be available.
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
//               //   Cancel - Boolean - indicates that form creation was canceled.
//               //      See details of the parameter with the same name ManagedForm.OnCreateAtServer in Syntax Assistant.
//               //   StandardProcessing - Boolean - indicates that the standard (system) event processing is completed.
//               //      See details of the parameter with the same name ManagedForm.OnCreateAtServer in Syntax Assistant.
//               //
//               // See also:
//               //   The procedure of outputting the added commands to the ReportsServer.OutputCommand() form.
//               //   Global handler of this event: ReportsOverridable.OnCreateAtServer().
//               //
//               // An example of adding a command:
//               //	Command = Form.Commands.Add("<CommandName>");
//               //	Command.Action  = "Attachable_Command";
//               //	Command.Header = NStr("en = '<Command presentation...>'");
//               //	ReportsServer.OutputCommand(Form, Command, "<Compositor>");
//               // Command handler is written in the ReportsClientOverridable.CommandHandler procedure.
//               //
//               Procedure OnCreateAtServer(Form, Cancel, StandardProcessing) Export
//               	// Handling an event.
//               EndProcedure
//           
//           ** BeforeImportSettingsToComposer  - Boolean - if True, the event handler must be 
//               defined in the report object module using the following template:
//               
//               // Called before importing new settings. Used to change composition schema.
//               //   For example, if the report schema depends on the option key or the report parameters.
//               //   For the schema changes to take effect, call the ReportsServer.EnableSchema() method.
//               //
//               // Parameters:
//               //   Context - Arbitrary -
//               //       The context parameters where the report is used.
//               //       Used to pass the ReportsServer.EnableSchema() method in the parameters.
//               //   SchemaKey - String -
//               //       The ID of the setting composer current schema.
//               //       It is not filled in by default (that means, the composer is initialized based on the main schema).
//               //       It is used for optimization to reinitialize the composer as rarely as possible.
//               //       It is possible not to use it if the initialization is running unconditionally.
//               //   OptionKey - String, Undefined -
//               //       The predefined report option name or UUID of a custom one.
//               //       Undefined when called for a details option or without context.
//               //   NewDCSettings - DataCompositionSettings, Undefined -
//               //       Settings for the report option that will be imported into the settings composer after it is initialized.
//               //       Undefined when option settings do not need to be imported (already imported earlier).
//               //   NewDataCompositionUserSettings - DataCompositionUserSettings, Undefined -
//               //       User settings that will be imported into the settings composer after it is initialized.
//               //       Undefined when user settings do not need to be imported (already imported earlier).
//               //
//               // Examples:
//               // 1. The report composer is initialized based on the schema from common templates:
//               //	If SchemaKey <> "1" Then
//               //		SchemaKey = "1";
//               //		DSChema = GetCommonTemplate("MyCommonCompositionSchema");
//               //		ReportsServer.EnableSchema(ThisObject, Context, DCSchema, SchemaKey);
//               //	EndIf;
//               //
//               // 2. The schema depends on the parameter value that is displayed in the report user settings:
//               //	If TypeOf(NewDataCompositionUserSettings) = Type("DataCompositionUserSettings") Then
//               //		FullMetadataObjectName = "";
//               //		For Each DCItem From NewDataCompositionUserSettings.Items Loop
//               //		\If TypeOf(DCItem) = Type("DataCompositionSettingsParameterValue") Then
//               //				ParameterName = String(DCItem.Parameter);
//               //				If ParameterName = MetadataObject Then
//               //					FullMetadataObjectName = DCItem.Value;
//               //				EndIf;
//               //			EndIf;
//               //		EndDo;
//               //		If SchemaKey <> FullMetadataObjectName Then
//               //			SchemaKey = FullMetadataObjectName;
//               //			DCSchema = New DataCompositionSchema;
//               //			// Filling schema...
//               //			ReportsServer.EnableSchema(ThisObject, Context, DCSchema, SchemaKey);
//               //		EndIf;
//               //	EndIf;
//               //
//               Procedure BeforeImportSettingsToComposer(Context, SchemaKey, OptionKey, NewDCSettings, NewDataCompositionUserSettings) Export
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
//               // See ReportsOverridable.BeforeLoadOptionAtServer(). 
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
//               // See "Managed form extension for reports.OnLoadOptionAtServer" Syntax Assistant in Syntax Assistant.
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
//               // See "Managed form extension for reports.OnLoadUserSettingsAtServer" Syntax Assistant
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
//           ** OnDefineChoiceParameters - Boolean - if True, then the event handler must be defined 
//               in the report object module according to the following template:
//               
//               // The procedure is called in the report form before outputting the setting.
//               //
//               // Parameters:
//               //   Form - ManagedForm, Undefined - a report form.
//               //   SettingProperties - Structure - a description of report setting that will be output as a report form.
//               //       * TypesDetails - TypesDetails - a setting type.
//               //       * ValuesForSelection - ValueList - objects that will be offered to a user 
//                          in the choice list. The parameter adds items to the list of objects previously selected by a user.
//               //       * SelectionValuesQuery - Query - returns objects to complement ValuesForSelection.
//               //           As the first column (with 0m index) select the object,
//               //          that has to be added to the ValuesForSelection.Value.
//               //           To disable autofill
//               //          write a blank string to the  SelectionValuesQuery.Text property.
//               //       * RestrictSelectionBySpecifiedValues - Boolean - when it is True, user choice will be
//               //           restricted by values specified in ValuesForSelection (its final status).
//               //
//               // See also:
//               //   ReportsOverridable.OnDefineChoiceParameters().
//               //
//               Procedure OnDefineChoiceParameters(Form, SettingProperties) Export
//               	// Handling an event.
//               EndProcedure
//           
//           ** OnDefineUsedTables - Boolean - if True, then the event handler must be defined in 
//               the report object module according to the following template:
//               
//               // A list of registers and other metadata objects, by which report is generated.
//               //   It is used to check if the report can contain non-updated data.
//               //
//               // Parameters:
//               //   OptionKey - String, Undefined -
//               //       The predefined report option name or UUID of a custom one.
//               //       Undefined when called for a details option or without context.
//               //   UsedTables - Array from String -
//               //       Full metadata object names (registers, documents, and other tables),
//               //       whose data is displayed in the report.
//               //
//               // Example:
//               //	UsedTables.Add(Metadata.Documents.<DocumentName>.FullName());
//               //
//               Procedure OnDefineUsedTables(OptionKey, UsedTables) Export
//               	// Handling an event.
//               EndProcedure
//           
//           ** AddMetadataObjectsLinks - Boolean - if True, then the event handler must be defined 
//               in the report object module according to the following template:
//               
//               // Additional links of the report settings.
//               // In this procedure, describe additional dependencies of configuration metadata objects
//               //   that will be used to connect report settings.
//               //
//               // Parameters:
//               //   MetadataObjectsLinks - ValueTable - a links table.
//               //       * SubordinateAttribute - String - an attribute name of a subordinate metadata object.
//               //       * SubordinateType      - Type    - a subordinate metadata object type.
//               //       * MasterType          - Type    - a leading metadata object type.
//               //
//               // See also:
//               //   ReportsOverridable.SupplementMetadateObjectsConnections().
//               //
//               Procedure SupplementMetadateObjectsConnections(MetadataObjectsLinks) Export
//               	// Handling an event.
//               EndProcedure
//
Function DefaultReportSettings() Export
	Settings = New Structure;
	Settings.Insert("GenerateImmediately", False);
	Settings.Insert("OutputSelectedCellsTotal", True);
	Settings.Insert("EditStructureAllowed", True);
	Settings.Insert("EditOptionsAllowed", True);
	Settings.Insert("SelectAndEditOptionsWithoutSavingAllowed", False);
	Settings.Insert("ControlItemsPlacementParameters", Undefined);
	Settings.Insert("HideBulkEmailCommands", False);
	Settings.Insert("ImportSchemaAllowed", False);
	Settings.Insert("EditSchemaAllowed", False);
	Settings.Insert("RestoreStandardSchemaAllowed", False);
	Settings.Insert("ImportSettingsOnChangeParameters", New Array);
	
	Print = New Structure;
	Print.Insert("TopMargin", 10);
	Print.Insert("LeftMargin", 10);
	Print.Insert("BottomMargin", 10);
	Print.Insert("RightMargin", 10);
	Print.Insert("PageOrientation", PageOrientation.Portrait);
	Print.Insert("FitToPage", True);
	Print.Insert("PrintScale", Undefined);
	
	Settings.Insert("Print", Print);
	
	Events = New Structure;
	Events.Insert("OnCreateAtServer", False);
	Events.Insert("BeforeImportSettingsToComposer", False);
	Events.Insert("BeforeLoadVariantAtServer", False);
	Events.Insert("OnLoadVariantAtServer", False);
	Events.Insert("OnLoadUserSettingsAtServer", False);
	Events.Insert("BeforeFillQuickSettingsPanel", False);
	Events.Insert("AfterQuickSettingsBarFilled", False);
	Events.Insert("OnDefineSelectionParameters", False);
	Events.Insert("OnDefineUsedTables", False);
	Events.Insert("AddMetadataObjectsConnections", False);
	Events.Insert("OnDefineSettingsFormItemsProperties", False);
	
	Settings.Insert("Events", Events);
	
	Return Settings;
EndFunction

#Region ObsoleteProceduresAndFunctions

// Obsolete. Please use ReportsClientServer.DefaultReportSettings.
// Default report form settings
//
// Returns:
//   Structure - report form settings:
//
Function GetDefaultReportSettings() Export
	Return DefaultReportSettings();
EndFunction

#EndRegion

#EndRegion

#Region Internal

// It finds a parameter in the composition settings by its name.
//   If user setting is not found (for example, if the parameter is not output in user settings), it 
//   searches the parameter value in option settings.
//   
//
// Parameters:
//   DCSettings - DataCompositionSettings, Undefined -
//       Report option settings where the second iteration of value search will be executed.
//   DCUserSettings - DataCompositionUserSettings, Undefined -
//       User settings where the first iteration of value search will be executed.
//   ParameterName - String - a parameter name. It must meet the requirements of generating variable names.
//
// Returns:
//   Structure - found parameter values.
//       Key - a parameter name;
//       Value - a parameter value. Undefined if a parameter is not found.
//
Function FindParameter(DCSettings, DCUserSettings, ParameterName) Export
	Return FindParameters(DCSettings, DCUserSettings, ParameterName)[ParameterName];
EndFunction

// It finds a common setting by a user setting ID.
//
// Parameters:
//   Settings - DataCompositionSettings - collections of settings.
//   ID - String - a user setting ID.
//   Hierarchy - Array - a collection of data composition structure settings.
//   UserSettings - DataCompositionUserSettings - a collection of user settings.
//
Function GetObjectByUserID(Settings, ID, Hierarchy = Undefined, UserSettings = Undefined) Export
	If UserSettings <> Undefined
		AND SearchSettingByIDAvailable() Then 
		
		FoundItems =
			UserSettings.GetMainSettingsByUserSettingID(ID);
		
		If FoundItems.Count() > 0 Then 
			Return FoundItems[0];
		EndIf;
	EndIf;
	
	If Hierarchy <> Undefined Then
		Hierarchy.Add(Settings);
	EndIf;
	
	SettingType = TypeOf(Settings);
	
	If SettingType <> Type("DataCompositionSettings") Then
		
		If Settings.UserSettingID = ID Then
			
			Return Settings;
			
		ElsIf SettingType = Type("DataCompositionNestedObjectSettings") Then
			
			Return GetObjectByUserID(Settings.Settings, ID, Hierarchy);
			
		ElsIf SettingType = Type("DataCompositionTableStructureItemCollection")
			OR SettingType = Type("DataCompositionChartStructureItemCollection")
			OR SettingType = Type("DataCompositionSettingStructureItemCollection") Then
			
			For Each NestedItem In Settings Do
				SearchResult = GetObjectByUserID(NestedItem, ID, Hierarchy);
				If SearchResult <> Undefined Then
					Return SearchResult;
				EndIf;
			EndDo;
			
			If Hierarchy <> Undefined Then
				Hierarchy.Delete(Hierarchy.UBound());
			EndIf;
			
			Return Undefined;
			
		EndIf;
		
	EndIf;
	
	If Settings.Selection.UserSettingID = ID Then
		Return Settings.Selection;
	ElsIf Settings.ConditionalAppearance.UserSettingID = ID Then
		Return Settings.ConditionalAppearance;
	EndIf;
	
	If SettingType <> Type("DataCompositionTable") AND SettingType <> Type("DataCompositionChart") Then
		If Settings.Filter.UserSettingID = ID Then
			Return Settings.Filter;
		ElsIf Settings.Order.UserSettingID = ID Then
			Return Settings.Order;
		EndIf;
	EndIf;
	
	If SettingType = Type("DataCompositionSettings") Then
		SearchResult = FindSettingItem(Settings.DataParameters, ID);
		If SearchResult <> Undefined Then
			Return SearchResult;
		EndIf;
	EndIf;
	
	If SettingType <> Type("DataCompositionTable") AND SettingType <> Type("DataCompositionChart") Then
		SearchResult = FindSettingItem(Settings.Filter, ID);
		If SearchResult <> Undefined Then
			Return SearchResult;
		EndIf;
	EndIf;
	
	SearchResult = FindSettingItem(Settings.ConditionalAppearance, ID);
	If SearchResult <> Undefined Then
		Return SearchResult;
	EndIf;
	
	If SettingType = Type("DataCompositionTable") Then
		
		SearchResult = GetObjectByUserID(Settings.Rows, ID, Hierarchy);
		If SearchResult <> Undefined Then
			Return SearchResult;
		EndIf;
		
		SearchResult = GetObjectByUserID(Settings.Columns, ID, Hierarchy);
		If SearchResult <> Undefined Then
			Return SearchResult;
		EndIf;
		
	ElsIf SettingType = Type("DataCompositionChart") Then
		
		SearchResult = GetObjectByUserID(Settings.Points, ID, Hierarchy);
		If SearchResult <> Undefined Then
			Return SearchResult;
		EndIf;
		
		SearchResult = GetObjectByUserID(Settings.Series, ID, Hierarchy);
		If SearchResult <> Undefined Then
			Return SearchResult;
		EndIf;
		
	Else
		
		SearchResult = GetObjectByUserID(Settings.Structure, ID, Hierarchy);
		If SearchResult <> Undefined Then
			Return SearchResult;
		EndIf;
		
	EndIf;
	
	If Hierarchy <> Undefined Then
		Hierarchy.Delete(Hierarchy.UBound());
	EndIf;
	
	Return Undefined;
EndFunction

// Finds an available setting for a filter or a parameter.
//
// Parameters:
//   DCSettings - DataCompositionSettings - Collections of settings.
//   DCItem - DataCompositionFilterItem, DataCompositionSettingsParameterValue,
//       DataCompositionNestedObjectSettings - setting item value.
//
// Returns:
//   DataCompositionAvailableField, DataCompositionAvailableParameter,
//       DataCompositionAvailableSettingsObject - found available setting.
//   Undefined - if an available setting is not found.
//
Function FindAvailableSetting(DCSettings, DCItem) Export
	Type = TypeOf(DCItem);
	If Type = Type("DataCompositionFilterItem") Then
		Return FindAvailableDCField(DCSettings, DCItem.LeftValue);
	ElsIf Type = Type("DataCompositionSettingsParameterValue") Then
		Return FindAvailableDCParameter(DCSettings, DCItem.Parameter);
	ElsIf Type = Type("DataCompositionNestedObjectSettings") Then
		Return DCSettings.AvailableObjects.Items.Find(DCItem.ObjectID);
	EndIf;
	
	Return Undefined;
EndFunction

// Finds parameters and filters by values.
//
// Parameters:
//   DCSettingsComposer - DataCompositionSettingsComposer - settings composer.
//   Filter              - Structure - search criteria.
//       * Usage - Boolean - setting usage.
//       * Value      - *      - setting value.
//   Result           - Array, Undefined - see return value.
//
// Returns:
//   Array - found user settings.
//
Function FindSettings(DCSettingsCollection, Filter, Result = Undefined) Export
	If Result = Undefined Then
		Result = New Array;
	EndIf;
	
	For Each DCSetting In DCSettingsCollection Do
		If TypeOf(DCSetting) = Type("DataCompositionFilterItem") 
			AND DCSetting.Use = Filter.Use
			AND DCSetting.RightValue = Filter.Value Then
			Result.Add(DCSetting);
		ElsIf TypeOf(DCSetting) = Type("DataCompositionSettingsParameterValue") 
			AND DCSetting.Use = Filter.Use
			AND DCSetting.Value = Filter.Value Then
			Result.Add(DCSetting);
		ElsIf TypeOf(DCSetting) = Type("DataCompositionFilter")
			Or TypeOf(DCSetting) = Type("DataCompositionFilterItemGroup") Then
			FindSettings(DCSetting.Items, Filter, Result);
		EndIf;
	EndDo;
	
	Return Result;
EndFunction

Function SettingItemIndexByPath(Val Path, ItemProperty = Undefined) Export 
	AvailableProperties = StrSplit("Use, Value, List", ", ", False);
	For Each ItemProperty In AvailableProperties Do 
		If StrEndsWith(Path, ItemProperty) Then 
			Break;
		EndIf;
	EndDo;
	
	IndexDetails = New TypeDescription("Number");
	
	ItemIndex = StrReplace(Path, "SettingsComposerUserSettingsItem", "");
	ItemIndex = StrReplace(ItemIndex, ItemProperty, "");
	
	Return IndexDetails.AdjustValue(ItemIndex);
EndFunction

#EndRegion

#Region Private

// Finds parameters in the composition settings by its name.
//   If a parameter is not found in user settings, it is searched in option settings.
//   
//
// Parameters:
//   DCSettings - DataCompositionSettings, Undefined -
//       Report option settings where the second iteration of value search will be executed.
//   DCUserSettings - DataCompositionUserSettings, Undefined -
//       User settings where the first iteration of value search will be executed.
//   ParameterNames - String - parameter names separated with commas.
//       Every parameter name must meet the requirements of variable name formation.
//
// Returns:
//   Structure - found parameter values.
//       Key - a parameter name;
//       Value - the found parameter. Undefined if a parameter is not found.
//
Function FindParameters(DCSettings, DCUserSettings, ParametersNames)
	Result = New Structure;
	RequiredParameters = New Map;
	NamesArray = StrSplit(ParametersNames, ",", False);
	Count = 0;
	For Each ParameterName In NamesArray Do
		RequiredParameters.Insert(TrimAll(ParameterName), True);
		Count = Count + 1;
	EndDo;
	
	If DCUserSettings <> Undefined Then
		For Each DCItem In DCUserSettings.Items Do
			If TypeOf(DCItem) = Type("DataCompositionSettingsParameterValue") Then
				ParameterName = String(DCItem.Parameter);
				If RequiredParameters[ParameterName] = True Then
					Result.Insert(ParameterName, DCItem);
					RequiredParameters.Delete(ParameterName);
					Count = Count - 1;
					If Count = 0 Then
						Break;
					EndIf;
				EndIf;
			EndIf;
		EndDo;
	EndIf;
	
	If Count > 0 Then
		For Each KeyAndValue In RequiredParameters Do
			If DCSettings <> Undefined Then
				DCItem = DCSettings.DataParameters.Items.Find(KeyAndValue.Key);
			Else
				DCItem = Undefined;
			EndIf;
			Result.Insert(KeyAndValue.Key, DCItem);
		EndDo;
	EndIf;
	
	Return Result;
EndFunction

// Finds an available data composition field setting.
//
// Parameters:
//   DCSettings - DataCompositionSettings, DataCompositionGroup - collections of settings.
//   Field - String, DataCompositionField - a field name.
//
// Returns:
//   Undefined - When the available field setting is not found.
//   DataCompositionAvailableField - an available setting for a field.
//
Function FindAvailableDCField(DCSettings, DCField)
	If DCField = Undefined Then
		Return Undefined;
	EndIf;
	
	If TypeOf(DCSettings) = Type("DataCompositionGroup")
		Or TypeOf(DCSettings) = Type("DataCompositionTableGroup")
		Or TypeOf(DCSettings) = Type("DataCompositionChartGroup") Then
		
		AvailableSetting = DCSettings.Filter.FilterAvailableFields.FindField(DCField);
	Else
		AvailableSetting = DCSettings.FilterAvailableFields.FindField(DCField);
	EndIf;
	
	If AvailableSetting <> Undefined Then
		Return AvailableSetting;
	EndIf;
	
	StructuresArray = New Array;
	StructuresArray.Add(DCSettings.Structure);
	While StructuresArray.Count() > 0 Do
		
		DCStructure = StructuresArray[0];
		StructuresArray.Delete(0);
		
		For Each DCStructureItem In DCStructure Do
			
			If TypeOf(DCStructureItem) = Type("DataCompositionNestedObjectSettings") Then
				
				AvailableSetting = DCStructureItem.Settings.FilterAvailableFields.FindField(DCField);
				If AvailableSetting <> Undefined Then
					Return AvailableSetting;
				EndIf;
				
				StructuresArray.Add(DCStructureItem.Settings.Structure);
				
			ElsIf TypeOf(DCStructureItem) = Type("DataCompositionGroup") Then
				
				AvailableSetting = DCStructureItem.Filter.FilterAvailableFields.FindField(DCField);
				If AvailableSetting <> Undefined Then
					Return AvailableSetting;
				EndIf;
				
				StructuresArray.Add(DCStructureItem.Structure);
				
			EndIf;
			
		EndDo;
		
	EndDo;
	
	Return Undefined;
EndFunction

// Finds an available data composition parameter setting.
//
// Parameters:
//   DCSettings - DataCompositionSettings - Collections of settings.
//   DCParameter - DataCompositionParameter - a parameter name.
//
// Returns:
//   AvailableDataCompositionParameter, Undefined - available setting for a parameter.
//
Function FindAvailableDCParameter(DCSettings, DCParameter)
	If DCParameter = Undefined Then
		Return Undefined;
	EndIf;
	
	If DCSettings.DataParameters.AvailableParameters <> Undefined Then
		// Settings that own the data parameters are connected to the source of the available settings.
		AvailableSetting = DCSettings.DataParameters.AvailableParameters.FindParameter(DCParameter);
		If AvailableSetting <> Undefined Then
			Return AvailableSetting;
		EndIf;
	EndIf;
	
	StructuresArray = New Array;
	StructuresArray.Add(DCSettings.Structure);
	While StructuresArray.Count() > 0 Do
		
		DCStructure = StructuresArray[0];
		StructuresArray.Delete(0);
		
		For Each DCStructureItem In DCStructure Do
			
			If TypeOf(DCStructureItem) = Type("DataCompositionNestedObjectSettings") Then
				
				If DCStructureItem.Settings.DataParameters.AvailableParameters <> Undefined Then
					// Settings that own the data parameters are connected to the source of the available settings.
					AvailableSetting = DCStructureItem.Settings.DataParameters.AvailableParameters.FindParameter(DCParameter);
					If AvailableSetting <> Undefined Then
						Return AvailableSetting;
					EndIf;
				EndIf;
				
				StructuresArray.Add(DCStructureItem.Settings.Structure);
				
			ElsIf TypeOf(DCStructureItem) = Type("DataCompositionGroup") Then
				
				StructuresArray.Add(DCStructureItem.Structure);
				
			EndIf;
			
		EndDo;
		
	EndDo;
	
	Return Undefined;
EndFunction

// Defines the FoldersAndItems type value depending on the comparison kind (preferably) or the source value.
//
// Parameters:
//  Condition - DataCompositionComparisonType, Undefined - current comparison kind value. 
//  SourceValue - FoldersAndItemsUse, FoldersAndItems - the current value of the
//                     ChoiceOfGroupsAndItems property.
//
// Returns:
//   GroupsAndItems - GroupsAndItems enumeration value.
//
Function GroupsAndItemsTypeValue(SourceValue, Condition = Undefined) Export
	If Condition <> Undefined Then 
		If Condition = DataCompositionComparisonType.InListByHierarchy
			Or Condition = DataCompositionComparisonType.NotInListByHierarchy Then 
			If SourceValue = FoldersAndItems.Folders
				Or SourceValue = FoldersAndItemsUse.Folders Then 
				Return FoldersAndItems.Folders;
			Else
				Return FoldersAndItems.FoldersAndItems;
			EndIf;
		ElsIf Condition = DataCompositionComparisonType.InHierarchy
			Or Condition = DataCompositionComparisonType.NotInHierarchy Then 
			Return FoldersAndItems.Folders;
		EndIf;
	EndIf;
	
	If TypeOf(SourceValue) = Type("FoldersAndItems") Then 
		Return SourceValue;
	ElsIf SourceValue = FoldersAndItemsUse.Items Then
		Return FoldersAndItems.Items;
	ElsIf SourceValue = FoldersAndItemsUse.FoldersAndItems Then
		Return FoldersAndItems.FoldersAndItems;
	ElsIf SourceValue = FoldersAndItemsUse.Folders Then
		Return FoldersAndItems.Folders;
	EndIf;
	
	Return FoldersAndItems.Auto;
EndFunction

// Imports new settings to the composer without resetting user settings.
//
// Parameters:
//  SettingsComposer - DataCompositionSettingsComposer - the place to import settings to.
//  Settings - DataCompositionSettings - option settings to be imported.
//  UserSettings - DataCompositionUserSettings, Undefined - user settings to be imported.
//                              If it is not specified, user settings are not imported.
//  FixedSettings - DataCompositionSettings, Undefined - fixed settings to be imported.
//                           If it is not specified, fixed settings are not imported.
//
Function LoadSettings(SettingsComposer, Settings, UserSettings = Undefined, FixedSettings = Undefined) Export
	SettingsImported = (TypeOf(Settings) = Type("DataCompositionSettings")
		AND Settings <> SettingsComposer.Settings);
	
	If SettingsImported Then
		If TypeOf(UserSettings) <> Type("DataCompositionUserSettings") Then
			UserSettings = SettingsComposer.UserSettings;
		EndIf;
		
		If TypeOf(FixedSettings) <> Type("DataCompositionSettings") Then 
			FixedSettings = SettingsComposer.FixedSettings;
		EndIf;
		
		AvailableValues = CommonClientServer.StructureProperty(
			SettingsComposer.Settings.AdditionalProperties, "AvailableValues");
		
		If AvailableValues <> Undefined Then 
			Settings.AdditionalProperties.Insert("AvailableValues", AvailableValues);
		EndIf;
		
		SettingsComposer.LoadSettings(Settings);
	EndIf;
	
	If TypeOf(UserSettings) = Type("DataCompositionUserSettings")
		AND UserSettings <> SettingsComposer.UserSettings Then
		SettingsComposer.LoadUserSettings(UserSettings);
	EndIf;
	
	If TypeOf(FixedSettings) = Type("DataCompositionSettings")
		AND FixedSettings <> SettingsComposer.FixedSettings Then
		SettingsComposer.LoadFixedSettings(FixedSettings);
	EndIf;
	
	Return SettingsImported;
EndFunction

////////////////////////////////////////////////////////////////////////////////
// Local internal procedures and functions.

// Finds a common data composition setting by ID.
Function FindSettingItem(SettingItem, UserSettingID)
	// Searching an item with the specified value of the UserSettingID (USID) property.
	
	Groups = New Array;
	Groups.Add(SettingItem.Items);
	Index = 0;
	
	While Index < Groups.Count() Do
		
		ItemsCollection = Groups[Index];
		Index = Index + 1;
		For Each SubordinateItem In ItemsCollection Do
			If TypeOf(SubordinateItem) = Type("DataCompositionSelectedFieldGroup") Then
				// It does not contain USID; The collection of nested items does not contain USID.
			ElsIf TypeOf(SubordinateItem) = Type("DataCompositionParameterValue") Then
				// It does not contain USID; The collection of nested items can contain USID.
				Groups.Add(SubordinateItem.NestedParameterValues);
			ElsIf SubordinateItem.UserSettingID = UserSettingID Then
				// The required item is found.
				Return SubordinateItem;
			Else
				// It contains USID; The collection of nested items can contain USID.
				If TypeOf(SubordinateItem) = Type("DataCompositionFilterItemGroup") Then
					Groups.Add(SubordinateItem.Items);
				ElsIf TypeOf(SubordinateItem) = Type("DataCompositionSettingsParameterValue") Then
					Groups.Add(SubordinateItem.NestedParameterValues);
				EndIf;
			EndIf;
		EndDo;
		
	EndDo;
	
	Return Undefined;
EndFunction

Function ChoiceParameterValue(Settings, UserSettings, Field, OptionChangeMode)
	Value = DataParameterValueByField(Settings, UserSettings, Field, OptionChangeMode);
	
	If Value = Undefined Then 
		FilterItems = Settings.Filter.Items;
		FindFilterItemsFieldValues(Field, FilterItems, UserSettings, Value, OptionChangeMode);
	EndIf;
	
	Return Value;
EndFunction

Function DataParameterValueByField(Settings, UserSettings, Field, OptionChangeMode)
	If TypeOf(Settings) <> Type("DataCompositionSettings") Then 
		Return Undefined;
	EndIf;
	
	SettingsItems = Settings.DataParameters.Items;
	For Each Item In SettingsItems Do 
		UserItem = UserSettings.Find(Item.UserSettingID);
		ItemToAnalyse = ?(OptionChangeMode Or UserItem = Undefined, Item, UserItem);
		
		Fields = New Array;
		Fields.Add(New DataCompositionField(String(Item.Parameter)));
		Fields.Add(New DataCompositionField("DataParameters." + String(Item.Parameter)));
		
		If ItemToAnalyse.Use
			AND (Fields[0] = Field Or Fields[1] = Field)
			AND ValueIsFilled(ItemToAnalyse.Value)
			AND TypeOf(ItemToAnalyse.Value) <> Type("ValueList") Then 
			
			Return ItemToAnalyse.Value;
		EndIf;
	EndDo;
	
	Return Undefined;
EndFunction

Procedure FindFilterItemsFieldValues(Field, FilterItems, UserSettings, Value, OptionChangeMode)
	If ValueIsFilled(Value) Then 
		Return;
	EndIf;
	
	For Each Item In FilterItems Do 
		UserItem = UserSettings.Find(Item.UserSettingID);
		ItemToAnalyse = ?(OptionChangeMode Or UserItem = Undefined, Item, UserItem);
		
		If TypeOf(ItemToAnalyse) = Type("DataCompositionFilterItemGroup") Then 
			FindFilterItemsFieldValues(Field, Item.Items, UserSettings, Value, OptionChangeMode);
		Else
			If ItemToAnalyse.Use
				AND ItemToAnalyse.LeftValue = Field
				AND ItemToAnalyse.ComparisonType = DataCompositionComparisonType.Equal
				AND ValueIsFilled(ItemToAnalyse.RightValue) Then 
				
				Value = Item.RightValue;
				Break;
			EndIf;
		EndIf;
	EndDo;
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Unifying the report form and report setting form.

Function ConditionalAppearanceItemPresentation(DCItem, DCOptionSetting, State) Export
	AppearancePresentation = AppearancePresentation(DCItem.Appearance);
	If AppearancePresentation = "" Then
		AppearancePresentation = NStr("ru = 'Не оформлять'; en = 'No decoration'; pl = 'Nie twórz';de = 'Nicht erstellen';ro = 'Nu crea';tr = 'Oluşturma'; es_ES = 'No crear'");
	EndIf;
	InfoFromOptionIsAvailable = (DCOptionSetting <> Undefined AND DCOptionSetting <> DCItem);
	
	FieldsPresentation = FormattedFieldsPresentation(DCItem.Fields, State);
	If FieldsPresentation = "" AND InfoFromOptionIsAvailable Then
		FieldsPresentation = FormattedFieldsPresentation(DCOptionSetting.Fields, State);
	EndIf;
	If FieldsPresentation = "" Then
		FieldsPresentation = NStr("ru = 'Все поля'; en = 'All fields'; pl = 'Wszystkie pola';de = 'Alle Felder';ro = 'Toate câmpurile';tr = 'Tüm alanlar'; es_ES = 'Todos campos'");
	Else
		FieldsPresentation = NStr("ru = 'Поля:'; en = 'Fields:'; pl = 'Pola:';de = 'Felder:';ro = 'Câmpuri:';tr = 'Alanlar:'; es_ES = 'Campos:'") + " " + FieldsPresentation;
	EndIf;
	
	FilterPresentation = FilterPresentation(DCItem.Filter, DCItem.Filter.Items, State);
	If FilterPresentation = "" AND InfoFromOptionIsAvailable Then
		FilterPresentation = FilterPresentation(DCOptionSetting.Filter, DCOptionSetting.Filter.Items, State);
	EndIf;
	If FilterPresentation = "" Then
		Separator = "";
	Else
		Separator = "; ";
		FilterPresentation = NStr("ru = 'Условие:'; en = 'Criteria:'; pl = 'Opis warunki:';de = 'Beschreibung der Bedingungen:';ro = 'Condiție:';tr = 'Durum:'; es_ES = 'Condición:'") + " " + FilterPresentation;
	EndIf;
	
	Return AppearancePresentation + " (" + FieldsPresentation + Separator + FilterPresentation + ")";
EndFunction

Function AppearancePresentation(DCAppearance)
	Presentation = "";
	For Each DCItem In DCAppearance.Items Do
		If DCItem.Use Then
			AvailableDCParameter = DCAppearance.AvailableParameters.FindParameter(DCItem.Parameter);
			If AvailableDCParameter <> Undefined AND ValueIsFilled(AvailableDCParameter.Title) Then
				KeyPresentation = AvailableDCParameter.Title;
			Else
				KeyPresentation = String(DCItem.Parameter);
			EndIf;
			
			If TypeOf(DCItem.Value) = Type("Color") Then
				ValuePresentation = ColorPresentation(DCItem.Value);
			Else
				ValuePresentation = String(DCItem.Value);
			EndIf;
			
			Presentation = Presentation
				+ ?(Presentation = "", "", ", ")
				+ KeyPresentation
				+ ?(ValuePresentation = "", "", ": " + ValuePresentation);
		EndIf;
	EndDo;
	Return Presentation;
EndFunction

Function ColorPresentation(Color)
	If Color.Type = ColorType.StyleItem Then
		Presentation = String(Color);
		Presentation = Mid(Presentation, StrFind(Presentation, ":")+1);
		Presentation = NameToPresentation(Presentation);
	ElsIf Color.Type = ColorType.WebColor
		Or Color.Type = ColorType.WindowsColor Then
		Presentation = StrLeftBeforeChar(String(Color), " (");
	ElsIf Color.Type = ColorType.Absolute Then
		Presentation = String(Color);
		If Presentation = "0, 0, 0" Then
			Presentation = NStr("ru = 'Черный'; en = 'Black'; pl = 'Czarny';de = 'Schwarz';ro = 'Negru';tr = 'Siyah'; es_ES = 'Negro'");
		ElsIf Presentation = "255, 255, 255" Then
			Presentation = NStr("ru = 'Белый'; en = 'White'; pl = 'Biały';de = 'Weiß';ro = 'Alb';tr = 'Beyaz'; es_ES = 'Blanco'");
		EndIf;
	ElsIf Color.Type = ColorType.AutoColor Then
		Presentation = NStr("ru = 'Авто'; en = 'Auto'; pl = 'Auto';de = 'Auto';ro = 'Auto';tr = 'Oto'; es_ES = 'Auto'");
	Else
		Presentation = "";
	EndIf;
	Return Presentation;
EndFunction

Function NameToPresentation(Val SourceString)
	Result = "";
	IsFirstSymbol = True;
	For CharNumber = 1 To StrLen(SourceString) Do
		CharCode = CharCode(SourceString, CharNumber);
		Char = Char(CharCode);
		If IsFirstSymbol Then
			If Not IsBlankString(Char) Then
				Result = Result + Char;
				IsFirstSymbol = False;
			EndIf;
		Else
			If (CharCode >= 65 AND CharCode <= 90)
				Or (CharCode >= 1040 AND CharCode <= 1071) Then
				Char = " " + Lower(Char);
			ElsIf Char = "_" Then
				Char = " ";
			EndIf;
			Result = Result + Char;
		EndIf;
	EndDo;
	Return Result;
EndFunction

Function FormattedFieldsPresentation(FormattedDCFields, State)
	Presentation = "";
	
	For Each FormattedDCField In FormattedDCFields.Items Do
		If Not FormattedDCField.Use Then
			Continue;
		EndIf;
		
		AvailableDCField = FormattedDCFields.AppearanceFieldsAvailableFields.FindField(FormattedDCField.Field);
		If AvailableDCField = Undefined Then
			State = "DeletionMark";
			FieldPresentation = String(FormattedDCField.Field);
		Else
			If ValueIsFilled(AvailableDCField.Title) Then
				FieldPresentation = AvailableDCField.Title;
			Else
				FieldPresentation = String(FormattedDCField.Field);
			EndIf;
		EndIf;
		Presentation = Presentation + ?(Presentation = "", "", ", ") + FieldPresentation;
		
	EndDo;
	
	Return Presentation;
EndFunction

Function FilterPresentation(DCNode, DCRowSet, State)
	Presentation = "";
	
	For Each DCItem In DCRowSet Do
		If Not DCItem.Use Then
			Continue;
		EndIf;
		
		If TypeOf(DCItem) = Type("DataCompositionFilterItemGroup") Then
			
			GroupPresentation = String(DCItem.GroupType);
			NestedItemsPresentation = FilterPresentation(DCNode, DCItem.Items, State);
			If NestedItemsPresentation = "" Then
				Continue;
			EndIf;
			ItemPresentation = GroupPresentation + "(" + NestedItemsPresentation + ")";
			
		ElsIf TypeOf(DCItem) = Type("DataCompositionFilterItem") Then
			
			AvailableDCFilterField = DCNode.FilterAvailableFields.FindField(DCItem.LeftValue);
			If AvailableDCFilterField = Undefined Then
				State = "DeletionMark";
				FieldPresentation = String(DCItem.LeftValue);
			Else
				If ValueIsFilled(AvailableDCFilterField.Title) Then
					FieldPresentation = AvailableDCFilterField.Title;
				Else
					FieldPresentation = String(DCItem.LeftValue);
				EndIf;
			EndIf;
			
			ValuePresentation = String(DCItem.RightValue);
			
			If DCItem.ComparisonType = DataCompositionComparisonType.Equal Then
				ConditionPresentation = "=";
			ElsIf DCItem.ComparisonType = DataCompositionComparisonType.NotEqual Then
				ConditionPresentation = "<>";
			ElsIf DCItem.ComparisonType = DataCompositionComparisonType.Greater Then
				ConditionPresentation = ">";
			ElsIf DCItem.ComparisonType = DataCompositionComparisonType.GreaterOrEqual Then
				ConditionPresentation = ">=";
			ElsIf DCItem.ComparisonType = DataCompositionComparisonType.Less Then
				ConditionPresentation = "<";
			ElsIf DCItem.ComparisonType = DataCompositionComparisonType.LessOrEqual Then
				ConditionPresentation = "<=";
			
			ElsIf DCItem.ComparisonType = DataCompositionComparisonType.InHierarchy Then
				ConditionPresentation = NStr("ru = 'В группе'; en = 'In group'; pl = 'W grupie';de = 'In Gruppe';ro = 'Face parte din grup';tr = 'Grupta'; es_ES = 'En grupo'");
			ElsIf DCItem.ComparisonType = DataCompositionComparisonType.NotInHierarchy Then
				ConditionPresentation = NStr("ru = 'Не в группе'; en = 'Not in group'; pl = 'Nie w grupie';de = 'Nicht in der Gruppe';ro = 'Nu în grup';tr = 'Grupta değil'; es_ES = 'No en grupo'");
			ElsIf DCItem.ComparisonType = DataCompositionComparisonType.InList Then
				ConditionPresentation = NStr("ru = 'В списке'; en = 'In list'; pl = 'Na liście';de = 'In der Liste';ro = 'În listă';tr = 'Listede'; es_ES = 'En la lista'");
			ElsIf DCItem.ComparisonType = DataCompositionComparisonType.NotInList Then
				ConditionPresentation = NStr("ru = 'Не в списке'; en = 'Not in list'; pl = 'Nie na liście';de = 'Nicht in der Liste';ro = 'Nu este în listă';tr = 'Listede değil'; es_ES = 'No en la lista'");
			ElsIf DCItem.ComparisonType = DataCompositionComparisonType.InListByHierarchy Then
				ConditionPresentation = NStr("ru = 'В списке включая подчиненные'; en = 'In list including subordinate objects'; pl = 'Na liście łącznie z podporządkowanymi';de = 'In Liste einschließlich untergeordnet';ro = 'În listă, inclusiv subordonate';tr = 'Alt listeler dahil listede'; es_ES = 'En la lista que incluye una subordinada'");
			ElsIf DCItem.ComparisonType = DataCompositionComparisonType.NotInListByHierarchy Then
				ConditionPresentation = NStr("ru = 'Не в списке включая подчиненные'; en = 'Not in list including subordinate objects'; pl = 'Nie na liście, łącznie z podporządkowanymi';de = 'Nicht in der Liste, einschließlich untergeordnet';ro = 'Nu este în listă, inclusiv subordonate';tr = 'Alt listeler dahil listede değil'; es_ES = 'No en la lista, que incluye la subordinada'");
			
			ElsIf DCItem.ComparisonType = DataCompositionComparisonType.Contains Then
				ConditionPresentation = NStr("ru = 'Содержит'; en = 'Contains'; pl = 'Zawiera';de = 'Enthält';ro = 'Conţine';tr = 'Içerir'; es_ES = 'Contiene'");
			ElsIf DCItem.ComparisonType = DataCompositionComparisonType.NotContains Then
				ConditionPresentation = NStr("ru = 'Не содержит'; en = 'Does not contain'; pl = 'Nie zawiera';de = 'Enthält nicht';ro = 'Nu conține';tr = 'Içermez'; es_ES = 'No contiene'");
			ElsIf DCItem.ComparisonType = DataCompositionComparisonType.Like Then
				ConditionPresentation = NStr("ru = 'Соответствует шаблону'; en = 'Matches pattern'; pl = 'Odpowiada szablonowi';de = 'Entspricht der Vorlage';ro = 'Corespunde șablonului';tr = 'Şablona uygun'; es_ES = 'Corresponde al modelo'");
			ElsIf DCItem.ComparisonType = DataCompositionComparisonType.NotLike Then
				ConditionPresentation = NStr("ru = 'Не соответствует шаблону'; en = 'Does not match pattern'; pl = 'Nie odpowiada szablonowi';de = 'Entspricht nicht der Vorlage';ro = 'Nu corespunde șablonului';tr = 'Şablona uygun değil'; es_ES = 'No corresponde al modelo'");
			ElsIf DCItem.ComparisonType = DataCompositionComparisonType.BeginsWith Then
				ConditionPresentation = NStr("ru = 'Начинается с'; en = 'Begins with'; pl = 'Zaczyna się na';de = 'Beginnt mit';ro = 'Începe cu';tr = 'İle başlar'; es_ES = 'Empieza con'");
			ElsIf DCItem.ComparisonType = DataCompositionComparisonType.NotBeginsWith Then
				ConditionPresentation = NStr("ru = 'Не начинается с'; en = 'Does not begin with'; pl = 'Nie zaczyna się na';de = 'Beginnt nicht mit';ro = 'Nu începe cu';tr = 'İle başlamaz'; es_ES = 'No empieza con'");
			ElsIf DCItem.ComparisonType = DataCompositionComparisonType.Filled Then
				ConditionPresentation = NStr("ru = 'Заполнено'; en = 'Not blank'; pl = 'Wypełnił';de = 'Ausgefüllt';ro = 'Completat';tr = 'Dolduruldu'; es_ES = 'Rellenado'");
				ValuePresentation = "";
			ElsIf DCItem.ComparisonType = DataCompositionComparisonType.NotFilled Then
				ConditionPresentation = NStr("ru = 'Не заполнено'; en = 'Blank'; pl = 'Niewypełniony';de = 'Leer';ro = 'Goală';tr = 'Boş'; es_ES = 'Vacía'");
				ValuePresentation = "";
			EndIf;
			
			ItemPresentation = TrimAll(FieldPresentation + " " + ConditionPresentation + " " + ValuePresentation);
			
		Else
			Continue;
		EndIf;
		
		Presentation = Presentation + ?(Presentation = "", "", ", ") + ItemPresentation;
		
	EndDo;
	
	Return Presentation;
EndFunction

////////////////////////////////////////////////////////////////////////////////
// Other methods

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

Function CopyRecursive(Val Node, Val WhatToCopy, Val WhereToPaste, Val Index, Map) Export
	ItemType = TypeOf(WhatToCopy);
	CopyingParameters = CopyingParameters(ItemType, WhereToPaste);
	
	If CopyingParameters.ItemTypeMustBeSpecified Then
		If Index = Undefined Then
			NewRow = WhereToPaste.Add(ItemType);
		Else
			NewRow = WhereToPaste.Insert(Index, ItemType);
		EndIf;
	Else
		If Index = Undefined Then
			NewRow = WhereToPaste.Add();
		Else
			NewRow = WhereToPaste.Insert(Index);
		EndIf;
	EndIf;
	
	FillPropertiesRecursively(Node, NewRow, WhatToCopy, Map, CopyingParameters);
	
	Return NewRow;
EndFunction

Function CopyingParameters(ItemType, Collection)
	Result = New Structure;
	Result.Insert("ItemTypeMustBeSpecified", False);
	Result.Insert("ExcludeProperties", Undefined);
	Result.Insert("HasSettings", False);
	Result.Insert("HasItems", False);
	Result.Insert("HasSelection", False);
	Result.Insert("HasFilter", False);
	Result.Insert("HasOutputParameters", False);
	Result.Insert("HasDataParameters", False);
	Result.Insert("HasUserFields", False);
	Result.Insert("HasGroupFields", False);
	Result.Insert("HasOrder", False);
	Result.Insert("HasStructure", False);
	Result.Insert("HasConditionalAppearance", False);
	Result.Insert("HasColumnsAndRows", False);
	Result.Insert("HasSeriesAndDots", False);
	Result.Insert("HasNestedParametersValues", False);
	Result.Insert("HasFieldsAndDecorations", False);
	
	If ItemType = Type("DataCompositionSelectedFieldGroup")
		Or ItemType = Type("DataCompositionFilterItemGroup") Then
		
		Result.ItemTypeMustBeSpecified = True;
		Result.ExcludeProperties = "Parent";
		Result.HasItems = True;
		
	ElsIf ItemType = Type("DataCompositionSelectedField")
		Or ItemType = Type("DataCompositionAutoSelectedField")
		Or ItemType = Type("DataCompositionFilterItem") Then
		
		Result.ExcludeProperties = "Parent";
		Result.ItemTypeMustBeSpecified = True;
		
	ElsIf ItemType = Type("DataCompositionParameterValue")
		Or ItemType = Type("DataCompositionSettingsParameterValue") Then
		
		Result.ExcludeProperties = "Parent";
		
	ElsIf ItemType = Type("DataCompositionGroupField")
		Or ItemType = Type("DataCompositionAutoGroupField")
		Or ItemType = Type("DataCompositionOrderItem")
		Or ItemType = Type("DataCompositionAutoOrderItem") Then
		
		Result.ItemTypeMustBeSpecified = True;
		
	ElsIf ItemType = Type("DataCompositionConditionalAppearanceItem") Then
		
		Result.HasFilter = True;
		Result.HasFieldsAndDecorations = True;
		
	ElsIf ItemType = Type("DataCompositionGroup")
		Or ItemType = Type("DataCompositionTableGroup")
		Or ItemType = Type("DataCompositionChartGroup")Then
		
		Result.ExcludeProperties = "Parent";
		CollectionType = TypeOf(Collection);
		If CollectionType = Type("DataCompositionSettingStructureItemCollection") Then
			Result.ItemTypeMustBeSpecified = True;
			ItemType = Type("DataCompositionGroup"); // Replacing type with the supported one.
		EndIf;
		
		Result.HasSelection = True;
		Result.HasFilter = True;
		Result.HasOutputParameters = True;
		Result.HasGroupFields = True;
		Result.HasOrder = True;
		Result.HasStructure = True;
		Result.HasConditionalAppearance = True;
		
	ElsIf ItemType = Type("DataCompositionTable") Then
		
		Result.ExcludeProperties = "Parent";
		Result.ItemTypeMustBeSpecified = True;
		
		Result.HasSelection = True;
		Result.HasColumnsAndRows = True;
		Result.HasOutputParameters = True;
		
	ElsIf ItemType = Type("DataCompositionChart") Then
		
		Result.ExcludeProperties = "Parent";
		Result.ItemTypeMustBeSpecified = True;
		
		Result.HasSelection = True;
		Result.HasSeriesAndDots = True;
		Result.HasOutputParameters = True;
		
	ElsIf ItemType = Type("DataCompositionNestedObjectSettings") Then
		
		Result.ExcludeProperties = "Parent";
		Result.ItemTypeMustBeSpecified = True;
		Result.HasSettings = True;
		
		Result.HasSelection = True;
		Result.HasFilter = True;
		Result.HasOutputParameters = True;
		Result.HasDataParameters = True;
		Result.HasUserFields = True;
		Result.HasOrder = True;
		Result.HasStructure = True;
		Result.HasConditionalAppearance = True;
		
	ElsIf ItemType <> Type("FormDataTreeItem") Then 
		
		Raise StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Копирование элементов ""%1"" не поддерживается'; en = '%1 copy is not supported.'; pl = 'Kopiowanie elementów ""%1"" nie jest obsługiwane.';de = 'Kopieren von Elementen ""%1"" wird nicht unterstützt.';ro = 'Copierea articolelor ""%1"" nu este acceptată.';tr = '""%1"" öğelerinin kopyalanması desteklenmiyor.'; es_ES = 'No se admite copiar los artículos ""%1"".'"), ItemType);
		
	EndIf;
	
	Return Result;
	
EndFunction

Function FillPropertiesRecursively(Node, WhatToFill, FillWithWhat, Map = Undefined, CopyingParameters = Undefined) Export
	If Map = Undefined Then
		Map = New Map;
	EndIf;
	If CopyingParameters = Undefined Then
		CopyingParameters = CopyingParameters(TypeOf(FillWithWhat), Undefined);
	EndIf;
	
	If CopyingParameters.ExcludeProperties <> "*" Then
		FillPropertyValues(WhatToFill, FillWithWhat, , CopyingParameters.ExcludeProperties);
	EndIf;
	
	IsDataTreeFormItem = TypeOf(FillWithWhat) = Type("FormDataTreeItem");
	If IsDataTreeFormItem Then
		Map.Insert(FillWithWhat, WhatToFill);
		
		NestedItemsCollection = ?(IsDataTreeFormItem, FillWithWhat.GetItems(), FillWithWhat.Rows);
		If NestedItemsCollection.Count() > 0 Then
			NewNestedItemsCollection = ?(IsDataTreeFormItem, WhatToFill.GetItems(), WhatToFill.Rows);
			For Each SubordinateRow In NestedItemsCollection Do
				CopyRecursive(Node, SubordinateRow, NewNestedItemsCollection, Undefined, Map);
			EndDo;
		EndIf;
		
		Return WhatToFill;
	EndIf;
		
	OldID = Node.GetIDByObject(FillWithWhat);
	NewID = Node.GetIDByObject(WhatToFill);
	Map.Insert(OldID, NewID);
	
	If CopyingParameters.HasSettings Then
		WhatToFill.SetIdentifier(FillWithWhat.ObjectID);
		WhatToFill = WhatToFill.Settings;
		FillWithWhat = FillWithWhat.Settings;
	EndIf;
	
	If CopyingParameters.HasItems Then
		//   Items (DataCompositionSelectedFieldCollection,
		//       DataCompositionFilterItemCollection).
		NestedItemsCollection = FillWithWhat.Items;
		If NestedItemsCollection.Count() > 0 Then
			NewNestedItemsCollection = WhatToFill.Items;
			For Each SubordinateRow In NestedItemsCollection Do
				CopyRecursive(Node, SubordinateRow, NewNestedItemsCollection, Undefined, Map);
			EndDo;
		EndIf;
	EndIf;
	
	If CopyingParameters.HasSelection Then
		//   Choice (DataCompositionSelectedFields).
		FillPropertyValues(WhatToFill.Selection, FillWithWhat.Selection, , "SelectionAvailableFields, Items");
		//   Choice.Items (DataCompositionSelectedFieldCollection).
		NestedItemsCollection = FillWithWhat.Selection.Items;
		If NestedItemsCollection.Count() > 0 Then
			NewNestedItemsCollection = WhatToFill.Selection.Items;
			For Each SubordinateRow In NestedItemsCollection Do
				CopyRecursive(Node, SubordinateRow, NewNestedItemsCollection, Undefined, Map);
			EndDo;
		EndIf;
	EndIf;
	
	If CopyingParameters.HasFilter Then
		//   Filter (DataCompositionFilter).
		FillPropertyValues(WhatToFill.Filter, FillWithWhat.Filter, , "FilterAvailableFields, Items");
		//   Filter.Items (DataCompositionFilterItemCollection).
		NestedItemsCollection = FillWithWhat.Filter.Items;
		If NestedItemsCollection.Count() > 0 Then
			NewNestedItemsCollection = WhatToFill.Filter.Items;
			For Each SubordinateRow In NestedItemsCollection Do
				CopyRecursive(Node, SubordinateRow, NewNestedItemsCollection, Undefined, New Map);
			EndDo;
		EndIf;
	EndIf;
	
	If CopyingParameters.HasOutputParameters Then
		//   OutputParameters (DataCompositionOutputParameterValues,
		//       DataCompositionGroupOutputParameterValues,
		//       DataCompositionTableGroupOutputParameterValues,
		//       DataCompositionChartGroupOutputParameterValues,
		//       DataCompositionTableOutputParameterValues,
		//       DataCompositionChartOutputParameterValues).
		//   OutputParameters.Items (DataCompositionParameterValueCollection).
		NestedItemsCollection = FillWithWhat.OutputParameters.Items;
		If NestedItemsCollection.Count() > 0 Then
			NestedItemsNode = WhatToFill.OutputParameters;
			For Each SubordinateRow In NestedItemsCollection Do
				DCParameterValue = NestedItemsNode.FindParameterValue(SubordinateRow.Parameter);
				If DCParameterValue <> Undefined Then
					FillPropertyValues(DCParameterValue, SubordinateRow);
				EndIf;
			EndDo;
		EndIf;
	EndIf;
	
	If CopyingParameters.HasDataParameters Then
		//   DataParameters (DataCompositionDataParameterValues).
		//   DataParameters.Items (DataCompositionParameterValueCollection).
		NestedItemsCollection = FillWithWhat.DataParameters.Items;
		If NestedItemsCollection.Count() > 0 Then
			NestedItemsNode = WhatToFill.DataParameters;
			For Each SubordinateRow In NestedItemsCollection Do
				DCParameterValue = NestedItemsNode.FindParameterValue(SubordinateRow.Parameter);
				If DCParameterValue <> Undefined Then
					FillPropertyValues(DCParameterValue, SubordinateRow);
				EndIf;
			EndDo;
		EndIf;
	EndIf;
	
	If CopyingParameters.HasUserFields Then
		//   UserFields (DataCompositionUserFields).
		//   ПользовательскиеПоля.Items (DataCompositionUserFieldCollection).
		NestedItemsCollection = FillWithWhat.UserFields.Items;
		If NestedItemsCollection.Count() > 0 Then
			NewNestedItemsCollection = WhatToFill.UserFields.Items;
			For Each SubordinateRow In NestedItemsCollection Do
				CopyRecursive(Node, SubordinateRow, NewNestedItemsCollection, Undefined, Map);
			EndDo;
		EndIf;
	EndIf;
	
	If CopyingParameters.HasGroupFields Then
		//   GroupFields (DataCompositionGroupFields).
		//   GroupFields.Items (DataCompositionGroupFieldCollection).
		NestedItemsCollection = FillWithWhat.GroupFields.Items;
		If NestedItemsCollection.Count() > 0 Then
			NewNestedItemsCollection = WhatToFill.GroupFields.Items;
			For Each SubordinateRow In NestedItemsCollection Do
				CopyRecursive(Node, SubordinateRow, NewNestedItemsCollection, Undefined, New Map);
			EndDo;
		EndIf;
	EndIf;
	
	If CopyingParameters.HasOrder Then
		//   Order (DataCompositionOrder).
		FillPropertyValues(WhatToFill.Order, FillWithWhat.Order, , "OrderAvailableFields, Items");
		//   Order.Items (DataCompositionOrderItemCollection).
		NestedItemsCollection = FillWithWhat.Order.Items;
		If NestedItemsCollection.Count() > 0 Then
			NewNestedItemsCollection = WhatToFill.Order.Items;
			For Each SubordinateRow In NestedItemsCollection Do
				CopyRecursive(Node, SubordinateRow, NewNestedItemsCollection, Undefined, Map);
			EndDo;
		EndIf;
	EndIf;
	
	If CopyingParameters.HasStructure Then
		//   Structure (DataCompositionSettingStructureItemCollection,
		//       DataCompositionChartStructureItemCollection,
		//       DataCompositionTableStructureItemCollection).
		FillPropertyValues(WhatToFill.Structure, FillWithWhat.Structure);
		NestedItemsCollection = FillWithWhat.Structure;
		If NestedItemsCollection.Count() > 0 Then
			NewNestedItemsCollection = WhatToFill.Structure;
			For Each SubordinateRow In NestedItemsCollection Do
				CopyRecursive(Node, SubordinateRow, NewNestedItemsCollection, Undefined, Map);
			EndDo;
		EndIf;
	EndIf;
	
	If CopyingParameters.HasConditionalAppearance Then
		//   ConditionalAppearance (DataCompositionConditionalAppearance).
		FillPropertyValues(WhatToFill.ConditionalAppearance, FillWithWhat.ConditionalAppearance, , "FilterAvailableFields, FieldsAvailableFields, Items");
		//   ConditionalAppearance.Items (DataCompositionConditionalAppearanceItemCollection).
		NestedItemsCollection = FillWithWhat.ConditionalAppearance.Items;
		If NestedItemsCollection.Count() > 0 Then
			NewNestedItemsCollection = WhatToFill.ConditionalAppearance.Items;
			For Each SubordinateRow In NestedItemsCollection Do
				CopyRecursive(Node, SubordinateRow, NewNestedItemsCollection, Undefined, Map);
			EndDo;
		EndIf;
	EndIf;
	
	If CopyingParameters.HasColumnsAndRows Then
		//   Columns (DataCompositionTableStructureItemCollection).
		NestedItemsCollection = FillWithWhat.Columns;
		NewNestedItemsCollection = WhatToFill.Columns;
		OldID = Node.GetIDByObject(NestedItemsCollection);
		NewID = Node.GetIDByObject(NewNestedItemsCollection);
		Map.Insert(OldID, NewID);
		For Each SubordinateRow In NestedItemsCollection Do
			CopyRecursive(Node, SubordinateRow, NewNestedItemsCollection, Undefined, Map);
		EndDo;
		//   Rows (DataCompositionTableStructureItemCollection).
		NestedItemsCollection = FillWithWhat.Rows;
		NewNestedItemsCollection = WhatToFill.Rows;
		OldID = Node.GetIDByObject(NestedItemsCollection);
		NewID = Node.GetIDByObject(NewNestedItemsCollection);
		Map.Insert(OldID, NewID);
		For Each SubordinateRow In NestedItemsCollection Do
			CopyRecursive(Node, SubordinateRow, NewNestedItemsCollection, Undefined, Map);
		EndDo;
	EndIf;
	
	If CopyingParameters.HasSeriesAndDots Then
		//   Series (DataCompositionChartStructureItemCollection).
		NestedItemsCollection = FillWithWhat.Series;
		NewNestedItemsCollection = WhatToFill.Series;
		OldID = Node.GetIDByObject(NestedItemsCollection);
		NewID = Node.GetIDByObject(NewNestedItemsCollection);
		Map.Insert(OldID, NewID);
		For Each SubordinateRow In NestedItemsCollection Do
			CopyRecursive(Node, SubordinateRow, NewNestedItemsCollection, Undefined, Map);
		EndDo;
		//   Dots (DataCompositionChartStructureItemCollection).
		NestedItemsCollection = FillWithWhat.Points;
		NewNestedItemsCollection = WhatToFill.Points;
		OldID = Node.GetIDByObject(NestedItemsCollection);
		NewID = Node.GetIDByObject(NewNestedItemsCollection);
		Map.Insert(OldID, NewID);
		For Each SubordinateRow In NestedItemsCollection Do
			CopyRecursive(Node, SubordinateRow, NewNestedItemsCollection, Undefined, Map);
		EndDo;
	EndIf;
	
	If CopyingParameters.HasNestedParametersValues Then
		//   NestedParameterValues (DataCompositionParameterValueCollection).
		For Each SubordinateRow In FillWithWhat.NestedParameterValues Do
			CopyRecursive(Node, SubordinateRow, WhatToFill.NestedParameterValues, Undefined, Map);
		EndDo;
	EndIf;
	
	If CopyingParameters.HasFieldsAndDecorations Then
		For Each FormattedField In FillWithWhat.Fields.Items Do
			FillPropertyValues(WhatToFill.Fields.Items.Add(), FormattedField);
		EndDo;
		For Each Source In FillWithWhat.Appearance.Items Do
			Destination = WhatToFill.Appearance.FindParameterValue(Source.Parameter);
			If Destination <> Undefined Then
				FillPropertyValues(Destination, Source, , "Parent");
				For Each NestedSource In Source.NestedParameterValues Do
					NestedDestination = WhatToFill.Appearance.FindParameterValue(Source.Parameter);
					If NestedDestination <> Undefined Then
						FillPropertyValues(NestedDestination, NestedSource, , "Parent");
					EndIf;
				EndDo;
			EndIf;
		EndDo;
	EndIf;
		
	Return WhatToFill;
EndFunction

Function AddUniqueValueToList(List, Value, Presentation, Usage) Export
	If TypeOf(List) <> Type("ValueList")
		Or (Not ValueIsFilled(Value) AND Not ValueIsFilled(Presentation)) Then
		Return Undefined;
	EndIf;
	
	ListItem = List.FindByValue(Value);
	
	If ListItem = Undefined Then
		ListItem = List.Add();
		ListItem.Value = Value;
	EndIf;
	
	If ValueIsFilled(Presentation) Then
		ListItem.Presentation = Presentation;
	ElsIf Not ValueIsFilled(ListItem.Presentation) Then
		ListItem.Presentation = String(Value);
	EndIf;
	
	If Usage AND Not ListItem.Check Then
		ListItem.Check = True;
	EndIf;
	
	Return ListItem;
EndFunction

Function ValuesByList(Values, OnlyFilledValues = False) Export
	If TypeOf(Values) = Type("ValueList") Then
		List = Values;
	Else
		List = New ValueList;
		If TypeOf(Values) = Type("Array") Then
			List.LoadValues(Values);
		ElsIf Values <> Undefined Then
			List.Add(Values);
		EndIf;
	EndIf;
	
	If Not OnlyFilledValues Then 
		Return List;
	EndIf;
	
	Index = List.Count() - 1;
	While Index >= 0 Do 
		Item = List[Index];
		If Not ValueIsFilled(Item.Value) Then 
			List.Delete(Item);
		EndIf;
		Index = Index - 1;
	EndDo;
	
	Return List;
EndFunction

Function AddToList(DestinationList, SourceList, CheckType = Undefined, AddNewItems = True) Export
	If DestinationList = Undefined Or SourceList = Undefined Then
		Return Undefined;
	EndIf;
	
	ReplaceExistingItems = True;
	ReplacePresentation = ReplaceExistingItems AND AddNewItems;
	
	Result = New Structure;
	Result.Insert("Total", 0);
	Result.Insert("Added", 0);
	Result.Insert("Updated", 0);
	Result.Insert("Skipped", 0);
	
	If CheckType = Undefined Then
		CheckType = (DestinationList.ValueType <> SourceList.ValueType);
	EndIf;
	If CheckType Then
		DestinationTypesDetails = DestinationList.ValueType;
	EndIf;
	For Each SourceItem In SourceList Do
		Result.Total = Result.Total + 1;
		Value = SourceItem.Value;
		If CheckType AND Not DestinationTypesDetails.ContainsType(TypeOf(Value)) Then
			Result.Skipped = Result.Skipped + 1;
			Continue;
		EndIf;
		DestinationItem = DestinationList.FindByValue(Value);
		If DestinationItem = Undefined Then
			If AddNewItems Then
				Result.Added = Result.Added + 1;
				FillPropertyValues(DestinationList.Add(), SourceItem);
			Else
				Result.Skipped = Result.Skipped + 1;
			EndIf;
		Else
			If ReplaceExistingItems Then
				Result.Updated = Result.Updated + 1;
				FillPropertyValues(DestinationItem, SourceItem, , ?(ReplacePresentation, "", "Presentation"));
			Else
				Result.Skipped = Result.Skipped + 1;
			EndIf;
		EndIf;
	EndDo;
	Return Result;
EndFunction

Function StrLeftBeforeChar(Row, Separator, Balance = Undefined)
	Position = StrFind(Row, Separator);
	If Position = 0 Then
		StringBeforeDot = Row;
		Balance = "";
	Else
		StringBeforeDot = Left(Row, Position - 1);
		Balance = Mid(Row, Position + 1);
	EndIf;
	Return StringBeforeDot;
EndFunction

Function FindTableRows(TableAttribute, RowData) Export
	If TypeOf(TableAttribute) = Type("FormDataCollection") Then // Value table.
		Return TableAttribute.FindRows(RowData);
	ElsIf TypeOf(TableAttribute) = Type("FormDataTree") Then // Value tree.
		Return FindRecursively(TableAttribute.GetItems(), RowData);
	Else
		Return Undefined;
	EndIf;
EndFunction

Function FindRecursively(RowsSet, RowData, FoundItems = Undefined)
	If FoundItems = Undefined Then
		FoundItems = New Array;
	EndIf;
	For Each TableRow In RowsSet Do
		ValuesMatch = True;
		For Each KeyAndValue In RowData Do
			If TableRow[KeyAndValue.Key] <> KeyAndValue.Value Then
				ValuesMatch = False;
				Break;
			EndIf;
		EndDo;
		If ValuesMatch Then
			FoundItems.Add(TableRow);
		EndIf;
		FindRecursively(TableRow.GetItems(), RowData, FoundItems);
	EndDo;
	Return FoundItems;
EndFunction

Procedure CastValueToType(Value, TypesDetails) Export
	If Not TypesDetails.ContainsType(TypeOf(Value)) Then
		Value = TypesDetails.AdjustValue();
	EndIf;
EndProcedure

// Picture name in the ReportSettingsIcons collection.
Function PictureIndex(Type, State = Undefined) Export
	If Type = "Group" Then
		Index = 1;
	ElsIf Type = "Item" Then
		Index = 4;
	ElsIf Type = "Group"
		Or Type = "TableGroup"
		Or Type = "ChartGroup" Then
		Index = 7;
	ElsIf Type = "Table" Then
		Index = 10;
	ElsIf Type = "Chart" Then
		Index = 11;
	ElsIf Type = "NestedObjectSettings" Then
		Index = 12;
	ElsIf Type = "DataParameters" Then
		Index = 14;
	ElsIf Type = "DataParameter" Then
		Index = 15;
	ElsIf Type = "Filters" Then
		Index = 16;
	ElsIf Type = "FilterItem" Then
		Index = 17;
	ElsIf Type = "SelectedFields" Then
		Index = 18;
	ElsIf Type = "Sorting" Then
		Index = 19;
	ElsIf Type = "ConditionalAppearance" Then
		Index = 20;
	ElsIf Type = "Settings" Then
		Index = 21;
	ElsIf Type = "Structure" Then
		Index = 22;
	ElsIf Type = "Resource" Then
		Index = 23;
	ElsIf Type = "Warning" Then
		Index = 24;
	ElsIf Type = "Error" Then
		Index = 25;
	Else
		Index = -2;
	EndIf;
	
	If State = "DeletionMark" Then
		Index = Index + 1;
	ElsIf State = "Predefined" Then
		Index = Index + 2;
	EndIf;
	
	Return Index;
EndFunction

Function UniqueKey(FullReportName, OptionKey) Export
	Result = FullReportName;
	If ValueIsFilled(OptionKey) Then
		Result = Result + "/VariantKey." + OptionKey;
	EndIf;
	Return Result;
EndFunction

Function SettingItemCondition(Item, Details) Export 
	Condition = DataCompositionComparisonType.Equal;
	
	If TypeOf(Item) = Type("DataCompositionFilterItem") Then 
		Condition = Item.ComparisonType;
	ElsIf TypeOf(Item) = Type("DataCompositionSettingsParameterValue")
		AND Details.ValueListAllowed Then 
		Condition = DataCompositionComparisonType.InList;
	EndIf;
	
	Return Condition;
EndFunction

Function IsListComparisonKind(ComparisonType) Export 
	ComparisonsTypes = New Array;
	ComparisonsTypes.Add(DataCompositionComparisonType.InList);
	ComparisonsTypes.Add(DataCompositionComparisonType.NotInList);
	ComparisonsTypes.Add(DataCompositionComparisonType.InListByHierarchy);
	ComparisonsTypes.Add(DataCompositionComparisonType.NotInListByHierarchy);
	
	Return ComparisonsTypes.Find(ComparisonType) <> Undefined;
EndFunction

Function ChoiceParameters(Settings, UserSettings, SettingItem, OptionChangeMode = False) Export 
	ChoiceParameters = New Array;
	
	SettingItemDetails = FindAvailableSetting(Settings, SettingItem);
	If SettingItemDetails = Undefined Then 
		Return New FixedArray(ChoiceParameters);
	EndIf;
	
	Parameters = SettingItemDetails.GetChoiceParameters();
	For Each Parameter In Parameters Do 
		If ValueIsFilled(Parameter.Name) Then
			ChoiceParameters.Add(New ChoiceParameter(Parameter.Name, Parameter.Value));
		EndIf;
	EndDo;
	
	Parameters = SettingItemDetails.GetChoiceParameterLinks();
	For Each Parameter In Parameters Do 
		If Not ValueIsFilled(Parameter.Name) Then
			Continue;
		EndIf;
		
		Value = ChoiceParameterValue(Settings, UserSettings, Parameter.Field, OptionChangeMode);
		If ValueIsFilled(Value) Then 
			ChoiceParameters.Add(New ChoiceParameter(Parameter.Name, Value));
		EndIf;
	EndDo;
	
	Return New FixedArray(ChoiceParameters);
EndFunction

Function SearchSettingByIDAvailable()
	SystemInformation = New SystemInfo;
	VersionStructure = StrSplit(SystemInformation.AppVersion, ".");
	
	NumberDetails = New TypeDescription("Number");
	ApplicationVersion = NumberDetails.AdjustValue(VersionStructure[2]);
	
	Return (ApplicationVersion > 12);
EndFunction

#EndRegion
