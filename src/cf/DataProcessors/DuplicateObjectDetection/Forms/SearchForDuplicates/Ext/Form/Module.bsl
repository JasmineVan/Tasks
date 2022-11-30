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
	SetColorsAndConditionalAppearance();
	
	FuzzySearch = Common.AttachAddInFromTemplate("FuzzyStringMatchExtension", "CommonTemplate.StringSearchAddIn");
	If FuzzySearch <> Undefined Then 
		FuzzySearch1 = True;
	EndIf;
	
	FormSettings = Common.CommonSettingsStorageLoad(FormName, "");
	If FormSettings = Undefined Then
		FormSettings = New Structure;
		FormSettings.Insert("TakeAppliedRulesIntoAccount", True);
		FormSettings.Insert("DuplicatesSearchArea",        "");
		FormSettings.Insert("DCSettings",                Undefined);
		FormSettings.Insert("SearchRules",              Undefined);
	EndIf;
	FillPropertyValues(FormSettings, Parameters);
	
	OnCreateAtServerDataInitialization(FormSettings);
	InitializeFilterComposerAndRules(FormSettings);
	
	// The schema must be always regenerated, and the composer settings must be regenerated broken down by SearchForDuplicatesArea.
	
	// Permanent Interface
	StatePresentation = Items.NoSearchPerformed.StatePresentation;
	StatePresentation.Visible = True;
	StatePresentation.Text = NStr("ru = 'Поиск дублей не выполнялся. 
	                                        |Задайте условия отбора и сравнения и нажмите ""Найти дубли"".'; 
	                                        |en = 'You did not run duplicate search yet.
	                                        |Set filter criteria and select Find duplicates.'; 
	                                        |pl = 'Wyszukiwanie duplikatów nie jest wykonywane w toku. 
	                                        |Ustaw filtr i kryteria porównania i kliknij Znajdź duplikaty.';
	                                        |de = 'Duplikatsuche wird nicht ausgeführt. 
	                                        |Legen Sie Filter- und Vergleichskriterien fest und klicken Sie auf Duplikate suchen.';
	                                        |ro = 'Căutarea duplicatelor nu s-a executat. 
	                                        | Setați criteriile de filtrare și comparație și faceți clic pe ""Găsește duplicate"".';
	                                        |tr = 'Yinelenen arama devam etmiyor. 
	                                        |Filtre ve karşılaştırma kriterlerini ayarlayın ve Çiftleri bul''u tıklayın.'; 
	                                        |es_ES = 'Búsqueda de duplicados no está en progreso. 
	                                        |Establecer el filtro y los criterios de comparación, y hacer clic en Buscar duplicados.'");
	StatePresentation.Picture = Items.Warning32.Picture;
	
	StatePresentation = Items.PerformSearch.StatePresentation;
	StatePresentation.Visible = True;
	StatePresentation.Picture = Items.TimeConsumingOperation48.Picture;
	
	StatePresentation = Items.Deletion.StatePresentation;
	StatePresentation.Visible = True;
	StatePresentation.Picture = Items.TimeConsumingOperation48.Picture;
	
	StatePresentation = Items.DuplicatesNotFound.StatePresentation;
	StatePresentation.Visible = True;
	StatePresentation.Text = NStr("ru = 'Не обнаружено дублей по указанным параметрам.
	                                        |Измените условия отбора и сравнения, нажмите ""Найти дубли""'; 
	                                        |en = 'No duplicates found by the specified criteria.
	                                        |Edit the filter criteria and select Find duplicates.'; 
	                                        |pl = 'Duplikaty według określonych parametrów nie zostały znalezione.
	                                        |Zmień kryteria filtrowania i porównania, kliknij Znajdź duplikaty';
	                                        |de = 'Duplikate nach angegebenen Parametern werden nicht gefunden.
	                                        |Ändern Sie Filter und Vergleichskriterien, klicken Sie auf Duplikate suchen';
	                                        |ro = 'Nu au fost găsite duplicate după parametrii specificați.
	                                        |Modificați criteriile de filtrare și comparație, faceți clic pe ""Găsește duplicate""';
	                                        |tr = 'Belirtilen parametrelere sahip kopyalar bulunamadı. 
	                                        |Filtre ve karşılaştırma ölçütlerini değiştirin, Çiftleri bul''u tıklayın.'; 
	                                        |es_ES = 'Duplicados por parámetros especificados no se han encontrado.
	                                        |Cambiar el filtro y los criterios de comparación, hacer clic en Buscar duplicados'");
	StatePresentation.Picture = Items.Warning32.Picture;
	
	// Autosaving settings
	SavedInSettingsDataModified = True;
	
	// Initialization of step-by-step wizard steps.
	InitializeStepByStepWizardSettings();
	
	// 1. No search executed.
	SearchStep = AddWizardStep(Items.NoSearchPerformedStep);
	SearchStep.BackButton.Visible = False;
	SearchStep.NextButton.Title = NStr("ru = 'Найти дубли >'; en = 'Find duplicates >'; pl = 'Znajdź duplikaty >';de = 'Duplikate finden >';ro = 'Găsiți duplicate>';tr = 'Çiftleri bul >'; es_ES = 'Buscar duplicados >'");
	SearchStep.NextButton.ToolTip = NStr("ru = 'Найти дубли по указанным критериям'; en = 'Find duplicates by the specified criteria.'; pl = 'Znajdź duplikaty wg określonych kryteriów';de = 'Duplikate nach den angegebenen Kriterien finden';ro = 'Găsește duplicate în funcție de criteriile specificate';tr = 'Belirtilen kriterlere göre kopyaları bulun'; es_ES = 'Buscar los duplicados según los criterios especificados'");
	SearchStep.CancelButton.Title = NStr("ru = 'Закрыть'; en = 'Close'; pl = 'Zamknij';de = 'Schließen';ro = 'Închideți';tr = 'Kapat'; es_ES = 'Cerrar'");
	SearchStep.CancelButton.ToolTip = NStr("ru = 'Отказаться от поиска и замены дублей'; en = 'Close the form without duplicate search.'; pl = 'Odmów wyszukiwania i zastępowania duplikatów';de = 'Verweigert das Suchen und Ersetzen von Duplikaten';ro = 'Respinge căutarea și înlocuirea duplicatelor';tr = 'Çiftleri aramayı ve değiştirmeyi reddet'; es_ES = 'Rechazar la búsqueda y el reemplazo de duplicados'");
	
	// 2. Time-consuming search.
	Step = AddWizardStep(Items.PerformSearchStep);
	Step.BackButton.Visible = False;
	Step.NextButton.Visible = False;
	Step.CancelButton.Title = NStr("ru = 'Прервать'; en = 'Cancel'; pl = 'Przerwij';de = 'Abbrechen';ro = 'Eșuat';tr = 'Durdur'; es_ES = 'Anular'");
	Step.CancelButton.ToolTip = NStr("ru = 'Прервать поиск дублей'; en = 'Cancel duplicate search.'; pl = 'Zatrzymaj wyszukiwanie duplikatów';de = 'Stoppen Sie die Duplikatsuche';ro = 'Întrerupe căutarea duplicatelor';tr = 'Çiftleri aramayı durdur'; es_ES = 'Parar la búsqueda de duplicados'");
	
	// 3. Processing search results and selecting main items.
	Step = AddWizardStep(Items.MainItemSelectionStep);
	Step.BackButton.Visible = False;
	Step.NextButton.Title = NStr("ru = 'Удалить дубли >'; en = 'Delete duplicates >'; pl = 'Usuń duplikaty >';de = 'Duplikate löschen >';ro = 'Ștergeți duplicate>';tr = 'Çiftleri sil >'; es_ES = 'Borrar los duplicados >'");
	Step.NextButton.ToolTip = NStr("ru = 'Удалить дубли'; en = 'Delete found duplicates.'; pl = 'Usuń duplikaty';de = 'Duplikate löschen';ro = 'Ștergeți duplicatele';tr = 'Çiftleri sil'; es_ES = 'Borrar duplicados'");
	Step.CancelButton.Title = NStr("ru = 'Закрыть'; en = 'Close'; pl = 'Zamknij';de = 'Schließen';ro = 'Închideți';tr = 'Kapat'; es_ES = 'Cerrar'");
	Step.CancelButton.ToolTip = NStr("ru = 'Отказаться от поиска и замены дублей'; en = 'Close the form without duplicate search.'; pl = 'Odmów wyszukiwania i zastępowania duplikatów';de = 'Verweigert das Suchen und Ersetzen von Duplikaten';ro = 'Respinge căutarea și înlocuirea duplicatelor';tr = 'Çiftleri aramayı ve değiştirmeyi reddet'; es_ES = 'Rechazar la búsqueda y el reemplazo de duplicados'");
	
	// 4. Time-consuming deletion of duplicates.
	Step = AddWizardStep(Items.DeletionStep);
	Step.BackButton.Visible = False;
	Step.NextButton.Visible = False;
	Step.CancelButton.Title = NStr("ru = 'Прервать'; en = 'Cancel'; pl = 'Przerwij';de = 'Abbrechen';ro = 'Eșuat';tr = 'Durdur'; es_ES = 'Anular'");
	Step.CancelButton.ToolTip = NStr("ru = 'Прервать удаление дублей'; en = 'Cancel duplicate deletion.'; pl = 'Zatrzymaj usuwanie duplikatów';de = 'Stoppen Sie die Entfernung von Duplikaten';ro = 'Întrerupe ștergerea duplicatelor';tr = 'Çiftleri silmeyi durdur'; es_ES = 'Parar la eliminación de duplicados'");
	
	// 5. Successful deletion.
	Step = AddWizardStep(Items.SuccessfulDeletionStep);
	Step.BackButton.Title = NStr("ru = '< Новый поиск'; en = '< New search'; pl = '< Nowe wyszukiwanie';de = '< Neue Suche';ro = '<Căutare nouă';tr = '< Yeni arama'; es_ES = '< Nueva búsqueda'");
	Step.BackButton.ToolTip = NStr("ru = 'Начать новый поиск с другими параметрами'; en = 'Start a new duplicate search.'; pl = 'Rozpocznij nowe wyszukiwanie z innymi parametrami';de = 'Starten Sie die neue Suche mit verschiedenen Parametern';ro = 'Începe căutarea nouă cu alți parametri';tr = 'Farklı parametrelerle yeni arama başlat'; es_ES = 'Iniciar una nueva búsqueda con parámetros diferentes'");
	Step.NextButton.Visible = False;
	Step.CancelButton.DefaultButton = True;
	Step.CancelButton.Title = NStr("ru = 'Закрыть'; en = 'Close'; pl = 'Zamknij';de = 'Schließen';ro = 'Închideți';tr = 'Kapat'; es_ES = 'Cerrar'");
	
	// 6. Incomplete deletion.
	Step = AddWizardStep(Items.UnsuccessfulReplacementsStep);
	Step.BackButton.Visible = False;
	Step.NextButton.Title = NStr("ru = 'Повторить удаление >'; en = 'Delete again >'; pl = 'Powtórz usuwanie >';de = 'Löschen wiederholen >';ro = 'Repetare ștergerea >';tr = 'Silme işlemini tekrarla>'; es_ES = 'Repetir la eliminación >'");
	Step.NextButton.ToolTip = NStr("ru = 'Удалить дубли'; en = 'Delete found duplicates.'; pl = 'Usuń duplikaty';de = 'Duplikate löschen';ro = 'Ștergeți duplicatele';tr = 'Çiftleri sil'; es_ES = 'Borrar duplicados'");
	Step.CancelButton.Title = NStr("ru = 'Закрыть'; en = 'Close'; pl = 'Zamknij';de = 'Schließen';ro = 'Închideți';tr = 'Kapat'; es_ES = 'Cerrar'");
	
	// 7. No duplicates found.
	Step = AddWizardStep(Items.DuplicatesNotFoundStep);
	Step.BackButton.Visible = False;
	Step.NextButton.Title = NStr("ru = 'Найти дубли >'; en = 'Find duplicates >'; pl = 'Znajdź duplikaty >';de = 'Duplikate finden >';ro = 'Găsiți duplicate>';tr = 'Çiftleri bul >'; es_ES = 'Buscar duplicados >'");
	Step.NextButton.ToolTip = NStr("ru = 'Найти дубли по указанным критериям'; en = 'Find duplicates by the specified criteria.'; pl = 'Znajdź duplikaty wg określonych kryteriów';de = 'Duplikate nach den angegebenen Kriterien finden';ro = 'Găsește duplicate în funcție de criteriile specificate';tr = 'Belirtilen kriterlere göre kopyaları bulun'; es_ES = 'Buscar los duplicados según los criterios especificados'");
	Step.CancelButton.Title = NStr("ru = 'Закрыть'; en = 'Close'; pl = 'Zamknij';de = 'Schließen';ro = 'Închideți';tr = 'Kapat'; es_ES = 'Cerrar'");
	
	// 8. Runtime errors.
	Step = AddWizardStep(Items.ErrorOccurredStep);
	Step.BackButton.Visible = False;
	Step.NextButton.Visible = False;
	Step.CancelButton.Title = NStr("ru = 'Закрыть'; en = 'Close'; pl = 'Zamknij';de = 'Schließen';ro = 'Închideți';tr = 'Kapat'; es_ES = 'Cerrar'");
	
	// Updating form items.
	WizardSettings.CurrentStep = SearchStep;
	SetVisibilityAvailability(ThisObject);
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	// Running wizard.
	OnActivateWizardStep();
	
EndProcedure

&AtClient
Procedure BeforeClose(Cancel, Exit, WarningText, StandardProcessing)
	If Not WizardSettings.ShowDialogBeforeClose Then
		Return;
	EndIf;
	If Exit Then
		Return;
	EndIf;
	
	Cancel = True;
	CurrentPage = Items.WizardSteps.CurrentPage;
	If CurrentPage = Items.PerformSearchStep Then
		QuestionText = NStr("ru = 'Прервать поиск дублей и закрыть форму?'; en = 'Do you want to stop search and close the form?'; pl = 'Zaprzestać szukania duplikatów i zamknij formularz?';de = 'Stoppen Sie die Suche nach Duplikaten und schließen Sie das Formular?';ro = 'Nu mai căutați duplicate și închideți formularul?';tr = 'Çiftleri araması durdurulsun ve form kapatılsın mı?'; es_ES = '¿Parar la búsqueda de duplicados y cerrar el formulario?'");
	ElsIf CurrentPage = Items.DeletionStep Then
		QuestionText = NStr("ru = 'Прервать удаление дублей и закрыть форму?'; en = 'Do you want to stop deletion and close the form?'; pl = 'Zaprzestać usuwania duplikatów i zamknij formularz?';de = 'Stoppen Sie das Löschen von Duplikaten und schließen Sie das Formular?';ro = 'Nu mai ștergeți duplicatele și închideți formularul?';tr = 'Çiftleri değiştirmeyi bırak ve formu kapat?'; es_ES = '¿Parar la eliminación de duplicados y cerrar el formulario?'");
	EndIf;
	
	Buttons = New ValueList;
	Buttons.Add(DialogReturnCode.Abort, NStr("ru = 'Прервать'; en = 'Cancel operation'; pl = 'Przerwij';de = 'Abbrechen';ro = 'Renunțați';tr = 'Durdur'; es_ES = 'Anular'"));
	Buttons.Add(DialogReturnCode.No,      NStr("ru = 'Не прерывать'; en = 'Continue operation'; pl = 'Nie przerywać';de = 'Nicht unterbrechen';ro = 'Nu întrerupe';tr = 'Kesme'; es_ES = 'No interrumpir'"));
	
	Handler = New NotifyDescription("AfterConfirmCancelJob", ThisObject);
	
	ShowQueryBox(Handler, QuestionText, Buttons, , DialogReturnCode.No);
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure SearchForDuplicatesAreaStartChoice(Item, ChoiceData, StandardProcessing)
	StandardProcessing = False;
	
	Name = FullFormName("DuplicatesSearchArea");
	
	FormParameters = New Structure;
	FormParameters.Insert("SettingsAddress", SettingsAddress);
	FormParameters.Insert("DuplicatesSearchArea", DuplicatesSearchArea);
	
	Handler = New NotifyDescription("DuplicatesSearchAreaSelectionCompletion", ThisObject);
	
	OpenForm(Name, FormParameters, ThisObject, , , , Handler);
EndProcedure

&AtClient
Procedure DuplicatesSearchAreaSelectionCompletion(Result, ExecutionParameters) Export
	If TypeOf(Result) <> Type("String") Then
		Return;
	EndIf;
	
	DuplicatesSearchArea = Result;
	InitializeFilterComposerAndRules(Undefined);
	GoToWizardStep(Items.NoSearchPerformedStep);
EndProcedure

&AtClient
Procedure SearchForDuplicatesAreaOnChange(Item)
	InitializeFilterComposerAndRules(Undefined);
	GoToWizardStep(Items.NoSearchPerformedStep);
EndProcedure

&AtClient
Procedure SearchForDuplicatesAreaClearing(Item, StandardProcessing)
	
	StandardProcessing = False;
	
EndProcedure

&AtClient
Procedure AllUnprocessedItemsUsageInstancesClick(Item)
	
	ShowUsageInstances(UnprocessedDuplicates);
	
EndProcedure

&AtClient
Procedure AllUsageInstancesClick(Item)
	
	ShowUsageInstances(FoundDuplicates);
	
EndProcedure

&AtClient
Procedure FilterRulesPresentationStartChoice(Item, ChoiceData, StandardProcessing)
	StandardProcessing = False;
	
	AttachIdleHandler("OnStartSelectFilterRules", 0.1, True);
EndProcedure

&AtClient
Procedure OnStartSelectFilterRules()
	
	Name = FullFormName("FilterRules");
	
	ListItem = Items.DuplicatesSearchArea.ChoiceList.FindByValue(DuplicatesSearchArea);
	If ListItem = Undefined Then
		SearchForDuplicatesAreaPresentation = Undefined;
	Else
		SearchForDuplicatesAreaPresentation = ListItem.Presentation;
	EndIf;
	
	FormParameters = New Structure;
	FormParameters.Insert("CompositionSchemaAddress",            CompositionSchemaAddress);
	FormParameters.Insert("FilterComposerSettingsAddress", FilterComposerSettingsAddress());
	FormParameters.Insert("MasterFormID",      UUID);
	FormParameters.Insert("FilterAreaPresentation",      SearchForDuplicatesAreaPresentation);
	
	Handler = New NotifyDescription("FilterRulesSelectionCompletion", ThisObject);
	
	OpenForm(Name, FormParameters, ThisObject, , , , Handler);
	
EndProcedure

&AtClient
Procedure FilterRulesSelectionCompletion(ResultAddress, ExecutionParameters) Export
	If TypeOf(ResultAddress) <> Type("String") Or Not IsTempStorageURL(ResultAddress) Then
		Return;
	EndIf;
	UpdateFilterComposer(ResultAddress);
	GoToWizardStep(Items.NoSearchPerformedStep);
EndProcedure

&AtClient
Procedure FilterRulesPresentationClearing(Item, StandardProcessing)
	StandardProcessing = False;
	PrefilterComposer.Settings.Filter.Items.Clear();
	GoToWizardStep(Items.NoSearchPerformedStep);
	SaveUserSettingsSSL();
EndProcedure

&AtClient
Procedure SearchRulesPresentationClick(Item, StandardProcessing)
	StandardProcessing = False;
	
	Name = FullFormName("SearchRules");
	
	ListItem = Items.DuplicatesSearchArea.ChoiceList.FindByValue(DuplicatesSearchArea);
	If ListItem = Undefined Then
		SearchForDuplicatesAreaPresentation = Undefined;
	Else
		SearchForDuplicatesAreaPresentation = ListItem.Presentation;
	EndIf;
	
	FormParameters = New Structure;
	FormParameters.Insert("DuplicatesSearchArea",        DuplicatesSearchArea);
	FormParameters.Insert("AppliedRuleDetails",   AppliedRuleDetails);
	FormParameters.Insert("SettingsAddress",              SearchRulesSettingsAddress());
	FormParameters.Insert("FilterAreaPresentation", SearchForDuplicatesAreaPresentation);
	
	Handler = New NotifyDescription("SearchRulesSelectionCompletion", ThisObject);
	
	OpenForm(Name, FormParameters, ThisObject, , , , Handler);
EndProcedure

&AtClient
Procedure SearchRulesSelectionCompletion(ResultAddress, ExecutionParameters) Export
	If TypeOf(ResultAddress) <> Type("String") Or Not IsTempStorageURL(ResultAddress) Then
		Return;
	EndIf;
	UpdateSearchRules(ResultAddress);
	GoToWizardStep(Items.NoSearchPerformedStep);
EndProcedure

&AtClient
Procedure DetailsRefClick(Item)
	StandardSubsystemsClient.ShowDetailedInfo(Undefined, Item.ToolTip);
EndProcedure

#EndRegion

#Region FoundDuplicatesFormTableItemsEventHandlers

&AtClient
Procedure FoundDuplicatesOnActivateRow(Item)
	
	AttachIdleHandler("DuplicatesRowActivationDeferredHandler", 0.1, True);
	
EndProcedure

&AtClient
Procedure DuplicatesRowActivationDeferredHandler()
	RowID = Items.FoundDuplicates.CurrentRow;
	If RowID = Undefined Or RowID = CurrentRowID Then
		Return;
	EndIf;
	CurrentRowID = RowID;
	
	UpdateCandidateUsageInstances(RowID);
EndProcedure

&AtServer
Procedure UpdateCandidateUsageInstances(Val RowID)
	RowData = FoundDuplicates.FindByID(RowID);
	
	If RowData.GetParent() = Undefined Then
		// Group details
		ProbableDuplicateUsageInstances.Clear();
		
		OriginalDescription = Undefined;
		For Each Candidate In RowData.GetItems() Do
			If Candidate.Main Then
				OriginalDescription = Candidate.Description;
				Break;
			EndIf;
		EndDo;
		
		Items.CurrentDuplicatesGroupDetails.Title = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Для элемента ""%1"" найдено дублей: %2'; en = 'Found %2 duplicates for %1.'; pl = 'Dla elementu ""%1"" znaleziono duplikatów: %2';de = 'Für das Element ""%1"" Duplikate gefunden: %2';ro = 'Pentru elementul ""%1"" au fost găsite duplicate: %2';tr = '""%2"" Öğesi için çiftler (%1) bulundu'; es_ES = 'Para el artículo ""%1"" no se he encontrado duplicados: %2'"),
			OriginalDescription,
			RowData.Count);
		
		Items.UsageInstancesPages.CurrentPage = Items.GroupDetails;
		Return;
	EndIf;
	
	// List of usage instances.
	UsageTable = GetFromTempStorage(UsageInstancesAddress);
	Filter = New Structure("Ref", RowData.Ref);
	
	ProbableDuplicateUsageInstances.Load(UsageTable.Copy(UsageTable.FindRows(Filter)));
	
	If RowData.Count = 0 Then
		Items.CurrentDuplicatesGroupDetails.Title = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Элемент ""%1"" не используется'; en = 'No usage locations for %1.'; pl = 'Pozycja ""%1"" nie jest używana';de = 'Artikel ""%1"" wird nicht verwendet';ro = 'Elementul ""%1"" nu este utilizat';tr = 'Öğe ""%1"" kullanılmadı'; es_ES = 'Artículo ""%1"" no se ha utilizado'"), 
			RowData.Description);
		
		Items.UsageInstancesPages.CurrentPage = Items.GroupDetails;
	Else
		Items.ProbableDuplicateUsageInstances.Title = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Места использования ""%1"" (%2)'; en = 'Found %2 usage locations for %1.'; pl = 'Miejsca użycia ""%1"" (%2)';de = 'Verwendungsorte ""%1"" (%2)';ro = 'Locuri de utilizare ""%1"" (%2)';tr = 'Kullanıcı konumları ""%1"" (%2)'; es_ES = 'Ubicaciones de uso ""%1"" (%2)'"), 
			RowData.Description,
			RowData.Count);
		
		Items.UsageInstancesPages.CurrentPage = Items.UsageInstances;
	EndIf;
	
