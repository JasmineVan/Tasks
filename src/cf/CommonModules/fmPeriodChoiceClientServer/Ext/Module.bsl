
////////////////////////////////////////////////////////////////////////////////
// Функции и процедуры обеспечения выбора периода.
//  
////////////////////////////////////////////////////////////////////////////////

#Region ProgramInterface

// Заполняет переданный в параметрах список выбора. 
// 
// Параметры: 
// МинимальныйПериод   - Перечисление.уфДоступныеПериодыОтчета - минимальный вид периода, 
//                       начиная с которого необходимо включать остальные виды периода по возрастанию.
// СписокВыбора        - СписокЗначений - в списке возвращаются заполненный список выбора
// ЗначениеПоУмолчанию - Перечисление.уфДоступныеПериодыОтчета - в параметре возвращает вид периода по умолчанию.
//
Procedure FillChoiceListPeriodType(VAL MinimumPeriod, ChoiceList, DefaultValue = Undefined) Export
	
	If TypeOf(ChoiceList) <> Type("ValueList") Then
		Return;
	EndIf;
	
	AvailablePeriodList = GetAvailablePeriodList();
	
	ListItem = AvailablePeriodList.FindByValue(MinimumPeriod);
	If ListItem <> Undefined Then
		ItemIndex = AvailablePeriodList.IndexOf(ListItem);
		For Counter = ItemIndex To AvailablePeriodList.Count() - 1 Do
			Period = AvailablePeriodList.Get(Counter);
			ChoiceList.Add(Period.Value, Period.Presentation);
		EndDo;
		If NOT ValueIsFilled(DefaultValue) Then
			DefaultValue = PredefinedValue("Enum.fmAvailableReportPeriods.ArbitraryPeriod");
		EndIf;
	Else
		Return; 
	EndIf;
	
EndProcedure

// Возвращает дату начала переданного вида периода, сам период определяется по переданной дате.
//
// Параметры:
//   ВидПериода – ПеречислениеСсылка.уфДоступныеПериодыОтчета - Вид периода.
//   ДатаПериода - Дата - Дата, принадлежащая периоду.
//
// Возвращаемое значение:
//   Дата - Дата начала периода.
//
Function ReportBegOfPeriod(PeriodType, PeriodDate) Export
	
	BeginOfPeriod = PeriodDate;
	
	If PeriodType = PredefinedValue("Enum.fmAvailableReportPeriods.Year") Then
		BeginOfPeriod = BegOfYear(PeriodDate);
		
	ElsIf PeriodType = PredefinedValue("Enum.fmAvailableReportPeriods.HalfYear") Then
		If Month(PeriodDate) > 6 Then
			BeginOfPeriod = DATE(Year(PeriodDate), 7, 1);
		Else
			BeginOfPeriod = DATE(Year(PeriodDate), 1, 1);
		EndIf;
		
	ElsIf PeriodType = PredefinedValue("Enum.fmAvailableReportPeriods.Quarter") Then
		BeginOfPeriod = BegOfQuarter(PeriodDate);
		
	ElsIf PeriodType = PredefinedValue("Enum.fmAvailableReportPeriods.Month") Then
		BeginOfPeriod = BegOfMonth(PeriodDate);
		
	ElsIf PeriodType = PredefinedValue("Enum.fmAvailableReportPeriods.TenDays") Then
		If Day(PeriodDate) <= 10 Then
			BeginOfPeriod = DATE(Year(PeriodDate), Month(PeriodDate), 1);
		ElsIf Day(PeriodDate) > 10 AND Day(PeriodDate) <= 20 Then
			BeginOfPeriod = DATE(Year(PeriodDate), Month(PeriodDate), 11);
		Else
			BeginOfPeriod = DATE(Year(PeriodDate), Month(PeriodDate), 21);
		EndIf;
		
	ElsIf PeriodType = PredefinedValue("Enum.fmAvailableReportPeriods.Week") Then
		BeginOfPeriod = BegOfWeek(PeriodDate);
		
	ElsIf PeriodType = PredefinedValue("Enum.fmAvailableReportPeriods.Day") Then
		BeginOfPeriod = BegOfDay(PeriodDate);
		
	EndIf;
		
	Return BeginOfPeriod;
	
