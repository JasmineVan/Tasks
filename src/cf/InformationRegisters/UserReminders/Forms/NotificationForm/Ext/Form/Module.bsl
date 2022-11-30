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
	
	If Common.IsWebClient() Then
		WindowOpeningMode = FormWindowOpeningMode.LockOwnerWindow;
	EndIf;
	
	If Common.IsMobileClient() Then
		Items.RepeatedNotificationPeriod.Visible = False;
		Items.SnoozeButton.Title = NStr("ru = 'Отложить'; en = 'Snooze'; pl = 'Odłożyć';de = 'Verschieben';ro = 'Amânare';tr = 'Ayırmak'; es_ES = 'Aplazar'");
		Items.SnoozeButton.DefaultButton = True;
		Items.OpenButton.OnlyInAllActions = True;
		Items.StopButton.OnlyInAllActions = True;
	EndIf;
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	FillRepeatedReminderPeriod();
	RepeatedNotificationPeriod = "15borough";
	RepeatedNotificationPeriod = UserRemindersClientServer.ApplyAppearanceTime(RepeatedNotificationPeriod);
	UpdateRemindersTable();
	UpdateTimeInRemindersTable();
	Activate();
EndProcedure

&AtClient
Procedure OnReopen()
	UpdateRemindersTable();
	UpdateTimeInRemindersTable();
	ThisObject.CurrentItem = Items.RepeatedNotificationPeriod;
	Activate();
EndProcedure

&AtClient
Procedure OnClose(Exit)
	
	If Exit Then
		Return;
	EndIf;
	
	DeferActiveReminders();
	UserRemindersClient.ResetCurrentNotificationsCheckTimer();
	
	// Forced disabling of handlers is necessary as the form is not exported from the memory.
	DetachIdleHandler("UpdateRemindersTable");
	DetachIdleHandler("UpdateTimeInRemindersTable");
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure RepeatedNotificationPeriodOnChange(Item)
	RepeatedNotificationPeriod = UserRemindersClientServer.ApplyAppearanceTime(RepeatedNotificationPeriod);
EndProcedure

#EndRegion

#Region ReminderFormTableItemsEventHandlers

&AtClient
Procedure RemindersSelection(Item, RowSelected, Field, StandardProcessing)
	OpenReminder();
EndProcedure

&AtClient
Procedure RemindersOnActivateRow(Item)
	
	If Item.CurrentData = Undefined Then
		Return;
	EndIf;
		
	Source = Item.CurrentData.Source;
	
	HasSource = ValueIsFilled(Source);
	Items.RemindersContextMenuOpen.Enabled = HasSource;
	
EndProcedure

#EndRegion

#Region FormCommandHandlers

&AtClient
Procedure Change(Command)
	EditReminder();
EndProcedure

&AtClient
Procedure OpenCommand(Command)
	OpenReminder();
EndProcedure

&AtClient
Procedure Defer(Command)
	DeferActiveReminders();
EndProcedure

&AtClient
Procedure Stop(Command)
	If Items.Reminders.CurrentData = Undefined Then
		Return;
	EndIf;
	
	For Each RowIndex In Items.Reminders.SelectedRows Do
		RowData = Reminders.FindByID(RowIndex);
	
		ReminderParameters = UserRemindersClientServer.ReminderDetails(RowData);
		
		DisableReminder(ReminderParameters);
		UserRemindersClient.DeleteRecordFromNotificationsCache(RowData);
	EndDo;
	
	NotifyChanged(Type("InformationRegisterRecordKey.UserReminders"));
	
	UpdateRemindersTable();
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure AttachReminder(ReminderParameters)
	UserRemindersInternal.AttachReminder(ReminderParameters, True);
EndProcedure

&AtServer
Procedure DisableReminder(ReminderParameters)
	UserRemindersInternal.DisableReminder(ReminderParameters);
EndProcedure

