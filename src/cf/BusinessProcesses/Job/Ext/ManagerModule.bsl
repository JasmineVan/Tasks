///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

#Region ForCallsFromOtherSubsystems

// StandardSubsystems.BatchObjectsModification

// Returns object attributes allowed to be edited using batch attribute change data processor.
// 
//
// Returns:
//  Array - a list of object attribute names.
Function AttributesToEditInBatchProcessing() Export
	
	Result = New Array;
	Result.Add("Author");
	Result.Add("Importance");
	Result.Add("Performer");
	Result.Add("CheckExecution");
	Result.Add("Supervisor");
	Result.Add("DueDate");
	Result.Add("VerificationDueDate");
	Return Result;
	
EndFunction

// End StandardSubsystems.BatchObjectsModification

// StandardSubsystems.BusinessProcessesAndTasks

// Gets a structure with description of a task execution form.
// The function is called when opening the task execution form.
//
// Parameters:
//   TaskRef                - TaskRef.PerformerTask - a task.
//   BusinessProcessRoutePoint - BusinessProcessRoutePointRef - a route point.
//
// Returns:
//   Structure   - a structure with description of the task execution form.
//                 Key FormName contains the form name that is passed to the OpenForm() context method.
//                 Key FormOptions contains the form parameters.
//
Function TaskExecutionForm(TaskRef, BusinessProcessRoutePoint) Export
	
	Result = New Structure;
	Result.Insert("FormParameters", New Structure("Key", TaskRef));
	Result.Insert("FormName", "BusinessProcess.Job.Form.Action" + BusinessProcessRoutePoint.Name);
	Return Result;
	
EndFunction

// The function is called when forwarding a task.
//
// Parameters:
//   TaskRef  - TaskRef.PerformerTask - a forwarded task.
//   NewTaskRef  - TaskRef.PerformerTask - a task for a new assignee.
//
Procedure OnForwardTask(TaskRef, NewTaskRef) Export
	
	BusinessProcessObject = TaskRef.BusinessProcess.GetObject();
	LockDataForEdit(BusinessProcessObject.Ref);
	BusinessProcessObject.ExecutionResult = ExecutionResultOnForward(TaskRef) 
		+ BusinessProcessObject.ExecutionResult;
	SetPrivilegedMode(True);
	BusinessProcessObject.Write();
	
EndProcedure

// The function is called when a task is executed from a list form.
//
// Parameters:
//   TaskRef  - TaskRef.PerformerTask - a task.
//   BusinessProcessRef - BusinessProcessRef - a business process for which the TaskRef task is generated.
//   BusinessProcessRoutePoint - BusinessProcessRoutePointRef - a route point.
//
Procedure DefaultCompletionHandler(TaskRef, BusinessProcessRef, BusinessProcessRoutePoint) Export
	
	// Setting default values for batch task execution.
	If BusinessProcessRoutePoint = BusinessProcesses.Job.RoutePoints.Execute Then
		SetPrivilegedMode(True);
		JobObject = BusinessProcessRef.GetObject();
		LockDataForEdit(JobObject.Ref);
		JobObject.Completed = True;	
		JobObject.Write();
	ElsIf BusinessProcessRoutePoint = BusinessProcesses.Job.RoutePoints.Validate Then
		SetPrivilegedMode(True);
		JobObject = BusinessProcessRef.GetObject();
		LockDataForEdit(JobObject.Ref);
		JobObject.Completed = True;
		JobObject.Confirmed = True;
		JobObject.Write();
	EndIf;
	
EndProcedure	

// End StandardSubsystems.BusinessProcessesAndTasks

// StandardSubsystems.AccessManagement

