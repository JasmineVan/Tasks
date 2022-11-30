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
	
	COMConnector = COMConnector();
	
	ServerAgentConnection = ServerAgentConnection(
		COMConnector,
		ClusterAdministrationParameters.ServerAgentAddress,
		ClusterAdministrationParameters.ServerAgentPort);
	
	Cluster = GetCluster(
		ServerAgentConnection,
		ClusterAdministrationParameters.ClusterPort,
		ClusterAdministrationParameters.ClusterAdministratorName,
		ClusterAdministrationParameters.ClusterAdministratorPassword);
	
	WorkingProcessConnection = WorkingProcessConnection(COMConnector, ServerAgentConnection, Cluster);
	
	Infobase = GetIB(
		WorkingProcessConnection,
		Cluster,
		IBAdministrationParameters.NameInCluster,
		IBAdministrationParameters.InfobaseAdministratorName,
		IBAdministrationParameters.InfobaseAdministratorPassword);
	
	Result = COMAdministratorObjectModelObjectDetails(
		Infobase,
		SessionAndScheduledJobLockPropertiesDictionary());
	
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
	
	LockToSet = New Structure();
	For Each KeyAndValue In SessionAndJobLockProperties Do
		LockToSet.Insert(KeyAndValue.Key, KeyAndValue.Value);
	EndDo;
	
	If Not ValueIsFilled(LockToSet.DateFrom) Then
		LockToSet.DateFrom = ClusterAdministration.EmptyDate();
	EndIf;
	
	If Not ValueIsFilled(LockToSet.DateTo) Then
		LockToSet.DateTo = ClusterAdministration.EmptyDate();
	EndIf;
	
	COMConnector = COMConnector();
	
	ServerAgentConnection = ServerAgentConnection(
		COMConnector,
		ClusterAdministrationParameters.ServerAgentAddress,
		ClusterAdministrationParameters.ServerAgentPort);
	
	Cluster = GetCluster(
		ServerAgentConnection,
		ClusterAdministrationParameters.ClusterPort,
		ClusterAdministrationParameters.ClusterAdministratorName,
		ClusterAdministrationParameters.ClusterAdministratorPassword);
	
	WorkingProcessConnection = WorkingProcessConnection(COMConnector, ServerAgentConnection, Cluster);
	
	Infobase = GetIB(
		WorkingProcessConnection,
		Cluster,
		IBAdministrationParameters.NameInCluster,
		IBAdministrationParameters.InfobaseAdministratorName,
		IBAdministrationParameters.InfobaseAdministratorPassword);
	
	FillCOMAdministratorObjectModelObjectPropertiesByDeclaration(
		Infobase,
		LockToSet,
		SessionAndScheduledJobLockPropertiesDictionary());
	
	WorkingProcessConnection.UpdateInfoBase(Infobase);
	
EndProcedure

// Checks whether administration parameters are filled correctly.
//
// Parameters:
//   ClusterAdministrationParameters - Structure - the structure that describes parameters for 
//                  connecting the server cluster. For details, see ClusterAdministration. ClusterAdministrationParameters().
//   IBAdministrationParameters - Structure - the structure describing infobase connection 
//                  parameters. For details, see ClusterAdministration. ClusterInfobaseAdministrationParameters().
//   CheckClusterAdministrationParameters - Boolean - indicates whether cluster administration 
//                  parameters check is required.
//  CheckClusterAdministrationParameters - Boolean - Indicates whether cluster administration 
//                  parameters check is required.
//
Procedure CheckAdministrationParameters(Val ClusterAdministrationParameters, Val IBAdministrationParameters = Undefined,
	CheckInfobaseAdministrationParameters = True,
	CheckClusterAdministrationParameters = True) Export
	
	If CheckClusterAdministrationParameters OR CheckInfobaseAdministrationParameters Then
		
		Try
			COMConnector = COMConnector();
			
			ServerAgentConnection = ServerAgentConnection(
				COMConnector,
				ClusterAdministrationParameters.ServerAgentAddress,
				ClusterAdministrationParameters.ServerAgentPort);
			
			Cluster = GetCluster(
				ServerAgentConnection,
				ClusterAdministrationParameters.ClusterPort,
				ClusterAdministrationParameters.ClusterAdministratorName,
				ClusterAdministrationParameters.ClusterAdministratorPassword);
		Except
			If Common.IsWindowsServer() Then 
				ExceptionText = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("ru = '%1
					           |
					           |Если компонента ""comcntr"" не зарегистрирована или ее версия не совпадает с требуемой,
					           |следует зарегистрировать ее на компьютере %2 выполнив команду cmd с повышением привилегий UAC
					           |для учетной записи ОС Windows, от имени которой выполняется 1С:Предприятие.
					           |
					           |Например:
					           |regsvr32.exe ""%3""'; 
					           |en = '%1
					           |
					           |If comcntr is not registered or its version is invalid,
					           |register it on %2. Ensure that you run the cmd command with elevated UAC privileges
					           |for the Windows user signed in to 1C:Enterprise.
					           |
					           |Example:
					           |regsvr32.exe ""%3"".'; 
					           |pl = '%1
					           |
					           |Jeśli komponentu ""comcntr"" nie jest zarejestrowany lub jego wersja nie jest zgodna z wymaganą,
					           |powinien zostać zarejestrowany na komputerze %2 uruchamiając polecenie cmd z podniesieniem uprawnień UAC
					           |dla konta systemu operacyjnego Windows, w imieniu którego wykonywane jest 1C:Enterprise.
					           |
					           |Na przykład:
					           |regsvr32.exe ""%3""';
					           |de = '%1
					           |
					           |Wenn die Komponente ""comcntr"" nicht registriert ist oder ihre Version nicht mit der erforderlichen übereinstimmt,
					           | sollten Sie sie auf Ihrem Computer registrieren%2, indem Sie den Befehl cmd mit der Berechtigungserweiterung UAC
					           |für das Windows-Betriebssystemkonto ausführen, auf dessen Namen 1C:Enterprise läuft.
					           |
					           |Zum Beispiel:
					           |regsvr32.exe ""%3""';
					           |ro = '%1
					           |
					           |Dacă componenta ""comcntr"" nu este înregistrată sau versiunea ei nu coincide cu cea dorită,
					           |atunci trebuie s-o înregistrați pe computer %2 cu executarea comenzii cmd și cu ridicarea privilegiilor UAC
					           |pentru accountul SO Windows, din numele căruia se execută 1C:Enterprise.
					           |
					           |De exemplu:
					           |regsvr32.exe ""%3""';
					           |tr = '%1
					           |
					           |""Comcntr"" bileşeni kayıtlı değilse veya sürümü gerekli olanla aynı değilse
					           |, 1C:İşletme''nin %3yerine getirildiği Windows hesabı için UAC %2ayrıcalıklarını artıran cmd komutunu çalıştırarak bilgisayara kaydetmeniz gerekir.
					           |
					           |Örneğin:
					           |regsvr32.exe ""
					           |'; 
					           |es_ES = '%1
					           |
					           |Si el componente ""comcntr"" no se ha registrado o su versión no coincide con la requerida,
					           |hay que registrarla en el ordenador %2 al realizar el comando cmd aumentando las privilegias UAC
					           |para la cuenta de OS Windows de cuyo nombre se ejecuta 1C:Enterprise.
					           |
					           |Por ejemplo:
					           |regsvr32.exe ""%3""'"),
					BriefErrorDescription(ErrorInfo()),
					ComputerName(),
					BinDir() + "comcntr.dll");
			Else 
				ExceptionText = BriefErrorDescription(ErrorInfo());
			EndIf;
			
			Raise ExceptionText
			
		EndTry;
		
	EndIf;
	
	If CheckInfobaseAdministrationParameters Then
		
		WorkingProcessConnection = WorkingProcessConnection(COMConnector, ServerAgentConnection, Cluster);
		
		GetIB(WorkingProcessConnection,
			Cluster,
			IBAdministrationParameters.NameInCluster,
			IBAdministrationParameters.InfobaseAdministratorName,
			IBAdministrationParameters.InfobaseAdministratorPassword);
		
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
// Returns:
//   Boolean - the state of lock.
//
Function InfobaseScheduledJobLock(Val ClusterAdministrationParameters, Val IBAdministrationParameters) Export
	
	COMConnector = COMConnector();
	
	ServerAgentConnection = ServerAgentConnection(
		COMConnector,
		ClusterAdministrationParameters.ServerAgentAddress,
		ClusterAdministrationParameters.ServerAgentPort);
	
	Cluster = GetCluster(
		ServerAgentConnection,
		ClusterAdministrationParameters.ClusterPort,
		ClusterAdministrationParameters.ClusterAdministratorName,
		ClusterAdministrationParameters.ClusterAdministratorPassword);
	
	WorkingProcessConnection = WorkingProcessConnection(COMConnector, ServerAgentConnection, Cluster);
	
	Infobase = GetIB(
		WorkingProcessConnection,
		Cluster,
		IBAdministrationParameters.NameInCluster,
		IBAdministrationParameters.InfobaseAdministratorName,
		IBAdministrationParameters.InfobaseAdministratorPassword);
	
	Return Infobase.ScheduledJobsDenied;
	
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
	
	COMConnector = COMConnector();
	
	ServerAgentConnection = ServerAgentConnection(
		COMConnector,
		ClusterAdministrationParameters.ServerAgentAddress,
		ClusterAdministrationParameters.ServerAgentPort);
	
	Cluster = GetCluster(
		ServerAgentConnection,
		ClusterAdministrationParameters.ClusterPort,
		ClusterAdministrationParameters.ClusterAdministratorName,
		ClusterAdministrationParameters.ClusterAdministratorPassword);
	
	WorkingProcessConnection = WorkingProcessConnection(COMConnector, ServerAgentConnection, Cluster);
	
	Infobase = GetIB(
		WorkingProcessConnection,
		Cluster,
		IBAdministrationParameters.NameInCluster,
		IBAdministrationParameters.InfobaseAdministratorName,
		IBAdministrationParameters.InfobaseAdministratorPassword);
	
	Infobase.ScheduledJobsDenied = ScheduledJobLock;
	WorkingProcessConnection.UpdateInfoBase(Infobase);
	
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
//   Array - an array of structures describing session properties. See ClusterAdministration.
//                  SessionProperties(). 
//
Function InfobaseSessions(Val ClusterAdministrationParameters, Val IBAdministrationParameters, Val Filter = Undefined) Export
	
	COMConnector = COMConnector();
	
	ServerAgentConnection = ServerAgentConnection(
		COMConnector,
		ClusterAdministrationParameters.ServerAgentAddress,
		ClusterAdministrationParameters.ServerAgentPort);
	
	Cluster = GetCluster(
		ServerAgentConnection,
		ClusterAdministrationParameters.ClusterPort,
		ClusterAdministrationParameters.ClusterAdministratorName,
		ClusterAdministrationParameters.ClusterAdministratorPassword);
	
	InfobaseDetails = GetIBDetails(
		ServerAgentConnection,
		Cluster,
		IBAdministrationParameters.NameInCluster);
	
	Return GetSessions(ServerAgentConnection, Cluster, InfobaseDetails, Filter, True);
	
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
	
	COMConnector = COMConnector();
	
	ServerAgentConnection = ServerAgentConnection(
		COMConnector,
		ClusterAdministrationParameters.ServerAgentAddress,
		ClusterAdministrationParameters.ServerAgentPort);
	
	Cluster = GetCluster(
		ServerAgentConnection,
		ClusterAdministrationParameters.ClusterPort,
		ClusterAdministrationParameters.ClusterAdministratorName,
		ClusterAdministrationParameters.ClusterAdministratorPassword);
	
	InfobaseDetails = GetIBDetails(
		ServerAgentConnection,
		Cluster,
		IBAdministrationParameters.NameInCluster);
	
	AttemptCount = 3;
	AllSessionsTerminated = False;
	
	For CurrentAttempt = 0 To AttemptCount Do
		
		Sessions = GetSessions(ServerAgentConnection, Cluster, InfobaseDetails, Filter, False);
		
		If Sessions.Count() = 0 Then
			
			AllSessionsTerminated = True;
			Break;
			
		ElsIf CurrentAttempt = AttemptCount Then
			
			Break;
			
		EndIf;
		
		For each Session In Sessions Do
			
			Try
				
				ServerAgentConnection.TerminateSession(Cluster, Session);
				
			Except
				
				// The session might close before TerminateSession is called.
				Continue;
				
			EndTry;
			
		EndDo;
		
	EndDo;
	
	If NOT AllSessionsTerminated Then
	
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
// Returns:
//   Array - an array of structures describing connection properties. See ClusterAdministration.
//                  ConnectionProperties(). 
//
Function InfobaseConnections(Val ClusterAdministrationParameters, Val IBAdministrationParameters, Val Filter = Undefined) Export
	
	COMConnector = COMConnector();
	
	ServerAgentConnection = ServerAgentConnection(
		COMConnector,
		ClusterAdministrationParameters.ServerAgentAddress,
		ClusterAdministrationParameters.ServerAgentPort);
	
	Cluster = GetCluster(
		ServerAgentConnection,
		ClusterAdministrationParameters.ClusterPort,
		ClusterAdministrationParameters.ClusterAdministratorName,
		ClusterAdministrationParameters.ClusterAdministratorPassword);
	
	Return GetConnections(
		COMConnector,
		ServerAgentConnection,
		Cluster,
		IBAdministrationParameters,
		Filter,
		True);
	
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
	
	COMConnector = COMConnector();
	
	ServerAgentConnection = ServerAgentConnection(
		COMConnector,
		ClusterAdministrationParameters.ServerAgentAddress,
		ClusterAdministrationParameters.ServerAgentPort);
	
	Cluster = GetCluster(
		ServerAgentConnection,
		ClusterAdministrationParameters.ClusterPort,
		ClusterAdministrationParameters.ClusterAdministratorName,
		ClusterAdministrationParameters.ClusterAdministratorPassword);
		
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
		
		Connections = GetConnections(
			COMConnector,
			ServerAgentConnection,
			Cluster,
			IBAdministrationParameters,
			Filter,
			False);
	
		If Connections.Count() = 0 Then
			
			AllConnectionsTerminated = True;
			Break;
			
		ElsIf CurrentAttempt = AttemptCount Then
			
			Break;
			
		EndIf;
	
		For each Connection In Connections Do
			
			Try
				
				Connection.WorkingProcessConnection.Disconnect(Connection.Connection);
				
			Except
				
				// The connection might terminate before TerminateSession is called.
				Continue;
				
			EndTry;
			
		EndDo;
		
	EndDo;
	
	If NOT AllConnectionsTerminated Then
	
		Raise NStr("ru = 'Не удалось разорвать соединения.'; en = 'Cannot close connections.'; pl = 'Nie udało się przerwać połączenie.';de = 'Die Verbindungen konnten nicht unterbrochen werden.';ro = 'Eșec la întreruperea conexiunii.';tr = 'Bağlantı koparılamadı.'; es_ES = 'No se ha podido desconectar.'");
		
	EndIf;
	
