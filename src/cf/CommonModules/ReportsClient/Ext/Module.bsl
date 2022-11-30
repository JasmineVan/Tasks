///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Public

// Starts a report generation process in the report form.
//  When the generation is completed, CompletionHandler is called.
//
// Parameters:
//   ReportForm - ManagedForm - a report form.
//   CompletionHandler - NotificationHandler - a handler to be called once the report is generated.
//     To the first parameter of the procedure, specified in CompletionHandler, the following 
//     parameter is passed: ReportGenerated (Boolean) - indicates that a report was generated successfully.
//
Procedure GenerateReport(ReportForm, CompletionHandler = Undefined) Export
	If TypeOf(CompletionHandler) = Type("NotifyDescription") Then
		ReportForm.HandlerAfterGenerateAtClient = CompletionHandler;
	EndIf;
	ReportForm.AttachIdleHandler("Generate", 0.1, True);
EndProcedure

#EndRegion

#Region Private

////////////////////////////////////////////////////////////////////////////////
// Method of working with DCS from the report option.

Function ValueTypeRestrictedByLinkByType(Settings, UserSettings, SettingItem, SettingItemDetails, ValueType = Undefined) Export 
	If SettingItemDetails = Undefined Then 
		Return ?(ValueType = Undefined, New TypeDescription("Undefined"), ValueType);
	EndIf;
	
	If ValueType = Undefined Then 
		ValueType = SettingItemDetails.ValueType;
	EndIf;
	
	LinkByType = SettingItemDetails.TypeLink;
	
	LinkedSettingItem = SettingItemByField(Settings, UserSettings, LinkByType.Field);
	If LinkedSettingItem = Undefined Then 
		Return ValueType;
	EndIf;
	
	AllowedComparisonKinds = New Array;
	AllowedComparisonKinds.Add(DataCompositionComparisonType.Equal);
	AllowedComparisonKinds.Add(DataCompositionComparisonType.InHierarchy);
	
	If TypeOf(LinkedSettingItem) = Type("DataCompositionFilterItem")
		AND (Not LinkedSettingItem.Use
		Or AllowedComparisonKinds.Find(LinkedSettingItem.ComparisonType) = Undefined) Then 
		Return ValueType;
	EndIf;
	
	LinkedSettingItemDetails = ReportsClientServer.FindAvailableSetting(Settings, LinkedSettingItem);
	If LinkedSettingItemDetails = Undefined Then 
		Return ValueType;
	EndIf;
	
	If TypeOf(LinkedSettingItem) = Type("DataCompositionSettingsParameterValue")
		AND (LinkedSettingItemDetails.Use <> DataCompositionParameterUse.Always
		Or Not LinkedSettingItem.Use) Then 
		Return ValueType;
	EndIf;
	
	If TypeOf(LinkedSettingItem) = Type("DataCompositionSettingsParameterValue") Then 
		LinkedSettingItemValue = LinkedSettingItem.Value;
	ElsIf TypeOf(LinkedSettingItem) = Type("DataCompositionFilterItem") Then 
		LinkedSettingItemValue = LinkedSettingItem.RightValue;
	EndIf;
	
	ExtDimensionType = ReportsOptionsServerCall.ExtDimensionType(LinkedSettingItemValue, LinkByType.LinkItem);
	If TypeOf(ExtDimensionType) = Type("TypeDescription") Then
		LinkedTypes = ExtDimensionType.Types();
	Else
		LinkedTypes = LinkedSettingItemDetails.ValueType.Types();
	EndIf;
	
	RemovedTypes = ValueType.Types();
	Index = RemovedTypes.UBound();
	While Index >= 0 Do 
		If LinkedTypes.Find(RemovedTypes[Index]) <> Undefined Then 
			RemovedTypes.Delete(Index);
		EndIf;
		Index = Index - 1;
	EndDo;
	
	Return New TypeDescription(ValueType,, RemovedTypes);
EndFunction

Function SettingItemByField(Settings, UserSettings, Field)
	SettingItem = DataParametersItemByField(Settings, UserSettings, Field);
	
	If SettingItem = Undefined Then 
		FindFilterItemByField(Field, Settings.Filter.Items, UserSettings, SettingItem);
	EndIf;
	
	Return SettingItem;
EndFunction

Function DataParametersItemByField(Settings, UserSettings, Field)
	If TypeOf(Settings) <> Type("DataCompositionSettings") Then 
		Return Undefined;
	EndIf;
	
	SettingsItems = Settings.DataParameters.Items;
	For Each Item In SettingsItems Do 
		UserItem = UserSettings.Find(Item.UserSettingID);
		ItemToAnalyse = ?(UserItem = Undefined, Item, UserItem);
		
		Fields = New Array;
		Fields.Add(New DataCompositionField(String(Item.Parameter)));
		Fields.Add(New DataCompositionField("DataParameters." + String(Item.Parameter)));
		
		If ItemToAnalyse.Use
			AND (Fields[0] = Field Or Fields[1] = Field) Then 
			
			Return ItemToAnalyse;
		EndIf;
	EndDo;
	
	Return Undefined;
EndFunction

Procedure FindFilterItemByField(Field, FilterItems, UserSettings, SettingItem)
	For Each Item In FilterItems Do 
		If TypeOf(Item) = Type("DataCompositionFilterItemGroup") Then 
			FindFilterItemByField(Field, Item.Items, UserSettings, SettingItem)
		Else
			UserItem = UserSettings.Find(Item.UserSettingID);
			ItemToAnalyse = ?(UserItem = Undefined, Item, UserItem);
			
			If ItemToAnalyse.Use AND Item.LeftValue = Field Then 
				SettingItem = ItemToAnalyse;
				Break;
			EndIf;
		EndIf;
	EndDo;
