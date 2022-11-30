///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Public

// Starts measuring the time for the key operation.
// The result is recorded in the TimeMeasurements information register.
// Since client measurements are stored in the client buffer and recorded at the intervals specified 
// in the PerformanceMonitorRecordPeriod constant (every minute by default), some of the 
// measurements may be lost if the session is terminated.
//
// Parameters:
//	KeyOperation - String - 	key operation name. If Undefined, the key operation must be specified 
//									explicitly by calling
//									SetMeasurementKeyOperation.
//	RecordWithError - Boolean -	indicates automatic error recording. 
//									True - if the measurement was stopped automatically, it will be stored with the 
//									"Completed with error" flag. If an error cannot occur in a certain code chunk, you must 
//									stop the measurement explicitly using the 
//									StopTimeMeasurement method, or set the error flag False using the 
//									SetMeasurementErrorFlag method in this chunk.
//									False - the measurement will be considered correct upon automatic completion.
//	AutoCompletion - Boolean	 - 		indicates whether the measurement must be completed automatically.
//									True - the measurement will be completed automatically via the global idle handler.
//									
//									False - the measurement must be completed explicitly by calling
//									StopTimeMeasurement.
//
// Returns:
//	UUID - a unique measurement ID.
//
Function TimeMeasurement(KeyOperation = Undefined, RecordWithError = False, AutoCompletion = True) Export
	
	MeasurementUUID = New UUID("00000000-0000-0000-0000-000000000000");
	
	If RunPerformanceMeasurements() Then
		MeasurementUUID = New UUID();
		Parameters = New Structure;
		Parameters.Insert("KeyOperation", KeyOperation);
		Parameters.Insert("MeasurementUUID", MeasurementUUID);
		Parameters.Insert("AutoStop", AutoCompletion);
		Parameters.Insert("CompletedWithError", RecordWithError);
				
		StartTimeMeasurementAtClientInternal(Parameters);
	EndIf;
		
	Return MeasurementUUID;
	
EndFunction

// Begins a technological measurement of the key operation time.
// The measurement result will be recorded in InformationRegister.TimeMeasurements.
//
// Parameters:
//	AutoStop - Boolean	 - 	indicates whether the measurement must be completed automatically.
//								True - the measurement will be completed automatically via the global idle handler.
//								
//								False - the measurement must be completed explicitly by calling
//								StopTimeMeasurement.
//	KeyOperation - String - key operation name. If Undefined, the key operation must be specified 
//								explicitly by calling
//								SetMeasurementKeyOperation.
//
// Returns:
//	UUID - a unique measurement ID.
//
Function StartTechologicalTimeMeasurement(AutoStop = True, KeyOperation = Undefined) Export
	
	MeasurementUUID = New UUID("00000000-0000-0000-0000-000000000000");
	
	If RunPerformanceMeasurements() Then
		MeasurementUUID = New UUID();
		Parameters = New Structure;
		Parameters.Insert("KeyOperation", KeyOperation);
		Parameters.Insert("MeasurementUUID", MeasurementUUID);
		Parameters.Insert("AutoStop", AutoStop);
		Parameters.Insert("Technological", True);
		Parameters.Insert("CompletedWithError", False);
		
		StartTimeMeasurementAtClientInternal(Parameters);
	EndIf;
		
	Return MeasurementUUID;
	
EndFunction

