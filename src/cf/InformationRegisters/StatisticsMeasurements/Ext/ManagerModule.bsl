///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Private

Function IsRecord(RecordPeriod, RecordPeriodType, varKey, StatisticsOperation)
    
    Query = New Query;
    
    Query.Text = "
    |SELECT TOP 1
    |   TRUE
    |FROM
    |   InformationRegister.StatisticsMeasurements
    |WHERE
    |   RecordPeriod = &RecordPeriod
    |   AND RecordType = &RecordType
    |   AND Key = &Key
    |   AND StatisticsOperation = &StatisticsOperation
    |";
    
    Query.SetParameter("RecordPeriod", RecordPeriod);
    Query.SetParameter("RecordType", RecordPeriodType);
    Query.SetParameter("Key", varKey);
    Query.SetParameter("StatisticsOperation", StatisticsOperation);
    
    
    SetPrivilegedMode(True);
    Result = Query.Execute();
    SetPrivilegedMode(False);
    
    Return NOT Result.IsEmpty();    
    
EndFunction

Procedure WriteBusinessStatisticsOperation(RecordPeriod, RecordPeriodType, varKey, StatisticsOperation, OperationValue, Replace) Export
    
    IsRecord = IsRecord(RecordPeriod, RecordPeriodType, varKey, StatisticsOperation);
    
    If NOT IsRecord OR Replace Then
        
        BeginTransaction();
        Try
            
            Lock = New DataLock;
            
            LockItemRecordPeriod = Lock.Add("InformationRegister.StatisticsMeasurements");
		    LockItemRecordPeriod.SetValue("RecordPeriod", RecordPeriod);            
            LockItemRecordPeriod.SetValue("RecordType", RecordPeriodType);                  
            LockItemRecordPeriod.SetValue("Key", varKey);                            
            LockItemRecordPeriod.SetValue("StatisticsOperation", StatisticsOperation);
                           
		    Lock.Lock();
            
            IsRecord = IsRecord(RecordPeriod, RecordPeriodType, varKey, StatisticsOperation);
            
            If NOT IsRecord OR Replace Then
                
                RecordManager = CreateRecordManager();
                RecordManager.RecordPeriod = RecordPeriod;
                RecordManager.Key = varKey;
                RecordManager.RecordType = RecordPeriodType;
                RecordManager.StatisticsOperation = StatisticsOperation;
                RecordManager.DeletionID = BegOfDay(RecordPeriod);
                RecordManager.OperationValue = OperationValue;
                
                SetPrivilegedMode(True);
                If IsRecord AND Replace Then
                    RecordManager.Write(True);
                Else
                    RecordManager.Write(False);
                EndIf;
                SetPrivilegedMode(False);
                
            EndIf;
            CommitTransaction();
        Except
            RollbackTransaction();
        EndTry;
        
    EndIf;
         
EndProcedure

Function GetHourMeasurements(StartDate, EndDate) Export
    
    Return GetMeasurementsByType(StartDate, EndDate, 1);
        
EndFunction

Function GetDayMeasurements(StartDate, EndDate) Export
    
    Return GetMeasurementsByType(StartDate, EndDate, 2);
        
EndFunction

Function GetMeasurementsByType(StartDate, EndDate, RecordPeriodType)
    
    Query = New Query;
    Query.Text = "
    |SELECT
    |   StatisticsOperations.Description AS StatisticsOperation,
    |   MeasurementsStatisticsOperations.RecordPeriod AS Period,
    |   COUNT(*) AS ValuesCount,
    |   SUM(MeasurementsStatisticsOperations.OperationValue) AS ValueSum
    |FROM
    |   InformationRegister.StatisticsMeasurements AS MeasurementsStatisticsOperations
    |INNER JOIN
    |   InformationRegister.StatisticsOperations AS StatisticsOperations
	|ON
	|	MeasurementsStatisticsOperations.StatisticsOperation = StatisticsOperations.OperationID
    |WHERE
    |   MeasurementsStatisticsOperations.RecordType = &RecordType
    |   AND MeasurementsStatisticsOperations.RecordPeriod BETWEEN &StartDate AND &EndDate
    |GROUP BY
    |   StatisticsOperations.Description,
    |   MeasurementsStatisticsOperations.RecordPeriod
    |";
    
    Query.SetParameter("StartDate", StartDate);
    Query.SetParameter("EndDate", EndDate);
    Query.SetParameter("RecordType", RecordPeriodType);
    
    Result = Query.Execute();
    
    Return Result;
    
EndFunction

#EndRegion

#EndIf
