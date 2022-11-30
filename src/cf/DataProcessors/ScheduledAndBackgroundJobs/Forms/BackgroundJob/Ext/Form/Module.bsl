///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region EventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.BackgroundJobProperties = Undefined Then
		
		BackgroundJobProperties = ScheduledJobsInternal
			.GetBackgroundJobProperties(Parameters.ID);
		
		If BackgroundJobProperties = Undefined Then
			Raise(NStr("ru = 'Фоновое задание не найдено.'; en = 'The background job was not found.'; pl = 'Nie znaleziono zadania w tle.';de = 'Hintergrundjob wurde nicht gefunden.';ro = 'Sarcina de fundal nu a fost găsită.';tr = 'Arka plan görevi bulunamadı.'; es_ES = 'Tarea de fondo no encontrada.'"));
		EndIf;
		
		UserMessagesAndErrorDescription = ScheduledJobsInternal
			.BackgroundJobMessagesAndErrorDescriptions(Parameters.ID);
			
		If ValueIsFilled(BackgroundJobProperties.ScheduledJobID) Then
			
			ScheduledJobID
				= BackgroundJobProperties.ScheduledJobID;
			
			ScheduledJobDescription
				= ScheduledJobsInternal.ScheduledJobPresentation(
					BackgroundJobProperties.ScheduledJobID);
		Else
			ScheduledJobDescription  = ScheduledJobsInternal.TextUndefined();
			ScheduledJobID = ScheduledJobsInternal.TextUndefined();
		EndIf;
	Else
		BackgroundJobProperties = Parameters.BackgroundJobProperties;
		FillPropertyValues(
			ThisObject,
			BackgroundJobProperties,
			"UserMessagesAndErrorDescription,
			|ScheduledJobID,
			|ScheduledJobDescription");
	EndIf;
	
	FillPropertyValues(
		ThisObject,
		BackgroundJobProperties,
		"ID,
		|Key,
		|Description,
		|Begin,
		|End,
		|Location,
		|State,
		|MethodName");
		
	StandardSubsystemsServer.SetGroupTitleRepresentation(ThisObject);
	
EndProcedure

#EndRegion

#Region FormCommandHandlers

&AtClient
Procedure EventLogEvents(Command)
	EventFilter = New Structure;
	EventFilter.Insert("StartDate", Begin);
	EventFilter.Insert("EndDate", End);
	EventLogClient.OpenEventLog(EventFilter, ThisObject);
EndProcedure

#EndRegion
