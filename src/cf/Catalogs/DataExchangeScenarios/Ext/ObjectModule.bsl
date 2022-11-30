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
	
	If DeletionMark Then
		
		UseScheduledJob = False;
		
	EndIf;
	
EndProcedure

Procedure OnWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	// Deleting a scheduled job if necessary.
	If DeletionMark Then
		
		DeleteScheduledJob(Cancel);
		
	EndIf;
	
	// Updating the platform cache for reading relevant settings of data exchange scenario by the 
	// DataExchangeCached.DataExchangeSettings procedure.
	RefreshReusableValues();
	
EndProcedure

Procedure OnCopy(CopiedObject)
	
	GUIDScheduledJob = "";
	
EndProcedure

Procedure BeforeDelete(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	DeleteScheduledJob(Cancel);
	
EndProcedure

#EndRegion

#Region Private

// Deletes a scheduled job.
//
// Parameters:
//  Cancel                     - Boolean - a cancellation flag. It is set to True if errors occur 
//                                       upon the procedure execution.
//  ScheduledJobObject - a scheduled job object to be deleted.
// 
Procedure DeleteScheduledJob(Cancel)
	
	SetPrivilegedMode(True);
	
	// Defining a scheduled job.
	ScheduledJobObject = Catalogs.DataExchangeScenarios.ScheduledJobByID(GUIDScheduledJob);
	
	If ScheduledJobObject <> Undefined Then
		
		Try
			ScheduledJobObject.Delete();
		Except
			MessageString = NStr("ru = 'Ошибка при удалении регламентного задания: %1'; en = 'Cannot delete the scheduled job: %1'; pl = 'Błąd podczas usunięcia zaplanowanego zadania: %1';de = 'Beim Entfernen des geplanten Jobs ist ein Fehler aufgetreten: %1';ro = 'Eroare la ștergerea sarcinii reglementare: %1';tr = 'Planlanmış işi kaldırırken bir hata oluştu: %1'; es_ES = 'Ha ocurrido un error al eliminar la tarea programada: %1'");
			MessageString = StringFunctionsClientServer.SubstituteParametersToString(MessageString, BriefErrorDescription(ErrorInfo()));
			DataExchangeServer.ReportError(MessageString, Cancel);
		EndTry;
		
	EndIf;
	
EndProcedure

#EndRegion

#Else
Raise NStr("ru = 'Недопустимый вызов объекта на клиенте.'; en = 'Invalid object call on the client.'; pl = 'Niedozwolone wezwanie obiektu na kliencie.';de = 'Unzulässiger Objektaufruf auf dem Client.';ro = 'Apel inadmisibil al obiectului pe client.';tr = 'İstemcide kabul edilmeyen nesne çağrısı.'; es_ES = 'Llamada no disponible del objeto en el cliente.'");
#EndIf