EndFunction
 
// Возвращает дату окончания переданного вида периода, сам период определяется по переданной дате.
//
// Параметры:
//   ВидПериода – ПеречислениеСсылка.уфДоступныеПериодыОтчета - Вид периода.
//   ДатаПериода - Дата - Дата, принадлежащая периоду.
//
// Возвращаемое значение:
//   Дата - Дата окончания периода.
//
Function ReportEndOfPeriod(PeriodType, PeriodDate) Export
	
	EndOfPeriod = PeriodDate;
	
	If PeriodType = PredefinedValue("Enum.fmAvailableReportPeriods.Year") Then
		EndOfPeriod = EndOfYear(PeriodDate);
		
	ElsIf PeriodType = PredefinedValue("Enum.fmAvailableReportPeriods.HalfYear") Then
		If Month(PeriodDate) > 6 Then
			EndOfPeriod = EndOfYear(PeriodDate);
		Else
			EndOfPeriod = EndOfDay(DATE(Year(PeriodDate), 6, 30));
		EndIf;
		
	ElsIf PeriodType = PredefinedValue("Enum.fmAvailableReportPeriods.Quarter") Then
		EndOfPeriod = EndOfQuarter(PeriodDate);
		
	ElsIf PeriodType = PredefinedValue("Enum.fmAvailableReportPeriods.Month") Then
		EndOfPeriod = EndOfMonth(PeriodDate);
		
	ElsIf PeriodType = PredefinedValue("Enum.fmAvailableReportPeriods.TenDays") Then
		If Day(PeriodDate) <= 10 Then
			EndOfPeriod = EndOfDay(DATE(Year(PeriodDate), Month(PeriodDate), 10));
		ElsIf Day(PeriodDate) > 10 AND Day(PeriodDate) <= 20 Then
			EndOfPeriod = EndOfDay(DATE(Year(PeriodDate), Month(PeriodDate), 20));
		Else
			EndOfPeriod = EndOfMonth(PeriodDate);
		EndIf;
		
	ElsIf PeriodType = PredefinedValue("Enum.fmAvailableReportPeriods.Week") Then
		EndOfPeriod = EndOfWeek(PeriodDate);
		
	ElsIf PeriodType = PredefinedValue("Enum.fmAvailableReportPeriods.Day") Then
		EndOfPeriod = EndOfDay(PeriodDate);
		
	EndIf;
		
	Return EndOfPeriod;
	
EndFunction

