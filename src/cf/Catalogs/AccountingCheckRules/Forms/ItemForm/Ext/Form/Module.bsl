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
	
	If NOT ValueIsFilled(Object.Ref) Then
		Raise NStr("ru='Интерактивное создание запрещено.'; en = 'Interactive creation is prohibited.'; pl = 'Interactive creation is prohibited.';de = 'Interactive creation is prohibited.';ro = 'Interactive creation is prohibited.';tr = 'Interactive creation is prohibited.'; es_ES = 'Interactive creation is prohibited.'");
	EndIf;
	
	InfobaseUpdate.CheckObjectProcessed(Object, ThisObject);
	Items.IndividualSchedulePresentation.Enabled = Not ReadOnly;
	Items.PresentationOfCommonSchedule.Enabled          = Not ReadOnly;
	
	CurrentCheckMetadata = CheckMetadata(Object.ID);
	SetImportanceFieldAccessibility(ThisObject, CurrentCheckMetadata);
	SetPathToHandlerProcedure(ThisObject, CurrentCheckMetadata);
	
	AccountingCheckRulesSettingAllowed = AccessRight("Update", Metadata.Catalogs.AccountingCheckRules);
	Items.FormExecuteCheck.Visible              = AccountingCheckRulesSettingAllowed;
	Items.FormApplyStandardSettings.Visible = AccountingCheckRulesSettingAllowed;
	
	SetInitialScheduleSettings();
	IsSystemAdministrator = Users.IsFullUser(, True);
	If Not Common.DataSeparationEnabled() Or IsSystemAdministrator Then
		GenerateSchedules();
	ElsIf Common.DataSeparationEnabled() AND Not IsSystemAdministrator Then
		Items.ScheduleGroup.Visible = False;
	EndIf;
		
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	If Not ValueIsFilled(CurrentObject.Code) Then
		CurrentObject.SetNewCode();
	EndIf;
	
	If ValueIsFilled(IndividualScheduleAddress) Then
		CurrentObject.CheckSchedule = GetFromTempStorage(IndividualScheduleAddress);
	EndIf;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure IndividualSchedulePresentationURLProcessing(Item, FormattedStringURL, StandardProcessing)
	
	StandardProcessing = False;
	
	StorageData = GetFromTempStorage(FormattedStringURL);
	If StorageData = "AddJob" Then
		ScheduleDialog    = New ScheduledJobDialog(New JobSchedule);
		ChangeNotification = New NotifyDescription("AddJobAtClientCompletion", ThisObject);
		ScheduleDialog.Show(ChangeNotification);
	Else
		ScheduleDialog    = New ScheduledJobDialog(StorageData);
		ChangeNotification = New NotifyDescription("ChangeTaskOnClientCompletion", ThisObject);
		ScheduleDialog.Show(ChangeNotification);
	EndIf;
	
EndProcedure

&AtClient
Procedure RunsInBackgroundOnScheduleOnChange(Item)
	
	If RunsInBackgroundOnSchedule Then
		SetScheduleSettingsAtServer();
	Else
		HideScheduleSettingsAtServer();
	EndIf;
	
	Modified = True;
	
EndProcedure

&AtClient
Procedure ScheduleSelectorOnChange(Item)
	
	SetScheduleSettingsAtServer();
	Modified = True;
	
EndProcedure

#EndRegion

#Region FormCommandHandlers

&AtClient
Procedure ExecuteCheck(Command)
	
	If Not Write() Then
		Return;
	EndIf;	
	
	If Not Object.Use Then
		CompletionNotification = New NotifyDescription("ExecuteCheckAfterQuestion", ThisObject);
		ShowQueryBox(CompletionNotification, NStr("ru = 'Проверка отключена. Все равно выполнить?'; en = 'Check is disabled. Check anyway?'; pl = 'Check is disabled. Check anyway?';de = 'Check is disabled. Check anyway?';ro = 'Check is disabled. Check anyway?';tr = 'Check is disabled. Check anyway?'; es_ES = 'Check is disabled. Check anyway?'"), QuestionDialogMode.YesNo);
		Return;
	EndIf;	
	
	ExecuteCheckAfterQuestion(DialogReturnCode.Yes, Undefined);
	
