///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Private

Function GetRecentComments() Export
	Query = New Query;
	QueryText = "
	|SELECT
	|	Comment AS Comment,
	|	COUNT(Comment) AS UsageFrequency
	|FROM
	|	(
	|		SELECT TOP 1000
	|			TimeMeasurements.Comment AS Comment
	|		FROM
	|			InformationRegister.TimeMeasurements AS TimeMeasurements
	|		ORDER BY
	|			TimeMeasurements.RecordDate DESC
	|	) AS Selection
	|GROUP BY
	|	Comment
	|ORDER BY
	|	COUNT(Comment) DESC
	|";

	Query.Text = QueryText;
	QueryResult = Query.Execute();
	
	Comments = New Array();
	
	Count = 0;
	DetailedRecordsSelection = QueryResult.Select();
    While DetailedRecordsSelection.Next() Do
		Comments.Add(DetailedRecordsSelection.Comment);
		Count = Count + 1;
		
		If Count = 5 Then
			Break;
		EndIf;
	EndDo;
	
	Return Comments;
EndFunction

Function GetAPDEXTop(StartDate, EndDate, AggregationPeriod, Count) Export
	
	Query = New Query;
	
	IntervalsSettingsTable = IntervalsSettingsTable();
	
	IntervalsTable = IntervalsTableForSettings(IntervalsSettingsTable);
	
	QueryTextByIntervals_Fields = QueryTextSubstringForIntervals(IntervalsTable, "Measurements", "RunTime", True);
	QueryTextByIntervals_Groups = QueryTextSubstringForIntervals(IntervalsTable, "Measurements", "RunTime", False);
	
	Query = New Query;	
	Query.Text = QueryText();
	Query.Text = StrReplace(Query.Text, "//%Intervals_Fields", QueryTextByIntervals_Fields); 
	Query.Text = StrReplace(Query.Text, "//%Intervals_Groups", QueryTextByIntervals_Groups); 
	Query.SetParameter("StartDate", (StartDate - Date(1,1,1)) * 1000);	
	Query.SetParameter("EndDate", (EndDate - Date(1,1,1)) * 1000);
	Query.SetParameter("AggregationPeriod", AggregationPeriod);
	
	QueryResult = Query.Execute();
	
	Return QueryResult;
EndFunction

Function QueryText()
	Return "SELECT
	|	DATEADD(DATETIME(2015,1,1),SECOND, CAST((Measurements.MeasurementStartDate/1000)/&AggregationPeriod - 0.5 AS NUMBER(11,0)) * &AggregationPeriod - 63555667200) AS Period,
	|	KeyOperationsCatalog.Description AS KOD,
	|	KeyOperationsCatalog.Name AS KON,
	|	KeyOperationsCatalog.NameHash AS KOHash,
	|	Measurements.CompletedWithError AS ExecutedWithError,
	|	//%Intervals_Fields
	|   Sum(1) AS MeasurementQuantity,
	|   Mean(Measurements.MeasurementWeight) AS AvgWeight,
	|   Maximum(Measurements.MeasurementWeight) AS MaxWeight
	|FROM
	|	InformationRegister.TimeMeasurements AS Measurements
	|INNER JOIN
	|	Catalog.KeyOperations AS KeyOperationsCatalog
	|ON
	|	Measurements.KeyOperation = KeyOperationsCatalog.Ref
	|WHERE
	|	Measurements.MeasurementStartDate BETWEEN &StartDate AND &EndDate
	|GROUP BY                             
	|	DATEADD(DATETIME(2015,1,1),SECOND, CAST((Measurements.MeasurementStartDate/1000)/&AggregationPeriod - 0.5 AS NUMBER(11,0)) * &AggregationPeriod - 63555667200),
	|	//%Intervals_Groups
	|	KeyOperationsCatalog.Name,
	|	KeyOperationsCatalog.NameHash,
	|	KeyOperationsCatalog.Description,
	|	Measurements.CompletedWithError
	|ORDER BY
	|	DATEADD(DATETIME(2015, 1, 1), SECOND, (CAST(Measurements.MeasurementStartDate / 1000 / &AggregationPeriod - 0.5 AS NUMBER(11, 0))) * &AggregationPeriod - 63555667200)"
EndFunction

