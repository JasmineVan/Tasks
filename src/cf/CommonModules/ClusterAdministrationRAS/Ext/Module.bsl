///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Internal

#Region SessionAndJobLock

// Returns the current state of infobase session locks and scheduled job locks.
//
// Parameters:
//   ClusterAdministrationParameters - Structure - the structure that describes parameters for 
//                  connecting the server cluster. For details, see ClusterAdministration. ClusterAdministrationParameters().
//   IBAdministrationParameters - Structure - the structure describing infobase connection 
//                  parameters. For details, see ClusterAdministration. ClusterInfobaseAdministrationParameters().
//
// Returns:
//   Structure - structure that describes the state of session and scheduled job lock. For details, 
//                  see ClusterAdministration.SessionAndScheduleJobLockProperties(). 
//
Function InfobaseSessionAndJobLock(Val ClusterAdministrationParameters, Val IBAdministrationParameters) Export
	
	Result = InfobaseProperties(ClusterAdministrationParameters, IBAdministrationParameters, SessionAndScheduledJobLockPropertiesDictionary());
	
	If Result.DateFrom = ClusterAdministration.EmptyDate() Then
		Result.DateFrom = Undefined;
	EndIf;
	
	If Result.DateTo = ClusterAdministration.EmptyDate() Then
		Result.DateTo = Undefined;
	EndIf;
	
	If Not ValueIsFilled(Result.KeyCode) Then
		Result.KeyCode = "";
	EndIf;
	
	If Not ValueIsFilled(Result.Message) Then
		Result.Message = "";
	EndIf;
	
	If Not ValueIsFilled(Result.LockParameter) Then
		Result.LockParameter = "";
	EndIf;
	
	Return Result;
	
EndFunction

// Sets the state of infobase session locks and scheduled job locks.
//
// Parameters:
//   ClusterAdministrationParameters - Structure - the structure that describes parameters for 
//                  connecting the server cluster. For details, see ClusterAdministration. ClusterAdministrationParameters().
//   IBAdministrationParameters - Structure - the structure describing infobase connection 
//                  parameters. For details, see ClusterAdministration. ClusterInfobaseAdministrationParameters().
//   SessionAndJobLockProperties - Structure - the structure describing the state of session and 
//                  scheduled job lock. For details, see ClusterAdministration. SessionAndScheduleJobLockProperties().
//
Procedure SetInfobaseSessionAndJobLock(Val ClusterAdministrationParameters, Val IBAdministrationParameters, Val SessionAndJobLockProperties) Export
	
	SetInfobaseProperties(
		ClusterAdministrationParameters,
		IBAdministrationParameters,
		SessionAndScheduledJobLockPropertiesDictionary(),
		SessionAndJobLockProperties);
	
EndProcedure

// Checks whether administration parameters are filled correctly.
//
// Parameters:
//   ClusterAdministrationParameters - Structure - the structure that describes parameters for 
//                  connecting the server cluster. For details, see ClusterAdministration. ClusterAdministrationParameters().
//   IBAdministrationParameters - Structure - the structure describing infobase connection 
//                  parameters. For details, see ClusterAdministration. ClusterInfobaseAdministrationParameters().
//   CheckClusterAdministrationParameters - Boolean - indicates whether cluster administration parameters check is required
//   CheckClusterAdministrationParameters - Boolean - Indicates whether cluster administration 
//                  parameters check is required.
//
Procedure CheckAdministrationParameters(Val ClusterAdministrationParameters, Val IBAdministrationParameters = Undefined,
	CheckInfobaseAdministrationParameters = True,
	CheckClusterAdministrationParameters = True) Export
	
	If CheckClusterAdministrationParameters Or CheckInfobaseAdministrationParameters Then
		
		Try
			ClusterID = ClusterID(ClusterAdministrationParameters);
			WorkingProcessesProperties(ClusterID, ClusterAdministrationParameters);
		Except
			Raise StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = '%1
				           |
				           |Если на компьютере %2 не запущен сервер администрирования (ras),
				           |следует его запустить.
				           |
				           |Например:
				           |""%3"" cluster --port=%4 %5:%6
				           |
				           |В противном случае следует проверить параметры подключения и сетевого экрана.'; 
				           |en = '%1
				           |
				           |Run ras administration server on %2.
				           |
				           |Example:
				           |""%3"" cluster --port=%4 %5:%6
				           |
				           |If ras has been running,
				           |check connection parameters and firewall settings.'; 
				           |pl = '%1
				           |
				           |Jeśli na komputerze %2 nie działa  serwer administrowania (ras),
				           |należy jego uruchomić.
				           |
				           |Na przykład:
				           |""%3"" cluster --port=%4 %5:%6
				           |
				           |W przeciwnym razie sprawdź ustawienia połączenia i zapory sieciowej.';
				           |de = '%1
				           |
				           |Wenn der Administrationsserver %2 (ras) nicht auf Ihrem Computer läuft,
				           |sollten Sie ihn starten.
				           |
				           |Zum Beispiel:
				           |""%3"" cluster --port=%4%5:%6
				           |
				           |Andernfalls sollten Sie die Verbindungsparameter und den Netzwerkbildschirm überprüfen.';
				           |ro = '%1
				           |
				           |Dacă pe computerul %2 nu este lansat serverul de administrare (ras),
				           |atunci lansați-l.
				           |
				           |De exemplu:
				           |""%3"" cluster --port=%4 %5:%6
				           |
				           |În caz contrar trebuie să verificați parametrii de conectare și ai ecranului de rețea.';
				           |tr = '%1
				           |
				           |Bilgisayarda yönetim %2 sunucusu (ras) çalıştırılmamışsa,
				           |çalıştırılmalıdır.
				           |
				           |Örneğin:
				           |""%3"" cluster --port=%4 %5:%6
				           |
				           |Aksi halde bağlantı ve ağ ekranın parametreleri kontrol edilmelidir.'; 
				           |es_ES = '%1
				           |
				           |Si en el ordenador %2 no se ha lanzado el servidor de administración (ras),
				           |hay que lanzarlo.
				           |
				           |Por ejemplo:
				           |""%3"" cluster --port=%4 %5:%6
				           |
				           |En el caso contrario hay que comprobar los parámetros de conexión y de pantalla de red.'"),
				BriefErrorDescription(ErrorInfo()),
				ComputerName(),
				BinDir() + ?(Common.IsWindowsServer(), "ras.exe", "ras"),
				XMLString(ClusterAdministrationParameters.AdministrationServerPort),
				ClusterAdministrationParameters.ServerAgentAddress,
				XMLString(ClusterAdministrationParameters.ServerAgentPort));
		EndTry;
		
	EndIf;
	
	If CheckInfobaseAdministrationParameters Then
		
		Dictionary = New Structure();
		Dictionary.Insert("SessionsLock", "sessions-deny");
		
		InfobaseProperties(ClusterAdministrationParameters, IBAdministrationParameters, Dictionary);
		
	EndIf;
	
EndProcedure

#EndRegion

#Region ScheduledJobLock

// Returns the current state of infobase scheduled job locks.
//
// Parameters:
//   ClusterAdministrationParameters - Structure - the structure that describes parameters for 
//                  connecting the server cluster. For details, see ClusterAdministration. ClusterAdministrationParameters().
//   IBAdministrationParameters - Structure - the structure describing infobase connection 
//                  parameters. For details, see ClusterAdministration. ClusterInfobaseAdministrationParameters().
//
// Returns: Boolean.
//
Function InfobaseScheduledJobLock(Val ClusterAdministrationParameters, Val IBAdministrationParameters) Export
	
	Dictionary = New Structure("ScheduledJobLock", "scheduled-jobs-deny");
	
	IBProperties = InfobaseProperties(ClusterAdministrationParameters, IBAdministrationParameters, Dictionary);
	Return IBProperties.ScheduledJobLock;
	
EndFunction

// Sets the state of infobase scheduled job locks.
//
// Parameters:
//   ClusterAdministrationParameters - Structure - the structure that describes parameters for 
//                  connecting the server cluster. For details, see ClusterAdministration. ClusterAdministrationParameters().
//   IBAdministrationParameters - Structure - the structure describing infobase connection 
//                  parameters. For details, see ClusterAdministration. ClusterInfobaseAdministrationParameters().
//   ScheduledJobLock - Boolean - indicates whether infobase scheduled jobs are locked.
//
Procedure SetInfobaseScheduledJobLock(Val ClusterAdministrationParameters, Val IBAdministrationParameters, Val ScheduledJobLock) Export
	
	Dictionary = New Structure("ScheduledJobLock", "scheduled-jobs-deny");
	Properties = New Structure("ScheduledJobLock", ScheduledJobLock);
	
	SetInfobaseProperties(
		ClusterAdministrationParameters,
		IBAdministrationParameters,
		Dictionary,
		Properties);
	
EndProcedure

#EndRegion

#Region InfobaseSessions

// Returns descriptions of infobase sessions.
//
// Parameters:
//   ClusterAdministrationParameters - Structure - the structure that describes parameters for 
//                  connecting the server cluster. For details, see ClusterAdministration. ClusterAdministrationParameters().
//   IBAdministrationParameters - Structure - the structure describing infobase connection 
//                  parameters. For details, see ClusterAdministration. ClusterInfobaseAdministrationParameters().
//   Filter - Description of filter criteria for sessions whose descriptions are required.
//      Options:
//         1. Array of structures that describe session filter criteria. Each array structure has the following fields:
//            Property - String - property name to be used in the filter. For valid values, see
//               Return value of the ClusterAdministration.SessionProperties() function,
//            ComparisonType - ComparisonType - value of system enumeration ComparisonType, the type 
//               of comparing the session values and the filter values. The following values are available:
//                  ComparisonType.Equal,
//                  ComparisonType.NotEqual,
//                  ComparisonType.Greater (for numeric values only),
//                  ComparisonType.GreaterOrEqual (for numeric values only),
//                  ComparisonType.Less (for numeric values only),
//                  ComparisonType.LessOrEqual (for numeric values only),
//                  ComparisonType.InList,
//                  ComparisonType.NotInList,
//                  ComparisonType.Interval (for numeric values only),
//                  ComparisonType.IntervalIncludingBounds (for numeric values only),
//                  ComparisonType.IntervalIncludingLowerBound (for numeric values only),
//                  ComparisonType.IntervalIncludingUpperBound (for numeric values only),
//            Value - Number, String, Data, Boolean, ValueList, Array, Structure - the value the 
//               matching session property value is compared with. For ComparisonType.InList and 
//               ComparisonType.NotInList, the passed values are ValueList or Array that contain the 
//               set of values to compare to. For ComparisonType.Interval, ComparisonType.IntervalIncludingBounds,
//               ComparisonType.IntervalIncludingLowerBound, and ComparisonType.
//               IntervalIncludingUpperBound, the passed value contains a structure with the From 
//               and To fields that forms an interval to be compared to.
//         2. Structure (simplified). Key - the session property Name (mentioned above). Value - the 
//            value to compare to. When you use this filter description, the comparison always 
//            checks for equality.
//
// Returns:
//   Array - an array of structures that describe the session properties. For more details see 
//                  ClusterAdministration.SessionProperties(). 
//
Function InfobaseSessions(Val ClusterAdministrationParameters, Val IBAdministrationParameters, Val Filter = Undefined) Export
	
	ClusterID = ClusterID(ClusterAdministrationParameters);
	InfobaseID = InfoBaseID(ClusterID, ClusterAdministrationParameters, IBAdministrationParameters);
		
	ClusterParameters = ClusterParameters(ClusterAdministrationParameters, ClusterID);
	
	// Licenses for processes.
	Command = "process list --licenses " + ClusterParameters;
	ProcessLicenses = New Map;
	For Each License In RunCommand(Command, ClusterAdministrationParameters, , , LicensePropertyTypes()) Do
		License.Insert("license-type", ?(License["license-type"] = "soft", 0, 1));
		ProcessLicenses.Insert(License["process"], License); 
	EndDo;
	
	// Processes.
	Command = "process list " + ClusterParameters;
	Processes = New Map;
	For Each Process In RunCommand(Command, ClusterAdministrationParameters, , , WorkingProcessPropertyTypes()) Do
		Process.Insert("license", ProcessLicenses[Process["process"]]);
		Process.Insert("running", ?(Process["running"], 1, 0));
		Process.Insert("use", ?(Process["use"] = "used", 1, ?(Process["use"] = "not-used", 0, 2)));  // "not-used" is inaccurate value.
		Processes.Insert(Process["process"], Process);
	EndDo;
	
	// Connection details.
	Command = "connection list " + ClusterParameters;
	ConnectionDetails = New Map;
	For Each Connection In RunCommand(Command, ClusterAdministrationParameters, , , ConnectionDetailsPropertyTypes()) Do
		Connection.Insert("process", Processes[Connection["process"]]);
		ConnectionDetails.Insert(Connection["connection"], Connection);
	EndDo;
	
	// Licenses for sessions.
	Command = "session list --licenses " + ClusterParameters;
	SessionLicenses = New Map;
	For Each SessionLicense In RunCommand(Command, ClusterAdministrationParameters, , , LicensePropertyTypes()) Do
		SessionLicense.Insert("license-type", ?(SessionLicense["license-type"] = "soft", 0, 1));
		SessionLicenses.Insert(SessionLicense["session"], SessionLicense);
	EndDo;
	
	// Session locks.
	Command = "lock list --infobase=%1 " + ClusterParameters;
	SubstituteParametersToCommand(Command, InfobaseID);
	SessionLocks = New Map();
	For Each SessionLock In RunCommand(Command, ClusterAdministrationParameters, , , LockPropertyTypes()) Do
		ClusterAdministration.SessionDataFromLock(SessionLocks,
		                                                               SessionLock["descr"],
		                                                               SessionLock["session"],
		                                                               IBAdministrationParameters.NameInCluster); 

	EndDo;
	
	// Sessions.
	Command = "session list --infobase=%1 " + ClusterParameters;
	SubstituteParametersToCommand(Command, InfobaseID);
	Filter = FilterToRacNotation(Filter, SessionPropertiesDictionary());
	Result = New Array;
	For Each Session In RunCommand(Command, ClusterAdministrationParameters, , Filter, SessionPropertyTypes()) Do
		Session.Insert("process", Processes[Session["process"]]);
		Session.Insert("license", SessionLicenses[Session["session"]]);
		Session.Insert("connection", ConnectionDetails[Session["connection"]]);
		ParsedSession = ParseOutputItem(Session, SessionPropertiesDictionary());
		
		ParsedSession.Insert("DBLockMode", ?(SessionLocks[Session["session"]] <> Undefined, SessionLocks[Session["session"]].DBLockMode, ""));
		ParsedSession.Insert("Separator", ?(SessionLocks[Session["session"]] <> Undefined, SessionLocks[Session["session"]].Separator, ""));
		
		Result.Add(ParsedSession);
	EndDo;
	
	Return Result;
	
EndFunction

// Deletes infobase sessions according to filter.
//
// Parameters:
//   ClusterAdministrationParameters - Structure - the structure that describes parameters for 
//                  connecting the server cluster. For details, see ClusterAdministration. ClusterAdministrationParameters().
//   IBAdministrationParameters - Structure - the structure describing infobase connection 
//                  parameters. For details, see ClusterAdministration. ClusterInfobaseAdministrationParameters().
//   Filter - Description of filter criteria for sessions whose descriptions are required.
//      Options:
//         1. Array of structures that describe session filter criteria. Each array structure has the following fields:
//            Property - String - property name to be used in the filter. For valid values, see
//               Return value of the ClusterAdministration.SessionProperties() function,
//            ComparisonType - ComparisonType - value of system enumeration ComparisonType, the type 
//               of comparing the session values and the filter values. The following values are available:
//                  ComparisonType.Equal,
//                  ComparisonType.NotEqual,
//                  ComparisonType.Greater (for numeric values only),
//                  ComparisonType.GreaterOrEqual (for numeric values only),
//                  ComparisonType.Less (for numeric values only),
//                  ComparisonType.LessOrEqual (for numeric values only),
//                  ComparisonType.InList,
//                  ComparisonType.NotInList,
//                  ComparisonType.Interval (for numeric values only),
//                  ComparisonType.IntervalIncludingBounds (for numeric values only),
//                  ComparisonType.IntervalIncludingLowerBound (for numeric values only),
//                  ComparisonType.IntervalIncludingUpperBound (for numeric values only),
//            Value - Number, String, Data, Boolean, ValueList, Array, Structure - the value the 
//               matching session property value is compared with. For ComparisonType.InList and 
//               ComparisonType.NotInList, the passed values are ValueList or Array that contain the 
//               set of values to compare to. For ComparisonType.Interval, ComparisonType.IntervalIncludingBounds,
//               ComparisonType.IntervalIncludingLowerBound, and ComparisonType.
//               IntervalIncludingUpperBound, the passed value contains a structure with the From 
//               and To fields that forms an interval to be compared to.
//         2. Structure (simplified). Key - the session property Name (mentioned above). Value - the 
//            value to compare to. When you use this filter description, the comparison always 
//            checks for equality.
//
Procedure DeleteInfobaseSessions(Val ClusterAdministrationParameters, Val IBAdministrationParameters, Val Filter = Undefined) Export
	
	ClusterID = ClusterID(ClusterAdministrationParameters);
	InfobaseID = InfoBaseID(ClusterID, ClusterAdministrationParameters, IBAdministrationParameters);
	
	ClusterParameters = ClusterParameters(ClusterAdministrationParameters, ClusterID);
	
	AttemptCount = 3;
	AllSessionsTerminated = False;
	
	For CurrentAttempt = 0 To AttemptCount Do
		
		Sessions = SessionsProperties(ClusterID, ClusterAdministrationParameters, InfobaseID, Filter, False);
		
		If Sessions.Count() = 0 Then
			
			AllSessionsTerminated = True;
			Break;
			
		ElsIf CurrentAttempt = AttemptCount Then
			
			Break;
			
		EndIf;
		
		For Each Session In Sessions Do
			
			Try
				
				Command = "session terminate --session=%1 " + ClusterParameters;
				SubstituteParametersToCommand(Command,  Session.Get("session"));
				RunCommand(Command, ClusterAdministrationParameters);
				
			Except
				
				// The session might close before rac session terminate is called.
				Continue;
				
			EndTry;
			
		EndDo;
		
	EndDo;
	
	If Not AllSessionsTerminated Then
	
		Raise NStr("ru = 'Не удалось удалить сеансы.'; en = 'Cannot delete sessions.'; pl = 'Nie udało się usunąć sesji.';de = 'Die Sitzungen konnten nicht gelöscht werden.';ro = 'Eșec la ștergerea sesiunilor.';tr = 'Oturumlar devre dışı bırakılamadı.'; es_ES = 'No se ha podido eliminar las sesiones.'");
		
	EndIf;
	
