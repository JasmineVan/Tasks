///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Public

#Region ProgramInterfaceParameterConstructors

// Constructor of a structure that defines the connection parameters of the server cluster being administrated.
//
// Returns:
//   Structure - where:
//     * ConnectionType - String - valid values:
//                  "COM" - when connecting to the server agent using the V8*.ComConnector COM object;
//                  "RAS" - when connecting the administration server (ras) using the console client 
//                  of the administration server (rac).
//     * ServerAgentAddress - String - network address of the server agent (only for ConnectionType = "COM");
//     * ServerAgentPort - Number - network port of the server agent (only for ConnectionType = 
//                  "COM"). Usually, 1540;
//     * AdministrationServerAddress - String - network address of the administration server ras (only.
//                  When ConnectionType = "RAS");
//     * AdministrationServerPort - Number - network port of the ras administration server (only with.
//                  ConnectionType = "RAS"). Usually, 1545;
//     * ClusterPort - Number - network port of the cluster manager. Usually, 1541;
//     * ClusterAdministratorName - String - cluster administrator account name (if the list of 
//                  administrators is not specified for the cluster, the value is set to empty string);
//     * ClusterAdministratorPassword - String - cluster administrator account password. If the list 
//                  of administrators is not specified for the cluster or the administrator account 
//                  password is not set, the value is a blank string.
//
Function ClusterAdministrationParameters() Export
	
	Result = New Structure();
	
	Result.Insert("ConnectionType", "COM"); // "COM" or "RAS"
	
	// For "COM" only
	Result.Insert("ServerAgentAddress", "");
	Result.Insert("ServerAgentPort", 1540);
	
	// For "RAS" only
	Result.Insert("AdministrationServerAddress", "");
	Result.Insert("AdministrationServerPort", 1545);
	
	Result.Insert("ClusterPort", 1541);
	Result.Insert("ClusterAdministratorName", "");
	Result.Insert("ClusterAdministratorPassword", "");
	
	Return Result;
	
EndFunction

// Constructor of a structure that defines the cluster infobase connection parameters being administered.
//
// Returns:
//  Structure - where:
//    * NameInCluster - String - name of the infobase in cluster server.
//    * InfobaseAdministratorName - String - name of the infobase user with administrative rights 
//                  (if the list of infobase users is not set, the value is set to empty string).
//                  
//    * InfobaseAdministratorPassword - String - password of the infobase user with administrative 
//                  rights (if the list of infobase users is not set or the infobase user password 
//                  is not set, the value is set to empty string).
//
Function ClusterInfobaseAdministrationParameters() Export
	
	Result = New Structure();
	
	Result.Insert("NameInCluster", "");
	Result.Insert("InfobaseAdministratorName", "");
	Result.Insert("InfobaseAdministratorPassword", "");
	
	Return Result;
	
EndFunction

// Checks whether administration parameters are filled correctly.
//
// Parameters:
//  ClusterAdministrationParameters - (See ClusterAdministration.ClusterAdministrationParameters)
//  IBAdministrationParameters - See ClusterAdministration.ClusterInfobaseAdministrationParameters)
//                  The parameter can be skipped if the same fields have been filled in the 
//                  structure passed as the ClusterAdministrationParameters parameter value,
//  CheckClusterAdministrationParameters - Boolean - indicates whether cluster administration 
//                  parameters check is required.
//  CheckClusterAdministrationParameters - Boolean - Indicates whether cluster administration 
//                  parameters check is required.
//
Procedure CheckAdministrationParameters(Val ClusterAdministrationParameters, Val IBAdministrationParameters = Undefined,
	CheckClusterAdministrationParameters = True,
	CheckInfobaseAdministrationParameters = True) Export
	
	If IBAdministrationParameters = Undefined Then
		IBAdministrationParameters = ClusterAdministrationParameters;
	EndIf;
	
	AdministrationManager = AdministrationManager(ClusterAdministrationParameters);
	AdministrationManager.CheckAdministrationParameters(ClusterAdministrationParameters, IBAdministrationParameters, CheckInfobaseAdministrationParameters, CheckClusterAdministrationParameters);
	
EndProcedure

#EndRegion

#Region SessionAndScheduledJobLock

// Constructor of a structure that defines infobase session and scheduled job lock properties.
//  
//
// Returns:
//   Structure - where:
//     * SessionsLock - Boolean - indicates whether new infobase sessions are locked.
//     * DateFrom - Date - a moment of time after which new infobase sessions are prohibited.
//     * DateTo - Date - a moment of time after which new infobase sessions are allowed.
//     * Message - String - the message displayed to the user when a new session is being 
//                            established with the locked infobase.
//     * PermissionCode - String - a pass code that allows to connect to a locked infobase.
//     * ScheduledJobLock - Boolean - flag that shows whether infobase scheduled jobs must be locked.
//
Function SessionAndScheduleJobLockProperties() Export
	
	Result = New Structure();
	
	Result.Insert("SessionsLock");
	Result.Insert("DateFrom");
	Result.Insert("DateTo");
	Result.Insert("Message");
	Result.Insert("KeyCode");
	Result.Insert("LockParameter");
	Result.Insert("ScheduledJobLock");
	
	Return Result;
	
EndFunction

// Returns the current state of infobase session locks and scheduled job locks.
//
// Parameters:
//   ClusterAdministrationParameters - Structure - the parameters for connecting the server cluster. 
//                  For details, see ClusterAdministration.ClusterAdministrationParameters(). 
//   IBAdministrationParameters - Structure - the infobase connection parameters. For details, see 
//                  ClusterAdministration.ClusterInfobaseAdministrationParameters(). 
//                  The parameter can be skipped if the same fields have been filled in the 
//                  structure passed as the ClusterAdministrationParameters parameter value.
//
// Returns:
//   Structure - structure that describes the state of session and scheduled job lock. For details, 
//                  see ClusterAdministration.SessionAndScheduleJobLockProperties(). 
//
Function InfobaseSessionAndJobLock(Val ClusterAdministrationParameters, Val IBAdministrationParameters = Undefined) Export
	
	If IBAdministrationParameters = Undefined Then
		IBAdministrationParameters = ClusterAdministrationParameters;
	EndIf;
	
	AdministrationManager = AdministrationManager(ClusterAdministrationParameters);
	
	Result = AdministrationManager.InfobaseSessionAndJobLock(
		ClusterAdministrationParameters,
		IBAdministrationParameters);
	
	Return Result;
	
EndFunction

// Sets the state of infobase session locks and scheduled job locks.
//
// Parameters:
//   ClusterAdministrationParameters - Structure - the parameters for connecting the server cluster. 
//                  For details, see ClusterAdministration.ClusterAdministrationParameters(). 
//   IBAdministrationParameters - Structure - the infobase connection parameters. For details, see 
//                  ClusterAdministration.ClusterInfobaseAdministrationParameters(). 
//                  The parameter can be skipped if the same fields have been filled in the 
//                  structure passed as the ClusterAdministrationParameters parameter value.
//   SessionAndJobLockProperties - Structure - the state of session and scheduled job lock. For 
//                  details, see ClusterAdministration.SessionAndScheduleJobLockProperties(). 
//
Procedure SetInfobaseSessionAndJobLock(Val ClusterAdministrationParameters, Val IBAdministrationParameters, Val SessionAndJobLockProperties) Export
	
	If IBAdministrationParameters = Undefined Then
		IBAdministrationParameters = ClusterAdministrationParameters;
	EndIf;
	
	AdministrationManager = AdministrationManager(ClusterAdministrationParameters);
	
	AdministrationManager.SetInfobaseSessionAndJobLock(
		ClusterAdministrationParameters,
		IBAdministrationParameters,
		SessionAndJobLockProperties);
	
EndProcedure

// Unlocks infobase sessions and scheduled jobs.
//
// Parameters:
//   ClusterAdministrationParameters - Structure - the parameters for connecting the server cluster. 
//                  For details, see ClusterAdministration.ClusterAdministrationParameters(). 
//   IBAdministrationParameters - Structure - the infobase connection parameters. For details, see 
//                  ClusterAdministration.ClusterInfobaseAdministrationParameters(). 
//                  The parameter can be skipped if the same fields have been filled in the 
//                  structure passed as the ClusterAdministrationParameters parameter value.
//
Procedure RemoveInfobaseSessionAndJobLock(Val ClusterAdministrationParameters, Val IBAdministrationParameters = Undefined) Export
	
	If IBAdministrationParameters = Undefined Then
		IBAdministrationParameters = ClusterAdministrationParameters;
	EndIf;
	
	LockProperties = SessionAndScheduleJobLockProperties();
	LockProperties.SessionsLock = False;
	LockProperties.DateFrom = Undefined;
	LockProperties.DateTo = Undefined;
	LockProperties.Message = "";
	LockProperties.KeyCode = "";
	LockProperties.ScheduledJobLock = False;
	
	SetInfobaseSessionAndJobLock(
		ClusterAdministrationParameters,
		IBAdministrationParameters,
		LockProperties);
	
EndProcedure

#EndRegion

#Region ScheduledJobLock

// Returns the current state of infobase scheduled job locks.
//
// Parameters:
//  ClusterAdministrationParameters - (See ClusterAdministration.ClusterAdministrationParameters)
//  IBAdministrationParameters - See ClusterAdministration.ClusterInfobaseAdministrationParameters)
//                  The parameter can be skipped if the same fields have been filled in the 
//                  structure passed as the ClusterAdministrationParameters parameter value.
//
// Returns:
//  Boolean - the lock is set.
//
Function InfobaseScheduledJobLock(Val ClusterAdministrationParameters, Val IBAdministrationParameters = Undefined) Export
	
	If IBAdministrationParameters = Undefined Then
		IBAdministrationParameters = ClusterAdministrationParameters;
	EndIf;
	
	AdministrationManager = AdministrationManager(ClusterAdministrationParameters);
	
	Result = AdministrationManager.InfobaseScheduledJobLock(
		ClusterAdministrationParameters,
		IBAdministrationParameters);
	
	Return Result;
	
