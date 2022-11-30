///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Public

// Sets the passed schema to the report and initializes the settings composer based on the schema.
// If a report (settings) form is the context, the procedure refreshes the main form attribute - Report.
// The result is that the object context and the report form get synchronized.
// For example, it is called from the BeforeImportSettingsToComposer handler of an object of the 
// universal report in order to set the schema generated programmatically based on another metadata object.
//
// Parameters:
//  Report - ReportObject, ExternalReportObject - a report that requires a schema to be connected.
//  Context - ManagedForm - a report form or a report settings form.
//                                It is passed "as is" from the similarly named parameter of event
//                                BeforeImportSettingsToComposer.
//           - Structure - report parameters. See ReportOptions.AttachReportAndImportSettings. 
//  Schema - DataCompositionSchema - a schema to set to the report.
//  SchemaKey - String - new schema ID that will be written to additional properties of user 
//                       settings.
//
// Example:
//  // In report object handler BeforeImportSettingsToComposer, the settings composer 
//  // is initialized based on schema from the common templates:
//  If SchemaKey <> "1" Then
//  	SchemaKey = "1";
//  	Schema = GetCommonTemplate("MyCommonCompositionSchema");
//  	ReportsServer.EnableSchema(ThisObject, Context, Schema, SchemaKey);
//  EndIf;
//
Procedure AttachSchema(Report, Context, Schema, SchemaKey) Export
	FormEvent = (TypeOf(Context) = Type("ManagedForm"));
	
	Report.DataCompositionSchema = Schema;
	If FormEvent Then
		ReportSettings = Context.ReportSettings;
		SchemaURL = ReportSettings.SchemaURL;
		ReportSettings.Insert("SchemaModified", True);
	Else
		SchemaURLFilled = (TypeOf(Context.SchemaURL) = Type("String") AND IsTempStorageURL(Context.SchemaURL));
		If Not SchemaURLFilled Then
			FormID = CommonClientServer.StructureProperty(Context, "FormID");
			If TypeOf(FormID) = Type("UUID") Then
				SchemaURLFilled = True;
				Context.SchemaURL = PutToTempStorage(Schema, FormID);
			EndIf;
		EndIf;
		If SchemaURLFilled Then
			SchemaURL = Context.SchemaURL;
		Else
			SchemaURL = PutToTempStorage(Schema);
		EndIf;
		Context.SchemaModified = True;
	EndIf;
	PutToTempStorage(Schema, SchemaURL);
	
	ReportOption = ?(FormEvent, ReportSettings.OptionRef, Undefined);
	InitializeSettingsComposer(Report.SettingsComposer, SchemaURL, Report, ReportOption);
	
	If FormEvent Then
		ValueToFormData(Report, Context.Report);
	EndIf;
EndProcedure

// Initializes data composition settings composer with exception handling.
//
// Parameters:
//  SettingsComposer - DataCompositionSettingsComposer - the settings composer to initialize.
//  Schema - DataCompositionSchema, URL - see Syntax Assistant: DataCompositionAvailableSettingsSource.
//  Report - ReportObject, Undefined - the report whose composer is to initialize.
//  ReportOption - CatalogRef.ReportOptions, Undefined - report option storage.
//
Procedure InitializeSettingsComposer(SettingsComposer, Schema, Report = Undefined, ReportOption = Undefined) Export 
	Try
		SettingsComposer.Initialize(New DataCompositionAvailableSettingsSource(Schema));
	Except
		EventName = NStr("ru = 'Ошибка инициализации компоновщика настроек компоновки данных.'; en = 'Error starting data composition settings composer.'; pl = 'Błąd inicjowania ustawień składu danych układu.';de = 'Initialisierungsfehler des Linkers für Datenlayout-Einstellungen.';ro = 'Eroare de inițializare a linkerului setărilor de combinare a datelor.';tr = 'Veri düzeni ayarları bağlayıcı başlatma hatası.'; es_ES = 'Error de inicializar el diseñador de ajustes de diseño de datos.'",
			Common.DefaultLanguageCode());
		
		MetadataObject = Undefined;
		If Report <> Undefined Then 
			MetadataObject = Report.Metadata();
		ElsIf ReportOption <> Undefined Then 
			MetadataObject = ReportOption.Metadata();
		EndIf;
		
		Comment = DetailErrorDescription(ErrorInfo());
		
		WriteLogEvent(
			EventName, EventLogLevel.Error, MetadataObject, ReportOption, Comment);
		
		Raise;
	EndTry;
EndProcedure

// Outputs command to a report form as a button to the specified group.
// It also registers the command protecting it from deletion upon redrawing the form.
// To call from the OnCreateAtServer report form event.
//
// Parameters:
//   ReportForm       - ManagedForm - a report form, to which command is added.
//   CommandOrCommands - FormCommand     - a command, to which the displayed buttons will be connected.
//					       If the Action property has a blank string, when the command is executed, the 
//					       ReportsClientOverridable.CommandHandler procedure will be called.
//					       If the Action property contains a string of the "<CommonClientModuleName>.
//					       <ExportProcedureName>" kind, when the command is executed in the specified module, the 
//					       specified procedure with two parameters will be called, similar to the first two parameters of the ReportsClientOverridable.CommandHandler procedure.
//				       - Array - a set of commands (FormCommand), that will be output to the specified group.
//   GroupType         - String - conditional name of the group, in which a button is to be output.
//					       "Main"          - a group with the "Generate" and "Generate now" buttons.
//					       "Settings"        - a group with buttons "Settings", "Change report options", and so on.
//					       "SpreadsheetDocumentOperations" - a group with buttons "Find", "Expand all groups", and so on.
//					       "Integration"       - a group with such buttons as "Print, Save, Send", and so on.
//					       "SubmenuSend" - a submenu in the "Integration" group to send via email.
//					       "Other"           - a group with such buttons as "Change form", "Help", and so on.
//   ToGroupBeginning      - Boolean - if True, the button will be output to the beginning of the group. Otherwise, a button will be output to group end.
//   OnlyInAllActions - Boolean - if True, a button will be output only to the "More actions" submenu.
//                                    Otherwise, a button will be output both to the "More actions" submenu and to the form command bar.
//   SubgroupSuffix   - String - if it is filled, commands will be merged into a subgroup.
//                                 SubgroupSuffix is added to the right subgroup name.
//
Procedure OutputCommand(ReportForm, CommandOrCommands, GroupType, ToGroupBeginning = False, OnlyInAllActions = False, SubgroupSuffix = "") Export
	BeforeWhatToInsert = Undefined;
	MoreGroup = Undefined;
	
	If GroupType = "Main" Then
		Folder = ReportForm.Items.MainGroup;
		MoreGroup = ReportForm.Items.MoreCommandBarMainGroup;
	ElsIf GroupType = "Settings" Then
		Folder = ReportForm.Items.ReportSettingsGroup;
		MoreGroup = ReportForm.Items.MoreCommandBarReportSettingsGroup;
	ElsIf GroupType = "SpreadsheetDocumentOperations" Then
		Folder = ReportForm.Items.WorkInTableGroup;
		MoreGroup = ReportForm.Items.MoreCommandBarTableActionsGroup;
	ElsIf GroupType = "Integration" Then
		Folder = ReportForm.Items.OutputGroup;
		MoreGroup = ReportForm.Items.MoreCommandBarOutputGroup;
	ElsIf GroupType = "SubmenuSend" Then
		Folder = ReportForm.Items.SendGroup;
		MoreGroup = ReportForm.Items.MoreCommandBarSendGroup;
	ElsIf GroupType = "Other" Then
		Folder = ReportForm.Items.MainCommandBar;
		MoreGroup = ReportForm.Items.MoreCommandBar;
		BeforeWhatToInsert = ?(ToGroupBeginning, ReportForm.Items.NewWindow, Undefined);
	Else
		Raise StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'При вызове процедуры ""%1"" передано недопустимо значение параметра ""%2"".'; en = 'Invalid value is passed in parameter %2 on calling procedure %1.'; pl = 'Podczas wywołania procedury ""%1"" została przekazana niedopuszczalna wartość parametru ""%2"".';de = 'Beim Aufruf der Prozedur ""%1"" ist der Wert des Parameters ""%2"" ungültig.';ro = 'La apelarea procedurii ""%1"" a fost transmisă valoarea inadmisibilă a parametrului ""%2"".';tr = '""%1"" prosedürü çağrıldığında ""%2"" parametrenin değeri kullanılamıyor.'; es_ES = 'Al llamar el procedimiento ""%1"" ha sido pasado un valor inadmisible del parámetro ""%2"".'"),
			"ReportsServer.OutputCommand",
			"GroupType");
	EndIf;
	
	If OnlyInAllActions Then 
		Folder = MoreGroup;
		MoreGroup = Undefined;
	EndIf;
	
	If ToGroupBeginning AND BeforeWhatToInsert = Undefined Then
		BeforeWhatToInsert = Folder.ChildItems[0];
	EndIf;
	
	If TypeOf(CommandOrCommands) = Type("FormCommand") Then
		Commands = New Array;
		Commands.Add(CommandOrCommands);
	Else
		Commands = CommandOrCommands;
	EndIf;
	
	If SubgroupSuffix <> "" Then
		Subgroup = ReportForm.Items.Find(Folder.Name + SubgroupSuffix);
		If Subgroup = Undefined Then
			Subgroup = ReportForm.Items.Insert(Folder.Name + SubgroupSuffix, Type("FormGroup"), Folder, BeforeWhatToInsert);
			If Subgroup.Type = FormGroupType.Popup Then
				Subgroup.Type = FormGroupType.ButtonGroup;
			EndIf;
		EndIf;
		Folder = Subgroup;
		BeforeWhatToInsert = Undefined;
	EndIf;
	
	For Each Command In Commands Do
		Handler = ?(StrOccurrenceCount(Command.Action, ".") = 0, "", Command.Action);
		ReportForm.ConstantCommands.Add(Command.Name, Handler);
		Command.Action = "Attachable_Command";
		
		Button = ReportForm.Items.Insert(Command.Name, Type("FormButton"), Folder, BeforeWhatToInsert);
		Button.CommandName = Command.Name;
		Button.OnlyInAllActions = OnlyInAllActions;
		
		If MoreGroup = Undefined Then 
			Continue;
		EndIf;
		
		Button = ReportForm.Items.Insert(Command.Name + "MoreActions", Type("FormButton"), MoreGroup);
		Button.CommandName = Command.Name;
		Button.OnlyInAllActions = True;
	EndDo;
EndProcedure

// Hyperlinks the cell and fills address fields and reference presentations.
//
// Parameters:
//   Cell      - SpreadsheetDocumentRange - spreadsheet document area.
//   HyperlinkAddress - String                          - an address of the hyperlink to be displayed in the specified cell.
//			       Hyperlinks of the following formats automatically open in a standard report form:
//			       "http://<address>", "https://<address>", "e1cib/<address>", "e1c://<address>"
//			       Such hyperlinks are opened using the CommonClient.OpenURL procedure.
//			       See also URLPresentation.URL in Syntax Assistant.
//			       To open hyperlinks of other formats write code in the ReportsClientOverridable.
//			       SpreadsheetDocumentChoiceProcessing procedure.
//   RefPresentation - String, Undefined - description to be displayed in the specified cell.
//                                                If Undefined, HyperlinkAddress is displayed as is.
//
Procedure OutputHyperlink(Cell, HyperlinkAddress, RefPresentation = Undefined) Export
	Cell.Hyperlink = True;
	Cell.Font       = New Font(Cell.Font, , , , , True);
	Cell.TextColor  = StyleColors.HyperlinkColor;
	Cell.Details = HyperlinkAddress;
	Cell.Text       = ?(RefPresentation = Undefined, HyperlinkAddress, RefPresentation);
EndProcedure

// Defines that a report is blank.
//
// Parameters:
//   ReportObject - ReportObject, ExternalReportObject - a report to be checked.
//   DCProcessor - DataCompositionProcessor - an object composing the data in the report.
//
// Returns:
//   Boolean - True if a report is blank. False if a report contains data.
//
Function ReportIsBlank(ReportObject, DCProcessor = Undefined) Export
	If DCProcessor = Undefined Then
		
		If ReportObject.DataCompositionSchema = Undefined Then
			Return False; // Not DCS Report.
		EndIf;
		
		// Objects to create a data composition template.
		DCTemplateComposer = New DataCompositionTemplateComposer;
		
		// Composes a template.
		DCTemplate = DCTemplateComposer.Execute(ReportObject.DataCompositionSchema, ReportObject.SettingsComposer.GetSettings());
		
		// Skip the check whether the report is empty.
		If ThereIsExternalDataSet(DCTemplate.DataSets) Then
			Return False;
		EndIf;
		
		// Object that composes data.
		DCProcessor = New DataCompositionProcessor;
		
		// Initialize an object.
		DCProcessor.Initialize(DCTemplate, , , True);
		
	Else
		
		// Stand at the beginning of the composition.
		DCProcessor.Reset();
		
	EndIf;
	
	// The object to output a composition result to the spreadsheet document.
	DCResultOutputProcessor = New DataCompositionResultSpreadsheetDocumentOutputProcessor;
	
	// Determines the spreadsheet document in which the result has to be displayed.
	DCResultOutputProcessor.SetDocument(New SpreadsheetDocument);
	
	// Sequential output
	DCResultOutputProcessor.BeginOutput();
	
	// Gets the next item of the composition result.
	DCResultItem = DCProcessor.Next();
	While DCResultItem <> Undefined Do
		
		// Output the item of the report composition result into the document.
		DCResultOutputProcessor.OutputItem(DCResultItem);
		
		// Determine a non-empty result.
		For Each DCTemplateParameterValue In DCResultItem.ParameterValues Do
			Try
				ValueIsFilled = ValueIsFilled(DCTemplateParameterValue.Value);
			Except
				ValueIsFilled = False; // Line, Border, Color and other DC objects which can appear on the output.
			EndTry;
			If ValueIsFilled Then
				DCResultOutputProcessor.EndOutput();
				Return False;
			EndIf;
		EndDo;
		
		Try
			// Gets the next item of the composition result.
			DCResultItem = DCProcessor.Next();
		Except
			Return False;
		EndTry;
		
	EndDo;
	
	// Indicate to the object that the output of the result is complete.
	DCResultOutputProcessor.EndOutput();
	
	Return True;
EndFunction

// The wizard of group items properties of user settings form.
//
// Returns:
//   Structure - contains property values of the group:
//    * Presentation - UsualGroupPresentation - see the UsualGroupPresentation syntax assistant. 
//    * Grouping - ChildFormItemsGroup - values determine the number of groups that are item columns:
//       
//       ** Vertical - ChildFormItemsGroup - equals to one column.
//       ** HorizontalIfPossible - ChildFormItemsGroup - equals to two columns.
//       ** AlwaysHorizontal - ChildFormItemsGroup - the number of columns equals to the number of 
//                                                                        items in the group.
//
Function FormItemsGroupProperties() Export 
	GroupProperties = New Structure;
	GroupProperties.Insert("Representation", UsualGroupRepresentation.None);
	GroupProperties.Insert("Group", ChildFormItemsGroup.HorizontalIfPossible);
	
	Return GroupProperties;
EndFunction

#EndRegion

#Region Internal

Procedure UpdateSettingsFormItems(Form, ItemsHierarchyNode, UpdateParameters = Undefined) Export 
	If Common.IsMobileClient() Then 
		Form.CreateUserSettingsFormItems(ItemsHierarchyNode);
		Return;
	EndIf;
	
	Items = Form.Items;
	ReportSettings = Form.ReportSettings;
	
	StyylizedItemsKinds = StrSplit("Period, List, CheckBox", ", ", False);
	AttributesNames = SettingsItemsAttributesNames(Form, StyylizedItemsKinds);
	
	PrepareFormToRegroupItems(Form, ItemsHierarchyNode, AttributesNames, StyylizedItemsKinds);
	
	TemporaryGroup = Items.Add("Temporary", Type("FormGroup"));
	TemporaryGroup.Type = FormGroupType.UsualGroup;
	
	Mode = DataCompositionSettingsViewMode.QuickAccess;
	If Form.ReportFormType = ReportFormType.Settings Then 
		Mode = DataCompositionSettingsViewMode.All;
	EndIf;
	
	Form.CreateUserSettingsFormItems(TemporaryGroup, Mode, 1);
	
	ItemsProperties = SettingsFormItemsProperties(
		Form.ReportFormType, Form.Report.SettingsComposer, ReportSettings);
	
	RegroupSettingsFormItems(
		Form, ItemsHierarchyNode, ItemsProperties, AttributesNames, StyylizedItemsKinds);
	
	Items.Delete(TemporaryGroup);
	
	// Call an overridable module.
	If ReportSettings.Events.AfterQuickSettingsBarFilled Then
		ReportObject = ReportObject(ReportSettings.FullName);
		ReportObject.AfterQuickSettingsBarFilled(Form, UpdateParameters);
	EndIf;
EndProcedure

Function AvailableSettings(ImportParameters, ReportSettings) Export 
	Settings = Undefined;
	UserSettings = Undefined;
	FixedSettings = Undefined;
	
	If ImportParameters.Property("DCSettingsComposer") Then
		Settings = ImportParameters.DCSettingsComposer.Settings;
		UserSettings = ImportParameters.DCSettingsComposer.UserSettings;
		FixedSettings = ImportParameters.DCSettingsComposer.FixedSettings;
	Else
		If ImportParameters.Property("DCSettings") Then
			Settings = ImportParameters.DCSettings;
		EndIf;
		If ImportParameters.Property("DCUserSettings") Then
			UserSettings = ImportParameters.DCUserSettings;
		EndIf;
	EndIf;
	
	If ReportSettings.Events.BeforeImportSettingsToComposer Then
		XMLSettings = CommonClientServer.StructureProperty(ReportSettings, "NewXMLSettings");
		If TypeOf(XMLSettings) = Type("String") Then
			Try
				Settings = Common.ValueFromXMLString(XMLSettings);
			Except
				Settings = Undefined;
			EndTry;
			ReportSettings.NewXMLSettings = Undefined;
		EndIf;
		
		UserXMLSettings = CommonClientServer.StructureProperty(ReportSettings, "NewUserXMLSettings");
		If TypeOf(UserXMLSettings) = Type("String") Then
			Try
				UserSettings = Common.ValueFromXMLString(UserXMLSettings);
			Except
				UserSettings = Undefined;
			EndTry;
			ReportSettings.NewUserXMLSettings = Undefined;
		EndIf;
	EndIf;
	
	Return New Structure("Settings, UserSettings, FixedSettings",
		Settings, UserSettings, FixedSettings);
EndFunction

Procedure SetAvailableValues(Report, Form) Export 
	SettingsComposer = Form.Report.SettingsComposer;
	
	UserSettings = SettingsComposer.UserSettings;
	For Each UserSettingItem In UserSettings.Items Do 
		If TypeOf(UserSettingItem) <> Type("DataCompositionSettingsParameterValue")
			AND TypeOf(UserSettingItem) <> Type("DataCompositionFilterItem") Then 
			Continue;
		EndIf;
		
		SettingItem = ReportsClientServer.GetObjectByUserID(
			SettingsComposer.Settings,
			UserSettingItem.UserSettingID,,
			UserSettings);
		
		SettingDetails = ReportsClientServer.FindAvailableSetting(SettingsComposer.Settings, SettingItem);
		
		SettingProperties = UserSettingsItemProperties(
			SettingsComposer, UserSettingItem, SettingItem, SettingDetails);
		
		// Extension functionality.
		// Global settings of type output.
		ReportsOverridable.OnDefineSelectionParameters(Undefined, SettingProperties);
		// Local override for a report.
		If Form.ReportSettings.Events.OnDefineSelectionParameters Then 
			Report.OnDefineSelectionParameters(Form, SettingProperties);
		EndIf;
		
		// Automatic filling.
		If SettingProperties.SelectionValuesQuery.Text <> "" Then
			ValuesToAdd = SettingProperties.SelectionValuesQuery.Execute().Unload().UnloadColumn(0);
			For Each Item In ValuesToAdd Do
				ReportsClientServer.AddUniqueValueToList(
					SettingProperties.ValuesForSelection, Item, Undefined, False);
			EndDo;
			SettingProperties.ValuesForSelection.SortByPresentation(SortDirection.Asc);
		EndIf;
		
		If TypeOf(SettingProperties.ValuesForSelection) = Type("ValueList")
			AND SettingProperties.ValuesForSelection.Count() > 0 Then 
			SettingDetails.AvailableValues = SettingProperties.ValuesForSelection;
		EndIf;
	EndDo;
EndProcedure

Function IsTechnicalObject(Val FullObjectName) Export
	
	Return FullObjectName = Upper("Catalog.PredefinedExtensionsReportsOptions")
		Or FullObjectName = Upper("Catalog.PredefinedReportsOptions");
	
EndFunction

#EndRegion

#Region Private

////////////////////////////////////////////////////////////////////////////////
// Analysis

