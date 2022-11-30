///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Variables

&AtClient
Var ExternalResourcesAllowed;

#EndRegion

#Region EventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If NOT PerformanceMonitorInternal.SubsystemExists("StandardSubsystems.Core") Then
        ThisObject.Items.LocalExportDirectory.ChoiceButton = False;
		SSLAvailable = False;
	Else
		SSLAvailable = True;
		SecurityProfilesAvailable = PerformanceMonitorInternal.SubsystemExists("StandardSubsystems.SecurityProfiles");
	EndIf;
	
	ConstantsSet.RunPerformanceMeasurements = Constants.RunPerformanceMeasurements.Get();
	ConstantsSet.LastPerformanceMeasurementsExportDateUTC = Constants.LastPerformanceMeasurementsExportDateUTC.Get();
		
	ConstantsSet.PerformanceMonitorRecordPeriod = PerformanceMonitor.RecordPeriod();
	ConstantsSet.MeasurementsCountInExportPackage = Constants.MeasurementsCountInExportPackage.Get();
	ConstantsSet.KeepMeasurementsPeriod = Constants.KeepMeasurementsPeriod.Get();
	
	DirectoriesForExport = PerformanceMonitorInternal.PerformanceMonitorDataExportDirectories();
	If TypeOf(DirectoriesForExport) <> Type("Structure")
		OR DirectoriesForExport.Count() = 0 Then
		Return;
	EndIf;
	
	DoExportToFTPDirectory = DirectoriesForExport.DoExportToFTPDirectory;
	FTPExportDirectory = DirectoriesForExport.FTPExportDirectory;
	DoExportToLocalDirectory = DirectoriesForExport.DoExportToLocalDirectory;
	LocalExportDirectory = DirectoriesForExport.LocalExportDirectory;
	
	DoExport = DoExportToFTPDirectory Or DoExportToLocalDirectory;
	
EndProcedure

&AtClient
Procedure ExecuteExportOnChange(Item)
	
	ExportAllowed = DoExport;
	DoExportToLocalDirectory = ExportAllowed;
	DoExportToFTPDirectory = ExportAllowed;
	
	Modified = True;
	
EndProcedure	

&AtClient
Procedure ExecuteExportToDirectoryOnChange(Item)
	
	DoExport = DoExportToLocalDirectory OR DoExportToFTPDirectory;
	Modified = True;
	
EndProcedure	

&AtClient
Procedure ExportLocalFileDirectoryStartChoice(Item, ChoiceData, StandardProcessing)
	
	If SSLAvailable Then
		NotifyDescription = New NotifyDescription("SelectExportDirectorySuggested", ThisObject);
		ModuleFileSystemClient = Eval("FileSystemClient");
		If TypeOf(ModuleFileSystemClient) = Type("CommonModule") Then
			ModuleFileSystemClient.AttachFileOperationsExtension(NotifyDescription);
		EndIf;
	EndIf;
	
EndProcedure

&AtServer
Function FillCheckProcessingAtServer()
	ItemsOnControl = New Map;
	ItemsOnControl.Insert(Items.DoExportToLocalDirectory, Items.LocalExportDirectory);
	ItemsOnControl.Insert(Items.DoExportToFTPDirectory, Items.FTPExportDirectory);
	
	NoErrors = True;	
	For Each PathFlag In ItemsOnControl Do
		ExecuteJob = ThisObject[PathFlag.Key.DataPath];
		PathItem = PathFlag.Value;
		If ExecuteJob AND IsBlankString(TrimAll(ThisObject[PathItem.DataPath])) Then
			MessageText = NStr("ru = 'Поле ""%1"" не заполнено'; en = 'Field ""%1"" is blank'; pl = 'Field ""%1"" is blank';de = 'Field ""%1"" is blank';ro = 'Field ""%1"" is blank';tr = 'Field ""%1"" is blank'; es_ES = 'Field ""%1"" is blank'");
			MessageText = StrReplace(MessageText, "%1", PathItem.Title);
			PerformanceMonitorInternal.MessageToUser(
				MessageText,
				,
				PathItem.Name,
				PathItem.DataPath);
			NoErrors = False;
		EndIf;
	EndDo;
	
	Return NoErrors;	
EndFunction

