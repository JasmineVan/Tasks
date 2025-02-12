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
	
	FillObjectTypesInValueTree();
	FillChoiceLists();
	
	Items.Clear.Visible = False;
	Items.Schedule.Title = CurrentSchedule();
	DeleteObsoleteVersionsAutomatically = AutomaticClearingEnabled();
	Items.Schedule.Enabled = DeleteObsoleteVersionsAutomatically;
	Items.SetUpSchedule.Enabled = DeleteObsoleteVersionsAutomatically;
	Items.ObsoleteVersionsInformation.Title = StatusTextCalculation();
	
	ShowCleanupScheduleSetting = Not Common.DataSeparationEnabled();
	Items.Schedule.Visible = ShowCleanupScheduleSetting;
	Items.SetUpSchedule.Visible = ShowCleanupScheduleSetting;
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	UpdateObsoleteVersionsInfo();
EndProcedure

#EndRegion

#Region MetadataObjectTreeFormTableItemsEventHandlers

&AtClient
Procedure MetadataObjectsTreeBeforeRowChange(Item, Cancel)
	
	If Item.CurrentData.GetParent() = Undefined Then
		Cancel = True;
	EndIf;
	
	If Item.CurrentItem = Items.VersioningMode Then
		FillChoiceList(Items.MetadataObjectsTree.CurrentItem);
	EndIf;
	
EndProcedure

&AtClient
Procedure SettingOnChange(Item)
	CurrentData = Items.MetadataObjectsTree.CurrentData;
	SaveCurrentObjectSettings(CurrentData.ObjectType, CurrentData.VersioningMode, CurrentData.VersionsLifetime);
	UpdateObsoleteVersionsInfo();
EndProcedure

#EndRegion

#Region FormCommandHandlers

&AtClient
Procedure SetVersioningOptionDontVersionize(Command)
	
	SetSelectedRowsVersioningMode(
		PredefinedValue("Enum.ObjectsVersioningOptions.DontVersionize"));	
	
EndProcedure

&AtClient
Procedure SetVersioningModeOnWrite(Command)
	
	SetSelectedRowsVersioningMode(
		PredefinedValue("Enum.ObjectsVersioningOptions.VersionizeOnWrite"));	
	
EndProcedure

&AtClient
Procedure SetVersioningOptionOnPost(Command)
	
	If DocumentsThatCannotBePostedSelected() Then
		ShowMessageBox(, NStr("ru = 'Документам, которые не могут быть проведены, установлен режим версионирования ""Версионировать при записи"".'; en = 'Documents that cannot be posted are in ""on write"" versioning mode.'; pl = 'Dla dokumentów, które nie mogą być zaksięgowany ustawiono tryb wersjonowania ""Wersjonowanie podczas zapisu"".';de = 'Dokumente, die nicht gebucht werden können, werden in den Versionsmodus ""Version beim Schreiben"" gesetzt.';ro = 'Documentele care nu pot fi validate sunt setate la regimul de versionare ""Versionare la înregistrare"".';tr = 'Onaylanamayan dokümanlar, ""Yazma versiyonu"" modelleme moduna ayarlanmıştır.'; es_ES = 'Documentos que no pueden enviarse se han establecido para el modo de versionar ""Versión al grabar"".'"));
	EndIf;
	
	SetSelectedRowsVersioningMode(
		PredefinedValue("Enum.ObjectsVersioningOptions.VersionizeOnPost"));	
	
EndProcedure

&AtClient
Procedure ApplyDefaultSettings(Command)
	
	SetSelectedRowsVersioningMode(Undefined);
	
EndProcedure

&AtClient
Procedure Update(Command)
	FillObjectTypesInValueTree();
	UpdateObsoleteVersionsInfo();
	For Each Item In MetadataObjectsTree.GetItems() Do
		Items.MetadataObjectsTree.Expand(Item.GetID(), True);
	EndDo;
EndProcedure

&AtClient
Procedure Clear(Command)
	CancelBackgroundJob();
	RunScheduledJob();
	StartUpdateObsoleteVersionsInformation();
	AttachIdleHandler("CheckBackgroundJobExecution", 2, True);
