///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////////////
// Integration with Service Technology Library (STL).
// Here you can find processors of program events that make calls between SSL and STL.
// 
//


// Processing program events that occur in STL subsystems.
// Only for calls from STL library to SSL.

#Region Public

#Region ForCallsFromOtherSubsystems

// SaaSTechnology.Core

#Region ExportImportData

// See ExportImportDataOverridable.OnFillCommonDataTypesSupportingRefsMapOnImport. 
Procedure OnFillCommonDataTypesSupportingRefMappingOnExport(Types) Export
	
	StandardSubsystemsServer.OnFillCommonDataTypesSupportingRefMappingOnExport(Types);
	
	If Common.SubsystemExists("StandardSubsystems.Banks") Then
		ModuleBankManager = Common.CommonModule("BankManager");
		ModuleBankManager.OnFillCommonDataTypesSupportingRefMappingOnExport(Types);
	EndIf;
	
	If Common.SubsystemExists("StandardSubsystems.ReportsOptions") Then
		ModuleReportsOptions = Common.CommonModule("ReportsOptions");
		ModuleReportsOptions.OnFillCommonDataTypesSupportingRefMappingOnExport(Types);
	EndIf;
	
	If Common.SubsystemExists("StandardSubsystems.PeriodClosingDates") Then
		ModulePeriodClosingDatesInternal = Common.CommonModule("PeriodClosingDatesInternal");
		ModulePeriodClosingDatesInternal.OnFillCommonDataTypesSupportingRefMappingOnExport(Types);
	EndIf;
	
	If Common.SubsystemExists("StandardSubsystems.CalendarSchedules") Then
		ModuleCalendarSchedules = Common.CommonModule("CalendarSchedules");
		ModuleCalendarSchedules.OnFillCommonDataTypesSupportingRefMappingOnExport(Types);
	EndIf;
	
EndProcedure

// See ExportImportDataOverridable.OnFillCommonDataTypesThatDoNotRequireMappingRefsOnImport. 
Procedure OnFillCommonDataTypesThatDoNotRequireMappingRefsOnImport(Types) Export
	
	If Common.SubsystemExists("StandardSubsystems.FilesOperations") Then
		ModuleFilesOperationsInternal = Common.CommonModule("FilesOperationsInternal");
		ModuleFilesOperationsInternal.OnFillCommonDataTypesThatDoNotRequireMappingRefsOnImport(Types);
	EndIf;
	
	If Common.SubsystemExists("StandardSubsystems.AccessManagement") Then
		ModuleAccessManagementInternal = Common.CommonModule("AccessManagementInternal");
		ModuleAccessManagementInternal.OnFillCommonDataTypesThatDoNotRequireMappingRefsOnImport(Types);
	EndIf;
	
EndProcedure

// See ExportImportDataOverridable.OnFillTypesExcludedFromExportImport. 
Procedure OnFillTypesExcludedFromExportImport(Types) Export
	
	StandardSubsystemsServer.OnFillTypesExcludedFromExportImport(Types);
		
	If Common.SubsystemExists("StandardSubsystems.ReportsOptions") Then
		ModuleReportsOptions = Common.CommonModule("ReportsOptions");
		ModuleReportsOptions.OnFillTypesExcludedFromExportImport(Types);
	EndIf;
	
	If Common.SubsystemExists("StandardSubsystems.Interactions") Then
		ModuleInteractions = Common.CommonModule("Interactions");
		ModuleInteractions.OnFillTypesExcludedFromExportImport(Types);
	EndIf;
	
	If Common.SubsystemExists("StandardSubsystems.AddIns") Then
		ModuleAddInsInternal = Common.CommonModule("AddInsInternal");
		ModuleAddInsInternal.OnFillTypesExcludedFromExportImport(Types);
	EndIf;
	
	If Common.SubsystemExists("StandardSubsystems.SaaS.AddInsSaaS") Then
		ModuleAddInsSaaSInternal = Common.CommonModule("AddInsSaaSInternal");
		ModuleAddInsSaaSInternal.OnFillTypesExcludedFromExportImport(Types);
	EndIf;
	
	If Common.SubsystemExists("StandardSubsystems.UserSessionsCompletion") Then
		ModuleIBConnections = Common.CommonModule("IBConnections");
		ModuleIBConnections.OnFillTypesExcludedFromExportImport(Types);
	EndIf;
	
	If Common.SubsystemExists("StandardSubsystems.AccountingAudit") Then
		ModuleAccountingAuditInternal = Common.CommonModule("AccountingAuditInternal");
		ModuleAccountingAuditInternal.OnFillTypesExcludedFromExportImport(Types);
	EndIf;
	
	If Common.SubsystemExists("StandardSubsystems.SaaS.AddressClassifierSaaS") Then
		ModuleAddressClassifierSaaSInternal = Common.CommonModule("AddressClassifierSaaSInternal");
		ModuleAddressClassifierSaaSInternal.OnFillTypesExcludedFromExportImport(Types);
	EndIf;
	
	If Common.SubsystemExists("StandardSubsystems.SaaS.CoreSaaS") Then
		ModuleSaaS = Common.CommonModule("SaaS");
		ModuleSaaS.OnFillTypesExcludedFromExportImport(Types);
	EndIf;

	If Common.SubsystemExists("StandardSubsystems.SaaS.MessageExchange") Then
		ModuleMessageExchangeInternal = Common.CommonModule("MessageExchangeInternal");
		ModuleMessageExchangeInternal.OnFillTypesExcludedFromExportImport(Types);
	EndIf;
	
	If Common.SubsystemExists("StandardSubsystems.SaaS.IBVersionUpdateSaaS") Then
		ModuleInfobaseUpdateInternalSaaS = Common.CommonModule("InfobaseUpdateInternalSaaS");
		ModuleInfobaseUpdateInternalSaaS.OnFillTypesExcludedFromExportImport(Types);
	EndIf;
	
	If Common.SubsystemExists("StandardSubsystems.SaaS.JobQueue") Then
		ModuleJobQueueInternalDataSeparation = Common.CommonModule("JobQueueInternalDataSeparation");
		ModuleJobQueueInternalDataSeparation.OnFillTypesExcludedFromExportImport(Types);
	EndIf;
	
	If Common.SubsystemExists("StandardSubsystems.SaaS.DataAreaBackup") Then
		ModuleDataAreasBackup = Common.CommonModule("DataAreaBackup");
		ModuleDataAreasBackup.OnFillTypesExcludedFromExportImport(Types);
	EndIf;
	
	If Common.SubsystemExists("StandardSubsystems.SaaS.FilesManagerSaaS") Then
		ModuleFilesManagerInternalSaaS = Common.CommonModule("FilesManagerInternalSaaS");
		ModuleFilesManagerInternalSaaS.OnFillTypesExcludedFromExportImport(Types);
	EndIf;
	
	If Common.SubsystemExists("StandardSubsystems.AccessManagement") Then
		ModuleAccessManagementInternal = Common.CommonModule("AccessManagementInternal");
		ModuleAccessManagementInternal.OnFillTypesExcludedFromExportImport(Types);
	EndIf;
	
