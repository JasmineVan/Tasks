///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Variables

&AtClient
Var ResultAddress, StoredDataAddress, ProgressUpdateJobID, AccessUpdateErrorText;

#EndRegion


#Region EventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	SetConditionalAppearance();
	
	URL = "e1cib/app/InformationRegister.DataAccessKeysUpdate.Form.AccessUpdateAtRecordLevel";
	
	ProgressUpdatePeriod = 3;
	ProgressAutoUpdate = Not Parameters.DisableProgressBarAutoRefresh;
	ShowItemsCount = True;
	ShowAccessKeysCount = True;
	
	ShowProcessingDelay = True;
	SortFields.Add("ListProcessingDelay", "Asc");
	MaxDate = AccessManagementInternal.MaxDate();
	SetSortingPicture(Items.ListProcessingDelayLists, False);
	
	If Parameters.ShowProgressPerLists Then
		Items.BriefDetailed.Show();
	EndIf;
	
	AccessUpdateThreadsCount = Constants.AccessUpdateThreadsCount.Get();
	If AccessUpdateThreadsCount = 0 Then
		AccessUpdateThreadsCount = 1;
	EndIf;
	Items.NumberOfAccessUpdateThreads1.ToolTip =
		Metadata.Constants.AccessUpdateThreadsCount.Tooltip;
	Items.NumberOfAccessUpdateStreams2.ToolTip =
		Metadata.Constants.AccessUpdateThreadsCount.Tooltip;
	
	If Common.FileInfobase()
	 Or Common.DataSeparationEnabled() Then
		
		Items.NumberOfAccessUpdateThreads1Group.Visible = False;
		Items.NumberOfAccessUpdateStreams2Group.Visible = False;
	EndIf;
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	UpdateAccessUpdateThreadsCountGroupTitle();
	
	OnReopen();
	
EndProcedure

&AtClient
Procedure OnReopen()
	
	UpdateAccessUpdateJobState();
	UpdateAccessUpdateJobStateInThreeSeconds();
	
	StartProgressUpdate(True);
	
EndProcedure

&AtClient
Procedure OnClose(Exit)
	
	If Exit Then
		Return;
	EndIf;
	
	If ValueIsFilled(ProgressUpdateJobID) Then
		CancelProgressUpdateAtServer(ProgressUpdateJobID);
	EndIf;
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If EventName = "Write_UpdateDataAccessKeys"
	 Or EventName = "Write_UpdateUserAccessKeys" Then
		
		StartProgressUpdate(True);
	EndIf;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure AccessUpdateThreadsOnChangeCount(Item)
	
	If AccessUpdateThreadsCount = 0 Then
		AccessUpdateThreadsCount = 1;
	EndIf;
	
	SetAccessUpdateThreadsCountAtServer(AccessUpdateThreadsCount);
	
	UpdateAccessUpdateThreadsCountGroupTitle();
	
EndProcedure

&AtClient
Procedure AccessUpdateThreadsCountChangeEditingText(Item, Text, StandardProcessing)
	
	StandardProcessing = False;
	If ValueIsFilled(Text) Then
		AccessUpdateThreadsCount = Number(Text);
	Else
		AccessUpdateThreadsCount = 1;
	EndIf;
	
	AccessUpdateThreadsOnChangeCount(Item);
	
EndProcedure

&AtClient
Procedure LastAccessUpdateCompletionURLProcessing(Item, FormattedStringURL, StandardProcessing)
	
	StandardProcessing = False;
	
	If FormattedStringURL = "ShowErrorText" Then
	#If MobileClient Then
		ShowMessageBox(, AccessUpdateErrorText);
	#Else
		TextDocument = New TextDocument;
		TextDocument.SetText(AccessUpdateErrorText);
		TextDocument.Show(NStr("ru = 'Ошибка обновления доступа'; en = 'Access update error'; pl = 'Błąd aktualizacji dostępu';de = 'Zugriffsaktualisierung fehlgeschlagen';ro = 'Eroare de actualizare a accesului';tr = 'Erişim güncellemesi başarısız oldu'; es_ES = 'Error de actualizar el acceso'"));
	#EndIf
	EndIf;
	
EndProcedure

&AtClient
Procedure ProgressAutoupdateOnChange(Item)
	
	StartProgressUpdate();
	
EndProcedure

&AtClient
Procedure CalculateByDataCountOnChange(Item)
	
	UpdateDisplaySettingsVisibility();
	
	IsRepeatedProgressUpdate = False;
	StartProgressUpdate(True);
	
EndProcedure

&AtClient
Procedure ShowItemsCountOnChange(Item)
	
	Items.ListsItemsCount.Visible             = ShowItemsCount;
	Items.ListsProcessedItemsCount.Visible = ShowItemsCount;
	
EndProcedure

&AtClient
Procedure ShowAccessKeysCountOnChange(Item)
	
	Items.ListsAccessKeysCount.Visible             = ShowAccessKeysCount;
	Items.ListsProcessedAccessKeysCount.Visible = ShowAccessKeysCount;
	
EndProcedure

&AtClient
Procedure ShowProcessingDelayOnChange(Item)
	
	Items.ListProcessingDelayLists.Visible = ShowProcessingDelay;
	
EndProcedure

&AtClient
Procedure ShowTableNameOnChange(Item)
	
	Items.ListsTableName.Visible = ShowTableName;
	
EndProcedure

&AtClient
Procedure ShowProcessedListsOnChange(Item)
	
	StartProgressUpdate(True);
	
EndProcedure

#EndRegion

#Region ItemsEventHandlersTablesFormsLists

