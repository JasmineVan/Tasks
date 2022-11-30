///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Public

// Updates a full-text search index.
Procedure FullTextSearchIndexUpdate() Export
	
	UpdateIndex(NStr("ru = 'Обновление индекса ППД'; en = 'Update full-text search index'; pl = 'Aktualizacja indeksu wyszukiwania pełnotekstowego';de = 'Aktualisieren Sie den Volltextsuchindex';ro = 'Actualizarea indexului de căutare full-text';tr = 'Tam metin arama dizinini güncelle.'; es_ES = 'Actualizar el índice de la búsqueda del texto completo'"), False, True);
	
EndProcedure

// Merges full-text search indexes.
Procedure FullTextSearchMergeIndex() Export
	
	UpdateIndex(NStr("ru = 'Слияние индекса ППД'; en = 'Merge full-text search index'; pl = 'Łączenie indeksu wyszukiwania pełnotekstowego.';de = 'Zusammenführen des Volltextsuchindex';ro = 'Fuzionarea indexului de căutare full-text';tr = 'Tam metin arama dizinini birleştirme.'; es_ES = 'Combinando el índice de la búsqueda del texto completo.'"), True);
	
EndProcedure

// Returns a flag showing whether full-text search index is up-to-date.
//   The UseFullTextSearch functional option is checked in the calling code.
//
// Returns:
//   Boolean - True - full-text search contains relevant data.
//
Function SearchIndexIsRelevant() Export
	
	Status = FullTextSearchStatus();
	Return Status = "SearchAllowed";
	
EndFunction

// Flag status for the full text search setting form.
//
// Returns:
//   Number - 0 - disabled, 1 - enabled, 2 - setting error, settings are not synchronized.
//
// Example:
//	If Common.SubsystemExists("StandardSubsystems.FullTextSearch") Then
//		ModuleFullTextSearchServer = Common.CommonModule("FullTextSearchServer");
//		UseFullTextSearch = ModuleFullTextSearchServer.UseSearchFlagValue();
//	Else
//		Items.FullTextSearchManagementGroup.Visibility = False;
//	EndIf;
//
Function UseSearchFlagValue() Export
	
	Status = FullTextSearchStatus();
	If Status = "SearchProhibited" Then
		Result = 0;
	ElsIf Status = "SearchSettingsError" Then
		Result = 2;
	Else
		Result = 1;
	EndIf;
	
	Return Result;
	
EndFunction

#EndRegion

#Region Internal

// Returns the current full text search status depending on settings and relevance.
// Does not throw exceptions.
//
// Returns:
//  String - options
//    - SearchAllowed
//    - SearchProhibited
//    - UpdatingIndex
//    - IndexMergeInProgress
//    - IndexUpdateRequired
//    - SearchSettingsError
//
Function FullTextSearchStatus() Export
	
	If GetFunctionalOption("UseFullTextSearch") Then 
		
		If FullTextSearch.GetFullTextSearchMode() = FullTextSearchMode.Enable Then 
			
			If CurrentDate() < (FullTextSearch.UpdateDate() + 300) Then 
				Return "SearchAllowed";
			Else
				If FullTextSearchIndexIsUpToDate() Then 
					Return "SearchAllowed";
				ElsIf IndexUpdateBackgroundJobInProgress() Then 
					Return "IndexUpdateInProgress";
				ElsIf MergeIndexBackgroundJobInProgress() Then 
					Return "IndexMergeInProgress";
				Else
					Return "IndexUpdateRequired";
				EndIf;
			EndIf;
			
		Else 
			// The value of the UseFullTextSearch constant is not synchronized with the full-text search mode 
			// set in the infobase.
			Return "SearchSettingsError";
		EndIf;
		
	Else
		If FullTextSearch.GetFullTextSearchMode() = FullTextSearchMode.Enable Then
			// The value of the UseFullTextSearch constant is not synchronized with the full-text search mode 
			// set in the infobase.
			Return "SearchSettingsError";
		Else 
			Return "SearchProhibited";
		EndIf;
	EndIf;
	
EndFunction

