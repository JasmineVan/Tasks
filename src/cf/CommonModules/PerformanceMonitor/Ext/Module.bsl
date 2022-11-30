///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Public

// Starts measuring the time for the key operation. Time measurement must be completed explicitly by 
// calling EndTimeMeasurement or EndTechnologicalTimeMeasurement.
//
// Returns:
//	Number (14.0) - start time in UTC, accurate to the nearest millisecond.
//
Function StartTimeMeasurement() Export
	
	StartTime = 0;
	
	If PerformanceMonitorServerCallCached.RunPerformanceMeasurements() Then
		StartTime = CurrentUniversalDateInMilliseconds();
	EndIf;
	
	Return StartTime;
	
EndFunction

// Ends time measurement for the key operation and writes the result to the TimeMeasurements 
// information register.
//
// Parameters:
// 	KeyOperation	- CatalogRef.KeyOperations, String	- key operation.
//	StartTime			- Number										- universal date (in milliseconds) returned at the beginning of 
//								  				  					  measurement by the PerformanceMonitor.StartTimeMeasurement function.
//	MeasurementWeight			- Number										- a quantitative indicator of the measurement, such as number of rows in a document.
//	Comment			- String, Map						- arbitrary information about the measurement.
//  CompletedWithError	- Boolean									- indicates that the measurement was not completed to the end,
//
Procedure EndTimeMeasurement(KeyOperation, StartTime, MeasurementWeight = 1, Comment = Undefined, CompletedWithError = False) Export
	If PerformanceMonitorServerCallCached.RunPerformanceMeasurements() Then	
		EndTime = CurrentUniversalDateInMilliseconds();
		Duration = (EndTime - StartTime)/1000;
		
		MeasurementParameters = New Structure;
		MeasurementParameters.Insert("KeyOperation", KeyOperation);
		MeasurementParameters.Insert("Duration", Duration);
		MeasurementParameters.Insert("KeyOperationStartDate", StartTime);
		MeasurementParameters.Insert("KeyOperationEndDate", EndTime);
		MeasurementParameters.Insert("MeasurementWeight", MeasurementWeight);
		MeasurementParameters.Insert("Comment", Comment);
		MeasurementParameters.Insert("Technological", False);
		MeasurementParameters.Insert("TimeConsuming", False);
		MeasurementParameters.Insert("CompletedWithError", CompletedWithError);
		
		RecordKeyOperationDuration(MeasurementParameters);
	EndIf;
EndProcedure

// Completes measuring the time of a key operation and writes the result to the 
// TimeMeasurementsTechnological information register.
//
// Parameters:
// 	KeyOperation	- CatalogRef.KeyOperations, String - key operation.
//	StartTime			- Number										- universal date (in milliseconds) returned at the beginning of 
//								  				  					  measurement by the PerformanceMonitor.StartTimeMeasurement function.
//	MeasurementWeight			- Number										- a quantitative indicator of the measurement, such as number of rows in a document.
//	Comment			- String, Map						- arbitrary information about the measurement.
//
Procedure EndTechnologicalTimeMeasurement(KeyOperation, StartTime, MeasurementWeight = 1, Comment = Undefined) Export
	If PerformanceMonitorServerCallCached.RunPerformanceMeasurements() Then	
		EndTime = CurrentUniversalDateInMilliseconds();
		Duration = (EndTime - StartTime)/1000;
		
		MeasurementParameters = New Structure;
		MeasurementParameters.Insert("KeyOperation", KeyOperation);
		MeasurementParameters.Insert("Duration", Duration);
		MeasurementParameters.Insert("KeyOperationStartDate", StartTime);
		MeasurementParameters.Insert("KeyOperationEndDate", EndTime);
		MeasurementParameters.Insert("MeasurementWeight", MeasurementWeight);
		MeasurementParameters.Insert("Comment", Comment);
		MeasurementParameters.Insert("Technological", True);
		MeasurementParameters.Insert("TimeConsuming", False);
		MeasurementParameters.Insert("CompletedWithError", False);
		
		RecordKeyOperationDuration(MeasurementParameters);
	EndIf;
EndProcedure

// Creates key operations if they are not available.
//
// Parameters:
//  KeyOperations - Array - key operations; each array element is a Structure("KeyOperationName, ResponseTimeThreshold").
//
Procedure CreateKeyOperations(KeyOperations) Export
	Query = New Query;
	Query.Text = "SELECT TOP 1
	               |	KeyOperations.Ref AS Ref
	               |FROM
	               |	Catalog.KeyOperations AS KeyOperations
	               |WHERE
	               |	KeyOperations.Name = &Name
	               |ORDER BY
	               |	Ref";
				   
	For Each KeyOperation In KeyOperations Do
		Query.SetParameter("Name", KeyOperation.KeyOperationName);
		QueryResult = Query.Execute();
		If QueryResult.IsEmpty() Then
			CreateKeyOperation(KeyOperation.KeyOperationName, KeyOperation.ResponseTimeThreshold);
		EndIf;
	EndDo;
EndProcedure

// Sets a new time threshold for a key operation.
//
// Parameters:
//  KeyOperations - Array - key operations; each array element is a Structure("KeyOperationName, ResponseTimeThreshold").
//
Procedure SetTimeThreshold (KeyOperations) Export
	
	Query = New Query;
	Query.Text = "SELECT TOP 1
	|	KeyOperations.Ref AS Ref
	|FROM
	|	Catalog.KeyOperations AS KeyOperations
	|WHERE
	|	KeyOperations.Name = &Name
	|ORDER BY
	|	Ref";
		
	BeginTransaction();
	Try
		
		Lock = New DataLock;
		For Each KeyOperation In KeyOperations Do
			LockItem = Lock.Add("Catalog.KeyOperations");
			LockItem.Mode = DataLockMode.Exclusive;
			LockItem.SetValue("Name", KeyOperation.KeyOperationName);
		EndDo;
		Lock.Lock();
		
		For Each KeyOperation In KeyOperations Do
			Query.SetParameter("Name", KeyOperation.KeyOperationName);
			QueryResult = Query.Execute();
			If NOT QueryResult.IsEmpty() Then
				Selection = QueryResult.Select();
                Selection.Next();
				KeyOperationRef = Selection.Ref;
				KeyOperationObject = KeyOperationRef.GetObject();
				KeyOperationObject.ResponseTimeThreshold = KeyOperation.ResponseTimeThreshold;
				
				KeyOperationObject.Write();
			EndIf;
		EndDo;
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;
	
EndProcedure

