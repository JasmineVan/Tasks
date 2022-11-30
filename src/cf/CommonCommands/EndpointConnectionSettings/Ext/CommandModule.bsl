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
	
	WriteParameters = New Structure;
	WriteParameters.Insert("Key", RegisterRecordKey(CommandParameter));
	WriteParameters.Insert("FillingValues", New Structure("Endpoint", CommandParameter));
	
	OpenForm("InformationRegister.MessageExchangeTransportSettings.RecordForm",
		WriteParameters, CommandExecuteParameters.Source);
	
EndProcedure
	
#EndRegion

#Region Private

&AtServer
Function RegisterRecordKey(Endpoint)
	
	Return InformationRegisters.MessageExchangeTransportSettings.CreateRecordKey(
		New Structure("Endpoint", Endpoint));
	
EndFunction

#EndRegion
