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
	
	RecordManager = InformationRegisters.XDTODataExchangeSettings.CreateRecordManager();
	FillPropertyValues(RecordManager, Record.SourceRecordKey);
	RecordManager.Read();
	
	SettingsSupportedObjects = InformationRegisters.XDTODataExchangeSettings.SettingValue(
		RecordManager.InfobaseNode, "SupportedObjects");
		
	If Not SettingsSupportedObjects = Undefined Then
		SupportedObjects.Load(SettingsSupportedObjects);
	EndIf;
	
	CorrespondentSettingsSupportedObjects = InformationRegisters.XDTODataExchangeSettings.CorrespondentSettingValue(
		RecordManager.InfobaseNode, "SupportedObjects");
	
	If Not CorrespondentSettingsSupportedObjects = Undefined Then
		SupportedCorrespondentObjects.Load(CorrespondentSettingsSupportedObjects);
	EndIf;
	
EndProcedure

#EndRegion
