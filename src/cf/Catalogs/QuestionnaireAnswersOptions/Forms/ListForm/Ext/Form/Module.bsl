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
	
	If NOT Users.IsExternalUserSession() Then
		Common.MessageToUser(
			NStr("ru = 'Варианты ответов анкет используются только внешними пользователями.'; en = 'Questionnaire response options are used only by external users.'; pl = 'Questionnaire response options are used only by external users.';de = 'Questionnaire response options are used only by external users.';ro = 'Questionnaire response options are used only by external users.';tr = 'Questionnaire response options are used only by external users.'; es_ES = 'Questionnaire response options are used only by external users.'"),,,,Cancel);
	EndIf;
	
EndProcedure

#EndRegion
