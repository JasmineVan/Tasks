///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Variables

&AtClient
Var NodesToExpand;
&AtClient
Var CountOfNodesToExpand;

#EndRegion

#Region EventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Not Parameters.Property("SettingsComposer", SettingsComposer) Then
		Raise NStr("ru = 'Не передан служебный параметр ""КомпоновщикНастроек"".'; en = 'SettingsComposer service parameter has not been passed.'; pl = 'Nie przekazano parametru serwisowego SettingsLinker.';de = 'Der SettingsLinker-Serviceparameter ist nicht bestanden.';ro = 'Parametrul serviciului ”SettingsLinker” nu este transmis.';tr = 'SettingsLinker hizmet parametresi iletilmedi.'; es_ES = 'El parámetro de servicio SettingsLinker no está pasado.'");
	EndIf;
	If Not Parameters.Property("Mode", Mode) Then
		Raise NStr("ru = 'Не передан служебный параметр ""Режим"".'; en = 'Mode service parameter has not been passed.'; pl = 'Nie przesłano parametru serwisowego ""Tryb"".';de = 'Der Serviceparameter ""Modus"" wird nicht übertragen.';ro = 'Parametrul de service ""Mod"" nu este transferat.';tr = 'Servis parametresi ""Mod"" aktarılmıyor.'; es_ES = 'Parámetro de servicio ""Modo"" no se ha transferido.'");
	EndIf;
	If Mode = "GroupComposition" Or Mode = "OptionStructure" Then
		TableName = "GroupFields";
	ElsIf Mode = "Filters" Or Mode = "SelectedFields" Or Mode = "Sort" Or Mode = "GroupFields" Then
		TableName = Mode;
	Else
		Raise StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = 'Некорректное значение параметра ""Режим"": ""%1"".'; en = 'Mode parameter contains invalid value: %1.'; pl = 'Niepoprawna wartość parametru ""Tryb"": ""%1"".';de = 'Falscher Wert des Parameters ""Modus"": ""%1"".';ro = 'Valoare incorectă a parametrului ""Mod"": ""%1"".';tr = '""Mode"" parametresinin yanlış değeri: ""%1"".'; es_ES = 'Valor incorrecto del parámetro ""Modo"": ""%1"".'"), String(Mode));
	EndIf;
	If Not Parameters.Property("ReportSettings", ReportSettings) Then
		Raise NStr("ru = 'Не передан служебный параметр ""НастройкиОтчета"".'; en = 'ReportSettings service parameter has not been passed.'; pl = 'Nie przekazano parametru serwisowego ReportSettings.';de = 'Serviceparameter ""ReportSettings"" ist nicht bestanden.';ro = 'Parametrul serviciului ""ReportSettings"" nu este transmis.';tr = 'Servis parametresi ReportSettings geçmedi.'; es_ES = 'Parámetro de servicio ReportSettings no está pasado.'");
	EndIf;
	If Parameters.Property("SettingsStructureItemID", SettingsStructureItemID)
		AND SettingsStructureItemID <> Undefined Then
		DCCurrentNode = SettingsComposer.Settings.GetObjectByID(SettingsStructureItemID);
		If TypeOf(DCCurrentNode) = Type("DataCompositionTableStructureItemCollection")
			Or TypeOf(DCCurrentNode) = Type("DataCompositionChartStructureItemCollection")
			Or TypeOf(DCCurrentNode) = Type("DataCompositionTable")
			Or TypeOf(DCCurrentNode) = Type("DataCompositionChart") Then
			SettingsStructureItemID = Undefined;
		EndIf;
	EndIf;
	
	If TableName = "GroupFields" Then
		TreeItems = GroupFields.GetItems();
		GroupFieldsExpandRow(DCTable(ThisObject), TreeItems);
		If Mode = "OptionStructure" Then
			TreeRow = TreeItems.Add();
			TreeRow.Presentation  = NStr("ru = '<Детальные записи>'; en = '<Detailed records>'; pl = '<Zapisy szczegółowe>';de = '<Detaillierte Datensätze>';ro = '<Înregistrări detaliate>';tr = '<Detailed records>'; es_ES = '<Registros detallados>'");
			TreeRow.PictureIndex = ReportsClientServer.PictureIndex("Item", "Predefined");
		EndIf;
	EndIf;
	
	DCField = Undefined;
	Parameters.Property("DCField", DCField);
	If DCField <> Undefined Then
		DCTable = DCTable(ThisObject);
		AvailableDCField = DCTable.FindField(DCField);
		If AvailableDCField <> Undefined Then
			Items[TableName + "Table"].CurrentRow = DCTable.GetIDByObject(AvailableDCField);
		EndIf;
	EndIf;
	
	Items.Pages.CurrentPage = Items[TableName + "Page"];
	
	Source = New DataCompositionAvailableSettingsSource(ReportSettings.SchemaURL);
	SettingsComposer.Initialize(Source);
	
	CloseOnChoice = False;
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	NodesToExpand = New Array;
	CountOfNodesToExpand = 0;
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure Select(Command)
	SelectAndClose();
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersFiltersTable

&AtClient
Procedure FiltersTableChoice(Item, RowSelected, Field, StandardProcessing)
	StandardProcessing = False;
	SelectAndClose();
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersSelectedFieldsTable

&AtClient
Procedure SelectedFieldsTableChoice(Item, RowSelected, Field, StandardProcessing)
	StandardProcessing = False;
	SelectAndClose();
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersSortingTable

&AtClient
Procedure SortingTableChoice(Item, RowSelected, Field, StandardProcessing)
	StandardProcessing = False;
	SelectAndClose();
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersGroupFields

&AtClient
Procedure GroupFieldsTableBeforeExpand(Item, RowID, Cancel)
	If CountOfNodesToExpand > 10 Then
		Cancel = True;
		Return;
	EndIf;
	TreeRow = GroupFields.FindByID(RowID);
	If TreeRow = Undefined Then
		Cancel = True;
		Return;
	EndIf;
	If TreeRow.ReadNestedItems Then // Not all nodes have to be expanded.
		CountOfNodesToExpand = CountOfNodesToExpand + 1;
		NodesToExpand.Add(RowID);
		AttachIdleHandler("ExpandGroupFieldLines", 0.1, True); // Protection against hanging by Ctrl_Shift_+.
		TreeRow.GetItems().Clear(); // So that the user does not see intermediate effects.
	EndIf;
EndProcedure

&AtClient
Procedure GroupFieldsTableChoice(Item, RowSelected, Field, StandardProcessing)
	StandardProcessing = False;
	SelectAndClose();
EndProcedure

#EndRegion

#Region Private

////////////////////////////////////////////////////////////////////////////////
// Client

&AtClient
Procedure SelectAndClose()
	TableItem = Items[TableName + "Table"];
	If TableName = "GroupFields" Then
		TreeRow = TableItem.CurrentData;
		If TreeRow = Undefined Then
			Return;
		EndIf;
		DCID = TreeRow.DCID;
	Else
		DCID = TableItem.CurrentRow;
	EndIf;
	If DCID = Undefined Then
		If TableName = "GroupFields" Then
			AvailableDCField = "<>";
		Else
			Return;
		EndIf;
	Else
		AvailableDCField = DCTable(ThisObject).GetObjectByID(DCID);
		If AvailableDCField = Undefined Then
			Return;
		EndIf;
	EndIf;
	If TypeOf(AvailableDCField) = Type("DataCompositionAvailableField")
		Or TypeOf(AvailableDCField) = Type("DataCompositionFilterAvailableField") Then
		If AvailableDCField.Folder Then
			ShowMessageBox(, NStr("ru = 'Выберите элемент'; en = 'Select item'; pl = 'Wybierz element';de = 'Wählen Sie ein Element aus';ro = 'Selectați elementul';tr = 'Öğe seçin'; es_ES = 'Seleccione un elemento'"));
			Return;
		EndIf;
	EndIf;
	NotifyChoice(AvailableDCField);
	Close(AvailableDCField);
EndProcedure