// Возвращает список периодов, список определяется по переданной дате и виду периода.
// 
// Параметры:
//   НачалоПериода - Дата - Дата начала периода.
//   ВидПериода    - ПеречислениеСсылка.уфДоступныеПериодыОтчета - Вид периода.
// 
// Возвращаемое значение:
//   СписокЗначений - Список возможных периодов.
// 
Function GetPeriodList(VAL BeginOfPeriod, VAL PeriodType) Export
	
	PeriodList = New ValueList;
	If BeginOfPeriod = '00010101' Then
		Return New ValueList;
	Else
		BegOfPeriodValue = BeginOfPeriod;
	EndIf;
	
	If PeriodType = PredefinedValue("Enum.fmAvailableReportPeriods.Year") Then
		CurrentYear = Year(BegOfPeriodValue);
		PeriodList.Add(DATE(CurrentYear - 7, 1, 1), NStr("en='Pred. years';ru='Предыдущие года'"));
		For Counter = CurrentYear - 3 To CurrentYear + 3 Do
			PeriodList.Add(DATE(Counter, 1, 1), Format(Counter, "NG=0"));
		EndDo;
		PeriodList.Add(DATE(CurrentYear + 7, 1, 1), NStr("en='Next years';ru='Последующие года'"));
		
	ElsIf PeriodType = PredefinedValue("Enum.fmAvailableReportPeriods.HalfYear") Then
		CurrentYear = Year(BegOfPeriodValue);
		PeriodList.Add(DATE(CurrentYear - 2, 1, 1), Format(CurrentYear - 2, "NG=0") + "...");
		For Counter = CurrentYear - 1 To CurrentYear + 1 Do
			PeriodList.Add(DATE(Counter, 1, 1), StrTemplate(NStr("en='I half year %1';ru='I полугодие %1'"), Format(Counter, "NG=0")));
			PeriodList.Add(DATE(Counter, 7, 1), StrTemplate(NStr("en='II half year %1';ru='II полугодие %1'"), Format(Counter, "NG=0")));
		EndDo;
		PeriodList.Add(DATE(CurrentYear + 2, 1, 1), Format(CurrentYear + 2, "NG=0") + "...");
		
	ElsIf PeriodType = PredefinedValue("Enum.fmAvailableReportPeriods.Quarter") Then
		CurrentYear = Year(BegOfPeriodValue);
		PeriodList.Add(DATE(CurrentYear - 2, 1, 1), Format(CurrentYear - 2, "NG=0") + "...");
		For Counter = CurrentYear - 1 To CurrentYear Do
			PeriodList.Add(DATE(Counter, 1, 1),	 StrTemplate(NStr("en='1st quarter %1';ru='1 квартал %1'"), Format(Counter, "NG=0")));
			PeriodList.Add(DATE(Counter, 4, 1),	 StrTemplate(NStr("en='2nd quarter %1';ru='2 квартал %1'"), Format(Counter, "NG=0")));
			PeriodList.Add(DATE(Counter, 7, 1),	 StrTemplate(NStr("en='3 quarter %1';ru='3 квартал %1'"), Format(Counter, "NG=0")));
			PeriodList.Add(DATE(Counter, 10, 1), StrTemplate(NStr("en='4 quarter %1';ru='4 квартал %1'"), Format(Counter, "NG=0")));
		EndDo;
		PeriodList.Add(DATE(CurrentYear + 1, 1, 1), Format(CurrentYear + 1, "NG=0") + "...");
		
	ElsIf PeriodType = PredefinedValue("Enum.fmAvailableReportPeriods.Month") Then
		CurrentYear = Year(BegOfPeriodValue);
		PeriodList.Add(DATE(CurrentYear - 1, 1, 1), Format(CurrentYear - 1, "NG=0") + "...");
		For Counter = 1 To 12 Do
			PeriodList.Add(DATE(CurrentYear, Counter, 1), Format(DATE(CurrentYear, Counter, 1), "L=en; DF='MMMM yyyy'"));
		EndDo;
		PeriodList.Add(DATE(CurrentYear + 1, 1, 1), Format(CurrentYear + 1, "NG=0") + "...");

	ElsIf PeriodType = PredefinedValue("Enum.fmAvailableReportPeriods.TenDays") Then
		CurrentYear   = Year(BegOfPeriodValue);
		CurrentMonth = Month(BegOfPeriodValue);
		
		MonthCounter = ?(CurrentMonth - 4 < 1, 12 + CurrentMonth - 4, CurrentMonth - 4);
		YearCounter   = ?(CurrentMonth - 4 < 1, CurrentYear - 1       , CurrentYear);
		Counter = 6;
		
		Period = DATE(?(MonthCounter <> 1, YearCounter, YearCounter - 1), ?(MonthCounter > 1, MonthCounter - 1, 12), 1);
		PeriodList.Add(Period, Format(Period, "L=en; DF='MMMM yyyy'") + "...");
		While Counter >0 Do
			PeriodList.Add(DATE(YearCounter, MonthCounter, 1),  StrTemplate(NStr("en='I dec. %1';ru='I дек. %1'"), Lower(Format(DATE(YearCounter, MonthCounter, 1), "DF='MMMM yyyy'"))));
			PeriodList.Add(DATE(YearCounter, MonthCounter, 11), StrTemplate(NStr("en='II dec. %1';ru='II дек. %1'"), Lower(Format(DATE(YearCounter, MonthCounter, 1), "DF='MMMM yyyy'"))));
			PeriodList.Add(DATE(YearCounter, MonthCounter, 21), StrTemplate(NStr("en='III dec. %1';ru='III дек. %1'"), Lower(Format(DATE(YearCounter, MonthCounter, 1), "DF='MMMM yyyy'"))));
			MonthCounter = MonthCounter + 1;
			If MonthCounter > 12 Then
				YearCounter = YearCounter + 1;
				MonthCounter = 1;
			EndIf;
			Counter = Counter - 1;
		EndDo;
		PeriodList.Add(DATE(YearCounter, MonthCounter, 1), Format(DATE(YearCounter, MonthCounter, 1), "L=en; DF='MMMM yyyy'") + "...");
		
	ElsIf PeriodType = PredefinedValue("Enum.fmAvailableReportPeriods.Week") Then
		BegOfWeek = BegOfWeek(BegOfPeriodValue) - 21 * 86400;
		
		PeriodList.Add(BegOfWeek - 7 * 86400, NStr("en='Pred. weeks.....';ru='Пред. недели ...'"));
		For Counter = 0 To 6 Do
			BOfWeek = BegOfWeek + 7 * Counter * 86400;  
			EOfWeek = EndOfWeek(BOfWeek);
			PeriodList.Add(BOfWeek, Format(BOfWeek, "DF=dd.MM") + " - " + Format(EOfWeek, "DF=dd.MM"));
		EndDo;
		PeriodList.Add(BegOfWeek + 7 * 86400, NStr("en='Next weeks....';ru='След. недели ...'"));
		
	ElsIf PeriodType = PredefinedValue("Enum.fmAvailableReportPeriods.Day") Then
		EndOfWeek   = EndOfWeek(BegOfPeriodValue);
		DayOfWeekDate = BegOfWeek(BegOfPeriodValue);
		
		PeriodList.Add(DayOfWeekDate - 86400, NStr("en='Pred. week';ru='Предыдущая неделя'"));
		
		While DayOfWeekDate < EndOfWeek Do
			WDay = WeekDay(DayOfWeekDate);
			
			PeriodList.Add(DayOfWeekDate, Format(DayOfWeekDate, "L=en; DF='dd MMMM yyyy (ddd)'"));
			
			DayOfWeekDate = DayOfWeekDate + 86400;
		EndDo;
		
		PeriodList.Add(EndOfWeek + 1, NStr("en='Next week';ru='Следующая неделя'"));
	EndIf;
		
	Return PeriodList;
	
