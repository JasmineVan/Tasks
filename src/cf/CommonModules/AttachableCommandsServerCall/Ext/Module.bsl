﻿///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Private

// Returns command details by form item name.
Function CommandDetails(CommandNameInForm, SettingsAddress) Export
	Return AttachableCommands.CommandDetails(CommandNameInForm, SettingsAddress);
EndFunction

// Analyzes the document array for posting and for rights to post them.
Function DocumentsInfo(RefsArray) Export
	Result = New Structure;
	Result.Insert("Unposted", Common.CheckDocumentsPosting(RefsArray));
	Result.Insert("HasRightToPost", StandardSubsystemsServer.HasRightToPost(Result.Unposted));
	Return Result;
EndFunction

#EndRegion