EndFunction

// Sets the state of infobase scheduled job locks.
//
// Parameters:
//  ClusterAdministrationParameters - Structure - the parameters for connecting the server cluster. 
//                  For details, see ClusterAdministration.ClusterAdministrationParameters(). 
//  IBAdministrationParameters - Structure - the infobase connection parameters. For details, see 
//                  ClusterAdministration.ClusterInfobaseAdministrationParameters(). 
//                  The parameter can be skipped if the same fields have been filled in the 
//                  structure passed as the ClusterAdministrationParameters parameter value.
//  ScheduledJobLock - Boolean - indicates whether infobase scheduled jobs are locked.
//
Procedure SetInfobaseScheduledJobLock(Val ClusterAdministrationParameters, Val IBAdministrationParameters, Val ScheduledJobLock) Export
	
	If IBAdministrationParameters = Undefined Then
		IBAdministrationParameters = ClusterAdministrationParameters;
	EndIf;
	
	AdministrationManager = AdministrationManager(ClusterAdministrationParameters);
	
	AdministrationManager.SetInfobaseScheduledJobLock(
		ClusterAdministrationParameters,
		IBAdministrationParameters,
		ScheduledJobLock);
	
EndProcedure

#EndRegion

#Region InfobaseSessions

// Constructor of a structure that describes infobase session properties.
//
// Returns:
//   Structure - where:
//     * Number - Number - session number. The number is unique across the infobase sessions.
//     * UserName - String - infobase user's name.
//     * ClientComputerName - String - name or network address of the computer that established the 
//          session with the infobase.
//     * ClientApplicationID - String - ID of the application that established the session.
//          Possible values - see the details of the ApplicationPresentation() global function.
//     * LanguageID - String - interface language ID.
//     * SessionCreationTime - Date - date and time the session was created.
//     * LatestSessionActivityTime - Date - date and time of the session last activity.
//     * Lock - Number - number of the session that resulted in managed transactional lock wait if 
//          the session sets managed transactional locks and waits for locks set by another session 
//          to be disabled. Otherwise, the value is 0.
//     * DBMSLock - Number - number of the session that caused transactional lock wait if the 
//          session performs a DBMS call and waits for a transactional lock set by another session 
//          to be disabled. Otherwise, the value is 0.
//     * Passed - Number - volume of data passed between the 1C:Enterprise server and the current 
//          session client application since the session start, in bytes.
//     * PassedIn5Minutes - Number - volume of data passed between the 1C:Enterprise server and the 
//          current session client application in the last 5 minutes, in bytes.
//     * ServerCalls - Number - number of the 1c:Enterpraise server calls made by the current 
//          session since the session started.
//     * ServerCallsIn5Minutes - Number - number of the 1C:Enterprise server calls made by the 
//          current session in the last 5 minutes.
//     * ServerCallDurations - Number - total 1C:Enterprise server call time made by the current 
//          session since the session start, in seconds.
//     * CurrentServerCallDuration - Number - time interval since the 1C:Enterprise server call 
//          start. If there is no server call, the value is 0.
//     * ServerCallDurationsIn5Minutes - Number - total time of 1C:Enterprise server calls made by 
//          the current session in the last 5 minutes, in milliseconds.
//     * ExchangedWithDBMS - Number - volume of data passed and received from DBMS on behalf of the 
//          current session since the session start, in bytes.
//     * ExchangedWithDBMSIn5Minutes - Number - volume of data passed and received from DBMS on 
//          behalf of the current session in the last 5 minutes, in bytes.
//     * DBMSCallDurations - Number - total time spent on executing DBMS queries made on behalf of 
//          the current session since the session start, in milliseconds.
//     * CurrentDBMSCallDuration - Number - time interval since the current DBMS query execution 
//          start, in milliseconds. If there is no query, the value is 0.
//     * DBMSCallDurationsIn5Minutes - Number - total time spent on executing DBMS queries made on 
//          behalf of the current session in the last 5 minutes (in milliseconds).
//     * DBMSConnection - String - DBMS connection number in the terms of DBMS if when the session 
//          list is retrieved, the DBMS query is executed, a transaction is opened, or temporary 
//          tables are defined (DBMS connection is seized). If the BDMS session is not seized, the value is a blank string,
//     * DBMSConnectionTime - Number - the period since the DBMS connection capture, in milliseconds. If the
//          BDMS session is not seized - the value is 0,
//     * DBMSConnectionSeizeTime - Date - the date and time of the last DBMS connection capture.
//          
//     * ConnectionDetails - Structure, Undefined - the details of connection with assigned session. 
//                  For fields details see ClusterAdministration.ConnectionDetailsProperties().  Else Undefined.
//     * Sleep - Boolean - the session is in sleep mode.
//     * TerminateIn - Number - a period of time in seconds in which the sleep session terminates.
//     * SleepIn - Number - a period of time in seconds in which the inactive session sets in a 
//                              sleep mode.
//     * ReadFromDisk - Number - volume of data read from a disk by session since the session start, in bytes.
//     * ReadFromDiskInCurrentCall - Number - volume of data read from a disk since the current call 
//                  start, in bytes.
//     * ReadFromDiskIn5Minutes - Number - volume of data in bytes, read from a disk by session in last
//                                         5 minutes.
//     * License - Structure, Undefined - an information about the client license used by this 
//                  session. For fields details see ClusterAdministration.LicenseProperties(). 
//                  Undefined if session does not use license.
//     * OccupiedMemory - Number - contains volume of memory in bytes occupied in calls process since the beginning of the session.
//     * OccupiedMemoryInCurrentCall - Number - contains volume of memory in bytes occupied since the current call start.
//                  If the calling is not executed at the moment, it contains 0.
//     * OccupiedMemoryIn5Minutes - Number - contains volume of memory in bytes occupied during calls for the last 5 minutes.
//     * WrittenOnDisk - Number - volume of data written on a disk by session since the session start, in bytes.
//     * WrittenOnDiskInCurrentCall - Number - volume of data written on a disk since the current 
//                  call start, in bytes.
//     * WrittenOnDiskIn5Minutes - Number - volume of data written on a disk by session in last 5 
//                                        minutes, in bytes.
//     * WorkingProcess - Structure, Undefined - contains work process to which the connection is 
//                  set if the session is assigned to connection, fields details, see  ClusterAdministration.WorkingProcessProperties().
//                  Else Undefined.
//
Function SessionProperties() Export
	
	Result = New Structure();
	
	Result.Insert("Number");
	Result.Insert("UserName");
	Result.Insert("ClientComputerName");
	Result.Insert("ClientApplicationID");
	Result.Insert("LanguageID");
	Result.Insert("SessionCreationTime");
	Result.Insert("LatestSessionActivityTime");
	Result.Insert("Lock");
	Result.Insert("DBMSLock");
	Result.Insert("Passed");
	Result.Insert("PassedIn5Minutes");
	Result.Insert("ServerCalls");
	Result.Insert("ServerCallsIn5Minutes");
	Result.Insert("ServerCallDurations");
	Result.Insert("CurrentServerCallDuration");
	Result.Insert("ServerCallDurationsIn5Minutes");
	Result.Insert("ExchangedWithDBMS");
	Result.Insert("ExchangedWithDBMSIn5Minutes");
	Result.Insert("DBMSCallDurations");
	Result.Insert("CurrentDBMSCallDuration");
	Result.Insert("DBMSCallDurationsIn5Minutes");
	Result.Insert("DBMSConnection");
	Result.Insert("DBMSConnectionTime");
	Result.Insert("DBMSConnectionSeizeTime");
	Result.Insert("ConnectionDetails");
	Result.Insert("Sleep");
	Result.Insert("TerminateIn");
	Result.Insert("SleepIn");
	Result.Insert("ReadFromDisk");
	Result.Insert("ReadFromDiskInCurrentCall");
	Result.Insert("ReadFromDiskIn5Minutes");
	Result.Insert("License");
	Result.Insert("OccupiedMemory");
	Result.Insert("OccupiedMemoryInCurrentCall");
	Result.Insert("OccupiedMemoryIn5Minutes");
	Result.Insert("WrittenOnDisk");
	Result.Insert("WrittenOnDiskInCurrentCall");
	Result.Insert("WrittenOnDiskIn5Minutes");
	Result.Insert("WorkingProcess");
	
	Return Result;
	
EndFunction

// Constructor of the structure that defines license properties.
//
// Returns:
//   Structure - a structure containing fields:
//     * FileName - String - contains full name of the software license file being used.
//     * FullPresentation - String - contains localized string presentation of the license as in property
//                  Session properties dialog "license" or cluster console working process properties
//     * BriefDescription - String - contains localized string presentation of the license as in column
//                  "License" of session list or working processes.
//     * IssuedByServer - Boolean - True - whether the license received by 1C:Enterprise server and issued to the client application.
//                  False - license received by the client application.
//     * LicenseType - Number - contains license type:
//                  0 - platform software license;
//                  1 - hardware license (application security key).
//     * MaxUsersForSet - Number - contains max users allowed for this set if platform software 
//                  license is used. Otherwise, it matches with the MaxUsersCur property value.
//                  
//     * MaxUsersInKey - Number - contains max users in the application security key being used or 
//                  in software license file being used.
//     * LicenseIsReceivedViaAladdinLicenseManager - Boolean - true if the application security key 
//                  is network for hardware license, the license is received via Aladdin License 
//                  Manager; otherwise False.
//     * ProcessAddress - String - contains server address where the process which received license is started.
//     * ProcessID - String - contains process ID that received license and that was assigned to it 
//                  by the operating system.
//     * ProcessPort - Number - contains server process IP-port number received the license.
//     * KeySeries - String - contains application security key series for hardware license or 
//                  registration number of the set for the platform software license.
//
Function LicenseProperties() Export
	
	Result = New Structure();
	
	Result.Insert("FileName");
	Result.Insert("FullPresentation");
	Result.Insert("BriefPresentation");
	Result.Insert("IssuedByServer");
	Result.Insert("LisenceType");
	Result.Insert("MaxUsersForSet");
	Result.Insert("MaxUsersInKey");
	Result.Insert("LicenseIsReceivedViaAladdinLicenseManager");
	Result.Insert("ProcessAddress");
	Result.Insert("ProcessID");
	Result.Insert("ProcessPort");
	Result.Insert("KeySeries");
	
	Return Result;
	
