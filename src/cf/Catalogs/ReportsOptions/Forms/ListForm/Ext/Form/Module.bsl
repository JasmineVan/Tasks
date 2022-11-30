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
	ClientParameters = ReportsOptions.ClientParameters();
	IncludeSubordinateSubsystems = True;
	
	ValuesTree = ReportsOptionsCached.CurrentUserSubsystems().Copy();
	SubsystemsTreeFillFullPresentation(ValuesTree.Rows);
	ValueToFormAttribute(ValuesTree, "SubsystemsTree");
	
	SubsystemsTreeCurrentRow = -1;
	Items.SubsystemsTree.CurrentRow = 0;
	If Parameters.ChoiceMode = True Then
		FormOperationMode = "Selection";
		WindowOpeningMode = FormWindowOpeningMode.LockOwnerWindow;
		Items.List.Representation = TableRepresentation.List;
	ElsIf Parameters.SectionRef <> Undefined Then
		FormOperationMode = "AllReportsInSection";
		ParentItems = New Array;
		ParentItems.Add(SubsystemsTree.GetItems()[0]);
		While ParentItems.Count() > 0 Do
			ParentItem = ParentItems[0].GetItems();
			ParentItems.Delete(0);
			For Each SubordinateItem In ParentItem Do
				If SubordinateItem.Ref = Parameters.SectionRef Then
					Items.SubsystemsTree.CurrentRow = SubordinateItem.GetID();
					ParentItems.Clear();
					Break;
				EndIf;
				ParentItems.Add(SubordinateItem);
			EndDo;
		EndDo;
	Else
		FormOperationMode = "List";
		CommonClientServer.SetFormItemProperty(Items, "Change", "Representation", ButtonRepresentation.PictureAndText);
		CommonClientServer.SetFormItemProperty(Items, "PlaceInSections", "OnlyInAllActions", False);
	EndIf;
	
	GlobalSettings = ReportsOptions.GlobalSettings();
	Items.SearchString.InputHint = GlobalSettings.Search.InputHint;
	
	WindowOptionsKey = FormOperationMode;
	PurposeUseKey = FormOperationMode;
	
	SetListPropertyByFormParameter("ChoiceMode");
	SetListPropertyByFormParameter("ChoiceFoldersAndItems");
	SetListPropertyByFormParameter("MultipleChoice");
	SetListPropertyByFormParameter("CurrentRow");
	
	Items.Select.DefaultButton = Parameters.ChoiceMode;
	Items.Select.Visible = Parameters.ChoiceMode;
	Items.FilterByReportType.Visible = ReportsOptions.FullRightsToOptions();
	
	ChoiceList = Items.FilterByReportType.ChoiceList;
	ChoiceList.Add(1, NStr("ru = 'Все, кроме внешних'; en = 'All but external reports'; pl = 'Wszystkie, oprócz zewnętrznych';de = 'Alle, außer extern';ro = 'Toate, cu excepția celor externe';tr = 'Harici olanlar dışında hepsi'; es_ES = 'Todos excepto externos'"));
	ChoiceList.Add(Enums.ReportTypes.Internal,     NStr("ru = 'Внутренние'; en = 'Integrated reports'; pl = 'Wewnętrzne';de = 'Interne';ro = 'Intern';tr = 'Dahili'; es_ES = 'Interno'"));
	ChoiceList.Add(Enums.ReportTypes.Extension,     NStr("ru = 'Расширения'; en = 'Extensions'; pl = 'Rozszerzenia';de = 'Erweiterungen';ro = 'Extensii';tr = 'Uzantılar'; es_ES = 'Extensiones'"));
	ChoiceList.Add(Enums.ReportTypes.Additional, NStr("ru = 'Дополнительные'; en = 'Additional reports'; pl = 'Dodatkowe';de = 'Zusätzlich';ro = 'Suplimentar';tr = 'Ek'; es_ES = 'Adicional'"));
	ChoiceList.Add(Enums.ReportTypes.External,        NStr("ru = 'Внешние'; en = 'External reports'; pl = 'Zewnętrzne';de = 'Extern';ro = 'Extern';tr = 'Harici'; es_ES = 'Externo'"));
	
	SearchString = Parameters.SearchString;
	If Parameters.Filter.Property("ReportType", FilterByReportType) Then
		Parameters.Filter.Delete("ReportType");
	EndIf;
	If Parameters.OptionsOnly Then
		CommonClientServer.SetDynamicListFilterItem(List,
			"VariantKey", "", DataCompositionComparisonType.NotEqual,,,
			DataCompositionSettingsItemViewMode.Normal);
	EndIf;
	
	PersonalListSettings = Common.CommonSettingsStorageLoad(
		ReportsOptionsClientServer.FullSubsystemName(),
		"Catalog.ReportsOptions.ListForm");
	If PersonalListSettings <> Undefined Then
		Items.SearchString.ChoiceList.LoadValues(PersonalListSettings.SearchStringSelectionList);
	EndIf;
	
	List.Parameters.SetParameterValue("AvailableReports", ReportsOptions.CurrentUserReports());
	List.Parameters.SetParameterValue("DIsabledApplicationOptions", New Array(ReportsOptionsCached.DIsabledApplicationOptions()));
	List.Parameters.SetParameterValue("IsMainLanguage", CurrentLanguage() = Metadata.DefaultLanguage);
	List.Parameters.SetParameterValue("LanguageCode", CurrentLanguage().LanguageCode);
	
	CurrentItem = Items.List;
	
	ReportsOptions.ComplementFiltersFromStructure(List.SettingsComposer.Settings.Filter, Parameters.Filter);
	Parameters.Filter.Clear();
	
	UpdateListContent("OnCreateAtServer");
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	If FormOperationMode = "AllReportsInSection" OR FormOperationMode = "Selection" Then
		Items.SubsystemsTree.Expand(SubsystemsTreeCurrentRow, True);
	EndIf;
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	If EventName = ReportsOptionsClient.EventNameChangingOption()
		Or EventName = "Write_ConstantsSet" Then
		SubsystemsTreeCurrentRow = -1;
		AttachIdleHandler("SubsystemsTreeRowActivationHandler", 0.1, True);
	EndIf;
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure FilterReportTypeOnChange(Item)
	UpdateListContent();
