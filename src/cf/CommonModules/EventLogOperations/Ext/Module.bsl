///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Public

// Handles bulk message writing to the event log.
// The EventsForEventLog variable is cleared after writing.
//
// Parameters:
//  EventsForEventLog - ValueList - where Value is structure with the following properties:
//              * EventName  - String - a name of the event to write.
//              * LevelPresentation  - String - a presentation of the EventLogLevel collection values.
//                                       Possible values: Information, Error, Warning, and Note.
//              * Comment - String - an event comment.
//              * EventDate - Date   - the event date that is added to the comment when writing.
//
Procedure WriteEventsToEventLog(EventsForEventLog) Export
	
	If TypeOf(EventsForEventLog) <> Type("ValueList") Then
		Return;
	EndIf;	
	
	If EventsForEventLog.Count() = 0 Then
		Return;
	EndIf;
	
	For Each LogMessage In EventsForEventLog Do
		MessageValue = LogMessage.Value;
		EventName = MessageValue.EventName;
		EventLevel = EventLevelByPresentation(MessageValue.LevelPresentation);
		EventDate = CurrentSessionDate();
		If MessageValue.Property("EventDate") AND ValueIsFilled(MessageValue.EventDate) Then
			EventDate = MessageValue.EventDate;
		EndIf;
		Comment = String(EventDate) + " " + MessageValue.Comment;
		WriteLogEvent(EventName, EventLevel,,, Comment);
	EndDo;
	EventsForEventLog.Clear();
	
EndProcedure

#EndRegion

#Region Internal

// Write the message to the event log.
//
//  Parameters:
//   EventName          - String - the name of the event used for event log.
//   Level       - EventLogLevel - events importance level of the log event.
//   MetadataObject - MetadataObject - metadata object that the event refers to.
//   Data           - AnyRef, Number, String, Date, Boolean, Undefined, Type - data that the event is related to.
//                      It is recommended to specify referencies to the data objects (catalog items, 
//                      documents that the event refers to).
//   Comment         - String - the comment to the log event.
//
Procedure AddMessageForEventLog(Val EventName, Val Level,
		Val MetadataObject = Undefined, Val Data = Undefined, Val Comment = "") Export
		
	If IsBlankString(EventName) Then
		EventName = "Event"; // not localized to prevent startup from stopping in a partially translated configuration
	EndIf;

	WriteLogEvent(EventName, Level, MetadataObject, Data, Comment, EventLogEntryTransactionMode.Independent);
	
EndProcedure

