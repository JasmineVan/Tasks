///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Private

Function DeliveryStatus(MessageID) Export
	
	SendSMSMessage.CheckRights();
	
	If IsBlankString(MessageID) Then
		Return "Pending";
	EndIf;
	
	Result = Undefined;
	SetPrivilegedMode(True);
	SMSMessageSendingSettings = SendSMSMessage.SMSMessageSendingSettings();
	SetPrivilegedMode(False);
	
	ModuleSMSMessageSendingViaProvider = SendSMSMessage.ModuleSMSMessageSendingViaProvider(SMSMessageSendingSettings.Provider);
	If ModuleSMSMessageSendingViaProvider <> Undefined Then
		Result = ModuleSMSMessageSendingViaProvider.DeliveryStatus(MessageID, SMSMessageSendingSettings);
	ElsIf ValueIsFilled(SMSMessageSendingSettings.Provider) Then
		SMSOverridable.DeliveryStatus(MessageID, SMSMessageSendingSettings.Provider,
			SMSMessageSendingSettings.Username, SMSMessageSendingSettings.Password, Result);
	Else // provider is not selected
		Result = "Error";
	EndIf;
	
	Return Result;
	
EndFunction

#EndRegion