// Returns information on composer settings.
//  After completing setting operations, call ClearAdvancedInformationOnSettings to clear cyclic 
//  references for correct clearing of memory.
//
// Calls (6):
//  1. CommonModule.ReportsOptions.ReduceQuickSettingsNumber()
//     * Only the UserSettings property is used.
//     * It is a parameter of the ReportsServer.ClearAdvancedInformationOnSettings() method being called.
//  2. SettingsStorage.ReportsOptionsStorageForm.ReportFiltersConditions.OnCreateAtServer()
//     * Only the UserSettings property is used.
//     * It is a parameter of the ReportsServer.ClearAdvancedInformationOnSettings() method being called.
//  3. CommonForm.ReportSettingsForm:
//    3.1. QuickSettingsFill()
//         * It is used to the full extent.
//    3.2. ClearSettingsFromNonExistingFieldsAtServer()
//         * Used properties: OptionTree, OptionSettings.
//  4. CommonForm.ReportForm.QuickSettingsFill()
//     * Used properties: MetadataObjectNamesMap, Links, UserSettings.
//  5. Report.QuickReportsSettings.ObjectModule.AnalyseUserSettings()
//     * Only the UserSettings property is used.
//
// Parameters:
//  DCSettingsComposer - DataCompositionSettingsComposer - Report.SettingsComposer.
//                          Report property.
//  ReportSettings - Structure - see ReportsOptions.ReportFormSettings(). 
//                    Contains report properties. It is stored in form (report, settings) attribute.
//  ReportObjectOrFullName - ReportObject, String - an object of the report being composed or its full metadata name.
//  OutputConditions - Structure, Undefined - additional flags:
//                  * UserSettingsOnly - Boolean.
//                  * QuickSettingsOnly - Boolean.
//                  * CurrentDCNodeID - DataCompositionID, Undefined - an ID of the current setting.
//
// Returns:
//   Structure - contains:
//               * UserSettingsOnly - Boolean.
//               * QuickSettingsOnly - Boolean.
//               * CurrentDCNodeID - DataCompositionID, Undefined - an ID of the current setting.
//               * DCSettings - DataCompositionSettings - see the DataCompositionSettingsComposer. Settings Syntax Assistant.
//               * ReportSettings - Structure - see ReportsOptions.ReportFormSettings(). 
//               * ReportObjectOrFullName - ReportObject, String - an object of the report being composed or its full metadata name.
//               * OptionTree - ValuesTree - see ReportsServer.OptionTree(). 
//                                  Stores properties and flags of data composition settings and all its structure hierarchy.
//               * OptionSettings - ValuesTree - see ReportsServer.OptionSettingsTable(). 
//                                     Stores a reference to each row of the OptionTree initialized 
//                                     earlier, as well as properties and flags of the corresponding setting collections: Filter, Order and so on.
//               * UserSettings - ValueTables - see ReportsServer.UserSettingsTable(). 
//                                             Stores a reference to each row of the OptionTree initialized earlier,
//                                             as well as properties and flagsby each user setting.
//                                             
//               * LinksThatCanBeDisabled - Array:
//                                    * ByType - ValueTables - see ReportsServer. TableOfLinksByType().
//                                               Stores a reference to tree row of the OptionTree 
//                                               property initialized earlier and values of the 
//                                               LinkByType edit parameter properties of available filter fields and data composition settings parameters.
//                                    * ChoiceParameters - ValueTables - see ReportsServer. ChoiceParametersLinksTable().
//                                                         Stores a reference to tree row of the 
//                                                         OptionTree property initialized earlier 
//                                                         and values of the ChoiceParametersLinks 
//                                                         edit parameter properties of available filter fields and data composition settings parameters.
//                                    * MetadataObjects - ValueTables - see ReportsServer. MetadataObjectsLinksTable().
//               * AdditionalItemsSettings - Map - it is stored in DataCompositionSettingsComposer.
//                                                    UserSettings.AdditionalProperties by the FormItems key:
//                                                    * Key - String - derived from the user setting 
//                                                             UUID. It is a part of the control 
//                                                             referring to a user setting.
//                                                    * Value - Structure - user setting properties.
//               * MetadataObjectNamesMap - Map - contains:
//                                                      * Key - Type - a reference type.
//                                                      * Value - String - a full name of a metadata 
//                                                                            object that maps the current key.
//               * Search - Structure - contains:
//                         * OptionSettingsByDCField - Map:
//                                                       * Key - DataCompositionField.
//                                                       * Value - ValueTreeRow - a reference to a 
//                                                           tree row of the OptionTree property initialized earlier.
//                         * UserSettings - Map.
//                                                       * Key - String - derived from the user 
//                                                                setting UUID. It is a part of the 
//                                                                control referring to a user setting.
//                                                       * Value - ValueTableRow - a reference to a 
//                                                                    value table row of the UserSettings property initialised earlier.
//               * HasQuickSettings - Boolean - True if at least one of user settings
//                                        DisplayMode = DataCompositionSettingItemDisplayMode.
//                                        QuickAccess or DisplayMode = DataCompositionSettingItemDisplayMode.Auto.
//               * HasRegularSettings - Boolean - True if at least one of user settings
//                                        DisplayMode = DataCompositionSettingItemDisplayMode.Regular.
//               * HasNonexistingFields - Boolean - indicates that field is missing in available fields.
//               * HasNestedReports - Boolean - indicates that at least one setting item has the DataCompositionNestedObjectSettings type.
//               * HasNestedAppearance - Boolean - see Syntax Assistant - DataCompositionSettings. ItemHasConditionalAppearance().
//               * HasNestedFields - Boolean - see Syntax Assistant - DataCompositionSettings. ItemHasChoice().
//               * HasNestedSorting - Boolean - see Syntax Assistant - DataCompositionSettings. ItemHasOrder().
//               * ItemsGroupsProperties - Structure - see ReportsServer.FormItemsGroupProperties()  
//                                          - settings of the items group of default quick settings (displayed on the form).
//               * ItemsGroups - Map - a collection for setting private properties of item groups of quick settings.
//               * OptionTreeRootRow - ValuesTreeRow - a reference to a row of the OptionTree tree 
//                                                initialised earlier that matches the current setting item.
//
Function AdvancedInformationOnSettings(DCSettingsComposer, ReportSettings, ReportObjectOrFullName, OutputConditions = Undefined) Export
	DCSettings = DCSettingsComposer.Settings;
	DCUserSettings = DCSettingsComposer.UserSettings;
	
	AdditionalItemsSettings = CommonClientServer.StructureProperty(DCUserSettings.AdditionalProperties, "FormItems");
	If AdditionalItemsSettings = Undefined Then
		AdditionalItemsSettings = New Map;
	EndIf;
	
	Information = New Structure;
	Information.Insert("UserSettingsOnly", False);
	Information.Insert("QuickSettingsOnly", False);
	Information.Insert("CurrentDCNodeID", Undefined);
	If OutputConditions <> Undefined Then
		FillPropertyValues(Information, OutputConditions);
	EndIf;
	
	Information.Insert("DCSettings", DCSettings);
	
	Information.Insert("ReportSettings",           ReportSettings);
	Information.Insert("ReportObjectOrFullName",   ReportObjectOrFullName);
	Information.Insert("OptionTree",            OptionTree());
	Information.Insert("OptionSettings",         OptionSettingsTable());
	Information.Insert("UserSettings", UserSettingsTable());
	
	Information.Insert("LinksThatCanBeDisabled", New Array);
	Information.Insert("Links", New Structure);
	Information.Links.Insert("ByType",             TableOfLinksByType());
	Information.Links.Insert("SelectionParameters",   ChoiceParametersLinksTable());
	Information.Links.Insert("MetadataObjects", MetadataObjectsLinksTable(ReportSettings, Information.ReportObjectOrFullName));
	
	Information.Insert("AdditionalItemsSettings",   AdditionalItemsSettings);
	Information.Insert("MetadataObjectNamesMap", New Map);
	Information.Insert("Search", New Structure);
	Information.Search.Insert("OptionSettingsByDCField", New Map);
	Information.Search.Insert("UserSettings", New Map);
	Information.Insert("HasQuickSettings", False);
	Information.Insert("HasRegularSettings", False);
	Information.Insert("HasNonexistingFields", False);
	
	Information.Insert("HasNestedReports", False);
	Information.Insert("HasNestedFilters", False);
	Information.Insert("HasNestedAppearance", False);
	Information.Insert("HasNestedFields", False);
	Information.Insert("HasNestedSorting", False);
	
	// Settings of the items group of default quick settings (displayed on the form).
	Information.Insert("ItemsGroupsProperties", FormItemsGroupProperties());
	// The collection for setting private properties of item groups of quick settings.
	Information.Insert("ItemsGroups", New Map);
	
	For Each DCUserSetting In DCUserSettings.Items Do
		SettingProperties = Information.UserSettings.Add();
		SettingProperties.DCUserSetting = DCUserSetting;
		SettingProperties.ID               = DCUserSetting.UserSettingID;
		SettingProperties.IndexInCollection = DCUserSettings.Items.IndexOf(DCUserSetting);
		SettingProperties.DCID  = DCUserSettings.GetIDByObject(DCUserSetting);
		SettingProperties.Type              = ReportsClientServer.SettingTypeAsString(TypeOf(DCUserSetting));
		Information.Search.UserSettings.Insert(SettingProperties.ID, SettingProperties);
		
		// Default title location.
		SettingProperties.TitleLocation = FormItemTitleLocation.Auto;
	EndDo;
	
	TreeRow = RegisterOptionTreeNode(Information, DCSettings, DCSettings, Information.OptionTree.Rows, "Report");
	TreeRow.Global = True;
	Information.Insert("OptionTreeRootRow", TreeRow);
	If Information.CurrentDCNodeID = Undefined Then
		Information.CurrentDCNodeID = TreeRow.DCID;
		If Not Information.UserSettingsOnly Then
			TreeRow.OutputAllowed = True;
		EndIf;
	EndIf;
	
	RegisterOptionSettings(DCSettings, Information);
	RegisterLinksFromMasterItems(Information);
	
	Return Information;
EndFunction

// Clear from circular references to release memory.
Procedure ClearAdvancedInformationOnSettings(InformationOnSettings) Export
	
	ClearValueTree(InformationOnSettings.OptionTree);
	ClearValueTree(InformationOnSettings.OptionSettings);
	InformationOnSettings.Search.Clear();
	InformationOnSettings.UserSettings.Columns.Clear();
	InformationOnSettings.Links.Clear();
	InformationOnSettings.Clear();

EndProcedure

// Clear the value tree from circular references to release memory.
//
Procedure ClearValueTree(Val Tree)
	
	TreeRows = Tree.Rows;
	ColumnsToClear = New Array;
	ColumnIndex = 0;
	For each TreeColumn In Tree.Columns Do
		If TreeColumn.ValueType <> New TypeDescription("String")
			AND TreeColumn.ValueType <> New TypeDescription("Boolean")
			AND TreeColumn.ValueType <> New TypeDescription("Number") 
			AND TreeColumn.ValueType <> New TypeDescription("Date") Then
			ColumnsToClear.Add(ColumnIndex);
		EndIf;	
		ColumnIndex = ColumnIndex + 1;
	EndDo;
	
	If ColumnsToClear.Count() = 0 Then
		Return;
	EndIf;
	
	For each TreeRow In TreeRows Do
		ClearValueTreeRows(TreeRow.Rows, ColumnsToClear);
	EndDo;
	Tree.Columns.Clear();
	
EndProcedure

Procedure ClearValueTreeRows(Val TreeRows, Val ColumnsToClear)
	
	For each TreeRow In TreeRows Do
		ClearValueTreeRows(TreeRow.Rows, ColumnsToClear);
	EndDo;
	
	For each TreeRow In TreeRows Do
		For each Column In ColumnsToClear Do
			TreeRow[Column] = Undefined;
		EndDo;	
	EndDo;
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Option tree

Function OptionTree()
	Result = New ValueTree;
	
	// DCS nodes.
	Result.Columns.Add("DCNode");
	Result.Columns.Add("AvailableDCSetting");
	Result.Columns.Add("DCUserSetting");
	
	// Application structure.
	Result.Columns.Add("UserSetting");
	
	// Search for this setting in a node.
	Result.Columns.Add("DCID");
	
	// A link with DCS nodes.
	Result.Columns.Add("ID", New TypeDescription("String"));
	
	// Setting type.
	Result.Columns.Add("Type", New TypeDescription("String"));
	Result.Columns.Add("Subtype", New TypeDescription("String"));
	Result.Columns.Add("State", New TypeDescription("String"));
	
	Result.Columns.Add("HasStructure", New TypeDescription("Boolean"));
	Result.Columns.Add("HasFieldsAndDecorations", New TypeDescription("Boolean"));
	Result.Columns.Add("Global", New TypeDescription("Boolean"));
	
	// Setting content.
	Result.Columns.Add("ContainsFilters", New TypeDescription("Boolean"));
	Result.Columns.Add("ContainsFields", New TypeDescription("Boolean"));
	Result.Columns.Add("ContainsSorting", New TypeDescription("Boolean"));
	Result.Columns.Add("ContainsConditionalAppearance", New TypeDescription("Boolean"));
	
	// Output.
	Result.Columns.Add("Presentation", New TypeDescription("String"));
	Result.Columns.Add("DefaultPresentation", New TypeDescription("String"));
	Result.Columns.Add("Title", New TypeDescription("String"));
	Result.Columns.Add("OutputAllowed", New TypeDescription("Boolean"));
	Result.Columns.Add("OutputFlagOnly", New TypeDescription("Boolean"));
	
	Return Result;
EndFunction

Function RegisterOptionTreeNode(Information, DCSettings, DCNode, TreeRowsSet, Subtype = "")
	TreeRow = TreeRowsSet.Add();
	TreeRow.DCNode = DCNode;
	TreeRow.Type = ReportsClientServer.SettingTypeAsString(TypeOf(DCNode));
	TreeRow.Subtype = Subtype;
	If TreeRow.Type <> "Settings" Then
		TreeRow.ID = DCNode.UserSettingID;
	EndIf;
	
	TreeRow.DCID = DCSettings.GetIDByObject(DCNode);
	TreeRow.Global = (Subtype = "Report");
	
	If TreeRow.Type = "Settings" Then
		TreeRow.HasStructure = True;
		TreeRow.HasFieldsAndDecorations = True;
	ElsIf TreeRow.Type = "Group"
		Or TreeRow.Type = "ChartGroup"
		Or TreeRow.Type = "TableGroup" Then
		TreeRow.HasStructure = True;
		TreeRow.HasFieldsAndDecorations = True;
	ElsIf TreeRow.Type = "Table" Then
		TreeRow.HasFieldsAndDecorations = True;
	ElsIf TreeRow.Type = "Chart" Then
		TreeRow.HasFieldsAndDecorations = True;
	ElsIf TreeRow.Type = "NestedObjectSettings" Then
		TreeRow.AvailableDCSetting = DCSettings.AvailableObjects.Items.Find(DCNode.ObjectID);
	ElsIf TreeRow.Type = "TableStructureItemCollection"
		Or TreeRow.Type = "ChartStructureItemCollection" Then
		// see below.
	Else
		Return TreeRow;
	EndIf;
	
	FillSettingPresentationAndState(
		TreeRow,
		TreeRow.DCNode,
		Undefined,
		TreeRow.AvailableDCSetting);
	
	If TreeRow.HasFieldsAndDecorations Then
		TreeRow.Title = TitleFromOutputParameters(DCNode.OutputParameters);
		TreeRow.ContainsFields               = DCSettings.HasItemSelection(DCNode);
		TreeRow.ContainsConditionalAppearance = DCSettings.HasItemConditionalAppearance(DCNode);
	EndIf;
	
	If Not Information.QuickSettingsOnly Then
		TreeRow.OutputAllowed = (TreeRow.DCID = Information.CurrentDCNodeID);
	EndIf;
	
	If TypeOf(TreeRow.ID) = Type("String") AND Not IsBlankString(TreeRow.ID) Then
		SettingProperties = Information.Search.UserSettings.Get(TreeRow.ID);
		If SettingProperties <> Undefined Then
			TreeRow.UserSetting   = SettingProperties;
			TreeRow.DCUserSetting = SettingProperties.DCUserSetting;
			RegisterUserSetting(Information, SettingProperties, TreeRow, Undefined);
			If ValueIsFilled(TreeRow.Title) Then
				SettingProperties.Presentation = TreeRow.Title;
			EndIf;
			If Information.UserSettingsOnly Then
				TreeRow.OutputAllowed = SettingProperties.OutputAllowed;
				TreeRow.State = SettingProperties.State;
			EndIf;
		EndIf;
	EndIf;
	
	If TreeRow.HasStructure Then
		For Each NestedItem In DCNode.Structure Do
			RegisterOptionTreeNode(Information, DCSettings, NestedItem, TreeRow.Rows);
		EndDo;
		TreeRow.ContainsFilters     = DCSettings.HasItemFilter(DCNode);
		TreeRow.ContainsSorting = DCSettings.HasItemOrder(DCNode);
	EndIf;
	
	If TreeRow.Type = "Table" Then
		RegisterOptionTreeNode(Information, DCSettings, DCNode.Rows, TreeRow.Rows, "TableRows");
		RegisterOptionTreeNode(Information, DCSettings, DCNode.Columns, TreeRow.Rows, "ColumnsTable");
	ElsIf TreeRow.Type = "Chart" Then
		RegisterOptionTreeNode(Information, DCSettings, DCNode.Points, TreeRow.Rows, "ChartPoints");
		RegisterOptionTreeNode(Information, DCSettings, DCNode.Series, TreeRow.Rows, "ChartSeries");
	ElsIf TreeRow.Type = "TableStructureItemCollection"
		Or TreeRow.Type = "ChartStructureItemCollection" Then
		For Each NestedItem In DCNode Do
			RegisterOptionTreeNode(Information, DCSettings, NestedItem, TreeRow.Rows);
		EndDo;
	ElsIf TreeRow.Type = "NestedObjectSettings" Then
		Information.HasNestedReports = True;
		RegisterOptionTreeNode(Information, DCSettings, DCNode.Settings, TreeRow.Rows);
	EndIf;
	
	If Not TreeRow.Global Then
		If TreeRow.ContainsFields Then
			Information.HasNestedFields = True;
		EndIf;
		If TreeRow.ContainsConditionalAppearance Then
			Information.HasNestedAppearance = True;
		EndIf;
		If TreeRow.ContainsFilters Then
			Information.HasNestedFilters = True;
		EndIf;
		If TreeRow.ContainsSorting Then
			Information.HasNestedSorting = True;
		EndIf;
	EndIf;
	
	Return TreeRow;
EndFunction

Function TitleFromOutputParameters(OutputParameters)
	OutputDCTitle = OutputParameters.FindParameterValue(New DataCompositionParameter("OutputTitle"));
	If OutputDCTitle = Undefined Then
		Return "";
	EndIf;
	If OutputDCTitle.Use = True
		AND OutputDCTitle.Value = DataCompositionTextOutputType.DontOutput Then
		Return "";
	EndIf;
	// In the Auto value, it is considered that the header is displayed.
	// When the OutputTitle parameter is disabled, this is an equivalent to the Auto value.
	DCTitle = OutputParameters.FindParameterValue(New DataCompositionParameter("Title"));
	If DCTitle = Undefined Then
		Return "";
	EndIf;
	Return DCTitle.Value;
EndFunction

////////////////////////////////////////////////////////////////////////////////
// Option settings

Function OptionSettingsTable()
	Result = New ValueTree;
	
	// DCS nodes.
	Result.Columns.Add("DCItem");
	Result.Columns.Add("AvailableDCSetting");
	Result.Columns.Add("DCUserSetting");
	
	// Application structure.
	Result.Columns.Add("TreeRow");
	Result.Columns.Add("UserSetting");
	Result.Columns.Add("Owner");
	Result.Columns.Add("Global", New TypeDescription("Boolean"));
	
	// Search for this setting in a node.
	Result.Columns.Add("CollectionName", New TypeDescription("String"));
	Result.Columns.Add("DCID");
	
	// A link with DCS nodes.
	Result.Columns.Add("ID", New TypeDescription("String"));
	Result.Columns.Add("ItemID", New TypeDescription("String"));
	
	// A setting description.
	Result.Columns.Add("Type", New TypeDescription("String"));
	Result.Columns.Add("Subtype", New TypeDescription("String"));
	Result.Columns.Add("State", New TypeDescription("String"));
	
	Result.Columns.Add("DCField");
	Result.Columns.Add("Value");
	Result.Columns.Add("ComparisonType");
	Result.Columns.Add("ListInput", New TypeDescription("Boolean"));
	Result.Columns.Add("TypesInformation");
	Result.Columns.Add("ChoiceForm", New TypeDescription("String"));
	
	Result.Columns.Add("MarkedValues");
	Result.Columns.Add("ChoiceParameters");
	
	Result.Columns.Add("TypeLink");
	Result.Columns.Add("ChoiceParameterLinks");
	Result.Columns.Add("MetadataRelations");
	Result.Columns.Add("TypeRestriction");
	
	// API
	Result.Columns.Add("TypeDescription");
	Result.Columns.Add("ValuesForSelection");
	Result.Columns.Add("SelectionValuesQuery");
	Result.Columns.Add("ValueListRedefined",           New TypeDescription("Boolean"));
	Result.Columns.Add("QuickChoice",                          New TypeDescription("Boolean"));
	Result.Columns.Add("RestrictSelectionBySpecifiedValues", New TypeDescription("Boolean"));
	Result.Columns.Add("EventOnChange", New TypeDescription("Boolean"));
	Result.Columns.Add("Width", New TypeDescription("Number"));
	Result.Columns.Add("OutputInMainSettingsGroup", New TypeDescription("Boolean"));
	
	// Output.
	Result.Columns.Add("DefaultPresentation", New TypeDescription("String"));
	Result.Columns.Add("Presentation", New TypeDescription("String"));
	Result.Columns.Add("OutputAllowed", New TypeDescription("Boolean"));
	Result.Columns.Add("OutputFlag", New TypeDescription("Boolean"));
	Result.Columns.Add("ChoiceFoldersAndItems");
	Result.Columns.Add("OutputFlagOnly", New TypeDescription("Boolean"));
	
	Return Result;
EndFunction

Function UserSettingsTable()
	Result = New ValueTable;
	
	// DCS nodes.
	Result.Columns.Add("DCNode");
	Result.Columns.Add("DCOptionSetting");
	Result.Columns.Add("DCUserSetting");
	Result.Columns.Add("AvailableDCSetting");
	
	// Application structure.
	Result.Columns.Add("TreeRow");
	Result.Columns.Add("OptionSetting");
	
	// Search for this setting in a node.
	Result.Columns.Add("DCID");
	Result.Columns.Add("IndexInCollection", New TypeDescription("Number"));
	
	// A link with DCS nodes.
	Result.Columns.Add("ID", New TypeDescription("String"));
	Result.Columns.Add("ItemID", New TypeDescription("String"));
	
	// A setting description.
	Result.Columns.Add("Type", New TypeDescription("String"));
	Result.Columns.Add("Subtype", New TypeDescription("String"));
	Result.Columns.Add("State", New TypeDescription("String"));
	
	Result.Columns.Add("DCField");
	Result.Columns.Add("Value");
	Result.Columns.Add("ComparisonType");
	Result.Columns.Add("ListInput", New TypeDescription("Boolean"));
	Result.Columns.Add("TypesInformation");
	
	Result.Columns.Add("MarkedValues");
	Result.Columns.Add("ChoiceParameters");
	
	// API
	Result.Columns.Add("TypeDescription");
	Result.Columns.Add("ValuesForSelection");
	Result.Columns.Add("SelectionValuesQuery");
	Result.Columns.Add("QuickChoice",                          New TypeDescription("Boolean"));
	Result.Columns.Add("RestrictSelectionBySpecifiedValues", New TypeDescription("Boolean"));
	
	// Output.
	Result.Columns.Add("DefaultPresentation", New TypeDescription("String"));
	Result.Columns.Add("Presentation", New TypeDescription("String"));
	Result.Columns.Add("Quick", New TypeDescription("Boolean"));
	Result.Columns.Add("Ordinary", New TypeDescription("Boolean"));
	Result.Columns.Add("OutputAllowed", New TypeDescription("Boolean"));
	Result.Columns.Add("OutputFlag", New TypeDescription("Boolean"));
	Result.Columns.Add("OutputFlagOnly", New TypeDescription("Boolean"));
	
	// The name of the item group to which the quick setting will be subordinate.
	Result.Columns.Add("ItemsGroup", New TypeDescription("String"));
	// Property that determines behavior of the quick setting item title.
	Result.Columns.Add("TitleLocation", New TypeDescription("FormItemTitleLocation"));
	
	Result.Columns.Add("ItemsType", New TypeDescription("String"));
	Result.Columns.Add("ChoiceFoldersAndItems");
	
	// Additional properties.
	Result.Columns.Add("More", New TypeDescription("Structure"));
	
	Return Result;
EndFunction

Function TableOfLinksByType()
	// Links from DCS.
	TableOfLinksByType = New ValueTable;
	TableOfLinksByType.Columns.Add("Master");
	TableOfLinksByType.Columns.Add("MasterDCField");
	TableOfLinksByType.Columns.Add("SubordinateSettingsItem");
	TableOfLinksByType.Columns.Add("SubordinateParameterName");
	
	Return TableOfLinksByType;
EndFunction

