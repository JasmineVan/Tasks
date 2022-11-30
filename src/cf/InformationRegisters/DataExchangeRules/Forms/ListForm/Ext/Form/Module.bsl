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
	
	If Parameters.Property("ExchangePlansWithRulesFromFile") Then
		
		Items.RulesSource.Visible = False;
		CommonClientServer.SetDynamicListFilterItem(
			List,
			"RulesSource",
			Enums.DataExchangeRulesSources.File,
			DataCompositionComparisonType.Equal);
		
	EndIf;
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersList

&AtClient
Procedure ListBeforeDelete(Item, Cancel)
	Cancel = True;
EndProcedure

#EndRegion

#Region FormCommandHandlers

&AtClient
Procedure UpdateAllStandardRules(Command)
	
	UpdateAllStandardRulesAtServer();
	Items.List.Refresh();
	
	ShowUserNotification(NStr("ru = 'Обновление правил успешно завершено.'; en = 'The rule update is completed.'; pl = 'Aktualizacja reguł zakończona pomyślnie.';de = 'Regeln werden erfolgreich aktualisiert.';ro = 'Regulile sunt actualizate cu succes.';tr = 'Kurallar başarıyla güncellendi.'; es_ES = 'Reglas se han actualizado con éxito.'"));
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure UpdateAllStandardRulesAtServer()
	
	DataExchangeServer.UpdateDataExchangeRules();
	
	RefreshReusableValues();
	
EndProcedure

&AtClient
Procedure UseStandardRules(Command)
	UseStandardRulesAtServer();
	Items.List.Refresh();
	ShowUserNotification(NStr("ru = 'Обновление правил успешно завершено.'; en = 'The rule update is completed.'; pl = 'Aktualizacja reguł zakończona pomyślnie.';de = 'Regeln werden erfolgreich aktualisiert.';ro = 'Regulile sunt actualizate cu succes.';tr = 'Kurallar başarıyla güncellendi.'; es_ES = 'Reglas se han actualizado con éxito.'"));
EndProcedure

&AtServer
Procedure UseStandardRulesAtServer()
	
	For Each Record In Items.List.SelectedRows Do
		RecordManager = InformationRegisters.DataExchangeRules.CreateRecordManager();
		FillPropertyValues(RecordManager, Record);
		RecordManager.Read();
		RecordManager.RulesSource = Enums.DataExchangeRulesSources.ConfigurationTemplate;
		HasErrors = False;
		InformationRegisters.DataExchangeRules.ImportRules(HasErrors, RecordManager);
		If Not HasErrors Then
			RecordManager.Write();
		EndIf;
	EndDo;
	
	DataExchangeInternal.ResetObjectsRegistrationMechanismCache();
	RefreshReusableValues();
	
EndProcedure

#EndRegion