EndProcedure

&AtClient
Procedure FoundDuplicatesChoice(Item, RowSelected, Field, StandardProcessing)
	
	OpenDuplicateForm(Item.CurrentData);
	
EndProcedure

&AtClient
Procedure FoundDuplicatesMarkOnChange(Item)
	
	RowData = Items.FoundDuplicates.CurrentData;
	RowData.Check = RowData.Check % 2;
	ChangeCandidatesMarksHierarchically(RowData);
	
	DuplicatesSearchErrorDescription = "";
	TotalFoundDuplicates = 0;
	For Each Duplicate In FoundDuplicates.GetItems() Do
		For Each Child In Duplicate.GetItems() Do
			If Not Child.Main AND Child.Check Then
				TotalFoundDuplicates = TotalFoundDuplicates + 1;
			EndIf;
		EndDo;
	EndDo;
	
	UpdateFoundDuplicatesStateDetails(ThisObject);
	
EndProcedure

#EndRegion

#Region UnprocessedDuplicatesFormTableItemsEventHandlers

&AtClient
Procedure UnprocessedDuplicatesOnActivateRow(Item)
	
	AttachIdleHandler("UnprocessedDuplicatesRowActivationDeferredHandler", 0.1, True);
	
EndProcedure

&AtClient
Procedure UnprocessedDuplicatesRowActivationDeferredHandler()
	
	RowData = Items.UnprocessedDuplicates.CurrentData;
	If RowData = Undefined Then
		Return;
	EndIf;
	
	UpdateUnprocessedItemsUsageInstancesDuplicates( RowData.GetID() );