Function ChoiceParametersLinksTable()
	LinksTable = New ValueTable;
	LinksTable.Columns.Add("Master");
	LinksTable.Columns.Add("MasterDCField");
	LinksTable.Columns.Add("SubordinateSettingsItem");
	LinksTable.Columns.Add("SubordinateParameterName");
	LinksTable.Columns.Add("Action");
	
	Return LinksTable;
EndFunction

Function MetadataObjectsLinksTable(ReportSettings, ReportObjectOrFullName)
	// Links from metadata.
	Result = New ValueTable;
	Result.Columns.Add("MainType",          New TypeDescription("Type"));
	Result.Columns.Add("SubordinateType",      New TypeDescription("Type"));
	Result.Columns.Add("SubordinateAttribute", New TypeDescription("String"));
	
	// Extension functionality.
	ReportsOverridable.AddMetadataObjectsConnections(Result); // Global links...
	If ReportSettings.Events.AddMetadataObjectsConnections Then // ... can be locally overridden for a report.
		ReportObject(ReportObjectOrFullName).AddMetadataObjectsConnections(Result);
	EndIf;
	
	Result.Columns.Add("HasParent",     New TypeDescription("Boolean"));
	Result.Columns.Add("HasSubordinate", New TypeDescription("Boolean"));
	Result.Columns.Add("LeadingItems",     New TypeDescription("Array"));
	Result.Columns.Add("SubordinateSettingsItems", New TypeDescription("Array"));
	Result.Columns.Add("MasterFullName",     New TypeDescription("String"));
	Result.Columns.Add("SubordinateAttributeFullName", New TypeDescription("String"));
	
	Return Result;
EndFunction

Procedure RegisterOptionSettings(DCSettings, Information)
	
	OptionTree = Information.OptionTree;
	
	FoundItems = OptionTree.Rows.FindRows(New Structure("HasStructure", True), True);
	For Each TreeRow In FoundItems Do
		
		// Settings, Filter property
		// Group, Filter property
		// TableGroup, Filter property.
		// ChartGroup, Filter property.
		
		// Settings, Filter.Items property.
		// Group, Filter.Items property
		// TableGroup, Filter.Items property
		// ChartGroup, Filter.Items property.
		
		RegisterSettingsNode(DCSettings, Information, TreeRow, "Filter");
		
		// Settings, Order property.
		// Group, Order property
		// TableGroup, Order property.
		// ChartGroup, Order property.
		
		RegisterSettingsNode(DCSettings, Information, TreeRow, "Order");
		
		// Settings, Structure property.
		// Group, Structure property.
		// TableGroup, Structure property.
		// ChartGroup, Structure property.
		
		RegisterSettingsNode(DCSettings, Information, TreeRow, "Structure");
		
	EndDo;
	
	FoundItems = OptionTree.Rows.FindRows(New Structure("HasFieldsAndDecorations", True), True);
	For Each TreeRow In FoundItems Do
		
		// Settings, Choice property
		// Table, Choice property
		// Chart, Choice property
		// Group, Choice property
		// ChartGroup, Choice property.
		// TableGroup, Choice property.
		
		RegisterSettingsNode(DCSettings, Information, TreeRow, "Selection");
		
		// Settings, ConditionalAppearance property.
		// Table, ConditionalAppearance property.
		// Chart, ConditionalAppearance property.
		// Group, ConditionalAppearance property.
		// ChartGroup, ConditionalAppearance property.
		// TableGroup, ConditionalAppearance property.
		
		// Settings, ConditionalAppearance.Items property.
		// Table, ConditionalAppearance.Items property.
		// Chart, ConditionalAppearance.Items property.
		// Group, ConditionalAppearance.Items property
		// ChartGroup, ConditionalAppearance.Items property
		// TableGroup,  ConditionalAppearance.Items property.
		
		RegisterSettingsNode(DCSettings, Information, TreeRow, "ConditionalAppearance");
		
		// Settings, OutputParameters property.
		// Table, OutputParameters property.
		// Chart, OutputParameters property.
		// Group, OutputParameters property
		// ChartGroup, OutputParameters property
		// TableGroup, OutputParameters property.
		
		RegisterSettingsNode(DCSettings, Information, TreeRow, "OutputParameters");
		
	EndDo;
	
	FoundItems = OptionTree.Rows.FindRows(New Structure("Type", "Settings"), True);
	For Each TreeRow In FoundItems Do
		
		// Settings, DataParameters property, FindParameterValue() method.
		
		RegisterSettingsNode(DCSettings, Information, TreeRow, "DataParameters");
		
	EndDo;
	
EndProcedure

Procedure RegisterSettingsNode(DCSettings, Information, TreeRow, CollectionName, ItemsSet = Undefined, Parent = Undefined, Owner = Undefined)
	DCNode = TreeRow.DCNode[CollectionName];
	
	Owner = Information.OptionSettings.Rows.Add();
	Owner.TreeRow = TreeRow;
	If CollectionName <> "DataParameters" AND CollectionName <> "OutputParameters" Then
		Owner.ID = DCNode.UserSettingID;
	EndIf;
	Owner.Type           = ReportsClientServer.SettingTypeAsString(TypeOf(DCNode));
	Owner.CollectionName  = CollectionName;
	Owner.Global    = TreeRow.Global;
	Owner.DCItem     = DCNode;
	Owner.OutputAllowed = Not Information.QuickSettingsOnly AND TreeRow.OutputAllowed;
	
	If TypeOf(Owner.ID) = Type("String") AND Not IsBlankString(Owner.ID) Then
		SettingProperties = Information.Search.UserSettings.Get(Owner.ID);
		If SettingProperties <> Undefined Then
			Owner.UserSetting = SettingProperties;
			RegisterUserSetting(Information, SettingProperties, Undefined, Owner);
			SettingProperties.ChoiceParameters = New Array;
			Owner.ChoiceParameters          = New Array;
			Owner.ChoiceParameterLinks    = New Array;
			Owner.MetadataRelations        = New Array;
			If Information.UserSettingsOnly Then
				Owner.OutputAllowed = SettingProperties.OutputAllowed;
			EndIf;
		EndIf;
	EndIf;
	
	If Owner.OutputAllowed Then
		If Owner.UserSetting = Undefined Then
			FillSettingPresentationAndState(
				Owner,
				Owner.DCItem,
				Undefined,
				Undefined);
		Else
			FillPropertyValues(Owner, Owner.UserSetting, "Presentation, OutputFlagOnly");
		EndIf;
	EndIf;
	
	If CollectionName = "Filter"
		Or CollectionName = "DataParameters"
		Or CollectionName = "OutputParameters"
		Or CollectionName = "ConditionalAppearance" Then
		RegisterSettingsItems(Information, DCNode, DCNode.Items, Owner, Owner);
	ElsIf Not Information.QuickSettingsOnly // (Optimization) Fields are sortings are not displayed in quick settings.
		AND (CollectionName = "Order" Or CollectionName = "Selection") Then
		RegisterSettingsItems(Information, DCNode, DCNode.Items, Owner, Owner);
	EndIf;
	
EndProcedure

Procedure RegisterSettingsItems(Information, DCNode, ItemsSet, Owner, Parent)
	HasUnmarkedItems = False;
	HasMarkedItems = False;
	
	For Each DCItem In ItemsSet Do
		OptionSettingsItem = Parent.Rows.Add();
		FillPropertyValues(OptionSettingsItem, Owner, "TreeRow, CollectionName, Global");
		OptionSettingsItem.Type = ReportsClientServer.SettingTypeAsString(TypeOf(DCItem));
		OptionSettingsItem.DCID = DCNode.GetIDByObject(DCItem);
		OptionSettingsItem.Owner = Owner;
		OptionSettingsItem.DCItem = DCItem;
		OptionSettingsItem.OutputAllowed = Not Information.QuickSettingsOnly AND Owner.OutputAllowed;
		OptionSettingsItem.OutputFlag = True;
		
		If OptionSettingsItem.Type = "AutoOrderItem"
			Or OptionSettingsItem.Type = "AutoSelectedField"
			Or OptionSettingsItem.Type = "SelectedFieldsGroup" Then
			// No action required.
		ElsIf OptionSettingsItem.Type = "OrderingItem" Then
			OptionSettingsItem.Value = DCItem.OrderType;
			OptionSettingsItem.DCField = DCItem.Field;
			OptionSettingsItem.AvailableDCSetting = DCNode.OrderAvailableFields.FindField(DCItem.Field);
			If OptionSettingsItem.AvailableDCSetting = Undefined Then
				OptionSettingsItem.State = "DeletionMark";
			EndIf;
		ElsIf OptionSettingsItem.Type = "SelectedField" Then
			OptionSettingsItem.DCField = DCItem.Field;
			OptionSettingsItem.AvailableDCSetting = DCNode.SelectionAvailableFields.FindField(DCItem.Field);
			If OptionSettingsItem.AvailableDCSetting = Undefined Then
				OptionSettingsItem.State = "DeletionMark";
			EndIf;
		Else
			OptionSettingsItem.ID = DCItem.UserSettingID;
		EndIf;
		
		If OptionSettingsItem.Type = "SelectedFields"
			Or OptionSettingsItem.Type = "Order"
			Or OptionSettingsItem.Type = "TableStructureItemCollection"
			Or OptionSettingsItem.Type = "ChartStructureItemCollection"
			Or OptionSettingsItem.Type = "Filter"
			Or OptionSettingsItem.Type = "ConditionalAppearance"
			Or OptionSettingsItem.Type = "SettingsStructure" Then
			OptionSettingsItem.OutputFlag = False;
		EndIf;
		
		SettingProperties = Undefined;
		If TypeOf(OptionSettingsItem.ID) = Type("String") AND Not IsBlankString(OptionSettingsItem.ID) Then
			SettingProperties = Information.Search.UserSettings.Get(OptionSettingsItem.ID);
		EndIf;
		
		If OptionSettingsItem.Type = "FilterItem" Or OptionSettingsItem.Type = "SettingsParameterValue" Then
			// Skipping all DCS settings that are not included in user settings, except for DCS parameters.
			If SettingProperties = Undefined AND Owner.CollectionName <> "DataParameters" Then
				Parent.Rows.Delete(OptionSettingsItem); // As an optimization.
				Continue;
			EndIf;
			RegisterField(Information, DCNode, DCItem, OptionSettingsItem);
			RegisterTypesAndLinks(Information, OptionSettingsItem);
		EndIf;
		
		If SettingProperties <> Undefined Then
			OptionSettingsItem.UserSetting = SettingProperties;
			RegisterUserSetting(Information, SettingProperties, Undefined, OptionSettingsItem);
			If Information.UserSettingsOnly Then
				OptionSettingsItem.OutputAllowed = SettingProperties.OutputAllowed;
				OptionSettingsItem.Value      = SettingProperties.Value;
				OptionSettingsItem.ComparisonType  = SettingProperties.ComparisonType;
			EndIf;
		EndIf;
		
		If OptionSettingsItem.OutputAllowed Then
			FillSettingPresentationAndState(
				OptionSettingsItem,
				OptionSettingsItem.DCItem,
				Undefined,
				OptionSettingsItem.AvailableDCSetting);
			If OptionSettingsItem.State = "DeletionMark" Then
				Information.HasNonexistingFields = True;
				OptionSettingsItem.OutputAllowed = False;
			ElsIf OptionSettingsItem.Type = "FilterItem"
				Or OptionSettingsItem.Type = "SettingsParameterValue" Then
				OnDefineSelectionParameters(Information, OptionSettingsItem);
			EndIf;
		EndIf;
		
		If OptionSettingsItem.Type = "FilterItemsGroup" Then
			OptionSettingsItem.Value = DCItem.GroupType;
			RegisterSettingsItems(Information, DCNode, DCItem.Items, Owner, OptionSettingsItem);
		ElsIf OptionSettingsItem.Type = "SelectedFieldsGroup" Then
			OptionSettingsItem.Value = DCItem.Placement;
			RegisterSettingsItems(Information, DCNode, DCItem.Items, Owner, OptionSettingsItem);
		ElsIf OptionSettingsItem.Type = "SettingsParameterValue" Then
			If SettingProperties <> Undefined Then // As an optimization.
				RegisterSettingsItems(Information, DCNode, DCItem.NestedParameterValues, Owner, OptionSettingsItem);
			EndIf;
		EndIf;
		
		If SettingProperties <> Undefined Then
			SettingProperties.ValuesForSelection = OptionSettingsItem.ValuesForSelection;
			SettingProperties.ChoiceParameters   = OptionSettingsItem.ChoiceParameters;
			SettingProperties.QuickChoice      = OptionSettingsItem.QuickChoice;
			SettingProperties.RestrictSelectionBySpecifiedValues = OptionSettingsItem.RestrictSelectionBySpecifiedValues;
		EndIf;
		
		If OptionSettingsItem.State = "DeletionMark" Then
			Information.HasNonexistingFields = True;
			HasMarkedItems = True;
		Else
			HasUnmarkedItems = True;
		EndIf;
	EndDo;
	
	If HasMarkedItems AND Not HasUnmarkedItems AND Parent <> Owner Then
		Parent.State = "DeletionMark";
	EndIf;
EndProcedure

Procedure RegisterField(Information, DCNode, DCItem, OptionSettingsItem)
	If IsBlankString(OptionSettingsItem.ID) Then
		ID = String(OptionSettingsItem.TreeRow.DCID);
		If Not IsBlankString(ID) Then
			ID = ID + "_";
		EndIf;
		OptionSettingsItem.ID = ID + OptionSettingsItem.CollectionName + "_" + String(OptionSettingsItem.DCID);
	EndIf;
	OptionSettingsItem.ItemID = CastIDToName(OptionSettingsItem.ID);
	
	If OptionSettingsItem.Type = "SettingsParameterValue" Then
		OptionSettingsItem.DCField = New DataCompositionField("DataParameters." + String(DCItem.Parameter));
		AvailableParameters = DCNode.AvailableParameters;
		If AvailableParameters = Undefined Then
			Return;
		EndIf;
		AvailableDCSetting = AvailableParameters.FindParameter(DCItem.Parameter);
		If AvailableDCSetting = Undefined Then
			Return;
		EndIf;
		// AvailableDCSetting has the DataCompositionAvailableParameter type:
		//   Visibility - Boolean - parameter visibility on editing values.
		//   Parameter - DataCompositionParameter - a parameter name.
		//   Value - Arbitrary - the initial value.
		//   ValueListAvailable - Boolean - Можно ли указывать несколько значений.
		//   AvailableValues - ValueList, Undefined - values available for selection.
		//   QuickChoice, ChoiceFoldersAndItems, DenyIncompleteValues,
		//   Use, Mask, TypeLink, ChoiceForm, EditFormat.
		If Not AvailableDCSetting.Visible Then
			OptionSettingsItem.OutputAllowed = False;
		EndIf;
		OptionSettingsItem.AvailableDCSetting = AvailableDCSetting;
		OptionSettingsItem.Value = DCItem.Value;
		If AvailableDCSetting.ValueListAllowed Then
			OptionSettingsItem.ComparisonType = DataCompositionComparisonType.InList;
		Else
			OptionSettingsItem.ComparisonType = DataCompositionComparisonType.Equal;
		EndIf;
		If AvailableDCSetting.Use = DataCompositionParameterUse.Always Then
			OptionSettingsItem.OutputFlag = False;
		EndIf;
	Else
		OptionSettingsItem.DCField       = DCItem.LeftValue;
		OptionSettingsItem.Value     = DCItem.RightValue;
		OptionSettingsItem.ComparisonType = DCItem.ComparisonType;
		FilterAvailableFields = DCNode.FilterAvailableFields;
		If FilterAvailableFields = Undefined Then
			Return;
		EndIf;
		AvailableDCSetting = FilterAvailableFields.FindField(DCItem.LeftValue);
		If AvailableDCSetting = Undefined Then
			Return;
		EndIf;
		// AvailableDCSetting has the DataCompositionFilterAvailableField type.
		OptionSettingsItem.AvailableDCSetting = AvailableDCSetting;
	EndIf;
	
	If OptionSettingsItem.ComparisonType = DataCompositionComparisonType.InList
		Or OptionSettingsItem.ComparisonType = DataCompositionComparisonType.InListByHierarchy
		Or OptionSettingsItem.ComparisonType = DataCompositionComparisonType.NotInList
		Or OptionSettingsItem.ComparisonType = DataCompositionComparisonType.NotInListByHierarchy Then
		OptionSettingsItem.ListInput = True;
		OptionSettingsItem.ChoiceFoldersAndItems = FoldersAndItems.FoldersAndItems;
	ElsIf OptionSettingsItem.ComparisonType = DataCompositionComparisonType.InHierarchy
		Or OptionSettingsItem.ComparisonType = DataCompositionComparisonType.NotInHierarchy Then
		OptionSettingsItem.ChoiceFoldersAndItems = FoldersAndItems.Folders;
	Else
		OptionSettingsItem.ChoiceFoldersAndItems = CastValueToGroupsAndItemsType(AvailableDCSetting.ChoiceFoldersAndItems);
	EndIf;
	
	OptionSettingsItem.TypeDescription = AvailableDCSetting.ValueType;
	OptionSettingsItem.ChoiceForm   = AvailableDCSetting.ChoiceForm;
	OptionSettingsItem.QuickChoice  = AvailableDCSetting.QuickChoice;
	
	If Information.Search.OptionSettingsByDCField.Get(OptionSettingsItem.DCField) = Undefined Then
		Information.Search.OptionSettingsByDCField.Insert(OptionSettingsItem.DCField, OptionSettingsItem);
	EndIf;
	
EndProcedure

Procedure RegisterTypesAndLinks(Information, OptionSettingsItem)
	
	///////////////////////////////////////////////////////////////////
	// Information on types.
	
	OptionSettingsItem.MetadataRelations     = New Array;
	OptionSettingsItem.ChoiceParameterLinks = New Array;
	OptionSettingsItem.ChoiceParameters       = New Array;
	
	If OptionSettingsItem.ListInput Then
		OptionSettingsItem.MarkedValues = ReportsClientServer.ValuesByList(OptionSettingsItem.Value);
	EndIf;
	OptionSettingsItem.SelectionValuesQuery = New Query;
	OptionSettingsItem.ValuesForSelection = New ValueList;
	
	TypesInformation = ExtendedTypesDetails(OptionSettingsItem.TypeDescription, True);
	TypesInformation.Insert("ContainsRefTypes", False);
	TypesInformation.Insert("NumberOfItemsWithQuickAccess", 0);
	AllTypesWithQuickChoice = TypesInformation.TypesCount < 10
		AND (TypesInformation.TypesCount = TypesInformation.ObjectTypes.Count());
	
	For Each Type In TypesInformation.ObjectTypes Do
		MetadataObject = Metadata.FindByType(Type);
		FullName = Information.MetadataObjectNamesMap.Get(Type);
		If FullName = Undefined Then // Registering a metadata object name.
			If MetadataObject = Undefined Then
				FullName = -1;
			Else
				FullName = MetadataObject.FullName();
			EndIf;
			Information.MetadataObjectNamesMap.Insert(Type, FullName);
		EndIf;
		If FullName = -1 Then
			AllTypesWithQuickChoice = False;
			Continue;
		EndIf;
		
		TypesInformation.ContainsRefTypes = True;
		
		If AllTypesWithQuickChoice Then
			Kind = Upper(StrSplit(FullName, ".")[0]);
			If Kind <> "ENUM" Then
				If Kind = "CATALOG"
					Or Kind = "CHARTOFCALCULATIONTYPES"
					Or Kind = "CHARTOFCHARACTERISTICTYPES"
					Or Kind = "EXCHANGEPLAN"
					Or Kind = "CHARTOFACCOUNTS" Then
					If MetadataObject.ChoiceMode <> Metadata.ObjectProperties.ChoiceMode.QuickChoice Then
						AllTypesWithQuickChoice = False;
					EndIf;
				Else
					AllTypesWithQuickChoice = False;
				EndIf;
			EndIf;
		EndIf;
		
		// Search for a type in the global links among subordinates.
		FoundItems = Information.Links.MetadataObjects.FindRows(New Structure("SubordinateType", Type));
		For Each LinkByMetadata In FoundItems Do // Registering a setting as subordinate.
			LinkByMetadata.HasSubordinate = True;
			LinkByMetadata.SubordinateSettingsItems.Add(OptionSettingsItem);
		EndDo;
		
		// Search for a type in the global links among leading.
		If OptionSettingsItem.ComparisonType = DataCompositionComparisonType.Equal Then
			// The field can be leading if it has the "Equal" comparison kind.
			FoundItems = Information.Links.MetadataObjects.FindRows(New Structure("MainType", Type));
			For Each LinkByMetadata In FoundItems Do // Registering a setting as leading.
				LinkByMetadata.HasParent = True;
				LinkByMetadata.LeadingItems.Add(OptionSettingsItem);
			EndDo;
		EndIf;
	EndDo;
	
	// Only enumerations or types with quick selection.
	If AllTypesWithQuickChoice AND TypesInformation.ObjectTypes.Count() = TypesInformation.TypesCount Then
		OptionSettingsItem.QuickChoice = True;
	EndIf;
	
	OptionSettingsItem.TypesInformation = TypesInformation;
	OptionSettingsItem.TypeDescription = TypesInformation.TypesDetailsForForm;
	
	///////////////////////////////////////////////////////////////////
	// Information on selection links and parameters.
	
	AvailableDCSetting = OptionSettingsItem.AvailableDCSetting;
	If AvailableDCSetting = Undefined Then
		Return;
	EndIf;
	
	If ValueIsFilled(AvailableDCSetting.TypeLink) Then
		LinkRow = Information.Links.ByType.Add();
		LinkRow.SubordinateSettingsItem   = OptionSettingsItem;
		LinkRow.MasterDCField = AvailableDCSetting.TypeLink.Field;
		LinkRow.SubordinateParameterName = AvailableDCSetting.TypeLink.LinkItem;
	EndIf;
	
	For Each LinkRow In AvailableDCSetting.GetChoiceParameterLinks() Do
		If IsBlankString(String(LinkRow.Field)) Then
			Continue;
		EndIf;
		ParametersLinkRow = Information.Links.SelectionParameters.Add();
		ParametersLinkRow.SubordinateSettingsItem             = OptionSettingsItem;
		ParametersLinkRow.SubordinateParameterName = StrReplace(LinkRow.Name, "@", "");
		ParametersLinkRow.MasterDCField           = LinkRow.Field;
		ParametersLinkRow.Action                = LinkRow.ValueChange;
	EndDo;
	
	For Each DCChoiceParameters In AvailableDCSetting.GetChoiceParameters() Do
		OptionSettingsItem.ChoiceParameters.Add(New ChoiceParameter(DCChoiceParameters.Name, DCChoiceParameters.Value));
	EndDo;
	
	///////////////////////////////////////////////////////////////////
	// Value list.
	
	If TypeOf(AvailableDCSetting.AvailableValues) = Type("ValueList") Then
		OptionSettingsItem.ValuesForSelection = AvailableDCSetting.AvailableValues;
		OptionSettingsItem.RestrictSelectionBySpecifiedValues = OptionSettingsItem.ValuesForSelection.Count() > 0;
	Else
		EarlierSavedSettings = Information.AdditionalItemsSettings[OptionSettingsItem.ItemID];
		Limit = CommonClientServer.StructureProperty(EarlierSavedSettings, "RestrictSelectionBySpecifiedValues");
		If EarlierSavedSettings <> Undefined AND Limit = False Then
			OldValuesForSelection = CommonClientServer.StructureProperty(EarlierSavedSettings, "ValuesForSelection");
			If TypeOf(OldValuesForSelection) = Type("ValueList") Then
				OptionSettingsItem.ValuesForSelection.ValueType = OptionSettingsItem.TypeDescription;
				For Each OldListItem In OldValuesForSelection Do
					If Not OptionSettingsItem.TypeDescription.ContainsType(TypeOf(OldListItem.Value)) Then
						Continue;
					EndIf;
					If OptionSettingsItem.ValuesForSelection.FindByValue(OldListItem.Value) <> Undefined Then
						Continue;
					EndIf;
					DestinationItem = OptionSettingsItem.ValuesForSelection.Add();
					DestinationItem.Value = OldListItem.Value;
				EndDo;
			EndIf;
		EndIf;
	EndIf;
	