EndProcedure

&AtClient
Procedure CustomizeStandardSettings(Command)
	
	QuestionText = NStr("ru = 'Установить стандартные настройки?'; en = 'Set standard settings?'; pl = 'Set standard settings?';de = 'Set standard settings?';ro = 'Set standard settings?';tr = 'Set standard settings?'; es_ES = 'Set standard settings?'");
	Handler = New NotifyDescription("SetStandardSettingsAtClient", ThisObject);
	ShowQueryBox(Handler, QuestionText, QuestionDialogMode.YesNo);
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Function RunCheckAtServer()
	
	If TimeConsumingOperation <> Undefined Then
		TimeConsumingOperations.CancelJobExecution(TimeConsumingOperation.JobID);
	EndIf;
	
	ExecutionParameters = TimeConsumingOperations.BackgroundExecutionParameters(UUID);
	ExecutionParameters.BackgroundJobDescription = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("ru = 'Выполнение проверки ведения учета ""%1""'; en = 'Checking accounting ""%1""'; pl = 'Checking accounting ""%1""';de = 'Checking accounting ""%1""';ro = 'Checking accounting ""%1""';tr = 'Checking accounting ""%1""'; es_ES = 'Checking accounting ""%1""'"), Object.Description);
	
	ParametersArray = New Array;
	
	JobParameters = New Structure;
	JobParameters.Insert("ID",                          Object.ID);
	JobParameters.Insert("Description",                           Object.Description);
	JobParameters.Insert("ScheduledJobID",      Object.ScheduledJobID);
	JobParameters.Insert("CheckStartDate",                     Object.CheckStartDate);
	JobParameters.Insert("IssuesLimit",                           Object.IssuesLimit);
	JobParameters.Insert("RunMethod",                       Object.RunMethod);
	JobParameters.Insert("IssueSeverity",                       Object.IssueSeverity);
	JobParameters.Insert("AccountingChecksContext",           Object.AccountingChecksContext);
	JobParameters.Insert("AccountingCheckContextClarification", Object.AccountingCheckContextClarification);
	JobParameters.Insert("CheckWasStopped",                False);
	JobParameters.Insert("ManualStart",                           True);
	
	ParametersArray.Add(JobParameters);
	
	Return TimeConsumingOperations.ExecuteInBackground("AccountingAuditInternal.ExecuteChecksInBackgroundJob", 
		New Structure("ParametersArray", ParametersArray), ExecutionParameters);
	
EndFunction

&AtClient
Procedure ExecuteCheckAfterQuestion(QuestionResult, AdditionalParameters) Export
	
	If QuestionResult <> DialogReturnCode.Yes Then
		Return;
	EndIf;	
	
	TimeConsumingOperation = RunCheckAtServer();
	
	CompletionNotification = New NotifyDescription("ExecuteCheckCompletion", ThisObject);
	IdleParameters = TimeConsumingOperationsClient.IdleParameters(ThisObject);
	IdleParameters.MessageText = NStr("ru = 'Выполняется проверка. Это может занять некоторое время.'; en = 'Checking. This might take a while.'; pl = 'Checking. This might take a while.';de = 'Checking. This might take a while.';ro = 'Checking. This might take a while.';tr = 'Checking. This might take a while.'; es_ES = 'Checking. This might take a while.'");
	TimeConsumingOperationsClient.WaitForCompletion(TimeConsumingOperation, CompletionNotification, IdleParameters);
	
EndProcedure
	
