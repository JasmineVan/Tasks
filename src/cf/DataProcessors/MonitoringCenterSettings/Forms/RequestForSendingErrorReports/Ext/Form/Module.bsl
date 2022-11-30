///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region EventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	ParametersToGet = New Structure("DumpsInformation, DumpInstances, DumpInstancesApproved");
	MonitoringCenterParameters = MonitoringCenterInternal.GetMonitoringCenterParameters(ParametersToGet);
	DumpsInformation = MonitoringCenterParameters.DumpsInformation;
	Items.DumpsInformation.Height = StrLineCount(DumpsInformation);
	DumpsData = New Structure;
	DumpsData.Insert("DumpInstances", MonitoringCenterParameters.DumpInstances);
	DumpsData.Insert("DumpInstancesApproved", MonitoringCenterParameters.DumpInstancesApproved);
EndProcedure

#EndRegion

#Region FormCommandHandlers

&AtClient
Procedure Yes(Command)
	Response = New Structure;
	Response.Insert("Consistent", True);
	Response.Insert("DumpsInformation", DumpsInformation);
	Response.Insert("DoNotAskAgain", DoNotAskAgain);
	Response.Insert("DumpInstances", DumpsData.DumpInstances);
	Response.Insert("DumpInstancesApproved", DumpsData.DumpInstancesApproved);	
	SetMonitoringCenterParameters(Response);
	Close();
EndProcedure

&AtClient
Procedure No(Command)
	Response = New Structure;
	Response.Insert("Consistent", False);
	Response.Insert("DoNotAskAgain", DoNotAskAgain);
	SetMonitoringCenterParameters(Response);
	Close();
EndProcedure

#EndRegion

#Region Private

&AtServerNoContext
Procedure SetMonitoringCenterParameters(Response)
	
	NewParameters = New Structure;
	
	If Response.Consistent Then
		
		// The user does not want to be asked.
		If Response.DoNotAskAgain Then
			NewParameters.Insert("RequestConfirmationBeforeSending", False);
		EndIf;
		
		// Request for the current parameters as they might be changed.
		ParametersToGet = New Structure("DumpsInformation, DumpInstances");
		MonitoringCenterParameters = MonitoringCenterInternal.GetMonitoringCenterParameters(ParametersToGet);
		
		// Add dumps approved by the user to the approved ones.
		NewParameters.Insert("DumpInstancesApproved", Response.DumpInstancesApproved);
		For Each Record In Response.DumpInstances Do
			NewParameters.DumpInstancesApproved.Insert(Record.Key, Record.Value);
			MonitoringCenterParameters.DumpInstances.Delete(Record.Key);
		EndDo;
		
		NewParameters.Insert("DumpInstances", MonitoringCenterParameters.DumpInstances);
		
		// Clear parameters.
		If Response.DumpsInformation = MonitoringCenterParameters.DumpsInformation Then
			NewParameters.Insert("DumpsInformation", "");	
		EndIf;
		
	Else
		
		// The user does not want to be asked and they are not going to send anything.
		If Response.DoNotAskAgain Then
			NewParameters.Insert("SendDumpsFiles", 0);
			NewParameters.Insert("SendingResult", NStr("ru = 'Пользователь отказал в предоставлении полных дампов.'; en = 'User refused to submit full dumps.'; pl = 'User refused to submit full dumps.';de = 'User refused to submit full dumps.';ro = 'User refused to submit full dumps.';tr = 'User refused to submit full dumps.'; es_ES = 'User refused to submit full dumps.'"));
			// There is nothing to approve, clear parameters.
			NewParameters.Insert("DumpsInformation", "");
			NewParameters.Insert("DumpInstances", New Map);
		EndIf;
		
	EndIf;    
	
	MonitoringCenterInternal.SetMonitoringCenterParametersExternalCall(NewParameters);
	
EndProcedure

#EndRegion
