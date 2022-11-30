///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region EventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	GetIDJobState = "";
	
	If Parameters.Property("JobID") Then
		JobID = Parameters.JobID;
		JobResultAddress = Parameters.JobResultAddress;
		If ValueIsFilled(JobID) Then
			GetIDJobState = JobCompleted(JobID);
		EndIf;
	EndIf;  	
	
	MonitoringCenterID = MonitoringCenterID();
	If NOT IsBlankString(MonitoringCenterID) Then
		ID = MonitoringCenterID;
	Else
		// There is no ID for some reason, get it again.
		Items.IDGroup.CurrentPage = Items.GetIDPage;
	EndIf;
	
	ParametersToGet = New Structure("SendDumpsFiles, RequestConfirmationBeforeSending");
	MonitoringCenterParameters = MonitoringCenterInternal.GetMonitoringCenterParameters(ParametersToGet);
	SendErrorsInformation = MonitoringCenterParameters.SendDumpsFiles;
	If SendErrorsInformation = 2 Then
		Items.SendErrorsInformation.ThreeState = True;
	EndIf;
	RequestConfirmationBeforeSending = MonitoringCenterParameters.RequestConfirmationBeforeSending;
	ToolTipContent = Items.SendErrorsInformationExtendedTooltip.Title;
	If Common.FileInfobase() Then                                   		
		Items.SendErrorsInformationExtendedTooltip.Title = StrReplace(ToolTipContent,"%AddlInfo","");
	Else
		Items.SendErrorsInformationExtendedTooltip.Title = StrReplace(ToolTipContent,"%AddlInfo"," " + NStr("ru = 'на сервере 1С'; en = 'on 1C server'; pl = 'on 1C server';de = 'on 1C server';ro = 'on 1C server';tr = 'on 1C server'; es_ES = 'on 1C server'"));
	EndIf;
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	VisibilityParameters = New Structure("Status, ResultAddress", GetIDJobState, JobResultAddress);
	If NOT IsBlankString(GetIDJobState) AND IsBlankString(ID) Then
		SetItemsVisibility(VisibilityParameters);
	EndIf;
EndProcedure

&AtClient
Procedure SendErrorsInformationOnChange(Item)
	Item.ThreeState = False;
EndProcedure

#EndRegion


#Region FormCommandHandlers

&AtClient
Procedure Write(Command)
	NewParameters = New Structure("SendDumpsFiles, RequestConfirmationBeforeSending", 
										SendErrorsInformation, RequestConfirmationBeforeSending);
	SetMonitoringCenterParameters(NewParameters);
EndProcedure

&AtClient
Procedure WriteAndClose(Command)
	NewParameters = New Structure("SendDumpsFiles, RequestConfirmationBeforeSending", 
										SendErrorsInformation, RequestConfirmationBeforeSending);
	SetMonitoringCenterParameters(NewParameters);
	Close();
EndProcedure

&AtClient
Procedure GetID(Command)
	RunResult = DiscoveryPackageSending();
	JobID = RunResult.JobID;
	JobResultAddress = RunResult.ResultAddress;
	GetIDJobState = "Running";
	Notification = New NotifyDescription("AfterUpdateID", MonitoringCenterClient);
	IdleParameters = TimeConsumingOperationsClient.IdleParameters(ThisObject);
	IdleParameters.OutputIdleWindow = False;
	TimeConsumingOperationsClient.WaitForCompletion(RunResult, Notification, IdleParameters);
	
	// Outputs the status of getting ID.
	VisibilityParameters = New Structure("Status, ResultAddress", GetIDJobState, JobResultAddress);
	SetItemsVisibility(VisibilityParameters);
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	If EventName = "IDUpdateMonitoringCenter" AND Parameter <> Undefined Then
		SetItemsVisibility(Parameter);	
	EndIf;
EndProcedure

#EndRegion

#Region Private

&AtServerNoContext
Procedure SetMonitoringCenterParameters(NewParameters)
	MonitoringCenterInternal.SetMonitoringCenterParametersExternalCall(NewParameters);
EndProcedure

&AtServerNoContext
Function MonitoringCenterID()
	Return MonitoringCenter.InfoBaseID();