// Completes time measurement on the client.
//
// Parameters:
//  MeasurementUUID - UUID - a measurement UUID.
//  CompletedWithError - Boolean - indicates that the measurement was not completed to the end, and 
//  							the key operation completed with error.
//
Procedure StopTimeMeasurement(MeasurementUUID, CompletedWithError = False) Export
	
	If RunPerformanceMeasurements() Then
		EndTime = CurrentUniversalDateInMilliseconds();
		StopTimeMeasurementInternal(MeasurementUUID, EndTime);
		
		PerformanceMonitorTimeMeasurement = ApplicationParameters["StandardSubsystems.PerformanceMonitorTimeMeasurement"];
		If PerformanceMonitorTimeMeasurement <> Undefined Then
			Measurements = PerformanceMonitorTimeMeasurement["Measurements"];
			Msrmnt = Measurements[MeasurementUUID];
			If Msrmnt <> Undefined Then
				Msrmnt["CompletedWithError"] = CompletedWithError;
				CompletedMeasurements = ApplicationParameters["StandardSubsystems.PerformanceMonitorTimeMeasurement"]["CompletedMeasurements"];
				CompletedMeasurements.Insert(MeasurementUUID, Msrmnt);
				Measurements.Delete(MeasurementUUID);
			EndIf;
		EndIf;   
		
	EndIf;
	
EndProcedure

// Sets measurement parameters.
//
// Parameters:
//	MeasurementUUID	- UUID - a measurement UUID.
//	MeasurementParameters	- Structure - structure with the following properties:
//		* KeyOperation 	- String					- key operation name.
//		* MeasurementWeight			- Number						- measurement complexity indicator.
//		* Comment		- String, Map		- any additional information about the measurement.
//		* CompletedWithError - Boolean					- indicates whether the measurement was completed with an 
//														  error, see SetMeasurementErrorFlag.
//
Procedure SetMeasurementParameters(MeasurementUUID, MeasurementParameters) Export
	
	If RunPerformanceMeasurements() Then
		ParameterName = "StandardSubsystems.PerformanceMonitorTimeMeasurement";
		Measurements = ApplicationParameters[ParameterName]["Measurements"];
		For Each Parameter In MeasurementParameters Do
			Measurements[MeasurementUUID][Parameter.Key] = Parameter.Value;
		EndDo;
	EndIf;
	
EndProcedure

// Sets the key operation for a measurement.
//
// Parameters:
//	MeasurementUUID 			- UUID - a measurement UUID.
//	KeyOperation	- String - a key operation description.
//
// If the key operation name is not yet known at the time of measurement, this procedure can be used 
// to specify the key operation name at any time before the measurement is completed.
// 
// For example, this can be done when posting a document because it cannot be guaranteed from the 
// start that the document will be completed and not rejected.
// 
// &AtClient
// Procedure BeforeRecord(Cancel, RecordParameters)
//	If RecordParameters.RecordMode = DocumentRecordMode.Posting Then
//		MeasurementIDPosting = PerformanceMonitorClient.StartTimeMeasurement(True);
//	EndIf.
// EndProcedure
//
// &AtClient
// Procedure AfterRecord(RecordParameters)
//	If RecordParameters.RecordMode = DocumentRecordMode.Posting Then
//		PerformanceMonitorClient.SetMeasurementKeyOperation(MeasurementIDPosting, "_DemoDocumentPosting");
//	EndIf.
// EndProcedure
//
Procedure SetMeasurementKeyOperation(MeasurementUUID, KeyOperation) Export
	
	If RunPerformanceMeasurements() Then
		ParameterName = "StandardSubsystems.PerformanceMonitorTimeMeasurement";
		Measurements = ApplicationParameters[ParameterName]["Measurements"];	
		Measurements[MeasurementUUID]["KeyOperation"] = KeyOperation;
	EndIf;
	
EndProcedure

// Sets the weight for a measurement operation.
//
// Parameters:
//	MeasurementUUID - UUID - a measurement UUID.
//	MeasurementWeight - Number					- an indicator of measurement complexity, e.g. the number of lines 
//										  in a document.
//
Procedure SetMeasurementWeight(MeasurementUUID, MeasurementWeight) Export
	
	If RunPerformanceMeasurements() Then
		ParameterName = "StandardSubsystems.PerformanceMonitorTimeMeasurement";
		Measurements = ApplicationParameters[ParameterName]["Measurements"];	
		Measurements[MeasurementUUID]["MeasurementWeight"] = MeasurementWeight;
	EndIf;
	
EndProcedure

