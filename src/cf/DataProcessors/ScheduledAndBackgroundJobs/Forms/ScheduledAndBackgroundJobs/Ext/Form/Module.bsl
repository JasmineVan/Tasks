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
	
	If NOT Users.IsFullUser(, True) Then
		Raise NStr("ru = 'Недостаточно прав доступа.
		                             |
		                             |Работа с регламентными и фоновыми заданиями
		                             |выполняется только администраторами.'; 
		                             |en = 'Insufficient access rights.
		                             |
		                             |Only administrators can perform operations with scheduled and
		                             |background jobs.'; 
		                             |pl = 'Nie masz wystarczających uprawnień dostępu.
		                             |
		                             |Prace z planowymi i zadaniami w tle
		                             |wykonywane są tylko przez administratorów.';
		                             |de = 'Nicht genügend Zugriffsrechte.
		                             |
		                             |Die Arbeit mit Routine- und Hintergrundaufgaben 
		                             |wird nur von Administratoren durchgeführt.';
		                             |ro = 'Drepturi de acces insuficiente.
		                             |
		                             |Lucrul cu sarcinile reglementare și de fundal
		                             |se execută numai de administratori.';
		                             |tr = 'Yetersiz erişim hakları. 
		                             |
		                             |Zamanlanmış ve 
		                             |arka plan görevleriyle çalışma yalnızca yöneticiler tarafından yürütülür.'; 
		                             |es_ES = 'Insuficientes derechos de acceso.
		                             |
		                             |Trabajo con tareas programadas y de fondo
		                             |se ejecuta solo por administradores.'");
	EndIf;
	
	BlankID = String(CommonClientServer.BlankUUID());
	TextUndefined = ScheduledJobsInternal.TextUndefined();
	IsSubordinateDIBNode = Common.IsSubordinateDIBNode();
	
	If Common.DebugMode() Then
		Items.ScheduledJobsTableContextMenuExecuteNotInBackground.Visible = True;
		Items.ScheduledJobsTableExecuteInForeground.Visible = True;
	EndIf;
	
	Items.ExternalResourcesOperationsLockGroup.Visible = ScheduledJobsServer.OperationsWithExternalResourcesLocked();
	
	If Common.IsMobileClient() Then
		
		Items.ScheduledJobsTableRefreshData.OnlyInAllActions = True;
		Items.ScheduledJobsTableSetSchedule.OnlyInAllActions = True;
		Items.HeaderGroup.ShowTitle = True;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	If NOT SettingsImported Then
		FillFormSettings(New Map);
	EndIf;
	
	ImportScheduledJobs();
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If EventName = "Write_ScheduledJobs" Then
		
		If ValueIsFilled(Parameter) Then
			ImportScheduledJobs(Parameter, True);
		Else
			AttachIdleHandler("ScheduledJobsDeferredUpdate", 0.1, True);
		EndIf;
	ElsIf EventName = "OperationsWithExternalResourcesAllowed" Then
		Items.ExternalResourcesOperationsLockGroup.Visible = False;
	ElsIf EventName = "Write_ConstantsSet" Then
		AttachIdleHandler("ScheduledJobsDeferredUpdate", 0.1, True);
	EndIf;
	
EndProcedure

&AtServer
Procedure OnLoadDataFromSettingsAtServer(Settings)
	
	FillFormSettings(Settings);
	
	SettingsImported = True;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure JobsOnChangePage(Item, CurrentPage)
	
	If CurrentPage = Items.BackgroundJobs AND Not BackgroundJobsPageOpened Then
		BackgroundJobsPageOpened = True;
		UpdateBackgroundJobsTableAtClient();
	EndIf;
	
EndProcedure

&AtClient
Procedure FilterKindByPeriodOnChange(Item)
	
	CurrentSessionDate = CurrentSessionDateAtServer();
	
	Items.FilterPeriodFrom.ReadOnly  = NOT (FilterKindByPeriod = 4);
	Items.FilterPeriodTo.ReadOnly = NOT (FilterKindByPeriod = 4);
	
	If FilterKindByPeriod = 0 Then
		FilterPeriodFrom  = '00010101';
		FilterPeriodTo = '00010101';
		Items.SettingArbitraryPeriod.Visible = False;
	ElsIf FilterKindByPeriod = 4 Then
		FilterPeriodFrom  = BegOfDay(CurrentSessionDate);
		FilterPeriodTo = FilterPeriodFrom;
		Items.SettingArbitraryPeriod.Visible = True;
	Else
		RefreshAutomaticPeriod(ThisObject, CurrentSessionDate);
		Items.SettingArbitraryPeriod.Visible = False;
	EndIf;
	
EndProcedure

&AtClient
Procedure FilterByScheduledJobOnChange(Item)

	Items.ScheduledJobForFilter.Enabled = FilterByScheduledJob;
	
EndProcedure

&AtClient
Procedure ScheduledJobForFilterClear(Item, StandardProcessing)
	
	StandardProcessing = False;
	ScheduledJobForFilterID = BlankID;
	
EndProcedure

&AtClient
Procedure LockOfOperationsWithExternalResourcesURLProcessingNote(Item, FormattedStringURL, StandardProcessing)
	StandardProcessing = False;
	Items.ExternalResourcesOperationsLockGroup.Visible = False;
	LockOfOperationsWithExternalResourcesURLProcessingAtServerNote();
	Notify("OperationsWithExternalResourcesAllowed");
EndProcedure

#EndRegion

#Region BackgroundJobTableFormTableItemEventHandlers

&AtClient
Procedure BackgroundJobTableChoice(Item, RowSelected, Field, StandardProcessing)
	
	OpenBackgroundJob();
	
EndProcedure

#EndRegion

#Region ScheduledJobTableFormTableItemEventHandlers

&AtClient
Procedure ScheduledJobTableChoice(Item, RowSelected, Field, StandardProcessing)
	
	If Field = "Predefined"
	 OR Field = "Use" Then
		
		AddCopyEditScheduledJob("Change");
	EndIf;
	
EndProcedure

&AtClient
Procedure ScheduledJobTableBeforeAddRow(Item, Cancel, Clone, Parent, Folder)
	
	Cancel = True;
	
	AddCopyEditScheduledJob(?(Clone, "Copy", "Add"));
	
EndProcedure

&AtClient
Procedure ScheduledJobTableBeforeChange(Item, Cancel)
	
	Cancel = True;
	
	AddCopyEditScheduledJob("Change");
	
EndProcedure

&AtClient
Procedure ScheduledJobTableBeforeDelete(Item, Cancel)
	
	Cancel = True;
	
	If Items.ScheduledJobsTable.SelectedRows.Count() > 1 Then
		ShowMessageBox(, NStr("ru = 'Выберите одно регламентное задание.'; en = 'Select one scheduled job.'; pl = 'Wybierz jedno zaplanowane zadanie.';de = 'Wählen Sie einen geplanten Job aus.';ro = 'Selectați o sarcină reglementară.';tr = 'Zamanlanmış bir görev seçin.'; es_ES = 'Seleccionar una tarea programada.'"));
		
	ElsIf Item.CurrentData.Predefined Then
		ShowMessageBox(, NStr("ru = 'Невозможно удалить предопределенное регламентное задание.'; en = 'Cannot delete a predefined scheduled job.'; pl = 'Nie można usunąć predefiniowanego  zaplanowanego zadania.';de = 'Der vordefinierte geplante Job kann nicht gelöscht werden.';ro = 'Nu poate fi ștearsă sarcina reglementară predefinită.';tr = 'Ön tanımlı planlanmış görev silinemiyor.'; es_ES = 'No se puede borrar la tarea programada predefinida.'") );
	Else
		ShowQueryBox(
			New NotifyDescription("ScheduledJobsTableBeforeDeleteEnd", ThisObject),
			NStr("ru = 'Удалить регламентное задание?'; en = 'Do you want to delete the scheduled job?'; pl = 'Usunąć zaplanowane zadanie?';de = 'Entfernen Sie den geplanten Job?';ro = 'Ștergeți sarcina reglementară?';tr = 'Zamanlanmış görev kaldırılsın mı?'; es_ES = '¿Eliminar la tarea programada?'"), QuestionDialogMode.YesNo);
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandHandlers

&AtClient
Procedure UpdateScheduledJobs(Command)
	
	If Items.Jobs.CurrentPage = Items.BackgroundJobs Then
		UpdateBackgroundJobsTableAtClient();
	Else
		ImportScheduledJobs();
	EndIf;
	
EndProcedure

&AtClient
Procedure ExecuteScheduledJobManually(Command)

	If Items.ScheduledJobsTable.CurrentData = Undefined Then
		ShowMessageBox(, NStr("ru = 'Выберите регламентное задание.'; en = 'Select a scheduled job.'; pl = 'Wybierz jedno zaplanowane zadanie.';de = 'Wählen Sie einen geplanten Job aus.';ro = 'Selectați un program de lucru.';tr = 'Zamanlanmış bir görev seçin.'; es_ES = 'Seleccionar una tarea programada.'"));
		Return;
	EndIf;
	
	SelectedRows = New Array;
	For each SelectedRow In Items.ScheduledJobsTable.SelectedRows Do
		SelectedRows.Add(SelectedRow);
	EndDo;
	Index = 0;
	
	SelectedJobsCount = SelectedRows.Count();
	ErrorMessageArray = New Array;
	
	For each SelectedRow In SelectedRows Do
		CurrentData = ScheduledJobsTable.FindByID(SelectedRow);
		
		If CurrentData.Parameterized AND SelectedJobsCount = 1 Then
			ShowMessageBox(, NStr("ru = 'Выбранное регламентное задание нельзя выполнить вручную.'; en = 'The selected scheduled job cannot be started manually.'; pl = 'Wybrane planowe zadanie nie można wykonać ręcznie.';de = 'Die ausgewählte Routineaufgabe kann nicht manuell ausgeführt werden.';ro = 'Nu puteți executa manual sarcina reglementară selectată.';tr = 'Seçilen zamanlanmış görev manuel olarak yürütülemez.'; es_ES = 'No se puede realizar manualmente la tarea programada seleccionada.'"));
			Return;
		ElsIf CurrentData.Parameterized Then
			Continue;
		EndIf;
		
		ExecutionParameters = ExecuteScheduledJobManuallyAtServer(CurrentData.ID);
		If ExecutionParameters.Started Then
			
			ShowUserNotification(
				NStr("ru = 'Запущена процедура регламентного задания'; en = 'Procedure of the scheduled job has been started'; pl = 'Jest uruchomiona procedura zaplanowanego zadania';de = 'Geplanter Job wird gestartet';ro = 'Procedura sarcinii reglementare este lansată';tr = 'Zamanlanmış iş başlatıldı'; es_ES = 'Se ha lanzado un tarea programada'"), ,
				StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = '%1.
					|Процедура запущена в фоновом задании %2'; 
					|en = '%1.
					|The procedure has been started in the %2 background job'; 
					|pl = '%1.
					|Procedura jest uruchamiana w zadaniu działającym w tle %2';
					|de = '%1.
					|Prozedur wird im Hintergrundjob gestartet %2';
					|ro = '%1.
					|Procedura este lansată în sarcina de fundal %2';
					|tr = '%1.
					|Prosedür, arka plan görevinde başlatıldı%2'; 
					|es_ES = '%1.
					|Procedimiento se ha lanzado en la tarea de fondo %2'"),
					CurrentData.Description,
					String(ExecutionParameters.StartedAt)),
				PictureLib.ExecuteScheduledJobManually);
			
			BackgroundJobIDsOnManualExecution.Add(
				ExecutionParameters.BackgroundJobID,
				CurrentData.Description);
			
			AttachIdleHandler(
				"NotifyAboutManualScheduledJobCompletion", 0.1, True);
		ElsIf ExecutionParameters.ProcedureAlreadyExecuting Then
			ErrorMessageArray.Add(
				StringFunctionsClientServer.SubstituteParametersToString(
					NStr("ru = 'Процедура регламентного задания ""%1""
					|  уже выполняется в фоновом задании ""%2"", начатом %3.'; 
					|en = 'Procedure of the ""%1""
					| scheduled job is already running in the ""%2"" background job started %3.'; 
					|pl = 'Procedura planowego zadania ""%1""
					| jest już wykonywane w zadaniu w tle ""%2"", rozpoczętym %3.';
					|de = 'Die Prozedur der Routineaufgabe ""%1""
					| wird bereits in der Hintergrundaufgabe ""%2"" durchgeführt, gestartet %3.';
					|ro = 'Procedura sarcinii reglementare ""%1""
					| deja se execută în sarcina de fundal ""%2"" începută %3.';
					|tr = '""%1""
					|zamanlanmış görevin prosedürü %2 başlayan ""%3"" arkaplan görevinde zaten yürütülüyor.'; 
					|es_ES = 'El procedimiento de la tarea programada ""%1""
					| ya se está realizando en la tarea de fondo ""%2"", empezada %3.'"),
					CurrentData.Description,
					ExecutionParameters.BackgroundJobPresentation,
					String(ExecutionParameters.StartedAt)));
		Else
			Items.ScheduledJobsTable.SelectedRows.Delete(
				Items.ScheduledJobsTable.SelectedRows.Find(SelectedRow));
		EndIf;
		
		Index = Index + 1;
	EndDo;
	
	ErrorsCount = ErrorMessageArray.Count();
	If ErrorsCount > 0 Then
		ErrorTextTitle = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Задания выполнены с ошибками (%1 из %2)'; en = 'Jobs have been completed with errors (%1 of %2)'; pl = 'Zadania są zakończone z błędami (%1 z %2)';de = 'Jobs werden mit Fehlern abgeschlossen (%1 aus %2)';ro = 'Însărcinările sunt executate cu erori (%1 din %2)';tr = 'İşler hatalarla tamamlandı (%1''in %2)'; es_ES = 'Tareas se han finalizado con errores (%1 de %2)'"),
			Format(ErrorsCount, "NG="),
			Format(SelectedRows.Count(), "NG="));
		
		AllErrorsText = New TextDocument;
		AllErrorsText.AddLine(ErrorTextTitle + ":");
		For Each ThisErrorText In ErrorMessageArray Do
			AllErrorsText.AddLine("");
			AllErrorsText.AddLine(ThisErrorText);
		EndDo;
		
		If ErrorsCount > 5 Then
			Buttons = New ValueList;
			Buttons.Add(1, NStr("ru = 'Показать ошибки'; en = 'Show errors'; pl = 'Pokaż błędy';de = 'Fehler anzeigen';ro = 'Arată erori';tr = 'Hataları göster'; es_ES = 'Mostrar los errores'"));
			Buttons.Add(DialogReturnCode.Cancel);
			
			ShowQueryBox(
				New NotifyDescription(
					"ExecuteScheduledJobManuallyEnd", ThisObject, AllErrorsText),
				ErrorTextTitle, Buttons);
		Else
			ShowMessageBox(, TrimAll(AllErrorsText.GetText()));
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure SetUpSchedule(Command)
	
	CurrentData = Items.ScheduledJobsTable.CurrentData;
	
	If CurrentData = Undefined Then
		ShowMessageBox(, NStr("ru = 'Выберите регламентное задание.'; en = 'Select a scheduled job.'; pl = 'Wybierz jedno zaplanowane zadanie.';de = 'Wählen Sie einen geplanten Job aus.';ro = 'Selectați un program de lucru.';tr = 'Zamanlanmış bir görev seçin.'; es_ES = 'Seleccionar una tarea programada.'"));
	
	ElsIf Items.ScheduledJobsTable.SelectedRows.Count() > 1 Then
		ShowMessageBox(, NStr("ru = 'Выберите одно регламентное задание.'; en = 'Select one scheduled job.'; pl = 'Wybierz jedno zaplanowane zadanie.';de = 'Wählen Sie einen geplanten Job aus.';ro = 'Selectați o sarcină reglementară.';tr = 'Zamanlanmış bir görev seçin.'; es_ES = 'Seleccionar una tarea programada.'"));
	Else
		Dialog = New ScheduledJobDialog(
			GetSchedule(CurrentData.ID));
		
		Dialog.Show(New NotifyDescription(
			"OpenScheduleEnd", ThisObject, CurrentData));
	EndIf;
	
