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
	
	If StandardSubsystemsClient.ClientRunParameters().SeparatedDataUsageAvailable Then
		NameOfFormToOpen = "DataProcessor.SSLAdministrationPanel.Form.DataSynchronization";
	Else
		NameOfFormToOpen = "DataProcessor.SSLAdministrationPanelSaaS.Form.DataSynchronizationForServiceAdministrator";
	EndIf;
	
	OpenForm(
		NameOfFormToOpen,
		New Structure,
		CommandExecuteParameters.Source,
		NameOfFormToOpen + ?(CommandExecuteParameters.Window = Undefined, ".SingleWindow", ""),
		CommandExecuteParameters.Window);
	
EndProcedure

#EndRegion
