﻿///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Variables

&AtClient
Var ListItemBeforeStartChanging;

#EndRegion

#Region EventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	Parameters.Property("RestrictSelectionBySpecifiedValues", RestrictSelectionBySpecifiedValues);
	QuickChoice = CommonClientServer.StructureProperty(Parameters, "QuickChoice", False);
	
	TypesInformation = ReportsServer.ExtendedTypesDetails(Parameters.TypeDescription, True);
	TypesInformation.Insert("ContainsRefTypes", False);
	
	AllTypesWithQuickChoice = TypesInformation.TypesCount < 10
		AND (TypesInformation.TypesCount = TypesInformation.ObjectTypes.Count());
	For Each Type In TypesInformation.ObjectTypes Do
		MetadataObject = Metadata.FindByType(Type);
		If MetadataObject = Undefined Then
			Continue;
		EndIf;
		
		TypesInformation.ContainsRefTypes = True;
		
		Kind = Upper(StrSplit(MetadataObject.FullName(), ".")[0]);
		If Kind <> "ENUM" Then
			If Kind = "CATALOG"
				Or Kind = "CHARTOFCALCULATIONTYPES"
				Or Kind = "CHARTOFCHARACTERISTICTYPES"
				Or Kind = "EXCHANGEPLAN"
				Or Kind = "CHARTOFACCOUNTS" Then
				If MetadataObject.ChoiceMode <> Metadata.ObjectProperties.ChoiceMode.QuickChoice Then
					AllTypesWithQuickChoice = False;
				EndIf;
			Else
				AllTypesWithQuickChoice = False;
			EndIf;
		EndIf;
		
		If Not AllTypesWithQuickChoice Then
			Break;
		EndIf;
	EndDo;
	
	ValuesForChoice = CommonClientServer.StructureProperty(Parameters, "ValuesForSelection");
	Marked = CommonClientServer.StructureProperty(Parameters, "Marked");
	
	If AllTypesWithQuickChoice Then
		QuickChoice = True;
	EndIf;
	
	If Not RestrictSelectionBySpecifiedValues AND QuickChoice AND Not Parameters.ValuesForSelectionFilled Then
		ValuesForChoice = ReportsServer.ValuesForSelection(Parameters);
	EndIf;
	
	Title = CommonClientServer.StructureProperty(Parameters, "Presentation");
	If IsBlankString(Title) Then
		Title = String(Parameters.TypeDescription);
	EndIf;
	
	If TypesInformation.TypesCount = 0 Then
		RestrictSelectionBySpecifiedValues = True;
	ElsIf Not TypesInformation.ContainsObjectTypes Or QuickChoice Then
		Items.ListPick.Visible       = False;
		Items.ListPickMenu.Visible   = False;
		Items.ListPickFooter.Visible = False;
		Items.ListAdd.OnlyInAllActions = False;
	EndIf;
	
	SelectGroupsAndItems = CommonClientServer.StructureProperty(Parameters, "ChoiceFoldersAndItems");
	Items.ListValue.ChoiceFoldersAndItems = ReportsClientServer.GroupsAndItemsTypeValue(SelectGroupsAndItems);
	
	List.ValueType = TypesInformation.TypesDetailsForForm;
	If TypeOf(ValuesForChoice) = Type("ValueList") Then
		ValuesForChoice.FillChecks(False);
		ReportsClientServer.AddToList(List, ValuesForChoice, True, True);
	EndIf;
	If TypeOf(Marked) = Type("ValueList") Then
		Marked.FillChecks(True);
		ReportsClientServer.AddToList(List, Marked, True, Not RestrictSelectionBySpecifiedValues);
	EndIf;
	
	If List.Count() = 0 Then
		Items.ListPickFooter.Visible = False;
	EndIf;
	
	If RestrictSelectionBySpecifiedValues Then
		Items.ListValue.ReadOnly = True;
		Items.List.ChangeRowSet    = False;
		
		Items.ListAddDelete.Visible     = False;
		Items.ListAddDeleteMenu.Visible = False;
		
		Items.ListSort.Visible     = False;
		Items.ListSortMenu.Visible = False;
		
		Items.ListMove.Visible     = False;
		Items.ListMoveMenu.Visible = False;
		
		Items.ListPickFooter.Visible = False;
	EndIf;
	
	ChoiceParameters = CommonClientServer.StructureProperty(Parameters, "ChoiceParameters");
	If TypeOf(ChoiceParameters) = Type("Array") Then
		Items.ListValue.ChoiceParameters = New FixedArray(ChoiceParameters);
	EndIf;
	
	WindowOptionsKey = CommonClientServer.StructureProperty(Parameters, "UniqueKey");
	If IsBlankString(WindowOptionsKey) Then
		WindowOptionsKey = Common.TrimStringUsingChecksum(String(List.ValueType), 128);
	EndIf;
	
	If RestrictSelectionBySpecifiedValues
		Or Not TypesInformation.ContainsRefTypes
		Or Not Common.SubsystemExists("StandardSubsystems.ImportDataFromFile") Then
			Items.ListPasteFromClipboard.Visible     = False;
			Items.ListPasteFromClipboardMenu.Visible = False;
	EndIf;
EndProcedure

#EndRegion

#Region ListFormTableItemsEventHandlers

