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
	DefineBehaviorInMobileClient();
EndProcedure

&AtClient
Procedure BeforeClose(Cancel, Exit, WarningText, StandardProcessing)
	If Exit Then
		Return;
	EndIf;
	
	CommonSettings = BeforeCloseAtServer(DisableDetails);
	Notify(
		ReportsOptionsClient.EventNameChangingCommonSettings(),
		CommonSettings,
		Undefined);
EndProcedure

#EndRegion

#Region FormCommandHandlers

&AtClient
Procedure DisableNow(Command)
	DisableDetails = True;
	Close();
EndProcedure

&AtClient
Procedure OK(Command)
	Close();
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure DefineBehaviorInMobileClient()
	IsMobileClient = Common.IsMobileClient();
	If Not IsMobileClient Then 
		Return;
	EndIf;
	
	CommandBarLocation = FormCommandBarLabelLocation.Auto;
EndProcedure

&AtServerNoContext
Function BeforeCloseAtServer(DisableDetails)
	CommonSettings = ReportsOptions.CommonPanelSettings();
	If DisableDetails Then
		CommonSettings.ShowTooltips = False;
	EndIf;
	CommonSettings.ShowTooltipsNotification = False;
	ReportsOptions.SaveCommonPanelSettings(CommonSettings);
	Return CommonSettings;
EndFunction

#EndRegion