&AtClient
Procedure ListsOnActivateString(Item)
	
	AttachIdleHandler("UpdateDisplaySettingsVisibility", 0.1, True);
	
EndProcedure

#EndRegion

#Region FormCommandHandlers

&AtClient
Procedure StartAccessUpdateImmediately(Command)
	
	AttachIdleHandler("StartAccessUpdateNowWaitHandler", 0.1, True);
	Items.StartAccessUpdateImmediately.Enabled = False;
	UpdateAccessUpdateJobStateInThreeSeconds();
	
EndProcedure

&AtClient
Procedure EnableAccessUpdate(Command)
	
	EnableAccessUpdateAtServer();
	
	Items.AccessUpdateProhibited.Visible = False;
	Items.ScheduledJobDisabled.Visible = False;
	
	StartProgressUpdate(True);
	
EndProcedure

&AtClient
Procedure StopAndProhibitAccessUpdate(Command)
	
	AttachIdleHandler("StopAndProhibitAccessUpdateWaitHandler", 0.1, True);
	Items.StopAndProhibitAccessUpdate.Enabled = False;
	UpdateAccessUpdateJobStateInThreeSeconds();
	
EndProcedure

&AtClient
Procedure RefreshProgressBar(Command)
	
	StartProgressUpdate(True);
	
EndProcedure

&AtClient
Procedure CancelProgressUpdate(Command)
	
	If ValueIsFilled(ProgressUpdateJobID) Then
		CancelProgressUpdateAtServer(ProgressUpdateJobID);
		If ProgressAutoUpdate Then
			ProgressAutoUpdate = False;
			Note = NStr("ru = 'Автообновление прогресса отключено'; en = 'Progress autoupdate disabled'; pl = 'Automatyczna aktualizacja postępu wyłączona';de = 'Automatische Aktualisierung des Fortschritts deaktiviert';ro = 'Actualizarea automată a progresului este dezactivată';tr = 'Otomatik ilerleme güncellemesi devre dışı bırakıldı'; es_ES = 'Autoactualización del progreso desactivada'");
		Else
			Note = "";
		EndIf;
		ShowUserNotification(NStr("ru = 'Обновление прогресса отменено'; en = 'Progress update canceled'; pl = 'Aktualizacja postępu anulowana';de = 'Aktualisierung des Fortschritts abgebrochen';ro = 'Actualizarea progresului este revocată';tr = 'İlerlemenin güncellenmesi iptal edildi'; es_ES = 'Actualización de progreso cancelada'"),,
			Note);
	EndIf;
	
	Items.ProgressBarRefresh.CurrentPage = Items.ProgressBarRefreshCompleted;
	Items.CancelProgressRefresh.Enabled = False;
	
EndProcedure

&AtClient
Procedure ManualControl(Command)
	
	OpenForm("InformationRegister.DataAccessKeysUpdate.Form.AccessUpdateManualControl");
	
EndProcedure

&AtClient
Procedure SortListAsc(Command)
	
	SortList();
	
EndProcedure

&AtClient
Procedure SortListDesc(Command)
	
	SortList(True);
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SetConditionalAppearance()
	
	ConditionalAppearance.Items.Clear();
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ListProcessingDelayLists.Name);
	
	FilterGroup = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
	
	ItemFilter = FilterGroup.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Lists.ListProcessingDelay");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = 999999;
	
	ItemFilter = FilterGroup.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Lists.ItemsProcessed");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = 100;
	
	ItemFilter = FilterGroup.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Lists.AccessKeysProcessed");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = 100;
	
	Item.Appearance.SetParameterValue("Text", "--- ---");
	
EndProcedure

&AtServerNoContext
Procedure SetAccessUpdateThreadsCountAtServer(Val Count)
	
	If Constants.AccessUpdateThreadsCount.Get() <> Count Then
		Constants.AccessUpdateThreadsCount.Set(Count);
	EndIf;
	
EndProcedure

&AtClient
Procedure UpdateAccessUpdateThreadsCountGroupTitle()
	
	Items.NumberOfAccessUpdateThreads1Group.Title =
		Format(AccessUpdateThreadsCount, "NG=") + " "
			+ UsersInternalClientServer.IntegerSubject(AccessUpdateThreadsCount,
				"", NStr("ru = 'поток,потока,потоков,,,,,,0'; en = 'thread,threads,,,,,,,0'; pl = 'strumień,strumienia,strumieni,,,,,,0';de = 'Stream,Streams,Stream,,,,,0';ro = 'flux,fluxuri,fluxuri,,,,,,0';tr = 'akış, akış, akış ,,,,,, 0'; es_ES = 'flujo,del flujo,de los flujos,,,,,,0'"));
	
	Items.NumberOfAccessUpdateStreams2Group.Title =
		Items.NumberOfAccessUpdateThreads1Group.Title;
	
EndProcedure

&AtClient
Procedure UpdateAccessUpdateJobStateInThreeSeconds()
	
	DetachIdleHandler("UpdateAccessUpdateJobStateIdleHandler");
	AttachIdleHandler("UpdateAccessUpdateJobStateIdleHandler", 3.5);
	
EndProcedure

&AtClient
Procedure UpdateAccessUpdateJobStateIdleHandler()
	
	UpdateAccessUpdateJobState();
	
EndProcedure

