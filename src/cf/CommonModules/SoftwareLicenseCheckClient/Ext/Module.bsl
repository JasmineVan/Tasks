﻿///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Public

// Asks the user to confirm that the update is received legally and closes the application if the 
// update is received illegally (see the TerminateApplication parameter).
// 
//
// Parameters:
//  Notification             - NotifyDescription - contains a handler called after confirming that 
//                                    the update is legal.
//  TerminateApplication - Boolean - close the application if the user specifies that the update is 
//                                    received illegally.
//
Procedure ShowLegitimateSoftwareCheck(Notification, TerminateApplication = False) Export
	
	If StandardSubsystemsClient.ClientRunParameters().IsBaseConfigurationVersion Then
		ExecuteNotifyProcessing(Notification, True);
		Return;
	EndIf;
	
	FormParameters = New Structure;
	FormParameters.Insert("ShowRestartWarning", TerminateApplication);
	FormParameters.Insert("OpenProgrammatically", True);
	
	OpenForm("DataProcessor.LegitimateSoftware.Form", FormParameters,,,,, Notification);
	
EndProcedure

#EndRegion

#Region Internal

// See CommonClientOverridable.BeforeStart. 
Procedure BeforeStart(Parameters) Export
	
	// Check whether the update is received legally on the application start.
	// The procedure is to be called before the infobase update.
	
	ClientParameters = StandardSubsystemsClient.ClientParametersOnStart();
	
	If Not ClientParameters.Property("CheckLegitimateSoftware") Then
		Return;
	EndIf;
	
	Parameters.InteractiveHandler = New NotifyDescription(
		"LegitimateSoftwareCheckInteractiveHandler", ThisObject);
	
EndProcedure

// For internal use only. Continues the execution of the CheckLegitimateSoftwareOnStart procedure.
Procedure LegitimateSoftwareCheckInteractiveHandler(Parameters, Context) Export
	
	FormParameters = New Structure;
	FormParameters.Insert("OpenProgrammatically", True);
	FormParameters.Insert("ShowRestartWarning", True);
	FormParameters.Insert("SkipRestart", True);
	
	OpenForm("DataProcessor.LegitimateSoftware.Form", FormParameters, , , , ,
		New NotifyDescription("AfterCloseLegitimateSoftwareCheckFormOnStart",
			ThisObject, Parameters));
	
EndProcedure

#EndRegion

#Region Private

// For internal use only. Continues the execution of the CheckLegitimateSoftwareOnStart procedure.
Procedure AfterCloseLegitimateSoftwareCheckFormOnStart(Result, Parameters) Export
	
	If Result <> True Then
		Parameters.Cancel = True;
	EndIf;
	
	ExecuteNotifyProcessing(Parameters.ContinuationHandler);
	
EndProcedure

#EndRegion