EndProcedure

&AtServer
Procedure UpdateUnprocessedItemsUsageInstancesDuplicates(Val DataString)
	RowData = UnprocessedDuplicates.FindByID(DataString);
	
	If RowData.GetParent() = Undefined Then
		// Group details
		UnprocessedItemsUsageInstances.Clear();
		
		Items.CurrentDuplicatesGroupDetails1.Title = NStr("ru = 'Для просмотра причин выберите проблемный элемент-дубль.'; en = 'To view details, select the duplicate that caused the issue.'; pl = 'Aby wyświetlić przyczyny wybierz problematyczny element-duplikat.';de = 'Um die Gründe anzuzeigen, wählen Sie das problematische Element-Duplikat.';ro = 'Pentru vizualizarea cauzelor selectați elementul-duplicat cu probleme.';tr = 'Nedeni görüntülemek için sorunlu nesne-kopyayı seçin.'; es_ES = 'Para ver las causas seleccione un elemento-duplicado con problemas.'");
		Items.UnprocessedItemsUsageInstancesPages.CurrentPage = Items.UnprocessedItemsGroupDetails;
		Return;
	EndIf;
	
	// List of error instances
	ErrorsTable = GetFromTempStorage(ReplacementResultAddress);
	Filter = New Structure("Ref", RowData.Ref);
	
	Data = ErrorsTable.Copy( ErrorsTable.FindRows(Filter) );
	Data.Columns.Add("Icon");
	Data.FillValues(True, "Icon");
	UnprocessedItemsUsageInstances.Load(Data);
	
	If RowData.Count = 0 Then
		Items.CurrentDuplicatesGroupDetails1.Title = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Замена дубля ""%1"" возможна, но была отменена из-за невозможности замены в других местах.'; en = 'Replacement of %1 is possible, but was canceled. Cannot replace item in some of the usage locations.'; pl = 'Wymiana duplikatu ""%1"" jest możliwe, ale została odwołana z powodu braku możliwości wymiany w innych miejscach.';de = 'Das Ersetzen des Duplikats ""%1"" ist möglich, wurde aber wegen der Unmöglichkeit, an anderer Stelle zu ersetzen, abgebrochen.';ro = 'Înlocuirea duplicatului ""%1"" este posibilă, dar a fost revocată din cauza imposibilității înlocuirii în alte locuri.';tr = '""%1"" kopyanın yer değişmesi mümkün, ancak diğer yerlerde mümkün olmadığından iptal edildi.'; es_ES = 'El cambio del duplicado ""%1"" es posible pero a causa de la imposibilidad de reemplazar en otros lugares.'"), 
			RowData.Description);
		
		Items.UnprocessedItemsUsageInstancesPages.CurrentPage = Items.UnprocessedItemsGroupDetails;
	Else
		Items.ProbableDuplicateUsageInstances.Title = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Не удалось заменить дубли в некоторых местах (%1)'; en = 'Cannot replace duplicates in %1 usage locations.'; pl = 'Nie można zastąpić duplikatów w niektórych lokalizacjach (%1)';de = 'Duplikate können an einigen Stellen nicht ersetzt werden (%1)';ro = 'Eșec la înlocuirea duplicatelor în unele locuri (%1)';tr = 'Bazı konumlarda çiftler değiştirilemiyor (%1)'; es_ES = 'No se puede reemplazar los duplicados en algunas ubcaciones (%1)'"), 
			RowData.Count);
		
		Items.UnprocessedItemsUsageInstancesPages.CurrentPage = Items.UnprocessedItemsUsageInstanceDetails;
	EndIf;
	
EndProcedure

&AtClient
Procedure UnprocessedDuplicatesChoice(Item, RowSelected, Field, StandardProcessing)
	
	OpenDuplicateForm(Items.UnprocessedDuplicates.CurrentData);
	
EndProcedure

#EndRegion

#Region UnprocessedItemsUsageInstancesFormTableItemsEventHandlers

&AtClient
Procedure UnprocessedItemsUsageInstancesOnActivateRow(Item)
	
	CurrentData = Item.CurrentData;
	If CurrentData = Undefined Then
		UnprocessedItemsErrorDescription = "";
	Else
		UnprocessedItemsErrorDescription = CurrentData.ErrorText;
	EndIf;
	
EndProcedure

&AtClient
Procedure UnprocessedsItemUsageInstancesSelection(Item, RowSelected, Field, StandardProcessing)
	
	CurrentData = UnprocessedItemsUsageInstances.FindByID(RowSelected);
	ShowValue(, CurrentData.ErrorObject);
	
EndProcedure

#EndRegion

#Region CandidateUsageInstancesFormTableItemsEventHandlers

&AtClient
Procedure CandidateUsageInstancesSelection(Item, RowSelected, Field, StandardProcessing)
	
	CurrentData = ProbableDuplicateUsageInstances.FindByID(RowSelected);
	ShowValue(, CurrentData.Data);
	
EndProcedure

#EndRegion

#Region FormCommandHandlers

&AtClient
Procedure WizardButtonHandler(Command)
	
	If Command.Name = WizardSettings.NextButton Then
		
		WizardStepNext();
		
	ElsIf Command.Name = WizardSettings.BackButton Then
		
		WizardStepBack();
		
	ElsIf Command.Name = WizardSettings.CancelButton Then
		
		WizardStepCancel();
		
	EndIf;
	
EndProcedure

&AtClient
Procedure SelectMainItem(Command)
	
	RowData = Items.FoundDuplicates.CurrentData;
	If RowData = Undefined Or RowData.Main Then
		Return; // No data or the Current item is the main one already.
	EndIf;
		
	Parent = RowData.GetParent();
	If Parent = Undefined Then
		Return;
	EndIf;
	
	ChangeMainItemHierarchically(RowData, Parent);
EndProcedure

&AtClient
Procedure OpenProbableDuplicate(Command)
	
	OpenDuplicateForm(Items.FoundDuplicates.CurrentData);
	
EndProcedure

&AtClient
Procedure OpenUnprocessedDuplicate(Command)
	
	OpenDuplicateForm(Items.UnprocessedDuplicates.CurrentData);
	
EndProcedure

&AtClient
Procedure ExpandDuplicatesGroups(Command)
	
	ExpandDuplicatesGroupHierarchically();
	
EndProcedure

&AtClient
Procedure CollapseDuplicatesGroups(Command)
	
	CollapseDuplicatesGroupHierarchically();
	
EndProcedure

&AtClient
Procedure RetrySearch(Command)
	
	GoToWizardStep(Items.PerformSearchStep);
	
EndProcedure

#EndRegion

#Region Private

////////////////////////////////////////////////////////////////////////////////
// Wizard programming interface

// Initializes wizard structures.
// The following value is written to the StepByStepWizardSettings form attribute:
//   Structure - description of wizard settings.
//     Public wizard settings:
//       * Steps - Array - description of wizard steps. Read only.
//           To add steps, use the AddWizardStep function.
//       * CurrentStep - Structure - current wizard step. Read only.
//       * ShowDialogBeforeClose - Boolean - If True, a warning will be displayed before closing the form.
//           For changing.
//     Internal wizard settings:
//       * PageGroup - String - a form item name that is passed to the PageGroup parameter.
//       * NextButton - String - a form item name that is passed to the NextButton parameter.
//       * BackButton - String - a form item name that is passed to the BackButton parameter.
//       * CancelButton - String - a form item name that is passed to the CancelButton parameter.
//
&AtServer
Procedure InitializeStepByStepWizardSettings()
	WizardSettings = New Structure;
	WizardSettings.Insert("Steps", New Array);
	WizardSettings.Insert("CurrentStep", Undefined);
	
	// Interface part IDs.
	WizardSettings.Insert("PagesGroup", Items.WizardSteps.Name);
	WizardSettings.Insert("NextButton",   Items.WizardStepNext.Name);
	WizardSettings.Insert("BackButton",   Items.WizardStepBack.Name);
	WizardSettings.Insert("CancelButton",  Items.WizardStepCancel.Name);
	
	// For processing time-consuming operations.
	WizardSettings.Insert("ShowDialogBeforeClose", False);
	
	// Everything is disabled by default.
	Items.WizardStepNext.Visible  = False;
	Items.WizardStepBack.Visible  = False;
	Items.WizardStepCancel.Visible = False;
EndProcedure

