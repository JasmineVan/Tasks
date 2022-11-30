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
	
	If Parameters.Property("ShowAdditionalAttributes") Then
		StandardSubsystemsServer.SetFormAssignmentKey(ThisObject,
			"AdditionalAttributeSets");
		Items.IsAdditionalInfoSets.Visible = False;
		
	ElsIf Parameters.Property("ShowAdditionalInfo") Then
		StandardSubsystemsServer.SetFormAssignmentKey(ThisObject,
			"AdditionalDataSets");
		Items.IsAdditionalInfoSets.Visible = False;
		IsAdditionalInfoSets = True;
	EndIf;
	
	FormColor = Items.Properties.BackColor;
	ApplySetsAndPropertiesAppearance();
	
	UpdateCommandsUsage();
	
	ConfigureSetsDisplay();
	
	If Not Common.SubsystemExists("StandardSubsystems.DuplicateObjectDetection") Then
		Items.DuplicateObjectDetection.Visible = False;
	EndIf;
	
	If Common.IsMobileClient() Then
		Items.PropertiesSets.InitialTreeView = InitialTreeView.ExpandAllLevels;
		Items.PropertiesSets.TitleLocation         = FormItemTitleLocation.Top;
		Items.Properties.TitleLocation              = FormItemTitleLocation.Top;
		Items.PropertiesSubmenuAdd.Representation      = ButtonRepresentation.Picture;
	EndIf;
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If EventName = "Write_AdditionalAttributesAndInfo"
	 OR EventName = "Write_ObjectPropertyValues"
	 OR EventName = "Write_ObjectPropertyValueHierarchy" Then
		
		// Upon writing a property, move the property to the appropriate group.
		// Upon writing a value, update the list of the top three values.
		OnChangeCurrentSetAtServer();
		
	ElsIf EventName = "Go_AdditionalDataAndAttributeSets" Then
		// Upon opening the form for editing properties of a certain metadata object, go to the set or set 
		// group of this metadata object.
		If TypeOf(Parameter) = Type("Structure") Then
			SelectSpecifiedRows(Parameter);
		EndIf;
		
	ElsIf EventName = "Write_ConstantsSet" Then
		
		If Source = "UseCommonAdditionalValues"
		 OR Source = "UseAdditionalCommonAttributesAndInfo" Then
			UpdateCommandsUsage();
		EndIf;
	EndIf;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure IsAdditionalInfoSetsOnChange(Item)
	
	ConfigureSetsDisplay();
	
EndProcedure

#EndRegion

#Region PropertiesSetsFormTableItemsEventsHandlers

&AtClient
Procedure PropertiesSetsOnActivateRow(Item)
	
	AttachIdleHandler("OnChangeCurrentSet", 0.1, True);
	
EndProcedure

&AtClient
Procedure PropertiesSetsBeforeChangeRow(Item, Cancel)
	
	Cancel = True;
	
EndProcedure

&AtClient
Procedure PropertySetsDragCheck(Item, DragParameters, StandardProcessing, Row, Field)
	StandardProcessing = False;
	
	If Items.PropertiesSets.RowData(Row).IsFolder Then
		DragParameters.Action = DragAction.Cancel;
	EndIf;
	
EndProcedure

&AtClient
Procedure PropertySetsDrag(Item, DragParameters, StandardProcessing, Row, Field)
	StandardProcessing = False;
	
	If DragParameters.Value.CommonValues Then
		ItemToDrag = DragParameters.Value.AdditionalValuesOwner;
	Else
		ItemToDrag = DragParameters.Value.Property;
	EndIf;
	
	If TypeOf(ItemToDrag) <> Type("ChartOfCharacteristicTypesRef.AdditionalAttributesAndInfo") Then
		Return;
	EndIf;
	
	DestinationSet = Row;
	AddAttributeToSet(ItemToDrag, Row);
EndProcedure

#EndRegion

#Region PropertyFormTableItemEventHandlers

&AtClient
Procedure PropertiesOnActivateRow(Item)
	
	PropertiesSetCommandAvailability(ThisObject);
	
EndProcedure

&AtClient
Procedure PropertiesBeforeAddRow(Item, Cancel, Clone, Parent, Folder)
	
	If Clone Then
		Copy();
	Else
		Create();
	EndIf;
	
	Cancel = True;
	
EndProcedure

&AtClient
Procedure PropertiesBeforeChangeRow(Item, Cancel)
	
	Change();
	
	Cancel = True;
	
EndProcedure

&AtClient
Procedure PropertiesBeforeDelete(Item, Cancel)
	
	ChangeDeletionMark();
	
	Cancel = True;
	
EndProcedure

&AtClient
Procedure PropertiesChoiceProcessing(Item, ValueSelected, StandardProcessing)
	
	StandardProcessing = False;
	
	If TypeOf(ValueSelected) = Type("Structure") Then
		If ValueSelected.Property("AdditionalValuesOwner") Then
			
			FormParameters = New Structure;
			FormParameters.Insert("IsAdditionalInfo",      IsAdditionalInfoSets);
			FormParameters.Insert("CurrentPropertiesSet",            CurrentSet);
			FormParameters.Insert("AdditionalValuesOwner", ValueSelected.AdditionalValuesOwner);
			
			OpenForm("ChartOfCharacteristicTypes.AdditionalAttributesAndInfo.ObjectForm",
				FormParameters, Items.Properties);
			
		ElsIf ValueSelected.Property("CommonProperty") Then
			
			ChangedSet = CurrentSet;
			If ValueSelected.Property("Drag") Then
				AddCommonPropertyByDragging(ValueSelected.CommonProperty);
			Else
				ExecuteCommandAtServer("AddCommonProperty", ValueSelected.CommonProperty);
				ChangedSet = DestinationSet;
			EndIf;
			
			Notify("Write_AdditionalDataAndAttributeSets",
				New Structure("Ref", ChangedSet), ChangedSet);
		Else
			SelectSpecifiedRows(ValueSelected);
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure PropertiesDragCheck(Item, DragParameters, StandardProcessing, Row, Field)
	StandardProcessing = False;
EndProcedure

&AtClient
Procedure PropertiesDragStart(Item, DragParameters, Perform)
	// Moving of properties and attributes is not supported, copying is always performed.
	// The cursor should have an appropriate icon.
	DragParameters.AllowedActions = DragAllowedActions.Copy;
	DragParameters.Action           = DragAction.Copy;
EndProcedure

#EndRegion

#Region FormCommandHandlers

&AtClient
Procedure Create(Command = Undefined)
	
	FormParameters = New Structure;
	FormParameters.Insert("PropertiesSet", CurrentSet);
	FormParameters.Insert("IsAdditionalInfo", IsAdditionalInfoSets);
	FormParameters.Insert("CurrentPropertiesSet", CurrentSet);
	
	OpenForm("ChartOfCharacteristicTypes.AdditionalAttributesAndInfo.ObjectForm",
		FormParameters, Items.Properties);
	
EndProcedure

&AtClient
Procedure AddFromSet(Command)
	
	FormParameters = New Structure;
	
	SelectedValues = New Array;
	FoundRows = Properties.FindRows(New Structure("Common", True));
	For each Row In FoundRows Do
		SelectedValues.Add(Row.Property);
	EndDo;
	
	If IsAdditionalInfoSets Then
		FormParameters.Insert("SelectCommonProperty", True);
	Else
		FormParameters.Insert("SelectAdditionalValueOwner", True);
	EndIf;
	
	FormParameters.Insert("SelectedValues", SelectedValues);
	FormParameters.Insert("IsAdditionalInfo", IsAdditionalInfoSets);
	FormParameters.Insert("CurrentPropertiesSet", CurrentSet);
	
	OpenForm("ChartOfCharacteristicTypes.AdditionalAttributesAndInfo.Form.ItemForm",
		FormParameters, Items.Properties);
