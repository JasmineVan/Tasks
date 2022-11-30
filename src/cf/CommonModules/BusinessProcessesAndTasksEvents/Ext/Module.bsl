///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Private

////////////////////////////////////////////////////////////////////////////////
// Subsystem event subscription handlers.

// The WriteToBusinessProcessesList event subscription handler.
//
Procedure WriteToBusinessProcessesList(Source, Cancel) Export
	
	If Source.DataExchange.Load Then 
        Return;  
	EndIf; 
	
	RecordSet = InformationRegisters.BusinessProcessesData.CreateRecordSet();
	RecordSet.Filter.BusinessProcess.Value = Source.Ref;
	RecordSet.Filter.BusinessProcess.Use = True;
	Record = RecordSet.Add();
	Record.BusinessProcess = Source.Ref;
	FieldsList = "Number,Date,Completed,Started,Author,CompletedOn,Description,DeletionMark";
	FillPropertyValues(Record, Source, FieldsList);
	
	BusinessProcessesAndTasksOverridable.OnWriteBusinessProcessesList(Record);
	
	SetPrivilegedMode(True);
	RecordSet.Write();

EndProcedure

// MarkTasksForDeletion event subscription handler.
//
Procedure MarkTasksForDeletion(Source, Cancel) Export
	
	If Source.DataExchange.Load Then 
        Return;  
	EndIf; 
	
	If Source.IsNew() Then 
        Return;  
	EndIf; 
	
	PreviousDeletionMark = Common.ObjectAttributeValue(Source.Ref, "DeletionMark");
	If Source.DeletionMark <> PreviousDeletionMark Then
		SetPrivilegedMode(True);
		BusinessProcessesAndTasksServer.MarkTasksForDeletion(Source.Ref, Source.DeletionMark);
	EndIf;	
	
EndProcedure

// The UpdateBusinessProcessState event subscription handler.
//
Procedure UpdateBusinessProcessState(Source, Cancel) Export
	
	If Source.DataExchange.Load Then 
        Return;  
	EndIf; 
	
	If Source.Metadata().Attributes.Find("State") = Undefined Then
		Return;
	EndIf;	
	
	If Not Source.IsNew() Then
		NewState = Source.State;
		OldState = Common.ObjectAttributeValue(Source.Ref, "State");
		If NewState <> OldState Then
			BusinessProcessesAndTasksServer.OnChangeBusinessProcessState(Source, OldState, NewState);
		EndIf;
	EndIf;	
	
EndProcedure

// The DeferredProcessesStart scheduled job handler.
//
Procedure StartDeferredProcesses() Export
	
	Common.OnStartExecuteScheduledJob(Metadata.ScheduledJobs.StartDeferredProcesses);
	
	SetPrivilegedMode(True);
	
	Query = New Query;
	Query.Text = 
		"SELECT
		|	ProcessesToStart.BusinessProcess AS BusinessProcess
		|FROM
		|	InformationRegister.ProcessesToStart AS ProcessesToStart
		|		INNER JOIN InformationRegister.BusinessProcessesData AS BusinessProcessesData
		|		ON ProcessesToStart.BusinessProcess = BusinessProcessesData.BusinessProcess
		|WHERE
		|	ProcessesToStart.State = VALUE(Enum.ProcessesStatesForStart.ReadyToStart)
		|	AND ProcessesToStart.DeferredStartDate <= &CurrentDate
		|	AND ProcessesToStart.DeferredStartDate <> DATETIME(1, 1, 1)
		|	AND BusinessProcessesData.DeletionMark = FALSE";
	Query.SetParameter("CurrentDate", CurrentSessionDate());
	
	Selection  = Query.Execute().Select();
	
	While Selection.Next() Do
		BusinessProcessesAndTasksServer.StartDeferredProcess(Selection.BusinessProcess);
	EndDo;
	
EndProcedure

#EndRegion