// Modifies key operations.
//
// Parameters:
//  KeyOperations - Array - key operations; each array element is a Structure("KeyOperationNameOld, 
//								KeyOperationNameNew , ResponseTimeThreshold") or a Structure("KeyOperationNameOld, 
//								KeyOperationNameNew"); does not change the time threshold.
//								
//								
//
Procedure ChangeKeyOperations(KeyOperations) Export
	
	Query = New Query;
	Query.Text = "SELECT TOP 1
	|	KeyOperations.Ref AS Ref
	|FROM
	|	Catalog.KeyOperations AS KeyOperations
	|WHERE
	|	KeyOperations.Name = &Name
	|ORDER BY
	|	Ref";
		
	BeginTransaction();
	Try
		
		Lock = New DataLock;
		For Each KeyOperation In KeyOperations Do
			LockItem = Lock.Add("Catalog.KeyOperations");
			LockItem.Mode = DataLockMode.Exclusive;
			LockItem.SetValue("Name", KeyOperation.KeyOperationNameOld);
			LockItem = Lock.Add("Catalog.KeyOperations");
			LockItem.Mode = DataLockMode.Exclusive;
			LockItem.SetValue("Name", KeyOperation.KeyOperationNameNew);
		EndDo;
		Lock.Lock();
		
		For Each KeyOperation In KeyOperations Do
			Query.SetParameter("Name", KeyOperation.KeyOperationNameOld);
			QueryResult = Query.Execute();
			If NOT QueryResult.IsEmpty() Then
				Selection = QueryResult.Select();
                Selection.Next();
				KeyOperationRef = Selection.Ref;
				KeyOperationObject = KeyOperationRef.GetObject();
				KeyOperationObject.Name = KeyOperation.KeyOperationNameNew;
                KeyOperationObject.Description = SplitStringByWords(KeyOperation.KeyOperationNameNew); 
				If KeyOperation.Property("ResponseTimeThreshold") Then
					KeyOperationObject.ResponseTimeThreshold = KeyOperation.ResponseTimeThreshold;
				EndIf;
				
				KeyOperationObject.Write();
			EndIf;
		EndDo;
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;
	
EndProcedure

// Starts measuring the time of a time-consuming key operation. You must complete the measurement 
// explicitly by calling the EndTimeConsumingOperationMeasurement procedure.
//
// Parameters:
// 	KeyOperation	- String - key operation.
//
// Returns:
// 	MeasurementDetails - Map.
//   KeyOperation - name of the key operation.
//   StartTime - key operation start time in milliseconds.
//   LastMeasurementTime - time of the last key operation measurement in milliseconds.
//   MeasurementWeight - amount of data processed during execution.
//   NestedMeasurements - collection of nested step measurements.
//
Function StartTimeConsumingOperationMeasurement(KeyOperation) Export
	
	MeasurementDetails = New Map;
	If PerformanceMonitorServerCallCached.RunPerformanceMeasurements() Then
		StartTime = CurrentUniversalDateInMilliseconds();
		MeasurementDetails.Insert("KeyOperation", KeyOperation);
		MeasurementDetails.Insert("BeginTime", StartTime);
		MeasurementDetails.Insert("LastMeasurementTime", StartTime);
		MeasurementDetails.Insert("MeasurementWeight", 0);
		MeasurementDetails.Insert("NestedMeasurements", New Map);
	EndIf;
	
	Return MeasurementDetails;
	
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
	
	Duration = CurrentTime - MeasurementDetails["LastMeasurementTime"];
	DataVolumeInStep = ?(DataVolume = 0, 1, DataVolume);
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
	
	If NOT ValueIsFilled(MeasurementDetails) Then
		Return;
	EndIf;
	
	If MeasurementDetails["Client"] = True Then
		Return;
	EndIf;
	
	// Variables from the measurement details.
	MeasurementStartTime	 = MeasurementDetails["BeginTime"];
	KeyOperationName	 = MeasurementDetails["KeyOperation"];
	NestedMeasurements		 = MeasurementDetails["NestedMeasurements"];
	
	// Calculated variables
	NestedMeasurementsAvailable = NestedMeasurements.Count();
	CurrentTime = CurrentUniversalDateInMilliseconds();
	Duration = CurrentTime - MeasurementStartTime;
	WeightedTimeTotal = 0;
	
	// If no step name is specified, but there are nested steps, the default name is "LastStep".
	DataVolumeInStep = ?(DataVolume = 0, 1, DataVolume);
	If NestedMeasurementsAvailable Then                                      		
		FixTimeConsumingOperationMeasure(MeasurementDetails, DataVolumeInStep, ?(IsBlankString(StepName), "LastStep", StepName), Comment);
	EndIf;
	                                  	
	MeasurementsArrayToWrite = New Array;	
	
	For Each Msrmnt In NestedMeasurements Do
		MeasurementData = Msrmnt.Value; 
		NestedMeasurementWeight = MeasurementData["MeasurementWeight"];
		NestedMeasurementDuration = MeasurementData["Duration"];
		KeyOperation = KeyOperationName + "." + Msrmnt.Key;
		WeightedTime = ?(NestedMeasurementWeight = 0, NestedMeasurementDuration, NestedMeasurementDuration / NestedMeasurementWeight);
		WeightedTimeTotal = WeightedTimeTotal + WeightedTime;
		
		MeasurementParameters = New Structure;
		MeasurementParameters.Insert("KeyOperation", KeyOperation);
		MeasurementParameters.Insert("Duration", WeightedTime/1000);
		MeasurementParameters.Insert("KeyOperationStartDate", MeasurementData["BeginTime"]);
		MeasurementParameters.Insert("KeyOperationEndDate", MeasurementData["EndTime"]);
		MeasurementParameters.Insert("MeasurementWeight", NestedMeasurementWeight);
		MeasurementParameters.Insert("Comment", MeasurementData["Comment"]);
		MeasurementParameters.Insert("Technological", False);
		MeasurementParameters.Insert("TimeConsuming", True);
		
		MeasurementsArrayToWrite.Add(MeasurementParameters);
	EndDo;
	
	// Committing the key operation's weighted time.
	MeasurementParameters = New Structure;
	MeasurementParameters.Insert("KeyOperation", KeyOperationName + ".Specific");
	MeasurementParameters.Insert("KeyOperationStartDate", MeasurementStartTime);
	MeasurementParameters.Insert("KeyOperationEndDate", CurrentTime);
	MeasurementParameters.Insert("Comment", Comment);
	MeasurementParameters.Insert("Technological", False);
	MeasurementParameters.Insert("TimeConsuming", True);
		
	If NestedMeasurementsAvailable Then
		MeasurementParameters.Insert("Duration", WeightedTimeTotal/1000);
		MeasurementParameters.Insert("MeasurementWeight", MeasurementDetails["MeasurementWeight"]);		
	Else
		// If there were no nested measurements, recording the weighted measurement.
		MeasurementParameters.Insert("Duration", Duration/1000/DataVolumeInStep);
		MeasurementParameters.Insert("MeasurementWeight", DataVolumeInStep);
	EndIf;
	MeasurementsArrayToWrite.Add(MeasurementParameters);
	
	// Recording a time-consuming key operation.
	MeasurementParameters = New Structure;
	MeasurementParameters.Insert("KeyOperation", KeyOperationName);
	MeasurementParameters.Insert("Duration", (Duration)/1000);
	MeasurementParameters.Insert("KeyOperationStartDate", MeasurementStartTime);
	MeasurementParameters.Insert("KeyOperationEndDate", CurrentTime);
	If NestedMeasurementsAvailable Then
		MeasurementParameters.Insert("MeasurementWeight", MeasurementDetails["MeasurementWeight"]);
	Else
		MeasurementParameters.Insert("MeasurementWeight", DataVolumeInStep);		
	EndIf;
	MeasurementParameters.Insert("Comment", Comment);
	MeasurementParameters.Insert("Technological", False);
	MeasurementParameters.Insert("TimeConsuming", False);
	
	MeasurementsArrayToWrite.Add(MeasurementParameters);	
	
	WriteTimeMeasurements(MeasurementsArrayToWrite);
	