EndProcedure

// See ExportImportDataOverridable.AfterDataImport. 
Procedure AfterImportData(Container) Export
	
	UsersInternal.AfterImportData(Container);
	
	If Common.SubsystemExists("StandardSubsystems.ScheduledJobs") Then
		ModuleScheduledJobsInternal = Common.CommonModule("ScheduledJobsInternal");
		ModuleScheduledJobsInternal.AfterImportData(Container);
	EndIf;
	
	If Common.SubsystemExists("StandardSubsystems.SaaS.CoreSaaS") Then
		ModuleSaaS = Common.CommonModule("SaaS");
		ModuleSaaS.AfterImportData(Container);
	EndIf;
	
	If Common.SubsystemExists("SaaS.CurrenciesSaaS") Then
		ModuleCurrencyExchangeRatesInternalSaaS = Common.CommonModule("CurrencyRatesInternalSaaS");
		ModuleCurrencyExchangeRatesInternalSaaS.AfterImportData(Container);
	EndIf;
	
	If Common.SubsystemExists("StandardSubsystems.SaaS.CoreSaaS") Then
		ModuleJobQueueInternalDataSeparation = Common.CommonModule("JobQueueInternalDataSeparation");
		ModuleJobQueueInternalDataSeparation.AfterImportData(Container);
	EndIf;
	
	If Common.SubsystemExists("StandardSubsystems.SaaS.IBVersionUpdateSaaS") Then
		ModuleInfobaseUpdateInternalSaaS = Common.CommonModule("InfobaseUpdateInternalSaaS");
		ModuleInfobaseUpdateInternalSaaS.AfterImportData(Container);
	EndIf;
	
	If Common.SubsystemExists("StandardSubsystems.SaaS.AccessManagementSaaS") Then
		ModuleAccessManagementInternalSaaS = Common.CommonModule("AccessManagementInternalSaaS");
		ModuleAccessManagementInternalSaaS.AfterImportData(Container);
	EndIf;
	
	InfobaseUpdateInternal.AfterImportData(Container);
	
EndProcedure

// See ExportImportDataOverridable.OnRegisterDataExportHandlers. 
Procedure OnRegisterDataExportHandlers(HandlersTable) Export
	
	If Common.SubsystemExists("StandardSubsystems.AccessManagement") Then
		ModuleAccessManagementInternal = Common.CommonModule("AccessManagementInternal");
		ModuleAccessManagementInternal.OnRegisterDataExportHandlers(HandlersTable);
	EndIf;
	
EndProcedure

#EndRegion

// End SaaSTechnology.Core

#EndRegion

#EndRegion

// Processing program events that occur in SSL subsystems.
// Only for calls from SSL libraries to STL.

#Region Internal

#Region Core

