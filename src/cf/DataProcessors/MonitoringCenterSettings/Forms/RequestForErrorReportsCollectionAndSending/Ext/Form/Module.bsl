///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region FormCommandHandlers

&AtClient
Procedure GoToSettingsClick(Item)
	Close();
	OpenForm("DataProcessor.MonitoringCenterSettings.Form.MonitoringCenterSettings");
EndProcedure

&AtClient
Procedure Yes(Command)
	NewParameters = New Structure("SendDumpsFiles", 1);
	SetMonitoringCenterParameters(NewParameters);
	Close();
EndProcedure

&AtClient
Procedure No(Command)
	NewParameters = New Structure("SendDumpsFiles", 0);
	NewParameters.Insert("SendingResult", NStr("ru = 'Пользователь отказал в предоставлении полных дампов.'; en = 'User refused to submit full dumps.'; pl = 'User refused to submit full dumps.';de = 'User refused to submit full dumps.';ro = 'User refused to submit full dumps.';tr = 'User refused to submit full dumps.'; es_ES = 'User refused to submit full dumps.'"));
	SetMonitoringCenterParameters(NewParameters);
	Close();
EndProcedure

#EndRegion

#Region Private

&AtServerNoContext
Procedure SetMonitoringCenterParameters(NewParameters)
	MonitoringCenterInternal.SetMonitoringCenterParametersExternalCall(NewParameters);
EndProcedure

#EndRegion