EndProcedure

&AtClient
Procedure EnableScheduledJob(Command)
	
	SetScheduledJobUsage(True);
	
EndProcedure

&AtClient
Procedure DisableScheduledJob(Command)
	
	SetScheduledJobUsage(False);
	
EndProcedure

&AtClient
Procedure OpenBackgroundJobAtClient(Command)
	
	OpenBackgroundJob();
	
EndProcedure

&AtClient
Procedure CancelBackgroundJob(Command)
	
	If Items.BackgroundJobsTable.CurrentData = Undefined Then
		ShowMessageBox(, NStr("ru = 'Выберите фоновое задание.'; en = 'Select a background job.'; pl = 'Wybierz zadanie w tle.';de = 'Wählen Sie einen Hintergrundjob aus.';ro = 'Selectați sarcina de fundal.';tr = 'Arkaplan işi seçin.'; es_ES = 'Seleccionar una tarea de fondo.'"));
		Return;
	EndIf;

	CancelBackgroundJobAtServer(Items.BackgroundJobsTable.CurrentData.ID);
	ImportScheduledJobs(, True);
	
	ShowMessageBox(,
		NStr("ru = 'Задание отменено, но состояние отмены будет установлено сервером только через некоторое время,
		           |возможно потребуется обновить данные вручную.'; 
		           |en = 'The job is canceled, but the canceled status will be set by the server only in several seconds,
		           |you might need to update the data manually.'; 
		           |pl = 'Zadanie zostało anulowane, ale status anulowania będzie ustawione przez serwer tylko przez jakiś czas,
		           |być może trzeba będzie zaktualizować dane ręcznie.';
		           |de = 'Die Aufgabe wird abgebrochen, aber der Abbruchstatus wird vom Server erst nach einiger Zeit gesetzt,
		           |möglicherweise müssen Sie die Daten manuell aktualisieren.';
		           |ro = 'Sarcina este revocată, dar statutul de revocare va fi instalat de server numai peste un anumit timp,
		           |posibil să fie necesar să actualizați manual datele.';
		           |tr = 'Görev  iptal edildi, ancak 
		           |iptal durumu sadece birkaç saniye içinde sunucu  tarafından ayarlanacak, verileri manuel olarak güncellemeniz  gerekebilir.'; 
		           |es_ES = 'La tarea se ha cancelado pero el estado de cancelación será instalado solo dentro de un tiempo,
		           |es posible que tendrá que actualizar los datos manualmente.'"));
	
EndProcedure

&AtClient
Procedure ShowAllJobs(Command)
	Value = Items.ScheduledJobsTableShowAllJobs.Check;
	Items.ScheduledJobsTableShowAllJobs.Check = Not Value;
	
	SetDisabledJobsVisibility(Not Value);
EndProcedure

&AtClient
Procedure ExecuteNotInBackground(Command)
	
	If Items.ScheduledJobsTable.CurrentData = Undefined Then
		ShowMessageBox(, NStr("ru = 'Выберите регламентное задание.'; en = 'Select a scheduled job.'; pl = 'Wybierz jedno zaplanowane zadanie.';de = 'Wählen Sie einen geplanten Job aus.';ro = 'Selectați un program de lucru.';tr = 'Zamanlanmış bir görev seçin.'; es_ES = 'Seleccionar una tarea programada.'"));
		Return;
	EndIf;
	
	SelectedRows = New Array;
	For each SelectedRow In Items.ScheduledJobsTable.SelectedRows Do
		SelectedRows.Add(SelectedRow);
	EndDo;
	Index = 0;
	
	For each SelectedRow In SelectedRows Do
		CurrentData = ScheduledJobsTable.FindByID(SelectedRow);
		RunScheduledJobNotInBackground(CurrentData.ID);
		Index = Index + 1;
	EndDo;
	
	ShowUserNotification(
		NStr("ru = 'Выполнена процедура регламентного задания'; en = 'The scheduled job procedure has been completed'; pl = 'Procedura zaplanowanego zadania została wykonana';de = 'Geplante Job-Prozedur wird ausgeführt';ro = 'Procedura sarcinii de fundal este executată';tr = 'Zamanlanmış iş prosedürü gerçekleştirildi'; es_ES = 'Procedimiento de la tarea programada se ha ejecutado'"), ,
		StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = '%1.
			|Процедура выполнена вручную без фонового задания'; 
			|en = '%1.
			|The procedure has been completed manually without a background job'; 
			|pl = '%1.
			|Procedura została wykonana ręcznie, bez zadania w tle';
			|de = '%1.
			|Der Vorgang wird manuell ohne Hintergrundjob durchgeführt.';
			|ro = '%1.
			|Procedura este executată manual fără sarcina de fundal';
			|tr = '%1.
			|Prosedür manuel olarak, arkaplan görevi olmadan yürütüldü'; 
			|es_ES = '%1.
			|El procedimiento ha sido realizado manualmente sin tarea de fondo'"),
			CurrentData.Description),
		PictureLib.ExecuteScheduledJobManually);
	
EndProcedure

&AtServer
Procedure RunScheduledJobNotInBackground(JobID)
	
	ScheduledJobsInternal.RaiseIfNoAdministrationRights();
	SetPrivilegedMode(True);
	
	Job = ScheduledJobsServer.GetScheduledJob(JobID);
	MethodName = Job.Metadata.MethodName;
	
	Common.SystemSettingsStorageSave("ScheduledJobs", MethodName, True);
	Common.ExecuteConfigurationMethod(MethodName, Job.Parameters);
	Common.SystemSettingsStorageSave("ScheduledJobs", MethodName, Undefined);
	
EndProcedure

&AtClient
Procedure EventLogEvents(Command)
	
	EventFilter = New Structure;
	If Items.Jobs.CurrentPage = Items.ScheduledJobs Then
		CurrentData = Items.ScheduledJobsTable.CurrentData;
		If CurrentData = Undefined Then
			ShowMessageBox(, NStr("ru = 'Выберите регламентное задание.'; en = 'Select a scheduled job.'; pl = 'Wybierz jedno zaplanowane zadanie.';de = 'Wählen Sie einen geplanten Job aus.';ro = 'Selectați un program de lucru.';tr = 'Zamanlanmış bir görev seçin.'; es_ES = 'Seleccionar una tarea programada.'"));
			Return;
		EndIf;	
		If Not ValueIsFilled(CurrentData.StartDate) AND Not ValueIsFilled(CurrentData.EndDate) Then
			ShowMessageBox(, NStr("ru = 'Нет событий для просмотра, так как регламентное задание не выполнялось.'; en = 'No events to view as the scheduled job was not executed.'; pl = 'Brak zdarzeń do wyświetlenia, ponieważ regulaminowe zadanie nie zostało wykonane.';de = 'Es gibt keine Ereignisse zu sehen, da die Routineaufgabe nicht ausgeführt wurde.';ro = 'Evenimentele pentru vizualizare lipsesc, deoarece sarcina reglementară nu s-a executat.';tr = 'Standart görev yapılmamasından dolayı görüntülenecek olay yok.'; es_ES = 'No hay eventos para ver, porque la tarea programada no se ejecutaba.'"));
			Return;
		EndIf;	
		EventFilter.Insert("StartDate", CurrentData.StartDate);
		EventFilter.Insert("EndDate", CurrentData.EndDate);
	ElsIf Items.Jobs.CurrentPage = Items.BackgroundJobs Then
		CurrentData = Items.BackgroundJobsTable.CurrentData;
		If CurrentData = Undefined Then
			ShowMessageBox(, NStr("ru = 'Выберите фоновое задание.'; en = 'Select a background job.'; pl = 'Wybierz zadanie w tle.';de = 'Wählen Sie einen Hintergrundjob aus.';ro = 'Selectați sarcina de fundal.';tr = 'Arkaplan işi seçin.'; es_ES = 'Seleccionar una tarea de fondo.'"));
			Return;
		EndIf;	
		EventFilter.Insert("StartDate", CurrentData.Begin);
		EventFilter.Insert("EndDate", CurrentData.End);
	EndIf;
	
	EventLogClient.OpenEventLog(EventFilter, ThisObject);
		
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SetConditionalAppearance()
	
	ConditionalAppearance.Items.Clear();
	
	//
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.End.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("BackgroundJobsTable.End");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	Item.Appearance.SetParameterValue("Text", NStr("ru = '<>'; en = '<>'; pl = '<>';de = '<>';ro = '<>';tr = '<>'; es_ES = '<>'"));
	
	//
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ExecutionState.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("ScheduledJobsTable.ExecutionState");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = NStr("ru = '<не определено>'; en = '<not defined>'; pl = '<nie określono>';de = '<nicht bestimmt>';ro = '<nu este determinată>';tr = '<belirlenmedi>'; es_ES = '<no determinado>'");
	Item.Appearance.SetParameterValue("TextColor", StyleColors.InaccessibleCellTextColor);
	
	//
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.EndDate.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("ScheduledJobsTable.EndDate");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = NStr("ru = '<не определено>'; en = '<not defined>'; pl = '<nie określono>';de = '<nicht bestimmt>';ro = '<nu este determinată>';tr = '<belirlenmedi>'; es_ES = '<no determinado>'");
	Item.Appearance.SetParameterValue("TextColor", StyleColors.InaccessibleCellTextColor);
	
	//
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.StartDate.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("ScheduledJobsTable.StartDate");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = NStr("ru = '<не определено>'; en = '<not defined>'; pl = '<nie określono>';de = '<nicht bestimmt>';ro = '<nu este determinată>';tr = '<belirlenmedi>'; es_ES = '<no determinado>'");
	Item.Appearance.SetParameterValue("TextColor", StyleColors.InaccessibleCellTextColor);
	
	//
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.Use.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.Description.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ExecutionState.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.EndDate.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.StartDate.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.UserName.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.Predefined.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("ScheduledJobsTable.JobName");
	ItemFilter.ComparisonType = DataCompositionComparisonType.InList;
	ItemFilter.RightValue = DisabledJobs;
	Item.Appearance.SetParameterValue("Visible", False);
	
EndProcedure

&AtServer
Procedure SetDisabledJobsVisibility(Show)
	
	Item = ConditionalAppearance.Items.Get(4);
	AppearanceItem = Item.Appearance.Items.Find("Visible");
	
	If Not Show Then
		Item.Filter.Items.Clear();
		ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
		ItemFilter.LeftValue  = New DataCompositionField("ScheduledJobsTable.JobName");
		ItemFilter.ComparisonType   = DataCompositionComparisonType.InList;
		ItemFilter.RightValue = DisabledJobs;
		
		AppearanceItem.Use = True;
	Else
		Item.Filter.Items.Clear();
		AppearanceItem.Use = False;
	EndIf;
	
	ParenthesisPosition = StrFind(Items.ScheduledJobs.Title, " (");
	If ParenthesisPosition > 0 Then
		Items.ScheduledJobs.Title = Left(Items.ScheduledJobs.Title, ParenthesisPosition - 1);
	EndIf;
	ItemsOnList = ScheduledJobsTable.Count();
	If ItemsOnList > 0 Then
		If Not Show Then
			ItemsOnList = ItemsOnList - DisabledJobs.Count();
		EndIf;
		Items.ScheduledJobs.Title = Items.ScheduledJobs.Title + " (" + Format(ItemsOnList, "NG=") + ")";
	EndIf;
	
EndProcedure

&AtClient
Procedure ScheduledJobsTableBeforeDeleteEnd(Response, Context) Export
	
	If Response = DialogReturnCode.Yes Then
		DeleteScheduledJobExecuteAtServer(
			Items.ScheduledJobsTable.CurrentData.ID);
	EndIf;
	
EndProcedure

&AtClient
Procedure ExecuteScheduledJobManuallyEnd(Response, AllErrorsText) Export
	
	If Response = 1 Then
		AllErrorsText.Show();
	EndIf;
	
EndProcedure

&AtClient
Procedure OpenScheduleEnd(NewSchedule, CurrentData) Export

	If NewSchedule <> Undefined Then
		SetSchedule(CurrentData.ID, NewSchedule);
		ImportScheduledJobs(CurrentData.ID, True);
	EndIf;
	
EndProcedure

&AtServerNoContext
Function GetSchedule(Val ScheduledJobID)
	
	SetPrivilegedMode(True);
	
	Return ScheduledJobsServer.JobSchedule(
		ScheduledJobID);
	
EndFunction

&AtServerNoContext
Procedure SetSchedule(Val ScheduledJobID, Val Schedule)
	
	SetPrivilegedMode(True);
	
	ScheduledJobsServer.SetJobSchedule(
		ScheduledJobID,
		Schedule);
	
EndProcedure

&AtServer
Procedure FillFormSettings(Val Settings)
	
	DefaultSettings = New Structure;
	
	// Background job filter setting.
	If Settings.Get("FilterByActiveState") = Undefined Then
		Settings.Insert("FilterByActiveState", True);
	EndIf;
	
	If Settings.Get("FilterByCompletedState") = Undefined Then
		Settings.Insert("FilterByCompletedState", True);
	EndIf;
	
	If Settings.Get("FilterByFailedState") = Undefined Then
		Settings.Insert("FilterByFailedState", True);
	EndIf;

	If Settings.Get("FilterByCanceledState") = Undefined Then
		Settings.Insert("FilterByCanceledState", True);
	EndIf;
	
	If Settings.Get("FilterByScheduledJob") = Undefined
	 OR Settings.Get("ScheduledJobForFilterID")   = Undefined Then
		Settings.Insert("FilterByScheduledJob", False);
		Settings.Insert("ScheduledJobForFilterID", BlankID);
	EndIf;
	
	// Setting filter by the All time period.
	// See also the FilterKindByPeriodOnChange switch event handler.
	If Settings.Get("FilterKindByPeriod") = Undefined
	 OR Settings.Get("FilterPeriodFrom")       = Undefined
	 OR Settings.Get("FilterPeriodTo")      = Undefined Then
		
		Settings.Insert("FilterKindByPeriod", 0);
		CurrentSessionDate = CurrentSessionDate();
		Settings.Insert("FilterPeriodFrom",  BegOfDay(CurrentSessionDate) - 3*3600);
		Settings.Insert("FilterPeriodTo", BegOfDay(CurrentSessionDate) + 9*3600);
	EndIf;
	
	For Each Setting In Settings Do
		DefaultSettings.Insert(Setting.Key, Setting.Value);
	EndDo;
	
	FillPropertyValues(ThisObject, DefaultSettings);
	
	// Setting visibility and accessibility.
	Items.SettingArbitraryPeriod.Visible = (FilterKindByPeriod = 4);
	Items.FilterPeriodFrom.ReadOnly  = NOT (FilterKindByPeriod = 4);
	Items.FilterPeriodTo.ReadOnly = NOT (FilterKindByPeriod = 4);
	Items.ScheduledJobForFilter.Enabled = FilterByScheduledJob;
	
	RefreshAutomaticPeriod(ThisObject, CurrentSessionDate());
	
EndProcedure

&AtClient
Procedure OpenBackgroundJob()
	
	If Items.BackgroundJobsTable.CurrentData = Undefined Then
		ShowMessageBox(, NStr("ru = 'Выберите фоновое задание.'; en = 'Select a background job.'; pl = 'Wybierz zadanie w tle.';de = 'Wählen Sie einen Hintergrundjob aus.';ro = 'Selectați sarcina de fundal.';tr = 'Arkaplan işi seçin.'; es_ES = 'Seleccionar una tarea de fondo.'"));
		Return;
	EndIf;
	
	PassedPropertyList =
	"ID,
	|Key,
	|Description,
	|MethodName,
	|State,
	|Begin,
	|End,
	|Location,
	|UserMessagesAndErrorDescription,
	|ScheduledJobID,
	|ScheduledJobDescription";
	CurrentDataValues = New Structure(PassedPropertyList);
	FillPropertyValues(CurrentDataValues, Items.BackgroundJobsTable.CurrentData);
	
	FormParameters = New Structure;
	FormParameters.Insert("ID", Items.BackgroundJobsTable.CurrentData.ID);
	FormParameters.Insert("BackgroundJobProperties", CurrentDataValues);
	
	OpenForm("DataProcessor.ScheduledAndBackgroundJobs.Form.BackgroundJob", FormParameters, ThisObject);
	
EndProcedure

&AtServerNoContext
Function CurrentSessionDateAtServer()
	
	Return CurrentSessionDate();
	
EndFunction

&AtServer
Function ScheduledJobsFinishedNotification()
	
	CompletionNotifications = New Array;
	
	If BackgroundJobIDsOnManualExecution.Count() > 0 Then
		Index = BackgroundJobIDsOnManualExecution.Count() - 1;
		
		SetPrivilegedMode(True);
		While Index >= 0 Do
			
			NewUUID = New UUID(
				BackgroundJobIDsOnManualExecution[Index].Value);
			Filter = New Structure;
			Filter.Insert("UUID", NewUUID);
			
			BackgroundJobArray = BackgroundJobs.GetBackgroundJobs(Filter);
			
			If BackgroundJobArray.Count() = 1 Then
				FinishedAt = BackgroundJobArray[0].End;
				
				If ValueIsFilled(FinishedAt) Then
					
					CompletionNotifications.Add(
						New Structure(
							"ScheduledJobPresentation,
							|FinishedAt",
							BackgroundJobIDsOnManualExecution[Index].Presentation,
							FinishedAt));
					
					BackgroundJobIDsOnManualExecution.Delete(Index);
				EndIf;
			Else
				BackgroundJobIDsOnManualExecution.Delete(Index);
			EndIf;
			Index = Index - 1;
		EndDo;
		SetPrivilegedMode(False);
	EndIf;
	
	Return CompletionNotifications;
	
EndFunction

&AtClient
Procedure NotifyAboutManualScheduledJobCompletion()
	
	CompletionNotifications = ScheduledJobsFinishedNotification();
	
	For each Notification In CompletionNotifications Do
		
		ShowUserNotification(
			NStr("ru = 'Выполнена процедура регламентного задания'; en = 'The scheduled job procedure has been completed'; pl = 'Procedura zaplanowanego zadania została wykonana';de = 'Geplante Job-Prozedur wird ausgeführt';ro = 'Procedura sarcinii de fundal este executată';tr = 'Zamanlanmış iş prosedürü gerçekleştirildi'; es_ES = 'Procedimiento de la tarea programada se ha ejecutado'"),
			,
			StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = '%1.
				           |Процедура завершена в фоновом задании %2'; 
				           |en = '%1.
				           |The procedure has been completed in the %2 background job'; 
				           |pl = '%1.
				           |Procedura została zakończona w pracy w tle %2';
				           |de = '%1.
				           |Die Prozedur wurde im Hintergrundjob abgeschlossen %2';
				           |ro = '%1.
				           |A fost finalizată procedura în sarcina de fundal %2';
				           |tr = '%1. 
				           |Prosedür arka plan işinde tamamlandı%2'; 
				           |es_ES = '%1.
				           |El procedimiento se ha finalizado en la tarea de fondo %2'"),
				Notification.ScheduledJobPresentation,
				String(Notification.FinishedAt)),
			PictureLib.ExecuteScheduledJobManually);
	EndDo;
	
	If BackgroundJobIDsOnManualExecution.Count() > 0 Then
		
		AttachIdleHandler(
			"NotifyAboutManualScheduledJobCompletion", 2, True);
	Else
		ImportScheduledJobs(, True);
	EndIf;
	
