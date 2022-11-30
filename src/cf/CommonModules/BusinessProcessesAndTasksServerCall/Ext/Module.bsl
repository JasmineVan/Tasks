///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Public

// Gets a structure with description of a task execution form.
//
// Parameters:
//  TaskRef  - TaskRef.PerformerTask - a task.
//
// Returns:
//   Structure   - a structure with description of the task execution form.
//
Function TaskExecutionForm(Val TaskRef) Export
	
	If TypeOf(TaskRef) <> Type("TaskRef.PerformerTask") Then
		
		MessageText = StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = 'Неправильный тип параметра ЗадачаСсылка (передан: %1; ожидается: %2)'; en = 'Invalid TaskRef parameter type (passed: %1, expected: %2)'; pl = 'Invalid TaskRef parameter type (passed: %1, expected: %2)';de = 'Invalid TaskRef parameter type (passed: %1, expected: %2)';ro = 'Invalid TaskRef parameter type (passed: %1, expected: %2)';tr = 'Invalid TaskRef parameter type (passed: %1, expected: %2)'; es_ES = 'Invalid TaskRef parameter type (passed: %1, expected: %2)'"),
			TypeOf(TaskRef), "TaskRef.PerformerTask");
		Raise MessageText;
		
	EndIf;
	
	Attributes = Common.ObjectAttributesValues(TaskRef, "BusinessProcess,RoutePoint");
	If Attributes.BusinessProcess = Undefined OR Attributes.BusinessProcess.IsEmpty() Then
		Return New Structure();
	EndIf;
	
	BusinessProcessType = Attributes.BusinessProcess.Metadata();
	FormParameters = BusinessProcesses[BusinessProcessType.Name].TaskExecutionForm(TaskRef,
		Attributes.RoutePoint);
	BusinessProcessesAndTasksOverridable.OnReceiveTaskExecutionForm(
		BusinessProcessType.Name, TaskRef, Attributes.RoutePoint, FormParameters);
	
	Return FormParameters;
	
EndFunction

// Checks whether report cell contains a reference to the task.
//  Returns the details value in the DetailsValue parameter.
//
// Parameters:
//  Details             - String - a cell name.
//  ReportDetailsData - String - address in the temporary storage.
//  DetailsValue     - TaskRef.PerformerTask, Arbitrary - details value from the cell.
// 
// Returns:
//  Boolean - if True, then it is an assignee's task.
//
Function IsPerformerTask(Val Details, Val ReportDetailsData, DetailsValue) Export
	
	ObjectDetailsData = GetFromTempStorage(ReportDetailsData);
	DetailsValue = ObjectDetailsData.Items[Details].GetFields()[0].Value;
	Return TypeOf(DetailsValue) = Type("TaskRef.PerformerTask");
	
EndFunction

// Completes the TaskRef task. If necessary, executes  
//  DefaultCompletionHandler in the manager module of the business process where the TaskRef task 
//  belongs.
//
// Parameters:
//  TaskRef - TaskRef  - a reference to a task.
//  DefaultAction - Boolean - shows whether it is required to call procedure
//                                       DefaultCompletionHandler for the task business process.
//
Procedure ExecuteTask(TaskRef, DefaultAction = False) Export

	BeginTransaction();
	Try
		BusinessProcessesAndTasksServer.LockTasks(TaskRef);
		
		TaskObject = TaskRef.GetObject();
		If TaskObject.Executed Then
			Raise NStr("ru = 'Задача уже была выполнена ранее.'; en = 'The task was completed earlier.'; pl = 'The task was completed earlier.';de = 'The task was completed earlier.';ro = 'The task was completed earlier.';tr = 'The task was completed earlier.'; es_ES = 'The task was completed earlier.'");
		EndIf;
		
		If DefaultAction AND TaskObject.BusinessProcess <> Undefined 
			AND NOT TaskObject.BusinessProcess.IsEmpty() Then
			BusinessProcessType = TaskObject.BusinessProcess.Metadata();
			BusinessProcesses[BusinessProcessType.Name].DefaultCompletionHandler(TaskRef,
				TaskObject.BusinessProcess, TaskObject.RoutePoint);
		EndIf;
			
		TaskObject.Executed = False;
		TaskObject.ExecuteTask();
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;

EndProcedure

