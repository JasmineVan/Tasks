///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	If NOT UsedByAddressingObjects AND NOT UsedWithoutAddressingObjects Then
		Common.MessageToUser(
			NStr("ru = 'Не указаны допустимые способы назначения исполнителей на роль: совместно с объектами адресации, без них или обоими способами.'; en = 'The allowed methods for adding assignees to roles are not specified (together with the addressing objects, without them, or both ways).'; pl = 'The allowed methods for adding assignees to roles are not specified (together with the addressing objects, without them, or both ways).';de = 'The allowed methods for adding assignees to roles are not specified (together with the addressing objects, without them, or both ways).';ro = 'The allowed methods for adding assignees to roles are not specified (together with the addressing objects, without them, or both ways).';tr = 'The allowed methods for adding assignees to roles are not specified (together with the addressing objects, without them, or both ways).'; es_ES = 'The allowed methods for adding assignees to roles are not specified (together with the addressing objects, without them, or both ways).'"),
		 	ThisObject, "UsedWithoutAddressingObjects",,Cancel);
		Return;
	EndIf;
	
	If NOT UsedByAddressingObjects Then
		Return;
	EndIf;
	
	MainAddressingObjectTypesAreSet = MainAddressingObjectTypes <> Undefined AND NOT MainAddressingObjectTypes.IsEmpty();
	If NOT MainAddressingObjectTypesAreSet Then
		Common.MessageToUser(NStr("ru = 'Не указаны типы основного объекта адресации.'; en = 'Types of the main addressing object are not specified.'; pl = 'Types of the main addressing object are not specified.';de = 'Types of the main addressing object are not specified.';ro = 'Types of the main addressing object are not specified.';tr = 'Types of the main addressing object are not specified.'; es_ES = 'Types of the main addressing object are not specified.'"),
		 	ThisObject, "MainAddressingObjectTypes",,Cancel);
	EndIf;
	
EndProcedure

Procedure BeforeWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
		
	If MainAddressingObjectTypes <> Undefined AND MainAddressingObjectTypes.IsEmpty() Then
		MainAddressingObjectTypes = Undefined;
	EndIf;
	
	If AdditionalAddressingObjectTypes <> Undefined AND AdditionalAddressingObjectTypes.IsEmpty() Then
		AdditionalAddressingObjectTypes = Undefined;
	EndIf;
	
	If NOT GetFunctionalOption("UseExternalUsers") Then
		If Purpose.Find(Catalogs.Users.EmptyRef(), "UsersType") = Undefined Then
			// If external users are disconnected, the role must be assigned to users.
			Purpose.Add().UsersType = Catalogs.Users.EmptyRef();
		EndIf;
	EndIf;
	
EndProcedure

#EndRegion

#Else
Raise NStr("ru = 'Недопустимый вызов объекта на клиенте.'; en = 'Invalid object call on the client.'; pl = 'Invalid object call on the client.';de = 'Invalid object call on the client.';ro = 'Invalid object call on the client.';tr = 'Invalid object call on the client.'; es_ES = 'Invalid object call on the client.'");
#EndIf