// See CommonOverridable.OnAddRefsSearchExceptions. 
Procedure OnAddReferenceSearchExceptions(RefSearchExclusions) Export
	
	If Common.SubsystemExists("SaaSTechnology.Core") Then
		ModuleSaaSTechnologyIntegrationWithSSL = Common.CommonModule("SaaSTechnologyIntegrationWithSSL");
		ModuleSaaSTechnologyIntegrationWithSSL.OnAddReferenceSearchExceptions(RefSearchExclusions);
	EndIf;
	
EndProcedure

// See the Syntax Assistant for OnSendDataToMaster. 
Procedure OnSendDataToMaster(DataItem, ItemSending, Recipient) Export
	
	If Common.SubsystemExists("SaaSTechnology.Core") Then
		ModuleSaaSTechnologyIntegrationWithSSL = Common.CommonModule("SaaSTechnologyIntegrationWithSSL");
		ModuleSaaSTechnologyIntegrationWithSSL.OnSendDataToMaster(DataItem, ItemSending, Recipient);
	EndIf;
	
EndProcedure

// See the Syntax Assistant for OnSendDataToSlave. 
Procedure OnSendDataToSlave(DataItem, ItemSending, InitialImageCreation, Recipient) Export
	
	If Common.SubsystemExists("SaaSTechnology.Core") Then
		ModuleSaaSTechnologyIntegrationWithSSL = Common.CommonModule("SaaSTechnologyIntegrationWithSSL");
		ModuleSaaSTechnologyIntegrationWithSSL.OnSendDataToSlave(DataItem, ItemSending, InitialImageCreation, Recipient);
	EndIf;
	
EndProcedure

// See the Syntax Assistant for OnReceiveDataFromMaster. 
Procedure OnReceiveDataFromMaster(DataItem, GetItem, SendBack, Sender) Export
	
	If Common.SubsystemExists("SaaSTechnology.Core") Then
		ModuleSaaSTechnologyIntegrationWithSSL = Common.CommonModule("SaaSTechnologyIntegrationWithSSL");
		ModuleSaaSTechnologyIntegrationWithSSL.OnReceiveDataFromMaster(DataItem, GetItem, SendBack, Sender);
	EndIf;
	
EndProcedure

// See the Syntax Assistant for OnReceiveDataFromSlave. 
Procedure OnReceiveDataFromSlave(DataItem, GetItem, SendBack, Sender) Export
	
	If Common.SubsystemExists("SaaSTechnology.Core") Then
		ModuleSaaSTechnologyIntegrationWithSSL = Common.CommonModule("SaaSTechnologyIntegrationWithSSL");
		ModuleSaaSTechnologyIntegrationWithSSL.OnReceiveDataFromSlave(DataItem, GetItem, SendBack, Sender);
	EndIf;
	
EndProcedure

// See SaaSOverridable.OnEnableDataSeparation. 
Procedure OnEnableSeparationByDataAreas() Export
	
	If Common.SubsystemExists("SaaSTechnology.Core") Then
		ModuleSaaSTechnologyIntegrationWithSSL = Common.CommonModule("SaaSTechnologyIntegrationWithSSL");
		ModuleSaaSTechnologyIntegrationWithSSL.OnEnableSeparationByDataAreas();
	EndIf;
	
EndProcedure

// See CommonOverridable.OnDefineSupportedInterfaceVersions. 
Procedure OnDefineSupportedInterfaceVersions(Val SupportedVersionsStructure) Export
	
	If Common.SubsystemExists("SaaSTechnology.Core") Then
		ModuleSaaSTechnologyIntegrationWithSSL = Common.CommonModule("SaaSTechnologyIntegrationWithSSL");
		ModuleSaaSTechnologyIntegrationWithSSL.OnDefineSupportedInterfaceVersions(SupportedVersionsStructure);
	EndIf;
	
EndProcedure

// See CommonOverridable.OnAddClientParametersOnStart. 
Procedure OnAddClientParametersOnStart(Parameters) Export
	
	If Common.SubsystemExists("SaaSTechnology.Core") Then
		ModuleSaaSTechnologyIntegrationWithSSL = Common.CommonModule("SaaSTechnologyIntegrationWithSSL");
		ModuleSaaSTechnologyIntegrationWithSSL.OnAddClientParametersOnStart(Parameters);
	EndIf;
	
EndProcedure

// See CommonOverridable.OnAddClientParameters. 
Procedure OnAddClientParameters(Parameters) Export
	
	If Common.SubsystemExists("SaaSTechnology.Core") Then
		ModuleSaaSTechnologyIntegrationWithSSL = Common.CommonModule("SaaSTechnologyIntegrationWithSSL");
		ModuleSaaSTechnologyIntegrationWithSSL.OnAddClientParameters(Parameters);
	EndIf;
	
EndProcedure

#EndRegion

#Region AdditionalReportsAndDataProcessors