// Sets a comment for a measurement operation.
//
// Parameters:
//  MeasurementUUID   - UUID -  a measurement UUID.
//  Comment - String, Map    - any additional information about the measurement.
//                                          If a Map is specified:
//                                            * Key     - String - name of the additional parameter.
//                                            * Value - String, Number, Boolean - value of the additional parameter.
//
Procedure SetMeasurementComment(MeasurementUUID, Comment) Export
		
	If RunPerformanceMeasurements() Then
		ParameterName = "StandardSubsystems.PerformanceMonitorTimeMeasurement";
		Measurements = ApplicationParameters[ParameterName]["Measurements"];	
		Measurements[MeasurementUUID]["Comment"] = Comment;
	EndIf;
	
EndProcedure

// Sets an error flag for a measurement.
//
// Parameters:
//	MeasurementUUID	- UUID	-  a measurement UUID.
//	Flag		- Boolean					- whether the measurement was successful. True - the measurement was successful.
//											  False - there was an error during the measurement.
//
Procedure SetMeasurementErrorFlag(MeasurementUUID, Flag) Export
	
	If RunPerformanceMeasurements() Then
		ParameterName = "StandardSubsystems.PerformanceMonitorTimeMeasurement";
		Measurements = ApplicationParameters[ParameterName]["Measurements"];	
		Measurements[MeasurementUUID]["CompletedWithError"] = Flag;
	EndIf;
	
EndProcedure

// Starts measuring the time of a time-consuming key operation. You must complete the measurement 
// explicitly by calling the EndTimeConsumingOperationMeasurement procedure.
// The result is recorded in the TimeMeasurements information register.
//
// Parameters:
//	KeyOperation - String - key operation name. 
//	RecordWithError - Boolean -	indicates automatic error recording. 
//									True - if the measurement was stopped automatically, it will be stored with the 
//									"Completed with error" flag. If an error cannot occur in a certain code chunk, you must 
//									stop the measurement explicitly using the 
//									StopTimeMeasurement method, or set the error flag False using the 
//									SetMeasurementErrorFlag
//									False - the measurement will be considered correct upon automatic completion.
//									StopTimeMeasurement.
//	AutoCompletion - Boolean	 - 		indicates whether the measurement must be completed automatically.
//									True - the measurement will be completed automatically via the global idle handler.
//									
//									False - the measurement must be completed explicitly by calling
//									StopTimeMeasurement.
//	LastStepName - String - 	name of the key operation last step. The parameter is useful when 
//									running a measurement with automatic completion. Otherwise, the last actions executed 
//									between RecordTimeConsumingOperationMeasurement and idle handler will be recorded under 
//									the name "Last step".
//
// Returns:
// 	MeasurementDetails - Map.
//   KeyOperation - name of the key operation.
//   StartTime - key operation start time in milliseconds.
//   LastMeasurementTime - time of the last key operation measurement in milliseconds.
//   MeasurementWeight - amount of data processed during execution.
//   NestedMeasurements - collection of nested step measurements.
//
Function StartTimeConsumingOperationMeasurement(KeyOperation, RecordWithError = False, AutoCompletion = False, LastStepName = "LastStep") Export
	
	MeasurementUUID = New UUID("00000000-0000-0000-0000-000000000000");
	Msrmnt = New Map;
	
	If RunPerformanceMeasurements() Then
		MeasurementUUID = New UUID();
		Parameters = New Structure;
		Parameters.Insert("KeyOperation", KeyOperation);
		Parameters.Insert("MeasurementUUID", MeasurementUUID);
		Parameters.Insert("CompletedWithError", RecordWithError);
		Parameters.Insert("AutoStop", AutoCompletion);
				
		StartTimeMeasurementAtClientInternal(Parameters);
		
		ParameterName = "StandardSubsystems.PerformanceMonitorTimeMeasurement";
		Measurements = ApplicationParameters[ParameterName]["Measurements"];
		Msrmnt = Measurements[MeasurementUUID]; 		
		Msrmnt.Insert("LastMeasurementTime", Msrmnt["BeginTime"]);
		Msrmnt.Insert("WeightedTime", 0.0);
		Msrmnt.Insert("MeasurementWeight", 0);
		Msrmnt.Insert("NestedMeasurements", New Map);
		Msrmnt.Insert("MeasurementUUID", MeasurementUUID);
		Msrmnt.Insert("Client", True);
		Msrmnt.Insert("LastStepName", LastStepName);
		
	EndIf;
		
	Return Msrmnt;
	
