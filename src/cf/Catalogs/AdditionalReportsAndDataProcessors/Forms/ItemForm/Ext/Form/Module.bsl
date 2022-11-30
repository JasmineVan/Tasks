///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Variables

&AtClient
Var ClientCache;

#EndRegion

#Region EventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	SetConditionalAppearance();
	
	If ValueIsFilled(Parameters.CopyingValue) Then
		Raise NStr("ru = 'Создание нового элемента копированием запрещено.'; en = 'Create by copying is prohibited.'; pl = 'Tworzenie nowego elementu przez kopiowanie jest zabronione.';de = 'Das Erstellen eines neuen Elements durch Kopieren ist verboten.';ro = 'Crearea elementului nou prin copiere este interzisă.';tr = 'Kopyalayarak yeni bir öğe oluşturmak yasaktır.'; es_ES = 'Está prohibido crear un elemento nuevo copiando.'");
	EndIf;
	
	If Object.Kind = Enums.AdditionalReportsAndDataProcessorsKinds.PrintForm
		AND Not Common.SubsystemExists("StandardSubsystems.Print") Then
		Cancel = True;
		Common.MessageToUser(NStr("ru = 'Работа с печатными формами не поддерживается.'; en = 'Print forms are not supported.'; pl = 'Praca z formularzami wydruku nie jest obsługiwana.';de = 'Die Arbeit mit Druckformularen wird nicht unterstützt.';ro = 'Lucrul cu formele de tipar nu este susținut.';tr = 'Basılı formlar ile çalışma desteklenmez.'; es_ES = 'No se admite el uso de los formularios de impresión.'"));
		Return;
	EndIf;
	
	// Checking if new data processors can be imported into the infobase.
	IsNew = Object.Ref.IsEmpty();
	InsertRight = AdditionalReportsAndDataProcessors.InsertRight();
	If Not InsertRight Then
		If IsNew Then
			Raise NStr("ru = 'Недостаточно прав доступа для добавления дополнительных отчетов или обработок.'; en = 'Insufficient rights to add additional reports and data processors.'; pl = 'Niewystarczające prawa dostępu do dodatkowych sprawozdań lub przetwarzania danych.';de = 'Unzureichende Zugriffsrechte zum Hinzufügen zusätzlicher Berichte und Datenprozessoren.';ro = 'Drepturi de acces insuficiente pentru adăugarea rapoartelor sau procesărilor suplimentare.';tr = 'Ek raporlar veya veri işlemcileri eklemek için yetersiz erişim hakları.'; es_ES = 'Derechos insuficientes de acceso para añadir informes adicionales y procesadores de datos.'");
		Else
			Items.LoadFromFile.Visible = False;
			Items.ExportToFile.Visible = False;
		EndIf;
	EndIf;
	
	// Restrict available publication options as specified in the infobase settings.
	Items.Publication.ChoiceList.Clear();
	AvaliablePublicationKinds = AdditionalReportsAndDataProcessorsCached.AvaliablePublicationKinds();
	For Each PublicationKind In AvaliablePublicationKinds Do
		Items.Publication.ChoiceList.Add(PublicationKind);
	EndDo;
	
	// Restricting detailed information display.
	ExtendedInformationDisplay = AdditionalReportsAndDataProcessors.DisplayExtendedInformation(Object.Ref);
	Items.AdditionalInfoPage.Visible = ExtendedInformationDisplay;
	
	// Restricting data processor import from/export to a file.
	If Not AdditionalReportsAndDataProcessors.CanImportDataProcessorFromFile(Object.Ref) Then
		Items.LoadFromFile.Visible = False;
	EndIf;
	If Not AdditionalReportsAndDataProcessors.CanExportDataProcessorToFile(Object.Ref) Then
		Items.ExportToFile.Visible = False;
	EndIf;
	
	KindAdditionalDataProcessor = Enums.AdditionalReportsAndDataProcessorsKinds.AdditionalDataProcessor;
	KindAdditionalReport     = Enums.AdditionalReportsAndDataProcessorsKinds.AdditionalReport;
	ReportKind                   = Enums.AdditionalReportsAndDataProcessorsKinds.Report;
	
	Parameters.Property("ShowImportFromFileDialogOnOpen", ShowImportFromFileDialogOnOpen);
	
	If IsNew Then
		Object.UseForObjectForm = True;
		Object.UseForListForm  = True;
		ShowImportFromFileDialogOnOpen = True;
	EndIf;
	
	If ShowImportFromFileDialogOnOpen AND Not Items.LoadFromFile.Visible Then
		Raise NStr("ru = 'Недостаточно прав для загрузки дополнительных отчетов и обработок'; en = 'Insufficient rights to import additional reports and data processors.'; pl = 'Niewystarczające uprawnienia do importowania dodatkowych sprawozdań lub przetwarzania danych';de = 'Unzureichende Rechte zum Importieren zusätzlicher Berichte und Datenprozessoren';ro = 'Drepturi insuficiente pentru importul rapoartelor și procesărilor suplimentare';tr = 'Ek raporlar veya veri işlemcileri içe aktarmak için yetersiz haklar.'; es_ES = 'Derechos insuficientes para importar informes adicionales y procesadores de datos'");
	EndIf;
	
	FillInCommands();
	
	PermissionsAddress = PutToTempStorage(
		FormAttributeToValue("Object").Permissions.Unload(),
		ThisObject.UUID);
	
	SetVisibilityAvailability();
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	ClientCache = New Structure;
	
	If ShowImportFromFileDialogOnOpen Then
		AttachIdleHandler("UpdateFromFile", 0.1, True);
	EndIf;
	
EndProcedure

&AtClient
Procedure ChoiceProcessing(SelectedValue, ChoiceSource)
	
	If Upper(ChoiceSource.FormName) = Upper("Catalog.AdditionalReportsAndDataProcessors.Form.PlacementInSections") Then
		
		If TypeOf(SelectedValue) <> Type("ValueList") Then
			Return;
		EndIf;
		
		Object.Sections.Clear();
		For Each ListItem In SelectedValue Do
			NewRow = Object.Sections.Add();
			NewRow.Section = ListItem.Value;
		EndDo;
		
		Modified = True;
		SetVisibilityAvailability();
		
	ElsIf Upper(ChoiceSource.FormName) = Upper("Catalog.AdditionalReportsAndDataProcessors.Form.QuickAccessToAdditionalReportsAndDataProcessors") Then
		
		If TypeOf(SelectedValue) <> Type("ValueList") Then
			Return;
		EndIf;
		
		ItemCommand = Object.Commands.FindByID(ClientCache.CommandRowID);
		If ItemCommand = Undefined Then
			Return;
		EndIf;
		
		FoundItems = QuickAccess.FindRows(New Structure("CommandID", ItemCommand.ID));
		For Each TableRow In FoundItems Do
			QuickAccess.Delete(TableRow);
		EndDo;
		
		For Each ListItem In SelectedValue Do
			TableRow = QuickAccess.Add();
			TableRow.CommandID = ItemCommand.ID;
			TableRow.User = ListItem.Value;
		EndDo;
		
		ItemCommand.QuickAccessPresentation = UsersQuickAccessPresentation(SelectedValue.Count());
		Modified = True;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If EventName = "SelectMetadataObjects" Then
		
		ImportSelectedMetadataObjects(Parameter);
		
	EndIf;
	
EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)
	
	If AdditionalReportsAndDataProcessors.CanExportDataProcessorToFile(Object.Ref) Then
		
		DataProcessorDataAddress = PutToTempStorage(
			CurrentObject.DataProcessorStorage.Get(),
			UUID);
		
	EndIf;
	
	Query = New Query;
	Query.SetParameter("Ref", CurrentObject.Ref);
	Query.Text =
	"SELECT ALLOWED
	|	RegisterData.CommandID,
	|	RegisterData.User
	|FROM
	|	InformationRegister.DataProcessorAccessUserSettings AS RegisterData
	|WHERE
	|	RegisterData.AdditionalReportOrDataProcessor = &Ref
	|	AND RegisterData.Available = TRUE
	|	AND NOT RegisterData.User.DeletionMark
	|	AND NOT RegisterData.User.Invalid";
	QuickAccess.Load(Query.Execute().Unload());
	
	// StandardSubsystems.AccessManagement
	If Common.SubsystemExists("StandardSubsystems.AccessManagement") Then
		ModuleAccessManagement = Common.CommonModule("AccessManagement");
		ModuleAccessManagement.OnReadAtServer(ThisObject, CurrentObject);
	EndIf;
	// End StandardSubsystems.AccessManagement

EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	If DataProcessorRegistration AND AdditionalReportsAndDataProcessors.CanImportDataProcessorFromFile(Object.Ref) Then
		DataProcessorBinaryData = GetFromTempStorage(DataProcessorDataAddress);
		CurrentObject.DataProcessorStorage = New ValueStorage(DataProcessorBinaryData, New Deflation(9));
	EndIf;
	
	If Object.Kind = KindAdditionalDataProcessor OR Object.Kind = KindAdditionalReport Then
		CurrentObject.AdditionalProperties.Insert("RelevantCommands", Object.Commands.Unload());
	Else
		QuickAccess.Clear();
	EndIf;
	
	CurrentObject.AdditionalProperties.Insert("QuickAccess", QuickAccess.Unload());
	
	CurrentObject.Permissions.Load(GetFromTempStorage(PermissionsAddress));
EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)

	// StandardSubsystems.AccessManagement
	If Common.SubsystemExists("StandardSubsystems.AccessManagement") Then
		ModuleAccessManagement = Common.CommonModule("AccessManagement");
		ModuleAccessManagement.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	EndIf;
	// End StandardSubsystems.AccessManagement

	If CurrentObject.AdditionalProperties.Property("ConnectionError") Then
		MessageText = CurrentObject.AdditionalProperties.ConnectionError;
		Common.MessageToUser(MessageText);
	EndIf;
	IsNew = False;
	If DataProcessorRegistration Then
		RefreshReusableValues();
		DataProcessorRegistration = False;
	EndIf;
	FillInCommands();
	SetVisibilityAvailability();
	
	If Object.Kind = Enums.AdditionalReportsAndDataProcessorsKinds.PrintForm
		AND Common.SubsystemExists("StandardSubsystems.Print") Then
		ModulePrintManager = Common.CommonModule("PrintManagement");
		ModulePrintManager.DisablePrintCommands(SelectedRelatedObjects().UnloadValues(), CommandsToDisable().UnloadValues());
	EndIf;
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure AdditionalReportOptionsBeforeAddRow(Item, Cancel, Clone, Parent, Folder)
	Cancel = True;
EndProcedure

&AtClient
Procedure AdditionalReportOptionsBeforeRowChange(Item, Cancel)
	Cancel = True;
	OpenOption();
EndProcedure

&AtClient
Procedure AdditionalReportOptionsBeforeDeleteRow(Item, Cancel)
	Cancel = True;
	Option = Items.AdditionalReportOptions.CurrentData;
	If Option = Undefined Then
		Return;
	EndIf;
	
	If NOT Option.Custom Then
		ShowMessageBox(, NStr("ru = 'Пометка на удаление предопределенного варианта отчета запрещена.'; en = 'Predefined report option cannot be marked for deletion.'; pl = 'Nie można zaznaczyć predefiniowanej opcji sprawozdania do usunięcia.';de = 'Die vordefinierte Berichtsoption kann nicht zum Löschen markiert werden.';ro = 'Este interzisă marcarea la ștergere a variantei predefinite a raportului.';tr = 'Silinmek üzere önceden tanımlanmış rapor seçeneği işaretlenemez.'; es_ES = 'No se puede marcar la opción del informe predefinido para borrar.'"));
		Return;
	EndIf;
	
	QuestionText = StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = 'Пометить ""%1"" на удаление?'; en = 'Do you want to mark %1 for deletion?'; pl = 'Zaznaczyć ""%1"" do usunięcia?';de = 'Markieren Sie ""%1"" zum Löschen?';ro = 'Marcați ""%1"" la ștergere?';tr = '""%1"" silinmek üzere işaretlensin mi?'; es_ES = '¿Marcar ""%1"" para borrar?'"), Option.Description);
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("Variant", Option);
	Handler = New NotifyDescription("AdditionalReportOptionsBeforeDeleteCompletion", ThisObject, AdditionalParameters);
	ShowQueryBox(Handler, QuestionText, QuestionDialogMode.YesNo, , DialogReturnCode.Yes);
EndProcedure

&AtClient
Procedure UseForListFormOnChange(Item)
	If NOT Object.UseForObjectForm AND NOT Object.UseForListForm Then
		Object.UseForObjectForm = True;
	EndIf;
EndProcedure

