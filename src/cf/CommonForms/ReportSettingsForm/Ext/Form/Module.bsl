///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Variables

&AtClient
Var DragSourceAtClient;
&AtClient
Var DragDestinationAtClient;

#EndRegion

#Region EventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	SetConditionalAppearance();
	
	DefineBehaviorInMobileClient();
	
	ParametersForm = New Structure(
		"PurposeUseKey, UserSettingsKey,
		|Details, GenerateOnOpen, ReadOnly,
		|FixedSettings, Section, Subsystem, SubsystemPresentation");
	FillPropertyValues(ParametersForm, Parameters);
	ParametersForm.Insert("Filter", New Structure);
	If TypeOf(Parameters.Filter) = Type("Structure") Then
		CommonClientServer.SupplementStructure(ParametersForm.Filter, Parameters.Filter, True);
		Parameters.Filter.Clear();
	EndIf;
	
	If Not Parameters.Property("ReportSettings", ReportSettings) Then
		Raise NStr("ru = 'Не передан служебный параметр ""НастройкиОтчета"".'; en = 'ReportSettings service parameter has not been passed.'; pl = 'Nie przekazano parametru serwisowego ReportSettings.';de = 'Serviceparameter ""ReportSettings"" ist nicht bestanden.';ro = 'Parametrul serviciului ""ReportSettings"" nu este transmis.';tr = 'Servis parametresi ReportSettings geçmedi.'; es_ES = 'Parámetro de servicio ReportSettings no está pasado.'");
	EndIf;
	If Not Parameters.Property("DescriptionOption", DescriptionOption) Then
		Raise NStr("ru = 'Не передан служебный параметр ""ВариантНаименование"".'; en = 'OptionDescription service parameter has not been passed.'; pl = 'Nie przekazano parametru serwisowego OptionDescription.';de = 'Serviceparameter ""OptionDescription"" ist nicht bestanden.';ro = 'Parametrul serviciului ""OptionDescription"" nu este transmis.';tr = 'Hizmet parametresi OptionDescription geçirilmedi.'; es_ES = 'Parámetro de servicio OptionDescription no está pasado.'");
	EndIf;
	
	WindowOptionsKey = ReportSettings.FullName;
	If ValueIsFilled(CurrentVariantKey) Then
		WindowOptionsKey = WindowOptionsKey + "." + CurrentVariantKey;
	EndIf;
	
	DCSettings = CommonClientServer.StructureProperty(Parameters, "Variant");
	If DCSettings = Undefined Then
		DCSettings = Report.SettingsComposer.Settings;
	EndIf;
	
	Parameters.Property("SettingsStructureItemID", SettingsStructureItemID);
	If TypeOf(SettingsStructureItemID) = Type("DataCompositionID") Then
		SettingsStructureItemChangeMode = True;
		Height = 0;
		WindowOptionsKey = WindowOptionsKey + ".Node";
		
		If Not Parameters.Property("Title", Title) Then
			Raise NStr("ru = 'Не передан служебный параметр ""Заголовок"".'; en = 'Title service parameter has not been passed.'; pl = 'Nie przesłano parametru serwisowego ""Nagłówek"".';de = 'Der Serviceparameter ""Titel"" wird nicht übertragen.';ro = 'Parametrul de serviciu ""Title"" nu este transferat.';tr = 'Servis parametresi ""Başlık"" aktarılmaz.'; es_ES = 'Parámetro de servicio ""Título"" no se ha transferido.'");
		EndIf;
		
		If Not Parameters.Property("SettingsStructureItemType", SettingsStructureItemType) Then
			Raise NStr("ru = 'Не передан служебный параметр ""ТипЭлементаСтруктурыНастроек"".'; en = 'SettingsStructureItemType service parameter has not been passed.'; pl = 'Nie przekazano parametru serwisowego ""SettingsStructureItemType"".';de = 'Es wurde kein Service-Parameter ""SettingsStructureItemType"" übergeben.';ro = 'Nu este transmis parametrul de serviciu ""SettingsStructureItemType"".';tr = 'Hizmet parametresi ""SettingsStructureItemType"" geçmedi.'; es_ES = 'No se ha pasado el parámetro de servicio ""SettingsStructureItemType"".'");
		EndIf;
	Else
		If Not ValueIsFilled(DescriptionOption) Then
			DescriptionOption = ReportSettings.Description;
		EndIf;
		Title = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Настройки отчета ""%1""'; en = '%1 report settings'; pl = 'Ustawienia raportu ""%1""';de = 'Berichtseinstellungen ""%1""';ro = 'Setările raportului ""%1""';tr = 'Rapor ayarları ""%1""'; es_ES = 'Ajustes del informe ""%1""'"), DescriptionOption);
	EndIf;
	
	GlobalSettings = ReportsOptions.GlobalSettings();
	Items.AppearanceCustomizeHeadersFooters.Visible =
		GlobalSettings.OutputIndividualHeaderOrFooterSettings AND Not SettingsStructureItemChangeMode;
	
	If SettingsStructureItemChangeMode Then
		PageName = CommonClientServer.StructureProperty(Parameters, "PageName", "GroupingContentPage");
		ExtendedMode = 1;
	Else
		ExtendedMode = CommonClientServer.StructureProperty(ReportSettings, "SettingsFormAdvancedMode", 0);
		PageName = CommonClientServer.StructureProperty(ReportSettings, "SettingsFormPageName", "FiltersPage");
	EndIf;
	
	Page = Items.Find(PageName);
	If Page <> Undefined Then
		Items.SettingsPages.CurrentPage = Page;
	EndIf;
	
	If ReportSettings.SchemaModified Then
		Report.SettingsComposer.Initialize(New DataCompositionAvailableSettingsSource(ReportSettings.SchemaURL));
	EndIf;
	
	InactiveTableValueColor = StyleColors.InaccessibleCellTextColor;
	
	// Registering commands and form attributes that are not deleted upon overwriting quick settings.
	AttributesSet = GetAttributes();
	For Each Attribute In AttributesSet Do
		ConstantAttributes.Add(FullAttributeName(Attribute));
	EndDo;
	
	For Each Command In Commands Do
		ConstantCommands.Add(Command.Name);
	EndDo;
	
	SettingsUpdateRequired = True;
EndProcedure

&AtServer
Procedure BeforeLoadVariantAtServer(NewDCSettings)
	
	If TypeOf(ParametersForm.Filter) = Type("Structure") Then
		ReportsServer.SetFixedFilters(ParametersForm.Filter, NewDCSettings, ReportSettings);
	EndIf;
	
	SettingsUpdateRequired = True;
	
	// Preparing for calling the reinitialization event.
	If ReportSettings.Events.BeforeImportSettingsToComposer Then
		Try
			NewXMLSettings = Common.ValueToXMLString(NewDCSettings);
		Except
			NewXMLSettings = Undefined;
		EndTry;
		ReportSettings.Insert("NewXMLSettings", NewXMLSettings);
	EndIf;
EndProcedure

&AtServer
Procedure BeforeLoadUserSettingsAtServer(NewDCUserSettings)
	
	SettingsUpdateRequired = True;
	
	// Preparing for calling the reinitialization event.
	If ReportSettings.Events.BeforeImportSettingsToComposer Then
		Try
			NewUserXMLSettings = Common.ValueToXMLString(NewDCUserSettings);
		Except
			NewUserXMLSettings = Undefined;
		EndTry;
		ReportSettings.Insert("NewUserXMLSettings", NewUserXMLSettings);
	EndIf;
EndProcedure

&AtServer
Procedure OnUpdateUserSettingSetAtServer(StandardProcessing)
	
	StandardProcessing = False;
	VariantModified = False;
	
	If SettingsUpdateRequired Then
		SettingsUpdateRequired = False;
		
		FillingParameters = New Structure;
		FillingParameters.Insert("EventName", "OnCreateAtServer");
		FillingParameters.Insert("UpdateOptionSettings", Not SettingsStructureItemChangeMode AND ExtendedMode = 1);
		
		UpdateForm(FillingParameters);
	EndIf;
EndProcedure

&AtClient
Procedure BeforeClose(Cancel, Exit, WarningText, StandardProcessing)
	VariantModified = False;
EndProcedure

&AtClient
Procedure OnClose(Exit)
	If Exit Then
		Return;
	EndIf;
	
	If SelectionResultGenerated Then
		Return;
	EndIf;
	
	If OnCloseNotifyDescription <> Undefined Then
		ExecuteNotifyProcessing(OnCloseNotifyDescription, SelectionResult(False));
	EndIf;
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure ExtendedModeOnChange(Item)
	UpdateParameters = New Structure;
	UpdateParameters.Insert("EventName", "ExtendedModeOnChange");
	UpdateParameters.Insert("DCSettingsComposer", Report.SettingsComposer);
	UpdateParameters.Insert("UpdateOptionSettings", ExtendedMode = 1);
	UpdateParameters.Insert("ResetUserSettings", ExtendedMode <> 1);
	
	UpdateForm(UpdateParameters);
EndProcedure

&AtClient
Procedure NoUserSettingsWarningsURLProcessing(Item, FormattedStringURL, StandardProcessing)
	StandardProcessing = False;
	ExtendedMode = 1;
	ExtendedModeOnChange(Undefined);
EndProcedure

&AtClient
Procedure CurrentChartTypeOnChange(Item)
	StructureItem = Report.SettingsComposer.Settings.GetObjectByID(SettingsStructureItemID);
	If TypeOf(StructureItem) = Type("DataCompositionNestedObjectSettings") Then
		StructureItem = StructureItem.Settings;
	EndIf;
	
	SetOutputParameter(StructureItem, "ChartType", CurrentChartType);
	DetermineIfModified();
EndProcedure

&AtClient
Procedure HasNestedReportsTooltipURLProcessing(Item, Address, StandardProcessing)
	StandardProcessing = False;
	Row = Items.OptionStructure.CurrentData;
	ChangeStructureItem(Row,, True);
EndProcedure

&AtClient
Procedure OutputTitleOnChange(Item)
	PredefinedParameters = Report.SettingsComposer.Settings.OutputParameters.Items;
	
	SettingItem = PredefinedParameters.Find("TITLE");
	SettingItem.Use = OutputTitle;
	
	SynchronizePredefinedOutputParameters(OutputTitle, SettingItem);
	DetermineIfModified();
EndProcedure

&AtClient
Procedure OutputParametersAndFiltersOnChange(Item)
	PredefinedParameters = Report.SettingsComposer.Settings.OutputParameters.Items;
	
	SettingItem = PredefinedParameters.Find("DATAPARAMETERSOUTPUT");
	SettingItem.Use = True;
	
	If DisplayParametersAndFilters Then 
		SettingItem.Value = DataCompositionTextOutputType.Auto;
	Else
		SettingItem.Value = DataCompositionTextOutputType.DontOutput;
	EndIf;
	
	SynchronizePredefinedOutputParameters(DisplayParametersAndFilters, SettingItem);
	DetermineIfModified();
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Attachable

&AtClient
Procedure Attachable_Period_OnChange(Item)
	ReportsClient.SetPeriod(ThisObject, Item.Name);
EndProcedure

&AtClient
Procedure Attachable_SettingItem_OnChange(Item)
	SettingsComposer = Report.SettingsComposer;
	
	Index = PathToItemsData.ByName[Item.Name];
	If Index = Undefined Then 
		Index = ReportsClientServer.SettingItemIndexByPath(Item.Name);
	EndIf;
	
	SettingItem = SettingsComposer.UserSettings.Items[Index];
	
	IsCheckBox = StrStartsWith(Item.Name, "CheckBox") Or StrEndsWith(Item.Name, "CheckBox");
	If IsCheckBox Then 
		SettingItem.Value = ThisObject[Item.Name];
	EndIf;
	
	If TypeOf(SettingItem) = Type("DataCompositionSettingsParameterValue")
		AND ReportSettings.ImportSettingsOnChangeParameters.Find(SettingItem.Parameter) <> Undefined Then 
		
		UpdateParameters = New Structure;
		UpdateParameters.Insert("DCSettingsComposer", SettingsComposer);
		
		UpdateForm(UpdateParameters);
	Else
		RegisterList(Item, SettingItem);
	EndIf;
EndProcedure

&AtClient
Procedure Attachable_ListItem_OnChange(Item)
	ListPath = StrReplace(Item.Name, "Value", "");
	
	Row = Items[ListPath].CurrentData;
	
	ListItem = ThisObject[ListPath].FindByValue(Row.Value);
	ListItem.Check = True;
EndProcedure

&AtClient
Procedure Attachable_List_OnChange(Item)
	SettingsComposer = Report.SettingsComposer;
	
	Index = PathToItemsData.ByName[Item.Name];
	SettingItem = SettingsComposer.UserSettings.Items[Index];
	
	List = ThisObject[Item.Name];
	SelectedValues = New ValueList;
	For Each ListItem In List Do 
		If ListItem.Check Then 
			FillPropertyValues(SelectedValues.Add(), ListItem);
		EndIf;
	EndDo;
	
	If TypeOf(SettingItem) = Type("DataCompositionSettingsParameterValue") Then 
		SettingItem.Value = SelectedValues;
	ElsIf TypeOf(SettingItem) = Type("DataCompositionFilterItem") Then 
		SettingItem.RightValue = SelectedValues;
	EndIf;
	SettingItem.Use = True;
	
	RegisterList(Item, SettingItem);
EndProcedure

&AtClient
Procedure Attachable_ListItem_StartChoice(Item, ChoiceData, StandardProcessing)
	StandardProcessing = False;
	
	ListPath = StrReplace(Item.Name, "Value", "");
	
	FillingParameters = ListFillingParameters(True, False, False);
	FillingParameters.ListPath = ListPath;
	FillingParameters.IndexOf = PathToItemsData.ByName[ListPath];
	FillingParameters.Owner = Item;
	
	StartListFilling(Item, FillingParameters);
EndProcedure

&AtClient
Procedure Attachable_List_ChoiceProcessing(Item, SelectionResult, StandardProcessing)
	StandardProcessing = False;
	
	List = ThisObject[Item.Name];
	
	Selected = ReportsClientServer.ValuesByList(SelectionResult);
	Selected.FillChecks(True);
	
	Addition = ReportsClientServer.AddToList(List, Selected, False, True);
	
	Index = PathToItemsData.ByName[Item.Name];
	SettingsComposer = Report.SettingsComposer;
	SettingItem = SettingsComposer.UserSettings.Items[Index];
	
	If TypeOf(SettingItem) = Type("DataCompositionSettingsParameterValue") Then
		SettingItem.Value = List;
	Else
		SettingItem.RightValue = List;
	EndIf;
	SettingItem.Use = True;
	
	RegisterList(Item, SettingItem);
	
	If Addition.Total > 0 Then
		If Addition.Total = 1 Then
			NotificationTitle = NStr("ru = 'Элемент добавлен в список'; en = 'The item added to the list.'; pl = 'Element dodany do listy';de = 'Element zur Liste hinzugefügt';ro = 'Elementul este adăugat în listă';tr = 'Öğe listeye eklendi'; es_ES = 'Elemento añadido en la lista'");
		Else
			NotificationTitle = NStr("ru = 'Элементы добавлены в список'; en = 'The items added to the list.'; pl = 'Elementy zostały dodane do listy';de = 'Elemente zur Liste hinzugefügt';ro = 'Elementele sunt adăugate în listă';tr = 'Öğeler listeye eklendi'; es_ES = 'Elementos añadidos en la lista'");
		EndIf;
		
		ShowUserNotification(
			NotificationTitle,,
			String(Selected),
			PictureLib.ExecuteTask);
	EndIf;
	
	DetermineIfModified();
EndProcedure

#EndRegion

#Region SortingFormTableItemsEventHandlers

&AtClient
Procedure SortingChoice(Item, RowID, Field, StandardProcessing)
	StandardProcessing = False;
	
	Row = Items.Sort.CurrentData;
	If Row = Undefined Then
		Return;
	EndIf;
	
	If TypeOf(Row.Field) = Type("DataCompositionField") Then
		If Field = Items.SortingField Then // Changing the field
			SortingSelectField(RowID, Row);
		ElsIf Field = Items.SortingOrderType Then // Changing the order.
			ChangeOrderType(Row);
		EndIf;
	EndIf;
EndProcedure

&AtClient
Procedure SortingBeforeAdd(Item, Cancel, Clone, Parent, Folder, Parameter)
	Cancel = True;
	SelectField("Sort", New NotifyDescription("SortAfterFieldChoice", ThisObject));
EndProcedure

&AtClient
Procedure SortingBeforeRemove(Item, Cancel)
	DeleteRows(Item, Cancel);
EndProcedure

&AtClient
Procedure SortingUsageOnChange(Item)
	ChangeSettingItemUsage("Sort");
EndProcedure

&AtClient
Procedure Sort_Descending(Command)
	ChangeRowsOrderType(DataCompositionSortDirection.Desc);
EndProcedure

&AtClient
Procedure Sort_Ascending(Command)
	ChangeRowsOrderType(DataCompositionSortDirection.Asc);
EndProcedure

&AtClient
Procedure Sorting_MoveUp(Command)
	ShiftSorting();
EndProcedure

&AtClient
Procedure Sorting_MoveDown(Command)
	ShiftSorting(False);
EndProcedure

&AtClient
Procedure Sorting_SelectCheckBoxes(Command)
	ChangeUsage("Sort");
EndProcedure

&AtClient
Procedure Sorting_ClearCheckBoxes(Command)
	ChangeUsage("Sort", False);
EndProcedure

&AtClient
Procedure SortingStartDragging(Item, DragParameters, AllowDragging)
	DragSourceAtClient = Item.Name;
EndProcedure

&AtClient
Procedure SortingCheckDragging(Item, DragParameters, StandardProcessing, CurrentRow, Field)
	DragDestinationAtClient = Item.Name;
	
	If DragParameters.Value.Count() > 0 Then 
		StandardProcessing = False;
	EndIf;
EndProcedure

&AtClient
Procedure SortingDragging(Item, DragParameters, StandardProcessing, CurrentRow, Field)
	StandardProcessing = False;
	If DragSourceAtClient = Item.Name Then 
		DragSortingWithinCollection(DragParameters, CurrentRow);
	ElsIf DragSourceAtClient = Items.SelectedFields.Name Then 
		DragSelectedFieldsToSorting(DragParameters.Value);
	EndIf;
EndProcedure

&AtClient
Procedure SortingEndDragging(Item, DragParameters, StandardProcessing)
	StandardProcessing = False;
EndProcedure

&AtClient
Procedure SelectedFields_Sorting_Right(Command)
	RowsIDs = Items.SelectedFields.SelectedRows;
	If RowsIDs = Undefined Then 
		Return;
	EndIf;
	
	Rows = New Array;
	For Each RowID In RowsIDs Do 
		Row = SelectedFields.FindByID(RowID);
		If TypeOf(Row.ID) = Type("DataCompositionID") Then 
			Rows.Add(Row);
		EndIf;
	EndDo;
	
	DragSelectedFieldsToSorting(Rows);
EndProcedure

&AtClient
Procedure SelectedFields_Sorting_Left(Command)
	RowsIDs = Items.Sort.SelectedRows;
	If RowsIDs = Undefined Then 
		Return;
	EndIf;
	
	Rows = New Array;
	For Each RowID In RowsIDs Do 
		Row = Sort.FindByID(RowID);
		If TypeOf(Row.ID) = Type("DataCompositionID") Then 
			Rows.Add(Row);
		EndIf;
	EndDo;
	
	DragSortingFieldsToSelectedFields(Rows);
EndProcedure

&AtClient
Procedure SelectedFields_Sorting_LeftAll(Command)
	DragSortingFieldsToSelectedFields(Sort.GetItems()[0].GetItems());
EndProcedure

#EndRegion

#Region SelectedFieldsFormTableItemsEventHandlers

&AtClient
Procedure SelectedFieldsChoice(Item, RowID, Field, StandardProcessing)
	StandardProcessing = False;
	
	Row = Items.SelectedFields.CurrentData;
	If Row = Undefined Then
		Return;
	EndIf;
	
	If Field = Items.SelectedFieldsField Then // Changing order.
		If TypeOf(Row.Field) = Type("DataCompositionField") Then
			SelectedFieldsSelectField(RowID, Row);
		ElsIf Row.IsFolder Then
			SelectedFieldsSelectGroup(RowID, Row);
		EndIf;
	EndIf;
EndProcedure

&AtClient
Procedure SelectedFieldsBeforeAdd(Item, Cancel, Clone, Parent, Folder, Parameter)
	Cancel = True;
	
	Handler = New NotifyDescription("SelectedFieldsAfterFieldChoice", ThisObject);
	SelectField("SelectedFields", Handler);
EndProcedure

&AtClient
Procedure SelectedFieldsBeforeRemove(Item, Cancel)
	If ExtendedMode = 0 Then
		Cancel = True;
		Return;
	EndIf;
	DeleteRows(Item, Cancel);
EndProcedure

&AtClient
Procedure SelectedFieldsUsageOnChange(Item)
	ChangeSettingItemUsage("SelectedFields");
EndProcedure

&AtClient
Procedure SelectedFields_MoveUp(Command)
	ShiftSelectedFields();
EndProcedure

&AtClient
Procedure SelectedFields_MoveDown(Command)
	ShiftSelectedFields(False);
EndProcedure

&AtClient
Procedure SelectedFields_Group(Command)
	GroupingParameters = GroupingParametersOfSelectedFields();
	If GroupingParameters = Undefined Then 
		Return;
	EndIf;
	
	FormParameters = New Structure("Placement", DataCompositionFieldPlacement.Auto);
	Handler = New NotifyDescription("SelectedFieldsBeforeGroupFields", ThisObject, GroupingParameters);
	OpenForm("SettingsStorage.ReportsVariantsStorage.Form.SelectedFieldsGroup", FormParameters, 
		ThisObject, UUID,,, Handler, FormWindowOpeningMode.LockOwnerWindow);
EndProcedure

&AtClient
Procedure SelectedFields_Ungroup(Command)
	RowsIDs = Items.SelectedFields.SelectedRows;
	If RowsIDs.Count() <> 1 Then 
		ShowMessageBox(, NStr("ru = 'Выберите одну группу.'; en = 'Select a group.'; pl = 'Wybierz grupę.';de = 'Wählen Sie eine Gruppe aus.';ro = 'Selectați un grup.';tr = 'Bir grubu seçin.'; es_ES = 'Seleccionar un grupo.'"));
		Return;
	EndIf;
	
	SourceRowParent = SelectedFields.FindByID(RowsIDs[0]);
	If TypeOf(SourceRowParent.ID) <> Type("DataCompositionID") Then 
		ShowMessageBox(, NStr("ru = 'Выберите группу.'; en = 'Select a group.'; pl = 'Wybierz grupę.';de = 'Wähle die Gruppe.';ro = 'Selectați grupul.';tr = 'Grubu seçin.'; es_ES = 'Seleccionar un grupo.'"));
		Return;
	EndIf;
	
	StructureItemProperty = SettingsStructureItemProperty(
		Report.SettingsComposer, "Selection", SettingsStructureItemID, ExtendedMode);
	
	SourceSettingItemParent = StructureItemProperty.GetObjectByID(SourceRowParent.ID);
	If TypeOf(SourceSettingItemParent) <> Type("DataCompositionSelectedFieldGroup") Then 
		ShowMessageBox(, NStr("ru = 'Выберите группу.'; en = 'Select a group.'; pl = 'Wybierz grupę.';de = 'Wähle die Gruppe.';ro = 'Selectați grupul.';tr = 'Grubu seçin.'; es_ES = 'Seleccionar un grupo.'"));
		Return;
	EndIf;
	
	DestinationSettingItemParent = SourceSettingItemParent.Parent;
	If SourceSettingItemParent.Parent = Undefined Then 
		DestinationSettingItemParent = StructureItemProperty;
	EndIf;
	
	SettingsItemsInheritors = New Map;
	SettingsItemsInheritors.Insert(SourceSettingItemParent, DestinationSettingItemParent);
	
	DestinationRowParent = SourceRowParent.GetParent();
	RowsInheritors = New Map;
	RowsInheritors.Insert(SourceRowParent, DestinationRowParent);
	
	ChangeGroupingOfSelectedFields(StructureItemProperty, SourceRowParent.GetItems(), SettingsItemsInheritors, RowsInheritors);
	
	// Deleting basic grouping items.
	DestinationRowParent.GetItems().Delete(SourceRowParent);
	DestinationSettingItemParent.Items.Delete(SourceSettingItemParent);
	
	Section = SelectedFields.GetItems()[0];
	Items.SelectedFields.Expand(Section.GetID(), True);
	Items.SelectedFields.CurrentRow = DestinationRowParent.GetID();
	
	DetermineIfModified();
EndProcedure

&AtClient
Procedure SelectedFields_SelectCheckBoxes(Command)
	ChangeUsage("SelectedFields");
EndProcedure

&AtClient
Procedure SelectedFields_ClearCheckBoxes(Command)
	ChangeUsage("SelectedFields", False);
EndProcedure

&AtClient
Procedure SelectedFieldsStartDragging(Item, DragParameters, AllowDragging)
	DragSourceAtClient = Item.Name;
	
	CheckRowsToDragFromSelectedFields(DragParameters.Value);
	If DragParameters.Value.Count() = 0 Then 
		AllowDragging = False;
	EndIf;
EndProcedure

&AtClient
Procedure SelectedFieldsCheckDragging(Item, DragParameters, StandardProcessing, CurrentRow, Field)
	DragDestinationAtClient = Item.Name;
	
	If DragParameters.Value.Count() > 0 Then 
		StandardProcessing = False;
	EndIf;
EndProcedure

&AtClient
Procedure SelectedFieldsDrag(Item, DragParameters, StandardProcessing, CurrentRow, Field)
	StandardProcessing = False;
	
	If DragSourceAtClient = Item.Name Then 
		DragSelectedFieldsWithinCollection(DragParameters, CurrentRow);
	EndIf;
EndProcedure

&AtClient
Procedure SelectedFieldsEndDragging(Item, DragParameters, StandardProcessing)
	If DragDestinationAtClient <> Item.Name Then 
		Return;
	EndIf;
	
	StandardProcessing = False;
	
	StructureItemProperty = SettingsStructureItemProperty(
		Report.SettingsComposer, "Selection", SettingsStructureItemID, ExtendedMode);
	
	Rows = DragParameters.Value;
	Parent = Rows[0].GetParent();
	
	Index = Rows.UBound();
	While Index >= 0 Do 
		Row = Rows[Index];
		
		SettingItem = SettingItem(StructureItemProperty, Row);
		SettingItemParent = StructureItemProperty;
		If SettingItem.Parent <> Undefined Then 
			SettingItemParent = SettingItem.Parent;
		EndIf;
		
		SettingItemParent.Items.Delete(SettingItem);
		Parent.GetItems().Delete(Row);
		
		Index = Index - 1;
	EndDo;
EndProcedure

#EndRegion

#Region FiltersFormTableItemsEventHandlers

&AtClient
Procedure Filters_Group(Command)
	GroupingParameters = FiltersGroupingParameters();
	If GroupingParameters = Undefined Then 
		Return;
	EndIf;
	
	StructureItemProperty = SettingsStructureItemProperty(
		Report.SettingsComposer, "Filter", SettingsStructureItemID);
	
	// Processing setting items.
	SettingItemSource = StructureItemProperty;
	If TypeOf(GroupingParameters.Parent.ID) = Type("DataCompositionID") Then 
		SettingItemSource = StructureItemProperty.GetObjectByID(GroupingParameters.Parent.ID);
	EndIf;
	
	SettingItemDestination = SettingItemSource.Items.Insert(GroupingParameters.IndexOf, Type("DataCompositionFilterItemGroup"));
	SettingItemDestination.UserSettingID = New UUID;
	SettingItemDestination.ViewMode = DataCompositionSettingsItemViewMode.Inaccessible;
	
	SettingsItemsInheritors = New Map;
	SettingsItemsInheritors.Insert(SettingItemSource, SettingItemDestination);
	
	// Processing rows.
	SourceRow = GroupingParameters.Parent;
	DestinationRow = SourceRow.GetItems().Insert(GroupingParameters.IndexOf);
	SetFiltersRowData(DestinationRow, StructureItemProperty, SettingItemDestination);
	DestinationRow.ID = StructureItemProperty.GetIDByObject(SettingItemDestination);
	
	RowsInheritors = New Map;
	RowsInheritors.Insert(SourceRow, DestinationRow);
	
	ChangeFiltersGrouping(StructureItemProperty, GroupingParameters.Rows, SettingsItemsInheritors, RowsInheritors);
	DeleteBasicFiltersGroupingItems(StructureItemProperty, GroupingParameters);
	
	Section = DefaultRootRow("Filters");
	Items.Filters.Expand(Section.GetID(), True);
	Items.Filters.CurrentRow = DestinationRow.GetID();
	
	DetermineIfModified();
EndProcedure

&AtClient
Procedure Filters_Ungroup(Command)
	RowsIDs = Items.Filters.SelectedRows;
	If RowsIDs.Count() <> 1 Then 
		ShowMessageBox(, NStr("ru = 'Выберите одну группу.'; en = 'Select a group.'; pl = 'Wybierz grupę.';de = 'Wählen Sie eine Gruppe aus.';ro = 'Selectați un grup.';tr = 'Bir grubu seçin.'; es_ES = 'Seleccionar un grupo.'"));
		Return;
	EndIf;
	
	SourceRowParent = Filters.FindByID(RowsIDs[0]);
	If TypeOf(SourceRowParent.ID) <> Type("DataCompositionID") Then 
		ShowMessageBox(, NStr("ru = 'Выберите группу.'; en = 'Select a group.'; pl = 'Wybierz grupę.';de = 'Wähle die Gruppe.';ro = 'Selectați grupul.';tr = 'Grubu seçin.'; es_ES = 'Seleccionar un grupo.'"));
		Return;
	EndIf;
	
	StructureItemProperty = SettingsStructureItemProperty(
		Report.SettingsComposer, "Filter", SettingsStructureItemID);
	
	SourceSettingItemParent = StructureItemProperty.GetObjectByID(SourceRowParent.ID);
	If TypeOf(SourceSettingItemParent) <> Type("DataCompositionFilterItemGroup") Then 
		ShowMessageBox(, NStr("ru = 'Выберите группу.'; en = 'Select a group.'; pl = 'Wybierz grupę.';de = 'Wähle die Gruppe.';ro = 'Selectați grupul.';tr = 'Grubu seçin.'; es_ES = 'Seleccionar un grupo.'"));
		Return;
	EndIf;
	
	DestinationSettingItemParent = SourceSettingItemParent.Parent;
	If SourceSettingItemParent.Parent = Undefined Then 
		DestinationSettingItemParent = StructureItemProperty;
	EndIf;
	
	SettingsItemsInheritors = New Map;
	SettingsItemsInheritors.Insert(SourceSettingItemParent, DestinationSettingItemParent);
	
	DestinationRowParent = SourceRowParent.GetParent();
	RowsInheritors = New Map;
	RowsInheritors.Insert(SourceRowParent, DestinationRowParent);
	
	ChangeFiltersGrouping(StructureItemProperty, SourceRowParent.GetItems(), SettingsItemsInheritors, RowsInheritors);
	
	// Deleting basic grouping items.
	DestinationRowParent.GetItems().Delete(SourceRowParent);
	DestinationSettingItemParent.Items.Delete(SourceSettingItemParent);
	
	Section = DefaultRootRow("Filters");
	Items.Filters.Expand(Section.GetID(), True);
	Items.Filters.CurrentRow = DestinationRowParent.GetID();
	
	DetermineIfModified();
EndProcedure

&AtClient
Procedure Filters_MoveUp(Command)
	ShiftFilters();
EndProcedure

&AtClient
Procedure Filters_MoveDown(Command)
	ShiftFilters(False);
EndProcedure

&AtClient
Procedure Filters_SelectCheckBoxes(Command)
	ChangeUsage("Parameters");
	ChangeUsage("Filters");
EndProcedure

&AtClient
Procedure Filters_ClearCheckBoxes(Command)
	ChangeUsage("Parameters", False);
	ChangeUsage("Filters", False);
EndProcedure

&AtClient
Procedure Filters_ShowInReportHeader(Command)
	FiltersSetDisplayMode("ShowInReportHeader");
EndProcedure

&AtClient
Procedure Filters_ShowInReportSettings(Command)
	FiltersSetDisplayMode("ShowInReportSettings");
EndProcedure

&AtClient
Procedure Filters_ShowOnlyCheckBoxInReportHeader(Command)
	FiltersSetDisplayMode("ShowOnlyCheckBoxInReportHeader");
EndProcedure

&AtClient
Procedure Filters_ShowOnlyCheckBoxInReportSettings(Command)
	FiltersSetDisplayMode("ShowOnlyCheckBoxInReportSettings");
EndProcedure

&AtClient
Procedure Filters_DontShow(Command)
	FiltersSetDisplayMode("DontShow");
EndProcedure

&AtClient
Procedure FiltersChoice(Item, RowID, Field, StandardProcessing)
	Row = Items.Filters.CurrentData;
	If Row = Undefined Or Row.IsSection Then
		Return;
	EndIf;
	
	StandardProcessing = False;
	
	Fields = StrSplit("FiltersParameter, FiltersGroupType, FiltersLeftValue", ", ", False);
	If Fields.Find(Field.Name) <> Undefined Then 
		If Row.IsParameter Then 
			Return;
		EndIf;
		
		If Row.IsFolder Then 
			FiltersSelectGroup(RowID);
		Else
			FiltersSelectField(RowID, Row);
		EndIf;
	ElsIf Field = Items.FiltersDisplayModePicture Then // Changing quick access to the filter.
		If Row.IsParameter Then 
			StructureItemProperty = SettingsStructureItemProperty(Report.SettingsComposer, "DataParameters");
		Else
			StructureItemProperty = SettingsStructureItemProperty(Report.SettingsComposer, "Filter", SettingsStructureItemID);
		EndIf;
		SelectDisplayMode(StructureItemProperty, "Filters", RowID, True, Not Row.IsParameter);
	Else
		StandardProcessing = True;
	EndIf;
EndProcedure

&AtClient
Procedure FiltersOnActivateRow(Item)
	AttachIdleHandler("FiltersOnChangeCurrentRow", 0.1, True);
EndProcedure

&AtClient
Procedure FiltersOnActivateCell(Item)
	Row = Item.CurrentData;
	If Row = Undefined Then 
		Return;
	EndIf;
	
	IsListField = Row.ValueListAllowed Or ReportsClientServer.IsListComparisonKind(Row.ComparisonType);
	
	ValueField = ?(Row.IsParameter, Items.FiltersValue, Items.FiltersRightValue);
	ValueField.TypeRestriction = ?(IsListField, New TypeDescription("ValueList"), Row.ValueType);
	ValueField.ListChoiceMode = Not IsListField AND (Row.AvailableValues <> Undefined);
	
	CastValueToComparisonKind(Row);
	SetValuePresentation(Row);
EndProcedure

&AtClient
Procedure FiltersBeforeAdd(Item, Cancel, Clone, Parent, Folder, Parameter)
	Cancel = True;
	
	If Not SettingsStructureItemChangeMode Then
		Row = Items.Filters.CurrentData;
		If (Row = Undefined)
			Or (Row.IsParameter)
			Or (Row.IsSection AND Row.ID = "DataParameters") Then
			Row = Filters.GetItems()[1];
			Items.Filters.CurrentRow = Row.GetID();
		EndIf;
	EndIf;
	
	SelectField("Filters", New NotifyDescription("FiltersAfterFieldChoice", ThisObject));
EndProcedure

&AtClient
Procedure FiltersBeforeRemove(Item, Cancel)
	DeleteRows(Item, Cancel);
EndProcedure

&AtClient
Procedure FiltersUsageOnChange(Item)
	ChangeSettingItemUsage("Filters");
EndProcedure

&AtClient
Procedure FiltersComparisonKindOnChange(Item)
	Row = Items.Filters.CurrentData;
	If Row = Undefined Then 
		Return;
	EndIf;
	
	PropertyKey = SettingsStructureItemPropertyKey("Filters", Row);
	StructureItemProperty = SettingsStructureItemProperty(
		Report.SettingsComposer, PropertyKey, SettingsStructureItemID, ExtendedMode);
	
	SettingItem = SettingItem(StructureItemProperty, Row);
	SettingItem.ComparisonType = Row.ComparisonType;
	
	If Row.IsParameter Then 
		Condition = DataCompositionComparisonType.Equal;
		If Row.ValueListAllowed Then 
			Condition = DataCompositionComparisonType.InList;
		EndIf;
	Else
		Condition = Row.ComparisonType;
	EndIf;
	
	ValueField = ?(Row.IsParameter, Items.FiltersValue, Items.FiltersRightValue);
	ValueField.ChoiceFoldersAndItems = ReportsClientServer.GroupsAndItemsTypeValue(Row.ChoiceFoldersAndItems, Condition);
	
	CastValueToComparisonKind(Row, SettingItem);
	DetermineIfModified();
EndProcedure

&AtClient
Procedure FiltersValueOnChange(Item)
	Row = Items.Filters.CurrentData;
	If Row = Undefined Then 
		Return;
	EndIf;
	
	StructureItemProperty = SettingsStructureItemProperty(Report.SettingsComposer, "DataParameters");
	SettingItem = SettingItem(StructureItemProperty, Row);
	SettingItem.Value = Row.Value;
	
	DetermineIfModified();
	SetValuePresentation(Row);
	
	If ReportSettings.ImportSettingsOnChangeParameters.Find(SettingItem.Parameter) <> Undefined Then 
		Report.SettingsComposer.Settings.AdditionalProperties.Insert("ReportInitialized", False);
		
		UpdateParameters = New Structure;
		UpdateParameters.Insert("DCSettingsComposer", Report.SettingsComposer);
		UpdateParameters.Insert("VariantModified", VariantModified);
		UpdateParameters.Insert("UserSettingsModified", UserSettingsModified);
		UpdateParameters.Insert("ResetUserSettings", True);
		
		UpdateForm(UpdateParameters);
	EndIf;
EndProcedure

&AtClient
Procedure FiltersValueStartChoice(Item, ChoiceData, StandardProcessing)
	Row = Items.Filters.CurrentData;
	
	If Row.ValueListAllowed Then 
		ShowChoiceList(Row, StandardProcessing);
	Else
		SetEditParameters(Row);
	EndIf;
EndProcedure

&AtClient
Procedure FiltersRightValueOnChange(Item)
	Row = Items.Filters.CurrentData;
	If Row = Undefined Then 
		Return;
	EndIf;
	
	Row.Use = True;
	
	StructureItemProperty = SettingsStructureItemProperty(
		Report.SettingsComposer, "Filter", SettingsStructureItemID);
	
	SettingItem = SettingItem(StructureItemProperty, Row);
	FillPropertyValues(SettingItem, Row, "Use, RightValue");
	
	DetermineIfModified();
	SetValuePresentation(Row);
EndProcedure

&AtClient
Procedure FiltersRightValueStartChoice(Item, ChoiceData, StandardProcessing)
	Row = Items.Filters.CurrentData;
	
	If ReportsClientServer.IsListComparisonKind(Row.ComparisonType) Then 
		ShowChoiceList(Row, StandardProcessing);
	Else
		SetEditParameters(Row);
	EndIf;
EndProcedure

&AtClient
Procedure FiltersUserSettingPresentationOnChange(Item)
	Row = Items.Filters.CurrentData;
	If Row = Undefined Then
		Return;
	EndIf;
	
	If IsBlankString(Row.UserSettingPresentation) Then
		Row.UserSettingPresentation = Row.Title;
	EndIf;
	Row.IsPredefinedTitle = (Row.Title = Row.UserSettingPresentation);
	
	If Row.IsParameter Then 
		StructureItemProperty = SettingsStructureItemProperty(Report.SettingsComposer, "DataParameters");
	Else
		StructureItemProperty = SettingsStructureItemProperty(
			Report.SettingsComposer, "Filter", SettingsStructureItemID);
	EndIf;
	
	SettingItem = SettingItem(StructureItemProperty, Row);
	If Row.IsPredefinedTitle Then
		SettingItem.UserSettingPresentation = "";
	Else
		SettingItem.UserSettingPresentation = Row.UserSettingPresentation;
	EndIf;
	
	If Not Row.IsParameter Then
		If Row.DisplayModePicture = 1 Or Row.DisplayModePicture = 3 Then
			// If UserSettingPresentation is filled in, the Presentation acts as radio buttons and can also be 
			// used for output to a spreadsheet document.
			// 
			SettingItem.Presentation = Row.UserSettingPresentation;
		Else
			SettingItem.Presentation = "";
		EndIf;
	EndIf;
	
	DetermineIfModified();
EndProcedure

#EndRegion

#Region OptionStructureFormTableItemsEventHandlers

&AtClient
Procedure OptionStructureOnActivateRow(Item)
	AttachIdleHandler("OptionStructureOnChangeCurrentRow", 0.1, True);
EndProcedure

&AtClient
Procedure OptionStructureChoice(Item, IDRow, Field, StandardProcessing)
	StandardProcessing = False;
	If ExtendedMode = 0 Then
		Return;
	EndIf;
	
	Row = Item.CurrentData;
	If Row = Undefined Then
		Return;
	EndIf;
	
	If Row.Type = "DataCompositionSettings"
		Or Row.Type = "DataCompositionTableStructureItemCollection"
		Or Row.Type = "DataCompositionChartStructureItemCollection" Then
		Return;
	EndIf;
	
	If Field = Items.OptionStructurePresentation
		Or Field = Items.OptionStructureContainsFilters
		Or Field = Items.OptionStructureContainsFieldsOrSorting
		Or Field = Items.OptionStructureContainsConditionalAppearance Then
		
		PageName = Undefined;
		If Field = Items.OptionStructureContainsFilters Then
			PageName = "FiltersPage";
		ElsIf Field = Items.OptionStructureContainsFieldsOrSorting Then
			PageName = "SelectedFieldsAndSortingsPage";
		ElsIf Field = Items.OptionStructureContainsConditionalAppearance Then
			PageName = "AppearancePage";
		EndIf;
		ChangeStructureItem(Row, PageName);
	Else
		StandardProcessing = True;
	EndIf;
EndProcedure

&AtClient
Procedure OptionStructureBeforeAdd(Item, Cancel, Clone, Parent, Folder, Parameter)
	Cancel = True;
	
	If Clone
		Or Not Items.OptionStructure_Add.Enabled Then
		Return;
	EndIf;
	
	AddOptionStructureGrouping();
EndProcedure

&AtClient
Procedure OptionStructure_Group(Command)
	If Items.OptionStructure_Group.Enabled Then
		AddOptionStructureGrouping(False);
	EndIf;
EndProcedure

&AtClient
Procedure OptionStructure_AddTable(Command)
	If Items.OptionStructure_AddTable.Enabled Then
		AddSettingsStructureItem(Type("DataCompositionTable"));
	EndIf;
EndProcedure

&AtClient
Procedure OptionStructure_AddChart(Command)
	If Items.OptionStructure_AddChart.Enabled Then
		AddSettingsStructureItem(Type("DataCompositionChart"));
	EndIf;
EndProcedure

&AtClient
Procedure OptionStructure_SelectCheckBoxes(Command)
	ChangeUsage("OptionStructure");
EndProcedure

&AtClient
Procedure OptionStructure_ClearCheckBoxes(Command)
	ChangeUsage("OptionStructure", False);
EndProcedure

&AtClient
Procedure OptionStructureStartDragging(Item, DragParameters, StandardProcessing)
	// Checking general conditions.
	If ExtendedMode = 0 Then
		StandardProcessing = False;
		Return;
	EndIf;
	// Checking the source.
	Row = OptionStructure.FindByID(DragParameters.Value);
	If Row = Undefined Then
		StandardProcessing = False;
		Return;
	EndIf;
	If Row.Type = "DataCompositionChartStructureItemCollection"
		Or Row.Type = "DataCompositionTableStructureItemCollection"
		Or Row.Type = "DataCompositionSettings" Then
		StandardProcessing = False;
		Return;
	EndIf;
EndProcedure

&AtClient
Procedure OptionStructureCheckDragging(Item, DragParameters, StandardProcessing, DestinationID, Field)
	// Checking general conditions.
	If DestinationID = Undefined Then
		DragParameters.Action = DragAction.Cancel;
		Return;
	EndIf;
	// Checking the source.
	Row = OptionStructure.FindByID(DragParameters.Value);
	If Row = Undefined Then
		DragParameters.Action = DragAction.Cancel;
		Return;
	EndIf;
	// Checking the destination.
	NewParent = OptionStructure.FindByID(DestinationID);
	If NewParent = Undefined Then
		DragParameters.Action = DragAction.Cancel;
		Return;
	EndIf;
	If NewParent.Type = "Table"
		Or NewParent.Type = "Chart" Then
		DragParameters.Action = DragAction.Cancel;
		Return;
	EndIf;
	
	// Checking compatibility of the source and destination.
	OnlyGroupingsAreAllowed = False;
	If NewParent.Type = "TableStructureItemCollection"
		Or NewParent.Type = "ChartStructureItemCollection"
		Or NewParent.Type = "TableGroup"
		Or NewParent.Type = "ChartGroup" Then
		OnlyGroupingsAreAllowed = True;
	EndIf;
	
	If OnlyGroupingsAreAllowed
		AND Row.Type <> "Group"
		AND Row.Type <> "TableGroup"
		AND Row.Type <> "ChartGroup" Then
		DragParameters.Action = DragAction.Cancel;
		Return;
	EndIf;
	
	CollectionsOfCollections = New Array;
	CollectionsOfCollections.Add(Row.GetItems());
	Count = 1;
	While Count > 0 Do
		Collection = CollectionsOfCollections[0];
		Count = Count - 1;
		CollectionsOfCollections.Delete(0);
		For Each NestedRow In Collection Do
			If NestedRow = NewParent Then
				DragParameters.Action = DragAction.Cancel;
				Return;
			EndIf;
			If OnlyGroupingsAreAllowed
				AND NestedRow.Type <> "Group"
				AND NestedRow.Type <> "TableGroup"
				AND NestedRow.Type <> "ChartGroup" Then
				DragParameters.Action = DragAction.Cancel;
				Return;
			EndIf;
			CollectionsOfCollections.Add(NestedRow.GetItems());
			Count = Count + 1;
		EndDo;
	EndDo;
EndProcedure

&AtClient
Procedure OptionStructureDragging(Item, DragParameters, StandardProcessing, DestinationID, Field)
	// All checks are passed.
	StandardProcessing = False;
	
	Row = OptionStructure.FindByID(DragParameters.Value);
	NewParent = OptionStructure.FindByID(DestinationID);
	
	Result = MoveOptionStructureItems(Row, NewParent);
	
	Items.OptionStructure.Expand(NewParent.GetID(), True);
	Items.OptionStructure.CurrentRow = Result.Row.GetID();
	
	DetermineIfModified();
EndProcedure

&AtClient
Procedure OptionStructureUsageOnChange(Item)
	ChangeSettingItemUsage("OptionStructure");
EndProcedure

&AtClient
Procedure OptionStructureTitleOnChange(Item)
	Row = Items.OptionStructure.CurrentData;
	If Row = Undefined Then
		Return;
	EndIf;
	
	UpdateOptionStructureItemTitle(Row);
	DetermineIfModified();
EndProcedure

&AtClient
Procedure OptionStructure_MoveUp(Command)
	Context = NewContext("OptionStructure", "Move");
	Context.Insert("Direction", -1);
	DefineSelectedRows(Context);
	If ValueIsFilled(Context.ReasonDenied) Then
		ShowMessageBox(, Context.ReasonDenied);
		Return;
	EndIf;
	
	ShiftRows(Context);
EndProcedure

&AtClient
Procedure OptionStructure_MoveDown(Command)
	Context = NewContext("OptionStructure", "Move");
	Context.Insert("Direction", 1);
	DefineSelectedRows(Context);
	If ValueIsFilled(Context.ReasonDenied) Then
		ShowMessageBox(, Context.ReasonDenied);
		Return;
	EndIf;
	
	ShiftRows(Context);
EndProcedure

&AtClient
Procedure OptionStructure_Change(Command)
	TableItem = Items.OptionStructure;
	Field = TableItem.CurrentItem;
	StandardProcessing = True;
	IDRow = TableItem.CurrentRow;
	OptionStructureChoice(TableItem, IDRow, Field, StandardProcessing);
EndProcedure

&AtClient
Procedure OptionStructureBeforeRemove(Item, Cancel)
	DeleteRows(Item, Cancel);
EndProcedure

&AtClient
Procedure OptionStructure_MoveUpAndLeft(Command)
	If Not Items.OptionStructure_MoveUpAndLeft.Enabled Then
		Return;
	EndIf;
	TableRowUp = Items.OptionStructure.CurrentData;
	If TableRowUp = Undefined Then
		Return;
	EndIf;
	TableRowDown = TableRowUp.GetParent();
	If TableRowDown = Undefined Then
		Return;
	EndIf;
	
	ExecutionParameters = New Structure;
	ExecutionParameters.Insert("Mode",              "UpAndLeft");
	ExecutionParameters.Insert("TableRowUp", TableRowUp);
	ExecutionParameters.Insert("TableRowDown",  TableRowDown);
	OptionStructure_Move(-1, ExecutionParameters);
EndProcedure

&AtClient
Procedure OptionStructure_MoveDownAndRight(Command)
	If Not Items.OptionStructure_MoveDownAndRight.Enabled Then
		Return;
	EndIf;
	TableRowDown = Items.OptionStructure.CurrentData;
	If TableRowDown = Undefined Then
		Return;
	EndIf;
	ExecutionParameters = New Structure;
	ExecutionParameters.Insert("Mode",              "DownAndRight");
	ExecutionParameters.Insert("TableRowUp", Undefined);
	ExecutionParameters.Insert("TableRowDown",  TableRowDown);
	
	SubordinateRows = TableRowDown.GetItems();
	Count = SubordinateRows.Count();
	If Count = 0 Then
		Return;
	ElsIf Count = 1 Then
		ExecutionParameters.TableRowUp = SubordinateRows[0];
		OptionStructure_Move(-1, ExecutionParameters);
	Else
		List = New ValueList;
		For RowNumber = 1 To Count Do
			SubordinateRow = SubordinateRows[RowNumber-1];
			List.Add(SubordinateRow.GetID(), SubordinateRow.Presentation);
		EndDo;
		Handler = New NotifyDescription("OptionStructure_Move", ThisObject, ExecutionParameters);
		ShowChooseFromMenu(Handler, List);
	EndIf;
	
EndProcedure

&AtClient
Procedure OptionStructure_Move(Result, ExecutionParameters) Export
	If Result <> -1 Then
		If TypeOf(Result) <> Type("ValueListItem") Then
			Return;
		EndIf;
		TableRowUp = OptionStructure.FindByID(Result.Value);
	Else
		TableRowUp = ExecutionParameters.TableRowUp;
	EndIf;
	TableRowDown = ExecutionParameters.TableRowDown;
	
	// 0. Remember, before which item to insert the top row.
	RowsDown = TableRowDown.GetItems();
	Index = RowsDown.IndexOf(TableRowUp);
	RowsIDsArrayDown = New Array;
	For Each TableRow In RowsDown Do
		If TableRow = TableRowUp Then
			Continue;
		EndIf;
		RowsIDsArrayDown.Add(TableRow.GetID());
	EndDo;
	
	// 1. Move the bottom row to the level of the top one.
	Result = MoveOptionStructureItems(TableRowUp, TableRowDown.GetParent(), TableRowDown);
	TableRowUp = Result.Row;
	
	// 2. Remember, which rows are to be moved.
	RowsUp = TableRowUp.GetItems();
	
	// 3. Exchanging rows.
	For Each TableRow In RowsUp Do
		MoveOptionStructureItems(TableRow, TableRowDown);
	EndDo;
	For Each TableRowID In RowsIDsArrayDown Do
		TableRow = OptionStructure.FindByID(TableRowID);
		MoveOptionStructureItems(TableRow, TableRowUp);
	EndDo;
	
	// 4. Move the top row to the bottom one.
	RowsUp = TableRowUp.GetItems();
	If RowsUp.Count() - 1 < Index Then
		BeforeWhatToInsert = Undefined;
	Else
		BeforeWhatToInsert = RowsUp[Index];
	EndIf;
	Result = MoveOptionStructureItems(TableRowDown, TableRowUp, BeforeWhatToInsert);
	TableRowDown = Result.Row;
	
	// Bells and whistles.
	If ExecutionParameters.Mode = "DownAndRight" Then
		CurrentRow = TableRowDown;
	Else
		CurrentRow = TableRowUp;
	EndIf;
	IDCurrentRow = CurrentRow.GetID();
	Items.OptionStructure.Expand(IDCurrentRow, True);
	Items.OptionStructure.CurrentRow = IDCurrentRow;
	
	UserSettingsModified = True;
	If ExtendedMode = 1 Then
		OptionChanged = True;
	EndIf;
EndProcedure

&AtClient
Procedure OptionStructure_SaveToFile(Command)
	Address = SettingsAddressInXMLString();
	GetFile(Address, NStr("ru = 'Настройки.xml'; en = 'Settings.xml'; pl = 'Ustawienia.xml';de = 'Einstellungen.xml';ro = 'Setările.xml';tr = 'Ayarlar.xml'; es_ES = 'Ajustes.xml'"), True);
EndProcedure

&AtServer
Function SettingsAddressInXMLString()
	Return PutToTempStorage(
		Common.ValueToXMLString(Report.SettingsComposer.Settings),
		UUID);
EndFunction

#EndRegion

#Region GroupContentFormTableItemsEventHandlers

&AtClient
Procedure GroupContentUsageOnChange(Item)
	ChangeSettingItemUsage("GroupComposition");
EndProcedure

&AtClient
Procedure GroupContentChoice(Item, RowID, Field, StandardProcessing)
	StandardProcessing = False;
	
	Row = Items.GroupComposition.CurrentData;
	If Row = Undefined Then
		Return;
	EndIf;
	
	If Field = Items.GroupContentField Then
		If TypeOf(Row.Field) = Type("DataCompositionField") Then 
			GroupContentSelectField(RowID, Row);
		EndIf;
	ElsIf Field = Items.GroupContentGroupType
		Or Field = Items.GroupContentAdditionType Then
		StandardProcessing = True;
	EndIf;
EndProcedure

&AtClient
Procedure GroupContentBeforeAdd(Item, Cancel, Clone, Parent, Folder, Parameter)
	Cancel = True;
	SelectField("GroupComposition", New NotifyDescription("GroupCompositionAfterFieldChoice", ThisObject));
EndProcedure

&AtClient
Procedure GroupContentBeforeRemove(Item, Cancel)
	DeleteRows(Item, Cancel);
EndProcedure

&AtClient
Procedure GroupContentGroupTypeOnChange(Item)
	Row = Items.GroupComposition.CurrentData;
	If Row = Undefined Then
		Return;
	EndIf;
	
	StructureItemProperty = SettingsStructureItemProperty(
		Report.SettingsComposer, "GroupFields", SettingsStructureItemID);
	
	SettingItem = SettingItem(StructureItemProperty, Row);
	SettingItem.GroupType = Row.GroupType;
	
	DetermineIfModified();
EndProcedure

&AtClient
Procedure GroupContentAdditionTypeOnChange(Item)
	Row = Items.GroupComposition.CurrentData;
	If Row = Undefined Then
		Return;
	EndIf;
	
	StructureItemProperty = SettingsStructureItemProperty(
		Report.SettingsComposer, "GroupFields", SettingsStructureItemID);
	
	SettingItem = SettingItem(StructureItemProperty, Row);
	SettingItem.AdditionType = Row.AdditionType;
	
	DetermineIfModified();
EndProcedure

&AtClient
Procedure GroupContent_MoveUp(Command)
	ShiftGroupField();
EndProcedure

&AtClient
Procedure GroupContent_MoveDown(Command)
	ShiftGroupField(False);
EndProcedure

#EndRegion

#Region AppearanceFormTableItemsEventHandlers

&AtClient
Procedure AppearanceBeforeAdd(Item, Cancel, Clone, Parent, Folder, Parameter)
	Cancel = True;
	
	Row = DefaultRootRow("Appearance");
	If Row <> Undefined Then 
		Items.Appearance.CurrentRow = Row.GetID();
	EndIf;
	
	AppearanceChangeItem();
EndProcedure

&AtClient
Procedure AppearanceChoice(Item, RowID, Field, StandardProcessing)
	StandardProcessing = False;
	
	Row = Items.Appearance.CurrentData;
	If Row = Undefined Or Row.IsSection Then 
		Return;
	EndIf;
	
	If Row.IsOutputParameter Then 
		If String(Row.ID) = "TITLE"
			AND Field = Items.AppearanceTitle Then 
			
			Handler = New NotifyDescription("AppearanceTitleInputCompletion", ThisObject, RowID);
			ShowInputString(Handler, Row.Value, "Title",, True);
		EndIf;
	ElsIf Field = Items.AppearanceTitle Then // Changing order.
		AppearanceChangeItem(RowID, Row);
	ElsIf Field = Items.AppearanceAccessPictureIndex Then // Changing quick access to the filter.
		StructureItemProperty = SettingsStructureItemProperty(
			Report.SettingsComposer, "ConditionalAppearance", SettingsStructureItemID);
		SelectDisplayMode(StructureItemProperty, "Appearance", RowID, True, False);
	EndIf;
EndProcedure

&AtClient
Procedure AppearanceBeforeRemove(Item, Cancel)
	DeleteRows(Item, Cancel);
EndProcedure

&AtClient
Procedure AppearanceUsageOnChange(Item)
	ChangeSettingItemUsage("Appearance");
EndProcedure

&AtClient
Procedure Appearance_MoveUp(Command)
	ShiftAppearance();
EndProcedure

&AtClient
Procedure Appearance_MoveDown(Command)
	ShiftAppearance(False);
EndProcedure

&AtClient
Procedure Appearance_SelectCheckBoxes(Command)
	ChangePredefinedOutputParametersUsage();
	ChangeUsage("Appearance");
EndProcedure

&AtClient
Procedure Appearance_ClearCheckBoxes(Command)
	ChangePredefinedOutputParametersUsage(False);
	ChangeUsage("Appearance", False);
EndProcedure

&AtClient
Procedure CustomizeHeadersFooters(Command)
	Var Settings;
	
	Report.SettingsComposer.Settings.AdditionalProperties.Property("HeaderOrFooterSettings", Settings);
	
	OpenForm("CommonForm.HeaderAndFooterSettings",
		New Structure("Settings", Settings),
		ThisObject,
		UUID,,,
		New NotifyDescription("RememberHeaderFooterSettings", ThisObject),
		FormWindowOpeningMode.LockOwnerWindow);
EndProcedure

#EndRegion

#Region FormCommandHandlers

&AtClient
Procedure GenerateAndClose(Command)
	WriteAndClose(True);
EndProcedure

&AtClient
Procedure DontGenerateAndClose(Command)
	WriteAndClose(False);
EndProcedure

&AtClient
Procedure EditFiltersConditions(Command)
	FormParameters = New Structure;
	FormParameters.Insert("OwnerFormType", ReportFormType);
	FormParameters.Insert("ReportSettings", ReportSettings);
	FormParameters.Insert("SettingsComposer", Report.SettingsComposer);
	Handler = New NotifyDescription("EditFilterCriteriaCompletion", ThisObject);
	OpenForm("SettingsStorage.ReportsVariantsStorage.Form.ReportFiltersConditions", FormParameters, ThisObject, True,,, Handler);
EndProcedure

&AtClient
Procedure EditFilterCriteriaCompletion(FiltersConditions, Context) Export
	If FiltersConditions = Undefined
		Or FiltersConditions = DialogReturnCode.Cancel
		Or FiltersConditions.Count() = 0 Then
		Return;
	EndIf;
	
	UpdateParameters = New Structure;
	UpdateParameters.Insert("EventName", "EditFilterCriteria");
	UpdateParameters.Insert("DCSettingsComposer", Report.SettingsComposer);
	UpdateParameters.Insert("UserSettingsModified", True);
	UpdateParameters.Insert("FiltersConditions", FiltersConditions);
	
	UpdateForm(UpdateParameters);
EndProcedure

&AtClient
Procedure RemoveNonexistentFieldsFromSettings(Command)
	DeleteFiedsMarkedForDeletion();
	
	UpdateParameters = New Structure;
	UpdateParameters.Insert("DCSettingsComposer", Report.SettingsComposer);
	
	UpdateForm(UpdateParameters);
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Attachable commands

&AtClient
Procedure Attachable_SelectPeriod(Command)
	ReportsClient.SelectPeriod(ThisObject, Command.Name);
EndProcedure

&AtClient
Procedure Attachable_List_Pick(Command)
	ListPath = StrReplace(Command.Name, "Select", "");
	
	FillingParameters = ListFillingParameters();
	FillingParameters.ListPath = ListPath;
	FillingParameters.IndexOf = PathToItemsData.ByName[ListPath];
	FillingParameters.Owner = Items[ListPath];
	
	StartListFilling(Items[Command.Name], FillingParameters);
EndProcedure

&AtClient
Procedure Attachable_List_PasteFromClipboard(Command)
	ListPath = StrReplace(Command.Name, "PasteFromClipboard", "");
	
	List = ThisObject[ListPath];
	ListField = Items[ListPath];
	
	Index = PathToItemsData.ByName[ListPath];
	Info = ReportsClient.SettingItemInfo(Report.SettingsComposer, Index);
	UserSettings = Report.SettingsComposer.UserSettings.Items;
	
	ChoiceParameters = ReportsClientServer.ChoiceParameters(Info.Settings, UserSettings, Info.Item);
	List.ValueType = ReportsClient.ValueTypeRestrictedByLinkByType(
		Info.Settings, UserSettings, Info.Item, Info.Details);
	
	SearchParameters = New Structure;
	SearchParameters.Insert("TypeDescription", TypesDetailsWithoutPrimitiveOnes(List.ValueType));
	SearchParameters.Insert("FieldPresentation", ListField.Title);
	SearchParameters.Insert("Scenario", "PastingFromClipboard");
	SearchParameters.Insert("ChoiceParameters", ChoiceParameters);
	
	Handler = New NotifyDescription("PasteFromClipboardCompletion", ThisObject, ListPath);
	
	ModuleDataImportFromFileClient = CommonClient.CommonModule("ImportDataFromFileClient");
	ModuleDataImportFromFileClient.ShowRefFillingForm(SearchParameters, Handler);
EndProcedure

#EndRegion

#Region Private

#Region GroupFields

// Reading settings.

&AtServer
Procedure UpdateGroupFields()
	StructureItemProperty = SettingsStructureItemProperty(
		Report.SettingsComposer, "GroupFields", SettingsStructureItemID);
	
	If StructureItemProperty = Undefined Then 
		Return;
	EndIf;
	
	For Each SettingItem In StructureItemProperty.Items Do 
		Row = GroupComposition.GetItems().Add();
		FillPropertyValues(Row, SettingItem);
		Row.ID = StructureItemProperty.GetIDByObject(SettingItem);
		
		If TypeOf(SettingItem) = Type("DataCompositionAutoGroupField") Then 
			Row.Title  = NStr("ru = 'Авто (по всем полям)'; en = 'Auto (all fields)'; pl = 'Auto (dla wszystkich pól)';de = 'Automatisch (alle Felder)';ro = 'Auto (pe toate câmpurile)';tr = 'Oto (tüm alanlarda)'; es_ES = 'Auto (por todos los campos)'");
			Row.Picture = ReportsClientServer.PictureIndex("Item", "Predefined");
			Continue;
		EndIf;
		
		SettingDetails = StructureItemProperty.GroupFieldsAvailableFields.FindField(SettingItem.Field);
		If SettingDetails = Undefined Then 
			SetDeletionMark("GroupComposition", Row);
			Continue;
		EndIf;
		
		FillPropertyValues(Row, SettingDetails);
		Row.ShowAdditionType = SettingDetails.ValueType.ContainsType(Type("Date"));
		
		If SettingDetails.Resource Then
			Row.Picture = ReportsClientServer.PictureIndex("Resource");
		ElsIf SettingDetails.Table Then
			Row.Picture = ReportsClientServer.PictureIndex("Table");
		ElsIf SettingDetails.Folder Then
			Row.Picture = ReportsClientServer.PictureIndex("Group");
		Else
			Row.Picture = ReportsClientServer.PictureIndex("Item");
		EndIf;
	EndDo;
EndProcedure

// Adding and changing items.

&AtClient
Procedure GroupContentSelectField(RowID, Row)
	StructureItemProperty = SettingsStructureItemProperty(
		Report.SettingsComposer, "GroupFields", SettingsStructureItemID);
	SettingItem = SettingItem(StructureItemProperty, Row);
	
	Handler = New NotifyDescription("GroupCompositionAfterFieldChoice", ThisObject, RowID);
	SelectField("GroupComposition", Handler, SettingItem.Field);
EndProcedure

&AtClient
Procedure GroupCompositionAfterFieldChoice(SettingDetails, RowID) Export
	If SettingDetails = Undefined Then
		Return;
	EndIf;
	
	StructureItemProperty = SettingsStructureItemProperty(
		Report.SettingsComposer, "GroupFields", SettingsStructureItemID);
	
	If RowID = Undefined Then 
		Row = GroupComposition.GetItems().Add();
		SettingItem = StructureItemProperty.Items.Add(Type("DataCompositionGroupField"));
	Else
		Row = GroupComposition.FindByID(RowID);
		SettingItem = SettingItem(StructureItemProperty, Row);
	EndIf;
	
	SettingItem.Use = True;
	SettingItem.Field = SettingDetails.Field;
	
	FillPropertyValues(Row, SettingItem);
	Row.ID = StructureItemProperty.GetIDByObject(SettingItem);
	
	FillPropertyValues(Row, SettingDetails);
	
	Row.ShowAdditionType = SettingDetails.ValueType.ContainsType(Type("Date"));
	
	If SettingDetails.Resource Then
		Row.Picture = ReportsClientServer.PictureIndex("Resource");
	ElsIf SettingDetails.Table Then
		Row.Picture = ReportsClientServer.PictureIndex("Table");
	ElsIf SettingDetails.Folder Then
		Row.Picture = ReportsClientServer.PictureIndex("Group");
	Else
		Row.Picture = ReportsClientServer.PictureIndex("Item");
	EndIf;
	
	ChangeUsageOfLinkedSettingsItems("GroupComposition", Row, SettingItem);
	
	Items.GroupComposition.CurrentRow = Row.GetID();
	
	DetermineIfModified();
EndProcedure

// Shifting items.

&AtClient
Procedure ShiftGroupField(ToBeginning = True)
	RowsIDs = Items.GroupComposition.SelectedRows;
	If RowsIDs.Count() = 0 Then 
		Return;
	EndIf;
	
	StructureItemProperty = SettingsStructureItemProperty(
		Report.SettingsComposer, "GroupFields", SettingsStructureItemID);
	
	For Each RowID In RowsIDs Do 
		Row = GroupComposition.FindByID(RowID);
		SettingItem = SettingItem(StructureItemProperty, Row);
		
		SettingsItems = StructureItemProperty.Items;
		Rows = GroupComposition.GetItems();
		
		Index = SettingsItems.IndexOf(SettingItem);
		Border = SettingsItems.Count() - 1;
		
		If ToBeginning Then // Moving to the collection beginning.
			If Index = 0 Then 
				SettingsItems.Move(SettingItem, Border);
				Rows.Move(Index, Border);
			Else
				SettingsItems.Move(SettingItem, -1);
				Rows.Move(Index, -1);
			EndIf;
		Else // Shifting to the collection end.
			If Index = Border Then 
				SettingsItems.Move(SettingItem, -Border);
				Rows.Move(Index, -Border);
			Else
				SettingsItems.Move(SettingItem, 1);
				Rows.Move(Index, 1);
			EndIf;
		EndIf;
	EndDo;
	
	DetermineIfModified();
EndProcedure

#EndRegion

#Region DataParametersAndFilters

// Reading settings.

&AtServer
Procedure UpdateDataParameters()
	If ExtendedMode = 0
		Or SettingsStructureItemChangeMode Then 
		Return;
	EndIf;
	
	StructureItemProperty = SettingsStructureItemProperty(
		Report.SettingsComposer, "DataParameters", SettingsStructureItemID);
	
	Section = Filters.GetItems().Add();
	Section.IsSection = True;
	Section.Title = NStr("ru = 'Параметры'; en = 'Parameters'; pl = 'Parametry';de = 'Parameter';ro = 'Parametrii ';tr = 'Parametreler'; es_ES = 'Parámetros'");
	Section.Picture = ReportsClientServer.PictureIndex("DataParameters");
	Section.ID = "DataParameters";
	SectionItems = Section.GetItems();
	
	If StructureItemProperty = Undefined
		Or StructureItemProperty.Items.Count() = 0 Then 
		Return;
	EndIf;
	
	Schema = GetFromTempStorage(ReportSettings.SchemaURL);
	
	For Each SettingItem In StructureItemProperty.Items Do 
		FoundParameter = Schema.Parameters.Find(SettingItem.Parameter);
		If FoundParameter <> Undefined AND FoundParameter.UseRestriction Then 
			Continue;
		EndIf;
		
		Row = SectionItems.Add();
		FillPropertyValues(Row, SettingItem);
		Row.ID = StructureItemProperty.GetIDByObject(SettingItem);
		Row.DisplayModePicture = SettingItemDisplayModePicture(SettingItem);
		Row.Picture = -1;
		Row.IsParameter = True;
		Row.IsPeriod = (TypeOf(Row.Value) = Type("StandardPeriod"));
		
		SettingDetails = StructureItemProperty.AvailableParameters.FindParameter(SettingItem.Parameter);
		If SettingDetails <> Undefined Then 
			FillPropertyValues(Row, SettingDetails,, "Use");
			Row.DisplayUsage = (SettingDetails.Use <> DataCompositionParameterUse.Always);
			
			If SettingDetails.AvailableValues <> Undefined Then 
				ListItem = SettingDetails.AvailableValues.FindByValue(SettingItem.Value);
				If ListItem <> Undefined Then 
					Row.ValuePresentation = ListItem.Presentation;
				EndIf;
			EndIf;
		EndIf;
		
		If Not ValueIsFilled(Row.UserSettingPresentation) Then 
			Row.UserSettingPresentation = Row.Title;
		EndIf;
		Row.IsPredefinedTitle = (Row.Title = Row.UserSettingPresentation);
	EndDo;
EndProcedure

&AtServer
Procedure UpdateFilters(Rows = Undefined, SettingsItems = Undefined)
	If ExtendedMode = 0 Then 
		Return;
	EndIf;
	
	StructureItemProperty = SettingsStructureItemProperty(
		Report.SettingsComposer, "Filter", SettingsStructureItemID);
	
	If StructureItemProperty = Undefined Then 
		Return;
	EndIf;
	
	If Rows = Undefined Then 
		Section = Filters.GetItems().Add();
		Section.IsSection = True;
		Section.Title = NStr("ru = 'Отборы'; en = 'Filters'; pl = 'Filtry';de = 'Filter';ro = 'Filtre';tr = 'Filtreler'; es_ES = 'Filtros'");
		Section.Picture = ReportsClientServer.PictureIndex("Filters");
		Section.ID = "Filters";
		Rows = Section.GetItems();
	EndIf;
	
	StructureItemProperty = SettingsStructureItemProperty(
		Report.SettingsComposer, "Filter", SettingsStructureItemID);
	
	If SettingsItems = Undefined Then 
		SettingsItems = StructureItemProperty.Items;
	EndIf;
	
	For Each SettingItem In SettingsItems Do 
		Row = Rows.Add();
		
		If Not SetFiltersRowData(Row, StructureItemProperty, SettingItem) Then 
			SetDeletionMark("Filters", Row);
		EndIf;
		
		If TypeOf(SettingItem) = Type("DataCompositionFilterItemGroup") Then 
			UpdateFilters(Row.GetItems(), SettingItem.Items);
		EndIf;
	EndDo;
EndProcedure

&AtClientAtServerNoContext
Function SetFiltersRowData(Row, StructureItemProperty, SettingItem, SettingDetails = Undefined)
	InstalledSuccessfully = True;
	
	IsGroup = (TypeOf(SettingItem) = Type("DataCompositionFilterItemGroup"));
	
	If SettingDetails = Undefined Then 
		If Not IsGroup Then 
			SettingDetails = StructureItemProperty.FilterAvailableFields.FindField(SettingItem.LeftValue);
			InstalledSuccessfully = (SettingDetails <> Undefined);
		EndIf;
		
		If SettingDetails = Undefined Then 
			SettingDetails = New Structure("AvailableValues, AvailableCompareTypes");
			SettingDetails.Insert("ValueType", New TypeDescription("Undefined"));
		EndIf;
	EndIf;
	
	AvailableCompareTypes = SettingDetails.AvailableCompareTypes;
	If AvailableCompareTypes <> Undefined
		AND AvailableCompareTypes.Count() > 0
		AND AvailableCompareTypes.FindByValue(SettingItem.ComparisonType) = Undefined Then 
		SettingItem.ComparisonType = AvailableCompareTypes[0].Value;
	EndIf;
	
	FillPropertyValues(Row, SettingDetails);
	FillPropertyValues(Row, SettingItem);
	
	Row.ID = StructureItemProperty.GetIDByObject(SettingItem);
	Row.DisplayUsage = True;
	Row.IsPeriod = (TypeOf(Row.RightValue) = Type("StandardPeriod"));
	Row.IsUUID = (TypeOf(Row.RightValue) = Type("UUID"));
	
	Row.IsFolder = IsGroup;
	Row.DisplayModePicture = SettingItemDisplayModePicture(SettingItem);
	Row.Picture = -1;
	
	If IsGroup Then 
		Row.Title = Row.GroupType;
	Else
		ReportsClientServer.CastValueToType(SettingItem.RightValue, SettingDetails.ValueType);
	EndIf;
	
	If Not ValueIsFilled(Row.UserSettingPresentation) Then 
		If ValueIsFilled(SettingItem.Presentation) Then 
			Row.UserSettingPresentation = SettingItem.Presentation;
		Else
			Row.UserSettingPresentation = Row.Title;
		EndIf;
	EndIf;
	Row.IsPredefinedTitle = (Row.Title = Row.UserSettingPresentation);
	
	CastValueToComparisonKind(Row, SettingItem);
	SetValuePresentation(Row);
	
	Return InstalledSuccessfully;
EndFunction

// Adding and changing items.

&AtClient
Procedure FiltersSelectGroup(RowID)
	Handler = New NotifyDescription("FiltersAfterGroupChoice", ThisObject, RowID);
	
	List = New ValueList;
	List.Add(DataCompositionFilterItemsGroupType.AndGroup);
	List.Add(DataCompositionFilterItemsGroupType.OrGroup);
	List.Add(DataCompositionFilterItemsGroupType.NotGroup);
	
	ShowChooseFromMenu(Handler, List);
EndProcedure

&AtClient
Procedure FiltersAfterGroupChoice(GroupType, RowID) Export
	If GroupType = Undefined Then
		Return;
	EndIf;
	
	Row = Filters.FindByID(RowID);
	Row.GroupType = GroupType.Value;
	Row.Title = Row.GroupType;
	Row.UserSettingPresentation = Row.GroupType;
	
	StructureItemProperty = SettingsStructureItemProperty(
		Report.SettingsComposer, "Filter", SettingsStructureItemID);
	
	SettingItem = SettingItem(StructureItemProperty, Row);
	SettingItem.GroupType = GroupType.Value;
	
	DetermineIfModified();
EndProcedure

&AtClient
Procedure FiltersSelectField(RowID, Row)
	StructureItemProperty = SettingsStructureItemProperty(
		Report.SettingsComposer, "Filter", SettingsStructureItemID);
	
	SettingItem = SettingItem(StructureItemProperty, Row);
	
	Handler = New NotifyDescription("FiltersAfterFieldChoice", ThisObject, RowID);
	SelectField("Filters", Handler, SettingItem.LeftValue);
EndProcedure

&AtClient
Procedure FiltersAfterFieldChoice(SettingDetails, RowID) Export
	If SettingDetails = Undefined Then
		Return;
	EndIf;
	
	StructureItemProperty = SettingsStructureItemProperty(
		Report.SettingsComposer, "Filter", SettingsStructureItemID);
	
	If RowID = Undefined Then 
		Parent = Items.Filters.CurrentData;
		If Not Parent.IsSection AND Not Parent.IsFolder Then 
			Parent = Parent.GetParent();
		EndIf;
		Row = Parent.GetItems().Add();
		
		SettingItemParent = StructureItemProperty;
		If TypeOf(Parent.ID) = Type("DataCompositionID") Then 
			SettingItemParent = StructureItemProperty.GetObjectByID(Parent.ID);
		EndIf;
		SettingItem = SettingItemParent.Items.Add(Type("DataCompositionFilterItem"));
	Else
		Row = Filters.FindByID(RowID);
		SettingItem = SettingItem(StructureItemProperty, Row);
	EndIf;
	
	SettingItem.Use = True;
	SettingItem.LeftValue = SettingDetails.Field;
	SettingItem.RightValue = SettingDetails.Type.AdjustValue();
	SettingItem.ViewMode = DataCompositionSettingsItemViewMode.Normal;
	SettingItem.UserSettingID = New UUID;
	SettingItem.UserSettingPresentation = "";
	
	AvailableCompareTypes = SettingDetails.AvailableCompareTypes;
	If AvailableCompareTypes <> Undefined
		AND AvailableCompareTypes.Count() > 0
		AND AvailableCompareTypes.FindByValue(SettingItem.ComparisonType) = Undefined Then 
		SettingItem.ComparisonType = AvailableCompareTypes[0].Value;
	EndIf;
	
	SetFiltersRowData(Row, StructureItemProperty, SettingItem, SettingDetails);
	
	Section = DefaultRootRow("Filters");
	Items.Filters.Expand(Section.GetID(), True);
	
	DetermineIfModified();
EndProcedure

&AtClient
Procedure FiltersOnChangeCurrentRow()
	Row = Items.Filters.CurrentData;
	If Row = Undefined Then
		FiltersOnChangeCurrentRowAtServer();
		Return;
	EndIf;
	
	FiltersOnChangeCurrentRowAtServer(Not Row.IsParameter AND Not Row.IsSection, Row.IsSection);
	
	If Row.IsSection Or Row.IsFolder Then
		Return;
	EndIf;
	
	Items.FiltersComparisonType.ListChoiceMode = (Row.AvailableCompareTypes <> Undefined);
	If Row.AvailableCompareTypes <> Undefined Then 
		List = Items.FiltersComparisonType.ChoiceList;
		List.Clear();
		
		For Each ComparisonKinds In Row.AvailableCompareTypes Do 
			FillPropertyValues(List.Add(), ComparisonKinds);
		EndDo;
	EndIf;
	
	If Row.IsParameter Then 
		Condition = DataCompositionComparisonType.Equal;
		If Row.ValueListAllowed Then 
			Condition = DataCompositionComparisonType.InList;
		EndIf;
	Else
		Condition = Row.ComparisonType;
	EndIf;
	
	ValueField = ?(Row.IsParameter, Items.FiltersValue, Items.FiltersRightValue);
	ValueField.AvailableTypes = Row.ValueType;
	ValueField.ChoiceFoldersAndItems = ReportsClientServer.GroupsAndItemsTypeValue(Row.ChoiceFoldersAndItems, Condition);
	
	List = ValueField.ChoiceList;
	List.Clear();
	If Row.AvailableValues <> Undefined Then 
		For Each AvailableValue In Row.AvailableValues Do 
			FillPropertyValues(List.Add(), AvailableValue);
		EndDo;
	EndIf;
EndProcedure

&AtServer
Procedure FiltersOnChangeCurrentRowAtServer(IsFilter = False, IsSection = False)
	Items.Filters_Delete.Enabled = IsFilter;
	Items.Filters_Delete1.Enabled = IsFilter;
	Items.Filters_Group.Enabled = IsFilter;
	Items.Filters_Group1.Enabled = IsFilter;
	Items.Filters_Ungroup.Enabled = IsFilter;
	Items.Filters_Ungroup1.Enabled = IsFilter;
	Items.Filters_MoveUp.Enabled = IsFilter;
	Items.Filters_MoveUp1.Enabled = IsFilter;
	Items.Filters_MoveDown.Enabled = IsFilter;
	Items.Filters_MoveDown1.Enabled = IsFilter;
	
	Items.FiltersCommands_Show.Enabled = Not IsSection;
	Items.FiltersCommands_Show1.Enabled = Not IsSection;
	Items.Filters_ShowOnlyCheckBoxInReportHeader.Enabled = IsFilter;
	Items.Filters_ShowOnlyCheckBoxInReportHeader1.Enabled = IsFilter;
	Items.Filters_ShowOnlyCheckBoxInReportSettings.Enabled = IsFilter;
	Items.Filters_ShowOnlyCheckBoxInReportSettings1.Enabled = IsFilter;
EndProcedure

&AtClient
Procedure FiltersSetDisplayMode(DisplayMode)
	Row = Items.Filters.CurrentData;
	If Row = Undefined Then
		Return;
	EndIf;
	
	If Row.IsParameter Then 
		StructureItemProperty = SettingsStructureItemProperty(Report.SettingsComposer, "DataParameters");
	Else
		StructureItemProperty = SettingsStructureItemProperty(
			Report.SettingsComposer, "Filter", SettingsStructureItemID);
	EndIf;
	
	SelectDisplayMode(StructureItemProperty, "Filters", Row.GetID(), True, Row.IsParameter, DisplayMode);
EndProcedure

// Changing grouping of items.

&AtClient
Function FiltersGroupingParameters()
	Rows = New Array;
	Parents = New Array;
	
	RowsIDs = Items.Filters.SelectedRows;
	For Each RowID In RowsIDs Do 
		Row = Filters.FindByID(RowID);
		Parent = Row.GetParent();
		
		If Parent.GetItems().IndexOf(Row) < 0
			Or TypeOf(Row.ID) <> Type("DataCompositionID") Then 
			Continue;
		EndIf;
		
		Rows.Add(Row);
		Parents.Add(Parent);
	EndDo;
	
	If Rows.Count() = 0 Then 
		ShowMessageBox(, NStr("ru = 'Выберите элементы.'; en = 'Select items.'; pl = 'Wybrane elementy.';de = 'Wählen Sie Elemente.';ro = 'Selectați elementele.';tr = 'Öğeleri seçin.'; es_ES = 'Seleccionar los artículos.'"));
		Return Undefined;
	EndIf;
	
	Parents = CommonClientServer.CollapseArray(Parents);
	If Parents.Count() > 1 Then 
		ShowMessageBox(, NStr("ru = 'Выбранные элементы не могут быть сгруппированы, поскольку они принадлежат разным родителям.'; en = 'Cannot group selected items as they have different parents.'; pl = 'Nie można zgrupować wybranych dokumentów, ponieważ mają one różnych ""rodziców"".';de = 'Die ausgewählten Elemente können nicht gruppiert werden, da sie unterschiedliche Übergeordnete haben.';ro = 'Elementele selectate nu pot fi grupate deoarece au părinți diferiți.';tr = 'Seçilen öğeler farklı üst öğeleri olduğu için aktarılamaz.'; es_ES = 'Los artículos seleccionados no pueden agruparse porque tienen diferentes padres.'"));
		Return Undefined;
	EndIf;
	
	Rows = ArraySort(Rows);
	Parent = Parents[0];
	Index = Parent.GetItems().IndexOf(Rows[0]);
	
	Return New Structure("Rows, Parent, IndexOf", Rows, Parent, Index);
EndFunction

&AtClient
Procedure ChangeFiltersGrouping(SettingsNodeFilters, Rows, SettingsItemsInheritors, RowsInheritors)
	For Each SourceRow In Rows Do 
		SettingItemSource = SettingsNodeFilters.GetObjectByID(SourceRow.ID);
		
		If SettingItemSource.Parent = Undefined Then 
			SourceSettingItemParent = SettingsNodeFilters;
		Else
			SourceSettingItemParent = SettingItemSource.Parent;
		EndIf;
		DestinationSettingItemParent = SettingsItemsInheritors.Get(SourceSettingItemParent);
		
		SourceRowParent = SourceRow.GetParent();
		DestinationRowParent = RowsInheritors.Get(SourceRowParent);
		
		Index = DestinationSettingItemParent.Items.IndexOf(SourceSettingItemParent);
		If Index < 0 Then 
			SettingItemDestination = DestinationSettingItemParent.Items.Add(TypeOf(SettingItemSource));
			DestinationRow = DestinationRowParent.GetItems().Add();
		Else // This is grouping deletion.
			SettingItemDestination = DestinationSettingItemParent.Items.Insert(Index, TypeOf(SettingItemSource));
			DestinationRow = DestinationRowParent.GetItems().Insert(Index);
		EndIf;
		
		FillPropertyValues(SettingItemDestination, SettingItemSource);
		FillPropertyValues(DestinationRow, SourceRow);
		DestinationRow.ID = SettingsNodeFilters.GetIDByObject(SettingItemDestination);
		
		SettingsItemsInheritors.Insert(SettingItemSource, SettingItemDestination);
		RowsInheritors.Insert(SourceRow, DestinationRow);
		
		ChangeFiltersGrouping(SettingsNodeFilters, SourceRow.GetItems(), SettingsItemsInheritors, RowsInheritors);
	EndDo;
EndProcedure

&AtClient
Procedure DeleteBasicFiltersGroupingItems(SettingsNodeFilters, GroupingParameters)
	Rows = GroupingParameters.Parent.GetItems();
	
	SettingsItems = SettingsNodeFilters.Items;
	If TypeOf(GroupingParameters.Parent.ID) = Type("DataCompositionID") Then 
		SettingsItems = SettingsNodeFilters.GetObjectByID(GroupingParameters.Parent.ID).Items;
	EndIf;
	
	Index = GroupingParameters.Rows.UBound();
	While Index >= 0 Do 
		Row = GroupingParameters.Rows[Index];
		SettingItem = SettingsNodeFilters.GetObjectByID(Row.ID);
		
		Rows.Delete(Row);
		SettingsItems.Delete(SettingItem);
		
		Index = Index - 1;
	EndDo;
EndProcedure

// Shifting items.

&AtClient
Procedure ShiftFilters(ToBeginning = True)
	ShiftParameters = FiltersShiftParameters();
	If ShiftParameters = Undefined Then 
		Return;
	EndIf;
	
	StructureItemProperty = SettingsStructureItemProperty(
		Report.SettingsComposer, "Filter", SettingsStructureItemID);
	
	For Each Row In ShiftParameters.Rows Do 
		SettingItem = SettingItem(StructureItemProperty, Row);
		
		SettingsItems = StructureItemProperty.Items;
		If SettingItem.Parent <> Undefined Then 
			SettingsItems = SettingItem.Parent.Items;
		EndIf;
		Rows = ShiftParameters.Parent.GetItems();
		
		Index = SettingsItems.IndexOf(SettingItem);
		Border = SettingsItems.Count() - 1;
		
		If ToBeginning Then // Shifting to the collection beginning.
			If Index = 0 Then 
				SettingsItems.Move(SettingItem, Border);
				Rows.Move(Index, Border);
			Else
				SettingsItems.Move(SettingItem, -1);
				Rows.Move(Index, -1);
			EndIf;
		Else // Shifting to the collection end.
			If Index = Border Then 
				SettingsItems.Move(SettingItem, -Border);
				Rows.Move(Index, -Border);
			Else
				SettingsItems.Move(SettingItem, 1);
				Rows.Move(Index, 1);
			EndIf;
		EndIf;
	EndDo;
	
	DetermineIfModified();
EndProcedure

&AtClient
Function FiltersShiftParameters()
	Rows = New Array;
	Parents = New Array;
	
	RowsIDs = Items.Filters.SelectedRows;
	For Each RowID In RowsIDs Do 
		Row = Filters.FindByID(RowID);
		Parent = Row.GetParent();
		
		If Parent.GetItems().IndexOf(Row) < 0
			Or TypeOf(Row.ID) <> Type("DataCompositionID") Then 
			Continue;
		EndIf;
		
		Rows.Add(Row);
		Parents.Add(Parent);
	EndDo;
	
	If Rows.Count() = 0 Then 
		ShowMessageBox(, NStr("ru = 'Выберите элементы.'; en = 'Select items.'; pl = 'Wybrane elementy.';de = 'Wählen Sie Elemente.';ro = 'Selectați elementele.';tr = 'Öğeleri seçin.'; es_ES = 'Seleccionar los artículos.'"));
		Return Undefined;
	EndIf;
	
	Parents = CommonClientServer.CollapseArray(Parents);
	If Parents.Count() > 1 Then 
		ShowMessageBox(, NStr("ru = 'Выбранные элементы не могут быть перемещены, поскольку они принадлежат разным родителям.'; en = 'Cannot move selected items as they have different parents.'; pl = 'Nie można przenieść wybranych dokumentów, ponieważ mają one różnych ""rodziców"".';de = 'Die ausgewählten Elemente können nicht übertragen werden, da sie unterschiedliche Übergeordnete haben.';ro = 'Elementele selectate nu pot fi transferate deoarece au părinți diferiți.';tr = 'Seçilen öğeler farklı üst öğeleri olduğu için aktarılamaz.'; es_ES = 'Los artículos seleccionados no pueden transferirse porque tienen diferentes padres.'"));
		Return Undefined;
	EndIf;
	
	Return New Structure("Rows, Parent", ArraySort(Rows), Parents[0]);
EndFunction

#EndRegion

#Region SelectedFields

// Reading settings.

&AtServer
Procedure UpdateSelectedFields(Rows = Undefined, SettingsItems = Undefined)
	StructureItemProperty = SettingsStructureItemProperty(
		Report.SettingsComposer, "Selection", SettingsStructureItemID, ExtendedMode);
	
	If StructureItemProperty = Undefined Then 
		Return;
	EndIf;
	
	If Rows = Undefined Then 
		Section = SelectedFields.GetItems().Add();
		Section.IsSection = True;
		Section.Title = NStr("ru = 'Поля'; en = 'Fields'; pl = 'Pola';de = 'Felder';ro = 'Câmpuri';tr = 'Alanlar'; es_ES = 'Campos'");
		Section.Picture = ReportsClientServer.PictureIndex("SelectedFields");
		Section.ID = "SelectedFields";
		Rows = Section.GetItems();
	EndIf;
	
	GroupPicture = ReportsClientServer.PictureIndex("Group");
	ItemPicture = ReportsClientServer.PictureIndex("Item");
	
	If SettingsItems = Undefined Then 
		SettingsItems = StructureItemProperty.Items;
	EndIf;
	
	For Each SettingItem In SettingsItems Do 
		Row = Rows.Add();
		FillPropertyValues(Row, SettingItem);
		Row.ID = StructureItemProperty.GetIDByObject(SettingItem);
		
		If TypeOf(SettingItem) = Type("DataCompositionAutoSelectedField") Then 
			Row.Title = NStr("ru = 'Авто (поля родителя)'; en = 'Auto (parent field)'; pl = 'Auto (pola rodzica)';de = 'Automatisch (übergeordnete Felder)';ro = 'Auto (câmpurile părintelui)';tr = 'Oto (ana alan)'; es_ES = 'Auto (campo de padre)'");
			Row.Picture = 6;
			Continue;
		EndIf;
		
		If TypeOf(SettingItem) = Type("DataCompositionSelectedFieldGroup") Then 
			Row.IsFolder = True;
			Row.Picture = GroupPicture;
			Row.Title = SelectedFieldsGroupTitle(SettingItem);
			
			UpdateSelectedFields(Row.GetItems(), SettingItem.Items);
		Else
			SettingDetails = StructureItemProperty.SelectionAvailableFields.FindField(SettingItem.Field);
			If SettingDetails = Undefined Then 
				SetDeletionMark("SelectedFields", Row);
			Else
				FillPropertyValues(Row, SettingDetails);
				Row.Picture = ItemPicture;
			EndIf;
		EndIf;
	EndDo;
EndProcedure

// Adding and changing items.

&AtClient
Procedure SelectedFieldsSelectGroup(RowID, Row)
	StructureItemProperty = SettingsStructureItemProperty(
		Report.SettingsComposer, "Selection", SettingsStructureItemID, ExtendedMode);
	
	SettingItem = SettingItem(StructureItemProperty, Row);
	
	FormParameters = New Structure;
	FormParameters.Insert("GroupTitle", SettingItem.Title);
	FormParameters.Insert("Placement", SettingItem.Placement);
	
	Handler = New NotifyDescription("SelectedFieldsAfterGroupChoice", ThisObject, RowID);
	
	OpenForm("SettingsStorage.ReportsVariantsStorage.Form.SelectedFieldsGroup",
		FormParameters, ThisObject, UUID,,, Handler, FormWindowOpeningMode.LockOwnerWindow);
EndProcedure

&AtClient
Procedure SelectedFieldsAfterGroupChoice(GroupProperties, RowID) Export
	If TypeOf(GroupProperties) <> Type("Structure") Then
		Return;
	EndIf;
	
	Row = SelectedFields.FindByID(RowID);
	
	StructureItemProperty = SettingsStructureItemProperty(
		Report.SettingsComposer, "Selection", SettingsStructureItemID, ExtendedMode);
	
	SettingItem = SettingItem(StructureItemProperty, Row);
	SettingItem.Title = GroupProperties.GroupTitle;
	SettingItem.Placement = GroupProperties.Placement;
	
	FillPropertyValues(Row, SettingItem);
	
	If SettingItem.Placement <> DataCompositionFieldPlacement.Auto Then 
		Row.Title = Row.Title + " (" + String(SettingItem.Placement) + ")";
	EndIf;

	DetermineIfModified();
EndProcedure

&AtClient
Procedure SelectedFieldsSelectField(RowID, Row)
	StructureItemProperty = SettingsStructureItemProperty(
		Report.SettingsComposer, "Selection", SettingsStructureItemID, ExtendedMode);
	
	SettingItem = SettingItem(StructureItemProperty, Row);
	
	Handler = New NotifyDescription("SelectedFieldsAfterFieldChoice", ThisObject, RowID);
	SelectField("SelectedFields", Handler, SettingItem.Field);
EndProcedure

&AtClient
Procedure SelectedFieldsAfterFieldChoice(SettingDetails, RowID = Undefined) Export
	If SettingDetails = Undefined Then
		Return;
	EndIf;
	
	StructureItemProperty = SettingsStructureItemProperty(
		Report.SettingsComposer, "Selection", SettingsStructureItemID, ExtendedMode);
	
	If RowID = Undefined Then 
		Parent = Items.SelectedFields.CurrentData;
		If Parent = Undefined Then 
			Parent = DefaultRootRow("SelectedFields");
		EndIf;
		
		If Not Parent.IsSection AND Not Parent.IsFolder Then 
			Parent = Parent.GetParent();
		EndIf;
		Row = Parent.GetItems().Add();
		
		SettingItemParent = StructureItemProperty;
		If TypeOf(Parent.ID) = Type("DataCompositionID") Then 
			SettingItemParent = StructureItemProperty.GetObjectByID(Parent.ID);
		EndIf;
		SettingItem = SettingItemParent.Items.Add(Type("DataCompositionSelectedField"));
	Else
		Row = SelectedFields.FindByID(RowID);
		SettingItem = SettingItem(StructureItemProperty, Row);
	EndIf;
	
	SettingItem.Use = True;
	SettingItem.Field = SettingDetails.Field;
	
	FillPropertyValues(Row, SettingItem);
	FillPropertyValues(Row, SettingDetails);
	
	Row.ID = StructureItemProperty.GetIDByObject(SettingItem);
	Row.Picture = ReportsClientServer.PictureIndex("Item");
	
	DetermineIfModified();
EndProcedure

// Changing grouping of items.

&AtClient
Function GroupingParametersOfSelectedFields()
	Rows = New Array;
	Parents = New Array;
	
	RowsIDs = Items.SelectedFields.SelectedRows;
	For Each RowID In RowsIDs Do 
		Row = SelectedFields.FindByID(RowID);
		Parent = Row.GetParent();
		
		If Parent.GetItems().IndexOf(Row) < 0
			Or TypeOf(Row.ID) <> Type("DataCompositionID") Then 
			Continue;
		EndIf;
		
		Rows.Add(Row);
		Parents.Add(Parent);
	EndDo;
	
	If Rows.Count() = 0 Then 
		ShowMessageBox(, NStr("ru = 'Выберите элементы.'; en = 'Select items.'; pl = 'Wybrane elementy.';de = 'Wählen Sie Elemente.';ro = 'Selectați elementele.';tr = 'Öğeleri seçin.'; es_ES = 'Seleccionar los artículos.'"));
		Return Undefined;
	EndIf;
	
	Parents = CommonClientServer.CollapseArray(Parents);
	If Parents.Count() > 1 Then 
		ShowMessageBox(, NStr("ru = 'Выбранные элементы не могут быть сгруппированы, поскольку они принадлежат разным родителям.'; en = 'Cannot group selected items as they have different parents.'; pl = 'Nie można zgrupować wybranych dokumentów, ponieważ mają one różnych ""rodziców"".';de = 'Die ausgewählten Elemente können nicht gruppiert werden, da sie unterschiedliche Übergeordnete haben.';ro = 'Elementele selectate nu pot fi grupate deoarece au părinți diferiți.';tr = 'Seçilen öğeler farklı üst öğeleri olduğu için aktarılamaz.'; es_ES = 'Los artículos seleccionados no pueden agruparse porque tienen diferentes padres.'"));
		Return Undefined;
	EndIf;
	
	Rows = ArraySort(Rows);
	Parent = Parents[0];
	Index = Parent.GetItems().IndexOf(Rows[0]);
	
	Return New Structure("Rows, Parent, IndexOf", Rows, Parent, Index);
EndFunction

&AtClient
Procedure SelectedFieldsBeforeGroupFields(GroupProperties, GroupingParameters) Export
	If TypeOf(GroupProperties) <> Type("Structure") Then
		Return;
	EndIf;
	
	StructureItemProperty = SettingsStructureItemProperty(
		Report.SettingsComposer, "Selection", SettingsStructureItemID, ExtendedMode);
	
	// Processing settings items.
	SettingItemSource = StructureItemProperty;
	If TypeOf(GroupingParameters.Parent.ID) = Type("DataCompositionID") Then 
		SettingItemSource = StructureItemProperty.GetObjectByID(GroupingParameters.Parent.ID);
	EndIf;
	
	SettingItemDestination = SettingItemSource.Items.Insert(GroupingParameters.IndexOf, Type("DataCompositionSelectedFieldGroup"));
	SettingItemDestination.Title = GroupProperties.GroupTitle;
	SettingItemDestination.Placement = GroupProperties.Placement;
	
	SettingsItemsInheritors = New Map;
	SettingsItemsInheritors.Insert(SettingItemSource, SettingItemDestination);
	
	// Processing rows.
	SourceRow = GroupingParameters.Parent;
	DestinationRow = SourceRow.GetItems().Insert(GroupingParameters.IndexOf);
	FillPropertyValues(DestinationRow, SettingItemDestination);
	DestinationRow.ID = StructureItemProperty.GetIDByObject(SettingItemDestination);
	DestinationRow.IsFolder = True;
	DestinationRow.Picture = ReportsClientServer.PictureIndex("Group");
	DestinationRow.Title = SelectedFieldsGroupTitle(SettingItemDestination);
	
	RowsInheritors = New Map;
	RowsInheritors.Insert(SourceRow, DestinationRow);
	
	ChangeGroupingOfSelectedFields(StructureItemProperty, GroupingParameters.Rows, SettingsItemsInheritors, RowsInheritors);
	DeleteBasicGroupingItemsOfSelectedFields(StructureItemProperty, GroupingParameters);
	
	Section = SelectedFields.GetItems()[0];
	Items.SelectedFields.Expand(Section.GetID(), True);
	Items.SelectedFields.CurrentRow = DestinationRow.GetID();
	
	DetermineIfModified();
EndProcedure

&AtClient
Procedure ChangeGroupingOfSelectedFields(SelectedSettingsNodeFields, Rows, SettingsItemsInheritors, RowsInheritors)
	For Each SourceRow In Rows Do 
		SettingItemSource = SelectedSettingsNodeFields.GetObjectByID(SourceRow.ID);
		
		If SettingItemSource.Parent = Undefined Then 
			SourceSettingItemParent = SelectedSettingsNodeFields;
		Else
			SourceSettingItemParent = SettingItemSource.Parent;
		EndIf;
		DestinationSettingItemParent = SettingsItemsInheritors.Get(SourceSettingItemParent);
		
		SourceRowParent = SourceRow.GetParent();
		DestinationRowParent = RowsInheritors.Get(SourceRowParent);
		
		Index = DestinationSettingItemParent.Items.IndexOf(SourceSettingItemParent);
		If Index < 0 Then 
			SettingItemDestination = DestinationSettingItemParent.Items.Add(TypeOf(SettingItemSource));
			DestinationRow = DestinationRowParent.GetItems().Add();
		Else // This is grouping deletion.
			SettingItemDestination = DestinationSettingItemParent.Items.Insert(Index, TypeOf(SettingItemSource));
			DestinationRow = DestinationRowParent.GetItems().Insert(Index);
		EndIf;
		
		FillPropertyValues(SettingItemDestination, SettingItemSource);
		FillPropertyValues(DestinationRow, SourceRow);
		DestinationRow.ID = SelectedSettingsNodeFields.GetIDByObject(SettingItemDestination);
		DestinationRow.IsFolder = (TypeOf(SettingItemDestination) = Type("DataCompositionSelectedFieldGroup"));
		
		SettingsItemsInheritors.Insert(SettingItemSource, SettingItemDestination);
		RowsInheritors.Insert(SourceRow, DestinationRow);
		
		ChangeGroupingOfSelectedFields(SelectedSettingsNodeFields, SourceRow.GetItems(), SettingsItemsInheritors, RowsInheritors);
	EndDo;
EndProcedure

&AtClient
Procedure DeleteBasicGroupingItemsOfSelectedFields(SelectedSettingsNodeFields, GroupingParameters)
	Rows = GroupingParameters.Parent.GetItems();
	
	SettingsItems = SelectedSettingsNodeFields.Items;
	If TypeOf(GroupingParameters.Parent.ID) = Type("DataCompositionID") Then 
		SettingsItems = SelectedSettingsNodeFields.GetObjectByID(GroupingParameters.Parent.ID).Items;
	EndIf;
	
	Index = GroupingParameters.Rows.UBound();
	While Index >= 0 Do 
		Row = GroupingParameters.Rows[Index];
		SettingItem = SelectedSettingsNodeFields.GetObjectByID(Row.ID);
		
		Rows.Delete(Row);
		SettingsItems.Delete(SettingItem);
		
		Index = Index - 1;
	EndDo;
EndProcedure

&AtClientAtServerNoContext
Function SelectedFieldsGroupTitle(SettingItem)
	GroupTitle = SettingItem.Title;
	
	If Not ValueIsFilled(GroupTitle) Then 
		GroupTitle = "(" + SettingItem.Placement + ")";
	ElsIf SettingItem.Placement <> DataCompositionFieldPlacement.Auto Then 
		GroupTitle = GroupTitle + " (" + SettingItem.Placement + ")";
	EndIf;
	
	Return GroupTitle;
EndFunction

// Dragging items.

&AtClient
Procedure CheckRowsToDragFromSelectedFields(RowsIDs)
	Parents = New Array;
	
	Index = RowsIDs.UBound();
	While Index >= 0 Do 
		RowID = RowsIDs[Index];
		
		Row = SelectedFields.FindByID(RowID);
		Parent = Row.GetParent();
		
		If Parent = Undefined
			Or Parent.GetItems().IndexOf(Row) < 0
			Or TypeOf(Row.ID) <> Type("DataCompositionID") Then 
			RowsIDs.Delete(Index);
		Else
			Parents.Add(Parent);
		EndIf;
		
		Index = Index - 1;
	EndDo;
	
	Parents = CommonClientServer.CollapseArray(Parents);
	If Parents.Count() > 1 Then 
		RowsIDs.Clear();
	EndIf;
EndProcedure

&AtClient
Procedure DragSelectedFieldsWithinCollection(DragParameters, CurrentRow)
	CurrentData = SelectedFields.FindByID(CurrentRow);
	
	Rows = New Array;
	For Each RowID In DragParameters.Value Do 
		Rows.Add(SelectedFields.FindByID(RowID));
	EndDo;
	
	SourceRow = Rows[0].GetParent();
	If CurrentData.IsSection Or CurrentData.IsFolder Then 
		DestinationRow = CurrentData;
	Else
		DestinationRow = CurrentData.GetParent();
	EndIf;
	
	Index = DestinationRow.GetItems().IndexOf(CurrentData);
	If Index < 0 Then 
		Index = 0;
	EndIf;
	
	RowsInheritors = New Map;
	RowsInheritors.Insert(SourceRow, DestinationRow);
	
	StructureItemProperty = SettingsStructureItemProperty(
		Report.SettingsComposer, "Selection", SettingsStructureItemID, ExtendedMode);
	
	SettingItemSource = StructureItemProperty;
	If TypeOf(SourceRow.ID) = Type("DataCompositionID") Then 
		SettingItemSource = StructureItemProperty.GetObjectByID(SourceRow.ID);
	EndIf;
	
	SettingItemDestination = StructureItemProperty;
	If TypeOf(DestinationRow.ID) = Type("DataCompositionID") Then 
		SettingItemDestination = StructureItemProperty.GetObjectByID(DestinationRow.ID);
	EndIf;
	
	SettingsItemsInheritors = New Map;
	SettingsItemsInheritors.Insert(SettingItemSource, SettingItemDestination);
	
	DragSelectedFields(StructureItemProperty, Index, Rows, SettingsItemsInheritors, RowsInheritors);
	
	Items.SelectedFields.Expand(SelectedFields.GetItems()[0].GetID(), True);
	
	DetermineIfModified();
EndProcedure

&AtClient
Procedure DragSelectedFields(SelectedSettingsNodeFields, Index, Rows, SettingsItemsInheritors, RowsInheritors)
	For Each SourceRow In Rows Do
		SettingItemSource = SelectedSettingsNodeFields.GetObjectByID(SourceRow.ID);
		
		SettingItemParentSource = SelectedSettingsNodeFields;
		If SettingItemSource.Parent <> Undefined Then 
			SettingItemParentSource = SettingItemSource.Parent;
		EndIf;
		
		SettingItemParentDestination = SettingsItemsInheritors.Get(SettingItemParentSource);
		DestinationRowParent = RowsInheritors.Get(SourceRow.GetParent());
		
		If Index > SettingItemParentDestination.Items.Count() - 1 Then 
			SettingItemDestination = SettingItemParentDestination.Items.Add(TypeOf(SettingItemSource));
			DestinationRow = DestinationRowParent.GetItems().Add();
		Else
			SettingItemDestination = SettingItemParentDestination.Items.Insert(Index, TypeOf(SettingItemSource));
			DestinationRow = DestinationRowParent.GetItems().Insert(Index);
		EndIf;
		
		FillPropertyValues(SettingItemDestination, SettingItemSource);
		FillPropertyValues(DestinationRow, SourceRow);
		DestinationRow.ID = SelectedSettingsNodeFields.GetIDByObject(SettingItemDestination);
		DestinationRow.Picture = ReportsClientServer.PictureIndex("Item");
		DestinationRow.IsFolder = (TypeOf(SettingItemDestination) = Type("DataCompositionSelectedFieldGroup"));
		
		SettingsItemsInheritors.Insert(SettingItemSource, SettingItemDestination);
		RowsInheritors.Insert(SourceRow, DestinationRow);
		
		If TypeOf(SettingItemDestination) = Type("DataCompositionSelectedFieldGroup") Then 
			DestinationRow.Picture = ReportsClientServer.PictureIndex("Group");
			DragSelectedFields(SelectedSettingsNodeFields, Index, SourceRow.GetItems(), SettingsItemsInheritors, RowsInheritors)
		EndIf;
	EndDo;
EndProcedure

// Shifting items.

&AtClient
Procedure ShiftSelectedFields(ToBeginning = True)
	ShiftParameters = ShiftParametersOfSelectedFields();
	If ShiftParameters = Undefined Then 
		Return;
	EndIf;
	
	StructureItemProperty = SettingsStructureItemProperty(
		Report.SettingsComposer, "Selection", SettingsStructureItemID, ExtendedMode);
	
	For Each Row In ShiftParameters.Rows Do 
		SettingItem = SettingItem(StructureItemProperty, Row);
		
		SettingsItems = StructureItemProperty.Items;
		If SettingItem.Parent <> Undefined Then 
			SettingsItems = SettingItem.Parent.Items;
		EndIf;
		Rows = ShiftParameters.Parent.GetItems();
		
		Index = SettingsItems.IndexOf(SettingItem);
		Border = SettingsItems.Count() - 1;
		
		If ToBeginning Then // Shifting to the collection beginning.
			If Index = 0 Then 
				SettingsItems.Move(SettingItem, Border);
				Rows.Move(Index, Border);
			Else
				SettingsItems.Move(SettingItem, -1);
				Rows.Move(Index, -1);
			EndIf;
		Else // Shifting to the collection end.
			If Index = Border Then 
				SettingsItems.Move(SettingItem, -Border);
				Rows.Move(Index, -Border);
			Else
				SettingsItems.Move(SettingItem, 1);
				Rows.Move(Index, 1);
			EndIf;
		EndIf;
	EndDo;
	
	DetermineIfModified();
EndProcedure

&AtClient
Function ShiftParametersOfSelectedFields()
	Rows = New Array;
	Parents = New Array;
	
	RowsIDs = Items.SelectedFields.SelectedRows;
	For Each RowID In RowsIDs Do 
		Row = SelectedFields.FindByID(RowID);
		Parent = Row.GetParent();
		
		If Parent.GetItems().IndexOf(Row) < 0
			Or TypeOf(Row.ID) <> Type("DataCompositionID") Then 
			Continue;
		EndIf;
		
		Rows.Add(Row);
		Parents.Add(Parent);
	EndDo;
	
	If Rows.Count() = 0 Then 
		ShowMessageBox(, NStr("ru = 'Выберите элементы.'; en = 'Select items.'; pl = 'Wybrane elementy.';de = 'Wählen Sie Elemente.';ro = 'Selectați elementele.';tr = 'Öğeleri seçin.'; es_ES = 'Seleccionar los artículos.'"));
		Return Undefined;
	EndIf;
	
	Parents = CommonClientServer.CollapseArray(Parents);
	If Parents.Count() > 1 Then 
		ShowMessageBox(, NStr("ru = 'Выбранные элементы не могут быть перемещены, поскольку они принадлежат разным родителям.'; en = 'Cannot move selected items as they have different parents.'; pl = 'Nie można przenieść wybranych dokumentów, ponieważ mają one różnych ""rodziców"".';de = 'Die ausgewählten Elemente können nicht übertragen werden, da sie unterschiedliche Übergeordnete haben.';ro = 'Elementele selectate nu pot fi transferate deoarece au părinți diferiți.';tr = 'Seçilen öğeler farklı üst öğeleri olduğu için aktarılamaz.'; es_ES = 'Los artículos seleccionados no pueden transferirse porque tienen diferentes padres.'"));
		Return Undefined;
	EndIf;
	
	Return New Structure("Rows, Parent", ArraySort(Rows), Parents[0]);
EndFunction

// Common

&AtClientAtServerNoContext
Procedure CastValueToComparisonKind(Row, SettingItem = Undefined)
	ValueFieldName = ?(Row.IsParameter, "Value", "RightValue");
	CurrentValue = Row[ValueFieldName];
	
	If Row.ValueListAllowed
		Or ReportsClientServer.IsListComparisonKind(Row.ComparisonType) Then 
		
		Value = ReportsClientServer.ValuesByList(CurrentValue);
		Value.FillChecks(True);
		
		If Row.AvailableValues <> Undefined Then 
			For Each ListItem In Value Do 
				FoundItem = Row.AvailableValues.FindByValue(ListItem.Value);
				If FoundItem <> Undefined Then 
					FillPropertyValues(ListItem, FoundItem,, "Check");
				EndIf;
			EndDo;
		EndIf;
	Else
		Value = Undefined;
		If TypeOf(CurrentValue) <> Type("ValueList") Then 
			Value = CurrentValue;
		ElsIf CurrentValue.Count() > 0 Then 
			Value = CurrentValue[0].Value;
		EndIf;
	EndIf;
	
	Row[ValueFieldName] = Value;
	
	If TypeOf(SettingItem) = Type("DataCompositionSettingsParameterValue")
		Or TypeOf(SettingItem) = Type("DataCompositionFilterItem") Then 
		SettingItem[ValueFieldName] = Value;
	EndIf;
EndProcedure

&AtClientAtServerNoContext
Procedure SetValuePresentation(Row)
	Row.ValuePresentation = "";
	
	AvailableValues = Row.AvailableValues;
	If AvailableValues = Undefined Then 
		Return;
	EndIf;
	
	Value = ?(Row.IsParameter, Row.Value, Row.RightValue);
	FoundItem = AvailableValues.FindByValue(Value);
	If FoundItem <> Undefined Then 
		Row.ValuePresentation = FoundItem.Presentation;
	EndIf;
EndProcedure

&AtClient
Procedure SetEditParameters(Row)
	SettingsComposer = Report.SettingsComposer;
	
	If Row.IsParameter Then 
		ValueField = Items.FiltersValue;
		StructureItemProperty = SettingsStructureItemProperty(SettingsComposer, "DataParameters");
	Else
		ValueField = Items.FiltersRightValue;
		StructureItemProperty = SettingsStructureItemProperty(
			SettingsComposer, "Filter", SettingsStructureItemID);
	EndIf;
	
	UserSettings = SettingsComposer.UserSettings.Items;
	
	CurrentSettings = SettingsStructureItem(SettingsComposer.Settings, SettingsStructureItemID);
	SettingItem = SettingItem(StructureItemProperty, Row);
	SettingItemDetails = ReportsClientServer.FindAvailableSetting(CurrentSettings, SettingItem);
	
	ValueField.ChoiceParameters = ReportsClientServer.ChoiceParameters(CurrentSettings, UserSettings, SettingItem, ExtendedMode = 1);
	
	Row.ValueType = ReportsClient.ValueTypeRestrictedByLinkByType(
		CurrentSettings, UserSettings, SettingItem, SettingItemDetails);
	
	ValueField.AvailableTypes = Row.ValueType;
EndProcedure

&AtClient
Procedure ShowChoiceList(Row, StandardProcessing)
	StandardProcessing = False;
	
	SetEditParameters(Row);
	
	If Row.IsParameter Then 
		ValueField = Items.FiltersValue;
		CurrentValue = Row.Value;
	Else
		ValueField = Items.FiltersRightValue;
		CurrentValue = Row.RightValue;
	EndIf;
	
	OpeningParameters = New Structure;
	OpeningParameters.Insert("Marked", ReportsClientServer.ValuesByList(CurrentValue, True));
	OpeningParameters.Insert("TypeDescription", Row.ValueType);
	OpeningParameters.Insert("ValuesForSelection", Row.AvailableValues);
	OpeningParameters.Insert("ValuesForSelectionFilled", Row.AvailableValues <> Undefined);
	OpeningParameters.Insert("RestrictSelectionBySpecifiedValues", OpeningParameters.ValuesForSelectionFilled);
	OpeningParameters.Insert("Presentation", Row.UserSettingPresentation);
	OpeningParameters.Insert("ChoiceParameters", New Array(ValueField.ChoiceParameters));
	OpeningParameters.Insert("ChoiceFoldersAndItems", ValueField.ChoiceFoldersAndItems);
	
	Handler = New NotifyDescription("CompleteChoiceFromList", ThisObject, Row.GetID());
	Mode = FormWindowOpeningMode.LockOwnerWindow;
	
	OpenForm("CommonForm.InputValuesInListWithCheckBoxes", OpeningParameters, ThisObject,,,, Handler, Mode);
EndProcedure

&AtClient
Procedure CompleteChoiceFromList(List, RowID) Export
	If TypeOf(List) <> Type("ValueList") Then
		Return;
	EndIf;
	
	Row = Filters.FindByID(RowID);
	If Row = Undefined Then
		Return;
	EndIf;
	
	SelectedValues = New ValueList;
	For Each ListItem In List Do 
		If ListItem.Check Then 
			FillPropertyValues(SelectedValues.Add(), ListItem);
		EndIf;
	EndDo;
	
	ValueFieldName = ?(Row.IsParameter, "Value", "RightValue");
	PropertyKey = SettingsStructureItemPropertyKey("Filters", Row);
	
	Row[ValueFieldName] = SelectedValues;
	Row.Use = True;
	
	StructureItemProperty = SettingsStructureItemProperty(
		Report.SettingsComposer, PropertyKey, SettingsStructureItemID);
	
	SettingItem = SettingItem(StructureItemProperty, Row);
	FillPropertyValues(SettingItem, Row, "Use, " + ValueFieldName);
	
	DetermineIfModified();
EndProcedure

#EndRegion

#Region Order

// Reading settings.

&AtServer
Procedure UpdateSorting()
	StructureItemProperty = SettingsStructureItemProperty(
		Report.SettingsComposer, "Order", SettingsStructureItemID, ExtendedMode);
	
	If StructureItemProperty = Undefined Then 
		Return;
	EndIf;
	
	Section = Sort.GetItems().Add();
	Section.IsSection = True;
	Section.Title = NStr("ru = 'Сортировки'; en = 'Sorts'; pl = 'Sortowanie';de = 'Sortierung';ro = 'Sortare';tr = 'Sınıflandırma'; es_ES = 'Clasificación'");
	Section.Picture = ReportsClientServer.PictureIndex("Sorting");
	Rows = Section.GetItems();
	
	SettingsItems = StructureItemProperty.Items;
	
	For Each SettingItem In SettingsItems Do 
		Row = Rows.Add();
		FillPropertyValues(Row, SettingItem);
		Row.ID = StructureItemProperty.GetIDByObject(SettingItem);
		
		If TypeOf(SettingItem) = Type("DataCompositionAutoOrderItem") Then 
			Row.Title = NStr("ru = 'Авто (сортировки родителя)'; en = 'Auto (parent sorts)'; pl = 'Auto (pole rodzica)';de = 'Auto (übergeordnete Sortierung)';ro = 'Auto (sortare părinte)';tr = 'Oto (ana filtre)'; es_ES = 'Auto (clasificaciones de padre)'");
			Row.IsAutoField = True;
			Row.Picture = 6;
			Continue;
		EndIf;
		
		SettingDetails = StructureItemProperty.OrderAvailableFields.FindField(SettingItem.Field);
		If SettingDetails = Undefined Then 
			SetDeletionMark("Sort", Row);
		Else
			FillPropertyValues(Row, SettingDetails);
			Row.Picture = ReportsClientServer.PictureIndex("Item");
		EndIf;
	EndDo;
EndProcedure

// Adding and changing items.

&AtClient
Procedure SortingSelectField(RowID, Row)
	StructureItemProperty = SettingsStructureItemProperty(
		Report.SettingsComposer, "Order", SettingsStructureItemID, ExtendedMode);
	
	SettingItem = SettingItem(StructureItemProperty, Row);
	
	Handler = New NotifyDescription("SortAfterFieldChoice", ThisObject, RowID);
	SelectField("Sort", Handler, SettingItem.Field);
EndProcedure

&AtClient
Procedure SortAfterFieldChoice(SettingDetails, RowID = Undefined) Export
	If SettingDetails = Undefined Then
		Return;
	EndIf;
	
	StructureItemProperty = SettingsStructureItemProperty(
		Report.SettingsComposer, "Order", SettingsStructureItemID, ExtendedMode);
	
	If RowID = Undefined Then 
		Parent = Items.Sort.CurrentData;
		If Not Parent.IsSection Then 
			Parent = Parent.GetParent();
		EndIf;
		Row = Parent.GetItems().Add();
		
		SettingItemParent = StructureItemProperty;
		If TypeOf(Parent.ID) = Type("DataCompositionID") Then 
			SettingItemParent = StructureItemProperty.GetObjectByID(Parent.ID);
		EndIf;
		SettingItem = SettingItemParent.Items.Add(Type("DataCompositionOrderItem"));
	Else
		Row = Sort.FindByID(RowID);
		SettingItem = SettingItem(StructureItemProperty, Row);
	EndIf;
	
	SettingItem.Use = True;
	SettingItem.Field = SettingDetails.Field;
	
	FillPropertyValues(Row, SettingItem);
	FillPropertyValues(Row, SettingDetails);
	
	Row.ID = StructureItemProperty.GetIDByObject(SettingItem);
	Row.Picture = ReportsClientServer.PictureIndex("Item");
	
	Items.Sort.Expand(Sort.GetItems()[0].GetID());
	
	DetermineIfModified();
EndProcedure

&AtClient
Procedure ChangeRowsOrderType(OrderType)
	Rows = Sort.GetItems()[0].GetItems();
	If Rows.Count() = 0 Then 
		Return;
	EndIf;
	
	StructureItemProperty = SettingsStructureItemProperty(
		Report.SettingsComposer, "Order", SettingsStructureItemID, ExtendedMode);
	
	For Each Row In Rows Do 
		SettingItem = SettingItem(StructureItemProperty, Row);
		SettingItem.OrderType = OrderType;
		Row.OrderType = SettingItem.OrderType;
	EndDo;
	
	DetermineIfModified();
EndProcedure

&AtClient
Procedure ChangeOrderType(Row)
	StructureItemProperty = SettingsStructureItemProperty(
		Report.SettingsComposer, "Order", SettingsStructureItemID, ExtendedMode);
	
	SettingItem = SettingItem(StructureItemProperty, Row);
	
	If SettingItem.OrderType = DataCompositionSortDirection.Asc Then 
		SettingItem.OrderType = DataCompositionSortDirection.Desc;
	Else
		SettingItem.OrderType = DataCompositionSortDirection.Asc;
	EndIf;
	Row.OrderType = SettingItem.OrderType;
	
	DetermineIfModified();
EndProcedure

// Dragging items.

&AtClient
Procedure DragSelectedFieldsToSorting(Rows)
	SelectedStructureItemFields = SettingsStructureItemProperty(
		Report.SettingsComposer, "Selection", SettingsStructureItemID, ExtendedMode);
	
	StructureItemSorting = SettingsStructureItemProperty(
		Report.SettingsComposer, "Order", SettingsStructureItemID, ExtendedMode);
	
	Section = Sort.GetItems()[0];
	
	For Each SourceRow In Rows Do 
		SettingItemSource = SelectedStructureItemFields.GetObjectByID(SourceRow.ID);
		If TypeOf(SettingItemSource) = Type("DataCompositionSelectedFieldGroup") Then 
			DragSelectedFieldsToSorting(SourceRow.GetItems());
		Else
			If FindOrderField(StructureItemSorting, SettingItemSource.Field) <> Undefined Then 
				Continue;
			EndIf;
			
			SettingItemDestination = StructureItemSorting.Items.Add(Type("DataCompositionOrderItem"));
			FillPropertyValues(SettingItemDestination, SettingItemSource);
			SettingItemDestination.Use = True;
			
			SettingDetails = StructureItemSorting.OrderAvailableFields.FindField(SettingItemSource.Field);
			
			DestinationRow = Section.GetItems().Add();
			FillPropertyValues(DestinationRow, SettingItemDestination);
			FillPropertyValues(DestinationRow, SettingDetails);
			DestinationRow.ID = StructureItemSorting.GetIDByObject(SettingItemDestination);
			DestinationRow.Picture = ReportsClientServer.PictureIndex("Item");
		EndIf;
	EndDo;
	
	Items.Sort.Expand(Section.GetID());
	DetermineIfModified();
EndProcedure

&AtClient
Procedure DragSortingWithinCollection(DragParameters, CurrentRow)
	
EndProcedure

&AtClient
Function FindOrderField(SettingsNodeSorting, Field)
	For Each SettingItem In SettingsNodeSorting.Items Do 
		If SettingItem.Field = Field Then 
			Return Field;
		EndIf;
	EndDo;
	
	Return Undefined;
EndFunction

&AtClient
Procedure DragSortingFieldsToSelectedFields(Rows)
	SelectedStructureItemFields = SettingsStructureItemProperty(
		Report.SettingsComposer, "Selection", SettingsStructureItemID, ExtendedMode);
	
	StructureItemSorting = SettingsStructureItemProperty(
		Report.SettingsComposer, "Order", SettingsStructureItemID, ExtendedMode);
	
	SelectedFieldsSection = SelectedFields.GetItems()[0];
	SortingFieldsSection = Sort.GetItems()[0];
	
	Index = Rows.Count() - 1;
	While Index >= 0 Do 
		SourceRow = Rows[Index];
		SettingItemSource = StructureItemSorting.GetObjectByID(SourceRow.ID);
		
		If FindSelectedField(SelectedStructureItemFields, SettingItemSource.Field) = Undefined Then 
			SettingItemDestination = SelectedStructureItemFields.Items.Add(Type("DataCompositionSelectedField"));
			FillPropertyValues(SettingItemDestination, SettingItemSource);
			
			SettingDetails = SelectedStructureItemFields.SelectionAvailableFields.FindField(SettingItemSource.Field);
			
			DestinationRow = SelectedFieldsSection.GetItems().Add();
			FillPropertyValues(DestinationRow, SettingItemDestination);
			FillPropertyValues(DestinationRow, SettingDetails);
			DestinationRow.ID = SelectedStructureItemFields.GetIDByObject(SettingItemDestination);
			DestinationRow.Picture = ReportsClientServer.PictureIndex("Item");
		EndIf;
		
		StructureItemSorting.Items.Delete(SettingItemSource);
		SortingFieldsSection.GetItems().Delete(SourceRow);
		
		Index = Index - 1;
	EndDo;
	
	Items.SelectedFields.Expand(SelectedFieldsSection.GetID(), True);
	DetermineIfModified();
EndProcedure

&AtClient
Function FindSelectedField(SelectedSettingsNodeFields, Field)
	FoundField = Undefined;
	
	For Each SettingItem In SelectedSettingsNodeFields.Items Do 
		If TypeOf(SettingItem) = Type("DataCompositionSelectedFieldGroup") Then 
			FoundField = FindSelectedField(SettingItem, Field);
		ElsIf SettingItem.Field = Field Then 
			FoundField = Field;
		EndIf;
	EndDo;
	
	Return FoundField;
EndFunction

// Shifting items.

&AtClient
Procedure ShiftSorting(ToBeginning = True)
	RowsIDs = Items.Sort.SelectedRows;
	SectionID = Sort.GetItems()[0].GetID();
	
	SectionIndex = RowsIDs.Find(SectionID);
	If SectionIndex <> Undefined Then 
		RowsIDs.Delete(SectionIndex);
	EndIf;
	
	If RowsIDs.Count() = 0 Then 
		Return;
	EndIf;
	
	StructureItemProperty = SettingsStructureItemProperty(
		Report.SettingsComposer, "Order", SettingsStructureItemID, ExtendedMode);
	
	For Each RowID In RowsIDs Do 
		Row = Sort.FindByID(RowID);
		SettingItem = SettingItem(StructureItemProperty, Row);
		
		SettingsItems = StructureItemProperty.Items;
		Rows = Row.GetParent().GetItems();
		
		Index = SettingsItems.IndexOf(SettingItem);
		Border = SettingsItems.Count() - 1;
		
		If ToBeginning Then // Shifting to the collection beginning.
			If Index = 0 Then 
				SettingsItems.Move(SettingItem, Border);
				Rows.Move(Index, Border);
			Else
				SettingsItems.Move(SettingItem, -1);
				Rows.Move(Index, -1);
			EndIf;
		Else // Shifting to the collection end.
			If Index = Border Then 
				SettingsItems.Move(SettingItem, -Border);
				Rows.Move(Index, -Border);
			Else
				SettingsItems.Move(SettingItem, 1);
				Rows.Move(Index, 1);
			EndIf;
		EndIf;
	EndDo;
	
	DetermineIfModified();
EndProcedure

#EndRegion

#Region Appearance

// Reading settings.

&AtServer
Procedure UpdateAppearance()
	StructureItemProperty = SettingsStructureItemProperty(
		Report.SettingsComposer, "ConditionalAppearance", SettingsStructureItemID);
	
	If StructureItemProperty = Undefined Then 
		Return;
	EndIf;
	
	ReadPredefinedAppearanceParameters();
	
	If SettingsStructureItemChangeMode Then 
		Rows = Appearance.GetItems();
	Else
		Section = Appearance.GetItems().Add();
		Section.Title = NStr("ru = 'Условное оформление'; en = 'Conditional appearance'; pl = 'Formatowanie warunkowe';de = 'Bedingtes Erscheinungsbild';ro = 'Perfectare convențională';tr = 'Koşullu görünüm'; es_ES = 'Formato condicional'");
		Section.Presentation = NStr("ru = 'Условное оформление'; en = 'Conditional appearance'; pl = 'Formatowanie warunkowe';de = 'Bedingtes Erscheinungsbild';ro = 'Perfectare convențională';tr = 'Koşullu görünüm'; es_ES = 'Formato condicional'");
		Section.Picture = ReportsClientServer.PictureIndex("ConditionalAppearance");
		Section.IsSection = True;
		Rows = Section.GetItems();
	EndIf;
	
	For Each SettingItem In StructureItemProperty.Items Do 
		Row = Rows.Add();
		FillPropertyValues(Row, SettingItem);
		Row.ID = StructureItemProperty.GetIDByObject(SettingItem);
		Row.Picture = -1;
		
		If AppearanceItemIsMarkedForDeletion(SettingItem.Fields) Then 
			SetDeletionMark("Appearance", Row);
		EndIf;
		
		Row.Presentation = ReportsClientServer.ConditionalAppearanceItemPresentation(
			SettingItem, SettingItem, ?(Row.DeletionMark, "DeletionMark", ""));
		
		If ValueIsFilled(Row.UserSettingPresentation) Then 
			Row.Title = Row.UserSettingPresentation;
		Else
			Row.Title = Row.Presentation;
		EndIf;
		
		Row.IsPredefinedTitle = (Row.Title = Row.UserSettingPresentation);
		Row.DisplayModePicture = SettingItemDisplayModePicture(SettingItem);
	EndDo;
EndProcedure

&AtServer
Function AppearanceItemIsMarkedForDeletion(Fields)
	AvailableFields = Fields.AppearanceFieldsAvailableFields;
	
	For Each Item In Fields.Items Do 
		If AvailableFields.FindField(Item.Field) = Undefined Then 
			Return True;
		EndIf;
	EndDo;
	
	Return False;
EndFunction

// Defines output parameter properties that affect the display of title, data parameters, and filters.
//  See also ReportsServer.InitializePredefinedOutputParameters().
//
&AtServer
Procedure ReadPredefinedAppearanceParameters()
	If SettingsStructureItemChangeMode Then 
		Return;
	EndIf;
	
	PredefinedParameters = PredefinedOutputParameters(Report.SettingsComposer.Settings);
	
	// The Title output parameter.
	Object = PredefinedParameters.TITLE.Object;
	
	Row = Appearance.GetItems().Add();
	FillPropertyValues(Row, Object, "Use, Value");
	Row.Title = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("ru = 'Заголовок: %1'; en = 'Title: %1'; pl = 'Tytuł: %1';de = 'Titel: %1';ro = 'Titlul: %1';tr = 'Başlık: %1'; es_ES = 'Título: %1'"),
		?(ValueIsFilled(Object.Value), Object.Value, "<Missing>"));
	Row.Presentation = NStr("ru = 'Заголовок'; en = 'Title'; pl = 'Nagłówek';de = 'Titel';ro = 'Titlul';tr = 'Başlık'; es_ES = 'Título'");
	Row.ID = PredefinedParameters.TITLE.ID;
	Row.Picture = -1;
	Row.DisplayModePicture = 4;
	Row.IsOutputParameter = True;
	
	// The OutputParameters output parameter.
	Object = PredefinedParameters.DATAPARAMETERSOUTPUT.Object;
	LinkedObject = PredefinedParameters.FILTEROUTPUT.Object;
	
	Row = Appearance.GetItems().Add();
	Row.Use = (Object.Value <> DataCompositionTextOutputType.DontOutput
		Or LinkedObject.Value <> DataCompositionTextOutputType.DontOutput);
	Row.Title = NStr("ru = 'Выводить параметры и отборы'; en = 'Show parameters and filters'; pl = 'Wyświetlanie ustawień i selekcje';de = 'Parameter und Auswahlen anzeigen';ro = 'Arată parametrii și filtrele';tr = 'Çıkış parametreleri ve seçimleri'; es_ES = 'Mostrar parámetros y selecciones'");
	Row.Presentation = NStr("ru = 'Выводить параметры и отборы'; en = 'Show parameters and filters'; pl = 'Wyświetlanie ustawień i selekcje';de = 'Parameter und Auswahlen anzeigen';ro = 'Arată parametrii și filtrele';tr = 'Çıkış parametreleri ve seçimleri'; es_ES = 'Mostrar parámetros y selecciones'");
	Row.ID = PredefinedParameters.DATAPARAMETERSOUTPUT.ID;
	Row.Picture = -1;
	Row.DisplayModePicture = 4;
	Row.IsOutputParameter = True;
