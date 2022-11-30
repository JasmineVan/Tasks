///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Private

////////////////////////////////////////////////////////////////////////////////
// Identical procedures and functions of PeriodClosingDates and EditPeriodEndClosingDate forms.

Function ClosingDatesDetails() Export
	
	List = New Map;
	List.Insert("",                      NStr("ru = 'Не установлена'; en = 'No date'; pl = 'Nie zainstalowana';de = 'Nicht installiert';ro = 'Nu este stabilită';tr = 'Belirlenmedi'; es_ES = 'No establecida'"));
	List.Insert("Custom",      NStr("ru = 'Произвольная дата'; en = 'Custom date'; pl = 'Dowolna data';de = 'Individuelle Datum';ro = 'Date personalizate';tr = 'Özel tarih'; es_ES = 'Fecha personalizada'"));
	List.Insert("EndOfLastYear",     NStr("ru = 'Конец прошлого года'; en = 'End of last year'; pl = 'Koniec zeszłego roku';de = 'Letztes Jahresende';ro = 'Sfârșitul anului trecut';tr = 'Geçen yıl sonu'; es_ES = 'Fin del año pasado'"));
	List.Insert("EndOfLastQuarter", NStr("ru = 'Конец прошлого квартала'; en = 'End of last quarter'; pl = 'Koniec zeszłego kwartału';de = 'Letztes Quartalsende';ro = 'Ultimul trimestru';tr = 'Geçen çeyrek sonu'; es_ES = 'Fin del último trimestre'"));
	List.Insert("EndOfLastMonth",   NStr("ru = 'Конец прошлого месяца'; en = 'End of last month'; pl = 'Koniec zeszłego miesiąca';de = 'Letztes Monatsende';ro = 'Sfârșitul lunii trecute';tr = 'Geçen ay sonu'; es_ES = 'Fin del último mes'"));
	List.Insert("EndOfLastWeek",    NStr("ru = 'Конец прошлой недели'; en = 'End of last week'; pl = 'Koniec zeszłego tygodnia';de = 'Letzte Woche Ende';ro = 'Săptămâna trecută';tr = 'Geçen hafta sonu'; es_ES = 'Fin de la última semana'"));
	List.Insert("PreviousDay",        NStr("ru = 'Предыдущий день'; en = 'Previous day'; pl = 'Dzień poprzedni';de = 'Letzter Tag';ro = 'Ziua precedentă';tr = 'Önceki gün'; es_ES = 'Día precedente'"));
	
	Return List;
	
EndFunction

