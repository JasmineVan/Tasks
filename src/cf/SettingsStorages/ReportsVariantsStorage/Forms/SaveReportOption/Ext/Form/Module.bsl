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
	SetConditionalAppearance();
	
	DefineBehaviorInMobileClient();
	
	Context = New Structure;
	Context.Insert("CurrentUser", Users.AuthorizedUser());
	Context.Insert("FullRightsToOptions", ReportsOptions.FullRightsToOptions());
	
	PrototypeKey = Parameters.CurrentSettingsKey;
	
	ReportInformation = ReportsOptions.GenerateReportInformationByFullName(Parameters.ObjectKey);
	If TypeOf(ReportInformation.ErrorText) = Type("String") Then
		Raise ReportInformation.ErrorText;
	EndIf;
	Context.Insert("ReportRef", ReportInformation.Report);
	Context.Insert("ReportName",    ReportInformation.ReportName);
	Context.Insert("ReportType",   ReportInformation.ReportType);
	Context.Insert("IsExternal",  ReportInformation.ReportType = Enums.ReportTypes.External);
	Context.Insert("SearchByDescription", New Map);
	
	FillOptionsList(False);
	
	Items.AvailableToGroup.ReadOnly = Not Context.FullRightsToOptions;
	If Context.IsExternal Then
		Items.ExternalReportDetails.Visible = True;
		Items.DefaultVisibilityOption.Visible = False;
		Items.Back.Visible = False;
		Items.Next.Visible = False;
		Items.AvailableToGroup.Visible = False;
		Items.NextStepInfoNewOptionDecoration.Title = NStr("ru = 'Будет сохранен новый вариант отчета.'; en = 'The report option will be saved as a new option.'; pl = 'Zostanie zapisany nowy wariant sprawozdania.';de = 'Eine neue Berichtoption wird gespeichert.';ro = 'Se va salva o nouă opțiune de raport.';tr = 'Yeni bir rapor seçeneği kaydedilecektir.'; es_ES = 'Una opción del informe nueva se guardará.'");
		Items.NextStepInfoOverwriteOptionDecoration.Title = NStr("ru = 'Будет перезаписан существующий вариант отчета.'; en = 'The current report option will be overwritten.'; pl = 'Istniejący wariant sprawozdania zostanie nadpisany.';de = 'Die vorhandene Version des Berichts wird überschrieben.';ro = 'Varianta existentă a raportului va fi suprascrisă.';tr = 'Varolan bir rapor seçeneği üzerine yazılır.'; es_ES = 'La opción existente del informe será sobrescrita.'");
	EndIf;
	
	ItemsToLocalize = New Array;
	ItemsToLocalize.Add(Items.Description);
	ItemsToLocalize.Add(Items.ExternalReportDetails);
	ItemsToLocalize.Add(Items.Details);
	LocalizationServer.OnCreateAtServer(ItemsToLocalize);
	
	Items.Details.ChoiceButton = Not Items.Details.OpenButton;
EndProcedure

&AtServer
Procedure FillCheckProcessingAtServer(Cancel, CheckedAttributes)
	If Not ValueIsFilled(Object.Description) Then
		Common.MessageToUser(
			NStr("ru = 'Поле ""Наименование"" не заполнено'; en = 'Description is not populated'; pl = 'Nie wypełniono nazwy';de = 'Der Name ist nicht ausgefüllt';ro = 'Numele nu este completat';tr = 'Isim doldurulmadı'; es_ES = 'Nombre no está poblado'"),
			,
			"Description");
		Cancel = True;
	ElsIf ReportsOptions.DescriptionIsUsed(Context.ReportRef, OptionRef, Object.Description) Then
		Common.MessageToUser(
			StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = '""%1"" занято, необходимо указать другое Наименование.'; en = '""%1"" is taken. Enter another description.'; pl = '""%1"" jest już używane, wprowadź inną nazwę.';de = '""%1"" wird bereits verwendet, geben Sie einen anderen Namen ein.';ro = '""%1"" este deja folosit, introduceți un alt Nume.';tr = '""%1"" zaten kullanılmakta, başka bir ad girin.'; es_ES = '""%1"" ya está utilizado, introducir otro nombre.'"),
				Object.Description),
			,
			"Description");
		Cancel = True;
	EndIf;
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	If Source = FormName Then
		Return;
	EndIf;
	
	If EventName = ReportsOptionsClient.EventNameChangingOption()
		Or EventName = "Write_ConstantsSet" Then
		FillOptionsList(True);
	EndIf;
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	CurrentItem = Items.Description;
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure DescriptionOpen(Item, StandardProcessing)
	LocalizationClient.OnOpen(Object, Item, "Description", StandardProcessing);