EndProcedure

// Adding and changing items.

&AtClient
Procedure AppearanceChangeItem(RowID = Undefined, Row = Undefined)
	Handler = New NotifyDescription("AppearanceChangeItemCompletion", ThisObject, RowID);
	
	FormParameters = New Structure;
	FormParameters.Insert("ReportSettings", ReportSettings);
	FormParameters.Insert("SettingsComposer", Report.SettingsComposer);
	FormParameters.Insert("SettingsStructureItemID", SettingsStructureItemID);
	If Row = Undefined Then
		FormParameters.Insert("DCID", Undefined);
		FormParameters.Insert("Description", "");
	Else
		FormParameters.Insert("DCID", Row.ID);
		FormParameters.Insert("Description", Row.Title);
	EndIf;
	FormParameters.Insert("Title", StringFunctionsClientServer.SubstituteParametersToString(
		NStr("ru = 'Элемент условного оформления отчета ""%1""'; en = 'Conditional report appearance item ""%1""'; pl = 'Element warunkowego sporządzania sprawozdania ""%1""';de = 'Element der bedingten Berichterstattung ""%1""';ro = 'Elementul de perfectare convențională a raportului ""%1""';tr = '""%1"" raporun koşullu kayıt öğesi'; es_ES = 'Elemento de diseño condicional del informe ""%1""'"), DescriptionOption));
	
	OpenForm("SettingsStorage.ReportsVariantsStorage.Form.ConditionalReportAppearanceItem",
		FormParameters, ThisObject, UUID,,, Handler);