EndProcedure

#Region ObsoleteProceduresAndFunctions

// Obsolete. It will be removed in the next library version.
// Sets an error flag for a key operation.
//
// Parameters:
//  KeyOperations - Array - key operations; each array element is a Structure("KeyOperationName, Flag").
//
Procedure SetCompletedWithErrorFlag(KeyOperations) Export
	
	Query = New Query;
	Query.Text = "SELECT TOP 1
	|	KeyOperations.Ref AS Ref
	|FROM
	|	Catalog.KeyOperations AS KeyOperations
	|WHERE
	|	KeyOperations.Name = &Name
	|ORDER BY
	|	Ref";
		
	BeginTransaction();
	Try
		
		Lock = New DataLock;
		For Each KeyOperation In KeyOperations Do
			LockItem = Lock.Add("Catalog.KeyOperations");
			LockItem.Mode = DataLockMode.Exclusive;
			LockItem.SetValue("Name", KeyOperation.KeyOperationName);
		EndDo;
		Lock.Lock();
		
		For Each KeyOperation In KeyOperations Do
			Query.SetParameter("Name", KeyOperation.KeyOperationName);
			QueryResult = Query.Execute();
			If NOT QueryResult.IsEmpty() Then
				Selection = QueryResult.Select();
                Selection.Next();
				KeyOperationRef = Selection.Ref;
				KeyOperationObject = KeyOperationRef.GetObject();
				KeyOperationObject.OperationFailed = KeyOperation.Flag;
				
				KeyOperationObject.Write();
			EndIf;
		EndDo;
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;
	
EndProcedure

#EndRegion

#EndRegion

#Region Internal

// Enables or disables performance measurements.
//
Procedure EnablePerformanceMeasurements(Parameter) Export
	
	Constants.RunPerformanceMeasurements.Set(Parameter);
	
EndProcedure

#EndRegion

#Region Private

// Creates an element in the "Key operations" catalog.
//
// Parameters:
//  KeyOperationName - String - key operation name.
//	ResponseTimeThreshold - Number - a response time threshold for the key operation.
//	TimeConsuming - Boolean - indicates recording weighted time for the key operation measurement.
//
// Returns:
//	CatalogRef.KeyOperations.
//
Function CreateKeyOperation(KeyOperationName, ResponseTimeThreshold = 1, TimeConsuming = False) Export
	
	SetPrivilegedMode(True);
	
	BeginTransaction();
	
	Try
		Lock = New DataLock;
		LockItem = Lock.Add("Catalog.KeyOperations");
		LockItem.SetValue("Name", KeyOperationName);
		Lock.Lock();
		
		Query = New Query;
		Query.Text = "SELECT TOP 1
		               |	KeyOperations.Ref AS Ref
		               |FROM
		               |	Catalog.KeyOperations AS KeyOperations
		               |WHERE
		               |	KeyOperations.NameHash = &NameHash
		               |
		               |ORDER BY
		               |	Ref";
		
		MD5Hash = New DataHashing(HashFunction.MD5);
		MD5Hash.Append(KeyOperationName);
		NameHash = MD5Hash.HashSum;
		NameHash = StrReplace(String(NameHash), " ", "");			   
					   
		Query.SetParameter("NameHash", NameHash);
		QueryResult = Query.Execute();
		If QueryResult.IsEmpty() Then
			Description = SplitStringByWords(KeyOperationName);
			
			NewItem = Catalogs.KeyOperations.CreateItem();
			NewItem.Name = KeyOperationName;
			NewItem.Description = Description;
			NewItem.ResponseTimeThreshold = ResponseTimeThreshold;
			NewItem.TimeConsuming = TimeConsuming;
			NewItem.Write();
			KeyOperationRef = NewItem.Ref;
		Else
			Selection = QueryResult.Select();
			Selection.Next();
			KeyOperationRef = Selection.Ref;
		EndIf;
		
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;
	
	Return KeyOperationRef;
	
EndFunction

// Splits a string of several merged words into a string with separated words.
// A sign of new word beginning is an uppercase letter.
//
// Parameters:
//  String                 - String - delimited text;
//
// Returns:
//  String - string split into words.
//
// Examples:
//  SplitStringByWords("OneTwoThree") returns "One two three".
//	SplitStringByWords("onetwothree") - returns "onetwothree".
//
Function SplitStringByWords(Val Row)
	
	WordArray = New Array;
	
	WordPositions = New Array;
	For CharPosition = 1 To StrLen(Row) Do
		CurChar = Mid(Row, CharPosition, 1);
		If CurChar = Upper(CurChar) 
			AND (PerformanceMonitorClientServer.OnlyLatinInString(CurChar) 
				Or PerformanceMonitorClientServer.OnlyRomanInString(CurChar)) Then
			WordPositions.Add(CharPosition);
		EndIf;
	EndDo;
	
	If WordPositions.Count() > 0 Then
		PreviousPosition = 0;
		For Each Position In WordPositions Do
			If PreviousPosition > 0 Then
				Substring = Mid(Row, PreviousPosition, Position - PreviousPosition);
				If Not IsBlankString(Substring) Then
					WordArray.Add(TrimAll(Substring));
				EndIf;
			EndIf;
			PreviousPosition = Position;
		EndDo;
		
		Substring = Mid(Row, Position);
		If Not IsBlankString(Substring) Then
			WordArray.Add(TrimAll(Substring));
		EndIf;
	EndIf;
	
	For Index = 1 To WordArray.UBound() Do
		WordArray[Index] = Lower(WordArray[Index]);
	EndDo;
	
	If WordArray.Count() <> 0 Then
		Result = StrConcat(WordArray, " ");
	Else
		Result = Row;
	EndIf;
		
	Return Result;
	
EndFunction

// Returns the period of writing performance measurement results on the server.
//
// Returns:
//   Number - value in seconds.
//
Function RecordPeriod() Export
	CurrentPeriod = Constants.PerformanceMonitorRecordPeriod.Get();
	Return ?(CurrentPeriod >= 1, CurrentPeriod, 60);
EndFunction

