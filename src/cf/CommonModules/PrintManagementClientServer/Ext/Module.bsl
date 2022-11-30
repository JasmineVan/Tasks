///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Public

#Region ObsoleteProceduresAndFunctions

// Obsolete. Use AttachableCommandsClientServer.UpdateCommands.
//
// Updates a list of print commands depending on the current context.
//
// Parameters:
//  Form - ManagedForm - a form that requires an update of print commands.
//  Source - FormDataStructure - FormTable - a context to check conditions (Form.Object or Form.Items.List).
//
Procedure UpdateCommands(Form, Source) Export
	AttachableCommandsClientServer.UpdateCommands(Form, Source);
EndProcedure

#EndRegion

#EndRegion

#Region Private

Function PrintFormsCollectionFieldsNames() Export
	
	Fields = New Array;
	Fields.Add("TemplateName");
	Fields.Add("UpperCaseName");
	Fields.Add("TemplateSynonym");
	Fields.Add("SpreadsheetDocument");
	Fields.Add("Copies");
	Fields.Add("Picture");
	Fields.Add("FullTemplatePath");
	Fields.Add("PrintFormFileName");
	Fields.Add("OfficeDocuments");
	
	Return Fields;
	
EndFunction

#EndRegion