EndProcedure

&AtClient
Procedure AppearanceChangeItemCompletion(Result, RowID) Export
	If Result = Undefined Or Result = DialogReturnCode.Cancel Then
		Return;
	EndIf;
	
	StructureItemProperty = SettingsStructureItemProperty(
		Report.SettingsComposer, "ConditionalAppearance", SettingsStructureItemID);
	
	Section = DefaultRootRow("Appearance");
	
	If RowID = Undefined Then
		If Section = Undefined Then 
			Row = Appearance.GetItems().Add();
		Else
			Row = Section.GetItems().Add();
		EndIf;
		SettingItem = StructureItemProperty.Items.Add();
	Else
		Row = Appearance.FindByID(RowID);
		SettingItem = SettingItem(StructureItemProperty, Row);
		SettingItem.Filter.Items.Clear();
		SettingItem.Fields.Items.Clear();
	EndIf;
	
	ReportsClientServer.FillPropertiesRecursively(StructureItemProperty, SettingItem, Result.DCItem);
	SettingItem.UserSettingID = New UUID;
	SettingItem.Presentation = Result.Description;
	
	Row.ID = StructureItemProperty.GetIDByObject(SettingItem);
	Row.Use = SettingItem.Use;
	Row.Title = Result.Description;
	Row.Presentation = Result.Description;
	Row.IsPredefinedTitle = (Row.Title = Row.Presentation);
	
	If Row.IsPredefinedTitle Then
		SettingItem.UserSettingPresentation = "";
	Else
		SettingItem.UserSettingPresentation = Row.Title;
	EndIf;
	
	Row.Picture = -1;
	Row.DisplayModePicture = SettingItemDisplayModePicture(SettingItem);
	
	If Section <> Undefined Then 
		Items.Appearance.Expand(Section.GetID());
	EndIf;
	
	DetermineIfModified();
