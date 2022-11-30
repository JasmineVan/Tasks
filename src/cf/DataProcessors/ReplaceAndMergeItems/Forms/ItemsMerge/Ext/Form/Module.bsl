///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

// This form is parameterized.
//
// Parameters:
//     ReferenceList - Array, ValueList - a set of references to analyze.
//                                             The parameter can be a collection of objects that have the "Reference" field.
//

#Region EventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	SetConditionalAppearance();
	
	// Passing parameters to the UsageInstances table.
	// Initializing the MainItem, ReferencesToReplaceCommonOwner, and ParameterErrorText attributes.
	InitializeReferencesToMerge( RefArrayFromSet(Parameters.RefSet) );
	If Not IsBlankString(ParametersErrorText) Then
		// A warning will be issued on opening;
		Return;
	EndIf;
	
	ObjectMetadata = MainItem.Ref.Metadata();
	HasRightToDeletePermanently = AccessRight("DataAdministration", Metadata) 
		Or AccessRight("InteractiveDelete", ObjectMetadata);
	ReplacementNotificationEvent        = DataProcessors.ReplaceAndMergeItems.ReplacementNotificationEvent();
	
	CurrentDeletionOption = "Check";
	
	// Initialization of step-by-step wizard steps.
	InitializeStepByStepWizardSettings();
	
	// 1. Searching for usage instances by parameters.
	SearchStep = AddWizardStep(Items.SearchForUsageInstancesStep);
	SearchStep.BackButton.Visible = False;
	SearchStep.NextButton.Visible = False;
	SearchStep.CancelButton.Title = NStr("ru = 'Прервать'; en = 'Cancel'; pl = 'Przerwij';de = 'Abbrechen';ro = 'Eșuat';tr = 'Durdur'; es_ES = 'Anular'");
	SearchStep.CancelButton.ToolTip = NStr("ru = 'Отказаться от объединения элементов'; en = 'Cancel merging.'; pl = 'Odmów łączenia elementów';de = 'Verweigern Sie das Zusammenführen von Elementen';ro = 'Respinge gruparea elementelor';tr = 'Öğeleri birleştirmeyi reddet'; es_ES = 'Rechazar la combinación de artículos'");
	
	// 2. Main item selection.
	Step = AddWizardStep(Items.MainItemSelectionStep);
	Step.BackButton.Visible = False;
	Step.NextButton.DefaultButton = True;
	Step.NextButton.Title = NStr("ru = 'Объединить >'; en = 'Merge >'; pl = 'Połącz >';de = 'Zusammenführen >';ro = 'Unire >';tr = 'Birleştir >'; es_ES = 'Combinar >'");
	Step.NextButton.ToolTip = NStr("ru = 'Начать объединение элементов'; en = 'Run merging.'; pl = 'Zacznij łączyć elementy';de = 'Beginnen Sie mit dem Zusammenführen von Elementen';ro = 'Începeți să îmbinați articolele';tr = 'Öğeleri birleştirmeye başla'; es_ES = 'Empezar a combinar los artículos'");
	Step.CancelButton.Title = NStr("ru = 'Отмена'; en = 'Cancel'; pl = 'Anuluj';de = 'Abbrechen';ro = 'Revocare';tr = 'İptal'; es_ES = 'Cancelar'");
	Step.CancelButton.ToolTip = NStr("ru = 'Отказаться от объединения элементов'; en = 'Cancel merging.'; pl = 'Odmów łączenia elementów';de = 'Verweigern Sie das Zusammenführen von Elementen';ro = 'Respinge gruparea elementelor';tr = 'Öğeleri birleştirmeyi reddet'; es_ES = 'Rechazar la combinación de artículos'");
	
	// 3. Waiting for process.
	Step = AddWizardStep(Items.MergeStep);
	Step.BackButton.Visible = False;
	Step.NextButton.Visible = False;
	Step.CancelButton.Title = NStr("ru = 'Прервать'; en = 'Cancel'; pl = 'Przerwij';de = 'Abbrechen';ro = 'Eșuat';tr = 'Durdur'; es_ES = 'Anular'");
	Step.CancelButton.ToolTip = NStr("ru = 'Прервать объединение элементов'; en = 'Cancel merging.'; pl = 'Zatrzymaj łączenie elementów';de = 'Aufhören Elemente zu verbinden';ro = 'Întrerupe gruparea elementelor';tr = 'Öğelere katılmayı durdur'; es_ES = 'Parar juntar los artículos'");
	
	// 4. Successful merge.
	Step = AddWizardStep(Items.SuccessfulCompletionStep);
	Step.BackButton.Visible = False;
	Step.NextButton.Visible = False;
	Step.CancelButton.DefaultButton = True;
	Step.CancelButton.Title = NStr("ru = 'Закрыть'; en = 'Close'; pl = 'Zamknij';de = 'Schließen';ro = 'Închideți';tr = 'Kapat'; es_ES = 'Cerrar'");
	Step.CancelButton.ToolTip = NStr("ru = 'Закрыть результаты объединения'; en = 'Close merge results.'; pl = 'Zamknij wyniki grupowania';de = 'Schließen Sie die Gruppierungsergebnisse';ro = 'Închide rezultatele grupării';tr = 'Gruplama sonuçlarını kapat'; es_ES = 'Cerrar los resultado de agrupación'");
	
	// 5. Reference replacement issues.
	Step = AddWizardStep(Items.RetryMergeStep);
	Step.BackButton.Title = NStr("ru = '< В начало'; en = '< To first step'; pl = '< do Strony Głównej';de = '< Zum Anfang';ro = '< Salt la prima pagină';tr = '< Başa'; es_ES = '< Ir a la página principal'");
	Step.BackButton.ToolTip = NStr("ru = 'Вернутся к выбору основного элемента'; en = 'Go to the replacement item selection.'; pl = 'Wróć do wyboru głównego elementu';de = 'Gehe zurück zur Hauptelementauswahl';ro = 'Revenire la selectarea elementului principal';tr = 'Ana öğe seçimine geri dön'; es_ES = 'Volver a la selección principal de artículos'");
	Step.NextButton.DefaultButton = True;
	Step.NextButton.Title = NStr("ru = 'Повторить'; en = 'Merge again'; pl = 'Powtórz';de = 'Wiederholen';ro = 'Repetare';tr = 'Tekrarla'; es_ES = 'Repetir'");
	Step.NextButton.ToolTip = NStr("ru = 'Повторить объединение'; en = 'Merge again'; pl = 'Powtórz grupowanie';de = 'Wiederholen Sie die Gruppierung';ro = 'Repetare gruparea';tr = 'Gruplamayı tekrarla'; es_ES = 'Repetir la agrupación'");
	Step.CancelButton.Title = NStr("ru = 'Отмена'; en = 'Cancel'; pl = 'Anuluj';de = 'Abbrechen';ro = 'Revocare';tr = 'İptal'; es_ES = 'Cancelar'");
	Step.CancelButton.ToolTip = NStr("ru = 'Закрыть результаты объединения'; en = 'Close merge results.'; pl = 'Zamknij wyniki grupowania';de = 'Schließen Sie die Gruppierungsergebnisse';ro = 'Închide rezultatele grupării';tr = 'Gruplama sonuçlarını kapat'; es_ES = 'Cerrar los resultado de agrupación'");
	
	// 6. Runtime errors.
	Step = AddWizardStep(Items.ErrorOccurredStep);
	Step.BackButton.Visible = False;
	Step.NextButton.Visible = False;
	Step.CancelButton.Title = NStr("ru = 'Закрыть'; en = 'Close'; pl = 'Zamknij';de = 'Schließen';ro = 'Închideți';tr = 'Kapat'; es_ES = 'Cerrar'");
	
	// Updating form items.
	WizardSettings.CurrentStep = SearchStep;
	VisibleEnabled(ThisObject);
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	// Checking whether an error message is required.
	If Not IsBlankString(ParametersErrorText) Then
		Cancel = True;
		ShowMessageBox(, ParametersErrorText);
		Return;
	EndIf;
	
	// Running wizard.
	OnActivateWizardStep();