EndFunction

// Возвращает вид периода по переданным датам начала и окончания этого периода.
// 
// Параметры:
// 	НачалоПериода - Дата - Дата начала периода.
//  КонецПериода  - Дата - Дата окончания периода.
//	МинимальныйВидПериода - Перечисление.уфДоступныеПериодыОтчета - Наименьший доступный вид периода.
// 
// Возвращаемое значение:
//   ПеречислениеСсылка.уфДоступныеПериодыОтчета - Вид периода.
// 
Function GetPeriodType(VAL BeginOfPeriod, VAL EndOfPeriod, VAL MinimumPeriodType = Undefined) Export
	
	PeriodType = PredefinedValue("Enum.fmAvailableReportPeriods.ArbitraryPeriod");
	If ValueIsFilled(BeginOfPeriod) AND ValueIsFilled(EndOfPeriod) Then
		Begin = BegOfDay(BeginOfPeriod);
		END  = EndOfDay(EndOfPeriod);
		If Begin = BegOfDay(BeginOfPeriod) AND END = EndOfDay(BeginOfPeriod) Then
			PeriodType = PredefinedValue("Enum.fmAvailableReportPeriods.Day");
		ElsIf Begin = BegOfWeek(BeginOfPeriod) AND END = EndOfWeek(BeginOfPeriod) Then
			PeriodType = PredefinedValue("Enum.fmAvailableReportPeriods.Week");
		ElsIf Begin = BegOfMonth(BeginOfPeriod) AND END = EndOfMonth(BeginOfPeriod) Then
			PeriodType = PredefinedValue("Enum.fmAvailableReportPeriods.Month");
		ElsIf Begin = BegOfQuarter(BeginOfPeriod) AND END = EndOfQuarter(BeginOfPeriod) Then
			PeriodType = PredefinedValue("Enum.fmAvailableReportPeriods.Quarter");
		ElsIf Begin = BegOfYear(BeginOfPeriod) AND END = EndOfYear(BeginOfPeriod) Then
			PeriodType = PredefinedValue("Enum.fmAvailableReportPeriods.Year");
		ElsIf Begin = DATE(Year(BeginOfPeriod), 1, 1) AND END = DATE(Year(BeginOfPeriod), 6, 30, 23, 59, 59)
			OR Begin = DATE(Year(BeginOfPeriod), 7, 1) AND END = DATE(Year(BeginOfPeriod), 12, 31, 23, 59, 59) Then
			PeriodType = PredefinedValue("Enum.fmAvailableReportPeriods.HalfYear");
		ElsIf Begin = DATE(Year(BeginOfPeriod), Month(BeginOfPeriod), 1) 
			AND END = DATE(Year(BeginOfPeriod), Month(BeginOfPeriod), 10, 23, 59, 59)
			OR Begin = DATE(Year(BeginOfPeriod), Month(BeginOfPeriod), 11) 
			AND END = DATE(Year(BeginOfPeriod), Month(BeginOfPeriod), 20, 23, 59, 59)
			OR Begin = DATE(Year(BeginOfPeriod), Month(BeginOfPeriod), 1) 
			AND END = EndOfMonth(BeginOfPeriod)	Then
			PeriodType = PredefinedValue("Enum.fmAvailableReportPeriods.TenDays");
		EndIf;
	EndIf;
	
	If ValueIsFilled(MinimumPeriodType) Then
		AvailablePeriodList = GetAvailablePeriodList();
		
		PositionPeriodType            = AvailablePeriodList.IndexOf(AvailablePeriodList.FindByValue(PeriodType));
		PositionMinimumPeriodType = AvailablePeriodList.IndexOf(AvailablePeriodList.FindByValue(MinimumPeriodType));
		
		If PositionPeriodType < PositionMinimumPeriodType Then
			PeriodType = MinimumPeriodType;
		EndIf;
	EndIf;
	
	Return PeriodType;
	
