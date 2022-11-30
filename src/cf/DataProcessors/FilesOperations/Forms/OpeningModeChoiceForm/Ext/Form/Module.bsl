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
	
	DontAskAgain = False;
	If Common.IsMobileClient() Then
		CommandBarLocation = FormCommandBarLabelLocation.Top;
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandHandlers

&AtClient
Procedure OpenFile(Command)
	
	If DontAskAgain = True Then
		CommonServerCall.CommonSettingsStorageSave(
			"OpenFileSettings", "PromptForEditModeOnOpenFile", False,,, True);
		RefreshReusableValues();
	EndIf;
	
	SelectionResult = New Structure;
	SelectionResult.Insert("DontAskAgain", DontAskAgain);
	SelectionResult.Insert("HowToOpen", HowToOpen);
	NotifyChoice(SelectionResult);
	
EndProcedure

&AtClient
Procedure Cancel(Command)
	NotifyChoice(DialogReturnCode.Cancel);
EndProcedure

#EndRegion
