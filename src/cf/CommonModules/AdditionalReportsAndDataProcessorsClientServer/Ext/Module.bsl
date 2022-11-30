///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Public

////////////////////////////////////////////////////////////////////////////////
// Names of object kinds.

// Print form.
//
// Returns:
//   String - a name of the additional print form kind.
//
Function DataProcessorKindPrintForm() Export
	
	Return "PrintForm"; // Internal ID.
	
EndFunction

// Filling an object.
//
// Returns:
//   String - a name of the additional filling data processor kind.
//
Function DataProcessorKindObjectFilling() Export
	
	Return "ObjectFilling"; // Internal ID.
	
EndFunction

// Creating related objects.
//
// Returns:
//   String - a name of a kind of additional data processors for related object creation.
//
Function DataProcessorKindRelatedObjectCreation() Export
	
	Return "RelatedObjectsCreation"; // Internal ID.
	
EndFunction

// Assignable report.
//
// Returns:
//   String - a name of the additional context report kind.
//
Function DataProcessorKindReport() Export
	
	Return "Report"; // Internal ID.
	
EndFunction

// Creating related objects.
//
// Returns:
//   String - a name of the additional context report kind.
//
Function DataProcessorKindMessageTemplate() Export
	
	Return "MessageTemplate"; // Internal ID.
	
EndFunction

// Additional data processor.
//
// Returns:
//   String - a name of the additional global data processor kind.
//
Function DataProcessorKindAdditionalDataProcessor() Export
	
	Return "AdditionalDataProcessor"; // Internal ID.
	
EndFunction

// Additional report.
//
// Returns:
//   String - a name of the additional global report kind.
//
Function DataProcessorKindAdditionalReport() Export
	
	Return "AdditionalReport"; // Internal ID.
	
EndFunction

////////////////////////////////////////////////////////////////////////////////
// Command type names.

