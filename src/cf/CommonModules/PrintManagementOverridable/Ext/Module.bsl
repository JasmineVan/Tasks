///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Public

// Defines configuration objects, in whose manager modules the AddPrintCommands procedure is placed. 
// The procedure generates a print command list provided by this object.
// See syntax of the AddPrintCommands procedure in the subsystem documentation.
//
// Parameters:
//  ObjectsList - Array - object managers with the AddPrintCommands procedure.
//
Procedure OnDefineObjectsWithPrintCommands(ObjectsList) Export
	
	
	
EndProcedure

// Allows to override a list of print commands in an arbitrary form.
// Can be used for common forms that do not have a manager module to place the AddPrintCommands 
// procedure in it and when the standard functionality is not enough to add commands to such forms.
// For example, if common forms require specific print commands.
// It is called from the PrintManager.FormPrintCommands.
// 
// Parameters:
//  FormName - String - a full name of form, in which print commands are added.
//  PrintCommands - ValueTable - see PrintManager.CreatePrintCommandsCollection. 
//  StandardProcessing - Boolean - when setting to False, the PrintCommands collection will not be filled in automatically.
//
// Example:
//  If FormName = "CommonForm.DocumentJournal" Then
//    If Users.RolesAvailable("PrintProformaInvoiceToPrinter") Then
//      PrintCommand = PrintCommands.Add();
//      PrintCommand.ID = "Invoice";
//      PrintCommand.Presentation = NStr("en = 'Proforma invoice to printer)'");
//      PrintCommand.Picture = PictureLib.PrintImmediately;
//      PrintCommand.CheckPostingBeforePrint = True;
//      PrintCommand.SkipPreview = True;
//    EndIf;
//  EndIf;
//
Procedure BeforeAddPrintCommands(FormName, PrintCommands, StandardProcessing) Export
	
EndProcedure

// Allows to set additional print command settings in document journals.
//
// Parameters:
//  ListSettings - Structure - print command list modifiers.
//   * PrintCommandsManager - ObjectManager - an object manager, in which the list of print commands is generated.
//   * Autofill - Boolean - filling print commands from the objects included in the journal.
//                                         If the value is False, the list of journal print commands 
//                                         will be filled by calling the AddPrintCommands method from the journal manager module.
//                                         The default value is True - the AddPrintCommands method 
//                                         will be called from the document manager modules from the journal.
//
// Example:
//   If ListSettings.PrintCommandsManager = "DocumentJournal.WarehouseDocuments" Then
//     ListSettings.Autofill = False;
//   EndIf;
//
Procedure OnGetPrintCommandListSettings(ListSettings) Export
	
EndProcedure

// Allows you to post-process print forms while generating them.
// For example, you can insert a date of print form generation to the header or footer.
// It is called after completing the Print procedure of the object print manager and has the same parameters.
//
// Parameters:
//  ObjectsArray - Array - a list of objects, for which the Print procedure was executed.
//  PrintParameters - Structure - arbitrary parameters passed when calling the print command.
//  PrintFormsCollection - ValueTable - contains generated spreadsheet documents and additional information.
//  PrintObjects - ValueList - correspondence between objects and names of areas in spreadsheet 
//                                   documents, where the value is Object, and the presentation is an area name with the object in spreadsheet documents.
//  OutputParameters - Structure - parameters connected to output of spreadsheet documents:
//   * SendOptions - Structure - for filling in a message when sending a print form by email.
//                    see EmailOperationsClient.EmailOperationsClient.EmailSendOptions. 
//
// Example:
//   PrintForm = PrintManager.PrintFormInfo(PrintFormsCollection, "ActSales");
//   If PrintForm <> Undefined, Then
//     PrintForm.SpreadsheetDocument.LeftMargin = 20;
//     ...
//
Procedure OnPrint(ObjectsArray, PrintParameters, PrintFormsCollection, PrintObjects, OutputParameters) Export
	
	
	
EndProcedure

// Overrides the print form send parameters when preparing a message.
// It can be used, for example, to prepare a message text.
//
// Parameters:
//  SendOptions - Structure - a collection of the following parameters:
//   * Recipient - Array - a collection of recipient names.
//   * Subject - String - an email subject.
//   * Text - String - an email text.
//   * Attachments - Structure - a collection of attachments:
//    ** AddressInTempStorage - String - an attachment address in a temporary storage.
//    ** Presentation - String - an attachment file name.
//  PrintObjects - Array - a collection of objects, by which print forms are generated.
//  OutputParameters - Structure - the OutputParameters parameter when calling the Print procedure.
//  PrintForms - ValueTable - a collection of spreadsheet documents:
//   * Name - String - a print form name.
//   * SpreadsheetDocument - SpreadsheetDocument - a print form.
//
Procedure BeforeSendingByEmail(SendOptions, OutputParameters, PrintObjects, PrintForms) Export
	
	
	
EndProcedure

