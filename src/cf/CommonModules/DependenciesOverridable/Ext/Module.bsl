///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Public

// It is called to get subsystem settings.
//
// Parameters:
//  Settings - Structure - with the following properties:
//   * Attributes - Map - to override the names of object attribute names that contain information 
//                                about the amount and currency displayed in the list of related documents.
//                                The key contains a full name of the metadata object. The value 
//                                contains a mapping between the Currency and DocumentAmount attributes and actual object attributes.
//                                If not specified, the values are read from the Currency and DocumentAmount attributes.
//   * AttributesForPresentation - Map - to override the presentation of objects displayed in the 
//                                list of related documents. The key contains a full name of the 
//                                metadata object. The value contains an array of names of attributes whose values are used in presentation.
//                                To generate a presentation of the objects listed here, procedure 
//                                DependenciesOverridable.OnGettingPresentationis called.
//
// Example:
//	Attributes = New Map;
//	Attributes.Insert("DocumentAmount", Metadata.Documents.CustomerInvoice.Attributes.PaymentTotal.Name);
//	Attributes.Insert("Currency", Metadata.Documents.CustomerInvoice.Attributes.DocumentCurrency.Name);
//	Settings.Attributes.Insert(Metadata.Documents.CustomerInvoice.FullName(), Attributes);
//		
//	AttributesForPresentation = New Array;
//	AttributesForPresentation.Add(Metadata.Documents.OutgoingEmail.Attributes.SentDate.Name);
//	AttributesForPresentation.Add(Metadata.Documents.OutgoingEmail.Attributes.MailSubject.Name);
//	AttributesForPresentation.Add(Metadata.Documents.OutgoingEmail.Attributes.EmailRecipientsList.Name);
//	Settings.AttributesForPresentation.Insert(Metadata.Documents.OutgoingEmail.FullName(),
//		AttributesForPresentation);
//
Procedure OnDefineSettings(Settings) Export
	
	
	
EndProcedure

// It is called to get a presentation of the objects displayed in the list of related documents.
// Only for objects listed in the AttributesForPresentation property of the Settings parameter of 
// the DependenciesOverridable.OnDefineSettings procedure.
//
// Parameters:
//  DataType - AnyRef - a reference type of the output object. See the RelatedDocuments filter criteria type property.
//  Data - QueryResultSelection, Structure - contains the values of the fields from which the presentation is being generated:
//               * Reference - AnyRef - a reference of the object being output in the list of related documents.
//               * AdditionalAttribute1 - Arbitrary - value of the first attribute specified in array
//                 AttributesForPresentation of the Settings parameter in the OnDefineSettings procedure.
//               * AdditionalAttribute2 - Arbitrary - value of the second attribute...
//               ...
//  Presentation - Row - return the calculated object presentation to this parameter.
//  StandardProcessing - Boolean - if the Presentation parameter value is set, return False to this parameter.
//
Procedure OnGettingPresentation(DataType, Data, Presentation, StandardProcessing) Export
	
	
	
EndProcedure	
	
#Region ObsoleteProceduresAndFunctions

// Obsolete. Use DependenciesOverridable.OnDefineSettings.
// See AttributesForPresentation property of the Settings parameter.
// Generates an array of document attributes.
// 
// Parameters:
//  DocumentName - String - a document name.
//
// Returns:
//   Array - an array of document attribute descriptions.
//
Function ObjectAttributesArrayForPresentationGeneration(DocumentName) Export
	
	Return New Array;
	
EndFunction

// Obsolete. Use DependenciesOverridable.OnGettingPresentation.
// Gets document presentation for printing.
//
// Parameters:
//  Selection  - DataCollection - a structure or a query result selection containing additional 
//                 attributes which you can use to generate an overridden document presentation for 
//                 the Hierarchy report.
//                 
//
// Returns:
//   Row,Undefined   - an overridden document presentation or Undefined, if it is not specified for 
//                           this document type.
//
Function ObjectPresentationForReportOutput(Selection) Export
	
	Return Undefined;
	
EndFunction

// Obsolete. Use DependenciesOverridable.OnDefineSettings.
// See the Attributes property of the Settings parameter.
// Returns the name of the document attribute that contains information about Amount and Currency of 
// the document for output to the hierarchy.
// The default attributes are Currency and DocumentAmount. If other attributes are used for a 
// particular document or configuration, you can change default values using this function.
// 
//
// Parameters:
//  DocumentName - String - name of the document whose attribute name is required.
//  Attribute     - String - a string, possible values are Currency and DocumentAmount.
//
// Returns:
//   String   - a name of an attribute of the document that contains information about Currency or Amount.
//
Function DocumentAttributeName(DocumentName, Attribute) Export
	
	Return Undefined;
	
EndFunction

#EndRegion

#EndRegion