EndProcedure

#EndRegion

#Region SecurityProfiles

// Returns the name of a security profile assigned to the infobase.
//
// Parameters:
//   ClusterAdministrationParameters - Structure - the structure that describes parameters for 
//                  connecting the server cluster. For details, see ClusterAdministration. ClusterAdministrationParameters().
//   IBAdministrationParameters - Structure - the structure describing infobase connection 
//                  parameters. For details, see ClusterAdministration. ClusterInfobaseAdministrationParameters().
//
// Returns:
//   String - name of the security profile set for the infobase. If the infobase is not assigned 
//                  with a security profile, returns an empty string.
//
Function InfobaseSecurityProfile(Val ClusterAdministrationParameters, Val IBAdministrationParameters) Export
	
	COMConnector = COMConnector();
	
	ServerAgentConnection = ServerAgentConnection(
		COMConnector,
		ClusterAdministrationParameters.ServerAgentAddress,
		ClusterAdministrationParameters.ServerAgentPort);
	
	Cluster = GetCluster(
		ServerAgentConnection,
		ClusterAdministrationParameters.ClusterPort,
		ClusterAdministrationParameters.ClusterAdministratorName,
		ClusterAdministrationParameters.ClusterAdministratorPassword);
	
	WorkingProcessConnection = WorkingProcessConnection(COMConnector, ServerAgentConnection, Cluster);
	
	Infobase = GetIB(
		WorkingProcessConnection,
		Cluster,
		IBAdministrationParameters.NameInCluster,
		IBAdministrationParameters.InfobaseAdministratorName,
		IBAdministrationParameters.InfobaseAdministratorPassword);
	
	If ValueIsFilled(Infobase.SecurityProfileName) Then
		Result = Infobase.SecurityProfileName;
	Else
		Result = "";
	EndIf;
	
	Infobase = Undefined;
	WorkingProcessConnection = Undefined;
	Cluster = Undefined;
	ServerAgentConnection = Undefined;
	COMConnector = Undefined;
	
	Return Result;
	
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
	
	COMConnector = COMConnector();
	
	ServerAgentConnection = ServerAgentConnection(
		COMConnector,
		ClusterAdministrationParameters.ServerAgentAddress,
		ClusterAdministrationParameters.ServerAgentPort);
	
	Cluster = GetCluster(
		ServerAgentConnection,
		ClusterAdministrationParameters.ClusterPort,
		ClusterAdministrationParameters.ClusterAdministratorName,
		ClusterAdministrationParameters.ClusterAdministratorPassword);
	
	WorkingProcessConnection = WorkingProcessConnection(COMConnector, ServerAgentConnection, Cluster);
	
	Infobase = GetIB(
		WorkingProcessConnection,
		Cluster,
		IBAdministrationParameters.NameInCluster,
		IBAdministrationParameters.InfobaseAdministratorName,
		IBAdministrationParameters.InfobaseAdministratorPassword);
	
	If ValueIsFilled(Infobase.SafeModeSecurityProfileName) Then
		Result = Infobase.SafeModeSecurityProfileName;
	Else
		Result = "";
	EndIf;
	
	Infobase = Undefined;
	WorkingProcessConnection = Undefined;
	Cluster = Undefined;
	ServerAgentConnection = Undefined;
	COMConnector = Undefined;
	
	Return Result;
	
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
	
	COMConnector = COMConnector();
	
	ServerAgentConnection = ServerAgentConnection(
		COMConnector,
		ClusterAdministrationParameters.ServerAgentAddress,
		ClusterAdministrationParameters.ServerAgentPort);
	
	Cluster = GetCluster(
		ServerAgentConnection,
		ClusterAdministrationParameters.ClusterPort,
		ClusterAdministrationParameters.ClusterAdministratorName,
		ClusterAdministrationParameters.ClusterAdministratorPassword);
	
	WorkingProcessConnection = WorkingProcessConnection(COMConnector, ServerAgentConnection, Cluster);
	
	Infobase = GetIB(
		WorkingProcessConnection,
		Cluster,
		IBAdministrationParameters.NameInCluster,
		IBAdministrationParameters.InfobaseAdministratorName,
		IBAdministrationParameters.InfobaseAdministratorPassword);
	
	Infobase.SecurityProfileName = ProfileName;
	
	WorkingProcessConnection.UpdateInfoBase(Infobase);
	
	Infobase = Undefined;
	WorkingProcessConnection = Undefined;
	Cluster = Undefined;
	ServerAgentConnection = Undefined;
	COMConnector = Undefined
	
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
	
	COMConnector = COMConnector();
	
	ServerAgentConnection = ServerAgentConnection(
		COMConnector,
		ClusterAdministrationParameters.ServerAgentAddress,
		ClusterAdministrationParameters.ServerAgentPort);
	
	Cluster = GetCluster(
		ServerAgentConnection,
		ClusterAdministrationParameters.ClusterPort,
		ClusterAdministrationParameters.ClusterAdministratorName,
		ClusterAdministrationParameters.ClusterAdministratorPassword);
	
	WorkingProcessConnection = WorkingProcessConnection(COMConnector, ServerAgentConnection, Cluster);
	
	Infobase = GetIB(
		WorkingProcessConnection,
		Cluster,
		IBAdministrationParameters.NameInCluster,
		IBAdministrationParameters.InfobaseAdministratorName,
		IBAdministrationParameters.InfobaseAdministratorPassword);
	
	Infobase.SafeModeSecurityProfileName = ProfileName;
	
	WorkingProcessConnection.UpdateInfoBase(Infobase);
	
	Infobase = Undefined;
	WorkingProcessConnection = Undefined;
	Cluster = Undefined;
	ServerAgentConnection = Undefined;
	COMConnector = Undefined
	
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
	
	COMConnector = COMConnector();
	
	ServerAgentConnection = ServerAgentConnection(
		COMConnector,
		ClusterAdministrationParameters.ServerAgentAddress,
		ClusterAdministrationParameters.ServerAgentPort);
	
	Cluster = GetCluster(
		ServerAgentConnection,
		ClusterAdministrationParameters.ClusterPort,
		ClusterAdministrationParameters.ClusterAdministratorName,
		ClusterAdministrationParameters.ClusterAdministratorPassword);
	
	For Each SecurityProfile In ServerAgentConnection.GetSecurityProfiles(Cluster) Do
		
		If SecurityProfile.Name = ProfileName Then
			Return True;
		EndIf;
		
	EndDo;
	
	Return False;
	
