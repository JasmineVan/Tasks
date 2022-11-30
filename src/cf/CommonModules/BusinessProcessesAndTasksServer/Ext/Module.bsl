///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Public

// Initializes common parameters of the task execution form.
//
// Parameters:
//  BusinessProcessTaskForm            - ManagedForm - a task execution form.
//  TaskObject           - TaskObject     - a task object.
//  StateGroupItem - FormGroup      -a group with information on the task state.
//  CompletionDateItem  - FormField        - a field with the task completion date.
//
Procedure TaskFormOnCreateAtServer(BusinessProcessTaskForm, TaskObject, 
	StateGroupItem, CompletionDateItem) Export
	
	BusinessProcessTaskForm.ReadOnly = TaskObject.Executed;

	If TaskObject.Executed Then
		If StateGroupItem <> Undefined Then
			StateGroupItem.Visible = True;
		EndIf;
		Parent = ?(StateGroupItem <> Undefined, StateGroupItem, BusinessProcessTaskForm);
		Item = BusinessProcessTaskForm.Items.Find("__TaskStatePicture");
		If Item = Undefined Then
			Item = BusinessProcessTaskForm.Items.Add("__TaskStatePicture", Type("FormDecoration"), Parent);
			Item.Type = FormDecorationType.Picture;
			Item.Picture = PictureLib.Information;
		EndIf;
		
		Item = BusinessProcessTaskForm.Items.Find("__TaskState");
		If Item = Undefined Then
			Item = BusinessProcessTaskForm.Items.Add("__TaskState", Type("FormDecoration"), Parent);
			Item.Type = FormDecorationType.Label;
			Item.Height = 0; // Auto height
			Item.AutoMaxWidth = False;
		EndIf;
		UseDateAndTimeInTaskDeadlines = GetFunctionalOption("UseDateAndTimeInTaskDeadlines");
		CompletionDateAsString = ?(UseDateAndTimeInTaskDeadlines, 
			Format(TaskObject.CompletionDate, "DLF=DT"), Format(TaskObject.CompletionDate, "DLF=D"));
		Item.Title = StringFunctionsClientServer.SubstituteParametersToString(NStr("ru ='Задача выполнена %1 пользователем %2.'; en = 'The task is completed on %1 by user %2.'; pl = 'The task is completed on %1 by user %2.';de = 'The task is completed on %1 by user %2.';ro = 'The task is completed on %1 by user %2.';tr = 'The task is completed on %1 by user %2.'; es_ES = 'The task is completed on %1 by user %2.'"),
			CompletionDateAsString, 
			PerformerString(TaskObject.Performer, TaskObject.PerformerRole,
			TaskObject.MainAddressingObject, TaskObject.AdditionalAddressingObject));
	EndIf;
	
	If BusinessProcessesAndTasksServerCall.IsHeadTask(TaskObject.Ref) Then
		If StateGroupItem <> Undefined Then
			StateGroupItem.Visible = True;
		EndIf;
		Parent = ?(StateGroupItem <> Undefined, StateGroupItem, BusinessProcessTaskForm);
		Item = BusinessProcessTaskForm.Items.Find("__HeadTaskPicture");
		If Item = Undefined Then
			Item = BusinessProcessTaskForm.Items.Add("__HeadTaskPicture", Type("FormDecoration"), Parent);
			Item.Type = FormDecorationType.Picture;
			Item.Picture = PictureLib.Information;
		EndIf;
		
		Item = BusinessProcessTaskForm.Items.Find("__HeadTask");
		If Item = Undefined Then
			Item = BusinessProcessTaskForm.Items.Add("__HeadTask", Type("FormDecoration"), Parent);
			Item.Type = FormDecorationType.Label;
			Item.Title = NStr("ru ='Это ведущая задача для вложенных бизнес-процессов. Она будет выполнена автоматически при их завершении.'; en = 'This is a leading task for nested business processes. It will be completed automatically upon their completion.'; pl = 'This is a leading task for nested business processes. It will be completed automatically upon their completion.';de = 'This is a leading task for nested business processes. It will be completed automatically upon their completion.';ro = 'This is a leading task for nested business processes. It will be completed automatically upon their completion.';tr = 'This is a leading task for nested business processes. It will be completed automatically upon their completion.'; es_ES = 'This is a leading task for nested business processes. It will be completed automatically upon their completion.'");
			Item.Height = 0; // Auto height
			Item.AutoMaxWidth = False;
		EndIf;
	EndIf;
	
EndProcedure

// The procedure is called when creating a task list form on the server.
//
// Parameters:
//  TaskListOrItsConditionalAppearance - DynamicList, DataCompositionConditionalAppearance - 
//   conditional appearance of a task list.
//
Procedure SetTaskAppearance(Val TaskListOrItsConditionalAppearance) Export
	
	If TypeOf(TaskListOrItsConditionalAppearance) = Type("DynamicList") Then
		ConditionalTaskListAppearance = TaskListOrItsConditionalAppearance.SettingsComposer.Settings.ConditionalAppearance;
		ConditionalTaskListAppearance.UserSettingID = "MainAppearance";
	Else
		ConditionalTaskListAppearance = TaskListOrItsConditionalAppearance;
	EndIf;
	
	// Deleting preset appearance items.
	PresetAppearanceItems = New Array;
	Items = ConditionalTaskListAppearance.Items;
	For each ConditionalAppearanceItem In Items Do
		If ConditionalAppearanceItem.ViewMode = DataCompositionSettingsItemViewMode.Inaccessible Then
			PresetAppearanceItems.Add(ConditionalAppearanceItem);
		EndIf;
	EndDo;
	For each ConditionalAppearanceItem In PresetAppearanceItems Do
		Items.Delete(ConditionalAppearanceItem);
	EndDo;
		
	// Setting appearance for overdue tasks.
	ConditionalAppearanceItem = ConditionalTaskListAppearance.Items.Add();
	ConditionalAppearanceItem.ViewMode = DataCompositionSettingsItemViewMode.Inaccessible;
	
	DataFilterItem = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	DataFilterItem.LeftValue = New DataCompositionField("DueDate");
	DataFilterItem.ComparisonType = DataCompositionComparisonType.Filled;
	DataFilterItem.Use = True;
	
	DataFilterItem = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	DataFilterItem.LeftValue = New DataCompositionField("DueDate");
	DataFilterItem.ComparisonType = DataCompositionComparisonType.Less;
	DataFilterItem.RightValue = CurrentSessionDate();
	DataFilterItem.Use = True;
	
	DataFilterItem = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	DataFilterItem.LeftValue = New DataCompositionField("Executed");
	DataFilterItem.ComparisonType = DataCompositionComparisonType.Equal;
	DataFilterItem.RightValue = False;
	DataFilterItem.Use = True;
	
	AppearanceColorItem = ConditionalAppearanceItem.Appearance.Items.Find("TextColor");
	AppearanceColorItem.Value =  Metadata.StyleItems.OverdueDataColor.Value;   
	AppearanceColorItem.Use = True;
	
	// Setting appearance for completed tasks.
	ConditionalAppearanceItem = ConditionalTaskListAppearance.Items.Add();
	ConditionalAppearanceItem.ViewMode = DataCompositionSettingsItemViewMode.Inaccessible;
	
	DataFilterItem = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	DataFilterItem.LeftValue = New DataCompositionField("Executed");
	DataFilterItem.ComparisonType = DataCompositionComparisonType.Equal;
	DataFilterItem.RightValue = True;
	DataFilterItem.Use = True;
	
	AppearanceColorItem = ConditionalAppearanceItem.Appearance.Items.Find("TextColor");
	AppearanceColorItem.Value = Metadata.StyleItems.ExecutedTask.Value; 
	AppearanceColorItem.Use = True;
	
	// Setting appearance for tasks that are not accepted for execution.
	ConditionalAppearanceItem = ConditionalTaskListAppearance.Items.Add();
	ConditionalAppearanceItem.ViewMode = DataCompositionSettingsItemViewMode.Inaccessible;
	
	DataFilterItem = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	DataFilterItem.LeftValue = New DataCompositionField("AcceptedForExecution");
	DataFilterItem.ComparisonType = DataCompositionComparisonType.Equal;
	DataFilterItem.RightValue = False;
	DataFilterItem.Use = True;
	
	AppearanceColorItem = ConditionalAppearanceItem.Appearance.Items.Find("Font");
	AppearanceColorItem.Value = Metadata.StyleItems.NotAcceptedForExecutionTasks.Value; 
	AppearanceColorItem.Use = True;
	
	// Setting appearance for tasks with unfilled Deadline.
	ConditionalAppearanceItem = ConditionalTaskListAppearance.Items.Add();
	ConditionalAppearanceItem.ViewMode = DataCompositionSettingsItemViewMode.Inaccessible;
	
	FormattedField = ConditionalAppearanceItem.Fields.Items.Add();
	FormattedField.Field = New DataCompositionField("DueDate");
	FormattedField.Use = True;
	
	DataFilterItem = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	DataFilterItem.LeftValue = New DataCompositionField("DueDate");
	DataFilterItem.ComparisonType = DataCompositionComparisonType.NotFilled;
	DataFilterItem.RightValue = True;
	DataFilterItem.Use = True;
	
	AppearanceColorItem = ConditionalAppearanceItem.Appearance.Items.Find("TextColor");
	AppearanceColorItem.Value = Metadata.StyleItems.InaccessibleCellTextColor.Value;
	AppearanceColorItem.Use = True;
	
	AppearanceColorItem = ConditionalAppearanceItem.Appearance.Items.Find("Text");
	AppearanceColorItem.Value = NStr("ru = 'Срок не указан'; en = 'Due date is not specified'; pl = 'Due date is not specified';de = 'Due date is not specified';ro = 'Due date is not specified';tr = 'Due date is not specified'; es_ES = 'Due date is not specified'");
	AppearanceColorItem.Use = True;
	
	// Setting appearance for external users. The Author field is empty.
	If Users.IsExternalUserSession() Then
			ConditionalAppearanceItem = ConditionalTaskListAppearance.Items.Add();
			ConditionalAppearanceItem.ViewMode = DataCompositionSettingsItemViewMode.Inaccessible;

			FormattedField = ConditionalAppearanceItem.Fields.Items.Add();
			FormattedField.Field = New DataCompositionField("Author");
			FormattedField.Use = True;
			
			DataFilterItem = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
			DataFilterItem.LeftValue = New DataCompositionField("Author");
			DataFilterItem.ComparisonType = DataCompositionComparisonType.NotEqual;
			DataFilterItem.RightValue = Users.AuthorizedUser();
			DataFilterItem.Use = True;

			AppearanceColorItem = ConditionalAppearanceItem.Appearance.Items.Find("Text");
			AppearanceColorItem.Value = NStr("ru = 'Представитель организации'; en = 'Company representative'; pl = 'Company representative';de = 'Company representative';ro = 'Company representative';tr = 'Company representative'; es_ES = 'Company representative'");
			AppearanceColorItem.Use = True;
	EndIf;
	
EndProcedure

// The procedure is called when creating business processes list form on the server.
//
// Parameters:
//  BusinessProcessesConditionalAppearance - ConditionalAppearance - conditional appearance of a business process list.
//
Procedure SetBusinessProcessesAppearance(Val BusinessProcessesConditionalAppearance) Export
	
	// Description is not specified.
	ConditionalAppearanceItem = BusinessProcessesConditionalAppearance.Items.Add();
	ConditionalAppearanceItem.ViewMode = DataCompositionSettingsItemViewMode.Inaccessible;
	
	FormattedField = ConditionalAppearanceItem.Fields.Items.Add();
	FormattedField.Field = New DataCompositionField("Description");
	FormattedField.Use = True;
	
	DataFilterItem = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	DataFilterItem.LeftValue = New DataCompositionField("Description");
	DataFilterItem.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	ConditionalAppearanceItem.Appearance.SetParameterValue("TextColor", StyleColors.InaccessibleCellTextColor);
	ConditionalAppearanceItem.Appearance.SetParameterValue("Text", NStr("ru = 'Без описания'; en = 'No description'; pl = 'No description';de = 'No description';ro = 'No description';tr = 'No description'; es_ES = 'No description'"));
	
	// Completed business process.
	ConditionalAppearanceItem = BusinessProcessesConditionalAppearance.Items.Add();
	ConditionalAppearanceItem.ViewMode = DataCompositionSettingsItemViewMode.Inaccessible;
	
	DataFilterItem = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	DataFilterItem.LeftValue = New DataCompositionField("Completed");
	DataFilterItem.ComparisonType = DataCompositionComparisonType.Equal;
	DataFilterItem.RightValue = True;
	
	ConditionalAppearanceItem.Appearance.SetParameterValue("TextColor", StyleColors.CompletedBusinessProcess);
	
EndProcedure

// Returns the string representation of the task  assignee Performer or the values specified in 
// parameters PerformerRole, MainAddressingObject, and AdditionalAddressingObject.
//
// Parameters:
//  Performer                   - UserRef  - a task assignee.
//  PerformerRole               - Catalogs.PerformerRoles - a role.
//  MainAddressingObject       - AnyRef - a reference to the main addressing object.
//  AdditionalAddressingObject - AnyRef - a reference to an additional addressing object.
//
// Returns:
//  String -  a string representation of the task assignee, for example:
//           "John Smith" - assignee as specified in the Performer parameter.
//           "Chief Accountant" - an assignee role specified in the PerformerRole parameter.
//           "Chief Accountant (Sun LLC)" - if a role is specified along with the main addressing object.
//           "Chief Accountant (Sun LLC, New York branch)" - if a role is specified along with both 
//                                                                   addressing objects.
//
Function PerformerString(Val Performer, Val PerformerRole,
	Val MainAddressingObject = Undefined, Val AdditionalAddressingObject = Undefined) Export
	
	If ValueIsFilled(Performer) Then
		Return String(Performer)
	ElsIf NOT PerformerRole.IsEmpty() Then
		Return RoleString(PerformerRole, MainAddressingObject, AdditionalAddressingObject);
	EndIf;
	Return NStr("ru = 'Не указан'; en = 'Not specified'; pl = 'Not specified';de = 'Not specified';ro = 'Not specified';tr = 'Not specified'; es_ES = 'Not specified'");

EndFunction

// Returns a string representation of the PerformerRole role and its addressing objects if they are specified.
//
// Parameters:
//  PerformerRole               - Catalogs.PerformerRoles  - a role.
//  MainAddressingObject       - AnyRef - a reference to the main addressing object.
//  AdditionalAddressingObject - AnyRef - a reference to an additional addressing object.
// 
// Returns:
//  String - a string representation of a role. For example:
//            "Chief Accountant" - an assignee role specified in the PerformerRole parameter.
//            "Chief Accountant (Sun LLC)" - if a role is specified along with the main addressing object.
//            "Chief Accountant (Sun LLC, New York branch)" - if a role is specified along with both 
//                                                                    addressing objects.
//
Function RoleString(Val PerformerRole,
	Val MainAddressingObject = Undefined, Val AdditionalAddressingObject = Undefined) Export
	
	If NOT PerformerRole.IsEmpty() Then
		Result = String(PerformerRole);
		If MainAddressingObject <> Undefined Then
			Result = Result + " (" + String(MainAddressingObject);
			If AdditionalAddressingObject <> Undefined Then
				Result = Result + " ," + String(AdditionalAddressingObject);
			EndIf;
			Result = Result + ")";
		EndIf;
		Return Result;
	EndIf;
	Return "";

