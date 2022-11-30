///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Variables

Var PreviousValue;

#EndRegion

#Region EventHandlers

Procedure BeforeWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	PreviousValue = Constants.LimitAccessAtRecordLevelUniversally.Get();
	
EndProcedure

Procedure OnWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	If Value AND Not PreviousValue Then // Enabled.
		ValueManager = Constants.LastAccessUpdate.CreateValueManager();
		ValueManager.Value = New ValueStorage(Undefined);
		InfobaseUpdate.WriteData(ValueManager);
		RecordSet = InformationRegisters.AccessRestrictionParameters.CreateRecordSet();
		InfobaseUpdate.WriteData(RecordSet);
		InformationRegisters.AccessRestrictionParameters.UpdateRegisterData();
	EndIf;
	
	If Not Value AND PreviousValue Then // Disabled.
		ValueManager = Constants.FirstAccessUpdateCompleted.CreateValueManager();
		ValueManager.Value = False;
		InfobaseUpdate.WriteData(ValueManager);
		AccessManagementInternal.EnableDataFillingForAccessRestriction();
	EndIf;
	
	If Value <> PreviousValue Then // Changed.
		// Updating session parameters.
		// It is required so that the administrator does not have to restart.
		SpecifiedParameters = New Array;
		AccessManagementInternal.SessionParametersSetting("", SpecifiedParameters);
		RefreshReusableValues();
	EndIf;
	
EndProcedure

#EndRegion

#Else
Raise NStr("ru = 'Недопустимый вызов объекта на клиенте.'; en = 'Invalid object call on the client.'; pl = 'Niedozwolone wezwanie obiektu na kliencie.';de = 'Unzulässiger Objektaufruf auf dem Client.';ro = 'Apel inadmisibil al obiectului pe client.';tr = 'İstemcide kabul edilmeyen nesne çağrısı.'; es_ES = 'Llamada no disponible del objeto en el cliente.'");
#EndIf