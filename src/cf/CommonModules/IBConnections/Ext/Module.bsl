///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Public

////////////////////////////////////////////////////////////////////////////////
// Locking the infobase and terminating connections.

// Sets the infobase connection lock.
// If this function is called from a session with separator values set, it sets the data area 
// session lock.
//
// Parameters:
//  MessageText - String - text to be used in the error message displayed when someone attempts to 
//                             connect to a locked infobase.
//                             
// 
//  KeyCode - String - string to be added to "/uc" command line parameter or to "uc" connection 
//                             string parameter in order to establish connection to the infobase 
//                             regardless of the lock.
//                             
//                             Cannot be used for data area session locks.
//
// Returns:
//   Boolean - True if the lock is set successfully.
//              False if the lock cannot be set due to insufficient rights.
//
Function SetConnectionLock(Val MessageText = "",
	Val KeyCode = "KeyCode") Export
	
	If Common.DataSeparationEnabled() AND Common.SeparatedDataUsageAvailable() Then
		
		If Not Users.IsFullUser() Then
			Return False;
		EndIf;
		
		Lock = NewConnectionLockParameters();
		Lock.Use = True;
		Lock.Begin = CurrentSessionDate();
		Lock.Message = GenerateLockMessage(MessageText, KeyCode);
		Lock.Exclusive = Users.IsFullUser(, True);
		SetDataAreaSessionLock(Lock);
		Return True;
	Else
		If Not Users.IsFullUser(, True) Then
			Return False;
		EndIf;
		
		Lock = New SessionsLock;
		Lock.Use = True;
		Lock.Begin = CurrentSessionDate();
		Lock.KeyCode = KeyCode;
		Lock.Message = GenerateLockMessage(MessageText, KeyCode);
		SetSessionsLock(Lock);
		Return True;
	EndIf;
	
EndFunction

// Determines whether connection lock is set for the infobase configuration batch update.
// 
//
// Returns:
//    Boolean - True if the lock is set, otherwise False.
//
Function ConnectionsLocked() Export
	
	LockParameters = CurrentConnectionLockParameters();
	Return LockParameters.ConnectionsLocked;
	
EndFunction

// Gets the infobase connection lock parameters to be used at client side.
//
// Parameters:
//    GetSessionCount - Boolean - if True, then the SessionCount field is filled in the returned 
//                                         structure.
//
// Returns:
//   Structure - with the following properties:
//     * IsSet - Boolean - True if the lock is set, otherwise False.
//     * Start - Date - lock start date.
//     * End - Date - lock end date.
//     * Message - String - message to a user.
//     * SessionTerminationTimeout - Number - interval in seconds.
//     * SessionCount - Number - 0 if the GetSessionCount parameter value is False.
//     * CurrentSessionDate - Date - current session date.
//
Function SessionLockParameters(Val GetSessionCount = False) Export
	
	LockParameters = CurrentConnectionLockParameters();
	Return AdvancedSessionLockParameters(GetSessionCount, LockParameters);
	
EndFunction

// Removes the infobase lock.
//
// Returns:
//   Boolean - True if the operation is successful.
//              False if the operation cannot be performed due to insufficient rights.
//
Function AllowUserAuthorization() Export
	
	If Common.DataSeparationEnabled() AND Common.SeparatedDataUsageAvailable() Then
		
		If Not Users.IsFullUser() Then
			Return False;
		EndIf;
		
		CurrentMode = GetDataAreaSessionLock();
		If CurrentMode.Use Then
			NewMode = NewConnectionLockParameters();
			NewMode.Use = False;
			SetDataAreaSessionLock(NewMode);
		EndIf;
		Return True;
		
	Else
		If NOT Users.IsFullUser(, True) Then
			Return False;
		EndIf;
		
		CurrentMode = GetSessionsLock();
		If CurrentMode.Use Then
			NewMode = New SessionsLock;
			NewMode.Use = False;
			SetSessionsLock(NewMode);
		EndIf;
		Return True;
	EndIf;
	
EndFunction

// Returns information about the current connections to the infobase.
// If necessary, writes a message to the event log.
//
// Parameters:
//    GetConnectionString - Boolean - add the connection string to the return value.
//    MessagesForEventLog - ValueList - if the parameter is not blank, the events from the list will 
//                                                      be written to the event log.
//    ClusterPort - Number - Non-standard port of a server cluster.
//
// Returns:
//    Structure - structure with the following properties:
//        * HasActiveConnections - Boolean - shows if there are active connections.
//        * HasCOMConnections - Boolean - shows if there are COM connections.
//        * HasDesignerConnection - shows if there is a designer connection.
//        * HasActiveUsers - Boolean - shows if there are active users.
//        * InfoBaseConnectionString - String - infobase connection string. The property is present 
//                                                        only if the GetConnectionString parameter value is True.
//
Function ConnectionsInformation(GetConnectionString = False,
	MessagesForEventLog = Undefined, ClusterPort = 0) Export
	
	SetPrivilegedMode(True);
	
	Result = New Structure();
	Result.Insert("HasActiveConnections", False);
	Result.Insert("HasCOMConnections", False);
	Result.Insert("HasDesignerConnection", False);
	Result.Insert("HasActiveUsers", False);
	
	If InfoBaseUsers.GetUsers().Count() > 0 Then
		Result.HasActiveUsers = True;
	EndIf;
	
	If GetConnectionString Then
		Result.Insert("InfobaseConnectionString", InfoBaseConnectionString());
	EndIf;
		
	EventLogOperations.WriteEventsToEventLog(MessagesForEventLog);
	
	SessionsArray = GetInfoBaseSessions();
	If SessionsArray.Count() = 1 Then
		Return Result;
	EndIf;
	
	Result.HasActiveConnections = True;
	
	For Each Session In SessionsArray Do
		If Upper(Session.ApplicationName) = Upper("COMConnection") Then // COM connection
			Result.HasCOMConnections = True;
		ElsIf Upper(Session.ApplicationName) = Upper("Designer") Then // Designer
			Result.HasDesignerConnection = True;
		EndIf;
	EndDo;
	
	Return Result;
	