EndFunction

// Marks for deletion all the specified business process tasks (or clears the mark).
//
// Parameters:
//  BusinessProcessRef - BusinessProcessRef - a business process whose tasks are to be marked for deletion.
//  DeletionMark     - Boolean - the DeletionMark property value for tasks.
//
Procedure MarkTasksForDeletion(BusinessProcessRef, DeletionMark) Export
	
	BeginTransaction();
	Try
		Lock = New DataLock;
		LockItem = Lock.Add("Task.PerformerTask");
		LockItem.SetValue("BusinessProcess", BusinessProcessRef);
		Lock.Lock();
		
		Query = New Query("SELECT
			|	Tasks.Ref AS Ref 
			|FROM
			|	Task.PerformerTask AS Tasks
			|WHERE
			|	Tasks.BusinessProcess = &BusinessProcess");
		Query.SetParameter("BusinessProcess", BusinessProcessRef);
		Selection = Query.Execute().Select();
		
		While Selection.Next() Do
			TaskObject = Selection.Ref.GetObject();
			TaskObject.SetDeletionMark(DeletionMark);
		EndDo;
		
		CommitTransaction();
	Except
		RollbackTransaction();
		WriteLogEvent(EventLogEvent(), EventLogLevel.Error, 
			BusinessProcessRef.Metadata(), BusinessProcessRef, DetailErrorDescription(ErrorInfo()));
		Raise;
	EndTry;
	
EndProcedure	

// Sets display and edit format for a form field of the Date type based on the subsystem settings.
//  
//
// Parameters:
//  DateField - FormField - a form control, a field with a value of the Date type.
//
Procedure SetDateFormat(DateField) Export
	
	UseDateAndTimeInTaskDeadlines = GetFunctionalOption("UseDateAndTimeInTaskDeadlines");
	FormatLine = ?(UseDateAndTimeInTaskDeadlines, "DLF=DT", "DLF=D");
	If DateField.Type = FormFieldType.InputField Then
		DateField.EditFormat = FormatLine;
	Else	
		DateField.Format               = FormatLine;
	EndIf;
	DateField.Width                   = ?(UseDateAndTimeInTaskDeadlines, 0, 9);
	
EndProcedure

// Gets the business processes of the TaskRef head task.
//
// Parameters:
//   TaskRef - TaskRef.PerformerTask - a head task.
//   ForChange - Boolean - if True, sets an exclusive managed lock for all business processes of the 
//                           specified head task. The default value is False.
// Returns:
//    Array - references to business processes (BusinessProcessRef.<Business process name>.)
// 
Function HeadTaskBusinessProcesses(TaskRef, ForChange = False) Export
	
	Result = SelectHeadTaskBusinessProcesses(TaskRef, ForChange);
	Return Result.Unload().UnloadColumn("Ref");
		
EndFunction

// Returns the business process completion date which is the maximum completion date of the business 
//  process tasks.
//
// Parameters:
//  BusinessProcessRef - BusinessProcessRef - a reference to a business process.
// 
// Returns:
//  Date - a completion date of the specified business process.
//
Function BusinessProcessCompletionDate(BusinessProcessRef) Export
	
	VerifyAccessRights("Read", BusinessProcessRef.Metadata());
	SetPrivilegedMode(True);
	Query = New Query;
	Query.Text = 
		"SELECT
		|	MAX(PerformerTask.CompletionDate) AS MaxCompletionDate
		|FROM
		|	Task.PerformerTask AS PerformerTask
		|WHERE
		|	PerformerTask.BusinessProcess = &BusinessProcess
		|	AND PerformerTask.Executed = TRUE";
	Query.SetParameter("BusinessProcess", BusinessProcessRef);
	
	Result = Query.Execute();
	If Result.IsEmpty() Then 
		Return CurrentSessionDate();
	EndIf;	
	
	Selection = Result.Select();
	Selection.Next();
	Return Selection.MaxCompletionDate;
	
EndFunction	

// Returns an array of business processes subordinate to the specified task.
//
// Parameters:
//  TaskRef  - TaskRef.PerformerTask - a task.
//  ForChange  - Boolean - if True, sets an exclusive managed lock for all business processes of the 
//                           specified head task. The default value is False.
//
// Returns:
//   Array - references to business processes (BusinessProcessRef.<Business process name>.)
//
Function MainTaskBusinessProcesses(TaskRef, ForChange = False) Export
	
	Result = New Array;
	For Each BusinessProcessMetadata In Metadata.BusinessProcesses Do
		
		// Business processes are not required to have a main task.
		MainTaskAttribute = BusinessProcessMetadata.Attributes.Find("MainTask");
		If MainTaskAttribute = Undefined Then
			Continue;
		EndIf;	
			
		If ForChange Then
			Lock = New DataLock;
			LockItem = Lock.Add(BusinessProcessMetadata.FullName());
			LockItem.SetValue("MainTask", TaskRef);
			Lock.Lock();
		EndIf;
		
		QueryText = StringFunctionsClientServer.SubstituteParametersToString(
			"SELECT ALLOWED
			|	%1.Ref AS Ref
			|FROM
			|	%2 AS %1
			|WHERE
			|	%1.MainTask = &MainTask", 
			BusinessProcessMetadata.Name, BusinessProcessMetadata.FullName());
		Query = New Query(QueryText);
		Query.SetParameter("MainTask", TaskRef);
		
		QueryResult = Query.Execute();
		Selection = QueryResult.Select();
		While Selection.Next() Do
			Result.Add(Selection.Ref);
		EndDo;
			
	EndDo;	
	
	Return Result;
		
EndFunction	

// Checks if the current user has sufficient rights to change the business process state.
//
// Parameters:
//  BusinessProcessObject - BusinessProcessObject - a business process object.
//
Procedure ValidateRightsToChangeBusinessProcessState(BusinessProcessObject) Export
	
	If Not ValueIsFilled(BusinessProcessObject.State) Then 
		BusinessProcessObject.State = Enums.BusinessProcessStates.Active;
	EndIf;
	
	If BusinessProcessObject.IsNew() Then
		PreviousState = Enums.BusinessProcessStates.Active;
	Else
		PreviousState = Common.ObjectAttributeValue(BusinessProcessObject.Ref, "State");
	EndIf;
	
	If PreviousState <> BusinessProcessObject.State Then
		
		If Not HasRightsToStopBusinessProcess(BusinessProcessObject) Then 
			MessageText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'Недостаточно прав для остановки бизнес-процесса ""%1"".'; en = 'Insufficient rights to stop business process ""%1"".'; pl = 'Insufficient rights to stop business process ""%1"".';de = 'Insufficient rights to stop business process ""%1"".';ro = 'Insufficient rights to stop business process ""%1"".';tr = 'Insufficient rights to stop business process ""%1"".'; es_ES = 'Insufficient rights to stop business process ""%1"".'"),
				String(BusinessProcessObject));
			Raise MessageText;
		EndIf;
		
		If PreviousState = Enums.BusinessProcessStates.Active Then
			
			If BusinessProcessObject.Completed Then
				Raise NStr("ru = 'Невозможно остановить завершенные бизнес-процессы.'; en = 'Cannot stop the completed business processes.'; pl = 'Cannot stop the completed business processes.';de = 'Cannot stop the completed business processes.';ro = 'Cannot stop the completed business processes.';tr = 'Cannot stop the completed business processes.'; es_ES = 'Cannot stop the completed business processes.'");
			EndIf;
				
			If Not BusinessProcessObject.Started Then
				Raise NStr("ru = 'Невозможно остановить не стартовавшие бизнес-процессы.'; en = 'Cannot stop the business processes that are not started yet.'; pl = 'Cannot stop the business processes that are not started yet.';de = 'Cannot stop the business processes that are not started yet.';ro = 'Cannot stop the business processes that are not started yet.';tr = 'Cannot stop the business processes that are not started yet.'; es_ES = 'Cannot stop the business processes that are not started yet.'");
			EndIf;
			
		ElsIf PreviousState = Enums.BusinessProcessStates.Stopped Then
			
			If BusinessProcessObject.Completed Then
				Raise NStr("ru = 'Невозможно сделать активными завершенные бизнес-процессы.'; en = 'Cannot activate the completed business processes.'; pl = 'Cannot activate the completed business processes.';de = 'Cannot activate the completed business processes.';ro = 'Cannot activate the completed business processes.';tr = 'Cannot activate the completed business processes.'; es_ES = 'Cannot activate the completed business processes.'");
			EndIf;
				
			If Not BusinessProcessObject.Started Then
				Raise NStr("ru = 'Невозможно сделать активными не стартовавшие бизнес-процессы.'; en = 'Cannot activate the business processes that are not started yet.'; pl = 'Cannot activate the business processes that are not started yet.';de = 'Cannot activate the business processes that are not started yet.';ro = 'Cannot activate the business processes that are not started yet.';tr = 'Cannot activate the business processes that are not started yet.'; es_ES = 'Cannot activate the business processes that are not started yet.'");
			EndIf;
			
		EndIf;
		
	EndIf;
	
EndProcedure

// Sets an exclusive managed lock for the specified business process.
// For calling commands in dynamic lists from handlers.
// Rows of dynamic list grouping are ignored.
//
// Parameters:
//   BusinessProcesses - Array - references to business processes (BusinessProcessRef.<Business 
//                             process name>) or a single business process reference.
//
Procedure LockBusinessProcesses(BusinessProcesses) Export
	
	Lock = New DataLock;
	If TypeOf(BusinessProcesses) = Type("Array") Then
		For each BusinessProcess In BusinessProcesses Do
			
			If TypeOf(BusinessProcess) = Type("DynamicalListGroupRow") Then
				Continue;
			EndIf;	
			
			LockItem = Lock.Add(BusinessProcess.Metadata().FullName());
			LockItem.SetValue("Ref", BusinessProcess);
		EndDo;
	Else	
		If TypeOf(BusinessProcesses) = Type("DynamicalListGroupRow") Then
			Return;
		EndIf;	
		LockItem = Lock.Add(BusinessProcesses.Metadata().FullName());
		LockItem.SetValue("Ref", BusinessProcesses);
	EndIf;
	Lock.Lock();
	
EndProcedure	

// Sets an exclusive managed lock for the specified tasks.
// For calling commands in dynamic lists from handlers.
// Rows of dynamic list grouping are ignored.
//
// Parameters:
//   Tasks - Array, TaskRef.PerformerTask - references  to tasks or a single reference.
//
Procedure LockTasks(Tasks) Export
	
	Lock = New DataLock;
	If TypeOf(Tasks) = Type("Array") Then
		For each Task In Tasks Do
			
			If TypeOf(Task) = Type("DynamicalListGroupRow") Then 
				Continue;
			EndIf;
			
			LockItem = Lock.Add("Task.PerformerTask");
			LockItem.SetValue("Ref", Task);
		EndDo;
	Else	
		If TypeOf(BusinessProcesses) = Type("DynamicalListGroupRow") Then
			Return;
		EndIf;	
		LockItem = Lock.Add("Task.PerformerTask");
		LockItem.SetValue("Ref", Tasks);
	EndIf;
	Lock.Lock();
	
EndProcedure

// Fills MainTask attribute when creating a business process based on another business process.
// See also BusinessProcessesAndTasksOverridable.OnFillMainBusinessProcessTask.
//
// Parameters:
//  BusinessProcessObject	 - BusinessProcessObject        - a business process to be filled in.
//  FillingData	 - TaskRef, Arbitrary - filling data that is passed to the filling handler.
//
Procedure FillMainTask(BusinessProcessObject, FillingData) Export
	
	StandardProcessing = True;
	BusinessProcessesAndTasksOverridable.OnFillMainBusinessProcessTask(BusinessProcessObject, FillingData, StandardProcessing);
	If Not StandardProcessing Then
		Return;
	EndIf;
	
	If FillingData = Undefined Then 
		Return;
	EndIf;
	
	If TypeOf(FillingData) = Type("TaskRef.PerformerTask") Then
		BusinessProcessObject.MainTask = FillingData;
	EndIf;
	
EndProcedure

