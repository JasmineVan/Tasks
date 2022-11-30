///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Variables

&AtClient
Var RefreshInterface;

#EndRegion

#Region EventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Common.SubsystemExists("StandardSubsystems.BusinessProcessesAndTasks") Then
		If Users.IsFullUser() Then
			HasMail = Common.SubsystemExists("StandardSubsystems.EmailOperations");
			ScheduledJob = FindScheduledJob("TaskMonitoring");
			If HasMail AND ScheduledJob <> Undefined Then
				TasksMonitoringUsage = ScheduledJob.Use;
				TaskMonitoringSchedule    = ScheduledJob.Schedule;
			Else
				Items.TasksMonitoringGroup.Visible = False;
			EndIf;
			ScheduledJob = FindScheduledJob("NewPerformerTaskNotifications");
			If HasMail AND ScheduledJob <> Undefined Then
				NotifyPerformersAboutNewTasksUsage = ScheduledJob.Use;
				NewPerformerTaskNotificationsSchedule    = ScheduledJob.Schedule;
			Else
				Items.NotifyPerformersAboutNewTasksGroup.Visible = False;
			EndIf;
		Else
			Items.TasksMonitoringGroup.Visible = False;
			Items.NotifyPerformersAboutNewTasksGroup.Visible = False;
		EndIf;
		
		If Common.DataSeparationEnabled() Then
			Items.TasksMonitoringConfigureSchedule.Visible = False;
			Items.NotifyPerformersAboutNewTasksConfigureSchedule.Visible = False;
		EndIf;
	Else
		Items.BusinessProcessesAndTasksGroup.Visible = False;
	EndIf;
	
	If Common.SubsystemExists("StandardSubsystems.Interactions") Then
		ModuleInteractions = Common.CommonModule("Interactions");
		Items.MailSecurity.Visible = ModuleInteractions.HasAbilityToFilterHTMLContent();
	EndIf;
	
	// Update items states.
	SetAvailability();
	
	ApplicationSettingsOverridable.OrganizerOnCreateAtServer(ThisObject);
	
EndProcedure

&AtClient
Procedure OnClose(Exit)
	If Exit Then
		Return;
	EndIf;
	UpdateApplicationInterface();
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If EventName <> "Write_ConstantsSet" Then
		Return;
	EndIf;
	
	If Source = "UseExternalUsers" Then
		
		ThisObject.Read();
		SetAvailability();
		
	EndIf;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure UseMailClientOnChange(Item)
	Attachable_OnChangeAttribute(Item);
EndProcedure

&AtClient
Procedure UseOtherInteractionsOnChange(Item)
	Attachable_OnChangeAttribute(Item);
EndProcedure

&AtClient
Procedure SendEmailsInHTMLFormatOnChange(Item)
	Attachable_OnChangeAttribute(Item);
EndProcedure

&AtClient
Procedure UseReviewedFlagOnChange(Item)
	Attachable_OnChangeAttribute(Item);
EndProcedure

&AtClient
Procedure ProhibitUnsafeContentRepresentationInEmailsOnChange(Item)
	Attachable_OnChangeAttribute(Item);
EndProcedure

&AtClient
Procedure UseNotesOnChange(Item)
	Attachable_OnChangeAttribute(Item);
EndProcedure

&AtClient
Procedure UseUserRemindersOnChange(Item)
	Attachable_OnChangeAttribute(Item);
EndProcedure

&AtClient
Procedure UsePollsOnChange(Item)
	Attachable_OnChangeAttribute(Item);
EndProcedure

&AtClient
Procedure UseMessagesTemplatesOnChange(Item)
	Attachable_OnChangeAttribute(Item);
EndProcedure

&AtClient
Procedure UseBusinessProcessesAndTasksOnChange(Item)
	Attachable_OnChangeAttribute(Item);
EndProcedure

&AtClient
Procedure UseSubordinateBusinessProcessesOnChange(Item)
	Attachable_OnChangeAttribute(Item);
EndProcedure

&AtClient
Procedure ChangeJobsRetroactivelyOnChange(Item)
	Attachable_OnChangeAttribute(Item);
EndProcedure

&AtClient
Procedure UseTasksStartDateOnChange(Item)
	Attachable_OnChangeAttribute(Item);
EndProcedure