EndFunction

// Constructor of the structure that defines connection details properties.
//
// Returns:
//   Structure - a structure containing fields:
//     * ApplicationName - String - contains application name that connected with 1C:Enterprise server farm.
//     * Lock - Number - contains connection ID that locks this connection work (in the 
//                  Transactional locks service).
//     * ConnectionEstablishingTime - Date - contains the time when the connection was established.
//     * Number - Number - contains connection ID. Allows to distinguish between different 
//                  connections that were set by the same application from the same client computer
//     * ClientComputerName - String - contains name of the computer that established the connection.
//     * SessionNumber - Number - contains session number if the session is assigned to the connection, otherwise - 0.
//     * Working process - Structure - contains object interface with server process details to 
//                  which the connection is set.
//
Function ConnectionDetailsProperties() Export
	
	Result = New Structure();
	
	Result.Insert("ApplicationName");
	Result.Insert("Lock");
	Result.Insert("ConnectionEstablishingTime");
	Result.Insert("Number");
	Result.Insert("ClientComputerName");
	Result.Insert("SessionNumber");
	Result.Insert("WorkingProcess");
	
	Return Result;
	
EndFunction

// Constructor of the structure that defines working process properties.
//
// Returns:
//   Structure - a structure containing fields:
//     * AvailablePerformance - Number - average available performance in the last 5 minutes. It is 
//                  defined by the reaction time of the working process to the reference query. 
//                  According to the available performance server cluster makes a decision on the 
//                  distribution of clients between working processes.
//     * SpentByTheClient - Number - shows the average time that working process takes to client 
//                  application methods call back while single client call is executed
//     * ServerReaction - Number - shows the average support time of a single client call by the working process.
//                  It consists of: SpentByTheServer property values, SpentByDBMS, SpentByTheLockManager,
//                  SpentByTheClient.
//     * SpentByDBMS - Number - shows the average time spent by the working process to access the 
//                  database server when a single client call is executed.
//     * SpentByTheLockManager - Number - shows the average time of a call to the lock manager.
//     * SpentByTheServer - Number - shows the average time spent by the working process itself to 
//                  execute single client call.
//     * ClientStreams - Number - shows the average number of client streams executed by the working process of cluster.
//     * RelativePerformance - Number - relative process performance. The value can be in the range 
//                  from 1 to 1000. It is used to select the working process for connecting the next 
//                  client. Clients are distributed between working processes in proportion to the 
//                  working processes performance.
//     * Connections - Number - number of the working process connections to the user applications.
//     * ComputerName - String - contains the name or IP address of a computer to start the working process.
//     * Enabled - Boolean - the flag is set by the cluster when it is necessary to start or stop the working process.
//                  True - the process must be started and will be started when possible.
//                  False - the process must be stopped and will be stopped after all users 
//                  disconnect or after the time specified by the cluster settings has expired.
//     * Port - Number - contains the number of main IP port of the working process. This port is 
//                  allocated dynamically at the start of the working process from the port ranges defined for the corresponding working server.
//     * ExceedingTheCriticalValue - Number - contains the time during which the virtual memory 
//                  amount of the working process exceeds critical value set for the cluster in seconds.
//     * OccupiedMemory - Number - contains the volume of virtual memory occupied by the working process, in kilobytes.
//     * ID - String - active working process ID in terms of the operating system.
//     * IsStarted - Number - the working process state.
//                  0 - the process is inactive (not imported in memory or cannot execute client queries);
//                  1 - the process is active (operates).
//     * CallsCountByWhichTheStatisticsIsCalculated - Number - calls count by which the statistics is calculated.
//     * StartTime - Date - contains the moment when the working process started. If the process is not started, then the blank date.
//     * Usage - Number - determines the usage of the working process by the cluster. Determined by the administrator.
//                  Possible values:
//                     0 - do not use, the process must not be started;
//                     1 - use, the process must be started;
//                     2 - use as backup, the process must be started only if the process with the 
//                         value 1 of this property cannot be started.
//     * License - Structure, Undefined - contains information about server license used by working process.
//                  Undefined - the working process does not use server license.
//
Function WorkingProcessProperties() Export
	
	Result = New Structure();
	
	Result.Insert("AvailablePerformance");
	Result.Insert("SpentByTheClient");
	Result.Insert("ServerReaction");
	Result.Insert("SpentByDBMS");
	Result.Insert("SpentByTheLockManager");
	Result.Insert("SpentByTheServer");
	Result.Insert("ClientStreams");
	Result.Insert("RelativePerformance");
	Result.Insert("Connections");
	Result.Insert("ComputerName");
	Result.Insert("Enabled");
	Result.Insert("Port");
	Result.Insert("ExceedingTheCriticalValue");
	Result.Insert("OccupiedMemory");
	Result.Insert("ID");
	Result.Insert("Started");
	Result.Insert("CallsCountByWhichTheStatisticsIsCalculated");
	Result.Insert("StartedAt");
	Result.Insert("Use");
	Result.Insert("License");
	
	Return Result;
	
EndFunction

// Returns descriptions of infobase sessions.
//
// Parameters:
//   ClusterAdministrationParameters - (See ClusterAdministration.ClusterAdministrationParameters)
//   IBAdministrationParameters - See ClusterAdministration.ClusterInfobaseAdministrationParameters)
//                  The parameter can be skipped if the same fields have been filled in the 
//                  structure passed as the ClusterAdministrationParameters parameter value.
//   Filter - Array from Structure - describe session filter criteria. Each array structure has the following fields:
//            * Property - String - property name to be used in the filter. For valid values, see
//               Return value of the ClusterAdministration.SessionProperties() function,
//            * ComparisonType - ComparisonType - value of system enumeration ComparisonType, the 
//               type of comparing the session values and the filter values. The following values are available:
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
//            * Value - Number, String, Data, Boolean, ValueList, Array, Structure - the value the 
//               matching session property value is compared with. For ComparisonType.InList and 
//               ComparisonType.NotInList, the passed values are ValueList or Array that contain the 
//               set of values to compare to. For ComparisonType.Interval, ComparisonType.IntervalIncludingBounds,
//               ComparisonType.IntervalIncludingLowerBound, and ComparisonType.
//               IntervalIncludingUpperBound, the passed value contains a structure with the From 
//               and To fields that forms an interval to be compared to.
//          - Structure - Key - the session property Name (mentioned above). Value - the value to 
//            compare to. When you use this filter description, the comparison always checks for 
//            equality.
//
// Returns:
//   Array of (see ClusterAdministration.SessionProperties)
//
Function InfobaseSessions(Val ClusterAdministrationParameters, Val IBAdministrationParameters = Undefined, Val Filter = Undefined) Export
	
	If IBAdministrationParameters = Undefined Then
		IBAdministrationParameters = ClusterAdministrationParameters;
	EndIf;
	
	AdministrationManager = AdministrationManager(ClusterAdministrationParameters);
	
	Return AdministrationManager.InfobaseSessions(
		ClusterAdministrationParameters,
		IBAdministrationParameters,
		Filter);
	
EndFunction

// Deletes infobase sessions according to filter.
//
// Parameters:
//   ClusterAdministrationParameters - Structure - the structure describing parameters for 
//                  connecting the server cluster. For details, see ClusterAdministration. ClusterAdministrationParameters(),
//   IBAdministrationParameters - Structure - the infobase connection parameters. For details, see 
//                  ClusterAdministration.ClusterInfobaseAdministrationParameters(). 
//                  The parameter can be skipped if the same fields have been filled in the 
//                  structure passed as the ClusterAdministrationParameters parameter value.
//   Filter - Array from Structure - describe session filter criteria. Each array structure has the following fields:
//            * Property - String - property name to be used in the filter. For valid values, see
//               Return value of the ClusterAdministration.SessionProperties() function,
//            * ComparisonType - ComparisonType - value of system enumeration ComparisonType, the 
//               type of comparing the session values and the filter values. The following values are available:
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
//            * Value - Number, String, Data, Boolean, ValueList, Array, Structure - the value the 
//               matching session property value is compared with. For ComparisonType.InList and 
//               ComparisonType.NotInList, the passed values are ValueList or Array that contain the 
//               set of values to compare to. For ComparisonType.Interval, ComparisonType.IntervalIncludingBounds,
//               ComparisonType.IntervalIncludingLowerBound, and ComparisonType.
//               IntervalIncludingUpperBound, the passed value contains a structure with the From 
//               and To fields that forms an interval to be compared to.
//          - Structure - Key - the session property Name (mentioned above). Value - the value to 
//            compare to. When you use this filter description, the comparison always checks for 
//            equality.
//
Procedure DeleteInfobaseSessions(Val ClusterAdministrationParameters, Val IBAdministrationParameters = Undefined, Val Filter = Undefined) Export
	
	If IBAdministrationParameters = Undefined Then
		IBAdministrationParameters = ClusterAdministrationParameters;
	EndIf;
	
	AdministrationManager = AdministrationManager(ClusterAdministrationParameters);
	
	AdministrationManager.DeleteInfobaseSessions(
		ClusterAdministrationParameters,
		IBAdministrationParameters,
		Filter);
	