EndProcedure

&AtServer
Procedure UpdateScheduledJobChoiceList()
	
	Table = ScheduledJobsTable;
	List  = Items.ScheduledJobForFilter.ChoiceList;
	
	// Adding a predefined item.
	If List.Count() = 0 Then
		List.Add(BlankID, TextUndefined);
	EndIf;
	
	Index = 1;
	For each Job In Table Do
		If Index >= List.Count()
		 OR List[Index].Value <> Job.ID Then
			// Inserting a new job.
			List.Insert(Index, Job.ID, Job.Description);
		Else
			List[Index].Presentation = Job.Description;
		EndIf;
		Index = Index + 1;
	EndDo;
	
	// Deleting unnecessary rows.
	While Index < List.Count() Do
		List.Delete(Index);
	EndDo;
	
	ListItem = List.FindByValue(ScheduledJobForFilterID);
	If ListItem = Undefined Then
		ScheduledJobForFilterID = BlankID;
	EndIf;
	
EndProcedure

&AtServer
Function ExecuteScheduledJobManuallyAtServer(Val ScheduledJobID)
	
	Result = ScheduledJobsInternal.ExecuteScheduledJobManually(ScheduledJobID);
	Return Result;
	
EndFunction

&AtServer
Procedure CancelBackgroundJobAtServer(Val ID)
	
	ScheduledJobsInternal.CancelBackgroundJob(ID);
	UpdateBackgroundJobTable();
	