&AtClient
Procedure UseForObjectFormOnChange(Item)
	If NOT Object.UseForObjectForm AND NOT Object.UseForListForm Then
		Object.UseForListForm = True;
	EndIf;
EndProcedure

&AtClient
Procedure DecorationEnableSecurityProfilesLabelURLProcessing(Item, Ref, StandardProcessing)
	
	If Ref = "int://sp-on" Then
		
		ModuleSafeModeManagerClient = CommonClient.CommonModule("SafeModeManagerClient");
		ModuleSafeModeManagerClient.OpenSecurityProfileSetupDialog();
		StandardProcessing = False;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure CommandsPlacementClick(Item, StandardProcessing)
	StandardProcessing = False;
	If Object.Kind = KindAdditionalReport OR Object.Kind = KindAdditionalDataProcessor Then
		// Select sections
		Sections = New ValueList;
		For Each TableRow In Object.Sections Do
			Sections.Add(TableRow.Section);
		EndDo;
		
		FormParameters = New Structure;
		FormParameters.Insert("Sections",      Sections);
		FormParameters.Insert("DataProcessorKind", Object.Kind);
		
		OpenForm("Catalog.AdditionalReportsAndDataProcessors.Form.PlacementInSections", FormParameters, ThisObject);
	Else
		// Select metadata objects
		FormParameters = PrepareMetadataObjectsSelectionFormParameters();
		OpenForm("CommonForm.SelectMetadataObjects", FormParameters);
	EndIf;
EndProcedure

#EndRegion

#Region ObjectCommandsFormTableItemsEventHandlers

&AtClient
Procedure ObjectCommandsQuickAccessPresentationStartChoice(Item, ChoiceData, StandardProcessing)
	StandardProcessing = False;
	ChangeQuickAccess();
EndProcedure

&AtClient
Procedure ObjectCommandsQuickAccessPresentationClearing(Item, StandardProcessing)
	StandardProcessing = False;
EndProcedure

&AtClient
Procedure ObjectCommandsScheduledJobUseOnChange(Item)
	ChangeScheduledJob(False, True);
EndProcedure

&AtClient
Procedure ObjectCommandsScheduledJobPresentationStartChoice(Item, ChoiceData, StandardProcessing)
	ChangeScheduledJob(True, False);
EndProcedure

&AtClient
Procedure ObjectCommandsScheduledJobPresentationClearing(Item, StandardProcessing)
	StandardProcessing = False;
EndProcedure

&AtClient
Procedure ObjectCommandsSetQuickAccess(Command)
	ChangeQuickAccess();
EndProcedure

&AtClient
Procedure ObjectCommandsSetSchedule(Command)
	ChangeScheduledJob(True, False);
EndProcedure

&AtClient
Procedure ObjectCommandsBeforeAddRow(Item, Cancel, Clone, Parent, Folder)
	Cancel = True;
EndProcedure

&AtClient
Procedure ObjectCommandsBeforeDeleteRow(Item, Cancel)
	Cancel = True;
EndProcedure

#EndRegion

#Region FormCommandHandlers

&AtClient
Procedure CommandWriteAndClose(Command)
	WriteAtClient(True);
EndProcedure

&AtClient
Procedure CommandWrite(Command)
	WriteAtClient(False);
EndProcedure

&AtClient
Procedure ImportFromFile(Command)
	UpdateFromFile();
EndProcedure

&AtClient
Procedure ExportToFile(Command)
	ExportParameters = New Structure;
	ExportParameters.Insert("IsReport", Object.Kind = ReportKind Or Object.Kind = KindAdditionalReport);
	ExportParameters.Insert("FileName", Object.FileName);
	ExportParameters.Insert("DataProcessorDataAddress", DataProcessorDataAddress);
	AdditionalReportsAndDataProcessorsClient.ExportToFile(ExportParameters);
EndProcedure

&AtClient
Procedure AdditionalReportOptionsOpen(Command)
	Option = ThisObject.Items.AdditionalReportOptions.CurrentData;
	If Option = Undefined Then
		ShowMessageBox(, NStr("ru = 'Выберите вариант отчета.'; en = 'Choose a report option.'; pl = 'Wybierz opcję sprawozdania.';de = 'Wählen Sie die Berichtsoption.';ro = 'Selectați opțiunea de raport.';tr = 'Rapor seçeneğini seçin.'; es_ES = 'Seleccionar la opción de informe.'"));
		Return;
	EndIf;
	
	AdditionalReportsAndDataProcessorsClient.OpenAdditionalReportOption(Object.Ref, Option.VariantKey);
EndProcedure

&AtClient
Procedure PlaceInSections(Command)
	OptionsArray = New Array;
	For Each RowID In Items.AdditionalReportOptions.SelectedRows Do
		Option = AdditionalReportOptions.FindByID(RowID);
		If ValueIsFilled(Option.Ref) Then
			OptionsArray.Add(Option.Ref);
		EndIf;
	EndDo;
	
	// Opens a dialog for assigning multiple report options to command interface sections
	If CommonClient.SubsystemExists("StandardSubsystems.ReportsOptions") Then
		ModuleReportsOptionsClient = CommonClient.CommonModule("ReportsOptionsClient");
		ModuleReportsOptionsClient.OpenOptionArrangeInSectionsDialog(OptionsArray);
	EndIf;
EndProcedure

&AtClient
Procedure SetVisibility(Command)
	If Modified Then
		NotifyDescription = New NotifyDescription("SetUpVisibilityCompletion", ThisObject);
		QuestionText = NStr("ru = 'Для настройки видимости команд печати обработку необходимо записать. Продолжить?'; en = 'To configure the visibility of print commands, save the data processor. Continue?'; pl = 'Aby ustawić widoczność poleceń wydruku przetwarzanie należy zapisać. Kontynuować?';de = 'Um die Sichtbarkeit von Druckbefehlen anzupassen, muss die Verarbeitung aufgezeichnet werden. Fortfahren?';ro = 'Pentru setarea vizibilității comenzilor de imprimare procesarea trebuie înregistrată. Continuați?';tr = 'Yazdırma komutlarının görünürlüğünü ayarlamak için işleme yazılmalıdır. Devam etmek istiyor musunuz?'; es_ES = 'Para ajustar la visibilidad de los comandos de impresión hay que guardar el procesamiento. ¿Continuar?'");
		Buttons = New ValueList;
		Buttons.Add("Continue", NStr("ru = 'Продолжить'; en = 'Continue'; pl = 'Kontynuuj';de = 'Weiter';ro = 'Continuare';tr = 'Devam'; es_ES = 'Continuar'"));
		Buttons.Add(DialogReturnCode.Cancel);
		ShowQueryBox(NotifyDescription, QuestionText, Buttons);
	Else
		OpenPrintSubmenuSettingsForm();
	EndIf;
EndProcedure

&AtClient
Procedure ExecuteCommand(Command)
	CommandsTableRow = Items.ObjectCommands.CurrentData;
	If CommandsTableRow = Undefined Then
		Return;
	EndIf;
	If Not CommandsTableRow.StartupOption = PredefinedValue("Enum.AdditionalDataProcessorsCallMethods.OpeningForm")
		AND Not CommandsTableRow.StartupOption = PredefinedValue("Enum.AdditionalDataProcessorsCallMethods.ClientMethodCall")
		AND Not CommandsTableRow.StartupOption = PredefinedValue("Enum.AdditionalDataProcessorsCallMethods.ServerMethodCall")
		AND Not CommandsTableRow.StartupOption = PredefinedValue("Enum.AdditionalDataProcessorsCallMethods.ScenarioInSafeMode") Then
		Return;
	EndIf;
	
	Context = New Structure;
	Context.Insert("CommandToExecuteID", CommandsTableRow.ID);
	Handler = New NotifyDescription("ExecuteCommandAfterWriteConfirmed", ThisObject, Context);
	
	If Object.Ref.IsEmpty() Or Modified Then
		QuestionText = NStr("ru = 'Для выполнения команды необходимо записать данные.'; en = 'Please save the data before running the command.'; pl = 'Aby uruchomić polecenie zapisz dane.';de = 'Um den Befehl auszuführen, ist es notwendig, die Daten aufzuschreiben.';ro = 'Pentru executarea comenzii trebuie să înregistrați datele.';tr = 'Komutunu çalıştırmak için verileri yazın.'; es_ES = 'Para lanzar el comando, grabar los datos.'");
		Buttons = New ValueList;
		Buttons.Add("WriteAndContinue", NStr("ru = 'Записать и продолжить'; en = 'Save and continue'; pl = 'Zapisz i kontynuuj';de = 'Schreibe und fahre fort';ro = 'Înregistrare și continuare';tr = 'Kaydet ve devam et'; es_ES = 'Grabar y continuar'"));
		Buttons.Add(DialogReturnCode.Cancel);
		ShowQueryBox(Handler, QuestionText, Buttons);
	Else
		ExecuteNotifyProcessing(Handler, "ContinueWithoutWriting");
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SetConditionalAppearance()

	ConditionalAppearance.Items.Clear();

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ObjectCommandsScheduledJobUsage.Name);

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ObjectCommandsScheduledJobPresentation.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Commands.ScheduledJobAllowed");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;

	Item.Appearance.SetParameterValue("ReadOnly", True);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ObjectCommandsScheduledJobPresentation.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Commands.ScheduledJobUsage");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;

	Item.Appearance.SetParameterValue("TextColor", StyleColors.InaccessibleCellTextColor);
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Client

&AtClient
Procedure WriteAtClient(CloseAfterWrite)
	
	Handler = New NotifyDescription("ContinueWriteAtClient", ThisObject, CloseAfterWrite);
	If CommonClient.SubsystemExists("StandardSubsystems.SecurityProfiles") Then
		Queries = PermissionsUpdateRequests();
		ModuleSafeModeManagerClient = CommonClient.CommonModule("SafeModeManagerClient");
		ModuleSafeModeManagerClient.ApplyExternalResourceRequests(Queries, ThisObject, Handler);
	Else
		ExecuteNotifyProcessing(Handler, DialogReturnCode.OK);
	EndIf;
	
EndProcedure

&AtClient
Procedure ContinueWriteAtClient(Result, CloseAfterWrite)  Export
	
	WriteParameters = New Structure;
	WriteParameters.Insert("DataProcessorRegistration", DataProcessorRegistration);
	WriteParameters.Insert("CloseAfterWrite", CloseAfterWrite);
	
	Success = Write(WriteParameters);
	If Not Success Then
		Return;
	EndIf;
	
	If WriteParameters.DataProcessorRegistration Then
		RefreshReusableValues();
		NotificationText = NStr("ru = 'Для применения изменений в открытых окнах необходимо их закрыть и открыть заново.'; en = 'To apply the changes to open windows, close and reopen them.'; pl = 'Aby zastosować zmiany w oknach otwartych, należy je zamknąć i ponownie otworzyć.';de = 'Um Änderungen in den geöffneten Fenstern zu übernehmen, sollten Sie diese schließen und neu öffnen.';ro = 'Pentru aplicarea modificărilor în ferestrele deschise trebuie să le închideți și să le redeschideți.';tr = 'Açık pencerelerde değişiklikleri uygulamak için bunları kapatın ve yeniden açın.'; es_ES = 'Para aplicar los cambios en las ventanas abiertas es necesario cerrarlas y abrirlas de nuevo.'");
		ShowUserNotification(, , NotificationText);
	EndIf;
	WriteAtClientEnd(WriteParameters);
	
EndProcedure

&AtServer
Function PermissionsUpdateRequests()
	
	Return AdditionalReportsAndDataProcessorsSafeModeInternal.AdditionalDataProcessorPermissionRequests(
		Object, SecurityProfilePermissions());
	
EndFunction

&AtClient
Procedure WriteAtClientEnd(WriteParameters)
	If WriteParameters.CloseAfterWrite AND IsOpen() Then
		Close();
	EndIf;
EndProcedure

&AtClient
Procedure UpdateFromFile()
	Notification = New NotifyDescription("UpdateFromFileAfterConfirm", ThisObject);
	FormParameters = New Structure("Key", "BeforeAddExternalReportOrDataProcessor");
	OpenForm("CommonForm.SecurityWarning", FormParameters, , , , , Notification);
EndProcedure