EndFunction

////////////////////////////////////////////////////////////////////////////////
// Data area session lock.

// Gets an empty structure with data area session lock parameters.
// 
// Returns:
//   Structure - with the following fields:
//     Start - Date - time the lock became active.
//     End - Date - time the lock ended.
//     Message - String - messages for users attempting to access the locked data area.
//     IsSet - Boolean - shows if the lock is set.
//     IsExclusive - Boolean - the lock cannot be modified by the application administrator.
//
Function NewConnectionLockParameters() Export
	
	Result = New Structure;
	Result.Insert("End", Date(1,1,1));
	Result.Insert("Begin", Date(1,1,1));
	Result.Insert("Message", "");
	Result.Insert("Use", False);
	Result.Insert("Exclusive", False);
	
	Return Result;
	
EndFunction

// Sets the data area session lock.
// 
// Parameters:
//   Parameters - Structure - see NewConnectionLockParameters. 
//   LocalTime - Boolean - lock beginning time and lock end time are specified in the local session time.
//                                If the parameter is False, they are specified in universal time.
//   DataArea - Number - number of the data area to be locked.
//     When calling this procedure from a session with separator values set, only a value equal to 
//       the session separator value (or unspecified) can be passed.
//     When calling this procedure from a session with separator values not set, the parameter value must be specified.
//
Procedure SetDataAreaSessionLock(Parameters, Val LocalTime = True, Val DataArea = -1) Export
	
	If Not Users.IsFullUser() Then
		Raise NStr("ru ='Недостаточно прав для выполнения операции'; en = 'Not enough rights to perform the operation.'; pl = 'Nie masz wystarczających uprawnień do wykonania operacji';de = 'Unzureichende Rechte zum Ausführen des Vorgangs';ro = 'Drepturile insuficiente pentru efectuarea operațiunii';tr = 'İşlemi gerçekleştirmek için yetersiz haklar'; es_ES = 'Insuficientes derechos para realizar la operación'");
	EndIf;
	
	Exclusive = False;
	If Not Parameters.Property("Exclusive", Exclusive) Then
		Exclusive = False;
	EndIf;
	If Exclusive AND Not Users.IsFullUser(, True) Then
		Raise NStr("ru ='Недостаточно прав для выполнения операции'; en = 'Not enough rights to perform the operation.'; pl = 'Nie masz wystarczających uprawnień do wykonania operacji';de = 'Unzureichende Rechte zum Ausführen des Vorgangs';ro = 'Drepturile insuficiente pentru efectuarea operațiunii';tr = 'İşlemi gerçekleştirmek için yetersiz haklar'; es_ES = 'Insuficientes derechos para realizar la operación'");
	EndIf;
	
	If Common.SeparatedDataUsageAvailable() Then
		
		If Common.SubsystemExists("StandardSubsystems.SaaS") Then
			ModuleSaaS = Common.CommonModule("SaaS");
			SessionSeparatorValue = ModuleSaaS.SessionSeparatorValue();
		Else
			SessionSeparatorValue = 0;
		EndIf;
		
		If DataArea = -1 Then
			DataArea = SessionSeparatorValue;
		ElsIf DataArea <> SessionSeparatorValue Then
			Raise NStr("ru = 'Из сеанса с используемыми значениями разделителей нельзя установить блокировку сеансов области данных, отличной от используемой в сеансе.'; en = 'Cannot set a session lock for a data area that is different from the session data area because the session uses separator values.'; pl = 'Uruchamiając sesję z używanymi wartościami separatora, nie można ustawić blokady sesji dla obszaru danych innego niż używane w sesji.';de = 'Wenn Sie eine Sitzung mit verwendeten Trennzeichenwerten ausführen, können Sie keine Sitzungssperre für einen Datenbereich festlegen, der sich von dem in der Sitzung verwendeten unterscheidet.';ro = 'Dacă executați o sesiune cu valorile separatoare utilizate, nu puteți seta o blocare a sesiunii pentru o zonă de date diferită de cea utilizată în sesiune.';tr = 'Kullanılan  ayırıcı değerleri olan bir oturumdan, oturumda kullanılandan  farklı bir veri alanı için bir oturum kilidi ayarlayamazsınız.'; es_ES = 'Lanzando una sesión con los valores del separador utilizado, usted no puede establecer un bloqueo de sesión para un área de datos que es diferente de aquella utilizada en la sesión.'");
		EndIf;
		
	Else
		
		If DataArea = -1 Then
			Raise NStr("ru = 'Невозможно установить блокировку сеансов области данных - не указана область данных.'; en = 'Cannot lock data area sessions because the data area is not specified.'; pl = 'Nie można ustawić blokadę sesji obszarze danych - nie określono obszar danych.';de = 'Datensitzungssitzungssperre kann nicht festgelegt werden- Es wurde kein Datenbereich angegeben.';ro = 'Nu puteți instala blocarea sesiunilor domeniului de date - nu este indicat domeniul de date.';tr = 'Veri alanı belirlenmediğinden dolayı, veri alanı oturumları kilitlenemedi.'; es_ES = 'No se puede establecer el bloqueo para las sesiones del área de datos, porque el área de datos no se ha especificado.'");
		EndIf;
		
	EndIf;
	
	SettingsStructure = Parameters;
	If TypeOf(Parameters) = Type("SessionsLock") Then
		SettingsStructure = NewConnectionLockParameters();
		FillPropertyValues(SettingsStructure, Parameters);
	EndIf;

	SetPrivilegedMode(True);
	LockSet = InformationRegisters.DataAreaSessionLocks.CreateRecordSet();
	LockSet.Filter.DataAreaAuxiliaryData.Set(DataArea);
	LockSet.Read();
	LockSet.Clear();
	If Parameters.Use Then 
		Lock = LockSet.Add();
		Lock.DataAreaAuxiliaryData = DataArea;
		Lock.LockStart = ?(LocalTime AND ValueIsFilled(SettingsStructure.Begin), 
			ToUniversalTime(SettingsStructure.Begin), SettingsStructure.Begin);
		Lock.LockEnd = ?(LocalTime AND ValueIsFilled(SettingsStructure.End), 
			ToUniversalTime(SettingsStructure.End), SettingsStructure.End);
		Lock.LockMessage = SettingsStructure.Message;
		Lock.Exclusive = SettingsStructure.Exclusive;
	EndIf;
	LockSet.Write();
	