Procedure SpecifyPeriodEndClosingDateSetupOnChange(Context, CalculatePeriodEndClosingDate = True) Export
	
	If Context.ExtendedModeSelected Then
		If Context.PeriodEndClosingDateDetails = "" Then
			Context.PeriodEndClosingDate = "00010101";
		EndIf;
	Else
		If Context.PeriodEndClosingDate <> '00010101' AND Context.PeriodEndClosingDateDetails = "" Then
			Context.PeriodEndClosingDateDetails = "Custom";
			
		ElsIf Context.PeriodEndClosingDate = '00010101' AND Context.PeriodEndClosingDateDetails = "Custom" Then
			Context.PeriodEndClosingDateDetails = "";
		EndIf;
	EndIf;
	
	Context.RelativePeriodEndClosingDateLabelText = "";
	
	If Context.PeriodEndClosingDateDetails = "Custom" Or Context.PeriodEndClosingDateDetails = "" Then
		Context.PermissionDaysCount = 0;
		Return;
	EndIf;
	
	CalculatedPeriodEndClosingDates = PeriodEndClosingDateCalculation(
		Context.PeriodEndClosingDateDetails, Context.BegOfDay);
	
	If CalculatePeriodEndClosingDate Then
		Context.PeriodEndClosingDate = CalculatedPeriodEndClosingDates.Current;
	EndIf;
	
	LabelText = "";
	
	If Context.EnableDataChangeBeforePeriodEndClosingDate Then
		Days = 60*60*24;
		
		AdjustPermissionDaysCount(
			Context.PeriodEndClosingDateDetails, Context.PermissionDaysCount);
		
		PermissionPeriod = CalculatedPeriodEndClosingDates.Current + Context.PermissionDaysCount * Days;
		
		If Context.BegOfDay > PermissionPeriod Then
			LabelText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'Запрещен ввод и редактирование данных за все прошлые периоды 
					|по %1 включительно (%2).
					|Отсрочка, разрешавшая ввод и редактирование данных 
					|за период с %3 по %4, истекла %5.'; 
					|en = 'Data entry and modification for past periods through %1 are restricted (%2).
					|Delayed data entry and modification for the period from %3 to %4 expired on %5.'; 
					|pl = 'Jest zakazane wprowadzenie i edycja danych za wszystkie poprzednie okresy 
					|do %1 włącznie (%2).
					| Odroczenie, pozwalające wprowadzenie i edycję danych 
					|za okres od %3 do %4, wygasło %5.';
					|de = 'Es ist verboten, Daten für alle vergangenen Zeiträume 
					| bis %1 einschließlich (%2) einzugeben und zu bearbeiten.
					|Die Verzögerung, die die Eingabe und Bearbeitung von Daten
					|für den Zeitraum von %3 bis %4ermöglicht, ist abgelaufen %5.';
					|ro = 'Este interzisă introducerea și editarea datelor pentru toate perioadele precedente 
					|până la %1 inclusiv (%2).
					|Amânarea care permitea introducerea și editarea datelor 
					|pe perioada de la %3 până la %4 s-a scurs la %5.';
					|tr = '
					| itibaren %1 kadar tüm geçmiş dönemlerde veri girişi ve düzenleme yasaktır (%2).
					|Yazılımın 
					| itibaren %3 kadar olan dönem boyunca verilerin girilmesine ve düzenlenmesine izin veren erteleme%4 süresi doldu %5.'; 
					|es_ES = 'Está prohibido introducir o editar los datos de los períodos anteriores 
					|a %1 incluyendo (%2).
					|El aplazamiento que permitía la introducción y edición de los datos 
					|en el período de %3 a %4, está expirado %5.'"),
				Format(Context.PeriodEndClosingDate, "DLF=D"), Lower(ClosingDatesDetails()[Context.PeriodEndClosingDateDetails]),
				Format(CalculatedPeriodEndClosingDates.Previous + Days, "DLF=D"), Format(CalculatedPeriodEndClosingDates.Current, "DLF=D"),
				Format(PermissionPeriod, "DLF=D"));
		Else
			If CalculatePeriodEndClosingDate Then
				Context.PeriodEndClosingDate = CalculatedPeriodEndClosingDates.Previous;
			EndIf;
			LabelText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = '• По %1 включительно запрещен ввод и редактирование данных
					|  за все прошлые периоды по %2
					|  и действует отсрочка, разрешающая ввод и редактирование данных 
					|  за период с %4 по %5;
					|• С %6 начнет действовать запрет на ввод и редактирование данных
					|  за все прошлые периоды по %5 (%3).'; 
					|en = '• You cannot enter and edit data till %1 inclusive 
					|for all previous periods up to %2; 
					|there is a delay that allows data entry and editing 
					|for the period from %4 to %5;
					|• Period-end closing becomes effective from %6 
					| for all previous periods up to %5 (%3).'; 
					|pl = '• Do %1 włącznie jest zakazane wprowadzenie i edycja danych 
					| za wszystkie poprzednie okresy według %2
					|  i działa odroczenie, pozwalające wprowadzenie i edycję danych 
					|  za okres od %4 do %5;
					|• Z dnia%6 zacznie obowiązywać zakaz na wprowadzenie i edycję danych 
					|  za wszystkie poprzednie okresy do%5 (%3).';
					|de = '• Bis einschließlich %1 ist die Dateneingabe und -bearbeitung
					|  für alle vergangenen Zeiträume bis %2
					| verboten, und es gibt eine Zurückstellung, die die Dateneingabe und -bearbeitung 
					|  für den Zeitraum von %4 bis %5ermöglicht;
					|. • Mit %6 wird ein Verbot der Dateneingabe und -bearbeitung
					|   für alle vergangenen Zeiträume bis %5 (%3) wirksam.';
					|ro = '• Până la %1 inclusiv este interzisă introducerea și editarea datelor
					| pe toate perioadele precedente până la %2
					| și este valabilă amânarea care permite introducerea și editarea datelor 
					| pe perioada de la %4 până la %5;
					|• Din %6 va intra în vigoare interdicția de introducere și modificare a datelor
					| pe toate perioadele precedente până la %5 (%3).';
					|tr = '•  %1 kadar, tüm geçmiş dönemler  %2
					|  kadar veri girişi ve düzenlenmesi 
					| yasaklanmış olup,  %4 itibaren %5 kadar veri girişine ve düzenlenmesine izin veren erteleme geçerlidir
					|;
					|•  %6 itibaren 
					| kadar tüm geçmiş dönemlere ait %5veri girişi ve düzenlenmesi yasaklanacaktır (%3).'; 
					|es_ES = '• A %1 incluyendo está prohibido introducir y editar los datos 
					| de todos los períodos anteriores a %2
					| y hay aplazamiento, que permite la introducción y edición de los datos 
					| del período de %4 a %5;
					|• De %6 va a estar prohibido introducir y editar los datos
					| de todos los períodos anteriores a %5 (%3).'"),
					Format(PermissionPeriod, "DLF=D"), Format(Context.PeriodEndClosingDate, "DLF=D"), Lower(ClosingDatesDetails()[Context.PeriodEndClosingDateDetails]),
					Format(CalculatedPeriodEndClosingDates.Previous + Days, "DLF=D"),  Format(CalculatedPeriodEndClosingDates.Current, "DLF=D"), 
					Format(PermissionPeriod + Days, "DLF=D"));
		EndIf;
	Else 
		Context.PermissionDaysCount = 0;
		LabelText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Запрещен ввод и редактирование данных за все прошлые периоды
			           |по %1 (%2)'; 
			           |en = 'Data entry and editing for all previous periods
			           |up to %1 (%2) are restricted'; 
			           |pl = 'Jest zakazane wprowadzenie i edycja danych za wszystkie poprzednie okresy 
			           |do %1 (%2)';
			           |de = 'Es ist verboten, Daten für alle früheren Perioden 
			           |bis %1 einzugeben und zu bearbeiten (%2).';
			           |ro = 'Este interzisă introducerea și editarea datelor pe toate perioadele precedente
			           |până la %1 (%2)';
			           |tr = '
			           | ile %1 arasındaki tüm geçmiş dönemler için veri girişi ve düzenlenmesi yasaklanmıştır (%2)'; 
			           |es_ES = 'Está prohibido introducir y editar los datos de todos los períodos anteriores 
			           |a %1 (%2)'"),
			Format(Context.PeriodEndClosingDate, "DLF=D"), Lower(ClosingDatesDetails()[Context.PeriodEndClosingDateDetails]));
	EndIf;
	
	Context.RelativePeriodEndClosingDateLabelText = LabelText;
	