// Reads event log message texts taking into account the filter settings.
//
// Parameters:
//
//     ReportParameters - Structure - contains parameters for reading event records from the event log. Contains fields:
//         Log                  - ValueTable         - contains records of the event log.
//         EventLogFilterAtClient   - Structure               - filter settings used to read the event log records.
//         EventCount       - Number                   - maximum number of records that can be read from the event log.
//         UUID - UUID - a form UUID.
//         OwnerManager       - Arbitrary            - event log is displayed in the form of this 
//                                                             object. The manager is used to call 
//                                                             back appearance functions.
//         AddAdditionalColumns - Boolean           - Determines whether callback is needed to add 
//                                                             additional columns.
//     StorageAddress - String, UUID - address of the temporary storage used to store the result.
//
// Result is a structure with the following fields:
//     LogEvents - ValueTable - the selected events.
//
Procedure ReadEventLogEvents(ReportParameters, StorageAddress) Export
	
	EventLogFilterAtClient          = ReportParameters.EventLogFilter;
	EventCount              = ReportParameters.EventsCountLimit;
	OwnerManager              = ReportParameters.OwnerManager;
	AddAdditionalColumns = ReportParameters.AddAdditionalColumns;
	
	// Verifying the parameters.
	StartDate    = Undefined;
	EndDate = Undefined;
	FilterDatesSpecified= EventLogFilterAtClient.Property("StartDate", StartDate) AND EventLogFilterAtClient.Property("EndDate", EndDate)
		AND ValueIsFilled(StartDate) AND ValueIsFilled(EventLogFilterAtClient.EndDate);
		
	If FilterDatesSpecified AND StartDate > EndDate Then
		Raise NStr("ru = 'Некорректно заданы условия отбора журнала регистрации. Дата начала больше даты окончания.'; en = 'Invalid event log filter settings. The start date is later than the end date.'; pl = 'Warunki filtrowania dziennika zdarzeń są nieprawidłowe. Data rozpoczęcia jest późniejsza niż data zakończenia.';de = 'Filterbedingungen des Ereignisprotokolls sind falsch. Startdatum ist größer als Enddatum.';ro = 'Condițiile filtrului din registrul logare sunt specificate incorect. Data începutului este mai mare decât data sfârșitului.';tr = 'Olay günlüğünün filtre koşulları yanlış. Başlangıç tarihi bitiş tarihinden büyüktür.'; es_ES = 'Condiciones del filtro del registro de eventos son incorrectas. Fecha inicial es mayor de la fecha final.'");
	EndIf;
	ServerTimeOffset = ServerTimeOffset();
	
	// Filter preparation
	Filter = New Structure;
	For Each FilterItem In EventLogFilterAtClient Do
		Filter.Insert(FilterItem.Key, FilterItem.Value);
	EndDo;
	FilterTransformation(Filter, ServerTimeOffset);
	
	// Exporting the selected events and generating the table structure.
	LogEvents = New ValueTable;
	UnloadEventLog(LogEvents, Filter, , , EventCount);
	
	LogEvents.Columns.Date.Name = "DateAtServer";
	LogEvents.Columns.Add("Date", New TypeDescription("Date"));
	
	LogEvents.Columns.Add("PictureNumber", New TypeDescription("Number"));
	LogEvents.Columns.Add("DataAddress",  New TypeDescription("String"));
	
	If Common.SeparatedDataUsageAvailable() Then
		LogEvents.Columns.Add("SessionDataSeparation", New TypeDescription("String"));
		LogEvents.Columns.Add("SessionDataSeparationPresentation", New TypeDescription("String"));
	EndIf;
	
	If AddAdditionalColumns Then
		OwnerManager.AddAdditionalEventColumns(LogEvents);
	EndIf;
	
	If Common.DataSeparationEnabled()
	   AND Common.SeparatedDataUsageAvailable()
	   AND Common.SubsystemExists("StandardSubsystems.SaaS.CoreSaaS") Then
		
		ModuleSaaS = Common.CommonModule("SaaS");
		UserAliases    = New Map();
	Else
		ModuleSaaS = Undefined;
		UserAliases    = Undefined;
	EndIf;
	
	For Each LogEvent In LogEvents Do
		LogEvent.Date = LogEvent.DateAtServer - ServerTimeOffset;
		
		// Filling numbers of row pictures.
		OwnerManager.SetPictureNumber(LogEvent);
		
		If AddAdditionalColumns Then
			// Filling additional fields that are defined for the owner only.
			OwnerManager.FillAdditionalEventColumns(LogEvent);
		EndIf;
		
		// Converting the array of metadata into a value list.
		MetadataPresentationList = New ValueList;
		If TypeOf(LogEvent.MetadataPresentation) = Type("Array") Then
			MetadataPresentationList.LoadValues(LogEvent.MetadataPresentation);
			LogEvent.MetadataPresentation = MetadataPresentationList;
		Else
			LogEvent.MetadataPresentation = String(LogEvent.MetadataPresentation);
		EndIf;
		
		// Converting the SessionDataSeparationPresentation array into a value list.
		If Common.DataSeparationEnabled()
			AND Not Common.SeparatedDataUsageAvailable() Then
			FullSessionDataSeparationPresentation = "";
			
			SessionDataSeparation = LogEvent.SessionDataSeparation;
			SeparatedDataAttributeList = New ValueList;
			For Each SessionSeparator In SessionDataSeparation Do
				SeparatorPresentation = Metadata.CommonAttributes.Find(SessionSeparator.Key).Synonym;
				SeparatorPresentation = SeparatorPresentation + " = " + SessionSeparator.Value;
				SeparatorValue = SessionSeparator.Key + "=" + SessionSeparator.Value;
				SeparatedDataAttributeList.Add(SeparatorValue, SeparatorPresentation);
				FullSessionDataSeparationPresentation = ?(Not IsBlankString(FullSessionDataSeparationPresentation),
				                                            FullSessionDataSeparationPresentation + "; ", "")
				                                            + SeparatorPresentation;
			EndDo;
			LogEvent.SessionDataSeparation = SeparatedDataAttributeList;
			LogEvent.SessionDataSeparationPresentation = FullSessionDataSeparationPresentation;
		EndIf;
		
		// Processing special event data.
		If LogEvent.Event = "_$Access$_.Access" Then
			SetDataAddressString(LogEvent);
			
			If LogEvent.Data <> Undefined Then
				LogEvent.Data = ?(LogEvent.Data.Data = Undefined, "", "...");
			EndIf;
			
		ElsIf LogEvent.Event = "_$Access$_.AccessDenied" Then
			SetDataAddressString(LogEvent);
			
			If LogEvent.Data <> Undefined Then
				If LogEvent.Data.Property("Right") Then
					LogEvent.Data = StringFunctionsClientServer.SubstituteParametersToString(
						NStr("ru = 'Право: %1'; en = 'Right: %1'; pl = 'Prawo: %1';de = 'Rechts: %1';ro = 'Dreapt: %1';tr = 'Hak: %1'; es_ES = 'Derecho: %1'"), 
						LogEvent.Data.Right);
				Else
					LogEvent.Data = StringFunctionsClientServer.SubstituteParametersToString(
						NStr("ru = 'Действие: %1%2'; en = 'Action: %1%2'; pl = 'Działanie: %1%2';de = 'Aktion: %1%2';ro = 'Acțiune: %1%2';tr = 'Işlem: %1%2'; es_ES = 'Acción: %1%2'"), 
						LogEvent.Data.Action, ?(LogEvent.Data.Data = Undefined, "", ", ...") );
				EndIf;
			EndIf;
			
		ElsIf LogEvent.Event = "_$Session$_.Authentication"
		      Or LogEvent.Event = "_$Session$_.AuthenticationError" Then
			
			SetDataAddressString(LogEvent);
			
			LogEventData = "";
			If LogEvent.Data <> Undefined Then
				For Each KeyAndValue In LogEvent.Data Do
					If ValueIsFilled(LogEventData) Then
						LogEventData = LogEventData + ", ...";
						Break;
					EndIf;
					LogEventData = KeyAndValue.Key + ": " + KeyAndValue.Value;
				EndDo;
			EndIf;
			LogEvent.Data = LogEventData;
			
		ElsIf LogEvent.Event = "_$User$_.Delete" Then
			SetDataAddressString(LogEvent);
			
			LogEventData = "";
			If LogEvent.Data <> Undefined Then
				For each KeyAndValue In LogEvent.Data Do
					LogEventData = KeyAndValue.Key + ": " + KeyAndValue.Value;
					Break;
				EndDo;
			EndIf;
			LogEvent.Data = LogEventData;
			
		ElsIf LogEvent.Event = "_$User$_.New"
		      OR LogEvent.Event = "_$User$_.Update" Then
			SetDataAddressString(LogEvent);
			
			IBUserName = "";
			If LogEvent.Data <> Undefined Then
				LogEvent.Data.Property("Name", IBUserName);
			EndIf;
			LogEvent.Data = StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = 'Имя: %1, ...'; en = 'Name: %1, ...'; pl = 'Nazwa: %1, ...';de = 'Name: %1, ...';ro = 'Nume: %1,...';tr = 'Isim: %1...'; es_ES = 'Nombre: %1, ...'"), IBUserName);
			
		EndIf;
		
		SetPrivilegedMode(True);
		// Processing special user name value.
		If LogEvent.User = New UUID("00000000-0000-0000-0000-000000000000") Then
			LogEvent.UserName = NStr("ru = '<Неопределен>'; en = '<Undefined>'; pl = '<nie zdefiniowany>';de = '<Undefiniert>';ro = '<Nedefinit>';tr = '<Tanımsız>'; es_ES = '<No definido>'");
			
		ElsIf LogEvent.UserName = "" Then
			LogEvent.UserName = Users.UnspecifiedUserFullName();
			
		ElsIf InfoBaseUsers.FindByUUID(LogEvent.User) = Undefined Then
			LogEvent.UserName = StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = '%1 <Удален>'; en = '%1 <Deleted>'; pl = '%1 <Usunięto>';de = '%1 <Entfernt>';ro = '%1 <Șters>';tr = '%1<Kaldırıldı>'; es_ES = '%1 <Eliminado>'"), LogEvent.UserName);
		EndIf;
		
		If ModuleSaaS <> Undefined Then
			If UserAliases.Get(LogEvent.User) = Undefined Then
				UserAlias = ModuleSaaS.InfobaseUserAlias(LogEvent.User);
				UserAliases.Insert(LogEvent.User, UserAlias);
			Else
				UserAlias = UserAliases.Get(LogEvent.User);
			EndIf;
			
			If ValueIsFilled(UserAlias) Then
				LogEvent.UserName = UserAlias;
			EndIf;
		EndIf;
		
		// Converting the UUID into a name. Further this name will be used in filter settings.
		LogEvent.User = InfoBaseUsers.FindByUUID(LogEvent.User);
		SetPrivilegedMode(False);
	EndDo;
	
	// Successful completion
	Result = New Structure;
	Result.Insert("LogEvents", LogEvents);
	
	PutToTempStorage(Result, StorageAddress);