EndProcedure

// Gets information on the data area session lock.
// 
// Parameters:
//   LocalTime - Boolean - lock beginning time and lock end time are returned in the local session 
//                                time zone. If the parameter is False, they are returned in 
//                                universal time.
//
// Returns:
//   Structure - see NewConnectionLockParameters. 
//
Function GetDataAreaSessionLock(Val LocalTime = True) Export
	
	Result = NewConnectionLockParameters();
	If Not Common.DataSeparationEnabled() Or Not Common.SeparatedDataUsageAvailable() Then
		Return Result;
	EndIf;
	
	If Not Users.IsFullUser() Then
		Raise NStr("ru ='Недостаточно прав для выполнения операции'; en = 'Not enough rights to perform the operation.'; pl = 'Nie masz wystarczających uprawnień do wykonania operacji';de = 'Unzureichende Rechte zum Ausführen der Operation';ro = 'Insufficient rights to perform the operation';tr = 'İşlemi gerçekleştirmek için yetersiz haklar'; es_ES = 'Insuficientes derechos para realizar la operación'");
	EndIf;
	
	ModuleSaaS = Common.CommonModule("SaaS");
	
	SetPrivilegedMode(True);
	LockSet = InformationRegisters.DataAreaSessionLocks.CreateRecordSet();
	LockSet.Filter.DataAreaAuxiliaryData.Set(
		ModuleSaaS.SessionSeparatorValue());
	LockSet.Read();
	If LockSet.Count() = 0 Then
		Return Result;
	EndIf;
	Lock = LockSet[0];
	Result.Begin = ?(LocalTime AND ValueIsFilled(Lock.LockStart), 
		ToLocalTime(Lock.LockStart), Lock.LockStart);
	Result.End = ?(LocalTime AND ValueIsFilled(Lock.LockEnd), 
		ToLocalTime(Lock.LockEnd), Lock.LockEnd);
	Result.Message = Lock.LockMessage;
	Result.Exclusive = Lock.Exclusive;
	Result.Use = True;
	If ValueIsFilled(Lock.LockEnd) AND CurrentSessionDate() > Lock.LockEnd Then
		Result.Use = False;
	EndIf;
	Return Result;
	
EndFunction

#EndRegion

#Region Internal

// Returns a text string containing the active infobase connection list.
// The connection names are separated by line breaks.
//
// Parameters:
//	Message - String - string to pass.
//
// Returns:
//   String - connection names.
//
Function ActiveSessionsMessage() Export
	
	Message = NStr("ru = 'Не удалось отключить сеансы:'; en = 'Cannot close sessions:'; pl = 'Nie można wyłączyć sesji:';de = 'Sitzungen können nicht deaktiviert werden:';ro = 'Nu se pot dezactiva sesiunile:';tr = 'Oturumlar devre dışı bırakılamaz:'; es_ES = 'No se puede desactivar las sesiones:'");
	CurrentSessionNumber = InfoBaseSessionNumber();
	For Each Session In GetInfoBaseSessions() Do
		If Session.SessionNumber <> CurrentSessionNumber Then
			Message = Message + Chars.LF + "• " + Session;
		EndIf;
	EndDo;
	
	Return Message;
	