EndProcedure

Procedure OnDefineSelectionParameters(Information, OptionSettingsItem)
	PresentationBefore = String(OptionSettingsItem.ValuesForSelection);
	CountBefore = OptionSettingsItem.ValuesForSelection.Count();
	
	// Extension functionality.
	// Global settings of type output.
	ReportsOverridable.OnDefineSelectionParameters(Undefined, OptionSettingsItem);
	// Local override for a report.
	If Information.ReportSettings.Events.OnDefineSelectionParameters Then
		ReportObject(Information.ReportObjectOrFullName).OnDefineSelectionParameters(Undefined, OptionSettingsItem);
	EndIf;
	
	// Automatic filling.
	If OptionSettingsItem.SelectionValuesQuery.Text <> "" Then
		ValuesToAdd = OptionSettingsItem.SelectionValuesQuery.Execute().Unload().UnloadColumn(0);
		For Each ValueInForm In ValuesToAdd Do
			ReportsClientServer.AddUniqueValueToList(OptionSettingsItem.ValuesForSelection, ValueInForm, Undefined, False);
		EndDo;
		OptionSettingsItem.ValuesForSelection.SortByPresentation(SortDirection.Asc);
	EndIf;
	
	// Deleting values that cannot be selected.
	If OptionSettingsItem.ListInput
		AND OptionSettingsItem.RestrictSelectionBySpecifiedValues
		AND TypeOf(OptionSettingsItem.Value) = Type("ValueList")
		AND TypeOf(OptionSettingsItem.ValuesForSelection) = Type("ValueList") Then
		List = OptionSettingsItem.Value;
		Count = List.Count();
		For Number = 1 To Count Do
			ReverseIndex = Count - Number;
			Value = List[ReverseIndex].Value;
			If OptionSettingsItem.ValuesForSelection.FindByValue(Value) = Undefined Then
				List.Delete(ReverseIndex);
			EndIf;
		EndDo;
	EndIf;
	
	If CountBefore <> OptionSettingsItem.ValuesForSelection.Count()
		Or PresentationBefore <> String(OptionSettingsItem.ValuesForSelection) Then
		OptionSettingsItem.ValueListRedefined = True;
	EndIf;
EndProcedure

Procedure RegisterLinksFromMasterItems(Information)
	Links = Information.Links;
	
	// Register the link of choice parameters (dynamic link disabled by the Usage checkbox).
	FoundItems = Links.MetadataObjects.FindRows(New Structure("HasSubordinate, HasParent", True, True));
	For Each LinkByMetadata In FoundItems Do
		For Each Master In LinkByMetadata.LeadingItems Do
			For Each SubordinateSettingsItem In LinkByMetadata.SubordinateSettingsItems Do
				If Master.OutputAllowed Then // Link to be disabled.
					LinkDetails = New Structure;
					LinkDetails.Insert("LinkType",                "ByMetadata");
					LinkDetails.Insert("Master",                 Master);
					LinkDetails.Insert("SubordinateSettingsItem",             SubordinateSettingsItem);
					LinkDetails.Insert("MainType",              LinkByMetadata.MainType);
					LinkDetails.Insert("SubordinateType",          LinkByMetadata.SubordinateType);
					LinkDetails.Insert("SubordinateParameterName", LinkByMetadata.SubordinateAttribute);
					Information.LinksThatCanBeDisabled.Add(LinkDetails);
					SubordinateSettingsItem.MetadataRelations.Add(LinkDetails);
				Else // Fixed choice parameter.
					SubordinateSettingsItem.ChoiceParameters.Add(New ChoiceParameter(LinkByMetadata.SubordinateAttribute, Master.Value));
				EndIf;
			EndDo;
		EndDo;
	EndDo;
	
	// Links by type.
	For Each LinkByType In Links.ByType Do
		Master = Information.Search.OptionSettingsByDCField.Get(LinkByType.MasterDCField);
		If Master = Undefined Then
			Continue;
		EndIf;
		SubordinateSettingsItem = LinkByType.SubordinateSettingsItem;
		If Master.OutputAllowed Then // Link to be disabled.
			LinkDetails = New Structure;
			LinkDetails.Insert("LinkType",                "ByType");
			LinkDetails.Insert("Master",                 Master);
			LinkDetails.Insert("SubordinateSettingsItem",             SubordinateSettingsItem);
			LinkDetails.Insert("SubordinateParameterName", LinkByType.SubordinateParameterName);
			Information.LinksThatCanBeDisabled.Add(LinkDetails);
			SubordinateSettingsItem.TypeLink = LinkDetails;
		Else // Fixed type restriction.
			TypesArray = New Array;
			TypesArray.Add(TypeOf(Master.Value));
			SubordinateSettingsItem.TypeRestriction = New TypeDescription(TypesArray);
		EndIf;
	EndDo;
	
	// Selection parameters links.
	For Each ChoiceParametersLink In Links.SelectionParameters Do
		Master     = ChoiceParametersLink.Master;
		SubordinateSettingsItem = ChoiceParametersLink.SubordinateSettingsItem;
		If Master = Undefined Then
			BestOption = 99;
			FoundItems = Information.OptionSettings.Rows.FindRows(New Structure("DCField", ChoiceParametersLink.MasterDCField), True);
			For Each PotentialParent In FoundItems Do
				If PotentialParent.Type <> "FilterItem"
					AND PotentialParent.Type <> "SettingsParameterValue" Then
					Continue;
				EndIf;
				If PotentialParent.Parent = SubordinateSettingsItem.Parent Then // Items in one group.
					If Not IsBlankString(PotentialParent.ItemID) Then // Master is displayed to the user.
						Master = PotentialParent;
						BestOption = 0;
						Break; // The best option.
					Else
						Master = PotentialParent;
						BestOption = 1;
					EndIf;
				ElsIf BestOption > 2 AND PotentialParent.Owner = SubordinateSettingsItem.Owner Then // Items in one collection.
					If Not IsBlankString(PotentialParent.ItemID) Then // Master is displayed to the user.
						If BestOption > 2 Then
							Master = PotentialParent;
							BestOption = 2;
						EndIf;
					Else
						If BestOption > 3 Then
							Master = PotentialParent;
							BestOption = 3;
						EndIf;
					EndIf;
				ElsIf BestOption > 4 AND PotentialParent.TreeRow = SubordinateSettingsItem.TreeRow Then // Items in one node.
					If Not IsBlankString(PotentialParent.ItemID) Then // Master is displayed to the user.
						If BestOption > 4 Then
							Master = PotentialParent;
							BestOption = 4;
						EndIf;
					Else
						If BestOption > 5 Then
							Master = PotentialParent;
							BestOption = 5;
						EndIf;
					EndIf;
				ElsIf BestOption > 6 Then
					Master = PotentialParent;
					BestOption = 6;
				EndIf;
			EndDo;
			If Master = Undefined Then
				Continue;
			EndIf;
		EndIf;
		If Master.OutputAllowed Then // Link to be disabled.
			LinkDetails = New Structure;
			LinkDetails.Insert("LinkType",      "SelectionParameters");
			LinkDetails.Insert("Master",       Master);
			LinkDetails.Insert("SubordinateSettingsItem",   SubordinateSettingsItem);
			LinkDetails.Insert("SubordinateParameterName", ChoiceParametersLink.SubordinateParameterName);
			LinkDetails.Insert("SubordinateAction",     ChoiceParametersLink.Action);
			Information.LinksThatCanBeDisabled.Add(LinkDetails);
			SubordinateSettingsItem.ChoiceParameterLinks.Add(LinkDetails);
		Else // Fixed choice parameter.
			If TypeOf(Master.Value) = Type("DataCompositionField") Then
				Continue; // Extended operations with filters by the data composition field are not supported.
			EndIf;
			Try
				ValueIsFilled = ValueIsFilled(Master.Value);
			Except
				ValueIsFilled = True;
			EndTry;
			If Not ValueIsFilled Then
				Continue;
			EndIf;
			SubordinateSettingsItem.ChoiceParameters.Add(New ChoiceParameter(ChoiceParametersLink.SubordinateParameterName, Master.Value));
		EndIf;
	EndDo;
EndProcedure

// Defines output parameter properties that affect the display of title, data and filter parameters:
//  * Display title.
//  * Title.
//  * Output data parameters.
//  * Output filter.
//
// Parameters:
//  Context - Structure - information on report option and its metadata ID.
//  Settings - DataCompositionSettings - settings whose output parameters are being set.
//
Procedure InitializePredefinedOutputParameters(Context, Settings) Export 
	If Settings = Undefined Then 
		Return;
	EndIf;
	
	OutputParameters = Settings.OutputParameters.Items;
	
	// The Title parameter is always available but in report setting form only.
	Object = OutputParameters.Find("TITLE");
	Object.ViewMode = DataCompositionSettingsItemViewMode.Normal;
	Object.UserSettingID = "";
	
	SetDefaultReportTitle(Object, Context);
	
	// The OutputTitle parameter is always unavailable. Properties depend on the Title parameter.
	LinkedObject = OutputParameters.Find("TITLEOUTPUT");
	LinkedObject.ViewMode = DataCompositionSettingsItemViewMode.Inaccessible;
	LinkedObject.UserSettingID = "";
	LinkedObject.Use = True;
	
	If Object.Use Then 
		LinkedObject.Value = DataCompositionTextOutputType.Auto;
	Else
		LinkedObject.Value = DataCompositionTextOutputType.DontOutput;
	EndIf;
	
	// The OutputParameters parameter is always available but in report setting form only.
	Object = OutputParameters.Find("DATAPARAMETERSOUTPUT");
	Object.ViewMode = DataCompositionSettingsItemViewMode.Normal;
	Object.UserSettingID = "";
	Object.Use = True;
	
	If Object.Value <> DataCompositionTextOutputType.DontOutput Then 
		Object.Value = DataCompositionTextOutputType.Auto;
	EndIf;
	
	// The OutputFilter parameter is always unavailable. The property values are the same as for the OutputDataParameters parameter.
	LinkedObject = OutputParameters.Find("FILTEROUTPUT");
	LinkedObject.ViewMode = DataCompositionSettingsItemViewMode.Inaccessible;
	LinkedObject.UserSettingID = "";
	LinkedObject.Use = True;
	
	If LinkedObject.Value <> DataCompositionTextOutputType.DontOutput Then 
		LinkedObject.Value = DataCompositionTextOutputType.Auto;
	EndIf;
EndProcedure

Procedure SetDefaultReportTitle(Title, Context)
	If ValueIsFilled(Title.Value) Then 
		Return;
	EndIf;
	
	ReportID = CommonClientServer.StructureProperty(Context, "ReportRef");
	If ReportID = Undefined Then 
		Return;
	EndIf;
	
	IsAdditionalReportOrDataProcessorType = False;
	If Common.SubsystemExists("StandardSubsystems.AdditionalReportsAndDataProcessors") Then
		ModuleAdditionalReportsAndDataProcessors = Common.CommonModule("AdditionalReportsAndDataProcessors");
		IsAdditionalReportOrDataProcessorType = ModuleAdditionalReportsAndDataProcessors.IsAdditionalReportOrDataProcessorType(
			TypeOf(ReportID));
	EndIf;
	
	If TypeOf(ReportID) = Type("String")
		Or IsAdditionalReportOrDataProcessorType Then 
		Title.Value = CommonClientServer.StructureProperty(Context, "Description", "");
		Return;
	EndIf;
	
	Option = CommonClientServer.StructureProperty(Context, "OptionRef");
	If ValueIsFilled(Option) Then 
		Title.Value = Common.ObjectAttributeValue(Option, "Description");
	EndIf;
	
	If ValueIsFilled(Title.Value)
		AND Title.Value <> "Main" Then 
		Return;
	EndIf;
	
	MetadataOfReport = Common.MetadataObjectByID(ReportID, False);
	If TypeOf(MetadataOfReport) = Type("MetadataObject") Then 
		Title.Value = MetadataOfReport.Presentation();
	EndIf;
EndProcedure

Procedure SetFixedFilters(FiltersStructure, DCSettings, ReportSettings) Export
	If TypeOf(DCSettings) <> Type("DataCompositionSettings")
		Or FiltersStructure = Undefined
		Or FiltersStructure.Count() = 0 Then
		Return;
	EndIf;
	DCParameters = DCSettings.DataParameters;
	DCFilters = DCSettings.Filter;
	Unavailable = DataCompositionSettingsItemViewMode.Inaccessible;
	For Each KeyAndValue In FiltersStructure Do
		Name = KeyAndValue.Key;
		Value = KeyAndValue.Value;
		If TypeOf(Value) = Type("FixedArray") Then
			Value = New Array(Value);
		EndIf;
		If TypeOf(Value) = Type("Array") Then
			List = New ValueList;
			List.LoadValues(Value);
			Value = List;
		EndIf;
		DCParameter = DCParameters.FindParameterValue(New DataCompositionParameter(Name));
		If TypeOf(DCParameter) = Type("DataCompositionSettingsParameterValue") Then
			DCParameter.UserSettingID = "";
			DCParameter.Use    = True;
			DCParameter.ViewMode = Unavailable;
			DCParameter.Value         = Value;
			Continue;
		EndIf;
		If TypeOf(Value) = Type("ValueList") Then
			DCComparisonType = DataCompositionComparisonType.InList;
		Else
			DCComparisonType = DataCompositionComparisonType.Equal;
		EndIf;
		CommonClientServer.SetFilterItem(DCFilters, Name, Value, DCComparisonType, , True, Unavailable, "");
	EndDo;
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// User settings

Function RegisterUserSetting(Information, SettingProperties, TreeRow, OptionSettingsItem)
	DCUserSetting = SettingProperties.DCUserSetting;
	
	DisplayMode = DCUserSetting.ViewMode;
	If DisplayMode = DataCompositionSettingsItemViewMode.Inaccessible Then
		Return SettingProperties;
	EndIf;
	
	If Not ValueIsFilled(SettingProperties.ID) Then
		Return SettingProperties;
	EndIf;
	SettingProperties.ItemID = CastIDToName(SettingProperties.ID);
	
	If OptionSettingsItem <> Undefined Then
		If OptionSettingsItem.Owner <> Undefined Then
			SettingProperties.DCNode = OptionSettingsItem.Owner.DCItem;
		EndIf;
		SettingProperties.TreeRow         = OptionSettingsItem.TreeRow;
		SettingProperties.DCOptionSetting  = OptionSettingsItem.DCItem;
		SettingProperties.OptionSetting    = OptionSettingsItem;
		SettingProperties.Subtype               = OptionSettingsItem.Subtype;
		SettingProperties.DCField               = OptionSettingsItem.DCField;
		SettingProperties.AvailableDCSetting = OptionSettingsItem.AvailableDCSetting;
		SettingProperties.TypesInformation     = OptionSettingsItem.TypesInformation;
		SettingProperties.TypeDescription        = OptionSettingsItem.TypeDescription;
		If DisplayMode = DataCompositionSettingsItemViewMode.Auto Then
			DisplayMode = SettingProperties.DCOptionSetting.ViewMode;
		EndIf;
	Else
		SettingProperties.DCNode              = TreeRow.DCNode;
		SettingProperties.TreeRow        = TreeRow;
		SettingProperties.Type                 = TreeRow.Type;
		SettingProperties.Subtype              = TreeRow.Subtype;
		SettingProperties.DCOptionSetting = SettingProperties.DCNode;
		If DisplayMode = DataCompositionSettingsItemViewMode.Auto Then
			DisplayMode = SettingProperties.DCNode.ViewMode;
		EndIf;
	EndIf;
	
	If DisplayMode = DataCompositionSettingsItemViewMode.QuickAccess Then
		SettingProperties.Quick = True;
		Information.HasQuickSettings = True;
	ElsIf DisplayMode = DataCompositionSettingsItemViewMode.Normal Then
		SettingProperties.Ordinary = True;
		Information.HasRegularSettings = True;
	ElsIf Information.UserSettingsOnly Then
		Return SettingProperties;
	EndIf;
	
	// Defining an available setting.
	If SettingProperties.Type = "NestedObjectSettings" Then
		SettingProperties.AvailableDCSetting = Information.DCSettings.AvailableObjects.Items.Find(SettingProperties.TreeRow.DCNode.ObjectID);
	EndIf;
	
	If Information.UserSettingsOnly Then
		If Information.QuickSettingsOnly Then
			SettingProperties.OutputAllowed = SettingProperties.Quick;
		Else
			SettingProperties.OutputAllowed = True;
		EndIf;
	EndIf;
	
	SettingProperties.OutputFlag = True;
	SettingProperties.OutputFlagOnly = False;
	
	FillSettingPresentationAndState(
		SettingProperties,
		SettingProperties.DCOptionSetting,
		SettingProperties.DCUserSetting,
		SettingProperties.AvailableDCSetting);
	
	If SettingProperties.State = "DeletionMark" Then
		Information.HasNonexistingFields = True;
		SettingProperties.OutputAllowed = False;
	EndIf;
	
	If SettingProperties.Type = "FilterItemsGroup"
		Or SettingProperties.Type = "NestedObjectSettings"
		Or SettingProperties.Type = "Group"
		Or SettingProperties.Type = "Table"
		Or SettingProperties.Type = "TableGroup"
		Or SettingProperties.Type = "Chart"
		Or SettingProperties.Type = "ChartGroup"
		Or SettingProperties.Type = "ConditionalAppearanceItem" Then
		
		SettingProperties.OutputFlagOnly = True;
		
	ElsIf SettingProperties.Type = "SettingsParameterValue"
		Or SettingProperties.Type = "FilterItem" Then
		
		If SettingProperties.Type = "SettingsParameterValue" Then
			SettingProperties.Value = DCUserSetting.Value;
		Else
			SettingProperties.Value = DCUserSetting.RightValue;
		EndIf;
		
		// Defining a setting value type.
		If SettingProperties.Type = "SettingsParameterValue" Then
			If SettingProperties.AvailableDCSetting.Use = DataCompositionParameterUse.Always Then
				SettingProperties.OutputFlag = False;
				DCUserSetting.Use = True;
			EndIf;
			If SettingProperties.AvailableDCSetting.ValueListAllowed Then
				SettingProperties.ComparisonType = DataCompositionComparisonType.InList;
			Else
				SettingProperties.ComparisonType = DataCompositionComparisonType.Equal;
			EndIf;
		ElsIf SettingProperties.Type = "FilterItem" Then
			SettingProperties.ComparisonType = DCUserSetting.ComparisonType;
		EndIf;
		
		If SettingProperties.TypesInformation.ContainsPeriodType
			AND SettingProperties.TypesInformation.TypesCount = 1 Then
			
			SettingProperties.ItemsType = "StandardPeriod";
			
		ElsIf Not SettingProperties.OutputFlag
			AND SettingProperties.TypesInformation.ContainsBooleanType
			AND SettingProperties.TypesInformation.TypesCount = 1 Then
			
			SettingProperties.ItemsType = "ValueCheckBoxOnly";
			
		ElsIf SettingProperties.ComparisonType = DataCompositionComparisonType.Filled
			Or SettingProperties.ComparisonType = DataCompositionComparisonType.NotFilled Then
			
			SettingProperties.ItemsType = "ConditionInViewingMode";
			
		ElsIf SettingProperties.ComparisonType = DataCompositionComparisonType.InList
			Or SettingProperties.ComparisonType = DataCompositionComparisonType.InListByHierarchy
			Or SettingProperties.ComparisonType = DataCompositionComparisonType.NotInList
			Or SettingProperties.ComparisonType = DataCompositionComparisonType.NotInListByHierarchy Then
			
			SettingProperties.ListInput = True;
			SettingProperties.ItemsType = "ListWithPicking";
			SettingProperties.ChoiceFoldersAndItems = FoldersAndItems.FoldersAndItems;
			
		Else
			
			SettingProperties.ItemsType = "LinkWithComposer";
			If SettingProperties.ComparisonType = DataCompositionComparisonType.InHierarchy
				Or SettingProperties.ComparisonType = DataCompositionComparisonType.NotInHierarchy Then
				SettingProperties.ChoiceFoldersAndItems = FoldersAndItems.Folders;
			EndIf;
			
		EndIf;
		
		If SettingProperties.ChoiceFoldersAndItems = Undefined Then
			SettingProperties.ChoiceFoldersAndItems = OptionSettingsItem.ChoiceFoldersAndItems;
		EndIf;
		
	ElsIf SettingProperties.Type = "SelectedFields"
		Or SettingProperties.Type = "Order"
		Or SettingProperties.Type = "TableStructureItemCollection"
		Or SettingProperties.Type = "ChartStructureItemCollection"
		Or SettingProperties.Type = "Filter"
		Or SettingProperties.Type = "ConditionalAppearance"
		Or SettingProperties.Type = "SettingsStructure" Then
		
		SettingProperties.ItemsType = "LinkWithComposer";
		SettingProperties.OutputFlag = False;
		
	Else
		
		SettingProperties.ItemsType = "LinkWithComposer";
		
	EndIf;
	
	If SettingProperties.OutputFlagOnly Then
		SettingProperties.ItemsType = "";
	ElsIf SettingProperties.Quick AND SettingProperties.ItemsType = "ListWithPicking" Then
		SettingProperties.ItemsType = "LinkWithComposer";
	EndIf;
	
	Return SettingProperties;
EndFunction