EndProcedure

#EndRegion

#Region InfobaseConnections

// Constructor of a structure that defines infobase connection properties.
//
// Returns:
//   Structure - where:
//     * Number - Number - number of infobase connection.
//     * UserName - String - the name of a 1C:Enterprise user connected to the infobase.
//     * ClientComputerName - String - the name of the computer that established the connection.
//     * ClientApplicationID - String - ID of the application that established the connection.
//                  Possible values - see the details of the ApplicationPresentation() global function.
//     * ConnectionEstablishingTime - Date - connection establishing time.
//     * InfobaseConnectionMode - Number - the infobase connection mode (0 if shared, 1 if 
//                  exclusive).
//     * DatabaseConnectionMode - Number - database connection mode (0 if no connection,
//                  1 - shared, 2 - exclusive).
//     * DBMSLock - Number - ID of the connection that locks the current connection in the DBMS.
//     * Passed - Number - volume of data that the connection sent and received.
//     * PassedIn5Minutes - Number - the volume of data sent and received over the connection in the last 5 minutes.
//     * ServerCalls - Number - the number of server calls.
//     * ServerCallsIn5Minutes - Number - number of server calls in the last 5 minutes.
//     * ExchangedWithDBMS - Number -  the data volume passed between the 1C:Enterprise server and 
//                  the database server since the connection was established.
//     * ExchangedWithDBMSIn5Minutes - Number - the volume of data passed between the 1C:Enterprise 
//                  server and the database server in the last 5 minutes.
//     * DBMSConnection - String - the DBMS connection process ID if the connection is contacting a 
//                  DBMS server when the list is requested. Otherwise, the value is a blank string.
//                   The ID is returned in the DBMS server terms.
//     * DBMSTime - Number - the DBMS server call duration in seconds if the connection is 
//                  contacting a DBMS server when the list is requested. Otherwise, the value is 0.
//                  
//     * DBMSConnectionSeizeTime - Date - last time when the DBMS server connection was seized.
//     * ServerCallDurations - Number - total duration of all server calls for the connection.
//     * DBMSCallDurations - Number - duration of the DBMS calls that the connection initialized.
//     * CurrentServerCallDuration - Number - duration of the current server call.
//     * CurrentDBMSCallDuration - Number - duration of the current DBMS server call.
//     * ServerCallDurationsIn5Minutes - Number - duration of server calls in the last 5 minutes.
//     * DBMSCallDurationsIn5Minutes - Number - the duration of DBMS server calls in the last 5 minutes.
//     * ReadFromDisk - Number - volume of data read from a disk by session since the session start, in bytes.
//     * ReadFromDiskInCurrentCall - Number - volume of data read from a disk since the current call 
//                  start, in bytes.
//     * ReadFromDiskIn5Minutes - Number - volume of data in bytes, read from a disk by session in 
//                  last 5 minutes.
//     * OccupiedMemory - Number - contains volume of memory in bytes occupied in calls process since the beginning of the session.
//     * OccupiedMemoryInCurrentCall - Number - contains volume of memory in bytes occupied since 
//                  the current call start. If the calling is not executed at the moment, it contains 0.
//     * OccupiedMemoryIn5Minutes - Number - contains volume of memory in bytes occupied during calls for the last 5 minutes.
//     * WrittenOnDisk - Number - volume of data written on a disk by session since the session start, in bytes.
//     * WrittenOnDiskInCurrentCall - Number - volume of data written on a disk since the current 
//                  call start, in bytes.
//     * WrittenOnDiskIn5Minutes - Number - volume of data written on a disk by session in last 5 
//                  minutes, in bytes.
//     * ControlIsOnServer - Number - specifies whether the control is on the server (0 - it is not on the server, 1 - it is on the server).
//
Function ConnectionProperties() Export
	
	Result = New Structure();
	
	Result.Insert("Number");
	Result.Insert("UserName");
	Result.Insert("ClientComputerName");
	Result.Insert("ClientApplicationID");
	Result.Insert("ConnectionEstablishingTime");
	Result.Insert("InfobaseConnectionMode");
	Result.Insert("DataBaseConnectionMode");
	Result.Insert("DBMSLock");
	Result.Insert("Passed");
	Result.Insert("PassedIn5Minutes");
	Result.Insert("ServerCalls");
	Result.Insert("ServerCallsIn5Minutes");
	Result.Insert("ExchangedWithDBMS");
	Result.Insert("ExchangedWithDBMSIn5Minutes");
	Result.Insert("DBMSConnection");
	Result.Insert("DBMSTime");
	Result.Insert("DBMSConnectionSeizeTime");
	Result.Insert("ServerCallDurations");
	Result.Insert("DBMSCallDurations");
	Result.Insert("CurrentServerCallDuration");
	Result.Insert("CurrentDBMSCallDuration");
	Result.Insert("ServerCallDurationsIn5Minutes");
	Result.Insert("DBMSCallDurationsIn5Minutes");
	Result.Insert("ReadFromDisk");
	Result.Insert("ReadFromDiskInCurrentCall");
	Result.Insert("ReadFromDiskIn5Minutes");
	Result.Insert("OccupiedMemory");
	Result.Insert("OccupiedMemoryInCurrentCall");
	Result.Insert("OccupiedMemoryIn5Minutes");
	Result.Insert("WrittenOnDisk");
	Result.Insert("WrittenOnDiskInCurrentCall");
	Result.Insert("WrittenOnDiskIn5Minutes");
	Result.Insert("ControlIsOnServer");
	
	Return Result;
	
EndFunction

// Returns descriptions of infobase connections.
//
// Parameters:
//   ClusterAdministrationParameters - Structure - the structure describing parameters for 
//                  connecting the server cluster. For details, see ClusterAdministration. ClusterAdministrationParameters(),
//   IBAdministrationParameters - Structure - the structure describing infobase connection 
//                  parameters. For details, see ClusterAdministration. ClusterInfobaseAdministrationParameters(),
//                  The parameter can be skipped if the same fields have been filled in the 
//                  structure passed as the ClusterAdministrationParameters parameter value.
//   Filter - Array from Structure - describe session filter criteria. Each array structure has the following fields:
//            * Property - String - property name to be used in the filter. For valid values, see
//               Return value of the ClusterAdministration.SessionProperties() function,
//            * ComparisonType - ComparisonType - value of system enumeration ComparisonType, the 
//               type of comparing the session values and the filter values. The following values are available:
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
//            * Value - Number, String, Data, Boolean, ValueList, Array, Structure - the value the 
//               matching session property value is compared with. For ComparisonType.InList and 
//               ComparisonType.NotInList, the passed values are ValueList or Array that contain the 
//               set of values to compare to. For ComparisonType.Interval, ComparisonType.IntervalIncludingBounds,
//               ComparisonType.IntervalIncludingLowerBound, and ComparisonType.
//               IntervalIncludingUpperBound, the passed value contains a structure with the From 
//               and To fields that forms an interval to be compared to.
//          - Structure - Key - the session property Name (mentioned above). Value - the value to 
//            compare to. When you use this filter description, the comparison always checks for 
//            equality.
//
// Returns:
//   Array - an array of structures describing connection properties. For structure descriptions, 
//                  see ClusterAdministration.ConnectionProperties(). 
//
Function InfobaseConnections(Val ClusterAdministrationParameters, Val IBAdministrationParameters = Undefined, Val Filter = Undefined) Export
	
	If IBAdministrationParameters = Undefined Then
		IBAdministrationParameters = ClusterAdministrationParameters;
	EndIf;
	
	AdministrationManager = AdministrationManager(ClusterAdministrationParameters);
	
	Return AdministrationManager.InfobaseConnections(
		ClusterAdministrationParameters,
		IBAdministrationParameters,
		Filter);
	
EndFunction

// Terminates infobase connections according to filter.
//
// Parameters:
//   ClusterAdministrationParameters - Structure - the structure describing parameters for 
//                  connecting the server cluster. For details, see ClusterAdministration. ClusterAdministrationParameters(),
//   IBAdministrationParameters - Structure - the structure describing infobase connection 
//                  parameters. For details, see ClusterAdministration. ClusterInfobaseAdministrationParameters().
//                  The parameter can be skipped if the same fields have been filled in the 
//                  structure passed as the ClusterAdministrationParameters parameter value.
//   Filter - Array - an array from structures that contain session filter criteria. Each array structure has the following fields:
//            * Property - String - property name used as a filter base. For valid values, see
//               Return value of the ClusterAdministration.SessionProperties() function.
//            * ComparisonType - ComparisonType - value of system enumeration ComparisonType, the 
//               type of comparing the session values and the filter values. The following values are available:
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
//                  ComparisonType.IntervalIncludingUpperBound (for numeric values only).
//            * Value - Number, String, Data, Boolean, ValueList, Array, Structure - the value the 
//               matching session property value is compared with. For ComparisonType.InList and 
//               ComparisonType.NotInList, the passed values are ValueList or Array that contain the 
//               set of values to compare to. For ComparisonType.Interval, ComparisonType.IntervalIncludingBounds,
//               ComparisonType.IntervalIncludingLowerBound, and ComparisonType.
//               IntervalIncludingUpperBound, the passed value contains a structure with the From 
//               and To fields that forms an interval to be compared to.
//          - Structure - Key - the session property Name (mentioned above). Value - the value to 
//            compare to. When you use this filter description, the comparison always checks for 
//            equality.
//
Procedure TerminateInfobaseConnections(Val ClusterAdministrationParameters, Val IBAdministrationParameters = Undefined, Val Filter = Undefined) Export
	
	If IBAdministrationParameters = Undefined Then
		IBAdministrationParameters = ClusterAdministrationParameters;
	EndIf;
	
	AdministrationManager = AdministrationManager(ClusterAdministrationParameters);
	
	AdministrationManager.TerminateInfobaseConnections(
		ClusterAdministrationParameters,
		IBAdministrationParameters,
		Filter);
	