// Returns the name of the command type with a server method call. To execute commands of this type, 
//   in the object module, determine the export procedure using the following template:
//   
//   For global reports and data processors (Kind = "AdditionalDataProcessor" or Kind = "AdditionalReport"):
//       // Server command handler.
//       //
//       // Parameters:
//       //   CommandID - String    - a command name determined using function ExternalDataProcessorInfo().
//       //   ExecutionParameters  - Structure - command execution context.
//       //       * AdditionalDataProcessorRef - CatalogRef.AdditionalReportsAndDataProcessors - a data processor reference.
//       //           Can be used for reading data processor parameters.
//       //           See an example in the comment to function AdditionalReportsAndDataProcessorsClientServer.CommandTypeOpenForm().
//       //       * ExecutionResult - Structure - a command execution result.
//       //           Can be used for passing the result from server or from a background job to the initial point.
//       //           In particular, it is returned by functions AdditionalReportsAndDataProcessors.ExecuteCommand()
//       //           and AdditionalReportsAndDataProcessors.ExecuteCommandFromExternalObjectForm().
//       //           It can also be obtained from the temporary storage
//       //           in the idle handler of procedure AdditionalReportsAndDataProcessorsClient.ExecuteCommnadInBackground().
//       //
//       Procedure ExecuteCommand(CommandID, ExecutionParameters) Export
//       	// Implementing command logic.
//       EndProcedure
//   
//   For print forms (Kind = "PrintForm"):
//       // Print handler.
//       //
//       // Parameters:
//       //   ObjectsArray - Array - references to objects to be printed.
//       //   PrintFormsCollection - ValueTable - information on spreadsheet documents.
//       //       The parameter is used for passing function PrintManager.PrintFormInfo() in the parameters.
//       //   PrintObjects - ValueList - a map between objects and names of spreadsheet document areas.
//       //       The parameter is used for passing procedure  PrintManager.SetDocumentPrintArea() in the parameters.
//       //   OutputParameters - Structure - additional parameters of generated spreadsheet documents.
//       //       * AdditionalDataProcessorRef - CatalogRef.AdditionalReportsAndDataProcessors - a data processor reference.
//       //           Can be used for reading data processor parameters.
//       //           See an example in the comment to function AdditionalReportsAndDataProcessorsClientServer.CommandTypeOpenForm().
//       //
//       // Example:
//       //  	PrintForm = PrintManager.PrintFormInfo(PrintFormsCollection, "<PrintFormID>").
//       //  	If PrintForm <> Undefined Then
//       //  		SpreadsheetDocument = New SpreadsheetDocument.
//       //  		SpreadsheetDocument.PrintParametersKey = "<PrintFormParametersSaveKey>".
//       //  		For Each Ref In ObjectsArray Do
//       //  			If SpreadsheetDocument.TableHeight > 0 Then
//       //  				SpreadsheetDocument.OutputHorizontalPageBreak();
//       //  			EndIf;
//       //  			AreaBegin = SpreadsheetDocument.TableHeight + 1.
//       //  			// ... spreadsheet document generation code ...
//       //  			PrintManager.SetDocumentPrintArea(SpreadsheetDocument, AreaBegin, PrintObjects, Ref).
//       //  		EndDo.
//       //  		PrintForm.SpreadsheetDocument = SpreadsheetDocument.
//       //  	EndIf.
//       //
//       Procedure Print(ObjectsArray, PrintFormsCollection, PrintObjects, OutputParameters) Export
//       	// Implementing command logic.
//       EndProcedure
//   
//   For data processors of related object creation (Kind = "RelatedObjectsCreation"):
//       // Server command handler.
//       //
//       // Parameters:
//       //   CommandID - String - a command name determined using function ExternalDataProcessorInfo().
//       //   RelatedObjects    - Array - references to the objects the command is called for.
//       //   CreatedObjects     - Array - references to the objects created while executing the command.
//       //   ExecutionParameters  - Structure - command execution context.
//       //       * AdditionalDataProcessorRef - CatalogRef.AdditionalReportsAndDataProcessors - a data processor reference.
//       //           Can be used for reading data processor parameters.
//       //           See an example in the comment to function AdditionalReportsAndDataProcessorsClientServer.CommandTypeOpenForm().
//       //       * ExecutionResult - Structure - a command execution result.
//       //           Can be used for passing the result from server or from a background job to the initial point.
//       //           In particular, it is returned by functions AdditionalReportsAndDataProcessors.ExecuteCommand()
//       //           and AdditionalReportsAndDataProcessors.ExecuteCommandFromExternalObjectForm().
//       //           It can also be obtained from the temporary storage
//       //           in the idle handler of procedure AdditionalReportsAndDataProcessorsClient.ExecuteCommnadInBackground().
//       //
//       Procedure ExecuteCommand(CommandID, RelatedObjects, CreatedObjects, ExecutionParameters) Export
//       	// Implementing command logic.
//       EndProcedure
//   
//   For filling data processors (Kind = "ObjectFilling"):
//       // Server command handler.
//       //
//       // Parameters:
//       //   CommandID - String - a command name determined using function ExternalDataProcessorInfo().
//       //   RelatedObjects    - Array - references to the objects the command is called for.
//       //       - Undefined - for commands FillingForm.
//       //   ExecutionParameters  - Structure - command execution context.
//       //       * AdditionalDataProcessorRef - CatalogRef.AdditionalReportsAndDataProcessors - a data processor reference.
//       //           Can be used for reading data processor parameters.
//       //           See an example in the comment to function AdditionalReportsAndDataProcessorsClientServer.CommandTypeOpenForm().
//       //       * ExecutionResult - Structure - a command execution result.
//       //           Can be used for passing the result from server or from a background job to the initial point.
//       //           In particular, it is returned by functions AdditionalReportsAndDataProcessors.ExecuteCommand()
//       //           and AdditionalReportsAndDataProcessors.ExecuteCommandFromExternalObjectForm().
//       //           It can also be obtained from the temporary storage
//       //           in the idle handler of procedure AdditionalReportsAndDataProcessorsClient.ExecuteCommnadInBackground().
//       //
//       Procedure ExecuteCommand(CommandID, RelatedObjects, ExecutionParameters) Export
//       	// Implementing command logic.
//       EndProcedure
//
// Returns:
//   String - a name of the command type with a server method call.
//
Function CommandTypeServerMethodCall() Export
	
	Return "ServerMethodCall"; // Internal ID.
	
EndFunction

