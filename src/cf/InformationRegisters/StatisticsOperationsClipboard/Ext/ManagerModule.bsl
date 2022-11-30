///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Private

Procedure WriteBusinessStatisticsOperation(OperationName, Value, Comment = Undefined, Separator = ".") Export
    
    SetPrivilegedMode(True);
	
	DeletionIDPeriod = MonitoringCenterInternal.GetMonitoringCenterParameters("AggregationPeriodMinor");

	If Common.SubsystemExists("StandardSubsystems.SaaS") Then
		ModuleSaaS = Common.CommonModule("SaaS");
		If ModuleSaaS.SessionSeparatorUsage() Then
			DataArea = Format(ModuleSaaS.SessionSeparatorValue(), "NZ=0; NG=0");
		Else
			DataArea = Format(0, "NZ=0; NG=0");
		EndIf;
	Else
		DataArea = Format(0, "NZ=0; NG=0");
	EndIf;
	
	CurDate = CurrentUniversalDateInMilliseconds();
		
	If Separator <> "." Then
		OperationName = StrReplace(OperationName, ".", "☼");
		OperationName = StrReplace(OperationName, Separator, ".");
	EndIf;
	
	OperationRef = MonitoringCenterCached.GetStatisticsOperationRef(OperationName);
	CommentRef = InformationRegisters.StatisticsComments.GetRef(Comment, OperationRef);
	DataAreaRef = InformationRegisters.StatisticsAreas.GetRef(DataArea);
	
	RecordManager = CreateRecordManager();
	RecordManager.RecordDate = CurDate;
	RecordManager.DeletionID = Int(Int(CurDate/1000)/DeletionIDPeriod)*DeletionIDPeriod;
	RecordManager.RecordID = New UUID();
	RecordManager.StatisticsOperation = OperationRef;
	RecordManager.StatisticsComment = CommentRef;
	RecordManager.StatisticsArea = DataAreaRef;
	RecordManager.Value = Value;
	
	RecordManager.Write(False);
    
EndProcedure

Procedure WriteBusinessStatisticsOperations(Operations) Export
    
    SetPrivilegedMode(True);
    
    DeletionIDPeriod = MonitoringCenterInternal.GetMonitoringCenterParameters("AggregationPeriodMinor");
    
    CurDate = CurrentUniversalDateInMilliseconds();
    DeletionID = Int(Int(CurDate/1000)/DeletionIDPeriod)*DeletionIDPeriod; 
    CommentRef = CommonClientServer.BlankUUID();
	DataAreaRef = InformationRegisters.StatisticsAreas.GetRef("0");
    
    RecordSet = CreateRecordSet();
    MaxRecordCount = 1000;
    
    For Each Operation In Operations Do
        
        NewRecord = RecordSet.Add();
        NewRecord.RecordDate = CurDate;
        NewRecord.DeletionID = DeletionID;
        NewRecord.RecordID = New UUID();
        NewRecord.StatisticsOperation = MonitoringCenterCached.GetStatisticsOperationRef(Operation.StatisticsOperation);
        NewRecord.StatisticsComment = CommentRef;
        NewRecord.StatisticsArea = DataAreaRef;
        NewRecord.Value = Operation.Value;
        
        If RecordSet.Count() >= MaxRecordCount Then
            RecordSet.Write(False);
            RecordSet.Clear();
        EndIf;
                
    EndDo;
    
    If RecordSet.Count() > 0 Then
        RecordSet.Write(False);
        RecordSet.Clear();
    EndIf;
            
EndProcedure