EndProcedure

// Creates a custom event log presentation.
//
// Parameters:
//  FilterPresentation - String - the string that contains user presentation of the filter.
//  EventLogFilter - Structure - values of the event log filter.
//  DefaultEventLogFilter - Structure - default values of the event log filter (not included in the 
//     user presentation).
//
Procedure GenerateFilterPresentation(FilterPresentation, EventLogFilter, 
		DefaultEventLogFilter = Undefined) Export
	
	FilterPresentation = "";
	// Interval
	PeriodStartDate    = Undefined;
	PeriodEndDate = Undefined;
	If Not EventLogFilter.Property("StartDate", PeriodStartDate)
		Or PeriodStartDate = Undefined Then
		PeriodStartDate    = '00010101000000';
	EndIf;
	
	If Not EventLogFilter.Property("EndDate", PeriodEndDate)
		Or PeriodEndDate = Undefined Then
		PeriodEndDate = '00010101000000';
	EndIf;
	
	If Not (PeriodStartDate = '00010101000000' AND PeriodEndDate = '00010101000000') Then
		FilterPresentation = PeriodPresentation(PeriodStartDate, PeriodEndDate);
	EndIf;
	
	AddRestrictionToFilterPresentation(EventLogFilter, FilterPresentation, "User");
	AddRestrictionToFilterPresentation(EventLogFilter, FilterPresentation,
		"Event", DefaultEventLogFilter);
	AddRestrictionToFilterPresentation(EventLogFilter, FilterPresentation,
		"ApplicationName", DefaultEventLogFilter);
	AddRestrictionToFilterPresentation(EventLogFilter, FilterPresentation, "Session");
	AddRestrictionToFilterPresentation(EventLogFilter, FilterPresentation, "Level");
	
	// All other restrictions are specified by presentations without values.
	For Each FilterItem In EventLogFilter Do
		RestrictionName = FilterItem.Key;
		If Upper(RestrictionName) = Upper("StartDate")
			Or Upper(RestrictionName) = Upper("EndDate")
			Or Upper(RestrictionName) = Upper("Event")
			Or Upper(RestrictionName) = Upper("ApplicationName")
			Or Upper(RestrictionName) = Upper("User")
			Or Upper(RestrictionName) = Upper("Session")
			Or Upper(RestrictionName) = Upper("Level") Then
			Continue; // Interval and special restrictions are already displayed.
		EndIf;
		
		// Changing restrictions for some of presentations.
		If Upper(RestrictionName) = Upper("ApplicationName") Then
			RestrictionName = NStr("ru = 'Приложение'; en = 'Application'; pl = 'Załącznik';de = 'Anwendung';ro = 'Aplicația';tr = 'Uygulama'; es_ES = 'Aplicación'");
		ElsIf Upper(RestrictionName) = Upper("TransactionStatus") Then
			RestrictionName = NStr("ru = 'Статус транзакции'; en = 'Transaction status'; pl = 'Status transakcji';de = 'Transaktionsstatus';ro = 'Statutul tranzacției';tr = 'Işlem statüsü'; es_ES = 'Estado de transacción'");
		ElsIf Upper(RestrictionName) = Upper("DataPresentation") Then
			RestrictionName = NStr("ru = 'Представление данных'; en = 'Data presentation'; pl = 'Prezentacja danych';de = 'Datenpräsentation';ro = 'Prezentarea datelor';tr = 'Veri gösterimi'; es_ES = 'Presentación de datos'");
		ElsIf Upper(RestrictionName) = Upper("ServerName") Then
			RestrictionName = NStr("ru = 'Рабочий сервер'; en = 'Working server'; pl = 'Serwer';de = 'Arbeitsserver';ro = 'Server de lucru';tr = 'Çalışma sunucusu'; es_ES = 'Servidor en función'");
		ElsIf Upper(RestrictionName) = Upper("Port") Then
			RestrictionName = NStr("ru = 'Основной IP порт'; en = 'IP port'; pl = 'Podstawowy IP port';de = 'Primärer IP-Port';ro = 'Port IP primar';tr = 'Ana IP portu'; es_ES = 'Puerto IP primario'");
		ElsIf Upper(RestrictionName) = Upper("SyncPort") Then
			RestrictionName = NStr("ru = 'Вспомогательный IP порт'; en = 'Auxiliary IP port'; pl = 'Pomocniczy IP port';de = 'Port synchronisieren';ro = 'Portul IP auxiliar';tr = 'Senk portu'; es_ES = 'Puerto sincronizado'");
		ElsIf Upper(RestrictionName) = Upper("SessionDataSeparation") Then
			RestrictionName = NStr("ru = 'Разделение данных сеанса'; en = 'Session data separation'; pl = 'Separacja danych sesji';de = 'Sitzungsdatentrennung';ro = 'Sesiunea de separare a datelor';tr = 'Oturum veri ayırma'; es_ES = 'Sesión separación de datos'");
		EndIf;
		
		If Not IsBlankString(FilterPresentation) Then 
			FilterPresentation = FilterPresentation + "; ";
		EndIf;
		FilterPresentation = FilterPresentation + RestrictionName;
		
	EndDo;
	
	If IsBlankString(FilterPresentation) Then
		FilterPresentation = NStr("ru = 'Не установлен'; en = 'Not set'; pl = 'Nieustawiony';de = 'Nicht eingestellt';ro = 'Nu este setat';tr = 'Belirlenmedi'; es_ES = 'No definido'");
	EndIf;
	
