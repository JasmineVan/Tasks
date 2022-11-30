///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Internal

Function Locked() Export
	
	SetPrivilegedMode(True);
	RegistrationData = Common.ReadDataFromSecureStorage(
		"CollaborationSystemInfoBaseRegistrationData");
	Locked = RegistrationData <> Undefined;
	Return Locked;
	
EndFunction

Procedure Lock() Export 
	
	If Not AccessRight("DataAdministration", Metadata) Then 
		Raise 
			NStr("ru = 'Обсуждения не заблокированы. Для выполнения операции требуется право администрирования данных.'; en = 'Discussions are not locked. To perform an action, you need permissions to administer data.'; pl = 'Discussions are not locked. To perform an action, you need permissions to administer data.';de = 'Discussions are not locked. To perform an action, you need permissions to administer data.';ro = 'Discussions are not locked. To perform an action, you need permissions to administer data.';tr = 'Discussions are not locked. To perform an action, you need permissions to administer data.'; es_ES = 'Discussions are not locked. To perform an action, you need permissions to administer data.'");
	EndIf;
	
	If Locked() Then 
		Return;
	EndIf;
	
	SetPrivilegedMode(True);
	RegistrationData = CollaborationSystem.GetInfoBaseRegistrationData();
	If TypeOf(RegistrationData) = Type("CollaborationSystemInfoBaseRegistrationData") Then
		Common.WriteDataToSecureStorage(
			"CollaborationSystemInfoBaseRegistrationData", 
			RegistrationData);
	EndIf;
	CollaborationSystem.SetInfoBaseRegistrationData(Undefined);
	
EndProcedure

Procedure Unlock() Export 
	
	If Not AccessRight("DataAdministration", Metadata) Then 
		Raise 
			NStr("ru = 'Обсуждения не заблокированы. Для выполнения операции требуется право администрирования данных.'; en = 'Discussions are not locked. To perform an action, you need permissions to administer data.'; pl = 'Discussions are not locked. To perform an action, you need permissions to administer data.';de = 'Discussions are not locked. To perform an action, you need permissions to administer data.';ro = 'Discussions are not locked. To perform an action, you need permissions to administer data.';tr = 'Discussions are not locked. To perform an action, you need permissions to administer data.'; es_ES = 'Discussions are not locked. To perform an action, you need permissions to administer data.'");
	EndIf;
	
	SetPrivilegedMode(True);
	RegistrationData = Common.ReadDataFromSecureStorage(
		"CollaborationSystemInfoBaseRegistrationData");
	Common.DeleteDataFromSecureStorage("CollaborationSystemInfoBaseRegistrationData");
	If TypeOf(RegistrationData) = Type("CollaborationSystemInfoBaseRegistrationData") Then 
		CollaborationSystem.SetInfoBaseRegistrationData(RegistrationData);
	EndIf;
	RegistrationData = Undefined;
	
EndProcedure

Procedure OnCreateAtUserServer(Cancel, Form, Object) Export
	
	If Not AccessRight("DataAdministration", Metadata) Then
		Form.SuggestDiscussions = False;
		Return;
	EndIf;
	
	SuggestDiscussions = Common.CommonSettingsStorageLoad("ApplicationSettings", "SuggestDiscussions", True);
	Form.SuggestDiscussions = Not Cancel AND Not ValueIsFilled(Object.Ref) AND SuggestDiscussions 
		AND Not ConversationsServiceServerCall.Connected();
	If Not Form.SuggestDiscussions Then
		Return;
	EndIf;
	
	AdministrationSubsystem = Metadata.Subsystems.Find("Administration");
	If AdministrationSubsystem <> Undefined Then 
		EnableLater = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Включить обсуждения также можно позднее из раздела %1.'; en = 'You can also enable discussions later from the %1 section.'; pl = 'You can also enable discussions later from the %1 section.';de = 'You can also enable discussions later from the %1 section.';ro = 'You can also enable discussions later from the %1 section.';tr = 'You can also enable discussions later from the %1 section.'; es_ES = 'You can also enable discussions later from the %1 section.'"),
			AdministrationSubsystem.Synonym);
	Else
		EnableLater = NStr("ru = 'Включить обсуждения также можно позднее из настроек программы.'; en = 'You can also enable discussions later from the program settings.'; pl = 'You can also enable discussions later from the program settings.';de = 'You can also enable discussions later from the program settings.';ro = 'You can also enable discussions later from the program settings.';tr = 'You can also enable discussions later from the program settings.'; es_ES = 'You can also enable discussions later from the program settings.'");
	EndIf;
	
	Form.SuggestConversationsText = 
		NStr("ru = 'Включить обсуждения?
			       |
			       |С их помощью пользователи смогут отправлять друг другу текстовые сообщения и совершать видеозвонки, создавать тематические обсуждения и вести переписку по документам.'; 
			       |en = 'Enable discussions?
			       |
			       |They allow users to send text messages and make video calls, create themed discussions and keep correspondence on documents.'; 
			       |pl = 'Enable discussions?
			       |
			       |They allow users to send text messages and make video calls, create themed discussions and keep correspondence on documents.';
			       |de = 'Enable discussions?
			       |
			       |They allow users to send text messages and make video calls, create themed discussions and keep correspondence on documents.';
			       |ro = 'Enable discussions?
			       |
			       |They allow users to send text messages and make video calls, create themed discussions and keep correspondence on documents.';
			       |tr = 'Enable discussions?
			       |
			       |They allow users to send text messages and make video calls, create themed discussions and keep correspondence on documents.'; 
			       |es_ES = 'Enable discussions?
			       |
			       |They allow users to send text messages and make video calls, create themed discussions and keep correspondence on documents.'")
			+ Chars.LF + Chars.LF + EnableLater;
	
EndProcedure

#EndRegion