EndProcedure

&AtClient
Procedure DescriptionOnChange(Item)
	DescriptionModified = True;
	SetOptionSavingScenario();
EndProcedure

&AtClient
Procedure AvailableOnChange(Item)
	Object.AvailableToAuthorOnly = (Available = "AuthorOnly");
EndProcedure

&AtClient
Procedure DescriptionStartChoice(Item, ChoiceData, StandardProcessing)
	StandardProcessing = False;
	Notification = New NotifyDescription("BeginSelectDetailsCompletion", ThisObject);
	CommonClient.ShowMultilineTextEditingForm(Notification, Items.Details.EditText,
		NStr("ru = 'Описание'; en = 'Details'; pl = 'Szczegóły';de = 'Einzelheiten';ro = 'Detalii';tr = 'Ayrıntılar'; es_ES = 'Detalles'"));
EndProcedure

&AtClient
Procedure DetailsOpen(Item, StandardProcessing)
	LocalizationClient.OnOpen(Object, Item, "Details", StandardProcessing);
EndProcedure

&AtClient
Procedure DetailsOnChange(Item)
	DetailsModified = True;
EndProcedure

&AtClient
Procedure ExternalReportDetailsOpen(Item, StandardProcessing)
	LocalizationClient.OnOpen(Object, Item, "Details", StandardProcessing);
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersReportOptions

&AtClient
Procedure ReportOptionsOnActivateRow(Item)
	If Not DescriptionModified AND Not DetailsModified Then 
		AttachIdleHandler("SetOptionSavingScenarioDeferred", 0.1, True);
	EndIf;
	DescriptionModified = False;
	DetailsModified = False;
EndProcedure

&AtClient
Procedure ReportOptionsChoice(Item, RowSelected, Field, StandardProcessing)
	StandardProcessing = False;
	SaveAndLoad();
EndProcedure

&AtClient
Procedure ReportOptionsBeforeChangeRow(Item, Cancel)
	Cancel = True;
	OpenOptionForChange();
EndProcedure

&AtClient
Procedure ReportOptionsBeforeDelete(Item, Cancel)
	Cancel = True;
	Option = Items.ReportOptions.CurrentData;
	If Option = Undefined Or Not ValueIsFilled(Option.Ref) Then
		Return;
	EndIf;
	
	If Not Context.FullRightsToOptions AND Not Option.CurrentUserAuthor Then
		WarningText = NStr("ru = 'Недостаточно прав для удаления варианта отчета ""%1"".'; en = 'Insufficient rights to delete report option %1.'; pl = 'Niewystarczające uprawnienia do usunięcia wersji raportu ""%1"".';de = 'Nicht ausreichende Rechte, um die Berichtsvariante ""%1"" zu löschen.';ro = 'Drepturi insuficiente pentru ștergerea variantei raportului ""%1"".';tr = '""%1"" Rapor seçeneğini silmek için haklar yetersiz.'; es_ES = 'Insuficientes derechos para eliminar la variante del informe ""%1"".'");
		WarningText = StringFunctionsClientServer.SubstituteParametersToString(WarningText, Option.Description);
		ShowMessageBox(, WarningText);
		Return;
	EndIf;
	
	If Not Option.Custom Then
		ShowMessageBox(, NStr("ru = 'Невозможно удалить предопределенный вариант отчета.'; en = 'Predefined report options cannot be deleted.'; pl = 'Nie można usunąć predefiniowanego wariantu raportu.';de = 'Die vordefinierte Berichtsoption kann nicht gelöscht werden.';ro = 'Nu se poate șterge opțiunea predefinită a raportului.';tr = 'Ön tanımlı rapor öğesi silinemedi.'; es_ES = 'No se puede borrar la opción del informe predefinida.'"));
		Return;
	EndIf;
	
	If Option.DeletionMark Then
		QuestionText = NStr("ru = 'Снять с ""%1"" пометку на удаление?'; en = 'Do you want to unmark %1 for deletion?'; pl = 'Oczyścić znacznik usunięcia dla ""%1""?';de = 'Löschzeichen für ""%1"" löschen?';ro = 'Scoateți marcajul la ștergere de pe ""%1""?';tr = '""%1"" silme işareti kaldırılsın mı?'; es_ES = '¿Eliminar la marca para borrar para ""%1""?'");
	Else
		QuestionText = NStr("ru = 'Пометить ""%1"" на удаление?'; en = 'Do you want to mark %1 for deletion?'; pl = 'Zaznaczyć ""%1"" do usunięcia?';de = 'Markieren Sie ""%1"" zum Löschen?';ro = 'Marcați ""%1"" la ștergere?';tr = '""%1"" silinmek üzere işaretlensin mi?'; es_ES = '¿Marcar ""%1"" para borrar?'");
	EndIf;
	QuestionText = StringFunctionsClientServer.SubstituteParametersToString(QuestionText, Option.Description);
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("ID", Option.GetID());
	Handler = New NotifyDescription("ReportOptionsBeforeDeleteCompletion", ThisObject, AdditionalParameters);
	
	ShowQueryBox(Handler, QuestionText, QuestionDialogMode.YesNo, 60, DialogReturnCode.Yes); 