EndFunction

// Возвращает представление периода.
// 
// Параметры:
//   ВидПериода    - ПеречислениеСсылка.уфДоступныеПериодыОтчета - Вид периода.
//   НачалоПериода - Дата - Дата начала периода.
//   КонецПериода  - Дата - Дата окончания периода.
// 
// Возвращаемое значение:
//   Строка - Текстовое представление периода.
// 
Function GetReportPeroidRepresentation(PeriodType, VAL BeginOfPeriod, VAL EndOfPeriod) Export
	
	If PeriodType = PredefinedValue("Enum.fmAvailableReportPeriods.ArbitraryPeriod") Then	
		If NOT ValueIsFilled(BeginOfPeriod) AND NOT ValueIsFilled(EndOfPeriod) Then
			Return "";
		Else
			Return Format(BeginOfPeriod, "DF=dd.MM.yy") + " - " + Format(EndOfPeriod, "DF=dd.MM.yy");
		EndIf;
	Else
		CalculatedPeriodType = GetPeriodType(BeginOfPeriod, EndOfPeriod);
		If CalculatedPeriodType <> PeriodType AND ValueIsFilled(BeginOfPeriod) Then
			PeriodType = CalculatedPeriodType;
		EndIf;
		
		List = GetPeriodList(BeginOfPeriod, PeriodType);
		
		ListItem = List.FindByValue(BeginOfPeriod);
		If ListItem <> Undefined Then
			Return ListItem.Presentation;
		Else
			Return "";
		EndIf;
	EndIf;
	
	Return "";
	
EndFunction

// Подбирает период отчета по виду периода и текущим датам отчетов.
//
// Параметры:
//	ВидПериода    - ПеречислениеСсылка.уфДоступныеПериодыОтчета - Вид периода.
//	Текст         - Строка - Текстовое описание периода.
//	ДатаНачала    - Дата - Дата начала периода.
//	ДатаОкончания - Дата - Дата окончания периода.
//
// Возвращаемое значение:
//	СписокЗначений - Список возможных периодов.
//		* Значение - Дата - Дата начала периода.
//		* Представление - Строка - Текстовое описание периода.
//
Function ChooseReportPeriod(PeriodType, Text, BeginDate, EndDate) Export
	
	DataForChoice = New ValueList;
	
	WordArray = GetReportPeriodWordsArray(Text);
	
	GetPeriodValue(PeriodType, WordArray, DataForChoice);
	
	Return DataForChoice;
	
