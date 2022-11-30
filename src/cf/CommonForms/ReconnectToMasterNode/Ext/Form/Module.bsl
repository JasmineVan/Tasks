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
	
	MasterNode = Constants.MasterNode.Get();
	
	If Not ValueIsFilled(MasterNode) Then
		Raise NStr("ru = 'Главный узел не сохранен.'; en = 'The master node is not saved.'; pl = 'Główny węzeł nie został zapisany.';de = 'Hauptknoten wird nicht gespeichert.';ro = 'Nodul principal nu este salvat.';tr = 'Ana ünite kaydedilmedi.'; es_ES = 'Nodo principal no se ha guardado.'");
	EndIf;
	
	If ExchangePlans.MasterNode() <> Undefined Then
		Raise NStr("ru = 'Главный узел установлен.'; en = 'The master node is set.'; pl = 'Główny węzeł jest ustawiony.';de = 'Hauptknoten ist gesetzt.';ro = 'Nodul principal este setat.';tr = 'Ana ünite belirlendi.'; es_ES = 'Nodo principal está establecido.'");
	EndIf;
	
	Items.WarningText.Title = StringFunctionsClientServer.SubstituteParametersToString(
		Items.WarningText.Title, String(MasterNode));
	
EndProcedure

#EndRegion

#Region FormCommandHandlers

&AtClient
Procedure Reconnect(Command)
	
	ReconnectAtServer();
	
	Close(New Structure("Cancel", False));
	
EndProcedure

&AtClient
Procedure Disable(Command)
	
	DisconnectAtServer();
	
	Close(New Structure("Cancel", False));
	
EndProcedure

&AtClient
Procedure ExitApplication(Command)
	
	Close(New Structure("Cancel", True));
	
EndProcedure

#EndRegion

#Region Private

&AtServerNoContext
Procedure DisconnectAtServer()
	
	BeginTransaction();
	Try
		MasterNode = Constants.MasterNode.Get();
		
		MasterNodeManager = Constants.MasterNode.CreateValueManager();
		MasterNodeManager.Value = Undefined;
		InfobaseUpdate.WriteData(MasterNodeManager);
		
		IsStandaloneWorkplace = Constants.IsStandaloneWorkplace.CreateValueManager();
		IsStandaloneWorkplace.Read();
		If IsStandaloneWorkplace.Value Then
			IsStandaloneWorkplace.Value = False;
			InfobaseUpdate.WriteData(IsStandaloneWorkplace);
			
			DontUseSeparationByDataAreas = Constants.DoNotUseSeparationByDataAreas.CreateValueManager();
			DontUseSeparationByDataAreas.Read();
			If Not Constants.UseSeparationByDataAreas.Get()
				AND Not DontUseSeparationByDataAreas.Value Then
				DontUseSeparationByDataAreas.Value = True;
				InfobaseUpdate.WriteData(DontUseSeparationByDataAreas);
			EndIf;
			
		EndIf;
		
		If Common.SubsystemExists("StandardSubsystems.DataExchange") Then
			ModuleDataExchangeServer = Common.CommonModule("DataExchangeServer");
			ModuleDataExchangeServer.DeleteSynchronizationSettingsForMasterDIBNode(MasterNode);
		EndIf;
		
		StandardSubsystemsServer.RestorePredefinedItems();
		
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;
	
EndProcedure

&AtServerNoContext
Procedure ReconnectAtServer()
	
	MasterNode = Constants.MasterNode.Get();
	
	ExchangePlans.SetMasterNode(MasterNode);
	
EndProcedure

#EndRegion
