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
	
	ExchangeNode = Parameters.ExchangeNode;
	
	CorrespondentDescription = Common.ObjectAttributeValue(ExchangeNode, "Description");
	
	Items.WaitLabelDecoration.Title = StrReplace(Items.WaitLabelDecoration.Title,
		"%CorrespondentDescription%", CorrespondentDescription);
	Items.ErrorLabelDecoration.Title = StrReplace(Items.ErrorLabelDecoration.Title,
		"%CorrespondentDescription%", CorrespondentDescription);
	
	Title = NStr("ru = 'Загрузка параметров обмена данными'; en = 'Import data exchange parameters'; pl = 'Pobieranie parametrów wymiany danych';de = 'Laden von Datenaustauschoptionen';ro = 'Încărcarea parametrilor schimbului de date';tr = 'Veri alışverişi parametrelerin içe aktarılması'; es_ES = 'Carga de parámetros de intercambio de datos'");
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	Items.MainPanel.CurrentPage = Items.TimeConsumingOperationPage;
	Items.DoneCommandForm.DefaultButton = False;
	Items.DoneCommandForm.Enabled = False;
	
	AttachIdleHandler("OnStartImportXDTOSettings", 1, True);
	
EndProcedure

#EndRegion

#Region FormCommandHandlers

&AtClient
Procedure DoneCommand(Command)
	
	Result = New Structure;
	Result.Insert("ContinueSetup",            False);
	Result.Insert("DataReceivedForMapping", False);
	
	Close(Result);
	
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure OnStartImportXDTOSettings()
	
	ContinueWait = True;
	OnStartImportXDTOSettingsAtServer(ContinueWait);
	
	If ContinueWait Then
		DataExchangeClient.InitializeIdleHandlerParameters(
			IdleHandlerParameters);
			
		AttachIdleHandler("OnWaitForImportXDTOSettings",
			IdleHandlerParameters.CurrentInterval, True);
	Else
		OnCompleteXDTOSettingsImport();
	EndIf;
	
EndProcedure

&AtClient
Procedure OnWaitForImportXDTOSettings()
	
	ContinueWait = False;
	OnWaitImportXDTOSettingsAtServer(HandlerParameters, ContinueWait);
	
	If ContinueWait Then
		DataExchangeClient.UpdateIdleHandlerParameters(IdleHandlerParameters);
		
		AttachIdleHandler("OnWaitForImportXDTOSettings",
			IdleHandlerParameters.CurrentInterval, True);
	Else
		IdleHandlerParameters = Undefined;
		OnCompleteXDTOSettingsImport();
	EndIf;
	
EndProcedure

&AtClient
Procedure OnCompleteXDTOSettingsImport()
	
	ErrorMessage = "";
	SettingsImported = False;
	DataReceivedForMapping = False;
	OnCompleteImportXDTOSettingsAtServer(HandlerParameters, SettingsImported, DataReceivedForMapping, ErrorMessage);
	
	If SettingsImported Then
		
		Result = New Structure;
		Result.Insert("ContinueSetup",            True);
		Result.Insert("DataReceivedForMapping", DataReceivedForMapping);
		
		Close(Result);
	Else
		Items.MainPanel.CurrentPage = Items.ErrorPage;
		Items.DoneCommandForm.DefaultButton = True;
		Items.DoneCommandForm.Enabled = True;
	EndIf;
	
EndProcedure

&AtServer
Procedure OnStartImportXDTOSettingsAtServer(ContinueWait)
	
	ModuleSetupWizard = DataExchangeServer.ModuleDataExchangeCreationWizard();
	
	ImportSettings = New Structure;
	ImportSettings.Insert("ExchangeNode", ExchangeNode);
	
	ModuleSetupWizard.OnStartImportXDTOSettings(ImportSettings, HandlerParameters, ContinueWait);
	
EndProcedure
	
&AtServerNoContext
Procedure OnWaitImportXDTOSettingsAtServer(HandlerParameters, ContinueWait)
	
	ModuleSetupWizard = DataExchangeServer.ModuleDataExchangeCreationWizard();
	
	ContinueWait = False;
	ModuleSetupWizard.OnWaitForImportXDTOSettings(HandlerParameters, ContinueWait);
	
EndProcedure

&AtServerNoContext
Procedure OnCompleteImportXDTOSettingsAtServer(HandlerParameters, SettingsImported, DataReceivedForMapping, ErrorMessage)
	
	ModuleSetupWizard = DataExchangeServer.ModuleDataExchangeCreationWizard();
	
	CompletionStatus = Undefined;
	ModuleSetupWizard.OnCompleteImportXDTOSettings(HandlerParameters, CompletionStatus);
		
	If CompletionStatus.Cancel Then
		SettingsImported = False;
		DataReceivedForMapping = False;
		ErrorMessage = CompletionStatus.ErrorMessage;
	Else
		SettingsImported = CompletionStatus.Result.SettingsImported;
			
		If Not SettingsImported Then
			DataReceivedForMapping = False;
			ErrorMessage = CompletionStatus.Result.ErrorMessage;
		Else
			DataReceivedForMapping = CompletionStatus.Result.DataReceivedForMapping;
		EndIf;
	EndIf;
	
EndProcedure 

#EndRegion