EndFunction

#EndRegion

#Region ServiceProceduresAdFunctions

Procedure GetPeriodValue(PeriodType, WordArray, DataForChoice)

	TodayDate = CurrentDate(); // Дата сеанса не используется.

	Day  = Day(TodayDate);
	Month = Month(TodayDate);
	Year   = Year(TodayDate);
	
	If PredefinedValue("Enum.fmAvailableReportPeriods.Day") = PeriodType Then
		If WordArray.Count() > 0 Then                 
			If ContainsChars(WordArray[0], "1234567890") Then
				Day = Number(WordArray[0]);
			EndIf;
		EndIf;
		
		If WordArray.Count() > 1 Then
			MonthNumber = GetMonth(WordArray[1]);
			If MonthNumber <> Undefined Then
				Month = MonthNumber;
			EndIf;
		EndIf;
		
		If WordArray.Count() > 2 Then
			If ContainsChars(WordArray[2], "1234567890") Then
				Year = GetMonth(WordArray[2]);
			EndIf;
		EndIf;
		
		Try
			DateForChoice = DATE(Year, Month, Day);
		Except
			Return;
		EndTry;
	
		DataForChoice.Add(DateForChoice, Format(DateForChoice, "DF='dd MMMM yyyy'"))
		
	ElsIf PredefinedValue("Enum.fmAvailableReportPeriods.Week") = PeriodType Then
	// Период Неделя не обрабатывается.
	ElsIf PredefinedValue("Enum.fmAvailableReportPeriods.TenDays") = PeriodType Then
		If Day <= 10 Then
			DecadeNumber = 1;
		ElsIf Day >= 11 AND Day <= 20 Then
			DecadeNumber = 2;
		ElsIf Day >= 21 Then
			DecadeNumber = 3;
		EndIf;
		
		If WordArray.Count() > 0 Then
			If ContainsChars(WordArray[0], "123") Then
				DecadeNumber = Number(WordArray[0]);
			Else
				Return;
			EndIf;
		EndIf;
		
		If WordArray.Count() > 1 Then
			If StrFind(WordArray[1], "Dec") = 0  Then
				Return;
			EndIf;
		EndIf;
		
		
		If WordArray.Count() > 2 Then
			MonthNumber = GetMonth(WordArray[2]);
			If MonthNumber <> Undefined Then
				Month = MonthNumber;
			EndIf;
		EndIf;
		
		If WordArray.Count() > 3 Then
			If ContainsChars(WordArray[3], "1234567890") Then 
				Year = GetMonth(WordArray[3]);
			EndIf;
		EndIf;
		
		Try 
			BegOfDecade = DATE(Year, Month, (DecadeNumber - 1) * 10 + 1);
			EndOfDecade  = ReportEndOfPeriod(PeriodType, BegOfDecade);
		Except
			Return;
		EndTry;
		
		DataForChoice.Add(BegOfDecade, GetReportPeroidRepresentation(PeriodType, BegOfDecade, EndOfDecade))
		
	ElsIf PredefinedValue("Enum.fmAvailableReportPeriods.Month") = PeriodType Then
		Day = 1;

		If WordArray.Count() > 0 Then
			MonthNumber = GetMonth(WordArray[0]);
			If MonthNumber <> Undefined Then
				Month = MonthNumber;
			EndIf;
		EndIf;
		
		If WordArray.Count() > 1 Then
			If ContainsChars(WordArray[1], "1234567890") Then 
				Year = GetMonth(WordArray[1]);
			EndIf;
		EndIf;
		
		Try
			BegOfMonth = DATE(Year, Month, Day);
			EndOfMonth  = ReportEndOfPeriod(PeriodType, BegOfMonth);
		Except
			Return;
		EndTry;
		
		DataForChoice.Add(BegOfMonth, GetReportPeroidRepresentation(PeriodType, BegOfMonth, EndOfMonth))
		
	ElsIf PredefinedValue("Enum.fmAvailableReportPeriods.Quarter") = PeriodType Then
		QuarterNumber = 1;
		If Month <= 3 Then
			QuarterNumber = 1;
		ElsIf Month >= 4 AND Month <= 6 Then
			QuarterNumber = 2;
		ElsIf Month >= 7 AND Month <= 9 Then
			QuarterNumber = 3;
		ElsIf Month >= 10 Then
			QuarterNumber = 4;
		EndIf;
		
		If WordArray.Count() > 0 Then
			If ContainsChars(WordArray[0], "1234") Then
				QuarterNumber = Number(WordArray[0]);
			Else
				Return;
			EndIf;
		EndIf;
		
		If WordArray.Count() > 1 Then
			If StrFind(WordArray[1], "Quar") = 0  Then
				Return;
			EndIf;
		EndIf;

		If WordArray.Count() > 2 Then
			If ContainsChars(WordArray[2], "1234567890") Then 
				Year = GetMonth(WordArray[2]);
			EndIf;
		EndIf;
		
		Try 
			BegOfQuarter = BegOfQuarter(DATE(Year, (QuarterNumber - 1) * 3 + 1, 1));
			EndOfQuarter  = ReportEndOfPeriod(PeriodType, BegOfQuarter);
		Except
			Return;
		EndTry;
	
		DataForChoice.Add(BegOfQuarter, GetReportPeroidRepresentation(PeriodType, BegOfQuarter, EndOfQuarter))

	ElsIf PredefinedValue("Enum.fmAvailableReportPeriods.HalfYear") = PeriodType Then
		HalfyearNumber = 1;
		If Month <= 6 Then
			HalfyearNumber = 1;
		Else
			HalfyearNumber = 2;
		EndIf;
		
		If WordArray.Count() > 0 Then
			If ContainsChars(WordArray[0], "12") Then
				HalfyearNumber = Number(WordArray[0]);
			Else
				Return;
			EndIf;
		EndIf;
		
		If WordArray.Count() > 1 Then
			If StrFind(WordArray[1], "Half") = 0  Then
				Return;
			EndIf;
		EndIf;

		If WordArray.Count() > 2 Then
			If ContainsChars(WordArray[2], "1234567890") Then 
				Year = GetMonth(WordArray[2]);
			EndIf;
		EndIf;
		
		Try 
			BegOfHalfYear = BegOfQuarter(DATE(Year, (HalfyearNumber - 1) * 6 + 1, 1));
			EndOfHalfYear  = ReportEndOfPeriod(PeriodType, BegOfHalfYear);
		Except
			Return;
		EndTry;
		
		DataForChoice.Add(BegOfHalfYear, GetReportPeroidRepresentation(PeriodType, BegOfHalfYear, EndOfHalfYear))
		
	ElsIf PredefinedValue("Enum.fmAvailableReportPeriods.Year") = PeriodType Then
		For Each Word In WordArray Do
			If ContainsChars(Word, "1234567890") Then 
				Year = Number(Word);
				If Year < 10 Then // Один знак.
					CurrYear = Year(TodayDate);
					Year = Int(CurrYear / 10) * 10 + Year;
				ElsIf Year >= 10 AND Year < 100  Then // Два знака.
					CurrYear             = Year(TodayDate);
					CurrCentury        = Int(CurrYear / 100) * 100;
					PrevCentury = CurrCentury - 100;
					UpperBoundaryOfCurrCentury = CurrYear - CurrCentury + 20;
					If Year >= 0 AND UpperBoundaryOfCurrCentury >= Year Then
						Year = Year + CurrCentury;
					Else
						Year = Year + PrevCentury;
					EndIf;
				EndIf;
				Try 
					BegOfYear = DATE(Year, 1, 1);
					EndOfYear  = DATE(Year, 12, 31, 23, 59, 59);
				Except
					Return;
				EndTry;
				DataForChoice.Add(BegOfYear, GetReportPeroidRepresentation(PeriodType, BegOfYear, EndOfYear))
			EndIf;
		EndDo;
	EndIf;
	