EndProcedure

// For internal use only.
//
Procedure PutDataInTempStorage(LogEvents, UUID) Export
	
	For Each EventRow In LogEvents Do
		If IsBlankString(EventRow.DataAddress) Then
			DataAddress = "";
		Else
			XMLReader = New XMLReader();
			XMLReader.SetString(EventRow.DataAddress);
			DataAddress = XDTOSerializer.ReadXML(XMLReader);
		EndIf;
		EventRow.DataAddress = PutToTempStorage(DataAddress, UUID);
	EndDo;
	
EndProcedure

// Determines the server time offset relative to the application time.
//
// Returns:
//   Number - time offset, in seconds.
//       Can be used to convert log filters to the server date and also to convert dates obtained 
//       from the log to the application dates.
//
Function ServerTimeOffset() Export
	
	ServerTimeOffset = CurrentDate() - CurrentSessionDate();
	If ServerTimeOffset >= -1 AND ServerTimeOffset <= 1 Then
		ServerTimeOffset = 0;
	EndIf;
	Return ServerTimeOffset;
	
EndFunction

#EndRegion

#Region Private

// Filter transformation.
//
// Parameters:
//  Filter - Filter - the filter to be passed.
//
Procedure FilterTransformation(Filter, ServerTimeOffset)
	
	For Each FilterItem In Filter Do
		If TypeOf(FilterItem.Value) = Type("ValueList") Then
			FilterItemTransform(Filter, FilterItem);
		ElsIf Upper(FilterItem.Key) = Upper("TransactionID") Then
			If StrFind(FilterItem.Value, "(") = 0 Then
				Filter.Insert(FilterItem.Key, "(" + FilterItem.Value);
			EndIf;
		ElsIf ServerTimeOffset <> 0
			AND (Upper(FilterItem.Key) = Upper("StartDate") Or Upper(FilterItem.Key) = Upper("EndDate")) Then
			Filter.Insert(FilterItem.Key, FilterItem.Value + ServerTimeOffset);
		EndIf;
	EndDo;
	