EndFunction

// Records the measurement of a nested step of a time-consuming operation.
// Parameters:
//	MeasurementDetails 		- Map	 - must be obtained by calling the StartTimeConsumingOperationMeasurement method.
//	DataVolume 	 - Number			 - amount of data, e.g. lines, processed during the nested step.
//	StepName 			 - String		 - an arbitrary name of the nested step.
//	Comment 		 - String		 - an arbitrary additional description of the measurement.
//
Procedure FixTimeConsumingOperationMeasure(MeasurementDetails, DataVolume, StepName, Comment = "") Export
	
	If NOT ValueIsFilled(MeasurementDetails) Then
		Return;
	EndIf;
	
	CurrentTime = CurrentUniversalDateInMilliseconds();
	DataVolumeInStep = ?(DataVolume = 0, 1, DataVolume);
	
	Duration = CurrentTime - MeasurementDetails["LastMeasurementTime"];
	// Initializing the nested measurement if it's the first time it's performed.
	NestedMeasurements = MeasurementDetails["NestedMeasurements"];
	If NestedMeasurements[StepName] = Undefined Then
		NestedMeasurements.Insert(StepName, New Map);
		NestedMeasurementStep = NestedMeasurements[StepName];
		NestedMeasurementStep.Insert("Comment", Comment);
		NestedMeasurementStep.Insert("BeginTime", MeasurementDetails["LastMeasurementTime"]);
		NestedMeasurementStep.Insert("Duration", 0.0);	
		NestedMeasurementStep.Insert("MeasurementWeight", 0);
	EndIf;                                                            
	// Writing the nested measurement data.
	NestedMeasurementStep = NestedMeasurements[StepName];
	NestedMeasurementStep.Insert("EndTime", CurrentTime);
	NestedMeasurementStep.Insert("Duration", Duration + NestedMeasurementStep["Duration"]);
	NestedMeasurementStep.Insert("MeasurementWeight", DataVolumeInStep + NestedMeasurementStep["MeasurementWeight"]);
	
	// Writing the data for a time-consuming measurement.
	MeasurementDetails.Insert("LastMeasurementTime", CurrentTime);
	MeasurementDetails.Insert("MeasurementWeight", DataVolumeInStep + MeasurementDetails["MeasurementWeight"]);
	
EndProcedure

// Completes the measurement of a time-consuming operation.
// If a step name is specified, records it as a separate nested step.
// Parameters:
//	MeasurementDetails 		- Map	 - must be obtained by calling the StartTimeConsumingOperationMeasurement method.
//	DataVolume 	 - Number			 - amount of data, e.g. lines, processed during the nested step.
//	StepName 			 - String		 - an arbitrary name of the nested step.
//	Comment 		 - String		 - an arbitrary additional description of the measurement.
//
Procedure EndTimeConsumingOperationMeasurement(MeasurementDetails, DataVolume, StepName = "", Comment = "") Export
	
	If RunPerformanceMeasurements() Then
		
		If MeasurementDetails["NestedMeasurements"].Count() Then
			DataVolumeInStep = ?(DataVolume = 0, 1, DataVolume);
			FixTimeConsumingOperationMeasure(MeasurementDetails, DataVolumeInStep, ?(IsBlankString(StepName), "LastStep", StepName), Comment);
		EndIf;
		
		MeasurementUUID = MeasurementDetails["MeasurementUUID"];
		EndTime = CurrentUniversalDateInMilliseconds();
		StopTimeMeasurementInternal(MeasurementUUID, EndTime);
		
		Measurements = ApplicationParameters["StandardSubsystems.PerformanceMonitorTimeMeasurement"]["Measurements"];
		Msrmnt = Measurements[MeasurementUUID];
		
		If Msrmnt <> Undefined Then
			CompletedMeasurements = ApplicationParameters["StandardSubsystems.PerformanceMonitorTimeMeasurement"]["CompletedMeasurements"];
			MeasurementDetails.Insert("EndTime", Msrmnt["EndTime"]);
			CompletedMeasurements.Insert(MeasurementUUID, MeasurementDetails);
			Measurements.Delete(MeasurementUUID);
		EndIf;
	EndIf;
	
