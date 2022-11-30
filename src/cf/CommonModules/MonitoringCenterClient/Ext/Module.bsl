///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Public

#Region PublicBusinessStatistics

// Writes a business statistics operation in cache on the client.
// It is written in the infobase using the StandardPeriodicCheckIdleHandler handler of the 
// StandardSubsystemsGlobal global module.
// If the application is closed, the data is not written.
//
// Parameters:
//  OperationName	- String	- a statistics operation name, if it is missing, a new one is created.
//  Value	- Number		- a quantitative value of the statistics operation.
//
Procedure WriteBusinessStatisticsOperation(OperationName, Value) Export
    
    If RegisterBusinessStatistics() Then 
        WriteParameters = New Structure("OperationName,Value, RecordType");
        WriteParameters.OperationName = OperationName;
        WriteParameters.Value = Value;
        WriteParameters.RecordType = 0;
        
        WriteBusinessStatisticsOperationInternal(WriteParameters);
    EndIf;
    
EndProcedure

// Writes a unique business statistics operation by hours in cache on the client.
// Uniqueness is checked upon writing.
// It is written in the infobase using the StandardPeriodicCheckIdleHandler handler of the 
// StandardSubsystemsGlobal global module.
// If the application is closed, the data is not written.
//
// Parameters:
//  OperationName - String - a statistics operation name, if it is missing, a new one is created.
//  Value - Number - a quantitative value of the statistics operation.
//  Substitute - Boolean - determines a replacement mode of an existing record.
//                              True - an existing record will be deleted before writing.
//                              False - if a record already exists, new data is ignored.
//                              The default value is False.
//  UniqueKey - String - a key used to check whether a record is unique. Its maximum length is 100. 
//                              If it is not set, the MD5 hash of user UUID and session number is used.
//                              The default value is Undefined.
//
Procedure WriteBusinessStatisticsOperationHour(OperationName, Value, Replace = False, UniqueKey = Undefined) Export
    
    If RegisterBusinessStatistics() Then
        WriteParameters = New Structure("OperationName, UniqueKey, Value, Replace, RecordType");
        WriteParameters.OperationName = OperationName;
        WriteParameters.UniqueKey = UniqueKey;
        WriteParameters.Value = Value;
        WriteParameters.Replace = Replace;
        WriteParameters.RecordType = 1;
        
        WriteBusinessStatisticsOperationInternal(WriteParameters);
    EndIf;
    
EndProcedure

// Writes a unique business statistics operation by days in cache on the client.
// Uniqueness is checked upon writing.
// It is written in the infobase using the StandardPeriodicCheckIdleHandler handler of the 
// StandardSubsystemsGlobal global module.
// If the application is closed, the data is not written.
//
// Parameters:
//  OperationName - String - a statistics operation name, if it is missing, a new one is created.
//  Value - Number - a quantitative value of the statistics operation.
//  Substitute - Boolean - determines a replacement mode of an existing record.
//                              True - an existing record will be deleted before writing.
//                              False - if a record already exists, new data is ignored.
//                              The default value is False.
//  UniqueKey - String - a key used to check whether a record is unique. Its maximum length is 100. 
//                              If it is not set, the MD5 hash of user UUID and session number is used.
//                              The default value is Undefined.
//
Procedure WriteBusinessStatisticsOperationDay(OperationName, Value, Replace = False, UniqueKey = Undefined) Export
    
    If RegisterBusinessStatistics() Then
        WriteParameters = New Structure("OperationName, UniqueKey, Value, Replace, RecordType");
        WriteParameters.OperationName = OperationName;
        WriteParameters.UniqueKey = UniqueKey;
        WriteParameters.Value = Value;
        WriteParameters.Replace = Replace;
        WriteParameters.RecordType = 2;
        
        WriteBusinessStatisticsOperationInternal(WriteParameters);
    EndIf;
    
EndProcedure

#EndRegion

#EndRegion

#Region Private

Procedure WriteBusinessStatisticsOperationInternal(WriteParameters)
    
    MonitoringCenterApplicationParameters = MonitoringCenterClientInternal.GetApplicationParameters();
    Measurements = MonitoringCenterApplicationParameters["Measurements"][WriteParameters.RecordType];
    
    Msrmnt = New Structure("RecordType, Key, StatisticsOperation, Value, Replace");
    Msrmnt.RecordType = WriteParameters.RecordType;
    Msrmnt.StatisticsOperation = WriteParameters.OperationName;
    Msrmnt.Value = WriteParameters.Value;
    
    If Msrmnt.RecordType = 0 Then
        
        Measurements.Add(Msrmnt);
        
    Else
        
        If WriteParameters.UniqueKey = Undefined Then
            Msrmnt.Key = MonitoringCenterApplicationParameters["ClientInformation"]["ClientParameters"]["UserHash"];
        Else
            Msrmnt.Key = WriteParameters.UniqueKey;
        EndIf;
        
        Msrmnt.Replace = WriteParameters.Replace;
        
        If NOT (Measurements[Msrmnt.Key] <> Undefined AND NOT Msrmnt.Replace) Then
            Measurements.Insert(Msrmnt.Key, Msrmnt);
        EndIf;
        
    EndIf;
        
EndProcedure

Function  RegisterBusinessStatistics()
    
    ParameterName = "StandardSubsystems.MonitoringCenter";
    
    If ApplicationParameters[ParameterName] = Undefined Then
        ApplicationParameters.Insert(ParameterName, MonitoringCenterClientInternal.GetApplicationParameters());
    EndIf;
        
    Return ApplicationParameters[ParameterName]["RegisterBusinessStatistics"];
    
EndFunction

Procedure AfterUpdateID(Result, AdditionalParameters) Export	
	Notify("IDUpdateMonitoringCenter", Result);
EndProcedure

#EndRegion