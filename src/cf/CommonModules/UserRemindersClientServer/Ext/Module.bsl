///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Public

// Returns the annual schedule for the event as of the specified date.
//
// Parameters:
//  EventDate - Date - an arbitrary date.
//
// Returns:
//  JobSchedule - a schedule.
//
Function AnnualSchedule(EventDate) Export
	Months = New Array;
	Months.Add(Month(EventDate));
	DayInMonth = Day(EventDate);
	
	Schedule = New JobSchedule;
	Schedule.DaysRepeatPeriod = 1;
	Schedule.WeeksPeriod = 1;
	Schedule.Months = Months;
	Schedule.DayInMonth = DayInMonth;
	Schedule.BeginTime = '000101010000' + (EventDate - BegOfDay(EventDate));
	
	Return Schedule;
EndFunction

#EndRegion

#Region Private

// Returns a text presentation of a time interval specified in seconds.
//
// Parameters:
//
//  Time - Number - a time interval in seconds.
//
//  FullPresentation	- Boolean - a short or full time presentation.
//		For example, interval of 1,000,000 seconds:
//		- Full presentation:  11 days 13 hours 46 minutes 40 seconds.
//		- Short presentation: 11 days 13 hours.
//
// Returns:
//   String - a time period presentation.
//
Function TimePresentation(Val Time, FullPresentation = True, OutputSeconds = True) Export
	Result = "";
	
	// Presentation of time units of measure in Accusative for quantities: 1, 2-4, 5-20.
	WeeksPresentation = NStr("ru = ';%1 неделю;;%1 недели;%1 недель;%1 недели'; en = ';%1 week;;;;%1 weeks'; pl = ';%1 tydzień;;%1 tygodnie;%1 tygodnie;%1 tygodnia';de = ';%1 Woche ;;%1 Wochen;%1 Wochen;%1 Wochen';ro = ';%1 săptămână;;%1 săptămâni;%1 săptămâni;%1 săptămâni';tr = ';%1 hafta;;%1 hafta;%1 hafta;%1 haftalar'; es_ES = ';%1 semana;;%1 semanas;%1 semanas;%1 semanas'");
	DaysPresentation   = NStr("ru = ';%1 день;;%1 дня;%1 дней;%1 дня'; en = ';%1 day;;;;%1 days'; pl = ';%1 dzień;;%1 dnia;%1 dni;%1 dnia';de = ';%1 Tag;;%1 Tag;%1 Tage;%1 Tag';ro = ';%1 zi;;%1 zile;%1 zile;%1 zile';tr = ';%1 gün;;%1 gün;%1 gün;%1 gün'; es_ES = ';%1 día;;%1 días;%1 días;%1 días'");
	HoursPresentation  = NStr("ru = ';%1 час;;%1 часа;%1 часов;%1 часа'; en = ';%1 hour;;;;%1 hours'; pl = ';%1 godzina;;%1 godziny;%1 godzin;%1 godzin';de = ';%1 Stunde;;%1 Stunden;%1 Stunden;%1 Stunden';ro = ';%1 oră;;%1 ore;%1 ore;%1 ore';tr = ';%1 saat;;%1 saat;%1 saat;%1 saat'; es_ES = ';%1 hora;;%1 horas;%1 horas;%1 horas'");
	MinutesPresentation  = NStr("ru = ';%1 минуту;;%1 минуты;%1 минут;%1 минуты'; en = ';%1 minute;;;;%1 minutes'; pl = ';%1 minutę;;%1 minuty;%1 minut;%1 minuty';de = ';%1 Minute;;%1 Minuten;%1 Minuten;%1 Minuten';ro = ';%1 minut;;%1 minute;%1 minute;%1 minute';tr = ';%1 dakika;;%1 dakika;%1 dakika;%1 dakika'; es_ES = ';%1 minuto;;%1 minutos;%1 minutos;%1 minutos'");
	SecondsPresentation = NStr("ru = ';%1 секунду;;%1 секунды;%1 секунд;%1 секунды'; en = ';%1 second;;;;%1 seconds'; pl = ';%1 sekundę;%1 sekundy;%1 sekund;%1 sekundy';de = ';%1 Sekunde;;%1 Sekunden;%1 Sekunden;%1 Sekunden';ro = ';%1 secundă;;%1 secunde;%1 secunde;%1 secunde';tr = ';%1 saniye;;%1 saniye;%1 saniye;%1 saniye'; es_ES = ';%1 segundo;;%1 segundos;%1 segundos;%1 segundos'");
	
	Time = Number(Time);
	
	If Time < 0 Then
		Time = -Time;
	EndIf;
	
	WeeksCount = Int(Time / 60/60/24/7);
	DaysCount   = Int(Time / 60/60/24);
	HoursCount  = Int(Time / 60/60);
	MinutesCount  = Int(Time / 60);
	SecondsCount = Int(Time);
	
	SecondsCount = SecondsCount - MinutesCount * 60;
	MinutesCount  = MinutesCount - HoursCount * 60;
	HoursCount  = HoursCount - DaysCount * 24;
	DaysCount   = DaysCount - WeeksCount * 7;
	
	If Not OutputSeconds Then
		SecondsCount = 0;
	EndIf;
	
	If WeeksCount > 0 AND DaysCount+HoursCount+MinutesCount+SecondsCount=0 Then
		Result = StringFunctionsClientServer.StringWithNumberForAnyLanguage(WeeksPresentation, WeeksCount);
	Else
		DaysCount = DaysCount + WeeksCount * 7;
		
		Counter = 0;
		If DaysCount > 0 Then
			Result = Result + StringFunctionsClientServer.StringWithNumberForAnyLanguage(DaysPresentation, DaysCount) + " ";
			Counter = Counter + 1;
		EndIf;
		
		If HoursCount > 0 Then
			Result = Result + StringFunctionsClientServer.StringWithNumberForAnyLanguage(HoursPresentation, HoursCount) + " ";
			Counter = Counter + 1;
		EndIf;
		
		If (FullPresentation Or Counter < 2) AND MinutesCount > 0 Then
			Result = Result + StringFunctionsClientServer.StringWithNumberForAnyLanguage(MinutesPresentation, MinutesCount) + " ";
			Counter = Counter + 1;
		EndIf;
		
		If (FullPresentation Or Counter < 2) AND (SecondsCount > 0 Or WeeksCount+DaysCount+HoursCount+MinutesCount = 0) Then
			Result = Result + StringFunctionsClientServer.StringWithNumberForAnyLanguage(SecondsPresentation, SecondsCount);
		EndIf;
		
	EndIf;
	
	Return TrimR(Result);
	
