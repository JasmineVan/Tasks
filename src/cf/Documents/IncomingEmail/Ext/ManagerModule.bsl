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
	Result.Add("Importance");
	Result.Add("EmployeeResponsible");
	Result.Add("InteractionBasis");
	Result.Add("Comment");
	Result.Add("SenderContact");
	Result.Add("SenderPresentation");
	Result.Add("EmailRecipients.Presentation");
	Result.Add("EmailRecipients.Contact");
	Result.Add("CCRecipients.Presentation");
	Result.Add("CCRecipients.Contact");
	Result.Add("ReplyRecipients.Presentation");
	Result.Add("ReplyRecipients.Contact");
	Result.Add("ReadReceiptAddresses.Presentation");
	Result.Add("ReadReceiptAddresses.Contact");
	Return Result;
	
EndFunction

// End StandardSubsystems.BatchObjectsModification

// StandardSubsystems.Interactions

// Receives a sender and addressees of an email.
//
// Parameters:
//  Ref - DocumentRef.IncomingEmail - a document whose subscriber is to be received.
//
// Returns:
//   ValueTable - a table that contains the Contact, Presentation, and Address columns.
//
Function GetContacts(Ref) Export

	QueryText = 
		"SELECT
		|	IncomingEmail.Account.EmailAddress AS AccountEmailAddress
		|INTO OurAddress
		|FROM
		|	Document.IncomingEmail AS IncomingEmail
		|WHERE
		|	IncomingEmail.Ref = &Ref
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	IncomingEmail.SenderAddress AS Address,
		|	SUBSTRING(IncomingEmail.SenderPresentation, 1, 1000) AS Presentation,
		|	IncomingEmail.SenderContact AS Contact
		|INTO AllContacts
		|FROM
		|	Document.IncomingEmail AS IncomingEmail
		|WHERE
		|	IncomingEmail.Ref = &Ref
		|
		|UNION
		|
		|SELECT
		|	EmailMessageIncomingMessageRecipients.Address,
		|	EmailMessageIncomingMessageRecipients.Presentation,
		|	EmailMessageIncomingMessageRecipients.Contact
		|FROM
		|	Document.IncomingEmail.EmailRecipients AS EmailMessageIncomingMessageRecipients
		|WHERE
		|	EmailMessageIncomingMessageRecipients.Ref = &Ref
		|
		|UNION
		|
		|SELECT
		|	EmailMessageIncomingCCRecipients.Address,
		|	EmailMessageIncomingCCRecipients.Presentation,
		|	EmailMessageIncomingCCRecipients.Contact
		|FROM
		|	Document.IncomingEmail.CCRecipients AS EmailMessageIncomingCCRecipients
		|WHERE
		|	EmailMessageIncomingCCRecipients.Ref = &Ref
		|
		|UNION
		|
		|SELECT
		|	EmailMessageIncomingResponseRecipients.Address,
		|	EmailMessageIncomingResponseRecipients.Presentation,
		|	EmailMessageIncomingResponseRecipients.Contact
		|FROM
		|	Document.IncomingEmail.ReplyRecipients AS EmailMessageIncomingResponseRecipients
		|WHERE
		|	EmailMessageIncomingResponseRecipients.Ref = &Ref
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	AllContacts.Address AS Address,
		|	MAX(AllContacts.Presentation) AS Presentation,
		|	MAX(AllContacts.Contact) AS Contact
		|FROM
		|	AllContacts AS AllContacts
		|		LEFT JOIN OurAddress AS OurAddress
		|		ON AllContacts.Address = OurAddress.AccountEmailAddress
		|WHERE
		|	OurAddress.AccountEmailAddress IS NULL
		|
		|GROUP BY
		|	AllContacts.Address";

	Query = New Query;
	Query.Text = QueryText;
	Query.SetParameter("Ref", Ref);
	ContactsTable = Query.Execute().Unload();

	Return Interactions.ConvertContactsTableToArray(ContactsTable);
	
EndFunction

// End StandardSubsystems.Interactions

// StandardSubsystems.AccessManagement

// See AccessManagementOverridable.OnFillListsWithAccessRestriction. 
Procedure OnFillAccessRestriction(Restriction) Export
	
	Restriction.Text =
	"AllowReadUpdate
	|WHERE
	|	ValueAllowed(EmployeeResponsible, Disabled AS False)
	|	OR ValueAllowed(Account, Disabled AS False)";
	
EndProcedure

// End StandardSubsystems.AccessManagement

#EndRegion

#EndRegion

#Region EventHandlers

Procedure ChoiceDataGetProcessing(ChoiceData, Parameters, StandardProcessing)
	
	InteractionsEvents.ChoiceDataGetProcessing(Metadata.Documents.IncomingEmail.Name,
		ChoiceData, Parameters, StandardProcessing);
	
EndProcedure

#EndRegion

#Region Private

#Region UpdateHandlers

// Registers for processing emails whose InteractionBase can be filled in.
//
Procedure FillBasisInteractionsForDependentEmailsToProcess(Parameters) Export

	Query = New Query;
	Query.Text = Interactions.QueryTextOfMarkToProcessingOfBaseEmailsFilling("Document.IncomingEmail");
	
	InfobaseUpdate.MarkForProcessing(
		Parameters,
		Query.Execute().Unload().UnloadColumn("Ref"));

EndProcedure 

// Completes filling of the InteractionBase email attribute.
//
Procedure FillBasisInteractionsForDependentEmails(Parameters) Export
	
	FullDocumentName = "Document.IncomingEmail";
	DocumentMetadata = Metadata.Documents.IncomingEmail;
	
	Interactions.FillBasisInteractionsForDependentEmails(Parameters, FullDocumentName, DocumentMetadata);
	
EndProcedure

#EndRegion

#EndRegion

#EndIf