&AtClient
Procedure UpdateFromFileAfterConfirm(Response, RegistrationParameters) Export
	If Response <> "Continue" Then
		UpdateFromFileCompletion(Undefined, RegistrationParameters);
		Return;
	EndIf;
	
	RegistrationParameters = New Structure;
	RegistrationParameters.Insert("Success", False);
	RegistrationParameters.Insert("DataProcessorDataAddress", DataProcessorDataAddress);
	
	Handler = New NotifyDescription("UpdateFromFileAfterFileChoice", ThisObject, RegistrationParameters);
	
	ImportParameters = FileSystemClient.FileImportParameters();
	ImportParameters.Dialog.Filter = AdditionalReportsAndDataProcessorsClientServer.SelectingAndSavingDialogFilter();
	ImportParameters.FormID = UUID;
	
	If Object.Ref.IsEmpty() Then
		ImportParameters.Dialog.FilterIndex = 0;
		ImportParameters.Dialog.Title = NStr("ru = 'Выберите файл внешнего отчета или обработки'; en = 'Select a file with external report or data processor'; pl = 'Wybierz plik zewnętrznego sprawozdania lub procesora danych';de = 'Wählen Sie eine Datei mit einem externen Bericht oder Datenprozessor aus';ro = 'Selectați un fișier de raport extern sau procesor de date';tr = 'Harici rapor veya veri işlemcisini seç'; es_ES = 'Seleccionar un archivo del informe externo o el procesador de datos.'");
	ElsIf Object.Kind = KindAdditionalReport Or Object.Kind = ReportKind Then
		ImportParameters.Dialog.FilterIndex = 1;
		ImportParameters.Dialog.Title = NStr("ru = 'Выберите файл внешнего отчета'; en = 'Select an file with external report'; pl = 'Wybierz plik zewnętrznego sprawozdania';de = 'Wählen Sie eine externe Berichtsdatei';ro = 'Selectați fișierul raportului extern';tr = 'Harici rapor dosyasını seç'; es_ES = 'Seleccionar un archivo del informe externo'");
	Else
		ImportParameters.Dialog.FilterIndex = 2;
		ImportParameters.Dialog.Title = NStr("ru = 'Выберите файл внешней обработки'; en = 'Select a file with external data processor'; pl = 'Wybierz plik zewnętrznego przetwarzania danych';de = 'Wählen Sie eine externe Datenprozessordatei aus';ro = 'Selectați fișierul procesării externe';tr = 'Harici veri işlemci dosyasını seç'; es_ES = 'Seleccionar un archivo del procesador de datos externo'");
	EndIf;
	
	FileSystemClient.ImportFile(Handler, ImportParameters, Object.FileName);
	
EndProcedure

