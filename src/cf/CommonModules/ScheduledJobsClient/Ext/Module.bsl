///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Internal

// See CommonClientOverridable.OnStart. 
Procedure OnStart(Parameters) Export
	
	ClientRunParametersOnStart = StandardSubsystemsClient.ClientParametersOnStart();
	If ClientRunParametersOnStart.ShowExternalResourceLockForm Then
		Parameters.InteractiveHandler = New NotifyDescription("ShowExternalResourceLockForm", ThisObject);
	EndIf;
	
EndProcedure
	
// For internal use only.
Procedure ShowExternalResourceLockForm(Parameters, AdditionalParameters) Export
	
	FormParameters = New Structure("LockDecisionMaking", True);
	Notification = New NotifyDescription("AfterOpenOperationsWithExternalResourcesLockWindow", ThisObject, Parameters);
	OpenForm("CommonForm.ExternalResourcesOperationsLock", FormParameters,,,,, Notification);
	
EndProcedure

// For internal use only.
Procedure AfterOpenOperationsWithExternalResourcesLockWindow(Result, Parameters) Export
	
	ExecuteNotifyProcessing(Parameters.ContinuationHandler);
	
EndProcedure

#EndRegion