Function GetAggregatedOperationsRecords(RecordDate, AggregationPeriod, DeletionPeriod) Export
	Query = New Query;
	Query.Text = "
	|SELECT
	|	DATEADD(
	|		DATETIME(2015,1,1),
	|		SECOND,
	|		(CAST(StatisticsOperationsClipboard.RecordDate/&AggregationPeriod - 0.5 AS NUMBER(15,0)) * &AggregationPeriod)/1000  - 63555667200
	|	) AS Period,
	|	StatisticsOperationsClipboard.StatisticsOperation AS StatisticsOperation,
	|	DATEADD(
	|		DATETIME(2015,1,1),
	|		SECOND,
	|		(CAST(StatisticsOperationsClipboard.RecordDate/&DeletionPeriod - 0.5 AS NUMBER(15,0)) * &DeletionPeriod)/1000  - 63555667200
	|	) AS DeletionID,
	|   SUM(1) AS ValuesCount, 
	|	SUM(StatisticsOperationsClipboard.Value) AS ValueSum,
	|	DATEADD(
	|		DATETIME(2015,1,1),
	|		SECOND,
	|		(CAST(StatisticsOperationsClipboard.RecordDate/&AggregationPeriod - 0.5 AS NUMBER(15,0)) * &AggregationPeriod)/1000  - 63555667200 + &AggregationPeriod/1000 - 1
	|	) AS PeriodEnd
	|FROM
	|	InformationRegister.StatisticsOperationsClipboard AS StatisticsOperationsClipboard
	|WHERE
	|	StatisticsOperationsClipboard.RecordDate < &RecordDate
	|GROUP BY
	|	DATEADD(
	|		DATETIME(2015,1,1),
	|		SECOND,
	|		(CAST(StatisticsOperationsClipboard.RecordDate/&AggregationPeriod - 0.5 AS NUMBER(15,0)) * &AggregationPeriod)/1000  - 63555667200
	|	),
	|	StatisticsOperationsClipboard.StatisticsOperation,
	|	DATEADD(
	|		DATETIME(2015,1,1),
	|		SECOND,
	|		(CAST(StatisticsOperationsClipboard.RecordDate/&DeletionPeriod - 0.5 AS NUMBER(15,0)) * &DeletionPeriod)/1000  - 63555667200
	|	),
	|	DATEADD(
	|		DATETIME(2015,1,1),
	|		SECOND,
	|		(CAST(StatisticsOperationsClipboard.RecordDate/&AggregationPeriod - 0.5 AS NUMBER(15,0)) * &AggregationPeriod)/1000  - 63555667200 + &AggregationPeriod/1000 - 1
	|	)
	|ORDER BY
	|	DATEADD(
	|		DATETIME(2015,1,1),
	|		SECOND,
	|		(CAST(StatisticsOperationsClipboard.RecordDate/&AggregationPeriod - 0.5 AS NUMBER(15,0)) * &AggregationPeriod)/1000  - 63555667200
	|	)
	|";
	
	Query.SetParameter("RecordDate", (RecordDate - Date(1, 1, 1)) * 1000);
	Query.SetParameter("AggregationPeriod", AggregationPeriod * 1000);
	Query.SetParameter("DeletionPeriod", DeletionPeriod * 1000);
	
	QueryResult = Query.Execute();
	
	Return QueryResult;	
EndFunction

Function GetAggregatedRecordsComment(RecordDate, AggregationPeriod, DeletionPeriod) Export
	Query = New Query;
	Query.Text = "
	|SELECT
	|	DATEADD(
	|		DATETIME(2015,1,1),
	|		SECOND,
	|		(CAST(StatisticsOperationsClipboard.RecordDate/&AggregationPeriod - 0.5 AS NUMBER(15,0)) * &AggregationPeriod)/1000  - 63555667200
	|	) AS Period,
	|	StatisticsOperationsClipboard.StatisticsOperation AS StatisticsOperation,
	|	StatisticsOperationsClipboard.StatisticsComment AS StatisticsComment,
	|	DATEADD(
	|		DATETIME(2015,1,1),
	|		SECOND,
	|		(CAST(StatisticsOperationsClipboard.RecordDate/&DeletionPeriod - 0.5 AS NUMBER(15,0)) * &DeletionPeriod)/1000  - 63555667200
	|	) AS DeletionID,
	|   SUM(1) AS ValuesCount,
	|	DATEADD(
	|		DATETIME(2015,1,1),
	|		SECOND,
	|		(CAST(StatisticsOperationsClipboard.RecordDate/&AggregationPeriod - 0.5 AS NUMBER(15,0)) * &AggregationPeriod)/1000  - 63555667200 + &AggregationPeriod/1000 - 1
	|	) AS PeriodEnd
	|FROM
	|	InformationRegister.StatisticsOperationsClipboard AS StatisticsOperationsClipboard
	|WHERE
	|	StatisticsOperationsClipboard.RecordDate < &RecordDate
	|GROUP BY
	|	DATEADD(
	|		DATETIME(2015,1,1),
	|		SECOND,
	|		(CAST(StatisticsOperationsClipboard.RecordDate/&AggregationPeriod - 0.5 AS NUMBER(15,0)) * &AggregationPeriod)/1000  - 63555667200
	|	),
	|	StatisticsOperationsClipboard.StatisticsOperation,
	|	StatisticsOperationsClipboard.StatisticsComment,
	|	DATEADD(
	|		DATETIME(2015,1,1),
	|		SECOND,
	|		(CAST(StatisticsOperationsClipboard.RecordDate/&DeletionPeriod - 0.5 AS NUMBER(15,0)) * &DeletionPeriod)/1000  - 63555667200
	|	),
	|	DATEADD(
	|		DATETIME(2015,1,1),
	|		SECOND,
	|		(CAST(StatisticsOperationsClipboard.RecordDate/&AggregationPeriod - 0.5 AS NUMBER(15,0)) * &AggregationPeriod)/1000  - 63555667200 + &AggregationPeriod/1000 - 1
	|	)
	|ORDER BY
	|	DATEADD(
	|		DATETIME(2015,1,1),
	|		SECOND,
	|		(CAST(StatisticsOperationsClipboard.RecordDate/&AggregationPeriod - 0.5 AS NUMBER(15,0)) * &AggregationPeriod)/1000  - 63555667200
	|	)
	|";
	
	Query.SetParameter("RecordDate", (RecordDate - Date(1, 1, 1)) * 1000);
	Query.SetParameter("AggregationPeriod", AggregationPeriod * 1000);
	Query.SetParameter("DeletionPeriod", DeletionPeriod * 1000);
	
	QueryResult = Query.Execute();
	
	Return QueryResult;	
