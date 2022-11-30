///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Public

////////////////////////////////////////////////////////////////////////////////
// Commands for business processes.

// Marks the specified business process as stopped.
//
// Parameters:
//  CommandParameters - Array, BusinessProcessRef - an array of references to business processes or a business process.
//
Procedure Stop(Val CommandParameter) Export
	
	QuestionText = "";
	TaskCount = 0;
	
	If TypeOf(CommandParameter) = Type("Array") Then
		
		If CommandParameter.Count() = 0 Then
			ShowMessageBox(,NStr("ru= 'Не выбран ни один бизнес-процесс.'; en = 'No business process is selected.'; pl = 'No business process is selected.';de = 'No business process is selected.';ro = 'No business process is selected.';tr = 'No business process is selected.'; es_ES = 'No business process is selected.'"));
			Return;
		EndIf;
		
		If CommandParameter.Count() = 1 AND TypeOf(CommandParameter[0]) = Type("DynamicalListGroupRow") Then
			ShowMessageBox(,NStr("ru= 'Не выбран ни один бизнес-процесс.'; en = 'No business process is selected.'; pl = 'No business process is selected.';de = 'No business process is selected.';ro = 'No business process is selected.';tr = 'No business process is selected.'; es_ES = 'No business process is selected.'"));
			Return;
		EndIf;
		
		TaskCount = BusinessProcessesAndTasksServerCall.UncompletedBusinessProcessesTasksCount(CommandParameter);
		If CommandParameter.Count() = 1 Then
			If TaskCount > 0 Then
				QuestionText = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("ru = 'Будет выполнена остановка бизнес-процесса ""%1"" и всех его невыполненных задач (%2). Продолжить?'; en = 'Business process ""%1"" and all its unfinished tasks (%2) will be stopped. Continue?'; pl = 'Business process ""%1"" and all its unfinished tasks (%2) will be stopped. Continue?';de = 'Business process ""%1"" and all its unfinished tasks (%2) will be stopped. Continue?';ro = 'Business process ""%1"" and all its unfinished tasks (%2) will be stopped. Continue?';tr = 'Business process ""%1"" and all its unfinished tasks (%2) will be stopped. Continue?'; es_ES = 'Business process ""%1"" and all its unfinished tasks (%2) will be stopped. Continue?'"), 
					String(CommandParameter[0]), TaskCount);
			Else
				QuestionText = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("ru = 'Будет выполнена остановка бизнес-процесса ""%1"". Продолжить?'; en = 'Business process ""%1"" will be stopped. Continue?'; pl = 'Business process ""%1"" will be stopped. Continue?';de = 'Business process ""%1"" will be stopped. Continue?';ro = 'Business process ""%1"" will be stopped. Continue?';tr = 'Business process ""%1"" will be stopped. Continue?'; es_ES = 'Business process ""%1"" will be stopped. Continue?'"), 
					String(CommandParameter[0]));
			EndIf;
		Else
			QuestionText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'Будет выполнена остановка бизнес-процессов (%1) и всех их невыполненных задач (%2). Продолжить?'; en = 'Business processes (%1) and all their unfinished tasks (%2) will be stopped. Continue?'; pl = 'Business processes (%1) and all their unfinished tasks (%2) will be stopped. Continue?';de = 'Business processes (%1) and all their unfinished tasks (%2) will be stopped. Continue?';ro = 'Business processes (%1) and all their unfinished tasks (%2) will be stopped. Continue?';tr = 'Business processes (%1) and all their unfinished tasks (%2) will be stopped. Continue?'; es_ES = 'Business processes (%1) and all their unfinished tasks (%2) will be stopped. Continue?'"), 
				CommandParameter.Count(), TaskCount);
		EndIf;
		
	Else
		
		If TypeOf(CommandParameter) = Type("DynamicalListGroupRow") Then
			ShowMessageBox(,NStr("ru= 'Не выбран ни один бизнес-процесс'; en = 'No business process is selected'; pl = 'No business process is selected';de = 'No business process is selected';ro = 'No business process is selected';tr = 'No business process is selected'; es_ES = 'No business process is selected'"));
			Return;
		EndIf;
		
		TaskCount = BusinessProcessesAndTasksServerCall.UncompletedBusinessProcessTasksCount(CommandParameter);
		If TaskCount > 0 Then
			QuestionText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'Будет выполнена остановка бизнес-процесса ""%1"" и всех его невыполненных задач (%2). Продолжить?'; en = 'Business process ""%1"" and all its unfinished tasks (%2) will be stopped. Continue?'; pl = 'Business process ""%1"" and all its unfinished tasks (%2) will be stopped. Continue?';de = 'Business process ""%1"" and all its unfinished tasks (%2) will be stopped. Continue?';ro = 'Business process ""%1"" and all its unfinished tasks (%2) will be stopped. Continue?';tr = 'Business process ""%1"" and all its unfinished tasks (%2) will be stopped. Continue?'; es_ES = 'Business process ""%1"" and all its unfinished tasks (%2) will be stopped. Continue?'"), 
				String(CommandParameter), TaskCount);
		Else
			QuestionText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'Будет выполнена остановка бизнес-процесса ""%1"". Продолжить?'; en = 'Business process ""%1"" will be stopped. Continue?'; pl = 'Business process ""%1"" will be stopped. Continue?';de = 'Business process ""%1"" will be stopped. Continue?';ro = 'Business process ""%1"" will be stopped. Continue?';tr = 'Business process ""%1"" will be stopped. Continue?'; es_ES = 'Business process ""%1"" will be stopped. Continue?'"), 
				String(CommandParameter));
		EndIf;
		
	EndIf;
	
	Notification = New NotifyDescription("StopCompletion", ThisObject, CommandParameter);
	ShowQueryBox(Notification, QuestionText, QuestionDialogMode.YesNo, , DialogReturnCode.No, NStr("ru = 'Остановка бизнес-процесса'; en = 'Stop business process'; pl = 'Stop business process';de = 'Stop business process';ro = 'Stop business process';tr = 'Stop business process'; es_ES = 'Stop business process'"));
	