// Sets the order of search sections for the FullTextSearchServerOverridable.
// OnGetFullTextSearchSections event
//
// Parameters:
//   SearchSections - ValueTree - search areas. Contains the following columns:
//       ** Section   - String   - a presentation of a section: subsystem or metadata object.
//       ** Picture - Picture - a section picture, recommended only for root sections.
//       ** MetadataObject - CatalogRef.MetadataObjectsIDs - specified only for metadata objects, 
//                     leave it blank for sections.
//   SectionsOrder - Array - synonyms of section subsystems. The higher the index is, the lower the section is in the list.
//
Procedure SetFullTextSearchSectionsOrder(SearchSections, SectionsOrder) Export
	
	OrderColumn = SearchSections.Columns.Add("Order");
	
	For Index = 0 To SectionsOrder.UBound() Do
		SectionName = SectionsOrder[Index];
		RowSection = SearchSections.Rows.Find(SectionName, "Section");
		If RowSection <> Undefined Then
			RowSection.Order = Index;
		EndIf;
	EndDo;
	
	SearchSections.Rows.Sort("Order");
	SearchSections.Columns.Delete(OrderColumn);
	
EndProcedure

// Metadata object with functional option of full text search usage.
//
// Returns:
//   MetadataObjectFunctionalOption - a functional option metadata
//
Function UseFullTextSearchFunctionalOption() Export
	
	Return Metadata.FunctionalOptions.UseFullTextSearch;
	
EndFunction

#Region ConfigurationSubsystemsEventHandlers

