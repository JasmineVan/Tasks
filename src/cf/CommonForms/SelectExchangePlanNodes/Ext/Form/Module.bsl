///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////////////
// Selection form for fields of Exchange Plan Node type.
//  
////////////////////////////////////////////////////////////////////////////////

#Region EventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	// Processing the standard parameters.
	If Parameters.CloseOnChoice = False Then
		PickMode = True;
		If Parameters.Property("MultipleChoice") AND Parameters.MultipleChoice = True Then
			MultipleChoice = True;
		EndIf;
	EndIf;
	
	// Preparing the list of used exchange plans.
	If TypeOf(Parameters.ExchangePlansForSelection) = Type("Array") Then
		For each Item In Parameters.ExchangePlansForSelection Do
			If TypeOf(Item) = Type("String") Then
				// Searching for the exchange plan by name.
				AddUsedExchangePlan(Metadata.FindByFullName(Item));
				AddUsedExchangePlan(Metadata.FindByFullName("ExchangePlan." + Item));
				//
			ElsIf TypeOf(Item) = Type("Type") Then
				// Searching for the exchange plan by type.
				AddUsedExchangePlan(Metadata.FindByType(Item));
			Else
				// Searching for the exchange plan by node type.
				AddUsedExchangePlan(Metadata.FindByType(TypeOf(Item)));
			EndIf;
		EndDo;
	Else
		// All exchange plans are available for selection.
		For each MetadataObject In Metadata.ExchangePlans Do
			AddUsedExchangePlan(MetadataObject);
		EndDo;
	EndIf;
	
	ExchangePlansNodes.Sort("ExchangePlanPresentation Asc");
	
	If PickMode Then
		Title = NStr("ru = 'Подбор узлов планов обмена'; en = 'Select exchange plan nodes'; pl = 'SelectExchangePlanNodes';de = 'Austauschplan- Knoten auswählen';ro = 'Selectați nodurile planului de schimb';tr = 'Değişim plan düğümleri seç'; es_ES = 'SelectExchangePlanNodes'");
	EndIf;
	If MultipleChoice Then
		Items.ExchangePlansNodes.SelectionMode = TableSelectionMode.MultiRow;
	EndIf;
	
	CurrentRow = Undefined;
	Parameters.Property("CurrentRow", CurrentRow);
	
	FoundRows = ExchangePlansNodes.FindRows(New Structure("Node", CurrentRow));
	
	If FoundRows.Count() > 0 Then
		Items.ExchangePlansNodes.CurrentRow = FoundRows[0].GetID();
	EndIf;
	
EndProcedure

#EndRegion

#Region ExchangePlanNodesFormTableItemsEventHandlers

&AtClient
Procedure ExchangePlanNodesChoice(Item, RowSelected, Field, StandardProcessing)
	
	If MultipleChoice Then
		ChoiceValue = New Array;
		ChoiceValue.Add(ExchangePlansNodes.FindByID(RowSelected).Node);
		NotifyChoice(ChoiceValue);
	Else
		NotifyChoice(ExchangePlansNodes.FindByID(RowSelected).Node);
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandHandlers

&AtClient
Procedure Select(Command)
	
	If MultipleChoice Then
		ChoiceValue = New Array;
		For Each SelectedRow In Items.ExchangePlansNodes.SelectedRows Do
			ChoiceValue.Add(ExchangePlansNodes.FindByID(SelectedRow).Node)
		EndDo;
		NotifyChoice(ChoiceValue);
	Else
		CurrentData = Items.ExchangePlansNodes.CurrentData;
		If CurrentData = Undefined Then
			ShowMessageBox(, NStr("ru = 'Узел не выбран.'; en = 'No nodes are selected.'; pl = 'Nie wybrano węzła.';de = 'Knoten ist nicht ausgewählt.';ro = 'Nodul nu este selectat.';tr = 'Ünite seçilmedi.'; es_ES = 'Nodo no está seleccionado.'"));
		Else
			NotifyChoice(CurrentData.Node);
		EndIf;
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure AddUsedExchangePlan(MetadataObject)
	
	If MetadataObject = Undefined
		OR NOT Metadata.ExchangePlans.Contains(MetadataObject) Then
		Return;
	EndIf;
	
	If Not AccessRight("Read", MetadataObject) Then
		Return;
	EndIf;
	
	ExchangePlan = Common.ObjectManagerByFullName(MetadataObject.FullName()).EmptyRef();
	
	// Filling nodes of the used exchange plans.
	If Parameters.SelectAllNodes Then
		NewRow = ExchangePlansNodes.Add();
		NewRow.ExchangePlan              = ExchangePlan;
		NewRow.ExchangePlanPresentation = MetadataObject.Synonym;
		NewRow.Node                    = ExchangePlan;
		NewRow.NodePresentation       = NStr("ru = '<Все информационные базы>'; en = '<All infobases>'; pl = '<Wszystkie bazy informacyjne>';de = '<Alle Infobases>';ro = '<Toate bazele de date> ';tr = '<Tüm bilgi tabanları>'; es_ES = '<Todas infobases>'");
	EndIf;
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	ExchangePlanTable.Ref,
	|	ExchangePlanTable.Presentation AS Presentation
	|FROM
	|	&ExchangePlanTable AS ExchangePlanTable
	|WHERE
	|	NOT ExchangePlanTable.ThisNode
	|
	|ORDER BY
	|	Presentation";
	Query.Text = StrReplace(Query.Text, "&ExchangePlanTable", MetadataObject.FullName());
	
	Selection = Query.Execute().Select();
	
	While Selection.Next() Do
		NewRow = ExchangePlansNodes.Add();
		NewRow.ExchangePlan              = ExchangePlan;
		NewRow.ExchangePlanPresentation = MetadataObject.Synonym;
		NewRow.Node                    = Selection.Ref;
		NewRow.NodePresentation       = Selection.Presentation;
	EndDo;
	
EndProcedure

#EndRegion