EndFunction

// Returns properties of a security profile.
//
// Parameters:
//   ClusterAdministrationParameters - Structure - the structure that describes parameters for 
//                  connecting the server cluster. For details, see ClusterAdministration. ClusterAdministrationParameters().
//  ProfileName - String, a security profile name.
//
// Returns:
//   Structure - structure describing security profile. For details, see
//                  ClusterAdministration.SecurityProfileProperties().
//
Function SecurityProfile(Val ClusterAdministrationParameters, Val ProfileName) Export
	
	COMConnector = COMConnector();
	
	ServerAgentConnection = ServerAgentConnection(
		COMConnector,
		ClusterAdministrationParameters.ServerAgentAddress,
		ClusterAdministrationParameters.ServerAgentPort);
	
	Cluster = GetCluster(
		ServerAgentConnection,
		ClusterAdministrationParameters.ClusterPort,
		ClusterAdministrationParameters.ClusterAdministratorName,
		ClusterAdministrationParameters.ClusterAdministratorPassword);
	
	SecurityProfile = GetSecurityProfile(ServerAgentConnection, Cluster, ProfileName);
	
	Result = COMAdministratorObjectModelObjectDetails(
		SecurityProfile,
		SecurityProfilePropertiesDictionary());
	
	// Virtual directories
	Result.Insert("VirtualDirectories",
		COMAdministratorObjectModelObjectsDetails(
			GetVirtualDirectories(ServerAgentConnection, Cluster, ProfileName),
			VirtualDirectoryPropertiesDictionary()));
	
	// Allowed COM classes.
	Result.Insert("COMClasses",
		COMAdministratorObjectModelObjectsDetails(
			GetCOMClasses(ServerAgentConnection, Cluster, ProfileName),
			COMClassPropertiesDictionary()));
	
	// Add-ins
	Result.Insert("AddIns",
		COMAdministratorObjectModelObjectsDetails(
			GetAddIns(ServerAgentConnection, Cluster, ProfileName),
			AddInPropertiesDictionary()));
	
	// External modules
	Result.Insert("ExternalModules",
		COMAdministratorObjectModelObjectsDetails(
			GetExternalModules(ServerAgentConnection, Cluster, ProfileName),
			ExternalModulePropertiesDictionary()));
	
	// OS applications
	Result.Insert("OSApplications",
		COMAdministratorObjectModelObjectsDetails(
			GetOSApplications(ServerAgentConnection, Cluster, ProfileName),
			OSApplicationPropertiesDictionary()));
	
	// Internet resources
	Result.Insert("InternetResources",
		COMAdministratorObjectModelObjectsDetails(
			GetInternetResources(ServerAgentConnection, Cluster, ProfileName),
			InternetResourcePropertiesDictionary()));
	
	Return Result;
	
EndFunction

// Creates a security profile on the basis of the passed description.
//
// Parameters:
//   ClusterAdministrationParameters - Structure - the structure that describes parameters for 
//                  connecting the server cluster. For details, see ClusterAdministration. ClusterAdministrationParameters().
//   SecurityProfileProperties - Structure - structure that describes the properties of the security 
//                  profile. For the details, see ClusterAdministration.SecurityProfileProperties(). 
//
Procedure CreateSecurityProfile(Val ClusterAdministrationParameters, Val SecurityProfileProperties) Export
	
	COMConnector = COMConnector();
	
	ServerAgentConnection = ServerAgentConnection(
		COMConnector,
		ClusterAdministrationParameters.ServerAgentAddress,
		ClusterAdministrationParameters.ServerAgentPort);
	
	Cluster = GetCluster(
		ServerAgentConnection,
		ClusterAdministrationParameters.ClusterPort,
		ClusterAdministrationParameters.ClusterAdministratorName,
		ClusterAdministrationParameters.ClusterAdministratorPassword);
	
	SecurityProfile = ServerAgentConnection.CreateSecurityProfile();
	ApplySecurityProfilePropertyChanges(ServerAgentConnection, Cluster, SecurityProfile, SecurityProfileProperties);
	
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
	
	COMConnector = COMConnector();
	
	ServerAgentConnection = ServerAgentConnection(
		COMConnector,
		ClusterAdministrationParameters.ServerAgentAddress,
		ClusterAdministrationParameters.ServerAgentPort);
	
	Cluster = GetCluster(
		ServerAgentConnection,
		ClusterAdministrationParameters.ClusterPort,
		ClusterAdministrationParameters.ClusterAdministratorName,
		ClusterAdministrationParameters.ClusterAdministratorPassword);
	
	SecurityProfile = GetSecurityProfile(
		ServerAgentConnection,
		Cluster,
		SecurityProfileProperties.Name);
	
	ApplySecurityProfilePropertyChanges(ServerAgentConnection, Cluster, SecurityProfile, SecurityProfileProperties);
	
EndProcedure

// Deletes a securiy profile.
//
// Parameters:
//   ClusterAdministrationParameters - Structure - the structure that describes parameters for 
//                  connecting the server cluster. For details, see ClusterAdministration. ClusterAdministrationParameters().
//   ProfileName - String - the security profile name.
//
Procedure DeleteSecurityProfile(Val ClusterAdministrationParameters, Val ProfileName) Export
	
	COMConnector = COMConnector();
	
	ServerAgentConnection = ServerAgentConnection(
		COMConnector,
		ClusterAdministrationParameters.ServerAgentAddress,
		ClusterAdministrationParameters.ServerAgentPort);
	
	Cluster = GetCluster(
		ServerAgentConnection,
		ClusterAdministrationParameters.ClusterPort,
		ClusterAdministrationParameters.ClusterAdministratorName,
		ClusterAdministrationParameters.ClusterAdministratorPassword);
	
	GetSecurityProfile(
		ServerAgentConnection,
		Cluster,
		ProfileName);
	
	ServerAgentConnection.UnregSecurityProfile(Cluster, ProfileName);
	
EndProcedure

#EndRegion

#EndRegion

#Region Private