EndProcedure

&AtClient
Procedure SynchronizePredefinedOutputParameters(Usage, SettingItem)
	OutputParameters = Report.SettingsComposer.Settings.OutputParameters.Items;
	
	Value = ?(Usage, DataCompositionTextOutputType.Auto, DataCompositionTextOutputType.DontOutput);
	
	If SettingItem.Parameter = New DataCompositionParameter("Title") Then 
		LinkedSettingItem = OutputParameters.Find("TITLEOUTPUT");
		LinkedSettingItem.Use = True;
		LinkedSettingItem.Value = Value;
	ElsIf SettingItem.Parameter = New DataCompositionParameter("OutputDataParameters") Then 
		LinkedSettingItem = OutputParameters.Find("FILTEROUTPUT");
		FillPropertyValues(LinkedSettingItem, SettingItem, "Use, Value");
	EndIf;
EndProcedure

&AtClient
Procedure AppearanceTitleInputCompletion(Value, ID) Export 
	If Value = Undefined Then 
		Return;
	EndIf;
	
	Row = Appearance.FindByID(ID);
	Row.Use = True;
	Row.Value = Value;
	Row.Title = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("ru = 'Заголовок: %1'; en = 'Title: %1'; pl = 'Tytuł: %1';de = 'Titel: %1';ro = 'Titlul: %1';tr = 'Başlık: %1'; es_ES = 'Título: %1'"),
		?(ValueIsFilled(Value), Value, "<Missing>"));
	
	OutputParameters = Report.SettingsComposer.Settings.OutputParameters;
	SettingItem = OutputParameters.GetObjectByID(Row.ID);
	SettingItem.Value = Value;
	SettingItem.Use = True;
	
	DetermineIfModified();
