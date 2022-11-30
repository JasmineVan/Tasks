///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Public

////////////////////////////////////////////////////////////////////////////////
// Operations with office document templates.

// Gets all data required for printing within a single call: object template data, binary template 
// data, and template area description.
// Used for calling print forms based on office document templates from client modules.
//
// Parameters:
//   PrintManagerName - String - a name for accessing the object manager, for example, Document.<Document name>.
//   TemplatesNames - String - names of templates used for print form generation.
//   DocumentsContent - Array - references to infobase objects (all references must be of the same type).
//
// Returns:
//  Map - a collection of references to objects and their data:
//   * Key - AnyRef - reference to an infobase object.
//   * Value - Structure - a template and data:
//       ** Key - String - a template name.
//       ** Value - Structure - object data.
//
Function TemplatesAndObjectsDataToPrint(Val PrintManagerName, Val TemplatesNames, Val DocumentsComposition) Export
	
	Return PrintManagement.TemplatesAndObjectsDataToPrint(PrintManagerName, TemplatesNames, DocumentsComposition);
	
EndFunction

#EndRegion

#Region Private

// Generates print forms for direct output to a printer.
//
// Detailed - for details, see PrintManager.GeneratePrintFormsForQuickPrint().
//
Function GeneratePrintFormsForQuickPrint(PrintManagerName, TemplatesNames, ObjectsArray,	PrintParameters) Export
	
	Return PrintManagement.GeneratePrintFormsForQuickPrint(PrintManagerName, TemplatesNames,
		ObjectsArray,	PrintParameters);
	
EndFunction

// Generates print forms for direct output to a printer in an ordinary application.
//
// Detailed - for details, see PrintManager.GeneratePrintFormsForQuickPrintOrdinaryApplication().
//
Function GeneratePrintFormsForQuickPrintOrdinaryApplication(PrintManagerName, TemplatesNames, ObjectsArray, PrintParameters) Export
	
	Return PrintManagement.GeneratePrintFormsForQuickPrintOrdinaryApplication(PrintManagerName, TemplatesNames,
		ObjectsArray,	PrintParameters);
	
EndFunction

// Returns True if the user is authorized to post at least one document.
Function HasRightToPost(DocumentsList) Export
	Return StandardSubsystemsServer.HasRightToPost(DocumentsList);
EndFunction

// See. PrintManager.DocumentsPackage. 
Function DocumentsPackage(SpreadsheetDocuments, PrintObjects, PrintInSets, CopiesCount = 1) Export
	
	Return PrintManagement.DocumentsPackage(SpreadsheetDocuments, PrintObjects,
		PrintInSets, CopiesCount);
	
EndFunction

#EndRegion