EndProcedure

&AtServer
Procedure DeleteScheduledJobExecuteAtServer(Val ID)
	
	Job = ScheduledJobsServer.GetScheduledJob(ID);
	Row = ScheduledJobsTable.FindRows(New Structure("ID", ID))[0];
	Job.Delete();
	ScheduledJobsTable.Delete(ScheduledJobsTable.IndexOf(Row));
	
EndProcedure

&AtClient
Procedure AddCopyEditScheduledJob(Val Action)
	
	If Items.ScheduledJobsTable.CurrentData = Undefined Then
		ShowMessageBox(, NStr("ru = 'Выберите регламентное задание.'; en = 'Select a scheduled job.'; pl = 'Wybierz jedno zaplanowane zadanie.';de = 'Wählen Sie einen geplanten Job aus.';ro = 'Selectați un program de lucru.';tr = 'Zamanlanmış bir görev seçin.'; es_ES = 'Seleccionar una tarea programada.'"));
	Else
		FormParameters = New Structure;
		FormParameters.Insert("ID", Items.ScheduledJobsTable.CurrentData.ID);
		FormParameters.Insert("Action",      Action);
		
		OpenForm("DataProcessor.ScheduledAndBackgroundJobs.Form.ScheduledJob", FormParameters, ThisObject);
	EndIf;
	
