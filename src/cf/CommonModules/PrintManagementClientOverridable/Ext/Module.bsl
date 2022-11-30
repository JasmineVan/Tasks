///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Public

// It is called after executing the OnOpen handler of document printing form (CommonForm.PrintDocuments).
//
// Parameters:
//  Form - ManagedForm - CommonForm.PrintDocuments form.
//
Procedure PrintDocumentsAfterOpen(Form) Export
	
EndProcedure

// It is called from the Attachable_URLProcessing handler of the document printing form (CommonForm.PrintDocuments).
// Allows to implement a handler of clicking a hyperlink added to the form using 
// PrintManagerOverridable.PrintDocumentsOnCreateAtServer.
//
// Parameters:
//  Form                - ManagedForm - CommonForm.PrintDocuments form.
//  Item              - FormField - a form item that caused this event.
//  FormattedStringURL - String - a value of the formatted string URL. It is passed by the link.
//  StandardProcessing - Boolean - indicates a standard (system) event processing execution. If it 
//                                  is set to False, standard event processing will not be performed.
//
Procedure PrintDocumentsURLProcessing(Form, Item, FormattedStringURL, StandardProcessing) Export
	
	
	
EndProcedure

// It is called from the Attachable_ExecuteCommand handler of the document printing form (CommonForm.PrintDocuments).
// It allows to implement a client part of the command handler that is added to the form using 
// PrintManagerOverridable.PrintDocumentsOnCreateAtServer.
//
// Parameters:
//  Form                         - ManagedForm - CommonForm.PrintDocuments form.
//  Command                       - FormCommand     - a running command.
//  ContinueExecutionAtServer - Boolean - when set to True, the handler will continue to run in the 
//                                           server context in the PrintManagerOverridable.PrintDocumentsOnExecuteCommand procedure.
//  AdditionalParameters - Arbitrary - parameters to be passed to the server context.
//
// Example:
//  If Command.Name = "MyCommand" Then
//   PrintFormSetting = PrintManagerClient.CurrentPrintFormSetting(Form);
//   
//   AdditionalParameters = New Structure;
//   AdditionalParameters.Insert("CommandName", Command.Name);
//   AdditionalParameters.Insert("SpreadsheetDocumentAttributeName", PrintFormSetting.AttributeName);
//   AdditionalParameters.Insert("PrintFormName", PrintFormSetting.Name);
//   
//   ContinueExecutionAtServer = True;
//  EndIf;
//
Procedure PrintDocumentsExecuteCommand(Form, Command, ContinueExecutionAtServer, AdditionalParameters) Export
	
EndProcedure

#EndRegion