// Gets a task assignees group that matches the addressing attributes.
//  If the group does not exist yet, it is created and returned.
//
// Parameters:
//  PerformerRole               - CatalogRef.PerformerRoles - an assignee role.
//  MainAddressingObject       - AnyRef - a reference to the main addressing object.
//  AdditionalAddressingObject - AnyRef - a reference to an additional addressing object.
// 
// Returns:
//  CatalogRef.TaskPerformersGroups - a task assignees group found by role.
//
Function TaskPerformersGroup(PerformerRole, MainAddressingObject, AdditionalAddressingObject) Export
	
	BeginTransaction();
	Try
		Lock = New DataLock;
		LockItem = Lock.Add("Catalog.TaskPerformersGroups");
		LockItem.SetValue("PerformerRole", PerformerRole);
		LockItem.SetValue("MainAddressingObject", MainAddressingObject);
		LockItem.SetValue("AdditionalAddressingObject", AdditionalAddressingObject);
		Lock.Lock();
		
		Query = New Query(
			"SELECT
			|	TaskPerformersGroups.Ref AS Ref
			|FROM
			|	Catalog.TaskPerformersGroups AS TaskPerformersGroups
			|WHERE
			|	TaskPerformersGroups.PerformerRole = &PerformerRole
			|	AND TaskPerformersGroups.MainAddressingObject = &MainAddressingObject
			|	AND TaskPerformersGroups.AdditionalAddressingObject = &AdditionalAddressingObject");
		Query.SetParameter("PerformerRole",               PerformerRole);
		Query.SetParameter("MainAddressingObject",       MainAddressingObject);
		Query.SetParameter("AdditionalAddressingObject", AdditionalAddressingObject);
		Selection = Query.Execute().Select();
		If Selection.Next() Then
			PerformersGroup = Selection.Ref;
		Else
			// It is necessary to add a new task assignees group.
			PerformersGroupObject = Catalogs.TaskPerformersGroups.CreateItem();
			PerformersGroupObject.PerformerRole               = PerformerRole;
			PerformersGroupObject.MainAddressingObject       = MainAddressingObject;
			PerformersGroupObject.AdditionalAddressingObject = AdditionalAddressingObject;
			PerformersGroupObject.Write();
			PerformersGroup = PerformersGroupObject.Ref;
		EndIf;
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;	
	Return PerformersGroup;
	
EndFunction 

////////////////////////////////////////////////////////////////////////////////
// Deferred start of business processes.

// Adds a process for deferred start.
//
// Parameters:
//  Process    -  BusinessProcessRef - a business process for deferred start.
//  StartDate - Date - a deferred start date.
//
Procedure AddProcessForDeferredStart(Process, StartDate) Export
	
	If Not ValueIsFilled(StartDate) OR Not ValueIsFilled(Process) Then
		Return;
	EndIf;
	
	RecordSet = InformationRegisters.ProcessesToStart.CreateRecordSet();
	RecordSet.Filter.BusinessProcess.Set(Process);
	
	Record = RecordSet.Add();
	Record.BusinessProcess = Process;
	Record.DeferredStartDate = StartDate;
	Record.State = Enums.ProcessesStatesForStart.ReadyToStart;
	
	RecordSet.Write();
	
EndProcedure

// Disables deferred process start.
//
// Parameters:
//  Process - BusinessProcessRef - a business process to disable a deferred start for.
//
Procedure DisableProcessDeferredStart(Process) Export
	
	StartSettings = DeferredProcessParameters(Process);
	
	If StartSettings = Undefined Then // The process does not wait for start.
		Return;
	EndIf;
	
	If StartSettings.State = PredefinedValue("Enum.ProcessesStatesForStart.ReadyToStart") Then
		RecordSet = InformationRegisters.ProcessesToStart.CreateRecordSet();
		RecordSet.Filter.BusinessProcess.Set(Process);
		RecordSet.Write();
	EndIf;
	
EndProcedure

// Starts the deferred business process and sets the start flag.
//
// Parameters:
//   - BusinessProcess - BusinessProcessObject - a process to be started in deferred mode.
//
Procedure StartDeferredProcess(BusinessProcess) Export
	
	BeginTransaction();
	
	Try
		
		LockDataForEdit(BusinessProcess);
		
		BusinessProcessObject = BusinessProcess.GetObject();
		// Starting a business process and registering it in the register.
		BusinessProcessObject.Start();
		InformationRegisters.ProcessesToStart.RegisterProcessStart(BusinessProcess);
		
		UnlockDataForEdit(BusinessProcess);
		
		CommitTransaction();
		
	Except
		
		RollbackTransaction();
		
		ErrorDescription = DetailErrorDescription(ErrorInfo());
		
		ErrorText = NStr("ru = 'Во время отложенного старта этого процесса произошла ошибка:
			|%1
			|Попробуйте запустить процесс вручную, а не отложенно.'; 
			|en = 'An error occurred during the deferred start of this process:
			|%1
			|Try to start the process manually, not automatically.'; 
			|pl = 'An error occurred during the deferred start of this process:
			|%1
			|Try to start the process manually, not automatically.';
			|de = 'An error occurred during the deferred start of this process:
			|%1
			|Try to start the process manually, not automatically.';
			|ro = 'An error occurred during the deferred start of this process:
			|%1
			|Try to start the process manually, not automatically.';
			|tr = 'An error occurred during the deferred start of this process:
			|%1
			|Try to start the process manually, not automatically.'; 
			|es_ES = 'An error occurred during the deferred start of this process:
			|%1
			|Try to start the process manually, not automatically.'");
			
		Details = StringFunctionsClientServer.SubstituteParametersToString(
			ErrorText,
			ErrorDescription);
		
		InformationRegisters.ProcessesToStart.RegisterStartCancellation(BusinessProcess, Details);
			
	EndTry;
	
EndProcedure

// Returns information on the business process start.
//
// Parameters:
//  Process - BusinessProcessRef - a business process to obtain start information from.
// 
// Returns:
//  - Undefined - returned if there is no info.
//  - Structure - if the following is available:
//     * BusinessProcess - BusinessProcessRef.
//     * DeferredStartDate - DateAndTime.
//     * State - EnumRef.ProcessesStatesForStart.
//     * StartCancelReason - String - a reason for canceling the start.
//
Function DeferredProcessParameters(Process) Export
	
	Result = Undefined;
	
	If Not ValueIsFilled(Process) Then
		Return Result;
	EndIf;
	
	Query = New Query;
	Query.Text = 
		"SELECT
		|	ProcessesToStart.BusinessProcess,
		|	ProcessesToStart.DeferredStartDate,
		|	ProcessesToStart.State,
		|	ProcessesToStart.StartCancelReason
		|FROM
		|	InformationRegister.ProcessesToStart AS ProcessesToStart
		|WHERE
		|	ProcessesToStart.BusinessProcess = &BusinessProcess";
	Query.SetParameter("BusinessProcess", Process);
	Selection = Query.Execute().Select();
	
	If Selection.Next() Then
		Result = New Structure;
		Result.Insert("BusinessProcess", Selection.BusinessProcess);
		Result.Insert("DeferredStartDate", Selection.DeferredStartDate);
		Result.Insert("State", Selection.State);
		Result.Insert("StartCancelReason", Selection.StartCancelReason);
	EndIf;
	
	Return Result;
	
EndFunction

// Returns the start date of a deferred business process if BusinessProcess waits for deferred start.
//  Otherwise returns an empty date.
//
// Parameters:
//  BusinessProcess - BusinessProcessRef - a business process to get a deferred start date for.
// 
// Returns:
//  Date - a deferred start date.
//
Function ProcessDeferredStartDate(BusinessProcess) Export

	DeferredStartDate = '00010101';
	
	Setting = DeferredProcessParameters(BusinessProcess);
	
	If Setting = Undefined Then
		Return DeferredStartDate;
	EndIf;
	
	If Setting.State = PredefinedValue("Enum.ProcessesStatesForStart.ReadyToStart") Then
		DeferredStartDate = Setting.DeferredStartDate;
	EndIf;
	
	Return DeferredStartDate;

EndFunction

////////////////////////////////////////////////////////////////////////////////
// Scheduled job handlers.

// Runs notification mailing to assignees on new tasks received since the date of previous mailing.
// Notifications are sent using email on behalf of the system account.
// Also it is the NewPerformerTaskNotifications scheduled job handler.
//
Procedure NotifyPerformersOnNewTasks() Export
	
	Common.OnStartExecuteScheduledJob(Metadata.ScheduledJobs.NewPerformerTaskNotifications);
	
	ErrorDescription = "";
	MessageKind = NStr("ru = 'Бизнес-процессы и задачи. Уведомление о новых задачах.'; en = 'Business processes and tasks. New task notification.'; pl = 'Business processes and tasks. New task notification.';de = 'Business processes and tasks. New task notification.';ro = 'Business processes and tasks. New task notification.';tr = 'Business processes and tasks. New task notification.'; es_ES = 'Business processes and tasks. New task notification.'", Common.DefaultLanguageCode());

	If NOT SystemEmailAccountIsSetUp(ErrorDescription) Then
		WriteLogEvent(MessageKind, EventLogLevel.Error,
			Metadata.ScheduledJobs.NewPerformerTaskNotifications,, ErrorDescription);
		Return;
	EndIf;
	
	NotificationDate = CurrentSessionDate();
	LatestNotificationDate = Constants.NewTasksNotificationDate.Get();
	
	// If no notifications were sent earlier or the last notification was sent more than one day ago, 
	// selecting new tasks for the last 24 hours.
	If (LatestNotificationDate = '00010101000000') 
		Or (NotificationDate - LatestNotificationDate > 24*60*60) Then
		LatestNotificationDate = NotificationDate - 24*60*60;
	EndIf;
	
	WriteLogEvent(MessageKind, EventLogLevel.Information,,,
		StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = 'Начато регламентное уведомление о новых задачах за период %1 - %2'; en = 'Scheduled notification of new tasks for the period %1–%2 is started'; pl = 'Scheduled notification of new tasks for the period %1–%2 is started';de = 'Scheduled notification of new tasks for the period %1–%2 is started';ro = 'Scheduled notification of new tasks for the period %1–%2 is started';tr = 'Scheduled notification of new tasks for the period %1–%2 is started'; es_ES = 'Scheduled notification of new tasks for the period %1–%2 is started'"),
		LatestNotificationDate, NotificationDate));
	
	TasksByPerformers = SelectNewTasksByPerformers(LatestNotificationDate, NotificationDate);
	For Each PerformerRow In TasksByPerformers.Rows Do
		SendNotificationOnNewTasks(PerformerRow.Performer, PerformerRow);
	EndDo;
	
	SetPrivilegedMode(True);
	Constants.NewTasksNotificationDate.Set(NotificationDate);
	SetPrivilegedMode(False);
	
	WriteLogEvent(MessageKind, EventLogLevel.Information,,,
		StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = 'Завершено регламентное уведомление о новых задачах (уведомлено исполнителей: %1)'; en = 'Scheduled notification of new tasks is completed (notified assignees: %1)'; pl = 'Scheduled notification of new tasks is completed (notified assignees: %1)';de = 'Scheduled notification of new tasks is completed (notified assignees: %1)';ro = 'Scheduled notification of new tasks is completed (notified assignees: %1)';tr = 'Scheduled notification of new tasks is completed (notified assignees: %1)'; es_ES = 'Scheduled notification of new tasks is completed (notified assignees: %1)'"),
		TasksByPerformers.Rows.Count()));
	
EndProcedure

// Runs notification mailing to task assignees and authors on overdue tasks.
// Notifications are sent using email on behalf of the system account.
// If a task is sent to a role with no assignee, a new task to the persons responsible for role 
// setting is created.
//
// Also it is the TaskMonitoring scheduled job handler.
//
Procedure CheckTasks() Export
	
	Common.OnStartExecuteScheduledJob(Metadata.ScheduledJobs.TaskMonitoring);
	ErrorDescription = "";
	
	If NOT SystemEmailAccountIsSetUp(ErrorDescription) Then
		MessageKind = NStr("ru = 'Бизнес-процессы и задачи. Мониторинг задач.'; en = 'Business processes and tasks. Task monitoring.'; pl = 'Business processes and tasks. Task monitoring.';de = 'Business processes and tasks. Task monitoring.';ro = 'Business processes and tasks. Task monitoring.';tr = 'Business processes and tasks. Task monitoring.'; es_ES = 'Business processes and tasks. Task monitoring.'", Common.DefaultLanguageCode());
		WriteLogEvent(MessageKind, EventLogLevel.Error,
			Metadata.ScheduledJobs.TaskMonitoring,, ErrorDescription);
			Return;
	EndIf;

	OverdueTasks = SelectOverdueTasks();
	If OverdueTasks.Count() = 0 Then
		Return;
	EndIf;
		
	MessageSetByAddressees = SelectOverdueTasksPerformers(OverdueTasks);
	For Each EmailFromSet In MessageSetByAddressees Do
		SendNotificationAboutOverdueTasks(EmailFromSet);
	EndDo;
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Updates infobase.

// Prepares the first portion of objects for deferred access rights processing.
// It is intended to call from deferred update handlers on changing the logic of generating access value sets.
//
// Parameters:
//   Parameters     - Structure - structure of deferred update handler parameters.
//   BusinessProcess - MetadataObject.BusinessProcess - business process metadata whose access value 
//                   sets are to be updated.
//   ProcedureName  - String - a name of procedure of deferred update handler for the event log.
//   PortionSize  - Number  - a number of objects processed in one call.
//
Procedure StartUpdateAccessValuesSetsPortion(Parameters, BusinessProcess, ProcedureName, BatchSize = 1000) Export
	
	If Parameters.ExecutionProgress.TotalObjectCount = 0 Then
		Query = New Query;
		Query.Text =
			"SELECT
			|	COUNT(TableWithAccessValueSets.Ref) AS Count,
			|	MAX(TableWithAccessValueSets.Date) AS Date
			|FROM
			|	%1 AS TableWithAccessValueSets";
		
		Query.Text = StringFunctionsClientServer.SubstituteParametersToString(Query.Text, BusinessProcess.FullName());
		QueryResult = Query.Execute().Unload();
		Parameters.ExecutionProgress.TotalObjectCount = QueryResult[0].Count;
		
		If Not Parameters.Property("InitialDataForProcessing") Then
			Parameters.Insert("InitialDataForProcessing", QueryResult[0].Date);
		EndIf;
		
	EndIf;
	
	If Not Parameters.Property("ObjectsWithIssues") Then
		Parameters.Insert("ObjectsWithIssues", New Array);
	EndIf;
	
	If Not Parameters.Property("InitialRefForProcessing") Then
		Parameters.Insert("InitialRefForProcessing", Common.ObjectManagerByFullName(BusinessProcess.FullName()).EmptyRef());
	EndIf;
	
	Query = New Query;
	Query.Text =
		"SELECT TOP %1
		|	TableWithAccessValueSets.Ref AS Ref,
		|	TableWithAccessValueSets.Date AS Date
		|FROM
		|	%2 AS TableWithAccessValueSets
		|WHERE TableWithAccessValueSets.Date <= &InitialDataForProcessing
		|   AND TableWithAccessValueSets.Ref > &InitialRefForProcessing
		|ORDER BY 
		|   Date DESC,
		|   Ref";
	
	Query.Text = StringFunctionsClientServer.SubstituteParametersToString(Query.Text, Format(BatchSize, "NG=0"), BusinessProcess.FullName());
	Query.SetParameter("InitialDataForProcessing", Parameters.InitialDataForProcessing);
	Query.SetParameter("InitialRefForProcessing", Parameters.InitialRefForProcessing);
	
	QueryResult = Query.Execute().Unload();
	ObjectsToProcess = QueryResult.UnloadColumn("Ref");
	Parameters.Insert("ObjectsToProcess", ObjectsToProcess);
	
	CommonClientServer.SupplementArray(Parameters.ObjectsToProcess, Parameters.ObjectsWithIssues);
	Parameters.ObjectsWithIssues.Clear();
	
	Parameters.ProcessingCompleted = ObjectsToProcess.Count() = 0 
		Or QueryResult[0].Ref = Parameters.InitialRefForProcessing;
	If Not Parameters.ProcessingCompleted Then
		
		If Not Parameters.Property("BusinessProcess") Then
			Parameters.Insert("BusinessProcess", BusinessProcess);
		EndIf;
		
		If Not Parameters.Property("ObjectsProcessed") Then
			Parameters.Insert("ObjectsProcessed", 0);
		EndIf;
		
		If Not Parameters.Property("ProcedureName") Then
			Parameters.Insert("ProcedureName", ProcedureName);
		EndIf;
		
		Parameters.InitialDataForProcessing = QueryResult[QueryResult.Count() - 1].Date;
		Parameters.InitialRefForProcessing = QueryResult[QueryResult.Count() - 1].Ref;
	EndIf;
	
EndProcedure

// Complete processing of the first portion of objects for deferred access right processing.
// It is intended to call from deferred update handlers on changing the logic of generating access value sets.
//
// Parameters:
//   Parameters     - Structure - structure of deferred update handler parameters.
//
Procedure FinishUpdateAccessValuesSetsPortions(Parameters) Export
	
	Parameters.ExecutionProgress.ProcessedObjectsCount = Parameters.ExecutionProgress.ProcessedObjectsCount + Parameters.ObjectsProcessed;
	If Parameters.ObjectsProcessed = 0 Then
		MessageText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Процедуре ""%1"" не удалось обновить права доступа для некоторых объектов (пропущены): %1'; en = 'Procedure ""%1"" cannot update access rights for some objects (skipped): %1'; pl = 'Procedure ""%1"" cannot update access rights for some objects (skipped): %1';de = 'Procedure ""%1"" cannot update access rights for some objects (skipped): %1';ro = 'Procedure ""%1"" cannot update access rights for some objects (skipped): %1';tr = 'Procedure ""%1"" cannot update access rights for some objects (skipped): %1'; es_ES = 'Procedure ""%1"" cannot update access rights for some objects (skipped): %1'"), 
				Parameters.ProcedureName, Parameters.ObjectsWithIssues.Count());
		Raise MessageText;
	EndIf;
	
	WriteLogEvent(InfobaseUpdate.EventLogEvent(), EventLogLevel.Information,
		Parameters.BusinessProcess,, 
		StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = 'Процедура ""%1"" обновила права доступа для очередной порции объектов: %2'; en = 'The ""%1"" procedure has updated access rights for objects: %2'; pl = 'The ""%1"" procedure has updated access rights for objects: %2';de = 'The ""%1"" procedure has updated access rights for objects: %2';ro = 'The ""%1"" procedure has updated access rights for objects: %2';tr = 'The ""%1"" procedure has updated access rights for objects: %2'; es_ES = 'The ""%1"" procedure has updated access rights for objects: %2'"), 
			Parameters.ProcedureName, Parameters.ObjectsProcessed));
	
	// Clearing temporary parameters which are not required to save between the sessions.
	Parameters.Delete("ObjectsToProcess");
	Parameters.Delete("ProcedureName");
	Parameters.Delete("BusinessProcess");
	Parameters.Delete("ObjectsProcessed");
	