EndFunction

// Gets the number of active infobase sessions.
//
// Parameters:
//   IncludeConsole - Boolean - if False, the server cluster console sessions are excluded.
//                               The server cluster console sessions do not prevent execution of 
//                               administrative operations (enabling the exclusive mode, and so on).
//
// Returns:
//   Number - number of active infobase sessions.
//
Function InfobaseSessionCount(IncludeConsole = True, IncludeBackgroundJobs = True) Export
	
	IBSessions = GetInfoBaseSessions();
	If IncludeConsole AND IncludeBackgroundJobs Then
		Return IBSessions.Count();
	EndIf;
	
	Result = 0;
	
	For Each IBSession In IBSessions Do
		
		If Not IncludeConsole AND IBSession.ApplicationName = "SrvrConsole"
			Or Not IncludeBackgroundJobs AND IBSession.ApplicationName = "BackgroundJob" Then
			Continue;
		EndIf;
		
		Result = Result + 1;
		
	EndDo;
	
	Return Result;
	
EndFunction

// Determines the number of infobase sessions and checks if there are sessions that cannot be 
// forcibly disabled. Generates error message text.
// 
//
Function BlockingSessionsInformation(MessageText = "") Export
	
	BlockingSessionsInformation = New Structure;
	
	CurrentSessionNumber = InfoBaseSessionNumber();
	InfobaseSessions = GetInfoBaseSessions();
	
	HasBlockingSessions = False;
	If Common.FileInfobase() Then
		ActiveSessionNames = "";
		For Each Session In InfobaseSessions Do
			If Session.SessionNumber <> CurrentSessionNumber
				AND Session.ApplicationName <> "1CV8"
				AND Session.ApplicationName <> "1CV8C"
				AND Session.ApplicationName <> "WebClient" Then
				ActiveSessionNames = ActiveSessionNames + Chars.LF + "• " + Session;
				HasBlockingSessions = True;
			EndIf;
		EndDo;
	EndIf;
	
	BlockingSessionsInformation.Insert("HasBlockingSessions", HasBlockingSessions);
	BlockingSessionsInformation.Insert("SessionCount", InfobaseSessions.Count());
	
	If HasBlockingSessions Then
		Message = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Имеются активные сеансы работы с программой,
			|которые не могут быть завершены принудительно:
			|%1
			|%2'; 
			|en = 'There are active sessions
			|that cannot be closed:
			|%1
			|%2'; 
			|pl = 'Są aktywne sesje pracy z programem,
			|które nie mogą być zakończone przymusowo:
			|%1
			|%2';
			|de = 'Es gibt aktive Sitzungen mit dem Programm,
			|die nicht gewaltsam beendet werden können:
			|%1
			|%2';
			|ro = 'Există sesiuni active de lucru cu programul,
			|care nu pot fi finalizate forțat:
			|%1
			|%2';
			|tr = 'Sonlandırılamayacak 
			|aktif kullanıcı oturumları var:
			|%1
			|%2'; 
			|es_ES = 'Hay sesiones activas del uso del programa 
			|que no pueden ser terminadas obligatoriamente:
			|%1
			|%2'"),
			ActiveSessionNames, MessageText);
		BlockingSessionsInformation.Insert("MessageText", Message);
		
	EndIf;
	
	Return BlockingSessionsInformation;
	
EndFunction

////////////////////////////////////////////////////////////////////////////////
// Configuration subsystems event handlers.

// See SaaSOverridable.OnFillIBParametersTable. 
Procedure OnFillIIBParametersTable(Val ParametersTable) Export
	
	If Common.SubsystemExists("StandardSubsystems.SaaS.CoreSaaS") Then
		ModuleSaaS = Common.CommonModule("SaaS");
		ModuleSaaS.AddConstantToIBParametersTable(ParametersTable, "LockMessageOnConfigurationUpdate");
	EndIf;
	
EndProcedure

