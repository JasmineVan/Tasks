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

	If Common.SubsystemExists("StandardSubsystems.ScheduledJobs") Then
		Items.ExternalResourcesOperationsLockGroup.Visible =
			ScheduledJobsServer.OperationsWithExternalResourcesLocked();
		
		Items.ScheduledAndBackgroundJobsDataProcessorGroup.Visible =
			Users.IsFullUser(, True);
	Else
		Items.ScheduledAndBackgroundJobsDataProcessorGroup.Visible = False;
		Items.ExternalResourcesOperationsLockGroup.Visible = False;
	EndIf;
	
	If Common.SubsystemExists("StandardSubsystems.TotalsAndAggregatesManagement") Then
		Items.TotalsAndAggregatesManagementDataProcessorOpenGroup.Visible =
			  Users.IsFullUser()
			AND Not Common.DataSeparationEnabled();
	Else
		Items.TotalsAndAggregatesManagementDataProcessorOpenGroup.Visible = False;
	EndIf;
	
	If Common.SubsystemExists("StandardSubsystems.IBBackup") Then
		Items.BackupAndRecoveryGroup.Visible =
			  Users.IsFullUser(, True)
			AND Not Common.DataSeparationEnabled()
			AND Not Common.ClientConnectedOverWebServer()
			AND Common.IsWindowsClient();
		
		UpdateBackupSettings();
	Else
		Items.BackupAndRecoveryGroup.Visible = False;
	EndIf;
	
	If Common.SubsystemExists("StandardSubsystems.PerformanceMonitor") Then
		Items.PerformanceMonitorGroup.Visible =
			Users.IsFullUser(, True);
	Else
		Items.PerformanceMonitorGroup.Visible = False;
	EndIf;
	
	If Common.SubsystemExists("StandardSubsystems.BatchEditObjects") Then
		Items.BulkObjectEditingDataProcessorGroup.Visible =
			Users.IsFullUser();
	Else
		Items.BulkObjectEditingDataProcessorGroup.Visible = False;
	EndIf;
	
	If Not Common.SubsystemExists("StandardSubsystems.DuplicateObjectDetection") Then
		Items.DuplicateObjectsDetectionGroup.Visible = False;
	EndIf;
	
	If Common.SubsystemExists("StandardSubsystems.AdditionalReportsAndDataProcessors") Then
		Items.AdditionalReportsAndDataProcessorsGroup.Visible =
			ConstantsSet.UseAdditionalReportsAndDataProcessors;
	Else
		Items.AdditionalReportsAndDataProcessorsGroup.Visible = False;
	EndIf;
	
	If Common.SubsystemExists("StandardSubsystems.ConfigurationUpdate") Then
		Items.UpdatesInstallationGroup.Visible =
			  Users.IsFullUser(, True)
			AND Not Common.IsStandaloneWorkplace()
			AND Not Common.DataSeparationEnabled()
			AND Not Common.ClientConnectedOverWebServer()
			AND Common.IsWindowsClient();
		
		Items.InstalledPatchesGroup.Visible =
			Users.IsFullUser()
			AND Not StandardSubsystemsServer.IsBaseConfigurationVersion();
			
		If StandardSubsystemsServer.IsBaseConfigurationVersion() Then
			Items.InstallUpdates.Title = NStr("ru = 'Установка обновлений'; en = 'Install updates'; pl = 'Instalacja aktualizacji';de = 'Updates installieren';ro = 'Instalarea actualizărilor';tr = 'Güncellemeleri yükle'; es_ES = 'Instalar las actualizaciones'");
			Items.InstallUpdates.ExtendedTooltip.Title =
				NStr("ru = 'Обновление программы из файла на локальном диске или в сетевом каталоге.'; en = 'Update the application from a file on a hard drive or in a network directory.'; pl = 'Aktualizacja programu z pliku na dysku lokalnym lub w katalogu sieciowym.';de = 'Aktualisieren Sie das Programm aus einer Datei auf der lokalen Festplatte oder in einem Netzwerkverzeichnis.';ro = 'Actualizarea programului din fișier pe discul local sau în catalogul de rețea.';tr = 'Programı yerel diskinizdeki veya ağ dizininizdeki bir dosyadan güncelleyin.'; es_ES = 'Actualización del programa del archivo en el disco local o en el catálogo de red.'");
		EndIf;
	Else
		Items.UpdatesInstallationGroup.Visible = False;
		Items.InstalledPatchesGroup.Visible = False;
	EndIf;
	
	If Common.SubsystemExists("OnlineUserSupport.CloudArchive") Then
		ModuleCloudArchive = Common.CommonModule("CloudArchive");
		ModuleCloudArchive.SSLAdministrationPanel_OnCreateAtServer(ThisObject);
	EndIf;
	
	If Not Common.SubsystemExists("StandardSubsystems.AccountingAudit") Then
		If Items.Find("AccountingCheckRules") <> Undefined Then
			Items.AccountingCheckRules.Visible = False;
		EndIf;
	EndIf;
	
	// Update items states.
	SetAvailability();
	
	ApplicationSettingsOverridable.ServiceOnCreateAtServer(ThisObject);
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)

	If CommonClient.SubsystemExists("OnlineUserSupport.CloudArchive") Then
		ModuleCloudArchiveClient = CommonClient.CommonModule("CloudArchiveClient");
		ModuleCloudArchiveClient.SSLAdministrationPanel_OnOpen(ThisObject);
	EndIf;

EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If EventName = "BackupSettingsFormClosed"
		AND CommonClient.SubsystemExists("StandardSubsystems.IBBackup") Then
		UpdateBackupSettings();
	ElsIf EventName = "OperationsWithExternalResourcesAllowed" Then
		Items.ExternalResourcesOperationsLockGroup.Visible = False;
	EndIf;
	
	If CommonClient.SubsystemExists("OnlineUserSupport.CloudArchive") Then
		ModuleCloudArchiveClient = CommonClient.CommonModule("CloudArchiveClient");
		ModuleCloudArchiveClient.SSLAdministrationPanel_NotificationProcessing(ThisObject, EventName, Parameter, Source);
	EndIf;
	
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
Procedure ExecutePerformanceMeasurementsOnChange(Item)
	Attachable_OnChangeAttribute(Item);
EndProcedure

&AtClient
Procedure ItemizeIBUpdateInEventLogOnChange(Item)
	Attachable_OnChangeAttribute(Item);
EndProcedure

#Region OnlineUserSupport_CloudArchive

&AtClient
Procedure CloudArchiveURLProcessing(Item, FormattedStringURL, StandardProcessing)

	StandardProcessing = True;

	If CommonClient.SubsystemExists("OnlineUserSupport.CloudArchive") Then
		ModuleCloudArchiveClient = CommonClient.CommonModule("CloudArchiveClient");
		ModuleCloudArchiveClient.URLProcessing(
			ThisObject, Item, FormattedStringURL,
			StandardProcessing, New Structure);
	EndIf;

EndProcedure

&AtClient
Procedure BackupMethodOnChange(Item)

	// Depending on the state, display a correct page.
	If CommonClient.SubsystemExists("OnlineUserSupport.CloudArchive") Then
		ModuleCloudArchiveClient = CommonClient.CommonModule("CloudArchiveClient");
		ModuleCloudArchiveClient.SSLAdministrationPanel_BackupMethodOnChange(ThisObject);
	EndIf;

EndProcedure

#EndRegion

#EndRegion

#Region FormCommandHandlers

&AtClient
Procedure UnlockOperationsWithExternalResources(Command)
	UnlockExternalResourcesOperationsAtServer();
	StandardSubsystemsClient.SetAdvancedApplicationCaption();
	Notify("OperationsWithExternalResourcesAllowed");
	RefreshInterface();
EndProcedure

&AtClient
Procedure DeferredDataProcessing(Command)
	FormParameters = New Structure("OpenedFromAdministrationPanel", True);
	OpenForm("DataProcessor.ApplicationUpdateResult.Form.DeferredIBUpdateProgressIndicator", FormParameters);
EndProcedure

#Region OnlineUserSupport_CloudArchive

&AtClient
Procedure EnableCloudArchiveService(Command)

	If CommonClient.SubsystemExists("OnlineUserSupport.CloudArchive") Then
		ModuleCloudArchiveClient = CommonClient.CommonModule("CloudArchiveClient");
		ModuleCloudArchiveClient.EnableCloudArchiveService();
	EndIf;