// Creates a V8*.ComConnector COM object.
//
// Returns:
//   COMObject.
//
Function COMConnector()
	
	If SafeMode() <> False Then
		Raise NStr("ru = 'Администрирование кластера невозможно в безопасном режиме'; en = 'Safe mode does not support cluster administration.'; pl = 'Administrowanie klastrem jest niedostępne w trybie awaryjnym';de = 'Die Clusterverwaltung ist im abgesicherten Modus nicht möglich';ro = 'Administrarea cluster-ului este imposibilă în regim securizat';tr = 'Küme güvenli modda yönetilemez'; es_ES = 'Es imposible administrar clúster en el modo seguro'");
	EndIf;
	
	If Common.DataSeparationEnabled() Then
		Raise NStr("ru = 'В модели сервиса недопустимо выполнение прикладной информационной базой функций администрирования кластера'; en = 'SaaS mode does not support cluster administration.'; pl = 'Zastosowana baza informacyjna nie może administrować klastra w SaaS';de = 'Im Servicemodell ist es inakzeptabel, dass die Anwendungsinformationsbasis die Funktionen der Clusterverwaltung übernimmt';ro = 'În modelul serviciului nu se admite executarea de către baza de informații aplicată a funcțiilor de administrare a clusterului';tr = 'Servis modelinde, uygulanan işlev veritabanı, kümeyi yönetemez'; es_ES = 'En el modelo de servicio es imposible ejecutar las funciones de administrar clúster por la base de información aplicada'");
	EndIf;
	
	Return New COMObject(CommonClientServer.COMConnectorName());
	
EndFunction

// Establishes a connection with the server agent.
//
// Parameters:
//   COMConnector - COMObject - V8* ComConnector com object.
//   ServerAgentAddress - String - network address of the server agent.
//   ServerAgentPort - Number - network port of the server agent (usually 1540).
//
// Returns:
//   COMObject - com object that implements IV8AgentConnection interface.
//
Function ServerAgentConnection(COMConnector, Val ServerAgentAddress, Val ServerAgentPort)
	
	AddressAndPort = ServerAgentAddress + ":" + Format(ServerAgentPort, "NG=0");
	Try
		
		ServerAgentConnectionString = "tcp://" + AddressAndPort;
		ServerAgentConnection = COMConnector.ConnectAgent(ServerAgentConnectionString);
		Return ServerAgentConnection;
		
	Except
		Raise;
	EndTry;
	
EndFunction

// Returns a server cluster.
//
// Parameters:
//   ServerAgentConnection - COMObject - com object that implements IV8AgentConnection interface.
//   ClusterPort - Number - network port of the cluster manager (usually 1541).
//   ClusterAdministratorName - String - cluster administrator account name.
//   ClusterAdministratorPassword - String - cluster administrator account password.
//
// Returns:
//   COMObject - com object that implements IClusterInfo interface.
//
Function GetCluster(ServerAgentConnection, Val ClusterPort, Val ClusterAdministratorName, Val ClusterAdministratorPassword)
	
	For Each Cluster In ServerAgentConnection.GetClusters() Do
		If Cluster.MainPort = ClusterPort Then
			Try
				ServerAgentConnection.Authenticate(Cluster, ClusterAdministratorName, ClusterAdministratorPassword);
				Return Cluster;
			Except
				Raise;
			EndTry;
		EndIf;
	EndDo;
	
	Raise StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = 'На рабочем сервере %1 не найден кластер %2'; en = 'Cannot find cluster %2 on working server %1.'; pl = 'Nie znaleziono klastra %2 na serwerze %1 ';de = 'Der Cluster %2 wurde nicht auf dem Server %1 gefunden';ro = 'Clusterul %2 nu a fost găsit pe serverul de lucru %1';tr = 'Küme %2  %1 sunucuda bulunamadı'; es_ES = 'Clúster %2 no encontrado en el servidor %1'"),
		ServerAgentConnection.ConnectionString,
		ClusterPort);
	
EndFunction

// Establishes a connection with the working process.
//
// Parameters:
//   COMConnector - COMObject - V8* ComConnector, com object.
//   ServerAgentConnection - COMObject - com object that implements IV8AgentConnection interface.
//   Cluster - COMObject - com object that implements IClusterInfo interface.
//
// Returns:
//   COMObject - com object that implements IV8ServerConnection interface.
//
Function WorkingProcessConnection(COMConnector, ServerAgentConnection, Cluster)
	
	For Each WorkingProcess In ServerAgentConnection.GetWorkingProcesses(Cluster) Do
		If WorkingProcess.Running AND WorkingProcess.IsEnable  Then
			WorkingProcessConnectionString = WorkingProcess.HostName + ":" + Format(WorkingProcess.MainPort, "NG=");
			Return COMConnector.ConnectWorkingProcess(WorkingProcessConnectionString);
		EndIf;
	EndDo;
	
	Raise StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = 'В кластере серверов %1:%2 не найдено активных рабочих процессов.'; en = 'Cannot find active working processes in server cluster %1:%2.'; pl = 'Nie znaleziono aktywnych procesów w klastrze serwerów %1:%2.';de = 'Aktive Prozesse werden im Server-Cluster nicht gefunden %1: %2.';ro = 'Procesele de lucru active nu au fost găsite în clusterul serverelor %1: %2';tr = 'Sunucu kümesinde etkin işlemler bulunamadı%1:%2.'; es_ES = 'Procesos activos no encontrados en el clúster del servidor %1:%2.'"),
		Cluster.HostName,
		Format(Cluster.MainPort, "NG=0"));
	
EndFunction

// Returns an infobase description.
//
// Parameters:
//   ServerAgentConnection - COMObject - com object that implements IV8AgentConnection interface.
//   Cluster - COMObject - com object that implements IClusterInfo interface.
//   NameInCluster - String - name of an infobase in the cluster server.
//
// Returns:
//   COMObject - com object that implements IInfoBaseShort interface.
//
Function GetIBDetails(ServerAgentConnection, Cluster, Val NameInCluster)
	
	For Each InfobaseDetails In ServerAgentConnection.GetInfoBases(Cluster) Do
		
		If InfobaseDetails.Name = NameInCluster Then
			
			Return InfobaseDetails;
			
		EndIf;
		
	EndDo;
	
	Raise StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = 'В кластере серверов %1:%2 не найдена информационная база ""%3""'; en = 'Cannot find infobase ""%3"" in server cluster %1:%2.'; pl = 'W klasterze serwerów %1:%2 nie odnaleziono bazy informacyjnej ""%3""';de = 'Im Server-Cluster %1:%2 keine Informationsbasis ""%3"" gefunden';ro = 'Baza de date ""%3"" nu a fost găsită în clusterul serverelor %1: %2';tr = 'Sunucu kümesinde ""%3"" veritabanı bulunamadı%1:%2.'; es_ES = 'En el clúster de servidores %1:%2 no se ha encontrado base de información ""%3""'"),
		Cluster.HostName,
		Format(Cluster.MainPort, "NG=0"),
		NameInCluster);
	
EndFunction

// Returns an infobase.
//
// Parameters:
//   WorkingProcessConnection - COMObject - com object that implements IV8ServerConnection interface.
//   Cluster - COMObject - com object that implements IClusterInfo interface.
//   NameInCluster - String - name of an infobase in the cluster server.
//   InfobaseAdministratorName - String - infobase administrator name.
//   InfobaseAdministratorPassword - String - infobase administrator password.
//
// Returns:
//   COMObject - com object that implements IInfoBaseInfo interface.
//
Function GetIB(WorkingProcessConnection, Cluster, Val NameInCluster, Val IBAdministratorName, Val IBAdministratorPassword)
	
	WorkingProcessConnection.AddAuthentication(IBAdministratorName, IBAdministratorPassword);
	
	For Each Infobase In WorkingProcessConnection.GetInfoBases() Do
		
		If Infobase.Name = NameInCluster Then
			
			If Not ValueIsFilled(Infobase.DBMS) Then
				
				Raise StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = 'Неправильные имя и пароль администратора информационной базы %1 в кластере серверов %2:%3 (имя: ""%4"").'; en = 'Incorrect administrator name or password for infobase %1, server cluster %2:%3 (name: ""%4"").'; pl = 'Niepoprawna nazwa lub hasło administratora w klastrze serwerów %2:%3 w bazie informacyjnej %1 (nazwa: ""%4"").';de = 'Der Benutzername oder das Kennwort des Administrators ist im Cluster der Server falsch %2: %3 in der Infobase %1 (Name: ""%4"").';ro = 'Numele de utilizator sau parola de administrator este incorect în grupul de servere %2: %3 din baza de date %1 (nume: ""%4"").';tr = 'Sunucu kümesinin veritabanı yöneticisinin kullanıcı adı veya şifresi yanlıştır %2:%3 veritabanı %1 (isim: ""%4"").'; es_ES = 'El nombre de usuario del administrador o la contraseña es incorrecto en el clúster de servidores %2:%3 en la infobase %1 (nombre: ""%4"").'"),
					NameInCluster,
					Cluster.HostName, 
					Cluster.MainPort,
					IBAdministratorName);
				
			EndIf;
			
			Return Infobase;
			
		EndIf;
		
	EndDo;
	
	Raise StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = 'В кластере серверов %1:%2 не найдена информационная база ""%3""'; en = 'Cannot find infobase ""%3"" in server cluster%1:%2.'; pl = 'W klasterze serwerów %1:%2 nie odnaleziono bazy informacyjnej ""%3""';de = 'Im Server-Cluster %1:%2 keine Informationsbasis ""%3"" gefunden';ro = 'Baza de date ""%3"" nu a fost găsită în clusterul serverelor %1: %2';tr = 'Sunucu kümesinde ""%3"" veritabanı bulunamadı%1:%2.'; es_ES = 'En el clúster de servidores %1:%2 no se ha encontrado base de información ""%3""'"),
		Cluster.HostName,
		Format(Cluster.MainPort, "NG=0"),
		NameInCluster);
	