// Writes a single measurement
//
// Parameters:
//  KeyOperation - CatalogRef.KeyOperations - key operation or String - key operation name
//						
//  Duration - Number
//  KeyOperationStartDate - Date.
//
Procedure RecordKeyOperationDuration(Parameters)
	
	KeyOperation				 = Parameters.KeyOperation;
	Duration					 = Parameters.Duration;
	KeyOperationStartDate		 = Parameters.KeyOperationStartDate;
	KeyOperationEndDate	 = Parameters.KeyOperationEndDate;
	MeasurementWeight						 = Parameters.MeasurementWeight;
	Comment						 = Parameters.Comment;
	Technological					 = Parameters.Technological;
	TimeConsuming						 = Parameters.TimeConsuming;
	CompletedWithError				 = Parameters.CompletedWithError;
	
	DefaultLanguageCode = Common.DefaultLanguageCode();
	
	If SafeMode() <> False Then
		WriteLogEvent(NStr("ru = 'Работа подсистемы оценка производительности в безопасном режиме не поддерживается'; en = 'Performance assessment subsystem is not supported in the safe mode'; pl = 'Performance assessment subsystem is not supported in the safe mode';de = 'Performance assessment subsystem is not supported in the safe mode';ro = 'Performance assessment subsystem is not supported in the safe mode';tr = 'Performance assessment subsystem is not supported in the safe mode'; es_ES = 'Performance assessment subsystem is not supported in the safe mode'", DefaultLanguageCode),
			EventLogLevel.Information,,,String(KeyOperation));
			
		Return;
	EndIf;
	
	If Not ValueIsFilled(KeyOperationStartDate) Then
		WriteLogEvent(NStr("ru = 'Невозможно зафиксировать замер с пустой датой начала'; en = 'Cannot commit measurement with empty start date'; pl = 'Cannot commit measurement with empty start date';de = 'Cannot commit measurement with empty start date';ro = 'Cannot commit measurement with empty start date';tr = 'Cannot commit measurement with empty start date'; es_ES = 'Cannot commit measurement with empty start date'", DefaultLanguageCode),
			EventLogLevel.Information,,,String(KeyOperation));
			
		Return;
	EndIf;
	
	SetPrivilegedMode(True);
		
	If TypeOf(KeyOperation) = Type("String") Then
		KeyOperationRef = PerformanceMonitorCached.GetKeyOperationByName(KeyOperation, TimeConsuming);
	Else
		KeyOperationRef = KeyOperation;
	EndIf;
	
	If Comment = Undefined Then
		Comment = SessionParameters.TimeMeasurementComment;
	Else
		JSONReader = New JSONReader();
		JSONReader.SetString(SessionParameters.TimeMeasurementComment);
		DefaultComment = ReadJSON(JSONReader, True);
		DefaultComment.Insert("AddlInf", Comment);
		
		JSONWriter = New JSONWriter;
		JSONWriter.SetString(New JSONWriterSettings(JSONLineBreak.None));
		WriteJSON(JSONWriter, DefaultComment);
		Comment = JSONWriter.Close();
	EndIf;
	
	If NOT Technological Then
		Record = InformationRegisters.TimeMeasurements.CreateRecordManager();
	Else
		Record = InformationRegisters.TimeMeasurementsTechnological.CreateRecordManager();
	EndIf;
	
	Record.KeyOperation = KeyOperationRef;
	
	// Getting the date in UTC
	Record.MeasurementStartDate = KeyOperationStartDate;
	Record.SessionNumber = InfoBaseSessionNumber();
		
	Record.RunTime = ?(Duration = 0, 0.001, Duration); // Duration is less than timer resolution.
	Record.MeasurementWeight = MeasurementWeight;
	
	Record.RecordDate = Date(1,1,1) + CurrentUniversalDateInMilliseconds()/1000;
	Record.RecordDateBegOfHour = BegOfHour(Record.RecordDate);
	If KeyOperationEndDate <> Undefined Then
		// Getting the date in UTC
		Record.EndDate = KeyOperationEndDate;
	EndIf;
	Record.User = InfoBaseUsers.CurrentUser();
	Record.RecordDateLocal = CurrentSessionDate();
	Record.Comment = Comment;
	If NOT Technological Then
		Record.CompletedWithError = CompletedWithError;
	EndIf;
	
	Record.Write();
	
EndProcedure

// Writes an array of measurements.
// Each array element is a structure.
// Records are made in sets.
//   KeyOperation - name of the key operation.
//   Duration - duration in milliseconds.
//   KeyOperationStartDate - key operation start time in milliseconds.
//   KeyOperationEndDate - key operation end time in milliseconds.
//   Comment - any comment to the measurement.
//   MeasurementWeight - amount of data processed.
//   TimeConsuming - indicates whether the measurement duration is calculated per weight unit.
//
Procedure WriteTimeMeasurements(MeasurementsArray)
	
	If ExclusiveMode() Then
		Return;
	EndIf;
	
	DefaultLanguageCode = Common.DefaultLanguageCode();
	
	If SafeMode() <> False Then
		WriteLogEvent(NStr("ru = 'Работа подсистемы оценка производительности в безопасном режиме не поддерживается'; en = 'Performance assessment subsystem is not supported in the safe mode'; pl = 'Performance assessment subsystem is not supported in the safe mode';de = 'Performance assessment subsystem is not supported in the safe mode';ro = 'Performance assessment subsystem is not supported in the safe mode';tr = 'Performance assessment subsystem is not supported in the safe mode'; es_ES = 'Performance assessment subsystem is not supported in the safe mode'", DefaultLanguageCode),
			EventLogLevel.Information);
		Return;
	EndIf;
	
	SetPrivilegedMode(True);
	
	RecordSet = InformationRegisters.TimeMeasurements.CreateRecordSet();
	SessionNumber = InfoBaseSessionNumber();
	RecordDate = Date(1,1,1) + CurrentUniversalDateInMilliseconds()/1000;
	RecordDateBegOfHour = BegOfHour(RecordDate);
	User = InfoBaseUsers.CurrentUser();
	RecordDateLocal = CurrentSessionDate();
	
	For Each Msrmnt In MeasurementsArray Do
		
		If Not ValueIsFilled(Msrmnt.KeyOperationStartDate) Then
			WriteLogEvent(NStr("ru = 'Невозможно зафиксировать замер с пустой датой начала'; en = 'Cannot commit measurement with empty start date'; pl = 'Cannot commit measurement with empty start date';de = 'Cannot commit measurement with empty start date';ro = 'Cannot commit measurement with empty start date';tr = 'Cannot commit measurement with empty start date'; es_ES = 'Cannot commit measurement with empty start date'", DefaultLanguageCode),
				EventLogLevel.Information,,,String(Msrmnt.KeyOperation));
			Return;
		EndIf;
		
		If TypeOf(Msrmnt.KeyOperation) = Type("String") Then
			KeyOperationRef = PerformanceMonitorCached.GetKeyOperationByName(Msrmnt.KeyOperation, Msrmnt.TimeConsuming);
		Else
			KeyOperationRef = Msrmnt.KeyOperation;
		EndIf;
		
		If Not ValueIsFilled(Msrmnt.Comment) Then
			Comment = SessionParameters.TimeMeasurementComment;
		Else
			JSONReader = New JSONReader();
			JSONReader.SetString(SessionParameters.TimeMeasurementComment);
			DefaultComment = ReadJSON(JSONReader, True);
			DefaultComment.Insert("AddlInf", Msrmnt.Comment);
			
			JSONWriter = New JSONWriter;
			JSONWriter.SetString(New JSONWriterSettings(JSONLineBreak.None));
			WriteJSON(JSONWriter, DefaultComment);
			Comment = JSONWriter.Close();
		EndIf;
		
		Record = RecordSet.Add();	
		
		Record.KeyOperation = KeyOperationRef;
	
		// Getting the date in UTC
		Record.MeasurementStartDate = Msrmnt.KeyOperationStartDate;
		Record.SessionNumber = SessionNumber;
			
		Record.RunTime = ?(Msrmnt.Duration = 0, 0.001, Msrmnt.Duration); // Duration is less than timer resolution.
		Record.MeasurementWeight = Msrmnt.MeasurementWeight;
		
		Record.RecordDate = RecordDate;
		Record.RecordDateBegOfHour = RecordDateBegOfHour;
		If ValueIsFilled(Msrmnt.KeyOperationEndDate) Then
			// Getting the date in UTC
			Record.EndDate = Msrmnt.KeyOperationEndDate;
		EndIf;
		Record.User = User;
		Record.RecordDateLocal = RecordDateLocal;
		Record.Comment = Comment;
		
	EndDo;
	
	If RecordSet.Count() > 0 Then
		Try
			RecordSet.Write(False);
		Except
			WriteLogEvent(NStr("ru = 'Не удалось сохранить замеры производительности'; en = 'Cannot save performance measurements'; pl = 'Cannot save performance measurements';de = 'Cannot save performance measurements';ro = 'Cannot save performance measurements';tr = 'Cannot save performance measurements'; es_ES = 'Cannot save performance measurements'", DefaultLanguageCode),
				EventLogLevel.Error,,,DetailErrorDescription(ErrorInfo()));
		EndTry;
	EndIf;
	
	SetPrivilegedMode(False);
	
