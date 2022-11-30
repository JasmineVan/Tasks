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
	
	// Checking whether the form is opened from 1C:Enterprise script.
	If Not Parameters.Property("ExchangeMessageFileName") Then
		Raise NStr("ru = 'Обработка не предназначена для непосредственного использования.'; en = 'The data processor cannot be opened manually.'; pl = 'Opracowanie nie jest przeznaczone do bezpośredniego użycia.';de = 'Der Datenprozessor ist nicht für den direkten Gebrauch bestimmt.';ro = 'Procesarea nu este destinată pentru utilizare nemijlocită.';tr = 'Veri işlemcisi doğrudan kullanım için uygun değildir.'; es_ES = 'Procesador de datos no está destinado al uso directo.'");
	EndIf;
	
	PerformDataMapping = True;
	ExecuteDataImport      = True;
	
	If Parameters.Property("PerformDataMapping") Then
		PerformDataMapping = Parameters.PerformDataMapping;
	EndIf;
	
	If Parameters.Property("ExecuteDataImport") Then
		ExecuteDataImport = Parameters.ExecuteDataImport;
	EndIf;
	
	// Initializing the data processor with the passed parameters.
	FillPropertyValues(Object, Parameters);
	
	// Calling a constructor of the current data processor instance.
	DataProcessorObject = FormAttributeToValue("Object");
	DataProcessorObject.Designer();
	ValueToFormAttribute(DataProcessorObject, "Object");
	
	// Removing possible search fields and attributes with strings of unlimited length from the list.
	MetadataObjectType = Metadata.FindByType(Type(Object.DestinationTypeString));
	
	If MetadataObjectType <> Undefined Then
		
		RowIndex = Object.TableFieldsList.Count() - 1;
		
		While RowIndex >= 0 Do
			
			Item = Object.TableFieldsList[RowIndex];
			RowIndex = RowIndex - 1;
			MetadataObjectAttribute = MetadataObjectType.Attributes.Find(Item.Value);
			
			If MetadataObjectAttribute <> Undefined
				AND MetadataObjectAttribute.Type = New TypeDescription("String",, New StringQualifiers(0)) Then
				Object.TableFieldsList.Delete(Item);
				Continue;
			EndIf;
			
		EndDo;
	EndIf;
	
	// List of filters by status:
	//
	//     MappingStatus - Number:
	//          0 - mapping based on information register data
	//         -1 - an unmapped source object
	//         +1 - an unmapped destination object
	//          3 - mapping available but not approved.
	//
	//     MappingStatusAdditional - Number:
	//         1 - unmapped objects
	//         0 - mapped objects.
	
	MappingStatusFilterOptions = New Structure;
	
	// Filling filter list
	ChoiceList = Items.FilterByMappingStatus.ChoiceList;;
	
	NewListItem = ChoiceList.Add("AllObjects", NStr("ru='Все данные'; en = 'All data'; pl = 'Wszystkie dane';de = 'Alle Daten';ro = 'Toate datele';tr = 'Tüm veriler'; es_ES = 'Todos datos'"));
	MappingStatusFilterOptions.Insert(NewListItem.Value, New FixedStructure);
	
	NewListItem = ChoiceList.Add("UnapprovedMappedObjects", NStr("ru='Изменения'; en = 'Changes'; pl = 'Zmiany';de = 'Änderungen';ro = 'Modificări';tr = 'Değişiklikler'; es_ES = 'Cambios'"));
	MappingStatusFilterOptions.Insert(NewListItem.Value, 
						New FixedStructure("MappingStatus",  3));
	
	NewListItem = ChoiceList.Add("MappedObjects", NStr("ru='Сопоставленные данные'; en = 'Mapped data'; pl = 'Zmapowane dane';de = 'Zugeordnete Daten';ro = 'Confruntarea datelor';tr = 'Eşlenen veriler'; es_ES = 'Datos mapeados'"));
	MappingStatusFilterOptions.Insert(NewListItem.Value, 
						New FixedStructure("MappingStatusAdditional", 0));
	
	NewListItem = ChoiceList.Add("UnmappedObjects", NStr("ru='Несопоставленные данные'; en = 'Unmapped data'; pl = 'Odmapowane dane';de = 'Nicht zugeordnete Daten';ro = 'Date neimprimate';tr = 'Eşlenmeyen veriler'; es_ES = 'Datos no mapeados'"));
	MappingStatusFilterOptions.Insert(NewListItem.Value, 
						New FixedStructure("MappingStatusAdditional", 1));
	
	NewListItem = ChoiceList.Add("UnmappedDestinationObjects", NStr("ru='Несопоставленные данные этой базы'; en = 'Unmapped data (this infobase)'; pl = 'Odmapowane dane tej bazy';de = 'Nicht zugeordnete Daten dieser Basis';ro = 'Datele neconfruntate din această bază';tr = 'Bu tabanın eşlenmeyen verileri'; es_ES = 'Datos no mapeados de esta base'"));
	MappingStatusFilterOptions.Insert(NewListItem.Value, 
						New FixedStructure("MappingStatus",  1));
	
	NewListItem = ChoiceList.Add("UnmappedSourceObjects", NStr("ru='Несопоставленные данные второй базы'; en = 'Unmapped data (second infobase)'; pl = 'Odmapowane dane drugiej bazy';de = 'Nicht zugeordnete zweite Basisdaten';ro = 'Datele neconfruntate din baza a doua';tr = 'Eşlenmeyen ikinci veritabanı'; es_ES = 'Datos no mapeados de la segunda base'"));
	MappingStatusFilterOptions.Insert(NewListItem.Value, 
						New FixedStructure("MappingStatus", -1));
	
	// Defaults
	FilterByMappingStatus = "UnmappedObjects";
		
	// Setting the form title.
	Synonym = Undefined;
	Parameters.Property("Synonym", Synonym);
	If IsBlankString(Synonym) Then
		DataPresentation = String(Metadata.FindByType(Type(Object.DestinationTypeString)));
	Else
		DataPresentation = Synonym;
	EndIf;
	Title = NStr("ru = 'Сопоставление данных ""[DataPresentation]""'; en = 'Data mapping ""[DataPresentation]""'; pl = 'Mapowanie danych ""[DataPresentation]""';de = 'Zuordnen von Daten ""[DataPresentation]""';ro = 'Confruntarea datelor ""[DataPresentation]""';tr = '""[DataPresentation]"" verinin eşleşmesi'; es_ES = 'Comparación de datos ""[DataPresentation]""'");
	Title = StrReplace(Title, "[DataPresentation]", DataPresentation);
	
	// Setting the form item visibility according to option values.
	Items.LinksGroup.Visible                                    = PerformDataMapping;
	Items.RunAutoMapping.Visible           = PerformDataMapping;
	Items.MappingDigestInfo.Visible               = PerformDataMapping;
	Items.MappingTableContextMenuLinksGroup.Visible = PerformDataMapping;
	
	Items.RunDataImport.Visible = ExecuteDataImport;
	
	CurrentApplicationDescription = DataExchangeCached.ThisNodeDescription(Object.InfobaseNode);
	CurrentApplicationDescription = ?(IsBlankString(CurrentApplicationDescription), NStr("ru = 'Эта программа'; en = 'This application'; pl = 'Ta aplikacja';de = 'Diese Anwendung';ro = 'Această aplicație';tr = 'Bu uygulama'; es_ES = 'Esta aplicación'"), CurrentApplicationDescription);
	
	SecondApplicationDescription = Common.ObjectAttributeValue(Object.InfobaseNode, "Description");
	SecondApplicationDescription = ?(IsBlankString(SecondApplicationDescription), NStr("ru = 'Вторая программа'; en = 'Second application'; pl = 'Druga aplikacja';de = 'Die zweite Anwendung';ro = 'Al doilea program';tr = 'Ikinci uygulama'; es_ES = 'La segunda aplicación'"), SecondApplicationDescription);
	
	Items.CurrentApplicationData.Title = CurrentApplicationDescription;
	Items.SecondApplicationData.Title = SecondApplicationDescription;
	
	Items.Explanation.Title = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("ru = 'Для сопоставления данных ""%1""
		|с данными ""%2"" воспользуйтесь командой ""Сопоставить автоматически..."".
		|Оставшиеся несопоставленные данные можно связать друг с другом вручную.'; 
		|en = 'To map %1 data
		|to%2 data, click ""Map automatically"".
		|Then you can map the remaining data manually.'; 
		|pl = 'Aby dopasować dane
		|""%1"" do danych ""%2"", użyj polecenia ""Dopasuj automatycznie""..."".
		|Pozostałe niedopasowane dane można połączyć ręcznie.';
		|de = 'Um Daten
		|""%1"" mit Daten ""%2"" zu vergleichen, verwenden Sie den Befehl ""Automatisch anpassen""... "".
		|Verbleibende nicht übereinstimmende Daten können manuell miteinander verknüpft werden.';
		|ro = 'Pentru compararea datelor ""%1""
		|cu datele ""%2"" utilizați comanda ""Confuntare automată... "".
		|Datele rămase neconfruntate pot fi legate între ele în mod manual.';
		|tr = '"
"  
		|verilerini ""%1"" verileriyle eşleştirmek için, ""Otomatik olarak eşleştir...""  komutunu kullanın. %2Kalan eşsiz veriler birbiriyle manuel olarak  bağlanabilir.'; 
		|es_ES = 'Para emparejar los datos
		|""%1"" con los datos ""%2"", utilizar el comando ""Emparejar automáticamente""..."".
		|Datos no mapeados restantes pueden vincularse unos con otros manualmente.'"),
		CurrentApplicationDescription, SecondApplicationDescription);
	
	ObjectMappingScenario();
	
	ApplyUnapprovedRecordsTable = False;
	ApplyAutomaticMappingResult = False;
	AutoMappedObjectsTableAddress = "";
	WriteAndClose = False;
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	ShowWarningOnFormClose = True;
	
	// Setting a flag that shows whether the form has been modified.
	AttachIdleHandler("SetFormModified", 2);
	
	UpdateMappingTable();
