///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Variables

&AtClient
Var JobActive;

#EndRegion

#Region EventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	StorageAddress = PutToTempStorage(Undefined, New UUID);
	StateStorageAddress = PutToTempStorage(Undefined, New UUID);
	
	Items.Close.Enabled = Not Parameters.CheckMode;
	
	StartRequestsProcessing(
		Parameters.IDs,
		Parameters.EnablingMode,
		Parameters.DisablingMode,
		Parameters.RecoveryMode,
		Parameters.CheckMode);
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	JobActive = True;
	CheckIteration = 1;
	AttachRequestsProcessingIdleHandler(3);
	
EndProcedure

&AtClient
Procedure BeforeClose(Cancel, Exit, WarningText, StandardProcessing)
	
	If Exit Then
		Return;
	EndIf;
	
	If JobActive Then
		CancelRequestsProcessing(JobID);
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Function StartRequestsProcessing(Val Queries, Val EnablingMode, DisablingMode, Val RecoveryMode, Val ApplicabilityCheckMode)
	
	If EnablingMode Then
		
		JobParameters = New Array();
		JobParameters.Add(StorageAddress);
		JobParameters.Add(StateStorageAddress);
		
		MethodCallParameters = New Array();
		MethodCallParameters.Add("DataProcessors.ExternalResourcePermissionSetup.ExecuteUpdateRequestProcessing");
		MethodCallParameters.Add(JobParameters);
		
	ElsIf DisablingMode Then
		
		JobParameters = New Array();
		JobParameters.Add(StorageAddress);
		JobParameters.Add(StateStorageAddress);
		
		MethodCallParameters = New Array();
		MethodCallParameters.Add("DataProcessors.ExternalResourcePermissionSetup.ExecuteDisableRequestProcessing");
		MethodCallParameters.Add(JobParameters);
		
	ElsIf RecoveryMode Then
		
		JobParameters = New Array();
		JobParameters.Add(StorageAddress);
		JobParameters.Add(StateStorageAddress);
		
		MethodCallParameters = New Array();
		MethodCallParameters.Add("DataProcessors.ExternalResourcePermissionSetup.ExecuteRecoveryRequestProcessing");
		MethodCallParameters.Add(JobParameters);
		
	Else
		
		JobParameters = New Array();
		JobParameters.Add(Queries);
		JobParameters.Add(StorageAddress);
		JobParameters.Add(StateStorageAddress);
		
		MethodCallParameters = New Array();
		MethodCallParameters.Add("DataProcessors.ExternalResourcePermissionSetup.ExecuteRequestProcessing");
		MethodCallParameters.Add(JobParameters);
		
	EndIf;
	
	Job = BackgroundJobs.Execute("Common.ExecuteConfigurationMethod",
			MethodCallParameters,
			,
			NStr("ru = 'Обработка запросов на использование внешних ресурсов...'; en = 'Processing requests for external resources...'; pl = 'Processing requests for external resources...';de = 'Processing requests for external resources...';ro = 'Processing requests for external resources...';tr = 'Processing requests for external resources...'; es_ES = 'Processing requests for external resources...'"));
	
	JobID = Job.UUID;
	
	Return StorageAddress;
	
EndFunction

&AtClient
Procedure CheckRequestsProcessing()
	
	Try
		Readiness = RequestsProcessed(JobID);
	Except
		JobActive = False;
		Result = New Structure();
		Result.Insert("ReturnCode", DialogReturnCode.Cancel);
		Close(Result);
		Raise;
	EndTry;
	
	If Readiness Then
		JobActive = False;
		EndRequestsProcessing();
	Else
		
		CheckIteration = CheckIteration + 1;
		
		If CheckIteration = 2 Then
			AttachRequestsProcessingIdleHandler(5);
		ElsIf CheckIteration = 3 Then
			AttachRequestsProcessingIdleHandler(8);
		Else
			AttachRequestsProcessingIdleHandler(10);
		EndIf;
		
	EndIf;
	
EndProcedure

