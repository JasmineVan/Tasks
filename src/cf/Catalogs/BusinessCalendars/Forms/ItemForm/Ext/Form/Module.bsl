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
	
	If Object.Ref.IsEmpty() Then
		FillWithCurrentYearData(Parameters.CopyingValue);
		SetBasicCalendarFieldProperties(ThisObject);
	EndIf;
	
	DaysKindsColors = New FixedMap(Catalogs.BusinessCalendars.BusinessCalendarDayKindsAppearanceColors());
	
	DayKindsList = Catalogs.BusinessCalendars.DayKindsList();
	
EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)
	
	If Common.SubsystemExists("SaaSTechnology.SaaS.DataExchangeSaaS") Then
		ModuleStandaloneMode = Common.CommonModule("StandaloneMode");
		ModuleStandaloneMode.ObjectOnReadAtServer(CurrentObject, ThisObject.ReadOnly);
	EndIf;
	
	FillWithCurrentYearData();
	
	HasBasicCalendar = ValueIsFilled(Object.BasicCalendar);
	SetBasicCalendarFieldProperties(ThisObject);
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	StartBasicCalendarVisibilitySetup();
	
EndProcedure

&AtClient
Procedure ChoiceProcessing(SelectedValue, ChoiceSource)
	If Upper(ChoiceSource.FormName) = Upper("CommonForm.SelectDate") Then
		If SelectedValue = Undefined Then
			Return;
		EndIf;
		SelectedDates = Items.Calendar.SelectedDates;
		If SelectedDates.Count() = 0 Or Year(SelectedDates[0]) <> CurrentYearNumber Then
			Return;
		EndIf;
		ReplacementDate = SelectedDates[0];
		ShiftDayKind(ReplacementDate, SelectedValue);
		Items.Calendar.Refresh();
	EndIf;
EndProcedure

&AtServer
Procedure FillCheckProcessingAtServer(Cancel, CheckedAttributes)
	
	If HasBasicCalendar AND Not ValueIsFilled(Object.BasicCalendar) Then
		MessageText = NStr("ru = 'Федеральный календарь не заполнен.'; en = 'The federal calendar is blank.'; pl = 'Nie wypełniono kalendarza federalnego.';de = 'Der Bundeskalender ist nicht ausgefüllt.';ro = 'Calendarul superior nu este completat.';tr = 'Federal takvim doldurulmadı.'; es_ES = 'Calendario federal no rellenado.'");
		Common.MessageToUser(MessageText, , , "Object.BasicCalendar", Cancel);
	EndIf;
	
EndProcedure

&AtServer
Procedure OnWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	Var YearNumber;
	
	If Not WriteParameters.Property("YearNumber", YearNumber) Then
		YearNumber = CurrentYearNumber;
	EndIf;
	
	WriteBusinessCalendarData(YearNumber, CurrentObject);
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure CurrentYearNumberOnChange(Item)
	
	WriteScheduleData = False;
	If Modified Then
		MessageText = StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = 'Записать измененные данные за %1 год?'; en = 'Do you want to write the changes for year %1?'; pl = 'Zapisać zmienione dane za %1 rok?';de = 'Schreiben Sie die geänderten Daten für das Jahr%1?';ro = 'Scrieți datele modificate pentru anul %1?';tr = '%1 yılı için değiştirilmiş veriler yazılsın mı?'; es_ES = '¿Inscribir los datos cambiados para el año de %1?'"), Format(PreviousYearNumber, "NG=0"));
		Notification = New NotifyDescription("CurrentYearNumberOnChangeCompletion", ThisObject);
		ShowQueryBox(Notification, MessageText, QuestionDialogMode.YesNo);
		Return;
	EndIf;
	
	ProcessYearChange(WriteScheduleData);
	
	Modified = False;
	
	Items.Calendar.Refresh();
	
EndProcedure