EndProcedure

Function GetMonth(MonthRepresentationString)
	
	MonthList = New ValueList;
	MonthList.Add(1, "Jan");
	MonthList.Add(2, "Feb");
	MonthList.Add(3, "Mar");
	MonthList.Add(4, "Apr");
	MonthList.Add(5, "May");
	MonthList.Add(6, "Jun");
	MonthList.Add(7, "Jul");
	MonthList.Add(8, "Aug");
	MonthList.Add(9, "Sep");
	MonthList.Add(10, "Oct");
	MonthList.Add(11, "Nov");
	MonthList.Add(12, "Dec");
	
	Month = Undefined;
	
	If ContainsChars(MonthRepresentationString, "1234567890") Then
		Month = Number(MonthRepresentationString);
	Else
		For Each ListItem In MonthList Do
			If StrFind(MonthRepresentationString, ListItem.Presentation) > 0 Then
				Month = ListItem.Value;
			EndIf;
		EndDo;
	EndIf;
	Return Month;
	
EndFunction 

Function ContainsChars(StringInCheck, CharString)
	
	ContainOnlySubstring = True;
	
	CheckChars = New ValueList;
	
	For Counter = 1 To StrLen(CharString) Do
		CheckChars.Add(CharCode(CharString, Counter));
	EndDo;
	
	For Counter = 1 To StrLen(StringInCheck) Do
		If CheckChars.FindByValue(CharCode(StringInCheck, Counter)) = Undefined Then
			ContainOnlySubstring = False;
			Break;
		EndIf;
	EndDo;
	
	Return ContainOnlySubstring;
	
