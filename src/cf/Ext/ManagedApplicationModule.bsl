///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Variables

// StandardSubsystems

// Storage of global variables.
//
// ApplicationParameters - Map - value storage, where:
//   * Key - String - a variable name in the format of  "LibraryName.VariableName";
//   * Value - Arbitrary - a variable value.
//
// Initialization (see the example of MessagesForEventLog):
//   ParameterName = "StandardSubsystems.MessagesForEventLog";
//   If ApplicationParameters[ParameterName] = Undefined Then
//     ApplicationParameters.Insert(ParameterName, New ValueList);
//   EndIf.
//  
// Usage (as illustrated by MessagesForEventLog):
//   ApplicationParameters["StandardSubsystems.MessagesForEventLog"].Add(...);
//   ApplicationParameters["StandardSubsystems.MessagesForEventLog"] = ...;
Var ApplicationParameters Export;

// End StandardSubsystems

#EndRegion

#Region EventHandlers

Procedure BeforeStart()
	
	// StandardSubsystems
	StandardSubsystemsClient.BeforeStart();
	// End StandardSubsystems
	
	
	
EndProcedure

Procedure OnStart()
	
	// StandardSubsystems
	StandardSubsystemsClient.OnStart();
	// End StandardSubsystems
	
EndProcedure

Procedure BeforeExit(Cancel, WarningText)
	
	// StandardSubsystems
	StandardSubsystemsClient.BeforeExit(Cancel, WarningText);
	// End StandardSubsystems
	
EndProcedure

#EndRegion