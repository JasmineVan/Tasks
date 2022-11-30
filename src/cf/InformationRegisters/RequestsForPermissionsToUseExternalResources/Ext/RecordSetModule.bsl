///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Private

Procedure OnWrite(Cancel, Replacing)
	
	// DataExchange.Import is not required.
	// Writing internal data in safe mode is prohibited.
	If SafeModeManager.SafeModeSet() Then
		
		CurrentSafeMode = SafeMode();
		
		For Each Record In ThisObject Do
			
			If Record.SafeMode <> CurrentSafeMode Then
				
				Raise StringFunctionsClientServer.SubstituteParametersToString(
					NStr("ru = 'Безопасный режим %1 отличается от текущего %2'; en = 'Safe mode (%1) is different from the current one (%2)'; pl = 'Safe mode (%1) is different from the current one (%2)';de = 'Safe mode (%1) is different from the current one (%2)';ro = 'Safe mode (%1) is different from the current one (%2)';tr = 'Safe mode (%1) is different from the current one (%2)'; es_ES = 'Safe mode (%1) is different from the current one (%2)'"),
					Record.SafeMode, CurrentSafeMode);
				
			EndIf;
			
			ProgramModule = SafeModeManagerInternal.ReferenceFormPermissionRegister(
				Record.OwnerType, Record.ModuleID);
			
			If ProgramModule <> Catalogs.MetadataObjectIDs.EmptyRef() Then
				
				ProgramModuleSafeMode = InformationRegisters.ExternalModulesAttachmentModes.ExternalModuleAttachmentMode(
					ProgramModule);
				
				If Record.SafeMode <> ProgramModuleSafeMode Then
					
					Raise StringFunctionsClientServer.SubstituteParametersToString(
						NStr("ru = 'Для программного модуля %1 не может быть выполнен запрос разрешений из безопасного режима %2'; en = 'Cannot perform the permission request for the %1 program module in the %2 safe mode'; pl = 'Cannot perform the permission request for the %1 program module in the %2 safe mode';de = 'Cannot perform the permission request for the %1 program module in the %2 safe mode';ro = 'Cannot perform the permission request for the %1 program module in the %2 safe mode';tr = 'Cannot perform the permission request for the %1 program module in the %2 safe mode'; es_ES = 'Cannot perform the permission request for the %1 program module in the %2 safe mode'"),
						String(ProgramModule), Record.SafeMode);
					
				EndIf;
				
			EndIf;
			
		EndDo;
		
	EndIf;
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
EndProcedure

#EndRegion

#Else
Raise NStr("ru = 'Недопустимый вызов объекта на клиенте.'; en = 'Invalid object call on the client.'; pl = 'Invalid object call on the client.';de = 'Invalid object call on the client.';ro = 'Invalid object call on the client.';tr = 'Invalid object call on the client.'; es_ES = 'Invalid object call on the client.'");
#EndIf