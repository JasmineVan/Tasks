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
	
	If Parameters.Property("IsAccessValueSelection") Then
		Parameters.IsAdditionalInfo = True;
	EndIf;
	
	If Parameters.IsAdditionalInfo <> Undefined Then
		IsAdditionalInfo = Parameters.IsAdditionalInfo;
		
		CommonClientServer.SetDynamicListFilterItem(
			List, "IsAdditionalInfo", IsAdditionalInfo, , , True);
	EndIf;
	
	If Parameters.SelectCommonProperty Then
		
		SelectionKind = "SelectCommonProperty";
		
		CommonClientServer.SetDynamicListFilterItem(
			List, "PropertiesSet", , DataCompositionComparisonType.NotFilled, , True);
		
		If IsAdditionalInfo = True Then
			AutoTitle = False;
			Title = NStr("ru = 'Выбор общего дополнительного сведения'; en = 'Select shared additional information record'; pl = 'Wybierz wspólne dodatkowe informacje';de = 'Wählen Sie allgemeine zusätzliche Informationen';ro = 'Selectați informații suplimentare comune';tr = 'Ortak ek bilgileri seçin'; es_ES = 'Seleccionar la información adicional común'");
		ElsIf IsAdditionalInfo = False Then
			AutoTitle = False;
			Title = NStr("ru = 'Выбор общего дополнительного реквизита'; en = 'Select shared additional attribute'; pl = 'Wybierz wspólny dodatkowy atrybut';de = 'Wählen Sie das allgemeine zusätzliche Attribut aus';ro = 'Selectați atributul adițional comun';tr = 'Ortak ek nitelikleri seçin'; es_ES = 'Seleccionar el atributo adicional común'");
		EndIf;
		
	ElsIf Parameters.SelectAdditionalValueOwner Then
		
		SelectionKind = "SelectAdditionalValueOwner";
		
		CommonClientServer.SetDynamicListFilterItem(
			List, "PropertiesSet", , DataCompositionComparisonType.Filled, , True);
		
		CommonClientServer.SetDynamicListFilterItem(
			List, "AdditionalValuesUsed", True, , , True);
		
		CommonClientServer.SetDynamicListFilterItem(
			List, "AdditionalValuesOwner", ,
			DataCompositionComparisonType.NotFilled, , True);
		
		AutoTitle = False;
		Title = NStr("ru = 'Выбор образца'; en = 'Select sample'; pl = 'Wybierz wzór';de = 'Wählen Sie ein Beispiel aus';ro = 'Selectați eșantionul';tr = 'Örnek seçin'; es_ES = 'Seleccionar el modelo'");
		
		Items.FormCreate.Visible = False;
		Items.FormCopy.Visible = False;
		Items.FormChange.Visible = False;
		Items.FormMarkForDeletion.Visible = False;
		
		Items.ListContextMenuCreate.Visible = False;
		Items.ListContextMenuCopy.Visible = False;
		Items.ListContextMenuChange.Visible = False;
		Items.ListContextMenuMarkForDeletion.Visible = False;
	EndIf;
	FillSelectedValues();
	
	AddFilterByPropertySets();
	
	CommonClientServer.SetDynamicListParameter(
		List,
		"CommonPropertiesGroupPresentation",
		NStr("ru = 'Общие (для нескольких наборов)'; en = 'Shared (for multiple sets)'; pl = 'Wspólne (dla kilku zestawów)';de = 'Allgemein (für mehrere Sätze)';ro = 'Comun (pentru mai multe seturi)';tr = 'Ortak (birkaç küme için)'; es_ES = 'Común (para varios conjuntos)'"),
		True);
	
	// Grouping properties to sets.
	DataGroup = List.SettingsComposer.Settings.Structure.Add(Type("DataCompositionGroup"));
	DataGroup.UserSettingID = "GroupPropertiesBySets";
	DataGroup.ViewMode = DataCompositionSettingsItemViewMode.Inaccessible;
	
	GroupFields = DataGroup.GroupFields;
	
	DataGroupItem = GroupFields.Items.Add(Type("DataCompositionGroupField"));
	DataGroupItem.Field = New DataCompositionField("PropertiesSetGroup");
	DataGroupItem.Use = True;
	
	Parameters.Filter.Property("PropertiesSet", PropertiesSetFilter);
