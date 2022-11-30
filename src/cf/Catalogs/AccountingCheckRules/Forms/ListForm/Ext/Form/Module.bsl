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
		
	SetConditionalAppearance();
	
	AccountingCheckRulesSettingAllowed = AccessRight("Update", Metadata.Catalogs.AccountingCheckRules);
	Items.FormExecuteCheck.Visible = AccountingCheckRulesSettingAllowed;
	Items.ListContextMenuExecuteCheck.Visible = AccountingCheckRulesSettingAllowed;
	Items.FormRestoreByInitialFilling.Visible = AccountingCheckRulesSettingAllowed;
	
	IsSystemAdministrator = Users.IsFullUser(, True);
	
	If Not ( (Not Common.DataSeparationEnabled() AND AccountingCheckRulesSettingAllowed)
		Or (Common.DataSeparationEnabled() AND IsSystemAdministrator) ) Then
		
		Items.PresentationOfCommonSchedule.Visible    = False;
		Items.ScheduledJobPresentation.Visible = False;
		
	Else
		
		CommonScheduledJob = ScheduledJobsServer.Job(Metadata.ScheduledJobs.AccountingCheck);
		If CommonScheduledJob <> Undefined Then
			If Not Common.DataSeparationEnabled() Then
				CommonSchedulePresentation = String(CommonScheduledJob.Schedule)
			Else
				If IsSystemAdministrator Then
					CommonSchedulePresentation = String(CommonScheduledJob.Template.Schedule.Get());
					Items.ScheduledJobPresentation.Visible = True;
				Else
					Items.ScheduledJobPresentation.Visible = False;
					Items.PresentationOfCommonSchedule.Visible    = False;
					CommonSchedulePresentation                        = "";
				EndIf;
			EndIf;
		Else
			If (Common.DataSeparationEnabled() AND IsSystemAdministrator) Or Not Common.DataSeparationEnabled() Then
				CommonSchedulePresentation = NStr("ru = 'Не найдено общее регламентное задание'; en = 'Common scheduled job is not found'; pl = 'Common scheduled job is not found';de = 'Common scheduled job is not found';ro = 'Common scheduled job is not found';tr = 'Common scheduled job is not found'; es_ES = 'Common scheduled job is not found'");
			Else
				CommonSchedulePresentation                     = "";
				Items.PresentationOfCommonSchedule.Visible = False;
			EndIf;
		EndIf;
		
		List.SettingsComposer.Settings.AdditionalProperties.Insert("PresentationOfCommonSchedule", CommonSchedulePresentation);
		
		Items.PresentationOfCommonSchedule.Title = GenerateRowWithSchedule();
		
	EndIf;
	
	Items.PresentationOfCommonSchedule.Enabled = InfobaseUpdate.ObjectProcessed(
		Metadata.Catalogs.AccountingCheckRules.FullName()).Processed;
	
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure ListBeforeAddRow(Item, Cancel, Clone, Parent, Folder, Parameter)
	
	Cancel = True;
	
EndProcedure