&AtClient
Procedure CalendarOnPeriodOutput(Item, PeriodAppearance)
	
	For Each PeriodAppearanceString In PeriodAppearance.Dates Do
		DayAppearanceColor = DaysKindsColors.Get(DaysKinds.Get(PeriodAppearanceString.Date));
		If DayAppearanceColor = Undefined Then
			DayAppearanceColor = CommonClient.StyleColor("BusinessCalendarDayKindColorNotSpecified");
		EndIf;
		PeriodAppearanceString.TextColor = DayAppearanceColor;
	EndDo;
	
EndProcedure

&AtClient
Procedure HasBasicCalendarOnChange(Item)
	
	SetBasicCalendarFieldProperties(ThisObject);
	
	If Not HasBasicCalendar Then
		Object.BasicCalendar = Undefined;
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandHandlers

&AtClient
Procedure ChangeDay(Command)
	
	SelectedDates = Items.Calendar.SelectedDates;
	
	If SelectedDates.Count() > 0 AND Year(SelectedDates[0]) = CurrentYearNumber Then
		Notification = New NotifyDescription("ChangeDayCompletion", ThisObject, SelectedDates);
		ShowChooseFromList(Notification, DayKindsList, , DayKindsList.FindByValue(DaysKinds.Get(SelectedDates[0])));
	EndIf;
	
EndProcedure