// See ToDoListOverridable.OnDetermineToDoListHandlers 
Procedure OnFillToDoList(ToDoList) Export
	
	If Not Users.IsFullUser(, True) Then 
		Return;
	EndIf;
	
	ModuleToDoListServer = Common.CommonModule("ToDoListServer");
	If ModuleToDoListServer.UserTaskDisabled("FullTextSearchInData") Then
		Return;
	EndIf;
	
	Status = FullTextSearchStatus();
	If Status = "SearchProhibited" Then 
		Return;
	EndIf;
	
	Section = Metadata.Subsystems.Find("Administration");
	If Section = Undefined Then
		Sections = ModuleToDoListServer.SectionsForObject(Metadata.DataProcessors.FullTextSearchInData.FullName());
		If Sections.Count() = 0 Then 
			Return;
		Else 
			Section = Sections[0];
		EndIf;
	EndIf;
	
	// Search setup error
	
	ToDoItem = ToDoList.Add();
	ToDoItem.ID = "FullTextSearchInDataSearchSettingsError";
	ToDoItem.HasToDoItems = (Status = "SearchSettingsError");
	ToDoItem.Presentation = NStr("ru = 'Ошибка настройки полнотекстового поиска'; en = 'Full-text search setup error'; pl = 'Błąd podczas ustawiania wyszukiwania pełnotekstowego';de = 'Fehler bei der Einstellung der Volltextsuche';ro = 'Erori de setare a căutării full-text';tr = 'Tam metin araması ayarlanırken hata oluştu'; es_ES = 'Error de ajustar la búsqueda de texto completo'");
	ToDoItem.Form = "DataProcessor.FullTextSearchInData.Form.FullTextSearchAndTextExtractionControl";
	ToDoItem.ToolTip = 
		NStr("ru = 'Рассинхронизация значения константы ИспользоватьПолнотекстовыйПоиск
		           |и установленного режима полнотекстового поиска в информационной базе.
		           |Попробуйте выключить полнотекстовый поиск и снова включить.'; 
		           |en = 'The value of the UseFullTextSearch constant and
		           |the full-text search mode setting are not synchronized.
		           |Try to turn full-text search off and turn it on again.'; 
		           |pl = 'Desynchronizacja wartości stałej ИспользоватьПолнотекстовыйПоиск
		           |i ustalonego trybu wyszukiwania pełnotekstowego w bazie informacyjnej.
		           |Spróbuj wyłączyć wyszukiwanie pełnotekstowe, a następnie z powrotem włączyć.';
		           |de = 'Dissynchronisation des Wertes der Konstanten VolltextsucheVerwenden
		           |des eingestellten Modus der Volltextsuche in der Informationsdatenbank.
		           |Versuchen Sie, die Volltextsuche zu deaktivieren und wieder zu aktivieren.';
		           |ro = 'Desincronizare a valorii constantei ИспользоватьПолнотекстовыйПоиск
		           |și a regimului instalat de căutare full-text în baza de informații.
		           |Încercați să dezactivați căutarea full-text și s-o activați din nou.';
		           |tr = 'Sabit değerinin zaman uyumsuzluğu Tam metin aramalarını bilgi tabanında kurulu 
		           |tam metin arama modunu kullanın
		           | Tam metin aramasını kapatıp tekrar açmayı deneyin.'; 
		           |es_ES = 'Desincronización del valor del constante ИспользоватьПолнотекстовыйПоиск
		           |y del modo instalado de búsqueda de texto completo en la base de información.
		           |Pruebe de desactiva la búsqueda de texto completo y activarla de nuevo.'");
	ToDoItem.Owner = Section;
	
	// Index update is required
	
	If Status = "IndexUpdateRequired" Then 
		IndexUpdateDate = FullTextSearch.UpdateDate();
		CurrentDate = CurrentDate(); // Exception, use CurrentDate().
		
		If IndexUpdateDate > CurrentDate Then
			Interval = NStr("ru = 'менее одного дня назад'; en = 'less than one day ago'; pl = 'mniej, niż jeden dzień wstecz';de = 'vor weniger als einem Tag';ro = 'mai puțin de o zi în urmă';tr = 'bir günden az önce'; es_ES = 'menos de un día atrás'");
		Else
			Interval = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = '%1 назад'; en = '%1 ago'; pl = '%1 wstecz';de = '%1 zurück';ro = '%1 în urmă';tr = '%1 geri'; es_ES = '%1 atrás'"),
				Common.TimeIntervalString(IndexUpdateDate, CurrentDate));
		EndIf;
		
		DaysFromLastUpdate = Int((CurrentDate - IndexUpdateDate) / 60 / 60 / 24);
		HasToDoItems = (DaysFromLastUpdate >= 1);
	Else 
		Interval = NStr("ru = 'Никогда'; en = 'never'; pl = 'Nigdy';de = 'Niemals';ro = 'Niciodată';tr = 'Hiç bir zaman'; es_ES = 'Nunca'");
		HasToDoItems = False;
	EndIf;
	
	ToDoItem = ToDoList.Add();
	ToDoItem.ID = "FullTextSearchInDataIndexUpdateRequired";
	ToDoItem.HasToDoItems = HasToDoItems;
	ToDoItem.Presentation = NStr("ru = 'Индекс полнотекстового поиска устарел'; en = 'Full-text search index is outdated'; pl = 'Indeks wyszukiwania pełnotekstowego jest nieaktualny';de = 'Der Volltextsuchindex ist veraltet';ro = 'Indexul de căutare integrală este depășit';tr = 'Tam metin arama dizini eskidi'; es_ES = 'Índice de la búsqueda de texto completo está desactualizada'");
	ToDoItem.Form = "DataProcessor.FullTextSearchInData.Form.FullTextSearchAndTextExtractionControl";
	ToDoItem.ToolTip = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("ru = 'Последнее обновление %1'; en = 'Last update: %1.'; pl = 'Ostatnia aktualizacja %1';de = 'Letztes Update %1';ro = 'Ultima actualizare %1';tr = 'Son güncelleme%1'; es_ES = 'Última actualización %1'"),
		Interval);
	ToDoItem.Owner = Section;
	
EndProcedure

// See InfobaseUpdateSSL.OnAddUpdateHandlers. 
Procedure OnAddUpdateHandlers(Handlers) Export
	
	Handler = Handlers.Add();
	Handler.InitialFilling = True;
	Handler.Procedure = "FullTextSearchServer.InitializeFullTextSearchFunctionalOption";
	Handler.Version = "1.0.0.1";
	Handler.SharedData = True;
	
EndProcedure