&AtClient
Procedure UpdateAccessUpdateJobState(State = Undefined)
	
	UpdateDisplaySettingsVisibility();
	
	If State = Undefined Then
		State = AccessUpdateJobState();
	EndIf;
	
	Universal = State.LimitAccessAtRecordLevelUniversally;
	Items.WarningUniversalRestrictionDisabledGroup.Visible = Not Universal;
	Items.AllowAccessUpdate.Enabled  = Universal;
	Items.EnableScheduledJob.Enabled = Universal;
	
	Items.InitialAccessUpdateInProgressWarningGroup.Visible =
		Universal AND Not State.LimitAccessAtRecordLevelUniversallyEnabled;
	
	Items.AccessUpdateProhibited.Visible = State.AccessUpdateProhibited;
	Items.ScheduledJobDisabled.Visible = Not State.AccessUpdateProhibited
		AND ScheduledJobDisabled AND Not State.AccessUpdateInProgress;
	
	AccessUpdateErrorText = State.AccessUpdateErrorText;
	
	If ValueIsFilled(State.LastAccessUpdateCompletedAt) Then
		PartsFormat = New Map;
		BoldFont = New Font(Items.LastAccessUpdateCompletedAt.Font,,, True);
		If ValueIsFilled(AccessUpdateErrorText) Then
			If State.UpdateCanceled Then
				If State.LastCompletionToday Then
					Template = NStr("ru = '<1>отменено</1> <2>с ошибкой</2> в %1 через %2'; en = '<1>canceled</1> <2>with error</2> at %1 in %2'; pl = '<1>anulowane</ 1> <2>z błędem</ 2> w %1 przez %2';de = '<1>abgebrochen</1> <2> mit einem Fehler</2> in %1 durch %2';ro = '<1>revocat</1> <2>cu eroare</2> la %1 peste%2';tr = 'akış, akış, akış ,,,,,, %10%2'; es_ES = '<1>cancelado</1> <2>con error</2> en %1 a través de %2'");
				Else
					Template = NStr("ru = '<1>отменено</1> <2>с ошибкой</2> %1 через %2'; en = '<1>canceled</1> <2>with error</2> %1 in %2'; pl = '<1>anulowane</ 1> <2>z błędem</ 2> %1 przez %2';de = '<1>abgebrochen</1> <2> mit einem Fehler</2> %1 durch %2';ro = '<1>revocat</1> <2>cu eroare</2> %1 peste%2';tr = '<1>, </ 1> <2>, </ 2>%1%2 sonrasında bir hatayla iptal edildi'; es_ES = '<1>cancelado</1> <2>con error</2> %1 a través de %2'");
				EndIf;
			Else
				If State.LastCompletionToday Then
					Template = NStr("ru = '<1>завершено</1> <2>с ошибкой</2> в %1 через %2'; en = '<1>completed</1> <2>with error</2> at %1 in %2'; pl = '<1>zakończone</ 1> <2>z błędem</ 2> w %1 przez %2';de = '<1>abgeschlossen</1> <2> mit einem Fehler</2> %1 durch %2';ro = '<1>finalizat</1> <2>cu eroare</2> la %1 peste%2';tr = '<1> </ 1> <2> ile </ 2> içinde bir hatayla %1tamamlandı%2'; es_ES = '<1>terminado</1> <2>con error</2> en %1 a través de %2'");
				Else
					Template = NStr("ru = '<1>завершено</1> <2>с ошибкой</2> %1 через %2'; en = '<1>completed</1> <2>with error</2> %1 in %2'; pl = '<1>zakończone</ 1> <2>z błędem</ 2> %1 przez %2';de = '<1>abgeschlossen</1> <2> mit einem Fehler</2> %1 durch %2';ro = '<1>finalizat</1> <2>cu eroare</2> %1 peste%2';tr = '<1> </ 1> <2> ile </ 2> arasında bir hatayla %1tamamlandı%2'; es_ES = '<1>terminado</1> <2>con error</2> %1 a través de %2'");
				EndIf;
			EndIf;
			PartsFormat.Insert(1, New Structure("Font, TextColor", BoldFont, New Color(255, 0, 0)));
			PartsFormat.Insert(2, New Structure("Ref", "ShowErrorText"));
		Else
			If State.UpdateCanceled Then
				If State.LastCompletionToday Then
					Template = NStr("ru = 'отменено в %1 через %2'; en = 'canceled at %1 in %2'; pl = 'anulowane w %1 przez %2';de = 'abgebrochen in %1 durch %2';ro = 'revocat la %1 peste %2';tr = 'üzerinden iptal %1edildi%2'; es_ES = 'cancelado en %1 a través de %2'")
				Else
					Template = NStr("ru = 'отменено %1 через %2'; en = 'canceled %1 in %2'; pl = 'anulowane %1 przez %2';de = 'abgebrochen %1 durch %2';ro = 'revocat %1 peste %2';tr = 'üzerinden iptal %1edildi%2'; es_ES = 'cancelado %1 a través de %2'")
				EndIf;
			Else
				If State.LastCompletionToday Then
					Template = NStr("ru = 'завершено в %1 за %2'; en = 'completed at %1 in %2'; pl = 'zakończono w %1 za %2';de = 'abgeschlossen in %1 durch %2';ro = 'finalizat la %1 timp de %2';tr = 'başına%1 tamamlandı%2'; es_ES = 'terminado a %1 en %2'")
				Else
					Template = NStr("ru = 'завершено %1 за %2'; en = 'completed %1 in %2'; pl = 'zakończono %1 za %2';de = 'abgeschlossen %1 durch %2';ro = 'finalizat %1 timp de %2';tr = 'için%1 tamamlandı%2'; es_ES = 'terminado %1 en %2'")
				EndIf;
			EndIf;
		EndIf;
		If State.LastCompletionToday Then
			Template = StrReplace(Template, "%1", "<3>%1</3>");
			PartsFormat.Insert(3, New Structure("Font", BoldFont));
			
			LastCompletion = StringFunctionsClientServer.SubstituteParametersToString(Template,
				Format(State.LastAccessUpdateCompletedAt, "DLF=T"),
				State.LastCompletionDuration);
		Else
			LastCompletion = StringFunctionsClientServer.SubstituteParametersToString(Template,
				Format(State.LastAccessUpdateCompletedAt, "DLF=DT"),
				State.LastCompletionDuration);
		EndIf;
		LastCompletion = StringWithFormattedParts("(" + LastCompletion + ")", PartsFormat, 3);
	Else
		LastCompletion = "(" + ?(State.AccessUpdateInProgress,
			NStr("ru = 'не завершалось'; en = 'have not been completed'; pl = 'nie zostało zakończone';de = 'nicht abgeschlossen';ro = 'nu a fost finalizată';tr = 'bitmedi'; es_ES = 'no terminaba'"), NStr("ru = 'не запускалось'; en = 'have not been started'; pl = 'nie zostało uruchamiane';de = 'nicht angefangen';ro = 'nu a fost lansată';tr = 'başlamadı'; es_ES = 'no lanzaba'")) + ")";
	EndIf;
	Items.LastAccessUpdateCompletedAt.Title = LastCompletion;
	
	JobExecutionCompleted = ValueIsFilled(LastAccessUpdateCompletedAt)
		AND ValueIsFilled(State.LastAccessUpdateCompletedAt)
		AND LastAccessUpdateCompletedAt <> State.LastAccessUpdateCompletedAt;
	
	LastAccessUpdateCompletedAt = State.LastAccessUpdateCompletedAt;
	
	Items.AccessUpdateInProgress.Visible   =    State.AccessUpdateInProgress;
	Items.AccessUpdateNotStarted.Visible = Not State.AccessUpdateInProgress;
	
	Items.StopAndProhibitAccessUpdate.Enabled =    State.AccessUpdateInProgress;
	Items.StartAccessUpdateImmediately.Enabled      = Not State.AccessUpdateInProgress AND Universal;
	
	Items.BackgroundJobInProgressPicture.Visible       =    State.BackgroundJobRunning;
	Items.BackgroundJobPendingExecutionPicture.Visible = Not State.BackgroundJobRunning;
	
	If Not State.AccessUpdateInProgress Then
		Items.BackgroundJobRunTime1.Title = "";
		Items.BackgroundJobRunTime2.Title = "";
		If JobExecutionCompleted AND Not ProgressAutoUpdate Then
			StartProgressUpdate(True);
		EndIf;
		Return;
	EndIf;
	
	TitleText = StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = 'Выполняется %1'; en = 'In progress %1'; pl = 'W trakcie wykonywania %1';de = 'Ausgeführt %1';ro = 'Se execută %1';tr = 'Yürütülüyor %1'; es_ES = 'Se está ejecutando %1'"),
		ExecutionTimeAsString(State.RunningInSeconds));
	
	Items.BackgroundJobRunTime1.Title = TitleText;
	Items.BackgroundJobRunTime2.Title = TitleText;
	
	FirstJobVisibility = Items.BackgroundJobRunTime1.Visible;
	FirstJobVisibility = Not FirstJobVisibility;
	
	Items.BackgroundJobRunTime1.Visible =    FirstJobVisibility;
	Items.BackgroundJobRunTime2.Visible = Not FirstJobVisibility;
	
