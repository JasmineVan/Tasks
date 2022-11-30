///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

#Region ForCallsFromOtherSubsystems

// StandardSubsystems.DataExchange

// Fills in the settings that influence the exchange plan usage.
// 
// Parameters:
//  Settings - Structure - default exchange plan settings, see DataExchangeServer. 
//                          DefaultExchangePlanSettings, details of the function return value.
//
Procedure OnGetSettings(Settings) Export
	
	Settings.Algorithms.OnGetSettingOptionDetails = True;
	
EndProcedure

// Fills in a set of parameters that define an exchange setting option.
// 
// Parameters:
//  OptionDetails - Structure - a default setting option set, see DataExchangeServer.
//                                       DefaultExchangeSettingOptionDetails, details of the return  
//                                       value.
//  SettingID - String - an ID of data exchange setting option.
//  ContextParameters - Structure - see DataExchangeServer. 
//                                       ContextParametersOfSettingOptionDetailsReceipt, details of the function return value.
//
Procedure OnGetSettingOptionDetails(OptionDetails, SettingID, ContextParameters) Export
	
	OptionDetails.UseDataExchangeCreationWizard = False;
	
	UsedExchangeMessagesTransports = New Array;
	UsedExchangeMessagesTransports.Add(Enums.ExchangeMessagesTransportTypes.WS);
	
	OptionDetails.UsedExchangeMessagesTransports = UsedExchangeMessagesTransports;
	
EndProcedure

// End StandardSubsystems.DataExchange

// StandardSubsystems.BatchObjectsModification

// Returns the object attributes that are not recommended to be edited using batch attribute 
// modification data processor.
//
// Returns:
//  Array - a list of object attribute names.
Function AttributesToSkipInBatchProcessing() Export
	
	Result = New Array;
	Result.Add("*");
	Return Result;
	
EndFunction

// End StandardSubsystems.BatchObjectsModification

#EndRegion

#EndRegion

#EndIf