///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Internal

// Gets N worst performance measurements over a period.
// Parameters:
//	StartDate - DateTime - sampling start date.
//	EndDate - DateTime - sampling end date.
//	TopApdexCount - Number - number of worst measurements. If zero, returns all measurements.
//
Function GetAPDEXTop(StartDate, EndDate, AggregationPeriod, TopApdexCount) Export
	Return InformationRegisters.TimeMeasurements.GetAPDEXTop(StartDate, EndDate, AggregationPeriod, TopApdexCount);
EndFunction

// Gets N worst technological performance measurements over a period.
// Parameters:
//	StartDate - DateTime - sampling start date.
//	EndDate - DateTime - sampling end date.
//	TopApdexCount - Number - number of worst measurements. If zero, returns all measurements.
//
Function GetTopTechnologicalAPDEX(StartDate, EndDate, AggregationPeriod, TopApdexCount) Export
	Return InformationRegisters.TimeMeasurementsTechnological.GetAPDEXTop(StartDate, EndDate, AggregationPeriod, TopApdexCount);
EndFunction

////////////////////////////////////////////////////////////////////////////////
// Configuration subsystems event handlers.

// See InfobaseUpdateSSL.OnAddUpdateHandlers. 
Procedure OnAddUpdateHandlers(Handlers) Export
	
	Handler = Handlers.Add();
	Handler.InitialFilling = True;
	Handler.Procedure = "PerformanceMonitorInternal.InitialFilling";
	
	Handler = Handlers.Add();
	Handler.Version = "2.3.1.38";
	Handler.Procedure = "PerformanceMonitorInternal.FillHashName";
	
	Handler = Handlers.Add();
	Handler.ExclusiveMode = True;
	Handler.Version = "2.3.1.74";
	Handler.Procedure = "PerformanceMonitorInternal.FillHashName";
	
	
	Handler = Handlers.Add();
	Handler.ExclusiveMode = True;
	Handler.SharedData = True;
	Handler.Version = "2.3.3.45";
	Handler.Procedure = "PerformanceMonitorInternal.SetConstantValues_2_3_3_45";
	
EndProcedure

// See CommonOverridable.OnAddSessionParametersSettingHandlers. 
Procedure OnAddSessionParameterSettingHandlers(Handlers) Export
	
	Handlers.Insert("TimeMeasurementComment", "PerformanceMonitorInternal.SessionParametersSetting");
	
EndProcedure

// See UsersOverridable.OnDefineRolesAssignment. 
Procedure OnDefineRoleAssignment(RolesAssignment) Export
	
	// ForSystemUsersOnly.
	RolesAssignment.ForSystemUsersOnly.Add(
		Metadata.Roles.PerformanceSetupAndMonitoring.Name);
	
EndProcedure

// See ScheduledJobsOverridable.OnDefineScheduledJobsSettings. 
Procedure OnDefineScheduledJobSettings(Dependencies) Export
	Dependence = Dependencies.Add();
	Dependence.ScheduledJob = Metadata.ScheduledJobs.PerformanceMonitorDataExport;
	Dependence.UseExternalResources = True;
EndProcedure

// See SafeModeManagerOverridable.OnFillPermissionsToAccessExternalResources. 
Procedure OnFillPermissionsToAccessExternalResources(PermissionRequests) Export
	
	SaaSExists = SubsystemExists("StandardSubsystems.SaaS");
	If SaaSExists Then
		ModuleSaaS = CommonModule("SaaS");
		If ModuleSaaS.DataSeparationEnabled() AND ModuleSaaS.SeparatedDataUsageAvailable() Then
			Return;
		EndIf;
	EndIf;
	
	DirectoriesForExport = PerformanceMonitorDataExportDirectories();
	If DirectoriesForExport = Undefined Then
		Return;
	EndIf;
	
	URIStructure = PerformanceMonitorClientServer.URIStructure(DirectoriesForExport.FTPExportDirectory);
	DirectoriesForExport.Insert("FTPExportDirectory", URIStructure.ServerName);
	If ValueIsFilled(URIStructure.Port) Then
		DirectoriesForExport.Insert("FTPExportDirectoryPort", URIStructure.Port);
	EndIf;
    
    CoreAvailable = SubsystemExists("StandardSubsystems.Core");
	SafeModeManagerAvailable = SubsystemExists("StandardSubsystems.SecurityProfiles");
	
	If CoreAvailable AND SafeModeManagerAvailable Then
		ModuleSafeModeManager = CommonModule("SafeModeManager");
		ModuleCommon = CommonModule("Common");
		PermissionRequests.Add(
			ModuleSafeModeManager.RequestToUseExternalResources(
				PermissionsToUseServerResources(DirectoriesForExport), 
				ModuleCommon.MetadataObjectID("Constant.RunPerformanceMeasurements")));
	EndIf;
			