EndProcedure

&AtClient
Procedure LastWeek(Command)
	SetSelectedObjectsVersionStoringDuration(
		PredefinedValue("Enum.VersionsLifetimes.LastWeek"));
	UpdateObsoleteVersionsInfo();
EndProcedure

&AtClient
Procedure LastMonth(Command)
	SetSelectedObjectsVersionStoringDuration(
		PredefinedValue("Enum.VersionsLifetimes.LastMonth"));
	UpdateObsoleteVersionsInfo();
EndProcedure

&AtClient
Procedure LastThreeMonths(Command)
	SetSelectedObjectsVersionStoringDuration(
		PredefinedValue("Enum.VersionsLifetimes.LastThreeMonths"));
	UpdateObsoleteVersionsInfo();
EndProcedure

&AtClient
Procedure LastSixMonths(Command)
	SetSelectedObjectsVersionStoringDuration(
		PredefinedValue("Enum.VersionsLifetimes.LastSixMonths"));
	UpdateObsoleteVersionsInfo();
EndProcedure

&AtClient
Procedure LastYear(Command)
	SetSelectedObjectsVersionStoringDuration(
		PredefinedValue("Enum.VersionsLifetimes.LastYear"));
	UpdateObsoleteVersionsInfo();
EndProcedure

&AtClient
Procedure Indefinitely(Command)
	SetSelectedObjectsVersionStoringDuration(
		PredefinedValue("Enum.VersionsLifetimes.Indefinitely"));
	UpdateObsoleteVersionsInfo();
EndProcedure

&AtClient
Procedure VersionizeOnStart(Command)
	SetSelectedRowsVersioningMode(
		PredefinedValue("Enum.ObjectsVersioningOptions.VersionizeOnStart"));
EndProcedure

&AtClient
Procedure SetUpSchedule(Command)
	ScheduleDialog = New ScheduledJobDialog(CurrentSchedule());
	NotifyDescription = New NotifyDescription("SetUpScheduleCompletion", ThisObject);
	ScheduleDialog.Show(NotifyDescription);
EndProcedure

&AtClient
Procedure StoredObjectsVersionsCountAndSize(Command)
	OpenForm("Report.ObjectVersionsAnalysis.ObjectForm");
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure FillChoiceList(Item)
	
	TreeRow = Items.MetadataObjectsTree.CurrentData;
	
	Item.ChoiceList.Clear();
	
	If TreeRow.ObjectClass = "DocumentsClass" AND TreeRow.BeingPosted Then
		ChoiceList = SelectionListDocuments;
	ElsIf TreeRow.ObjectClass = "BusinessProcessesClass" Then
		ChoiceList = SelectionListBusinessProcesses;
	Else
		ChoiceList = SelectionListCatalogs;
	EndIf;
	
	For Each ListItem In ChoiceList Do
		Item.ChoiceList.Add(ListItem.Value);
	EndDo;
	
EndProcedure

