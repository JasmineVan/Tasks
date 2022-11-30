
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
	
	If Parameters.ChoiceMode Then
		WindowOpeningMode = FormWindowOpeningMode.LockOwnerWindow;
	EndIf;
	
	If Parameters.Property("Title") Then
		AutoTitle = False;
		Title = Parameters.Title;
	EndIf;
	If Parameters.Property("Representation") Then
		Items.List.Representation = TableRepresentation[Parameters.Representation];
	EndIf;
	
	PublicationsKindsList = Items.PublicationFilter.ChoiceList;
	
	KindUsed = Enums.AdditionalReportsAndDataProcessorsPublicationOptions.Used;
	KindDebugMode = Enums.AdditionalReportsAndDataProcessorsPublicationOptions.DebugMode;
	
	AvaliablePublicationKinds = AdditionalReportsAndDataProcessorsCached.AvaliablePublicationKinds();
	
	AllPublicationsExceptDisabled = New Array;
	AllPublicationsExceptDisabled.Add(KindUsed);
	If AvaliablePublicationKinds.Find(KindDebugMode) <> Undefined Then
		AllPublicationsExceptDisabled.Add(KindDebugMode);
	EndIf;
	If AllPublicationsExceptDisabled.Count() > 1 Then
		ArrayPresentation = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = '%1 или %2'; en = '%1 or %2'; pl = '%1 lub %2';de = '%1 oder %2';ro = '%1 sau %2';tr = '%1 ya da %2'; es_ES = '%1 o %2'"),
			String(AllPublicationsExceptDisabled[0]),
			String(AllPublicationsExceptDisabled[1]));
		PublicationsKindsList.Add(1, ArrayPresentation);
	EndIf;
	For Each EnumValue In Enums.AdditionalReportsAndDataProcessorsPublicationOptions Do
		If AvaliablePublicationKinds.Find(EnumValue) <> Undefined Then
			PublicationsKindsList.Add(EnumValue, String(EnumValue));
		EndIf;
	EndDo;
	
	If Parameters.Filter.Property("Publication") Then
		PublicationFilter = Parameters.Filter.Publication;
		Parameters.Filter.Delete("Publication");
		If PublicationsKindsList.FindByValue(PublicationFilter) = Undefined Then
			PublicationFilter = Undefined;
		EndIf;
	EndIf;
	
	ChoiceList = Items.KindFilter.ChoiceList;
	ChoiceList.Add(1, NStr("ru = 'Только отчеты'; en = 'Reports only'; pl = 'Tylko sprawozdania';de = 'Nur Berichte';ro = 'Numai rapoarte';tr = 'Yalnızca raporlar'; es_ES = 'Solo informes'"));
	ChoiceList.Add(2, NStr("ru = 'Только обработки'; en = 'Data processors only'; pl = 'Tylko opracowania';de = 'Nur Datenprozessoren';ro = 'Numai procesări';tr = 'Yalnızca veri işlemcileri'; es_ES = 'Solo procesadores de datos'"));
	For Each EnumValue In Enums.AdditionalReportsAndDataProcessorsKinds Do
		ChoiceList.Add(EnumValue, String(EnumValue));
	EndDo;
	
	AddlReportsKinds = New Array;
	AddlReportsKinds.Add(Enums.AdditionalReportsAndDataProcessorsKinds.AdditionalReport);
	AddlReportsKinds.Add(Enums.AdditionalReportsAndDataProcessorsKinds.Report);
	
	List.Parameters.SetParameterValue("PublicationFilter", PublicationFilter);
	List.Parameters.SetParameterValue("KindFilter",        KindFilter);
	List.Parameters.SetParameterValue("AddlReportsKinds",  AddlReportsKinds);
	List.Parameters.SetParameterValue("AllPublicationsExceptDisabled", AllPublicationsExceptDisabled);
	
	InsertRight = AdditionalReportsAndDataProcessors.InsertRight();
	CommonClientServer.SetFormItemProperty(Items, "Create",              "Visible", InsertRight);
	CommonClientServer.SetFormItemProperty(Items, "CreateMenu",          "Visible", InsertRight);
	CommonClientServer.SetFormItemProperty(Items, "CreateFolder",        "Visible", InsertRight);
	CommonClientServer.SetFormItemProperty(Items, "CreateMenuGroup",    "Visible", InsertRight);
	CommonClientServer.SetFormItemProperty(Items, "LoadFromFile",     "Visible", InsertRight);
	CommonClientServer.SetFormItemProperty(Items, "ExportFromMenuFile", "Visible", InsertRight);
	CommonClientServer.SetFormItemProperty(Items, "ExportToFile",       "Visible", InsertRight);
	CommonClientServer.SetFormItemProperty(Items, "ExportToFileMenu",   "Visible", InsertRight);
	
	If Common.SubsystemExists("StandardSubsystems.SecurityProfiles") Then
		ModuleSafeModeManager = Common.CommonModule("SafeModeManager");
		UseSecurityProfiles = ModuleSafeModeManager.UseSecurityProfiles();
	Else
		UseSecurityProfiles = False;
	EndIf;
	
	UseProfiles = Not UseSecurityProfiles;
	
	CommonClientServer.SetFormItemProperty(Items, "ChangeDeletionMarkWithoutProfiles",
		"Visible", Not UseProfiles);
	CommonClientServer.SetFormItemProperty(Items, "ChangeDeletionMarkWithoutProfilesMenu",
		"Visible", Not UseProfiles);
	
	Items.ChangeDeletionMarkWithProfiles.Visible     = UseProfiles;
	Items.ChangeDeletionMarkWithProfilesMenu.Visible = UseProfiles;
	
	If Not Common.SubsystemExists("StandardSubsystems.BatchEditObjects")
		Or Not AccessRight("Update", Metadata.Catalogs.AdditionalReportsAndDataProcessors) Then
		Items.ChangeSelectedItems.Visible = False;
		Items.ChangeSelectedItemsMenu.Visible = False;
	EndIf;
	
	If Parameters.Property("AdditionalReportsAndDataProcessorsCheck") Then
		Items.Create.Visible = False;
		Items.CreateFolder.Visible = False;
	EndIf;
	
	Items.NoteServiceGroup.Visible = Common.DataSeparationEnabled();
	