// Forwards tasks TaskArray to a new assignee specified in structure.
// ForwardingInfo.
//
// Parameters:
//  TaskArray - Array - an array of tasks to be forwarded.
//  ForwardingInfo - Structure - contains new values of task addressing attributes.
//  CheckOnly - Boolean - if True, the function does not actually forward tasks, it only checks 
//                                     whether they can be forwarded.
//                                     
//  ForwardedTaskArray - Array - an array of forwarded tasks.
//                                         The array elements might not exactly match the TaskArray 
//                                         elements if some tasks cannot forwarded.
//                                         
//
// Returns:
//   Boolean - True if the tasks are forwarded successfully.
//
Function ForwardTasks(Val TaskArray, Val ForwardingInfo, Val CheckOnly = False,
	ForwardedTaskArray = Undefined) Export
	
	Result = True;
	
	TasksInfo = Common.ObjectsAttributesValues(TaskArray, "BusinessProcess,Executed");
	BeginTransaction();
	Try
		For Each Task In TasksInfo Do
			
			If Task.Value.Executed Then
				Result = False;
				If CheckOnly Then
					RollbackTransaction();
					Return Result;
				EndIf;
			EndIf;	
			
			BusinessProcessesAndTasksServer.LockTasks(Task.Key);
			If ValueIsFilled(Task.Value.BusinessProcess) AND Not Task.Value.BusinessProcess.IsEmpty() Then
				BusinessProcessesAndTasksServer.LockBusinessProcesses(Task.Value.BusinessProcess);
			EndIf;
		EndDo;
						
		If CheckOnly Then
			For Each Task In TasksInfo Do
				TaskObject = Task.Key.GetObject();
				TaskObject.Executed = False;
				TaskObject.AdditionalProperties.Insert("Redirection", True);
				TaskObject.ExecuteTask();
			EndDo;	
			RollbackTransaction();
			Return Result;
		EndIf;	
		
		For Each Task In TasksInfo Do
			
			If NOT ValueIsFilled(ForwardedTaskArray) Then
				ForwardedTaskArray = New Array();
			EndIf;
			
			// The object lock is not set for Task. This ensures that the task can be forwarded using the task 
			// form command.
			TaskObject = Task.Key.GetObject();
			
			SetPrivilegedMode(True);
			NewTask = Tasks.PerformerTask.CreateTask();
			NewTask.Fill(TaskObject);
			FillPropertyValues(NewTask, ForwardingInfo, 
				"Performer,PerformerRole,MainAddressingObject,AdditionalAddressingObject");
			NewTask.Write();
			SetPrivilegedMode(False);
		
			ForwardedTaskArray.Add(NewTask.Ref);
			
			TaskObject.ExecutionResult = ForwardingInfo.Comment; 
			TaskObject.Executed = False;
			TaskObject.AdditionalProperties.Insert("Redirection", True);
			TaskObject.ExecuteTask();
			
			SetPrivilegedMode(True);
			SubordinateBusinessProcesses = BusinessProcessesAndTasksServer.SelectHeadTaskBusinessProcesses(Task.Key, True).Select();
			SetPrivilegedMode(False);
			While SubordinateBusinessProcesses.Next() Do
				BusinessProcessObject = SubordinateBusinessProcesses.Ref.GetObject();
				BusinessProcessObject.HeadTask = NewTask.Ref;
				BusinessProcessObject.Write();
			EndDo;
			
			SubordinateBusinessProcesses = BusinessProcessesAndTasksServer.MainTaskBusinessProcesses(Task.Key, True);
			For each SubordinateBusinessProcess In SubordinateBusinessProcesses Do
				BusinessProcessObject = SubordinateBusinessProcess.GetObject();
				BusinessProcessObject.MainTask = NewTask.Ref;
				BusinessProcessObject.Write();
			EndDo;
			
			OnForwardTask(TaskObject, NewTask);
				
		EndDo;
			
		CommitTransaction();
	Except
		RollbackTransaction();
		Result = False;
		If Not CheckOnly Then
			Raise;
		EndIf;
	EndTry;
	
	Return Result;
	
EndFunction

