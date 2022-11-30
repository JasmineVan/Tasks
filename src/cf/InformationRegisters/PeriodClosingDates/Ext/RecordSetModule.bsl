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
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	If Filter.User.Use
	   AND Not PeriodClosingDatesInternal.IsPeriodClosingAddressee(Filter.User.Value) Then
		// Import restriction dates are set up separately in each infobase.
		AdditionalProperties.Insert("DisableObjectChangeRecordMechanism");
	EndIf;
	
EndProcedure

Procedure OnWrite(Cancel, Replacing)
	
	// In the DataExchange.Import mode, it is required to update UUID in the PeriodClosingDatesVersion 
	// constant that allows sessions to define that the cache of period-end closing dates is to be updated.
	If DataExchange.Load Then
		If Not AdditionalProperties.Property("SkipPeriodClosingDatesVersionUpdate") Then
			PeriodClosingDatesInternal.UpdatePeriodClosingDatesVersionOnDataImport(ThisObject);
		EndIf;
		Return;
	EndIf;
	
	If Not AdditionalProperties.Property("SkipPeriodClosingDatesVersionUpdate") Then
		PeriodClosingDatesInternal.UpdatePeriodClosingDatesVersion();
	EndIf;
	
EndProcedure

#EndRegion

#Else
Raise NStr("ru = 'Недопустимый вызов объекта на клиенте.'; en = 'Invalid object call on the client.'; pl = 'Niedozwolone wezwanie obiektu na kliencie.';de = 'Unzulässiger Objektaufruf auf dem Client.';ro = 'Apel inadmisibil al obiectului pe client.';tr = 'İstemcide kabul edilmeyen nesne çağrısı.'; es_ES = 'Llamada no disponible del objeto en el cliente.'");
#EndIf