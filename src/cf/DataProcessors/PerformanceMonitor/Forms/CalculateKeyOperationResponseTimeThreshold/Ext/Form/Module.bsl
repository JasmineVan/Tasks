///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region EventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	Parameters.Property("KeyOperation", KeyOperation);
	If Not ValueIsFilled(Period.StartDate) Then
		Period.StartDate = AddMonth(BegOfDay(CurrentSessionDate()), -3);
	EndIf;
	If Not ValueIsFilled(Period.EndDate) Then
		Period.EndDate = BegOfDay(CurrentSessionDate());
	EndIf;
EndProcedure

#EndRegion

#Region FormCommandHandlers

&AtClient
Procedure CalculateResponseTimeThreshold(Command)                             
	CheckResult = FillChecking();
	If CheckResult Then
		
		CalculationParameters = New Structure;
		CalculationParameters.Insert("KeyOperation", KeyOperation);
		CalculationParameters.Insert("StartDate", Period.StartDate);
		CalculationParameters.Insert("EndDate", Period.EndDate);
		CalculationParameters.Insert("TargetAPDEX", CurrentAPDEX);		
		CalculationResult = CalculateResponseTimeThresholdAtServer(CalculationParameters);
		If CalculationResult.Property("ErrorDescription") Then
			Message = New UserMessage;
			Message.Text = CalculationResult.ErrorDescription;
			Message.Message();
			Return;
		EndIf;
		EstimatedAPDEX = CalculationResult.EstimatedAPDEX;
		MeasurementsCount = CalculationResult.MeasurementsCount;
		ResponseTimeThreshold = CalculationResult.ResponseTimeThreshold;
		
		APDEXScoreChart.ChartType = ChartType.Line;
		APDEXScoreChart.PlotArea.ValuesScale.TitleText = NStr("ru = 'Количество замеров, шт'; en = 'Number of measurements, pcs'; pl = 'Number of measurements, pcs';de = 'Number of measurements, pcs';ro = 'Number of measurements, pcs';tr = 'Number of measurements, pcs'; es_ES = 'Number of measurements, pcs'");
		APDEXScoreChart.Clear();
		Series = APDEXScoreChart.Series.Add("Time execution, with");		
		For Each Measurement In CalculationResult.Measurements Do
			For Each Record In Measurement Do
				Dot = APDEXScoreChart.Points.Add(Record.Key);
				Dot.Text = Format(Record.Key, "NZ=0");
				APDEXScoreChart.SetValue(Dot, Series, Record.Value);
			EndDo;
		EndDo;		
	EndIf;
EndProcedure


#EndRegion

#Region Private

&AtClient
Function FillChecking()
	Success = True;
	If KeyOperation.IsEmpty() Then
		Message = New UserMessage;
		Message.Text = NStr("ru = 'Не указана ключевая операция.'; en = 'The key operation is not specified.'; pl = 'The key operation is not specified.';de = 'The key operation is not specified.';ro = 'The key operation is not specified.';tr = 'The key operation is not specified.'; es_ES = 'The key operation is not specified.'");
		Message.Field = "KeyOperation";
		Message.Message();
		Success = False;
	EndIf;
	If Not ValueIsFilled(CurrentAPDEX) Then
		Message = New UserMessage;
		Message.Text = NStr("ru = 'Не указан текущий APDEX.'; en = 'The current APDEX is not specified.'; pl = 'The current APDEX is not specified.';de = 'The current APDEX is not specified.';ro = 'The current APDEX is not specified.';tr = 'The current APDEX is not specified.'; es_ES = 'The current APDEX is not specified.'");
		Message.Field = "CurrentApdex";
		Message.Message();
		Success = False;
	EndIf;
	If Not ValueIsFilled(Period.StartDate) Then
		Message = New UserMessage;
		Message.Text = NStr("ru = 'Не указана дата начала периода.'; en = 'Period start date is not specified.'; pl = 'Period start date is not specified.';de = 'Period start date is not specified.';ro = 'Period start date is not specified.';tr = 'Period start date is not specified.'; es_ES = 'Period start date is not specified.'");
		Message.Field = "Period";
		Message.Message();
		Success = False;
	EndIf;
	If Not ValueIsFilled(Period.EndDate) Then
		Message = New UserMessage;
		Message.Text = NStr("ru = 'Не указана дата окончания периода.'; en = 'Period end date is not specified.'; pl = 'Period end date is not specified.';de = 'Period end date is not specified.';ro = 'Period end date is not specified.';tr = 'Period end date is not specified.'; es_ES = 'Period end date is not specified.'");
		Message.Field = "Period";
		Message.Message();
		Success = False;
	EndIf;
	Return Success;