// Marks the specified business processes as active.
//
// Parameters:
//  BusinessProcesses - Array - an array of references to business processes.
//
Procedure ActivateBusinessProcesses(BusinessProcesses) Export
	
	BeginTransaction();
	Try
		BusinessProcessesAndTasksServer.LockBusinessProcesses(BusinessProcesses);
		
		For each BusinessProcess In BusinessProcesses Do
			ActivateBusinessProcess(BusinessProcess);
		EndDo;
		
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;
	
EndProcedure

// Marks the specified business processes as active.
//
// Parameters:
//  BusinessProcess - BusinessProcessRef - a reference to a business process.
//
Procedure ActivateBusinessProcess(BusinessProcess) Export
	
	If TypeOf(BusinessProcess) = Type("DynamicalListGroupRow") Then
		Return;
	EndIf;
	
	BeginTransaction();
	Try
		BusinessProcessesAndTasksServer.LockBusinessProcesses(BusinessProcess);
		
		Object = BusinessProcess.GetObject();
		If Object.State = Enums.BusinessProcessStates.Active Then
			
			If Object.Completed Then
				Raise NStr("ru = 'Невозможно сделать активными завершенные бизнес-процессы.'; en = 'Cannot activate the completed business processes.'; pl = 'Cannot activate the completed business processes.';de = 'Cannot activate the completed business processes.';ro = 'Cannot activate the completed business processes.';tr = 'Cannot activate the completed business processes.'; es_ES = 'Cannot activate the completed business processes.'");
			EndIf;
			
			If Not Object.Started Then
				Raise NStr("ru = 'Невозможно сделать активными не стартовавшие бизнес-процессы.'; en = 'Cannot activate the business processes that are not started yet.'; pl = 'Cannot activate the business processes that are not started yet.';de = 'Cannot activate the business processes that are not started yet.';ro = 'Cannot activate the business processes that are not started yet.';tr = 'Cannot activate the business processes that are not started yet.'; es_ES = 'Cannot activate the business processes that are not started yet.'");
			EndIf;
			
			Raise NStr("ru = 'Бизнес-процесс уже активен.'; en = 'The business process is already active.'; pl = 'The business process is already active.';de = 'The business process is already active.';ro = 'The business process is already active.';tr = 'The business process is already active.'; es_ES = 'The business process is already active.'");
		EndIf;
			
		Object.Lock();
		Object.State = Enums.BusinessProcessStates.Active;
		Object.Write();
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;
	
EndProcedure

// Marks the specified business processes as stopped.
//
// Parameters:
//  BusinessProcesses - Array - an array of references to business processes.
//
Procedure StopBusinessProcesses(BusinessProcesses) Export
	
	BeginTransaction();
	Try 
		BusinessProcessesAndTasksServer.LockBusinessProcesses(BusinessProcesses);
		
		For each BusinessProcess In BusinessProcesses Do
			StopBusinessProcess(BusinessProcess);
		EndDo;
		CommitTransaction();
	Except
		RollbackTransaction();
		WriteLogEvent(BusinessProcessesAndTasksServer.EventLogEvent(), EventLogLevel.Error,,, 
			DetailErrorDescription(ErrorInfo()));
		Raise;
	EndTry;
	
EndProcedure

// Marks the specified business process as stopped.
//
// Parameters:
//  BusinessProcess - BusinessProcessRef - a reference to a business process.
//
Procedure StopBusinessProcess(BusinessProcess) Export
	
	If TypeOf(BusinessProcess) = Type("DynamicalListGroupRow") Then
		Return;
	EndIf;
	
	BeginTransaction();
	Try
		BusinessProcessesAndTasksServer.LockBusinessProcesses(BusinessProcess);
		
		Object = BusinessProcess.GetObject();
		If Object.State = Enums.BusinessProcessStates.Stopped Then
			
			If Object.Completed Then
				Raise NStr("ru = 'Невозможно остановить завершенные бизнес-процессы.'; en = 'Cannot stop the completed business processes.'; pl = 'Cannot stop the completed business processes.';de = 'Cannot stop the completed business processes.';ro = 'Cannot stop the completed business processes.';tr = 'Cannot stop the completed business processes.'; es_ES = 'Cannot stop the completed business processes.'");
			EndIf;
				
			If Not Object.Started Then
				Raise NStr("ru = 'Невозможно остановить не стартовавшие бизнес-процессы.'; en = 'Cannot stop the business processes that are not started yet.'; pl = 'Cannot stop the business processes that are not started yet.';de = 'Cannot stop the business processes that are not started yet.';ro = 'Cannot stop the business processes that are not started yet.';tr = 'Cannot stop the business processes that are not started yet.'; es_ES = 'Cannot stop the business processes that are not started yet.'");
			EndIf;
			
			Raise NStr("ru = 'Бизнес-процесс уже остановлен.'; en = 'The business process is already stopped.'; pl = 'The business process is already stopped.';de = 'The business process is already stopped.';ro = 'The business process is already stopped.';tr = 'The business process is already stopped.'; es_ES = 'The business process is already stopped.'");
		EndIf;
		
		Object.Lock();
		Object.State = Enums.BusinessProcessStates.Stopped;
		Object.Write();
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;
	