EndProcedure

&AtClient
Procedure ReportOptionsBeforeDeleteCompletion(Response, AdditionalParameters) Export
	If Response = DialogReturnCode.Yes Then
		DeleteOptionAtServer(AdditionalParameters.ID);
		ReportsOptionsClient.UpdateOpenForms();
	EndIf;
EndProcedure

&AtClient
Procedure ReportOptionsBeforeAddRow(Item, Cancel, Clone, Parent, Folder)
	Cancel = True;
EndProcedure

#EndRegion

#Region SubsystemsTreeFormTableItemsEventHandlers

&AtClient
Procedure SubsystemsTreeUsageOnChange(Item)
	ReportsOptionsClient.SubsystemsTreeUsageOnChange(ThisObject, Item);
EndProcedure

&AtClient
Procedure SubsystemsTreeImportanceOnChange(Item)
	ReportsOptionsClient.SubsystemsTreeImportanceOnChange(ThisObject, Item);
EndProcedure

#EndRegion

#Region FormCommandHandlers

&AtClient
Procedure Back(Command)
	GoToPage1();
EndProcedure

&AtClient
Procedure Next(Command)
	Package = New Structure;
	Package.Insert("CheckPage1",       True);
	Package.Insert("GoToPage2",       True);
	Package.Insert("FillPage2Server", True);
	Package.Insert("CheckAndWriteServer", False);
	Package.Insert("CloseAfterWrite",       False);
	Package.Insert("CurrentStep", Undefined);
	
	ExecuteBatch(Undefined, Package);
EndProcedure

&AtClient
Procedure Save(Command)
	SaveAndLoad();
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure DefineBehaviorInMobileClient()
	IsMobileClient = Common.IsMobileClient();
	If Not IsMobileClient Then 
		Return;
	EndIf;
	
	CommandBarLocation = FormCommandBarLabelLocation.Auto;
EndProcedure

&AtServer
Procedure SetConditionalAppearance()
	
	ConditionalAppearance.Items.Clear();
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ReportOptions.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ReportOptionsDescription.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("ReportOptions.Custom");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;

	Item.Appearance.SetParameterValue("TextColor", StyleColors.ReportHiddenColorVariant);
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ReportOptions.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ReportOptionsDescription.Name);
	
	FilterGroup = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
 
 	ItemFilter = FilterGroup.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("FullRightsToOptions");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	ItemFilter = FilterGroup.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("ReportOptions.CurrentUserAuthor");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;

	Item.Appearance.SetParameterValue("TextColor", StyleColors.ReportHiddenColorVariant);
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ReportOptions.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ReportOptionsDescription.Name);
	
 	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("ReportOptions.Order");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = 3;
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.ReportHiddenColorVariant);
	
	ReportsOptions.SetSubsystemsTreeConditionalAppearance(ThisObject);
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Client

&AtClient
Procedure SetOptionSavingScenarioDeferred()
	SetOptionSavingScenario();
EndProcedure

