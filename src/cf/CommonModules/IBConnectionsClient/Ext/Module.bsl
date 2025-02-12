﻿///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Public

// Opens the form for entering infobase and/or cluster administration parameters.
//
// Parameters:
//	OnCloseNotifyDescription - NotifyDescription - handler that will be called once the 
//	                                                   administration parameters are entered.
//	PromptForIBAdministrationParameters - Boolean - shows whether the infobase administration 
//	                                                   parameters must be entered.
//	PromptForClusterAdministrationParameters - Boolean - shows whether the cluster administration 
//	                                                         parameters must be entered.
//	AdministrationParameters - Structure - administration parameters that were entered earlier.
//                                           See StandardSubsystemsServer.AdministrationParameters. 
//	Title - String - form title that explains the purpose of requesting the administration parameters.
//	CommentLabel - String - description of the action in whose context the administration parameters are requested.
//
Procedure ShowAdministrationParameters(OnCloseNotifyDescription, PromptForIBAdministrationParameters,
	PromptForClusterAdministrationParameters, AdministrationParameters = Undefined,
	Title = "", NoteLabel = "") Export
	
	FormParameters = New Structure;
	FormParameters.Insert("PromptForIBAdministrationParameters", PromptForIBAdministrationParameters);
	FormParameters.Insert("PromptForClusterAdministrationParameters", PromptForClusterAdministrationParameters);
	FormParameters.Insert("AdministrationParameters", AdministrationParameters);
	FormParameters.Insert("Title", Title);
	FormParameters.Insert("NoteLabel", NoteLabel);
	
	OpenForm("CommonForm.ApplicationAdministrationParameters", FormParameters,,,,,OnCloseNotifyDescription);
	
EndProcedure

#EndRegion

#Region Internal

// Attaches the SessionTerminationModeManagement idle handler or.
// The TerminateSessions idle handler depending on the SetConnectionLock parameter.
//
Procedure SetSessionTerminationHandlers(Val SetConnectionLock) Export
	
	SetUserTerminationInProgressFlag(SetConnectionLock);
	If SetConnectionLock Then
		// As the lock is not set yet, a session termination handler was attached for this user during the 
		// authorization.
		// Disabling it now. For this user, a special idle handler
		// called "TerminateSessions" is attached. It takes into account that this user should be 
		// disconnected last.
		
		DetachIdleHandler("SessionTerminationModeManagement");
		AttachIdleHandler("EndUserSessions", 60);
		EndUserSessions();
	Else
		DetachIdleHandler("EndUserSessions");
		AttachIdleHandler("SessionTerminationModeManagement", 60);
	EndIf;
	
EndProcedure

// Terminates the last remaining session of the administrator who initiated user session termination.
//
Procedure TerminateThisSession(OutputQuestion = True) Export
	
	SetUserTerminationInProgressFlag(False);
	DetachIdleHandler("EndUserSessions");
	
	If TerminateAllSessionsExceptCurrent() Then
		Return;
	EndIf;
	
	If Not OutputQuestion Then 
		Exit(False);
		Return;
	EndIf;
	
	Notification = New NotifyDescription("TerminateThisSessionCompletion", ThisObject);
	MessageText = NStr("ru = 'Работа пользователей с программой запрещена. Завершить работу этого сеанса?'; en = 'User access to the application is denied. Do you want to close your session?'; pl = 'Operacja użytkownika w aplikacji jest zabroniona. Zamknąć tę sesję?';de = 'Benutzerbedienung in der Anwendung ist untersagt. Diese Sitzung schließen?';ro = 'Activitatea utilizatorului în aplicație este interzisă. Închideți această sesiune?';tr = 'Uygulamada kullanıcı işlemi yasaktır. Bu oturumu kapatmak istiyor musunuz?'; es_ES = 'Operación de usuario en la aplicación está prohibida. ¿Cerrar esta sesión?'");
	Title = NStr("ru = 'Завершение работы текущего сеанса'; en = 'Close current session'; pl = 'Zakończyć bieżącą sesję';de = 'Beende die aktuelle Sitzung';ro = 'Finalizarea sesiunii curente';tr = 'Mevcut oturumu sonlandır'; es_ES = 'Finalizar la sesión actual'");
	ShowQueryBox(Notification, MessageText, QuestionDialogMode.YesNo, 60, DialogReturnCode.Yes, Title, DialogReturnCode.Yes);
	