EndProcedure

// Marks the specified task as accepted for execution.
//
// Parameters:
//   Tasks - Array - an array of references to tasks.
//
Procedure AcceptTasksForExecution(Tasks) Export
	
	NewTaskArray = New Array();
	
	BeginTransaction();
	Try
		BusinessProcessesAndTasksServer.LockTasks(Tasks);
		
		For each Task In Tasks Do
			
			If TypeOf(Task) = Type("DynamicalListGroupRow") Then
				Continue;
			EndIf;
			
			TaskObject = Task.GetObject();
			If TaskObject.Executed Then
				Continue;
			EndIf;
			
			TaskObject.Lock();
			TaskObject.AcceptedForExecution = True;
			TaskObject.AcceptForExecutionDate = CurrentSessionDate();
			If NOT ValueIsFilled(TaskObject.Performer) Then
				TaskObject.Performer = Users.AuthorizedUser();
			EndIf;
			TaskObject.Write();
			
			NewTaskArray.Add(Task);
			
		EndDo;
	CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;
	
	Tasks = NewTaskArray;
	
EndProcedure

// Marks the specified tasks as not accepted for execution.
//
// Parameters:
//   Tasks - Array - an array of references to tasks.
//
Procedure CancelAcceptTasksForExecution(Tasks) Export
	
	NewTaskArray = New Array();
	
	BeginTransaction();
	Try
		BusinessProcessesAndTasksServer.LockTasks(Tasks);
			
		For each Task In Tasks Do
			
			If TypeOf(Task) = Type("DynamicalListGroupRow") Then 
				Continue;
			EndIf;	
			
			TaskObject = Task.GetObject();
			If TaskObject.Executed Then
				Continue;
			EndIf;
			
			TaskObject.Lock();
			TaskObject.AcceptedForExecution = False;
			TaskObject.AcceptForExecutionDate = "00010101000000";
			If Not TaskObject.PerformerRole.IsEmpty() Then
				TaskObject.Performer = Catalogs.Users.EmptyRef();
			EndIf;
			TaskObject.Write();
			
			NewTaskArray.Add(Task);
			
		EndDo;
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;
	
	Tasks = NewTaskArray;
	
EndProcedure

// Checks whether the specified task is the head one.
//
// Parameters:
//  TaskRef  - TaskRef.PerformerTask - a task.
//
// Returns:
//   Boolean - If True, then the task is the head one.
//
Function IsHeadTask(TaskRef) Export
	
	SetPrivilegedMode(True);
	Result = BusinessProcessesAndTasksServer.SelectHeadTaskBusinessProcesses(TaskRef);
	Return NOT Result.IsEmpty();
	
EndFunction

// Generates a list for selecting an assignee in composite fields (User and Role.)
//  
//
// Parameters:
//  Text - String - a text fragment to search for possible assignees.
// 
// Returns:
//  ValueList - a selection list containing possible assignees.
//
Function GeneratePerformerChoiceData(Text) Export
	
	ChoiceData = New ValueList;
	
	Query = New Query;
	Query.Text = 
	"SELECT ALLOWED
	|	Users.Ref AS Ref
	|FROM
	|	Catalog.Users AS Users
	|WHERE
	|	Users.Description LIKE &Text
	|	AND Users.Invalid = FALSE
	|	AND Users.Internal = FALSE
	|	AND Users.DeletionMark = FALSE
	|
	|UNION ALL
	|
	|SELECT
	|	PerformerRoles.Ref
	|FROM
	|	Catalog.PerformerRoles AS PerformerRoles
	|WHERE
	|	PerformerRoles.Description LIKE &Text
	|	AND NOT PerformerRoles.DeletionMark";
	Query.SetParameter("Text", Text + "%");
	
	Selection = Query.Execute().Select();
	While Selection.Next() Do
		ChoiceData.Add(Selection.Ref);
	EndDo;
	
	Return ChoiceData;
	