// Adds a wizard step. Navigation between pages is performed according to the order the pages are added.
//
// Parameters:
//   Page - FormGroup - a page that contains step items.
//
// Returns:
//   Structure - description of page settings.
//       * PageName - String - a page name.
//       * NextButton - Structure - description of "Next" button.
//           ** Title - String - a button title. The default value is "Next >".
//           ** Tooltip - String - button tooltip. Corresponds to the button title by default.
//           ** Visible - Boolean - If True, the button is visible. The default value is True.
//           ** Availability - Boolean - If True, the button is clickable. The default value is True.
//           ** DefaultButton - Boolean - if True, the button is the main button of the form. The default value is True.
//       * BackButton - Structure - description of the "Back" button.
//           ** Title - String - a button title. Default value: "< Back".
//           ** Tooltip - String - button tooltip. Corresponds to the button title by default.
//           ** Visible - Boolean - If True, the button is visible. The default value is True.
//           ** Availability - Boolean - If True, the button is clickable. The default value is True.
//           ** DefaultButton - Boolean - if True, the button is the main button of the form. Default value: False.
//       * CancelButton - Structure - description of the "Cancel" button.
//           ** Title - String - a button title. The default value is "Cancel".
//           ** Tooltip - String - button tooltip. Corresponds to the button title by default.
//           ** Visible - Boolean - If True, the button is visible. The default value is True.
//           ** Availability - Boolean - If True, the button is clickable. The default value is True.
//           ** DefaultButton - Boolean - if True, the button is the main button of the form. Default value: False.
//
&AtServer
Function AddWizardStep(Val Page)
	StepDescription = New Structure("IndexOf, PageName, BackButton, NextButton, CancelButton");
	StepDescription.PageName = Page.Name;
	StepDescription.BackButton = WizardButton();
	StepDescription.BackButton.Title = NStr("ru='< Назад'; en = '< Back'; pl = '< Wstecz';de = '< Zurück';ro = '< Înapoi';tr = '< Geri'; es_ES = '< Atrás'");
	StepDescription.NextButton = WizardButton();
	StepDescription.NextButton.DefaultButton = True;
	StepDescription.NextButton.Title = NStr("ru = 'Далее >'; en = 'Next >'; pl = 'Dalej >';de = 'Weiter >';ro = ' Următorul >';tr = 'Sonraki >'; es_ES = 'Siguiente >'");
	StepDescription.CancelButton = WizardButton();
	StepDescription.CancelButton.Title = NStr("ru = 'Отмена'; en = 'Cancel'; pl = 'Anuluj';de = 'Abbrechen';ro = 'Revocare';tr = 'İptal'; es_ES = 'Cancelar'");
	
	WizardSettings.Steps.Add(StepDescription);
	
	StepDescription.IndexOf = WizardSettings.Steps.UBound();
	Return StepDescription;
EndFunction

// Updates visibility and availability of form items according to the current wizard step.
&AtClientAtServerNoContext
Procedure SetVisibilityAvailability(Form)
	
	Items = Form.Items;
	WizardSettings = Form.WizardSettings;
	CurrentStep = WizardSettings.CurrentStep;
	
	// Navigating to the page.
	Items[WizardSettings.PagesGroup].CurrentPage = Items[CurrentStep.PageName];
	
	// Updating buttons.
	UpdateWizardButtonProperties(Items[WizardSettings.NextButton],  CurrentStep.NextButton);
	UpdateWizardButtonProperties(Items[WizardSettings.BackButton],  CurrentStep.BackButton);
	UpdateWizardButtonProperties(Items[WizardSettings.CancelButton], CurrentStep.CancelButton);
	
EndProcedure

// Navigates to the specified page.
//
// Parameters:
//   StepOrIndexOrFormGroup - Structure, Number, FormGroup - a page to navigate to.
//
&AtClient
Procedure GoToWizardStep(Val StepOrIndexOrFormGroup)
	
	// Searching for step.
	Type = TypeOf(StepOrIndexOrFormGroup);
	If Type = Type("Structure") Then
		StepDescription = StepOrIndexOrFormGroup;
	ElsIf Type = Type("Number") Then
		StepIndex = StepOrIndexOrFormGroup;
		If StepIndex < 0 Then
			Raise NStr("ru='Попытка выхода назад из первого шага мастера'; en = 'Attempt to go back from the first step.'; pl = 'Próba wyjścia do tyłu, z pierwszego kroku kreatora';de = 'Versuch, vom ersten Schritt des Assistenten zurückzukehren';ro = 'Tentativa de a ieși înapoi din primul pas al expertului';tr = 'İlk sihirbaz adımını aşma girişimi'; es_ES = 'Intentando volver desde el primer paso del asistente'");
		ElsIf StepIndex > WizardSettings.Steps.UBound() Then
			Raise NStr("ru='Попытка выхода за последний шаг мастера'; en = 'Attempt to go next from the last step.'; pl = 'Próba wyjścia za ostatni krok kreatora';de = 'Versuch, den letzten Schritt des Assistenten zu durchlaufen';ro = 'Tentativa de a trece peste ultimul pas al expertului';tr = 'Son sihirbaz adımını aşma girişimi'; es_ES = 'Intentando repasar el último paso del asistente'");
		EndIf;
		StepDescription = WizardSettings.Steps[StepIndex];
	Else
		StepFound = False;
		RequiredPageName = StepOrIndexOrFormGroup.Name;
		For Each StepDescription In WizardSettings.Steps Do
			If StepDescription.PageName = RequiredPageName Then
				StepFound = True;
				Break;
			EndIf;
		EndDo;
		If Not StepFound Then
			Raise StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'Не найден шаг ""%1"".'; en = 'Step %1 is not found.'; pl = 'Krok ""%1"" nie został znaleziony.';de = 'Schritt ""%1"" wird nicht gefunden.';ro = 'Nu s-a găsit pasul ""%1"".';tr = 'Adım ""%1"" bulunamadı.'; es_ES = 'El paso ""%1"" no se ha encontrado.'"),
				RequiredPageName);
		EndIf;
	EndIf;
	
	// Step switch.
	WizardSettings.CurrentStep = StepDescription;
	
	// Updating visibility.
	SetVisibilityAvailability(ThisObject);
	OnActivateWizardStep();
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Wizard events

&AtClient
Procedure OnActivateWizardStep()
	
	CurrentPage = Items.WizardSteps.CurrentPage;
	
	If CurrentPage = Items.NoSearchPerformedStep Then
		
		Items.Header.Enabled = True;
		
		// Filter rule presentation.
		FilterRulesPresentation = String(PrefilterComposer.Settings.Filter);
		If IsBlankString(FilterRulesPresentation) Then
			FilterRulesPresentation = NStr("ru = 'Все элементы'; en = 'All items'; pl = 'Wszystkie elementy';de = 'Alle Elemente';ro = 'Toate obiectele';tr = 'Tüm öğeler'; es_ES = 'Todos los artículos'");
		EndIf;
		
		// Search rule presentation.
		Conjunction = " " + NStr("ru = 'И'; en = 'AND'; pl = 'AND';de = 'UND';ro = 'ȘI';tr = 'VE'; es_ES = 'Y'") + " ";
		RulesText = "";
		For Each Rule In SearchRules Do
			If Rule.Rule = "Equal" Then
				Comparison = Rule.AttributePresentation + " " + NStr("ru = 'совпадает'; en = 'match'; pl = 'pokrywa się';de = 'stimmt überein';ro = 'coincide';tr = 'uyumlu'; es_ES = 'corresponde'");
			ElsIf Rule.Rule = "Like" Then
				Comparison = Rule.AttributePresentation + " " + NStr("ru = 'совпадает по похожим словам'; en = 'fuzzy match'; pl = 'pokrywa się według podobnych wyrazów';de = 'stimmt mit ähnlichen Wörtern überein';ro = 'coincide cu cuvinte asemănătoare';tr = 'benzer kelimelere göre uyumlu'; es_ES = 'corresponde por palabras relacionadas'");
			Else
				Continue;
			EndIf;
			RulesText = ?(RulesText = "", "", RulesText + Conjunction) + Comparison;
		EndDo;
		If TakeAppliedRulesIntoAccount Then
			For Position = 1 To StrLineCount(AppliedRuleDetails) Do
				RuleRow = TrimAll(StrGetLine(AppliedRuleDetails, Position));
				If Not IsBlankString(RuleRow) Then
					RulesText = ?(RulesText = "", "", RulesText + Conjunction) + RuleRow;
				EndIf;
			EndDo;
		EndIf;
		If IsBlankString(RulesText) Then
			RulesText = NStr("ru = 'Правила не заданы'; en = 'No rules set'; pl = 'Reguły nie są ustawione';de = 'Die Regeln sind nicht festgelegt';ro = 'Regulile nu sunt setate';tr = 'Kurallar belirlenmedi'; es_ES = 'Las reglas no se han establecido'");
		EndIf;
		SearchRulesPresentation = RulesText;
		
		// Availability.
		Items.FilterRulesPresentation.Enabled = Not IsBlankString(DuplicatesSearchArea);
		Items.SearchRulesPresentation.Enabled = Not IsBlankString(DuplicatesSearchArea);
		
	ElsIf CurrentPage = Items.PerformSearchStep Then
		
		If Not IsTempStorageURL(CompositionSchemaAddress) Then
			Return; // Not initialized.
		EndIf;
		Items.Header.Enabled = False;
		WizardSettings.ShowDialogBeforeClose = True;
		FindAndDeleteDuplicatesClient();
		
	ElsIf CurrentPage = Items.MainItemSelectionStep Then
		
		Items.Header.Enabled = True;
		Items.RetrySearch.Visible = True;
		ExpandDuplicatesGroupHierarchically();
		
	ElsIf CurrentPage = Items.DeletionStep Then
		
		Items.Header.Enabled = False;
		WizardSettings.ShowDialogBeforeClose = True;
		FindAndDeleteDuplicatesClient();
		
	ElsIf CurrentPage = Items.SuccessfulDeletionStep Then
		
		Items.Header.Enabled = False;
		
	ElsIf CurrentPage = Items.UnsuccessfulReplacementsStep Then
		
		Items.Header.Enabled = False;
		
	ElsIf CurrentPage = Items.DuplicatesNotFoundStep Then
		
		Items.Header.Enabled = True;
		If IsBlankString(DuplicatesSearchErrorDescription) Then
			Message = NStr("ru = 'Не обнаружено дублей по указанным параметрам.'; en = 'No duplicates found by the specified parameters.'; pl = 'Nie wykryto duplikatów wg określonych parametrów.';de = 'Nicht erkannte Duplikate der angegebenen Parameter.';ro = 'Nu au fost găsite duplicate conform parametrilor specificați.';tr = 'Belirtilen parametrelerin kopyaları algılanmadı.'; es_ES = 'No se han encontrado duplicados por parámetros indicados.'");
		Else	
			Message = DuplicatesSearchErrorDescription;
		EndIf;	
		Items.DuplicatesNotFound.StatePresentation.Text = Message + Chars.LF 
			+ NStr("ru = 'Измените условия и нажмите ""Найти дубли""'; en = 'Edit the criteria and select Find duplicates.'; pl = 'Zmień warunki i kliknij ""Znajdź duplikaty""';de = 'Ändern Sie die Bedingungen und klicken Sie auf ""Duplikate finden""';ro = 'Modificați condițiile și tastați ""Găsește duplicatele""';tr = 'Koşulları değiştirin ve ""Çiftleri bul"" u tıklayın'; es_ES = 'Cambie las condiciones y pulse ""Buscar duplicados""'");
		
	ElsIf CurrentPage = Items.ErrorOccurredStep Then
		
		Items.Header.Enabled = True;
		Items.DetailsRef.Visible = ValueIsFilled(Items.DetailsRef.ToolTip);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure WizardStepNext()
	
	ClearMessages();
	CurrentPage = Items.WizardSteps.CurrentPage;
	
	If CurrentPage = Items.NoSearchPerformedStep Then
		
		If IsBlankString(DuplicatesSearchArea) Then
			ShowMessageBox(, NStr("ru = 'Необходимо выбрать область поиска дублей'; en = 'Select search area'; pl = 'Wybierz obszar do wyszukiwania duplikatów';de = 'Wählen Sie den Bereich, um nach Duplikaten zu suchen';ro = 'Selectați zona pentru a căuta duplicate';tr = 'Kopyaları aramak için alan seçin'; es_ES = 'Seleccionar un área para buscar los duplicados'"));
			Return;
		EndIf;
		
		GoToWizardStep(WizardSettings.CurrentStep.IndexOf + 1);
		
	ElsIf CurrentPage = Items.MainItemSelectionStep Then
		
		Items.RetrySearch.Visible = False;
		GoToWizardStep(WizardSettings.CurrentStep.IndexOf + 1);
		
	ElsIf CurrentPage = Items.UnsuccessfulReplacementsStep Then
		
		GoToWizardStep(Items.DeletionStep);
		
	ElsIf CurrentPage = Items.DuplicatesNotFoundStep Then
		
		GoToWizardStep(Items.PerformSearchStep);
		
	Else
		
		GoToWizardStep(WizardSettings.CurrentStep.IndexOf + 1);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure WizardStepBack()
	
	CurrentPage = Items.WizardSteps.CurrentPage;
	
	If CurrentPage = Items.SuccessfulDeletionStep Then
		
		GoToWizardStep(Items.NoSearchPerformedStep);
		
	Else
		
		GoToWizardStep(WizardSettings.CurrentStep.IndexOf - 1);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure WizardStepCancel()
	
	CurrentPage = Items.WizardSteps.CurrentPage;
	
	If CurrentPage = Items.PerformSearchStep
		Or CurrentPage = Items.DeletionStep Then
		
		WizardSettings.ShowDialogBeforeClose = False;
		
	EndIf;
	
	If IsOpen() Then
		Close();
	EndIf;
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Client