// Call to determine whether the current user has right to add an additional report or data 
// processor to a data area.
//
// Parameters:
//  AdditionalDataProcessor - CatalogObject.AdditionalReportsAndDataProcessors, catalog item written 
//    by user.
//  Result - Boolean - indicates whether the required rights are granted.
//  StandardProcessing - Boolean - flag specifying whether standard processing is used to validate 
//    rights.
//
Procedure OnCheckInsertRight(Val AdditionalDataProcessor, Result, StandardProcessing) Export
	
	If Common.SubsystemExists("SaaSTechnology.Core") Then
		ModuleSaaSTechnologyIntegrationWithSSL = Common.CommonModule("SaaSTechnologyIntegrationWithSSL");
		ModuleSaaSTechnologyIntegrationWithSSL.OnCheckInsertRight(AdditionalDataProcessor, Result, StandardProcessing);
	EndIf;
	
EndProcedure

// Called to check whether an additional report or data processor can be imported from file.
//
// Parameters:
//  AdditionalDataProcessor - CatalogRef.AdditionalReportsAndDataProcessors,
//  Result - Boolean - indicates whether additional reports or data processors can be imported from 
//    files.
//  StandardProcessing - Boolean - indicates whether standard processing checks if additional 
//    reports or data processors can be imported from files.
//
Procedure OnCheckCanImportDataProcessorFromFile(Val AdditionalDataProcessor, Result, StandardProcessing) Export
	
	If Common.SubsystemExists("SaaSTechnology.Core") Then
		ModuleSaaSTechnologyIntegrationWithSSL = Common.CommonModule("SaaSTechnologyIntegrationWithSSL");
		ModuleSaaSTechnologyIntegrationWithSSL.OnCheckCanImportDataProcessorFromFile(AdditionalDataProcessor, Result, StandardProcessing);
	EndIf;
	
EndProcedure

// Called to check whether an additional report or data processor can be exported to a file.
//
// Parameters:
//  AdditionalDataProcessor - CatalogRef.AdditionalReportsAndDataProcessors,
//  Result - Boolean - indicates whether additional reports or data processors can be exported to 
//    files.
//  StandardProcessing - Boolean - indicates whether standard processing checks if additional 
//    reports or data processors can be exported to files.
//
Procedure OnCheckCanExportDataProcessorToFile(Val AdditionalDataProcessor, Result, StandardProcessing) Export
	
	If Common.SubsystemExists("SaaSTechnology.Core") Then
		ModuleSaaSTechnologyIntegrationWithSSL = Common.CommonModule("SaaSTechnologyIntegrationWithSSL");
		ModuleSaaSTechnologyIntegrationWithSSL.OnCheckCanExportDataProcessorToFile(AdditionalDataProcessor, Result, StandardProcessing);
	EndIf;
	
EndProcedure

// Fills additional report or data processor publication kinds that cannot be used in the current 
// infobase model.
//
// Parameters:
//  UnavailablePublicationKinds - an array of strings.
//
Procedure OnFillUnavailablePublicationKinds(Val NotAvailablePublicationKinds) Export
	
	If Common.SubsystemExists("SaaSTechnology.Core") Then
		ModuleSaaSTechnologyIntegrationWithSSL = Common.CommonModule("SaaSTechnologyIntegrationWithSSL");
		ModuleSaaSTechnologyIntegrationWithSSL.OnFillUnavailablePublicationKinds(NotAvailablePublicationKinds);
	EndIf;
	
EndProcedure

// The procedure is called from the BeforeWrite event of catalog
//  AdditionalReportsAndDataProcessors. Validates changes to the catalog item attributes for 
//  additional data processors retrieved from the additional data processor directory from the 
//  service manager.
//
// Parameters:
//  Source - CatalogObject.AdditionalReportsAndDataProcessors.
//  Cancel - Boolean - the flag specifying whether writing a catalog item must be canceled.
//
Procedure BeforeWriteAdditionalDataProcessor(Source, Cancel) Export
	
	If Common.SubsystemExists("SaaSTechnology.Core") Then
		ModuleSaaSTechnologyIntegrationWithSSL = Common.CommonModule("SaaSTechnologyIntegrationWithSSL");
		ModuleSaaSTechnologyIntegrationWithSSL.BeforeWriteAdditionalDataProcessor(Source, Cancel);
	EndIf;
	
EndProcedure

// The procedure is called from the BeforeDelete event of catalog
//  AdditionalReportsAndDataProcessors.
//
// Parameters:
//  Source - CatalogObject.AdditionalReportsAndDataProcessors.
//  Cancel - boolean, indicates whether the catalog item deletion from the infobase must be canceled.
//
Procedure BeforeDeleteAdditionalDataProcessor(Source, Cancel) Export
	
	If Common.SubsystemExists("SaaSTechnology.Core") Then
		ModuleSaaSTechnologyIntegrationWithSSL = Common.CommonModule("SaaSTechnologyIntegrationWithSSL");
		ModuleSaaSTechnologyIntegrationWithSSL.BeforeDeleteAdditionalDataProcessor(Source, Cancel);
	EndIf;
	
EndProcedure

// Called to get registration data for a new additional report or data processor.
// 
//
Procedure OnGetRegistrationData(Object, RegistrationData, StandardProcessing) Export
	
	If Common.SubsystemExists("SaaSTechnology.Core") Then
		ModuleSaaSTechnologyIntegrationWithSSL = Common.CommonModule("SaaSTechnologyIntegrationWithSSL");
		ModuleSaaSTechnologyIntegrationWithSSL.OnGetRegistrationData(Object, RegistrationData, StandardProcessing);
	EndIf;
	