EndFunction

&AtServerNoContext
Function CalculateResponseTimeThresholdAtServer(CalculationParameters)
	
	CalculationResult = New Structure;
	CalculationResult.Insert("Measurements", New Array);
	CalculationResult.Insert("MeasurementsCount", 0);
	CalculationResult.Insert("ResponseTimeThreshold", 0);
	CalculationResult.Insert("EstimatedAPDEX", 0);
	Minimum = 0;
	Max = 0;
	PermissibleDifference = 0.01;
	MaxNumberOfIterations = 1000;
	Counter = 0;
	TTM = New TempTablesManager;
	
	
	Query = New Query("SELECT
	                      |	Measurements.RunTime AS RunTime,
	                      |	1 AS MeasurementsCount
	                      |INTO OperationMeasurements
	                      |FROM
	                      |	InformationRegister.TimeMeasurements AS Measurements
	                      |WHERE
	                      |	Measurements.MeasurementStartDate BETWEEN &StartDate AND &EndDate
	                      |	AND Measurements.KeyOperation = &KeyOperation
	                      |;
	                      |
	                      |////////////////////////////////////////////////////////////////////////////////
	                      |SELECT
	                      |	ISNULL(MAX(OperationMeasurements.RunTime), 0) AS MAXIMUMRunTime,
	                      |	ISNULL(MIN(OperationMeasurements.RunTime), 0) AS MINIMUMRunTime,
	                      |	ISNULL(SUM(OperationMeasurements.MeasurementsCount), 0) AS MeasurementsCount
	                      |FROM
	                      |	OperationMeasurements AS OperationMeasurements");
	Query.TempTablesManager = TTM;
	Query.SetParameter("StartDate", (CalculationParameters.StartDate - Date(1,1,1)) * 1000);	
	Query.SetParameter("EndDate", (CalculationParameters.EndDate - Date(1,1,1)) * 1000);
	Query.SetParameter("KeyOperation", CalculationParameters.KeyOperation);
	
	Selection = Query.Execute().Select();
	If Selection.Next() Then
		Minimum = Selection.MINIMUMRunTime;
		Max = Selection.MAXIMUMRunTime;
		CalculationResult.MeasurementsCount = Selection.MeasurementsCount;
	Else
		CalculationResult.Insert("ErrorDescription", NStr("ru = 'Не удалось получить данные о замерах, попробуйте изменить настройки.'; en = 'Cannot receive data on measurements, try to change settings.'; pl = 'Cannot receive data on measurements, try to change settings.';de = 'Cannot receive data on measurements, try to change settings.';ro = 'Cannot receive data on measurements, try to change settings.';tr = 'Cannot receive data on measurements, try to change settings.'; es_ES = 'Cannot receive data on measurements, try to change settings.'"));
		Return CalculationResult;
	EndIf;
	
	If CalculationResult.MeasurementsCount = 0 Then
		CalculationResult.Insert("ErrorDescription",
			StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'Получено 0 замеров по ключевой операции %1. Измените период или выберите другую ключевую операцию.'; en = '0 measurements are received by the %1 key operation. Change the period or select another key operation.'; pl = '0 measurements are received by the %1 key operation. Change the period or select another key operation.';de = '0 measurements are received by the %1 key operation. Change the period or select another key operation.';ro = '0 measurements are received by the %1 key operation. Change the period or select another key operation.';tr = '0 measurements are received by the %1 key operation. Change the period or select another key operation.'; es_ES = '0 measurements are received by the %1 key operation. Change the period or select another key operation.'"),
				CalculationParameters.KeyOperation));
		Return CalculationResult;
	EndIf;
	
	CurrentResponseTimeThreshold = (Minimum + Max) / 2;
	EstimatedAPDEX = ApdexValue(TTM, CurrentResponseTimeThreshold);
	Deviation = Max(EstimatedAPDEX - CalculationParameters.TargetAPDEX, CalculationParameters.TargetAPDEX - EstimatedAPDEX);
	
	While Deviation > PermissibleDifference
		AND Counter < MaxNumberOfIterations
		Do
		Counter = Counter + 1;
		DataMin = DeviationAPDEX(Minimum, CurrentResponseTimeThreshold, TTM, CalculationParameters.TargetAPDEX);
		DataMax = DeviationAPDEX(Max, CurrentResponseTimeThreshold, TTM, CalculationParameters.TargetAPDEX);
		
		If Max - Minimum <= 0.002 Then
			Break;
		ElsIf DataMin.Deviation <= DataMax.Deviation Then
			Max = CurrentResponseTimeThreshold;
			CurrentResponseTimeThreshold = DataMin.CurrentResponseTimeThreshold;			
			Deviation = DataMin.Deviation;
			EstimatedAPDEX = DataMin.APDEX;
		ElsIf DataMin.Deviation > DataMax.Deviation Then
			Minimum = CurrentResponseTimeThreshold;
			CurrentResponseTimeThreshold = DataMax.CurrentResponseTimeThreshold;			
			Deviation = DataMax.Deviation;
			EstimatedAPDEX = DataMax.APDEX;
		EndIf;
		
	EndDo;
	
	CalculationResult.ResponseTimeThreshold = CurrentResponseTimeThreshold;
	CalculationResult.EstimatedAPDEX = EstimatedAPDEX; 
	CalculationResult.Measurements = MeasurementsMap(TTM);
		
	Return CalculationResult;
	