&AtClient
Procedure ListBeforeStartChanging(Item, Cancel)
	IDRow = Item.CurrentRow;
	If IDRow = Undefined Then
		Return;
	EndIf;
	
	ValueListInForm = ThisObject[Item.Name];
	ListItemInForm = ValueListInForm.FindByID(IDRow);
	
	CurrentRow = Item.CurrentData;
	If CurrentRow = Undefined Then
		Return;
	EndIf;
	ListItemBeforeStartChanging = New Structure("ID, Check, Value, Presentation");
	FillPropertyValues(ListItemBeforeStartChanging, ListItemInForm);
	ListItemBeforeStartChanging.ID = IDRow;
EndProcedure

&AtClient
Procedure ListBeforeAdd(Item, Cancel, Clone, Parent, Folder, Parameter)
	If RestrictSelectionBySpecifiedValues Then
		Cancel = True;
	EndIf;
EndProcedure

&AtClient
Procedure ListBeforeRemove(Item, Cancel)
	If RestrictSelectionBySpecifiedValues Then
		Cancel = True;
	EndIf;
EndProcedure

&AtClient
Procedure ListBeforeEditEnd(Item, NewRow, CancelEditStart, CancelEditComplete)
	If CancelEditStart Then
		Return;
	EndIf;
	
	IDRow = Item.CurrentRow;
	If IDRow = Undefined Then
		Return;
	EndIf;
	ValueListInForm = ThisObject[Item.Name];
	ListItemInForm = ValueListInForm.FindByID(IDRow);
	
	Value = ListItemInForm.Value;
	If Value = Undefined
		Or Value = Type("Undefined")
		Or Value = New TypeDescription("Undefined")
		Or Not ValueIsFilled(Value) Then
		CancelEditComplete = True; // Blank values are prohibited.
	Else
		For Each ListItemDuplicateInForm In ValueListInForm Do
			If ListItemDuplicateInForm.Value = Value AND ListItemDuplicateInForm <> ListItemInForm Then
				CancelEditComplete = True; // Duplicates are prohibited.
				Break;
			EndIf;
		EndDo;
	EndIf;
	
	HasInformation = (ListItemBeforeStartChanging <> Undefined AND ListItemBeforeStartChanging.ID = IDRow);
	If Not CancelEditComplete AND HasInformation AND ListItemBeforeStartChanging.Value <> Value Then
		If RestrictSelectionBySpecifiedValues Then
			CancelEditComplete = True;
		Else
			ListItemInForm.Presentation = ""; // Autofilling a presentation.
			ListItemInForm.Check = True; // Selecting a check box.
		EndIf;
	EndIf;
	
	If CancelEditComplete Then
		// Rolling back values.
		If HasInformation Then
			FillPropertyValues(ListItemInForm, ListItemBeforeStartChanging);
		EndIf;
		// Restart the "BeforeEditEnd" event with CancelEditStart = True.
		Item.EndEditRow(True);
	Else
		If NewRow Then
			ListItemInForm.Check = True; // Selecting a check box.
		EndIf;
	EndIf;
EndProcedure

&AtClient
Procedure ChoiceProcessingList(Item, SelectionResult, StandardProcessing)
	StandardProcessing = False;
	
	Selected = ReportsClientServer.ValuesByList(SelectionResult);
	Selected.FillChecks(True);
	
	Addition = ReportsClientServer.AddToList(List, Selected, True, True);
	If Addition.Total = 0 Then
		Return;
	EndIf;
	If Addition.Total = 1 Then
		NotificationTitle = NStr("ru = 'Элемент добавлен в список'; en = 'The item added to the list.'; pl = 'Element dodany do listy';de = 'Element zur Liste hinzugefügt';ro = 'Elementul este adăugat în listă';tr = 'Öğe listeye eklendi'; es_ES = 'Elemento añadido en la lista'");
	Else
		NotificationTitle = NStr("ru = 'Элементы добавлены в список'; en = 'The items added to the list.'; pl = 'Elementy zostały dodane do listy';de = 'Elemente zur Liste hinzugefügt';ro = 'Elementele sunt adăugate în listă';tr = 'Öğeler listeye eklendi'; es_ES = 'Elementos añadidos en la lista'");
	EndIf;
	ShowUserNotification(
		NotificationTitle,
		,
		String(Selected),
		PictureLib.ExecuteTask);
EndProcedure

#EndRegion

#Region FormCommandHandlers

&AtClient
Procedure CompleteEditing(Command)
	If ModalMode
		Or WindowOpeningMode = FormWindowOpeningMode.LockWholeInterface
		Or FormOwner = Undefined Then
		Close(List);
	Else
		NotifyChoice(List);
	EndIf;
EndProcedure

&AtClient
Procedure PasteFromClipboard(Command)
	SearchParameters = New Structure;
	SearchParameters.Insert("TypeDescription", List.ValueType);
	SearchParameters.Insert("ChoiceParameters", Items.ListValue.ChoiceParameters);
	SearchParameters.Insert("FieldPresentation", Title);
	SearchParameters.Insert("Scenario", "RefsSearch");
	
	ExecutionParameters = New Structure;
	Handler = New NotifyDescription("PasteFromClipboardCompletion", ThisObject, ExecutionParameters);
	
	ModuleImportDataFromFileClient = CommonClient.CommonModule("ImportDataFromFileClient");
	ModuleImportDataFromFileClient.ShowRefFillingForm(SearchParameters, Handler);
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure PasteFromClipboardCompletion(FoundObjects, ExecutionParameters) Export
	
	If FoundObjects = Undefined Then
		Return;
	EndIf;
	
	For Each Value In FoundObjects Do
		ReportsClientServer.AddUniqueValueToList(List, Value, Undefined, True);
	EndDo;
	
EndProcedure

#EndRegion