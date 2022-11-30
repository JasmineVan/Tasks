///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////////////
// Data exchange subsystem
//
////////////////////////////////////////////////////////////////////////////////

#Region Public

// Sets the ORMCachedValueUpdateDate constant value.
// The value is set to the current date of the computer (server).
// On changing the value of this constant, cached values become outdated for the data exchange 
// subsystem and require re-initialization.
// 
Procedure ResetObjectsRegistrationMechanismCache() Export
	
	DataExchangeInternal.ResetObjectsRegistrationMechanismCache();
	
EndProcedure

#EndRegion

#Region Internal

// Returns background job state.
// This function is used to implement time-consuming operations.
//
// Parameters:
//  JobID - UUID - ID of the background job to receive state for.
//                                                   
// 
// Returns:
//  String - background job state:
//   Active - the job is being executed.
//   Completed - the job is executed successfully.
//   Failed - the job is terminated due to an error or canceled by a user.
//
Function JobState(Val JobID) Export
	
	Try
		Result = ?(TimeConsumingOperations.JobCompleted(JobID), "Completed", "Active");
	Except
		Result = "Failed";
		WriteLogEvent(DataExchangeServer.EventLogMessageTextDataExchange(),
			EventLogLevel.Error,,, DetailErrorDescription(ErrorInfo()));
	EndTry;
	
	Return Result;
EndFunction

#EndRegion

#Region Private

// Executes data exchange process separately for each exchange setting line.
// Data exchange process consists of two stages:
// - Exchange initialization - preparation of data exchange subsystem to perform data exchange.
// - Data exchange - a process of reading a message file and then importing this data to infobase or 
//                          exporting changes to the message file.
// The initialization stage is performed once per session and is saved to the session cache at 
// server until the session is restarted or cached values of data exchange subsystem are reset.
// Cached values are reset when data that affects data exchange process is changed (transport 
// settings, exchange settings, filter settings on exchange plan nodes).
//
// The exchange can be executed completely for all scenario lines or can be executed for a single 
// row of the exchange scenario TS.
//
// Parameters:
//  Cancel                     - Boolean - a cancelation flag. It appears when scenario execution errors occur.
//  ExchangeExecutionSettings - CatalogRef.DataExchangeScenarios - a catalog item whose attribute 
//                              values are used to perform data exchange.
//  LineNumber - Number - a number of the line to use for performing data exchange.
//                              If it is not specified, all lines are involved in data exchange.
// 
Procedure ExecuteDataExchangeUsingDataExchangeScenario(Cancel, ExchangeExecutionSettings, RowNumber = Undefined) Export
	
	DataExchangeServer.ExecuteDataExchangeUsingDataExchangeScenario(Cancel, ExchangeExecutionSettings, RowNumber);
	
EndProcedure

// Records that data exchange is completed.
//
Procedure RecordDataExportInTimeConsumingOperationMode(Val InfobaseNode, Val StartDate) Export
	
	SetPrivilegedMode(True);
	
	ActionOnExchange = Enums.ActionsOnExchange.DataExport;
	
	ExchangeSettingsStructure = New Structure;
	ExchangeSettingsStructure.Insert("InfobaseNode", InfobaseNode);
	ExchangeSettingsStructure.Insert("ExchangeExecutionResult", Enums.ExchangeExecutionResults.Completed);
	ExchangeSettingsStructure.Insert("ActionOnExchange", ActionOnExchange);
	ExchangeSettingsStructure.Insert("ProcessedObjectsCount", 0);
	ExchangeSettingsStructure.Insert("EventLogMessageKey", DataExchangeServer.EventLogMessageKey(InfobaseNode, ActionOnExchange));
	ExchangeSettingsStructure.Insert("StartDate", StartDate);
	ExchangeSettingsStructure.Insert("EndDate", CurrentSessionDate());
	ExchangeSettingsStructure.Insert("IsDIBExchange", DataExchangeCached.IsDistributedInfobaseNode(InfobaseNode));
	
	DataExchangeServer.AddExchangeCompletionEventLogMessage(ExchangeSettingsStructure);
	
EndProcedure

// Records data exchange crash.
//
Procedure RecordExchangeCompletionWithError(Val InfobaseNode,
												Val ActionOnExchange,
												Val StartDate,
												Val ErrorMessageString) Export
	
	SetPrivilegedMode(True);
	
	DataExchangeServer.RecordExchangeCompletionWithError(InfobaseNode,
											ActionOnExchange,
											StartDate,
											ErrorMessageString);
EndProcedure

// Returns the flag of whether a register record set is empty.
//
Function RegisterRecordSetIsEmpty(RecordStructure, RegisterName) Export
	
	RegisterMetadata = Metadata.InformationRegisters[RegisterName];
	
	// Creating register record set.
	RecordSet = InformationRegisters[RegisterName].CreateRecordSet();
	
	// Setting register dimension filters.
	For Each Dimension In RegisterMetadata.Dimensions Do
		
		// If dimension filter value is specified in a structure, the filter is set.
		If RecordStructure.Property(Dimension.Name) Then
			
			RecordSet.Filter[Dimension.Name].Set(RecordStructure[Dimension.Name]);
			
		EndIf;
		
	EndDo;
	
	RecordSet.Read();
	
	Return RecordSet.Count() = 0;
	