// Returns the name of the command type with a client method call. To execute commands of this type, 
//   in the main form of the external object, determine the client export procedure using the following template:
//   
//   For global reports and data processors (Kind = "AdditionalDataProcessor" or Kind = "AdditionalReport"):
//       &AtClient
//       Procedure ExecuteCommand(CommandID) Export
//       	// Implementing command logic.
//       EndProcedure
//   
//   For print forms (Kind = "PrintForm"):
//       &AtClient
//       Procedure Print(CommandID, RelatedObjectsArray) Export
//       	// Implementing command logic.
//       EndProcedure
//   
//   For data processors of related object creation (Kind = "RelatedObjectsCreation"):
//       &AtClient
//       Procedure ExecuteCommand(CommandID, RelatedObjectsArray, CreatedObjects) Export
//       	// Implementing command logic.
//       EndProcedure
//   
//   For filling data processors and context reports (Kind = "ObjectFilling" or Kind = "Report"):
//       &AtClient
//       Procedure ExecuteCommand(CommandID, RelatedObjectsArray) Export
//       	// Implementing command logic.
//       EndProcedure
//   
//   Additionally, (for all kinds) in the AdditionalDataProcessorRef form parameter, a reference to 
//     this object is passed (an AdditionalReportsAndDataProcessors catalog item matching the 
//     object). The reference can be used for running time-consuming operations in the background.
//     For more information, see subsystem help, section "Running time-consuming operations in the background" (in Russian).
//
// Returns:
//   String - a name of the command type with a client method call.
//
Function CommandTypeClientMethodCall() Export
	
	Return "ClientMethodCall"; // Internal ID.
	
EndFunction

// Returns a name of a type of commands for opening a form. When executing these commands, the main 
//   form of the external object opens with the parameters specified below.
//
//   Common parameters:
//       * CommandID - String - a command name determined using function ExternalDataProcessorInfo().
//       * AdditionalDataProcessorRef - CatalogRef.AdditionalReportsAndDataProcessors - a reference to the object.
//           Can be used for reading and saving data processor parameters.
//           It can also be used for running time-consuming operations in the background.
//           For more information, see subsystem help, section "Running time-consuming operations in the background" (in Russian).
//       * FormName - String - a name of the owner form the command is called from.
//   
//   Auxiliary parameters for data processors of related object creation (Kind = 
//   "RelatedObjectsCreation"), filling data processors (Kind = "ObjectFilling"), and context reports (Kind = "Report"):
//       * RelatedObjects - Array - references to the objects the command is called for.
//   
//   Example of reading common parameter values:
//       	ObjectRef = CommonClientServer.StructureProperty(Parameters, "AdditionalDataProcessorRef").
//       	CommandID = CommonClientServer.StructureProperty(Parameters, "CommandID").
//   
//   Example of reading additional parameter values:
//       	If ValueIsFilled(ObjectRef) Then
//       		SettingsStorage = Common.ObjectAttributeValue(ObjectRef, "SettingsStorage").
//       		Settings = SettingsStorage.Get().
//       		If ValueType(Settings) = Type("Structure") Then
//       			FillPropertyValues(ThisObject, "<SettingsNames>").
//       		EndIf.
//       	EndIf.
//   
//   Example of saving values of additional settings:
//       	Settings = New Structure("<SettingsNames>", <SettingsValues>).
//       	AdditionalDataProcessorObject = ObjectRef.GetObject().
//       	AdditionalDataProcessorObject.SettingsStorage = New ValueStorage(Settings).
//       	AdditionalDataProcessorObject.Write().
//
// Returns:
//   String - a name of a type of commands for opening a form.
//
Function CommandTypeOpenForm() Export
	
	Return "OpeningForm"; // Internal ID.
	
EndFunction

// Returns a name of a type of commands for filling a form without writing the object. These 
//   commands are available only in filling data processors (Kind = "ObjectFilling").
//   To execute commands of this type, in the object module, determine the export procedure using the following template:
//       // Server command handler.
//       //
//       // Parameters:
//       //   CommandID - String - a command name determined using function ExternalDataProcessorInfo().
//       //   RelatedObjects    - Array - references to the objects the command is called for.
//       //       - Undefined - not passed for commands of the FillingForm type.
//       //   ExecutionParameters  - Structure - command execution context.
//       //       * ThisForm - ManagedForm - a form being filled in. The parameter is passed for commands of the FillingForm type.
//       //       * AdditionalDataProcessorRef - CatalogRef.AdditionalReportsAndDataProcessors - a data processor reference.
//       //           Can be used for reading data processor parameters.
//       //           See an example in the comment to function AdditionalReportsAndDataProcessorsClientServer.CommandTypeOpenForm().
//       //
//       Procedure ExecuteCommand(CommandID, RelatedObjects, ExecutionParameters) Export
//       	// Implementing command logic.
//       EndProcedure
//
// Returns:
//   String - a name of a type of commands for filling a form.
//
Function CommandTypeFormFilling() Export
	
	Return "FillingForm"; // Internal ID.
	