&AtClient
Procedure ExecuteBatch(Result, Package) Export
	If Not Package.Property("OptionIsNew") Then
		Package.Insert("OptionIsNew", Not ValueIsFilled(OptionRef));
	EndIf;
	
	// Processing the previous step result.
	If Package.CurrentStep = "PromptForOverwrite" Then
		Package.CurrentStep = Undefined;
		If Result = DialogReturnCode.Yes Then
			Package.Insert("PromptForOverwriteConfirmed", True);
		Else
			Return;
		EndIf;
	EndIf;
	
	// Performing the next step.
	If Package.CheckPage1 = True Then
		// Description is not entered.
		If Not ValueIsFilled(Object.Description) Then
			ErrorText = NStr("ru = 'Поле ""Наименование"" не заполнено'; en = 'Description is not populated'; pl = 'Nie wypełniono nazwy';de = 'Der Name ist nicht ausgefüllt';ro = 'Numele nu este completat';tr = 'Isim doldurulmadı'; es_ES = 'Nombre no está poblado'");
			CommonClient.MessageToUser(ErrorText, , "Object.Description");
			Return;
		EndIf;
		
		// Description of the existing report option is entered.
		If Not Package.OptionIsNew Then
			FoundItems = ReportOptions.FindRows(New Structure("Ref", OptionRef));
			Option = FoundItems[0];
			If Not RightToWriteOption(Option, Context.FullRightsToOptions) Then
				ErrorText = NStr("ru = 'Недостаточно прав для изменения варианта ""%1"". Необходимо выбрать другой вариант или изменить Наименование.'; en = 'Insufficient rights to modify option ""%1"". Save it under a different description or select another report option.'; pl = 'Niewystarczające uprawnienia do zmiany wariantu ""%1"". Wybierz inny wariant lub zmień nazwę.';de = 'Unzureichende Rechte zum Ändern der Option ""%1"". Wählen Sie eine andere Option oder ändern Sie den Namen.';ro = 'Opțiunea insuficientă de schimbare a drepturilor ""%1"". Selectați altă opțiune sau schimbați numele.';tr = '""%1"" Seçeneğini değiştirmek için yetersiz hak. Başka bir seçenek seçin veya ismi değiştirin.'; es_ES = 'Insuficientes derechos para cambiar la opción ""%1"". Seleccionar otra opción o cambiar el nombre.'");
				ErrorText = StringFunctionsClientServer.SubstituteParametersToString(ErrorText, Object.Description);
				CommonClient.MessageToUser(ErrorText, , "Object.Description");
				Return;
			EndIf;
			
			If Not Package.Property("PromptForOverwriteConfirmed") Then
				If Option.DeletionMark = True Then
					QuestionText = NStr("ru = 'Вариант отчета ""%1"" помечен на удаление.
					|Заменить помеченный на удаление вариант отчета?'; 
					|en = 'Report option %1 is marked for deletion. 
					|Do you want to overwrite it?'; 
					|pl = 'Wariant raportu ""%1"" zaznaczono do usunięcia.
					|Zamienić zaznaczony do usunięcia wariant raportu?';
					|de = 'Die Berichtsoption ""%1"" ist zum Löschen markiert. 
					|Möchten Sie die zum Löschen markierte Berichtsoption ersetzen?';
					|ro = 'Varianta raportului ""%1"" este marcată la ștergere.
					|Doriți să înlocuiți varianta raportului marcată la ștergere?';
					|tr = 'Rapor seçeneği ""%1"" silinmek üzere işaretlendi. 
					|Silinmek üzere işaretlenmiş rapor seçeneğini değiştirmek ister misiniz?'; 
					|es_ES = 'Opción del informe ""%1"" está marcada para borrar.
					|¿Quiere reemplazar la opción del informe marcada para borrar?'");
					DefaultButton = DialogReturnCode.No;
				Else
					QuestionText = NStr("ru = 'Заменить ранее сохраненный вариант отчета ""%1""?'; en = 'Do you want to overwrite the option of %1 report?'; pl = 'Zamienić poprzedni zapisany wariant raportu ""%1""?';de = 'Ersetzen Sie eine zuvor gespeicherte Option des Berichts ""%1""?';ro = 'Înlocuiți o opțiune salvată anterior de raport ""%1""?';tr = 'Önceden kaydedilmiş bir rapor ""%1"" değiştirilsin mi?'; es_ES = '¿Reemplazar una opción del informe ""%1"" previamente guardada?'");
					DefaultButton = DialogReturnCode.Yes;
				EndIf;
				QuestionText = StringFunctionsClientServer.SubstituteParametersToString(QuestionText, Object.Description);
				Package.CurrentStep = "PromptForOverwrite";
				Handler = New NotifyDescription("ExecuteBatch", ThisObject, Package);
				ShowQueryBox(Handler, QuestionText, QuestionDialogMode.YesNo, 60, DefaultButton);
				Return;
			EndIf;
		EndIf;
		
		// Check is completed.
		Package.CheckPage1 = False;
	EndIf;
	
	If Package.GoToPage2 = True Then
		// For external reports, only fill checks are executed without switching the page.
		If Not Context.IsExternal Then
			Items.Pages.CurrentPage = Items.More;
			Items.Back.Enabled        = True;
			Items.Next.Enabled        = False;
		EndIf;
		
		// Switch is executed.
		Package.GoToPage2 = False;
	EndIf;
	
	If Package.FillPage2Server = True
		Or Package.CheckAndWriteServer = True Then
		
		ExecutePackageServer(Package);
		
		TreeRows = SubsystemsTree.GetItems();
		For Each TreeRow In TreeRows Do
			Items.SubsystemsTree.Expand(TreeRow.GetID(), True);
		EndDo;
		
		If Package.Cancel = True Then
			GoToPage1();
			Return;
		EndIf;
		
	EndIf;
	
	If Package.CloseAfterWrite = True Then
		ReportsOptionsClient.UpdateOpenForms(, FormName);
		Close(New SettingsChoice(ReportOptionOptionKey));
		Package.CloseAfterWrite = False;
	EndIf;
	
EndProcedure

&AtClient
Procedure GoToPage1()
	Items.Pages.CurrentPage = Items.Main;
	Items.Back.Enabled        = False;
	Items.Next.Title          = "";
	Items.Next.Enabled        = True;
EndProcedure

&AtClient
Procedure OpenOptionForChange()
	Option = Items.ReportOptions.CurrentData;
	If Option = Undefined Or Not ValueIsFilled(Option.Ref) Then
		Return;
	EndIf;
	If Not RightToConfigureOption(Option, Context.FullRightsToOptions) Then
		WarningText = NStr("ru = 'Недостаточно прав доступа для изменения варианта ""%1"".'; en = 'Insufficient rights to modify report option %1.'; pl = 'Niewystarczające uprawnienia do zmiany wariantu ""%1"".';de = 'Zu wenig Zugriffsrechte, um die Option ""%1"" zu ändern.';ro = 'Opțiunea de modificare a drepturilor de acces insuficientă ""%1"".';tr = '""%1"" opsiyonunu değiştirmek için erişim hakları yetersiz.'; es_ES = 'Insuficientes derechos de acceso para cambiar la opción ""%1"".'");
		WarningText = StringFunctionsClientServer.SubstituteParametersToString(WarningText, Option.Description);
		ShowMessageBox(, WarningText);
		Return;
	EndIf;
	ReportsOptionsClient.ShowReportSettings(Option.Ref);
EndProcedure

&AtClient
Procedure SaveAndLoad()
	AdditionalPageFilled = (Items.Pages.CurrentPage = Items.More);
	
	Package = New Structure;
	Package.Insert("CheckPage1",       Not AdditionalPageFilled);
	Package.Insert("GoToPage2",       Not AdditionalPageFilled);
	Package.Insert("FillPage2Server", Not AdditionalPageFilled);
	Package.Insert("CheckAndWriteServer", True);
	Package.Insert("CloseAfterWrite",       True);
	Package.Insert("CurrentStep", Undefined);
	
	ExecuteBatch(Undefined, Package);
EndProcedure

&AtClient
Procedure BeginSelectDetailsCompletion(Val EnteredText, Val AdditionalParameters) Export
	
	If EnteredText = Undefined Then
		Return;
	EndIf;

	Object.Details = EnteredText;
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Client and server

&AtServer
Procedure SetOptionSavingScenario()
	NewObjectWillBeWritten = False;
	ExistingObjectWillBeOverwritten = False;
	CannotOverwrite = False;
	
	If DescriptionModified Then 
		Items.ReportOptions.CurrentRow = Context.SearchByDescription.Get(Object.Description);
	EndIf;
	
	ID = Items.ReportOptions.CurrentRow;
	Option = ?(ID <> Undefined, ReportOptions.FindByID(ID), Undefined);
	
	If Option = Undefined Then
		NewObjectWillBeWritten = True;
		OptionRef = Undefined;
		Object.VisibleByDefault = True;
		If Not DetailsModified Then
			Object.Details = "";
		EndIf;
		Items.ReportOptions.CurrentRow = Undefined;
		If Not Context.FullRightsToOptions Then
			Object.AvailableToAuthorOnly = True;
		EndIf;
	Else
		RightToWriteOption = RightToWriteOption(Option, Context.FullRightsToOptions);
		If RightToWriteOption Then
			ExistingObjectWillBeOverwritten = True;
			DescriptionModified = False;
			Object.Description = Option.Description;
			
			OptionRef = Option.Ref;
			If Context.FullRightsToOptions Then
				Object.AvailableToAuthorOnly = Option.AvailableToAuthorOnly;
			Else
				Object.AvailableToAuthorOnly = True;
			EndIf;
			Object.VisibleByDefault = Option.VisibleByDefault;
			If Not DetailsModified Then
				Object.Details = Option.Details;
			EndIf;
			FillPresentations(Option.Ref);
		Else
			If DescriptionModified Then
				CannotOverwrite = True;
				Items.ReportOptions.CurrentRow = Undefined;
			Else
				NewObjectWillBeWritten = True;
				Object.Description = GenerateFreeDescription(Option, ReportOptions);
			EndIf;
			
			OptionRef = Undefined;
			Object.AvailableToAuthorOnly      = True;
			Object.VisibleByDefault = True;
			If Not DetailsModified Then
				Object.Details = "";
			EndIf;
		EndIf;
	EndIf;
	
	Available = ?(Object.AvailableToAuthorOnly, "AuthorOnly", "AllUsers");
	
	If NewObjectWillBeWritten Then
		Items.NextStepInfo.CurrentPage = Items.New;
		Items.ClearSettings.Visible = False;
		Items.Next.Enabled     = True;
		Items.Save.Enabled = True;
	ElsIf ExistingObjectWillBeOverwritten Then
		Items.NextStepInfo.CurrentPage = Items.OverwriteOption;
		Items.ClearSettings.Visible = True;
		Items.Next.Enabled     = True;
		Items.Save.Enabled = True;
	ElsIf CannotOverwrite Then
		Items.NextStepInfo.CurrentPage = Items.CannotOverwriteOption;
		Items.ClearSettings.Visible = False;
		Items.Next.Enabled     = False;
		Items.Save.Enabled = False;
	EndIf;
EndProcedure

&AtClientAtServerNoContext
Function RightToConfigureOption(Option, FullRightsToOptions)
	Return (FullRightsToOptions Or Option.CurrentUserAuthor) AND ValueIsFilled(Option.Ref);
EndFunction

&AtClientAtServerNoContext
Function RightToWriteOption(Option, FullRightsToOptions)
	Return Option.Custom AND RightToConfigureOption(Option, FullRightsToOptions);
EndFunction

&AtClientAtServerNoContext
Function GenerateFreeDescription(Option, ReportOptions)
	OptionNameTemplate = TrimAll(Option.Description) +" - "+ NStr("ru = 'копия'; en = 'copy'; pl = 'kopiuj';de = 'kopieren';ro = 'copia';tr = 'kopyala'; es_ES = 'copiar'");
	
	FreeDescription = OptionNameTemplate;
	FoundItems = ReportOptions.FindRows(New Structure("Description", FreeDescription));
	If FoundItems.Count() = 0 Then
		Return FreeDescription;
	EndIf;
	
	OptionNumber = 1;
	While True Do
		OptionNumber = OptionNumber + 1;
		FreeDescription = OptionNameTemplate +" (" + Format(OptionNumber, "") + ")";
		FoundItems = ReportOptions.FindRows(New Structure("Description", FreeDescription));
		If FoundItems.Count() = 0 Then
			Return FreeDescription;
		EndIf;
	EndDo;
EndFunction

&AtServer
Procedure FillPresentations(Option)
	Query = New Query("
	|SELECT ALLOWED
	|	&DefaultLanguageCode AS LanguageCode,
	|	CASE
	|		WHEN NOT FromConfiguration.Description IS NULL
	|			THEN FromConfiguration.Description
	|		WHEN NOT FromExtensions.Description IS NULL
	|			THEN FromExtensions.Description
	|		ELSE UserSettings.Description
	|	END AS Description,
	|	CASE
	|		WHEN SUBSTRING(UserSettings.Details, 1, 1) <> """"
	|			THEN UserSettings.Details
	|		WHEN NOT FromConfiguration.Details IS NULL
	|			THEN FromConfiguration.Details
	|		WHEN NOT FromExtensions.Details IS NULL
	|			THEN FromExtensions.Details
	|		ELSE CAST("""" AS STRING(1000))
	|	END AS Details
	|FROM
	|	Catalog.ReportsOptions AS UserSettings
	|	LEFT JOIN Catalog.PredefinedReportsOptions AS FromConfiguration
	|		ON FromConfiguration.Ref = UserSettings.PredefinedVariant
	|	LEFT JOIN Catalog.PredefinedExtensionsReportsOptions AS FromExtensions
	|		ON FromExtensions.Ref = UserSettings.PredefinedVariant
	|WHERE
	|	UserSettings.Ref = &Variant
	|
	|UNION ALL
	|
	|SELECT
	|	CASE
	|		WHEN NOT PresentationsFromConfiguration.LanguageCode IS NULL
	|			THEN PresentationsFromConfiguration.LanguageCode
	|		WHEN NOT PresentationsFromExtensions.LanguageCode IS NULL
	|			THEN PresentationsFromExtensions.LanguageCode
	|		WHEN NOT UserOptionsPresentations.LanguageCode IS NULL
	|			THEN UserOptionsPresentations.LanguageCode
	|		ELSE CAST("""" AS STRING(10))
	|	END AS LanguageCode,
	|	CASE
	|		WHEN NOT PresentationsFromConfiguration.Description IS NULL
	|			THEN PresentationsFromConfiguration.Description
	|		WHEN NOT PresentationsFromExtensions.Description IS NULL
	|			THEN PresentationsFromExtensions.Description
	|		WHEN NOT UserOptionsPresentations.Description IS NULL
	|			THEN UserOptionsPresentations.Description
	|		ELSE CAST("""" AS STRING(150))
	|	END AS Description,
	|	CASE
	|		WHEN SUBSTRING(ISNULL(UserOptionsPresentations.Details, """"), 1, 1) <> """"
	|			THEN UserOptionsPresentations.Details
	|		WHEN NOT PresentationsFromConfiguration.Details IS NULL
	|			THEN PresentationsFromConfiguration.Details
	|		WHEN NOT PresentationsFromExtensions.Details IS NULL
	|			THEN PresentationsFromExtensions.Details
	|		ELSE CAST("""" AS STRING(1000))
	|	END AS Details
	|FROM
	|	Catalog.ReportsOptions AS UserSettings
	|	LEFT JOIN Catalog.ReportsOptions.Presentations AS UserOptionsPresentations
	|		ON UserOptionsPresentations.Ref = UserSettings.Ref
	|		AND UserOptionsPresentations.LanguageCode <> &DefaultLanguageCode
	|	LEFT JOIN Catalog.PredefinedReportsOptions.Presentations AS PresentationsFromConfiguration
	|		ON PresentationsFromConfiguration.Ref = UserSettings.PredefinedVariant
	|		AND PresentationsFromConfiguration.LanguageCode <> &DefaultLanguageCode
	|	LEFT JOIN Catalog.PredefinedExtensionsReportsOptions.Presentations AS PresentationsFromExtensions
	|		ON PresentationsFromExtensions.Ref = UserSettings.PredefinedVariant
	|		AND PresentationsFromExtensions.LanguageCode <> &DefaultLanguageCode
	|WHERE
	|	UserSettings.Ref = &Variant
	|");
	Query.SetParameter("Variant", Option);
	Query.SetParameter("DefaultLanguageCode", Metadata.DefaultLanguage.LanguageCode);
	
	Object.Presentations.Load(Query.Execute().Unload());
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Server call

&AtServer
Procedure ExecutePackageServer(Package)
	
	Package.Insert("Cancel", False);
	
	If Package.FillPage2Server = True Then
		If Not Context.IsExternal Then
			RefillAdditionalPage(Package);
		EndIf;
		Package.FillPage2Server = False;
	EndIf;
	
	If Package.CheckAndWriteServer = True Then
		CheckAndWriteReportOption(Package);
		Package.CheckAndWriteServer = False;
	EndIf;
	
EndProcedure

&AtServer
Procedure DeleteOptionAtServer(ID)
	If ID = Undefined Then
		Return;
	EndIf;
	Option = ReportOptions.FindByID(ID);
	If Option = Undefined Then
		Return;
	EndIf;
	DeletionMark = Not Option.DeletionMark;
	OptionObject = Option.Ref.GetObject();
	OptionObject.SetDeletionMark(DeletionMark);
	Option.DeletionMark = DeletionMark;
	Option.PictureIndex  = ?(DeletionMark, 4, ?(OptionObject.Custom, 3, 5));
EndProcedure

&AtServer
Procedure RefillAdditionalPage(Package)
	If Package.OptionIsNew Then
		OptionBasis = PrototypeRef;
	Else
		OptionBasis = OptionRef;
	EndIf;
	
	DestinationTree = ReportsOptions.SubsystemsTreeGenerate(ThisObject, OptionBasis);
	ValueToFormAttribute(DestinationTree, "SubsystemsTree");
EndProcedure

&AtServer
Procedure CheckAndWriteReportOption(Package)
	IsNewReportOption = Not ValueIsFilled(OptionRef);
	
	BeginTransaction();
	Try
		Lock = New DataLock;
		If Not IsNewReportOption Then
			LockItem = Lock.Add(Metadata.Catalogs.ReportsOptions.FullName());
			LockItem.SetValue("Ref", OptionRef);
		EndIf;
		Lock.Lock();
		
		If IsNewReportOption AND ReportsOptions.DescriptionIsUsed(Context.ReportRef, OptionRef, Object.Description) Then
			ErrorText = StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = '""%1"" занято, необходимо указать другое наименование.'; en = '""%1"" is taken. Enter another description.'; pl = '""%1"" jest już używane, wprowadź inną nazwę.';de = '""%1"" wird bereits verwendet, geben Sie einen anderen Namen ein.';ro = '""%1"" este ocupat, introduceți un alt nume.';tr = '""%1"" zaten kullanılmakta, başka bir ad girin.'; es_ES = '""%1"" ya está utilizado, introducir otro nombre.'"), Object.Description);
			Common.MessageToUser(ErrorText, , "Object.Description");
			Package.Cancel = True;
			RollbackTransaction();
			Return;
		EndIf;
		
		If IsNewReportOption Then
			OptionObject = Catalogs.ReportsOptions.CreateItem();
			OptionObject.Report            = Context.ReportRef;
			OptionObject.ReportType        = Context.ReportType;
			OptionObject.VariantKey     = String(New UUID());
			OptionObject.Custom = True;
			OptionObject.Author            = Context.CurrentUser;
			If PrototypePredefined Then
				OptionObject.Parent = PrototypeRef;
			ElsIf TypeOf(PrototypeRef) = Type("CatalogRef.ReportsOptions") AND Not PrototypeRef.IsEmpty() Then
				OptionObject.Parent = Common.ObjectAttributeValue(PrototypeRef, "Parent");
			Else
				OptionObject.FillInParent();
			EndIf;
		Else
			OptionObject = OptionRef.GetObject();
		EndIf;
		
		If Context.IsExternal Then
			OptionObject.Placement.Clear();
		Else
			DestinationTree = FormAttributeToValue("SubsystemsTree", Type("ValueTree"));
			If IsNewReportOption Then
				ChangedSections = DestinationTree.Rows.FindRows(New Structure("Use", 1), True);
			Else
				ChangedSections = DestinationTree.Rows.FindRows(New Structure("Modified", True), True);
			EndIf;
			ReportsOptions.SubsystemsTreeWrite(OptionObject, ChangedSections);
		EndIf;
		
		OptionObject.Description = Object.Description;
		OptionObject.Details     = Object.Details;
		OptionObject.AvailableToAuthorOnly      = Object.AvailableToAuthorOnly;
		OptionObject.VisibleByDefault = Object.VisibleByDefault;
		
		OptionObject.Presentations.Load(Object.Presentations.Unload());
		LocalizationServer.BeforeWriteAtServer(OptionObject);
		
		OptionObject.Write();
		
		OptionRef       = OptionObject.Ref;
		ReportOptionOptionKey = OptionObject.VariantKey;
		
		If ClearSettings Then
			ReportsOptions.ResetUserSettings(OptionObject.Ref);
		EndIf;
		
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Server

&AtServer
Procedure FillOptionsList(UpdateForm)
	
	CurrentOptionKey = PrototypeKey;
	
	// Changing to the "before refilling" option key.
	CurrentRowID = Items.ReportOptions.CurrentRow;
	If CurrentRowID <> Undefined Then
		CurrentRow = ReportOptions.FindByID(CurrentRowID);
		If CurrentRow <> Undefined Then
			CurrentOptionKey = CurrentRow.VariantKey;
		EndIf;
	EndIf;
	
	FilterReports = New Array;
	FilterReports.Add(Context.ReportRef);
	SearchParameters = New Structure("Reports, OnlyPersonal", FilterReports, True);
	ReportOptionsTable = ReportsOptions.ReportOptionTable(SearchParameters);
	
	// Populate autocalculated columns.
	ReportOptions.Load(ReportOptionsTable);
	For each Option In ReportOptions Do
		Option.CurrentUserAuthor = (Option.Author = Context.CurrentUser);
		Option.PictureIndex = ?(Option.DeletionMark, 3, ?(Option.Custom, 3, 5));
		Option.Order = ?(Option.DeletionMark, 3, ?(Option.Custom, 2, 1));
	EndDo;
	
	If Context.IsExternal
		AND Not SettingsStorages.ReportsVariantsStorage.AddExternalReportOptions(
			ReportOptions, Context.ReportRef, Context.ReportName) Then
		Return;
	EndIf;
	
	ReportOptions.Sort("Description Asc");
	
	Context.SearchByDescription = New Map;
	For Each Option In ReportOptions Do
		ID = Option.GetID();
		Context.SearchByDescription.Insert(Option.Description, ID);
		If Option.VariantKey = PrototypeKey Then
			PrototypeRef           = Option.Ref;
			PrototypePredefined = Not Option.Custom;
		EndIf;
		If Option.VariantKey = CurrentOptionKey Then
			Items.ReportOptions.CurrentRow = ID;
		EndIf;
	EndDo;
	
	SetOptionSavingScenario();
	
EndProcedure

#EndRegion