EndProcedure

// Processes a data export scheduled job.
//
// Parameters:
//  DirectoriesForExport - a Structure with Array values.
//
Procedure PerformanceMonitorDataExport(DirectoriesForExport, AddtnlParameters = Undefined) Export
	
	If PerformanceMonitorInternal.SubsystemExists("StandardSubsystems.Core") Then
		ModuleCommon = PerformanceMonitorInternal.CommonModule("Common");
		ModuleCommon.OnStartExecuteScheduledJob(Metadata.ScheduledJobs.PerformanceMonitorDataExport);
	EndIf;
		
	// Skipping data export if performance measurement is turned off
	If AddtnlParameters = Undefined AND Not PerformanceMonitorServerCallCached.RunPerformanceMeasurements() Then
	    Return;	
	EndIf;
	
	Query = New Query;
	Query.Text = 
	"SELECT
	|	MAX(Measurements.RecordDate) AS MeasurementDate
	|FROM 
	|	InformationRegister.TimeMeasurements AS Measurements
	|WHERE
	|	Measurements.RecordDate <= &CurDate";
	
	If AddtnlParameters = Undefined Then
		Query.SetParameter("CurDate", CurrentUniversalDate() - 1);
	Else
		Query.SetParameter("CurDate", AddtnlParameters.EndDate);
	EndIf;
	
	Selection = Query.Execute().Select();
	If Selection.Next() AND Selection.MeasurementDate <> Null Then
		MeasurementsDateUpperBoundary = Selection.MeasurementDate;
	Else 
		Return;	
	EndIf;

	MeasurementsArrays = MeasurementsDividedByKeyOperations(MeasurementsDateUpperBoundary, AddtnlParameters);
	
	FileSequenceNumber = 0;
	CurDate = CurrentUniversalDateInMilliseconds();
	If AddtnlParameters <> Undefined Then
		TempDirectory = GetTempFileName();
		CreateDirectory(TempDirectory);
		
		DirectoriesForExport = New Structure("LocalExportDirectory, FTPExportDirectory", New Array, New Array);
		DirectoriesForExport.LocalExportDirectory.Add(True);
		DirectoriesForExport.LocalExportDirectory.Add(TempDirectory);
		DirectoriesForExport.FTPExportDirectory.Add(False);
		DirectoriesForExport.FTPExportDirectory.Add("");
	EndIf;
	
	For Each MeasurementsArray In MeasurementsArrays Do
		FileSequenceNumber = FileSequenceNumber + 1;
		ExportResults(DirectoriesForExport, MeasurementsArray, CurDate, FileSequenceNumber);
	EndDo;
	
	If AddtnlParameters <> Undefined Then
		DataFiles = FindFiles(TempDirectory, "*.xml");
		ZipFileWriter = New ZipFileWriter();
		ArchiveName = GetTempFileName("zip");
		ZipFileWriter.Open(ArchiveName,,,ZIPCompressionMethod.Deflate);
		For Each DataFile In DataFiles Do
			ZipFileWriter.Add(DataFile.FullName);
		EndDo;
		ZipFileWriter.Write();		
		
		BinaryDataArchive = New BinaryData(ArchiveName);
		PutToTempStorage(BinaryDataArchive, AddtnlParameters.StorageAddress);
		
		DeleteFiles(TempDirectory);
		DeleteFiles(ArchiveName);
	EndIf;
			
EndProcedure

// Handles the scheduled job for clearing measurement registers.
Procedure ClearTimeMeasurementsRegisters() Export
	
	If PerformanceMonitorInternal.SubsystemExists("StandardSubsystems.Core") Then
		ModuleCommon = PerformanceMonitorInternal.CommonModule("Common");
		ModuleCommon.OnStartExecuteScheduledJob(Metadata.ScheduledJobs.PerformanceMonitorDataExport);
	EndIf;
	
	DeletionBoundary = BegOfDay(CurrentUniversalDate() - 86400*Constants.KeepMeasurementsPeriod.Get());
	
	TimeMeasurementsQuery = New Query;
	TimeMeasurementsQuery.Text = "
	|SELECT
	|	MIN(RecordDateBegOfHour) AS RecordDateBegOfHour
	|FROM
	|	InformationRegister.TimeMeasurements
	|WHERE
	|	RecordDateBegOfHour < &DeletionBoundary
	|";
	TimeMeasurementsQuery.SetParameter("DeletionBoundary", DeletionBoundary);
	
	TechnologicalTimeMeasurementsQuery = New Query;
	TechnologicalTimeMeasurementsQuery.Text = "
	|SELECT
	|	MIN(RecordDateBegOfHour) AS RecordDateBegOfHour
	|FROM
	|	InformationRegister.TimeMeasurementsTechnological
	|WHERE
	|	RecordDateBegOfHour < &DeletionBoundary
	|";
	TechnologicalTimeMeasurementsQuery.SetParameter("DeletionBoundary", DeletionBoundary);
	
	RecordSet = InformationRegisters.TimeMeasurements.CreateRecordSet();
	RecordSetTechnologicalRecords = InformationRegisters.TimeMeasurementsTechnological.CreateRecordSet();
	
	DeletionRequired = True;
	TechnologicalDeletionRequired = True;
	While DeletionRequired OR TechnologicalDeletionRequired Do
		
		If DeletionRequired Then
			DeletionRequired = False;
			
			Result = TimeMeasurementsQuery.Execute();
			Selection = Result.Select();
			Selection.Next();
			RecordDateBegOfHour = Selection.RecordDateBegOfHour;
			
			If NOT RecordDateBegOfHour = Null Then
				RecordSet.Filter.RecordDateBegOfHour.Set(RecordDateBegOfHour);
				RecordSet.Write(True);
				DeletionRequired = True;
			EndIf; 
		EndIf;
		
		If TechnologicalDeletionRequired Then
			TechnologicalDeletionRequired = False;
			Result = TechnologicalTimeMeasurementsQuery.Execute();
			Selection = Result.Select();
			Selection.Next();
			RecordDateBegOfHour = Selection.RecordDateBegOfHour;
			If NOT RecordDateBegOfHour = Null Then
				RecordSetTechnologicalRecords.Filter.RecordDateBegOfHour.Set(RecordDateBegOfHour);
				RecordSetTechnologicalRecords.Write(True);
				TechnologicalDeletionRequired = True;
			EndIf;
		EndIf;
				
	EndDo;
	