&AtClient
Function FullFormName(ShortFormName)
	Names = StrSplit(FormName, ".");
	Return Names[0] + "." + Names[1] + ".Form." + ShortFormName;
EndFunction

&AtClient
Procedure OpenDuplicateForm(Val CurrentData)
	If CurrentData = Undefined Or Not ValueIsFilled(CurrentData.Ref) Then
		Return;
	EndIf;
	
	ShowValue(,CurrentData.Ref);
EndProcedure

&AtClient
Procedure ShowUsageInstances(SourceTree)
	RefsArray = New Array;
	For Each DuplicatesGroup In SourceTree.GetItems() Do
		For Each TreeRow In DuplicatesGroup.GetItems() Do
			RefsArray.Add(TreeRow.Ref);
		EndDo;
	EndDo;
	
	ReportParameters = New Structure;
	ReportParameters.Insert("Filter", New Structure("RefSet", RefsArray));
	WindowMode = FormWindowOpeningMode.LockOwnerWindow;
	OpenForm("Report.SearchForReferences.Form", ReportParameters, ThisObject, , , , , WindowMode);
EndProcedure

&AtClient
Procedure ExpandDuplicatesGroupHierarchically(Val DataString = Undefined)
	If DataString <> Undefined Then
		Items.FoundDuplicates.Expand(DataString, True);
	EndIf;
	
	// All items of the first level
	AllRows = Items.FoundDuplicates;
	For Each RowData In FoundDuplicates.GetItems() Do 
		AllRows.Expand(RowData.GetID(), True);
	EndDo;
EndProcedure

&AtClient
Procedure CollapseDuplicatesGroupHierarchically(Val DataString = Undefined)
	If DataString <> Undefined Then
		Items.FoundDuplicates.Collapse(DataString);
		Return;
	EndIf;
	
	// All items of the first level
	AllRows = Items.FoundDuplicates;
	For Each RowData In FoundDuplicates.GetItems() Do 
		AllRows.Collapse(RowData.GetID());
	EndDo;
EndProcedure

&AtClient
Procedure ChangeCandidatesMarksHierarchically(Val RowData)
	SetMarksDown(RowData);
	SetMarksUp(RowData);
EndProcedure

&AtClient
Procedure SetMarksDown(Val RowData)
	Value = RowData.Check;
	For Each Child In RowData.GetItems() Do
		Child.Check = Value;
		SetMarksDown(Child);
	EndDo;
EndProcedure

&AtClient
Procedure SetMarksUp(Val RowData)
	RowParent = RowData.GetParent();
	
	If RowParent <> Undefined Then
		AllTrue = True;
		NotAllFalse = False;
		
		For Each Child In RowParent.GetItems() Do
			AllTrue = AllTrue AND (Child.Check = 1);
			NotAllFalse = NotAllFalse Or (Child.Check > 0);
		EndDo;
		
		If AllTrue Then
			RowParent.Check = 1;
			
		ElsIf NotAllFalse Then
			RowParent.Check = 2;
			
		Else
			RowParent.Check = 0;
			
		EndIf;
		
		SetMarksUp(RowParent);
	EndIf;
	
EndProcedure

&AtClient
Procedure ChangeMainItemHierarchically(Val RowData, Val Parent)
	For Each Child In Parent.GetItems() Do
		Child.Main = False;
	EndDo;
	RowData.Main = True;
	
	// Selected item is always used.
	RowData.Check = 1;
	ChangeCandidatesMarksHierarchically(RowData);
	
	// Changing the group name
	Parent.Description = RowData.Description + " (" + Parent.Count + ")";
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Client, Server

&AtClientAtServerNoContext
Procedure UpdateFoundDuplicatesStateDetails(Form)
	
	If IsBlankString(Form.DuplicatesSearchErrorDescription) Then
		Details = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Выбрано дублей: %1 из %2.'; en = 'Selected duplicates: %1 out of %2.'; pl = 'Wybrane duplikaty: %1 z %2.';de = 'Ausgewählte Duplikate: %1 von %2.';ro = 'Duplicate selectate: %1 din %2.';tr = 'Seçilen kopyalar:%1 dan%2.'; es_ES = 'Se han seleccionado duplicados: %1 de %2.'"),
			Form.TotalFoundDuplicates, Form.TotalItems);
	Else	
		Details = Form.DuplicatesSearchErrorDescription;
	EndIf;
	
	Form.FoundDuplicatesStateDetails = New FormattedString(Details + Chars.LF
		+ NStr("ru = 'Выбранные элементы будут помечены на удаление и заменены на оригиналы (отмечены стрелкой).'; en = 'The selected items will be marked for deletion and replaced by originals.'; pl = 'Wybrane elementy zostaną oznaczone do usunięcia i zastąpione oryginałami (oznaczone strzałką).';de = 'Die ausgewählten Elemente werden zum Löschen markiert und durch Originale ersetzt (mit einem Pfeil markiert).';ro = 'Elementele selectate vor fi marcate la ștergere și înlocuite cu originalele (marcate cu săgeată).';tr = 'Seçilen öğeler silinmek üzere işaretlenecek ve orijinallerle değiştirilecektir (bir okla işaretlenmiş).'; es_ES = 'Los elementos seleccionados serán marcados para borrar y cambiados por originales (marcados con flecha).'"),
		, Form.InformationTextColor);
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Server call, Server

&AtServer
Function FilterComposerSettingsAddress()
	Return PutToTempStorage(PrefilterComposer.Settings, UUID);
EndFunction

&AtServer
Function SearchRulesSettingsAddress()
	Settings = New Structure;
	Settings.Insert("TakeAppliedRulesIntoAccount", TakeAppliedRulesIntoAccount);
	Settings.Insert("AllComparisonOptions", AllComparisonOptions);
	Settings.Insert("SearchRules", FormAttributeToValue("SearchRules"));
	Return PutToTempStorage(Settings);
EndFunction

&AtServer
Procedure UpdateFilterComposer(ResultAddress)
	Result = GetFromTempStorage(ResultAddress);
	DeleteFromTempStorage(ResultAddress);
	PrefilterComposer.LoadSettings(Result);
	PrefilterComposer.Refresh(DataCompositionSettingsRefreshMethod.Full);
	SaveUserSettingsSSL();
EndProcedure

&AtServer
Procedure UpdateSearchRules(ResultAddress)
	Result = GetFromTempStorage(ResultAddress);
	DeleteFromTempStorage(ResultAddress);
	TakeAppliedRulesIntoAccount = Result.TakeAppliedRulesIntoAccount;
	ValueToFormAttribute(Result.SearchRules, "SearchRules");
	SaveUserSettingsSSL();
EndProcedure