EndProcedure

#EndRegion

#Region Internal

////////////////////////////////////////////////////////////////////////////////
// Configuration subsystems event handlers.

// See InfobaseUpdateSSL.OnAddUpdateHandlers. 
Procedure OnAddUpdateHandlers(Handlers) Export
	
	Handler = Handlers.Add();
	Handler.Version = "1.0.2.2";
	Handler.InitialFilling = True;
	Handler.Procedure = "BusinessProcessesAndTasksServer.FillEmployeeResponsibleForCompletionControl";
	
	Handler = Handlers.Add();
	Handler.Version = "1.0.6.6";
	Handler.Procedure = "BusinessProcessesAndTasksServer.FillSubjectFromString";
	
	Handler = Handlers.Add();
	Handler.Version = "1.1.1.2";
	Handler.Procedure = "BusinessProcessesAndTasksServer.FillStatesAndAcceptedFlags";
	
	Handler = Handlers.Add();
	Handler.Version = "1.2.1.1";
	Handler.Procedure = "BusinessProcessesAndTasksServer.FillPerformerRoleCode";
	
	If Common.SubsystemExists("StandardSubsystems.AccessManagement") Then
		Handler = Handlers.Add();
		Handler.Version = "2.3.3.39";
		Handler.ID = New UUID("80A64E76-12CC-4075-A80B-9EB93C411C85");
		Handler.Procedure = "BusinessProcesses.Job.ProcessDataForMigrationToNewVersion";
		Handler.Comment = NStr("ru = 'Обновление прав доступа для бизнес-процесса ""Задание"". 
			|До завершения обработки будут действовать прежние права доступа к заданиям.'; 
			|en = 'Updating access rights to the ""Job"" business process.
			|Until the processing is complete, previous access rights to the jobs are applied.'; 
			|pl = 'Updating access rights to the ""Job"" business process.
			|Until the processing is complete, previous access rights to the jobs are applied.';
			|de = 'Updating access rights to the ""Job"" business process.
			|Until the processing is complete, previous access rights to the jobs are applied.';
			|ro = 'Updating access rights to the ""Job"" business process.
			|Until the processing is complete, previous access rights to the jobs are applied.';
			|tr = 'Updating access rights to the ""Job"" business process.
			|Until the processing is complete, previous access rights to the jobs are applied.'; 
			|es_ES = 'Updating access rights to the ""Job"" business process.
			|Until the processing is complete, previous access rights to the jobs are applied.'");
		Handler.ExecutionMode = "Deferred";
		Handler.DeferredProcessingQueue = 1;
		Handler.UpdateDataFillingProcedure = "BusinessProcesses.Job.RegisterDataToProcessForMigrationToNewVersion";
		Handler.ObjectsToBeRead      = "BusinessProcess.Job";
		Handler.ObjectsToChange    = "BusinessProcess.Job";
		Handler.CheckProcedure    = "InfobaseUpdate.DataUpdatedForNewApplicationVersion";
		Handler.ObjectsToLock   = "BusinessProcess.Job";
	EndIf;
	
	Handler = Handlers.Add();
	Handler.InitialFilling = True;
	Handler.Version              = "2.3.3.70";
	Handler.Procedure           = "BusinessProcessesAndTasksServer.UpdateScheduledJobUsage";
	Handler.SharedData         = False;
	Handler.ExecutionMode     = "Seamless";
	Handler.ID       = New UUID("86ec32f9-d28f-4282-1e6f-222a8653d2e0");
	Handler.Comment         =
		NStr("ru = 'Определяет использование регламентного задания выполняющего старт отложенных бизнес-процессов.'; en = 'Defines usage of a scheduled job that starts deferred business processes.'; pl = 'Defines usage of a scheduled job that starts deferred business processes.';de = 'Defines usage of a scheduled job that starts deferred business processes.';ro = 'Defines usage of a scheduled job that starts deferred business processes.';tr = 'Defines usage of a scheduled job that starts deferred business processes.'; es_ES = 'Defines usage of a scheduled job that starts deferred business processes.'");
		
	Handler = Handlers.Add();
	Handler.InitialFilling = True;
	Handler.ExecutionMode = "Seamless";
	Handler.Procedure = "BusinessProcessesAndTasksServer.FillPredefinedItemDescriptionAllAddressingObjects";
	
EndProcedure

// See SubsystemIntegrationSSL.OnDeterminePerformersGroups. 
Procedure OnDeterminePerformersGroups(TempTablesManager, ParameterContent, ParameterValue, NoPerformerGroups) Export
	
	NoPerformerGroups = False;
	
	Query = New Query;
	Query.TempTablesManager = TempTablesManager;
	
	If ParameterContent = "PerformersGroups" Then
		
		Query.SetParameter("PerformersGroups", ParameterValue);
		Query.Text =
		"SELECT DISTINCT
		|	TaskPerformers.TaskPerformersGroup AS PerformersGroup,
		|	TaskPerformers.Performer AS User
		|INTO PerformerGroupsTable
		|FROM
		|	InformationRegister.TaskPerformers AS TaskPerformers
		|WHERE
		|	TaskPerformers.TaskPerformersGroup IN(&PerformersGroups)";
		
	ElsIf ParameterContent = "Performers" Then
		
		Query.SetParameter("Performers", ParameterValue);
		Query.Text =
		"SELECT DISTINCT
		|	TaskPerformers.TaskPerformersGroup AS PerformersGroup,
		|	TaskPerformers.Performer AS User
		|INTO PerformerGroupsTable
		|FROM
		|	InformationRegister.TaskPerformers AS TaskPerformers
		|WHERE
		|	TaskPerformers.Performer IN(&Performers)";
		
	Else
		Query.Text =
		"SELECT DISTINCT
		|	TaskPerformers.TaskPerformersGroup AS PerformersGroup,
		|	TaskPerformers.Performer AS User
		|INTO PerformerGroupsTable
		|FROM
		|	InformationRegister.TaskPerformers AS TaskPerformers";
	EndIf;
	
	Query.Execute();
	
EndProcedure

// See ImportDataFromFileOverridable.OnDefineCatalogsForDataImport. 
Procedure OnDefineCatalogsForDataImport(CatalogsToImport) Export
	
	// Cannot import to the TaskPerformersGroups catalog.
	TableRow = CatalogsToImport.Find(Metadata.Catalogs.TaskPerformersGroups.FullName(), "FullName");
	If TableRow <> Undefined Then 
		CatalogsToImport.Delete(TableRow);
	EndIf;
	
EndProcedure

// See BatchObjectModificationOverridable.OnDetermineObjectsWithEditableAttributes. 
Procedure OnDefineObjectsWithEditableAttributes(Objects) Export
	Objects.Insert(Metadata.BusinessProcesses.Job.FullName(), "AttributesToEditInBatchProcessing");
	Objects.Insert(Metadata.Tasks.PerformerTask.FullName(), "AttributesToEditInBatchProcessing");
	Objects.Insert(Metadata.ChartsOfCharacteristicTypes.TaskAddressingObjects.FullName(), "AttributesToSkipInBatchProcessing");
	Objects.Insert(Metadata.Catalogs.TaskPerformersGroups.FullName(), "AttributesToSkipInBatchProcessing");
	Objects.Insert(Metadata.Catalogs.PerformerRoles.FullName(), "AttributesToSkipInBatchProcessing");
EndProcedure

// See ScheduledJobsOverridable.OnDefineScheduledJobsSettings. 
Procedure OnDefineScheduledJobSettings(Settings) Export
	Setting = Settings.Add();
	Setting.ScheduledJob = Metadata.ScheduledJobs.TaskMonitoring;
	Setting.FunctionalOption = Metadata.FunctionalOptions.UseBusinessProcessesAndTasks;
	Setting.UseExternalResources = True;
	
	Setting = Settings.Add();
	Setting.ScheduledJob = Metadata.ScheduledJobs.NewPerformerTaskNotifications;
	Setting.FunctionalOption = Metadata.FunctionalOptions.UseBusinessProcessesAndTasks;
	Setting.UseExternalResources = True;
	
	Setting = Settings.Add();
	Setting.ScheduledJob = Metadata.ScheduledJobs.StartDeferredProcesses;
	Setting.FunctionalOption = Metadata.FunctionalOptions.UseBusinessProcessesAndTasks;

EndProcedure

// See CommonOverridable.OnAddRefsSearchExceptions. 
Procedure OnAddReferenceSearchExceptions(RefSearchExclusions) Export
	
	RefSearchExclusions.Add(Metadata.InformationRegisters.TaskPerformers.FullName());
	RefSearchExclusions.Add(Metadata.InformationRegisters.BusinessProcessesData.FullName());
	
EndProcedure

// See JobsQueueOverridable.OnGetTemplatesList. 
Procedure OnGetTemplateList(JobTemplates) Export
	
	JobTemplates.Add("TaskMonitoring");
	JobTemplates.Add("NewPerformerTaskNotifications");
	
EndProcedure

// See UserRemindersOverridable.OnFillSourceAttributesListWithReminderDates. 
Procedure OnFillSourceAttributesListWithReminderDates(Source, AttributesWithDates) Export
	
	If TypeOf(Source) = Type("TaskRef.PerformerTask") Then
		AttributesWithDates.Clear();
		AttributesWithDates.Add("DueDate"); 
		AttributesWithDates.Add("StartDate"); 
	EndIf;
	
EndProcedure

// See AccessManagementOverridable.OnFillAccessRightsDependencies. 
Procedure OnFillAccessRightsDependencies(RightsDependencies) Export
	
	// An assignee task can be changed when a business process is read-only. That is why it is not 
	// required to check edit rights or editing restrictions. Check read rights and reading restrictions.
	// 
	
	Row = RightsDependencies.Add();
	Row.SubordinateTable = "Task.PerformerTask";
	Row.LeadingTable     = "BusinessProcess.Job";
	
EndProcedure

// See AccessManagementOverridable.OnFillMetadataObjectsAccessRestrictionsKinds. 
Procedure OnFillMetadataObjectsAccessRestrictionKinds(Details) Export
	
	Details = Details 
		+ "
		|BusinessProcess.Job.Read.Users
		|BusinessProcess.Job.Update.Users
		|Task.PerformerTask.Read.Object.BusinessProcess.Job
		|Task.PerformerTask.Read.Users
		|Task.PerformerTask.Update.Users
		|InformationRegister.BusinessProcessesData.Read.Object.BusinessProcess.Job
		|";
	
EndProcedure

// See AccessManagementOverridable.OnFillAccessKinds. 
Procedure OnFillAccessKinds(AccessKinds) Export
	
	AccessKind = AccessKinds.Find("Users", "Name");
	If AccessKind <> Undefined Then
		ModuleAccessManagement = Common.CommonModule("AccessManagement");
		ModuleAccessManagement.AddExtraAccessKindTypes(AccessKind,
			Type("CatalogRef.TaskPerformersGroups"));
	EndIf;
	
EndProcedure

// See AccessManagementOverridable.OnFillListsWithAccessRestriction. 
Procedure OnFillListsWithAccessRestriction(Lists) Export
	
	Lists.Insert(Metadata.InformationRegisters.BusinessProcessesData, True);
	Lists.Insert(Metadata.InformationRegisters.TaskPerformers, True);
	Lists.Insert(Metadata.BusinessProcesses.Job, True);
	Lists.Insert(Metadata.Tasks.PerformerTask, True);
	
EndProcedure

// See ReportsOptionsOverridable.CustomizeReportsOptions. 
Procedure OnSetUpReportsOptions(Settings) Export
	ModuleReportsOptions = Common.CommonModule("ReportsOptions");
	ModuleReportsOptions.CustomizeReportInManagerModule(Settings, Metadata.Reports.BusinessProcesses);
	ModuleReportsOptions.CustomizeReportInManagerModule(Settings, Metadata.Reports.HungTasks);
	ModuleReportsOptions.CustomizeReportInManagerModule(Settings, Metadata.Reports.Jobs);
	ModuleReportsOptions.CustomizeReportInManagerModule(Settings, Metadata.Reports.Tasks);
	ModuleReportsOptions.CustomizeReportInManagerModule(Settings, Metadata.Reports.ExpiringTasksOnDate);
	ModuleReportsOptions.CustomizeReportInManagerModule(Settings, Metadata.Reports.OverdueTasks);
EndProcedure

// See ToDoListOverridable.OnDetermineToDoListHandlers 
Procedure OnFillToDoList(ToDoList) Export
	
	ModuleToDoListServer = Common.CommonModule("ToDoListServer");
	If Not AccessRight("Edit", Metadata.Tasks.PerformerTask)
		Or ModuleToDoListServer.UserTaskDisabled("PerformerTasks") Then
		Return;
	EndIf;
	
	If Not GetFunctionalOption("UseBusinessProcessesAndTasks") Then
		Return;
	EndIf;
	
	PerformerTaskQuantity = PerformerTaskQuantity();
	
	// This procedure is only called when To-do list subsystem is available. Therefore, the subsystem 
	// availability check is redundant.
	Sections = ModuleToDoListServer.SectionsForObject(Metadata.Tasks.PerformerTask.FullName());
	
	If Users.IsExternalUserSession()
		AND Sections.Count() = 0 Then
		Sections.Add(Metadata.Tasks.PerformerTask);
	EndIf;
	
	For Each Section In Sections Do
		
		MyTasksID = "PerformerTasks" + StrReplace(Section.FullName(), ".", "");
		ToDoItem = ToDoList.Add();
		ToDoItem.ID  = MyTasksID;
		ToDoItem.HasToDoItems       = PerformerTaskQuantity.Total > 0;
		ToDoItem.Presentation  = NStr("ru = 'Мои задачи'; en = 'My tasks'; pl = 'My tasks';de = 'My tasks';ro = 'My tasks';tr = 'My tasks'; es_ES = 'My tasks'");
		ToDoItem.Count     = PerformerTaskQuantity.Total;
		ToDoItem.Form          = "Task.PerformerTask.Form.MyTasks";
		FilterValue		= New Structure("Executed", False);
		ToDoItem.FormParameters = New Structure("Filter", FilterValue);
		ToDoItem.Owner       = Section;
		
		ToDoItem = ToDoList.Add();
		ToDoItem.ID  = "PerformerTasksOverdue";
		ToDoItem.HasToDoItems       = PerformerTaskQuantity.Overdue > 0;
		ToDoItem.Presentation  = NStr("ru = 'просроченные'; en = 'overdue'; pl = 'overdue';de = 'overdue';ro = 'overdue';tr = 'overdue'; es_ES = 'overdue'");
		ToDoItem.Count     = PerformerTaskQuantity.Overdue;
		ToDoItem.Important         = True;
		ToDoItem.Owner       = MyTasksID; 
		
		ToDoItem = ToDoList.Add();
		ToDoItem.ID  = "PerformerTasksForToday";
		ToDoItem.HasToDoItems       = PerformerTaskQuantity.ForToday > 0;
		ToDoItem.Presentation  = NStr("ru = 'сегодня'; en = 'today'; pl = 'today';de = 'today';ro = 'today';tr = 'today'; es_ES = 'today'");
		ToDoItem.Count     = PerformerTaskQuantity.ForToday;
		ToDoItem.Owner       = MyTasksID; 

		ToDoItem = ToDoList.Add();
		ToDoItem.ID  = "PerformerTasksForWeek";
		ToDoItem.HasToDoItems       = PerformerTaskQuantity.ForWeek > 0;
		ToDoItem.Presentation  = NStr("ru = 'на этой неделе'; en = 'this week'; pl = 'this week';de = 'this week';ro = 'this week';tr = 'this week'; es_ES = 'this week'");
		ToDoItem.Count     = PerformerTaskQuantity.ForWeek;
		ToDoItem.Owner       = MyTasksID; 

		ToDoItem = ToDoList.Add();
		ToDoItem.ID  = "PerformerTasksForNextWeek";
		ToDoItem.HasToDoItems       = PerformerTaskQuantity.ForNextWeek > 0;
		ToDoItem.Presentation  = NStr("ru = 'на следующей неделе'; en = 'next week'; pl = 'next week';de = 'next week';ro = 'next week';tr = 'next week'; es_ES = 'next week'");
		ToDoItem.Count     = PerformerTaskQuantity.ForNextWeek > 0;
		ToDoItem.Owner       = MyTasksID; 
	EndDo;
	
EndProcedure

// See JobsQueueOverridable.OnDefineHandlersAliases. 
Procedure OnDefineHandlerAliases(NameAndAliasMap) Export
	
	NameAndAliasMap.Insert("BusinessProcessesAndTasksEvents.StartDeferredProcesses");
	
EndProcedure

#EndRegion

#Region Private

////////////////////////////////////////////////////////////////////////////////
// Monitoring and management control of task completion.

Function ExportPerformers(QueryText, MainAddressingObjectRef, AdditionalAddressingObjectRef)
	
	Query = New Query(QueryText);
	
	If ValueIsFilled(AdditionalAddressingObjectRef) Then
		Query.SetParameter("AAO", AdditionalAddressingObjectRef);
	EndIf;
	
	If ValueIsFilled(MainAddressingObjectRef) Then
		Query.SetParameter("MAO", MainAddressingObjectRef);
	EndIf;
	
	Return Query.Execute().Unload();
	
EndFunction

Function FindPerformersByRoles(Val Task, Val BaseQueryText)
	
	UsersList = New Array;
	
	MAO = Task.MainAddressingObject;
	AAO = Task.AdditionalAddressingObject;
	
	If ValueIsFilled(AAO) Then
		QueryText = BaseQueryText + " AND TaskPerformers.MainAddressingObject = &MAO
		                                     |AND TaskPerformers.AdditionalAddressingObject = &AAO";
	ElsIf ValueIsFilled(MAO) Then
		QueryText = BaseQueryText 
			+ " AND TaskPerformers.MainAddressingObject = &MAO
		    |AND (TaskPerformers.AdditionalAddressingObject = VALUE(ChartOfCharacteristicTypes.TaskAddressingObjects.EmptyRef)
			|   OR TaskPerformers.AdditionalAddressingObject = Undefined)";
	Else
		QueryText = BaseQueryText 
			+ " AND (TaskPerformers.MainAddressingObject = VALUE(ChartOfCharacteristicTypes.TaskAddressingObjects.EmptyRef)
			|    OR TaskPerformers.MainAddressingObject = Undefined)
		    |AND (TaskPerformers.AdditionalAddressingObject = VALUE(ChartOfCharacteristicTypes.TaskAddressingObjects.EmptyRef)
			|   OR TaskPerformers.AdditionalAddressingObject = Undefined)";
	EndIf;
	
	RetrievedPerformerData = ExportPerformers(QueryText, MAO, AAO);
	
	// If the main and additional addressing objects are not specified in the task.
	If Not ValueIsFilled(AAO) AND Not ValueIsFilled(MAO) Then
		For Each RetrievedDataItem In RetrievedPerformerData Do
			UsersList.Add(RetrievedDataItem.Performer);
		EndDo;
		
		Return UsersList;
	EndIf;
	
	If RetrievedPerformerData.Count() = 0 AND ValueIsFilled(AAO) Then
		QueryText = BaseQueryText + " AND TaskPerformers.MainAddressingObject = &MAO
			|AND (TaskPerformers.AdditionalAddressingObject = VALUE(ChartOfCharacteristicTypes.TaskAddressingObjects.EmptyRef)
			|   OR TaskPerformers.AdditionalAddressingObject = Undefined)";
		RetrievedPerformerData = ExportPerformers(QueryText, MAO, Undefined);
	EndIf;
	
	If RetrievedPerformerData.Count() = 0 Then
		QueryText = BaseQueryText + " AND (TaskPerformers.MainAddressingObject = VALUE(ChartOfCharacteristicTypes.TaskAddressingObjects.EmptyRef)
			|    OR TaskPerformers.MainAddressingObject = Undefined)
			|AND (TaskPerformers.AdditionalAddressingObject = VALUE(ChartOfCharacteristicTypes.TaskAddressingObjects.EmptyRef)
			|   OR TaskPerformers.AdditionalAddressingObject = Undefined)";
		RetrievedPerformerData = ExportPerformers(QueryText, Undefined, Undefined);
	EndIf;
	
	For Each RetrievedDataItem In RetrievedPerformerData Do
		UsersList.Add(RetrievedDataItem.Performer);
	EndDo;
	
	Return UsersList;
	