&AtServer
Procedure FillObjectTypesInValueTree()
	
	VersioningSettings = CurrentVersioningSettings();
	
	MOTree = FormAttributeToValue("MetadataObjectsTree");
	MOTree.Rows.Clear();
	
	// Command parameter type ChangeHistory contains objects that are to be versionized.
	// 
	TypesArray = Metadata.CommonCommands.ChangeHistory.CommandParameterType.Types();
	HasBusinessProcesses = False;
	AllCatalogs = Catalogs.AllRefsType();
	AllDocuments = Documents.AllRefsType();
	CatalogsNode = Undefined;
	DocumentsNode = Undefined;
	BusinessProcessesNode = Undefined;
	
	For Each Type In TypesArray Do
		If Type = Type("CatalogRef.MetadataObjectIDs") Then
			Continue;
		EndIf;
		If AllCatalogs.ContainsType(Type) Then
			If CatalogsNode = Undefined Then
				CatalogsNode = MOTree.Rows.Add();
				CatalogsNode.ObjectDescriptionSynonym = NStr("ru = 'Справочники'; en = 'Catalogs'; pl = 'Katalogi';de = 'Stammdaten';ro = 'Cataloage';tr = 'Ana kayıtlar'; es_ES = 'Catálogos'");
				CatalogsNode.ObjectClass = "01CatalogsClassRoot";
				CatalogsNode.PictureCode = 2;
			EndIf;
			NewTableRow = CatalogsNode.Rows.Add();
			NewTableRow.PictureCode = 19;
			NewTableRow.ObjectClass = "CatalogsClass";
		ElsIf AllDocuments.ContainsType(Type) Then
			If DocumentsNode = Undefined Then
				DocumentsNode = MOTree.Rows.Add();
				DocumentsNode.ObjectDescriptionSynonym = NStr("ru = 'Документы'; en = 'Documents'; pl = 'Dokumenty';de = 'Dokumente';ro = 'Documente';tr = 'Belgeler'; es_ES = 'Documentos'");
				DocumentsNode.ObjectClass = "02DocumentsClassRoot";
				DocumentsNode.PictureCode = 3;
			EndIf;
			NewTableRow = DocumentsNode.Rows.Add();
			NewTableRow.PictureCode = 20;
			NewTableRow.ObjectClass = "DocumentsClass";
		ElsIf BusinessProcesses.AllRefsType().ContainsType(Type) Then
			If BusinessProcessesNode = Undefined Then
				BusinessProcessesNode = MOTree.Rows.Add();
				BusinessProcessesNode.ObjectDescriptionSynonym = NStr("ru = 'Бизнес-процессы'; en = 'Business processes'; pl = 'Procesy biznesowe';de = 'Geschäftsprozesse';ro = 'Procesele de afaceri';tr = 'İş süreçleri'; es_ES = 'Procesos de negocio'");
				BusinessProcessesNode.ObjectClass = "03BusinessProcessesRoot";
				BusinessProcessesNode.ObjectType = "BusinessProcesses";
			EndIf;
			NewTableRow = BusinessProcessesNode.Rows.Add();
			NewTableRow.ObjectClass = "BusinessProcessesClass";
			HasBusinessProcesses = True;
		ElsIf ChartsOfAccounts.AllRefsType().ContainsType(Type) Then
			NameOfGroup = "04ChartsOfAccountsRoot";
			GroupPresentation = NStr("ru = 'Планы счетов'; en = 'Charts of accounts'; pl = 'Plany kont';de = 'Kontenpläne';ro = 'Planurile conturilor';tr = 'Hesap çizelgeleri'; es_ES = 'Diagramas de las cuentas'");
			GroupObjectsType = "ChartsOfAccounts";
			Folder = MOTree.Rows.Find(NameOfGroup, "ObjectClass");
			If Folder = Undefined Then
				Folder = MOTree.Rows.Add();
				Folder.ObjectDescriptionSynonym = GroupPresentation;
				Folder.ObjectClass = NameOfGroup;
				Folder.ObjectType = GroupObjectsType;
			EndIf;
			NewTableRow = Folder.Rows.Add();
			NewTableRow.ObjectClass = "ChartsOfAccountsClass";
		ElsIf ChartsOfCharacteristicTypes.AllRefsType().ContainsType(Type) Then
			NameOfGroup = "05ChartsOfCharacteristicTypesRoot";
			GroupPresentation = NStr("ru = 'Планы видов характеристик'; en = 'Charts of characteristic types'; pl = 'Plany rodzajów charakterystyk';de = 'Diagramme von charakteristischen Typen';ro = 'Diagrame de tipuri caracteristice';tr = 'Karakteristik tiplerin çizelgeleri'; es_ES = 'Diagramas de los tipos de características'");
			GroupObjectsType = "ChartsOfCharacteristicTypes";
			Folder = MOTree.Rows.Find(NameOfGroup, "ObjectClass");
			If Folder = Undefined Then
				Folder = MOTree.Rows.Add();
				Folder.ObjectDescriptionSynonym = GroupPresentation;
				Folder.ObjectClass = NameOfGroup;
				Folder.ObjectType = GroupObjectsType;
			EndIf;
			NewTableRow = Folder.Rows.Add();
			NewTableRow.ObjectClass = "ChartsOfCharacteristicTypesClass";
		EndIf;
		ObjectMetadata = Metadata.FindByType(Type);
		NewTableRow.ObjectType = Common.MetadataObjectID(Type);
		NewTableRow.ObjectDescriptionSynonym = ObjectMetadata.Synonym;
		
		FoundSettings = VersioningSettings.FindRows(New Structure("ObjectType", NewTableRow.ObjectType));
		If FoundSettings.Count() > 0 Then
			NewTableRow.VersioningMode = FoundSettings[0].VersioningMode;
			NewTableRow.VersionsLifetime = FoundSettings[0].VersionsLifetime;
			If Not ValueIsFilled(FoundSettings[0].VersionsLifetime) Then
				NewTableRow.VersionsLifetime = Enums.VersionsLifetimes.Indefinitely;
			EndIf;
		Else
			NewTableRow.VersioningMode = Enums.ObjectsVersioningOptions.DontVersionize;
			NewTableRow.VersionsLifetime = Enums.VersionsLifetimes.Indefinitely;
		EndIf;
		
		If NewTableRow.ObjectClass = "DocumentsClass" Then
			NewTableRow.BeingPosted = ? (ObjectMetadata.Posting = Metadata.ObjectProperties.Posting.Allow, True, False);
		EndIf;
	EndDo;
	MOTree.Rows.Sort("ObjectClass");
	For Each TopLevelNode In MOTree.Rows Do
		TopLevelNode.Rows.Sort("ObjectDescriptionSynonym");
	EndDo;
	ValueToFormAttribute(MOTree, "MetadataObjectsTree");
	
	Items.FormVersionizeOnStart.Visible = HasBusinessProcesses;
