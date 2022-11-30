///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

// There are two ways to parameterize a form:
//
// Option 1
//     Parameters:
//         InfobaseNode - ExchangePlanObject - an exchange plan node for which the wizard is executed.
//         ExportAdditionExtendedMode - Boolean           - indicates whether the export addition 
//                                                                 setup by node scenario is enabled.
//
// Case 2:
//     Parameters:
//         InfobaseNodeCode          - String           - an exchange plan node code, for which the wizard will be opened. 
//         ExchangePlanName                     - String           - a name of an exchange plan to 
//                                                                 use for searching an exchange 
//                                                                 plan node whose code is specified in the InfobaseNodeCode parameter.
//         ExportAdditionExtendedMode - Boolean           - indicates whether the export addition 
//                                                                 setup by node scenario is enabled.
//
#Region Variables

&AtClient
Var SkipCurrentPageCancelControl;

#EndRegion

#Region EventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	IsStartedFromAnotherApplication = False;
	
	If Parameters.Property("InfobaseNode", Object.InfobaseNode) Then
		
		Object.ExchangePlanName = DataExchangeCached.GetExchangePlanName(Object.InfobaseNode);
		
	ElsIf Parameters.Property("InfobaseNodeCode") Then
		
		IsStartedFromAnotherApplication = True;
		
		Object.InfobaseNode = DataExchangeServer.ExchangePlanNodeByCode(
			Parameters.ExchangePlanName, Parameters.InfobaseNodeCode);
		
		If Not ValueIsFilled(Object.InfobaseNode) Then
			Raise NStr("ru = 'Настройка обмена данными не найдена.'; en = 'The data exchange setting is not found.'; pl = 'Ustawienia wymiany danych nie zostały znalezione.';de = 'Datenaustauscheinstellung wurde nicht gefunden.';ro = 'Setarea schimbului de date nu a fost găsită.';tr = 'Veri değişimi ayarı bulunmadı.'; es_ES = 'Configuración del intercambio de datos no se ha encontrado.'");
		EndIf;
		
		Object.ExchangePlanName = Parameters.ExchangePlanName;
		
	Else
		
		Raise NStr("ru = 'Непосредственное открытие помощника не предусмотрено.'; en = 'The wizard cannot be opened manually.'; pl = 'Kreatora nie można otworzyć bezpośrednio.';de = 'Der Assistent kann nicht geöffnet werden.';ro = 'Deschiderea nemijlocită a asistentului nu este prevăzută.';tr = 'Sihirbaz açılamıyor.'; es_ES = 'Asistente no puede abrirse.'");
		
	EndIf;
	
	// Interactive data exchange is supported only for universal exchanges.
	If Not DataExchangeCached.IsUniversalDataExchangeNode(Object.InfobaseNode) Then
		Raise NStr("ru = 'Для выбранного узла выполнение обмена данными с настройкой не предусмотрено.'; en = 'The selected node does not support settings-based data exchange.'; pl = 'Wykonanie wymiany danych za pomocą tego ustawienia nie jest wymagane dla wybranego węzła.';de = 'Die Ausführung des Datenaustauschs mit der Einstellung ist für den ausgewählten Knoten nicht erforderlich.';ro = 'Pentru nodul selectat executarea schimbului de date cu setarea nu este prevăzută.';tr = 'Seçilen ünite için ayar ile veri değişimi uygulaması gerekli değildir.'; es_ES = 'No se requiere la ejecución del intercambio de datos con la configuración para el nodo seleccionado.'");
	EndIf;
	
	// Check whether exchange settings match the filter.
	AllNodes = DataExchangeEvents.AllExchangePlanNodes(Object.ExchangePlanName);
	If AllNodes.Find(Object.InfobaseNode) = Undefined Then
		Raise NStr("ru = 'Для выбранного узла сопоставление данных не предусмотрено.'; en = 'The selected node does not provide data mapping.'; pl = 'Mapowanie danych nie jest wymagane dla wybranego węzła.';de = 'Für den ausgewählten Knoten ist keine Datenzuordnung erforderlich.';ro = 'Pentru nodul selectat confruntarea datelor nu este prevăzută.';tr = 'Seçilen ünite için ayar ile veri eşlenmesi gerekli değildir.'; es_ES = 'No se requiere el mapeo de datos para el nodo seleccionado.'");
	EndIf;
	
	EmailReceivedForDataMapping = DataExchangeServer.MessageWithDataForMappingReceived(Object.InfobaseNode);
	
	If Not Parameters.Property("GetData", GetData) Then
		GetData = True;
	EndIf;
	
	If Not Parameters.Property("SendData", SendData) Then
		SendData = True;
	EndIf;
	
	If Not GetData AND Not SendData Then
		Raise NStr("ru = 'Заданный сценарий синхронизации данных не поддерживается.'; en = 'The data synchronization scenario is not supported.'; pl = 'Podany scenariusz synchronizacji danych nie jest obsługiwany.';de = 'Dieses Datensynchronisierungsszenario wird nicht unterstützt.';ro = 'Scenariul specificat de sincronizare a datelor nu este susținut.';tr = 'Bu veri senkronizasyon senaryosu desteklenmiyor.'; es_ES = 'Este escenario de la sincronización de datos no se admite.'");
	EndIf;
	
	SaaSModel = Common.DataSeparationEnabled()
		AND Common.SeparatedDataUsageAvailable();
		
	Parameters.Property("ExchangeMessagesTransportKind", Object.ExchangeMessagesTransportKind);	
	Parameters.Property("CorrespondentDataArea",  CorrespondentDataArea);
	
	Parameters.Property("ExportAdditionMode",            ExportAdditionMode);
	Parameters.Property("AdvancedExportAdditionMode", ExportAdditionExtendedMode);
	
	CheckVersionDifference = True;
	
	CorrespondentDescription = Common.ObjectAttributeValue(Object.InfobaseNode, "Description");
	
	SetFormHeader();
	
	InitializeScheduleSetupWizard(IsStartedFromAnotherApplication);
	
	If ExportAdditionMode Then
		InitializeExportAdditionAttributes();
	EndIf;
	
	InitializeExchangeMessagesTransportSettings();
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	SetNavigationNumber(1);
	
EndProcedure

&AtClient
Procedure BeforeClose(Cancel, Exit, WarningText, StandardProcessing)
	
	If ForceCloseForm Then
		Return;
	EndIf;

	CommonClient.ShowArbitraryFormClosingConfirmation(ThisObject, Cancel, Exit,
		NStr("ru = 'Выйти из помощника?'; en = 'Do you want to exit the wizard?'; pl = 'Wyjść z asystenta?';de = 'Den Assistenten verlassen?';ro = 'Părăsiți asistentul?';tr = 'Sihirbazdan çıkmak istiyor musunuz?'; es_ES = '¿Salir del ayudante?'"), "ForceCloseForm");
		
EndProcedure

&AtClient
Procedure OnClose(Exit)
	
	If Exit Then
		Return;
	EndIf;
	
	If TimeConsumingOperation Then
		EndExecutingTimeConsumingOperation(JobID);
	EndIf;
	
	If EmailReceivedForDataMapping Then
		If (EndDataMapping AND Not SkipGettingData)
			Or (DataImportResult = "Warning_ExchangeMessageAlreadyAccepted") Then
			DeleteMessageForDataMapping(Object.InfobaseNode);
		EndIf;
	EndIf;
	
	DeleteTempExchangeMessagesDirectory(Object.TempExchangeMessageCatalogName);
	
	If ValueIsFilled(FormReopeningParameters)
		AND FormReopeningParameters.Property("NewDataSynchronizationSetting") Then
		
		NewDataSynchronizationSetting = FormReopeningParameters.NewDataSynchronizationSetting;
		
		FormParameters = New Structure;
		FormParameters.Insert("InfobaseNode", NewDataSynchronizationSetting);
		FormParameters.Insert("AdvancedExportAdditionMode", True);
		
		OpeningParameters = New Structure;
		OpeningParameters.Insert("WindowOpeningMode", FormWindowOpeningMode.LockOwnerWindow);
		
		DataExchangeClient.OpenFormAfterClosingCurrentOne(ThisObject,
			"DataProcessor.InteractiveDataExchangeWizard.Form", FormParameters, OpeningParameters);
		
	Else
		Notify("ObjectMappingWizardFormClosed");
	EndIf;
	
EndProcedure

&AtClient
Procedure ChoiceProcessing(SelectedValue, ChoiceSource)
	
	// Checking whether the additional export item initialization event occurred.
	If DataExchangeClient.ExportAdditionChoiceProcessing(SelectedValue, ChoiceSource, ExportAddition) Then
		// Event is handled, updating filter details.
		SetExportAdditionFilterDescription();
		Return;
	EndIf;
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If EventName = "ObjectMappingFormClosing" Then
		
		Cancel = False;
		
		UpdateMappingStatisticsDataAtServer(Cancel, Parameter);
		
		If Cancel Then
			ShowMessageBox(, NStr("ru = 'При получении информации статистики возникли ошибки.'; en = 'Error gathering statistic data.'; pl = 'Podczas pobierania informacji statystycznej wystąpiły błędy.';de = 'Beim Empfang von Statistikinformationen sind Fehler aufgetreten.';ro = 'Au apărut erori la primirea informațiilor statistice.';tr = 'İstatistik bilgisi alınırken hatalar oluştu.'; es_ES = 'Errores ocurridos al recibir la información de estadística.'"));
		Else
			
			ExpandStatisticsTree(Parameter.UniqueKey);
			
			ShowUserNotification(NStr("ru = 'Сбор информации завершен'; en = 'Information collection is complete'; pl = 'Zbiór informacji został zakończony';de = 'Die Informationssammlung ist abgeschlossen';ro = 'Colectarea informațiilor este completă';tr = 'Bilgi toplama tamamlandı'; es_ES = 'Recopilación de información se ha finalizado'"));
		EndIf;
		
	EndIf;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

////////////////////////////////////////////////////////////////////////////////
// StartPage page

&AtClient
Procedure ExchangeMessagesTransportKindOnChange(Item)
	
	OnChangeExchangeMessagesTransportKind();
	
EndProcedure

&AtClient
Procedure ExchangeMessagesTransportKindClear(Item, StandardProcessing)
	
	StandardProcessing = False;
	
EndProcedure

&AtClient
Procedure DataExchangeDirectoryClick(Item)
	
	OpenNodeDataExchangeDirectory();
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// StatisticsPage page

&AtClient
Procedure EndMappingDataOnChange(Item)
	
	OnChangeFlagEndDataMapping();
	
EndProcedure

&AtClient
Procedure LoadMessageAfterMappingOnChange(Item)
	
	OnChangeFlagImportMessageAfterMapping();
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// QuestionAboutExportContentPage page

&AtClient
Procedure ExportAdditionExportVariantOnChange(Item)
	ExportAdditionExportVariantSetVisibility();
EndProcedure

&AtClient
Procedure ExportAdditionNodeScenarioFilterPeriodOnChange(Item)
	ExportAdditionNodeScenarioPeriodChanging();
EndProcedure

&AtClient
Procedure ExportAdditionGeneralDocumentPeriodClearing(Item, StandardProcessing)
	// Prohibiting period clearing
	StandardProcessing = False;
EndProcedure

&AtClient
Procedure ExportAdditionNodeScenarioFilterPeriodClearing(Item, StandardProcessing)
	// Prohibiting period clearing
	StandardProcessing = False;
EndProcedure

#EndRegion

#Region StatisticsTreeFormTableItemEventHandlers

&AtClient
Procedure StatisticsTreeChoice(Item, RowSelected, Field, StandardProcessing)
	
	OpenMappingForm(Undefined);
	
EndProcedure

#EndRegion

#Region FormCommandHandlers

&AtClient
Procedure NextCommand(Command)
	
	ChangeNavigationNumber(+1);
	
EndProcedure

&AtClient
Procedure CancelCommand(Command)
	
	Close();
	
EndProcedure

&AtClient
Procedure DoneCommand(Command)
	// Updating all opened dynamic lists.
	DataExchangeClient.RefreshAllOpenDynamicLists();
	
	Result = New Structure;
	Result.Insert("DataExportResult", DataExportResult);
	Result.Insert("DataImportResult", DataImportResult);
	
	ForceCloseForm = True;
	Close(Result);
	
EndProcedure

&AtClient
Procedure OpenScheduleSettings(Command)
	FormParameters = New Structure("InfobaseNode", Object.InfobaseNode);
	OpenForm("Catalog.DataExchangeScenarios.ObjectForm", FormParameters, ThisObject);
EndProcedure

&AtClient
Procedure ContinueSync(Command)
	
	SwitchNumber = SwitchNumber - 1;
	SetNavigationNumber(SwitchNumber + 1);
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// StartPage page

&AtClient
Procedure OpenDataExchangeDirectory(Command)
	
	OpenNodeDataExchangeDirectory();
	
EndProcedure

&AtClient
Procedure ConfigureExchangeMessagesTransportParameters(Command)
	
	Filter              = New Structure("Node", Object.InfobaseNode);
	FillingValues = New Structure("Node", Object.InfobaseNode);
	
	Notification = New NotifyDescription("SetUpExchangeMessageTransportParametersCompletion", ThisObject);
	DataExchangeClient.OpenInformationRegisterWriteFormByFilter(Filter,
		FillingValues, "DataExchangeTransportSettings", ThisObject, , , Notification);

EndProcedure

////////////////////////////////////////////////////////////////////////////////
// StatisticsPage page

&AtClient
Procedure RefreshAllMappingInformation(Command)
	
	CurrentData = Items.StatisticsInformationTree.CurrentData;
	
	If CurrentData <> Undefined Then
		
		CurrentRowKey = CurrentData.Key;
		
	EndIf;
	
	Cancel = False;
	
	RowsKeys = New Array;
	
	GetAllRowKeys(RowsKeys, StatisticsInformationTree.GetItems());
	
	If RowsKeys.Count() > 0 Then
		
		UpdateMappingByRowDetailsAtServer(Cancel, RowsKeys);
		
	EndIf;
	
	If Cancel Then
		ShowMessageBox(, NStr("ru = 'При получении информации статистики возникли ошибки.'; en = 'Error gathering statistic data.'; pl = 'Podczas pobierania informacji statystycznej wystąpiły błędy.';de = 'Beim Empfang von Statistikinformationen sind Fehler aufgetreten.';ro = 'Au apărut erori la primirea informațiilor statistice.';tr = 'İstatistik bilgisi alınırken hatalar oluştu.'; es_ES = 'Errores ocurridos al recibir la información de estadística.'"));
	Else
		
		ExpandStatisticsTree(CurrentRowKey);
		
		ShowUserNotification(NStr("ru = 'Сбор информации завершен'; en = 'Information collection is complete'; pl = 'Zbiór informacji został zakończony';de = 'Die Informationssammlung ist abgeschlossen';ro = 'Colectarea informațiilor este completă';tr = 'Bilgi toplama tamamlandı'; es_ES = 'Recopilación de información se ha finalizado'"));
	EndIf;
	
EndProcedure