&AtClient
Procedure ShiftDay(Command)
	
	SelectedDates = Items.Calendar.SelectedDates;
	
	If SelectedDates.Count() = 0 Or Year(SelectedDates[0]) <> CurrentYearNumber Then
		Return;
	EndIf;
		
	ReplacementDate = SelectedDates[0];
	DayKind = DaysKinds.Get(ReplacementDate);
	
	DateSelectionParameters = New Structure(
		"InitialValue, 
		|BeginOfRepresentationPeriod, 
		|EndOfRepresentationPeriod, 
		|Title, 
		|NoteText");
		
	DateSelectionParameters.InitialValue = ReplacementDate;
	DateSelectionParameters.BeginOfRepresentationPeriod = BegOfYear(Calendar);
	DateSelectionParameters.EndOfRepresentationPeriod = EndOfYear(Calendar);
	DateSelectionParameters.Title = NStr("ru = 'Выбор даты переноса'; en = 'Select substitute date'; pl = 'Wybierz datę transferu';de = 'Wählen Sie die Übertragungsdaten aus';ro = 'Selectați datele transferate';tr = 'Transfer verileri seçin'; es_ES = 'Seleccionar los datos de traslado'");
	
	MessageText = NStr("ru = 'Выберите дату, на которую будет осуществлен перенос дня %1 (%2)'; en = 'Select a date that substitutes %1 (%2).'; pl = 'Wybierz datę, na którą zostanie przeniesiony termin %1 (%2)';de = 'Wählen Sie einen Tagesdatum%1 aus, an das (%2) übertragen werden soll';ro = 'Selectați data la care va fi transferată ziua de %1 (%2)';tr = '(%2) transfer edilecek tarihi  %1 seçin'; es_ES = 'Seleccionar una fecha un día %1 se trasladará a (%2)'");
	DateSelectionParameters.NoteText = StringFunctionsClientServer.SubstituteParametersToString(MessageText, Format(ReplacementDate, "DF='d MMMM'"), DayKind);
	
	OpenForm("CommonForm.SelectDate", DateSelectionParameters, ThisObject);
	
EndProcedure

&AtClient
Procedure FillByDefault(Command)
	
	FillWithDefaultData();
	
	Items.Calendar.Refresh();
	
EndProcedure

&AtClient
Procedure Print(Command)
	
	If Object.Ref.IsEmpty() Then
		Handler = New NotifyDescription("PrintCompletion", ThisObject);
		ShowQueryBox(
			Handler,
			NStr("ru = 'Данные производственного календаря еще не записаны.
                  |Печать возможна только после записи данных.
                  |
                  |Записать?'; 
                  |en = 'You have unsaved business calendar data.
                  |Before you print the calendar, please save the data.
                  |
                  |Do you want to save it?'; 
                  |pl = 'Dane kalendarza firmowego nie zostały jeszcze zapisane.
                  |Można je wydrukować dopiero po zapisaniu danych.
                  |
                  |Zapisać?';
                  |de = 'Die Geschäftskalenderdaten sind noch nicht geschrieben. 
                  |Sie können sie nur nach Datenaufzeichnung drucken. 
                  |
                  |Aufzeichnend?';
                  |ro = 'Datele din calendarul de afaceri nu au fost încă scrise. 
                  | Puteți să le tipăriți numai după înregistrarea datelor.
                  |
                  | Înregistrați?';
                  |tr = 'İş takvimi verileri henüz yazılmadı. 
                  |Sadece veri kaydettikten sonra yazdırabilirsiniz. 
                  |
                  |Kayıt?'; 
                  |es_ES = 'Datos del calendario de negocio aún no se han inscrito.
                  |Puede imprimirlo solo después de haber grabado los datos.
                  |
                  |¿Grabar?'"),
			QuestionDialogMode.YesNo,
			,
			DialogReturnCode.Yes);
		Return;
	EndIf;
	
	PrintCompletion(-1);
		
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure FillWithCurrentYearData(CopyingValue = Undefined)
	
	// Fills in the form with data of the current year.
	
	SetCalendarField();
	
	RefToCalendar = Object.Ref;
	If ValueIsFilled(CopyingValue) Then
		RefToCalendar = CopyingValue;
		Object.Description = Undefined;
		Object.Code = Undefined;
	EndIf;
	
	ReadBusinessCalendarData(RefToCalendar, CurrentYearNumber);
		
EndProcedure

&AtServer
Procedure ReadBusinessCalendarData(BusinessCalendar, YearNumber)
	
	// Importing business calendar data for the specified year.
	ConvertBusinessCalendarData(
		Catalogs.BusinessCalendars.BusinessCalendarData(BusinessCalendar, YearNumber));
	
EndProcedure

&AtServer
Procedure FillWithDefaultData()
	
	// Fills in the form with business calendar data based on information on holidays and their 
	// replacements.
	
	BasicCalendarCode = Undefined;
	If ValueIsFilled(Object.BasicCalendar) Then
		BasicCalendarCode = Common.ObjectAttributeValue(Object.BasicCalendar, "Code");
	EndIf;
	
	DefaultData = Catalogs.BusinessCalendars.BusinessCalendarDefaultFillingResult(
		Object.Code, CurrentYearNumber, BasicCalendarCode);
		
	ConvertBusinessCalendarData(DefaultData);

	Modified = True;
	
EndProcedure

&AtServer
Procedure ConvertBusinessCalendarData(BusinessCalendarData)
	
	// Business calendar data is used in the form as maps between DaysKinds and ShiftedDays.
	// 
	// The procedure fills in these maps.
	
	DaysKindsMap = New Map;
	ShiftedDaysMap = New Map;
	
	For Each TableRow In BusinessCalendarData Do
		DaysKindsMap.Insert(TableRow.Date, TableRow.DayKind);
		If ValueIsFilled(TableRow.ReplacementDate) Then
			ShiftedDaysMap.Insert(TableRow.Date, TableRow.ReplacementDate);
		EndIf;
	EndDo;
	
	DaysKinds = New FixedMap(DaysKindsMap);
	ShiftedDays = New FixedMap(ShiftedDaysMap);
	
	FillReplacementsPresentation(ThisObject);
	
EndProcedure

&AtServer
Procedure WriteBusinessCalendarData(Val YearNumber, Val CurrentObject = Undefined)
	
	// Write business calendar data for the specified year.
	
	If CurrentObject = Undefined Then
		CurrentObject = FormAttributeToValue("Object");
	EndIf;
	
	BusinessCalendarData = New ValueTable;
	BusinessCalendarData.Columns.Add("Date", New TypeDescription("Date"));
	BusinessCalendarData.Columns.Add("DayKind", New TypeDescription("EnumRef.BusinessCalendarDaysKinds"));
	BusinessCalendarData.Columns.Add("ReplacementDate", New TypeDescription("Date"));
	
	For Each KeyAndValue In DaysKinds Do
		
		TableRow = BusinessCalendarData.Add();
		TableRow.Date = KeyAndValue.Key;
		TableRow.DayKind = KeyAndValue.Value;
		
		// If the day is shifted from another date, specify the replacement date.
		ReplacementDate = ShiftedDays.Get(TableRow.Date);
		If ReplacementDate <> Undefined 
			AND ReplacementDate <> TableRow.Date Then
			TableRow.ReplacementDate = ReplacementDate;
		EndIf;
		
	EndDo;
	
	Catalogs.BusinessCalendars.WriteBusinessCalendarData(CurrentObject.Ref, YearNumber, BusinessCalendarData);
	
EndProcedure

&AtServer
Procedure ProcessYearChange(WriteScheduleData)
	
	If Not WriteScheduleData Then
		FillWithCurrentYearData();
		Return;
	EndIf;
	
	If Object.Ref.IsEmpty() Then
		Write(New Structure("YearNumber", PreviousYearNumber));
	Else
		WriteBusinessCalendarData(PreviousYearNumber);
	EndIf;
	
	FillWithCurrentYearData();	
	
EndProcedure

&AtClient
Procedure ChangeDaysKinds(DaysDates, DayKind)
	
	// Sets a particular day kind for all array dates.
	
	DaysKindsMap = New Map(DaysKinds);
	
	For Each SelectedDate In DaysDates Do
		DaysKindsMap.Insert(SelectedDate, DayKind);
	EndDo;
	
	DaysKinds = New FixedMap(DaysKindsMap);
	
EndProcedure

&AtClient
Procedure ShiftDayKind(ReplacementDate, PurposeDate)
	
	// Swap two days in the calendar
	// - Swap day kinds.
	// - Remember replacement dates.
	//	* If the day being shifted already has a replacement date (has already been moved),
	//		use the existing replacement date.
	//	* If the dates match (the day is returned to its place), delete such record.
	
	DaysKindsMap = New Map(DaysKinds);
	
	DaysKindsMap.Insert(PurposeDate, DaysKinds.Get(ReplacementDate));
	DaysKindsMap.Insert(ReplacementDate, DaysKinds.Get(PurposeDate));
	
	ShiftedDaysMap = New Map(ShiftedDays);
	
	EnterReplacementDate(ShiftedDaysMap, ReplacementDate, PurposeDate);
	EnterReplacementDate(ShiftedDaysMap, PurposeDate, ReplacementDate);
	
	DaysKinds = New FixedMap(DaysKindsMap);
	ShiftedDays = New FixedMap(ShiftedDaysMap);
	
	FillReplacementsPresentation(ThisObject);
	
EndProcedure

&AtClient
Procedure EnterReplacementDate(ShiftedDaysMap, ReplacementDate, PurposeDate)
	
	// Fills in a correct replacement date according to days replacement dates.
	
	PurposeDateDaySource = ShiftedDays.Get(PurposeDate);
	If PurposeDateDaySource = Undefined Then
		PurposeDateDaySource = PurposeDate;
	EndIf;
	
	If ReplacementDate = PurposeDateDaySource Then
		ShiftedDaysMap.Delete(ReplacementDate);
	Else	
		ShiftedDaysMap.Insert(ReplacementDate, PurposeDateDaySource);
	EndIf;
	
EndProcedure

&AtClientAtServerNoContext
Procedure FillReplacementsPresentation(Form)
	
	// Generates a holiday replacement presentation as a value list.
	
	Form.ReplacementsList.Clear();
	For Each KeyAndValue In Form.ShiftedDays Do
		// From the applied perspective, a weekday is always replaced by a holiday, so let us select the 
		// date that previously was a holiday and now is a weekday.
		SourceDate = KeyAndValue.Key;
		DestinationDate = KeyAndValue.Value;
		DayKind = Form.DaysKinds.Get(SourceDate);
		If DayKind = PredefinedValue("Enum.BusinessCalendarDaysKinds.Saturday")
			Or DayKind = PredefinedValue("Enum.BusinessCalendarDaysKinds.Sunday") Then
			// Swap dates to show holiday replacement information as "A replaces B" instead of "B replaces A".
			ReplacementDate = DestinationDate;
			DestinationDate = SourceDate;
			SourceDate = ReplacementDate;
		EndIf;
		If Form.ReplacementsList.FindByValue(SourceDate) <> Undefined 
			Or Form.ReplacementsList.FindByValue(DestinationDate) <> Undefined Then
			// Holiday replacement is already added, skip it.
			Continue;
		EndIf;
		SourceDayKind = ShiftedDayKindPresentation(Form.DaysKinds.Get(DestinationDate), SourceDate);
		DestinationDayKind = ShiftedDayKindPresentation(Form.DaysKinds.Get(SourceDate), DestinationDate);
		Form.ReplacementsList.Add(SourceDate, ReplacementPresentation(SourceDate, DestinationDate, SourceDayKind, DestinationDayKind));
	EndDo;
	Form.ReplacementsList.SortByValue();
	
	SetReplacementsListVisibility(Form);
	
EndProcedure

&AtClientAtServerNoContext
Function ReplacementPresentation(SourceDate, DestinationDate, SourceDayKind, DestinationDayKind)
	
	Presentation = "";
	
	TemplateMale = NStr("ru = '%1 %3 перенесен на %2 %4'; en = '%2 %4 is substituted for %1 %3'; pl = '%1 %3 zostaje przeniesiony do %2 %4';de = '%1 %3 übertragen auf %2 %4';ro = '%1 %3 este transferată la %2 %4';tr = '%1%3 ertelendi %2%4'; es_ES = '%1 %3 se ha trasladado a %2 %4'");
	TemplateNeuter = NStr("ru = '%1 %3 перенесено на %2 %4'; en = '%2 %4 is substituted for %1 %3'; pl = '%1 %3 przeniesiono na %2 %4';de = '%1 %3 übertragen auf %2 %4';ro = '%1 %3 este transferată la %2 %4';tr = '%1%3 ertelendi %2%4'; es_ES = '%1 %3 se ha trasladado a %2 %4'");
	TemplateFemale = NStr("ru = '%1 %3 перенесена на %2 %4'; en = '%2 %4 is substituted for %1 %3'; pl = '%1 %3 została przeniesiony na %2 %4';de = '%1 %3 übertragen auf %2 %4';ro = '%1 %3 este transferată la %2 %4';tr = '%1%3 ertelendi %2%4'; es_ES = '%1 %3 se ha trasladado a %2 %4'");
	
	DaysFemale = New Map;
	DaysFemale.Insert(NStr("ru = 'среда'; en = 'Wednesday'; pl = 'środa';de = 'Mittwoch';ro = 'miercuri';tr = 'Çarşamba'; es_ES = 'miércoles'"), NStr("ru = 'среду'; en = 'Wednesday'; pl = 'środę';de = 'mittwochs';ro = 'miercuri';tr = 'Çarşamba'; es_ES = 'miércoles'"));
	DaysFemale.Insert(NStr("ru = 'пятница'; en = 'Friday'; pl = 'piątek';de = 'Freitag';ro = 'vineri';tr = 'Cuma'; es_ES = 'viernes'"), NStr("ru = 'пятницу'; en = 'Friday'; pl = 'piątek';de = 'freitags';ro = 'vineri';tr = 'Cuma'; es_ES = 'viernes'"));
	DaysFemale.Insert(NStr("ru = 'суббота'; en = 'Saturday'; pl = 'sobota';de = 'Samstag';ro = 'sâmbătă';tr = 'Cumartesi'; es_ES = 'sábado'"), NStr("ru = 'субботу'; en = 'Saturday'; pl = 'sobotę';de = 'samstags';ro = 'sâmbătă';tr = 'Cumartesi'; es_ES = 'sábado'"));
	
	DaysNeuter = New Map;
	DaysNeuter.Insert(NStr("ru = 'воскресенье'; en = 'Sunday'; pl = 'niedziela';de = 'Sonntag';ro = 'duminică';tr = 'Pazar'; es_ES = 'domingo'"), True);
	
	Template = TemplateMale;
	If DaysFemale[SourceDayKind] <> Undefined Then
		Template = TemplateFemale;
	EndIf;
	If DaysNeuter[SourceDayKind] <> Undefined Then
		Template = TemplateNeuter;
	EndIf;
	
	DestinationDayPresentation = DestinationDayKind;
	If DaysFemale[DestinationDayKind] <> Undefined Then
		DestinationDayPresentation = DaysFemale[DestinationDayKind];
	EndIf;
	
	Presentation = StringFunctionsClientServer.SubstituteParametersToString(
		Template, 
		Format(SourceDate, "DF='d MMMM'"), 
		Format(DestinationDate, "DF='d MMMM'"), 
		SourceDayKind, 
		DestinationDayPresentation);
	
	Return Presentation;
	
EndFunction

&AtClientAtServerNoContext
Procedure SetReplacementsListVisibility(Form)
	
	ListVisibility = Form.ReplacementsList.Count() > 0;
	CommonClientServer.SetFormItemProperty(Form.Items, "ReplacementsList", "Visible", ListVisibility);
	
EndProcedure

&AtClientAtServerNoContext
Function ShiftedDayKindPresentation(DayKind, Date)
	
	// If a day is a weekday or a holiday, display the day of the week as its presentation.
	
	If DayKind = PredefinedValue("Enum.BusinessCalendarDaysKinds.Work") 
		Or DayKind = PredefinedValue("Enum.BusinessCalendarDaysKinds.Holiday") Then
		DayKind = Format(Date, "DF='dddd'");
	EndIf;
	
	Return Lower(String(DayKind));
	
EndFunction	

&AtServer
Procedure SetCalendarField()
	
	If CurrentYearNumber = 0 Then
		CurrentYearNumber = Year(CurrentSessionDate());
	EndIf;
	PreviousYearNumber = CurrentYearNumber;
	
	Items.Calendar.BeginOfRepresentationPeriod	= Date(CurrentYearNumber, 1, 1);
	Items.Calendar.EndOfRepresentationPeriod	= Date(CurrentYearNumber, 12, 31);
		
EndProcedure

&AtClient
Procedure CurrentYearNumberOnChangeCompletion(Response, AdditionalParameters) Export
	
	ProcessYearChange(Response = DialogReturnCode.Yes);
	Modified = False;
	Items.Calendar.Refresh();
	
EndProcedure

&AtClient
Procedure ChangeDayCompletion(SelectedItem, SelectedDates) Export
	
	If SelectedItem <> Undefined Then
		ChangeDaysKinds(SelectedDates, SelectedItem.Value);
		Items.Calendar.Refresh();
	EndIf;
	
EndProcedure

&AtClient
Procedure PrintCompletion(ResponseToWriteSuggestion, ExecutionParameters = Undefined) Export
	
	If ResponseToWriteSuggestion <> -1 Then
		If ResponseToWriteSuggestion <> DialogReturnCode.Yes Then
			Return;
		EndIf;
		Written = Write();
		If Not Written Then
			Return;
		EndIf;
	EndIf;
	
	PrintParameters = New Structure;
	PrintParameters.Insert("BusinessCalendar", Object.Ref);
	PrintParameters.Insert("YearNumber", CurrentYearNumber);
	
	CommandParameter = New Array;
	CommandParameter.Add(Object.Ref);
	
	If CommonClient.SubsystemExists("StandardSubsystems.Print") Then
		ModulePrintManagerClient = CommonClient.CommonModule("PrintManagementClient");
		ModulePrintManagerClient.ExecutePrintCommand("Catalog.BusinessCalendars", "BusinessCalendar", 
			CommandParameter, ThisObject, PrintParameters);
	EndIf;
	
EndProcedure

&AtClientAtServerNoContext
Procedure SetBasicCalendarFieldProperties(Form)
	
	CommonClientServer.SetFormItemProperty(
		Form.Items, 
		"BasicCalendar", 
		"Enabled", 
		Form.HasBasicCalendar);
		
	CommonClientServer.SetFormItemProperty(
		Form.Items, 
		"BasicCalendar", 
		"AutoMarkIncomplete", 
		Form.HasBasicCalendar);
		
	CommonClientServer.SetFormItemProperty(
		Form.Items, 
		"BasicCalendar", 
		"MarkIncomplete", 
		Not ValueIsFilled(Form.Object.BasicCalendar));
	
EndProcedure

&AtClient
Procedure StartBasicCalendarVisibilitySetup()
	
	TimeConsumingOperation = LoadSupportedBusinessCalendarsList();
	
	IdleParameters = TimeConsumingOperationsClient.IdleParameters(ThisObject);
	
	CompletionNotification = New NotifyDescription("CompleteBasicCalendarVisibilitySetting", ThisObject);
	TimeConsumingOperationsClient.WaitForCompletion(TimeConsumingOperation, CompletionNotification, IdleParameters);
	
EndProcedure

&AtServer
Function LoadSupportedBusinessCalendarsList()
	
	ProcedureParameters = New Structure;
	
	ExecutionParameters = TimeConsumingOperations.BackgroundExecutionParameters(UUID);
	ExecutionParameters.BackgroundJobDescription = NStr("ru = 'Заполнение списка поддерживаемых календарей'; en = 'Populate list of supported calendars'; pl = 'Wypełnianie listy obsługiwanych kalendarzy';de = 'Ausfüllen der Liste der unterstützten Kalender';ro = 'Completarea listei calendarelor susținute de aplicație';tr = 'Desteklenen takvimlerin listesini doldurma'; es_ES = 'Relleno de la lista de calendarios soportados'");
	
	Return TimeConsumingOperations.ExecuteInBackground("Catalogs.BusinessCalendars.FillDefaultBusinessCalendarsTimeConsumingOperation", 
		ProcedureParameters, ExecutionParameters);
	
EndFunction

&AtClient
Procedure CompleteBasicCalendarVisibilitySetting(Result, AdditionalParameters) Export
	
	If Result = Undefined Then
		CommonClientServer.SetFormItemProperty(Items, "BasicCalendarGroup", "Visible", True);
		Return;
	EndIf;
	
	CalendarsAddress = Result.ResultAddress;
	IsSuppliedCalendar = HasSuppliedCalendarWithThisCode(CalendarsAddress, Object.Code);
	
	If Not IsSuppliedCalendar Then
		CommonClientServer.SetFormItemProperty(Items, "BasicCalendarGroup", "Visible", True);
	EndIf;
	
EndProcedure

&AtServerNoContext
Function HasSuppliedCalendarWithThisCode(CalendarsAddress, Code)
	
	CalendarsTable = GetFromTempStorage(CalendarsAddress);
	
	If CalendarsTable <> Undefined AND CalendarsTable.Columns.Find("Code") <> Undefined Then
		Return CalendarsTable.Find(TrimAll(Code), "Code") <> Undefined;
	EndIf;
	
	Return False;
	
EndFunction

#EndRegion