EndProcedure

&AtClient
Procedure FilterReportTypeClear(Item, StandardProcessing)
	StandardProcessing = False;
	FilterByReportType = Undefined;
	UpdateListContent();
EndProcedure

&AtClient
Procedure SearchStringOnChange(Item)
	UpdateListContentClient("SearchStringOnChange");
EndProcedure

&AtClient
Procedure IncludeSubordinateSubsystemsOnChange(Item)
	SubsystemsTreeCurrentRow = -1;
	AttachIdleHandler("SubsystemsTreeRowActivationHandler", 0.1, True);
EndProcedure

#EndRegion

#Region SubsystemsTreeFormTableItemsEventHandlers

&AtClient
Procedure SubsystemsTreeBeforeChange(Item, Cancel)
	Cancel = True;
EndProcedure

&AtClient
Procedure SubsystemsTreeBeforeAdd(Item, Cancel, Clone, Parent, Folder)
	Cancel = True;
EndProcedure

&AtClient
Procedure SubsystemsTreeBeforeRemove(Item, Cancel)
	Cancel = True;
EndProcedure

&AtClient
Procedure SubsystemsTreeOnActivateRow(Item)
	AttachIdleHandler("SubsystemsTreeRowActivationHandler", 0.1, True);
	
#If MobileClient Then
	AttachIdleHandler("SetSubsystemsTreeTitle", 0.1, True);
	CurrentItem = Items.List;
#EndIf
EndProcedure

