///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Public

#Region ForCallsFromOtherSubsystems

// StandardSubsystems.IBVersionUpdate

////////////////////////////////////////////////////////////////////////////////
// Info about the library or configuration.

// Fills the general information about the library or base configuration.
// The library that has the same name as the base configuration name in the metadata is considered base configuration.
// 
// Parameters:
//  Description - Structure - library details:
//
//   * Name                 - String - library name (for example, "StandardSubsystems").
//   * Version              - String - version number in a four-digit format (for example, "2.1.3.1").
//
//   * OnlineSupportID - String - a unique application name in online support services.
//   * RequiredSubsystems - Array - names of other libraries (String) the current library depends on.
//                                    Update handlers of such libraries should be called earlier 
//                                    than update handlers of the current library.
//                                    If they have cyclic dependencies or, on the contrary, no 
//                                    dependencies, the update handlers call order is determined by 
//                                    the order of added modules in the SubsystemsOnAdd procedure of the common module
//                                    ConfigurationSubsystemsOverridable.
//   * DeferredHandlerExecutionMode - String - Sequential - deferred update handlers run 
//                                    sequentially in the interval from the infobase version number 
//                                    to the configuration version number. 
//                                    DeferredHandlerExecutionMode - String - Parallel - once the 
//                                    first data batch is processed, the deferred handler passes control to another handler; once the last handler finishes work, the cycle is repeated.
//
Procedure OnAddSubsystem(Details) Export
	
	Details.Name    = "FinancialManagement";
	Details.Version = "3.0.3.14";
	Details.OnlineSupportID = "FM";
	Details.DeferredHandlerExecutionMode = "Parallel";
	Details.ParralelDeferredUpdateFromVersion = "2.3.3.0";
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Infobase update handlers.

// Adds the procedures-Infobase data update handlers for all supported versions of the library or 
// configuration to the list.
// Called before the beginning of Infobase data update to build the update plan.
//
// Parameters:
//  Handlers - ValueTable - see InfobaseUpdate.NewUpdateHandlerTable. 
//
// Example:
//  To add a custom handler procedure to a list:
//  Handler = Handlers.Add();
//  Handler.Version              = "1.1.0.0";
//  Handler.Procedure           = "IBUpdate.SwitchToVersion_1_1_0_0";
//  Handler.ExecutionMode     = "Seamless";
//
Procedure OnAddUpdateHandlers(Handlers) Export
	
	SSLSubsystemsIntegration.OnAddUpdateHandlers(Handlers);
	
	// rarus fm begin
	Handler = Handlers.Add();
	Handler.Version              = "3.0.3.14";
	Handler.Procedure           = "Catalogs.fmBudgetingScenarios.FillPredefinedValues";
	Handler.InitialFilling = True;
	Handler.SharedData         = True;
	
	Handler = Handlers.Add();
	Handler.Version              = "3.0.3.14";
	Handler.Procedure           = "Catalogs.fmDepartmentsStructuresVersions.FillPredefinedValues";
	Handler.InitialFilling = True;
	Handler.SharedData         = True;
	
	Handler = Handlers.Add();
	Handler.Version              = "3.0.3.14";
	Handler.Procedure           = "Catalogs.fmInfoStructures.FillPredefinedValuesIncomesAndExpenses";
	Handler.InitialFilling = True;
	Handler.SharedData         = True;
	
	Handler = Handlers.Add();
	Handler.Version              = "3.0.3.14";
	Handler.Procedure           = "Catalogs.fmInfoStructures.FillPredefinedValuesCashflow";
	Handler.InitialFilling = True;
	Handler.SharedData         = True;
	// rarus fm end
	
EndProcedure

// See InfobaseUpdateOverridable. BeforeInfobaseUpdate. 
Procedure BeforeUpdateInfobase() Export
	
EndProcedure

// See InfobaseUpdateOverridable.AfterUpdateInfobase. 
Procedure AfterUpdateInfobase(Val PreviousVersion, Val CurrentVersion,
		Val CompletedHandlers, OutputUpdatesDetails, ExclusiveMode) Export
		
	SSLSubsystemsIntegration.AfterUpdateInfobase(PreviousVersion, CurrentVersion,
		CompletedHandlers, OutputUpdatesDetails, ExclusiveMode);
		
EndProcedure

// See InfobaseUpdateOverridable.OnPrepareUpdatesDescriptionTemplate. 
Procedure OnPrepareUpdateDetailsTemplate(Val Template) Export
	
EndProcedure

// Overrides infobase data update mode.
// Used in rare (irregular) migration scenarios not applied in the standard update procedure.
// 
//
// Parameters:
//   DataUpdateMode - String - one of the values can be assigned in a handler: 
//              "InitialFilling" if this is the first start of an empty infobase (data area).
//              "VersionUpdate" if this is the first start after an infobase configuration update.
//              MigrationFromAnotherApplication if this is the first start after infobase 
//                                          configuration update that changed the configuration name.
//
//   StandardProcessing - Boolean - if False is attributed, the standard procedure of the update 
//                                    mode identification is not executed, the DataUpdateMode is 
//                                    used instead.
//
Procedure OnDefineDataUpdateMode(DataUpdateMode, StandardProcessing) Export
	
EndProcedure

// Adds handlers of migration from another application to the list.
// For example, to migrate between different applications of the same family: Base -> Standard > CORP
// The procedure is called prior to infobase data update.
//
// Parameters:
//  Handlers - ValueTable - with the following columns:
//    * PreviousConfigurationName - String - a name of the configuration to migrate from;
//                                           or an asterisk ("*") if must be executed while migrating from any configuration.
//    * Procedure                 - String - full name of a handler procedure for a migration from a program
//                                           PreviousConfigurationName.
//                                  For example, "MEMInfobaseUpdate.FillAdministrativePolicy"
//                                  Must be an export procedure.
//
// Example:
//  Handler = Handlers.Add();
//  Handler.PreviousConfigurationName = "TradeManagement";
//  Handler.Procedure = "MEMInfobaseUpdate.FillAdministrativePolicy";
//
Procedure OnAddApplicationMigrationHandlers(Handlers) Export
	
EndProcedure

// Called when all the application migration handlers have been executed but before the infobase 
// data update.
//
// Parameters:
//  PreviousConfigurationName    - String - a configuration name before migration.
//  PreviousConfigurationVersion - String - a name of the previous configuration (before migration).
//  Parameters                    - Structure - 
//    * ExecExecuteUpdateFromVersion   - Boolean - True by default. If False, only mandatory update 
//        handlers (with version "*") are executed.
//    * ConfigurationVersion           - String - a version number after migration.
//        By default, it is equal to the version in configuration metadata properties.
//        To execute, for example, all migration from PreviousConfigurationVersion handlers, set the 
//        PreviousConfigurationVersion parameter.
//        To perform all update handlers, set the value to "0.0.0.1".
//    * ClearPreviousConfigurationInfo - Boolean - True by default.
//        When the previous configuration has the same name with one of current configuration 
//        subsystems, set the parameter to False.
//
Procedure OnCompleteApplicationMigration(PreviousConfigurationName, PreviousConfigurationVersion, Parameters) Export
	
EndProcedure

// End StandardSubsystems.IBVersionUpdate

#EndRegion

#EndRegion