EndProcedure

#EndRegion

#Region InfobaseConnections

// Returns descriptions of infobase connections.
//
// Parameters:
//   ClusterAdministrationParameters - Structure - the structure that describes parameters for 
//                  connecting the server cluster. For details, see ClusterAdministration. ClusterAdministrationParameters().
//   IBAdministrationParameters - Structure - the structure describing infobase connection 
//                  parameters. For details, see ClusterAdministration. ClusterInfobaseAdministrationParameters().
//   Filter - Description of filter criteria for sessions whose descriptions are required.
//      Options:
//         1. Array of structures that describe session filter criteria. Each array structure has the following fields:
//            Property - String - property name to be used in the filter. For valid values, see
//               Return value of the ClusterAdministration.SessionProperties() function,
//            ComparisonType - ComparisonType - value of system enumeration ComparisonType, the type 
//               of comparing the session values and the filter values. The following values are available:
//                  ComparisonType.Equal,
//                  ComparisonType.NotEqual,
//                  ComparisonType.Greater (for numeric values only),
//                  ComparisonType.GreaterOrEqual (for numeric values only),
//                  ComparisonType.Less (for numeric values only),
//                  ComparisonType.LessOrEqual (for numeric values only),
//                  ComparisonType.InList,
//                  ComparisonType.NotInList,
//                  ComparisonType.Interval (for numeric values only),
//                  ComparisonType.IntervalIncludingBounds (for numeric values only),
//                  ComparisonType.IntervalIncludingLowerBound (for numeric values only),
//                  ComparisonType.IntervalIncludingUpperBound (for numeric values only),
//            Value - Number, String, Data, Boolean, ValueList, Array, Structure - the value the 
//               matching session property value is compared with. For ComparisonType.InList and 
//               ComparisonType.NotInList, the passed values are ValueList or Array that contain the 
//               set of values to compare to. For ComparisonType.Interval, ComparisonType.IntervalIncludingBounds,
//               ComparisonType.IntervalIncludingLowerBound, and ComparisonType.
//               IntervalIncludingUpperBound, the passed value contains a structure with the From 
//               and To fields that forms an interval to be compared to.
//         2. Structure (simplified). Key - the session property Name (mentioned above). Value - the 
//            value to compare to. When you use this filter description, the comparison always 
//            checks for equality.
//
// Returns: Array of Structure that describes connection properties. For structure descriptions, see 
//  ClusterAdministration.ConnectionProperties(). 
//
Function InfobaseConnections(Val ClusterAdministrationParameters, Val IBAdministrationParameters, Val Filter = Undefined) Export
	
	ClusterID = ClusterID(ClusterAdministrationParameters);
	InfobaseID = InfoBaseID(ClusterID, ClusterAdministrationParameters, IBAdministrationParameters);
	Return ConnectionsProperties(ClusterID, ClusterAdministrationParameters, InfobaseID, IBAdministrationParameters, Filter, True);
	
EndFunction

// Terminates infobase connections according to filter.
//
// Parameters:
//   ClusterAdministrationParameters - Structure - the structure that describes parameters for 
//                  connecting the server cluster. For details, see ClusterAdministration. ClusterAdministrationParameters().
//   IBAdministrationParameters - Structure - the structure describing infobase connection 
//                  parameters. For details, see ClusterAdministration. ClusterInfobaseAdministrationParameters().
//   Filter - Description of filter criteria for sessions whose descriptions are required.
//      Options:
//         1. Array of structures that describe session filter criteria. Each array structure has the following fields:
//            Property - String - property name to be used in the filter. For valid values, see
//               Return value of the ClusterAdministration.SessionProperties() function,
//            ComparisonType - ComparisonType - value of system enumeration ComparisonType, the type 
//               of comparing the session values and the filter values. The following values are available:
//                  ComparisonType.Equal,
//                  ComparisonType.NotEqual,
//                  ComparisonType.Greater (for numeric values only),
//                  ComparisonType.GreaterOrEqual (for numeric values only),
//                  ComparisonType.Less (for numeric values only),
//                  ComparisonType.LessOrEqual (for numeric values only),
//                  ComparisonType.InList,
//                  ComparisonType.NotInList,
//                  ComparisonType.Interval (for numeric values only),
//                  ComparisonType.IntervalIncludingBounds (for numeric values only),
//                  ComparisonType.IntervalIncludingLowerBound (for numeric values only),
//                  ComparisonType.IntervalIncludingUpperBound (for numeric values only),
//            Value - Number, String, Data, Boolean, ValueList, Array, Structure - the value the 
//               matching session property value is compared with. For ComparisonType.InList and 
//               ComparisonType.NotInList, the passed values are ValueList or Array that contain the 
//               set of values to compare to. For ComparisonType.Interval, ComparisonType.IntervalIncludingBounds,
//               ComparisonType.IntervalIncludingLowerBound, and ComparisonType.
//               IntervalIncludingUpperBound, the passed value contains a structure with the From 
//               and To fields that forms an interval to be compared to.
//         2. Structure (simplified). Key - the session property Name (mentioned above). Value - the 
//            value to compare to. When you use this filter description, the comparison always 
//            checks for equality.
//
Procedure TerminateInfobaseConnections(Val ClusterAdministrationParameters, Val IBAdministrationParameters, Val Filter = Undefined) Export
	
	ClusterID = ClusterID(ClusterAdministrationParameters);
	InfobaseID = InfoBaseID(ClusterID, ClusterAdministrationParameters, IBAdministrationParameters);
	
	ClusterParameters = ClusterParameters(ClusterAdministrationParameters, ClusterID);
	
	Value = New Array;
	Value.Add("1CV8");               // ID of 1C:Enterprise application running in thick client mode.
	Value.Add("1CV8C");              // ID of 1C:Enterprise application running in thin client mode.
	Value.Add("WebClient");          // ID of 1C:Enterprise application running in web client mode.
	Value.Add("Designer");           // ID of Designer.
	Value.Add("COMConnection");      // ID of 1C:Enterprise external COM connection session.
	Value.Add("WSConnection");       // ID of web service session.
	Value.Add("BackgroundJob");      // ID of job processing session.
	Value.Add("WebServerExtension"); // ID of web server extension.

	ClusterAdministration.AddFilterCondition(Filter, "ClientApplicationID", ComparisonType.InList, Value);
	
	AttemptCount = 3;
	AllConnectionsTerminated = False;
	
	For CurrentAttempt = 0 To AttemptCount Do
	
		Connections = ConnectionsProperties(ClusterID, ClusterAdministrationParameters, InfobaseID, IBAdministrationParameters, Filter, False);
		
		If Connections.Count() = 0 Then
			
			AllConnectionsTerminated = True;
			Break;
			
		ElsIf CurrentAttempt = AttemptCount Then
			
			Break;
			
		EndIf;
	
		For Each Connection In Connections Do
			
			Try
				
				Command = "connection disconnect --process=%1 --connection=%2 --infobase-user=%3 --infobase-pwd=%4 " + ClusterParameters;
				SubstituteParametersToCommand(Command,
					Connection.Get("process"),
					Connection.Get("connection"),
					IBAdministrationParameters.InfobaseAdministratorName,
					IBAdministrationParameters.InfobaseAdministratorPassword);
				RunCommand(Command, ClusterAdministrationParameters);
				
			Except
				
				// The connection might terminate before rac connection disconnect is called.
				Continue;
				
			EndTry;
			
		EndDo;
		
	EndDo;
	
	If Not AllConnectionsTerminated Then
	
		Raise NStr("ru = 'Не удалось разорвать соединения.'; en = 'Cannot close connections.'; pl = 'Nie udało się przerwać połączenie.';de = 'Die Verbindungen konnten nicht unterbrochen werden.';ro = 'Eșec la întreruperea conexiunii.';tr = 'Bağlantı koparılamadı.'; es_ES = 'No se ha podido desconectar.'");
		
	EndIf;
	
EndProcedure

#EndRegion

#Region SecurityProfiles

// Returns the name of a security profile assigned to the infobase.
//
// Parameters:
//   ClusterAdministrationParameters - (See ClusterAdministration.ClusterAdministrationParameters)
//   IBAdministrationParameters - See ClusterAdministration.ClusterInfobaseAdministrationParameters)
//
// Returns:
//   String - name of the security profile set for the infobase. If the infobase is not assigned 
//                  with a security profile, returns an empty string.
//
Function InfobaseSecurityProfile(Val ClusterAdministrationParameters, Val IBAdministrationParameters) Export
	
	Dictionary = New Structure();
	Dictionary.Insert("ProfileName", "security-profile-name");
	
	Result = InfobaseProperties(ClusterAdministrationParameters, IBAdministrationParameters, Dictionary).ProfileName;
	If ValueIsFilled(Result) Then
		Return Result;
	Else
		Return "";
	EndIf;
	
EndFunction

// Returns the name of the security profile that was set as the infobase safe mode security profile.
//  
//
// Parameters:
//   ClusterAdministrationParameters - Structure - the structure that describes parameters for 
//                  connecting the server cluster. For details, see ClusterAdministration. ClusterAdministrationParameters().
//   IBAdministrationParameters - Structure - the structure describing infobase connection 
//                  parameters. For details, see ClusterAdministration. ClusterInfobaseAdministrationParameters().
//
// Returns:
//   String - name of the security profile set for the infobase as the safe mode security profile.
//                   If the infobase is not assigned with a security profile, returns an empty string.
//
Function InfobaseSafeModeSecurityProfile(Val ClusterAdministrationParameters, Val IBAdministrationParameters) Export
	
	Dictionary = New Structure();
	Dictionary.Insert("ProfileName", "safe-mode-security-profile-name");
	
	Result = InfobaseProperties(ClusterAdministrationParameters, IBAdministrationParameters, Dictionary).ProfileName;
	If ValueIsFilled(Result) Then
		Return Result;
	Else
		Return "";
	EndIf;
	
EndFunction

// Assigns a security profile to an infobase.
//
// Parameters:
//   ClusterAdministrationParameters - Structure - the structure that describes parameters for 
//                  connecting the server cluster. For details, see ClusterAdministration. ClusterAdministrationParameters().
//   IBAdministrationParameters - Structure - the structure describing infobase connection 
//                  parameters. For details, see ClusterAdministration. ClusterInfobaseAdministrationParameters().
//   ProfileName - String - the security profile name. If the passed string is empty, the security 
//                  profile is disabled for the infobase.
//
Procedure SetInfobaseSecurityProfile(Val ClusterAdministrationParameters, Val IBAdministrationParameters, Val ProfileName = "") Export
	
	Dictionary = New Structure();
	Dictionary.Insert("ProfileName", "security-profile-name");
	
	Values = New Structure();
	Values.Insert("ProfileName", ProfileName);
	
	SetInfobaseProperties(
		ClusterAdministrationParameters,
		IBAdministrationParameters,
		Dictionary,
		Values);
	
EndProcedure

// Assigns a safe-mode security profile to an infobase.
//
// Parameters:
//   ClusterAdministrationParameters - Structure - the structure that describes parameters for 
//                  connecting the server cluster. For details, see ClusterAdministration. ClusterAdministrationParameters().
//   IBAdministrationParameters - Structure - the structure describing infobase connection 
//                  parameters. For details, see ClusterAdministration. ClusterInfobaseAdministrationParameters().
//   ProfileName - String - the security profile name. If the passed string is empty, the safe mode 
//                  security profile is disabled for the infobase.
//
Procedure SetInfobaseSafeModeSecurityProfile(Val ClusterAdministrationParameters, Val IBAdministrationParameters, Val ProfileName = "") Export
	
	Dictionary = New Structure();
	Dictionary.Insert("ProfileName", "safe-mode-security-profile-name");
	
	Values = New Structure();
	Values.Insert("ProfileName", ProfileName);
	
	SetInfobaseProperties(
		ClusterAdministrationParameters,
		IBAdministrationParameters,
		Dictionary,
		Values);
	
EndProcedure

// Checks whether a security profile exists in the server cluster.
//
// Parameters:
//   ClusterAdministrationParameters - Structure - the structure that describes parameters for 
//                  connecting the server cluster. For details, see ClusterAdministration. ClusterAdministrationParameters().
//     ProfileName - String - the security profile name.
//
// Returns:
//   Boolean
//
Function SecurityProfileExists(Val ClusterAdministrationParameters, Val ProfileName) Export
	
	Filter = New Structure("Name", ProfileName);
	
	ClusterID = ClusterID(ClusterAdministrationParameters);
	
	SecurityProfiles = GetSecurityProfiles(ClusterID, ClusterAdministrationParameters, Filter);
	
	Return (SecurityProfiles.Count() = 1);
	
EndFunction

// Returns properties of a security profile.
//
// Parameters:
//   ClusterAdministrationParameters - Structure - the structure that describes parameters for 
//                  connecting the server cluster. For details, see ClusterAdministration. ClusterAdministrationParameters().
//   ProfileName - String - the security profile name.
//   ClusterID - String - internal ID of a server cluster.
//
// Returns:
//   Structure - structure describing security profile. For details, see ClusterAdministration.
//                  SecurityProfileProperties(). 
//
Function SecurityProfile(Val ClusterAdministrationParameters, Val ProfileName, Val ClusterID = Undefined) Export
	
	Filter = New Structure("Name", ProfileName);
	
	If ClusterID = Undefined Then
		ClusterID = ClusterID(ClusterAdministrationParameters);
	EndIf;
	
	SecurityProfiles = GetSecurityProfiles(ClusterID, ClusterAdministrationParameters, Filter);
	
	If SecurityProfiles.Count() <> 1 Then
		Raise StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = 'В кластере серверов %1 не зарегистрирован профиль безопасности %2'; en = 'Security profile %2 is not registered in server cluster %1.'; pl = 'Profil bezpieczeństwa %1 nie jest zarejestrowany w klastrze serwerów %2';de = 'Es ist kein Sicherheitsprofil %2 im Server-Cluster %1 registriert';ro = 'Profilul de securitate %2 nu este înregistrat în clusterul serverelor %1';tr = 'Güvenlik profili %2 %1 sunucu kümesinde kayıtlı değil.'; es_ES = 'En el clúster de servidores %1 no se ha registrado perfil de seguridad %2'"), ClusterID, ProfileName);
	EndIf;
	
	Result = SecurityProfiles[0];
	Result = ConvertAccessListUsagePropertyValues(Result);
	
	// Virtual directories
	Result.Insert("VirtualDirectories",
		GetVirtualDirectories(ClusterID, ClusterAdministrationParameters, ProfileName));
	
	// Allowed COM classes.
	Result.Insert("COMClasses",
		GetAllowedCOMClasses(ClusterID, ClusterAdministrationParameters, ProfileName));
	
	// Add-ins
	Result.Insert("AddIns",
		GetAllowedAddIns(ClusterID, ClusterAdministrationParameters, ProfileName));
	
	// External modules
	Result.Insert("ExternalModules",
		GetAllowedExternalModules(ClusterID, ClusterAdministrationParameters, ProfileName));
	
	// OS applications
	Result.Insert("OSApplications",
		GetAllowedOSApplications(ClusterID, ClusterAdministrationParameters, ProfileName));
	
	// Internet resources
	Result.Insert("InternetResources",
		GetAllowedInternetResources(ClusterID, ClusterAdministrationParameters, ProfileName));
	
	Return Result;
	
EndFunction

