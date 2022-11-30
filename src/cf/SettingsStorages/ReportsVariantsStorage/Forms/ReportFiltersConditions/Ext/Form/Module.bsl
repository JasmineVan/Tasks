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
	
	CloseOnChoice = False;
	
	FillPropertyValues(ThisObject, Parameters, "ReportSettings, SettingsComposer");
	SettingsComposer.Initialize(New DataCompositionAvailableSettingsSource(ReportSettings.SchemaURL));
	
	OwnerFormType = CommonClientServer.StructureProperty(
		Parameters, "OwnerFormType", ReportFormType.Main);
	
	UpdateFilters(OwnerFormType);
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersFiltersTable

&AtClient
Procedure FiltersOnActivateRow(Item)
	List = Items.FiltersComparisonType.ChoiceList;
	List.Clear();
	
	Row = Item.CurrentData;
	If Row = Undefined
		Or Row.AvailableCompareTypes = Undefined Then 
		Return;
	EndIf;
	
	For Each ComparisonKinds In Row.AvailableCompareTypes Do 
		FillPropertyValues(List.Add(), ComparisonKinds);
	EndDo;
EndProcedure

#EndRegion

#Region FormCommandHandlers

&AtClient
Procedure Select(Command)
	SelectAndClose();
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SetConditionalAppearance()
	ConditionalAppearance.Items.Clear();
	
	// UserSettingPresentation - Empty.
	// Presentation - filled.
	//
	Item = ConditionalAppearance.Items.Add();
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Filters.UserSettingPresentation");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Filters.Presentation");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	
	Item.Appearance.SetParameterValue("Text", New DataCompositionField("Filters.Presentation"));
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.FiltersUserSettingPresentation.Name);
	
	// UserSettingPresentation - Empty.
	// Presentation - NotFilled.
	// Title - filled in.
	//
	Item = ConditionalAppearance.Items.Add();
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Filters.UserSettingPresentation");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Filters.Presentation");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Filters.Title");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	
	Item.Appearance.SetParameterValue("Text", New DataCompositionField("Filters.Title"));
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.FiltersUserSettingPresentation.Name);
EndProcedure

&AtServer
Procedure UpdateFilters(OwnerFormType)
	Rows = Filters.GetItems();
	
	AllowedDisplayModes = New Array;
	AllowedDisplayModes.Add(DataCompositionSettingsItemViewMode.Auto);
	AllowedDisplayModes.Add(DataCompositionSettingsItemViewMode.QuickAccess);
	If OwnerFormType = ReportFormType.Settings Then 
		AllowedDisplayModes.Add(DataCompositionSettingsItemViewMode.Normal);
	EndIf;
	
	UserSettings = SettingsComposer.UserSettings;
	For Each UserSettingItem In UserSettings.Items Do 
		If TypeOf(UserSettingItem) <> Type("DataCompositionFilterItem")
			Or TypeOf(UserSettingItem.RightValue) = Type("StandardPeriod") Then 
			Continue;
		EndIf;
		
		SettingItem = ReportsClientServer.GetObjectByUserID(
			SettingsComposer.Settings,
			UserSettingItem.UserSettingID,,
			UserSettings);
		
		If AllowedDisplayModes.Find(SettingItem.ViewMode) = Undefined Then 
			Continue;
		EndIf;
		
		SettingDetails = ReportsClientServer.FindAvailableSetting(SettingsComposer.Settings, SettingItem);
		If SettingDetails = Undefined Then 
			Continue;
		EndIf;
		
		Row = Rows.Add();
		FillPropertyValues(Row, SettingDetails);
		FillPropertyValues(Row, UserSettingItem);
		
		AvailableCompareTypes = SettingDetails.AvailableCompareTypes;
		If AvailableCompareTypes <> Undefined
			AND AvailableCompareTypes.Count() > 0
			AND AvailableCompareTypes.FindByValue(Row.ComparisonType) = Undefined Then 
			Row.ComparisonType = AvailableCompareTypes[0].Value;
		EndIf;
		
		Row.ID = UserSettings.GetIDByObject(UserSettingItem);
		Row.InitialComparisonType = Row.ComparisonType;
	EndDo;
EndProcedure

&AtClient
Procedure SelectAndClose()
	FiltersConditions = New Map;
	
	Rows = Filters.GetItems();
	For Each Row In Rows Do
		If Row.InitialComparisonType <> Row.ComparisonType Then
			FiltersConditions.Insert(Row.ID, Row.ComparisonType);
		EndIf;
	EndDo;
	
	Close(FiltersConditions);
EndProcedure

#EndRegion