EndProcedure

#Region ObsoleteProceduresAndFunctions

// Obsolete. It will be removed in the next library version.
// Instead, use
//		PerformanceMonitorClient.TimeMeasurement
// Starts measuring the time for the key operation.
// The result is recorded in the TimeMeasurements information register.
// Since client measurements are stored in the client buffer and recorded at the intervals specified 
// in the PerformanceMonitorRecordingPeriod constant (every minute by default), some of the 
// measurements may be lost if the session is terminated.
//
// Parameters:
//	AutoStop - Boolean	 - 	indicates whether the measurement must be completed automatically.
//								True - the measurement will be completed automatically via the global idle handler.
//								
//								False - the measurement must be completed explicitly by calling
//								StopTimeMeasurement.
//	KeyOperation - String - key operation name. If Undefined, the key operation must be specified 
//								explicitly by calling
//								SetMeasurementKeyOperation.
//
// Returns:
//	UUID - a unique measurement ID.
//
Function StartTimeMeasurement(AutoStop = True, KeyOperation = Undefined) Export
	
	MeasurementUUID = New UUID("00000000-0000-0000-0000-000000000000");
	
	If RunPerformanceMeasurements() Then
		MeasurementUUID = New UUID();
		Parameters = New Structure;
		Parameters.Insert("KeyOperation", KeyOperation);
		Parameters.Insert("MeasurementUUID", MeasurementUUID);
		Parameters.Insert("AutoStop", AutoStop);
		Parameters.Insert("CompletedWithError", False);
				
		StartTimeMeasurementAtClientInternal(Parameters);
	EndIf;
		
	Return MeasurementUUID;
	
EndFunction

#EndRegion
#EndRegion

#Region Internal

////////////////////////////////////////////////////////////////////////////////
// Configuration subsystems event handlers.

// See CommonClientOverridable.BeforeStart. 
Procedure BeforeStart(Parameters) Export
	
	ParameterName = "StandardSubsystems.PerformanceMonitor.StartTime";
	StartTime = ApplicationParameters[ParameterName];
	ApplicationParameters.Delete(ParameterName);
	
	StartTimeMeasurementWithOffset(StartTime, True, "TotalApplicationStartTime");
	
EndProcedure

#EndRegion

#Region Private

// Starts measuring the time for the key operation.
// The result is recorded in the TimeMeasurements information register.
//
// Parameters:
//	Offset - Number	 	 - 	measurement start date and time in milliseconds (see CurrentUniversalDateInMilliseconds).
//	AutoStop - Boolean	 - 	indicates whether the measurement must be completed automatically.
//								True - the measurement will be completed automatically via the global idle handler.
//								
//								False - the measurement must be completed explicitly by calling
//								StopTimeMeasurement.
//	KeyOperation - String - key operation name. If Undefined, the key operation must be specified 
//								explicitly by calling
//								SetMeasurementKeyOperation.
//
// Returns:
//	UUID - a unique measurement ID.
//
Function StartTimeMeasurementWithOffset(Offset, AutoStop = True, KeyOperation = Undefined)
	
	MeasurementUUID = New UUID("00000000-0000-0000-0000-000000000000");
	
	If RunPerformanceMeasurements() Then
		MeasurementUUID = New UUID();
		Parameters = New Structure;
		Parameters.Insert("KeyOperation", KeyOperation);
		Parameters.Insert("MeasurementUUID", MeasurementUUID);
		Parameters.Insert("AutoStop", AutoStop);
		Parameters.Insert("CompletedWithError", False);
		Parameters.Insert("BeforeAfter", Offset);
				
		StartTimeMeasurementAtClientInternal(Parameters);
	EndIf;
		
	Return MeasurementUUID;
	