&AtClient
Procedure UseDateAndTimeInTasksDeadlinesOnChange(Item)
	Attachable_OnChangeAttribute(Item);
EndProcedure

#EndRegion

#Region FormCommandHandlers

&AtClient
Procedure TasksMonitoringConfigureSchedule(Command)
	Dialog = New ScheduledJobDialog(TaskMonitoringSchedule);
	Dialog.Show(New NotifyDescription("TaskMonitoringAfterScheduleChanged", ThisObject));
EndProcedure

&AtClient
Procedure NotifyPerformersAboutNewTasksConfigureSchedule(Command)
	Dialog = New ScheduledJobDialog(NewPerformerTaskNotificationsSchedule);
	Dialog.Show(New NotifyDescription("NewPerformerTaskNotificationsAfterChangeSchedule", ThisObject));
EndProcedure

#EndRegion

#Region Private

////////////////////////////////////////////////////////////////////////////////
// Client

&AtClient
Procedure Attachable_OnChangeAttribute(Item, UpdateInterface = True)
	
	ConstantName = OnChangeAttributeServer(Item.Name);
	
	RefreshReusableValues();
	
	If UpdateInterface Then
		RefreshInterface = True;
		AttachIdleHandler("UpdateApplicationInterface", 2, True);
	EndIf;
	
	If ConstantName <> "" Then
		Notify("Write_ConstantsSet", New Structure, ConstantName);
	EndIf;
	
EndProcedure

&AtClient
Procedure UpdateApplicationInterface()
	
	If RefreshInterface = True Then
		RefreshInterface = False;
		CommonClient.RefreshApplicationInterface();
	EndIf;
	
EndProcedure

&AtClient
Procedure TaskMonitoringAfterScheduleChanged(Schedule, ExecutionParameters) Export
	If Schedule = Undefined Then
		Return;
	EndIf;
	
	TaskMonitoringSchedule = Schedule;
	TasksMonitoringUsage = True;
	WriteScheduledJob("TaskMonitoring", TasksMonitoringUsage, 
		TaskMonitoringSchedule, "TaskMonitoringSchedule");
EndProcedure

&AtClient
Procedure TasksMonitoringUsageOnChange(Item)
	WriteScheduledJob("TaskMonitoring", TasksMonitoringUsage, 
		TaskMonitoringSchedule, "TaskMonitoringSchedule");
EndProcedure

&AtClient
Procedure NewPerformerTaskNotificationsAfterChangeSchedule(Schedule, ExecutionParameters) Export
	If Schedule = Undefined Then
		Return;
	EndIf;
	
	NewPerformerTaskNotificationsSchedule = Schedule;
	NotifyPerformersAboutNewTasksUsage = True;
	WriteScheduledJob("NewPerformerTaskNotifications", NotifyPerformersAboutNewTasksUsage, 
		NewPerformerTaskNotificationsSchedule, "NewPerformerTaskNotificationsSchedule");
EndProcedure

&AtClient
Procedure NotifyAssigneesOfNewTasksUsageOnChange(Item)
	WriteScheduledJob("NewPerformerTaskNotifications", NotifyPerformersAboutNewTasksUsage, 
		NewPerformerTaskNotificationsSchedule, "NewPerformerTaskNotificationsSchedule");
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Server

&AtServer
Function OnChangeAttributeServer(ItemName)
	
	DataPathAttribute = Items[ItemName].DataPath;
	
	ConstantName = SaveAttributeValue(DataPathAttribute);
	
	SetAvailability(DataPathAttribute);
	
	RefreshReusableValues();
	
	Return ConstantName;
	
EndFunction

&AtServer
Function SaveAttributeValue(DataPathAttribute)
	
	NameParts = StrSplit(DataPathAttribute, ".");
	If NameParts.Count() <> 2 Then
		Return "";
	EndIf;
	
	ConstantName = NameParts[1];
	ConstantManager = Constants[ConstantName];
	ConstantValue = ConstantsSet[ConstantName];
	
	If ConstantManager.Get() <> ConstantValue Then
		ConstantManager.Set(ConstantValue);
	EndIf;
	
	If (ConstantName = "UseEmailClient" OR ConstantName = "UseBusinessProcessesAndTasks") AND ConstantValue = False Then
		ThisObject.Read();
	EndIf;
	
	Return ConstantName;
	
EndFunction