&AtClient
Procedure ExecuteCheckCompletion(Result, AdditionalParameters) Export
	
	If Result = Undefined Then
		Return;
	EndIf;
	
	If Result.Status = "Error" Then
		Raise Result.BriefErrorPresentation;
	ElsIf Result.Status = "Completed" Then
		ShowUserNotification(NStr("ru = 'Проверка выполнена'; en = 'Check is completed'; pl = 'Check is completed';de = 'Check is completed';ro = 'Check is completed';tr = 'Check is completed'; es_ES = 'Check is completed'"),,
			NStr("ru = 'Проверка ведения учета завершена успешно.'; en = 'Accounting check is successfully completed.'; pl = 'Accounting check is successfully completed.';de = 'Accounting check is successfully completed.';ro = 'Accounting check is successfully completed.';tr = 'Accounting check is successfully completed.'; es_ES = 'Accounting check is successfully completed.'"));
	EndIf;
	
EndProcedure

&AtServer
Procedure GenerateSchedules()
	
	GenerateRowWithCommonSchedule();
	GenerateRowWithIndividualSchedule();
	
EndProcedure

&AtServer
Procedure GenerateRowWithIndividualSchedule()
	
	ScheduledJobID = Object.ScheduledJobID;
	SeparateScheduledJob      = Undefined;
	SeparateScheduledJobPresentation  = "";
	
	If ValueIsFilled(ScheduledJobID) Then
		SeparateScheduledJob = ScheduledJobsServer.Job(ScheduledJobID);
		If SeparateScheduledJob <> Undefined Then
			SeparateScheduledJobPresentation = String(SeparateScheduledJob.Schedule) + ". ";
		EndIf;
	EndIf;
	
	If Not Common.DataSeparationEnabled() Then
		
		If SeparateScheduledJob = Undefined Then
			Items.IndividualSchedulePresentation.Title = 
				New FormattedString(NStr("ru='Настроить расписание'; en = 'Set schedule'; pl = 'Set schedule';de = 'Set schedule';ro = 'Set schedule';tr = 'Set schedule'; es_ES = 'Set schedule'"), , , , PutToTempStorage("AddJob", UUID));
		Else
			Items.IndividualSchedulePresentation.Title = 
				New FormattedString(SeparateScheduledJobPresentation, , , , PutToTempStorage(SeparateScheduledJob.Schedule, UUID));
		EndIf;
		
	Else
		
		If SeparateScheduledJob = Undefined Then
			Items.IndividualSchedulePresentation.Title = 
				New FormattedString(SeparateScheduledJobPresentation + ". ", , StyleColors.HyperlinkColor);
		Else
			Items.IndividualSchedulePresentation.Title = 
				New FormattedString(SeparateScheduledJobPresentation, , StyleColors.HyperlinkColor);
		EndIf;
		
	EndIf;
	
EndProcedure

&AtServer
Procedure GenerateRowWithCommonSchedule()
	
	CommonScheduledJob = ScheduledJobsServer.Job(Metadata.ScheduledJobs.AccountingCheck);
	If CommonScheduledJob <> Undefined Then
		If Not Common.DataSeparationEnabled() Then
			CommonSchedulePresentation = String(CommonScheduledJob.Schedule);
		Else
			If Users.IsFullUser(, True) Then
				CommonSchedulePresentation = String(CommonScheduledJob.Template.Schedule.Get());
			EndIf;
		EndIf;
	Else
		CommonSchedulePresentation = NStr("ru = 'Не найдено общее регламентное задание'; en = 'Common scheduled job is not found'; pl = 'Common scheduled job is not found';de = 'Common scheduled job is not found';ro = 'Common scheduled job is not found';tr = 'Common scheduled job is not found'; es_ES = 'Common scheduled job is not found'");
	EndIf;
	
	Items.PresentationOfCommonSchedule.Title = 
		New FormattedString(CommonSchedulePresentation, , StyleColors.HyperlinkColor);
	
EndProcedure

&AtClient
Procedure ChangeTaskOnClientCompletion(Schedule, AdditionalParameters) Export
	ChangeJobAtServerCompletion(Schedule, AdditionalParameters);
EndProcedure