EndProcedure

// Called to attach an external data processor.
//
// Parameters:
//  Ref - CatalogRef.AdditionalReportsAndDataProcessors.
//  StandardProcessing - Boolean - indicates whether the standard processing is required to attach 
//    an external data processor.
//  Result - String - a name of the attached external report or data processor (provided that the 
//    handler StandardProcessing parameter is set to False).
//
Procedure OnAttachExternalDataProcessor(Val Ref, StandardProcessing, Result) Export
	
	If Common.SubsystemExists("SaaSTechnology.Core") Then
		ModuleSaaSTechnologyIntegrationWithSSL = Common.CommonModule("SaaSTechnologyIntegrationWithSSL");
		ModuleSaaSTechnologyIntegrationWithSSL.OnAttachExternalDataProcessor(Ref, StandardProcessing, Result);
	EndIf;
	
EndProcedure

// Called to create an external data processor object.
//
// Parameters:
//  Ref - CatalogRef.AdditionalReportsAndDataProcessors.
//  StandardProcessing - Boolean - indicates whether the standard processing is required to attach 
//    an external data processor.
//  Result - ExternalDataProcessorObject, ExternalReportObject - an object of the attached external 
//    report or data processor (provided that the handler StandardProcessing parameter is set to False).
//
Procedure OnCreateExternalDataProcessor(Val Ref, StandardProcessing, Result) Export
	
	If Common.SubsystemExists("SaaSTechnology.Core") Then
		ModuleSaaSTechnologyIntegrationWithSSL = Common.CommonModule("SaaSTechnologyIntegrationWithSSL");
		ModuleSaaSTechnologyIntegrationWithSSL.OnCreateExternalDataProcessor(Ref, StandardProcessing, Result);
	EndIf;
	
EndProcedure

// Called before writing changes of a scheduled job of additional reports and data processors in SaaS.
//
// Parameters:
//   Object - CatalogRef.AdditionalReportsAndDataProcessors - an object of an additional report or a data processor.
//   Command - CatalogTabularSectionRow.AdditionalReportsAndDataProcessors.Commands - command details.
//   Job - ScheduledJob.ValueTableRow - scheduled job details.
//       See details on the ScheduledJobsServer.Job() function return value.
//   Changes - Structure - the job attribute values to be modified.
//       See details of the second parameter of the ScheduledJobsServer.ChangeJob procedure.
//       If the value is Undefined, the scheduled job stays unchanged.
//
Procedure BeforeUpdateJob(Object, Command, Job, Changes) Export
	
	If Common.SubsystemExists("SaaSTechnology.Core") Then
		ModuleSaaSTechnologyIntegrationWithSSL = Common.CommonModule("SaaSTechnologyIntegrationWithSSL");
		ModuleSaaSTechnologyIntegrationWithSSL.BeforeUpdateJob(Object, Command, Job, Changes);
	EndIf;
	
EndProcedure

#EndRegion

#Region IBVersionUpdate

// With it, you can override update priority. The default priority order is stored in the IBUpdateInfo constant.
// For example, STL can override update priority for each data area in SaaS mode.
//
// Parameters:
//  Priority - String - a new update priority value (return value). Valid return values:
//              * "UserWork" - user processing priority (single thread).
//              * "DataProcessing" - data processing priority (several threads).
//              * Another - apply the priority as specified in the IBUpdateInfo constant (do not override).
//
Procedure OnGetUpdatePriority(Priority) Export
	
	If Common.SubsystemExists("SaaSTechnology.Core") Then
		RequiredSTLVersion = "1.0.17.3";
		ModuleSaaSTechnology = Common.CommonModule("SaaSTechnology");
		CurrentSTLVersion = ModuleSaaSTechnology.LibraryVersion();
		
		If CommonClientServer.CompareVersions(CurrentSTLVersion, RequiredSTLVersion) >= 0  Then
			ModuleSaaSTechnologyIntegrationWithSSL = Common.CommonModule("SaaSTechnologyIntegrationWithSSL");
			ModuleSaaSTechnologyIntegrationWithSSL.OnGetUpdatePriorityInDataAreas(Priority);
		EndIf;
	EndIf;
	
EndProcedure

#EndRegion

#Region Users

// The procedure is called if the current infobase user cannot be found in the user catalog.
//  For such cases, you can enable auto creation of a Users catalog item for the current user.
// 
//
// Parameters:
//  CreateUser - Boolean - (return value) - if True, a new user is created in the Users catalog.
//       
//       To override the default user settings before its creation, use 
//       OnAutoCreateCurrentUserInCatalog.
//
Procedure OnNoCurrentUserInCatalog(CreateUser) Export
	
	If Common.SubsystemExists("SaaSTechnology.Core") Then
		ModuleSaaSTechnologyIntegrationWithSSL = Common.CommonModule("SaaSTechnologyIntegrationWithSSL");
		ModuleSaaSTechnologyIntegrationWithSSL.OnNoCurrentUserInCatalog(CreateUser);
	EndIf;
	
