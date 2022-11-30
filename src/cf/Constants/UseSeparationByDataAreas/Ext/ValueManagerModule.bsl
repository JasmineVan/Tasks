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
	
	AdditionalProperties.Insert("CurrentValue", Constants.UseSeparationByDataAreas.Get());
	
EndProcedure

Procedure OnWrite(Cancel)
	
	If DataExchange.Load Then
		
		Return;
		
	EndIf;
	
	// The following constants are mutually exclusive and intended for use in specific functional options only.
	//
	// Constant.IsStandaloneWorkstation -> FD.StandaloneModeOperations
	// Constant.DoNotUseDataSeparation -> FD.StandaloneModeOperations
	// Constant.UseDataSeparation -> FD.SaaS.
	//
	// Names of the constants are retained for backwards compatibility purposes.
	
	If Value Then
		
		Constants.DoNotUseSeparationByDataAreas.Set(False);
		Constants.IsStandaloneWorkplace.Set(False);
		
	ElsIf Constants.IsStandaloneWorkplace.Get() Then
		
		Constants.DoNotUseSeparationByDataAreas.Set(False);
		
	Else
		
		Constants.DoNotUseSeparationByDataAreas.Set(True);
		
	EndIf;
	
	If AdditionalProperties.CurrentValue <> Value Then
		
		RefreshReusableValues();
		
		If Value Then
			
			SSLSubsystemsIntegration.OnEnableSeparationByDataAreas();
			
		EndIf;
		
	EndIf;
	
EndProcedure

#EndRegion

#Else
Raise NStr("ru = 'Недопустимый вызов объекта на клиенте.'; en = 'Invalid object call on the client.'; pl = 'Niedozwolone wezwanie obiektu na kliencie.';de = 'Unzulässiger Objektaufruf auf dem Client.';ro = 'Apel inadmisibil al obiectului pe client.';tr = 'İstemcide kabul edilmeyen nesne çağrısı.'; es_ES = 'Llamada no disponible del objeto en el cliente.'");
#EndIf