EndFunction

Function GetAggregatedRecordsStatisticsAreas(RecordDate, AggregationPeriod, DeletionPeriod) Export
	DeletionPeriod = 3600;
	
	Query = New Query;
	Query.Text = "
	|SELECT
	|	DATEADD(
	|		DATETIME(2015,1,1),
	|		SECOND,
	|		(CAST(StatisticsOperationsClipboard.RecordDate/&AggregationPeriod - 0.5 AS NUMBER(15,0)) * &AggregationPeriod)/1000  - 63555667200
	|	) AS Period,
	|	StatisticsOperationsClipboard.StatisticsOperation AS StatisticsOperation,
	|	StatisticsOperationsClipboard.StatisticsArea AS StatisticsArea,
	|	DATEADD(
	|		DATETIME(2015,1,1),
	|		SECOND,
	|		(CAST(StatisticsOperationsClipboard.RecordDate/&DeletionPeriod - 0.5 AS NUMBER(15,0)) * &DeletionPeriod)/1000  - 63555667200
	|	) AS DeletionID,
	|   SUM(1) AS ValuesCount,
	|	DATEADD(
	|		DATETIME(2015,1,1),
	|		SECOND,
	|		(CAST(StatisticsOperationsClipboard.RecordDate/&AggregationPeriod - 0.5 AS NUMBER(15,0)) * &AggregationPeriod)/1000  - 63555667200 + &AggregationPeriod/1000 - 1
	|	) AS PeriodEnd
	|FROM
	|	InformationRegister.StatisticsOperationsClipboard AS StatisticsOperationsClipboard
	|WHERE
	|	StatisticsOperationsClipboard.RecordDate < &RecordDate
	|GROUP BY
	|	DATEADD(
	|		DATETIME(2015,1,1),
	|		SECOND,
	|		(CAST(StatisticsOperationsClipboard.RecordDate/&AggregationPeriod - 0.5 AS NUMBER(15,0)) * &AggregationPeriod)/1000  - 63555667200
	|	),
	|	StatisticsOperationsClipboard.StatisticsOperation,
	|	StatisticsOperationsClipboard.StatisticsArea,
	|	DATEADD(
	|		DATETIME(2015,1,1),
	|		SECOND,
	|		(CAST(StatisticsOperationsClipboard.RecordDate/&DeletionPeriod - 0.5 AS NUMBER(15,0)) * &DeletionPeriod)/1000  - 63555667200
	|	),
	|	DATEADD(
	|		DATETIME(2015,1,1),
	|		SECOND,
	|		(CAST(StatisticsOperationsClipboard.RecordDate/&AggregationPeriod - 0.5 AS NUMBER(15,0)) * &AggregationPeriod)/1000  - 63555667200 + &AggregationPeriod/1000 - 1
	|	)
	|ORDER BY
	|	DATEADD(
	|		DATETIME(2015,1,1),
	|		SECOND,
	|		(CAST(StatisticsOperationsClipboard.RecordDate/&AggregationPeriod - 0.5 AS NUMBER(15,0)) * &AggregationPeriod)/1000  - 63555667200
	|	)
	|";
	
	Query.SetParameter("RecordDate", (RecordDate - Date(1, 1, 1)) * 1000);
	Query.SetParameter("AggregationPeriod", AggregationPeriod * 1000);
	Query.SetParameter("DeletionPeriod", DeletionPeriod * 1000);
	
	QueryResult = Query.Execute();
	
	Return QueryResult;	
EndFunction

Procedure DeleteRecords(RecordDate) Export
	Query = New Query;
	Query.Text = "
	|SELECT DISTINCT
	|	StatisticsOperationsClipboard.DeletionID AS DeletionID
	|FROM
	|	InformationRegister.StatisticsOperationsClipboard AS StatisticsOperationsClipboard
	|WHERE
	|	StatisticsOperationsClipboard.RecordDate < &RecordDate
	|ORDER BY
	|	StatisticsOperationsClipboard.DeletionID
	|";
	
	Query.SetParameter("RecordDate", (RecordDate - Date(1, 1, 1)) * 1000);
	
	QueryResult = Query.Execute();
	
	RecordSet = CreateRecordSet();
	Selection = QueryResult.Select();
	While Selection.Next() Do
		RecordSet.Filter.DeletionID.Set(Selection.DeletionID);
		RecordSet.Write(True);
	EndDo;
EndProcedure

#EndRegion

#EndIf