&AtClient
Procedure ExpandGroupFieldLines()
	ExpandServerCallGroupFieldsRows(NodesToExpand);
	NodesToExpand.Clear();
	CountOfNodesToExpand = 0;
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Client, Server

&AtClientAtServerNoContext
Function DCTable(ThisObject)
	If ThisObject.TableName = "Filters" Then
		Return ThisObject.SettingsComposer.Settings.Filter.FilterAvailableFields;
	ElsIf ThisObject.TableName = "SelectedFields" Then
		Return ThisObject.SettingsComposer.Settings.Selection.SelectionAvailableFields;
	ElsIf ThisObject.TableName = "Sort" Then
		Return ThisObject.SettingsComposer.Settings.Order.OrderAvailableFields;
	ElsIf ThisObject.TableName = "GroupFields" Then
		If ThisObject.SettingsStructureItemID = Undefined Then
			DCCurrentNode = ThisObject.SettingsComposer.Settings;
		Else
			DCCurrentNode = ThisObject.SettingsComposer.Settings.GetObjectByID(ThisObject.SettingsStructureItemID);
		EndIf;
		If TypeOf(DCCurrentNode) = Type("DataCompositionSettings") Then
			Return DCCurrentNode.GroupAvailableFields;
		Else
			Return DCCurrentNode.GroupFields.GroupFieldsAvailableFields;
		EndIf;
	EndIf;
EndFunction

&AtClientAtServerNoContext
Procedure ExpandClientServerGroupFieldsRows(DCTable, GroupFields, NodesToExpand)
	Total = 0;
	For Each RowID In NodesToExpand Do
		TreeRow = GroupFields.FindByID(RowID);
		If TreeRow = Undefined Then
			Continue;
		EndIf;
		If Not TreeRow.ReadNestedItems Then
			Continue;
		EndIf;
		TreeRow.ReadNestedItems = False;
		AvailableDCField = DCTable.GetObjectByID(TreeRow.DCID);
		TreeRows = TreeRow.GetItems();
		TreeRows.Clear();
		GroupFieldsExpandRow(DCTable, TreeRows, AvailableDCField, Total);
	EndDo;
EndProcedure

&AtClientAtServerNoContext
Procedure GroupFieldsExpandRow(DCTable, TreeRows, AvailableDCFieldParent = Undefined, Total = 0)
	If AvailableDCFieldParent = Undefined Then
		AvailableDCFieldParent = DCTable;
		Prefix = "";
	Else
		Prefix = AvailableDCFieldParent.Title + ".";
	EndIf;
	
	Total = Total + AvailableDCFieldParent.Items.Count();
	CalculateCount = (Total <= 100);
	For Each AvailableDCField In AvailableDCFieldParent.Items Do
		If TypeOf(AvailableDCField) = Type("DataCompositionAvailableField") Then
			TreeRow = TreeRows.Add();
			TreeRow.Presentation = StrReplace(AvailableDCField.Title, Prefix, "");
			TreeRow.DCID = DCTable.GetIDByObject(AvailableDCField);
			If AvailableDCField.Table Then
				Type = "Table";
			ElsIf AvailableDCField.Resource Then
				Type = "Resource";
			ElsIf AvailableDCField.Folder Then
				Type = "Folder";
			Else
				Type = "Item";
			EndIf;
			TreeRow.PictureIndex = ReportsClientServer.PictureIndex(Type);
			
			// Collecting the "AvailableDCField.Items" collection sometimes makes an implicit server call.
			If CalculateCount Then
				TreeRow.ReadNestedItems = AvailableDCField.Items.Count() > 0;
			Else
				TreeRow.ReadNestedItems = True;
			EndIf;
			If TreeRow.ReadNestedItems Then
				TreeRow.GetItems().Add().Presentation = "...";
			EndIf;
		EndIf;
	EndDo;
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Server call, Server

&AtServer
Procedure ExpandServerCallGroupFieldsRows(NodesToExpand)
	ExpandClientServerGroupFieldsRows(DCTable(ThisObject), GroupFields, NodesToExpand);
EndProcedure

#EndRegion