EndProcedure

&AtClient
Procedure BeforeClose(Cancel, Exit, WarningText, StandardProcessing)
	
	// References replacement is a critical step that requires confirmation of cancellation.
	If WizardSettings.ShowDialogBeforeClose
		AND Items.WizardSteps.CurrentPage = Items.MergeStep Then
		
		Cancel = True;
		If Exit Then
			Return;
		EndIf;
		
		QuestionText = NStr("ru = 'Прервать объединение элементов и закрыть форму?'; en = 'Do you want to cancel merging and close the form?'; pl = 'Zaprzestać łączyć elementy i zamknąć formularz?';de = 'Das Zusammenführen von Elementen beenden und das Formular schließen?';ro = 'Nu mai fuzionați elementele și închideți formularul?';tr = 'Öğeleri birleştirmeyi bırak ve formu kapat?'; es_ES = '¿Parar la combinación de artículos y cerrar el formulario?'");
		
		Buttons = New ValueList;
		Buttons.Add(DialogReturnCode.Abort, NStr("ru = 'Прервать'; en = 'Cancel merging'; pl = 'Przerwij';de = 'Abbrechen';ro = 'Renunțați';tr = 'Durdur'; es_ES = 'Anular'"));
		Buttons.Add(DialogReturnCode.No,      NStr("ru = 'Не прерывать'; en = 'Continue merging'; pl = 'Nie przerywać';de = 'Nicht unterbrechen';ro = 'Nu întrerupe';tr = 'Kesme'; es_ES = 'No interrumpir'"));
		
		Handler = New NotifyDescription("AfterConfirmCancelJob", ThisObject);
		ShowQueryBox(Handler, QuestionText, Buttons, , DialogReturnCode.No);
		
	EndIf;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure MainItemSelectionTooltipURLProcessing(Item, URLValue, StandardProcessing)
	StandardProcessing = False;
	
	If URLValue = "SwitchDeletionMode" Then
		If CurrentDeletionOption = "Directly" Then
			CurrentDeletionOption = "Check" 
		Else
			CurrentDeletionOption = "Directly" 
		EndIf;
		GenerateMergeTooltip();
	EndIf;
	
EndProcedure

&AtClient
Procedure DetailsRefClick(Item)
	StandardSubsystemsClient.ShowDetailedInfo(Undefined, Item.ToolTip);
EndProcedure

#EndRegion

#Region UsageInstancesFormTableItemsEventHandlers

&AtClient
Procedure UsageInstancesSelection(Item, RowSelected, Field, StandardProcessing)
	
	StandardProcessing = False;
	Ref = UsageInstances.FindByID(RowSelected).Ref;
	
	If Field <> Items.UsageInstancesUsageCount Then
		ShowValue(, Ref);
		Return;
	EndIf;
	
	RefSet = New Array;
	RefSet.Add(Ref);
	FindAndDeleteDuplicatesDuplicatesClient.ShowUsageInstances(RefSet);
	
EndProcedure

&AtClient
Procedure UsageInstancesBeforeAddRow(Item, Cancel, Clone, Parent, Folder)
	
	Cancel = True;
	If Clone Then
		Return;
	EndIf;
	
	// Always add an item of the same type as the main one.
	ChoiceFormName = SelectionFormNameByReference(MainItem);
	If Not IsBlankString(ChoiceFormName) Then
		FormParameters = New Structure("MultipleChoice", True);
		If ReferencesToReplaceCommonOwner <> Undefined Then
			FormParameters.Insert("Filter", New Structure("Owner", ReferencesToReplaceCommonOwner));
		EndIf;
		OpenForm(ChoiceFormName, FormParameters, Item);
	EndIf;
EndProcedure

&AtClient
Procedure UsageInstancesBeforeDelete(Item, Cancel)
	Cancel = True;
	
	CurrentData = Item.CurrentData;
	If CurrentData=Undefined Or UsageInstances.Count()<3 Then
		Return;
	EndIf;
	
	Ref = CurrentData.Ref;
	Code    = String(CurrentData.Code);
	
	QuestionText = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("ru = 'Удалить из списка для объединения элемент ""%1""?'; en = 'Delete item %1 from the merge list?'; pl = 'Usunąć element ""%1"" z listy do połączenia?';de = 'Element ""%1"" aus der Liste zum Zusammenführen löschen?';ro = 'Ștergeți elementul ""%1"" din lista pentru grupare?';tr = 'Öğe ""%1"" yenileme listesinden silinsin mi?'; es_ES = '¿Borrar el artículo ""%1"" de la lista para combinar?'"),
		String(Ref) + ?(IsBlankString(Code), "", " (" + Code + ")" ));
	
	Notification = New NotifyDescription("UsageInstancesBeforeDeleteCompletion", ThisObject, New Structure);
	Notification.AdditionalParameters.Insert("CurrentRow", Item.CurrentRow);
	ShowQueryBox(Notification, QuestionText, QuestionDialogMode.YesNo);
EndProcedure

