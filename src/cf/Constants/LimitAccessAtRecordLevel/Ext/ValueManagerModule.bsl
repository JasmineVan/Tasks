///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Variables

Var AccessRestrictionAtRecordLevelEnabled; // Flag showing whether the constant value changed from False to True.
                                                 // Used in OnWrite event handler.

Var AccessRestrictionAtRecordLevelChanged; // Flag indicating whether the constant value changed.
                                                 // Used in OnWrite event handler.

#EndRegion

#Region EventHandlers

Procedure BeforeWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	AccessRestrictionAtRecordLevelEnabled
		= Value AND NOT Constants.LimitAccessAtRecordLevel.Get();
	
	AccessRestrictionAtRecordLevelChanged
		= Value <>   Constants.LimitAccessAtRecordLevel.Get();
	
EndProcedure

Procedure OnWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	If AccessRestrictionAtRecordLevelChanged Then
		AccessManagementInternal.OnChangeAccessRestrictionAtRecordLevel(
			AccessRestrictionAtRecordLevelEnabled);
		
		If AccessManagementInternal.LimitAccessAtRecordLevelUniversally(True) Then
			
			PlanningParameters = AccessManagementInternal.AccessUpdatePlanningParameters();
			PlanningParameters.IsUpdateContinuation = True;
			PlanningParameters.Details = "RestrictAccessAtRecordsLevelOnWrite";
			AccessManagementInternal.ScheduleAccessUpdate(, PlanningParameters);
			
			AccessManagementInternal.SetAccessUpdate(True);
		EndIf;
	EndIf;
	
EndProcedure

#EndRegion

#Else
Raise NStr("ru = 'Недопустимый вызов объекта на клиенте.'; en = 'Invalid object call on the client.'; pl = 'Niedozwolone wezwanie obiektu na kliencie.';de = 'Unzulässiger Objektaufruf auf dem Client.';ro = 'Apel inadmisibil al obiectului pe client.';tr = 'İstemcide kabul edilmeyen nesne çağrısı.'; es_ES = 'Llamada no disponible del objeto en el cliente.'");
#EndIf