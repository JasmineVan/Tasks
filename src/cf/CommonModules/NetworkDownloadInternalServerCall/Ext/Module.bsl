///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Private

#Region DownloadFileAtClient

Function DownloadFile(URL, ReceivingParameters, WriteError) Export
	
	SavingSetting = New Map;
	SavingSetting.Insert("StorageLocation", "TemporaryStorage");
	
	Return GetFilesFromInternetInternal.DownloadFile(
		URL, ReceivingParameters, SavingSetting, WriteError);
	
EndFunction

#EndRegion

#Region ObsoleteProceduresAndFunctions

Function ProxySettingsState() Export
	
	Return GetFilesFromInternetInternal.ProxySettingsState();
	
EndFunction

#EndRegion

#EndRegion