&AtServerNoContext
Function RequestsProcessed(Val JobID)
	
	Job = BackgroundJobs.FindByUUID(JobID);
	
	If Job <> Undefined
		AND Job.State = BackgroundJobState.Active Then
		
		Return False;
	EndIf;
	
	If Job = Undefined Then
		Raise(NStr("ru = 'При обработке запросов произошла ошибка - не найдено задание обработки запросов.'; en = 'Cannot process requests. The request processing job is not found.'; pl = 'Cannot process requests. The request processing job is not found.';de = 'Cannot process requests. The request processing job is not found.';ro = 'Cannot process requests. The request processing job is not found.';tr = 'Cannot process requests. The request processing job is not found.'; es_ES = 'Cannot process requests. The request processing job is not found.'"));
	EndIf;
	
	If Job.State = BackgroundJobState.Failed Then
		JobError = Job.ErrorInfo;
		If JobError <> Undefined Then
			Raise(DetailErrorDescription(JobError));
		Else
			Raise(NStr("ru = 'При обработке запросов произошла ошибка - задание обработки запросов завершилось с неизвестной ошибкой.'; en = 'Cannot process requests. The request processing job failed with an unknown error.'; pl = 'Cannot process requests. The request processing job failed with an unknown error.';de = 'Cannot process requests. The request processing job failed with an unknown error.';ro = 'Cannot process requests. The request processing job failed with an unknown error.';tr = 'Cannot process requests. The request processing job failed with an unknown error.'; es_ES = 'Cannot process requests. The request processing job failed with an unknown error.'"));
		EndIf;
	ElsIf Job.State = BackgroundJobState.Canceled Then
		Raise(NStr("ru = 'При обработке запросов произошла ошибка - задание обработки запросов было отменено администратором.'; en = 'Cannot process requests. The administrator stopped the request processing job.'; pl = 'Cannot process requests. The administrator stopped the request processing job.';de = 'Cannot process requests. The administrator stopped the request processing job.';ro = 'Cannot process requests. The administrator stopped the request processing job.';tr = 'Cannot process requests. The administrator stopped the request processing job.'; es_ES = 'Cannot process requests. The administrator stopped the request processing job.'"));
	Else
		JobID = Undefined;
		Return True;
	EndIf;
	
EndFunction

&AtClient
Procedure EndRequestsProcessing()
	
	JobActive = False;
	
	If IsOpen() Then
		
		Result = New Structure();
		Result.Insert("ReturnCode", DialogReturnCode.OK);
		Result.Insert("StateStorageAddress", StateStorageAddress);
		
		Close(Result);
		
	Else
		
		NotifyDescription = ThisObject.OnCloseNotifyDescription;
		If NotifyDescription <> Undefined Then
			ExecuteNotifyProcessing(NotifyDescription, DialogReturnCode.OK);
		EndIf;
		
	EndIf;
	
EndProcedure

&AtServerNoContext
Procedure CancelRequestsProcessing(Val JobID)
	
	Job = BackgroundJobs.FindByUUID(JobID);
	
	If Job = Undefined OR Job.State <> BackgroundJobState.Active Then
		Return;
	EndIf;
	
	Try
		Job.Cancel();
	Except
		// The job might have been completed at that moment and no error occurred.
		WriteLogEvent(NStr("ru = 'Настройка разрешений на использование внешних ресурсов.Отмена выполнения фонового задания'; en = 'External resource permission setup.Background job cancellation'; pl = 'External resource permission setup.Background job cancellation';de = 'External resource permission setup.Background job cancellation';ro = 'External resource permission setup.Background job cancellation';tr = 'External resource permission setup.Background job cancellation'; es_ES = 'External resource permission setup.Background job cancellation'", Common.DefaultLanguageCode()),
			EventLogLevel.Error, , , DetailErrorDescription(ErrorInfo()));
	EndTry;
	
EndProcedure

&AtClient
Procedure AttachRequestsProcessingIdleHandler(Val Interval)
	
	AttachIdleHandler("CheckRequestsProcessing", Interval, True);
	
EndProcedure

#EndRegion