// See AccessManagementOverridable.OnFillListsWithAccessRestriction. 
Procedure OnFillAccessRestriction(Restriction) Export
	
	Restriction.Text =
	"AttachAdditionalTables
	|ThisList AS Job
	|
	|LEFT JOIN InformationRegister.TaskPerformers AS TaskPerformers
	|ON
	|	TaskPerformers.PerformerRole = Job.Performer
	|	AND TaskPerformers.MainAddressingObject = Job.MainAddressingObject
	|	AND TaskPerformers.AdditionalAddressingObject = Job.AdditionalAddressingObject
	|
	|LEFT JOIN InformationRegister.TaskPerformers AS TaskSupervisors
	|ON
	|	TaskSupervisors.PerformerRole = Job.Supervisor
	|	AND TaskSupervisors.MainAddressingObject = Job.MainAddressingObjectSupervisor
	|	AND TaskSupervisors.AdditionalAddressingObject = Job.AdditionalAddressingObjectSupervisor
	|;
	|AllowRead
	|WHERE
	|	ValueAllowed(Author)
	|	OR ValueAllowed(Performer EXCEPT Catalog.PerformerRoles)
	|	OR ValueAllowed(TaskPerformers.Performer)
	|	OR ValueAllowed(Supervisor EXCEPT Catalog.PerformerRoles)
	|	OR ValueAllowed(TaskSupervisors.Performer)
	|;
	|AllowUpdateIfReadingAllowed
	|WHERE
	|	ValueAllowed(Author)";
	
EndProcedure

// End StandardSubsystems.AccessManagement

#EndRegion

#EndRegion

#EndIf

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Private

////////////////////////////////////////////////////////////////////////////////
// Update handlers

// Registers the objects to be updated to the latest version in the InfobaseUpdate exchange plan.
// 
//
Procedure RegisterDataToProcessForMigrationToNewVersion(Parameters) Export
	
	Query = New Query;
	Query.Text =
		"SELECT
		|	TableWithAccessValueSets.Ref
		|FROM
		|	%1 AS TableWithAccessValueSets
		|ORDER BY
		|	TableWithAccessValueSets.Date DESC";
	
	Query.Text = StringFunctionsClientServer.SubstituteParametersToString(Query.Text, Metadata.BusinessProcesses.Job.FullName());
	RefsArray = Query.Execute().Unload().UnloadColumn("Ref");
	
	InfobaseUpdate.MarkForProcessing(Parameters, RefsArray);
	
EndProcedure

Procedure ProcessDataForMigrationToNewVersion(Parameters) Export
	
	BusinessProcess = Metadata.BusinessProcesses.Job;
	ProcedureName = "BusinessProcesses.Job.ProcessDataForMigrationToNewVersion";
	
	ObjectsWithIssuesCount = 0;
	ObjectsProcessed = 0;
	
	Job = InfobaseUpdate.SelectRefsToProcess(Parameters.Queue, "BusinessProcess.Job");
	
	While Job.Next() Do
		Try
			RefreshJobAccessValuesSets(Parameters, Job.Ref);
			ObjectsProcessed = ObjectsProcessed + 1;
		Except
			// If a job cannot be processed, trying again.
			ObjectsWithIssuesCount = ObjectsWithIssuesCount + 1;
			
			MessageText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'Не удалось обновить права доступа для ""%1"" в обработчике ""%2"" по причине:
					|%3'; 
					|en = 'Cannot update access rights for ""%1"" in handler ""%2"" due to:
					|%3'; 
					|pl = 'Cannot update access rights for ""%1"" in handler ""%2"" due to:
					|%3';
					|de = 'Cannot update access rights for ""%1"" in handler ""%2"" due to:
					|%3';
					|ro = 'Cannot update access rights for ""%1"" in handler ""%2"" due to:
					|%3';
					|tr = 'Cannot update access rights for ""%1"" in handler ""%2"" due to:
					|%3'; 
					|es_ES = 'Cannot update access rights for ""%1"" in handler ""%2"" due to:
					|%3'"), 
					Job.Ref, ProcedureName, DetailErrorDescription(ErrorInfo()));
			WriteLogEvent(InfobaseUpdate.EventLogEvent(), EventLogLevel.Warning,
				BusinessProcess, Job.Ref, MessageText);
		EndTry;
	EndDo;
	
	Parameters.ProcessingCompleted = InfobaseUpdate.DataProcessingCompleted(Parameters.Queue, "BusinessProcess.Job");
	If ObjectsProcessed = 0 AND ObjectsWithIssuesCount <> 0 Then
		MessageText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Процедуре ""%1"" не удалось обновить права доступа для некоторых объектов (пропущены): %2'; en = 'The ""%1"" procedure cannot update access rights for some objects (skipped): %2'; pl = 'The ""%1"" procedure cannot update access rights for some objects (skipped): %2';de = 'The ""%1"" procedure cannot update access rights for some objects (skipped): %2';ro = 'The ""%1"" procedure cannot update access rights for some objects (skipped): %2';tr = 'The ""%1"" procedure cannot update access rights for some objects (skipped): %2'; es_ES = 'The ""%1"" procedure cannot update access rights for some objects (skipped): %2'"),
				ProcedureName, ObjectsWithIssuesCount);
		Raise MessageText;
	EndIf;
	
	WriteLogEvent(InfobaseUpdate.EventLogEvent(), EventLogLevel.Information,
	BusinessProcess,, StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = 'Процедура ""%1"" обновила права доступа для очередной порции объектов: %2'; en = 'The ""%1"" procedure has updated access rights for objects: %2'; pl = 'The ""%1"" procedure has updated access rights for objects: %2';de = 'The ""%1"" procedure has updated access rights for objects: %2';ro = 'The ""%1"" procedure has updated access rights for objects: %2';tr = 'The ""%1"" procedure has updated access rights for objects: %2'; es_ES = 'The ""%1"" procedure has updated access rights for objects: %2'"), 
		ProcedureName, ObjectsProcessed));
	
