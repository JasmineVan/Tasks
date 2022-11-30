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
	
	PropertyToConfigure = Parameters.PropertyToConfigure;
	
	ObjectProperties = Common.ObjectAttributesValues(Parameters.AdditionalAttribute, "Title");
	
	Title = NStr("ru = '%1 дополнительного реквизита ""%2""'; en = '%1 of the ""%2"" additional attribute'; pl = '%1 atrybutu dodatkowego ""%2""';de = '%1 zusätzliche Attribute ""%2""';ro = '%1 atributului suplimentare ""%2""';tr = '%1ek alanın ""%2""'; es_ES = '%1 del requisito adicional ""%2""'");
	If PropertyToConfigure = "Available" Then
		PropertyPresentation = NStr("ru = 'Доступность'; en = 'Availability'; pl = 'Dostępność';de = 'Verfügbarkeit';ro = 'Accesibilitatea';tr = 'Erişilebilirlik'; es_ES = 'Disponibilidad'");
	ElsIf PropertyToConfigure = "RequiredToFill" Then
		PropertyPresentation = NStr("ru = 'Обязательность заполнения'; en = 'Required filling'; pl = 'Wymagane wypełnienie';de = 'Erforderliches Ausfüllen';ro = 'Umplere necesar';tr = 'Gerekli doldurma'; es_ES = 'Necesidad de rellenado'");
	Else
		PropertyPresentation = NStr("ru = 'Видимость'; en = 'Visibility'; pl = 'Widoczność';de = 'Sichtbarkeit';ro = 'Vizibilitate';tr = 'Görünürlük'; es_ES = 'Visibilidad'");
	EndIf;
	Title = StrReplace(Title, "%1", PropertyPresentation);
	Title = StrReplace(Title, "%2", ObjectProperties.Title);
	
	If Not ValueIsFilled(ObjectProperties.Title)  Then
		Title = StrReplace(Title, """", "");
	EndIf;
	
	PropertiesSet = Parameters.Set;
	While ValueIsFilled(PropertiesSet.Parent) Do
		PropertiesSet = PropertiesSet.Parent;
	EndDo;
	
	AdditionalAttributesSet = PropertiesSet.AdditionalAttributes;
	
	PredefinedPropertiesSets = PropertyManagerCached.PredefinedPropertiesSets();
	SetDetails = PredefinedPropertiesSets.Get(PropertiesSet);
	If SetDetails = Undefined Then
		PredefinedDataName = Common.ObjectAttributeValue(PropertiesSet, "PredefinedDataName");
	Else
		PredefinedDataName = SetDetails.Name;
	EndIf;
	
	ReplacedCharacterPosition = StrFind(PredefinedDataName, "_");
	FullMetadataObjectName = Left(PredefinedDataName, ReplacedCharacterPosition - 1)
		                       + "."
		                       + Mid(PredefinedDataName, ReplacedCharacterPosition + 1);
	
	ObjectAttributes = ListOfAttributesToFilter(FullMetadataObjectName, AdditionalAttributesSet);
	
	FIlterRow = Undefined;
	AdditionalAttributesDependencies = Parameters.AttributesDependencies;
	For Each TabularSectionRow In AdditionalAttributesDependencies Do
		If TabularSectionRow.DependentProperty = PropertyToConfigure Then
			ConditionByParts = StrSplit(TabularSectionRow.Condition, " ");
			NewCondition = "";
			If ConditionByParts.Count() > 0 Then
				For Each ConditionPart In ConditionByParts Do
					NewCondition = NewCondition + Upper(Left(ConditionPart, 1)) + Mid(ConditionPart, 2);
				EndDo;
			EndIf;
			
			If ValueIsFilled(NewCondition) Then
				TabularSectionRow.Condition = NewCondition;
			EndIf;
			
			AttributeWithMultivalue = (TabularSectionRow.Condition = "InList")
				Or (TabularSectionRow.Condition = "NotInList");
			
			If AttributeWithMultivalue Then
				FilterParameters = New Structure;
				FilterParameters.Insert("Attribute", TabularSectionRow.Attribute);
				FilterParameters.Insert("Condition",  TabularSectionRow.Condition);
				
				SearchResult = AttributesDependencies.FindRows(FilterParameters);
				If SearchResult.Count() = 0 Then
					FIlterRow = AttributesDependencies.Add();
					FillPropertyValues(FIlterRow, TabularSectionRow,, "Value");
					
					Values = New ValueList;
					Values.Add(TabularSectionRow.Value);
					FIlterRow.Value = Values;
				Else
					FIlterRow = SearchResult[0];
					FIlterRow.Value.Add(TabularSectionRow.Value);
				EndIf;
			Else
				FIlterRow = AttributesDependencies.Add();
				FillPropertyValues(FIlterRow, TabularSectionRow);
			EndIf;
			
			AttributeDetails = ObjectAttributes.Find(FIlterRow.Attribute, "Attribute");
			If AttributeDetails = Undefined Then
				Continue; // Object attribute is not found.
			EndIf;
			FIlterRow.ChoiceMode   = AttributeDetails.ChoiceMode;
			FIlterRow.Presentation = AttributeDetails.Presentation;
			FIlterRow.ValueType   = AttributeDetails.ValueType;
			If AttributeWithMultivalue Then
				FIlterRow.Value.ValueType = AttributeDetails.ValueType;
			EndIf;
		EndIf;
	EndDo;
	
	If Common.IsMobileClient() Then
		CommandBarLocation = FormCommandBarLabelLocation.Top;
	EndIf;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure AttributesDependenciesChoiceStartAttribute(Item, ChoiceData, StandardProcessing)
	StandardProcessing = False;
	OpenAttributeChoiceForm();
EndProcedure

&AtClient
Procedure AttributesDependenciesBeforeChangeStart(Item, Cancel)
	AttributesDependenciesSetTypeRestrictionForValue();
EndProcedure

&AtClient
Procedure AttributesDependenciesComparisonKindOnChange(Item)
	AttributesDependenciesSetTypeRestrictionForValue();
	
	FormTable = Items.AttributesDependencies;
	CurrentRow = AttributesDependencies.FindByID(FormTable.CurrentRow);
	CurrentRow.Value = Undefined;
	
	If FormTable.CurrentData.Condition = "InList"
		Or FormTable.CurrentData.Condition = "NotInList" Then
		CurrentRow.Value = New ValueList;
		CurrentRow.Value.ValueType = FormTable.CurrentData.ValueType;
	Else
		CurrentRow.Value = Undefined;
	EndIf;
EndProcedure

&AtClient
Procedure AttributesDependenciesBeforeAdd(Item, Cancel, Clone, Parent, Folder, Parameter)
	If Not AddRow Then
		Cancel = True;
	Else
		OpenAttributeChoiceForm();
		AddRow = False;
	EndIf;
EndProcedure

&AtClient
Procedure OpenAttributeChoiceForm()
	FormParameters = New Structure;
	FormParameters.Insert("ObjectAttributes", ObjectAttributesInStorage);
	OpenForm("ChartOfCharacteristicTypes.AdditionalAttributesAndInfo.Form.SelectAttribute", FormParameters);
EndProcedure

#EndRegion

#Region FormCommandHandlers

&AtClient
Procedure AddCondition(Command)
	AddRow = True;
	Items.AttributesDependencies.AddRow();
EndProcedure

&AtClient
Procedure OkCommand(Command)
	Result = New Structure;
	Result.Insert(PropertyToConfigure, FilterSettingsInValueStorage());
	Notify("Properties_AttributeDependencySet", Result);
	Close();
EndProcedure

&AtClient
Procedure CancelCommand(Command)
	Close();
EndProcedure

#EndRegion

#Region Private

&AtServer
Function FilterSettingsInValueStorage()
	
	If AttributesDependencies.Count() = 0 Then
		Return Undefined;
	EndIf;
	
	DependenciesTable = FormAttributeToValue("AttributesDependencies");
	TableCopy = DependenciesTable.Copy();
	TableCopy.Columns.Delete("Presentation");
	TableCopy.Columns.Delete("ValueType");
	
	FilterParameter = New Structure;
	FilterParameter.Insert("Condition", "InList");
	ConvertDependenciesInList(TableCopy, FilterParameter);
	FilterParameter.Condition = "NotInList";
	ConvertDependenciesInList(TableCopy, FilterParameter);
	
	Return New ValueStorage(TableCopy);
	
EndFunction

&AtServer
Procedure ConvertDependenciesInList(Table, Filter)
	FoundRows = Table.FindRows(Filter);
	For Each Row In FoundRows Do
		For Each Item In Row.Value Do
			NewRow = Table.Add();
			FillPropertyValues(NewRow, Row);
			NewRow.Value = Item.Value;
		EndDo;
		Table.Delete(Row);
	EndDo;
EndProcedure

&AtServer
Function ListOfAttributesToFilter(FullMetadataObjectName, AdditionalAttributesSet)
	
	ObjectAttributes = New ValueTable;
	ObjectAttributes.Columns.Add("Attribute");
	ObjectAttributes.Columns.Add("Presentation", New TypeDescription("String"));
	ObjectAttributes.Columns.Add("ValueType", New TypeDescription);
	ObjectAttributes.Columns.Add("PictureNumber", New TypeDescription("Number"));
	ObjectAttributes.Columns.Add("ChoiceMode", New TypeDescription("FoldersAndItemsUse"));
	
	MetadataObject = Metadata.FindByFullName(FullMetadataObjectName);
	
	For Each AdditionalAttribute In AdditionalAttributesSet Do
		ObjectProperties = Common.ObjectAttributesValues(AdditionalAttribute.Property, "Description, ValueType");
		StringAttribute = ObjectAttributes.Add();
		StringAttribute.Attribute = AdditionalAttribute.Property;
		StringAttribute.Presentation = ObjectProperties.Description;
		StringAttribute.PictureNumber  = 2;
		StringAttribute.ValueType = ObjectProperties.ValueType;
	EndDo;
	
	For Each Attribute In MetadataObject.StandardAttributes Do
		AddAttributeToTable(ObjectAttributes, Attribute, True);
	EndDo;
	
	For Each Attribute In MetadataObject.Attributes Do
		AddAttributeToTable(ObjectAttributes, Attribute, False);
	EndDo;
	
	ObjectAttributes.Sort("Presentation Asc");
	
	ObjectAttributesInStorage = PutToTempStorage(ObjectAttributes, UUID);
	
	Return ObjectAttributes;
	
EndFunction

&AtServer
Procedure AddAttributeToTable(ObjectAttributes, Attribute, Standard)
	AttributeString = ObjectAttributes.Add();
	AttributeString.Attribute = Attribute.Name;
	AttributeString.Presentation = Attribute.Presentation();
	AttributeString.PictureNumber  = 1;
	AttributeString.ValueType = Attribute.Type;
	If Standard Then
		AttributeString.ChoiceMode = ?(Attribute.Name = "Parent", FoldersAndItemsUse.Folders, Undefined);
	Else
		AttributeString.ChoiceMode = Attribute.ChoiceFoldersAndItems;
	EndIf;
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	If EventName = "Properties_ObjectAttributeSelection" Then
		CurrentRow = AttributesDependencies.FindByID(Items.AttributesDependencies.CurrentRow);
		FillPropertyValues(CurrentRow, Parameter);
		AttributesDependenciesSetTypeRestrictionForValue();
		CurrentRow.DependentProperty = PropertyToConfigure;
		CurrentRow.Condition   = "Equal";
		CurrentRow.Value = CurrentRow.ValueType.AdjustValue(Undefined);
	EndIf;
EndProcedure

&AtClient
Procedure AttributesDependenciesSetTypeRestrictionForValue()
	
	FormTable = Items.AttributesDependencies;
	InputField    = Items.AttributesDependenciesRightValue;
	
	ChoiceParametersArray = New Array;
	If TypeOf(FormTable.CurrentData.Attribute) <> Type("String") Then
		ChoiceParametersArray.Add(New ChoiceParameter("Filter.Owner", FormTable.CurrentData.Attribute));
	EndIf;
	
	ChoiceMode = FormTable.CurrentData.ChoiceMode;
	If ChoiceMode = FoldersAndItemsUse.Folders Then
		InputField.ChoiceFoldersAndItems = FoldersAndItems.Folders;
	ElsIf ChoiceMode = FoldersAndItemsUse.Items Then
		InputField.ChoiceFoldersAndItems = FoldersAndItems.Items;
	ElsIf ChoiceMode = FoldersAndItemsUse.FoldersAndItems Then
		InputField.ChoiceFoldersAndItems = FoldersAndItems.FoldersAndItems;
	EndIf;
	
	InputField.ChoiceParameters = New FixedArray(ChoiceParametersArray);
	If FormTable.CurrentData.Condition = "InList"
		Or FormTable.CurrentData.Condition = "NotInList" Then
		InputField.TypeRestriction = New TypeDescription("ValueList");
	Else
		InputField.TypeRestriction = FormTable.CurrentData.ValueType;
	EndIf;
	
EndProcedure

&AtServer
Procedure SetConditionalAppearance()
	
	ConditionalAppearance.Items.Clear();
	
	//
	
	ConditionalAppearanceItem = ConditionalAppearance.Items.Add();
	
	AvailabilityItem = ConditionalAppearanceItem.Appearance.Items.Find("Enabled");
	AvailabilityItem.Value = False;
	AvailabilityItem.Use = True;
	
	ComparisonValues = New ValueList;
	ComparisonValues.Add("Filled");
	ComparisonValues.Add("NotFilled"); // an exception, it is ID.
	
	DataFilterItem = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	DataFilterItem.LeftValue  = New DataCompositionField("AttributesDependencies.Condition");
	DataFilterItem.ComparisonType   = DataCompositionComparisonType.InList;
	DataFilterItem.RightValue = ComparisonValues;
	DataFilterItem.Use  = True;
	
	AppearanceFieldItem = ConditionalAppearanceItem.Fields.Items.Add();
	AppearanceFieldItem.Field = New DataCompositionField("AttributesDependenciesRightValue");
	AppearanceFieldItem.Use = True;
	
	//
	
	ConditionalAppearanceItem = ConditionalAppearance.Items.Add();
	
	ItemField = ConditionalAppearanceItem.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.AttributesDependenciesComparisonKind.Name);
	
	ItemFilter = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue  = New DataCompositionField("AttributesDependencies.Condition");
	ItemFilter.ComparisonType   = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = "NotEqual";
	ConditionalAppearanceItem.Appearance.SetParameterValue("Text", NStr("ru = 'Не равно'; en = 'Not equal to'; pl = 'Nie równy';de = 'Nicht gleich';ro = 'Nu este egal';tr = 'Eşit değil'; es_ES = 'Desigual'"));
	
	//
	
	ConditionalAppearanceItem = ConditionalAppearance.Items.Add();
	
	ItemField = ConditionalAppearanceItem.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.AttributesDependenciesComparisonKind.Name);
	
	ItemFilter = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue  = New DataCompositionField("AttributesDependencies.Condition");
	ItemFilter.ComparisonType   = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = "NotFilled";
	ConditionalAppearanceItem.Appearance.SetParameterValue("Text", NStr("ru = 'Не заполнено'; en = 'Not filled in'; pl = 'Niewypełniony';de = 'Leer';ro = 'Goală';tr = 'Boş'; es_ES = 'Vacía'"));
	
	//
	
	ConditionalAppearanceItem = ConditionalAppearance.Items.Add();
	
	ItemField = ConditionalAppearanceItem.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.AttributesDependenciesComparisonKind.Name);
	
	ItemFilter = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue  = New DataCompositionField("AttributesDependencies.Condition");
	ItemFilter.ComparisonType   = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = "InList";
	ConditionalAppearanceItem.Appearance.SetParameterValue("Text", NStr("ru = 'В списке'; en = 'In list'; pl = 'Na liście';de = 'In der Liste';ro = 'În listă';tr = 'Listede'; es_ES = 'En la lista'"));
	
	//
	
	ConditionalAppearanceItem = ConditionalAppearance.Items.Add();
	
	ItemField = ConditionalAppearanceItem.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.AttributesDependenciesComparisonKind.Name);
	
	ItemFilter = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue  = New DataCompositionField("AttributesDependencies.Condition");
	ItemFilter.ComparisonType   = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = "NotInList";
	ConditionalAppearanceItem.Appearance.SetParameterValue("Text", NStr("ru = 'Не в списке'; en = 'Not in list'; pl = 'Nie na liście';de = 'Nicht in der Liste';ro = 'Nu este în listă';tr = 'Listede değil'; es_ES = 'No en la lista'"));
	
EndProcedure

#EndRegion