&AtClient
Procedure RunDataImportForRow(Command)
	
	Cancel = False;
	
	SelectedRows = Items.StatisticsInformationTree.SelectedRows;
	
	If SelectedRows.Count() = 0 Then
		NString = NStr("ru = 'Выберите имя таблицы в поле статистической информации.'; en = 'Select a table name in the statistics field.'; pl = 'Wybierz nazwę tablicy w polu informacji statystycznej.';de = 'Wählen Sie im Feld für statistische Informationen einen Tabellennamen aus.';ro = 'Selectați numele tabelului în câmpul informațiilor statistice.';tr = 'İstatistik bilgi alanında bir tablo adı seçin.'; es_ES = 'Seleccionar un nombre de la tabla en el campo de la información estadística.'");
		CommonClient.MessageToUser(NString,,"StatisticsInformationTree",, Cancel);
		Return;
	EndIf;
	
	HasUnmappedObjects = False;
	For Each RowID In SelectedRows Do
		TreeRow = StatisticsInformationTree.FindByID(RowID);
		
		If IsBlankString(TreeRow.Key) Then
			Continue;
		EndIf;
		
		If TreeRow.UnmappedObjectCount <> 0 Then
			HasUnmappedObjects = True;
			Break;
		EndIf;
	EndDo;
	
	If HasUnmappedObjects Then
		NString = NStr("ru = 'Имеются несопоставленные объекты.
		                     |При загрузке данных будут созданы дубли несопоставленных объектов. Продолжить?'; 
		                     |en = 'Unmapped objects are found.
		                     |When you import the data, duplicates of these objects will be created. Do you want to continue?'; 
		                     |pl = 'Istnieją obiekty niedostosowane.
		                     |Niedostosowane duplikaty obiektów zostaną utworzone podczas importowania danych. Kontynuować?';
		                     |de = 'Es gibt nicht übereinstimmende Objekte.
		                     |Nicht übereinstimmende Objektduplikate werden beim Importieren von Daten erstellt. Fortsetzen?';
		                     |ro = 'Există obiecte neconfruntate.
		                     |La importul de date vor fi create duplicatele obiectelor neconfruntate. Continuați?';
		                     |tr = 'Eşsiz nesneler vardır.
		                     | Veri içe aktarılırken eşleştirilmemiş nesne çiftleri oluşturulacak. Devam et?'; 
		                     |es_ES = 'Hay objetos no emparejados.
		                     |Duplicados de objetos no emparejados se crearán al importar los datos. ¿Continuar?'");
		
		Notification = New NotifyDescription("ExecuteDataImportForRowQuestionUnmapped", ThisObject, New Structure);
		Notification.AdditionalParameters.Insert("SelectedRows", SelectedRows);
		ShowQueryBox(Notification, NString, QuestionDialogMode.YesNo, , DialogReturnCode.No);
		Return;
	EndIf;
	
	ExecuteDataImportForRowContinued(SelectedRows);
EndProcedure

&AtClient
Procedure OpenMappingForm(Command)
	
	CurrentData = Items.StatisticsInformationTree.CurrentData;
	
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	If IsBlankString(CurrentData.Key) Then
		Return;
	EndIf;
	
	If Not CurrentData.UsePreview Then
		ShowMessageBox(, NStr("ru = 'Для типа данных нельзя выполнить сопоставление объектов.'; en = 'Object mapping cannot be performed for the data type.'; pl = 'Dla typu danych nie można wykonać zestawienie obiektów.';de = 'Objekte für den Datentyp können nicht zugeordnet werden.';ro = 'Nu puteți executa confruntarea obiectelor pentru acest tip de date.';tr = 'Veri türü için nesneler eşlenemez.'; es_ES = 'No se puede mapear los objetos para el tipo de datos.'"));
		Return;
	EndIf;
	
	FormParameters = New Structure;
	FormParameters.Insert("DestinationTableName",            CurrentData.DestinationTableName);
	FormParameters.Insert("SourceTableObjectTypeName", CurrentData.ObjectTypeString);
	FormParameters.Insert("DestinationTableFields",           CurrentData.TableFields);
	FormParameters.Insert("DestinationTableSearchFields",     CurrentData.SearchFields);
	FormParameters.Insert("SourceTypeString",            CurrentData.SourceTypeString);
	FormParameters.Insert("DestinationTypeString",            CurrentData.DestinationTypeString);
	FormParameters.Insert("IsObjectDeletion",             CurrentData.IsObjectDeletion);
	FormParameters.Insert("DataImportedSuccessfully",         CurrentData.DataImportedSuccessfully);
	FormParameters.Insert("Key",                           CurrentData.Key);
	FormParameters.Insert("Synonym",                        CurrentData.Synonym);
	
	FormParameters.Insert("InfobaseNode",               Object.InfobaseNode);
	FormParameters.Insert("ExchangeMessageFileName",              Object.ExchangeMessageFileName);
	
	OpenForm("DataProcessor.InfobaseObjectMapping.Form", FormParameters, ThisObject);
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// MappingCompletePage page

&AtClient
Procedure GoToDataImportEventLog(Command)
	
	DataExchangeClient.GoToDataEventLogModally(Object.InfobaseNode, ThisObject, "DataImport");
	
EndProcedure

&AtClient
Procedure GoToDataExportEventLog(Command)
	
	DataExchangeClient.GoToDataEventLogModally(Object.InfobaseNode, ThisObject, "DataExport");
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// QuestionAboutExportContentPage page

&AtClient
Procedure ExportAdditionGeneralDocumentsFilter(Command)
	DataExchangeClient.OpenExportAdditionFormAllDocuments(ExportAddition, ThisObject);
EndProcedure

&AtClient
Procedure ExportAdditionDetailedFilter(Command)
	DataExchangeClient.OpenExportAdditionFormDetailedFilter(ExportAddition, ThisObject);
EndProcedure

&AtClient
Procedure ExportAdditionFilterByNodeScenario(Command)
	DataExchangeClient.OpenExportAdditionFormNodeScenario(ExportAddition, ThisObject);
EndProcedure

&AtClient
Procedure ExportAdditionExportComposition(Command)
	DataExchangeClient.OpenExportAdditionFormCompositionOfData(ExportAddition, ThisObject);
EndProcedure

&AtClient
Procedure ExportAdditionClearGeneralFilter(Command)
	
	TitleText = NStr("ru='Подтверждение'; en = 'Confirm operation'; pl = 'Potwierdzenie';de = 'Bestätigung';ro = 'Confirmare';tr = 'Onay'; es_ES = 'Confirmación'");
	QuestionText   = NStr("ru='Очистить общий отбор?'; en = 'Do you want to clear the common filter?'; pl = 'Oczyścić wspólny filtr?';de = 'Gemeinsamen Filter löschen?';ro = 'Goliți filtrul comun?';tr = 'Genel filtreyi temizle?'; es_ES = '¿Borrar el filtro común?'");
	NotifyDescription = New NotifyDescription("ExportAdditionGeneralFilterClearingCompletion", ThisObject);
	ShowQueryBox(NotifyDescription, QuestionText, QuestionDialogMode.YesNo,,,TitleText);
	
EndProcedure

&AtClient
Procedure ExportAdditionClearDetailedFilter(Command)
	TitleText = NStr("ru='Подтверждение'; en = 'Confirm operation'; pl = 'Potwierdzenie';de = 'Bestätigung';ro = 'Confirmare';tr = 'Onay'; es_ES = 'Confirmación'");
	QuestionText   = NStr("ru='Очистить детальный отбор?'; en = 'Do you want to clear the detailed filter?'; pl = 'Oczyścić filtr szczegółowy?';de = 'Detaillierten Filter löschen?';ro = 'Curățați filtrul detaliat?';tr = 'Ayrıntılı filtreyi temizle?'; es_ES = '¿Borrar el filtro detallado?'");
	NotifyDescription = New NotifyDescription("ExportAdditionDetailedFilterClearingCompletion", ThisObject);
	ShowQueryBox(NotifyDescription, QuestionText, QuestionDialogMode.YesNo,,,TitleText);
EndProcedure

&AtClient
Procedure ExportAdditionFiltersHistory(Command)
	// Filling a menu list with all saved settings options.
	VariantList = ExportAdditionServerSettingsHistory();
	
	// Adding the option for saving the current settings.
	Text = NStr("ru='Сохранить текущую настройку...'; en = 'Save current setting...'; pl = 'Zapisuję bieżącą konfigurację...';de = 'Die aktuelle Konfiguration speichern...';ro = 'Salvați setarea curentă...';tr = 'Mevcut ayarlar kaydediliyor...'; es_ES = 'Guardando la configuración actual...'");
	VariantList.Add(1, Text, , PictureLib.SaveReportSettings);
	
	NotifyDescription = New NotifyDescription("ExportAdditionFilterHistoryMenuSelection", ThisObject);
	ShowChooseFromMenu(NotifyDescription, VariantList, Items.ExportAdditionFiltersHistory);
	
EndProcedure

#EndRegion

#Region Private

////////////////////////////////////////////////////////////////////////////////
// SUPPLIED PART
////////////////////////////////////////////////////////////////////////////////

#Region PartToSupply

&AtClient
Function GetFormButtonByCommandName(FormItem, CommandName)
	
	For Each Item In FormItem.ChildItems Do
		
		If TypeOf(Item) = Type("FormGroup") Then
			
			FormItemByCommandName = GetFormButtonByCommandName(Item, CommandName);
			
			If FormItemByCommandName <> Undefined Then
				
				Return FormItemByCommandName;
				
			EndIf;
			
		ElsIf TypeOf(Item) = Type("FormButton")
			AND Item.CommandName = CommandName Then
			
			Return Item;
			
		Else
			
			Continue;
			
		EndIf;
		
	EndDo;
	
	Return Undefined;
	
EndFunction

&AtClient
Procedure GoNextExecute()
	
	ChangeNavigationNumber(+1);
	
EndProcedure

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
		Raise NStr("ru = 'Не определена страница для отображения.'; en = 'The page to display is not specified.'; pl = 'Strona do wyświetlenia nie jest zdefiniowana.';de = 'Die Seite für die Anzeige ist nicht definiert.';ro = 'Pagina pentru afișare nu este definită.';tr = 'Gösterilecek sayfa tanımlanmamış.'; es_ES = 'Página para visualizar no se ha definido.'");
	EndIf;
	
	NavigationRowCurrent = NavigationRowsCurrent[0];
	
	Items.MainPanel.CurrentPage  = Items[NavigationRowCurrent.MainPageName];
	Items.NavigationPanel.CurrentPage = Items[NavigationRowCurrent.NavigationPageName];
	
	Items.NavigationPanel.CurrentPage.Enabled = Not (IsMoveNext AND NavigationRowCurrent.TimeConsumingOperation);
	
	// Setting the default button.
	NextButton = GetFormButtonByCommandName(Items.NavigationPanel.CurrentPage, "NextCommand");
	
	If NextButton <> Undefined Then
		
		NextButton.DefaultButton = True;
		
	Else
		
		DoneButton = GetFormButtonByCommandName(Items.NavigationPanel.CurrentPage, "DoneCommand");
		
		If DoneButton <> Undefined Then
			
			DoneButton.DefaultButton = True;
			
		EndIf;
		
	EndIf;
	
	If IsMoveNext AND NavigationRowCurrent.TimeConsumingOperation Then
		
		AttachIdleHandler("ExecuteTimeConsumingOperationHandler", 0.1, True);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure ExecuteNavigationEventHandlers(Val IsMoveNext)
	
	// Navigation event handlers.
	If IsMoveNext Then
		
		NavigationRows = NavigationTable.FindRows(New Structure("SwitchNumber", SwitchNumber - 1));
		
		If NavigationRows.Count() > 0 Then
			NavigationRow = NavigationRows[0];
		
			// OnNavigationToNextPage handler.
			If Not IsBlankString(NavigationRow.OnSwitchToNextPageHandlerName)
				AND Not NavigationRow.TimeConsumingOperation Then
				
				ProcedureName = "Attachable_[HandlerName](Cancel)";
				ProcedureName = StrReplace(ProcedureName, "[HandlerName]", NavigationRow.OnSwitchToNextPageHandlerName);
				
				Cancel = False;
				
				Result = Eval(ProcedureName);
				
				If Cancel Then
					
					SetNavigationNumber(SwitchNumber - 1);
					
					Return;
					
				EndIf;
				
			EndIf;
		EndIf;
		
	Else
		
		NavigationRows = NavigationTable.FindRows(New Structure("SwitchNumber", SwitchNumber + 1));
		
		If NavigationRows.Count() = 0 Then
			Return;
		EndIf;
		
	EndIf;
	
	NavigationRowsCurrent = NavigationTable.FindRows(New Structure("SwitchNumber", SwitchNumber));
	
	If NavigationRowsCurrent.Count() = 0 Then
		Raise NStr("ru = 'Не определена страница для отображения.'; en = 'The page to display is not specified.'; pl = 'Strona do wyświetlenia nie jest zdefiniowana.';de = 'Die Seite für die Anzeige ist nicht definiert.';ro = 'Pagina pentru afișare nu este definită.';tr = 'Gösterilecek sayfa tanımlanmamış.'; es_ES = 'Página para visualizar no se ha definido.'");
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
		Raise NStr("ru = 'Не определена страница для отображения.'; en = 'The page to display is not specified.'; pl = 'Strona do wyświetlenia nie jest zdefiniowana.';de = 'Die Seite für die Anzeige ist nicht definiert.';ro = 'Pagina pentru afișare nu este definită.';tr = 'Gösterilecek sayfa tanımlanmamış.'; es_ES = 'Página para visualizar no se ha definido.'");
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
			
			If VersionMismatchErrorOnGetData <> Undefined
				AND VersionMismatchErrorOnGetData.HasError Then
				
				ProcessVersionDifferenceError();
				Return;
				
			EndIf;
			
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
Procedure NavigationTableNewRow(
									MainPageName,
									NavigationPageName,
									OnOpenHandlerName = "",
									OnNavigationToNextPageHandlerName = "")
									
	NewRow = NavigationTable.Add();
	
	NewRow.SwitchNumber = NavigationTable.Count();
	NewRow.MainPageName     = MainPageName;
	NewRow.NavigationPageName    = NavigationPageName;
	
	NewRow.OnSwitchToNextPageHandlerName = OnNavigationToNextPageHandlerName;
	NewRow.OnOpenHandlerName      = OnOpenHandlerName;
	
	NewRow.TimeConsumingOperation = False;
	NewRow.TimeConsumingOperationHandlerName = "";
	
EndProcedure

&AtServer
Procedure NavigationTableNewRowTimeConsumingOperation(
									MainPageName,
									NavigationPageName,
									TimeConsumingOperation = False,
									TimeConsumingOperationHandlerName = "",
									OnOpenHandlerName = "")
	
	NewRow = NavigationTable.Add();
	
	NewRow.SwitchNumber = NavigationTable.Count();
	NewRow.MainPageName     = MainPageName;
	NewRow.NavigationPageName    = NavigationPageName;
	
	NewRow.OnSwitchToNextPageHandlerName = "";
	NewRow.OnOpenHandlerName      = OnOpenHandlerName;
	
	NewRow.TimeConsumingOperation = TimeConsumingOperation;
	NewRow.TimeConsumingOperationHandlerName = TimeConsumingOperationHandlerName;
	
EndProcedure

#EndRegion

////////////////////////////////////////////////////////////////////////////////
// OVERRIDABLE PART
////////////////////////////////////////////////////////////////////////////////

#Region OverridablePart

////////////////////////////////////////////////////////////////////////////////
// PROCEDURES AND FUNCTIONS SECTION

#Region ProceduresAndFuctionsOfProcessing

#Region ProceduresAndFunctionsClient

&AtClient
Procedure InitializeDataProcessorVariables()
	
	// Initialization of data processor variables
	ProgressPercent                   = 0;
	FileID                  = "";
	ProgressAdditionalInformation             = "";
	TempStorageAddress            = "";
	ErrorMessage                   = "";
	OperationID               = "";
	TimeConsumingOperation                  = False;
	TimeConsumingOperationCompleted         = True;
	TimeConsumingOperationCompletedWithError = False;
	JobID                = Undefined;
	
EndProcedure

&AtClient
Procedure SetUpExchangeMessageTransportParametersCompletion(ClosingResult, AdditionalParameters) Export
	
	InitializeExchangeMessagesTransportSettings();
	
EndProcedure

&AtClient
Procedure ExportAdditionFilterHistoryCompletion(Response, SettingPresentation) Export
	
	If Response = DialogReturnCode.Yes Then
		ExportAdditionSetSettingsServer(SettingPresentation);
		ExportAdditionExportVariantSetVisibility();
	EndIf;
	
EndProcedure

&AtClient
Procedure ExportAdditionGeneralFilterClearingCompletion(Response, AdditionalParameters) Export
	
	If Response = DialogReturnCode.Yes Then
		ExportAdditionGeneralFilterClearingServer();
	EndIf;
	
EndProcedure

&AtClient
Procedure ExportAdditionDetailedFilterClearingCompletion(Response, AdditionalParameters) Export
	If Response = DialogReturnCode.Yes Then
		ExportAdditionDetailedFilterClearingServer();
	EndIf;
EndProcedure

&AtClient
Procedure ExportAdditionFilterHistoryMenuSelection(Val SelectedItem, Val AdditionalParameters) Export
	
	If SelectedItem = Undefined Then
		Return;
	EndIf;
		
	SettingPresentation = SelectedItem.Value;
	If TypeOf(SettingPresentation)=Type("String") Then
		// An option is selected, which is name of the setting saved earlier.
		
		TitleText = NStr("ru='Подтверждение'; en = 'Confirm operation'; pl = 'Potwierdzenie';de = 'Bestätigung';ro = 'Confirmare';tr = 'Onay'; es_ES = 'Confirmación'");
		QuestionText = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("ru='Восстановить настройки ""%1""?'; en = 'Do you want to restore ""%1"" settings?'; pl = 'Przywróć ustawienia ""%1""?';de = 'Einstellungen wiederherstellen ""%1""?';ro = 'Restabiliți setările ""%1""?';tr = 'Ayarları eski haline getir ""%1""?'; es_ES = '¿Restablecer las configuraciones ""%1""?'"), SettingPresentation);
		
		NotifyDescription = New NotifyDescription("ExportAdditionFilterHistoryCompletion", ThisObject, SettingPresentation);
		ShowQueryBox(NotifyDescription, QuestionText, QuestionDialogMode.YesNo,,,TitleText);
		
	ElsIf SettingPresentation=1 Then
		// A save option is selected, opening the form of all settings.
		DataExchangeClient.OpenExportAdditionFormSaveSettings(ExportAddition, ThisObject);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure ExecuteDataImportForRowQuestionUnmapped(Val QuestionResult, Val AdditionalParameters) Export
	If QuestionResult <> DialogReturnCode.Yes Then
		Return;
	EndIf;
	
	ExecuteDataImportForRowContinued(AdditionalParameters.SelectedRows);