// Returns the default interval settings table.
//
// Returns:
//   IntervalsSettingsTable - value table containing default interval settings.
//									Columns: LowerBoundary, UpperBoundary, Step.
//
Function IntervalsSettingsTable()
	
	IntervalsSettingsTable = New ValueTable;
	IntervalsSettingsTable.Columns.Add("LowerBound", New TypeDescription("Number",,, New NumberQualifiers(10, 3, AllowedSign.Nonnegative)));
	IntervalsSettingsTable.Columns.Add("UpperBound", New TypeDescription("Number",,, New NumberQualifiers(10, 3, AllowedSign.Nonnegative)));
	IntervalsSettingsTable.Columns.Add("Step", New TypeDescription("Number",,, New NumberQualifiers(10, 3, AllowedSign.Nonnegative)));
	
	// Intervals where the lower boundary and the step are both zero refer to infinite intervals unbounded from below, i.e. x <= UpperBoundary.
	// Intervals where the upper boundary and the step are both zero refer to infinite intervals unbounded from above, i.e. x > LowerBoundary.
	
	// Less than 0.5 s
	NewSettingsRow = IntervalsSettingsTable.Add();
	NewSettingsRow.LowerBound	 = 0;
	NewSettingsRow.UpperBound	 = 0.5;
	NewSettingsRow.Step				 = 0;
	
	// 0.5 to 5 s with a step of 0.25 s
	NewSettingsRow = IntervalsSettingsTable.Add();
	NewSettingsRow.LowerBound	 = 0.5;
	NewSettingsRow.UpperBound	 = 5;
	NewSettingsRow.Step				 = 0.25;
	
	// 5 to 7 s with a step of 0.5 s
	NewSettingsRow = IntervalsSettingsTable.Add();
	NewSettingsRow.LowerBound	 = 5;
	NewSettingsRow.UpperBound	 = 7;
	NewSettingsRow.Step				 = 0.5;
	
	// 7 to 12 s with a step of 1 s
	NewSettingsRow = IntervalsSettingsTable.Add();
	NewSettingsRow.LowerBound	 = 7;
	NewSettingsRow.UpperBound	 = 12;
	NewSettingsRow.Step				 = 1;
	
	// 12 to 20 s with a step of 2 s
	NewSettingsRow = IntervalsSettingsTable.Add();
	NewSettingsRow.LowerBound	 = 12;
	NewSettingsRow.UpperBound	 = 20;
	NewSettingsRow.Step				 = 2;
	
	// 20 to 30 s with a step of 5 s
	NewSettingsRow = IntervalsSettingsTable.Add();
	NewSettingsRow.LowerBound	 = 20;
	NewSettingsRow.UpperBound	 = 30;
	NewSettingsRow.Step				 = 5;
	
	// 30 to 80 s with a step of 10 s
	NewSettingsRow = IntervalsSettingsTable.Add();
	NewSettingsRow.LowerBound	 = 30;
	NewSettingsRow.UpperBound	 = 80;
	NewSettingsRow.Step				 = 10;
	
	// 80 to 120 s with a step of 20 s
	NewSettingsRow = IntervalsSettingsTable.Add();
	NewSettingsRow.LowerBound	 = 80;
	NewSettingsRow.UpperBound	 = 120;
	NewSettingsRow.Step				 = 20;
	
	// 120 to 300 s with a step of 30 s
	NewSettingsRow = IntervalsSettingsTable.Add();
	NewSettingsRow.LowerBound	 = 120;
	NewSettingsRow.UpperBound	 = 300;
	NewSettingsRow.Step				 = 30;
	
	// 300 to 600 s with a step of 60 s
	NewSettingsRow = IntervalsSettingsTable.Add();
	NewSettingsRow.LowerBound	 = 300;
	NewSettingsRow.UpperBound	 = 600;
	NewSettingsRow.Step				 = 60;
	
	// 600 to 1800 s with a step of 300 s
	NewSettingsRow = IntervalsSettingsTable.Add();
	NewSettingsRow.LowerBound	 = 600;
	NewSettingsRow.UpperBound	 = 1800;
	NewSettingsRow.Step				 = 300;
	
	// 1800 to 3600 s with a step of 600 s
	NewSettingsRow = IntervalsSettingsTable.Add();
	NewSettingsRow.LowerBound	 = 1800;
	NewSettingsRow.UpperBound	 = 3600;
	NewSettingsRow.Step				 = 600;
	
	// 3600 to 7200 s with a step of 1800 s
	NewSettingsRow = IntervalsSettingsTable.Add();
	NewSettingsRow.LowerBound	 = 3600;
	NewSettingsRow.UpperBound	 = 7200;
	NewSettingsRow.Step				 = 1800;
	
	// 7200 to 42300 s with a step of 3600 s
	NewSettingsRow = IntervalsSettingsTable.Add();
	NewSettingsRow.LowerBound	 = 7200;
	NewSettingsRow.UpperBound	 = 43200;
	NewSettingsRow.Step				 = 3600;
	
	// More than 42300 s
	NewSettingsRow = IntervalsSettingsTable.Add();
	NewSettingsRow.LowerBound	 = 43200;
	NewSettingsRow.UpperBound	 = 0;
	NewSettingsRow.Step				 = 0;
	
	Return IntervalsSettingsTable;
	
EndFunction // DefaultIntervalsSettingsTable()

