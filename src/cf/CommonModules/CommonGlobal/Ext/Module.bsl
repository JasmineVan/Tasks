///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Private

// Asks whether the user wants to continue the action that will discard the changes.
//
Procedure ConfirmFormClosingNow() Export
	
	CommonInternalClient.ConfirmFormClosing();
	
EndProcedure

// Asks whether the user wants to continue the action that closes the form.
//
Procedure ConfirmArbitraryFormClosingNow() Export
	
	CommonInternalClient.ConfirmArbitraryFormClosing();
	
EndProcedure

#EndRegion
