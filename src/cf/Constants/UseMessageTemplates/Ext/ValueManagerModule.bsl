///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure BeforeWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	If Value Then
		CanSendSMSMessage = Common.SubsystemExists("StandardSubsystems.SendSMSMessage");
		EmailOperationsAvailable = Common.SubsystemExists("StandardSubsystems.EmailOperations");
	Else
		CanSendSMSMessage = False;
		EmailOperationsAvailable = False;
	EndIf;
	
	Constants.UseSMSMessagesSendingInMessagesTemplates.Set(CanSendSMSMessage);
	Constants.UseEmailInMessagesTemplates.Set(EmailOperationsAvailable);
EndProcedure

#EndRegion

#Else
Raise NStr("ru = 'Недопустимый вызов объекта на клиенте.'; en = 'Invalid object call on the client.'; pl = 'Invalid object call on the client.';de = 'Invalid object call on the client.';ro = 'Invalid object call on the client.';tr = 'Invalid object call on the client.'; es_ES = 'Invalid object call on the client.'");
#EndIf