EndFunction

// Gets a time interval in seconds from text details.
//
// Parameters:
//  StringWithTime - String - text details of time, where numbers are written in digits and units of 
//								measure are written as a string.
//
// Returns
//  Number - a time interval in seconds.
Function GetTimeIntervalFromString(Val StringWithTime) Export
	
	If IsBlankString(StringWithTime) Then
		Return 0;
	EndIf;
	
	StringWithTime = Lower(StringWithTime);
	StringWithTime = StrReplace(StringWithTime, Chars.NBSp," ");
	StringWithTime = StrReplace(StringWithTime, ".",",");
	StringWithTime = StrReplace(StringWithTime, "+","");
	
	SubstringWithDigits = "";
	SubstringWithLetters = "";
	
	PreviousCharacterIsDigit = False;
	HasFraction = False;
	
	Result = 0;
	For Position = 1 To StrLen(StringWithTime) Do
		CurrentCharCode = CharCode(StringWithTime,Position);
		Char = Mid(StringWithTime,Position,1);
		If (CurrentCharCode >= CharCode("0") AND CurrentCharCode <= CharCode("9"))
			OR (Char="," AND PreviousCharacterIsDigit AND Not HasFraction) Then
			If Not IsBlankString(SubstringWithLetters) Then
				SubstringWithDigits = StrReplace(SubstringWithDigits,",",".");
				Result = Result + ?(IsBlankString(SubstringWithDigits), 1, Number(SubstringWithDigits))
					* ReplaceUnitOfMeasureByMultiplier(SubstringWithLetters);
					
				SubstringWithDigits = "";
				SubstringWithLetters = "";
				
				PreviousCharacterIsDigit = False;
				HasFraction = False;
			EndIf;
			
			SubstringWithDigits = SubstringWithDigits + Mid(StringWithTime,Position,1);
			
			PreviousCharacterIsDigit = True;
			If Char = "," Then
				HasFraction = True;
			EndIf;
		Else
			If Char = " " AND ReplaceUnitOfMeasureByMultiplier(SubstringWithLetters) = "0" Then
				SubstringWithLetters = "";
			EndIf;
			
			SubstringWithLetters = SubstringWithLetters + Mid(StringWithTime,Position,1);
			PreviousCharacterIsDigit = False;
		EndIf;
	EndDo;
	
	If Not IsBlankString(SubstringWithLetters) Then
		SubstringWithDigits = StrReplace(SubstringWithDigits,",",".");
		Result = Result + ?(IsBlankString(SubstringWithDigits), 1, Number(SubstringWithDigits))
			* ReplaceUnitOfMeasureByMultiplier(SubstringWithLetters);
	EndIf;
	
	Return Result;
	