EndProcedure

&AtClient
Function DocumentsThatCannotBePostedSelected()
	
	For Each RowID In Items.MetadataObjectsTree.SelectedRows Do
		TreeItem = MetadataObjectsTree.FindByID(RowID);
		If TreeItem.ObjectClass = "DocumentsClass" AND Not TreeItem.BeingPosted Then
			Return True;
		EndIf;
	EndDo;
	
	Return False;
	
EndFunction

&AtServer
Procedure SetSelectedRowsVersioningMode(Val VersioningMode)
	
	For Each RowID In Items.MetadataObjectsTree.SelectedRows Do
		TreeItem = MetadataObjectsTree.FindByID(RowID);
		If TreeItem.GetParent() = Undefined Then 
			For Each TreeChildItem In TreeItem.GetItems() Do
				SetTreeItemVersioningMode(TreeChildItem, VersioningMode);
			EndDo;
		Else
			SetTreeItemVersioningMode(TreeItem, VersioningMode);
		EndIf;
	EndDo;
	
EndProcedure

&AtServer
Procedure SetTreeItemVersioningMode(TreeItem, Val VersioningMode)
	
	If VersioningMode = Undefined Then
		If TreeItem.ObjectClass = "DocumentsClass" Then
			VersioningMode = Enums.ObjectsVersioningOptions.VersionizeOnPost;
		ElsIf TreeItem.GetParent().ObjectType = "BusinessProcesses" Then
			VersioningMode = Enums.ObjectsVersioningOptions.VersionizeOnStart;
		Else
			VersioningMode = Enums.ObjectsVersioningOptions.DontVersionize;
		EndIf;
	EndIf;
	
	If VersioningMode = Enums.ObjectsVersioningOptions.VersionizeOnPost
		AND Not TreeItem.BeingPosted 
		Or VersioningMode = Enums.ObjectsVersioningOptions.VersionizeOnStart
		AND TreeItem.ObjectClass <> "BusinessProcessesClass" Then
			VersioningMode = Enums.ObjectsVersioningOptions.VersionizeOnWrite;
	EndIf;
	
	TreeItem.VersioningMode = VersioningMode;
	
	SaveCurrentObjectSettings(TreeItem.ObjectType, VersioningMode, TreeItem.VersionsLifetime);
	
EndProcedure

