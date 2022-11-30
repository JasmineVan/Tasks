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
	
	Correspondent = CommandParameter;
	SettingID = "";
	
	If DataExchangeWithExternalSystem(Correspondent, SettingID) Then
		If CommonClient.SubsystemExists("OnlineUserSupport.DataExchangeWithExternalSystems") Then
			
			Context = New Structure;
			Context.Insert("SettingID", SettingID);
			Context.Insert("Correspondent", Correspondent);
			Context.Insert("Mode", "EditConnectionParameters");
			
			Cancel = False;
			WizardFormName  = "";
			WizardParameters = New Structure;
			
			ModuleDataExchangeWithExternalSystemsClient = CommonClient.CommonModule("DataExchangeWithExternalSystemsClient");
			ModuleDataExchangeWithExternalSystemsClient.BeforeConnectionParametersSetting(
				Context, Cancel, WizardFormName, WizardParameters);
			
			If Not Cancel Then
				OpenForm(WizardFormName,
					WizardParameters, ThisObject, , , , , FormWindowOpeningMode.LockOwnerWindow);
			EndIf;
		EndIf;
		Return;
	EndIf;
	
	Filter              = New Structure("Correspondent", Correspondent);
	FillingValues = New Structure("Correspondent", Correspondent);
	
	DataExchangeClient.OpenInformationRegisterWriteFormByFilter(Filter,
		FillingValues, "DataExchangeTransportSettings", CommandExecuteParameters.Source);
	
EndProcedure

&AtServer
Function DataExchangeWithExternalSystem(Correspondent, SettingID = "")
	
	TransportKind = InformationRegisters.DataExchangeTransportSettings.DefaultExchangeMessagesTransportKind(Correspondent);
	
	SettingID = DataExchangeServer.SavedExchangePlanNodeSettingOption(Correspondent);
	
	Return TransportKind = Enums.ExchangeMessagesTransportTypes.ExternalSystem;
	
EndFunction

#EndRegion