EndFunction

// Analyzes the word for compliance with the time unit of measure and if it complies, the function 
// returns the number of seconds contained in the time unit of measure.
//
// Parameters:
//  Unit - String - a word being analyzed.
//
// Returns
//  Number - a number of seconds in the Unit. If the unit is undefined or blank, 0 returns.
//
Function ReplaceUnitOfMeasureByMultiplier(Val Unit)
	
	Result = 0;
	Unit = Lower(Unit);
	
	AllowedChars = NStr("ru = 'абвгдеёжзийклмнопрстуфхцчшщъыьэюя'; en = 'abcdefghijklmnopqrstuvwxyz'; pl = 'abcdefghijklmnopqrstuvwxyz';de = 'abcdefghijklmnopqrstuvwxyz';ro = 'abcdefghijklmnopqrstuvwxyz';tr = 'abcdefghijklmnopqrstuvwxyz'; es_ES = 'abcdefghijklmnopqrstuvwxyz'");
	ProhibitedChars = StrConcat(StrSplit(Unit, AllowedChars, False), "");
	If ProhibitedChars <> "" Then
		Unit = StrConcat(StrSplit(Unit, ProhibitedChars, False), "");
	EndIf;
	
	WordFormsForWeek = StrSplit(NStr("ru = 'нед,н'; en = 'wee,wk,w'; pl = 'maleńki,m';de = 'wee,w';ro = 'wee,w';tr = 'wee,w'; es_ES = 'wee,w'"), ",", False);
	WordFormsForDay = StrSplit(NStr("ru = 'ден,дне,дня,дн,д'; en = 'day,d'; pl = 'dzień,dzień,dzień,dzień,d';de = 'Tag,Tag,Tag,Tag,d';ro = 'zi,zi,zi,zi,z';tr = 'gün,gün,gün,gün,g'; es_ES = 'day,day,day,day,d'"), ",", False);
	WordFormsForHour = StrSplit(NStr("ru = 'час,ч'; en = 'hou,hr,h'; pl = 'godz,g';de = 'hou,h';ro = 'ora,h';tr = 'hou(saat),h'; es_ES = 'hou,h'"), ",", False);
	WordFormsForMinute = StrSplit(NStr("ru = 'мин,м'; en = 'min,m'; pl = 'min,m';de = 'min,m';ro = 'min,m';tr = 'min (dakika),m'; es_ES = 'min,m'"), ",", False);
	WordFormsForSecond = StrSplit(NStr("ru = 'сек,с'; en = 'sec,s'; pl = 'sek,s';de = 'sec,s';ro = 'sec,s';tr = 'sec(saniye),s'; es_ES = 'sec,s'"), ",", False);
	
	FirstThreeChars = Left(Unit,3);
	If WordFormsForWeek.Find(FirstThreeChars) <> Undefined Then
		Result = 60*60*24*7;
	ElsIf WordFormsForDay.Find(FirstThreeChars) <> Undefined Then
		Result = 60*60*24;
	ElsIf WordFormsForHour.Find(FirstThreeChars) <> Undefined Then
		Result = 60*60;
	ElsIf WordFormsForMinute.Find(FirstThreeChars) <> Undefined Then
		Result = 60;
	ElsIf WordFormsForSecond.Find(FirstThreeChars) <> Undefined Then
		Result = 1;
	EndIf;
	
	Return Format(Result,"NZ=0; NG=0");
	
EndFunction

// Gets a time interval from a string and returns its text presentation.
//
// Parameters:
//  TimeAsString - String - text details of time, where numbers are written in digits and units of 
//							measure are written as a string.
//
// Returns
//  String - an arranged time presentation.
Function ApplyAppearanceTime(TimeAsString) Export
	Return TimePresentation(GetTimeIntervalFromString(TimeAsString));
EndFunction

// Returns the reminder structure with filled values.
//
// Parameters:
//  DataToFill - Structure - values used to fill reminder parameters.
//  AllAttributes - Boolean - if true, the function also returns attributes related to reminder time 
//                          settings.
Function ReminderDetails(DataToFill = Undefined, AllAttributes = False) Export
	Result = New Structure("User,EventTime,Source,ReminderTime,Details,ID");
	If AllAttributes Then 
		Result.Insert("ReminderTimeSettingMethod");
		Result.Insert("ReminderInterval", 0);
		Result.Insert("SourceAttributeName");
		Result.Insert("Schedule");
		Result.Insert("PictureIndex", 2);
		Result.Insert("RepeatAnnually", False);
	EndIf;
	If DataToFill <> Undefined Then
		FillPropertyValues(Result, DataToFill);
	EndIf;
	Return Result;
EndFunction

#EndRegion