EndProcedure

&AtClientAtServerNoContext
Function ExecutionTimeAsString(TimeInSeconds)
	
	MinutesTotal = Int(TimeInSeconds / 60);
	Seconds = TimeInSeconds - MinutesTotal * 60;
	HoursTotal = Int(MinutesTotal / 60);
	Minutes = MinutesTotal - HoursTotal * 60;
	
	If HoursTotal > 0 Then
		Template = NStr("ru = '%3 ч %2 мин %1 сек'; en = '%3 h %2 min %1 sec'; pl = '%3 g %2 min %1 sek';de = '%3 h %2 min %1 s';ro = '%3 h %2 min %1 sec';tr = '%3 s %2 dak %1 san'; es_ES = '%3 h %2 min %1 seg'");
		
	ElsIf Minutes > 0 Then
		Template = NStr("ru = '%2 мин %1 сек'; en = '%2 min %1 sec'; pl = '%2 min %1 sek';de = '%2 min %1 s';ro = '%2 min %1 sec';tr = '%2 dak %1 san'; es_ES = '%2 min %1 seg'");
	Else
		Template = NStr("ru = '%1 сек'; en = '%1 sec'; pl = '%1 sek.';de = '%1 s';ro = '%1 sec';tr = 'saniye%1'; es_ES = '%1 segundo'");
	EndIf;
	
	Return StringFunctionsClientServer.SubstituteParametersToString(Template,
		Format(Seconds, "NZ=0; NG="), Format(Minutes, "NZ=0; NG="), Format(HoursTotal, "NG="));
	
EndFunction

