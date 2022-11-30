///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Internal

// Generates a value table to display to the user.
//
// Returns:
//  ValueTable - the resulting value table.
//
Function PerformanceIndicators() Export
	
	EvaluationParameters = ParametersStructureForAPDEXCalculation();
	
	StepValue = 0;
	StepsCount = 0;
	If Not ChartPeriodicity(StepValue, StepsCount) Then
		Return Undefined;
	EndIf;
	
	EvaluationParameters.StepValue = StepValue;
	EvaluationParameters.StepsCount = StepsCount;
	EvaluationParameters.StartDate = StartDate;
	EvaluationParameters.EndDate = EndDate;
	EvaluationParameters.KeyOperationTable = Performance.Unload(, "KeyOperation, Priority, ResponseTimeThreshold");
	If Not ValueIsFilled(OverallSystemPerformance) Or Performance.Find(OverallSystemPerformance, "KeyOperation") = Undefined Then
		EvaluationParameters.OutputTotals = False
	Else
		EvaluationParameters.OutputTotals = True;
	EndIf;
	EvaluationParameters.Comment = Comment;
	If NOT IsBlankString(Comment) Then
		EvaluationParameters.FilterOptionComment = FilterOptionComment;
	Else
		EvaluationParameters.FilterOptionComment = "DontFilter";
	EndIf;
	
	Return EvaluateApdex(EvaluationParameters);
	
EndFunction

