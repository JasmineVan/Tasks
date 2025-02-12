﻿///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Private

// Returns the WSProxy object reference for the specified exchange node.
//
// Parameters:
//   Endpoint - ExchangePlanRef.
//
Function WSEndpointProxy(Endpoint, Timeout) Export
	
	SettingsStructure = InformationRegisters.MessageExchangeTransportSettings.TransportSettingsWS(Endpoint);
	
	ErrorMessageString = "";
	
	Result = MessageExchangeInternal.GetWSProxy(SettingsStructure, ErrorMessageString, Timeout);
	
	If Result = Undefined Then
		Raise ErrorMessageString;
	EndIf;
	
	Return Result;
EndFunction

// Returns the manager array of the catalogs which can be used for massage keeping.
// 
//
Function GetMessageCatalogs() Export
	
	CatalogArray = New Array();
	
	If SaaSCached.IsSeparatedConfiguration() Then
		ModuleMessagesSaaSDataSeparation = Common.CommonModule("MessagesSaaSDataSeparation");
		ModuleMessagesSaaSDataSeparation.OnFillMessageCatalogs(CatalogArray);
	EndIf;
	
	CatalogArray.Add(Catalogs.SystemMessages);
	
	Return New FixedArray(CatalogArray);
	
EndFunction

#EndRegion
