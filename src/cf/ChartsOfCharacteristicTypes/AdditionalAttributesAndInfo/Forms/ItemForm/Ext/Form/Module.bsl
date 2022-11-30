///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Variables

&AtClient
Var ContinuationHandlerOnWriteError, CancelOnWrite;

#EndRegion

#Region EventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	InfobaseUpdate.CheckObjectProcessed(Object, ThisObject);
	
	NewPassedParametersStructure();
	
	If PassedFormParameters.CopyWithQuestion
		AND Not GetFunctionalOption("UseAdditionalCommonAttributesAndInfo")
		AND (Not AttributeWithAdditionalValuesList()
			Or Not GetFunctionalOption("UseCommonAdditionalValues")) Then
		PassedFormParameters.CopyWithQuestion = False;
		PassedFormParameters.CopyingValue = PassedFormParameters.AdditionalValuesOwner;
	EndIf;
	
	If PassedFormParameters.SelectCommonProperty
		Or PassedFormParameters.SelectAdditionalValueOwner
		Or PassedFormParameters.CopyWithQuestion Then
		ThisObject.WindowOpeningMode = FormWindowOpeningMode.LockOwnerWindow;
		WizardMode               = True;
		If PassedFormParameters.CopyWithQuestion Then
			Items.WIzardCardPages.CurrentPage = Items.ActionChoice;
			FillActionListOnAddAttribute();
		Else
			FillChoicePage();
		EndIf;
		RefreshFormItemsContent();
		
		If Common.IsWebClient() Then
			Items.AttributeCard.Visible = False;
		EndIf;
	Else
		FillAttributeOrInfoCard();
		// Object attribute lock subsystem handler.
		ObjectAttributesLock.LockAttributes(ThisObject);
	EndIf;
	
	If Not Common.SubsystemExists("StandardSubsystems.DuplicateObjectDetection") Then
		Items.FormDuplicateObjectsDetection.Visible = False;
	EndIf;
	
	Items.MultilineGroup.Representation          = UsualGroupRepresentation.NormalSeparation;
	If Not PropertyManagerInternal.ValueTypeContainsPropertyValues(Object.ValueType) Then
		Items.PropertiesAndDependenciesGroup.Representation = UsualGroupRepresentation.NormalSeparation;
		Items.OtherAttributes.Representation         = UsualGroupRepresentation.NormalSeparation;
	EndIf;
	
	If Common.IsMobileClient() Then
		Items.PropertiesSets.InitialTreeView = InitialTreeView.ExpandAllLevels;
		Items.AdditionalInformationGroup.Representation = UsualGroupRepresentation.NormalSeparation;
		Items.Close.Visible = False;
		Items.AttributeDescriptionGroup.ItemsAndTitlesAlign = ItemsAndTitlesAlignVariant.ItemsRightTitlesLeft;
		Items.AttributeValueType.ItemsAndTitlesAlign        = ItemsAndTitlesAlignVariant.ItemsRightTitlesLeft;
	EndIf;
	
	ItemsToLocalize = New Array;
	ItemsToLocalize.Add(Items.Title);
	ItemsToLocalize.Add(Items.ToolTip);
	ItemsToLocalize.Add(Items.ValueFormTitle);
	ItemsToLocalize.Add(Items.ValueChoiceFormTitle);
	LocalizationServer.OnCreateAtServer(ItemsToLocalize);
	
EndProcedure

&AtClient
Procedure ChoiceProcessing(SelectedValue, ChoiceSource)
	
	If TypeOf(SelectedValue) = Type("ChartOfCharacteristicTypesRef.AdditionalAttributesAndInfo") Then
		Close();
		
		// Opening the property form.
		FormParameters = New Structure;
		FormParameters.Insert("Key", SelectedValue);
		FormParameters.Insert("CurrentPropertiesSet", CurrentPropertiesSet);
		
		OpenForm("ChartOfCharacteristicTypes.AdditionalAttributesAndInfo.ObjectForm",
			FormParameters, FormOwner);
	EndIf;
	
EndProcedure

&AtClient
Procedure BeforeWrite(Cancel, WriteParameters)
	
	If NOT WriteParameters.Property("WhenDescriptionAlreadyInUse") Then
	
		// Fill in description by property set and check if there is a property with the same description.
		// 
		QuestionText = DescriptionAlreadyUsed(
			Object.Title, Object.Ref, Object.PropertiesSet, Object.Description, Object.Presentations);
		
		If ValueIsFilled(QuestionText) Then
			Buttons = New ValueList;
			Buttons.Add("ContinueWrite",            NStr("ru = 'Продолжить запись'; en = 'Continue writing'; pl = 'Kontynuuj zapisywanie';de = 'Weiter schreiben';ro = 'Continuați să scrieți';tr = 'Yazmaya devam et'; es_ES = 'Continuar la grabación'"));
			Buttons.Add("BackToDescriptionInput", NStr("ru = 'Вернуться к вводу наименования'; en = 'Back to description input'; pl = 'Wróć do wprowadzania nazwy';de = 'Zurück zur Namenseingabe';ro = 'Revenire la introducerea denumirii';tr = 'İsim girişine dön'; es_ES = 'Volver a la introducción del nombre'"));
			
			ShowQueryBox(
				New NotifyDescription("AfterResponseOnQuestionWhenDescriptionIsAlreadyUsed", ThisObject, WriteParameters),
				QuestionText, Buttons, , "BackToDescriptionInput");
			
			CancelOnWrite = True;
			Cancel = True;
			Return;
		EndIf;
	EndIf;
	
	If NOT WriteParameters.Property("WhenNameAlreadyInUse")
		AND ValueIsFilled(Object.Name) Then
		// Fill in description by property set and check if there is a property with the same description.
		// 
		QuestionText = NameAlreadyUsed(
			Object.Name, Object.Ref, Object.PropertiesSet, Object.Description);
		
		If ValueIsFilled(QuestionText) Then
			Buttons = New ValueList;
			Buttons.Add("ContinueWrite",            NStr("ru = 'Продолжить'; en = 'Continue'; pl = 'Kontynuuj';de = 'Weiter';ro = 'Continuare';tr = 'Devam'; es_ES = 'Continuar'"));
			Buttons.Add("BackToNameInput", NStr("ru = 'Отмена'; en = 'Cancel'; pl = 'Anuluj';de = 'Abbrechen';ro = 'Revocare';tr = 'İptal'; es_ES = 'Cancelar'"));
			
			ShowQueryBox(
				New NotifyDescription("AfterResponseOnQuestionWhenNameIsAlreadyUsed", ThisObject, WriteParameters),
				QuestionText, Buttons, , "ContinueWrite");
			
			CancelOnWrite = True;
			Cancel = True;
			Return;
		EndIf;
	EndIf;
	
	If WriteParameters.Property("ContinuationHandler") Then
		ContinuationHandlerOnWriteError = WriteParameters.ContinuationHandler;
		AttachIdleHandler("AfterWriteError", 0.1, True);
	EndIf;
	
EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	If PropertyManagerInternal.ValueTypeContainsPropertyValues(Object.ValueType) Then
		CurrentObject.AdditionalValuesUsed = True;
	Else
		CurrentObject.AdditionalValuesUsed = False;
		CurrentObject.ValueFormTitle = "";
		CurrentObject.ValueChoiceFormTitle = "";
	EndIf;
	
	If Object.IsAdditionalInfo
	 OR NOT (    Object.ValueType.ContainsType(Type("Number" ))
	         OR Object.ValueType.ContainsType(Type("Date"  ))
	         OR Object.ValueType.ContainsType(Type("Boolean")) )Then
		
		CurrentObject.FormatProperties = "";
	EndIf;
	
	CurrentObject.MultilineInputField = 0;
	
	If NOT Object.IsAdditionalInfo
	   AND Object.ValueType.Types().Count() = 1
	   AND Object.ValueType.ContainsType(Type("String")) Then
		
		If AttributePresentation = "MultilineInputField" Then
			CurrentObject.MultilineInputField   = MultilineInputFieldNumber;
			CurrentObject.OutputAsHyperlink = False;
		EndIf;
	EndIf;
	
	// Generating additional attribute or info name.
	If Not ValueIsFilled(CurrentObject.Name)
		Or WriteParameters.Property("WhenNameAlreadyInUse") Then
		CurrentObject.Name = "";
		ObjectTitle = CurrentObject.Title;
		PropertyManagerInternal.DeleteDisallowedCharacters(ObjectTitle);
		ObjectTitleInParts = StrSplit(ObjectTitle, " ", False);
		For Each TitlePart In ObjectTitleInParts Do
			CurrentObject.Name = CurrentObject.Name + Upper(Left(TitlePart, 1)) + Mid(TitlePart, 2);
		EndDo;
		
		UID = New UUID();
		UIDString = StrReplace(String(UID), "-", "");
		CurrentObject.Name = CurrentObject.Name + "_" + UIDString;
	EndIf;
	
	LocalizationServer.BeforeWriteAtServer(CurrentObject);
	
EndProcedure

&AtServer
Procedure OnWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	If ValueIsFilled(CurrentObject.PropertiesSet) Then
		AddToSet = CurrentObject.PropertiesSet;
		
		Lock = New DataLock;
		LockItem = Lock.Add("Catalog.AdditionalAttributesAndInfoSets");
		LockItem.SetValue("Ref", AddToSet);
		Lock.Lock();
		LockDataForEdit(AddToSet);
		
		ObjectPropertySet = AddToSet.GetObject();
		If CurrentObject.IsAdditionalInfo Then
			TabularSection = ObjectPropertySet.AdditionalInfo;
		Else
			TabularSection = ObjectPropertySet.AdditionalAttributes;
		EndIf;
		FoundRow = TabularSection.Find(CurrentObject.Ref, "Property");
		If FoundRow = Undefined Then
			NewRow = TabularSection.Add();
			NewRow.Property = CurrentObject.Ref;
			ObjectPropertySet.Write();
			CurrentObject.AdditionalProperties.Insert("ModifiedSet", AddToSet);
		EndIf;
		
	EndIf;
	
	If WriteParameters.Property("ClearEnteredWeightCoefficients") Then
		ClearEnteredWeightCoefficients();
	EndIf;
	
EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)

	// StandardSubsystems.AccessManagement
	If Common.SubsystemExists("StandardSubsystems.AccessManagement") Then
		ModuleAccessManagement = Common.CommonModule("AccessManagement");
		ModuleAccessManagement.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	EndIf;
	// End StandardSubsystems.AccessManagement
	
	If AttributeAddMode = "CreateByCopying" Then
		WriteAdditionalAttributeValuesOnCopy(CurrentObject);
	EndIf;
	
	// Object attribute lock subsystem handler.
	ObjectAttributesLock.LockAttributes(ThisObject);
	
	RefreshFormItemsContent();
	
	If CurrentObject.AdditionalProperties.Property("ModifiedSet") Then
		WriteParameters.Insert("ModifiedSet", CurrentObject.AdditionalProperties.ModifiedSet);
	EndIf;
	
EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)
	
	Notify("Write_AdditionalAttributesAndInfo",
		New Structure("Ref", Object.Ref), Object.Ref);
	
	If WriteParameters.Property("ModifiedSet") Then
		
		Notify("Write_AdditionalDataAndAttributeSets",
			New Structure("Ref", WriteParameters.ModifiedSet), WriteParameters.ModifiedSet);
	EndIf;
	
	If WriteParameters.Property("ContinuationHandler") Then
		ContinuationHandlerOnWriteError = Undefined;
		DetachIdleHandler("AfterWriteError");
		ExecuteNotifyProcessing(
			New NotifyDescription(WriteParameters.ContinuationHandler.ProcedureName,
				ThisObject, WriteParameters.ContinuationHandler.Parameters),
			False);
	EndIf;
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	If WizardMode Then
		SetWizardSettings();
	EndIf;
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	If EventName = "Properties_AttributeDependencySet" Then
		Modified = True;
		ValueAdded = False;
		For Each DependenceCondition In AttributeDependencyConditions Do
			Value = Undefined;
			If Parameter.Property(DependenceCondition.Presentation, Value) Then
				ValueInStorage = PutToTempStorage(Value, UUID);
				DependenceCondition.Value = ValueInStorage;
				ValueAdded = True;
			EndIf;
		EndDo;
		If Not ValueAdded Then
			For Each PassedParameter In Parameter Do
				ValueInStorage = PutToTempStorage(PassedParameter.Value, UUID);
				AttributeDependencyConditions.Add(ValueInStorage, PassedParameter.Key);
			EndDo;
		EndIf;
		
		SetAdditionalAttributeDependencies();
	EndIf;
	
EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)

	// StandardSubsystems.AccessManagement
	If Common.SubsystemExists("StandardSubsystems.AccessManagement") Then
		ModuleAccessManagement = Common.CommonModule("AccessManagement");
		ModuleAccessManagement.OnReadAtServer(ThisObject, CurrentObject);
	EndIf;
	// End StandardSubsystems.AccessManagement
	
	LocalizationServer.OnReadAtServer(ThisObject, CurrentObject);
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure IsAdditionalInfoOnChange(Item)
	
	Object.IsAdditionalInfo = IsAdditionalInfo;
	
	RefreshFormItemsContent();
	
EndProcedure

&AtClient
Procedure ValueListAdjustmentCommentClick(Item)
	
	WriteObject("GoToValueList",
		"ValueListAdjustmentCommentClickCompletion");
	
EndProcedure

&AtClient
Procedure SetAdjustmentCommentClick(Item)
	
	WriteObject("GoToValueList",
		"SetAdjustmentCommentClickFollowUp");
	
EndProcedure

&AtClient
Procedure ValueTypeOnChange(Item)
	
	WarningText = "";
	RefreshFormItemsContent(WarningText);
	
	If ValueIsFilled(WarningText) Then
		ShowMessageBox(, WarningText);
	EndIf;
	
EndProcedure