&AtServer
Procedure InitializeFilterComposerAndRules(FormSettings)
	// 1. Clearing and initializing information about the metadata object.
	FilterRulesPresentation = "";
	SearchRulesPresentation = "";
	
	SettingsTable = GetFromTempStorage(SettingsAddress);
	SettingsTableRow = SettingsTable.Find(DuplicatesSearchArea, "FullName");
	If SettingsTableRow = Undefined Then
		DuplicatesSearchArea = "";
		Return;
	EndIf;
	
	MetadataObject = Metadata.FindByFullName(DuplicatesSearchArea);
	
	// 2. Initializing a DCS used for filters.
	CompositionSchema = New DataCompositionSchema;
	DataSource = CompositionSchema.DataSources.Add();
	DataSource.DataSourceType = "Local";
	
	DataSet = CompositionSchema.DataSets.Add(Type("DataCompositionSchemaDataSetQuery"));
	DataSet.Query = "SELECT " + AvailableFilterAttributes(MetadataObject) + " FROM " + DuplicatesSearchArea;
	DataSet.AutoFillAvailableFields = True;
	
	CompositionSchemaAddress = PutToTempStorage(CompositionSchema, UUID);
	
	PrefilterComposer.Initialize(New DataCompositionAvailableSettingsSource(CompositionSchema));
	
	// 3. Filling in the SearchRules table.
	RulesTable = FormAttributeToValue("SearchRules");
	RulesTable.Clear();
	
	IgnoredAttributes = New Structure("DeletionMark, Ref, Predefined, PredefinedDataName, IsFolder");
	AddMetaAttributesRules(RulesTable, IgnoredAttributes, AllComparisonOptions, MetadataObject.StandardAttributes, FuzzySearch1);
	AddMetaAttributesRules(RulesTable, IgnoredAttributes, AllComparisonOptions, MetadataObject.Attributes, FuzzySearch1);
	
	// 4. Importing saved values.
	FiltersImported = False;
	DCSettings = CommonClientServer.StructureProperty(FormSettings, "DCSettings");
	If TypeOf(DCSettings) = Type("DataCompositionSettings") Then
		PrefilterComposer.LoadSettings(DCSettings);
		FiltersImported = True;
	EndIf;
	
	RulesImported = False;
	SavedRules = CommonClientServer.StructureProperty(FormSettings, "SearchRules");
	If TypeOf(SavedRules) = Type("ValueTable") Then
		RulesImported = True;
		For Each SavedRule In SavedRules Do
			Rule = RulesTable.Find(SavedRule.Attribute, "Attribute");
			If Rule <> Undefined
				AND Rule.ComparisonOptions.FindByValue(SavedRule.Rule) <> Undefined Then
				Rule.Rule = SavedRule.Rule;
			EndIf;
		EndDo;
	EndIf;
	
	// 5. Setting defaults.
	// Filtering by deletion mark.
	If Not FiltersImported Then
		CommonClientServer.SetFilterItem(
			PrefilterComposer.Settings.Filter,
			"DeletionMark",
			False,
			DataCompositionComparisonType.Equal,
			,
			False);
	EndIf;
	// Comparing by description.
	If Not RulesImported Then
		Rule = RulesTable.Find("Description", "Attribute");
		If Rule <> Undefined Then
			ValueToCompare = ?(FuzzySearch1, "Like", "Equal");
			If Rule.ComparisonOptions.FindByValue(ValueToCompare) <> Undefined Then
				Rule.Rule = ValueToCompare;
			EndIf;
		EndIf;
	EndIf;
	
	// 6. Extension functionality in applied rules.
	AppliedRuleDetails = Undefined;
	If SettingsTableRow.EventDuplicateSearchParameters Then
		DefaultParameters = New Structure;
		DefaultParameters.Insert("SearchRules",        RulesTable);
		DefaultParameters.Insert("ComparisonRestrictions", New Array);
		DefaultParameters.Insert("FilterComposer",    PrefilterComposer);
		DefaultParameters.Insert("ItemsCountToCompare", 1000);
		MetadataObjectManager = Common.ObjectManagerByFullName(MetadataObject.FullName());
		MetadataObjectManager.DuplicatesSearchParameters(DefaultParameters);
		
		// Presentation of applied rules.
		AppliedRuleDetails = "";
		For Each Details In DefaultParameters.ComparisonRestrictions Do
			AppliedRuleDetails = AppliedRuleDetails + Chars.LF + Details.Presentation;
		EndDo;
		AppliedRuleDetails = TrimAll(AppliedRuleDetails);
	EndIf;
	
	PrefilterComposer.Refresh(DataCompositionSettingsRefreshMethod.Full);
	
	RulesTable.Sort("AttributePresentation");
	ValueToFormAttribute(RulesTable, "SearchRules");
	
	If FormSettings = Undefined Then
		SaveUserSettingsSSL();
	EndIf;
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Server

&AtServer
Procedure OnCreateAtServerDataInitialization(FormSettings)
	TakeAppliedRulesIntoAccount = CommonClientServer.StructureProperty(FormSettings, "TakeAppliedRulesIntoAccount");
	DuplicatesSearchArea        = CommonClientServer.StructureProperty(FormSettings, "DuplicatesSearchArea");
	
	SettingsTable = DuplicateObjectDetection.MetadataObjectsSettings();
	SettingsAddress = PutToTempStorage(SettingsTable, UUID);
	
	ChoiceList = Items.DuplicatesSearchArea.ChoiceList;
	For Each TableRow In SettingsTable Do
		ChoiceList.Add(TableRow.FullName, TableRow.ListPresentation, , PictureLib[TableRow.Kind]);
	EndDo;
	
	AllComparisonOptions.Add("Equal",   NStr("ru = 'Совпадает'; en = 'Match'; pl = 'Pasuje do';de = 'Übereinstimmen';ro = 'Potriviri';tr = 'Uyumlu'; es_ES = 'Corresponde'"));
	AllComparisonOptions.Add("Like", NStr("ru = 'Совпадает по похожим словам'; en = 'Fuzzy match'; pl = 'Dopasowano wg podobnych słów';de = 'Stimmt mit ähnlichen wörtern überein';ro = 'Coincide cu cuvinte asemănătoare';tr = 'Benzer kelimelere göre uyumlu'; es_ES = 'Corresponde por palabras relacionadas'"));
EndProcedure

&AtServer
Procedure SaveUserSettingsSSL()
	FormSettings = New Structure;
	FormSettings.Insert("TakeAppliedRulesIntoAccount", TakeAppliedRulesIntoAccount);
	FormSettings.Insert("DuplicatesSearchArea", DuplicatesSearchArea);
	FormSettings.Insert("DCSettings", PrefilterComposer.Settings);
	FormSettings.Insert("SearchRules", SearchRules.Unload());
	Common.CommonSettingsStorageSave(FormName, "", FormSettings);
EndProcedure

&AtServer
Procedure SetColorsAndConditionalAppearance()
	InformationTextColor       = StyleColorOrAuto("NoteText",       69,  81,  133);
	ErrorInformationTextColor = StyleColorOrAuto("ErrorNoteText", 255, 0,   0);
	InaccessibleDataColor     = StyleColorOrAuto("InaccessibleDataColor", 192, 192, 192);
	
	ConditionalAppearanceItems = ConditionalAppearance.Items;
	ConditionalAppearanceItems.Clear();
	
	// No usage instances of the group.
	AppearanceItem = ConditionalAppearanceItems.Add();
	
	AppearanceFilter = AppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	AppearanceFilter.LeftValue = New DataCompositionField("FoundDuplicates.Ref");
	AppearanceFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	AppearanceFilter.RightValue = True;
	
	AppearanceItem.Appearance.SetParameterValue("Text", "");
	
	AppearanceField = AppearanceItem.Fields.Items.Add();
	AppearanceField.Field = New DataCompositionField("FoundDuplicatesCount");
	
	// 1. Row with the current main group item:
	
	// Picture
	AppearanceItem = ConditionalAppearanceItems.Add();
	
	AppearanceFilter = AppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	AppearanceFilter.LeftValue = New DataCompositionField("FoundDuplicates.Main");
	AppearanceFilter.ComparisonType = DataCompositionComparisonType.Equal;
	AppearanceFilter.RightValue = True;
	
	AppearanceItem.Appearance.SetParameterValue("Visible", True);
	AppearanceItem.Appearance.SetParameterValue("Show", True);
	
	AppearanceField = AppearanceItem.Fields.Items.Add();
	AppearanceField.Field = New DataCompositionField("FoundDuplicatesMain");
	
	// Mark cleared
	AppearanceItem = ConditionalAppearanceItems.Add();
	
	AppearanceFilter = AppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	AppearanceFilter.LeftValue = New DataCompositionField("FoundDuplicates.Main");
	AppearanceFilter.ComparisonType = DataCompositionComparisonType.Equal;
	AppearanceFilter.RightValue = True;
	
	AppearanceItem.Appearance.SetParameterValue("Visible", False);
	AppearanceItem.Appearance.SetParameterValue("Show", False);
	
	AppearanceField = AppearanceItem.Fields.Items.Add();
	AppearanceField.Field = New DataCompositionField("FoundDuplicatesCheck");
	
	// 2. Row with a usual item.
	
	// Picture
	AppearanceItem = ConditionalAppearanceItems.Add();
	
	AppearanceFilter = AppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	AppearanceFilter.LeftValue = New DataCompositionField("FoundDuplicates.Main");
	AppearanceFilter.ComparisonType = DataCompositionComparisonType.Equal;
	AppearanceFilter.RightValue = False;
	
	AppearanceItem.Appearance.SetParameterValue("Visible", False);
	AppearanceItem.Appearance.SetParameterValue("Show", False);
	
	AppearanceField = AppearanceItem.Fields.Items.Add();
	AppearanceField.Field = New DataCompositionField("FoundDuplicatesMain");
	
	// Mark selected
	AppearanceItem = ConditionalAppearanceItems.Add();
	
	AppearanceFilter = AppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	AppearanceFilter.LeftValue = New DataCompositionField("FoundDuplicates.Main");
	AppearanceFilter.ComparisonType = DataCompositionComparisonType.Equal;
	AppearanceFilter.RightValue = False;
	
	AppearanceItem.Appearance.SetParameterValue("Visible", True);
	AppearanceItem.Appearance.SetParameterValue("Show", True);
	
	AppearanceField = AppearanceItem.Fields.Items.Add();
	AppearanceField.Field = New DataCompositionField("FoundDuplicatesCheck");
	
	// 3. Usage instances
	AppearanceItem = ConditionalAppearanceItems.Add();
	
	AppearanceFilter = AppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	AppearanceFilter.LeftValue = New DataCompositionField("FoundDuplicates.Ref");
	AppearanceFilter.ComparisonType = DataCompositionComparisonType.Filled;
	AppearanceFilter.RightValue = True;
	
	AppearanceFilter = AppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	AppearanceFilter.LeftValue = New DataCompositionField("FoundDuplicates.Count");
	AppearanceFilter.ComparisonType = DataCompositionComparisonType.Equal;
	AppearanceFilter.RightValue = 0;
	
	AppearanceItem.Appearance.SetParameterValue("Text", NStr("ru = '-'; en = '-'; pl = '-';de = '-';ro = '-';tr = '-'; es_ES = '-'"));
	
	AppearanceField = AppearanceItem.Fields.Items.Add();
	AppearanceField.Field = New DataCompositionField("FoundDuplicatesCount");
	
	// 4. Inactive row
	AppearanceItem = ConditionalAppearanceItems.Add();
	
	AppearanceFilter = AppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	AppearanceFilter.LeftValue = New DataCompositionField("FoundDuplicates.Check");
	AppearanceFilter.ComparisonType = DataCompositionComparisonType.Equal;
	AppearanceFilter.RightValue = 0;
	
	AppearanceItem.Appearance.SetParameterValue("TextColor", InaccessibleDataColor);
	
	AppearanceField = AppearanceItem.Fields.Items.Add();
	AppearanceField.Field = New DataCompositionField("FoundDuplicates");
	
EndProcedure

&AtServer
Function StyleColorOrAuto(Val Name, Val Red = Undefined, Green = Undefined, Blue = Undefined)
	StyleItem = Metadata.StyleItems.Find(Name);
	If StyleItem <> Undefined AND StyleItem.Type = Metadata.ObjectProperties.StyleElementType.Color Then
		Return StyleColors[Name];
	EndIf;
	
	Return ?(Red = Undefined, New Color, New Color(Red, Green, Blue));
EndFunction

&AtServer
Function DuplicatesReplacementPairs()
	ReplacementPairs = New Map;
	
	DuplicatesTree = FormAttributeToValue("FoundDuplicates");
	SearchFilter = New Structure("Main", True);
	
	For Each Parent In DuplicatesTree.Rows Do
		MainInGroup = Parent.Rows.FindRows(SearchFilter)[0].Ref;
		
		For Each Child In Parent.Rows Do
			If Child.Check = 1 Then 
				ReplacementPairs.Insert(Child.Ref, MainInGroup);
			EndIf;
		EndDo;
	EndDo;
	
	Return ReplacementPairs;
EndFunction

&AtServerNoContext
Function AvailableFilterAttributes(MetadataObject)
	AttributesArray = New Array;
	For Each AttributeMetadata In MetadataObject.StandardAttributes Do
		If Not AttributeMetadata.Type.ContainsType(Type("ValueStorage")) Then
			AttributesArray.Add(AttributeMetadata.Name);
		EndIf
	EndDo;
	For Each AttributeMetadata In MetadataObject.Attributes Do
		If Not AttributeMetadata.Type.ContainsType(Type("ValueStorage")) Then
			AttributesArray.Add(AttributeMetadata.Name);
		EndIf
	EndDo;
	Return StrConcat(AttributesArray, ",");