// Generates and returns a table of intervals from the interval settings table.
//
// Parameters:
//  SettingsTable  - ValueTable - interval settings table.
//                 BoundaryMust contain the following Number columns: LowerBoundary, UpperBoundary, Step.
//
// Returns:
//   IntervalsTable   - table with lower and upper bounds for each of the intervals.
//						   Columns: LowerBoundary, UpperBoundary.
//
Function IntervalsTableForSettings(SettingsTable)
	
	IntervalsTable = New ValueTable;
	IntervalsTable.Columns.Add("LowerBound", New TypeDescription("Number",,, New NumberQualifiers(10, 3, AllowedSign.Nonnegative)));
	IntervalsTable.Columns.Add("UpperBound", New TypeDescription("Number",,, New NumberQualifiers(10, 3, AllowedSign.Nonnegative)));
	
	// Limits the number of intervals. If there are more intervals than specified, they will not be 
	// added to the intervals table. This is done to prevent uncontrolled growth of dynamically 
	// generated interval columns.
	// 
	MaxIntervalsCount = 80;
	TotalIntervals = 0;
		
	For each SettingsString In SettingsTable Do
		
		// Checking if the intervals are valid.
		// If the step is not zero, the lower boundary must be greater than the upper boundary.
		If SettingsString.LowerBound >= SettingsString.UpperBound AND SettingsString.Step <> 0
			OR SettingsString.LowerBound = SettingsString.UpperBound Then
			Continue;		
		EndIf; 
	
		If SettingsString.LowerBound = 0 AND SettingsString.Step = 0 Then
			NewIntervalRow = IntervalsTable.Add();	
			NewIntervalRow.LowerBound	 = 0;
			NewIntervalRow.UpperBound	 = SettingsString.UpperBound;			
			TotalIntervals = TotalIntervals + 1;
		ElsIf SettingsString.UpperBound = 0 AND SettingsString.Step = 0 Then
			NewIntervalRow = IntervalsTable.Add();	
			NewIntervalRow.LowerBound	 = SettingsString.LowerBound;
			NewIntervalRow.UpperBound	 = 0;                           			
			TotalIntervals = TotalIntervals + 1;
		Else
			CurrentValue = SettingsString.LowerBound;
			While CurrentValue < SettingsString.UpperBound Do
				// Too many columns.
				If TotalIntervals >= MaxIntervalsCount Then
					Break;
				EndIf;
				UpperValue = CurrentValue + SettingsString.Step;
				If UpperValue > SettingsString.UpperBound Then
					// Invalid interval settings. The current interval's upper boundary exceeds the upper boundary of the settings.
					Break;
				EndIf; 								
				NewIntervalRow = IntervalsTable.Add();	
				NewIntervalRow.LowerBound	 = CurrentValue;				
				NewIntervalRow.UpperBound	 = UpperValue;	
				CurrentValue = UpperValue;
				TotalIntervals = TotalIntervals + 1;
				
			EndDo; 		
		EndIf; 
	
	EndDo; 
	
	Return IntervalsTable;
	
EndFunction // IntervalsTableForSettings()

// Generates and returns partial text of an interval table query.
//
// Parameters:
//  IntervalsTable  - ValueTable - list of intervals.
//                 Must contain the following columns: LowerBoundary, UpperBoundary.
//
// Returns:
//   QueryText   - part of the query text for the specified intervals table.
//
Function QueryTextSubstringForIntervals(IntervalsTable, SourceTableName, SourceColumnName, WithName)
	
	QueryText = "";	
	StringPattern = "	WHEN %1 %2 THEN %3";
	
	For Each IntervalString In IntervalsTable Do
		
		If IntervalString.LowerBound = 0 Then
			LowerBoundText = "";
			UpperBoundText = SourceTableName + "." + SourceColumnName + " <= " + Format(IntervalString.UpperBound,"NDS=.; NZ=0; NG=");
		ElsIf IntervalString.UpperBound = 0 Then
			LowerBoundText = SourceTableName + "." + SourceColumnName + " > " + Format(IntervalString.LowerBound,"NDS=.; NZ=0; NG=");
			UpperBoundText = "";
		Else
			LowerBoundText = SourceTableName + "." + SourceColumnName + " > " + Format(IntervalString.LowerBound,"NDS=.; NZ=0; NG=") + " AND ";
			UpperBoundText = SourceTableName + "." + SourceColumnName + " <= " + Format(IntervalString.UpperBound,"NDS=.; NZ=0; NG=");
		EndIf;
		
		QueryTextForInterval = StringFunctionsClientServer.SubstituteParametersToString(StringPattern, LowerBoundText, UpperBoundText, Format(IntervalString.UpperBound,"NDS=.; NZ=0; NG=")); 		
		QueryText = QueryText + ?(IsBlankString(QueryText), "", Chars.LF) + QueryTextForInterval;
		
	EndDo;
	
	QueryText = "CASE " + QueryText + ?(IsBlankString(QueryText), "", Chars.LF) + " Else 0 End" + ?(WithName, " AS ExecutionTime, ", ",");
	
	Return QueryText;
	
EndFunction

#EndRegion

#EndIf