&AtServerNoContext
Function AccessUpdateJobState()
	
	LastAccessUpdate = AccessManagementInternal.LastAccessUpdate();
	CurrentDateAtServer = AccessManagementInternal.CurrentDateAtServer();
	
	State = New Structure;
	
	State.Insert("LimitAccessAtRecordLevelUniversally",
		AccessManagementInternal.LimitAccessAtRecordLevelUniversally(True));
	
	State.Insert("LimitAccessAtRecordLevelUniversallyEnabled",
		AccessManagementInternal.LimitAccessAtRecordLevelUniversally(True, True));
	
	State.Insert("LastAccessUpdateCompletedAt",
		LastAccessUpdate.EndDateAtServer);
	
	State.Insert("LastCompletionDuration",
		ExecutionTimeAsString(LastAccessUpdate.LastRunSeconds));
	
	State.Insert("LastCompletionToday",
		IsCurrentDate(CurrentDateAtServer, State.LastAccessUpdateCompletedAt));
	
	State.Insert("UpdateCanceled",
		LastAccessUpdate.UpdateCanceled);
	
	State.Insert("AccessUpdateErrorText",
		LastAccessUpdate.CompletionErrorText);
	
	State.Insert("AccessUpdateProhibited",
		LastAccessUpdate.AccessUpdateProhibited);
	
	State.Insert("RunningInSeconds", 0);
	
	Performer = AccessManagementInternal.AccessUpdateAssignee(LastAccessUpdate);
	
	If Performer = Undefined Then
		State.Insert("AccessUpdateInProgress", False);
		State.Insert("BackgroundJobRunning", False);
		
	ElsIf TypeOf(Performer) = Type("BackgroundJob")
	        AND (Performer.UUID <> LastAccessUpdate.BackgroundJobID
	           Or Common.FileInfobase()
	             AND Not BackgroundJobSessionExists(Performer)) Then
		
		State.Insert("AccessUpdateInProgress", True);
		WaitsForSecondsExecution = CurrentDateAtServer - Performer.Begin;
		WaitsForSecondsExecution = ?(WaitsForSecondsExecution < 0, 0, WaitsForSecondsExecution);
		State.Insert("BackgroundJobRunning", WaitsForSecondsExecution < 2);
	Else
		State.Insert("AccessUpdateInProgress", True);
		State.Insert("BackgroundJobRunning", True);
		RunningInSeconds = CurrentDateAtServer - LastAccessUpdate.StartDateAtServer;
		State.Insert("RunningInSeconds", ?(RunningInSeconds < 0, 0, RunningInSeconds));
	EndIf;
	
	Return State;
	
EndFunction

&AtServerNoContext
Function BackgroundJobSessionExists(BackgroundJob)
	
	Sessions = GetInfoBaseSessions();
	For Each Session In Sessions Do
		If Session.ApplicationName <> "BackgroundJob" Then
			Continue;
		EndIf;
		SessionBackgroundJob = Session.GetBackgroundJob();
		If SessionBackgroundJob = Undefined Then
			Continue;
		EndIf;
		If SessionBackgroundJob.UUID = BackgroundJob.UUID Then
			Return True;
		EndIf;
	EndDo;
	
	Return False;
	
EndFunction

&AtServerNoContext
Function IsCurrentDate(CurrentDate, Date)
	
	Return CurrentDate < Date + 12 * 60 * 6;
	
EndFunction

&AtClient
Procedure StartAccessUpdateNowWaitHandler()
	
	AccessUpdateJobState = Undefined;
	
	WarningText = StartAccessUpdateNowAtServer(AccessUpdateJobState);
	
	If ValueIsFilled(WarningText) Then
		ShowMessageBox(, WarningText);
		Return;
	EndIf;
	
	UpdateAccessUpdateJobState(AccessUpdateJobState);
	
EndProcedure

&AtServerNoContext
Function StartAccessUpdateNowAtServer(AccessUpdateJobState)
	
	Result = AccessManagementInternal.StartAccessUpdateAtRecordLevel(True);
	
	If Result.AlreadyRunning Then
		WarningText = Result.WarningText;
	Else
		WarningText = "";
	EndIf;
	
	AccessUpdateJobState = AccessUpdateJobState();
	
	Return WarningText;
	
EndFunction

&AtClient
Procedure StartProgressUpdate(ManualStart = False)
	
	If ManualStart AND ValueIsFilled(ProgressUpdateJobID) Then
		CancelProgressUpdateAtServer(ProgressUpdateJobID);
		
	ElsIf Not ProgressAutoUpdate AND Not ManualStart
	 Or Items.ProgressBarRefresh.CurrentPage = Items.ProgressUpdateRunning Then
		
		Return;
	EndIf;
	
	AttachIdleHandler("UpdateProgressIdleHandler", 0.1, True);
	UpdateAccessUpdateJobStateInThreeSeconds();
	
	Items.ProgressBarRefresh.CurrentPage = Items.ProgressUpdateRunning;
	Items.CancelProgressRefresh.Enabled = False;
	Items.RefreshingProgressBarPicture.Visible = True;
	Items.ProgressRefreshPendingPicture.Visible = False;
	
EndProcedure

&AtClient
Procedure StartProgressUpdateIdleHandler()
	
	StartProgressUpdate();
	
EndProcedure

&AtClient
Procedure UpdateProgressIdleHandler()
	
	Context = New Structure;
	Context.Insert("CalculateByDataAmount",  CalculateByDataAmount);
	Context.Insert("ShowProcessedLists",    ShowProcessedLists AND CalculateByDataAmount);
	Context.Insert("IsRepeatedProgressUpdate", IsRepeatedProgressUpdate);
	Context.Insert("UpdatedTotal",                  UpdatedTotal);
	Context.Insert("ProgressUpdatePeriod",       ProgressUpdatePeriod);
	Context.Insert("ProgressAutoUpdate",         ProgressAutoUpdate);
	Context.Insert("AddedRows",               New Array);
	Context.Insert("DeletedRows",                 New Map);
	Context.Insert("ModifiedRows",                New Map);
	
	Try
		Status = StartProgressUpdateAtServer(Context, ResultAddress, StoredDataAddress,
			UUID, ProgressUpdateJobID);
	Except
		Items.CancelProgressRefresh.Enabled = True;
		Raise;
	EndTry;
	Items.CancelProgressRefresh.Enabled = True;
	
	If Status = "Completed" Then
		UpdateProgressAfterReceiveData(Context);
		
	ElsIf Status = "Running" Then
		ProgressUpdateRunning = False;
		AttachIdleHandler("CompleteProgressUpdateIdleHandler", 1, True);
		UpdateAccessUpdateJobStateInThreeSeconds();
		Return;
	EndIf;
	