// Generates a query dynamically and gets the Apdex value.
//
// Parameters:
//  EvaluationParameters - Structure - a structure with the following properties:
//		* StepValue					- Number				- a step size in seconds.
//		* StepsCount			- Number				- a number of steps per period.
//		* StartDate				- Date				- measurement start date.
//		* EndDate				- Date				- measurement end date.
//		* KeyOperationsTable	- ValueTable	- data to select from. Columns:
//			** KeyOperation		- CatalogRef.KeyOperations	- key operation.
//			** RowNumber			- Number								- a key operation priority.
//			** TimeThreshold		- Number								- key operation time threshold.
//		* OutputTotals				- Boolean.
//
// Returns:
//  ValueTable - a table of key operations and performance figures over the period.
//  
//
Function EvaluateApdex(EvaluationParameters) Export
	Query = New Query;
	Query.SetParameter("KeyOperationTable", EvaluationParameters.KeyOperationTable);
	Query.SetParameter("BeginOfPeriod", (EvaluationParameters.StartDate - Date(1,1,1))* 1000);
	Query.SetParameter("EndOfPeriod", (EvaluationParameters.EndDate - Date(1,1,1)) * 1000);
	Query.SetParameter("KeyOperationTotal", OverallSystemPerformance);
	
	Query.TempTablesManager = New TempTablesManager;
	Query.Text =
	"SELECT
	|	KeyOperations.KeyOperation AS KeyOperation,
	|	KeyOperations.Priority AS Priority,
	|	KeyOperations.ResponseTimeThreshold AS ResponseTimeThreshold
	|INTO KeyOperations
	|FROM
	|	&KeyOperationTable AS KeyOperations";
	Query.Execute();
	
	QueryText = 
	"SELECT
	|	KeyOperations.KeyOperation AS KeyOperation,
	|	KeyOperations.Priority AS Priority,
	|	KeyOperations.ResponseTimeThreshold AS ResponseTimeThreshold%Columns%
	|FROM
	|	KeyOperations AS KeyOperations
	|LEFT JOIN
	|	InformationRegister.TimeMeasurements AS TimeMeasurements
	|ON
	|	KeyOperations.KeyOperation = TimeMeasurements.KeyOperation
	|	AND TimeMeasurements.MeasurementStartDate BETWEEN &BeginOfPeriod AND &EndOfPeriod
	|	%ConditionComment%
	|WHERE
	|	NOT KeyOperations.KeyOperation = &KeyOperationTotal
	|
	|GROUP BY
	|	KeyOperations.KeyOperation,
	|	KeyOperations.Priority,
	|	KeyOperations.ResponseTimeThreshold
	|%Totals%";
	
	Expression = 
	"
	|	CASE
	|		WHEN 
	|			// No key operation measurement records within this period
	|			NOT 1 IN (
	|				SELECT TOP 1
	|					1 
	|				FROM 
	|					InformationRegister.TimeMeasurements AS InternalTimeMeasurements
	|				WHERE
	|					InternalTimeMeasurements.KeyOperation = KeyOperations.KeyOperation 
	|					AND InternalTimeMeasurements.KeyOperation <> &KeyOperationTotal
	|					AND InternalTimeMeasurements.MeasurementStartDate BETWEEN &BeginOfPeriod AND &EndOfPeriod
	|					AND InternalTimeMeasurements.MeasurementStartDate >= &BeginOfPeriod%Number% 
	|					AND InternalTimeMeasurements.MeasurementStartDate <= &EndOfPeriod%Number%
	|					%ConditionCommentInternal%
	|			) 
	|			THEN 0
	|
	|		ELSE (CAST((SUM(CASE
	|								WHEN TimeMeasurements.MeasurementStartDate >= &BeginOfPeriod%Number%
	|										AND TimeMeasurements.MeasurementStartDate <= &EndOfPeriod%Number%
	|									THEN CASE
	|											WHEN TimeMeasurements.RunTime <= KeyOperations.ResponseTimeThreshold
	|												THEN 1
	|											ELSE 0
	|										END
	|								ELSE 0
	|							END) + SUM(CASE
	|								WHEN TimeMeasurements.MeasurementStartDate >= &BeginOfPeriod%Number%
	|										AND TimeMeasurements.MeasurementStartDate <= &EndOfPeriod%Number%
	|									THEN CASE
	|											WHEN TimeMeasurements.RunTime > KeyOperations.ResponseTimeThreshold
	|													AND TimeMeasurements.RunTime <= KeyOperations.ResponseTimeThreshold * 4
	|												THEN 1
	|											ELSE 0
	|										END
	|								ELSE 0
	|							END) / 2) / SUM(CASE
	|								WHEN TimeMeasurements.MeasurementStartDate >= &BeginOfPeriod%Number%
	|										AND TimeMeasurements.MeasurementStartDate <= &EndOfPeriod%Number%
	|									THEN 1
	|								ELSE 0
	|							END) + 0.001 AS NUMBER(6, 3)))
	|	END AS Performance%Number%";
	
	ExpressionForTotals = 
	"
	|	SUM(CASE
	|			WHEN TimeMeasurements.MeasurementStartDate >= &BeginOfPeriod%Number%
	|					AND TimeMeasurements.MeasurementStartDate <= &EndOfPeriod%Number%
	|				THEN 1
	|			ELSE 0
	|		END) AS TimeTotal%Number%,
	|	SUM(CASE
	|			WHEN TimeMeasurements.MeasurementStartDate >= &BeginOfPeriod%Number%
	|					AND TimeMeasurements.MeasurementStartDate <= &EndOfPeriod%Number%
	|				THEN CASE
	|						WHEN TimeMeasurements.RunTime <= KeyOperations.ResponseTimeThreshold
	|							THEN 1
	|						ELSE 0
	|					END
	|			ELSE 0
	|		END) AS TimeBefore%Number%,
	|	SUM(CASE
	|			WHEN TimeMeasurements.MeasurementStartDate >= &BeginOfPeriod%Number%
	|					AND TimeMeasurements.MeasurementStartDate <= &EndOfPeriod%Number%
	|				THEN CASE
	|						WHEN TimeMeasurements.RunTime > KeyOperations.ResponseTimeThreshold
	|								AND TimeMeasurements.RunTime <= KeyOperations.ResponseTimeThreshold * 4
	|							THEN 1
	|						ELSE 0
	|					END
	|			ELSE 0
	|		END) AS TimeBetweenT4T%Number%";
	
	Total = 
	"
	|	MAX(TimeTotal%Number%)";
	
	ByOverall = 
	"
	|ON
	|	OVERALL";
	
	ColumnHeaders = New Array;
	Columns = "";
	Totals = "";
	BeginOfPeriod = EvaluationParameters.StartDate;
	For CurStep = 0 To EvaluationParameters.StepsCount - 1 Do
		
		EndOfPeriod = ?(CurStep = EvaluationParameters.StepsCount - 1, EvaluationParameters.EndDate, BeginOfPeriod + EvaluationParameters.StepValue - 1);
		
		StepIndex = Format(CurStep, "NZ=0; NG=0");
		Query.SetParameter("BeginOfPeriod" + StepIndex, (BeginOfPeriod - Date(1,1,1)) * 1000);
		Query.SetParameter("EndOfPeriod" + StepIndex, (EndOfPeriod - Date(1,1,1)) * 1000);
		
		ColumnHeaders.Add(ColumnHeader(BeginOfPeriod));
		
		BeginOfPeriod = BeginOfPeriod + EvaluationParameters.StepValue;
		
		Columns = Columns + ?(EvaluationParameters.OutputTotals, "," + ExpressionForTotals, "") + "," + Expression;
		Columns = StrReplace(Columns, "%Number%", StepIndex);
		
		If EvaluationParameters.OutputTotals Then
			Totals = Totals + Total + ?(CurStep = EvaluationParameters.StepsCount - 1, "", ",");
			Totals = StrReplace(Totals, "%Number%", StepIndex);
		EndIf;
		
	EndDo;
	
	QueryText = StrReplace(QueryText, "%Columns%", Columns);
	QueryText = StrReplace(QueryText, "%Totals%", ?(EvaluationParameters.OutputTotals, "TOTALS" + Totals, ""));
	QueryText = QueryText + ?(EvaluationParameters.OutputTotals, ByOverall, "");
	
	If EvaluationParameters.FilterOptionComment = "DontFilter" Then
		QueryText = StrReplace(QueryText, "%ConditionComment%", "");
		QueryText = StrReplace(QueryText, "%ConditionCommentInternal%", "");
	ElsIf EvaluationParameters.FilterOptionComment = "EqualTo" Then
		QueryText = StrReplace(QueryText, "%ConditionComment%", "AND TimeMeasurements.Comment = &Comment");
		QueryText = StrReplace(QueryText, "%ConditionCommentInternal%", "AND InternalTimeMeasurements.Comment = &Comment");
		Query.SetParameter("Comment", EvaluationParameters.Comment);
	ElsIf EvaluationParameters.FilterOptionComment = "Contains" Then
		QueryText = StrReplace(QueryText, "%ConditionComment%", "AND TimeMeasurements.Comment LIKE &Comment");
		QueryText = StrReplace(QueryText, "%ConditionCommentInternal%", "AND InternalTimeMeasurements.Comment LIKE &Comment");
		Query.SetParameter("Comment", "%" + EvaluationParameters.Comment + "%");
	EndIf;
	
	Query.Text = QueryText;
	Result = Query.Execute();
	
	If Result.IsEmpty() Then
		Return New ValueTable;
	Else
		KeyOperationTable = Result.Unload();
		
		KeyOperationTable.Sort("Priority");
		If EvaluationParameters.OutputTotals Then
			KeyOperationTable[0][0] = OverallSystemPerformance;
			CalculateTotalApdex(KeyOperationTable);
		EndIf;
		
		ColumnIndex = 0;
		ArrayIndex = 0;
		While ColumnIndex <= KeyOperationTable.Columns.Count() - 1 Do
			
			KeyOperationTableColumn = KeyOperationTable.Columns[ColumnIndex];
			If StrStartsWith(KeyOperationTableColumn.Name, "Temp") Then
				KeyOperationTable.Columns.Delete(KeyOperationTableColumn);
				Continue;
			EndIf;
			
			If ColumnIndex < 3 Then
				ColumnIndex = ColumnIndex + 1;
				Continue;
			EndIf;
			KeyOperationTableColumn.Title = ColumnHeaders[ArrayIndex];
			
			ArrayIndex = ArrayIndex + 1;
			ColumnIndex = ColumnIndex + 1;
			
		EndDo;
		
		Return KeyOperationTable;
	EndIf;
	