EndProcedure

&AtClient
Procedure ExecuteDataImportForRowContinued(Val SelectedRows) 

	RowsKeys = GetSelectedRowKeys(SelectedRows);
	If RowsKeys.Count() = 0 Then
		Return;
	EndIf;
	
	Cancel = False;
	UpdateMappingByRowDetailsAtServer(Cancel, RowsKeys, True);
	
	If Cancel Then
		NString = NStr("ru = 'При загрузке данных возникли ошибки.
		                     |Перейти в журнал регистрации?'; 
		                     |en = 'Errors occurred during data import.
		                     |Do you want to view the event log?'; 
		                     |pl = 'Wystąpiły błędy podczas importowania danych.
		                     |Czy chcesz otworzyć dziennik zdarzeń?';
		                     |de = 'Beim Importieren von Daten sind Fehler aufgetreten.
		                     |Möchten Sie das Ereignisprotokoll öffnen?';
		                     |ro = 'Au apărut erori în timpul importului.
		                     |Treceți în registrul logare?';
		                     |tr = 'Veri alınırken hatalar oluştu.
		                     | Olay günlüğünü açmak ister misiniz?'; 
		                     |es_ES = 'Errores ocurridos al importar los datos.
		                     |¿Quiere abrir el registro de eventos?'");
		
		NotifyDescription = New NotifyDescription("GoToEventLog", ThisObject);
		ShowQueryBox(NotifyDescription, NString, QuestionDialogMode.YesNo, ,DialogReturnCode.No);
		Return;
	EndIf;
		
	ExpandStatisticsTree(RowsKeys[RowsKeys.UBound()]);
	ShowUserNotification(NStr("ru = 'Загрузка данных завершена.'; en = 'Data import completed.'; pl = 'Pobieranie danych zakończone.';de = 'Der Datenimport ist abgeschlossen.';ro = 'Importul de date este finalizat.';tr = 'Verinin içe aktarımı tamamlandı.'; es_ES = 'Importación de datos se ha finalizado.'"));
EndProcedure

&AtClient
Procedure OpenNodeDataExchangeDirectory()
	
	// Server call without context.
	DirectoryName = GetDirectoryNameAtServer(Object.ExchangeMessagesTransportKind, Object.InfobaseNode);
	
	If IsBlankString(DirectoryName) Then
		ShowMessageBox(, NStr("ru = 'Не задан каталог обмена информацией.'; en = 'The data exchange directory is not specified.'; pl = 'Katalog wymiany informacji nie został określony.';de = 'Informationsaustauschverzeichnis ist nicht angegeben.';ro = 'Catalogul schimbului de informații nu este specificat.';tr = 'Bilgi değişim dizini belirtilmemiş.'; es_ES = 'Directorio de intercambio de información no está especificado.'"));
		Return;
	EndIf;
	
	FileSystemClient.OpenExplorer(DirectoryName);
	
EndProcedure

&AtClient
Procedure GoToEventLog(Val QuestionResult, Val AdditionalParameters) Export
	
	If QuestionResult = DialogReturnCode.Yes Then
		
		DataExchangeClient.GoToDataEventLogModally(Object.InfobaseNode, ThisObject, "DataImport");
		
	EndIf;
	
EndProcedure

&AtClient
Procedure ProcessVersionDifferenceError()
	
	Items.MainPanel.CurrentPage             = Items.VersionsDifferenceErrorPage;
	Items.NavigationPanel.CurrentPage            = Items.NavigationPageVersionsDifferenceError;
	Items.ContinueSync.DefaultButton  = True;
	Items.VersionsDifferenceErrorDecoration.Title = VersionMismatchErrorOnGetData.ErrorText;
	
	VersionMismatchErrorOnGetData = Undefined;
	
	CheckVersionDifference = False;
	
EndProcedure

&AtClient
Procedure OnChangeFlagEndDataMapping()
	
	LoadMessageAfterMapping = EndDataMapping;
	
	Items.LoadMessageAfterMapping.Enabled = EndDataMapping;
	
	UpdateAvailabilityOfStatisticsInformationMoveCommand();
	UpdateTooltipTitleOfStatisticsInformationMove();
	
EndProcedure

&AtClient
Procedure OnChangeFlagImportMessageAfterMapping()
	
	UpdateAvailabilityOfStatisticsInformationMoveCommand();
	UpdateTooltipTitleOfStatisticsInformationMove();
	
EndProcedure

&AtClient
Procedure UpdateTooltipTitleOfStatisticsInformationMove()
	
	If EmailReceivedForDataMapping Then
		If EndDataMapping Then
			If LoadMessageAfterMapping Then
				Items.StatisticsDataNavigationTooltipDecoration.Title =
					NStr("ru = 'Нажмите кнопку ""Далее"" для завершения сопоставления данных и загрузки сообщения обмена.'; en = 'Click ""Next"" to confirm the mapping and import the exchange message.'; pl = 'Kliknij przycisk ""Dalej"", aby zakończyć dopasowanie danych i pobieranie wiadomości wymiany.';de = 'Klicken Sie auf ""Weiter"", um den Datenvergleich abzuschließen und die Austauschnachricht herunterzuladen.';ro = 'Tastați butonul ""Înainte"" pentru finalizarea confruntării datelor și importul mesajului de schimb.';tr = 'Veri eşlemesini tamamlamak ve veri alışverişi mesajını yüklemek için ""İleri"" düğmesini tıklayın.'; es_ES = 'Pulse el botón ""Seguir"" para terminar de comparar los datos y descargar el mensaje del cambio.'");
			Else
				Items.StatisticsDataNavigationTooltipDecoration.Title =
					NStr("ru = 'Нажмите кнопку ""Сохранить и закрыть"" для завершения сопоставления данных и выхода из помощника.'; en = 'Click ""Save and close"" to confirm the mapping and exit the wizard.'; pl = 'Kliknij przycisk ""Zapisz i zamknij"", aby zakończyć dopasowanie danych i wyjścia z asystenta.';de = 'Klicken Sie auf die Schaltfläche ""Speichern und Schließen"", um den Vergleich abzuschließen und den Assistenten zu verlassen.';ro = 'Tastați butonul ""Salvare și închidere"" pentru finalizarea confruntării datelor și părăsirea asistentului.';tr = 'Veri eşlemesini tamamlamak ve sihirbazdan çıkmak için ""Kaydet ve kapat"" düğmesini tıklayın.'; es_ES = 'Pulse el botón ""Guardar y cerrar"" para terminar de comparar los datos y salir del ayudante.'");
			EndIf;
		Else
			Items.StatisticsDataNavigationTooltipDecoration.Title =
				NStr("ru = 'Нажмите кнопку ""Сохранить и закрыть"" для сохранения результатов сопоставления и выхода из помощника.
				|При следующем запуске помощника можно будет продолжить сопоставление данных.'; 
				|en = 'Click ""Save and close"" to confirm the mapping and exit the wizard.
				|You can continue editing the mapping next time you start the wizard.'; 
				|pl = 'Kliknij przycisk ""Zapisz i zamknij"", aby zapisać wyniki dopasowania i wyjścia z asystenta.
				|Przy następnym uruchomieniu asystenta będzie można kontynuować dopasowanie danych.';
				|de = 'Klicken Sie auf die Schaltfläche ""Speichern und schließen"", um die Vergleichsergebnisse zu speichern und den Assistenten zu verlassen.
				|Wenn Sie den Assistenten das nächste Mal starten, können Sie den Abgleich der Daten fortsetzen.';
				|ro = 'Tastați butonul ""Salvare și închidere"" pentru salvarea rezultatelor confruntării și părăsirea asistentului.
				|La următoarea lansare a asistentului veți putea continua confruntarea datelor.';
				|tr = 'Veri eşlemesini kaydetmek ve sihirbazdan çıkmak için ""Kaydet ve kapat"" düğmesini tıklayın. 
				| Sihirbaz bir sonraki çalıştırıldığında verilerin eşleşmesine devam edilebilecektir.'; 
				|es_ES = 'Pulse el botón ""Guardar y cerrar"" para guardar los resultados de comparación y salir del ayudante.
				|Al volver a lanzar el ayudante se podrá seguir comparando los datos.'");
		EndIf;
	Else
		Items.StatisticsDataNavigationTooltipDecoration.Title =
			NStr("ru = 'Нажмите кнопку ""Далее"" для синхронизации данных.'; en = 'Click ""Next"" to synchronize data.'; pl = 'Kliknij Dalej, aby zsynchronizować dane.';de = 'Klicken Sie auf Weiter, um die Daten zu synchronisieren.';ro = 'Faceți click pe Următorul pentru a sincroniza datele.';tr = 'Verileri senkronize etmek için İleri''ye tıklayın.'; es_ES = 'Hacer clic en Siguiente para sincronizar los datos.'");
	EndIf;
	
EndProcedure

&AtClient
Procedure UpdateAvailabilityOfStatisticsInformationMoveCommand()
	
	Items.DoneCommand.Enabled = Not EndDataMapping Or Not LoadMessageAfterMapping;
	Items.DoneCommand.DefaultButton = EndDataMapping;
	
	Items.StatisticsInformationNextCommand.Enabled = EndDataMapping AND LoadMessageAfterMapping;
	Items.StatisticsInformationNextCommand.DefaultButton = EndDataMapping AND LoadMessageAfterMapping;
	
EndProcedure

#EndRegion

#Region ProceduresAndFunctionsServer

&AtServer
Procedure UpdateMappingByRowDetailsAtServer(Cancel, RowsKeys, RunDataImport = False)
	
	RowIndexes = GetStatisticsTableRowIndexes(RowsKeys);
	
	DataProcessorObject = FormAttributeToValue("Object");
	
	If RunDataImport Then
		DataProcessorObject.RunDataImport(Cancel, RowIndexes);
	EndIf;
	
	// Getting mapping statistic data.
	DataProcessorObject.GetObjectMappingByRowStats(Cancel, RowIndexes);
	
	ValueToFormAttribute(DataProcessorObject, "Object");
	
	StatisticsInformation(DataProcessorObject.StatisticsTable());
	
	ModuleInteractiveExchangeWizard = DataExchangeServer.ModuleInteractiveDataExchangeWizard();
	
	AllDataMapped   = ModuleInteractiveExchangeWizard.AllDataMapped(DataProcessorObject.StatisticsTable());
	HasUnmappedMasterData = Not AllDataMapped AND ModuleInteractiveExchangeWizard.HasUnmappedMasterData(DataProcessorObject.StatisticsTable());
	
	SetAdditionalInfoGroupVisible();
	
EndProcedure

&AtServer
Procedure UpdateMappingStatisticsDataAtServer(Cancel, NotificationParameters)
	
	TableRows = Object.StatisticsInformation.FindRows(New Structure("Key", NotificationParameters.UniqueKey));
	
	If TableRows.Count() > 0 Then
		FillPropertyValues(TableRows[0], NotificationParameters, "DataImportedSuccessfully");
		
		RowsKeys = New Array;
		RowsKeys.Add(NotificationParameters.UniqueKey);
		
		UpdateMappingByRowDetailsAtServer(Cancel, RowsKeys);
	EndIf;
	
EndProcedure

&AtServer
Procedure StatisticsInformation(StatisticsInformation)
	
	TreeItemsCollection = StatisticsInformationTree.GetItems();
	TreeItemsCollection.Clear();
	
	Common.FillFormDataTreeItemCollection(TreeItemsCollection,
		DataExchangeServer.StatisticsInformation(StatisticsInformation));
	
EndProcedure

&AtServer
Procedure SetAdditionalInfoGroupVisible()
	
	Items.DataMappingStatusPages.CurrentPage = ?(AllDataMapped,
		Items.MappingStatusAllDataMapped,
		Items.MappingStatusUnmappedDataDetected);
	
EndProcedure

&AtServer
Procedure InitializeExchangeMessagesTransportSettings()
	
	DefaultTransportKind  = InformationRegisters.DataExchangeTransportSettings.DefaultExchangeMessagesTransportKind(Object.InfobaseNode);
	ConfiguredTransportTypes = InformationRegisters.DataExchangeTransportSettings.ConfiguredTransportTypes(Object.InfobaseNode);
	
	SkipTransportPage = True;
	
	If ConfiguredTransportTypes.Count() > 1
		AND Not ValueIsFilled(Object.ExchangeMessagesTransportKind) Then
		SkipTransportPage = ExportAdditionExtendedMode;
	EndIf;
	
	If Not ValueIsFilled(Object.ExchangeMessagesTransportKind) Then
		Object.ExchangeMessagesTransportKind = DefaultTransportKind;
	EndIf;
	
	StartDataExchangeFromCorrespondent = Not ValueIsFilled(Object.ExchangeMessagesTransportKind);
		
	ExchangeBetweenSaaSApplications = SaaSModel
		AND (Object.ExchangeMessagesTransportKind = Enums.ExchangeMessagesTransportTypes.FILE
			Or Object.ExchangeMessagesTransportKind = Enums.ExchangeMessagesTransportTypes.FTP);
	
	OnChangeExchangeMessagesTransportKind(True);
	
	If Not SkipTransportPage Then
		
		If DataExchangeServer.HasRightsToAdministerExchanges() Then
			Items.ConfigureExchangeMessagesTransportParameters.Visible = True;
			
			DataExchangeServer.FillChoiceListWithAvailableTransportTypes(Object.InfobaseNode,
				Items.ExchangeMessagesTransportKind);
		Else
			Items.ConfigureExchangeMessagesTransportParameters.Visible = False;
			
			DataExchangeServer.FillChoiceListWithAvailableTransportTypes(Object.InfobaseNode,
				Items.ExchangeMessagesTransportKind, ConfiguredTransportTypes);
		EndIf;
		
		TransportChoiceList = Items.ExchangeMessagesTransportKind.ChoiceList;
		
		If TransportChoiceList.Count() = 0 Then
			TransportChoiceList.Add(Undefined, NStr("ru = 'подключение не настроено'; en = 'no connections are configured'; pl = 'Połączenie nie zostało skonfigurowane';de = 'Verbindung ist nicht konfiguriert';ro = 'conexiunea nu este setată';tr = 'Bağlantı yapılandırılmadı'; es_ES = 'Conexión no está configurada'"));
			
			Items.ExchangeMessageTransportKindAsString.TextColor = StyleColors.ErrorNoteText
		Else
			Items.ExchangeMessageTransportKindAsString.TextColor = New Color;
		EndIf;
		
		Items.ExchangeMessageTransportKindAsString.Title = TransportChoiceList[0].Presentation;
		Items.ExchangeMessageTransportKindAsString.Visible = (TransportChoiceList.Count() = 1);
		Items.ExchangeMessagesTransportKind.Visible        = Not Items.ExchangeMessageTransportKindAsString.Visible;
		
		Items.WSPassword.Visible          = ExchangeOverWebService AND Not WSRememberPassword;
		Items.WSPasswordLabel.Visible   = ExchangeOverWebService AND Not WSRememberPassword;
        Items.WSRememberPassword.Visible = ExchangeOverWebService AND Not WSRememberPassword;
		
		SetExchangeDirectoryOpeningButtonVisible();
		
	EndIf;
	
EndProcedure

&AtServer
Procedure OnChangeExchangeMessagesTransportKind(Initializing = False)
	
	ExchangeOverExternalConnection = (Object.ExchangeMessagesTransportKind = Enums.ExchangeMessagesTransportTypes.COM);
	ExchangeOverWebService         = (Object.ExchangeMessagesTransportKind = Enums.ExchangeMessagesTransportTypes.WS);
	
	If ExchangeOverWebService Then
		SettingsStructure = InformationRegisters.DataExchangeTransportSettings.TransportSettingsWS(Object.InfobaseNode);
		FillPropertyValues(ThisObject, SettingsStructure, "WSRememberPassword");
	EndIf;
	
	UseProgressBar = Not ExchangeOverWebService AND Not ExchangeBetweenSaaSApplications;
	
	If Initializing Then
		SkipTransportPage = SkipTransportPage AND (Not ExchangeOverWebService Or WSRememberPassword);
		FillNavigationTable();
	EndIf;
	
EndProcedure

&AtServer
Procedure InitializeScheduleSetupWizard(IsStartedFromAnotherApplication)
	
	OpenDataExchangeScenarioCreationWizard = DataExchangeServer.HasRightsToAdministerExchanges();
	
	If IsStartedFromAnotherApplication Then
		OpenDataExchangeScenarioCreationWizard = False;
	ElsIf Parameters.Property("ScheduleSetup") Then
		OpenDataExchangeScenarioCreationWizard = Parameters.ScheduleSetup;
	EndIf;
	
	Items.ScheduleSettingsHelpText.Visible = OpenDataExchangeScenarioCreationWizard;
	
EndProcedure

&AtServer
Function GetStatisticsTableRowIndexes(RowsKeys)
	
	RowIndexes = New Array;
	
	For Each varKey In RowsKeys Do
		
		TableRows = Object.StatisticsInformation.FindRows(New Structure("Key", varKey));
		
		RowIndex = Object.StatisticsInformation.IndexOf(TableRows[0]);
		
		RowIndexes.Add(RowIndex);
		
	EndDo;
	
	Return RowIndexes;
	
EndFunction

&AtServer
Procedure SetExchangeDirectoryOpeningButtonVisible()
	
	ButtonVisibility = (Object.ExchangeMessagesTransportKind = Enums.ExchangeMessagesTransportTypes.FILE
		Or Object.ExchangeMessagesTransportKind = Enums.ExchangeMessagesTransportTypes.FTP);
	
	Items.DataExchangeDirectory.Visible = ButtonVisibility;
	
	If ButtonVisibility Then
		Items.DataExchangeDirectory.Title = GetDirectoryNameAtServer(Object.ExchangeMessagesTransportKind, Object.InfobaseNode);
	EndIf;
	
EndProcedure

&AtServer
Procedure CheckWhetherTransferToNewExchangeIsRequired()
	
	MessagesArray = GetUserMessages(True);
	
	If MessagesArray = Undefined Then
		Return;
	EndIf;
	
	Count = MessagesArray.Count();
	If Count = 0 Then
		Return;
	EndIf;
	
	Message      = MessagesArray[Count-1];
	MessageText = Message.Text;
	
	// A subsystem ID is deleted from the message if necessary.
	If StrStartsWith(MessageText, "{MigrationToNewExchangeDone}") Then
		
		MessageData = Common.ValueFromXMLString(MessageText);
		
		If MessageData <> Undefined
			AND TypeOf(MessageData) = Type("Structure") Then
			
			ExchangePlanName                    = MessageData.ExchangePlanNameToMigrateToNewExchange;
			ExchangePlanNodeCode                = MessageData.Code;
			NewDataSynchronizationSetting = ExchangePlans[ExchangePlanName].FindByCode(ExchangePlanNodeCode);
			
			BackgroundJobExecutionResult.AdditionalResultData.Insert("FormReopeningParameters",
				New Structure("NewDataSynchronizationSetting", NewDataSynchronizationSetting));
				
			BackgroundJobExecutionResult.AdditionalResultData.Insert("ForceCloseForm", True);
			
		EndIf;
		
	EndIf;
	
EndProcedure

&AtServer
Procedure PrepareExportAdditionStructure(StructureAddition)
	
	StructureAddition = New Structure;
	StructureAddition.Insert("ExportOption", ExportAddition.ExportOption);
	StructureAddition.Insert("AllDocumentsFilterPeriod", ExportAddition.AllDocumentsFilterPeriod);
	
	StructureAddition.Insert("AllDocumentsComposer", Undefined);
	If Not IsBlankString(ExportAddition.AllDocumentsComposerAddress) Then
		AllDocumentsComposer = GetFromTempStorage(ExportAddition.AllDocumentsComposerAddress);
		
		StructureAddition.AllDocumentsComposer = AllDocumentsComposer;
	EndIf;
	
	StructureAddition.Insert("NodeScenarioFilterPeriod", ExportAddition.NodeScenarioFilterPeriod);
	StructureAddition.Insert("NodeScenarioFilterPresentation", ExportAddition.NodeScenarioFilterPresentation);
	StructureAddition.Insert("AdditionScenarioParameters", ExportAddition.AdditionScenarioParameters);
	StructureAddition.Insert("CurrentSettingsItemPresentation", ExportAddition.CurrentSettingsItemPresentation);
	StructureAddition.Insert("InfobaseNode", ExportAddition.InfobaseNode);
	
	StructureAddition.Insert("AllDocumentsSettingFilterComposer", ExportAddition.AllDocumentsFilterComposer.GetSettings());
	
	StructureAddition.Insert("AdditionalNodeScenarioRegistration", ExportAddition.AdditionalNodeScenarioRegistration.Unload());
	StructureAddition.Insert("AdditionalRegistration", ExportAddition.AdditionalRegistration.Unload());
	
EndProcedure

#Region ExportAdditionOperations

&AtServer
Procedure InitializeExportAdditionAttributes()
	
	// Getting settings as a structure, settings will be saved implicitly to the form temporary storage.
	ExportAdditionSettings = DataExchangeServer.InteractiveExportModification(
		Object.InfobaseNode, ThisObject.UUID, ExportAdditionExtendedMode);
		
	// Setting up the form.
	// Converting ThisObject form attribute to a value of DataProcessor type. It is used to simplify data link with the form.
	DataExchangeServer.InteractiveExportModificationAttributeBySettings(ThisObject, ExportAdditionSettings, "ExportAddition");
	
	AdditionScenarioParameters = ExportAddition.AdditionScenarioParameters;
	
	// Configuring interface according to the specified scenario.
	
	// Special cases
	StandardVariantsProhibited = Not AdditionScenarioParameters.OptionDoNotAdd.Use
		AND Not AdditionScenarioParameters.AllDocumentsOption.Use
		AND Not AdditionScenarioParameters.ArbitraryFilterOption.Use;
		
	If StandardVariantsProhibited Then
		If AdditionScenarioParameters.AdditionalOption.Use Then
			// A single node scenario option is available.
			Items.ExportAdditionNodeAsStringExportOption.Visible = True;
			Items.ExportAdditionNodeExportOption.Visible        = False;
			Items.CustomGroupIndentDecoration.Visible           = False;
			ExportAddition.ExportOption = 3;
		Else
			// Nothing is found. Setting the flag showing that the page is skipped and exiting.
			ExportAddition.ExportOption = -1;
			Items.ExportAdditionOptions.Visible = False;
			Return;
		EndIf;
	EndIf;
	
	// Setting typical input fields.
	Items.StandardAdditionOptionNone.Visible = AdditionScenarioParameters.OptionDoNotAdd.Use;
	If Not IsBlankString(AdditionScenarioParameters.OptionDoNotAdd.Title) Then
		Items.ExportAdditionExportOption0.ChoiceList[0].Presentation = AdditionScenarioParameters.OptionDoNotAdd.Title;
	EndIf;
	Items.StandardAdditionOptionNoneNote.Title = AdditionScenarioParameters.OptionDoNotAdd.Explanation;
	If IsBlankString(Items.StandardAdditionOptionNoneNote.Title) Then
		Items.StandardAdditionOptionNoneNote.Visible = False;
	EndIf;
	
	Items.StandardAdditionOptionDocuments.Visible = AdditionScenarioParameters.AllDocumentsOption.Use;
	If Not IsBlankString(AdditionScenarioParameters.AllDocumentsOption.Title) Then
		Items.ExportAdditionExportOption1.ChoiceList[0].Presentation = AdditionScenarioParameters.AllDocumentsOption.Title;
	EndIf;
	Items.StandardAdditionOptionDocumentsNote.Title = AdditionScenarioParameters.AllDocumentsOption.Explanation;
	If IsBlankString(Items.StandardAdditionOptionDocumentsNote.Title) Then
		Items.StandardAdditionOptionDocumentsNote.Visible = False;
	EndIf;
	
	Items.StandardAdditionOptionCustom.Visible = AdditionScenarioParameters.ArbitraryFilterOption.Use;
	If Not IsBlankString(AdditionScenarioParameters.ArbitraryFilterOption.Title) Then
		Items.ExportAdditionExportOption2.ChoiceList[0].Presentation = AdditionScenarioParameters.ArbitraryFilterOption.Title;
	EndIf;
	Items.StandardAdditionOptionCustomNote.Title = AdditionScenarioParameters.ArbitraryFilterOption.Explanation;
	If IsBlankString(Items.StandardAdditionOptionCustomNote.Title) Then
		Items.StandardAdditionOptionCustomNote.Visible = False;
	EndIf;
	
	Items.CustomAdditionOption.Visible           = AdditionScenarioParameters.AdditionalOption.Use;
	Items.ExportPeriodNodeScenarioGroup.Visible         = AdditionScenarioParameters.AdditionalOption.UseFilterPeriod;
	Items.ExportAdditionFilterByNodeScenario.Visible    = Not IsBlankString(AdditionScenarioParameters.AdditionalOption.FilterFormName);
	
	Items.ExportAdditionNodeExportOption.ChoiceList[0].Presentation = AdditionScenarioParameters.AdditionalOption.Title;
	Items.ExportAdditionNodeAsStringExportOption.Title              = AdditionScenarioParameters.AdditionalOption.Title;
	
	Items.CustomAdditionOptionNote.Title = AdditionScenarioParameters.AdditionalOption.Explanation;
	If IsBlankString(Items.CustomAdditionOptionNote.Title) Then
		Items.CustomAdditionOptionNote.Visible = False;
	EndIf;
	
	// Command titles
	If Not IsBlankString(AdditionScenarioParameters.AdditionalOption.FormCommandTitle) Then
		Items.ExportAdditionFilterByNodeScenario.Title = AdditionScenarioParameters.AdditionalOption.FormCommandTitle;
	EndIf;
	
	// Sorting visible items.
	AdditionGroupOrder = New ValueList;
	If Items.StandardAdditionOptionNone.Visible Then
		AdditionGroupOrder.Add(Items.StandardAdditionOptionNone, 
			Format(AdditionScenarioParameters.OptionDoNotAdd.Order, "ND=10; NZ=; NLZ=; NG="));
	EndIf;
	If Items.StandardAdditionOptionDocuments.Visible Then
		AdditionGroupOrder.Add(Items.StandardAdditionOptionDocuments, 
			Format(AdditionScenarioParameters.AllDocumentsOption.Order, "ND=10; NZ=; NLZ=; NG="));
	EndIf;
	If Items.StandardAdditionOptionCustom.Visible Then
		AdditionGroupOrder.Add(Items.StandardAdditionOptionCustom, 
			Format(AdditionScenarioParameters.ArbitraryFilterOption.Order, "ND=10; NZ=; NLZ=; NG="));
	EndIf;
	If Items.CustomAdditionOption.Visible Then
		AdditionGroupOrder.Add(Items.CustomAdditionOption, 
			Format(AdditionScenarioParameters.AdditionalOption.Order, "ND=10; NZ=; NLZ=; NG="));
	EndIf;
	AdditionGroupOrder.SortByPresentation();
	For Each AdditionGroupItem In AdditionGroupOrder Do
		Items.Move(AdditionGroupItem.Value, Items.ExportAdditionOptions);
	EndDo;
	
	// Editing settings is only allowed if the appropriate rights are granted.
	HasRightsToSetup = AccessRight("SaveUserData", Metadata);
	Items.StandardSettingsOptionsImportGroup.Visible = HasRightsToSetup;
	If HasRightsToSetup Then
		// Restoring predefined settings.
		SetFirstItem = Not ExportAdditionSetSettingsServer(DataExchangeServer.ExportAdditionSettingsAutoSavingName());
		ExportAddition.CurrentSettingsItemPresentation = "";
	Else
		SetFirstItem = True;
	EndIf;
		
	SetFirstItem = SetFirstItem
		Or ExportAddition.ExportOption<0 
		Or ( (ExportAddition.ExportOption=0) AND (Not AdditionScenarioParameters.OptionDoNotAdd.Use) )
		Or ( (ExportAddition.ExportOption=1) AND (Not AdditionScenarioParameters.AllDocumentsOption.Use) )
		Or ( (ExportAddition.ExportOption=2) AND (Not AdditionScenarioParameters.ArbitraryFilterOption.Use) )
		Or ( (ExportAddition.ExportOption=3) AND (Not AdditionScenarioParameters.AdditionalOption.Use) );
	
	If SetFirstItem Then
		For Each AdditionGroupItem In AdditionGroupOrder[0].Value.ChildItems Do
			If TypeOf(AdditionGroupItem)=Type("FormField") AND AdditionGroupItem.Type = FormFieldType.RadioButtonField Then
				ExportAddition.ExportOption = AdditionGroupItem.ChoiceList[0].Value;
				Break;
			EndIf;
		EndDo;
	EndIf;
	
	// Initial view, same as ExportAdditionExportVariantSetVisibility client procedure.
	Items.AllDocumentsFilterGroup.Enabled  = ExportAddition.ExportOption=1;
	Items.DetailedFilterGroup.Enabled     = ExportAddition.ExportOption=2;
	Items.CustomFilterGroup.Enabled = ExportAddition.ExportOption=3;
	
	// Description of standard initial filters.
	SetExportAdditionFilterDescription();
	
EndProcedure

&AtServer
Procedure SetFormHeader()
	
	CaptionPattern = NStr("ru = 'Обмен данными с ""%1""'; en = 'Exchange data with %1'; pl = 'Wymiana danych z ""%1""';de = 'Datenaustausch mit ""%1""';ro = 'Schimb de date cu ""%1""';tr = '""%1"" ile veri alışverişi'; es_ES = 'Intercambio de datos con ""%1""'");
	
	If EmailReceivedForDataMapping Then
		CaptionPattern = NStr("ru = 'Сопоставление данных ""%1""'; en = 'Map %1 data'; pl = 'Mapowanie danych ""%1"".';de = 'Zuordnung von Daten ""%1"".';ro = 'Confruntarea datelor ""%1""';tr = '""%1"" verinin eşleşmesi.'; es_ES = 'Mapeo de los datos ""%1"".'");
	ElsIf GetData AND SendData Then
		CaptionPattern = NStr("ru = 'Синхронизация данных с ""%1""'; en = 'Synchronize data with %1'; pl = 'Synchronizacja danych z %1';de = 'Datensynchronisation mit %1';ro = 'Sincronizarea datelor cu %1';tr = 'İle veri senkronizasyonu%1'; es_ES = 'Sincronización de datos con %1'");
	ElsIf SendData Then
		CaptionPattern = NStr("ru = 'Отправка данных для ""%1""'; en = 'Send data to %1'; pl = 'Wysyłanie danych dla ""%1""';de = 'Senden von Daten für ""%1""';ro = 'Trimiterea datelor pentru ""%1""';tr = '""%1"" için veri gönderiliyor'; es_ES = 'Envío de datos para ""%1""'");
	ElsIf GetData Then
		CaptionPattern = NStr("ru = 'Получение данных от ""%1""'; en = 'Receive data from %1'; pl = 'Uzyskiwanie danych od ""%1""';de = 'Empfangen von Daten von ""%1""';ro = 'Primirea datelor de la ""%1""';tr = '""%1"" ''dan veri alınıyor'; es_ES = 'Recepción de datos de ""%1""'");
	EndIf;
		
	Title = StringFunctionsClientServer.SubstituteParametersToString(
		CaptionPattern, CorrespondentDescription);
	
EndProcedure

&AtClient
Procedure ExportAdditionExportVariantSetVisibility()
	Items.AllDocumentsFilterGroup.Enabled  = ExportAddition.ExportOption=1;
	Items.DetailedFilterGroup.Enabled     = ExportAddition.ExportOption=2;
	Items.CustomFilterGroup.Enabled = ExportAddition.ExportOption=3;
EndProcedure

&AtServer
Procedure ExportAdditionNodeScenarioPeriodChanging()
	DataExchangeServer.InteractiveExportModificationSetNodeScenarioPeriod(ExportAddition);
EndProcedure

&AtServer
Procedure ExportAdditionGeneralFilterClearingServer()
	DataExchangeServer.InteractiveExportModificationGeneralFilterClearing(ExportAddition);
	SetGeneralFilterAdditionDescription();
EndProcedure

&AtServer
Procedure ExportAdditionDetailedFilterClearingServer()
	DataExchangeServer.InteractiveExportModificationDetailsClearing(ExportAddition);
	SetAdditionDetailDescription();
EndProcedure

&AtServer
Procedure SetExportAdditionFilterDescription()
	SetGeneralFilterAdditionDescription();
	SetAdditionDetailDescription();
EndProcedure

&AtServer
Procedure SetGeneralFilterAdditionDescription()
	
	Text = DataExchangeServer.InteractiveExportModificationGeneralFilterAdditionDescription(ExportAddition);
	NoFilter = IsBlankString(Text);
	If NoFilter Then
		Text = NStr("ru='Все документы'; en = 'All documents'; pl = 'Wszystkie dokumenty';de = 'Alle Dokumente';ro = 'Toate documentele';tr = 'Tüm belgeler'; es_ES = 'Todos documentos'");
	EndIf;
	
	Items.ExportAdditionGeneralDocumentsFilter.Title = Text;
	Items.ExportAdditionClearGeneralFilter.Visible = Not NoFilter;
EndProcedure

&AtServer
Procedure SetAdditionDetailDescription()
	
	Text = DataExchangeServer.InteractiveExportModificationDetailedFilterDetails(ExportAddition);
	NoFilter = IsBlankString(Text);
	If NoFilter Then
		Text = NStr("ru='Дополнительные данные не выбраны'; en = 'No additional data is selected'; pl = 'Dodatkowe dane nie zostały wybrane';de = 'Zusätzliche Daten sind nicht ausgewählt';ro = 'Nu sunt selectate date suplimentare';tr = 'Ek veri seçilmedi'; es_ES = 'Datos adicionales no seleccionados'");
	EndIf;
	
	Items.ExportAdditionDetailedFilter.Title = Text;
	Items.ExportAdditionClearDetailedFilter.Visible = Not NoFilter;
EndProcedure

// Returns boolean - success or failure (setting is not found).
&AtServer 
Function ExportAdditionSetSettingsServer(SettingPresentation)
	Result = DataExchangeServer.InteractiveExportModificationRestoreSettings(ExportAddition, SettingPresentation);
	SetExportAdditionFilterDescription();
	Return Result;
EndFunction

&AtServer 
Function ExportAdditionServerSettingsHistory() 
	Return DataExchangeServer.InteractiveExportModificationSettingsHistory(ExportAddition);
EndFunction

#EndRegion

#EndRegion

#Region ProceduresAndFunctionsServerWIthoutContext

&AtServerNoContext
Procedure GetDataExchangesStates(DataImportResult, DataExportResult, Val InfobaseNode)
	
	DataExchangesStates = DataExchangeServer.DataExchangesStatesForInfobaseNode(InfobaseNode);
	
	DataImportResult = DataExchangesStates["DataImportResult"];
	If IsBlankString(DataExportResult) Then
		DataExportResult = DataExchangesStates["DataExportResult"];
	EndIf;
	
EndProcedure

&AtServerNoContext
Procedure DeleteMessageForDataMapping(ExchangeNode)
	
	SetPrivilegedMode(True);
	
	Filter = New Structure("InfobaseNode", ExchangeNode);
	CommonSettings = InformationRegisters.CommonInfobasesNodesSettings.Get(Filter);
	
	If ValueIsFilled(CommonSettings.MessageForDataMapping) Then
		
		MessageFileNameInStorage = DataExchangeServer.GetFileFromStorage(CommonSettings.MessageForDataMapping);
		
		File = New File(MessageFileNameInStorage);
		If File.Exist() AND File.IsFile() Then
			DeleteFiles(MessageFileNameInStorage);
		EndIf;
		
		InformationRegisters.CommonInfobasesNodesSettings.PutMessageForDataMapping(ExchangeNode, Undefined);
		
	EndIf;
	
EndProcedure

&AtServerNoContext
Procedure DeleteTempExchangeMessagesDirectory(TempDirectoryName)
	
	If Not IsBlankString(TempDirectoryName) Then
		
		Try
			DeleteFiles(TempDirectoryName);
			TempDirectoryName = "";
		Except
			WriteLogEvent(DataExchangeServer.EventLogMessageTextDataExchange(),
				EventLogLevel.Error, , , DetailErrorDescription(ErrorInfo()));
		EndTry;
		
	EndIf;
	
EndProcedure

&AtServerNoContext
Procedure EndExecutingTimeConsumingOperation(JobID)
	TimeConsumingOperations.CancelJobExecution(JobID);
EndProcedure

&AtServerNoContext
Function GetDirectoryNameAtServer(ExchangeMessagesTransportKind, InfobaseNode)
	
	Return InformationRegisters.DataExchangeTransportSettings.DataExchangeDirectoryName(ExchangeMessagesTransportKind, InfobaseNode);
	
EndFunction

&AtServerNoContext
Function TimeConsumingOperationState(Val OperationID, ExchangeNode)
	
	Try
		
		ConnectionParameters = DataExchangeServer.WSParameterStructure();
		
		SavedParameters = InformationRegisters.DataExchangeTransportSettings.TransportSettingsWS(ExchangeNode);
		FillPropertyValues(ConnectionParameters, SavedParameters);
		
		InterfaceVersions = DataExchangeCached.CorrespondentVersions(ConnectionParameters);
		
		ErrorMessageString = "";
		
		WSProxy = Undefined;
		If InterfaceVersions.Find("3.0.1.1") <> Undefined Then
			
			WSProxy = DataExchangeServer.GetWSProxy_3_0_1_1(ConnectionParameters, ErrorMessageString);
			
		ElsIf InterfaceVersions.Find("2.1.1.7") <> Undefined Then
			
			WSProxy = DataExchangeServer.GetWSProxy_2_1_1_7(ConnectionParameters, ErrorMessageString);
			
		ElsIf InterfaceVersions.Find("2.0.1.6") <> Undefined Then
			
			WSProxy = DataExchangeServer.GetWSProxy_2_0_1_6(ConnectionParameters, ErrorMessageString);
			
		Else
			
			WSProxy = DataExchangeServer.GetWSProxy(ConnectionParameters, ErrorMessageString);
			
		EndIf;
		
		If WSProxy = Undefined Then
			Raise ErrorMessageString;
		EndIf;
		
		Result = WSProxy.GetContinuousOperationStatus(OperationID, ErrorMessageString);
		
	Except
		Result = "Failed";
		ErrorMessageString = DetailErrorDescription(ErrorInfo())
			+ ?(ValueIsFilled(ErrorMessageString), Chars.LF + ErrorMessageString, "");
	EndTry;
	
	If Result = "Failed" Then
		MessageString = NStr("ru = 'Ошибка в базе-корреспонденте: %1'; en = 'Peer infobase error: %1'; pl = 'Błąd w bazie-korespondencie: %1';de = 'Es liegt ein Fehler in der entsprechenden Datenbank vor: %1';ro = 'Eroare în baza-corespondentă: %1';tr = 'Muhabir tabanındaki hata: %1'; es_ES = 'Error en la base-correspondiente: %1'");
		ErrorMessageString = StringFunctionsClientServer.SubstituteParametersToString(MessageString, ErrorMessageString);
	EndIf;
	
	Return Result;
	
EndFunction

#EndRegion

////////////////////////////////////////////////////////////////////////////////
// Idle handlers

&AtClient
Procedure TimeConsumingOperationIdleHandler()
	
	TimeConsumingOperationCompleted         = False;
	TimeConsumingOperationCompletedWithError = False;
	
	If ExchangeOverWebService Then
		
		ActionState = TimeConsumingOperationState(OperationID, Object.InfobaseNode);
			
	Else
		// Exchange via COM connection.
		ActionState = DataExchangeServerCall.JobState(JobID);
	EndIf;
	
	If ActionState = "Active" Or ActionState = "Active" Then
		AttachIdleHandler("TimeConsumingOperationIdleHandler", 5, True);
	Else
		
		TimeConsumingOperation          = False;
		TimeConsumingOperationCompleted = True;
		
		If ActionState = "Failed" 
			Or ActionState = "Canceled" 
			Or ActionState = "Failed" Then
			TimeConsumingOperationCompletedWithError = True;
		EndIf;
		
		AttachIdleHandler("GoNextExecute", 0.1, True);
		
	EndIf;
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Procedures and function of the master.

&AtClient
Function GetSelectedRowKeys(SelectedRows)
	
	// Function return value.
	RowsKeys = New Array;
	
	For Each RowID In SelectedRows Do
		
		TreeRow = StatisticsInformationTree.FindByID(RowID);
		
		If Not IsBlankString(TreeRow.Key) Then
			
			RowsKeys.Add(TreeRow.Key);
			
		EndIf;
		
	EndDo;
	
	Return RowsKeys;
EndFunction

&AtClient
Procedure GetAllRowKeys(RowsKeys, TreeItemsCollection)
	
	For Each TreeRow In TreeItemsCollection Do
		
		If Not IsBlankString(TreeRow.Key) Then
			
			RowsKeys.Add(TreeRow.Key);
			
		EndIf;
		
		ItemsCollection = TreeRow.GetItems();
		
		If ItemsCollection.Count() > 0 Then
			
			GetAllRowKeys(RowsKeys, ItemsCollection);
			
		EndIf;
		
	EndDo;
	
EndProcedure

&AtClient
Procedure RefreshDataExchangeStatusItemPresentation()
	
	Items.DataImportGroup.Visible = GetData;
	
	Items.DataImportStatusPages.CurrentPage = Items[DataExchangeClient.DataImportStatusPages()[DataImportResult]];
	If Items.DataImportStatusPages.CurrentPage=Items.ImportStatusUndefined Then
		Items.GoToDataImportEventLog.Title = NStr("ru='Загрузка данных не произведена'; en = 'Data is not imported.'; pl = 'Dane nie zostały zaimportowane';de = 'Daten wurden nicht importiert';ro = 'Datele nu au fost importate';tr = 'Veri içe aktarılmadı'; es_ES = 'Datos no se han importado'");
	Else
		Items.GoToDataImportEventLog.Title = DataExchangeClient.DataImportHyperlinksHeaders()[DataImportResult];
	EndIf;
	
	Items.DataExportGroup.Visible = SendData;
	
	Items.DataExportStatusPages.CurrentPage = Items[DataExchangeClient.DataExportStatusPages()[DataExportResult]];
	If Items.DataExportStatusPages.CurrentPage=Items.ExportStatusUndefined Then
		Items.GoToDataExportEventLog.Title = NStr("ru='Выгрузка данных не произведена'; en = 'Data is not exported.'; pl = 'Dane nie zostały eksportowane';de = 'Daten werden nicht exportiert';ro = 'Datele nu sunt exportate';tr = 'Veri dışa aktarılmadı'; es_ES = 'Datos no se han exportado'");
	Else
		Items.GoToDataExportEventLog.Title = DataExchangeClient.DataExportHyperlinksHeaders()[DataExportResult];
	EndIf;
	
EndProcedure

&AtClient
Procedure ExpandStatisticsTree(RowKey = "")
	
	ItemsCollection = StatisticsInformationTree.GetItems();
	
	For Each TreeRow In ItemsCollection Do
		
		Items.StatisticsInformationTree.Expand(TreeRow.GetID(), True);
		
	EndDo;
	
	// Placing a mouse pointer in the value tree.
	If Not IsBlankString(RowKey) Then
		
		RowID = 0;
		
		CommonClientServer.GetTreeRowIDByFieldValue("Key", RowID, StatisticsInformationTree.GetItems(), RowKey, False);
		
		Items.StatisticsInformationTree.CurrentRow = RowID;
		
	EndIf;
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// SECTION OF PROCESSING BACKGROUND JOBS

&AtClient
Function BackgroundJobParameters()
	
	JobParameters = New Structure();
	JobParameters.Insert("MethodBeingExecuted",      "");
	JobParameters.Insert("JobDescription",   "");
	JobParameters.Insert("MethodParameters",       Undefined);
	JobParameters.Insert("CompletionNotification", Undefined);
	JobParameters.Insert("CompletionHandler",  Undefined);
	
	Return JobParameters;
	
EndFunction

&AtClient
Procedure BackgroundJobStartClient(JobParameters, Cancel)
	
	Result = ScheduledJobStartAtServer(JobParameters);
	
	If Result = Undefined Then
		Cancel = True;
		Return;
	EndIf;
	
	If VersionMismatchErrorOnGetData <> Undefined
		AND VersionMismatchErrorOnGetData.HasError Then
		Cancel = True;
		ErrorMessage = VersionMismatchErrorOnGetData.ErrorText;
		Return;
	EndIf;
	
	BackgroundJobExecutionResult = Result;
	BackgroundJobExecutionResult.Insert("CompletionHandler", JobParameters.CompletionHandler);
	
	If Result.Status = "Running" Then
		
		TimeConsumingOperation = True;
		
		IdleParameters = TimeConsumingOperationsClient.IdleParameters(ThisObject);
		IdleParameters.OutputIdleWindow  = False;
		IdleParameters.OutputMessages     = True;
		
		BackgroundJobCompletionNotification = New NotifyDescription("BackgroundJobCompletionNotification", ThisObject);
		
		If UseProgressBar Then
			IdleParameters.OutputProgressBar     = True;
			IdleParameters.ExecutionProgressNotification = New NotifyDescription("BackgroundJobExecutionProgress", ThisObject);
			IdleParameters.Interval                       = 1;
		EndIf;
		
		TimeConsumingOperationsClient.WaitForCompletion(Result, BackgroundJobCompletionNotification, IdleParameters);
		
	Else
		// Job is completed, canceled, or completed with an error.
		AttachIdleHandler(JobParameters.CompletionHandler, 0.1, True);
	EndIf;
	
EndProcedure

&AtClient
Procedure BackgroundJobExecutionProgress(Progress, AdditionalParameters) Export
	
	If Progress = Undefined Then
		Return;
	EndIf;
	
	If Progress.Progress <> Undefined Then
		ProgressStructure      = Progress.Progress;
		
		AdditionalProgressParameters = Undefined;
		If Not ProgressStructure.Property("AdditionalParameters", AdditionalProgressParameters) Then
			Return;
		EndIf;
		
		If Not AdditionalProgressParameters.Property("DataExchange") Then
			Return;
		EndIf;
		
		ProgressPercent       = ProgressStructure.Percent;
		ProgressAdditionalInformation = ProgressStructure.Text;
	EndIf;
	
EndProcedure

&AtServer
Function ScheduledJobStartAtServer(JobParameters)
	
	OperationStartDate  = CurrentSessionDate();
	ExecutionParameters = TimeConsumingOperations.BackgroundExecutionParameters(UUID);
	ExecutionParameters.BackgroundJobDescription = JobParameters.JobDescription;
	
	Result = TimeConsumingOperations.ExecuteInBackground(
		JobParameters.MethodBeingExecuted,
		JobParameters.MethodParameters,
		ExecutionParameters);
	
	Return Result;
	
EndFunction

&AtClient
Procedure BackgroundJobCompletionNotification(Result, AdditionalParameters) Export
	
	CompletionHandler = BackgroundJobExecutionResult.CompletionHandler;
	BackgroundJobExecutionResult = Result;
	
	// Job is completed, canceled, or completed with an error.
	AttachIdleHandler(CompletionHandler, 0.1, True);
	
EndProcedure

&AtClient
Procedure ProcessBackgroundJobExecutionStatus()
	If BackgroundJobExecutionResult.Status = "Error" Then
		ErrorMessage = BackgroundJobExecutionResult.DetailedErrorPresentation;
	ElsIf BackgroundJobExecutionResult.Status = "Canceled" Then
		ErrorMessage = NStr("ru = 'Действие отменено пользователем.'; en = 'The operation was canceled by user.'; pl = 'Operacja została anulowana przez użytkownika.';de = 'Die Aktion wurde vom Benutzer abgebrochen.';ro = 'Acțiunea este revocată de utilizator.';tr = 'Eylem kullanıcı tarafından iptal edildi.'; es_ES = 'Acción cancelada por usuario.'");
	EndIf;
EndProcedure

#EndRegion

////////////////////////////////////////////////////////////////////////////////
// SECTION OF STEP CHANGE HANDLERS

#Region NavigationEventHandlers

&AtClient
Function Attachable_StartPage_OnGoNext(Cancel)
	
	// Check filling of form attributes.
	If Object.InfobaseNode.IsEmpty() Then
		
		NString = NStr("ru = 'Укажите узел информационной базы'; en = 'Please specify the infobase node.'; pl = 'Podaj węzeł bazy informacyjnej';de = 'Geben Sie einen Infobase-Knoten an';ro = 'Indicați nodul bazei de informații';tr = 'Bir veritabanı ünitesini belirtin.'; es_ES = 'Especificar un nodo de la infobase'");
		CommonClient.MessageToUser(NString, , "Object.InfobaseNode", , Cancel);
		
	ElsIf Object.ExchangeMessagesTransportKind.IsEmpty()
		AND Not EmailReceivedForDataMapping Then
		
		NString = NStr("ru = 'Укажите вариант подключения'; en = 'Please specify the connection option.'; pl = 'Podaj opcję połączenia';de = 'Geben Sie die Verbindungsoption an';ro = 'Indicați varianta de conectare';tr = 'Bağlantı opsiyonunu belirtin'; es_ES = 'Especificar la opción de conexión'");
		CommonClient.MessageToUser(NString, , "Object.ExchangeMessagesTransportKind", , Cancel);
		
	ElsIf ExchangeOverWebService AND IsBlankString(WSPassword) Then
		
		NString = NStr("ru = 'Не указан пароль.'; en = 'Please enter the password.'; pl = 'Hasło nie zostało określone.';de = 'Passwort ist nicht angegeben.';ro = 'Parola nu este specificată.';tr = 'Şifre belirtilmemiş.'; es_ES = 'Contraseña no está especificada.'");
		CommonClient.MessageToUser(NString, , "WSPassword", , Cancel);
		
	EndIf;
	
	Return Undefined;
	
EndFunction

&AtClient
Function Attachable_ConnectionCheckIdlePage_TimeConsumingOperationHandler(Cancel, GoToNext)
	
	If ExchangeOverExternalConnection Then
		If CommonClient.FileInfobase() Then
			CommonClient.RegisterCOMConnector(False);
		EndIf;
		Return Undefined;
	EndIf;
	
	If ExchangeOverWebService Then
		TestConnectionAndSaveSettings(Cancel);
		If Cancel Then
			ShowMessageBox(, NStr("ru = 'Не удалось выполнить операцию.'; en = 'Cannot perform the operation.'; pl = 'Nie można wykonać tej operacji.';de = 'Die Operation kann nicht ausgeführt werden.';ro = 'Nu se poate executa operația.';tr = 'İşlem yapılamıyor.'; es_ES = 'No se puede ejecutar la operación.'"));
		EndIf;
	EndIf;
	
	Return Undefined;
	
EndFunction

&AtServer
Procedure TestConnectionAndSaveSettings(Cancel)
	
	ConnectionParameters = DataExchangeServer.WSParameterStructure();
	SavedParameters = InformationRegisters.DataExchangeTransportSettings.TransportSettingsWS(Object.InfobaseNode);
	
	FillPropertyValues(ConnectionParameters, SavedParameters);
	
	If Not SkipTransportPage Then
		ConnectionParameters.WSPassword = WSPassword;
	EndIf;
	
	UserMessage = "";
	WSProxy = DataExchangeServer.GetWSProxy(ConnectionParameters, , UserMessage);
	
	If WSProxy = Undefined Then
		Common.MessageToUser(UserMessage, , "WSPassword", , Cancel);
		Return;
	EndIf;
	
	If Not SkipTransportPage Then
		
		Try
			
			SetPrivilegedMode(True);
			
			// Updating record in the information register.
			RecordStructure = New Structure;
			RecordStructure.Insert("Correspondent", Object.InfobaseNode);
			RecordStructure.Insert("WSRememberPassword", True);
			RecordStructure.Insert("WSPassword", WSPassword);
			
			InformationRegisters.DataExchangeTransportSettings.UpdateRecord(RecordStructure);
			
			WSPassword = String(ThisObject.UUID);
			
		Except
			
			ErrorMessage = DetailErrorDescription(ErrorInfo());
			
			WriteLogEvent(DataExchangeServer.EventLogMessageTextDataExchange(),
				EventLogLevel.Error, , , ErrorMessage);
				
			Common.MessageToUser(ErrorMessage, , , , Cancel);
			Return;
			
		EndTry;
		
	EndIf;
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Pages of data receipt processing (exchange message transport).

&AtClient
Function Attachable_DataAnalysisIdlePage_OnOpen(Cancel, SkipPage, IsMoveNext)
	
	InitializeDataProcessorVariables();
	
	Return Undefined;
	
EndFunction

&AtClient
Function Attachable_DataAnalysisIdlePage_TimeConsumingOperationProcessing(Cancel, GoToNext)
	
	SkipGettingData = False;
	GoToNext              = False;
	
	MethodParameters = New Structure;
	MethodParameters.Insert("Cancel", False);
	MethodParameters.Insert("TimeConsumingOperation",                   TimeConsumingOperation);
	MethodParameters.Insert("OperationID",                OperationID);
	MethodParameters.Insert("DataPackageFileID",       DataPackageFileID);
	MethodParameters.Insert("FileID",                   FileID);
	MethodParameters.Insert("ExchangeMessageFileName",              Object.ExchangeMessageFileName);
	MethodParameters.Insert("InfobaseNode",               Object.InfobaseNode);
	MethodParameters.Insert("TempExchangeMessageCatalogName", Object.TempExchangeMessageCatalogName);
	MethodParameters.Insert("ExchangeMessagesTransportKind",         Object.ExchangeMessagesTransportKind);
	MethodParameters.Insert("WSPassword",                             Undefined);
	
	MethodParameters.Insert("EmailReceivedForDataMapping", EmailReceivedForDataMapping);
	
	JobParameters = BackgroundJobParameters();
	JobParameters.MethodBeingExecuted     = "DataProcessors.InteractiveDataExchangeWizard.GetExchangeMessageToTemporaryDirectory";
	JobParameters.MethodParameters      = MethodParameters;
	JobParameters.JobDescription  = NStr("ru = 'Получение сообщения обмена во временный каталог'; en = 'Get exchange message to temporary directory'; pl = 'Otrzymanie wiadomości wymiany do katalogu tymczasowego';de = 'Empfangen einer Austauschnachricht in einem temporären Verzeichnis';ro = 'Obținerea mesajului de schimb în catalogul temporar';tr = 'Alışveriş mesajının geçici dizine alınıyor'; es_ES = 'Recepción del mensaje de cambio en el catálogo temporal'");
	JobParameters.CompletionHandler = "DataReceiptToTemporaryFolderCompletion";
	
	BackgroundJobStartClient(JobParameters, Cancel);
	
	Return Undefined;
	
EndFunction

&AtClient
Procedure DataReceiptToTemporaryFolderCompletion()
	
	ProcessBackgroundJobExecutionStatus();
	
	If ValueIsFilled(ErrorMessage) Then
		SkipGettingData = True;
	Else
		GetDataToTemporaryDirectoryAtServerCompletion();
	EndIf;
	
	If TimeConsumingOperation AND Not SkipGettingData Then
		AttachIdleHandler("TimeConsumingOperationIdleHandler", 5, True);
	Else
		AttachIdleHandler("GoNextExecute", 0.1, True);
	EndIf;
	
EndProcedure

&AtClient
Function Attachable_DataAnalysisIdlePageTimeConsumingOperationCompletion_TimeConsumingOperationProcessing(Cancel, GoToNext)
	
	If SkipGettingData Then
		Return Undefined;
	EndIf;
	
	If TimeConsumingOperationCompleted
		AND Not TimeConsumingOperationCompletedWithError Then
		
		// Get the file prepared at the correspondent to the temporary directory.
		If Not ValueIsFilled(Object.ExchangeMessageFileName) Then
			
			GoToNext = False;
			
			MethodParameters = New Structure;
			MethodParameters.Insert("Cancel",                                False);
			MethodParameters.Insert("FileID",                   FileID);
			MethodParameters.Insert("DataPackageFileID",       DataPackageFileID);
			MethodParameters.Insert("InfobaseNode",               Object.InfobaseNode);
			MethodParameters.Insert("ExchangeMessageFileName",              Object.ExchangeMessageFileName);
			MethodParameters.Insert("TempExchangeMessageCatalogName", Object.TempExchangeMessageCatalogName);
			MethodParameters.Insert("WSPassword",                             Undefined);
			
			JobParameters = BackgroundJobParameters();
			JobParameters.MethodBeingExecuted     = "DataProcessors.InteractiveDataExchangeWizard.GetExchangeMessageFromCorrespondentToTemporaryDirectory";
			JobParameters.MethodParameters      = MethodParameters;
			JobParameters.JobDescription  = NStr("ru = 'Получение файла с данными сообщения обмена во временный каталог'; en = 'Get exchange message file to temporary directory'; pl = 'Pobieranie pliku z danymi wiadomości wymiany do katalogu tymczasowego';de = 'Empfangen einer Datei mit Datenaustauschnachrichten in einem temporären Verzeichnis';ro = 'Obținerea fișierului cu datele mesajului de schimb în catalogul temporar';tr = 'Geçici bir dizine alışveriş mesajı verileri ile bir dosya alma'; es_ES = 'Recepción de archivo de datos con los datos del mensaje de cambio en el catálogo temporal'");
			JobParameters.CompletionHandler = "CorrespondentDataReceiptToTemporaryFolderCompletion";
			
			BackgroundJobStartClient(JobParameters, Cancel);
			
		EndIf;
		
	EndIf;
	
	Return Undefined;
	
EndFunction

&AtClient
Procedure CorrespondentDataReceiptToTemporaryFolderCompletion()
	
	ProcessBackgroundJobExecutionStatus();
	
	If ValueIsFilled(ErrorMessage) Then
		SkipGettingData = True;
	Else
		GetDataToTemporaryDirectoryAtServerCompletion();
	EndIf;
	
	AttachIdleHandler("GoNextExecute", 0.1, True);
	
EndProcedure

&AtServer
Procedure GetDataToTemporaryDirectoryAtServerCompletion()
	
	ErrorMessageTemplate = NStr("ru = 'Не удалось выполнить загрузку данных. Подробности см. в журнале регистрации'; en = 'Cannot import data. See the event log for details.'; pl = 'Nie udało się wykonać pobieranie danych. Szczegóły można znaleźć w dzienniku rejestracji';de = 'Daten konnten nicht geladen werden. Einzelheiten finden Sie im Ereignisprotokoll';ro = 'Eșec la executarea importului datelor. Detalii vezi în registrul logare';tr = 'Veriler içe aktarılamadı. Ayrıntılar için olay günlüğüne bakın.'; es_ES = 'No se ha podido descargar los datos. Véase más en el registro'");
	MethodExecutionResult = GetFromTempStorage(BackgroundJobExecutionResult.ResultAddress);
	
	If MethodExecutionResult = Undefined Then
		If Not ValueIsFilled(ErrorMessage) Then
			ErrorMessage = ErrorMessageTemplate;
		EndIf;
	Else
		
		If MethodExecutionResult.Cancel Then
			If Not ValueIsFilled(ErrorMessage) Then
				ErrorMessage = ErrorMessageTemplate;
			EndIf;
		Else
			
			FillPropertyValues(ThisObject, MethodExecutionResult);
			
			Object.ExchangeMessageFileName              = MethodExecutionResult.ExchangeMessageFileName;
			Object.TempExchangeMessageCatalogName = MethodExecutionResult.TempExchangeMessageCatalogName;
			
		EndIf;
			
	EndIf;
	
	If ValueIsFilled(ErrorMessage) Then
		
		TimeConsumingOperation                  = False;
		TimeConsumingOperationCompleted         = True;
		TimeConsumingOperationCompletedWithError = True;
		SkipGettingData           = True;
		
		DataExchangeServerCall.RecordExchangeCompletionWithError(
			Object.InfobaseNode,
			"DataImport",
			OperationStartDate,
			ErrorMessage);
			
	EndIf;
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Data analysis pages (automatic data mapping).

&AtClient
Function Attachable_DataAnalysisPage_OnOpen(Cancel, SkipPage, IsMoveNext)
	
	If SkipGettingData Then
		SkipPage = True;
	Else
		InitializeDataProcessorVariables();
	EndIf;
	
	Return Undefined;
	
EndFunction

&AtClient
Function Attachable_DataAnalysis_TimeConsumingOperationProcessing(Cancel, GoToNext)
	
	If SkipGettingData Then
		Return Undefined;
	EndIf;
	
	GoToNext = False;
	
	MethodParameters = New Structure;
	MethodParameters.Insert("InfobaseNode",               Object.InfobaseNode);
	MethodParameters.Insert("ExchangeMessageFileName",              Object.ExchangeMessageFileName);
	MethodParameters.Insert("TempExchangeMessageCatalogName", Object.TempExchangeMessageCatalogName);
	MethodParameters.Insert("CheckVersionDifference",           CheckVersionDifference);
	
	JobParameters = BackgroundJobParameters();
	JobParameters.MethodBeingExecuted     = "DataProcessors.InteractiveDataExchangeWizard.ExecuteAutomaticDataMapping";
	JobParameters.MethodParameters      = MethodParameters;
	JobParameters.JobDescription  = NStr("ru = 'Анализ данных сообщения обмена'; en = 'Analyze exchange message data'; pl = 'Analiza danych wiadomości wymiany';de = 'Analyse von Austauschnachrichtendaten';ro = 'Analiza datelor mesajului de schimb';tr = 'Alışveriş mesajı verilerinin analizi'; es_ES = 'Análisis de los datos de mensajes de intercambio'");
	JobParameters.CompletionHandler = "DataAnalysisCompletion";
	
	BackgroundJobStartClient(JobParameters, Cancel);
	
	Return Undefined;
	
EndFunction

&AtClient
Procedure DataAnalysisCompletion()
	
	ProcessBackgroundJobExecutionStatus();
	
	If Not SkipGettingData AND ValueIsFilled(ErrorMessage) Then
		SkipGettingData = True;
		DataExchangeServerCall.RecordExchangeCompletionWithError(
			Object.InfobaseNode,
			"DataImport",
			OperationStartDate,
			ErrorMessage);
	Else
		AtalyzeDataAtServerCompletion();
	EndIf;
	
	If ForceCloseForm Then
		ThisObject.Close();
	EndIf;

	If Not SkipGettingData Then
		ExpandStatisticsTree();
	EndIf;
	
	AttachIdleHandler("GoNextExecute", 0.1, True);
	
EndProcedure

&AtServer
Procedure AtalyzeDataAtServerCompletion()
	
	RecordError = False;
	
	// Checking the transition to a new data exchange.
	CheckWhetherTransferToNewExchangeIsRequired();
	If ForceCloseForm Then
		Return;
	EndIf;
	
	Try
		
		AnalysisResult = GetFromTempStorage(BackgroundJobExecutionResult.ResultAddress);
		
		If AnalysisResult.Property("ErrorText") Then
			VersionMismatchErrorOnGetData = AnalysisResult;
		ElsIf AnalysisResult.Cancel Then
			
			SkipGettingData = True;
			RecordError       = True;
			
			If AnalysisResult.Property("ExchangeExecutionResult")
				AND AnalysisResult.ExchangeExecutionResult = Enums.ExchangeExecutionResults.Warning_ExchangeMessageAlreadyAccepted Then
				
				ExchangeSettingsStructure = New Structure;
				ExchangeSettingsStructure.Insert("InfobaseNode",       Object.InfobaseNode);
				ExchangeSettingsStructure.Insert("ExchangeExecutionResult",    AnalysisResult.ExchangeExecutionResult);
				ExchangeSettingsStructure.Insert("ActionOnExchange",            "DataImport");
				ExchangeSettingsStructure.Insert("ProcessedObjectsCount", 0);
				ExchangeSettingsStructure.Insert("StartDate",                   OperationStartDate);
				ExchangeSettingsStructure.Insert("EndDate",                CurrentSessionDate());
				ExchangeSettingsStructure.Insert("EventLogMessageKey", 
					DataExchangeServer.EventLogMessageKey(Object.InfobaseNode, "DataImport"));
				ExchangeSettingsStructure.Insert("IsDIBExchange", 
					DataExchangeCached.IsDistributedInfobaseNode(Object.InfobaseNode));
				
				DataExchangeServer.AddExchangeCompletionEventLogMessage(ExchangeSettingsStructure);
				
			EndIf;
			
		Else
			
			AllDataMapped   = AnalysisResult.AllDataMapped;
			HasUnmappedMasterData = AnalysisResult.HasUnmappedMasterData;
			StatisticsBlank        = AnalysisResult.StatisticsBlank;
			
			Object.StatisticsInformation.Load(AnalysisResult.StatisticsInformation);
			Object.StatisticsInformation.Sort("Presentation");
			
			StatisticsInformation(Object.StatisticsInformation.Unload());
			
			SetAdditionalInfoGroupVisible();
			
		EndIf;
		
	Except
		SkipGettingData = True;
		ErrorMessage   = DetailErrorDescription(ErrorInfo());
		
		DataExchangeServerCall.RecordExchangeCompletionWithError(
			Object.InfobaseNode,
			"DataImport",
			OperationStartDate,
			ErrorMessage);
	EndTry;
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Pages of data mapping processing (interactive data mapping).

&AtClient
Function Attachable_StatisticsPage_OnOpen(Cancel, SkipPage, IsMoveNext)
	
	If StatisticsBlank Or SkipGettingData Then
		SkipPage = True;
		If EmailReceivedForDataMapping Then
			EndDataMapping = StatisticsBlank;
		EndIf;
	EndIf;
	
	If Not SkipPage Then
		Items.MappingCompletionGroup.Visible = EmailReceivedForDataMapping;
		OnChangeFlagEndDataMapping();
	EndIf;
	
	Return Undefined;
	
EndFunction

&AtClient
Function Attachable_StatisticsPage_OnGoNext(Cancel)
	
	If StatisticsBlank Or SkipGettingData Or AllDataMapped Or NOT HasUnmappedMasterData Then
		Return Undefined;
	EndIf;
	
	If SkipCurrentPageCancelControl = True Then
		SkipCurrentPageCancelControl = Undefined;
		Return Undefined;
	EndIf;
	
	// Going to the next page after user confirmation.
	Cancel = True;
	
	Buttons = New ValueList;
	Buttons.Add(DialogReturnCode.Yes,  NStr("ru = 'Продолжить'; en = 'Continue'; pl = 'Kontynuuj';de = 'Fortfahren';ro = 'Continuare';tr = 'Devam et'; es_ES = 'Continuar'"));
	Buttons.Add(DialogReturnCode.No, NStr("ru = 'Отмена'; en = 'Cancel'; pl = 'Anuluj';de = 'Abbrechen';ro = 'Revocare';tr = 'İptal'; es_ES = 'Cancelar'"));
	
	Message = NStr("ru = 'Не все данные сопоставлены. Наличие несопоставленных данных
	                       |может привести к появлению одинаковых элементов в списках (дублей).
	                       |Продолжить?'; 
	                       |en = 'Unmapped data is found. This might result in
	                       |duplication of list items.
	                       |Do you want to continue?'; 
	                       |pl = 'Nie wszystkie dane są dopasowane. Obecność niedopasowanych danych
	                       |może doprowadzić do pojawienia się identycznych elementów w listach (duplikatów).
	                       |Kontynuować?';
	                       |de = 'Nicht alle Daten stimmen überein. Das Vorhandensein nicht übereinstimmender Daten
	                       |kann dazu führen, dass identische Elemente in den Listen (Duplikate) erscheinen. 
	                       |Fortfahren?';
	                       |ro = 'Nu toate datele au fost confruntate. Prezența datelor neconfruntate
	                       |poate duce la apariția de elemente identice în liste (duplicate).
	                       |Continuați?';
	                       |tr = 'Tüm veriler eşlenmedi. Eşleşmeyen verilerin
	                       | varlığı aynı katalog öğelerine yol açabilir (kopyalar).
	                       |Devam et?'; 
	                       |es_ES = 'No todos los datos se han comparado. Existencia de datos no comparados
	                       |puede causar la aparición de los elementos del catálogo idénticos (duplicados).
	                       |¿Continuar?'");
	
	Notification = New NotifyDescription("StatisticsPage_OnGoNextQuestionCompletion", ThisObject);
	
	ShowQueryBox(Notification, Message, Buttons,, DialogReturnCode.Yes);
	
	Return Undefined;
	
EndFunction

// Continuation of the procedure (see above).
&AtClient
Procedure StatisticsPage_OnGoNextQuestionCompletion(Val QuestionResult, Val AdditionalParameters) Export
	
	If QuestionResult <> DialogReturnCode.Yes Then
		Return;
	EndIf;
	
	AttachIdleHandler("Attachable_GoStepForwardWithDeferredProcessing", 0.1, True);
	
EndProcedure

&AtClient
Procedure Attachable_GoStepForwardWithDeferredProcessing()
	
	// Going a step forward (forced).
	SkipCurrentPageCancelControl = True;
	ChangeNavigationNumber( +1 );
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Pages of data import processing

&AtClient
Function Attachable_DataImport_OnOpen(Cancel, SkipPage, IsMoveNext)
	
	If SkipGettingData Then
		SkipPage = True;
		If Not EmailReceivedForDataMapping Then
			DeleteTempExchangeMessagesDirectory(Object.TempExchangeMessageCatalogName);
		EndIf;
	Else
		InitializeDataProcessorVariables();
	EndIf;
	
	Return Undefined;
	
EndFunction

&AtClient
Function Attachable_DataImport_TimeConsumingOperationProcessing(Cancel, GoToNext)
	
	If SkipGettingData Then
		DeleteTempExchangeMessagesDirectory(Object.TempExchangeMessageCatalogName);
		Return Undefined;
	EndIf;
	
	GoToNext    = False;
	MethodParameters = New Structure;
	MethodParameters.Insert("InfobaseNode",  Object.InfobaseNode);
	MethodParameters.Insert("ExchangeMessageFileName", Object.ExchangeMessageFileName);
	
	JobParameters = BackgroundJobParameters();
	JobParameters.MethodBeingExecuted     = "DataProcessors.InteractiveDataExchangeWizard.RunDataImport";
	JobParameters.MethodParameters      = MethodParameters;
	JobParameters.JobDescription  = NStr("ru = 'Загрузка данных из сообщения обмена'; en = 'Import data from exchange message'; pl = 'Import danych z wiadomości wymiany';de = 'Importieren von Daten aus der Austauschnachricht';ro = 'Importul datelor din mesajul de schimb';tr = 'Verileri alışveriş mesajından içe aktar'; es_ES = 'Importar los datos del mensaje de intercambio'");
	JobParameters.CompletionHandler = "DataImportCompletion";
	
	BackgroundJobStartClient(JobParameters, Cancel);
	
	Return Undefined;
	
EndFunction

&AtClient
Procedure DataImportCompletion()
	
	ProcessBackgroundJobExecutionStatus();
	
	If ValueIsFilled(ErrorMessage) AND Not SkipGettingData Then
		SkipGettingData = True;
	EndIf;
	
	ProgressBarDisplayed = Items.MainPanel.CurrentPage = Items.DataSynchronizationWaitProgressBarImportPage
		Or Items.MainPanel.CurrentPage = Items.DataSynchronizationWaitProgressBarExportPage;
		
	If UseProgressBar AND ProgressBarDisplayed Then
		ProgressPercent       = 100;
		ProgressAdditionalInformation = "";
	EndIf;
	
	If SkipGettingData Then
		
		DataExchangeServerCall.RecordExchangeCompletionWithError(
			Object.InfobaseNode,
			"DataImport",
			OperationStartDate,
			ErrorMessage);
		
	EndIf;
		
	AttachIdleHandler("GoNextExecute", 0.1, True);
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Additional export pages (registration to additional data export).

&AtClient
Function Attachable_QuestionAboutExportContentPage_OnOpen(Cancel, SkipPage, IsMoveNext)
	
	If ExportAddition.ExportOption < 0 Then
		// According to the node settings, the addition of export is not performed, go to the next page.
		SkipPage = True;
	EndIf;
	
	Return Undefined;
	
EndFunction

&AtClient
Function Attachable_DataRegistrationPage_OnOpen(Cancel, SkipPage, IsMoveNext)
	
	If ExportAddition.ExportOption < 0 Then
		// According to the node settings, the addition of export is not performed, go to the next page.
		SkipPage = True;
	EndIf;
	
	Return Undefined;
	
EndFunction

&AtClient
Function Attachable_DataRegistrationPage_TimeConsumingOperationProcessing(Cancel, GoToNext)
	
	GoToNext = False;
	AttachIdleHandler("OnStartRecordData", 0.1, True);
	
	Return Undefined;
	
EndFunction

&AtClient
Procedure OnStartRecordData()
	
	ContinueWait = True;
	OnStartRecordDataAtServer(ContinueWait);
	
	If ContinueWait Then
		DataExchangeClient.InitializeIdleHandlerParameters(
			DataRegistrationIdleHandlerParameters);
			
		AttachIdleHandler("OnWaitForRecordData",
			DataRegistrationIdleHandlerParameters.CurrentInterval, True);
	Else
		AttachIdleHandler("OnCompleteDataRecording", 0.1, True);
	EndIf;
	
EndProcedure

&AtClient
Procedure OnWaitForRecordData()
	
	ContinueWait = False;
	OnWaitForRecordDataAtServer(DataRegistrationHandlerParameters, ContinueWait);
	
	If ContinueWait Then
		DataExchangeClient.UpdateIdleHandlerParameters(DataRegistrationIdleHandlerParameters);
		
		AttachIdleHandler("OnWaitForRecordData",
			DataRegistrationIdleHandlerParameters.CurrentInterval, True);
	Else
		AttachIdleHandler("OnCompleteDataRecording", 0.1, True);
	EndIf;
	
EndProcedure

&AtClient
Procedure OnCompleteDataRecording()
	
	DataRegistered = False;
	ErrorMessage = "";
	
	OnCompleteDataRecordingAtServer(DataRegistrationHandlerParameters, DataRegistered, ErrorMessage);
	
	If DataRegistered Then
		
		ChangeNavigationNumber(+1);
		
	Else
		ChangeNavigationNumber(-1);
		
		If Not IsBlankString(ErrorMessage) Then
			CommonClient.MessageToUser(ErrorMessage);
		Else
			CommonClient.MessageToUser(
				NStr("ru = 'Не удалось зарегистрировать данные для выгрузки.'; en = 'Cannot register data to export.'; pl = 'Nie udało się zarejestrować dane do ładowania.';de = 'Die Daten konnten nicht für den Upload registriert werden.';ro = 'Eșec la înregistrarea datelor pentru export.';tr = 'Dışa aktarılacak veriler kaydedilemedi.'; es_ES = 'No se ha podido registrar los datos para subir.'"));
		EndIf;
	EndIf;
	
EndProcedure

&AtServer
Procedure OnStartRecordDataAtServer(ContinueWait)
	
	RegistrationSettings = New Structure;
	RegistrationSettings.Insert("ExchangeNode", ExportAddition.InfobaseNode);
	RegistrationSettings.Insert("ExportAddition", Undefined);
	
	PrepareExportAdditionStructure(RegistrationSettings.ExportAddition);
	
	DataRegistrationHandlerParameters = Undefined;
	
	ModuleInteractiveExchangeWizard = DataExchangeServer.ModuleInteractiveDataExchangeWizard();
	ModuleInteractiveExchangeWizard.OnStartRecordData(RegistrationSettings,
		DataRegistrationHandlerParameters, ContinueWait);
	
EndProcedure
	
&AtServerNoContext
Procedure OnWaitForRecordDataAtServer(HandlerParameters, ContinueWait)
	
	ModuleInteractiveExchangeWizard = DataExchangeServer.ModuleInteractiveDataExchangeWizard();
	ModuleInteractiveExchangeWizard.OnWaitForRecordData(HandlerParameters, ContinueWait);
	
EndProcedure

&AtServerNoContext
Procedure OnCompleteDataRecordingAtServer(HandlerParameters, DataRegistered, ErrorMessage)
	
	CompletionStatus = Undefined;
	
	ModuleInteractiveExchangeWizard = DataExchangeServer.ModuleInteractiveDataExchangeWizard();
	ModuleInteractiveExchangeWizard.OnCompleteDataRecording(HandlerParameters, CompletionStatus);
	HandlerParameters = Undefined;
		
	If CompletionStatus.Cancel Then
		DataRegistered = False;
		ErrorMessage = CompletionStatus.ErrorMessage;
	Else
		DataRegistered = CompletionStatus.Result.DataRegistered;
		
		If Not DataRegistered Then
			ErrorMessage = CompletionStatus.Result.ErrorMessage;
		EndIf;
	EndIf;
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Data export processing pages

&AtClient
Function Attachable_DataExport_OnOpen(Cancel, SkipPage, IsMoveNext)
	
	InitializeDataProcessorVariables();
	
	Return Undefined;
	
EndFunction

&AtClient
Function Attachable_DataExportIdlePage_TimeConsumingOperationProcessing(Cancel, GoToNext)
	
	GoToNext = False;
	OnStartExportData(Cancel);
	
	Return Undefined;
	
EndFunction

&AtClient
Function Attachable_DataExportIdlePageTimeConsumingOperationCompletion_TimeConsumingOperationProcessing(Cancel, GoToNext)
	
	If TimeConsumingOperationCompleted
		AND Not TimeConsumingOperationCompletedWithError Then
		DataExchangeServerCall.RecordDataExportInTimeConsumingOperationMode(
			Object.InfobaseNode, OperationStartDate);
	EndIf;
	
	Return Undefined;
	
EndFunction

&AtClient
Procedure OnStartExportData(Cancel)
	
	If ExchangeBetweenSaaSApplications Then
		ContinueWait = True;
		OnStartExportDataAtServer(ContinueWait);
		
		If ContinueWait Then
			DataExchangeClient.InitializeIdleHandlerParameters(
				DataExportIdleHandlerParameters);
				
			AttachIdleHandler("OnWaitForExportData",
				DataExportIdleHandlerParameters.CurrentInterval, True);
		Else
			OnCompleteDataExport();
		EndIf;
	Else
		MethodParameters = New Structure;
		MethodParameters.Insert("InfobaseNode",       Object.InfobaseNode);
		MethodParameters.Insert("ExchangeMessagesTransportKind", Object.ExchangeMessagesTransportKind);
		MethodParameters.Insert("ExchangeMessageFileName",      Object.ExchangeMessageFileName);
		MethodParameters.Insert("TimeConsumingOperation",           TimeConsumingOperation);
		MethodParameters.Insert("OperationID",        OperationID);
		MethodParameters.Insert("FileID",           FileID);
		MethodParameters.Insert("WSPassword",                     Undefined);
		MethodParameters.Insert("Cancel",                        False);
		
		JobParameters = BackgroundJobParameters();
		JobParameters.MethodBeingExecuted     = "DataProcessors.InteractiveDataExchangeWizard.RunDataExport";
		JobParameters.MethodParameters      = MethodParameters;
		JobParameters.JobDescription  = NStr("ru = 'Выгрузка данных в сообщение обмена'; en = 'Export data to exchange message'; pl = 'Ładowanie danych do wiadomości wymiany';de = 'Hochladen von Daten in eine Austauschnachricht';ro = 'Exportul datelor în mesajul de schimb';tr = 'Verilerin alışveriş mesajına dışa aktarma'; es_ES = 'Subida de datos en mensaje de cambio'");
		JobParameters.CompletionHandler = "DataExportCompletion";
		
		BackgroundJobStartClient(JobParameters, Cancel);
	EndIf;
	
EndProcedure

&AtClient
Procedure OnWaitForExportData()
	
	ContinueWait = False;
	OnWaitForExportDataAtServer(DataExportHandlerParameters, ContinueWait);
	
	If ContinueWait Then
		DataExchangeClient.UpdateIdleHandlerParameters(DataExportIdleHandlerParameters);
		
		AttachIdleHandler("OnWaitForExportData",
			DataExportIdleHandlerParameters.CurrentInterval, True);
	Else
		OnCompleteDataExport();
	EndIf;
	
EndProcedure

&AtClient
Procedure OnCompleteDataExport()
	
	DataExported = False;
	ErrorMessage = "";
	
	OnCompleteDataUnloadAtServer(DataExportHandlerParameters, DataExported, ErrorMessage);
	
	If DataExported Then
		ChangeNavigationNumber(+1);
	Else
		ChangeNavigationNumber(-1);
		
		If Not IsBlankString(ErrorMessage) Then
			CommonClient.MessageToUser(ErrorMessage);
		Else
			CommonClient.MessageToUser(
				NStr("ru = 'Не удалось выполнить обмен данными.'; en = 'Cannot perform data exchange.'; pl = 'Nie udało się wykonać wymianę danych.';de = 'Der Datenaustausch ist fehlgeschlagen.';ro = 'Eșec la executarea schimbului de date.';tr = 'Veri alışverişi yapılamadı.'; es_ES = 'No se ha podido intercambiar los datos.'"));
		EndIf;
	EndIf;
	
EndProcedure

&AtServer
Procedure OnStartExportDataAtServer(ContinueWait)
	
	ModuleInteractiveExchangeWizard = DataExchangeServer.ModuleInteractiveDataExchangeWizardInSaaS();
	
	If ModuleInteractiveExchangeWizard = Undefined Then
		ContinueWait = False;
		Return;
	EndIf;
	
	ExportSettings = New Structure;
	ExportSettings.Insert("Correspondent", Object.InfobaseNode);
	ExportSettings.Insert("CorrespondentDataArea", CorrespondentDataArea);
	ExportSettings.Insert("ExportAddition", Undefined);
	
	PrepareExportAdditionStructure(ExportSettings.ExportAddition);
	
	DataExportHandlerParameters = Undefined;
	ModuleInteractiveExchangeWizard.OnStartExportData(ExportSettings,
		DataExportHandlerParameters, ContinueWait);
	
EndProcedure
	
&AtServerNoContext
Procedure OnWaitForExportDataAtServer(HandlerParameters, ContinueWait)
	
	ModuleInteractiveExchangeWizard = DataExchangeServer.ModuleInteractiveDataExchangeWizardInSaaS();
	
	If ModuleInteractiveExchangeWizard = Undefined Then
		ContinueWait = False;
		Return;
	EndIf;
	
	ModuleInteractiveExchangeWizard.OnWaitForExportData(HandlerParameters, ContinueWait);
	
EndProcedure

&AtServerNoContext
Procedure OnCompleteDataUnloadAtServer(HandlerParameters, DataExported, ErrorMessage)
	
	ModuleInteractiveExchangeWizard = DataExchangeServer.ModuleInteractiveDataExchangeWizardInSaaS();
	
	If ModuleInteractiveExchangeWizard = Undefined Then
		DataExported = False;
		Return;
	EndIf;
	
	CompletionStatus = Undefined;
	
	ModuleInteractiveExchangeWizard.OnCompleteExportData(HandlerParameters, CompletionStatus);
	HandlerParameters = Undefined;
		
	If CompletionStatus.Cancel Then
		DataExported = False;
		ErrorMessage = CompletionStatus.ErrorMessage;
		Return;
	Else
		DataExported = CompletionStatus.Result.DataExported;
		
		If Not DataExported Then
			ErrorMessage = CompletionStatus.Result.ErrorMessage;
			Return;
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure DataExportCompletion()
	
	ProcessBackgroundJobExecutionStatus();
	
	ProgressBarDisplayed = Items.MainPanel.CurrentPage = Items.DataSynchronizationWaitProgressBarImportPage
		Or Items.MainPanel.CurrentPage = Items.DataSynchronizationWaitProgressBarExportPage;
	
	If UseProgressBar AND ProgressBarDisplayed Then
		ProgressPercent       = 100;
		ProgressAdditionalInformation = "";
	EndIf;
	
	DataExportCompletionAtServer();
	
	If TimeConsumingOperation AND Not ValueIsFilled(ErrorMessage) Then
		AttachIdleHandler("TimeConsumingOperationIdleHandler", 5, True);
	Else
		DeleteTempExchangeMessagesDirectory(Object.TempExchangeMessageCatalogName);
		AttachIdleHandler("GoNextExecute", 0.1, True);
	EndIf;
	
EndProcedure

&AtServer
Procedure DataExportCompletionAtServer()
	
	MethodExecutionResult = GetFromTempStorage(BackgroundJobExecutionResult.ResultAddress);
	
	If MethodExecutionResult = Undefined Then
		MethodExecutionResult = New Structure("Cancel", True);
	Else
		FillPropertyValues(ThisObject, MethodExecutionResult, 
			"TimeConsumingOperation, OperationID, FileID");
	EndIf;
	
	If MethodExecutionResult.Cancel
		AND Not ValueIsFilled(ErrorMessage) Then
		ErrorMessage = NStr("ru = 'Не удалось выполнить отправку данных. Подробности см. в журнале регистрации'; en = 'Cannot send data. See the event log for details.'; pl = 'Nie udało się wykonać wysyłanie danych. Szczegóły można znaleźć w dzienniku rejestracji';de = 'Die Daten konnten nicht gesendet werden. Siehe das Ereignisprotokoll für Details';ro = 'Eșec la executarea trimiterii datelor. Detalii vezi în registrul logare';tr = 'Veriler gönderilemedi. Ayrıntılar için olay günlüğüne bakın.'; es_ES = 'No se ha podido enviar los datos. Véase más en el registro'");
	EndIf;
	
	If ValueIsFilled(ErrorMessage) Then
		
		TimeConsumingOperation                  = False;
		TimeConsumingOperationCompleted         = True;
		TimeConsumingOperationCompletedWithError = True;
		
		DataExchangeServerCall.RecordExchangeCompletionWithError(
			Object.InfobaseNode,
			"DataExport",
			OperationStartDate,
			ErrorMessage);
			
	EndIf;
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Summary information pages

&AtClient
Function Attachable_MappingCompletionPage_OnOpen(Cancel, SkipPage, Val IsMoveNext)
	
	GetDataExchangesStates(DataImportResult, DataExportResult, Object.InfobaseNode);
	
	RefreshDataExchangeStatusItemPresentation();
	
	ForceCloseForm = True;
	
	Return Undefined;
	
EndFunction

#EndRegion

////////////////////////////////////////////////////////////////////////////////
// FILLING WIZARD NAVIGATION TABLE SECTION

&AtServer
Procedure FillNavigationTable()
	
	If UseProgressBar Then
		PageNameSynchronizationImport = "DataSynchronizationWaitProgressBarImportPage";
		PageNameSynchronizationExport = "DataSynchronizationWaitProgressBarExportPage";
	Else
		PageNameSynchronizationImport = "DataSynchronizationWaitPage";
		PageNameSynchronizationExport = "DataSynchronizationWaitPage";
	EndIf;
	
	NavigationTable.Clear();
	
	If Not SkipTransportPage Then
		NavigationTableNewRow("StartPage", "NavigationStartPage", , "BeginningPage_OnGoNext");
	EndIf;
	
	If ExchangeBetweenSaaSApplications Then
		
		If EmailReceivedForDataMapping Then
			// Getting data (exchange message transport.
			NavigationTableNewRowTimeConsumingOperation("DataAnalysisWaitPage", "NavigationWaitPage", True, "DataAnalysisWaitingPage_TimeConsumingOperationProcessing", "DataAnalysisWaitingPage_OnOpen");
			
			// Data analysis. Automatic data mapping.
			NavigationTableNewRowTimeConsumingOperation("DataAnalysisWaitPage", "NavigationWaitPage", True, "DataAnalysis_TimeConsumingOperationProcessing", "DataAnalysisPage_OnOpen");
			
			// Manual data mapping.
			NavigationTableNewRow("StatisticsInformationPage", "StatisticsInformationNavigationPage", "StatisticsInformationPage_OnOpen", "StatisticsInformationPage_OnGoNext");
			
			// Data import.
			NavigationTableNewRowTimeConsumingOperation(PageNameSynchronizationImport, "NavigationWaitPage", True, "DataImport_TimeConsumingOperationProcessing", "DataImport_OnOpen");
		EndIf;
		
		If SendData Then
			
			If ExportAdditionMode Then
				DataExportResult = "";
				NavigationTableNewRow("QuestionAboutExportCompositionPage", "NavigationPageFollowUp", "QuestionAboutExportCompositionPage_OnOpen");
			EndIf;
			
			// Export and import data.
			NavigationTableNewRowTimeConsumingOperation(PageNameSynchronizationExport, "NavigationWaitPage", True, "DataExportWaitingPage_TimeConsumingOperationProcessing", "DataExport_OnOpen");
		EndIf;
		
	Else
		
		If ExchangeOverWebService
			Or ExchangeOverExternalConnection Then
			// Testing connection.
			If GetData Then
				NavigationTableNewRowTimeConsumingOperation("DataAnalysisWaitPage", "NavigationWaitPage", True, "ConnectionTestWaitingPage_TimeConsumingOperationProcessing");
			Else
				NavigationTableNewRowTimeConsumingOperation("DataSynchronizationWaitPage", "NavigationWaitPage", True, "ConnectionTestWaitingPage_TimeConsumingOperationProcessing");
			EndIf;
		EndIf;
		
		If GetData Then
			// Getting data (exchange message transport.
			NavigationTableNewRowTimeConsumingOperation("DataAnalysisWaitPage", "NavigationWaitPage", True, "DataAnalysisWaitingPage_TimeConsumingOperationProcessing", "DataAnalysisWaitingPage_OnOpen");
			If ExchangeOverWebService Then
				NavigationTableNewRowTimeConsumingOperation("DataAnalysisWaitPage", "NavigationWaitPage", True, "DataAnalysisWaitingPageTimeConsumingOperationCompletion_TimeConsumingOperationProcessing");
			EndIf;
			
			// Data analysis. Automatic data mapping.
			NavigationTableNewRowTimeConsumingOperation("DataAnalysisWaitPage", "NavigationWaitPage", True, "DataAnalysis_TimeConsumingOperationProcessing", "DataAnalysisPage_OnOpen");
			
			// Manual data mapping.
			If EmailReceivedForDataMapping Then
				NavigationTableNewRow("StatisticsInformationPage", "StatisticsInformationNavigationPage", "StatisticsInformationPage_OnOpen", "StatisticsInformationPage_OnGoNext");
			Else
				NavigationTableNewRow("StatisticsInformationPage", "NavigationPageFollowUp", "StatisticsInformationPage_OnOpen", "StatisticsInformationPage_OnGoNext");
			EndIf;
			
			// Data import.
			NavigationTableNewRowTimeConsumingOperation(PageNameSynchronizationImport, "NavigationWaitPage", True, "DataImport_TimeConsumingOperationProcessing", "DataImport_OnOpen");
		EndIf;
		
		If SendData Then
			If ExportAdditionMode Then
				// Data export setup.
				DataExportResult = "";
				NavigationTableNewRow("QuestionAboutExportCompositionPage", "NavigationPageFollowUp", "QuestionAboutExportCompositionPage_OnOpen");
				
				// The time-consuming operation of registering additional data to export.
				NavigationTableNewRowTimeConsumingOperation("DataRegistrationPage", "NavigationWaitPage", True, "DataRegistrationPage_TimeConsumingOperationProcessing", "DataRegistrationPage_OnOpen");
			EndIf;
			
			// Exporting data.
			NavigationTableNewRowTimeConsumingOperation(PageNameSynchronizationExport, "NavigationWaitPage", True, "DataExportWaitingPage_TimeConsumingOperationProcessing", "DataExport_OnOpen");
			If ExchangeOverWebService Then
				NavigationTableNewRowTimeConsumingOperation(PageNameSynchronizationExport, "NavigationWaitPage", True, "DataExportWaitingPageTimeConsumingOperationCompletion_TimeConsumingOperationProcessing");
			EndIf;
		EndIf;
		
	EndIf;
	
	// Totals.
	NavigationTableNewRow("MappingCompletePage", "NavigationEndPage", "MappingCompletePage_OnOpen");
	
EndProcedure

#EndRegion

#EndRegion