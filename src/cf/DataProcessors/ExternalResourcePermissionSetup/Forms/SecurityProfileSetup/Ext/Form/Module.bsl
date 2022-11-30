///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Variables

&AtClient
Var RefreshInterface;

#EndRegion

#Region EventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Not SafeModeManagerInternal.SecurityProfilesUsageAvailable() Then
		Raise NStr("ru = 'Внимание! Использование профилей безопасности недоступно для данной конфигурации'; en = 'Warning! Use of security profiles is not available for this configuration'; pl = 'Warning! Use of security profiles is not available for this configuration';de = 'Warning! Use of security profiles is not available for this configuration';ro = 'Warning! Use of security profiles is not available for this configuration';tr = 'Warning! Use of security profiles is not available for this configuration'; es_ES = 'Warning! Use of security profiles is not available for this configuration'");
	EndIf;
	
	If Not SafeModeManagerInternal.CanSetUpSecurityProfiles() Then
		Raise NStr("ru = 'Внимание! Настройка профилей безопасности недоступна'; en = 'Warning! Setting of security profiles is unavailable.'; pl = 'Warning! Setting of security profiles is unavailable.';de = 'Warning! Setting of security profiles is unavailable.';ro = 'Warning! Setting of security profiles is unavailable.';tr = 'Warning! Setting of security profiles is unavailable.'; es_ES = 'Warning! Setting of security profiles is unavailable.'");
	EndIf;
	
	If Not Users.IsFullUser(, True) Then
		Raise NStr("ru = 'Недостаточно прав доступа'; en = 'Insufficient access rights'; pl = 'Insufficient access rights';de = 'Insufficient access rights';ro = 'Insufficient access rights';tr = 'Insufficient access rights'; es_ES = 'Insufficient access rights'");
	EndIf;
	
	// Visibility settings at startup.
	ReadSecurityProfilesUsageMode();
	
	// Update items states.
	SetAvailability();
	
EndProcedure

&AtClient
Procedure OnClose(Exit)
	If Exit Then
		Return;
	EndIf;
	UpdateApplicationInterface();
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure OnChangeSecurityProfilesUsageMode(Item)
	
	Try
		
		StartApplyingSecurityProfilesSettings(ThisObject.UUID);
		
		PreviousMode = CurrentSecurityProfilesUsageMode();
		NewMode = ProfileSecurityUsageMode;
		
		If (PreviousMode <> NewMode) Then
			
			If (PreviousMode = 2 Or NewMode = 2) Then
				
				ClosingNotification = New NotifyDescription("AfterCloseSecurityProfileCustomizationWizard", ThisObject, True);
				
				If NewMode = 2 Then
					
					ExternalResourcePermissionSetupClient.StartEnablingSecurityProfilesUsage(ThisObject, ClosingNotification);
					
				Else
					
					ExternalResourcePermissionSetupClient.StartDisablingSecurityProfilesUsage(ThisObject, ClosingNotification);
					
				EndIf;
				
			Else
				
				EndApplyingSecurityProfilesSettings();
				SetAvailability("ProfileSecurityUsageMode");
				
			EndIf;
			
		EndIf;
		
	Except
		
		ReadSecurityProfilesUsageMode();
		Raise;
		
	EndTry;
	
EndProcedure

&AtClient
Procedure InfobaseSecurityProfileOnChange(Item)
	Attachable_OnChangeAttribute(Item);
EndProcedure

#EndRegion

#Region FormCommandHandlers

&AtClient
Procedure RequiredPermissions(Command)
	
	ReportParameters = New Structure();
	ReportParameters.Insert("GenerateOnOpen", True);
	
	OpenForm(
		"Report.ExternalResourcesInUse.ObjectForm",
		ReportParameters);
	
EndProcedure

&AtClient
Procedure RestoreSecurityProfiles(Command)
	
	Try
		
		StartApplyingSecurityProfilesSettings(ThisObject.UUID);
		ClosingNotification = New NotifyDescription("AfterCloseSecurityProfileCustomizationWizard", ThisObject, True);
		ExternalResourcePermissionSetupClient.StartRestoringSecurityProfiles(ThisObject, ClosingNotification);
		
	Except
		
		ReadSecurityProfilesUsageMode();
		Raise;
		
	EndTry;
	
EndProcedure

&AtClient
Procedure OpenExternalDataProcessor(Command)
	
	SafeModeManagerClient.OpenExternalDataProcessorOrReport(ThisObject);
	
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure AfterCloseSecurityProfileCustomizationWizard(Result, ClientApplicationRestartRequired) Export
	
	If Result = DialogReturnCode.OK Then
		EndApplyingSecurityProfilesSettings();
	EndIf;
	
	ReadSecurityProfilesUsageMode();
	
	If Result = DialogReturnCode.OK AND ClientApplicationRestartRequired Then
		Terminate(True);
	EndIf;
	