EndFunction

Function FindPersonsResponsibleForRolesAssignment(Val Task)
	
	BaseQueryText = "SELECT DISTINCT ALLOWED TaskPerformers.Performer
	                      |FROM
	                      |	InformationRegister.TaskPerformers AS TaskPerformers, Catalog.PerformerRoles AS PerformerRoles
	                      |WHERE
	                      |	TaskPerformers.PerformerRole = PerformerRoles.Ref
	                      |AND
	                      |	PerformerRoles.Ref = VALUE(Catalog.PerformerRoles.EmployeeResponsibleForTasksManagement)";
						  
	ResponsiblePersons = FindPerformersByRoles(Task, BaseQueryText);
	Return ResponsiblePersons;
	
EndFunction

Function SelectTasksPerformers(Val Task)
	
	QueryText = "SELECT DISTINCT ALLOWED
				  |	TaskPerformers.Performer AS Performer
				  |FROM
				  |	InformationRegister.TaskPerformers AS TaskPerformers
				  |WHERE
				  |	TaskPerformers.PerformerRole = &PerformerRole
				  |	AND TaskPerformers.MainAddressingObject = &MainAddressingObject
				  |	AND TaskPerformers.AdditionalAddressingObject = &AdditionalAddressingObject";
				  
	Query = New Query(QueryText);
	Query.Parameters.Insert("PerformerRole", Task.PerformerRole);
	Query.Parameters.Insert("MainAddressingObject", Task.MainAddressingObject);
	Query.Parameters.Insert("AdditionalAddressingObject", Task.AdditionalAddressingObject);
	Performers = Query.Execute().Unload();
	Return Performers;
	
EndFunction

Procedure FindMessageAndAddText(Val MessageSetByAddressees,
                                  Val EmailRecipient,
                                  Val MessageRecipientPresentation,
                                  Val EmailText,
                                  Val EmailType)
	
	FilterParameters = New Structure("EmailType, MailAddress", EmailType, EmailRecipient);
	EmailParametersRow = MessageSetByAddressees.FindRows(FilterParameters);
	If EmailParametersRow.Count() = 0 Then
		EmailParametersRow = Undefined;
	Else
		EmailParametersRow = EmailParametersRow[0];
	EndIf;
	
	If EmailParametersRow = Undefined Then
		EmailParametersRow = MessageSetByAddressees.Add();
		EmailParametersRow.MailAddress = EmailRecipient;
		EmailParametersRow.EmailText = "";
		EmailParametersRow.TaskCount = 0;
		EmailParametersRow.EmailType = EmailType;
		EmailParametersRow.Recipient = MessageRecipientPresentation;
	EndIf;
	
	If ValueIsFilled(EmailParametersRow.EmailText) Then
		EmailParametersRow.EmailText =
		        EmailParametersRow.EmailText + Chars.LF
		        + "------------------------------------"  + Chars.LF;
	EndIf;
	
	EmailParametersRow.TaskCount = EmailParametersRow.TaskCount + 1;
	EmailParametersRow.EmailText = EmailParametersRow.EmailText + EmailText;
	
EndProcedure

Function SelectOverdueTasks()
	
	QueryText = 
		"SELECT ALLOWED
		|	PerformerTask.Ref AS Ref,
		|	PerformerTask.DueDate AS DueDate,
		|	PerformerTask.Performer AS Performer,
		|	PerformerTask.PerformerRole AS PerformerRole,
		|	PerformerTask.MainAddressingObject AS MainAddressingObject,
		|	PerformerTask.AdditionalAddressingObject AS AdditionalAddressingObject,
		|	PerformerTask.Author AS Author,
		|	PerformerTask.Details AS Details
		|FROM
		|	Task.PerformerTask AS PerformerTask
		|WHERE
		|	PerformerTask.DeletionMark = FALSE
		|	AND PerformerTask.Executed = FALSE
		|	AND PerformerTask.DueDate <= &Date
		|	AND PerformerTask.BusinessProcessState <> VALUE(Enum.BusinessProcessStates.Stopped)";
	
	DueDate = EndOfDay(CurrentSessionDate());

	Query = New Query;
	Query.Text = QueryText;
	Query.SetParameter("Date", DueDate);
	
	OverdueTasks = Query.Execute().Unload();
	
	Index = OverdueTasks.Count() - 1;
	While Index > 0 Do
		OverdueTask = OverdueTasks[Index];
		If NOT ValueIsFilled(OverdueTask.Performer) AND BusinessProcessesAndTasksServerCall.IsHeadTask(OverdueTask.Ref) Then
			OverdueTasks.Delete(OverdueTask);
		EndIf;
		Index = Index - 1;
	EndDo;
	
	Return OverdueTasks;
	
EndFunction

Function SelectOverdueTasksPerformers(OverdueTasks)
	
	MessageSetByAddressees = New ValueTable;
	MessageSetByAddressees.Columns.Add("MailAddress");
	MessageSetByAddressees.Columns.Add("EmailText");
	MessageSetByAddressees.Columns.Add("TaskCount");
	MessageSetByAddressees.Columns.Add("EmailType");
	MessageSetByAddressees.Columns.Add("Recipient");
	MessageSetByAddressees.Indexes.Add("EmailType, MailAddress");
	
	For Each OverdueTasksItem In OverdueTasks Do
		OverdueTask = OverdueTasksItem.Ref;
		
		EmailText = GenerateTaskPresentation(OverdueTasksItem);
		// Is the task addressed to the assignee personally?
		If ValueIsFilled(OverdueTask.Performer) Then
			EmailRecipient = EmailAddress(OverdueTask.Performer);
			FindMessageAndAddText(MessageSetByAddressees, EmailRecipient, OverdueTask.Performer, EmailText, "ToPerformer");
			EmailRecipient = EmailAddress(OverdueTask.Author);
			FindMessageAndAddText(MessageSetByAddressees, EmailRecipient, OverdueTask.Author, EmailText, "ToAuthor");
		Else
			Performers = SelectTasksPerformers(OverdueTask);
			Coordinators = FindPersonsResponsibleForRolesAssignment(OverdueTask);
			// Is there at least one assignee for the task role addressing dimensions?
			If Performers.Count() > 0 Then
				// The assignee does not execute the tasks.
				For Each Performer In Performers Do
					EmailRecipient = EmailAddress(Performer.Performer);
					FindMessageAndAddText(MessageSetByAddressees, EmailRecipient, Performer.Performer, EmailText, "ToPerformer");
				EndDo;
			Else	// There is no assignee to execute the task.
				CreateTaskForSettingRoles(OverdueTask, Coordinators);
			EndIf;
			
			For Each Coordinator In Coordinators Do
				EmailRecipient = EmailAddress(Coordinator);
				FindMessageAndAddText(MessageSetByAddressees, EmailRecipient, Coordinator, EmailText, "ToCoordinator");
			EndDo;
		EndIf;
	EndDo;
	
	Return MessageSetByAddressees;
	
EndFunction