EndFunction

// Creates a parameter structure required for calculating APDEX.
//
// Returns:
//  Structure - 
//  	StepValue - Number - a step size in seconds.
//  	StepsCount - Number - number of steps per period.
//  	StartDate - Date - measurement start date.
//  	EndDate - Date - measurement end date.
//  	KeyOperationTable - ValueTable,
//  		KeyOperation - CatalogRef.KeyOperations, key operation.
//  		LineNumber - Number - key operation priority.
//  		ResponseTimeThreshold - Number - key operation time threshold.
//  	OutputTotals - Boolean,
//  		True to calculate the overall performance,
//  		False otherwise.
//
Function ParametersStructureForAPDEXCalculation() Export
	ParametersStructure = New Structure;
	
	ParametersStructure.Insert("StepValue");
	ParametersStructure.Insert("StepsCount");
	ParametersStructure.Insert("StartDate");
	ParametersStructure.Insert("EndDate");
	ParametersStructure.Insert("KeyOperationTable");
	ParametersStructure.Insert("OutputTotals");
	ParametersStructure.Insert("Comment");
	ParametersStructure.Insert("FilterOptionComment");
	
	Return ParametersStructure;
EndFunction

// Calculates the size and number of steps over a given interval.
//
// Parameters:
//  StepValue		- Number - a number of seconds to add to the start date to proceed to the next step.
//  StepsCount - Number - number of steps over the specified interval.
//
// Returns:
//  Boolean:
//  	True if parameters are calculated,
//  	False otherwise.
//
Function ChartPeriodicity(StepValue, StepsCount) Export
	TimeDifference = EndDate - StartDate + 1;
	
	If TimeDifference <= 0 Then
		Return False;
	EndIf;
	
	// StepCount is an integer rounded upwards.
	StepsCount = 0;
	If Step = "Hour" Then
		StepValue = 86400 / 24;
		StepsCount = TimeDifference / StepValue;
		StepsCount = Int(StepsCount) + ?(StepsCount - Int(StepsCount) > 0, 1, 0);
	ElsIf Step = "Day" Then
		StepValue = 86400;
		StepsCount = TimeDifference / StepValue;
		StepsCount = Int(StepsCount) + ?(StepsCount - Int(StepsCount) > 0, 1, 0);
	ElsIf Step = "Week" Then
		StepValue = 86400 * 7;
		StepsCount = TimeDifference / StepValue;
		StepsCount = Int(StepsCount) + ?(StepsCount - Int(StepsCount) > 0, 1, 0);
	ElsIf Step = "Month" Then
		StepValue = 86400 * 30;
		Temp = EndOfDay(StartDate);
		While Temp <= EndDate Do
			Temp = AddMonth(Temp, 1);
			StepsCount = StepsCount + 1;
		EndDo;
	Else
		StepValue = 0;
		StepsCount = 1;
	EndIf;
	
	Return True;
	
