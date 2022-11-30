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
	
	FormParameters = New Structure;
	FormParameters.Insert("AuthorizationObject", CommandParameter);
	
	Try
		OpenForm(
			"Catalog.ExternalUsers.ObjectForm",
			FormParameters,
			CommandExecuteParameters.Source,
			CommandExecuteParameters.Uniqueness,
			CommandExecuteParameters.Window);
	Except
		ErrorInformation = ErrorInfo();
		If StrFind(DetailErrorDescription(ErrorInformation),
		         "Raise" + " " + "ErrorAsWarningDescription") > 0 Then
			
			ShowMessageBox(, BriefErrorDescription(ErrorInformation));
		Else
			Raise;
		EndIf;
	EndTry;
	
EndProcedure

#EndRegion