// Defines a set of signatures and seals for documents.
//
// Parameters:
//  Document      - Array    - a collection of references to print objects.
//  SignaturesAndSeals - Map - a collection of print objects and their sets of signatures and seals.
//   * Key - AnyRef - a reference to the print object.
//   * Value - Structure - a set of signatures and seals:
//     ** Key     - String - an ID of signature or seal in print form template. It must start with 
//                            "Signature...", "Seal...", or "Facsimile", for example, 
//                            ManagerSignature or CompanySeal.
//     ** Value - Picture - a picture of signature or seal.
//
Procedure OnGetSignaturesAndSeals(Documents, SignaturesAndSeals) Export
	
	
	
EndProcedure

// It is called from the OnCreateAtServer handler of the document prin form (CommonForm.PrintDocuments).
// Allows to change form appearance and behavior, for example, place the following additional items on it:
// information labels, buttons, hyperlinks, various settings, and so on.
//
// When adding commands (buttons), specify the Attachable_ExecuteCommand name as a handler and place 
// its implementation either to PrintManagerOverridable.PrintDocumentsOnExecuteCommand (server part), 
// or to PrintManagerClientOverridable.PrintDocumentsExecuteCommand (client part).
//
// To add your command to the form:
// 1. Create a command and a button in PrintManagerOverridable.PrintDocumentsOnCreateAtServer.
// 2. Implement the command client handler in PrintManagerClientOverridable.PrintDocumentsExecuteCommand.
// 3. (Optional) Implement server command handler in PrintManagerOverridable.PrintDocumentsOnExecuteCommand.
//
// When adding hyperlinks as a click handler, specify the AttachableAttachableURLProcessing name and 
// place its implementation to PrintManagerClientOverridable.PrintDocumentsURLProcessing.
//
// When placing items whose values must be remembered between print form openings, use the 
// PrintDocumentsOnImportDataFromSettingsAtServer and
// PrintDocumentsOnSaveDataInSettingsAtServer procedures.
//
// Parameters:
//  Form                - ManagedForm - CommonForm.PrintDocuments form.
//  Cancel                - Boolean - indicates that the form creation is canceled. If this 
//                                  parameter is set to True, the form is not created.
//  StandardProcessing - Boolean - a flag indicating whether the standard (system) event processing 
//                                  is executed is passed to this parameter. If this parameter is 
//                                  set to False, standard event processing will not be carried out.
// 
// Example:
//  FormCommand = Form.Command.Add("MyCommand");
//  FormCommand.Action = "Attachable_ExecuteCommand";
//  FormCommand.Header = NStr("en = 'MyCommand...'");
//  
//  FormButton = Form.Items.Add(FormCommand.Name, Type("FormButton"), Form.Items.CommandBarRightPart);
//  FormButton.Kind = FormButtonKind.CommandBarButton;
//  FormButton.CommandName = FormCommand.Name;
//
Procedure PrintDocumentsOnCreateAtServer(Form, Cancel, StandardProcessing) Export
	
	
	
EndProcedure

// It is called from the OnImportDataFromSettingsAtServer handler of the document print form (CommonForm.PrintDocuments).
// Together with PrintDocumentsOnSaveDataInSettingsAtServer, it allows you to import and save form 
// control settings placed using PrintDocumentsOnCreateAtServer.
//
// Parameters:
//  Form     - ManagedForm - CommonForm.PrintDocuments form.
//  Settings - Map     - form attribute values.
//
Procedure PrintDocumentsOnImportDataFromSettingsAtServer(Form, Settings) Export
	
EndProcedure

// It is called from the OnSaveDataInSettingsAtServer handler of the document print form (CommonForm.PrintDocuments).
// Together with PrintDocumentsOnImportDataFromSettingsAtServer, it allows you to import and save 
// form control settings placed using PrintDocumentsOnCreateAtServer.
//
// Parameters:
//  Form     - ManagedForm - CommonForm.PrintDocuments form.
//  Settings - Map     - form attribute values.
//
Procedure PrintDocumentsOnSaveDataInSettingsAtServer(Form, Settings) Export

EndProcedure

// It is called from the Attachable_ExecuteCommand handler of the document printing form (CommonForm.PrintDocuments).
// It allows you to implement server part of the command handler added to the form using 
// PrintDocumentsOnCreateAtServer.
//
// Parameters:
//  Form                   - ManagedForm - CommonForm.PrintDocuments.
//  AdditionalParameters - Arbitrary     - parameters passed from PrintManagerClientOverridable.PrintDocumentsExecuteCommand.
//
// Example:
//  If TypeOf(AdditionalParameters) = Type("Structure") AND AdditionalParameters.CommandName = "MyCommand" Then
//   SpreadsheetDocument = New SpreadsheetDocument;
//   SpreadsheetDocument.Area("R1C1").Text = NStr("en = 'An example of using a server handler of the attached command.'");
//  
//   PrintForm = Form[AdditionalParameters.SpreadsheetDocumentAttributeName];
//   PrintFrom.InsertArea(SpreadsheetDocument.Area("R1"), PrintForm.Area("R1"),
//    SpreadsheetDocumentShiftType.Horizontally)
//  EndIf;
//
Procedure PrintDocumentsOnExecuteCommand(Form, AdditionalParameters) Export
	
EndProcedure

#EndRegion