EndProcedure

#EndRegion

#Region SecurityProfiles

// Returns the name of a security profile assigned to the infobase.
//
// Parameters:
//   ClusterAdministrationParameters - Structure - the structure describing parameters for 
//                  connecting the server cluster. For details, see ClusterAdministration. ClusterAdministrationParameters(),
//   IBAdministrationParameters - Structure - the structure describing infobase connection 
//                  parameters. For details, see ClusterAdministration. ClusterInfobaseAdministrationParameters().
//                  The parameter can be skipped if the same fields have been filled in the 
//                  structure passed as the ClusterAdministrationParameters parameter value.
//
// Returns:
//   String - name of the security profile set for the infobase. If the infobase is not assigned 
//                  with a security profile, returns an empty string.
//
Function InfobaseSecurityProfile(Val ClusterAdministrationParameters, Val IBAdministrationParameters = Undefined) Export
	
	If IBAdministrationParameters = Undefined Then
		IBAdministrationParameters = ClusterAdministrationParameters;
	EndIf;
	
	AdministrationManager = AdministrationManager(ClusterAdministrationParameters);
	
	Return AdministrationManager.InfobaseSecurityProfile(
		ClusterAdministrationParameters,
		IBAdministrationParameters);
	
EndFunction

// Returns the name of the security profile that was set as the infobase safe mode security profile.
//  
//
// Parameters:
//   ClusterAdministrationParameters - Structure - the structure describing parameters for 
//                  connecting the server cluster. For details, see ClusterAdministration. ClusterAdministrationParameters(),
//   IBAdministrationParameters - Structure - the structure describing infobase connection 
//                  parameters. For details, see ClusterAdministration. ClusterInfobaseAdministrationParameters().
//                  The parameter can be skipped if the same fields have been filled in the 
//                  structure passed as the ClusterAdministrationParameters parameter value.
//
// Returns:
//   String - name of the security profile set for the infobase as the safe mode security profile.
//                   If the infobase is not assigned with a security profile, returns an empty string.
//
Function InfobaseSafeModeSecurityProfile(Val ClusterAdministrationParameters, Val IBAdministrationParameters = Undefined) Export
	
	If IBAdministrationParameters = Undefined Then
		IBAdministrationParameters = ClusterAdministrationParameters;
	EndIf;
	
	AdministrationManager = AdministrationManager(ClusterAdministrationParameters);
	
	Return AdministrationManager.InfobaseSafeModeSecurityProfile(
		ClusterAdministrationParameters,
		IBAdministrationParameters);
	
EndFunction

// Assigns a security profile to an infobase.
//
// Parameters:
//   ClusterAdministrationParameters - Structure - the structure describing parameters for 
//                  connecting the server cluster. For details, see ClusterAdministration. ClusterAdministrationParameters(),
//   IBAdministrationParameters - Structure - the structure describing infobase connection 
//                  parameters. For details, see ClusterAdministration. ClusterInfobaseAdministrationParameters(),
//                  The parameter can be skipped if the same fields have been filled in the 
//                  structure passed as the ClusterAdministrationParameters parameter value.
//   ProfileName - String - the security profile name. If the passed string is empty, the security 
//                  profile is disabled for the infobase.
//
Procedure SetInfobaseSecurityProfile(Val ClusterAdministrationParameters, Val IBAdministrationParameters = Undefined, Val ProfileName = "") Export
	
	If IBAdministrationParameters = Undefined Then
		IBAdministrationParameters = ClusterAdministrationParameters;
	EndIf;
	
	AdministrationManager = AdministrationManager(ClusterAdministrationParameters);
	
	AdministrationManager.SetInfobaseSecurityProfile(
		ClusterAdministrationParameters,
		IBAdministrationParameters,
		ProfileName);
	
EndProcedure

// Assigns a safe-mode security profile to an infobase.
//
// Parameters:
//   ClusterAdministrationParameters - Structure - the structure describing parameters for 
//                  connecting the server cluster. For details, see ClusterAdministration. ClusterAdministrationParameters(),
//   IBAdministrationParameters - Structure - the structure describing infobase connection 
//                  parameters. For details, see ClusterAdministration. ClusterInfobaseAdministrationParameters(),
//                  The parameter can be skipped if the same fields have been filled in the 
//                  structure passed as the ClusterAdministrationParameters parameter value.
//   ProfileName - String - the security profile name. If the passed string is empty, the safe mode 
//                  security profile is disabled for the infobase.
//
Procedure SetInfobaseSafeModeSecurityProfile(Val ClusterAdministrationParameters, Val IBAdministrationParameters = Undefined, Val ProfileName = "") Export
	
	If IBAdministrationParameters = Undefined Then
		IBAdministrationParameters = ClusterAdministrationParameters;
	EndIf;
	
	AdministrationManager = AdministrationManager(ClusterAdministrationParameters);
	
	AdministrationManager.SetInfobaseSafeModeSecurityProfile(
		ClusterAdministrationParameters,
		IBAdministrationParameters,
		ProfileName);
	
EndProcedure

// Checks whether a security profile exists in the server cluster.
//
// Parameters:
//   ClusterAdministrationParameters - Structure - the structure describing parameters for 
//                  connecting the server cluster. For details, see ClusterAdministration. ClusterAdministrationParameters(),
//    ProfileName - String - the security profile name.
//
// Returns:
//   Boolean
//
Function SecurityProfileExists(Val ClusterAdministrationParameters, Val ProfileName) Export
	
	AdministrationManager = AdministrationManager(ClusterAdministrationParameters);
	
	Return AdministrationManager.SecurityProfileExists(
		ClusterAdministrationParameters,
		ProfileName);
	
EndFunction

// Constructor of the structure that defines security profile properties.
//
// Returns:
//   Structure - a structure containing fields:
//     * Name - String - the name of the security profile.
//     * Details - String - details of the security profile.
//     * SafeModeProfile - Boolean - flag that shows whether the security profile can be used as a 
//                  security profile of the safe mode (both when the profile is specified for the 
//                  infobase and when calling.
//                  SetSafeMode(<Profile name>) is called from the configuration code.
//     * FullAccessToPrivilegedMode - Boolean - the flag that shows whether the privileged mode can 
//                  be set from the safe mode of the security profile.
//     * FullAccessToCryptoFunctions - Boolean - whether the cryptographic functionality (signature, 
//                  signature check, encryption, details, operation with certificate storage, 
//                  certificate check, and extracting certificates from the signature) when operating on server can be used.
//                  Cryptographic functions are not locked on the client.
//                  True - execution is allowed. False - execution is prohibited.
//     * FullAccessToAllModulesExtension - Boolean - whether the change of all modules in 
//                  configuration extension is allowed:
//                     True - extension of all modules is allowed.
//                     False - only modules from the allowed list are allowed to extend.
//     * ModulesAvailableForExtension - String - it is used when the extension of all modules is not allowed.
//                  Contains a list of full configuration or modules object names whose extension is 
//                  allowed, separated by ";". Specifying full configuration object name allows to 
//                  extend all object modules. Specifying full configuration object name allows to extend a specific module.
//     * ModulesNotAvailableForExtension - String - it is used when the extension of all modules is allowed.
//                  Contains a list of full configuration or modules object names whose extension is 
//                  not allowed, separated by ";". Specifying full configuration object name 
//                  prohibits to extend all object modules.
//     * FullAccessToAccessRightsExtension - Boolean - whether the increasing rights to 
//                  configuration objects is allowed by the extensions limited by the security profile:
//                     True - increasing rights is allowed.
//                     False - increasing rights is not allowed.
//                  If the roles list of configuration being extended is specified, increasing 
//                  rights is allowed if at least one role from the list includes the required right.
//     * AccessRightsExtensionLimitingRoles - String - contains role names list that affect access 
//                  rights change from the extension. When changing role list, the changes in roles 
//                  content are considered only after current sessions restart and for new sessions.
//     * FileSystemFullAccess - Boolean - the flag that shows whether there are file system access 
//                  restrictions. If the value is False, infobase users can access only file system 
//                  directories specified in the VirtualDirectories property.
//     * COMObjectFullAccess - Boolean - the flag that shows whether there are restrictions to access.
//                  COM object. If the value is False, infobase users can access only COM classes 
//                  specified in the COM classes property.
//     * FullAddInAccess - Boolean - the flag that defines whether there are add-in access 
//                  restrictions. If the value is False, infobase users can access only add-ins 
//                  specified in the AddIns property.
//     * FullExternalModuleAccess - Boolean - flag that shows whether there are external module 
//                  (external reports and data processors, Execute() and Evaluate() calls in the unsafe mode) access restrictions.
//                  If the value is False, infobase users can use in the unsafe mode only external 
//                  modules specified in the ExternalModules property.
//     * FullOperatingSystemApplicationAccess - Boolean - the flag that shows whether there are 
//                  operating system application access restrictions. If the value is False, 
//                  infobase users can use operating system applications specified in the 
//                  OSApplications property.
//     * InternetResourcesFullAccess - Boolean - the flag that shows whether there are restrictions 
//                  to internet resources access. If the value is False, infobase users can use 
//                  internet resources specified in the InternetResources property.
//     * VirtualDirectories - Array - an array of structures that describe virtual directories that 
//                  are provided with an access when setting FileSystemFullAccess = False. Structure 
//                  fields descriptions see ClusterAdministration.VirtualDirectoryProperties(). 
//     * COMClasses - Array - an array of structures that describe COM classes that are provided with an access when setting
//                  COMObjectFullAccess = False. Structure fields descriptions see 
//                  ClusterAdministration.COMClassProperties(). 
//     * AddIns - Array - an array of structures that describe add-ins that are provided with an 
//                  access when setting AddInFullAccess = False. Structure fields descriptions see 
//                  ClusterAdministration.AddInProperties(). 
//     * ExternalModules - Array - an array of structures that describe external modules that are 
//                  provided with an access in the unsafe mode when setting ExternalModuleFullAccess = False. 
//                  Structure fields descriptions see ClusterAdministration. ExternalModuleProperties().
//     * OSApplications - Array - an array of structures that describe operating system applications 
//                  provided with an access when setting FullOperatingSystemApplicationAccess = False. 
//                  Structure fields descriptions see ClusterAdministration. OSApplicationProperties().
//     * InternetResources - Array - an array of structures that describe internet resources that 
//                  are provided with an access when setting InternetResourcesFullAccess = False. 
//                  Structure fields descriptions see ClusterAdministration. InternetResourceProperties().
//
Function SecurityProfileProperties() Export
	
	Result = New Structure();
	
	Result.Insert("Name", "");
	Result.Insert("Details", "");
	Result.Insert("SafeModeProfile", False);
	Result.Insert("FullAccessToPrivilegedMode", False);
	Result.Insert("FullAccessToCryptoFunctions", False);
	
	Result.Insert("FullAccessToAllModulesExtension", False);
	Result.Insert("ModulesAvailableForExtension", "");
	Result.Insert("ModulesNotAvailableForExtension", "");
	
	Result.Insert("FullAccessToAccessRightsExtension", False);
	Result.Insert("AccessRightsExtensionLimitingRoles", "");
		
	Result.Insert("FileSystemFullAccess", False);
	Result.Insert("FullCOMObjectAccess", False);
	Result.Insert("FullAddInAccess", False);
	Result.Insert("FullExternalModuleAccess", False);
	Result.Insert("FullOperatingSystemApplicationAccess", False);
	Result.Insert("FullInternetResourceAccess", False);
	
	Result.Insert("VirtualDirectories", New Array());
	Result.Insert("COMClasses", New Array());
	Result.Insert("AddIns", New Array());
	Result.Insert("ExternalModules", New Array());
	Result.Insert("OSApplications", New Array());
	Result.Insert("InternetResources", New Array());
	
	Return Result;
	
