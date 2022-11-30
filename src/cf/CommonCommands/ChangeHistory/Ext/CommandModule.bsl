///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region EventHandlers

&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)
	
	If CommandParameter = Undefined Then
		Return;
	EndIf;
	
	If TypeOf(CommandParameter) = Type("Array") Then
		If CommandParameter.Count() = 0 Then
			Return;
		EndIf;
		ObjectRef = CommandParameter[0];
	Else
		ObjectRef = CommandParameter;
	EndIf;
	
	FormParameters = New Structure;
	FormParameters.Insert("Ref", ObjectRef);
	FormParameters.Insert("ReadOnly", CommandExecuteParameters.Source.ReadOnly);
	
	OpenForm("InformationRegister.ObjectsVersions.Form.SelectStoredVersions",
								FormParameters,
								CommandExecuteParameters.Source,
								CommandExecuteParameters.Uniqueness,
								CommandExecuteParameters.Window);
	
EndProcedure

#EndRegion