// See ScheduledJobsOverridable.OnDefineScheduledJobsSettings. 
Procedure OnDefineScheduledJobSettings(Dependencies) Export
	
	Dependence = Dependencies.Add();
	Dependence.ScheduledJob = Metadata.ScheduledJobs.FullTextSearchIndexUpdate;
	Dependence.FunctionalOption = UseFullTextSearchFunctionalOption();
	
	Dependence = Dependencies.Add();
	Dependence.ScheduledJob = Metadata.ScheduledJobs.FullTextSearchMergeIndex;
	Dependence.FunctionalOption = UseFullTextSearchFunctionalOption();
	
EndProcedure

#EndRegion

// Sets a value of the UseFullTextSearch constant.
//   Used to synchronize a value of the UseFullTextSearch functional option
//   
//   with the FullTextSearch.GetFullTextSearchMode() function value.
//
Procedure InitializeFullTextSearchFunctionalOption() Export
	
	OperationsAllowed = (FullTextSearch.GetFullTextSearchMode() = FullTextSearchMode.Enable);
	Constants.UseFullTextSearch.Set(OperationsAllowed);
	
EndProcedure

#EndRegion

#Region Private

#Region ScheduledJobsHandlers

// Handler of the FullTextSearchUpdateIndex scheduled job.
Procedure FullTextSearchUpdateIndexOnSchedule() Export
	
	Common.OnStartExecuteScheduledJob(Metadata.ScheduledJobs.FullTextSearchIndexUpdate);
	
	If MergeIndexBackgroundJobInProgress() Then
		Return;
	EndIf;
	
	FullTextSearchIndexUpdate();
	
EndProcedure

// Handler of the FullTextSearchMergeIndex scheduled job.
Procedure FullTextSearchMergeIndexOnSchedule() Export
	
	Common.OnStartExecuteScheduledJob(Metadata.ScheduledJobs.FullTextSearchMergeIndex);
	
	If IndexUpdateBackgroundJobInProgress() Then
		Return;
	EndIf;
	
	FullTextSearchMergeIndex();
	
EndProcedure

#EndRegion

#Region SearchBusinessLogic

#Region SearchState

Function IndexUpdateBackgroundJobInProgress()
	
	ScheduledJob = Metadata.ScheduledJobs.FullTextSearchIndexUpdate;
	
	Filter = New Structure;
	Filter.Insert("MethodName", ScheduledJob.MethodName);
	Filter.Insert("State", BackgroundJobState.Active);
	CurrentBackgroundJobs = BackgroundJobs.GetBackgroundJobs(Filter);
	
	Return CurrentBackgroundJobs.Count() > 0;
	
EndFunction

Function MergeIndexBackgroundJobInProgress()
	
	ScheduledJob = Metadata.ScheduledJobs.FullTextSearchMergeIndex;
	
	Filter = New Structure;
	Filter.Insert("MethodName", ScheduledJob.MethodName);
	Filter.Insert("State", BackgroundJobState.Active);
	CurrentBackgroundJobs = BackgroundJobs.GetBackgroundJobs(Filter);
	
	Return CurrentBackgroundJobs.Count() > 0;
	
EndFunction

Function FullTextSearchIndexIsUpToDate()
	
	UpToDate = False;
	
	Try
		UpToDate = FullTextSearch.IndexTrue();
	Except
		LogRecord(
			EventLogLevel.Warning, 
			NStr("ru = 'Не удалось проверить состояние индекса полнотекстового поиска'; en = 'Failed to check full-text search index status'; pl = 'Nie można sprawdzić statusu indeksu wyszukiwania pełnotekstowego';de = 'Der Status des Volltextsuchindex konnte nicht überprüft werden';ro = 'Eșec la verificarea statutului indexului de căutare full-text';tr = 'Tam metin arama dizininin durumu kontrol edilemedi.'; es_ES = 'No se ha podido comprobar el estado del índica de búsqueda de texto completo'"),
			ErrorInfo());
	EndTry;
	
	Return UpToDate;
	
EndFunction

#EndRegion

#Region ExecuteSearch

Function SearchParameters() Export 
	
	Parameters = New Structure;
	Parameters.Insert("SearchString", "");
	Parameters.Insert("SearchDirection", "FirstPart");
	Parameters.Insert("CurrentPosition", 0);
	Parameters.Insert("SearchInSections", False);
	Parameters.Insert("SearchAreas", New Array);
	
	Return Parameters;
	