&AtClient
Procedure UpdateRemindersTable() 

	DetachIdleHandler("UpdateRemindersTable");
	
	TimeOfClosest = Undefined;
	RemindersTable = UserRemindersClient.GetCurrentNotifications(TimeOfClosest);
	For Each Reminder In RemindersTable Do
		FoundRows = Reminders.FindRows(New Structure("Source,EventTime", Reminder.Source, Reminder.EventTime));
		If FoundRows.Count() > 0 Then
			FillPropertyValues(FoundRows[0], Reminder, , "ReminderTime");
		Else
			NewRow = Reminders.Add();
			FillPropertyValues(NewRow, Reminder);
		EndIf;
	EndDo;
	
	RowsToDelete = New Array;
	For Each Reminder In Reminders Do
		If ValueIsFilled(Reminder.Source) AND IsBlankString(Reminder.SourceAsString) Then
			UpdateSubjectsPresentations();
		EndIf;
			
		RowFound = False;
		For Each CacheRow In RemindersTable Do
			If CacheRow.Source = Reminder.Source AND CacheRow.EventTime = Reminder.EventTime Then
				RowFound = True;
				Break;
			EndIf;
		EndDo;
		If Not RowFound Then 
			RowsToDelete.Add(Reminder);
		EndIf;
	EndDo;
	
	For Each Row In RowsToDelete Do
		Reminders.Delete(Row);
	EndDo;
	
	SetVisibility();
	
	Interval = 15; // Update the table not less than once in 15 seconds.
	If TimeOfClosest <> Undefined Then 
		Interval = Max(Min(Interval, TimeOfClosest - CommonClient.SessionDate()), 1); 
	EndIf;
	
	AttachIdleHandler("UpdateRemindersTable", Interval, True);
	
EndProcedure

&AtServer
Procedure UpdateSubjectsPresentations()
	
	For Each Reminder In Reminders Do
		If ValueIsFilled(Reminder.Source) Then
			Reminder.SourceAsString = Common.SubjectString(Reminder.Source);
		EndIf;
	EndDo;
	
EndProcedure

&AtClient
Function ModuleNumbers(Number)
	If Number >= 0 Then
		Return Number;
	Else
		Return -Number;
	EndIf;
EndFunction

&AtClient
Procedure UpdateTimeInRemindersTable()
	DetachIdleHandler("UpdateTimeInRemindersTable");
	
	For Each TableRow In Reminders Do
		TimePresentation = NStr("ru = 'срок не определен'; en = 'n/a'; pl = 'nie określono terminu';de = 'Deadline ist nicht festgelegt';ro = 'termenul nu este stabilit';tr = 'son tarih belirlenmedi'; es_ES = 'fecha límite no está establecida'");
		
		If ValueIsFilled(TableRow.EventTime) Then
			CurrentDate = CommonClient.SessionDate();
			Time = CurrentDate - TableRow.EventTime;
			If TableRow.EventTime - BegOfDay(TableRow.EventTime) < 60 // Events for the whole day.
				AND BegOfDay(TableRow.EventTime) = BegOfDay(CurrentDate) Then
					TimePresentation = NStr("ru = 'сегодня'; en = 'today'; pl = 'dzisiaj';de = 'Heute';ro = 'astăzi';tr = 'bugün'; es_ES = 'hoy'");
			Else
				If ModuleNumbers(Time) > 60*60*24 Then
					Time = BegOfDay(CommonClient.SessionDate()) - BegOfDay(TableRow.EventTime);
				EndIf;
				TimePresentation = TimeIntervalPresentation(Time);
			EndIf;
		EndIf;
		
		If TableRow.EventTimeString <> TimePresentation Then
			TableRow.EventTimeString = TimePresentation;
		EndIf;
		
	EndDo;
	
	AttachIdleHandler("UpdateTimeInRemindersTable", 5, True);
EndProcedure

&AtClient
Procedure DeferActiveReminders()
	TimeInterval = UserRemindersClientServer.GetTimeIntervalFromString(RepeatedNotificationPeriod);
	If TimeInterval = 0 Then
		TimeInterval = 5*60; // 5 minutes.
	EndIf;
	For Each TableRow In Reminders Do
		TableRow.ReminderTime = CommonClient.SessionDate() + TimeInterval;
		
		ReminderParameters = UserRemindersClientServer.ReminderDetails(TableRow);
		
		AttachReminder(ReminderParameters);
		UserRemindersClient.UpdateRecordInNotificationsCache(TableRow);
	EndDo;
	UpdateRemindersTable();
EndProcedure

&AtClient
Procedure OpenReminder()
	If Items.Reminders.CurrentData = Undefined Then
		Return;
	EndIf;
	Source = Items.Reminders.CurrentData.Source;
	If ValueIsFilled(Source) Then
		ShowValue(, Source);
	Else
		EditReminder();
	EndIf;
EndProcedure