EndFunction

// Returns a name of a type of commands for scenario execution in safe mode.
//   To execute commands of this type, in the object module, determine the export procedure using the following template:
//       // Generating command execution scenario using module interface
//       //   AdditionalReportsAndDataProcessorsSafeModeInterface.
//       //   Functions that add scenario stages:
//       //       AddConfigurationMethod() adds a configuration procedure or function call to the scenario.
//       //         The function returns a scenario stage that can be used in a parameter filling function later.
//       //       AddDataProcessorMethod() adds a call of a procedure or function of an additional data processor object to a scenario.
//       //         The function returns a scenario stage that can be used in a parameter filling function later.
//       //   Procedures that register the parameters to be passed to the procedure or function handling the stage:
//       //       AddSessionKey() adds the current session key of safe mode extension to the array of parameters.
//       //       AddValue() adds a fixed value of an arbitrary type to the array of parameters.
//       //       AddValueToSave() adds a value to be saved to the array of parameters.
//       //       AddCollectionOfValuesToSave() adds a collection of values to be saved to the array of parameters.
//       //       AddCommandRunParameter() adds an item of the CommandExecuteParameters structure to the array of parameters.
//       //       AddRelatedObjects() adds an array of objects that are subject to report or data processor commands to the array of parameters.
//       //         (only applies to additional data processors to be assigned).
//       //   For more information, see subsystem help, section "Safe mode extension" (in Russian).
//       //
//       // Parameters:
//       //   CommandID - String - a command name determined using function ExternalDataProcessorInfo().
//       //   ExecutionParameters  - Structure - command execution context.
//       //       * AdditionalDataProcessorRef - CatalogRef.AdditionalReportsAndDataProcessors - a reference to the object.
//       //           Can be used for reading data processor parameters.
//       //           See an example in the comment to function AdditionalReportsAndDataProcessorsClientServer.CommandTypeOpenForm().
//       //
//       // Returns:
//       //   ValueTable - for more information, see  AdditionalReportsAndDataProcessorsSafeModeInterface.NewScenario().
//       //
//       Function GenerateScenario(CommandID, ExecutionParameters) Export
//       	Scenario = AdditionalReportsAndDataProcessorsSafeModeInterface.NewScenario().
//       	// Generating a scenario.
//       	Return Scenario.
//       EndFunction
//
// Returns:
//   String -  a name of a type of commands for scenario execution in safe mode.
//
Function CommandTypeScenarioInSafeMode() Export
	
	Return "ScenarioInSafeMode"; // Internal ID.
	
EndFunction

// Returns a name of a type of commands for importing data from a file.  These commands are 
//   available only in global data processors (Kind = "AdditionalDataProcessor") provided that the 
//   configuration includes the ImportDataFromFiles subsystem.
//   To execute commands of this type, in the object module, determine export procedures using the following template:
//       // Determines parameters of data import from a file.
//       //
//       // Parameters:
//       //   CommandID - String - a command name determined using function ExternalDataProcessorInfo().
//       //   ImportParameters - Structure - data import settings:
//       //       * DataStructureTemplateName - String - a name of the template for data to import.
//       //           Default template is ImportFromFile.
//       //       * MandatoryTemplateColumns - Array - a list of names of required columns.
//       //
//       Procedure GetDataImportFromFileParameters(CommandID, ImportParameters) Export
//       	// Overriding settings of data import from a file.
//       EndProcedure
//       
//       // Maps the data to import with the existing infobase data.
//       //
//       // Parameters:
//       //   CommandID - String - a command name determined using function ExternalDataProcessorInfo().
//       //   DataToImport - ValueTable - details of data to import:
//       //       * MappedObject - CatalogRef.Ref - a reference to the mapped object.
//       //           It is populated inside the procedure
//       //       * <other columns> - String - data imported from the file.
//       //           Columns are the same as in the ImportFromFile template.
//       //
//       Procedure MapDataToImportFromFile(CommandID, DataToImport) Export
//       	// Implementing logic of data search in the application.
//       EndProcedure
//       
//       // Imports mapped data into the infobase.
//       //
//       // Parameters:
//       //   CommandID - String - a command name determined using function ExternalDataProcessorInfo().
//       //   DataToImport - ValueTable - details of data to import:
//       //       * MappedObject - CatalogRef - a reference to the mapped object.
//       //       * RowMappingResult - String - an import status. Possible values: Created, Updated, and Skipped.
//       //       * ErrorDescription   - String - data import error details.
//       //       * ID    - Number  - a unique row number.
//       //       * <other columns> - String - data imported from the file.
//       //           Columns are the same as in the ImportFromFile template.
//       //   ImportParameters - Structure - parameters with custom settings of data import.
//       //       * CreateNewItems        - Boolean - indicates whether new catalog items are to be created.
//       //       * UpdateExistingItems - Boolean - indicates whether catalog items are to be updated.
//       //   Cancel - Boolean - indicates whether data import is canceled.
//       //
//       Procedure LoadFromFile(CommandID, DataToImport, ImportParameters, Cancel) Export
//       	// Implementing logic of data import into the application.
//       EndProcedure
//
// Returns:
//   String - a name of a type of commands for importing data from a file.
//
Function CommandTypeDataImportFromFile() Export
	
	Return "ImportDataFromFile"; // Internal ID.
	
