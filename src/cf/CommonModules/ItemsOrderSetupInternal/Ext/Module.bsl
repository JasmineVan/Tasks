///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Private

// Returns a value of an additional order attribute for a new object.
//
// Parameters:
//  Information - Structure - information on object metadata.
//  Parent   - Ref    - a reference to the object parent.
//  Owner   - Ref    - a reference to the object owner.
//
// Returns:
//  Number - a value of an additional order attribute.
Function GetNewAdditionalOrderingAttributeValue(Information, Parent, Owner) Export
	
	SetPrivilegedMode(True);
	
	Query = New Query();
	
	QueryConditions = New Array;
	
	If Information.HasParent Then
		QueryConditions.Add("Table.Parent = &Parent");
		Query.SetParameter("Parent", Parent);
	EndIf;
	
	If Information.HasOwner Then
		QueryConditions.Add("Table.Owner = &Owner");
		Query.SetParameter("Owner", Owner);
	EndIf;
	
	AdditionalConditions = "TRUE";
	For Each Condition In QueryConditions Do
		AdditionalConditions = AdditionalConditions + " AND " + Condition;
	EndDo;
	
	QueryText =
	"SELECT TOP 1
	|	Table.AddlOrderingAttribute AS AddlOrderingAttribute
	|FROM
	|	&Table AS Table
	|WHERE
	|	&AdditionalConditions
	|
	|ORDER BY
	|	AddlOrderingAttribute DESC";
	
	QueryText = StrReplace(QueryText, "&Table", Information.FullName);
	QueryText = StrReplace(QueryText, "&AdditionalConditions", AdditionalConditions);
	
	Query.Text = QueryText;
	
	Selection = Query.Execute().Select();
	Selection.Next();
	
	Return ?(Not ValueIsFilled(Selection.AddlOrderingAttribute), 1, Selection.AddlOrderingAttribute + 1);
	
EndFunction

Function CheckItemsOrdering(TableMetadata)
	If Not AccessRight("Update", TableMetadata) Then
		Return False;
	EndIf;
	
	SetPrivilegedMode(True);
	
	QueryText = 
	"SELECT
	|	&Owner AS Owner,
	|	&Parent AS Parent,
	|	Table.AddlOrderingAttribute AS AddlOrderingAttribute,
	|	1 AS Count,
	|	Table.Ref AS Ref
	|INTO AllItems
	|FROM
	|	&Table AS Table
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	AllItems.Owner,
	|	AllItems.Parent,
	|	AllItems.AddlOrderingAttribute,
	|	SUM(AllItems.Count) AS Count
	|INTO IndexStatistics
	|FROM
	|	AllItems AS AllItems
	|
	|GROUP BY
	|	AllItems.AddlOrderingAttribute,
	|	AllItems.Parent,
	|	AllItems.Owner
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	IndexStatistics.Owner,
	|	IndexStatistics.Parent,
	|	IndexStatistics.AddlOrderingAttribute
	|INTO Duplicates
	|FROM
	|	IndexStatistics AS IndexStatistics
	|WHERE
	|	IndexStatistics.Count > 1
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	AllItems.Ref AS Ref
	|FROM
	|	AllItems AS AllItems
	|		INNER JOIN Duplicates AS Duplicates
	|		ON AllItems.AddlOrderingAttribute = Duplicates.AddlOrderingAttribute
	|			AND AllItems.Parent = Duplicates.Parent
	|			AND AllItems.Owner = Duplicates.Owner
	|
	|UNION ALL
	|
	|SELECT
	|	AllItems.Ref
	|FROM
	|	AllItems AS AllItems
	|WHERE
	|	AllItems.AddlOrderingAttribute = 0";
	
	Information = ItemOrderSetup.GetInformationForMoving(TableMetadata);
	
	QueryText = StrReplace(QueryText, "&Table", Information.FullName);
	
	ParentField = "Parent";
	If Not Information.HasParent Then
		ParentField = "1";
	EndIf;
	QueryText = StrReplace(QueryText, "&Parent", ParentField);
	
	OwnerField = "Owner";
	If Not Information.HasOwner Then
		OwnerField = "1";
	EndIf;
	QueryText = StrReplace(QueryText, "&Owner", OwnerField);
	
	Query = New Query(QueryText);
	QueryResult = Query.Execute();
	If QueryResult.IsEmpty() Then
		Return False;
	EndIf;
	
	Selection = QueryResult.Select();
	While Selection.Next() Do
		Object = Selection.Ref.GetObject();
		Object.AddlOrderingAttribute = 0;
		Try
			Object.Write();
		Except
			Continue;
		EndTry;
	EndDo;
	
	Return True;
	
