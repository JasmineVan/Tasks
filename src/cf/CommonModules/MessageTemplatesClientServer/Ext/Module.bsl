///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Public

// Describes a template parameter for their use in external data processors.
//
// Parameters:
//  ParametersTable           - ValueTable - a table with parameters.
//  ParameterName                - String - a name of the used parameter.
//  TypeDetails                - TypesDetails - a parameter type.
//  IsPredefinedParameter - Boolean - if False, this is an arbitrary parameter, otherwise, a main parameter.
//  ParameterPresentation      - String - a parameter presentation to be displayed.
//
Procedure AddTemplateParameter(ParametersTable, ParameterName, TypeDetails, IsPredefinedParameter, ParameterPresentation = "") Export

	NewRow                             = ParametersTable.Add();
	NewRow.ParameterName                = ParameterName;
	NewRow.TypeDetails                = TypeDetails;
	NewRow.IsPredefinedParameter = IsPredefinedParameter;
	NewRow.ParameterPresentation      = ?(IsBlankString(ParameterPresentation),ParameterName, ParameterPresentation);
	
EndProcedure

// Initializes the message structure that has to be returned by the external data processor from the template.
//
// Returns:
//   Structure - a created structure.
//
Function InitializeMessageStructure() Export
	
	MessageStructure = New Structure;
	MessageStructure.Insert("SMSMessageText", "");
	MessageStructure.Insert("EmailSubject", "");
	MessageStructure.Insert("EmailText", "");
	MessageStructure.Insert("AttachmentsStructure", New Structure);
	MessageStructure.Insert("HTMLEmailText", "<HTML></HTML>");
	
	Return MessageStructure;
	
EndFunction

// Initializes the Recipients structure to fill in possible message recipients.
//
// Returns:
//   Structure - a created structure.
//
Function InitializeRecipientsStructure() Export
	
	Return New Structure("Recipient", New Array);
	
EndFunction

// Template parameter constructor.
// 
// Returns:
//  Structure - a list of template parameters.
//
Function TemplateParametersDetails() Export
	Result = New Structure;
	
	Result.Insert("Text", "");
	Result.Insert("Subject", "");
	Result.Insert("TemplateType", "Email");
	Result.Insert("Purpose", "");
	Result.Insert("FullAssignmentTypeName", "");
	Result.Insert("EmailFormat", PredefinedValue("Enum.EmailEditingMethods.HTML"));
	Result.Insert("PackToArchive", False);
	Result.Insert("TransliterateFileNames", False);
	Result.Insert("Transliterate", False);
	Result.Insert("From", "");
	Result.Insert("ExternalDataProcessor", Undefined);
	Result.Insert("TemplateByExternalDataProcessor", False);
	Result.Insert("ExpandRefAttributes", True);
	Result.Insert("AttachmentsFormats", New ValueList);
	Result.Insert("SelectedAttachments", New Map);
	Result.Insert("Template", "");
	Result.Insert("Parameters", New Map);
	Result.Insert("DCSParameters", New Map);
	Result.Insert("TemplateOwner", Undefined);
	Result.Insert("Ref", Undefined);
	Result.Insert("Description", "");
	Result.Insert("MessageParameters", New Structure);
	Result.Insert("SignatureAndSeal", False);
	
	Return Result;
	
EndFunction

#EndRegion

#Region Private

Function SendOptionsConstructor(Template, Topic, UUID) Export
	
	SendOptions = New Structure();
	SendOptions.Insert("Template", Template);
	SendOptions.Insert("Topic", Topic);
	SendOptions.Insert("UUID", UUID);
	SendOptions.Insert("AdditionalParameters", New Structure);
	SendOptions.AdditionalParameters.Insert("ConvertHTMLForFormattedDocument", False);
	SendOptions.AdditionalParameters.Insert("MessageKind", "");
	SendOptions.AdditionalParameters.Insert("ArbitraryParameters", New Map);
	SendOptions.AdditionalParameters.Insert("SendImmediately", False);
	SendOptions.AdditionalParameters.Insert("MessageParameters", New Structure);
	SendOptions.AdditionalParameters.Insert("Account", Undefined);
	
	Return SendOptions;
	
EndFunction

Function ArbitraryParametersTitle() Export
	Return NStr("ru = 'Произвольные'; en = 'Arbitrary'; pl = 'Arbitrary';de = 'Arbitrary';ro = 'Arbitrary';tr = 'Arbitrary'; es_ES = 'Arbitrary'");
EndFunction

#EndRegion
