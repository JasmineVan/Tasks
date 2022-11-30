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

// StandardSubsystems.Interactions

// The procedure generates participant list rows.
//
// Parameters:
//  Contacts - Array - an array containing interaction participants.
//
Procedure FillContacts(Contacts) Export
	
	Interactions.FillContactsForMeeting(Contacts, Members);
	
EndProcedure

// End StandardSubsystems.Interactions

// StandardSubsystems.AccessManagement

// See AccessManagement.FillAccessValuesSets. 
Procedure FillAccessValuesSets(Table) Export
	
	InteractionsEvents.FillAccessValuesSets(ThisObject, Table);
	
EndProcedure

// End StandardSubsystems.AccessManagement

#EndRegion

#EndRegion

#Region EventHandlers

Procedure Filling(FillingData, FillingText, StandardProcessing)

	SetDefaultDates();
	Interactions.FillDefaultAttributes(ThisObject, FillingData);

EndProcedure

Procedure BeforeWrite(Cancel, WriteMode, PostingMode)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	Interactions.GenerateParticipantsList(ThisObject);
	
EndProcedure

Procedure OnCopy(CopiedObject)
	
	SetDefaultDates();
	EmployeeResponsible    = Users.CurrentUser();
	Author            = Users.CurrentUser();
	
EndProcedure

Procedure FillCheckProcessing(Cancel, CheckedAttributes)

	If EndDate < StartDate Then

		Common.MessageToUser(
			NStr("ru='Дата окончания не может быть меньше даты начала.'; en = 'The end date cannot be earlier than the start date.'; pl = 'The end date cannot be earlier than the start date.';de = 'The end date cannot be earlier than the start date.';ro = 'The end date cannot be earlier than the start date.';tr = 'The end date cannot be earlier than the start date.'; es_ES = 'The end date cannot be earlier than the start date.'"),
			,
			"EndDate",
			,
			Cancel);

	EndIf;

EndProcedure

Procedure OnWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	Interactions.OnWriteDocument(ThisObject);
	
EndProcedure

#EndRegion

#Region Private

Procedure SetDefaultDates()

	StartDate = CurrentSessionDate();
	StartDate = BegOfHour(StartDate) + ?(Minute(StartDate) < 30, 1800, 3600);
	EndDate = StartDate + 1800;

EndProcedure

#EndRegion

#Else
Raise NStr("ru = 'Недопустимый вызов объекта на клиенте.'; en = 'Invalid object call on the client.'; pl = 'Invalid object call on the client.';de = 'Invalid object call on the client.';ro = 'Invalid object call on the client.';tr = 'Invalid object call on the client.'; es_ES = 'Invalid object call on the client.'");
#EndIf