EndProcedure

Function SettingItemInfo(SettingsComposer, ID) Export 
	Settings = SettingsComposer.Settings;
	UserSettings = SettingsComposer.UserSettings;
	
	If TypeOf(ID) = Type("Number") Then 
		Index = ID;
	Else
		Index = ReportsClientServer.SettingItemIndexByPath(ID);
	EndIf;
	
	UserSettingItem = UserSettings.Items[Index];
	
	SettingsHierarchy = New Array;
	Item = ReportsClientServer.GetObjectByUserID(
		Settings,
		UserSettingItem.UserSettingID,
		SettingsHierarchy,
		UserSettings);
	
	Settings = ?(SettingsHierarchy.Count() > 0, SettingsHierarchy[SettingsHierarchy.UBound()], Settings);
	Details = ReportsClientServer.FindAvailableSetting(Settings, Item);
	
	Info = New Structure;
	Info.Insert("Settings", Settings);
	Info.Insert("IndexOf", Index);
	Info.Insert("UserSettingItem", UserSettingItem);
	Info.Insert("Item", Item);
	Info.Insert("Details", Details);
	
	Return Info;
EndFunction

// Defines the FoldersAndItemsUse type value depending on comparison kind (preferably) or on the source value.
//
// Parameters:
//  Condition - DataCompositionComparisonType, Undefined - current comparison kind value. 
//  SourceValue - FoldersAndItemsUse, FoldersAndItems - the current value of the
//                     ChoiceOfGroupsAndItems property.
//
// Returns:
//   FoldersAndItemsUse - a value of the FoldersAndItemsUse enumeration.
//
Function ValueOfFoldersAndItemsUseType(SourceValue, Condition = Undefined) Export
	If Condition <> Undefined Then 
		If Condition = DataCompositionComparisonType.InListByHierarchy
			Or Condition = DataCompositionComparisonType.NotInListByHierarchy Then 
			If SourceValue = FoldersAndItems.Folders
				Or SourceValue = FoldersAndItemsUse.Folders Then 
				Return FoldersAndItemsUse.Folders;
			Else
				Return FoldersAndItemsUse.FoldersAndItems;
			EndIf;
		ElsIf Condition = DataCompositionComparisonType.InHierarchy
			Or Condition = DataCompositionComparisonType.NotInHierarchy Then 
			Return FoldersAndItemsUse.Folders;
		EndIf;
	EndIf;
	
	If TypeOf(SourceValue) = Type("FoldersAndItemsUse") Then 
		Return SourceValue;
	ElsIf SourceValue = FoldersAndItems.Items Then
		Return FoldersAndItemsUse.Items;
	ElsIf SourceValue = FoldersAndItems.FoldersAndItems Then
		Return FoldersAndItemsUse.FoldersAndItems;
	ElsIf SourceValue = FoldersAndItems.Folders Then
		Return FoldersAndItemsUse.Folders;
	EndIf;
	
	Return Undefined;
EndFunction

#Region ReportPeriod

// Calls a dialog box for editing a standard period.
//
// Parameters:
//  Form - ManagedForm - a report form or a report settings form.
//  CommandName - String - a period choice command name that contains a period value path.
//
Procedure SelectPeriod(Form, CommandName) Export
	Path = StrReplace(CommandName, "SelectPeriod", "Period");
	Context = New Structure("Form, Path", Form, Path);
	
	Dialog = New StandardPeriodEditDialog;
	Dialog.Period = Form[Path];
	Dialog.Show(New NotifyDescription("SelectPeriodCompletion", ThisObject, Context));
EndProcedure

// Handler for editing a standard period.
//
// Parameters:
//  SelectedPeriod - StandardPeriod - a value returned by the dialog box.
//  Context - Structure - it contains a report form (of settings) and a period value path.
//
Procedure SelectPeriodCompletion(SelectedPeriod, Context) Export 
	If SelectedPeriod = Undefined Then 
		Return;
	EndIf;
	
	Context.Form[Context.Path] = SelectedPeriod;
	SetPeriod(Context.Form, Context.Path);
EndProcedure

// Initializes value of the period setting item.
//
Procedure SetPeriod(Form, Val Path) Export 
	SettingsComposer = Form.Report.SettingsComposer;
	
	Properties = StrSplit("StartDate, EndDate", ", ", False);
	For Each Property In Properties Do 
		Path = StrReplace(Path, Property, "");
	EndDo;
	
	Index = Form.PathToItemsData.ByName[Path];
	UserSettingItem = SettingsComposer.UserSettings.Items[Index];
	UserSettingItem.Use = True;
	
	If TypeOf(UserSettingItem) = Type("DataCompositionSettingsParameterValue") Then 
		UserSettingItem.Value = Form[Path];
	Else // Filter element.
		UserSettingItem.RightValue = Form[Path];
	EndIf;
EndProcedure

#EndRegion

#Region Miscellaneous

Function SpecifyItemTypeOnAddToCollection(CollectionType) Export
	If CollectionType = Type("DataCompositionTableStructureItemCollection")
		Or CollectionType = Type("DataCompositionChartStructureItemCollection")
		Or CollectionType = Type("DataCompositionConditionalAppearanceItemCollection") Then
		Return False;
	Else
		Return True;
	EndIf;
EndFunction

#EndRegion

#EndRegion