EndProcedure

&AtClient
Procedure Change(Command = Undefined)
	
	If Items.Properties.CurrentData <> Undefined Then
		// Opening the property form.
		FormParameters = New Structure;
		FormParameters.Insert("Key", Items.Properties.CurrentData.Property);
		FormParameters.Insert("CurrentPropertiesSet", CurrentSet);
		
		OpenForm("ChartOfCharacteristicTypes.AdditionalAttributesAndInfo.ObjectForm",
			FormParameters, Items.Properties);
	EndIf;
	
EndProcedure

&AtClient
Procedure Copy(Command = Undefined, PasteFromClipboard = False)
	
	FormParameters = New Structure;
	CopyingValue = Items.Properties.CurrentData.Property;
	FormParameters.Insert("AdditionalValuesOwner", CopyingValue);
	FormParameters.Insert("CurrentPropertiesSet", CurrentSet);
	FormParameters.Insert("CopyingValue", CopyingValue);
	
	OpenForm("ChartOfCharacteristicTypes.AdditionalAttributesAndInfo.ObjectForm", FormParameters);
	
EndProcedure

&AtClient
Procedure AddAttributeToSet(AdditionalValuesOwner, Set = Undefined)
	
	FormParameters = New Structure;
	If Set = Undefined Then
		CurrentPropertiesSet = CurrentSet;
	Else
		CurrentPropertiesSet = Set;
		FormParameters.Insert("Drag", True);
	EndIf;
	
	FormParameters.Insert("CopyWithQuestion", True);
	FormParameters.Insert("AdditionalValuesOwner", AdditionalValuesOwner);
	FormParameters.Insert("IsAdditionalInfo", IsAdditionalInfoSets);
	FormParameters.Insert("CurrentPropertiesSet", CurrentPropertiesSet);
	
	OpenForm("ChartOfCharacteristicTypes.AdditionalAttributesAndInfo.ObjectForm", FormParameters, Items.Properties);
	
EndProcedure

&AtClient
Procedure MarkForDeletion(Command)
	
	ChangeDeletionMark();
	
EndProcedure

&AtClient
Procedure MoveUp(Command)
	
	ExecuteCommandAtServer("MoveUp");
	
EndProcedure

&AtClient
Procedure MoveDown(Command)
	
	ExecuteCommandAtServer("MoveDown");
	
EndProcedure

&AtClient
Procedure DuplicateObjectsDetection(Command)
	ModuleDuplicateObjectsDetectionClient = CommonClient.CommonModule("FindAndDeleteDuplicatesDuplicatesClient");
	DuplicateObjectsDetectionFormName = ModuleDuplicateObjectsDetectionClient.DuplicateObjectsDetectionDataProcessorFormName();
	OpenForm(DuplicateObjectsDetectionFormName);
EndProcedure

&AtClient
Procedure CopySelectedAttribute(Command)
	AttributeToCopy = New Structure;
	AttributeToCopy.Insert("AttributeToCopy", Items.Properties.CurrentData.Property);
	AttributeToCopy.Insert("CommonValues", Items.Properties.CurrentData.CommonValues);
	AttributeToCopy.Insert("AdditionalValuesOwner", Items.Properties.CurrentData.AdditionalValuesOwner);
	
	Items.PasteAttribute.Enabled = True;
EndProcedure

&AtClient
Procedure PasteAttribute(Command)
	If AttributeToCopy.CommonValues Then
		AdditionalValuesOwner = AttributeToCopy.AdditionalValuesOwner;
	Else
		AdditionalValuesOwner = AttributeToCopy.AttributeToCopy;
	EndIf;
	
	AddAttributeToSet(AdditionalValuesOwner);
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure ApplySetsAndPropertiesAppearance()
	
	// Appearance of the sets root.
	ConditionalAppearanceItem = PropertiesSets.ConditionalAppearance.Items.Add();
	
	AppearanceColorItem = ConditionalAppearanceItem.Appearance.Items.Find("Text");
	AppearanceColorItem.Value = NStr("ru = 'Наборы'; en = 'Sets'; pl = 'Zestawy';de = 'Sätze';ro = 'Seturi';tr = 'Kümeler'; es_ES = 'Conjuntos'");
	AppearanceColorItem.Use = True;
	
	DataFilterItem = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	DataFilterItem.LeftValue  = New DataCompositionField("Ref");
	DataFilterItem.ComparisonType   = DataCompositionComparisonType.NotFilled;
	DataFilterItem.Use  = True;
	
	AppearanceFieldItem = ConditionalAppearanceItem.Fields.Items.Add();
	AppearanceFieldItem.Field = New DataCompositionField("Presentation");
	AppearanceFieldItem.Use = True;
	
	// Appearance of unavailable set groups that by default are displayed by the platform as a part of group tree.
	ConditionalAppearanceItem = PropertiesSets.ConditionalAppearance.Items.Add();
	
	VisibilityItem = ConditionalAppearanceItem.Appearance.Items.Find("Visible");
	VisibilityItem.Value = False;
	VisibilityItem.Use = True;
	
	DataFilterItemsGroup = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	DataFilterItemsGroup.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
	DataFilterItemsGroup.Use = True;
	
	DataFilterItem = DataFilterItemsGroup.Items.Add(Type("DataCompositionFilterItem"));
	DataFilterItem.LeftValue  = New DataCompositionField("Ref");
	DataFilterItem.ComparisonType   = DataCompositionComparisonType.NotInList;
	DataFilterItem.RightValue = AvailableSetsList;
	DataFilterItem.Use  = True;
	
	DataFilterItem = DataFilterItemsGroup.Items.Add(Type("DataCompositionFilterItem"));
	DataFilterItem.LeftValue  = New DataCompositionField("Parent");
	DataFilterItem.ComparisonType   = DataCompositionComparisonType.NotInList;
	DataFilterItem.RightValue = AvailableSetsList;
	DataFilterItem.Use  = True;
	
	DataFilterItem = DataFilterItemsGroup.Items.Add(Type("DataCompositionFilterItem"));
	DataFilterItem.LeftValue  = New DataCompositionField("Ref");
	DataFilterItem.ComparisonType   = DataCompositionComparisonType.Filled;
	DataFilterItem.Use  = True;
	
	AppearanceFieldItem = ConditionalAppearanceItem.Fields.Items.Add();
	AppearanceFieldItem.Field = New DataCompositionField("Presentation");
	AppearanceFieldItem.Use = True;
	
	// Configuring required properties.
	ConditionalAppearanceItem = ConditionalAppearance.Items.Add();
	
	AppearanceColorItem = ConditionalAppearanceItem.Appearance.Items.Find("Font");
	AppearanceColorItem.Value = New Font(, , True);
	AppearanceColorItem.Use = True;
	
	DataFilterItem = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	DataFilterItem.LeftValue  = New DataCompositionField("Properties.RequiredToFill");
	DataFilterItem.ComparisonType   = DataCompositionComparisonType.Equal;
	DataFilterItem.RightValue = True;
	DataFilterItem.Use  = True;
	
	AppearanceFieldItem = ConditionalAppearanceItem.Fields.Items.Add();
	AppearanceFieldItem.Field = New DataCompositionField("PropertiesTitle");
	AppearanceFieldItem.Use = True;
	
EndProcedure

