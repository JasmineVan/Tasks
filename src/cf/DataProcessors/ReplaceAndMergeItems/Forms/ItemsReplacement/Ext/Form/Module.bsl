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
//     RefSet - Array, ValueList - a set of items to analyze.
//                                            The parameter can be a collection of objects that have the "Reference" field.
//

#Region EventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Not Parameters.Property("OpenByScenario") Then
		Raise NStr("ru = 'Обработка не предназначена для непосредственного использования.'; en = 'This data processor is not intended for manual use.'; pl = 'Opracowanie nie jest przeznaczone do bezpośredniego użycia.';de = 'Der Datenprozessor ist nicht für den direkten Gebrauch bestimmt.';ro = 'Procesarea nu este destinată pentru utilizare nemijlocită.';tr = 'Veri işlemcisi doğrudan kullanım için uygun değildir.'; es_ES = 'Procesador de datos no está destinado al uso directo.'");
	EndIf;
	
	// Moving parameters to the ReferencesToReplace table.
	// Initializing the following attributes: ReplacementItem, ReferencesToReplaceCommonOwner, ParameterErrorText.
	InitializeReferencesToReplace(RefArrayFromList(Parameters.RefSet));
	If Not IsBlankString(ParametersErrorText) Then
		Return; // A warning will be issued on opening.
	EndIf;
	
	HasRightToDeletePermanently = AccessRight("DataAdministration", Metadata);
	ReplacementNotificationEvent        = DataProcessors.ReplaceAndMergeItems.ReplacementNotificationEvent();
	CurrentDeletionOption          = "Check";
	
	// Initializing a dynamic list on the form - selection form imitation.
	BasicMetadata = ReplacementItem.Metadata();
	List.CustomQuery = False;
	
	DynamicListParameters = Common.DynamicListPropertiesStructure();
	DynamicListParameters.MainTable = BasicMetadata.FullName();
	DynamicListParameters.DynamicDataRead = True;
	Common.SetDynamicListProperties(Items.List, DynamicListParameters);
	
	Items.List.ChangeRowOrder = False;
	Items.List.ChangeRowSet  = False;
	
	ItemsToReplaceList = New ValueList;
	ItemsToReplaceList.LoadValues(RefsToReplace.Unload().UnloadColumn("Ref"));
	CommonClientServer.SetDynamicListFilterItem(
		List,
		"Ref",
		ItemsToReplaceList,
		DataCompositionComparisonType.NotInList,
		NStr("ru = 'Не показывать заменяемые'; en = 'Do not show replaceable items.'; pl = 'Nie pokazuj zastąpione';de = 'Zeige nicht ersetzte';ro = 'Nu afișați cele înlocuite';tr = 'Değiştirileni gösterme'; es_ES = 'No mostrar los reemplazados'"),
		True,
		DataCompositionSettingsItemViewMode.Inaccessible,
		"5bf5cd06-c1fd-4bd3-94b9-4e9803e90fd5");
	
	If ReferencesToReplaceCommonOwner <> Undefined Then 
		CommonClientServer.SetDynamicListFilterItem(List, "Owner", ReferencesToReplaceCommonOwner );
	EndIf;
	
	If RefsToReplace.Count() > 1 Then
		Items.SelectedItemTypeLabel.Title = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Выберите один из элементов ""%1"", на который следует заменить выбранные значения (%2):'; en = 'Select one of the %1 items. The item will replace all %2 selected values:'; pl = 'Wybierz jeden z elementów ""%1"", na które wybrane wartości (%2) powinny zostać zastąpione przez:';de = 'Wählen Sie eines der ""%1"" Elemente, die die ausgewählten Werte (%2) ersetzt werden sollen mit:';ro = 'Selectați unul dintre elementele ""%1"" valorile selectate (%2) ar trebui înlocuite cu:';tr = 'Seçilen değerlerin (%1) değiştirilmesi gereken ""%2"" öğelerinden birini seçin:'; es_ES = 'Seleccionar uno de los ""%1"" artículos, los valores seleccionados (%2) tienen que reemplazarse por:'"),
			BasicMetadata.Presentation(), RefsToReplace.Count());
	Else
		Title = NStr("ru = 'Замена элемента'; en = 'Item replacement'; pl = 'Wymiana elementów';de = 'Artikel ersetzen';ro = 'Item replacement';tr = 'Öğe değiştirme'; es_ES = 'Reemplazo de artículo'");
		Items.SelectedItemTypeLabel.Title = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Выберите один из элементов ""%1"", на который следует заменить ""%2"":'; en = 'Select one of the %1 items. The item will replace %2:'; pl = 'Wybierz jeden z ""%1"" elementów ""%2"" na który należy zastąpić:';de = 'Wählen Sie eines der ""%1"" Elemente ""%2"" sollte ersetzt werden mit:';ro = 'Selectați unul dintre  ""%1"" elemente ""%2"" ar trebui înlocuit cu:';tr = 'Aşağıdaki ile değiştirilmesi gereken ""%1"" öğelerden ""%2"" birini seçin:'; es_ES = 'Seleccionar uno de los ""%1"" artículos ""%2"" tiene que reemplazarse por:'"),
			BasicMetadata.Presentation(), RefsToReplace[0].Ref);
	EndIf;
	Items.ReplacementItemSelectionTooltip.Title = NStr("ru = 'Элемент для замены не выбран.'; en = 'Replacement item required.'; pl = 'Element zamienny nie jest wybrany.';de = 'Ersatzelement ist nicht ausgewählt.';ro = 'Elementul de înlocuire nu este selectat.';tr = 'Yedek öğe seçilmemiş.'; es_ES = 'Artículo de reemplazo no se ha seleccionado.'");
	
	// Initialization of step-by-step wizard steps.
	InitializeStepByStepWizardSettings();
	
	// 1. Main item selection.
	StepSelect = AddWizardStep(Items.ReplacementItemSelectionStep);
	StepSelect.BackButton.Visible = False;
	StepSelect.NextButton.Title = NStr("ru = 'Заменить >'; en = 'Replace >'; pl = 'Zastąp >';de = 'Ersetzen >';ro = 'Înlocuiți>';tr = 'Değiştir >'; es_ES = 'Reemplazar >'");
	StepSelect.NextButton.ToolTip = NStr("ru = 'Начать замену элементов'; en = 'Start replacement.'; pl = 'Zacznij zastępowanie elementów';de = 'Ersetzen von Elementen beginnen';ro = 'Începeți înlocuirea elementelor';tr = 'Öğeleri değiştirmeye başla'; es_ES = 'Iniciar a reemplazar los artículos'");
	StepSelect.CancelButton.Title = NStr("ru = 'Отмена'; en = 'Cancel'; pl = 'Anuluj';de = 'Abbrechen';ro = 'Revocare';tr = 'İptal'; es_ES = 'Cancelar'");
	StepSelect.CancelButton.ToolTip = NStr("ru = 'Отказаться от замены элементов'; en = 'Cancel replacement.'; pl = 'Odmów zastępowania elementów';de = 'Ablehnen Elemente zu ersetzen';ro = 'Refuză înlocuirea elementelor';tr = 'Öğeleri değiştirmeyi reddet'; es_ES = 'Rechazar el reemplazo de los artículos'");
	
	// 2. Waiting for process.
	Step = AddWizardStep(Items.ReplacementStep);
	Step.BackButton.Visible = False;
	Step.NextButton.Visible = False;
	Step.CancelButton.Title = NStr("ru = 'Прервать'; en = 'Abort'; pl = 'Przerwij';de = 'Abbrechen';ro = 'Eșuat';tr = 'Durdur'; es_ES = 'Anular'");
	Step.CancelButton.ToolTip = NStr("ru = 'Прервать замену элементов'; en = 'Abort replacement.'; pl = 'Zatrzymaj zastępowanie elementów';de = 'Stoppen Sie den Elementaustausch';ro = 'Întrerupe înlocuirea elementelor';tr = 'Öğe değiştirmeyi durdur'; es_ES = 'Parar el reemplazo de artículos'");
	
	// 3. Reference replacement issues.
	Step = AddWizardStep(Items.RetryReplacementStep);
	Step.BackButton.Title = NStr("ru = '< Назад'; en = '< Back'; pl = '< Wstecz';de = '<Zurück';ro = '< Înapoi';tr = '< Geri'; es_ES = '< Atrás'");
	Step.BackButton.ToolTip = NStr("ru = 'Вернутся к выбору целевого элемента'; en = 'Return to selecting replacement item.'; pl = 'Wróć do wyboru elementu docelowego';de = 'Zurück zur Auswahl der Stammartikel';ro = 'Reveniți la selectarea elementului principal';tr = 'Ana öğe seçimine geri dön'; es_ES = 'Volver a la selección de unidades maestras'");
	Step.NextButton.Title = NStr("ru = 'Повторить замену >'; en = 'Replace again >'; pl = 'Powtórz wymianę >';de = 'Ersetzen wiederholen >';ro = 'Repetare înlocuirea>';tr = 'Değiştirmeyi tekrarla >'; es_ES = 'Repetir el reemplazo >'");
	Step.NextButton.ToolTip = NStr("ru = 'Повторить замену элементов'; en = 'Replace again.'; pl = 'Powtórz wymianę elementów';de = 'Element ersetzen wiederholen';ro = 'Repetare înlocuirea elementelor';tr = 'Öğe değiştirmeyi tekrarla'; es_ES = 'Repetir el reemplazo de artículos'");
	Step.CancelButton.Title = NStr("ru = 'Закрыть'; en = 'Close'; pl = 'Zamknij';de = 'Schließen';ro = 'Închideți';tr = 'Kapat'; es_ES = 'Cerrar'");
	Step.CancelButton.ToolTip = NStr("ru = 'Закрыть результаты замены элементов'; en = 'Close replacement results.'; pl = 'Zamknij wyniki zastępowania elementów';de = 'Schließen Sie die Ergebnisse der Element Ersetzung';ro = 'Închide rezultatele înlocuirii elementelor';tr = 'Öğe değiştirmenin sonuçlarını kapatın'; es_ES = 'Cerrar los resultados del reemplazo de artículos'");
	
	// 4. Runtime errors.
	Step = AddWizardStep(Items.ErrorOccurredStep);
	Step.BackButton.Visible = False;
	Step.NextButton.Visible = False;
	Step.CancelButton.Title = NStr("ru = 'Закрыть'; en = 'Close'; pl = 'Zamknij';de = 'Schließen';ro = 'Închideți';tr = 'Kapat'; es_ES = 'Cerrar'");
	
	// Updating form items.
	WizardSettings.CurrentStep = StepSelect;
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
	
	If Items.WizardSteps.CurrentPage <> Items.ReplacementStep
		Or Not WizardSettings.ShowDialogBeforeClose Then
		Return;
	EndIf;
	
	Cancel = True;
	If Exit Then
		Return;
	EndIf;
	
	QuestionText = NStr("ru = 'Прервать замену элементов и закрыть форму?'; en = 'Do you want to abort replacing and close the form?'; pl = 'Przerwać wymianę elementów i zamknąć formularz?';de = 'Stoppen Sie den Austausch von Elementen und schließen Sie das Formular?';ro = 'Întrerupeți înlocuirea elementelor și închideți forma?';tr = 'Öğeleri değiştirmeyi bırak ve formu kapat?'; es_ES = '¿Parar el reemplazo de artículos y cerrar el formulario?'");
	
	Buttons = New ValueList;
	Buttons.Add(DialogReturnCode.Abort, NStr("ru = 'Прервать'; en = 'Abort'; pl = 'Przerwij';de = 'Abbrechen';ro = 'Eșuat';tr = 'Durdur'; es_ES = 'Anular'"));
	Buttons.Add(DialogReturnCode.No,      NStr("ru = 'Не прерывать'; en = 'Continue'; pl = 'Nie przerywać';de = 'Nicht unterbrechen';ro = 'Nu întrerupe';tr = 'Kesme'; es_ES = 'No interrumpir'"));
	
	Handler = New NotifyDescription("AfterConfirmCancelJob", ThisObject);
	ShowQueryBox(Handler, QuestionText, Buttons, , DialogReturnCode.No);
	
