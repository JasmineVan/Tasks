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
	
	// Visibility settings at startup.
	Items.Extensions.Visible = Not StandardSubsystemsServer.IsBaseConfigurationVersion();
	
	If Common.SubsystemExists("StandardSubsystems.AdditionalReportsAndDataProcessors") Then
		DataSeparationEnabled = Common.DataSeparationEnabled();
		Items.UseAdditionalReportsAndDataProcessors.Visible = Not DataSeparationEnabled;
		Items.OpenAdditionalReportsAndDataProcessors.Visible      = Not DataSeparationEnabled
			// In SaaS mode, if it is enabled by the service administrator.
			Or ConstantsSet.UseAdditionalReportsAndDataProcessors;
	Else
		Items.AdditionalReportsAndDataProcessorsGroup.Visible = False;
	EndIf;
	
	If Common.SubsystemExists("StandardSubsystems.ReportMailing") Then
		ModuleReportDistribution = Common.CommonModule("ReportMailing");
		Items.OpenReportsBulkEmails.Visible = ModuleReportDistribution.InsertRight();
	Else
		Items.ReportsBulkEmailsGroup.Visible = False;
	EndIf;
	
	// Update items states.
	SetAvailability();
	
	ApplicationSettingsOverridable.PrintFormsReportsAndDataProcessorsOnCreateAtServer(ThisObject);
	
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
Procedure UseAdditionalReportsAndDataProcessorsOnChange(Item)
	
	PreviousValue = ConstantsSet.UseAdditionalReportsAndDataProcessors;
	
	Try
		
		Handler = New NotifyDescription("UseAdditionalReportsAndDataProcessorsOnChangeCompletion", ThisObject, Item);
		If CommonClient.SubsystemExists("StandardSubsystems.SecurityProfiles") Then
			PermissionRequestsToUseExternalResources = PermissionRequestsToUseExternalResourcesOfAdditionalReportsAndDataProcessors(PreviousValue);
			ModuleSafeModeManagerClient = CommonClient.CommonModule("SafeModeManagerClient");
			ModuleSafeModeManagerClient.ApplyExternalResourceRequests(PermissionRequestsToUseExternalResources, ThisObject, Handler);
		Else
			ExecuteNotifyProcessing(Handler, DialogReturnCode.OK);
		EndIf;
		
	Except
		
		ConstantsSet.UseAdditionalReportsAndDataProcessors = PreviousValue;
		Raise;
		
	EndTry;
	
EndProcedure

#EndRegion

#Region Private

////////////////////////////////////////////////////////////////////////////////
// Client

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

////////////////////////////////////////////////////////////////////////////////
// Server call

&AtServer
Function OnChangeAttributeServer(ItemName)
	
	DataPathAttribute = Items[ItemName].DataPath;
	
	ConstantName = SaveAttributeValue(DataPathAttribute);
	
	SetAvailability(DataPathAttribute);
	
	RefreshReusableValues();
	
	Return ConstantName;
	
EndFunction

////////////////////////////////////////////////////////////////////////////////
// Server

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
	
	If DataPathAttribute = "ConstantsSet.UseAdditionalReportsAndDataProcessors" OR DataPathAttribute = ""
		AND Common.SubsystemExists("StandardSubsystems.AdditionalReportsAndDataProcessors") Then
		Items.OpenAdditionalReportsAndDataProcessors.Enabled = ConstantsSet.UseAdditionalReportsAndDataProcessors;
	EndIf;
	
EndProcedure

&AtServerNoContext
Function PermissionRequestsToUseExternalResourcesOfAdditionalReportsAndDataProcessors(Include)
	
	ModuleAdditionalReportsAndDataProcessorsSafeModeInternal = Common.CommonModule(
		"AdditionalReportsAndDataProcessorsSafeModeInternal");
	Return ModuleAdditionalReportsAndDataProcessorsSafeModeInternal.AdditionalDataProcessorsPermissionRequests(Include);
	
EndFunction

&AtClient
Procedure UseAdditionalReportsAndDataProcessorsOnChangeCompletion(Response, Item) Export
	
	If Response <> DialogReturnCode.OK Then
		ConstantsSet.UseAdditionalReportsAndDataProcessors = Not ConstantsSet.UseAdditionalReportsAndDataProcessors;
	Else
		Attachable_OnChangeAttribute(Item);
	EndIf;
	
EndProcedure

#EndRegion