EndFunction

// Returns infobase sessions.
//
// Parameters:
//   ServerAgentConnection - COMObject - com object that implements IV8AgentConnection interface.
//   Cluster - COMObject - com object that implements IClusterInfo interface.
//   InfoBase - COMObject - com object that implements IInfoBaseInfo interface.
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
//  Details - Boolean - if False, the function returns an array of com objects that implement the 
//                  ISessionInfo interface. If True, returns an array of structures that describe 
//                  the session properties. For more details see ClusterAdministration. SessionProperties().
//
// Returns: Array(COMObject), Array(Structure).
//
Function GetSessions(ServerAgentConnection, Cluster, Infobase, Val Filter = Undefined, Val Details = False)
	
	Sessions = New Array;
	
	Dictionary = SessionPropertiesDictionary();
	SessionLocks = New Map();
	
	For Each Lock In ServerAgentConnection.GetInfoBaseLocks(Cluster, Infobase) Do
		
		If Lock.Session <> Undefined Then
			
			ClusterAdministration.SessionDataFromLock(
				SessionLocks,
				Lock.LockDescr,
				Lock.Session.SessionID,
				Infobase.Name);
			
		EndIf;
		
	EndDo;
	
	For Each Session In ServerAgentConnection.GetInfoBaseSessions(Cluster, Infobase) Do
		
		SessionDetails = COMAdministratorObjectModelObjectDetails(Session, Dictionary);
		SessionDetails.Insert("DBLockMode",
			?(SessionLocks[SessionDetails.Number] <> Undefined, SessionLocks[SessionDetails.Number].DBLockMode, ""));
		SessionDetails.Insert("Separator",
			?(SessionLocks[SessionDetails.Number] <> Undefined, SessionLocks[SessionDetails.Number].Separator, ""));
		
		If ClusterAdministration.CheckFilterConditions(SessionDetails, Filter) Then
			
			If Details Then
				Sessions.Add(SessionDetails);
			Else
				Sessions.Add(Session);
			EndIf;
			
		EndIf;
		
	EndDo;
	
	Return Sessions;
	
EndFunction

// Returns infobase connections.
//
// Parameters:
//   COMConnector - COMObject - V8*.ComConnector com object.
//   ServerAgentConnection - COMObject - com object that implements IV8AgentConnection interface.
//   Cluster - COMObject - com object that implements IClusterInfo interface.
//   NameInCluster - String - name of an infobase in the cluster server.
//   InfobaseAdministratorName - String - infobase administrator name.
//   InfobaseAdministratorPassword - String - infobase administrator password.
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
//  Details - Boolean - if False is passed, the function returns an array of com objects that implement the interface
//                  IConnectionShort interface. If True, returns an array of structures that 
//                  describe the connection properties. For more details see ClusterAdministration. ConnectionsProperties().
//
// Returns:
//   Array - an array of com objects or an array of structures.
//
Function GetConnections(COMConnector, ServerAgentConnection, Cluster, IBAdministrationParameters, Val Filter = Undefined, Val SetOfDetails = False)
	
	NameInCluster = IBAdministrationParameters.NameInCluster;
	IBAdministratorName = IBAdministrationParameters.InfobaseAdministratorName;
	IBAdministratorPassword = IBAdministrationParameters.InfobaseAdministratorPassword;
	
	Connections = New Array();
	Dictionary = ConnectionPropertiesDictionary();
	
	// Working processes that are registered in the cluster.
	For each WorkingProcess In ServerAgentConnection.GetWorkingProcesses(Cluster) Do
		
		If WorkingProcess.Running = 0 Then
			Continue;
		EndIf;
		
		// Administrative connection with the working process.
		WorkingProcessConnectionString = WorkingProcess.HostName + ":" + Format(WorkingProcess.MainPort, "NG=");
		WorkingProcessConnection = COMConnector.ConnectWorkingProcess(WorkingProcessConnectionString);
		
		// Getting infobases (no authentication required).
		For each Infobase In WorkingProcessConnection.GetInfoBases() Do
			
			// This is a required infobase.
			If Infobase.Name = NameInCluster Then
				
				// Authentication is required to get infobase connection data.
				WorkingProcessConnection.AddAuthentication(IBAdministratorName, IBAdministratorPassword);
				
				// Getting infobase connections.
				For each Connection In WorkingProcessConnection.GetInfoBaseConnections(Infobase) Do
					
					ConnectionDetails = COMAdministratorObjectModelObjectDetails(Connection, Dictionary);
					
					// Checking whether the connection passes the filters.
					If ClusterAdministration.CheckFilterConditions(ConnectionDetails, Filter) Then
						
						If SetOfDetails Then
							
							Connections.Add(ConnectionDetails);
							
						Else
							
							Connections.Add(New Structure("WorkingProcessConnection, Connection", WorkingProcessConnection, Connection));
							
						EndIf;
						
					EndIf;
				
				EndDo;
				
			EndIf;
			
		EndDo;
	
	EndDo;
	
	Return Connections;
	
EndFunction

// Returns a security profile.
//
// Parameters:
//   ServerAgentConnection - COMObject - com object that implements IV8AgentConnection interface.
//   Cluster - COMObject - com object that implements IClusterInfo interface.
//   ProfileName - String - the security profile name.
//
// Returns:
//   COMObject - com object that implements ISecurityProfile interface.
//
Function GetSecurityProfile(ServerAgentConnection, Cluster, ProfileName)
	
	For Each SecurityProfile In ServerAgentConnection.GetSecurityProfiles(Cluster) Do
		
		If SecurityProfile.Name = ProfileName Then
			Return SecurityProfile;
		EndIf;
		
	EndDo;
	
	Raise StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = 'В кластере серверов %1:%2 не найден профиль безопасности ""%3""'; en = 'Cannot find security profile ""%3"" in server cluster %1:%2.'; pl = 'W klasterze serwerów %1:%2 nie odnaleziono profilu bezpieczeństwa ""%3""';de = 'Im Server-Cluster %1:%2 kein Sicherheitsprofil ""%3"" gefunden';ro = 'Profilul de securitate ""%3"" nu a fost găsit în clusterul serverelor %1: %2';tr = 'Güvenlik profili %2 %1 sunucu kümesinde bulunamadı:%3'; es_ES = 'En el clúster de servidores %1:%2 no se ha encontrado perfil de seguridad ""%3""'"),
		Cluster.HostName,
		Format(Cluster.MainPort, "NG=0"),
		ProfileName);
	
EndFunction

// Returns virtual directories allowed in the security profile.
//
// Parameters:
//   ServerAgentConnection - COMObject - com object that implements IV8AgentConnection interface.
//   Cluster - COMObject - com object that implements IClusterInfo interface.
//   ProfileName - String - the security profile name.
//
// Returns:
//   Array - an array of com objects that implement ISecurityProfileVirtualDirectory interface.
//
Function GetVirtualDirectories(ServerAgentConnection, Cluster, ProfileName)
	
	VirtualDirectories = New Array();
	
	For Each VirtualDirectory In ServerAgentConnection.GetSecurityProfileVirtualDirectories(Cluster, ProfileName) Do
		
		VirtualDirectories.Add(VirtualDirectory);
		
	EndDo;
	
	Return VirtualDirectories;
	
EndFunction

// Returns COM classes allowed in a security profile.
//
// Parameters:
//   ServerAgentConnection - COMObject - com object that implements IV8AgentConnection interface.
//   Cluster - COMObject - com object that implements IClusterInfo interface.
//   ProfileName - String - the security profile name.
//
// Returns:
//   Array - an array of com objects that implement ISecurityProfileCOMClass interface.
//
Function GetCOMClasses(ServerAgentConnection, Cluster, ProfileName)
	
	COMClasses = New Array();
	
	For Each COMClass In ServerAgentConnection.GetSecurityProfileCOMClasses(Cluster, ProfileName) Do
		
		COMClasses.Add(COMClass);
		
	EndDo;
	
	Return COMClasses;
	
EndFunction

// Returns add-ins allowed in the security profile.
//
// Parameters:
//   ServerAgentConnection - COMObject - com object that implements IV8AgentConnection interface.
//   Cluster - COMObject - com object that implements IClusterInfo interface.
//   ProfileName - String - the security profile name.
//
// Returns:
//   Array - an array of com objects that implement ISecurityProfileAddIn interface.
//
Function GetAddIns(ServerAgentConnection, Cluster, ProfileName)
	
	AddIns = New Array();
	
	For Each AddIn In ServerAgentConnection.GetSecurityProfileAddIns(Cluster, ProfileName) Do
		
		AddIns.Add(AddIn);
		
	EndDo;
	
	Return AddIns;
	