EndFunction

////////////////////////////////////////////////////////////////////////////////
// Form type names. They are used on assignable object setup.

// List form ID.
//
// Returns:
//   String - an ID of list forms.
//
Function ListFormType() Export
	
	Return "ListForm"; // Internal ID.
	
EndFunction

// Object form ID.
//
// Returns:
//   String - an ID of object forms.
//
Function ObjectFormType() Export
	
	Return "ObjectForm"; // Internal ID.
	
EndFunction

////////////////////////////////////////////////////////////////////////////////
// Other procedures and functions.

// Filter for dialog boxes used to select or save additional reports or data processors.
//
// Returns:
//   String - a filter for dialog boxes used to select or save additional reports or data processors.
//
Function SelectingAndSavingDialogFilter() Export
	
	Filter = NStr("ru = 'Внешние отчеты и обработки (*.%1, *.%2)|*.%1;*.%2|Внешние отчеты (*.%1)|*.%1|Внешние обработки (*.%2)|*.%2'; en = 'External reports and data processors (*.%1, *.%2)|*.%1;*.%2|External reports (*.%1)|*.%1|External data processors (*.%2)|*.%2'; pl = 'Zewnętrzne raporty i opracowania (*.%1,*.%2)| *.%1;*.%2|Zewnętrzne raporty (*.%1) | *.%1| Zewnętrzne opracowania (*.%2) | *.%2';de = 'Externe Berichte und Datenprozessoren (*.%1, %2*.)|*.%1; *. %2| Externe Berichte (*.%1) | *. %1| Externe Datenprozessoren (*. %2) | *. %2';ro = 'Rapoarte externe și procesoare de date (*.%1, *.%2)|*.%1;*.%2|Rapoarte externe (*.%1)|*.%1|Procesoare de date externe (*.%2)|*.%2';tr = 'Dış raporlar ve veri işlemcileri (*.%1, *.) | *%2.; *.%1 Dış raporlar (*%2.) | *%1. Dış veri işlemcileri (*%1.) | *%2.%2'; es_ES = 'Informes externos y procesadores de datos (*.%1,*.%2)|*.%1;*.%2|Informes externos (*.%1)|*.%1|Procesadores de datos externos (*.%2)|*.%2'");
	Filter = StringFunctionsClientServer.SubstituteParametersToString(Filter, "erf", "epf");
	Return Filter;
	
EndFunction

// Name of the section that matches the start page.
//
// Returns:
//   String - a name of the section that matches the start page.
//
Function StartPageName() Export
	
	Return "Desktop"; 
	
EndFunction

#Region ObsoleteProceduresAndFunctions

// Obsolete. Use AdditionalReportsAndDataProcessorsCllientServer.StartPageName instead.
// Name of the section that matches the start page.
//
// Returns:
//   String
//
Function DesktopID() Export
	
	Return "Desktop"; 
	
EndFunction

#EndRegion

#EndRegion

#Region Private

// Defines whether the job schedule is set.
//
// Parameters:
//   Schedule - JobSchedule - a job schedule.
//
// Returns:
//   Boolean - True if the job schedule is set.
//
Function ScheduleSpecified(Schedule) Export
	
	Return Schedule = Undefined
		Or String(Schedule) <> String(New JobSchedule);
	
EndFunction

#EndRegion