Procedure FillSettingPresentationAndState(SettingProperties, DCOptionSetting, DCUserSetting, AvailableDCSetting)
	If DCUserSetting = Undefined Then
		DCUserSetting = DCOptionSetting;
	EndIf;
	
	PresentationsStructure = New Structure("Presentation, UserSettingPresentation", "", "");
	FillPropertyValues(PresentationsStructure, DCOptionSetting);
	
	SettingProperties.OutputFlagOnly = ValueIsFilled(PresentationsStructure.Presentation);
	
	If ValueIsFilled(PresentationsStructure.UserSettingPresentation) Then
		Presentation = PresentationsStructure.UserSettingPresentation;
	ElsIf ValueIsFilled(PresentationsStructure.Presentation) AND PresentationsStructure.Presentation <> "1" Then
		Presentation = PresentationsStructure.Presentation;
	Else
		Presentation = "";
	EndIf;
	SettingProperties.Presentation = TrimAll(Presentation);
	
	// Default presentation.
	If AvailableDCSetting <> Undefined AND ValueIsFilled(AvailableDCSetting.Title) Then
		DefaultPresentation = AvailableDCSetting.Title;
	ElsIf ValueIsFilled(SettingProperties.Subtype) Then
		If SettingProperties.Subtype = "ChartSeries" Then
			DefaultPresentation = NStr("ru = 'Серии'; en = 'Series'; pl = 'Seria';de = 'Serie';ro = 'Serii';tr = 'Seri'; es_ES = 'Serie'");
		ElsIf SettingProperties.Subtype = "ChartPoints" Then
			DefaultPresentation = NStr("ru = 'Точки'; en = 'Dots'; pl = 'Punkty';de = 'Punkte';ro = 'Puncte';tr = 'Noktalar'; es_ES = 'Puntos'");
		ElsIf SettingProperties.Subtype = "TableRows" Then
			DefaultPresentation = NStr("ru = 'Строки'; en = 'Rows'; pl = 'Wiersze';de = 'Zeilen';ro = 'Rânduri';tr = 'Satırlar'; es_ES = 'Líneas'");
		ElsIf SettingProperties.Subtype = "ColumnsTable" Then
			DefaultPresentation = NStr("ru = 'Колонки'; en = 'Columns'; pl = 'Kolumny';de = 'Spalten';ro = 'Coloane';tr = 'Sütunlar'; es_ES = 'Columnas'");
		ElsIf SettingProperties.Subtype = "Report" Then
			DefaultPresentation = NStr("ru = 'Отчет'; en = 'Report'; pl = 'Sprawozdanie';de = 'Bericht';ro = 'Raportul';tr = 'Rapor'; es_ES = 'Informe'");
		Else
			DefaultPresentation = String(SettingProperties.Subtype);
		EndIf;
	
	// Parameters and filters.
	ElsIf SettingProperties.Type = "Filter" Then
		DefaultPresentation = NStr("ru = 'Отбор'; en = 'Filter'; pl = 'Wybór';de = 'Auswahl';ro = 'Filtrare';tr = 'Seçim'; es_ES = 'Selección'");
	ElsIf SettingProperties.Type = "FilterItemsGroup" Then
		DefaultPresentation = String(DCOptionSetting.GroupType);
	ElsIf SettingProperties.Type = "FilterItem" Then
		DefaultPresentation = String(DCOptionSetting.LeftValue);
	ElsIf SettingProperties.Type = "SettingsParameterValue" Then
		DefaultPresentation = String(DCOptionSetting.Parameter);
	
	// Sorting.
	ElsIf SettingProperties.Type = "Order" Then
		DefaultPresentation = NStr("ru = 'Сортировка'; en = 'Sort'; pl = 'Sortuj';de = 'Sortieren';ro = 'Sortare';tr = 'Sınıflandır'; es_ES = 'Clasificar'");
	ElsIf SettingProperties.Type = "AutoOrderItem" Then
		DefaultPresentation = NStr("ru = 'Авто (сортировки родителя)'; en = 'Auto (parent sort)'; pl = 'Auto (sortowania rodzica)';de = 'Automatisch (übergeordnete Sortierung)';ro = 'Auto (sortările părintelui)';tr = 'Oto (ana filtre)'; es_ES = 'Auto (clasificaciones de padre)'");
	ElsIf SettingProperties.Type = "OrderingItem" Then
		DefaultPresentation = String(DCOptionSetting.Field);
	
	// Selected fields.
	ElsIf SettingProperties.Type = "SelectedFields" Then
		DefaultPresentation = NStr("ru = 'Поля'; en = 'Fields'; pl = 'Pola';de = 'Felder';ro = 'Câmpuri';tr = 'Alanlar'; es_ES = 'Campos'");
	ElsIf SettingProperties.Type = "SelectedField" Then
		DefaultPresentation = String(DCOptionSetting.Field);
	ElsIf SettingProperties.Type = "AutoSelectedField" Then
		DefaultPresentation = NStr("ru = 'Авто (поля родителя)'; en = 'Auto (parent fields)'; pl = 'Auto (pola rodzica)';de = 'Automatisch (übergeordnete Felder)';ro = 'Auto (câmpurile părintelui)';tr = 'Oto (ana alan)'; es_ES = 'Auto (campo de padre)'");
	ElsIf SettingProperties.Type = "SelectedFieldsGroup" Then
		DefaultPresentation = DCOptionSetting.Title;
		If DCOptionSetting.Placement <> DataCompositionFieldPlacement.Auto Then
			DefaultPresentation = DefaultPresentation + " (" + String(DCOptionSetting.Placement) + ")";
		EndIf;
	
	// Conditional appearance.
	ElsIf SettingProperties.Type = "ConditionalAppearance" Then
		DefaultPresentation = NStr("ru = 'Оформление'; en = 'Appearance'; pl = 'Wygląd';de = 'Aussehen';ro = 'Aspect';tr = 'Düzenleme'; es_ES = 'Formato'");
	ElsIf SettingProperties.Type = "ConditionalAppearanceItem" Then
		DefaultPresentation = ReportsClientServer.ConditionalAppearanceItemPresentation(
			DCUserSetting,
			DCOptionSetting,
			SettingProperties.State);
	
	// Structure.
	ElsIf SettingProperties.Type = "Group"
		Or SettingProperties.Type = "TableGroup"
		Or SettingProperties.Type = "ChartGroup" Then
		DefaultPresentation = TrimAll(String(DCOptionSetting.GroupFields));
		If IsBlankString(DefaultPresentation) Then
			DefaultPresentation = NStr("ru = '<Детальные записи>'; en = '<Detailed records>'; pl = '<Zapisy szczegółowe>';de = '<Detaillierte Datensätze>';ro = '<Înregistrări detaliate>';tr = '<Detailed records>'; es_ES = '<Registros detallados>'");
		Else
			AvailableDCFields = DCOptionSetting.GroupFields.GroupFieldsAvailableFields;
			For Each DCGroupField In DCOptionSetting.GroupFields.Items Do
				If TypeOf(DCGroupField) = Type("DataCompositionGroupField")
					AND AvailableDCFields.FindField(DCGroupField.Field) = Undefined Then
					SettingProperties.State = "DeletionMark";
					Break;
				EndIf;
			EndDo;
		EndIf;
	ElsIf SettingProperties.Type = "Table" Then
		DefaultPresentation = NStr("ru = 'Таблица'; en = 'Table'; pl = 'Tabela';de = 'Tabelle';ro = 'Tabel';tr = 'Tablo'; es_ES = 'Tabla'");
	ElsIf SettingProperties.Type = "Chart" Then
		DefaultPresentation = NStr("ru = 'Диаграмма'; en = 'Chart'; pl = 'Wykres';de = 'Grafik';ro = 'Grafic';tr = 'Diyagram'; es_ES = 'Diagrama'");
	ElsIf SettingProperties.Type = "NestedObjectSettings" Then
		DefaultPresentation = String(DCUserSetting);
		If IsBlankString(DefaultPresentation) Then
			DefaultPresentation = NStr("ru = 'Вложенная группировка'; en = 'Nested grouping'; pl = 'Załączone grupowanie';de = 'Gruppierung anhängen';ro = 'Grupare incorporată';tr = 'Gruplandırmayı ekle'; es_ES = 'Añadir la agrupación'");
		EndIf;
	ElsIf SettingProperties.Type = "SettingsStructure" Then
		DefaultPresentation = NStr("ru = 'Структура'; en = 'Structure'; pl = 'Skład';de = 'Struktur';ro = 'Structură';tr = 'Yapı'; es_ES = 'Estructura'");
	Else
		DefaultPresentation = String(SettingProperties.Type);
	EndIf;
	SettingProperties.DefaultPresentation = TrimAll(DefaultPresentation);
	
	If SettingProperties.AvailableDCSetting = Undefined
		AND (SettingProperties.Type = "FilterItem"
			Or SettingProperties.Type = "SettingsParameterValue"
			Or SettingProperties.Type = "OrderingItem"
			Or SettingProperties.Type = "SelectedField")Then
		SettingProperties.State = "DeletionMark";
	EndIf;
	
	If Not ValueIsFilled(SettingProperties.Presentation) Then
		SettingProperties.Presentation = SettingProperties.DefaultPresentation;
	EndIf;
	
EndProcedure

// Collects statistics on the number of user settings broken down by display modes.
//
// Parameters:
//  SettingsComposer - DataCompositionSettingsComposer  a relevant composer.
//
// Returns:
//   Structure - the number of user settings broken down by display modes:
//             - QuickAccess - number of settings with the QuickAccess or Auto display modes.
//             - Typical - number of settings with the Typical display mode.
//             - Total - total amount of available settings.
//
Function CountOfAvailableSettings(SettingsComposer) Export 
	AvailableSettings = New Structure;
	AvailableSettings.Insert("QuickAccess", 0);
	AvailableSettings.Insert("Typical", 0);
	AvailableSettings.Insert("Total", 0);
	
	UserSettings = SettingsComposer.UserSettings;
	For Each UserSettingItem In UserSettings.Items Do 
		SettingItem = ReportsClientServer.GetObjectByUserID(
			SettingsComposer.Settings,
			UserSettingItem.UserSettingID,,
			UserSettings);
		
		DisplayMode = ?(SettingItem = Undefined,
			UserSettingItem.ViewMode, SettingItem.ViewMode);
		
		If DisplayMode = DataCompositionSettingsItemViewMode.Auto
			Or DisplayMode = DataCompositionSettingsItemViewMode.QuickAccess Then 
			AvailableSettings.QuickAccess = AvailableSettings.QuickAccess + 1;
		ElsIf DisplayMode = DataCompositionSettingsItemViewMode.Normal Then 
			AvailableSettings.Typical = AvailableSettings.Typical + 1;
		EndIf;
	EndDo;
	
	AvailableSettings.Total = AvailableSettings.QuickAccess + AvailableSettings.Typical;
	
	Return AvailableSettings;
EndFunction

Function UserSettingsItemProperties(SettingsComposer, UserSettingItem, SettingItem, SettingDetails)
	Properties = UserSettingsItemPropertiesPalette();
	
	Properties.DCUserSetting = UserSettingItem;
	Properties.DCItem = SettingItem;
	Properties.AvailableDCSetting = SettingDetails;
	
	Properties.ID = UserSettingItem.UserSettingID;
	Properties.DCID = SettingsComposer.UserSettings.GetIDByObject(
		UserSettingItem);
	Properties.ItemID = StrReplace(
		UserSettingItem.UserSettingID, "-", "");
	
	SettingItemType = TypeOf(SettingItem);
	If SettingItemType = Type("DataCompositionSettingsParameterValue") Then 
		Properties.DCField = New DataCompositionField("DataParameters." + String(SettingItem.Parameter));
		Properties.Value = SettingItem.Value;
	ElsIf TypeOf(SettingItem) = Type("DataCompositionFilterItem") Then 
		Properties.DCField = SettingItem.LeftValue;
		Properties.Value = SettingItem.RightValue;
	EndIf;
	
	Properties.Type = SettingTypeAsString(SettingItemType);
	
	If SettingDetails = Undefined Then 
		Return Properties;
	EndIf;
	
	Properties.TypeDescription = SettingDetails.ValueType;
	
	If SettingDetails.AvailableValues <> Undefined Then 
		Properties.ValuesForSelection = SettingDetails.AvailableValues;
	EndIf;
	
	Return Properties;
EndFunction

Function UserSettingsItemPropertiesPalette()
	Properties = New Structure;
	Properties.Insert("QuickChoice", False);
	Properties.Insert("ListInput", False);
	Properties.Insert("ComparisonType", DataCompositionComparisonType.Equal);
	Properties.Insert("Owner", Undefined);
	Properties.Insert("ChoiceFoldersAndItems", FoldersAndItems.Auto);
	Properties.Insert("OutputAllowed", True);
	Properties.Insert("OutputInMainSettingsGroup", False);
	Properties.Insert("OutputFlagOnly", False);
	Properties.Insert("OutputFlag", True);
	Properties.Insert("Global", True);
	Properties.Insert("AvailableDCSetting", Undefined);
	Properties.Insert("SelectionValuesQuery", New Query);
	Properties.Insert("Value", Undefined);
	Properties.Insert("ValuesForSelection", New ValueList);
	Properties.Insert("ID", "");
	Properties.Insert("DCID", Undefined);
	Properties.Insert("ItemID", "");
	Properties.Insert("CollectionName", "");
	Properties.Insert("TypesInformation", New Structure);
	Properties.Insert("TypeRestriction", Undefined);
	Properties.Insert("RestrictSelectionBySpecifiedValues", False);
	Properties.Insert("TypeDescription", New TypeDescription("Undefined"));
	Properties.Insert("MarkedValues", Undefined);
	Properties.Insert("ChoiceParameters", New Array);
	Properties.Insert("Subtype", "");
	Properties.Insert("DCField", Undefined);
	Properties.Insert("UserSetting", Undefined);
	Properties.Insert("DCUserSetting", Undefined);
	Properties.Insert("Presentation", "");
	Properties.Insert("DefaultPresentation", "");
	Properties.Insert("Parent", Undefined);
	Properties.Insert("ChoiceParameterLinks", New Array);
	Properties.Insert("MetadataRelations", New Array);
	Properties.Insert("TypeLink", Undefined);
	Properties.Insert("EventOnChange", False);
	Properties.Insert("State", "");
	Properties.Insert("ValueListRedefined", False);
	Properties.Insert("TreeRow", Undefined);
	Properties.Insert("Rows", Undefined);
	Properties.Insert("Type", "");
	Properties.Insert("ChoiceForm", "");
	Properties.Insert("Width", 0);
	Properties.Insert("DCItem", Undefined);
	
	Return Properties;
EndFunction

////////////////////////////////////////////////////////////////////////////////
// Auxiliary

// Creates and returns an instance of the report by full metadata object name.
//
// Parameters:
//  FullName - String - full name of a metadata object. Example: "Report.BusinessProcesses".
//
// Returns:
//  ReportObject - a report instance.
//
Function ReportObject(ID) Export
	FullName = ID;
	
	If TypeOf(ID) = Type("CatalogRef.MetadataObjectIDs") Then
		FullName = Common.ObjectAttributeValue(ID, "FullName");
	EndIf;
	
	ObjectDetails = StrSplit(FullName, ".");
	
	If ObjectDetails.Count() >= 2 Then
		Kind = Upper(ObjectDetails[0]);
		Name = ObjectDetails[1];
	Else
		Raise StrReplace(NStr("ru = 'Некорректное полное имя отчета ""%1"".'; en = 'Report %1 has invalid name.'; pl = 'Niepoprawna pełna nazwa raportu %1.';de = 'Falscher vollständiger Name des Berichts ""%1"".';ro = 'Nume complet incorect al raportului ""%1"".';tr = 'Raporun yanlış tam adı""%1"".'; es_ES = 'Nombre completo del informe incorrecto ""%1"".'"), "%1", FullName);
	EndIf;
	
	If Kind = "REPORT" Then
		Return Reports[Name].Create();
	ElsIf Kind = "EXTERNALREPORT" Then
		Return ExternalReports.Create(Name); // CAC:553 For external reports not connected to the Additional reports and data processors subsystem. The call is safe because safety checks for the external report were executed earlier upon connection.
	Else
		Raise StrReplace(NStr("ru = '""%1"" не является отчетом.'; en = '%1 is not a report.'; pl = '""%1"" nie jest raportem.';de = '""%1"" ist kein Bericht.';ro = '""%1"" nu este raport.';tr = '""%1""bir rapor.'; es_ES = '""%1"" no es informe.'"), "%1", FullName);
	EndIf;
EndFunction

////////////////////////////////////////////////////////////////////////////////
// Updating form items of user settings

Function SettingsFormItemsProperties(FormType, SettingsComposer, AdditionalParameters) 
	#Region StructurePreparing
	
	ItemsProperties = New Structure("Folders, Fields");
	ItemsProperties.Folders = New Structure;
	
	RowDetails = New TypeDescription("String");
	NumberDetails = New TypeDescription("Number");
	
	Fields = New ValueTable;
	Fields.Columns.Add("SettingIndex", NumberDetails);
	Fields.Columns.Add("SettingID", RowDetails);
	Fields.Columns.Add("Settings");
	Fields.Columns.Add("SettingItem");
	Fields.Columns.Add("SettingDetails");
	Fields.Columns.Add("Presentation", RowDetails);
	Fields.Columns.Add("GroupID", RowDetails);
	Fields.Columns.Add("TitleLocation", New TypeDescription("FormItemTitleLocation"));
	Fields.Columns.Add("HorizontalStretch");
	Fields.Columns.Add("Width", NumberDetails);
	
	AvailableModes = New Array;
	AvailableModes.Add(DataCompositionSettingsItemViewMode.QuickAccess);
	If FormType = ReportFormType.Settings Then 
		AvailableModes.Add(DataCompositionSettingsItemViewMode.Normal);
	EndIf;
	
	UnavailableStructureItems = New Map;
	UnavailableStructureItems.Insert(Type("DataCompositionGroup"), ReportFormType.Settings);
	UnavailableStructureItems.Insert(Type("DataCompositionTableGroup"), ReportFormType.Settings);
	UnavailableStructureItems.Insert(Type("DataCompositionChartGroup"), ReportFormType.Settings);
	UnavailableStructureItems.Insert(Type("DataCompositionTable"), ReportFormType.Settings);
	UnavailableStructureItems.Insert(Type("DataCompositionChart"), ReportFormType.Settings);
	
	PropertiesTiSynchronize = New Map;
	PropertiesTiSynchronize.Insert(Type("DataCompositionFilterItem"), "LeftValue, Presentation");
	PropertiesTiSynchronize.Insert(Type("DataCompositionConditionalAppearanceItem"), "Presentation");
	
	#EndRegion
	
	#Region StructureFilling
	
	Info = UserSettingsInfo(SettingsComposer.Settings);
	UserSettings = SettingsComposer.UserSettings;
	For Each UserSettingItem In UserSettings.Items Do 
		FoundInfo = Info[UserSettingItem.UserSettingID];
		SettingItem = FoundInfo.SettingItem;
		
		If SettingItem = Undefined
			Or UnavailableStructureItems.Get(TypeOf(SettingItem)) = FormType
			Or AvailableModes.Find(SettingItem.ViewMode) = Undefined Then 
			Continue;
		EndIf;
		
		ItemType = TypeOf(SettingItem);
		If ItemType = Type("DataCompositionConditionalAppearanceItem") Then 
			Presentation = ReportsClientServer.ConditionalAppearanceItemPresentation(
				SettingItem, Undefined, "");
			
			If Not ValueIsFilled(SettingItem.Presentation) Then 
				SettingItem.Presentation = Presentation;
			ElsIf Not ValueIsFilled(SettingItem.UserSettingPresentation)
				AND SettingItem.Presentation <> Presentation Then 
				
				SettingItem.UserSettingPresentation = SettingItem.Presentation;
				SettingItem.Presentation = Presentation;
			EndIf;
		EndIf;
		
		Properties = PropertiesTiSynchronize[ItemType];
		If Properties <> Undefined Then 
			FillPropertyValues(UserSettingItem, SettingItem, Properties);
		EndIf;
		
		Field = Fields.Add();
		Field.SettingID = UserSettingItem.UserSettingID;
		Field.SettingIndex = UserSettings.Items.IndexOf(UserSettingItem);
		Field.Settings = FoundInfo.Settings;
		Field.SettingItem = SettingItem;
		Field.SettingDetails = FoundInfo.SettingDetails;
		Field.TitleLocation = FormItemTitleLocation.Auto;
		
		If UnavailableStructureItems.Get(TypeOf(SettingItem)) <> Undefined Then 
			Presentation = SettingItem.OutputParameters.Items.Find("TITLE");
			If Presentation <> Undefined
				AND ValueIsFilled(Presentation.Value) Then 
				Field.Presentation = Presentation.Value;
			EndIf;
		EndIf;
		
		If FormType = ReportFormType.Settings
			AND TypeOf(SettingItem) = Type("DataCompositionConditionalAppearanceItem") Then 
			Field.GroupID = "More";
		EndIf;
	EndDo;
	
	If Fields.Find("More", "GroupID") <> Undefined Then 
		ItemsProperties.Folders.Insert("More", FormItemsGroupProperties());
	EndIf;
	
	Fields.Sort("SettingIndex");
	ItemsProperties.Fields = Fields;
	
	If AdditionalParameters.Events.OnDefineSettingsFormItemsProperties Then 
		ReportObject(AdditionalParameters.FullName).OnDefineSettingsFormItemsProperties(
			FormType, ItemsProperties, UserSettings.Items);
	EndIf;
	
	#EndRegion
	
	Return ItemsProperties;
EndFunction

// Getting info on main settings included in user settings.

Function UserSettingsInfo(Settings)
	Info = New Map;
	GetGroupingInfo(Settings, Info);
	
	Return Info;
EndFunction

Procedure GetGroupingInfo(Grouping, Info)
	GroupingType = TypeOf(Grouping);
	If GroupingType <> Type("DataCompositionSettings")
		AND GroupingType <> Type("DataCompositionGroup")
		AND GroupingType <> Type("DataCompositionTableGroup")
		AND GroupingType <> Type("DataCompositionChartGroup") Then 
		Return;
	EndIf;
	
	If GroupingType <> Type("DataCompositionSettings")
		AND ValueIsFilled(Grouping.UserSettingID) Then 
		
		InfoKinds = InfoKinds();
		InfoKinds.Settings = Grouping;
		InfoKinds.SettingItem = Grouping;
		
		Info.Insert(Grouping.UserSettingID, InfoKinds);
	EndIf;
	
	GetSettingsItemInfo(Grouping, Info);
EndProcedure

Procedure GetTableInfo(Table, Info)
	If TypeOf(Table) <> Type("DataCompositionTable") Then
		Return;
	EndIf;
	
	If ValueIsFilled(Table.UserSettingID) Then 
		InfoKinds = InfoKinds();
		InfoKinds.Settings = Table;
		InfoKinds.SettingItem = Table;
		
		Info.Insert(Table.UserSettingID, InfoKinds);
	EndIf;
	
	GetSettingsItemInfo(Table, Info);
	GetCollectionInfo(Table, Table.Rows, Info);
	GetCollectionInfo(Table, Table.Columns, Info);
EndProcedure

Procedure GetChartInfo(Chart, Info)
	If TypeOf(Chart) <> Type("DataCompositionChart") Then
		Return;
	EndIf;
	
	If ValueIsFilled(Chart.UserSettingID) Then 
		InfoKinds = InfoKinds();
		InfoKinds.Settings = Chart;
		InfoKinds.SettingItem = Chart;
		
		Info.Insert(Chart.UserSettingID, InfoKinds);
	EndIf;
	
	GetSettingsItemInfo(Chart, Info);
	GetCollectionInfo(Chart, Chart.Series, Info);
	GetCollectionInfo(Chart, Chart.Points, Info);
EndProcedure

