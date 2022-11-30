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
	
	If Parameters.Property("FileOwner") Then
		CurrentFileOwner = Common.MetadataObjectID(TypeOf(Parameters.FileOwner));
		FileOwner        = Parameters.FileOwner;
	EndIf;
	
	FillObjectTypesInValueTree();
	
	AutomaticallySynchronizeFiles       = AutomaticSynchronizationEnabled();
	
	Items.Schedule.Title            = CurrentSchedule();
	Items.Schedule.Enabled          = AutomaticallySynchronizeFiles;
	Items.SetUpSchedule.Enabled = AutomaticallySynchronizeFiles;
	
	If Common.DataSeparationEnabled() Then
		Items.SetUpSchedule.Visible = False;
		Items.Schedule.Visible          = False;
	EndIf;
	
	If Common.IsMobileClient() Then
		
		Items.MetadataObjectsTree.Header = False;
		Items.MetadataObjectsTreeUserAccount.Visible = False;
		Items.MetadataObjectsTreeFilterRule.Visible = False;
		Items.MetadataObjectsTreeSynchronize.Visible = False;
		Items.MetadataObjectsTreeFileOwnerType.Visible = False;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure SynchronizeFilesOnChangeAutomatically(Item)
	
	SetScheduledJobParameter("Use", AutomaticallySynchronizeFiles);
	Items.Schedule.Enabled = AutomaticallySynchronizeFiles;
	Items.SetUpSchedule.Enabled = AutomaticallySynchronizeFiles;
	
EndProcedure

#EndRegion

#Region MetadataObjectTreeFormTableItemsEventHandlers

&AtClient
Procedure MetadataObjectsTreeSynchronizeOnChange(Item)
	
	CurrentData = Items.MetadataObjectsTree.CurrentData;
	If Not ValueIsFilled(CurrentData.Account) Then
		CurrentData.Synchronize = False;
		OpenSettingsForm();
		Return;
	EndIf;
	
	If CurrentData.GetItems().Count() > 1 Then
		SetSynchronizationValueToSubordinateObjects(CurrentData.Synchronize);
	Else
		WriteCurrentSettings();
	EndIf;
	
EndProcedure

&AtClient
Procedure MetadataObjectsTreeOnActivateRow(Item)
	
	CurrentData = Items.MetadataObjectsTree.CurrentData;
	
	If CurrentData <> Undefined Then
		HasSettings = ValueIsFilled(CurrentData.Account);
		Items.MetadataObjectsTreeContextMenuDelete.Enabled                        = HasSettings;
		Items.FormMetadataObjectsTreeDelete.Enabled                                  = HasSettings;
		Items.ChangeSyncSettingForm.Enabled                                   = HasSettings;
		Items.MetadataObjectsTreeContextMenuChangeSyncSetting.Enabled = HasSettings;
	EndIf;
	
EndProcedure

&AtClient
Procedure MetadataObjectsTreeChoice(Item, RowSelected, Field, StandardProcessing)
	StandardProcessing = False;
	OpenSettingsForm();
EndProcedure

&AtClient
Procedure MetadataObjectsTreeBeforeAddRow(Item, Cancel, Clone, Parent, Folder, Parameter)
	Cancel = True;
EndProcedure

&AtClient
Procedure MetadataObjectsTreeFilterRuleStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	OpenSettingsForm();
	
EndProcedure