EndProcedure

// Scheduled job for export
Function MeasurementsDividedByKeyOperations(MeasurementsDateUpperBoundary, AddtnlParameters = Undefined)
	
	Query = New Query;
	
	PerformanceLevelsNumber = New Map;
	PerformanceLevelsNumber.Insert(Enums.PerformanceLevels.Ideal, 1);
	PerformanceLevelsNumber.Insert(Enums.PerformanceLevels.Excellent, 0.94);
	PerformanceLevelsNumber.Insert(Enums.PerformanceLevels.Satisfactory, 0.85);
	PerformanceLevelsNumber.Insert(Enums.PerformanceLevels.Tolerated, 0.70);
	PerformanceLevelsNumber.Insert(Enums.PerformanceLevels.Frustrated, 0.50);
		
	If AddtnlParameters = Undefined Then
		QueryText = TimeMeasurementsWithoutProfileFiltering();
		Query.SetParameter("LastExportDate", Constants.LastPerformanceMeasurementsExportDateUTC.Get());	
		Query.SetParameter("MeasurementsDateUpperBoundary", MeasurementsDateUpperBoundary);
		Constants.LastPerformanceMeasurementsExportDateUTC.Set(MeasurementsDateUpperBoundary);
	Else
		If ValueIsFilled(AddtnlParameters.Profile) Then
			QueryText = TimeMeasurementsWithProfileFiltering();
			Query.SetParameter("Profile", AddtnlParameters.Profile);	
		Else
			QueryText = TimeMeasurementsWithoutProfileFiltering();
		EndIf;
		Query.SetParameter("LastExportDate", AddtnlParameters.StartDate);	
		Query.SetParameter("MeasurementsDateUpperBoundary", AddtnlParameters.EndDate);
	EndIf;
	
	Query.Text = QueryText;
		
	Result = Query.Execute();
	
	MeasurementsCountInFile = Constants.MeasurementsCountInExportPackage.Get();
	MeasurementsCountInFile = ?(MeasurementsCountInFile <> 0, MeasurementsCountInFile, 1000);
	
	MeasurementsByFiles = New Array;
	
	DividedMeasurements = New Map;
	CurMeasurementsCount = 0;
	
	Selection = Result.Select();
	While Selection.Next() Do
		KeyOperation = DividedMeasurements.Get(Selection.KeyOperation);
		
		If KeyOperation = Undefined Then
			KeyOperation = New Map;
			KeyOperation.Insert("uid", String(Selection.KeyOperation.UUID()));
			KeyOperation.Insert("name", Selection.KeyOperationRow);
			KeyOperation.Insert("nameFull", Selection.KeyOperationName);
			KeyOperation.Insert("comments", New Map);
			KeyOperation.Insert("priority", Selection.KeyOperationPriority);
			KeyOperation.Insert("targetValue", Selection.KeyOperation.ResponseTimeThreshold);
			KeyOperation.Insert("minimalApdexValue", PerformanceLevelsNumber[Selection.KeyOperation.MinValidLevel]);
			KeyOperation.Insert("long", Selection.TimeConsuming);
						
			DividedMeasurements.Insert(Selection.KeyOperation, KeyOperation);
		EndIf;
		
		Comment = DividedMeasurements[Selection.KeyOperation]["comments"][Selection.Comment];
		If Comment = Undefined Then
			Comment = New Map;
			Comment.Insert("Measurements", New Array);
			KeyOperation["comments"].Insert(Selection.Comment, Comment);
		EndIf;
				
		KeyOperationMeasurements = Comment.Get("Measurements");
		
		MeasurementStructure = New Structure;
		MeasurementStructure.Insert("value", Selection.RunTime);
		MeasurementStructure.Insert("weight", Selection.MeasurementWeight);
		MeasurementStructure.Insert("tUTC", Selection.MeasurementStartDate);
		MeasurementStructure.Insert("userName", Selection.User);
		MeasurementStructure.Insert("tSaveUTC", Selection.RecordDate);
		MeasurementStructure.Insert("sessionNumber", Selection.SessionNumber);
		MeasurementStructure.Insert("comment", Selection.Comment);
		MeasurementStructure.Insert("runningError", Selection.CompletedWithError);
		
		KeyOperationMeasurements.Add(MeasurementStructure);
		
		CurMeasurementsCount = CurMeasurementsCount + 1;
		
		If CurMeasurementsCount = MeasurementsCountInFile Then
			MeasurementsByFiles.Add(DividedMeasurements);
			DividedMeasurements = New Map;
			KeyOperation = Undefined;
			CurMeasurementsCount = 0;
		EndIf;
	EndDo;
	MeasurementsByFiles.Add(DividedMeasurements);
	
	Return MeasurementsByFiles;
EndFunction