EndProcedure

// Filter item transformation.
//
// Parameters:
//  Filter - Filter - the filter to be passed.
//  Filter - Filter item - item of the filter to be passed.
//
Procedure FilterItemTransform(Filter, FilterItem)
	
	FilterStructureKey = FilterItem.Key;
	// Is called if a filter item is a value list.
	//  Transforming the value list into an array because the filter cannot process a list.
	If Upper(FilterStructureKey) = Upper("SessionDataSeparation") Then
		NewValue = New Structure;
	Else
		NewValue = New Array;
	EndIf;
	
	FilterStructureKey = FilterItem.Key;
	
	For Each ValueFromList In FilterItem.Value Do
		If Upper(FilterStructureKey) = Upper("Level") Then
			// Message text level is a string, it must be converted into an enumeration.
			NewValue.Add(DataProcessors.EventLog.EventLogLevelValueByName(ValueFromList.Value));
		ElsIf Upper(FilterStructureKey) = Upper("TransactionStatus") Then
			// Transaction status is a string, it must be converted into an enumeration.
			NewValue.Add(DataProcessors.EventLog.EventLogEntryTransactionStatusValueByName(ValueFromList.Value));
		ElsIf Upper(FilterStructureKey) = Upper("SessionDataSeparation") Then
			SeparatorValueArray = New Array;
			FilterStructureKey = "SessionDataSeparation";
			DataSeparationArray = StrSplit(ValueFromList.Value, "=", True);
			
			SeparatorValues = StrSplit(DataSeparationArray[1], ",", True);
			For Each SeparatorValue In SeparatorValues Do
				SeparatorFilterItem = New Structure("Value, Use", Number(SeparatorValue), True);
				SeparatorValueArray.Add(SeparatorFilterItem);
			EndDo;
			
			NewValue.Insert(DataSeparationArray[0], SeparatorValueArray);
			
		Else
			FilterValues = StringFunctionsClientServer.SplitStringIntoSubstringsArray(ValueFromList.Value, Chars.LF);
			For Each FilterValue In FilterValues Do
				NewValue.Add(FilterValue);
			EndDo;
		EndIf;
	EndDo;
	
	Filter.Insert(FilterItem.Key, NewValue);
	