EndProcedure

&AtClient
Procedure BeforeClose(Cancel, Exit, WarningText, StandardProcessing)
	
	If WriteAndClose Then
		Return;
	EndIf;
	
	If Object.UnapprovedMappingTable.Count() = 0 Then
		// Everything mapped
		Return;
	EndIf;
	
	If ShowWarningOnFormClose = True Then
		Notification = New NotifyDescription("BeforeCloseCompletion", ThisObject);
		
		CommonClient.ShowFormClosingConfirmation(Notification, Cancel, Exit);
		
		Return;
	EndIf;
	
	If Exit Then
		Return;
	EndIf;
		
	BeforeCloseContinuation();
	
EndProcedure

&AtClient
Procedure BeforeCloseCompletion(Val QuestionResult = Undefined, Val AdditionalParameters = Undefined) Export
	// This procedure is called if the answer is yes.
	// Closing the form and saving data.
	WriteAndClose(Undefined);
EndProcedure

&AtClient
Procedure BeforeCloseContinuation()
	WriteAndClose = True;
	ShowWarningOnFormClose = True;
	UpdateMappingTable();
EndProcedure

&AtClient
Procedure OnClose(Exit)
	
	If Exit Then
		Return;
	EndIf;
	
	NotificationParameters = New Structure;
	NotificationParameters.Insert("UniqueKey",       Parameters.Key);
	NotificationParameters.Insert("DataImportedSuccessfully", Object.DataImportedSuccessfully);
	
	Notify("ObjectMappingFormClosing", NotificationParameters);
	
EndProcedure

&AtClient
Procedure ChoiceProcessing(SelectedValue, ChoiceSource)
	
	If Upper(ChoiceSource.FormName) = Upper("DataProcessor.InfobaseObjectMapping.Form.AutomaticMappingSetting") Then
		
		If TypeOf(SelectedValue) <> Type("ValueList") Then
			Return;
		EndIf;
		
		// Performing automatic object mapping.
		FormParameters = New Structure;
		FormParameters.Insert("DestinationTableName",                         Object.DestinationTableName);
		FormParameters.Insert("ExchangeMessageFileName",                     Object.ExchangeMessageFileName);
		FormParameters.Insert("SourceTableObjectTypeName",              Object.SourceTableObjectTypeName);
		FormParameters.Insert("SourceTypeString",                         Object.SourceTypeString);
		FormParameters.Insert("DestinationTypeString",                         Object.DestinationTypeString);
		FormParameters.Insert("DestinationTableFields",                        Object.DestinationTableFields);
		FormParameters.Insert("DestinationTableSearchFields",                  Object.DestinationTableSearchFields);
		FormParameters.Insert("InfobaseNode",                      Object.InfobaseNode);
		FormParameters.Insert("TableFieldsList",                          Object.TableFieldsList.Copy());
		FormParameters.Insert("UsedFieldsList",                     Object.UsedFieldsList.Copy());
		FormParameters.Insert("MappingFieldsList",                    SelectedValue.Copy());
		FormParameters.Insert("MaxUserFields", MaxUserFields());
		FormParameters.Insert("Title",                                   Title);
		
		FormParameters.Insert("UnapprovedMappingTableTempStorageAddress", PutUnapprovedMappingTableInTempStorage());
		
		// Opening the automatic object mapping form.
		OpenForm("DataProcessor.InfobaseObjectMapping.Form.AutoMappingResult", FormParameters, ThisObject,,,,,FormWindowOpeningMode.LockOwnerWindow);
		
	ElsIf Upper(ChoiceSource.FormName) = Upper("DataProcessor.InfobaseObjectMapping.Form.AutoMappingResult") Then
		
		If TypeOf(SelectedValue) = Type("String")
			AND Not IsBlankString(SelectedValue) Then
			
			ApplyAutomaticMappingResult = True;
			AutoMappedObjectsTableAddress = SelectedValue;
			
			UpdateMappingTable();
			
		EndIf;
		
	ElsIf Upper(ChoiceSource.FormName) = Upper("DataProcessor.InfobaseObjectMapping.Form.TableFieldSetup") Then
		
		If TypeOf(SelectedValue) <> Type("ValueList") Then
			Return;
		EndIf;
		
		Object.UsedFieldsList = SelectedValue.Copy();
		SetTableFieldVisible("MappingTable"); // Setting visibility and titles of the mapping table fields.
		
	ElsIf Upper(ChoiceSource.FormName) = Upper("DataProcessor.InfobaseObjectMapping.Form.MappingFieldTableSetup") Then
		
		If TypeOf(SelectedValue) <> Type("ValueList") Then
			Return;
		EndIf;
		
		Object.TableFieldsList = SelectedValue.Copy();
		
		FillListWithSelectedItems(Object.TableFieldsList, Object.UsedFieldsList);
		
		// Generating the sorting table.
		FillSortTable(Object.UsedFieldsList);
		
		// Updating the mapping table.
		UpdateMappingTable();
		
	ElsIf Upper(ChoiceSource.FormName) = Upper("DataProcessor.InfobaseObjectMapping.Form.SortingSetup") Then
		
		If TypeOf(SelectedValue) <> Type("FormDataCollection") Then
			Return;
		EndIf;
		
		Object.SortTable.Clear();
		
		// Filling the form collection with retrieved settings.
		For Each TableRow In SelectedValue Do
			FillPropertyValues(Object.SortTable.Add(), TableRow);
		EndDo;
		
		// Sorting mapping table.
		ExecuteTableSorting();
		
		// Updating tabular section filter
		SetTabularSectionFilter();
		
	ElsIf Upper(ChoiceSource.FormName) = Upper("DataProcessor.InfobaseObjectMapping.Form.MappingChoiceForm") Then
		
		If SelectedValue = Undefined Then
			Return; // Manual mapping is canceled.
		EndIf;
		
		BeginningRowID = Items.MappingTable.CurrentRow;
		
		// server call
		FoundRows = MappingTable.FindRows(New Structure("SerialNumber", SelectedValue));
		If FoundRows.Count() > 0 Then
			EndingRowID = FoundRows[0].GetID();
			// Processing retrieved mapping.
			AddUnapprovedMappingAtClient(BeginningRowID, EndingRowID);
		EndIf;
		
		// Switching to the mapping table.
		CurrentItem = Items.MappingTable;
		
	EndIf;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure FilterByMappingStatusOnChange(Item)
	
	SetTabularSectionFilter();
	
