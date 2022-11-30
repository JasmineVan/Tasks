///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure BeforeWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	If Owner.DeletionMark Then
		Return;
	EndIf;

	If NOT Interactions.UserIsResponsibleForMaintainingFolders(Owner) Then
		Common.MessageToUser(
			NStr("ru = 'Данная операция доступна только ответственному за ведение папок для данной учетной записи'; en = 'This operation is available only for the person responsible for the account''s folders.'; pl = 'This operation is available only for the person responsible for the account''s folders.';de = 'This operation is available only for the person responsible for the account''s folders.';ro = 'This operation is available only for the person responsible for the account''s folders.';tr = 'This operation is available only for the person responsible for the account''s folders.'; es_ES = 'This operation is available only for the person responsible for the account''s folders.'"),
			Ref,,,Cancel);
	ElsIf PredefinedFolder AND DeletionMark AND (NOT Owner.DeletionMark) Then
		Common.MessageToUser(
		NStr("ru = 'Нельзя установить пометку удаления для предопределенной папки'; en = 'Cannot set the deletion mark for the predefined folder'; pl = 'Cannot set the deletion mark for the predefined folder';de = 'Cannot set the deletion mark for the predefined folder';ro = 'Cannot set the deletion mark for the predefined folder';tr = 'Cannot set the deletion mark for the predefined folder'; es_ES = 'Cannot set the deletion mark for the predefined folder'"),
		Ref,,,Cancel);
	ElsIf PredefinedFolder AND (Not Parent.IsEmpty()) Then
	Common.MessageToUser(
		NStr("ru = 'Нельзя переместить предопределенную папку в другую папку'; en = 'Cannot move predefined folder to another folder'; pl = 'Cannot move predefined folder to another folder';de = 'Cannot move predefined folder to another folder';ro = 'Cannot move predefined folder to another folder';tr = 'Cannot move predefined folder to another folder'; es_ES = 'Cannot move predefined folder to another folder'"),
		Ref,,,Cancel);
	EndIf;
	
	AdditionalProperties.Insert("Parent",Common.ObjectAttributeValue(Ref,"Parent"));
	
EndProcedure

Procedure OnCopy(CopiedObject)
	
	PredefinedFolder = False;
	
EndProcedure

Procedure OnWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	If AdditionalProperties.Property("Parent") AND Parent <> AdditionalProperties.Parent Then
		If NOT AdditionalProperties.Property("ParentChangeProcessed") Then
			Interactions.SetFolderParent(Ref,Parent,True)
		EndIf;
	EndIf;
	
EndProcedure

#EndRegion

#Else
Raise NStr("ru = 'Недопустимый вызов объекта на клиенте.'; en = 'Invalid object call on the client.'; pl = 'Invalid object call on the client.';de = 'Invalid object call on the client.';ro = 'Invalid object call on the client.';tr = 'Invalid object call on the client.'; es_ES = 'Invalid object call on the client.'");
#EndIf