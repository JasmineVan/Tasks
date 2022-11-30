///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Internal

Procedure OnExecuteStandardPeriodicChecksAtClient(Parameters) Export
    
    Windows = GetWindows();
    ActiveWIndows = 0;
	If Windows <> Undefined Then
		For Each CurWindow In Windows Do
	        If Not CurWindow.IsMain Then
	            ActiveWIndows = ActiveWIndows + 1;
	        EndIf;
		EndDo;
	EndIf;
    
    ApplicationParametersMonitoringCenter = GetApplicationParameters();
    ApplicationParametersMonitoringCenter["ClientInformation"].Insert("ActiveWindows", ActiveWIndows);
    
    Parameters.Insert("MonitoringCenter", New FixedMap(ApplicationParametersMonitoringCenter));
    
    Measurements = New Map;
    Measurements.Insert(0, New Array);
    Measurements.Insert(1, New Map);
    Measurements.Insert(2, New Map);
    ApplicationParametersMonitoringCenter.Insert("Measurements", Measurements);
    
EndProcedure

Procedure AfterStandardPeriodicChecksAtClient(Parameters) Export
    
    ApplicationParametersMonitoringCenter = GetApplicationParameters();
    ApplicationParametersMonitoringCenter.Insert("RegisterBusinessStatistics", Parameters.MonitoringCenter["RegisterBusinessStatistics"]);
	
	If Parameters.MonitoringCenter.Get("RequestForGettingDumps") = True Then
		NotifyRequestForReceivingDumps();
		SetApplicationParametersMonitoringCenter("PromptForFullDumpDisplayed", True);
	EndIf;
	If Parameters.MonitoringCenter.Get("RequestForGettingContacts") = True Then
		NotifyContactInformationRequest();
		SetApplicationParametersMonitoringCenter("RequestForGettingContactsDisplayed", True);
	EndIf;
	If Parameters.MonitoringCenter.Get("DumpsSendingRequest") = True Then
		DumpsInformation = Parameters.MonitoringCenter.Get("DumpsInformation");
		// Check if the message was displayed earlier.
		If DumpsInformation <> ApplicationParametersMonitoringCenter["DumpsInformation"] Then
			NotifyRequestForSendingDumps();
			SetApplicationParametersMonitoringCenter("DumpsInformation", DumpsInformation);
		EndIf;
	EndIf;
        
EndProcedure

#EndRegion

#Region Private

// See details of the same procedure in the common module
// CommonClientOverridable.
//
Procedure OnStart(Parameters) Export
    
    MonitoringCenterApplicationParameters = GetApplicationParameters();
	
	If Not MonitoringCenterApplicationParameters["ClientInformation"]["ClientParameters"]["PromptForFullDump"] = True Then
		Return;
	EndIf;
	
	If MonitoringCenterApplicationParameters["ClientInformation"]["ClientParameters"]["RequestForGettingDumps"] = True Then
		AttachIdleHandler("MonitoringCenterDumpCollectionAndSendingRequest",90, True);
		SetApplicationParametersMonitoringCenter("PromptForFullDumpDisplayed", True);
	EndIf;
	If MonitoringCenterApplicationParameters["ClientInformation"]["ClientParameters"]["SendingRequest"] = True Then
		AttachIdleHandler("MonitoringCenterDumpSendingRequest",90, True);
		DumpsInformation = MonitoringCenterApplicationParameters["ClientInformation"]["ClientParameters"]["DumpsInformation"];
		SetApplicationParametersMonitoringCenter("DumpsInformation", DumpsInformation);
	EndIf;
	If MonitoringCenterApplicationParameters["ClientInformation"]["ClientParameters"]["RequestForGettingContacts"] = True Then
		AttachIdleHandler("MonitoringCenterContactInformationRequest",120, True);
		SetApplicationParametersMonitoringCenter("RequestForGettingContactsDisplayed", True);
	EndIf;
	   
EndProcedure