// Creates a security profile on the basis of the passed description.
//
// Parameters:
//   ClusterAdministrationParameters - Structure - the structure that describes parameters for 
//                  connecting the server cluster. For details, see ClusterAdministration. ClusterAdministrationParameters().
//  SecurityProfileProperties - Structure - structure that describes the properties of the security 
//                  profile. For the details, see ClusterAdministration.SecurityProfileProperties(). 
//
Procedure CreateSecurityProfile(Val ClusterAdministrationParameters, Val SecurityProfileProperties) Export
	
	ProfileName = SecurityProfileProperties.Name;
	
	Filter = New Structure("Name", ProfileName);
	
	ClusterID = ClusterID(ClusterAdministrationParameters);
	
	SecurityProfiles = GetSecurityProfiles(ClusterID, ClusterAdministrationParameters, Filter);
	
	If SecurityProfiles.Count() = 1 Then
		Raise StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = 'В кластере серверов %1 уже зарегистрирован профиль безопасности %2'; en = 'Security profile %2 is already registered in server cluster %1.'; pl = 'Profil bezpieczeństwa %1 jest już zarejestrowany w klastrze serwerów %2';de = 'Im Servercluster %1 ist bereits ein Sicherheitsprofil registriert %2';ro = 'Profilul de securitate %2 este deja înregistrat în clusterul de serverelor %1';tr = 'Güvenlik profili %2, %1 sunucu kümesinde zaten kayıtlı.'; es_ES = 'En el clúster de servidores %1 se ha registrado ya un perfil de seguridad %2'"), ClusterID, ProfileName);
	EndIf;
	
	UpdateSecurityProfileProperties(ClusterAdministrationParameters, SecurityProfileProperties);
	
EndProcedure

// Sets properties for a security profile on the basis of the passed description.
//
// Parameters:
//   ClusterAdministrationParameters - Structure - the structure that describes parameters for 
//                  connecting the server cluster. For details, see ClusterAdministration. ClusterAdministrationParameters().
//   SecurityProfileProperties - Structure - structure that describes the properties of the security 
//                  profile. For the details, see ClusterAdministration.SecurityProfileProperties(). 
//
Procedure SetSecurityProfileProperties(Val ClusterAdministrationParameters, Val SecurityProfileProperties)  Export
	
	ProfileName = SecurityProfileProperties.Name;
	
	Filter = New Structure("Name", ProfileName);
	
	ClusterID = ClusterID(ClusterAdministrationParameters);
	
	SecurityProfiles = GetSecurityProfiles(ClusterID, ClusterAdministrationParameters, Filter);
	
	If SecurityProfiles.Count() <> 1 Then
		Raise StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = 'В кластере серверов %1 не зарегистрирован профиль безопасности %2'; en = 'Security profile %2 is not registered in server cluster %1.'; pl = 'Profil bezpieczeństwa %1 nie jest zarejestrowany w klastrze serwerów %2';de = 'Es ist kein Sicherheitsprofil %2 im Server-Cluster %1 registriert';ro = 'Profilul de securitate %2 nu este înregistrat în clusterul serverelor %1';tr = 'Güvenlik profili %2 %1 sunucu kümesinde kayıtlı değil.'; es_ES = 'En el clúster de servidores %1 no se ha registrado perfil de seguridad %2'"), ClusterID, ProfileName);
	EndIf;
	
	PreviousProperties = SecurityProfile(ClusterAdministrationParameters, ProfileName, ClusterID);
	
	UpdateSecurityProfileProperties(ClusterAdministrationParameters, SecurityProfileProperties, PreviousProperties);
	
EndProcedure

// Deletes a securiy profile.
//
// Parameters:
//   ClusterAdministrationParameters - Structure - the structure that describes parameters for 
//                  connecting the server cluster. For details, see ClusterAdministration. ClusterAdministrationParameters().
//   ProfileName - String - the security profile name.
//
Procedure DeleteSecurityProfile(Val ClusterAdministrationParameters, Val ProfileName) Export
	
	Command = "profile remove --name=%1 " + ClusterParameters(ClusterAdministrationParameters);
	SubstituteParametersToCommand(Command, ProfileName);
	RunCommand(Command, ClusterAdministrationParameters);
	
EndProcedure

#EndRegion

#Region Infobases

// Returns an internal infobase ID.
//
// Parameters:
//   ClusterID - String - internal ID of a server cluster.
//   ClusterAdministrationParameters - Structure - the structure that describes parameters for 
//                  connecting the server cluster. For details, see ClusterAdministration. ClusterAdministrationParameters().
//   IBAdministrationParameters - Structure - the structure describing infobase connection 
//                  parameters. For details, see ClusterAdministration. ClusterInfobaseAdministrationParameters().
//
// Returns:
//   String - internal infobase ID.
//
Function InfoBaseID(Val ClusterID, Val ClusterAdministrationParameters, Val InfobaseAdministrationParameters) Export
	
	Filter = New Structure("name", InfobaseAdministrationParameters.NameInCluster);
	
	Infobases = InfobasesProperties(ClusterID, ClusterAdministrationParameters, Filter);
	
	If Infobases.Count() = 1 Then
		Return Infobases[0].Get("infobase");
	Else
		Raise StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = 'В кластере серверов %1 не зарегистрирована информационная база %2'; en = 'Infobase %2 is not registered in server cluster %1.'; pl = 'Baza informacyjna %1 nie jest zarejestrowana  w klastrze serwerów %2';de = 'Im Servercluster %1 ist keine Informationsbasis registriert %2';ro = 'Baza de date %2 nu este înregistrată în clusterul serverelor %1';tr = 'Veritabanı %2 %1 sunucu kümesinde kayıtlı değil.'; es_ES = 'En el clúster de servidores %1no se ha registrado base de información %2'"), ClusterID, InfobaseAdministrationParameters.NameInCluster);
	EndIf;
	
EndFunction

// Returns infobase descriptions
//
// Parameters:
//   ClusterID - String - internal ID of a server cluster.
//   ClusterAdministrationParameters - Structure - the structure that describes parameters for 
//                  connecting the server cluster. For details, see ClusterAdministration. ClusterAdministrationParameters().
//   Filter - Structure - infobase filtering criteria.
//
// Returns: Array(Structure).
//
Function InfobasesProperties(Val ClusterID, Val ClusterAdministrationParameters, Val Filter = Undefined) Export
	
	Command = "infobase summary list " + ClusterParameters(ClusterAdministrationParameters, ClusterID);
	Properties = RunCommand(Command, ClusterAdministrationParameters, , Filter, BaseDetailsPropertyTypes());
	
	Return Properties;
	
EndFunction

#EndRegion

#Region Cluster

// Returns an internal ID of a server cluster.
//
// Parameters:
//   ClusterAdministrationParameters - Structure - the structure that describes parameters for 
//                  connecting the server cluster. For details, see ClusterAdministration. ClusterAdministrationParameters().
//
// Returns:
//   String - internal server cluster ID.
//
Function ClusterID(Val ClusterAdministrationParameters) Export
	
	Filter = New Structure("port", ClusterAdministrationParameters.ClusterPort);
	
	Clusters = ClusterProperties(ClusterAdministrationParameters, Filter);
	
	If Clusters.Count() = 1 Then
		Return Clusters[0].Get("cluster");
	Else
		Raise StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = 'Не обнаружен кластер серверов с портом %1'; en = 'Cannot find a server cluster with port %1.'; pl = 'Nie znaleziono klastra serwera z portem %1';de = 'Server-Cluster mit Port %1 wurde nicht gefunden';ro = 'Clusterul serverelor cu portul %1 nu a fost găsit';tr = '%1Bağlantı noktası olan sunucu kümesi bulunamadı'; es_ES = 'Clúster del servidor con el puerto %1 no encontrado'"), ClusterAdministrationParameters.ClusterPort);
	EndIf;
	
EndFunction

// Returns server cluster descriptions.
//
//   ClusterAdministrationParameters - Structure - the structure that describes parameters for 
//                  connecting the server cluster. For details, see ClusterAdministration. ClusterAdministrationParameters().
//   Filter - Structure - server cluster filtering criteria.
//
// Returns:
//   Array - an array of map, and cluster details in the rac notation.
//
Function ClusterProperties(Val ClusterAdministrationParameters, Val Filter = Undefined) Export
	
	If ValueIsFilled(ClusterAdministrationParameters.AdministrationServerAddress) Then
		Server = TrimAll(ClusterAdministrationParameters.AdministrationServerAddress);
		If ValueIsFilled(ClusterAdministrationParameters.AdministrationServerPort) Then
			Server = Server + ":" + CastValue(ClusterAdministrationParameters.AdministrationServerPort);
		EndIf;
	Else
		Server = "";
	EndIf;
	
	Return RunCommand("cluster list " + Server, ClusterAdministrationParameters, , Filter, ClusterPropertyTypes());
	
EndFunction

#EndRegion

#Region WorkingProcessesServers

// Returns descriptions of working processes.
//
// Parameters:
//   ClusterID - String - the internal ID of a server cluster.
//   ClusterAdministrationParameters - Structure - the structure that describes parameters for 
//                  connecting the server cluster. For details, see ClusterAdministration. ClusterAdministrationParameters().
//   Filter - Structure - working process filtering criteria.
//
// Returns:
//   Array - an array of map, and working process details in the rac notation.
//
Function WorkingProcessesProperties(Val ClusterID, Val ClusterAdministrationParameters, Val Filter = Undefined) Export
	
	Return RunCommand("process list " + ClusterParameters(ClusterAdministrationParameters, ClusterID), ClusterAdministrationParameters, , Filter);
	
EndFunction

// Returns descriptions of working servers.
//
// Parameters:
//  ClusterID - String - internal ID of a server cluster,
//   ClusterAdministrationParameters - Structure - the structure that describes parameters for 
//                  connecting the server cluster. For details, see ClusterAdministration. ClusterAdministrationParameters().
//   Filter - Structure - working server filtering criteria.
//
// Returns:
//   Array - an array of map, and working process details in the rac notation.
//
Function WorkingServerProperties(Val ClusterID, Val ClusterAdministrationParameters, Val Filter = Undefined) Export
	
	ClusterParameters = ClusterParameters(ClusterAdministrationParameters, ClusterID);
	
	Return RunCommand("server list " + ClusterParameters, ClusterAdministrationParameters, , Filter, WorkingServerPropertyTypes());
	
EndFunction

#EndRegion

// Returns descriptions of infobase sessions.
//
// Parameters:
//   ClusterID - String - internal ID of a server cluster.
//   ClusterAdministrationParameters - Structure - the structure that describes parameters for 
//                  connecting the server cluster. For details, see ClusterAdministration. ClusterAdministrationParameters().
//   InfoBaseID - String - an internal ID of an infobase.
//   IBAdministrationParameters - Structure - the structure describing infobase connection 
//                  parameters. For details, see ClusterAdministration. ClusterInfobaseAdministrationParameters().
//   Filter - Description of filter criteria for sessions whose descriptions are required.
//      Options:
//         1. Array of structures that describe session filter criteria. Each array structure has the following fields:
//            Property - String - property name to be used in the filter. For valid values, see
//               Return value of the ClusterAdministration.SessionProperties() function,
//            ComparisonType - ComparisonType - value of system enumeration ComparisonType, the type 
//               of comparing the session values and the filter values. The following values are available:
//                  ComparisonType.Equal,
//                  ComparisonType.NotEqual,
//                  ComparisonType.Greater (for numeric values only),
//                  ComparisonType.GreaterOrEqual (for numeric values only),
//                  ComparisonType.Less (for numeric values only),
//                  ComparisonType.LessOrEqual (for numeric values only),
//                  ComparisonType.InList,
//                  ComparisonType.NotInList,
//                  ComparisonType.Interval (for numeric values only),
//                  ComparisonType.IntervalIncludingBounds (for numeric values only),
//                  ComparisonType.IntervalIncludingLowerBound (for numeric values only),
//                  ComparisonType.IntervalIncludingUpperBound (for numeric values only),
//            Value - Number, String, Data, Boolean, ValueList, Array, Structure - the value the 
//               matching session property value is compared with. For ComparisonType.InList and 
//               ComparisonType.NotInList, the passed values are ValueList or Array that contain the 
//               set of values to compare to. For ComparisonType.Interval, ComparisonType.IntervalIncludingBounds,
//               ComparisonType.IntervalIncludingLowerBound, and ComparisonType.
//               IntervalIncludingUpperBound, the passed value contains a structure with the From 
//               and To fields that forms an interval to be compared to.
//         2. Structure (simplified). Key - the session property Name (mentioned above). Value - the 
//            value to compare to. When you use this filter description, the comparison always 
//            checks for equality.
//   UseDictionary - Boolean - if True, the return value is generated using a dictionary. Otherwise, 
//                  the dictionary is not used.
//
// Returns:
//   Array - an array of structures that describe session properties (for more details see 
//                  ClusterAdministration.SessionProperties()) or (If UseDictionary = False) an  
//                  array of map that describes session properties in the rac utility notation.
//                  
//
Function SessionsProperties(Val ClusterID, Val ClusterAdministrationParameters, Val InfobaseID, Val Filter = Undefined, Val UseDictionary = True) Export
	
	Command = "session list --infobase=%1 " + ClusterParameters(ClusterAdministrationParameters, ClusterID);	
	SubstituteParametersToCommand(Command, InfobaseID);	
	
	If UseDictionary Then
		Dictionary = SessionPropertiesDictionary();
	Else
		Dictionary = Undefined;
		Filter = FilterToRacNotation(Filter, SessionPropertiesDictionary());
	EndIf;
	
	Result = RunCommand(Command, ClusterAdministrationParameters, Dictionary, Filter, SessionPropertyTypes());
	
	Return Result;                                       
	
EndFunction

// Returns descriptions of infobase connections.
//
// Parameters:
//   ClusterID - String - internal ID of a server cluster.
//   ClusterAdministrationParameters - Structure - the structure that describes parameters for 
//                  connecting the server cluster. For details, see ClusterAdministration. ClusterAdministrationParameters().
//   InfoBaseID - String - an internal ID of an infobase.
//   IBAdministrationParameters - Structure - the structure describing infobase connection 
//                  parameters. For details, see ClusterAdministration. ClusterInfobaseAdministrationParameters().
//   Filter - Description of filter criteria for sessions whose descriptions are required.
//      Options:
//         1. Array of structures that describe session filter criteria. Each array structure has the following fields:
//            Property - String - property name to be used in the filter. For valid values, see
//               Return value of the ClusterAdministration.SessionProperties() function,
//            ComparisonType - ComparisonType - value of system enumeration ComparisonType, the type 
//               of comparing the session values and the filter values. The following values are available:
//                  ComparisonType.Equal,
//                  ComparisonType.NotEqual,
//                  ComparisonType.Greater (for numeric values only),
//                  ComparisonType.GreaterOrEqual (for numeric values only),
//                  ComparisonType.Less (for numeric values only),
//                  ComparisonType.LessOrEqual (for numeric values only),
//                  ComparisonType.InList,
//                  ComparisonType.NotInList,
//                  ComparisonType.Interval (for numeric values only),
//                  ComparisonType.IntervalIncludingBounds (for numeric values only),
//                  ComparisonType.IntervalIncludingLowerBound (for numeric values only),
//                  ComparisonType.IntervalIncludingUpperBound (for numeric values only),
//            Value - Number, String, Data, Boolean, ValueList, Array, Structure - the value the 
//               matching session property value is compared with. For ComparisonType.InList and 
//               ComparisonType.NotInList, the passed values are ValueList or Array that contain the 
//               set of values to compare to. For ComparisonType.Interval, ComparisonType.IntervalIncludingBounds,
//               ComparisonType.IntervalIncludingLowerBound, and ComparisonType.
//               IntervalIncludingUpperBound, the passed value contains a structure with the From 
//               and To fields that forms an interval to be compared to.
//         2. Structure (simplified). Key - the session property Name (mentioned above). Value - the 
//            value to compare to. When you use this filter description, the comparison always 
//            checks for equality.
//   UseDictionary - Boolean - if True, the return value is generated using a dictionary. Otherwise, 
//                  the dictionary is not used.
//
// Returns:
//   Array - an array of structures that describe connection properties (for more details see 
//                  ClusterAdministration.ConnectionProperties()) or (If UseDictionary = False) an  
//                  array of map that describes connection properties in the rac utility notation.
//                  
//
Function ConnectionsProperties(Val ClusterID, Val ClusterAdministrationParameters, Val InfobaseID, Val IBAdministrationParameters, Val Filter = Undefined, Val UseDictionary = False) Export
	
	ClusterParameters = ClusterParameters(ClusterAdministrationParameters, ClusterID);
	
	If UseDictionary Then
		Dictionary = ConnectionPropertiesDictionary();
	Else
		Dictionary = Undefined;
		Filter = FilterToRacNotation(Filter, ConnectionPropertiesDictionary());
	EndIf;
	
	Result = New Array();
	WorkingProcesses = WorkingProcessesProperties(ClusterID, ClusterAdministrationParameters);
	
	For Each WorkingProcess In WorkingProcesses Do
		
		Command = "connection list --process=%1 --infobase=%2 --infobase-user=%3 --infobase-pwd=%4 " + ClusterParameters;
		SubstituteParametersToCommand(Command,
			WorkingProcess.Get("process"),
			InfobaseID,
			IBAdministrationParameters.InfobaseAdministratorName,
			IBAdministrationParameters.InfobaseAdministratorPassword);
			
		WorkingProcessConnections = RunCommand(Command, ClusterAdministrationParameters, Dictionary, Filter, ConnectionPropertyTypes());
		For Each Connection In WorkingProcessConnections Do
			If UseDictionary Then
				If Connection.DataBaseConnectionMode = "none" Then
					Connection.Insert("DataBaseConnectionMode", 0);
				ElsIf Connection.DataBaseConnectionMode = "shared" Then
					Connection.Insert("DataBaseConnectionMode", 1);
				Else // exclusive
					Connection.Insert("DataBaseConnectionMode", 2);
				EndIf;
				Connection.Insert("InfobaseConnectionMode", ?(Connection.InfobaseConnectionMode = "shared", 0, 1));
				Connection.Insert("ControlIsOnServer", ?(Connection.ControlIsOnServer = "client", 0, 1));
			Else
				Connection.Insert("process", WorkingProcess.Get("process"));
			EndIf;
			Result.Add(Connection);
		EndDo;
		
	EndDo;
	
	Return Result;
	