EndProcedure

// Sets the TerminateAllSessionsExceptCurrent variable to Value.
//
// Parameters:
//   Value - Boolean - value being set.
//
Procedure SetTerminateAllSessionsExceptCurrentFlag(Value) Export
	
	ParameterName = "StandardSubsystems.UserSessionTerminationParameters";
	If ApplicationParameters[ParameterName] = Undefined Then
		ApplicationParameters.Insert(ParameterName, New Structure);
	EndIf;
	
	ApplicationParameters["StandardSubsystems.UserSessionTerminationParameters"].Insert("TerminateAllSessionsExceptCurrent", Value);
	
EndProcedure

// Sets the SessionTerminationInProgress variable to Value.
//
// Parameters:
//   Value - Boolean - value being set.
//
Procedure SetUserTerminationInProgressFlag(Value) Export
	
	ParameterName = "StandardSubsystems.UserSessionTerminationParameters";
	If ApplicationParameters[ParameterName] = Undefined Then
		ApplicationParameters.Insert(ParameterName, New Structure);
	EndIf;
	
	ApplicationParameters["StandardSubsystems.UserSessionTerminationParameters"].Insert("SessionTerminationInProgress", Value);
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Configuration subsystems event handlers.

// The procedure is called when a user works interactively with a data area.
//
// Parameters:
//  LaunchParameters - Array - an array of strings separated with semicolons ";" in the start 
//                     parameter passed to the configuration using the /C command line key.
//  Cancel - Boolean (return value). If True, the OnStart event processing is canceled.
//                     
//
Procedure LaunchParametersOnProcess(StartParameters, Cancel) Export
	
	Cancel = Cancel Or ProcessStartParameters(StartParameters);
	
EndProcedure

// See CommonClientOverridable.BeforeStart. 
Procedure BeforeStart(Parameters) Export
	
	ClientParameters = StandardSubsystemsClient.ClientParametersOnStart();
	
	If Not ClientParameters.Property("DataAreaSessionsLocked") Then
		Return;
	EndIf;
	
	Parameters.InteractiveHandler = New NotifyDescription(
		"BeforeStartInteractiveHandler", ThisObject);
	
EndProcedure

// See CommonClientOverridable.AfterStart. 
Procedure AfterStart() Export
	
	RunParameters = StandardSubsystemsClient.ClientParametersOnStart();
	If NOT RunParameters.SeparatedDataUsageAvailable Then
		Return;
	EndIf;
	
	If GetClientConnectionSpeed() <> ClientConnectionSpeed.Normal Then
		Return;
	EndIf;
	
	LockMode = RunParameters.SessionLockParameters;
	CurrentTime = LockMode.CurrentSessionDate;
	If LockMode.Use 
		 AND (NOT ValueIsFilled(LockMode.Begin) OR CurrentTime >= LockMode.Begin) 
		 AND (NOT ValueIsFilled(LockMode.End) OR CurrentTime <= LockMode.End) Then
		// If the user logged on to a locked infobase, they must have used the /UC key.
		// Sessions by these users should not be terminated.
		Return;
	EndIf;
	
	If StrFind(Upper(LaunchParameter), Upper("EndUserSessions")) > 0 Then
		Return;
	EndIf;
	
	AttachIdleHandler("SessionTerminationModeManagement", 60);
	
EndProcedure