EndProcedure

&AtClient
Procedure ScheduledJobsDeferredUpdate()
	
	ImportScheduledJobs(, True);
	
EndProcedure

&AtClientAtServerNoContext
Procedure RefreshAutomaticPeriod(Form, CurrentSessionDate)
	
	If Form.FilterKindByPeriod = 1 Then
		Form.FilterPeriodFrom  = BegOfDay(CurrentSessionDate) - 3*3600;
		Form.FilterPeriodTo = BegOfDay(CurrentSessionDate) + 9*3600;
		
	ElsIf Form.FilterKindByPeriod = 2 Then
		Form.FilterPeriodFrom  = BegOfDay(CurrentSessionDate) - 24*3600;
		Form.FilterPeriodTo = EndOfDay(Form.FilterPeriodFrom);
		
	ElsIf Form.FilterKindByPeriod = 3 Then
		Form.FilterPeriodFrom  = BegOfDay(CurrentSessionDate);
		Form.FilterPeriodTo = EndOfDay(Form.FilterPeriodFrom);
	EndIf;
	
EndProcedure

&AtServer
Procedure SetScheduledJobUsage(Enabled)
	
	For each SelectedRow In Items.ScheduledJobsTable.SelectedRows Do
		CurrentData = ScheduledJobsTable.FindByID(SelectedRow);
		Job = ScheduledJobsServer.GetScheduledJob(CurrentData.ID);
		If Job.Use <> Enabled Then
			Job.Use = Enabled;
			Job.Write();
			CurrentData.Use = Enabled;
		EndIf;
	EndDo;
	