&AtServerNoContext
Procedure ListOnReceiveDataAtServer(ItemName, Settings, Rows)
	
	ComposerAdditionalProperties = Settings.AdditionalProperties;
	If Not ComposerAdditionalProperties.Property("PresentationOfCommonSchedule") Then
		Return;
	EndIf;
	
	RowsKeys = Rows.GetKeys();
	For Each RowKey In RowsKeys Do
		RowData = Rows[RowKey].Data;
		If RowData.IsFolder Then
			Continue;
		EndIf;
		If RowData.RunMethod = Enums.CheckMethod.Manually Then
			RowData.ScheduledJobPresentation = NStr("ru = 'Вручную'; en = 'Manually'; pl = 'Manually';de = 'Manually';ro = 'Manually';tr = 'Manually'; es_ES = 'Manually'");
		ElsIf RowData.RunMethod = Enums.CheckMethod.ByCommonSchedule Then
			RowData.ScheduledJobPresentation = NStr("ru = 'По общему расписанию'; en = 'On common schedule'; pl = 'On common schedule';de = 'On common schedule';ro = 'On common schedule';tr = 'On common schedule'; es_ES = 'On common schedule'")
		ElsIf RowData.RunMethod = Enums.CheckMethod.OnSeparateSchedule Then
			JobID = RowData.ScheduledJobID;
			If Not ValueIsFilled(JobID) Then
				RowData.ScheduledJobPresentation = NStr("ru = 'Расписание не задано'; en = 'The schedule is not set'; pl = 'The schedule is not set';de = 'The schedule is not set';ro = 'The schedule is not set';tr = 'The schedule is not set'; es_ES = 'The schedule is not set'");
			Else
				FoundScheduledJob = ScheduledJobsServer.Job(New UUID(JobID));
				If FoundScheduledJob <> Undefined Then
					ScheduleAsString = String(FoundScheduledJob.Schedule);
				Else
					
					RuleObject = RowKey.GetObject();
					
					Parameters = New Structure;
					Parameters.Insert("Use", True);
					Parameters.Insert("Metadata",    Metadata.ScheduledJobs.AccountingCheck);
					Parameters.Insert("Schedule",    CommonClientServer.StructureToSchedule(
						RuleObject.CheckSchedule.Get()));
					
					RestoredJob = ScheduledJobsServer.AddJob(Parameters);
					
					JobParameters = New Structure;
					ParametersArray = New Array;
					ParametersArray.Add(String(RestoredJob.UUID));
					JobParameters.Insert("Parameters", ParametersArray);
					
					ScheduledJobsServer.ChangeJob(RestoredJob.UUID, JobParameters);
					
					RuleObject.ScheduledJobID = String(RestoredJob.UUID);
					InfobaseUpdate.WriteData(RuleObject);
					
					ScheduleAsString = String(RestoredJob.Schedule);
					
				EndIf;
				RowData.ScheduledJobPresentation = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("ru = 'По расписанию: ""%1""'; en = 'On schedule: ""%1""'; pl = 'On schedule: ""%1""';de = 'On schedule: ""%1""';ro = 'On schedule: ""%1""';tr = 'On schedule: ""%1""'; es_ES = 'On schedule: ""%1""'"), ScheduleAsString);
			EndIf;
		EndIf;
	EndDo;
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersList

&AtClient
Procedure ListOnActivateRow(Item)
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

#EndRegion

#Region FormCommandHandlers

&AtClient
Procedure ExecuteCheck(Command)
	
	Checks = EnabledChecks();
	If Checks.Count() = 0 Then
		Raise NStr("ru = 'Необходимо выбрать в списке одну или несколько проверок.'; en = 'Select one or several checks in the list.'; pl = 'Select one or several checks in the list.';de = 'Select one or several checks in the list.';ro = 'Select one or several checks in the list.';tr = 'Select one or several checks in the list.'; es_ES = 'Select one or several checks in the list.'");
	EndIf;
	
	TimeConsumingOperation = ExecuteChecksAtServer(Checks);
	
	CompletionNotification = New NotifyDescription("ExecuteCheckCompletion", ThisObject);
	IdleParameters = TimeConsumingOperationsClient.IdleParameters(ThisObject);
	IdleParameters.MessageText = NStr("ru = 'Выполняется проверка. Это может занять некоторое время.'; en = 'Checking. This might take a while.'; pl = 'Checking. This might take a while.';de = 'Checking. This might take a while.';ro = 'Checking. This might take a while.';tr = 'Checking. This might take a while.'; es_ES = 'Checking. This might take a while.'");
	TimeConsumingOperationsClient.WaitForCompletion(TimeConsumingOperation, CompletionNotification, IdleParameters);
	
EndProcedure