// See CommonOverridable.OnAddClientParametersOnStart. 
Procedure OnAddClientParametersOnStart(Parameters) Export
	
	LockParameters = CurrentConnectionLockParameters();
	Parameters.Insert("SessionLockParameters", New FixedStructure(AdvancedSessionLockParameters(False, LockParameters)));
	
	If Not LockParameters.ConnectionsLocked
		Or Not Common.DataSeparationEnabled()
		Or Not Common.SeparatedDataUsageAvailable() Then
		Return;
	EndIf;
	
	// The following code is intended for locked data areas only.
	If InfobaseUpdate.InfobaseUpdateInProgress() 
		AND Users.IsFullUser() Then
		// The application administrator can sign in regardless of the incomplete area update status (and the data area lock).
		// The administrator initiates area update.
		Return; 
	EndIf;
	
	CurrentMode = LockParameters.CurrentDataAreaMode;
	
	If ValueIsFilled(CurrentMode.End) Then
		LockPeriod = StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = 'на период с %1 по %2'; en = 'from %1 to %2'; pl = 'za okres od %1 do %2';de = 'für den Zeitraum von %1 bis %2';ro = 'pentru perioada de la %1 până la %2';tr = '%1 ile%2 arası bir dönem için'; es_ES = 'para el período desde %1 hasta %2'"), CurrentMode.Begin, CurrentMode.End);
	Else
		LockPeriod = StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = 'с %1'; en = 'from %1'; pl = 'od %1';de = 'von %1';ro = 'de la %1';tr = 'itibaren%1'; es_ES = 'desde %1'"), CurrentMode.Begin);
	EndIf;
	If ValueIsFilled(CurrentMode.Message) Then
		LockReason = NStr("ru = 'по причине:'; en = 'for the following reason:'; pl = 'z powodu:';de = 'aufgrund:';ro = 'din motivul:';tr = 'nedeniyle:'; es_ES = 'debido a:'") + Chars.LF + CurrentMode.Message;
	Else
		LockReason = NStr("ru = 'для проведения регламентных работ'; en = 'for maintenance'; pl = 'przeprowadzenia zaplanowanych operacji';de = 'zur Durchführung geplanter Operationen';ro = 'pentru executarea lucrărilor reglementare';tr = 'planlanmış operasyonlar yürütmek'; es_ES = 'realizar las operaciones programadas'");
	EndIf;
	MessageText = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("ru = 'Администратором приложения установлена блокировка работы пользователей %1 %2.
			|
			|Приложение временно недоступно.'; 
			|en = 'The administrator denied access to the application %1 %2.
			|
			|Please try again later.'; 
			|pl = 'Administrator aplikacji ustawił %1 %2 blokadę pracy użytkowników.
			|
			|Aplikacja jest tymczasowo niedostępna.';
			|de = 'Anwendungsadministrator setzen %1 %2Benutzer Arbeitssperre. 
			| 
			|Die Anwendung ist vorübergehend nicht verfügbar.';
			|ro = 'Administratorul aplicației a stabilit blocarea lucrului utilizatorilor %1 %2.
			|
			|Aplicația temporar este insccesibilă.';
			|tr = 'Uygulama yöneticisi, %1 %2 kullanıcıların çalışma kilidini ayarladı.
			|
			|Uygulama geçici olarak kullanılamıyor.'; 
			|es_ES = 'Bloqueo de trabajo de usuarios %1 %2 del conjunto de administradores de la aplicación.
			|
			|Aplicación no se encuentra temporalmente disponible.'"), LockPeriod, LockReason);
	Parameters.Insert("DataAreaSessionsLocked", MessageText);
	MessageText = "";
	If Users.IsFullUser() Then
		MessageText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Администратором приложения установлена блокировка работы пользователей %1 %2.
				|
				|Войти в заблокированное приложение?'; 
				|en = 'He administrator denied access to the application %1 %2.
				|
				|Do you want to sign in anyway?'; 
				|pl = 'Administrator aplikacji ustawił %1 %2 blokadę pracy użytkowników.
				|
				|Czy chcesz wejść do zablokowanej aplikacji?';
				|de = 'Anwendungsadministrator setzen %1 %2Benutzer Arbeitssperre.
				| 
				|Möchten Sie in die gesperrte Anwendung einsteigen?';
				|ro = 'Administratorul aplicației a stabilit blocarea lucrului utilizatorilor %1 %2.
				|
				|Intrați în aplicația blocată?';
				|tr = 'Uygulama yöneticisi %1 %2 kullanıcıların iş kilidini ayarladı. 
				|
				|Kilitli uygulamaya girmek istiyor musunuz?'; 
				|es_ES = 'Bloqueo de trabajo de usuarios %1 %2 del conjunto de administradores de la aplicación.
				|
				|¿Quiere entrar en la aplicación bloqueada?'"),
			LockPeriod, LockReason);
	EndIf;
	Parameters.Insert("PromptToAuthorize", MessageText);
	If (Users.IsFullUser() AND Not CurrentMode.Exclusive) 
		Or Users.IsFullUser(, True) Then
		
		Parameters.Insert("CanUnlock", True);
	Else
		Parameters.Insert("CanUnlock", False);
	EndIf;
	
EndProcedure

// See CommonOverridable.OnAddClientParameters. 
Procedure OnAddClientParameters(Parameters) Export
	
	Parameters.Insert("SessionLockParameters", New FixedStructure(SessionLockParameters()));
	
EndProcedure

// See InfobaseUpdateSSL.OnAddUpdateHandlers. 
Procedure OnAddUpdateHandlers(Handlers) Export
	
	Handler = Handlers.Add();
	Handler.Version = "2.1.3.9";
	Handler.Procedure = "IBConnections.MoveDataAreasSessionLocksToAuxiliaryData";
	Handler.SharedData = True;
	
EndProcedure

// See ExportImportDataOverridable.OnFillTypesExcludedFromExportImport. 
Procedure OnFillTypesExcludedFromExportImport(Types) Export
	
	Types.Add(Metadata.InformationRegisters.DataAreaSessionLocks);
	
EndProcedure