EndFunction

// Constructor of a structure that describe virtual directory properties.
//
// Returns:
//    Structure - a structure containing fields:
//     * LogicalURL - String - the logical URL of a directory.
//     * PhysicalURL - String - the physical URL of the server directory where virtual directory data is stored.
//     * Details - String - virtual directory details.
//     * DataReader - Boolean - the flag that shows whether virtual directory data reading is allowed.
//     * DataWriter - Boolean - the flag that shows whether virtual directory data writing is allowed.
//
Function VirtualDirectoryProperties() Export
	
	Result = New Structure();
	
	Result.Insert("LogicalURL");
	Result.Insert("PhysicalURL");
	
	Result.Insert("Details");
	
	Result.Insert("DataReader");
	Result.Insert("DataWriter");
	
	Return Result;
	
EndFunction

// Constructor of a structure that describes COM class properties.
//
// Returns:
//    Structure - a structure containing fields:
//     * Name - String - the name of a COM class that is used as a search key.
//     * Details - String - the COM class details.
//     * FileMoniker - String - name of file used for creating the object using the global context method
//                  GetCOMObject() with an empty value of the second parameter.
//     * CLSID - Sting - the COM class ID representation in the Windows system registry format 
//                  without curly brackets, which the operating system uses to create the COM class.
//     * Computer - String - the name of the computer on which you can create the COM object.
//
Function COMClassProperties() Export
	
	Result = New Structure();
	
	Result.Insert("Name");
	Result.Insert("Details");
	
	Result.Insert("FileMoniker");
	Result.Insert("CLSID");
	Result.Insert("Computer");
	
	Return Result;
	
EndFunction

// Constructor of the structure that describes the add-in properties.
//
// Returns:
//    Structure - a structure containing fields:
//     * Name - String - the name of the add-in. Used as a search key.
//     * Details - String - the add-in details.
//     * HashSum - String - contains the checksum of the allowed add-in, calculated with SHA-1 
//                  algorithm and converted to a base64 string.
//
Function AddInProperties() Export
	
	Result = New Structure();
	
	Result.Insert("Name");
	Result.Insert("Details");
	
	Result.Insert("HashSum");
	
	Return Result;
	
EndFunction

// Constructor of the structure that describes external module properties.
//
// Returns:
//    Structure - a structure containing fields:
//     * Name - String - the name of the external module. Used as a search key.
//     * Details - String - the external module details.
//     * HashSum - String - contains the checksum of the allowed external module, calculated with 
//                  SHA-1 algorithm and converted to a base64 string.
//
Function ExternalModuleProperties() Export
	
	Result = New Structure();
	
	Result.Insert("Name");
	Result.Insert("Details");
	
	Result.Insert("HashSum");
	
	Return Result;
	
EndFunction

// Constructor of a structure that defines operating system application properties.
//
// Returns:
//    Structure - a structure containing fields:
//     * Name - String - the name of the operating system application. Used as a search key.
//     * Details - String - the operating system application details.
//     * CommandLinePattern - String - application command line pattern, which consists of 
//                  space-separated pattern words.
//
Function OSApplicationProperties() Export
	
	Result = New Structure();
	
	Result.Insert("Name");
	Result.Insert("Details");
	
	Result.Insert("CommandLinePattern");
	
	Return Result;
	
EndFunction

// Constructor of a structure that describes the Internet resource.
//
// Returns:
//    Structure - a structure containing fields:
//     * Name - String - the name of the internet resource. Used as a search key.
//     * Details - String - internet resource details.
//     * Protocol - String - an allowed network protocol. Possible values:
//          HTTP,
//          HTTPS,
//          FTP,
//          FTPS,
//          POP3,
//          SMTP,
//          IMAP.
//     * Address - String - a network address with no protocol and port.
//     * Port - Number - an internet resource port.
//
Function InternetResourceProperties() Export
	
	Result = New Structure();
	
	Result.Insert("Name");
	Result.Insert("Details");
	
	Result.Insert("Protocol");
	Result.Insert("Address");
	Result.Insert("Port");
	
	Return Result;
	
EndFunction

// Returns properties of a security profile.
//
// Parameters:
//   ClusterAdministrationParameters - Structure - the structure that describes parameters for 
//                  connecting the server cluster. For details, see ClusterAdministration. ClusterAdministrationParameters().
//  ProfileName - String - the security profile name.
//
// Returns:
//   Structure - structure describing security profile. For details, see
//                  ClusterAdministration.SecurityProfileProperties().
//
Function SecurityProfile(Val ClusterAdministrationParameters, Val ProfileName) Export
	
	AdministrationManager = AdministrationManager(ClusterAdministrationParameters);
	
	Return AdministrationManager.SecurityProfile(
		ClusterAdministrationParameters,
		ProfileName);
	
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
	
	AdministrationManager = AdministrationManager(ClusterAdministrationParameters);
	
	AdministrationManager.CreateSecurityProfile(
		ClusterAdministrationParameters,
		SecurityProfileProperties);
	
EndProcedure

// Sets properties for a security profile on the basis of the passed description.
//
// Parameters:
//   ClusterAdministrationParameters - Structure - the parameters for connecting the server cluster. 
//                  For details, see ClusterAdministration.ClusterAdministrationParameters(). 
//  SecurityProfileProperties - Structure - structure that describes the properties of the security 
//                  profile. For the details, see ClusterAdministration.SecurityProfileProperties(). 
//
Procedure SetSecurityProfileProperties(Val ClusterAdministrationParameters, Val SecurityProfileProperties)  Export
	
	AdministrationManager = AdministrationManager(ClusterAdministrationParameters);
	
	AdministrationManager.SetSecurityProfileProperties(
		ClusterAdministrationParameters,
		SecurityProfileProperties);
	
EndProcedure

// Deletes a securiy profile.
//
// Parameters:
//   ClusterAdministrationParameters - Structure - the structure that describes parameters for 
//                  connecting the server cluster. For details, see ClusterAdministration. ClusterAdministrationParameters().
//  ProfileName - String - the security profile name.
//
Procedure DeleteSecurityProfile(Val ClusterAdministrationParameters, Val ProfileName) Export
	
	AdministrationManager = AdministrationManager(ClusterAdministrationParameters);
	
	AdministrationManager.DeleteSecurityProfile(
		ClusterAdministrationParameters,
		ProfileName);
	
EndProcedure

#EndRegion

#Region Infobases

// Returns an internal infobase ID.
//
// Parameters:
//   ClusterID - String - internal ID of a server cluster.
//   ClusterAdministrationParameters - Structure - the structure describing parameters for 
//                  connecting the server cluster. For details, see ClusterAdministration. ClusterAdministrationParameters(),
//  InfobaseAdministrationParameters - Structure - the structure describing infobase connection 
//                  parameters. For details, see ClusterAdministration. ClusterInfobaseAdministrationParameters().
//
// Returns:
//   String - internal infobase ID.
//
Function InfoBaseID(Val ClusterID, Val ClusterAdministrationParameters, Val InfobaseAdministrationParameters) Export
	
	AdministrationManager = AdministrationManager(ClusterAdministrationParameters);
	
	Return AdministrationManager.InfoBaseID(
		ClusterID,
		ClusterAdministrationParameters,
		InfobaseAdministrationParameters);
	
EndFunction

// Returns infobase descriptions
//
// Parameters:
//   ClusterID - String - internal ID of a server cluster.
//   ClusterAdministrationParameters - (See ClusterAdministration.ClusterAdministrationParameters)
//   Filter - Structure - infobase filtering criteria.
//
// Returns:
//  Array from Structure - properties.
//
Function InfobasesProperties(Val ClusterID, Val ClusterAdministrationParameters, Val Filter = Undefined) Export
	
	AdministrationManager = AdministrationManager(ClusterAdministrationParameters);
	
	Return AdministrationManager.InfobasesProperties(
		ClusterID,
		ClusterAdministrationParameters,
		Filter);
	