Function GetApplicationParameters() Export
    
    If ApplicationParameters = Undefined Then
    	ApplicationParameters = New Map;
    EndIf;
    
    ParameterName = "StandardSubsystems.MonitoringCenter";
    If ApplicationParameters[ParameterName] = Undefined Then
        
        ClientParameters = ClientParameters();
        
        ApplicationParameters.Insert(ParameterName, New Map);
        MonitoringCenterApplicationParameters = ApplicationParameters[ParameterName];
        MonitoringCenterApplicationParameters.Insert("RegisterBusinessStatistics", ClientParameters["RegisterBusinessStatistics"]);
		MonitoringCenterApplicationParameters.Insert("PromptForFullDumpDisplayed", ClientParameters["PromptForFullDumpDisplayed"]);
		MonitoringCenterApplicationParameters.Insert("DumpsInformation", ClientParameters["DumpsInformation"]);		
		
        Measurements = New Map;
        Measurements.Insert(0, New Array);
        Measurements.Insert(1, New Map);
        Measurements.Insert(2, New Map);
        MonitoringCenterApplicationParameters.Insert("Measurements", Measurements);
        
        MonitoringCenterApplicationParameters.Insert("ClientInformation", GetClientInformation());
        
    Else
        
        MonitoringCenterApplicationParameters = ApplicationParameters["StandardSubsystems.MonitoringCenter"];
                       
    EndIf;
    
    Return MonitoringCenterApplicationParameters; 
    
EndFunction

Function GetClientInformation()
    
    ClientInformation = New Map;
    
    InformationScreens = New Array;
    ClientScreens = GetClientDisplaysInformation();
    For Each CurScreen In ClientScreens Do
        InformationScreens.Add(ScreenResolutionInString(CurScreen));
    EndDo;
    
    ClientInformation.Insert("CustomerScreens", InformationScreens);
    ClientInformation.Insert("ClientParameters", ClientParameters());
    ClientInformation.Insert("SystemInformation", GetSystemInformation());
    ClientInformation.Insert("ActiveWindows", 0);
    
    Return ClientInformation;
    
EndFunction

Function ScreenResolutionInString(Screen)
    
    Return Format(Screen.Width, "NG=0") + "x" + Format(Screen.Height, "NG=0");
    
EndFunction

Function ClientParameters()
    
    ClientParameters = CommonClientServer.StructureProperty(StandardSubsystemsClient.ClientParametersOnStart(),"MonitoringCenter");
    If ClientParameters = Undefined Then
        ClientParameters = New Structure;
		ClientParameters.Insert("SessionTimeZone", Undefined);
		ClientParameters.Insert("UserHash", Undefined);
		ClientParameters.Insert("RegisterBusinessStatistics", False);
		ClientParameters.Insert("PromptForFullDump", False);
		ClientParameters.Insert("PromptForFullDumpDisplayed", False);
		ClientParameters.Insert("DumpsInformation", "");
		ClientParameters.Insert("RequestForGettingDumps", False);
		ClientParameters.Insert("SendingRequest", False);
		ClientParameters.Insert("RequestForGettingContacts", False);
		ClientParameters.Insert("RequestForGettingContactsDisplayed", False);
    EndIf;
    
    ClientParametersInformation = New Map;
    For Each CurParameter In ClientParameters Do
        ClientParametersInformation.Insert(CurParameter.Key, CurParameter.Value);
    EndDo;
        
    Return ClientParametersInformation; 
        
EndFunction

