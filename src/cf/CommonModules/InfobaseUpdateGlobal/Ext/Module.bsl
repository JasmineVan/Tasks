///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Private

// Checks deferred update status. If there occurred errors during an update procedure, this function 
// informs a user and an administrator about it.
//
Procedure CheckDeferredUpdateStatus() Export
	
	ClientParameters = StandardSubsystemsClient.ClientParametersOnStart();
	
	If ClientParameters.Property("ShowInvalidHandlersMessage") Then
		OpenForm("DataProcessor.ApplicationUpdateResult.Form.DeferredIBUpdateProgressIndicator");
	Else
		InfobaseUpdateClient.NotifyDeferredHandlersNotExecuted();
	EndIf;
	
EndProcedure

#EndRegion
