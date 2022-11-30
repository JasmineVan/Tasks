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
	
	// server call
	ExchangePlanName = ExchangePlanName(CommandParameter);
	
	// server call
	RulesKind = PredefinedValue("Enum.DataExchangeRulesTypes.ObjectConversionRules");
	
	Filter              = New Structure("ExchangePlanName, RulesKind", ExchangePlanName, RulesKind);
	FillingValues = New Structure("ExchangePlanName, RulesKind", ExchangePlanName, RulesKind);
	
	DataExchangeClient.OpenInformationRegisterWriteFormByFilter(Filter, FillingValues, "DataExchangeRules", CommandExecuteParameters.Source, "ObjectConversionRules");
	
EndProcedure

&AtServer
Function ExchangePlanName(Val InfobaseNode)
	
	Return DataExchangeCached.GetExchangePlanName(InfobaseNode);
	
EndFunction

#EndRegion
