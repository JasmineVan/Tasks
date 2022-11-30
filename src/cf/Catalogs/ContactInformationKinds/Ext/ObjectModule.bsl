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
	
	If NOT IsFolder Then
		Result = ContactsManagerInternal.CheckContactsKindParameters(ThisObject);
		If Result.HasErrors Then
			Cancel = True;
			Raise Result.ErrorText;
		EndIf;
		NameOfGroup = Common.ObjectAttributeValue(Parent, "PredefinedKindName");
		If IsBlankString(NameOfGroup) Then
			NameOfGroup = Common.ObjectAttributeValue(Parent, "PredefinedDataName");
		EndIf;
	EndIf;
	
EndProcedure

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	If IsFolder Then
		
		AttributesNotToCheck = New Array;
		AttributesNotToCheck.Add("Parent");
		Common.DeleteNotCheckedAttributesFromArray(CheckedAttributes, AttributesNotToCheck);

	EndIf;
	
EndProcedure

#EndRegion

#Region EventHandlers

Procedure OnReadPresentationsAtServer() Export
	
	LocalizationServer.OnReadPresentationsAtServer(ThisObject);
	
EndProcedure

#EndRegion

#Else
Raise NStr("ru = 'Недопустимый вызов объекта на клиенте.'; en = 'Invalid object call on the client.'; pl = 'Niedozwolone wezwanie obiektu na kliencie.';de = 'Unzulässiger Objektaufruf auf dem Client.';ro = 'Apel inadmisibil al obiectului pe client.';tr = 'İstemcide kabul edilmeyen nesne çağrısı.'; es_ES = 'Llamada no disponible del objeto en el cliente.'");
#EndIf