&AtClient
Procedure UsageInstancesChoiceProcessing(Item, ValueSelected, StandardProcessing)
	StandardProcessing = False;
	
	If TypeOf(ValueSelected) = Type("Array") Then
		ItemsToAdd = ValueSelected;
	Else
		ItemsToAdd = New Array;
		ItemsToAdd.Add(ValueSelected);
	EndIf;
	
	AddUsageInstancesRows(ItemsToAdd);
	GenerateMergeTooltip();
EndProcedure

#EndRegion

#Region UnsuccessfulReplacementsFormTableItemEventHandlers

&AtClient
Procedure UnsuccessfulReplacementsOnActivateRow(Item)
	CurrentData = Item.CurrentData;
	If CurrentData = Undefined Then
		FailureReasonDetails = "";
	Else
		FailureReasonDetails = CurrentData.DetailedReason;
	EndIf;
EndProcedure

&AtClient
Procedure UnsuccessfulReplacementsChoice(Item, RowSelected, Field, StandardProcessing)
	StandardProcessing = False;
	
	Ref = UnsuccessfulReplacements.FindByID(RowSelected).Ref;
	If Ref <> Undefined Then
		ShowValue(, Ref);
	EndIf;

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
Procedure OpenUsageInstancesItem(Command)
	CurrentData = Items.UsageInstances.CurrentData;
	If CurrentData <> Undefined Then
		ShowValue(, CurrentData.Ref);
	EndIf;
EndProcedure

&AtClient
Procedure UsageInstances(Command)
	
	CurrentData = Items.UsageInstances.CurrentData;
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	RefSet = New Array;
	RefSet.Add(CurrentData.Ref);
	FindAndDeleteDuplicatesDuplicatesClient.ShowUsageInstances(RefSet);
	
EndProcedure

&AtClient
Procedure AllUsageInstances(Command)
	
	If UsageInstances.Count() > 0 Then 
		FindAndDeleteDuplicatesDuplicatesClient.ShowUsageInstances(UsageInstances);
	EndIf;
	
EndProcedure

&AtClient
Procedure SetAsMain(Command)
	CurrentData = Items.UsageInstances.CurrentData;
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	MainItem = CurrentData.Ref;
	GenerateMergeTooltip();
EndProcedure

&AtClient
Procedure OpenUnsuccessfulReplacementItem(Command)
	CurrentData = Items.UnsuccessfulReplacements.CurrentData;
	If CurrentData <> Undefined Then
		ShowValue(, CurrentData.Ref);
	EndIf;
EndProcedure

&AtClient
Procedure ExpandAllUnsuccessfulReplacements(Command)
	FormTree = Items.UnsuccessfulReplacements;
	For Each Item In UnsuccessfulReplacements.GetItems() Do
		FormTree.Expand(Item.GetID(), True);
	EndDo;
EndProcedure

&AtClient
Procedure CollapseAllUnsuccessfulReplacements(Command)
	FormTree = Items.UnsuccessfulReplacements;
	For Each Item In UnsuccessfulReplacements.GetItems() Do
		FormTree.Collapse(Item.GetID());
	EndDo;
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
Procedure VisibleEnabled(Form)
	
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
	VisibleEnabled(ThisObject);
	OnActivateWizardStep();
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Wizard events