&AtClient
Procedure SelectSpecifiedRows(Details)
	
	If Details.Property("Set") Then
		
		If TypeOf(Details.Set) = Type("String") Then
			ConvertStringsToReferences(Details);
		EndIf;
		
		If Details.IsAdditionalInfo <> IsAdditionalInfoSets Then
			IsAdditionalInfoSets = Details.IsAdditionalInfo;
			ConfigureSetsDisplay();
		EndIf;
		
		Items.PropertiesSets.CurrentRow = Details.Set;
		CurrentSet = Undefined;
		OnChangeCurrentSet();
		FoundRows = Properties.FindRows(New Structure("Property", Details.Property));
		If FoundRows.Count() > 0 Then
			Items.Properties.CurrentRow = FoundRows[0].GetID();
		Else
			Items.Properties.CurrentRow = Undefined;
		EndIf;
	EndIf;
	
EndProcedure

&AtServerNoContext
Procedure ConvertStringsToReferences(Details)
	
	Details.Insert("Set", Catalogs.AdditionalAttributesAndInfoSets.GetRef(
		New UUID(Details.Set)));
	
	Details.Insert("Property", ChartsOfCharacteristicTypes.AdditionalAttributesAndInfo.GetRef(
		New UUID(Details.Property)));
	
EndProcedure

&AtServer
Procedure UpdateCommandsUsage()
	
	If GetFunctionalOption("UseCommonAdditionalValues")
	 OR GetFunctionalOption("UseAdditionalCommonAttributesAndInfo") Then
		
		Items.PropertiesCreateOnly.Visible = False;
		Items.PropertiesSubmenuAdd.Visible = True;
		
		Items.PropertiesContextMenuCreateOnly.Visible = False;
		Items.PropertiesContextMenuAddSubmenu.Visible = True
	Else
		Items.PropertiesCreateOnly.Visible = True;
		Items.PropertiesSubmenuAdd.Visible = False;
		
		Items.PropertiesContextMenuCreateOnly.Visible = True;
		Items.PropertiesContextMenuAddSubmenu.Visible = False
	EndIf;
	
EndProcedure

