///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region EventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	OpenFormsToCopy = Parameters.OpenFormsToCopy;
	Items.ActiveUsersGroup.Visible    = Parameters.HasActiveUsersRecipients;
	Items.OpenFormsWithSettingsBeingCopiedGroup.Visible = ValueIsFilled(OpenFormsToCopy);
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure ActiveUserListClick(Item)
	
	StandardSubsystemsClient.OpenActiveUserList();
	
EndProcedure

&AtClient
Procedure OpenFormsURLProcessingMessage(Item, FormattedStringURL, StandardProcessing)
	ShowMessageBox(, OpenFormsToCopy);
	StandardProcessing = False;
EndProcedure

#EndRegion

#Region FormCommandHandlers

&AtClient
Procedure Copy(Command)
	
	If Parameters.Action <> "CopyAndClose" Then
		Close();
	EndIf;
	
	Result = New Structure("Action", Parameters.Action);
	Notify("CopySettingsToActiveUsers", Result);
	
EndProcedure

#EndRegion