EndProcedure

// See CommonOverridable.OnAddClientParametersOnStart. 
Procedure OnAddClientParametersOnStart(Parameters) Export
	
	ClientRunParameters = New Structure("RecordPeriod, RunPerformanceMeasurements");
	
	SetPrivilegedMode(True);
	CurrentPeriod = Constants.PerformanceMonitorRecordPeriod.Get();
	ClientRunParameters.RecordPeriod = ?(CurrentPeriod >= 1, CurrentPeriod, 60);
	ClientRunParameters.RunPerformanceMeasurements = Constants.RunPerformanceMeasurements.Get();

	Parameters.Insert("PerformanceMonitor", New FixedStructure(ClientRunParameters));
	
EndProcedure

// See ReportsOptionsOverridable.CustomizeReportsOptions. 
Procedure OnSetUpReportsOptions(Settings) Export
	ModuleReportsOptions = CommonModule("ReportsOptions");
	ModuleReportsOptions.CustomizeReportInManagerModule(Settings, Metadata.Reports.PerformanceMonitor);
EndProcedure

#EndRegion

#Region Private

// See CommonOverridable.OnAddSessionParametersSettingHandlers. 
Procedure SessionParametersSetting(ParameterName, SpecifiedParameters) Export
	
	// Session parameters must be initialized without using application parameters.
	
	If ParameterName = "TimeMeasurementComment" Then
		SessionParameters.TimeMeasurementComment = GetTimeMeasurementComment();
		SpecifiedParameters.Add("TimeMeasurementComment");
		Return;
	EndIf;
EndProcedure

Procedure InitialFilling() Export
	
	SaaSExists = SubsystemExists("StandardSubsystems.SaaS");
	If SaaSExists Then
		ModuleSaaS = CommonModule("SaaS");
		If ModuleSaaS.DataSeparationEnabled() Then
			Return;
		EndIf;
	EndIf;
	
	Constants.MeasurementsCountInExportPackage.Set(1000);
	Constants.PerformanceMonitorRecordPeriod.Set(300);
	Constants.KeepMeasurementsPeriod.Set(100);
		
EndProcedure

// Sets the "TimeMeasurementComment" session parameter
// at startup.
//
Function GetTimeMeasurementComment()
	
	TimeMeasurementComment = New Map;
	
	SystemInfo = New SystemInfo();
	ApplicationVersion = SystemInfo.AppVersion;
		
	TimeMeasurementComment.Insert("Platform", ApplicationVersion);
	TimeMeasurementComment.Insert("Conf", Metadata.Synonym);
	TimeMeasurementComment.Insert("ConfVer", Metadata.Version);
	
	DataSeparation = InfoBaseUsers.CurrentUser().DataSeparation;
	DataSeparationValues = New Array;
	If DataSeparation.Count() <> 0 Then
		For Each CurSeparator In DataSeparation Do
			DataSeparationValues.Add(CurSeparator.Value);
		EndDo;
	Else
		DataSeparationValues.Add(0);
	EndIf;
	TimeMeasurementComment.Insert("Separation", DataSeparationValues);
	
	JSONWriter = New JSONWriter;
	JSONWriter.SetString(New JSONWriterSettings(JSONLineBreak.None));
	WriteJSON(JSONWriter, TimeMeasurementComment);
		
	Return JSONWriter.Close();
	
EndFunction

// For internal use only.
Function RequestToUseExternalResources(Directories) Export
	If SubsystemExists("StandardSubsystems.SecurityProfiles") Then
		ModuleSafeModeManager = CommonModule("SafeModeManager");
		ModuleCommon = CommonModule("Common");
		Return ModuleSafeModeManager.RequestToUseExternalResources(
					PermissionsToUseServerResources(Directories),
					ModuleCommon.MetadataObjectID("Constant.RunPerformanceMeasurements"));
	EndIf;
