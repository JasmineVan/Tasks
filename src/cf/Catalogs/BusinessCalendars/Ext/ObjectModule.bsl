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
	CheckBasicCalendarUse(Cancel);
EndProcedure

Procedure OnWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	CalendarSchedules.UpdateMultipleBusinessCalendarsUsage();
	
EndProcedure

#EndRegion

#Region Private

Procedure CheckBasicCalendarUse(Cancel)
	
	If Ref.IsEmpty() Or Not ValueIsFilled(BasicCalendar) Then
		Return;
	EndIf;
	
	// The reference to itself is prohibited.
	If Ref = BasicCalendar Then
		MessageText = NStr("ru = 'В качестве базового не может быть выбран тот же самый календарь.'; en = 'Cannot select a calendar as a source for itself.'; pl = 'Jako podstawowy nie może być wybrany ten sam kalendarz.';de = 'Der gleiche Kalender kann nicht als Basiskalender ausgewählt werden.';ro = 'Nu puteți alege același calendar în calitate de calendar de bază.';tr = 'Aynı takvim baz takvimi olarak seçilemez.'; es_ES = 'Como el calendario básico no puede ser seleccionado el mismo calendario.'");
		Common.MessageToUser(MessageText, , , "Object.BasicCalendar", Cancel);
		Return;
	EndIf;
	
	// If the calendar is already a basic one for another calendar, then prohibit filling of the basic 
	// calendar to avoid cyclic dependencies.
	
	Query = New Query;
	Query.SetParameter("Calendar", Ref);
	Query.Text = 
		"SELECT TOP 1
		|	Ref
		|FROM
		|	Catalog.BusinessCalendars AS BusinessCalendars
		|WHERE
		|	BusinessCalendars.BasicCalendar = &Calendar";
	QueryResult = Query.Execute();
	If QueryResult.IsEmpty() Then
		Return;
	EndIf;
	
	Selection = QueryResult.Select();
	Selection.Next();
	
	MessageText = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("ru = 'Календарь уже является базовым для календаря «%1» и не может зависеть от другого.'; en = 'The calendar is a source for ""%1."" It cannot depend on another calendar.'; pl = 'Kalendarz jest już podstawowym dla kalendarza ""%1"" i nie może zależeć od innego.';de = 'Der Kalender ist bereits grundlegend für den Kalender ""%1"" und kann nicht von anderen abhängig sein.';ro = 'Calendarul deja este de bază pentru calendarul ”%1” și nu poate fi subordonat altuia.';tr = 'Takvim ""%1"" takvimi için zaten baz takvimdir ve başka takvime bağlı olamaz.'; es_ES = 'El calendario ya es básico para el calendario ""%1"" y no puede depender de otro.'"),
		Selection.Ref);
	Common.MessageToUser(MessageText, Selection.Ref, , "Object.BasicCalendar", Cancel);
	
EndProcedure

#EndRegion

#Else
Raise NStr("ru = 'Недопустимый вызов объекта на клиенте.'; en = 'Invalid object call on the client.'; pl = 'Niedozwolone wezwanie obiektu na kliencie.';de = 'Unzulässiger Objektaufruf auf dem Client.';ro = 'Apel inadmisibil al obiectului pe client.';tr = 'İstemcide kabul edilmeyen nesne çağrısı.'; es_ES = 'Llamada no disponible del objeto en el cliente.'");
#EndIf