// See also CommonClientOverridable.BeforeExit. 
Procedure BeforeExit(Cancel, Warnings) Export
	
	If SessionTerminationInProgress() Then
		WarningParameters = StandardSubsystemsClient.WarningOnExit();
		WarningParameters.HyperlinkText = NStr("ru = 'Блокировка работы пользователей'; en = 'User access'; pl = 'Blokowanie operacji użytkownika';de = 'Sperrung der Benutzerbedienung';ro = 'Blocarea lucrului utilizatorilor';tr = 'Kullanıcı operasyon kilitleme'; es_ES = 'Bloqueo de la operación del usuario'");
		WarningParameters.WarningText = NStr("ru = 'Из текущего сеанса выполняется завершение работы пользователей'; en = 'User sessions are being closed from the current session.'; pl = 'W bieżącej sesji trwa kończenie pracy użytkowników';de = 'Aus der aktuellen Sitzung wird die Benutzersitzung beendet';ro = 'Din sesiunea curentă se execută finalizarea lucrului utilizatorilor';tr = 'Geçerli oturumdan kullanıcı kapatma işlemi yapılır'; es_ES = 'De la sesión actual se realiza la terminación del trabajo de usuarios'");
		WarningParameters.OutputSingleWarning = True;
		
		Form = "DataProcessor.ApplicationLock.Form.InfobaseConnectionsLock";
		
		ActionOnClickHyperlink = WarningParameters.ActionOnClickHyperlink;
		ActionOnClickHyperlink.Form = Form;
		ActionOnClickHyperlink.ApplicationWarningForm = Form;
		
		Warnings.Add(WarningParameters);
	EndIf;
	
EndProcedure

// The procedure is called during an unsuccessful attempt to set exclusive mode in a file infobase.
//
// Parameters:
//  Notification - NotifyDescription - describes the object which must be passed control after closing this form.
//
Procedure OnOpenExclusiveModeSetErrorForm(Notification = Undefined, FormParameters = Undefined) Export
	
	OpenForm("DataProcessor.ApplicationLock.Form.ExclusiveModeSettingError", FormParameters,
		, , , , Notification);
	
EndProcedure

// Opens the user activity lock form.
//
Procedure OnOpenUserActivityLockForm(Notification = Undefined, FormParameters = Undefined) Export
	
	OpenForm("DataProcessor.ApplicationLock.Form.InfobaseConnectionsLock", FormParameters,
		, , , , Notification);
	
EndProcedure

// Replaces the default notification with a custom form containing the active user list.
//
// Parameters:
//  FormName - String (return value).
//
Procedure OnDefineActiveUserForm(FormName) Export
	
	FormName = "DataProcessor.ActiveUsers.Form.ActiveUsers";
	
EndProcedure

#EndRegion

#Region Private

///////////////////////////////////////////////////////////////////////////////
// Core subsystem event handlers.

Function SessionTerminationInProgress() Export
	
	UserSessionTerminationParameters = ApplicationParameters["StandardSubsystems.UserSessionTerminationParameters"];
	
	Return TypeOf(UserSessionTerminationParameters) = Type("Structure")
		AND UserSessionTerminationParameters.Property("SessionTerminationInProgress")
		AND UserSessionTerminationParameters.SessionTerminationInProgress;
	
EndFunction

Function TerminateAllSessionsExceptCurrent()
	
	UserSessionTerminationParameters = ApplicationParameters["StandardSubsystems.UserSessionTerminationParameters"];
	
	Return TypeOf(UserSessionTerminationParameters) = Type("Structure")
		AND UserSessionTerminationParameters.Property("TerminateAllSessionsExceptCurrent")
		AND UserSessionTerminationParameters.TerminateAllSessionsExceptCurrent;
	
EndFunction

Function SavedAdministrationParameters() Export
	
	UserSessionTerminationParameters = ApplicationParameters["StandardSubsystems.UserSessionTerminationParameters"];
	AdministrationParameters = Undefined;
	
	If TypeOf(UserSessionTerminationParameters) = Type("Structure")
		AND UserSessionTerminationParameters.Property("AdministrationParameters") Then
		
		AdministrationParameters = UserSessionTerminationParameters.AdministrationParameters;
		
	EndIf;
		
	Return AdministrationParameters;
	