EndProcedure

#EndRegion

#Region MappingTableFormTableItemEventHandlers

&AtClient
Procedure MappingTableChoice(Item, RowSelected, Field, StandardProcessing)
	
	SetMappingInteractively();
	StandardProcessing = False;
	
EndProcedure

&AtClient
Procedure MappingTableBeforeRowChange(Item, Cancel)
	Cancel = True;
	SetMappingInteractively();
EndProcedure

#EndRegion

#Region FormCommandHandlers

&AtClient
Procedure Update(Command)
	
	UpdateMappingTable();
	
EndProcedure

&AtClient
Procedure RunAutoMapping(Command)
	
	Cancel = False;
	
	// Determining the number of user-defined fields to be displayed.
	CheckUserFieldsFilled(Cancel, Object.UsedFieldsList.UnloadValues());
	
	If Cancel Then
		Return;
	EndIf;
	
	// Getting the mapping field list.
	FormParameters = New Structure;
	FormParameters.Insert("MappingFieldsList", Object.TableFieldsList.Copy());
	
	OpenForm("DataProcessor.InfobaseObjectMapping.Form.AutomaticMappingSetting", FormParameters, ThisObject,,,,,FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure RunDataImport(Command)
	NString = NStr("ru = 'Получить данные в информационную базу?'; en = 'Do you want to import data into the infobase?'; pl = 'Odbieranie danych do bazy informacyjnej?';de = 'Daten an die Infobase erhalten?';ro = 'Obțineți datele în baza de informații?';tr = 'Veriler veritabanına alınsın mı?'; es_ES = '¿Recibir los datos a la infobase?'");
	Notification = New NotifyDescription("RunDataImportAfterPromptToConfirmDataImport", ThisObject);
	
	ShowQueryBox(Notification, NString, QuestionDialogMode.YesNo, ,DialogReturnCode.Yes);
EndProcedure

&AtClient
Procedure ChangeTableFields(Command)
	
	FormParameters = New Structure;
	FormParameters.Insert("FieldList", Object.UsedFieldsList.Copy());
	
	OpenForm("DataProcessor.InfobaseObjectMapping.Form.TableFieldSetup", FormParameters, ThisObject,,,,,FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure SetupTableFieldsList(Command)
	
	FormParameters = New Structure;
	FormParameters.Insert("FieldList", Object.TableFieldsList.Copy());
	
	OpenForm("DataProcessor.InfobaseObjectMapping.Form.MappingFieldTableSetup", FormParameters, ThisObject,,,,,FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure Sort(Command)
	
	FormParameters = New Structure;
	FormParameters.Insert("SortTable", Object.SortTable);
	
	OpenForm("DataProcessor.InfobaseObjectMapping.Form.SortingSetup", FormParameters, ThisObject,,,,,FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure AddMapping(Command)
	
	SetMappingInteractively();
	
EndProcedure

&AtClient
Procedure CancelMapping(Command)
	
	SelectedRows = Items.MappingTable.SelectedRows;
	
	CancelMappingAtServer(SelectedRows);
	
	// Updating the tabular section filter
	SetTabularSectionFilter();
	
EndProcedure

&AtClient
Procedure WriteRefresh(Command)
	
	ApplyUnapprovedRecordsTable = True;
	
	UpdateMappingTable();
	
EndProcedure

&AtClient
Procedure WriteAndClose(Command)
	
	ApplyUnapprovedRecordsTable = True;
	WriteAndClose = True;
	
	UpdateMappingTable();
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// INTERNAL PROCEDURES AND FUNCTIONS (Supplied part)

&AtClient
Procedure ChangeNavigationNumber(Iterator)
	
	ClearMessages();
	
	SetNavigationNumber(SwitchNumber + Iterator);
	
EndProcedure

&AtClient
Procedure SetNavigationNumber(Val Value)
	
	IsMoveNext = (Value > SwitchNumber);
	
	SwitchNumber = Value;
	
	If SwitchNumber < 0 Then
		
		SwitchNumber = 0;
		
	EndIf;
	
	NavigationNumberOnChange(IsMoveNext);
	
EndProcedure

&AtClient
Procedure NavigationNumberOnChange(Val IsMoveNext)
	
	// Executing navigation event handlers.
	ExecuteNavigationEventHandlers(IsMoveNext);
	
	// Setting page view.
	NavigationRowsCurrent = NavigationTable.FindRows(New Structure("SwitchNumber", SwitchNumber));
	
	If NavigationRowsCurrent.Count() = 0 Then
		Raise NStr("ru = 'Не определена страница для отображения.'; en = 'Page to be displayed is not specified.'; pl = 'Strona do wyświetlenia nie jest zdefiniowana.';de = 'Die Seite für die Anzeige ist nicht definiert.';ro = 'Pagina pentru afișare nu este definită.';tr = 'Gösterilecek sayfa tanımlanmamış.'; es_ES = 'Página para visualizar no se ha definido.'");
	EndIf;
	
	NavigationRowCurrent = NavigationRowsCurrent[0];
	
	Items.MainPanel.CurrentPage = Items[NavigationRowCurrent.MainPageName];
	
	If IsMoveNext AND NavigationRowCurrent.TimeConsumingOperation Then
		
		AttachIdleHandler("ExecuteTimeConsumingOperationHandler", 0.1, True);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure ExecuteNavigationEventHandlers(Val IsMoveNext)
	
		// Navigation event handlers.
	If IsMoveNext Then
		
		NavigationRows = NavigationTable.FindRows(New Structure("SwitchNumber", SwitchNumber - 1));
		
		If NavigationRows.Count() = 0 Then
			Return;
		EndIf;
		
	Else
		
		NavigationRows = NavigationTable.FindRows(New Structure("SwitchNumber", SwitchNumber + 1));
		
		If NavigationRows.Count() = 0 Then
			Return;
		EndIf;
		
	EndIf;
	
	NavigationRowsCurrent = NavigationTable.FindRows(New Structure("SwitchNumber", SwitchNumber));
	
	If NavigationRowsCurrent.Count() = 0 Then
		Raise NStr("ru = 'Не определена страница для отображения.'; en = 'Page to be displayed is not specified.'; pl = 'Strona do wyświetlenia nie jest zdefiniowana.';de = 'Die Seite für die Anzeige ist nicht definiert.';ro = 'Pagina pentru afișare nu este definită.';tr = 'Gösterilecek sayfa tanımlanmamış.'; es_ES = 'Página para visualizar no se ha definido.'");
	EndIf;
	
	NavigationRowCurrent = NavigationRowsCurrent[0];
	
	If NavigationRowCurrent.TimeConsumingOperation AND Not IsMoveNext Then
		
		SetNavigationNumber(SwitchNumber - 1);
		Return;
	EndIf;
	
	// OnOpen handler
	If Not IsBlankString(NavigationRowCurrent.OnOpenHandlerName) Then
		
		ProcedureName = "Attachable_[HandlerName](Cancel, SkipPage, IsMoveNext)";
		ProcedureName = StrReplace(ProcedureName, "[HandlerName]", NavigationRowCurrent.OnOpenHandlerName);
		
		Cancel = False;
		SkipPage = False;
		
		CalculationResult = Eval(ProcedureName);
		
		If Cancel Then
			
			SetNavigationNumber(SwitchNumber - 1);
			
			Return;
			
		ElsIf SkipPage Then
			
			If IsMoveNext Then
				
				SetNavigationNumber(SwitchNumber + 1);
				
				Return;
				
			Else
				
				SetNavigationNumber(SwitchNumber - 1);
				
				Return;
				
			EndIf;
			
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure ExecuteTimeConsumingOperationHandler()
	
	NavigationRowsCurrent = NavigationTable.FindRows(New Structure("SwitchNumber", SwitchNumber));
	
	If NavigationRowsCurrent.Count() = 0 Then
		Raise NStr("ru = 'Не определена страница для отображения.'; en = 'Page to be displayed is not specified.'; pl = 'Strona do wyświetlenia nie jest zdefiniowana.';de = 'Die Seite für die Anzeige ist nicht definiert.';ro = 'Pagina pentru afișare nu este definită.';tr = 'Gösterilecek sayfa tanımlanmamış.'; es_ES = 'Página para visualizar no se ha definido.'");
	EndIf;
	
	NavigationRowCurrent = NavigationRowsCurrent[0];
	
	// TimeConsumingOperationProcessing handler.
	If Not IsBlankString(NavigationRowCurrent.TimeConsumingOperationHandlerName) Then
		
		ProcedureName = "Attachable_[HandlerName](Cancel, GoToNext)";
		ProcedureName = StrReplace(ProcedureName, "[HandlerName]", NavigationRowCurrent.TimeConsumingOperationHandlerName);
		
		Cancel = False;
		GoToNext = True;
		
		CalculationResult = Eval(ProcedureName);
		
		If Cancel Then
			
			SetNavigationNumber(SwitchNumber - 1);
			
			Return;
			
		ElsIf GoToNext Then
			
			SetNavigationNumber(SwitchNumber + 1);
			
			Return;
			
		EndIf;
		
	Else
		
		SetNavigationNumber(SwitchNumber + 1);
		
		Return;
		
	EndIf;
	
EndProcedure

&AtServer
Procedure NavigationTableNewRow(NavigationNumber,
	MainPageName,
	OnOpenHandlerName = "",
	IsLongOperation = False,
	TimeConsumingOperationHandlerName = "")
	
	NewRow = NavigationTable.Add();
	NewRow.SwitchNumber          = NavigationNumber;
	NewRow.MainPageName              = MainPageName;
	NewRow.OnOpenHandlerName        = OnOpenHandlerName;
	NewRow.TimeConsumingOperation               = IsLongOperation;
	NewRow.TimeConsumingOperationHandlerName = TimeConsumingOperationHandlerName;
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SetConditionalAppearance()

	ConditionalAppearance.Items.Clear();

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.MappingTableDestinationField1.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("MappingTable.MappingStatus");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = -1;

	Item.Appearance.SetParameterValue("TextColor", StyleColors.InaccessibleCellTextColor);
	Item.Appearance.SetParameterValue("Text", NStr("ru = 'Нет соответствия, объект будет скопирован'; en = 'No mapping. Object will be copied.'; pl = 'Brak mapowania dla obiektu. Obiekt zostanie skopiowany';de = 'Keine Zuordnung für Objekt. Das Objekt wird kopiert';ro = 'Lipsește confruntarea, obiectul va fi copiat';tr = 'Nesne için eşlenme yok.  Nesne kopyalanacaktır'; es_ES = 'No hay mapeo para el objeto. El objeto se copiará'"));

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.MappingTableSourceField1.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("MappingTable.MappingStatus");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = 1;

	Item.Appearance.SetParameterValue("TextColor", StyleColors.InaccessibleCellTextColor);
	Item.Appearance.SetParameterValue("Text", NStr("ru = 'Нет соответствия, объект будет скопирован'; en = 'No mapping. Object will be copied.'; pl = 'Brak mapowania dla obiektu. Obiekt zostanie skopiowany';de = 'Keine Zuordnung für Objekt. Das Objekt wird kopiert';ro = 'Lipsește confruntarea, obiectul va fi copiat';tr = 'Nesne için eşlenme yok.  Nesne kopyalanacaktır'; es_ES = 'No hay mapeo para el objeto. El objeto se copiará'"));

EndProcedure

&AtClient
Procedure RunDataImportAfterPromptToConfirmDataImport(Val QuestionResult, Val AdditionalParameters) Export
	If QuestionResult <> DialogReturnCode.Yes Then
		Return;
	EndIf;
	
	If Object.DataImportedSuccessfully Then
		NString = NStr("ru = 'Данные уже были получены. Выполнить получение данных повторно?'; en = 'Data is already received. Receive data again?'; pl = 'Dane już zostały odebrane. Odebrać dane ponownie?';de = 'Daten sind bereits erhalten. Daten erneut empfangen?';ro = 'Datele sunt deja primite. Primiți din nou datele?';tr = 'Veri zaten alındı.  Veri tekrar alınsın mı?'; es_ES = 'Datos ya se han recibido. ¿Recibir los datos de nuevo?'");
		Notification = New NotifyDescription("RunDataImportAfterPromptToReimportData", ThisObject);
		
		ShowQueryBox(Notification, NString, QuestionDialogMode.YesNo, ,DialogReturnCode.No);
		Return;
	EndIf;
	
	ExecuteDataImportAfterConfirmGettingData();
EndProcedure

&AtClient
Procedure RunDataImportAfterPromptToReimportData(Val QuestionResult, Val AdditionalParameters) Export
	If QuestionResult <> DialogReturnCode.Yes Then
		Return;
	EndIf;
	
	ExecuteDataImportAfterConfirmGettingData();
EndProcedure

&AtClient
Procedure ExecuteDataImportAfterConfirmGettingData()
	
	// Importing data on the server.
	Cancel = False;
	ExecuteDataImportAtServer(Cancel);
	
	If Cancel Then
		NString = NStr("ru = 'При получении данных возникли ошибки.
		                     |Перейти в журнал регистрации?'; 
		                     |en = 'Errors occurred during data retrieval.
		                     |Go to the event log?'; 
		                     |pl = 'Wystąpiły błędy podczas odbierania danych.
		                     |Czy chcesz otworzyć dziennik zdarzeń?';
		                     |de = 'Beim Empfangen von Daten sind Fehler aufgetreten. 
		                     |Möchten Sie das Ereignisprotokoll öffnen?';
		                     |ro = 'Erori la obținerea datelor.
		                     |Doriți să treceți în registrul logare?';
		                     |tr = 'Veri alınırken hatalar oluştu.
		                     | Olay günlüğünü açmak ister misiniz?'; 
		                     |es_ES = 'Errores ocurridos recibiendo los datos.
		                     |¿Quiere abrir el registro de eventos?'");
		
		Notification = New NotifyDescription("RunDataImportAfterPromptToOpenEventLog", ThisObject);
		ShowQueryBox(Notification, NString, QuestionDialogMode.YesNo, ,DialogReturnCode.No);
		
		Return;
	EndIf;
	
	// Updating mapping table data.
	UpdateMappingTable();
EndProcedure

&AtClient
Procedure RunDataImportAfterPromptToOpenEventLog(Val QuestionResult, Val AdditionalParameters) Export
	If QuestionResult <> DialogReturnCode.Yes Then
		Return;
	EndIf;
	
	DataExchangeClient.GoToDataEventLogModally(Object.InfobaseNode, ThisObject, "DataImport");
EndProcedure

&AtClient
Procedure GoToNext()
	
	ChangeNavigationNumber(+1);
	
EndProcedure

&AtClient
Procedure GoBack()
	
	ChangeNavigationNumber(-1);
	
EndProcedure

&AtServer
Procedure CancelMappingAtServer(SelectedRows)
	
	For Each RowID In SelectedRows Do
		
		CurrentData = MappingTable.FindByID(RowID);
		
		If CurrentData.MappingStatus = 0 Then // mapping based on information register data.
			
			CancelDataMapping(CurrentData, False);
			
		ElsIf CurrentData.MappingStatus = 3 Then // Unapproved mapping.
			
			CancelDataMapping(CurrentData, True);
			
		EndIf;
		
	EndDo;
	
EndProcedure

&AtServer
Procedure CancelDataMapping(CurrentData, IsUnapprovedMapping)
	
	Filter = New Structure;
	Filter.Insert("SourceUUID", CurrentData.DestinationUUID);
	Filter.Insert("DestinationUUID", CurrentData.SourceUUID);
	Filter.Insert("SourceType",                     CurrentData.DestinationType);
	Filter.Insert("DestinationType",                     CurrentData.SourceType);
	
	If IsUnapprovedMapping Then
		For Each FoundString In Object.UnapprovedMappingTable.FindRows(Filter) Do
			// Deleting the unapproved mapping item from the unapproved mapping table
			Object.UnapprovedMappingTable.Delete(FoundString);
		EndDo;
		
	Else
		CancelApprovedMappingAtServer(Filter);
		
	EndIf;
	
	// Adding new source and destination rows to the mapping table.
	NewSourceRow = MappingTable.Add();
	NewDestinationRow = MappingTable.Add();
	
	FillPropertyValues(NewSourceRow, CurrentData, "SourceField1, SourceField2, SourceField3, SourceField4, SourceField5, SourceUUID, SourceType, SourcePictureIndex");
	FillPropertyValues(NewDestinationRow, CurrentData, "DestinationField1, DestinationField2, DestinationField3, DestinationField4, DestinationField5, DestinationUUID, DestinationType, DestinationPictureIndex");
	
	// Setting field values for sorting source rows.
	NewSourceRow.OrderField1 = CurrentData.SourceField1;
	NewSourceRow.OrderField2 = CurrentData.SourceField2;
	NewSourceRow.OrderField3 = CurrentData.SourceField3;
	NewSourceRow.OrderField4 = CurrentData.SourceField4;
	NewSourceRow.OrderField5 = CurrentData.SourceField5;
	NewSourceRow.PictureIndex  = CurrentData.SourcePictureIndex;
	
	// Setting field values for sorting destination rows.
	NewDestinationRow.OrderField1 = CurrentData.DestinationField1;
	NewDestinationRow.OrderField2 = CurrentData.DestinationField2;
	NewDestinationRow.OrderField3 = CurrentData.DestinationField3;
	NewDestinationRow.OrderField4 = CurrentData.DestinationField4;
	NewDestinationRow.OrderField5 = CurrentData.DestinationField5;
	NewDestinationRow.PictureIndex  = CurrentData.DestinationPictureIndex;
	
	NewSourceRow.MappingStatus = -1;
	NewSourceRow.MappingStatusAdditional = 1; // unmapped objects
	
	NewDestinationRow.MappingStatus = 1;
	NewDestinationRow.MappingStatusAdditional = 1; // unmapped objects
	
	// Deleting the current mapping table row.
	MappingTable.Delete(CurrentData);
	
	// Updating numbers
	NewSourceRow.SerialNumber = NextNumberByMappingOrder();
	NewDestinationRow.SerialNumber = NextNumberByMappingOrder();
EndProcedure

&AtServer
Procedure CancelApprovedMappingAtServer(Filter)
	
	If DataExchangeServer.IsXDTOExchangePlan(Object.InfobaseNode) Then
		PublicIDsFilter = New Structure("InfobaseNode, ID, Ref",
			Object.InfobaseNode,
			Filter.DestinationUUID,
			Filter.SourceUUID);
		InformationRegisters.SynchronizedObjectPublicIDs.DeleteRecord(PublicIDsFilter);
	Else
		Filter.Insert("InfobaseNode", Object.InfobaseNode);
	
		InformationRegisters.InfobaseObjectsMaps.DeleteRecord(Filter);
	EndIf;
	
EndProcedure

&AtServer
Procedure ExecuteDataImportAtServer(Cancel)
	
	DataProcessorObject = FormAttributeToValue("Object");
	
	// Applying the table of unapproved mapping items to the database.
	DataProcessorObject.ApplyUnapprovedRecordsTable(Cancel);
	
	If Cancel Then
		Return;
	EndIf;
	
	TablesToImport = New Array;
	
	DataTableKey = DataExchangeServer.DataTableKey(Object.SourceTypeString, Object.DestinationTypeString, Object.IsObjectDeletion);
	
	TablesToImport.Add(DataTableKey);
	
	// Importing data from a batch file in the data exchange mode.
	DataProcessorObject.ExecuteDataImportForInfobase(Cancel, TablesToImport);
	
	ValueToFormAttribute(DataProcessorObject, "Object");
	
	PictureIndex = DataExchangeServer.StatisticsTablePictureIndex(UnmappedObjectCount, Object.DataImportedSuccessfully);
	
EndProcedure

&AtServer
Function PutUnapprovedMappingTableInTempStorage()
	
	Return PutToTempStorage(Object.UnapprovedMappingTable.Unload(), UUID);
	
EndFunction

&AtServer
Function GetMappingChoiceTableTempStorageAddress(FilterParameters)
	
	Columns = "SerialNumber, OrderField1, OrderField2, OrderField3, OrderField4, OrderField5, PictureIndex";
	
	Return PutToTempStorage(MappingTable.Unload(FilterParameters, Columns));
	
EndFunction

&AtClient
Procedure SetFormModified()
	
	Modified = (Object.UnapprovedMappingTable.Count() > 0);
	
EndProcedure

&AtClient
Procedure UpdateMappingTable()
	
	Items.TableButtons.Enabled = False;
	Items.TableHeaderGroup.Enabled = False;
	
	SwitchNumber = 0;
	
	// Selecting the second wizard step.
	SetNavigationNumber(2);
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Applicable

&AtClient
Procedure FillSortTable(SourceValueList)
	
	Object.SortTable.Clear();
	
	For Each Item In SourceValueList Do
		
		IsFirstField = SourceValueList.IndexOf(Item) = 0;
		
		TableRow = Object.SortTable.Add();
		
		TableRow.FieldName               = Item.Value;
		TableRow.Use         = IsFirstField; // Default sorting by the first field.
		TableRow.SortDirection = True; // ascending
		
	EndDo;
	
EndProcedure

&AtClient
Procedure FillListWithSelectedItems(SourceList, DestinationList)
	
	DestinationList.Clear();
	
	For Each Item In SourceList Do
		
		If Item.Check Then
			
			DestinationList.Add(Item.Value, Item.Presentation, True);
			
		EndIf;
		
	EndDo;
	
EndProcedure

&AtClient
Procedure SetTabularSectionFilter()
	
	Items.MappingTable.RowFilter = MappingStatusFilterOptions[FilterByMappingStatus];
	
EndProcedure

&AtClient
Procedure CheckUserFieldsFilled(Cancel, UserFields)
	
	If UserFields.Count() = 0 Then
		
		// One or more fields must be specified.
		NString = NStr("ru = 'Следует указать хотя бы одно поле для отображения'; en = 'Specify one or more fields to be displayed.'; pl = 'Trzeba wskazać chociażby jedno pole dla wyświetlenia';de = 'Geben Sie mindestens ein anzuzeigendes Feld an';ro = 'Trebuie să indicați cel puțin un câmp pentru afișare';tr = 'Gösterilecek en az bir alanı tanımlayın'; es_ES = 'Especificar como mínimo un campo para visualizar'");
		
		CommonClient.MessageToUser(NString,,"Object.TableFieldsList",, Cancel);
		
	ElsIf UserFields.Count() > MaxUserFields() Then
		
		// The value must not exceed the specified number.
		MessageString = NStr("ru = 'Уменьшите количество полей (можно выбирать не более %1 полей)'; en = 'Reduce the number of fields (you can select no more than %1 fields).'; pl = 'Zmniejszcie ilość pól (można wybierać nie więcej %1 pól)';de = 'Reduzieren Sie die Anzahl der Felder (wählen Sie nicht mehr als %1 Felder)';ro = 'Reduceți numărul de câmpuri (puteți selecta nu mai mult de %1 câmpuri)';tr = 'Alan sayısını azaltın (en fazla %1 alan seçin)'; es_ES = 'Reducir el número de campos (seleccionar no más de %1 campos)'");
		MessageString = StringFunctionsClientServer.SubstituteParametersToString(MessageString, String(MaxUserFields()));
		
		CommonClient.MessageToUser(MessageString,,"Object.TableFieldsList",, Cancel);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure SetTableFieldVisible(FormTableName)
	
	SourceFieldName = StrReplace("#FormTableName#SourceFieldNN","#FormTableName#", FormTableName);
	DestinationFieldName = StrReplace("#FormTableName#DestinationFieldNN","#FormTableName#", FormTableName);
	
	// Making all mapping table fields invisible.
	For FieldNumber = 1 To MaxUserFields() Do
		
		SourceField = StrReplace(SourceFieldName, "NN", String(FieldNumber));
		DestinationField = StrReplace(DestinationFieldName, "NN", String(FieldNumber));
		
		Items[SourceField].Visible = False;
		Items[DestinationField].Visible = False;
		
	EndDo;
	
	// Making all mapping table fields that are selected by user visible.
	For Each Item In Object.UsedFieldsList Do
		
		FieldNumber = Object.UsedFieldsList.IndexOf(Item) + 1;
		
		SourceField = StrReplace(SourceFieldName, "NN", String(FieldNumber));
		DestinationField = StrReplace(DestinationFieldName, "NN", String(FieldNumber));
		
		// Setting field visibility.
		Items[SourceField].Visible = Item.Check;
		Items[DestinationField].Visible = Item.Check;
		
		// Setting field titles.
		Items[SourceField].Title = Item.Presentation;
		Items[DestinationField].Title = Item.Presentation;
		
	EndDo;
	
EndProcedure

&AtClient
Procedure SetMappingInteractively()
	CurrentData = Items.MappingTable.CurrentData;
	
	If CurrentData=Undefined Then
		Return;
	EndIf;
	
	// Only unmapped source or destination objects can be selected for mapping.
	// In the condition: an unmapped source object and an unmapped destination object.
	If Not (CurrentData.MappingStatus=-1 Or CurrentData.MappingStatus=+1) Then
		
		ShowMessageBox(, NStr("ru = 'Объекты уже сопоставлены'; en = 'Objects are already mapped.'; pl = 'Obiekty już są zestawione';de = 'Objekte sind bereits zugeordnet';ro = 'Obiectele deja sunt confruntate';tr = 'Nesneler zaten eşlenmiş'; es_ES = 'Objetos ya se han mapeado'"), 2);
		
		// Switching to the mapping table.
		CurrentItem = Items.MappingTable;
		Return;
	EndIf;
	
	CannotCreateMappingFast = False;
	
	SelectedRows = Items.MappingTable.SelectedRows;
	If SelectedRows.Count()<>2 Then
		CannotCreateMappingFast = True;
		
	Else
		ID1 = SelectedRows[0];
		ID2 = SelectedRows[1];
		
		String1 = MappingTable.FindByID(ID1);
		String2 = MappingTable.FindByID(ID2);
		
		If Not (( String1.MappingStatus = -1 // Unmapped source object.
				AND String2.MappingStatus = +1 ) // Unmapped destination object.
			Or ( String1.MappingStatus = +1 // Unmapped destination object.
				AND String2.MappingStatus = -1 )) Then // Unmapped source object.
			CannotCreateMappingFast = True;
		EndIf;
	EndIf;
	
	If CannotCreateMappingFast Then
		// Setting the mapping in a regular way.
		FilterParameters = New Structure("MappingStatus", ?(CurrentData.MappingStatus = -1, 1, -1));
		FilterParameters.Insert("PictureIndex", CurrentData.PictureIndex);
		
		FormParameters = New Structure;
		FormParameters.Insert("TempStorageAddress",   GetMappingChoiceTableTempStorageAddress(FilterParameters));
		FormParameters.Insert("StartRowSerialNumber", CurrentData.SerialNumber);
		FormParameters.Insert("UsedFieldsList",    Object.UsedFieldsList.Copy());
		FormParameters.Insert("MaxUserFields", MaxUserFields());
		FormParameters.Insert("ObjectToMap", GetObjectToMap(CurrentData));
		FormParameters.Insert("Application1", ?(CurrentData.MappingStatus = -1, SecondApplicationDescription, CurrentApplicationDescription));
		FormParameters.Insert("Application2", ?(CurrentData.MappingStatus = -1, CurrentApplicationDescription, SecondApplicationDescription));
		
		OpenForm("DataProcessor.InfobaseObjectMapping.Form.MappingChoiceForm", FormParameters, ThisObject,,,,,FormWindowOpeningMode.LockOwnerWindow);
		
		Return;
	EndIf;
	
	// Proposing fast mapping.
	Buttons = New ValueList;
	Buttons.Add(DialogReturnCode.Yes,     NStr("ru='Установить'; en = 'Apply'; pl = 'Zainstaluj';de = 'Einstellen';ro = 'Setare';tr = 'Küme'; es_ES = 'Establecer'"));
	Buttons.Add(DialogReturnCode.Cancel, NStr("ru='Отмена'; en = 'Cancel'; pl = 'Anuluj';de = 'Abbrechen';ro = 'Revocare';tr = 'İptal'; es_ES = 'Cancelar'"));
	
	Notification = New NotifyDescription("SetMappingInteractivelyCompletion", ThisObject, New Structure);
	Notification.AdditionalParameters.Insert("ID1", ID1);
	Notification.AdditionalParameters.Insert("ID2", ID2);
	
	QuestionText = NStr("ru='Установить соответствие между выбранными объектами?'; en = 'Do you want to map the selected objects?'; pl = 'Mapować wybrane obiekty?';de = 'Die ausgewählten Objekte zuordnen?';ro = 'Stabiliți corespondența între obiectele selectate?';tr = 'Seçilmiş nesneler eşlensin mi?'; es_ES = '¿Mapear los objetos seleccionados?'");
	ShowQueryBox(Notification, QuestionText, Buttons,, DialogReturnCode.Yes);
EndProcedure

&AtClient
Procedure SetMappingInteractivelyCompletion(Val QuestionResult, Val AdditionalParameters) Export
	If QuestionResult <> DialogReturnCode.Yes Then
		Return;
	EndIf;
	
	AddUnapprovedMappingAtClient(AdditionalParameters.ID1, AdditionalParameters.ID2);
	CurrentItem = Items.MappingTable;
EndProcedure

&AtClient
Function GetObjectToMap(Data)
	
	Result = New Array;
	
	FieldNamePattern = ?(Data.MappingStatus = -1, "SourceFieldNN", "DestinationFieldNN");
	
	For FieldNumber = 1 To MaxUserFields() Do
		
		Field = StrReplace(FieldNamePattern, "NN", String(FieldNumber));
		
		If Items["MappingTable" + Field].Visible
			AND ValueIsFilled(Data[Field]) Then
			
			Result.Add(Data[Field]);
			
		EndIf;
		
	EndDo;
	
	If Result.Count() = 0 Then
		
		Result.Add(NStr("ru = '<не задан>'; en = '<not specified>'; pl = '<nieokreślony>';de = '<nicht angegeben>';ro = '<nu este specificat>';tr = '<belirtilmedi>'; es_ES = '<no especificado>'"));
		
	EndIf;
	
	Return StrConcat(Result, ", ");
EndFunction

&AtClient
Procedure AddUnapprovedMappingAtClient(Val BeginningRowID, Val EndingRowID)
	
	// Getting two mapped table rows by the specified IDs.
	// Adding a row to the unapproved mapping table.
	// Adding a row to the mapping table.
	// Deleting two mapped rows from the mapping table.
	
	BeginningRow    = MappingTable.FindByID(BeginningRowID);
	EndingRow = MappingTable.FindByID(EndingRowID);
	
	If BeginningRow = Undefined Or EndingRow = Undefined Then
		Return;
	EndIf;
	
	If BeginningRow.MappingStatus=-1 AND EndingRow.MappingStatus=+1 Then
		SourceRow = BeginningRow;
		DestinationRow = EndingRow;
	ElsIf BeginningRow.MappingStatus=+1 AND EndingRow.MappingStatus=-1 Then
		SourceRow = EndingRow;
		DestinationRow = BeginningRow;
	Else
		Return;
	EndIf;
	
	// Adding a row to the unapproved mapping table.
	NewRow = Object.UnapprovedMappingTable.Add();
	
	NewRow.SourceUUID = DestinationRow.DestinationUUID;
	NewRow.SourceType                     = DestinationRow.DestinationType;
	NewRow.DestinationUUID = SourceRow.SourceUUID;
	NewRow.DestinationType                     = SourceRow.SourceType;
	
	// Adding a row to the mapping table as an unapproved one.
	NewRowUnapproved = MappingTable.Add();
	
	// Taking sorting fields from the destination row.
	FillPropertyValues(NewRowUnapproved, SourceRow, "SourcePictureIndex, SourceField1, SourceField2, SourceField3, SourceField4, SourceField5, SourceUUID, SourceType");
	FillPropertyValues(NewRowUnapproved, DestinationRow, "DestinationPictureIndex, DestinationField1, DestinationField2, DestinationField3, DestinationField4, DestinationField5, DestinationUUID, DestinationType, OrderField1, OrderField2, OrderField3, OrderField4, OrderField5, PictureIndex");
	
	NewRowUnapproved.MappingStatus               = 3; // unapproved connection
	NewRowUnapproved.MappingStatusAdditional = 0;
	
	// Deleting mapped rows.
	MappingTable.Delete(BeginningRow);
	MappingTable.Delete(EndingRow);
	
	// Updating numbers
	NewRowUnapproved.SerialNumber = NextNumberByMappingOrder();
	
	// Setting the filter and updating data in the mapping table.
	SetTabularSectionFilter();
EndProcedure

&AtServer
Function NextNumberByMappingOrder()
	Result = 0;
	
	For Each Row In MappingTable Do
		Result = Max(Result, Row.SerialNumber);
	EndDo;
	
	Return Result + 1;
EndFunction

&AtClient
Procedure ExecuteTableSorting()
	
	SortFields = GetSortingFields();
	If Not IsBlankString(SortFields) Then
		MappingTable.Sort(SortFields);
	EndIf;
	
EndProcedure

&AtClient
Function GetSortingFields()
	
	// Function return value.
	SortFields = "";
	
	FieldPattern = "OrderFieldNN #SortDirection"; // Do not localize.
	
	For Each TableRow In Object.SortTable Do
		
		If TableRow.Use Then
			
			Separator = ?(IsBlankString(SortFields), "", ", ");
			
			SortDirectionStr = ?(TableRow.SortDirection, "Asc", "Desc");
			
			ListItem = Object.UsedFieldsList.FindByValue(TableRow.FieldName);
			
			FieldIndex = Object.UsedFieldsList.IndexOf(ListItem) + 1;
			
			FieldName = StrReplace(FieldPattern, "NN", String(FieldIndex));
			FieldName = StrReplace(FieldName, "#SortDirection", SortDirectionStr);
			
			SortFields = SortFields + Separator + FieldName;
			
		EndIf;
		
	EndDo;
	
	Return SortFields;
	
EndFunction

////////////////////////////////////////////////////////////////////////////////
// Properties

&AtClient
Function MaxUserFields()
	
	Return DataExchangeClient.MaxCountOfObjectsMappingFields();
	
EndFunction

////////////////////////////////////////////////////////////////////////////////
// Navigation event handlers.

// Page 1: Object mapping error.
//
&AtClient
Function Attachable_ObjectMappingError_OnOpen(Cancel, SkipPage, IsMoveNext)
	
	ApplyUnapprovedRecordsTable = False;
	ApplyAutomaticMappingResult = False;
	AutoMappedObjectsTableAddress = "";
	WriteAndClose = False;
	
	Items.TableButtons.Enabled = True;
	Items.TableHeaderGroup.Enabled = True;
	
	Return Undefined;
	
EndFunction

// Page 1 (waiting): Object mapping.
//
&AtClient
Function Attachable_ObjectMappingWait_TimeConsumingOperationProcessing(Cancel, GoToNext)
	
	// Determining the number of user-defined fields to be displayed.
	CheckUserFieldsFilled(Cancel, Object.UsedFieldsList.UnloadValues());
	
	If Cancel Then
		Return Undefined;
	EndIf;
	
	TimeConsumingOperation          = False;
	TimeConsumingOperationCompleted = True;
	JobID        = Undefined;
	TempStorageAddress    = "";
	
	Result = ScheduledJobStartAtServer(Cancel);
	
	If Cancel Then
		Return Undefined;
	EndIf;
	
	If Result.Status = "Running" Then
		
		GoToNext                = False;
		TimeConsumingOperation          = True;
		TimeConsumingOperationCompleted = False;
		
		IdleParameters = TimeConsumingOperationsClient.IdleParameters(ThisObject);
		IdleParameters.OutputIdleWindow = False;
		IdleParameters.OutputMessages    = True;
		
		CompletionNotification = New NotifyDescription("BackgroundJobCompletion", ThisObject);
		TimeConsumingOperationsClient.WaitForCompletion(Result, CompletionNotification, IdleParameters);
		
	EndIf;
	
	Return Undefined;
	
EndFunction

// Page 2 Handler of background job completion notification.
&AtClient
Procedure BackgroundJobCompletion(Result, AdditionalParameters) Export
	
	TimeConsumingOperation          = False;
	TimeConsumingOperationCompleted = True;
	
	If Result = Undefined Then
		// Background job aborted.
		RecordError(NStr("ru = 'Фоновое задание аварийно отменилось.'; en = 'Background job aborted.'; pl = 'Zadanie w tle zostało awaryjnie anulowane.';de = 'Die Hintergrundjob wurde abgebrochen.';ro = 'Sarcina de fundal a fost revocată forțat.';tr = 'Arka plan görevi acil olarak iptal edildi.'; es_ES = 'Tarea de fondo ha fallado.'"));
		GoBack();
	ElsIf Result.Status = "Error" Or Result.Status = "Canceled" Then
		RecordError(Result.DetailedErrorPresentation);
		GoBack();
	Else
		GoToNext();
	EndIf;
	
EndProcedure

// Page 1 (waiting): Object mapping.
//
&AtClient
Function Attachable_ObjectsMappingWait_TimeConsumingOperationCompletion_TimeConsuminOperationProcessing(Cancel, GoToNext)
	
	If WriteAndClose Then
		GoToNext = False;
		Close();
		Return Undefined;
	EndIf;
	
	If TimeConsumingOperationCompleted Then
		ExecuteObjectMappingCompletion(Cancel);
	EndIf;
	
	Items.TableButtons.Enabled          = True;
	Items.TableHeaderGroup.Enabled = True;
	
	// Setting filter in the mapping tabular section.
	SetTabularSectionFilter();
	
	// Setting mapping table field headers and visibility.
	SetTableFieldVisible("MappingTable");
	
	Return Undefined;

EndFunction

// Page 2 Object mapping in background job.
//
&AtServer
Function ScheduledJobStartAtServer(Cancel)
	
	FormAttributes = New Structure;
	FormAttributes.Insert("UnapprovedRecordTableApplyOnly",    WriteAndClose);
	FormAttributes.Insert("ApplyUnapprovedRecordsTable",          ApplyUnapprovedRecordsTable);
	FormAttributes.Insert("ApplyAutomaticMappingResult", ApplyAutomaticMappingResult);
	
	JobParameters = New Structure;
	JobParameters.Insert("ObjectContext", DataExchangeServer.GetObjectContext(FormAttributeToValue("Object")));
	JobParameters.Insert("FormAttributes",  FormAttributes);
	
	If ApplyAutomaticMappingResult Then
		JobParameters.Insert("AutomaticallyMappedObjectsTable", GetFromTempStorage(AutoMappedObjectsTableAddress));
	EndIf;
	
	ExecutionParameters = TimeConsumingOperations.BackgroundExecutionParameters(UUID);
	ExecutionParameters.BackgroundJobDescription = NStr("ru = 'Сопоставление объектов'; en = 'Object mapping'; pl = 'Mapowanie obiektów';de = 'Objekte zuordnen';ro = 'Maparea obiectelor';tr = 'Nesne eşleniyor'; es_ES = 'Mapeo de objeto'");
	
	Result = TimeConsumingOperations.ExecuteInBackground(
		"DataProcessors.InfobaseObjectMapping.MapObjects",
		JobParameters,
		ExecutionParameters);
		
	If Result = Undefined Then
		Cancel = True;
		Return Undefined;
	EndIf;
	
	JobID     = Result.JobID;
	TempStorageAddress = Result.ResultAddress;
	
	If Result.Status = "Error" Or Result.Status = "Canceled" Then
		Cancel = True;
		RecordError(Result.DetailedErrorPresentation);
	EndIf;
	
	Return Result;
	
EndFunction

// Page 3: Object mapping.
//
&AtServer
Procedure ExecuteObjectMappingCompletion(Cancel)
	
	Try
		AfterObjectMapping();
	Except
		Cancel = True;
		RecordError(DetailErrorDescription(ErrorInfo()));
		Return;
	EndTry;
	
EndProcedure

&AtServer
Procedure AfterObjectMapping()
	
	If WriteAndClose Then
		Return;
	EndIf;
	
	MappingResult = GetFromTempStorage(TempStorageAddress);
	
	// {Mapping digest}
	ObjectCountInSource       = MappingResult.ObjectCountInSource;
	ObjectCountInDestination       = MappingResult.ObjectCountInDestination;
	MappedObjectCount   = MappingResult.MappedObjectCount;
	UnmappedObjectCount = MappingResult.UnmappedObjectCount;
	MappedObjectPercentage       = MappingResult.MappedObjectPercentage;
	PictureIndex                     = DataExchangeServer.StatisticsTablePictureIndex(UnmappedObjectCount, Object.DataImportedSuccessfully);
	
	MappingTable.Load(MappingResult.MappingTable);
	
	DataProcessorObject = DataProcessors.InfobaseObjectMapping.Create();
	DataExchangeServer.ImportObjectContext(MappingResult.ObjectContext, DataProcessorObject);
	
	ValueToFormAttribute(DataProcessorObject, "Object");
	
	If ApplyUnapprovedRecordsTable Then
		Modified = False;
	EndIf;
	
	ApplyUnapprovedRecordsTable           = False;
	ApplyAutomaticMappingResult  = False;
	AutoMappedObjectsTableAddress = "";
	
EndProcedure

&AtServer
Procedure RecordError(DetailedErrorPresentation)
	
	WriteLogEvent(
		NStr("ru = 'Помощник сопоставления объектов.Анализ данных'; en = 'Object mapping wizard.Data analysis'; pl = 'Kreator mapowania obiektów. Analiza danych';de = 'Objekt-Zuordnungs-Assistent. Datenanalyse';ro = 'Maparea obiectelor wizard. Analiza datelor';tr = 'Nesne eşlenme sihirbazı.  Veri analizi'; es_ES = 'Asistente de mapeo de objetos.Análisis de datos'", Common.DefaultLanguageCode()),
		EventLogLevel.Error,
		,
		, DetailedErrorPresentation);
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Filling wizard navigation table.

&AtServer
Procedure ObjectMappingScenario()
	
	NavigationTable.Clear();
	NavigationTableNewRow(1, "ObjectMappingError", "ObjectMappingError_OnOpen");
	
	// Waiting for object mapping.
	NavigationTableNewRow(2, "ObjectMappingWait",, True, "ObjectMappingWaiting_TimeConsumingOperationProcessing");
	NavigationTableNewRow(3, "ObjectMappingWait",, True, "ObjectMappingWaitingTimeConsumingOperationCompletion_TimeConsumingOperationProcessing");
	
	// Operations with object mapping table.
	NavigationTableNewRow(4, "ObjectMapping");
	
EndProcedure

#EndRegion
