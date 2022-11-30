///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Variables

&AtClient
Var AdministrationParameters, CurrentLockValue;

#EndRegion

#Region EventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	SetConditionalAppearance();
	
	If Common.SubsystemExists("StandardSubsystems.SaaS") Then
		ModuleSaaS = Common.CommonModule("SaaS");
		SessionWithoutSeparators = ModuleSaaS.SessionWithoutSeparators();
	Else
		SessionWithoutSeparators = True;
	EndIf;
	
	IsFileInfobase = Common.FileInfobase();
	IsSystemAdministrator = Users.IsFullUser(, True);
	
	If IsFileInfobase Or Not IsSystemAdministrator Then
		Items.DisableScheduledJobsGroup.Visible = False;
	EndIf;
	
	If Common.DataSeparationEnabled() Or Not IsSystemAdministrator Then
		Items.UnlockCode.Visible = False;
	EndIf;
	
	SetInitialUserAuthorizationRestrictionStatus();
	RefreshSettingsPage();
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	ClientConnectedOverWebServer = CommonClient.ClientConnectedOverWebServer();
	If IBConnectionsClient.SessionTerminationInProgress() Then
		Items.ModeGroup.CurrentPage = Items.LockStatePage;
		RefreshStatePage(ThisObject);
	EndIf;
	
EndProcedure