EndProcedure

&AtServer
Procedure ReadSecurityProfilesUsageMode()
	
	ProfileSecurityUsageMode = CurrentSecurityProfilesUsageMode();
	SetAvailability("ProfileSecurityUsageMode");
	
EndProcedure

&AtServer
Function CurrentSecurityProfilesUsageMode()
	
	If SafeModeManagerInternal.SecurityProfilesUsageAvailable() AND GetFunctionalOption("UseSecurityProfiles") Then
		
		If Constants.AutomaticallyConfigurePermissionsInSecurityProfiles.Get() Then
			
			Result = 2; // From the current infobase
			
		Else
			
			Result = 1; // Via the cluster console
			
		EndIf;
		
	Else
		
		Result = 0; // Not used
		
	EndIf;
	
	Return Result;
	
EndFunction

&AtServerNoContext
Procedure StartApplyingSecurityProfilesSettings(Val UUID)
	
	If Not SafeModeManagerInternal.SecurityProfilesUsageAvailable() Then
		Raise NStr("ru = 'Внимание! Включение автоматического запроса разрешений недоступно'; en = 'Warning! Enabling automatic permission request is not available.'; pl = 'Warning! Enabling automatic permission request is not available.';de = 'Warning! Enabling automatic permission request is not available.';ro = 'Warning! Enabling automatic permission request is not available.';tr = 'Warning! Enabling automatic permission request is not available.'; es_ES = 'Warning! Enabling automatic permission request is not available.'");
	EndIf;
	
	SetExclusiveMode(True);
	
EndProcedure

&AtServer
Procedure EndApplyingSecurityProfilesSettings()
	
	If ProfileSecurityUsageMode = 0 Then
		
		Constants.UseSecurityProfiles.Set(False);
		Constants.AutomaticallyConfigurePermissionsInSecurityProfiles.Set(False);
		Constants.InfobaseSecurityProfile.Set("");
		
	ElsIf ProfileSecurityUsageMode = 1 Then
		
		Constants.UseSecurityProfiles.Set(True);
		Constants.AutomaticallyConfigurePermissionsInSecurityProfiles.Set(False);
		
	ElsIf ProfileSecurityUsageMode = 2 Then
		
		Constants.UseSecurityProfiles.Set(True);
		Constants.AutomaticallyConfigurePermissionsInSecurityProfiles.Set(True);
		
	EndIf;
	
	If ExclusiveMode() Then
		SetExclusiveMode(False);
	EndIf;
	
EndProcedure

&AtClient
Procedure Attachable_OnChangeAttribute(Item, UpdateInterface = True)
	
	ConstantName = OnChangeAttributeServer(Item.Name);
	
	RefreshReusableValues();
	
	If UpdateInterface Then
		RefreshInterface = True;
		AttachIdleHandler("UpdateApplicationInterface", 2, True);
	EndIf;
	
	If ConstantName <> "" Then
		Notify("Write_ConstantsSet", New Structure, ConstantName);
	EndIf;
	
EndProcedure

&AtClient
Procedure UpdateApplicationInterface()
	
	If RefreshInterface = True Then
		RefreshInterface = False;
		CommonClient.RefreshApplicationInterface();
	EndIf;
	
EndProcedure

&AtServer
Function OnChangeAttributeServer(ItemName)
	
	DataPathAttribute = Items[ItemName].DataPath;
	
	ConstantName = SaveAttributeValue(DataPathAttribute);
	
	SetAvailability(DataPathAttribute);
	
	RefreshReusableValues();
	
	Return ConstantName;
	
EndFunction

&AtServer
Function SaveAttributeValue(DataPathAttribute)
	
	NameParts = StrSplit(DataPathAttribute, ".");
	If NameParts.Count() <> 2 Then
		Return "";
	EndIf;
	
	ConstantName = NameParts[1];
	ConstantManager = Constants[ConstantName];
	ConstantValue = ConstantsSet[ConstantName];
	
	If ConstantManager.Get() <> ConstantValue Then
		ConstantManager.Set(ConstantValue);
	EndIf;
	
	Return ConstantName;
	
EndFunction

&AtServer
Procedure SetAvailability(DataPathAttribute = "")
	
	If Users.IsFullUser(, True) Then
		
		If DataPathAttribute = "ProfileSecurityUsageMode" OR DataPathAttribute = "" Then
			
			Items.InfobaseSecurityProfileGroup.Enabled = ProfileSecurityUsageMode > 0;
			
			Items.InfobaseSecurityProfile.ReadOnly = (ProfileSecurityUsageMode = 2);
			Items.SecurityProfilesRestorationGroup.Enabled = (ProfileSecurityUsageMode = 2);
			
		EndIf;
		
	EndIf;
	
EndProcedure

#EndRegion
