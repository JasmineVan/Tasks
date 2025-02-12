﻿///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Public

// This procedure defines standard settings applied to subsystem objects.
//
// Parameters:
//   Settings - Structure - a subsystem settings collection. Attributes:
//       * OutputReportsInsteadOfOptions - Boolean - default for hyperlink output in the report panel:
//           True - report options are hidden by default, and reports are enabled and visible.
//           False   - report options are visible by default, reports are disabled.
//           The default value is False.
//       * OutputDetails - Boolean - default for showing details in the report panel:
//           True - default value. Show details as captions under options hyperlinks
//           False   - output details as tooltips
//           The default value is True.
//       * Search - Structure - settings of report options search.
//           ** InputHint - String - a hint text is displayed in the search field when the search is not specified.
//               It is recommended to use frequently used terms of the applied configuration as an example.
//       * OtherReports - Structure - setting of the Other reports form:
//           ** CloseAfterChoice - Boolean - indicates whether the form is closed after selecting a report hyperlink.
//               True - close "Other reports" after selection.
//               False   - do not close.
//               The default value is True.
//           ** ShowCheckBox - Boolean - indicates whether the CloseAfterChoice check box is visible.
//               True - whether to show "Close this window after moving to another report" check box.
//               False   - hide the check box.
//               The default value is False.
//       * OptionChangesAllowed - Boolean - show advanced report settings and commands of report 
//               option change.
//
// Example:
//	Settings.Search.InputHint = NStr("en = 'For example, cost'");
//	Settings.OtherReports.CloseAfterChoice = False;
//	Settings.OtherReports.ShowCheckBox = True;
//	Settings.OptionChangesAllowed = False;
//
Procedure OnDefineSettings(Settings) Export
	
	
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Report placement settings

// Determines sections of the global command interface in which report panels are provided.
// In Sections, it is necessary to add metadata of those subsystems of the first level in which 
// commands of report panels call are placed.
//
// Parameters:
//  Sections - ValuesList - sections in which the commands for opening the report panel are displayed.
//      * Value - MetadataObject: Subsystem, String - a subsystem of the global command interface or 
//                   ReportOptionsClientServer.HomePageID for the home page.
//      * Presentation - String - the report panel header in this section.
//
// Example:
//	Sections.Add(Metadata.Subsystems.Questionnaire, НСтр("en = 'Questionnaire reports'"));
//	Sections.Add(ReportOptionsClientServer.HomePageID(), NStr("en = 'Main reports'"));
//
Procedure DefineSectionsWithReportOptions(Sections) Export
	
	
	
EndProcedure

// Sets the settings for placing report options in the report panel.
// You can change the settings of all report options by modifying the report settings.
// If report option settings are retrieved explicitly, they become independent (they no longer 
// inherit settings changes from the report).
//   
// Initial report availability in the subsystems is read from the metadata, duplicating this in the 
// script is not required.
//   
// Functional options of the predefined report option are merged to functional options of this report according to the following rules:
// (FO1_Report OR FO2_Report) And (FO3_Option OR FO4_Option).
// Only report functional options are in effect for user report options, they can be disabled only by disabling the entire report.
// - they are disabled only with disabling the entire report.
//
// Parameters:
//   Settings - Collection - settings of configuration reports options.
//                           The following auxiliary procedures and functions are designed to change them:
//                           ReportsOptions.ReportDetails, 
//                           ReportsOptions.OptionDetails, 
//                           ReportOptions.SetOutputModeInReportPanels,
//                           ReportOptions.SetUpReportInManagerModule.
//
// Example:
//
//  // Adding report option to the subsystem.
//	OptionSettings = ReportsOptions.OptionDetails(Settings, Metadata.Reports.NameOfReport, "<OptionName>");
//	OptionSettings.Placement.Insert(Subsystems.SectionName.Subsystems.SubsystemName);
//
//  // Disabling report options.
//	OptionSettings = ReportsOptions.OptionDetails(Settings, Metadata.Reports.NameOfReport, "<OptionName>");
//	OptionSettings.Enabled = False;
//
//  // Disabling all report options except one.
//	ReportSettings = ReportsOptions.ReportDetails(Settings, Metadata.Reports.NameOfReport);
//	ReportSettings.Enabled = False;
//	OptionSettings = ReportsOptions.OptionDetails(Settings, ReportSettings, "<OptionName>");
//	OptionSettings.Enabled = True;
//
//  // Filling in the search settings - field descriptions, parameters and filters:
//	OptionSettings = ReportsOptions.OptionDetails(Settings, Metadata.Reports.NameOfReportWithoutSchema, "");
//	OptionSettings.SearchSettings.FieldDescriptions =
//		NStr("en = 'Counterparty
//		|Contract
//		|Responsible person
//		|Discount
//		|Date'");
//	OptionSettings.SearchSettings.FilterAndParameterDescriptions =
//		NStr("en = 'Period
//		|Responsible person
//		|Counterparty
//		|Contract'");
//
//  // Switching the output mode in report panels:
//  // Grouping report options by this report:
//	ReportsOptions.SetOutputModeInReportPanels(Settings, Metadata.Reports.NameOfReport, True);
//  // Without grouping by the report:
//	Report = ReportsOptions.ReportDetails(Settings, Metadata.Reports.NameOfReport);
//	ReportOptions.SetOutputModeInReportPanels(Settings, Report, False);
//
Procedure CustomizeReportsOptions(Settings) Export
	
	
	