&AtServer
Procedure ConfigureSetsDisplay()
	
	CreateCommand                      = Commands.Find("Create");
	CopyCommand                  = Commands.Find("Copy");
	ChangeCommand                     = Commands.Find("Change");
	MarkForDeletionCommand           = Commands.Find("MarkToDelete");
	MoveUpCommand             = Commands.Find("MoveUp");
	MoveDownCommand              = Commands.Find("MoveDown");
	
	If IsAdditionalInfoSets Then
		Title = NStr("ru = 'Дополнительные сведения'; en = 'Additional information'; pl = 'Informacje dodatkowe';de = 'Zusätzliche informationen';ro = 'Informații suplimentare';tr = 'Ek bilgi'; es_ES = 'Información adicional'");
		
		CreateCommand.ToolTip          = NStr("ru = 'Создать уникальное сведение'; en = 'Create unique information'; pl = 'Utwórz unikalne informacje';de = 'Erstellen Sie einzigartige Informationen';ro = 'Creați informații unice';tr = 'Benzersiz bilgi oluştur'; es_ES = 'Crear la información única'");
		CreateCommand.Title          = NStr("ru = 'Новое'; en = 'New'; pl = 'Nowy';de = 'Neu';ro = 'Nou';tr = 'Yeni'; es_ES = 'Nuevo'");
		CreateCommand.ToolTip          = NStr("ru = 'Создать уникальное сведение'; en = 'Create unique information'; pl = 'Utwórz unikalne informacje';de = 'Erstellen Sie einzigartige Informationen';ro = 'Creați informații unice';tr = 'Benzersiz bilgi oluştur'; es_ES = 'Crear la información única'");
		
		CopyCommand.ToolTip        = NStr("ru = 'Создать новое сведение копированием текущего'; en = 'Create an information by copying the current one'; pl = 'Utwórz nowe informacje, kopiując istniejące';de = 'Erstellen Sie neue Informationen, indem Sie die vorhandenen kopieren';ro = 'Creare date noi prin copierea de curente';tr = 'Geçerli olanı kopyalayarak yeni bir bilgi oluştur'; es_ES = 'Crear nueva información copiando aquella existente'");
		ChangeCommand.ToolTip           = NStr("ru = 'Изменить (или открыть) текущее сведение'; en = 'Change or open the current information'; pl = 'Zmień (lub otwórz) bieżące informacje';de = 'Ändern (oder öffnen) Sie die aktuellen Informationen';ro = 'Modificare (sau deschide) datele curente';tr = 'Geçerli bilgiyi düzenle (veya aç)'; es_ES = 'Cambiar (o abrir) la información actual'");
		MarkForDeletionCommand.ToolTip = NStr("ru = 'Пометить текущее сведение на удаление (Del)'; en = 'Mark the current information for deletion (Del)'; pl = 'Zaznacz bieżące informacje do usunięcia (Del)';de = 'Aktuelle Informationen zum Löschen markieren (Del)';ro = 'Marcare la ștergere datele curente (Del)';tr = 'Silinmek için geçerli bilgiyi işaretle (Del)'; es_ES = 'Marcar la información actual para borrar (Del)'");
		MoveUpCommand.ToolTip   = NStr("ru = 'Переместить текущее сведение вверх'; en = 'Move the current information up'; pl = 'Przenieś bieżące dane do góry';de = 'Verschieben Sie die aktuellen Daten nach oben';ro = 'Mutare datele curente în sus';tr = 'Geçerli bilgiyi yukarı taşı'; es_ES = 'Mover arriba los datos actuales'");
		MoveDownCommand.ToolTip    = NStr("ru = 'Переместить текущее сведение вниз'; en = 'Move the current information down'; pl = 'Przenieś bieżące informacje w dół';de = 'Verschieben Sie die aktuelle Information nach unten';ro = 'Mutați informațiile curente în jos';tr = 'Geçerli bilgiyi aşağı taşı'; es_ES = 'Mover abajo la información actual'");
		
		MetadataTabularSection =
			Metadata.Catalogs.AdditionalAttributesAndInfoSets.TabularSections.AdditionalInfo;
		
		Items.PropertiesTitle.ToolTip = MetadataTabularSection.Attributes.Property.ToolTip;
		
		Items.PropertiesRequired.Visible = False;
		
		Items.PropertiesValueType.ToolTip =
			NStr("ru = 'Типы значения, которое можно ввести при заполнении сведения.'; en = 'Types of value that can be entered upon information filling.'; pl = 'Typy wartości, które można wprowadzić przy wprowadzeniu informacji.';de = 'Werttypen, die beim Ausfüllen der Informationen eingegeben werden können.';ro = 'Tipuri de valori care pot fi introduse la completarea datelor.';tr = 'Bilginin doldurulmasında girilebilecek değer türleri.'; es_ES = 'Tipos de valores que pueden entrar al rellenar la información.'");
		
		Items.PropertiesSharedValues.ToolTip =
			NStr("ru = 'Сведение использует список значений сведения-образца.'; en = 'The information uses sample information values.'; pl = 'Informacje wykorzystują przykładową listę wartości.';de = 'Information verwendet eine Beispielwerteliste.';ro = 'Datele utilizează lista de valori ale datelor-model.';tr = 'Bilgi, değerlerin örnek listesini kullanır.'; es_ES = 'Lista de modelos de usos de la información de valores.'");
		
		Items.PropertiesShared.Title = NStr("ru = 'Общее'; en = 'Shared'; pl = 'Wspólny';de = 'Allgemein';ro = 'Comun';tr = 'Ortak'; es_ES = 'Común'");
		Items.PropertiesShared.ToolTip = NStr("ru = 'Общее дополнительное сведение, которое используется в
		                                              |нескольких наборах дополнительных сведений.'; 
		                                              |en = 'Shared additional information record.
		                                              |Belongs to multiple sets.'; 
		                                              |pl = 'Wspólna informacja dodatkowa, która jest wykorzystywana w
		                                              |kilku zestawach informacji dodatkowych.';
		                                              |de = 'Allgemeine Zusatzinformationen, die in
		                                              |mehreren Sets von Zusatzinformationen verwendet werden.';
		                                              |ro = 'Datele suplimentare comune utilizate în
		                                              |mai multe seturi de date suplimentare.';
		                                              |tr = 'Birkaç ek veri kümesinde kullanılan 
		                                              |ortak özel veriler.'; 
		                                              |es_ES = 'Datos personalizados comunes en
		                                              | varios conjuntos de los datos adicionales.'");
	Else
		Title = NStr("ru = 'Дополнительные реквизиты'; en = 'Additional attributes'; pl = 'Dodatkowe atrybuty';de = 'Zusätzliche Attribute';ro = 'Atribute suplimentare';tr = 'Ek özellikler'; es_ES = 'Atributos adicionales'");
		CreateCommand.Title          = NStr("ru = 'Новый'; en = 'New'; pl = 'Nowy';de = 'Neu';ro = 'Nou';tr = 'Yeni'; es_ES = 'Nuevo'");
		CreateCommand.ToolTip          = NStr("ru = 'Создать уникальный реквизит'; en = 'Create unique attribute'; pl = 'Utwórz unikalne pole';de = 'Erstellen Sie ein eindeutiges Feld';ro = 'Creare atribut unic';tr = 'Benzersiz bir alan oluştur'; es_ES = 'Crear un campo único'");
		
		CopyCommand.ToolTip        = NStr("ru = 'Создать новый реквизит копированием текущего'; en = 'Create an attribute by copying the current one'; pl = 'Utwórz nowy atrybut, kopiując bieżący';de = 'Erstellen Sie ein neues Attribut, indem Sie das aktuelle kopieren';ro = 'Creare atribut nou prin copierea celui curent';tr = 'Geçerli olanı kopyalayarak yeni bir öznitelik oluştur'; es_ES = 'Crear un atributo nuevo copiando el actual'");
		ChangeCommand.ToolTip           = NStr("ru = 'Изменить (или открыть) текущий реквизит'; en = 'Change or open the current attribute'; pl = 'Zmienić (albo otworzyć) bieżący atrybut';de = 'Aktuelles Feld bearbeiten (oder öffnen)';ro = 'Modificare (sau deschide) atributul curent';tr = 'Geçerli alanı düzenle (veya aç)'; es_ES = 'Editar (o abrir) el campo actual'");
		MarkForDeletionCommand.ToolTip = NStr("ru = 'Пометить текущий реквизит на удаление (Del)'; en = 'Mark the current attribute for deletion (Del)'; pl = 'Zaznacz bieżące pole do usunięcia (Del)';de = 'Markiere das aktuelle Feld zum Löschen (Del)';ro = 'Marcare la ștergere atributul curent (Del)';tr = 'Geçerli alanı silinmek üzere işaretle (Sil)'; es_ES = 'Marcar el campo actual para borrar (Del)'");
		MoveUpCommand.ToolTip   = NStr("ru = 'Переместить текущий реквизит вверх'; en = 'Move the current attribute up'; pl = 'Przenieś bieżący atrybut w górę';de = 'Das aktuelle Attribut nach oben verschieben';ro = 'Mutați atributul curent în sus';tr = 'Geçerli özniteliği yukarı taşı'; es_ES = 'Mover arriba el atributo actual'");
		MoveDownCommand.ToolTip    = NStr("ru = 'Переместить текущий реквизит вниз'; en = 'Move the current attribute down'; pl = 'Przenieś bieżący atrybut w dół';de = 'Aktuelles Attribut nach unten verschieben';ro = 'Mutare atributul curent în jos';tr = 'Geçerli özniteliği aşağı taşı'; es_ES = 'Mover abajo el atributo actual'");
		
		MetadataTabularSection =
			Metadata.Catalogs.AdditionalAttributesAndInfoSets.TabularSections.AdditionalAttributes;
		
		Items.PropertiesTitle.ToolTip = MetadataTabularSection.Attributes.Property.ToolTip;
		
		Items.PropertiesRequired.Visible = True;
		Items.PropertiesRequired.ToolTip =
			Metadata.ChartsOfCharacteristicTypes.AdditionalAttributesAndInfo.Attributes.RequiredToFill.ToolTip;
		
		Items.PropertiesValueType.ToolTip =
			NStr("ru = 'Типы значения, которое можно ввести при заполнении реквизита.'; en = 'Types of value that can be entered upon attribute filling.'; pl = 'Rodzaje wartości, które można wprowadzić przy wypełnianiu atrybutu.';de = 'Arten von Werten, die beim Ausfüllen des Attributs eingegeben werden können.';ro = 'Tipuri de valori care pot fi introduse la completarea atributului.';tr = 'Özniteliğin doldurulmasında girilebilecek değer türleri.'; es_ES = 'Tipos de valores que se puede introducir al rellenar en el atributo.'");
		
		Items.PropertiesSharedValues.ToolTip =
			NStr("ru = 'Реквизит использует список значений реквизита-образца.'; en = 'The attribute uses a list of sample attribute values.'; pl = 'Ten atrybut używa listy wartości atrybutu wzorcowego.';de = 'Das Attribut verwendet die Attribut-Stichprobenwertliste.';ro = 'Atributul folosește lista valorilor atributului-model.';tr = 'Özellik, öznitelik-örnek değer listesini kullanır.'; es_ES = 'El atributo utiliza la lista de valores de muestra de atributos.'");
		
		Items.PropertiesShared.Title = NStr("ru = 'Общий'; en = 'Shared'; pl = 'Wspólny';de = 'Allgemein';ro = 'Comun';tr = 'Ortak'; es_ES = 'Común'");
		Items.PropertiesShared.ToolTip = NStr("ru = 'Общий дополнительный реквизит, который используется в
		                                              |нескольких наборах дополнительных реквизитов.'; 
		                                              |en = 'Shared additional attribute.
		                                              |Belongs to multiple sets.'; 
		                                              |pl = 'Wspólne pole niestandardowe używane
		                                              |w kilku niestandardowych zestawach pól.';
		                                              |de = 'Ein gemeinsames zusätzliches Attribut, das von 
		                                              |mehreren Sets von zusätzlichen Attributen verwendet wird.';
		                                              |ro = 'Atributul suplimentar comun utilizat în
		                                              |mai multe seturi de atribute suplimentare.';
		                                              |tr = 'Birkaç özel alan kümesinde kullanılan 
		                                              |ortak özel alan.'; 
		                                              |es_ES = 'Un campo personalizado común utilizado en
		                                              | varios conjuntos de campos personalizados.'");
	EndIf;
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	Sets.Ref AS Ref
	|FROM
	|	Catalog.AdditionalAttributesAndInfoSets AS Sets
	|WHERE
	|	Sets.Parent = VALUE(Catalog.AdditionalAttributesAndInfoSets.EmptyRef)";
	
	Sets = Query.Execute().Unload().UnloadColumn("Ref");
	AvailableSets = New Array;
	AvailableSetsList.Clear();
	
	For each Ref In Sets Do
		SetPropertiesTypes = PropertyManagerInternal.SetPropertiesTypes(Ref, False);
		
		If IsAdditionalInfoSets
		   AND SetPropertiesTypes.AdditionalInfo
		 OR NOT IsAdditionalInfoSets
		   AND SetPropertiesTypes.AdditionalAttributes Then
			
			AvailableSets.Add(Ref);
			AvailableSetsList.Add(Ref);
		EndIf;
	EndDo;
	
	CommonClientServer.SetDynamicListParameter(
		PropertiesSets, "IsAdditionalInfoSets", IsAdditionalInfoSets, True);
	
	CommonClientServer.SetDynamicListParameter(
		PropertiesSets, "Sets", AvailableSets, True);
		
	CommonClientServer.SetDynamicListParameter(
		PropertiesSets, "IsMainLanguage", CurrentLanguage() = Metadata.DefaultLanguage, True);
	
	CommonClientServer.SetDynamicListParameter(
		PropertiesSets, "LanguageCode", CurrentLanguage().LanguageCode, True);
	
	OnChangeCurrentSetAtServer();
	
EndProcedure

&AtClient
Procedure OnChangeCurrentSet()
	
	If Items.PropertiesSets.CurrentData = Undefined Then
		If ValueIsFilled(CurrentSet) Then
			CurrentSet = Undefined;
			OnChangeCurrentSetAtServer();
		EndIf;
		
	ElsIf Items.PropertiesSets.CurrentData.Ref <> CurrentSet Then
		CurrentSet          = Items.PropertiesSets.CurrentData.Ref;
		CurrentSetIsFolder = Items.PropertiesSets.CurrentData.IsFolder;
		OnChangeCurrentSetAtServer();
	EndIf;
	
#If MobileClient Then
	CurrentItem = Items.Properties;
	If Not ImportanceConfigured Then
		Items.PropertiesSets.DisplayImportance = DisplayImportance.VeryLow;
		ImportanceConfigured = True;
	EndIf;
	Items.Properties.Title = String(CurrentSet);
#EndIf
	
EndProcedure

&AtClient
Procedure ChangeDeletionMark()
	
	If Items.Properties.CurrentData <> Undefined Then
		
		If IsAdditionalInfoSets Then
			If Items.Properties.CurrentData.Common Then
				QuestionText = NStr("ru ='Исключить текущее общее сведения из набора?'; en = 'Do you want to remove the shared information record from the set?'; pl = 'Wykluczyć bieżące informacje wspólne z zestawu?';de = 'Die aktuellen allgemeinen Informationen aus dem Set ausschließen?';ro = 'Excludeți datele curente comune din set?';tr = 'Geçerli ortak bilgiler kümenin dışına bırakılsın mı?'; es_ES = '¿Excluir la información común actual del conjunto?'");
				
			ElsIf Items.Properties.CurrentData.DeletionMark Then
				QuestionText = NStr("ru ='Снять с текущего сведения пометку на удаление?'; en = 'Do you want to clear the deletion mark from the current information?'; pl = 'Usunąć zaznaczenie do usunięcia dla aktualnej informacji?';de = 'Löschzeichen für die aktuelle Information löschen?';ro = 'Scoateți marcajul la ștergere de pe datele curente?';tr = 'Geçerli bilgiler için silme işareti kaldırılsın mi?'; es_ES = '¿Eliminar las marcas para borrar para la información actual?'");
			Else
				QuestionText = NStr("ru ='Пометить текущее сведение на удаление?'; en = 'Do you want to mark the current information for deletion?'; pl = 'Zaznaczyć aktualne informacje do usunięcia?';de = 'Aktuelle Informationen zum Löschen markieren?';ro = 'Marcați la ștergere datele curente?';tr = 'Geçerli bilgi silinmek üzere işaretlensin mi?'; es_ES = '¿Marcar la información actual para borrar?'");
			EndIf;
		Else
			If Items.Properties.CurrentData.Common Then
				QuestionText = NStr("ru ='Исключить текущий общий реквизит из набора?'; en = 'Do you want to remove the shared attribute from the set?'; pl = 'Wykluczyć bieżący wspólny atrybut z zestawu?';de = 'Das aktuelle gemeinsame Attribut aus dem Set ausschließen?';ro = 'Excludeți atributul curent comun din set?';tr = 'Geçerli ortak nitelik kümenin dışına bırakılsın mı?'; es_ES = '¿Excluir el atributo común actual del conjunto?'");
				
			ElsIf Items.Properties.CurrentData.DeletionMark Then
				QuestionText = NStr("ru ='Снять с текущего реквизита пометку на удаление?'; en = 'Do you want to clear the deletion mark from the current attribute?'; pl = 'Usunąć zaznaczenie do usunięcia dla bieżącego atrybutu?';de = 'Löschzeichen für das aktuelle Attribut löschen?';ro = 'Scoateți marcajul la ștergere de pe atributul curent?';tr = 'Geçerli nitelik için silme işareti kaldırılsın mi?'; es_ES = '¿Eliminar las marcas para borrar para el atributo actual?'");
			Else
				QuestionText = NStr("ru ='Пометить текущий реквизит на удаление?'; en = 'Do you want to mark the current attribute for deletion?'; pl = 'Zaznaczyć bieżące pole do usunięcia?';de = 'Das aktuelle Feld zum Löschen markieren?';ro = 'Marcați la ștergere atributul curent?';tr = 'Geçerli alan silinmek üzere işaretlensin mi?'; es_ES = '¿Marcar el campo actual para borrar?'");
			EndIf;
		EndIf;
		
		ShowQueryBox(
			New NotifyDescription("ChangeDeletionMarkCompletion", ThisObject, CurrentSet),
			QuestionText, QuestionDialogMode.YesNo);
	EndIf;
	
EndProcedure

&AtClient
Procedure ChangeDeletionMarkCompletion(Response, CurrentSet) Export
	
	If Response <> DialogReturnCode.Yes Then
		Return;
	EndIf;
	
	ExecuteCommandAtServer("EditDeletionMark");
	
	Notify("Write_AdditionalDataAndAttributeSets",
		New Structure("Ref", CurrentSet), CurrentSet);
	
EndProcedure

&AtServer
Procedure OnChangeCurrentSetAtServer()
	
	If ValueIsFilled(CurrentSet)
	   AND NOT CurrentSetIsFolder Then
		
		CurrentAvailability = True;
		If Items.Properties.BackColor <> Items.PropertiesSets.BackColor Then
			Items.Properties.BackColor = Items.PropertiesSets.BackColor;
		EndIf;
		UpdateCurrentSetPropertiesList(CurrentAvailability);
	Else
		CurrentAvailability = False;
		If Items.Properties.BackColor <> FormColor Then
			Items.Properties.BackColor = FormColor;
		EndIf;
		Properties.Clear();
	EndIf;
	
	If Items.Properties.ReadOnly = CurrentAvailability Then
		Items.Properties.ReadOnly = NOT CurrentAvailability;
	EndIf;
	
	PropertiesSetCommandAvailability(ThisObject);
	
	Items.PropertiesSets.Refresh();
	
EndProcedure

&AtClientAtServerNoContext
Procedure PropertiesSetCommandAvailability(Context)
	
	Items = Context.Items;
	
	CommonAvailability = NOT Items.Properties.ReadOnly;
	InsertAvailability = CommonAvailability AND (Context.AttributeToCopy <> Undefined);
	
	AvailabilityForString = CommonAvailability
		AND Context.Items.Properties.CurrentRow <> Undefined;
	
	// Customizing commands of command bar.
	Items.AddFromSet.Enabled           = CommonAvailability;
	Items.PropertiesCreate.Enabled            = CommonAvailability;
	Items.PropertiesCreateOnly.Enabled      = CommonAvailability;
	
	Items.PropertiesCopy.Enabled        = AvailabilityForString;
	Items.PropertiesEdit.Enabled           = AvailabilityForString;
	Items.PropertiesMarkForDeletion.Enabled = AvailabilityForString;
	
	Items.PropertiesMoveUp.Enabled   = AvailabilityForString;
	Items.PropertiesMoveDown.Enabled    = AvailabilityForString;
	
	Items.CopyAttribute.Enabled         = AvailabilityForString;
	Items.PasteAttribute.Enabled           = InsertAvailability;
	
	// Customizing commands of context menu.
	Items.PropertiesContextMenuCreate.Enabled            = CommonAvailability;
	Items.PropertiesContextMenuCreateOnly.Enabled      = CommonAvailability;
	Items.PropertiesContextMenuAddFromSet.Enabled   = CommonAvailability;
	
	Items.PropertiesContextMenuCopy.Enabled        = AvailabilityForString;
	Items.PropertiesContextMenuChange.Enabled           = AvailabilityForString;
	Items.PropertiesContextMenuMarkForDeletion.Enabled = AvailabilityForString;
	
	Items.PropertiesContextMenuCopyAttribute.Enabled = AvailabilityForString;
	Items.PropertiesContextMenuPasteAttribute.Enabled   = InsertAvailability;
	
EndProcedure

&AtServer
Procedure UpdateCurrentSetPropertiesList(CurrentAvailability)
	
	Query = New Query;
	Query.SetParameter("Set", CurrentSet);
	Query.SetParameter("IsMainLanguage", CurrentLanguage() = Metadata.DefaultLanguage);
	Query.SetParameter("LanguageCode", CurrentLanguage().LanguageCode);
	
	Query.Text =
	"SELECT
	|	SetsProperties.LineNumber,
	|	SetsProperties.Property,
	|	SetsProperties.DeletionMark,
	|	CASE
	|		WHEN &IsMainLanguage
	|			THEN Properties.Title
	|		ELSE CAST(ISNULL(PresentationProperties.Title, Properties.Title) AS STRING(150))
	|	END AS Title,
	|	Properties.AdditionalValuesOwner,
	|	Properties.RequiredToFill,
	|	Properties.ValueType AS ValueType,
	|	CASE
	|		WHEN Properties.Ref IS NULL 
	|			THEN TRUE
	|		WHEN Properties.PropertiesSet = VALUE(Catalog.AdditionalAttributesAndInfoSets.EmptyRef)
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS Common,
	|	CASE
	|		WHEN SetsProperties.DeletionMark = TRUE
	|			THEN 4
	|		ELSE 3
	|	END AS PictureNumber
	|FROM
	|	Catalog.AdditionalAttributesAndInfoSets.AdditionalAttributes AS SetsProperties
	|		LEFT JOIN ChartOfCharacteristicTypes.AdditionalAttributesAndInfo AS Properties
	|		ON SetsProperties.Property = Properties.Ref
	|		LEFT JOIN ChartOfCharacteristicTypes.AdditionalAttributesAndInfo.Presentations AS PresentationProperties
	|		ON (PresentationProperties.Ref = Properties.Ref)
	|			AND PresentationProperties.LanguageCode = &LanguageCode
	|WHERE
	|	SetsProperties.Ref = &Set
	|
	|ORDER BY
	|	SetsProperties.LineNumber
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Sets.DataVersion AS DataVersion
	|FROM
	|	Catalog.AdditionalAttributesAndInfoSets AS Sets
	|WHERE
	|	Sets.Ref = &Set";
	
	If IsAdditionalInfoSets Then
		Query.Text = StrReplace(
			Query.Text,
			"Catalog.AdditionalAttributesAndInfoSets.AdditionalAttributes",
			"Catalog.AdditionalAttributesAndInfoSets.AdditionalInfo");
	EndIf;
	
	BeginTransaction();
	Try
		QueryResults = Query.ExecuteBatch();
		
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;
	
	If Items.Properties.CurrentRow = Undefined Then
		Row = Undefined;
	Else
		Row = Properties.FindByID(Items.Properties.CurrentRow);
	EndIf;
	CurrentProperty = ?(Row = Undefined, Undefined, Row.Property);
	
	Properties.Clear();
	
	If QueryResults[1].IsEmpty() Then
		CurrentAvailability = False;
		Return;
	EndIf;
	
	CurrentSetDataVersion = QueryResults[1].Unload()[0].DataVersion;
	
	Selection = QueryResults[0].Select();
	While Selection.Next() Do
		
		NewRow = Properties.Add();
		FillPropertyValues(NewRow, Selection);
		
		NewRow.CommonValues = ValueIsFilled(Selection.AdditionalValuesOwner);
		
		If Selection.ValueType <> NULL
		   AND PropertyManagerInternal.ValueTypeContainsPropertyValues(Selection.ValueType) Then
			
			NewRow.ValueType = String(New TypeDescription(
				Selection.ValueType,
				,
				"CatalogRef.ObjectPropertyValueHierarchy,
				|CatalogRef.ObjectsPropertiesValues"));
			
			Query = New Query;
			If ValueIsFilled(Selection.AdditionalValuesOwner) Then
				Query.SetParameter("Owner", Selection.AdditionalValuesOwner);
			Else
				Query.SetParameter("Owner", Selection.Property);
			EndIf;
			Query.Text =
			"SELECT TOP 4
			|	PRESENTATION(ObjectsPropertiesValues.Ref) AS Description
			|FROM
			|	Catalog.ObjectsPropertiesValues AS ObjectsPropertiesValues
			|WHERE
			|	ObjectsPropertiesValues.Owner = &Owner
			|	AND NOT ObjectsPropertiesValues.IsFolder
			|	AND NOT ObjectsPropertiesValues.DeletionMark
			|
			|UNION
			|
			|SELECT TOP 4
			|	PRESENTATION(ObjectPropertyValueHierarchy.Ref) AS Description
			|FROM
			|	Catalog.ObjectPropertyValueHierarchy AS ObjectPropertyValueHierarchy
			|WHERE
			|	ObjectPropertyValueHierarchy.Owner = &Owner
			|	AND NOT ObjectPropertyValueHierarchy.DeletionMark
			|;
			|
			|////////////////////////////////////////////////////////////////////////////////
			|SELECT TOP 1
			|	TRUE AS TrueValue
			|FROM
			|	Catalog.ObjectsPropertiesValues AS ObjectsPropertiesValues
			|WHERE
			|	ObjectsPropertiesValues.Owner = &Owner
			|	AND NOT ObjectsPropertiesValues.IsFolder
			|
			|UNION ALL
			|
			|SELECT TOP 1
			|	TRUE
			|FROM
			|	Catalog.ObjectPropertyValueHierarchy AS ObjectPropertyValueHierarchy
			|WHERE
			|	ObjectPropertyValueHierarchy.Owner = &Owner";
			QueryResults = Query.ExecuteBatch();
			
			TopValues = QueryResults[0].Unload().UnloadColumn("Description");
			
			If TopValues.Count() = 0 Then
				If QueryResults[1].IsEmpty() Then
					ValuesPresentation = NStr("ru = 'Значения еще не введены'; en = 'Values are not entered yet'; pl = 'Nie wprowadzono żadnych wartości';de = 'Keine Werte eingegeben';ro = 'Nu au fost introduse valori';tr = 'Değer girilmedi'; es_ES = 'No hay valores entrados'");
				Else
					ValuesPresentation = NStr("ru = 'Значения помечены на удаление'; en = 'Values are marked for deletion'; pl = 'Wartości są zaznaczone do usunięcia';de = 'Die Werte sind zum Löschen markiert';ro = 'Valorile sunt marcate pentru ștergere';tr = 'Değerler silinmek üzere işaretlendi'; es_ES = 'Valores están marcados para borrar'");
				EndIf;
			Else
				ValuesPresentation = "";
				Number = 0;
				For each Value In TopValues Do
					Number = Number + 1;
					If Number = 4 Then
						ValuesPresentation = ValuesPresentation + ",...";
						Break;
					EndIf;
					ValuesPresentation = ValuesPresentation + ?(Number > 1, ", ", "") + Value;
				EndDo;
			EndIf;
			ValuesPresentation = "<" + ValuesPresentation + ">";
			If ValueIsFilled(NewRow.ValueType) Then
				ValuesPresentation = ValuesPresentation + ", ";
			EndIf;
			NewRow.ValueType = ValuesPresentation + NewRow.ValueType;
		EndIf;
		
		If Selection.Property = CurrentProperty Then
			Items.Properties.CurrentRow =
				Properties[Properties.Count()-1].GetID();
		EndIf;
	EndDo;
	
EndProcedure

&AtServer
Procedure AddCommonPropertyByDragging(PropertyToAdd)
	
	Lock = New DataLock;
	LockItem = Lock.Add("Catalog.AdditionalAttributesAndInfoSets");
	LockItem.SetValue("Ref", DestinationSet);
	
	Try
		LockDataForEdit(DestinationSet);
		BeginTransaction();
		Try
			Lock.Lock();
			LockDataForEdit(DestinationSet);
			
			SetDestinationObject = DestinationSet.GetObject();
			
			TabularSection = SetDestinationObject[?(IsAdditionalInfoSets,
				"AdditionalInfo", "AdditionalAttributes")];
			
			FoundRow = TabularSection.Find(PropertyToAdd, "Property");
			
			If FoundRow = Undefined Then
				NewRow = TabularSection.Add();
				NewRow.Property = PropertyToAdd;
				SetDestinationObject.Write();
				
			ElsIf FoundRow.DeletionMark Then
				FoundRow.DeletionMark = False;
				SetDestinationObject.Write();
			EndIf;
			
			CommitTransaction();
		Except
			RollbackTransaction();
			Raise;
		EndTry;
	Except
		UnlockDataForEdit(DestinationSet);
		Raise;
	EndTry;
	
	Items.PropertiesSets.Refresh();
	DestinationSet = Undefined;
	
EndProcedure

&AtServer
Procedure ExecuteCommandAtServer(Command, Parameter = Undefined)
	
	Lock = New DataLock;
	
	If Command = "EditDeletionMark" Then
		LockItem = Lock.Add("Catalog.AdditionalAttributesAndInfoSets");
		LockItem = Lock.Add("ChartOfCharacteristicTypes.AdditionalAttributesAndInfo");
		LockItem = Lock.Add("Catalog.ObjectsPropertiesValues");
		LockItem = Lock.Add("Catalog.ObjectPropertyValueHierarchy");
	Else
		LockItem = Lock.Add("Catalog.AdditionalAttributesAndInfoSets");
		LockItem.SetValue("Ref", CurrentSet);
	EndIf;
	
	Try
		LockDataForEdit(CurrentSet);
		BeginTransaction();
		Try
			Lock.Lock();
			LockDataForEdit(CurrentSet);
			
			CurrentSetObject = CurrentSet.GetObject();
			If CurrentSetObject.DataVersion <> CurrentSetDataVersion Then
				OnChangeCurrentSetAtServer();
				If IsAdditionalInfoSets Then
					Raise
						NStr("ru = 'Действие не выполнено, так как состав дополнительных сведений
						           |был изменен другим пользователем.
						           |Новый состав дополнительных сведений прочитан.
						           |
						           |Повторите действие, если требуется.'; 
						           |en = 'The action is not performed as additional information
						           |was changed by another user.
						           |New additional information is read.
						           |
						           |Try again if required.'; 
						           |pl = 'Czynność nie została wykonywana, ponieważ
						           | zawartość informacji dodatkowych była zmieniona przez innego użytkownika.
						           |Odczytano nową treść informacji dodatkowych.
						           |
						           |W razie potrzeby powtórz czynność';
						           |de = 'Die Aktion wurde nicht durchgeführt, da die Zusatzinformationen
						           |von einem anderen Benutzer geändert wurden.
						           |Der neue Satz von Zusatzinformationen wurde gelesen.
						           |
						           |Wiederholen Sie die Aktion bei Bedarf.';
						           |ro = 'Acțiunea nu este executată, deoarece componența datelor suplimentare
						           |a fost modificată de alt utilizator.
						           |Este citită componența nouă a datelor suplimentare.
						           |
						           |Repetați acțiunea, dacă este necesar.';
						           |tr = 'Ek bilgilerin 
						           |içeriği başka bir kullanıcı tarafından değiştirildiği için eylem gerçekleştirilemez. 
						           |Ek bilgilerin yeni içeriği hazır. 
						           |
						           |Gerekirse işlemi tekrarlayın'; 
						           |es_ES = 'Acción no está realizada desde que el contenido de la información adicional 
						           |se ha cambiado por otro usuario.
						           |Nuevo contenido de la información adicional está leído.
						           |
						           |Reintentar la acción si es necesario.'");
				Else
					Raise
						NStr("ru = 'Действие не выполнено, так как состав дополнительных реквизитов
						           |был изменен другим пользователем.
						           |Новый состав дополнительных реквизитов прочитан.
						           |
						           |Повторите действие, если требуется.'; 
						           |en = 'The action is not performed as additional attributes
						           |were changed by another user.
						           |New additional attributes are read.
						           |
						           |Try again if required.'; 
						           |pl = 'Czynność nie została wykonywana, ponieważ
						           |zawartość atrybutów dodatkowych była zmieniona przez innego użytkownika.
						           |Odczytano nową treść atrybutów dodatkowych.
						           |
						           |W razie potrzeby powtórz czynność';
						           |de = 'Die Aktion wurde nicht durchgeführt, da die Zusatzinformationen
						           |von einem anderen Benutzer geändert wurden.
						           |Der neue Satz von Zusatzinformationen wurde gelesen.
						           |
						           |Wiederholen Sie die Aktion bei Bedarf.';
						           |ro = 'Acțiunea nu este executată, deoarece componența atributelor suplimentare
						           |a fost modificată de alt utilizator.
						           |Este citită componența nouă a atributelor suplimentare.
						           |
						           |Repetați acțiunea, dacă este necesar.';
						           |tr = 'Ek bilgilerin 
						           |içeriği başka bir kullanıcı tarafından değiştirildiği için eylem gerçekleştirilemez. 
						           |Ek bilgilerin yeni içeriği hazır. 
						           |
						           |Gerekirse işlemi tekrarlayın.'; 
						           |es_ES = 'Acción no está realizada desde que el contenido de los requisitos adicionales 
						           |se ha cambiado por otro usuario.
						           |Nuevo contenido de los requisitos adicionales está leído.
						           |
						           |Reintentar la acción si es necesario.'");
				EndIf;
			EndIf;
			
			TabularSection = CurrentSetObject[?(IsAdditionalInfoSets,
				"AdditionalInfo", "AdditionalAttributes")];
			
			If Command = "AddCommonProperty" Then
				FoundRow = TabularSection.Find(Parameter, "Property");
				
				If FoundRow = Undefined Then
					NewRow = TabularSection.Add();
					NewRow.Property = Parameter;
					CurrentSetObject.Write();
					
				ElsIf FoundRow.DeletionMark Then
					FoundRow.DeletionMark = False;
					CurrentSetObject.Write();
				EndIf;
			Else
				Row = Properties.FindByID(Items.Properties.CurrentRow);
				
				If Row <> Undefined Then
					Index = Row.LineNumber-1;
					
					If Command = "MoveUp" Then
						TopRowIndex = Properties.IndexOf(Row)-1;
						If TopRowIndex >= 0 Then
							Offset = Properties[TopRowIndex].LineNumber - Row.LineNumber;
							TabularSection.Move(Index, Offset);
						EndIf;
						CurrentSetObject.Write();
						
					ElsIf Command = "MoveDown" Then
						BottomRowIndex = Properties.IndexOf(Row)+1;
						If BottomRowIndex < Properties.Count() Then
							Offset = Properties[BottomRowIndex].LineNumber - Row.LineNumber;
							TabularSection.Move(Index, Offset);
						EndIf;
						CurrentSetObject.Write();
						
					ElsIf Command = "EditDeletionMark" Then
						Row = Properties.FindByID(Items.Properties.CurrentRow);
						
						If Row.Common Then
							TabularSection.Delete(Index);
							CurrentSetObject.Write();
							Properties.Delete(Row);
							If TabularSection.Count() > Index Then
								Items.Properties.CurrentRow = Properties[Index].GetID();
							ElsIf TabularSection.Count() > 0 Then
								Items.Properties.CurrentRow = Properties[Properties.Count()-1].GetID();
							EndIf;
						Else
							TabularSection[Index].DeletionMark = NOT TabularSection[Index].DeletionMark;
							CurrentSetObject.Write();
							
							ChangeDeletionMarkAndValuesOwner(
								CurrentSetObject.Ref,
								TabularSection[Index].Property,
								TabularSection[Index].DeletionMark);
						EndIf;
					EndIf;
				EndIf;
			EndIf;
			
			CommitTransaction();
		Except
			RollbackTransaction();
			Raise;
		EndTry;
	Except
		UnlockDataForEdit(CurrentSet);
		Raise;
	EndTry;
	
	OnChangeCurrentSetAtServer();
	
EndProcedure

&AtServer
Procedure ChangeDeletionMarkAndValuesOwner(CurrentSet, CurrentProperty, PropertyDeletionMark)
	
	OldValuesOwner = CurrentProperty;
	
	NewValuesMark   = Undefined;
	NewValuesOwner  = Undefined;
	
	ObjectProperty = CurrentProperty.GetObject();
	
	If ValueIsFilled(ObjectProperty.PropertiesSet) Then
		
		If PropertyDeletionMark Then
			// Upon marking a unique property:
			// - mark the property,
			// - if there are ones that were created by a template and not marked for deletion, then set a new 
			//   value owner and specify a new template for all properties, otherwise, mark all the values for 
			//   deletion.
			//   
			ObjectProperty.DeletionMark = True;
			
			If NOT ValueIsFilled(ObjectProperty.AdditionalValuesOwner) Then
				Query = New Query;
				Query.SetParameter("Property", ObjectProperty.Ref);
				Query.Text =
				"SELECT
				|	Properties.Ref,
				|	Properties.DeletionMark
				|FROM
				|	ChartOfCharacteristicTypes.AdditionalAttributesAndInfo AS Properties
				|WHERE
				|	Properties.AdditionalValuesOwner = &Property";
				DataExported = Query.Execute().Unload();
				FoundRow = DataExported.Find(False, "DeletionMark");
				If FoundRow <> Undefined Then
					NewValuesOwner  = FoundRow.Ref;
					ObjectProperty.AdditionalValuesOwner = NewValuesOwner;
					For each Row In DataExported Do
						CurrentObject = Row.Ref.GetObject();
						If CurrentObject.Ref = NewValuesOwner Then
							CurrentObject.AdditionalValuesOwner = Undefined;
						Else
							CurrentObject.AdditionalValuesOwner = NewValuesOwner;
						EndIf;
						CurrentObject.Write();
					EndDo;
				Else
					NewValuesMark = True;
				EndIf;
			EndIf;
			ObjectProperty.Write();
		Else
			If ObjectProperty.DeletionMark Then
				ObjectProperty.DeletionMark = False;
				ObjectProperty.Write();
			EndIf;
			// Upon removing a mark from a unique property:
			// - remove a mark from the property,
			// - if the property is created by sample, then if the template is marked for deletion, set a new 
			//   value owner or the current one for all properties and remove the deletion mark from the values
			//     
			//     
			//   otherwise, remove the deletion mark from values.
			If NOT ValueIsFilled(ObjectProperty.AdditionalValuesOwner) Then
				NewValuesMark = False;
				
			ElsIf Common.ObjectAttributeValue(
			            ObjectProperty.AdditionalValuesOwner, "DeletionMark") Then
				
				Query = New Query;
				Query.SetParameter("Property", ObjectProperty.AdditionalValuesOwner);
				Query.Text =
				"SELECT
				|	Properties.Ref AS Ref
				|FROM
				|	ChartOfCharacteristicTypes.AdditionalAttributesAndInfo AS Properties
				|WHERE
				|	Properties.AdditionalValuesOwner = &Property";
				Array = Query.Execute().Unload().UnloadColumn("Ref");
				Array.Add(ObjectProperty.AdditionalValuesOwner);
				NewValuesOwner = ObjectProperty.Ref;
				For each CurrentRef In Array Do
					If CurrentRef = NewValuesOwner Then
						Continue;
					EndIf;
					CurrentObject = CurrentRef.GetObject();
					CurrentObject.AdditionalValuesOwner = NewValuesOwner;
					CurrentObject.Write();
				EndDo;
				OldValuesOwner = ObjectProperty.AdditionalValuesOwner;
				ObjectProperty.AdditionalValuesOwner = Undefined;
				ObjectProperty.Write();
				NewValuesMark = False;
			EndIf;
		EndIf;
	EndIf;
	
	If NewValuesMark  = Undefined
	   AND NewValuesOwner = Undefined Then
		Return;
	EndIf;
	
	Query = New Query;
	Query.SetParameter("Owner", OldValuesOwner);
	Query.Text =
	"SELECT
	|	ObjectsPropertiesValues.Ref AS Ref,
	|	ObjectsPropertiesValues.DeletionMark AS DeletionMark
	|FROM
	|	Catalog.ObjectsPropertiesValues AS ObjectsPropertiesValues
	|WHERE
	|	ObjectsPropertiesValues.Owner = &Owner
	|
	|UNION ALL
	|
	|SELECT
	|	ObjectPropertyValueHierarchy.Ref,
	|	ObjectPropertyValueHierarchy.DeletionMark
	|FROM
	|	Catalog.ObjectPropertyValueHierarchy AS ObjectPropertyValueHierarchy
	|WHERE
	|	ObjectPropertyValueHierarchy.Owner = &Owner";
	
	DataExported = Query.Execute().Unload();
	
	If NewValuesOwner <> Undefined Then
		For each Row In DataExported Do
			CurrentObject = Row.Ref.GetObject();
			
			If CurrentObject.Owner <> NewValuesOwner Then
				CurrentObject.Owner = NewValuesOwner;
			EndIf;
			
			If CurrentObject.Modified() Then
				CurrentObject.DataExchange.Load = True;
				CurrentObject.Write();
			EndIf;
		EndDo;
	EndIf;
	
	If NewValuesMark <> Undefined Then
		For each Row In DataExported Do
			CurrentObject = Row.Ref.GetObject();
			
			If CurrentObject.DeletionMark <> NewValuesMark Then
				CurrentObject.DeletionMark = NewValuesMark;
			EndIf;
			
			If CurrentObject.Modified() Then
				CurrentObject.Write();
			EndIf;
		EndDo;
	EndIf;
	
EndProcedure

#EndRegion