&AtServer
Procedure SetAvailability(DataPathAttribute = "")
	
	If (DataPathAttribute = "ConstantsSet.UseEmailClient" OR DataPathAttribute = "")
		AND Common.SubsystemExists("StandardSubsystems.Interactions") Then
		
		Items.UseOtherInteractions.Enabled             = ConstantsSet.UseEmailClient;
		Items.UseReviewedFlag.Enabled               = ConstantsSet.UseEmailClient;
		Items.SendEmailsInHTMLFormat.Enabled                 = ConstantsSet.UseEmailClient;
		Items.DenyDisplayingUnsafeContentInEmails.Enabled = ConstantsSet.UseEmailClient;
		
	EndIf;
	
	If (DataPathAttribute = "ConstantsSet.UseBusinessProcessesAndTasks" OR DataPathAttribute = "")
		AND Common.SubsystemExists("StandardSubsystems.BusinessProcessesAndTasks") Then
		
		Items.OpenRolesAndPerformersForBusinessProcesses.Enabled = ConstantsSet.UseBusinessProcessesAndTasks;
		Items.UseSubordinateBusinessProcesses.Enabled  = ConstantsSet.UseBusinessProcessesAndTasks;
		Items.ChangeJobsBackdated.Enabled            = ConstantsSet.UseBusinessProcessesAndTasks;
		Items.UseTaskStartDate.Enabled            = ConstantsSet.UseBusinessProcessesAndTasks;
		Items.UseDateAndTimeInTaskDeadlines.Enabled     = ConstantsSet.UseBusinessProcessesAndTasks;
		Items.TasksMonitoringGroup.Enabled					= ConstantsSet.UseBusinessProcessesAndTasks;
		Items.NotifyPerformersAboutNewTasksGroup.Enabled = ConstantsSet.UseBusinessProcessesAndTasks;
		
	EndIf;
	
	If Items.TasksMonitoringGroup.Visible
		AND (DataPathAttribute = "TaskMonitoringSchedule" Or DataPathAttribute = "")
		AND Common.SubsystemExists("StandardSubsystems.BusinessProcessesAndTasks") Then
		Items.TasksMonitoringConfigureSchedule.Enabled	= TasksMonitoringUsage;
		If TasksMonitoringUsage Then
			SchedulePresentation = String(TaskMonitoringSchedule);
			Presentation = Upper(Left(SchedulePresentation, 1)) + Mid(SchedulePresentation, 2);
		Else
			Presentation = "";
		EndIf;
		Items.TasksMonitoringNote.Title = Presentation;
	EndIf;
	
	If Items.NotifyPerformersAboutNewTasksGroup.Visible
		AND (DataPathAttribute = "NewPerformerTaskNotificationsSchedule" Or DataPathAttribute = "")
		AND Common.SubsystemExists("StandardSubsystems.BusinessProcessesAndTasks") Then
		Items.NotifyPerformersAboutNewTasksConfigureSchedule.Enabled	= NotifyPerformersAboutNewTasksUsage;
		If NotifyPerformersAboutNewTasksUsage Then
			SchedulePresentation = String(NewPerformerTaskNotificationsSchedule);
			Presentation = Upper(Left(SchedulePresentation, 1)) + Mid(SchedulePresentation, 2);
		Else
			Presentation = "";
		EndIf;
		Items.NotifyPerformersAboutNewTasksNote.Title = Presentation;
	EndIf;
	
EndProcedure

&AtServer
Procedure WriteScheduledJob(PredefinedItemName, Usage, Schedule, DataPathAttribute)
	ScheduledJob = FindScheduledJob(PredefinedItemName);
	
	JobParameters = New Structure;
	JobParameters.Insert("Use", Usage);
	JobParameters.Insert("Schedule", Schedule);
	
	ScheduledJobsServer.ChangeJob(ScheduledJob, JobParameters);
	
	If DataPathAttribute <> Undefined Then
		SetAvailability(DataPathAttribute);
	EndIf;
EndProcedure

&AtServer
Function FindScheduledJob(PredefinedItemName)
	Filter = New Structure;
	Filter.Insert("Metadata", PredefinedItemName);
	
	SearchResult = ScheduledJobsServer.FindJobs(Filter);
	Return ?(SearchResult.Count() = 0, Undefined, SearchResult[0]);
EndFunction

#EndRegion