Procedure GetCollectionInfo(SettingsItem, Collection, Info)
	CollectionType = TypeOf(Collection);
	If CollectionType <> Type("DataCompositionTableStructureItemCollection")
		AND CollectionType <> Type("DataCompositionChartStructureItemCollection")
		AND CollectionType <> Type("DataCompositionSettingStructureItemCollection") Then
		Return;
	EndIf;
	
	If ValueIsFilled(Collection.UserSettingID) Then 
		InfoKinds = InfoKinds();
		InfoKinds.Settings = SettingsItem;
		InfoKinds.SettingItem = Collection;
		
		Info.Insert(Collection.UserSettingID, InfoKinds);
	EndIf;
	
	For Each Item In Collection Do 
		Settings = Item;
		If TypeOf(Item) = Type("DataCompositionNestedObjectSettings") Then
			If ValueIsFilled(Item.UserSettingID) Then 
				InfoKinds = InfoKinds();
				InfoKinds.Settings = Item;
				InfoKinds.SettingItem = Item;
				
				Info.Insert(Item.UserSettingID, InfoKinds);
			EndIf;
			
			Settings = Item.Settings;
		EndIf;

		GetGroupingInfo(Settings, Info);
		GetTableInfo(Settings, Info);
		GetChartInfo(Settings, Info);
	EndDo;
EndProcedure

Procedure GetSettingsItemInfo(SettingsItem, Info)
	PropertiesIDs = StrSplit("Selection, OutputParameters, ConditionalAppearance", ", ", False);
	AvailableProperties = New Structure("Selection, Filter, Order, ConditionalAppearance, Structure");
	
	SettingsItemType = TypeOf(SettingsItem);
	If SettingsItemType <> Type("DataCompositionTable")
		AND SettingsItemType <> Type("DataCompositionChart") Then 
		
		PropertiesIDs.Add("Filter");
		PropertiesIDs.Add("Order");
		PropertiesIDs.Add("Structure");
		
		If SettingsItemType = Type("DataCompositionSettings") Then 
			PropertiesIDs.Add("DataParameters");
		EndIf;
	EndIf;
	
	For Each ID In PropertiesIDs Do 
		Property = SettingsItem[ID];
		
		If AvailableProperties.Property(ID)
			AND ValueIsFilled(Property.UserSettingID) Then 
			
			InfoKinds = InfoKinds();
			InfoKinds.Settings = SettingsItem;
			InfoKinds.SettingItem = Property;
			
			Info.Insert(Property.UserSettingID, InfoKinds);
		EndIf;
		
		GetSettingsPropertyItemsInfo(SettingsItem, Property, ID, Info);
		GetCollectionInfo(SettingsItem, Property, Info);
	EndDo;
EndProcedure

Procedure GetSettingsPropertyItemsInfo(Settings, Property, PropertyID, Info)
	PropertiesWithItems = New Structure("Filter, DataParameters, OutputParameters, ConditionalAppearance");
	If Not PropertiesWithItems.Property(PropertyID) Then 
		Return;
	EndIf;
	
	For Each Item In Property.Items Do 
		ItemType = TypeOf(Item);
		
		If ValueIsFilled(Item.UserSettingID) Then 
			Details = Undefined;
			If ItemType = Type("DataCompositionFilterItem") Then 
				Details = Settings[PropertyID].FilterAvailableFields.FindField(Item.LeftValue);
			ElsIf ItemType = Type("DataCompositionParameterValue")
				Or ItemType = Type("DataCompositionSettingsParameterValue") Then 
				Details = Settings[PropertyID].AvailableParameters.FindParameter(Item.Parameter);
			EndIf;
			
			InfoKinds = InfoKinds();
			InfoKinds.Settings = Settings;
			InfoKinds.SettingItem = Item;
			InfoKinds.SettingDetails = Details;
			
			Info.Insert(Item.UserSettingID, InfoKinds);
		EndIf;
		
		If ItemType = Type("DataCompositionFilterItemGroup") Then 
			GetSettingsPropertyItemsInfo(Settings, Item, PropertyID, Info);
		ElsIf ItemType = Type("DataCompositionParameterValue")
			Or ItemType = Type("DataCompositionSettingsParameterValue") Then 
			GetNestedParametersValuesInfo(
				Settings, Item.NestedParameterValues, PropertyID, Info);
		EndIf;
	EndDo;
EndProcedure

Procedure GetNestedParametersValuesInfo(Settings, ParametersValues, PropertyID, Info)
	For Each ParameterValue In ParametersValues Do 
		If ValueIsFilled(ParameterValue.UserSettingID) Then 
			InfoKinds = InfoKinds();
			InfoKinds.Settings = Settings;
			InfoKinds.SettingItem = ParameterValue;
			InfoKinds.SettingDetails =
				Settings[PropertyID].AvailableParameters.FindParameter(ParameterValue.Parameter);
			
			Info.Insert(ParameterValue.UserSettingID, InfoKinds);
		EndIf;
		
		GetNestedParametersValuesInfo(
			Settings, ParameterValue.NestedParameterValues, PropertyID, Info);
	EndDo;
EndProcedure

Function InfoKinds()
	Return New Structure("Settings, SettingItem, SettingDetails");
EndFunction

// Regrouping form items connected to user settings.

Function SettingsItemsAttributesNames(Form, ItemsKinds)
	PredefinedItemsattributesNames = New Structure;
	GeneratedItemsAttributesNames = New Structure;
	
	For Each ItemKind In ItemsKinds Do 
		PredefinedItemsattributesNames.Insert(ItemKind, New Array);
		GeneratedItemsAttributesNames.Insert(ItemKind, New Array);
	EndDo;
	
	Attributes = Form.GetAttributes();
	For Each Attribute In Attributes Do 
		For Each ItemKind In ItemsKinds Do 
			If StrStartsWith(Attribute.Name, ItemKind)
				AND StringFunctionsClientServer.OnlyNumbersInString(StrReplace(Attribute.Name, ItemKind, "")) Then 
				PredefinedItemsattributesNames[ItemKind].Add(Attribute.Name);
			EndIf;
			
			If StrStartsWith(Attribute.Name, "SettingsComposerUserSettingsItem")
				AND StrEndsWith(Attribute.Name, ItemKind) Then 
				GeneratedItemsAttributesNames[ItemKind].Add(Attribute.Name);
			EndIf;
		EndDo;
	EndDo;
	
	AttributesNames = New Structure;
	AttributesNames.Insert("Predefined", PredefinedItemsattributesNames);
	AttributesNames.Insert("Generated", GeneratedItemsAttributesNames);
	
	Return AttributesNames;
EndFunction

Procedure PrepareFormToRegroupItems(Form, ItemsHierarchyNode, AttributesNames, StyylizedItemsKinds)
	Items = Form.Items;
	
	// Regrouping predefined form items.
	PredefinedItemsProperties = StrSplit("Indent, Select, PasteFromClipboard", ", ", False);
	PredefinedItemsProperties.Add("");
	
	For Each ItemKind In StyylizedItemsKinds Do 
		PredefinedAttributesNames = AttributesNames.Predefined[ItemKind];
		For Each AttributeName In PredefinedAttributesNames Do 
			For Each Property In PredefinedItemsProperties Do 
				FoundItem = Items.Find(AttributeName + Property);
				If FoundItem <> Undefined Then 
					Items.Move(FoundItem, Items.PredefinedSettingsItems);
					FoundItem.Visible = False;
				EndIf;
			EndDo;
		EndDo;
	EndDo;
	
	// Deleting dynamic form items.
	ItemsHierarchyNodes = New Array;
	ItemsHierarchyNodes.Add(ItemsHierarchyNode);
	
	FoundNode = Items.Find("More");
	If FoundNode <> Undefined Then 
		ItemsHierarchyNodes.Add(FoundNode);
	EndIf;
	
	Exceptions = New Array;
	
	FoundNode = Items.Find("PredefinedSettings");
	If FoundNode <> Undefined Then 
		Exceptions.Add(FoundNode);
	EndIf;
	
	For Each CurrentNode In ItemsHierarchyNodes Do 
		ItemsHierarchy = CurrentNode.ChildItems;
		ItemIndex = ItemsHierarchy.Count() - 1;
		While ItemIndex >= 0 Do 
			HierarchyItem = ItemsHierarchy[ItemIndex];
			If Exceptions.Find(HierarchyItem) = Undefined Then 
				Items.Delete(HierarchyItem);
			EndIf;
			ItemIndex = ItemIndex - 1;
		EndDo;
	EndDo;
EndProcedure

Procedure RegroupSettingsFormItems(Form, Val ItemsHierarchyNode, ItemsProperties, AttributesNames, StyylizedItemsKinds)
	SettingsDetails = ItemsProperties.Fields.Copy(,
		"SettingIndex, SettingID, Settings, SettingItem, SettingDetails");
	
	SettingsItems = SettingsFormItems(Form, SettingsDetails, AttributesNames);
	SetSettingsFormItemsProperties(Form, SettingsItems, ItemsProperties);
	
	If Form.ReportFormType <> ReportFormType.Settings Then 
		SettingsItems.FillValues(False, "IsList");
	EndIf;
	
	TakeListToSeparateGroup(SettingsItems, ItemsProperties);
	
	GroupsIDs = ItemsProperties.Fields.Copy();
	GroupsIDs.GroupBy("GroupID");
	GroupsIDs = GroupsIDs.UnloadColumn("GroupID");
	
	Items = Form.Items;
	
	If GroupsIDs.Count() = 1 Then 
		ItemsHierarchyNode.Group = ChildFormItemsGroup.AlwaysHorizontal;
	Else
		ItemsHierarchyNode.Group = ChildFormItemsGroup.Vertical;
	EndIf;
	
	GroupNumber = 0;
	For Each GroupID In GroupsIDs Do 
		GroupNumber = GroupNumber + 1;
		
		GroupProperties = Undefined;
		If Not ValueIsFilled(GroupID)
			Or Not ItemsProperties.Folders.Property(GroupID, GroupProperties) Then 
			GroupProperties = FormItemsGroupProperties();
		EndIf;
		
		FoundHierarchyNode = Items.Find(GroupID);
		If FoundHierarchyNode <> Undefined Then 
			ItemsHierarchyNode = FoundHierarchyNode;
			GroupNumber = 1;
		EndIf;
		
		GroupName = ItemsHierarchyNode.Name + "String" + GroupNumber;
		Folder = ?(GroupsIDs.Count() = 1, ItemsHierarchyNode, Items.Find(GroupName));
		
		If Folder = Undefined Then 
			Folder = SettingsFormItemsGroup(Items, ItemsHierarchyNode, GroupName);
			Folder.Title = "String " + GroupNumber;
			FillPropertyValues(Folder, GroupProperties,, "Group");
			Folder.Group = ChildFormItemsGroup.AlwaysHorizontal;
		EndIf;
		
		SearchGroupFields = New Structure("GroupID", GroupID);
		GroupFieldsProperties = ItemsProperties.Fields.FindRows(SearchGroupFields);
		GroupSettingsItems = GroupSettingsItems(SettingsItems, GroupFieldsProperties);
		
		PrepareSettingsFormItemsToDistribution(GroupSettingsItems, GroupProperties.Group);
		DistributeSettingsFormItems(Form.Items, Folder, GroupSettingsItems);
	EndDo;
	
	OutputStylizedSettingsFormItems(Form, SettingsItems, SettingsDetails, AttributesNames, StyylizedItemsKinds);
EndProcedure

// Searching setting form items created by the system and preparing them for distribution.

Function SettingsFormItems(Form, SettingsDetails, AttributesNames)
	Items = Form.Items;
	
	SettingsItems = SettingsItemsCollectionPalette();
	FindSettingsFormItems(Form, Items.Temporary, SettingsItems, SettingsDetails);
	
	SummaryInfo = SettingsItems.Copy();
	SummaryInfo.GroupBy("SettingIndex", "Checksum");
	IncompleteItems = SummaryInfo.FindRows(New Structure("Checksum", 1));
	
	Search = New Structure("SettingIndex, SettingProperty");
	CommonProperties = "IsPeriod, IsFlag, IsList, ValueType, ChoiceForm, AvailableValues";
	
	For Each Record In IncompleteItems Do 
		Item = SettingsItems.Find(Record.SettingIndex, "SettingIndex");
		Item.Field.TitleLocation = FormItemTitleLocation.None;
		
		SourceProperty = "Value";
		LinkedProperty = "Use";
		If StrEndsWith(Item.Field.Name, LinkedProperty) Then 
			SourceProperty = "Use";
			LinkedProperty = "Value";
		EndIf;
		
		AdditionalItemName = StrReplace(Item.Field.Name, Item.SettingProperty, LinkedProperty);
		
		ItemGroup = Item.Field.Parent;
		If Items.Find(AdditionalItemName) <> Undefined
			Or ItemGroup.ChildItems.Find(AdditionalItemName) <> Undefined Then 
			Continue;
		EndIf;
		
		AdditionalItem = Items.Add(AdditionalItemName, Type("FormDecoration"), ItemGroup);
		AdditionalItem.Title = Item.Field.Title;
		AdditionalItem.AutoMaxHeight = False;
		
		AdditionalRecord = SettingsItems.Add();
		AdditionalRecord.Field = AdditionalItem;
		AdditionalRecord.SettingIndex = Record.SettingIndex;
		AdditionalRecord.SettingProperty = LinkedProperty;
		AdditionalRecord.Checksum = 1;
		
		Search.SettingIndex = Record.SettingIndex;
		Search.SettingProperty = SourceProperty;
		LinkedItems = SettingsItems.FindRows(Search);
		FillPropertyValues(AdditionalRecord, LinkedItems[0], CommonProperties);
	EndDo;
	
	FindValuesAsCheckBoxes(Form, SettingsItems, AttributesNames);
	
	SettingsItems.Sort("SettingIndex");
	
	Return SettingsItems;
EndFunction

Function SettingsItemsCollectionPalette()
	NumberDetails = New TypeDescription("Number");
	RowDetails = New TypeDescription("String");
	FlagDetails = New TypeDescription("Boolean");
	
	SettingsItems = New ValueTable;
	SettingsItems.Columns.Add("Priority", NumberDetails);
	SettingsItems.Columns.Add("SettingIndex", NumberDetails);
	SettingsItems.Columns.Add("SettingProperty", RowDetails);
	SettingsItems.Columns.Add("Field");
	SettingsItems.Columns.Add("IsPeriod", FlagDetails);
	SettingsItems.Columns.Add("IsList", FlagDetails);
	SettingsItems.Columns.Add("IsFlag", FlagDetails);
	SettingsItems.Columns.Add("IsValueAsCheckBox", FlagDetails);
	SettingsItems.Columns.Add("ValueType");
	SettingsItems.Columns.Add("ChoiceForm", RowDetails);
	SettingsItems.Columns.Add("AvailableValues");
	SettingsItems.Columns.Add("Checksum", NumberDetails);
	SettingsItems.Columns.Add("ColumnNumber", NumberDetails);
	SettingsItems.Columns.Add("GroupNumber", NumberDetails);
	
	Return SettingsItems;
EndFunction

Procedure FindSettingsFormItems(Form, ItemsGroup, SettingsItems, SettingsDetails)
	UserSettings = Form.Report.SettingsComposer.UserSettings.Items;
	
	MainProperties = New Structure("Use, Value");
	For Each Item In ItemsGroup.ChildItems Do 
		If TypeOf(Item) = Type("FormGroup") Then 
			FindSettingsFormItems(Form, Item, SettingsItems, SettingsDetails);
		ElsIf TypeOf(Item) = Type("FormField") Then 
			SettingProperty = Undefined;
			SettingIndex = ReportsClientServer.SettingItemIndexByPath(Item.Name, SettingProperty);
			
			ItemSettingDetails = SettingsDetails.Find(SettingIndex, "SettingIndex");
			If ItemSettingDetails = Undefined Then 
				Continue;
			EndIf;
			
			Record = SettingsItems.Add();
			Record.SettingIndex = SettingIndex;
			Record.SettingProperty = SettingProperty;
			Record.Field = Item;
			
			SettingItem = ItemSettingDetails.SettingItem;
			SettingDetails = ItemSettingDetails.SettingDetails;
			
			If SettingDetails <> Undefined Then 
				FillPropertyValues(Record, SettingDetails, "ValueType, ChoiceForm, AvailableValues");
			EndIf;
			
			If TypeOf(SettingItem) = Type("DataCompositionSettingsParameterValue") Then 
				Record.IsPeriod = TypeOf(SettingItem.Value) = Type("StandardPeriod");
				Record.IsList = SettingDetails <> Undefined AND SettingDetails.ValueListAllowed;
			ElsIf TypeOf(SettingItem) = Type("DataCompositionFilterItem") Then 
				Record.IsPeriod = TypeOf(SettingItem.RightValue) = Type("StandardPeriod");
				Record.IsFlag = ValueIsFilled(SettingItem.Presentation);
				
				UserSettingItem = UserSettings.Find(
					ItemSettingDetails.SettingID);
				
				Record.IsList = Not Record.IsFlag
					AND ReportsClientServer.IsListComparisonKind(UserSettingItem.ComparisonType);
			ElsIf TypeOf(SettingItem) = Type("DataCompositionConditionalAppearanceItem") Then 
				Record.IsFlag = ValueIsFilled(SettingItem.Presentation)
					Or ValueIsFilled(SettingItem.UserSettingPresentation);
			EndIf;
			
			If MainProperties.Property(Record.SettingProperty) Then 
				Record.Checksum = 1;
			EndIf;
		EndIf;
	EndDo;
EndProcedure

Procedure FindValuesAsCheckBoxes(Form, SettingsItems, AttributesNames)
	Search = New Structure;
	Search.Insert("ValueType", New TypeDescription("Boolean"));
	FoundItems = SettingsItems.Copy(Search);
	FoundItems.GroupBy("SettingIndex, ValueType", "Checksum");
	
	FoundItems = FoundItems.FindRows(New Structure("Checksum", 2));
	If FoundItems.Count() = 0 Then 
		Return;
	EndIf;
	
	Search = New Structure("SettingProperty, SettingIndex");
	For Each Item In FoundItems Do 
		Search.SettingProperty = "Use";
		Search.SettingIndex = Item.SettingIndex;
		
		CheckBoxItem = SettingsItems.FindRows(Search);
		If CheckBoxItem.Count() = 0 Then 
			Continue;
		EndIf;
		
		CheckBoxItem = CheckBoxItem[0];
		If TypeOf(CheckBoxItem.Field) <> Type("FormDecoration") Then 
			Continue;
		EndIf;
		
		Search.SettingProperty = "Value";
		
		ItemValue = SettingsItems.FindRows(Search);
		If ItemValue.Count() = 0 Then 
			Continue;
		EndIf;
		
		CheckBoxItem.SettingProperty = "Value";
		CheckBoxItem.IsFlag = True;
		CheckBoxItem.IsValueAsCheckBox = True;
		
		ItemValue = ItemValue[0];
		ItemValue.SettingProperty = "Use";
		ItemValue.IsFlag = True;
		ItemValue.IsValueAsCheckBox = True;
		ItemValue.Field.Visible = False;
	EndDo;
EndProcedure

Procedure SetSettingsFormItemsProperties(Form, SettingsItems, ItemsProperties)
	SettingsComposer = Form.Report.SettingsComposer;
	
	#Region SetItemsPropertiesUsage
	
	Exceptions = New Array;
	Exceptions.Add(DataCompositionComparisonType.Equal);
	Exceptions.Add(DataCompositionComparisonType.Contains);
	Exceptions.Add(DataCompositionComparisonType.Filled);
	Exceptions.Add(DataCompositionComparisonType.Like);
	Exceptions.Add(DataCompositionComparisonType.InList);
	Exceptions.Add(DataCompositionComparisonType.InListByHierarchy);
	
	FoundItems = SettingsItems.FindRows(New Structure("SettingProperty", "Use"));
	For Each Item In FoundItems Do 
		Field = Item.Field;
		FieldProperties = ItemsProperties.Fields.Find(Item.SettingIndex, "SettingIndex");
		
		If ValueIsFilled(FieldProperties.Presentation) Then 
			Field.Title = FieldProperties.Presentation;
		EndIf;
		
		If TypeOf(Field) = Type("FormField") Then 
			Field.TitleLocation = FormItemTitleLocation.Right;
			Field.SetAction("OnChange", "Attachable_SettingItem_OnChange");
		ElsIf TypeOf(Field) = Type("FormDecoration") Then 
			Field.Visible = (FieldProperties.TitleLocation <> FormItemTitleLocation.None);
		EndIf;
		
		If StrLen(Field.Title) > 40 Then
			Field.TitleHeight = 2;
		EndIf;
		
		SettingItem = FieldProperties.SettingItem;
		If TypeOf(SettingItem) = Type("DataCompositionSettingsParameterValue") Then 
			Field.Title = Item.Field.Title + ":";
		ElsIf TypeOf(SettingItem) = Type("DataCompositionFilterItem") Then 
			If Exceptions.Find(SettingItem.ComparisonType) <> Undefined Then 
				Field.Title = Item.Field.Title + ":";
			ElsIf Not ValueIsFilled(SettingItem.Presentation) Then 
				Field.Title = Item.Field.Title + " (" + Lower(SettingItem.ComparisonType) + "):";
			EndIf;
		EndIf;
	EndDo;
	
	#EndRegion
	
	#Region SetItemsPropertiesSettingsItems
	
	FoundItems = SettingsItems.FindRows(New Structure("SettingProperty", "ComparisonType"));
	For Each Item In FoundItems Do 
		Item.Field.Visible = False;
	EndDo;
	
	#EndRegion
	
	#Region SetItemsPropertiesValue
	
	PickingParameters = New Map;
	ExtendedTypesDetails = New Map;
	
	FoundItems = SettingsItems.FindRows(New Structure("SettingProperty", "Value"));
	For Each Item In FoundItems Do 
		Field = Item.Field;
		
		If TypeOf(Field) = Type("FormDecoration") Then 
			Field.Title = "     ";
			
			Search = New Structure("SettingIndex, SettingProperty", Item.SettingIndex, "Use");
			FoundLinkedItems = SettingsItems.FindRows(Search);
			
			LinkedField = FoundLinkedItems[0].Field;
			If StrEndsWith(LinkedField.Title, ":") Then 
				LinkedField.Title = Left(LinkedField.Title, StrLen(LinkedField.Title) - 1);
			EndIf;
		Else // Input field.
			FieldProperties = ItemsProperties.Fields.Find(Item.SettingIndex, "SettingIndex");
			FillPropertyValues(Field, FieldProperties,, "TitleLocation");
			
			If Item.IsFlag Then 
				Item.Field.Visible = False;
				Continue;
			EndIf;
			
			Field.SetAction("OnChange", "Attachable_SettingItem_OnChange");
			If Item.IsList Then
				Field.SetAction("StartChoice", "Attachable_SettingItem_StartChoice");
			EndIf;
			
			Field.ChoiceForm = Item.ChoiceForm;
			If ValueIsFilled(Field.ChoiceForm) Then 
				PickingParameters.Insert(Item.SettingIndex, Field.ChoiceForm);
			EndIf;
			
			Result = ReportsClientServer.AddToList(
				Field.ChoiceList, Item.AvailableValues, False, True);
			Field.ListChoiceMode = Not Item.IsList AND Result <> Undefined AND Result.Total > 0;
			
			If Item.ValueType = Undefined Then 
				Continue;
			EndIf;
			
			ExtendedTypeDetails = ExtendedTypesDetails(Item.ValueType, True, PickingParameters);
			ExtendedTypesDetails.Insert(Item.SettingIndex, ExtendedTypeDetails);
			
			Field.AvailableTypes = ExtendedTypeDetails.TypesDetailsForForm;
			Field.TypeRestriction = ExtendedTypeDetails.TypesDetailsForForm;
			
			If StrLen(Field.Title) > 40 Then
				Field.TitleHeight = 2;
			EndIf;
			
			If Field.HorizontalStretch = Undefined Then
				Field.HorizontalStretch = True;
				Field.AutoMaxWidth = False;
				Field.MaxWidth = 40;
			EndIf;
			
			If ExtendedTypeDetails.TypesCount = 1 Then 
				If ExtendedTypeDetails.ContainsNumberType Then 
					Field.ChoiceButton = True;
					If Field.HorizontalStretch = True Then
						Field.HorizontalStretch = False;
					EndIf;
				ElsIf ExtendedTypeDetails.ContainsDateType Then 
					Field.MaxWidth = 25;
				ElsIf ExtendedTypeDetails.ContainsBooleanType Then 
					Field.MaxWidth = 5;
				EndIf;
			EndIf;
		EndIf;
	EndDo;
	
	AdditionalProperties = SettingsComposer.Settings.AdditionalProperties;
	AdditionalProperties.Insert("PickingParameters", PickingParameters);
	AdditionalProperties.Insert("ExtendedTypesDetails", ExtendedTypesDetails);
	
	#EndRegion