&AtClient
Procedure SubsystemsTreeDrag(Item, DragParameters, StandardProcessing, Row, Field)
	StandardProcessing = False;
	
	If Row = Undefined Then
		Return;
	EndIf;
	
	AssignmentParameters = New Structure("Variants, Action, Destination, Source"); //OptionsArray, Total, and Presentation
	AssignmentParameters.Variants = New Structure("Array, Total, Presentation");
	AssignmentParameters.Variants.Array = DragParameters.Value;
	AssignmentParameters.Variants.Total  = DragParameters.Value.Count();
	
	If AssignmentParameters.Variants.Total = 0 Then
		Return;
	EndIf;
	
	DestinationRow = SubsystemsTree.FindByID(Row);
	If DestinationRow = Undefined OR DestinationRow.Priority = "" Then
		Return;
	EndIf;
	
	AssignmentParameters.Destination = New Structure("Ref, FullPresentation, ID");
	FillPropertyValues(AssignmentParameters.Destination, DestinationRow);
	AssignmentParameters.Destination.ID = DestinationRow.GetID();
	
	SourceRow = Items.SubsystemsTree.CurrentData;
	AssignmentParameters.Source = New Structure("Ref, FullPresentation, ID");
	If SourceRow = Undefined OR SourceRow.Priority = "" Then
		AssignmentParameters.Action = "Copy";
	Else
		FillPropertyValues(AssignmentParameters.Source, SourceRow);
		AssignmentParameters.Source.ID = SourceRow.GetID();
		If DragParameters.Action = DragAction.Copy Then
			AssignmentParameters.Action = "Copy";
		Else
			AssignmentParameters.Action = "Move";
		EndIf;
	EndIf;
	
	If AssignmentParameters.Source.Ref = AssignmentParameters.Destination.Ref Then
		ShowMessageBox(, NStr("ru = 'Выбранные варианты отчетов уже в данном разделе.'; en = 'Selected report options already assigned to this section.'; pl = 'Wybrane opcje sprawozdania znajdują się już w tej sekcji.';de = 'Die ausgewählten Berichtsoptionen befinden sich bereits in diesem Abschnitt.';ro = 'Opțiunile de raport selectate sunt deja în această secțiune.';tr = 'Seçilen rapor seçenekleri bu bölümde zaten var.'; es_ES = 'Las opciones del informe seleccionadas ya están en esta sección.'"));
		Return;
	EndIf;
	
	If AssignmentParameters.Variants.Total = 1 Then
		If AssignmentParameters.Action = "Copy" Then
			QuestionTemplate = NStr("ru = 'Разместить ""%1"" в ""%4""?'; en = 'Do you want to assign %1 to %4?'; pl = 'Umieścić  ""%1"" w ""%4""?';de = 'Platzieren Sie ""%1"" nach ""%4""?';ro = 'Puneți ""%1"" la ""%4""?';tr = '""%1"" ""%4"" ''te yerleştirilsin mi?'; es_ES = '¿Colocar ""%1"" a ""%4""?'");
		Else
			QuestionTemplate = NStr("ru = 'Переместить ""%1"" из ""%3"" в ""%4""?'; en = 'Do you want to move %1 from %3 to %4?'; pl = 'Przenieść ""%1"" z ""%3"" do ""%4""?';de = 'Bewegen Sie ""%1"" von ""%3"" nach ""%4""?';ro = 'Mutare  ""%1"" La  ""%3"" În  ""%4""?';tr = '""%1"", ""%3"" ''dan ""%4"" ''a taşınsın mı?'; es_ES = '¿Mover ""%1"" desde ""%3"" a ""%4""?'");
		EndIf;
		AssignmentParameters.Variants.Presentation = String(AssignmentParameters.Variants.Array[0]);
	Else
		AssignmentParameters.Variants.Presentation = "";
		For Each OptionRef In AssignmentParameters.Variants.Array Do
			AssignmentParameters.Variants.Presentation = AssignmentParameters.Variants.Presentation
			+ ?(AssignmentParameters.Variants.Presentation = "", "", ", ")
			+ String(OptionRef);
			If StrLen(AssignmentParameters.Variants.Presentation) > 23 Then
				AssignmentParameters.Variants.Presentation = Left(AssignmentParameters.Variants.Presentation, 20) + "...";
				Break;
			EndIf;
		EndDo;
		If AssignmentParameters.Action = "Copy" Then
			QuestionTemplate = NStr("ru = 'Разместить варианты отчетов ""%1"" (%2 шт.) в ""%4""?'; en = 'Do you want to assign %2 report options %1 to %4?'; pl = 'Umieścić opcje sprawozdania ""%1"" (%2 szt.) w ""%4""?';de = 'Platzieren Sie die Berichtsoptionen ""%1"" (%2Stück) in ""%4""?';ro = 'Puneți opțiunile raportului ""%1"" (%2 buc.) în ""%4""?';tr = '""%1"" rapor seçeneklerini (%2 adet.) ""%4"" ''te yerleştirilsin mi?'; es_ES = '¿Colocar las opciones del informe ""%1"" (%2 piezas) a ""%4""?'");
		Else
			QuestionTemplate = NStr("ru = 'Переместить варианты отчетов ""%1"" (%2 шт.) из ""%3"" в ""%4""?'; en = 'Do you want to move %2 report options %1 from %3 to %4?'; pl = 'Przenieś opcje sprawozdania ""%1"" (%2 szt.) z ""%3"" do ""%4""?';de = 'Verschieben Sie die Berichtsoptionen ""%1"" (%2Stück) von ""%3"" nach ""%4""?';ro = 'Mutați opțiunile de raport ""%1"" (%2 buc.) De la ""%3"" la ""%4""?';tr = '""%1"" rapor seçenekleri (%2.) ""%3"" ''ten %4''e taşınsın mi?'; es_ES = '¿Mover las opciones del informe ""%1"" (%2 piezas) desde ""%3"" a ""%4""?'");
		EndIf;
	EndIf;
	
	QuestionText = StringFunctionsClientServer.SubstituteParametersToString(
		QuestionTemplate,
		AssignmentParameters.Variants.Presentation,
		Format(AssignmentParameters.Variants.Total, "NG=0"),
		AssignmentParameters.Source.FullPresentation,
		AssignmentParameters.Destination.FullPresentation);
	
	Handler = New NotifyDescription("SubsystemsTreeDragCompletion", ThisObject, AssignmentParameters);
	ShowQueryBox(Handler, QuestionText, QuestionDialogMode.YesNo, 60, DialogReturnCode.Yes);
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersList

&AtClient
Procedure ListBeforeChangeRow(Item, Cancel)
	Cancel = True;
	ReportsOptionsClient.ShowReportSettings(Items.List.CurrentRow);
EndProcedure

&AtClient
Procedure ListChoice(Item, RowSelected, Field, StandardProcessing)
	If FormOperationMode = "AllReportsInSection" Then
		StandardProcessing = False;
		ReportsOptionsClient.OpenReportForm(ThisObject, Items.List.CurrentData);
	ElsIf FormOperationMode = "List" Then
		StandardProcessing = False;
		ReportsOptionsClient.ShowReportSettings(RowSelected);
	EndIf;
EndProcedure

#EndRegion

#Region FormCommandHandlers

&AtClient
Procedure RunSearch(Command)
	UpdateListContentClient("RunSearch");
EndProcedure

&AtClient
Procedure Change(Command)
	ReportsOptionsClient.ShowReportSettings(Items.List.CurrentRow);
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure DefineBehaviorInMobileClient()
	If Not Common.IsMobileClient() Then 
		Return;
	EndIf;
	
	Items.SearchString.Width = 0;
	Items.SearchString.HorizontalStretch = Undefined;
	Items.SearchString.TitleLocation = FormItemTitleLocation.None;
	Items.SearchString.DropListButton = False;
	Items.RunSearch.Representation = ButtonRepresentation.Picture;
EndProcedure

&AtServer
Procedure SubsystemsTreeFillFullPresentation(RowsSet, ParentPresentation = "")
	For Each TreeRow In RowsSet Do
		If IsBlankString(TreeRow.Name) Then
			TreeRow.FullPresentation = "";
		ElsIf IsBlankString(ParentPresentation) Then
			TreeRow.FullPresentation = TreeRow.Presentation;
		Else
			TreeRow.FullPresentation = ParentPresentation + "." + TreeRow.Presentation;
		EndIf;
		SubsystemsTreeFillFullPresentation(TreeRow.Rows, TreeRow.FullPresentation);
	EndDo;
EndProcedure

&AtServer
Procedure SetConditionalAppearance()
	
	ConditionalAppearance.Items.Clear();
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.Details.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("List.Details");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;

	Item.Appearance.SetParameterValue("TextColor", StyleColors.NoteText);
	
EndProcedure