EndFunction

////////////////////////////////////////////////////////////////////////////////
// Internal export procedures and functions.

// Finds and returns the scheduled job for exporting time measurements.
//
// Returns:
//  ScheduledJob - ScheduledJob.PerformanceMonitorDataExport - retrieved job.
//
Function PerformanceMonitorDataExportScheduledJob() Export
	
	SetPrivilegedMode(True);
	Jobs = ScheduledJobs.GetScheduledJobs(
		New Structure("Metadata", "PerformanceMonitorDataExport"));
	If Jobs.Count() = 0 Then
		Job = ScheduledJobs.CreateScheduledJob(
			Metadata.ScheduledJobs.PerformanceMonitorDataExport);
		Job.Write();
		Return Job;
	Else
		Return Jobs[0];
	EndIf;
		
EndFunction

// Returns directories containing measurement export files.
//
// Parameters:
//	No
//
// Returns:
//    Structure
//        "ExecuteExportToFTPDirectory"              - Boolean - indicates whether export to an FTP directory was performed.
//        "FTPExportDirectory"                - String - an FTP directory.
//        "ExecuteExportToLocalDirectory" - Boolean - indicates whether export to a local directory was performed.
//        "ЛокальныйExportDirectory"          - String - a local directory.
//
Function PerformanceMonitorDataExportDirectories() Export
	
	Job = PerformanceMonitorDataExportScheduledJob();
	Directories = New Structure;
	If Job.Parameters.Count() > 0 Then
		Directories = Job.Parameters[0];
	EndIf;
	
	If TypeOf(Directories) <> Type("Structure") OR Directories.Count() = 0 Then
		Return Undefined;
	EndIf;
	
	ReturnValue = New Structure;
	ReturnValue.Insert("DoExportToFTPDirectory");
	ReturnValue.Insert("FTPExportDirectory");
	ReturnValue.Insert("DoExportToLocalDirectory");
	ReturnValue.Insert("LocalExportDirectory");
	
	JobKeyToItems = New Structure;
	FTPItems = New Array;
	FTPItems.Add("DoExportToFTPDirectory");
	FTPItems.Add("FTPExportDirectory");
	
	LocalItems = New Array;
	LocalItems.Add("DoExportToLocalDirectory");
	LocalItems.Add("LocalExportDirectory");
	
	JobKeyToItems.Insert(PerformanceMonitorClientServer.FTPExportDirectoryJobKey(), FTPItems);
	JobKeyToItems.Insert(PerformanceMonitorClientServer.LocalExportDirectoryJobKey(), LocalItems);
	ExecuteExport = False;
	For Each ItemsKeyName In JobKeyToItems Do
		KeyName = ItemsKeyName.Key;
		ItemsToEdit = ItemsKeyName.Value;
		ItemNumber = 0;
		For Each ItemName In ItemsToEdit Do
			Value = Directories[KeyName][ItemNumber];
			ReturnValue[ItemName] = Value;
			If ItemNumber = 0 Then 
				ExecuteExport = ExecuteExport OR Value;
			EndIf;
			ItemNumber = ItemNumber + 1;
		EndDo;
	EndDo;
	
	Return ReturnValue;
	
EndFunction