EndProcedure

&AtServer
Procedure AddFilterByPropertySets()
	If TypeOf(Parameters.DisplayedPropertySets) = Type("Array")
		AND Parameters.DisplayedPropertySets.Count() <> 0 Then
		QueryCondition =
			"
			|WHERE
			|	PropertiesOverridable.PropertiesSet IN (&Sets)";
		
		ListProperties = Common.DynamicListPropertiesStructure();
		ListProperties.QueryText = List.QueryText + QueryCondition;
		Common.SetDynamicListProperties(Items.List,
			ListProperties);
		
		CommonClientServer.SetDynamicListParameter(
			List, "Sets", Parameters.DisplayedPropertySets, True);
	EndIf;
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersList

&AtClient
Procedure ListValueChoice(Item, Value, StandardProcessing)
	
	If SelectionKind = "SelectCommonProperty" Then
		StandardProcessing = False;
		NotifyChoice(New Structure("CommonProperty", Value));
		
	ElsIf SelectionKind = "SelectAdditionalValueOwner" Then
		StandardProcessing = False;
		NotifyChoice(New Structure("AdditionalValuesOwner", Value));
	EndIf;
	
EndProcedure

&AtClient
Procedure ListBeforeAddRow(Item, Cancel, Clone)
	
	Cancel = True;
	
	If NOT Items.FormCreate.Visible Then
		Return;
	EndIf;
	
	FormParameters = New Structure;
	FormParameters.Insert("IsAdditionalInfo", IsAdditionalInfo);
	
	If Item.CurrentData = Undefined Then
		PropertiesSet = PropertiesSetFilter;
	ElsIf Item.CurrentData.Property("RowGroup") Then
		PropertiesSet = Item.CurrentData.RowGroup.Key;
	ElsIf Item.CurrentData.Property("ParentRowGrouping") Then
		PropertiesSet = Item.CurrentData.ParentRowGrouping.Key;
	Else
		PropertiesSet = PropertiesSetFilter;
	EndIf;
	
	FormParameters.Insert("PropertiesSet", PropertiesSet);
	FormParameters.Insert("CurrentPropertiesSet", PropertiesSet);
	
	If Clone Then
		FormParameters.Insert("CopyingValue", Item.CurrentRow);
	Else
		FillingValues = New Structure;
		FormParameters.Insert("FillingValues", FillingValues);
	EndIf;
	
	OpenForm("ChartOfCharacteristicTypes.AdditionalAttributesAndInfo.ObjectForm", FormParameters);
	
EndProcedure

&AtClient
Procedure ListBeforeChangeRow(Item, Cancel)
	
	Cancel = True;
	
	If NOT Items.FormCreate.Visible Then
		Return;
	EndIf;
	
	If Item.CurrentData <> Undefined Then
		
		FormParameters = New Structure;
		FormParameters.Insert("Key", Item.CurrentRow);
		FormParameters.Insert("IsAdditionalInfo", IsAdditionalInfo);
		
		OpenForm("ChartOfCharacteristicTypes.AdditionalAttributesAndInfo.ObjectForm", FormParameters);
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure FillSelectedValues()
	
	If Parameters.Property("SelectedValues")
	   AND TypeOf(Parameters.SelectedValues) = Type("Array") Then
		
		SelectedItemsList.LoadValues(Parameters.SelectedValues);
	EndIf;
	
	ConditionalAppearanceItem = ConditionalAppearance.Items.Add();
	
	AppearanceColorItem = ConditionalAppearanceItem.Appearance.Items.Find("Font");
	AppearanceColorItem.Value = New Font(, , True);
	AppearanceColorItem.Use = True;
	
	DataFilterItem = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	DataFilterItem.LeftValue  = New DataCompositionField("List.Ref");
	DataFilterItem.ComparisonType   = DataCompositionComparisonType.InList;
	DataFilterItem.RightValue = SelectedItemsList;
	DataFilterItem.Use  = True;
	
	AppearanceFieldItem = ConditionalAppearanceItem.Fields.Items.Add();
	AppearanceFieldItem.Field = New DataCompositionField("Presentation");
	AppearanceFieldItem.Use = True;
	
EndProcedure

#EndRegion