EndProcedure

// Shifting items.

&AtClient
Procedure ShiftAppearance(ToBeginning = True)
	RowsIDs = Items.Appearance.SelectedRows;
	
	Section = DefaultRootRow("Appearance");
	If Section <> Undefined Then 
		SectionID = Section.GetID();
		SectionIndex = RowsIDs.Find(SectionID);
		If SectionIndex <> Undefined Then 
			RowsIDs.Delete(SectionIndex);
		EndIf;
	EndIf;
	
	If RowsIDs.Count() = 0 Then 
		Return;
	EndIf;
	
	StructureItemProperty = SettingsStructureItemProperty(
		Report.SettingsComposer, "ConditionalAppearance", SettingsStructureItemID);
	
	For Each RowID In RowsIDs Do 
		Row = Appearance.FindByID(RowID);
		SettingItem = SettingItem(StructureItemProperty, Row);
		
		SettingsItems = StructureItemProperty.Items;
		Rows = Row.GetParent().GetItems();
		
		Index = SettingsItems.IndexOf(SettingItem);
		Border = SettingsItems.Count() - 1;
		
		If ToBeginning Then // Shifting to the collection beginning.
			If Index = 0 Then 
				SettingsItems.Move(SettingItem, Border);
				Rows.Move(Index, Border);
			Else
				SettingsItems.Move(SettingItem, -1);
				Rows.Move(Index, -1);
			EndIf;
		Else // Shifting to the collection end.
			If Index = Border Then 
				SettingsItems.Move(SettingItem, -Border);
				Rows.Move(Index, -Border);
			Else
				SettingsItems.Move(SettingItem, 1);
				Rows.Move(Index, 1);
			EndIf;
		EndIf;
	EndDo;
	
	DetermineIfModified();
EndProcedure

// Item usage.

&AtClient
Procedure ChangePredefinedOutputParametersUsage(Usage = True)
	If SettingsStructureItemChangeMode Then 
		Return;
	EndIf;
	
	Rows = Appearance.GetItems();
	StructureItemProperty = Report.SettingsComposer.Settings.OutputParameters;
	
	For Each Row In Rows Do 
		If TypeOf(Row.ID) <> Type("DataCompositionID") Then 
			Continue;
		EndIf;
		
		Row.Use = Usage;
		SettingItem = SettingItem(StructureItemProperty, Row);
		SettingItem.Use = Usage;
	EndDo;
EndProcedure

// Handler of closing the HeaderAndFooterSettings common form.
//  See Syntax Assistant: OpenForm - OnCloseNotifyDescription. 
//
&AtClient
Procedure RememberHeaderFooterSettings(Settings, AdditionalParameters) Export 
	PreviousSettings = Undefined;
	Report.SettingsComposer.Settings.AdditionalProperties.Property("HeaderOrFooterSettings", PreviousSettings);
	
	If Settings <> PreviousSettings Then 
		DetermineIfModified();
	EndIf;
	
	Report.SettingsComposer.Settings.AdditionalProperties.Insert("HeaderOrFooterSettings", Settings);
EndProcedure

#EndRegion

#Region Structure

// Reading settings.

&AtServer
Procedure UpdateStructure()
	StructureItemProperty = SettingsStructureItemProperty(Report.SettingsComposer, "Structure");
	If StructureItemProperty = Undefined Then 
		Return;
	EndIf;
	
	Section = OptionStructure.GetItems().Add();
	Section.Presentation = NStr("ru = 'Отчет'; en = 'Report'; pl = 'Raport';de = 'Bericht';ro = 'Raport';tr = 'Rapor'; es_ES = 'Informe'");
	Section.IsSection = True;
	Section.Picture = -1;
	Section.Type = StructureItemProperty;
	Rows = Section.GetItems();
	
	UpdateStructureCollection(StructureItemProperty, "Structure", Rows);
EndProcedure

&AtServer
Procedure UpdateStructureCollection(Val Node, Val CollectionName, Rows)
	StructureItemProperty = SettingsStructureItemProperty(Report.SettingsComposer, "Structure");
	UserSettings = Report.SettingsComposer.UserSettings.Items;
	
	Collection = Node[CollectionName];
	
	// Adding a collection title.
	If CollectionName <> "Structure"
		AND (TypeOf(Collection) = Type("DataCompositionTableStructureItemCollection")
		Or TypeOf(Collection) = Type("DataCompositionChartStructureItemCollection")) Then 
		Row = Rows.Add();
		Row.ID = StructureItemProperty.GetIDByObject(Collection);
		Row.Presentation = CollectionName;
		Row.Picture = -1;
		Row.Type = Collection;
		Rows = Row.GetItems();
	EndIf;
	
	For Each Item In Collection Do 
		If ValueIsFilled(Item.UserSettingID) Then 
			ContainsUserStructureItems = True;
		EndIf;
		
		UserSettingItem = UserSettings.Find(Item.UserSettingID);
		
		Row = Rows.Add();
		Row.Use = True;
		
		If TypeOf(Item) = Type("DataCompositionNestedObjectSettings") Then 
			Node = Item.Settings;
			ContainsNestedReports = True;
		Else
			Node = Item;
			FillPropertyValues(Row, Item);
			
			If ExtendedMode = 0 AND UserSettingItem <> Undefined Then 
				Row.Use = UserSettingItem.Use;
			EndIf;
		EndIf;
		
		Row.ID = StructureItemProperty.GetIDByObject(Node);
		Row.AvailableFlag = True;
		
		ItemProperties = StructureCollectionItemProperties(Item);
		FillPropertyValues(Row, ItemProperties);
		
		If ItemProperties.DeletionMark Then 
			SetDeletionMark("OptionStructure", Row);
		EndIf;
		
		For Each CollectionName In ItemProperties.CollectionsNames Do 
			UpdateStructureCollection(Node, CollectionName, Row.GetItems());
		EndDo;
	EndDo;
EndProcedure

&AtServer
Function StructureCollectionItemProperties(Item)
	ItemProperties = StructureCollectionItemPropertiesPalette();
	
	ItemType = TypeOf(Item);
	If ItemType = Type("DataCompositionGroup")
		Or ItemType = Type("DataCompositionTableGroup")
		Or ItemType = Type("DataCompositionChartGroup") Then 
		
		ItemProperties.Presentation = GroupFieldsPresentation(Item, ItemProperties.DeletionMark);
		CollectionsNames = "Structure";
	ElsIf ItemType = Type("DataCompositionNestedObjectSettings") Then 
		Objects = AvailableSettingsObjects(Item);
		ObjectDetails = Objects.Find(Item.ObjectID);
		
		ItemProperties.Presentation = ObjectDetails.Title;
		If ValueIsFilled(Item.UserSettingPresentation) Then 
			ItemProperties.Presentation = Item.UserSettingPresentation;
		EndIf;
		
		If Not ValueIsFilled(ItemProperties.Presentation) Then
			ItemProperties.Presentation = NStr("ru = 'Вложенная группировка'; en = 'Nested grouping'; pl = 'Załączone grupowanie';de = 'Gruppierung anhängen';ro = 'Grupare incorporată';tr = 'Gruplandırmayı ekle'; es_ES = 'Añadir la agrupación'");
		EndIf;
		CollectionsNames = "Structure";
	ElsIf ItemType = Type("DataCompositionTable") Then 
		ItemProperties.Presentation = NStr("ru = 'Таблица'; en = 'Table'; pl = 'Tabela';de = 'Tabelle';ro = 'Tabel';tr = 'Tablo'; es_ES = 'Tabla'");
		CollectionsNames = "Rows, Columns";
	ElsIf ItemType = Type("DataCompositionChart") Then 
		ItemProperties.Presentation = NStr("ru = 'Диаграмма'; en = 'Chart'; pl = 'Wykres';de = 'Grafik';ro = 'Grafic';tr = 'Diyagram'; es_ES = 'Diagrama'");
		CollectionsNames = "Points, Series";
	Else
		ItemProperties.Presentation = String(ItemType);
		CollectionsNames = "";
	EndIf;
	
	If ItemType <> Type("DataCompositionNestedObjectSettings") Then 
		ItemTitle = Item.OutputParameters.Items.Find("Title");
		If ItemTitle <> Undefined Then 
			ItemProperties.Title = ItemTitle.Value;
		EndIf;
	EndIf;
	
	ItemProperties.CollectionsNames = StrSplit(CollectionsNames, ", ", False);
	
	ItemTypePresentation = ReportsClientServer.SettingTypeAsString(ItemType);
	ItemState = ?(ItemProperties.DeletionMark, "DeletionMark", Undefined);
	ItemProperties.Picture = ReportsClientServer.PictureIndex(ItemTypePresentation, ItemState);
	
	ItemProperties.Type = Item;
	
	SetFlagsOfNestedSettingsItems(Item, ItemProperties);
	
	Return ItemProperties;
EndFunction

&AtServer
Function StructureCollectionItemPropertiesPalette()
	ItemProperties = New Structure;
	ItemProperties.Insert("Presentation", "");
	ItemProperties.Insert("Title", "");
	ItemProperties.Insert("CollectionsNames", New Array);
	ItemProperties.Insert("DeletionMark", False);
	ItemProperties.Insert("Picture", -1);
	ItemProperties.Insert("Type", "");
	ItemProperties.Insert("ContainsFilters", False);
	ItemProperties.Insert("ContainsFieldsOrSorting", False);
	ItemProperties.Insert("ContainsConditionalAppearance", False);
	
	Return ItemProperties;
EndFunction

&AtServer
Function GroupFieldsPresentation(SettingItem, DeletionMark)
	If ValueIsFilled(SettingItem.UserSettingPresentation) Then 
		Return SettingItem.UserSettingPresentation;
	EndIf;
	
	Fields = SettingItem.GroupFields;
	If Fields.Items.Count() = 0 Then 
		Return NStr("ru = '<Детальные записи>'; en = '<Detailed records>'; pl = '<Zapisy szczegółowe>';de = '<Detaillierte Datensätze>';ro = '<Înregistrări detaliate>';tr = '<Detailed records>'; es_ES = '<Registros detallados>'");
	EndIf;
	
	FieldsPresentation = New Array;
	
	For Each Item In Fields.Items Do 
		If TypeOf(Item) = Type("DataCompositionAutoGroupField") Then 
			Continue;
		EndIf;
		
		FieldDetails = Fields.GroupFieldsAvailableFields.FindField(Item.Field);
		If FieldDetails = Undefined Then
			DeletionMark = True;
			FieldPresentation = String(Item.Field);
		Else
			FieldPresentation = FieldDetails.Title;
		EndIf;
		
		If Item.GroupType <> DataCompositionGroupType.Items Then 
			FieldPresentation = FieldPresentation + " (" + Item.GroupType + ")";
		EndIf;
		
		FieldsPresentation.Add(FieldPresentation);
	EndDo;
	
	If FieldsPresentation.Count() = 0 Then 
		Return NStr("ru = '<Детальные записи>'; en = '<Detailed records>'; pl = '<Zapisy szczegółowe>';de = '<Detaillierte Datensätze>';ro = '<Înregistrări detaliate>';tr = '<Detailed records>'; es_ES = '<Registros detallados>'");
	EndIf;
	
	Return StrConcat(FieldsPresentation, ", ");
EndFunction

&AtServer
Function AvailableSettingsObjects(SettingsOfNestedObject)
	If TypeOf(SettingsOfNestedObject.Parent) = Type("DataCompositionSettings") Then 
		Return SettingsOfNestedObject.Parent.AvailableObjects.Items;
	Else
		Return AvailableSettingsObjects(SettingsOfNestedObject.Parent);
	EndIf;
EndFunction

&AtServer
Procedure SetFlagsOfNestedSettingsItems(StructureItem, StructureItemProperties)
	ItemType = TypeOf(StructureItem);
	If ItemType = Type("DataCompositionTable")
		Or ItemType = Type("DataCompositionChart") Then 
		Return;
	EndIf;
	
	Item = StructureItem;
	If ItemType = Type("DataCompositionNestedObjectSettings") Then 
		Item = StructureItem.Settings;
	EndIf;
	
	StructureItemProperties.ContainsFilters = Item.Filter.Items.Count();
	StructureItemProperties.ContainsConditionalAppearance = Item.ConditionalAppearance.Items.Count();
	
	NestedItems = Item.Selection.Items;
	ContainsFields = NestedItems.Count() > 0
		AND Not (NestedItems.Count() = 1
		AND TypeOf(NestedItems[0]) = Type("DataCompositionAutoSelectedField"));
	
	NestedItems = Item.Order.Items;
	ContainsSorting = NestedItems.Count() > 0
		AND Not (NestedItems.Count() = 1
		AND TypeOf(NestedItems[0]) = Type("DataCompositionAutoOrderItem"));
	
	StructureItemProperties.ContainsFieldsOrSorting = ContainsFields Or ContainsSorting;
	
	// Setting service flags.
	If StructureItemProperties.ContainsFilters Then 
		ContainsNestedFilters = True;
	EndIf;
	
	If StructureItemProperties.ContainsFieldsOrSorting Then 
		ContainsNestedFieldsOrSorting = True;
	EndIf;
	
	If StructureItemProperties.ContainsConditionalAppearance Then 
		ContainsNestedConditionalAppearance = True;
	EndIf;
EndProcedure

// Adding and changing items.

&AtClient
Procedure AddOptionStructureGrouping(NextLevel = True)
	ExecutionParameters = New Structure;
	ExecutionParameters.Insert("NextLevel", NextLevel);
	ExecutionParameters.Insert("Turn", True);
	
	StructureItemID = Undefined;
	Row = Items.OptionStructure.CurrentData;
	If Row <> Undefined Then
		If Not NextLevel Then
			Row = Row.GetParent();
		EndIf;
		
		If NextLevel Then
			If Row.Type = "DataCompositionSettings" AND Not Row.AvailableFlag Then
				ExecutionParameters.Turn = False;
			ElsIf Row.GetItems().Count() > 1 Then
				ExecutionParameters.Turn = False;
			EndIf;
		EndIf;
		
		While Row <> Undefined Do
			If Row.Type = "DataCompositionSettings"
				Or Row.Type = "DataCompositionNestedObjectSettings"
				Or Row.Type = "DataCompositionGroup"
				Or Row.Type = "DataCompositionTableGroup"
				Or Row.Type = "DataCompositionChartGroup" Then
				StructureItemID = Row.ID;
				Break;
			EndIf;
			Row = Row.GetParent();
		EndDo;
	EndIf;
	
	Handler = New NotifyDescription("OptionStructureAfterSelectField", ThisObject, ExecutionParameters);
	SelectField("OptionStructure", Handler, Undefined, StructureItemID);
EndProcedure

&AtClient
Procedure AddSettingsStructureItem(ItemType)
	CurrentRow = Items.OptionStructure.CurrentData;
	
	Result = InsertSettingsStructureItem(ItemType, CurrentRow, True);
	SettingItem = Result.SettingItem;
	
	Row = Result.Row;
	Row.Type = SettingItem;
	Row.Title = Row.Presentation;
	Row.AvailableFlag = True;
	Row.Use = SettingItem.Use;
	
	ItemTypePresentation = ReportsClientServer.SettingTypeAsString(TypeOf(SettingItem));
	Row.Picture = ReportsClientServer.PictureIndex(ItemTypePresentation);
	
	StructureItemProperty = SettingsStructureItemProperty(Report.SettingsComposer, "Structure");
	SubordinateRows = Row.GetItems();
	
	If Row.Type = "DataCompositionChart" Then
		SettingItem.Selection.Items.Add(Type("DataCompositionAutoSelectedField"));
		SetOutputParameter(SettingItem, "ChartType.ValuesBySeriesConnection", ChartValuesBySeriesConnectionType.EdgesConnection);
		SetOutputParameter(SettingItem, "ChartType.ValuesBySeriesConnectionLines");
		SetOutputParameter(SettingItem, "ChartType.ValuesBySeriesConnectionColor", WebColors.Gainsboro);
		SetOutputParameter(SettingItem, "ChartType.SplineMode", ChartSplineMode.SmoothCurve);
		SetOutputParameter(SettingItem, "ChartType.SemitransparencyMode", ChartSemitransparencyMode.Use);
		
		Row.Presentation = NStr("ru = 'Диаграмма'; en = 'Chart'; pl = 'Wykres';de = 'Grafik';ro = 'Diagrama';tr = 'Diyagram'; es_ES = 'Diagrama'");
		
		SubordinateSettingItem = SettingItem.Points;
		SubordinateRow = SubordinateRows.Add();
		SubordinateRow.Type = SubordinateSettingItem;
		SubordinateRow.Subtype = "ChartPoints";
		SubordinateRow.ID = StructureItemProperty.GetIDByObject(SubordinateSettingItem);
		SubordinateRow.Picture = -1;
		SubordinateRow.Presentation = NStr("ru = 'Точки'; en = 'Dots'; pl = 'Punkty';de = 'Punkte';ro = 'Puncte';tr = 'Noktalar'; es_ES = 'Puntos'");
		
		SubordinateSettingItem = SettingItem.Series;
		SubordinateRow = SubordinateRows.Add();
		SubordinateRow.Type = SubordinateSettingItem;
		SubordinateRow.Subtype = "ChartSeries";
		SubordinateRow.ID = StructureItemProperty.GetIDByObject(SubordinateSettingItem);
		SubordinateRow.Picture = -1;
		SubordinateRow.Presentation = NStr("ru = 'Серии'; en = 'Series'; pl = 'Seria';de = 'Serie';ro = 'Serii';tr = 'Seri'; es_ES = 'Serie'");
	ElsIf Row.Type = "DataCompositionTable" Then
		Row.Presentation = NStr("ru = 'Таблица'; en = 'Table'; pl = 'Tabela';de = 'Tabelle';ro = 'Tabel';tr = 'Tablo'; es_ES = 'Tabla'");
		
		SubordinateSettingItem = SettingItem.Rows;
		SubordinateRow = SubordinateRows.Add();
		SubordinateRow.Type = SubordinateSettingItem;
		SubordinateRow.Subtype = "TableRows";
		SubordinateRow.ID = StructureItemProperty.GetIDByObject(SubordinateSettingItem);
		SubordinateRow.Picture = -1;
		SubordinateRow.Presentation = NStr("ru = 'Строки'; en = 'Rows'; pl = 'Wiersze';de = 'Zeilen';ro = 'Rânduri';tr = 'Satırlar'; es_ES = 'Líneas'");
		
		SubordinateSettingItem = SettingItem.Columns;
		SubordinateRow = SubordinateRows.Add();
		SubordinateRow.Type = SubordinateSettingItem;
		SubordinateRow.Subtype = "ColumnsTable";
		SubordinateRow.ID = StructureItemProperty.GetIDByObject(SubordinateSettingItem);
		SubordinateRow.Picture = -1;
		SubordinateRow.Presentation = NStr("ru = 'Колонки'; en = 'Columns'; pl = 'Kolumny';de = 'Spalten';ro = 'Coloane';tr = 'Sütunlar'; es_ES = 'Columnas'");
	EndIf;
	
	Items.OptionStructure.Expand(Row.GetID(), True);
	DetermineIfModified();
EndProcedure