EndProcedure

Procedure TakeListToSeparateGroup(SettingsItems, ItemsProperties)
	Search = New Structure("IsList", True);
	Statistics = SettingsItems.Copy(Search);
	Statistics.GroupBy("SettingIndex");
	
	If Statistics.Count() <> 1 Then 
		Return;
	EndIf;
	
	SettingIndex = SettingsItems.FindRows(Search)[0].SettingIndex;
	FieldProperties = ItemsProperties.Fields.Find(SettingIndex, "SettingIndex");
	If ValueIsFilled(FieldProperties.GroupID) Then 
		Return;
	EndIf;
	
	GroupID = "_" + StrReplace(New UUID, "-", "");
	FieldProperties.GroupID = GroupID;
	ItemsProperties.Folders.Insert(GroupID, FormItemsGroupProperties());
EndProcedure

Function GroupSettingsItems(SettingsItems, GroupFieldsProperties)
	GroupSettingsItems = SettingsItems.CopyColumns();
	
	Search = New Structure("SettingIndex");
	For Each Properties In GroupFieldsProperties Do 
		Search.SettingIndex = Properties.SettingIndex;
		FoundItems = SettingsItems.FindRows(Search);
		For Each Item In FoundItems Do 
			FillPropertyValues(GroupSettingsItems.Add(), Item);
		EndDo;
	EndDo;
	
	Return GroupSettingsItems;
EndFunction

// Distributing setting form items in the hierarchy.

Procedure PrepareSettingsFormItemsToDistribution(SettingsItems, Grouping)
	#Region BeforePreparation
	
	Statistics = SettingsItems.Copy();
	Statistics.GroupBy("SettingIndex");
	
	ColumnsCount = 1;
	If Grouping = ChildFormItemsGroup.HorizontalIfPossible Then 
		ColumnsCount = Min(2, Statistics.Count());
	ElsIf Grouping = ChildFormItemsGroup.AlwaysHorizontal Then 
		ColumnsCount = Statistics.Count();
	EndIf;
	ColumnsCount = Max(1, ColumnsCount);
	
	#EndRegion
	
	#Region SetPriority
	
	FoundItems = SettingsItems.FindRows(New Structure("IsPeriod", True));
	For Each Item In FoundItems Do 
		Item.Priority = -1;
	EndDo;
	
	SettingsItems.Sort("Priority, SettingIndex");
	
	#EndRegion
	
	#Region SetColumnsNumbers
	
	Statistics = SettingsItems.Copy();
	Statistics.GroupBy("Priority, SettingIndex");
	
	ItemsCount = Statistics.Count();
	Index = 0;
	PropertiesBorder = ItemsCount - 1;
	
	Step = ItemsCount / ColumnsCount;
	BreakBoundary = ?(ItemsCount % ColumnsCount = 0, Step - 1, Int(Step));
	Step = ?(BreakBoundary = 0, 1, Int(Step));
	
	Search = New Structure("SettingIndex");
	For ColumnNumber = 1 To ColumnsCount Do 
		While Index <= BreakBoundary Do 
			Search.SettingIndex = Statistics[Index].SettingIndex;
			FoundItems = SettingsItems.FindRows(Search);
			For Each Item In FoundItems Do 
				Item.ColumnNumber = ColumnNumber;
			EndDo;
			Index = Index + 1;
		EndDo;
		
		BreakBoundary = BreakBoundary + Step;
		If BreakBoundary > PropertiesBorder Then 
			BreakBoundary = PropertiesBorder;
		EndIf;
	EndDo;
	
	DistributeListsByColumnsProportionally(SettingsItems, ColumnsCount);
	
	#EndRegion
	
	#Region SetGroupsNumbers
	
	SearchOptions = New Array;
	SearchOptions.Add(New Structure("GroupNumber, IsFlag, IsList", 0, False, False));
	SearchOptions.Add(New Structure("GroupNumber, IsFlag, IsList", 0, True, False));
	SearchOptions.Add(New Structure("GroupNumber, IsFlag, IsList", 0, False, True));
	
	GroupNumber = 1;
	For Each Search In SearchOptions Do 
		FoundItems = SettingsItems.FindRows(Search);
		
		PreviousIndex = Undefined;
		For Each Item In FoundItems Do 
			If Item.IsFlag Or Item.IsList Then 
				Index = Item.SettingIndex;
			Else
				Index = SettingsItems.IndexOf(Item);
			EndIf;
			
			If PreviousIndex = Undefined Then 
				PreviousIndex = Index;
			EndIf;
			
			If ((Item.IsFlag Or Item.IsList) AND Index <> PreviousIndex)
				Or (Not Item.IsFlag AND Not Item.IsList AND Index > PreviousIndex + 1) Then 
				GroupNumber = GroupNumber + 1;
			EndIf;
			
			Item.GroupNumber = GroupNumber;
			PreviousIndex = Index;
		EndDo;
		
		GroupNumber = GroupNumber + 1;
	EndDo;
	
	#EndRegion
EndProcedure

Procedure DistributeListsByColumnsProportionally(SettingsItems, ColumnsCount)
	If ColumnsCount <> 2
		Or SettingsItems.Find(True, "IsList") = Undefined Then 
		Return;
	EndIf;
	
	NumberDetails = New TypeDescription("Number");
	
	Statistics = SettingsItems.Copy();
	Statistics.GroupBy("SettingIndex, IsList, ColumnNumber");
	Statistics.Columns.Add("Lists", NumberDetails);
	
	For Each Item In Statistics Do 
		Item.Lists = Number(Item.IsList);
	EndDo;
	
	Statistics.GroupBy("ColumnNumber", "Lists");
	
	Lists = Statistics.Total("Lists");
	If Lists = 1 Then 
		Return;
	EndIf;
	
	Statistics.Sort("Lists");
	
	Mean = Round(Lists / Statistics.Count(), 0, RoundMode.Round15as10);
	Target = Statistics[0];
	Source = Statistics[Statistics.Count() - 1];
	
	Deviation = Mean - Target.Lists;
	If Deviation = 0 Then 
		Return;
	EndIf;
	
	Search = New Structure("IsList, ColumnNumber", True, Source.ColumnNumber);
	SourceItems = SettingsItems.Copy(Search);
	SourceItems.GroupBy("SettingIndex");
	If Target.ColumnNumber > Source.ColumnNumber Then 
		SourceItems.Sort("SettingIndex Desc");
	EndIf;
	
	Deviation = Min(Deviation, SourceItems.Count());
	Search = New Structure("SettingIndex");
	
	Index = 0;
	While Deviation > 0 Do 
		Search.SettingIndex = SourceItems[Index].SettingIndex;
		LinkedItems = SettingsItems.FindRows(Search);
		For Each Item In LinkedItems Do 
			Item.ColumnNumber = Target.ColumnNumber;
		EndDo;
		
		Index = Index + 1;
		Deviation = Deviation - 1;
	EndDo;
EndProcedure

Procedure DistributeSettingsFormItems(Items, Val Folder, SettingsItems)
	ColumnsCount = 0;
	If SettingsItems.Count() > 0 Then 
		ColumnsCount = SettingsItems[SettingsItems.Count() - 1].ColumnNumber;
	EndIf;
	
	For ColumnNumber = 1 To ColumnsCount Do 
		ItemsFlags = SettingsItems.Copy(New Structure("ColumnNumber", ColumnNumber));
		ItemsFlags.GroupBy("IsFlag, IsList, GroupNumber");
		
		InputFieldsOnly = ItemsFlags.Find(True, "IsFlag") = Undefined
			AND ItemsFlags.Find(True, "IsList") = Undefined;
		
		ColumnName = Folder.Name + "Column" + ColumnNumber;
		Column = ?(ColumnsCount = 1, Folder, Items.Find(ColumnName));
		If Column = Undefined Then 
			Column = SettingsFormItemsGroup(Items, Folder, ColumnName);
			Column.Title = "Column " + ColumnNumber;
			
			If InputFieldsOnly Then 
				Column.Group = ChildFormItemsGroup.AlwaysHorizontal;
			EndIf;
		EndIf;
		
		If InputFieldsOnly Then 
			DistributeSettingsFormItemsByProperties(Items, Column, SettingsItems, ColumnNumber);
			Continue;
		EndIf;
		
		RowNumber = 0;
		For Each Flags In ItemsFlags Do 
			RowNumber = RowNumber + 1;
			Parent = SettingsFormItemsHierarchy(Items, Column, Flags, RowNumber, ColumnNumber);
			
			DistributeSettingsFormItemsByProperties(Items, Parent, SettingsItems, ColumnNumber, Flags.GroupNumber);
		EndDo;
	EndDo;
EndProcedure

Procedure DistributeSettingsFormItemsByProperties(Items, Parent, SettingsItems, ColumnNumber, GroupNumber = Undefined)
	SettingsProperties = StrSplit("Use, ComparisonType, Value", ", ", False);
	For Each SettingProperty In SettingsProperties Do 
		GroupName = Parent.Name + SettingProperty;
		Folder = SettingsFormItemsGroup(Items, Parent, GroupName);
		Folder.Title = SettingProperty;
		Folder.Visible = (SettingProperty <> "ComparisonType");
		
		Search = New Structure("SettingProperty, ColumnNumber", SettingProperty, ColumnNumber);
		If GroupNumber <> Undefined Then 
			Search.Insert("GroupNumber", GroupNumber);
		EndIf;
		
		FoundItems = SettingsItems.FindRows(Search);
		For Each Item In FoundItems Do 
			Folder.United = SettingProperty = "Use" AND Item.IsList;
			Items.Move(Item.Field, Folder);
		EndDo;
	EndDo;
EndProcedure

Function SettingsFormItemsHierarchy(Items, Parent, Flags, RowNumber, ColumnNumber)
	RowName = Parent.Name + "String" + RowNumber;
	Row = SettingsFormItemsGroup(Items, Parent, RowName);
	Row.Title = "String " + ColumnNumber + "." + RowNumber;
	
	If Not Flags.IsList Then 
		Row.Group = ChildFormItemsGroup.AlwaysHorizontal;
	EndIf;
	
	If Flags.IsFlag Or Flags.IsList Then 
		Return Row;
	EndIf;
	
	ColumnName = Row.Name + "Column1";
	Column = SettingsFormItemsGroup(Items, Row, ColumnName);
	Column.Title = "Column " + ColumnNumber + "." + RowNumber + ".1";
	Column.Group = ChildFormItemsGroup.AlwaysHorizontal;
	
	Return Column;
EndFunction

Function SettingsFormItemsGroup(Items, Parent, GroupName)
	Folder = Items.Find(GroupName);
	If Folder <> Undefined Then 
		Return Folder;
	EndIf;
	
	Folder = Items.Add(GroupName, Type("FormGroup"), Parent);
	Folder.Type = FormGroupType.UsualGroup;
	Folder.ShowTitle = False;
	Folder.Representation = UsualGroupRepresentation.None;
	Folder.Group = ChildFormItemsGroup.Vertical;
	
	Return Folder;
EndFunction

// Output stylized setting form items.

Procedure OutputStylizedSettingsFormItems(Form, SettingsItems, SettingsDetails, AttributesNames, ItemsKinds)
	// Change attributes.
	PathToItemsData = New Structure("ByName, ByIndex", New Map, New Map);
	
	AttributesToAdd = SettingsItemsAttributesToAdd(SettingsItems, ItemsKinds, AttributesNames, PathToItemsData);
	AttributesToDelete = SettingsItemsAttributesToDelete(ItemsKinds, AttributesNames, PathToItemsData);
	
	Form.ChangeAttributes(AttributesToAdd, AttributesToDelete);
	DeleteSettingsItemsCommands(Form, AttributesToDelete);
	
	Form.PathToItemsData = PathToItemsData;
	
	// Change items.
	OutputSettingsPeriods(Form, SettingsItems, AttributesNames);
	OutputSettingsLists(Form, SettingsItems, SettingsDetails, AttributesNames);
	OutputValuesAsCheckBoxesFields(Form, SettingsItems, AttributesNames);
EndProcedure

Function SettingsItemsAttributesToAdd(SettingsItems, ItemsKinds, AttributesNames, PathToItemsData)
	AttributesToAdd = New Array;
	
	ItemsTypes = New Structure;
	ItemsTypes.Insert("Period", New TypeDescription("StandardPeriod"));
	ItemsTypes.Insert("List", New TypeDescription("ValueList"));
	ItemsTypes.Insert("CheckBox", New TypeDescription("Boolean"));
	
	ItemsKindsIndicators = New Structure("Period, List, CheckBox", "IsPeriod", "IsList", "IsValueAsCheckBox");
	ItemsKindsProperties = New Structure("Period, List, CheckBox", "Value", "Value", "Use");
	
	For Each ItemKind In ItemsKinds Do 
		Flag = ItemsKindsIndicators[ItemKind];
		
		Generated = AttributesNames.Generated[ItemKind];
		Predefined = AttributesNames.Predefined[ItemKind];
		
		PredefinedItemsIndex = -1;
		PredefinedItemsBorder = Predefined.UBound();
		
		Search = New Structure;
		Search.Insert(Flag, True);
		Search.Insert("SettingProperty", "Value");
		
		FoundItems = SettingsItems.Copy(Search);
		For Each Item In FoundItems Do 
			If PredefinedItemsBorder >= FoundItems.IndexOf(Item) Then 
				PredefinedItemsIndex = PredefinedItemsIndex + 1;
				PathToItemsData.ByName.Insert(Predefined[PredefinedItemsIndex], Item.SettingIndex);
				PathToItemsData.ByIndex.Insert(Item.SettingIndex, Predefined[PredefinedItemsIndex]);
				Continue;
			EndIf;
			
			ItemTitle = Item.Field.Title;
			ItemNameTemplate = StrReplace(Item.Field.Name, ItemsKindsProperties[ItemKind], "%1");
			
			AttributeName = StringFunctionsClientServer.SubstituteParametersToString(ItemNameTemplate, ItemKind);
			If Generated.Find(AttributeName) = Undefined Then 
				ItemType = Item.ValueType;
				ItemsTypes.Property(ItemKind, ItemType);
				
				AttributesToAdd.Add(New FormAttribute(AttributeName, ItemType,, ItemTitle));
			EndIf;
			
			PathToItemsData.ByName.Insert(AttributeName, Item.SettingIndex);
			PathToItemsData.ByIndex.Insert(Item.SettingIndex, AttributeName);
		EndDo;
	EndDo;
	
	Return AttributesToAdd;
EndFunction

Function SettingsItemsAttributesToDelete(ItemsKinds, AttributesNames, PathToItemsData)
	AttributesToDelete = New Array;
	
	For Each ItemKind In ItemsKinds Do 
		Generated = AttributesNames.Generated[ItemKind];
		For Each AttributeName In Generated Do 
			If PathToItemsData.ByName[AttributeName] = Undefined Then 
				AttributesToDelete.Add(AttributeName);
			EndIf;
		EndDo;
	EndDo;
	
	Return AttributesToDelete;
EndFunction

Procedure DeleteSettingsItemsCommands(Form, AttributesToDelete)
	CommandsSuffixes = StrSplit("SelectPeriod, Select, PasteFromClipboard", ", ", FALSE);
	
	For Each AttributeName In AttributesToDelete Do 
		For Each Suffix In CommandsSuffixes Do 
			Command = Form.Commands.Find(AttributeName + Suffix);
			If Command <> Undefined Then 
				Form.Commands.Delete(Command);
			EndIf;
		EndDo;
	EndDo;
EndProcedure

// Output setting form items

Procedure OutputSettingsPeriods(Form, SettingsItems, AttributesNames)
	FoundItems = SettingsItems.FindRows(New Structure("IsPeriod, SettingProperty", True, "Value"));
	If FoundItems.Count() = 0 Then 
		Return;
	EndIf;
	
	Items = Form.Items;
	PredefinedItemsattributesNames = AttributesNames.Predefined.Period;
	
	For Each Item In FoundItems Do 
		LinkedItems = SettingsItems.FindRows(New Structure("SettingIndex", Item.SettingIndex));
		For Each LinkedItem In LinkedItems Do 
			LinkedItem.Field.Visible = (LinkedItem.SettingProperty = "Use");
		EndDo;
		
		InitializePeriod(Form, Item.SettingIndex);
		
		Field = Item.Field;
		Parent = Field.Parent;
		
		NextItem = Undefined;
		ItemIndex = Parent.ChildItems.IndexOf(Field);
		If Parent.ChildItems.Count() > ItemIndex + 1 Then 
			NextItem = Parent.ChildItems.Get(ItemIndex + 1);
		EndIf;
		
		AttributeName = Form.PathToItemsData.ByIndex[Item.SettingIndex];
		If PredefinedItemsattributesNames.Find(AttributeName) <> Undefined Then 
			FoundItem = Items.Find(AttributeName);
			Items.Move(FoundItem, Parent, NextItem);
			FoundItem.Visible = True;
			Continue;
		EndIf;
		
		ItemNameTemplate = StrReplace(Field.Name, "Value", "%1%2");
		
		Folder = PeriodItemsGroup(Items, Parent, NextItem, ItemNameTemplate, Field.Title);
		AddPeriodItem(Items, Folder, ItemNameTemplate, "StartDate", Field.Title);
		
		ItemName = StringFunctionsClientServer.SubstituteParametersToString(ItemNameTemplate, "Separator");
		Separator = Items.Find(ItemName);
		If Separator = Undefined Then 
			Separator = Items.Add(ItemName, Type("FormDecoration"), Folder);
		EndIf;
		Separator.Type = FormDecorationType.Label;
		Separator.Title = Char(8211); // En dash.
		
		AddPeriodItem(Items, Folder, ItemNameTemplate, "EndDate", Field.Title);
		AddPeriodChoiceCommand(Form, Folder, ItemNameTemplate);
	EndDo;
EndProcedure

Function PeriodItemsGroup(Items, Parent, NextItem, NameTemplate, Title)
	ItemName = StringFunctionsClientServer.SubstituteParametersToString(NameTemplate, "", "Period");
	
	Folder = Items.Find(ItemName);
	If Folder = Undefined Then 
		Folder = Items.Add(ItemName, Type("FormGroup"), Parent);
	EndIf;
	Folder.Type = FormGroupType.UsualGroup;
	Folder.Representation = UsualGroupRepresentation.None;
	Folder.Group = ChildFormItemsGroup.AlwaysHorizontal;
	Folder.Title = Title;
	Folder.ShowTitle = False;
	Folder.EnableContentChange = False;
	
	If NextItem <> Undefined Then 
		Items.Move(Folder, Parent, NextItem);
	EndIf;
	
	Return Folder;
EndFunction

Procedure AddPeriodItem(Items, Folder, NameTemplate, Property, SettingItemTitle)
	ItemName = StringFunctionsClientServer.SubstituteParametersToString(NameTemplate, "", Property);
	
	CaptionPattern = "%1 (date %2)";
	Title = StringFunctionsClientServer.SubstituteParametersToString(
		CaptionPattern, SettingItemTitle, ?(StrEndsWith(Property, "Beginning"), "beginning", "end"));
	
	Item = Items.Find(ItemName);
	If Item = Undefined Then 
		Item = Items.Add(ItemName, Type("FormField"), Folder);
	EndIf;
	Item.Type = FormFieldType.InputField;
	Item.DataPath = StringFunctionsClientServer.SubstituteParametersToString(NameTemplate, "Period.", Property);
	Item.Width = 9;
	Item.HorizontalStretch = False;
	Item.ChoiceButton = True;
	Item.OpenButton = False;
	Item.ClearButton = False;
	Item.SpinButton = False;
	Item.TextEdit = True;
	Item.Title = Title;
	Item.TitleLocation = FormItemTitleLocation.None;
	Item.SetAction("OnChange", "Attachable_Period_OnChange");
EndProcedure

Procedure AddPeriodChoiceCommand(Form, Folder, NameTemplate)
	ItemName = StringFunctionsClientServer.SubstituteParametersToString(NameTemplate, "", "SelectPeriod");
	
	Command = Form.Commands.Find(ItemName);
	If Command = Undefined Then 
		Command = Form.Commands.Add(ItemName);
	EndIf;
	Command.Action = "Attachable_SelectPeriod";
	Command.Title = NStr("ru = 'Выбрать период...'; en = 'Select period...'; pl = 'Wybierz okres...';de = 'Zeitraum auswählen...';ro = 'Selectare perioada...';tr = 'Dönem seç...'; es_ES = 'Seleccionar un período...'");
	Command.ToolTip = Command.Title;
	Command.Representation = ButtonRepresentation.Picture;
	Command.Picture = PictureLib.Select;
	
	Button = Form.Items.Find(ItemName);
	If Button = Undefined Then 
		Button = Form.Items.Add(ItemName, Type("FormButton"), Folder);
	EndIf;
	Button.CommandName = ItemName;
EndProcedure

Procedure InitializePeriod(Form, Index)
	UserSettings = Form.Report.SettingsComposer.UserSettings;
	SettingItem = UserSettings.Items[Index];
	
	Path = Form.PathToItemsData.ByIndex[Index];
	If TypeOf(SettingItem) = Type("DataCompositionSettingsParameterValue") Then 
		Form[Path] = SettingItem.Value;
	Else // Filter element.
		Form[Path] = SettingItem.RightValue;
	EndIf;
EndProcedure

// Output lists of setting form items.

Procedure OutputSettingsLists(Form, SettingsItems, SettingsDetails, AttributesNames)
	Search = New Structure("IsList, SettingProperty", True, "Value");
	FoundItems = SettingsItems.FindRows(Search);
	If FoundItems.Count() = 0 Then 
		Return;
	EndIf;
	
	For Each Item In FoundItems Do 
		Item.Field.Visible = False;
		Details = SettingsDetails.Find(Item.SettingIndex, "SettingIndex");
		
		ListName = Form.PathToItemsData.ByIndex[Item.SettingIndex];
		
		AddListItems(Form, Item, Details, ListName, AttributesNames);
		AddListCommands(Form, Item, SettingsItems, ListName);
	EndDo;
