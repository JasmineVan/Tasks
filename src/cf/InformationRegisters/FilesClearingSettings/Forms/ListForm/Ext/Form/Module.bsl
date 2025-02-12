﻿///////////////////////////////////////////////////////////////////////////////////////////////////////
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
	
	FillObjectTypesInValueTree();
	
	FillChoiceLists();
	
	AutomaticallyCleanUpUnusedFiles = AutomaticClearingEnabled();
	Items.Schedule.Title     = CurrentSchedule();
	
	Items.Schedule.Enabled = AutomaticallyCleanUpUnusedFiles;
	Items.SetUpSchedule.Enabled = AutomaticallyCleanUpUnusedFiles;
	
	If Common.DataSeparationEnabled() Then
		Items.SetUpSchedule.Visible = False;
		Items.Schedule.Visible = False;
	EndIf;
	
EndProcedure

&AtClient
Procedure ClearUnusedFilesOnChangeAutomatically(Item)
	SetScheduledJobParameter("Use", AutomaticallyCleanUpUnusedFiles);
	Items.Schedule.Enabled = AutomaticallyCleanUpUnusedFiles;
	Items.SetUpSchedule.Enabled = AutomaticallyCleanUpUnusedFiles;
EndProcedure

#EndRegion

#Region MetadataObjectTreeFormTableItemsEventHandlers

&AtClient
Procedure MetadataObjectsTreeBeforeAddRow(Item, Cancel, Clone, Parent, Folder, Parameter)
	
	Cancel = True;
	If NOT Clone Then
		AttachIdleHandler("AddFileCleanupSettings", 0.1, True);
	EndIf;
	
EndProcedure

&AtClient
Procedure MetadataObjectsTreeBeforeRowChange(Item, Cancel)
	
	If Item.CurrentData.GetParent() = Undefined Then
		Cancel = True;
	EndIf;
	
	If Item.CurrentItem = Items.MetadataObjectsTreeAction Then
		FillChoiceList(Items.MetadataObjectsTree.CurrentItem);
	EndIf;

EndProcedure

&AtClient
Procedure MetadataObjectsTreeChoice(Item, RowSelected, Field, StandardProcessing)
	
	If Field.Name = "MetadataObjectsTreeFilterRule" Then
		StandardProcessing = False;
		OpenSettingsForm();
	EndIf;
	
EndProcedure

&AtClient
Procedure MetadataObjectsTreeFilterRuleStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	AttachIdleHandler("OpenSettingsForm", 0.1, True);
	
EndProcedure

&AtClient
Procedure MetadataObjectsTreeActionOnChange(Item)
	
	WriteCurrentSettings();
	
EndProcedure

&AtClient
Procedure MetadataObjectsTreeClearingPeriodOnChange(Item)
	
	WriteCurrentSettings();
		
EndProcedure

&AtClient
Procedure MetadataObjectsTreeChoiceProcessing(Item, ValueSelected, StandardProcessing)
	
	StandardProcessing = False;
	AddSettingsByOwner(ValueSelected);

EndProcedure

