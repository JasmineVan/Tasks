///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Private

Function FormCache(Val FormName, Val SourcesCommaSeparated, Val IsObjectForm) Export
	Return New FixedStructure(AttachableCommands.FormCache(FormName, SourcesCommaSeparated, IsObjectForm));
EndFunction

Function Parameters() Export
	
	SetSafeModeDisabled(True);
	SetPrivilegedMode(True);
	
	Parameters = StandardSubsystemsServer.ApplicationParameter("StandardSubsystems.AttachableCommands");
	If Parameters = Undefined Then
		AttachableCommands.ConfigurationCommonDataNonexclusiveUpdate();
		Parameters = StandardSubsystemsServer.ApplicationParameter("StandardSubsystems.AttachableCommands");
		If Parameters = Undefined Then
			Return New FixedStructure("AttachedObjects", New Map);
		EndIf;
	EndIf;
	
	If ValueIsFilled(SessionParameters.ExtensionsVersion) Then
		ExtensionParameters = StandardSubsystemsServer.ExtensionParameter(AttachableCommands.FullSubsystemName());
		If ExtensionParameters = Undefined Then
			AttachableCommands.OnFillAllExtensionsParameters();
			ExtensionParameters = StandardSubsystemsServer.ExtensionParameter(AttachableCommands.FullSubsystemName());
			If ExtensionParameters = Undefined Then
				Return New FixedStructure(Parameters);
			EndIf;
		EndIf;
		SupplementMapWithArrays(Parameters.AttachedObjects, ExtensionParameters.AttachedObjects);
	EndIf;
	
	SetPrivilegedMode(False);
	SetSafeModeDisabled(False);
	
	Return New FixedStructure(Parameters);
EndFunction

Procedure SupplementMapWithArrays(DestinationMap, SourceMap)
	For Each KeyAndValue In SourceMap Do
		DestinationArray = DestinationMap[KeyAndValue.Key];
		If DestinationArray = Undefined Then
			DestinationMap[KeyAndValue.Key] = KeyAndValue.Value;
		Else
			CommonClientServer.SupplementArray(DestinationArray, KeyAndValue.Value, True);
		EndIf;
	EndDo;
EndProcedure

#EndRegion