EndFunction

// Returns path to the console client of the administration server.
//
// Returns:
//   String - a path to the console client of the administration server.
//
Function PathToAdministrationServerClient() Export
	
	StartDirectory = PlatformExecutableFilesDirectory();
	Client = StartDirectory + "rac";
	
	SysInfo = New SystemInfo();
	If (SysInfo.PlatformType = PlatformType.Windows_x86) Or (SysInfo.PlatformType = PlatformType.Windows_x86_64) Then
		Client = Client + ".exe";
	EndIf;
	
	Return Client;
	
EndFunction

#EndRegion

#Region Private

// Returns a directory of platform executable files.
//
// Returns:
//   String - directory of executable platform files.
//
Function PlatformExecutableFilesDirectory()
	
	Result = BinDir();
	SeparatorChar = GetPathSeparator();
	
	If Right(Result, 1) <> SeparatorChar Then
		Result = Result + SeparatorChar;
	EndIf;
	
	Return Result;
	
EndFunction

// Returns values of infobase properties.
//
// Parameters:
//   ClusterAdministrationParameters - Structure - the structure that describes parameters for 
//                  connecting the server cluster. For details, see ClusterAdministration. ClusterAdministrationParameters().
//   IBAdministrationParameters - Structure - the structure describing infobase connection 
//                  parameters. For details, see ClusterAdministration. ClusterInfobaseAdministrationParameters().
//   Dictionary - Structure - correspondence between names of API properties and rac output stream.
//
// Returns:
//   Structure - an infobase description generated from the passed dictionary.
//
Function InfobaseProperties(Val ClusterAdministrationParameters, Val IBAdministrationParameters, Val Dictionary)
	
	ClusterID = ClusterID(ClusterAdministrationParameters);
	InfobaseID = InfoBaseID(ClusterID, ClusterAdministrationParameters, IBAdministrationParameters);
	
	ClusterParameters = ClusterParameters(ClusterAdministrationParameters, ClusterID);
	
	Command = "infobase info --infobase=%1 --infobase-user=%2 --infobase-pwd=%3";
	SubstituteParametersToCommand(Command, 
		InfobaseID, 
		IBAdministrationParameters.InfobaseAdministratorName, 
		IBAdministrationParameters.InfobaseAdministratorPassword);
		
	Result = RunCommand(Command + " " + ClusterParameters, ClusterAdministrationParameters, Dictionary, , InfoBasePropertyTypes());
	
	Return Result[0];
	
EndFunction

// Sets values of infobase properties.
//
// Parameters:
//   ClusterAdministrationParameters - Structure - the structure that describes parameters for 
//                  connecting the server cluster. For details, see ClusterAdministration. ClusterAdministrationParameters().
//   IBAdministrationParameters - Structure - the structure describing infobase connection 
//                  parameters. For details, see ClusterAdministration. ClusterInfobaseAdministrationParameters().
//   Dictionary - Structure - correspondence between names of API properties and rac output stream.
//   PropertyValues - Structure - values of infobase properties to set:
//     * Key - property name in API notation.
//     * Value - a value to set for the property.
//
Procedure SetInfobaseProperties(Val ClusterAdministrationParameters, Val IBAdministrationParameters, Val Dictionary, Val PropertyValues)
	
	ClusterID = ClusterID(ClusterAdministrationParameters);
	InfobaseID = InfoBaseID(ClusterID, ClusterAdministrationParameters, IBAdministrationParameters);
	
	ClusterParameters = ClusterParameters(ClusterAdministrationParameters, ClusterID);
	
	ReceivingParameters = New Structure;
	ReceivingParameters.Insert("ClusterAdministrationParameters", ClusterAdministrationParameters);
	ReceivingParameters.Insert("IBAdministrationParameters", IBAdministrationParameters);
	ReceivingParameters.Insert("ObjectType", "infobase");
	SupportedProperties = SupportedObjectProperties(ReceivingParameters);
	
	Command = "infobase update --infobase=%1 --infobase-user=%2 --infobase-pwd=%3";
	SubstituteParametersToCommand(Command, 
		InfobaseID, 
		IBAdministrationParameters.InfobaseAdministratorName, 
		IBAdministrationParameters.InfobaseAdministratorPassword);
		
	// For these two boolean properties the presentation differs.
	NewPropertiesValues = Common.CopyRecursive(PropertyValues);
	For Each KeyAndValue In Dictionary Do
		If KeyAndValue.Value = "scheduled-jobs-deny" Or KeyAndValue.Value = "sessions-deny" Then
			NewPropertiesValues.Insert(KeyAndValue.Key, Format(NewPropertiesValues[KeyAndValue.Key], "BF=off; BT=on"));
		EndIf;
	EndDo;
	
	AddCommandParametersByDictionary(Command, Dictionary, NewPropertiesValues, SupportedProperties);
	
	RunCommand(Command + " " + ClusterParameters, ClusterAdministrationParameters);
	
EndProcedure

// Returns security profile descriptions.
//
// Parameters:
//   ClusterID - String - internal ID of a server cluster.
//   ClusterAdministrationParameters - Structure - the structure that describes parameters for 
//                  connecting the server cluster. For details, see ClusterAdministration. ClusterAdministrationParameters().
//   Filter - Structure - security profile filtering criteria.
//
// Returns:
//   Array - an array of details in the rac notation.
//
Function GetSecurityProfiles(Val ClusterID, Val ClusterAdministrationParameters, Val Filter = Undefined)
	
	Command = "profile list " + ClusterParameters(ClusterAdministrationParameters, ClusterID);
	Result = RunCommand(Command, ClusterAdministrationParameters, SecurityProfilePropertiesDictionary(), Filter, ProfilePropertyTypes()); 
	
	Return Result;
	
EndFunction

// Returns descriptions of virtual directories.
//
// Parameters:
//   ClusterID - String - internal ID of a server cluster.
//   ClusterAdministrationParameters - Structure - the structure that describes parameters for 
//                  connecting the server cluster. For details, see ClusterAdministration. ClusterAdministrationParameters().
//   ProfileName - String - the security profile name.
//   Filter - Structure - virtual directory filtering criteria.
//
// Returns:
//   Array - an array of details in the rac notation.
//
Function GetVirtualDirectories(Val ClusterID, Val ClusterAdministrationParameters, Val ProfileName, Val Filter = Undefined)
	
	Return AccessManagementLists(
		ClusterID,
		ClusterAdministrationParameters,
		ProfileName,
		"directory", // Do not localize.
		VirtualDirectoryPropertiesDictionary(),
		,
		VirtualDirectoryPropertyTypes());
	
EndFunction

// Returns descriptions of COM classes.
//
// Parameters:
//   ClusterID - String - internal ID of a server cluster.
//   ClusterAdministrationParameters - Structure - the structure that describes parameters for 
//                  connecting the server cluster. For details, see ClusterAdministration. ClusterAdministrationParameters().
//   ProfileName - String - the security profile name.
//   Filter - Structure - COM class filtering criteria.
//
// Returns:
//   Array - an array of details in the rac notation.
//
Function GetAllowedCOMClasses(Val ClusterID, Val ClusterAdministrationParameters, Val ProfileName, Val Filter = Undefined)
	
	Return AccessManagementLists(
		ClusterID,
		ClusterAdministrationParameters,
		ProfileName,
		"com", // Do not localize.
		COMClassPropertiesDictionary(),
		,
		COMClassPropertyTypes());
	
EndFunction

// Returns descriptions of add-ins.
//
// Parameters:
//   ClusterID - String - internal ID of a server cluster.
//   ClusterAdministrationParameters - Structure - the structure that describes parameters for 
//                  connecting the server cluster. For details, see ClusterAdministration. ClusterAdministrationParameters().
//  ProfileName - String - the security profile name.
//  Filter - Structure - add-in filtering criteria.
//
// Returns:
//   Array - an array of details in the rac notation.
//
Function GetAllowedAddIns(Val ClusterID, Val ClusterAdministrationParameters, Val ProfileName, Val Filter = Undefined)
	
	Return AccessManagementLists(
		ClusterID,
		ClusterAdministrationParameters,
		ProfileName,
		"addin", // Do not localize.
		AddInPropertiesDictionary(),
		,
		AddInPropertyTypes());
	
EndFunction

// Returns descriptions of external modules.
//
// Parameters:
//   ClusterID - String - internal ID of a server cluster.
//   ClusterAdministrationParameters - Structure - the structure that describes parameters for 
//                  connecting the server cluster. For details, see ClusterAdministration. ClusterAdministrationParameters().
//  ProfileName - String - the security profile name.
//  Filter - Structure - external module filtering criteria.
//
// Returns:
//   Array - an array of details in the rac notation.
//
Function GetAllowedExternalModules(Val ClusterID, Val ClusterAdministrationParameters, Val ProfileName, Val Filter = Undefined)
	
	Return AccessManagementLists(
		ClusterID,
		ClusterAdministrationParameters,
		ProfileName,
		"module", // Do not localize.
		ExternalModulePropertiesDictionary(),
		,
		ExternalModulePropertyType());
	
EndFunction

// Returns descriptions of OS applications.
//
// Parameters:
//   ClusterID - String - internal ID of a server cluster.
//   ClusterAdministrationParameters - Structure - the structure that describes parameters for 
//                  connecting the server cluster. For details, see ClusterAdministration. ClusterAdministrationParameters().
//   ProfileName - String - the security profile name.
//   Filter - Structure - OS application filtering criteria.
//
// Returns:
//   Array - an array of details in the rac notation.
//
Function GetAllowedOSApplications(Val ClusterID, Val ClusterAdministrationParameters, Val ProfileName, Val Filter = Undefined)
	
	Return AccessManagementLists(
		ClusterID,
		ClusterAdministrationParameters,
		ProfileName,
		"app", // Do not localize.
		OSApplicationPropertiesDictionary(),
		,
		OSApplicationPropertyTypes());
	
EndFunction

// Returns descriptions of Internet resources.
//
// Parameters:
//   ClusterID - String - internal ID of a server cluster.
//   ClusterAdministrationParameters - Structure - the structure that describes parameters for 
//                  connecting the server cluster. For details, see ClusterAdministration. ClusterAdministrationParameters().
//   ProfileName - String - the security profile name.
//   Filter - Structure - Internet resource filtering criteria.
//
// Returns:
//   Array - an array of details in the rac notation.
//
Function GetAllowedInternetResources(Val ClusterID, Val ClusterAdministrationParameters, Val ProfileName, Val Filter = Undefined)
	
	Return AccessManagementLists(
		ClusterID,
		ClusterAdministrationParameters,
		ProfileName,
		"inet", // Do not localize.
		InternetResourcePropertiesDictionary(),
		,
		InternetResourcePropertyTypes());
	
EndFunction

// Returns descriptions of access control list items.
//
// Parameters:
//   ClusterID - String - internal ID of a server cluster.
//   ClusterAdministrationParameters - Structure - the structure that describes parameters for 
//                  connecting the server cluster. For details, see ClusterAdministration. ClusterAdministrationParameters().
//   ProfileName - String - the security profile name.
//   ListName - String - name of an access control list (acl) in rac notation.
//   Dictionary - Structure - correspondence between property names in rac output stream and in the required details.
//   Filter - Structure - access control list item filtering criteria.
//
// Returns:
//   Array - an array of details in the rac notation.
//
Function AccessManagementLists(Val ClusterID, Val ClusterAdministrationParameters, Val ProfileName, Val ListName, Val Dictionary, Val Filter = Undefined, Val PropertyTypes = Undefined)
	
	Command = "profile acl --name=%1 %2 list " + ClusterParameters(ClusterAdministrationParameters, ClusterID);
	SubstituteParametersToCommand(Command, ProfileName, ListName);
	
	Result = RunCommand(Command, ClusterAdministrationParameters, Dictionary, Filter, PropertyTypes);
	
	Return Result;
	
EndFunction

// Updates the security profile properties (including acl content and usage updates).
//
// Parameters:
//   ClusterAdministrationParameters - Structure - the structure that describes parameters for 
//                  connecting the server cluster. For details, see ClusterAdministration. ClusterAdministrationParameters().
//   NewProperties - Structure - structure that describes the properties of the security profile. 
//       For details, see ClusterAdministration.SecurityProfileProperties(). 
//   OldProperties - Structure - structure that describes the properties of the security profile. 
//       For details, see ClusterAdministration.SecurityProfileProperties(). 
//
Procedure UpdateSecurityProfileProperties(Val ClusterAdministrationParameters, Val NewProperties, Val PreviousProperties = Undefined)
	
	If PreviousProperties = Undefined Then
		PreviousProperties = ClusterAdministration.SecurityProfileProperties();
	EndIf;
	
	ClusterID = ClusterID(ClusterAdministrationParameters);
	ClusterParameters = ClusterParameters(ClusterAdministrationParameters, ClusterID);
	
	ProfileName = NewProperties.Name;
	
	ReceivingParameters = New Structure;
	ReceivingParameters.Insert("ClusterAdministrationParameters", ClusterAdministrationParameters);
	ReceivingParameters.Insert("ObjectType", "profile");
	SupportedProperties = SupportedObjectProperties(ReceivingParameters);
	
	ProfilePropertiesDictionary = SecurityProfilePropertiesDictionary(False);
	For Each DictionaryFragment In ProfilePropertiesDictionary Do
		If NewProperties.Property(DictionaryFragment.Key) Then
			If NewProperties[DictionaryFragment.Key] <> PreviousProperties[DictionaryFragment.Key] Then
				Command = "profile update";
				AddCommandParametersByDictionary(Command, ProfilePropertiesDictionary, NewProperties, SupportedProperties.profile); 
				RunCommand(Command + " " + ClusterParameters, ClusterAdministrationParameters);
				Break;
			EndIf;
		EndIf;
	EndDo;
	
	For Each DictionaryFragment In AccessManagementListUsagePropertiesDictionary() Do
		If NewProperties[DictionaryFragment.Key] = PreviousProperties[DictionaryFragment.Key] Then
			Continue;
		EndIf;
		SetAccessManagementListUsage(ClusterID, ClusterAdministrationParameters, ProfileName, DictionaryFragment.Value, Not NewProperties[DictionaryFragment.Key]);
	EndDo;
	
	// Virtual directories
	UpdateAccessControlListItems(ClusterID, 
		ClusterAdministrationParameters, 
		ProfileName, 
		"directory", 
		VirtualDirectoryPropertiesDictionary(), 
		NewProperties.VirtualDirectories,
		PreviousProperties.VirtualDirectories);
	
	// Allowed COM classes.
	UpdateAccessControlListItems(ClusterID, 
		ClusterAdministrationParameters, 
		ProfileName, 
		"com", 
		COMClassPropertiesDictionary(), 
		NewProperties.COMClasses,
		PreviousProperties.COMClasses);
	
	// Add-ins
	UpdateAccessControlListItems(ClusterID, 
		ClusterAdministrationParameters, 
		ProfileName, 
		"addin", 
		AddInPropertiesDictionary(), 
		NewProperties.AddIns,
		PreviousProperties.AddIns);
	
	// External modules
	UpdateAccessControlListItems(ClusterID, 
		ClusterAdministrationParameters, 
		ProfileName, 
		"module", 
		ExternalModulePropertiesDictionary(),
		NewProperties.ExternalModules,
		PreviousProperties.ExternalModules);
		
	// OS applications
	UpdateAccessControlListItems(ClusterID, 
		ClusterAdministrationParameters, 
		ProfileName, 
		"app", 
		OSApplicationPropertiesDictionary(), 
		NewProperties.OSApplications,
		PreviousProperties.OSApplications);
	
	// Internet resources
	UpdateAccessControlListItems(ClusterID, 
		ClusterAdministrationParameters,
		ProfileName, 
		"inet", 
		InternetResourcePropertiesDictionary(), 
		NewProperties.InternetResources,
		PreviousProperties.InternetResources);
	
EndProcedure

// Sets acl usage for security profiles.
//
// Parameters:
//   ClusterID - String - internal ID of a server cluster.
//   ClusterAdministrationParameters - Structure - the structure that describes parameters for 
//                  connecting the server cluster. For details, see ClusterAdministration. ClusterAdministrationParameters().
//   ProfileName - String - the security profile name.
//   ListName - String - name of an access control list (acl) in rac notation.
//   Usage - Boolean - indicates whether the access control list is used.
//
Procedure SetAccessManagementListUsage(Val ClusterID, Val ClusterAdministrationParameters, Val ProfileName, Val ListName, Val Usage)
	
	Command = "profile acl --name=%1 %2 --access=%3 " + ClusterParameters(ClusterAdministrationParameters, ClusterID);
	SubstituteParametersToCommand(Command, ProfileName, ListName, ?(Usage, "list", "full"));
	RunCommand(Command, ClusterAdministrationParameters);
	
