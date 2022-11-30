///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Private

// Completes measuring the time of a key operation.
// The procedure is called from an idle handler.
Procedure EndTimeMeasurementAuto() Export
	
	PerformanceMonitorClient.StopTimeMeasurementAtClientAuto();
		
EndProcedure

// Calls the server function for recording measurement results.
// The procedure is called from an idle handler.
Procedure WriteResultsAuto() Export
	
	PerformanceMonitorClient.WriteResultsAutoNotGlobal();
	
EndProcedure

#EndRegion