// Returns a reference to the "Overall performance" item,
// i.e. the predefined OverallSystemPerformance item, if it exists,
// or an empty reference otherwise.
//
// Parameters:
//	No
// Returns:
//	CatalogRef.KeyOperations
//
Function GetOverallSystemPerformanceItem() Export
	
	PredefinedKO = Metadata.Catalogs.KeyOperations.GetPredefinedNames();
	HasPredefinedItem = ?(PredefinedKO.Find("OverallSystemPerformance") <> Undefined, True, False);
	
	QueryText = 
	"SELECT TOP 1
	|	KeyOperations.Ref,
	|	2 AS Priority
	|FROM
	|	Catalog.KeyOperations AS KeyOperations
	|WHERE
	|	KeyOperations.Name = ""OverallSystemPerformance""
	|	AND NOT KeyOperations.DeletionMark
	|
	|UNION ALL
	|
	|SELECT TOP 1
	|	VALUE(Catalog.KeyOperations.EmptyRef),
	|	3
	|
	|ORDER BY
	|	Priority";
	
	If HasPredefinedItem Then
		QueryText = 
		"SELECT TOP 1
		|	KeyOperations.Ref,
		|	1 AS Priority
		|FROM
		|	Catalog.KeyOperations AS KeyOperations
		|WHERE
		|	KeyOperations.PredefinedDataName = ""OverallSystemPerformance""
		|	AND NOT KeyOperations.DeletionMark
		|
		|UNION ALL
		|" + QueryText;
	EndIf;
	
	Query = New Query;
	Query.Text = QueryText;
	Query.SetParameter("KeyOperations", PredefinedKO);
	QueryResult = Query.Execute();
	Selection = QueryResult.Select();
	Selection.Next();
	
	Return Selection.Ref;
	
EndFunction

Procedure SetConstantValues_2_3_3_45() Export
	
	Constants.MeasurementsCountInExportPackage.Set(1000);
	Constants.KeepMeasurementsPeriod.Set(3650);
	
	ScheduledJob = ScheduledJobs.FindPredefined(Metadata.ScheduledJobs.ClearTimeMeasurements);
	If ScheduledJob <> Undefined Then
		ScheduledJob.Use = Constants.RunPerformanceMeasurements.Get();
		ScheduledJob.Write();
	EndIf
		
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Local internal procedures and functions.

// Creates an array of permissions to export measurement data.
// 
// Parameters - DirectoriesForExport - Structure
//
// Returns:
//	Array
Function PermissionsToUseServerResources(Directories)
	
	Permissions = New Array;
	
	CoreAvailable = SubsystemExists("StandardSubsystems.Core");
	If CoreAvailable Then
		ModuleSafeModeManager = CommonModule("SafeModeManager");
		If Directories <> Undefined Then
			If Directories.Property("DoExportToLocalDirectory") AND Directories.DoExportToLocalDirectory = True Then
				If Directories.Property("LocalExportDirectory") AND ValueIsFilled(Directories.LocalExportDirectory) Then
					Item = ModuleSafeModeManager.PermissionToUseFileSystemDirectory(
						Directories.LocalExportDirectory,
						True,
						True,
						NStr("ru = 'Сетевой каталог для экспорта результатов замеров производительности.'; en = 'Network directory for exporting performance measurement results.'; pl = 'Network directory for exporting performance measurement results.';de = 'Network directory for exporting performance measurement results.';ro = 'Network directory for exporting performance measurement results.';tr = 'Network directory for exporting performance measurement results.'; es_ES = 'Network directory for exporting performance measurement results.'"));
					Permissions.Add(Item);
				EndIf;
			EndIf;
			
			If Directories.Property("DoExportToFTPDirectory") AND Directories.DoExportToFTPDirectory = True Then
				If Directories.Property("FTPExportDirectory") AND ValueIsFilled(Directories.FTPExportDirectory) Then
					Item = ModuleSafeModeManager.PermissionToUseInternetResource(
						"FTP",
						Directories.FTPExportDirectory,
						?(Directories.Property("FTPExportDirectoryPort"), Directories.FTPExportDirectoryPort, Undefined),
						NStr("ru = 'FTP-ресурс для экспорта результатов замеров производительности.'; en = 'FTP resource for exporting performance measurement results.'; pl = 'FTP resource for exporting performance measurement results.';de = 'FTP resource for exporting performance measurement results.';ro = 'FTP resource for exporting performance measurement results.';tr = 'FTP resource for exporting performance measurement results.'; es_ES = 'FTP resource for exporting performance measurement results.'"));
					Permissions.Add(Item);
				EndIf;
			EndIf;
		EndIf;
	EndIf;
	
	Return Permissions;
EndFunction