EndFunction

// Returns external modules allowed in the security profile.
//
// Parameters:
//   ServerAgentConnection - COMObject - com object that implements IV8AgentConnection interface.
//   Cluster - COMObject - com object that implements IClusterInfo interface.
//   ProfileName - String - the security profile name.
//
// Returns:
//   Array - an array of com objects that implement ISecurityProfileExternalModule interface.
//
Function GetExternalModules(ServerAgentConnection, Cluster, ProfileName)
	
	ExternalModules = New Array();
	
	For Each ExternalModule In ServerAgentConnection.GetSecurityProfileUnSafeExternalModules(Cluster, ProfileName) Do
		
		ExternalModules.Add(ExternalModule);
		
	EndDo;
	
	Return ExternalModules;
	
EndFunction

// Returns OS applications allowed in the security profile.
//
// Parameters:
//   ServerAgentConnection - COMObject - com object that implements IV8AgentConnection interface.
//   Cluster - COMObject - com object that implements IClusterInfo interface.
//   ProfileName - String - the security profile name.
//
// Returns:
//   Array - an array of com objects that implement ISecurityProfileApplication interface.
//
Function GetOSApplications(ServerAgentConnection, Cluster, ProfileName)
	
	OSApplications = New Array();
	
	For Each OSApplication In ServerAgentConnection.GetSecurityProfileApplications(Cluster, ProfileName) Do
		
		OSApplications.Add(OSApplication);
		
	EndDo;
	
	Return OSApplications;
	
EndFunction

// Returns OS applications allowed in the security profile.
//
// Parameters:
//   ServerAgentConnection - COMObject - com object that implements IV8AgentConnection interface.
//   Cluster - COMObject - com object that implements IClusterInfo interface.
//   ProfileName - String - the security profile name.
//
// Returns:
//   Array - an array of com objects that implement ISecurityProfileInternetResource interface.
//
Function GetInternetResources(ServerAgentConnection, Cluster, ProfileName)
	
	InternetResources = New Array();
	
	For Each InternetResource In ServerAgentConnection.GetSecurityProfileInternetResources(Cluster, ProfileName) Do
		
		InternetResources.Add(InternetResource);
		
	EndDo;
	
	Return InternetResources;
	
EndFunction

// Overwrites the security profile properties using the passed data.
//
// Parameters:
//   ServerAgentConnection - COMObject - com object that implements IV8AgentConnection interface.
//   Cluster - COMObject - com object that implements IClusterInfo interface.
//   SecurityProfile - COMObject - com object that implements ISecurityProfile interface.
//   SecurityProfileProperties - Structure - structure describing security profile. For details, see 
//                  ClusterAdministration.SecurityProfileProperties(). 
//
Procedure ApplySecurityProfilePropertyChanges(ServerAgentConnection, Cluster, SecurityProfile, SecurityProfileProperties)
	
	FillCOMAdministratorObjectModelObjectPropertiesByDeclaration(
		SecurityProfile,
		SecurityProfileProperties,
		SecurityProfilePropertiesDictionary());
	
	ProfileName = SecurityProfileProperties.Name;
	
	ServerAgentConnection.RegSecurityProfile(Cluster, SecurityProfile);
	
	// Virtual directories
	VirtualDirectoriesToDelete = GetVirtualDirectories(ServerAgentConnection, Cluster, ProfileName);
	For Each VirtualDirectoryToDelete In VirtualDirectoriesToDelete Do
		ServerAgentConnection.UnregSecurityProfileVirtualDirectory(
			Cluster,
			ProfileName,
			VirtualDirectoryToDelete.Alias);
	EndDo;
	VirtualDirectoriesToCreate = SecurityProfileProperties.VirtualDirectories;
	For Each VirtualDirectoryToCreate In VirtualDirectoriesToCreate Do
		VirtualDirectory = ServerAgentConnection.CreateSecurityProfileVirtualDirectory();
		FillCOMAdministratorObjectModelObjectPropertiesByDeclaration(
			VirtualDirectory,
			VirtualDirectoryToCreate,
			VirtualDirectoryPropertiesDictionary());
		ServerAgentConnection.RegSecurityProfileVirtualDirectory(Cluster, ProfileName, VirtualDirectory);
	EndDo;
	
	// Allowed COM classes.
	COMClassesToDelete = GetCOMClasses(ServerAgentConnection, Cluster, ProfileName);
	For Each COMClassToDelete In COMClassesToDelete Do
		ServerAgentConnection.UnregSecurityProfileCOMClass(
			Cluster,
			ProfileName,
			COMClassToDelete.Name);
	EndDo;
	COMClassesToCreate = SecurityProfileProperties.COMClasses;
	For Each COMClassToCreate In COMClassesToCreate Do
		COMClass = ServerAgentConnection.CreateSecurityProfileCOMClass();
		FillCOMAdministratorObjectModelObjectPropertiesByDeclaration(
			COMClass,
			COMClassToCreate,
			COMClassPropertiesDictionary());
		ServerAgentConnection.RegSecurityProfileCOMClass(Cluster, ProfileName, COMClass);
	EndDo;
	
	// Add-ins
	AddInsToDelete = GetAddIns(ServerAgentConnection, Cluster, ProfileName);
	For Each AddInToDelete In AddInsToDelete Do
		ServerAgentConnection.UnregSecurityProfileAddIn(
			Cluster,
			ProfileName,
			AddInToDelete.Name);
	EndDo;
	AddInsToCreate = SecurityProfileProperties.AddIns;
	For Each AddInToCreate In AddInsToCreate Do
		AddIn = ServerAgentConnection.CreateSecurityProfileAddIn();
		FillCOMAdministratorObjectModelObjectPropertiesByDeclaration(
			AddIn,
			AddInToCreate,
			AddInPropertiesDictionary());
		ServerAgentConnection.RegSecurityProfileAddIn(Cluster, ProfileName, AddIn);
	EndDo;
	
	// External modules
	ExternalModulesToDelete = GetExternalModules(ServerAgentConnection, Cluster, ProfileName);
	For Each ModuleExternalToDelete In ExternalModulesToDelete Do
		ServerAgentConnection.UnregSecurityProfileUnSafeExternalModule(
			Cluster,
			ProfileName,
			ModuleExternalToDelete.Name);
	EndDo;
	ExternalModulesToCreate = SecurityProfileProperties.ExternalModules;
	For Each ExternalModuleToCreate In ExternalModulesToCreate Do
		ExternalModule = ServerAgentConnection.CreateSecurityProfileUnSafeExternalModule();
		FillCOMAdministratorObjectModelObjectPropertiesByDeclaration(
			ExternalModule,
			ExternalModuleToCreate,
			ExternalModulePropertiesDictionary());
		ServerAgentConnection.RegSecurityProfileUnSafeExternalModule(Cluster, ProfileName, ExternalModule);
	EndDo;
	
	// OS applications
	OSApplicationsToDelete = GetOSApplications(ServerAgentConnection, Cluster, ProfileName);
	For Each OSApplicationToDelete In OSApplicationsToDelete Do
		ServerAgentConnection.UnregSecurityProfileApplication(
			Cluster,
			ProfileName,
			OSApplicationToDelete.Name);
	EndDo;
	OSApplicationsToCreate = SecurityProfileProperties.OSApplications;
	For Each OSApplicationToCreate In OSApplicationsToCreate Do
		OSApplication = ServerAgentConnection.CreateSecurityProfileApplication();
		FillCOMAdministratorObjectModelObjectPropertiesByDeclaration(
			OSApplication,
			OSApplicationToCreate,
			OSApplicationPropertiesDictionary());
		ServerAgentConnection.RegSecurityProfileApplication(Cluster, ProfileName, OSApplication);
	EndDo;
	
	// Internet resources
	InternetResourcesToDelete = GetInternetResources(ServerAgentConnection, Cluster, ProfileName);
	For Each InternetResourceToDelete In InternetResourcesToDelete Do
		ServerAgentConnection.UnregSecurityProfileInternetResource(
			Cluster,
			ProfileName,
			InternetResourceToDelete.Name);
	EndDo;
	InternetResourcesToCreate = SecurityProfileProperties.InternetResources;
	For Each InternetResourceToCreate In InternetResourcesToCreate Do
		InternetResource = ServerAgentConnection.CreateSecurityProfileInternetResource();
		FillCOMAdministratorObjectModelObjectPropertiesByDeclaration(
			InternetResource,
			InternetResourceToCreate,
			InternetResourcePropertiesDictionary());
		ServerAgentConnection.RegSecurityProfileInternetResource(Cluster, ProfileName, InternetResource);
	EndDo;
	
EndProcedure