EndProcedure

Procedure UpdatePeriodEndClosingDateDisplayOnChange(Context) Export
	
	If Not Context.ExtendedModeSelected Then
		
		If Context.PeriodEndClosingDateDetails = "" Or Context.PeriodEndClosingDateDetails = "Custom" Then
			Context.ExtendedModeSelected = False;
			Context.Items.ExtendedMode.Visible = False;
			Context.Items.OperationModesGroup.CurrentPage = Context.Items.SimpleMode;
		Else
			Context.ExtendedModeSelected = True;
			Context.Items.ExtendedMode.Visible = True;
			Context.Items.OperationModesGroup.CurrentPage = Context.Items.ExtendedMode;
		EndIf;
		
	EndIf;
	 
	If Context.PeriodEndClosingDateDetails = "Custom" Then
		Context.Items.PeriodEndClosingDateProperties.CurrentPage = Context.Items.NoDetails;
		Context.Items.Custom.CurrentPage = Context.Items.CustomDateUsed;
		Context.EnableDataChangeBeforePeriodEndClosingDate = False;
		Return;
	EndIf;
	
	If Context.PeriodEndClosingDateDetails = "" Then
		Context.Items.PeriodEndClosingDateProperties.CurrentPage = Context.Items.NoDetails;
		Context.Items.Custom.CurrentPage = Context.Items.CustomDateNotUsed;
		Context.EnableDataChangeBeforePeriodEndClosingDate = False;
		Return;
	EndIf;
	
	Context.Items.PeriodEndClosingDateProperties.CurrentPage = Context.Items.RelativeDate;
	Context.Items.Custom.CurrentPage = Context.Items.CustomDateNotUsed;
	
	If Context.PeriodEndClosingDateDetails = "PreviousDay" Then
		Context.Items.EnableDataChangeBeforePeriodEndClosingDate.Enabled = False;
		Context.EnableDataChangeBeforePeriodEndClosingDate = False;
	Else
		Context.Items.EnableDataChangeBeforePeriodEndClosingDate.Enabled = True;
	EndIf;
	
	Context.Items.PermissionDaysCount.Enabled = Context.EnableDataChangeBeforePeriodEndClosingDate;
	Context.Items.NoncustomDateNote.Title = Context.RelativePeriodEndClosingDateLabelText;
	