Procedure FillHashName() Export
	
	BeginTransaction();
	
	Try
		Lock = New DataLock;
		LockItem = Lock.Add("Catalog.KeyOperations");
		LockItem.Mode = DataLockMode.Exclusive;
		Lock.Lock();
		
		Query = New Query;
		Query.Text = "
		|SELECT
		|	Ref
		|FROM
		|	Catalog.KeyOperations
		|WHERE
		|	NameHash = """"
		|";
		
		Result = Query.Execute();
		Selection = Result.Select();
		While Selection.Next() Do
			CatObject = Selection.Ref.GetObject();
						
			MD5Hash = New DataHashing(HashFunction.MD5);
			MD5Hash.Append(CatObject.Name);
			NameHashTmp = MD5Hash.HashSum;
			CatObject.NameHash = StrReplace(String(NameHashTmp), " ", "");
            CatObject.AdditionalProperties.Insert(PerformanceMonitorClientServer.DoNotCheckPriority(), True);
			
			CatObject.Write();
		EndDo;
		
		CommitTransaction();
	Except
		RollbackTransaction();
 		WriteLogEvent(NStr("ru = 'Выполнение операции'; en = 'Performing transaction'; pl = 'Performing transaction';de = 'Performing transaction';ro = 'Performing transaction';tr = 'Performing transaction'; es_ES = 'Performing transaction'", Metadata.DefaultLanguage.LanguageCode), EventLogLevel.Error,,, DetailErrorDescription(ErrorInfo()));
		Raise;
	EndTry;
	
EndProcedure

#Region CommonCopy

// Returns True if the "functional" subsystem exists in the configuration.
// Intended for calling optional subsystems (conditional calls).
//
// A subsystem is considered functional if its "Include in command interface" check box is cleared.
//
// Parameters:
//  FullSubsystemName - String - the full name of the subsystem metadata object without the 
//                        "Subsystem." part, case-sensitive.
//                        Example: "StandardSubsystems.ReportOptions".
//
// Example:
//
//  If Common.SubsystemExists("StandardSubsystems.ReportOptions") Then
//  	ModuleReportOptions = Common.CommonModule("ReportOptions");
//  	ModuleReportOptions.<Method name>();
//  EndIf.
//
// Returns:
//  Boolean.
//
Function SubsystemExists(FullSubsystemName) Export
	
	If CoreAvailable() Then
		ModuleCommon = CalculateInSafeMode("Common");
		Return ModuleCommon.SubsystemExists(FullSubsystemName);
	Else
		SubsystemsNames = PerformanceMonitorCached.SubsystemsNames();
		Return SubsystemsNames.Get(FullSubsystemName) <> Undefined;
	EndIf;
	
EndFunction

// Returns common basic functionality parameters.
//
// Returns:
//  Structure - structure with the following properties:
//      * PersonalSettingsFormName            - String - name of the form for editing personal settings.
//                                                           Previously, it used to be defined in
//                                                           CommonOverridable.PersonalSettingsFormName.
//      * MinPlatformVersion    - String - the full platform version required to start the application.
//                                                           For example, "8.3.4.365".
//                                                           Previously, it used to be defined in
//                                                           CommonOverridable.GetMinRequiredPlatformVersion
//      * MustExit               - Boolean - False by default.
//      * AskConfirmationOnExit - Boolean - True by default. If False, the exit confirmation is not 
//                                                                  requested when exiting the 
//                                                                  application, if it is not 
//                                                                  clearly enabled in the personal application settings.
//      * DisableMetadataObjectsIDs - Boolean - disables completing the MetadataObjectIDs and 
//              ExtensionObjectsIDs catalogs, as well as the export/import procedure for DIB nodes.
//              For partial embedding certain library functions into the configuration without enabling support.
//      * DisabledSubsystems                     - Map - use to disable certain subsystems virtually 
//                                                                  for testing purposes.
//                                                                  If the subsystem is disabled, 
//                                                                  Common.SubsystemExists returns False. 
//                                                                  Set the map's key to the name of the subsystem to be disabled and value to True.
//
Function CommonCoreParameters() Export
	
	CommonParameters = New Structure;
	CommonParameters.Insert("DisabledSubsystems", New Map);
	
	Return CommonParameters;
	
EndFunction

Function CoreAvailable()
	
	StandardSubsystemsAvailable = Metadata.Subsystems.Find("StandardSubsystems");
	
	If StandardSubsystemsAvailable = Undefined Then
		Return False;
	Else
		If StandardSubsystemsAvailable.Subsystems.Find("Core") = Undefined Then
			Return False;
		Else
			Return True;
		EndIf;
	EndIf;
	
EndFunction

// Generates and displays the message that can relate to a form item.
//
// Parameters:
//  UserMessageText - String - a mesage text.
//  DataKey - AnyRef - the infobase record key or object that message refers to.
//  Field - String - a form attribute description.
//  DataPath - String - a data path (a path to a form attribute).
//  Cancel - Boolean - an output parameter. Always True.
//
// Example:
//
//  1. Showing the message associated with the object attribute near the managed form field
//  CommonClient.InformUser(
//   NStr("en = 'Error message.'"), ,
//   "FieldInFormAttributeObject",
//   "Object");
//
//  An alternative variant of using in the object form module
//  CommonClient.InformUser(
//   NStr("en = 'Error message.'"), ,
//   "Object.FieldInFormAttributeObject");
//
//  2. Showing a message for the form attribute, next to the managed form field:
//  CommonClient.InformUser(
//   NStr("en = 'Error message.'"), ,
//   "FormAttributeName");
//
//  3. To display a message associated with an infobase object:
//  CommonClient.InformUser(
//   NStr("en = 'Error message.'"), InfobaseObject, "Responsible person",,Cancel);
//
//  4. To display a message from a link to an infobase object:
//  CommonClient.InformUser(
//   NStr("en = 'Error message.'"), Reference, , , Cancel);
//
//  Scenarios of incorrect using:
//   1. Passing DataKey and DataPath parameters at the same time.
//   2. Passing a value of an illegal type to the DataKey parameter.
//   3. Specifying a reference without specifying a field (and/or a data path).
//
Procedure MessageToUser( 
	Val MessageToUserText,
	Val DataKey = Undefined,
	Val Field = "",
	Val DataPath = "",
	Cancel = False) Export
	
	IsObject = False;
	
	If DataKey <> Undefined
		AND XMLTypeOf(DataKey) <> Undefined Then
		
		ValueTypeAsString = XMLTypeOf(DataKey).TypeName;
		IsObject = StrFind(ValueTypeAsString, "Object.") > 0;
	EndIf;
	
	Message = New UserMessage;
	Message.Text = MessageToUserText;
	Message.Field = Field;
	
	If IsObject Then
		Message.SetData(DataKey);
	Else
		Message.DataKey = DataKey;
	EndIf;
	
	If NOT IsBlankString(DataPath) Then
		Message.DataPath = DataPath;
	EndIf;
	
	Message.Message();
	
	Cancel = True;
	
EndProcedure

// Returns a reference to the common module by the name.
//
// Parameters:
//  Name          - String - common module name, for example:
//                 "Common",
//                 "CommonClient".
//
// Returns:
//  CommonModule.
//
Function CommonModule(Name) Export
	
	If CoreAvailable() Then
		ModuleCommon = CalculateInSafeMode("Common");
		Module = ModuleCommon.CommonModule(Name);
	Else
		If Metadata.CommonModules.Find(Name) <> Undefined Then
			Module = CalculateInSafeMode(Name);
		ElsIf StrOccurrenceCount(Name, ".") = 1 Then
			Return ServerManagerModule(Name);
		Else
			Module = Undefined;
		EndIf;
		
		If TypeOf(Module) <> Type("CommonModule") Then
			ExceptionMessage = NStr("ru = 'Общий модуль ""%1"" не найден.'; en = 'Common module ""%1"" is not found.'; pl = 'Common module ""%1"" is not found.';de = 'Common module ""%1"" is not found.';ro = 'Common module ""%1"" is not found.';tr = 'Common module ""%1"" is not found.'; es_ES = 'Common module ""%1"" is not found.'");
			Raise StrReplace(ExceptionMessage, "%1", Name);
		EndIf;
	EndIf;
	
	Return Module;
	
EndFunction

// Returns a server manager module by object name.
Function ServerManagerModule(Name)
	ObjectFound = False;
	
	NameParts = StrSplit(Name, ".");
	If NameParts.Count() = 2 Then
		
		KindName = Upper(NameParts[0]);
		ObjectName = NameParts[1];
		
		If KindName = Upper(ConstantsTypeName()) Then
			If Metadata.Constants.Find(ObjectName) <> Undefined Then
				ObjectFound = True;
			EndIf;
		ElsIf KindName = Upper(InformationRegistersTypeName()) Then
			If Metadata.InformationRegisters.Find(ObjectName) <> Undefined Then
				ObjectFound = True;
			EndIf;
		ElsIf KindName = Upper(AccumulationRegistersTypeName()) Then
			If Metadata.AccumulationRegisters.Find(ObjectName) <> Undefined Then
				ObjectFound = True;
			EndIf;
		ElsIf KindName = Upper(AccountingRegistersTypeName()) Then
			If Metadata.AccountingRegisters.Find(ObjectName) <> Undefined Then
				ObjectFound = True;
			EndIf;
		ElsIf KindName = Upper(CalculationRegistersTypeName()) Then
			If Metadata.CalculationRegisters.Find(ObjectName) <> Undefined Then
				ObjectFound = True;
			EndIf;
		ElsIf KindName = Upper(CatalogsTypeName()) Then
			If Metadata.Catalogs.Find(ObjectName) <> Undefined Then
				ObjectFound = True;
			EndIf;
		ElsIf KindName = Upper(DocumentsTypeName()) Then
			If Metadata.Documents.Find(ObjectName) <> Undefined Then
				ObjectFound = True;
			EndIf;
		ElsIf KindName = Upper(ReportsTypeName()) Then
			If Metadata.Reports.Find(ObjectName) <> Undefined Then
				ObjectFound = True;
			EndIf;
		ElsIf KindName = Upper(DataProcessorsTypeName()) Then
			If Metadata.DataProcessors.Find(ObjectName) <> Undefined Then
				ObjectFound = True;
			EndIf;
		ElsIf KindName = Upper(BusinessProcessesTypeName()) Then
			If Metadata.BusinessProcesses.Find(ObjectName) <> Undefined Then
				ObjectFound = True;
			EndIf;
		ElsIf KindName = Upper(DocumentJournalsTypeName()) Then
			If Metadata.DocumentJournals.Find(ObjectName) <> Undefined Then
				ObjectFound = True;
			EndIf;
		ElsIf KindName = Upper(TasksTypeName()) Then
			If Metadata.Tasks.Find(ObjectName) <> Undefined Then
				ObjectFound = True;
			EndIf;
		ElsIf KindName = Upper(ChartsOfAccountsTypeName()) Then
			If Metadata.ChartsOfAccounts.Find(ObjectName) <> Undefined Then
				ObjectFound = True;
			EndIf;
		ElsIf KindName = Upper(ExchangePlansTypeName()) Then
			If Metadata.ExchangePlans.Find(ObjectName) <> Undefined Then
				ObjectFound = True;
			EndIf;
		ElsIf KindName = Upper(ChartsOfCharacteristicTypesTypeName()) Then
			If Metadata.ChartsOfCharacteristicTypes.Find(ObjectName) <> Undefined Then
				ObjectFound = True;
			EndIf;
		ElsIf KindName = Upper(ChartsOfCalculationTypesTypeName()) Then
			If Metadata.ChartsOfCalculationTypes.Find(ObjectName) <> Undefined Then
				ObjectFound = True;
			EndIf;
		EndIf;
		
	EndIf;
	
	If Not ObjectFound Then
		ExceptionMessage = NStr("ru = 'Объект метаданных ""%1"" не найден,
			|либо для него не поддерживается получение модуля менеджера.'; 
			|en = 'Metadata object ""%1"" is not found
			|or it does not support getting the manager module.'; 
			|pl = 'Metadata object ""%1"" is not found
			|or it does not support getting the manager module.';
			|de = 'Metadata object ""%1"" is not found
			|or it does not support getting the manager module.';
			|ro = 'Metadata object ""%1"" is not found
			|or it does not support getting the manager module.';
			|tr = 'Metadata object ""%1"" is not found
			|or it does not support getting the manager module.'; 
			|es_ES = 'Metadata object ""%1"" is not found
			|or it does not support getting the manager module.'");
		Raise StrReplace(ExceptionMessage, "%1", Name);
	EndIf;
	
	Module = CalculateInSafeMode(Name);
	
	Return Module;
EndFunction

// Returns a value for identification of the Information registers type.
//
// Returns:
//  String.
//
Function InformationRegistersTypeName()
	
	Return "InformationRegisters";
	
EndFunction

// Returns a value for identification of the Accumulation registers type.
//
// Returns:
//  String.
//
Function AccumulationRegistersTypeName()
	
	Return "AccumulationRegisters";
	
EndFunction

// Returns a value for identification of the Accounting registers type.
//
// Returns:
//  String.
//
Function AccountingRegistersTypeName()
	
	Return "AccountingRegisters";
	
EndFunction

// Returns a value for identification of the Calculation registers type.
//
// Returns:
//  String.
//
Function CalculationRegistersTypeName()
	
	Return "CalculationRegisters";
	
EndFunction

// Returns a value for identification of the Documents type.
//
// Returns:
//  String.
//
Function DocumentsTypeName()
	
	Return "Documents";
	
EndFunction

// Returns a value for identification of the Catalogs type.
//
// Returns:
//  String.
//
Function CatalogsTypeName()
	
	Return "Catalogs";
	
EndFunction

// Returns a value for identification of the Reports type.
//
// Returns:
//  String.
//
Function ReportsTypeName()
	
	Return "Reports";
	
EndFunction

// Returns a value for identification of the Data processors type.
//
// Returns:
//  String.
//
Function DataProcessorsTypeName()
	
	Return "DataProcessors";
	
EndFunction

// Returns a value for identification of the Exchange plans type.
//
// Returns:
//  String.
//
Function ExchangePlansTypeName()
	
	Return "ExchangePlans";
	
EndFunction

// Returns a value for identification of the Charts of characteristic types type.
//
// Returns:
//  String.
//
Function ChartsOfCharacteristicTypesTypeName()
	
	Return "ChartsOfCharacteristicTypes";
	
EndFunction

// Returns a value for identification of the Business processes type.
//
// Returns:
//  String.
//
Function BusinessProcessesTypeName()
	
	Return "BusinessProcesses";
	
EndFunction

// Returns a value for identification of the Tasks type.
//
// Returns:
//  String.
//
Function TasksTypeName()
	
	Return "Tasks";
	
EndFunction

// Checks whether the metadata object belongs to the Charts of accounts type.
//
// Returns:
//  String.
//
Function ChartsOfAccountsTypeName()
	
	Return "ChartsOfAccounts";
	
EndFunction

// Returns a value for identification of the Charts of calculation types type.
//
// Returns:
//  String.
//
Function ChartsOfCalculationTypesTypeName()
	
	Return "ChartsOfCalculationTypes";
	
EndFunction

// Returns a value for identification of the Constants type.
//
// Returns:
//  String.
//
Function ConstantsTypeName()
	
	Return "Constants";
	
EndFunction

// Returns a value for identification of the Document journals type.
//
// Returns:
//  String.
//
Function DocumentJournalsTypeName()
	
	Return "DocumentJournals";
	
EndFunction

#EndRegion

#Region SafeModeCopy

// Evaluates the passed expression, setting the safe mode of script execution and the safe mode of 
//  data separation for all separators of the configuration.
//  Thus, when evaluating the expression:
//   - attempts to set the privileged mode are ignored;
//   - all external (relative to the 1C:Enterprise platform) actions (COM, add-in loading, external 
//       application startup, operating system command execution, file system and Internet resource 
//       access) are prohibited;
//   - session separators cannot be disabled;
//   - session separator values cannot be changed (if data separation is not disabled 
//       conditionally);
//   - objects that manage the conditional separation state cannot be changed.
//
// Parameters:
//  Expression - String - an expression that should be calculated. For example, "MyModule.MyFunction(Parameters)".
//  Parameters - Arbitrary - any value as might be required for evaluating the expression. The 
//    expression must refer to  this value as the Parameters variable.
//    
//
// Returns:
//   Arbitrary - the result of the expression calculation.
//
Function CalculateInSafeMode(Val Expression, Val Parameters = Undefined)
	
	SetSafeMode(True);
	
	SeparatorArray = PerformanceMonitorCached.ApplicationSeparators();
	
	For Each SeparatorName In SeparatorArray Do
		
		SetDataSeparationSafeMode(SeparatorName, True);
		
	EndDo;
	
	Return Eval(Expression);
	
EndFunction

#EndRegion

#EndRegion