// Saves Apdex calculation result to a file.
//
// Parameters:
//  DirectoriesForExport - a Structure with Array values.
//  APDEXSelection - a query result.
//  MeasurementsArrays - Structure with Array values.
Procedure ExportResults(DirectoriesForExport, MeasurementsArrays, CurDate, FileSequenceNumber)
	
	Namespace = "www.v8.1c.ru/ssl/performace-assessment/apdexExport/1.0.0.4";
	TempFileName = GetTempFileName(".xml");
	
	XMLWriter = New XMLWriter;
	XMLWriter.OpenFile(TempFileName, "UTF-8");
	XMLWriter.WriteXMLDeclaration();
	XMLWriter.WriteStartElement("Performance", Namespace);
	XMLWriter.WriteNamespaceMapping("prf", Namespace);
	XMLWriter.WriteNamespaceMapping("xs", "http://www.w3.org/2001/XMLSchema");
	XMLWriter.WriteNamespaceMapping("xsi", "http://www.w3.org/2001/XMLSchema-instance");
	
	XMLWriter.WriteAttribute("version", Namespace, "1.0.0.4");
	XMLWriter.WriteAttribute("period", Namespace, String(Date(1,1,1) + CurDate/1000));
	
	TypeKeyOperation = XDTOFactory.Type(Namespace, "KeyOperation");
	TypeMeasurement = XDTOFactory.Type(Namespace, "Measurement");
	
	For Each CurMeasurement In MeasurementsArrays Do
		KeyOperationMeasurements = CurMeasurement.Value;
		
		For Each Comment In KeyOperationMeasurements["comments"] Do
			KeyOperation = XDTOFactory.Create(TypeKeyOperation);
			KeyOperation.name = KeyOperationMeasurements["name"];
			KeyOperation.nameFull = KeyOperationMeasurements["nameFull"];
			KeyOperation.long = KeyOperationMeasurements["long"];
			KeyOperation.comment = Comment.Key;
			KeyOperation.priority = KeyOperationMeasurements["priority"];
			KeyOperation.targetValue = KeyOperationMeasurements["targetValue"];
			KeyOperation.uid = KeyOperationMeasurements["uid"];
						
			Measurements = Comment.Value["Measurements"];
			For Each Msrmnt In Measurements Do
				XMLMeasurement = XDTOFactory.Create(TypeMeasurement);
				XMLMeasurement.value = Msrmnt.value;
				XMLMeasurement.weight = Msrmnt.weight;
				XMLMeasurement.tUTC = Msrmnt.tUTC;
				XMLMeasurement.userName = Msrmnt.userName;
				XMLMeasurement.tSaveUTC = Msrmnt.tSaveUTC;
				XMLMeasurement.sessionNumber = Msrmnt.sessionNumber;
				XMLMeasurement.runningError = Msrmnt.runningError;
				
				KeyOperation.measurement.Add(XMLMeasurement);
			EndDo;
			
			XDTOFactory.WriteXML(XMLWriter, KeyOperation);
		EndDo;
	EndDo;
	XMLWriter.WriteEndElement();
	XMLWriter.Close();
	
	For Each ExecuteDirectoryKey In DirectoriesForExport Do
		ExecuteDirectory = ExecuteDirectoryKey.Value;
		ExecuteJob = ExecuteDirectory[0];
		If NOT ExecuteJob Then
			Continue;
		EndIf;
		
		ExportDirectory = ExecuteDirectory[1];
		varKey = ExecuteDirectoryKey.Key;
		If varKey = PerformanceMonitorClientServer.LocalExportDirectoryJobKey() Then
			CreateDirectory(ExportDirectory);
		EndIf;
		
		FileCopy(TempFileName, ExportFileFullName(ExportDirectory, CurDate, FileSequenceNumber, ".xml"));
	EndDo;
	DeleteFiles(TempFileName);
EndProcedure

Function TimeMeasurementsWithoutProfileFiltering()
	Return "
	|SELECT
	|	Measurements.KeyOperation AS KeyOperation,
	|	Measurements.MeasurementStartDate AS MeasurementStartDate,
	|	Measurements.RunTime AS RunTime,
	|	Measurements.MeasurementWeight AS MeasurementWeight,
	|	Measurements.User AS User,
	|	Measurements.RecordDate AS RecordDate,
	|	Measurements.SessionNumber AS SessionNumber,
	|	Measurements.Comment AS Comment, 
	|	KeyOperations.Description AS KeyOperationRow,
	|	KeyOperations.Name AS KeyOperationName,
	|	KeyOperations.Priority AS KeyOperationPriority,
	|	KeyOperations.ResponseTimeThreshold AS KeyOperationResponseTimeThreshold,
	|	KeyOperations.MinValidLevel AS MinValidLevel,
	|	Measurements.CompletedWithError AS CompletedWithError,
	|	KeyOperations.TimeConsuming AS TimeConsuming
	|FROM
	|	InformationRegister.TimeMeasurements AS Measurements
	|INNER JOIN
	|	Catalog.KeyOperations AS KeyOperations
	|ON
	|	KeyOperations.Ref = Measurements.KeyOperation
	|WHERE
	|	Measurements.RecordDate > &LastExportDate
	|	AND Measurements.RecordDate <= &MeasurementsDateUpperBoundary
	|ORDER BY
	|	Measurements.KeyOperation,
	|	Measurements.Comment
	|";
EndFunction

Function TimeMeasurementsWithProfileFiltering()
	Return "
	|SELECT
	|	Measurements.KeyOperation AS KeyOperation,
	|	Measurements.MeasurementStartDate AS MeasurementStartDate,
	|	Measurements.RunTime AS RunTime,
	|	Measurements.MeasurementWeight AS MeasurementWeight,
	|	Measurements.User AS User,
	|	Measurements.RecordDate AS RecordDate,
	|	Measurements.SessionNumber AS SessionNumber,
	|	Measurements.Comment AS Comment, 
	|	KeyOperations.KeyOperation.Description AS KeyOperationRow,
	|	KeyOperations.KeyOperation.Name AS KeyOperationName,
	|	KeyOperations.Priority AS KeyOperationPriority,
	|	KeyOperations.ResponseTimeThreshold AS KeyOperationResponseTimeThreshold,
	|	KeyOperations.KeyOperation.MinValidLevel AS MinValidLevel,
	|	Measurements.CompletedWithError AS CompletedWithError,
	|	KeyOperations.KeyOperation.TimeConsuming AS TimeConsuming
	|FROM
	|	InformationRegister.TimeMeasurements AS Measurements
	|INNER JOIN
	|	Catalog.KeyOperationProfiles.ProfileKeyOperations AS KeyOperations
	|ON
	|	KeyOperations.KeyOperation = Measurements.KeyOperation
	|	AND KeyOperations.Ref = &Profile
	|WHERE
	|	Measurements.RecordDate > &LastExportDate
	|	AND Measurements.RecordDate <= &MeasurementsDateUpperBoundary
	|ORDER BY
	|	Measurements.KeyOperation,
	|	Measurements.Comment
	|";
EndFunction

// Generates a file name for exporting measurement results.
//
// Parameters:
//  Directory - String, 
//  FileGenerationDate - Date - a measurement date and time.
//  ExtensionWithDot - String - a string containing a file extension with a dot. For example, ".xxx".
// Returns:
//  String - full path to the export file.
//
Function ExportFileFullName(Directory, CurDate, FileSequenceNumber, ExtentionWithDot)
	
	FileFormationDate = Date(1,1,1) + CurDate/1000;
	FileSequenceNumberFormat = Format(FileSequenceNumber, "ND=5; NLZ=; NG=0");
	
	Separator = ?(Upper(Left(Directory, 3)) = "FTP", "/", GetPathSeparator());
	Return RemoveSeparatorsAtFileNameEnd(Directory, Separator) + Separator + Format(FileFormationDate, "DF='yyyy-mm-dd HH-mm-ss-" + FileSequenceNumberFormat + "'") + ExtentionWithDot;

EndFunction

// Checks whether a path ends with a slash mark and deletes the slash mark.
//
// Parameters:
//  FileName - String.
//  Separator - String.
Function RemoveSeparatorsAtFileNameEnd(Val FileName, Separator)
	
	PathLength = StrLen(FileName);	
	If PathLength = 0 Then
		Return FileName;
	EndIf;
	
	While PathLength > 0 AND StrEndsWith(FileName, Separator) Do
		FileName = Left(FileName, PathLength - 1);
		PathLength = StrLen(FileName);
	EndDo;
	
	Return FileName;
	
EndFunction