&AtClient
Procedure AdditionalValuesWithWeightOnChange(Item)
	
	If ValueIsFilled(Object.Ref)
	   AND NOT Object.AdditionalValuesWithWeight Then
		
		QuestionText =
			NStr("ru = 'Очистить введенные весовые коэффициенты?
			           |
			           |Данные будут записаны.'; 
			           |en = 'Do you want to clear the entered weight coefficients?
			           |
			           |The data will be written.'; 
			           |pl = 'Oczyścić wprowadzone współczynniki wagowe?
			           |
			           |Dane zostaną zapisane.';
			           |de = 'Die eingegebenen Gewichtswerte löschen?
			           |
			           |Die Daten werden aufgezeichnet.';
			           |ro = 'Goliți coeficienții de greutate introduși?
			           |
			           |Datele vor fi înregistrate.';
			           |tr = 'Girilen ağırlık katsayıları temizlensin mi? 
			           |
			           |Veri yazılacak.'; 
			           |es_ES = '¿Eliminar los coeficientes de peso introducidos?
			           |
			           |Datos se guardarán.'");
		
		Buttons = New ValueList;
		Buttons.Add("ClearAndWrite", NStr("ru = 'Очистить и записать'; en = 'Clear and write'; pl = 'Oczyść i zapisz';de = 'Löschen und schreiben';ro = 'Ștergeți și scrieți';tr = 'Temizle ve yaz'; es_ES = 'Eliminar y grabar'"));
		Buttons.Add("Cancel", NStr("ru = 'Отмена'; en = 'Cancel'; pl = 'Anuluj';de = 'Abbrechen';ro = 'Revocare';tr = 'İptal'; es_ES = 'Cancelar'"));
		
		ShowQueryBox(
			New NotifyDescription("AfterConfirmClearWeightCoefficients", ThisObject),
			QuestionText, Buttons, , "ClearAndWrite");
	Else
		WriteObject("WeightUsageEdit",
			"AdditionalValuesWithWeightOnChangeCompletion");
	EndIf;
	
EndProcedure

&AtClient
Procedure MultilineInputFieldNumberOnChange(Item)
	
	AttributePresentation = "MultilineInputField";
	
EndProcedure

&AtClient
Procedure CommentOpen(Item, StandardProcessing)
	
	StandardProcessing = False;
	CommonClient.ShowCommentEditingForm(Item.EditText, ThisObject);
	
EndProcedure

&AtClient
Procedure RequiredToFillOnChange(Item)
	Items.ChooseItemRequiredOption.Enabled = Object.RequiredToFill;
EndProcedure

&AtClient
Procedure SetAvailabilityConditionClick(Item)
	OpenDependenceSettingForm("Available");
EndProcedure

&AtClient
Procedure SetConditionClick(Item)
	OpenDependenceSettingForm("RequiredToFill");
EndProcedure

&AtClient
Procedure SetVisibilityConditionClick(Item)
	OpenDependenceSettingForm("Visible");
EndProcedure

&AtClient
Procedure CommentStartChoice(Item, ChoiceData, StandardProcessing)
	CommonClient.ShowCommentEditingForm(Item.EditText, ThisObject);
EndProcedure

&AtClient
Procedure AttributeKindOnChange(Item)
	Items.OutputAsHyperlink.Enabled    = (AttributePresentation = "OneLineInputField");
	Items.MultilineInputFieldNumber.Enabled = (AttributePresentation = "MultilineInputField");
EndProcedure

&AtClient
Procedure TitleOpen(Item, StandardProcessing)
	LocalizationClient.OnOpen(Object, Item, "Title", StandardProcessing);
EndProcedure

&AtClient
Procedure TooltipOpen(Item, StandardProcessing)
	LocalizationClient.OnOpen(Object, Item, "ToolTip", StandardProcessing);
EndProcedure

&AtClient
Procedure ValueFormTitleOpen(Item, StandardProcessing)
	LocalizationClient.OnOpen(Object, Item, "ValueFormTitle", StandardProcessing);
EndProcedure

&AtClient
Procedure ValueChoiceFormTitleOpen(Item, StandardProcessing)
	LocalizationClient.OnOpen(Object, Item, "ValueChoiceFormTitle", StandardProcessing);
EndProcedure

#EndRegion

#Region PropertiesSetsFormTableItemsEventsHandlers

&AtClient
Procedure PropertiesSetsOnActivateRow(Item)
	AttachIdleHandler("OnChangeCurrentSet", 0.1, True)
EndProcedure

&AtClient
Procedure PropertiesSetsBeforeChangeRow(Item, Cancel)
	Cancel = True;
EndProcedure

#EndRegion

#Region PropertiesChoiceFormTableItemsEventsHandlers

&AtClient
Procedure PropertiesChoice(Item, RowSelected, Field, StandardProcessing)
	StandardProcessing = False;
	
	NextCommand(Undefined);
EndProcedure

#EndRegion

#Region ValueFormTableItemEventHandlers

&AtClient
Procedure ValuesOnChange(Item)
	
	If Item.CurrentData = Undefined Then
		Return;
	EndIf;
	
	If Object.ValueType.ContainsType(Type("CatalogRef.ObjectsPropertiesValues")) Then
		EventName = "Write_ObjectPropertyValues";
	Else
		EventName = "Write_ObjectPropertyValueHierarchy";
	EndIf;
	
	Notify(EventName,
		New Structure("Ref", Item.CurrentData.Ref),
		Item.CurrentData.Ref);
	
EndProcedure

&AtClient
Procedure ValuesBeforeAddRow(Item, Cancel, Clone, Parent, Folder)
	
	Cancel = True;
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("Copy", Clone);
	AdditionalParameters.Insert("Parent", Parent);
	AdditionalParameters.Insert("Group", Folder);
	
	WriteObject("GoToValueList",
		"BeforeAddRowValuesCompletion", AdditionalParameters);
	
EndProcedure

&AtClient
Procedure ValuesBeforeChangeStart(Item, Cancel)
	
	Cancel = True;
	
	If Items.AdditionalValues.ReadOnly Then
		Return;
	EndIf;
	
	WriteObject("GoToValueList",
		"ValuesBeforeChangeRowCompletion");
	
EndProcedure

#EndRegion

#Region FormCommandHandlers

&AtClient
Procedure NextCommand(Command)
	
#If WebClient Then
	If Not Items.AttributeCard.Visible Then
		Items.AttributeCard.Visible = True;
	EndIf;
#EndIf
	
	If AttributeAddMode = "MakeCommon" Then
		ConvertAdditionalAttributeToCommonOne();
	EndIf;
	
	If AttributeAddMode = "AddCommonAttributeToSet"
		Or AttributeAddMode = "MakeCommon" Then
		Result = New Structure;
		Result.Insert("CommonProperty", PassedFormParameters.AdditionalValuesOwner);
		If PassedFormParameters.Drag Then
			Result.Insert("Drag", True);
		EndIf;
		NotifyChoice(Result);
		Return;
	EndIf;
	
	MainPage = Items.WIzardCardPages;
	PageIndex = MainPage.ChildItems.IndexOf(MainPage.CurrentPage);
	If PageIndex = 0
		AND Items.Properties.CurrentData = Undefined Then
		WarningText = NStr("ru = 'Элемент не выбран.'; en = 'Item is not selected.'; pl = 'Element nie został wybrany.';de = 'Element nicht ausgewählt.';ro = 'Elementul nu este selectat.';tr = 'Öğe seçilmedi.'; es_ES = 'Elemento no seleccionado.'");
		ShowMessageBox(, WarningText);
		Return;
	EndIf;
	If PageIndex = 2 Then
		If Not CheckFilling() Then
			Return;
		EndIf;
		
		If AttributeAddMode = "CreateByCopying" Then
			Items.AttributeValuePages.CurrentPage = Items.AdditionalValues;
		EndIf;
		
		Write();
		If CancelOnWrite <> True Then
			Close();
		EndIf;
		Return;
	EndIf;
	CurrentPage = MainPage.ChildItems.Get(PageIndex + 1);
	SetWizardSettings(CurrentPage);
	
	OnChangePage("Forward", MainPage, CurrentPage);
	
EndProcedure

&AtClient
Procedure BackCommand(Command)
	
	MainPage = Items.WIzardCardPages;
	PageIndex = MainPage.ChildItems.IndexOf(MainPage.CurrentPage);
	If PageIndex = 1 Then
		AttributeAddMode = "";
	EndIf;
	CurrentPage = MainPage.ChildItems.Get(PageIndex - 1);
	SetWizardSettings(CurrentPage);
	
	OnChangePage("Back", MainPage, CurrentPage);
	
EndProcedure

&AtClient
Procedure CloseForm(Command)
	Close();
EndProcedure

&AtClient
Procedure EditValueFormat(Command)
	
	Designer = New FormatStringWizard(Object.FormatProperties);
	
	Designer.AvailableTypes = Object.ValueType;
	
	Designer.Show(
		New NotifyDescription("EditValueFormatCompletion", ThisObject));
	
EndProcedure

&AtClient
Procedure ValueListAdjustmentChange(Command)
	
	WriteObject("AttributeKindEdit",
		"ValueListAdjustmentChangeCompletion");
	
EndProcedure

&AtClient
Procedure SetsAdjustmentChange(Command)
	
	WriteObject("AttributeKindEdit",
		"ChangeSetAdjustmentCompletion");
	
EndProcedure

&AtClient
Procedure Attachable_AllowObjectAttributesEditing(Command)
	
	LockedAttributes = ObjectAttributesLockClient.Attributes(ThisObject);
	
	If LockedAttributes.Count() > 0 Then
		
		FormParameters = New Structure;
		FormParameters.Insert("Ref", Object.Ref);
		FormParameters.Insert("IsAdditionalAttribute", Not Object.IsAdditionalInfo);
		
		Notification = New NotifyDescription("AfterAttributesToUnlockChoice", ThisObject);
		OpenForm("ChartOfCharacteristicTypes.AdditionalAttributesAndInfo.Form.AttributeUnlocking",
			FormParameters, ThisObject,,,, Notification);
	Else
		ObjectAttributesLockClient.ShowAllVisibleAttributesUnlockedWarning();
	EndIf;
	
EndProcedure

&AtClient
Procedure DuplicateObjectsDetection(Command)
	ModuleDuplicateObjectsDetectionClient = CommonClient.CommonModule("FindAndDeleteDuplicatesDuplicatesClient");
	DuplicateObjectsDetectionFormName = ModuleDuplicateObjectsDetectionClient.DuplicateObjectsDetectionDataProcessorFormName();
	OpenForm(DuplicateObjectsDetectionFormName);
EndProcedure

&AtClient
Procedure Change(Command)
	
	If Items.Properties.CurrentData <> Undefined Then
		// Opening the property form.
		FormParameters = New Structure;
		FormParameters.Insert("Key", Items.Properties.CurrentData.Property);
		FormParameters.Insert("CurrentPropertiesSet", SelectedPropertiesSet);
		
		OpenForm("ChartOfCharacteristicTypes.AdditionalAttributesAndInfo.ObjectForm",
			FormParameters, Items.Properties,,,,, FormWindowOpeningMode.LockOwnerWindow);
	EndIf;
	
EndProcedure

&AtClient
Procedure SharedAttributesNotIncludedInSets(Command)
	NewValue = Not Items.SharedAttributesNotIncludedInSets.Check;
	Items.SharedAttributesNotIncludedInSets.Check = NewValue;
	If NewValue Then
		Items.PropertiesSetsPages.CurrentPage = Items.SharedSetsPage;
	Else
		Items.PropertiesSetsPages.CurrentPage = Items.AllSetsPage;
	EndIf;
	
	DisplayShowCommonAttributesWithoutSets();
	
EndProcedure

&AtServer
Procedure DisplayShowCommonAttributesWithoutSets()
	
	UpdateCurrentSetPropertiesList();
	
EndProcedure

&AtClient
Procedure SetClearDeletionMark(Command)
	WriteObject("DeletionMarkEdit", "SetClearDeletionMarkFollowUp");
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SetAdditionalAttributeDependencies()
	
	If AttributeDependencyConditions.Count() = 0 Then
		Return;
	EndIf;
	
	CurrentObject = FormAttributeToValue("Object");
	
	AdditionalAttributesDependencies = CurrentObject.AdditionalAttributesDependencies;
	
	For Each DependenceCondition In AttributeDependencyConditions Do
		RowsFilter = New Structure;
		RowsFilter.Insert("DependentProperty", DependenceCondition.Presentation);
		RowsArray = AdditionalAttributesDependencies.FindRows(RowsFilter);
		For Each TabularSectionRow In RowsArray Do
			AdditionalAttributesDependencies.Delete(TabularSectionRow);
		EndDo;
		
		ValueFromStorage = GetFromTempStorage(DependenceCondition.Value);
		If ValueFromStorage = Undefined Then
			Continue;
		EndIf;
		For Each NewDependence In ValueFromStorage.Get() Do
			FillPropertyValues(CurrentObject.AdditionalAttributesDependencies.Add(), NewDependence);
		EndDo;
	EndDo;
	
	ValueToFormAttribute(CurrentObject, "Object");
	
	SetHyperlinkTitles();
	
EndProcedure

&AtServer
Procedure FillChoicePage()
	
	If PassedFormParameters.IsAdditionalInfo <> Undefined Then
		IsAdditionalInfo = PassedFormParameters.IsAdditionalInfo;
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
	For Each Ref In Sets Do
		SetPropertiesTypes = PropertyManagerInternal.SetPropertiesTypes(Ref, False);
		
		If IsAdditionalInfo = 1
		   AND SetPropertiesTypes.AdditionalInfo
		 OR IsAdditionalInfo = 0
		   AND SetPropertiesTypes.AdditionalAttributes Then
			
			AvailableSets.Add(Ref);
		EndIf;
	EndDo;
	
	CurrentSetParent = Common.ObjectAttributeValue(
		PassedFormParameters.CurrentPropertiesSet, "Parent");
	SetsToExclude = New Array;
	SetsToExclude.Add(PassedFormParameters.CurrentPropertiesSet);
	If ValueIsFilled(CurrentSetParent) Then
		PredefinedSets = PropertyManagerCached.PredefinedPropertiesSets();
		SetProperties = PredefinedSets.Get(CurrentSetParent);
		If SetProperties = Undefined Then
			PredefinedDataName = Common.ObjectAttributeValue(CurrentSetParent, "PredefinedDataName");
		Else
			PredefinedDataName = SetProperties.Name;
		EndIf;
		ReplacedCharacterPosition = StrFind(PredefinedDataName, "_");
		FullObjectName = Left(PredefinedDataName, ReplacedCharacterPosition - 1)
			             + "."
			             + Mid(PredefinedDataName, ReplacedCharacterPosition + 1);
		Manager         = Common.ObjectManagerByFullName(FullObjectName);
		
		If StrStartsWith(FullObjectName, "Document") Then
			NewObject = Manager.CreateDocument();
		Else
			NewObject = Manager.CreateItem();
		EndIf;
		ObjectSets = PropertyManagerInternal.GetObjectPropertySets(NewObject);
		
		FilterParameters = New Structure;
		FilterParameters.Insert("CommonSet", True);
		FoundRows = ObjectSets.FindRows(FilterParameters);
		For Each FoundRow In FoundRows Do
			If PassedFormParameters.CurrentPropertiesSet = FoundRow.Set Then
				Continue;
			EndIf;
			SetsToExclude.Add(FoundRow.Set);
		EndDo;
	EndIf;
	
	If IsAdditionalInfo = 1 Then
		Items.SharedAttributesNotIncludedInSets.Title = NStr("ru ='Только общие дополнительные сведения'; en = 'Only shared additional information records'; pl = 'Tylko wspólne informacje dodatkowe';de = 'Nur allgemeine Zusatzinformationen';ro = 'Numai datele suplimentare comune';tr = 'Sadece genel ek bilgiler'; es_ES = 'Solo la información adicional común'");
	Else
		Items.SharedAttributesNotIncludedInSets.Title = NStr("ru ='Только общие дополнительные реквизиты'; en = 'Only shared additional attributes'; pl = 'Tylko wspólne atrybuty dodatkowe';de = 'Nur allgemeine Zusatzattribute';ro = 'Numai atributele suplimentare comune';tr = 'Sadece genel ek alanlar'; es_ES = 'Solo los requisitos adicionales comunes'");
	EndIf;
	
	CommonClientServer.SetDynamicListParameter(
		PropertiesSets, "Sets", AvailableSets, True);
	
	CommonClientServer.SetDynamicListParameter(
		PropertiesSets, "SetsToExclude", SetsToExclude, True);
	
	CommonClientServer.SetDynamicListParameter(
		PropertiesSets, "IsAdditionalInfo", (IsAdditionalInfo = 1), True);
	
	CommonClientServer.SetDynamicListParameter(
		CommonPropertySets, "IsAdditionalInfo", (IsAdditionalInfo = 1), True);
	
	CommonClientServer.SetDynamicListParameter(
		CommonPropertySets, "CommonAdditionalInfo", NStr("ru = 'Общие дополнительные сведения'; en = 'Shared additional information records'; pl = 'Wspólne informacje dodatkowe';de = 'Allgemeine Zusatzinformationen';ro = 'Date suplimentare comune';tr = 'Genel ek bilgiler'; es_ES = 'Información adicional común'"), True);
	
	CommonClientServer.SetDynamicListParameter(
		CommonPropertySets, "CommonAdditionalAttributes", NStr("ru = 'Общие дополнительные реквизиты'; en = 'Shared additional attributes'; pl = 'Wspólne atrybuty dodatkowe';de = 'Allgemeine Zusatzattribute';ro = 'Atribute suplimentare comune';tr = 'Genel ek alanlar'; es_ES = 'Requisitos adicionales comunes'"), True);
	
	SetConditionalListAppearance(AvailableSets);
	
EndProcedure

&AtServer
Procedure SetConditionalListAppearance(AvailableSetsList)
	
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
	
EndProcedure

&AtServer
Procedure FillAdditionalAttributesValues(ValuesOwner)
	
	ValuesTree = FormAttributeToValue("AdditionalAttributesValues");
	
	Query = New Query;
	Query.Text =
		"SELECT
		|	ObjectsPropertiesValues.Ref AS Ref,
		|	ObjectsPropertiesValues.Owner AS Owner,
		|	0 AS PictureCode,
		|	ObjectsPropertiesValues.Weight,
		|	PRESENTATION(ObjectsPropertiesValues.Ref) AS Description
		|FROM
		|	Catalog.ObjectsPropertiesValues AS ObjectsPropertiesValues
		|WHERE
		|	ObjectsPropertiesValues.DeletionMark = FALSE
		|	AND ObjectsPropertiesValues.Owner = &Owner
		|
		|UNION ALL
		|
		|SELECT
		|	ObjectPropertyValueHierarchy.Ref,
		|	ObjectPropertyValueHierarchy.Owner,
		|	0,
		|	ObjectPropertyValueHierarchy.Weight,
		|	PRESENTATION(ObjectPropertyValueHierarchy.Description) AS Description
		|FROM
		|	Catalog.ObjectPropertyValueHierarchy AS ObjectPropertyValueHierarchy
		|WHERE
		|	ObjectPropertyValueHierarchy.DeletionMark = FALSE
		|	AND ObjectPropertyValueHierarchy.Owner = &Owner
		|
		|ORDER BY
		|	Ref HIERARCHY";
	Query.SetParameter("Owner", ValuesOwner);
	Result = Query.Execute().Unload(QueryResultIteration.ByGroupsWithHierarchy);
	
	ValuesTree = Result.Copy();
	ValueToFormAttribute(ValuesTree, "AdditionalAttributesValues");
	
EndProcedure

&AtServer
Procedure ConvertAdditionalAttributeToCommonOne()
	BeginTransaction();
	Try
		SelectedAttribute = PassedFormParameters.AdditionalValuesOwner;
		SelectedAttributeObject = SelectedAttribute.GetObject();
		SelectedAttributeObject.PropertiesSet = Catalogs.AdditionalAttributesAndInfoSets.EmptyRef();
		SelectedAttributeObject.Description = SelectedAttributeObject.Title;
		SelectedAttributeObject.Write();
		
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;
EndProcedure

&AtServer
Procedure FillAttributeOrInfoCard()
	
	If ValueIsFilled(PassedFormParameters.CopyingValue) Then
		AttributeAddMode = "CreateByCopying";
	EndIf;
	
	CreateAttributeByCopying = (AttributeAddMode = "CreateByCopying");
	
	CurrentPropertiesSet = PassedFormParameters.CurrentPropertiesSet;
	
	If ValueIsFilled(Object.Ref) Then
		Items.IsAdditionalInfo.Enabled = False;
		ShowSetAdjustment = PassedFormParameters.ShowSetAdjustment;
	Else
		Object.Available = True;
		Object.Visible  = True;
		
		Object.AdditionalAttributesDependencies.Clear();
		If ValueIsFilled(CurrentPropertiesSet) Then
			Object.PropertiesSet = CurrentPropertiesSet;
		EndIf;
		
		If CreateAttributeByCopying Then
			Object.AdditionalValuesOwner = ChartsOfCharacteristicTypes.AdditionalAttributesAndInfo.EmptyRef();
		ElsIf ValueIsFilled(PassedFormParameters.AdditionalValuesOwner) Then
			Object.AdditionalValuesOwner = PassedFormParameters.AdditionalValuesOwner;
		EndIf;
		
		If PassedFormParameters.IsAdditionalInfo <> Undefined Then
			Object.IsAdditionalInfo = PassedFormParameters.IsAdditionalInfo;
			
		ElsIf NOT ValueIsFilled(PassedFormParameters.CopyingValue) Then
			Items.IsAdditionalInfo.Visible = True;
		EndIf;
	EndIf;
	
	If Object.Predefined AND NOT ValueIsFilled(Object.Title) Then
		Object.Title = Object.Description;
	EndIf;
	
	IsAdditionalInfo = ?(Object.IsAdditionalInfo, 1, 0);
	
	If CreateAttributeByCopying Then
		// For cases when the attribute is copied from its card using the Copy command.
		If Not ValueIsFilled(PassedFormParameters.AdditionalValuesOwner) Then
			PassedFormParameters.AdditionalValuesOwner = PassedFormParameters.CopyingValue;
		EndIf;
		
		OwnerProperties = Common.ObjectAttributesValues(
			PassedFormParameters.AdditionalValuesOwner, "ValueType, AdditionalValuesWithWeight, FormatProperties");
		
		Object.ValueType    = OwnerProperties.ValueType;
		Object.FormatProperties = OwnerProperties.FormatProperties;
		
		OwnerValuesWithWeight                                = OwnerProperties.AdditionalValuesWithWeight;
		Object.AdditionalValuesWithWeight                    = OwnerValuesWithWeight;
		Items.AdditionalAttributeValues.Header        = OwnerValuesWithWeight;
		Items.AdditionalAttributeValuesWeight.Visible = OwnerValuesWithWeight;
		Items.AttributeValuePages.CurrentPage     = Items.ValueTreePage;
		
		FillAdditionalAttributesValues(PassedFormParameters.AdditionalValuesOwner);
	EndIf;
	
	RefreshFormItemsContent();
	
	If Object.MultilineInputField > 0 Then
		AttributePresentation = "MultilineInputField";
		MultilineInputFieldNumber = Object.MultilineInputField;
	Else
		AttributePresentation = "OneLineInputField";
	EndIf;
	
	Items.OutputAsHyperlink.Enabled    = (AttributePresentation = "OneLineInputField");
	Items.MultilineInputFieldNumber.Enabled = (AttributePresentation = "MultilineInputField");
	
EndProcedure

&AtClient
Procedure AfterAttributesToUnlockChoice(AttributesToUnlock, Context) Export
	
	If TypeOf(AttributesToUnlock) <> Type("Array") Then
		Return;
	EndIf;
	
	ObjectAttributesLockClient.SetFormItemEnabled(ThisObject,
		AttributesToUnlock);
	
	#If WebClient Then
		RefreshDataRepresentation();
	#EndIf
	
EndProcedure

&AtClient
Procedure AfterResponseOnQuestionWhenDescriptionIsAlreadyUsed(Response, WriteParameters) Export
	
	If Response <> "ContinueWrite" Then
		CurrentItem = Items.Title;
		If WriteParameters.Property("ContinuationHandler") Then
			ExecuteNotifyProcessing(
				New NotifyDescription(WriteParameters.ContinuationHandler.ProcedureName,
					ThisObject, WriteParameters.ContinuationHandler.Parameters),
				True);
		EndIf;
	Else
		WriteParameters.Insert("WhenDescriptionAlreadyInUse");
		Write(WriteParameters);
	EndIf;
	
EndProcedure

&AtClient
Procedure AfterResponseOnQuestionWhenNameIsAlreadyUsed(Response, WriteParameters) Export
	
	If Response <> "ContinueWrite" Then
		CurrentItem = Items.Title;
		If WriteParameters.Property("ContinuationHandler") Then
			ExecuteNotifyProcessing(
				New NotifyDescription(WriteParameters.ContinuationHandler.ProcedureName,
					ThisObject, WriteParameters.ContinuationHandler.Parameters),
				True);
		EndIf;
	Else
		WriteParameters.Insert("WhenNameAlreadyInUse");
		Write(WriteParameters);
	EndIf;
	
EndProcedure

&AtClient
Procedure AfterConfirmClearWeightCoefficients(Response, Context) Export
	
	If Response <> "ClearAndWrite" Then
		Object.AdditionalValuesWithWeight = NOT Object.AdditionalValuesWithWeight;
		Return;
	EndIf;
	
	WriteParameters = New Structure;
	WriteParameters.Insert("ClearEnteredWeightCoefficients");
	
	WriteObject("WeightUsageEdit",
		"AdditionalValuesWithWeightOnChangeCompletion",
		,
		WriteParameters);
	
EndProcedure

&AtClient
Procedure AdditionalValuesWithWeightOnChangeCompletion(Cancel, Context) Export
	
	If Cancel Then
		Object.AdditionalValuesWithWeight = NOT Object.AdditionalValuesWithWeight;
		Return;
	EndIf;
	
	If ValueIsFilled(Object.Ref) Then
		Notify(
			"Change_ValueIsCharacterizedByWeightCoefficient",
			Object.AdditionalValuesWithWeight,
			Object.Ref);
	EndIf;
	
EndProcedure

&AtClient
Procedure ValueListAdjustmentCommentClickCompletion(Cancel, Context) Export
	
	If Cancel Then
		Return;
	EndIf;
	
	Close();
	
	FormParameters = New Structure;
	FormParameters.Insert("ShowSetAdjustment", True);
	FormParameters.Insert("Key", Object.AdditionalValuesOwner);
	FormParameters.Insert("CurrentPropertiesSet", CurrentPropertiesSet);
	
	OpenForm("ChartOfCharacteristicTypes.AdditionalAttributesAndInfo.ObjectForm",
		FormParameters, FormOwner);
	
EndProcedure

&AtClient
Procedure SetAdjustmentCommentClickFollowUp(Cancel, Context) Export
	
	If Cancel Then
		Return;
	EndIf;
	
	If SetsList.Count() > 1 Then
		ShowChooseFromList(
			New NotifyDescription("SetAdjustmentCommentClickCompletion", ThisObject),
			SetsList, Items.SetsAdjustmentComment);
	Else
		SetAdjustmentCommentClickCompletion(Undefined, SetsList[0].Value);
	EndIf;
	
EndProcedure

&AtClient
Procedure SetAdjustmentCommentClickCompletion(SelectedItem, SelectedSet) Export
	
	If SelectedItem <> Undefined Then
		SelectedSet = SelectedItem.Value;
	EndIf;
	
	If Not ValueIsFilled(CurrentPropertiesSet) Then
		Return;
	EndIf;
	
	If SelectedSet <> Undefined Then
		ChoiceValue = New Structure;
		ChoiceValue.Insert("Set", SelectedSet);
		ChoiceValue.Insert("Property", Object.Ref);
		ChoiceValue.Insert("IsAdditionalInfo", Object.IsAdditionalInfo);
		NotifyChoice(ChoiceValue);
	EndIf;
	
EndProcedure

&AtClient
Procedure BeforeAddRowValuesCompletion(Cancel, ProcessingParameters) Export
	
	If Cancel Then
		Return;
	EndIf;
	
	If AttributeAddMode = "CreateByCopying" Then
		Items.AttributeValuePages.CurrentPage = Items.AdditionalValues;
	EndIf;
	
	If Object.ValueType.ContainsType(Type("CatalogRef.ObjectsPropertiesValues")) Then
		ValueTableName = "Catalog.ObjectsPropertiesValues";
	Else
		ValueTableName = "Catalog.ObjectPropertyValueHierarchy";
	EndIf;
	
	FillingValues = New Structure;
	FillingValues.Insert("Parent", ProcessingParameters.Parent);
	FillingValues.Insert("Owner", Object.Ref);
	
	FormParameters = New Structure;
	FormParameters.Insert("HideOwner", True);
	FormParameters.Insert("FillingValues", FillingValues);
	
	If ProcessingParameters.Group Then
		FormParameters.Insert("IsFolder", True);
		
		OpenForm(ValueTableName + ".FolderForm", FormParameters, Items.Values);
	Else
		FormParameters.Insert("ShowWeight", Object.AdditionalValuesWithWeight);
		
		If ProcessingParameters.Copy Then
			FormParameters.Insert("CopyingValue", Items.Values.CurrentRow);
		EndIf;
		
		OpenForm(ValueTableName + ".ObjectForm", FormParameters, Items.Values);
	EndIf;
	
EndProcedure

&AtClient
Procedure ValuesBeforeChangeRowCompletion(Cancel, Context) Export
	
	If Cancel Then
		Return;
	EndIf;
	
	If Object.ValueType.ContainsType(Type("CatalogRef.ObjectsPropertiesValues")) Then
		ValueTableName = "Catalog.ObjectsPropertiesValues";
	Else
		ValueTableName = "Catalog.ObjectPropertyValueHierarchy";
	EndIf;
	
	If Items.Values.CurrentRow <> Undefined Then
		// Opening a value form or a value set.
		FormParameters = New Structure;
		FormParameters.Insert("HideOwner", True);
		FormParameters.Insert("ShowWeight", Object.AdditionalValuesWithWeight);
		FormParameters.Insert("Key", Items.Values.CurrentRow);
		
		OpenForm(ValueTableName + ".ObjectForm", FormParameters, Items.Values);
	EndIf;
	
EndProcedure

&AtClient
Procedure ValueListAdjustmentChangeCompletion(Cancel, Context) Export
	
	If Cancel Then
		Return;
	EndIf;
	
	FormParameters = New Structure;
	FormParameters.Insert("CurrentPropertiesSet", CurrentPropertiesSet);
	FormParameters.Insert("PropertiesSet", Object.PropertiesSet);
	FormParameters.Insert("Property", Object.Ref);
	FormParameters.Insert("AdditionalValuesOwner", Object.AdditionalValuesOwner);
	FormParameters.Insert("IsAdditionalInfo", Object.IsAdditionalInfo);
	
	OpenForm("ChartOfCharacteristicTypes.AdditionalAttributesAndInfo.Form.ChangePropertySettings",
		FormParameters, ThisObject);
	
EndProcedure

&AtClient
Procedure ChangeSetAdjustmentCompletion(Cancel, Context) Export
	
	If Cancel Then
		Return;
	EndIf;
	
	FormParameters = New Structure;
	FormParameters.Insert("CurrentPropertiesSet", CurrentPropertiesSet);
	FormParameters.Insert("Property", Object.Ref);
	FormParameters.Insert("PropertiesSet", Object.PropertiesSet);
	FormParameters.Insert("AdditionalValuesOwner", Object.AdditionalValuesOwner);
	FormParameters.Insert("IsAdditionalInfo", Object.IsAdditionalInfo);
	
	OpenForm("ChartOfCharacteristicTypes.AdditionalAttributesAndInfo.Form.ChangePropertySettings",
		FormParameters, ThisObject);
	
EndProcedure

&AtClient
Procedure WriteObject(QuestionTextVariant, ContinuationProcedureName, AdditionalParameters = Undefined, WriteParameters = Undefined)
	
	If WriteParameters = Undefined Then
		WriteParameters = New Structure;
	EndIf;
	
	If QuestionTextVariant = "DeletionMarkEdit" Then
		If Modified Then
			QuestionText = NStr("ru = 'Для %1 пометки удаления необходимо записать внесенные изменения. Записать данные?'; en = 'To set a deletion mark %1, write made changes. Write data?'; pl = 'Dla %1 zaznaczenia do usunięcia należy zapisać wprowadzone zmiany. Zapisać dane?';de = 'Für die %1 Löschmarkierung müssen die vorgenommenen Änderungen protokolliert werden. Die Daten aufschreiben?';ro = 'Pentru %1 marcajul la ștergere trebuie înregistrate modificările introduse. Înregistrați datele?';tr = 'Silinmeyi %1işaretlemek için yapılan değişiklikler kaydedilmelidir.  Veri kaydedilsin mi?'; es_ES = 'Para %1 marca de borrar es necesario guardar los cambios introducidos. ¿Guardar los datos?'");
			If Object.DeletionMark Then
				Action = NStr("ru = 'снятия'; en = 'Clear'; pl = 'Wyczyść';de = 'Löschen';ro = 'Ștergere';tr = 'Temiz'; es_ES = 'Eliminar'");
			Else
				Action = NStr("ru = 'установки'; en = 'Set'; pl = 'ustawienia';de = 'Einstellungen';ro = 'instalarea';tr = 'kurulma'; es_ES = 'de instalar'");
			EndIf;
			QuestionText = StringFunctionsClientServer.SubstituteParametersToString(QuestionText, Action);
		Else
			QuestionText = NStr("ru = 'Пометить ""%1"" на удаление?'; en = 'Do you want to mark %1 for deletion?'; pl = 'Zaznaczyć ""%1"" do usunięcia?';de = 'Markieren Sie ""%1"" zum Löschen?';ro = 'Marcați ""%1"" la ștergere?';tr = '""%1"" silinmek üzere işaretlensin mi?'; es_ES = '¿Marcar ""%1"" para borrar?'");
			QuestionText = StringFunctionsClientServer.SubstituteParametersToString(QuestionText, Object.Description);
		EndIf;
		
		ShowQueryBox(
			New NotifyDescription(
				ContinuationProcedureName, ThisObject, WriteParameters),
			QuestionText, QuestionDialogMode.YesNo, , DialogReturnCode.Yes);
		Return;
	EndIf;
	
	If ValueIsFilled(Object.Ref) AND NOT Modified Then
		
		ExecuteNotifyProcessing(New NotifyDescription(
			ContinuationProcedureName, ThisObject, AdditionalParameters), False);
		Return;
	EndIf;
	
	ContinuationHandler = New Structure;
	ContinuationHandler.Insert("ProcedureName", ContinuationProcedureName);
	ContinuationHandler.Insert("Parameters", AdditionalParameters);
	
	WriteParameters.Insert("ContinuationHandler", ContinuationHandler);
	
	If ValueIsFilled(Object.Ref) Then
		WriteObjectContinuation("Write", WriteParameters);
		Return;
	EndIf;
	
	If QuestionTextVariant = "GoToValueList" Then
		QuestionText =
			NStr("ru = 'Переход к работе со списком значений
			           |возможен только после записи данных.
			           |
			           |Данные будут записаны.'; 
			           |en = 'You can start working with a value list
			           |only after writing data.
			           |
			           |The data will be written.'; 
			           |pl = 'Przejście do pracy z listą wartości
			           |jest możliwe tylko po zapisaniu danych.
			           |
			           |Dane zostaną zapisane.';
			           |de = 'Auf die Werteliste
			           | kann erst nach dem Schreiben der Daten zugegriffen werden
			           |
			           | Die Daten werden aufgezeichnet.';
			           |ro = 'Trecerea la lucrul cu lista de valori
			           |este posibilă numai după înregistrarea datelor.
			           |
			           |Datele vor fi înregistrate.';
			           |tr = 'Değer listesi çalışmalarına geçiş 
			           |sadece veri kaydından sonra yapılabilir. 
			           |
			           |Veri yazılacak.'; 
			           |es_ES = 'Transición para el trabajo de la lista de valores es
			           |posible solo después de haber grabado los datos.
			           |
			           |Datos se guardarán.'");
	Else
		QuestionText =
			NStr("ru = 'Данные будут записаны.'; en = 'Data will be written.'; pl = 'Dane zostaną zapisane.';de = 'Daten werden geschrieben.';ro = 'Datele vor fi scrise.';tr = 'Veriler yazılacaktır.'; es_ES = 'Datos se grabarán.'")
	EndIf;
	
	Buttons = New ValueList;
	Buttons.Add("Write", NStr("ru = 'Записать'; en = 'Write'; pl = 'Zapisz';de = 'Schreiben';ro = 'Scrieți';tr = 'Yaz'; es_ES = 'Escribir'"));
	Buttons.Add("Cancel", NStr("ru = 'Отмена'; en = 'Cancel'; pl = 'Anuluj';de = 'Abbrechen';ro = 'Revocare';tr = 'İptal'; es_ES = 'Cancelar'"));
	
	ShowQueryBox(
		New NotifyDescription(
			"WriteObjectContinuation", ThisObject, WriteParameters),
		QuestionText, Buttons, , "Write");
	
EndProcedure

&AtClient
Procedure SetClearDeletionMarkFollowUp(Response, WriteParameters) Export
	
	If Response = DialogReturnCode.Yes Then
		Object.DeletionMark = Not Object.DeletionMark;
	EndIf;
	WriteObjectContinuation(Response, WriteParameters);
	
EndProcedure


&AtClient
Procedure WriteObjectContinuation(Response, WriteParameters) Export
	
	If Response = "Write"
		Or Response = DialogReturnCode.Yes Then
		Write(WriteParameters);
	EndIf;
	
EndProcedure

&AtClient
Procedure AfterWriteError()
	
	If ContinuationHandlerOnWriteError <> Undefined Then
		ExecuteNotifyProcessing(
			New NotifyDescription(ContinuationHandlerOnWriteError.ProcedureName,
				ThisObject, ContinuationHandlerOnWriteError.Parameters),
			True);
	EndIf;
	
EndProcedure

&AtClient
Procedure EditValueFormatCompletion(Text, Context) Export
	
	If Text <> Undefined Then
		Object.FormatProperties = Text;
		SetFormatButtonTitle(ThisObject);
		
		WarningText = NStr("ru = 'Следующие настройки формата автоматически не применяются в большинстве мест:'; en = 'The following format settings are not applied automatically in many places:'; pl = 'Następujące ustawienia formatu nie są stosowane automatycznie w większości miejsc:';de = 'Die folgenden Formateinstellungen werden an den meisten Orten nicht automatisch angewendet:';ro = 'Următoarele setări ale formatului nu se aplică automat în majoritatea locurilor:';tr = 'Aşağıdaki biçim ayarları çoğu yerde otomatik olarak uygulanmaz:'; es_ES = 'Los ajustes siguientes del formato o se aplican automáticamente en lugares:'");
		Array = StrSplit(Text, ";", False);
		
		For each Substring In Array Do
			If StrFind(Substring, "DE=") > 0 OR StrFind(Substring, "DE=") > 0 Then
				WarningText = WarningText + Chars.LF
					+ " - " + NStr("ru = 'представление пустой даты'; en = 'blank date presentation'; pl = 'prezentacja pustej daty';de = 'ein leeres Datum präsentieren';ro = 'prezentarea datei goale';tr = 'boş tarih görüntüleme'; es_ES = 'presentación de la fecha vacía'");
				Continue;
			EndIf;
			If StrFind(Substring, "NZ=") > 0 OR StrFind(Substring, "NZ=") > 0 Then
				WarningText = WarningText + Chars.LF
					+ " - " + NStr("ru = 'представление пустого числа'; en = 'blank number presentation'; pl = 'prezentacja pustej liczby';de = 'eine leere Nummer präsentieren';ro = 'prezentarea numărului gol';tr = 'boş gün görüntüleme'; es_ES = 'presentación del número vacío'");
				Continue;
			EndIf;
			If StrFind(Substring, "DF=") > 0 OR StrFind(Substring, "DF=") > 0 Then
				If StrFind(Substring, "ddd") > 0 OR StrFind(Substring, "ddd") > 0 Then
					WarningText = WarningText + Chars.LF
						+ " - " + NStr("ru = 'кратное название дня недели'; en = 'short weekday name'; pl = 'krotna nazwa dnia tygodnia';de = 'mehrfacher Name des Wochentags';ro = 'denumirea scurtă a zilei săptămânii';tr = 'hafta gününün kısa adı'; es_ES = 'nombre corto del día de semana'");
				EndIf;
				If StrFind(Substring, "dddd") > 0 OR StrFind(Substring, "dddd") > 0 Then
					WarningText = WarningText + Chars.LF
						+ " - " + NStr("ru = 'полное название дня недели'; en = 'full weekday name'; pl = 'pełna nazwa dni tygodnia';de = 'vollständiger Name des Wochentags';ro = 'denumirea deplină a zilei săptămânii';tr = 'hafta gününün tam adı'; es_ES = 'nombre completo del día de semana'");
				EndIf;
				If StrFind(Substring, "MMM") > 0 OR StrFind(Substring, "MMM") > 0 Then
					WarningText = WarningText + Chars.LF
						+ " - " + NStr("ru = 'кратное название месяца'; en = 'short month name'; pl = 'krotna nazwa miesiąca';de = 'mehrfacher Name des Monats';ro = 'denumirea scurtă a lunii';tr = 'ayın kısa adı'; es_ES = 'nombre corto del mes'");
				EndIf;
				If StrFind(Substring, "MMMM") > 0 OR StrFind(Substring, "MMMM") > 0 Then
					WarningText = WarningText + Chars.LF
						+ " - " + NStr("ru = 'полное название месяца'; en = 'full month name'; pl = 'pełna nazwa miesiąca';de = 'vollständiger Monatsname';ro = 'denumirea deplină a lunii';tr = 'ayın tam adı'; es_ES = 'nombre completo del mes'");
				EndIf;
			EndIf;
			If StrFind(Substring, "DLF=") > 0 OR StrFind(Substring, "DLF=") > 0 Then
				If StrFind(Substring, "DD") > 0 OR StrFind(Substring, "DD") > 0 Then
					WarningText = WarningText + Chars.LF
						+ " - " + NStr("ru = 'длинная дата (месяц прописью)'; en = 'long date (month in writing)'; pl = 'długa data (miesiąc słownie)';de = 'langes Datum (Monat in Worten)';ro = 'data lungă (luna cu litere)';tr = 'uzun tarih (ay yazı ile)'; es_ES = 'fecha larga (mes en letras)'");
				EndIf;
			EndIf;
		EndDo;
		
		If StrLineCount(WarningText) > 1 Then
			ShowMessageBox(, WarningText);
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure SetWizardSettings(CurrentPage = Undefined)
	
	If CurrentPage = Undefined Then
		CurrentPage = Items.WIzardCardPages.CurrentPage;
	EndIf;
	
	ListHeaderTemplate        = NStr("ru = 'Выберите %1 для включения в набор ""%2""'; en = 'Select %1 to include it in the ""%2"" set'; pl = 'Wybierz %1 aby włączyć do zestawu ""%2""';de = 'Wählen Sie %1, um in das ""%2"" Set aufgenommen zu werden';ro = 'Selectați %1 pentru includere în setul ""%2"":';tr = '""%1"" kümesine ilave etmek için %2 seç'; es_ES = 'Seleccione %1 para activar en el conjunto ""%2""'");
	RadioButtonHeaderTemplate = NStr("ru = 'Выберите вариант добавления дополнительного %1 ""%2"" в набор ""%3""'; en = 'Select an option of adding additional %1 %2 to the ""%3"" set'; pl = 'Wybierz wariant dodawania dodatkowego %1 ""%2"" do zestawu ""%3""';de = 'Wählen Sie die Option aus, um dem Set ""%3"" ein zusätzliches %1 ""%2"" hinzuzufügen';ro = 'Selectați o opțiune de adăugare suplimentară %1 %2 la ""%3"" set';tr = '""%1"" kümeye ek %2 ""%3"" ilave etme opsiyonunu seç'; es_ES = 'Seleccione la variante de añadir el adicional %1 ""%2"" en el conjunto ""%3""'");
	
	If CurrentPage = Items.SelectAttribute Then
		
		If PassedFormParameters.IsAdditionalInfo Then
			Title = NStr("ru = 'Добавление дополнительного сведения'; en = 'Add additional information'; pl = 'Dodawanie informacji dodatkowej';de = 'Hinzufügen weiterer Informationen';ro = 'Adăugarea datelor suplimentare';tr = 'Ek bilgi ilavesi'; es_ES = 'Añadir la información adicional'");
		Else
			Title = NStr("ru = 'Добавление дополнительного реквизита'; en = 'Add additional attribute'; pl = 'Dodawanie atrybutu dodatkowego';de = 'Hinzufügen weiterer Attribute';ro = 'Adăugarea atributului suplimentar';tr = 'Ek özellik ilavesi'; es_ES = 'Añadir el requisito adicional'");
		EndIf;
		
		Items.CommandBarLeft.Enabled = False;
		Items.NextCommand.Title = NStr("ru = 'Далее >'; en = 'Next >'; pl = 'Dalej >';de = 'Weiter >';ro = 'Următorul >';tr = 'Sonraki >'; es_ES = 'Siguiente >'");
		
		Items.HeaderDecoration.Title = StringFunctionsClientServer.SubstituteParametersToString(
			ListHeaderTemplate,
			?(PassedFormParameters.IsAdditionalInfo, NStr("ru = 'дополнительное сведение'; en = 'additional information'; pl = 'dodatkowa informacja';de = 'zusätzliche informationen';ro = 'informații suplimentare';tr = 'ek bilgi'; es_ES = 'información adicional'"), NStr("ru = 'дополнительный реквизит'; en = 'additional attribute'; pl = 'atrybut dodatkowy';de = 'zusätzliche Attribute';ro = 'atribut suplimentar';tr = 'ek özellik'; es_ES = '(atributo adicional)'")),
			String(PassedFormParameters.CurrentPropertiesSet));
		
	ElsIf CurrentPage = Items.ActionChoice Then
		
		If PassedFormParameters.CopyWithQuestion Then
			Items.CommandBarLeft.Enabled = False;
			AdditionalValuesOwner = PassedFormParameters.AdditionalValuesOwner;
		Else
			Items.CommandBarLeft.Enabled = True;
			SelectedItem = Items.Properties.CurrentData;
			If SelectedItem = Undefined Then
				AdditionalValuesOwner = PassedFormParameters.AdditionalValuesOwner;
			Else
				AdditionalValuesOwner = Items.Properties.CurrentData.Property;
			EndIf;
		EndIf;
		Items.NextCommand.Title = NStr("ru = 'Далее >'; en = 'Next >'; pl = 'Dalej >';de = 'Weiter >';ro = 'Următorul >';tr = 'Sonraki >'; es_ES = 'Siguiente >'");
		
		Items.AttributeAddMode.Title = StringFunctionsClientServer.SubstituteParametersToString(
			RadioButtonHeaderTemplate,
			?(PassedFormParameters.IsAdditionalInfo, NStr("ru = 'сведения'; en = 'info'; pl = 'szczegóły';de = 'details';ro = 'informație';tr = 'bilginin'; es_ES = 'información'"), NStr("ru = 'реквизита'; en = 'attribute'; pl = 'atrybut';de = 'attribut';ro = 'atribute';tr = 'özellik'; es_ES = 'atributo'")),
			String(AdditionalValuesOwner),
			String(PassedFormParameters.CurrentPropertiesSet));
		
		If PassedFormParameters.IsAdditionalInfo Then
			Title = NStr("ru = 'Добавление дополнительного сведения'; en = 'Add additional information'; pl = 'Dodawanie informacji dodatkowej';de = 'Hinzufügen weiterer Informationen';ro = 'Adăugarea datelor suplimentare';tr = 'Ek bilgi ilavesi'; es_ES = 'Añadir la información adicional'");
		Else
			Title = NStr("ru = 'Добавление дополнительного реквизита'; en = 'Add additional attribute'; pl = 'Dodawanie atrybutu dodatkowego';de = 'Hinzufügen weiterer Attribute';ro = 'Adăugarea atributului suplimentar';tr = 'Ek özellik ilavesi'; es_ES = 'Añadir el requisito adicional'");
		EndIf;
		
	Else
		Items.NextCommand.Title = NStr("ru = 'Готово'; en = 'Finish'; pl = 'Data zakończenia';de = 'Abschluss';ro = 'Sfârșit';tr = 'Bitiş'; es_ES = 'Finalizar'");
		Items.CommandBarLeft.Enabled = True;
	EndIf;
	
EndProcedure

&AtServer
Procedure RefreshFormItemsContent(WarningText = "")
	
	If WizardMode Then
		CommandBarLocation = FormCommandBarLabelLocation.None;
		Items.NextCommand.DefaultButton    = True;
	Else
		Items.WizardCommandBar.Visible = False;
		Items.WIzardCardPages.CurrentPage = Items.AttributeCard;
	EndIf;
	
	SetFormHeader();
	
	If NOT Object.ValueType.ContainsType(Type("Number"))
	   AND NOT Object.ValueType.ContainsType(Type("Date"))
	   AND NOT Object.ValueType.ContainsType(Type("Boolean")) Then
		
		Object.FormatProperties = "";
	EndIf;
	
	SetFormatButtonTitle(ThisObject);
	
	If Object.IsAdditionalInfo
	 OR NOT (    Object.ValueType.ContainsType(Type("Number" ))
	         OR Object.ValueType.ContainsType(Type("Date"  ))
	         OR Object.ValueType.ContainsType(Type("Boolean")) )Then
		
		Items.EditValueFormat.Visible = False;
	Else
		Items.EditValueFormat.Visible = True;
	EndIf;
	
	If NOT Object.IsAdditionalInfo Then
		Items.MultilineGroup.Visible = True;
		SwitchAttributeDisplaySettings(Object.ValueType);
	Else
		Items.MultilineGroup.Visible = False;
	EndIf;
	
	If ValueIsFilled(Object.Ref) Then
		OldValueType = Common.ObjectAttributeValue(Object.Ref, "ValueType");
		VisibilityAvailabilityCanBeCustomized = ValueIsFilled(Object.PropertiesSet);
	Else
		OldValueType = New TypeDescription;
		VisibilityAvailabilityCanBeCustomized = ValueIsFilled(CurrentPropertiesSet);
	EndIf;
	
	If Object.IsAdditionalInfo Then
		Object.RequiredToFill = False;
		Items.PropertiesAndDependenciesGroup.Visible = False;
	Else
		AttributeBoolean = (Object.ValueType = New TypeDescription("Boolean"));
		Items.RequiredToFill.Visible    = Not AttributeBoolean;
		Items.ChooseItemRequiredOption.Visible = Not AttributeBoolean;
		Items.PropertiesAndDependenciesGroup.Visible = True;
		
		If VisibilityAvailabilityCanBeCustomized Then
			Items.ChooseItemRequiredOption.Enabled  = Object.RequiredToFill;
			Items.ChooseAvailabilityOption.Enabled = True;
			Items.ChooseVisibilityOption.Enabled   = True;
		Else
			Items.ChooseVisibilityOption.Visible   = False;
			Items.ChooseAvailabilityOption.Visible = False;
			Items.ChooseItemRequiredOption.Visible  = False;
			
			Items.Visible.Visible    = False;
			Items.Available.Visible = False;
			Items.RequiredToFill.Title = NStr("ru = 'Заполнять обязательно'; en = 'Required'; pl = 'Wypełniaj obowiązkowo';de = 'Ausfüllen ist obligatorisch';ro = 'Completare obligatorie';tr = 'Doldurulması zorunlu'; es_ES = 'Rellenar obligatoriamente'");
		EndIf;
		SetHyperlinkTitles();
	EndIf;
	
	If ValueIsFilled(Object.AdditionalValuesOwner) Then
		
		OwnerProperties = Common.ObjectAttributesValues(
			Object.AdditionalValuesOwner, "ValueType, AdditionalValuesWithWeight");
		
		If OwnerProperties.ValueType.ContainsType(Type("CatalogRef.ObjectPropertyValueHierarchy")) Then
			Object.ValueType = New TypeDescription(
				Object.ValueType,
				"CatalogRef.ObjectPropertyValueHierarchy",
				"CatalogRef.ObjectsPropertiesValues");
		Else
			Object.ValueType = New TypeDescription(
				Object.ValueType,
				"CatalogRef.ObjectsPropertiesValues",
				"CatalogRef.ObjectPropertyValueHierarchy");
		EndIf;
		
		ValuesOwner = Object.AdditionalValuesOwner;
		ValuesWithWeight   = OwnerProperties.AdditionalValuesWithWeight;
	Else
		// Checking possibility to delete an additional value type.
		If PropertyManagerInternal.ValueTypeContainsPropertyValues(OldValueType) Then
			Query = New Query;
			Query.SetParameter("Owner", Object.Ref);
			
			If OldValueType.ContainsType(Type("CatalogRef.ObjectPropertyValueHierarchy")) Then
				Query.Text =
				"SELECT TOP 1
				|	TRUE AS TrueValue
				|FROM
				|	Catalog.ObjectPropertyValueHierarchy AS ObjectPropertyValueHierarchy
				|WHERE
				|	ObjectPropertyValueHierarchy.Owner = &Owner";
			Else
				Query.Text =
				"SELECT TOP 1
				|	TRUE AS TrueValue
				|FROM
				|	Catalog.ObjectsPropertiesValues AS ObjectsPropertiesValues
				|WHERE
				|	ObjectsPropertiesValues.Owner = &Owner";
			EndIf;
			
			If NOT Query.Execute().IsEmpty() Then
				
				If OldValueType.ContainsType(Type("CatalogRef.ObjectPropertyValueHierarchy"))
				   AND NOT Object.ValueType.ContainsType(Type("CatalogRef.ObjectPropertyValueHierarchy")) Then
					
					WarningText = StringFunctionsClientServer.SubstituteParametersToString(
						NStr("ru = 'Недопустимо удалять тип ""%1"",
						           |так как дополнительные значения уже введены.
						           |Сначала нужно удалить введенные дополнительные значения.
						           |
						           |Удаленный тип восстановлен.'; 
						           |en = 'Cannot delete the %1 type
						           |as additional values are entered already.
						           |Delete additional values you entered first.
						           |
						           |Deleted type is restored.'; 
						           |pl = 'Usuwanie typu ""%1"" jest niedozwolone,
						           |ponieważ dodatkowe wartości zostały już wprowadzone.
						           |Najpierw należy usunąć wprowadzone wartości dodatkowe.
						           |
						           |Usunięty typ został odzyskany.';
						           |de = 'Löschen Sie den Typ ""%1"" nicht,
						           |da bereits zusätzliche Werte eingegeben wurden. 
						           |Zunächst müssen die eingegebenen zusätzlichen Werte gelöscht werden.
						           |
						           |Der gelöschte Typ wird wiederhergestellt.';
						           |ro = 'Nu se permite ștergerea tipului ""%1"",
						           | deoarece valorile suplimentare deja sunt introduse.
						           | Ma întâi trebuie să ștergeți valorile suplimentare introduse.
						           |
						           |Tipul șters este restabilit.';
						           |tr = '"
" türün ek değerleri bulunduğundan "" %1 "" türünü silemezsiniz. 
						           | Türü silmeden önce tüm ek değerleri silin.
						           |
						           |Silinen tür geri yüklendi.'; 
						           |es_ES = 'No se puede borrar el tipo ""%1"",
						           |porque los valores adicionales de este tipo no se han encontrado.
						           |Borrar todos los valores adicionales antes de borrar el tipo.
						           |
						           |Tipo eliminado restablecido.'"),
						String(Type("CatalogRef.ObjectPropertyValueHierarchy")) );
					
					Object.ValueType = New TypeDescription(
						Object.ValueType,
						"CatalogRef.ObjectPropertyValueHierarchy",
						"CatalogRef.ObjectsPropertiesValues");
				
				ElsIf OldValueType.ContainsType(Type("CatalogRef.ObjectsPropertiesValues"))
				        AND NOT Object.ValueType.ContainsType(Type("CatalogRef.ObjectsPropertiesValues")) Then
					
					WarningText = StringFunctionsClientServer.SubstituteParametersToString(
						NStr("ru = 'Недопустимо удалять тип ""%1"",
						           |так как дополнительные значения уже введены.
						           |Сначала нужно удалить введенные дополнительные значения.
						           |
						           |Удаленный тип восстановлен.'; 
						           |en = 'Cannot delete the %1 type
						           |as additional values are entered already.
						           |Delete additional values you entered first.
						           |
						           |Deleted type is restored.'; 
						           |pl = 'Usuwanie typu ""%1"" jest niedozwolone,
						           |ponieważ dodatkowe wartości zostały już wprowadzone.
						           |Najpierw należy usunąć wprowadzone wartości dodatkowe.
						           |
						           |Usunięty typ został odzyskany.';
						           |de = 'Löschen Sie den Typ ""%1"" nicht,
						           |da bereits zusätzliche Werte eingegeben wurden. 
						           |Zunächst müssen die eingegebenen zusätzlichen Werte gelöscht werden.
						           |
						           |Der gelöschte Typ wird wiederhergestellt.';
						           |ro = 'Nu se permite ștergerea tipului ""%1"",
						           | deoarece valorile suplimentare deja sunt introduse.
						           | Ma întâi trebuie să ștergeți valorile suplimentare introduse.
						           |
						           |Tipul șters este restabilit.';
						           |tr = '"
" türün ek değerleri bulunduğundan "" %1 "" türünü silemezsiniz. 
						           | Türü silmeden önce tüm ek değerleri silin.
						           |
						           |Silinen tür geri yüklendi.'; 
						           |es_ES = 'No se puede borrar el tipo ""%1"",
						           |porque los valores adicionales de este tipo no se han encontrado.
						           |Borrar todos los valores adicionales antes de borrar el tipo.
						           |
						           |Tipo eliminado restablecido.'"),
						String(Type("CatalogRef.ObjectsPropertiesValues")) );
					
					Object.ValueType = New TypeDescription(
						Object.ValueType,
						"CatalogRef.ObjectsPropertiesValues",
						"CatalogRef.ObjectPropertyValueHierarchy");
				EndIf;
			EndIf;
		EndIf;
		
		// Checking that not more than one additional value type is set.
		If Object.ValueType.ContainsType(Type("CatalogRef.ObjectPropertyValueHierarchy"))
		   AND Object.ValueType.ContainsType(Type("CatalogRef.ObjectsPropertiesValues")) Then
			
			If NOT OldValueType.ContainsType(Type("CatalogRef.ObjectPropertyValueHierarchy")) Then
				
				WarningText = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("ru = 'Недопустимо одновременно использовать типы значения
					           |""%1"" и
					           |""%2"".
					           |
					           |Второй тип удален.'; 
					           |en = 'Cannot use the
					           |""%1"" and
					           |""%2"" value types at the same time.
					           |
					           |The second type is deleted.'; 
					           |pl = 'Jednoczesne wykorzystywanie typów wartości
					           |""%1"" i
					           |""%2"" jest niedozwolone.
					           |
					           |Drugi typ został usunięty.';
					           |de = 'Verwenden Sie nicht gleichzeitig die Werttypen
					           |""%1"" und
					           |""%2"". 
					           |
					           |Der zweite Typ wird gelöscht. ';
					           |ro = 'Nu se permite utilizarea concomitentă a tipurilor de valorii
					           |""%1"" și
					           |""%2"".
					           |
					           |Al doilea tip este șters.';
					           |tr = 'Aynı zamanda 
					           |""%1"" ve
					           |""%2"".
					           |
					           | değerin tipleri kullanılamaz. İkinci tip silindi.'; 
					           |es_ES = 'No se admite usar simultáneamente los tipos del valor
					           |""%1"" y
					           |""%2"".
					           |
					           |El segundo tipo se ha eliminado.'"),
					String(Type("CatalogRef.ObjectsPropertiesValues")),
					String(Type("CatalogRef.ObjectPropertyValueHierarchy")) );
				
				// Deletion of the second type.
				Object.ValueType = New TypeDescription(
					Object.ValueType,
					,
					"CatalogRef.ObjectPropertyValueHierarchy");
			Else
				WarningText = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("ru = 'Недопустимо одновременно использовать типы значения
					           |""%1"" и
					           |""%2"".
					           |
					           |Первый тип удален.'; 
					           |en = 'Cannot use the
					           |""%1"" and
					           |""%2"" value types at the same time.
					           |
					           |The first type is deleted.'; 
					           |pl = 'Jednoczesne wykorzystywanie typów wartości
					           |""%1"" i
					           |""%2"" jest niedozwolone.
					           |
					           |Pierwszy typ został usunięty.';
					           |de = 'Verwenden Sie nicht gleichzeitig die Werttypen
					           |""%1"" und
					           |""%2"". 
					           |
					           |Der erste Typ wird gelöscht. ';
					           |ro = 'Nu se permite utilizarea concomitentă a tipurilor de valorii
					           |""%1"" și
					           |""%2"".
					           |
					           |Primul tip este șters.';
					           |tr = 'Aynı zamanda 
					           |""%1"" ve
					           |""%2"".
					           |
					           | değerin tipleri kullanılamaz. Birinci tip silindi.'; 
					           |es_ES = 'No se admite usar simultáneamente los tipos del valor
					           |""%1"" y
					           |""%2"".
					           |
					           |El primer tipo se ha eliminado.'"),
					String(Type("CatalogRef.ObjectsPropertiesValues")),
					String(Type("CatalogRef.ObjectPropertyValueHierarchy")) );
				
				// Deletion of the first type.
				Object.ValueType = New TypeDescription(
					Object.ValueType,
					,
					"CatalogRef.ObjectsPropertiesValues");
			EndIf;
		EndIf;
		
		ValuesOwner = Object.Ref;
		ValuesWithWeight   = Object.AdditionalValuesWithWeight;
	EndIf;
	
	If PropertyManagerInternal.ValueTypeContainsPropertyValues(Object.ValueType) Then
		Items.ValueFormsHeadersGroup.Visible = True;
		Items.AdditionalValuesWithWeight.Visible = True;
		Items.ValuePage.Visible = True;
		Items.Pages.PagesRepresentation = FormPagesRepresentation.TabsOnTop;
	Else
		Items.ValueFormsHeadersGroup.Visible = False;
		Items.AdditionalValuesWithWeight.Visible = False;
		Items.ValuePage.Visible = False;
		Items.Pages.PagesRepresentation = FormPagesRepresentation.None;
	EndIf;
	
	Items.Values.Header        = ValuesWithWeight;
	Items.WeightFactorValues.Visible = ValuesWithWeight;
	
	CommonClientServer.SetDynamicListFilterItem(
		Values, "Owner", ValuesOwner, , , True);
	
	If Object.ValueType.ContainsType(Type("CatalogRef.ObjectsPropertiesValues")) Then
		ListProperties = Common.DynamicListPropertiesStructure();
		ListProperties.QueryText =
			"SELECT
			|	Values.Ref,
			|	Values.DataVersion,
			|	Values.DeletionMark,
			|	Values.Predefined,
			|	Values.Owner,
			|	Values.Parent,
			|	CASE
			|		WHEN &IsMainLanguage
			|		THEN Values.Description
			|		ELSE CAST(ISNULL(PresentationValues.Description, Values.Description) AS STRING(150))
			|	END AS Description,
			|	Values.Weight
			|FROM
			|	Catalog.ObjectsPropertiesValues AS Values
			|	LEFT JOIN Catalog.ObjectsPropertiesValues.Presentations AS PresentationValues
			|		ON (PresentationValues.Ref = Values.Ref)
			|		AND PresentationValues.LanguageCode = &LanguageCode";
		ListProperties.MainTable = "Catalog.ObjectsPropertiesValues";
		Common.SetDynamicListProperties(Items.Values,
			ListProperties);
	Else
		ListProperties = Common.DynamicListPropertiesStructure();
		ListProperties.QueryText =
			"SELECT
			|	Values.Ref,
			|	Values.DataVersion,
			|	Values.DeletionMark,
			|	Values.Predefined,
			|	Values.Owner,
			|	Values.Parent,
			|	CASE
			|		WHEN &IsMainLanguage
			|		THEN Values.Description
			|		ELSE CAST(ISNULL(PresentationValues.Description, Values.Description) AS STRING(150))
			|	END AS Description,
			|	Values.Weight
			|FROM
			|	Catalog.ObjectPropertyValueHierarchy AS Values
			|	LEFT JOIN Catalog.ObjectPropertyValueHierarchy.Presentations AS PresentationValues
			|		ON (PresentationValues.Ref = Values.Ref)
			|		AND PresentationValues.LanguageCode = &LanguageCode";
		ListProperties.MainTable = "Catalog.ObjectPropertyValueHierarchy";
		Common.SetDynamicListProperties(Items.Values,
			ListProperties);
	EndIf;
	
	CommonClientServer.SetDynamicListParameter(
		Values, "IsMainLanguage", CurrentLanguage() = Metadata.DefaultLanguage, True);
	CommonClientServer.SetDynamicListParameter(
		Values, "LanguageCode", CurrentLanguage().LanguageCode, True);
	
	// Displaying adjustments.
	
	If NOT ValueIsFilled(Object.AdditionalValuesOwner) Then
		Items.ValueListAdjustment.Visible = False;
		Items.AdditionalValues.ReadOnly = False;
		Items.ValuesEditingCommandBar.Visible = True;
		Items.ValuesEditingContextMenu.Visible = True;
		Items.AdditionalValuesWithWeight.Visible = True;
	Else
		Items.ValueListAdjustment.Visible = True;
		Items.AdditionalValues.ReadOnly = True;
		Items.ValuesEditingCommandBar.Visible = False;
		Items.ValuesEditingContextMenu.Visible = False;
		Items.AdditionalValuesWithWeight.Visible = False;
		
		Items.ValueListAdjustmentComment.Hyperlink = ValueIsFilled(Object.Ref);
		Items.ValueListAdjustmentChange.Enabled    = ValueIsFilled(Object.Ref);
		
		OwnerProperties = Common.ObjectAttributesValues(
			Object.AdditionalValuesOwner, "PropertiesSet, Title, IsAdditionalInfo");
		
		If OwnerProperties.IsAdditionalInfo <> True Then
			AdjustmentTemplate = NStr("ru = 'Список значений общий с реквизитом ""%1""'; en = 'Value list shared with attribute %1'; pl = 'Lista wartości wspólna z atrybutem ""%1""';de = 'Die Werteliste ist allgemein mit den Attributen ""%1"".';ro = 'Lista valorilor comună cu atributul ""%1""';tr = '""%1"" alana sahip ortak değer listesi'; es_ES = 'Lista común de valores con el atributo ""%1""              '");
		Else
			AdjustmentTemplate = NStr("ru = 'Список значений общий со сведением ""%1""'; en = 'Value list shared with information record %1'; pl = 'Lista wartości wspólna z informacją ""%1""';de = 'Die Werteliste ist allgemein mit den Informationen ""%1"".';ro = 'Lista valorilor comună cu datele ""%1""';tr = '""%1"" bilgiye sahip ortak değer listesi'; es_ES = 'Lista común de valores con los datos ""%1""'");
		EndIf;
		
		If ValueIsFilled(OwnerProperties.PropertiesSet) Then
			AdjustmentTemplateSet = " " + NStr("ru = 'набора ""%1""'; en = 'of the ""%1"" set'; pl = 'zestawu ""%1""';de = 'Set ""%1""';ro = 'setul ""%1""';tr = '""%1"" kümesinin'; es_ES = 'del conjunto ""%1""'");
			AdjustmentTemplateSet = StringFunctionsClientServer.SubstituteParametersToString(AdjustmentTemplateSet, String(OwnerProperties.PropertiesSet));
		Else
			AdjustmentTemplateSet = "";
		EndIf;
		
		Items.ValueListAdjustmentComment.Title =
			StringFunctionsClientServer.SubstituteParametersToString(AdjustmentTemplate, OwnerProperties.Title)
			+ AdjustmentTemplateSet + "  ";
	EndIf;
	
	RefreshSetsList();
	
	If NOT ShowSetAdjustment
	   AND ValueIsFilled(Object.PropertiesSet)
	   AND SetsList.Count() < 2 Then
		
		Items.SetsAdjustment.Visible = False;
	Else
		Items.SetsAdjustment.Visible = True;
		Items.SetsAdjustmentComment.Hyperlink = True;
		
		Items.SetsAdjustmentChange.Enabled = ValueIsFilled(Object.Ref);
		
		If ValueIsFilled(Object.PropertiesSet)
		   AND SetsList.Count() < 2 Then
			
			Items.SetsAdjustmentChange.Visible = False;
		
		ElsIf ValueIsFilled(CurrentPropertiesSet) Then
			Items.SetsAdjustmentChange.Visible = True;
		Else
			Items.SetsAdjustmentChange.Visible = False;
		EndIf;
		
		If SetsList.Count() > 0 Then
		
			If ValueIsFilled(Object.PropertiesSet)
			   AND SetsList.Count() < 2 Then
				
				If Object.IsAdditionalInfo Then
					AdjustmentTemplate = NStr("ru = 'Сведение входит в набор: %1'; en = 'The information is included in set: %1'; pl = 'Dane są zawarte w zestawie: %1';de = 'Daten sind im Satz enthalten: %1';ro = 'Datele fac parte din setul: %1';tr = 'Verinin dahil olduğu küme: %1'; es_ES = 'Datos está incluido en el conjunto: %1'");
				Else
					AdjustmentTemplate = NStr("ru = 'Реквизит входит в набор: %1'; en = 'The attribute is included in set: %1'; pl = 'Atrybut należy do zestawu: %1';de = 'Das Attribut gehört zu dem Satz: %1';ro = 'Atributul face parte din setul: %1';tr = 'Özelliğin ait olduğu küme: %1'; es_ES = 'El atributo pertenece al conjunto: %1'");
				EndIf;
				CommentText = StringFunctionsClientServer.SubstituteParametersToString(AdjustmentTemplate, TrimAll(SetsList[0].Presentation));
			Else
				If SetsList.Count() > 1 Then
					If Object.IsAdditionalInfo Then
						AdjustmentTemplate = NStr("ru = 'Общее сведение входит в %1 %2'; en = 'The shared information record belongs to %1 %2'; pl = 'Informacje ogólne są zawarte w %1 %2';de = 'Gemeinsame Informationen sind enthalten in  %1 %2';ro = 'Datele comune fac parte din %1 %2';tr = 'Ortak bilgiler %1 %2''e dahil edildi'; es_ES = 'Información común está incluida en %1 %2'");
					Else
						AdjustmentTemplate = NStr("ru = 'Общий реквизит входит в %1 %2'; en = 'The shared attribute belongs to %1 %2'; pl = 'Wspólny atrybut zawarty jest w %1 %2';de = 'Das gemeinsame Attribut ist enthalten in %1 %2';ro = 'Atributul comun face parte din %1 %2';tr = 'Ortak özellik %1 %2''e dahil edildi'; es_ES = 'Atributo común está incluido en %1 %2'");
					EndIf;
					
					StringSets = UsersInternalClientServer.IntegerSubject(SetsList.Count(),
						"", NStr("ru = 'набор,набора,наборов,,,,,,0'; en = 'set, sets, sets,,,,,,0'; pl = 'zestaw,zestawu,zestawów,,,,,,0';de = 'Set,des Set,Sets,,,,,0';ro = 'set,seturi,seturi,,,,,,0';tr = 'küme, kümeler, kümeler,,,,,,0'; es_ES = 'conjunto,del conjunto, de los conjuntos,,,,,,0'"));
					
					CommentText = StringFunctionsClientServer.SubstituteParametersToString(AdjustmentTemplate, Format(SetsList.Count(), "NG="), StringSets);
				Else
					If Object.IsAdditionalInfo Then
						AdjustmentTemplate = NStr("ru = 'Общее сведение входит в набор: %1'; en = 'The shared information record belongs to set %1'; pl = 'Wspólne informacje są zawarte w zestawie: %1';de = 'Allgemeine Informationen sind im Satz enthalten: %1';ro = 'Datele comune fac parte din setul: %1';tr = 'Ortak bilgilerin dahil edildiği küme: %1'; es_ES = 'Información común está incluida en el conjunto: %1'");
					Else
						AdjustmentTemplate = NStr("ru = 'Общий реквизит входит в набор: %1'; en = 'The shared attribute belongs to set %1'; pl = 'Wspólny atrybut jest zawarty w zestawie: %1';de = 'Gemeinsames Attribut ist im Satz enthalten: %1';ro = 'Atributul comun face din setul: %1';tr = 'Ortak özelliğin dahil olduğu küme: %1'; es_ES = 'Atributo común está incluido en el conjunto: %1'");
					EndIf;
					
					CommentText = StringFunctionsClientServer.SubstituteParametersToString(AdjustmentTemplate, TrimAll(SetsList[0].Presentation));
				EndIf;
			EndIf;
		Else
			Items.SetsAdjustmentComment.Hyperlink = False;
			Items.SetsAdjustmentChange.Visible = False;
			
			If ValueIsFilled(Object.PropertiesSet) Then
				If Object.IsAdditionalInfo Then
					CommentText = NStr("ru = 'Сведение не входит в набор'; en = 'The information is not included in the set'; pl = 'Dane nie są zawarte w zestawie';de = 'Daten sind nicht im Set enthalten';ro = 'Datele nu fac parte din set';tr = 'Veri kümeye dahil edilmedi'; es_ES = 'Datos no están incluido en el conjunto'");
				Else
					CommentText = NStr("ru = 'Реквизит не входит в набор'; en = 'The attribute is not used in the set'; pl = 'Atrybut nie należy do zestawu';de = 'Das Attribut gehört nicht zum Satz';ro = 'Atributul comun nu face parte din set';tr = 'Özellik kümeye dahil edilmedi'; es_ES = 'El atributo no pertenece al conjunto'");
				EndIf;
			Else
				If Object.IsAdditionalInfo Then
					CommentText = NStr("ru = 'Общее сведение не входит в наборы'; en = 'The shared information record does not belong to any set'; pl = 'Wspólne informacje nie są zawarte w zestawach';de = 'Allgemeine Informationen sind nicht in Sätzen enthalten';ro = 'Datele comune nu fac parte din seturi';tr = 'Ortak bilgi kümelere dahil edilmedi'; es_ES = 'Información común no está incluida en los conjuntos'");
				Else
					CommentText = NStr("ru = 'Общий реквизит не входит в наборы'; en = 'The shared attribute does not belong to any set'; pl = 'Wspólny atrybut nie wchodzi w skład zestawów';de = 'Allgemeine Attribute sind nicht in den Sets enthalten';ro = 'Atributul comun nu face parte din seturi';tr = 'Ortak özellik kümeye dahil edilmedi'; es_ES = 'El requisito común no se incluye en los conjuntos'");
				EndIf;
			EndIf;
		EndIf;
		
		Items.SetsAdjustmentComment.Title = CommentText + " ";
		
		If Items.SetsAdjustmentComment.Hyperlink Then
			Items.SetsAdjustmentComment.ToolTip = NStr("ru = 'Переход к набору'; en = 'Go to set'; pl = 'Przejdź do zestawu';de = 'Gehe zum Satz';ro = 'Du-te la set';tr = 'Kümeye git'; es_ES = 'Ir al conjunto'");
		Else
			Items.SetsAdjustmentComment.ToolTip = "";
		EndIf;
	EndIf;
	
EndProcedure

&AtServer
Procedure SwitchAttributeDisplaySettings(ValueType)
	
	AllowMultilineFieldChoice = (Object.ValueType.Types().Count() = 1)
		AND (Object.ValueType.ContainsType(Type("String")));
	AllowDisplayAsHyperlink   = AllowMultilineFieldChoice
		Or (Not Object.ValueType.ContainsType(Type("String"))
			AND Not Object.ValueType.ContainsType(Type("Date"))
			AND Not Object.ValueType.ContainsType(Type("Boolean"))
			AND Not Object.ValueType.ContainsType(Type("Number")));
	
	Items.SingleLineKind.Visible                       = AllowMultilineFieldChoice;
	Items.MultilineInputFieldGroupSettings.Visible = AllowMultilineFieldChoice;
	Items.OutputAsHyperlink.Visible              = AllowDisplayAsHyperlink;
	
EndProcedure

&AtServer
Procedure ClearEnteredWeightCoefficients()
	
	If Object.ValueType.ContainsType(Type("CatalogRef.ObjectsPropertiesValues")) Then
		ValueTableName = "Catalog.ObjectsPropertiesValues";
	Else
		ValueTableName = "Catalog.ObjectPropertyValueHierarchy";
	EndIf;
	
	Lock = New DataLock;
	Lock.Add(ValueTableName);
	
	BeginTransaction();
	Try
		Lock.Lock();
		Query = New Query;
		Query.Text =
		"SELECT
		|	CurrentTable.Ref AS Ref
		|FROM
		|	Catalog.ObjectsPropertiesValues AS CurrentTable
		|WHERE
		|	CurrentTable.Weight <> 0";
		Query.Text = StrReplace(Query.Text , "Catalog.ObjectsPropertiesValues", ValueTableName);
		
		Selection = Query.Execute().Select();
		While Selection.Next() Do
			ValueObject = Selection.Ref.GetObject();
			ValueObject.Weight = 0;
			ValueObject.Write();
		EndDo;
		
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;
	
EndProcedure

&AtServer
Procedure RefreshSetsList()
	
	SetsList.Clear();
	
	If ValueIsFilled(Object.Ref) Then
		
		Query = New Query(
		"SELECT
		|	AdditionalAttributes.Ref AS Set,
		|	AdditionalAttributes.Ref.Description
		|FROM
		|	Catalog.AdditionalAttributesAndInfoSets.AdditionalAttributes AS AdditionalAttributes
		|WHERE
		|	AdditionalAttributes.Property = &Property
		|	AND NOT AdditionalAttributes.Ref.IsFolder
		|
		|UNION ALL
		|
		|SELECT
		|	AdditionalInfo.Ref,
		|	AdditionalInfo.Ref.Description
		|FROM
		|	Catalog.AdditionalAttributesAndInfoSets.AdditionalInfo AS AdditionalInfo
		|WHERE
		|	AdditionalInfo.Property = &Property
		|	AND NOT AdditionalInfo.Ref.IsFolder");
		
		Query.SetParameter("Property", Object.Ref);
		
		BeginTransaction();
		Try
			Selection = Query.Execute().Select();
			While Selection.Next() Do
				SetsList.Add(Selection.Set, Selection.Description + "         ");
			EndDo;
			
			CommitTransaction();
		Except
			RollbackTransaction();
			Raise;
		EndTry;
	EndIf;
	
EndProcedure

&AtClient
Procedure OnChangePage(Direction, MainPage, CurrentPage)
	
	MainPage.CurrentPage = CurrentPage;
	If CurrentPage = Items.ActionChoice Then
		If Direction = "Forward" Then
			SelectedItem = Items.Properties.CurrentData;
			PassedFormParameters.AdditionalValuesOwner = SelectedItem.Property;
			FillActionListOnAddAttribute();
		EndIf;
	ElsIf CurrentPage = Items.AttributeCard Then
		FillAttributeOrInfoCard();
	EndIf;
	
EndProcedure

&AtServer
Function IsCommonAdditionalAttribute(SelectedItem)
	AttributePropertiesSet = Common.ObjectAttributesValues(SelectedItem, "PropertiesSet");
	Return Not ValueIsFilled(AttributePropertiesSet.PropertiesSet);
EndFunction

&AtServer
Function AttributeWithAdditionalValuesList()
	
	AttributeWithAdditionalValuesList = True;
	OwnerProperties = Common.ObjectAttributesValues(
		PassedFormParameters.AdditionalValuesOwner, "ValueType");
	If Not OwnerProperties.ValueType.ContainsType(Type("CatalogRef.ObjectsPropertiesValues"))
		AND Not OwnerProperties.ValueType.ContainsType(Type("CatalogRef.ObjectPropertyValueHierarchy")) Then
		AttributeWithAdditionalValuesList = False;
	EndIf;
	
	Return AttributeWithAdditionalValuesList;
EndFunction

&AtServer
Procedure FillActionListOnAddAttribute()
	
	IsCommonAdditionalAttribute = IsCommonAdditionalAttribute(PassedFormParameters.AdditionalValuesOwner);
	UseCommonAdditionalValues = GetFunctionalOption("UseCommonAdditionalValues");
	UseAdditionalCommonAttributesAndInfo = GetFunctionalOption("UseAdditionalCommonAttributesAndInfo");
	
	AttributeWithAdditionalValuesList = AttributeWithAdditionalValuesList();
	
	If PassedFormParameters.IsAdditionalInfo Then
		AddCommon = NStr("ru = 'Добавить общее сведение в набор (рекомендуется)
			|
			|Выбранное сведение уже входит в несколько наборов, поэтому рекомендуется также включить его в этот набор ""как есть"".
			|В этом случае будет возможно отбирать по нему данные разных типов в списках и отчетах.'; 
			|en = 'Add shared information record to the set (recommended).
			|
			|The information record belongs to multiple sets. It is recommended that you include it in the set ""as is.""
			|This will allow you to filter data by this record in lists and reports.'; 
			|pl = 'Dodaj wspólną informację do zestawu (zalecane) 
			|
			|Wybrana informacja wchodzi już w skład kilku zestawów, dlatego jest zalecane włączenie do również do tego zestawu ""tak jak jest"".
			|W tym wypadku będzie możliwy wybór wg niej danych różnych typów w listach i sprawozdaniach.';
			|de = 'Hinzufügen einer allgemeinen Information zum Set (empfohlen)
			|
			|Die ausgewählte Information ist bereits in mehreren Sets enthalten, daher wird empfohlen, sie auch in diesem Set ""so wie sie ist"" aufzunehmen.
			|In diesem Fall wird es möglich sein, Daten unterschiedlicher Art in Listen und Berichten auszuwählen.';
			|ro = 'Adăugare datele comune în set (recomandat)
			|
			|Datele selectate deja fac parte din mai multe seturi, de aceea recomandăm la fel să le includeți în acest set ""cum sunt"".
			|În acest caz va fi posibil să selectați conform acesteia date de diferite tipuri în liste și rapoarte.';
			|tr = 'Bir kümeye ortak bilgi ekle (önerilen) 
			|
			|Seçilen ayrıntı zaten birkaç kümeye girer, bu nedenle bu kümeye ""olduğu gibi"" de dahil etmeniz önerilir.
			|Bu durumda, listelerde ve raporlarda farklı türde verileri seçmek mümkündür.'; 
			|es_ES = 'Añadir la información común en el conjunto (se recomienda)
			|
			| La información seleccionada ya forma parte de unos conjuntos por eso se recomienda también incluirlo en este conjunto ""como es"".
			|En este caso será posible seleccionar los datos de diferentes tipos en las listas e informes.'");
		MakeCommon = NStr("ru = 'Сделать дополнительное сведение общим и добавить в набор
			|
			|Этот вариант подходит для тех случаев, когда сведение должно быть одинаково для обоих наборов.
			|В этом случае будет возможно отбирать по нему данные разных типов в списках и отчетах.'; 
			|en = 'Make additional information shared and add it to the set
			|
			|This option is suitable when information is to be the same for both sets.
			|In such case, you will be able to filter data of different types by it in lists and reports.'; 
			|pl = 'Określ dodatkową informację jako wspólną i dodaj do zestawu
			|
			|Ten wariant jest odpowiedni dla tych sytuacji, kiedy informacja musi być jednakowa dla obu zestawów.
			|W tym przypadku będzie możliwy wybór wg niej kilku danych różnych typów w listach i sprawozdaniach.';
			|de = 'Zusatzinformationen allgemein machen und zum Set hinzufügen
			|
			|Diese Option ist für die Fälle geeignet, in denen die Informationen für beide Sets gleich sein sollten.
			|In diesem Fall wird es möglich sein, Daten unterschiedlicher Art aus Listen und Berichten auszuwählen.';
			|ro = 'Fă comune datele suplimentare și adaugă în set
			|
			|Această variantă se potrivește pentru cazurile, când datele trebuie să fie la fel pentru ambele seturi.
			|În acest caz va fi posibil să selectați conform acesteia date de diferite tipuri în liste și rapoarte.';
			|tr = 'Ek bilgiyi ortak yap ve 
			|
			| kümeye ekle. Bu seçenek, her iki küme için de aynı olması gereken durumlar için uygundur.
			|Bu durumda, listelerde ve raporlarda farklı türde verileri seçmek mümkündür.'; 
			|es_ES = 'Hacer la información adicional como común y añadirla en el conjunto
			|
			|Esta variante es conveniente para los casos cuando la información debe ser la misma para ambos conjuntos.
			|En este caso será posible seleccionar los datos de diferentes tipos en las listas e informes.'");
		MakeBySample = NStr("ru = 'Сделать копию сведения по образцу (с общим списком значений)
			|
			|Список значений этого сведения будет одинаков для обоих наборов.
			|С помощью этого варианта удобно выполнять централизованную настройку списка значений сразу для нескольких однотипных сведений.
			|При этом можно отредактировать наименование и ряд других свойств сведения.'; 
			|en = 'Copy information by sample (with shared value list)
			|
			|The value list of this information will be the same for both sets.
			|With this option, you can configure the value list for information of the same type with a single action.
			|You can edit description and some other information properties.'; 
			|pl = 'Utwórz kopię informacji wg wzoru (ze wspólną listą wartości)
			|
			|Lista wartości tej informacji będzie jednakowa dla obu zestawów.
			|Przy pomocy tego wariantu można wygodnie wykonywać scentralizowaną konfigurację listy wartości od razu dla kilku informacji tego samego typu.
			|Przy czym jest możliwa edycja nazw i wielu innych właściwości informacji.';
			|de = 'Machen Sie eine Kopie der Informationen nach dem Muster (mit der allgemeinen Werteliste)
			|
			|Die Werteliste dieser Informationen ist für beide Sets gleich.
			|Diese Option erleichtert die zentrale Konfiguration der Werteliste für mehr als eine Art von Informationen gleichzeitig.
			|Sie können den Namen und andere Eigenschaften der Informationen bearbeiten.';
			|ro = 'Fă copia datelor conform modelului (cu lista de valori comună)
			|
			|Lista valorilor acestei date va fi la fel pentru ambele seturi.
			|Cu ajutorul acestei variante este comod să executați setarea centralizată a listei de valori concomitent pentru mai multe date de același tip.
			|Totodată puteți edita denumirea și o serie de alte proprietăți ale datelor.';
			|tr = 'Örnek bilgileri (ortak bir değer listesi ile) bir kopyasını yap 
			|
			| Bu bilgilerin değer listesi her iki küme için de aynı olacaktır.
			|Bu seçenek, birden çok tek tip bilgi için bir kerede merkezi bir değer listesi ayarını yapmak için kullanışlıdır.
			|Bu durumda, bilginin adı ve diğer özelliklerini düzenleyebilirsiniz.'; 
			|es_ES = 'Hacer la copia de respaldo según el modelo (con lista común de valores)
			|
			|La lista de valores de esta información será igual para ambos conjuntos.
			|Con esta variante es más cómodo realizar el ajuste centralizado de la lista de valores para unos tipos de información de un tipo.
			|Así se puede editar el nombre y otras propiedades de información.'");
		CreateByCopying = NStr("ru = 'Сделать копию сведения
			|
			|Будет создана копия сведения%1'; 
			|en = 'Copy information
			|
			|Copy of the %1 information will be created'; 
			|pl = 'Utwórz kopię informacji
			|
			|Zostanie utworzona kopia informacji%1';
			|de = 'Eine Kopie der Informationen erstellen
			|
			|Eine Kopie der Informationen wird erstellt%1';
			|ro = 'Fă copia datelor
			|
			|Va fi creată copia datelor%1';
			|tr = '
			|
			|Bilginin kopyasını yap %1Bilginin kopyası yapılacak'; 
			|es_ES = 'Hacer la copia de información
			|
			|Será creada una copia de información %1'");
	Else
		AddCommon = NStr("ru = 'Добавить общий реквизит в набор (рекомендуется)
			|
			|Выбранный реквизит уже входит в несколько наборов, поэтому рекомендуется также включить его в этот набор ""как есть"".
			|В этом случае будет возможно отбирать по нему данные разных типов в списках и отчетах.'; 
			|en = 'Add shared attribute to set (recommended)
			|
			|The selected attribute is already included in several sets. That is way it is recommended that you include it in this set ""as it is"".
			|In such case, you will be able to filter data of different types by it in lists and reports.'; 
			|pl = 'Dodaj wspólny atrybut do zestawu (zalecane) 
			|
			|Wybrany atrybut wchodzi już w skład kilku zestawów, dlatego jest zalecane włączenie do również do tego zestawu ""tak jak jest"".
			|W tym wypadku będzie możliwy wybór wg niego danych różnych typów w listach i sprawozdaniach.';
			|de = 'Hinzufügen eines allgemeinen Attributs zum Set (empfohlen)
			|
			|Das ausgewählte Attribut ist bereits in mehreren Sets enthalten, daher wird empfohlen, sie auch in diesem Set ""so wie sie ist"" aufzunehmen.
			|In diesem Fall wird es möglich sein, Daten unterschiedlicher Art in Listen und Berichten auszuwählen.';
			|ro = 'Adăugă atributul comun în set (recomandat)
			|
			|Atributul selectat deja face parte din mai multe seturi, de aceea recomandăm la fel să-l includeți în acest set ""cum este"".
			|În acest caz va fi posibil să selectați conform acestuia date de diferite tipuri în liste și rapoarte.';
			|tr = 'Bir kümeye ortak özellik ekle (önerilen) 
			|
			|Seçilen ayrıntı zaten birkaç kümeye girer, bu nedenle bu kümeye ""olduğu gibi"" de dahil etmeniz önerilir.
			|Bu durumda, listelerde ve raporlarda farklı türde verileri seçmek mümkündür.'; 
			|es_ES = 'Añadir el requisito común en el conjunto (se recomienda)
			|
			| El requisito seleccionado ya forma parte de unos conjuntos por eso se recomienda también incluirlo en este conjunto ""como es"".
			|En este caso será posible seleccionar los datos de diferentes tipos en las listas e informes.'");
		MakeCommon = NStr("ru = 'Сделать реквизит общим и добавить в набор
			|
			|Этот вариант подходит для тех случаев, когда реквизит должен быть одинаков для обоих наборов.
			|В этом случае будет возможно отбирать по нему данные разных типов в списках и отчетах.'; 
			|en = 'Make attribute shared and add it to set
			|
			|This option is suitable when the attribute is to be the same for both sets.
			|In such case, you will be able to filter data of different types by it in lists and reports.'; 
			|pl = 'Określ dodatkowy atrybut jako wspólny i dodaj do zestawu
			|
			|Ten wariant jest odpowiedni dla tych sytuacji, kiedy atrybut musi być jednakowy dla obu zestawów.
			|W tym przypadku będzie możliwy wybór wg niego danych różnych typów w listach i sprawozdaniach.';
			|de = 'Zusatzinattribute allgemein machen und zum Set hinzufügen
			|
			|Diese Option ist für die Fälle geeignet, in denen die Attribute für beide Sets gleich sein sollten.
			|In diesem Fall wird es möglich sein, Daten unterschiedlicher Art aus Listen und Berichten auszuwählen.';
			|ro = 'Fă comun atributul și adaugă în set
			|
			|Această variantă se potrivește pentru cazurile, când atributul trebuie să fie la fel pentru ambele seturi.
			|În acest caz va fi posibil să selectați conform acestuia date de diferite tipuri în liste și rapoarte.';
			|tr = 'Ek özelliği ortak yap ve 
			|
			| kümeye ekle. Bu seçenek, özelliğin her iki küme için de aynı olması gereken durumlar için uygundur.
			|Bu durumda, listelerde ve raporlarda farklı türde verileri seçmek mümkündür.'; 
			|es_ES = 'Hacer el requisito adicional como común y añadirlo en el conjunto
			|
			|Esta variante es conveniente para los casos cuando el requisito debe ser el mismo para ambos conjuntos.
			|En este caso será posible seleccionar los datos de diferentes tipos en las listas e informes.'");
		MakeBySample = NStr("ru = 'Сделать копию реквизита по образцу (с общим списком значений)
			|
			|Список значений этого реквизита будет одинаков для обоих наборов.
			|С помощью этого варианта удобно выполнять централизованную настройку списка значений сразу для нескольких однотипных реквизитов.
			|При этом можно отредактировать наименование и ряд других свойств реквизита.'; 
			|en = 'Copy attribute by sample (with shared value list)
			|
			|The value list of this attribute will be the same for both sets.
			|With this option, you can configure the value list for several attributes of the same type with a single action.
			|You can edit description and some other attribute properties.'; 
			|pl = 'Utwórz kopię atrybutu wg wzoru (ze wspólną listą wartości)
			|
			|Lista wartości tego atrybutu będzie jednakowa dla obu zestawów.
			|Przy pomocy tego wariantu można wygodnie wykonywać scentralizowaną konfigurację listy wartości od razu dla kilku atrybutów tego samego typu.
			|Przy czym jest możliwa edycja nazw i wielu innych właściwości atrybutu.';
			|de = 'Machen Sie eine Kopie der Informationen nach dem Muster (mit der allgemeinen Werteliste)
			|
			|Die Werteliste dieser Attribute ist für beide Sets gleich.
			|Diese Option erleichtert die zentrale Konfiguration der Werteliste für mehr als eine Art von Attributen gleichzeitig.
			|Sie können den Namen und andere Eigenschaften der Attribute bearbeiten.';
			|ro = 'Fă copia atributului conform modelului (cu lista de valori comună)
			|
			|Lista valorilor acestui atribut va fi la fel pentru ambele seturi.
			|Cu ajutorul acestei variante este comod să executați setarea centralizată a listei de valori concomitent pentru mai multe atribute de același tip.
			|Totodată puteți edita denumirea și o serie de alte proprietăți ale atributului.';
			|tr = 'Örnek özelliğin (ortak bir değer listesi ile) bir kopyasını yap 
			|
			| Bu özelliğin değerleri listesi her iki küme için de aynı olacaktır.
			|Bu seçenek, birden çok tek tip özellik için bir kerede merkezi bir değer listesi ayarını yapmak için kullanışlıdır.
			|Bu durumda, özelliğin adı ve diğer özelliklerini düzenleyebilirsiniz.'; 
			|es_ES = 'Hacer la copia de respaldo del requisito según el modelo (con lista común de valores)
			|
			|La lista de valores de este requisito será igual para ambos conjuntos.
			|Con esta variante es más cómodo realizar el ajuste centralizado de la lista de valores para unos tipos de requisitos de un tipo.
			|Así se puede editar el nombre y otras propiedades de información.'");
		CreateByCopying = NStr("ru = 'Сделать копию реквизита
			|
			|Будет создана копия реквизита%1'; 
			|en = 'Copy attribute
			|
			|Copy of the %1 attribute'; 
			|pl = 'Utwórz kopię atrybutu
			|
			|Zostanie utworzona kopia atrybutu%1';
			|de = 'Machen Sie eine Kopie der Attribute
			|
			|Eine Kopie der Attribute wird erstellt%1';
			|ro = 'Fă copia atributului
			|
			|Va fi creată copia atributului%1';
			|tr = '
			|
			|Özelliğin kopyasını yap %1Özelliğin '; 
			|es_ES = 'Hacer la copia del requisito
			|
			|Será creada una copia del requisito%1'");
	EndIf;
	
	ChoiceList = Items.AttributeAddMode.ChoiceList;
	ChoiceList.Clear();
	
	If AttributeWithAdditionalValuesList Then
		PasteTemplate = " " + NStr("ru = 'и всех его значений.'; en = 'and all its values will be created.'; pl = 'i wszystkich jego wartości.';de = 'und all seine Bedeutungen.';ro = 'și toate valorile sale.';tr = 've tüm onun değerlerinin kopyası yapılacak.'; es_ES = 'y de todos sus valores.'");
	Else
		PasteTemplate = ".";
	EndIf;
	CreateByCopying = StringFunctionsClientServer.SubstituteParametersToString(CreateByCopying, PasteTemplate);
	
	ChoiceList.Add("CreateByCopying", CreateByCopying);
	
	If UseCommonAdditionalValues AND AttributeWithAdditionalValuesList Then
		ChoiceList.Add("CreateBySample", MakeBySample);
	EndIf;
	
	If UseAdditionalCommonAttributesAndInfo AND IsCommonAdditionalAttribute Then
		ChoiceList.Add("AddCommonAttributeToSet", AddCommon);
	ElsIf UseAdditionalCommonAttributesAndInfo Then
		ChoiceList.Add("MakeCommon", MakeCommon);
	EndIf;
	
	AttributeAddMode = "CreateByCopying";
	
EndProcedure

&AtServer
Procedure WriteAdditionalAttributeValuesOnCopy(CurrentObject)
	
	If CurrentObject.ValueType.ContainsType(Type("CatalogRef.ObjectPropertyValueHierarchy")) Then
		Parent = Catalogs.ObjectPropertyValueHierarchy.EmptyRef();
	Else
		Parent = Catalogs.ObjectsPropertiesValues.EmptyRef();
	EndIf;
	
	Owner = CurrentObject.Ref;
	TreeRow = AdditionalAttributesValues.GetItems();
	WriteAdditionalAttributeValuesOnCopyRecursively(Owner, TreeRow, Parent);
	TreeRow.Clear();
	Items.AttributeValuePages.CurrentPage = Items.AdditionalValues;
	
EndProcedure

&AtServer
Procedure WriteAdditionalAttributeValuesOnCopyRecursively(Owner, TreeRow, Parent)
	
	For Each TreeItem In TreeRow Do
		ObjectCopy = TreeItem.Ref.GetObject().Copy();
		ObjectCopy.Owner = Owner;
		ObjectCopy.Parent = Parent;
		ObjectCopy.Write();
		
		SubordinateItems = TreeItem.GetItems();
		WriteAdditionalAttributeValuesOnCopyRecursively(Owner, SubordinateItems, ObjectCopy.Ref)
	EndDo;
	
EndProcedure

&AtServer
Procedure SetHyperlinkTitles()
	
	AvailabilityDependenceDefined              = False;
	RequiredFillingDependenceDefined = False;
	VisibilityDependenceDefined                = False;
	PropertiesDependencies = Object.AdditionalAttributesDependencies;
	
	For Each PropertyDependence In PropertiesDependencies Do
		If PropertyDependence.DependentProperty = "Available" Then
			AvailabilityDependenceDefined = True;
		ElsIf PropertyDependence.DependentProperty = "RequiredToFill" Then
			RequiredFillingDependenceDefined = True;
		ElsIf PropertyDependence.DependentProperty = "Visible" Then
			VisibilityDependenceDefined = True;
		EndIf;
	EndDo;
	
	TemplateDependenceDefined = NStr("ru = 'с условием'; en = 'with condition'; pl = 'z warunkiem';de = 'vorbehaltlich';ro = 'cu condiția';tr = 'koşulu ile'; es_ES = 'con condición'");
	TemplateDependenceNotDefined = NStr("ru = 'всегда'; en = 'always'; pl = 'zawsze';de = 'immer';ro = 'întotdeauna';tr = 'her zaman'; es_ES = 'siempre'");
	
	Items.ChooseAvailabilityOption.Title = ?(AvailabilityDependenceDefined,
		TemplateDependenceDefined,
		TemplateDependenceNotDefined);
	
	Items.ChooseItemRequiredOption.Title = ?(RequiredFillingDependenceDefined,
		TemplateDependenceDefined,
		TemplateDependenceNotDefined);
	
	Items.ChooseVisibilityOption.Title = ?(VisibilityDependenceDefined,
		TemplateDependenceDefined,
		TemplateDependenceNotDefined);
	
EndProcedure

&AtClient
Procedure OpenDependenceSettingForm(PropertyToConfigure)
	
	FormParameters = New Structure;
	FormParameters.Insert("AdditionalAttribute", Object.Ref);
	FormParameters.Insert("AttributesDependencies", Object.AdditionalAttributesDependencies);
	FormParameters.Insert("Set", Object.PropertiesSet);
	FormParameters.Insert("PropertyToConfigure", PropertyToConfigure);
	
	OpenForm("ChartOfCharacteristicTypes.AdditionalAttributesAndInfo.Form.AttributesDependencies", FormParameters);
	
EndProcedure

&AtServer
Procedure SetFormHeader()
	
	If ValueIsFilled(Object.Ref) Then
		
		If ValueIsFilled(Object.PropertiesSet) Then
			If Object.IsAdditionalInfo Then
				Title = String(Object.Title) + " " + NStr("ru = '(Дополнительное сведение)'; en = '(Additional information)'; pl = '(Informacja dodatkowa)';de = '(Zusätzliche Information)';ro = '(Date suplimentare)';tr = '(Ek bilgi)'; es_ES = '(Información adicional)'");
			Else
				Title = String(Object.Title) + " " + NStr("ru = '(Дополнительный реквизит)'; en = '(Additional attribute)'; pl = '(Dodatkowy atrybut)';de = '(Zusätzliches Attribut)';ro = '(Atribut suplimentar)';tr = '(Ek özellik)'; es_ES = '(Atributo adicional)'");
			EndIf;
		Else
			If Object.IsAdditionalInfo Then
				Title = String(Object.Title) + " " + NStr("ru = '(Общее дополнительное сведение)'; en = '(Shared additional information record)'; pl = '(Wspólne informacje dodatkowe)';de = '(Gemeinsame zusätzliche Informationen)';ro = '(Informații suplimentare comun)';tr = '(Ortak ek bilgi)'; es_ES = '(Información adicional común)'");
			Else
				Title = String(Object.Title) + " " + NStr("ru = '(Общий дополнительный реквизит)'; en = '(Shared additional attribute)'; pl = '(Wspólny atrybut dodatkowy)';de = '(Gemeinsames zusätzliches Attribut)';ro = '(Atribut suplimentar comun)';tr = '(Ortak ek özellik)'; es_ES = '(Atributo adicional común)'");
			EndIf;
		EndIf;
	Else
		If ValueIsFilled(Object.PropertiesSet) Then
			If Object.IsAdditionalInfo Then
				Title = NStr("ru = 'Дополнительное сведение (создание)'; en = 'Additional information (create)'; pl = 'Informacja dodatkowa (tworzenie)';de = 'Zusätzliche Informationen (Erstellung)';ro = 'Date suplimentare (creare)';tr = 'Ek bilgi (oluşturma)'; es_ES = 'Información adicional (creación)'");
			Else
				Title = NStr("ru = 'Дополнительный реквизит (создание)'; en = 'Additional attribute (create)'; pl = 'Dodatkowy rekwizyt (tworzenie)';de = 'Zusätzliches Attribut (Erstellung)';ro = 'Atribut suplimentar (creare)';tr = 'Ek özellik (oluşturma)'; es_ES = 'Atributo adicional (creación)'");
			EndIf;
		Else
			If Object.IsAdditionalInfo Then
				Title = NStr("ru = 'Общее дополнительное сведение (создание)'; en = 'Shared additional information record (create)'; pl = 'Wspólne dodatkowe informacje (tworzenie)';de = 'Gemeinsame zusätzliche Informationen (Erstellung)';ro = 'Date suplimentare comune (creare)';tr = 'Ortak ek bilgi (oluşturma)'; es_ES = 'Información adicional común (creación)'");
			Else
				Title = NStr("ru = 'Общий дополнительный реквизит (создание)'; en = 'Shared additional attribute (create)'; pl = 'Wspólny dodatkowy atrybut (tworzenie)';de = 'Gemeinsames zusätzliches Attribut (Erstellung)';ro = 'Atribut suplimentar comun (creare)';tr = 'Ortak ek özellik (oluşturma)'; es_ES = 'Atributo adicional común (creación)'");
			EndIf;
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure OnChangeCurrentSet()
	
	If Items.PropertiesSets.CurrentData = Undefined Then
		If ValueIsFilled(SelectedPropertiesSet) Then
			SelectedPropertiesSet = Undefined;
			OnChangeCurrentSetAtServer();
		EndIf;
		
	ElsIf Items.PropertiesSets.CurrentData.Ref <> SelectedPropertiesSet Then
		SelectedPropertiesSet = Items.PropertiesSets.CurrentData.Ref;
		CurrentSetIsFolder = Items.PropertiesSets.CurrentData.IsFolder;
		OnChangeCurrentSetAtServer(CurrentSetIsFolder);
	EndIf;
	
EndProcedure

&AtServer
Procedure OnChangeCurrentSetAtServer(CurrentSetIsFolder = Undefined)
	
	If ValueIsFilled(SelectedPropertiesSet)
		AND NOT CurrentSetIsFolder Then
		UpdateCurrentSetPropertiesList();
	Else
		Properties.Clear();
	EndIf;
	
EndProcedure

&AtServer
Procedure UpdateCurrentSetPropertiesList()
	
	Query = New Query;
	
	If Not Items.SharedAttributesNotIncludedInSets.Check Then
		Query.SetParameter("Set", SelectedPropertiesSet);
		Query.Text =
			"SELECT
			|	SetsProperties.LineNumber,
			|	SetsProperties.Property,
			|	SetsProperties.DeletionMark,
			|	CASE
			|		WHEN &IsMainLanguage
			|		THEN Properties.Title
			|		ELSE CAST(ISNULL(PresentationProperties.Title, Properties.Title) AS STRING(150))
			|	END AS Title,
			|	Properties.AdditionalValuesOwner,
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
			|	END AS PictureNumber,
			|	CASE
			|		WHEN &IsMainLanguage
			|		THEN Properties.ToolTip
			|		ELSE CAST(ISNULL(PresentationProperties.ToolTip, Properties.ToolTip) AS STRING(150))
			|	END AS ToolTip,
			|	CASE
			|		WHEN &IsMainLanguage
			|		THEN Properties.ValueFormTitle
			|		ELSE CAST(ISNULL(PresentationProperties.ValueFormTitle, Properties.ValueFormTitle) AS STRING(150))
			|	END AS ValueFormTitle,
			|	CASE
			|		WHEN &IsMainLanguage
			|		THEN Properties.ValueChoiceFormTitle
			|		ELSE CAST(ISNULL(PresentationProperties.ValueChoiceFormTitle, Properties.ValueChoiceFormTitle) AS STRING(150))
			|	END AS ValueChoiceFormTitle
			|FROM
			|	Catalog.AdditionalAttributesAndInfoSets.AdditionalAttributes AS SetsProperties
			|		LEFT JOIN ChartOfCharacteristicTypes.AdditionalAttributesAndInfo AS Properties
			|		ON SetsProperties.Property = Properties.Ref
			|		LEFT JOIN ChartOfCharacteristicTypes.AdditionalAttributesAndInfo.Presentations AS PresentationProperties
			|		ON SetsProperties.Property = PresentationProperties.Ref
			|			AND PresentationProperties.LanguageCode = &LanguageCode
			|
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
		
		If IsAdditionalInfo Then
			Query.Text = StrReplace(
				Query.Text,
				"Catalog.AdditionalAttributesAndInfoSets.AdditionalAttributes",
				"Catalog.AdditionalAttributesAndInfoSets.AdditionalInfo");
		EndIf;
		
	Else
		Query.Text =
		"SELECT
		|	Properties.Ref AS Property,
		|	Properties.DeletionMark AS DeletionMark,
		|	CASE
		|		WHEN &IsMainLanguage
		|		THEN Properties.Title
		|		ELSE CAST(ISNULL(PresentationProperties.Title, Properties.Title) AS STRING(150))
		|	END AS Title,
		|	Properties.AdditionalValuesOwner,
		|	Properties.ValueType AS ValueType,
		|	TRUE AS Common,
		|	CASE
		|		WHEN Properties.DeletionMark = TRUE
		|			THEN 4
		|		ELSE 3
		|	END AS PictureNumber,
		|	CASE
		|		WHEN &IsMainLanguage
		|		THEN Properties.ToolTip
		|		ELSE CAST(ISNULL(PresentationProperties.ToolTip, Properties.ToolTip) AS STRING(150))
		|	END AS ToolTip,
		|	CASE
		|		WHEN &IsMainLanguage
		|		THEN Properties.ValueFormTitle
		|		ELSE CAST(ISNULL(PresentationProperties.ValueFormTitle, Properties.ValueFormTitle) AS STRING(150))
		|	END AS ValueFormTitle,
		|	CASE
		|		WHEN &IsMainLanguage
		|		THEN Properties.ValueChoiceFormTitle
		|		ELSE CAST(ISNULL(PresentationProperties.ValueChoiceFormTitle, Properties.ValueChoiceFormTitle) AS STRING(150))
		|	END AS ValueChoiceFormTitle
		|FROM
		|	ChartOfCharacteristicTypes.AdditionalAttributesAndInfo AS Properties
		|		LEFT JOIN ChartOfCharacteristicTypes.AdditionalAttributesAndInfo.Presentations AS PresentationProperties
		|		ON Properties.Property = PresentationProperties.Ref
		|			AND PresentationProperties.LanguageCode = &LanguageCode
		|		
		|WHERE
		|	Properties.PropertiesSet = VALUE(Catalog.AdditionalAttributesAndInfoSets.EmptyRef)
		|		AND Properties.IsAdditionalInfo = &IsAdditionalInfo
		|
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	""DataVersion"" AS DataVersion";
		
		Query.SetParameter("IsAdditionalInfo", (IsAdditionalInfo = 1));
	EndIf;
	Query.SetParameter("IsMainLanguage", CurrentLanguage() = Metadata.DefaultLanguage);
	Query.SetParameter("LanguageCode", CurrentLanguage().LanguageCode);
	
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
			|UNION ALL
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
Procedure NewPassedParametersStructure()
	PassedFormParameters = New Structure;
	PassedFormParameters.Insert("AdditionalValuesOwner");
	PassedFormParameters.Insert("ShowSetAdjustment");
	PassedFormParameters.Insert("CurrentPropertiesSet");
	PassedFormParameters.Insert("IsAdditionalInfo");
	PassedFormParameters.Insert("SelectCommonProperty");
	PassedFormParameters.Insert("SelectedValues");
	PassedFormParameters.Insert("SelectAdditionalValueOwner");
	PassedFormParameters.Insert("CopyingValue");
	PassedFormParameters.Insert("CopyWithQuestion");
	PassedFormParameters.Insert("Drag", False);
	
	FillPropertyValues(PassedFormParameters, Parameters);
EndProcedure

&AtServerNoContext
Function DescriptionAlreadyUsed(Val Title, Val CurrentProperty, Val PropertiesSet, NewDescription, Val Presentations)
	
	If CurrentLanguage() <> Metadata.DefaultLanguage Then
		Filter = New Structure();
		Filter.Insert("LanguageCode", Metadata.DefaultLanguage.LanguageCode);
		FoundRows = Presentations.FindRows(Filter);
		If FoundRows.Count() > 0 Then
			Title = FoundRows[0].Title;
		EndIf;
	EndIf;
	
	If ValueIsFilled(PropertiesSet) Then
		SetDescription = Common.ObjectAttributeValue(PropertiesSet, "Description");
		NewDescription = Title + " (" + SetDescription + ")";
	Else
		NewDescription = Title;
	EndIf;
	
	Query = New Query;
	Query.Text =
	"SELECT TOP 1
	|	Properties.IsAdditionalInfo,
	|	Properties.PropertiesSet
	|FROM
	|	ChartOfCharacteristicTypes.AdditionalAttributesAndInfo AS Properties
	|WHERE
	|	Properties.Description = &Description
	|	AND Properties.Ref <> &Ref
	|	AND Properties.PropertiesSet = &Set";
	
	Query.SetParameter("Ref",       CurrentProperty);
	Query.SetParameter("Set",        PropertiesSet);
	Query.SetParameter("Description", NewDescription);
	
	BeginTransaction();
	Try
		Selection = Query.Execute().Select();
		
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;
	
	If NOT Selection.Next() Then
		Return "";
	EndIf;
	
	If ValueIsFilled(Selection.PropertiesSet) Then
		If Selection.IsAdditionalInfo Then
			QuestionText = NStr("ru = 'Существует дополнительное сведение с наименованием
			                          |""%1"".'; 
			                          |en = 'Additional information with the
			                          |""%1"" description is not unique.'; 
			                          |pl = 'Istnieje informacja dodatkowa z pozycją
			                          |""%1"".';
			                          |de = 'Es gibt zusätzliche Informationen zum Namen
			                          |""%1"".';
			                          |ro = 'Există datele suplimentare cu numele
			                          |""%1"".';
			                          |tr = '
			                          |""%1"" adlı ek bilgi mevcut.'; 
			                          |es_ES = 'Hay una información adicional con el nombre 
			                          | ""%1"".'");
		Else
			QuestionText = NStr("ru = 'Существует дополнительный реквизит с наименованием
			                          |""%1"".'; 
			                          |en = 'Additional attribute with the
			                          |""%1"" description is not unique.'; 
			                          |pl = 'Istnieje atrybut dodatkowy z pozycją
			                          |""%1"".';
			                          |de = 'Es gibt zusätzliche Attribute zum Namen
			                          |""%1"".';
			                          |ro = 'Există atributul suplimentar cu numele
			                          |""%1"".';
			                          |tr = '%1"
" adlı ek özellik mevcut.'; 
			                          |es_ES = 'Hay un requisito adicional con el nombre 
			                          | ""%1"".'");
		EndIf;
	Else
		If Selection.IsAdditionalInfo Then
			QuestionText = NStr("ru = 'Существует общее дополнительное сведение с наименованием
			                          |""%1"".'; 
			                          |en = 'Shared additional information record
			                          |%1 already exists.'; 
			                          |pl = 'Istnieje wspólna informacja dodatkowa z pozycją
			                          |""%1"".';
			                          |de = 'Es gibt allgemeine Informationen zum Namen
			                          |""%1"".';
			                          |ro = 'Există datele suplimentare comune cu numele
			                          |""%1"".';
			                          |tr = '"
" adıyla ortak %1 ek bilgi mevcuttur. '; 
			                          |es_ES = 'Hay una información adicional común con el nombre 
			                          | ""%1"".'");
		Else
			QuestionText = NStr("ru = 'Существует общий дополнительный реквизит с наименованием
			                          |""%1"".'; 
			                          |en = 'Shared additional attribute
			                          |%1 already exists.'; 
			                          |pl = 'Istnieje wspólny atrybut dodatkowy z pozycją
			                          |""%1"".';
			                          |de = 'Es gibt allgemeine Attribute zum Namen
			                          |""%1"".';
			                          |ro = 'Există atributul suplimentar comun cu numele
			                          |""%1"".';
			                          |tr = '"
" adıyla ortak %1 ek özellik mevcuttur. '; 
			                          |es_ES = 'Hay un requisito adicional común con el nombre 
			                          | ""%1"".'");
		EndIf;
	EndIf;
	
	QuestionText = StringFunctionsClientServer.SubstituteParametersToString(
		QuestionText + Chars.LF + Chars.LF
		                         + NStr("ru ='Рекомендуется использовать другое наименование,
		                         |иначе программа может работать некорректно.'; 
		                         |en = 'We recommend that you use another description,
		                         |otherwise, the application might not work properly.'; 
		                         |pl = 'Zaleca się użycie innej pozycji,
		                         |w przeciwnym wypadku program może pracować nieprawidłowo.';
		                         |de = 'Es wird empfohlen, einen anderen Namen zu verwenden,
		                         |da das Programm sonst möglicherweise nicht richtig funktioniert.';
		                         |ro = 'Se recomandă să utilizați un alt nume,
		                         |altfel aplicația poate funcționa incorect.';
		                         |tr = '
		                         |Başka bir ad kullanmanız önerilir, aksi halde uygulama yanlış çalışabilir.'; 
		                         |es_ES = 'Se recomienda usar otro nombre,
		                         |en otro caso el programa puede funcionar incorrectamente.'"),
		NewDescription);
	
	Return QuestionText;
	
EndFunction

&AtServerNoContext
Function NameAlreadyUsed(Val Name, Val CurrentProperty, Val PropertiesSet, NewDescription)
	
	Query = New Query;
	Query.Text =
	"SELECT TOP 1
	|	Properties.IsAdditionalInfo,
	|	Properties.PropertiesSet
	|FROM
	|	ChartOfCharacteristicTypes.AdditionalAttributesAndInfo AS Properties
	|WHERE
	|	Properties.Name = &Name
	|	AND Properties.Ref <> &Ref";
	
	Query.SetParameter("Ref", CurrentProperty);
	Query.SetParameter("Name",    Name);
	
	BeginTransaction();
	Try
		Selection = Query.Execute().Select();
		
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;
	
	If NOT Selection.Next() Then
		Return "";
	EndIf;
	
	If Selection.IsAdditionalInfo Then
		QuestionText = NStr("ru = 'Существует дополнительное сведение с именем
		                          |""%1"".'; 
		                          |en = 'Additional information with the
		                          |""%1"" name is not unique.'; 
		                          |pl = 'Istnieje informacja dodatkowa o nazwie
		                          |""%1""';
		                          |de = 'Es gibt zusätzliche Informationen mit dem Namen
		                          |""%1"".';
		                          |ro = 'Există datele suplimentare cu numele
		                          |""%1"".';
		                          |tr = '
		                          |""%1"" adlı ek bilgi mevcut.'; 
		                          |es_ES = 'Hay una información adicional con el nombre 
		                          | ""%1"".'");
	Else
		QuestionText = NStr("ru = 'Существует дополнительный реквизит с именем
		                          |""%1"".'; 
		                          |en = 'Additional attribute with the
		                          |""%1"" name is not unique.'; 
		                          |pl = 'Istnieje atrybut dodatkowy o nazwie
		                          |""%1"".';
		                          |de = 'Es gibt zusätzliche Attribute mit dem Namen
		                          |""%1"".';
		                          |ro = 'Există atributul suplimentar cu numele
		                          |""%1"".';
		                          |tr = '%1"
" adlı ek özellik mevcut.'; 
		                          |es_ES = 'Hay un requisito adicional con el nombre 
		                          | ""%1"".'");
	EndIf;
	
	QuestionText = StringFunctionsClientServer.SubstituteParametersToString(
		QuestionText + Chars.LF + Chars.LF
		                         + NStr("ru = 'Рекомендуется использовать другое имя,
		                         |иначе программа может работать некорректно.
		                         |
		                         |Создать новое имя и продолжить запись?'; 
		                         |en = 'We recommend that you use another name,
		                         |otherwise, the application might not work properly.
		                         |
		                         |Create a new name and continue writing?'; 
		                         |pl = 'Zaleca się użycie innej nazwy,
		                         |w przeciwnym wypadku program może pracować nieprawidłowo.
		                         |
		                         |Utworzyć nową nazwę i kontynuować zapis?';
		                         |de = 'Es wird empfohlen, einen anderen Namen zu verwenden,
		                         |da das Programm sonst möglicherweise nicht richtig funktioniert.
		                         |
		                         |Einen neuen Namen anlegen und die Aufzeichnung fortsetzen?';
		                         |ro = 'Recomandăm să utilizați alt nume,
		                         |în alt caz programul poate lucra incorect.
		                         |
		                         |Creați numele nou și continuați înregistrarea?';
		                         |tr = 'Başka bir ad kullanmanız önerilir, 
		                         |aksi halde uygulama yanlış çalışabilir.
		                         |
		                         |Yeni ad oluştur ve kaydetmeye devam et?'; 
		                         |es_ES = 'Se recomienda usar otro nombre,
		                         |en otro caso el programa puede funcionar incorrectamente.
		                         |
		                         |¿Crear el nuevo nombre y seguir guardando?'"),
		Name);
	
	Return QuestionText;
	
EndFunction

&AtClientAtServerNoContext
Procedure SetFormatButtonTitle(Form)
	
	If IsBlankString(Form.Object.FormatProperties) Then
		TitleText = NStr("ru = 'Формат по умолчанию'; en = 'Default format'; pl = 'Format domyślnie';de = 'Standardformat';ro = 'Formatul implicit';tr = 'Varsayılan biçim'; es_ES = 'Formato por defecto'");
	Else
		TitleText = NStr("ru = 'Формат установлен'; en = 'Format is set'; pl = 'Format jest ustalony';de = 'Format ist eingestellt';ro = 'Format este setat';tr = 'Biçim ayarlandı'; es_ES = 'Formato se ha establecido'");
	EndIf;
	
	Form.Items.EditValueFormat.Title = TitleText;
	
EndProcedure

#EndRegion