EndFunction

Function GetAvailablePeriodList()
	
	AvailablePeriodList = New ValueList;
	AvailablePeriodList.Add(PredefinedValue("Enum.fmAvailableReportPeriods.Day"));
	AvailablePeriodList.Add(PredefinedValue("Enum.fmAvailableReportPeriods.Month"));
	AvailablePeriodList.Add(PredefinedValue("Enum.fmAvailableReportPeriods.Quarter"));
	AvailablePeriodList.Add(PredefinedValue("Enum.fmAvailableReportPeriods.HalfYear"));
	AvailablePeriodList.Add(PredefinedValue("Enum.fmAvailableReportPeriods.Year"));
	AvailablePeriodList.Add(PredefinedValue("Enum.fmAvailableReportPeriods.ArbitraryPeriod"));
	
	Return AvailablePeriodList;
	
EndFunction

// Из переданного текста извлекаются строки, задающие период отчета.
//
// Параметры:
//  Текст        - текст, содержащий данные периода отчета.
//
// Возвращаемое значение:
//   Массив      - строки, задающие период отчета.
//
Function GetReportPeriodWordsArray(Text)
	
	WordArray = New Array;
	SearchText = Lower(TrimAll(Text));
	SplitPosition = 1;
	While SearchText <> "" Do
		Word = "";
		SplitPosition = 0;
		If StrFind(SearchText, " ") > 0 Then
			 SplitPosition = ?(SplitPosition > 0, Min(SplitPosition, StrFind(SearchText, " ")), StrFind(SearchText, " "));
		EndIf;
		If StrFind(SearchText, ".") > 0 Then
			 SplitPosition = ?(SplitPosition > 0, Min(SplitPosition, StrFind(SearchText, ".")), StrFind(SearchText, "."));
		EndIf;
		If StrFind(SearchText, "/") > 0 Then
			 SplitPosition = ?(SplitPosition > 0, Min(SplitPosition, StrFind(SearchText, "/")), StrFind(SearchText, "/"));
		EndIf;
		If StrFind(SearchText, "\") > 0 Then
			 SplitPosition = ?(SplitPosition > 0, Min(SplitPosition, StrFind(SearchText, "\")), StrFind(SearchText, "\"));
		EndIf;
		
		If SplitPosition = 0 Then
			Word = TrimAll(SearchText);
			SearchText = "";
		Else
			Word = TrimAll(Mid(SearchText, 1, SplitPosition-1));
		EndIf;
		
		If Word <> " " AND Word <> "." AND Word <> "/" AND Word <> "\" AND Word <> "" Then
			WordArray.Add(Word);
		EndIf;

		SearchText = TrimAll(Right(SearchText, StrLen(SearchText) - SplitPosition));
	EndDo;
	
	Return WordArray;
	
EndFunction

#EndRegion



