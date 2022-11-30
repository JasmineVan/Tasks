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
	
	If Not IsFolder AND DeletionMark Then
		Use = False;
	EndIf;
	
	InfobaseUpdate.CheckObjectProcessed(ThisObject);
	
	AccountingCheckIsChanged = ObjectChanged();
	
EndProcedure

#EndRegion

#Region Private

Function ObjectChanged()
	
	If IsNew() Then
		Return False;
	EndIf;
	
	If AccountingCheckIsChanged Then
		Return True;
	EndIf;
	
	If AdditionalProperties.Property("CheckChange") AND Not AdditionalProperties.CheckChange Then
		Return False;
	EndIf;
	
	AttributesToCheck = New Array;
	AttributesToCheck.Add("Description");
	
	If Not IsFolder Then
		
		Attributes = Metadata().Attributes;
		For Each Attribute In Attributes Do
			
			If Attribute.Name = "AdditionalParameters"
				Or Attribute.Name = "CheckSchedule"
				Or Attribute.Name = "AccountingCheckIsChanged" Then
				Continue;
			EndIf;
			
			AttributesToCheck.Add(Attribute.Name);
			
		EndDo;
		
	EndIf;
	
	For Each AttributeToCheck In AttributesToCheck Do
		
		If Ref[AttributeToCheck] <> ThisObject[AttributeToCheck] Then
			Return True;
		EndIf;
		
	EndDo;
	
EndFunction

#EndRegion

#Else
Raise NStr("ru = 'Недопустимый вызов объекта на клиенте.'; en = 'Invalid object call on the client.'; pl = 'Invalid object call on the client.';de = 'Invalid object call on the client.';ro = 'Invalid object call on the client.';tr = 'Invalid object call on the client.'; es_ES = 'Invalid object call on the client.'");
#EndIf