// Generates a description for an object in COM administrator object model.
//
// Parameters:
//   Object - COMObject - com object for which the details are formed.
//   Dictionary - Map - containing the object property map where:
//     * Key - Property name in description,
//     * Value - Object property name.
//
// Returns:
//   Structure - details of the COM administrator object model object by the passed dictionary.
//
Function COMAdministratorObjectModelObjectDetails(Val Object, Val Dictionary)
	
	ObjectProperties = New Structure;
	For Each DictionaryFragment In Dictionary Do
		If TypeOf(DictionaryFragment.Value) = Type("String") Then
			ObjectProperties.Insert(DictionaryFragment.Value);
		ElsIf TypeOf(DictionaryFragment.Value) = Type("FixedStructure") Then
			ObjectProperties.Insert(DictionaryFragment.Value.Key);
		EndIf;
	EndDo;
	FillPropertyValues(ObjectProperties, Object);
	
	Details = New Structure();
	For Each DictionaryFragment In Dictionary Do
		If TypeOf(DictionaryFragment.Value) = Type("String") Then
			Details.Insert(DictionaryFragment.Key, ObjectProperties[DictionaryFragment.Value]);
		ElsIf TypeOf(DictionaryFragment.Value) = Type("FixedStructure") Then
			SubordinateObject = ObjectProperties[DictionaryFragment.Value.Key];
			If SubordinateObject = Undefined Then
				Details.Insert(DictionaryFragment.Key, Undefined);
			Else
				Property = COMAdministratorObjectModelObjectDetails(SubordinateObject, DictionaryFragment.Value.Dictionary);
				Details.Insert(DictionaryFragment.Key, Property);
			EndIf;
		EndIf;
	EndDo;
	
	Return Details;
	
EndFunction

// Generates descriptions of COM administrator object model objects.
//
// Parameters:
//   Objects - Array - com objects array.
//   Dictionary - Map - containing the object property map where:
//     * Key - Property name in description,
//     * Value - Object property name.
//
// Returns: Array of Structure - description of COM administrator object model objects by the passed 
//  dictionary.
//
Function COMAdministratorObjectModelObjectsDetails(Val Objects, Val Dictionary)
	
	SetOfDetails = New Array();
	
	For Each Object In Objects Do
		SetOfDetails.Add(COMAdministratorObjectModelObjectDetails(Object, Dictionary));
	EndDo;
	
	Return SetOfDetails;
	
EndFunction

// Fills properties of the COM administrator object model object by the properties from the passed 
//  description.
//
// Parameters:
//   Object - COMObject - com object whose properties are filled in.
//   Details - Structure - details used to fill object properties.
//   Dictionary - Map - containing the object property map where:
//     * Key - Property name in description,
//     * Value - Object property name.
//
Procedure FillCOMAdministratorObjectModelObjectPropertiesByDeclaration(Object, Val Details, Val Dictionary)
	
	ObjectProperties = New Structure;
	For Each DictionaryFragment In Dictionary Do
		If TypeOf(DictionaryFragment.Value) = Type("String") Then
			If Details.Property(DictionaryFragment.Key) Then
				ObjectProperties.Insert(DictionaryFragment.Value, Details[DictionaryFragment.Key]);
			EndIf;
		EndIf;
	EndDo;
	
	FillPropertyValues(Object, ObjectProperties);
	
EndProcedure

// Returns a map of the infobase property names (that describe states of session lock and scheduled 
//  jobs for structures used in the API) and COM administrator object model objects.
//  
//
// Returns:
//   FixedStructure - fixed structure that:
//     * Key - String - the name of an API property (see
//                  ClusterAdministration.SessionAndScheduleJobLockProperties()).
//     * Value - String - the name of an object property.
//
Function SessionAndScheduledJobLockPropertiesDictionary()
	
	Result = ClusterAdministration.SessionAndScheduleJobLockProperties();
	
	Result.SessionsLock = "SessionsDenied";
	Result.DateFrom = "DeniedFrom";
	Result.DateTo = "DeniedTo";
	Result.Message = "DeniedMessage";
	Result.KeyCode = "PermissionCode";
	Result.LockParameter = "DeniedParameter";
	Result.ScheduledJobLock = "ScheduledJobsDenied";
	
	Return New FixedStructure(Result);
	
EndFunction

// Returns a map of the infobase session property names used in the API and COM administrator object 
//  model objects.
//
// Returns:
//   FixedStructure - fixed structure that:
//     * Key - String - the name of an API property (see ClusterAdministration.SessionProperties()),
//     * Value - String - the name of an object property.
//
Function SessionPropertiesDictionary()
	
	License = New Structure;
	License.Insert("Key", "License");
	License.Insert("Dictionary", LicensePropertiesDictionary());
	
	ConnectionDetails = New Structure;
	ConnectionDetails.Insert("Key", "Connection");
	ConnectionDetails.Insert("Dictionary", ConnectionDetailsPropertiesDictionary());
	
	WorkingProcess = New Structure;
	WorkingProcess.Insert("Key", "Process");
	WorkingProcess.Insert("Dictionary", WorkingProcessPropertiesDictionary());
	
	Result = ClusterAdministration.SessionProperties();
	
	Result.Number = "SessionID";
	Result.UserName = "UserName";
	Result.ClientComputerName = "Host";
	Result.ClientApplicationID = "AppID";
	Result.LanguageID = "Locale";
	Result.SessionCreationTime = "StartedAt";
	Result.LatestSessionActivityTime = "LastActiveAt";
	Result.DBMSLock = "blockedByDBMS";
	Result.Lock = "blockedByLS";
	Result.Passed = "bytesAll";
	Result.PassedIn5Minutes = "bytesLast5Min";
	Result.ServerCalls = "callsAll";
	Result.ServerCallsIn5Minutes = "callsLast5Min";
	Result.ServerCallDurations = "durationAll";
	Result.CurrentServerCallDuration = "durationCurrent";
	Result.ServerCallDurationsIn5Minutes = "durationLast5Min";
	Result.ExchangedWithDBMS = "dbmsBytesAll";
	Result.ExchangedWithDBMSIn5Minutes = "dbmsBytesLast5Min";
	Result.DBMSCallDurations = "durationAllDBMS";
	Result.CurrentDBMSCallDuration = "durationCurrentDBMS";
	Result.DBMSCallDurationsIn5Minutes = "durationLast5MinDBMS";
	Result.DBMSConnection = "dbProcInfo";
	Result.DBMSConnectionTime = "dbProcTook";
	Result.DBMSConnectionSeizeTime = "dbProcTookAt";
	Result.Sleep = "Hibernate";
	Result.TerminateIn = "HibernateSessionTerminateTime";
	Result.SleepIn = "PassiveSessionHibernateTime";
	Result.ReadFromDisk = "InBytesAll";
	Result.ReadFromDiskInCurrentCall = "InBytesCurrent";
	Result.ReadFromDiskIn5Minutes = "InBytesLast5Min";
	Result.OccupiedMemory = "MemoryAll";
	Result.OccupiedMemoryInCurrentCall = "MemoryCurrent";
	Result.OccupiedMemoryIn5Minutes = "MemoryLast5Min";
	Result.WrittenOnDisk = "OutBytesAll";
	Result.WrittenOnDiskInCurrentCall = "OutBytesCurrent";
	Result.WrittenOnDiskIn5Minutes = "OutBytesLast5Min";
	Result.License = New FixedStructure(License);
	Result.ConnectionDetails = New FixedStructure(ConnectionDetails);
	Result.WorkingProcess = New FixedStructure(WorkingProcess);
	
	Return New FixedStructure(Result);
	
EndFunction

// Returns a map of the infobase connection property names used in the API and COM administrator 
//  object model objects.
//
//
Function ConnectionPropertiesDictionary()
	
	Result = ClusterAdministration.ConnectionProperties();
	
	Result.Number = "ConnID";
	Result.UserName = "UserName";
	Result.ClientComputerName = "HostName";
	Result.ClientApplicationID = "AppID";
	Result.ConnectionEstablishingTime = "ConnectedAt";
	Result.InfobaseConnectionMode = "IBConnMode";
	Result.DataBaseConnectionMode = "dbConnMode";
	Result.DBMSLock = "blockedByDBMS";
	Result.Passed = "bytesAll";
	Result.PassedIn5Minutes = "bytesLast5Min";
	Result.ServerCalls = "callsAll";
	Result.ServerCallsIn5Minutes = "callsLast5Min";
	Result.ExchangedWithDBMS = "dbmsBytesAll";
	Result.ExchangedWithDBMSIn5Minutes = "dbmsBytesLast5Min";
	Result.DBMSConnection = "dbProcInfo";
	Result.DBMSTime = "dbProcTook";
	Result.DBMSConnectionSeizeTime = "dbProcTookAt";
	Result.ServerCallDurations = "durationAll";
	Result.DBMSCallDurations = "durationAllDBMS";
	Result.CurrentServerCallDuration = "durationCurrent";
	Result.CurrentDBMSCallDuration = "durationCurrentDBMS";
	Result.ServerCallDurationsIn5Minutes = "durationLast5Min";
	Result.DBMSCallDurationsIn5Minutes = "durationLast5MinDBMS";
	Result.ReadFromDisk = "InBytesAll";
	Result.ReadFromDiskInCurrentCall = "InBytesCurrent";
	Result.ReadFromDiskIn5Minutes = "InBytesLast5Min";
	Result.OccupiedMemory = "MemoryAll";
	Result.OccupiedMemoryInCurrentCall = "MemoryCurrent";
	Result.OccupiedMemoryIn5Minutes = "MemoryLast5Min";
	Result.WrittenOnDisk = "OutBytesAll";
	Result.WrittenOnDiskInCurrentCall = "OutBytesCurrent";
	Result.WrittenOnDiskIn5Minutes = "OutBytesLast5Min";
	Result.ControlIsOnServer = "ThreadMode";
	
	Return New FixedStructure(Result);
	
