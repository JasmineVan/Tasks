///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Private

// Deletes one record or all records from the register.
//
// Parameters:
//  Interaction  - DocumentRef - an interaction document ref, undefined - an interaction whose 
//                                     record is deleted.
//                                     If the Undefined value is specified, the register will be cleared.
//
Procedure DeleteRecordSetOnInteraction(Interaction = Undefined) Export
	
	SetPrivilegedMode(True);
	
	RecordSet = CreateRecordSet();
	If Interaction <> Undefined Then
		RecordSet.Filter.Interaction.Set(Interaction);
	EndIf;
	
	RecordSet.Write();
	
EndProcedure

// Writes to the information register for the specified interaction.
//
// Parameters:
//  Interaction - DocumentRef - an interaction to be recorded.
//  Contact         - CatalogRef - a reference to a contact catalog that is an interaction participant.
//
Procedure ExecuteRecordToRegister(Interaction, Contact) Export

	SetPrivilegedMode(True);
	
	Record = CreateRecordManager();
	Record.Interaction = Interaction;
	Record.Contact        = Contact;
	Record.Write(True);

EndProcedure

#Region UpdateHandlers

// Infobase update procedure for SSL 2.2.
// Fills in the InteractionContacts information register.
//
// Parameters:
//  Parameter - Structure - execution parameters of the current update handler batch.
//
Procedure FillInteractionsContacts_2_2_0_0(Parameters) Export
	
	Query = New Query;
	Query.Text = "
	|SELECT TOP 1000
	|	Interactions.Ref AS Ref
	|INTO UnprocessedInteractions
	|FROM
	|	DocumentJournal.Interactions AS Interactions
	|		LEFT JOIN InformationRegister.InteractionsContacts AS InteractionsContacts
	|		ON Interactions.Ref = InteractionsContacts.Interaction
	|WHERE
	|	InteractionsContacts.Interaction IS NULL 
	|
	|INDEX BY
	|	Ref
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	MeetingParticipants.Ref AS Interaction,
	|	MeetingParticipants.Contact,
	|	MeetingParticipants.ContactPresentation AS ContactPresentation
	|INTO ContactsInformation
	|FROM
	|	Document.Meeting.Members AS MeetingParticipants
	|WHERE
	|	MeetingParticipants.Ref IN
	|			(SELECT
	|				UnprocessedInteractions.Ref
	|			FROM
	|				UnprocessedInteractions AS UnprocessedInteractions)
	|
	|UNION
	|
	|SELECT DISTINCT
	|	PlannedInteractionParticipants.Ref,
	|	PlannedInteractionParticipants.Contact,
	|	PlannedInteractionParticipants.ContactPresentation
	|FROM
	|	Document.PlannedInteraction.Members AS PlannedInteractionParticipants
	|WHERE
	|	PlannedInteractionParticipants.Ref IN
	|			(SELECT
	|				UnprocessedInteractions.Ref
	|			FROM
	|				UnprocessedInteractions AS UnprocessedInteractions)
	|
	|UNION
	|
	|SELECT DISTINCT
	|	PhoneCall.Ref,
	|	PhoneCall.SubscriberContact,
	|	PhoneCall.SubscriberPresentation
	|FROM
	|	Document.PhoneCall AS PhoneCall
	|WHERE
	|	PhoneCall.Ref IN
	|			(SELECT
	|				UnprocessedInteractions.Ref
	|			FROM
	|				UnprocessedInteractions AS UnprocessedInteractions)
	|
	|UNION
	|
	|SELECT DISTINCT
	|	SMSMessageRecipients.Ref,
	|	SMSMessageRecipients.Contact,
	|	SMSMessageRecipients.ContactPresentation
	|FROM
	|	Document.SMSMessage.Recipients AS SMSMessageRecipients
	|WHERE
	|	SMSMessageRecipients.Ref IN
	|			(SELECT
	|				UnprocessedInteractions.Ref
	|			FROM
	|				UnprocessedInteractions AS UnprocessedInteractions)
	|
	|UNION
	|
	|SELECT DISTINCT
	|	IncomingEmail.Ref,
	|	IncomingEmail.SenderContact,
	|	IncomingEmail.SenderPresentation
	|FROM
	|	Document.IncomingEmail AS IncomingEmail
	|WHERE
	|	IncomingEmail.Ref IN
	|			(SELECT
	|				UnprocessedInteractions.Ref
	|			FROM
	|				UnprocessedInteractions AS UnprocessedInteractions)
	|
	|UNION
	|
	|SELECT DISTINCT
	|	EmailMessageOutgoingMessageRecipients.Ref,
	|	EmailMessageOutgoingMessageRecipients.Contact,
	|	EmailMessageOutgoingMessageRecipients.Presentation
	|FROM
	|	Document.OutgoingEmail.EmailRecipients AS EmailMessageOutgoingMessageRecipients
	|WHERE
	|	EmailMessageOutgoingMessageRecipients.Ref IN
	|			(SELECT
	|				UnprocessedInteractions.Ref
	|			FROM
	|				UnprocessedInteractions AS UnprocessedInteractions)
	|
	|UNION
	|
	|SELECT DISTINCT
	|	EmailMessageOutgoingCCRecipients.Ref,
	|	EmailMessageOutgoingCCRecipients.Contact,
	|	EmailMessageOutgoingCCRecipients.Presentation
	|FROM
	|	Document.OutgoingEmail.CCRecipients AS EmailMessageOutgoingCCRecipients
	|WHERE
	|	EmailMessageOutgoingCCRecipients.Ref IN
	|			(SELECT
	|				UnprocessedInteractions.Ref
	|			FROM
	|				UnprocessedInteractions AS UnprocessedInteractions)
	|
	|UNION
	|
	|SELECT DISTINCT
	|	EmailMessageOutgoingBCCRecipients.Ref,
	|	EmailMessageOutgoingBCCRecipients.Contact,
	|	EmailMessageOutgoingBCCRecipients.Presentation
	|FROM
	|	Document.OutgoingEmail.BccRecipients AS EmailMessageOutgoingBCCRecipients
	|WHERE
	|	EmailMessageOutgoingBCCRecipients.Ref IN
	|			(SELECT
	|				UnprocessedInteractions.Ref
	|			FROM
	|				UnprocessedInteractions AS UnprocessedInteractions)
	|
	|INDEX BY
	|	ContactPresentation
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	ContactsInformation.Interaction AS Interaction,
	|	CASE
	|		WHEN ContactsInformation.Contact = UNDEFINED
	|			THEN ISNULL(StringContactInteractions.Ref, UNDEFINED)
	|		ELSE ContactsInformation.Contact
	|	END AS Contact,
	|	ContactsInformation.ContactPresentation
	|FROM
	|	ContactsInformation AS ContactsInformation
	|		LEFT JOIN Catalog.StringContactInteractions AS StringContactInteractions
	|		ON ContactsInformation.ContactPresentation = StringContactInteractions.Description
	|TOTALS BY
	|	Interaction";
	
	QueryResult = Query.Execute();
	If QueryResult.IsEmpty() Then
		Return;
	EndIf;
	
	CreatedStringContacts = New Map;
	
	SelectionInteraction = Query.Execute().Select(QueryResultIteration.ByGroups);
	While SelectionInteraction.Next() Do
		
		DetailsSelection = SelectionInteraction.Select();
		
		RecordSet = CreateRecordSet();
		RecordSet.Filter.Interaction.Set(SelectionInteraction.Interaction);
		
		While DetailsSelection.Next() Do
			
			NewRecord = RecordSet.Add();
			NewRecord.Interaction = SelectionInteraction.Interaction;
			If DetailsSelection.Contact <> Undefined Then
				NewRecord.Contact = DetailsSelection.Contact;
			Else
				
				ExistingStringContact = CreatedStringContacts.Get(DetailsSelection.ContactPresentation);
				
				If ExistingStringContact = Undefined Then
					StringInteractionsContact              = Catalogs.StringContactInteractions.CreateItem();
					StringInteractionsContact.Description = DetailsSelection.ContactPresentation;
					StringInteractionsContact.Write();
					CreatedStringContacts.Insert(DetailsSelection.ContactPresentation, StringInteractionsContact.Ref);
					NewRecord.Contact                         = StringInteractionsContact.Ref;
				Else
					NewRecord.Contact                         = ExistingStringContact;
				EndIf;
			EndIf;
			
		EndDo;
		
		InfobaseUpdate.WriteData(RecordSet);
		
	EndDo;
	
	Parameters.ProcessingCompleted = (SelectionInteraction.Count() = 0);

EndProcedure

#EndRegion

#EndRegion

#EndIf