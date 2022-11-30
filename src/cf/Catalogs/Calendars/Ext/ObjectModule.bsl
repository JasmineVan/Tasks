///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	If ValueIsFilled(EndDate) AND EndDate < StartDate Then
		MessageText = NStr("ru = 'Дата окончания меньше даты начала. Скорее всего, дата окончания заполнена неверно.'; en = 'The end date is earlier than the start date. Probably the end date is incorrect.'; pl = 'Data końcowa jest mniejsza, niż data rozpoczęcia. Najprawdopodobniej data końcowa jest niepoprawnie wypełniona.';de = 'Das Enddatum liegt vor dem Anfangsdatum. Wahrscheinlich ist das Enddatum falsch ausgefüllt.';ro = 'Data sfârșitului este mai mică decât data începutului. Posibil, data sfârșitului este completată incorect.';tr = 'Bitiş tarihi başlangıç tarihinden daha azdır. Büyük olasılıkla bitiş tarihi yanlış doldurulur.'; es_ES = 'Fecha de finalización es menor que la fecha del inicio. Es posible que la fecha de finalización esté rellenado incorrectamente.'");
		Common.MessageToUser(MessageText, Ref, , , Cancel);
	EndIf;
	
EndProcedure

Procedure BeforeWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	If IsFolder Then
		Return;
	EndIf;
	
	InfobaseUpdate.CheckObjectProcessed("Catalog.Calendars");
	
	If Not ConsiderHolidays Then
		// If the work schedule does not consider holidays, delete preholiday intervals.
		PreholidaySchedule = WorkSchedule.FindRows(New Structure("DayNumber", 0));
		For Each ScheduleString In PreholidaySchedule Do
			WorkSchedule.Delete(ScheduleString);
		EndDo;
	EndIf;
	
EndProcedure

Procedure OnWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	If IsFolder Then
		Return;
	EndIf;
	
	// If the end date is not specified, it will be picked by the business calendar.
	FillingEndDate = EndDate;
	
	DaysIncludedInSchedule = Catalogs.Calendars.DaysIncludedInSchedule(
									StartDate, 
									FillingMethod, 
									FillingTemplate, 
									FillingEndDate,
									BusinessCalendar, 
									ConsiderHolidays, 
									StartingDate);
									
	Catalogs.Calendars.WriteScheduleDataToRegister(
		Ref, DaysIncludedInSchedule, StartDate, FillingEndDate);
	
EndProcedure

#EndRegion

#Else
Raise NStr("ru = 'Недопустимый вызов объекта на клиенте.'; en = 'Invalid object call on the client.'; pl = 'Niedozwolone wezwanie obiektu na kliencie.';de = 'Unzulässiger Objektaufruf auf dem Client.';ro = 'Apel inadmisibil al obiectului pe client.';tr = 'İstemcide kabul edilmeyen nesne çağrısı.'; es_ES = 'Llamada no disponible del objeto en el cliente.'");
#EndIf