EndFunction

Function RunPerformanceMeasurements()
	
	RunPerformanceMeasurements = False;
	
	StandardSubsystemsParameterName = "StandardSubsystems.ClientParameters";
	
	If ApplicationParameters[StandardSubsystemsParameterName] = Undefined Then
		RunPerformanceMeasurements = PerformanceMonitorServerCallCached.RunPerformanceMeasurements();
	Else
		If ApplicationParameters[StandardSubsystemsParameterName].Property("PerformanceMonitor") Then
			RunPerformanceMeasurements = ApplicationParameters[StandardSubsystemsParameterName]["PerformanceMonitor"]["RunPerformanceMeasurements"];
		Else
			RunPerformanceMeasurements = PerformanceMonitorServerCallCached.RunPerformanceMeasurements();
		EndIf;
	EndIf;
	
	Return RunPerformanceMeasurements; 
	
EndFunction

Procedure StartTimeMeasurementAtClientInternal(Parameters)
    
    StartTime = CurrentUniversalDateInMilliseconds();
    
	If ApplicationParameters = Undefined Then
		ApplicationParameters = New Map;
	EndIf;
		
	ParameterName = "StandardSubsystems.PerformanceMonitorTimeMeasurement";
	If ApplicationParameters[ParameterName] = Undefined Then
		ApplicationParameters.Insert(ParameterName, New Structure);
		ApplicationParameters[ParameterName].Insert("Measurements", New Map);
		ApplicationParameters[ParameterName].Insert("CompletedMeasurements", New Map);
		ApplicationParameters[ParameterName].Insert("HasHandler", False);
		ApplicationParameters[ParameterName].Insert("HandlerAttachmentTime", StartTime);
		
		StandardSubsystemsParameterName = "StandardSubsystems.ClientParameters";
		If ApplicationParameters[StandardSubsystemsParameterName] = Undefined Then
			PerformanceMonitorParameters = PerformanceMonitorServerCall.GetParametersAtServer();
			CurrentRecordingPeriod = PerformanceMonitorParameters.RecordPeriod;
			DateAndTimeAtServer = PerformanceMonitorParameters.DateAndTimeAtServer;
		
			// Getting the date in UTC
			DateAndTimeAtClient = CurrentUniversalDateInMilliseconds();
			ApplicationParameters[ParameterName].Insert("ClientDateOffset", DateAndTimeAtServer - DateAndTimeAtClient);
		Else
			StandardSubsystemsApplicationParameters = ApplicationParameters[StandardSubsystemsParameterName];
			If StandardSubsystemsApplicationParameters.Property("PerformanceMonitor") Then
				CurrentRecordingPeriod = StandardSubsystemsApplicationParameters["PerformanceMonitor"]["RecordPeriod"];
				ApplicationParameters[ParameterName].Insert("ClientDateOffset", StandardSubsystemsApplicationParameters["ClientDateOffset"]);
			Else
				PerformanceMonitorParameters = PerformanceMonitorServerCall.GetParametersAtServer();
				CurrentRecordingPeriod = PerformanceMonitorParameters.RecordPeriod;
				DateAndTimeAtServer = PerformanceMonitorParameters.DateAndTimeAtServer;
				
				// Getting the date in UTC
				DateAndTimeAtClient = CurrentUniversalDateInMilliseconds();
				ApplicationParameters[ParameterName].Insert("ClientDateOffset", DateAndTimeAtServer - DateAndTimeAtClient);
			EndIf;
		EndIf;
				
		UserAgentInformation = "";
		#If ThickClientManagedApplication Then
			UserAgentInformation = "ThickClientManagedApplication";
		#ElsIf ThickClientOrdinaryApplication Then
			UserAgentInformation = "ThickClient";
		#ElsIf ThinClient Then
			UserAgentInformation = "ThinClient";
		#ElsIf WebClient Then
			ClientInfo = New SystemInfo();
			UserAgentInformation = ClientInfo.UserAgentInformation;
		#EndIf
		ApplicationParameters[ParameterName].Insert("UserAgentInformation", UserAgentInformation);
						
		AttachIdleHandler("WriteResultsAuto", CurrentRecordingPeriod, True);
	EndIf;
	
	// Actual start of time measurement on the client.
	// Cannot be moved up because ApplicationParameters are not yet initialized when measuring the 
	// application startup time.
	//
	
	If Parameters.Property("BeforeAfter") Then
		StartTime = Parameters.BeforeAfter + ApplicationParameters[ParameterName]["ClientDateOffset"];;
	Else
		StartTime = StartTime + ApplicationParameters[ParameterName]["ClientDateOffset"];
	EndIf;
		
	KeyOperation = Parameters.KeyOperation;
	MeasurementUUID = Parameters.MeasurementUUID;
	AutoStop = Parameters.AutoStop;
	
	If Parameters.Property("Comment") Then
		Comment = Parameters.Comment;
	Else
		Comment = Undefined;
	EndIf;
	
	If Parameters.Property("Technological") Then
		Technological = Parameters.Technological;
	Else
		Technological = False;
	EndIf;
	
	If Parameters.Property("CompletedWithError") Then
		CompletedWithError = Parameters.CompletedWithError;
	Else
		CompletedWithError = False;
	EndIf;
	
	Measurements = ApplicationParameters[ParameterName]["Measurements"]; 
	Measurements.Insert(MeasurementUUID, New Map);
	Msrmnt = Measurements[MeasurementUUID];
	Msrmnt.Insert("KeyOperation", KeyOperation);
	Msrmnt.Insert("AutoStop", AutoStop);
	Msrmnt.Insert("BeginTime", StartTime);
	Msrmnt.Insert("Comment", Comment);
	Msrmnt.Insert("CompletedWithError", CompletedWithError);
	Msrmnt.Insert("Technological", Technological);
	Msrmnt.Insert("MeasurementWeight", 1);
	
	If AutoStop Then
		If NOT ApplicationParameters[ParameterName]["HasHandler"] Then
			AttachIdleHandler("EndTimeMeasurementAuto", 0.1, True);
			ApplicationParameters[ParameterName]["HasHandler"] = True;
			ApplicationParameters[ParameterName]["HandlerAttachmentTime"] = CurrentUniversalDateInMilliseconds() + ApplicationParameters[ParameterName]["ClientDateOffset"];
		EndIf;	
	EndIf;	
	