Procedure LoadPerformanceMonitorFile(FileName, StorageAddress) Export
	
	FileForStorage = GetTempFileName("zip");
	ArchiveBinaryData = GetFromTempStorage(StorageAddress);
	ArchiveBinaryData.Write(FileForStorage);
	
	FileDirectory = AddLastPathSeparator(GetTempFileName());
	
	Try
		ZIPReader = New ZipFileReader(FileForStorage);
		ZIPReader.ExtractAll(FileDirectory, ZIPRestoreFilePathsMode.DontRestore);
		ZIPReader.Close();			
	Except
		DeleteFiles(FileForStorage);
		DeleteFiles(FileDirectory);
		ErrorDescription = ErrorDescription();
		StringPattern = NStr("ru = 'Не удалось распаковать архив %1 %2'; en = 'Cannot unpack the archive %1 %2'; pl = 'Cannot unpack the archive %1 %2';de = 'Cannot unpack the archive %1 %2';ro = 'Cannot unpack the archive %1 %2';tr = 'Cannot unpack the archive %1 %2'; es_ES = 'Cannot unpack the archive %1 %2'");
		ExceptionDetails = PerformanceMonitorClientServer.SubstituteParametersToString(StringPattern, FileName, ErrorDescription);
		Raise ExceptionDetails;
	EndTry;
	
	Try
		AvailableKeyOperations = AvailableKeyOperations();
		
		For Each File In FindFiles(FileDirectory, "*.XML") Do
			XMLReader = New XMLReader;	
			XMLReader.OpenFile(File.FullName);
			XMLReader.MoveToContent();
			KeyOperationsToWrite = New Array;
			RawMeasurementsToWrite = New Array;
			LoadPerformanceMonitorFileApdexExport(XMLReader, AvailableKeyOperations, KeyOperationsToWrite, RawMeasurementsToWrite);
			XMLReader.Close();
		EndDo;
		DeleteFiles(FileForStorage);
		DeleteFiles(FileDirectory);
	Except
		XMLReader.Close();
		DeleteFiles(FileForStorage);
		DeleteFiles(FileDirectory);		
		Raise;
	EndTry;
	
	BeginTransaction();
	Try
		For Each RawMeasurementToWrite In RawMeasurementsToWrite Do
			Record = InformationRegisters.TimeMeasurements.CreateRecordManager();
			For Each KeyAndValue In RawMeasurementToWrite Do
				Record[KeyAndValue.Key] = KeyAndValue.Value;
			EndDo;
			Record.RecordDateBegOfHour = BegOfHour(Record.RecordDate);
			Record.EndDate = Record.MeasurementStartDate + Record.RunTime*1000;
			Record.Write();
		EndDo;
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;		          	

EndProcedure

Procedure LoadPerformanceMonitorFileApdexExport(XMLReader, AvailableKeyOperations, KeyOperationsToWrite, RawMeasurementsToWrite)
	
	Namespace = XMLReader.NamespaceURI;
	
	// Starting from version 1.0.0.4, information on executing a measurement with an error is stored in the measurement itself instead of the key operation.
	ErrorInMeasurementFlag = Metadata.XDTOPackages.ApdexExport_1_0_0_4.Namespace = Namespace;
	
	measurement = "measurement";
	TypeKeyOperation = XDTOFactory.Type(Namespace, "KeyOperation");
	
	XMLReader.Read();
	
	While XMLReader.NodeType <> XMLNodeType.EndElement Do
		
		KeyOperation = XDTOFactory.ReadXML(XMLReader, TypeKeyOperation);
		
		KeyOperationName = KeyOperation.nameFull;
		ResponseTimeThreshold = KeyOperation.targetValue;
		Comment = KeyOperation.comment;
		TimeConsuming = KeyOperation.long;
		
		KeyOperationRef = AvailableKeyOperations[KeyOperationName];
		If KeyOperationRef = Undefined Then
			KeyOperationRef = CreateKeyOperation(KeyOperationName, ResponseTimeThreshold, TimeConsuming);
			AvailableKeyOperations.Insert(KeyOperationName, KeyOperationRef);
		EndIf;
				
		MaxMeasurementDate = Undefined;
		NumberOfMeasurements = KeyOperation[measurement].Count();
		MeasurementNumber = 0;
		While MeasurementNumber < NumberOfMeasurements Do
			Msrmnt = KeyOperation[measurement].Get(MeasurementNumber);
			MeasurementDate = Msrmnt.tUTC;
			If MaxMeasurementDate = Undefined OR MaxMeasurementDate < MeasurementDate Then
				MaxMeasurementDate = MeasurementDate;
			EndIf;
			If ErrorInMeasurementFlag Then
				CompletedWithError = Msrmnt.runningError;
			Else
				CompletedWithError = KeyOperation.runningError;
			EndIf;
			
			RawMeasurementToWrite = New Map;
			RawMeasurementToWrite.Insert("KeyOperation", KeyOperationRef);
			RawMeasurementToWrite.Insert("MeasurementStartDate", Msrmnt.tUTC);
			RawMeasurementToWrite.Insert("RunTime", Msrmnt.value);
			RawMeasurementToWrite.Insert("MeasurementWeight", Msrmnt.weight);
			RawMeasurementToWrite.Insert("User", Msrmnt.userName);
			RawMeasurementToWrite.Insert("RecordDate", Msrmnt.tSaveUTC);
			RawMeasurementToWrite.Insert("SessionNumber", Msrmnt.sessionNumber);
			RawMeasurementToWrite.Insert("Comment", Comment);
			RawMeasurementToWrite.Insert("CompletedWithError", CompletedWithError);
			
			RawMeasurementsToWrite.Add(RawMeasurementToWrite);
			
			MeasurementNumber = MeasurementNumber + 1;
		EndDo;
	EndDo;

EndProcedure

Function AvailableKeyOperations()
	AvailableKeyOperations = New Map;
	Query = New Query("SELECT
	                      |	KeyOperations.Ref AS Ref,
	                      |	KeyOperations.Name AS Name
	                      |FROM
	                      |	Catalog.KeyOperations AS KeyOperations");
	Selection = Query.Execute().Select();
	While Selection.Next() Do
		AvailableKeyOperations.Insert(Selection.Name, Selection.Ref);
	EndDo;
	Return AvailableKeyOperations;
EndFunction

// Adds the trailing separator to the passed directory path if it is missing.
//
// Parameters:
//  DirectoryPath - String - a directory path.
//  Platform - PlatformType - deprecated parameter.
//
// Returns:
//  String - path to the directory, including the trailing separator.
//
// Example:
//  Result = AddLastPathSeparator("C:\My directory"); // Returns "C:\My directory\".
//  Result = AddLastPathSeparator("C:\My directory\"); // returns "C:\My directory\".
//  Result = AddLastPathSeparator("%APPDATA%"); // Returns "%APPDATA%\".
//
Function AddLastPathSeparator(Val DirectoryPath, Val Platform = Undefined)
	If IsBlankString(DirectoryPath) Then
		Return DirectoryPath;
	EndIf;
	
	CharToAdd = GetPathSeparator();
	
	If StrEndsWith(DirectoryPath, CharToAdd) Then
		Return DirectoryPath;
	Else 
		Return DirectoryPath + CharToAdd;
	EndIf;
EndFunction

#EndRegion