EndFunction

Procedure SaveAdministrationParameters(Value) Export
	
	ParameterName = "StandardSubsystems.UserSessionTerminationParameters";
	If ApplicationParameters[ParameterName] = Undefined Then
		ApplicationParameters.Insert(ParameterName, New Structure);
	EndIf;
	
	ApplicationParameters["StandardSubsystems.UserSessionTerminationParameters"].Insert("AdministrationParameters", Value);

EndProcedure

Procedure FillInClusterAdministrationParameters(StartParameters)
	AdministrationParameters = IBConnectionsServerCall.AdministrationParameters();
	
	ParametersCount = StartParameters.Count();
	If ParametersCount > 1 Then
		AdministrationParameters.ClusterAdministratorName = StartParameters[1];
	EndIf;
	
	If ParametersCount > 2 Then
		AdministrationParameters.ClusterAdministratorPassword = StartParameters[2];
	EndIf;
	SaveAdministrationParameters(AdministrationParameters);
	
EndProcedure

///////////////////////////////////////////////////////////////////////////////
// Notification handlers.

// Suggests to remove the application lock and sign in, or to shut down the application.
Procedure BeforeStartInteractiveHandler(Parameters, Context) Export
	
	ClientParameters = StandardSubsystemsClient.ClientParametersOnStart();
	
	QuestionText   = ClientParameters.PromptToAuthorize;
	MessageText = ClientParameters.DataAreaSessionsLocked;
	
	If Not IsBlankString(QuestionText) Then
		Buttons = New ValueList();
		Buttons.Add(DialogReturnCode.Yes, NStr("ru = 'Войти'; en = 'Sign in'; pl = 'Wejdź';de = 'Anmelden';ro = 'Intră';tr = 'Login'; es_ES = 'Entrar'"));
		If ClientParameters.CanUnlock Then
			Buttons.Add(DialogReturnCode.No, NStr("ru = 'Снять блокировку и войти'; en = 'Remove lock and sign in'; pl = 'Odblokować i wyjść';de = 'Entsperren und anmelden';ro = 'Scoate blocarea și intră';tr = 'Kilidini aç ve oturumu aç'; es_ES = 'Desbloquear e iniciar la sesión'"));
		EndIf;
		Buttons.Add(DialogReturnCode.Cancel, NStr("ru = 'Отмена'; en = 'Cancel'; pl = 'Anuluj';de = 'Abbrechen';ro = 'Revocare';tr = 'İptal'; es_ES = 'Cancelar'"));
		
		ResponseHandler = New NotifyDescription(
			"AfterAnswerToPromptToAuthorizeOrUnlock", ThisObject, Parameters);
		
		ShowQueryBox(ResponseHandler, QuestionText, Buttons, 15,
			DialogReturnCode.Cancel,, DialogReturnCode.Cancel);
		Return;
	Else
		Parameters.Cancel = True;
		ShowMessageBox(
			StandardSubsystemsClient.NotificationWithoutResult(Parameters.ContinuationHandler),
			MessageText, 15);
	EndIf;
	
EndProcedure

// Continues from the above procedure.
Procedure AfterAnswerToPromptToAuthorizeOrUnlock(Response, Parameters) Export
	
	If Response = DialogReturnCode.Yes Then // Logging on to the locked application.
		
	ElsIf Response = DialogReturnCode.No Then // Removing the application lock and logging on.
		IBConnectionsServerCall.SetDataAreaSessionLock(
			New Structure("Use", False));
	Else
		Parameters.Cancel = True;
	EndIf;
	
	ExecuteNotifyProcessing(Parameters.ContinuationHandler);
	
EndProcedure