EndProcedure

&AtServerNoContext
Procedure LockOfOperationsWithExternalResourcesURLProcessingAtServerNote()
	ScheduledJobsServer.UnlockOperationsWithExternalResources();
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Background import of scheduled jobs.

&AtClient
Procedure ImportScheduledJobs(JobID = Undefined, UpdateSilently = False)
	
	If Not UpdateSilently Then
		Items.ScheduledJobsDeferredImportPages.CurrentPage = Items.ScheduledJobsImportPage;
	EndIf;
	If Items.ScheduledJobsTable.CurrentData <> Undefined Then
		CurrentRowID = Items.ScheduledJobsTable.CurrentData.ID;
	EndIf;
	Result = ScheduledJobsImport(JobID);
	
	IdleParameters = TimeConsumingOperationsClient.IdleParameters(ThisObject);
	IdleParameters.OutputIdleWindow = False;
	CompletionNotification = New NotifyDescription("ImportScheduledJobsCompletion", ThisObject);
	
	TimeConsumingOperationsClient.WaitForCompletion(Result, CompletionNotification, IdleParameters);
	
EndProcedure

&AtClient
Procedure ImportScheduledJobsCompletion(Result, AdditionalParameters) Export
	
	If Result = Undefined Then
		Return;
	EndIf;
	
	If Result.Status = "Completed" Then
		ProcessResult(Result);
		Items.ScheduledJobsDeferredImportPages.CurrentPage = Items.ScheduledJobsPage;
	ElsIf Result.Status = "Error" Then
		Items.ScheduledJobsDeferredImportPages.CurrentPage = Items.ScheduledJobsPage;
		Raise Result.BriefErrorPresentation;
	EndIf;
	