EndProcedure

// Registers changes in report option names.
// It is used when updating to keep reference integrity, in particular for saving user settings and 
// mailing report settings.
// Old option name is reserved and cannot be used later.
// If there are several changes, each change must be registered by specifying the last (current) 
// report option name in the relevant option name.
// Since the names of report options are not displayed in the user interface, it is recommended to 
// set them in such a way that they would not be changed.
// Add to Changes the details of changes in names of the report options connected to the subsystem.
// 
//
// Parameters:
//   Changes - ValueTable - a table of report option name changes. Columns:
//       * Report - MetadataObject - metadata of the report whose schema contains the changed option name.
//       * OldOptionName - String - old option name before changes.
//       * RelevantOptionName - String - current (last relevant) option name.
//
// Example:
//	Change = Changes.Add();
//	Change.Report = Metadata.Reports.<NameOfReport>;
//	Change.OldOptionName = "<OldOptionName>";
//	Change.RelevantOptionName = "<RelevantOptionName>";
//
Procedure RegisterChangesOfReportOptionsKeys(Changes) Export
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Report command settings

// Determines configuration objects whose manager modules support the AddReportsCommands procedure 
// describing context report opening commands.
// See the help for the AddReportsCommands procedure syntax.
//
// Parameters:
//  Objects - Array - metadata objects (MetadataObject) with report commands.
//
Procedure DefineObjectsWithReportCommands(Objects) Export
	
EndProcedure

// Determining a list of global report commands.
// The event occurs when calling a re-use module.
//
// Parameters:
//  ReportsCommands - ValueTable - a table of commands to be shown in the submenu. For changing.
//       * ID - String - a command ID.
//     
//     Appearance settings:
//       * Presentation - String   - command presentation in a form.
//       * Importance      - String   - a suffix of a submenu group in which the command is to be output.
//                                    The following values are acceptable: "Important", "Ordinary", and "SeeAlso".
//       * Order       - Number    - a command position in the group. It is used to set up a 
//                                    particular workplace.
//       * Picture      - Picture - a command picture.
//       * Shortcut - Shortcut - a shortcut for fast command call.
//     
//     Visibility and availability settings:
//       * ParameterType - TypesDetails - types of objects that the command is intended for.
//       * VisibilityOnForms    - String - comma-separated names of forms on which the command is to be displayed.
//                                        Used when the command content is different for different forms.
//       * FunctionalOptions - String - comma-separated  names of functional options that define the command visibility.
//       * VisibilityConditions    - Array - defines the command visibility depending on the context.
//                                        To register conditions, use procedure
//                                        AttachableCommands.AddCommandVisibilityCondition().
//                                        The conditions are combined by "And".
//       * ChangesSelectedObjects - Boolean - defines whether the command is available in case a 
//                                        user is not authorized to edit the object.
//                                        If True, the button will be unavailable.
//                                        Optional. The default value is False.
//     
//     Execution process settings:
//       * MultipleChoice - Boolean, Undefined - if True, then the command supports multiple choice.
//             In this case, the parameter is passed via a list.
//             Optional. The default value is True.
//       * WriteMode - String - actions associated with object writing that are executed before the command handler.
//             ** "DoNotWrite"          - do not write the object and pass the full form in the 
//                                       handler parameters instead of references. In this mode, we 
//                                       recommend that you operate directly with a form that is passed in the structure of parameter 2 of the command handler.
//             ** "WriteNewOnly" - write only new objects.
//             ** "Write"            - write only new and modified objects.
//             ** "Post"             - post documents.
//             Before writing or posting the object, users are asked for confirmation.
//             Optional. Default value is "Write".
//       * FilesOperationsRequired - Boolean - if True, in the web client, users are prompted to 
//             install the file system extension.
//             Optional. The default value is False.
//     
//     Handler settings:
//       * Manager - String - a full name of the metadata object responsible for executing the command.
//             Example: "Report._DemoPurchaseLedger".
//       * FormName - String - a name of the form to be open or retrieved for the command execution.
//             If Handler is not specified, the "Open" form method is called.
//       * OptionKey - String - a name of the report option opened upon command execution.
//       * FormParameterName - String - a name of the form parameter to which a reference or a reference array is to be passed.
//       * FormParameters - Undefined, Structure - parameters of the form, specified in the FormName.
//       * Handler - String - details of the procedure that handles the main action of the command.
//             Format "<CommonModuleName>.<ProcedureName>" is used when the procedure is in a common module.
//             Format "<ProcedureName>" is used in the following cases:
//               - If FormName is filled, a client procedure is expected in the module of the specified form.
//               - If FormName is not filled, a server procedure is expected in the manager module.
//       * AdditionalParameters - Structure - parameters of the handler, specified in the Handler.
//   
//  Parameters - Structure - info about execution context.
//       * FormName - String - full name of the form.
//   
//  StandardProcessing - Boolean - if False, the AddReportsCommands event of the object manager is 
//                                  not called.
//
Procedure BeforeAddReportCommands(ReportsCommands, Parameters, StandardProcessing) Export
	
	
	
EndProcedure

#EndRegion