EndFunction

#EndRegion

#Region Cluster

// Returns an internal ID of a server cluster.
//
// Parameters:
//  ClusterAdministrationParameters - Structure - the structure that describes parameters for 
//                  connecting the server cluster. For details, see ClusterAdministration. ClusterAdministrationParameters().
//
// Returns:
//   String - internal server cluster ID.
//
Function ClusterID(Val ClusterAdministrationParameters) Export
	
	AdministrationManager = AdministrationManager(ClusterAdministrationParameters);
	
	Return AdministrationManager.ClusterID(ClusterAdministrationParameters);
	
EndFunction

// Returns server cluster descriptions.
//
//   ClusterAdministrationParameters - (See ClusterAdministration.ClusterAdministrationParameters)
//   Filter - Structure - server cluster filtering criteria.
//
// Returns:
//   Array from Structure - properties.
//
Function ClusterProperties(Val ClusterAdministrationParameters, Val Filter = Undefined) Export
	
	AdministrationManager = AdministrationManager(ClusterAdministrationParameters);
	
	Return AdministrationManager.ClusterProperties(ClusterAdministrationParameters, Filter);
	
EndFunction

#EndRegion

#Region WorkingProcessesServers

// Returns descriptions of working processes.
//
// Parameters:
//   ClusterID - String - internal ID of a server cluster.
//   ClusterAdministrationParameters - Structure - the structure that describes parameters for 
//                  connecting the server cluster. For details, see ClusterAdministration. ClusterAdministrationParameters().
//   Filter - Structure - working process filtering criteria.
//
// Returns:
//   Array - an array of structures describing working process properties.
//
Function WorkingProcessesProperties(Val ClusterID, Val ClusterAdministrationParameters, Val Filter = Undefined) Export
	
	AdministrationManager = AdministrationManager(ClusterAdministrationParameters);
	
	Return AdministrationManager.WorkingProcessesProperties(
		ClusterID,
		ClusterAdministrationParameters,
		Filter);
	
EndFunction

// Returns descriptions of working servers.
//
// Parameters:
//   ClusterID - String - internal ID of a server cluster.
//   ClusterAdministrationParameters - Structure - the parameters for connecting the server cluster. 
//                  For details, see ClusterAdministration.ClusterAdministrationParameters(). 
//   Filter - Structure - working server filtering criteria.
//
// Returns:
//   Array - an array of structures describing working server properties.
//
Function WorkingServerProperties(Val ClusterID, Val ClusterAdministrationParameters, Val Filter = Undefined) Export
	
	AdministrationManager = AdministrationManager(ClusterAdministrationParameters);
	
	Return AdministrationManager.WorkingServerProperties(
		ClusterID,
		ClusterAdministrationParameters,
		Filter);
	
EndFunction

#EndRegion

// Returns descriptions of infobase sessions.
//
// Parameters:
//   ClusterID - String - internal ID of a server cluster.
//   ClusterAdministrationParameters - (See ClusterAdministration.ClusterAdministrationParameters)
//   InfoBaseID - String - an internal ID of an infobase.
//   Filter - Array from Structure - describe session filter criteria. Each array structure has the following fields:
//            * Property - String - property name to be used in the filter. For valid values, see
//               Return value of the ClusterAdministration.SessionProperties() function,
//            * ComparisonType - ComparisonType - value of system enumeration ComparisonType, the 
//               type of comparing the session values and the filter values. The following values are available:
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
//            * Value - Number, String, Data, Boolean, ValueList, Array, Structure - the value the 
//               matching session property value is compared with. For ComparisonType.InList and 
//               ComparisonType.NotInList, the passed values are ValueList or Array that contain the 
//               set of values to compare to. For ComparisonType.Interval, ComparisonType.IntervalIncludingBounds,
//               ComparisonType.IntervalIncludingLowerBound, and ComparisonType.
//               IntervalIncludingUpperBound, the passed value contains a structure with the From 
//               and To fields that forms an interval to be compared to.
//          - Structure - Key - the session property Name (mentioned above). Value - the value to 
//            compare to. When you use this filter description, the comparison always checks for 
//            equality.
//   UseDictionary - Boolean - if True, the return value is generated using a dictionary. Otherwise, 
//                  the dictionary is not used.
//
// Returns:
//   - Array of (see ClusterAdministration.SessionProperties)
//   - Array from Map - that describe session properties in the rac utility notation if UseDictionary = False.
//
Function SessionsProperties(Val ClusterID, Val ClusterAdministrationParameters, Val InfobaseID, Val Filter = Undefined, Val UseDictionary = True) Export
	
	AdministrationManager = AdministrationManager(ClusterAdministrationParameters);
	
	Return AdministrationManager.SessionsProperties(
		ClusterID,
		ClusterAdministrationParameters,
		InfobaseID,
		Filter,
		UseDictionary);
	
EndFunction

// Returns descriptions of infobase connections.
//
// Parameters:
//   ClusterID - String - internal ID of a server cluster.
//   ClusterAdministrationParameters - (See ClusterAdministration.ClusterAdministrationParameters)
//   InfoBaseID - String - an internal ID of an infobase.
//   InfobaseAdministrationParameters - (See. ClusterAdministration.ClusterInfobaseAdministrationParameters)
//   Filter - Array from Structure - describe session filter criteria. Each array structure has the following fields:
//            * Property - String - property name to be used in the filter. For valid values, see
//               Return value of the ClusterAdministration.SessionProperties() function,
//            * ComparisonType - ComparisonType - value of system enumeration ComparisonType, the 
//               type of comparing the session values and the filter values. The following values are available:
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
//            * Value - Number, String, Data, Boolean, ValueList, Array, Structure - the value the 
//               matching session property value is compared with. For ComparisonType.InList and 
//               ComparisonType.NotInList, the passed values are ValueList or Array that contain the 
//               set of values to compare to. For ComparisonType.Interval, ComparisonType.IntervalIncludingBounds,
//               ComparisonType.IntervalIncludingLowerBound, and ComparisonType.
//               IntervalIncludingUpperBound, the passed value contains a structure with the From 
//               and To fields that forms an interval to be compared to.
//          - Structure - Key - the session property Name (mentioned above). Value - the value to 
//            compare to. When you use this filter description, the comparison always checks for 
//            equality.
//  UseDictionary - Boolean - if True, the return value is generated using a dictionary. Otherwise, 
//                  the dictionary is not used.
//
// Returns:
//   - Array of (see ClusterAdministration.ConnectionsProperties)
//   - Array from Map - that describe connection properties in the rac utility notation if UseDictionary = False.
//
Function ConnectionsProperties(Val ClusterID, Val ClusterAdministrationParameters, Val InfobaseID, Val InfobaseAdministrationParameters, Val Filter = Undefined, Val UseDictionary = False) Export
	
	AdministrationManager = AdministrationManager(ClusterAdministrationParameters);
	
	Return AdministrationManager.ConnectionsProperties(
		ClusterID,
		ClusterAdministrationParameters,
		InfobaseID,
		InfobaseAdministrationParameters,
		Filter,
		UseDictionary);
	
EndFunction

// Returns path to the console client of the administration server.
//
// Parameters:
//   ClusterAdministrationParameters - (See ClusterAdministration.ClusterAdministrationParameters)
//
// Returns:
//   String - a path to the console client of the administration server.
//
Function PathToAdministrationServerClient(Val ClusterAdministrationParameters) Export
	
	AdministrationManager = AdministrationManager(ClusterAdministrationParameters);
	
	Return AdministrationManager.PathToAdministrationServerClient();
	
EndFunction

#EndRegion

#Region Private

// Adds a new filter condition.
//
Procedure AddFilterCondition(Filter, Val Property, Val ValueComparisonType, Val Value) Export
	
	If Filter = Undefined Then
		
		If ValueComparisonType = ComparisonType.Equal Then
			
			Filter = New Structure;
			Filter.Insert(Property, Value);
			
		Else
			
			NewFilerItem = New Structure("Property, ComparisonType, Value", Property, ValueComparisonType, Value);
			
			Filter = New Array;
			Filter.Add(NewFilerItem);
			
		EndIf;
		
	ElsIf TypeOf(Filter) = Type("Structure") Then
		
		ExistingFilterItem = New Structure("Property, ComparisonType, Value", Filter.Key, ComparisonType.Equal, Filter.Value);
		NewFilerItem = New Structure("Property, ComparisonType, Value", Property, ValueComparisonType, Value);
		
		Filter = New Array;
		Filter.Add(ExistingFilterItem);
		Filter.Add(NewFilerItem);
		
	ElsIf TypeOf(Filter) = Type("Array") Then
		
		Filter.Add(New Structure("Property, ComparisonType, Value", Property, ValueComparisonType, Value));
		
	Else
		
		Raise NStr("ru = 'Неверный тип параметра Фильтр, ожидалось <Структура> или <Массив>'; en = 'Unexpected type of the Filter parameter. Expected type is <Structure> or <Array>.'; pl = 'Nieprawidłowy typ parametru Filtr, oczekiwana <Struktura> lub <Tablica>';de = 'Falscher Typ des Filterparameters, erwartet <Struktur> oder <Array>.';ro = 'Tipul incorect al parametrului Filter, se aștepta <Структура> sau <Массив>';tr = 'Filtre parametre türü yanlış, beklenen <Yapısı> veya <Dizi>'; es_ES = 'Tipo del parámetro Filtro es incorrecto, se esperaba <Estructura> o <Matriz>'");
		
	EndIf;
	
EndProcedure