EndProcedure

&AtClient
Procedure CompleteProgressUpdateIdleHandler()
	
	If Not ValueIsFilled(ProgressUpdateJobID) Then
		Return;
	EndIf;
	
	Context = Undefined;
	JobCompleted = EndProgressUpdateAtServer(Context, ResultAddress,
		StoredDataAddress, ProgressUpdateJobID);
	
	If Not JobCompleted Then
		If Context.ProgressUpdateRunning Then
			ProgressUpdateRunning = True;
		EndIf;
		Items.RefreshingProgressBarPicture.Visible         =    ProgressUpdateRunning;
		Items.ProgressRefreshPendingPicture.Visible = Not ProgressUpdateRunning;
		AttachIdleHandler("CompleteProgressUpdateIdleHandler", 1, True);
		Return;
	EndIf;
	
	UpdateProgressAfterReceiveData(Context);
	
EndProcedure

&AtClient
Procedure UpdateProgressAfterReceiveData(Context)
	
	UpdatedTotal = Context.UpdatedTotal;
	If Context.Property("ProgressUpdatePeriod") Then
		ProgressUpdatePeriod = Context.ProgressUpdatePeriod;
	EndIf;
	If Context.Property("ProgressAutoUpdate") Then
		ProgressAutoUpdate = Context.ProgressAutoUpdate;
	EndIf;
	
	ScheduledJobDisabled = Context.Property("ScheduledJobDisabled");
	
	CurrentMoment = CommonClient.SessionDate();
	UpdateDelay = SortFields[0].Value = "ListProcessingDelay";
	
	Index = Lists.Count() - 1;
	While Index >= 0 Do
		Row = Lists.Get(Index);
		If Context.DeletedRows.Get(Row.List) <> Undefined Then
			Lists.Delete(Index);
		Else
			ChangedRow = Context.ModifiedRows.Get(Row.List);
			If ChangedRow <> Undefined Then
				FillPropertyValues(Row, ChangedRow);
			EndIf;
			If UpdateDelay Then
				UpdateListUpdateDelay(Row, CurrentMoment);
			EndIf;
		EndIf;
		Index = Index - 1;
	EndDo;
	For Each AddedRow In Context.AddedRows Do
		NewString = Lists.Add();
		FillPropertyValues(NewString, AddedRow);
		If UpdateDelay Then
			UpdateListUpdateDelay(NewString, CurrentMoment);
		EndIf;
	EndDo;
	
	If Context.AddedRows.Count() > 0
	 Or SortingWithGoToBeginning()
	   AND Context.ModifiedRows.Count() > 0  Then
		
		SortListByFields();
	EndIf;
	
	If ProgressAutoUpdate Then
		AttachIdleHandler("StartProgressUpdateIdleHandler",
			ProgressUpdatePeriod, True);
	EndIf;
	
	Items.ProgressBarRefresh.CurrentPage = Items.ProgressBarRefreshCompleted;
	IsRepeatedProgressUpdate = True;
	
	UpdateAccessUpdateJobState(Context.AccessUpdateJobState);
	UpdateAccessUpdateJobStateInThreeSeconds();
	
EndProcedure

&AtClient
Procedure UpdateListUpdateDelay(String, CurrentMoment)
	
	Divisor = 5;
	
	If ValueIsFilled(String.LatestUpdate) Then
		String.ListProcessingDelay =
			Int((CurrentMoment - String.LatestUpdate) / Divisor) * Divisor;
		
	ElsIf String.FirstUpdateSchedule < MaxDate Then
		String.ListProcessingDelay =
			Int((CurrentMoment - String.FirstUpdateSchedule) / Divisor) * Divisor;
	Else
		String.ListProcessingDelay = 999999;
	EndIf;
	
EndProcedure

&AtServerNoContext
Function StartProgressUpdateAtServer(Context, ResultAddress, StoredDataAddress,
			FormID, ProgressUpdateJobID)
	
	If ValueIsFilled(StoredDataAddress) Then
		StoredData = GetFromTempStorage(StoredDataAddress);
	Else
		StoredData = New Structure;
		StoredData.Insert("ListsRows",    New Map);
		StoredData.Insert("ListsProperties",  New Map);
		StoredData.Insert("KeysCount", 0);
		StoredData.Insert("LatestUpdateDate", '00010101');
		StoredDataAddress = PutToTempStorage(StoredData, FormID);
	EndIf;
	
	FixedContext = New FixedStructure(Context);
	ProcedureParameters = New Structure(FixedContext);
	
	ResultAddress = PutToTempStorage(Undefined, FormID);
	ProcedureParameters.Insert("StoredData", StoredData);
	
	ExecutionParameters = TimeConsumingOperations.BackgroundExecutionParameters(FormID);
	ExecutionParameters.WaitForCompletion = 0;
	ExecutionParameters.ResultAddress = ResultAddress;
	ExecutionParameters.BackgroundJobDescription =
		NStr("ru = 'Управление доступом: Получение прогресса обновления доступа'; en = 'Access management: Receiving access update progress'; pl = 'Kontrola dostępu: Uzyskiwanie dostępu do postępu aktualizacji';de = 'Zugriffskontrolle: Erreichen des Fortschritts bei der Aktualisierung der Zugriffsrechte';ro = 'Administrarea accesului: Obținerea progresului de actualizare a accesului';tr = 'Erişim yönetimi: Erişim güncelleme ilerlemesini elde etmek'; es_ES = 'Gestión de acceso: Recepción de progreso de actualización de acceso'");
	
	RunResult = TimeConsumingOperations.ExecuteInBackground("AccessManagementInternal.UpdateProgressInBackground",
		ProcedureParameters, ExecutionParameters);
	
	ProgressUpdateJobID = Undefined;
	
	If RunResult.Status = "Completed" Then
		EndProgressUpdateAtServer(Context, ResultAddress,
			StoredDataAddress, Undefined);
		
	ElsIf RunResult.Status = "Running" Then
		ProgressUpdateJobID = RunResult.JobID;
		
	ElsIf RunResult.Status = "Error" Then
		Raise RunResult.DetailedErrorPresentation;
	EndIf;
	
	Return RunResult.Status;
	
