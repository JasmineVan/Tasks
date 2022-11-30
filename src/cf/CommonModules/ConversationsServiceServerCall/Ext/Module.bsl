///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Internal

Function Connected() Export
	
	If ConversationsService.Locked() Then 
		Return False;
	EndIf;
	
	// Server call ensures that you get the correct state in case infobase registration data was changed 
	// by method
	// CollaborationSystem.SetInfoBaseRegistrationData.
	Return CollaborationSystem.InfoBaseRegistered();
	
EndFunction

Procedure Unlock() Export 
	
	ConversationsService.Unlock();
	
EndProcedure

#EndRegion