EndFunction

Function ExecuteFullTextSearch(SearchParameters) Export 
	
	SearchString = SearchParameters.SearchString;
	Direction = SearchParameters.SearchDirection;
	CurrentPosition = SearchParameters.CurrentPosition;
	SearchInSections = SearchParameters.SearchInSections;
	SearchAreas = SearchParameters.SearchAreas;
	
	BatchSize = 10;
	ErrorDescription = "";
	ErrorCode = "";
	
	SearchList = FullTextSearch.CreateList(SearchString, BatchSize);
	
	If SearchInSections AND SearchAreas.Count() > 0 Then
		SearchList.MetadataUse = FullTextSearchMetadataUse.DontUse;
		
		For Each Area In SearchAreas Do
			MetadataObject = Common.MetadataObjectByID(Area.Value, False);
			If TypeOf(MetadataObject) = Type("MetadataObject") Then 
				SearchList.SearchArea.Add(MetadataObject);
			EndIf;
		EndDo;
	EndIf;
	
	Try
		If Direction = "FirstPart" Then
			SearchList.FirstPart();
		ElsIf Direction = "PreviousPart" Then
			SearchList.PreviousPart(CurrentPosition);
		ElsIf Direction = "NextPart" Then
			SearchList.NextPart(CurrentPosition);
		Else 
			Raise NStr("ru = 'Параметр НаправлениеПоиска задан неверно.'; en = 'Invalid SearchDirection parameter.'; pl = 'Parametr НаправлениеПоиска jest podany błędnie.';de = 'Der Parameter SuchRichtung ist nicht korrekt eingestellt.';ro = 'Parametrul DirecțiaDeCăutare este specificat incorect.';tr = 'AramaYönü parametresi yanlış girilmiştir.'; es_ES = 'Parámetro SearchDirection está especificado incorrectamente.'");
		EndIf;
	Except
		ErrorDescription = BriefErrorDescription(ErrorInfo());
		ErrorCode = "SearchError";
	EndTry;
	
	If SearchList.TooManyResults() Then 
		ErrorDescription = NStr("ru = 'Слишком много результатов, уточните запрос'; en = 'Too many results, refine the search query.'; pl = 'Zbyt dużo wyników, uściślij zapytanie';de = 'Zu viele Ergebnisse, verfeinern Sie die Anfrage';ro = 'Prea multe rezultate, concretizați interogarea';tr = 'Çok fazla sonuç var, aramanızı netleştirin'; es_ES = 'Hay demasiados resultados, refinar los criterios de su búsqueda'");
		ErrorCode = "TooManyResults";
	EndIf;
	
	TotalCount = SearchList.TotalCount();
	
	If TotalCount = 0 Then
		ErrorDescription = NStr("ru = 'По запросу ничего не найдено'; en = 'No results found'; pl = 'Brak rezultatów wyszukiwania';de = 'Keine Ergebnisse gefunden';ro = 'Nici un rezultat gasit';tr = 'Sonuç bulunamadı'; es_ES = 'No hay resultados encontrados'");
		ErrorCode = "FoundNothing";
	EndIf;
	
	If IsBlankString(ErrorCode) Then 
		SearchResults = FullTextSearchResults(SearchList);
	Else 
		SearchResults = New Array;
	EndIf;
	
	Result = New Structure;
	Result.Insert("CurrentPosition", SearchList.StartPosition());
	Result.Insert("Count", SearchList.Count());
	Result.Insert("TotalCount", TotalCount);
	Result.Insert("ErrorCode", ErrorCode);
	Result.Insert("ErrorDescription", ErrorDescription);
	Result.Insert("SearchResults", SearchResults);
	
	Return Result;
	
EndFunction