// See ToDoListOverridable.OnDetermineToDoListHandlers 
Procedure OnFillToDoList(ToDoList) Export
	
	ModuleToDoListServer = Common.CommonModule("ToDoListServer");
	If Not AccessRight("DataAdministration", Metadata)
		Or ModuleToDoListServer.UserTaskDisabled("SessionsLock") Then
		Return;
	EndIf;
	
	// This procedure is only called when To-do list subsystem is available. Therefore, the subsystem 
	// availability check is redundant.
	Sections = ModuleToDoListServer.SectionsForObject(Metadata.DataProcessors.ApplicationLock.FullName());
	
	LockParameters = SessionLockParameters(False);
	CurrentSessionDate = CurrentSessionDate();
	
	If LockParameters.Use Then
		If CurrentSessionDate < LockParameters.Begin Then
			If LockParameters.End <> Date(1, 1, 1) Then
				Message = StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = 'Запланирована с %1 по %2'; en = 'Scheduled from %1 to %2'; pl = 'Zaplanowane od %1 do %2';de = 'Geplant von %1 bis %2';ro = 'Este planificată de la %1 până la %2';tr = '%1 ile %2 arası için planlandı'; es_ES = 'Programado desde %1 hasta %2'"),
					Format(LockParameters.Begin, "DLF=DT"), Format(LockParameters.End, "DLF=DT"));
			Else
				Message = StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = 'Запланирована с %1'; en = 'Scheduled from %1'; pl = 'Zaplanowane od %1';de = 'Geplant von %1';ro = 'Este planificată de la %1';tr = '%1 itibaren planlandı'; es_ES = 'Programado desde %1'"), Format(LockParameters.Begin, "DLF=DT"));
			EndIf;
			Importance = False;
		ElsIf LockParameters.End <> Date(1, 1, 1) AND CurrentSessionDate > LockParameters.End AND LockParameters.Begin <> Date(1, 1, 1) Then
			Importance = False;
			Message = StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = 'Не действует (истек срок %1)'; en = 'Inactive (expired on %1)'; pl = 'Nieważny (przeterminowany %1)';de = 'Nicht gültig (abgelaufen %1)';ro = 'Nu este valabilă (a expirat %1)';tr = 'Geçerli değil (süresi doldu%1)'; es_ES = 'No válido (caducado %1)'"), Format(LockParameters.End, "DLF=DT"));
		Else
			If LockParameters.End <> Date(1, 1, 1) Then
				Message = StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = 'с %1 по %2'; en = 'from %1 to %2'; pl = 'od %1 do %2';de = 'von %1 bis %2';ro = 'de la %1 la %2';tr = '%1 itibaren %2 kadar'; es_ES = 'desde %1 hasta %2'"),
					Format(LockParameters.Begin, "DLF=DT"), Format(LockParameters.End, "DLF=DT"));
			Else
				Message = StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = 'с %1'; en = 'from %1'; pl = 'od %1';de = 'von %1';ro = 'de la %1';tr = 'itibaren%1'; es_ES = 'desde %1'"), 
					Format(LockParameters.Begin, "DLF=DT"));
			EndIf;
			Importance = True;
		EndIf;
	Else
		Message = NStr("ru = 'Не действует'; en = 'Inactive'; pl = 'Nie aktywny';de = 'Nicht gültig';ro = 'Utilizator inactiv';tr = 'Geçerli değil'; es_ES = 'No válido'");
		Importance = False;
	EndIf;

	
	For Each Section In Sections Do
		
		ToDoItemID = "SessionsLock" + StrReplace(Section.FullName(), ".", "");
		
		ToDoItem = ToDoList.Add();
		ToDoItem.ID  = ToDoItemID;
		ToDoItem.HasToDoItems       = LockParameters.Use;
		ToDoItem.Presentation  = NStr("ru = 'Блокировка работы пользователей'; en = 'Deny user access'; pl = 'Blokowanie operacji użytkownika';de = 'Sperrung der Benutzerbedienung';ro = 'Blocarea lucrului utilizatorilor';tr = 'Kullanıcı operasyon kilitleme'; es_ES = 'Bloqueo de la operación del usuario'");
		ToDoItem.Form          = "DataProcessor.ApplicationLock.Form";
		ToDoItem.Important         = Importance;
		ToDoItem.Owner       = Section;
		
		ToDoItem = ToDoList.Add();
		ToDoItem.ID  = "SessionLockDetails";
		ToDoItem.HasToDoItems       = LockParameters.Use;
		ToDoItem.Presentation  = Message;
		ToDoItem.Owner       = ToDoItemID; 
		
	EndDo;
	
EndProcedure

#EndRegion

#Region Private

////////////////////////////////////////////////////////////////////////////////
// INFOBASE UPDATE HANDLERS