EndProcedure

// Marks the specified business process as stopped.
//  The procedure is intended for calling from a business process form.
//
// Parameters:
//  Form - ManagedForm - a business process form.
//
Procedure StopBusinessProcessFromObjectForm(Form) Export
	Form.Object.State = PredefinedValue("Enum.BusinessProcessStates.Stopped");
	ClearMessages();
	Form.Write();
	ShowUserNotification(
		NStr("ru = 'Бизнес-процесс остановлен'; en = 'The business process is stopped'; pl = 'The business process is stopped';de = 'The business process is stopped';ro = 'The business process is stopped';tr = 'The business process is stopped'; es_ES = 'The business process is stopped'"),
		GetURL(Form.Object.Ref),
		String(Form.Object.Ref),
		PictureLib.Information32);
	NotifyChanged(Form.Object.Ref);
	
EndProcedure

// Marks the specified business processes as active.
//
// Parameters:
//  CommandParameter - Array, DynamicListGroupRow, BusinessProcessesRef - a business process.
//
Procedure Activate(Val CommandParameter) Export
	
	QuestionText = "";
	TaskCount = 0;
	
	If TypeOf(CommandParameter) = Type("Array") Then
		
		If CommandParameter.Count() = 0 Then
			ShowMessageBox(,NStr("ru= 'Не выбран ни один бизнес-процесс.'; en = 'No business process is selected.'; pl = 'No business process is selected.';de = 'No business process is selected.';ro = 'No business process is selected.';tr = 'No business process is selected.'; es_ES = 'No business process is selected.'"));
			Return;
		EndIf;
		
		If CommandParameter.Count() = 1 AND TypeOf(CommandParameter[0]) = Type("DynamicalListGroupRow") Then
			ShowMessageBox(,NStr("ru= 'Не выбран ни один бизнес-процесс.'; en = 'No business process is selected.'; pl = 'No business process is selected.';de = 'No business process is selected.';ro = 'No business process is selected.';tr = 'No business process is selected.'; es_ES = 'No business process is selected.'"));
			Return;
		EndIf;
		
		TaskCount = BusinessProcessesAndTasksServerCall.UncompletedBusinessProcessesTasksCount(CommandParameter);
		If CommandParameter.Count() = 1 Then
			QuestionText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'Бизнес-процесс ""%1"" и все его задачи (%2) будут сделаны активными. Продолжить?'; en = 'Business process ""%1"" and its tasks (%2) will be active. Continue?'; pl = 'Business process ""%1"" and its tasks (%2) will be active. Continue?';de = 'Business process ""%1"" and its tasks (%2) will be active. Continue?';ro = 'Business process ""%1"" and its tasks (%2) will be active. Continue?';tr = 'Business process ""%1"" and its tasks (%2) will be active. Continue?'; es_ES = 'Business process ""%1"" and its tasks (%2) will be active. Continue?'"),
				String(CommandParameter[0]), TaskCount);
		Else		
			QuestionText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'Бизнес-процессы (%1) и их задачи (%2) будут сделаны активными. Продолжить?'; en = 'Business processes (%1) and their tasks (%2) will be active. Continue?'; pl = 'Business processes (%1) and their tasks (%2) will be active. Continue?';de = 'Business processes (%1) and their tasks (%2) will be active. Continue?';ro = 'Business processes (%1) and their tasks (%2) will be active. Continue?';tr = 'Business processes (%1) and their tasks (%2) will be active. Continue?'; es_ES = 'Business processes (%1) and their tasks (%2) will be active. Continue?'"),
				CommandParameter.Count(), TaskCount);
		EndIf;
		
	Else
		
		If TypeOf(CommandParameter) = Type("DynamicalListGroupRow") Then
			ShowMessageBox(,NStr("ru= 'Не выбран ни один бизнес-процесс.'; en = 'No business process is selected.'; pl = 'No business process is selected.';de = 'No business process is selected.';ro = 'No business process is selected.';tr = 'No business process is selected.'; es_ES = 'No business process is selected.'"));
			Return;
		EndIf;
		
		TaskCount = BusinessProcessesAndTasksServerCall.UncompletedBusinessProcessTasksCount(CommandParameter);
		QuestionText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Бизнес-процесс ""%1"" и все его задачи (%2) будут сделаны активными. Продолжить?'; en = 'Business process ""%1"" and its tasks (%2) will be active. Continue?'; pl = 'Business process ""%1"" and its tasks (%2) will be active. Continue?';de = 'Business process ""%1"" and its tasks (%2) will be active. Continue?';ro = 'Business process ""%1"" and its tasks (%2) will be active. Continue?';tr = 'Business process ""%1"" and its tasks (%2) will be active. Continue?'; es_ES = 'Business process ""%1"" and its tasks (%2) will be active. Continue?'"),
			String(CommandParameter), TaskCount);
			
	EndIf;
	
	Notification = New NotifyDescription("ActivateCompletion", ThisObject, CommandParameter);
	ShowQueryBox(Notification, QuestionText, QuestionDialogMode.YesNo, , DialogReturnCode.No, NStr("ru = 'Остановка бизнес-процесса'; en = 'Stop business process'; pl = 'Stop business process';de = 'Stop business process';ro = 'Stop business process';tr = 'Stop business process'; es_ES = 'Stop business process'"));
	