&AtClient
Procedure UpdateFromFileAfterFileChoice(FileDetails, RegistrationParameters) Export
	If FileDetails = Undefined Then
		UpdateFromFileCompletion(Undefined, RegistrationParameters);
		Return;
	EndIf;
	
	Keys = New Structure("FileName, IsReport, DisablePublication, DisableConflicts, Conflicting");
	CommonClientServer.SupplementStructure(RegistrationParameters, Keys, False);
	
	RegistrationParameters.DisablePublication = False;
	RegistrationParameters.DisableConflicts = False;
	RegistrationParameters.Conflicting = New ValueList;
	
	SubstringsArray = StrSplit(FileDetails.Name, "\", False);
	RegistrationParameters.FileName = SubstringsArray.Get(SubstringsArray.UBound());
	FileExtention = Upper(Right(RegistrationParameters.FileName, 3));
	
	If FileExtention = "ERF" Then
		RegistrationParameters.IsReport = True;
	ElsIf FileExtention = "EPF" Then
		RegistrationParameters.IsReport = False;
	Else
		RegistrationParameters.Success = False;
		ResultHandler = New NotifyDescription("UpdateFromFileCompletion", ThisObject, RegistrationParameters);
		WarningText = NStr("ru = 'Расширение файла не соответствует расширению внешнего отчета (ERF) или обработки (EPF).'; en = 'The file extension does not match external report extension (ERF) or external data processor extension (EPF).'; pl = 'Rozszerzenie pliku nie jest zgodne ze sprawozdaniem zewnętrznym (ERF) lub procesorem przetwarzania danych (EPF).';de = 'Die Dateierweiterung stimmt nicht mit der des externen Berichts (ERF) oder Datenprozessors (EPF) überein.';ro = 'Extensia fișierului nu corespunde extensiei raportului extern (ERF) sau a procesării externe (EPF).';tr = 'Dosya uzantısı harici rapor (ERF) veya veri işlemcisi (EPF) ile uyuşmuyor.'; es_ES = 'Extensión del archivo no coincide con aquellas del informe externo (FER) o el procesador de datos (EPF). '");
		ReturnParameters = New Structure;
		ReturnParameters.Insert("Handler", ResultHandler);
		ReturnParameters.Insert("Result",  Undefined);
		SimpleDialogHandler = New NotifyDescription("ReturnResultAfterCloseSimpleDialog", ThisObject, ReturnParameters);
		ShowMessageBox(SimpleDialogHandler, WarningText);
		Return;
	EndIf;
	
	RegistrationParameters.DataProcessorDataAddress = FileDetails.Location;
	
	UpdateFromFileAndMessage(RegistrationParameters);
EndProcedure

&AtClient
Procedure ReturnResultAfterCloseSimpleDialog(HandlerParameters) Export
	If TypeOf(HandlerParameters.Handler) = Type("NotifyDescription") Then
		ExecuteNotifyProcessing(HandlerParameters.Handler, HandlerParameters.Result);
	EndIf;
EndProcedure

&AtClient
Procedure UpdateFromFileAndMessage(RegistrationParameters)

	UpdateFromFileAtServer(RegistrationParameters);
	
	If RegistrationParameters.DisableConflicts Then
		// Multiple objects are disabled, which requires dynamic list refresh.
		NotifyChanged(Type("CatalogRef.AdditionalReportsAndDataProcessors"));
	EndIf;
	
	If RegistrationParameters.Success Then
		NotificationTitle = ?(RegistrationParameters.IsReport, NStr("ru = 'Файл внешнего отчета загружен'; en = 'External report file is imported'; pl = 'Plik zewnętrznego sprawozdania został pobrany';de = 'Externe Berichtsdatei wird importiert';ro = 'Fișierul raportului extern este importat';tr = 'Harici rapor dosyası içe aktarıldı'; es_ES = 'Archivo del informe externo se ha importado'"), NStr("ru = 'Файл внешней обработки загружен'; en = 'External data processor file is imported'; pl = 'Plik z zewnętrzneym opracowaniem został pobrany';de = 'Externe Datenprozessordatei wird importiert';ro = 'Fișierul procesorului de date extern este importat';tr = 'Harici veri işlemci dosyası içe aktarıldı'; es_ES = 'Archivo del procesador de datos externo se ha importado'"));
		NotificationRef    = ?(IsNew, "", GetURL(Object.Ref));
		NotificationText     = RegistrationParameters.FileName;
		ShowUserNotification(NotificationTitle, NotificationRef, NotificationText);
		UpdateFromFileCompletion(Undefined, RegistrationParameters);
	ElsIf RegistrationParameters.ObjectNameUsed Then // Checking the reason of canceling data processor import and displaying the reason to the user.
		ShowConflicts(RegistrationParameters);
	Else
		ResultHandler = New NotifyDescription("UpdateFromFileCompletion", ThisObject, RegistrationParameters);
		QuestionParameters = StandardSubsystemsClient.QuestionToUserParameters();
		QuestionParameters.SuggestDontAskAgain = False;
		StandardSubsystemsClient.ShowQuestionToUser(ResultHandler, RegistrationParameters.ErrorText, 
			QuestionDialogMode.OK, QuestionParameters);
	EndIf;
EndProcedure

&AtClient
Procedure ShowConflicts(RegistrationParameters)
	
	If RegistrationParameters.ConflictsCount > 1 Then
		If RegistrationParameters.IsReport Then
			QuestionTitle = NStr("ru = 'Конфликты при загрузке внешнего отчета'; en = 'External report import conflict'; pl = 'Konflikty podczas importu zewnętrznego sprawozdania';de = 'Konflikte beim externen Berichtsimport';ro = 'Conflicte în timpul importului de rapoarte externe';tr = 'Harici rapor içe aktarılırken oluşan çakışmalar'; es_ES = 'Conflictos durante la importación del informe externo'");
			QuestionText = NStr("ru = 'Внутреннее имя отчета ""[Name]""
			|уже занято существующими дополнительными отчетами ([Count]): 
			|[List].
			|
			|Выберите:
			|1. ""[Continue]"" - загрузить новый отчет в режиме отладки.
			|2. ""[Disable]"" - загрузить новый отчет, отключив публикацию всех конфликтующих отчетов.
			|3. ""[Open]"" - отменить загрузку и показать список конфликтующих отчетов.'; 
			|en = 'The report or data processor name [Name] is not unique.
			|It is assigned to existing additional reports ([Count]):
			|[List].
			|
			|Select:
			|1. ""[Continue]"" to import the report in debug mode.
			|2. ""[Disable]"" to disable publication of conflicting reports and import the new report.
			|3. ""[Open]"" to cancel import and show the list of conflicting reports.'; 
			|pl = 'Nazwa wewnętrzna sprawozdania ""[Name]""
			|jest już zajęta przez istniejące sprawozdania dodatkowe ([Count]): 
			|[List].
			|
			|Wybierz:
			|1. ""[Continue]"" - pobierz nowe sprawozdanie w trybie debugowania.
			|2. ""[Disable]"" - pobierz nowe sprawozdanie z wyłączeniem publikacji wszystkich konfliktujących sprawozdań.
			|3. ""[Open]"" - anuluj pobieranie i pokaż listę konfliktujących sprawozdań.';
			|de = 'Der interne Name des Berichts ""[Name]""
			|ist bereits durch bestehende zusätzliche Berichte belegt ([Count]):
			|[List].
			|
			|Wählen Sie:
			|1. ""[Continue]"" - einen neuen Bericht im Debug-Modus herunterladen.
			|2. ""[Disable]"" - Laden Sie den neuen Bericht herunter, indem Sie die Veröffentlichung aller widersprüchlichen Berichte deaktivieren.
			|3. ""[Open]"" - bricht den Download ab und zeigt die Liste der widersprüchlichen Berichte an.';
			|ro = 'Numele intern al raportului ""[Name]""
			|deja este ocupat de rapoartele suplimentare existente ([Count]): 
			|[List].
			|
			|Selectați:
			|1. ""[Continue]"" - încarcă raport nou în regim de depanare.
			|2. ""[Disable]"" - încarcă raport nou, dezactivând publicarea tuturor rapoartelor care intră în conflict.
			|3. ""[Open]"" - revocă încărcarea și afișează lista rapoartelor în conflict.';
			|tr = '""[Name]"" raporunun 
			|dahili adı zaten mevcut ek raporlar tarafından alınmış ([Count]): 
			|[List]. 
			|
			|Seçin: 
			|1. ""[Continue]"" - hata ayıklama modunda yeni bir rapor indir. 
			|2. ""[Disable]"" - tüm çelişkili raporların yayınlanmasını engelleyen yeni bir rapor indirin. 
			|3. ""[Open]"" - indirmeyi iptal edin ve çakışan raporların bir listesini gösterin.'; 
			|es_ES = 'El nombre interno del informe ""[Name]""
			|ya está ocupado por los informes adicionales existentes ([Count]): 
			|[List].
			|
			|Seleccione:
			|1. ""[Continue]"" - cargar el informe nuevo en el modo de depuración.
			|2. ""[Disable]"" - cargar el informe nuevo desactivando la publicación de todos los informes enfrentados.
			|3. ""[Open]"" - cancelar la carga y mostrar la lista de los informes enfrentados.'");
		Else
			QuestionTitle = NStr("ru = 'Конфликты при загрузке внешней обработки'; en = 'Conflicts occurred during import of external data processor'; pl = 'Konflikty podczas importu zewnętrznego procesora przetwarzania danych';de = 'Beim Import des externen Datenprozessors sind Konflikte aufgetreten';ro = 'Au apărut conflicte în timpul procesării datelor externe';tr = 'Dış veri işlemcisi içe aktarılırken çakışmalar meydana geldi'; es_ES = 'Conflictos ocurridos durante la importación el procesador de datos externo'");
			QuestionText = NStr("ru = 'Внутреннее имя обработки ""[Name]""
			|уже занято существующими дополнительными обработками ([Count]):
			|[List].
			|
			|Выберите:
			|1. ""[Continue]"" - загрузить новую обработку в режиме отладки.
			|2. ""[Disable]"" - загрузить новую обработку, отключив публикацию всех конфликтующих обработок.
			|3. ""[Open]"" - отменить загрузку и показать список конфликтующих обработок.'; 
			|en = 'The data processor name [Name] is not unique.
			|It is assigned to existing additional data processors ([Count]):
			|[List].
			|
			|Select:
			|1. ""[Continue]"" to import the data processor in debug mode.
			|2. ""[Disable]"" to disable publication of conflicting data processor and import the new data processor.
			|3. ""[Open]"" to cancel import and show the list of conflicting data processors.'; 
			|pl = 'Nazwa wewnętrzna przetwarzania ""[Name]""
			|jest już zajęta przez istniejące dodatkowe procedury przetwarzania ([Count]): 
			|[List].
			|
			|Wybierz:
			|1. ""[Continue]"" - pobierz nowe przetwarzanie w trybie debugowania.
			|2. ""[Disable]"" - pobierz nowe przetwarzanie z wyłączeniem publikacji wszystkich konfliktujących procedur przetwarzania
			|3. ""[Open]"" - anuluj pobieranie i pokaż listę konfliktujących procedur przetwarzania.';
			|de = 'Der interne Name der Verarbeitung ""[Name]""
			|ist bereits durch die vorhandene Zusatzverarbeitung belegt([Count]:
			|[List].
			|
			| Wählen Sie:
			|1. ""[Continue]"" - lädt eine neue Behandlung im Debug-Modus.
			|2. ""[Disable]"" - laden Sie die neue Behandlung herunter, indem Sie die Veröffentlichung aller widersprüchlichen Behandlungen deaktivieren.
			|3. ""[Open]"" - bricht den Download ab und zeigt die Liste der widersprüchlichen Behandlungen an.';
			|ro = 'Numele intern al procesării ""[Name]""
			|deja este ocupat de procesările suplimentare existente ([Count]): 
			|[List].
			|
			|Selectați:
			|1. ""[Continue]"" - încarcă procesare nouă în regim de depanare.
			|2. ""[Disable]"" - încarcă procesare nouă, dezactivând publicarea tuturor procesărilor care intră în conflict.
			|3. ""[Open]"" - revocă încărcarea și afișează lista procesărilor în conflict.';
			|tr = '""[Name]"" raporunun 
			|dahili adı zaten mevcut ek veri işlemcileri tarafından alınmış ([Count]): 
			|[List]. 
			|
			|Seçin: 
			|1. ""[Continue]"" - hata ayıklama modunda yeni bir veri işlemcisini indir. 
			|2. ""[Disable]"" - tüm çelişkili veri işlemcilerin yayınlanmasını engelleyen yeni bir veri işlemcisini indirin. 
			|3. ""[Open]"" - indirmeyi iptal edin ve çakışan veri işlemcilerin listesini gösterin.'; 
			|es_ES = 'El nombre interno del procesamiento ""[Name]""
			|ya está ocupado por los procesamientos adicionales existentes ([Count]): 
			|[List].
			|
			|Seleccione:
			|1. ""[Continue]"" - cargar el procesamiento nuevo en el modo de depuración.
			|2. ""[Disable]"" - cargar el procesamiento nuevo desactivando la publicación de todos los procesamientos enfrentados.
			|3. ""[Open]"" - cancelar la carga y mostrar la lista de los procesamientos enfrentados.'");
		EndIf;
		DisableButtonPresentation = NStr("ru = 'Отключить конфликтующие'; en = 'Disable conflicting objects'; pl = 'Wyłącz konfliktujące';de = 'Konflikte werden deaktiviert';ro = 'Dezactivați conflictul';tr = 'Çakışmayı devre dışı bırak'; es_ES = 'Desactivar conflictos'");
		OpenButtonPresentation = NStr("ru = 'Отменить и показать список'; en = 'Cancel and show list'; pl = 'Anuluj i pokaż listę';de = 'Abbrechen und Liste anzeigen';ro = 'Anulați și afișați lista';tr = 'İptal et ve listeyi göster'; es_ES = 'Cancelar y mostrar la lista'");
	Else
		If RegistrationParameters.IsReport Then
			QuestionTitle = NStr("ru = 'Конфликт при загрузке внешнего отчета'; en = 'External report import conflict'; pl = 'Konflikt podczas importu sprawozdania zewnętrznego ';de = 'Konflikt beim externen Berichtsimport';ro = 'Conflicte în timpul importului de rapoarte externe';tr = 'Harici rapor içe aktarılırken oluşan çakışma'; es_ES = 'Conflicto durante la importación del informe externo'");
			QuestionText = NStr("ru = 'Внутреннее имя отчета ""[Name]""
			|уже занято существующим дополнительным отчетом [List].
			|
			|Выберите:
			|1. ""[Continue]"" - загрузить новый отчет в режиме отладки.
			|2. ""[Disable]"" - загрузить новый отчет, отключив публикацию конфликтующего отчета.
			|3. ""[Open]"" - открыть карточку конфликтующего отчета.'; 
			|en = 'The report name [Name] is not unique.
			|It is assigned to additional report [List].
			|
			|Select:
			|1. ""[Continue]"" to import the report in debug mode.
			|2. ""[Disable]"" to disable publication of conflicting reports and import the new report.
			|3. ""[Open]"" to open the card of the conflicting report.'; 
			|pl = 'Nazwa wewnętrzna sprawozdania ""[Name]""
			|jest już zajęta przez istniejące sprawozdanie dodatkowe [List].
			|
			|Wybierz:
			|1. ""[Continue]"" - pobierz nowe sprawozdanie w trybie debugowania.
			|2. ""[Disable]"" - pobierz nowe sprawozdanie z wyłączeniem publikacji konfliktującego sprawozdania.
			|3. ""[Open]"" - otwórz kartę konfliktującego sprawozdania.';
			|de = 'Der interne Berichtsname ""[Name]""
			|ist bereits durch den vorhandenen zusätzlichen Bericht[List] belegt.
			|
			|Wählen Sie:
			|1. ""[Continue]"" - einen neuen Bericht im Debug-Modus herunterladen.
			|2. ""[Disable]"" - Laden Sie den neuen Bericht herunter, indem Sie die Veröffentlichung des widersprüchlichen Berichts deaktivieren.
			|3. ""[Open]"" - öffnet das widersprüchliche Zeugnis.';
			|ro = 'Numele intern al raportului ""[Name]""
			|deja este ocupat de raportul suplimentar existent [List].
			|
			|Selectați:
			|1. ""[Continue]"" - încarcă raport nou în regim de depanare.
			|2. ""[Disable]"" - încarcă raport nou, dezactivând publicarea raportului care intră în conflict.
			|3. ""[Open]"" - deschide fișa raportului care intră în conflict.';
			|tr = '""[Name]"" raporunun 
			|dahili adı zaten mevcut ek raporlar tarafından alınmış [List]. 
			|
			|Seçin: 
			|1. ""[Continue]"" - hata ayıklama modunda yeni bir rapor indir. 
			|2. ""[Disable]"" - tüm çelişkili raporların yayınlanmasını engelleyen yeni bir rapor indirin. 
			|3. ""[Open]"" - indirmeyi iptal edin ve çakışan raporların kartını gösterin.'; 
			|es_ES = 'El nombre interno del informe ""[Name]""
			|ya está ocupado por el informe adicional existente [List].
			|
			|Seleccione:
			|1. ""[Continue]"" - cargar el informe nuevo en el modo de depuración.
			|2. ""[Disable]"" - cargar el informe nuevo desactivando la publicación del informe enfrentado.
			|3. ""[Open]"" - abrir la tarjeta del informe enfrentado.'");
			DisableButtonPresentation = NStr("ru = 'Отключить другой отчет'; en = 'Disable another report'; pl = 'Wyłącz inne sprawozdanie';de = 'Deaktivieren Sie einen anderen Bericht';ro = 'Dezactivați un alt raport';tr = 'Diğer raporu devre dışı bırak'; es_ES = 'Desactivar otro informe'");
		Else
			QuestionTitle = NStr("ru = 'Конфликт при загрузке внешней обработки'; en = 'External data processor import conflict'; pl = 'Konflikt podczas importowania zewnętrznego procesora danych';de = 'Beim Import des externen Datenprozessors ist ein Konflikt aufgetreten';ro = 'Au apărut conflicte în timpul procesării datelor externe';tr = 'Dış veri işlemcisi içe aktarılırken çakışma meydana geldi'; es_ES = 'Conflicto ocurrido durante la importación del procesador de datos externo'");
			QuestionText = NStr("ru = 'Внутреннее имя обработки ""[Name]""
			|уже занято существующей дополнительной обработкой [List].
			|
			|Выберите:
			|1. ""[Continue]"" - загрузить новую обработку в режиме отладки.
			|2. ""[Disable]"" - загрузить новую обработку, отключив публикацию конфликтующей обработки.
			|3. ""[Open]"" - открыть карточку конфликтующей обработки.'; 
			|en = 'The data processor name [Name] is not unique.
			|It is assigned to additional data processor [List].
			|
			|Select:
			|1. ""[Continue]"" to import the data processor in debug mode.
			|2. ""[Disable]"" to disable publication of conflicting data processor and import the new data processor.
			|3. ""[Open]"" to open the conflicting data processor card.'; 
			|pl = 'Nazwa wewnętrzna przetwarzania ""[Name]""
			|jest już zajęta przez istniejące dodatkowe procedury przetwarzania[List].
			|
			|Wybierz:
			|1. ""[Continue]"" - pobierz nowe przetwarzanie w trybie debugowania.
			|2. ""[Disable]"" - pobierz nowe przetwarzanie z wyłączeniem publikacji wszystkich konfliktujących procedur przetwarzania
			|3. ""[Open]"" - otwórz kartę konfliktujących procedur przetwarzania.';
			|de = 'Der interne Name der Verarbeitung ""[Name]""
			|ist bereits durch die bestehende Zusatzverarbeitung [List] belegt.
			|
			|Wählen Sie:
			|1. ""[Continue]"" - lädt eine neue Behandlung im Debug-Modus.
			|2. ""[Disable]"" - laden Sie die neue Behandlung herunter, indem Sie die Veröffentlichung der widersprüchlichen Behandlung deaktivieren.
			|3. ""[Open]"" - öffnen Sie die widersprüchliche Verarbeitungskarte.';
			|ro = 'Numele intern al procesării ""[Name]""
			|deja este ocupat de procesarea suplimentară existentă [List].
			|
			|Selectați:
			|1. ""[Continue]"" - încarcă procesare nouă în regim de depanare.
			|2. ""[Disable]"" - încarcă procesare nouă, dezactivând publicarea tuturor procesării care intră în conflict.
			|3. ""[Open]"" - deschide fișa procesării care intră în conflict.';
			|tr = '""[Name]"" veri işlemcisinin 
			|dahili adı zaten mevcut ek veri işlemcisi tarafından alınmış [List]. 
			|
			|Seçin: 
			|1. ""[Continue]"" - hata ayıklama modunda yeni bir veri işlemcisini indir. 
			|2. ""[Disable]"" - tüm çelişkili veri işlemcisinin yayınlanmasını engelleyen yeni bir veri işlemcisini indirin. 
			|3. ""[Open]"" - çakışan veri işlemcisinin kartını gösterin.'; 
			|es_ES = 'El nombre interno del procesamiento ""[Name]""
			|ya está ocupado por el procesamiento adicional existente [List].
			|
			|Seleccione:
			|1. ""[Continue]"" - cargar el procesamiento nuevo en el modo de depuración.
			|2. ""[Disable]"" - cargar el procesamiento nuevo desactivando la publicación del procesamiento enfrentado.
			|3. ""[Open]"" - abrir la tarjeta del procesamiento enfrentado.'");
			DisableButtonPresentation = NStr("ru = 'Отключить другую обработку'; en = 'Disable another data processor'; pl = 'Wyłącz inne opracowanie';de = 'Deaktivieren Sie einen anderen Datenprozessor';ro = 'Dezactivați un alt procesor de date';tr = 'Diğer veri işlemcisini devre dışı bırak'; es_ES = 'Desactivar otro procesador de datos'");
		EndIf;
		OpenButtonPresentation = NStr("ru = 'Отменить и открыть'; en = 'Cancel and open'; pl = 'Anuluj i pokaż';de = 'Abbrechen und anzeigen';ro = 'Revocare și deschidere';tr = 'İptal et ve göster'; es_ES = 'Cancelar y mostrar'");
	EndIf;
	ContinueButtonPresentation = NStr("ru = 'В режиме отладки'; en = 'Debug mode'; pl = 'w trybie debugowania';de = 'Im Debug-Modus';ro = 'În modul de reparare';tr = 'Hata ayıklama modunda'; es_ES = 'En el modo de depuración'");
	QuestionText = StrReplace(QuestionText, "[Name]",  RegistrationParameters.ObjectName);
	QuestionText = StrReplace(QuestionText, "[Count]", RegistrationParameters.ConflictsCount);
	QuestionText = StrReplace(QuestionText, "[List]",  RegistrationParameters.LockersPresentation);
	QuestionText = StrReplace(QuestionText, "[Disable]",  DisableButtonPresentation);
	QuestionText = StrReplace(QuestionText, "[Open]",     OpenButtonPresentation);
	QuestionText = StrReplace(QuestionText, "[Continue]", ContinueButtonPresentation);
	
	QuestionButtons = New ValueList;
	QuestionButtons.Add("ContinueWithoutPublishing", ContinueButtonPresentation);
	QuestionButtons.Add("DisableConflictingItems",  DisableButtonPresentation);
	QuestionButtons.Add("CancelAndOpen",        OpenButtonPresentation);
	QuestionButtons.Add(DialogReturnCode.Cancel);
	
	Handler = New NotifyDescription("UpdateFromFileConflictSolution", ThisObject, RegistrationParameters);
	ShowQueryBox(Handler, QuestionText, QuestionButtons, , "ContinueWithoutPublishing", QuestionTitle);
EndProcedure

&AtClient
Procedure UpdateFromFileConflictSolution(Response, RegistrationParameters) Export
	If Response = "ContinueWithoutPublishing" Then
		// Recall server (Debug mode option) and process the result.
		RegistrationParameters.DisablePublication = True;
		UpdateFromFileAndMessage(RegistrationParameters);
	ElsIf Response = "DisableConflictingItems" Then
		// Repeating server call (switching conflicting items to debug mode) and processing the result.
		RegistrationParameters.DisableConflicts = True;
		UpdateFromFileAndMessage(RegistrationParameters);
	ElsIf Response = "CancelAndOpen" Then
		// Canceling and showing conflicting items.
		// Showing the list if multiple conflicts are found.
		ShowList = (RegistrationParameters.ConflictsCount > 1);
		If RegistrationParameters.OldObjectName = RegistrationParameters.ObjectName AND Not IsNew Then
			// Also when the current item is already written with a conflicting name.
			// The list will contain two items: the current one and the conflicting one.
			// It allows you to decide which item is to be disabled.
			ShowList = True;
		EndIf;
		If ShowList Then // List form with a filter by conflicting items.
			FormName = "Catalog.AdditionalReportsAndDataProcessors.ListForm";
			FormTitle = NStr("ru = 'Дополнительные отчеты и обработки с внутреннем именем ""%1""'; en = 'Additional reports and data processors with name ""%1""'; pl = 'Dodatkowe sprawozdania i przetwarzania danych z wewnętrzną nazwą ""%1""';de = 'Zusätzliche Berichte und Datenprozessoren mit dem internen Namen ""%1""';ro = 'Rapoarte și procesări suplimentare cu numele intern "" %1""';tr = 'Dahili adı ""%1"" olan ek raporlar ve veri işlemcileri'; es_ES = 'Informes adicionales y procesadores de datos con el nombre interno ""%1""'");
			FormTitle = StringFunctionsClientServer.SubstituteParametersToString(FormTitle, RegistrationParameters.ObjectName);
			ParametersForm = New Structure;
			ParametersForm.Insert("Filter", New Structure);
			ParametersForm.Filter.Insert("ObjectName", RegistrationParameters.ObjectName);
			ParametersForm.Filter.Insert("IsFolder", False);
			ParametersForm.Insert("Title", FormTitle);
			ParametersForm.Insert("Representation", "List");
		Else // Item form
			FormName = "Catalog.AdditionalReportsAndDataProcessors.ObjectForm";
			ParametersForm = New Structure;
			ParametersForm.Insert("Key", RegistrationParameters.Conflicting[0].Value);
		EndIf;
		UpdateFromFileCompletion(Undefined, RegistrationParameters);
		OpenForm(FormName, ParametersForm, Undefined, True);
	Else // Canceling.
		UpdateFromFileCompletion(Undefined, RegistrationParameters);
	EndIf;
EndProcedure

&AtClient
Procedure UpdateFromFileCompletion(EmptyResult, RegistrationParameters) Export
	If RegistrationParameters = Undefined Or RegistrationParameters.Success = False Then
		If ShowImportFromFileDialogOnOpen AND IsOpen() Then
			Close();
		EndIf;
	ElsIf RegistrationParameters.Success = True Then
		If Not IsOpen() Then
			Open();
		EndIf;
		Modified = True;
		DataProcessorRegistration = True;
		DataProcessorDataAddress = RegistrationParameters.DataProcessorDataAddress;
	EndIf;
EndProcedure

&AtClient
Procedure OpenOption()
	Option = Items.AdditionalReportOptions.CurrentData;
	If Option = Undefined Then
		Return;
	EndIf;
	
	If NOT ValueIsFilled(Option.Ref) Then
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = 'Вариант отчета ""%1"" не зарегистрирован.'; en = '""%1"" report option is not registered.'; pl = 'Opcja sprawozdania ""%1"" nie jest zarejestrowana.';de = 'Die Berichtsoption ""%1"" ist nicht registriert.';ro = 'Varianta raportului ""%1"" nu este înregistrată.';tr = 'Rapor seçeneği ""%1"" kayıtlı değil.'; es_ES = 'Opción de informe ""%1"" no está registrada.'"), Option.Description);
		ShowMessageBox(, ErrorText);
	Else
		ModuleReportsOptionsClient = CommonClient.CommonModule("ReportsOptionsClient");
		ModuleReportsOptionsClient.ShowReportSettings(Option.Ref);
	EndIf;
EndProcedure

&AtClient
Procedure ChangeScheduledJob(ChoiceMode = False, CheckBoxChanged = False)
	
	ItemCommand = Items.ObjectCommands.CurrentData;
	If ItemCommand = Undefined Then
		Return;
	EndIf;
	
	If ItemCommand.StartupOption <> PredefinedValue("Enum.AdditionalDataProcessorsCallMethods.ServerMethodCall")
		AND ItemCommand.StartupOption <> PredefinedValue("Enum.AdditionalDataProcessorsCallMethods.ScenarioInSafeMode") Then
		ErrorText = NStr("ru = 'Команда с вариантом запуска ""%1""
		|не может использоваться в регламентных заданиях.'; 
		|en = 'Scheduled jobs do not support commands
		|with the ""%1"" startup option.'; 
		|pl = 'Polecenie z wariantem uruchomienia ""%1""
		|nie może być używane w zadaniach reglamentowanych.';
		|de = 'Der Befehl mit der Startoption ""%1""
		|kann nicht in Routineaufgaben verwendet werden.';
		|ro = 'Comanda cu opțiunea de lansare ""%1""
		|nu poate fi utilizată în sarcinile reglementare.';
		|tr = 'Başlangıç seçeneği komutu 
		|""%1"" planlanan işlerde kullanılamaz.'; 
		|es_ES = 'Comando de la opción de iniciación""%1""
		|no puede utilizarse en las tareas programadas.'");
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(ErrorText, String(ItemCommand.StartupOption));
		ShowMessageBox(, ErrorText);
		If CheckBoxChanged Then
			ItemCommand.ScheduledJobUsage = NOT ItemCommand.ScheduledJobUsage;
		EndIf;
		Return;
	EndIf;
	
	If CheckBoxChanged AND Not ItemCommand.ScheduledJobUsage Then
		Return;
	EndIf;
	
	If ItemCommand.ScheduledJobSchedule.Count() > 0 Then
		CommandSchedule = ItemCommand.ScheduledJobSchedule.Get(0).Value;
	Else
		CommandSchedule = Undefined;
	EndIf;
	
	If TypeOf(CommandSchedule) <> Type("JobSchedule") Then
		CommandSchedule = New JobSchedule;
	EndIf;
	
	Context = New Structure;
	Context.Insert("ItemCommand", ItemCommand);
	Context.Insert("DisableFlagOnCancelEdit", CheckBoxChanged);
	Handler = New NotifyDescription("AfterScheduleEditComplete", ThisObject, Context);
	
	EditSchedule = New ScheduledJobDialog(CommandSchedule);
	EditSchedule.Show(Handler);
	
EndProcedure

&AtClient
Procedure AfterScheduleEditComplete(Schedule, Context) Export
	ItemCommand = Context.ItemCommand;
	If Schedule = Undefined Then
		If Context.DisableFlagOnCancelEdit Then
			ItemCommand.ScheduledJobUsage = False;
		EndIf;
	Else
		ItemCommand.ScheduledJobSchedule.Clear();
		ItemCommand.ScheduledJobSchedule.Add(Schedule);
		If AdditionalReportsAndDataProcessorsClientServer.ScheduleSpecified(Schedule) Then
			Modified = True;
			ItemCommand.ScheduledJobUsage = True;
			ItemCommand.ScheduledJobPresentation = String(Schedule);
		Else
			ItemCommand.ScheduledJobPresentation = NStr("ru = 'Не заполнено'; en = 'Not filled'; pl = 'Niewypełniony';de = 'Leer';ro = 'Goală';tr = 'Boş'; es_ES = 'Vacía'");
			If ItemCommand.ScheduledJobUsage Then
				ItemCommand.ScheduledJobUsage = False;
				ShowUserNotification(
					NStr("ru = 'Запуск по расписанию отключен'; en = 'Scheduling is disabled'; pl = 'Uruchomienie wg harmonogramu jest wyłączone';de = 'Der geplante Start ist deaktiviert';ro = 'Lansarea conform orarului este dezactivată';tr = 'Planlanmış başlatma devre dışı bırakıldı'; es_ES = 'El lanzamiento por horario está desactivado'"),
					,
					NStr("ru = 'Расписание не заполнено'; en = 'Schedule is not filled'; pl = 'Nie wypełniono harmonogramu';de = 'Der Zeitplan ist nicht gefüllt';ro = 'Orarul nu este completat';tr = 'Plan doldurulmadı'; es_ES = 'Horario no está rellenado'"));
			EndIf;
		EndIf;
	EndIf;
EndProcedure

&AtClient
Procedure ChangeQuickAccess()
	ItemCommand = Items.ObjectCommands.CurrentData;
	If ItemCommand = Undefined Then
		Return;
	EndIf;
	
	FoundItems = QuickAccess.FindRows(New Structure("CommandID", ItemCommand.ID));
	UsersWithQuickAccess = New ValueList;
	For Each TableRow In FoundItems Do
		UsersWithQuickAccess.Add(TableRow.User);
	EndDo;
	
	FormParameters = New Structure;
	FormParameters.Insert("UsersWithQuickAccess", UsersWithQuickAccess);
	FormParameters.Insert("CommandPresentation",         ItemCommand.Presentation);
	
	ClientCache.Insert("CommandRowID", ItemCommand.GetID());
	OpenForm("Catalog.AdditionalReportsAndDataProcessors.Form.QuickAccessToAdditionalReportsAndDataProcessors", FormParameters, ThisObject);
	
EndProcedure

&AtClient
Procedure PermissionsOnClick(Item, EventData, StandardProcessing)
	
	StandardProcessing = False;
	
	Transition = EventData.Href;
	If Not IsBlankString(Transition) Then
		AttachIdleHandler("PermissionsOnClick_Attachable", 0.1, True);
	EndIf;
	
EndProcedure

&AtClient
Procedure PermissionsOnClick_Attachable()
	
	InternalProcessingKey = "internal:";
	
	If Transition = InternalProcessingKey + "home" Then
		
		GeneratePermissionsList();
		
	ElsIf StrStartsWith(Transition, InternalProcessingKey) Then
		
		GeneratePermissionsPresentations(Right(Transition, StrLen(Transition) - StrLen(InternalProcessingKey)));
		
	EndIf;
	
EndProcedure

&AtClient
Procedure AdditionalReportOptionsBeforeDeleteCompletion(Response, AdditionalParameters) Export
	If Response = DialogReturnCode.Yes Then
		Option = AdditionalParameters.Variant;
		DeleteAdditionalReportOption("ExternalReport." + Object.ObjectName, Option.VariantKey);
		AdditionalReportOptions.Delete(Option);
	EndIf;
EndProcedure

&AtClient
Procedure ExecuteCommandAfterWriteConfirmed(Response, Context) Export
	If Response = "WriteAndContinue" Then
		ClearMessages();
		If Not Write() Then
			Return; // Failed to write, the platform shows an error message.
		EndIf;
	ElsIf Response <> "ContinueWithoutWriting" Then
		Return;
	EndIf;
	
	If Object.Ref.IsEmpty() Or Modified Then
		Return; // Final check.
	EndIf;
	
	CommandsTableRow = Items.ObjectCommands.CurrentData;
	If CommandsTableRow = Undefined
		Or CommandsTableRow.ID <> Context.CommandToExecuteID Then
		FoundItems = Object.Commands.FindRows(New Structure("ID", Context.CommandToExecuteID));
		If FoundItems.Count() = 0 Then
			Return;
		EndIf;
		CommandsTableRow = FoundItems[0];
	EndIf;
	
	CommandToExecute = New Structure(
		"Ref, Presentation,
		|ID, StartupOption, ShowNotification, 
		|Modifier, RelatedObjects, IsReport, Kind");
	FillPropertyValues(CommandToExecute, CommandsTableRow);
	CommandToExecute.Ref = Object.Ref;
	CommandToExecute.Kind = Object.Kind;
	CommandToExecute.IsReport = (Object.Kind = KindAdditionalReport Or Object.Kind = ReportKind);
	
	If CommandsTableRow.StartupOption = PredefinedValue("Enum.AdditionalDataProcessorsCallMethods.OpeningForm") Then
		
		AdditionalReportsAndDataProcessorsClient.OpenDataProcessorForm(CommandToExecute, ThisObject, CommandToExecute.RelatedObjects);
		
	ElsIf CommandsTableRow.StartupOption = PredefinedValue("Enum.AdditionalDataProcessorsCallMethods.ClientMethodCall") Then
		
		AdditionalReportsAndDataProcessorsClient.ExecuteDataProcessorClientMethod(CommandToExecute, ThisObject, CommandToExecute.RelatedObjects);
		
	ElsIf CommandsTableRow.StartupOption = PredefinedValue("Enum.AdditionalDataProcessorsCallMethods.ServerMethodCall")
		Or CommandsTableRow.StartupOption = PredefinedValue("Enum.AdditionalDataProcessorsCallMethods.ScenarioInSafeMode") Then
		
		StateHeader = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Выполняется команда ""%1""'; en = '""%1"" command is running'; pl = 'Wykonywanie polecenia ""%1""';de = 'Der Befehl ""%1"" wird gerade ausgeführt';ro = 'Are loc executarea comenzii ""%1""';tr = '""%1"" komutu yürütülüyor'; es_ES = 'Ejecutando el comando ""%1""'"),
			CommandsTableRow.Presentation);
		ShowUserNotification(StateHeader + "...", , , PictureLib.TimeConsumingOperation48);
		
		TimeConsumingOperation = StartExecuteServerCommandInBackground(CommandToExecute, UUID);
		
		IdleParameters = TimeConsumingOperationsClient.IdleParameters(ThisObject);
		IdleParameters.MessageText = StateHeader;
		IdleParameters.UserNotification.Show = True;
		IdleParameters.OutputIdleWindow = True;
		
		CompletionNotification = New NotifyDescription("AfterCompleteExecutingServerCommandInBackground", ThisObject, CommandToExecute);
		TimeConsumingOperationsClient.WaitForCompletion(TimeConsumingOperation, CompletionNotification, IdleParameters);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure AfterCompleteExecutingServerCommandInBackground(Job, CommandToExecute) Export
	If Job.Status = "Error" Then
		Raise StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Не удалось выполнить команду по причине:
				|%1.'; 
				|en = 'Cannot run the command. Reason:
				|%1.'; 
				|pl = 'Wykonywanie polecenia nie powiodło się z powodu:
				|%1.';
				|de = 'Der Befehl konnte nicht ausgeführt werden wegen:
				|%1.';
				|ro = 'Eșec la executarea comenzii din motivul:
				|%1.';
				|tr = 'Komut 
				|%1 nedeniyle yürütülemedi.'; 
				|es_ES = 'No se ha podido realizar el comando a causa de:
				|%1.'"), Job.BriefErrorPresentation);
	Else
		Result = GetFromTempStorage(Job.ResultAddress);
		NotifyForms = CommonClientServer.StructureProperty(Result, "NotifyForms");
		If NotifyForms <> Undefined Then
			StandardSubsystemsClient.NotifyFormsAboutChange(NotifyForms);
		EndIf;
	EndIf;
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Client, Server

&AtClientAtServerNoContext
Function UsersQuickAccessPresentation(UsersCount)
	
	If UsersCount = 0 Then
		Return NStr("ru = 'Нет'; en = 'None'; pl = 'Żaden';de = 'Nein';ro = 'Nici unul';tr = 'Hiçbiri'; es_ES = 'Ninguno'");
	EndIf;
	
	QuickAccessPresentation = StringFunctionsClientServer.StringWithNumberForAnyLanguage(
		NStr("ru = ';%1 пользователь;;%1 пользователя;%1 пользователей;%1 пользователя'; en = ';%1 user;;%1 users;%1 users;%1 users'; pl = ';%1 użytkownik;;%1 użytkownika;%1 użytkowników;%1 użytkownika';de = ';%1 Benutzer;;%1 Benutzer;%1 Benutzer;%1Benutzer';ro = ';%1 utilizator;;%1 utilizatori;%1 utilizatori;%1 utilizatori';tr = ';%1 kullanıcı;; %1 kullanıcı; %1kullanıcı; %1kullanıcı'; es_ES = ';%1 usuario;;%1 de usuario;%1 usuarios;%1 de usuario'"), UsersCount);
	
	Return QuickAccessPresentation;
	
EndFunction

////////////////////////////////////////////////////////////////////////////////
// Server call, Server

&AtServerNoContext
Function StartExecuteServerCommandInBackground(CommandToExecute, UUID)
	ProcedureName = "AdditionalReportsAndDataProcessors.ExecuteCommand";
	
	ProcedureParameters = New Structure("AdditionalDataProcessorRef, CommandID, RelatedObjects");
	ProcedureParameters.AdditionalDataProcessorRef = CommandToExecute.Ref;
	ProcedureParameters.CommandID          = CommandToExecute.ID;
	ProcedureParameters.RelatedObjects             = CommandToExecute.RelatedObjects;
	
	StartSettings = TimeConsumingOperations.BackgroundExecutionParameters(UUID);
	StartSettings.BackgroundJobDescription = NStr("ru = 'Дополнительные отчеты и обработки: Выполнение серверного метода обработки'; en = 'Additional reports and data processors: executing data processor server method.'; pl = 'Dodatkowe sprawozdania i przetwarzanie danych: Uruchomiona metoda serwera procesora danych';de = 'Zusätzliche Berichte und Datenprozessoren: Laufende Servermethode des Datenprozessors';ro = 'Rapoarte și procesări suplimentare: Executarea metodei de procesare pe server';tr = 'Ek raporlar ve veri işlemcileri: Sunucu işlem yöntemini yürütme'; es_ES = 'Informes adicionales y procesadores de datos: Lanzando el método de servidor del procesador de datos'");
	
	Return TimeConsumingOperations.ExecuteInBackground(ProcedureName, ProcedureParameters, StartSettings);
EndFunction

&AtServer
Procedure UpdateFromFileAtServer(RegistrationParameters)
	CatalogObject = FormAttributeToValue("Object");
	SavedCommands = CatalogObject.Commands.Unload();
	RegistrationResult = AdditionalReportsAndDataProcessors.RegisterDataProcessor(CatalogObject, RegistrationParameters);
	PermissionsAddress = PutToTempStorage(CatalogObject.Permissions.Unload(), ThisObject.UUID);
	ValueToFormAttribute(CatalogObject, "Object");
	
	CommonClientServer.SupplementStructure(RegistrationParameters, RegistrationResult, True);
	
	If RegistrationParameters.Success Then
		FillInCommands(SavedCommands);
	ElsIf RegistrationParameters.ObjectNameUsed Then
		LockersPresentation = "";
		For Each ListItem In RegistrationParameters.Conflicting Do
			If StrLen(LockersPresentation) > 80 Then
				LockersPresentation = LockersPresentation + "... ";
				Break;
			EndIf;
			LockersPresentation = LockersPresentation
				+ ?(LockersPresentation = "", "", ", ")
				+ """" + TrimAll(ListItem.Presentation) + """";
		EndDo;
		RegistrationParameters.Insert("LockersPresentation", LockersPresentation);
		RegistrationParameters.Insert("ConflictsCount", RegistrationParameters.Conflicting.Count());
	EndIf;
	
	SetVisibilityAvailability(RegistrationParameters.Success);
EndProcedure

&AtServer
Function PrepareMetadataObjectsSelectionFormParameters()
	MetadataObjectsTable = AdditionalReportsAndDataProcessors.AttachedMetadataObjects(Object.Kind);
	If MetadataObjectsTable = Undefined Then
		Return Undefined;
	EndIf;
	
	FilterByMetadataObjects = New ValueList;
	FilterByMetadataObjects.LoadValues(MetadataObjectsTable.UnloadColumn("FullName"));
	
	SelectedMetadataObjects = New ValueList;
	For Each AssignmentItem In Object.Purpose Do
		If MetadataObjectsTable.Find(AssignmentItem.RelatedObject, "Ref") <> Undefined Then
			SelectedMetadataObjects.Add(AssignmentItem.RelatedObject.FullName);
		EndIf;
	EndDo;
	
	FormParameters = New Structure;
	FormParameters.Insert("FilterByMetadataObjects", FilterByMetadataObjects);
	FormParameters.Insert("SelectedMetadataObjects", SelectedMetadataObjects);
	FormParameters.Insert("Title", NStr("ru = 'Назначение дополнительной обработки'; en = 'Additional data processor assignment'; pl = 'Dodatkowy cel przetwarzania danych';de = 'Zusätzlicher Zweck des Datenprozessors';ro = 'Scopul procesorului de date suplimentar';tr = 'Ek veri işlemcisinin amacı'; es_ES = 'Propósito del procesador de datos adicional'"));
	
	Return FormParameters;
EndFunction

&AtServer
Procedure ImportSelectedMetadataObjects(Parameter)
	Object.Purpose.Clear();
	
	For Each ParameterItem In Parameter Do
		MetadataObject = Metadata.FindByFullName(ParameterItem.Value);
		If MetadataObject = Undefined Then
			Continue;
		EndIf;
		AssignmentRow = Object.Purpose.Add();
		AssignmentRow.RelatedObject = Common.MetadataObjectID(MetadataObject);
	EndDo;
	
	Modified = True;
	SetVisibilityAvailability();
EndProcedure

&AtServerNoContext
Procedure DeleteAdditionalReportOption(ObjectKey, OptionKey)
	SettingsStorages["ReportsVariantsStorage"].Delete(ObjectKey, OptionKey, Undefined);
EndProcedure

&AtServer
Procedure SetVisibilityAvailability(Registration = False)
	
	IsGlobalDataProcessor = (Object.Kind = KindAdditionalDataProcessor OR Object.Kind = KindAdditionalReport);
	IsReport = (Object.Kind = KindAdditionalReport OR Object.Kind = ReportKind);
	
	If Not Registration AND Not IsNew AND IsReport Then
		AdditionalReportOptionsFill();
	Else
		AdditionalReportOptions.Clear();
	EndIf;
	
	OptionsCount = AdditionalReportOptions.Count();
	CommandsCount = Object.Commands.Count();
	VisibleTabsCount = 1;
	
	If Object.Kind = KindAdditionalReport AND Object.UseOptionStorage Then
		VisibleTabsCount = VisibleTabsCount + 1;
		
		Items.OptionsPages.Visible = True;
		
		If Registration OR OptionsCount = 0 Then
			Items.OptionsPages.CurrentPage = Items.OptionsHideBeforeWrite;
			Items.OptionsPage.Title = NStr("ru = 'Варианты отчета'; en = 'Report options'; pl = 'Opcje sprawozdania';de = 'Berichtsoptionen';ro = 'Opțiuni rapoarte';tr = 'Rapor seçenekleri'; es_ES = 'Opciones de informe'");
		Else
			Items.OptionsPages.CurrentPage = Items.OptionsShow;
			Items.OptionsPage.Title = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'Варианты отчета (%1)'; en = 'Report options (%1)'; pl = 'Opcje sprawozdania (%1)';de = 'Berichtsoptionen (%1)';ro = 'Variantele raportului (%1)';tr = 'Rapor seçenekleri (%1)'; es_ES = 'Opciones de informe (%1)'"),
				Format(OptionsCount, "NG="));
		EndIf;
	Else
		Items.OptionsPages.Visible = False;
	EndIf;
	
	Items.CommandsPage.Visible = CommandsCount > 0;
	If CommandsCount = 0 Then
		Items.CommandsPage.Title = CommandsPageName();
	Else
		VisibleTabsCount = VisibleTabsCount + 1;
		Items.CommandsPage.Title = CommandsPageName() + " (" + Format(CommandsCount, "NG=") + ")";
	EndIf;
	
	Items.ExecuteCommand.Visible = False;
	If IsGlobalDataProcessor AND CommandsCount > 0 Then
		For Each CommandsTableRow In Object.Commands Do
			If CommandsTableRow.StartupOption = PredefinedValue("Enum.AdditionalDataProcessorsCallMethods.OpeningForm")
				Or CommandsTableRow.StartupOption = PredefinedValue("Enum.AdditionalDataProcessorsCallMethods.ClientMethodCall")
				Or CommandsTableRow.StartupOption = PredefinedValue("Enum.AdditionalDataProcessorsCallMethods.ServerMethodCall")
				Or CommandsTableRow.StartupOption = PredefinedValue("Enum.AdditionalDataProcessorsCallMethods.ScenarioInSafeMode") Then
				Items.ExecuteCommand.Visible = True;
				Break;
			EndIf;
		EndDo;
	EndIf;
	
	PermissionsCount = SecurityProfilePermissions().Count();
	PermissionsCompatibilityMode = Object.PermissionsCompatibilityMode;
	
	SafeMode = Object.SafeMode;
	
	If Common.SubsystemExists("StandardSubsystems.SecurityProfiles") Then
		ModuleSafeModeManager = Common.CommonModule("SafeModeManager");
		UseSecurityProfiles = ModuleSafeModeManager.UseSecurityProfiles();
	Else
		UseSecurityProfiles = False;
	EndIf;
	
	If GetFunctionalOption("SaaS") Or UseSecurityProfiles Then
		ModuleSafeModeManagerInternal = Common.CommonModule("SafeModeManagerInternal");
		If PermissionsCompatibilityMode = Enums.AdditionalReportsAndDataProcessorsPermissionCompatibilityModes.Version_2_1_3 Then
			If SafeMode AND PermissionsCount > 0 AND UseSecurityProfiles Then
				If IsNew Then
					SafeMode = "";
				Else
					SafeMode = ModuleSafeModeManagerInternal.ExternalModuleAttachmentMode(Object.Ref);
				EndIf;
			EndIf;
		Else
			If PermissionsCount = 0 Then
				SafeMode = True;
			Else
				If UseSecurityProfiles Then
					If IsNew Then
						SafeMode = "";
					Else
						SafeMode = ModuleSafeModeManagerInternal.ExternalModuleAttachmentMode(Object.Ref);
					EndIf;
				Else
					SafeMode = False;
				EndIf;
			EndIf;
		EndIf;
	EndIf;
	
	If PermissionsCount = 0 Then
		
		Items.PermissionsPage.Visible = False;
		Items.SafeModeGlobalGroup.Visible = True;
		Items.SafeModeFalseLabelDecoration.Visible = (SafeMode = False);
		Items.SafeModeTrueLabelDecoration.Visible = (SafeMode = True);
		Items.EnablingSecurityProfilesGroup.Visible = False;
		
	Else
		
		VisibleTabsCount = VisibleTabsCount + 1;
		
		Items.PermissionsPage.Visible = True;
		Items.PermissionsPage.Title = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Разрешения (%1)'; en = 'Permissions (%1)'; pl = 'Zezwolenia (%1)';de = 'Berechtigungen (%1)';ro = 'Permisiuni (%1)';tr = 'İzinler (%1)'; es_ES = 'Permisos (%1)'"),
			Format(PermissionsCount, "NG="));
		
		Items.SafeModeGlobalGroup.Visible = False;
		
		If PermissionsCompatibilityMode = Enums.AdditionalReportsAndDataProcessorsPermissionCompatibilityModes.Version_2_1_3 Then
			Items.PermissionCompatibilityModesPagesGroup.CurrentPage = Items.PermissionsPageVersion_2_1_3;
		Else
			Items.PermissionCompatibilityModesPagesGroup.CurrentPage = Items.PermissionsPageVersion_2_2_2;
		EndIf;
		
		If SafeMode = True Then
			Items.SafeModeWithPermissionsPages.CurrentPage = Items.SafeModeWithPermissionsPage;
		ElsIf SafeMode = False Then
			Items.SafeModeWithPermissionsPages.CurrentPage = Items.UnsafeModeWithPermissionsPage;
		ElsIf TypeOf(SafeMode) = Type("String") Then
			Items.SafeModeWithPermissionsPages.CurrentPage = Items.PersonalSecurityProfilePage;
			Items.DecorationPersonalSecurityProfileLabel.Title = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'Дополнительный отчет или обработка будет подключаться к программе с использованием ""персонального""
					|профиля безопасности %1, в котором будут разрешены только следующие операции:'; 
					|en = 'The report or data processor will be attached to the application with a custom security profile
					|%1, which allows the following actions:'; 
					|pl = 'Dodatkowe sprawozdanie lub przetwarzanie będzie łączyć się z programem przy użyciu ""prywatnego""
					| profilu bezpieczeństwa %1, w którym będą dozwolone tylko następujące operacje:';
					|de = 'Der zusätzliche Bericht oder die Verarbeitung wird über das ""persönliche""
					|Sicherheitsprofil %1mit dem Programm verbunden, in dem nur die folgenden Operationen erlaubt sind:';
					|ro = 'Raportul sau procesarea de date vor fi atașate la aplicație cu un profil de securitate
					|personalizat %1 cu următoarele operații permise:';
					|tr = 'Ek rapor veya veri işlemcisi, sadece aşağıdaki işlemlere izin veren ""kişisel"" 
					|güvenlik profilini kullanarak %1 bağlanacaktır:'; 
					|es_ES = 'Informe adicional o el procesador de datos se conectará a la aplicación usando el perfil
					| de seguridad ""personal""%1, que permite solo las siguientes operaciones:'"),
				SafeMode);
		Else
			Raise StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = '%1 не является корректным режимом подключения для дополнительных отчетов и обработок,
					|требующих разрешений на использование профилей безопасности.'; 
					|en = '%1 is not a valid mode to attach additional reports and data processors
					|that require permissions to use security profiles.'; 
					|pl = '%1 nie jest prawidłowym trybem połączenia dla dodatkowych sprawozdań i procedur przetwarzania,
					|wymagających zezwoleń na wykorzystywanie profili bezpieczeństwa.';
					|de = '%1 ist kein korrekter Verbindungsmodus für zusätzliche Berichte und Verarbeitungen,
					|die Berechtigungen zur Verwendung von Sicherheitsprofilen erfordern.';
					|ro = ' %1 nu este un mod de conectare corect pentru rapoarte și procesări suplimentare 
					|care necesită permisiuni pentru utilizarea profilulělor de securitate.';
					|tr = 'Güvenlik profili kullanımı için izin gerektiren ek raporlar ve veri işlemcileri için %1 doğru bir 
					|bağlantı modu değil.'; 
					|es_ES = '%1 no es un modo de conexión correcto para los informes adicionales y los procesadores de datos,
					|que requieren permisos para el uso de seguridad del perfil.'"),
				SafeMode);
		EndIf;
		
		If Common.SubsystemExists("StandardSubsystems.SecurityProfiles") Then
			ModuleSafeModeManagerInternal = Common.CommonModule("SafeModeManagerInternal");
			CanSetUpSecurityProfiles = ModuleSafeModeManagerInternal.CanSetUpSecurityProfiles();
		Else
			CanSetUpSecurityProfiles = False;
		EndIf;
		
		If SafeMode = False AND Not UseSecurityProfiles AND CanSetUpSecurityProfiles Then
			Items.EnablingSecurityProfilesGroup.Visible = True;
		Else
			Items.EnablingSecurityProfilesGroup.Visible = False;
		EndIf;
		
		GeneratePermissionsList();
		
	EndIf;
	
	Items.OptionsCommandsPermissionsPages.PagesRepresentation = FormPagesRepresentation[?(VisibleTabsCount > 1, "TabsOnTop", "None")];
	
	PurposePresentation = "";
	If IsGlobalDataProcessor Then
		For Each RowSection In Object.Sections Do
			SectionPresentation = AdditionalReportsAndDataProcessors.SectionPresentation(RowSection.Section);
			If SectionPresentation = Undefined Then
				Continue;
			EndIf;
			PurposePresentation = ?(IsBlankString(PurposePresentation), SectionPresentation,
				PurposePresentation + ", " + SectionPresentation);
		EndDo;
	Else
		For Each AssignmentRow In Object.Purpose Do
			ObjectPresentation = AdditionalReportsAndDataProcessors.MetadataObjectPresentation(AssignmentRow.RelatedObject);
			PurposePresentation = ?(IsBlankString(PurposePresentation), ObjectPresentation,
				PurposePresentation + ", " + ObjectPresentation);
		EndDo;
	EndIf;
	If PurposePresentation = "" Then
		PurposePresentation = NStr("ru = 'Не определено'; en = 'Undefined'; pl = 'Nie określono';de = 'Nicht definiert';ro = 'Nu este definit';tr = 'Tanımlanmamış'; es_ES = 'No determinado'");
	EndIf;
	
	Items.ObjectCommandsQuickAccessPresentation.Visible       = IsGlobalDataProcessor;
	Items.ObjectCommandsSetQuickAccess.Visible           = IsGlobalDataProcessor;
	Items.ObjectCommandsScheduledJobPresentation.Visible = IsGlobalDataProcessor;
	Items.ObjectCommandsScheduledJobUsage.Visible = IsGlobalDataProcessor;
	Items.ObjectCommandsSetSchedule.Visible              = IsGlobalDataProcessor;
	
	IsPrintForm = Object.Kind = Enums.AdditionalReportsAndDataProcessorsKinds.PrintForm;
	Items.FormsTypes.Visible = Not IsGlobalDataProcessor AND Not IsPrintForm;
	If Not Items.FormsTypes.Visible Then
		Object.UseForObjectForm = True;
		Object.UseForListForm = True;
	EndIf;
	Items.SetVisibility.Visible = IsPrintForm;
	Items.ObjectCommandsComment.Visible = IsPrintForm;
	
	If IsNew Then
		Title = ?(IsReport, NStr("ru = 'Дополнительный отчет (создание)'; en = 'Additional report (create)'; pl = 'Dodatkowe sprawozdanie (tworzenie)';de = 'Zusätzlicher Bericht (Erstellung)';ro = 'Raport suplimentar (creare)';tr = 'Ek rapor (oluşturma)'; es_ES = 'Informe adicional (creación)'"), NStr("ru = 'Дополнительная обработка (создание)'; en = 'Additional data processor (create)'; pl = 'Dodatkowe opracowanie (tworzenie)';de = 'Zusätzlicher Datenprozessor (Erstellung)';ro = 'Procesare suplimentară (creare)';tr = 'Ek veri işlemcisi (oluşturma)'; es_ES = 'Procesador de datos adicional (creación)'"));
	Else
		Title = Object.Description + " " + ?(IsReport, NStr("ru = '(Дополнительный отчет)'; en = '(Additional report)'; pl = '(Dodatkowe sprawozdanie)';de = '(Zusätzlicher Bericht)';ro = '(Raport suplimentar)';tr = '(Ek rapor)'; es_ES = '(Informe adicional)'"), NStr("ru = '(Дополнительная обработка)'; en = '(Additional data processor)'; pl = '(Dodatkowe opracowanie)';de = '(Zusätzlicher Datenprozessor)';ro = '(Procesor de date suplimentar)';tr = '(Ek veri işlemcisi)'; es_ES = '(Procesador de datos adicional)'"));
	EndIf;
	
	If OptionsCount > 0 Then
		
		OutputTableTitle = VisibleTabsCount <= 1 AND Object.Kind = KindAdditionalReport AND Object.UseOptionStorage;
		
		Items.AdditionalReportOptions.TitleLocation = FormItemTitleLocation[?(OutputTableTitle, "Top", "None")];
		Items.AdditionalReportOptions.Header               = NOT OutputTableTitle;
		Items.AdditionalReportOptions.HorizontalLines = NOT OutputTableTitle;
		
	EndIf;
	
	If CommandsCount > 0 Then
		
		OutputTableTitle = VisibleTabsCount <= 1 AND NOT IsGlobalDataProcessor;
		
		Items.ObjectCommands.TitleLocation = FormItemTitleLocation[?(OutputTableTitle, "Top", "None")];
		Items.ObjectCommands.Header               = NOT OutputTableTitle;
		Items.ObjectCommands.HorizontalLines = NOT OutputTableTitle;
		
	EndIf;
	
	WindowOptionsKey = AdditionalReportsAndDataProcessors.KindToString(Object.Kind);
	
EndProcedure

&AtServer
Procedure GeneratePermissionsPresentations(Val PermissionKind)
	
	PermissionsTable = SecurityProfilePermissions();
	PermissionRow = PermissionsTable.Find(PermissionKind, "PermissionKind");
	If PermissionRow <> Undefined Then
		PermissionParameters = PermissionRow.Parameters.Get();
		PermissionsPresentation_2_1_3 = AdditionalReportsAndDataProcessorsSafeModeInternal.GenerateDetailedPermissionDetails(
			PermissionKind, PermissionParameters);
	EndIf;
	
EndProcedure

&AtServer
Procedure GeneratePermissionsList()
	
	PermissionsTable = GetFromTempStorage(PermissionsAddress);
	
	If Object.PermissionsCompatibilityMode = Enums.AdditionalReportsAndDataProcessorsPermissionCompatibilityModes.Version_2_1_3 Then
		
		PermissionsPresentation_2_1_3 = AdditionalReportsAndDataProcessorsSafeModeInternal.GeneratePermissionPresentation(PermissionsTable);
		
	ElsIf Object.PermissionsCompatibilityMode = Enums.AdditionalReportsAndDataProcessorsPermissionCompatibilityModes.Version_2_2_2 Then
		
		Permissions = New Array();
		
		ModuleSafeModeManagerInternal = Common.CommonModule("SafeModeManagerInternal");
		
		For Each Row In PermissionsTable Do
			Permission = XDTOFactory.Create(XDTOFactory.Type(ModuleSafeModeManagerInternal.Package(), Row.PermissionKind));
			FillPropertyValues(Permission, Row.Parameters.Get());
			Permissions.Add(Permission);
		EndDo;
		
		Properties = ModuleSafeModeManagerInternal.PropertiesForPermissionRegister(Object.Ref);
		
		SetPrivilegedMode(True);
		PermissionsPresentation_2_2_2 = ModuleSafeModeManagerInternal.PermissionsToUseExternalResourcesPresentation(
			Properties.Type, Properties.ID, Properties.Type, Properties.ID, Permissions);
		SetPrivilegedMode(False);
		
	EndIf;
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Server

&AtServer
Procedure FillInCommands(SavedCommands = Undefined)
	
	Object.Commands.Sort("Presentation");
	
	ObjectPrintCommands = Undefined;
	If Object.Kind = Enums.AdditionalReportsAndDataProcessorsKinds.PrintForm
		AND Object.Purpose.Count() = 1
		AND Common.SubsystemExists("StandardSubsystems.Print") Then
		ModulePrintManager = Common.CommonModule("PrintManagement");
		ObjectPrintCommands = ModulePrintManager.StandardObjectPrintCommands(Object.Purpose[0].RelatedObject);
	EndIf;
	
	For Each ItemCommand In Object.Commands Do
		If Object.Kind = KindAdditionalDataProcessor OR Object.Kind = KindAdditionalReport Then
			FoundItems = QuickAccess.FindRows(New Structure("CommandID", ItemCommand.ID));
			ItemCommand.QuickAccessPresentation = UsersQuickAccessPresentation(
				FoundItems.Count());
		EndIf;
		
		ItemCommand.ScheduledJobUsage = False;
		ItemCommand.ScheduledJobAllowed = False;
		
		If Object.Kind = KindAdditionalDataProcessor
			AND (ItemCommand.StartupOption = Enums.AdditionalDataProcessorsCallMethods.ServerMethodCall
			OR ItemCommand.StartupOption = Enums.AdditionalDataProcessorsCallMethods.ScenarioInSafeMode) Then
			
			ItemCommand.ScheduledJobAllowed = True;
			
			GUIDScheduledJob = ItemCommand.GUIDScheduledJob;
			If SavedCommands <> Undefined Then
				FoundRow = SavedCommands.Find(ItemCommand.ID, "ID");
				If FoundRow <> Undefined Then
					GUIDScheduledJob = FoundRow.GUIDScheduledJob;
				EndIf;
			EndIf;
			
			If ValueIsFilled(GUIDScheduledJob) Then
				SetPrivilegedMode(True);
				ScheduledJob = ScheduledJobsServer.Job(GUIDScheduledJob);
				If ScheduledJob <> Undefined Then
					ItemCommand.GUIDScheduledJob = GUIDScheduledJob;
					ItemCommand.ScheduledJobPresentation = String(ScheduledJob.Schedule);
					ItemCommand.ScheduledJobUsage = ScheduledJob.Use;
					ItemCommand.ScheduledJobSchedule.Insert(0, ScheduledJob.Schedule);
				EndIf;
				SetPrivilegedMode(False);
			EndIf;
			If Not ValueIsFilled(ItemCommand.ScheduledJobPresentation) Then
				ItemCommand.ScheduledJobPresentation = NStr("ru = 'Не заполнено'; en = 'Not filled'; pl = 'Niewypełniony';de = 'Leer';ro = 'Goală';tr = 'Boş'; es_ES = 'Vacía'");
			EndIf;
		ElsIf Object.Kind = Enums.AdditionalReportsAndDataProcessorsKinds.PrintForm Then
			If Not IsBlankString(ItemCommand.CommandsToReplace) AND ObjectPrintCommands <> Undefined Then
				CommandsToReplaceIDs = StrSplit(ItemCommand.CommandsToReplace, ",", False);
				CommandsToReplacePresentation = "";
				CommandsToReplaceCount = 0;
				Filter = New Structure("ID, SaveFormat, SkipPreview", Undefined, Undefined, False);
				For Each IDOfCommandToReplace In CommandsToReplaceIDs Do
					Filter.ID = TrimAll(IDOfCommandToReplace);
					ListOfCommandsToReplace = ObjectPrintCommands.FindRows(Filter);
					// If it is impossible to exactly determine a command to replace, replacement is not performed.
					If ListOfCommandsToReplace.Count() = 1 Then
						CommandsToReplacePresentation = CommandsToReplacePresentation + ?(IsBlankString(CommandsToReplacePresentation), "", ", ") + """" + ListOfCommandsToReplace[0].Presentation + """";
						CommandsToReplaceCount = CommandsToReplaceCount + 1;
					EndIf;
				EndDo;
				If CommandsToReplaceCount > 0 Then
					If CommandsToReplaceCount = 1 Then
						CommentTemplate = NStr("ru = 'Заменяет стандартную команду печати %1'; en = 'Replace standard print command %1'; pl = 'Zamienia standardowe polecenie wydruku %1';de = 'Ersetzt den Standard-Druckbefehl %1';ro = 'Înlocuiește comanda standard de imprimare %1';tr = 'Standart yazdırma komutu yerinde kullanılır %1'; es_ES = 'Reemplaza el comando estándar de la impresión %1'");
					Else
						CommentTemplate = NStr("ru = 'Заменяет стандартные команды печати: %1'; en = 'Replace standard print commands: %1'; pl = 'Zamienia standardowe polecenia wydruku: %1';de = 'Ersetzt den Standard-Druckbefehl: %1';ro = 'Înlocuiește comenzile standard de imprimare: %1';tr = 'Standart yazdırma komutu yerinde kullanılır: %1'; es_ES = 'Reemplaza el comando estándar de la impresión: %1'");
					EndIf;
					ItemCommand.Comment = StringFunctionsClientServer.SubstituteParametersToString(CommentTemplate, CommandsToReplacePresentation);
				EndIf;
			EndIf;
		Else
			ItemCommand.ScheduledJobPresentation = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'Неприменимо для команд с вариантом запуска ""%1""'; en = 'Not applicable for commands with the ""%1"" startup option'; pl = 'Nie dotyczy poleceń z opcją uruchamiania ""%1""';de = 'Nicht anwendbar auf Befehle mit Startoption ""%1"".';ro = 'Nu se aplică pentru comenzile cu opțiunea de lansare "" %1""';tr = 'Başlatma seçeneği ""%1"" olan komutlar için uygulanmaz'; es_ES = 'No aplicado para comandos con la opción de lanzamiento ""%1""'"),
				String(ItemCommand.StartupOption));
		EndIf;
	EndDo;
	
EndProcedure

&AtServer
Procedure AdditionalReportOptionsFill()
	AdditionalReportOptions.Clear();
	
	Try
		ExternalObject = AdditionalReportsAndDataProcessors.ExternalDataProcessorObject(Object.Ref);
	Except
		ErrorText = NStr("ru = 'Не удалось получить список вариантов отчета из-за ошибки, возникшей при подключении этого отчета:'; en = 'Cannot get the list of report options due to report attachment error:'; pl = 'Nie można odebrać listy opcji sprawozdania z powodu błędu, który wystąpił podczas podłączenia tego sprawozdania:';de = 'Aufgrund des beim Verbinden dieses Berichts aufgetretenen Fehlers kann keine Liste mit Berichtsoptionen empfangen werden:';ro = 'Eșec la obținerea listei variantelor rapoartelor din cauza erorii apărute la conectarea acestui raport:';tr = 'Bu raporu bağlarken oluşan hata nedeniyle rapor seçeneklerinin bir listesi alınamıyor:'; es_ES = 'No se puede recibir una lista de opciones de informe debido al error que ha ocurrido al conectar este informe:'");
		MessageText = ErrorText + Chars.LF + DetailErrorDescription(ErrorInfo());
		Common.MessageToUser(MessageText);
		Return;
	EndTry;
	
	If Common.SubsystemExists("StandardSubsystems.ReportsOptions") Then
		ModuleReportsOptions = Common.CommonModule("ReportsOptions");
		
		ReportMetadata = ExternalObject.Metadata();
		DCSchemaMetadata = ReportMetadata.MainDataCompositionSchema;
		If DCSchemaMetadata <> Undefined Then
			DCSchema = ExternalObject.GetTemplate(DCSchemaMetadata.Name);
			For Each DCSettingsOption In DCSchema.SettingVariants Do
				OptionKey = DCSettingsOption.Name;
				OptionRef = ModuleReportsOptions.ReportOption(Object.Ref, OptionKey);
				If OptionRef <> Undefined Then
					Option = AdditionalReportOptions.Add();
					Option.VariantKey = OptionKey;
					Option.Description = DCSettingsOption.Presentation;
					Option.Custom = False;
					Option.PictureIndex = 5;
					Option.Ref = OptionRef;
				EndIf;
			EndDo;
		Else
			OptionKey = "";
			OptionRef = ModuleReportsOptions.ReportOption(Object.Ref, OptionKey);
			If OptionRef <> Undefined Then
				Option = AdditionalReportOptions.Add();
				Option.VariantKey = OptionKey;
				Option.Description = ReportMetadata.Presentation();
				Option.Custom = False;
				Option.PictureIndex = 5;
				Option.Ref = OptionRef;
			EndIf;
		EndIf;
	Else
		ModuleReportsOptions = Undefined;
	EndIf;
	
	If Object.UseOptionStorage Then
		Storage = SettingsStorages["ReportsVariantsStorage"];
		ObjectKey = Object.Ref;
		SettingsList = ModuleReportsOptions.ReportOptionsKeys(ObjectKey);
	Else
		Storage = ReportsVariantsStorage;
		ObjectKey = "ExternalReport." + Object.ObjectName;
		SettingsList = Storage.GetList(ObjectKey);
	EndIf;
	
	For Each ListItem In SettingsList Do
		Option = AdditionalReportOptions.Add();
		Option.VariantKey = ListItem.Value;
		Option.Description = ListItem.Presentation;
		Option.Custom = True;
		Option.PictureIndex = 3;
		If ModuleReportsOptions <> Undefined Then
			Option.Ref = ModuleReportsOptions.ReportOption(Object.Ref, Option.VariantKey);
		EndIf;
	EndDo;
EndProcedure

&AtServer
Function SecurityProfilePermissions()
	
	Return GetFromTempStorage(PermissionsAddress);
	
EndFunction

&AtServer
Function SelectedRelatedObjects()
	Result = New ValueList;
	Result.LoadValues(Object.Purpose.Unload(, "RelatedObject").UnloadColumn("RelatedObject"));
	Return Result;
EndFunction

&AtClient
Procedure SetUpVisibilityCompletion(DialogResult, AdditionalParameters) Export
	If DialogResult <> "Continue" Then
		Return;
	EndIf;
	Write();
	OpenPrintSubmenuSettingsForm();
EndProcedure

&AtClient
Procedure OpenPrintSubmenuSettingsForm()
	ModulePrintManagerInternalClient = CommonClient.CommonModule("PrintManagementInternalClient");
	ModulePrintManagerInternalClient.OpenPrintSubmenuSettingsForm(SelectedRelatedObjects());
EndProcedure

&AtServer
Function CommandsToDisable()
	Result = New ValueList;
	For Each Command In Object.Commands Do
		If Not IsBlankString(Command.CommandsToReplace) Then
			ItemsToReplaceList = StrSplit(Command.CommandsToReplace, ",", False);
			For Each CommandToReplace In ItemsToReplaceList Do
				Result.Add(CommandToReplace);
			EndDo;
		EndIf;
	EndDo;
	Return Result;
EndFunction

&AtServer
Function CommandsPageName()
	If Object.Kind = Enums.AdditionalReportsAndDataProcessorsKinds.PrintForm Then
		Return NStr("ru = 'Команды печати'; en = 'Print commands'; pl = 'Polecenia druku';de = 'Druckbefehle';ro = 'Printați comenzile';tr = 'Yazdırma komutları'; es_ES = 'Comandos de imprenta'");
	Else
		Return NStr("ru = 'Команды'; en = 'Commands'; pl = 'Polecenia';de = 'Befehle';ro = 'Comenzi';tr = 'Komutlar'; es_ES = 'Comandos'");
	EndIf;
EndFunction

#EndRegion
