///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

// This form is used to edit exchange object registration changes for a specified node.
// You can use the following parameters in the OnCreateAtServer handler.
// 
// ExchangeNode                  - ExchangePlanRef - an exchange node reference.
// SelectExchangeNodeProhibited - Boolean           - a flag showing whether a user can change the specified node.
//                                                  The ExchangeNode parameter must be specified.
// NamesOfMetadataToHide   - ValueList   - contains metadata names to exclude from a registration 
//                                                  tree.
//
// If this form is called from the additional reports and data processors subsystem, the following additional parameters are available:
//
// AdditionalDataProcessorRef - Arbitrary - a reference to the item of the additional reports and 
//                                                data processors catalog that calls the form.
//                                                If this parameter is specified, the TargetObjects parameter must be specified too.
// TargetObjects             - Array       - objects to process. A first array element is used in 
//                                                the OnCreateAtServer procedure. If this parameter 
//                                                is specified, the CommandID parameter must be specified too.
//

#Region Variables

&AtClient
Var MetadataCurrentRow;

#EndRegion

#Region Public

#Region ForCallsFromOtherSubsystems

// StandardSubsystems.AdditionalReportsAndDataProcessors

// Command export handler for the additional reports and data processors subsystem.
//
// Parameters:
//     CommandID - String - command ID to execute.
//     TargetObjects             - Array       - references to process. This parameter is not used 
//                                     in the current procedure, expected that a similar parameter is passed and processed during the from creation.
//     CreatedObjects     - Array - a return value, an array of references to created objects.
//                                     This parameter is not used in the current data processor.
//
&AtClient
Procedure ExecuteCommand(CommandID, RelatedObjects, CreatedObjects) Export
	
	If CommandID = "OpenRegistrationEditingForm" Then
		
		If RegistrationObjectParameter <> Undefined Then
			// Using parameters that are set in the OnCreateAtServer procedure.
			
			RegistrationFormParameters = New Structure;
			RegistrationFormParameters.Insert("RegistrationObject",  RegistrationObjectParameter);
			RegistrationFormParameters.Insert("RegistrationTable", RegistrationTableParameter);

			OpenForm(ThisFormName + "Form.ObjectRegistrationNodes", RegistrationFormParameters);
		EndIf;
		
	EndIf;
	
EndProcedure

// End StandardSubsystems.AdditionalReportsAndDataProcessors

#EndRegion

#EndRegion

#Region EventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)

	SetConditionalAppearance();
	
	CheckPlatformVersionAndCompatibilityMode();
	
	RegistrationTableParameter = Undefined;
	RegistrationObjectParameter  = Undefined;
	
	OpenWithNodeParameter = False;
	CurrentObject = ThisObject();
	ThisFormName = GetFormName();
	// Analyzing form parameters and setting options
	If Parameters.AdditionalDataProcessorRef = Undefined Then
		// Starting the data processor in standalone mode, with the ExchangeNodeRef parameter specified.
		ExchangeNodeRef = Parameters.ExchangeNode;
		Parameters.Property("SelectExchangeNodeProhibited", SelectExchangeNodeProhibited);
		OpenWithNodeParameter = True;
		
	Else
		// This data processor is called from the additional reports and data processors subsystem.
		If TypeOf(Parameters.RelatedObjects) = Type("Array") AND Parameters.RelatedObjects.Count() > 0 Then
			
			// The form is opened with the specified object.
			RelatedObject = Parameters.RelatedObjects[0];
			Type = TypeOf(RelatedObject);
			
			If ExchangePlans.AllRefsType().ContainsType(Type) Then
				ExchangeNodeRef = RelatedObject;
				OpenWithNodeParameter = True;
			Else
				// Filling internal attributes.
				Details = CurrentObject.MetadataCharacteristics(RelatedObject.Metadata());
				If Details.IsReference Then
					RegistrationObjectParameter = RelatedObject;
					
				ElsIf Details.IsSet Then
					// Structure and table name
					RegistrationTableParameter = Details.TableName;
					RegistrationObjectParameter  = New Structure;
					For Each Dimension In CurrentObject.RecordSetDimensions(RegistrationTableParameter) Do
						CurName = Dimension.Name;
						RegistrationObjectParameter.Insert(CurName, RelatedObject.Filter[CurName].Value);
					EndDo;
					
				EndIf;
			EndIf;
			
		Else
			Raise StrReplace(
				NStr("ru = 'Некорректные параметры объектов назначения открытия команды ""%1""'; en = 'Invalid destination object parameters for the %1 command'; pl = 'Nieprawidłowy cel obiektów przeznaczenia otwarcia polecenia ""%1""';de = 'Ungültige Zielobjektparameter für den %1 Befehl';ro = 'Parametrii obiect destinație nevalizi pentru %1 comandă';tr = '""%1""komutu için geçersiz hedef nesne parametreleri'; es_ES = 'Destinación incorrecta de parámetros de objetos para el comando ""%1""'"),
				"%1", Parameters.CommandID);
		EndIf;
		
	EndIf;
	
	// Initializing object settings.
	CurrentObject.ReadSettings();
	CurrentObject.ReadSSLSupportFlags();
	ThisObject(CurrentObject);
	
	// Initializing other parameters only if this form will be opened
	If RegistrationObjectParameter <> Undefined Then
		Return;
	EndIf;
	Items.PagesGroup.CurrentPage = Items.Default;
	// Filling the list of prohibited metadata objects based on form parameters.
	Parameters.Property("NamesOfMetadataToHide", NamesOfMetadataToHide);
	AddNameOfMetadataToHide();
	
	Items.ObjectsListOptions.CurrentPage = Items.BlankPage;
	Parameters.Property("SelectExchangeNodeProhibited", SelectExchangeNodeProhibited);
	
	ExchangePlanNodeDescription = String(ExchangeNodeRef);
	
	If Not ControlSettings() AND OpenWithNodeParameter Then
		
		MessageText = StrReplace(
			NStr("ru = 'Для ""%1"" редактирование регистрации объектов недоступно.'; en = 'Cannot edit object registration for node %1.'; pl = 'Edytowanie rejestracji obiektu nie jest dostępne dla ""%1"".';de = 'Die Bearbeitung der Objektregistrierung ist für ""%1"" nicht verfügbar.';ro = 'Pentru ""%1"" este inaccesibilă editarea înregistrării obiectelor.';tr = 'Nesne kaydını düzenleme ""%1"" için mevcut değildir.'; es_ES = 'Edición del registro de objetos no se encuentra disponible para ""%1"".'"),
			"%1", ExchangePlanNodeDescription);
		
		Raise MessageText;
		
	EndIf;
		
EndProcedure

&AtClient
Procedure BeforeClose(Cancel, Exit, WarningText, StandardProcessing)
	
	If Exit Then
		Return;
	EndIf;
	
	If ForceCloseForm Then
		Return;
	EndIf;
	
	If TimeConsumingOperationStarted Then
		Cancel = True;
		Notification = New NotifyDescription("ConfirmFormClosingCompletion", ThisObject);
		ShowQueryBox(Notification, NStr("ru = 'Прервать выполнение регистрации данных?'; en = 'Do you want to cancel data registration?'; pl = 'Chcesz przerwać wykonywanie rejestracji danych?';de = 'Datenprotokollierung abbrechen?';ro = 'Întrerupeți executarea înregistrării datelor?';tr = 'Veri kaydını durdur?'; es_ES = '¿Interrumpir el registro de datos?'"), QuestionDialogMode.YesNo);
	EndIf;
	
EndProcedure

&AtClient
Procedure OnClose(Exit)
	
	If Exit Then
		Return;
	EndIf;
	
	If TimeConsumingOperationStarted Then
		EndExecutingTimeConsumingOperation(BackgroundJobID);
	EndIf;
	
EndProcedure

