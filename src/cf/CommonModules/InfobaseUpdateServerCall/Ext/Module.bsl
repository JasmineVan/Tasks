///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Internal

// Used for integration with the subsystem "Configurations update".
// See the ConfigurationUpdateFileTemplate template for UpdateInstallation processing.
//
Function UpdateInfobase(ExecuteDeferredHandlers = False) Export
	
	StartDate = CurrentSessionDate();
	Result = InfobaseUpdate.UpdateInfobase(ExecuteDeferredHandlers);
	EndDate = CurrentSessionDate();
	InfobaseUpdateInternal.WriteUpdateExecutionTime(StartDate, EndDate);
	
	Return Result;
	
EndFunction

#EndRegion
