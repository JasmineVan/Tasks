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
	
	SubsystemSettings = InfobaseUpdateInternal.SubsystemSettings();
	ToolTipText      = SubsystemSettings.UpdateResultNotes;
	
	If Not IsBlankString(ToolTipText) Then
		Items.WhereToFindThisFormHint.Title = ToolTipText;
	EndIf;
	
	If Not Users.IsFullUser(, True) Then
		
		Items.MinimalUserActivityPeriodHintGroup.Visible = False;
		Items.WhereToFindThisFormHint.Title = 
			NStr("ru = 'Ход обработки данных версии программы можно также проконтролировать из раздела
		               |""Информация"" на рабочем столе, команда ""Описание изменений программы"".'; 
		               |en = 'To monitor the progress of processing application version data,
		               |go to Quick menu—Information—Change log.'; 
		               |pl = 'Proces przetwarzania danych wersji programu można także przekontrolować z rozdziału 
		               |""Информация"" na pulpicie, polecenie ""Описание изменений программы"".';
		               |de = 'Sie können den Status der Datenverarbeitung der Programmversion auch im Abschnitt 
		               |""Informationen"" auf dem Desktop mit dem Befehl ""Beschreibung der Programmänderungen"" überwachen.';
		               |ro = 'Progresul procesării datelor versiunilor de aplicație poate fi, de asemenea, controlat din compartimentul 
		               |""Informații"" de pe desktop, comanda ""Descrierea modificărilor aplicației"".';
		               |tr = 'Uygulama  sürümleri veri işleminin ilerlemesi, masaüstündeki ""Bilgi"" bölümünden  de ""Uygulama değişikliklerinin açıklaması"" komutundan 
		               |kontrol  edilebilir.'; 
		               |es_ES = 'Progreso del procesamiento de los datos de las versiones de la aplicación puede también controlarse desde la sección
		               | ""Información"" en el escritorio, el comando ""Descripción de los cambios de la aplicación"".'");
		
	EndIf;
	
	// Reading values of add-ins.
	GetInfobaseUpdateThreadsCount();
	UpdateInfo = InfobaseUpdateInternal.InfobaseUpdateInfo();
	UpdatePriority = ?(UpdateInfo.DeferredUpdateManagement.Property("ForceUpdate"), "DataProcessing", "UserWork");
	UpdateEndTime = UpdateInfo.UpdateEndTime;
	
	DeferredUpdateStartTime = UpdateInfo.DeferredUpdateStartTime;
	DeferredUpdateEndTime = UpdateInfo.DeferredUpdateEndTime;
	
	FileIB = Common.FileInfobase();
	
	If ValueIsFilled(UpdateEndTime) Then
		Items.UpdateCompletedInformation.Title = StringFunctionsClientServer.SubstituteParametersToString(
			Items.UpdateCompletedInformation.Title,
			Metadata.Version,
			Format(UpdateEndTime, "DLF=D"),
			Format(UpdateEndTime, "DLF=T"),
			UpdateInfo.UpdateDuration);
	Else
		UpdateCompletedTitle = NStr("ru = 'Версия программы успешно обновлена на версию %1'; en = 'The application is updated to version %1.'; pl = 'Wersja aplikacji została pomyślnie zaktualizowana do wersji %1';de = 'Die Anwendungsversion wurde erfolgreich auf Version %1 aktualisiert';ro = 'Versiunea aplicației a fost actualizată cu succes cu versiunea %1';tr = 'Uygulama %1 sürümüne başarıyla güncellendi'; es_ES = 'La versión de la aplicación se ha actualizado con éxito para la versión %1'");
		Items.UpdateCompletedInformation.Title = StringFunctionsClientServer.SubstituteParametersToString(UpdateCompletedTitle, Metadata.Version);
	EndIf;
	
	If UpdateInfo.DeferredUpdateEndTime = Undefined Then
		
		If Not Users.IsFullUser(, True) Then
			Items.UpdateStatus.CurrentPage = Items.UpdateStatusForUser;
		Else
			
			If Not FileIB AND UpdateInfo.DeferredUpdateCompletedSuccessfully = Undefined Then
				Items.UpdateStatus.CurrentPage = Items.UpdateInProgress;
			Else
				Items.UpdateStatus.CurrentPage = Items.FileInfobaseUpdate;
			EndIf;
			
		EndIf;
		
	Else
		MessageText = UpdateResultMessage(UpdateInfo);
		Items.UpdateStatus.CurrentPage = Items.UpdateCompleted;
		
		UpdateInfo = InfobaseUpdateInternal.InfobaseUpdateInfo();
		CaptionPattern = NStr("ru = 'Дополнительные процедуры обработки данных завершены %1 в %2'; en = 'Additional data processing procedures were completed on %1 at %2.'; pl = 'Dodatkowe procedury przetwarzania danych są zakończone %1 na %2';de = 'Zusätzliche Datenverarbeitungsverfahren sind abgeschlossen %1 an %2';ro = 'Procedurile suplimentare de procesare a datelor sunt finalizate %1 la %2';tr = 'Ek veri işlemci prosedürleri %1 %2 tamamlandı'; es_ES = 'Procedimientos del procesador de datos adicional se han finalizado %1 en %2'");
		Items.DeferredUpdateCompletedInformation.Title = 
		StringFunctionsClientServer.SubstituteParametersToString(CaptionPattern, 
			Format(UpdateInfo.DeferredUpdateEndTime, "DLF=D"),
			Format(UpdateInfo.DeferredUpdateEndTime, "DLF=T"));
		
	EndIf;
	
	SetVisibilityForInfobaseUpdateThreadsCount();
	
	If Not FileIB Then
		UpdateCompleted = False;
		ShowUpdateStatus(UpdateInfo, UpdateCompleted);
		SetAvailabilityForInfobaseUpdateThreadsCount(ThisObject);
		
		If UpdateCompleted Then
			RefreshUpdateCompletedPage(UpdateInfo);
			Items.UpdateStatus.CurrentPage = Items.UpdateCompleted;
			Return;
		EndIf;
		
	Else
		Items.UpdateStatusInformation.Visible = False;
		Items.EditSchedule.Visible         = False;
	EndIf;
	
	If Users.IsFullUser(, True) Then
		
		If Common.DataSeparationEnabled() Then
			Items.ScheduleSetupGroup.Visible = False;
		Else
			JobsFilter = New Structure;
			JobsFilter.Insert("Metadata", Metadata.ScheduledJobs.DeferredIBUpdate);
			Jobs = ScheduledJobsServer.FindJobs(JobsFilter);
			For Each Job In Jobs Do
				Schedule = Job.Schedule;
				Break;
			EndDo;
		EndIf;
		
	EndIf;
	
	If Common.DataSeparationEnabled() Then
		Items.MainUpdateHyperlink.Visible = False;
		Items.PriorityGroup.Visible               = False;
	EndIf;
	
	ProcessUpdateResultAtServer();
	
	HideExtraGroupsInForm(Parameters.OpenedFromAdministrationPanel);
	
	Items.OpenDeferredHandlersList.Title = MessageText;
	Items.InformationTitle.Title = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("ru = 'Выполняются дополнительные процедуры обработки данных на версию %1
			|Работа с этими данными временно ограничена'; 
			|en = 'Additional data processing procedures required for upgrade to version %1 are in progress.
			|Operations with this data are temporarily restricted.'; 
			|pl = 'Są wykonywane dodatkowe procedury przetwarzania danych na wersję %1
			|Praca z tymi danymi jest czasowo ograniczona';
			|de = 'Zusätzliche Datenverarbeitungsverfahren pro Version werden durchgeführt %1
			|Arbeiten mit diesen Daten ist vorübergehend eingeschränkt';
			|ro = 'Procedurile suplimentare de procesare a datelor se execută pentru versiunea %1
			|Lucrul cu aceste date este limitat temporar';
			|tr = 'Veri işleme ek prosedürleri, %1
			|sürümü için çalışıyor Bu verileri ile çalışma geçici olarak sınırlandırılmıştır.'; 
			|es_ES = 'Procedimientos adicionales del procesador de datos están lanzados para la versión %1
			|Trabajo con estos datos está temporalmente limitado'"), Metadata.Version);
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
#If MobileClient Then
	ThisObject.CommandBarLocation = FormCommandBarLabelLocation.None;
#EndIf
	
	If Not FileIB Then
		AttachIdleHandler("CheckHandlersExecutionStatus", 15);
	EndIf;
	
	ProcessUpdateResultAtClient();
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If EventName = "DeferredUpdate" Then
		
		If Not FileIB Then
			Items.UpdateStatus.CurrentPage = Items.UpdateInProgress;
		EndIf;
		
		AttachIdleHandler("RunDeferredUpdate", 0.5, True);
	EndIf;
	
EndProcedure

&AtClient
Procedure UpdateStatusInformationClick(Item)
	OpenForm("DataProcessor.ApplicationUpdateResult.Form.DeferredHandlers");
EndProcedure

&AtClient
Procedure MainUpdateHyperlinkClick(Item)
	
	FormParameters = New Structure;
	FormParameters.Insert("StartDate", DeferredUpdateStartTime);
	If DeferredUpdateEndTime <> Undefined Then
		FormParameters.Insert("EndDate", DeferredUpdateEndTime);
	EndIf;
	
	OpenForm("DataProcessor.EventLog.Form.EventLog", FormParameters);
	
EndProcedure

&AtClient
Procedure InformationUpdateErrorURLProcessing(Item, FormattedStringURL, StandardProcessing)
	
	StandardProcessing = False;
	
	FormParameters = New Structure;
	
	ApplicationsList = New Array;
	ApplicationsList.Add("COMConnection");
	ApplicationsList.Add("Designer");
	ApplicationsList.Add("1CV8");
	ApplicationsList.Add("1CV8C");
	
	FormParameters.Insert("User", UserName());
	FormParameters.Insert("ApplicationName", ApplicationsList);
	
	OpenForm("DataProcessor.EventLog.Form.EventLog", FormParameters);
	
EndProcedure

&AtClient
Procedure UpdatePriorityOnChange(Item)
	
	SetUpdatePriority();
	SetAvailabilityForInfobaseUpdateThreadsCount(ThisObject);
	
EndProcedure

&AtClient
Procedure InfobaseUpdateThreadsCountOnChange(Item)
	
	SetInfobaseUpdateThreadsCount();
	
EndProcedure

&AtClient
Procedure InfoPatchesInstalledProcessURL(Item, FormattedStringURL, StandardProcessing)
	StandardProcessing = False;
	ShowInstalledPatches();
EndProcedure

#EndRegion

#Region FormCommandHandlers

&AtClient
Procedure RunUpdate(Command)
	
	If Not FileIB Then
		Items.UpdateStatus.CurrentPage = Items.UpdateInProgress;
	EndIf;
	
	AttachIdleHandler("RunDeferredUpdate", 0.5, True);
	
EndProcedure

&AtClient
Procedure OpenDeferredHandlerList(Command)
	OpenForm("DataProcessor.ApplicationUpdateResult.Form.DeferredHandlers");
EndProcedure

&AtClient
Procedure ChangeSchedule(Command)
	
	Dialog = New ScheduledJobDialog(Schedule);
	
	NotifyDescription = New NotifyDescription("ChangeScheduleAfterSetUpSchedule", ThisObject);
	Dialog.Show(NotifyDescription);
	
EndProcedure

&AtClient
Procedure EnableScheduledJobs(Command)
	If CommonClient.SubsystemExists("StandardSubsystems.UserSessionsCompletion") Then
		ModuleIBConnectionsClient = CommonClient.CommonModule("IBConnectionsClient");
		ModuleIBConnectionsClient.OnOpenUserActivityLockForm();
	EndIf;
EndProcedure

&AtClient
Procedure InformationForTechnicalSupport(Command)
	
	If Not IsBlankString(ScriptDirectory) Then
		NotifyDescription = New NotifyDescription("StartFileSearchCompletion", ThisObject);
		BeginFindingFiles(NotifyDescription, ScriptDirectory, "log*.txt");
	EndIf;
	
EndProcedure

&AtClient
Procedure StartFileSearchCompletion(FilesArray, AdditionalParameters) Export
	If FilesArray.Count() > 0 Then
		LogFile = FilesArray[0];
		FileSystemClient.OpenFile(LogFile.FullName);
	Else
		// If there is no log, open temporary directory of the update script.
		FileSystemClient.OpenExplorer(ScriptDirectory);
	EndIf;
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure HideExtraGroupsInForm(OpenedFromAdministrationPanel)
	
	IsFullUser = Users.IsFullUser(, True);
	
	If Not IsFullUser Or OpenedFromAdministrationPanel Then
		WindowOptionsKey = "FormForOrdinaryUser";
		
		Items.WhereToFindThisFormHint.Visible = False;
		Items.MainUpdateHyperlink.Visible = AccessRight("View", Metadata.DataProcessors.EventLog);
		
	Else
		WindowOptionsKey = "FormForAdministrator";
	EndIf;
	
	Items.EnableScheduledJobs.Visible = Common.SubsystemExists("StandardSubsystems.UserSessionsCompletion");
	
EndProcedure

&AtServer
Procedure SetUpdatePriority()
	
	BeginTransaction();
	Try
		Lock = New DataLock;
		Lock.Add("Constant.IBUpdateInfo");
		Lock.Lock();
		
		UpdateInfo = InfobaseUpdateInternal.InfobaseUpdateInfo();
		If UpdatePriority = "DataProcessing" Then
			UpdateInfo.DeferredUpdateManagement.Insert("ForceUpdate");
		Else
			UpdateInfo.DeferredUpdateManagement.Delete("ForceUpdate");
		EndIf;
		
		InfobaseUpdateInternal.WriteInfobaseUpdateInfo(UpdateInfo);
		
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;
	
EndProcedure

&AtServer
Procedure SetInfobaseUpdateThreadsCount()
	
	Constants.InfobaseUpdateThreadCount.Set(InfobaseUpdateThreadCount);
	
EndProcedure

&AtClient
Procedure RunDeferredUpdate()
	
	ExecuteUpdateAtServer();
	If Not FileIB Then
		AttachIdleHandler("CheckHandlersExecutionStatus", 15);
		Return;
	EndIf;
	
	Items.UpdateStatus.CurrentPage = Items.UpdateCompleted;
	
EndProcedure

&AtClient
Procedure CheckHandlersExecutionStatus()
	
	UpdateCompleted = False;
	CheckHandlersExecutionStatusAtServer(UpdateCompleted);
	If UpdateCompleted Then
		Items.UpdateStatus.CurrentPage = Items.UpdateCompleted;
		DetachIdleHandler("CheckHandlersExecutionStatus")
	EndIf;
	
EndProcedure

&AtServer
Procedure CheckHandlersExecutionStatusAtServer(UpdateCompleted)
	
	UpdateInfo = InfobaseUpdateInternal.InfobaseUpdateInfo();
	If UpdateInfo.DeferredUpdateEndTime <> Undefined Then
		UpdateCompleted = True;
	Else
		ShowUpdateStatus(UpdateInfo, UpdateCompleted);
	EndIf;
	
	If UpdateCompleted = True Then
		RefreshUpdateCompletedPage(UpdateInfo);
	EndIf;
	
EndProcedure

&AtServer
Procedure ExecuteUpdateAtServer()
	
	UpdateInfo = InfobaseUpdateInternal.InfobaseUpdateInfo();
	
	UpdateInfo.DeferredUpdateCompletedSuccessfully = Undefined;
	UpdateInfo.DeferredUpdateEndTime = Undefined;
	For Each TreeRowLibrary In UpdateInfo.HandlersTree.Rows Do
		For Each TreeRowVersion In TreeRowLibrary.Rows Do
			For Each Handler In TreeRowVersion.Rows Do
				Handler.AttemptCount = 0;
				If Handler.Status = "Error" Then
					Handler.ExecutionStatistics.Clear();
					Handler.Status = "NotCompleted";
				ElsIf Handler.Status = "Running" Then
					Handler.ExecutionStatistics.Insert("StartsCount", 0);
				EndIf;
			EndDo;
		EndDo;
	EndDo;
	
	UpdatePlanEmpty = True;
	For Each UpdateCycle In UpdateInfo.DeferredUpdatePlan Do
		If UpdateCycle.Property("CompletedWithErrors") Then
			UpdateCycle.Delete("CompletedWithErrors");
		EndIf;
		If UpdateCycle.Handlers.Count() > 0 Then
			UpdatePlanEmpty = False;
		EndIf;
	EndDo;
	
	If UpdatePlanEmpty Then
		InfobaseUpdateInternal.GenerateDeferredUpdatePlan(UpdateInfo, True);
	EndIf;
	
	InfobaseUpdateInternal.WriteInfobaseUpdateInfo(UpdateInfo);
	
	If Not FileIB Then
		InfobaseUpdateInternal.OnEnableDeferredUpdate(True);
		Return;
	EndIf;
	
	InfobaseUpdateInternal.ExecuteDeferredUpdateNow(Undefined);
	
	UpdateInfo = InfobaseUpdateInternal.InfobaseUpdateInfo();
	RefreshUpdateCompletedPage(UpdateInfo);
	
EndProcedure

&AtServer
Procedure RefreshUpdateCompletedPage(UpdateInfo)
	
	CaptionPattern = NStr("ru = 'Дополнительные процедуры обработки данных завершены %1 в %2'; en = 'Additional data processing procedures were completed on %1 at %2.'; pl = 'Dodatkowe procedury przetwarzania danych są zakończone %1 na %2';de = 'Zusätzliche Datenverarbeitungsverfahren sind abgeschlossen %1 an %2';ro = 'Procedurile suplimentare de procesare a datelor sunt finalizate %1 la %2';tr = 'Ek veri işlemci prosedürleri %1 %2 tamamlandı'; es_ES = 'Procedimientos del procesador de datos adicional se han finalizado %1 en %2'");
	MessageText = UpdateResultMessage(UpdateInfo);
	
	Items.DeferredUpdateCompletedInformation.Title = 
		StringFunctionsClientServer.SubstituteParametersToString(CaptionPattern, 
			Format(UpdateInfo.DeferredUpdateEndTime, "DLF=D"),
			Format(UpdateInfo.DeferredUpdateEndTime, "DLF=T"));
	
	Items.OpenDeferredHandlersList.Title = MessageText;
	
	DeferredUpdateEndTime = UpdateInfo.DeferredUpdateEndTime;
	
EndProcedure

&AtServer
Function UpdateResultMessage(UpdateInfo)
	
	HandlersSuccessfullyExecuted = 0;
	TotalHandlerCount            = 0;
	For Each TreeRowLibrary In UpdateInfo.HandlersTree.Rows Do
		For Each TreeRowVersion In TreeRowLibrary.Rows Do
			TotalHandlerCount = TotalHandlerCount + TreeRowVersion.Rows.Count();
			For Each Handler In TreeRowVersion.Rows Do
				
				If Handler.Status = "Completed" Then
					HandlersSuccessfullyExecuted = HandlersSuccessfullyExecuted + 1;
				EndIf;
				
			EndDo;
		EndDo;
	EndDo;
	
	If TotalHandlerCount = HandlersSuccessfullyExecuted Then
		
		If TotalHandlerCount = 0 Then
			Items.NoDeferredHandlersInformation.Visible = True;
			Items.SwitchToDeferredHandlersListGroup.Visible = False;
			MessageText = "";
		Else
			MessageText = StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = 'Все процедуры обновления выполнены успешно (%1)'; en = 'All update procedures are completed (%1).'; pl = 'Wszystkie procedury aktualizacji zostały pomyślnie zakończone (%1)';de = 'Alle Update-Prozeduren wurden erfolgreich abgeschlossen (%1)';ro = 'Toate procedurile de actualizare sunt finalizate cu succes (%1)';tr = 'Tüm güncelleme prosedürleri başarıyla tamamlandı (%1)'; es_ES = 'Todos los procedimientos de actualización se han finalizado con éxito (%1)'"), HandlersSuccessfullyExecuted);
		EndIf;
		Items.CompletedPicture.Picture = PictureLib.Done32;
	Else
		MessageText = StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = 'Не все процедуры удалось выполнить (выполнено %1 из %2)'; en = 'Some of the update procedures are not completed (%1 out of %2 completed)'; pl = 'Nie wszystkie procedury zostały wykonane (wykonywano %1 z %2)';de = 'Nicht alle Prozeduren wurden ausgeführt (%1 wird ausgeführt von %2)';ro = 'Nu toate procedurile au fost executate (executate %1 din %2)';tr = 'Bazı prosedürler gerçekleşmedi ( %1, %2 dışında gerçekleşti)'; es_ES = 'No todos los procedimientos se han ejecutado (%1 está ejecutado de %2)'"), 
			HandlersSuccessfullyExecuted, TotalHandlerCount);
		Items.CompletedPicture.Picture = PictureLib.Error32;
	EndIf;
	Return MessageText;
	
EndFunction

&AtServer
Procedure ShowUpdateStatus(UpdateInfo, UpdateCompleted = False)
	
	CompletedHandlersCount = 0;
	TotalHandlerCount     = 0;
	For Each TreeRowLibrary In UpdateInfo.HandlersTree.Rows Do
		For Each TreeRowVersion In TreeRowLibrary.Rows Do
			TotalHandlerCount = TotalHandlerCount + TreeRowVersion.Rows.Count();
			For Each Handler In TreeRowVersion.Rows Do
				
				If Handler.Status = "Completed" Then
					CompletedHandlersCount = CompletedHandlersCount + 1;
				EndIf;
				
			EndDo;
		EndDo;
	EndDo;
	
	If TotalHandlerCount = 0 Then
		UpdateCompleted = True;
	EndIf;
	
	Items.UpdateStatusInformation.Title = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("ru = 'Выполнено: %1 из %2'; en = 'Completed: %1 out of %2.'; pl = 'Ukończone: %1 z %2';de = 'Abgeschlossen: %1 von %2';ro = 'Executate: %1 din %2';tr = 'Tamamlandı : %1''nin %2'; es_ES = 'Finalizado: %1 de %2'"),
		CompletedHandlersCount,
		TotalHandlerCount);
	