EndProcedure

// Automatically completes a time measurement on the client.
//
Procedure StopTimeMeasurementAtClientAuto() Export
	
	EndTime = CurrentUniversalDateInMilliseconds();
	
	PerformanceMonitorTimeMeasurement = ApplicationParameters["StandardSubsystems.PerformanceMonitorTimeMeasurement"];
	HandlerAttachmentTime = PerformanceMonitorTimeMeasurement["HandlerAttachmentTime"];
		
    If PerformanceMonitorTimeMeasurement <> Undefined Then
        
        Measurements = ApplicationParameters["StandardSubsystems.PerformanceMonitorTimeMeasurement"]["Measurements"];
		CompletedMeasurements = ApplicationParameters["StandardSubsystems.PerformanceMonitorTimeMeasurement"]["CompletedMeasurements"];
		
		ToDelete = New Array;
        
        IncompleteAutoMeasurementsCount = 0;
		For Each Msrmnt In Measurements Do
			MeasurementValue = Msrmnt.Value;
            If MeasurementValue["AutoStop"] Then 
				If MeasurementValue["BeginTime"] <= HandlerAttachmentTime AND MeasurementValue["EndTime"] = Undefined Then
					// If there are nested measurements, record the last step.
					If MeasurementValue["NestedMeasurements"] <> Undefined
						AND MeasurementValue["NestedMeasurements"].Count() Then
						FixTimeConsumingOperationMeasure(MeasurementValue, 1, MeasurementValue["LastStepName"]);
					EndIf;
					
                    // The client's date offset is calculated within the procedure.
                    StopTimeMeasurementInternal(Msrmnt.Key, EndTime);
                    If ValueIsFilled(Msrmnt.Value["KeyOperation"]) Then
                        CompletedMeasurements.Insert(Msrmnt.Key, Msrmnt.Value);
                    EndIf;
                    ToDelete.Add(Msrmnt.Key);
                Else
                    IncompleteAutoMeasurementsCount = IncompleteAutoMeasurementsCount + 1;
                EndIf;
            EndIf;
		EndDo;
		
		For Each CurMeasurement In ToDelete Do
			Measurements.Delete(CurMeasurement);
		EndDo;
	EndIf;
	
	If IncompleteAutoMeasurementsCount = 0 Then
		PerformanceMonitorTimeMeasurement["HasHandler"] = False;
	Else
		AttachIdleHandler("EndTimeMeasurementAuto", 0.1, True);
		PerformanceMonitorTimeMeasurement["HasHandler"] = True;
		PerformanceMonitorTimeMeasurement["HandlerAttachmentTime"] = CurrentUniversalDateInMilliseconds() + PerformanceMonitorTimeMeasurement["ClientDateOffset"];
	EndIf;