Procedure SendNotificationAboutOverdueTasks(EmailFromSet)
	
	If IsBlankString(EmailFromSet.MailAddress) Then
		MessageText = StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = 'Уведомление не было отправлено, так как у пользователя %1 не задан адрес электронной почты.'; en = 'Cannot send the notification as user %1 does not have email address specified.'; pl = 'Cannot send the notification as user %1 does not have email address specified.';de = 'Cannot send the notification as user %1 does not have email address specified.';ro = 'Cannot send the notification as user %1 does not have email address specified.';tr = 'Cannot send the notification as user %1 does not have email address specified.'; es_ES = 'Cannot send the notification as user %1 does not have email address specified.'"), 
			EmailFromSet.Recipient);
		WriteLogEvent(NStr("ru = 'Бизнес-процессы и задачи.Уведомление о просроченных задачах'; en = 'Business processes and tasks.Overdue task notification'; pl = 'Business processes and tasks.Overdue task notification';de = 'Business processes and tasks.Overdue task notification';ro = 'Business processes and tasks.Overdue task notification';tr = 'Business processes and tasks.Overdue task notification'; es_ES = 'Business processes and tasks.Overdue task notification'", 
			Common.DefaultLanguageCode()),
			EventLogLevel.Information,,, MessageText);
		Return;
	EndIf;
	
	EmailParameters = New Structure;
	EmailParameters.Insert("SendTo", EmailFromSet.MailAddress);
	If EmailFromSet.EmailType = "ToPerformer" Then
		MessageBodyText = StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = 'Не выполненные в срок задачи:
			| 
			|%1'; 
			|en = 'Overdue tasks:
			|
			|%1'; 
			|pl = 'Overdue tasks:
			|
			|%1';
			|de = 'Overdue tasks:
			|
			|%1';
			|ro = 'Overdue tasks:
			|
			|%1';
			|tr = 'Overdue tasks:
			|
			|%1'; 
			|es_ES = 'Overdue tasks:
			|
			|%1'"), EmailFromSet.EmailText);
		EmailParameters.Insert("Body", MessageBodyText);
		
		EmailSubjectText = StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = 'Не выполненные в срок задачи (%1)'; en = 'Overdue tasks (%1)'; pl = 'Overdue tasks (%1)';de = 'Overdue tasks (%1)';ro = 'Overdue tasks (%1)';tr = 'Overdue tasks (%1)'; es_ES = 'Overdue tasks (%1)'"),
			String(EmailFromSet.TaskCount ));
		EmailParameters.Insert("Subject", EmailSubjectText);
	ElsIf EmailFromSet.EmailType = "ToAuthor" Then
		MessageBodyText = StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = 'По введенным задачам прошел крайний срок:
			| 
			|%1'; 
			|en = 'Deadline for specified tasks expired:
			|
			|%1'; 
			|pl = 'Deadline for specified tasks expired:
			|
			|%1';
			|de = 'Deadline for specified tasks expired:
			|
			|%1';
			|ro = 'Deadline for specified tasks expired:
			|
			|%1';
			|tr = 'Deadline for specified tasks expired:
			|
			|%1'; 
			|es_ES = 'Deadline for specified tasks expired:
			|
			|%1'"), EmailFromSet.EmailText);
		EmailParameters.Insert("Body", MessageBodyText);
		
		EmailSubjectText = StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = 'По задачам истек контрольный срок (%1)'; en = 'Task deadline expired (%1)'; pl = 'Task deadline expired (%1)';de = 'Task deadline expired (%1)';ro = 'Task deadline expired (%1)';tr = 'Task deadline expired (%1)'; es_ES = 'Task deadline expired (%1)'"),
			String(EmailFromSet.TaskCount));
		EmailParameters.Insert("Subject", EmailSubjectText);
	ElsIf EmailFromSet.EmailType = "ToCoordinator" Then
		MessageBodyText = StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = 'Прошел крайний срок по задачам:
			| 
			|%1'; 
			|en = 'Deadline for tasks has passed:
			| 
			|%1'; 
			|pl = 'Deadline for tasks has passed:
			| 
			|%1';
			|de = 'Deadline for tasks has passed:
			| 
			|%1';
			|ro = 'Deadline for tasks has passed:
			| 
			|%1';
			|tr = 'Deadline for tasks has passed:
			| 
			|%1'; 
			|es_ES = 'Deadline for tasks has passed:
			| 
			|%1'"), EmailFromSet.EmailText);
		EmailParameters.Insert("Body", MessageBodyText);
		
		EmailSubjectText = StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = 'Истек контрольный срок задач (%1)'; en = 'Deadline for tasks (%1) expired'; pl = 'Deadline for tasks (%1) expired';de = 'Deadline for tasks (%1) expired';ro = 'Deadline for tasks (%1) expired';tr = 'Deadline for tasks (%1) expired'; es_ES = 'Deadline for tasks (%1) expired'"),
			String(EmailFromSet.TaskCount));
		EmailParameters.Insert("Subject", EmailSubjectText);
	EndIf;
	
	MessageText = "";
	
	ModuleEmailOperations = Common.CommonModule("EmailOperations");
	Try
		ModuleEmailOperations.SendEmailMessage(
			ModuleEmailOperations.SystemAccount(), EmailParameters);
	Except
		ErrorDescription = DetailErrorDescription(ErrorInfo());
		MessageText = StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = 'Ошибка при отправке уведомления о просроченных задачах: %1.'; en = 'An error occurred when sending a notification about overdue tasks: %1.'; pl = 'An error occurred when sending a notification about overdue tasks: %1.';de = 'An error occurred when sending a notification about overdue tasks: %1.';ro = 'An error occurred when sending a notification about overdue tasks: %1.';tr = 'An error occurred when sending a notification about overdue tasks: %1.'; es_ES = 'An error occurred when sending a notification about overdue tasks: %1.'"),
			ErrorDescription);
		EventImportanceLevel = EventLogLevel.Error;
	EndTry;
	
	If IsBlankString(MessageText) Then
		If EmailParameters.SendTo.Count() > 0 Then
			SendTo = ? (IsBlankString(EmailParameters.SendTo[0].Presentation),
						EmailParameters.SendTo[0].Address,
						EmailParameters.SendTo[0].Presentation + " <" + EmailParameters.SendTo[0].Address + ">");
		EndIf;
		
		MessageText = StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = 'Уведомление о просроченных задачах успешно отправлено на адрес %1.'; en = 'Overdue task notification sent to %1.'; pl = 'Overdue task notification sent to %1.';de = 'Overdue task notification sent to %1.';ro = 'Overdue task notification sent to %1.';tr = 'Overdue task notification sent to %1.'; es_ES = 'Overdue task notification sent to %1.'"), SendTo);
		EventImportanceLevel = EventLogLevel.Information;
	EndIf;
	
	WriteLogEvent(NStr("ru = 'Бизнес-процессы и задачи.Уведомление о просроченных задачах'; en = 'Business processes and tasks.Overdue task notification'; pl = 'Business processes and tasks.Overdue task notification';de = 'Business processes and tasks.Overdue task notification';ro = 'Business processes and tasks.Overdue task notification';tr = 'Business processes and tasks.Overdue task notification'; es_ES = 'Business processes and tasks.Overdue task notification'",
		Common.DefaultLanguageCode()), 
		EventImportanceLevel,,, MessageText);
		
EndProcedure

Procedure CreateTaskForSettingRoles(TaskRef, EmployeesResponsible)
	
	For Each EmployeeResponsible In EmployeesResponsible Do
		TaskObject = Tasks.PerformerTask.CreateTask();
		TaskObject.Date = CurrentSessionDate();
		TaskObject.Importance = Enums.TaskImportanceOptions.High;
		TaskObject.Performer = EmployeeResponsible;
		TaskObject.Topic = TaskRef;

		TaskObject.Details = StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = 'Задача не может быть исполнена, так как у роли не задано ни одного исполнителя:
		    |%1'; 
		    |en = 'The task cannot be completed as no assignees are assigned for the role:
		    |%1'; 
		    |pl = 'The task cannot be completed as no assignees are assigned for the role:
		    |%1';
		    |de = 'The task cannot be completed as no assignees are assigned for the role:
		    |%1';
		    |ro = 'The task cannot be completed as no assignees are assigned for the role:
		    |%1';
		    |tr = 'The task cannot be completed as no assignees are assigned for the role:
		    |%1'; 
		    |es_ES = 'The task cannot be completed as no assignees are assigned for the role:
		    |%1'"), String(TaskRef));
		TaskObject.Description = StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = 'Назначить исполнителей: задача не может быть исполнена %1'; en = 'Set assignees: task %1 cannot be executed'; pl = 'Set assignees: task %1 cannot be executed';de = 'Set assignees: task %1 cannot be executed';ro = 'Set assignees: task %1 cannot be executed';tr = 'Set assignees: task %1 cannot be executed'; es_ES = 'Set assignees: task %1 cannot be executed'"), String(TaskRef));
		TaskObject.Write();
	EndDo;
	
EndProcedure