EndProcedure

// Adds a restriction to the filter presentation.
//
// Parameters:
//  EventLogFilter - Filter - the event log filter.
//  FilterPresentation - String - presentation of the filter.
//  RestrictionName - String - the name of the restriction.
//  DefaultEventLogFilter - Filter - the default event log filter.
//
Procedure AddRestrictionToFilterPresentation(EventLogFilter, FilterPresentation, RestrictionName,
	DefaultEventLogFilter = Undefined)
	
	If Not EventLogFilter.Property(RestrictionName) Then
		Return;
	EndIf;
	
	RestrictionList = EventLogFilter[RestrictionName];
	Restriction       = "";
	
	// If filter value is a default value there is no need to get a presentation of it.
	If DefaultEventLogFilter <> Undefined Then
		DefaultRestrictionList = "";
		If DefaultEventLogFilter.Property(RestrictionName, DefaultRestrictionList) 
			AND CommonClientServer.ValueListsAreEqual(DefaultRestrictionList, RestrictionList) Then
			Return;
		EndIf;
	EndIf;
	
	If RestrictionName = "Event" AND RestrictionList.Count() > 5 Then
		
		Restriction = StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = 'События (%1)'; en = 'Events (%1)'; pl = 'Zdarzenia (%1)';de = 'Ereignisse (%1)';ro = 'Evenimente (%1)';tr = 'Olaylar (%1)'; es_ES = 'Eventos (%1)'"), RestrictionList.Count());
		
	ElsIf RestrictionName = "Session" AND RestrictionList.Count() > 3 Then
		
		Restriction = StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = 'Сеансы (%1)'; en = 'Sessions (%1)'; pl = 'Sesje (%1)';de = 'Sitzungen (%1)';ro = 'Sesiuni (%1)';tr = 'Oturumlar (%1)'; es_ES = 'Sesiones (%1)'"), RestrictionList.Count());
		
	Else
		
		For Each ListItem In RestrictionList Do
			
			If Not IsBlankString(Restriction) Then
				Restriction = Restriction + ", ";
			EndIf;
			
			If (Upper(RestrictionName) = Upper("Session")
			OR Upper(RestrictionName) = Upper("Level"))
			AND IsBlankString(Restriction) Then
			
				Restriction = NStr("ru = '[RestrictionName]: [Value]'; en = '[RestrictionName]: [Value]'; pl = '[RestrictionName]: [Value]';de = '[RestrictionName]: [Value]';ro = '[RestrictionName]: [Value]';tr = '[RestrictionName]: [Value]'; es_ES = '[RestrictionName]: [Value]'");
				Restriction = StrReplace(Restriction, "[Value]", ListItem.Value);
				Restriction = StrReplace(Restriction, "[RestrictionName]", RestrictionName);
				
			ElsIf Upper(RestrictionName) = Upper("Session")
			OR Upper(RestrictionName) = Upper("Level")Then
				Restriction = Restriction + ListItem.Value;
			Else
				Restriction = Restriction + ListItem.Presentation;
			EndIf;
			
		EndDo;
		
	EndIf;
	
	If Not IsBlankString(FilterPresentation) Then 
		FilterPresentation = FilterPresentation + "; ";
	EndIf;
	
	FilterPresentation = FilterPresentation + Restriction;
	