&AtServer
Procedure FillCheckProcessingAtServer(Cancel, CheckedAttributes)
	
	BlockingSessionsInformation = IBConnections.BlockingSessionsInformation(NStr("ru = 'Блокировка не установлена.'; en = 'The lock is not set.'; pl = 'Nie zablokowany.';de = 'Nicht verschlossen.';ro = 'Blocarea nu este instalată.';tr = 'Kilitlenmedi.'; es_ES = 'No bloqueado.'"));
	
	If BlockingSessionsInformation.HasBlockingSessions Then
		Raise BlockingSessionsInformation.MessageText;
	EndIf;
	
	SessionCount = BlockingSessionsInformation.SessionCount;
	
	// Checking if a lock can be set.
	If Object.LockEffectiveFrom > Object.LockEffectiveTo 
		AND ValueIsFilled(Object.LockEffectiveTo) Then
		Common.MessageToUser(
			NStr("ru = 'Дата окончания блокировки не может быть меньше даты начала блокировки. Блокировка не установлена.'; en = 'Cannot set a lock. The end date cannot be earlier than the start date.'; pl = 'Data zakończenia blokady nie może być wcześniejsza niż data rozpoczęcia blokady. Blokada nie jest ustawiona.';de = 'Das Enddatum der Sperre darf nicht vor dem Startdatum der Sperre liegen. Sperre ist nicht eingestellt.';ro = 'Blocarea datei de încheiere nu poate fi mai devreme decât data de începere a blocării. Blocarea nu este setată.';tr = 'Kilit bitiş tarihi, kilit başlangıç tarihinden önce olamaz. Kilit ayarlanmamış.'; es_ES = 'Bloqueo de la fecha final no puede ser antes del bloqueo de la fecha inicial. Bloqueo no está establecido.'"),,
			"Object.LockEffectiveTo",,Cancel);
		Return;
	EndIf;
	
	If Not ValueIsFilled(Object.LockEffectiveFrom) Then
		Common.MessageToUser(
			NStr("ru = 'Не указана дата начала блокировки.'; en = 'Please select the start date.'; pl = 'Data rozpoczęcia blokady nie została określona.';de = 'Startdatum der Sperre ist nicht angegeben.';ro = 'Data de începere a blocării nu este specificată.';tr = 'Kilit başlangıç tarihi belirtilmemiş.'; es_ES = 'Fecha inicial del bloqueo no está especificada.'"),, "Object.LockEffectiveFrom",,Cancel);
		Return;
	EndIf;
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If EventName = "UserSessionsCompletion" Then
		SessionCount = Parameter.SessionCount;
		UpdateLockState(ThisObject);
		If Parameter.Status = "Finish" Then
			Close();
		ElsIf Parameter.Status = "Error" Then
			ShowMessageBox(,NStr("ru = 'Не удалось завершить работу всех активных пользователей.
				|Подробности см. в Журнале регистрации.'; 
				|en = 'Cannot close all active user sessions.
				|For more information, see the event log.'; 
				|pl = 'Nie udało się zamknąć wszystkich aktywnych użytkowników.
				|Szczegółowe informacje zawiera dziennik.';
				|de = 'Es war nicht möglich, alle aktiven Benutzer abzuschalten.
				|Siehe Ereignisprotokoll für Details.';
				|ro = 'Eșec la finalizarea lucrului tuturor utilizatorilor activi.
				|Detalii vezi în Registrul logare.';
				|tr = 'Tüm aktif kullanıcıların oturumları sonlandırılamaz. 
				|Olay günlüğündeki ayrıntıları arayın.'; 
				|es_ES = 'No se puede finalizar las sesiones de todos usuarios activos.
				|Buscar los detalles en el Registro de eventos.'"), 30);
			Close();
		EndIf;
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandHandlers

&AtClient
Procedure ActiveUsers(Command)
	
	OpenForm("DataProcessor.ActiveUsers.Form",, ThisObject);
	
EndProcedure

&AtClient
Procedure Apply(Command)
	
	ClearMessages();
	
	Object.DisableUserAuthorisation = Not InitialUserAuthorizationRestrictionStatusValue;
	If Object.DisableUserAuthorisation Then
		
		SessionCount = 1;
		Try
			If Not CheckLockPreconditions() Then
				Return;
			EndIf;
		Except
			CommonClient.MessageToUser(BriefErrorDescription(ErrorInfo()));
			Return;
		EndTry;
		
		QuestionTitle = NStr("ru = 'Блокировка работы пользователей'; en = 'Deny user access'; pl = 'Blokowanie operacji użytkownika';de = 'Sperrung der Benutzerbedienung';ro = 'Blocarea lucrului utilizatorilor';tr = 'Kullanıcı operasyon kilitleme'; es_ES = 'Bloqueo de la operación del usuario'");
		If SessionCount > 1 AND Object.LockEffectiveFrom < CommonClient.SessionDate() + 5 * 60 Then
			QuestionText = NStr("ru = 'Указано слишком близкое время начала действия блокировки, к которому пользователи могут не успеть сохранить все свои данные и завершить работу.
				|Рекомендуется установить время начала на 5 минут относительно текущего времени.'; 
				|en = 'The period before applying the lock is too short. Users might not have enough time to save their data.
				|It is recommended that you give them at least 5 minutes.'; 
				|pl = 'Ustawiono zbyt wczesny czas rozpoczęcia blokowania, użytkownicy mogą mieć za mało czasu, aby zapisać wszystkie swoje dane i zakończyć sesje.
				|Zaleca się ustawienie czasu rozpoczęcia na 5 minut później od bieżącego czasu.';
				|de = 'Zu frühe Startzeit der Blockierung ist festgelegt, Benutzer haben möglicherweise nicht genügend Zeit, alle ihre Daten zu speichern und ihre Sitzungen zu beenden.
				|Es wird empfohlen, die Startzeit 5 Minuten später als die aktuelle Uhrzeit einzustellen.';
				|ro = 'Este indicată ora prea apropiată a începutului blocării, către care utilizatorii nu vor reuși să-și salveze toate datele și să finalizeze sesiunile. 
				| Se recomandă setarea orei începutului cu 5 minute mai târziu decât ora curentă.';
				|tr = 'Engellemenin  çok erken başlama zamanı ayarlanmışsa, kullanıcılar tüm verilerini  kaydetme ve oturumlarını sonlandırma için yeterli zamana sahip  olmayabilir. 
				|Başlangıç saatinden 5 dakika sonra başlangıç zamanının ayarlanması önerilir.'; 
				|es_ES = 'La hora demasiado temprana de inicio está establecida, puede ser que los usuarios no tengan suficiente tiempo para guardar todos sus datos y finalizar sus sesiones.
				|Se recomienda establecer la hora de inicio 5 minutos después de la hora actual.'");
			Buttons = New ValueList;
			Buttons.Add(DialogReturnCode.Yes, NStr("ru = 'Заблокировать через 5 минут'; en = 'Lock in 5 minutes'; pl = 'Zablokować po upływie 5 minut';de = 'Blockieren in 5 Minuten';ro = 'Blocare peste 5 minute';tr = '5 dakika içinde kilitleme'; es_ES = 'Bloquear en 5 minutos'"));
			Buttons.Add(DialogReturnCode.No, NStr("ru = 'Заблокировать сейчас'; en = 'Lock now'; pl = 'Zablokować teraz';de = 'Jetzt sperren';ro = 'Bloca acum';tr = 'Şimdi kilitle'; es_ES = 'Bloquear ahora'"));
			Buttons.Add(DialogReturnCode.Cancel, NStr("ru = 'Отмена'; en = 'Cancel'; pl = 'Anuluj';de = 'Abbrechen';ro = 'Revocare';tr = 'İptal'; es_ES = 'Cancelar'"));
			Notification = New NotifyDescription("ApplyCompletion", ThisObject, "LockTimeTooSoon");
			ShowQueryBox(Notification, QuestionText, Buttons,,, QuestionTitle);
		ElsIf Object.LockEffectiveFrom > CommonClient.SessionDate() + 60 * 60 Then
			QuestionText = NStr("ru = 'Указано слишком большое время начала действия блокировки (более, чем через час).
				|Запланировать блокировку на указанное время?'; 
				|en = 'The period before applying the lock is too long (more than an hour).
				|Do you want to schedule the lock for this time?'; 
				|pl = 'Czas rozpoczęcia blokowania jest zbyt późny (ponad godzina).
				|Czy chcesz zaplanować blokowanie na określony czas?';
				|de = 'Die Blockierungszeit ist zu spät (mehr als in einer Stunde).
				|Möchten Sie die Sperrung für die angegebene Zeit planen?';
				|ro = 'Este indicat timpul prea mare a începutului blocării (mai mult de o oră).
				|Doriți să programați blocarea pentru ora specificată?';
				|tr = 'Engellemenin statü süresi çok geç (bir saatten fazla). 
				|Belirtilen süre için kilitlemeyi programlamak ister misiniz?'; 
				|es_ES = 'Fecha de inicio del bloqueo es demasiado tarde (más de en una hora).
				|¿Quiere programar el bloqueo para la hora especificada?'");
			Buttons = New ValueList;
			Buttons.Add(DialogReturnCode.No, NStr("ru = 'Запланировать'; en = 'Schedule'; pl = 'Zaplanuj';de = 'Planen';ro = 'Programare';tr = 'Planla'; es_ES = 'Planear'"));
			Buttons.Add(DialogReturnCode.Yes, NStr("ru = 'Заблокировать сейчас'; en = 'Lock now'; pl = 'Zablokować teraz';de = 'Jetzt sperren';ro = 'Bloca acum';tr = 'Şimdi kilitle'; es_ES = 'Bloquear ahora'"));
			Buttons.Add(DialogReturnCode.Cancel, NStr("ru = 'Отмена'; en = 'Cancel'; pl = 'Anuluj';de = 'Abbrechen';ro = 'Revocare';tr = 'İptal'; es_ES = 'Cancelar'"));
			Notification = New NotifyDescription("ApplyCompletion", ThisObject, "LockTimeTooLate");
			ShowQueryBox(Notification, QuestionText, Buttons,,, QuestionTitle);
		Else
			If Object.LockEffectiveFrom - CommonClient.SessionDate() > 15*60 Then
				QuestionText = NStr("ru = 'Завершение работы всех активных пользователей будет произведено в период с %1 по %2.
					|Продолжить?'; 
					|en = 'All active user sessions will be closed from %1 to %2.
					|Do you want to continue?'; 
					|pl = 'Sesje wszystkich aktywnych użytkowników zostaną zakończone w okresie od %1do %2.
					|Kontynuować?';
					|de = 'Sitzungen aller aktiven Benutzer werden während des Zeitraums von %1 bis %2 beendet.
					|Fortfahren?';
					|ro = 'Sesiunile tuturor utilizatorilor activi vor fi finalizate în perioada de la %1 până la %2.
					|Continuați?';
					|tr = 'Tüm aktif kullanıcıların oturumları  %1''den %2 kadar olan süre içinde sonlandırılacak. 
					|Devam et?'; 
					|es_ES = 'Sesiones de todos usuarios activos se finalizarán durante el período desde %1 hasta %2.
					|¿Continuar?'");
			Else
				QuestionText = NStr("ru = 'Сеансы всех активных пользователей будут завершены к %2.
					|Продолжить?'; 
					|en = 'All active user sessions will be closed by %2.
					|Do you want to continue?'; 
					|pl = 'Sesje wszystkich aktywnych użytkowników zostaną zakończone o %2.
					|Kontynuować?';
					|de = 'Sitzungen aller aktiven Benutzer werden durch %2 beendet.
					|Fortsetzen?';
					|ro = 'Sesiunile tuturor utilizatorilor activi vor fi finalizate către %2.
					|Continuați?';
					|tr = 'Tüm aktif kullanıcıların oturumları %2 tarafından sonlandırılacak. 
					|Devam etmek istiyor musunuz?'; 
					|es_ES = 'Sesiones de todos usuarios activos se finalizarán antes de %2.
					|¿Continuar?'");
			EndIf;
			Notification = New NotifyDescription("ApplyCompletion", ThisObject, "ConfirmPassword");
			QuestionText = StringFunctionsClientServer.SubstituteParametersToString(QuestionText, Object.LockEffectiveFrom - 900, Object.LockEffectiveFrom);
			ShowQueryBox(Notification, QuestionText, QuestionDialogMode.OKCancel,,, QuestionTitle);
		EndIf;
		
	Else
		
		Notification = New NotifyDescription("ApplyCompletion", ThisObject, "ConfirmPassword");
		ExecuteNotifyProcessing(Notification, DialogReturnCode.OK);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure ApplyCompletion(Response, Option) Export
	
	If Option = "LockTimeTooSoon" Then
		If Response = DialogReturnCode.Yes Then
			Object.LockEffectiveFrom = CommonClient.SessionDate() + 5 * 60;
		ElsIf Response <> DialogReturnCode.No Then
			Return;
		EndIf;
	ElsIf Option = "LockTimeTooLate" Then
		If Response = DialogReturnCode.Yes Then
			Object.LockEffectiveFrom = CommonClient.SessionDate() + 5 * 60;
		ElsIf Response <> DialogReturnCode.No Then
			Return;
		EndIf;
	ElsIf Option = "ConfirmPassword" Then
		If Response <> DialogReturnCode.OK Then
			Return;
		EndIf;
	EndIf;
	
	If CorrectAdministrationParametersEntered AND IsSystemAdministrator AND Not IsFileInfobase
		AND CurrentLockValue <> Object.DisableScheduledJobs Then
		
		Try
			SetScheduledJobLockAtServer(AdministrationParameters);
		Except
			EventLogClient.AddMessageForEventLog(IBConnectionsClient.EventLogEvent(), "Error",
				DetailErrorDescription(ErrorInfo()),, True);
			Items.ErrorGroup.Visible = True;
			Items.ErrorText.Title = BriefErrorDescription(ErrorInfo());
			Return;
		EndTry;
		
	EndIf;
	
	If Not IsFileInfobase AND Not CorrectAdministrationParametersEntered AND SessionWithoutSeparators Then
		
		NotifyDescription = New NotifyDescription("AfterGetAdministrationParametersOnLock", ThisObject);
		FormHeader = NStr("ru = 'Управление блокировкой сеансов'; en = 'User sessions'; pl = 'Zarządzanie blokowaniem sesji';de = 'Sitzungssperrverwaltung';ro = 'Gestionarea blocării sesiunii';tr = 'Oturum kilitleme yönetimi'; es_ES = 'Gestión de bloqueo de sesiones'");
		NoteLabel = NStr("ru = 'Для управления блокировкой сеансов необходимо ввести
			|параметры администрирования кластера серверов и информационной базы'; 
			|en = 'To manage user sessions, please enter
			|the infobase and server cluster administration parameters.'; 
			|pl = 'Aby zarządzać blokowaniem sesji, musisz wprowadzić
			| klaster serwera i parametry administracyjne bazy informacyjnej';
			|de = 'Um die Sitzungssperre zu verwalten, ist es notwendig, 
			|die Parameter des Server-Clusters und der Datenbankverwaltung einzugeben';
			|ro = 'Pentru gestionarea blocării sesiunilor trebuie să introduceți
			|parametrii de administrare a clusterului serverelor și bazei de date';
			|tr = 'Oturum kilidi yönetimi için sunucu kümesinin 
			|ve bilgi tabanlarının yönetim parametrelerini girmek gerekir'; 
			|es_ES = 'Para la gestión de bloqueo de sesiones es necesario introducir
			|los parámetros de administración del clúster del servidor y las infobases'");
		IBConnectionsClient.ShowAdministrationParameters(NotifyDescription, True,
			True, AdministrationParameters, FormHeader, NoteLabel);
		
	Else
		
		AfterGetAdministrationParametersOnLock(True, Undefined);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure Stop(Command)
	
	If Not IsFileInfobase AND Not CorrectAdministrationParametersEntered AND SessionWithoutSeparators Then
		
		NotifyDescription = New NotifyDescription("AfterGetAdministrationParametersOnUnlock", ThisObject);
		FormHeader = NStr("ru = 'Управление блокировкой сеансов'; en = 'User sessions'; pl = 'Zarządzanie blokowaniem sesji';de = 'Sitzungssperrverwaltung';ro = 'Gestionarea blocării sesiunii';tr = 'Oturum kilitleme yönetimi'; es_ES = 'Gestión de bloqueo de sesiones'");
		NoteLabel = NStr("ru = 'Для управления блокировкой сеансов необходимо ввести
			|параметры администрирования кластера серверов и информационной базы'; 
			|en = 'To manage user sessions, please enter
			|the infobase and server cluster administration parameters.'; 
			|pl = 'Aby zarządzać blokowaniem sesji, musisz wprowadzić
			| klaster serwera i parametry administracyjne bazy informacyjnej';
			|de = 'Um die Sitzungssperre zu verwalten, ist es notwendig, 
			|die Parameter des Server-Clusters und der Datenbankverwaltung einzugeben';
			|ro = 'Pentru gestionarea blocării sesiunilor trebuie să introduceți
			|parametrii de administrare a clusterului serverelor și bazei de date';
			|tr = 'Oturum kilidi yönetimi için sunucu kümesinin 
			|ve bilgi tabanlarının yönetim parametrelerini girmek gerekir'; 
			|es_ES = 'Para la gestión de bloqueo de sesiones es necesario introducir
			|los parámetros de administración del clúster del servidor y las infobases'");
		IBConnectionsClient.ShowAdministrationParameters(NotifyDescription, True,
			True, AdministrationParameters, FormHeader, NoteLabel);
		
	Else
		
		AfterGetAdministrationParametersOnUnlock(True, Undefined);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure AdministrationParameters(Command)
	
	NotifyDescription = New NotifyDescription("AfterGetAdministrationParameters", ThisObject);
	FormHeader = NStr("ru = 'Управление блокировкой регламентных заданий'; en = 'Scheduled job locks'; pl = 'Harmonogram zarządzania blokowaniem zadań';de = 'Geplante Auftragssperre';ro = 'Programul blocării locurilor de muncă';tr = 'Zamanlanmış iş kilidi yönetimi'; es_ES = 'Gestión de bloqueo de tareas programadas'");
	NoteLabel = NStr("ru = 'Для управления блокировкой регламентных заданий необходимо
		|ввести параметры администрирования кластера серверов и информационной базы'; 
		|en = 'To manage scheduled jobs locks, please enter
		|the infobase and server cluster administration parameters.'; 
		|pl = 'Aby kontrolować blokowanie zaplanowanych zadań, należy
		|wprowadzić klaster serwerów i parametry administracyjne bazy informacyjnej';
		|de = 'Um das Blockieren von Routineaufgaben zu verwalten, ist es notwendig, 
		|die Parameter für die Verwaltung des Serverclusters und der Informationsbasis einzugeben';
		|ro = 'Pentru gestionarea blocării sarcinilor reglementare trebuie să
		|introduceți parametrii de administrare a clusterului serverelor și bazei de date';
		|tr = 'Zamanlanmış işler yönetimi için sunucu kümesinin 
		|ve veritabanlarının yönetim parametrelerini girmek gerekir'; 
		|es_ES = 'Para gestión de bloqueo de tareas programadas es necesario
		|introducir los parámetros de administración del clúster del servidor y las infobases'");
	IBConnectionsClient.ShowAdministrationParameters(NotifyDescription, True,
		True, AdministrationParameters, FormHeader, NoteLabel);
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SetConditionalAppearance()

	ConditionalAppearance.Items.Clear();

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.InitialUserAuthorizationRestrictionStatus.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("UsersAuthorizationRestrictionStatus");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = NStr("ru = 'Запрещено'; en = 'Denied'; pl = 'Zabronione';de = 'Verboten';ro = 'Interzis';tr = 'Yasak'; es_ES = 'Prohibido'");

	Item.Appearance.SetParameterValue("TextColor", StyleColors.ErrorNoteText);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.InitialUserAuthorizationRestrictionStatus.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("UsersAuthorizationRestrictionStatus");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = NStr("ru = 'Запланировано'; en = 'Scheduled'; pl = 'Kwota planowana';de = 'Geplant';ro = 'Programat';tr = 'Planlanmış'; es_ES = 'Planificado'");

	Item.Appearance.SetParameterValue("TextColor", StyleColors.ErrorNoteText);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.InitialUserAuthorizationRestrictionStatus.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("UsersAuthorizationRestrictionStatus");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = NStr("ru = 'Истекло'; en = 'Expired'; pl = 'Przedawnione';de = 'Abgelaufen';ro = 'Restanțe';tr = 'Süresi bitmiş'; es_ES = 'Caducado'");

	Item.Appearance.SetParameterValue("TextColor", StyleColors.LockedAttributeColor);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.InitialUserAuthorizationRestrictionStatus.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("UsersAuthorizationRestrictionStatus");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = NStr("ru = 'Разрешено'; en = 'Allowed'; pl = 'Dozwolone';de = 'Erlauben';ro = 'Permis';tr = 'İzin verilen'; es_ES = 'Permitido'");

	Item.Appearance.SetParameterValue("TextColor", StyleColors.FormTextColor);

EndProcedure

&AtServer
Function CheckLockPreconditions()
	
	Return CheckFilling();

EndFunction

&AtServer
Function LockUnlock()
	
	Try
		FormAttributeToValue("Object").SetLock();
		Items.ErrorGroup.Visible = False;
	Except
		WriteLogEvent(IBConnections.EventLogEvent(),
			EventLogLevel.Error,,, 
			DetailErrorDescription(ErrorInfo()));
		If IsSystemAdministrator Then
			Items.ErrorGroup.Visible = True;
			Items.ErrorText.Title = BriefErrorDescription(ErrorInfo());
		EndIf;
		Return False;
	EndTry;
	
	SetInitialUserAuthorizationRestrictionStatus();
	SessionCount = IBConnections.InfobaseSessionCount();
	Return True;
	
EndFunction

&AtServer
Function CancelLock()
	
	Try
		FormAttributeToValue("Object").CancelLock();
	Except
		WriteLogEvent(IBConnections.EventLogEvent(),
			EventLogLevel.Error,,, 
			DetailErrorDescription(ErrorInfo()));
		If IsSystemAdministrator Then
			Items.ErrorGroup.Visible = True;
			Items.ErrorText.Title = BriefErrorDescription(ErrorInfo());
		EndIf;
		Return False;
	EndTry;
	
	SetInitialUserAuthorizationRestrictionStatus();
	Items.ModeGroup.CurrentPage = Items.SettingsPage;
	RefreshSettingsPage();
	Return True;
	
EndFunction

&AtServer
Procedure RefreshSettingsPage()
	
	Items.DisableScheduledJobsGroup.Enabled = True;
	Items.ApplyCommand.Visible = True;
	Items.ApplyCommand.DefaultButton = True;
	Items.StopCommand.Visible = False;
	Items.ApplyCommand.Title = ?(Object.DisableUserAuthorisation,
		NStr("ru='Снять блокировку'; en = 'Remove lock'; pl = 'Odblokuj';de = 'Freischalten';ro = 'Deblocare';tr = 'Blokeyi kaldır'; es_ES = 'Desbloquear'"), NStr("ru='Установить блокировку'; en = 'Set lock'; pl = 'Blokuj';de = 'Sperren';ro = 'Blocare';tr = 'Kilitle'; es_ES = 'Bloquear'"));
	Items.DisableScheduledJobs.Title = ?(Object.DisableScheduledJobs,
		NStr("ru='Оставить блокировку работы регламентных заданий'; en = 'Keep scheduled job locks'; pl = 'Zachowaj operacje zaplanowanych zadań';de = 'Halten Sie die Sperren geplanter Jobs fest';ro = 'Menține blocarea lucrului sarcinilor reglementare';tr = 'Zamanlanmış işlerin kilitleme işlemlerini sürdürün'; es_ES = 'Guardar las operaciones de bloqueo de las tareas programadas'"), NStr("ru='Также запретить работу регламентных заданий'; en = 'Lock scheduled jobs'; pl = 'Wyłącz również zaplanowane zadania';de = 'Deaktivieren Sie auch geplante Aufträge';ro = 'De asemenea, dezactivați operațiile programate';tr = 'Ayrıca planlanan işleri de devre dışı bırak'; es_ES = 'También desactivar las tareas programadas'"));
	
EndProcedure

&AtClientAtServerNoContext
Procedure RefreshStatePage(Form)
	
	Form.Items.DisableScheduledJobsGroup.Enabled = False;
	Form.Items.StopCommand.Visible = True;
	Form.Items.ApplyCommand.Visible = False;
	Form.Items.CloseCommand.DefaultButton = True;
	UpdateLockState(Form);
	
EndProcedure

&AtClientAtServerNoContext
Procedure UpdateLockState(Form)
	
	If Form.SessionCount = 0 Then
		
		StateText = NStr("ru='Ожидается установка блокировки...
			|Работа пользователей в программе будет запрещена в указанное время'; 
			|en = 'Lock pending...
			|Users will be unable to use the application during the lock period.'; 
			|pl = 'Blokada jest w toku...
			|Użytkownicy zostaną zablokowani w programie o określonej godzinie';
			|de = 'Sperre ausstehend...
			|Die Arbeit von Benutzern im Programm wird zu dem angegebenen Zeitpunkt verboten';
			|ro = 'Se așteaptă blocarea...
			|Lucrul utilizatorilor în program va fi interzis la ora indicată';
			|tr = 'Kilitleme bekleniyor...
			|Programdaki kullanıcıların çalışması belirtilen zamanda  yasaklanacak'; 
			|es_ES = 'Se está esperando la instalación del bloqueo...
			|El trabajo de usuarios en el programa será prohibido en el tiempo indicado'");
		
	Else
		
		StateText = StringFunctionsClientServer.SubstituteParametersToString(NStr("ru='Пожалуйста, подождите...
			|Работа пользователей завершается. Осталось активных сеансов: %1'; 
			|en = 'Please wait...
			|Closing user sessions. Active sessions remaining: %1.'; 
			|pl = 'Proszę czekać...
			|Użytkownicy się wyłączają. Pozostały aktywne sesje: %1';
			|de = 'Bitte warten Sie...
			|Die Arbeit der Benutzer ist beendet. Es sind noch aktive Sitzungen vorhanden: %1';
			|ro = 'Așteptați...
			|Are loc finalizarea lucrului utilizatorilor. Sesiuni active rămase: %1';
			|tr = 'Lütfen bekleyin ... 
			|Kullanıcı işlemi sonlandırıldı. Kalan aktif oturumlar: %1'; 
			|es_ES = 'Por favor, espere...
			|El trabajo de usuarios se ha finalizado. Quedan las sesiones activas: %1'"),
			Form.SessionCount);
			
	EndIf;
	
	Form.Items.State.Title = StateText;
	
EndProcedure

&AtServer
Procedure GetLockParameters()
	DataProcessor = FormAttributeToValue("Object");
	Try
		DataProcessor.GetLockParameters();
		Items.ErrorGroup.Visible = False;
	Except
		WriteLogEvent(IBConnections.EventLogEvent(),
			EventLogLevel.Error,,, 
			DetailErrorDescription(ErrorInfo()));
		If IsSystemAdministrator Then
			Items.ErrorGroup.Visible = True;
			Items.ErrorText.Title = BriefErrorDescription(ErrorInfo());
		EndIf;
	EndTry;
	
	ValueToFormAttribute(DataProcessor, "Object");
	
EndProcedure

&AtServer
Procedure SetInitialUserAuthorizationRestrictionStatus()
	
	GetLockParameters();
	
	InitialUserAuthorizationRestrictionStatusValue = Object.DisableUserAuthorisation;
	If Object.DisableUserAuthorisation Then
		If CurrentSessionDate() < Object.LockEffectiveFrom Then
			InitialUserAuthorizationRestrictionStatus = NStr("ru = 'Работа пользователей в программе будет запрещена в указанное время'; en = 'Users will be denied access to the application at the specified time.'; pl = 'Operacje użytkownika w aplikacji zostaną zabronione w określonym czasie';de = 'Die Benutzerbedienung in der Anwendung wird zur angegebenen Zeit verboten';ro = 'Lucrul utilizatorilor în program va fi interzisă la ora specificată';tr = 'Uygulamada kullanıcı işlemi belirtilen zamanda yasaklanacaktır'; es_ES = 'Operación de usuario en la aplicación estará prohibida en la hora especificada'");
			UsersAuthorizationRestrictionStatus = "Scheduled";
		ElsIf CurrentSessionDate() > Object.LockEffectiveTo AND Object.LockEffectiveTo <> '00010101' Then
			InitialUserAuthorizationRestrictionStatus = NStr("ru = 'Работа пользователей в программе разрешена (истек срок запрета)'; en = 'Users are allowed to sign in to the application (the lock has expired).'; pl = 'Operacje użytkownika w aplikacji są dozwolone (czas zakazu dobiegł końca)';de = 'Benutzerbedienung in der Anwendung ist erlaubt (Sperrfrist ist abgelaufen)';ro = 'Lucrul utilizatorilor în program este permis (perioada de interdicție s-a scurs)';tr = 'Uygulamada kullanıcı işlemine izin verilir (yasak süresi sona ermiştir)'; es_ES = 'Operación de usuario en la aplicación está permitida (período de prohibición se ha acabado)'");;
			UsersAuthorizationRestrictionStatus = "Expired";
		Else
			InitialUserAuthorizationRestrictionStatus = NStr("ru = 'Работа пользователей в программе запрещена'; en = 'Users are denied access to the application.'; pl = 'Operacje użytkownika w aplikacji są zabronione';de = 'Benutzerbedienung in der Anwendung ist untersagt';ro = 'Lucrul utilizatorilor în program este interzis';tr = 'Uygulamada kullanıcı işlemi yasaktır'; es_ES = 'Operación de usuario en la aplicación está prohibida'");
			UsersAuthorizationRestrictionStatus = "Denied";
		EndIf;
	Else
		InitialUserAuthorizationRestrictionStatus = NStr("ru = 'Работа пользователей в программе разрешена'; en = 'Users are allowed access to the application.'; pl = 'Operacje użytkownika w aplikacji są dozwolone';de = 'Benutzerbedienung in der Anwendung ist erlaubt';ro = 'Lucrul utilizatorilor în program este permis';tr = 'Uygulamada kullanıcı işlemine izin verilir'; es_ES = 'Operación de usuario en la aplicación está permitida'");
		UsersAuthorizationRestrictionStatus = "Allowed";
	EndIf;
	
EndProcedure

&AtClient
Procedure AfterGetAdministrationParameters(Result, AdditionalParameters) Export
	
	If Result <> Undefined Then
		
		AdministrationParameters = Result;
		CorrectAdministrationParametersEntered = True;
		
		Try
			Object.DisableScheduledJobs = InfobaseScheduledJobLockAtServer(AdministrationParameters);
			CurrentLockValue = Object.DisableScheduledJobs;
		Except;
			CorrectAdministrationParametersEntered = False;
			Raise;
		EndTry;
		
		Items.DisableScheduledJobsGroup.CurrentPage = Items.ScheduledJobManagementGroup;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure AfterGetAdministrationParametersOnLock(Result, AdditionalParameters) Export
	
	If Result = Undefined Then
		Return;
	ElsIf TypeOf(Result) = Type("Structure") Then
		AdministrationParameters = Result;
		CorrectAdministrationParametersEntered = True;
		EnableScheduledJobLockManagement();
		IBConnectionsClient.SaveAdministrationParameters(AdministrationParameters);
	ElsIf TypeOf(Result) = Type("Boolean") AND CorrectAdministrationParametersEntered Then
		IBConnectionsClient.SaveAdministrationParameters(AdministrationParameters);
	EndIf;
	
	If Not LockUnlock() Then
		Return;
	EndIf;
	
	ShowUserNotification(NStr("ru = 'Блокировка работы пользователей'; en = 'User access'; pl = 'Blokowanie operacji użytkownika';de = 'Sperrung der Benutzerbedienung';ro = 'Blocarea lucrului utilizatorilor';tr = 'Kullanıcı operasyon kilitleme'; es_ES = 'Bloqueo de la operación del usuario'"),
		"e1cib/app/DataProcessor.ApplicationLock",
		?(Object.DisableUserAuthorisation, NStr("ru = 'Блокировка установлена.'; en = 'User access is denied.'; pl = 'Zablokowane.';de = 'Gesperrt';ro = 'Blocat.';tr = 'Kilitli.'; es_ES = 'Bloqueado.'"), NStr("ru = 'Блокировка снята.'; en = 'User access is allowed.'; pl = 'Odblokowane.';de = 'Freischalten.';ro = 'Deblocat.';tr = 'Kilitsiz.'; es_ES = 'Desbloqueado.'")),
		PictureLib.Information32);
	IBConnectionsClient.SetSessionTerminationHandlers(Object.DisableUserAuthorisation);
	
	If Object.DisableUserAuthorisation Then
		Items.ModeGroup.CurrentPage = Items.LockStatePage;
		RefreshStatePage(ThisObject);
	Else
		Items.ModeGroup.CurrentPage = Items.SettingsPage;
		RefreshSettingsPage();
	EndIf;
	
EndProcedure

&AtClient
Procedure AfterGetAdministrationParametersOnUnlock(Result, AdditionalParameters) Export
	
	If Result = Undefined Then
		Return;
	ElsIf TypeOf(Result) = Type("Structure") Then
		AdministrationParameters = Result;
		CorrectAdministrationParametersEntered = True;
		EnableScheduledJobLockManagement();
		IBConnectionsClient.SaveAdministrationParameters(AdministrationParameters);
	ElsIf TypeOf(Result) = Type("Boolean") AND CorrectAdministrationParametersEntered Then
		IBConnectionsClient.SaveAdministrationParameters(AdministrationParameters);
	EndIf;
	
	If Not CancelLock() Then
		Return;
	EndIf;
	
	IBConnectionsClient.SetSessionTerminationHandlers(False);
	ShowMessageBox(,NStr("ru = 'Завершение работы активных пользователей отменено.'; en = 'Closing active user sessions is canceled.'; pl = 'Zamknij pracę aktywnych użytkowników anulowanych.';de = 'Aktive Benutzer herunterfahren abgebrochen.';ro = 'Finalizarea lucrului utilizatorilor activi este revocată.';tr = 'Etkin kullanıcıların kapatma işlemi iptal edildi.'; es_ES = 'La terminación del trabajo de los usuarios activos está cancelada.'"));
	
EndProcedure

&AtClient
Procedure EnableScheduledJobLockManagement()
	
	Object.DisableScheduledJobs = InfobaseScheduledJobLockAtServer(AdministrationParameters);
	CurrentLockValue = Object.DisableScheduledJobs;
	Items.DisableScheduledJobsGroup.CurrentPage = Items.ScheduledJobManagementGroup;
	
EndProcedure

&AtServer
Procedure SetScheduledJobLockAtServer(AdministrationParameters)
	
	ClusterAdministration.SetInfobaseScheduledJobLock(
		AdministrationParameters, Undefined, Object.DisableScheduledJobs);
	
EndProcedure

&AtServer
Function InfobaseScheduledJobLockAtServer(AdministrationParameters)
	
	Return ClusterAdministration.InfobaseScheduledJobLock(AdministrationParameters);
	
EndFunction

#EndRegion