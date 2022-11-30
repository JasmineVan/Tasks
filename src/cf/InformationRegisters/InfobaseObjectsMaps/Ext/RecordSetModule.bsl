///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure BeforeWrite(Cancel, Replacing)
	
	// Disabling standard object registration mechanism.
	AdditionalProperties.Insert("DisableObjectChangeRecordMechanism");
	
	// Deleting all nodes that was added by AutoRecord if the AutoRecord flag is wrongly set to True.
	DataExchange.Recipients.Clear();
	
	// Filling the SourceUUIDAsString by the source reference.
	If Count() > 0 Then
		
		If ThisObject[0].ObjectExportedByRef = True Then
			Return;
		EndIf;
		
		ThisObject[0]["SourceUUIDString"] = String(ThisObject[0]["SourceUUID"].UUID());
		
	EndIf;
	
	If DataExchange.Load
		OR Not ValueIsFilled(Filter.InfobaseNode.Value)
		OR Not ValueIsFilled(Filter.DestinationUUID.Value)
		OR Not Common.RefExists(Filter.InfobaseNode.Value) Then
		Return;
	EndIf;
	
	// The record set must be registered only in the node that is specified in the filter.
	DataExchange.Recipients.Add(Filter.InfobaseNode.Value);
	
EndProcedure

#EndRegion

#Else
Raise NStr("ru = 'Недопустимый вызов объекта на клиенте.'; en = 'Invalid object call on the client.'; pl = 'Niedozwolone wezwanie obiektu na kliencie.';de = 'Unzulässiger Objektaufruf auf dem Client.';ro = 'Apel inadmisibil al obiectului pe client.';tr = 'İstemcide kabul edilmeyen nesne çağrısı.'; es_ES = 'Llamada no disponible del objeto en el cliente.'");
#EndIf