&AtClient
Procedure MetadataObjectsTreeBeforeDelete(Item, Cancel)
	
	Cancel = True;
	
	SettingToDelete = MetadataObjectsTree.FindByID(Items.MetadataObjectsTree.CurrentRow);
	If SettingToDelete <> Undefined Then
		
		SettingToDeleteParent = SettingToDelete.GetParent();
		
		If SettingToDeleteParent <> Undefined AND SettingToDeleteParent.DetailedInfoAvailable Then
			
			QuestionText = NStr("ru = 'Удаление настройки приведет к прекращению очистки файлов
			|по заданным в ней правилам. Продолжить?'; 
			|en = 'If you delete the setting, you will not be able
			|to clean up files according to the rules defined in it.'; 
			|pl = 'Usunięcie ustawienia spowoduje zatrzymanie czyszczenia plików
			|zgodnie z określonymi w nich regułami. Chcesz kontynuować?';
			|de = 'Das Löschen der Einstellung beendet das Löschen von Dateien
			|gemäß den darin festgelegten Regeln. Fortfahren?';
			|ro = 'Ștergerea setării va conduce la încetarea golirii fișierelor
			|conform regulilor specificate în ea. Continuați?';
			|tr = 'Ayarların silinmesi, belirlenmiş kurallara göre dosyaların silinmesinin durdurulmasına
			| yol açar.  Devam edilsin mi?'; 
			|es_ES = 'La eliminación del ajuste llevará a la interrupción de vaciar los archivos 
			|según las reglas establecidas. ¿Continuar?'");
			NotifyDescription = New NotifyDescription("DeleteSettingItemCompletion", ThisObject);
			ShowQueryBox(NotifyDescription, QuestionText, QuestionDialogMode.YesNo, , DialogReturnCode.No, NStr("ru = 'Предупреждение'; en = 'Warning'; pl = 'Ostrzeżenie';de = 'Warnung';ro = 'Avertisment';tr = 'Uyarı'; es_ES = 'Aviso'"));
			Return;
			
		EndIf;
		
	EndIf;
	
	MessageText = NStr("ru = 'Расширенная настройка очистки файлов не предусмотрена для этого объекта.'; en = 'Advanced file cleanup settings are unavailable for this object.'; pl = 'Zaawansowane ustawienia czyszczenia plików nie jest dostępne dla tego obiektu.';de = 'Die erweiterte Einstellung zur Bereinigung von Dateien ist für dieses Objekt nicht verfügbar.';ro = 'Setarea extinsă a golirii fișierelor nu este prevăzută pentru acest obiect.';tr = 'Bu nesne için genişletilmiş dosya temizleme ayarı öngörülmemiştir.'; es_ES = 'El ajuste extendido de vaciar los archivos no está previsto para este objeto.'");
	ShowMessageBox(, MessageText);
	
EndProcedure

&AtClient
Procedure MetadataObjectsTreeClearingPeriodClearing(Item, StandardProcessing)
	StandardProcessing = False;
EndProcedure

&AtClient
Procedure MetadataObjectsTreeActionClearing(Item, StandardProcessing)
	
	StandardProcessing = False;
	
	SetActionForSelectedObjects(
		PredefinedValue("Enum.FilesCleanupOptions.DoNotClear"));
	
EndProcedure

#EndRegion

#Region FormCommandHandlers

&AtClient
Procedure IrrelevantFilesVolume(Command)
	
	ReportParameters = New Structure();
	ReportParameters.Insert("GenerateOnOpen", True);
	
	OpenForm("Report.IrrelevantFilesVolume.ObjectForm", ReportParameters);
	
EndProcedure

&AtClient
Procedure SetUpSchedule(Command)
	ScheduleDialog = New ScheduledJobDialog(CurrentSchedule());
	NotifyDescription = New NotifyDescription("SetUpScheduleCompletion", ThisObject);
	ScheduleDialog.Show(NotifyDescription);
EndProcedure

&AtClient
Procedure SetActionDoNotCleanUp(Command)
	
	SetActionForSelectedObjects(
		PredefinedValue("Enum.FilesCleanupOptions.DoNotClear"));
	
EndProcedure

&AtClient
Procedure SetActionCleanUpVersions(Command)
	
	If Not CanClearVersions() Then
		Return;
	EndIf;
	
	SetActionForSelectedObjects(
		PredefinedValue("Enum.FilesCleanupOptions.CleanUpVersions"));
	
EndProcedure

&AtClient
Procedure SetActionCleanUpFiles(Command)
	
	SetActionForSelectedObjects(
		PredefinedValue("Enum.FilesCleanupOptions.CleanUpFiles"));
	
EndProcedure

&AtClient
Procedure SetActionCleanUpFilesAndVersions(Command)
	
	If Not CanClearVersions() Then
		Return;
	EndIf;
	
	SetActionForSelectedObjects(
		PredefinedValue("Enum.FilesCleanupOptions.CleanUpFilesAndVersions"));
	
EndProcedure

&AtClient
Function CanClearVersions()
	If Items.MetadataObjectsTree.SelectedRows.Count() = 1 Then
		CurrentData = Items.MetadataObjectsTree.CurrentData;
		If Not CurrentData.IsFile
			AND CurrentData.FileOwner <> Undefined Then
			ShowMessageBox(, NStr("ru = 'Для данного объекта версии файлов не хранятся.'; en = 'File versions are not stored for this object.'; pl = 'Dla tego obiektu wersji plików nie są przechowywane.';de = 'Für dieses Objekt werden keine Dateiversionen gespeichert.';ro = 'Pentru acest obiect nu sunt stocate versiunile de fișiere.';tr = 'Bu nesne için dosya sürümleri kaydedilmemektedir.'; es_ES = 'No se guardan versiones de archivos para este objeto.'"));
			Return False;
		EndIf;
	EndIf;
	
	Return True;
EndFunction

&AtClient
Procedure OverOneMonth(Command)
	SetClearingPeriodForSelectedObjects(
		PredefinedValue("Enum.FilesCleanupPeriod.OverOneMonth"));
EndProcedure

&AtClient
Procedure OverSixMonths(Command)
	SetClearingPeriodForSelectedObjects(
		PredefinedValue("Enum.FilesCleanupPeriod.OverSixMonths"));
EndProcedure

&AtClient
Procedure OverOneYear(Command)
	SetClearingPeriodForSelectedObjects(
		PredefinedValue("Enum.FilesCleanupPeriod.OverOneYear"));
EndProcedure

&AtClient
Procedure Clear(Command)
	CancelBackgroundJob();
	RunScheduledJob();
	SetCommandVisibilityClear();
	AttachIdleHandler("CheckBackgroundJobExecution", 2, True);
EndProcedure

#EndRegion

#Region Private

&AtServer
Function ChoiceFormPath(FileOwner)
	
	MetadataObject = Common.MetadataObjectByID(FileOwner);
	Return MetadataObject.FullName() + ".ChoiceForm";
	
EndFunction

&AtClient
Procedure SetCommandVisibilityClear()
	
	SubordinatePages = Items.FilesCleanup.ChildItems;
	If IsBlankString(CurrentBackgroundJob) Then
		Items.FilesCleanup.CurrentPage = SubordinatePages.Clearing;
	Else
		Items.FilesCleanup.CurrentPage = SubordinatePages.BackgroundJobStatus;
	EndIf;
	
EndProcedure

&AtServer
Procedure FillChoiceLists()
	
	ChoiceListWithVersions = New ValueList;
	ChoiceListWithVersions.Add(Enums.FilesCleanupOptions.CleanUpFilesAndVersions);
	ChoiceListWithVersions.Add(Enums.FilesCleanupOptions.CleanUpVersions);
	ChoiceListWithVersions.Add(Enums.FilesCleanupOptions.DoNotClear);
	
	ChoiceListWithoutVersions = New ValueList;
	ChoiceListWithoutVersions.Add(Enums.FilesCleanupOptions.CleanUpFiles);
	ChoiceListWithoutVersions.Add(Enums.FilesCleanupOptions.DoNotClear);
	
EndProcedure

&AtClient
Procedure FillChoiceList(Item)
	
	TreeRow = Items.MetadataObjectsTree.CurrentData;
	
	Item.ChoiceList.Clear();
	
	If TreeRow.IsFile Then
		ChoiceList = ChoiceListWithVersions;
	Else
		ChoiceList = ChoiceListWithoutVersions;
	EndIf;
	
	For Each ListItem In ChoiceList Do
		Item.ChoiceList.Add(ListItem.Value);
	EndDo;
	
EndProcedure

&AtServer
Procedure FillObjectTypesInValueTree()
	
	CleanupSettings = InformationRegisters.FilesClearingSettings.CurrentClearSettings();
	
	MOTree = FormAttributeToValue("MetadataObjectsTree");
	MOTree.Rows.Clear();
	
	MetadataCatalogs = Metadata.Catalogs;
	
	TypesTable = New ValueTable;
	TypesTable.Columns.Add("FileOwner");
	TypesTable.Columns.Add("FileOwnerType");
	TypesTable.Columns.Add("FileOwnerName");
	TypesTable.Columns.Add("IsFile", New TypeDescription("Boolean"));
	TypesTable.Columns.Add("DetailedInfoAvailable"  , New TypeDescription("Boolean"));
	ExceptionsArray = FilesOperationsInternal.ExceptionItemsOnClearFiles();
	For Each Catalog In MetadataCatalogs Do
		If Catalog.Attributes.Find("FileOwner") <> Undefined Then
			FilesOwnersTypes = Catalog.Attributes.FileOwner.Type.Types();
			For Each OwnerType In FilesOwnersTypes Do
				
				If ExceptionsArray.Find(Catalog) <> Undefined Then
					Continue;
				EndIf;
				
				NewRow = TypesTable.Add();
				NewRow.FileOwner = OwnerType;
				NewRow.FileOwnerType = Catalog;
				OwnerMetadata = Metadata.FindByType(OwnerType);
				NewRow.FileOwnerName = OwnerMetadata.FullName();
				If Metadata.Catalogs.Contains(OwnerMetadata)
					AND OwnerMetadata.Hierarchical Then
					
					NewRow.DetailedInfoAvailable = True;
					
				EndIf;
				If Not StrEndsWith(Catalog.Name, "AttachedFiles") Then
					NewRow.IsFile = True;
				EndIf;
			EndDo;
		EndIf;
	EndDo;
	
	AllCatalogs = Catalogs.AllRefsType();
	
	AllDocuments = Documents.AllRefsType();
	CatalogsNode = Undefined;
	DocumentsNode = Undefined;
	BusinessProcessesNode = Undefined;
	
	FilesOwners = New Array;
	For Each Type In TypesTable Do
		
		If StrStartsWith(Type.FileOwnerType.Name, "Delete")
			Or FilesOwners.Find(Type.FileOwnerName) <> Undefined Then
			Continue;
		EndIf;
		
		FilesOwners.Add(Type.FileOwnerName);
		
		If AllCatalogs.ContainsType(Type.FileOwner) Then
			If CatalogsNode = Undefined Then
				CatalogsNode = MOTree.Rows.Add();
				CatalogsNode.ObjectDescriptionSynonym = NStr("ru = 'Справочники'; en = 'Catalogs'; pl = 'Katalogi';de = 'Stammdaten';ro = 'Cataloage';tr = 'Ana kayıtlar'; es_ES = 'Catálogos'");
			EndIf;
			NewTableRow = CatalogsNode.Rows.Add();
			ObjectID = Common.MetadataObjectID(Type.FileOwner);
			DetailedSettings = CleanupSettings.FindRows(New Structure(
				"OwnerID, IsFile",
				ObjectID, Type.IsFile));
			If DetailedSettings.Count() > 0 Then
				For Each Setting In DetailedSettings Do
					DetalizedSetting = NewTableRow.Rows.Add();
					DetalizedSetting.FileOwner = Setting.FileOwner;
					DetalizedSetting.FileOwnerType = Setting.FileOwnerType;
					DetalizedSetting.ObjectDescriptionSynonym = Setting.FileOwner;
					DetalizedSetting.Action = Setting.Action;
					DetalizedSetting.FilterRule = "Change";
					DetalizedSetting.ClearingPeriod = Setting.ClearingPeriod;
					DetalizedSetting.IsFile = Setting.IsFile;
				EndDo;
			EndIf;
		ElsIf AllDocuments.ContainsType(Type.FileOwner) Then
			If DocumentsNode = Undefined Then
				DocumentsNode = MOTree.Rows.Add();
				DocumentsNode.ObjectDescriptionSynonym = NStr("ru = 'Документы'; en = 'Documents'; pl = 'Dokumenty';de = 'Dokumente';ro = 'Documente';tr = 'Belgeler'; es_ES = 'Documentos'");
			EndIf;
			NewTableRow = DocumentsNode.Rows.Add();
		ElsIf BusinessProcesses.AllRefsType().ContainsType(Type.FileOwner) Then
			If BusinessProcessesNode = Undefined Then
				BusinessProcessesNode = MOTree.Rows.Add();
				BusinessProcessesNode.ObjectDescriptionSynonym = NStr("ru = 'Бизнес-процессы'; en = 'Business processes'; pl = 'Procesy biznesowe';de = 'Geschäftsprozesse';ro = 'Procesele de afaceri';tr = 'İş süreçleri'; es_ES = 'Procesos de negocio'");
			EndIf;
			NewTableRow = BusinessProcessesNode.Rows.Add();
		EndIf;
		ObjectMetadata = Metadata.FindByType(Type.FileOwner);
		NewTableRow.FileOwner = Common.MetadataObjectID(Type.FileOwner);
		NewTableRow.FileOwnerType = Common.MetadataObjectID(Type.FileOwnerType);
		NewTableRow.ObjectDescriptionSynonym = ObjectMetadata.Synonym;
		NewTableRow.FilterRule = "Change";
		NewTableRow.IsFile = Type.IsFile;
		NewTableRow.DetailedInfoAvailable = Type.DetailedInfoAvailable;
		
		FoundSettings = CleanupSettings.FindRows(New Structure("FileOwner, IsFile", NewTableRow.FileOwner, Type.IsFile));
		If FoundSettings.Count() > 0 Then
			NewTableRow.Action = FoundSettings[0].Action;
			NewTableRow.ClearingPeriod = FoundSettings[0].ClearingPeriod;
		Else
			NewTableRow.Action = Enums.FilesCleanupOptions.DoNotClear;
			NewTableRow.ClearingPeriod = Enums.FilesCleanupPeriod.OverOneYear;
		EndIf;
	EndDo;
	
	For Each TopLevelNode In MOTree.Rows Do
		TopLevelNode.Rows.Sort("ObjectDescriptionSynonym");
	EndDo;
	ValueToFormAttribute(MOTree, "MetadataObjectsTree");
	
EndProcedure

&AtClient
Procedure SetUpScheduleCompletion(Schedule, AdditionalParameters) Export
	If Schedule = Undefined Then
		Return;
	EndIf;
	
	SetScheduledJobParameter("Schedule", Schedule);
	Items.Schedule.Title = Schedule;
	
EndProcedure

&AtServer
Procedure SetClearingPeriodForSelectedObjects(ClearingPeriod)
	
	For Each RowID In Items.MetadataObjectsTree.SelectedRows Do
		TreeItem = MetadataObjectsTree.FindByID(RowID);
		If TreeItem.GetParent() = Undefined Then
			For Each TreeChildItem In TreeItem.GetItems() Do
				SetClearingPeriodForSelectedObject(TreeChildItem, ClearingPeriod);
			EndDo;
		Else
			SetClearingPeriodForSelectedObject(TreeItem, ClearingPeriod);
		EndIf;
	EndDo;
	
EndProcedure

&AtServer
Procedure SetClearingPeriodForSelectedObject(SelectedObject, ClearingPeriod)
	
	SelectedObject.ClearingPeriod = ClearingPeriod;
	SaveCurrentObjectSettings(
		SelectedObject.FileOwner,
		SelectedObject.FileOwnerType,
		SelectedObject.Action,
		ClearingPeriod,
		SelectedObject.IsFile);
	
EndProcedure

&AtServer
Procedure SetActionForSelectedObjects(Val Action)
	
	For Each RowID In Items.MetadataObjectsTree.SelectedRows Do
		TreeItem = MetadataObjectsTree.FindByID(RowID);
		If TreeItem.GetParent() = Undefined Then
			For Each TreeChildItem In TreeItem.GetItems() Do
				SetActionOfSelectedObjectWithRecursion(TreeChildItem, Action);
			EndDo;
		Else
			SetActionOfSelectedObjectWithRecursion(TreeItem, Action);
		EndIf;
	EndDo;
	
EndProcedure

&AtServer
Procedure SetActionOfSelectedObjectWithRecursion(SelectedObject, Val Action)
	
	SetSelectedObjectAction(SelectedObject, Action);
	For Each ChildObject In SelectedObject.GetItems() Do
		SetSelectedObjectAction(ChildObject, Action);
	EndDo;
	
EndProcedure

&AtServer
Procedure SetSelectedObjectAction(SelectedObject, Val Action)
	
	If Not SelectedObject.IsFile Then
		If Action = PredefinedValue("Enum.FilesCleanupOptions.CleanUpVersions") Then
			Return;
		ElsIf Action = PredefinedValue("Enum.FilesCleanupOptions.CleanUpFilesAndVersions") Then
			Action = PredefinedValue("Enum.FilesCleanupOptions.CleanUpFiles");
		EndIf;
	ElsIf Action = PredefinedValue("Enum.FilesCleanupOptions.CleanUpFiles") Then
		Action = PredefinedValue("Enum.FilesCleanupOptions.CleanUpFilesAndVersions");
	EndIf;
	
	SelectedObject.Action = Action;
	SaveCurrentObjectSettings(
		SelectedObject.FileOwner,
		SelectedObject.FileOwnerType,
		Action,
		SelectedObject.ClearingPeriod,
		SelectedObject.IsFile);
	
EndProcedure

&AtClient
Procedure WriteCurrentSettings()
	
	CurrentData = Items.MetadataObjectsTree.CurrentData;
	SaveCurrentObjectSettings(
		CurrentData.FileOwner,
		CurrentData.FileOwnerType,
		CurrentData.Action,
		CurrentData.ClearingPeriod,
		CurrentData.IsFile);
	
EndProcedure

&AtServer
Procedure SaveCurrentObjectSettings(FileOwner, FileOwnerType, Action, ClearingPeriod, IsFile)
	
	Setting                   = InformationRegisters.FilesClearingSettings.CreateRecordManager();
	Setting.FileOwner     = FileOwner;
	Setting.FileOwnerType = FileOwnerType;
	Setting.Action          = Action;
	Setting.ClearingPeriod     = ClearingPeriod;
	Setting.IsFile           = IsFile;
	Setting.Write();
	
EndProcedure

&AtClient
Procedure OpenSettingsForm()
	
	CurrentData = Items.MetadataObjectsTree.CurrentData;
	
	If CurrentData.ClearingPeriod <> PredefinedValue("Enum.FilesCleanupPeriod.ByRule") Then
		Return;
	EndIf;
	
	CheckSettingExistence(
		CurrentData.FileOwner,
		CurrentData.FileOwnerType,
		CurrentData.Action,
		CurrentData.ClearingPeriod,
		CurrentData.IsFile);
	
	Filter = New Structure(
		"FileOwner, FileOwnerType",
		CurrentData.FileOwner,
		CurrentData.FileOwnerType);
	
	ValueType = Type("InformationRegisterRecordKey.FilesClearingSettings");
	WriteParameters = New Array(1);
	WriteParameters[0] = Filter;
	
	RecordKey = New(ValueType, WriteParameters);
	
	WriteParameters = New Structure;
	WriteParameters.Insert("Key", RecordKey);
	
	OpenForm("InformationRegister.FilesClearingSettings.RecordForm", WriteParameters, ThisObject);
	
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

&AtServer
Procedure CheckSettingExistence(FileOwner, FileOwnerType, Action, ClearingPeriod, IsFile)
	
	SetPrivilegedMode(True);
	
	Query = New Query;
	Query.Text = 
		"SELECT
		|	FilesClearingSettings.FileOwner,
		|	FilesClearingSettings.FileOwnerType
		|FROM
		|	InformationRegister.FilesClearingSettings AS FilesClearingSettings
		|WHERE
		|	FilesClearingSettings.FileOwner = &FileOwner
		|	AND FilesClearingSettings.FileOwnerType = &FileOwnerType";
	
	Query.SetParameter("FileOwner", FileOwner);
	Query.SetParameter("FileOwnerType", FileOwnerType);
	
	RecordsCount = Query.Execute().Unload().Count();;
	
	If RecordsCount = 0 Then
		SaveCurrentObjectSettings(FileOwner, FileOwnerType, Action, ClearingPeriod, IsFile);
	EndIf;
	
EndProcedure

&AtClient
Procedure CheckBackgroundJobExecution()
	If ValueIsFilled(BackgroundJobID) AND Not JobCompleted(BackgroundJobID) Then
		AttachIdleHandler("CheckBackgroundJobExecution", 5, True);
	Else
		BackgroundJobID = "";
		CurrentBackgroundJob = "";
		SetCommandVisibilityClear();
	EndIf;
EndProcedure

&AtServerNoContext
Function JobCompleted(BackgroundJobID)
	Return TimeConsumingOperations.JobCompleted(BackgroundJobID);
EndFunction

&AtServer
Procedure RunScheduledJob()
	
	ScheduledJobMetadata = Metadata.ScheduledJobs.ExcessiveFilesClearing;
	
	Filter = New Structure;
	MethodName = ScheduledJobMetadata.MethodName;
	Filter.Insert("MethodName", MethodName);
	Filter.Insert("State", BackgroundJobState.Active);
	CleanupBackgroundJobs = BackgroundJobs.GetBackgroundJobs(Filter);
	If CleanupBackgroundJobs.Count() > 0 Then
		BackgroundJobID = CleanupBackgroundJobs[0].UUID;
	Else
		JobParameters = TimeConsumingOperations.BackgroundExecutionParameters(UUID);
		JobParameters.BackgroundJobDescription = StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = 'Запуск вручную: %1'; en = 'Manual start: %1'; pl = 'Uruchomienie ręczne: %1';de = 'Manuell starten: %1';ro = 'Lansare manuală: %1';tr = 'Manuel olarak başlat: %1'; es_ES = 'Iniciar manualmente: %1'"), ScheduledJobMetadata.Synonym);
		JobResult = TimeConsumingOperations.ExecuteInBackground(ScheduledJobMetadata.MethodName, New Structure, JobParameters);
		If ValueIsFilled(BackgroundJobID) Then
			BackgroundJobID = JobResult.JobID;
		EndIf;
	EndIf;
	
	CurrentBackgroundJob = "Clearing";
	
EndProcedure

&AtServer
Procedure SetScheduledJobParameter(ParameterName, ParameterValue)
	
	JobParameters = New Structure;
	JobParameters.Insert("Metadata", Metadata.ScheduledJobs.ExcessiveFilesClearing);
	If Not Common.DataSeparationEnabled() Then
		JobParameters.Insert("MethodName", Metadata.ScheduledJobs.ExcessiveFilesClearing.MethodName);
	EndIf;
	
	SetPrivilegedMode(True);
	
	JobsList = ScheduledJobsServer.FindJobs(JobParameters);
	If JobsList.Count() = 0 Then
		JobParameters.Insert(ParameterName, ParameterValue);
		ScheduledJobsServer.AddJob(JobParameters);
	Else
		JobParameters = New Structure(ParameterName, ParameterValue);
		For Each Job In JobsList Do
			ScheduledJobsServer.ChangeJob(Job, JobParameters);
		EndDo;
	EndIf;
	
EndProcedure

&AtServer
Function GetScheduledJobParameter(ParameterName, DefaultValue)
	
	JobParameters = New Structure;
	JobParameters.Insert("Metadata", Metadata.ScheduledJobs.ExcessiveFilesClearing);
	If Not Common.DataSeparationEnabled() Then
		JobParameters.Insert("MethodName", Metadata.ScheduledJobs.ExcessiveFilesClearing.MethodName);
	EndIf;
	
	SetPrivilegedMode(True);
	
	JobsList = ScheduledJobsServer.FindJobs(JobParameters);
	For Each Job In JobsList Do
		Return Job[ParameterName];
	EndDo;
	
	Return DefaultValue;
	
EndFunction

&AtServer
Procedure AddSettingsByOwner(SelectedValue)
	
	RowOwner = MetadataObjectsTree.FindByID(Items.MetadataObjectsTree.CurrentRow);
	
	OwnerRecord = InformationRegisters.FilesClearingSettings.CreateRecordManager();
	FillPropertyValues(OwnerRecord, RowOwner);
	OwnerRecord.Write();
	
	OwnerElement = RowOwner.GetItems();
	For Each Setting In SelectedValue Do
		NewRecord = InformationRegisters.FilesClearingSettings.CreateRecordManager();
		NewRecord.FileOwner = Setting;
		NewRecord.FileOwnerType = RowOwner.FileOwnerType;
		NewRecord.Action = Enums.FilesCleanupOptions.DoNotClear;
		NewRecord.ClearingPeriod = Enums.FilesCleanupPeriod.OverOneYear;
		NewRecord.IsFile = RowOwner.IsFile;
		NewRecord.Write(True);

		DetalizedSetting = OwnerElement.Add();
		FillPropertyValues(DetalizedSetting, NewRecord);
		DetalizedSetting.ObjectDescriptionSynonym = Setting;
		DetalizedSetting.FilterRule = NStr("ru = 'Изменить правило'; en = 'Change rule'; pl = 'Zmień regułę';de = 'Ändern der Regel';ro = 'Modifică regula';tr = 'Kural değiştir'; es_ES = 'Cambiar regla'");
	EndDo;
	
EndProcedure

&AtServer
Procedure ClearSettingData()
	
	SettingToDelete = MetadataObjectsTree.FindByID(Items.MetadataObjectsTree.CurrentRow);
	
	RecordManager = InformationRegisters.FilesClearingSettings.CreateRecordManager();
	RecordManager.FileOwner = SettingToDelete.FileOwner;
	RecordManager.FileOwnerType = SettingToDelete.FileOwnerType;
	RecordManager.Read();
	RecordManager.Delete();
	
	SettingsItemParent = SettingToDelete.GetParent();
	If SettingsItemParent <> Undefined Then
		SettingsItemParent.GetItems().Delete(SettingToDelete);
	Else
		MetadataObjectsTree.GetItems().Delete(SettingToDelete);
	EndIf;
	
EndProcedure

&AtServer
Function CurrentSchedule()
	Return GetScheduledJobParameter("Schedule", New JobSchedule);
EndFunction

&AtServer
Function AutomaticClearingEnabled()
	Return GetScheduledJobParameter("Use", False);
EndFunction

&AtServer
Procedure SetConditionalAppearance()
	
	ConditionalAppearance.Items.Clear();
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField("MetadataObjectsTreeFilterRule");
	
	FilterItemsGroup = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterItemsGroup.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	
	ItemFilter = FilterItemsGroup.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("MetadataObjectsTree.Action");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.FilesCleanupOptions.DoNotClear;
	
	ItemFilter = FilterItemsGroup.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("MetadataObjectsTree.ClearingPeriod");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotEqual;
	ItemFilter.RightValue = Enums.FilesCleanupPeriod.ByRule;
	
	Item.Appearance.SetParameterValue("Text", "");
	Item.Appearance.SetParameterValue("ReadOnly", True);

	Item = ConditionalAppearance.Items.Add();
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField("MetadataObjectsTreeCleanupPeriod");
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("MetadataObjectsTree.Action");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.FilesCleanupOptions.DoNotClear;
	
	Item.Appearance.SetParameterValue("Text", "");
	Item.Appearance.SetParameterValue("ReadOnly", True);
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField("MetadataObjectsTreeAction");
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("MetadataObjectsTree.Action");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotEqual;
	ItemFilter.RightValue = Enums.FilesCleanupOptions.DoNotClear;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("MetadataObjectsTree.Action");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;

	Item.Appearance.SetParameterValue("Font", New Font(WindowsFonts.DefaultGUIFont, , , True, False, False, False));
	
EndProcedure

&AtClient
Procedure DeleteSettingItemCompletion(Result, AdditionalParameters) Export
	
	If Result = DialogReturnCode.Yes Then
		ClearSettingData();
	EndIf;
	
EndProcedure

&AtClient
Procedure AddFileCleanupSettings()
	
	Var Setting, ChoiceFormParameters, ExistingSettingsList, TreeRow, ExistingSettings, MessageText, FixedSettings, SettingItem;
	
	TreeRow = Items.MetadataObjectsTree.CurrentData;
	
	If Not TreeRow.DetailedInfoAvailable Then
		MessageText = NStr("ru = 'Расширенная настройка очистки файлов не предусмотрена для этого объекта.'; en = 'Advanced file cleanup settings are unavailable for this object.'; pl = 'Zaawansowane ustawienia czyszczenia plików nie jest dostępne dla tego obiektu.';de = 'Die erweiterte Einstellung zur Bereinigung von Dateien ist für dieses Objekt nicht verfügbar.';ro = 'Setarea extinsă a golirii fișierelor nu este prevăzută pentru acest obiect.';tr = 'Bu nesne için genişletilmiş dosya temizleme ayarı öngörülmemiştir.'; es_ES = 'El ajuste extendido de vaciar los archivos no está previsto para este objeto.'");
		ShowMessageBox(, MessageText);
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

#EndRegion