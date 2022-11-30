///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Private

// Terminates active sessions if infobase connection lock is set.
// 
//
Procedure SessionTerminationModeManagement() Export

	// Getting the current lock parameter values.
	CurrentMode = IBConnectionsServerCall.SessionLockParameters();
	LockSet = CurrentMode.Use;
	
	If Not LockSet Then
		Return;
	EndIf;
		
	LockBeginTime = CurrentMode.Begin;
	LockEndTime = CurrentMode.End;
	
	// ExitWithConfirmationTimeout and StopTimeout have negative values, that is why "<=" is used when 
	// these parameters are compared with the difference (LockBeginTime - CurrentMoment) as this 
	// difference keeps getting smaller.
	WaitTimeout    = CurrentMode.SessionTerminationTimeout;
	ExitWithConfirmationTimeout = WaitTimeout / 3;
	StopTimeoutSaaS = 60; // One minute before the lock initiation.
	StopTimeout        = 0; // At the moment of lock initiation.
	CurrentMoment             = CurrentMode.CurrentSessionDate;
	
	If LockEndTime <> '00010101' AND CurrentMoment > LockEndTime Then
		Return;
	EndIf;
	
	LockBeginTimeDate  = Format(LockBeginTime, "DLF=DD");
	LockBeginTimeTime = Format(LockBeginTime, "DLF=T");
	
	MessageText = IBConnectionsClientServer.ExtractLockMessage(CurrentMode.Message);
	Template = NStr("ru = 'Рекомендуется завершить текущую работу и сохранить все свои данные. Работа программы будет завершена %1 в %2. 
		|%3'; 
		|en = 'Please save your data. The application will be temporarily unavailable since %1, %2.
		|%3'; 
		|pl = 'Zaleca się zakończyć bieżącą pracę i zapisać wszystkie dane. Aplikacja zostanie zamknięta %1w %2. 
		|%3';
		|de = 'Es wird empfohlen, die aktuelle Arbeit zu beenden und alle Daten zu speichern. Die Anwendung wird geschlossen %1 in %2. 
		|%3';
		|ro = 'Recomandăm să finalizați lucrul curent și să vă salvați datele. Lucrul programului va fi finalizat %1 la %2. 
		|%3';
		|tr = 'Mevcut çalışmayı sonlandırmanızı ve tüm verileri kaydetmenizi tavsiye edilir. Uygulama %1 içinde kapatılacak%2.
		|%3'; 
		|es_ES = 'Se recomienda finalizar el trabajo actual y guardar todos los datos. La aplicación se cerrará %1 en %2. 
		|%3'");
	MessageText = StringFunctionsClientServer.SubstituteParametersToString(Template, LockBeginTimeDate, LockBeginTimeTime, MessageText);
	
	DataSeparationEnabled = StandardSubsystemsClient.ClientRunParameters().DataSeparationEnabled;
	If Not DataSeparationEnabled
		AND (Not ValueIsFilled(LockBeginTime) Or LockBeginTime - CurrentMoment < StopTimeout) Then
		
		StandardSubsystemsClient.SkipExitConfirmation();
		Exit(False, CurrentMode.RestartOnCompletion);
		
	ElsIf DataSeparationEnabled
		AND (Not ValueIsFilled(LockBeginTime) Or LockBeginTime - CurrentMoment < StopTimeoutSaaS) Then
		
		StandardSubsystemsClient.SkipExitConfirmation();
		Exit(False, False);
		
	ElsIf LockBeginTime - CurrentMoment <= ExitWithConfirmationTimeout Then
		
		IBConnectionsClient.AskOnTermination(MessageText);
		
	ElsIf LockBeginTime - CurrentMoment <= WaitTimeout Then
		
		IBConnectionsClient.ShowWarningOnExit(MessageText);
		
	EndIf;
	
EndProcedure

// Terminates active sessions upon timeout, and then terminates the current session.
// 
//
Procedure EndUserSessions() Export

	// Getting the current lock parameter values.
	CurrentMode = IBConnectionsServerCall.SessionLockParameters(True);
	
	LockBeginTime = CurrentMode.Begin;
	CurrentMoment = CurrentMode.CurrentSessionDate;
	
	If CurrentMoment < LockBeginTime Then
		MessageText = NStr("ru = 'Блокировка работы пользователей запланирована на %1.'; en = 'The application will be temporarily unavailable since %1.'; pl = 'Blokada operacji użytkowników jest zaplanowana na %1.';de = 'Die Sperre der Benutzeroperation ist geplant auf %1.';ro = 'Blocarea lucrului utilizatorilor este planificată pentru %1.';tr = 'Kullanıcı işleminin kilitlenmesi %1 planlandı.'; es_ES = 'Bloqueo de la operación de usuario está programado para %1.'");
		MessageText = StringFunctionsClientServer.SubstituteParametersToString(MessageText, LockBeginTime);
		ShowUserNotification(NStr("ru = 'Завершение работы пользователей'; en = 'User sessions'; pl = 'Zakończenie pracy użytkowników';de = 'Benutzerarbeit abgeschlossen';ro = 'Finalizarea lucrului utilizatorilor';tr = 'Kullanıcı çalışmasını tamamlanma'; es_ES = 'Finalización del trabajo de usuario'"), 
			"e1cib/app/DataProcessor.ApplicationLock", 
			MessageText, PictureLib.Information32);
		Return;
	EndIf;
		
	SessionCount = CurrentMode.SessionCount;
	If SessionCount <= 1 Then
		// All users except the current session are disconnected.
		// The session started with the "TerminateSessions" parameter should be terminated last.
		// This termination order is required to update the configuration with a batch file.
		IBConnectionsClient.SetUserTerminationInProgressFlag(False);
		Notify("UserSessionsCompletion", New Structure("Status, SessionCount", "Finish", SessionCount));
		IBConnectionsClient.TerminateThisSession();
		Return;
	EndIf; 
	
	LockSet = CurrentMode.Use;
	If Not LockSet Then
		Return;
	EndIf;
	
	// If the infobase is file-based, some connections cannot be forcibly terminated.
	If StandardSubsystemsClient.ClientParameter("FileInfobase") Then
		Return;
	EndIf;
	
	// Once the session lock is enabled, all user sessions must be terminated. Terminating connections 
	// for users that are still connected.
	DetachIdleHandler("EndUserSessions");
	
	Try
		AdministrationParameters = IBConnectionsClient.SavedAdministrationParameters();
		If CommonClient.ClientConnectedOverWebServer() Then
			IBConnectionsServerCall.DeleteAllSessionsExceptCurrent(AdministrationParameters);
		Else 
			IBConnectionsClientServer.DeleteAllSessionsExceptCurrent(AdministrationParameters);
		EndIf;
		IBConnectionsClient.SaveAdministrationParameters(Undefined);
	Except
		IBConnectionsClient.SetUserTerminationInProgressFlag(False);
			ShowUserNotification(NStr("ru = 'Завершение работы пользователей'; en = 'User sessions'; pl = 'Zakończenie pracy użytkowników';de = 'Benutzerarbeit abgeschlossen';ro = 'Finalizarea lucrului utilizatorilor';tr = 'Kullanıcı çalışmasını tamamlanma'; es_ES = 'Finalización del trabajo de usuario'"),
			"e1cib/app/DataProcessor.ApplicationLock", 
			NStr("ru = 'Завершение сеансов не выполнено. Подробности см. в Журнале регистрации.'; en = 'Cannot close sessions. For more information, see the event log.'; pl = 'Zakończenie sesji nie powiodło się. Szczegóły patrz Dzienniku rejestracji.';de = 'Die Sitzungen wurden nicht abgeschlossen. Siehe Ereignisprotokoll für Details.';ro = 'Sesiunile nu sunt finalizate. Detalii vezi în Registrul logare.';tr = 'Oturumlar tamamlanmadı. Daha fazla bilgi için olay günlüğüne bakın.'; es_ES = 'Sesiones no se han finalizado. Para más información, ver el Registro de eventos.'"), PictureLib.Warning32);
		EventLogClient.AddMessageForEventLog(IBConnectionsClient.EventLogEvent(),
			"Error", DetailErrorDescription(ErrorInfo()),, True);
		Notify("UserSessionsCompletion", New Structure("Status,SessionCount", "Error", SessionCount));
		Return;
	EndTry;
	
	IBConnectionsClient.SetUserTerminationInProgressFlag(False);
	ShowUserNotification(NStr("ru = 'Завершение работы пользователей'; en = 'User sessions'; pl = 'Zakończenie pracy użytkowników';de = 'Benutzerarbeit abgeschlossen';ro = 'Finalizarea lucrului utilizatorilor';tr = 'Kullanıcı çalışmasını tamamlanma'; es_ES = 'Finalización del trabajo de usuario'"),
		"e1cib/app/DataProcessor.ApplicationLock", 
		NStr("ru = 'Завершение сеансов выполнено успешно'; en = 'All user sessions are closed.'; pl = 'Sesje zostały zamknięte pomyślnie';de = 'Sitzungen werden erfolgreich geschlossen';ro = 'Sesiunile au fost finalizate cu succes';tr = 'Oturumlar başarıyla kapatıldı'; es_ES = 'Sesiones se han cerrado con éxito'"), PictureLib.Information32);
	Notify("UserSessionsCompletion", New Structure("Status,SessionCount", "Finish", SessionCount));
	IBConnectionsClient.TerminateThisSession();
	
EndProcedure

#EndRegion
