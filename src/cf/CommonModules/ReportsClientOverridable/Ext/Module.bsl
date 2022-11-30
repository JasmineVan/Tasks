///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Public

// It appears after report is generated: after background job is completed.
// Allows to override a data processor of report generation result.
//
// Parameters:
//  ReportForm - ManagedForm - a report form.
//  ReportCreated - Boolean - True if the report has been successfully generated.
//
Procedure AfterGenerate(ReportForm, ReportCreated) Export
	
EndProcedure

// The details handler of a spreadsheet document of a report form.
// See "Form field extension for a spreadsheet document field.DetailProcessing" in Syntax Assistant.
//
// Parameters:
//   ReportForm - ManagedForm - a report form.
//   Item     - FormField        - a spreadsheet document.
//   Details - Arbitrary - details value of a point, series, or a chart value.
//   StandardProcessing - Boolean - a flag of standard (system) event processing execution.
//
Procedure DetailProcessing(ReportForm, Item, Details, StandardProcessing) Export
	
EndProcedure

// The handler of additional details (menu of a spreadsheet document of a report form).
// See "Form field extension for a spreadsheet document field.AdditionalDetailProcessing" in Syntax Assistant.
//
// Parameters:
//   ReportForm - ManagedForm - a report form.
//   Item     - FormField        - a spreadsheet document.
//   Details - Arbitrary - details value of a point, series, or a chart value.
//   StandardProcessing - Boolean - a flag of standard (system) event processing execution.
//
Procedure AdditionalDetailProcessing(ReportForm, Item, Details, StandardProcessing) Export
	
EndProcedure

// Handler of commands that were dynamically added and attached to the Attachable_Command handler.
// See an example of adding a command in ReportsOverridable.OnCreateAtServer(). 
//
// Parameters:
//   ReportForm - ManagedForm - a report form.
//   Command     - FormCommand - a command that was called.
//   Result   - Boolean           - True if the command call is processed.
//
Procedure CommandHandler(ReportForm, Command, Result) Export
	
	
	
EndProcedure

// Handler of the subordinate form selection result.
// See ManagedForm.ChoiceProcessing in Syntax Assistant.
//
// Parameters:
//   ReportForm       - ManagedForm - a report form.
//   SelectedValue - Arbitrary     - a selection result in a subordinate form.
//   ChoiceSource    - ManagedForm - a form where the choice is made.
//   Result - Boolean - True if the selection result is processed.
//
Procedure ChoiceProcessing(ReportForm, SelectedValue, ChoiceSource, Result) Export
	
EndProcedure

// Handler for double click, clicking Enter, or a hyperlink in a report form spreadsheet document.
// See "Form field extension for a spreadsheet document field.Choice" in Syntax Assistant.
//
// Parameters:
//   ReportForm - ManagedForm - a report form.
//   Item     - FormField        - a spreadsheet document.
//   Area     - SpreadsheetDocumentCellsArea - a selected value.
//   StandardProcessing - Boolean - indicates that event is processed in a standard way.
//
Procedure SpreadsheetDocumentSelectionHandler(ReportForm, Item, Area, StandardProcessing) Export
	
EndProcedure

// Handler of report form broadcast notification.
// See ManagedForm.NotificationProcessing in Syntax Assistant.
//
// Parameters:
//   ReportForm - ManagedForm - a report form.
//   EventName  - String           - an event ID for receiving forms.
//   Parameter    - Arbitrary     - extended informaion about an event.
//   Source    - ManagedForm, Arbitrary - an event source.
//   NotificationProcessed - Boolean - indicates that an event is processed.
//
Procedure NotificationProcessing(ReportForm, EventName, Parameter, Source, NotificationProcessed) Export
	
EndProcedure

// Handler of clicking the period selection button in a separate form.
//
// Parameters:
//   ReportForm - ManagedForm - a report form.
//   Period - StandardPeriod - a composer setting value that matches the selected period.
//   StandardProcessing - Boolean - if True, the standard period selection dialog box will be used.
//       If it is set to False, the standard dialog box will not open.
//   ResultHandler - NotifyDescription - a handler of period selection result.
//       The following type values can be passed to the ResultHandler as the result:
//       Undefined - user canceled the period input.
//       StandardPeriod - the selected period.
//
//  If the configuration uses its own period selection dialog box, set the StandardProcessing 
//      parameter to False and return the selected period to ResultHandler.
//      
//
Procedure OnClickPeriodSelectionButton(ReportForm, Period, StandardProcessing, ResultHandler) Export
	
EndProcedure

#EndRegion