EndFunction

&AtServerNoContext
Procedure CancelProgressUpdateAtServer(JobID)
	
	TimeConsumingOperations.CancelJobExecution(JobID);
	JobID = Undefined;
	
EndProcedure

&AtServerNoContext
Function EndProgressUpdateAtServer(Context, Val ResultAddress, Val StoredDataAddress,
			ProgressUpdateJobID)
	
	If ProgressUpdateJobID <> Undefined
	   AND Not TimeConsumingOperations.JobCompleted(ProgressUpdateJobID) Then
		
		Context = New Structure("ProgressUpdateRunning",
			TimeConsumingOperations.ReadProgress(ProgressUpdateJobID) <> Undefined);
		Return False;
	EndIf;
	ProgressUpdateJobID = Undefined;
	
	Context = GetFromTempStorage(ResultAddress);
	PutToTempStorage(Context.StoredData, StoredDataAddress);
	Context.Delete("StoredData");
	
	Context.Insert("AccessUpdateJobState", AccessUpdateJobState());
	
	Return True;
	
EndFunction

&AtClient
Procedure UpdateDisplaySettingsVisibility()
	
	DisplaySettings = CalculateByDataAmount;
	
	If Items.ViewSettings.Visible <> DisplaySettings Then
		Items.ViewSettings.Visible = DisplaySettings;
		
		If DisplaySettings Then
			Items.ListsItemsCount.Visible                 = ShowItemsCount;
			Items.ListsProcessedItemsCount.Visible     = ShowItemsCount;
			Items.ListsAccessKeysCount.Visible             = ShowAccessKeysCount;
			Items.ListsProcessedAccessKeysCount.Visible = ShowAccessKeysCount;
			Items.ListsTableName.Visible                          = ShowTableName;
		Else
			Items.ListsItemsCount.Visible                 = False;
			Items.ListsProcessedItemsCount.Visible     = False;
			Items.ListsAccessKeysCount.Visible             = False;
			Items.ListsProcessedAccessKeysCount.Visible = False;
			Items.ListsTableName.Visible                          = False;
		EndIf;
	EndIf;
	
	Items.ListProcessingDelayLists.Visible = ShowProcessingDelay;
	
EndProcedure

&AtClient
Procedure SortList(Descending = False)
	
	CurrentColumn = Items.Lists.CurrentItem;
	
	If CurrentColumn = Undefined
	 Or Not StrStartsWith(CurrentColumn.Name, "Lists") Then
		
		ShowMessageBox(,
			NStr("ru = 'Выберите колонку для сортировки'; en = 'Select a column to sort'; pl = 'Wybierz kolumnę do sortowania';de = 'Wählen Sie die Spalte aus, die Sie sortieren möchten';ro = 'Selectați coloana pentru sortare';tr = 'Sıralamak için bir sütun seçin'; es_ES = 'Seleccione una columna para ordenar'"));
		Return;
	EndIf;
	
	ClearSortingPicture(Items["Lists" + SortFields[0].Value]);
	
	SortFields.Clear();
	
	Field = Mid(CurrentColumn.Name, StrLen("Lists") + 1);
	SortFields.Add(Field, ?(Descending, "Desc", "Asc"));
	If Field <> "ListPresentation" Then
		SortFields.Add("ListPresentation", "Asc");
	EndIf;
	
	SetSortingPicture(CurrentColumn, Descending);
	
	SortListByFields();
	
	ShowUserNotification(
		?(Descending, NStr("ru = 'Сортировка по убыванию'; en = 'Sort descending'; pl = 'Sortowanie po opadnięciu';de = 'Absteigend sortieren';ro = 'Sortare descendentă';tr = 'Azalarak sırala'; es_ES = 'Clasificar en orden descendente'"),
			NStr("ru = 'Сортировка по возрастанию'; en = 'Sort ascending'; pl = 'Sortowanie za zwiększeniem';de = 'Aufsteigend sortieren';ro = 'Sortare ascendentă';tr = 'Artarak sırala'; es_ES = 'Clasificar en orden ascendente'")),,
		StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Колонка ""%1""'; en = 'Column %1'; pl = 'Kolumna ""%1""';de = 'Spalte ""%1""';ro = 'Coloana ""%1""';tr = '""%1"" Sütunu'; es_ES = 'Columna ""%1""'"),
			StrReplace(CurrentColumn.Title, Chars.LF, " ")));
	
EndProcedure

