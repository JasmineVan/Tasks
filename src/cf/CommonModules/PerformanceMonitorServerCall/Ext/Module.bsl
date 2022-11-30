///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Private

// Records an array of measurements.
//
// Parameters:
//  Measurements - Array of Structures.
//
// Returns:
// 	Number - a current recording period on the server if measurements were recorded, in seconds.
//
Function RecordKeyOperationsDuration(MeasurementsToWrite) Export
	
	RecordingPeriod = PerformanceMonitor.RecordPeriod();
	
	If ExclusiveMode() Then
		Return RecordingPeriod;
	EndIf;
	
	If NOT Constants.RunPerformanceMeasurements.Get() Then
		Return RecordingPeriod;
	EndIf;
		
	Measurements = MeasurementsToWrite.CompletedMeasurements;
	UserAgentInformation = MeasurementsToWrite.UserAgentInformation;	
	
	SetPrivilegedMode(True);
	
	RecordSet = InformationRegisters.TimeMeasurements.CreateRecordSet();
	TechnologicalRecordSet = InformationRegisters.TimeMeasurementsTechnological.CreateRecordSet();
	SessionNumber = InfoBaseSessionNumber();
	RecordDate = Date(1,1,1) + CurrentUniversalDateInMilliseconds()/1000;
	RecordDateBegOfHour = BegOfHour(RecordDate);
	User = InfoBaseUsers.CurrentUser();
	RecordDateLocal = CurrentSessionDate();
	
	JSONReader = New JSONReader();
	JSONReader.SetString(SessionParameters.TimeMeasurementComment);
	DefaultComment = ReadJSON(JSONReader, True);
	DefaultComment.Insert("InfCl", UserAgentInformation);
	
	JSONWriter = New JSONWriter;
	JSONWriter.SetString(New JSONWriterSettings(JSONLineBreak.None));
	WriteJSON(JSONWriter, DefaultComment);
	DefaultCommentLine = JSONWriter.Close();
		
	For Each Msrmnt In Measurements Do
		MeasurementParameters = Msrmnt.Value;
		Duration = (MeasurementParameters["EndTime"] - MeasurementParameters["BeginTime"])/1000;
		Duration = ?(Duration = 0, 0.001, Duration);
		
		If MeasurementParameters["Technological"] Then
			NewRecord = TechnologicalRecordSet.Add();
		Else
			NewRecord = RecordSet.Add();
		EndIf;
		
		KeyOperation = MeasurementParameters["KeyOperation"];
		CompletedWithError = MeasurementParameters["CompletedWithError"];
		
		If NOT ValueIsFilled(KeyOperation) Then
			Continue;
		EndIf;
				
		If TypeOf(KeyOperation) = Type("String") Then
			KeyOperationRef = PerformanceMonitorCached.GetKeyOperationByName(KeyOperation);
		Else
			KeyOperationRef = KeyOperation;
		EndIf;
		
		
		If MeasurementParameters["Comment"] <> Undefined Then
			DefaultComment.Insert("AddlInf", MeasurementParameters["Comment"]);
			JSONWriter = New JSONWriter;
			JSONWriter.SetString(New JSONWriterSettings(JSONLineBreak.None));
			WriteJSON(JSONWriter, DefaultComment);
			DefaultCommentLine = JSONWriter.Close();
		EndIf;
				
		NewRecord.KeyOperation = KeyOperationRef;
		NewRecord.MeasurementStartDate = MeasurementParameters["BeginTime"];
		NewRecord.SessionNumber = SessionNumber;
		NewRecord.RunTime = Duration;
		NewRecord.MeasurementWeight = MeasurementParameters["MeasurementWeight"];
		NewRecord.RecordDate = RecordDate;
		NewRecord.RecordDateBegOfHour = RecordDateBegOfHour;
		NewRecord.EndDate = MeasurementParameters["EndTime"];
		
		If NOT MeasurementParameters["Technological"] Then
			NewRecord.CompletedWithError = CompletedWithError;
		EndIf;
		
		NewRecord.User = User;
		NewRecord.RecordDateLocal = RecordDateLocal;
		NewRecord.Comment = DefaultCommentLine;
		
		// Recording nested measurements.
		NestedMeasurements = Msrmnt.Value["NestedMeasurements"];
		If NestedMeasurements = Undefined Then
			Continue;
		EndIf;
		
		WeightedTimeTotal = 0;
	
		For Each NestedMeasurement In NestedMeasurements Do
			MeasurementData = NestedMeasurement.Value;
			NestedMeasurementWeight = MeasurementData["MeasurementWeight"];
			NestedMeasurementDuration = MeasurementData["Duration"];
			NestedMeasurementComment = MeasurementData["Comment"];
			NestedStepKeyOperation = KeyOperation + "." + NestedMeasurement.Key;
			NestedStepKeyOperationLink = PerformanceMonitorCached.GetKeyOperationByName(NestedStepKeyOperation, True);
			WeightedTime = ?(NestedMeasurementWeight = 0, NestedMeasurementDuration, NestedMeasurementDuration / NestedMeasurementWeight);
			WeightedTimeTotal = WeightedTimeTotal + WeightedTime;
			
			If NestedMeasurementComment <> Undefined Then
				DefaultComment.Insert("AddlInf", NestedMeasurementComment);
				JSONWriter = New JSONWriter;
				JSONWriter.SetString(New JSONWriterSettings(JSONLineBreak.None));
				WriteJSON(JSONWriter, DefaultComment);
				StepCommentString = JSONWriter.Close();
			EndIf;
		
			NewRecord = RecordSet.Add();
			NewRecord.KeyOperation = NestedStepKeyOperationLink;
			NewRecord.MeasurementStartDate = MeasurementData["BeginTime"];
			NewRecord.SessionNumber = SessionNumber;
			NewRecord.RunTime = WeightedTime/1000;
			NewRecord.MeasurementWeight = NestedMeasurementWeight;
			NewRecord.EndDate = MeasurementData["EndTime"];		
			NewRecord.RecordDate = RecordDate;
			NewRecord.RecordDateBegOfHour = RecordDateBegOfHour;						
			NewRecord.User = User;
			NewRecord.RecordDateLocal = RecordDateLocal;
			NewRecord.Comment = StepCommentString;
		EndDo;
		// Committing the key operation's weighted time.
		If NestedMeasurements.Count() > 0 Then
			KeyOperationWeighted = KeyOperation + ".Specific";
			KeyOperationWeightedRef = PerformanceMonitorCached.GetKeyOperationByName(KeyOperationWeighted, True);
			NewRecord = RecordSet.Add();
			NewRecord.KeyOperation = KeyOperationWeightedRef;
			NewRecord.MeasurementStartDate = MeasurementParameters["BeginTime"];
			NewRecord.SessionNumber = SessionNumber;
			NewRecord.RunTime = WeightedTimeTotal/1000;
			NewRecord.MeasurementWeight = MeasurementParameters["MeasurementWeight"];
			NewRecord.RecordDate = RecordDate;
			NewRecord.RecordDateBegOfHour = RecordDateBegOfHour;
			NewRecord.EndDate = MeasurementParameters["EndTime"];		
			NewRecord.User = User;
			NewRecord.RecordDateLocal = RecordDateLocal;
			NewRecord.Comment = DefaultCommentLine;
		EndIf;
	EndDo;
	
	If RecordSet.Count() > 0 Then
		Try
			RecordSet.Write(False);
		Except
			WriteLogEvent(NStr("ru = 'Не удалось сохранить замеры производительности'; en = 'Cannot save performance measurements'; pl = 'Cannot save performance measurements';de = 'Cannot save performance measurements';ro = 'Cannot save performance measurements';tr = 'Cannot save performance measurements'; es_ES = 'Cannot save performance measurements'", Metadata.DefaultLanguage.LanguageCode),
				EventLogLevel.Error,,,DetailErrorDescription(ErrorInfo()));
		EndTry;
	EndIf;
	
	If TechnologicalRecordSet.Count() > 0 Then
		Try
			TechnologicalRecordSet.Write(False);
		Except
			WriteLogEvent(NStr("ru = 'Не удалось сохранить технологические замеры производительности'; en = 'Cannot save technological performance measurements'; pl = 'Cannot save technological performance measurements';de = 'Cannot save technological performance measurements';ro = 'Cannot save technological performance measurements';tr = 'Cannot save technological performance measurements'; es_ES = 'Cannot save technological performance measurements'", Metadata.DefaultLanguage.LanguageCode),
				EventLogLevel.Error,,,DetailErrorDescription(ErrorInfo()));
		EndTry;
    EndIf;
	
	Return RecordingPeriod;
	
EndFunction

// Gets performance monitor parameters.
//
// Returns:
// 	Structure - parameters obtained from the server.
Function GetParametersAtServer() Export
	
	Parameters = New Structure("DateAndTimeAtServer, RecordPeriod");
	Parameters.DateAndTimeAtServer = CurrentUniversalDateInMilliseconds();
	
	SetPrivilegedMode(True);
	CurrentPeriod = Constants.PerformanceMonitorRecordPeriod.Get();
	Parameters.RecordPeriod = ?(CurrentPeriod >= 1, CurrentPeriod, 60);
	
	Return Parameters;
	
EndFunction

#EndRegion