Function FullTextSearchResults(SearchList)
	
	// Parse the list by separating an HTML details block.
	HTMLSearchStrings = HTMLSearchResultStrings(SearchList);
	
	Result = New Array;
	
	// Bypass search list strings.
	For Index = 0 To SearchList.Count() - 1 Do
		
		HTMLDetails  = HTMLSearchStrings.HTMLDetails.Get(Index);
		Presentation = HTMLSearchStrings.Presentations.Get(Index);
		SearchListString = SearchList.Get(Index);
		
		ObjectMetadata = SearchListString.Metadata;
		Value = SearchListString.Value;
		
		Overridable_OnGetByFullTextSearch(ObjectMetadata, Value, Presentation);
		
		Ref = "";
		Try
			Ref = GetURL(Value);
		Except
			Ref = "#"; // It is not to be opened.
		EndTry;
		
		ResultString = New Structure;
		ResultString.Insert("Ref",        Ref);
		ResultString.Insert("HTMLDetails",  HTMLDetails);
		ResultString.Insert("Presentation", Presentation);
		
		Result.Add(ResultString);
		
	EndDo;
	
	Return Result;
	
EndFunction

Function HTMLSearchResultStrings(SearchList)
	
	HTMLListDisplay = SearchList.GetRepresentation(FullTextSearchRepresentationType.HTMLText);
	
	// Get DOM to display the list.
	// You cannot make this function as a separate function for getting DOM due to a platform error occurred in the call stack of the DOM reader stream.
	HTMLReader = New HTMLReader;
	HTMLReader.SetString(HTMLListDisplay);
	DOMBuilder = New DOMBuilder;
	DOMListDisplay = DOMBuilder.Read(HTMLReader);
	HTMLReader.Close();
	
	DivDOMItemsList = DOMListDisplay.GetElementByTagName("div");
	HTMLDetailsStrings = HTMLDetailsStrings(DivDOMItemsList);
	
	AnchorDOMItemsList = DOMListDisplay.GetElementByTagName("a");
	PresentationStrings = PresentationStrings(AnchorDOMItemsList);
	
	Result = New Structure;
	Result.Insert("HTMLDetails", HTMLDetailsStrings);
	Result.Insert("Presentations", PresentationStrings);
	
	Return Result;
	
EndFunction

Function HTMLDetailsStrings(DivDOMItemsList)
	
	HTMLDetailsStrings = New Array;
	For Each DOMElement In DivDOMItemsList Do 
		
		If DOMElement.ClassName = "textPortion" Then 
			
			DOMWriter = New DOMWriter;
			HTMLWriter = New HTMLWriter;
			HTMLWriter.SetString();
			DOMWriter.Write(DOMElement, HTMLWriter);
			
			HTMLResultStringDetails = HTMLWriter.Close();
			
			HTMLDetailsStrings.Add(HTMLResultStringDetails);
			
		EndIf;
	EndDo;
	
	Return HTMLDetailsStrings;
	
EndFunction

Function PresentationStrings(AnchorDOMItemsList)
	
	PresentationStrings = New Array;
	For Each DOMElement In AnchorDOMItemsList Do
		
		Presentation = DOMElement.TextContent;
		PresentationStrings.Add(Presentation);
		
	EndDo;
	
	Return PresentationStrings;
	
EndFunction

// Allows to override:
// - Value
// - Presentation
//
// See the FullTextSearchListItem data type.
//
Procedure Overridable_OnGetByFullTextSearch(ObjectMetadata, Value, Presentation)
	
	If Common.SubsystemExists("StandardSubsystems.Properties") Then 
		
		// To get additional info, open the form of the object the value belongs to and not the form of the 
		// record in the information register.
		
		If ObjectMetadata = Metadata.InformationRegisters["AdditionalInfo"] Then 
			
			Value = Value.Object;
			ObjectMetadata = Value.Metadata();
			
			Presentation = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = '%1: %2'; en = '%1: %2'; pl = '%1: %2';de = '%1: %2';ro = '%1: %2';tr = '%1: %2'; es_ES = '%1: %2'"), 
				ObjectMetadata.ObjectPresentation, 
				String(Value));
			
		EndIf;
		
	EndIf;
	
EndProcedure

#EndRegion

#Region SearchIndexUpdate

