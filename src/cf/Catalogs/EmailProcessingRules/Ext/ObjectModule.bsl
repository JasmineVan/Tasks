﻿///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure OnWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	If Not Interactions.UserIsResponsibleForMaintainingFolders(Owner) Then
		Common.MessageToUser(
			NStr("ru = 'Данная операция доступна только ответственному за ведение папок для данной учетной записи'; en = 'This operation is available only for the person responsible for the account''s folders.'; pl = 'This operation is available only for the person responsible for the account''s folders.';de = 'This operation is available only for the person responsible for the account''s folders.';ro = 'This operation is available only for the person responsible for the account''s folders.';tr = 'This operation is available only for the person responsible for the account''s folders.'; es_ES = 'This operation is available only for the person responsible for the account''s folders.'"),
			Ref,,,
			Cancel);
	EndIf;
	
EndProcedure

#EndRegion

#Else
Raise NStr("ru = 'Недопустимый вызов объекта на клиенте.'; en = 'Invalid object call on the client.'; pl = 'Invalid object call on the client.';de = 'Invalid object call on the client.';ro = 'Invalid object call on the client.';tr = 'Invalid object call on the client.'; es_ES = 'Invalid object call on the client.'");
#EndIf