EndProcedure

// Marks the specified business processes as active.
//  The procedure is intended for calling from a business process form.
//
// Parameters:
//  Form - ManagedForm - a business process form.
//
Procedure ContinueBusinessProcessFromObjectForm(Form) Export
	
	Form.Object.State = PredefinedValue("Enum.BusinessProcessStates.Active");
	ClearMessages();
	Form.Write();
	ShowUserNotification(
		NStr("ru = 'Бизнес-процесс сделан активным'; en = 'The business process is activated'; pl = 'The business process is activated';de = 'The business process is activated';ro = 'The business process is activated';tr = 'The business process is activated'; es_ES = 'The business process is activated'"),
		GetURL(Form.Object.Ref),
		String(Form.Object.Ref),
		PictureLib.Information32);
	NotifyChanged(Form.Object.Ref);
	
EndProcedure

// Marks the specified task as accepted for execution.
//
// Parameters:
//  TaskArray - Array - an array of references to tasks.
//
Procedure AcceptTasksForExecution(Val TaskArray) Export
	
	BusinessProcessesAndTasksServerCall.AcceptTasksForExecution(TaskArray);
	If TaskArray.Count() = 0 Then
		ShowMessageBox(,NStr("ru = 'Команда не может быть выполнена для указанного объекта.'; en = 'Cannot run the command for the specified object.'; pl = 'Cannot run the command for the specified object.';de = 'Cannot run the command for the specified object.';ro = 'Cannot run the command for the specified object.';tr = 'Cannot run the command for the specified object.'; es_ES = 'Cannot run the command for the specified object.'"));
		Return;
	EndIf;
	
	TaskValueType = Undefined;
	For each Task In TaskArray Do
		If TypeOf(Task) <> Type("DynamicalListGroupRow") Then 
			TaskValueType = TypeOf(Task);
			Break;
		EndIf;
	EndDo;
	If TaskValueType <> Undefined Then
		NotifyChanged(TaskValueType);
	EndIf;
	