EndProcedure

#EndRegion

////////////////////////////////////////////////////////////////////////////////
// ITEMS

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure ReplacementItemSelectionTooltipURLProcessing(Item, Ref, StandardProcessing)
	
	StandardProcessing = False;
	
	If Ref = "SwitchDeletionMode" Then
		If CurrentDeletionOption = "Directly" Then
			CurrentDeletionOption = "Check" 
		Else
			CurrentDeletionOption = "Directly" 
		EndIf;
		
		GenerateReplacementItemAndTooltip(ThisObject);
	EndIf;
	
EndProcedure

&AtClient
Procedure DetailsRefClick(Item)
	StandardSubsystemsClient.ShowDetailedInfo(Undefined, Item.ToolTip);
EndProcedure

#EndRegion

////////////////////////////////////////////////////////////////////////////////
// TABLE List

#Region FormTableItemsEventHandlersList

&AtClient
Procedure ListOnActivateRow(Item)
	
	AttachIdleHandler("GenerateReplacementItemAndTooltipDeferred", 0.01, True);
	
EndProcedure

&AtClient
Procedure ListChoice(Item, RowSelected, Field, StandardProcessing)
	StandardProcessing = False;
	StepReplacementItemSelectionOnClickNextButton();
EndProcedure

#EndRegion