EndFunction

// Returns a map of the security profile property names used in the API and COM administrator object 
//  model objects.
//
// Returns:
//   FixedStructure - fixed structure that:
//     * Key - String - the name of an API property (see ClusterAdministration.SecurityProfileProperties()),
//     * Value - String - the name of an object property.
//
Function SecurityProfilePropertiesDictionary()
	
	Result = ClusterAdministration.SecurityProfileProperties();
	
	Result.Name = "Name";
	Result.Details = "Descr";
	Result.SafeModeProfile = "SafeModeProfile";
	Result.FullAccessToPrivilegedMode = "PrivilegedModeInSafeModeAllowed";
	Result.FullAccessToCryptoFunctions = "CryptographyAllowed";
	
	Result.FullAccessToAllModulesExtension = "AllModulesExtension";
	Result.ModulesAvailableForExtension = "ModulesAvailableForExtension";
	Result.ModulesNotAvailableForExtension = "ModulesNotAvailableForExtension";
	
	Result.FullAccessToAccessRightsExtension = "RightExtension";
	Result.AccessRightsExtensionLimitingRoles = "RightExtensionDefinitionRoles";
	
	Result.FileSystemFullAccess = "FileSystemFullAccess";
	Result.FullCOMObjectAccess = "COMFullAccess";
	Result.FullAddInAccess = "AddInFullAccess";
	Result.FullExternalModuleAccess = "UnSafeExternalModuleFullAccess";
	Result.FullOperatingSystemApplicationAccess = "ExternalAppFullAccess";
	Result.FullInternetResourceAccess = "InternetFullAccess";
	
	Return New FixedStructure(Result);
	
EndFunction

// Returns a map of the virtual directory property names used in the API and COM administrator 
//  object model objects.
//
// Returns:
//   FixedStructure - fixed structure that:
//     * Key - String - the name of an API property (see ClusterAdministration.VirtualDirectoryProperties()),
//     * Value - String - the name of an object property.
//
Function VirtualDirectoryPropertiesDictionary()
	
	Result = ClusterAdministration.VirtualDirectoryProperties();
	
	Result.LogicalURL = "Alias";
	Result.PhysicalURL = "PhysicalPath";
	
	Result.Details = "Descr";
	
	Result.DataReader = "AllowedRead";
	Result.DataWriter = "AllowedWrite";
	
	Return New FixedStructure(Result);
	
EndFunction

// Returns a map of the COM class property names used in the API and COM administrator object model 
//  objects.
//
// Returns:
//   FixedStructure - fixed structure that:
//     * Key - String - the name of an API property (see ClusterAdministration.COMClassProperties()),
//     * Value - String - the name of an object property.
//
Function COMClassPropertiesDictionary()
	
	Result = ClusterAdministration.COMClassProperties();
	
	Result.Name = "Name";
	Result.Details = "Descr";
	
	Result.FileMoniker = "FileName";
	Result.CLSID = "ObjectUUID";
	Result.Computer = "ComputerName";
	
	Return New FixedStructure(Result);
	
EndFunction

// Returns a map of the add-in property names used in the API and COM administrator object model 
//  objects.
//
// Returns:
//   FixedStructure - fixed structure that:
//     * Key - String - the name of an API property (see ClusterAdministration.AddInProperties()),
//     * Value - String - the name of an object property.
//
Function AddInPropertiesDictionary()
	
	Result = ClusterAdministration.AddInProperties();
	
	Result.Name = "Name";
	Result.Details = "Descr";
	
	Result.HashSum = "AddInHash";
	
	Return New FixedStructure(Result);
	
EndFunction

// Returns a map of the external module property names used in the API and COM administrator object 
//  model objects.
//
// Returns:
//   FixedStructure - fixed structure that:
//     * Key - String - the name of an API property (see ClusterAdministration.ExternalModuleProperties()),
//     * Value - String - the name of an object property.
//
Function ExternalModulePropertiesDictionary()
	
	Result = ClusterAdministration.ExternalModuleProperties();
	
	Result.Name = "Name";
	Result.Details = "Descr";
	
	Result.HashSum = "ExternalModuleHash";
	
	Return New FixedStructure(Result);
	
EndFunction

// Returns a map of the operating system application property names used in the API and COM 
//  administrator object model objects.
//
// Returns:
//   FixedStructure - fixed structure that:
//     * Key - String - the name of an API property (see ClusterAdministration.OSApplicationProperties()),
//     * Value - String - the name of an object property.
//
Function OSApplicationPropertiesDictionary()
	
	Result = ClusterAdministration.OSApplicationProperties();
	
	Result.Name = "Name";
	Result.Details = "Descr";
	
	Result.CommandLinePattern = "CommandMask";
	
	Return New FixedStructure(Result);
	
EndFunction

// Returns a map of the Internet resource property names used in the API and COM administrator 
//  object model objects.
//
// Returns:
//   FixedStructure - fixed structure that:
//     * Key - String - the name of an API property (see ClusterAdministration.InternetResourceProperties()),
//     * Value - String - the name of an object property.
//
Function InternetResourcePropertiesDictionary()
	
	Result = ClusterAdministration.InternetResourceProperties();
	
	Result.Name = "Name";
	Result.Details = "Descr";
	
	Result.Protocol = "Protocol";
	Result.Address = "Address";
	Result.Port = "Port";
	
	Return New FixedStructure(Result);
	
EndFunction

// Returns a map of the connection Details property names used in the API and COM administrator 
//  object model objects.
//
// Returns:
//   FixedStructure - fixed structure that:
//     * Key - String - the name of an API property (see ClusterAdministration.ConnectionDetailsProperties()),
//     * Value - String - the name of an object property.
//
Function ConnectionDetailsPropertiesDictionary()
	
	WorkingProcess = New Structure;
	WorkingProcess.Insert("Key", "Process");
	WorkingProcess.Insert("Dictionary", WorkingProcessPropertiesDictionary());
	
	Result = ClusterAdministration.ConnectionDetailsProperties();
	
	Result.ApplicationName = "Application";
	Result.Lock = "blockedByLS";
	Result.ConnectionEstablishingTime = "ConnectedAt";
	Result.Number = "ConnID";
	Result.ClientComputerName = "Host";
	Result.SessionNumber = "SessionID";
	Result.WorkingProcess = New FixedStructure(WorkingProcess);
	
	Return New FixedStructure(Result);
	
EndFunction

// Returns a map of License property names used in the API and COM administrator object model 
//  objects.
//
// Returns:
//   FixedStructure - fixed structure that:
//     * Key - String - the name of an API property (see ClusterAdministration.LicenseProperties()),
//     * Value - String - the name of an object property.
//
Function LicensePropertiesDictionary()
	
	Result = ClusterAdministration.LicenseProperties();
	
	Result.FileName = "FileName";
	Result.FullPresentation = "FullPresentation";
	Result.BriefPresentation = "ShortPresentation";
	Result.IssuedByServer = "IssuedByServer";
	Result.LisenceType = "LicenseType";
	Result.MaxUsersForSet = "MaxUsersAll";
	Result.MaxUsersInKey = "MaxUsersCur";
	Result.LicenseIsReceivedViaAladdinLicenseManager = "Net";
	Result.ProcessAddress = "RMngrAddress";
	Result.ProcessID = "RMngrPID";
	Result.ProcessPort = "RMngrPort";
	Result.KeySeries = "Series";
	
	Return New FixedStructure(Result);
	
EndFunction

// Returns a map of the Working process property names used in the API and COM administrator object 
//  model objects.
//
// Returns:
//   FixedStructure - fixed structure that:
//     * Key - String - the name of an API property (see ClusterAdministration.WorkingProcessProperties()),
//     * Value - String - the name of an object property.
//
Function WorkingProcessPropertiesDictionary()
	
	License = New Structure;
	License.Insert("Key", "License");
	License.Insert("Dictionary", LicensePropertiesDictionary());
	
	Result = ClusterAdministration.WorkingProcessProperties();
	
	Result.AvailablePerformance = "AvailablePerfomance";
	Result.SpentByTheClient = "AvgBackCallTime";
	Result.ServerReaction = "AvgCallTime";
	Result.SpentByDBMS = "AvgDBCallTime";
	Result.SpentByTheLockManager = "AvgLockCallTime";
	Result.SpentByTheServer = "AvgServerCallTime";
	Result.ClientStreams = "AvgThreads";
	Result.RelativePerformance = "Capacity";
	Result.Connections = "Connections";
	Result.ComputerName = "HostName";
	Result.Enabled = "IsEnable";
	Result.Port = "MainPort";
	Result.ExceedingTheCriticalValue = "MemoryExcessTime";
	Result.OccupiedMemory = "MemorySize";
	Result.ID = "PID";
	Result.Started = "Running";
	Result.CallsCountByWhichTheStatisticsIsCalculated = "SelectionSize";
	Result.StartedAt = "StartedAt";
	Result.Use = "Use";
	Result.License = New FixedStructure(License);
	
	Return New FixedStructure(Result);
	
EndFunction

#EndRegion