EndFunction

&AtServerNoContext
Function DeviationAPDEX(IntervalEndpoint, CurrentResponseTimeThreshold, TempTablesManager, TargetAPDEX)
	CurrentResponseTimeThresholdNew = Round((IntervalEndpoint + CurrentResponseTimeThreshold) / 2, 3);
	APDEX = ApdexValue(TempTablesManager, CurrentResponseTimeThresholdNew);
	Deviation = Max(APDEX - TargetAPDEX, TargetAPDEX - APDEX);	
	Return New Structure("CurrentResponseTimeThreshold, APDEX, Deviation", CurrentResponseTimeThresholdNew, APDEX, Deviation)
EndFunction

&AtServerNoContext
Function MeasurementsMap(TempTablesManager)
	MeasurementsMap = New Array;
	Query = New Query("SELECT
	                      |	CAST(OperationMeasurements.RunTime AS NUMBER(15, 0)) AS RunTime,
	                      |	SUM(OperationMeasurements.MeasurementsCount) AS MeasurementsCount
	                      |FROM
	                      |	OperationMeasurements AS OperationMeasurements
	                      |
	                      |GROUP BY
	                      |	CAST(OperationMeasurements.RunTime AS NUMBER(15, 0))
	                      |
	                      |ORDER BY
	                      |	RunTime");
	Query.TempTablesManager = TempTablesManager;
	Selection = Query.Execute().Select();
	While Selection.Next() Do
		Measurement = New Map;
		Measurement.Insert(Selection.RunTime, Selection.MeasurementsCount);
		MeasurementsMap.Add(Measurement);
	EndDo;
	Return MeasurementsMap;
EndFunction

&AtServerNoContext
Function ApdexValue(TempTablesManager, CurrentResponseTimeThreshold)
	Query = New Query("SELECT
	               |	SUM(CASE
	               |			WHEN OperationMeasurements.RunTime <= &ResponseTimeThreshold
	               |				THEN OperationMeasurements.MeasurementsCount
	               |			ELSE 0
	               |		END) AS T,
	               |	SUM(CASE
	               |			WHEN OperationMeasurements.RunTime > &ResponseTimeThreshold
	               |					AND OperationMeasurements.RunTime <= 4 * &ResponseTimeThreshold
	               |				THEN OperationMeasurements.MeasurementsCount
	               |			ELSE 0
	               |		END) AS T_4T,
	               |	SUM(OperationMeasurements.MeasurementsCount) AS N,
	               |	ISNULL((SUM(CASE
	               |			WHEN OperationMeasurements.RunTime <= &ResponseTimeThreshold
	               |				THEN OperationMeasurements.MeasurementsCount
	               |			ELSE 0
	               |		END) + SUM(CASE
	               |			WHEN OperationMeasurements.RunTime > &ResponseTimeThreshold
	               |					AND OperationMeasurements.RunTime <= 4 * &ResponseTimeThreshold
	               |				THEN OperationMeasurements.MeasurementsCount
	               |			ELSE 0
	               |		END) / 2) / SUM(OperationMeasurements.MeasurementsCount),0) AS APDEX
	               |FROM
	               |	OperationMeasurements AS OperationMeasurements");
	Query.TempTablesManager = TempTablesManager;
	Query.SetParameter("ResponseTimeThreshold", CurrentResponseTimeThreshold);
	Selection = Query.Execute().Select();
	Selection.Next();
	Return Round(Selection.APDEX, 3);
EndFunction

#EndRegion