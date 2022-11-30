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
	
	NewConversation = NewConversation(CommandParameter);
	
	If NewConversation = "Unavailable" Then
		Return;
	ElsIf NewConversation = "NotActivated" Then
		SuggestConversationsText = 
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
				|They allow users to send text messages and make video calls, create themed discussions and keep correspondence on documents.'");
		CompletionNotification = New NotifyDescription("SuggestDiscussionsCompletion", ThisObject);
		ShowQueryBox(CompletionNotification, SuggestConversationsText, QuestionDialogMode.YesNo);
		Return;
	EndIf;
	
	FileSystemClient.OpenURL(NewConversation);
	
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure SuggestDiscussionsCompletion(QuestionResult, AdditionalParameters) Export
	
	If QuestionResult <> DialogReturnCode.Yes Then
		Return;
	EndIf;
	
	ConversationsServiceClient.ShowConnection();
	
EndProcedure

&AtServer
Function NewConversation(UserRef)
	
	If Not ConversationsServiceServerCall.Connected() Then
		Return "NotActivated";
	EndIf;
	
	SetPrivilegedMode(True);
	InfobaseUserID = Common.ObjectAttributeValue(UserRef, "IBUserID");
	SetPrivilegedMode(False);
	
	If Not ValueIsFilled(InfobaseUserID) Then
		Return "Unavailable";
	EndIf;
	
	Try
		CollaborationSystemUserID = CollaborationSystem.GetUserID(
			InfobaseUserID);
	Except
		Raise StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Для начала обсуждения необходимо, чтобы пользователь %1
			           |хотя бы один раз запустил программу.'; 
			           |en = 'To start the discussion, the user %1
			           |must run the program at least once.'; 
			           |pl = 'To start the discussion, the user %1
			           |must run the program at least once.';
			           |de = 'To start the discussion, the user %1
			           |must run the program at least once.';
			           |ro = 'To start the discussion, the user %1
			           |must run the program at least once.';
			           |tr = 'To start the discussion, the user %1
			           |must run the program at least once.'; 
			           |es_ES = 'To start the discussion, the user %1
			           |must run the program at least once.'"),
			UserRef);
	EndTry;
	
	If CollaborationSystemUserID = CollaborationSystem.CurrentUserID() Then 
		Raise NStr("ru = 'Для начала обсуждения выберите другого пользователя.'; en = 'Select another user to start the discussion.'; pl = 'Select another user to start the discussion.';de = 'Select another user to start the discussion.';ro = 'Select another user to start the discussion.';tr = 'Select another user to start the discussion.'; es_ES = 'Select another user to start the discussion.'");
	EndIf;
	
	Conversation = CollaborationSystem.CreateConversation();
	If GroupConversationSupported() Then 
		Conversation.Group = False;
	Else 
		Conversation.Title = NStr("ru='Обсуждение'; en = 'Conversation'; pl = 'Conversation';de = 'Conversation';ro = 'Conversation';tr = 'Conversation'; es_ES = 'Conversation'");
	EndIf;
	Conversation.Members.Add(CollaborationSystem.CurrentUserID());
	Conversation.Members.Add(CollaborationSystemUserID);
	Conversation.Write();
	
	Return GetURL(Conversation.ID);
	
EndFunction

&AtServer
Function GroupConversationSupported()
	
	SystemInformation = New SystemInfo;
	CurrentPlatformVersion = SystemInformation.AppVersion;
	RequiredPlatformVersion = "8.3.13.0";
	
	Return CommonClientServer.CompareVersions(RequiredPlatformVersion, CurrentPlatformVersion) <= 0;
	
EndFunction

#EndRegion
