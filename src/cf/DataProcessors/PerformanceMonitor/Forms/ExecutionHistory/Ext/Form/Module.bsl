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
	
	KeyOperation = Parameters.HistorySettings.KeyOperation;
	StartDate = Parameters.HistorySettings.StartDate;
	EndDate = Parameters.HistorySettings.EndDate;
	Priority = KeyOperation.Priority;
	ResponseTimeThreshold = KeyOperation.ResponseTimeThreshold;
	
	Query = New Query;
	Query.SetParameter("KeyOperation", KeyOperation);
	Query.SetParameter("StartDate", (StartDate - Date(1,1,1)) * 1000);
	Query.SetParameter("EndDate", (EndDate - Date(1,1,1)) * 1000);
	
	Query.Text = 
	"SELECT
	|	TimeMeasurements.User AS User,
	|	TimeMeasurements.RunTime AS Duration,
    |   DATEADD(DATETIME(2015,1,1), SECOND, (TimeMeasurements.MeasurementStartDate/1000) - 63555667200) AS EndTime
	|FROM
	|	InformationRegister.TimeMeasurements AS TimeMeasurements
	|WHERE
	|	TimeMeasurements.KeyOperation = &KeyOperation
	|	AND TimeMeasurements.MeasurementStartDate BETWEEN &StartDate AND &EndDate
	|ORDER BY
	|	EndTime";
    
    Result = Query.Execute();
	Selection = Result.Select();
	MeasurementsCountNumber = Selection.Count();
	MeasurementsCount = String(MeasurementsCountNumber) + ?(MeasurementsCountNumber < 100, " (insufficient)", "");
	
	While Selection.Next() Do
		
		HistoryRow = History.Add();
		FillPropertyValues(HistoryRow, Selection);
		
	EndDo;
	
EndProcedure

#EndRegion

#Region HistoryFormTableItemEventHandlers

// Disables key operation editing from the processing form as this can affect internal mechanisms.
// 
//
&AtClient
Procedure KeyOperationOpening(Item, StandardProcessing)
	
	StandardProcessing = False;
	
EndProcedure

#EndRegion