////////////////////////////////////////////////////////////////////////////////
// TABLE UnsuccessfulReplacements

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

////////////////////////////////////////////////////////////////////////////////
// COMMANDS

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

////////////////////////////////////////////////////////////////////////////////
// AUXILIARY PROCEDURES AND FUNCTIONS

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
	
	If CurrentPage = Items.ReplacementItemSelectionStep Then
		
		GenerateReplacementItemAndTooltip(ThisObject);
		
	ElsIf CurrentPage = Items.ReplacementStep Then
		
		WizardSettings.ShowDialogBeforeClose = True;
		ReplacementItemResult = ReplacementItem; // Saving start parameters.
		RunBackgroundJobClient();
		
	ElsIf CurrentPage = Items.RetryReplacementStep Then
		
		// Updating number of failures.
		Unsuccessful = New Map;
		For Each Row In UnsuccessfulReplacements.GetItems() Do
			Unsuccessful.Insert(Row.Ref, True);
		EndDo;
		
		ReplacementsCount = RefsToReplace.Count();
		Items.UnsuccessfulReplacementsResult.Title = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Не удалось заменить элементы (%1 из %2). В некоторых местах использования не может быть произведена
			           |автоматическая замена на ""%3""'; 
			           |en = 'Failed to replace %1 of %2 items.
			           |Cannot automatically replace to %3 with in some usage locations.'; 
			           |pl = 'Nie można wymienić elementów (%1 z %2). W niektórych miejscach użytkowania 
			           |nie można wykonać %3 automatycznej wymiany.';
			           |de = 'Es ist nicht möglich, Elemente zu ersetzen (%1 von %2). AN einigen Einsatzorten kann ein automatischer
			           |Ersatz für %3 nicht ausgeführt werden.';
			           |ro = 'Eșec la înlocuirea elementelor (%1 din %2). În unele locuri de utilizare nu poate fi executată
			           |înlocuirea automată cu ""%3""';
			           |tr = 'Öğeler değiştirilemiyor (%1''in %2). Bazı kullanım yerlerinde, 
			           |otomatik bir değiştirme işlemi yapılamaz%3.'; 
			           |es_ES = 'No se puede reemplazar los artículos (%1 de %2). EN algunos sitios de uso, un reemplazo
			           |automático para %3 no puede ejecutarse.'"),
			Unsuccessful.Count(),
			ReplacementsCount,
			ReplacementItem);
		
		// Generating a list of successful replacements and clearing a list of items to replace.
		UpdatedItemsList = New Array;
		UpdatedItemsList.Add(ReplacementItem);
		For Number = 1 To ReplacementsCount Do
			ReverseIndex = ReplacementsCount - Number;
			Ref = RefsToReplace[ReverseIndex].Ref;
			If Ref <> ReplacementItem AND Unsuccessful[Ref] = Undefined Then
				RefsToReplace.Delete(ReverseIndex);
				UpdatedItemsList.Add(Ref);
			EndIf;
		EndDo;
		
		// Notification of completed replacements.
		NotifyOfSuccessfulReplacement(UpdatedItemsList);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure WizardStepNext()
	
	CurrentPage = Items.WizardSteps.CurrentPage;
	
	If CurrentPage = Items.ReplacementItemSelectionStep Then
		
		StepReplacementItemSelectionOnClickNextButton();
		
	ElsIf CurrentPage = Items.RetryReplacementStep Then
		
		GoToWizardStep(Items.ReplacementStep);
		
	Else
		
		GoToWizardStep(WizardSettings.CurrentStep.IndexOf + 1);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure WizardStepBack()
	
	CurrentPage = Items.WizardSteps.CurrentPage;
	
	If CurrentPage = Items.RetryReplacementStep Then
		
		GoToWizardStep(Items.ReplacementItemSelectionStep);
		
	Else
		
		GoToWizardStep(WizardSettings.CurrentStep.IndexOf - 1);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure WizardStepCancel()
	
	CurrentPage = Items.WizardSteps.CurrentPage;
	
	If CurrentPage = Items.ReplacementStep Then
		
		WizardSettings.ShowDialogBeforeClose = False;
		
	EndIf;
	
	If IsOpen() Then
		Close();
	EndIf;
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Internal replace and merge items procedures