EndProcedure

Procedure RefreshJobAccessValuesSets(Parameters, JobReference) 
	
	ModuleAccessManagement = Common.CommonModule("AccessManagement");
	BeginTransaction();
	
	Try
		// Locking the object for changes by other sessions.
		Lock = New DataLock;
		LockItem = Lock.Add("BusinessProcess.Job");
		LockItem.SetValue("Ref", JobReference);
		Lock.Lock();
		
		JobObject = JobReference.GetObject();
		If JobObject = Undefined
			Or JobObject.TaskPerformersGroup <> Catalogs.TaskPerformersGroups.EmptyRef() Then
			RollbackTransaction();
			InfobaseUpdate.MarkProcessingCompletion(JobReference);
			Return;
		EndIf;
		
		JobObject.TaskPerformersGroup = ?(TypeOf(JobObject.Performer) = Type("CatalogRef.PerformerRoles"), 
			BusinessProcessesAndTasksServer.TaskPerformersGroup(JobObject.Performer, 
			JobObject.MainAddressingObject, JobObject.AdditionalAddressingObject), 
			JobObject.Performer);
		JobObject.TaskPerformersGroupSupervisor = ?(TypeOf(JobObject.Supervisor) = Type("CatalogRef.PerformerRoles"), 
			BusinessProcessesAndTasksServer.TaskPerformersGroup(JobObject.Supervisor, 
				JobObject.MainAddressingObjectSupervisor, JobObject.AdditionalAddressingObjectSupervisor), 
			JobObject.Supervisor);
		
		ModuleAccessManagement.UpdateAccessValuesSets(JobObject);
		If JobObject.Modified() Then
			InfobaseUpdate.WriteData(JobObject);
		Else
			InfobaseUpdate.MarkProcessingCompletion(JobReference);
		EndIf;
		
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;
		
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Other

// Sets the state of the task form items.
Procedure SetTaskFormItemsState(Form) Export
	
	If Form.Items.Find("ExecutionResult") <> Undefined 
		AND Form.Items.Find("ExecutionHistory") <> Undefined Then
			Form.Items.ExecutionHistory.Picture = CommonClientServer.CommentPicture(Form.JobExecutionResult);
	EndIf;
	
	Form.Items.Topic.Hyperlink = Form.Object.Topic <> Undefined AND NOT Form.Object.Topic.IsEmpty();
	Form.SubjectString = Common.SubjectString(Form.Object.Topic);	
	
EndProcedure	

Function ExecutionResultOnForward(Val TaskRef)
	
	StringFormat = "%1, %2 " + NStr("ru = 'перенаправил(а) задачу'; en = 'redirected the task'; pl = 'redirected the task';de = 'redirected the task';ro = 'redirected the task';tr = 'redirected the task'; es_ES = 'redirected the task'") + ":
		|%3
		|";
	
	Comment = TrimAll(TaskRef.ExecutionResult);
	Comment = ?(IsBlankString(Comment), "", Comment + Chars.LF);
	Result = StringFunctionsClientServer.SubstituteParametersToString(StringFormat, TaskRef.CompletionDate, TaskRef.Performer, Comment);
	Return Result;

EndFunction

#EndRegion

#EndIf