EndFunction

#EndRegion

#Region Private

// Calculates the total APDEX.
//
// Parameters:
//  KeyOperationTable - ValueTable - result of the query for APDEX calculation.
//
Procedure CalculateTotalApdex(KeyOperationTable)
	
	// Starting with the 4th column (the first 3 are KeyOperation, Priority, ResponseTimeThreshold).
	InitialColumnIndex	= 3;
	TotalRowIndex		= 0;
	PriorityColumnIndex	= 1;
	LastStringIndex	= KeyOperationTable.Count() - 1;
	LatestColumnIndex	= KeyOperationTable.Columns.Count() - 1;
	MinPriority	= KeyOperationTable[LastStringIndex][PriorityColumnIndex];
	
	// Clearing the totals row
	For Column = PriorityColumnIndex To LatestColumnIndex Do
		If NOT ValueIsFilled(KeyOperationTable[TotalRowIndex][Column]) Then
			KeyOperationTable[TotalRowIndex][Column] = 0;
		EndIf;
	EndDo;
	
	If MinPriority < 1 Then
		MinPriority = 1;
	EndIf;
	
	Column = InitialColumnIndex;
	While Column < LatestColumnIndex Do
		N = 0;
		NS = 0;
		NT = 0;
		
		MaxOperationsOverPeriod = KeyOperationTable[TotalRowIndex][Column];
		
		// Starting with 1, as 0 is the totals row.
		For Row = 1 To LastStringIndex Do
			
			CurrentOperationPriority = KeyOperationTable[Row][PriorityColumnIndex];
			CurrentOperationCount = KeyOperationTable[Row][Column];
			
			Coefficient = ?(CurrentOperationCount = 0, 0, 
							MaxOperationsOverPeriod / CurrentOperationCount * (1 - (CurrentOperationPriority - 1) / MinPriority));
			
			KeyOperationTable[Row][Column] = KeyOperationTable[Row][Column] * Coefficient;
			KeyOperationTable[Row][Column + 1] = KeyOperationTable[Row][Column + 1] * Coefficient;
			KeyOperationTable[Row][Column + 2] = KeyOperationTable[Row][Column + 2] * Coefficient;
			
			N = N + KeyOperationTable[Row][Column];
			NS = NS + KeyOperationTable[Row][Column + 1];
			NT = NT + KeyOperationTable[Row][Column + 2];
		EndDo;
		
		If N = 0 Then
			FinalApdex = 0;
		ElsIf NS = 0 AND NT = 0 AND N <> 0 Then
			FinalApdex = 0.001;
		Else
			FinalApdex = (NS + NT / 2) / N;
		EndIf;
		KeyOperationTable[TotalRowIndex][Column + 3] = FinalApdex;
		
		Column = Column + 4;
		
	EndDo;
	
EndProcedure

Function ColumnHeader(BeginOfPeriod)
	
	If Step = "Hour" Then
		ColumnHeader = String(Format(BeginOfPeriod, "DLF=T"));
	Else
		ColumnHeader = String(Format(BeginOfPeriod, "DLF=D"));
	EndIf;
	
	Return ColumnHeader;
	
EndFunction

#EndRegion

#Else
Raise NStr("ru = 'Недопустимый вызов объекта на клиенте.'; en = 'Invalid object call on the client.'; pl = 'Invalid object call on the client.';de = 'Invalid object call on the client.';ro = 'Invalid object call on the client.';tr = 'Invalid object call on the client.'; es_ES = 'Invalid object call on the client.'");
#EndIf