EndFunction

// Returns the event log message key by the specified action string.
//
Function EventLogMessageKeyByActionString(InfobaseNode, ActionOnStringExchange) Export
	
	SetPrivilegedMode(True);
	
	Return DataExchangeServer.EventLogMessageKey(InfobaseNode, Enums.ActionsOnExchange[ActionOnStringExchange]);
	
EndFunction

// Returns the structure that contains event log filter data.
//
Function EventLogFilterData(InfobaseNode, Val ActionOnExchange) Export
	
	If TypeOf(ActionOnExchange) = Type("String") Then
		
		ActionOnExchange = Enums.ActionsOnExchange[ActionOnExchange];
		
	EndIf;
	
	SetPrivilegedMode(True);
	
	DataExchangesStates = DataExchangeServer.DataExchangesStates(InfobaseNode, ActionOnExchange);
	
	Filter = New Structure;
	Filter.Insert("EventLogEvent", DataExchangeServer.EventLogMessageKey(InfobaseNode, ActionOnExchange));
	Filter.Insert("StartDate",                DataExchangesStates.StartDate);
	Filter.Insert("EndDate",             DataExchangesStates.EndDate);
	
	Return Filter;
	
EndFunction

// Returns the array of all reference types available in the configuration.
//
Function AllConfigurationReferenceTypes() Export
	
	Return DataExchangeCached.AllConfigurationReferenceTypes();
	
EndFunction

// Gets the state of a time-consuming operation (background job) being executed in a correspondent 
// infobase for a specific node.
//
Function TimeConsumingOperationStateForInfobaseNode(Val OperationID,
									Val InfobaseNode,
									Val AuthenticationParameters = Undefined,
									ErrorMessageString = "") Export
	
	Try
		SetPrivilegedMode(True);
		
		ConnectionParameters = InformationRegisters.DataExchangeTransportSettings.TransportSettingsWS(
			InfobaseNode, AuthenticationParameters);
		
		WSProxy = DataExchangeServer.GetWSProxy(ConnectionParameters, ErrorMessageString);
		
		If WSProxy = Undefined Then
			Raise ErrorMessageString;
		EndIf;
		
		Result = WSProxy.GetContinuousOperationStatus(OperationID, ErrorMessageString);
		
	Except
		Result = "Failed";
		ErrorMessageString = DetailErrorDescription(ErrorInfo())
			+ ?(ValueIsFilled(ErrorMessageString), Chars.LF + ErrorMessageString, "");
	EndTry;
	
	If Result = "Failed" Then
		MessageString = NStr("ru = 'Ошибка в базе-корреспонденте: %1'; en = 'An error occurred in the peer infobase: %1'; pl = 'Błąd w bazie-korespondencie: %1';de = 'Es liegt ein Fehler in der entsprechenden Datenbank vor: %1';ro = 'Eroare în baza-corespondentă: %1';tr = 'Muhabir tabanındaki hata: %1'; es_ES = 'Error en la base-correspondiente: %1'");
		ErrorMessageString = StringFunctionsClientServer.SubstituteParametersToString(MessageString, ErrorMessageString);
	EndIf;
	
	Return Result;
	
EndFunction

// Deletes data synchronization settings item.
//
Procedure DeleteSynchronizationSetting(Val InfobaseNode) Export
	
	DataExchangeServer.DeleteSynchronizationSetting(InfobaseNode);
	
EndProcedure

Function DataExchangeOption(Val Correspondent) Export
	
	SetPrivilegedMode(True);
	
	Return DataExchangeServer.DataExchangeOption(Correspondent);
EndFunction

////////////////////////////////////////////////////////////////////////////////
// Data exchange in privileged mode.

// Returns a list of metadata objects prohibited to export.
// Export is prohibited if a table is marked as NotExport in the rules of exchange plan objects registration.
//
// Parameters:
//     InfobaseNode - ExchangePlanRef - a reference to the exchange plan node being analyzed.
//
// Returns:
//     Array that contains full names of metadata objects.
//
Function NotExportedNodeObjectsMetadataNames(Val InfobaseNode) Export
	Result = New Array;
	
	NotExportMode = Enums.ExchangeObjectExportModes.DoNotExport;
	ExportModes   = DataExchangeCached.UserExchangePlanComposition(InfobaseNode);
	For Each KeyValue In ExportModes Do
		If KeyValue.Value=NotExportMode Then
			Result.Add(KeyValue.Key);
		EndIf;
	EndDo;
	
	Return Result;
EndFunction

// Checks if the specified exchange node is the master node.
//
// Parameters:
//   InfobaseNode - ExchangePlanRef - a reference to the exchange plan node to be checked if it is 
//       master node.
//
// Returns:
//   Boolean.
//
Function IsMasterNode(Val InfobaseNode) Export
	
	Return ExchangePlans.MasterNode() = InfobaseNode;
	
EndFunction

// Creates a query for clearing node permissions (on deleting).
//
Function RequestToClearPermissionsToUseExternalResources(Val InfobaseNode) Export
	
	ModuleSafeModeManager = Common.CommonModule("SafeModeManager");
	Query = ModuleSafeModeManager.RequestToClearPermissionsToUseExternalResources(InfobaseNode);
	Return CommonClientServer.ValueInArray(Query);
	
EndFunction

#EndRegion