&AtClient
Procedure OptionStructureAfterSelectField(SettingDetails, ExecutionParameters) Export
	If SettingDetails = Undefined Then
		Return;
	EndIf;
	
	CurrentRow = Items.OptionStructure.CurrentData;
	
	RowsToMoveToNewGroup = New Array;
	If ExecutionParameters.Turn Then
		If ExecutionParameters.NextLevel Then
			FoundItems = CurrentRow.GetItems();
			For Each RowToMove In FoundItems Do
				RowsToMoveToNewGroup.Add(RowToMove);
			EndDo;
		Else
			RowsToMoveToNewGroup.Add(CurrentRow);
		EndIf;
	EndIf;
	
	// Adding a new grouping.
	Result = InsertSettingsStructureItem(Type("DataCompositionGroup"), CurrentRow, ExecutionParameters.NextLevel);
	
	SettingItem = Result.SettingItem;
	SettingItem.Use = True;
	SettingItem.Selection.Items.Add(Type("DataCompositionAutoSelectedField"));
	SettingItem.Order.Items.Add(Type("DataCompositionAutoOrderItem"));
	
	If SettingDetails = "<>" Then
		// Detailed records - you do not need to add a field.
		Presentation = NStr("ru = '<Детальные записи>'; en = '<Detailed records>'; pl = '<Zapisy szczegółowe>';de = '<Detaillierte Datensätze>';ro = '<Înregistrări detaliate>';tr = '<Detaylı kayıtlar>'; es_ES = '<Registros detallados>'");
	Else
		GroupField = SettingItem.GroupFields.Items.Add(Type("DataCompositionGroupField"));
		GroupField.Use = True;
		GroupField.Field = SettingDetails.Field;
		Presentation = SettingDetails.Title;
	EndIf;
	
	Row = Result.Row;
	Row.Use = SettingItem.Use;
	Row.Presentation = Presentation;
	Row.AvailableFlag = True;
	Row.Type = SettingItem;
	
	ItemType = Type(Row.Type);
	ItemTypePresentation = ReportsClientServer.SettingTypeAsString(ItemType);
	ItemState = ?(Row.DeletionMark, "DeletionMark", Undefined);
	Row.Picture = ReportsClientServer.PictureIndex(ItemTypePresentation, ItemState);
	
	If Not ExecutionParameters.NextLevel Then
		Row.Title = CurrentRow.Title;
		UpdateOptionStructureItemTitle(Row);
		CurrentRow.Title = "";
		UpdateOptionStructureItemTitle(CurrentRow);
	EndIf;
	
	// Moving the current grouping to a new one.
	For Each RowToMove In RowsToMoveToNewGroup Do
		Result = MoveOptionStructureItems(RowToMove, Row);
	EndDo;
	
	Items.OptionStructure.Expand(Row.GetID(), True);
	Items.OptionStructure.CurrentRow = Row.GetID();
	
	DetermineIfModified();
EndProcedure

&AtClient
Function InsertSettingsStructureItem(ItemType, Row, NextLevel)
	StructureItemProperty = SettingsStructureItemProperty(Report.SettingsComposer, "Structure");
	
	If Row = Undefined Then
		Row = OptionStructure;
		Index = Undefined;
		SettingItemIndex = Undefined;
	EndIf;
	
	SettingItem = SettingItem(StructureItemProperty, Row);
	
	If NextLevel Then
		Rows = Row.GetItems();
		Index = Undefined;
		
		SettingsItems = SettingsItems(StructureItemProperty, SettingItem);
		SettingItemIndex = Undefined
	Else // Inserting it on the same level as the row.
		Parent = GetParent("OptionStructure", Row);
		Rows = Parent.GetItems();
		Index = Rows.IndexOf(Row) + 1;
		
		SettingItemParent = GetSettingItemParent(StructureItemProperty, SettingItem);
		SettingsItems = SettingsItems(StructureItemProperty, SettingItemParent);
		SettingItemIndex = SettingsItems.IndexOf(SettingItem) + 1;
	EndIf;
	
	If Index = Undefined Then
		NewString = Rows.Add();
	Else
		NewString = Rows.Insert(Index);
	EndIf;
	
	If ReportsClient.SpecifyItemTypeOnAddToCollection(TypeOf(SettingsItems)) Then
		If SettingItemIndex = Undefined Then
			NewSettingItem = SettingsItems.Add(ItemType);
		Else
			NewSettingItem = SettingsItems.Insert(SettingItemIndex, ItemType);
		EndIf;
	Else
		If SettingItemIndex = Undefined Then
			NewSettingItem = SettingsItems.Add();
		Else
			NewSettingItem = SettingsItems.Insert(SettingItemIndex);
		EndIf;
	EndIf;
	Items.OptionStructure.CurrentRow = NewString.GetID();
	NewString.ID = StructureItemProperty.GetIDByObject(NewSettingItem);
	
	Result = New Structure("Row, StructureItemProperty, SettingItem");
	Result.Row = NewString;
	Result.StructureItemProperty = StructureItemProperty;
	Result.SettingItem = NewSettingItem;
	
	Return Result;
EndFunction

&AtClient
Function MoveOptionStructureItems(Val Row, Val NewParent,
	Val BeforeWhatToInsert = Undefined, Val Index = Undefined, Val SettingItemIndex = Undefined)
	
	Result = New Structure("Row, SettingItem, IndexOf, SettingItemIndex");
	
	AddToEnd = (NewParent = Undefined);
	WhereToInsert = GetItems(OptionStructure, NewParent);
	
	DCNode = SettingsStructureItemProperty(Report.SettingsComposer, "Structure");
	
	DCItem = SettingItem(DCNode, Row);
	NewDCParent = SettingItem(DCNode, NewParent);
	WhereToInsertDC = SettingsItems(DCNode, NewDCParent);
	BeforeWhatToInsertDC = SettingItem(DCNode, BeforeWhatToInsert);
	
	PreviousParent = GetParent("OptionStructure", Row);
	FromWhereToMove = GetItems(OptionStructure, PreviousParent);
	
	PreviousDCParent = SettingItem(DCNode, PreviousParent);
	FromWhereToMoveDC = SettingsItems(DCNode, PreviousDCParent);
	
	If DCItem = BeforeWhatToInsertDC Then
		Result.SettingItem = DCItem;
		Result.Row = Row;
	Else
		If Index = Undefined Or SettingItemIndex = Undefined Then
			If BeforeWhatToInsertDC = Undefined Then
				If AddToEnd Then
					Index = WhereToInsert.Count();
					SettingItemIndex = WhereToInsertDC.Count();
				Else
					Index = 0;
					SettingItemIndex = 0;
				EndIf;
			Else
				Index = WhereToInsert.IndexOf(BeforeWhatToInsert);
				SettingItemIndex = WhereToInsertDC.IndexOf(BeforeWhatToInsertDC);
				If PreviousParent = NewParent Then
					PreviousIndex = FromWhereToMove.IndexOf(Row);
					If PreviousIndex <= Index Then
						Index = Index + 1;
						SettingItemIndex = SettingItemIndex + 1;
					EndIf;
				EndIf;
			EndIf;
		EndIf;
		
		SearchForDCItems = New Map;
		Result.SettingItem = ReportsClientServer.CopyRecursive(DCNode, DCItem, WhereToInsertDC, SettingItemIndex, SearchForDCItems);
		
		SearchForTableRows = New Map;
		Result.Row = ReportsClientServer.CopyRecursive(Undefined, Row, WhereToInsert, Index, SearchForTableRows);
		
		For Each KeyAndValue In SearchForTableRows Do
			PreviousRow = KeyAndValue.Key;
			NewString = KeyAndValue.Value;
			NewString.ID = SearchForDCItems.Get(PreviousRow.ID);
		EndDo;
		
		FromWhereToMove.Delete(Row);
		FromWhereToMoveDC.Delete(DCItem);
	EndIf;
	
	Result.IndexOf = WhereToInsert.IndexOf(Result.Row);
	Result.SettingItemIndex = WhereToInsertDC.IndexOf(Result.SettingItem);
	
	Return Result;
EndFunction

&AtClient
Procedure OptionStructureOnChangeCurrentRow()
	Row = Items.OptionStructure.CurrentData;
	If Row <> Undefined Then
		SetOptionStructureItemsProperties(Row.GetID());
	EndIf;
EndProcedure

&AtServer
Procedure SetOptionStructureItemsProperties(RowID)
	Row = OptionStructure.FindByID(RowID);
	Parent = Row.GetParent();
	HasSubordinateItems = (Row.GetItems().Count() > 0);
	HasNeighbors = GetItems(OptionStructure, Parent).Count() > 1;
	
	CanAddNestedItems = (Row.Type <> "DataCompositionTable"
		AND Row.Type <> "DataCompositionChart");
	
	CanGroup = (Row.Type <> "DataCompositionSettings"
		AND Row.Type <> "DataCompositionNestedObjectSettings"
		AND Row.Type <> "DataCompositionTableStructureItemCollection"
		AND Row.Type <> "DataCompositionChartStructureItemCollection");
	
	CanOpen = (Row.Type <> "DataCompositionSettings"
		AND Row.Type <> "DataCompositionNestedObjectSettings"
		AND Row.Type <> "DataCompositionTable"
		AND Row.Type <> "DataCompositionChart"
		AND Row.Type <> "DataCompositionTableStructureItemCollection"
		AND Row.Type <> "DataCompositionChartStructureItemCollection");
	
	CanRemoveAndMove = (Row.Type <> "DataCompositionSettings"
		AND Row.Type <> "DataCompositionNestedObjectSettings"
		AND Row.Type <> "DataCompositionTableStructureItemCollection"
		AND Row.Type <> "DataCompositionChartStructureItemCollection");
	
	CanAddTablesAndCharts = (Row.Type = "DataCompositionSettings"
		Or Row.Type = "DataCompositionNestedObjectSettings"
		Or Row.Type = "DataCompositionGroup");
	
	CanMoveParent = (Parent <> Undefined
		AND Parent.Type <> "DataCompositionSettings"
		AND Parent.Type <> "DataCompositionTableStructureItemCollection"
		AND Parent.Type <> "DataCompositionChartStructureItemCollection");
	
	Items.OptionStructure_Add.Enabled  = CanAddNestedItems;
	Items.OptionStructure_Add1.Enabled = CanAddNestedItems;
	Items.OptionStructure_Change.Enabled  = CanOpen;
	Items.OptionStructure_Change1.Enabled = CanOpen;
	Items.OptionStructure_AddTable.Enabled  = CanAddTablesAndCharts;
	Items.OptionStructure_AddTable1.Enabled = CanAddTablesAndCharts;
	Items.OptionStructure_AddChart.Enabled  = CanAddTablesAndCharts;
	Items.OptionStructure_AddChart1.Enabled = CanAddTablesAndCharts;
	Items.OptionStructure_Delete.Enabled  = CanRemoveAndMove;
	Items.OptionStructure_Delete1.Enabled = CanRemoveAndMove;
	Items.OptionStructure_Group.Enabled  = CanGroup;
	Items.OptionStructure_Group1.Enabled = CanGroup;
	Items.OptionStructure_MoveUpAndLeft.Enabled  = CanRemoveAndMove AND CanMoveParent AND CanAddNestedItems AND CanGroup;
	Items.OptionStructure_MoveUpAndLeft1.Enabled = CanRemoveAndMove AND CanMoveParent AND CanAddNestedItems AND CanGroup;
	Items.OptionStructure_MoveDownAndRight.Enabled  = CanRemoveAndMove AND HasSubordinateItems AND CanAddNestedItems AND CanGroup;
	Items.OptionStructure_MoveDownAndRight1.Enabled = CanRemoveAndMove AND HasSubordinateItems AND CanAddNestedItems AND CanGroup;
	Items.OptionStructure_MoveUp.Enabled  = CanRemoveAndMove AND HasNeighbors;
	Items.OptionStructure_MoveUp1.Enabled = CanRemoveAndMove AND HasNeighbors;
	Items.OptionStructure_MoveDown.Enabled  = CanRemoveAndMove AND HasNeighbors;
	Items.OptionStructure_MoveDown1.Enabled = CanRemoveAndMove AND HasNeighbors;
EndProcedure