Function GetSystemInformation()
    
    SysInfo = New SystemInfo();
    
    SysInfoInformation = New Map;
    SysInfoInformation.Insert("OSVersion", StrReplace(SysInfo.OSVersion, ".", "☺"));
    SysInfoInformation.Insert("RAM", Format((Int(SysInfo.RAM/512) + 1) * 512, "NG=0"));
    SysInfoInformation.Insert("Processor", StrReplace(SysInfo.Processor, ".", "☺"));
    SysInfoInformation.Insert("PlatformType", StrReplace(String(SysInfo.PlatformType), ".", "☺"));
        
    UserAgentInformation = "";
    #If ThickClientManagedApplication Then
        UserAgentInformation = "ThickClientManagedApplication";
    #ElsIf ThickClientOrdinaryApplication Then
        UserAgentInformation = "ThickClient";
    #ElsIf ThinClient Then
        UserAgentInformation = "ThinClient";
    #ElsIf WebClient Then                                                          
        UserAgentInformation = "WebClient";
    #EndIf
    
    SysInfoInformation.Insert("UserAgentInformation", UserAgentInformation);
    
    Return SysInfoInformation; 
    
EndFunction

Procedure SetApplicationParametersMonitoringCenter(Parameter, Value)
	ParameterName = "StandardSubsystems.MonitoringCenter";
	If ApplicationParameters[ParameterName] = Undefined Then
		Return;
	Else
		MonitoringCenterApplicationParameters = ApplicationParameters["StandardSubsystems.MonitoringCenter"];
		MonitoringCenterApplicationParameters.Insert(Parameter, Value);
	EndIf;
EndProcedure

Procedure NotifyRequestForReceivingDumps() Export
	ShowUserNotification(NStr("ru = 'Отчеты об ошибках'; en = 'Error reports'; pl = 'Error reports';de = 'Error reports';ro = 'Error reports';tr = 'Error reports'; es_ES = 'Error reports'"),
			"e1cib/app/DataProcessor.MonitoringCenterSettings.Form.RequestForErrorReportsCollectionAndSending",
			NStr("ru = 'Предоставьте отчеты о возникающих ошибках'; en = 'Provide reports on occurred errors'; pl = 'Provide reports on occurred errors';de = 'Provide reports on occurred errors';ro = 'Provide reports on occurred errors';tr = 'Provide reports on occurred errors'; es_ES = 'Provide reports on occurred errors'"),
			PictureLib.Warning32,
			UserNotificationStatus.Important, "RequestForGettingDumps");		
EndProcedure

Procedure NotifyRequestForSendingDumps() Export
	ShowUserNotification(NStr("ru = 'Отчеты об ошибках'; en = 'Error reports'; pl = 'Error reports';de = 'Error reports';ro = 'Error reports';tr = 'Error reports'; es_ES = 'Error reports'"),
				"e1cib/app/DataProcessor.MonitoringCenterSettings.Form.RequestForSendingErrorReports",
				NStr("ru = 'Отправьте отчеты о возникающих ошибках'; en = 'Send reports on occurred errors'; pl = 'Send reports on occurred errors';de = 'Send reports on occurred errors';ro = 'Send reports on occurred errors';tr = 'Send reports on occurred errors'; es_ES = 'Send reports on occurred errors'"),
				PictureLib.Warning32,
				UserNotificationStatus.Important, "DumpsSendingRequest");
EndProcedure

Procedure NotifyContactInformationRequest() Export
	ShowUserNotification(NStr("ru = 'Проблемы производительности'; en = 'Performance issues'; pl = 'Performance issues';de = 'Performance issues';ro = 'Performance issues';tr = 'Performance issues'; es_ES = 'Performance issues'"),
				New NotifyDescription(
						"OnClickNotifyContactInformationRequest",
						ThisObject, True),
				NStr("ru = 'Сообщить о проблемах производительности'; en = 'Inform of performance issues'; pl = 'Inform of performance issues';de = 'Inform of performance issues';ro = 'Inform of performance issues';tr = 'Inform of performance issues'; es_ES = 'Inform of performance issues'"),
				PictureLib.Warning32,
				UserNotificationStatus.Important, "ContactInformationRequest");
EndProcedure
			
Procedure OnClickNotifyContactInformationRequest(OnRequest) Export
	
	FormParameters = New Structure;
	FormParameters.Insert("OnRequest", OnRequest);
	OpenForm("DataProcessor.MonitoringCenterSettings.Form.SendContactInformation", FormParameters);
	
EndProcedure			
			

#EndRegion