// Checks whether object properties meet the requirements specified in the filter.
//
// Parameters:
//  ObjectToCheck - Structure - a structure containing fields:
//     * Key - String - the name of the property to be compared with the filter,
//     * Property - Arbitrary - the property value to be compared with the filter value,
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
//   Boolean - True if the object property values match the filter criteria.
//                  Otherwise, False.
//
Function CheckFilterConditions(Val ObjectToCheck, Val Filter = Undefined) Export
	
	If Filter = Undefined Or Filter.Count() = 0 Then
		Return True;
	EndIf;
	
	ConditionsMet = 0;
	
	For Each Condition In Filter Do
		
		If TypeOf(Condition) = Type("Structure") Then
			
			Field = Condition.Property;
			RequiredValue = Condition.Value;
			ValueComparisonType = Condition.ComparisonType;
			
		ElsIf TypeOf(Condition) = Type("KeyAndValue") Then
			
			Field = Condition.Key;
			RequiredValue = Condition.Value;
			ValueComparisonType = ComparisonType.Equal;
			
		Else
			
			Raise NStr("ru = 'Неверный тип значения параметра Фильтр, ожидалось <Структура> или <КлючИЗначение>'; en = 'Unexpected type of the Filter parameter. Expected type is <Structure> or <KeyAndValue>.'; pl = 'Nieprawidłowy typ znaczenia parametru Filtr, oczekiwana <Struktura> lub <КлючИЗначение>';de = 'Falscher Typ des Wertes des Filterparameters, erwartet <Struktur> oder <SchlüsselUndWert>';ro = 'Tipul incorect al parametrului Filter, se aștepta <Структура> sau <КлючИЗначение>';tr = 'Filtre parametre türü yanlış, beklenen <Yapısı> veya <AnahtarVeDeğeri>'; es_ES = 'Tipo del valor del parámetro Filtro es incorrecto, se esperaba <Estructura> o <КлючИЗначение>'");
			
		EndIf;
		
		ValueToCheck = ObjectToCheck[Field];
		ConditionMet = CheckFilterCondition(ValueToCheck, ValueComparisonType, RequiredValue);
		
		If ConditionMet Then
			ConditionsMet = ConditionsMet + 1;
		Else
			Break;
		EndIf;
		
	EndDo;
	
	Return ConditionsMet = Filter.Count();
	
EndFunction

// Checks whether values meet the requirements specified in the filter.
//
// Parameters:
//   ValueToCheck - Number, String, Data, Boolean - the value to compare with the criteria.
//   ValueComparisonType - value of system enumeration ComparisonType, the type of comparing the 
//      connection values and the filter values. The following values are available:
//         ComparisonType.Equal,
//         ComparisonType.NotEqual,
//         ComparisonType.Greater (for numeric values only),
//         ComparisonType.GreaterOrEqual (for numeric values only),
//         ComparisonType.Less (for numeric values only),
//         ComparisonType.LessOrEqual (for numeric values only),
//         ComparisonType.InList,
//         ComparisonType.NotInList,
//         ComparisonType.Interval (for numeric values only),
//         ComparisonType.IntervalIncludingBounds (for numeric values only),
//         ComparisonType.IntervalIncludingLowerBound (for numeric values only),
//         ComparisonType.IntervalIncludingUpperBound (for numeric values only),
//   Value - Number, String, Data, Boolean, ValueList, Array, Structure - the value the value to 
//      check is compared with. For ComparisonType.InList and ComparisonType.NotInList, the passed 
//      values are ValueList or Array that contain the set of values to compare to.
//       For ComparisonType.Interval, ComparisonType.IntervalIncludingBounds,
//      ComparisonType.IntervalIncludingLowerBound, and ComparisonType.IntervalIncludingUpperBound, 
//      the passed value contains a structure with the From and To fields that forms an interval to 
//      be compared to.
//
// Returns: Boolean, True if the value match the criteria. Otherwise, False.
//
Function CheckFilterCondition(Val ValueToCheck, Val ValueComparisonType, Val Value)
	
	If ValueComparisonType = ComparisonType.Equal Then
		
		Return ValueToCheck = Value;
		
	ElsIf ValueComparisonType = ComparisonType.NotEqual Then
		
		Return ValueToCheck <> Value;
		
	ElsIf ValueComparisonType = ComparisonType.Greater Then
		
		Return ValueToCheck > Value;
		
	ElsIf ValueComparisonType = ComparisonType.GreaterOrEqual Then
		
		Return ValueToCheck >= Value;
		
	ElsIf ValueComparisonType = ComparisonType.Less Then
		
		Return ValueToCheck < Value;
		
	ElsIf ValueComparisonType = ComparisonType.LessOrEqual Then
		
		Return ValueToCheck <= Value;
		
	ElsIf ValueComparisonType = ComparisonType.InList Then
		
		If TypeOf(Value) = Type("ValueList") Then
			
			Return Value.FindByValue(ValueToCheck) <> Undefined;
			
		ElsIf TypeOf(Value) = Type("Array") Then
			
			Return Value.Find(ValueToCheck) <> Undefined;
			
		EndIf;
		
	ElsIf ValueComparisonType = ComparisonType.NotInList Then
		
		If TypeOf(Value) = Type("ValueList") Then
			
			Return Value.FindByValue(ValueToCheck) = Undefined;
			
		ElsIf TypeOf(Value) = Type("Array") Then
			
			Return Value.Find(ValueToCheck) = Undefined;
			
		EndIf;
		
	ElsIf ValueComparisonType = ComparisonType.Interval Then
		
		Return ValueToCheck > Value.From AND ValueToCheck < Value.EndDate;
		
	ElsIf ValueComparisonType = ComparisonType.IntervalIncludingBounds Then
		
		Return ValueToCheck >= Value.From AND ValueToCheck <= Value.EndDate;
		
	ElsIf ValueComparisonType = ComparisonType.IntervalIncludingLowerBound Then
		
		Return ValueToCheck >= Value.From AND ValueToCheck < Value.EndDate;
		
	ElsIf ValueComparisonType = ComparisonType.IntervalIncludingUpperBound Then
		
		Return ValueToCheck > Value.From AND ValueToCheck <= Value.EndDate;
		
	EndIf;
	
EndFunction

// Returns the common module that implements a programming interface for administrating the server 
// cluster that corresponds the server cluster connection type.
//
// Parameters:
//   ClusterAdministrationParameters - Structure - the structure that describes parameters for 
//                  connecting the server cluster. For details, see ClusterAdministration. ClusterAdministrationParameters().
//
// Returns: CommonModule.
//
Function AdministrationManager(Val AdministrationParameters)
	
	If AdministrationParameters.ConnectionType = "COM" Then
		
		Return ClusterAdministrationCOM;
		
	ElsIf AdministrationParameters.ConnectionType = "RAS" Then
		
		Return ClusterAdministrationRAS;
		
	Else
		
		Raise StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Неизвестный тип параметра ПараметрыАдминистрирования (%1), ожидалось ""COM"" или ""RAS""'; en = 'Unexpected type of the AdministrationParameters parameter (%1). Expected type is COM or RAS.'; pl = 'Nieznany typ parametru AdministrationParameters (%1), oczekiwano ""COM"" albo ""RAS""';de = 'Unbekannter Typ des Parameters AdministrationParameters (%1), ""COM"" oder ""RAS"" wurde erwartet';ro = 'Tipul incorect al parametrului AdministrationParameters (%1), se aștepta ""COM"" sau ""RAS""';tr = 'AdministrationParameters parametresinin bilinmeyen türü (%1), beklenen ""COM"" veya ""RAS""'; es_ES = 'Tipo desconocido del parámetro AdministrationParameters (%1), se esperaba ""COM"" o ""RAS""'"), 
			AdministrationParameters.ConnectionType);
		
	EndIf;
	
EndFunction

// Returns the date that is an empty date in the server cluster registry.
//
// Returns:
//   Date - date and time.
//
Function EmptyDate() Export
	
	Return Date(1, 1, 1, 0, 0, 0);
	
EndFunction

// Supplements the session information according to the information from the lock description
//
// Parameters:
//  SessionData			- Map - a structure that accumulates session data by SessionKey as a structure with  DBLockMode and Separator fields
//  LockText			- String - source lock text received from the lock list (RAS/COM)
//  SessionKey				- Arbitrary - session ID
//  InfoBaseName	- String - the sought infobase name, other IB sessions are ignored
//
Procedure SessionDataFromLock(SessionData, Val LockText, Val SessionKey, Val InfoBaseName) Export
	
	TextLower = Lower(LockText);
	
	TextLower = StrReplace(TextLower, "db(",			"db(");
	TextLower = StrReplace(TextLower, "(session,",		"(session,");
	TextLower = StrReplace(TextLower, ",shared",		",shared");
	TextLower = StrReplace(TextLower, ",exceptional",	",exclusive");
	TextLower = StrReplace(TextLower, ",exclusive",	",exclusive");
	
	If Left(TextLower, 9) = "db(session," Then
		LockValuesAsString = Mid(TextLower, StrFind(TextLower, "(") + 1, StrFind(TextLower, ")") - StrFind(TextLower, "(") - 1);
		LockValues = StringFunctionsClientServer.SplitStringIntoSubstringsArray(LockValuesAsString, ",");
		If LockValues.Count() >= 3
			AND LockValues[0] = "session"
			AND LockValues[1] = Lower(InfoBaseName) Then
			
			If StrFind(LockValuesAsString, "'") > 0 Then
				SeparatorValue = Mid(LockValuesAsString, StrFind(LockValuesAsString, "'") + 1);
				SeparatorValue = Left(SeparatorValue, StrFind(SeparatorValue, "'") - 1);
			Else
				SeparatorValue = "";
			EndIf;
			
			SessionData[SessionKey] = New Structure("DBLockMode,Separator", LockValues[2], SeparatorValue);
			
		EndIf;
	EndIf;
	
EndProcedure

#EndRegion
