///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Private

// Returns external module attachment mode.
//
// Parameters:
//  ProgramModule - AnyRef - a reference to a module.
//    
//
// Returns: String - a name of the security profile to be used for attaching the external module.
//   If the attachment mode is not registered for the external module, Undefined is returned.
//
Function ExternalModuleAttachmentMode(Val ProgramModule) Export
	
	If SafeModeManager.SafeModeSet() Then
		
		// If the safe mode is set higher in the stack, external modules can be attached in the same safe 
		// mode.
		Result = SafeMode();
		
	Else
		
		SetPrivilegedMode(True);
		
		ModuleProperties = SafeModeManagerInternal.PropertiesForPermissionRegister(ProgramModule);
		
		Manager = CreateRecordManager();
		Manager.ModuleType = ModuleProperties.Type;
		Manager.ModuleID = ModuleProperties.ID;
		Manager.Read();
		If Manager.Selected() Then
			Result = Manager.SafeMode;
		Else
			Result = Undefined;
		EndIf;
		
		SaaSIntegration.OnAttachExternalModule(ProgramModule, Result);
		SafeModeManagerOverride.OnAttachExternalModule(ProgramModule, Result);
		
	EndIf;
	
	Return Result;
	
EndFunction

#EndRegion

#EndIf