&AtClient
Procedure OnActivateWizardStep()
	
	CurrentPage = Items.WizardSteps.CurrentPage;
	
	If CurrentPage = Items.SearchForUsageInstancesStep Then
		
		RunBackgroundJobClient();
		
	ElsIf CurrentPage = Items.MainItemSelectionStep Then
		
		GenerateMergeTooltip();
		
	ElsIf CurrentPage = Items.MergeStep Then
		
		WizardSettings.ShowDialogBeforeClose = True;
		RunBackgroundJobClient();
		
	ElsIf CurrentPage = Items.SuccessfulCompletionStep Then
		
		Items.MergeResult.Title = CompleteMessage() + " """ + String(MainItem) + """";
		
		UpdatedItemsList = New Array;
		For Each Row In UsageInstances Do
			UpdatedItemsList.Add(Row.Ref);
		EndDo;
		NotifyOfSuccessfulReplacement(UpdatedItemsList);
		
	ElsIf CurrentPage = Items.RetryMergeStep Then
		
		// Refreshing number of failures.
		GenerateUnsuccessfulReplacementLabel();
		
		// Notifying of partial successful replacement.
		UpdatedItemsList = DeleteProcessedItemsFromUsageInstances();	// Deleting the item from the list of options.
		NotifyOfSuccessfulReplacement(UpdatedItemsList);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure WizardStepNext()
	
	CurrentPage = Items.WizardSteps.CurrentPage;
	
	If CurrentPage = Items.MainItemSelectionStep Then
		
		ErrorText = CheckCanReplaceReferences();
		If Not IsBlankString(ErrorText) Then
			StandardSubsystemsClient.ShowQuestionToUser(Undefined, 
				StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = 'Невозможно объединить элементы по причине:
					|%1'; 
					|en = 'Cannot merge items due to:
					|%1'; 
					|pl = 'Nie można połączyć elementy z powodu:
					|%1';
					|de = 'Elemente können nicht zusammengeführt werden, weil:
					|%1';
					|ro = 'Eșec la unificarea elementelor din motivul:
					|%1';
					|tr = 'Aşağıdaki nedenden dolayı nesneler birleştirilemedi: 
					|%1'; 
					|es_ES = 'Es imposible unir los elementos a causa:
					|%1'"), ErrorText), QuestionDialogMode.OK);
			Return;
		EndIf;
		
		GoToWizardStep(WizardSettings.CurrentStep.IndexOf + 1);
		
	ElsIf CurrentPage = Items.RetryMergeStep Then
		
		GoToWizardStep(Items.MergeStep);
		
	Else
		
		GoToWizardStep(WizardSettings.CurrentStep.IndexOf + 1);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure WizardStepBack()
	
	CurrentPage = Items.WizardSteps.CurrentPage;
	
	If CurrentPage = Items.RetryMergeStep Then
		
		GoToWizardStep(Items.SearchForUsageInstancesStep);
		
	Else
		
		GoToWizardStep(WizardSettings.CurrentStep.IndexOf - 1);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure WizardStepCancel()
	
	CurrentPage = Items.WizardSteps.CurrentPage;
	
	If CurrentPage = Items.MergeStep Then
		
		WizardSettings.ShowDialogBeforeClose = False;
		
	EndIf;
	
	If IsOpen() Then
		Close();
	EndIf;
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Internal merge items procedures

&AtServer
Procedure SetConditionalAppearance()

	ConditionalAppearance.Items.Clear();

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.UsageInstancesMain.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("UsageInstances.Ref");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotEqual;
	ItemFilter.RightValue = New DataCompositionField("MainItem");

	Item.Appearance.SetParameterValue("Show", False);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.UsageInstancesRef.Name);

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.UsageInstancesCode.Name);

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.UsageInstancesUsageCount.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("UsageInstances.Ref");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = New DataCompositionField("MainItem");

	Item.Appearance.SetParameterValue("Font", New Font(WindowsFonts.DefaultGUIFont, , , True, False, False, False, ));

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.UsageInstancesNotUsed.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("UsageInstances.UsageInstancesCount");
	ItemFilter.ComparisonType = DataCompositionComparisonType.LessOrEqual;
	ItemFilter.RightValue = 0;

	Item.Appearance.SetParameterValue("Visible", True);
	Item.Appearance.SetParameterValue("Show", True);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.UsageInstancesNotUsed.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("UsageInstances.UsageInstancesCount");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Greater;
	ItemFilter.RightValue = 0;

	Item.Appearance.SetParameterValue("Visible", False);
	Item.Appearance.SetParameterValue("Show", False);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.UsageInstancesUsageCount.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("UsageInstances.UsageInstancesCount");
	ItemFilter.ComparisonType = DataCompositionComparisonType.LessOrEqual;
	ItemFilter.RightValue = 0;

	Item.Appearance.SetParameterValue("Visible", False);
	Item.Appearance.SetParameterValue("Show", False);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.UnsuccessfulReplacementsCode.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("UnsuccessfulReplacements.Code");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	Item.Appearance.SetParameterValue("Visible", False);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.UsageInstancesUsageCount.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("UsageInstances.UsageInstancesCount");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Greater;
	ItemFilter.RightValue = 0;

	Item.Appearance.SetParameterValue("Visible", True);
	Item.Appearance.SetParameterValue("Show", True);

EndProcedure

&AtServer
Procedure InitializeReferencesToMerge(Val RefsArray)
	
	CheckResult = CheckReferencesToMerge(RefsArray);
	ParametersErrorText = CheckResult.Error;
	If Not IsBlankString(ParametersErrorText) Then
		Return;
	EndIf;
	
	MainItem = RefsArray[0];
	ReferencesToReplaceCommonOwner = CheckResult.CommonOwner;
	
	UsageInstances.Clear();
	For Each Item In RefsArray Do
		UsageInstances.Add().Ref = Item;
	EndDo;
EndProcedure

&AtServerNoContext
Function CheckReferencesToMerge(Val RefSet)
	
	Result = New Structure("Error, CommonOwner");
	
	RefsCount = RefSet.Count();
	If RefsCount < 2 Then
		Result.Error = NStr("ru = 'Для объединения необходимо указать несколько элементов.'; en = 'Select more then one item to merge.'; pl = 'Określ kilka elementów do połączenia.';de = 'Geben Sie mehrere Elemente zum Zusammenführen an.';ro = 'Specificați mai multe elemente pentru grupare.';tr = 'Birleştirme için birkaç öğe belirtin.'; es_ES = 'Especificar varios artículos para combinar.'");
		Return Result;
	EndIf;
	
	FirstItem = RefSet[0];
	
	BasicMetadata = FirstItem.Metadata();
	Characteristics = New Structure("Owners, Hierarchical, HierarchyType", New Array, False);
	FillPropertyValues(Characteristics, BasicMetadata);
	
	HasOwners = Characteristics.Owners.Count() > 0;
	HasGroups    = Characteristics.Hierarchical AND Characteristics.HierarchyType = Metadata.ObjectProperties.HierarchyType.HierarchyFoldersAndItems;
	
	AdditionalFields = "";
	If HasOwners Then
		AdditionalFields = AdditionalFields + ", Owner AS Owner";
	Else
		AdditionalFields = AdditionalFields + ", UNDEFINED AS Owner";
	EndIf;
	
	If HasGroups Then
		AdditionalFields = AdditionalFields + ", IsFolder AS IsFolder";
	Else
		AdditionalFields = AdditionalFields + ", FALSE AS IsFolder";
	EndIf;
	
	TableName = BasicMetadata.FullName();
	Query = New Query("
		|SELECT Ref AS Ref" + AdditionalFields + " INTO RefsToReplace
		|FROM " + TableName + " WHERE Ref IN (&RefSet)
		|INDEX BY Owner, IsFolder
		|;
		|SELECT 
		|	COUNT(DISTINCT Owner) AS OwnersCount,
		|	MIN(Owner)              AS CommonOwner,
		|	MAX(IsFolder)            AS HasGroups,
		|	COUNT(Ref)             AS RefsCount
		|FROM
		|	RefsToReplace
		|");
	Query.SetParameter("RefSet", RefSet);
	
	Control = Query.Execute().Unload()[0];
	If Control.HasGroups Then
		Result.Error = NStr("ru = 'Один из объединяемых элементов является группой.
		                              |Группы не могут быть объединены.'; 
		                              |en = 'One of the items to merge is a group.
		                              |Groups cannot be merged.'; 
		                              |pl = 'Jeden z łączonych elementów jest grupą
		                              |Grupy nie mogą być połączone.';
		                              |de = 'Eines der zusammengeführten Elemente ist eine Gruppe.
		                              |Die Gruppen können nicht zusammengeführt werden.';
		                              |ro = 'Unul dintre elementele grupate este un grup.
		                              |Grupurile nu pot fi grupate.';
		                              |tr = 'Birleştirilmiş öğelerden biri bir gruptur. 
		                              |Gruplar birleştirilemez.'; 
		                              |es_ES = 'Uno de los artículos combinados es un grupo.
		                              |Los grupos no pueden combinarse.'");
	ElsIf Control.OwnersCount > 1 Then 
		Result.Error = NStr("ru = 'У объединяемых элементов различные владельцы.
		                              |Такие элементы не могут быть объединены.'; 
		                              |en = 'Items to merge have different owners. 
		                              |They cannot be merged.'; 
		                              |pl = 'Łączone elementy mają różnych właścicieli.
		                              |Takie elementy nie mogą być połączone.';
		                              |de = 'Zusammengeführte Artikel haben unterschiedliche Besitzer.
		                              |Solche Elemente können nicht zusammengeführt werden.';
		                              |ro = 'Elementele grupate au titulari diferiți.
		                              |Asemenea elemente nu pot fi grupate.';
		                              |tr = 'Birleştirilmiş öğelerin farklı sahipleri var. 
		                              |Bu tür maddeler birleştirilemez.'; 
		                              |es_ES = 'Artículos combinados tienen diferentes propietarios.
		                              |Estos artículos no pueden combinarse.'");
	ElsIf Control.RefsCount <> RefsCount Then
		Result.Error = NStr("ru = 'Все объединяемые элементы должны быть одного типа.'; en = 'All items to merge must be of the same type.'; pl = 'Wszystkie elementy łączone muszą być tego samego typu.';de = 'Alle zusammengeführten Elemente müssen vom gleichen Typ sein.';ro = 'Toate elementele grupate trebuie să fie de același tip.';tr = 'Tüm birleştirilebilir öğeler aynı tipte olmalıdır.'; es_ES = 'Todos los artículos combinables tienen que ser del mismo tipo.'");
	Else 
		// Successfully
		Result.CommonOwner = ?(HasOwners, Control.CommonOwner, Undefined);
	EndIf;
	
	Return Result;
EndFunction

&AtClient
Procedure UsageInstancesBeforeDeleteCompletion(Val QuestionResult, Val AdditionalParameters) Export
	If QuestionResult <> DialogReturnCode.Yes Then
		Return;
	EndIf;
	
	// Actual deletion from the table.
	Row = UsageInstances.FindByID(AdditionalParameters.CurrentRow);
	If Row = Undefined Then
		Return;
	EndIf;
	
	DeletedRowIndex = UsageInstances.IndexOf(Row);
	CalculateMain     = Row.Ref = MainItem;
	
	UsageInstances.Delete(Row);
	If CalculateMain Then
		LastStringIndex = UsageInstances.Count() - 1;
		If DeletedRowIndex <= LastStringIndex Then 
			MainStringIndex = DeletedRowIndex;
		Else
			MainStringIndex = LastStringIndex;
		EndIf;
			
		MainItem = UsageInstances[MainStringIndex].Ref;
	EndIf;
	
	GenerateMergeTooltip();
EndProcedure

&AtServer
Procedure GenerateMergeTooltip()

	If HasRightToDeletePermanently Then
		If CurrentDeletionOption = "Check" Then
			TooltipText = NStr("ru = 'Элементы (%1) будут <a href = ""ПереключениеРежимаУдаления"">помечены на удаление</a> и заменены во всех местах
				|использования на ""%2"" (отмечен стрелкой).'; 
				|en = '%1 items will be <a href = ""SwitchDeletionMode"">marked for deletion</a>
				|and replaced with %2.'; 
				|pl = 'Elementy (%1) będą <a href = ""DeletionModeSwitch > oznaczone
				|do usunięcia</a> i zastąpione we wszystkich miejscach użycia %2 (zaznaczone strzałką).';
				|de = 'Elemente (%1) werden <a href = ""LöschmodusSchalter> zum Löschen
				|markiert </a> und an allen Verwendungsstellen ersetzt durch %2 (mit einem Pfeil gekennzeichnet).';
				|ro = 'Elementele (%1) vor fi <a href = ""DeletionModeSwitch""> marcate pentru ștergere</a> și vor fi înlocuite în toate locurile
				|de utilizare cu ""%2"" (marcat cu săgeată). ';
				|tr = 'Öğeler  (%1), silinmek üzere işaretlenmiş <a href = ""DeletionModeSwitch> %2 olacaktır ve (okla işaretlenmiş) tüm kullanım yerlerinde
				| ile değiştirilecektir.'; 
				|es_ES = 'Artículos (%1) estarán <a href = ""DeletionModeSwitch > marcados
				|para deletion<a/> y reemplazados en todos los sitios del uso con %2 (marcado con una flecha).'");
		Else
			TooltipText = NStr("ru = 'Элементы (%1) будут <a href = ""ПереключениеРежимаУдаления"">удалены безвозвратно</a> и заменены во всех местах
				|использования на ""%2"" (отмечен стрелкой).'; 
				|en = '%1 items will be <a href = ""SwitchDeletionMode"">permanently deleted</a>
				|and replaced with %2.'; 
				|pl = 'Elementy (%1) będą <a href = ""PrzełączanieTrybuUsuwania"">bezpowrotnie usunięte</a> i wymienione we wszystkich miejscach
				|wykorzystania na ""%2"" (zaznaczony strzałką).';
				|de = 'Die Elemente (%1) werden <a href = ""WechselInLöschModus""> unwiderruflich gelöscht</a> und an allen
				|Verwendungsorten durch ""%2"" (mit einem Pfeil markiert) ersetzt.';
				|ro = 'Elementele (%1) vor fi <a href = ""DeletionModeSwitch""> șterse definitiv</a> și înlocuite în toate locurile
				|ďe utilizare cu ""%2"" (marcat cu săgeată).';
				|tr = 'Öğeler  (%1), <a href = ""DeletionModeSwitch> kalıcı olarak silinecek  </a> ve tüm kullanım yerlerinde
				| (okla işaretlenmiş) %2 ile değiştirilecektir.'; 
				|es_ES = 'Los elementos (%1) estarán <a href = ""DeletionModeSwitch > borrados para siempre</a> y reemplazados en todos los sitios
				|del uso con ""%2"" (marcado con una flecha).'");
		EndIf;
	Else
		TooltipText = NStr("ru = 'Элементы (%1) будут помечены на удаление и заменены во всех местах
			|использования на ""%2"" (отмечен стрелкой).'; 
			|en = '%1 items will be marked for deletion
			|and replaced with %2.'; 
			|pl = 'Elementy (%1) będą oznaczone do usunięcia i wymienione we wszystkich miejscach
			|wykorzystania na ""%2"" (zaznaczony strzałką).';
			|de = 'Die Elemente (%1) werden zum Löschen markiert und an allen
			|Verwendungsorten durch ""%2"" (mit einem Pfeil markiert) ersetzt.';
			|ro = 'Elementele (%1) vor fi marcate pentru ștergere și înlocuite în toate locurile
			|de utilizare cu ""%2"" (marcat cu săgeată).';
			|tr = 'Öğeler (%1) silinmek üzere işaretlenecek ve (okla işaretlenmiş) tüm kullanım %2 yerlerinde 
			| ile değiştirilecektir.'; 
			|es_ES = 'Los elementos (%1) se marcarán para borrar y se reemplazarán en todos los sitios
			|del uso con ""%2"" (marcado con una flecha).'");
	EndIf;
		
	TooltipText = StringFunctionsClientServer.SubstituteParametersToString(TooltipText, UsageInstances.Count()-1, MainItem);
	Items.MainItemSelectionTooltip.Title = StringFunctionsClientServer.FormattedString(TooltipText);
	
EndProcedure

&AtClient
Function CompleteMessage()
	Return StringFunctionsClientServer.StringWithNumberForAnyLanguage(
		NStr("ru = ';%1 элемент объединен в:;;%1 элемента объединено в:;%1 элементов объединено в:;%1 элемента объединено в:'; en = ';%1 item was merged into:;;%1 items were merged into:;%1 items were merged into:;%1 items were merged into:'; pl = ';%1 element połączony w:;;%1 elementy połączone w:;%1 elementów połączono w:;%1 elementy połączono w:';de = ';%1 Das Element ist kombiniert in:;;;%1 das Element ist kombiniert in:;%1 die Elemente sind kombiniert in:;%1 das Element ist kombiniert in:';ro = ';%1 element grupat în:;;%1 elemente grupate în:;%1 elemente grupate în:;%1 elemente grupate în:';tr = ';%1 nesne ile birleştirilmiş:;;%1 nesne ile birleştirilmiş:;%1 nesneler ile birliştirilmiş:;%1 nesne ile birleştirilmiş:'; es_ES = ';%1 elemento unido en:;;%1 del elemento unido en:;%1 de los elementos unidos en:;%1 del elemento unido en:'"),
		UsageInstances.Count());
EndFunction

&AtClient
Procedure GenerateUnsuccessfulReplacementLabel()
	
	Items.UnsuccessfulReplacementsResult.Title = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("ru = 'Объединение элементов не выполнено. В некоторых местах использования не может быть произведена
		           |автоматическая замена на ""%1""'; 
		           |en = 'Merge failed. In some usage locations,
		           |items cannot be automatically replaced with %1.'; 
		           |pl = 'Łączenie elementów nie zostało wykonane. W niektórych miejscach użytkowania nie może być wykonana
		           | automatyczna wymiana na ""%1""';
		           |de = 'Die Elemente wurden nicht zusammengeführt. In einigen Anwendungsbereichen kann das
		           |automatische Ersetzen durch ""%1"" nicht durchgeführt werden';
		           |ro = 'Elementele nu au fost grupate. În unele locuri de utilizare nu poate fi executată
		           |înlocuirea automată cu ""%1""';
		           |tr = 'Öğeler birleştirilemedi. Bazı yerlerde 
		           |otomatik yer değiştirme %1 ile çalıştırılamaz.'; 
		           |es_ES = 'Combinación de elementos no se ha ejecutado. En algunos sitios del uso un reemplazo
		           |automático con ""%1"" no puede ejecutarse'"),
		MainItem);
	
EndProcedure

// Parameters:
//     DataList - Array - contains changed data; its type will be shown as a notification.
//
&AtClient
Procedure NotifyOfSuccessfulReplacement(Val DataList)
	// Changes of items where replacements are performed.
	TypesList = New Map;
	For Each Item In DataList Do
		Type = TypeOf(Item);
		If TypesList[Type] = Undefined Then
			NotifyChanged(Type);
			TypesList.Insert(Type, True);
		EndIf;
	EndDo;
	
	// Common notification
	If TypesList.Count() > 0 Then
		Notify(ReplacementNotificationEvent, , ThisObject);
	EndIf;
EndProcedure

&AtServerNoContext
Function SelectionFormNameByReference(Val Ref)
	Meta = Metadata.FindByType(TypeOf(Ref));
	Return ?(Meta = Undefined, Undefined, Meta.FullName() + ".ChoiceForm");
EndFunction

// Converts an array, list of values, or collection to an array.
//
&AtServerNoContext
Function RefArrayFromSet(Val References)
	
	ParameterType = TypeOf(References);
	If References = Undefined Then
		RefsArray = New Array;
		
	ElsIf ParameterType  = Type("ValueList") Then
		RefsArray = References.UnloadValues();
		
	ElsIf ParameterType = Type("Array") Then
		RefsArray = References;
		
	Else
		RefsArray = New Array;
		For Each Item In References Do
			RefsArray.Add(Item.Ref);
		EndDo;
		
	EndIf;
	
	Return RefsArray;
EndFunction

// Adds an array of references
&AtServer
Procedure AddUsageInstancesRows(Val RefsArray)
	LastItemIndex = Undefined;
	MetadataCache    = New Map;
	
	Filter = New Structure("Ref");
	For Each Ref In RefsArray Do
		Filter.Ref = Ref;
		ExistingRows = UsageInstances.FindRows(Filter);
		If ExistingRows.Count() = 0 Then
			Row = UsageInstances.Add();
			Row.Ref = Ref;
			
			Row.Code      = PossibleReferenceCode(Ref, MetadataCache);
			Row.Owner = PossibleReferenceOwner(Ref, MetadataCache);
			
			Row.UsageInstancesCount = -1;
			Row.NotUsed    = NStr("ru = 'Не рассчитано'; en = 'Locations not searched for'; pl = 'Nie rozliczone';de = 'Nicht berechnet';ro = 'Nu se calculează';tr = 'Hesaplanmadı'; es_ES = 'No calculado'");
		Else
			Row = ExistingRows[0];
		EndIf;
		
		LastItemIndex = Row.GetID();
	EndDo;
	
	If LastItemIndex <> Undefined Then
		Items.UsageInstances.CurrentRow = LastItemIndex;
	EndIf;
EndProcedure

// Returns:
//     Arbitrary - catalog code and so on if metadata has a code,
//     Undefined if there is no code.
//
&AtServerNoContext
Function PossibleReferenceCode(Val Ref, MetadataCache)
	Data = MetaDetailsByReference(Ref, MetadataCache);
	Return ?(Data.HasCode, Ref.Code, Undefined);
EndFunction

// Returns:
//     Arbitrary - catalog owner if it exists according to metadata,
//     Undefined if there is no owner.
//
&AtServerNoContext
Function PossibleReferenceOwner(Val Ref, MetadataCache)
	Data = MetaDetailsByReference(Ref, MetadataCache);
	Return ?(Data.HasOwner, Ref.Owner, Undefined);
EndFunction

// Returns catalog description according to metadata.
&AtServerNoContext
Function MetaDetailsByReference(Val Ref, MetadataCache)
	
	ObjectMetadata = Ref.Metadata();
	Data = MetadataCache[ObjectMetadata];
	
	If Data = Undefined Then
		Test = New Structure("CodeLength, Owners", 0, New Array);
		FillPropertyValues(Test, ObjectMetadata);
		
		Data = New Structure;
		Data.Insert("HasCode", Test.CodeLength > 0);
		Data.Insert("HasOwner", Test.Owners.Count() > 0);
		
		MetadataCache[ObjectMetadata] = Data;
	EndIf;
	
	Return Data;
EndFunction

// Returns a list of successfully replaced references that are not in UnsuccessfulReplacements.
&AtClient
Function DeleteProcessedItemsFromUsageInstances()
	Result = New Array;
	
	Unsuccessful = New Map;
	For Each Row In UnsuccessfulReplacements.GetItems() Do
		Unsuccessful.Insert(Row.Ref, True);
	EndDo;
	
	Index = UsageInstances.Count() - 1;
	While Index > 0 Do
		Ref = UsageInstances[Index].Ref;
		If Ref<>MainItem AND Unsuccessful[Ref] = Undefined Then
			UsageInstances.Delete(Index);
			Result.Add(Ref);
		EndIf;
		Index = Index - 1;
	EndDo;
	
	Return Result;
EndFunction

// Checking whether items can be replaced in terms of applied data.
&AtServer
Function CheckCanReplaceReferences()
	
	RefSet = New Array;
	ReplacementPairs   = New Map;
	For Each Row In UsageInstances Do
		RefSet.Add(Row.Ref);
		ReplacementPairs.Insert(Row.Ref, MainItem);
	EndDo;
	
	// Checking once again, the set might be modified.
	Control = CheckReferencesToMerge(RefSet);
	If Not IsBlankString(Control.Error) Then
		Return Control.Error;
	EndIf;
	
	ReplacementParameters = New Structure("DeletionMethod", CurrentDeletionOption);
	Return DuplicateObjectDetection.CheckCanReplaceItemsString(ReplacementPairs, ReplacementParameters);
	
EndFunction

////////////////////////////////////////////////////////////////////////////////
// Time-consuming operations

&AtClient
Procedure RunBackgroundJobClient()
	Job = RunBackgroundJob();
	
	WaitSettings = TimeConsumingOperationsClient.IdleParameters(ThisObject);
	WaitSettings.OutputIdleWindow = False;
	
	Handler = New NotifyDescription("AfterCompleteBackgroundJob", ThisObject);
	
	TimeConsumingOperationsClient.WaitForCompletion(Job, Handler, WaitSettings);
EndProcedure

&AtServer
Function RunBackgroundJob()
	
	CurrentPage = Items.WizardSteps.CurrentPage;
	
	If CurrentPage = Items.SearchForUsageInstancesStep Then
		
		MethodName = "DuplicateObjectDetection.DefineUsageInstances";
		MethodDescription = NStr("ru = 'Поиск и удаление дублей: Определение мест использования'; en = 'Duplicate purge: Find usage locations'; pl = 'Wyszukiwanie i usuwanie duplikatów: Określenie lokalizacji użycia';de = 'Suchen und Löschen von Duplikaten: Bestimmen Sie Verwendungsorte';ro = 'Căutarea și ștergerea duplicatelor: Determinarea locurilor de utilizare';tr = 'Çiftlerin aranması ve silinmesi: Kullanım konumlarını belirleme'; es_ES = 'Buscar y borrar los duplicados: Determinas las ubicaciones de uso'");
		MethodParameters = RefArrayFromSet(UsageInstances);
		
	ElsIf CurrentPage = Items.MergeStep Then
		
		MethodName = "DuplicateObjectDetection.ReplaceReferences";
		MethodDescription = NStr("ru = 'Поиск и удаление дублей: Объединение элементов'; en = 'Duplicate purge: Merge items'; pl = 'Wyszukiwanie i usuwanie duplikatów: łączenie elementów';de = 'Suchen und Löschen von Duplikaten: Elemente zusammenführen';ro = 'Căutarea și ștergerea duplicatelor: Gruparea elementelor';tr = 'Çiftlerin aranması ve silinmesi: Öğeleri birleştir'; es_ES = 'Buscar y borrar los duplicados: Combinar los artículos'");
		
		MethodParameters = New Structure("ReplacementPairs, DeletionMethod");
		MethodParameters.ReplacementPairs = New Map;
		For Each Row In UsageInstances Do
			MethodParameters.ReplacementPairs.Insert(Row.Ref, MainItem);
		EndDo;
		MethodParameters.Insert("DeletionMethod", CurrentDeletionOption);
		
	Else
		
		Return Undefined;
		
	EndIf;
	
	StartSettings = TimeConsumingOperations.BackgroundExecutionParameters(UUID);
	StartSettings.BackgroundJobDescription = MethodDescription;
	
	Return TimeConsumingOperations.ExecuteInBackground(MethodName, MethodParameters, StartSettings);
EndFunction

&AtClient
Procedure AfterCompleteBackgroundJob(Job, AdditionalParameters) Export
	WizardSettings.ShowDialogBeforeClose = False;
	
	If Job.Status <> "Completed" Then
		BriefDescription = NStr("ru = 'При замене элементов возникла ошибка:'; en = 'Error occurred replacing items:'; pl = 'Podczas wymiany elementów wystąpił błąd:';de = 'Beim Ersetzen von Elementen ist ein Fehler aufgetreten:';ro = 'Eroare la înlocuirea elementelor:';tr = 'Nesne alışverişinde hata oluştu:'; es_ES = 'Ha ocurrido un error al reemplazar los elementos:'") + Chars.LF + Job.BriefErrorPresentation;
		More = BriefDescription + Chars.LF + Chars.LF + Job.DetailedErrorPresentation;
		Items.ErrorTextLabel.Title = BriefDescription;
		Items.DetailsRef.ToolTip    = More;
		GoToWizardStep(Items.ErrorOccurredStep);
		Activate();
		Return;
	EndIf;
	
	CurrentPage = Items.WizardSteps.CurrentPage;
	
	If CurrentPage = Items.SearchForUsageInstancesStep Then
		
		FillUsageInstances(Job.ResultAddress);
		Activate();
		GoToWizardStep(WizardSettings.CurrentStep.IndexOf + 1);
		
	ElsIf CurrentPage = Items.MergeStep Then
		
		HasUnsuccessfulReplacements = FillUnsuccessfulReplacements(Job.ResultAddress);
		If HasUnsuccessfulReplacements Then
			// Partially successful - display details.
			GoToWizardStep(Items.RetryMergeStep);
			Activate();
		Else
			// Completely successful - display notification and close the form.
			ShowUserNotification(
				CompleteMessage(),
				GetURL(MainItem),
				String(MainItem),
				PictureLib.Information32);
			UpdatedItemsList = New Array;
			For Each Row In UsageInstances Do
				UpdatedItemsList.Add(Row.Ref);
			EndDo;
			NotifyOfSuccessfulReplacement(UpdatedItemsList);
			Close();
		EndIf
		
	EndIf;
	
EndProcedure

&AtServer
Procedure FillUsageInstances(Val ResultAddress)
	UsageTable = GetFromTempStorage(ResultAddress);
	
	NewUsageInstances = UsageInstances.Unload();
	NewUsageInstances.Indexes.Add("Ref");
	
	IsUpdate = NewUsageInstances.Find(MainItem, "Ref") <> Undefined;
	
	If Not IsUpdate Then
		NewUsageInstances = UsageInstances.Unload(New Array);
		NewUsageInstances.Indexes.Add("Ref");
	EndIf;
	
	MetadataCache = New Map;
	
	MaxReference = Undefined;
	MaxInstances   = -1;
	For Each Row In UsageTable Do
		Ref = Row.Ref;
		
		UsageRow = NewUsageInstances.Find(Ref, "Ref");
		If UsageRow = Undefined Then
			UsageRow = NewUsageInstances.Add();
			UsageRow.Ref = Ref;
		EndIf;
		
		Instances = Row.Occurrences;
		If Instances>MaxInstances
			AND Not Ref.DeletionMark Then
			MaxReference = Ref;
			MaxInstances   = Instances;
		EndIf;
		
		UsageRow.UsageInstancesCount = Instances;
		UsageRow.Code      = PossibleReferenceCode(Ref, MetadataCache);
		UsageRow.Owner = PossibleReferenceOwner(Ref, MetadataCache);
		
		UsageRow.NotUsed = ?(Instances = 0, NStr("ru = 'Не используется'; en = 'Not used'; pl = 'Nie wykorzystuje się';de = 'Nicht benutzt';ro = 'Nefolosit';tr = 'Kullanılmadı'; es_ES = 'No utilizado'"), "");
	EndDo;
	
	UsageInstances.Load(NewUsageInstances);
	
	If MaxReference <> Undefined Then
		MainItem = MaxReference;
	EndIf;
	
	// Refreshing headers
	Presentation = ?(MainItem = Undefined, "", MainItem.Metadata().Presentation());
	Title = StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = 'Объединение элементов %1 в один'; en = 'Merge %1 items into one item'; pl = 'Połącz elementów %1 w jeden';de = 'Führen Sie Elemente von %1 zu einem einzigen zusammen';ro = 'Gruparea elementelor %1 într-un singur element';tr = 'Öğeleri tek bir öğeye birleştirme %1'; es_ES = 'Combinar los artículos de %1 en uno solo'"), Presentation);
EndProcedure

&AtServer
Function FillUnsuccessfulReplacements(Val ResultAddress)
	// ReplacementResults - table with the Reference, ErrorObject, ErrorType, ErrorText columns.
	ReplacementResults = GetFromTempStorage(ResultAddress);
	
	RootRows = UnsuccessfulReplacements.GetItems();
	RootRows.Clear();
	
	RowsMap = New Map;
	MetadataCache     = New Map;
	
	For Each ResultString In ReplacementResults Do
		Ref = ResultString.Ref;
		
		ErrorsByReference = RowsMap[Ref];
		If ErrorsByReference = Undefined Then
			TreeRow = RootRows.Add();
			TreeRow.Ref = Ref;
			TreeRow.Data = String(Ref);
			TreeRow.Code    = String( PossibleReferenceCode(Ref, MetadataCache) );
			TreeRow.Icon = -1;
			
			ErrorsByReference = TreeRow.GetItems();
			RowsMap.Insert(Ref, ErrorsByReference);
		EndIf;
		
		ErrorRow = ErrorsByReference.Add();
		ErrorRow.Ref = ResultString.ErrorObject;
		ErrorRow.Data = ResultString.ErrorObjectPresentation;
		
		ErrorType = ResultString.ErrorType;
		If ErrorType = "UnknownData" Then
			ErrorRow.Reason = NStr("ru = 'Обнаружена данные, обработка которых не планировалась.'; en = 'Data not supposed to be processed is provided.'; pl = 'Są wykryte dane, których przetwarzanie nie było zaplanowane.';de = 'Daten, deren Verarbeitung nicht geplant war, werden erkannt.';ro = 'Au fost depistate datele, procesarea cărora nu a fost planificată.';tr = 'Hangi işlemin planlanmadığı belirlendi.'; es_ES = 'Datos cuyo procesamiento no se ha programado se han detectado.'");
			
		ElsIf ErrorType = "LockError" Then
			ErrorRow.Reason = NStr("ru = 'Не удалось заблокировать данные.'; en = 'Cannot lock data.'; pl = 'Nie udało się zablokować dane.';de = 'Die Daten konnten nicht blockiert werden.';ro = 'Eșec la blocarea datelor.';tr = 'Veri kilitlenemedi'; es_ES = 'No se ha podido bloquear los datos.'");
			
		ElsIf ErrorType = "DataChanged" Then
			ErrorRow.Reason = NStr("ru = 'Данные изменены другим пользователем.'; en = 'Data was modified by another user.'; pl = 'Dane zmienione przez innego użytkownika.';de = 'Daten werden von einem anderen Benutzer geändert.';ro = 'Datele sunt modificate de alt utilizator.';tr = 'Veri başka bir kullanıcı tarafından değiştirildi.'; es_ES = 'Datos se han cambiado por otro usuario.'");
			
		ElsIf ErrorType = "WritingError" Then
			ErrorRow.Reason = ResultString.ErrorText;
			
		ElsIf ErrorType = "DeletionError" Then
			ErrorRow.Reason = NStr("ru = 'Невозможно удалить данные.'; en = 'Cannot delete data.'; pl = 'Nie możesz usunąć danych.';de = 'Sie können Daten nicht löschen.';ro = 'Datele nu pot fi șterse.';tr = 'Verileri silemezsiniz.'; es_ES = 'Usted no puede borrar los datos.'");
			
		Else
			ErrorRow.Reason = NStr("ru = 'Неизвестная ошибка.'; en = 'Unknown error.'; pl = 'Nieznany błąd.';de = 'Unbekannter Fehler.';ro = 'Eroare necunoscută.';tr = 'Bilinmeyen hata.'; es_ES = 'Error desconocido.'");
			
		EndIf;
		
		ErrorRow.DetailedReason = ResultString.ErrorText;
	EndDo;
	
	Return RootRows.Count() > 0;
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