&AtServer
Procedure ChangeJobAtServerCompletion(Schedule, AdditionalParameters)
	
	If Schedule = Undefined Then
		Return;
	EndIf;
	
	ScheduledJob = ScheduledJobsServer.Job(Object.ScheduledJobID);
	If ScheduledJob = Undefined Then
		AddJobAtServerCompletion(Schedule, AdditionalParameters);
	Else
		
		ScheduledJobsServer.ChangeJob(Object.ScheduledJobID, New Structure("Schedule", Schedule));
		Items.IndividualSchedulePresentation.Title = 
			New FormattedString(String(Schedule), , , , PutToTempStorage(Schedule, UUID));
		
		IndividualScheduleAddress = PutToTempStorage(New ValueStorage(CommonClientServer.ScheduleToStructure(Schedule)), UUID);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure AddJobAtClientCompletion(Schedule, AdditionalParameters) Export
	AddJobAtServerCompletion(Schedule, AdditionalParameters);
EndProcedure

&AtServer
Procedure AddJobAtServerCompletion(Schedule, AdditionalParameters)
		
	If Schedule = Undefined Then
		Return;
	EndIf;
	
	JobParameters = New Structure;
	JobParameters.Insert("Schedule",    Schedule);
	JobParameters.Insert("Use", True);
	JobParameters.Insert("Metadata",    Metadata.ScheduledJobs.AccountingCheck);
	
	ScheduledJob = ScheduledJobsServer.AddJob(JobParameters);
	
	Object.ScheduledJobID = String(ScheduledJob.UUID);
	
	JobParameters = New Structure;
	
	ParametersArray = New Array;
	ParametersArray.Add(String(ScheduledJob.UUID));
	
	JobParameters.Insert("Parameters", ParametersArray);
	ScheduledJobsServer.ChangeJob(ScheduledJob.UUID, JobParameters);
	
	Items.IndividualSchedulePresentation.Title =
		New FormattedString(String(Schedule), , , , PutToTempStorage(Schedule, UUID));
		
	IndividualScheduleAddress = PutToTempStorage(New ValueStorage(CommonClientServer.ScheduleToStructure(Schedule)), UUID);
	
EndProcedure

&AtServerNoContext
Function CheckMetadata(ID)
	
	CheckStructure = New Structure;
	Checks          = AccountingAuditInternalCached.AccountingChecks().Validation;
	CheckString    = Checks.Find(ID, "ID");
	
	If CheckString = Undefined Then
		Return Undefined;
	Else
		ChecksColumns = Checks.Columns;
		For Each CurrentColumn In ChecksColumns Do
			CheckStructure.Insert(CurrentColumn.Name, CheckString[CurrentColumn.Name]);
		EndDo;
	EndIf;
	
	Return CheckStructure;
	
EndFunction

&AtServerNoContext
Procedure SetImportanceFieldAccessibility(Form, CurrentCheckMetadata)
	Form.Items.IssueSeverity.Enabled = Not (CurrentCheckMetadata <> Undefined AND CurrentCheckMetadata.ImportanceChangeDenied);
EndProcedure

&AtServerNoContext
Procedure SetPathToHandlerProcedure(Form, CurrentCheckMetadata)
	Form.HandlerProcedurePath = ?(CurrentCheckMetadata = Undefined, NStr("ru = 'Не задан обработчик'; en = 'Handler is not defined'; pl = 'Handler is not defined';de = 'Handler is not defined';ro = 'Handler is not defined';tr = 'Handler is not defined'; es_ES = 'Handler is not defined'"), CurrentCheckMetadata.CheckHandler);
EndProcedure

&AtClient
Procedure SetStandardSettingsAtClient(Response, ExecutionParameters) Export
	
	If Response = DialogReturnCode.No Then
		Return;
	EndIf;
	
	SetStandardSettingsAtServer();
	Modified = True;
	
EndProcedure

&AtServer
Procedure SetStandardSettingsAtServer()
	
	CurrentCheckMetadata = CheckMetadata(Object.ID);
	If CurrentCheckMetadata = Undefined Then
		Raise StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Рассинхронизация проверок учета. Проверка с идентификатором ""%1"" не найдена в метаданных.'; en = 'Accounting check synchronization error. The check with ID %1 is not found in metadata.'; pl = 'Accounting check synchronization error. The check with ID %1 is not found in metadata.';de = 'Accounting check synchronization error. The check with ID %1 is not found in metadata.';ro = 'Accounting check synchronization error. The check with ID %1 is not found in metadata.';tr = 'Accounting check synchronization error. The check with ID %1 is not found in metadata.'; es_ES = 'Accounting check synchronization error. The check with ID %1 is not found in metadata.'"), Object.ID);
	EndIf;
		
	FillPropertyValues(Object, CurrentCheckMetadata, , "ID");
	Object.AccountingCheckIsChanged = False;
	