EndProcedure

Procedure StopTimeMeasurementInternal(MeasurementUUID, Val EndTime)
		
	If PerformanceMonitorServerCallCached.RunPerformanceMeasurements() Then
		PerformanceMonitorTimeMeasurement = ApplicationParameters["StandardSubsystems.PerformanceMonitorTimeMeasurement"];
		If PerformanceMonitorTimeMeasurement <> Undefined Then
			ClientDateOffset = ApplicationParameters["StandardSubsystems.PerformanceMonitorTimeMeasurement"]["ClientDateOffset"];
			EndTime = EndTime + ClientDateOffset;
			
			Measurements = ApplicationParameters["StandardSubsystems.PerformanceMonitorTimeMeasurement"]["Measurements"];
			Msrmnt = Measurements[MeasurementUUID];
			If Msrmnt <> Undefined Then
				Msrmnt.Insert("EndTime", EndTime);
			EndIf;
		EndIf;
	EndIf;
	
EndProcedure

// Records accumulated key operation time measurements on the server.
//
// Parameters:
//  BeforeCompletion - Boolean - True if the method is called before the application is closed.
//
Procedure WriteResultsAutoNotGlobal(BeforeCompletion = False) Export
	
	PerformanceMonitorTimeMeasurement = ApplicationParameters["StandardSubsystems.PerformanceMonitorTimeMeasurement"];
	
	If PerformanceMonitorTimeMeasurement <> Undefined Then
		CompletedMeasurements = PerformanceMonitorTimeMeasurement["CompletedMeasurements"];
		PerformanceMonitorTimeMeasurement["CompletedMeasurements"] = New Map;
		
		MeasurementsToWrite = New Structure;
		MeasurementsToWrite.Insert("CompletedMeasurements", CompletedMeasurements);
		MeasurementsToWrite.Insert("UserAgentInformation", PerformanceMonitorTimeMeasurement["UserAgentInformation"]);
		NewRecordingPeriod = PerformanceMonitorServerCall.RecordKeyOperationsDuration(MeasurementsToWrite);
				
		AttachIdleHandler("WriteResultsAuto", NewRecordingPeriod, True);
	EndIf;
	
EndProcedure

#EndRegion