EndProcedure

// The procedure is called when a Users catalog item is created automatically as a result of 
// interactive sign in or on the call from code.
//
// Parameters:
//  NewUser - CatalogObject.Users - the new user, not written.
//
Procedure OnAutoCreateCurrentUserInCatalog(NewUser) Export
	
	If Common.SubsystemExists("SaaSTechnology.Core") Then
		ModuleSaaSTechnologyIntegrationWithSSL = Common.CommonModule("SaaSTechnologyIntegrationWithSSL");
		ModuleSaaSTechnologyIntegrationWithSSL.OnAutoCreateCurrentUserInCatalog(NewUser);
	EndIf;
	
EndProcedure

// The procedure is called during the authorization of a new infobase user.
//
// Parameters:
//  IBUser - InfobaseUser - the current infobase user.
//  StandardProcessing - Boolean, the value can be set in the handler. In this case, standard 
//    processing of new infobase user authorization is not executed.
//
Procedure OnAuthorizeNewIBUser(InfobaseUser, StandardProcessing) Export
	
	If Common.SubsystemExists("SaaSTechnology.Core") Then
		ModuleSaaSTechnologyIntegrationWithSSL = Common.CommonModule("SaaSTechnologyIntegrationWithSSL");
		ModuleSaaSTechnologyIntegrationWithSSL.OnAuthorizeNewIBUser(InfobaseUser, StandardProcessing);
	EndIf;
	
EndProcedure

// The procedure is called at the start of infobase user processing.
//
// Parameters:
//  ProcessingParameters - Structure - see the comment to the StartIBUserProcessing() procedure.
//  StartIBUserProcessing - Structure - see the comment to the StartIBUserProcessing() procedure.
//
Procedure OnStartIBUserProcessing(ProcessingParameters, IBUserDetails) Export
	
	If Common.SubsystemExists("SaaSTechnology.Core") Then
		ModuleSaaSTechnologyIntegrationWithSSL = Common.CommonModule("SaaSTechnologyIntegrationWithSSL");
		ModuleSaaSTechnologyIntegrationWithSSL.OnStartIBUserProcessing(ProcessingParameters, IBUserDetails);
	EndIf;
	
EndProcedure

// Called before writing an infobase user.
//
// Parameters:
//  IBUser - InfobaseUser - the user to be written.
//
Procedure BeforeWriteIBUser(InfobaseUser) Export
	
	If Common.SubsystemExists("SaaSTechnology.Core") Then
		ModuleSaaSTechnologyIntegrationWithSSL = Common.CommonModule("SaaSTechnologyIntegrationWithSSL");
		ModuleSaaSTechnologyIntegrationWithSSL.BeforeWriteIBUser(InfobaseUser);
	EndIf;
	
EndProcedure

// Called before deleting an infobase user.
//
// Parameters:
//  IBUser - InfobaseUser - the user to be deleted.
//
Procedure BeforeDeleteIBUser(InfobaseUser) Export
	
	If Common.SubsystemExists("SaaSTechnology.Core") Then
		ModuleSaaSTechnologyIntegrationWithSSL = Common.CommonModule("SaaSTechnologyIntegrationWithSSL");
		ModuleSaaSTechnologyIntegrationWithSSL.BeforeDeleteIBUser(InfobaseUser);
	EndIf;
	
EndProcedure

#EndRegion

#Region SecurityProfiles

// Called when checking whether security profiles can be set.
//
// Parameters:
//  Cancel - Boolean. If security profiles cannot be used for the infobase, set the value of this 
//    parameter to True.
//
Procedure CanSetupSecurityProfilesOnCheck(Cancel) Export
	
	If Common.SubsystemExists("SaaSTechnology.Core") Then
		ModuleSaaSTechnologyIntegrationWithSSL = Common.CommonModule("SaaSTechnologyIntegrationWithSSL");
		ModuleSaaSTechnologyIntegrationWithSSL.CanSetUpSecurityProfilesOnCheck(Cancel);
	EndIf;
	
EndProcedure

// See SafeModeManagerOverridable.OnRequestPermissionsToUseExternalResources. 
Procedure OnRequestPermissionsToUseExternalResources(Val ProgramModule, Val Owner, Val ReplacementMode, Val PermissionsToAdd, Val PermissionsToDelete, StandardProcessing, Result) Export
	
	If Common.SubsystemExists("SaaSTechnology.Core") Then
		ModuleSaaSTechnologyIntegrationWithSSL = Common.CommonModule("SaaSTechnologyIntegrationWithSSL");
		ModuleSaaSTechnologyIntegrationWithSSL.OnRequestPermissionsToUseExternalResources(ProgramModule, Owner, ReplacementMode, PermissionsToAdd, PermissionsToDelete, StandardProcessing, Result);
	EndIf;
	
EndProcedure