&AtClient
Procedure StepReplacementItemSelectionOnClickNextButton()
	
	CurrentData = Items.List.CurrentData;
	If CurrentData = Undefined Then
		Return;
	ElsIf RefsToReplace.Count() = 1 AND CurrentData.Ref = RefsToReplace.Get(0).Ref Then
		ShowMessageBox(, NStr("ru = 'Нельзя заменять элемент сам на себя.'; en = 'Cannot replace an item with itself.'; pl = 'Element nie może być zastąpiony sam sobą.';de = 'Ein Element kann nicht durch sich selbst ersetzt werden.';ro = 'Elementul nu poate fi înlocuit cu sine însuși.';tr = 'Bir öğe kendi ile değiştirilemez.'; es_ES = 'Un artículo no puede reemplazarse por él mismo.'"));
		Return;
	ElsIf AttributeValue(CurrentData, "IsFolder", False) Then
		ShowMessageBox(, NStr("ru = 'Нельзя заменять элемент на группу.'; en = 'Cannot replace an item with a group.'; pl = 'Nie można zastąpić elementu grupą.';de = 'Element kann nicht durch Gruppe ersetzt werden.';ro = 'Elementul nu poate fi înlocuit cu grupul.';tr = 'Öğe grupla değiştirilemiyor.'; es_ES = 'No se puede reemplazar el artículo por un grupo.'"));
		Return;
	EndIf;
	
	CurrentOwner = AttributeValue(CurrentData, "Owner");
	If CurrentOwner <> ReferencesToReplaceCommonOwner Then
		Text = NStr("ru = 'Нельзя заменять на элемент, подчиненный другому владельцу.
			|У выбранного элемента владелец ""%1"", а у заменяемого - ""%2"".'; 
			|en = 'Cannot replace an item with the item that belongs to another owner.
			|Owner of the selected item:%1. Owner of the replacement item: %2.'; 
			|pl = 'Nie można element zastąpić obiektem podrzędnym, który jest podporządkowany do innego użytkownika.
			|Wybrany element%1ma właściciela, a zastąpiony element%2ma właściciela.';
			|de = 'Sie können es nicht durch das Objekt ersetzen, das einem anderen Benutzer untergeordnet ist.
			|Das ausgewählte Element hat %1 einen Eigentümer und das ersetzte Element hat %2 einen Eigentümer.';
			|ro = 'Nu se permite înlocuirea cu elementul subordonat altui titular.
			|Elementul selectat are titularul ""%1"", iar elementul înlocuit - ""%2"".';
			|tr = 'Onu başka bir kullanıcıya bağlı nesneyle değiştiremezsiniz. 
			|Seçilen öğenin %1 sahip olarak ve değiştirilen öğenin %2 sahip olarak vardır.'; 
			|es_ES = 'Usted no puede reemplazarlo por el objeto subordinado a otro usuario.
			|El artículo seleccionado tiene %1 como un propietario, y el artículo reemplazado tiene %2 como un propietario.'");
		ShowMessageBox(, StringFunctionsClientServer.SubstituteParametersToString(Text, CurrentOwner, ReferencesToReplaceCommonOwner));
		Return;
	EndIf;
	
	If AttributeValue(CurrentData, "DeletionMark", False) Then
		// Attempt to replace with an item marked for deletion.
		Text = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Элемент %1 помечен на удаление. Продолжить?'; en = 'Item %1 is marked for deletion. Continue?'; pl = 'Element %1 jest oznaczony do usunięcia. Kontynuować?';de = 'Das Element %1 ist zum Löschen markiert. Fortsetzen?';ro = 'Elementul %1 este marcat pentru ștergere. Continuați?';tr = 'Öğe %1 silinmek üzere işaretlenmiştir. Devam et?'; es_ES = 'El artículo %1 está marcado para borrar. ¿Continuar?'"),
			CurrentData.Ref);
		Details = New NotifyDescription("ConfirmItemSelection", ThisObject);
		ShowQueryBox(Details, Text, QuestionDialogMode.YesNo);
	Else
		// Additional check for applied data is required.
		AppliedAreaReplacementAvailabilityCheck();
	EndIf;
	
EndProcedure

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
	If TypesList.Count()>0 Then
		Notify(ReplacementNotificationEvent, , ThisObject);
	EndIf;
EndProcedure

&AtClient
Procedure GenerateReplacementItemAndTooltipDeferred()
	GenerateReplacementItemAndTooltip(ThisObject);
EndProcedure

&AtClient
Procedure ConfirmItemSelection(Val QuestionResult, Val AdditionalParameters) Export
	If QuestionResult <> DialogReturnCode.Yes Then
		Return;
	EndIf;
	
	// Additional check by applied data.
	AppliedAreaReplacementAvailabilityCheck();
EndProcedure