EndProcedure

// Deletes acl item from a security profile.
//
// Parameters:
//   ClusterID - String - internal ID of a server cluster.
//   ClusterAdministrationParameters - Structure - the structure that describes parameters for 
//                  connecting the server cluster. For details, see ClusterAdministration. ClusterAdministrationParameters().
//   ProfileName - String - the security profile name.
//   ListName - String - name of an access control list (acl) in rac notation.
//   ItemKey - String - a value of a key property of acl item.
//
Procedure DeleteAccessManagementListItem(Val ClusterID, Val ClusterAdministrationParameters, 
	Val ProfileName, Val ListName, Val ItemKey)
	
	ListKey = AccessManagementListsKeys()[ListName];
	
	Command = "profile acl --name=%1 %2 remove --%3=%4 " + ClusterParameters(ClusterAdministrationParameters, ClusterID);
	SubstituteParametersToCommand(Command, ProfileName, ListName, ListKey, ItemKey); 
	
	RunCommand(Command, ClusterAdministrationParameters);
	
EndProcedure

// Updates acl item for security profiles
//
// Parameters:
//   ClusterID - String - internal ID of a server cluster.
//   ClusterAdministrationParameters - Structure - the structure that describes parameters for 
//                  connecting the server cluster. For details, see ClusterAdministration. ClusterAdministrationParameters().
//   ProfileName - String - the security profile name.
//   ListName - String - name of an access control list (acl) in rac notation.
//   Dictionary - Structure - correspondence between property names in rac output stream and in the required details.
//   ItemProperties - Structure - values of access control list item properties.
//
Procedure UpdateAccessControlListItem(Val ClusterID, Val ClusterAdministrationParameters, 
	Val ProfileName, Val ListName, Val Dictionary, Val ItemProperties)
	
	ClusterParameters = ClusterParameters(ClusterAdministrationParameters, ClusterID);
	
	ReceivingParameters = New Structure;
	ReceivingParameters.Insert("ClusterAdministrationParameters", ClusterAdministrationParameters);
	ReceivingParameters.Insert("ObjectType", "profile");
	SupportedProperties = SupportedObjectProperties(ReceivingParameters);
	
	Command = "profile acl --name=%1 %2 update";
	SubstituteParametersToCommand(Command, ProfileName, ListName);
	AddCommandParametersByDictionary(Command, Dictionary, ItemProperties, SupportedProperties["profile_" + ListName]);
	
	RunCommand(Command + " " + ClusterParameters, ClusterAdministrationParameters);
	
EndProcedure

// Updates acl item for security profiles.
//
// Parameters:
//   ClusterID - String - internal ID of a server cluster.
//   ClusterAdministrationParameters - Structure - the structure that describes parameters for 
//                  connecting the server cluster. For details, see ClusterAdministration. ClusterAdministrationParameters().
//   ProfileName - String - the security profile name.
//   ListName - String - name of an access control list (acl) in rac notation.
//   Dictionary - Structure - correspondence between property names in rac output stream and in the required details.
//   NewItems - Structure - values of access control list item properties.
//   OldItems - Structure - values of access control list item properties.
//
Procedure UpdateAccessControlListItems(Val ClusterID, Val ClusterAdministrationParameters, 
	Val ProfileName, Val ListName, Val Dictionary, Val NewItems, Val OldItems = Undefined)
	
	If OldItems = Undefined Or OldItems.Count() = 0 Then
		For Each NewItem In NewItems Do
			UpdateAccessControlListItem(ClusterID, ClusterAdministrationParameters, ProfileName, ListName, Dictionary, NewItem);
		EndDo;
		Return;
	EndIf;
	
	ListKey = AccessManagementListsKeys()[ListName];
	KeyParameterName = "";
	For Each KeyAndValue In Dictionary Do
		If KeyAndValue.Value = ListKey Then
			KeyParameterName = KeyAndValue.Key;
			EndIf;
	EndDo;
	
	ItemsToDelete = New Map;
	For Each OldItem In OldItems Do
		ItemsToDelete.Insert(OldItem[KeyParameterName], OldItem);
	EndDo;
	
	// Create or update (if properties differ).
	For Each NewItem In NewItems Do
		varKey = NewItem[KeyParameterName];
		OldItem = ItemsToDelete.Get(varKey);
		If OldItem = Undefined Then
			UpdateAccessControlListItem(ClusterID, ClusterAdministrationParameters, ProfileName, ListName, Dictionary, NewItem);
		Else
			ItemsToDelete.Delete(varKey);
			// Update only if properties differ.
			For Each KeyAndValue In NewItem Do
				If KeyAndValue.Value <> OldItem[KeyAndValue.Key] Then
					UpdateAccessControlListItem(ClusterID, ClusterAdministrationParameters, ProfileName, ListName, Dictionary, NewItem);
					Break;
				EndIf;
			EndDo;
		EndIf;
	EndDo;
	
	// Delete useless items.
	For Each KeyAndValue In ItemsToDelete Do
		DeleteAccessManagementListItem(ClusterID, ClusterAdministrationParameters, ProfileName, ListName, KeyAndValue.Key);
	EndDo;
	
EndProcedure

// Converts values of the access control list usage property values (nonstandard value format are 
// used when passing the values to the rac utility: True = "full", False = "list").
//
// Parameters:
//   Details - Structure - a structure that contains the object details received from the output 
//                  thread of the rac utility.
//
// Returns:
//   Structure - the structure where "full" and "list" have been converted to True and False.
//
Function ConvertAccessListUsagePropertyValues(Val Details)
	
	Dictionary = AccessManagementListUsagePropertiesDictionary();
	
	Result = New Structure;
	
	For Each KeyAndValue In Details Do
		
		If Dictionary.Property(KeyAndValue.Key) Then
			
			If KeyAndValue.Value = "list" Then
				
				Value = False;
				
			ElsIf KeyAndValue.Value = "full" Then
				
				Value = True;
				
			EndIf;
			
			Result.Insert(KeyAndValue.Key, Value);
			
		Else
			
			Result.Insert(KeyAndValue.Key, KeyAndValue.Value);
			
		EndIf;
		
	EndDo;
	
	Return Result;
	
EndFunction

// Converts 1C:Enterprise script values into the notation of the console client of the 
//  administration server.
//
// Parameters:
//   Value - Arbitrary - value to convert.
//
// Returns:
//   String - value casted to the notation of the console client of the administration server.
//
Function CastValue(Val Value)
	
	If TypeOf(Value) = Type("Date") Then
		
		Return XMLString(Value);
		
	ElsIf TypeOf(Value) = Type("Boolean") Then
		
		Return Format(Value, "BF=no; BT=yes");
		
	ElsIf TypeOf(Value) = Type("Number") Then
		
		Return Format(Value, "NDS=,; NZ=0; NG=0; NN=1");
		
	ElsIf TypeOf(Value) = Type("String") Then
		
		// It is written in documentation:
		// Strings that allow arbitrary characters are output in double quotation marks. These  double quotation marks are duplicated in the strings themselves.
		Numbers = "0123456789";
		LatinCharacters = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz";
		CyrillicCharacters = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz"; // ACC:1036 do not spell check the alphabet.
		AllowedChars = Numbers + LatinCharacters + CyrillicCharacters + "-";
		If StringContainsAllowedCharsOnly(Value, AllowedChars) Then
			Return Value;
		Else
			Return """" + StrReplace(Value, """", """""") + """";
		EndIf;
		
	EndIf;
	
	Return String(Value);
	
EndFunction

Function StringContainsAllowedCharsOnly(String, AllowedChars)
	
	AllAllowedChars = New Map;
	For Position = 1 To StrLen(AllowedChars) Do
		AllAllowedChars[Mid(AllowedChars, Position, 1)] = True;
	EndDo;
	
	For Position = 1 To StrLen(String) Do
		If AllAllowedChars[Mid(String, Position, 1)] = Undefined Then
			Return False;
		EndIf;
	EndDo;
	
	Return True;
	
EndFunction


// Converts the output thread item that contains a value into the notation of the console client of 
//  the administration server.
//
// Parameters:
//   OutputItem - String - output thread item that contains the value in the notation of the console 
//                            client of the administration server.
//   ItemType - Type - item type, one of the simple types: String, Boolean, Date, and Number
//
// Returns:
//   Arbitrary - script language value.
//
Function CastOutputItem(OutputItem, ItemType)
	
	If ItemType = Type("String") Then
		
		Return OutputItem;
		
	ElsIf ItemType = Type("Number") Then
		
		If IsBlankString(OutputItem) Then
			Return 0;
		EndIf;
		
		Try
			Return Number(OutputItem);
		Except
			Raise NStr("ru = 'Неправильный формат.'; en = 'Invalid format.'; pl = 'Niepoprawny format.';de = 'Falsches Format.';ro = 'Format incorect.';tr = 'Yanlış biçim.'; es_ES = 'Formato incorrecto.'");
		EndTry;
		
	ElsIf ItemType = Type("Date") Then
		
		If IsBlankString(OutputItem) Then
			Return Date(1, 1, 1);
		EndIf;
		
		Try
			Return XMLValue(Type("Date"), OutputItem);
		Except
			Raise NStr("ru = 'Неправильный формат.'; en = 'Invalid format.'; pl = 'Niepoprawny format.';de = 'Falsches Format.';ro = 'Format incorect.';tr = 'Yanlış biçim.'; es_ES = 'Formato incorrecto.'");
		EndTry;
		
	ElsIf ItemType = Type("Boolean") Then
		
		If OutputItem = "on" Or OutputItem = "yes" Then
			Return True;
		ElsIf OutputItem = "off" Or OutputItem = "no" Then
			Return False;
		Else
			Raise NStr("ru = 'Неправильный формат.'; en = 'Invalid format.'; pl = 'Niepoprawny format.';de = 'Falsches Format.';ro = 'Format incorect.';tr = 'Yanlış biçim.'; es_ES = 'Formato incorrecto.'");
		EndIf;
		
	ElsIf ItemType = Undefined Then
		
		// An attempt to understand what type is not executed in the string, as, for example, a blank string 
		// can be a blank date, and there can be only numbers in the string (for example, working process 
		// PID).
		
		If IsBlankString(OutputItem) Then
			Return Undefined;
		EndIf;
		
		Return OutputItem;
		
	Else
		
		Raise NStr("ru = 'Неверный тип элемента.'; en = 'Invalid item type.'; pl = 'Błędny typ elementu.';de = 'Falscher Elementtyp.';ro = 'Tip de element nevalid.';tr = 'Yanlış öğe tipi.'; es_ES = 'Tipo de elemento incorrecto.'");
		
	EndIf;
	
	Return OutputItem;
	
EndFunction

// Converts redirected output thread of the console client of the administration server into the 
// array of maps (array elements -objects; map keys - property names; map values - property values).
// 
//
// Parameters:
//   OutputStream - String - a redirected output stream,
//   Dictionary - Structure - a mapping dictionary for object property names.
//                         In the rac utility notation and API notation,
//   Filter - Structure - object filter criteria (only for the threads of output commands that 
//                        return object collections).
//   PropertyTypes - Map - where the key is a property name, and the value is a property type.
//
// Returns:
//   Array - an array of objects, structures, or mapping details (depending on fullness of Dictionary property).
//
Function OutputParser(Val OutputStream, Val Dictionary, Val Filter = Undefined, PropertyTypes = Undefined)
	
	Result = New Array;
	ResultItem = New Map;
	
	Position = 1;
	OutputEnd = StrLen(OutputStream);
	
	While Position <= OutputEnd Do
		
		PropertyName = ReadUpToSeparator(OutputStream, Position, ":");
		PropertyRow = ReadUpToSeparator(OutputStream, Position, Chars.LF);
		PropertyType = ?(PropertyTypes = Undefined, Undefined, PropertyTypes.Get(PropertyName));
		PropertyValue = CastOutputItem(PropertyRow, PropertyType);
		ResultItem.Insert(PropertyName, PropertyValue);
		
		If Mid(OutputStream, Position, 1) = Chars.LF Then
			Position = Position + 1;
			OutputItemParser(ResultItem, Result, Dictionary, Filter);
			ResultItem = New Map;
		EndIf;
		
	EndDo;
	
	If ResultItem.Count() > 0 Then
		OutputItemParser(ResultItem, Result, Dictionary, Filter);
	EndIf;
	
	Return Result;
	
EndFunction

