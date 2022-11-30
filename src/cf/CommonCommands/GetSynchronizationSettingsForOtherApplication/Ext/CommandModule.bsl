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
	
	Cancel = False;
	
	TempStorageAddress = "";
	
	GetSecondInfobaseDataExchangeSettingsAtServer(Cancel, TempStorageAddress, CommandParameter);
	
	If Cancel Then
		
		ShowMessageBox(, NStr("ru = 'Возникли ошибки при получении настроек обмена данными.'; en = 'Cannot get data exchange settings.'; pl = 'Podczas pobierania ustawień wymiany danych zaistniały błędy.';de = 'Beim Empfangen der Kommunikationseinstellungen sind Fehler aufgetreten.';ro = 'Erori la primirea setărilor schimbului de date.';tr = 'Veri alışverişi ayarları alınırken hatalar oluştu.'; es_ES = 'Se han producido errores al recibir los ajustes de intercambio de datos.'"));
		
	Else
		
		GetFile(TempStorageAddress, NStr("ru = 'Настройки синхронизации данных.xml'; en = 'Synchronization settings.xml'; pl = 'Ustawienia synchronizacji danych.xml';de = 'Datensynchronisationseinstellungen.xml';ro = 'Setările de sincronizare a datelor.xml';tr = 'Veri senkronizasyonu ayarları.xml'; es_ES = 'Ajustes de sincronización de datos.xml'"), True);
		
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure GetSecondInfobaseDataExchangeSettingsAtServer(Cancel, TempStorageAddress, InfobaseNode)
	
	DataExchangeCreationWizard = DataExchangeServer.ModuleDataExchangeCreationWizard().Create();
	DataExchangeCreationWizard.Initializing(InfobaseNode);
	DataExchangeCreationWizard.ExportWizardParametersToTempStorage(Cancel, TempStorageAddress);
	
EndProcedure

#EndRegion