&AtClient
Procedure AppliedAreaReplacementAvailabilityCheck()
	// Checking items replacement for validity in terms of applied data.
	ErrorText = CheckCanReplaceReferences();
	If Not IsBlankString(ErrorText) Then
		DialogSettings = New Structure;
		DialogSettings.Insert("SuggestDontAskAgain", False);
		DialogSettings.Insert("Picture", PictureLib.Warning32);
		DialogSettings.Insert("DefaultButton", 0);
		DialogSettings.Insert("Title", NStr("ru = 'Невозможно заменить элементы'; en = 'Cannot replace items'; pl = 'Brak możliwości zastąpienia elementów';de = 'Sie können keine Elemente ersetzen';ro = 'Elementele nu pot fi înlocuite';tr = 'Öğeleri değiştiremezsiniz'; es_ES = 'Usted no puede reemplazar los artículos'"));
		
		Buttons = New ValueList;
		Buttons.Add(0, NStr("ru = 'ОК'; en = 'OK'; pl = 'OK';de = 'OK';ro = 'OK';tr = 'OK'; es_ES = 'OK'"));
		
		StandardSubsystemsClient.ShowQuestionToUser(Undefined, ErrorText, Buttons, DialogSettings);
		Return;
	EndIf;
	
	GoToWizardStep(WizardSettings.CurrentStep.IndexOf + 1);
EndProcedure