// Reads the string up to the separator shifting the position.
// 
// Parameters:
//   Stream - String - text.
//   Position - Number - the number of a current character.
//   Separator - Char - a character that is a separator.
//
// Returns:
//   String - a string read from the current position up to the separator. All extra quotation marks were deleted from it.
Function ReadUpToSeparator(Thread, Position, Separator)
	
	CurrentChar = Mid(Thread, Position, 1);
	
	// Move the position to the significant character.
	While IsBlankString(CurrentChar) AND Not CurrentChar = Separator AND Position < StrLen(Thread) Do
		Position = Position + 1;
		CurrentChar = Mid(Thread, Position, 1);
	EndDo;
	
	If CurrentChar = Separator Then
		Position = Position + 1;
		Return "";
	EndIf;
	
	QuotationMark = """";
	If CurrentChar = QuotationMark Then
		Position = Position + 1;
		StartPosition = Position;
		// You need to go to the next single quotation mark
		While Position <= StrLen(Thread) Do
			FoundQuotationMark = StrFind(Thread, QuotationMark, SearchDirection.FromBegin, Position); 
			If FoundQuotationMark = 0 Then
				Raise NStr("ru = 'Неправильный формат.'; en = 'Invalid format.'; pl = 'Niepoprawny format.';de = 'Falsches Format.';ro = 'Format incorect.';tr = 'Yanlış biçim.'; es_ES = 'Formato incorrecto.'");
			ElsIf Mid(Thread, FoundQuotationMark + 1, 1) = QuotationMark Then
				Position = FoundQuotationMark + 2;
			Else
				Position = FoundQuotationMark + 1;
				// There can be separator behind the quotation mark.
				If Mid(Thread, Position, 1) = Separator Then
					Position = Position + 1;
				EndIf;
				Break;
			EndIf;
		EndDo;
		If Position > StrLen(Thread) Then
			Raise NStr("ru = 'Неправильный формат.'; en = 'Invalid format.'; pl = 'Niepoprawny format.';de = 'Falsches Format.';ro = 'Format incorect.';tr = 'Yanlış biçim.'; es_ES = 'Formato incorrecto.'");
		EndIf;
		Value = TrimAll(Mid(Thread, StartPosition, FoundQuotationMark - StartPosition));
		Value = StrReplace(Value, QuotationMark + QuotationMark, QuotationMark);
		Return Value;
	Else
		// Simple case, read up to the next separator
		SeparatorPosition = StrFind(Thread, Separator, SearchDirection.FromBegin, Position);
		Value = TrimAll(Mid(Thread, Position, SeparatorPosition - Position));
		Position = SeparatorPosition + 1;
		Return Value;
	EndIf;
	
EndFunction

// Converts the item of the redirected output thread of the console client of the administration 
//  server into a map. Map keys - property names; map values - property values.
//
// Parameters:
//   ResultItem - String - an item of output stream,
//   Result - Array - array where the parsed object must be added,
//   Dictionary - Structure - a mapping dictionary for object property names.
//                         In the rac utility notation and API notation,
//   Filter - Structure - object filter criteria (only for the threads of output commands that 
//                        return object collections).
//
Procedure OutputItemParser(ResultItem, Result, Dictionary, Filter)
	
	If Dictionary <> Undefined Then
		Object = ParseOutputItem(ResultItem, Dictionary);
	Else
		Object = ResultItem;
	EndIf;
	
	If Filter <> Undefined AND Not ClusterAdministration.CheckFilterConditions(Object, Filter) Then
		Return;
	EndIf;
	
	Result.Add(Object);
	
EndProcedure

// Parses an item of the redirected output stream of the administration server console client.
//
// Parameters:
//   OutputItem - String - item of the redirected output stream of the administration server client.
//   Dictionary - Structure - a structure acting as a map dictionary for object property names in 
//                  the rac utility notation and in the API notation.
//
// Returns:
//   Structure - a structure where keys are property names in API notation, values are property 
//                  values from redirected output stream.
//
Function ParseOutputItem(Val OutputItem, Val Dictionary)
	
	Result = New Structure();
	
	For Each DictionaryFragment In Dictionary Do
		If TypeOf(DictionaryFragment.Value) = Type("FixedStructure") Then
			SubordinateObject = OutputItem[DictionaryFragment.Value.Key];
			If SubordinateObject = Undefined Then
				Result.Insert(DictionaryFragment.Key, Undefined);
			Else
				Property = ParseOutputItem(OutputItem[DictionaryFragment.Value.Key], DictionaryFragment.Value.Dictionary);
				Result.Insert(DictionaryFragment.Key, Property);
			EndIf;
		Else
			Result.Insert(DictionaryFragment.Key, OutputItem[DictionaryFragment.Value]);
		EndIf;
		
	EndDo;
	
	Return Result;
	
EndFunction

// Converts filter into the rac utility notation.
//
// Parameters:
//   Filter - Structure, Array - filter in API notation.
//   Dictionary - Structure - correspondence between property names in API notation and in the rac utility notation.
//
// Returns:
//   Structure, Array - filter in the rac utility notation.
//
Function FilterToRacNotation(Val Filter, Val Dictionary)
	
	If Filter = Undefined Then
		Return Undefined;
	EndIf;
	
	If Dictionary = Undefined Then
		Return Filter;
	EndIf;
	
	Result = New Array();
	
	For Each Condition In Filter Do
		
		If TypeOf(Condition) = Type("KeyAndValue") Then
			
			Result.Add(New Structure("Property, ComparisonType, Value", Dictionary[Condition.Key], ComparisonType.Equal, Condition.Value));
			
		ElsIf TypeOf(Condition) = Type("Structure") Then
			
			Result.Add(New Structure("Property, ComparisonType, Value", Dictionary[Condition.Property], Condition.ComparisonType, Condition.Value));
			
		EndIf;
		
	EndDo;
	
	Return Result;
	
EndFunction

// Returns a map of infobase property names that describe the session lock state and scheduled jobs. 
//  Is used for structures used in the API and for object descriptions in the rac output.
//  
//
// Returns:
//   FixedStructure - fixed structure that:
//     * Key - String - the name of an API property (see ClusterAdministration.SessionAndScheduleJobLockProperties()),
//     * Value - String - the name of an object property.
//
Function SessionAndScheduledJobLockPropertiesDictionary()
	
	Result = ClusterAdministration.SessionAndScheduleJobLockProperties();
	
	Result.SessionsLock = "sessions-deny";
	Result.DateFrom = "denied-from";
	Result.DateTo = "denied-to";
	Result.Message = "denied-message";
	Result.KeyCode = "permission-code";
	Result.LockParameter = "denied-parameter";
	Result.ScheduledJobLock = "scheduled-jobs-deny";
	
	Return New FixedStructure(Result);
	
EndFunction

// Returns a map of infobase session property names for structures used in the API and object 
//  descriptions in the rac output.
//
// Returns:
//   FixedStructure - fixed structure that:
//     * Key - String - the name of an API property (see ClusterAdministration.SessionProperties()),
//     * Value - String - the name of an object property.
//
Function SessionPropertiesDictionary()
	
	License = New Structure;
	License.Insert("Key", "license");
	License.Insert("Dictionary", LicensePropertiesDictionary());
	
	ConnectionDetails = New Structure;
	ConnectionDetails.Insert("Key", "connection");
	ConnectionDetails.Insert("Dictionary", ConnectionDetailsPropertiesDictionary());
	
	WorkingProcess = New Structure;
	WorkingProcess.Insert("Key", "process");
	WorkingProcess.Insert("Dictionary", WorkingProcessPropertiesDictionary());
	
	Result = ClusterAdministration.SessionProperties();
	
	Result.Number = "session-id";
	Result.UserName = "user-name";
	Result.ClientComputerName = "host";
	Result.ClientApplicationID = "app-id";
	Result.LanguageID = "locale";
	Result.SessionCreationTime = "started-at";
	Result.LatestSessionActivityTime = "last-active-at";
	Result.DBMSLock = "blocked-by-dbms";
	Result.Lock = "blocked-by-ls";
	Result.Passed = "bytes-all";
	Result.PassedIn5Minutes = "bytes-last-5min";
	Result.ServerCalls = "calls-all";
	Result.ServerCallsIn5Minutes = "calls-last-5min";
	Result.ServerCallDurations = "duration-all";
	Result.CurrentServerCallDuration = "duration-current";
	Result.ServerCallDurationsIn5Minutes = "duration-last-5min";
	Result.ExchangedWithDBMS = "dbms-bytes-all";
	Result.ExchangedWithDBMSIn5Minutes = "dbms-bytes-last-5min";
	Result.DBMSCallDurations = "duration-all-dbms";
	Result.CurrentDBMSCallDuration = "duration-current-dbms";
	Result.DBMSCallDurationsIn5Minutes = "duration-last-5min-dbms";
	Result.DBMSConnection = "db-proc-info";
	Result.DBMSConnectionTime = "db-proc-took";
	Result.DBMSConnectionSeizeTime = "db-proc-took-at";
	Result.Sleep = "hibernate";
	Result.TerminateIn = "hibernate-session-terminate-time";
	Result.SleepIn = "passive-session-hibernate-time";
	Result.ReadFromDisk = "read-total";
	Result.ReadFromDiskInCurrentCall = "read-current";
	Result.ReadFromDiskIn5Minutes = "read-last-5min";
	Result.OccupiedMemory = "memory-total";
	Result.OccupiedMemoryInCurrentCall = "memory-current";
	Result.OccupiedMemoryIn5Minutes = "memory-last-5min";
	Result.WrittenOnDisk = "write-total";
	Result.WrittenOnDiskInCurrentCall = "write-current";
	Result.WrittenOnDiskIn5Minutes = "write-last-5min";
	Result.License = New FixedStructure(License);
	Result.ConnectionDetails = New FixedStructure(ConnectionDetails);
	Result.WorkingProcess = New FixedStructure(WorkingProcess);
	
	Return New FixedStructure(Result);
	
EndFunction

// Returns a map of infobase connection property names for structures used in the API and object 
//  descriptions in the rac output.
//
// Returns:
//   FixedStructure - fixed structure that:
//     * Key - String - the name of an API property (see ClusterAdministration.ConnectionsProperties()),
//     * Value - String - the name of an object property.
//
Function ConnectionPropertiesDictionary()
	
	Result = ClusterAdministration.ConnectionProperties();
	
	Result.Number = "conn-id";
	Result.UserName = "user-name";
	Result.ClientComputerName = "host";
	Result.ClientApplicationID = "app-id";
	Result.ConnectionEstablishingTime = "connected-at";
	Result.InfobaseConnectionMode = "ib-conn-mode";
	Result.DataBaseConnectionMode = "db-conn-mode";
	Result.DBMSLock = "blocked-by-dbms";
	Result.Passed = "bytes-all";
	Result.PassedIn5Minutes = "bytes-last-5min";
	Result.ServerCalls = "calls-all";
	Result.ServerCallsIn5Minutes = "calls-last-5min";
	Result.ExchangedWithDBMS = "dbms-bytes-all";
	Result.ExchangedWithDBMSIn5Minutes = "dbms-bytes-last-5min";
	Result.DBMSConnection = "db-proc-info";
	Result.DBMSTime = "db-proc-took";
	Result.DBMSConnectionSeizeTime = "db-proc-took-at";
	Result.ServerCallDurations = "duration-all";
	Result.DBMSCallDurations = "duration-all-dbms";
	Result.CurrentServerCallDuration = "duration-current";
	Result.CurrentDBMSCallDuration = "duration-current-dbms";
	Result.ServerCallDurationsIn5Minutes = "duration-last-5min";
	Result.DBMSCallDurationsIn5Minutes = "duration-last-5min-dbms";
	Result.ReadFromDisk = "read-total";
	Result.ReadFromDiskInCurrentCall = "read-current";
	Result.ReadFromDiskIn5Minutes = "read-last-5min";
	Result.OccupiedMemory = "memory-total";
	Result.OccupiedMemoryInCurrentCall = "memory-current";
	Result.OccupiedMemoryIn5Minutes = "memory-last-5min";
	Result.WrittenOnDisk = "write-total";
	Result.WrittenOnDiskInCurrentCall = "write-current";
	Result.WrittenOnDiskIn5Minutes = "write-last-5min";
	Result.ControlIsOnServer = "thread-mode";
	
	Return New FixedStructure(Result);
	
EndFunction

// Returns a map of security profile property names for structures used in the API and object 
//  descriptions in the rac output.
//
// Returns:
//   FixedStructure - fixed structure that:
//     * Key - String - the name of an API property (see ClusterAdministration.SecurityProfileProperties()),
//     * Value - String - the name of an object property.
//
Function SecurityProfilePropertiesDictionary(Val IncludeAccessManagementListsUsageProperties = True)
	
	Result = ClusterAdministration.SecurityProfileProperties();
	
	Result.Delete("COMClasses");
	Result.Delete("VirtualDirectories");
	Result.Delete("AddIns");
	Result.Delete("ExternalModules");
	Result.Delete("InternetResources");
	Result.Delete("OSApplications");
	
	Result.Name = "name";
	Result.Details = "descr";
	Result.SafeModeProfile = "config";
	Result.FullAccessToPrivilegedMode =  "priv";
	Result.FullAccessToCryptoFunctions = "crypto";
	Result.FullAccessToAllModulesExtension = "all-modules-extension";
	Result.ModulesAvailableForExtension = "modules-available-for-extension";
	Result.ModulesNotAvailableForExtension = "modules-not-available-for-extension";
	Result.FullAccessToAccessRightsExtension = "right-extension";
	Result.AccessRightsExtensionLimitingRoles = "right-extension-definition-roles";
	
	AccessManagementListsUsagePropertiesDictionary = AccessManagementListUsagePropertiesDictionary();
	For Each DictionaryFragment In AccessManagementListsUsagePropertiesDictionary Do
		If IncludeAccessManagementListsUsageProperties Then
			Result[DictionaryFragment.Key] = DictionaryFragment.Value;
		Else
			Result.Delete(DictionaryFragment.Key);
		EndIf;
	EndDo;
	
	Return New FixedStructure(Result);
	
EndFunction

// Returns a map of security profile property names for structures used in the API and object 
//  descriptions in the rac output.
//
// Returns:
//   FixedStructure - fixed structure that:
//     * Key - String - the name of an API property (see ClusterAdministration.SecurityProfileProperties()),
//     * Value - String - the name of an object property.
//
Function AccessManagementListUsagePropertiesDictionary()
	
	Result = New Structure();
	
	Result.Insert("FullFileSystemAccess", "directory");
	Result.Insert("FullCOMObjectAccess", "com");
	Result.Insert("FullAddInAccess", "addin");
	Result.Insert("FullExternalModuleAccess", "module");
	Result.Insert("FullOperatingSystemApplicationAccess", "app");
	Result.Insert("FullInternetResourceAccess", "inet");
	
	Return New FixedStructure(Result);
	
EndFunction

// Returns a map of virtual directory property names for structures used in the API and object 
//  descriptions in the rac output.
//
// Returns:
//   FixedStructure - fixed structure that:
//     * Key - String - the name of an API property (see ClusterAdministration.VirtualDirectoryProperties()),
//     * Value - String - the name of an object property.
//
Function VirtualDirectoryPropertiesDictionary()
	
	Result = ClusterAdministration.VirtualDirectoryProperties();
	
	Result.LogicalURL = "alias";
	Result.PhysicalURL = "physicalPath";
	
	Result.Details = "descr";
	
	Result.DataReader = "allowedRead";
	Result.DataWriter = "allowedWrite";
	
	Return New FixedStructure(Result);
	
EndFunction

// Returns a map of COM class property names for structures used in the API and object descriptions 
//  in the rac output.
//
// Returns:
//   FixedStructure - fixed structure that:
//     * Key - String - the name of an API property (see ClusterAdministration.COMClassProperties()),
//     * Value - String - the name of an object property.
//
Function COMClassPropertiesDictionary()
	
	Result = ClusterAdministration.COMClassProperties();
	
	Result.Name = "name";
	Result.Details = "descr";
	
	Result.FileMoniker = "fileName";
	Result.CLSID = "id";
	Result.Computer = "host";
	
	Return New FixedStructure(Result);
	
EndFunction

// Returns a map of add-in property names for structures used in the API and object descriptions in 
//  the rac output.
//
// Returns:
//   FixedStructure - fixed structure that:
//     * Key - String - the name of an API property (see ClusterAdministration.AddInProperties()),
//     * Value - String - the name of an object property.
//
Function AddInPropertiesDictionary()
	
	Result = ClusterAdministration.AddInProperties();
	
	Result.Name = "name";
	Result.Details = "descr";
	
	Result.HashSum = "hash";
	
	Return New FixedStructure(Result);
	
EndFunction

// Returns a map of external module property names for structures used in the API and object 
//  descriptions in the rac output.
//
// Returns:
//   FixedStructure - fixed structure that:
//     * Key - String - the name of an API property (see ClusterAdministration.ExternalModuleProperties()),
//     * Value - String - the name of an object property.
//
Function ExternalModulePropertiesDictionary()
	
	Result = ClusterAdministration.ExternalModuleProperties();
	
	Result.Name = "name";
	Result.Details = "descr";
	
	Result.HashSum = "hash";
	
	Return New FixedStructure(Result);
	
EndFunction

// Returns a map of OS application property names for structures used in the API and object 
//  descriptions in the rac output.
//
// Returns:
//   FixedStructure - fixed structure that:
//     * Key - String - the name of an API property (see ClusterAdministration.OSApplicationProperties()),
//     * Value - String - the name of an object property.
//
Function OSApplicationPropertiesDictionary()
	
	Result = ClusterAdministration.OSApplicationProperties();
	
	Result.Name = "name";
	Result.Details = "descr";
	
	Result.CommandLinePattern = "wild";
	
	Return New FixedStructure(Result);
	
EndFunction

// Returns a map of Internet resource property names for structures used in the API and object 
//  details in the rac output.
//
// Returns:
//   FixedStructure - fixed structure that:
//     * Key - String - the name of an API property (see ClusterAdministration.InternetResourceProperties()),
//     * Value - String - the name of an object property.
//
Function InternetResourcePropertiesDictionary()
	
	Result = ClusterAdministration.InternetResourceProperties();
	
	Result.Name = "name";
	Result.Details = "descr";
	
	Result.Protocol = "protocol";
	Result.Address = "url";
	Result.Port = "port";
	
	Return New FixedStructure(Result);
	
EndFunction

// Returns a map of Connection details property names for structures used in the API and object 
//  details in the rac output.
//
// Returns:
//   FixedStructure - fixed structure that:
//     * Key - String - the name of an API property (see ClusterAdministration.ConnectionDetailsProperties()),
//     * Value - String - the name of an object property.
//
Function ConnectionDetailsPropertiesDictionary()
	
	WorkingProcess = New Structure;
	WorkingProcess.Insert("Key", "process");
	WorkingProcess.Insert("Dictionary", WorkingProcessPropertiesDictionary());
	
	Result = ClusterAdministration.ConnectionDetailsProperties();
	
	Result.ApplicationName = "application";
	Result.Lock = "blocked-by-ls";
	Result.ConnectionEstablishingTime = "connected-at";
	Result.Number = "conn-id";
	Result.ClientComputerName = "host";
	Result.SessionNumber = "session-number";
	Result.WorkingProcess = New FixedStructure(WorkingProcess);
	
	Return New FixedStructure(Result);
	
EndFunction

// Returns a map of License property names for structures used in the API and object details in the 
//  rac output.
//
// Returns:
//   FixedStructure - fixed structure that:
//     * Key - String - the name of an API property (see ClusterAdministration.LicenseProperties()),
//     * Value - String - the name of an object property.
//
Function LicensePropertiesDictionary()
	
	Result = ClusterAdministration.LicenseProperties();
	
	Result.FileName = "full-name";
	Result.FullPresentation = "full-presentation";
	Result.BriefPresentation = "short-presentation";
	Result.IssuedByServer = "issued-by-server";
	Result.LisenceType = "license-type";
	Result.MaxUsersForSet = "max-users-all";
	Result.MaxUsersInKey = "max-users-cur";
	Result.LicenseIsReceivedViaAladdinLicenseManager = "net";
	Result.ProcessAddress = "rmngr-address";
	Result.ProcessID = "rmngr-pid";
	Result.ProcessPort = "rmngr-port";
	Result.KeySeries = "series";
	
	Return New FixedStructure(Result);
	
EndFunction

// Returns a map of Working process property names for structures used in the API and object details 
//  in the rac output.
//
// Returns:
//   FixedStructure - fixed structure that:
//     * Key - String - the name of an API property (see ClusterAdministration.WorkingProcessProperties()),
//     * Value - String - the name of an object property.
//
Function WorkingProcessPropertiesDictionary()
	
	License = New Structure;
	License.Insert("Key", "license");
	License.Insert("Dictionary", LicensePropertiesDictionary());
	
	Result = ClusterAdministration.WorkingProcessProperties();
	
	Result.AvailablePerformance = "available-perfomance";
	Result.SpentByTheClient = "avg-back-call-time";
	Result.ServerReaction = "avg-call-time";
	Result.SpentByDBMS = "avg-db-call-time";
	Result.SpentByTheLockManager = "avg-lock-call-time";
	Result.SpentByTheServer = "avg-server-call-time";
	Result.ClientStreams = "avg-threads";
	Result.RelativePerformance = "capacity";
	Result.Connections = "connections";
	Result.ComputerName = "host";
	Result.Enabled = "is-enable";
	Result.Port = "port";
	Result.ExceedingTheCriticalValue = "memory-excess-time";
	Result.OccupiedMemory = "memory-size";
	Result.ID = "pid";
	Result.Started = "running";
	Result.CallsCountByWhichTheStatisticsIsCalculated = "selection-size";
	Result.StartedAt = "started-at";
	Result.Use = "use";
	Result.License = New FixedStructure(License);
	
	Return New FixedStructure(Result);
	
EndFunction

// Returns names of the key acl properties (in the rac utility notation).
//
// Returns:
//   FixedStructure - fixed structure that:
//     * Key - String - acl name,
//     * Value - String - key property name.
//
Function AccessManagementListsKeys()
	
	Result = New Structure();
	
	Result.Insert("directory", "alias");
	Result.Insert("com", "name");
	Result.Insert("addin", "name");
	Result.Insert("module", "name");
	Result.Insert("app", "name");
	Result.Insert("inet", "name");
	
	Return New FixedStructure(Result);
	
EndFunction

// Returns a map of names in the rac notation and for cluster properties.
// 
// Returns:
//   FixedMap - property name is specified as a key, and Type as a value.
//
Function ClusterPropertyTypes()
	
	Types = New Map;
	
	Types.Insert("cluster", Type("String"));
	Types.Insert("host", Type("String"));
	Types.Insert("port", Type("Number"));
	Types.Insert("name", Type("String"));
	Types.Insert("expiration-timeout", Type("Number"));
	Types.Insert("lifetime-limit", Type("Number"));
	Types.Insert("max-memory-size", Type("Number"));
	Types.Insert("max-memory-time-limit", Type("Number"));
	Types.Insert("security-level", Type("Number"));
	Types.Insert("session-fault-tolerance-level", Type("Number"));
	Types.Insert("load-balancing-mode", Type("String"));
	Types.Insert("errors-count-threshold", Type("Number"));
	Types.Insert("kill-problem-processes", Type("Number"));
	
	Return New FixedMap(Types);

EndFunction

// Returns a map of names in the rac notation and types for working server properties.
// 
// Returns:
//   FixedMap - property name is specified as a key, and Type as a value.
//
Function WorkingServerPropertyTypes()
	
	Types = New Map;
	
	Types.Insert("server", Type("String"));
	Types.Insert("agent-host", Type("String"));
	Types.Insert("agent-port", Type("Number"));
	Types.Insert("port-range", Type("String"));
	Types.Insert("name", Type("String"));
	Types.Insert("using", Type("String"));
	Types.Insert("dedicate-managers", Type("String"));
	Types.Insert("infobases-limit", Type("Number"));
	Types.Insert("memory-limit", Type("Number"));
	Types.Insert("connections-limit", Type("Number"));
	Types.Insert("safe-working-processes-memory-limit", Type("Number"));
	Types.Insert("safe-call-memory-limit", Type("Number"));
	Types.Insert("cluster-port", Type("Number"));

	Return New FixedMap(Types);
	
EndFunction

// Returns a map of names in the rac notation and types for base details properties.
// 
// Returns:
//   FixedMap - property name is specified as a key, and Type as a value.
//
Function BaseDetailsPropertyTypes()
	
	Types = New Map;
	
	Types.Insert("infobase", Type("String"));
	Types.Insert("name", Type("String"));
	Types.Insert("descr", Type("String"));

	Return New FixedMap(Types);
	
EndFunction

// Returns a map of names in the rac notation and types for infobase properties.
// 
// Returns:
//   FixedMap - property name is specified as a key, and Type as a value.
//
Function InfoBasePropertyTypes()
	
	Types = New Map;
	
	Types.Insert("infobase", Type("String"));
	Types.Insert("name", Type("String"));
	Types.Insert("dbms", Type("String"));
	Types.Insert("db-server", Type("String"));
	Types.Insert("db-name", Type("String"));
	Types.Insert("db-user", Type("String"));
	Types.Insert("security-level", Type("Number"));
	Types.Insert("license-distribution", Type("String"));
	Types.Insert("scheduled-jobs-deny", Type("Boolean"));
	Types.Insert("sessions-deny", Type("Boolean"));
	Types.Insert("denied-from", Type("Date"));
	Types.Insert("denied-message", Type("String"));
	Types.Insert("denied-parameter", Type("String"));
	Types.Insert("denied-to", Type("Date"));
	Types.Insert("permission-code", Type("String"));
	Types.Insert("external-session-manager-connection-string", Type("String"));
	Types.Insert("external-session-manager-required", Type("Boolean"));
	Types.Insert("security-profile-name", Type("String"));
	Types.Insert("safe-mode-security-profile-name", Type("String"));
	Types.Insert("descr", Type("String"));

	Return New FixedMap(Types);
	
EndFunction

// Returns a map of names in the rac notation and types for session properties.
// 
// Returns:
//   FixedMap - property name is specified as a key, and Type as a value.
//
Function SessionPropertyTypes()
	
	Types = New Map;
	
	Types.Insert("session", Type("String"));
	Types.Insert("session-id", Type("Number"));
	Types.Insert("infobase", Type("String"));
	Types.Insert("connection", Type("String"));
	Types.Insert("process", Type("String"));
	Types.Insert("user-name", Type("String"));
	Types.Insert("host", Type("String"));
	Types.Insert("app-id", Type("String"));
	Types.Insert("locale", Type("String"));
	Types.Insert("started-at", Type("Date"));
	Types.Insert("last-active-at", Type("Date"));
	Types.Insert("hibernate", Type("Boolean"));
	Types.Insert("passive-session-hibernate-time", Type("Number"));
	Types.Insert("hibernate-session-terminate-time", Type("Number"));
	Types.Insert("blocked-by-dbms", Type("Number"));
	Types.Insert("blocked-by-ls", Type("Number"));
	Types.Insert("bytes-all", Type("Number"));
	Types.Insert("bytes-last-5min", Type("Number"));
	Types.Insert("calls-all", Type("Number"));
	Types.Insert("calls-last-5min", Type("Number"));
	Types.Insert("dbms-bytes-all", Type("Number"));
	Types.Insert("dbms-bytes-last-5min", Type("Number"));
	Types.Insert("db-proc-info", Type("String"));
	Types.Insert("db-proc-took", Type("Number"));
	Types.Insert("db-proc-took-at", Type("Date"));
	Types.Insert("duration-all", Type("Number"));
	Types.Insert("duration-all-dbms", Type("Number"));
	Types.Insert("duration-current", Type("Number"));
	Types.Insert("duration-current-dbms", Type("Number"));
	Types.Insert("duration-last-5min", Type("Number"));
	Types.Insert("duration-last-5min-dbms", Type("Number"));
	Types.Insert("memory-current", Type("Number"));
	Types.Insert("memory-last-5min", Type("Number"));
	Types.Insert("memory-total", Type("Number"));
	Types.Insert("read-current", Type("Number"));
	Types.Insert("read-last-5min", Type("Number"));
	Types.Insert("read-total", Type("Number"));
	Types.Insert("write-current", Type("Number"));
	Types.Insert("write-last-5min", Type("Number"));
	Types.Insert("write-total", Type("Number"));
	
	Return New FixedMap(Types);
	
EndFunction

// Returns a map of names in the rac notation and types for connection properties.
// 
// Returns:
//   FixedMap - property name is specified as a key, and Type as a value.
//
Function ConnectionPropertyTypes()
	
	Types = New Map;
	
	Types.Insert("connection", Type("String"));
	Types.Insert("conn-id", Type("Number"));
	Types.Insert("user-name", Type("String"));
	Types.Insert("host", Type("String"));
	Types.Insert("app-id", Type("String"));
	Types.Insert("connected-at", Type("Date"));
	Types.Insert("thread-mode", Type("String"));
	Types.Insert("ib-conn-mode", Type("String"));
	Types.Insert("db-conn-mode", Type("String"));
	Types.Insert("blocked-by-dbms", Type("Number"));
	Types.Insert("bytes-all", Type("Number"));
	Types.Insert("bytes-last-5min", Type("Number"));
	Types.Insert("calls-all", Type("Number"));
	Types.Insert("calls-last-5min", Type("Number"));
	Types.Insert("dbms-bytes-all", Type("Number"));
	Types.Insert("dbms-bytes-last-5min", Type("Number"));
	Types.Insert("db-proc-info", Type("String"));
	Types.Insert("db-proc-took", Type("Number"));
	Types.Insert("db-proc-took-at", Type("Date"));
	Types.Insert("duration-all", Type("Number"));
	Types.Insert("duration-all-dbms", Type("Number"));
	Types.Insert("duration-current", Type("Number"));
	Types.Insert("duration-current-dbms", Type("Number"));
	Types.Insert("duration-last-5min", Type("Number"));
	Types.Insert("duration-last-5min-dbms", Type("Number"));
	Types.Insert("memory-current", Type("Number"));
	Types.Insert("memory-last-5min", Type("Number"));
	Types.Insert("memory-total", Type("Number"));
	Types.Insert("read-current", Type("Number"));
	Types.Insert("read-last-5min", Type("Number"));
	Types.Insert("read-total", Type("Number"));
	Types.Insert("write-current", Type("Number"));
	Types.Insert("write-last-5min", Type("Number"));
	Types.Insert("write-total", Type("Number"));
	
	Return New FixedMap(Types);
	
EndFunction

// Returns a map of names in the rac notation and types for security profile properties.
// 
// Returns:
//   FixedMap - property name is specified as a key, and Type as a value.
//
Function ProfilePropertyTypes()
	
	Types = New Map;
	
	Types.Insert("name", Type("String"));
	Types.Insert("descr", Type("String"));
	Types.Insert("config", Type("Boolean"));
	Types.Insert("priv", Type("Boolean"));
	Types.Insert("directory", Type("String"));
	Types.Insert("com", Type("String"));
	Types.Insert("addin", Type("String"));
	Types.Insert("module", Type("String"));
	Types.Insert("app", Type("String"));
	Types.Insert("inet", Type("String"));
	Types.Insert("crypto", Type("Boolean"));
	Types.Insert("right-extension", Type("Boolean"));
	Types.Insert("right-extension-definition-roles", Type("String"));
	Types.Insert("all-modules-extension", Type("Boolean"));
	Types.Insert("modules-available-for-extension", Type("String"));
	Types.Insert("modules-not-available-for-extension", Type("String"));
	
	Return New FixedMap(Types);
		
EndFunction

// Returns a map of names in the rac notation and types for connection details properties.
// 
// Returns:
//   FixedMap - property name is specified as a key, and Type as a value.
//
Function ConnectionDetailsPropertyTypes()
	
	Types = New Map;
	
	Types.Insert("connection", Type("String"));
	Types.Insert("conn-id", Type("Number"));
	Types.Insert("host", Type("String"));
	Types.Insert("process", Type("String"));
	Types.Insert("infobase", Type("String"));
	Types.Insert("application", Type("String"));
	Types.Insert("connected-at", Type("Date"));
	Types.Insert("session-number", Type("Number"));
	Types.Insert("blocked-by-ls", Type("Number"));
	
	Return New FixedMap(Types);
		
EndFunction

// Returns a map of names in the rac notation and types for license properties.
// 
// Returns:
//   FixedMap - property name is specified as a key, and Type as a value.
//
Function LicensePropertyTypes()
	
	Types = New Map;
	
	// Returns only for working process license.
	Types.Insert("process", Type("String"));
	Types.Insert("port", Type("Number"));
	Types.Insert("pid", Type("String"));
	Types.Insert("host", Type("String"));
	
	// Returns only for session license.
	Types.Insert("session", Type("String"));
	Types.Insert("user-name", Type("String"));
	Types.Insert("app-id", Type("String"));	
	Types.Insert("host", Type("String"));
	
	// Common to all licenses.
	Types.Insert("full-name", Type("String"));
	Types.Insert("series", Type("String"));
	Types.Insert("issued-by-server", Type("Boolean"));
	Types.Insert("license-type", Type("String"));
	Types.Insert("net", Type("Boolean"));
	Types.Insert("max-users-all", Type("Number"));
	Types.Insert("max-users-cur", Type("Number"));
	Types.Insert("rmngr-address", Type("String"));
	Types.Insert("rmngr-port", Type("Number"));
	Types.Insert("rmngr-pid", Type("String"));
	Types.Insert("short-presentation", Type("String"));
	Types.Insert("full-presentation", Type("String"));
	
	Return New FixedMap(Types);
		
EndFunction

// Returns a map of names in the rac notation and types for lock properties.
// 
// Returns:
//   FixedMap - property name is specified as a key, and Type as a value.
//
Function LockPropertyTypes()
	
	Types = New Map;
	
	Types.Insert("connection", Type("String"));
	Types.Insert("session", Type("String"));
	Types.Insert("object", Type("String"));
	Types.Insert("locked", Type("Date"));
	Types.Insert("descr", Type("String"));
	
	Return New FixedMap(Types);
		
EndFunction

// Returns a map of names in the rac notation and types for working process properties.
// 
// Returns:
//   FixedMap - property name is specified as a key, and Type as a value.
//
Function WorkingProcessPropertyTypes()
	
	Types = New Map;
	
	Types.Insert("process", Type("String"));
	Types.Insert("host", Type("String"));
	Types.Insert("port", Type("Number"));
	Types.Insert("pid", Type("String"));
	Types.Insert("is-enable", Type("Boolean"));
	Types.Insert("running", Type("Boolean"));
	Types.Insert("started-at", Type("Date"));
	Types.Insert("use", Type("String"));
	Types.Insert("available-perfomance", Type("Number"));
	Types.Insert("capacity", Type("Number"));
	Types.Insert("connections", Type("Number"));
	Types.Insert("memory-size", Type("Number"));
	Types.Insert("memory-excess-time", Type("Number"));
	Types.Insert("selection-size", Type("Number"));
	Types.Insert("avg-back-call-time", Type("Number"));
	Types.Insert("avg-call-time", Type("Number"));
	Types.Insert("avg-db-call-time", Type("Number"));
	Types.Insert("avg-lock-call-time", Type("Number"));
	Types.Insert("avg-server-call-time", Type("Number"));
	Types.Insert("avg-threads", Type("Number"));

	Return New FixedMap(Types);
		
EndFunction

// Returns a map of names in the rac notation and types for virtual directory properties.
// 
// Returns:
//   FixedMap - property name is specified as a key, and Type as a value.
//
Function VirtualDirectoryPropertyTypes()
	
	Types = New Map;
	
	Types.Insert("alias", Type("String"));
	Types.Insert("physicalPath", Type("String"));
	Types.Insert("descr", Type("String"));
	Types.Insert("allowedRead", Type("Boolean"));
	Types.Insert("allowedWrite", Type("Boolean"));

	Return New FixedMap(Types);
	
EndFunction

// Returns a map of names in the rac notation and types for com class properties.
// 
// Returns:
//   FixedMap - property name is specified as a key, and Type as a value.
//
Function COMClassPropertyTypes()
	
	Types = New Map;
	
	Types.Insert("name", Type("String"));
	Types.Insert("descr", Type("String"));
	Types.Insert("fileName", Type("String"));
	Types.Insert("id", Type("String"));
	Types.Insert("host", Type("String"));
	
	Return New FixedMap(Types);
	
EndFunction

// Returns a map of names in the rac notation and types for add-in properties.
// 
// Returns:
//   FixedMap - property name is specified as a key, and Type as a value.
//
Function AddInPropertyTypes()
	
	Types = New Map;
	
	Types.Insert("name", Type("String"));
	Types.Insert("descr", Type("String"));
	Types.Insert("hash", Type("String"));
	
	Return New FixedMap(Types);
	
EndFunction

// Returns a map of names in the rac notation and types for external module properties.
// 
// Returns:
//   FixedMap - property name is specified as a key, and Type as a value.
//
Function ExternalModulePropertyType()
	
	Types = New Map;
	
	Types.Insert("name", Type("String"));
	Types.Insert("descr", Type("String"));
	Types.Insert("hash", Type("String"));
	
	Return New FixedMap(Types);
	
EndFunction

// Returns a map of names in the rac notation and types for os application properties.
// 
// Returns:
//   FixedMap - property name is specified as a key, and Type as a value.
//
Function OSApplicationPropertyTypes()
	
	Types = New Map;
	
	Types.Insert("name", Type("String"));
	Types.Insert("descr", Type("String"));
	Types.Insert("wild", Type("String"));
	
	Return New FixedMap(Types);
	
EndFunction

// Returns a map of names in the rac notation and types for Internet resource properties.
// 
// Returns:
//   FixedMap - property name is specified as a key, and Type as a value.
//
Function InternetResourcePropertyTypes()
	
	Types = New Map;
	
	Types.Insert("name", Type("String"));
	Types.Insert("descr", Type("String"));
	Types.Insert("protocol", Type("String"));
	Types.Insert("url", Type("String"));
	Types.Insert("port", Type("Number"));
	
	Return New FixedMap(Types);
	
EndFunction

// Parses the command result and gets the used properties of the first object.
//
// Parameters:
//   Command - String - rac command.
//   PropertyTypes - Map - rac object property types.
//
// Returns:
//   Map - property name is specified as a key, and True as a value.
//
Function SupportedProperties(Command, ClusterAdministrationParameters, PropertyTypes)
	
	Result = RunCommand(Command, ClusterAdministrationParameters, , , PropertyTypes);
	
	Properties = New Map;
	For Each KeyAndValue In Result[0] Do
		Properties.Insert(KeyAndValue.Key, True);
	EndDo;
	
	Return Properties;
	
EndFunction

// Runs the command and parses the result if it is not empty.
//
// Parameters:
//   Command - String - rac command with filled parameters that must be run. For example:
//                  "profile list --cluster=166bf476-9675-4e85-a359-611f46512ac1".
//   Dictionary - Structure - properties dictionary, specify this parameter if the command returns a value.
//   Filter - Array, Structure - filter in API notation, specify this parameter if the command returns a value.
//   PropertyTypes - Map - where the key is a property name, and the value is one of the listed 
//                  types: String, Date, Number, Boolean.
// 
// Returns:
//   Array - an array of objects details (structures or map).
//
Function RunCommand(Command, ClusterAdministrationParameters, Dictionary = Undefined, Filter = Undefined, PropertyTypes = Undefined)
	
	If SafeMode() <> False Then
		Raise NStr("ru = 'Администрирование кластера невозможно в безопасном режиме'; en = 'Safe mode does not support cluster administration.'; pl = 'Administrowanie klastrem jest niedostępne w trybie awaryjnym';de = 'Die Clusterverwaltung ist im abgesicherten Modus nicht möglich';ro = 'Administrarea cluster-ului este imposibilă în regim securizat';tr = 'Küme güvenli modda yönetilemez'; es_ES = 'Es imposible administrar clúster en el modo seguro'");
	EndIf;
	
	If Common.DataSeparationEnabled() Then
		Raise NStr("ru = 'В модели сервиса недопустимо выполнение прикладной информационной базой функций администрирования кластера'; en = 'SaaS mode does not support cluster administration.'; pl = 'Zastosowana baza informacyjna nie może administrować klastra w SaaS';de = 'Im Servicemodell ist es inakzeptabel, dass die Anwendungsinformationsbasis die Funktionen der Clusterverwaltung übernimmt';ro = 'În modelul serviciului nu se admite executarea de către baza de informații aplicată a funcțiilor de administrare a clusterului';tr = 'Servis modelinde, uygulanan işlev veritabanı, kümeyi yönetemez'; es_ES = 'En el modelo de servicio es imposible ejecutar las funciones de administrar clúster por la base de información aplicada'");
	EndIf;
	
	// Substituting path to the rac utility and the ras server address to the command line.
	Client = PathToAdministrationServerClient();
	ClientFile = New File(Client);
	If Not ClientFile.Exist() Then
		
		Raise StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Невозможно выполнить операцию администрирования кластера серверов по причине: файл %1 не найден
			           |
			           |Для администрирования кластера через сервер администрирования (ras) требуется установить на данном
			           |компьютере клиент сервера администрирования (rac).
			           |Для его установки:
			           |- Для компьютеров с ОС Windows требуется переустановить платформу, установив компонент ""Сервер 1С:Предприятия"";
			           |- Для компьютеров с ОС Linux требуется установить пакет 1c-enterprise83-server*.'; 
			           |en = 'Cannot perform server cluster administration due to: file %1 is not found.
			           |
			           |To administer cluster with ras administration server,
			           |install ras administration client on this computer.
			           |To install the administration client:
			           |- On Windows, reinstall 1C:Enterprise with selected 1C:Enterprise server component.
			           |- On Linux, install 1c-enterprise83-server* package.'; 
			           |pl = 'Niemożliwe jest wykonanie operacji administrowania klastera serwerów z powodu: plik %1 nie znaleziony
			           |
			           |Dla administrowania klastera przez serwer administrowania (ras) wymagane jest zainstalować na tym 
			           |komputerze klient serwera administrowania (rac). 
			           |Dla jego instalacji: 
			           |- Dla komputerów z OS Windows należy ponownie zainstalować platformę, instalując komponent ""Serwer 1C:Enterprise""; 
			           |- Dla komputerów z OS Linux jest wymagane zainstalowanie pakietu 1c-enterprise83-server*.';
			           |de = 'Es ist nicht möglich, den Vorgang der Administration des Server-Clusters durchzuführen, da die Datei %1 nicht gefunden wird
			           |
			           | Die Administration des Clusters über den Administrationsserver (ras) erfordert die Installation des Client des Administrationsservers (rac)
			           |auf diesem
			           |Computer. Um es zu installieren:
			           |- Für Windows-Computer müssen Sie die Plattform neu installieren, indem Sie die Komponente ""Server 1C:Enterprise"" installieren;
			           |- Für Linux-Computer müssen Sie das Paket 1c-enterprise83-server* installieren.';
			           |ro = 'Operația de administrare a clusterului serverelor nu poate fi executată din motivul: fișierul %1 nu a fost găsit
			           |
			           |Pentru administrarea clusterului prin intermediul serverului de administrare (ras) trebuie să instalați pe acest
			           |computer clientul serverului de administrare (rac).
			           |Pentru instalarea lui:
			           |- Pentru computere cu SO Windows trebuie să reinstalați platforma cu instalarea componentelor ""Serverul 1С:Enterprise"";
			           |- Pentru computere cu SO Linux trebuie să instalați pachetul 1c-enterprise83-server*.';
			           |tr = 'Sunucu küme yönetiminin operasyonunu çalıştırılamıyor: %1 dosya bulunamadı.
			           |
			           |nKümeyi  yönetici sunucusu (ras) aracılığıyla yönetmek için, bu bilgisayara
			           |n bir yönetim sunucusu (ras) istemcisi yüklemeniz gerekir.
			           |nYüklemek  için:
			           |n- Windows işletim sistemine sahip bilgisayarlar için, 1C: İşletme sunucu yönetimi bileşenini kurarak platformu yeniden yüklemeniz  gerekir"";
			           |- Linux OS''li bilgisayarlar için 1c-enterprise83-server *  paketini yüklemeniz gerekir.'; 
			           |es_ES = 'No se puede ejecutar la operación de la administración del clúster de servidores a causa de: el archivo %1 no se ha encontrado
			           |
			           |Para administrar el clúster a través de la administración del servidor (ras), usted necesita instalar un cliente de administrar el servidor (rac) en este
			           |ordenador.
			           |Para instalarlo: 
			           |- Para los ordenadores con Windows OS usted necesita reinstalar la plataforma instalando el componente ""El servidor de 1C:Enterprise"";
			           |- Para los ordenadores con Linux OS usted necesita instalar el paquete 1c-enterprise83-server*.'"),
			ClientFile.FullName);
		
	EndIf;
	
	CommandLine = """" + Client + """ " + Command;
	
	ApplicationStartupParameters = FileSystem.ApplicationStartupParameters();
	ApplicationStartupParameters.CurrentDirectory = PlatformExecutableFilesDirectory();
	ApplicationStartupParameters.WaitForCompletion = True;
	ApplicationStartupParameters.GetOutputStream = True;
	ApplicationStartupParameters.GetErrorStream = True;
	
	Result = FileSystem.StartApplication(CommandLine, ApplicationStartupParameters);
	
	OutputStream = Result.OutputStream;
	ErrorStream = Result.ErrorStream;
	
	If ValueIsFilled(ErrorStream) Then
		Raise ErrorStream;
	EndIf;
	
	If IsBlankString(OutputStream) Then
		Return New Array;
	EndIf;
	
	Result = OutputParser(OutputStream, Dictionary, Filter, PropertyTypes);
	
	Return Result;
	