// Transfers data from the RemoveDataAreaSessionLocks information register to the 
//  DataAreaSessionLocks information register.
Procedure MoveDataAreasSessionLocksToAuxiliaryData() Export
	
	If Not Common.DataSeparationEnabled() Then
		Return;
	EndIf;
	
	BeginTransaction();
	
	Try
		
		Lock = New DataLock();
		Lock.Add("InformationRegister.DataAreaSessionLocks");
		Lock.Lock();
		
		QueryText =
			"SELECT
			|	ISNULL(DataAreaSessionLocks.DataAreaAuxiliaryData, DeleteDataAreaSessionLocks.DataArea) AS DataAreaAuxiliaryData,
			|	ISNULL(DataAreaSessionLocks.LockStart, DeleteDataAreaSessionLocks.LockStart) AS LockStart,
			|	ISNULL(DataAreaSessionLocks.LockEnd, DeleteDataAreaSessionLocks.LockEnd) AS LockEnd,
			|	ISNULL(DataAreaSessionLocks.LockMessage, DeleteDataAreaSessionLocks.LockMessage) AS LockMessage,
			|	ISNULL(DataAreaSessionLocks.Exclusive, DeleteDataAreaSessionLocks.Exclusive) AS Exclusive
			|FROM
			|	InformationRegister.DeleteDataAreaSessionLocks AS DeleteDataAreaSessionLocks
			|		LEFT JOIN InformationRegister.DataAreaSessionLocks AS DataAreaSessionLocks
			|		ON DeleteDataAreaSessionLocks.DataArea = DataAreaSessionLocks.DataAreaAuxiliaryData";
		Query = New Query(QueryText);
		
		Set = InformationRegisters.DataAreaSessionLocks.CreateRecordSet();
		Set.Load(Query.Execute().Unload());
		InfobaseUpdate.WriteData(Set);
		
		CommitTransaction();
		
	Except
		
		RollbackTransaction();
		Raise;
		
	EndTry;
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Other.