EndFunction

#Region ObsoleteProceduresAndFunctions

// Obsolete. Use BusinessProcessesAndTasksServer.NotifyPerformersOnNewTasks.
//
Procedure NotifyPerformersOnNewTasks() Export
	
	BusinessProcessesAndTasksServer.NotifyPerformersOnNewTasks();
	
EndProcedure

// Obsolete. Use BusinessProcessesAndTasksServer.CheckTasks.
//
Procedure CheckTasks() Export
	
	BusinessProcessesAndTasksServer.CheckTasks();
	
EndProcedure

#EndRegion

#EndRegion


#Region Private

////////////////////////////////////////////////////////////////////////////////
// Other internal procedures and functions.

// Returns the number of uncompleted tasks for the specified business processes.
//
Function UncompletedBusinessProcessesTasksCount(BusinessProcesses) Export
	
	TaskCount = 0;
	
	For each BusinessProcess In BusinessProcesses Do
		
		If TypeOf(BusinessProcess) = Type("DynamicalListGroupRow") Then
			Continue;
		EndIf;
		
		TaskCount = TaskCount + UncompletedBusinessProcessTasksCount(BusinessProcess);
		
	EndDo;
		
	Return TaskCount;
	
EndFunction

// Returns the number of uncompleted tasks for the specified business process.
//
Function UncompletedBusinessProcessTasksCount(BusinessProcess) Export
	
	If TypeOf(BusinessProcess) = Type("DynamicalListGroupRow") Then
		Return 0;
	EndIf;
	
	Query = New Query;
	Query.Text = "SELECT
	               |	COUNT(*) AS Count
	               |FROM
	               |	Task.PerformerTask AS Tasks
	               |WHERE
	               |	Tasks.BusinessProcess = &BusinessProcess
	               |	AND Tasks.Executed = FALSE";
				   
	Query.SetParameter("BusinessProcess", BusinessProcess);
	
	Selection = Query.Execute().Select();
	Selection.Next();
	
	Return Selection.Count;
	
EndFunction

// Marks the specified business processes for deletion.
//
Function MarkBusinessProcessesForDeletion(SelectedRows) Export
	Count = 0;
	For Each TableRow In SelectedRows Do
		BusinessProcessRef = TableRow.BusinessProcess;
		If BusinessProcessRef = Undefined OR BusinessProcessRef.IsEmpty() Then
			Continue;
		EndIf;	
		BeginTransaction();
		Try
			BusinessProcessesAndTasksServer.LockBusinessProcesses(BusinessProcessRef);
			BusinessProcessObject = BusinessProcessRef.GetObject();
			BusinessProcessObject.SetDeletionMark(NOT BusinessProcessObject.DeletionMark);
			CommitTransaction();
		Except
			RollbackTransaction();
			Raise;
		EndTry;
		
		Count = Count + 1;
	EndDo;
	Return ?(Count = 1, SelectedRows[0].BusinessProcess, Undefined);
EndFunction

Procedure OnForwardTask(TaskObject, NewTaskObject) 
	
	If TaskObject.BusinessProcess.IsEmpty() Then
		Return;
	EndIf;
	
	AttachedBusinessProcesses = New Map;
	AttachedBusinessProcesses.Insert(Metadata.BusinessProcesses.Job.FullName(), "");
	BusinessProcessesAndTasksOverridable.OnDetermineBusinessProcesses(AttachedBusinessProcesses);
	
	BusinessProcessType = TaskObject.BusinessProcess.Metadata();
	BusinessProcessInfo = AttachedBusinessProcesses[BusinessProcessType.FullName()];
	If BusinessProcessInfo <> Undefined Then 
		BusinessProcesses[BusinessProcessType.Name].OnForwardTask(TaskObject.Ref, NewTaskObject.Ref);
	EndIf;
	
EndProcedure

#EndRegion