EndProcedure

&AtServer
Function ScheduledJobsImport(JobID)
	
	If ExecutionResult <> Undefined
		AND ValueIsFilled(ExecutionResult.JobID) Then
		TimeConsumingOperations.CancelJobExecution(ExecutionResult.JobID);
	EndIf;
	
	TimeConsumingOperationParameters = TimeConsumingOperationParameters();
	TimeConsumingOperationParameters.Insert("ScheduledJobID", JobID);
	
	ExecutionParameters = TimeConsumingOperations.BackgroundExecutionParameters(UUID);
	If JobID <> Undefined Then
		ExecutionParameters.RunNotInBackground = True;
	EndIf;
	ExecutionParameters.WaitForCompletion = 0; // run immediately
	ExecutionParameters.BackgroundJobDescription = NStr("ru = 'Формирование таблицы регламентных заданий'; en = 'Generate scheduled jobs table'; pl = 'Tworzenie tabeli planowych zadań';de = 'Erstellung der Tabelle der Routineaufgaben';ro = 'Generarea tabelului sarcinilor reglementare';tr = 'Zamanlanmış görev tablosunun oluşturulması'; es_ES = 'Generación de la tabla de tarea programadas'");
	
	Return TimeConsumingOperations.ExecuteInBackground("ScheduledJobsInternal.GenerateScheduledJobsTable",
		TimeConsumingOperationParameters, ExecutionParameters);
	
EndFunction

&AtServer
Function TimeConsumingOperationParameters()
	
	OperationParameters = New Structure;
	OperationParameters.Insert("Table", FormAttributeToValue("ScheduledJobsTable"));
	OperationParameters.Insert("DisabledJobs", DisabledJobs.Copy());
	
	Return OperationParameters;
	
EndFunction

&AtServer
Procedure ProcessResult(JobParameters)
	
	Result = GetFromTempStorage(JobParameters.ResultAddress);
	DisabledJobs.Clear();
	For Each ListItem In Result.DisabledJobs Do
		DisabledJobs.Add(ListItem.Value);
	EndDo;
	
	SetDisabledJobsVisibility(Items.ScheduledJobsTableShowAllJobs.Check);
	
	ValueToFormAttribute(Result.Table, "ScheduledJobsTable");
	
	Items.ScheduledJobsTable.Refresh();
	
	// Positioning of the scheduled jobs list.
	If ValueIsFilled(CurrentRowID) Then
		SearchResult = ScheduledJobsTable.FindRows(New Structure("ID", CurrentRowID));
		If SearchResult.Count() = 1 Then
			Row = SearchResult[0];
			Items.ScheduledJobsTable.CurrentRow = Row.GetID();
		EndIf;
	EndIf;
	
	ParenthesisPosition = StrFind(Items.ScheduledJobs.Title, " (");
	If ParenthesisPosition > 0 Then
		Items.ScheduledJobs.Title = Left(Items.ScheduledJobs.Title, ParenthesisPosition - 1);
	EndIf;
	ItemsOnList = ScheduledJobsTable.Count();
	If ItemsOnList > 0 Then
		If Not Items.ScheduledJobsTableShowAllJobs.Check Then
			ItemsOnList = ItemsOnList - DisabledJobs.Count();
		EndIf;
		Items.ScheduledJobs.Title = Items.ScheduledJobs.Title + " (" + Format(ItemsOnList, "NG=") + ")";
	EndIf;
	
	UpdateScheduledJobChoiceList();
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Background import of background jobs.

&AtClient
Procedure UpdateBackgroundJobsTableAtClient()
	
	Result = GenerateBackgroundJobsTableInBackground();
	If Result.Status = "Completed" Or Result.Status = "Error" Then
		Return;
	EndIf;
	
	Items.HeaderGroup.Enabled = False;
	Items.BackgroundJobsDeferredImportPages.CurrentPage = Items.TimeConsumingOperationPage;
	
	IdleParameters = TimeConsumingOperationsClient.IdleParameters(ThisObject);
	IdleParameters.OutputIdleWindow = False;
	CompletionNotification = New NotifyDescription("UpdaetBackgroundJobTableCompletion", ThisObject);
	TimeConsumingOperationsClient.WaitForCompletion(Result, CompletionNotification, IdleParameters);
	