&AtClient
Procedure ChangeStructureItem(Row, PageName = Undefined, UseOptionForm = Undefined)
	If Row = Undefined Then
		Rows = OptionStructure.GetItems();
		If Rows.Count() = 0 Then
			Return;
		EndIf;
		Row = Rows[0];
	EndIf;
	
	If UseOptionForm = Undefined Then
		UseOptionForm = (Row.Type = "DataCompositionTable"
			Or Row.Type = "DataCompositionNestedObjectSettings");
	EndIf;
	
	Handler = New NotifyDescription("StructureItemIDCompletion", ThisObject);
	
	TitleTemplate = NStr("ru = 'Настройка %1 отчета ""%2""'; en = '%1 settings of report %2'; pl = 'Ustawienia %1 sprawozdania ""%2""';de = 'Erstellen %1 des Berichts ""%2""';ro = 'Setarea %1 raportului ""%2""';tr = '%1Raporun %2 ayarı'; es_ES = 'Ajustes %1 del informe ""%2""'");
	If Row.Type = "DataCompositionChart" Then
		ItemPresentation = NStr("ru = 'диаграммы'; en = 'Chart'; pl = 'wykresy';de = 'Diagramme';ro = 'diagrame';tr = 'diyagramlar'; es_ES = 'diagramas'");
	Else
		ItemPresentation = NStr("ru = 'группировки'; en = 'Grouping'; pl = 'grupowania';de = 'Gruppierungen';ro = 'grupări';tr = 'gruplar'; es_ES = 'agrupaciones'");
	EndIf;
	
	If ValueIsFilled(Row.Title) Then
		ItemPresentation = ItemPresentation + " """ + Row.Title + """";
	ElsIf ValueIsFilled(Row.Presentation) Then
		ItemPresentation = ItemPresentation + " """ + Row.Presentation + """";
	EndIf;
	
	FormParameters = New Structure;
	FormParameters.Insert("VariantKey", String(CurrentVariantKey));
	FormParameters.Insert("Variant", Report.SettingsComposer.Settings);
	FormParameters.Insert("UserSettings", Report.SettingsComposer.UserSettings);
	FormParameters.Insert("ReportSettings", ReportSettings);
	FormParameters.Insert("DescriptionOption", DescriptionOption);
	FormParameters.Insert("SettingsStructureItemID", Row.ID);
	FormParameters.Insert("SettingsStructureItemType", Row.Type);
	FormParameters.Insert("Title", StringFunctionsClientServer.SubstituteParametersToString(
		TitleTemplate, ItemPresentation, DescriptionOption));
	If PageName <> Undefined Then
		FormParameters.Insert("PageName", PageName);
	EndIf;
	
	RunMeasurements = ReportSettings.RunMeasurements AND ValueIsFilled(ReportSettings.MeasurementsKey);
	If RunMeasurements Then
		ModulePerformanceMonitorClient = CommonClient.CommonModule("PerformanceMonitorClient");
		MeasurementID = ModulePerformanceMonitorClient.TimeMeasurement(
			ReportSettings.MeasurementsKey + ".Settings", False, False);
		ModulePerformanceMonitorClient.SetMeasurementComment(MeasurementID, ReportSettings.MeasurementsPrefix);
	EndIf;
	
	NameOfFormToOpen = ReportSettings.FullName + ?(UseOptionForm, ".VariantForm", ".SettingsForm");
	OpenForm(NameOfFormToOpen, FormParameters, ThisObject,,,, Handler);
EndProcedure

&AtClient
Procedure StructureItemIDCompletion(Result, Context) Export
	If TypeOf(Result) <> Type("Structure")
		Or Result = DialogReturnCode.Cancel Then
		Return;
	EndIf;
	
	If Result.VariantModified Then 
		UpdateForm(Result);
	EndIf;
EndProcedure

#EndRegion

#Region Common

#Region NotificationsHandlers

&AtClient
Function ListFillingParameters(CloseOnChoose = False, MultipleChoice = True, AddRow = True)
	FillingParameters = New Structure("ListPath, IndexOf, Owner, SelectedType, ChoiceFoldersAndItems");
	FillingParameters.Insert("AddRow", AddRow);
	// Standard form parameters.
	FillingParameters.Insert("CloseOnChoice", CloseOnChoose);
	FillingParameters.Insert("CloseOnOwnerClose", True);
	FillingParameters.Insert("Filter", New Structure);
	// Standard parameters of the choice form (see Managed form extension for a dynamic list).
	FillingParameters.Insert("MultipleChoice", MultipleChoice);
	FillingParameters.Insert("ChoiceMode", True);
	// Supposed attributes.
	FillingParameters.Insert("WindowOpeningMode", FormWindowOpeningMode.LockOwnerWindow);
	FillingParameters.Insert("EnableStartDrag", False);
	
	Return FillingParameters;
EndFunction

&AtClient
Procedure StartListFilling(Item, FillingParameters)
	List = ThisObject[FillingParameters.ListPath];
	ListField = Items[FillingParameters.ListPath];
	ValueField = Items[FillingParameters.ListPath + "Value"];
	
	Info = ReportsClient.SettingItemInfo(Report.SettingsComposer, FillingParameters.IndexOf);
	
	Condition = ReportsClientServer.SettingItemCondition(Info.UserSettingItem, Info.Details);
	ValueField.ChoiceFoldersAndItems = ReportsClientServer.GroupsAndItemsTypeValue(
		Info.Details.ChoiceFoldersAndItems, Condition);
	FillingParameters.ChoiceFoldersAndItems = ReportsClient.ValueOfFoldersAndItemsUseType(
		Info.Details.ChoiceFoldersAndItems, Condition);
	
	ExtendedTypesDetails = CommonClientServer.StructureProperty(
		Report.SettingsComposer.Settings.AdditionalProperties, "ExtendedTypesDetails", New Map);
	
	ExtendedTypeDetails = ExtendedTypesDetails[FillingParameters.IndexOf];
	If ExtendedTypeDetails <> Undefined Then 
		List.ValueType = ExtendedTypeDetails.TypesDetailsForForm;
	EndIf;
	List.ValueType = TypesDetailsWithoutPrimitiveOnes(List.ValueType);
	
	UserSettings = Report.SettingsComposer.UserSettings.Items;
	
	ChoiceParameters = ReportsClientServer.ChoiceParameters(Info.Settings, UserSettings, Info.Item);
	FillingParameters.Insert("ChoiceParameters", ChoiceParameters);
	
	List.ValueType = ReportsClient.ValueTypeRestrictedByLinkByType(
		Info.Settings, UserSettings, Info.Item, Info.Details, List.ValueType);
	
	Types = List.ValueType.Types();
	If Types.Count() = 0 Then
		If FillingParameters.AddRow Then 
			ListField.AddRow();
		EndIf;
		Return;
	EndIf;
	
	If Types.Count() = 1 Then
		FillingParameters.SelectedType = Types[0];
		CompleteListFilling(-1, FillingParameters);
		Return;
	EndIf;
	
	AvailableTypes = New ValueList;
	AvailableTypes.LoadValues(Types);
	
	Handler = New NotifyDescription("CompleteListFilling", ThisObject, FillingParameters);
	ShowChooseFromMenu(Handler, AvailableTypes, Item);
EndProcedure

&AtClient
Procedure CompleteListFilling(SelectedItem, FillingParameters) Export
	If SelectedItem = Undefined Then
		Return;
	EndIf;
	
	If SelectedItem <> -1 Then
		FillingParameters.SelectedType = SelectedItem.Value;
	EndIf;
	
	PickingParameters = CommonClientServer.StructureProperty(
		Report.SettingsComposer.Settings.AdditionalProperties, "PickingParameters", New Map);
	
	FormPath = PickingParameters[FillingParameters.IndexOf];
	If Not ValueIsFilled(FormPath) Then 
		FormPath = PickingParameters[FillingParameters.SelectedType];
	EndIf;
	
	For Each Parameter In FillingParameters.ChoiceParameters Do 
		If Not ValueIsFilled(Parameter.Name) Then
			Continue;
		EndIf;
		
		If StrStartsWith(Upper(Parameter.Name), "FILTER.") Then 
			FillingParameters.Filter.Insert(Mid(Parameter.Name, 7), Parameter.Value);
		Else
			FillingParameters.Insert(Parameter.Name, Parameter.Value);
		EndIf;
	EndDo;
	
	Owner = FillingParameters.Owner;
	FillingParameters.Delete("Owner");
	
	OpenForm(FormPath, FillingParameters, Owner);
EndProcedure

&AtClient
Procedure PasteFromClipboardCompletion(FoundObjects, ListPath) Export
	If FoundObjects = Undefined Then
		Return;
	EndIf;
	
	List = ThisObject[ListPath];
	
	SettingsComposer = Report.SettingsComposer;
	
	Index = PathToItemsData.ByName[ListPath];
	SettingItem = SettingsComposer.UserSettings.Items[Index];
	
	If TypeOf(SettingItem) = Type("DataCompositionFilterItem") Then
		If SettingItem.RightValue = Undefined Then
			SettingItem.RightValue = New ValueList;
		EndIf;
		Marked = SettingItem.RightValue;
	Else
		Marked = SettingItem.Value;
	EndIf;
	
	For Each Value In FoundObjects Do
		ReportsClientServer.AddUniqueValueToList(List, Value, Undefined, True);
		ReportsClientServer.AddUniqueValueToList(Marked, Value, Undefined, True);
	EndDo;
	
	SettingItem.Use = True;
	
	RegisterList(Items[ListPath], SettingItem);
EndProcedure

#EndRegion

&AtClientAtServerNoContext
Function SettingsStructureItemProperty(SettingsComposer, varKey, ItemID = Undefined, Mode = Undefined)
	Settings = SettingsComposer.Settings;
	
	If varKey = "Structure" Then 
		Return Settings;
	EndIf;
	
	StructureItem = SettingsStructureItem(Settings, ItemID);
	
	StructureItemType = TypeOf(StructureItem);
	If StructureItem = Undefined
		Or (StructureItemType = Type("DataCompositionTable") AND varKey <> "Selection" AND varKey <> "ConditionalAppearance")
		Or (StructureItemType = Type("DataCompositionChart") AND varKey <> "Selection" AND varKey <> "ConditionalAppearance")
		Or (StructureItemType = Type("DataCompositionSettings") AND varKey = "GroupFields")
		Or (StructureItemType = Type("DataCompositionGroup") AND varKey = "DataParameters")
		Or (StructureItemType = Type("DataCompositionTableGroup") AND varKey = "DataParameters")
		Or (StructureItemType = Type("DataCompositionChartGroup") AND varKey = "DataParameters") Then 
		Return Undefined;
	EndIf;
	
	StructureItemProperty = StructureItem[varKey];
	
	If Mode = 0
		AND (TypeOf(StructureItemProperty) = Type("DataCompositionSelectedFields")
			Or TypeOf(StructureItemProperty) = Type("DataCompositionOrder"))
		AND ValueIsFilled(StructureItemProperty.UserSettingID) Then 
		
		StructureItemProperty = SettingsComposer.UserSettings.Items.Find(
			StructureItemProperty.UserSettingID);
	EndIf;
	
	Return StructureItemProperty;
EndFunction

&AtClientAtServerNoContext
Function SettingsStructureItem(Settings, ItemID)
	If TypeOf(ItemID) = Type("DataCompositionID") Then 
		StructureItem = Settings.GetObjectByID(ItemID);
	Else
		StructureItem = Settings;
	EndIf;
	
	Return StructureItem;
EndFunction

&AtClientAtServerNoContext
Function SettingsStructureItemPropertyKey(CollectionName, Row)
	varKey = Undefined;
	
	If CollectionName = "GroupComposition" Then 
		varKey = "GroupFields";
	ElsIf CollectionName = "Parameters" Or CollectionName = "Filters" Then 
		If Row.Property("IsParameter") AND Row.IsParameter Then 
			varKey = "DataParameters";
		Else
			varKey = "Filter";
		EndIf;
	ElsIf CollectionName = "SelectedFields" Then 
		varKey = "Selection";
	ElsIf CollectionName = "Sort" Then 
		varKey = "Order";
	ElsIf CollectionName = "Appearance" Then 
		If Row.Property("IsOutputParameter") AND Row.IsOutputParameter Then 
			varKey = "OutputParameters";
		Else
			varKey = "ConditionalAppearance";
		EndIf;
	ElsIf CollectionName = "OptionStructure" Then 
		varKey = "Structure";
	EndIf;
	
	Return varKey;
EndFunction

&AtClient
Procedure DeleteRows(Item, Cancel)
	Cancel = True;
	
	RowsIDs = Item.SelectedRows;
	
	Index = RowsIDs.UBound();
	While Index >= 0 Do 
		Row = ThisObject[Item.Name].FindByID(RowsIDs[Index]);
		Index = Index - 1;
		
		If TypeOf(Row.ID) <> Type("DataCompositionID")
			Or (Row.Property("IsSection") AND Row.IsSection)
			Or (Row.Property("IsParameter") AND Row.IsParameter)
			Or (Row.Property("IsOutputParameter") AND Row.IsOutputParameter) Then 
			Continue;
		EndIf;
		
		Rows = GetParent(Item.Name, Row).GetItems();
		If Rows.IndexOf(Row) < 0 Then 
			Continue;
		EndIf;
			
		PropertyKey = SettingsStructureItemPropertyKey(Item.Name, Row);
		StructureItemProperty = SettingsStructureItemProperty(
			Report.SettingsComposer, PropertyKey, SettingsStructureItemID, ExtendedMode);
		
		SettingItem = SettingItem(StructureItemProperty, Row);
		If TypeOf(SettingItem) = Type("DataCompositionTableStructureItemCollection")
			Or TypeOf(SettingItem) = Type("DataCompositionChartStructureItemCollection") Then 
			Continue;
		EndIf;
		
		SettingItemParent = GetSettingItemParent(StructureItemProperty, SettingItem);
		CollectionName = SettingsCollectionNameByID(Row.ID);
		SettingsItems = SettingsItems(StructureItemProperty, SettingItemParent, CollectionName);
		
		SettingsItems.Delete(SettingItem);
		Rows.Delete(Row);
	EndDo;
	
	DetermineIfModified();
EndProcedure

&AtClient
Procedure ChangeUsage(CollectionName, Usage = True, Rows = Undefined)
	If Rows = Undefined Then 
		RootRow = DefaultRootRow(CollectionName);
		If RootRow = Undefined Then 
			Return;
		EndIf;
		
		Rows = RootRow.GetItems();
	EndIf;
	
	For Each Row In Rows Do 
		Row.Use = Usage;
		
		PropertyKey = SettingsStructureItemPropertyKey(CollectionName, Row);
		StructureItemProperty = SettingsStructureItemProperty(
			Report.SettingsComposer, PropertyKey, SettingsStructureItemID, ExtendedMode);
		
		SettingItem = SettingItem(StructureItemProperty, Row);
		If Type(SettingItem) <> Type("DataCompositionTableStructureItemCollection")
			AND Type(SettingItem) <> Type("DataCompositionChartStructureItemCollection") Then 
			SettingItem.Use = Usage;
		EndIf;
		
		ChangeUsage(CollectionName, Usage, Row.GetItems());
	EndDo;
	
	DetermineIfModified();
EndProcedure

&AtClient
Procedure ChangeSettingItemUsage(CollectionName)
	Row = Items[CollectionName].CurrentData;
	
	SettingsComposer = Report.SettingsComposer;
	
	PropertyKey = SettingsStructureItemPropertyKey(CollectionName, Row);
	StructureItemProperty = SettingsStructureItemProperty(
		SettingsComposer, PropertyKey, SettingsStructureItemID, ExtendedMode);
	
	SettingItem = SettingItem(StructureItemProperty, Row);
	SettingItem.Use = Row.Use;
	
	If Row.Property("IsOutputParameter")
		AND Row.IsOutputParameter
		AND String(Row.ID) = "DATAPARAMETERSOUTPUT" Then 
		
		SettingItem.Use = True;
		SettingItem.Value = ?(Row.Use,
			DataCompositionTextOutputType.Auto, DataCompositionTextOutputType.DontOutput);
	EndIf;
	
	If ExtendedMode = 0 AND CollectionName = "OptionStructure" Then 
		UserSettingItem = SettingsComposer.UserSettings.Items.Find(
			SettingItem.UserSettingID);
		If UserSettingItem <> Undefined Then 
			UserSettingItem.Use = SettingItem.Use;
		EndIf;
	EndIf;
	
	ChangeUsageOfLinkedSettingsItems(CollectionName, Row, SettingItem);
	
	DetermineIfModified();
EndProcedure

&AtClient
Procedure ChangeUsageOfLinkedSettingsItems(CollectionName, Row, SettingItem)
	If CollectionName = "GroupComposition" Then
		LinkedCollection = "SelectedFields";
	ElsIf CollectionName = "SelectedFields" Then
		LinkedCollection = "GroupComposition";
	Else
		LinkedCollection = Undefined;
	EndIf;
	
	If LinkedCollection <> Undefined AND ValueIsFilled(Row.Field) Then
		Condition = New Structure("Field", Row.Field);
		ChangeUsageByCondition(LinkedCollection, Condition, Row.Use);
	ElsIf Row.Property("IsOutputParameter") AND Row.IsOutputParameter Then 
		SynchronizePredefinedOutputParameters(Row.Use, SettingItem);
	EndIf;
EndProcedure

&AtClient
Procedure ChangeUsageByCondition(CollectionName, Condition, Usage)
	Collection = ThisObject[CollectionName];
	FoundItems = ReportsClientServer.FindTableRows(Collection, Condition);
	
	StructureItemProperty = Undefined;
	For Each Row In FoundItems Do
		If Row.Use = Usage Then
			Continue;
		EndIf;
		
		If StructureItemProperty = Undefined Then
			PropertyKey = SettingsStructureItemPropertyKey(CollectionName, Row);
			StructureItemProperty = SettingsStructureItemProperty(
				Report.SettingsComposer, PropertyKey, SettingsStructureItemID, ExtendedMode);
		EndIf;
		
		SettingItem = SettingItem(StructureItemProperty, Row);
		If SettingItem <> Undefined Then
			Row.Use = Usage;
			SettingItem.Use = Usage;
		EndIf;
	EndDo;
EndProcedure

&AtServer
Procedure SetDeletionMark(CollectionName, Row)
	Row.DeletionMark = True;
	
	If CollectionName = "Appearance" Then 
		Row.Picture = ReportsClientServer.PictureIndex("Error");
	Else
		Row.Picture = ReportsClientServer.PictureIndex("Item", "DeletionMark");
	EndIf;
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Client

&AtClient
Procedure WriteAndClose(Regenerate)
	NotifyChoice(SelectionResult(Regenerate));
EndProcedure

&AtClient
Function SelectionResult(Regenerate)
	SelectionResultGenerated = True;
	
	If SettingsStructureItemChangeMode AND Not Regenerate Then
		Return Undefined;
	EndIf;
	
	SelectionResult = New Structure;
	SelectionResult.Insert("EventName", "SettingsForm");
	SelectionResult.Insert("Regenerate", Regenerate);
	SelectionResult.Insert("VariantModified", OptionChanged);
	SelectionResult.Insert("UserSettingsModified", OptionChanged Or UserSettingsModified);
	SelectionResult.Insert("ResetUserSettings", ExtendedMode = 1);
	SelectionResult.Insert("SettingsFormAdvancedMode", ExtendedMode);
	SelectionResult.Insert("SettingsFormPageName", Items.SettingsPages.CurrentPage.Name);
	SelectionResult.Insert("DCSettingsComposer", Report.SettingsComposer);
	
	Return SelectionResult;
EndFunction

&AtClientAtServerNoContext
Function PredefinedOutputParameters(Settings)
	PredefinedParameters = New Structure("TITLE, TITLEOUTPUT, DATAPARAMETERSOUTPUT, FILTEROUTPUT");
	
	OutputParameters = Settings.OutputParameters;
	For Each Parameter In PredefinedParameters Do 
		ParameterProperties = New Structure("Object, ID");
		ParameterProperties.Object = OutputParameters.Items.Find(Parameter.Key);
		ParameterProperties.ID = OutputParameters.GetIDByObject(ParameterProperties.Object);
		
		PredefinedParameters[Parameter.Key] = ParameterProperties;
	EndDo;
	
	Return PredefinedParameters;
EndFunction

&AtClient
Procedure SetOutputParameter(StructureItem, ParameterName, Value = Undefined, Usage = True)
	ParameterValue = StructureItem.OutputParameters.FindParameterValue(New DataCompositionParameter(ParameterName));
	If ParameterValue = Undefined Then
		Return;
	EndIf;
	
	If Value <> Undefined Then
		ParameterValue.Value = Value;
	EndIf;
	
	If Usage <> Undefined Then
		ParameterValue.Use = Usage;
	EndIf;
EndProcedure

&AtClient
Function NewContext(Val TableName, Val Action)
	Result = New Structure;
	Result.Insert("ReasonDenied", "");
	Result.Insert("TableName", TableName);
	Result.Insert("Action", Action);
	Return Result;
EndFunction

&AtClient
Procedure DefineSelectedRows(Context)
	Context.Insert("TreeRows", New Array); // Selected rows (not IDs).
	Context.Insert("CurrentRow", Undefined); // An active row (not an ID).
	TableItem = Items[Context.TableName];
	TableAttribute = ThisObject[Context.TableName];
	IDCurrentRow = TableItem.CurrentRow;
	
	Specifics = New Structure("CanBeSections, CanBeParameters,
		|CanBeOutputParameters, CanBeGroups, RequireOneParent");
	Specifics.CanBeSections = (Context.TableName = "Filters"
		Or Context.TableName = "SelectedFields"
		Or Context.TableName = "Sort"
		Or Context.TableName = "Appearance");
	Specifics.CanBeParameters = (Context.TableName = "Filters");
	Specifics.CanBeOutputParameters = (Context.TableName = "Appearance");
	Specifics.RequireOneParent = (Context.Action = "Move" Or Context.Action = "Group");
	Specifics.CanBeGroups = (Context.TableName = "Filters" Or Context.TableName = "SelectedFields");
	If Specifics.RequireOneParent Then
		Context.Insert("CurrentParent", -1);
	EndIf;
	If Specifics.CanBeGroups Then
		HadGroups = False;
	EndIf;
	
	SelectedRows = ArraySort(TableItem.SelectedRows, SortDirection.Asc);
	For Each IDRow In SelectedRows Do
		TreeRow = TableAttribute.FindByID(IDRow);
		If Not RowAdded(Context, TreeRow, Specifics) Then
			Return;
		EndIf;
		If Specifics.CanBeGroups AND TreeRow.IsFolder Then
			HadGroups = True;
		EndIf;
		If IDRow = IDCurrentRow Then
			Context.CurrentRow = TreeRow;
		EndIf;
	EndDo;
	If Context.TreeRows.Count() = 0 Then
		Context.ReasonDenied = NStr("ru = 'Выберите элементы.'; en = 'Select items.'; pl = 'Wybrane elementy.';de = 'Wählen Sie Elemente.';ro = 'Selectați elementele.';tr = 'Öğeleri seçin.'; es_ES = 'Seleccionar los artículos.'");
		Return;
	EndIf;
	If Context.CurrentRow = Undefined Then
		If Context.Action = "ChangeGroup" Then
			Context.ReasonDenied = NStr("ru = 'Выберите группу.'; en = 'Select group.'; pl = 'Wybierz grupę.';de = 'Wähle die Gruppe.';ro = 'Selectați grupul.';tr = 'Grubu seçin.'; es_ES = 'Seleccionar un grupo.'");
			Return;
		EndIf;
	EndIf;
	
	// Removing all subordinate rows whose parents are enabled from the list of rows to be removed.
	If Context.Action = "Delete" AND Specifics.CanBeGroups AND HadGroups Then
		Count = Context.TreeRows.Count();
		For Number = 1 To Count Do
			ReverseIndex = Count - Number;
			Parent = Context.TreeRows[ReverseIndex];
			While Parent <> Undefined Do
				Parent = Parent.GetParent();
				If Context.TreeRows.Find(Parent) <> Undefined Then
					Context.TreeRows.Delete(ReverseIndex);
					Break;
				EndIf;
			EndDo;
		EndDo;
	EndIf;
EndProcedure

&AtClient
Function RowAdded(Rows, TreeRow, Specifics)
	If Rows.TreeRows.Find(TreeRow) <> Undefined Then
		Return True; // Skipping the row.
	EndIf;
	If Specifics.CanBeSections AND TreeRow.IsSection Then
		Return True; // Skipping the row.
	EndIf;
	If (Specifics.CanBeParameters AND TreeRow.IsParameter)
		Or (Specifics.CanBeOutputParameters AND TreeRow.IsOutputParameter) Then
		If Rows.Action = "Move" Then
			Rows.ReasonDenied = NStr("ru = 'Параметры не могут быть перемещены.'; en = 'Parameters cannot be moved.'; pl = 'Parametry nie mogą zostać przesłane.';de = 'Parameter können nicht übertragen werden.';ro = 'Parametrii nu pot fi transferați.';tr = 'Parametreler aktarılamadı.'; es_ES = 'No se puede transferir los parámetros.'");
		ElsIf Rows.Action = "Group" Then
			Rows.ReasonDenied = NStr("ru = 'Параметры не могут быть участниками групп.'; en = 'Parameters cannot be group participants.'; pl = 'Parametry nie mogą być uczestnikami grupy.';de = 'Parameter können keine Gruppenteilnehmer sein.';ro = 'Parametrii nu pot fi participanți la grup.';tr = 'Parametreler grup katılımcısı olamaz.'; es_ES = 'Parámetros no pueden ser los participantes del grupo.'");
		ElsIf Rows.Action = "Delete" Then
			Rows.ReasonDenied = NStr("ru = 'Параметры не могут быть удалены.'; en = 'Parameters cannot be deleted.'; pl = 'Parametry nie mogą być usunięte.';de = 'Parameter können nicht gelöscht werden.';ro = 'Parametrii nu pot fi șterși.';tr = 'Parametreler silinemedi.'; es_ES = 'No se puede borrar los parámetros.'");
		EndIf;
		Return False;
	EndIf;
	If Specifics.RequireOneParent Then
		Parent = TreeRow.GetParent();
		If Rows.CurrentParent = -1 Then
			Rows.CurrentParent = Parent;
		ElsIf Rows.CurrentParent <> Parent Then
			If Rows.Action = "Move" Then
				Rows.ReasonDenied = NStr("ru = 'Выбранные элементы не могут быть перемещены, поскольку они принадлежат разным родителям.'; en = 'Cannot move selected items as they have different parents.'; pl = 'Nie można przenieść wybranych dokumentów, ponieważ mają one różnych ""rodziców"".';de = 'Die ausgewählten Elemente können nicht übertragen werden, da sie unterschiedliche Übergeordnete haben.';ro = 'Elementele selectate nu pot fi transferate deoarece au părinți diferiți.';tr = 'Seçilen öğeler farklı üst öğeleri olduğu için aktarılamaz.'; es_ES = 'Los artículos seleccionados no pueden transferirse porque tienen diferentes padres.'");
			ElsIf Rows.Action = "Group" Then
				Rows.ReasonDenied = NStr("ru = 'Выбранные элементы не могут быть сгруппированы, поскольку они принадлежат разным родителям.'; en = 'Cannot group selected items as they have different parents.'; pl = 'Nie można zgrupować wybranych dokumentów, ponieważ mają one różnych ""rodziców"".';de = 'Die ausgewählten Elemente können nicht gruppiert werden, da sie unterschiedliche Übergeordnete haben.';ro = 'Elementele selectate nu pot fi grupate deoarece au părinți diferiți.';tr = 'Seçilen öğeler farklı üst öğeleri olduğu için aktarılamaz.'; es_ES = 'Los artículos seleccionados no pueden agruparse porque tienen diferentes padres.'");
			EndIf;
			Return False; 
		EndIf;
	EndIf;
	Rows.TreeRows.Add(TreeRow);
	Return True; // Next row.
EndFunction

&AtClient
Procedure ShiftRows(Context)
	CurrentParent = Context.CurrentParent;
	DCNode = SettingsStructureItemProperty(Report.SettingsComposer, "Structure");
	
	If Context.CurrentParent = Undefined Then
		TableAttribute = ThisObject[Context.TableName];
		If Context.TableName = "Filters" AND Not SettingsStructureItemChangeMode Then
			CurrentParent = TableAttribute.GetItems()[1];
		Else
			CurrentParent = TableAttribute;
		EndIf;
		DCCurrentParent = DCNode;
	ElsIf TypeOf(CurrentParent.ID) <> Type("DataCompositionID") Then
		DCCurrentParent = DCNode;
	Else
		DCCurrentParent = DCNode.GetObjectByID(CurrentParent.ID);
	EndIf;
	ParentRows = CurrentParent.GetItems();
	DCParentRows = SettingsItems(DCNode, DCCurrentParent);
	
	UpperRowsBound = ParentRows.Count() - 1;
	RowsSelectedCount = Context.TreeRows.Count();
	
	// An array of selected rows towards the movement:
	// If we move rows to "+", we iterate from largest to smallest.
	// If we move rows to "-", we iterate from smallest to largest.
	MoveAsc = (Context.Direction < 0);
	
	For Number = 1 To RowsSelectedCount Do
		If MoveAsc Then 
			IndexInArray = Number - 1;
		Else
			IndexInArray = RowsSelectedCount - Number;
		EndIf;
		
		TreeRow = Context.TreeRows[IndexInArray];
		DCItem = DCNode.GetObjectByID(TreeRow.ID);
		
		IndexInTree = ParentRows.IndexOf(TreeRow);
		WhereRowWillBe = IndexInTree + Context.Direction;
		If WhereRowWillBe < 0 Then // Moving rows "to the end".
			ParentRows.Move(IndexInTree, UpperRowsBound - IndexInTree);
			DCParentRows.Move(DCItem, UpperRowsBound - IndexInTree);
		ElsIf WhereRowWillBe > UpperRowsBound Then // Moving rows "to the beginning".
			ParentRows.Move(IndexInTree, -IndexInTree);
			DCParentRows.Move(DCItem, -IndexInTree);
		Else
			ParentRows.Move(IndexInTree, Context.Direction);
			DCParentRows.Move(DCItem, Context.Direction);
		EndIf;
	EndDo;
	
	DetermineIfModified();
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Client - fields tables (universal entry points).

&AtClient
Procedure SelectDisplayMode(SettingsNodeFilters, CollectionName, RowID, ShowInputModes, ShowCheckBoxesModes, CurrentDisplayMode = Undefined)
	Context = New Structure("SettingsNodeFilters, CollectionName, RowID", SettingsNodeFilters, CollectionName, RowID);
	Handler = New NotifyDescription("DisplayModeAfterChoice", ThisObject, Context);
	
	List = New ValueList;
	If ShowInputModes Then
		List.Add("ShowInReportHeader", NStr("ru = 'В шапке отчета'; en = 'In report header'; pl = 'W nagłówku raportu';de = 'In Berichtskopfzeile';ro = 'În antetul raportului';tr = 'Rapor başlığında'; es_ES = 'En el encabezado del informe'"), , PictureLib.QuickAccess);
	EndIf;
	If ShowCheckBoxesModes Then
		List.Add("ShowOnlyCheckBoxInReportHeader", NStr("ru = 'Только флажок в шапке отчета'; en = 'Check box in report header'; pl = 'Tylko pole wyboru w nagłówku raportu';de = 'Nur Kontrollkästchen im Berichtstitel';ro = 'Doar caseta de validare din titlul raportului';tr = 'Sadece rapor başlığında onay kutusu'; es_ES = 'Solo la casilla de verificación en el título del informe'"), , PictureLib.QuickAccessWithFlag);
	EndIf;
	If ShowInputModes Then
		List.Add("ShowInReportSettings", NStr("ru = 'В настройках отчета'; en = 'In report settings'; pl = 'W ustawieniach raportu';de = 'In den Berichteinstellungen';ro = 'În setările raportului';tr = 'Rapor ayarlarında'; es_ES = 'En las configuraciones del informe'"), , PictureLib.Attribute);
	EndIf;
	If ShowCheckBoxesModes Then
		List.Add("ShowOnlyCheckBoxInReportSettings", NStr("ru = 'Только флажок в настройках отчета'; en = 'Check boxes in report settings'; pl = 'Tylko pole wyboru w ustawieniach raportu';de = 'Nur das Kontrollkästchen in den Berichteinstellungen';ro = 'Doar caseta de selectare din setările raportului';tr = 'Sadece rapor başlığında onay kutusu'; es_ES = 'Solo la casilla de verificación en las configuraciones del informe'"), , PictureLib.NormalAccessWithCheckBox);
	EndIf;
	List.Add("DontShow", NStr("ru = 'Не показывать'; en = 'Do not show'; pl = 'Nie pokazywać';de = 'Nicht zeigen';ro = 'Nu afișa';tr = 'Gösterme'; es_ES = 'No mostrar'"), , PictureLib.HiddenReportSettingsItem);
	
	If CurrentDisplayMode = Undefined Then
		ShowChooseFromMenu(Handler, List);
	Else
		DisplayMode = List.FindByValue(CurrentDisplayMode);
		ExecuteNotifyProcessing(Handler, DisplayMode);
	EndIf;
EndProcedure

&AtClient
Procedure DisplayModeAfterChoice(DisplayMode, Context) Export
	If DisplayMode = Undefined Then
		Return;
	EndIf;
	
	If DisplayMode.Value = "ShowInReportHeader" Then
		DisplayModePicture = 2;
	ElsIf DisplayMode.Value = "ShowOnlyCheckBoxInReportHeader" Then
		DisplayModePicture = 1;
	ElsIf DisplayMode.Value = "ShowInReportSettings" Then
		DisplayModePicture = 4;
	ElsIf DisplayMode.Value = "ShowOnlyCheckBoxInReportSettings" Then
		DisplayModePicture = 3;
	Else
		DisplayModePicture = 5;
	EndIf;
	
	Row = ThisObject[Context.CollectionName].FindByID(Context.RowID);
	If Row = Undefined Then
		Return;
	EndIf;
	
	SettingItem = Context.SettingsNodeFilters.GetObjectByID(Row.ID);
	If SettingItem = Undefined Then
		Return;
	EndIf;
	
	SetDisplayMode(Context.CollectionName, Row, SettingItem, DisplayModePicture);
	
	DetermineIfModified();
EndProcedure

&AtClient
Procedure SetDisplayMode(CollectionName, Row, SettingItem, DisplayModePicture = Undefined)
	If DisplayModePicture = Undefined Then
		DisplayModePicture = Row.DisplayModePicture;
	Else
		Row.DisplayModePicture = DisplayModePicture;
	EndIf;
	
	If DisplayModePicture = 1 Or DisplayModePicture = 2 Then
		SettingItem.ViewMode = DataCompositionSettingsItemViewMode.QuickAccess;
	ElsIf DisplayModePicture = 3 Or DisplayModePicture = 4 Then
		SettingItem.ViewMode = DataCompositionSettingsItemViewMode.Normal;
	Else
		SettingItem.ViewMode = DataCompositionSettingsItemViewMode.Inaccessible;
	EndIf;
	
	If CollectionName = "Filters" AND Not Row.IsParameter Then
		If DisplayModePicture = 1 Or DisplayModePicture = 3 Then
			// If UserSettingPresentation is filled in, the Presentation acts as radio buttons and can also be 
			// used for output to a spreadsheet document.
			// 
			SettingItem.Presentation = Row.Title;
		Else
			SettingItem.Presentation = "";
		EndIf;
		
		If Not Row.IsPredefinedTitle Then
			SettingItem.UserSettingPresentation = Row.Title;
		EndIf;
	ElsIf CollectionName = "Appearance" Then
		// CA feature: UserSettingPresentation can be cleared after GetSettings().
		If Row.IsPredefinedTitle Then
			If DisplayModePicture = 1 Or DisplayModePicture = 3 Then
				// If UserSettingPresentation is filled in, the Presentation acts as radio buttons and can also be 
				// used for output to a spreadsheet document.
				// 
				SettingItem.Presentation = Row.Title;
			Else
				SettingItem.Presentation = "";
			EndIf;
		Else
			// If UserSettingPresentation is filled in, the Presentation acts as radio buttons and can also be 
			// used for output to a spreadsheet document.
			// 
			SettingItem.Presentation = Row.Title;
		EndIf;
	EndIf;
	
	If SettingItem.ViewMode = DataCompositionSettingsItemViewMode.Inaccessible Then
		SettingItem.UserSettingID = "";
	ElsIf Not ValueIsFilled(SettingItem.UserSettingID) Then
		SettingItem.UserSettingID = New UUID;
	EndIf;
EndProcedure

&AtClientAtServerNoContext
Function SettingItemDisplayModePicture(SettingItem)
	DisplayModePicture = 5;
	
	If ValueIsFilled(SettingItem.UserSettingID) Then
		If SettingItem.ViewMode = DataCompositionSettingsItemViewMode.QuickAccess Then
			If TypeOf(SettingItem) = Type("DataCompositionSettingsParameterValue")
				Or TypeOf(SettingItem) = Type("DataCompositionConditionalAppearanceItem") Then 
				DisplayModePicture = 2;
			Else
				DisplayModePicture = ?(ValueIsFilled(SettingItem.Presentation), 1, 2);
			EndIf;
		ElsIf SettingItem.ViewMode = DataCompositionSettingsItemViewMode.Normal Then
			If TypeOf(SettingItem) = Type("DataCompositionSettingsParameterValue")
				Or TypeOf(SettingItem) = Type("DataCompositionConditionalAppearanceItem") Then 
				DisplayModePicture = 4;
			Else
				DisplayModePicture = ?(ValueIsFilled(SettingItem.Presentation), 3, 4);
			EndIf;
		EndIf;
	EndIf;
	
	Return DisplayModePicture;
EndFunction

////////////////////////////////////////////////////////////////////////////////
// Client - fields tables (functional part).

&AtClientAtServerNoContext
Function SettingItem(Val SettingsNode, Val Row)
	SettingItem = Undefined;
	
	If Row <> Undefined
		AND TypeOf(Row.ID) = Type("DataCompositionID") Then
		
		SettingItem = SettingsNode.GetObjectByID(Row.ID);
	EndIf;
	
	If TypeOf(SettingItem) = Type("DataCompositionNestedObjectSettings") Then
		SettingItem = SettingItem.Settings;
	EndIf;
	
	Return SettingItem;
EndFunction

&AtClientAtServerNoContext
Function SettingsItems(Val StructureItemProperty, Val SettingItem = Undefined, CollectionName = Undefined)
	If SettingItem = Undefined Then
		SettingItem = StructureItemProperty;
	EndIf;
	
	If CollectionName <> Undefined
		AND StrSplit("Rows, Columns, Series, Points", ", ", False).Find(CollectionName) <> Undefined Then 
		Return SettingItem[CollectionName];
	EndIf;
	
	ObjectType = TypeOf(SettingItem);
	If ObjectType = Type("DataCompositionSettings")
		Or ObjectType = Type("DataCompositionGroup")
		Or ObjectType = Type("DataCompositionTableGroup")
		Or ObjectType = Type("DataCompositionChartGroup") Then
		
		Return SettingItem.Structure;
	ElsIf ObjectType = Type("DataCompositionSettingStructureItemCollection")
		Or ObjectType = Type("DataCompositionTableStructureItemCollection")
		Or ObjectType = Type("DataCompositionChartStructureItemCollection") Then
		
		Return SettingItem;
	ElsIf ObjectType = Type("DataCompositionNestedObjectSettings") Then 
		
		Return SettingItem.Settings.Structure;
	EndIf;
	
	Return SettingItem.Items;
EndFunction

&AtClient
Function SettingsCollectionNameByID(ID)
	CollectionName = Undefined;
	
	Path = Upper(ID);
	If StrFind(Path, "SERIES") > 0 Then 
		CollectionName = "Series";
	ElsIf StrFind(Path, "POINT") > 0 Then 
		CollectionName = "Points";
	ElsIf StrFind(Path, "ROW") > 0 Then 
		CollectionName = "Rows";
	ElsIf StrFind(Path, "COLUMN") > 0 Then 
		CollectionName = "Columns";
	EndIf;
	
	Return CollectionName;
EndFunction

&AtClient
Function GetSettingItemParent(Val StructureItemProperty, Val SettingItem)
	Parent = Undefined;
	
	ItemType = TypeOf(SettingItem);
	If SettingItem <> Undefined
		AND ItemType <> Type("DataCompositionGroupField")
		AND ItemType <> Type("DataCompositionAutoOrderItem")
		AND ItemType <> Type("DataCompositionOrderItem")
		AND ItemType <> Type("DataCompositionConditionalAppearanceItem")
		AND ItemType <> Type("DataCompositionTableStructureItemCollection") Then 
		Parent = SettingItem.Parent;
	EndIf;
	
	If Parent = Undefined Then 
		Parent = StructureItemProperty;
	EndIf;
	
	Return Parent;
EndFunction

&AtClientAtServerNoContext
Function GetItems(Val Tree, Val Row)
	If Row = Undefined Then
		Row = Tree;
	EndIf;
	Return Row.GetItems();
EndFunction

&AtClient
Function GetParent(Val CollectionName, Val Row = Undefined)
	Parent = Undefined;
	
	If Row <> Undefined Then
		Parent = Row.GetParent();
	EndIf;
	
	If Parent = Undefined Then
		Parent = DefaultRootRow(CollectionName);
	EndIf;
	
	If Parent = Undefined Then
		Parent = ThisObject[CollectionName];
	EndIf;
	
	Return Parent;
EndFunction

&AtClient
Function DefaultRootRow(Val CollectionName)
	RootRow = Undefined;
	
	If CollectionName = "SelectedFields" Then
		RootRow = SelectedFields.GetItems()[0];
	ElsIf CollectionName = "Sort" Then
		RootRow = Sort.GetItems()[0];
	ElsIf CollectionName = "OptionStructure" Then
		RootRow = OptionStructure.GetItems()[0];
	ElsIf CollectionName = "Parameters" Then
		If Not SettingsStructureItemChangeMode Then
			RootRow = Filters.GetItems()[0];
		EndIf;
	ElsIf CollectionName = "Filters" Then
		If SettingsStructureItemChangeMode Then
			RootRow = Filters.GetItems()[0];
		Else
			RootRow = Filters.GetItems()[1];
		EndIf;
	ElsIf CollectionName = "Appearance" Then
		If Not SettingsStructureItemChangeMode Then 
			RootRow = Appearance.GetItems()[2];
		EndIf;
	EndIf;
	
	Return RootRow;
EndFunction

&AtClient
Procedure SelectField(CollectionName, Handler, Field = Undefined, SettingsNodeID = Undefined)
	ChoiceParameters = New Structure;
	ChoiceParameters.Insert("ReportSettings", ReportSettings);
	ChoiceParameters.Insert("SettingsComposer", Report.SettingsComposer);
	ChoiceParameters.Insert("Mode", CollectionName);
	ChoiceParameters.Insert("DCField", Field);
	ChoiceParameters.Insert("SettingsStructureItemID", 
		?(SettingsNodeID = Undefined, SettingsStructureItemID, SettingsNodeID));
	
	OpenForm(
		"SettingsStorage.ReportsVariantsStorage.Form.SelectReportField",
		ChoiceParameters, ThisObject, UUID,,, Handler, FormWindowOpeningMode.LockOwnerWindow);
EndProcedure

&AtClient
Procedure UpdateOptionStructureItemTitle(Row)
	StructureItemProperty = SettingsStructureItemProperty(Report.SettingsComposer, "Structure");
	
	SettingItem = SettingItem(StructureItemProperty, Row);
	If SettingItem = Undefined Then
		Return;
	EndIf;
	
	ParameterValue = SettingItem.OutputParameters.FindParameterValue(New DataCompositionParameter("OutputTitle"));
	If ParameterValue <> Undefined Then
		ParameterValue.Use = True;
		If ValueIsFilled(Row.Title) Then
			ParameterValue.Value = DataCompositionTextOutputType.Output;
		Else
			ParameterValue.Value = DataCompositionTextOutputType.DontOutput;
		EndIf;
	EndIf;
	
	ParameterValue = SettingItem.OutputParameters.FindParameterValue(New DataCompositionParameter("Title"));
	If ParameterValue <> Undefined Then
		ParameterValue.Use = True;
		ParameterValue.Value = Row.Title;
	EndIf;
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Client or server

&AtClientAtServerNoContext
Function ArraySort(SourceArray, Direction = Undefined)
	If Direction = Undefined Then 
		Direction = SortDirection.Asc;
	EndIf;
	
	List = New ValueList;
	List.LoadValues(SourceArray);
	List.SortByValue(Direction);
	
	Return List.UnloadValues();
EndFunction

////////////////////////////////////////////////////////////////////////////////
// Server call

&AtServer
Procedure UpdateForm(UpdateParameters = Undefined)
	ContainsNestedReports = False;
	ContainsNestedFilters = False;
	ContainsNestedFieldsOrSorting = False;
	ContainsNestedConditionalAppearance = False;
	ContainsUserStructureItems = False;
	
	ImportSettingsToComposer(UpdateParameters);
	
	If ExtendedMode = 0 Then 
		ReportsServer.UpdateSettingsFormItems(ThisObject, Items.Main, UpdateParameters);
	EndIf;
	
	UpdateSettingsFormCollections();
	
	SetChartType();
	UpdateFormItemsProperties();
EndProcedure

&AtServer
Procedure UpdateSettingsFormCollections()
	// Clearing settings.
	GroupComposition.GetItems().Clear();
	Filters.GetItems().Clear();
	SelectedFields.GetItems().Clear();
	Sort.GetItems().Clear();
	Appearance.GetItems().Clear();
	OptionStructure.GetItems().Clear();
	
	SetChartType();
	
	// Updating settings.
	UpdateGroupFields();
	UpdateDataParameters();
	UpdateFilters();
	UpdateSelectedFields();
	UpdateSorting();
	UpdateAppearance();
	UpdateStructure();
	
	// Searching for items marked for deletion.
	MarkedForDeletion.Clear();
	FindFieldsMarkedForDeletion();
EndProcedure

&AtServer
Procedure SetChartType()
	Items.CurrentChartType.Visible = False;
	
	If SettingsStructureItemType <> "DataCompositionChart" Then
		Return;
	EndIf;
	
	Items.CurrentChartType.TypeRestriction = New TypeDescription("ChartType");
	
	StructureItem = Report.SettingsComposer.Settings.GetObjectByID(SettingsStructureItemID);
	If TypeOf(StructureItem) = Type("DataCompositionNestedObjectSettings") Then
		StructureItem = StructureItem.Settings;
	EndIf;
	
	SettingItem = StructureItem.OutputParameters.FindParameterValue(New DataCompositionParameter("ChartType"));
	If SettingItem <> Undefined Then
		CurrentChartType = SettingItem.Value;
	EndIf;
	
	Items.CurrentChartType.Visible = (SettingItem <> Undefined);
EndProcedure

&AtServer
Procedure UpdateFormItemsProperties()
	SettingsComposer = Report.SettingsComposer;
	
	#Region CommonItemsPropertiesFlags
	
	IsExtendedMode = Boolean(ExtendedMode);
	DisplayInformation = IsExtendedMode AND Not SettingsStructureItemChangeMode;
	
	#EndRegion
	
	#Region SimpleEditModeItemsProperties
	
	Items.Main.Visible = Not IsExtendedMode;
	Items.More.Visible = Not IsExtendedMode;
	
	Items.OutputTitle.Visible = Not IsExtendedMode;
	Items.DisplayParametersAndFilters.Visible = Not IsExtendedMode;
	
	#EndRegion
	
	#Region GroupContentPageItemsProperties
	
	DisplayGroupContent = (IsExtendedMode
		AND SettingsStructureItemChangeMode
		AND SettingsStructureItemType <> "DataCompositionChart");
	
	Items.GroupingContentPage.Visible = DisplayGroupContent;
	Items.GroupContentCommands.Visible = DisplayGroupContent;
	Items.GroupComposition.Visible = DisplayGroupContent;
	
	#EndRegion
	
	#Region FiltersPageItemsProperties
	
	DisplayFilters = (IsExtendedMode
		AND SettingsStructureItemType <> "DataCompositionChart");
	
	If IsExtendedMode Then
		Items.FiltersPage.Title = NStr("ru = 'Отборы'; en = 'Filters'; pl = 'Filtry';de = 'Filter';ro = 'Filtre';tr = 'Filtreler'; es_ES = 'Selecciones'");
	Else
		Items.FiltersPage.Title = NStr("ru = 'Основное'; en = 'Main'; pl = 'Główne';de = 'Haupt';ro = 'Principale';tr = 'Hızlı Menü'; es_ES = 'Principal'");
	EndIf;
	
	Items.Filters.Visible = DisplayFilters;
	Items.HasNestedFiltersGroup.Visible = DisplayFilters;
	Items.HasNestedFiltersGroup.Visible = DisplayFilters
		AND ContainsNestedFilters
		AND DisplayInformation;
	
	#EndRegion
	
	#Region  FieldsAndSortingPageItemsProperties
	
	StructureItemProperty = SettingsStructureItemProperty(
		SettingsComposer, "Selection", SettingsStructureItemID, ExtendedMode);
	DisplaySelectedFields =
		StructureItemProperty <> Undefined
		AND (ValueIsFilled(StructureItemProperty.UserSettingID) Or IsExtendedMode);
	
	StructureItemProperty = SettingsStructureItemProperty(
		SettingsComposer, "Order", SettingsStructureItemID, ExtendedMode);
	DisplaySorting =
		SettingsStructureItemType <> "DataCompositionChart"
		AND StructureItemProperty <> Undefined
		AND (ValueIsFilled(StructureItemProperty.UserSettingID) Or IsExtendedMode);
	
	If DisplaySelectedFields AND DisplaySorting Then
		Items.SelectedFieldsAndSortingsPage.Title = NStr("ru = 'Поля и сортировки'; en = 'Fields and sorts'; pl = 'Pola i sortowanie';de = 'Felder und Sortierungen';ro = 'Câmpuri și sortări';tr = 'Alanlar ve filtreler'; es_ES = 'Campos y clasificaciones'");
	ElsIf DisplaySelectedFields Then
		Items.SelectedFieldsAndSortingsPage.Title = NStr("ru = 'Поля'; en = 'Fields'; pl = 'Pola';de = 'Felder';ro = 'Câmpuri';tr = 'Alanlar'; es_ES = 'Campos'");
	ElsIf DisplaySorting Then
		Items.SelectedFieldsAndSortingsPage.Title = NStr("ru = 'Сортировки'; en = 'Sorts'; pl = 'Sortowanie';de = 'Sortierungen';ro = 'Sortări';tr = 'Filtreler'; es_ES = 'Clasificaciones'");
	EndIf;
	
	Items.SelectedFields.Visible = DisplaySelectedFields;
	Items.SelectedFieldsCommands_AddDelete.Visible = DisplaySelectedFields AND IsExtendedMode;
	Items.SelectedFieldsCommands_AddDelete1.Visible = DisplaySelectedFields AND IsExtendedMode;
	Items.SelectedFieldsCommands_Groups.Visible = DisplaySelectedFields AND IsExtendedMode;
	Items.SelectedFieldsCommands_Groups1.Visible = DisplaySelectedFields AND IsExtendedMode;
	
	Items.FieldsAndSortingCommands.Visible = DisplaySelectedFields AND DisplaySorting;
	
	Items.Sort.Visible = DisplaySorting;
	Items.SortingCommands_AddDelete.Visible = DisplaySorting AND IsExtendedMode;
	Items.SortingCommands_AddDelete1.Visible = DisplaySorting AND IsExtendedMode;
	
	Items.HasNestedFieldsOrSortingGroup.Visible = ContainsNestedFieldsOrSorting AND DisplayInformation;
	
	#EndRegion
	
	#Region AppearancePageItemsProperties
	
	DisplayAppearance = IsExtendedMode;
	Items.Appearance.Visible = DisplayAppearance;
	Items.HasNestedAppearanceGroup.Visible = DisplayAppearance
		AND ContainsNestedConditionalAppearance
		AND DisplayInformation;
	
	#EndRegion
	
	#Region OptionStructurePageItemsProperties
	
	DisplayOptionStructure = (ContainsUserStructureItems Or IsExtendedMode)
		AND Not SettingsStructureItemChangeMode;
	Items.OptionStructurePage.Visible = DisplayOptionStructure;
	
	Items.OptionStructureCommands_Add.Visible = IsExtendedMode;
	Items.OptionStructureCommands_Add1.Visible = IsExtendedMode;
	Items.OptionStructureCommands_Change.Visible = IsExtendedMode;
	Items.OptionStructureCommands_Change1.Visible = IsExtendedMode;
	Items.OptionStructureCommands_MoveHierarchically.Visible = IsExtendedMode;
	Items.OptionStructureCommands_MoveHierarchically1.Visible = IsExtendedMode;
	Items.OptionStructureCommands_MoveInsideParent.Visible = IsExtendedMode;
	Items.OptionStructureCommands_MoveInsideParent1.Visible = IsExtendedMode;
	
	Items.OptionStructure.ChangeRowSet = IsExtendedMode;
	Items.OptionStructure.ChangeRowOrder = IsExtendedMode;
	Items.OptionStructure.EnableStartDrag = IsExtendedMode;
	Items.OptionStructure.EnableDrag = IsExtendedMode;
	Items.OptionStructure.Header = IsExtendedMode;
	
	Items.OptionStructureTitle.Visible = IsExtendedMode;
	
	Items.OptionStructureContainsFilters.Visible = IsExtendedMode;
	Items.OptionStructureContainsFieldsOrSorting.Visible = IsExtendedMode;
	Items.OptionStructureContainsConditionalAppearance.Visible = IsExtendedMode;
	
	#EndRegion
	
	#Region CommonItemsProperties
	
	If Not IsExtendedMode
		AND IsMobileClient Then 
		DisplayPages = False;
	Else
		DisplayPages =
			DisplayGroupContent
			Or DisplayFilters
			Or DisplaySelectedFields
			Or DisplaySorting
			Or DisplayAppearance
			Or DisplayOptionStructure;
	EndIf;
	
	If DisplayPages Then 
		Items.SettingsPages.PagesRepresentation = FormPagesRepresentation.TabsOnTop;
	Else
		Items.SettingsPages.CurrentPage = Items.FiltersPage;
		Items.SettingsPages.PagesRepresentation = FormPagesRepresentation.None;
	EndIf;
	
	Items.HasNestedReportsGroup.Visible = ContainsNestedReports AND DisplayInformation;
	Items.HasNonexistentFieldsGroup.Visible =  MarkedForDeletion.Count() > 0 AND DisplayInformation;
	
	Items.ExtendedMode.Visible = ReportSettings.EditOptionsAllowed AND Not SettingsStructureItemChangeMode;
	Items.EditFilterCriteria.Visible = AllowEditingFiltersConditions();
	
	If SettingsStructureItemChangeMode Then
		Items.GenerateAndClose.Title = NStr("ru = 'Завершить редактирование'; en = 'Finish editing'; pl = 'Zakończ edycję';de = 'Bearbeitung abschließen';ro = 'Finalizare editarea';tr = 'Düzenlemeyi bitir'; es_ES = 'Terminar de editar'");
		Items.Close.Title = NStr("ru = 'Отмена'; en = 'Cancel'; pl = 'Anulowanie';de = 'Abbrechen';ro = 'Revocare';tr = 'İptal'; es_ES = 'Cancelar'");
	Else
		Items.GenerateAndClose.Title = NStr("ru = 'Закрыть и сформировать'; en = 'Close and generate'; pl = 'Zamknij i wygeneruj';de = 'Schließen und generieren';ro = 'Închide și generează';tr = 'Kapat ve oluştur'; es_ES = 'Cerrar y generar'");
		Items.Close.Title = NStr("ru = 'Закрыть'; en = 'Close'; pl = 'Zamknij';de = 'Schließen';ro = 'Închide';tr = 'Kapat'; es_ES = 'Cerrar'");
	EndIf;
	
	CountOfAvailableSettings = ReportsServer.CountOfAvailableSettings(Report.SettingsComposer);
	Items.GenerateAndClose.Visible = CountOfAvailableSettings.Total > 0 Or DisplayPages;
	
	#EndRegion
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Server

&AtServer
Procedure DefineBehaviorInMobileClient()
	IsMobileClient = Common.IsMobileClient();
	If Not IsMobileClient Then 
		Return;
	EndIf;
	
	CommandBarLocation = FormCommandBarLabelLocation.Auto;
	Items.GenerateAndClose.Representation = ButtonRepresentation.Picture;
EndProcedure

&AtServer
Procedure SetConditionalAppearance()
	ConditionalAppearance.Items.Clear();
	
	#Region ConditionalTableAppearanceOfGroupContentForm
	
	// ShowAdditionType = True.
	//
	Item = ConditionalAppearance.Items.Add();
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("GroupComposition.ShowAdditionType");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	Item.Appearance.SetParameterValue("Visible", False);
	Item.Appearance.SetParameterValue("Show", False);
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GroupContentGroupType.Name);
	
	// ShowAdditionType = False.
	//
	Item = ConditionalAppearance.Items.Add();
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("GroupComposition.ShowAdditionType");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	Item.Appearance.SetParameterValue("Visible", False);
	Item.Appearance.SetParameterValue("Show", False);
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GroupContentAdditionType.Name);
	
	// Field = Undefined.
	//
	Item = ConditionalAppearance.Items.Add();
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("GroupComposition.Field");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Undefined;
	
	Item.Appearance.SetParameterValue("Visible", False);
	Item.Appearance.SetParameterValue("Show", False);
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GroupContentGroupType.Name);
	
	// Title - filled in.
	//
	Item = ConditionalAppearance.Items.Add();
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("GroupComposition.Title");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	
	Item.Appearance.SetParameterValue("Text", New DataCompositionField("GroupComposition.Title"));
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GroupContentField.Name);
	
	#EndRegion
	
	#Region ConditionalTableAppearanceOfFiltersForm
	
	// IsSection = True.
	//
	Item = ConditionalAppearance.Items.Add();
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Filters.IsSection");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	Item.Appearance.SetParameterValue("ReadOnly", True);
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.FiltersParameter.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.FiltersComparisonType.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.FiltersValue.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.FiltersDisplayModePicture.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.FiltersUserSettingPresentation.Name);
	
	//
	Item = ConditionalAppearance.Items.Add();
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Filters.IsSection");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	Item.Appearance.SetParameterValue("Visible", False);
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.FiltersGroupType.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.FiltersLeftValue.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.FiltersRightValue.Name);
	
	//
	Item = ConditionalAppearance.Items.Add();
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Filters.IsSection");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	Item.Appearance.SetParameterValue("Show", False);
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.FiltersUsage.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.FiltersGroupType.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.FiltersLeftValue.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.FiltersComparisonType.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.FiltersValue.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.FiltersDisplayModePicture.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.FiltersUserSettingPresentation.Name);
	
	// IsParameter = True.
	//
	Item = ConditionalAppearance.Items.Add();
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Filters.IsParameter");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	Item.Appearance.SetParameterValue("ReadOnly", True);
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.FiltersParameter.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.FiltersComparisonType.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.FiltersDisplayModePicture.Name);
	
	//
	Item = ConditionalAppearance.Items.Add();
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Filters.IsParameter");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	Item.Appearance.SetParameterValue("Visible", False);
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.FiltersGroupType.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.FiltersLeftValue.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.FiltersRightValue.Name);
	
	//
	Item = ConditionalAppearance.Items.Add();
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Filters.IsParameter");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	Item.Appearance.SetParameterValue("Show", False);
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.FiltersGroupType.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.FiltersComparisonType.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.FiltersLeftValue.Name);
	
	// IsPeriod = True.
	//
	Item = ConditionalAppearance.Items.Add();
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Filters.IsPeriod");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	Item.Appearance.SetParameterValue("ReadOnly", True);
	Item.Appearance.SetParameterValue("Show", False);
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.FiltersComparisonType.Name);
	
	// DisplayUsage = False.
	//
	Item = ConditionalAppearance.Items.Add();
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Filters.DisplayUsage");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	Item.Appearance.SetParameterValue("Visible", False);
	Item.Appearance.SetParameterValue("ReadOnly", True);
	Item.Appearance.SetParameterValue("Show", False);
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.FiltersUsage.Name);
	
	// IsSection = False; IsParameter = False; IsGroup = False - this is a filter item.
	//
	Item = ConditionalAppearance.Items.Add();
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Filters.IsSection");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Filters.IsParameter");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Filters.IsFolder");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	Item.Appearance.SetParameterValue("ReadOnly", True);
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.FiltersLeftValue.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.FiltersDisplayModePicture.Name);
	
	//
	Item = ConditionalAppearance.Items.Add();
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Filters.IsSection");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Filters.IsParameter");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Filters.IsFolder");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	Item.Appearance.SetParameterValue("Visible", False);
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.FiltersParameter.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.FiltersGroupType.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.FiltersValue.Name);
	
	//
	Item = ConditionalAppearance.Items.Add();
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Filters.IsSection");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Filters.IsParameter");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Filters.IsFolder");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	Item.Appearance.SetParameterValue("Show", False);
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.FiltersParameter.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.FiltersGroupType.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.FiltersValue.Name);
	
	// IsGroup = True.
	//
	Item = ConditionalAppearance.Items.Add();
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Filters.IsFolder");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	Item.Appearance.SetParameterValue("ReadOnly", True);
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.FiltersGroupType.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.FiltersDisplayModePicture.Name);
	
	//
	Item = ConditionalAppearance.Items.Add();
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Filters.IsFolder");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	Item.Appearance.SetParameterValue("Visible", False);
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.FiltersParameter.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.FiltersLeftValue.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.FiltersValue.Name);
	
	//
	Item = ConditionalAppearance.Items.Add();
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Filters.IsFolder");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	Item.Appearance.SetParameterValue("Show", False);
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.FiltersParameter.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.FiltersLeftValue.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.FiltersComparisonType.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.FiltersValue.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.FiltersRightValue.Name);
	
	//
	Item = ConditionalAppearance.Items.Add();
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Filters.IsFolder");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Filters.Title");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	Item.Appearance.SetParameterValue("Text", New DataCompositionField("Filters.GroupType"));
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.FiltersUserSettingPresentation.Name);
	
	// IsUUID = True.
	//
	Item = ConditionalAppearance.Items.Add();
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Filters.IsUUID");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	Item.Appearance.SetParameterValue("ReadOnly", True);
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.FiltersRightValue.Name);
	
	// Title - filled in.
	//
	Item = ConditionalAppearance.Items.Add();
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Filters.Title");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	
	Item.Appearance.SetParameterValue("Text", New DataCompositionField("Filters.Title"));
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.FiltersParameter.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.FiltersGroupType.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.FiltersLeftValue.Name);
	
	// ValuePresentation - filled in.
	//
	Item = ConditionalAppearance.Items.Add();
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Filters.ValuePresentation");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	
	Item.Appearance.SetParameterValue("Text", New DataCompositionField("Filters.ValuePresentation"));
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.FiltersValue.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.FiltersRightValue.Name);
	
	// IsPredefinedTitle = True.
	//
	Item = ConditionalAppearance.Items.Add();
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Filters.IsPredefinedTitle");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.InaccessibleCellTextColor);
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.FiltersUserSettingPresentation.Name);
	
	#EndRegion
	
	#Region ConditionalTableAppearanceOfSelectedFieldsForm
	
	// IsSection = True.
	//
	Item = ConditionalAppearance.Items.Add();
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("SelectedFields.IsSection");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	Item.Appearance.SetParameterValue("Visible", False);
	Item.Appearance.SetParameterValue("Show", False);
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.SelectedFieldsUsage.Name);
	
	// Title - filled in.
	//
	Item = ConditionalAppearance.Items.Add();
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("SelectedFields.Title");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	
	Item.Appearance.SetParameterValue("Text", New DataCompositionField("SelectedFields.Title"));
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.SelectedFieldsField.Name);
	
	#EndRegion
	
	#Region ConditionalTableAppearanceOfSortingForm
	
	// IsSection = True.
	//
	Item = ConditionalAppearance.Items.Add();
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Sort.IsSection");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	Item.Appearance.SetParameterValue("Visible", False);
	Item.Appearance.SetParameterValue("Show", False);
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.SortingUsage.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.SortingOrderType.Name);
	
	// IsAutoField = True.
	//
	Item = ConditionalAppearance.Items.Add();
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Sort.IsAutoField");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	Item.Appearance.SetParameterValue("Visible", False);
	Item.Appearance.SetParameterValue("Show", False);
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.SortingOrderType.Name);
	
	// Title - filled in.
	//
	Item = ConditionalAppearance.Items.Add();
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Sort.Title");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	
	Item.Appearance.SetParameterValue("Text", New DataCompositionField("Sort.Title"));
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.SortingField.Name);
	
	#EndRegion
	
	#Region ConditionalTableAppearanceOfAppearanceForm
	
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.AppearanceTitle.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.AppearanceAccessPictureIndex.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Appearance.IsOutputParameter");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;

	Item.Appearance.SetParameterValue("ReadOnly", True);
	
	//
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.AppearanceUsage.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.AppearanceTitle.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.AppearanceAccessPictureIndex.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Appearance.IsSection");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;

	Item.Appearance.SetParameterValue("ReadOnly", True);
	
	#EndRegion
	
	#Region ConditionalTableAppearanceOfOptionStructureForm
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("OptionStructure.IsFolder");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	Item.Appearance.SetParameterValue("Font", New Font(,, True));
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.OptionStructurePresentation.Name);

	//
	Item = ConditionalAppearance.Items.Add();
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("OptionStructure.Title");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("ExtendedMode");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = 0;
	
	Item.Appearance.SetParameterValue("Text", New DataCompositionField("OptionStructure.Title"));
	Item.Appearance.SetParameterValue("Font", New Font(,, True));
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.OptionStructurePresentation.Name);
	
	//
	Item = ConditionalAppearance.Items.Add();
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("OptionStructure.AvailableFlag");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	Item.Appearance.SetParameterValue("Visible", False);
	Item.Appearance.SetParameterValue("Show", False);
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.OptionStructureUsage.Name);
	
	#EndRegion
EndProcedure

&AtServer
Procedure ImportSettingsToComposer(ImportParameters)
	CheckImportParameters(ImportParameters);
	
	AvailableSettings = ReportsServer.AvailableSettings(ImportParameters, ReportSettings);
	
	UpdateOptionSettings = CommonClientServer.StructureProperty(ImportParameters, "UpdateOptionSettings", False);
	If UpdateOptionSettings Then
		AvailableSettings.Settings = Report.SettingsComposer.GetSettings();
		Report.SettingsComposer.LoadFixedSettings(New DataCompositionSettings);
		AvailableSettings.FixedSettings = Report.SettingsComposer.FixedSettings;
	EndIf;
	
	ClearUserSettings = CommonClientServer.StructureProperty(ImportParameters, "ResetUserSettings", False);
	If ClearUserSettings Then
		AvailableSettings.UserSettings = New DataCompositionUserSettings;
	EndIf;
	
	ReportObject = ReportsServer.ReportObject(ImportParameters.ReportObjectOrFullName);
	If ReportSettings.Events.BeforeImportSettingsToComposer Then
		ReportObject.BeforeImportSettingsToComposer(
			ThisObject,
			ReportSettings.SchemaKey,
			CurrentVariantKey,
			AvailableSettings.Settings,
			AvailableSettings.UserSettings);
	EndIf;
	
	SettingsAreImported = ReportsClientServer.LoadSettings(
		Report.SettingsComposer,
		AvailableSettings.Settings,
		AvailableSettings.UserSettings,
		AvailableSettings.FixedSettings);
	
	// Fixed filters are set via the composer as it has the most complete collection of settings.
	// In BeforeImport parameters, some parameters can be missing if their settings were not overridden.
	If SettingsAreImported AND TypeOf(ParametersForm.Filter) = Type("Structure") Then
		ReportsServer.SetFixedFilters(ParametersForm.Filter, AvailableSettings.Settings, ReportSettings);
	EndIf;
	
	If ParametersForm.Property("FixedSettings") Then 
		ParametersForm.FixedSettings = Report.SettingsComposer.FixedSettings;
	EndIf;
	
	ReportsServer.SetAvailableValues(ReportObject, ThisObject);
	ReportsServer.InitializePredefinedOutputParameters(ReportSettings, AvailableSettings.Settings);
	
	FiltersConditions = CommonClientServer.StructureProperty(ImportParameters, "FiltersConditions");
	If FiltersConditions <> Undefined Then
		UserSettings = Report.SettingsComposer.UserSettings;
		For Each Condition In FiltersConditions Do
			UserSettingItem = UserSettings.GetObjectByID(Condition.Key);
			If UserSettingItem <> Undefined Then 
				UserSettingItem.ComparisonType = Condition.Value;
			EndIf;
		EndDo;
	EndIf;
	
	InitializePredefinedOutputParametersAttributes();
	SettingsComposer = Report.SettingsComposer;
	
	If ImportParameters.VariantModified Then
		OptionChanged = True;
	EndIf;
	
	If ImportParameters.UserSettingsModified Then
		UserSettingsModified = True;
	EndIf;
EndProcedure

&AtServer
Procedure CheckImportParameters(ImportParameters)
	If ImportParameters = Undefined Then 
		ImportParameters = New Structure;
	EndIf;
	
	If Not ImportParameters.Property("EventName") Then
		ImportParameters.Insert("EventName", "");
	EndIf;
	
	If Not ImportParameters.Property("VariantModified") Then
		ImportParameters.Insert("VariantModified", VariantModified);
	EndIf;
	
	If Not ImportParameters.Property("UserSettingsModified") Then
		ImportParameters.Insert("UserSettingsModified", UserSettingsModified);
	EndIf;
	
	If Not ImportParameters.Property("Result") Then
		ImportParameters.Insert("Result", New Structure);
	EndIf;
	
	If Not ImportParameters.Property("Result") Then
		ImportParameters.Insert("Result", New Structure);
		ImportParameters.Result.Insert("ExpandTreeNodes", New Array);
	EndIf;
	
	ImportParameters.Insert("Abort", False);
	ImportParameters.Insert("ReportObjectOrFullName", ReportSettings.FullName);
EndProcedure

&AtServer
Procedure InitializePredefinedOutputParametersAttributes()
	PredefinedParameters = Report.SettingsComposer.Settings.OutputParameters.Items;
	
	Object = PredefinedParameters.Find("TITLE");
	OutputTitle = Object.Use;
	
	Object = PredefinedParameters.Find("DATAPARAMETERSOUTPUT");
	LinkedObject = PredefinedParameters.Find("FILTEROUTPUT");
	
	DisplayParametersAndFilters = (Object.Value <> DataCompositionTextOutputType.DontOutput
		Or LinkedObject.Value <> DataCompositionTextOutputType.DontOutput);
EndProcedure

&AtServer
Function FullAttributeName(Attribute)
	Return ?(IsBlankString(Attribute.Path), "", Attribute.Path + ".") + Attribute.Name;
EndFunction

&AtClientAtServerNoContext
Function TypesDetailsWithoutPrimitiveOnes(InitialTypesDetails)
	RemovedTypes = New Array;
	If InitialTypesDetails.ContainsType(Type("String")) Then
		RemovedTypes.Add(Type("String"));
	EndIf;
	If InitialTypesDetails.ContainsType(Type("Date")) Then
		RemovedTypes.Add(Type("Date"));
	EndIf;
	If InitialTypesDetails.ContainsType(Type("Number")) Then
		RemovedTypes.Add(Type("Number"));
	EndIf;
	If RemovedTypes.Count() = 0 Then
		Return InitialTypesDetails;
	EndIf;
	Return New TypeDescription(InitialTypesDetails, , RemovedTypes);
EndFunction

&AtClient
Procedure RegisterList(Item, SettingItem)
	Value = Undefined;
	If TypeOf(SettingItem) = Type("DataCompositionSettingsParameterValue") Then 
		Value = SettingItem.Value;
	ElsIf TypeOf(SettingItem) = Type("DataCompositionFilterItem") Then 
		Value = SettingItem.RightValue;
	EndIf;

	If TypeOf(Value) <> Type("ValueList") Then 
		Return;
	EndIf;
	
	Index = SettingsComposer.UserSettings.Items.IndexOf(SettingItem);
	ListPath = PathToItemsData.ByIndex[Index];
	
	List = Items.Find(ListPath);
	List.TextColor = ?(SettingItem.Use, New Color, InactiveTableValueColor);
EndProcedure

&AtServer
Function AllowEditingFiltersConditions()
	If Boolean(ExtendedMode) Then 
		Return False;
	EndIf;
	
	SettingsComposer = Report.SettingsComposer;
	
	UserSettings = SettingsComposer.UserSettings;
	For Each UserSettingItem In UserSettings.Items Do 
		SettingItem = ReportsClientServer.GetObjectByUserID(
			SettingsComposer.Settings,
			UserSettingItem.UserSettingID,,
			UserSettings);
		
		If TypeOf(SettingItem) <> Type("DataCompositionFilterItem")
			Or TypeOf(SettingItem.RightValue) = Type("StandardPeriod")
			Or SettingItem.ViewMode = DataCompositionSettingsItemViewMode.Inaccessible Then 
			Continue;
		EndIf;
		
		Return True;
	EndDo;
	
	Return False;
EndFunction

&AtClient
Procedure DetermineIfModified()
	UserSettingsModified = True;
	If ExtendedMode = 1 Then
		OptionChanged = True;
	EndIf;
EndProcedure

#EndRegion

#Region ProcessFieldsMarkedForDeletion

// Searching for fields marked for deletion.

&AtServer
Procedure FindFieldsMarkedForDeletion(Val StructureItems = Undefined)
	If SettingsStructureItemChangeMode Then 
		Return;
	EndIf;
	
	Settings = Report.SettingsComposer.Settings;
	
	If StructureItems = Undefined Then 
		StructureItems = Settings.Structure;
		
		FindSelectedFieldsMarkedForDeletion(Settings);
		FindFilterFieldsMarkedForDeletion(Settings);
		FindOrderFieldsMarkedForDeletion(Settings);
		FindConditionalAppearanceItemsMarkedForDeletion(Settings);
	EndIf;
	
	For Each StructureItem In StructureItems Do 
		ItemType = TypeOf(StructureItem);
		If ItemType = Type("DataCompositionGroup")
			Or ItemType = Type("DataCompositionTableGroup")
			Or ItemType = Type("DataCompositionChartGroup") Then 
			
			FindSelectedFieldsMarkedForDeletion(Settings, StructureItem);
			FindFilterFieldsMarkedForDeletion(Settings, StructureItem);
			FindOrderFieldsMarkedForDeletion(Settings, StructureItem);
			FindConditionalAppearanceItemsMarkedForDeletion(Settings, StructureItem);
			FindGroupingFieldsMarkedForDeletion(Settings, StructureItem);
		EndIf;
		
		CollectionsNames = StructureItemCollectionsNames(StructureItem);
		For Each CollectionName In CollectionsNames Do 
			StructureItemCollection = SettingsItems(StructureItem,, CollectionName);
			FindFieldsMarkedForDeletion(StructureItemCollection);
		EndDo;
	EndDo;
	
	ProcessedItems = MarkedForDeletion.Unload();
	ProcessedItems.GroupBy("StructureItemID, ItemID, KeyStructureItemProperties");
	ProcessedItems.Sort("StructureItemID Desc, KeyStructureItemProperties, ItemID");
	
	MarkedForDeletion.Load(ProcessedItems);
EndProcedure

&AtServer
Procedure FindSelectedFieldsMarkedForDeletion(Settings, Val StructureItem = Undefined, Folder = Undefined)
	If StructureItem = Undefined Then 
		StructureItem = Settings;
	EndIf;
	
	StructureItemProperty = StructureItem.Selection;
	AvailableFields = StructureItemProperty.SelectionAvailableFields;
	AutoFieldType = Type("DataCompositionAutoSelectedField");
	GroupType = Type("DataCompositionSelectedFieldGroup");
	
	SettingsItems = ?(Folder = Undefined, StructureItemProperty.Items, Folder.Items);
	For Each SettingItem In SettingsItems Do 
		If TypeOf(SettingItem) = GroupType Then 
			FindSelectedFieldsMarkedForDeletion(Settings,  StructureItem, SettingItem);
			Continue;
		EndIf;
		
		If TypeOf(SettingItem) = AutoFieldType
			Or AvailableFields.FindField(SettingItem.Field) <> Undefined Then 
			Continue;
		EndIf;
		
		Record = MarkedForDeletion.Add();
		Record.StructureItemID = Settings.GetIDByObject(StructureItem);
		Record.ItemID = StructureItemProperty.GetIDByObject(SettingItem);
		Record.KeyStructureItemProperties = "Selection";
	EndDo;
EndProcedure

&AtServer
Procedure FindFilterFieldsMarkedForDeletion(Settings, Val StructureItem = Undefined, Folder = Undefined)
	If StructureItem = Undefined Then 
		StructureItem = Settings;
	EndIf;
	
	StructureItemProperty = StructureItem.Filter;
	AvailableFields = StructureItemProperty.FilterAvailableFields;
	GroupType = Type("DataCompositionFilterItemGroup");
	
	SettingsItems = ?(Folder = Undefined, StructureItemProperty.Items, Folder.Items);
	For Each SettingItem In SettingsItems Do 
		If TypeOf(SettingItem) = GroupType Then 
			FindFilterFieldsMarkedForDeletion(Settings,  StructureItem, SettingItem);
			Continue;
		EndIf;
		
		If AvailableFields.FindField(SettingItem.LeftValue) <> Undefined Then 
			Continue;
		EndIf;
		
		Record = MarkedForDeletion.Add();
		Record.StructureItemID = Settings.GetIDByObject(StructureItem);
		Record.ItemID = StructureItemProperty.GetIDByObject(SettingItem);
		Record.KeyStructureItemProperties = "Filter";
	EndDo;
EndProcedure

&AtServer
Procedure FindOrderFieldsMarkedForDeletion(Settings, Val StructureItem = Undefined)
	If StructureItem = Undefined Then 
		StructureItem = Settings;
	EndIf;
	
	StructureItemProperty = StructureItem.Order;
	AvailableFields = StructureItemProperty.OrderAvailableFields;
	AutoFieldType = Type("DataCompositionAutoOrderItem");
	
	For Each SettingItem In StructureItemProperty.Items Do 
		If TypeOf(SettingItem) = AutoFieldType
			Or AvailableFields.FindField(SettingItem.Field) <> Undefined Then 
			Continue;
		EndIf;
		
		Record = MarkedForDeletion.Add();
		Record.StructureItemID = Settings.GetIDByObject(StructureItem);
		Record.ItemID = StructureItemProperty.GetIDByObject(SettingItem);
		Record.KeyStructureItemProperties = "Order";
	EndDo;
EndProcedure

&AtServer
Procedure FindConditionalAppearanceItemsMarkedForDeletion(Settings, Val StructureItem = Undefined)
	If StructureItem = Undefined Then 
		StructureItem = Settings;
	EndIf;
	
	StructureItemProperty = StructureItem.ConditionalAppearance;
	
	For Each SettingItem In StructureItemProperty.Items Do 
		AvailableFields = SettingItem.Fields.AppearanceFieldsAvailableFields;
		For Each Item In SettingItem.Fields.Items Do 
			If AvailableFields.FindField(Item.Field) <> Undefined Then 
				Continue;
			EndIf;
			
			Record = MarkedForDeletion.Add();
			Record.StructureItemID = Settings.GetIDByObject(StructureItem);
			Record.ItemID = StructureItemProperty.GetIDByObject(SettingItem);
			Record.KeyStructureItemProperties = "ConditionalAppearance";
		EndDo;
		
		FindConditionalAppearanceFilterItemsMarkedForDeletion(Settings, StructureItem, SettingItem);
	EndDo;
EndProcedure

&AtServer
Procedure FindConditionalAppearanceFilterItemsMarkedForDeletion(Settings, StructureItem, AppearanceItem, Folder = Undefined)
	StructureItemProperty = StructureItem.ConditionalAppearance;
	
	AvailableFields = AppearanceItem.Filter.FilterAvailableFields;
	GroupType = Type("DataCompositionFilterItemGroup");
	
	SettingsItems = ?(Folder = Undefined, AppearanceItem.Filter.Items, Folder.Items);
	For Each SettingItem In SettingsItems Do 
		If TypeOf(SettingItem) = GroupType Then 
			FindConditionalAppearanceFilterItemsMarkedForDeletion(
				Settings,  StructureItem, AppearanceItem, SettingItem);
			Continue;
		EndIf;
		
		If AvailableFields.FindField(SettingItem.LeftValue) <> Undefined Then 
			Continue;
		EndIf;
		
		Record = MarkedForDeletion.Add();
		Record.StructureItemID = Settings.GetIDByObject(StructureItem);
		Record.ItemID = StructureItemProperty.GetIDByObject(AppearanceItem);
		Record.KeyStructureItemProperties = "ConditionalAppearance";
	EndDo;
EndProcedure

&AtServer
Procedure FindGroupingFieldsMarkedForDeletion(Settings, StructureItem)
	StructureItemProperty = StructureItem.GroupFields;
	AvailableFields = StructureItemProperty.GroupFieldsAvailableFields;
	AutoFieldType = Type("DataCompositionAutoGroupField");
	
	For Each SettingItem In StructureItemProperty.Items Do 
		If TypeOf(SettingItem) = AutoFieldType
			Or AvailableFields.FindField(SettingItem.Field) <> Undefined Then 
			Continue;
		EndIf;
		
		Record = MarkedForDeletion.Add();
		Record.StructureItemID = Settings.GetIDByObject(StructureItem);
		Record.ItemID = StructureItemProperty.GetIDByObject(SettingItem);
		Record.KeyStructureItemProperties = "GroupFields";
	EndDo;
EndProcedure

&AtServer
Function StructureItemCollectionsNames(Item)
	CollectionsNames = "";
	
	ItemType = TypeOf(Item);
	If ItemType = Type("DataCompositionGroup")
		Or ItemType = Type("DataCompositionTableGroup")
		Or ItemType = Type("DataCompositionChartGroup")
		Or ItemType = Type("DataCompositionNestedObjectSettings") Then 
		
		CollectionsNames = "Structure";
	ElsIf ItemType = Type("DataCompositionTable") Then 
		CollectionsNames = "Rows, Columns";
	ElsIf ItemType = Type("DataCompositionChart") Then 
		CollectionsNames = "Points, Series";
	EndIf;
	
	Return StrSplit(CollectionsNames, ", ", False);
EndFunction

// Deleting fields marked for deletion.

&AtClient
Procedure DeleteFiedsMarkedForDeletion()
	SettingsComposer = Report.SettingsComposer;
	
	For Each Record In MarkedForDeletion Do 
		StructureItemProperty = SettingsStructureItemProperty(
			SettingsComposer, Record.KeyStructureItemProperties, Record.StructureItemID, ExtendedMode);
		
		SettingItem = StructureItemProperty.GetObjectByID(Record.ItemID);
		If SettingItem = Undefined Then 
			Continue;
		EndIf;
		
		SettingItemParent = GetSettingItemParent(StructureItemProperty, SettingItem);
		SettingsItems = SettingsItems(StructureItemProperty, SettingItemParent);
		SettingsItems.Delete(SettingItem);
		
		If SettingsItems.Count() = 0
			AND TypeOf(SettingItemParent) = Type("DataCompositionGroupFields") Then 
			
			StructureItem = SettingsComposer.Settings.GetObjectByID(Record.StructureItemID);
			If TypeOf(StructureItem) = Type("DataCompositionGroup") Then 
				StructureItems = StructureItem.Structure;
				If StructureItems.Count() = 0 Then 
					Continue;
				EndIf;
				
				Index = StructureItems.Count() - 1;
				While Index >= 0 Do 
					StructureItems.Delete(StructureItems[Index]);
					Index = Index - 1;
				EndDo;
			Else // DataCompositionTableGroup or DataCompositionChartGroup.
				StructureItemParent = GetSettingItemParent(StructureItemProperty, StructureItem);
				CollectionName = SettingsCollectionNameByID(Record.StructureItemID);
				StructureItems = SettingsItems(StructureItemProperty, StructureItemParent, CollectionName);
				StructureItems.Delete(StructureItem);
			EndIf;
		EndIf;
	EndDo;
	
	DetermineIfModified();
EndProcedure

#EndRegion

#EndRegion