// See SafeModeManagerOverridable.OnRequestToCreateSecurityProfile. 
Procedure OnRequestToCreateSecurityProfile(Val ProgramModule, StandardProcessing, Result) Export
	
	If Common.SubsystemExists("SaaSTechnology.Core") Then
		ModuleSaaSTechnologyIntegrationWithSSL = Common.CommonModule("SaaSTechnologyIntegrationWithSSL");
		ModuleSaaSTechnologyIntegrationWithSSL.OnRequestToCreateSecurityProfile(ProgramModule, StandardProcessing, Result);
	EndIf;
	
EndProcedure

// See SafeModeManagerOverridable.OnRequestToDeleteSecurityProfile. 
Procedure OnRequestToDeleteSecurityProfile(Val ProgramModule, StandardProcessing, Result) Export
	
	If Common.SubsystemExists("SaaSTechnology.Core") Then
		ModuleSaaSTechnologyIntegrationWithSSL = Common.CommonModule("SaaSTechnologyIntegrationWithSSL");
		ModuleSaaSTechnologyIntegrationWithSSL.OnRequestToDeleteSecurityProfile(ProgramModule, StandardProcessing, Result);
	EndIf;
	
EndProcedure

// See SafeModeManagerOverridable.OnAttachExternalModule. 
Procedure OnAttachExternalModule(Val ExternalModule, SafeMode) Export
	
	If Common.SubsystemExists("SaaSTechnology.Core") Then
		ModuleSaaSTechnologyIntegrationWithSSL = Common.CommonModule("SaaSTechnologyIntegrationWithSSL");
		ModuleSaaSTechnologyIntegrationWithSSL.OnAttachExternalModule(ExternalModule, SafeMode);
	EndIf;
	
EndProcedure

#EndRegion

#Region SaaS_CoreSaaS

// See SaaSOverridable.OnFillIBParametersTable. 
Procedure OnFillIIBParametersTable(Val ParametersTable) Export
	
	If Common.SubsystemExists("SaaSTechnology.Core") Then
		ModuleSaaSTechnologyIntegrationWithSSL = Common.CommonModule("SaaSTechnologyIntegrationWithSSL");
		ModuleSaaSTechnologyIntegrationWithSSL.OnFillIIBParametersTable(ParametersTable);
	EndIf;
	
EndProcedure

// Called when determining the user alias to be displayed in the interface.
//
// Parameters:
//  UserID - UUID.
//  Alias - String - the user alias.
//
Procedure OnDefineUserAlias(UserID, Alias) Export
	
	If Common.SubsystemExists("SaaSTechnology.Core") Then
		ModuleSaaSTechnologyIntegrationWithSSL = Common.CommonModule("SaaSTechnologyIntegrationWithSSL");
		ModuleSaaSTechnologyIntegrationWithSSL.OnDefineUserAlias(UserID, Alias);
	EndIf;
	
EndProcedure

// The procedure called on defining a list of unseparated metadata that can be written from a 
// separated session. The procedure adds references to metadata objects to be excluded to the 
// Exceptions array. The metadata might not exist in subscriptions that check if writing unseparated 
// data from the separated session is restricted.
Procedure OnDefineSharedDataExceptions(Exceptions) Export
	
	If Common.SubsystemExists("SaaSTechnology.Core") Then
		ModuleSaaSTechnologyIntegrationWithSSL = Common.CommonModule("SaaSTechnologyIntegrationWithSSL");
		ModuleSaaSTechnologyIntegrationWithSSL.OnDefineSharedDataExceptions(Exceptions);
	EndIf;
	
EndProcedure

#EndRegion

#Region SaaS_MessagesExchange

// See MessagesExchangeOverridable.GetMessagesChannelsHandlers. 
Procedure MessageChannelHandlersOnDefine(Handlers) Export
	
	If Common.SubsystemExists("SaaSTechnology.Core") Then
		ModuleSaaSTechnologyIntegrationWithSSL = Common.CommonModule("SaaSTechnologyIntegrationWithSSL");
		ModuleSaaSTechnologyIntegrationWithSSL.MessageChannelHandlersOnDefine(Handlers);
	EndIf;
	
EndProcedure

// See MessagesInterfacesSaaSOverridable.FillIncomingMessagesHandlers. 
Procedure RecordingIncomingMessageInterfaces(HandlersArray) Export
	
	If Common.SubsystemExists("SaaSTechnology.Core") Then
		ModuleSaaSTechnologyIntegrationWithSSL = Common.CommonModule("SaaSTechnologyIntegrationWithSSL");
		ModuleSaaSTechnologyIntegrationWithSSL.RecordingIncomingMessageInterfaces(HandlersArray);
	EndIf;
	
EndProcedure

// See MessagesInterfacesSaaSOverridable.FillOutgoingMessagesHandlers. 
Procedure RecordingOutgoingMessageInterfaces(HandlersArray) Export
	
	If Common.SubsystemExists("SaaSTechnology.Core") Then
		ModuleSaaSTechnologyIntegrationWithSSL = Common.CommonModule("SaaSTechnologyIntegrationWithSSL");
		ModuleSaaSTechnologyIntegrationWithSSL.RecordingOutgoingMessageInterfaces(HandlersArray);
	EndIf;
	
