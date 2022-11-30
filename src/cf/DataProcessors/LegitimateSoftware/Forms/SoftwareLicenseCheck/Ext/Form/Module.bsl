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
	
	If Not Parameters.OpenProgrammatically Then
		Raise
			NStr("ru = 'Обработка не предназначена для непосредственного использования.'; en = 'The data processor is not intended for direct usage.'; pl = 'Opracowanie nie jest przeznaczone do bezpośredniego użycia.';de = 'Der Datenprozessor ist nicht für den direkten Gebrauch bestimmt.';ro = 'Procesorul de date nu este destinat utilizării directe.';tr = 'Veri işlemcisi doğrudan kullanım için uygun değildir.'; es_ES = 'Procesador de datos no está destinado al uso directo.'");
	EndIf;
	
	SkipRestart = Parameters.SkipRestart;
	
	DocumentTemplate = DataProcessors.LegitimateSoftware.GetTemplate(
		"UpdateDistributionTerms");
	
	WarningText = DocumentTemplate.GetText();
	FileInfobase = Common.FileInfobase();
	
	// StandardSubsystems.MonitoringCenter
	MonitoringCenterExists = Common.SubsystemExists("StandardSubsystems.MonitoringCenter");
	If MonitoringCenterExists Then
		ModuleMonitoringCenterInternal = Common.CommonModule("MonitoringCenterInternal");
		MonitoringCenterParameters = ModuleMonitoringCenterInternal.GetMonitoringCenterParametersExternalCall();
				
		If (NOT MonitoringCenterParameters.EnableMonitoringCenter AND  NOT MonitoringCenterParameters.ApplicationInformationProcessingCenter) Then
			AllowSendStatistics = True;
			Items.SendStatisticsGroup.Visible = True;
		Else
			AllowSendStatistics = True;
			Items.SendStatisticsGroup.Visible = False;
		EndIf;
	Else
		Items.SendStatisticsGroup.Visible = False;
	EndIf;
	// End StandardSubsystems.MonitoringCenter
	
	If Common.IsMobileClient() Then
		CommandBarLocation = FormCommandBarLabelLocation.Top;
		Items.FormContinue.Representation = ButtonRepresentation.Picture;
	EndIf;
	
	CurrentItem = Items.AcceptTermsBoolean;
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	If FileInfobase
	   AND StrFind(LaunchParameter, "UpdateAndExit") > 0 Then
		
		WriteLegitimateSoftwareConfirmation();
		Cancel = True;
		StandardSubsystemsClient.SetFormStorageOption(ThisObject, True);
		AttachIdleHandler("ConfirmSoftwareLicense", 0.1, True);
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandHandlers

&AtClient
Procedure ContinueFormMainActions(Command)
	
	Result = AcceptTermsBoolean;
	
	If Result <> True Then
		If Parameters.ShowRestartWarning AND NOT SkipRestart Then
			Terminate();
		EndIf;
	Else
		WriteLegalityAndStatisticsSendingConfirmation(AllowSendStatistics);
	EndIf;
	
	Close(Result);
	
EndProcedure

&AtClient
Procedure OnClose(Exit)
	
	If Exit Then
		Return;
	ElsIf Result <> True Then
		If Parameters.ShowRestartWarning AND NOT SkipRestart Then
			Terminate();
		EndIf;
	Else
		WriteLegalityAndStatisticsSendingConfirmation(AllowSendStatistics);
	EndIf;
	
	Notify("LegitimateSoftware", Result);
	
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure ConfirmSoftwareLicense()
	
	StandardSubsystemsClient.SetFormStorageOption(ThisObject, False);
	
	ExecuteNotifyProcessing(ThisObject.OnCloseNotifyDescription, True);
	
EndProcedure

&AtServerNoContext
Procedure WriteLegalityAndStatisticsSendingConfirmation(AllowSendStatistics)
	
	WriteLegitimateSoftwareConfirmation();
	
	SetPrivilegedMode(True);
	
	MonitoringCenterExists = Common.SubsystemExists("StandardSubsystems.MonitoringCenter");
	If MonitoringCenterExists Then
		ModuleMonitoringCenterInternal = Common.CommonModule("MonitoringCenterInternal");
		
		SendStatisticsParameters = New Structure("EnableMonitoringCenter, ApplicationInformationProcessingCenter", Undefined, Undefined);
		SendStatisticsParameters = ModuleMonitoringCenterInternal.GetMonitoringCenterParametersExternalCall(SendStatisticsParameters);
		
		If (NOT SendStatisticsParameters.EnableMonitoringCenter AND SendStatisticsParameters.ApplicationInformationProcessingCenter) Then
			// Statistics are configured to be sent to a third-party developer. Do not change settings.
			// 
			//
		Else
			If AllowSendStatistics Then
				ModuleMonitoringCenterInternal.SetMonitoringCenterParameterExternalCall("EnableMonitoringCenter", AllowSendStatistics);
				ModuleMonitoringCenterInternal.SetMonitoringCenterParameterExternalCall("ApplicationInformationProcessingCenter", False);
				ScheduledJob = ModuleMonitoringCenterInternal.GetScheduledJobExternalCall("StatisticsDataCollectionAndSending", True);
				ModuleMonitoringCenterInternal.SetDefaultScheduleExternalCall(ScheduledJob);
			Else
				ModuleMonitoringCenterInternal.SetMonitoringCenterParameterExternalCall("EnableMonitoringCenter", AllowSendStatistics);
				ModuleMonitoringCenterInternal.SetMonitoringCenterParameterExternalCall("ApplicationInformationProcessingCenter", False);
				ModuleMonitoringCenterInternal.DeleteScheduledJobExternalCall("StatisticsDataCollectionAndSending");
			EndIf;
		EndIf;
	EndIf;
	
EndProcedure

&AtServerNoContext
Procedure WriteLegitimateSoftwareConfirmation()
	SetPrivilegedMode(True);
	InfobaseUpdateInternal.WriteLegitimateSoftwareConfirmation();
EndProcedure

#EndRegion