&AtClient
Procedure EditReminder()
	ReminderParameters = New Structure("User,Source,EventTime");
	FillPropertyValues(ReminderParameters, Items.Reminders.CurrentData);
	
	OpenForm("InformationRegister.UserReminders.Form.Reminder", New Structure("Key", GetRecordKey(ReminderParameters)));
EndProcedure

&AtServer
Function GetRecordKey(ReminderParameters)
	Return InformationRegisters.UserReminders.CreateRecordKey(ReminderParameters);
EndFunction

&AtClient
Procedure SetVisibility()
	HasTableData = Reminders.Count() > 0;
	
	If Not HasTableData AND ThisObject.IsOpen() Then
		ThisObject.Close();
	EndIf;
	
	Items.ButtonsPanel.Enabled = HasTableData;
EndProcedure

&AtClient
Procedure FillRepeatedReminderPeriod()
	For Each Item In Items.RepeatedNotificationPeriod.ChoiceList Do
		Item.Presentation = UserRemindersClientServer.ApplyAppearanceTime(Item.Value); 
	EndDo;
EndProcedure	

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	If EventName = "Write_UserReminders" Then 
		UpdateRemindersTable();
	EndIf;
EndProcedure

&AtClient
Function TimeIntervalPresentation(Val TimeCount)
	Result = "";
	
	WeeksPresentation = NStr("ru = ';%1 неделю;;%1 недели;%1 недель;%1 недели'; en = ';%1 week;;;;%1 weeks'; pl = ';%1 tydzień;;%1 tygodnie;%1 tygodnie;%1 tygodnia';de = ';%1 Woche ;;%1 Wochen;%1 Wochen;%1 Wochen';ro = ';%1 săptămână;;%1 săptămâni;%1 săptămâni;%1 săptămâni';tr = ';%1 hafta;;%1 hafta;%1 hafta;%1 haftalar'; es_ES = ';%1 semana;;%1 semanas;%1 semanas;%1 semanas'");
	DaysPresentation   = NStr("ru = ';%1 день;;%1 дня;%1 дней;%1 дня'; en = ';%1 day;;;;%1 days'; pl = ';%1 dzień;;%1 dnia;%1 dni;%1 dnia';de = ';%1 Tag;;%1 Tag;%1 Tage;%1 Tag';ro = ';%1 zi;;%1 zile;%1 zile;%1 zile';tr = ';%1 gün;;%1 gün;%1 gün;%1 gün'; es_ES = ';%1 día;;%1 días;%1 días;%1 días'");
	HoursPresentation  = NStr("ru = ';%1 час;;%1 часа;%1 часов;%1 часа'; en = ';%1 hour;;;;%1 hours'; pl = ';%1 godzina;;%1 godziny;%1 godzin;%1 godzin';de = ';%1 Stunde;;%1 Stunden;%1 Stunden;%1 Stunden';ro = ';%1 oră;;%1 ore;%1 ore;%1 ore';tr = ';%1 saat;;%1 saat;%1 saat;%1 saat'; es_ES = ';%1 hora;;%1 horas;%1 horas;%1 horas'");
	MinutesPresentation  = NStr("ru = ';%1 минуту;;%1 минуты;%1 минут;%1 минуты'; en = ';%1 minute;;;;%1 minutes'; pl = ';%1 minutę;;%1 minuty;%1 minut;%1 minuty';de = ';%1 Minute;;%1 Minuten;%1 Minuten;%1 Minuten';ro = ';%1 minut;;%1 minute;%1 minute;%1 minute';tr = ';%1 dakika;;%1 dakika;%1 dakika;%1 dakika'; es_ES = ';%1 minuto;;%1 minutos;%1 minutos;%1 minutos'");
	
	TimeCount = Number(TimeCount);
	CurrentDate = CommonClient.SessionDate();
	
	EventCame = True;
	TodayEvent = BegOfDay(CurrentDate - TimeCount) = BegOfDay(CurrentDate);
	PresentationTemplate = NStr("ru = '%1 назад'; en = '%1 before'; pl = '%1 wróć';de = '%1 zurück';ro = '%1 înapoi';tr = '%1 geri'; es_ES = '%1 atrás'");
	If TimeCount < 0 Then
		PresentationTemplate = NStr("ru = 'через %1'; en = 'in %1'; pl = 'w %1';de = 'in %1';ro = 'în %1';tr = '%1'' de'; es_ES = 'en %1'");
		TimeCount = -TimeCount;
		EventCame = False;
	EndIf;
	
	WeeksCount = Int(TimeCount / 60/60/24/7);
	DaysCount   = Int(TimeCount / 60/60/24);
	HoursCount  = Int(TimeCount / 60/60);
	MinutesCount  = Int(TimeCount / 60);
	SecondsCount = Int(TimeCount);
	
	SecondsCount = SecondsCount - MinutesCount * 60;
	MinutesCount  = MinutesCount - HoursCount * 60;
	HoursCount  = HoursCount - DaysCount * 24;
	DaysCount   = DaysCount - WeeksCount * 7;
	
	If WeeksCount > 4 Then
		If EventCame Then
			Return NStr("ru = 'очень давно'; en = 'long ago'; pl = 'bardzo dawno';de = 'vor langer Zeit';ro = 'cu mult timp în urmă';tr = 'uzun süre önce'; es_ES = 'hace mucho tiempo'");
		Else
			Return NStr("ru = 'еще не скоро'; en = 'a long way from now'; pl = 'nieprędko';de = 'nicht bald';ro = 'nu curând';tr = 'yakın değil'; es_ES = 'no pronto'");
		EndIf;
		
	ElsIf WeeksCount > 1 Then
		Result = StringFunctionsClientServer.StringWithNumberForAnyLanguage(WeeksPresentation, WeeksCount);
	ElsIf WeeksCount > 0 Then
		Result = NStr("ru = 'неделю'; en = 'a week'; pl = 'tydzień';de = 'woche';ro = 'săptămână';tr = 'hafta'; es_ES = 'semana'");
		
	ElsIf DaysCount > 1 Then
		If BegOfDay(CurrentDate) - BegOfDay(CurrentDate - TimeCount) = 60*60*24 * 2 Then
			If EventCame Then
				Return NStr("ru = 'позавчера'; en = 'the day before yesterday'; pl = 'przedwczoraj';de = 'vorgestern';ro = 'alaltăieri';tr = 'dünden önceki gün'; es_ES = 'anteayer'");
			Else
				Return NStr("ru = 'послезавтра'; en = 'the day after tomorrow'; pl = 'pojutrze';de = 'übermorgen';ro = 'poimâine';tr = 'yarından sonraki gün'; es_ES = 'pasado mañana'");
			EndIf;
		Else
			Result = StringFunctionsClientServer.StringWithNumberForAnyLanguage(DaysPresentation, DaysCount);
		EndIf;
	ElsIf HoursCount + DaysCount * 24 > 3 AND Not TodayEvent Then
			If EventCame Then
				Return NStr("ru = 'вчера'; en = 'yesterday'; pl = 'wczoraj';de = 'gestern';ro = 'ieri';tr = 'dün'; es_ES = 'ayer'");
			Else
				Return NStr("ru = 'завтра'; en = 'tomorrow'; pl = 'jutro';de = 'morgen';ro = 'mâine';tr = 'yarın'; es_ES = 'mañana'");
			EndIf;
	ElsIf DaysCount > 0 Then
		Result = NStr("ru = 'день'; en = 'a day'; pl = 'dzień';de = 'tag';ro = 'zi';tr = 'gün'; es_ES = 'día'");
	ElsIf HoursCount > 1 Then
		Result = StringFunctionsClientServer.StringWithNumberForAnyLanguage(HoursPresentation, HoursCount);
	ElsIf HoursCount > 0 Then
		Result = NStr("ru = 'час'; en = 'an hour'; pl = 'godzina';de = 'Stunde';ro = 'oră';tr = 'saat'; es_ES = 'hora'");
		
	ElsIf MinutesCount > 1 Then
		Result = StringFunctionsClientServer.StringWithNumberForAnyLanguage(MinutesPresentation, MinutesCount);
	ElsIf MinutesCount > 0 Then
		Result = NStr("ru = 'минуту'; en = 'a minute'; pl = 'minuta';de = 'Minute';ro = 'minut';tr = 'dakika'; es_ES = 'minuto'");
		
	Else
		Return NStr("ru = 'сейчас'; en = 'now'; pl = 'teraz';de = 'jetzt';ro = 'acum';tr = 'şimdi'; es_ES = 'ahora'");
	EndIf;
	
	Result = StringFunctionsClientServer.SubstituteParametersToString(PresentationTemplate, Result);
	
	Return Result;
EndFunction

#EndRegion
