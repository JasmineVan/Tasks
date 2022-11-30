///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region EventHandlers

&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)
	OpeningParameters = New Structure;
	If TypeOf(CommandExecuteParameters.Source) = Type("ManagedForm") Then
		OpeningParameters.Insert("JobID", CommandExecuteParameters.Source.MonitoringCenterJobID);
		OpeningParameters.Insert("JobResultAddress", CommandExecuteParameters.Source.MonitoringCenterJobResultAddress);
	EndIf;
	OpenForm("DataProcessor.MonitoringCenterSettings.Form.MonitoringCenterSettings", OpeningParameters, ThisObject,,,,,FormWindowOpeningMode.LockOwnerWindow);
EndProcedure

#EndRegion