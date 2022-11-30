///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Public

#Region PublicCommon

// Enables the MonitoringCenter subsystem.
//
Procedure EnableSubsystem() Export
    
    MonitoringCenterParameters = MonitoringCenterInternal.GetMonitoringCenterParameters();
    
    MonitoringCenterParameters.EnableMonitoringCenter = True;
	MonitoringCenterParameters.ApplicationInformationProcessingCenter = False;
    
    MonitoringCenterInternal.SetMonitoringCenterParametersExternalCall(MonitoringCenterParameters);
    
EndProcedure

// Disables the MonitoringCenter subsystem.
//
Procedure DisableSubsystem() Export
    
    MonitoringCenterParameters = MonitoringCenterInternal.GetMonitoringCenterParameters();
    
    MonitoringCenterParameters.EnableMonitoringCenter = False;
	MonitoringCenterParameters.ApplicationInformationProcessingCenter = False;
    
    MonitoringCenterInternal.SetMonitoringCenterParametersExternalCall(MonitoringCenterParameters);
    
EndProcedure

// Returns a string presentation of infobase ID in the monitoring center.
// Returns:
//	String - an UUID of the infobase in the monitoring center.
//
Function InfoBaseID() Export
	
	ParametersToGet = New Structure;
	ParametersToGet.Insert("EnableMonitoringCenter");
	ParametersToGet.Insert("ApplicationInformationProcessingCenter");
	ParametersToGet.Insert("DiscoveryPackageSent");
	ParametersToGet.Insert("LastPackageNumber");
	ParametersToGet.Insert("InfoBaseID");
	MonitoringCenterParameters = MonitoringCenterInternal.GetMonitoringCenterParameters(ParametersToGet);
	
	If (MonitoringCenterParameters.EnableMonitoringCenter OR MonitoringCenterParameters.ApplicationInformationProcessingCenter) 
		AND MonitoringCenterParameters.DiscoveryPackageSent Then
		Return String(MonitoringCenterParameters.InfoBaseID);
	EndIf;
	
	// If the data was never sent, an empty string returns.
	Return "";	
	
EndFunction

#EndRegion

#Region PublicBusinessStatistics

// Writes a business statistics operation.
//
// Parameters:
//  OperationName	- String	- a statistics operation name, if it is missing, a new one is created.
//  Value	- Number		- a quantitative value of the statistics operation.
//  Comment	- String	- an arbitrary comment.
//	Separator	- String	- a value separator in OperationName if separator is not a point.
//
Procedure WriteBusinessStatisticsOperation(OperationName, Value, Comment = Undefined, Separator = ".") Export
	If WriteBusinessStatisticsOperations() Then
		InformationRegisters.StatisticsOperationsClipboard.WriteBusinessStatisticsOperation(OperationName, Value, Comment, Separator);
	EndIf;
EndProcedure

// Writes a unique business statistics operation by hours.
// Uniqueness is checked upon writing.
//
// Parameters:
//  OperationName - String - a statistics operation name, if it is missing, a new one is created.
//  UniqueKey - String - a key used to check whether a record is unique. Its maximum length is 100.
//  Value - Number - a quantitative value of the statistics operation.
//  Substitute - Boolean - determines a replacement mode of an existing record.
//                              True - an existing record will be deleted before writing.
//                              False - if a record already exists, new data is ignored.
//                              The default value is False.
//
Procedure WriteBusinessStatisticsOperationHour(OperationName, UniqueKey, Value, Replace = False) Export
    
    WriteParameters = New Structure("OperationName, UniqueKey, Value, Replace, RecordType, RecordPeriod");
    WriteParameters.OperationName = OperationName;
    WriteParameters.UniqueKey = UniqueKey;
    WriteParameters.Value = Value;
    WriteParameters.Replace = Replace;
    WriteParameters.RecordType = 1;
    WriteParameters.RecordPeriod = BegOfHour(CurrentUniversalDate());
    
    MonitoringCenterInternal.WriteBusinessStatisticsOperationInternal(WriteParameters);
    
EndProcedure

