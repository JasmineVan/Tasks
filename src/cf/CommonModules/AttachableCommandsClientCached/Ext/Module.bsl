///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Private

// Returns command details by form item name.
Function CommandDetails(CommandName, SettingsAddress) Export
	Return AttachableCommandsServerCall.CommandDetails(CommandName, SettingsAddress);
EndFunction

#EndRegion
