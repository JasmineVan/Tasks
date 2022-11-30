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
//  Contact - CatalogRef, Undefined - a contact, for which the record is being deleted.
//             If the Undefined value is specified, the register will be cleared.
//
Procedure DeleteRecordFromRegister(Contact = Undefined) Export
	
	SetPrivilegedMode(True);
	
	RecordSet = CreateRecordSet();
	If Contact <> Undefined Then
		RecordSet.Filter.Contact.Set(Contact);
	EndIf;
	
	RecordSet.Write();
	
EndProcedure

// Writes to the information register for the specified subject.
//
// Parameters:
//  Contact - CatalogRef - a contact to be recorded.
//  NotReviewedInteractionsCount       - Number - a number of unreviewed interactions for the contact.
//  LastInteractionDate - DateTime - a date of last interaction on the contact.
//
Procedure ExecuteRecordToRegister(Contact,
	                              NotReviewedInteractionsCount = Undefined,
	                              LastInteractionDate = Undefined) Export
	
	SetPrivilegedMode(True);
	
	If NotReviewedInteractionsCount = Undefined AND LastInteractionDate = Undefined Then
		
		Return;
		
	ElsIf NotReviewedInteractionsCount = Undefined OR LastInteractionDate = Undefined Then
		
		Query = New Query;
		Query.Text = "
		|SELECT
		|	InteractionsContactStates.Contact,
		|	InteractionsContactStates.NotReviewedInteractionsCount,
		|	InteractionsContactStates.LastInteractionDate
		|FROM
		|	InformationRegister.InteractionsContactStates AS InteractionsContactStates
		|WHERE
		|	InteractionsContactStates.Contact = &Contact";
		
		Query.SetParameter("Contact",Contact);
		
		Result = Query.Execute();
		If NOT Result.IsEmpty() Then
			
			Selection = Result.Select();
			Selection.Next();
			
			If NotReviewedInteractionsCount = Undefined Then
				NotReviewedInteractionsCount = Selection.NotReviewedInteractionsCount;
			EndIf;
			
			If LastInteractionDate = Undefined Then
				LastInteractionDate = LastInteractionDate.Topic;
			EndIf;
			
		EndIf;
	EndIf;

	RecordSet = CreateRecordSet();
	RecordSet.Filter.Contact.Set(Contact);
	
	Record = RecordSet.Add();
	Record.Contact                      = Contact;
	Record.NotReviewedInteractionsCount      = NotReviewedInteractionsCount;
	Record.LastInteractionDate = LastInteractionDate;
	RecordSet.Write();

EndProcedure

#Region UpdateHandlers

// Infobase update procedure for SSL 2.2.
// Performs initial calculations of interaction contact states.
//
Procedure CalculateInteractionContactStatuses_2_2_0_0(Parameters) Export
	
	Query = New Query;
	Query.Text = "
	|SELECT DISTINCT TOP 1000
	|	InteractionsContacts.Contact
	|INTO ContactsForSettlement
	|FROM
	|	InformationRegister.InteractionsContacts AS InteractionsContacts
	|		LEFT JOIN InformationRegister.InteractionsContactStates AS InteractionsContactStates
	|		ON InteractionsContacts.Contact = InteractionsContactStates.Contact
	|WHERE
	|	InteractionsContactStates.Contact IS NULL 
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	InteractionsContacts.Contact,
	|	MAX(Interactions.Date) AS LastInteractionDate,
	|	SUM(CASE
	|			WHEN InteractionsFolderSubjects.Reviewed
	|				THEN 0
	|			ELSE 1
	|		END) AS NotReviewedInteractionsCount
	|FROM
	|	ContactsForSettlement AS ContactsForSettlement
	|		INNER JOIN InformationRegister.InteractionsContacts AS InteractionsContacts
	|			INNER JOIN DocumentJournal.Interactions AS Interactions
	|			ON InteractionsContacts.Interaction = Interactions.Ref
	|			INNER JOIN InformationRegister.InteractionsFolderSubjects AS InteractionsFolderSubjects
	|			ON InteractionsContacts.Interaction = InteractionsFolderSubjects.Interaction
	|		ON ContactsForSettlement.Contact = InteractionsContacts.Contact
	|
	|GROUP BY
	|	InteractionsContacts.Contact";
	
	Result = Query.Execute();
	If Result.IsEmpty() Then
		Return;
	EndIf;
	
	Selection = Result.Select();
	While Selection.Next() Do
		
		ExecuteRecordToRegister(Selection.Contact, Selection.NotReviewedInteractionsCount, Selection.LastInteractionDate);
		
	EndDo;
	
	Parameters.ProcessingCompleted = (Selection.Count() = 0);
	
EndProcedure

#EndRegion

#EndRegion

#EndIf