&AtServer
Procedure SetSelectedObjectsVersionStoringDuration(VersionLifetime)
	
	For Each RowID In Items.MetadataObjectsTree.SelectedRows Do
		TreeItem = MetadataObjectsTree.FindByID(RowID);
		If TreeItem.GetParent() = Undefined Then
			For Each TreeChildItem In TreeItem.GetItems() Do
				SetSelectedObjectVersionStoringDuration(TreeChildItem, VersionLifetime);
			EndDo;
		Else
			SetSelectedObjectVersionStoringDuration(TreeItem, VersionLifetime);
		EndIf;
	EndDo;
	
EndProcedure

&AtServer
Procedure SetSelectedObjectVersionStoringDuration(SelectedObject, VersionLifetime)
	
	SelectedObject.VersionsLifetime = VersionLifetime;
	SaveCurrentObjectSettings(SelectedObject.ObjectType, SelectedObject.VersioningMode, VersionLifetime);
	
EndProcedure

&AtServer
Procedure SaveCurrentObjectSettings(ObjectType, VersioningMode, VersionLifetime)
	ObjectsVersioning.SaveObjectVersioningConfiguration(ObjectType, VersioningMode, VersionLifetime);
EndProcedure

&AtServer
Function CurrentVersioningSettings()
	SetPrivilegedMode(True);
	QueryText =
	"SELECT
	|	ObjectVersioningSettings.ObjectType AS ObjectType,
	|	ObjectVersioningSettings.Variant AS VersioningMode,
	|	ObjectVersioningSettings.VersionsLifetime AS VersionsLifetime
	|FROM
	|	InformationRegister.ObjectVersioningSettings AS ObjectVersioningSettings";
	Query = New Query(QueryText);
	Return Query.Execute().Unload();
EndFunction

&AtClient
Procedure SetUpScheduleCompletion(Schedule, AdditionalParameters) Export
	If Schedule = Undefined Then
		Return;
	EndIf;
	SetScheduledJobParameter("Schedule", Schedule);
	Items.Schedule.Title = Schedule;
EndProcedure

&AtServer
Function CurrentSchedule()
	Return GetScheduledJobParameter("Schedule", New JobSchedule);
EndFunction

&AtClient
Procedure AutomaticallyDeleteObsoleteVersionsOnChange(Item)
	SetScheduledJobParameter("Use", DeleteObsoleteVersionsAutomatically);
	Items.Schedule.Enabled = DeleteObsoleteVersionsAutomatically;
	Items.SetUpSchedule.Enabled = DeleteObsoleteVersionsAutomatically;
EndProcedure

&AtServer
Procedure SetScheduledJobParameter(ParameterName, ParameterValue)
	JobParameters = New Structure;
	JobParameters.Insert("Metadata", Metadata.ScheduledJobs.ClearingObsoleteObjectVersions);
	
	SetPrivilegedMode(True);
	
	JobsList = ScheduledJobsServer.FindJobs(JobParameters);
	If JobsList.Count() = 0 Then
		JobParameters = New Structure;
		JobParameters.Insert(ParameterName, ParameterValue);
		JobParameters.Insert("Metadata", Metadata.ScheduledJobs.ClearingObsoleteObjectVersions);
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
	If Common.DataSeparationEnabled() Then
		JobParameters.Insert("MethodName", Metadata.ScheduledJobs.ClearingObsoleteObjectVersions.MethodName);
	Else
		JobParameters.Insert("Metadata", Metadata.ScheduledJobs.ClearingObsoleteObjectVersions);
	EndIf;
	
	SetPrivilegedMode(True);
	
	JobsList = ScheduledJobsServer.FindJobs(JobParameters);
	For Each Job In JobsList Do
		Return Job[ParameterName];
	EndDo;
	
	Return DefaultValue;
EndFunction

&AtClient
Procedure CheckBackgroundJobExecution()
	If ValueIsFilled(BackgroundJobID) AND Not JobCompleted(BackgroundJobID) Then
		AttachIdleHandler("CheckBackgroundJobExecution", 5, True);
	Else
		BackgroundJobID = "";
		If CurrentBackgroundJob = "Calculation" Then
			OutputObsoleteVersionsInfo();
			Return;
		EndIf;
		CurrentBackgroundJob = "";
		UpdateObsoleteVersionsInfo();
	EndIf;
EndProcedure