EndProcedure

&AtServer
Procedure SetDeferredUpdateSchedule(NewSchedule)
	
	JobsFilter = New Structure;
	JobsFilter.Insert("Metadata", Metadata.ScheduledJobs.DeferredIBUpdate);
	Jobs = ScheduledJobsServer.FindJobs(JobsFilter);
	
	For Each Job In Jobs Do
		JobParameters = New Structure("Schedule", NewSchedule);
		ScheduledJobsServer.ChangeJob(Job, JobParameters);
	EndDo;
	
	Schedule = NewSchedule;
	
EndProcedure

&AtClient
Procedure ChangeScheduleAfterSetUpSchedule(NewSchedule, AdditionalParameters) Export
	
	If NewSchedule <> Undefined Then
		If NewSchedule.RepeatPeriodInDay = 0 Then
			Notification = New NotifyDescription("ChangeScheduleAfterQuery", ThisObject, NewSchedule);
			
			QuestionButtons = New ValueList;
			QuestionButtons.Add("SetUpSchedule", NStr("ru = 'Настроить расписание'; en = 'Set schedule'; pl = 'Ustalić harmonogram';de = 'Zeitplan konfigurieren';ro = 'Configurați programul';tr = 'Takvimi yapılandır'; es_ES = 'Configurar el horario'"));
			QuestionButtons.Add("RecommendedSettings", NStr("ru = 'Установить рекомендуемые настройки'; en = 'Use recommended settings'; pl = 'Ustaw zalecane ustawienia';de = 'Legen Sie die empfohlenen Einstellungen fest';ro = 'Instalați setările recomandate';tr = 'Önerilen ayarları ayarla'; es_ES = 'Establecer las configuraciones recomendadas'"));
			
			MessageText = NStr("ru = 'Дополнительные процедуры обработки данных выполняются небольшими порциями,
				|поэтому для их корректной работы необходимо обязательно задать интервал повтора после завершения.
				|
				|Для этого в окне настройки расписания необходимо перейти на вкладку ""Дневное""
				|и заполнить поле ""Повторять через"".'; 
				|en = 'Additional data processing procedures are executed in small batches.
				|To have them executed correctly, specify the repeat interval.
				|
				|In the schedule settings window, click the ""Daily"" tab
				|and fill the ""Repeat in"" field.'; 
				|pl = 'Dodatkowe procedury przetwarzania danych są wykonywane niewielkimi porcjami, 
				|dlatego dla ich poprawnej pracy należy obowiązkowo ustawić interwał powtórzenia po zakończeniu. 
				|
				|W tym celu w oknie ustawienia harmonogramu należy przejść do wkładki ""Дневное""
				|i wypełnić pole ""Повторять через"".';
				|de = 'Zusätzliche Datenverarbeitungsverfahren werden in kleinen Chargen durchgeführt,
				|so dass für deren korrekte Funktion ein Wiederholungsintervall nach Abschluss angegeben werden muss.
				|
				|Gehen Sie dazu im Fenster der Zeiteinstellung auf die Registerkarte ""Tagsüber"" 
				|und füllen Sie das Feld ""Wiederholung durch"" aus.';
				|ro = 'Procedurile suplimentare de prelucrare a datelor sunt efectuate pe porțiuni mici,
				|de aceea pentru lucrul lor corect este necesară specificarea obligatorie a intervalului de repetare după finalizare.
				|
				|Pentru aceasta în fereastra de setare a orarului este necesar să mergeți în fila ""Ziua""
				|și să completați câmpul ""Repetare peste"".';
				|tr = 'Veri  işleme ek prosedürleri küçük bölümlerde 
				|yürütülür, bu nedenle doğru  çalışmaları için tamamlandıktan sonra yeniden deneme aralığını belirtmek  gerekir. 
				|
				|Bunun için program ayarı penceresinde ""Gündüz"" sekmesine gidip 
				|""Tekrarlanan"" alanı doldurmanız gerekmektedir.'; 
				|es_ES = 'Procedimientos adicionales del procesamiento de datos se han ejecutado en las pequeñas porciones,
				| así que para su correcto trabajo, se requiere especificar el intervalo de intentos después de la finalización.
				|
				|Para eso, en la ventana de la configuración del horario, se requiere ir a la pestaña ""Diario""
				|y rellenar ""Repitiendo a través"" archivado.'");
			ShowQueryBox(Notification, MessageText, QuestionButtons,, "SetUpSchedule");
		Else
			SetDeferredUpdateSchedule(NewSchedule);
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure ChangeScheduleAfterQuery(Result, NewSchedule) Export
	
	If Result = "RecommendedSettings" Then
		NewSchedule.RepeatPeriodInDay = 60;
		NewSchedule.RepeatPause = 60;
		SetDeferredUpdateSchedule(NewSchedule);
	Else
		NotifyDescription = New NotifyDescription("ChangeScheduleAfterSetUpSchedule", ThisObject);
		Dialog = New ScheduledJobDialog(NewSchedule);
		Dialog.Show(NotifyDescription);
	EndIf;
	
EndProcedure

&AtServer
Procedure ProcessUpdateResultAtServer()
	
	Items.InstalledPatchesGroup.Visible = False;
	// If it is the first start after a configuration update, storing and resetting status.
	If Common.SubsystemExists("StandardSubsystems.ConfigurationUpdate") Then
		PatchInfo = Undefined;
		ModuleSoftwareUpdate = Common.CommonModule("ConfigurationUpdate");
		ModuleSoftwareUpdate.CheckUpdateStatus(UpdateResult, ScriptDirectory, PatchInfo);
		ProcessPatchInstallResult(PatchInfo);
	EndIf;
	
	If IsBlankString(ScriptDirectory) Then 
		Items.InformationForTechnicalSupport.Visible = False;
	EndIf;
	
EndProcedure

&AtServer
Procedure ProcessPatchInstallResult(PatchInfo)
	
	If TypeOf(PatchInfo) <> Type("Structure") Then
		Return;
	EndIf;
	
	TotalPatchCount = PatchInfo.TotalPatchCount;
	If TotalPatchCount = 0 Then
		Return;
	EndIf;
	
	Items.InstalledPatchesGroup.Visible = True;
	Patches.LoadValues(PatchInfo.Installed);
	
	If PatchInfo.NotInstalled > 0 Then
		InstalledSuccessfully = TotalPatchCount - PatchInfo.NotInstalled;
		Ref = New FormattedString(NStr("ru = 'Не удалось установить исправления'; en = 'Cannot install the patches'; pl = 'Nie udało się ustawić korekty';de = 'Korrekturen konnten nicht installiert werden';ro = 'Eșec la instalarea corectărilor';tr = 'Düzeltme yüklenemez'; es_ES = 'No se ha podido establecer las correcciones'"),,,, "UnsuccessfulInstallation");
		PatchesLabel = StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = '(%1 из %2)'; en = '(%1 out of %2).'; pl = '(%1 z %2)';de = '(%1 aus %2)';ro = '(%1 din %2)';tr = '(%1''nin %2)'; es_ES = '(%1 de %2)'"), InstalledSuccessfully, TotalPatchCount);
		PatchesLabel = New FormattedString(Ref, " ", PatchesLabel);
		Items.InstalledPatchesGroup.CurrentPage = Items.PatchesInstallationErrorGroup;
		Items.PatchesErrorInformation.Title = PatchesLabel;
	Else
		Ref = New FormattedString(NStr("ru = 'Исправления (патчи)'; en = 'The patches'; pl = 'Korekty (łaty)';de = 'Korrekturen (Patches)';ro = 'Corectările (patch-urile)';tr = 'Düzeltmeler (yamalar)'; es_ES = 'Correcciones (parches)'"),,,, "InstalledPatches");
		PatchesLabel = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'успешно установлены (%1)'; en = 'are installed (%1).'; pl = 'pomyślnie zainstalowano (%1)';de = 'erfolgreich installiert (%1)';ro = 'sunt instalate cu succes (%1)';tr = 'başarı ile belirlendi (%1)'; es_ES = 'instalados con éxito (%1)'"), TotalPatchCount);
		PatchesLabel = New FormattedString(Ref, " ", PatchesLabel);
		Items.PatchesInstalledInformation.Title = PatchesLabel;
	EndIf;
	
EndProcedure

&AtClient
Procedure ProcessUpdateResultAtClient()
	
	If UpdateResult <> Undefined
		AND CommonClient.SubsystemExists("StandardSubsystems.ConfigurationUpdate") Then
		
		ModuleSoftwareUpdateClient = CommonClient.CommonModule("ConfigurationUpdateClient");
		ModuleSoftwareUpdateClient.ProcessUpdateResult(UpdateResult, ScriptDirectory);
		If UpdateResult = False Then
			Items.UpdateResultsGroup.CurrentPage = Items.UpdateErrorGroup;
			// If the configuration is not updated, the deferred handlers are also not executed.
			Items.UpdateStatus.Visible = False;
			Items.WhereToFindThisFormHint.Visible = False;
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure ShowInstalledPatches()
	
	If CommonClient.SubsystemExists("StandardSubsystems.ConfigurationUpdate") Then
		ModuleSoftwareUpdateClient = CommonClient.CommonModule("ConfigurationUpdateClient");
		ModuleSoftwareUpdateClient.ShowInstalledPatches(Patches);
	EndIf;
	
EndProcedure

&AtServer
Procedure GetInfobaseUpdateThreadsCount()
	
	If AccessRight("Read", Metadata.Constants.InfobaseUpdateThreadCount) Then
		InfobaseUpdateThreadCount =
			InfobaseUpdateInternal.InfobaseUpdateThreadCount();
	EndIf;
	
EndProcedure

&AtClientAtServerNoContext
Procedure SetAvailabilityForInfobaseUpdateThreadsCount(Form)
	
	Available = (Form.UpdatePriority = "DataProcessing");
	Form.Items.InfobaseUpdateThreadCount.Enabled = Available;
	
EndProcedure

&AtServer
Procedure SetVisibilityForInfobaseUpdateThreadsCount()
	
	MultithreadUpdateAllowed = InfobaseUpdateInternal.MultithreadUpdateAllowed();
	Items.InfobaseUpdateThreadCount.Visible = MultithreadUpdateAllowed;
	
	If MultithreadUpdateAllowed Then
		Items.UpdatePriority.ToolTipRepresentation = ToolTipRepresentation.None;
	Else
		Items.UpdatePriority.ToolTipRepresentation = ToolTipRepresentation.Button;
	EndIf;
	
EndProcedure

#EndRegion