Procedure ShowWarningOnExit(MessageText) Export
	
	ParameterName = "StandardSubsystems.WarningShownBeforeExit";
	If ApplicationParameters[ParameterName] <> True Then
		ShowUserNotification(NStr("ru = 'Работа программы будет завершена'; en = 'The application will be closed'; pl = 'Praca programu zostanie zakończona';de = 'Das Programm wird abgeschlossen sein';ro = 'Lucrul programului va fi finalizat';tr = 'Uygulama kapatılacak'; es_ES = 'El programa se terminará'"),, MessageText,, 
			UserNotificationStatus.Important);
		ApplicationParameters.Insert(ParameterName, True);
	EndIf;	
	ShowMessageBox(, MessageText, 30);
	
EndProcedure

Procedure AskOnTermination(MessageText) Export
	
	ParameterName = "StandardSubsystems.WarningShownBeforeExit";
	If ApplicationParameters[ParameterName] <> True Then
		ShowUserNotification(NStr("ru = 'Работа программы будет завершена'; en = 'The application will be closed'; pl = 'Praca programu zostanie zakończona';de = 'Das Programm wird abgeschlossen sein';ro = 'Lucrul programului va fi finalizat';tr = 'Uygulama kapatılacak'; es_ES = 'El programa se terminará'"),, MessageText,, UserNotificationStatus.Important);
		ApplicationParameters.Insert("StandardSubsystems.WarningShownBeforeExit", True);
	EndIf;	
		
	QuestionText = NStr("ru = '%1
		|Завершить работу?'; 
		|en = '%1
		|Do you want to exit?'; 
		|pl = '%1
		|Zakończyć pracę?';
		|de = '%1
		|Herunterfahren?';
		|ro = '%1
		|Finalizați lucrul?';
		|tr = '%1
		|Uygulama kapatılsın mı?'; 
		|es_ES = '%1
		|¿Terminar el trabajo?'");
	QuestionText = StringFunctionsClientServer.SubstituteParametersToString(QuestionText, MessageText);
	NotifyDescription = New NotifyDescription("AskQuestionOnTerminateCompletion", ThisObject);
	ShowQueryBox(NotifyDescription, QuestionText, QuestionDialogMode.YesNo, 30, DialogReturnCode.Yes);
	
EndProcedure

Procedure AskQuestionOnTerminateCompletion(Response, AdditionalParameters) Export
	
	If Response = DialogReturnCode.Yes Then
		StandardSubsystemsClient.SkipExitConfirmation();
		Exit(True, False);
	EndIf;
	
EndProcedure

Procedure TerminateThisSessionCompletion(Response, Parameters) Export
	
	If Response <> DialogReturnCode.No Then
		StandardSubsystemsClient.SkipExitConfirmation();
		Exit(False);
	EndIf;
	
EndProcedure	

// Processes start parameters related to allowing or terminating infobase connections.
//
// Parameters:
//  LaunchParameterValue - String - main launch parameter.
//  LaunchParameters - Array - additional start parameters separated by semicolons.
//                                       
//
// Returns:
//   Boolean - True if system start must be canceled.
//
Function ProcessStartParameters(Val StartParameters)

	RunParameters = StandardSubsystemsClient.ClientParametersOnStart();
	If NOT RunParameters.SeparatedDataUsageAvailable Then
		Return False;
	EndIf;
	
	// Processing the application start parameters -
	// ProhibitUserAuthorization and AllowUserAuthorization.
	If StartParameters.Find("AllowUserAuthorization") <> Undefined Then
		
		If NOT IBConnectionsServerCall.AllowUserAuthorization() Then
			MessageText = NStr("ru = 'Параметр запуска РазрешитьРаботуПользователей не отработан. Нет прав на администрирование информационной базы.'; en = 'The AllowUserAuthorization parameter is ignored because you do not have administrative rights.'; pl = 'Parametr uruchomienia AllowUsersWork nie został przetworzony. Nie masz uprawnień do administrowania bazy informacyjnej.';de = 'Der Parameter des Starts der AllowUserAuthorization wird nicht verarbeitet. Sie sind nicht berechtigt, die Infobase zu verwalten.';ro = 'Parametrul lansării AllowUserAuthorization nu este procesat. Nu sunteți autorizat să administrați baza de date.';tr = 'AllowUserAuthorization başlatma parametresi işlenmedi. Veritabanını yönetme yetkiniz yok.'; es_ES = 'Parámetro de lanzamiento AllowUserAuthorization no se ha procesado. Usted no está autorizado a administrar la infobase.'");
			ShowMessageBox(,MessageText);
			Return False;
		EndIf;
		
		EventLogClient.AddMessageForEventLog(EventLogEvent(),,
			NStr("ru = 'Выполнен запуск с параметром ""РазрешитьРаботуПользователей"". Работа программы будет завершена.'; en = 'The application is started with AllowUserAuthorization parameter. The application will be closed.'; pl = 'Wykonano uruchomienie z parametrem ""AllowUsersWork"". Aplikacja zostanie zamknięta.';de = 'Der Start mit dem Parameter AllowUserAuthorization wird durchgeführt. Die Anwendung wird geschlossen.';ro = 'Lansarea cu parametrul AllowUserAuthorization este efectuată. Cererea va fi închisă.';tr = '""AllowUserAuthorization"" parametresi ile başladı. Uygulama kapatılacak.'; es_ES = 'Iniciado con el parámetro AllowUserAuthorization. La aplicación se cerrará.'"), ,True);
		Exit(False);
		Return True;
		
	// The parameter can contain two additional semicolon-separated parts: a name and a password of the 
	// infobase administrator running server cluster connection in client/server mode of the system.
	//  These parameters must be passed if the current user is not an infobase administrator.
	// 
	// For usage examples, see the TerminateSessions() procedure.
	ElsIf StartParameters.Find("EndUserSessions") <> Undefined Then
		
		If NOT IBConnectionsServerCall.SetConnectionLock() Then
			MessageText = NStr("ru = 'Параметр запуска ЗавершитьРаботуПользователей не отработан. Нет прав на администрирование информационной базы.'; en = 'The AllowUserAuthorization parameter is ignored because you do not have administrative rights.'; pl = 'Parametr uruchomienia EndUsersWork nie został przetworzony. Nie masz uprawnień do administrowania bazy informacyjnej.';de = 'Der Startparameter AllowUserAuthorization wird nicht verarbeitet. Sie sind nicht berechtigt, die Infobase zu verwalten.';ro = 'Lansarea cu parametrul AllowUserAuthorization este efectuată. Cererea va fi închisă.';tr = 'AllowUserAuthorization başlatma parametresi işlenmez. Veritabanını yönetme yetkiniz yok.'; es_ES = 'El parámetro de lanzamiento AllowUserAuthorization no se ha procesado. Usted no está autorizado a administrar la infobase.'");
			ShowMessageBox(,MessageText);
			Return False;
		EndIf;
		
		// Offset cluster administration parameters in case of startup with a key.
		FillInClusterAdministrationParameters(StartParameters);
		
		AttachIdleHandler("EndUserSessions", 60);
		EndUserSessions();
		Return False; // Proceed with the application start.
		
	EndIf;
	Return False;
	
EndFunction

// Returns a string constant for generating event log messages.
//
// Returns:
//   String - an event description for the event log.
//
Function EventLogEvent() Export
	
	Return NStr("ru = 'Завершение работы пользователей'; en = 'User sessions'; pl = 'Zakończenie pracy użytkowników';de = 'Benutzerarbeit abgeschlossen';ro = 'Finalizarea lucrului utilizatorilor';tr = 'Kullanıcı çalışmasını tamamlanma'; es_ES = 'Finalización del trabajo de usuario'", CommonClient.DefaultLanguageCode());
	
EndFunction

#EndRegion