// Writes a unique business statistics operation by days.
// Uniqueness is checked upon writing.
//
// Parameters:
//  OperationName - String - a statistics operation name, if it is missing, a new one is created.
//  UniqueKey - String - a key used to check whether a record is unique. Its maximum length is 100.
//  Value - Number - a quantitative value of the statistics operation.
//  Substitute - Boolean - determines a replacement mode of an existing record.
//                              True - an existing record will be deleted before writing.
//                              False - if a record already exists, new data is ignored.
//                              The default value is False.
//
Procedure WriteBusinessStatisticsOperationDay(OperationName, UniqueKey, Value, Replace = False) Export
    
    WriteParameters = New Structure("OperationName, UniqueKey, Value, Replace, RecordType, RecordPeriod");
    WriteParameters.OperationName = OperationName;
    WriteParameters.UniqueKey = UniqueKey;
    WriteParameters.Value = Value;
    WriteParameters.Replace = Replace;
    WriteParameters.RecordType = 2;
    WriteParameters.RecordPeriod = BegOfDay(CurrentUniversalDate());
   
    MonitoringCenterInternal.WriteBusinessStatisticsOperationInternal(WriteParameters);
    
EndProcedure


// Returns a business statistics registration status.
// Returns:
//	Boolean - register business statistics.
//
Function WriteBusinessStatisticsOperations() Export
	MonitoringCenterParameters = New Structure("EnableMonitoringCenter, ApplicationInformationProcessingCenter, RegisterBusinessStatistics");
		
	MonitoringCenterInternal.GetMonitoringCenterParameters(MonitoringCenterParameters);
	
	Return (MonitoringCenterParameters.EnableMonitoringCenter OR MonitoringCenterParameters.ApplicationInformationProcessingCenter) AND MonitoringCenterParameters.RegisterBusinessStatistics;
EndFunction

#EndRegion

#Region PublicConfigurationStatistics

// Writes statistics by configuration objects.
//
// Parameters:
//  MetadataNameMatch - Structure - a structure with the following properties:
//   * Key		- String - 	metadata object name.
//   * Value	- String - 	data selection query text, it must contain the Quantity field.
//							 If Quantity is equal to zero, it is not recorded.
//                          
//
Procedure WriteConfigurationStatistics(MetadataNamesMap) Export
	Parameters = New Map;
	For Each CurMetadata In MetadataNamesMap Do
		Parameters.Insert(CurMetadata.Key, New Structure("Query, StatisticsOperations, StatisticsKind", CurMetadata.Value,,0));
	EndDo;
	
    If Common.DataSeparationEnabled() AND Common.SubsystemExists("StandardSubsystems.SaaS") Then
        ModuleSaaS = Common.CommonModule("SaaS");
        DataAreaString = Format(ModuleSaaS.SessionSeparatorValue(), "NG=0");
    Else
        DataAreaString = "0";
    EndIf;
	DataAreaRef = InformationRegisters.StatisticsAreas.GetRef(DataAreaString);
	
	InformationRegisters.ConfigurationStatistics.Write(Parameters, DataAreaRef);
EndProcedure

// Writes statistics by a configuration object.
//
// Parameters:
//  ObjectName - 	String	 - a statistics operation name, if it is missing, a new one is created.
//  Value - 		Number	 - a quantitative value of the statistics operation. If the value is equal to 
//                            zero, it is not recorded.
//
Procedure WriteConfigurationObjectStatistics(ObjectName, Value) Export
    
    If Value <> 0 Then 
        StatisticsOperation = MonitoringCenterCached.GetStatisticsOperationRef(ObjectName);
        
        If Common.DataSeparationEnabled() AND Common.SubsystemExists("StandardSubsystems.SaaS") Then
            ModuleSaaS = Common.CommonModule("SaaS");
            DataAreaString = Format(ModuleSaaS.SessionSeparatorValue(), "NG=0");
        Else
            DataAreaString = "0";
        EndIf;
        DataAreaRef = InformationRegisters.StatisticsAreas.GetRef(DataAreaString);
        
        RecordSet = InformationRegisters.ConfigurationStatistics.CreateRecordSet();
        RecordSet.Filter.StatisticsOperation.Set(StatisticsOperation);
        
        NewRecord = RecordSet.Add();
        NewRecord.StatisticsAreaID = DataAreaRef;
        NewRecord.StatisticsOperation = StatisticsOperation;
        NewRecord.Value = Value;	
        RecordSet.Write(True);
    EndIf;
    
EndProcedure

#EndRegion

#EndRegion