EndFunction

&AtServerNoContext
Procedure AddMetaAttributesRules(RulesTable, Val Ignore, Val AllComparisonOptions, Val MetaCollection, Val FuzzySearchAvailable)
	
	For Each MetaAttribute In MetaCollection Do
		If Not Ignore.Property(MetaAttribute.Name) Then
			ComparisonOptions = ComparisonOptionsForType(MetaAttribute.Type, AllComparisonOptions, FuzzySearchAvailable);
			If ComparisonOptions <> Undefined Then
				// Can be compared
				RulesRow = RulesTable.Add();
				RulesRow.Attribute          = MetaAttribute.Name;
				RulesRow.ComparisonOptions = ComparisonOptions;
				
				AttributePresentation = MetaAttribute.Synonym;
				RulesRow.AttributePresentation = ?(IsBlankString(AttributePresentation), MetaAttribute.Name, AttributePresentation);
			EndIf;
		EndIf;
	EndDo;
	
EndProcedure

&AtServerNoContext
Function ComparisonOptionsForType(Val AvailableTypes, Val AllComparisonOptions, Val FuzzySearchAvailable) 
	
	IsStorage = AvailableTypes.ContainsType(Type("ValueStorage"));
	If IsStorage Then 
		// Cannot be compared
		Return Undefined;
	EndIf;
	
	IsString = AvailableTypes.ContainsType(Type("String"));
	IsFixedString = IsString AND AvailableTypes.StringQualifiers <> Undefined 
		AND AvailableTypes.StringQualifiers.Length <> 0;
		
	If IsString AND Not IsFixedString Then
		// Cannot be compared
		Return Undefined;
	EndIf;
	
	Result = New ValueList;
	FillPropertyValues(Result.Add(), AllComparisonOptions[0]);		// Matches
	
	If FuzzySearchAvailable AND IsString Then
		FillPropertyValues(Result.Add(), AllComparisonOptions[1]);	// Similar
	EndIf;
		
	Return Result;
EndFunction

////////////////////////////////////////////////////////////////////////////////
// Time-consuming operations

&AtClient
Procedure FindAndDeleteDuplicatesClient()
	
	Job = FindAndDeleteDuplicates();
	
	WaitSettings = TimeConsumingOperationsClient.IdleParameters(ThisObject);
	WaitSettings.OutputIdleWindow = False;
	WaitSettings.OutputProgressBar = True;
	WaitSettings.ExecutionProgressNotification = New NotifyDescription("FindAndRemoveDuplicatesProgress", ThisObject);;
	Handler = New NotifyDescription("FindAndRemoveDuplicatesCompletion", ThisObject);
	TimeConsumingOperationsClient.WaitForCompletion(Job, Handler, WaitSettings);
	
EndProcedure

&AtServer
Function FindAndDeleteDuplicates()
	
	ProcedureParameters = New Structure;
	ProcedureParameters.Insert("TakeAppliedRulesIntoAccount", TakeAppliedRulesIntoAccount);
	
	CurrentPage = Items.WizardSteps.CurrentPage;
	If CurrentPage = Items.PerformSearchStep Then
		
		Items.PerformSearch.StatePresentation.Text = NStr("ru = 'Поиск дублей...'; en = 'Searching for duplicates...'; pl = 'Wyszukiwanie duplikatów...';de = 'Duplikatsuch...';ro = 'Căutarea duplicatelor...';tr = 'Çiftleri arama...'; es_ES = 'Búsqueda de duplicados...'");

		ProcedureName = FormAttributeToValue("Object").Metadata().FullName() + ".ObjectModule.BackgroundSearchForDuplicates";
		MethodDescription = NStr("ru = 'Поиск и удаление дублей: Поиск дублей'; en = 'Duplicate purge: Search for duplicates'; pl = 'Wyszukaj i usuń duplikaty: Wyszukaj duplikaty';de = 'Suchen und Löschen von Duplikaten: Suchen Sie nach Duplikaten';ro = 'Căutarea și ștergerea duplicatelor: Căutarea duplicatelor';tr = 'Çiftleri ara ve sil: Çiftleri ara'; es_ES = 'Buscar y borrar los duplicados: Búsqueda de duplicados'");
		ProcedureParameters.Insert("DuplicatesSearchArea",     DuplicatesSearchArea);
		ProcedureParameters.Insert("MaxDuplicates", 1500);
		SearchRulesArray = New Array;
		For Each Rule In SearchRules Do
			SearchRulesArray.Add(New Structure("Attribute, Rule", Rule.Attribute, Rule.Rule));
		EndDo;
		ProcedureParameters.Insert("SearchRules", SearchRulesArray);
		ProcedureParameters.Insert("CompositionSchema", GetFromTempStorage(CompositionSchemaAddress));
		ProcedureParameters.Insert("PrefilterComposerSettings", PrefilterComposer.Settings);
		
	ElsIf CurrentPage = Items.DeletionStep Then
		
		Items.Deletion.StatePresentation.Text = NStr("ru = 'Удаление дублей...'; en = 'Deleting duplicates...'; pl = 'Usuwanie duplikatów ...';de = 'Duplikate löschen ...';ro = 'Ștergerea duplicatelor...';tr = 'Çiftleri silme...'; es_ES = 'Eliminando los duplicados ...'");
		
		ProcedureName = FormAttributeToValue("Object").Metadata().FullName() + ".ObjectModule.BackgroundDuplicateDeletion";
		MethodDescription = NStr("ru = 'Поиск и удаление дублей: Удаление дублей'; en = 'Duplicate purge: Delete duplicates'; pl = 'Wyszukiwanie i usuwanie duplikatów: Usuń duplikaty';de = 'Suchen und Löschen von Duplikaten: Löschen Sie Duplikate';ro = 'Căutarea și ștergerea duplicatelor: Ștergerea duplicatelor';tr = 'Çiftlerin aranması ve silinmesi: Çiftleri sil'; es_ES = 'Buscar y borrar los duplicados: Eliminar los duplicados'");
		ProcedureParameters.Insert("ReplacementPairs", DuplicatesReplacementPairs());
		
	Else
		Raise NStr("ru = 'Некорректное состояние в НайтиИУдалитьДубли.'; en = 'Invalid status in FindAndDeleteDuplicates.'; pl = 'Nieprawidłowy stan w НайтиИУдалитьДубли.';de = 'Falscher Zustand in FindenUndLöschenDuplikat.';ro = 'Statut incorect în НайтиИУдалитьДубли.';tr = 'Çoğalt Bul ve Sil''de geçersiz durum.'; es_ES = 'Estado incorrecto en НайтиИУдалитьДубли.'");
	EndIf;
	
	StartSettings = TimeConsumingOperations.BackgroundExecutionParameters(UUID);
	StartSettings.BackgroundJobDescription = MethodDescription;
	
	Return TimeConsumingOperations.ExecuteInBackground(ProcedureName, ProcedureParameters, StartSettings);
EndFunction

&AtClient
Procedure FindAndRemoveDuplicatesProgress(Progress, AdditionalParameters) Export
	
	If Progress = Undefined Or Progress.Progress = Undefined Then
		Return;
	EndIf;
	
	CurrentPage = Items.WizardSteps.CurrentPage;
	If CurrentPage = Items.PerformSearchStep Then
		
		Message = NStr("ru = 'Поиск дублей...'; en = 'Searching for duplicates...'; pl = 'Wyszukiwanie duplikatów...';de = 'Duplikatsuch...';ro = 'Căutarea duplicatelor...';tr = 'Çiftleri arama...'; es_ES = 'Búsqueda de duplicados...'");
		If Progress.Progress.Text = "CalculateUsageInstances" Then 
			Message = NStr("ru = 'Выполняется расчет мест использования дублей...'; en = 'Searching for duplicate locations...'; pl = 'Są wykonywane obliczenia miejsc wykorzystania duplikatów...';de = 'Die Berechnung der Verwendung von Duplikaten wird durchgeführt...';ro = 'Are loc calcularea locurilor de utilizare a duplicatelor...';tr = 'Çiftlerin kullanımının hesaplanması yapılır ...'; es_ES = 'Se están calculando los lugares de uso de duplicados...'");
		ElsIf Progress.Progress.Percent > 0 Then
			Message = Message + " " 
				+ StringFunctionsClientServer.SubstituteParametersToString(
					NStr("ru = '(найдено %1)'; en = '(%1 locations found)'; pl = '(znaleziono %1)';de = '(gefunden %1)';ro = '(găsite %1)';tr = '(Bulunan%1)'; es_ES = '(encontrado %1)'"), Progress.Progress.Percent);
		EndIf;
		Items.PerformSearch.StatePresentation.Text = Message;
		
	ElsIf CurrentPage = Items.DeletionStep Then
		
		Message = NStr("ru = 'Удаление дублей...'; en = 'Deleting duplicates...'; pl = 'Usuwanie duplikatów ...';de = 'Duplikate löschen ...';ro = 'Ștergerea duplicatelor...';tr = 'Çiftleri silme...'; es_ES = 'Eliminando los duplicados ...'");
		If Progress.Progress.Percent > 0 Then
			Message = Message + " " 
				+ StringFunctionsClientServer.SubstituteParametersToString(
					NStr("ru = '(удалено %1 из %2)'; en = '(%1 out of %2 deleted)'; pl = '(usunięto %1 z %2)';de = '(entfernt %1 von %2)';ro = '(șterse %1 din %2)';tr = '(kaldırıldı%1%2)'; es_ES = '(eliminado %1 de %2)'"), Progress.Progress.Percent, TotalFoundDuplicates);
		EndIf;
		Items.Deletion.StatePresentation.Text = Message;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure FindAndRemoveDuplicatesCompletion(Job, AdditionalParameters) Export
	WizardSettings.ShowDialogBeforeClose = False;
	Activate();
	CurrentPage = Items.WizardSteps.CurrentPage;
	
	// The job is canceled.
	If Job = Undefined Then 
		Return;
	EndIf;
	
	If Job.Status <> "Completed" Then
		// Background job is completed with error.
		If CurrentPage = Items.PerformSearchStep Then
			Brief = NStr("ru = 'При поиске дублей возникла ошибка:'; en = 'Error occurred searching for duplicates:'; pl = 'Podczas wyszukiwania duplikatów wystąpił błąd:';de = 'Bei der Suche nach Duplikaten ist ein Fehler aufgetreten:';ro = 'Eroare la căutarea duplicatelor:';tr = 'Kopyaları ararken hata oluştu:'; es_ES = 'Al buscar los duplicados ha ocurrido un error:'");
		ElsIf CurrentPage = Items.DeletionStep Then
			Brief = NStr("ru = 'При удалении дублей возникла ошибка:'; en = 'Error occurred deleting duplicates:'; pl = 'Podczas usuwania duplikatów wystąpił błąd:';de = 'Beim Löschen von Duplikaten ist ein Fehler aufgetreten:';ro = 'Eroare la ștergerea duplicatelor:';tr = 'Kopyaları silerken hata oluştu:'; es_ES = 'Al eliminar los duplicados ha ocurrido un error:'");
		EndIf;
		Brief = Brief + Chars.LF + Job.BriefErrorPresentation;
		More = Brief + Chars.LF + Chars.LF + Job.DetailedErrorPresentation;
		Items.ErrorTextLabel.Title = Brief;
		Items.DetailsRef.ToolTip    = More;
		GoToWizardStep(Items.ErrorOccurredStep);
		Return;
	EndIf;
	
	If CurrentPage = Items.PerformSearchStep Then
		TotalFoundDuplicates = FillDuplicatesSearchResults(Job.ResultAddress);
		TotalItems = TotalFoundDuplicates;
		If TotalFoundDuplicates > 0 Then
			UpdateFoundDuplicatesStateDetails(ThisObject);
			GoToWizardStep(WizardSettings.CurrentStep.IndexOf + 1);
		Else
			GoToWizardStep(Items.DuplicatesNotFoundStep);
		EndIf;
	ElsIf CurrentPage = Items.DeletionStep Then
		Success = FillDuplicatesDeletionResults(Job.ResultAddress);
		If Success = True Then
			// All duplicate groups are replaced.
			GoToWizardStep(WizardSettings.CurrentStep.IndexOf + 1);
		Else
			// Cannot replace all usage instances.
			GoToWizardStep(Items.UnsuccessfulReplacementsStep);
		EndIf;
	EndIf;
	