// Returns session lock message text.
//
// Parameters:
//	Message - String - message for the lock.
//  KeyCode - String - infobase access key code.
//
// Returns:
//   String - lock message.
//
Function GenerateLockMessage(Val Message, Val KeyCode) Export
	
	AdministrationParameters = StandardSubsystemsServer.AdministrationParameters();
	FileModeFlag = False;
	IBPath = IBConnectionsClientServer.InfobasePath(FileModeFlag, AdministrationParameters.ClusterPort);
	InfobasePathString = ?(FileModeFlag = True, "/F", "/S") + IBPath;
	MessageText = "";
	If NOT IsBlankString(Message) Then
		MessageText = Message + Chars.LF + Chars.LF;
	EndIf;
	
	If Common.DataSeparationEnabled() AND Common.SeparatedDataUsageAvailable() Then
		MessageText = MessageText + NStr("ru = '%1
			|Для разрешения работы пользователей можно открыть приложение с параметром РазрешитьРаботуПользователей. Например:
			|http://<веб-адрес сервера>/?C=РазрешитьРаботуПользователей'; 
			|en = '%1
			|To allow user access, open the application with the AllowUserAuthorization parameter. Example:
			|http://<web server address>/?C=AllowUserAuthorization'; 
			|pl = '%1
			|Aby zezwolić użytkownikom na pracę, można otworzyć aplikację za pomocą parametru AllowUsersWork. Na 
			|przykład: http://<server web address>/?C=AllowUsersWork';
			|de = '%1
			|Damit Anwendungen verwendet werden können, können Sie die Anwendung mit dem Parameter BenutzernErlaubenZuArbeiten öffnen. Zum
			|Beispiel: http://<Server-Webadresse>/?C=BenutzernErlaubenZuArbeiten';
			|ro = '%1
			|Pentru a permite lucrul utilizatorilor puteți deschide aplicația cu parametrul РазрешитьРаботуПользователей. De exemplu:
			|http://<adresa web a serverului>/?C=РазрешитьРаботуПользователей';
			|tr = '%1
			|Kullanımlara izin vermek için, KullanıcılarınÇalışmasınaİzin Ver parametresiyle uygulamayı açabilirsiniz.
			| Örneğin: http: // <sunucu web adresi> /? C = KullanıcılarınÇalışmasınaİzinVer'; 
			|es_ES = '%1
			|Para permitir el trabajo de usos, usted puede abrir la aplicación con el parámetro AllowUsersWork. Por
			|ejemplo: http://<server web address>/?C=AllowUsersWork'");
		MessageText = StringFunctionsClientServer.SubstituteParametersToString(MessageText, IBConnectionsClientServer.TextForAdministrator());
	Else
		MessageText = MessageText + NStr("ru = '%1
			|Для того чтобы разрешить работу пользователей, воспользуйтесь консолью кластера серверов или запустите ""1С:Предприятие"" с параметрами:
			|ENTERPRISE %2 /CРазрешитьРаботуПользователей /UC%3'; 
			|en = '%1
			|To allow user access, use the server cluster console or run 1C:Enterprise with parameters:
			|ENTERPRISE %2 /CAllowUserAuthorization /UC%3'; 
			|pl = '%1
			|Aby zezwolić pracę użytkownikom, skorzystaj z konsoli klastra serwerów lub uruchom ""1C:Enterprise"" z konfiguracją:
			|ENTERPRISE %2/CZezwolićPracęUżytkowników /UC %3';
			|de = '%1
			|Um Benutzern die Arbeit zu ermöglichen, verwenden Sie die Server Cluster-Konsole oder führen Sie ""1C:Enterprise"" mit den Parametern:
			|ENTERPRISE %2/CBenutzeraktivitäten zulassen/UC%3aus';
			|ro = '%1
			|Pentru a permite lucrul utilizatorilor utilizați consola clusterului serverelor sau lansați ""1C:Enterprise"" cu parametrii:
			|ENTERPRISE %2 /CРазрешитьРаботуПользователей /UC%3';
			|tr = '%1
			|Kullanıcıların  çalışmasına izin vermek için sunucu kümesi konsolu veya  ""1C:
			|  İşletme%2"" aşağıdaki parametrelerle başlatın: ENTERPRISE /  CAllowUsersWork / UC%3'; 
			|es_ES = '%1
			|Para permitir el trabajo de usos, utilizar la consola del clúster de servidores, o iniciar la ""1C:Enterprise"" con los parámetros:
			|ENTERPRISE %2/CAllowUserOperations /UCC%3'");
		MessageText = StringFunctionsClientServer.SubstituteParametersToString(MessageText, IBConnectionsClientServer.TextForAdministrator(),
			InfobasePathString, NStr("ru = '<код разрешения>'; en = '<access code>'; pl = '<kod uprawnienia>';de = '<Berechtigungscode>';ro = '<codul permisiunii>';tr = '<izin kodu>'; es_ES = '<código del permiso>'"));
	EndIf;
	
	Return MessageText;
	
EndFunction

// Returns the flag specifying whether a connection lock is set for a specific date.
//
// Parameters:
//  CurrentMode - SessionsLock - sessions lock.
//  CurrentDate - Date - date to check.
//
// Returns:
//  Boolean - True if set.
//
Function ConnectionsLockedForDate(CurrentMode, CurrentDate)
	
	Return (CurrentMode.Use AND CurrentMode.Begin <= CurrentDate 
		AND (Not ValueIsFilled(CurrentMode.End) Or CurrentDate <= CurrentMode.End));
	
EndFunction

// See the description in the SessionLockParameters function.
//
Function AdvancedSessionLockParameters(Val GetSessionCount, LockParameters)
	
	If LockParameters.IBConnectionLockSetForDate Then
		CurrentMode = LockParameters.CurrentIBMode;
	ElsIf LockParameters.DataAreaConnectionLockSetForDate Then
		CurrentMode = LockParameters.CurrentDataAreaMode;
	ElsIf LockParameters.CurrentIBMode.Use Then
		CurrentMode = LockParameters.CurrentIBMode;
	Else
		CurrentMode = LockParameters.CurrentDataAreaMode;
	EndIf;
	
	SetPrivilegedMode(True);
	
	Result = New Structure;
	Result.Insert("Use", CurrentMode.Use);
	Result.Insert("Begin", CurrentMode.Begin);
	Result.Insert("End", CurrentMode.End);
	Result.Insert("Message", CurrentMode.Message);
	Result.Insert("SessionTerminationTimeout", 15 * 60);
	Result.Insert("SessionCount", ?(GetSessionCount, InfobaseSessionCount(), 0));
	Result.Insert("CurrentSessionDate", LockParameters.CurrentDate);
	Result.Insert("RestartOnCompletion", True);
	
	IBConnectionsOverridable.OnDetermineSessionLockParameters(Result);
	
	Return Result;
	
EndFunction

Function CurrentConnectionLockParameters()
	
	// CurrentSessionDate is not applied, because the lock is set in the server time zone.
	CurrentDate = CurrentDate();
	
	SetPrivilegedMode(True);
	CurrentIBMode = GetSessionsLock();
	CurrentDataAreaMode = GetDataAreaSessionLock();
	SetPrivilegedMode(False);
	
	IBLockedForDate = ConnectionsLockedForDate(CurrentIBMode, CurrentDate);
	AreaLockedAtDate = ConnectionsLockedForDate(CurrentDataAreaMode, CurrentDate);
	ConnectionsLocked = IBLockedForDate Or AreaLockedAtDate;
	
	Parameters = New Structure;
	Parameters.Insert("CurrentDate", CurrentDate);
	Parameters.Insert("CurrentIBMode", CurrentIBMode);
	Parameters.Insert("CurrentDataAreaMode", CurrentDataAreaMode);
	Parameters.Insert("IBConnectionLockSetForDate", IBLockedForDate);
	Parameters.Insert("DataAreaConnectionLockSetForDate", AreaLockedAtDate);
	Parameters.Insert("ConnectionsLocked", ConnectionsLocked);
	
	Return Parameters;
	
EndFunction

// Returns a string constant for generating event log messages.
//
// Returns:
//   String - an event description for the event log.
//
Function EventLogEvent() Export
	
	Return NStr("ru = 'Завершение работы пользователей'; en = 'User sessions'; pl = 'Zakończenie pracy użytkowników';de = 'Benutzerarbeit abgeschlossen';ro = 'Finalizarea lucrului utilizatorilor';tr = 'Kullanıcı çalışmasını tamamlanma'; es_ES = 'Finalización del trabajo de usuario'", Common.DefaultLanguageCode());
	
EndFunction

#EndRegion