EndProcedure

&AtServer
Procedure SetScheduleSettingsAtServer()
	
	If ScheduleSelector = 0 Then
		
		If Object.RunMethod = Enums.CheckMethod.ByCommonSchedule Then
			
			ScheduleSelector = 1;
			
			Items.ScheduleSelector.Enabled                     = True;
			Items.IndividualSchedulePresentation.Enabled = False;
			Items.PresentationOfCommonSchedule.Enabled          = True;
			
		ElsIf Object.RunMethod = Enums.CheckMethod.OnSeparateSchedule Then
			
			ScheduleSelector = 2;
			
			Items.ScheduleSelector.Enabled                     = True;
			Items.IndividualSchedulePresentation.Enabled = True;
			Items.PresentationOfCommonSchedule.Enabled          = False;
			
		EndIf;
		
	ElsIf ScheduleSelector = 1 Then
		
		Object.RunMethod = Enums.CheckMethod.ByCommonSchedule;
		Items.ScheduleSelector.Enabled                     = True;
		Items.IndividualSchedulePresentation.Enabled = False;
		Items.PresentationOfCommonSchedule.Enabled          = True;
		
	ElsIf ScheduleSelector = 2 Then
		
		Object.RunMethod = Enums.CheckMethod.OnSeparateSchedule;
		Items.ScheduleSelector.Enabled                     = True;
		Items.IndividualSchedulePresentation.Enabled = True;
		Items.PresentationOfCommonSchedule.Enabled          = False;
		
	EndIf;
	
EndProcedure

&AtServer
Procedure HideScheduleSettingsAtServer()
	
	Object.RunMethod = Enums.CheckMethod.Manually;
	Items.ScheduleSelector.Enabled                     = False;
	Items.IndividualSchedulePresentation.Enabled = False;
	Items.PresentationOfCommonSchedule.Enabled          = False;
	
EndProcedure

&AtServer
Procedure SetInitialScheduleSettings()
	
	If Object.RunMethod = Enums.CheckMethod.ByCommonSchedule Then
		
		RunsInBackgroundOnSchedule = True;
		ScheduleSelector           = 1;
		
		Items.ScheduleSelector.Enabled                     = True;
		Items.IndividualSchedulePresentation.Enabled = False;
		Items.PresentationOfCommonSchedule.Enabled          = True;
		
	ElsIf Object.RunMethod = Enums.CheckMethod.OnSeparateSchedule Then
		
		RunsInBackgroundOnSchedule = True;
		ScheduleSelector           = 2;
		
		Items.ScheduleSelector.Enabled                     = True;
		Items.IndividualSchedulePresentation.Enabled = True;
		Items.PresentationOfCommonSchedule.Enabled          = False;
		
	Else
		
		RunsInBackgroundOnSchedule = False;
		ScheduleSelector           = 1;
		
		Items.ScheduleSelector.Enabled                     = False;
		Items.IndividualSchedulePresentation.Enabled = False;
		Items.PresentationOfCommonSchedule.Enabled          = False
		
	EndIf;
	
EndProcedure

// StandardSubsystems.AttachableCommands

&AtClient
Procedure Attachable_ExecuteCommand(Command)
	AttachableCommandsClient.ExecuteCommand(ThisObject, Command, Object);
EndProcedure

&AtServer
Procedure Attachable_ExecuteCommandAtServer(Context, Result)
	AttachableCommands.ExecuteCommand(ThisObject, Context, Object, Result);
EndProcedure

&AtClient
Procedure Attachable_UpdateCommands()
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
EndProcedure

// End StandardSubsystems.AttachableCommands

#EndRegion