EndProcedure

Procedure AddListItems(Form, SettingItem, SettingItemDetails, ListName, AttributesNames)
	Items = Form.Items; 
	Field = SettingItem.Field;
	
	PredefinedItemsattributesNames = AttributesNames.Predefined.List;
	
	If PredefinedItemsattributesNames.Find(ListName) = Undefined Then 
		List = Items.Add(ListName, Type("FormTable"), Field.Parent);
		List.DataPath = ListName;
		List.CommandBarLocation = FormItemCommandBarLabelLocation.None;
		List.Height = 3;
		List.SetAction("OnChange", "Attachable_List_OnChange");
		List.SetAction("ChoiceProcessing", "Attachable_List_ChoiceProcessing");
		
		ListFields = Items.Add(List.Name + "Columns", Type("FormGroup"), List);
		ListFields.Type = FormGroupType.ColumnGroup;
		ListFields.Group = ColumnsGroup.InCell;
		ListFields.Title = "Fields";
		ListFields.ShowTitle = False;
		
		CheckBoxField = Items.Add(ListName + "Check", Type("FormField"), ListFields);
		CheckBoxField.Type = FormFieldType.CheckBoxField;
		CheckBoxField.DataPath = ListName + ".Check";
		
		ValueField = Items.Add(ListName + "Value", Type("FormField"), ListFields);
		ValueField.Type = FormFieldType.InputField;
		ValueField.DataPath = ListName + ".Value";
		ValueField.SetAction("OnChange", "Attachable_ListItem_OnChange");
		ValueField.SetAction("StartChoice", "Attachable_ListItem_StartChoice");
	Else
		List = Items.Find(ListName);
		List.Visible = True;
		
		ListFields = Items.Find(List.Name + "Columns");
		ValueField = Items.Find(List.Name + "Value");
		
		Items.Move(List, Field.Parent);
	EndIf;
	
	List.Title = Field.Title;
	
	Properties = "AvailableTypes, TypeRestriction, AutoMarkIncomplete, ChoiceParameterLinks, TypeLink";
	FillPropertyValues(ValueField, Field, Properties);
	
	ReportsClientServer.AddToList(ValueField.ChoiceList, Field.ChoiceList, False, True);
	
	ValueField.QuickChoice = SettingItemDetails.SettingDetails.QuickChoice;
	
	Condition = ReportsClientServer.SettingItemCondition(
		SettingItemDetails.SettingItem, SettingItemDetails.SettingDetails);
	ValueField.ChoiceFoldersAndItems = ReportsClientServer.GroupsAndItemsTypeValue(
		SettingItemDetails.SettingDetails.ChoiceFoldersAndItems, Condition);
	
	ValueField.ChoiceParameters = ReportsClientServer.ChoiceParameters(
		SettingItemDetails.Settings,
		Form.Report.SettingsComposer.UserSettings.Items,
		SettingItemDetails.SettingItem);
	
	InitializeList(Form, SettingItem.SettingIndex, ValueField, SettingItemDetails.SettingItem);
	
	If Field.ChoiceList.Count() > 0 Then 
		List.ChangeRowSet = False;
		ValueField.ReadOnly = True;
	EndIf;
EndProcedure

Procedure AddListCommands(Form, SettingItem, SettingsItems, ListName)
	Items = Form.Items; 
	
	Search = New Structure("SettingProperty, SettingIndex", "Use");
	Search.SettingIndex = SettingItem.SettingIndex;
	
	TitleField = SettingsItems.FindRows(Search)[0].Field;
	TitleGroup = TitleField.Parent;
	TitleGroup.Group = ChildFormItemsGroup.AlwaysHorizontal;
	
	ListGroup = TitleGroup.Parent;
	ListGroup.Representation = UsualGroupRepresentation.NormalSeparation;
	
	If Not Items[ListName].ChangeRowSet Then 
		Return;
	EndIf;
	
	ItemName = ListName + "Indent";
	Indent = Items.Find(ItemName);
	If Indent = Undefined Then 
		Indent = Items.Add(ItemName, Type("FormDecoration"), TitleGroup);
	ElsIf Indent.Parent <> TitleGroup Then 
		Items.Move(Indent, TitleGroup);
	EndIf;
	Indent.Type = FormDecorationType.Label;
	Indent.Title = "     ";
	Indent.HorizontalStretch = True;
	Indent.AutoMaxWidth = False;
	Indent.Visible = True;
	
	CommandName = ListName + "Select";
	CommandTitle = NStr("ru = 'Подбор'; en = 'Select'; pl = 'Odebrać';de = 'Abholen';ro = 'Restabilire';tr = 'Almak'; es_ES = 'Recopilar'");
	AddListCommand(Form, TitleGroup, CommandName, CommandTitle, "Attachable_List_Pick");
	
	If Not Common.SubsystemExists("StandardSubsystems.ImportDataFromFile") Then 
		Return;
	EndIf;
	
	CommandName = ListName + "PasteFromClipboard";
	CommandTitle = NStr("ru = 'Вставить из буфера обмена...'; en = 'Paste the clipboard...'; pl = 'Wstaw ze schowka...';de = 'Aus der Zwischenablage einfügen...';ro = 'Lipire din clipboard...';tr = 'Panodan ekle ...'; es_ES = 'Insertar desde el portapapeles...'");
	AddListCommand(Form, TitleGroup, CommandName, CommandTitle,
		"Attachable_List_PasteFromClipboard", PictureLib.PasteFromClipboard);
EndProcedure

Procedure AddListCommand(Form, Parent, CommandName, Title, Action, Picture = Undefined)
	Command = Form.Commands.Find(CommandName);
	If Command = Undefined Then 
		Command = Form.Commands.Add(CommandName);
	EndIf;
	Command.Action = Action;
	Command.Title = Title;
	Command.ToolTip = Title;
	
	If Picture = Undefined Then 
		Command.Representation = ButtonRepresentation.Text;
	Else
		Command.Representation = ButtonRepresentation.Picture;
		Command.Picture = PictureLib.PasteFromClipboard;
	EndIf;
	
	Button = Form.Items.Find(CommandName);
	If Button = Undefined Then 
		Button = Form.Items.Add(CommandName, Type("FormButton"), Parent);
	ElsIf Button.Parent <> Parent Then 
		Form.Items.Move(Button, Parent);
	EndIf;
	Button.CommandName = CommandName;
	Button.Type = FormButtonType.Hyperlink;
	Button.Visible = True;
EndProcedure

Procedure InitializeList(Form, Index, Field, SettingItem)
	UserSettings = Form.Report.SettingsComposer.UserSettings;
	SettingItem = UserSettings.Items[Index];
	
	Path = Form.PathToItemsData.ByIndex[Index];
	List = Form[Path];
	List.ValueType = Field.AvailableTypes;
	List.Clear();
	
	ValueFieldName = "RightValue";
	If TypeOf(SettingItem) = Type("DataCompositionSettingsParameterValue") Then 
		ValueFieldName = "Value";
	EndIf;
	
	SelectedValues = ReportsClientServer.ValuesByList(SettingItem[ValueFieldName], True);
	If SelectedValues.Count() > 0 Then 
		SettingItem[ValueFieldName] = SelectedValues;
	Else
		SelectedValues = ReportsClientServer.ValuesByList(SettingItem[ValueFieldName], True);
		If SelectedValues.Count() > 0 Then 
			// User settings value is reset while executing CreateUserSettingsFormItems method.
			// 
			SettingItem[ValueFieldName] = SelectedValues;
		EndIf;
	EndIf;
	
	AvailableValues = New ValueList;
	If Field.QuickChoice = True Then 
		ListParameters = New Structure("ChoiceParameters, TypeDescription", Field.ChoiceParameters, Field.AvailableTypes);
		AvailableValues = ValuesForSelection(ListParameters);
	EndIf;
	
	If AvailableValues.Count() = 0 Then 
		AvailableValues = Field.ChoiceList;
	EndIf;
	
	ReportsClientServer.AddToList(List, AvailableValues, False, True);
	ReportsClientServer.AddToList(List, SelectedValues, False, True);
	
	For Each ListItem In List Do 
		If Not ValueIsFilled(ListItem.Value) Then 
			Continue;
		EndIf;
		
		FoundItem = AvailableValues.FindByValue(ListItem.Value);
		If FoundItem <> Undefined Then 
			ListItem.Presentation = FoundItem.Presentation;
		EndIf;
		
		FoundItem = SelectedValues.FindByValue(ListItem.Value);
		ListItem.Check = (FoundItem <> Undefined);
	EndDo;
	
	ListField = Form.Items[Path];
	ListField.TextColor = ?(SettingItem.Use, New Color, StyleColors.InaccessibleCellTextColor);
EndProcedure

// Output values as check box fields.

Procedure OutputValuesAsCheckBoxesFields(Form, SettingsItems, AttributesNames)
	Search = New Structure("IsValueAsCheckBox, SettingProperty", True, "Use");
	FoundItems = SettingsItems.FindRows(Search);
	If FoundItems.Count() = 0 Then 
		Return;
	EndIf;
	
	Items = Form.Items;
	PredefinedItemsattributesNames = AttributesNames.Predefined.CheckBox;
	
	For Each Item In FoundItems Do 
		Field = Item.Field;
		
		AttributeName = Form.PathToItemsData.ByIndex[Item.SettingIndex];
		If PredefinedItemsattributesNames.Find(AttributeName) = Undefined Then 
			CheckBoxField = Items.Add(AttributeName, Type("FormField"), Field.Parent);
			CheckBoxField.Type = FormFieldType.CheckBoxField;
			CheckBoxField.DataPath = AttributeName;
			CheckBoxField.SetAction("OnChange", "Attachable_SettingItem_OnChange");
		Else
			CheckBoxField = Items.Find(AttributeName);
			Items.Move(CheckBoxField, Field.Parent);
			CheckBoxField.Visible = True;
		EndIf;
		
		CheckBoxField.Title = Field.Title;
		CheckBoxField.TitleLocation = FormItemTitleLocation.Right;
		Item.Field = CheckBoxField;
		
		InitializeCheckBox(Form, Item.SettingIndex);
	EndDo;
EndProcedure

Procedure InitializeCheckBox(Form, Index)
	UserSettings = Form.Report.SettingsComposer.UserSettings;
	SettingItem = UserSettings.Items[Index];
	
	Path = Form.PathToItemsData.ByIndex[Index];
	If TypeOf(SettingItem) = Type("DataCompositionSettingsParameterValue") Then 
		Form[Path] = SettingItem.Value;
	Else // Filter element.
		Form[Path] = SettingItem.RightValue;
	EndIf;
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Saving a form status

Function RememberSelectedRows(Form, TableName, KeyColumns) Export
	TableAttribute = Form[TableName];
	TableItem = Form.Items[TableName];
	
	Result = New Structure;
	Result.Insert("Selected", New Array);
	Result.Insert("Current", Undefined);
	
	CurrentRowID = TableItem.CurrentRow;
	If CurrentRowID <> Undefined Then
		TableRow = TableAttribute.FindByID(CurrentRowID);
		If TableRow <> Undefined Then
			RowData = New Structure(KeyColumns);
			FillPropertyValues(RowData, TableRow);
			Result.Current = RowData;
		EndIf;
	EndIf;
	
	SelectedRows = TableItem.SelectedRows;
	If SelectedRows <> Undefined Then
		For Each SelectedID In SelectedRows Do
			If SelectedID = CurrentRowID Then
				Continue;
			EndIf;
			TableRow = TableAttribute.FindByID(SelectedID);
			If TableRow <> Undefined Then
				RowData = New Structure(KeyColumns);
				FillPropertyValues(RowData, TableRow);
				Result.Selected.Add(RowData);
			EndIf;
		EndDo;
	EndIf;
	
	Return Result;
EndFunction

Procedure RestoreSelectedRows(Form, TableName, TableRows) Export
	TableAttribute = Form[TableName];
	TableItem = Form.Items[TableName];
	
	TableItem.SelectedRows.Clear();
	
	If TableRows.Current <> Undefined Then
		FoundItems = ReportsClientServer.FindTableRows(TableAttribute, TableRows.Current);
		If FoundItems <> Undefined AND FoundItems.Count() > 0 Then
			For Each TableRow In FoundItems Do
				If TableRow <> Undefined Then
					ID = TableRow.GetID();
					TableItem.CurrentRow = ID;
					Break;
				EndIf;
			EndDo;
		EndIf;
	EndIf;
	
	For Each RowData In TableRows.Selected Do
		FoundItems = ReportsClientServer.FindTableRows(TableAttribute, RowData);
		If FoundItems <> Undefined AND FoundItems.Count() > 0 Then
			For Each TableRow In FoundItems Do
				If TableRow <> Undefined Then
					TableItem.SelectedRows.Add(TableRow.GetID());
				EndIf;
			EndDo;
		EndIf;
	EndDo;
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Report is blank

// Checks if there are external data sets.
//
// Parameters:
//   DataSets - DataCompositionTemplateDataSets - a collection of data sets to be checked.
//
// Returns:
//   Boolean - True if there are external data sets.
//
Function ThereIsExternalDataSet(DataSets)
	
	For Each DataSet In DataSets Do
		
		If TypeOf(DataSet) = Type("DataCompositionTemplateDataSetObject") Then
			
			Return True;
			
		ElsIf TypeOf(DataSet) = Type("DataCompositionTemplateDataSetUnion") Then
			
			If ThereIsExternalDataSet(DataSet.Items) Then
				
				Return True;
				
			EndIf;
			
		EndIf;
		
	EndDo;
	
	Return False;
	
EndFunction

////////////////////////////////////////////////////////////////////////////////
// Selection parameters

Function ValuesForSelection(SetupParameters, TypeOrTypes = Undefined) Export
	GettingChoiceDataParameters = New Structure("Filter, ChoiceFoldersAndItems");
	FillPropertyValues(GettingChoiceDataParameters, SetupParameters);
	AddItemsFromChoiceParametersToStructure(GettingChoiceDataParameters, SetupParameters.ChoiceParameters);
	
	ValuesForSelection = New ValueList;
	If TypeOf(TypeOrTypes) = Type("Type") Then
		Types = New Array;
		Types.Add(TypeOrTypes);
	ElsIf TypeOf(TypeOrTypes) = Type("Array") Then
		Types = TypeOrTypes;
	Else
		Types = SetupParameters.TypeDescription.Types();
	EndIf;
	
	For Each Type In Types Do
		MetadataObject = Metadata.FindByType(Type);
		If MetadataObject = Undefined Then
			Continue;
		EndIf;
		Manager = Common.ObjectManagerByFullName(MetadataObject.FullName());
		
		ChoiceList = Manager.GetChoiceData(GettingChoiceDataParameters);
		For Each ListItem In ChoiceList Do
			ValueForSelection = ValuesForSelection.Add();
			FillPropertyValues(ValueForSelection, ListItem);
			
			// For enumerations, values are returned as a structure with the Value property.
			EnumValue = Undefined;
			If TypeOf(ValueForSelection.Value) = Type("Structure") 
				AND ValueForSelection.Value.Property("Value", EnumValue) Then
				ValueForSelection.Value = EnumValue;
			EndIf;	
				
		EndDo;
	EndDo;
	Return ValuesForSelection;
EndFunction

Procedure AddItemsFromChoiceParametersToStructure(Structure, ChoiceParametersArray)
	For Each ChoiceParameter In ChoiceParametersArray Do
		CurrentStructure = Structure;
		RowsArray = StrSplit(ChoiceParameter.Name, ".");
		Count = RowsArray.Count();
		If Count > 1 Then
			For Index = 0 To Count-2 Do
				varKey = RowsArray[Index];
				If CurrentStructure.Property(varKey) AND TypeOf(CurrentStructure[varKey]) = Type("Structure") Then
					CurrentStructure = CurrentStructure[varKey];
				Else
					CurrentStructure = CurrentStructure.Insert(varKey, New Structure);
				EndIf;
			EndDo;
		EndIf;
		varKey = RowsArray[Count-1];
		CurrentStructure.Insert(varKey, ChoiceParameter.Value);
	EndDo;
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Data composition schema

// Adds the selected data composition field.
//
// Parameters:
//   Destination - DataCompositionSettingsComposer, DataCompositionSettings, DataCompositionSelectedFields -
//       A collection, where the selected field has to be added.
//   DCNameOrField - String, DataCompositionField - a field name.
//   Title    - String - Optional. Field presentation.
//
// Returns:
//   DataCompositionSelectedField - an added selected field.
//
Function AddSelectedField(Destination, DCNameOrField, Title = "") Export
	
	If TypeOf(Destination) = Type("DataCompositionSettingsComposer") Then
		SelectedDCFields = Destination.Settings.Selection;
	ElsIf TypeOf(Destination) = Type("DataCompositionSettings") Then
		SelectedDCFields = Destination.Selection;
	Else
		SelectedDCFields = Destination;
	EndIf;
	
	If TypeOf(DCNameOrField) = Type("String") Then
		DCField = New DataCompositionField(DCNameOrField);
	Else
		DCField = DCNameOrField;
	EndIf;
	
	SelectedDCField = SelectedDCFields.Items.Add(Type("DataCompositionSelectedField"));
	SelectedDCField.Field = DCField;
	If Title <> "" Then
		SelectedDCField.Title = Title;
	EndIf;
	
	Return SelectedDCField;
	
EndFunction

////////////////////////////////////////////////////////////////////////////////
// Miscellaneous

Function ExtendedTypesDetails(SourceTypesDetails, CastToForm, PickingParameters = Undefined) Export
	Result = New Structure;
	Result.Insert("ContainsTypeType",        False);
	Result.Insert("ContainsDateType",       False);
	Result.Insert("ContainsBooleanType",     False);
	Result.Insert("ContainsStringType",     False);
	Result.Insert("ContainsNumberType",      False);
	Result.Insert("ContainsPeriodType",     False);
	Result.Insert("ContainsUUIDType",        False);
	Result.Insert("ContainsStorageType",  False);
	Result.Insert("ContainsObjectTypes", False);
	Result.Insert("ReducedLengthItem",     True);
	
	Result.Insert("TypesCount",            0);
	Result.Insert("PrimitiveTypesNumber", 0);
	Result.Insert("ObjectTypes", New Array);
	
	If CastToForm Then
		TypesToAdd = New Array;
		RemovedTypes = New Array;
		Result.Insert("OriginalTypesDetails", SourceTypesDetails);
		Result.Insert("TypesDetailsForForm", SourceTypesDetails);
	EndIf;
	
	If SourceTypesDetails = Undefined Then
		Return Result;
	EndIf;
	
	TypesArray = SourceTypesDetails.Types();
	For Each Type In TypesArray Do
		If Type = Type("DataCompositionField") Then
			If CastToForm Then
				RemovedTypes.Add(Type);
			EndIf;
			Continue;
		EndIf;
		
		SettingMetadata = Metadata.FindByType(Type);
		If SettingMetadata <> Undefined Then 
			If Common.MetadataObjectAvailableByFunctionalOptions(SettingMetadata) Then
				If TypeOf(PickingParameters) = Type("Map") Then 
					PickingParameters.Insert(Type, SettingMetadata.FullName() + ".ChoiceForm");
				EndIf;
			Else // Object is unavailable.
				If CastToForm Then
					RemovedTypes.Add(Type);
				EndIf;
				Continue;
			EndIf;
		EndIf;
		
		Result.TypesCount = Result.TypesCount + 1;
		
		If Type = Type("Type") Then
			Result.ContainsTypeType = True;
		ElsIf Type = Type("Date") Then
			Result.ContainsDateType = True;
			Result.PrimitiveTypesNumber = Result.PrimitiveTypesNumber + 1;
		ElsIf Type = Type("Boolean") Then
			Result.ContainsBooleanType = True;
			Result.PrimitiveTypesNumber = Result.PrimitiveTypesNumber + 1;
		ElsIf Type = Type("Number") Then
			Result.ContainsNumberType = True;
			Result.PrimitiveTypesNumber = Result.PrimitiveTypesNumber + 1;
		ElsIf Type = Type("StandardPeriod") Then
			Result.ContainsPeriodType = True;
		ElsIf Type = Type("String") Then
			Result.ContainsStringType = True;
			Result.PrimitiveTypesNumber = Result.PrimitiveTypesNumber + 1;
			If SourceTypesDetails.StringQualifiers.Length = 0
				AND SourceTypesDetails.StringQualifiers.AllowedLength = AllowedLength.Variable Then
				Result.ReducedLengthItem = False;
			EndIf;
		ElsIf Type = Type("UUID") Then
			Result.ContainsUUIDType = True;
		ElsIf Type = Type("ValueStorage") Then
			Result.ContainsStorageType = True;
		Else
			Result.ContainsObjectTypes = True;
			Result.ObjectTypes.Add(Type);
		EndIf;
		
	EndDo;
	
	If CastToForm
		AND (TypesToAdd.Count() > 0 Or RemovedTypes.Count() > 0) Then
		Result.TypesDetailsForForm = New TypeDescription(SourceTypesDetails, TypesToAdd, RemovedTypes);
	EndIf;
	
	Return Result;
EndFunction

Function SettingTypeAsString(Type)
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

Function ValueToArray(Value) Export
	If TypeOf(Value) = Type("Array") Then
		Return Value;
	Else
		Array = New Array;
		Array.Add(Value);
		Return Array;
	EndIf;
EndFunction

Function CastIDToName(ID) Export
	Return StrReplace(StrReplace(String(ID), "-", ""), ".", "_");
EndFunction

// Casts value of the FoldersAndItemsUse type to the FoldersAndItems type.
//  Returns the Auto value for other types.
//
Function CastValueToGroupsAndItemsType(SourceValue, DefaultValue = Undefined)
	Type = TypeOf(SourceValue);
	If Type = Type("FoldersAndItems") Then
		Return SourceValue;
	ElsIf Type = Type("FoldersAndItemsUse") Then
		If SourceValue = FoldersAndItemsUse.Items Then
			Return FoldersAndItems.Items;
		ElsIf SourceValue = FoldersAndItemsUse.FoldersAndItems Then
			Return FoldersAndItems.FoldersAndItems;
		ElsIf SourceValue = FoldersAndItemsUse.Folders Then
			Return FoldersAndItems.Folders;
		EndIf;
	ElsIf Type = Type("DataCompositionComparisonType") Then
		If SourceValue = DataCompositionComparisonType.InList
			Or SourceValue = DataCompositionComparisonType.InListByHierarchy
			Or SourceValue = DataCompositionComparisonType.NotInList
			Or SourceValue = DataCompositionComparisonType.NotInListByHierarchy Then
			// The InListByHierarchy (In a group from the list) and NotInListByHierarchy (Not in a group from 
			// the list) comparison types must be considered "In a list or in groups" and "Not in a list and not in groups".
			// - It makes clear why they use "FoldersAndItems" instead of "Groups".
			Return FoldersAndItems.FoldersAndItems;
		ElsIf SourceValue = DataCompositionComparisonType.InHierarchy
			Or SourceValue = DataCompositionComparisonType.NotInHierarchy Then
			Return FoldersAndItems.Folders;
		EndIf;
	EndIf;
	Return ?(DefaultValue = Undefined, FoldersAndItems.Auto, DefaultValue);
EndFunction

#EndRegion