EndProcedure

// See MessagesInterfacesSaaSOverridable.OnDefineCorrespondentInterfaceVersion. 
Procedure OnDefineCorrespondentInterfaceVersion(Val MessageInterface, Val ConnectionParameters, Val RecipientPresentation, Result) Export
	
	If Common.SubsystemExists("SaaSTechnology.Core") Then
		ModuleSaaSTechnologyIntegrationWithSSL = Common.CommonModule("SaaSTechnologyIntegrationWithSSL");
		ModuleSaaSTechnologyIntegrationWithSSL.OnDefineCorrespondentInterfaceVersion(MessageInterface, ConnectionParameters, RecipientPresentation, Result);
	EndIf;
	
EndProcedure

#EndRegion

#Region SaaS_JobQueue

// See JobsQueueOverridable.OnGetTemplatesList. 
Procedure OnGetTemplateList(JobTemplates) Export
	
	If Common.SubsystemExists("SaaSTechnology.Core") Then
		ModuleSaaSTechnologyIntegrationWithSSL = Common.CommonModule("SaaSTechnologyIntegrationWithSSL");
		ModuleSaaSTechnologyIntegrationWithSSL.OnGetTemplateList(JobTemplates);
	EndIf;
	
EndProcedure

// See JobsQueueOverridable.OnDefineHandlersAliases. 
Procedure OnDefineHandlerAliases(NameAndAliasMap) Export
	
	If Common.SubsystemExists("SaaSTechnology.Core") Then
		ModuleSaaSTechnologyIntegrationWithSSL = Common.CommonModule("SaaSTechnologyIntegrationWithSSL");
		ModuleSaaSTechnologyIntegrationWithSSL.OnDefineHandlerAliases(NameAndAliasMap);
	EndIf;
	
EndProcedure

// See JobsQueueOverridable.OnDefineErrorsHandlers. 
Procedure OnDefineErrorsHandlers(ErrorHandlers) Export
	
	If Common.SubsystemExists("SaaSTechnology.Core") Then
		ModuleSaaSTechnologyIntegrationWithSSL = Common.CommonModule("SaaSTechnologyIntegrationWithSSL");
		ModuleSaaSTechnologyIntegrationWithSSL.OnDefineErrorsHandlers(ErrorHandlers);
	EndIf;
	
EndProcedure

// See JobsQueueOverridable.OnDefineScheduledJobsUsage. 
Procedure OnDefineScheduledJobsUsage(UsageTable) Export
	
	If Common.SubsystemExists("SaaSTechnology.Core") Then
		ModuleSaaSTechnologyIntegrationWithSSL = Common.CommonModule("SaaSTechnologyIntegrationWithSSL");
		ModuleSaaSTechnologyIntegrationWithSSL.OnDefineScheduledJobsUsage(UsageTable);
	EndIf;
	
EndProcedure

#EndRegion

#Region SaaS_SuppliedData

// See SuppliedDataOverridable.GetSuppliedDataHandlers. 
Procedure OnDefineSuppliedDataHandlers(Handlers) Export
	
	If Common.SubsystemExists("SaaSTechnology.Core") Then
		ModuleSaaSTechnologyIntegrationWithSSL = Common.CommonModule("SaaSTechnologyIntegrationWithSSL");
		ModuleSaaSTechnologyIntegrationWithSSL.OnDefineSuppliedDataHandlers(Handlers);
	EndIf;
	
EndProcedure

#EndRegion

#Region ScheduledJobs

// See ScheduledJobsOverridable.OnDefineScheduledJobsSettings. 
Procedure OnDefineScheduledJobSettings(Settings) Export
	
	If Common.SubsystemExists("SaaSTechnology.Core") Then
		ModuleSaaSTechnology = Common.CommonModule("SaaSTechnology");
		If CommonClientServer.CompareVersions(ModuleSaaSTechnology.LibraryVersion(), "1.0.13.1") >= 0 Then
			ModuleSaaSTechnologyIntegrationWithSSL = Common.CommonModule("SaaSTechnologyIntegrationWithSSL");
			ModuleSaaSTechnologyIntegrationWithSSL.OnDefineScheduledJobSettings(Settings);
		EndIf;
	EndIf;
	
EndProcedure

#EndRegion

#Region AccessManagement

// This procedure is called when updating the infobase user roles.
//
// Parameters:
//  IBUserID - UUID.
//  Cancel - Boolean. If this parameter is set to False in the event handler, roles are not updated 
//    for this infobase user.
//
Procedure OnUpdateIBUserRoles(IBUserID, Cancel) Export
	
	If Common.SubsystemExists("SaaSTechnology.Core") Then
		ModuleSaaSTechnologyIntegrationWithSSL = Common.CommonModule("SaaSTechnologyIntegrationWithSSL");
		ModuleSaaSTechnologyIntegrationWithSSL.OnUpdateIBUserRoles(IBUserID, Cancel);
	EndIf;
	
EndProcedure

#EndRegion

#EndRegion