EndFunction

&AtClient
Procedure UpdateParameters()
	MonitoringCenterID = MonitoringCenterID();
	If NOT IsBlankString(MonitoringCenterID) Then
		ID = MonitoringCenterID;
	EndIf;                                                                     	
EndProcedure

&AtServerNoContext
Function JobCompleted(JobID)
	ExecutionResult = "Running";
	Try
		JobCompleted = TimeConsumingOperations.JobCompleted(JobID);
		If JobCompleted Then 
			ExecutionResult = "Completed";
		Else
			ExecutionResult = "Running";
		EndIf;
	Except
		ExecutionResult = "Error";
	EndTry;
	Return ExecutionResult;
EndFunction

&AtServerNoContext
Function DiscoveryPackageSending()
	// Send a discovery package.
	ExecutionParameters = TimeConsumingOperations.BackgroundExecutionParameters(New UUID);
	ExecutionParameters.WaitForCompletion = 0;
	ProcedureParameters = New Structure("Iterator, SendTestPackageFlag, GetID", 0, False, True);
	Return TimeConsumingOperations.ExecuteInBackground("MonitoringCenterInternal.SendTestPackage", ProcedureParameters, ExecutionParameters);
EndFunction

&AtClient
Procedure SetItemsVisibility(VisibilityParameters)
	ExecutionResult = GetFromTempStorage(VisibilityParameters.ResultAddress);
	If VisibilityParameters.Status = "Running" Then
		Items.ProgressDetails.Title = NStr("ru = 'Выполняется получение идентификатора'; en = 'Receiving ID'; pl = 'Receiving ID';de = 'Receiving ID';ro = 'Receiving ID';tr = 'Receiving ID'; es_ES = 'Receiving ID'");		
		Items.ProgressDetails.Visible = True;
		Items.Progress.Picture = PictureLib.TimeConsumingOperation16;
		Items.Progress.Visible = True;
		Items.IDGroup.Visible = False;	
	ElsIf VisibilityParameters.Status = "Completed" AND ExecutionResult.Success Then
		Items.ProgressDetails.Title = NStr("ru = 'Идентификатор успешно получен'; en = 'ID is received successfully'; pl = 'ID is received successfully';de = 'ID is received successfully';ro = 'ID is received successfully';tr = 'ID is received successfully'; es_ES = 'ID is received successfully'");		
		Items.ProgressDetails.Visible = False;
		Items.Progress.Visible = False;
		Items.IDGroup.Visible = True;
		Items.IDGroup.CurrentPage = Items.IDPage;
		UpdateParameters();
	ElsIf VisibilityParameters.Status = "Completed" AND NOT ExecutionResult.Success OR VisibilityParameters.Status = "Error" Then
		If VisibilityParameters.Status = "Error" Then
			Note = NStr("ru = 'Ошибка при выполнении фонового задания.'; en = 'An error occurred while executing the background job.'; pl = 'An error occurred while executing the background job.';de = 'An error occurred while executing the background job.';ro = 'An error occurred while executing the background job.';tr = 'An error occurred while executing the background job.'; es_ES = 'An error occurred while executing the background job.'");
		Else
			Note = ExecutionResult.BriefErrorPresentation;
		EndIf;
		CaptionPattern = NStr("ru = 'Не удалось получить идентификатор. %1 Подробнее см. в журнале регистрации'; en = 'Cannot receive ID. %1 For more information, see the event log'; pl = 'Cannot receive ID. %1 For more information, see the event log';de = 'Cannot receive ID. %1 For more information, see the event log';ro = 'Cannot receive ID. %1 For more information, see the event log';tr = 'Cannot receive ID. %1 For more information, see the event log'; es_ES = 'Cannot receive ID. %1 For more information, see the event log'");
		Items.ProgressDetails.Title = StringFunctionsClientServer.SubstituteParametersToString(CaptionPattern, Note);		
		Items.ProgressDetails.Visible = True;
		Items.Progress.Picture = PictureLib.Warning;
		Items.Progress.Visible = True;
		Items.IDGroup.Visible = True;
		Items.IDGroup.CurrentPage = Items.GetIDPage;
	EndIf;
EndProcedure

#EndRegion

