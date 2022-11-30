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
	
	If Parameters.ChoiceMode Then
		Items.List.ChoiceMode = True;
	EndIf;
	
	SetListParameters();
	
	CanBeEdited = AccessRight("Edit", Metadata.Catalogs.Calendars);
	HasAttributeBulkEditing = Common.SubsystemExists("StandardSubsystems.BatchEditObjects");
	Items.ListChangeSelectedItems.Visible = HasAttributeBulkEditing AND CanBeEdited;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtServerNoContext
Procedure ListOnReceiveDataAtServer(ItemName, Settings, Rows)
	
	Query = New Query;
	Query.SetParameter("Calendars", Rows.GetKeys());
	Query.Text = 
		"SELECT
		|	CalendarSchedules.Calendar AS WorkSchedule,
		|	MAX(CalendarSchedules.ScheduleDate) AS FillDate
		|INTO TTScheduleBusyDates
		|FROM
		|	InformationRegister.CalendarSchedules AS CalendarSchedules
		|WHERE
		|	CalendarSchedules.Calendar IN(&Calendars)
		|
		|GROUP BY
		|	CalendarSchedules.Calendar
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	BusinessCalendarsData.BusinessCalendar AS BusinessCalendar,
		|	MAX(BusinessCalendarsData.Date) AS FillDate
		|INTO TTCalendarBusyDates
		|FROM
		|	InformationRegister.BusinessCalendarData AS BusinessCalendarsData
		|		INNER JOIN Catalog.Calendars AS Calendars
		|		ON (Calendars.BusinessCalendar = BusinessCalendarsData.BusinessCalendar)
		|			AND (Calendars.Ref IN (&Calendars))
		|
		|GROUP BY
		|	BusinessCalendarsData.BusinessCalendar
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	CatalogWorkSchedules.Ref AS Ref,
		|	CatalogWorkSchedules.PlanningHorizon AS PlanningHorizon,
		|	CatalogWorkSchedules.EndDate AS EndDate,
		|	CatalogWorkSchedules.BusinessCalendar AS BusinessCalendar,
		|	ISNULL(SchedulesData.FillDate, DATETIME(1, 1, 1)) AS FillDate,
		|	ISNULL(BusinessCalendarsData.FillDate, DATETIME(1, 1, 1)) AS BusinessCalendarFillDate
		|FROM
		|	Catalog.Calendars AS CatalogWorkSchedules
		|		LEFT JOIN TTScheduleBusyDates AS SchedulesData
		|		ON CatalogWorkSchedules.Ref = SchedulesData.WorkSchedule
		|		LEFT JOIN TTCalendarBusyDates AS BusinessCalendarsData
		|		ON CatalogWorkSchedules.BusinessCalendar = BusinessCalendarsData.BusinessCalendar
		|WHERE
		|	CatalogWorkSchedules.Ref IN(&Calendars)
		|	AND NOT CatalogWorkSchedules.IsFolder";
	Selection = Query.Execute().Select();
	While Selection.Next() Do
		RequiredFillingDate = AddMonth(CurrentSessionDate(), Selection.PlanningHorizon);
		RequiresFilling = Selection.FillDate < RequiredFillingDate;
		ListLine = Rows[Selection.Ref];
		ListLine.Data["FillDate"] = Selection.FillDate;
		ListLine.Data["BusinessCalendarFillDate"] = Selection.BusinessCalendarFillDate;
		ListLine.Data["RequiresFilling"] = RequiresFilling;
		ListLine.Data["RequiredFillingDate"] = RequiredFillingDate;
		If Not RequiresFilling Then
			Continue;
		EndIf;
		For Each KeyAndValue In ListLine.Appearance Do
			KeyAndValue.Value.SetParameterValue("TextColor", StyleColors.OverdueDataColor);
		EndDo;
		PossibleReason = "";
		If ValueIsFilled(Selection.BusinessCalendar) Then
			If Not ValueIsFilled(Selection.BusinessCalendarFillDate) Then
				PossibleReason = NStr("ru = 'Производственный календарь не заполнен'; en = 'The business calendar is blank.'; pl = 'Nie wypełniono kalendarza produkcyjnego';de = 'Der Produktionskalender ist nicht ausgefüllt';ro = 'Calendarul de producție nu este completat';tr = 'Üretim takvimi doldurulmadı'; es_ES = 'Calendario laboral no rellenado'");
			Else
				If Selection.BusinessCalendarFillDate < RequiredFillingDate Then
					PossibleReason = NStr("ru = 'Производственный календарь не заполнен на очередной календарный год'; en = 'The business calendar for the next calendar year is blank.'; pl = 'Nie wypełniono kalendarza produkcyjnego na następny rok kalendarzowy';de = 'Der Produktionskalender wird für das nächste Kalenderjahr nicht ausgefüllt';ro = 'Calendarul de producție nu este completat pentru anul calendaristic necesar';tr = 'Üretim takvimi sonraki takvim yılı için doldurulmadı'; es_ES = 'Calendario laboral no rellenado para este año'");
				EndIf;
			EndIf;
		Else
			If Not ValueIsFilled(Selection.EndDate) Then
				PossibleReason = NStr("ru = 'График не был заполнен на очередной календарный год'; en = 'The schedule for the next calendar year was not filled in.'; pl = 'Harmonogram nie został wypełniony na następny rok kalendarzowy';de = 'Der Zeitplan wurde für das nächste Kalenderjahr nicht ausgefüllt';ro = 'Programul nu este completat pentru anul calendaristic necesar';tr = 'Grafik sonraki takvim yılı için doldurulmadı'; es_ES = 'El horario no ha sido rellenado para este año'");
			Else
				If Selection.EndDate < RequiredFillingDate Then
					PossibleReason = NStr("ru = 'Период заполнения графика ограничен (см. поле «Дата окончания»)'; en = 'The schedule period is limited (see the ""End date"" field).'; pl = 'Okres wypełniania harmonogramu jest ograniczony (zob. pole ""Data zakończenia"")';de = 'Der Füllzeitraum des Diagramms ist begrenzt (siehe Feld ""Enddatum"")';ro = 'Perioada de completare a programului este limitată (vezi câmpul ”Data finalizării”)';tr = 'Grafik doldurma süresi sınırlıdır (bkz. ""Bitiş tarihi"" alanı)'; es_ES = 'El período de rellenar el horario está restringido (véase el campo ""Fecha de terminación"")'")
				EndIf;
			EndIf;
		EndIf;
		ListLine.Data["PossibleCause"] = PossibleReason;
	EndDo;
	
EndProcedure

#EndRegion

#Region FormCommandHandlers

&AtClient
Procedure ChangeSelectedItems(Command)
	If CommonClient.SubsystemExists("StandardSubsystems.BatchEditObjects") Then
		ModuleBatchObjectModificationClient = CommonClient.CommonModule("BatchEditObjectsClient");
		ModuleBatchObjectModificationClient.ChangeSelectedItems(Items.List);
	EndIf;
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SetListParameters()
	
	CommonClientServer.SetDynamicListFilterItem(
		List, "ScheduleOwner", , DataCompositionComparisonType.NotFilled, , ,
		DataCompositionSettingsItemViewMode.Normal);
	
EndProcedure

#EndRegion