// Common procedure for updating and merging a full-text search index.
Procedure UpdateIndex(ProcedurePresentation, EnableJoining = False, InPortions = False)
	
	If (FullTextSearch.GetFullTextSearchMode() <> FullTextSearchMode.Enable) Then
		Return;
	EndIf;
	
	Common.OnStartExecuteScheduledJob();
	
	LogRecord(
		Undefined, 
		NStr("ru = 'Запуск процедуры ""%1"".'; en = 'Starting %1.'; pl = 'Rozpocząć procedurę ""%1"".';de = 'Starten Sie das ""%1"" Verfahren.';ro = 'Lansarea procedurii ""%1"".';tr = '""%1"" Prosedürünü başlatın.'; es_ES = 'Iniciar el procedimiento ""%1"".'"),,
		ProcedurePresentation);
	
	Try
		FullTextSearch.UpdateIndex(EnableJoining, InPortions);
		LogRecord(
			Undefined, 
			NStr("ru = 'Успешное завершение процедуры ""%1"".'; en = '%1 is successfully completed.'; pl = 'Procedura ""%1"" zakończona pomyślnie.';de = 'Die Prozedur ""%1"" wurde erfolgreich abgeschlossen.';ro = 'Procedura ""%1"" este finalizată cu succes.';tr = '""%1"" prosedürü başarı ile tamamlandı.'; es_ES = 'El procedimiento ""%1"" se ha finalizado con éxito.'"),, 
			ProcedurePresentation);
	Except
		LogRecord(
			EventLogLevel.Warning, 
			NStr("ru = 'Не удалось выполнить процедуру ""%1"":'; en = 'Failed to execute %1:'; pl = 'Procedura nie powiodła się ""%1"":';de = 'Der Vorgang ""%1"" konnte nicht ausgeführt werden:';ro = 'Eșec la executarea procedurii ""%1"":';tr = '""%1"" İşlemi yürütülemedi:'; es_ES = 'No se ha podido ejecutar el procedimiento ""%1"":'"),
			ErrorInfo(), 
			ProcedurePresentation);
	EndTry;
	
EndProcedure

// Creates a record in the event log and in messages to a user.
//
// Parameters:
//   LogLevel - EventLogLevel - message importance for the administrator.
//   CommentWithParameters - String - a comment that can contain parameters %1.
//   ErrorInfo - ErrorInfo, String - error information placed after the comment.
//   Parameter - String - replaces %1 in CommentWithParameters.
//
Procedure LogRecord(
	LogLevel,
	CommentWithParameters,
	ErrorInformation = Undefined,
	Parameter = Undefined)
	
	// Determine the event log level based on the type of the passed error message.
	If TypeOf(LogLevel) <> Type("EventLogLevel") Then
		If TypeOf(ErrorInformation) = Type("ErrorInfo") Then
			LogLevel = EventLogLevel.Error;
		ElsIf TypeOf(ErrorInformation) = Type("String") Then
			LogLevel = EventLogLevel.Warning;
		Else
			LogLevel = EventLogLevel.Information;
		EndIf;
	EndIf;
	
	// Comment for the event log.
	TextForLog = CommentWithParameters;
	If Parameter <> Undefined Then
		TextForLog = StringFunctionsClientServer.SubstituteParametersToString(TextForLog, Parameter);
	EndIf;
	If TypeOf(ErrorInformation) = Type("ErrorInfo") Then
		TextForLog = TextForLog + Chars.LF + DetailErrorDescription(ErrorInformation);
	ElsIf TypeOf(ErrorInformation) = Type("String") Then
		TextForLog = TextForLog + Chars.LF + ErrorInformation;
	EndIf;
	TextForLog = TrimAll(TextForLog);
	
	// Record to the event log.
	WriteLogEvent(
		NStr("ru = 'Полнотекстовое индексирование'; en = 'Full-text indexing'; pl = 'Indeksacja pełnotekstowa';de = 'Volltextindizierung';ro = 'Indexarea full-text';tr = 'Tam metin endekslenme'; es_ES = 'Indexación de texto completo'", Common.DefaultLanguageCode()), 
		LogLevel, , , 
		TextForLog);
	
EndProcedure

#EndRegion

#EndRegion

#EndRegion
