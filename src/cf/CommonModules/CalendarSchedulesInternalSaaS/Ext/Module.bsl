﻿///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Internal

// It is called when changing data of business calendars.
//
Procedure PlanUpdateOfDataDependentOnBusinessCalendars(Val UpdateConditions) Export
	
	MethodParameters = New Array;
	MethodParameters.Add(UpdateConditions);
	MethodParameters.Add(New UUID);

	JobParameters = New Structure;
	JobParameters.Insert("MethodName", "CalendarSchedulesInternalSaaS.UpdateDataDependentOnBusinessCalendars");
	JobParameters.Insert("Parameters", MethodParameters);
	JobParameters.Insert("RestartCountOnFailure", 3);
	JobParameters.Insert("DataArea", -1);
	
	SetPrivilegedMode(True);
	JobQueue.AddJob(JobParameters);

EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Configuration subsystems event handlers.

// See JobsQueueOverridable.OnDefineHandlersAliases. 
Procedure OnDefineHandlerAliases(NameAndAliasMap) Export
	
	NameAndAliasMap.Insert("CalendarSchedulesInternalSaaS.UpdateDataDependentOnBusinessCalendars");
	
EndProcedure

#EndRegion

#Region Private

// Procedure for calling from a job queue placed in PlanUpdateDataDependentOnBusinessCalendars.
// 
// Parameters:
//  UpdateConditions - ValueTable with schedule update conditions.
//  FileID - file UUID of processed supplied data.
//
Procedure UpdateDataDependentOnBusinessCalendars(Val UpdateConditions, Val FileID) Export
	
	// Getting data areas for processing.
	AreasForUpdate = SuppliedData.AreasRequireProcessing(
		FileID, "BusinessCalendarsData");
		
	// Updating work schedules by data areas.
	DistributeBusinessCalendarDataByDependentData(UpdateConditions, AreasForUpdate, 
		FileID, "BusinessCalendarsData");

EndProcedure

// Fills data that depends on business calendars according to the business calendar data for all data areas.
//
// Parameters:
//  UpdateConditions - ValueTable with schedule update conditions.
//  AreasForUpdate - array of area codes.
//  FileID - file UUID of processed rates.
//  HandlerCode - String, handler code.
//
Procedure DistributeBusinessCalendarDataByDependentData(Val UpdateConditions, 
	Val AreasForUpdate, Val FileID, Val HandlerCode)
	
	UpdateConditions.GroupBy("BusinessCalendarCode, Year");
	
	For each DataArea In AreasForUpdate Do
		SetPrivilegedMode(True);
		SaaS.SetSessionSeparation(True, DataArea);
		SetPrivilegedMode(False);
		BeginTransaction();
		Try
			CalendarSchedules.FillDataDependentOnBusinessCalendars(UpdateConditions);
			SuppliedData.AreaProcessed(FileID, HandlerCode, DataArea);
			CommitTransaction();
		Except
			RollbackTransaction();
			WriteLogEvent(NStr("ru = 'Календарные графики.Распространение производственных календарей'; en = 'Calendar schedules.Distribute business calendars'; pl = 'Harmonogramy kalendarzowe.Rozpowszechnianie kalendarzy produkcyjnych';de = 'Kalendergrafiken. Verteilung von Produktionskalendern';ro = 'Programe calendaristice.Distribuirea calendarelor de producție';tr = 'Takvim grafikler. Üretim takvimlerinin yayılması'; es_ES = 'Calendarios. Distribución de los calendarios laborales'", Common.DefaultLanguageCode()),
									EventLogLevel.Error,,,
									DetailErrorDescription(ErrorInfo()));
		EndTry;
	EndDo;
	
EndProcedure

#EndRegion
