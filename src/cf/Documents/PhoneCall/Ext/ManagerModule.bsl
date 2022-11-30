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
	Result.Add("Author");
	Result.Add("Importance");
	Result.Add("EmployeeResponsible");
	Result.Add("InteractionBasis");
	Result.Add("Incoming");
	Result.Add("Comment");
	Result.Add("SubscriberContact");
	Result.Add("SubscriberPresentation");
	Result.Add("HowToContactSubscriber");
	Return Result;
	
EndFunction

// End StandardSubsystems.BatchObjectsModification

// StandardSubsystems.Interactions

// Gets a phone call subscriber.
//
// Parameters:
//  Ref - DocumentRef.PhoneCall - a document whose subscriber is to be received.
//
// Returns:
//   ValueTable - a table that contains the Contact, Presentation, and Address columns.
//
Function GetContacts(Ref) Export
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	PhoneCall.SubscriberContact AS Contact,
	|	PhoneCall.HowToContactSubscriber AS Address,
	|	PhoneCall.SubscriberPresentation AS Presentation
	|FROM
	|	Document.PhoneCall AS PhoneCall
	|WHERE
	|	PhoneCall.Ref = &Ref";
	
	Query.SetParameter("Ref", Ref);
	Selection = Query.Execute().Select();
	
	If Selection.Next() Then
		Return Interactions.GetParticipantByFields(Selection.Contact, Selection.Address, Selection.Presentation);
	Else
		Return Undefined;
	EndIf;
	
EndFunction

// End StandardSubsystems.Interactions

// StandardSubsystems.AccessManagement

// See AccessManagementOverridable.OnFillListsWithAccessRestriction. 
Procedure OnFillAccessRestriction(Restriction) Export
	
	Restriction.Text =
	"AllowReadUpdate
	|WHERE
	|	ValueAllowed(EmployeeResponsible, Disabled AS False)
	|	OR ValueAllowed(Author, Disabled AS False)";
	
EndProcedure

// End StandardSubsystems.AccessManagement

#EndRegion

#EndRegion

#Region EventHandlers

Procedure ChoiceDataGetProcessing(ChoiceData, Parameters, StandardProcessing)
	
	InteractionsEvents.ChoiceDataGetProcessing(Metadata.Documents.PhoneCall.Name,
		ChoiceData, Parameters, StandardProcessing);
	
EndProcedure

#EndRegion

#EndIf