EndProcedure

&AtServer
Function GenerateBackgroundJobsTableInBackground()
	
	Filter = BackgroundJobsFilter();
	TransmittedParameters = New Structure;
	TransmittedParameters.Insert("Filter", Filter);
	
	ExecutionParameters = TimeConsumingOperations.BackgroundExecutionParameters(UUID);
	ExecutionParameters.WaitForCompletion = 0;
	ExecutionParameters.BackgroundJobDescription = NStr("ru = 'Регламентные задания. Обновление списка фоновых заданий'; en = 'Scheduled jobs. Updating a list of background jobs'; pl = 'Planowe zadania. Aktualizacja listy zadań wykonywanych w tle';de = 'Routineufgaben. Aktualisierung der Liste der Hintergrundaufgaben';ro = 'Sarcini reglementare. Actualizarea listei sarcinilor de fundal';tr = 'Zamanlanmış görevler.  Arkaplan görev listesinin güncellenmesi.'; es_ES = 'Tareas programadas. Actualización de la lista de tareas programadas'");
	
	Result = TimeConsumingOperations.ExecuteInBackground("ScheduledJobsInternal.FillBackgroundJobsPropertiesTableInBackground",
		TransmittedParameters, ExecutionParameters);
		
	If Result.Status = "Completed" Then
		UpdateBackgroundJobTable(Result.ResultAddress);
	ElsIf Result.Status = "Error" Then
		Raise Result.BriefErrorPresentation;
	EndIf;
	
	Return Result;
		
EndFunction

&AtServer
Function BackgroundJobsFilter()
	
	// 1. Filter preparation.
	Filter = New Structure;
	
	// 1.1. Adding filter by state.
	StateArray = New Array;
	
	If FilterByActiveState Then 
		StateArray.Add(BackgroundJobState.Active);
	EndIf;
	
	If FilterByCompletedState Then 
		StateArray.Add(BackgroundJobState.Completed);
	EndIf;
	
	If FilterByFailedState Then 
		StateArray.Add(BackgroundJobState.Failed);
	EndIf;
	
	If FilterByCanceledState Then 
		StateArray.Add(BackgroundJobState.Canceled);
	EndIf;
	
	If StateArray.Count() <> 4 Then
		If StateArray.Count() = 1 Then
			Filter.Insert("State", StateArray[0]);
		Else
			Filter.Insert("State", StateArray);
		EndIf;
	EndIf;
	
	// 1.2. Adding filter by scheduled job.
	If FilterByScheduledJob Then
		Filter.Insert(
				"ScheduledJobID",
				?(ScheduledJobForFilterID = BlankID,
				"",
				ScheduledJobForFilterID));
	EndIf;
	
	// 1.3. Adding filter by period.
	If FilterKindByPeriod <> 0 Then
		RefreshAutomaticPeriod(ThisObject, CurrentSessionDate());
		Filter.Insert("Begin", FilterPeriodFrom);
		Filter.Insert("End",  FilterPeriodTo);
	EndIf;
	
	Return Filter;
	
EndFunction

&AtServer
Procedure UpdateBackgroundJobTable(ResultAddress = Undefined)
	
	// Refreshing the background job list.
	
	If ResultAddress <> Undefined Then
		DataFromStorage = GetFromTempStorage(ResultAddress);
		CurrentTable = DataFromStorage.PropertiesTable;
	Else
		Filter = BackgroundJobsFilter();
		CurrentTable = ScheduledJobsInternal.BackgroundJobsProperties(Filter);
	EndIf;
	
	Table = BackgroundJobsTable;
	
	Index = 0;
	For each Job In CurrentTable Do
		
		If Index >= Table.Count()
		 OR Table[Index].ID <> Job.ID Then
			// Inserting a new job.
			ToUpdate = Table.Insert(Index);
			// Setting a UUID.
			ToUpdate.ID = Job.ID;
		Else
			ToUpdate = Table[Index];
		EndIf;
		
		FillPropertyValues(ToUpdate, Job);
		
		// Setting the scheduled job description from the ScheduledJobTable collection.
		If ValueIsFilled(ToUpdate.ScheduledJobID) Then
			
			ToUpdate.ScheduledJobID
				= ToUpdate.ScheduledJobID;
			
			Rows = ScheduledJobsTable.FindRows(
				New Structure("ID", ToUpdate.ScheduledJobID));
			
			ToUpdate.ScheduledJobDescription
				= ?(Rows.Count() = 0, NStr("ru = '<не найдено>'; en = '<not found>'; pl = '<nie znaleziono>';de = '<nicht gefunden>';ro = '<nu a fost găsită>';tr = '<bulunamadı>'; es_ES = '<no encontrado>'"), Rows[0].Description);
		Else
			ToUpdate.ScheduledJobDescription  = TextUndefined;
			ToUpdate.ScheduledJobID = TextUndefined;
		EndIf;
		
		// Getting error details.
		ToUpdate.UserMessagesAndErrorDescription 
			= ScheduledJobsInternal.BackgroundJobMessagesAndErrorDescriptions(
				ToUpdate.ID, Job);
		
		// Index increase
		Index = Index + 1;
	EndDo;
	
	// Deleting unnecessary rows.
	While Index < Table.Count() Do
		Table.Delete(Table.Count()-1);
	EndDo;
	
	Items.BackgroundJobsTable.Refresh();
	
	ParenthesisPosition = StrFind(Items.BackgroundJobs.Title, " (");
	If ParenthesisPosition > 0 Then
		Items.BackgroundJobs.Title = Left(Items.BackgroundJobs.Title, ParenthesisPosition - 1);
	EndIf;
	ItemsOnList = BackgroundJobsTable.Count();
	If ItemsOnList > 0 Then
		Items.BackgroundJobs.Title = Items.BackgroundJobs.Title + " (" + Format(ItemsOnList, "NG=") + ")";
	EndIf;
	
EndProcedure

&AtClient
Procedure UpdaetBackgroundJobTableCompletion(Result, AdditionalParameters) Export
	
	If Result = Undefined Then
		Return;
	EndIf;
	
	If Result.Status = "Completed" Then
		UpdateBackgroundJobTable(Result.ResultAddress);
		Items.HeaderGroup.Enabled = True;
		Items.BackgroundJobsDeferredImportPages.CurrentPage = Items.BackgroundJobsPage;
	ElsIf Result.Status = "Error" Then
		Items.HeaderGroup.Enabled = True;
		Items.BackgroundJobsDeferredImportPages.CurrentPage = Items.BackgroundJobsPage;
		Raise Result.BriefErrorPresentation;
	EndIf;
	
EndProcedure

#EndRegion
