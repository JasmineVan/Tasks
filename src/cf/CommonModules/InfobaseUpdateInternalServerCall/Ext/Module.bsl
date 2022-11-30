///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Private

// For description of this function, see the InfobaseUpdateInternal module.
Function UpdateInfobase(OnClientStart = False, Restart = False, ExecuteDeferredHandlers = False) Export
	
	UpdateParameters = InfobaseUpdateInternal.UpdateParameters();
	UpdateParameters.OnClientStart = OnClientStart;
	UpdateParameters.Restart = Restart;
	UpdateParameters.ExecuteDeferredHandlers = ExecuteDeferredHandlers;
	
	Try
		Result = InfobaseUpdateInternal.UpdateInfobase(UpdateParameters);
	Except
		// Preparing to open the form for data resynchronization before startup with two options, 
		// "Synchronize and continue" and "Continue".
		If Common.SubsystemExists("StandardSubsystems.DataExchange")
		   AND Common.IsSubordinateDIBNode() Then
			ModuleDataExchangeServer = Common.CommonModule("DataExchangeServer");
			ModuleDataExchangeServer.EnableDataExchangeMessageImportRecurrenceBeforeStart();
		EndIf;
		Raise;
	EndTry;
	
	Restart = UpdateParameters.Restart;
	Return Result;
	
EndFunction

// Unlocks file infobase.
Procedure RemoveFileInfobaseLock() Export
	
	If Not Common.FileInfobase() Then
		Return;
	EndIf;
	
	If Common.SubsystemExists("StandardSubsystems.UserSessionsCompletion") Then
		ModuleIBConnections = Common.CommonModule("IBConnections");
		ModuleIBConnections.AllowUserAuthorization();
	EndIf;
	
EndProcedure

#EndRegion