&AtClient
Procedure SubsystemsTreeDragCompletion(Response, AssignmentParameters) Export
	If Response <> DialogReturnCode.Yes Then
		Return;
	EndIf;
	
	ExecutionResult = AssignOptionsToSubsystem(AssignmentParameters);
	ReportsOptionsClient.UpdateOpenForms();
	
	If AssignmentParameters.Variants.Total = ExecutionResult.Placed Then
		If AssignmentParameters.Variants.Total = 1 Then
			If AssignmentParameters.Action = "Move" Then
				Template = NStr("ru = 'Успешно перемещен в ""%1"".'; en = 'Report successfully moved to %1.'; pl = 'Pomyślnie przeniesiono do %1"".';de = 'Erfolgreich übertragen auf %1"".';ro = 'Transferat cu succes la %1"".';tr = '%1"" ''e başarı ile taşındı.'; es_ES = 'Trasladado con éxito a %1"".'");
			Else
				Template = NStr("ru = 'Успешно размещен в ""%1"".'; en = 'Report successfully assigned to %1.'; pl = 'Pomyślnie umieszczono w %1"".';de = 'Erfolgreich platziert in %1"".';ro = 'A fost plasat cu succes în %1"".';tr = '%1"" ''e başarı ile yerleştirildi.'; es_ES = 'Colocado con éxito a %1"".'");
			EndIf;
			Text = AssignmentParameters.Variants.Presentation;
			Ref = GetURL(AssignmentParameters.Variants.Array[0]);
		Else
			If AssignmentParameters.Action = "Move" Then
				Template = NStr("ru = 'Успешно перемещены в ""%1"".'; en = 'Reports successfully moved to %1.'; pl = 'Pomyślnie przeniesiono do %1"".';de = 'Erfolgreich übertragen auf %1"".';ro = 'Transferat cu succes în ""%1"".';tr = '%1"" ''e başarı ile taşındı.'; es_ES = 'Trasladado con éxito a %1"".'");
			Else
				Template = NStr("ru = 'Успешно размещены в ""%1"".'; en = 'Reports successfully assigned to %1.'; pl = 'Pomyślnie umieszczono w %1"".';de = 'Erfolgreich platziert in %1"".';ro = 'Plasate cu succes în ""%1"".';tr = '%1"" ''e başarı ile yerleştirildi.'; es_ES = 'Colocado con éxito a %1"".'");
			EndIf;
			Text = StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = 'Варианты отчетов (%1).'; en = '%1 report options.'; pl = 'Opcje sprawozdania (%1).';de = 'Berichtsoptionen (%1)';ro = 'Opțiunile raportului (%1).';tr = 'Rapor seçenekleri (%1)'; es_ES = 'Opciones del informe (%1).'"), Format(AssignmentParameters.Variants.Total, "NZ=0; NG=0"));
			Ref = Undefined;
		EndIf;
		Template = StringFunctionsClientServer.SubstituteParametersToString(Template, AssignmentParameters.Destination.FullPresentation);
		ShowUserNotification(Template, Ref, Text);
	Else
		ErrorsText = "";
		If Not IsBlankString(ExecutionResult.CannotBePlaced) Then
			ErrorsText = ?(ErrorsText = "", "", ErrorsText + Chars.LF + Chars.LF)
				+ NStr("ru = 'Не могут размещаться в командном интерфейсе:'; en = 'Cannot assign to the command interface:'; pl = 'Nie można umieścić w interfejsie poleceń:';de = 'Kann nicht in der Befehlsschnittstelle platziert werden:';ro = 'Nu pot fi plasate în interfața de comandă:';tr = 'Komut arayüzüne yerleştirilemez:'; es_ES = 'No puede colocarse en le interfaz de comandos:'")
				+ Chars.LF
				+ ExecutionResult.CannotBePlaced;
		EndIf;
		If Not IsBlankString(ExecutionResult.AlreadyPlaced) Then
			ErrorsText = ?(ErrorsText = "", "", ErrorsText + Chars.LF + Chars.LF)
				+ NStr("ru = 'Уже размещены в этом разделе:'; en = 'Already assigned to this section:'; pl = 'Już jest w tej sekcji:';de = 'Bereits in diesem Bereich:';ro = 'Exista deja în această secțiune:';tr = 'Bu bölümde zaten var:'; es_ES = 'Ya ubicado en esta sección:'")
				+ Chars.LF
				+ ExecutionResult.AlreadyPlaced;
		EndIf;
		
		If AssignmentParameters.Action = "Move" Then
			Template = NStr("ru = 'Перемещено вариантов отчетов: %1 из %2.
				|Подробности:
				|%3'; 
				|en = '%1 out of %2 report options have been moved.
				|Details:
				|%3'; 
				|pl = 'Przemieszczone warianty sprawozdań: %1 z %2.
				|Szczegóły:
				|%3';
				|de = 'Verschobene Berichtsoptionen: %1 von %2.
				|Details:
				|%3';
				|ro = 'Variante de rapoarte mutate: %1 din %2.
				|Detalii:
				|%3';
				|tr = 'Rapor seçenekleri taşındı: %1 içinden %2. 
				| Detaylar: 
				|%3'; 
				|es_ES = 'Trasladado variantes de informes: %1 de %2. 
				|Detalles:
				|%3'");
		Else
			Template = NStr("ru = 'Размещено вариантов отчетов: %1 из %2.
				|Подробности:
				|%3'; 
				|en = '%1 of %2 report options have been assigned.
				|Details:
				|%3'; 
				|pl = 'rozmieszczone warianty raportów: %1 z %2.
				|Szczegóły:
				|%3';
				|de = 'Platzierte Berichtsoptionen: %1 von%2.
				| Details:
				|%3';
				|ro = 'Variante de rapoarte plasate: %1 din %2.
				|Detalii:
				|%3';
				|tr = 'Rapor seçenekleri yerleştirildi: %1 içinden %2. 
				| Detaylar: 
				|%3'; 
				|es_ES = 'Colocado variantes de informes: %1 de %2. 
				|Detalles:
				|%3'");
		EndIf;
		
		StandardSubsystemsClient.ShowQuestionToUser(Undefined, 
			StringFunctionsClientServer.SubstituteParametersToString(Template, ExecutionResult.Placed, 
				AssignmentParameters.Variants.Total, ErrorsText), QuestionDialogMode.OK);
	EndIf;
	
EndProcedure

&AtServer
Procedure SetListPropertyByFormParameter(varKey)
	
	If Parameters.Property(varKey) AND ValueIsFilled(Parameters[varKey]) Then
		Items.List[varKey] = Parameters[varKey];
	EndIf;
	
EndProcedure

&AtServer
Procedure UpdateListContent(Val Event = "")
	PersonalSettingsChanged = False;
	If ValueIsFilled(SearchString) Then
		ChoiceList = Items.SearchString.ChoiceList;
		ListItem = ChoiceList.FindByValue(SearchString);
		If ListItem = Undefined Then
			ChoiceList.Insert(0, SearchString);
			PersonalSettingsChanged = True;
			If ChoiceList.Count() > 10 Then
				ChoiceList.Delete(10);
			EndIf;
		Else
			Index = ChoiceList.IndexOf(ListItem);
			If Index <> 0 Then
				ChoiceList.Move(Index, -Index);
				PersonalSettingsChanged = True;
			EndIf;
		EndIf;
		CurrentItem = Items.SearchString;
	EndIf;
	
	If Event = "SearchStringOnChange" AND PersonalSettingsChanged Then
		PersonalListSettings = New Structure("SearchStringSelectionList");
		PersonalListSettings.SearchStringSelectionList = Items.SearchString.ChoiceList.UnloadValues();
		Common.CommonSettingsStorageSave(
			ReportsOptionsClientServer.FullSubsystemName(),
			"Catalog.ReportsOptions.ListForm",
			PersonalListSettings);
	EndIf;
	
	SubsystemsTreeCurrentRow = Items.SubsystemsTree.CurrentRow;
	
	TreeRow = SubsystemsTree.FindByID(SubsystemsTreeCurrentRow);
	If TreeRow = Undefined Then
		Return;
	EndIf;
	
	AllSubsystems = Not ValueIsFilled(TreeRow.FullName);
	
	SearchParameters = New Structure;
	If ValueIsFilled(SearchString) Then
		SearchParameters.Insert("SearchString", SearchString);
		Items.List.InitialTreeView = InitialTreeView.ExpandAllLevels;
	Else
		Items.List.InitialTreeView = InitialTreeView.NoExpand;
	EndIf;
	If Not AllSubsystems Or ValueIsFilled(SearchString) Then
		ReportsSubsystems = New Array;
		If Not AllSubsystems Then
			ReportsSubsystems.Add(TreeRow.Ref);
		EndIf;
		If AllSubsystems Or IncludeSubordinateSubsystems Then
			AddRecursively(ReportsSubsystems, TreeRow.GetItems());
		EndIf;
		SearchParameters.Insert("Subsystems", ReportsSubsystems);
	EndIf;
	If ValueIsFilled(FilterByReportType) Then
		ReportsTypes = New Array;
		If FilterByReportType = 1 Then
			ReportsTypes.Add(Enums.ReportTypes.Internal);
			ReportsTypes.Add(Enums.ReportTypes.Extension);
			ReportsTypes.Add(Enums.ReportTypes.Additional);
		Else
			ReportsTypes.Add(FilterByReportType);
		EndIf;
		SearchParameters.Insert("ReportTypes", ReportsTypes);
	EndIf;
	
	HasFilterByOptions = SearchParameters.Count() > 0;
	SearchParameters.Insert("DeletionMark", False);
	SearchParameters.Insert("ExactFilterBySubsystems", Not AllSubsystems);
	
	SearchResult = ReportsOptions.FindReportsOptions(SearchParameters);
	List.Parameters.SetParameterValue("HasVariantFilter", HasFilterByOptions);
	List.Parameters.SetParameterValue("UserOptions", SearchResult.References);
	
EndProcedure

&AtClient
Procedure SubsystemsTreeRowActivationHandler()
	If SubsystemsTreeCurrentRow <> Items.SubsystemsTree.CurrentRow Then
		UpdateListContent();
	EndIf;
EndProcedure

&AtClient
Procedure SetSubsystemsTreeTitle()
	Items.SectionsGroup.Title = ?(Items.SubsystemsTree.CurrentData = Undefined,
		NStr("ru = 'Все разделы'; en = 'All sections'; pl = 'Wszystkie sekcje';de = 'Alle Abschnitte';ro = 'Toate compartimentele';tr = 'Tüm bölümler'; es_ES = 'Todas secciones'", CommonClient.DefaultLanguageCode()),
		Items.SubsystemsTree.CurrentData.Presentation);
EndProcedure

&AtServer
Procedure AddRecursively(SubsystemsArray, TreeRowsCollection)
	For Each TreeRow In TreeRowsCollection Do
		SubsystemsArray.Add(TreeRow.Ref);
		AddRecursively(SubsystemsArray, TreeRow.GetItems());
	EndDo;
EndProcedure

&AtServer
Procedure SubsystemsTreeWritePropertyToArray(TreeRowsArray, PropertyName, RefsArray)
	For Each TreeRow In TreeRowsArray Do
		RefsArray.Add(TreeRow[PropertyName]);
		SubsystemsTreeWritePropertyToArray(TreeRow.GetItems(), PropertyName, RefsArray);
	EndDo;
EndProcedure

&AtServer
Function AssignOptionsToSubsystem(AssignmentParameters)
	SubsystemsToExclude = New Array;
	If AssignmentParameters.Action = "Move" Then
		SourceRow = SubsystemsTree.FindByID(AssignmentParameters.Source.ID);
		SubsystemsToExclude.Add(SourceRow.Ref);
		SubsystemsTreeWritePropertyToArray(SourceRow.GetItems(), "Ref", SubsystemsToExclude);
	EndIf;
	
	Assigned = 0;
	AlreadyAssigned = "";
	CannotBeAssigned = "";
	BeginTransaction();
	Try
		For Each OptionRef In AssignmentParameters.Variants.Array Do
			If OptionRef.ReportType = Enums.ReportTypes.External Then
				CannotBeAssigned = ?(CannotBeAssigned = "", "", CannotBeAssigned + Chars.LF)
					+ "  "
					+ String(OptionRef)
					+ " ("
					+ NStr("ru = 'внешний'; en = 'external'; pl = 'Zewnętrzne';de = 'extern';ro = 'extern';tr = 'harici'; es_ES = 'externo'")
					+ ")";
				Continue;
			ElsIf OptionRef.DeletionMark Then
				CannotBeAssigned = ?(CannotBeAssigned = "", "", CannotBeAssigned + Chars.LF)
					+ "  "
					+ String(OptionRef)
					+ " ("
					+ NStr("ru = 'помечен на удаление'; en = 'marked for deletion'; pl = 'zaznaczony do usunięcia';de = 'ist zum Löschen vorgemerkt';ro = 'marcat la ștergere';tr = 'silinmek üzere işaretlendi'; es_ES = 'marcado para borrar'")
					+ ")";
				Continue;
			EndIf;
			
			HasChanges = False;
			OptionObject = OptionRef.GetObject();
			
			DestinationRow = OptionObject.Placement.Find(AssignmentParameters.Destination.Ref, "Subsystem");
			If DestinationRow = Undefined Then
				DestinationRow = OptionObject.Placement.Add();
				DestinationRow.Subsystem = AssignmentParameters.Destination.Ref;
			EndIf;
			
			// Removing a row from a source subsystem.
			// Remember that a predefined option is excluded from a subsystem, when you clear the subsystem 
			// check box.
			If AssignmentParameters.Action = "Move" Then
				For Each SubsystemToExclude In SubsystemsToExclude Do
					SourceRow = OptionObject.Placement.Find(SubsystemToExclude, "Subsystem");
					If SourceRow <> Undefined Then
						If SourceRow.Use Then
							SourceRow.Use = False;
							If Not HasChanges Then
								FillPropertyValues(DestinationRow, SourceRow, "Important, SeeAlso");
								HasChanges = True;
							EndIf;
						EndIf;
						SourceRow.Important  = False;
						SourceRow.SeeAlso = False;
					ElsIf Not OptionObject.Custom Then
						SourceRow = OptionObject.Placement.Add();
						SourceRow.Subsystem = SubsystemToExclude;
						HasChanges = True;
					EndIf;
				EndDo;
			EndIf;
			
			// Registering a row in a destination subsystem.
			If Not DestinationRow.Use Then
				HasChanges = True;
				DestinationRow.Use = True;
			EndIf;
			
			If HasChanges Then
				Assigned = Assigned + 1;
				OptionObject.Write();
			Else
				AlreadyAssigned = ?(AlreadyAssigned = "", "", AlreadyAssigned + Chars.LF)
					+ "  "
					+ String(OptionRef);
			EndIf;
		EndDo;
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;
	
	If AssignmentParameters.Action = "Move" AND Assigned > 0 Then
		Items.SubsystemsTree.CurrentRow = AssignmentParameters.Destination.ID;
		UpdateListContent();
	EndIf;
	
	Return New Structure("Placed,AlreadyPlaced,CannotBePlaced", Assigned, AlreadyAssigned, CannotBeAssigned);
EndFunction

&AtClient
Procedure UpdateListContentClient(Event)
	Msrmnt = StartMeasurement(Event);
	UpdateListContent(Event);
	EndMeasurement(Msrmnt);
EndProcedure

&AtClient
Function StartMeasurement(Event)
	If Not ClientParameters.RunMeasurements Then
		Return Undefined;
	EndIf;
	
	If ValueIsFilled(SearchString) AND (Event = "SearchStringOnChange" Or Event = "RunSearch") Then
		Name = "ReportsList.Search";
	Else
		Return Undefined;
	EndIf;
	
	Comment = ClientParameters.MeasurementsPrefix;
	
	If ValueIsFilled(SearchString) Then
		Comment = Comment
			+ "; " + NStr("ru = 'Поиск:'; en = 'Search:'; pl = 'Wyszukiwanie:';de = 'Suche:';ro = 'Căutare:';tr = 'Arama:'; es_ES = 'Búsqueda:'") + " " + String(SearchString)
			+ "; " + NStr("ru = 'Включая подчиненные:'; en = 'Include subordinate reports:'; pl = 'Łącznie z podporządkowanymi:';de = 'Einschließlich der Untergebenen:';ro = 'Inclusiv subordonate:';tr = 'Alt sıra dahil:'; es_ES = 'Incluso subordinados:'") + " " + String(IncludeSubordinateSubsystems);
	Else
		Comment = Comment + "; " + NStr("ru = 'Без поиска'; en = 'No search'; pl = 'Bez wyszukiwania';de = 'Ohne Suche';ro = 'Fără căutare';tr = 'Aramadan'; es_ES = 'Sin buscar'");
	EndIf;
	
	Msrmnt = New Structure("ModulePerformanceMonitorClient, ID");
	Msrmnt.ModulePerformanceMonitorClient = CommonClient.CommonModule("PerformanceMonitorClient");
	Msrmnt.ID = Msrmnt.ModulePerformanceMonitorClient.TimeMeasurement(Name, False, False);
	Msrmnt.ModulePerformanceMonitorClient.SetMeasurementComment(Msrmnt.ID, Comment);
	Return Msrmnt;
EndFunction

&AtClient
Procedure EndMeasurement(Msrmnt)
	If Msrmnt <> Undefined Then
		Msrmnt.ModulePerformanceMonitorClient.StopTimeMeasurement(Msrmnt.ID);
	EndIf;
EndProcedure

#EndRegion