Function SelectNewTasksByPerformers(Val DateTimeFrom, Val DateTimeTo)
	
	Query = New Query(
		"SELECT ALLOWED
		|	PerformerTask.Ref AS Ref,
		|	PerformerTask.Number AS Number,
		|	PerformerTask.Date AS Date,
		|	PerformerTask.Description AS Description,
		|	PerformerTask.DueDate AS DueDate,
		|	PerformerTask.Author AS Author,
		|	PerformerTask.Details AS Details,
		|	CASE
		|		WHEN PerformerTask.Performer <> UNDEFINED
		|			THEN PerformerTask.Performer
		|		ELSE TaskPerformers.Performer
		|	END AS Performer,
		|	PerformerTask.PerformerRole AS PerformerRole,
		|	PerformerTask.MainAddressingObject AS MainAddressingObject,
		|	PerformerTask.AdditionalAddressingObject AS AdditionalAddressingObject
		|FROM
		|	Task.PerformerTask AS PerformerTask
		|		LEFT JOIN InformationRegister.TaskPerformers AS TaskPerformers
		|		ON PerformerTask.PerformerRole = TaskPerformers.PerformerRole
		|			AND PerformerTask.MainAddressingObject = TaskPerformers.MainAddressingObject
		|			AND PerformerTask.AdditionalAddressingObject = TaskPerformers.AdditionalAddressingObject
		|WHERE
		|	PerformerTask.Executed = FALSE
		|	AND PerformerTask.Date BETWEEN &DateTimeFrom AND &DateTimeTo
		|	AND PerformerTask.DeletionMark = FALSE
		|	AND (PerformerTask.Performer <> VALUE(Catalog.Users.EmptyRef)
		|			OR TaskPerformers.Performer IS NOT NULL 
		|		AND TaskPerformers.Performer <> VALUE(Catalog.Users.EmptyRef))
		|
		|ORDER BY
		|	Performer,
		|	DueDate DESC
		|TOTALS BY
		|	Performer");
	Query.Parameters.Insert("DateTimeFrom", DateTimeFrom + 1);
	Query.Parameters.Insert("DateTimeTo", DateTimeTo);
	Result = Query.Execute().Unload(QueryResultIteration.ByGroups);
	
	Return Result;
	
EndFunction

Function SendNotificationOnNewTasks(Performer, TasksByPerformer)
	
	RecipientEmailAddress = EmailAddress(Performer);
	If IsBlankString(RecipientEmailAddress) Then
		WriteLogEvent(NStr("ru = 'Бизнес-процессы и задачи.Уведомление о новых задачах'; en = 'Business processes and tasks.New task notification'; pl = 'Business processes and tasks.New task notification';de = 'Business processes and tasks.New task notification';ro = 'Business processes and tasks.New task notification';tr = 'Business processes and tasks.New task notification'; es_ES = 'Business processes and tasks.New task notification'",
			Common.DefaultLanguageCode()), 
			EventLogLevel.Information,,,
			StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = 'Уведомление не отправлено, так как не указан почтовый адрес у пользователя %1.'; en = 'Notification was not sent as the email address of user %1 is not specified.'; pl = 'Notification was not sent as the email address of user %1 is not specified.';de = 'Notification was not sent as the email address of user %1 is not specified.';ro = 'Notification was not sent as the email address of user %1 is not specified.';tr = 'Notification was not sent as the email address of user %1 is not specified.'; es_ES = 'Notification was not sent as the email address of user %1 is not specified.'"), String(Performer)));
		Return False;
	EndIf;
	
	EmailText = "";
	For Each Task In TasksByPerformer.Rows Do
		EmailText = EmailText + GenerateTaskPresentation(Task);
	EndDo;
	EmailSubject = StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = 'Направлены задачи - %1'; en = 'Tasks sent- %1'; pl = 'Tasks sent- %1';de = 'Tasks sent- %1';ro = 'Tasks sent- %1';tr = 'Tasks sent- %1'; es_ES = 'Tasks sent- %1'"), Metadata.BriefInformation);
	
	EmailParameters = New Structure;
	EmailParameters.Insert("Subject", EmailSubject);
	EmailParameters.Insert("Body", EmailText);
	EmailParameters.Insert("SendTo", RecipientEmailAddress);
	
	ModuleEmailOperations = Common.CommonModule("EmailOperations");
	Try 
		ModuleEmailOperations.SendEmailMessage(
			ModuleEmailOperations.SystemAccount(), EmailParameters);
	Except
		WriteLogEvent(NStr("ru = 'Бизнес-процессы и задачи.Уведомление о новых задачах'; en = 'Business processes and tasks.New task notification'; pl = 'Business processes and tasks.New task notification';de = 'Business processes and tasks.New task notification';ro = 'Business processes and tasks.New task notification';tr = 'Business processes and tasks.New task notification'; es_ES = 'Business processes and tasks.New task notification'",
			Common.DefaultLanguageCode()), 
			EventLogLevel.Error,,,
			StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = 'Ошибка при отправке уведомления о новых задачах: %1'; en = 'An error occurred when sending a notification about new tasks: %1'; pl = 'An error occurred when sending a notification about new tasks: %1';de = 'An error occurred when sending a notification about new tasks: %1';ro = 'An error occurred when sending a notification about new tasks: %1';tr = 'An error occurred when sending a notification about new tasks: %1'; es_ES = 'An error occurred when sending a notification about new tasks: %1'"), 
			   DetailErrorDescription(ErrorInfo())));
		Return False;
	EndTry;

	WriteLogEvent(NStr("ru = 'Бизнес-процессы и задачи.Уведомление о новых задачах'; en = 'Business processes and tasks.New task notification'; pl = 'Business processes and tasks.New task notification';de = 'Business processes and tasks.New task notification';ro = 'Business processes and tasks.New task notification';tr = 'Business processes and tasks.New task notification'; es_ES = 'Business processes and tasks.New task notification'",
		Common.DefaultLanguageCode()),
		EventLogLevel.Information,,,
		StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = 'Уведомления успешно отправлены на адрес %1.'; en = 'Notifications sent to %1.'; pl = 'Notifications sent to %1.';de = 'Notifications sent to %1.';ro = 'Notifications sent to %1.';tr = 'Notifications sent to %1.'; es_ES = 'Notifications sent to %1.'"), RecipientEmailAddress));
	Return True;	
		
EndFunction

Function GenerateTaskPresentation(TaskStructure)
	
	Result = StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = '%1
		|
		|Крайний срок: %2'; 
		|en = '%1
		|
		|Deadline: %2'; 
		|pl = '%1
		|
		|Deadline: %2';
		|de = '%1
		|
		|Deadline: %2';
		|ro = '%1
		|
		|Deadline: %2';
		|tr = '%1
		|
		|Deadline: %2'; 
		|es_ES = '%1
		|
		|Deadline: %2'") + Chars.LF,
		TaskStructure.Ref, 
		Format(TaskStructure.DueDate, "DLF=DD; DE='not set'"));
	If ValueIsFilled(TaskStructure.Performer) Then
		Result = Result + StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = 'Исполнитель: %1'; en = 'Assignee: %1'; pl = 'Assignee: %1';de = 'Assignee: %1';ro = 'Assignee: %1';tr = 'Assignee: %1'; es_ES = 'Assignee: %1'"), TaskStructure.Performer) + Chars.LF;
	EndIf;
	If ValueIsFilled(TaskStructure.PerformerRole) Then
		Result = Result + StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = 'Роль: %1'; en = 'Role: %1'; pl = 'Role: %1';de = 'Role: %1';ro = 'Role: %1';tr = 'Role: %1'; es_ES = 'Role: %1'"), TaskStructure.PerformerRole) + Chars.LF;
	EndIf;
	If ValueIsFilled(TaskStructure.MainAddressingObject) Then
		Result = Result + StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = 'Основной объект адресации: %1'; en = 'Main addressing object: %1'; pl = 'Main addressing object: %1';de = 'Main addressing object: %1';ro = 'Main addressing object: %1';tr = 'Main addressing object: %1'; es_ES = 'Main addressing object: %1'"), TaskStructure.MainAddressingObject) + Chars.LF;
	EndIf;
	If ValueIsFilled(TaskStructure.AdditionalAddressingObject) Then
		Result = Result + StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = 'Доп. объект адресации: %1'; en = 'Additional addressing object: %1'; pl = 'Additional addressing object: %1';de = 'Additional addressing object: %1';ro = 'Additional addressing object: %1';tr = 'Additional addressing object: %1'; es_ES = 'Additional addressing object: %1'"), TaskStructure.AdditionalAddressingObject) + Chars.LF;
	EndIf;
	If ValueIsFilled(TaskStructure.Author) Then
		Result = Result + StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = 'Автор: %1'; en = 'Author: %1'; pl = 'Author: %1';de = 'Author: %1';ro = 'Author: %1';tr = 'Author: %1'; es_ES = 'Author: %1'"), TaskStructure.Author) + Chars.LF;
	EndIf;
	If ValueIsFilled(TaskStructure.Details) Then
		Result = Result + Chars.LF + StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = '%1'; en = '%1'; pl = '%1';de = '%1';ro = '%1';tr = '%1'; es_ES = '%1'"), TaskStructure.Details) + Chars.LF;
	EndIf;
	Return Result + Chars.LF;
	
EndFunction

////////////////////////////////////////////////////////////////////////////////
// Auxiliary procedures and functions.

// The function is used to select the roles that can be assigned to MainAddressingObject and count 
// the list of assignments.
//
Function SelectRolesWithPerformerCount(MainAddressingObject) Export
	If MainAddressingObject <> Undefined Then
		QueryText = 
			"SELECT ALLOWED
			|	PerformerRoles.Ref AS RoleRef,
			|	PerformerRoles.Description AS Role,
			|	PerformerRoles.ExternalRole AS ExternalRole,
			|	PerformerRoles.MainAddressingObjectTypes AS MainAddressingObjectTypes,
			|	SUM(CASE
			|			WHEN TaskPerformers.PerformerRole <> VALUE(Catalog.PerformerRoles.EmptyRef) 
			|				AND TaskPerformers.PerformerRole IS NOT NULL 
			|				AND TaskPerformers.MainAddressingObject = &MainAddressingObject
			|				THEN 1
			|			ELSE 0
			|		END) AS Performers
			|FROM
			|	Catalog.PerformerRoles AS PerformerRoles
			|		LEFT JOIN InformationRegister.TaskPerformers AS TaskPerformers
			|		ON (TaskPerformers.PerformerRole = PerformerRoles.Ref)
			|WHERE
			|	PerformerRoles.DeletionMark = FALSE
			|	AND PerformerRoles.UsedByAddressingObjects = TRUE
			| GROUP BY
			|	PerformerRoles.Ref,
			|	TaskPerformers.PerformerRole, 
			|	PerformerRoles.ExternalRole,
			|	PerformerRoles.Description,
			|	PerformerRoles.MainAddressingObjectTypes";
	Else
		QueryText = 
			"SELECT ALLOWED
			|	PerformerRoles.Ref AS RoleRef,
			|	PerformerRoles.Description AS Role,
			|	PerformerRoles.ExternalRole AS ExternalRole,
			|	PerformerRoles.MainAddressingObjectTypes AS MainAddressingObjectTypes,
			|	SUM(CASE
			|			WHEN TaskPerformers.PerformerRole <> VALUE(Catalog.PerformerRoles.EmptyRef) 
			|				AND TaskPerformers.PerformerRole IS NOT NULL 
			|				AND (TaskPerformers.MainAddressingObject IS NULL 
			|					OR TaskPerformers.MainAddressingObject = Undefined)
			|				THEN 1
			|			ELSE 0
			|		END) AS Performers
			|FROM
			|	Catalog.PerformerRoles AS PerformerRoles
			|		LEFT JOIN InformationRegister.TaskPerformers AS TaskPerformers
			|		ON (TaskPerformers.PerformerRole = PerformerRoles.Ref)
			|WHERE
			|	PerformerRoles.DeletionMark = FALSE
			|	AND PerformerRoles.UsedWithoutAddressingObjects = TRUE
			| GROUP BY
			|	PerformerRoles.Ref,
			|	TaskPerformers.PerformerRole, 
			|	PerformerRoles.ExternalRole,
			|	PerformerRoles.Description, 
			|	PerformerRoles.MainAddressingObjectTypes";
	EndIf;		
	Query = New Query(QueryText);
	Query.Parameters.Insert("MainAddressingObject", MainAddressingObject);
	QuerySelection = Query.Execute().Select();
	Return QuerySelection;
	
EndFunction

// Checks if there is at least one assignee for the specified role.
//
// Result:
//   Boolean
//
Function HasRolePerformers(RoleReference, MainAddressingObject = Undefined,
	AdditionalAddressingObject = Undefined) Export
	
	QueryResult = ChooseRolePerformers(RoleReference, MainAddressingObject,
		AdditionalAddressingObject);
	Return NOT QueryResult.IsEmpty();	
	
EndFunction

Function ChooseRolePerformers(RoleReference, MainAddressingObject = Undefined,
	AdditionalAddressingObject = Undefined)
	
	QueryText = 
		"SELECT
	   |	TaskPerformers.Performer
	   |FROM
	   |	InformationRegister.TaskPerformers AS TaskPerformers
	   |WHERE
	   |	TaskPerformers.PerformerRole = &PerformerRole";
	If MainAddressingObject <> Undefined Then  
		QueryText = QueryText 
			+ "	AND TaskPerformers.MainAddressingObject = &MainAddressingObject";
	EndIf;		
	If AdditionalAddressingObject <> Undefined Then  
		QueryText = QueryText 
			+ "	AND TaskPerformers.AdditionalAddressingObject = &AdditionalAddressingObject";
	EndIf;		
	
	Query = New Query(QueryText);
	Query.Parameters.Insert("PerformerRole", RoleReference);
	Query.Parameters.Insert("MainAddressingObject", MainAddressingObject);
	Query.Parameters.Insert("AdditionalAddressingObject", AdditionalAddressingObject);
	QueryResult = Query.Execute();
	Return QueryResult;
	
EndFunction

// Selects any single assignee of PerformerRole in MainAddressingObject.
// 
Function SelectPerformer(MainAddressingObject, PerformerRole) Export
	
	Query = New Query(
		"SELECT ALLOWED TOP 1
		|	TaskPerformers.Performer AS Performer
		|FROM
		|	InformationRegister.TaskPerformers AS TaskPerformers
		|WHERE
		|	TaskPerformers.PerformerRole = &PerformerRole
		|	AND TaskPerformers.MainAddressingObject = &MainAddressingObject");
	Query.Parameters.Insert("MainAddressingObject", MainAddressingObject);
	Query.Parameters.Insert("PerformerRole", PerformerRole);
	QuerySelection = Query.Execute().Unload();
	Return ?(QuerySelection.Count() > 0, QuerySelection[0].Performer, Catalogs.Users.EmptyRef());
	
EndFunction	

Function SelectHeadTaskBusinessProcesses(TaskRef, ForChange = False) Export
	
	Iteration = 1;
	QueryText = "";
	For Each BusinessProcessMetadata In Metadata.BusinessProcesses Do
		
		If ForChange Then
			Lock = New DataLock;
			LockItem = Lock.Add(BusinessProcessMetadata.FullName());
			LockItem.SetValue("HeadTask", TaskRef);
			Lock.Lock();
		EndIf;
		
		If NOT IsBlankString(QueryText) Then
			QueryText = QueryText + "
				|
				|UNION ALL
				|";
				
		EndIf;
		QueryFragment = StringFunctionsClientServer.SubstituteParametersToString(
			"SELECT %3
			|	%1.Ref AS Ref
			|FROM
			|	%2 AS %1
			|WHERE
			|	%1.HeadTask = &HeadTask", 
			BusinessProcessMetadata.Name, BusinessProcessMetadata.FullName(),
			?(Iteration = 1, "ALLOWED", ""));
		QueryText = QueryText + QueryFragment;
		Iteration = Iteration + 1;
	EndDo;	
	
	Query = New Query(QueryText);
	Query.SetParameter("HeadTask", TaskRef);
	Result = Query.Execute();
	Return Result;
		
EndFunction	

// Returns the entry kind of the subsystem event log.
//
Function EventLogEvent() Export
	Return NStr("ru = 'Бизнес-процессы и задачи'; en = 'Business processes and tasks.'; pl = 'Business processes and tasks.';de = 'Business processes and tasks.';ro = 'Business processes and tasks.';tr = 'Business processes and tasks.'; es_ES = 'Business processes and tasks.'", Common.DefaultLanguageCode());
EndFunction

// The procedure is called when changing state of a business process. It is used to propagate the 
// state change to the uncompleted tasks of the business process.
// 
//
Procedure OnChangeBusinessProcessState(BusinessProcess, OldState, NewState) Export
	
	Query = New Query;
	Query.Text = 
		"SELECT
		|	PerformerTask.Ref AS Ref
		|FROM
		|	Task.PerformerTask AS PerformerTask
		|WHERE
		|	PerformerTask.BusinessProcess = &BusinessProcess
		|	AND PerformerTask.Executed = FALSE";

	Query.SetParameter("BusinessProcess", BusinessProcess.Ref);

	Result = Query.Execute();

	DetailedRecordsSelection = Result.Select();

	While DetailedRecordsSelection.Next() Do
		
		Task = DetailedRecordsSelection.Ref.GetObject();
		Task.Lock();
		Task.BusinessProcessState =  NewState;
		Task.Write();
		
		OnChangeTaskState(Task.Ref, OldState, NewState);
	EndDo;

EndProcedure

Procedure OnChangeTaskState(TaskRef, OldState, NewState)
	
	// Changing state of nested business processes.
	For each BusinessProcessMetadata In Metadata.BusinessProcesses Do
		
		If NOT AccessRight("Update", BusinessProcessMetadata) Then
		    Continue;
		EndIf;
		
		Query = New Query;
		Query.Text = 
			"SELECT ALLOWED
			|	BusinessProcesses.Ref AS Ref
			|FROM
			|	%1 AS BusinessProcesses
			|WHERE
			|   BusinessProcesses.HeadTask = &HeadTask
			|   AND BusinessProcesses.DeletionMark = FALSE
			| 	AND BusinessProcesses.Completed = FALSE";
			
		Query.Text = StringFunctionsClientServer.SubstituteParametersToString(Query.Text, BusinessProcessMetadata.FullName());
		Query.SetParameter("HeadTask", TaskRef);

		Result = Query.Execute();
		
		DetailedRecordsSelection = Result.Select();

		While DetailedRecordsSelection.Next() Do
			
			BusinessProcess = DetailedRecordsSelection.Ref.GetObject();
			BusinessProcess.State = NewState;
			BusinessProcess.Write();
			
		EndDo;
		
	EndDo;	
	
	// Changing state of subordinate business processes.
	For each BusinessProcessMetadata In Metadata.BusinessProcesses Do
		
		// Business processes are not required to have a main task.
		MainTaskAttribute = BusinessProcessMetadata.Attributes.Find("MainTask");
		If MainTaskAttribute = Undefined Then
			Continue;
		EndIf;	
			
		Query = New Query;
		Query.Text = 
			"SELECT ALLOWED
			|	BusinessProcesses.Ref AS Ref
			|FROM
			|	%1 AS BusinessProcesses
			|WHERE
			|   BusinessProcesses.MainTask = &MainTask
			|   AND BusinessProcesses.DeletionMark = FALSE
			| 	AND BusinessProcesses.Completed = FALSE";
			
		Query.Text = StringFunctionsClientServer.SubstituteParametersToString(Query.Text, BusinessProcessMetadata.FullName());
		Query.SetParameter("MainTask", TaskRef);

		Result = Query.Execute();
		
		DetailedRecordsSelection = Result.Select();

		While DetailedRecordsSelection.Next() Do
			
			BusinessProcess = DetailedRecordsSelection.Ref.GetObject();
			BusinessProcess.State = NewState;
			BusinessProcess.Write();
			
		EndDo;
		
	EndDo;	
	
EndProcedure

// Gets task assignee groups according to the new task assignee records.
//
// Parameters:
//  NewTasksPerformers  - ValueTable - data retrieved from the TaskPerformers information register 
//                           record set.
//
// Returns:
//   Array - with elements of the CatalogRef.TaskPerformersGroups type.
//
Function TaskPerformersGroups(NewTasksPerformers) Export
	
	FieldsNames = "PerformerRole, MainAddressingObject, AdditionalAddressingObject";
	
	Query = New Query;
	Query.SetParameter("NewRecords", NewTasksPerformers.Copy( , FieldsNames));
	Query.Text =
	"SELECT DISTINCT
	|	NewRecords.PerformerRole AS PerformerRole,
	|	NewRecords.MainAddressingObject AS MainAddressingObject,
	|	NewRecords.AdditionalAddressingObject AS AdditionalAddressingObject
	|INTO NewRecords
	|FROM
	|	&NewRecords AS NewRecords
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ISNULL(TaskPerformersGroups.Ref, VALUE(Catalog.TaskPerformersGroups.EmptyRef)) AS Ref,
	|	NewRecords.PerformerRole AS PerformerRole,
	|	NewRecords.MainAddressingObject AS MainAddressingObject,
	|	NewRecords.AdditionalAddressingObject AS AdditionalAddressingObject
	|FROM
	|	NewRecords AS NewRecords
	|		LEFT JOIN Catalog.TaskPerformersGroups AS TaskPerformersGroups
	|		ON NewRecords.PerformerRole = TaskPerformersGroups.PerformerRole
	|			AND NewRecords.MainAddressingObject = TaskPerformersGroups.MainAddressingObject
	|			AND NewRecords.AdditionalAddressingObject = TaskPerformersGroups.AdditionalAddressingObject";
	
	PerformersGroups = Query.Execute().Unload();
	
	PerformersGroupsFilter = New Structure(FieldsNames);
	TaskPerformersGroups = New Array;
	
	For each Record In NewTasksPerformers Do
		FillPropertyValues(PerformersGroupsFilter, Record);
		PerformersGroup = PerformersGroups.FindRows(PerformersGroupsFilter)[0];
		// It is necessary to update the reference in the found row.
		If NOT ValueIsFilled(PerformersGroup.Ref) Then
			// It is necessary to add a new assignee group.
			PerformersGroupObject = Catalogs.TaskPerformersGroups.CreateItem();
			FillPropertyValues(PerformersGroupObject, PerformersGroupsFilter);
			PerformersGroupObject.Write();
			PerformersGroup.Ref = PerformersGroupObject.Ref;
		EndIf;
		TaskPerformersGroups.Add(PerformersGroup.Ref);
	EndDo;
	
	Return TaskPerformersGroups;
	
EndFunction

// The procedure marks nested and subordinate business processes of TaskRef for deletion.
//
// Parameters:
//  TaskRef                 - TaskRef.PerformerTask.
//  DeletionMarkNewValue - Boolean.
//
Procedure OnMarkTaskForDeletion(TaskRef, DeletionMarkNewValue) Export
	
	TaskObject = TaskRef.Metadata();
	If DeletionMarkNewValue Then
		VerifyAccessRights("InteractiveSetDeletionMark", TaskObject);
	EndIf;
	If Not DeletionMarkNewValue Then
		VerifyAccessRights("InteractiveClearDeletionMark", TaskObject);
	EndIf;
	If TaskRef.IsEmpty() Then
		Return;
	EndIf;
	
	BeginTransaction();
	Try
		// Marking nested business processes.
		SetPrivilegedMode(True);
		SubBusinessProcesses = HeadTaskBusinessProcesses(TaskRef, True);
		SetPrivilegedMode(False);
		// Without privileged mode, with rights check.
		For Each SubBusinessProcess In SubBusinessProcesses Do
			BusinessProcessObject = SubBusinessProcess.GetObject();
			BusinessProcessObject.SetDeletionMark(DeletionMarkNewValue);
		EndDo;
		
		// Marking subordinate business processes.
		SubordinateBusinessProcesses = MainTaskBusinessProcesses(TaskRef, True);
		For Each SubordinateBusinessProcess In SubordinateBusinessProcesses Do
			BusinessProcessObject = SubordinateBusinessProcess.GetObject();
			BusinessProcessObject.Lock();
			BusinessProcessObject.SetDeletionMark(DeletionMarkNewValue);
		EndDo;
		
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;
	
EndProcedure

// Checks whether the user has sufficient rights to mark a business process as stopped or active.
// 
// 
// Parameters:
//  BusinessProcess - a reference to a business process.
//
// ReturnValue
//  True, if user has the rights, otherwise False.
//
Function HasRightsToStopBusinessProcess(BusinessProcess)
	
	HasRights = False;
	StandardProcessing = True;
	BusinessProcessesAndTasksOverridable.OnCheckStopBusinessProcessRights(BusinessProcess, HasRights, StandardProcessing);
	If Not StandardProcessing Then
		Return HasRights;
	EndIf;
	
	If Users.IsFullUser() Then
		Return True;
	EndIf;
	
	If BusinessProcess.Author = Users.CurrentUser() Then
		Return True;
	EndIf;
	
	Return HasRights;
	
EndFunction

Procedure SetMyTasksListParameters(List) Export
	
	CurrentSessionDate = CurrentSessionDate();
	Today = New StandardPeriod(StandardPeriodVariant.Today);
	ThisWeek = New StandardPeriod(StandardPeriodVariant.ThisWeek);
	NextWeek = New StandardPeriod(StandardPeriodVariant.NextWeek);
	
	List.Parameters.SetParameterValue("CurrentDate", CurrentSessionDate);
	List.Parameters.SetParameterValue("EndOfDay", Today.EndDate);
	List.Parameters.SetParameterValue("EndOfWeek", ThisWeek.EndDate);
	List.Parameters.SetParameterValue("EndOfNextWeek", NextWeek.EndDate);
	List.Parameters.SetParameterValue("Overdue", " " + NStr("ru = 'Просрочено'; en = 'Overdue'; pl = 'Overdue';de = 'Overdue';ro = 'Overdue';tr = 'Overdue'; es_ES = 'Overdue'")); // Inserting space for sorting.
	List.Parameters.SetParameterValue("Today", NStr("ru = 'В течение сегодня'; en = 'Today'; pl = 'Today';de = 'Today';ro = 'Today';tr = 'Today'; es_ES = 'Today'"));
	List.Parameters.SetParameterValue("ThisWeek", NStr("ru = 'До конца недели'; en = 'Till the end of the week'; pl = 'Till the end of the week';de = 'Till the end of the week';ro = 'Till the end of the week';tr = 'Till the end of the week'; es_ES = 'Till the end of the week'"));
	List.Parameters.SetParameterValue("NextWeek", NStr("ru = 'На следующей неделе'; en = 'Next week'; pl = 'Next week';de = 'Next week';ro = 'Next week';tr = 'Next week'; es_ES = 'Next week'"));
	List.Parameters.SetParameterValue("Later", NStr("ru = 'Позднее'; en = 'Later'; pl = 'Later';de = 'Later';ro = 'Later';tr = 'Later'; es_ES = 'Later'"));
	List.Parameters.SetParameterValue("BegOfDay", BegOfDay(CurrentSessionDate));
	List.Parameters.SetParameterValue("BlankDate", Date(1,1,1));
	
EndProcedure

Function PerformerTaskQuantity()
	
	Query = New Query;
	Query.Text = "SELECT ALLOWED
	|	TasksByExecutive.Ref AS Ref,
	|	TasksByExecutive.DueDate AS DueDate
	|INTO UserBusinessProcesses
	|FROM
	|	Task.PerformerTask.TasksByExecutive AS TasksByExecutive
	|WHERE
	|	NOT TasksByExecutive.DeletionMark
	|	AND NOT TasksByExecutive.Executed
	|	AND TasksByExecutive.BusinessProcessState = VALUE(Enum.BusinessProcessStates.Active)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	COUNT(UserBusinessProcesses.Ref) AS Count
	|FROM
	|	UserBusinessProcesses AS UserBusinessProcesses
	|
	|UNION ALL
	|
	|SELECT
	|	COUNT(UserBusinessProcesses.Ref)
	|FROM
	|	UserBusinessProcesses AS UserBusinessProcesses
	|WHERE
	|	UserBusinessProcesses.DueDate <> DATETIME(1, 1, 1)
	|	AND UserBusinessProcesses.DueDate <= &CurrentDate
	|
	|UNION ALL
	|
	|SELECT
	|	COUNT(UserBusinessProcesses.Ref)
	|FROM
	|	UserBusinessProcesses AS UserBusinessProcesses
	|WHERE
	|	UserBusinessProcesses.DueDate > &CurrentDate
	|	AND UserBusinessProcesses.DueDate <= &Today
	|
	|UNION ALL
	|
	|SELECT
	|	COUNT(UserBusinessProcesses.Ref)
	|FROM
	|	UserBusinessProcesses AS UserBusinessProcesses
	|WHERE
	|	UserBusinessProcesses.DueDate > &Today
	|	AND UserBusinessProcesses.DueDate <= &EndOfWeek
	|
	|UNION ALL
	|
	|SELECT
	|	COUNT(UserBusinessProcesses.Ref)
	|FROM
	|	UserBusinessProcesses AS UserBusinessProcesses
	|WHERE
	|	UserBusinessProcesses.DueDate > &EndOfWeek
	|	AND UserBusinessProcesses.DueDate <= &EndOfNextWeek";
	
	Today = New StandardPeriod(StandardPeriodVariant.Today);
	ThisWeek = New StandardPeriod(StandardPeriodVariant.ThisWeek);
	NextWeek = New StandardPeriod(StandardPeriodVariant.NextWeek);
	
	Query.SetParameter("CurrentDate", CurrentSessionDate());
	Query.SetParameter("Today", Today.EndDate);
	Query.SetParameter("EndOfWeek", ThisWeek.EndDate);
	Query.SetParameter("EndOfNextWeek", NextWeek.EndDate);
	QueryResult = Query.Execute().Unload();
	
	Result = New Structure("Total,Overdue,ForToday,ForWeek,ForNextWeek");
	Result.Total = QueryResult[0].Count;
	Result.Overdue = QueryResult[1].Count;
	Result.ForToday = QueryResult[2].Count;
	Result.ForWeek = QueryResult[3].Count;
	Result.ForNextWeek = QueryResult[4].Count;
	
	Return Result;
	
EndFunction

////////////////////////////////////////////////////////////////////////////////
// Updating an infobase.

// Initializes EmployeeResponsibleForTasksManagement predefined assignee role.
// 
Procedure FillEmployeeResponsibleForCompletionControl() Export
	
	AllAddressingObjects = ChartsOfCharacteristicTypes.TaskAddressingObjects.AllAddressingObjects;
	
	RoleObject = Catalogs.PerformerRoles.EmployeeResponsibleForTasksManagement.GetObject();
	LockDataForEdit(RoleObject.Ref);
	RoleObject.Description = NStr("ru='Координатор выполнения задач'; en = 'Task control manager'; pl = 'Task control manager';de = 'Task control manager';ro = 'Task control manager';tr = 'Task control manager'; es_ES = 'Task control manager'");
	RoleObject.UsedWithoutAddressingObjects = True;
	RoleObject.UsedByAddressingObjects = True;
	RoleObject.MainAddressingObjectTypes = AllAddressingObjects;
	InfobaseUpdate.WriteObject(RoleObject);
	
EndProcedure

// Initializes the new State field for the business processes that possess it.
// 
Procedure FillStatesAndAcceptedFlags() Export
	
	// Updating the states of business processes and tasks.
	For each BusinessProcessMetadata In Metadata.BusinessProcesses Do
		
		AttributeState = BusinessProcessMetadata.Attributes.Find("State");
		If AttributeState = Undefined Then
			Continue;
		EndIf;	
			
		Query = New Query;
		Query.Text = 
			"SELECT 
			|	BusinessProcesses.Ref AS Ref
			|FROM
			|	%1 AS BusinessProcesses";
			
		Query.Text = StringFunctionsClientServer.SubstituteParametersToString(Query.Text, BusinessProcessMetadata.FullName());

		Result = Query.Execute();
		
		DetailedRecordsSelection = Result.Select();

		While DetailedRecordsSelection.Next() Do
			
			BusinessProcess = DetailedRecordsSelection.Ref.GetObject();
			BusinessProcess.Lock();
			BusinessProcess.State = Enums.BusinessProcessStates.Active;
			InfobaseUpdate.WriteData(BusinessProcess);
			
		EndDo;
		
	EndDo;
	
	// Updating the property that marks tasks as "accepted for execution".
	Query = New Query;
	Query.Text = 
		"SELECT 
		|	Tasks.Ref AS Ref
		|FROM
		|	Task.PerformerTask AS Tasks";
		
	Result = Query.Execute();
	
	DetailedRecordsSelection = Result.Select();

	While DetailedRecordsSelection.Next() Do
		
		TaskObject = DetailedRecordsSelection.Ref.GetObject();
		
		If TaskObject.Executed = True Then
			TaskObject.AcceptedForExecution = True;
			TaskObject.AcceptForExecutionDate = TaskObject.CompletionDate;
		EndIf;
		
		TaskObject.BusinessProcessState = Enums.BusinessProcessStates.Active;
		
		InfobaseUpdate.WriteData(TaskObject);
		
	EndDo;
	
EndProcedure	

// Fills in a new SubjectAsString field in PerformerTask.
// 
Procedure FillSubjectFromString() Export
	
	Query = New Query;
	Query.Text = 
		"SELECT
		|	PerformerTask.Ref AS Ref,
		|	PerformerTask.Topic AS Topic
		|FROM
		|	Task.PerformerTask AS PerformerTask";

	Result = Query.Execute();
	DetailedRecordsSelection = Result.Select();
	While DetailedRecordsSelection.Next() Do
		
		SubjectRef = DetailedRecordsSelection.Topic;
		If SubjectRef = Undefined OR SubjectRef.IsEmpty() Then
			Continue;	
		EndIf;	
		
		TaskObject = DetailedRecordsSelection.Ref.GetObject();
		TaskObject.SubjectString = Common.SubjectString(SubjectRef);
		InfobaseUpdate.WriteData(TaskObject);
		
	EndDo;

EndProcedure

// Transfers data from the standard Code attribute to the new BriefPresentation attribute.
// 
Procedure FillPerformerRoleCode() Export
	
	Query = New Query;
	Query.Text = 
		"SELECT
		|	PerformerRoles.Ref AS Ref,
		|	PerformerRoles.Code AS Code
		|FROM
		|	Catalog.PerformerRoles AS PerformerRoles";

	Result = Query.Execute();
	DetailedRecordsSelection = Result.Select();
	While DetailedRecordsSelection.Next() Do
		
		CodeValue = DetailedRecordsSelection.Code;
		If IsBlankString(CodeValue) Then
			Continue;
		EndIf;
		
		PerformersRoleObject = DetailedRecordsSelection.Ref.GetObject();
		PerformersRoleObject.BriefPresentation = CodeValue;
		InfobaseUpdate.WriteData(PerformersRoleObject);
		
	EndDo;

EndProcedure

// Returns the Recipient user email address for mailing task notifications.
//
// Parameters:
//  Recipient  - CatalogRef.Users, CatalogRef.ExternalUsers - a task assignee.
//  Address       - String - email address to be returned.
//
//
Function EmailAddress(Recipient)
	
	Address = "";
	
	If Common.SubsystemExists("StandardSubsystems.ContactInformation") Then
		ModuleContactsManager = Common.CommonModule("ContactsManager");
		If TypeOf(Recipient) = Type("CatalogRef.Users") Then
			Address = ModuleContactsManager.ObjectContactInformation(
				Recipient, ModuleContactsManager.ContactInformationKindByName("UserEmail"));
		ElsIf TypeOf(Recipient) = Type("CatalogRef.ExternalUsers") Then
			Address = ExternalUserEmail(Recipient);
		EndIf;
	EndIf;
	
	Return Address;
	
EndFunction

Function ExternalUserEmail(Recipient)
	
	If Common.SubsystemExists("StandardSubsystems.ContactInformation") Then
		
		ModuleContactsManagerInternal = Common.CommonModule("ContactsManagerInternal");
		ModuleContactsManager = Common.CommonModule("ContactsManager");
		ContactInformationType = ModuleContactsManager.ContactInformationTypeByDescription("EmailAddress");
		
		Return ModuleContactsManagerInternal.FirstValueOfObjectContactsByType(
			Recipient.AuthorizationObject, ContactInformationType, CurrentSessionDate());
			
	EndIf;
	
	Return "";
	
EndFunction

Function SystemEmailAccountIsSetUp(ErrorDescription)
	
	If Not Common.SubsystemExists("StandardSubsystems.EmailOperations") Then
		ErrorDescription = NStr("ru = 'Отправка почты не предусмотрена в программе.'; en = 'Email sending is not available in the application.'; pl = 'Email sending is not available in the application.';de = 'Email sending is not available in the application.';ro = 'Email sending is not available in the application.';tr = 'Email sending is not available in the application.'; es_ES = 'Email sending is not available in the application.'");
	Else
		ModuleEmailOperations = Common.CommonModule("EmailOperations");
		If ModuleEmailOperations.AccountSetUp(ModuleEmailOperations.SystemAccount(), True, False) Then
			Return True;
		EndIf;
		ErrorDescription = NStr("ru = 'Системная учетная запись электронной почты не настроена для отправки.'; en = 'System email account is not configured for sending.'; pl = 'System email account is not configured for sending.';de = 'System email account is not configured for sending.';ro = 'System email account is not configured for sending.';tr = 'System email account is not configured for sending.'; es_ES = 'System email account is not configured for sending.'");
	EndIf;
	
	Return False;
EndFunction

// [2.3.3.70] Updates the DeferredProcessesStart scheduled job.
Procedure UpdateScheduledJobUsage() Export
	
	SearchParameters = New Structure;
	SearchParameters.Insert("Metadata", Metadata.ScheduledJobs.StartDeferredProcesses);
	JobsList = ScheduledJobsServer.FindJobs(SearchParameters);
	
	JobParameters = New Structure("Use", GetFunctionalOption("UseBusinessProcessesAndTasks"));
	For Each Job In JobsList Do
		ScheduledJobsServer.ChangeJob(Job, JobParameters);
	EndDo;
	
EndProcedure

// Called upon migration to configuration version 3.0.2.131 and initial filling.
// 
Procedure FillPredefinedItemDescriptionAllAddressingObjects() Export
	
	AllAddressingObjects = ChartsOfCharacteristicTypes.TaskAddressingObjects.AllAddressingObjects.GetObject();
	AllAddressingObjects.Description = NStr("ru='Все объекты адресации'; en = 'All addressing objects'; pl = 'All addressing objects';de = 'All addressing objects';ro = 'All addressing objects';tr = 'All addressing objects'; es_ES = 'All addressing objects'");
	InfobaseUpdate.WriteObject(AllAddressingObjects);
	
EndProcedure

#EndRegion
