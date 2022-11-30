///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Public

// In this procedure, describe additional dependencies of configuration metadata objects that will 
//   be used to connect report settings.
//
// Parameters:
//   MetadataObjectsLinks - ValueTable - a links table.
//       * SubordinateAttribute - String - an attribute name of a subordinate metadata object.
//       * SubordinateType      - Type    - a subordinate metadata object type.
//       * MasterType          - Type    - a leading metadata object type.
//
Procedure AddMetadataObjectsConnections(MetadataObjectsLinks) Export
	
	
	
EndProcedure

// It is called in the report form and in the report setting form before outputting a setting to 
// specify additional selection parameters.
//
// Parameters:
//  Form - ManagedForm, Undefined - a report form.
//  SettingProperties - Structure - details of report setting that will be output as a report form.
//      * DCField - DataCompositionField - a setting to be output.
//      * TypesDetails - TypesDetails - a type of a setting to be output.
//      * ValuesForSelection - ValueList - specify objects that will be offered to a user in the choice list.
//                            The parameter adds items to the list of objects previously selected by a user.
//                            However, do not assign a new value list to this parameter.
//      * SelectionValuesQuery - Query - specify a query to select objects that are required to be added into
//                               ValuesForSelection. As the first column (with 0 index), select the 
//                               object, that has to be added to the ValuesForSelection.Value.
//                               To disable autofilling, write a blank string to the 
//                               SelectionValuesQuery.Text property.
//      * RestrictSelectionBySpecifiedValues - Boolean - specify True to restrict user selection 
//                                                with values specified in ValuesForSelection (its final state).
//      * Type - String - a short property type ID of data composition settings composer.
//              See ReportsServer.SettingTypeAsString 
//
// Example:
//   1. For all settings of the CatalogRef.Users type, hide and do not permit to select users marked 
//   for deletion, as well as unavailable and internal ones.
//
//   If SettingProperties.TypesDetails.ContainsType(Type("CatalogRef.Users")) Then
//     SettingProperties.RestrictSelectionBySpecifiedValues = True;
//     SettingProperties.ValuesForSelection.Clear();
//     SettingProperties.SelectionValuesQuery.Text =
//       "SELECT Reference FROM Catalog.Users
//       |WHERE NOT DeletionMark AND NOT Unavailable AND NOT Internal";
//   EndIf.
//
//   2. Provide an additional value for selection for the Size setting.
//
//   If SettingProperties.DCField = New DataCompositionField("DataParameters.Size") Then
//     SettingProperties.ValuesForSelection.Add(10000000, NStr("en = 'Over 10 MB'"));
//   EndIf.
//
Procedure OnDefineSelectionParameters(Form, SettingProperties) Export
	
EndProcedure

// This procedure is called in the OnLoadVariantAtServer event handler of a report form after executing the form code.
// See "ManagedForm.OnCreateAtServer" in Syntax Assistant and ReportsClientOverridable.CommandHandler.
//
// Parameters:
//   Form - ManagedForm - a report form.
//   Cancel - Boolean - a flag showing whether form creation is denied.
//   StandardProcessing - Boolean - indicates a standard (system) event processing execution.
//
// Example:
//	//Adding a command with a handler to ReportsClientOverridable.CommandHandler:
//	Command = ReportForm.Commands.Add("MySpecialCommand");
//	Command.Action  = Attachable_Command;
//	Command.Header = NStr("en = 'My command...'");
//	
//	Button = ReportForm.Items.Add(Command.Name, Type("FormButton"), ReportForm.Items.<SubmenuName>);
//	Button.CommandName = Command.Name;
//	
//	ReportForm.ConstantCommands.Add(CreateCommand.Name);
//
Procedure OnCreateAtServer(Form, Cancel, StandardProcessing) Export
	
	
	
EndProcedure

// The procedure is called in the same name event handler of the report form and report setup form.
// See "Managed form extension for reports.BeforeLoadOptionAtServer" in Syntax Assistant.
//
// Parameters:
//   Form - ManagedForm - a report form or a report settings form.
//   NewDCSettings - DataCompositionSettings - settings to load into the settings composer.
//
Procedure BeforeLoadVariantAtServer(Form, NewDCSettings) Export
	
	
	
EndProcedure

#EndRegion
