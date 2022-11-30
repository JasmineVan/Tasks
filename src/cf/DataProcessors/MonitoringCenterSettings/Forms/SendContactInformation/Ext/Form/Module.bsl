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
	MonitoringCenterParameters = New Structure("ContactInformation, ContactInformationComment");
	MonitoringCenterParameters = MonitoringCenterInternal.GetMonitoringCenterParameters(MonitoringCenterParameters);
	Contacts = MonitoringCenterParameters.ContactInformation;
	Comment = MonitoringCenterParameters.ContactInformationComment;
	If Common.SubsystemExists("OnlineUserSupport") Then
		ModuleOnlineUserSupport = Common.CommonModule("OnlineUserSupport");
		AuthenticationData = ModuleOnlineUserSupport.OnlineSupportUserAuthenticationData();
		If AuthenticationData <> Undefined Then
			Username = AuthenticationData.Username;
		EndIf;
	EndIf;
	If Parameters.Property("OnRequest") Then
		OnRequest = True;
		Items.Title.Title = NStr("ru = 'Ранее Вы подписались на отправку анонимных обезличенных отчетов об использовании программы. В результате анализа предоставленных отчетов выявлены проблемы производительности. Если Вы готовы предоставить фирме ""1С"" копию Вашей информационной базы (может быть обезличена) для расследования проблем производительности, пожалуйста, укажите свои контактные данные, чтобы сотрудники фирмы ""1С"" могли с Вами связаться.
                                             |Если Вы откажетесь, никакие идентификационные данные не будут отправлены.'; 
                                             |en = 'Earlier you signed up to send anonymous depersonalized reports about the application usage. The analysis of the submitted reports revealed performance issues. If you are ready to submit a copy of your infobase (can be depersonalized) to 1C Company to get your performance issues looked into, please specify your contact details so that 1C Company employees can contact you.
                                             |If you refuse, no identification data will be sent.'; 
                                             |pl = 'Earlier you signed up to send anonymous depersonalized reports about the application usage. The analysis of the submitted reports revealed performance issues. If you are ready to submit a copy of your infobase (can be depersonalized) to 1C Company to get your performance issues looked into, please specify your contact details so that 1C Company employees can contact you.
                                             |If you refuse, no identification data will be sent.';
                                             |de = 'Earlier you signed up to send anonymous depersonalized reports about the application usage. The analysis of the submitted reports revealed performance issues. If you are ready to submit a copy of your infobase (can be depersonalized) to 1C Company to get your performance issues looked into, please specify your contact details so that 1C Company employees can contact you.
                                             |If you refuse, no identification data will be sent.';
                                             |ro = 'Earlier you signed up to send anonymous depersonalized reports about the application usage. The analysis of the submitted reports revealed performance issues. If you are ready to submit a copy of your infobase (can be depersonalized) to 1C Company to get your performance issues looked into, please specify your contact details so that 1C Company employees can contact you.
                                             |If you refuse, no identification data will be sent.';
                                             |tr = 'Earlier you signed up to send anonymous depersonalized reports about the application usage. The analysis of the submitted reports revealed performance issues. If you are ready to submit a copy of your infobase (can be depersonalized) to 1C Company to get your performance issues looked into, please specify your contact details so that 1C Company employees can contact you.
                                             |If you refuse, no identification data will be sent.'; 
                                             |es_ES = 'Earlier you signed up to send anonymous depersonalized reports about the application usage. The analysis of the submitted reports revealed performance issues. If you are ready to submit a copy of your infobase (can be depersonalized) to 1C Company to get your performance issues looked into, please specify your contact details so that 1C Company employees can contact you.
                                             |If you refuse, no identification data will be sent.'");
		Items.FormSend.Title = NStr("ru = 'Отправить контактную информацию'; en = 'Send contact information'; pl = 'Send contact information';de = 'Send contact information';ro = 'Send contact information';tr = 'Send contact information'; es_ES = 'Send contact information'");
	Else
		Items.Comment.InputHint = NStr("ru = 'Опишите проблему'; en = 'Describe your issue'; pl = 'Describe your issue';de = 'Describe your issue';ro = 'Describe your issue';tr = 'Describe your issue'; es_ES = 'Describe your issue'");
		Items.FormRefuse.Visible = False;
		Items.Contacts.AutoMarkIncomplete = True;
		Items.Comment.AutoMarkIncomplete = True;
	EndIf;
	ResetWindowLocationAndSize();    	
EndProcedure

#EndRegion


#Region FormCommandHandlers

&AtClient
Procedure Send(Command) 
	If Not FilledCorrectly() Then
		Return;
	EndIf;
	NewParameters = New Structure;
	NewParameters.Insert("ContactInformationRequest", 1);
	NewParameters.Insert("ContactInformationChanged", True);
	NewParameters.Insert("ContactInformation", Contacts);
	NewParameters.Insert("ContactInformationComment", Comment);
	NewParameters.Insert("PortalUsername", Username);
	SetMonitoringCenterParameters(NewParameters);
	Close();
EndProcedure

&AtClient
Procedure Cancel(Command)
	NewParameters = New Structure;
	NewParameters.Insert("ContactInformationRequest", 0);
	NewParameters.Insert("ContactInformationChanged", True);
	NewParameters.Insert("ContactInformation", "");
	NewParameters.Insert("ContactInformationComment", Comment);
	SetMonitoringCenterParameters(NewParameters);
	Close();
EndProcedure

#EndRegion

#Region Private

&AtClient
Function FilledCorrectly()
	CheckResult = True;
	If OnRequest Then
		If IsBlankString(Contacts)Then
			CommonClient.MessageToUser(NStr("ru = 'Не указана контактная информация.'; en = 'Contact information is not specified.'; pl = 'Contact information is not specified.';de = 'Contact information is not specified.';ro = 'Contact information is not specified.';tr = 'Contact information is not specified.'; es_ES = 'Contact information is not specified.'"),,"Contacts");
			CheckResult = False;
		EndIf; 
	Else 
		If IsBlankString(Contacts)Then
			CommonClient.MessageToUser(NStr("ru = 'Не указана контактная информация.'; en = 'Contact information is not specified.'; pl = 'Contact information is not specified.';de = 'Contact information is not specified.';ro = 'Contact information is not specified.';tr = 'Contact information is not specified.'; es_ES = 'Contact information is not specified.'"),,"Contacts");
			CheckResult = False;
		EndIf; 
		If IsBlankString(Comment)Then
			CommonClient.MessageToUser(NStr("ru = 'Не заполнен комментарий.'; en = 'Comment is not filled in.'; pl = 'Comment is not filled in.';de = 'Comment is not filled in.';ro = 'Comment is not filled in.';tr = 'Comment is not filled in.'; es_ES = 'Comment is not filled in.'"),,"Comment");
			CheckResult = False;
		EndIf; 
	EndIf;                	
	Return CheckResult;		
EndFunction

&AtServer
Procedure ResetWindowLocationAndSize()
	WindowOptionsKey = ?(OnRequest, "OnRequest", "Independent");
EndProcedure

&AtServerNoContext
Procedure SetMonitoringCenterParameters(NewParameters)
	MonitoringCenterInternal.SetMonitoringCenterParametersExternalCall(NewParameters);
EndProcedure

#EndRegion