EndProcedure

&AtServer
Procedure OnLoadDataFromSettingsAtServer(Settings)
	If Not ValueIsFilled(PublicationFilter) Then
		PublicationFilter = Settings.Get("PublicationFilter");
		List.Parameters.SetParameterValue("PublicationFilter", PublicationFilter);
	EndIf;
	KindFilter = Settings.Get("KindFilter");
	List.Parameters.SetParameterValue("KindFilter", KindFilter);
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure PublicationFilterOnEdit(Item)
	DCParameterValue = List.Parameters.Items.Find("PublicationFilter");
	If DCParameterValue.Value <> PublicationFilter Then
		DCParameterValue.Value = PublicationFilter;
	EndIf;
EndProcedure

&AtClient
Procedure KindFilterOnChange(Item)
	DCParameterValue = List.Parameters.Items.Find("KindFilter");
	If DCParameterValue.Value <> KindFilter Then
		DCParameterValue.Value = KindFilter;
	EndIf;
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersList

&AtClient
Procedure ListBeforeDelete(Item, Cancel)
	If UseProfiles Then
		Cancel = True;
		ChangeDeletionMarkList();
	EndIf;
EndProcedure

&AtClient
Procedure ListBeforeAddRow(Item, Cancel, Clone, Parent, Folder, Parameter)
	If Clone Then
		Cancel = True;
	EndIf;
EndProcedure

#EndRegion

#Region FormCommandHandlers

&AtClient
Procedure ExportToFile(Command)
	RowData = Items.List.CurrentData;
	If RowData = Undefined Or Not ItemSelected(RowData) Then
		Return;
	EndIf;
	
	ExportParameters = New Structure;
	ExportParameters.Insert("Ref",   RowData.Ref);
	ExportParameters.Insert("IsReport", RowData.IsReport);
	ExportParameters.Insert("FileName", RowData.FileName);
	AdditionalReportsAndDataProcessorsClient.ExportToFile(ExportParameters);
EndProcedure

