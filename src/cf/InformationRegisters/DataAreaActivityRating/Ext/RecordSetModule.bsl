///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure OnWrite(Cancel, Replacing)
	
	// There is no DataExchange.Load property value verification, because the limitations imposed by the 
	// script should not be bypassed by passing True to the Load property (on the side of the script 
	// that records to this register).
	//
	// This register cannot be included in any exchanges or data import or export operations if the data 
	// area separation is enabled.
	
	If Not SaaS.SessionWithoutSeparators() Then
		
		Raise NStr("ru = 'Нарушение прав доступа.'; en = 'Access right violation.'; pl = 'Naruszenie praw dostępu.';de = 'Verletzung von Zugriffsrechten.';ro = 'Încălcarea drepturilor de acces.';tr = 'Erişim hakkı ihlali.'; es_ES = 'Violación del derecho de acceso.'");
		
	EndIf;
	
EndProcedure

#EndRegion

#Else
Raise NStr("ru = 'Недопустимый вызов объекта на клиенте.'; en = 'Invalid object call on the client.'; pl = 'Niedozwolone wezwanie obiektu na kliencie.';de = 'Unzulässiger Objektaufruf auf dem Client.';ro = 'Apel inadmisibil al obiectului pe client.';tr = 'İstemcide kabul edilmeyen nesne çağrısı.'; es_ES = 'Llamada no disponible del objeto en el cliente.'");
#EndIf