EndProcedure

// Marks the specified task as accepted for execution.
//
// Parameters:
//  Form - ManagedForm - a task form.
//  CurrentUser - CatalogRef.ExternalUsers, CatalogRef.Users - a reference to the current 
//                                                                                              application user.
//
Procedure AcceptTaskForExecution(Form, CurrentUser) Export
	
	Form.Object.AcceptedForExecution = True;
	
	// Setting empty AcceptForExecutionDate. It is filled in with the current session date before 
	// writing the task.
	Form.Object.AcceptForExecutionDate = Date('00010101');
	If NOT ValueIsFilled(Form.Object.Performer) Then
		Form.Object.Performer = CurrentUser;
	EndIf;
	
	ClearMessages();
	Form.Write();
	UpdateAcceptForExecutionCommandsAvailability(Form);
	NotifyChanged(Form.Object.Ref);
	
EndProcedure

// Marks the specified tasks as not accepted for execution.
//
// Parameters:
//  TaskArray - Array - an array of references to tasks.
//
Procedure CancelAcceptTasksForExecution(Val TaskArray) Export
	
	BusinessProcessesAndTasksServerCall.CancelAcceptTasksForExecution(TaskArray);
	
	If TaskArray.Count() = 0 Then
		ShowMessageBox(, NStr("ru = 'Команда не может быть выполнена для указанного объекта.'; en = 'Cannot run the command for the specified object.'; pl = 'Cannot run the command for the specified object.';de = 'Cannot run the command for the specified object.';ro = 'Cannot run the command for the specified object.';tr = 'Cannot run the command for the specified object.'; es_ES = 'Cannot run the command for the specified object.'"));
		Return;
	EndIf;
	
	TaskValueType = Undefined;
	For each Task In TaskArray Do
		If TypeOf(Task) <> Type("DynamicalListGroupRow") Then 
			TaskValueType = TypeOf(Task);
			Break;
		EndIf;
	EndDo;
	
	If TaskValueType <> Undefined Then
		NotifyChanged(TaskValueType);
	EndIf;
	
EndProcedure

// Marks the specified task as not accepted for execution.
//
// Parameters:
//  Form - ManagedForm - a task form.
//
Procedure CancelAcceptTaskForExecution(Form) Export
	
	Form.Object.AcceptedForExecution      = False;
	Form.Object.AcceptForExecutionDate = "00010101000000";
	If Not Form.Object.PerformerRole.IsEmpty() Then
		Form.Object.Performer = PredefinedValue("Catalog.Users.EmptyRef");
	EndIf;
	
	ClearMessages();
	Form.Write();
	UpdateAcceptForExecutionCommandsAvailability(Form);
	NotifyChanged(Form.Object.Ref);
	
EndProcedure

// Sets availability of commands for accepting for execution.
//
// Parameters:
//  Form - ManagedForm - a task form.
//
Procedure UpdateAcceptForExecutionCommandsAvailability(Form) Export
	
	If Form.Object.AcceptedForExecution = True Then
		Form.Items.FormAcceptForExecution.Enabled = False;
		
		If Form.Object.Executed Then
			Form.Items.FormCancelAcceptForExecution.Enabled = False;
		Else
			Form.Items.FormCancelAcceptForExecution.Enabled = True;
		EndIf;
		
	Else	
		Form.Items.FormAcceptForExecution.Enabled = True;
		Form.Items.FormCancelAcceptForExecution.Enabled = False;
	EndIf;
		