&AtClient
Procedure ImportReportDataProcessorsFile(Command)
	RowData = Items.List.CurrentData;
	If RowData = Undefined Or Not ItemSelected(RowData) Then
		Return;
	EndIf;
	
	FormParameters = New Structure;
	FormParameters.Insert("Key", RowData.Ref);
	FormParameters.Insert("ShowImportFromFileDialogOnOpen", True);
	OpenForm("Catalog.AdditionalReportsAndDataProcessors.ObjectForm", FormParameters);
EndProcedure

&AtClient
Procedure ChangeSelectedItems(Command)
	ModuleBatchObjectModificationClient = CommonClient.CommonModule("BatchEditObjectsClient");
	ModuleBatchObjectModificationClient.ChangeSelectedItems(Items.List);
EndProcedure

&AtClient
Procedure PublicationAvailable(Command)
	EditPublication("Used");
EndProcedure

&AtClient
Procedure PublicationDisabled(Command)
	EditPublication("Disabled");
EndProcedure

&AtClient
Procedure PublicationDebugMode(Command)
	EditPublication("DebugMode");
EndProcedure

&AtClient
Procedure ChangeDeletionMarkWithProfiles(Command)
	ChangeDeletionMarkList();
EndProcedure

#EndRegion

#Region Private

&AtClient
Function ItemSelected(RowData)
	If TypeOf(RowData.Ref) <> Type("CatalogRef.AdditionalReportsAndDataProcessors") Then
		ShowMessageBox(, NStr("ru = 'Команда не может быть выполнена для указанного объекта.
			|Выберите дополнительный отчет или обработку.'; 
			|en = 'Cannot run the command for the specified object.
			|Please select an additional report or data processor.'; 
			|pl = 'Nie można uruchomić polecenia dla określonego obiektu.
			|Wybierz dodatkowe sprawozdanie lub przetwarzanie danych.';
			|de = 'Der Befehl kann nicht für das angegebene Objekt ausgeführt werden. 
			|Wählen Sie einen zusätzlichen Bericht oder Datenprozessor aus.';
			|ro = 'Comanda nu poate fi executată pentru obiectul indicat.
			|Selectați raportul sau procesarea suplimentară.';
			|tr = 'Komut belirtilen nesne için çalıştırılamaz. 
			| Ek rapor veya veri işlemcisi seçin.'; 
			|es_ES = 'El comando no puede lanzarse para el objeto especificado.
			|Seleccionar un informe adicional o un procesador de datos.'"));
		Return False;
	EndIf;
	If RowData.IsFolder Then
		ShowMessageBox(, NStr("ru = 'Команда не может быть выполнена для группы.
			|Выберите дополнительный отчет или обработку.'; 
			|en = 'Cannot run the command for a group.
			|Please select an additional report or data processor.'; 
			|pl = 'Nie można uruchomić polecenia dla grupy.
			|Wybierz dodatkowe sprawozdanie lub przetwarzanie danych.';
			|de = 'Der Befehl kann nicht für die Gruppe ausgeführt werden. 
			|Wählen Sie einen zusätzlichen Bericht oder Datenprozessor.';
			|ro = 'Comanda nu poate fi executată pentru grup.
			|Selectați raportul sau procesarea suplimentară.';
			|tr = 'Komut grup için çalıştırılamaz. 
			| Ek rapor veya veri işlemcisi seçin.'; 
			|es_ES = 'El comando no puede lanzarse para el grupo.
			|Seleccionar un informe adicional o un procesador de datos.'"));
		Return False;
	EndIf;
	Return True;
EndFunction

&AtClient
Procedure ImportDataProcessorsReportFileCompletion(Result, AdditionalParameters) Export
	
	If Result = "FileImported" Then
		ShowValue(,Items.List.CurrentData.Ref);
	EndIf;
	
EndProcedure	

&AtServer
Procedure SetConditionalAppearance()
	
	List.ConditionalAppearance.Items.Clear();
	//
	Item = List.ConditionalAppearance.Items.Add();
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Publication");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.AdditionalReportsAndDataProcessorsPublicationOptions.DebugMode;
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.OverdueDataColor);
	//
	Item = List.ConditionalAppearance.Items.Add();
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Publication");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.AdditionalReportsAndDataProcessorsPublicationOptions.Disabled;
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.InaccessibleCellTextColor);
	
EndProcedure

&AtClient
Procedure EditPublication(PublicationOption)
	
	ClearMessages();
	
	SelectedRows = Items.List.SelectedRows;
	RowsCount = SelectedRows.Count();
	If RowsCount = 0 Then
		ShowMessageBox(, NStr("ru = 'Не выбран ни один дополнительный отчет (обработка)'; en = 'No additional report or data processor is selected.'; pl = 'Nie można uruchomić polecenia dla grupy. Wybierz dodatkowe sprawozdanie lub przetwarzanie danych.';de = 'Es wurde kein zusätzlicher Bericht (Datenprozessor) ausgewählt';ro = 'Nu este selectat nici un raport suplimentar (procesare)';tr = 'Ek rapor (veri işlemcisi) seçilmedi'; es_ES = 'Ningún informe adicional (procesador de datos) se ha seleccionado'"));
		Return;
	EndIf;
	
	EditingPublication(PublicationOption);
	
	If RowsCount = 1 Then
		MessageText = NStr("ru = 'Изменена публикация дополнительного отчета (обработки) ""%1""'; en = 'Availability for the additional report or data processor has been changed: %1.'; pl = 'Publikacja dodatkowego sprawozdania (przetwarzania danych) ""%1"" została zmieniona';de = 'Dir Veröffentlichung eines zusätzlichen Berichts (Datenprozessor) ""%1"" wird geändert';ro = 'Publicarea raportului suplimentar (procesării) ""%1"" este modificată';tr = '""%1"" ek raporun (veri işlemcisinin) yayını değiştirildi'; es_ES = 'Envío del informe adicional (procesador de datos) ""%1"" se ha cambiado'");
		MessageText = StringFunctionsClientServer.SubstituteParametersToString(MessageText, String(SelectedRows[0]));
	Else
		MessageText = NStr("ru = 'Изменена публикация у дополнительных отчетов (обработок): %1'; en = 'Availability for the additional reports or data processors have been changed: %1.'; pl = 'Publikacja dodatkowych sprawozdań (przetwarzania danych) ""%1"" została zmieniona';de = 'Die Veröffentlichung zusätzlicher Berichte (Bearbeitungen) wurde geändert: %1';ro = 'Este modificată publicarea rapoartelor suplimentare (procesărilor): %1';tr = '""%1"" ek raporların (veri işlemcilerin) yayını değiştirildi'; es_ES = 'Envío de los informes adicionales (procesadores de datos) se ha cambiado: %1'");
		MessageText = StringFunctionsClientServer.SubstituteParametersToString(MessageText, RowsCount);
	EndIf;
	
	ShowUserNotification(NStr("ru = 'Изменена публикация'; en = 'Availability changed'; pl = 'Publikacja została zmieniona';de = 'Die Veröffentlichung wurde geändert';ro = 'Publicarea este modificată';tr = 'Yayın değiştirildi'; es_ES = 'Envío se ha cambiado'"),, MessageText);
	
EndProcedure

&AtServer
Procedure EditingPublication(PublicationOption)
	SelectedRows = Items.List.SelectedRows;
	
	BeginTransaction();
	Try
		For Each AdditionalReportOrDataProcessor In SelectedRows Do
			LockDataForEdit(AdditionalReportOrDataProcessor);
			
			Lock = New DataLock;
			LockItem = Lock.Add("Catalog.AdditionalReportsAndDataProcessors");
			LockItem.SetValue("Ref", AdditionalReportOrDataProcessor);
			Lock.Lock();
		EndDo;
		
		For Each AdditionalReportOrDataProcessor In SelectedRows Do
			Object = AdditionalReportOrDataProcessor.GetObject();
			If PublicationOption = "Used" Then
				Object.Publication = Enums.AdditionalReportsAndDataProcessorsPublicationOptions.Used;
			ElsIf PublicationOption = "DebugMode" Then
				Object.Publication = Enums.AdditionalReportsAndDataProcessorsPublicationOptions.DebugMode;
			Else
				Object.Publication = Enums.AdditionalReportsAndDataProcessorsPublicationOptions.Disabled;
			EndIf;
			
			Object.AdditionalProperties.Insert("ListCheck");
			If Not Object.CheckFilling() Then
				ErrorPresentation = "";
				MessagesArray = GetUserMessages(True);
				For Each UserMessage In MessagesArray Do
					ErrorPresentation = ErrorPresentation + UserMessage.Text + Chars.LF;
				EndDo;
				
				Raise ErrorPresentation;
			EndIf;
			
			Object.Write();
		EndDo;
		
		UnlockDataForEdit();
		CommitTransaction();
	Except
		RollbackTransaction();
		UnlockDataForEdit();
		Raise;
	EndTry;
	Items.List.Refresh();
	
EndProcedure

&AtClient
Procedure ChangeDeletionMarkList()
	TableRow = Items.List.CurrentData;
	If TableRow = Undefined Then
		Return;
	EndIf;
	
	Context = New Structure("Ref, DeletionMark");
	FillPropertyValues(Context, TableRow);
	
	If Context.DeletionMark Then
		QuestionText = NStr("ru = 'Снять с ""%1"" пометку на удаление?'; en = 'Do you want to unmark %1 for deletion?'; pl = 'Oczyścić znacznik usunięcia dla ""%1""?';de = 'Löschzeichen für ""%1"" löschen?';ro = 'Scoateți marcajul la ștergere de pe ""%1""?';tr = '""%1"" silme işareti kaldırılsın mı?'; es_ES = '¿Eliminar la marca para borrar para ""%1""?'");
	Else
		QuestionText = NStr("ru = 'Пометить ""%1"" на удаление?'; en = 'Do you want to mark %1 for deletion?'; pl = 'Zaznaczyć ""%1"" do usunięcia?';de = 'Markieren Sie ""%1"" zum Löschen?';ro = 'Marcați ""%1"" la ștergere?';tr = '""%1"" silinmek üzere işaretlensin mi?'; es_ES = '¿Marcar ""%1"" para borrar?'");
	EndIf;
	QuestionText = StringFunctionsClientServer.SubstituteParametersToString(QuestionText, TableRow.Description);
	
	Handler = New NotifyDescription("ChangeDeletionMarkListAfterConfirm", ThisObject, Context);
	ShowQueryBox(Handler, QuestionText, QuestionDialogMode.YesNo);
EndProcedure

&AtClient
Procedure ChangeDeletionMarkListAfterConfirm(Response, Context) Export
	If Response <> DialogReturnCode.Yes Then
		Return;
	EndIf;
	
	Context.Insert("Queries", Undefined);
	Context.Insert("FormID", UUID);
	LockObjectsAndGeneratePermissionsQueries(Context);
	
	Handler = New NotifyDescription("ChangeDeletionMarkListAfterConfirmQueries", ThisObject, Context);
	If CommonClient.SubsystemExists("StandardSubsystems.SecurityProfiles") Then
		ModuleSafeModeManagerClient = CommonClient.CommonModule("SafeModeManagerClient");
		ModuleSafeModeManagerClient.ApplyExternalResourceRequests(Context.Queries, ThisObject, Handler);
	Else
		ExecuteNotifyProcessing(Handler, DialogReturnCode.OK);
	EndIf;
EndProcedure

&AtServerNoContext
Procedure LockObjectsAndGeneratePermissionsQueries(Context)
	LockDataForEdit(Context.Ref, , Context.FormID);
	
	If Common.SubsystemExists("StandardSubsystems.SecurityProfiles") Then
		Object = Context.Ref.GetObject();
		
		Context.Queries = AdditionalReportsAndDataProcessorsSafeModeInternal.AdditionalDataProcessorPermissionRequests(
			Object,
			Object.Permissions.Unload(),
			,
			Not Context.DeletionMark);
	EndIf;
	
EndProcedure

&AtClient
Procedure ChangeDeletionMarkListAfterConfirmQueries(Response, Context) Export
	ModifyMark = (Response = DialogReturnCode.OK);
	UnlockAndChangeObjectsDeletionMark(Context, ModifyMark);
	Items.List.Refresh();
EndProcedure

&AtServerNoContext
Procedure UnlockAndChangeObjectsDeletionMark(Context, ModifyMark)
	If ModifyMark Then
		Object = Context.Ref.GetObject();
		Object.SetDeletionMark(Not Context.DeletionMark);
		Object.Write();
	EndIf;
	UnlockDataForEdit(Context.Ref, Context.FormID);
EndProcedure

#EndRegion