&AtServer
Procedure SaveAtServer()
	
	ExecuteLocalDirectory = New Array;
	ExecuteLocalDirectory.Add(DoExportToLocalDirectory);
	ExecuteLocalDirectory.Add(TrimAll(ThisObject.LocalExportDirectory));
	
	ExecuteFTPDirectory = New Array;
	ExecuteFTPDirectory.Add(DoExportToFTPDirectory);
	ExecuteFTPDirectory.Add(TrimAll(ThisObject.FTPExportDirectory));
	
	SetExportDirectory(ExecuteLocalDirectory, ExecuteFTPDirectory);  

	SetScheduledJobUsage(DoExport);
	
	Constants.RunPerformanceMeasurements.Set(ConstantsSet.RunPerformanceMeasurements);
	Constants.PerformanceMonitorRecordPeriod.Set(ConstantsSet.PerformanceMonitorRecordPeriod);
	Constants.MeasurementsCountInExportPackage.Set(ConstantsSet.MeasurementsCountInExportPackage);
	Constants.KeepMeasurementsPeriod.Set(ConstantsSet.KeepMeasurementsPeriod);
	
	Modified = False;
	
EndProcedure

&AtClient
Procedure LocalExportDirectoryOnChange(Item)
	
	ExternalResourcesAllowed = False;
	Modified = True;
	
EndProcedure

&AtClient
Procedure FTPExportDirectoryOnChange(Item)
	
	ExternalResourcesAllowed = False;
	Modified = True;
	
EndProcedure

///////////////////////////////////////////////////////////////////////
// COMMAND HANDLERS

&AtClient
Procedure SetExportSchedule(Command)
	
	JobSchedule = PerformanceMonitorDataExportSchedule();
	
	Notification = New NotifyDescription("SetUpExportScheduleCompletion", ThisObject);
	Dialog = New ScheduledJobDialog(JobSchedule);
	Dialog.Show(Notification);
	
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure SelectExportDirectorySuggested(FileSystemExtensionAttached, AdditionalParameters) Export
	
	If FileSystemExtensionAttached Then
		
		SelectFile = New FileDialog(FileDialogMode.ChooseDirectory);
		SelectFile.Multiselect = False;
		SelectFile.Title = NStr("ru = 'Выбор каталога экспорта'; en = 'Select export directory'; pl = 'Select export directory';de = 'Select export directory';ro = 'Select export directory';tr = 'Select export directory'; es_ES = 'Select export directory'");
		
		NotifyDescription = New NotifyDescription("SelectDirectoryDialogCompletion", ThisObject, Undefined);
		FileSystemClient.ShowSelectionDialog(NotifyDescription, SelectFile);
		
	EndIf;
	
EndProcedure

// Changes the directory for exporting data.
//
// Parameters:
//  ExportDirectory - String - new export directory.
//
&AtServerNoContext
Procedure SetExportDirectory(ExecuteLocalExportDirectory, ExecuteFTPExportDirectory)
	
	Job = PerformanceMonitorInternal.PerformanceMonitorDataExportScheduledJob();
	
	Directories = New Structure();
	Directories.Insert(PerformanceMonitorClientServer.LocalExportDirectoryJobKey(), ExecuteLocalExportDirectory);
	Directories.Insert(PerformanceMonitorClientServer.FTPExportDirectoryJobKey(), ExecuteFTPExportDirectory);
	
	JobParameters = New Array;	
	JobParameters.Add(Directories);
	Job.Parameters = JobParameters;
	CommitScheduledJob(Job);
	
EndProcedure

// Enables or disables a scheduled job.
//
// Parameters:
//  NewValue - Boolean - new value.
//
// Returns:
//  Boolean - old value (before the change).
//
&AtServerNoContext
Function SetScheduledJobUsage(NewValue)
	
	Job = PerformanceMonitorInternal.PerformanceMonitorDataExportScheduledJob();
	CurrentState = Job.Use;
	If CurrentState <> NewValue Then
		Job.Use = NewValue;
		CommitScheduledJob(Job);
	EndIf;
	
	Return CurrentState;
	
EndFunction

// Returns the current schedule for a scheduled job.
//
// Returns:
//  JobSchedule - the сurrent schedule.
//
&AtServerNoContext
Function PerformanceMonitorDataExportSchedule()
	
	Job = PerformanceMonitorInternal.PerformanceMonitorDataExportScheduledJob();
	Return Job.Schedule;
	
EndFunction