EndProcedure

// Opens the form to set up deferred start of a business process.
//
// Parameters:
//  BusinessProcess - - BusinessProcessRef - a process, for which a deferred start setting form is 
//                                            to be opened.
//  DueDate - Date                   - a date stating the deadline.
//
Procedure SetUpDeferredStart(BusinessProcess, DueDate) Export
	
	If BusinessProcess.IsEmpty() Then
		WarningText = 
			NStr("ru = 'Невозможно настроить отложенный старт для незаписанного процесса.'; en = 'Cannot set up deferred start for an unsaved process.'; pl = 'Cannot set up deferred start for an unsaved process.';de = 'Cannot set up deferred start for an unsaved process.';ro = 'Cannot set up deferred start for an unsaved process.';tr = 'Cannot set up deferred start for an unsaved process.'; es_ES = 'Cannot set up deferred start for an unsaved process.'");
		ShowMessageBox(, WarningText);
		Return;
	EndIf;
		
	FormParameters = New Structure;
	FormParameters.Insert("BusinessProcess", BusinessProcess);
	FormParameters.Insert("DueDate", DueDate);
	
	OpenForm(
		"InformationRegister.ProcessesToStart.Form.DeferredProcessStartSetup",
		FormParameters,,,,,,
		FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Additional procedures and functions.

// Standard notification handler for task execution forms.
//  The procedure is intended for calling from the NotificationProcessing form event handler.
//
// Parameters:
//  Form - ManagedForm - a task execution form.
//  EventName - String           - an event name.
//  Parameter   - Arbitrary     - an event parameter.
//  Source   - Arbitrary     - an event source.
//
Procedure TaskFormNotificationProcessing(Form, EventName, Parameter, Source) Export
	
	If EventName = "Write_PerformerTask" 
		AND NOT Form.Modified 
		AND (Source = Form.Object.Ref OR (TypeOf(Source) = Type("Array") 
		AND Source.Find(Form.Object.Ref) <> Undefined)) Then
		If Parameter.Property("Forwarded") Then
			Form.Close();
		Else
			Form.Read();
		EndIf;
	EndIf;
	
EndProcedure

// Standard BeforeAddRow handler for task lists.
//  The procedure is intended for calling from the BeforeAddRow form table event handler.
//
// Parameters:
//  Form        - ManagedForm - a task form.
//  Item      - Arbitrary - form table items.
//  Cancel        - Boolean - shows whether adding objects is cancelled. If the parameter is set to 
//                          True in the handler, the object is not added.
//  Copy  - Boolean - defines the copy mode. If True, the row is copied.
//  Parent     - Undefined, CatalogRef, ChartOfAccountsRef - a reference to the item used as a 
//                                                                    parent on adding.
//  Group       - Boolean - shows whether a group is added. True - a group is added.
//
Procedure TaskListBeforeAddRow(Form, Item, Cancel, Clone, Parent, Folder) Export
	
	If Clone Then
		Task = Item.CurrentRow;
		If NOT ValueIsFilled(Task) Then
			Return;
		EndIf;
		FormParameters = New Structure("Base", Task);
	EndIf;
	CreateJob(Form, FormParameters);
	Cancel = True;
	
EndProcedure

// Writes and closes the task execution form.
//
// Parameters:
//  Form  - ManagedForm - a task execution form.
//  ExecuteTask  - Boolean - a task is written in the execution mode.
//  NotificationParameters - Structure - additional notification parameters.
//
// Returns:
//   Boolean   - True if the task is written.
//
Function WriteAndCloseComplete(Form, ExecuteTask = False, NotificationParameters = Undefined) Export
	
	ClearMessages();
	
	NewObject = Form.Object.Ref.IsEmpty();
	NotificationText = "";
	If NotificationParameters = Undefined Then
		NotificationParameters = New Structure;
	EndIf;
	If NOT Form.InitialExecutionFlag AND ExecuteTask Then
		If NOT Form.Write(New Structure("ExecuteTask", True)) Then
			Return False;
		EndIf;
		NotificationText = NStr("ru = 'Задача выполнена'; en = 'The task is completed'; pl = 'The task is completed';de = 'The task is completed';ro = 'The task is completed';tr = 'The task is completed'; es_ES = 'The task is completed'");
	Else
		If NOT Form.Write() Then
			Return False;
		EndIf;
		NotificationText = ?(NewObject, NStr("ru = 'Задача создана'; en = 'The task is created'; pl = 'The task is created';de = 'The task is created';ro = 'The task is created';tr = 'The task is created'; es_ES = 'The task is created'"), NStr("ru = 'Задача изменена'; en = 'The task is changed'; pl = 'The task is changed';de = 'The task is changed';ro = 'The task is changed';tr = 'The task is changed'; es_ES = 'The task is changed'"));
	EndIf;
	
	Notify("Write_PerformerTask", NotificationParameters, Form.Object.Ref);
	ShowUserNotification(NotificationText,
		GetURL(Form.Object.Ref),
		String(Form.Object.Ref),
		PictureLib.Information32);
	Form.Close();
	Return True;
	
EndFunction

// Opens a new job form.
//
// Parameters:
//  FormOwner  - ManagedForm - a form that is to be the owner for the new one.
//  FormParameters - Structure - parameters of the form being opened.
//
Procedure CreateJob(Val OwnerForm = Undefined, Val FormParameters = Undefined) Export
	
	OpenForm("BusinessProcess.Job.ObjectForm", FormParameters, OwnerForm);
	
EndProcedure	

// Opens a form for forwarding one or several tasks to another assignee.
//
// Parameters:
//  TaskArray  - Array - a list of tasks to be forwarded.
//  OwnerForm - ManagedForm - a form to be the owner for the task forwarding form that is being 
//                                     opened.
//
Procedure ForwardTasks(TaskArray, OwnerForm) Export

	If TaskArray = Undefined Then
		ShowMessageBox(,NStr("ru = 'Не выбраны задачи.'; en = 'Tasks are not selected.'; pl = 'Tasks are not selected.';de = 'Tasks are not selected.';ro = 'Tasks are not selected.';tr = 'Tasks are not selected.'; es_ES = 'Tasks are not selected.'"));
		Return;
	EndIf;
		
	TasksCanBeForwarded = BusinessProcessesAndTasksServerCall.ForwardTasks(
		TaskArray, Undefined, True);
	If NOT TasksCanBeForwarded AND TaskArray.Count() = 1 Then
		ShowMessageBox(,NStr("ru = 'Невозможно перенаправить уже выполненную задачу или направленную другому исполнителю.'; en = 'Cannot forward a task that is already completed or was sent to another user.'; pl = 'Cannot forward a task that is already completed or was sent to another user.';de = 'Cannot forward a task that is already completed or was sent to another user.';ro = 'Cannot forward a task that is already completed or was sent to another user.';tr = 'Cannot forward a task that is already completed or was sent to another user.'; es_ES = 'Cannot forward a task that is already completed or was sent to another user.'"));
		Return;
	EndIf;
		
	Notification = New NotifyDescription("ForwardTasksCompletion", ThisObject, TaskArray);
	OpenForm("Task.PerformerTask.Form.ForwardTasks",
		New Structure("Task,TaskCount,FormCaption", 
		TaskArray[0], TaskArray.Count(), 
		?(TaskArray.Count() > 1, NStr("ru = 'Перенаправить задачи'; en = 'Forward tasks'; pl = 'Forward tasks';de = 'Forward tasks';ro = 'Forward tasks';tr = 'Forward tasks'; es_ES = 'Forward tasks'"), 
			NStr("ru = 'Перенаправить задачу'; en = 'Forward task'; pl = 'Forward task';de = 'Forward task';ro = 'Forward task';tr = 'Forward task'; es_ES = 'Forward task'"))), 
		OwnerForm,,,,Notification);
		
EndProcedure

// Opens the form with additional information about the task.
//
// Parameters:
//  TaskRef - TaskRef - a reference to a task.
// 
// Returns:
//  ManagedForm - a form of the assignee's additional task.
//
Procedure OpenAdditionalTaskInfo(Val TaskRef) Export
	
	OpenForm("Task.PerformerTask.Form.More", 
		New Structure("Key", TaskRef));
	
EndProcedure

#EndRegion

#Region Private

Procedure OpenBusinessProcess(List) Export
	If TypeOf(List.CurrentRow) <> Type("TaskRef.PerformerTask") Then
		ShowMessageBox(,NStr("ru = 'Команда не может быть выполнена для указанного объекта.'; en = 'Cannot run the command for the specified object.'; pl = 'Cannot run the command for the specified object.';de = 'Cannot run the command for the specified object.';ro = 'Cannot run the command for the specified object.';tr = 'Cannot run the command for the specified object.'; es_ES = 'Cannot run the command for the specified object.'"));
		Return;
	EndIf;
	If List.CurrentData.BusinessProcess = Undefined Then
		ShowMessageBox(,NStr("ru = 'У выбранной задачи не указан бизнес-процесс.'; en = 'Business process of the selected task is not specified.'; pl = 'Business process of the selected task is not specified.';de = 'Business process of the selected task is not specified.';ro = 'Business process of the selected task is not specified.';tr = 'Business process of the selected task is not specified.'; es_ES = 'Business process of the selected task is not specified.'"));
		Return;
	EndIf;
	ShowValue(, List.CurrentData.BusinessProcess);
EndProcedure

Procedure OpenTaskSubject(List) Export
	If TypeOf(List.CurrentRow) <> Type("TaskRef.PerformerTask") Then
		ShowMessageBox(,NStr("ru = 'Команда не может быть выполнена для указанного объекта.'; en = 'Cannot run the command for the specified object.'; pl = 'Cannot run the command for the specified object.';de = 'Cannot run the command for the specified object.';ro = 'Cannot run the command for the specified object.';tr = 'Cannot run the command for the specified object.'; es_ES = 'Cannot run the command for the specified object.'"));
		Return;
	EndIf;
	If List.CurrentData.Topic = Undefined Then
		ShowMessageBox(,NStr("ru = 'У выбранной задачи не указан предмет.'; en = 'Subject of the selected task is not specified.'; pl = 'Subject of the selected task is not specified.';de = 'Subject of the selected task is not specified.';ro = 'Subject of the selected task is not specified.';tr = 'Subject of the selected task is not specified.'; es_ES = 'Subject of the selected task is not specified.'"));
		Return;
	EndIf;
	ShowValue(, List.CurrentData.Topic);
EndProcedure

// Standard handler DeletionMark used in the lists of business processes.
// The procedure is intended for calling from the DeletionMark list event handler.
//
// Parameters:
//   List  - FormTable - a form control (form table) with a list of business processes.
//
Procedure BusinessProcessesListDeletionMark(List) Export
	
	SelectedRows = List.SelectedRows;
	If SelectedRows = Undefined OR SelectedRows.Count() <= 0 Then
		ShowMessageBox(,NStr("ru = 'Команда не может быть выполнена для указанного объекта.'; en = 'Cannot run the command for the specified object.'; pl = 'Cannot run the command for the specified object.';de = 'Cannot run the command for the specified object.';ro = 'Cannot run the command for the specified object.';tr = 'Cannot run the command for the specified object.'; es_ES = 'Cannot run the command for the specified object.'"));
		Return;
	EndIf;
	Notification = New NotifyDescription("BusinessProcessesListDeletionMarkCompletion", ThisObject, List);
	ShowQueryBox(Notification, NStr("ru = 'Изменить пометку удаления?'; en = 'Change deletion mark?'; pl = 'Change deletion mark?';de = 'Change deletion mark?';ro = 'Change deletion mark?';tr = 'Change deletion mark?'; es_ES = 'Change deletion mark?'"), QuestionDialogMode.YesNo);
	
EndProcedure

// Opens the assignee selection form.
//
// Parameters:
//   PerformerItem - a form item where an assignee is selected. The form item is specified as the 
//      owner of the assignee selection form.
//   PerformerAttribute - a previously selected assignee.
//      Used to set the current row in the assignee selection form.
//   SimpleRolesOnly - Boolean - if True, only roles without addressing objects are used in the 
//      selection.
//   WithoutExternalRoles	- Boolean - if True, only roles without the ExternalRole flag are used in 
//      the selection.
//
Procedure SelectPerformer(PerformerItem, PerformerAttribute, SimpleRolesOnly = False, NoExternalRoles = False) Export 
	
	StandardProcessing = True;
	BusinessProcessesAndTasksClientOverridable.OnPerformerChoice(PerformerItem, PerformerAttribute, 
		SimpleRolesOnly, NoExternalRoles, StandardProcessing);
	If Not StandardProcessing Then
		Return;
	EndIf;
			
	FormParameters = New Structure("Performer, SimpleRolesOnly, NoExternalRoles", 
		PerformerAttribute, SimpleRolesOnly, NoExternalRoles);
	OpenForm("CommonForm.SelectBusinessProcessPerformer", FormParameters, PerformerItem);
	
EndProcedure	

Procedure StopCompletion(Val Result, Val CommandParameter) Export
	
	If Result <> DialogReturnCode.Yes Then
		Return;
	EndIf;
	
	If TypeOf(CommandParameter) = Type("Array") Then
		
		BusinessProcessesAndTasksServerCall.StopBusinessProcesses(CommandParameter);
		
	Else
		
		BusinessProcessesAndTasksServerCall.StopBusinessProcess(CommandParameter);
		
	EndIf;
	
	If TypeOf(CommandParameter) = Type("Array") Then
		
		If CommandParameter.Count() <> 0 Then
			
			For Each Parameter In CommandParameter Do
				
				If TypeOf(Parameter) <> Type("DynamicalListGroupRow") Then
					NotifyChanged(TypeOf(Parameter));
					Break;
				EndIf;
				
			EndDo;
			
		EndIf;
		
	Else
		NotifyChanged(CommandParameter);
	EndIf;

EndProcedure

Procedure BusinessProcessesListDeletionMarkCompletion(Result, List) Export
	
	If Result <> DialogReturnCode.Yes Then
		Return;
	EndIf;
	
	SelectedRows = List.SelectedRows;
	BusinessProcessRef = BusinessProcessesAndTasksServerCall.MarkBusinessProcessesForDeletion(SelectedRows);
	List.Refresh();
	ShowUserNotification(NStr("ru = 'Пометка удаления изменена.'; en = 'The deletion mark is changed.'; pl = 'The deletion mark is changed.';de = 'The deletion mark is changed.';ro = 'The deletion mark is changed.';tr = 'The deletion mark is changed.'; es_ES = 'The deletion mark is changed.'"), 
		?(BusinessProcessRef <> Undefined, GetURL(BusinessProcessRef), ""),
		?(BusinessProcessRef <> Undefined, String(BusinessProcessRef), ""));
	
EndProcedure

Procedure ActivateCompletion(Val Result, Val CommandParameter) Export
	
	If Result <> DialogReturnCode.Yes Then
		Return;
	EndIf;
		
	If TypeOf(CommandParameter) = Type("Array") Then
		
		BusinessProcessesAndTasksServerCall.ActivateBusinessProcesses(CommandParameter);
		
	Else
		
		BusinessProcessesAndTasksServerCall.ActivateBusinessProcess(CommandParameter);
		
	EndIf;
	
	If TypeOf(CommandParameter) = Type("Array") Then
		
		If CommandParameter.Count() <> 0 Then
			
			For Each Parameter In CommandParameter Do
				
				If TypeOf(Parameter) <> Type("DynamicalListGroupRow") Then
					NotifyChanged(TypeOf(Parameter));
					Break;
				EndIf;
				
			EndDo;
			
		EndIf;
		
	Else
		NotifyChanged(CommandParameter);
	EndIf;
	
EndProcedure

Procedure ForwardTasksCompletion(Val Result, Val TaskArray) Export
	
	If TypeOf(Result) <> Type("Structure") Then
		Return;
	EndIf;
	
	ForwardedTaskArray = Undefined;
	TasksAreForwarded = BusinessProcessesAndTasksServerCall.ForwardTasks(
		TaskArray, Result, False, ForwardedTaskArray);
		
	Notify("Write_PerformerTask", New Structure("Forwarded", TasksAreForwarded), TaskArray);
	
EndProcedure

#EndRegion