&AtClient
Procedure RestoreByInitialFilling(Command)
	RestoreByInitialFillingAtServer();
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SetConditionalAppearance()
	
	List.ConditionalAppearance.Items.Clear();
	
	// Disabled checks.
	
	Item = List.ConditionalAppearance.Items.Add();
	
	DataFilterItem = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	DataFilterItem.LeftValue = New DataCompositionField("Use");
	DataFilterItem.ComparisonType = DataCompositionComparisonType.Equal;
	DataFilterItem.RightValue = False;
	DataFilterItem.Use = True;
	
	AppearanceColorItem = Item.Appearance.Items.Find("TextColor");
	AppearanceColorItem.Value =  Metadata.StyleItems.InaccessibleCellTextColor.Value;   
	AppearanceColorItem.Use = True;

	// Do not display if the causes of an issue are not described.
	
	Item = List.ConditionalAppearance.Items.Add();
	
	FormattedField = Item.Fields.Items.Add();
	FormattedField.Field = New DataCompositionField(Items.Reasons.Name);
	FormattedField.Use = True;
	
	DataFilterItem = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	DataFilterItem.LeftValue = New DataCompositionField("Reasons");
	DataFilterItem.ComparisonType = DataCompositionComparisonType.NotFilled;
	DataFilterItem.Use = True;
	
	AppearanceColorItem = Item.Appearance.Items.Find("Visible");
	AppearanceColorItem.Value = False;   
	AppearanceColorItem.Use = True;
	
EndProcedure