&AtClientAtServerNoContext
Procedure GenerateReplacementItemAndTooltip(Context)
	
	CurrentData = Context.Items.List.CurrentData;
	// Skipping empty data and groups
	If CurrentData = Undefined Or AttributeValue(CurrentData, "IsFolder", False) Then
		Return;
	EndIf;
	Context.ReplacementItem = CurrentData.Ref;
	
	Count = Context.RefsToReplace.Count();
	If Count = 1 Then
		
		If Context.HasRightToDeletePermanently Then
			If Context.CurrentDeletionOption = "Check" Then
				TooltipText = NStr("ru = 'Выбранный элемент будет заменен на ""%1""
					|и <a href = ""ПереключениеРежимаУдаления"">помечен на удаление</a>.'; 
					|en = 'The selected item will be replaced with %1
					|and <a href = ""SwitchDeletionMode"">marked for deletion</a>.'; 
					|pl = 'Wybrany element zostanie
					|zastąpiony i %1 <a href = <a href = ""DeletionModeSwitch> oznaczony do usunięcia</a>.';
					|de = 'Das ausgewählte Element wird
					|ersetzt durch %1 und <a href = ""LöschmodusSchalter>zum Löschen markiert </a>.';
					|ro = 'Elementul selectat va fi înlocuit cu ""%1""
					| și <a href = ""DeletionModeSwitch> marcat pentru ștergere</a>.';
					|tr = 'Seçilen öğe 
					| ve <a href = ""SilmeModunDeğiştirilmesi> silinmek üzere işaretlendi </a> ile %1  değiştirilecek.'; 
					|es_ES = 'El artículo seleccionado se
					|reemplazará por %1 y <a href = ""DeletionModeSwitch>se marcará para borrar</a>.'");
			Else
				TooltipText = NStr("ru = 'Выбранный элемент будет заменен на ""%1""
					|и <a href = ""ПереключениеРежимаУдаления"">удален безвозвратно</a>.'; 
					|en = 'The selected item will be replaced with %1
					|and <a href = ""SwitchDeletionMode"">permanently deleted</a>.'; 
					|pl = 'Wybrany element zostanie
					|zastąpiony %1 i <a href = ""DeletionModeSwitch> trwale usunięty</a>.';
					|de = 'Das ausgewählte Element wird
					|ersetzt durch %1 und <a href = ""LöschmodusSchalter>dauerhaft gelöscht</a>.';
					|ro = 'Elementul selectat va fi înlocuit cu ""%1""
					| și <a href = ""DeletionModeSwitch> șters definitiv</a>.';
					|tr = 'Seçilen öğe 
					| ve <a href = ""SilmeModunDeğiştirilmesi> kalıcı olarak silindi </a> ile %1 değiştirilecek.'; 
					|es_ES = 'El artículo seleccionado se
					|reemplazará por %1 y <a href = ""DeletionModeSwitch>se borrará para siempre</a>.'");
			EndIf;
		Else
			TooltipText = NStr("ru = 'Выбранный элемент будет заменен на ""%1""
				|и помечен на удаление.'; 
				|en = 'The selected item will be replaced with %1
				|and marked for deletion.'; 
				|pl = 'Wybrany element zostanie wymieniony na ""%1""
				|i zaznaczony do usunięcia.';
				|de = 'Das ausgewählte Element wird durch ""%1""
				|ersetzt und zum Löschen markiert.';
				|ro = 'Elementul selectat va fi înlocuit cu ""%1""
				| și marcat la ștergere.';
				|tr = 'Seçilen öğe 
				| ile %1 değiştirilecek ve silme için işaretlenecek.'; 
				|es_ES = 'El artículo seleccionado se reemplazará por ""%1""
				|y se marcará para borrar.'");
		EndIf;
		
		TooltipText = StringFunctionsClientServer.SubstituteParametersToString(TooltipText, Context.ReplacementItem);
		Context.Items.ReplacementItemSelectionTooltip.Title = StringFunctionsClientServer.FormattedString(TooltipText);
		
	Else
		
		If Context.HasRightToDeletePermanently Then
			If Context.CurrentDeletionOption = "Check" Then
				TooltipText = NStr("ru = 'Выбранные элементы (%1) будут заменены на ""%2""
					|и <a href = ""ПереключениеРежимаУдаления"">помечены на удаление</a>.'; 
					|en = 'The selected items (%1) will be replaced with ""%2""
					|and <a href = ""SwitchDeletionMode"">marked for deletion</a>.'; 
					|pl = 'Wybrane elementy (%1) zostaną
					|zastąpione i %2 <a href = <a href = ""DeletionModeSwitch> oznaczone do usunięcia</a>.';
					|de = 'Die ausgewählten Elemente (%1) werden
					|ersetzt durch %2 und <a href = ""LöschmodusSchalter>zum Löschen markiert</a>.';
					|ro = 'Elementele selectate (%1) vor fi înlocuite cu ""%2""
					| și <a href = ""DeletionModeSwitch> marcate la ștergere</a>.';
					|tr = 'Seçilen öğe ( 
					| ) %2<a href = ""SilmeModunDeğiştirilmesi> silinmek üzere işaretlendi </a> ile %1 değiştirilecek.'; 
					|es_ES = 'Los artículos seleccionados (%1) se
					|reemplazarán por %2 y <a href = ""DeletionModeSwitch>se marcarán para borrar</a>.'");
			Else
				TooltipText = NStr("ru = 'Выбранные элементы (%1) будут заменены на ""%2""
					|и <a href = ""ПереключениеРежимаУдаления"">удалены безвозвратно</a>.'; 
					|en = 'All %1 selected items will be replaced with %2
					|and <a href = ""SwitchDeletionMode"">permanently deleted</a>.'; 
					|pl = 'Wybrane elementy (%1) zostaną
					|zastąpione %2 i <a href = ""DeletionModeSwitch> trwale usunięte</a>.';
					|de = 'Die ausgewählten Elemente (%1) werden
					|ersetzt durch %2 und <a href = ""LöschmodusSchalter>auerhaft gelöscht</a>.';
					|ro = 'Elementele selectate (%1) vor fi înlocuite cu ""%2""
					| și <a href = ""DeletionModeSwitch> șterse definitiv</a>';
					|tr = 'Seçilen öğe (
					| ) %2 <a href = ""SilmeModunDeğiştirilmesi> kalıcı olarak silindi </a> ile %1 değiştirilecek.'; 
					|es_ES = 'Los artículos seleccionado (%1) se
					|reemplazarán por %2 y <a href = ""DeletionModeSwitch>se borrarán para siempre</a>.'");
			EndIf;
		Else
			TooltipText = NStr("ru = 'Выбранные элементы (%1) будут заменены на ""%2""
				|и помечен на удаление.'; 
				|en = 'All %1 selected items will be replaced with %2
				|and marked for deletion.'; 
				|pl = 'Wybrane elementy (%1) zostaną wymienione na ""%2""
				|i zaznaczone do usunięcia.';
				|de = 'Die ausgewählten Elemente %1) werden durch ""%2""
				|ersetzt und zum Löschen markiert.';
				|ro = 'Elementele selectate (%1) vor fi înlocuite cu ""%2""
				| și marcate la ștergere.';
				|tr = 'Seçilen öğe (
				|) ile %1 değiştirilecek ve %2 silme için işaretlenecek.'; 
				|es_ES = 'Los artículos seleccionados (%1) se reemplazarán por ""%2""
				| y se marcarán para borrar.'");
		EndIf;
			
		TooltipText = StringFunctionsClientServer.SubstituteParametersToString(TooltipText, Count, Context.ReplacementItem);
		Context.Items.ReplacementItemSelectionTooltip.Title = StringFunctionsClientServer.FormattedString(TooltipText);
		
	EndIf;
	
EndProcedure

&AtClientAtServerNoContext
Function AttributeValue(Val Data, Val AttributeName, Val ValueIfNotFound = Undefined)
	// Gets an attribute value safely.
	Trial = New Structure(AttributeName);
	
	FillPropertyValues(Trial, Data);
	If Trial[AttributeName] <> Undefined Then
		// There is a value
		Return Trial[AttributeName];
	EndIf;
	
	// Value in data might be set to Undefined.
	Trial[AttributeName] = True;
	FillPropertyValues(Trial, Data);
	If Trial[AttributeName] <> True Then
		Return Trial[AttributeName];
	EndIf;
	
	Return ValueIfNotFound;
EndFunction

&AtServer
Function CheckCanReplaceReferences()
	
	ReplacementPairs = New Map;
	For Each Row In RefsToReplace Do
		ReplacementPairs.Insert(Row.Ref, ReplacementItem);
	EndDo;
	
	ReplacementParameters = New Structure("DeletionMethod", CurrentDeletionOption);
	Return DuplicateObjectDetection.CheckCanReplaceItemsString(ReplacementPairs, ReplacementParameters);
	
EndFunction

&AtServerNoContext
Function RefArrayFromList(Val References)
	// Converts an array, list of values, or collection to an array.
	
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

&AtServerNoContext
Function PossibleReferenceCode(Val Ref, MetadataCache)
	// Returns:
	//     Arbitrary - catalog code and so on if metadata has a code,
	//     Undefined if there is no code.
	Meta = Ref.Metadata();
	HasCode = MetadataCache[Meta];
	
	If HasCode = Undefined Then
		// Checking whether the code exists.
		Test = New Structure("CodeLength", 0);
		FillPropertyValues(Test, Meta);
		HasCode = Test.CodeLength > 0;
		
		MetadataCache[Meta] = HasCode;
	EndIf;
	
	Return ?(HasCode, Ref.Code, Undefined);
EndFunction

&AtServer
Procedure InitializeReferencesToReplace(Val RefsArray)
	
	RefsCount = RefsArray.Count();
	If RefsCount = 0 Then
		ParametersErrorText = NStr("ru = 'Не указано ни одного элемента для замены.'; en = 'No items to be replaced are selected.'; pl = 'Nie określono elementu do wymiany.';de = 'Kein Artikel zum Ersetzen angegeben.';ro = 'Nu este specificat nici un element pentru înlocuire.';tr = 'Değiştirme için hiçbir öğe belirtilmemiş.'; es_ES = 'Ningún artículo para el reemplazo se ha especificado.'");
		Return;
	EndIf;
	
	ReplacementItem = RefsArray[0];
	
	BasicMetadata = ReplacementItem.Metadata();
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
	Query = New Query(
		"SELECT
		|Ref AS Ref
		|" + AdditionalFields + "
		|INTO RefsToReplace
		|FROM
		|	" + TableName + "
		|WHERE
		|	Ref IN (&RefSet)
		|INDEX BY
		|	Owner,
		|	IsFolder
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT ALLOWED
		|	COUNT(DISTINCT Owner) AS OwnersCount,
		|	MIN(Owner)              AS CommonOwner,
		|	MAX(IsFolder)            AS HasGroups,
		|	COUNT(Ref)             AS RefsCount
		|FROM
		|	RefsToReplace
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT ALLOWED TOP 1
		|	DestinationTable.Ref
		|FROM
		|	" + TableName + " AS DestinationTable
		|		LEFT JOIN RefsToReplace AS RefsToReplace
		|		ON DestinationTable.Ref = RefsToReplace.Ref
		|		AND DestinationTable.Owner = RefsToReplace.Owner
		|WHERE
		|	RefsToReplace.Ref IS NULL
		|	AND NOT DestinationTable.IsFolder");
		
	If Not HasOwners Then
		Query.Text = StrReplace(Query.Text, "AND DestinationTable.Owner = RefsToReplace.Owner", "");
	EndIf;
	If Not HasGroups Then
		Query.Text = StrReplace(Query.Text, "AND NOT DestinationTable.IsFolder", "");
	EndIf;
	Query.SetParameter("RefSet", RefsArray);
	
	Result = Query.ExecuteBatch();
	Conditions = Result[1].Unload()[0];
	If Conditions.HasGroups Then
		ParametersErrorText = NStr("ru = 'Один из заменяемых элементов является группой.
		                                   |Группы не могут быть заменены.'; 
		                                   |en = 'One of the items to replace is a group.
		                                   |Groups cannot be replaced.'; 
		                                   |pl = 'Jednym z wymienionych elementów jest grupa.
		                                   |Grupy nie mogą być zastąpione.';
		                                   |de = 'Eines der ersetzten Elemente ist eine Gruppe.
		                                   |Gruppen können nicht ersetzt werden.';
		                                   |ro = 'Unul dintre elementele înlocuite este un grup.
		                                   |Grupurile nu pot fi înlocuite.';
		                                   |tr = 'Birleştirilmiş öğelerden biri bir gruptur. 
		                                   |Gruplar birleştirilemez.'; 
		                                   |es_ES = 'Uno de los artículos reemplazados es un grupo.
		                                   |Grupos no pueden reemplazarse.'");
		Return;
	ElsIf Conditions.OwnersCount > 1 Then 
		ParametersErrorText = NStr("ru = 'У заменяемых элементов разные владельцы.
		                                   |Такие элементы не могут быть заменены.'; 
		                                   |en = 'Items to replace have different owners.
		                                   |They cannot be replaced.'; 
		                                   |pl = 'Wymienione elementy mają różnych właścicieli.
		                                   |Takie przedmioty nie mogą być zastąpione.';
		                                   |de = 'Ersetzte Gegenstände haben unterschiedliche Besitzer.
		                                   |Solche Elemente können nicht ersetzt werden.';
		                                   |ro = 'Elementele înlocuite au titulari diferiți.
		                                   |Asemenea elemente nu pot fi înlocuite.';
		                                   |tr = 'Değiştirilmiş öğelerin farklı sahipleri var. 
		                                   |Bu tür maddeler birleştirilemez.'; 
		                                   |es_ES = 'Artículos reemplazado tienen diferentes propietarios.
		                                   |Estos artículos no pueden reemplazarse.'");
		Return;
	ElsIf Conditions.RefsCount <> RefsCount Then
		ParametersErrorText = NStr("ru = 'Все заменяемые элементы должны быть одного типа.'; en = 'All items to replace must be of the same type.'; pl = 'Wszystkie wymienne elementy muszą być tego samego typu.';de = 'Alle austauschbaren Elemente müssen vom gleichen Typ sein.';ro = 'Toate elementele înlocuibile trebuie să fie de același tip.';tr = 'Tüm değiştirilebilir öğeler aynı tipte olmalıdır.'; es_ES = 'Todos los artículos reemplazables tienen que ser del mismo tipo.'");
		Return;
	EndIf;
	
	If Result[2].Unload().Count() = 0 Then
		If RefsCount > 1 Then
			ParametersErrorText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'Выбранные элементы (%1) не на что заменить.'; en = 'No replacement item for the selected items (%1).'; pl = 'Wybranych elementów (%1) nie ma czym zastąpić.';de = 'Es gibt nichts, um die ausgewählten Elemente (%1) zu ersetzen.';ro = 'Nu există nimic care să înlocuiască elementele selectate (%1) cu.';tr = 'Seçilen öğeleri (%1) ile değiştirmek için hiçbir şey yoktur.'; es_ES = 'No hay nada para reemplazar los artículos seleccionados (%1) por.'"), RefsCount);
		Else
			ParametersErrorText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'Выбранный элемент ""%1"" не на что заменить.'; en = 'No replacement item for item %1.'; pl = 'Wybrany element ""%1"" nie ma czym zastąpić.';de = 'Es gibt nichts, um das ausgewählte Element ""%1"" zu ersetzen.';ro = 'Nu există nimic care să înlocuiască elementul selectat ""%1"" cu.';tr = '""%1"" ile seçilen öğeyi değiştirecek hiçbir şey yok.'; es_ES = 'No hay nada para reemplazar el artículo seleccionado ""%1"" por.'"), Common.SubjectString(ReplacementItem));
		EndIf;
		Return;
	EndIf;
	
	ReferencesToReplaceCommonOwner = ?(HasOwners, Conditions.CommonOwner, Undefined);
	For Each Item In RefsArray Do
		RefsToReplace.Add().Ref = Item;
	EndDo;
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Time-consuming operations

&AtClient
Procedure RunBackgroundJobClient()
	
	MethodParameters = New Structure("ReplacementPairs, DeletionMethod");
	MethodParameters.ReplacementPairs = New Map;
	For Each Row In RefsToReplace Do
		MethodParameters.ReplacementPairs.Insert(Row.Ref, ReplacementItem);
	EndDo;
	MethodParameters.Insert("DeletionMethod", CurrentDeletionOption);
	
	Job = RunBackgroundJob(MethodParameters, UUID);
	
	WaitSettings = TimeConsumingOperationsClient.IdleParameters(ThisObject);
	WaitSettings.OutputIdleWindow = False;
	
	Handler = New NotifyDescription("AfterCompleteBackgroundJob", ThisObject);
	
	TimeConsumingOperationsClient.WaitForCompletion(Job, Handler, WaitSettings);
EndProcedure

&AtServerNoContext
Function RunBackgroundJob(Val MethodParameters, Val UUID)
	
	MethodName = "DuplicateObjectDetection.ReplaceReferences";
	MethodDescription = NStr("ru = 'Поиск и удаление дублей: Замена ссылок'; en = 'Duplicate purge: Replace references'; pl = 'Wyszukaj i usuń duplikaty: Wymiana linków';de = 'Suchen und Löschen von Duplikaten: Ersetzen von Referenzen';ro = 'Căutarea și ștergerea duplicatelor: Înlocuirea referințelor';tr = 'Çiftleri ara ve sil: Referans değişimi'; es_ES = 'Buscar y borrar los duplicados: Reemplazo de referencias'");
	
	StartSettings = TimeConsumingOperations.BackgroundExecutionParameters(UUID);
	StartSettings.BackgroundJobDescription = MethodDescription;
	
	Return TimeConsumingOperations.ExecuteInBackground(MethodName, MethodParameters, StartSettings);
	
EndFunction

&AtClient
Procedure AfterCompleteBackgroundJob(Job, AdditionalParameters) Export
	WizardSettings.ShowDialogBeforeClose = False;
	
	If Job.Status <> "Completed" Then
		// Background job is completed with error.
		BriefDescription = NStr("ru = 'При замене элементов возникла ошибка:'; en = 'Error occurred replacing items:'; pl = 'Podczas wymiany elementów wystąpił błąd:';de = 'Beim Ersetzen von Elementen ist ein Fehler aufgetreten:';ro = 'Eroare la înlocuirea elementelor:';tr = 'Nesne alışverişinde hata oluştu:'; es_ES = 'Ha ocurrido un error al reemplazar los elementos:'") + Chars.LF + Job.BriefErrorPresentation;
		More = BriefDescription + Chars.LF + Chars.LF + Job.DetailedErrorPresentation;
		Items.ErrorTextLabel.Title = BriefDescription;
		Items.DetailsRef.ToolTip    = More;
		GoToWizardStep(Items.ErrorOccurredStep);
		Activate();
		Return;
	EndIf;
	
	HasUnsuccessfulReplacements = FillUnsuccessfulReplacements(Job.ResultAddress);
	If HasUnsuccessfulReplacements Then
		// Partially successful - display details.
		GoToWizardStep(Items.RetryReplacementStep);
		Activate();
	Else
		// Completely successful - display notification and close the form.
		Count = RefsToReplace.Count();
		If Count = 1 Then
			ResultingText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'Элемент ""%1"" заменен на ""%2""'; en = 'Item %1 has been replaced with %2.'; pl = 'Element (%1) zostanie zastąpiony przez ""%2""';de = 'Artikel ""%1"" wird durch ""%2"" ersetzt';ro = 'Elementul ""%1"" este înlocuit cu ""%2""';tr = 'Öğe ""%1"" ""%2"" ile değiştirilecek'; es_ES = 'El artículo ""%1"" se ha reemplazado por ""%2""'"),
				RefsToReplace[0].Ref,
				ReplacementItemResult);
		Else
			ResultingText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'Элементы (%1) заменены на ""%2""'; en = '%1 items have been replaced with %2.'; pl = 'Elementy (%1) zostają zastąpione przez ""%2""';de = 'Elemente (%1) werden durch ""%2"" ersetzt';ro = 'Elementele (%1) sunt înlocuite cu ""%2""';tr = 'Öğeler (%1) ""%2"" ile değiştirilecek'; es_ES = 'Artículos (%1) se han reemplazado por ""%2""'"),
				Count,
				ReplacementItemResult);
		EndIf;
		ShowUserNotification(
			,
			GetURL(ReplacementItem),
			ResultingText,
			PictureLib.Information32);
		UpdatedItemsList = New Array;
		For Each Row In RefsToReplace Do
			UpdatedItemsList.Add(Row.Ref);
		EndDo;
		NotifyOfSuccessfulReplacement(UpdatedItemsList);
		Close();
	EndIf
	
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
	EndDo; // replacement results
	
	Return RootRows.Count() > 0;
EndFunction

&AtClient
Procedure AfterConfirmCancelJob(Response, ExecutionParameters) Export
	If Response = DialogReturnCode.Abort
		AND Items.WizardSteps.CurrentPage = Items.ReplacementStep Then
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