EndProcedure

Function TechnicalSupportLog(EventLogFilter, EventCount, UUID = Undefined) Export
	
	Filter = New Structure;
	For Each FilterItem In EventLogFilter Do
		Filter.Insert(FilterItem.Key, FilterItem.Value);
	EndDo;
	ServerTimeOffset = ServerTimeOffset();
	FilterTransformation(Filter, ServerTimeOffset);
	
	// Exporting the selected events and generating the table structure.
	TempFile = GetTempFileName("xml");
	UnloadEventLog(TempFile, Filter, , , EventCount);
	BinaryData = New BinaryData(TempFile);
	DeleteFiles(TempFile);
	
	Return PutToTempStorage(BinaryData, UUID);
	
EndFunction

////////////////////////////////////////////////////////////////////////////////
// Auxiliary procedures and functions.

// For internal use only.
//
Procedure SetDataAddressString(LogEvent)
	
	XMLWriter = New XMLWriter();
	XMLWriter.SetString();
	XDTOSerializer.WriteXML(XMLWriter, LogEvent.Data); 
	LogEvent.DataAddress = XMLWriter.Close();
	
EndProcedure

Function EventLevelByPresentation(LevelPresentation)
	If LevelPresentation = "Information" Then
		Return EventLogLevel.Information;
	ElsIf LevelPresentation = "Error" Then
		Return EventLogLevel.Error;
	ElsIf LevelPresentation = "Warning" Then
		Return EventLogLevel.Warning; 
	ElsIf LevelPresentation = "Note" Then
		Return EventLogLevel.Note;
	EndIf;	
EndFunction

#EndRegion