&AtServerNoContext
Function JobCompleted(BackgroundJobID)
	Return TimeConsumingOperations.JobCompleted(BackgroundJobID);
EndFunction

&AtServerNoContext
Procedure CancelJobExecution(BackgroundJobID)
	If ValueIsFilled(BackgroundJobID) Then 
		TimeConsumingOperations.CancelJobExecution(BackgroundJobID);
	EndIf;
EndProcedure

&AtServer
Procedure RunScheduledJob()
	
	ScheduledJobMetadata = Metadata.ScheduledJobs.ClearingObsoleteObjectVersions;
	
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
		If ValueIsFilled(JobResult.JobID) Then
			BackgroundJobID = JobResult.JobID;
		EndIf;
	EndIf;
	
	CurrentBackgroundJob = "Clearing";
	
EndProcedure

&AtClient
Procedure UpdateObsoleteVersionsInfo()
	DetachIdleHandler("StartUpdateObsoleteVersionsInformation");
	If CurrentBackgroundJob = "Calculation" AND ValueIsFilled(BackgroundJobID) Then
		CancelBackgroundJob();
	EndIf;
	AttachIdleHandler("StartUpdateObsoleteVersionsInformation", 2, True);
EndProcedure

&AtClient
Procedure CancelBackgroundJob()
	CancelJobExecution(BackgroundJobID);
	DetachIdleHandler("CheckBackgroundJobExecution");
	CurrentBackgroundJob = "";
	BackgroundJobID = "";
EndProcedure

&AtClient
Procedure StartUpdateObsoleteVersionsInformation()
	
	Items.Clear.Visible = CurrentBackgroundJob <> "Clearing";
	If ValueIsFilled(BackgroundJobID) Then
		If CurrentBackgroundJob = "Calculation" Then
			Items.ObsoleteVersionsInformation.Title = StatusTextCalculation();
		Else
			Items.ObsoleteVersionsInformation.Title = StatusTextCleanup();
		EndIf;
		Return;
	EndIf;
	
	Items.ObsoleteVersionsInformation.Title = StatusTextCalculation();
	TimeConsumingOperation = SerachForObsoleteVersions();
	
	IdleParameters = TimeConsumingOperationsClient.IdleParameters(ThisObject);
	IdleParameters.OutputIdleWindow = False;
	
	NotifyDescription = New NotifyDescription("OnCompleteSearchForObsoleteVersions", ThisObject);
	TimeConsumingOperationsClient.WaitForCompletion(TimeConsumingOperation, NotifyDescription, IdleParameters);
	
EndProcedure

&AtClient
Procedure OnCompleteSearchForObsoleteVersions(Result, AdditionalParameters) Export
	
	If Result = Undefined Then
		Return;
	EndIf;
	
	If Result.Status = "Error" Then
		EventLogClient.AddMessageForEventLog(NStr("ru = 'Поиск устаревших версий объектов'; en = 'Search for outdated versions'; pl = 'Wyszukaj przestarzałe wersje obiektów';de = 'Suche nach veralteten Versionen von Objekten';ro = 'Căutarea versiunilor vechi ale obiectelor';tr = 'Nesnelerin eski sürümlerini ara ...'; es_ES = 'Buscar las versiones antiguas de los objetos'", CommonClient.DefaultLanguageCode()),
			"Error", Result.DetailedErrorPresentation, , True);
		Raise Result.BriefErrorPresentation;
	EndIf;

	BackgroundJobID = "";
	OutputObsoleteVersionsInfo();
	
EndProcedure

&AtClientAtServerNoContext
Function StatusTextCalculation()
	Return NStr("ru = 'Поиск устаревших версий...'; en = 'Searching for outdated versions...'; pl = 'Wyszukaj nieaktualne wersje...';de = 'Nach veralteten Versionen suchen...';ro = 'Căutarea versiunilor mai vechi...';tr = 'Eski sürümlerde ara ...'; es_ES = 'Buscar las versiones antiguas...'");
EndFunction