&AtServer
Function ExecuteChecksAtServer(Checks)
	
	If TimeConsumingOperation <> Undefined Then
		TimeConsumingOperations.CancelJobExecution(TimeConsumingOperation.JobID);
	EndIf;
	
	ExecutionParameters = TimeConsumingOperations.BackgroundExecutionParameters(UUID);
	ExecutionParameters.BackgroundJobDescription = NStr("ru = 'Выполнение проверок ведения учета'; en = 'Checking accounting'; pl = 'Checking accounting';de = 'Checking accounting';ro = 'Checking accounting';tr = 'Checking accounting'; es_ES = 'Checking accounting'");
	
	ParametersArray = New Array;
	For Each CheckSSL In Checks Do
		
		CheckAttributes = Common.ObjectAttributesValues(CheckSSL,
			"ID, Description, ScheduledJobID,
			|CheckStartDate, IssuesLimit, RunMethod");
		
		CheckParameters = New Structure;
		CheckParameters.Insert("ID",                     CheckAttributes.ID);
		CheckParameters.Insert("Description",                      CheckAttributes.Description);
		CheckParameters.Insert("ScheduledJobID", CheckAttributes.ScheduledJobID);
		CheckParameters.Insert("CheckStartDate",                CheckAttributes.CheckStartDate);
		CheckParameters.Insert("IssuesLimit",                      CheckAttributes.IssuesLimit);
		CheckParameters.Insert("RunMethod",                  CheckAttributes.RunMethod);
		CheckParameters.Insert("CheckWasStopped",           False);
		CheckParameters.Insert("ManualStart",                      True);
		
		ParametersArray.Add(CheckParameters);
		
	EndDo;
	
	Return TimeConsumingOperations.ExecuteInBackground("AccountingAuditInternal.ExecuteChecksInBackgroundJob", 
		New Structure("ParametersArray", ParametersArray), ExecutionParameters);
	
EndFunction

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
Procedure RestoreByInitialFillingAtServer()
	
	AccountingAuditInternal.UpdateAccountingChecksParameters();
	If AccountingAuditInternal.HasChangesOfAccountingChecksParameters() Then
		AccountingAuditInternal.UpdateAuxiliaryRegisterDataByConfigurationChanges();
	EndIf;
	
EndProcedure

&AtClient
Function EnabledChecks()
	
	Result = New Array;
	For Each CheckSSL In Items.List.SelectedRows Do
		CheckData = Items.List.RowData(CheckSSL);
		If CheckData <> Undefined AND Not CheckData.IsFolder Then
			Result.Add(CheckData.Ref);
		EndIf;
	EndDo;
	Return Result;
	
EndFunction

&AtServer
Function GenerateRowWithSchedule()
	
	CommonScheduledJob = ScheduledJobsServer.Job(Metadata.ScheduledJobs.AccountingCheck);
	If CommonScheduledJob <> Undefined Then
		If Not Common.DataSeparationEnabled() Then
			CommonSchedule              = CommonScheduledJob.Schedule;
			CommonSchedulePresentation = String(CommonScheduledJob.Schedule);
		Else
			If Users.IsFullUser(, True) Then
				CommonSchedule              = CommonScheduledJob.Template.Schedule.Get();
				CommonSchedulePresentation = String(CommonSchedule);
			Else
				CommonSchedule = Undefined;
				CommonSchedulePresentation = NStr("ru = 'Просмотр расписания недоступен'; en = 'Viewing schedule is unavailable'; pl = 'Viewing schedule is unavailable';de = 'Viewing schedule is unavailable';ro = 'Viewing schedule is unavailable';tr = 'Viewing schedule is unavailable'; es_ES = 'Viewing schedule is unavailable'");
			EndIf;
		EndIf;
	Else
		CommonSchedule              = Undefined;
		CommonSchedulePresentation = NStr("ru = 'Не найдено общее регламентное задание'; en = 'Common scheduled job is not found'; pl = 'Common scheduled job is not found';de = 'Common scheduled job is not found';ro = 'Common scheduled job is not found';tr = 'Common scheduled job is not found'; es_ES = 'Common scheduled job is not found'");
	EndIf;
	
	If Not Common.DataSeparationEnabled() Then
		
		TextRef = PutToTempStorage(CommonSchedule, UUID);
	
		Return New FormattedString(NStr("ru='Общее расписание выполнения проверок:'; en = 'Common checks schedule:'; pl = 'Common checks schedule:';de = 'Common checks schedule:';ro = 'Common checks schedule:';tr = 'Common checks schedule:'; es_ES = 'Common checks schedule:'") + " ",
			New FormattedString(CommonSchedulePresentation, , , , TextRef));
			
	Else
			
		Return New FormattedString(NStr("ru='Общее расписание выполнения проверок:'; en = 'Common checks schedule:'; pl = 'Common checks schedule:';de = 'Common checks schedule:';ro = 'Common checks schedule:';tr = 'Common checks schedule:'; es_ES = 'Common checks schedule:'") + " ",
			New FormattedString(CommonSchedulePresentation, , StyleColors.HyperlinkColor));
			
	EndIf;
	
EndFunction

&AtClient
Procedure PresentationOfCommonScheduleURLProcessing(Item, FormattedStringURL, StandardProcessing)
	
	StandardProcessing = False;
	
	Dialog     = New ScheduledJobDialog(GetFromTempStorage(FormattedStringURL));
	Notification = New NotifyDescription("PresentationOfCommonScheduleClickAtClientCompletion", ThisObject);
	Dialog.Show(Notification);
	
EndProcedure

&AtClient
Procedure PresentationOfCommonScheduleClickAtClientCompletion(Schedule, AdditionalParameters) Export
	PresentationOfCommonScheduleClickAtServerCompletion(Schedule, AdditionalParameters);
EndProcedure

&AtServer
Procedure PresentationOfCommonScheduleClickAtServerCompletion(Schedule, AdditionalParameters)
	
	If Schedule = Undefined Then
		Return;
	EndIf;
	
	CommonJobID = ScheduledJobsServer.UUID(Metadata.ScheduledJobs.AccountingCheck);
	ScheduledJobsServer.ChangeJob(CommonJobID, New Structure("Schedule", Schedule));
	
	Items.PresentationOfCommonSchedule.Title = GenerateRowWithSchedule();
	
	List.SettingsComposer.Settings.AdditionalProperties.Insert("PresentationOfCommonSchedule", String(Schedule));
	Items.List.Refresh();
	
EndProcedure

// StandardSubsystems.AttachableCommands
&AtClient
Procedure Attachable_ExecuteCommand(Command)
	AttachableCommandsClient.ExecuteCommand(ThisObject, Command, Items.List);
EndProcedure

&AtServer
Procedure Attachable_ExecuteCommandAtServer(Context, Result)
	AttachableCommands.ExecuteCommand(ThisObject, Context, Items.List, Result);
EndProcedure

&AtClient
Procedure Attachable_UpdateCommands()
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Items.List);
EndProcedure

// End StandardSubsystems.AttachableCommands

#EndRegion