EndFunction

Function MoveItem(ItemList, CurrentItemRef, Direction) Export
	
	AccessParameters = AccessParameters("Update", CurrentItemRef.Metadata(), "Ref");
	If Not AccessParameters.Accessibility Then
		Return NStr("ru = 'Недостаточно прав для изменения порядка элементов.'; en = 'You are not authorized to change the item sequence'; pl = 'Nie masz wystarczających uprawnień, aby zmienić kolejność elementów.';de = 'Unzureichende Rechte, um die Reihenfolge der Artikel zu ändern.';ro = 'Drepturile insuficiente pentru modificarea ordinii elementelor.';tr = 'Öğe sırasını değiştirmek için yetersiz haklar.'; es_ES = 'Insuficientes derechos para cambiar el orden de artículos.'");
	EndIf;
	
	Information = ItemOrderSetup.GetInformationForMoving(CurrentItemRef.Metadata());
	DataCompositionSettings = ItemList.GetPerformingDataCompositionSettings();
	
	// For hierarchical catalogs, you can set filter by parent. If this filter is not set, the display 
	// method must be hierarchical or as a tree.
	RepresentedAsList = ItemList.Representation = TableRepresentation.List;
	If Information.HasParent AND RepresentedAsList AND Not ListContainsFilterByParent(DataCompositionSettings) Then
		Return NStr("ru = 'Для изменения порядка элементов необходимо установить режим просмотра ""Дерево"" или ""Иерархический список"".'; en = 'To be able to change the item sequence, set the view mode to Tree or Hierarchical list.'; pl = 'Aby zmienić kolejność elementów, ustaw tryb wyświetlania ""Drzewo"" lub ""Lista hierarchiczna"".';de = 'Um die Objektfolge zu ändern, stellen Sie den Ansichtsmodus ""Baum"" oder ""Hierarchische Liste"" ein.';ro = 'Pentru a modifica ordinea elementelor, setați modul de vizualizare ""Arbore"" sau ""Listă ierarhică"".';tr = 'Öğe sırasını değiştirmek için ""Ağaç"" veya ""Hiyerarşik liste"" görünüm modunu ayarlayın.'; es_ES = 'Para cambiar la secuencia de artículos, establecer el modo de vista ""Árbol"" o ""Lista jerárquica"".'");
	EndIf;
	
	// For subordinate catalogs, filter by owner is to be set.
	If Information.HasOwner AND Not ListContainsFilterByOwner(DataCompositionSettings) Then
		Return NStr("ru = 'Для изменения порядка элементов необходимо установить отбор по полю ""Владелец"".'; en = 'To be able to change the item sequence, filter the list by the Owner field.'; pl = 'Aby zmienić kolejność towaru, należy ustawić filtr wg pola ""Właściciel"".';de = 'Um die Objektfolge zu ändern, legen Sie den Filter nach dem Feld ""Besitzer"" fest.';ro = 'Pentru a modifica ordinea elementelor, setați filtrul după câmpul ""Titular"".';tr = 'Öğe sırasını değiştirmek için filtreyi ""Sahip"" alanına göre ayarlayın.'; es_ES = 'Para cambiar la secuencia de artículos, establecer el filtro por el campo ""Propietario"".'");
	EndIf;
	
	// Checking the Use flag of the AdditionalOrderingAttribute attribute for the item to be moved.
	If Information.HasGroups Then
		IsFolder = Common.ObjectAttributeValue(CurrentItemRef, "IsFolder");
		If IsFolder AND Not Information.ForGroups Or Not IsFolder AND Not Information.ForItems Then
			Return NStr("ru = 'Выбранный элемент нельзя перемещать.'; en = 'Cannot move the selected item.'; pl = 'Wybrana pozycja nie może być przeniesiona.';de = 'Der ausgewählte Artikel kann nicht übertragen werden.';ro = 'Elementul selectat nu poate fi transferat.';tr = 'Seçilen öğe aktarılamaz.'; es_ES = 'El artículos seleccionado no puede transferirse.'");
		EndIf;
	EndIf;
	
	CheckItemsOrdering(CurrentItemRef.Metadata());
	
	DataCompositionSettings = ItemList.GetPerformingDataCompositionSettings();
	ErrorText = CheckSortingInList(DataCompositionSettings);
	If Not IsBlankString(ErrorText) Then
		Return ErrorText;
	EndIf;
	
	DataCompositionGroup = DataCompositionSettings.Structure[0];
	
	DataCompositionField = DataCompositionGroup.Selection.SelectionAvailableFields.Items.Find("Ref").Field;
	HasFieldRef = False;
	For Each SelectedDataCompositionField In DataCompositionGroup.Selection.Items Do
		If SelectedDataCompositionField.Field = DataCompositionField Then
			HasFieldRef = True;
			Break;
		EndIf;
	EndDo;
	If Not HasFieldRef Then
		SelectedDataCompositionField = DataCompositionGroup.Selection.Items.Add(Type("DataCompositionSelectedField"));
		SelectedDataCompositionField.Use = True;
		SelectedDataCompositionField.Field = DataCompositionField;
	EndIf;
	
	DataCompositionSchema = ItemList.GetPerformingDataCompositionScheme();
	ValuesTree = ExecuteQuery(DataCompositionSchema, DataCompositionSettings);
	If ValuesTree = Undefined Then
		Return NStr("ru = 'Для изменения порядка элементов необходимо сбросить настройки списка
			|(Меню Еще - Установить стандартные настройки).'; 
			|en = 'To change the item sequence, reset the list settings
			| (Menu More - Use standard settings).'; 
			|pl = 'W celu zmiany porządku elementów należy zresetować ustawienia listy
			|(Menu Jeszcze - Ustaw ustawienia standardowe).';
			|de = 'Um die Reihenfolge der Elemente zu ändern, müssen Sie die Listeneinstellungen zurücksetzen
			|(Menü Mehr- Standardeinstellungen festlegen).';
			|ro = 'Pentru a modifica ordinea elementelor, resetați setările listei
			|(Meniul Mai multe - Instalare setările standard).';
			|tr = 'Öğe düzenini değiştirmek için liste ayarları sıfırlanmalıdır
			|(Menü Daha fazla - Standart ayarları yap).'; 
			|es_ES = 'Para cambiar el orden de los elementos es necesario restablecer los ajustes de la lista
			|(Menú Más - Establecer los ajustes estándares).'");
	EndIf;
	
	ValueTreeRow = ValuesTree.Rows.Find(CurrentItemRef, "Ref", True);
	Parent = ValueTreeRow.Parent;
	If Parent = Undefined Then
		Parent = ValuesTree;
	EndIf;
	
	CurrentItemIndex = Parent.Rows.IndexOf(ValueTreeRow);
	NeighborItemIndex = CurrentItemIndex;
	If Direction = "Up" Then
		If CurrentItemIndex > 0 Then
			NeighborItemIndex = CurrentItemIndex - 1;
		EndIf;
	Else // Down
		If CurrentItemIndex < Parent.Rows.Count() - 1 Then
			NeighborItemIndex = CurrentItemIndex + 1;
		EndIf;
	EndIf;
	
	If CurrentItemIndex <> NeighborItemIndex Then
		NeighborRow = Parent.Rows.Get(NeighborItemIndex);
		NeighborItemRef = NeighborRow.Ref;
		
		Items = New Array;
		Items.Add(CurrentItemRef);
		Items.Add(NeighborItemRef);
		
		SwapItems(CurrentItemRef, NeighborItemRef);
	EndIf;
	
	Return "";
EndFunction

Function ExecuteQuery(DataCompositionSchema, DataCompositionSettings)
	
	Result = New ValueTree;
	TemplateComposer = New DataCompositionTemplateComposer;
	Try
		DataCompositionTemplate = TemplateComposer.Execute(DataCompositionSchema,
			DataCompositionSettings, , , Type("DataCompositionValueCollectionTemplateGenerator"));
	Except
		Return Undefined;
	EndTry;
	
	DataCompositionProcessor = New DataCompositionProcessor;
	DataCompositionProcessor.Initialize(DataCompositionTemplate);
	
	OutputProcessor = New DataCompositionResultValueCollectionOutputProcessor;
	OutputProcessor.SetObject(Result);
	OutputProcessor.Output(DataCompositionProcessor);
	
	Return Result;
	
EndFunction

Procedure SwapItems(FirstItemRef, SecondItemRef)
	
	BeginTransaction();
	Try
		LockDataForEdit(FirstItemRef);
		LockDataForEdit(SecondItemRef);
		
		FirstItemObject = FirstItemRef.GetObject();
		SecondItemObject = SecondItemRef.GetObject();
		
		FirstItemIndex = FirstItemObject.AddlOrderingAttribute;
		SecondItemIndex = SecondItemObject.AddlOrderingAttribute;
		
		FirstItemObject.AddlOrderingAttribute = SecondItemIndex;
		SecondItemObject.AddlOrderingAttribute = FirstItemIndex;
	
		FirstItemObject.Write();
		SecondItemObject.Write();
		
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;
	
EndProcedure

Function CheckSortingInList(DataCompositionSettings)
	
	OrderItems = DataCompositionSettings.Order.Items;
	
	AdditionalOrderFields = New Array;
	AdditionalOrderFields.Add(New DataCompositionField("AdditionalOrderField1"));
	AdditionalOrderFields.Add(New DataCompositionField("AdditionalOrderField2"));
	AdditionalOrderFields.Add(New DataCompositionField("AdditionalOrderField3"));
	
	Item = Undefined;
	For Each OrderItem In OrderItems Do
		If OrderItem.Use Then
			Item = OrderItem;
			If AdditionalOrderFields.Find(Item.Field) <> Undefined Then
				Continue;
			EndIf;
			Break;
		EndIf;
	EndDo;
	
	SortingCorrect = False;
	If Item <> Undefined AND TypeOf(Item) = Type("DataCompositionOrderItem") Then
		If Item.OrderType = DataCompositionSortDirection.Asc Then
			AttributeField = New DataCompositionField("AddlOrderingAttribute");
			If Item.Field = AttributeField Then
				SortingCorrect = True;
			EndIf;
		EndIf;
	EndIf;
	
	AddlOrderingAttribute = DataCompositionSettings.Order.OrderAvailableFields.FindField(New DataCompositionField("AddlOrderingAttribute"));
	If Not SortingCorrect Then
		Return StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = 'Для перемещения элементов необходимо настроить сортировку
			|в списке по полю ""%1"" (по возрастанию)'; 
			|en = 'To transfer items, set up sorting in the 
			|list by the ""%1"" field (ascending)'; 
			|pl = 'W celu przemieszczenia elementów należy ustawić sortowanie
			|w liście wg pola ""%1"" (rosnąco)';
			|de = 'Um Elemente zu verschieben, sollten Sie eine Sortierung
			|in der Liste nach dem Feld ""%1"" einrichten (in aufsteigender Reihenfolge)';
			|ro = 'Pentru deplasarea elementelor, setați sortarea
			|în listă după câmpul ""%1"" (ascendent)';
			|tr = 'Öğeleri taşımak için liste "
" alanına göre (küçükten büyüğe doğru) %1sıralanmalıdır'; 
			|es_ES = 'Para trasladar los elementos es necesario ajustar la clasificación 
			|en la lista por el campo ""%1"" (en orden ascendente)'"), AddlOrderingAttribute.Title);
	EndIf;
	
	Return "";
	
EndFunction

Function ListContainsFilterByOwner(DataCompositionSettings)
	
	RequiredFilters = New Array;
	RequiredFilters.Add(New DataCompositionField("Owner"));
	RequiredFilters.Add(New DataCompositionField("Owner"));
	
	Return HasRequiredFilter(DataCompositionSettings.Filter, RequiredFilters);
	
EndFunction

Function ListContainsFilterByParent(DataCompositionSettings)
	
	RequiredFilters = New Array;
	RequiredFilters.Add(New DataCompositionField("Parent"));
	RequiredFilters.Add(New DataCompositionField("Parent"));
	
	Return HasRequiredFilter(DataCompositionSettings.Filter, RequiredFilters);
	
EndFunction

Function HasRequiredFilter(FiltersCollection, RequiredFilters)
	
	For Each Filter In FiltersCollection.Items Do
		If TypeOf(Filter) = Type("DataCompositionFilterItemGroup") Then
			FilterFound = HasRequiredFilter(Filter, RequiredFilters);
		Else
			FilterFound = RequiredFilters.Find(Filter.LeftValue) <> Undefined;
		EndIf;
		
		If FilterFound Then
			Return True;
		EndIf;
	EndDo;
	
	Return False;
	
EndFunction


#EndRegion
