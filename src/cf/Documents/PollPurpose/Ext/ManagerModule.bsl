///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

#Region ForCallsFromOtherSubsystems

// StandardSubsystems.BatchObjectsModification

// Returns object attributes allowed to be edited using batch attribute change data processor.
// 
//
// Returns:
//  Array - a list of object attribute names.
Function AttributesToEditInBatchProcessing() Export
	
	Result = New Array;
	Result.Add("StartDate");
	Result.Add("EndDate");
	Result.Add("AllowSavingQuestionnaireDraft");
	Result.Add("ShowInQuestionnaireArchive");
	Result.Add("Comment");
	Return Result;
	
EndFunction

// End StandardSubsystems.BatchObjectsModification

// StandardSubsystems.ReportsOptions

// Determines a report command list.
//
// Parameters:
//   ReportsCommands - ValueTable - a table with report commands. For changing.
//       See details of parameter 1 of the   ReportsOptionsOverridable.BeforeAddReportsCommands() procedure.
//   Parameters - Structure - auxiliary parameters. For reading.
//       See details of parameter 2 of the   ReportsOptionsOverridable.BeforeAddReportsCommands() procedure.
//
Procedure AddReportCommands(ReportsCommands, Parameters) Export
	
	If AccessRight("View", Metadata.Reports.PollStatistics) Then
		Command = ReportsCommands.Add();
		Command.Presentation      = NStr("ru = 'Анализ опроса'; en = 'Survey analysis'; pl = 'Survey analysis';de = 'Survey analysis';ro = 'Survey analysis';tr = 'Survey analysis'; es_ES = 'Survey analysis'");
		Command.MultipleChoice = False;
		Command.FormParameterName  = "Survey";
		Command.WriteMode        = "Write";
		Command.Manager           = "Report.PollStatistics";
	EndIf;
	
EndProcedure

// End StandardSubsystems.ReportsOptions

// StandardSubsystems.MessagesTemplates

// It is called when preparing message templates and allows you to override a list of attributes and attachments.
//
// Parameters:
//  Attributes               - ValueTree - a list of template attributes.
//         ** Name            - String - a unique name of a common attribute.
//         ** Presentation  - String - a common attribute presentation.
//         ** Type            - Type - an attribute type. It is a string by default.
//         ** Format         - String - a value output format for numbers, dates, strings, and boolean values.
//  Attachments                - ValueTable - print forms and attachments
//         ** Name            - String - a unique attachment name.
//         ** Presentation  - String - an option presentation.
//         ** FileType       - String - an attachment type that matches the file extension: pdf, png, jpg, mxl,
//                                      and other.
//  AdditionalParameters - Structure - additional information on a message template.
//
Procedure OnPrepareMessageTemplate(Attributes, Attachments, AdditionalParameters) Export
	
EndProcedure

// It is called upon creating messages from template to fill in values of attributes and attachments.
//
// Parameters:
//  Message - Structure - a structure with the following keys:
//    * AttributesValues - Map - a list of attributes used in the template.
//      ** Key     - String - an attribute name in the template.
//      ** Value - String - a filling value in the template.
//    * CommonAttributesValues - Map - a list of common attributes used in the template.
//      ** Key     - String - an attribute name in the template.
//      ** Value - String - a filling value in the template.
//    * Attachments - Map - attribute values
//      ** Key     - String - an attachment name in the template.
//      ** Value - BinaryData, String - binary data or an address in a temporary storage of the attachment.
//  MessageSubject - AnyRef - a reference to an object that is a data source.
//  AdditionalParameters - Structure - additional information on the message template.
//
Procedure OnCreateMessage(Message, MessageSubject, AdditionalParameters) Export
	
EndProcedure

// Fills in a list of text message recipients when sending a message generated from template.
//
// Parameters:
//   SMSMessageRecipients - ValueTable - a list of text message recipients.
//     * PhoneNumber - String - a phone number to send a text message to.
//     * Presentation - String - a text message recipient presentation.
//     * Contact       - Arbitrary - a contact that owns the phone number.
//  MessageSubject - AnyRef, Structure - a reference to an object that is a data source or a 
//                                              structure if the template contains the following arbitrary parameters:
//    * Subject               - AnyRef - a reference to an object that is a data source
//    * ArbitraryParameters - Map - a filled list of arbitrary parameters.
//
Procedure OnFillRecipientsPhonesInMessage(SMSMessageRecipients, MessageSubject) Export
	
EndProcedure

// Fills in the email recipients list when sending a message generated from template.
//
// Parameters:
//   MailRecipients - ValueTable - a list of mail recipients.
//     * Address           - String - a recipient email address.
//     * Presentation   - String - a mail recipient presentation.
//     * Contact         - Arbitrary - a contact that owns the email address.
//  MessageSubject - AnyRef, Structure - a reference to an object that is a data source or a 
//                                              structure if the template contains the following arbitrary parameters:
//    * Subject               - AnyRef - a reference to an object that is a data source
//    * ArbitraryParameters - Map - a filled list of arbitrary parameters.
//
Procedure OnFillRecipientsEmailsInMessage(EmailRecipients, MessageSubject) Export
	
EndProcedure

// End StandardSubsystems.MessagesTemplates

#EndRegion

#EndRegion

#EndIf