&AtClient
Procedure ChoiceProcessing(SelectedValue, ChoiceSource)
	
	If Not (TypeOf(ChoiceSource) = Type("ManagedForm")
			AND ChoiceSource.UniqueKey = QueryResultChoiceFormUniqueKey) Then
		Return;
	EndIf;
	
	// Analyzing selected value, it must be a structure.
	If TypeOf(SelectedValue) <> Type("Structure") 
		Or (Not SelectedValue.Property("ChoiceAction"))
		Or (Not SelectedValue.Property("ChoiceData"))
		Or TypeOf(SelectedValue.ChoiceAction) <> Type("Boolean")
		Or TypeOf(SelectedValue.ChoiceData) <> Type("String") Then
		Error = NStr("ru = 'Неожиданный результат выбора из консоли запросов'; en = 'Unexpected selection result received from the query console.'; pl = 'Nieoczekiwany wynik podczas zapytania z konsoli';de = 'Unerwartetes Ergebnis bei der Abfrage von der Konsole';ro = 'Rezultat neașteptat de selectare din consola interogărilor';tr = 'Konsoldan sorgulanırken beklenmeyen sonuç'; es_ES = 'Resultado inesperado solicitando desde la consola'");
	Else
		Error = RefControlForQuerySelection(SelectedValue.ChoiceData);
	EndIf;
	
	If Error <> "" Then 
		ShowMessageBox(,Error);
		Return;
	EndIf;
		
	If SelectedValue.ChoiceAction Then
		Text = NStr("ru = 'Зарегистрировать результат запроса
		                 |на узле ""%1""?'; 
		                 |en = 'Do you want to register the query result
		                 |at node ""%1""?'; 
		                 |pl = 'Zarejestrować wynik zapytania 
		                 |na węźle ""%1""?';
		                 |de = 'Abfrageergebnis
		                 |auf Knoten ""%1"" registrieren?';
		                 |ro = 'Înregistrați rezultatul de interogare
		                 |pe nodul ""%1""?';
		                 |tr = '"
" ünitede %1 talep sonucu kaydedilsin mi?'; 
		                 |es_ES = '¿Registrar el resultado de solicitud
		                 |en el nodo ""%1""?'"); 
	Else
		Text = NStr("ru = 'Отменить регистрацию результата запроса
		                 |на узле ""%1""?'; 
		                 |en = 'Do you want to cancel registration of the query result
		                 |at node ""%1""?'; 
		                 |pl = 'Anulować rejestrację wyniku zapytania
		                 |na węźle ""%1""?';
		                 |de = 'Die
		                 |vom Knoten ""%1"" angeforderte Ergebnisregistrierung abbrechen?';
		                 |ro = 'Revocați înregistrarea rezultatului interogării
		                 |pe nodul ""%1""?';
		                 |tr = '"
" ünitede %1 talep sonucunun kaydı iptal edilsin mi?'; 
		                 |es_ES = '¿Cancelar el registro del resultado de solicitud
		                 |en el nodo ""%1""?'");
	EndIf;
	Text = StrReplace(Text, "%1", String(ExchangeNodeRef));
					 
	QuestionTitle = NStr("ru = 'Подтверждение'; en = 'Confirm operation'; pl = 'Potwierdzenie';de = 'Bestätigung';ro = 'Confirmare';tr = 'Onay'; es_ES = 'Confirmación'");
	
	Notification = New NotifyDescription("ChoiceProcessingCompletion", ThisObject, New Structure);
	Notification.AdditionalParameters.Insert("SelectedValue", SelectedValue);
	ShowQueryBox(Notification, Text, QuestionDialogMode.YesNo, , , QuestionTitle);
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If EventName = "ObjectDataExchangeRegistrationEdit" Then
		FillRegistrationCountInTreeRows();
		UpdatePageContent();

	ElsIf EventName = "ExchangeNodeDataEdit" AND ExchangeNodeRef = Parameter Then
		SetMessageNumberTitle();
		
	EndIf;
	
EndProcedure

&AtServer
Procedure OnSaveDataInSettingsAtServer(Settings)
	// Automatic settings
	CurrentObject = ThisObject();
	CurrentObject.SaveSettings();
	ThisObject(CurrentObject);
EndProcedure

&AtServer
Procedure OnLoadDataFromSettingsAtServer(Settings)
	
	If RegistrationObjectParameter <> Undefined Then
		// Another form will be used.
		Return;
	EndIf;
	
	If ValueIsFilled(Parameters.ExchangeNode) Then
		ExchangeNodeRef = Parameters.ExchangeNode;
	Else
		ExchangeNodeRef = Settings["ExchangeNodeRef"];
		// If restored exchange node is deleted, clearing the ExchangeNodeRef value.
		If ExchangeNodeRef <> Undefined 
		    AND ExchangePlans.AllRefsType().ContainsType(TypeOf(ExchangeNodeRef))
		    AND IsBlankString(ExchangeNodeRef.DataVersion) Then
			ExchangeNodeRef = Undefined;
		EndIf;
	EndIf;
	
	ControlSettings();
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers
//

&AtClient
Procedure ExchangeNodeRefStartChoice(Item, ChoiceData, StandardProcessing)
	StandardProcessing = False;
	CurFormName = ThisFormName + "Form.SelectExchangePlanNode";
	CurParameters = New Structure("MultipleChoice, ChoiceInitialValue", False, ExchangeNodeRef);
	OpenForm(CurFormName, CurParameters, Item);
EndProcedure

&AtClient
Procedure ExchangeNodeRefChoiceProcessing(Item, ValueSelected, StandardProcessing)
	If ExchangeNodeRef <> ValueSelected Then
		ExchangeNodeRef = ValueSelected;
		AttachIdleHandler("ExchangeNodeChoiceProcessing", 0.1, True);
	EndIf;
EndProcedure

&AtClient
Procedure ExchangeNodeRefOnChange(Item)
	ExchangeNodeChoiceProcessingServer();
	ExpandMetadataTree();
	UpdatePageContent();
EndProcedure

&AtClient
Procedure ExchangeNodeRefClear(Item, StandardProcessing)
	StandardProcessing = False;
EndProcedure

&AtClient
Procedure FilterVariantByMessageNoOnChange(Item)
	SetFiltersInDynamicLists();
	UpdatePageContent();
EndProcedure

&AtClient
Procedure ObjectListVariantsOnCurrentPageChange(Item, CurrentPage)
	UpdatePageContent(CurrentPage);
EndProcedure

#EndRegion

#Region MetadataTreeFormTableItemsEventHandlers
//

&AtClient
Procedure MetadataTreeMarkOnChange(Item)
	ChangeMark(Items.MetadataTree.CurrentRow);
EndProcedure

&AtClient
Procedure MetadataTreeOnActivateRow(Item)
	If Items.MetadataTree.CurrentRow <> MetadataCurrentRow Then
		MetadataCurrentRow  = Items.MetadataTree.CurrentRow;
		AttachIdleHandler("SetUpChangeEditing", 0.1, True);
	EndIf;
EndProcedure

#EndRegion

#Region ConstantListFormTableItemEventHandlers
//

&AtClient
Procedure ConstantListChoiceProcessing(Item, ValueSelected, StandardProcessing)
	
	Result = AddRegistrationAtServer(True, ValueSelected);
	Items.ConstantsList.Refresh();
	FillRegistrationCountInTreeRows();
	ReportRegistrationResults(Result);
	
	If TypeOf(ValueSelected) = Type("Array") AND ValueSelected.Count() > 0 Then
		Item.CurrentRow = ValueSelected[0];
	Else
		Item.CurrentRow = ValueSelected;
	EndIf;
	
EndProcedure

#EndRegion

#Region RefListFormTableItemsEventHandlers
//
&AtClient
Procedure ReferenceListChoice(Item, RowSelected, Field, StandardProcessing)
	StandardProcessing = False;
	CurrentRef = Item.CurrentData.Ref;
	If Not ValueIsFilled(CurrentRef)
		Or Not ValueIsFilled(ReferencesListTableName) Then
		Return;
	EndIf;
	ParametersStructure = New Structure("Key, ReadOnly", CurrentRef, True);
	OpenForm(ReferencesListTableName + ".ObjectForm", ParametersStructure, ThisObject);
EndProcedure

&AtClient
Procedure ReferenceListChoiceProcessing(Item, ValueSelected, StandardProcessing)
	DataChoiceProcessing(Item, ValueSelected);
EndProcedure

#EndRegion

#Region RecordSetListFormTableItemEventHandlers
//

&AtClient
Procedure RecordSetListSelection(Item, RowSelected, Field, StandardProcessing)
	StandardProcessing = False;
	
	WriteParameters = RecordSetKeyStructure(Item.CurrentData);
	If WriteParameters <> Undefined Then
		OpenForm(WriteParameters.FormName, New Structure(WriteParameters.Parameter, WriteParameters.Value));
	EndIf;
	
EndProcedure

&AtClient
Procedure RecordSetListChoiceProcessing(Item, ValueSelected, StandardProcessing)
	DataChoiceProcessing(Item, ValueSelected);
EndProcedure

#EndRegion

#Region FormCommandHandlers
//

&AtClient
Procedure AddRegistrationForSingleObject(Command)
	
	If Not ValueIsFilled(ExchangeNodeRef) Then
		Return;
	EndIf;
	
	CurrRow = Items.ObjectsListOptions.CurrentPage;
	If CurrRow = Items.ConstantsPage Then
		AddConstantRegistrationInList();
		
	ElsIf CurrRow = Items.ReferencesListPage Then
		AddRegistrationInReferenceList();
		
	ElsIf CurrRow = Items.RecordSetPage Then
		AddRegistrationToRecordSetFilter();
		
	EndIf;
	
EndProcedure

&AtClient
Procedure DeleteRegistrationForSingleObject(Command)
	
	If Not ValueIsFilled(ExchangeNodeRef) Then
		Return;
	EndIf;
	
	CurrRow = Items.ObjectsListOptions.CurrentPage;
	If CurrRow = Items.ConstantsPage Then
		DeleteConstantRegistrationInList();
		
	ElsIf CurrRow = Items.ReferencesListPage Then
		DeleteRegistrationFromReferenceList();
		
	ElsIf CurrRow = Items.RecordSetPage Then
		DeleteRegistrationInRecordSet();
		
	EndIf;
	
EndProcedure

&AtClient
Procedure AddRegistrationFilter(Command)
	
	If Not ValueIsFilled(ExchangeNodeRef) Then
		Return;
	EndIf;
	
	CurrRow = Items.ObjectsListOptions.CurrentPage;
	If CurrRow = Items.ReferencesListPage Then
		AddRegistrationInListFilter();
		
	ElsIf CurrRow = Items.RecordSetPage Then
		AddRegistrationToRecordSetFilter();
		
	EndIf;
	
EndProcedure

&AtClient
Procedure DeleteRegistrationFilter(Command)
	
	If Not ValueIsFilled(ExchangeNodeRef) Then
		Return;
	EndIf;
	
	CurrRow = Items.ObjectsListOptions.CurrentPage;
	If CurrRow = Items.ReferencesListPage Then
		DeleteRegistrationInListFilter();
		
	ElsIf CurrRow = Items.RecordSetPage Then
		DeleteRegistrationInRecordSetFilter();
		
	EndIf;
	
EndProcedure

&AtClient
Procedure OpenNodeRegistrationForm(Command)
	
	If SelectExchangeNodeProhibited Then
		Return;
	EndIf;
		
	Data = GetCurrentObjectToEdit();
	If Data <> Undefined Then
		RegistrationTable = ?(TypeOf(Data) = Type("Structure"), RecordSetsListTableName, "");
		OpenForm(ThisFormName + "Form.ObjectRegistrationNodes",
			New Structure("RegistrationObject, RegistrationTable, NotifyAboutChanges", 
				Data, RegistrationTable, True), ThisObject);
	EndIf;
	
EndProcedure

&AtClient
Procedure ShowExportResult(Command)
	
	CurPage = Items.ObjectsListOptions.CurrentPage;
	Serialization = New Array;
	
	If CurPage = Items.ConstantsPage Then 
		FormItem = Items.ConstantsList;
		For Each Row In FormItem.SelectedRows Do
			curData = FormItem.RowData(Row);
			Serialization.Add(New Structure("TypeFlag, Data", 1, curData.MetaFullName));
		EndDo;
		
	ElsIf CurPage = Items.RecordSetPage Then
		MeasurementList = RecordSetKeyNameArray(RecordSetsListTableName);
		FormItem = Items.RecordSetsList;
		Prefix = "RecordSetsList";
		For Each Item In FormItem.SelectedRows Do
			curData = New Structure();
			Data = FormItem.RowData(Item);
			For Each Name In MeasurementList Do
				curData.Insert(Name, Data[Prefix + Name]);
			EndDo;
			Serialization.Add(New Structure("TypeFlag, Data", 2, curData));
		EndDo;
		
	ElsIf CurPage = Items.ReferencesListPage Then
		FormItem = Items.RefsList;
		For Each Item In FormItem.SelectedRows Do
			curData = FormItem.RowData(Item);
			Serialization.Add(New Structure("TypeFlag, Data", 3, curData.Ref));
		EndDo;
		
	Else
		Return;
		
	EndIf;
	
	If Serialization.Count() > 0 Then
		Text = SerializationText(Serialization);
		TextTitle = NStr("ru = 'Результат стандартной выгрузки (РИБ)'; en = 'Standard export result (DIB)'; pl = 'Wynik eksportu (w trybie DIB)';de = 'Ergebnis exportieren (im DIB-Modus)';ro = 'Rezultat export (în modul DIB)';tr = 'Sonucu dışa aktar (DIB modunda)'; es_ES = 'Resultado de exportación (en el modo DIB)'");
		Text.Show(TextTitle);
	EndIf;
	
EndProcedure

&AtClient
Procedure EditMessagesNumbers(Command)
	
	If ValueIsFilled(ExchangeNodeRef) Then
		CurFormName = ThisFormName + "Form.ExchangePlanNodeMessageNumbers";
		CurParameters = New Structure("ExchangeNodeRef", ExchangeNodeRef);
		OpenForm(CurFormName, CurParameters, ThisObject, , , , , FormWindowOpeningMode.LockOwnerWindow);
	EndIf;
	
EndProcedure

&AtClient
Procedure AddConstantRegistration(Command)
	If ValueIsFilled(ExchangeNodeRef) Then
		AddConstantRegistrationInList();
	EndIf;
EndProcedure

&AtClient
Procedure DeleteConstantRegistration(Command)
	If ValueIsFilled(ExchangeNodeRef) Then
		DeleteConstantRegistrationInList();
	EndIf;
EndProcedure

&AtClient
Procedure AddRefRegistration(Command)
	If ValueIsFilled(ExchangeNodeRef) Then
		AddRegistrationInReferenceList();
	EndIf;
EndProcedure

&AtClient
Procedure AddObjectDeletionRegistration(Command)
	If ValueIsFilled(ExchangeNodeRef) Then
		AddObjectDeletionRegistrationInReferenceList();
	EndIf;
EndProcedure

&AtClient
Procedure DeleteRefRegistration(Command)
	If ValueIsFilled(ExchangeNodeRef) Then
		DeleteRegistrationFromReferenceList();
	EndIf;
EndProcedure

&AtClient
Procedure AddRefRegistrationPickup(Command)
	If ValueIsFilled(ExchangeNodeRef) Then
		AddRegistrationInReferenceList(True);
	EndIf;
EndProcedure

&AtClient
Procedure AddRefRegistrationFilter(Command)
	If ValueIsFilled(ExchangeNodeRef) Then
		AddRegistrationInListFilter();
	EndIf;
EndProcedure

&AtClient
Procedure DeleteRefRegistrationFilter(Command)
	If ValueIsFilled(ExchangeNodeRef) Then
		DeleteRegistrationInListFilter();
	EndIf;
EndProcedure

&AtClient
Procedure AddRegistrationForAutoObjects(Command)
	If ValueIsFilled(ExchangeNodeRef) Then
		AddSelectedObjectRegistration(False);
	EndIf;
EndProcedure

&AtClient
Procedure DeleteRegistrationForAutoObjects(Command)
	If ValueIsFilled(ExchangeNodeRef) Then
		DeleteSelectedObjectRegistration(False);
	EndIf;
EndProcedure

&AtClient
Procedure AddRegistrationForAllObjects(Command)
	If ValueIsFilled(ExchangeNodeRef) Then
		AddSelectedObjectRegistration();
	EndIf;
EndProcedure

&AtClient
Procedure DeleteRegistrationForAllObjects(Command)
	If ValueIsFilled(ExchangeNodeRef) Then
		DeleteSelectedObjectRegistration();
	EndIf;
EndProcedure

&AtClient
Procedure AddRecordSetRegistrationFilter(Command)
	If ValueIsFilled(ExchangeNodeRef) Then
		AddRegistrationToRecordSetFilter();
	EndIf;
EndProcedure

&AtClient
Procedure DeleteRecordSetRegistration(Command)
	If ValueIsFilled(ExchangeNodeRef) Then
		DeleteRegistrationInRecordSet();
	EndIf;
EndProcedure

&AtClient
Procedure DeleteRecordSetRegistrationFilter(Command)
	If ValueIsFilled(ExchangeNodeRef) Then
		DeleteRegistrationInRecordSetFilter();
	EndIf;
EndProcedure

&AtClient
Procedure UpdateAllData(Command)
	FillRegistrationCountInTreeRows();
	UpdatePageContent();
EndProcedure

&AtClient
Procedure AddQueryResultRegistration(Command)
	If ValueIsFilled(ExchangeNodeRef) Then
		ActionWithQueryResult(True);
	EndIf;
EndProcedure

&AtClient
Procedure DeleteQueryResultRegistration(Command)
	If ValueIsFilled(ExchangeNodeRef) Then
		ActionWithQueryResult(False);
	EndIf;
EndProcedure

&AtClient
Procedure OpenSettingsForm(Command)
	OpenDataProcessorSettingsForm();
EndProcedure

&AtClient
Procedure EditObjectMessageNumber(Command)
	
	If Items.ObjectsListOptions.CurrentPage = Items.ConstantsPage Then
		EditConstantMessageNo();
		
	ElsIf Items.ObjectsListOptions.CurrentPage = Items.ReferencesListPage Then
		EditRefMessageNo();
		
	ElsIf Items.ObjectsListOptions.CurrentPage = Items.RecordSetPage Then
		EditMessageNoSetList()
		
	EndIf;
	
EndProcedure

&AtClient
Procedure RegisterMOIDAndPredefinedItems(Command)
	
	QuestionTitle = NStr("ru = 'Подтверждение'; en = 'Confirm operation'; pl = 'Potwierdzenie';de = 'Bestätigung';ro = 'Confirmare';tr = 'Onay'; es_ES = 'Confirmación'");
	QuestionText     = StrReplace( 
		NStr("ru = 'Зарегистрировать данные для восстановления подчиненного узла РИБ
		     |на узле ""%1""?'; 
		     |en = 'Do you want to register data for recovery of the subordinate DIB node
		     |at node ""%1""?'; 
		     |pl = 'Zarejestrować dane dla przywrócenia podwładnego węzła RBI
		     |na węźle ""%1""?';
		     |de = 'Daten registrieren, um die untergeordnete Knoten RIB
		     |auf dem Knoten ""%1"" wiederherzustellen?';
		     |ro = 'Înregistrați datele pentru restabilirea nodului subordonat al BID
		     |pe nodul ""%1""?';
		     |tr = 'Ünite "
" üzerindeki RIB alt ünitesini geri yüklemek için veriler %1 kaydedilsin mi?'; 
		     |es_ES = 'Registrar los datos para restablecer el nodo subordinado de la base de información distribuida
		     |en el nodo ""%1""?'"),
		"%1", ExchangeNodeRef);
	
	Notification = New NotifyDescription("RegisterMetadataObjectIDCompletion", ThisObject);
	ShowQueryBox(Notification, QuestionText, QuestionDialogMode.YesNo, , , QuestionTitle);
	
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure ConfirmFormClosingCompletion(QuestionResult, AdditionalParameters) Export
	
	If Not QuestionResult = DialogReturnCode.Yes Then
		Return;
	EndIf;
	
	ForceCloseForm = True;
	Close();
	
EndProcedure

&AtServer
Procedure SetConditionalAppearance()

	ConditionalAppearance.Items.Clear();

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ReferencesListMessageNumber.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("RefsList.NotExported");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;

	Item.Appearance.SetParameterValue("TextColor", WebColors.LightGray);
	Item.Appearance.SetParameterValue("Text", NStr("ru = 'Не выгружалось'; en = 'Not exported'; pl = 'Nie wyeksportowane';de = 'Nicht exportiert';ro = 'Nu este exportat';tr = 'Dışa aktarılmadı'; es_ES = 'No exportado'"));

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ConstantsListMessageNumber.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("ConstantsList.NotExported");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;

	Item.Appearance.SetParameterValue("TextColor", WebColors.LightGray);
	Item.Appearance.SetParameterValue("Text", NStr("ru = 'Не выгружалось'; en = 'Not exported'; pl = 'Nie wyeksportowane';de = 'Nicht exportiert';ro = 'Nu este exportat';tr = 'Dışa aktarılmadı'; es_ES = 'No exportado'"));

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.RecordSetsListMessageNumber.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("RecordSetsList.NotExported");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;

	Item.Appearance.SetParameterValue("TextColor", WebColors.LightGray);
	Item.Appearance.SetParameterValue("Text", NStr("ru = 'Не выгружалось'; en = 'Not exported'; pl = 'Nie wyeksportowane';de = 'Nicht exportiert';ro = 'Nu este exportat';tr = 'Dışa aktarılmadı'; es_ES = 'No exportado'"));

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.MetadataTreeChangesCountAsString.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("MetadataTree.ChangeCount");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = 0;

	Item.Appearance.SetParameterValue("TextColor", WebColors.DarkGray);
	Item.Appearance.SetParameterValue("Text", NStr("ru = 'Нет изменений'; en = 'No changes'; pl = 'Bez zmian';de = 'Keine Änderungen';ro = 'Nu sunt modificări';tr = 'Değişiklik yok'; es_ES = 'No hay cambios'"));
	
EndProcedure
//

// Dialog continuation notification handler.
&AtClient 
Procedure RegisterMetadataObjectIDCompletion(Val QuestionResult, Val AdditionalParameters) Export
	
	If QuestionResult <> DialogReturnCode.Yes Then
		Return;
	EndIf;
	
	ReportRegistrationResults(RegisterMOIDAndPredefinedItemsAtServer() );
		
	FillRegistrationCountInTreeRows();
	UpdatePageContent();
EndProcedure

// Dialog continuation notification handler.
&AtClient 
Procedure ChoiceProcessingCompletion(Val QuestionResult, Val AdditionalParameters) Export
	If QuestionResult <> DialogReturnCode.Yes Then
		Return
	EndIf;
	SelectedValue = AdditionalParameters.SelectedValue;
	If Object.AsynchronousRegistrationAvailable Then
		BackgroundJobParameters = PrepareRegistrationChangeParameters(SelectedValue.ChoiceAction, 
		AdditionalParameters.Property("NoAutoRegistration") AND AdditionalParameters.NoAutoRegistration,
		Undefined);
		BackgroundJobParameters.Insert("AddressData", SelectedValue.ChoiceData);
		BackgroundJobStartClient(BackgroundJobParameters);
	Else
		ReportRegistrationResults(ChangeQueryResultRegistrationServer(SelectedValue.ChoiceAction, SelectedValue.ChoiceData));
		
		FillRegistrationCountInTreeRows();
		UpdatePageContent();
	EndIf;
EndProcedure

&AtClient
Procedure EditConstantMessageNo()
	curData = Items.ConstantsList.CurrentData;
	If curData = Undefined Then
		Return;
	EndIf;
	
	Notification = New NotifyDescription("EditConstantMessageNoCompletion", ThisObject, New Structure);
	Notification.AdditionalParameters.Insert("MetaFullName", curData.MetaFullName);
	
	MessageNumber = curData.MessageNo;
	Tooltip = NStr("ru = 'Номер отправленного'; en = 'Number of the last sent message'; pl = 'Numer ostatniej wysłanej wiadomości';de = 'Nummer der zuletzt gesendeten Nachricht';ro = 'Numărul ultimului mesaj trimis';tr = 'Son gönderilen mesajın numarası'; es_ES = 'Número de los últimos mensajes enviados'"); 
	
	ShowInputNumber(Notification, MessageNumber, Tooltip);
EndProcedure

// Dialog continuation notification handler.
&AtClient
Procedure EditConstantMessageNoCompletion(Val MessageNumber, Val AdditionalParameters) Export
	If MessageNumber = Undefined Then
		// Canceling input.
		Return;
	EndIf;
	
	ReportRegistrationResults(EditMessageNumberAtServer(MessageNumber, AdditionalParameters.MetaFullName));
		
	Items.ConstantsList.Refresh();
	FillRegistrationCountInTreeRows();
EndProcedure

&AtClient
Procedure EditRefMessageNo()
	curData = Items.RefsList.CurrentData;
	If curData = Undefined Then
		Return;
	EndIf;
	
	Notification = New NotifyDescription("EditRefMessageNoCompletion", ThisObject, New Structure);
	Notification.AdditionalParameters.Insert("Ref", curData.Ref);
	
	MessageNumber = curData.MessageNo;
	Tooltip = NStr("ru = 'Номер отправленного'; en = 'Number of the last sent message'; pl = 'Numer ostatniej wysłanej wiadomości';de = 'Nummer der zuletzt gesendeten Nachricht';ro = 'Numărul ultimului mesaj trimis';tr = 'Son gönderilen mesajın numarası'; es_ES = 'Número de los últimos mensajes enviados'"); 
	
	ShowInputNumber(Notification, MessageNumber, Tooltip);
EndProcedure

// Dialog continuation notification handler.
&AtClient
Procedure EditRefMessageNoCompletion(Val MessageNumber, Val AdditionalParameters) Export
	If MessageNumber = Undefined Then
		// Canceling input.
		Return;
	EndIf;
	
	ReportRegistrationResults(EditMessageNumberAtServer(MessageNumber, AdditionalParameters.Ref));
		
	Items.RefsList.Refresh();
	FillRegistrationCountInTreeRows();
EndProcedure

&AtClient
Procedure EditMessageNoSetList()
	curData = Items.RecordSetsList.CurrentData;
	If curData = Undefined Then
		Return;
	EndIf;
	
	Notification = New NotifyDescription("EditMessageNoSetListCompletion", ThisObject, New Structure);
	
	RowData = New Structure;
	KeysNames = RecordSetKeyNameArray(RecordSetsListTableName);
	For Each Name In KeysNames Do
		RowData.Insert(Name, curData["RecordSetsList" + Name]);
	EndDo;
	
	Notification.AdditionalParameters.Insert("RowData", RowData);
	
	MessageNumber = curData.MessageNo;
	Tooltip = NStr("ru = 'Номер отправленного'; en = 'Number of the last sent message'; pl = 'Numer ostatniej wysłanej wiadomości';de = 'Nummer der zuletzt gesendeten Nachricht';ro = 'Numărul ultimului mesaj trimis';tr = 'Son gönderilen mesajın numarası'; es_ES = 'Número de los últimos mensajes enviados'"); 
	
	ShowInputNumber(Notification, MessageNumber, Tooltip);
EndProcedure

// Dialog continuation notification handler.
&AtClient
Procedure EditMessageNoSetListCompletion(Val MessageNumber, Val AdditionalParameters) Export
	If MessageNumber = Undefined Then
		// Canceling input.
		Return;
	EndIf;
	
	ReportRegistrationResults(EditMessageNumberAtServer(
		MessageNumber, AdditionalParameters.RowData, RecordSetsListTableName));
	
	Items.RecordSetsList.Refresh();
	FillRegistrationCountInTreeRows();
EndProcedure

&AtClient
Procedure SetUpChangeEditing()
	SetUpChangeEditingServer(MetadataCurrentRow);
EndProcedure

&AtClient
Procedure ExpandMetadataTree()
	For Each Row In MetadataTree.GetItems() Do
		Items.MetadataTree.Expand( Row.GetID() );
	EndDo;
EndProcedure

&AtServer
Procedure SetMessageNumberTitle()
	
	Text = NStr("ru = '№ отправленного %1, № принятого %2'; en = 'Sent message #%1, received message # %2'; pl = 'liczba wysłanych %1, liczba odebranych %2';de = '# der gesendeten %1, # der empfangenen %2';ro = 'Nr. trimise %1, Nr. primite %2';tr = 'Gönderilen No%1, alınan No%2'; es_ES = '# de los enviados %1, #  de los recibidos %2'");
	
	Data = ReadMessageNumbers();
	Text = StrReplace(Text, "%1", Format(Data.SentNo, "NFD=0; NZ="));
	Text = StrReplace(Text, "%2", Format(Data.ReceivedNo, "NFD=0; NZ="));
	
	Items.FormEditMessagesNumbers.Title = Text;
EndProcedure	

&AtClient
Procedure ExchangeNodeChoiceProcessing()
	ExchangeNodeChoiceProcessingServer();
EndProcedure

&AtServer
Procedure ExchangeNodeChoiceProcessingServer()
	
	// Modifying node numbers in the FormEditMessageNumbers title.
	SetMessageNumberTitle();
	
	// Updating metadata tree.
	ReadMetadataTree();
	FillRegistrationCountInTreeRows();
	
	// Updating active page.
	Items.ObjectsListOptions.CurrentPage = Items.BlankPage;
	
	// Setting visibility for related buttons.
	
	MetaNodeExchangePlan = ExchangeNodeRef.Metadata();
	
	If Object.DIBModeAvailable                             // Current SSL version supports MOID.
		AND (ExchangePlans.MasterNode() = Undefined)          // Current infobase is a master node.
		AND MetaNodeExchangePlan.DistributedInfoBase Then // Current node is DIB.
		Items.FormRegisterMOIDAndPredefinedItems.Visible = True;
	Else
		Items.FormRegisterMOIDAndPredefinedItems.Visible = False;
	EndIf;
	
EndProcedure

&AtClient
Procedure ReportRegistrationResults(Results)
	Command = Results.Command;
	If TypeOf(Command) = Type("Boolean") Then
		If Command Then
			WarningTitle = NStr("ru = 'Регистрация изменений:'; en = 'Register changes:'; pl = 'Rejestracja zmian:';de = 'Registrierung ändern:';ro = 'Înregistrarea modificărilor:';tr = 'Kaydı değiştir:'; es_ES = 'Cambiar el registro:'");
			WarningText = NStr("ru = 'Зарегистрировано %1 изменений из %2
			                           |на узле ""%0""'; 
			                           |en = '%1 out of %2 changes are registered
			                           |at node ""%0.""'; 
			                           |pl = 'Zarejestrowano %1 zmian z %2
			                           | na węźle ""%0""';
			                           |de = 'Registrierte %1 Änderungen von %2
			                           |zum Knoten ""%0""';
			                           |ro = 'Au fost înregistrate %1 modificări din %2
			                           |pe nodul ""%0""';
			                           |tr = '""%0"" ünitesinde %1%2 değişikliklerden 
			                           | ''i kaydedildi'; 
			                           |es_ES = 'Registrado %1 cambios de %2
			                           | en el nodo ""%0""'");
		Else
			WarningTitle = NStr("ru = 'Отмена регистрации:'; en = 'Cancel registration:'; pl = 'Anuluj rejestrację:';de = 'Registrierung abbrechen:';ro = 'Anularea înregistrării:';tr = 'Kayıt iptali:'; es_ES = 'Cancelar el registro:'");
			WarningText = NStr("ru = 'Отменена регистрация %1 изменений 
			                           |на узле ""%0"".'; 
			                           |en = 'Registration of %1 changes
			                           |at node ""%0"" is canceled.'; 
			                           |pl = 'Anulowano rejestrację %1 zmian 
			                           |na węźle ""%0"".';
			                           |de = 'Abbrechen der Registrierung %1 von Änderungen 
			                           | am Knoten ""%0"".';
			                           |ro = 'A fost revocată înregistrarea a %1 modificări 
			                           |pe nodul ""%0"".';
			                           |tr = '""%0"" ünitesinde %1değişikliklerin 
			                           |kaydı  iptal edildi.'; 
			                           |es_ES = 'Registro cancelado %1 de cambios de 
			                           | en el nodo ""%0"".'");
		EndIf;
	Else
		WarningTitle = NStr("ru = 'Изменение номера сообщения:'; en = 'Change message number:'; pl = 'Zmień numer wiadomości:';de = 'Nachrichtennummer ändern:';ro = 'Modificarea numărului mesajului:';tr = 'Mesaj numarasını değiştir:'; es_ES = 'Cambiar el número de mensaje:'");
		WarningText = NStr("ru = 'Номер сообщения изменен на %3
		                           |у %1 объекта(ов)'; 
		                           |en = 'Message number is changed to %3
		                           |for %1 object(s).'; 
		                           |pl = 'Numer wiadomości został zmieniony na %3
		                           | dla %1 obiektu(ów)';
		                           |de = 'Nachrichtennummer geändert in %3
		                           | für %1 Objekt(e)';
		                           |ro = 'Numărul mesajului a fost modificat cu %3
		                           |la %1 obiect(e)';
		                           |tr = '
		                           | nesnede (-lerde) mesaj numarası %3''den %1 olarak değiştirildi'; 
		                           |es_ES = 'Número de mensaje se ha cambiado por %3
		                           |y %1de objeto(s)'");
	EndIf;
	
	WarningText = StrReplace(WarningText, "%0", ExchangeNodeRef);
	WarningText = StrReplace(WarningText, "%1", Format(Results.Success, "NZ="));
	WarningText = StrReplace(WarningText, "%2", Format(Results.Total, "NZ="));
	WarningText = StrReplace(WarningText, "%3", Command);
	
	WarningRequired = Results.Total <> Results.Success;
	If WarningRequired Then
		RefreshDataRepresentation();
		ShowMessageBox(, WarningText, , WarningTitle);
	Else
		ShowUserNotification(WarningTitle,
			GetURL(ExchangeNodeRef),
			WarningText,
			Items.HiddenPictureInformation32.Picture);
	EndIf;
EndProcedure

&AtServer
Function GetQueryResultChoiceForm()
	
	CurrentObject = ThisObject();
	CurrentObject.ReadSettings();
	ThisObject(CurrentObject);
	
	CheckSSL = CurrentObject.CheckSettingsCorrectness();
	ThisObject(CurrentObject);
	
	If CheckSSL.QueryExternalDataProcessorAddressSetting <> Undefined Then
		Return Undefined;
		
	ElsIf IsBlankString(CurrentObject.QueryExternalDataProcessorAddressSetting) Then
		Return Undefined;
		
	ElsIf Lower(Right(TrimAll(CurrentObject.QueryExternalDataProcessorAddressSetting), 4)) = ".epf" Then
		Return Undefined;
		
	Else
		DataProcessor = DataProcessors[CurrentObject.QueryExternalDataProcessorAddressSetting].Create();
		FormID = ".Form";
		
	EndIf;
	
	Return DataProcessor.Metadata().FullName() + FormID;
EndFunction

&AtClient
Procedure AddConstantRegistrationInList()
	CurFormName = ThisFormName + "Form.SelectConstant";
	CurParameters = New Structure();
	CurParameters.Insert("ExchangeNode",ExchangeNodeRef);
	CurParameters.Insert("MetadataNamesArray",MetadataNamesStructure.Constants);
	CurParameters.Insert("PresentationsArray",MetadataPresentationsStructure.Constants);
	CurParameters.Insert("AutoRecordsArray",MetadataAutoRecordStructure.Constants);
	OpenForm(CurFormName, CurParameters, Items.ConstantsList);
EndProcedure

&AtClient
Procedure DeleteConstantRegistrationInList()
	
	Item = Items.ConstantsList;
	
	PresentationsList = New Array;
	NamesList          = New Array;
	For Each Row In Item.SelectedRows Do
		Data = Item.RowData(Row);
		PresentationsList.Add(Data.Description);
		NamesList.Add(Data.MetaFullName);
	EndDo;
	
	Count = NamesList.Count();
	If Count = 0 Then
		Return;
	ElsIf Count = 1 Then
		Text = NStr("ru = 'Отменить регистрацию ""%2""
		                 |на узле ""%1""?'; 
		                 |en = 'Do you want to cancel registration of ""%2""
		                 |at node ""%1""?'; 
		                 |pl = 'Anulować rejestrację ""%2""
		                 |na węźle ""%1""?';
		                 |de = 'Registrierung ""%2""
		                 | auf dem Knoten ""%1"" abbrechen?';
		                 |ro = 'Revocați înregistrarea ""%2""
		                 |pe nodul ""%1""?';
		                 |tr = '"
" ünitede%2 %1 kaydı iptal edilsin mi?'; 
		                 |es_ES = '¿Cancelar el registro ""%2""
		                 |en el nodo ""%1""?'"); 
	Else
		Text = NStr("ru = 'Отменить регистрацию выбранных констант
		                 |на узле ""%1""?'; 
		                 |en = 'Do you want to cancel registration of the selected constants
		                 |at node ""%1""?'; 
		                 |pl = 'Anulować rejestrację wybranych stałych
		                 |na węźle ""%1""?';
		                 |de = 'Abbrechen der Registrierung der ausgewählten Konstanten
		                 |im Knoten ""%1""?';
		                 |ro = 'Revocați înregistrarea constantelor
		                 |pe nodul ""%1""?';
		                 |tr = '"
" ünitede %1 seçilmiş sabitlerin kaydı iptal edilsin mi?'; 
		                 |es_ES = '¿Cancelar el registro de los constantes seleccionados
		                 | en el nodo ""%1""?'"); 
	EndIf;
	Text = StrReplace(Text, "%1", ExchangeNodeRef);
	Text = StrReplace(Text, "%2", PresentationsList[0]);
	
	QuestionTitle = NStr("ru = 'Подтверждение'; en = 'Confirm operation'; pl = 'Potwierdzenie';de = 'Bestätigung';ro = 'Confirmare';tr = 'Onay'; es_ES = 'Confirmación'");
	
	Notification = New NotifyDescription("DeleteConstantRegistrationInListCompletion", ThisObject, New Structure);
	Notification.AdditionalParameters.Insert("NamesList", NamesList);
	
	ShowQueryBox(Notification, Text, QuestionDialogMode.YesNo, , ,QuestionTitle);
EndProcedure

// Dialog continuation notification handler.
&AtClient
Procedure DeleteConstantRegistrationInListCompletion(Val QuestionResult, Val AdditionalParameters) Export
	If QuestionResult <> DialogReturnCode.Yes Then
		Return;
	EndIf;
		
	ReportRegistrationResults(DeleteRegistrationAtServer(True, AdditionalParameters.NamesList));
		
	Items.ConstantsList.Refresh();
	FillRegistrationCountInTreeRows();
EndProcedure

&AtClient
Procedure AddRegistrationInReferenceList(IsPick = False)
	CurFormName = ReferencesListTableName + ".ChoiceForm";
	CurParameters = New Structure();
	CurParameters.Insert("ChoiceMode", True);
	CurParameters.Insert("MultipleChoice", True);
	CurParameters.Insert("CloseOnChoice", IsPick);
	CurParameters.Insert("ChoiceFoldersAndItems", FoldersAndItemsUse.FoldersAndItems);

	OpenForm(CurFormName, CurParameters, Items.RefsList);
EndProcedure

&AtClient
Procedure AddObjectDeletionRegistrationInReferenceList()
	Ref = ObjectRefToDelete();
	DataChoiceProcessing(Items.RefsList, Ref);
EndProcedure

&AtServer
Function ObjectRefToDelete(Val UUID = Undefined)
	Details = ThisObject().MetadataCharacteristics(ReferencesListTableName);
	If UUID = Undefined Then
		Return Details.Manager.GetRef();
	EndIf;
	Return Details.Manager.GetRef(UUID);
EndFunction

&AtClient 
Procedure AddRegistrationInListFilter()
	CurFormName = ThisFormName + "Form.SelectObjectsUsingFilter";
	CurParameters = New Structure("ChoiceAction, TableName", 
		True,
		ReferencesListTableName);
	OpenForm(CurFormName, CurParameters, Items.RefsList);
EndProcedure

&AtClient 
Procedure DeleteRegistrationInListFilter()
	CurFormName = ThisFormName + "Form.SelectObjectsUsingFilter";
	CurParameters = New Structure("ChoiceAction, TableName", 
		False,
		ReferencesListTableName);
	OpenForm(CurFormName, CurParameters, Items.RefsList);
EndProcedure

&AtClient
Procedure DeleteRegistrationFromReferenceList()
	
	Item = Items.RefsList;
	
	DeletionList = New Array;
	For Each Row In Item.SelectedRows Do
		Data = Item.RowData(Row);
		DeletionList.Add(Data.Ref);
	EndDo;
	
	Count = DeletionList.Count();
	If Count = 0 Then
		Return;
	ElsIf Count = 1 Then
		Text = NStr("ru = 'Отменить регистрацию ""%2""
		                 |на узле ""%1""?'; 
		                 |en = 'Do you want to cancel registration of ""%2""
		                 |at node ""%1""?'; 
		                 |pl = 'Anulować rejestrację ""%2""
		                 |na węźle ""%1""?';
		                 |de = 'Registrierung ""%2""
		                 | auf dem Knoten ""%1"" abbrechen?';
		                 |ro = 'Revocați înregistrarea ""%2""
		                 |pe nodul ""%1""?';
		                 |tr = '"
" ünitede%2 %1 kaydı iptal edilsin mi?'; 
		                 |es_ES = '¿Cancelar el registro ""%2""
		                 |en el nodo ""%1""?'"); 
	Else
		Text = NStr("ru = 'Отменить регистрацию выбранных объектов
		                 |на узле ""%1""?'; 
		                 |en = 'Cancel registration of the selected objects
		                 |on node ""%1""?'; 
		                 |pl = 'Anulować rejestrację wybranych obiektów
		                 |na węźle ""%1""?';
		                 |de = 'Rückgängig machen der Registrierung ausgewählter Objekte
		                 |auf dem Knoten ""%1?';
		                 |ro = 'Revocați înregistrarea obiectelor selectate
		                 |pe nodul ""%1""?';
		                 |tr = '"
" ünitede %1 seçilmiş nesnelerin kaydı iptal edilsin mi?'; 
		                 |es_ES = '¿Cancelar el registro de los objetos seleccionados
		                 | en el nodo ""%1?'"); 
	EndIf;
	Text = StrReplace(Text, "%1", ExchangeNodeRef);
	Text = StrReplace(Text, "%2", DeletionList[0]);
	
	QuestionTitle = NStr("ru = 'Подтверждение'; en = 'Confirm operation'; pl = 'Potwierdzenie';de = 'Bestätigung';ro = 'Confirmare';tr = 'Onay'; es_ES = 'Confirmación'");
	
	Notification = New NotifyDescription("DeleteRegistrationFromReferenceListCompletion", ThisObject, New Structure);
	Notification.AdditionalParameters.Insert("DeletionList", DeletionList);
	
	ShowQueryBox(Notification, Text, QuestionDialogMode.YesNo, , , QuestionTitle);
EndProcedure

// Dialog continuation notification handler.
&AtClient 
Procedure DeleteRegistrationFromReferenceListCompletion(Val QuestionResult, Val AdditionalParameters) Export
	If QuestionResult <> DialogReturnCode.Yes Then
		Return;
	EndIf;
	
	ReportRegistrationResults(DeleteRegistrationAtServer(True, AdditionalParameters.DeletionList));
		
	Items.RefsList.Refresh();
	FillRegistrationCountInTreeRows();
EndProcedure

&AtClient
Procedure AddRegistrationToRecordSetFilter()
	CurFormName = ThisFormName + "Form.SelectObjectsUsingFilter";
	CurParameters = New Structure("ChoiceAction, TableName", 
		True,
		RecordSetsListTableName);
	OpenForm(CurFormName, CurParameters, Items.RecordSetsList);
EndProcedure

&AtClient
Procedure DeleteRegistrationInRecordSet()
	
	DataStructure = "";
	KeysNames = RecordSetKeyNameArray(RecordSetsListTableName);
	For Each Name In KeysNames Do
		DataStructure = DataStructure +  "," + Name;
	EndDo;
	DataStructure = Mid(DataStructure, 2);
	
	Data = New Array;
	Item = Items.RecordSetsList;
	For Each Row In Item.SelectedRows Do
		curData = Item.RowData(Row);
		RowData = New Structure;
		For Each Name In KeysNames Do
			RowData.Insert(Name, curData["RecordSetsList" + Name]);
		EndDo;
		Data.Add(RowData);
	EndDo;
	
	If Data.Count() = 0 Then
		Return;
	EndIf;
	
	Choice = New Structure();
	Choice.Insert("TableName",RecordSetsListTableName);
	Choice.Insert("ChoiceData",Data);
	Choice.Insert("ChoiceAction",False);
	Choice.Insert("FieldsStructure",DataStructure);
	DataChoiceProcessing(Items.RecordSetsList, Choice);
EndProcedure

&AtClient
Procedure DeleteRegistrationInRecordSetFilter()
	CurFormName = ThisFormName + "Form.SelectObjectsUsingFilter";
	CurParameters = New Structure("ChoiceAction, TableName", 
		False,
		RecordSetsListTableName);
	OpenForm(CurFormName, CurParameters, Items.RecordSetsList);
EndProcedure

&AtClient
Procedure AddSelectedObjectRegistration(NoAutoRegistration = True)
	
	Data = GetSelectedMetadataNames(NoAutoRegistration);
	Count = Data.MetaNames.Count();
	If Count = 0 Then
		// Current row
		Data = GetCurrentRowMetadataNames(NoAutoRegistration);
	EndIf;
	
	Text = NStr("ru = 'Зарегистрировать %1 для выгрузки на узле ""%2""?
	                 |
	                 |Изменение регистрации большого количества объектов может занять продолжительное время.'; 
	                 |en = 'Register %1 for exporting on the ""%2"" node?
	                 |
	                 |Changing registration of a large number of objects can take a long time.'; 
	                 |pl = 'Zarejestrować %1 dla ładowania na węźle ""%2""?
	                 |
	                 |Zmiana rejestracji dużej ilości obiektów może potrwać dłuższy czas.';
	                 |de = '%1 für den Upload auf den Knoten ""%2"" registrieren?
	                 |
	                 |Das Ändern der Registrierung einer großen Anzahl von Objekten kann sehr lange dauern.';
	                 |ro = 'Înregistrați %1 pentru descărcare pe nodul ""%2""?
	                 |
	                 |Modificarea înregistrării unui număr mare de obiecte poate fi de lungă durată.';
	                 |tr = '""%1"" ünitesinde %2 dışa aktarma kaydedilsin mi? 
	                 |
	                 |Çok sayıda nesnenin kaydının değiştirilmesi uzun zaman alabilir.'; 
	                 |es_ES = '¿Registrar %1 para subir en el nodo ""%2""?
	                 |
	                 |Cambiar el registro de gran número de objetos puede llevar mucho tiempo.'");
					 
	Text = StrReplace(Text, "%1", Data.Details);
	Text = StrReplace(Text, "%2", ExchangeNodeRef);
	
	QuestionTitle = NStr("ru = 'Подтверждение'; en = 'Confirm operation'; pl = 'Potwierdzenie';de = 'Bestätigung';ro = 'Confirmare';tr = 'Onay'; es_ES = 'Confirmación'");
	
	Notification = New NotifyDescription("AddSelectedObjectRegistrationCompletion", ThisObject, New Structure);
	Notification.AdditionalParameters.Insert("MetaNames", Data.MetaNames);
	Notification.AdditionalParameters.Insert("NoAutoRegistration", NoAutoRegistration);
	
	ShowQueryBox(Notification, Text, QuestionDialogMode.YesNo, , , QuestionTitle);
EndProcedure

// Dialog continuation notification handler.
&AtClient 
Procedure AddSelectedObjectRegistrationCompletion(Val QuestionResult, Val AdditionalParameters) Export
	If QuestionResult <> DialogReturnCode.Yes Then
		Return;
	EndIf;
	If Object.AsynchronousRegistrationAvailable Then
		BackgroundJobParameters = PrepareRegistrationChangeParameters(True, AdditionalParameters.NoAutoRegistration, 
										AdditionalParameters.MetaNames);
		BackgroundJobStartClient(BackgroundJobParameters);
	Else
		Result = AddRegistrationAtServer(AdditionalParameters.NoAutoRegistration, 
			AdditionalParameters.MetaNames);
		
		FillRegistrationCountInTreeRows();
		UpdatePageContent();
		ReportRegistrationResults(Result);
	EndIf;
EndProcedure

&AtClient
Procedure DeleteSelectedObjectRegistration(NoAutoRegistration = True)
	
	Data = GetSelectedMetadataNames(NoAutoRegistration);
	Count = Data.MetaNames.Count();
	If Count = 0 Then
		Data = GetCurrentRowMetadataNames(NoAutoRegistration);
	EndIf;
	
	Text = NStr("ru = 'Отменить регистрацию %1 для выгрузки на узле ""%2""?
	                 |
	                 |Изменение регистрации большого количества объектов может занять продолжительное время.'; 
	                 |en = 'Cancel %1 registration for export on the ""%2"" node? 
	                 |
	                 |Changing registration of a large number of objects can take a long time.'; 
	                 |pl = 'Anulować rejestrację %1 dla ładowania na węźle ""%2""?
	                 |
	                 |Zmiana rejestracji dużej ilości obiektów może potrwać dłuższy czas.';
	                 |de = 'Registrierung %1 für den Upload auf den Knoten """"%2 abbrechen?
	                 |
	                 |Das Ändern der Registrierung einer großen Anzahl von Objekten kann sehr lange dauern.';
	                 |ro = 'Revocați înregistrarea %1 pentru descărcare pe nodul ""%2""?
	                 |
	                 |Modificarea înregistrării unui număr mare de obiecte poate fi de lungă durată.';
	                 |tr = '""%1"" ünitesinde %2 dışa aktarma kaydedilsin mi? 
	                 |
	                 |Çok sayıda nesnenin kaydının değiştirilmesi uzun zaman alabilir.'; 
	                 |es_ES = '¿Cancelar el registro %1 para subir en el nodo ""%2""?
	                 |
	                 |Cambiar el registro de gran número de objetos puede llevar mucho tiempo.'");
	
	QuestionTitle = NStr("ru = 'Подтверждение'; en = 'Confirm operation'; pl = 'Potwierdzenie';de = 'Bestätigung';ro = 'Confirmare';tr = 'Onay'; es_ES = 'Confirmación'");
	
	Text = StrReplace(Text, "%1", Data.Details);
	Text = StrReplace(Text, "%2", ExchangeNodeRef);
	
	Notification = New NotifyDescription("DeleteSelectedObjectRegistrationCompletion", ThisObject, New Structure);
	Notification.AdditionalParameters.Insert("MetaNames", Data.MetaNames);
	Notification.AdditionalParameters.Insert("NoAutoRegistration", NoAutoRegistration);
	
	ShowQueryBox(Notification, Text, QuestionDialogMode.YesNo, , , QuestionTitle);
EndProcedure

// Dialog continuation notification handler.
&AtClient
Procedure DeleteSelectedObjectRegistrationCompletion(Val QuestionResult, Val AdditionalParameters) Export
	If QuestionResult <> DialogReturnCode.Yes Then
		Return;
	EndIf;
	
	If Object.AsynchronousRegistrationAvailable Then
		BackgroundJobParameters = PrepareRegistrationChangeParameters(False, AdditionalParameters.NoAutoRegistration, 
										AdditionalParameters.MetaNames);
		BackgroundJobStartClient(BackgroundJobParameters);
	Else
		ReportRegistrationResults(DeleteRegistrationAtServer(AdditionalParameters.NoAutoRegistration, 
				AdditionalParameters.MetaNames));
			
		FillRegistrationCountInTreeRows();
		UpdatePageContent();
	EndIf;
EndProcedure

&AtClient
Procedure BackgroundJobStartClient(BackgroundJobParameters)
	TimeConsumingOperationStarted = True;
	TimeConsumingOperationKind = ?(BackgroundJobParameters.Command, True, False);
	AttachIdleHandler("TimeConsumingOperationPage", 0.1, True);
	Result = ScheduledJobStartAtServer(BackgroundJobParameters);
	If Result = Undefined Then
		TimeConsumingOperationStarted = False;
		WarningText = NStr("ru='При запуске фонового задания с целью изменения регистрации произошла ошибка.'; en = 'An error occurred while starting the background job to change registration.'; pl = 'Podczas uruchomienia zadania w tle w celu zmiany rejestracji wystąpił błąd.';de = 'Beim Starten des Hintergrundjobs zum Ändern der Registrierung ist ein Fehler aufgetreten.';ro = 'La lansarea sarcinii de fundal cu scopul modificării înregistrării s-a produs eroare.';tr = 'Kaydı değiştirmek için arka plan çalıştırıldığında bir hata oluştu.'; es_ES = 'Al lanzar la tarea de fondo con el objetivo de cambiar el registro se ha producido un error.'");
		ShowMessageBox(, WarningText);
		Return;
	EndIf;
	CommonModuleTimeConsumingOperationsClient = CommonModuleTimeConsumingOperationsClient();
	If Result.Status = "Running" Then
		IdleParameters = CommonModuleTimeConsumingOperationsClient.IdleParameters(ThisObject);
		IdleParameters.OutputIdleWindow  = False;
		IdleParameters.OutputMessages     = True;
		
		CompletionNotification = New NotifyDescription("BackgroundJobCompletion", ThisObject);
		CommonModuleTimeConsumingOperationsClient.WaitForCompletion(Result, CompletionNotification, IdleParameters);
	Else
		BackgroundJobExecutionResult = Result;
		AttachIdleHandler("BackgroundJobExecutionResult", 0.1, True);
	EndIf;
EndProcedure

&AtClient
Procedure TimeConsumingOperationPage()
	If NOT TimeConsumingOperationStarted Then
		Return;
	EndIf;
	If TimeConsumingOperationKind Then
		OperationStatus = NStr("ru='Выполняется регистрация изменений. Пожалуйста, подождите.'; en = 'Registering changes. Please wait.'; pl = 'Trwa rejestracja zmian. Proszę czekać.';de = 'Die Registrierung von Änderungen wird ausgeführt. Bitte warten Sie.';ro = 'Are loc înregistrarea modificărilor. Așteptați.';tr = 'Değişiklikler kaydediliyor.  Lütfen bekleyin.'; es_ES = 'Se está registrando el cambio. Espere, por favor.'");
	Else
		OperationStatus = NStr("ru='Выполняется отмена регистрации изменений. Пожалуйста, подождите.'; en = 'Change registration is being canceled. Please wait.'; pl = 'Trwa anulowanie rejestracji zmian. Proszę czekać.';de = 'Der Abbruch der Registrierung von Änderungen wird ausgeführt. Bitte warten Sie.';ro = 'Are loc revocarea înregistrării modificărilor. Așteptați.';tr = 'Değişiklik kaydı iptal ediliyor.  Lütfen bekleyin.'; es_ES = 'Se está cancelando el registro del cambio. Espere, por favor.'");
	EndIf;
	Items.TimeConsumingOperationStatus.Title = OperationStatus;
	Items.PagesGroup.CurrentPage = Items.Wait;
EndProcedure

&AtClient
Procedure BackgroundJobCompletion(Result, AdditionalParameters) Export
	
	BackgroundJobExecutionResult = Result;
	BackgroundJobExecutionResult();
	
EndProcedure

&AtClient
Procedure BackgroundJobExecutionResult()
	
	BackgroundJobGetResultAtServer();
	TimeConsumingOperationStarted = False;
	
	Items.PagesGroup.CurrentPage = Items.Default;
	CurrentItem = Items.MetadataTree;
	
	If ValueIsFilled(ErrorMessage) Then
		Message = New UserMessage;
		Message.Text = ErrorMessage;
		Message.Message();
	EndIf;
	
	If Not BackgroundJobExecutionResult = Undefined Then
		If BackgroundJobExecutionResult.Property("AdditionalResultData")
			AND BackgroundJobExecutionResult.AdditionalResultData.Property("Command") Then
			
			ReportRegistrationResults(BackgroundJobExecutionResult.AdditionalResultData);
			FillRegistrationCountInTreeRows();
			UpdatePageContent();
			
		EndIf;
	EndIf;
	
EndProcedure

&AtServer
Function ScheduledJobStartAtServer(BackgroundJobParameters)
	
	ModuleTimeConsumingOperations = CommonModuleTimeConsumingOperations();
	ExecutionParameters = ModuleTimeConsumingOperations.BackgroundExecutionParameters(UUID);
	ExecutionParameters.AdditionalResult = False;
	
	If BackgroundJobParameters.Property("AddressData") Then
		// Data storage address is passed.
		Result = GetFromTempStorage(BackgroundJobParameters.AddressData);
		Result= Result[Result.UBound()];
		Data = Result.Unload().UnloadColumn("Ref");
		BackgroundJobParameters.Insert("Data", Data);
	EndIf;
	ProcedureName = FormAttributeToValue("Object").Metadata().FullName() + ".ObjectModule.ChangeRegistration";
	Result = ModuleTimeConsumingOperations.ExecuteInBackground(ProcedureName, BackgroundJobParameters, ExecutionParameters);
	BackgroundJobID  = Result.JobID;
	BackgroundJobStorageAddress = Result.ResultAddress;
	
	Return Result;
	
EndFunction

&AtServer
Procedure BackgroundJobGetResultAtServer()
	
	If BackgroundJobExecutionResult <> Undefined Then
		BackgroundJobExecutionResult.Insert("AdditionalResultData", New Structure);
		ErrorMessage = "";
		StandardErrorPresentation = NStr("ru = 'При изменении регистрации произошла ошибка. Подробности см. в журнале регистрации'; en = 'An error occurred when changing registration. For more information, see the event log'; pl = 'Podczas zmiany rejestracji wystąpił błąd. Szczegóły można znaleźć w dzienniku rejestracji';de = 'Beim Ändern der Registrierung ist ein Fehler aufgetreten. Einzelheiten finden Sie im Ereignisprotokoll';ro = 'Eroare la modificarea înregistrării. Detalii vezi în registrul logare';tr = 'Kayıt değiştiğinde bir hata oluştu.  Detaylar için kayıt günlüğüne bakın'; es_ES = 'Al cambiar el registro se ha producido un error. Véase más en el registro'");
		
		If BackgroundJobExecutionResult.Status = "Error" Then
			ErrorMessage = BackgroundJobExecutionResult.DetailedErrorPresentation;
		Else
			BackgroundExecutionResult = GetFromTempStorage(BackgroundJobStorageAddress);
			
			If BackgroundExecutionResult = Undefined Then
				ErrorMessage = StandardErrorPresentation;
			Else
				BackgroundJobExecutionResult.AdditionalResultData = BackgroundExecutionResult;
				DeleteFromTempStorage(BackgroundJobStorageAddress);
			EndIf;
		EndIf;
	EndIf;
	
	BackgroundJobStorageAddress = Undefined;
	BackgroundJobID  = Undefined;
	
EndProcedure

&AtServerNoContext
Procedure EndExecutingTimeConsumingOperation(JobID)
	ModuleTimeConsumingOperations = CommonModuleTimeConsumingOperations();
	ModuleTimeConsumingOperations.CancelJobExecution(JobID);
EndProcedure

// Returns a reference to the TimeConsumingOperationsClient common module.
//
// Returns:
//  CommonModule - the TimeConsumingOperationsClient common module.
//
&AtClient
Function CommonModuleTimeConsumingOperationsClient()
	
	// Calling CalculateInSafeMode is not required as a string literal is being passed for calculation.
	Module = Eval("TimeConsumingOperationsClient");
	
	If TypeOf(Module) <> Type("CommonModule") Then
		Raise NStr("ru = 'Общий модуль ""ДлительныеОперацииКлиент"" не найден.'; en = 'Common module TimeConsumingOperationsClient is not found.'; pl = 'Wspólny moduł ""DługieOperacjeKlient"" nie został znaleziony.';de = 'Das allgemeine Modul ""LangfristigerBetriebsClient"" wurde nicht gefunden.';ro = 'Modulul comun ""ДлительныеОперацииКлиент"" nu a fost găsit.';tr = 'Ortak modül ""Uzunİşlemlerİstemci"" bulunamadı.'; es_ES = 'Módulo común TimeConsumingOperationsClient no se ha encontrado.'");
	EndIf;
	
	Return Module;
	
EndFunction

// Returns a reference to the TimeConsumingOperations common module.
//
// Returns:
//  CommonModule - the TimeConsumingOperations common module.
//
&AtServerNoContext
Function CommonModuleTimeConsumingOperations()

	If Metadata.CommonModules.Find("TimeConsumingOperations") <> Undefined Then
		// Calling CalculateInSafeMode is not required as a string literal is being passed for calculation.
		Module = Eval("TimeConsumingOperations");
	Else
		Module = Undefined;
	EndIf;
	
	If TypeOf(Module) <> Type("CommonModule") Then
		Raise NStr("ru = 'Общий модуль ""ДлительныеОперации"" не найден.'; en = 'Common module TimeConsumingOperations is not found.'; pl = 'Wspólny moduł ""DługieOperacje"" nie został znaleziony.';de = 'Das allgemeine Modul ""LangristigerBetrieb"" wurde nicht gefunden.';ro = 'Modulul comun ""ДлительныеОперации"" nu a fost găsit.';tr = 'Ortak modül ""Uzunİşlemler"" bulunamadı.'; es_ES = 'Módulo común TimeConsumingOperations no se ha encontrado.'");
	EndIf;
	
	Return Module;
	
EndFunction

&AtClient
Procedure DataChoiceProcessing(FormTable, SelectedValue)
	
	Ref = Undefined;
	Type    = TypeOf(SelectedValue);
	
	If Type = Type("Structure") Then
		If Not (SelectedValue.Property("TableName")
			AND SelectedValue.Property("ChoiceAction")
			AND SelectedValue.Property("ChoiceData")) Then
			// Waiting for the structure in the specified format.
			Return;
		EndIf;
		TableName = SelectedValue.TableName;
		Action   = SelectedValue.ChoiceAction;
		Data     = SelectedValue.ChoiceData;
	Else
		TableName = Undefined;
		Action = True;
		If Type = Type("Array") Then
			Data = SelectedValue;
		Else		
			Data = New Array;
			Data.Add(SelectedValue);
		EndIf;
		
		If Data.Count() = 1 Then
			Ref = Data[0];
		EndIf;
	EndIf;
	
	If Action Then
		Result = AddRegistrationAtServer(True, Data, TableName);
		
		FormTable.Refresh();
		FillRegistrationCountInTreeRows();
		ReportRegistrationResults(Result);
		
		FormTable.CurrentRow = Ref;
		Return;
	EndIf;
	
	If Ref = Undefined Then
		Text = NStr("ru = 'Отменить регистрацию выбранных объектов
		                 |на узле ""%1?'; 
		                 |en = 'Cancel registration of the selected objects
		                 |on node ""%1""?'; 
		                 |pl = 'Anulować rejestrację wybranych obiektów
		                 |na węźle ""%1""?';
		                 |de = 'Rückgängig machen der Registrierung ausgewählter Objekte
		                 |auf dem Knoten ""%1?';
		                 |ro = 'Revocați înregistrarea obiectelor selectate
		                 |pe nodul ""%1""?';
		                 |tr = '"
" ünitede %1 seçilmiş nesnelerin kaydı iptal edilsin mi?'; 
		                 |es_ES = '¿Cancelar el registro de los objetos seleccionados
		                 | en el nodo ""%1?'"); 
	Else
		Text = NStr("ru = 'Отменить регистрацию ""%2""
		                 |на узле ""%1?'; 
		                 |en = 'Cancel registration of ""%2""
		                 |on node ""%1?'; 
		                 |pl = 'Anulować rejestrację ""%2""
		                 |na węźle ""%1""?';
		                 |de = 'Registrierung ""%2""
		                 |auf dem Knoten ""%1abbrechen?';
		                 |ro = 'Revocați înregistrarea ""%2""
		                 |pe nodul ""%1""?';
		                 |tr = '"
" ünitede%2 %1 kaydı iptal edilsin mi?'; 
		                 |es_ES = '¿Cancelar el registro ""%2""
		                 |en el nodo ""%1?'"); 
	EndIf;
		
	Text = StrReplace(Text, "%1", ExchangeNodeRef);
	Text = StrReplace(Text, "%2", Ref);
	
	QuestionTitle = NStr("ru = 'Подтверждение'; en = 'Confirm operation'; pl = 'Potwierdzenie';de = 'Bestätigung';ro = 'Confirmare';tr = 'Onay'; es_ES = 'Confirmación'");
		
	Notification = New NotifyDescription("DataChoiceProcessingCompletion", ThisObject, New Structure);
	Notification.AdditionalParameters.Insert("Action",     Action);
	Notification.AdditionalParameters.Insert("FormTable", FormTable);
	Notification.AdditionalParameters.Insert("Data",       Data);
	Notification.AdditionalParameters.Insert("TableName",   TableName);
	Notification.AdditionalParameters.Insert("Ref",       Ref);
	
	ShowQueryBox(Notification, Text, QuestionDialogMode.YesNo, , ,QuestionTitle);
EndProcedure

// Dialog continuation notification handler.
&AtClient
Procedure DataChoiceProcessingCompletion(Val QuestionResult, Val AdditionalParameters) Export
	If QuestionResult <> DialogReturnCode.Yes Then
		Return;
	EndIf;
	If Object.AsynchronousRegistrationAvailable Then
		BackgroundJobParameters = PrepareRegistrationChangeParameters(False, True, AdditionalParameters.Data, 
										AdditionalParameters.TableName);
		BackgroundJobStartClient(BackgroundJobParameters);
	Else
		Result = DeleteRegistrationAtServer(True, AdditionalParameters.Data, AdditionalParameters.TableName);
	
		AdditionalParameters.FormTable.Refresh();
		FillRegistrationCountInTreeRows();
		ReportRegistrationResults(Result);
	EndIf;
	
	AdditionalParameters.FormTable.CurrentRow = AdditionalParameters.Ref;
EndProcedure

&AtServer
Procedure UpdatePageContent(Page = Undefined)
	CurrRow = ?(Page = Undefined, Items.ObjectsListOptions.CurrentPage, Page);
	
	If CurrRow = Items.ReferencesListPage Then
		Items.RefsList.Refresh();
		
	ElsIf CurrRow = Items.ConstantsPage Then
		Items.ConstantsList.Refresh();
		
	ElsIf CurrRow = Items.RecordSetPage Then
		Items.RecordSetsList.Refresh();
		
	ElsIf CurrRow = Items.BlankPage Then
		Row = Items.MetadataTree.CurrentRow;
		If Row <> Undefined Then
			Data = MetadataTree.FindByID(Row);
			If Data <> Undefined Then
				SetUpEmptyPage(Data.Description, Data.MetaFullName);
			EndIf;
		EndIf;
	EndIf;
EndProcedure	

&AtClient
Function GetCurrentObjectToEdit()
	
	CurrRow = Items.ObjectsListOptions.CurrentPage;
	
	If CurrRow = Items.ReferencesListPage Then
		Data = Items.RefsList.CurrentData;
		If Data <> Undefined Then
			Return Data.Ref; 
		EndIf;
		
	ElsIf CurrRow = Items.ConstantsPage Then
		Data = Items.ConstantsList.CurrentData;
		If Data <> Undefined Then
			Return Data.MetaFullName; 
		EndIf;
		
	ElsIf CurrRow = Items.RecordSetPage Then
		Data = Items.RecordSetsList.CurrentData;
		If Data <> Undefined Then
			Result = New Structure;
			Dimensions = RecordSetKeyNameArray(RecordSetsListTableName);
			For Each Name In Dimensions  Do
				Result.Insert(Name, Data["RecordSetsList" + Name]);
			EndDo;
		EndIf;
		Return Result;
		
	EndIf;
	
	Return Undefined;
	
EndFunction

&AtClient
Procedure OpenDataProcessorSettingsForm()
	CurFormName = ThisFormName + "Form.Settings";
	OpenForm(CurFormName, , ThisObject);
EndProcedure

&AtClient
Procedure ActionWithQueryResult(ActionCommand)
	
	CurFormName = GetQueryResultChoiceForm();
	If CurFormName <> Undefined Then
		// Opening form
		If ActionCommand Then
			Text = NStr("ru = 'Регистрация изменений результата запроса'; en = 'Registering query result changes'; pl = 'Rejestracja zmian wyników zapytania';de = 'Registrierung von Abfrageergebnisänderungen';ro = 'Înregistrarea modificărilor rezultatului interogării';tr = 'Sorgu sonucu değişikliklerinin kaydı'; es_ES = 'Registro de los cambios del resultado de la solicitud'");
		Else
			Text = NStr("ru = 'Отмена регистрации изменений результата запроса'; en = 'Canceling query result change registration'; pl = 'Anuluj rejestrację zmian wyniku zapytania';de = 'Brechen Sie die Registrierung der Änderung des Anforderungsergebnisses ab';ro = 'Revocarea înregistrării modificărilor rezultatului interogării';tr = 'İstek sonucu değişikliklerinin kaydını iptal et'; es_ES = 'Cancelar el registro de los cambios del resultado de la solicitud'");
		EndIf;
		ParametersStructure = New Structure();
		ParametersStructure.Insert("Title", Text);
		ParametersStructure.Insert("ChoiceAction", ActionCommand);
		ParametersStructure.Insert("ChoiceMode", True);
		ParametersStructure.Insert("CloseOnChoice", False);
		
		If Not ValueIsFilled(QueryResultChoiceFormUniqueKey) Then
			QueryResultChoiceFormUniqueKey = New UUID;
		EndIf;
		
		OpenForm(CurFormName, ParametersStructure, ThisObject, QueryResultChoiceFormUniqueKey);
		Return;
	EndIf;
	
	// If the query execution handler is not specified, prompting the user to specify it.
	Text = NStr("ru = 'В настройках не указана обработка для выполнения запросов.
	                        |Настроить сейчас?'; 
	                        |en = 'Data processor for queries is not specified in settings.
	                        |Set it now?'; 
	                        |pl = 'Przetwarzanie danych nie jest określone w ustawieniach.
	                        |Dostosować teraz?';
	                        |de = 'Der Datenprozessor für die Ausführung von Abfragen ist in den Einstellungen nicht angegeben.
	                        |Jetzt anpassen?';
	                        |ro = 'În setări nu este indicată procesarea pentru executarea interogărilor.
	                        |Setați acum?';
	                        |tr = 'Ayarlarda sorgu yürütmek için işlem belirtilmemiş. 
	                        |Şimdi özelleştirilsin mi?'; 
	                        |es_ES = 'Procesador de datos para la ejecución de solicitudes no está especificado en las configuraciones.
	                        |¿Personalizar ahora?'");
	
	QuestionTitle = NStr("ru = 'Настройки'; en = 'Settings'; pl = 'Ustawienia';de = 'Einstellungen';ro = 'Setări';tr = 'Ayarlar'; es_ES = 'Configuraciones'");

	Notification = New NotifyDescription("ActionWithQueryResultsCompletion", ThisObject);
	ShowQueryBox(Notification, Text, QuestionDialogMode.YesNo, , , QuestionTitle);
EndProcedure

// Dialog continuation notification handler.
&AtClient 
Procedure ActionWithQueryResultsCompletion(Val QuestionResult, Val AdditionalParameters) Export
	If QuestionResult <> DialogReturnCode.Yes Then
		Return;
	EndIf;
	
	OpenDataProcessorSettingsForm();
EndProcedure

&AtServer
Function ProcessQuotationMarksInRow(Row)
	Return StrReplace(Row, """", """""");
EndFunction

&AtServer
Function ThisObject(CurrentObject = Undefined) 
	If CurrentObject = Undefined Then
		Return FormAttributeToValue("Object");
	EndIf;
	ValueToFormAttribute(CurrentObject, "Object");
	Return Undefined;
EndFunction

&AtServer
Function GetFormName(CurrentObject = Undefined)
	Return ThisObject().GetFormName(CurrentObject);
EndFunction

&AtServer
Procedure ChangeMark(Row)
	DataItem = MetadataTree.FindByID(Row);
	ThisObject().ChangeMark(DataItem);
EndProcedure

&AtServer
Procedure ReadMetadataTree()
	Data = ThisObject().GenerateMetadataStructure(ExchangeNodeRef);
	
	// Deleting rows that cannot be edited.
	MetaTree = Data.Tree;
	For Each ListItem In NamesOfMetadataToHide Do
		DeleteMetadataValueTreeRows(ListItem.Value, MetaTree.Rows);
	EndDo;
	
	ValueToFormAttribute(MetaTree, "MetadataTree");
	MetadataAutoRecordStructure = Data.AutoRecordStructure;
	MetadataPresentationsStructure   = Data.PresentationsStructure;
	MetadataNamesStructure            = Data.NamesStructure;
EndProcedure

&AtServer 
Procedure DeleteMetadataValueTreeRows(Val MetaFullName, TreeRows)
	If IsBlankString(MetaFullName) Then
		Return;
	EndIf;
	
	// In the current set
	Filter = New Structure("MetaFullName", MetaFullName);
	For Each DeletionRow In TreeRows.FindRows(Filter, False) Do
		TreeRows.Delete(DeletionRow);
		// If there are no subordinate rows left, deleting the parent row.
		If TreeRows.Count() = 0 Then
			ParentString = TreeRows.Parent;
			If ParentString.Parent <> Undefined Then
				ParentString.Parent.Rows.Delete(ParentString);
				// There are no subordinate rows.
				Return;
			EndIf;
		EndIf;
	EndDo;
	
	// Deleting subordinate row recursively.
	For Each TreeRow In TreeRows Do
		DeleteMetadataValueTreeRows(MetaFullName, TreeRow.Rows);
	EndDo;
EndProcedure

&AtServer
Procedure FormatChangeCount(Row)
	Row.ChangeCountString = Format(Row.ChangeCount, "NZ=") + " / " + Format(Row.NotExportedCount, "NZ=");
EndProcedure

&AtServer
Procedure FillRegistrationCountInTreeRows()
	
	Data = ThisObject().GetChangeCount(MetadataNamesStructure, ExchangeNodeRef);
	
	// Calculating and filling the number of changes, the number of exported items, and the number of items that are not exported
	Filter = New Structure("MetaFullName, ExchangeNode", Undefined, ExchangeNodeRef);
	Zeros   = New Structure("ChangeCount, ExportedCount, NotExportedCount", 0,0,0);
	
	For Each Root In MetadataTree.GetItems() Do
		RootSum = New Structure("ChangeCount, ExportedCount, NotExportedCount", 0,0,0);
		
		For Each Folder In Root.GetItems() Do
			GroupSum = New Structure("ChangeCount, ExportedCount, NotExportedCount", 0,0,0);
			
			NodesList = Folder.GetItems();
			If NodesList.Count() = 0 AND MetadataNamesStructure.Property(Folder.MetaFullName) Then
				// Node collection without nodes, sum manually and take auto record from structure.
				For Each MetaName In MetadataNamesStructure[Folder.MetaFullName] Do
					Filter.MetaFullName = MetaName;
					Found = Data.FindRows(Filter);
					If Found.Count() > 0 Then
						Row = Found[0];
						GroupSum.ChangeCount     = GroupSum.ChangeCount     + Row.ChangeCount;
						GroupSum.ExportedCount   = GroupSum.ExportedCount   + Row.ExportedCount;
						GroupSum.NotExportedCount = GroupSum.NotExportedCount + Row.NotExportedCount;
					EndIf;
				EndDo;
				
			Else
				// Calculating count values for each node
				For Each Node In NodesList Do
					Filter.MetaFullName = Node.MetaFullName;
					Found = Data.FindRows(Filter);
					If Found.Count() > 0 Then
						Row = Found[0];
						FillPropertyValues(Node, Row, "ChangeCount, ExportedCount, NotExportedCount");
						GroupSum.ChangeCount     = GroupSum.ChangeCount     + Row.ChangeCount;
						GroupSum.ExportedCount   = GroupSum.ExportedCount   + Row.ExportedCount;
						GroupSum.NotExportedCount = GroupSum.NotExportedCount + Row.NotExportedCount;
					Else
						FillPropertyValues(Node, Zeros);
					EndIf;
					
					FormatChangeCount(Node);
				EndDo;
				
			EndIf;
			FillPropertyValues(Folder, GroupSum);
			
			RootSum.ChangeCount     = RootSum.ChangeCount     + Folder.ChangeCount;
			RootSum.ExportedCount   = RootSum.ExportedCount   + Folder.ExportedCount;
			RootSum.NotExportedCount = RootSum.NotExportedCount + Folder.NotExportedCount;
			
			FormatChangeCount(Folder);
		EndDo;
		
		FillPropertyValues(Root, RootSum);
		
		FormatChangeCount(Root);
	EndDo;
	
EndProcedure

&AtServer
Function ChangeQueryResultRegistrationServer(Command, Address)
	
	Result = GetFromTempStorage(Address);
	Result= Result[Result.UBound()];
	Data = Result.Unload().UnloadColumn("Ref");
	
	If Command Then
		Return AddRegistrationAtServer(True, Data);
	EndIf;
		
	Return DeleteRegistrationAtServer(True, Data);
EndFunction

&AtServer
Function RefControlForQuerySelection(Address)
	
	Result = ?(Address = Undefined, Undefined, GetFromTempStorage(Address));
	If TypeOf(Result) = Type("Array") Then 
		Result = Result[Result.UBound()];	
		If Result.Columns.Find("Ref") = Undefined Then
			Return NStr("ru = 'В последнем результате запроса отсутствует колонка ""Ссылка""'; en = 'There is no column Ref in a last query result'; pl = 'W ostatnim wyniku zapytania brakuje kolumny ""Link"".';de = 'Die Spalte ""Ref"" fehlt im letzten Abfrageergebnis.';ro = 'În ultimul rezultat al interogării lipsește coloana ""Referința""';tr = 'Son sorgu sonucunda ""Ref"" sütunu eksik.'; es_ES = 'Columna ""Referencia"" está faltando en el último resultado de la solicitud.'");
		EndIf;
	Else		
		Return NStr("ru = 'Ошибка получения данных результата запроса'; en = 'Error getting query result data'; pl = 'Wystąpił błąd podczas odbierania danych wynikowych zapytania';de = 'Beim Empfang der Abfrageergebnisdaten ist ein Fehler aufgetreten';ro = 'Eroare de obținere a datelor rezultatului interogării';tr = 'Sorgu sonucu verileri alınırken bir hata oluştu'; es_ES = 'Ha ocurrido un error al recibir los datos del resultado de la solicitud'");
	EndIf;
	
	Return "";
EndFunction

&AtServer
Procedure SetUpChangeEditingServer(CurrentRow)
	
	Data = MetadataTree.FindByID(CurrentRow);
	If Data = Undefined Then
		Return;
	EndIf;
	
	TableName   = Data.MetaFullName;
	Description = Data.Description;
	CurrentObject   = ThisObject();
	
	If IsBlankString(TableName) Then
		Meta = Undefined;
	Else		
		Meta = CurrentObject.MetadataByFullName(TableName);
	EndIf;
	
	If Meta = Undefined Then
		SetUpEmptyPage(Description, TableName);
		NewPage = Items.BlankPage;
		
	ElsIf Meta = Metadata.Constants Then
		// All constants are included in the list
		SetUpConstantList();
		NewPage = Items.ConstantsPage;
		
	ElsIf TypeOf(Meta) = Type("MetadataObjectCollection") Then
		// All catalogs, all documents, and so on
		SetUpEmptyPage(Description, TableName);
		NewPage = Items.BlankPage;
		
	ElsIf Metadata.Constants.Contains(Meta) Then
		// Single constant
		SetUpConstantList(TableName, Description);
		NewPage = Items.ConstantsPage;
		
	ElsIf Metadata.Catalogs.Contains(Meta) 
		Or Metadata.Documents.Contains(Meta)
		Or Metadata.ChartsOfCharacteristicTypes.Contains(Meta)
		Or Metadata.ChartsOfAccounts.Contains(Meta)
		Or Metadata.ChartsOfCalculationTypes.Contains(Meta)
		Or Metadata.BusinessProcesses.Contains(Meta)
		Or Metadata.Tasks.Contains(Meta) Then
		// Reference type
		SetUpRefList(TableName, Description);
		NewPage = Items.ReferencesListPage;
		
	Else
		// Checking whether a record set is passed
		Dimensions = CurrentObject.RecordSetDimensions(TableName);
		If Dimensions <> Undefined Then
			SetUpRecordSet(TableName, Dimensions, Description);
			NewPage = Items.RecordSetPage;
		Else
			SetUpEmptyPage(Description, TableName);
			NewPage = Items.BlankPage;
		EndIf;
		
	EndIf;
	
	Items.ConstantsPage.Visible    = False;
	Items.ReferencesListPage.Visible = False;
	Items.RecordSetPage.Visible = False;
	Items.BlankPage.Visible       = False;
	
	Items.ObjectsListOptions.CurrentPage = NewPage;
	NewPage.Visible = True;
	
	SetUpGeneralMenuCommandVisibility();
EndProcedure

// Displaying changes for a reference type (catalog, document, chart of characteristic types, chart 
// of accounts, calculation type, business processes, tasks.
//
&AtServer
Procedure SetUpRefList(TableName, Description)
	
	ListProperties = DynamicListPropertiesStructure();
	ListProperties.DynamicDataRead = True;
	ListProperties.QueryText = 
	"SELECT
	|	ChangesTable.Ref AS Ref,
	|	ChangesTable.MessageNo AS MessageNo,
	|	CASE
	|		WHEN ChangesTable.MessageNo IS NULL
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS NotExported,
	|	MainTable.Ref AS ObjectRef
	|FROM
	|	#ChangeTableName# AS ChangesTable
	|		LEFT JOIN #TableName# AS MainTable
	|		ON (MainTable.Ref = ChangesTable.Ref)
	|WHERE
	|	ChangesTable.Node = &SelectedNode";
	
	ListProperties.QueryText = StrReplace(ListProperties.QueryText, "#TableName#", TableName);
	ListProperties.QueryText = StrReplace(ListProperties.QueryText, "#ChangeTableName#", TableName + ".Changes");
		
	SetDynamicListProperties(Items.RefsList, ListProperties);
	
	RefsList.Parameters.SetParameterValue("SelectedNode", ExchangeNodeRef);
	ReferencesListTableName = TableName;
	
	// Object presentation
	Meta = ThisObject().MetadataByFullName(TableName);
	CurTitle = Meta.ObjectPresentation;
	If IsBlankString(CurTitle) Then
		CurTitle = Description;
	EndIf;
	Items.ReferencesListRefPresentation.Title = CurTitle;
EndProcedure

// Displaying changes for constants.
//
&AtServer
Procedure SetUpConstantList(TableName = Undefined, Description = "")
	
	If TableName = Undefined Then
		// All constants
		Names = MetadataNamesStructure.Constants;
		Presentations = MetadataPresentationsStructure.Constants;
		AutoRegistration = MetadataAutoRecordStructure.Constants;
	Else
		Names = New Array;
		Names.Add(TableName);
		Presentations = New Array;
		Presentations.Add(Description);
		Index = MetadataNamesStructure.Constants.Find(TableName);
		AutoRegistration = New Array;
		AutoRegistration.Add(MetadataAutoRecordStructure.Constants[Index]);
	EndIf;
	
	// The limit to the number of tables must be considered.
	Text = "";
	For Index = 0 To Names.UBound() Do
		Name = Names[Index];
		Text = Text + ?(Text = "", "SELECT", "UNION ALL SELECT") + "
		|	" + Format(AutoRegistration[Index], "NZ=; NG=") + " AS AutoRecordPictureIndex,
		|	2                                                   AS PictureIndex,
		|
		|	""" + ProcessQuotationMarksInRow(Presentations[Index]) + """ AS Description,
		|	""" + Name +                                     """ AS MetaFullName,
		|
		|	ChangesTable.MessageNo AS MessageNo,
		|	CASE 
		|		WHEN ChangesTable.MessageNo IS NULL THEN TRUE ELSE FALSE
		|	END AS NotExported
		|FROM
		|	" + Name + ".Changes AS ChangesTable
		|WHERE
		|	ChangesTable.Node = &SelectedNode
		|";
	EndDo;
	
	ListProperties = DynamicListPropertiesStructure();
	ListProperties.DynamicDataRead = True;
	ListProperties.QueryText = 
	"SELECT
	|	AutoRecordPictureIndex, PictureIndex, MetaFullName, NotExported,
	|	Description, MessageNo
	|
	|{SELECT
	|	AutoRecordPictureIndex, PictureIndex, 
	|	Description, MetaFullName, 
	|	MessageNo, NotExported
	|}
	|
	|FROM (" + Text + ") Data
	|
	|{WHERE
	|	Description, MessageNo, NotExported
	|}";
	
	SetDynamicListProperties(Items.ConstantsList, ListProperties);
		
	ListItems = ConstantsList.Order.Items;
	If ListItems.Count() = 0 Then
		Item = ListItems.Add(Type("DataCompositionOrderItem"));
		Item.Field = New DataCompositionField("Description");
		Item.Use = True;
	EndIf;
	
	ConstantsList.Parameters.SetParameterValue("SelectedNode", ExchangeNodeRef);
EndProcedure	

// Displaying cap with an empty page
&AtServer
Procedure SetUpEmptyPage(Description, TableName = Undefined)
	
	If TableName = Undefined Then
		CountsText = "";
	Else
		Tree = FormAttributeToValue("MetadataTree");
		Row = Tree.Rows.Find(TableName, "MetaFullName", True);
		If Row <> Undefined Then
			CountsText = NStr("ru = 'Зарегистрировано объектов: %1
			                          |Выгружено объектов: %2
			                          |Не выгружено объектов: %3'; 
			                          |en = 'Objects registered: %1
			                          |Objects exported: %2
			                          |Objects not exported: %3'; 
			                          |pl = 'Zarejestrowano obiektów: %1
			                          |Wyładowano obiektów: %2 
			                          | Nie wyładowano obiektów: %3';
			                          |de = 'Registrierte Objekte: %1
			                          |Hochgeladene Objekte: %2
			                          |Nicht hochgeladene Objekte: %3';
			                          |ro = 'Obiecte înregistrate: %1
			                          |Obiecte descărcate: %2
			                          |Obiecte ne descărcate: %3';
			                          |tr = 'Kayıtlı nesneler:
			                          |%1 Dışa aktarılan nesneler: %2 
			                          |Dışa aktarılmayan nesneler: %3'; 
			                          |es_ES = 'Objetos registrados:%1
			                          |Objetos exportados: %2
			                          |Objetos no exportados: %3'");
	
			CountsText = StrReplace(CountsText, "%1", Format(Row.ChangeCount, "NFD=0; NZ="));
			CountsText = StrReplace(CountsText, "%2", Format(Row.ExportedCount, "NFD=0; NZ="));
			CountsText = StrReplace(CountsText, "%3", Format(Row.NotExportedCount, "NFD=0; NZ="));
		EndIf;
	EndIf;
	
	Text = NStr("ru = '%1.
	                 |
	                 |%2
	                 |Для регистрации или отмены регистрации обмена данными на узле
	                 |""%3""
	                 |выберите тип объекта слева в дереве метаданных и воспользуйтесь
	                 |командами ""Зарегистрировать"" или ""Отменить регистрацию""'; 
	                 |en = '%1.
	                 |
	                 |%2
	                 |To register or cancel registration of data exchange on node
	                 |""%3"",
	                 |select an object type in the metadata tree on the left and click
	                 |""Register"" or ""Cancel registration""'; 
	                 |pl = '%1.
	                 |
	                 |%2
	                 |Dla rejestracji lub anulowania rejestracji wymiany danych na węźle
	                 |""%3""
	                 |wybierz rodzaj obiektu po lewej stronie w drzewie metadanych i skorzystaj
	                 |z komend ""Zarejestrować"" lub ""Anulować rejestrację""';
	                 |de = '%1.
	                 |
	                 |%2
	                 |Um den Datenaustausch auf dem Knoten
	                 |""%3""
	                 |zu registrieren oder die Registrierung aufzuheben, wählen Sie links im Metadatenbaum den Objekttyp und verwenden Sie
	                 |die Befehle ""Registrieren"" oder ""Registrierung aufheben""';
	                 |ro = '%1.
	                 |
	                 |%2
	                 |Pentru înregistrare sau revocarea înregistrării schimbului de date pe nodul
	                 |""%3""
	                 |selectați tipul obiectului din stânga din arborele metadatelor și utilizați
	                 |comenzile ""Înregistrare"" sau ""Revocare înregistrarea""';
	                 |tr = '%1. 
	                 |
	                 |%2 
	                 |Ünite "
" üzerindeki veri değişiminin kaydını kaydetmek veya iptal etmek için,  
	                 |meta veri ağacındaki soldaki nesne türünü seçin ve %3""Kayıt"" veya 
	                 |""Kaydı  iptal et"" komutlarını kullanın.'; 
	                 |es_ES = '%1.
	                 |
	                 |%2
	                 |Para registrar o cancelar el registro del intercambio de datos en el nodo
	                 |""%3""
	                 |, seleccione el tipo de objeto a la izquierda en el árbol de metadatos, y utilizar
	                 |los comandos ""Registrar"" o ""Cancelar el registro""'");
		
	Text = StrReplace(Text, "%1", Description);
	Text = StrReplace(Text, "%2", CountsText);
	Text = StrReplace(Text, "%3", ExchangeNodeRef);
	Items.EmptyPageDecoration.Title = Text;
EndProcedure

// Displaying changes for record sets.
//
&AtServer
Procedure SetUpRecordSet(TableName, Dimensions, Description)
	
	ChoiceText = "";
	Prefix     = "RecordSetsList";
	For Each Row In Dimensions Do
		Name = Row.Name;
		ChoiceText = ChoiceText + ",ChangesTable." + Name + " AS " + Prefix + Name + Chars.LF;
		// Adding the prefix to exclude the MessageNo and NotExported dimensions.
		Row.Name = Prefix + Name;
	EndDo;
	
	ListProperties = DynamicListPropertiesStructure();
	ListProperties.DynamicDataRead = True;
	ListProperties.QueryText = 
	"SELECT ALLOWED
	|	ChangesTable.MessageNo AS MessageNo,
	|	CASE 
	|		WHEN ChangesTable.MessageNo IS NULL THEN TRUE ELSE FALSE
	|	END AS NotExported
	|
	|	" + ChoiceText + "
	|FROM
	|	" + TableName + ".Changes AS ChangesTable
	|WHERE
	|	ChangesTable.Node = &SelectedNode";
	
	SetDynamicListProperties(Items.RecordSetsList, ListProperties);
	
	RecordSetsList.Parameters.SetParameterValue("SelectedNode", ExchangeNodeRef);
	
	// Adding columns to the appropriate group.
	ThisObject().AddColumnsToFormTable(
		Items.RecordSetsList, 
		"MessageNo, NotExported, 
		|Order, Filter, Group, StandardPicture, Parameters, ConditionalAppearance",
		Dimensions,
		Items.RecordSetsListDimensionsGroup);
	
	RecordSetsListTableName = TableName;
EndProcedure

// Common filter by the MessageNumber field.
//
&AtServer
Procedure SetFilterByMessageNo(DynamList, Option)
	
	Field = New DataCompositionField("NotExported");
	// Iterating through the filter item list to delete a specific item.
	ListItems = DynamList.Filter.Items;
	Index = ListItems.Count();
	While Index > 0 Do
		Index = Index - 1;
		Item = ListItems[Index];
		If Item.LeftValue = Field Then 
			ListItems.Delete(Item);
		EndIf;
	EndDo;
	
	FilterItem = ListItems.Add(Type("DataCompositionFilterItem"));
	FilterItem.LeftValue = Field;
	FilterItem.ComparisonType  = DataCompositionComparisonType.Equal;
	FilterItem.Use = False;
	FilterItem.ViewMode = DataCompositionSettingsItemViewMode.Inaccessible;
	
	If Option = 1 Then 		// Exported
		FilterItem.RightValue = False;
		FilterItem.Use  = True;
		
	ElsIf Option = 2 Then	// Not exported
		FilterItem.RightValue = True;
		FilterItem.Use  = True;
		
	EndIf;
	
EndProcedure

&AtServer
Procedure SetUpGeneralMenuCommandVisibility()
	
	CurrRow = Items.ObjectsListOptions.CurrentPage;
	
	If CurrRow = Items.ConstantsPage Then
		Items.FormAddRegistrationForSingleObject.Enabled = True;
		Items.FormAddRegistrationFilter.Enabled         = False;
		Items.FormDeleteRegistrationForSingleObject.Enabled  = True;
		Items.FormDeleteRegistrationFilter.Enabled          = False;
		
	ElsIf CurrRow = Items.ReferencesListPage Then
		Items.FormAddRegistrationForSingleObject.Enabled = True;
		Items.FormAddRegistrationFilter.Enabled         = True;
		Items.FormDeleteRegistrationForSingleObject.Enabled  = True;
		Items.FormDeleteRegistrationFilter.Enabled          = True;
		
	ElsIf CurrRow = Items.RecordSetPage Then
		Items.FormAddRegistrationForSingleObject.Enabled = True;
		Items.FormAddRegistrationFilter.Enabled         = False;
		Items.FormDeleteRegistrationForSingleObject.Enabled  = True;
		Items.FormDeleteRegistrationFilter.Enabled          = False;
		
	Else
		Items.FormAddRegistrationForSingleObject.Enabled = False;
		Items.FormAddRegistrationFilter.Enabled         = False;
		Items.FormDeleteRegistrationForSingleObject.Enabled  = False;
		Items.FormDeleteRegistrationFilter.Enabled          = False;
		
	EndIf;
EndProcedure	

&AtServer
Function RecordSetKeyNameArray(TableName, NamesPrefix = "")
	Result = New Array;
	Dimensions = ThisObject().RecordSetDimensions(TableName);
	If Dimensions <> Undefined Then
		For Each Row In Dimensions Do
			Result.Add(NamesPrefix + Row.Name);
		EndDo;
	EndIf;
	Return Result;
EndFunction	

&AtServer
Function GetManagerByMetadata(TableName) 
	Details = ThisObject().MetadataCharacteristics(TableName);
	If Details <> Undefined Then
		Return Details.Manager;
	EndIf;
	Return Undefined;
EndFunction

&AtServer
Function SerializationText(Serialization)
	
	Text = New TextDocument;
	
	Record = New XMLWriter;
	For Each Item In Serialization Do
		Record.SetString("UTF-16");	
		Value = Undefined;
		
		If Item.TypeFlag = 1 Then
			// Metadata
			Manager = GetManagerByMetadata(Item.Data);
			Value = Manager.CreateValueManager();
			
		ElsIf Item.TypeFlag = 2 Then
			// Creating record set with a filter
			Manager = GetManagerByMetadata(RecordSetsListTableName);
			Value = Manager.CreateRecordSet();
			Filter = Value.Filter;
			For Each NameValue In Item.Data Do
				Filter[NameValue.Key].Set(NameValue.Value);
			EndDo;
			Value.Read();
			
		ElsIf Item.TypeFlag = 3 Then
			// Ref
			Value = Item.Data.GetObject();
			If Value = Undefined Then
				Value = New ObjectDeletion(Item.Data);
			EndIf;
		EndIf;
		
		WriteXML(Record, Value); 
		Text.AddLine(Record.Close());
	EndDo;
	
	Return Text;
EndFunction	

&AtServer
Function DeleteRegistrationAtServer(NoAutoRegistration, PermissionsToDelete, TableName = Undefined)
	RegistrationParameters = PrepareRegistrationChangeParameters(False, NoAutoRegistration, PermissionsToDelete, TableName);
	Return ThisObject().ChangeRegistration(RegistrationParameters);
EndFunction

&AtServer
Function AddRegistrationAtServer(NoAutoRegistration, PermissionsToAdd, TableName = Undefined)
	RegistrationParameters = PrepareRegistrationChangeParameters(True, NoAutoRegistration, PermissionsToAdd, TableName);
	Return ThisObject().ChangeRegistration(RegistrationParameters);
EndFunction

&AtServer
Function EditMessageNumberAtServer(MessageNumber, Data, TableName = Undefined)
	RegistrationParameters = PrepareRegistrationChangeParameters(MessageNumber, True, Data, TableName);
	Return ThisObject().ChangeRegistration(RegistrationParameters);
EndFunction

&AtServer
Function GetSelectedMetadataDetails(NoAutoRegistration, MetaGroupName = Undefined, MetaNodeName = Undefined)
    
	If MetaGroupName = Undefined AND MetaNodeName = Undefined Then
		// No item selected
		Text = NStr("ru = 'все объекты %1 по выбранной иерархии вида'; en = 'all objects %1 according to the selected hierarchy kind'; pl = 'wszystkie obiekty %1 według wybranej hierarchii rodzajowej';de = 'alle Objekte %1 nach der ausgewählten Hierarchieart';ro = 'toate obiectele %1 pentru ierarhia selectată de tipul';tr = 'Seçilen tür hiyerarşisine göre %1 tüm nesneler'; es_ES = 'todos objetos %1 por la jerarquía de tipos seleccionada'");
		
	ElsIf MetaGroupName <> Undefined AND MetaNodeName = Undefined Then
		// Only a group is specified.
		Text = "%2 %1";
		
	ElsIf MetaGroupName = Undefined AND MetaNodeName <> Undefined Then
		// Only a node is specified.
		Text = NStr("ru = 'все объекты %1 по выбранной иерархии вида'; en = 'all objects %1 according to the selected hierarchy kind'; pl = 'wszystkie obiekty %1 według wybranej hierarchii rodzajowej';de = 'alle Objekte %1 nach der ausgewählten Hierarchieart';ro = 'toate obiectele %1 pentru ierarhia selectată de tipul';tr = 'Seçilen tür hiyerarşisine göre %1 tüm nesneler'; es_ES = 'todos objetos %1 por la jerarquía de tipos seleccionada'");
		
	Else
		// A group and a node are specified, using these values to obtain a metadata presentation.
		Text = NStr("ru = 'все объекты типа ""%3"" %1'; en = 'all objects of type %3 %1'; pl = 'wszystkie obiekty typu ""%3"" %1';de = 'alle Objekte vom Typ ""%3"" %1';ro = 'toate obiectele de tipul ""%3"" %1';tr = '""%3""%1 tür tüm nesneler'; es_ES = 'todos objetos del tipo ""%3"" %1'");
		
	EndIf;
	
	If NoAutoRegistration Then
		FlagText = "";
	Else
		FlagText = NStr("ru = 'с признаком авторегистрации'; en = 'with autoregistration flag'; pl = 'z automatyczną flagą rejestracji';de = 'mit automatischer Registrierungs-Kennzeichnung';ro = 'cu indicele de înregistrare automată';tr = 'otomatik kayıt bayrağı ile'; es_ES = 'con la casilla del registro automático'");
	EndIf;
	
	Presentation = "";
	For Each KeyValue In MetadataPresentationsStructure Do
		If KeyValue.Key = MetaGroupName Then
			Index = MetadataNamesStructure[MetaGroupName].Find(MetaNodeName);
			Presentation = ?(Index = Undefined, "", KeyValue.Value[Index]);
			Break;
		EndIf;
	EndDo;
	
	Text = StrReplace(Text, "%1", FlagText);
	Text = StrReplace(Text, "%2", Lower(MetaGroupName));
	Text = StrReplace(Text, "%3", Presentation);
	
	Return TrimAll(Text);
EndFunction

&AtServer
Function GetCurrentRowMetadataNames(NoAutoRegistration) 
	
	Row = MetadataTree.FindByID(Items.MetadataTree.CurrentRow);
	If Row = Undefined Then
		Return Undefined;
	EndIf;
	
	Result = New Structure("MetaNames, Details", 
		New Array, GetSelectedMetadataDetails(NoAutoRegistration));
	MetaName = Row.MetaFullName;
	If IsBlankString(MetaName) Then
		Result.MetaNames.Add(Undefined);	
	Else
		Result.MetaNames.Add(MetaName);	
		
		Parent = Row.GetParent();
		MetaParentName = Parent.MetaFullName;
		If IsBlankString(MetaParentName) Then
			Result.Details = GetSelectedMetadataDetails(NoAutoRegistration, Row.Description);
		Else
			Result.Details = GetSelectedMetadataDetails(NoAutoRegistration, MetaParentName, MetaName);
		EndIf;
	EndIf;
	
	Return Result;
EndFunction

&AtServer
Function GetSelectedMetadataNames(NoAutoRegistration)
	
	Result = New Structure("MetaNames, Details", 
		New Array, GetSelectedMetadataDetails(NoAutoRegistration));
	
	For Each Root In MetadataTree.GetItems() Do
		
		If Root.Check = 1 Then
			Result.MetaNames.Add(Undefined);
			Return Result;
		EndIf;
		
		NumberOfPartial = 0;
		GroupsCount     = 0;
		NodeCount     = 0;
		For Each Folder In Root.GetItems() Do
			
			If Folder.Check = 0 Then
				Continue;
			ElsIf Folder.Check = 1 Then
				//	Getting data of the selected group.
				GroupsCount = GroupsCount + 1;
				GroupDetails = GetSelectedMetadataDetails(NoAutoRegistration, Folder.Description);
				
				If Folder.GetItems().Count() = 0 Then
					// Reading marked data from the metadata names structure.
					AutoArray = MetadataAutoRecordStructure[Folder.MetaFullName];
					NamesArray = MetadataNamesStructure[Folder.MetaFullName];
					For Index = 0 To NamesArray.UBound() Do
						If NoAutoRegistration Or AutoArray[Index] = 2 Then
							Result.MetaNames.Add(NamesArray[Index]);
							NodeDetails = GetSelectedMetadataDetails(NoAutoRegistration, Folder.MetaFullName, NamesArray[Index]);
						EndIf;
					EndDo;
					
					Continue;
				EndIf;
				
			Else
				NumberOfPartial = NumberOfPartial + 1;
			EndIf;
			
			For Each Node In Folder.GetItems() Do
				If Node.Check = 1 Then
					// Node.AutoRecord = 2 -> allowed
					If NoAutoRegistration Or Node.AutoRegistration = 2 Then
						Result.MetaNames.Add(Node.MetaFullName);
						NodeDetails = GetSelectedMetadataDetails(NoAutoRegistration, Folder.MetaFullName, Node.MetaFullName);
						NodeCount = NodeCount + 1;
					EndIf;
				EndIf
			EndDo;
			
		EndDo;
		
		If GroupsCount = 1 AND NumberOfPartial = 0 Then
			Result.Details = GroupDetails;
		ElsIf GroupsCount = 0 AND NodeCount = 1 Then
			Result.Details = NodeDetails;
		EndIf;
		
	EndDo;
	
	Return Result;
EndFunction

&AtServer
Function ReadMessageNumbers()
	
	QueryAttributes = "SentNo, ReceivedNo";
	
	Data = ThisObject().GetExchangeNodeParameters(ExchangeNodeRef, QueryAttributes);
	
	Return Data;
	
EndFunction

&AtServer
Procedure ProcessNodeChangeProhibition()
	OperationsAllowed = Not SelectExchangeNodeProhibited;
	
	If OperationsAllowed Then
		Items.ExchangeNodeRef.Visible = True;
		Title = NStr("ru = 'Регистрация изменений для обмена данными'; en = 'Record changes for data exchange'; pl = 'Rejestracja modyfikacji do wymiany danych';de = 'Registrierung von Änderungen für den Datenaustausch';ro = 'Înregistrarea modificărilor pentru schimbul de date';tr = 'Veri alışverişi için değişikliklerin kaydı'; es_ES = 'Registro de modificaciones para el intercambio de datos'");
	Else
		Items.ExchangeNodeRef.Visible = False;
		Title = StrReplace(NStr("ru = 'Регистрация изменений для обмена с  ""%1""'; en = 'Changes registration for exchange with ""%1""'; pl = 'Rejestracja zmian dla wymiany z ""%1""';de = 'Registrierung von Änderungen zum Austausch mit ""%1""';ro = 'Înregistrarea modificărilor pentru schimbul cu ""%1""';tr = '""%1"" ile veri alışverişi için değişiklikleri kaydedin'; es_ES = 'Registrar los cambios para intercambiar con ""%1""'"), "%1", String(ExchangeNodeRef));
	EndIf;
	
	Items.FormOpenNodeRegistrationForm.Visible = OperationsAllowed;
	
	Items.ConstantsListContextMenuOpenNodeRegistrationForm.Visible       = OperationsAllowed;
	Items.ReferencesListContextMenuOpenNodeRegistrationForm.Visible         = OperationsAllowed;
	Items.RecordSetsListContextMenuOpenNodeRegistrationForm.Visible = OperationsAllowed;
EndProcedure

&AtServer
Function ControlSettings()
	Result = True;
	
	// Checking a specified exchange node.
	CurrentObject = ThisObject();
	If ExchangeNodeRef <> Undefined AND ExchangePlans.AllRefsType().ContainsType(TypeOf(ExchangeNodeRef)) Then
		AllowedExchangeNodes = CurrentObject.GenerateNodeTree();
		PlanName = ExchangeNodeRef.Metadata().Name;
		If AllowedExchangeNodes.Rows.Find(PlanName, "ExchangePlanName", True) = Undefined Then
			// A node with an invalid exchange plan.
			ExchangeNodeRef = Undefined;
			Result = False;
		ElsIf ExchangeNodeRef = ExchangePlans[PlanName].ThisNode() Then
			// This node
			ExchangeNodeRef = Undefined;
			Result = False;
		EndIf;
	EndIf;
	
	If ValueIsFilled(ExchangeNodeRef) Then
		ExchangeNodeChoiceProcessingServer();
	EndIf;
	ProcessNodeChangeProhibition();
	
	// Settings relation
	SetFiltersInDynamicLists();
	
	Return Result;
EndFunction

&AtServer
Procedure SetFiltersInDynamicLists()
	SetFilterByMessageNo(ConstantsList,       FilterByMessageNumberOption);
	SetFilterByMessageNo(RefsList,         FilterByMessageNumberOption);
	SetFilterByMessageNo(RecordSetsList, FilterByMessageNumberOption);
EndProcedure

&AtServer
Function RecordSetKeyStructure(Val CurrentData)
	
	Details = ThisObject().MetadataCharacteristics(RecordSetsListTableName);
	
	If Details = Undefined Then
		// Unknown source
		Return Undefined;
	EndIf;
	
	Result = New Structure("FormName, Parameter, Value");
	
	Dimensions = New Structure;
	KeysNames = RecordSetKeyNameArray(RecordSetsListTableName);
	For Each Name In KeysNames Do
		Dimensions.Insert(Name, CurrentData["RecordSetsList" + Name]);
	EndDo;
	
	If Dimensions.Property("Recorder") Then
		MetaRecorder = Metadata.FindByType(TypeOf(Dimensions.Recorder));
		If MetaRecorder = Undefined Then
			Result = Undefined;
		Else
			Result.FormName = MetaRecorder.FullName() + ".ObjectForm";
			Result.Parameter = "Key";
			Result.Value = Dimensions.Recorder;
		EndIf;
		
	ElsIf Dimensions.Count() = 0 Then
		// Degenerated record set
		Result.FormName = RecordSetsListTableName + ".ListForm";
		
	Else
		Set = Details.Manager.CreateRecordSet();
		For Each KeyValue In Dimensions Do
			Set.Filter[KeyValue.Key].Set(KeyValue.Value);
		EndDo;
		Set.Read();
		If Set.Count() = 1 Then
			// Single item
			Result.FormName = RecordSetsListTableName + ".RecordForm";
			Result.Parameter = "Key";
			
			varKey = New Structure;
			For Each SetColumn In Set.Unload().Columns Do
				ColumnName = SetColumn.Name;
				varKey.Insert(ColumnName, Set[0][ColumnName]);
			EndDo;
			Result.Value = Details.Manager.CreateRecordKey(varKey);
		Else
			// List
			Result.FormName = RecordSetsListTableName + ".ListForm";
			Result.Parameter = "Filter";
			Result.Value = Dimensions;
		EndIf;
		
	EndIf;
	
	Return Result;
EndFunction

&AtServer
Procedure CheckPlatformVersionAndCompatibilityMode()
	
	Information = New SystemInfo;
	If Not (Left(Information.AppVersion, 3) = "8.3"
		AND (Metadata.CompatibilityMode = Metadata.ObjectProperties.CompatibilityMode.DontUse
		Or (Metadata.CompatibilityMode <> Metadata.ObjectProperties.CompatibilityMode.Version8_1
		AND Metadata.CompatibilityMode <> Metadata.ObjectProperties.CompatibilityMode.Version8_2_13
		AND Metadata.CompatibilityMode <> Metadata.ObjectProperties.CompatibilityMode["Version8_2_16"]
		AND Metadata.CompatibilityMode <> Metadata.ObjectProperties.CompatibilityMode["Version8_3_1"]
		AND Metadata.CompatibilityMode <> Metadata.ObjectProperties.CompatibilityMode["Version8_3_2"]
		AND Metadata.CompatibilityMode <> Metadata.ObjectProperties.CompatibilityMode["Version8_3_3"]
		AND Metadata.CompatibilityMode <> Metadata.ObjectProperties.CompatibilityMode["Version8_3_4"]))) Then
		
		Raise NStr("ru = 'Обработка предназначена для запуска на версии платформы
			|1С:Предприятие 8.3.5 с отключенным режимом совместимости или выше'; 
			|en = 'The data processor is intended for use with 
			|1C:Enterprise 8.3.5 or later, with disabled compatibility mode'; 
			|pl = 'Przetwarzanie jest przeznaczona do uruchomienia na wersji platformy 
			|1C:Enterprise 8.3.5 z odłączonym trybem kompatybilności lub wyżej';
			|de = 'Die Verarbeitung ist für
			|1C: Enterprise 8.3.5-Plattformversionen mit deaktiviertem oder höherem Kompatibilitätsmodus ausgelegt';
			|ro = 'Procesarea este destinată pentru lansare pe versiunea platformei
			|1C:Enterprise 8.3.5 cu regimul de compatibilitate dezactivat sau mai sus';
			|tr = 'İşlem, 
			|1C: İşletme 8.3 platform sürümü (veya üzeri) uyumluluk modu kapalı olarak başlamak için kullanılır'; 
			|es_ES = 'El procesamiento se utiliza para lanzar en la versión de la plataforma
			|1C:Enterprise 8.3.5 con el modo de compatibilidad desactivado o superior'");
		
	EndIf;
	
EndProcedure

&AtServer
Function RegisterMOIDAndPredefinedItemsAtServer()
	
	CurrentObject = ThisObject();
	Return CurrentObject.SSL_UpdateAndRegisterMasterNodeMetadataObjectID(ExchangeNodeRef);
	
EndFunction

&AtServer
Function PrepareRegistrationChangeParameters(Command, NoAutoRegistration, Data, TableName = Undefined)
	Result = New Structure;
	Result.Insert("Command", Command);
	Result.Insert("NoAutoRegistration", NoAutoRegistration);
	Result.Insert("Node", ExchangeNodeRef);
	Result.Insert("Data", Data);
	Result.Insert("TableName", TableName);
	
	Result.Insert("ConfigurationSupportsSSL",       Object.ConfigurationSupportsSSL);
	Result.Insert("RegisterWithSSLMethodsAvailable",  Object.RegisterWithSSLMethodsAvailable);
	Result.Insert("DIBModeAvailable",                 Object.DIBModeAvailable);
	Result.Insert("ObjectExportControlSetting", Object.ObjectExportControlSetting);
	Return Result;
EndFunction

&AtServer
Procedure AddNameOfMetadataToHide()
	// Registers with the Node dimension are hidden
	For Each InformationRegisterMetadata In Metadata.InformationRegisters Do
		For Each RegisterDimension In Metadata.InformationRegisters[InformationRegisterMetadata.Name].Dimensions Do
			If Lower(RegisterDimension.Name) = "node" Then
				NamesOfMetadataToHide.Add("InformationRegister." + InformationRegisterMetadata.Name);
				Break;
			EndIf;
		EndDo;
	EndDo;
EndProcedure

&AtServer
Procedure SetDynamicListProperties(List, ParametersStructure)
	
	Form = List.Parent;
	ManagedFormType = Type("ManagedForm");
	
	While TypeOf(Form) <> ManagedFormType Do
		Form = Form.Parent;
	EndDo;
	
	DynamicList = Form[List.DataPath];
	QueryText = ParametersStructure.QueryText;
	
	If Not IsBlankString(QueryText) Then
		DynamicList.QueryText = QueryText;
	EndIf;
	
	MainTable = ParametersStructure.MainTable;
	
	If Not IsBlankString(MainTable) Then
		DynamicList.MainTable = MainTable;
	EndIf;
	
	DynamicDataRead = ParametersStructure.DynamicDataRead;
	
	If TypeOf(DynamicDataRead) = Type("Boolean") Then
		DynamicList.DynamicDataRead = DynamicDataRead;
	EndIf;
	
EndProcedure

&AtServer
Function DynamicListPropertiesStructure()
	
	Return New Structure("QueryText, MainTable, DynamicDataRead");
	
EndFunction

#EndRegion