&AtClientAtServerNoContext
Function StatusTextCleanup()
	Return NStr("ru = 'Выполняется очистка устаревших версий...'; en = 'Cleaning up outdated versions...'; pl = 'Oczyść przestarzałe wersje...';de = 'Löschen veralteter Versionen...';ro = 'Ștergerea versiunilor mai vechi...';tr = 'Eski sürümlerin temizlenmesi ...'; es_ES = 'Eliminando las versiones obsoletas...'");
EndFunction

&AtServer
Function SerachForObsoleteVersions()
	
	ExecutionParameters = TimeConsumingOperations.BackgroundExecutionParameters(UUID);
	ExecutionParameters.BackgroundJobDescription = NStr("ru = 'Поиск устаревших версий объектов'; en = 'Search for outdated versions'; pl = 'Wyszukaj przestarzałe wersje obiektów';de = 'Suche nach veralteten Versionen von Objekten';ro = 'Căutarea versiunilor vechi ale obiectelor';tr = 'Nesnelerin eski sürümlerini ara ...'; es_ES = 'Buscar las versiones antiguas de los objetos'");
	
	TimeConsumingOperation = TimeConsumingOperations.ExecuteInBackground("ObjectsVersioning.InfoOnOutdatedVersionsOnBackground", New Structure, ExecutionParameters);
	CurrentBackgroundJob = "Calculation";
	BackgroundJobID = TimeConsumingOperation.JobID;
	ResultAddress = TimeConsumingOperation.ResultAddress;
	
	Return TimeConsumingOperation;
EndFunction

&AtClient
Procedure OutputObsoleteVersionsInfo()
	
	ObsoleteVersionsInformation = GetFromTempStorage(ResultAddress);
	If ObsoleteVersionsInformation = Undefined Then
		Return;
	EndIf;
	
	Items.Clear.Visible = ObsoleteVersionsInformation.DataSize > 0;
	If ObsoleteVersionsInformation.DataSize > 0 Then
		Items.ObsoleteVersionsInformation.Title = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Всего устаревших версий: %1 (%2)'; en = 'Total outdated versions: %1 (%2)'; pl = 'Łącznie przestarzałych wersji: %1 (%2)';de = 'Total veraltete Versionen: %1 (%2)';ro = 'Numărul total depășit: %1 (%2)';tr = 'Toplam eski sürümler:%1 (%2)'; es_ES = 'Total de versiones obsoletas: %1 (%2)'"),
			ObsoleteVersionsInformation.VersionsCount,
			ObsoleteVersionsInformation.DataSizeString);
	Else
		Items.ObsoleteVersionsInformation.Title = NStr("ru = 'Всего устаревших версий: нет'; en = 'Total outdated versions: none'; pl = 'Wszystkie przestarzałe wersje: brak';de = 'Alle veralteten Versionen: nein';ro = 'În total versiuni vechi: lipsesc';tr = 'Tüm eski sürümler: hayır'; es_ES = 'Todas las versiones obsoletas: no hay'");
	EndIf;
	
EndProcedure

&AtServer
Procedure FillChoiceLists()
	
	SelectionListCatalogs = New ValueList;
	SelectionListCatalogs.Add(Enums.ObjectsVersioningOptions.VersionizeOnWrite);
	SelectionListCatalogs.Add(Enums.ObjectsVersioningOptions.DontVersionize);
	
	SelectionListDocuments = New ValueList;
	SelectionListDocuments.Add(Enums.ObjectsVersioningOptions.VersionizeOnWrite);
	SelectionListDocuments.Add(Enums.ObjectsVersioningOptions.VersionizeOnPost);
	SelectionListDocuments.Add(Enums.ObjectsVersioningOptions.DontVersionize);
	
	SelectionListBusinessProcesses = New ValueList;
	SelectionListBusinessProcesses.Add(Enums.ObjectsVersioningOptions.VersionizeOnWrite);
	SelectionListBusinessProcesses.Add(Enums.ObjectsVersioningOptions.VersionizeOnStart);
	SelectionListBusinessProcesses.Add(Enums.ObjectsVersioningOptions.DontVersionize);
	
EndProcedure

&AtServer
Function AutomaticClearingEnabled()
	Return GetScheduledJobParameter("Use", False);
EndFunction

#EndRegion
