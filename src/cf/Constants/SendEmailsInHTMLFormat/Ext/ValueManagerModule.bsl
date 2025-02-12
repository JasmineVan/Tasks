﻿///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure OnWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	If Value Then
		Return;
	EndIf;
	
	BeginTransaction();
	
	Try
		
		Lock = New DataLock;
		Lock.Add("InformationRegister.EmailAccountSettings");
		Lock.Lock();
		
		// Switching signatures of all email accounts to plain text.
		AccountsSettings = InformationRegisters.EmailAccountSettings.CreateRecordSet();
		AccountsSettings.Read();
		For each Setting In AccountsSettings Do
			Setting.NewMessageSignatureFormat = Enums.EmailEditingMethods.NormalText;
			Setting.ReplyForwardSignatureFormat = Enums.EmailEditingMethods.NormalText;
		EndDo;
		If AccountsSettings.Modified() Then
			AccountsSettings.Write();
		EndIf;
		
		CommitTransaction();
		
	Except
		
		RollbackTransaction();
		Raise;
		
	EndTry;
	
EndProcedure

#EndRegion

#Else
Raise NStr("ru = 'Недопустимый вызов объекта на клиенте.'; en = 'Invalid object call on the client.'; pl = 'Invalid object call on the client.';de = 'Invalid object call on the client.';ro = 'Invalid object call on the client.';tr = 'Invalid object call on the client.'; es_ES = 'Invalid object call on the client.'");
#EndIf