&AtClientAtServerNoContext
Procedure SetSortingPicture(Item, Descending)
	
	WidthAddition = 3;
	
	If Item.Width > 0 Then
		Item.Width = Item.Width + WidthAddition;
	EndIf;
	Item.HeaderPicture = ?(Descending,
		PictureLib.SortListDesc,
		PictureLib.SortListAsc);
	
EndProcedure

&AtClientAtServerNoContext
Procedure ClearSortingPicture(Item)
	
	WidthAddition = 3;
	
	Item.HeaderPicture = New Picture;
	If Item.Width > WidthAddition Then
		Item.Width = Item.Width - WidthAddition;
	EndIf;
	
EndProcedure

&AtClient
Function SortingWithGoToBeginning()
	
	Return SortFields[0].Value <> "ListPresentation";
	
EndFunction

&AtClient
Procedure SortListByFields(SortFieldIndex = 0, ListRows = Undefined)
	
	If SortFieldIndex >= SortFields.Count() Then
		Return;
	EndIf;
	
	SortField = SortFields[SortFieldIndex].Value;
	If ListRows = Undefined Then
		ListRows = New ValueList;
		If Lists.Count() < 2 Then
			Return;
		EndIf;
		For Each Row In Lists Do
			ListRows.Add(Row,
				PresentationForSort(Row[SortField]));
		EndDo;
	ElsIf ListRows.Count() < 2 Then
		Return;
	Else
		For Each ListItem In ListRows Do
			ListItem.Presentation =
				PresentationForSort(ListItem.Value[SortField]);
		EndDo;
	EndIf;
	
	InitialIndex = Lists.IndexOf(ListRows[0].Value);
	ListRows.SortByPresentation(
		SortDirection[SortFields[SortFieldIndex].Presentation]);
	
	CurrentPresentation = Undefined;
	Substrings = Undefined;
	NewIndex = InitialIndex;
	For Each ListItem In ListRows Do
		CurrentIndex = Lists.IndexOf(ListItem.Value);
		If CurrentIndex <> NewIndex Then
			Lists.Move(CurrentIndex, NewIndex - CurrentIndex);
		EndIf;
		If CurrentPresentation <> ListItem.Presentation Then
			If Substrings <> Undefined Then
				SortListByFields(SortFieldIndex + 1, Substrings);
			EndIf;
			Substrings = New ValueList;
			CurrentPresentation = ListItem.Presentation;
		EndIf;
		Substrings.Add(ListItem.Value);
		NewIndex = NewIndex + 1;
	EndDo;
	
	If Substrings <> Undefined Then
		SortListByFields(SortFieldIndex + 1, Substrings);
	EndIf;
	
	If SortFieldIndex = 0
	   AND SortingWithGoToBeginning()
	   AND Lists.Count() > 0 Then
		
		Items.Lists.CurrentRow = Lists[0].GetID();
	EndIf;
	
EndProcedure

&AtClient
Function PresentationForSort(Value)
	
	Return Format(Value, "ND=15; NFD=4; NZ=00000000000,0000; NLZ=; NG=");
	
EndFunction

&AtServerNoContext
Procedure EnableAccessUpdateAtServer()
	
	AccessManagementInternal.SetAccessUpdateProhibition(False);
	AccessManagementInternal.SetAccessUpdate(True);
	
EndProcedure

&AtClient
Procedure StopAndProhibitAccessUpdateWaitHandler()
	
	StopAndProhibitAccessUpdateAtServer();
	
	Items.AccessUpdateProhibited.Visible = True;
	Items.ScheduledJobDisabled.Visible = False;
	
	StartProgressUpdate(True);
	
EndProcedure

&AtServerNoContext
Procedure StopAndProhibitAccessUpdateAtServer()
	
	AccessManagementInternal.SetAccessUpdate(False);
	AccessManagementInternal.CancelAccessUpdateAtRecordLevel();
	
EndProcedure

&AtClientAtServerNoContext
Function StringWithFormattedParts(Template, PartsFormat, PartsToFormatCount)
	
	Parts = New Array;
	
	For PartToFormatNumber = 1 To PartsToFormatCount Do
		SeparatorStart = "<"  + PartToFormatNumber + ">";
		SeparatorEnd  = "</" + PartToFormatNumber + ">";
		If StrOccurrenceCount(Template, SeparatorStart) <> 1
		 Or StrOccurrenceCount(Template, SeparatorEnd) <> 1 Then
			Template = StrReplace(Template, SeparatorStart, "");
			Template = StrReplace(Template, SeparatorEnd, "");
			Continue;
		EndIf;
	Position = StrFind(Template, SeparatorStart);
		If Position > 1 Then
			String = Left(Template, Position - 1);
			Parts.Add(StringWithFormattedParts(String, PartsFormat, PartsToFormatCount));
		EndIf;
		Template = Mid(Template, Position + StrLen(SeparatorStart));
		Position = StrFind(Template, SeparatorEnd);
		StringToFormat = Left(Template, Position - 1);
		If PartsFormat.Get(PartToFormatNumber) <> Undefined Then
			FormatParameters = New Structure("Font, TextColor, BackColor, Ref");
			FillPropertyValues(FormatParameters, PartsFormat.Get(PartToFormatNumber));
			StringToFormat = New FormattedString(StringToFormat,
				FormatParameters.Font, FormatParameters.TextColor, FormatParameters.BackColor, FormatParameters.Ref);
		EndIf;
		Parts.Add(StringToFormat);
		Template = Mid(Template, Position + StrLen(SeparatorEnd));
		If Template = "" Then
			Break;
		EndIf;
	EndDo;
	
	If Template <> "" Then
		Parts.Add(Template);
	EndIf;
	
	Return New FormattedString(Parts);
	
EndFunction

#EndRegion

