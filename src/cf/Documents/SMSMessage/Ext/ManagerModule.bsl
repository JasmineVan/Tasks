﻿///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

#Region ForCallsFromOtherSubsystems

// StandardSubsystems.Interactions

// Gets an array of structures and the SMS Message document addressees.
//
// Parameters:
//  Ref - Document.SMSMessage - a document, for which an array of contacts is being received.
//
// Returns:
//   Array   - SMS message addressees.
//
Function GetContacts(Ref) Export
	
	Return Interactions.GetParticipantsByTable(Ref);
	
EndFunction

// End StandardSubsystems.Interactions

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
	Result.Add("Comment");
	Result.Add("Recipients.Contact");
	Result.Add("Recipients.ContactPresentation");
	Result.Add("Recipients.HowToContact");
	Return Result;
	
EndFunction

// End StandardSubsystems.BatchObjectsModification

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
	
	InteractionsEvents.ChoiceDataGetProcessing(Metadata.Documents.SMSMessage.Name,
		ChoiceData, Parameters, StandardProcessing);
	
EndProcedure

#EndRegion

#EndIf