EndProcedure

Function PeriodEndClosingDateCalculation(Val PeriodEndClosingDateOption, Val CurrentDateAtServer)
	
	Days = 60*60*24;
	
	CurrentPeriodEndClosingDate    = '00010101';
	PreviousPeriodEndClosingDate = '00010101';
	
	If PeriodEndClosingDateOption = "EndOfLastYear" Then
		CurrentPeriodEndClosingDate    = BegOfYear(CurrentDateAtServer) - Days;
		PreviousPeriodEndClosingDate = BegOfYear(CurrentPeriodEndClosingDate)   - Days;
		
	ElsIf PeriodEndClosingDateOption = "EndOfLastQuarter" Then
		CurrentPeriodEndClosingDate    = BegOfQuarter(CurrentDateAtServer) - Days;
		PreviousPeriodEndClosingDate = BegOfQuarter(CurrentPeriodEndClosingDate)   - Days;
		
	ElsIf PeriodEndClosingDateOption = "EndOfLastMonth" Then
		CurrentPeriodEndClosingDate    = BegOfMonth(CurrentDateAtServer) - Days;
		PreviousPeriodEndClosingDate = BegOfMonth(CurrentPeriodEndClosingDate)   - Days;
		
	ElsIf PeriodEndClosingDateOption = "EndOfLastWeek" Then
		CurrentPeriodEndClosingDate    = BegOfWeek(CurrentDateAtServer) - Days;
		PreviousPeriodEndClosingDate = BegOfWeek(CurrentPeriodEndClosingDate)   - Days;
		
	ElsIf PeriodEndClosingDateOption = "PreviousDay" Then
		CurrentPeriodEndClosingDate    = BegOfDay(CurrentDateAtServer) - Days;
		PreviousPeriodEndClosingDate = BegOfDay(CurrentPeriodEndClosingDate)   - Days;
	EndIf;
	
	Return New Structure("Current, Previous", CurrentPeriodEndClosingDate, PreviousPeriodEndClosingDate);
	
EndFunction

Procedure AdjustPermissionDaysCount(Val PeriodEndClosingDateDetails, PermissionDaysCount)
	
	If PermissionDaysCount = 0 Then
		PermissionDaysCount = 1;
		
	ElsIf PeriodEndClosingDateDetails = "EndOfLastYear" Then
		If PermissionDaysCount > 90 Then
			PermissionDaysCount = 90;
		EndIf;
		
	ElsIf PeriodEndClosingDateDetails = "EndOfLastQuarter" Then
		If PermissionDaysCount > 60 Then
			PermissionDaysCount = 60;
		EndIf;
		
	ElsIf PeriodEndClosingDateDetails = "EndOfLastMonth" Then
		If PermissionDaysCount > 25 Then
			PermissionDaysCount = 25;
		EndIf;
		
	ElsIf PeriodEndClosingDateDetails = "EndOfLastWeek" Then
		If PermissionDaysCount > 5 Then
			PermissionDaysCount = 5;
		EndIf;
		
	EndIf;
	
EndProcedure

#EndRegion