// Sets a new schedule for a scheduled job.
//
// Parameters:
//  NewSchedule - JobSchedule - a new schedule.
//
&AtServerNoContext
Procedure SetSchedule(Val NewSchedule)
	
	Job = PerformanceMonitorInternal.PerformanceMonitorDataExportScheduledJob();
	Job.Schedule = NewSchedule;
	CommitScheduledJob(Job);
	
EndProcedure

// Saves scheduled job settings.
//
// Parameters:
//  Job - ScheduledJob.PerformanceMonitorDataExport.
//
&AtServerNoContext
Procedure CommitScheduledJob(Job)
	
	SetPrivilegedMode(True);
	Job.Write();
	
EndProcedure

&AtClient
Procedure SetUpExportScheduleCompletion(Schedule, AdditionalParameters) Export
	
	If Schedule <> Undefined Then
		SetSchedule(Schedule);
		Modified = True;
	EndIf;
	
EndProcedure

&AtClient
Procedure SaveSettings(Command)
	
	If FillCheckProcessingAtServer() Then
		ValidatePermissionToAccessExternalResources(False);
	EndIf;
	
EndProcedure

&AtClient
Procedure SaveClose(Command)
	
	If FillCheckProcessingAtServer() Then
		ValidatePermissionToAccessExternalResources(True);
	EndIf;
	
EndProcedure

&AtClient
Procedure ValidatePermissionToAccessExternalResources(CloseForm)
	
	If ExternalResourcesAllowed <> True Then
		If CloseForm Then
			ClosingNotification = New NotifyDescription("AllowExternalResourceSaveAndClose", ThisObject);
		Else
			ClosingNotification = New NotifyDescription("AllowExternalResourceSave", ThisObject);
		EndIf;
		
		If SecurityProfilesAvailable Then
			
			Directories = New Structure;
			Directories.Insert("DoExportToFTPDirectory", DoExportToFTPDirectory);
			
			URIStructure = PerformanceMonitorClientServer.URIStructure(FTPExportDirectory);
			Directories.Insert("FTPExportDirectory", URIStructure.ServerName);
			If ValueIsFilled(URIStructure.Port) Then
				Directories.Insert("FTPExportDirectoryPort", URIStructure.Port);
			EndIf;
			
			Directories.Insert("DoExportToLocalDirectory", DoExportToLocalDirectory);
			Directories.Insert("LocalExportDirectory", LocalExportDirectory);
			
			Query = RequestToUseExternalResources(Directories);
			
			QueryToArray = New Array;
			QueryToArray.Add(Query);
		
			ModuleSafeModeManagerClient = Eval("SafeModeManagerClient");
			ModuleSafeModeManagerClient.ApplyExternalResourceRequests(QueryToArray, ThisObject, ClosingNotification);
		Else
			ExecuteNotifyProcessing(ClosingNotification, DialogReturnCode.OK);
		EndIf;
	ElsIf CloseForm Then
		SaveAtServer();
		ThisObject.Close();
	Else
		SaveAtServer();
	EndIf;
	
EndProcedure

&AtServerNoContext
Function RequestToUseExternalResources(Directories)
	
	Return PerformanceMonitorInternal.RequestToUseExternalResources(Directories);
	
EndFunction

&AtClient
Procedure AllowExternalResourceSaveAndClose(Result, Context) Export
	
	If Result = DialogReturnCode.OK Then
		ExternalResourcesAllowed = True;
		SaveAtServer();
		ThisObject.Close();
	EndIf;
	
EndProcedure

&AtClient
Procedure AllowExternalResourceSave(Result, Context) Export
	
	If Result = DialogReturnCode.OK Then
		ExternalResourcesAllowed = True;
		SaveAtServer();
	EndIf;
	
EndProcedure

&AtClient
Procedure ConstantsSetPerformanceMonitorRecordingPeriodOnChange(Item)
	Modified = True;
EndProcedure

&AtClient
Procedure ConstantsSetMeasurementsCountInExportPackageOnChange(Item)
	Modified = True;
EndProcedure

&AtClient
Procedure ConstantsSetMeasurementsStoragePeriodOnChange(Item)
	Modified = True;
EndProcedure

&AtClient
Procedure SelectDirectoryDialogCompletion(SelectedFiles, AdditionalParameters) Export
    
    If SelectedFiles <> Undefined Then
		SelectedDirectory = SelectedFiles[0];
		LocalExportDirectory = SelectedDirectory;
		ThisObject.Modified = True;
	EndIf;
		
EndProcedure

#EndRegion