EndProcedure

&AtClient
Procedure CloudArchiveRestoreFromBackupClick(Item)

	If CommonClient.SubsystemExists("OnlineUserSupport.CloudArchive") Then
		ModuleCloudArchiveClient = CommonClient.CommonModule("CloudArchiveClient");
		ModuleCloudArchiveClient.RestoreFromBackup();
	EndIf;

EndProcedure

&AtClient
Procedure CloudArchiveBackupSetupClick(Item)

	If CommonClient.SubsystemExists("OnlineUserSupport.CloudArchive") Then
		ModuleCloudArchiveClient = CommonClient.CommonModule("CloudArchiveClient");
		ModuleCloudArchiveClient.BackupSetup();
	EndIf;

EndProcedure

#EndRegion

#EndRegion

#Region Private

////////////////////////////////////////////////////////////////////////////////
// Client

&AtClient
Procedure Attachable_OnChangeAttribute(Item, InterfaceUpdateIsRequired = True)
	
	ConstantName = OnChangeAttributeServer(Item.Name);
	
	RefreshReusableValues();
	
	If InterfaceUpdateIsRequired Then
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
	
	If Not Users.IsFullUser(, True) Then
		Return;
	EndIf;
	
	If Common.SubsystemExists("StandardSubsystems.PerformanceMonitor")
		AND (DataPathAttribute = "ConstantsSet.RunPerformanceMeasurements"
		Or DataPathAttribute = "") Then
			ItemDataProcessorPerformanceMonitorPerformanceMeasurementsImport = Items.Find("PerformanceEvaluationPerformanceMeasurementImportDataProcessor");
			ItemDataProcessorPerformanceMonitorDataExport = Items.Find("PerformanceEvaluationDataExportDataProcessor");
			ItemCatalogKeyOperationsProfilesOpenList = Items.Find("CatalogKeyOperationsProfilesOpenList");
			ItemDataProcessorPerformanceMonitorSettings = Items.Find("PerformanceEvaluationSettingsDataProcessor");
			If (ItemDataProcessorPerformanceMonitorSettings <> Undefined
				AND ItemDataProcessorPerformanceMonitorDataExport <> Undefined				
				AND ItemCatalogKeyOperationsProfilesOpenList <> Undefined
				AND ItemDataProcessorPerformanceMonitorPerformanceMeasurementsImport <> Undefined
				AND ConstantsSet.Property("RunPerformanceMeasurements")) Then
				ItemDataProcessorPerformanceMonitorSettings.Enabled = ConstantsSet.RunPerformanceMeasurements;
				ItemDataProcessorPerformanceMonitorDataExport.Enabled = ConstantsSet.RunPerformanceMeasurements;
				ItemCatalogKeyOperationsProfilesOpenList.Enabled = ConstantsSet.RunPerformanceMeasurements;
				ItemDataProcessorPerformanceMonitorPerformanceMeasurementsImport.Enabled = ConstantsSet.RunPerformanceMeasurements;
			EndIf;
	EndIf;
	
EndProcedure

&AtServer
Procedure UpdateBackupSettings()
	
	If Not Common.DataSeparationEnabled()
	   AND Users.IsFullUser(, True) Then
		
		ModuleIBBackupServer = Common.CommonModule("IBBackupServer");
		Items.IBBackupSetup.ExtendedTooltip.Title = ModuleIBBackupServer.CurrentBackupSetting();
	EndIf;
	
EndProcedure

&AtServer
Procedure UnlockExternalResourcesOperationsAtServer()
	Items.ExternalResourcesOperationsLockGroup.Visible = False;
	ModuleScheduledJobsServer = Common.CommonModule("ScheduledJobsServer");
	ModuleScheduledJobsServer.UnlockOperationsWithExternalResources();
EndProcedure

#Region OnlineUserSupport_CloudArchive

&AtClient
Procedure Attachable_CheckCloudArchiveState()

	If CommonClient.SubsystemExists("OnlineUserSupport.CloudArchive") Then
		ModuleCloudArchiveClient = CommonClient.CommonModule("CloudArchiveClient");
		ModuleCloudArchiveClient.SSLAdministrationPanel_CheckCloudArchiveStatus(ThisObject);
	EndIf;

EndProcedure

#EndRegion

#EndRegion