EndProcedure

&AtServer
Function FillDuplicatesSearchResults(Val ResultAddress)
	
	// Getting the result of the DuplicatesGroups function of the processing module.
	Data = GetFromTempStorage(ResultAddress);
	DuplicatesSearchErrorDescription = Data.ErrorDescription;
	
	TreeItems = FoundDuplicates.GetItems();
	TreeItems.Clear();
	
	UsageInstances = Data.UsageInstances;
	DuplicatesTable      = Data.DuplicatesTable;
	
	RowsFilter = New Structure("Parent");
	InstancesFilter  = New Structure("Ref");
	
	TotalFoundDuplicates = 0;
	
	AllGroups = DuplicatesTable.FindRows(RowsFilter);
	For Each Folder In AllGroups Do
		RowsFilter.Parent = Folder.Ref;
		GroupItems = DuplicatesTable.FindRows(RowsFilter);
		
		TreeGroup = TreeItems.Add();
		TreeGroup.Count = GroupItems.Count();
		TreeGroup.Check = 1;
		
		MaxRow = Undefined;
		MaxInstances   = -1;
		For Each Item In GroupItems Do
			TreeRow = TreeGroup.GetItems().Add();
			FillPropertyValues(TreeRow, Item, "Ref, Code, Description");
			TreeRow.Check = 1;
			
			InstancesFilter.Ref = Item.Ref;
			TreeRow.Count = UsageInstances.FindRows(InstancesFilter).Count();
			
			If MaxInstances < TreeRow.Count Then
				If MaxRow <> Undefined Then
					MaxRow.Main = False;
				EndIf;
				MaxRow = TreeRow;
				MaxInstances   = TreeRow.Count;
				MaxRow.Main = True;
			EndIf;
			
			TotalFoundDuplicates = TotalFoundDuplicates + 1;
		EndDo;
		
		// Setting a candidate by the maximum reference.
		TreeGroup.Description = MaxRow.Description + " (" + TreeGroup.Count + ")";
	EndDo;
	
	// Saving usage instances for further filter.
	ProbableDuplicateUsageInstances.Clear();
	Items.CurrentDuplicatesGroupDetails.Title = NStr("ru = 'Дублей не найдено'; en = 'No duplicates found'; pl = 'Duplikatów nie znaleziono';de = 'Duplikate werden nicht gefunden';ro = 'Nu au fost găsite duplicate';tr = 'Çiftler bulunamadı'; es_ES = 'Duplicados no se han encontrado'");
	
	If IsTempStorageURL(UsageInstancesAddress) Then
		DeleteFromTempStorage(UsageInstancesAddress);
	EndIf;
	UsageInstancesAddress = PutToTempStorage(UsageInstances, UUID);
	Return TotalFoundDuplicates;
	
EndFunction

&AtServer
Function FillDuplicatesDeletionResults(Val ResultAddress)
	// ErrorsTable - a result of the ReplaceReferences function of the module.
	ErrorsTable = GetFromTempStorage(ResultAddress);
	
	If IsTempStorageURL(ReplacementResultAddress) Then
		DeleteFromTempStorage(ReplacementResultAddress);
	EndIf;
	
	CompletedWithoutErrors = ErrorsTable.Count() = 0;
	LastCandidate  = Undefined;
	
	If CompletedWithoutErrors Then
		ProcessedItemsTotal = 0; 
		MainItemsTotal   = 0;
		For Each DuplicatesGroup In FoundDuplicates.GetItems() Do
			If DuplicatesGroup.Check Then
				For Each Candidate In DuplicatesGroup.GetItems() Do
					If Candidate.Main Then
						LastCandidate = Candidate.Ref;
						ProcessedItemsTotal   = ProcessedItemsTotal + 1;
						MainItemsTotal     = MainItemsTotal + 1;
					ElsIf Candidate.Check Then 
						ProcessedItemsTotal = ProcessedItemsTotal + 1;
					EndIf;
				EndDo;
			EndIf;
		EndDo;
		
		If MainItemsTotal = 1 Then
			// Multiple duplicates to one item.
			If LastCandidate = Undefined Then
				FoundDuplicatesStateDetails = New FormattedString(
					StringFunctionsClientServer.SubstituteParametersToString(
						NStr("ru = 'Все найденные дубли (%1) успешно объединены'; en = 'All %1 duplicates have been merged.'; pl = 'Wszystkie znalezione duplikaty (%1) zostały pomyślnie zgrupowane';de = 'Alle gefundenen Duplikate (%1) wurden erfolgreich gruppiert';ro = 'Toate duplicatele găsite (%1) sunt grupate cu succes';tr = 'Bulunan tüm kopyalar (%1) başarıyla gruplandırıldı'; es_ES = 'Todos los duplicados encontrados (%1) se han agrupado con éxito'"),
						ProcessedItemsTotal));
			Else
				LastCandidateAsString = Common.SubjectString(LastCandidate);
				FoundDuplicatesStateDetails = New FormattedString(
					StringFunctionsClientServer.SubstituteParametersToString(
						NStr("ru = 'Все найденные дубли (%1) успешно объединены
							|в ""%2""'; 
							|en = 'All %1 duplicates have been merged
							|into %2.'; 
							|pl = 'Wszystkie znalezione duplikaty (%1) zostały pomyślnie połączone
							|w ""%2""';
							|de = 'Alle gefundenen Duplikate (%1) wurden erfolgreich zusammengeführt
							|in ""%2""';
							|ro = 'Toate duplicatele găsite (%1) sunt grupate cu succes
							|în ""%2""';
							|tr = 'Bulunan tüm kopyalar (%1) başarıyla
							| ile %2 gruplandırıldı'; 
							|es_ES = 'Todos los duplicados encontrados (%1) se han combinado con éxito
							|en ""%2""'"),
						ProcessedItemsTotal, LastCandidateAsString));
			EndIf;
		Else
			// Multiple duplicates to multiple groups.
			FoundDuplicatesStateDetails = New FormattedString(
				StringFunctionsClientServer.SubstituteParametersToString(
					NStr("ru = 'Все найденные дубли (%1) успешно объединены.
						|Оставлено элементов (%2).'; 
						|en = 'All %1 duplicates have been merged.
						|Number of resulted items: %2.'; 
						|pl = 'Wszystkie znalezione duplikaty (%1) zostały pomyślnie połączone.
						|Zatrzymano elementy (%2).';
						|de = 'Alle gefundenen Duplikate (%1) erfolgreich zusammengeführt.
						|Gehalten Elemente (%2).';
						|ro = 'Toate duplicatele găsite (%1) sunt grupate cu succes.
						|Elemente rămase (%2).';
						|tr = 'Bulunan tüm kopyalar (%1) başarıyla birleştirildi. 
						|Tutulan öğeler (%2).'; 
						|es_ES = 'Todos los duplicados encontrados (%1) se han combinado con éxito.
						|Artículos guardados (%2).'"),
					ProcessedItemsTotal,
					MainItemsTotal));
		EndIf;
	EndIf;
	
	UnprocessedDuplicates.GetItems().Clear();
	UnprocessedItemsUsageInstances.Clear();
	ProbableDuplicateUsageInstances.Clear();
	
	If CompletedWithoutErrors Then
		FoundDuplicates.GetItems().Clear();
		Return True;
	EndIf;
	
	// Saving for further access when analyzing references.
	ReplacementResultAddress = PutToTempStorage(ErrorsTable, UUID);
	
	// Generating a duplicate tree by errors.
	ValueToFormAttribute(FormAttributeToValue("FoundDuplicates"), "UnprocessedDuplicates");
	
	// Analyzing the remains
	Filter = New Structure("Ref");
	Parents = UnprocessedDuplicates.GetItems();
	ParentPosition = Parents.Count() - 1;
	While ParentPosition >= 0 Do
		Parent = Parents[ParentPosition];
		
		Children = Parent.GetItems();
		ChildPosition = Children.Count() - 1;
		MainChild = Children[0];	// There is at least one
		
		While ChildPosition >= 0 Do
			Child = Children[ChildPosition];
			
			If Child.Main Then
				MainChild = Child;
				Filter.Ref = Child.Ref;
				Child.Count = ErrorsTable.FindRows(Filter).Count();
				
			ElsIf ErrorsTable.Find(Child.Ref, "Ref") = Undefined Then
				// Successfully deleted, no errors.
				Children.Delete(Child);
				
			Else
				Filter.Ref = Child.Ref;
				Child.Count = ErrorsTable.FindRows(Filter).Count();
				
			EndIf;
			
			ChildPosition = ChildPosition - 1;
		EndDo;
		
		ChildrenCount = Children.Count();
		If ChildrenCount = 1 AND Children[0].Main Then
			Parents.Delete(Parent);
		Else
			Parent.Count = ChildrenCount - 1;
			Parent.Description = MainChild.Description + " (" + ChildrenCount + ")";
		EndIf;
		
		ParentPosition = ParentPosition - 1;
	EndDo;
	
	Return False;
EndFunction

&AtClient
Procedure AfterConfirmCancelJob(Response, ExecutionParameters) Export
	If Response = DialogReturnCode.Abort Then
		WizardSettings.ShowDialogBeforeClose = False;
		Close();
	EndIf;
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Internal procedures and wizard functions

&AtClientAtServerNoContext
Function WizardButton()
	// Description of wizard button settings.
	//
	// Returns:
	//   Structure - Form button settings.
	//       * Title         - String - a button title.
	//       * Tooltip - String - a tooltip for the button.
	//       * Visible - Boolean - if True, the button is visible. The default value is True.
	//       * Availability - Boolean - if True, you can click the button. The default value is True.
	//       * DefaultButton - Boolean - if True, the button is the main button of the form. Default value:
	//                                      False.
	//
	// See also:
	//   "FormButton" in Syntax Assistant.
	//
	Result = New Structure;
	Result.Insert("Title", "");
	Result.Insert("ToolTip", "");
	
	Result.Insert("Enabled", True);
	Result.Insert("Visible", True);
	Result.Insert("DefaultButton", False);
	
	Return Result;
EndFunction

&AtClientAtServerNoContext
Procedure UpdateWizardButtonProperties(WizardButton, Details)
	
	FillPropertyValues(WizardButton, Details);
	WizardButton.ExtendedTooltip.Title = Details.ToolTip;
	
EndProcedure

#EndRegion