&AtClient
Procedure MetadataObjectsTreeBeforeDelete(Item, Cancel)
	
	Cancel = True;
	
	QuestionText = NStr("ru = 'Удаление настройки приведет к прекращению синхронизации 
		|по заданным в ней правилам. Продолжить?'; 
		|en = 'If you delete the setting, you will not be able
		|to synchronize files according to the rules defined in it.'; 
		|pl = 'Usunięcie ustawienia spowoduje zatrzymanie synchronizacji
		|zgodnie z określonymi w niej regułami. Chcesz kontynuować?';
		|de = 'Das Löschen der Einstellung führt dazu, dass die Synchronisation
		|gemäß den darin angegebenen Regeln gestoppt wird. Fortfahren?';
		|ro = 'Ștergerea setării va conduce la încetarea sincronizării 
		|conform regulilor specificate în ea. Continuați?';
		|tr = 'Ayarların silinmesi, belirlenmiş kurallara göre dosyaların eşleşmesinin durdurulmasına
		| yol açar.  Devam edilsin mi?'; 
		|es_ES = 'La eliminación del ajuste llevará a la interrupción de sincronización 
		|según las reglas establecidas. ¿Continuar?'");
		
	NotifyDescription = New NotifyDescription("DeleteSettingItemCompletion", ThisObject);
	ShowQueryBox(NotifyDescription, QuestionText, QuestionDialogMode.YesNo, , DialogReturnCode.No, NStr("ru = 'Предупреждение'; en = 'Warning'; pl = 'Ostrzeżenie';de = 'Warnung';ro = 'Avertisment';tr = 'Uyarı'; es_ES = 'Aviso'"));
	
EndProcedure

#EndRegion

#Region FormCommandHandlers

&AtClient
Procedure SetUpSchedule(Command)
	ScheduleDialog = New ScheduledJobDialog(CurrentSchedule());
	NotifyDescription = New NotifyDescription("SetUpScheduleCompletion", ThisObject);
	ScheduleDialog.Show(NotifyDescription);
EndProcedure

&AtClient
Procedure ItemSynchronization(Command)
	
	TreeRow = Items.MetadataObjectsTree.CurrentData;
	If Not TreeRow.DetailedInfoAvailable Then
		MessageText = NStr("ru = 'Добавление настройки возможно только для иерархических справочников'; en = 'The setting is only available for hierarchical catalogs.'; pl = 'Dodawanie ustawienia jest możliwe tylko w przypadku katalogów hierarchicznych';de = 'Das Hinzufügen der Einstellung ist nur für hierarchische Verzeichnisse möglich';ro = 'Adăugarea setării este posibilă numai pentru clasificatoarele ierarhice';tr = 'Ayarlar sadece hiyerarşik kataloglar için eklenebilir'; es_ES = 'Es posible añadir el ajuste solo para los catálogos jerárquicos'");
		CommonClient.MessageToUser(MessageText);
		Return;
	EndIf;
	
	ChoiceFormParameters = New Structure;
	
	ChoiceFormParameters.Insert("ChoiceFoldersAndItems", FoldersAndItemsUse.FoldersAndItems);
	ChoiceFormParameters.Insert("CloseOnChoice", True);
	ChoiceFormParameters.Insert("CloseOnOwnerClose", True);
	ChoiceFormParameters.Insert("MultipleChoice", True);
	ChoiceFormParameters.Insert("ChoiceMode", True);
	
	ChoiceFormParameters.Insert("WindowOpeningMode", FormWindowOpeningMode.LockOwnerWindow);
	ChoiceFormParameters.Insert("SelectFolders", True);
	ChoiceFormParameters.Insert("UsersGroupsSelection", True);
	
	ChoiceFormParameters.Insert("AdvancedPick", True);
	ChoiceFormParameters.Insert("PickFormHeader", NStr("ru = 'Подбор элементов настроек'; en = 'Select settings items'; pl = 'Dobór elementów ustalania';de = 'Auswahl der Einstellmöglichkeiten';ro = 'Selectarea elementelor setărilor';tr = 'Ayar öğelerini seç'; es_ES = 'Selección de elementos de ajustes'"));
	
	// Excluding already existing settings from the selection list.
	ExistingSettings = TreeRow.GetItems();
	FixedSettings = New DataCompositionSettings;
	SettingItem = FixedSettings.Filter.Items.Add(Type("DataCompositionFilterItem"));
	SettingItem.LeftValue = New DataCompositionField("Ref");
	SettingItem.ComparisonType = DataCompositionComparisonType.NotInList;
	ExistingSettingsList = New Array;
	For Each Setting In ExistingSettings Do
		ExistingSettingsList.Add(Setting.FileOwner);
	EndDo;
	SettingItem.RightValue = ExistingSettingsList;
	SettingItem.Use = True;
	SettingItem.ViewMode = DataCompositionSettingsItemViewMode.Inaccessible;
	ChoiceFormParameters.Insert("FixedSettings", FixedSettings);
	
	OpenForm(ChoiceFormPath(TreeRow.FileOwner), ChoiceFormParameters, Items.MetadataObjectsTree);
	
EndProcedure

&AtClient
Procedure Synchronize(Command)
	
	CancelBackgroundJob();
	RunScheduledJob();
	SetSynchronizeCommandVisibility();
	AttachIdleHandler("CheckBackgroundJobExecution", 2, True);
	
EndProcedure

&AtClient
Procedure ChangeSyncSetting(Command)
	
	OpenSettingsForm();
	
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure SetUpScheduleCompletion(Schedule, AdditionalParameters) Export
	
	If Schedule = Undefined Then
		Return;
	EndIf;
	
	SetScheduledJobParameter("Schedule", Schedule);
	Items.Schedule.Title = Schedule;
	
EndProcedure

&AtServer
Procedure FillObjectTypesInValueTree()
	
	SettingsTree = FormAttributeToValue("MetadataObjectsTree");
	SettingsTree.Rows.Clear();
	
	FilesOwnersTable = New ValueTable;
	FilesOwnersTable.Columns.Add("FileOwner");
	FilesOwnersTable.Columns.Add("FileOwnerType");
	FilesOwnersTable.Columns.Add("FileOwnerName");
	FilesOwnersTable.Columns.Add("IsFile", New TypeDescription("Boolean"));
	FilesOwnersTable.Columns.Add("DetailedInfoAvailable", New TypeDescription("Boolean"));
	
	FilesSynchronizationExceptions = New Map;
	For each SynchronizationException In FilesOperationsInternal.OnDefineFilesSynchronizationExceptionObjects() Do
		FilesSynchronizationExceptions[SynchronizationException] = True;
	EndDo;	
	
	OwnersMetadata = New Array;
	For Each Catalog In Metadata.Catalogs Do
		
		If Catalog.Attributes.Find("FileOwner") = Undefined Then
			Continue;
		EndIf;
			
		FilesOwnersTypes = Catalog.Attributes.FileOwner.Type.Types();
		For Each OwnerType In FilesOwnersTypes Do
			
			OwnerMetadata = Metadata.FindByType(OwnerType);
			If FilesSynchronizationExceptions[OwnerMetadata] <> Undefined Then
				Continue;
			EndIf;
			OwnersMetadata.Add(OwnerMetadata.FullName());
			
			NewRow                        = FilesOwnersTable.Add();
			NewRow.FileOwner          = OwnerType;
			NewRow.FileOwnerType      = Catalog;
			NewRow.FileOwnerName      = OwnerMetadata.FullName();
			NewRow.DetailedInfoAvailable = True;
			NewRow.IsFile                = Not StrEndsWith(Catalog.Name, "AttachedFiles");
			
		EndDo;
		
	EndDo;
	
	SynchronizationSettings = InformationRegisters.FileSynchronizationSettings.CurrentSynchronizationSettings();
	SynchronizationSettings.Indexes.Add("OwnerID, IsFile");
	
	OwnersIDs = Common.MetadataObjectIDs(OwnersMetadata);
	
	AllCatalogs = Catalogs.AllRefsType();
	AllDocuments = Documents.AllRefsType();
	CatalogsNode = Undefined;
	DocumentsNode = Undefined;
	BusinessProcessesNode = Undefined;
	
	FilesOwners = New Array;
	For Each OwnerInfo In FilesOwnersTable Do
		
		If StrStartsWith(OwnerInfo.FileOwnerType.Name, "Delete")
			Or FilesOwners.Find(OwnerInfo.FileOwnerName) <> Undefined Then
			Continue;
		EndIf;
		
		FilesOwners.Add(OwnerInfo.FileOwnerName);
		
		SettingHasGlobalRules = False;
		If AllCatalogs.ContainsType(OwnerInfo.FileOwner) Then
			If CatalogsNode = Undefined Then
				CatalogsNode = SettingsTree.Rows.Add();
				CatalogsNode.ObjectDescriptionSynonym = NStr("ru = 'Справочники'; en = 'Catalogs'; pl = 'Katalogi';de = 'Stammdaten';ro = 'Cataloage';tr = 'Ana kayıtlar'; es_ES = 'Catálogos'");
			EndIf;
			NewTableRow = CatalogsNode.Rows.Add();
		ElsIf AllDocuments.ContainsType(OwnerInfo.FileOwner) Then
			If DocumentsNode = Undefined Then
				DocumentsNode = SettingsTree.Rows.Add();
				DocumentsNode.ObjectDescriptionSynonym = NStr("ru = 'Документы'; en = 'Documents'; pl = 'Dokumenty';de = 'Dokumente';ro = 'Documente';tr = 'Belgeler'; es_ES = 'Documentos'");
			EndIf;
			NewTableRow = DocumentsNode.Rows.Add();
		ElsIf BusinessProcesses.AllRefsType().ContainsType(OwnerInfo.FileOwner) Then
			If BusinessProcessesNode = Undefined Then
				BusinessProcessesNode = SettingsTree.Rows.Add();
				BusinessProcessesNode.ObjectDescriptionSynonym = NStr("ru = 'Бизнес-процессы'; en = 'Business processes'; pl = 'Procesy biznesowe';de = 'Geschäftsprozesse';ro = 'Procesele de afaceri';tr = 'İş süreçleri'; es_ES = 'Procesos de negocio'");
			EndIf;
			NewTableRow = BusinessProcessesNode.Rows.Add();
		EndIf;
		
		ObjectID = OwnersIDs[OwnerInfo.FileOwnerName];
		Filter = New Structure("OwnerID, IsFile", ObjectID, OwnerInfo.IsFile);
		DetailedSettings = SynchronizationSettings.FindRows(Filter);
		If DetailedSettings.Count() > 0 Then
			For Each Setting In DetailedSettings Do
				FilterRule                               = Setting.FilterRule.Get();
				DetalizedSetting                   = NewTableRow.Rows.Add();
				DetalizedSetting.FileOwner     = Setting.FileOwner;
				DetalizedSetting.FileOwnerType = Setting.FileOwnerType;
				
				HasFilterRules = False;
				If FilterRule <> Undefined Then
					HasFilterRules = FilterRule.Filter.Items.Count() > 0;
				EndIf;
				
				If Not IsBlankString(Setting.Description) Then
					DetalizedSetting.ObjectDescriptionSynonym = Setting.Description;
				Else
					DetalizedSetting.ObjectDescriptionSynonym = Setting.FileOwner;
				EndIf;
				
				HasFilterRules = False;
				If FilterRule <> Undefined Then
					HasFilterRules = FilterRule.Filter.Items.Count() > 0;
				EndIf;
				
				DetalizedSetting.Synchronize = Setting.Synchronize;
				DetalizedSetting.Account    = Setting.Account;
				DetalizedSetting.IsFile          = Setting.IsFile;
				DetalizedSetting.FilterRule    =
					?(HasFilterRules, NStr("ru = 'Выбранные файлы'; en = 'Selected files'; pl = 'Wybrane pliki';de = 'Ausgewählte Dateien';ro = 'Fișierele selectate';tr = 'Seçilen dosyalar'; es_ES = 'Archivos seleccionador'"), NStr("ru = 'Все файлы'; en = 'All files'; pl = 'Wszystkie pliki';de = 'Alle Dateien';ro = 'Toate fișierele';tr = 'Tüm dosyalar'; es_ES = 'Todos archivos'"));
				
			EndDo;
		EndIf;
		
		ObjectMetadata = Metadata.FindByType(OwnerInfo.FileOwner);
		NewTableRow.FileOwner = Common.MetadataObjectID(OwnerInfo.FileOwner);
		NewTableRow.FileOwnerType = Common.MetadataObjectID(OwnerInfo.FileOwnerType);
		NewTableRow.ObjectDescriptionSynonym = ObjectMetadata.Synonym;
		NewTableRow.IsFile = OwnerInfo.IsFile;
		NewTableRow.DetailedInfoAvailable = OwnerInfo.DetailedInfoAvailable;
		
		Filter = New Structure("FileOwner, IsFile", NewTableRow.FileOwner, NewTableRow.IsFile);
		FoundSettings = SynchronizationSettings.FindRows(Filter);
		
		If FoundSettings.Count() > 0 Then
			
			FilterRule = FoundSettings[0].FilterRule.Get();
			
			NewTableRow.Synchronize = FoundSettings[0].Synchronize;
			NewTableRow.Account =    FoundSettings[0].Account;
			If FilterRule <> Undefined AND FilterRule.Filter.Items.Count() > 0 Then
				NewTableRow.FilterRule = ?(IsBlankString(FoundSettings[0].Description), 
					NStr("ru = 'Выбранные файлы'; en = 'Selected files'; pl = 'Wybrane pliki';de = 'Ausgewählte Dateien';ro = 'Fișierele selectate';tr = 'Seçilen dosyalar'; es_ES = 'Archivos seleccionador'"), FoundSettings[0].Description);
			Else
				NewTableRow.FilterRule = NStr("ru = 'Все файлы'; en = 'All files'; pl = 'Wszystkie pliki';de = 'Alle Dateien';ro = 'Toate fișierele';tr = 'Tüm dosyalar'; es_ES = 'Todos archivos'");
			EndIf;
			
		Else
			NewTableRow.Synchronize = Enums.FilesCleanupOptions.DoNotClear;
			NewTableRow.FilterRule = NStr("ru = 'Все файлы'; en = 'All files'; pl = 'Wszystkie pliki';de = 'Alle Dateien';ro = 'Toate fișierele';tr = 'Tüm dosyalar'; es_ES = 'Todos archivos'");
		EndIf;
			
	EndDo;
	
	For Each TopLevelNode In SettingsTree.Rows Do
		TopLevelNode.Rows.Sort("ObjectDescriptionSynonym");
	EndDo;
	ValueToFormAttribute(SettingsTree, "MetadataObjectsTree");
	
EndProcedure

&AtClient
Procedure WriteCurrentSettings()
	
	CurrentData = Items.MetadataObjectsTree.CurrentData;
	SaveCurrentObjectSettings(
		CurrentData.FileOwner,
		CurrentData.FileOwnerType,
		CurrentData.Synchronize,
		CurrentData.Account,
		CurrentData.IsFile);
	
EndProcedure

&AtClient
Procedure SetFilterSettings(SelectedValue, AdditionalParameters) Export
	
	If SelectedValue = Undefined Then
		Return
	EndIf;
	
	RowOwner = MetadataObjectsTree.FindByID(AdditionalParameters.ID);
	
	If RowOwner.FileOwner <> SelectedValue.FileOwner Then
		OwnerElement   = RowOwner.GetItems();
		RowToRefresh = OwnerElement.Add();
		If NOT SelectedValue.NewSetting Then
			RowOwner.Synchronize = False;
		EndIf;
		WriteCurrentSettings();
	Else
		RowToRefresh = RowOwner;
	EndIf;
	
	FillPropertyValues(RowToRefresh, SelectedValue);
	
	If SelectedValue.HasFilterRules Then
		RowToRefresh.FilterRule =
			?( ValueIsFilled(SelectedValue.Description), SelectedValue.Description, NStr("ru = 'Выбранные файлы'; en = 'Selected files'; pl = 'Wybrane pliki';de = 'Ausgewählte Dateien';ro = 'Fișierele selectate';tr = 'Seçilen dosyalar'; es_ES = 'Archivos seleccionador'"));
	Else
		RowToRefresh.FilterRule = NStr("ru = 'Все файлы'; en = 'All files'; pl = 'Wszystkie pliki';de = 'Alle Dateien';ro = 'Toate fișierele';tr = 'Tüm dosyalar'; es_ES = 'Todos archivos'");
	EndIf;
	
EndProcedure

&AtServer
Procedure SetSynchronizationValueToSubordinateObjects(Val Synchronize)
	
	For Each RowID In Items.MetadataObjectsTree.SelectedRows Do
		TreeItem = MetadataObjectsTree.FindByID(RowID);
		If TreeItem.GetParent() <> Undefined Then
			SetObjectSynchronizationValue(TreeItem, Synchronize);
			Continue;
		EndIf;
		For Each TreeChildItem In TreeItem.GetItems() Do
			SetObjectSynchronizationValue(TreeChildItem, Synchronize);
		EndDo;
	EndDo;
	
EndProcedure

&AtServer
Procedure SetObjectSynchronizationValue(SelectedObject, Val Synchronize)
	
	SelectedObject.Synchronize = Synchronize;
	SaveCurrentObjectSettings(
		SelectedObject.FileOwner,
		SelectedObject.FileOwnerType,
		Synchronize,
		SelectedObject.Account,
		SelectedObject.IsFile);
	
EndProcedure

&AtServer
Procedure SaveCurrentObjectSettings(FileOwner, FileOwnerType, Synchronize, Account, IsFile)
	
	Setting                   = InformationRegisters.FileSynchronizationSettings.CreateRecordManager();
	Setting.FileOwner     = FileOwner;
	Setting.FileOwnerType = FileOwnerType;
	Setting.Synchronize  = Synchronize;
	Setting.Account     = Account;
	Setting.IsFile           = IsFile;
	Setting.Write();
	
EndProcedure

&AtClient
Procedure OpenSettingsForm()
	
	CurrentData = Items.MetadataObjectsTree.CurrentData;
	
	If Not ValueIsFilled(CurrentData.FileOwner)
		Or Not ValueIsFilled(CurrentData.FileOwnerType) Then
		Return;
	EndIf;
	
	Filter = New Structure;
	Filter.Insert("FileOwner",     CurrentData.FileOwner);
	Filter.Insert("FileOwnerType", CurrentData.FileOwnerType);
	Filter.Insert("Account",     CurrentData.Account);
	
	If ValueIsFilled(CurrentData.Account) Then
		
		ValueType = Type("InformationRegisterRecordKey.FileSynchronizationSettings");
		WriteParameters = New Array(1);
		WriteParameters[0] = Filter;
		
		RecordKey = New(ValueType, WriteParameters);
		
		WriteParameters = New Structure;
		WriteParameters.Insert("Key", RecordKey);
	Else
		WriteParameters = Filter;
		WriteParameters.Insert("IsFile", CurrentData.IsFile);
	EndIf;
	
	AdditionalParameters = New Structure();
	
	If CurrentData.DetailedInfoAvailable Then
		AdditionalParameters.Insert("ID", CurrentData.GetID());
	Else
		AdditionalParameters.Insert("ID", CurrentData.GetParent().GetID());
	EndIf;
	
	Notification = New NotifyDescription("SetFilterSettings", ThisObject, AdditionalParameters);
	OpenForm("InformationRegister.FileSynchronizationSettings.Form.RecordFormSettings", WriteParameters, ThisObject,,,, Notification);
	
EndProcedure

&AtServer
Function ChoiceFormPath(FileOwner)
	
	MetadataObject = Common.MetadataObjectByID(FileOwner);
	Return MetadataObject.FullName() + ".ChoiceForm";
	
EndFunction

&AtServer
Function ClearSettingData()
	
	ServerCallParameters = New Structure();
	
	BackgroundExecutionParameters = TimeConsumingOperations.BackgroundExecutionParameters(ThisObject.UUID);
	BackgroundExecutionParameters.BackgroundJobDescription = NStr("ru = 'Подсистема Работа с файлам: Отключение синхронизации файлов с облачным сервисом'; en = '""Stored files"" subsystem: Turn off file synchronization with the cloud service'; pl = 'Podsystem Praca z plikami: Wyłączenie synchronizacji plików z usługą w chmurze';de = 'Subsystem Arbeiten mit Dateien: Deaktivieren der Dateisynchronisierung mit dem Cloud-Service';ro = 'Subsistemul Lucrul cu fișierele: Dezactivarea sincronizării fișierelor cu cloud service';tr = 'Dosyalarla çalışma alt sistemi: Dosyaların bulut hizmeti ile eşleştirmeyi kapat'; es_ES = 'Subsistema Uso de archivos: Desactivación de sincronización de archivos con el servicio de nube'");
	
	BackgroundJob = TimeConsumingOperations.ExecuteInBackground("FilesOperationsInternal.UnlockLockedFilesBackground",
		ServerCallParameters, BackgroundExecutionParameters);
	
	Return BackgroundJob;
	
EndFunction

&AtClient
Procedure ClearSettingDataCompletion(Result, AdditionalParameters) Export
	
	If TypeOf(Result) <> Type("Structure") OR NOT Result.Property("Status") OR Result.Status <> "Completed" Then
		Return;
	EndIf;
	
	ClearSettingDataAtServer(AdditionalParameters.CurrentRow);
	
EndProcedure

&AtClient
Procedure DeleteSettingItemCompletion(Result, AdditionalParameters) Export
	
	If Result = DialogReturnCode.Yes Then
		
		SettingToDelete = MetadataObjectsTree.FindByID(Items.MetadataObjectsTree.CurrentRow);
		SettingToDelete.Synchronize = False;
		SetSynchronizationValueToSubordinateObjects(False);
		WriteCurrentSettings();
		
		CallAdditionalParameters = New Structure();
		CallAdditionalParameters.Insert("CurrentRow", Items.MetadataObjectsTree.CurrentRow);
		
		BackgroundJob = ClearSettingData();
		WaitSettings                                = TimeConsumingOperationsClient.IdleParameters(ThisObject);
		WaitSettings.OutputIdleWindow           = True;
		Handler = New NotifyDescription("ClearSettingDataCompletion", ThisObject, CallAdditionalParameters);
		TimeConsumingOperationsClient.WaitForCompletion(BackgroundJob, Handler, WaitSettings);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure CreateFileSynchronization(Command)
	
	TreeRow = Items.MetadataObjectsTree.CurrentData;
	If TreeRow = Undefined Or TreeRow.GetParent() = Undefined Then
		Return;
	EndIf;
	
	If TreeRow.DetailedInfoAvailable Then
		FileOwner = TreeRow.FileOwner;
		ID = TreeRow.GetID();
	Else
		FileOwner = TreeRow.GetParent().FileOwner;
		ID = TreeRow.GetParent().GetID();
	EndIf;
	
	FormParameters = New Structure;
	FormParameters.Insert("FileOwner",     FileOwner);
	FormParameters.Insert("FileOwnerType", TreeRow.FileOwnerType);
	FormParameters.Insert("IsFile",           TreeRow.IsFile);
	FormParameters.Insert("NewSetting",    True);
	FormParameters.Insert("ID",     ID);
	
	Notification = New NotifyDescription("SetFilterSettings", ThisObject, FormParameters);
	OpenForm("InformationRegister.FileSynchronizationSettings.Form.RecordFormSettings", FormParameters, ThisObject,,,, Notification);
	
EndProcedure

&AtClient
Procedure CancelBackgroundJob()
	CancelJobExecution(BackgroundJobID);
	DetachIdleHandler("CheckBackgroundJobExecution");
	CurrentBackgroundJob = "";
	BackgroundJobID = "";
EndProcedure

&AtServerNoContext
Procedure CancelJobExecution(BackgroundJobID)
	If ValueIsFilled(BackgroundJobID) Then
		TimeConsumingOperations.CancelJobExecution(BackgroundJobID);
	EndIf;
EndProcedure

&AtClient
Procedure CheckBackgroundJobExecution()
	If ValueIsFilled(BackgroundJobID) AND Not JobCompleted(BackgroundJobID) Then
		AttachIdleHandler("CheckBackgroundJobExecution", 5, True);
	Else
		BackgroundJobID = "";
		CurrentBackgroundJob = "";
		SetSynchronizeCommandVisibility();
	EndIf;
EndProcedure

&AtServerNoContext
Function JobCompleted(BackgroundJobID)
	Return TimeConsumingOperations.JobCompleted(BackgroundJobID);
EndFunction

&AtServer
Procedure RunScheduledJob()
	
	ScheduledJobMetadata = Metadata.ScheduledJobs.FileSynchronization;
	
	Filter = New Structure;
	MethodName = ScheduledJobMetadata.MethodName;
	Filter.Insert("MethodName", MethodName);
	Filter.Insert("State", BackgroundJobState.Active);
	SynchronizationBackgroundJobs = BackgroundJobs.GetBackgroundJobs(Filter);
	If SynchronizationBackgroundJobs.Count() > 0 Then
		BackgroundJobID = SynchronizationBackgroundJobs[0].UUID;
	Else
		JobParameters = TimeConsumingOperations.BackgroundExecutionParameters(UUID);
		JobParameters.BackgroundJobDescription = StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = 'Запуск вручную: %1'; en = 'Manual start: %1'; pl = 'Uruchomienie ręczne: %1';de = 'Manuell starten: %1';ro = 'Lansare manuală: %1';tr = 'Manuel olarak başlat: %1'; es_ES = 'Iniciar manualmente: %1'"), ScheduledJobMetadata.Synonym);
		JobResult = TimeConsumingOperations.ExecuteInBackground(ScheduledJobMetadata.MethodName, New Structure, JobParameters);
		If ValueIsFilled(BackgroundJobID) Then
			BackgroundJobID = JobResult.JobID;
		EndIf;
	EndIf;
	
	CurrentBackgroundJob = "Synchronization";
	
EndProcedure

&AtClient
Procedure SetSynchronizeCommandVisibility()
	
	SubordinatePages = Items.FileSynchronization.ChildItems;
	If IsBlankString(CurrentBackgroundJob) Then
		Items.FileSynchronization.CurrentPage = SubordinatePages.Synchronization;
	Else
		Items.FileSynchronization.CurrentPage = SubordinatePages.BackgroundJobStatus;
	EndIf;
	
EndProcedure

&AtServer
Procedure SetScheduledJobParameter(ParameterName, ParameterValue)
	
	FilesOperationsInternal.SetFilesSynchronizationScheduledJobParameter(ParameterName, ParameterValue);
	
EndProcedure

&AtServer
Function GetScheduledJobParameter(ParameterName, DefaultValue)
	
	JobParameters = New Structure;
	JobParameters.Insert("Metadata", Metadata.ScheduledJobs.FileSynchronization);
	If Not Common.DataSeparationEnabled() Then
		JobParameters.Insert("MethodName", Metadata.ScheduledJobs.FileSynchronization.MethodName);
	EndIf;
	
	SetPrivilegedMode(True);
	
	JobsList = ScheduledJobsServer.FindJobs(JobParameters);
	For Each Job In JobsList Do
		Return Job[ParameterName];
	EndDo;
	
	Return DefaultValue;
	
EndFunction

&AtServer
Function CurrentSchedule()
	Return GetScheduledJobParameter("Schedule", New JobSchedule);
EndFunction

&AtServer
Function AutomaticSynchronizationEnabled()
	Return GetScheduledJobParameter("Use", False);
EndFunction

&AtServer
Procedure SetConditionalAppearance()
	
	ConditionalAppearance.Items.Clear();
	
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField("MetadataObjectsTreeObjectSynonym");

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue  = New DataCompositionField("MetadataObjectsTree.Synchronize");
	ItemFilter.ComparisonType   = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;

	Item.Appearance.SetParameterValue("Font", New Font(WindowsFonts.DefaultGUIFont, , , True, False, False, False));
	
	//
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField("MetadataObjectsTreeFilterRule");

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("MetadataObjectsTree.Synchronize");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;

	Item.Appearance.SetParameterValue("Visible", False);
	
	//
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField("MetadataObjectsTreeUserAccount");

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("MetadataObjectsTree.Synchronize");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("MetadataObjectsTree.Account");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;

	Item.Appearance.SetParameterValue("MarkIncomplete", True);
	
EndProcedure

&AtServer
Procedure ClearSettingDataAtServer(Val CurrentRow)
	
	SettingToDelete = MetadataObjectsTree.FindByID(CurrentRow);
	
	If ValueIsFilled(SettingToDelete.Account) Then
		RecordManager                   = InformationRegisters.FileSynchronizationSettings.CreateRecordManager();
		RecordManager.FileOwner     = SettingToDelete.FileOwner;
		RecordManager.FileOwnerType = SettingToDelete.FileOwnerType;
		RecordManager.Account     = SettingToDelete.Account;
		RecordManager.IsFile           = SettingToDelete.IsFile;
		RecordManager.Read();
		RecordManager.Delete();
		
		SettingsItemParent = SettingToDelete.GetParent();
		If SettingsItemParent <> Undefined Then
			// You do not need to remove the parent setting from the tree; you only have to clear the custom fields.
			SettingToDelete.CloudServiceSubfolder = "";
			SettingToDelete.FilterRule            = "";
			SettingToDelete.Synchronize         = False;
			SettingToDelete.Account            = Undefined;
			If Not SettingToDelete.DetailedInfoAvailable Then
				SettingsItemParent.GetItems().Delete(SettingToDelete);
			EndIf;
		Else
			MetadataObjectsTree.GetItems().Delete(SettingToDelete);
		EndIf;
	EndIf;

EndProcedure

#EndRegion