EndFunction

// Returns the parameters row for the rac command with the required cluster parameters.
//
//   ClusterAdministrationParameters - Structure - the structure that describes parameters for 
//                  connecting the server cluster. For details, see ClusterAdministration. ClusterAdministrationParameters().
//   ClusterID - String - internal ID of a server cluster.
//
// Returns:
//   String - parameters string.
//
Function ClusterParameters(ClusterAdministrationParameters, ClusterID = Undefined)
	
	If ClusterID = Undefined Then
		ClusterID = ClusterID(ClusterAdministrationParameters);
	EndIf;
	
	ClusterParameters = "--cluster=" + ClusterID;
	If ValueIsFilled(ClusterAdministrationParameters.ClusterAdministratorName) Then
		ClusterParameters = ClusterParameters + " --cluster-user=""" + ClusterAdministrationParameters.ClusterAdministratorName + """";
		If ValueIsFilled(ClusterAdministrationParameters.ClusterAdministratorPassword) Then
			ClusterParameters = ClusterParameters + " --cluster-pwd=""" + ClusterAdministrationParameters.ClusterAdministratorPassword + """";
		EndIf;
	EndIf;
	
	If ValueIsFilled(ClusterAdministrationParameters.AdministrationServerAddress) Then
		Server = TrimAll(ClusterAdministrationParameters.AdministrationServerAddress);
		If ValueIsFilled(ClusterAdministrationParameters.AdministrationServerPort) Then
			Server = Server + ":" + CastValue(ClusterAdministrationParameters.AdministrationServerPort);
		EndIf;
		ClusterParameters = ClusterParameters + " " + Server;
	EndIf;
	
	Return ClusterParameters;
	
EndFunction

// Substitutes parameters in a string similar to the StringFunctionsClientServer.
// SubstituteParametersToString() and converts the value to the rac format.
// 
// Parameters:
//   Command - String - a command whose parameters must be filled.
//  Parameter<n> - Arbitrary.
//
Procedure SubstituteParametersToCommand(Command, Val Parameter1, 
	Val Parameter2 = Undefined, 
	Val Parameter3 = Undefined, 
	Val Parameter4 = Undefined)
	
	Command = StringFunctionsClientServer.SubstituteParametersToString(Command, 
		CastValue(Parameter1),
		CastValue(Parameter2),
		CastValue(Parameter3),
		CastValue(Parameter4));
	
EndProcedure

// Adds rac parameters to the command.
//
// Parameters:
//   Command - String - a rac command, to which parameters will be added.
//   Dictionary - Structure - a dictionary.
//   PropertiesValues - Structure - the object values in API notation.
//   SupportedProperties - Map - if specified, the parameters that are in this collection are added.
//
Procedure AddCommandParametersByDictionary(Command, Dictionary, PropertyValues, SupportedProperties = Undefined)
	
	For Each DictionaryFragment In Dictionary Do
		ParameterName = DictionaryFragment.Value;	
		If SupportedProperties <> Undefined AND SupportedProperties.Get(ParameterName) = Undefined Then
			Continue;
		EndIf;
		
		If PropertyValues.Property(DictionaryFragment.Key) Then
			
			ParameterValue = CastValue(PropertyValues[DictionaryFragment.Key]);
			Command = Command + " --" + ParameterName + "=" + ParameterValue;
			
		EndIf;
		
	EndDo;
	
EndProcedure

// Returns the supported rac objects properties.
//
// Parameters:
//   ReceivingParameters - Structure - a structure with the following keys:
//     * ObjectType - String - "profile" or "infobase".
//     * ClusterAdministrationParameters - Structure - the structure describing parameters for 
//                  connecting the server cluster. For details, see  ClusterAdministrationClientServer.ClusterAdministrationParameters().
//
// Returns:
//   Structure, Map - an object with available properties.
//
Function SupportedObjectProperties(ReceivingParameters)
	
	If ReceivingParameters.ObjectType = "profile" Then
		Return ProfileSupportedProperties(ReceivingParameters.ClusterAdministrationParameters);
	ElsIf ReceivingParameters.ObjectType = "infobase" Then
		Return InfobaseSupportedProperties(ReceivingParameters.ClusterAdministrationParameters, 
			ReceivingParameters.IBAdministrationParameters);
	EndIf;
	
EndFunction

// Returns properties supported by the security profile and access lists.
//
// Parameters:
//   ClusterAdministrationParameters - Structure - the structure that describes parameters for 
//                  connecting the server cluster. For details, see ClusterAdministration. ClusterAdministrationParameters().
//
// Returns:
//   Structure - a structure with the keys:
//     * profile - Map - where the key is a supported property, and the value is True.
//     * profile_directory - Map - where the key is a supported property, and the value is
//                                          - True.
//     * profile_com - Map - where the key is a supported property, and the value is True.
//     * profile_addin - Map - where the key is a supported property, and the value is True.
//     * profile_module - Map - where the key is a supported property, and the value is True.
//     * profile_app - Map - where the key is a supported property, and the value is True.
//     * profile_inet - Map - where the key is a supported property, and the value is True.
//
Function ProfileSupportedProperties(ClusterAdministrationParameters)
	
	ProfileName = "ServiceProfile-81e39185-997c-4ae3-81f7-e7582cfdfa03";
	ProfileDetails = NStr("ru = 'Служебный профиль для проверки поддерживаемых свойств.'; en = 'Service profile for testing supported properties.'; pl = 'Profil serwisowy do sprawdzania obsługiwanych właściwości.';de = 'Serviceprofil, um die unterstützten Eigenschaften zu überprüfen.';ro = 'Profilul de serviciu pentru verificarea proprietăților susținute.';tr = 'Desteklenen özelliklerin kontrolü için kullanılan hizmet profili.'; es_ES = 'Perfil de servicio para comprobar propiedades admitidas.'");
	
	ClusterParameters = ClusterParameters(ClusterAdministrationParameters);
	
	Command = "profile update --name=%1 --descr=%2 " + ClusterParameters;
	SubstituteParametersToCommand(Command, ProfileName, ProfileDetails);
	RunCommand(Command, ClusterAdministrationParameters);
	
	Command = "profile acl --name=%1 directory update --alias=%2 " + ClusterParameters;
	SubstituteParametersToCommand(Command, ProfileName, "Directory");
	RunCommand(Command, ClusterAdministrationParameters);
	
	Command = "profile acl --name=%1 com update --name=%2 " + ClusterParameters;
	SubstituteParametersToCommand(Command, ProfileName, "ComObject");
	RunCommand(Command, ClusterAdministrationParameters);
	
	Command = "profile acl --name=%1 addin update --name=%2 " + ClusterParameters;
	SubstituteParametersToCommand(Command, ProfileName, "AddIn");
	RunCommand(Command, ClusterAdministrationParameters);
	
	Command = "profile acl --name=%1 module update --name=%2 " + ClusterParameters;
	SubstituteParametersToCommand(Command, ProfileName, "ExternalModule");
	RunCommand(Command, ClusterAdministrationParameters);
	
	Command = "profile acl --name=%1 app update --name=%2 " + ClusterParameters;
	SubstituteParametersToCommand(Command, ProfileName, "Application");
	RunCommand(Command, ClusterAdministrationParameters);
	
	Command = "profile acl --name=%1 inet update --name=%2 " + ClusterParameters;
	SubstituteParametersToCommand(Command, ProfileName, "InternetResources");
	RunCommand(Command, ClusterAdministrationParameters);
	
	Properties = New Structure;
	
	Command = "profile list " + ClusterParameters;
	Properties.Insert("profile", SupportedProperties(Command, ClusterAdministrationParameters, ProfilePropertyTypes()));
	
	Command = "profile acl --name=%1 directory list " + ClusterParameters;
	SubstituteParametersToCommand(Command, ProfileName);
	Properties.Insert("profile_directory", SupportedProperties(Command, ClusterAdministrationParameters, VirtualDirectoryPropertyTypes()));
	
	Command = "profile acl --name=%1 com list " + ClusterParameters;
	SubstituteParametersToCommand(Command, ProfileName);
	Properties.Insert("profile_com", SupportedProperties(Command, ClusterAdministrationParameters, COMClassPropertyTypes()));
		
	Command = "profile acl --name=%1 addin list " + ClusterParameters;
	SubstituteParametersToCommand(Command, ProfileName);
	Properties.Insert("profile_addin", SupportedProperties(Command, ClusterAdministrationParameters, AddInPropertyTypes()));
	
	Command = "profile acl --name=%1 module list " + ClusterParameters;
	SubstituteParametersToCommand(Command, ProfileName);
	Properties.Insert("profile_module", SupportedProperties(Command, ClusterAdministrationParameters, ExternalModulePropertyType()));
	
	Command = "profile acl --name=%1 app list " + ClusterParameters;
	SubstituteParametersToCommand(Command, ProfileName);
	Properties.Insert("profile_app", SupportedProperties(Command, ClusterAdministrationParameters, OSApplicationPropertyTypes()));
		
	Command = "profile acl --name=%1 inet list " + ClusterParameters;
	SubstituteParametersToCommand(Command, ProfileName);
	Properties.Insert("profile_inet", SupportedProperties(Command, ClusterAdministrationParameters, InternetResourcePropertyTypes()));
		
	Command = "profile remove --name=%1 " + ClusterParameters;
	SubstituteParametersToCommand(Command, ProfileName);
	RunCommand(Command, ClusterAdministrationParameters);

	Return Properties;
	
EndFunction

// Returns properties supported by the security profile and access lists.
//
// Parameters:
//   ClusterAdministrationParameters - Structure - the structure that describes parameters for 
//                  connecting the server cluster. For details, see ClusterAdministration. ClusterAdministrationParameters().
//
// Returns:
//   Map - where the key is a supported property, and the value is True.
//
Function InfobaseSupportedProperties(ClusterAdministrationParameters, IBAdministrationParameters)
	
	InfobaseProperties = InfobaseProperties(ClusterAdministrationParameters, IBAdministrationParameters, Undefined);
	
	Properties = New Map;
	
	For Each KeyAndValue In InfobaseProperties Do
		Properties.Insert(KeyAndValue.Key, True);
	EndDo;
	
	Return Properties;
	
EndFunction

#EndRegion