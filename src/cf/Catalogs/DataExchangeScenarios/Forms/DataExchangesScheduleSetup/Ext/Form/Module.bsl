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
	
	SetConditionalAppearance();
	
	List.Parameters.Items[0].Value = Parameters.InfobaseNode;
	List.Parameters.Items[0].Use = True;
	
	Title = NStr("ru = 'Сценарии синхронизации данных для: [InfobaseNode]'; en = 'Data synchronization scenarios for [InfobaseNode]'; pl = 'Konfiguracja scenariusza synchronizacji dla: [InfobaseNode]';de = 'Datensynchronisationsszenarien für: [InfobaseNode]';ro = 'Scenariile de sincronizare a datelor pentru: [InfobaseNode]';tr = '[InfobaseNode] için veri senkronizasyonu senaryoları'; es_ES = 'Scripts de la sincronización de datos para: [InfobaseNode].'");
	Title = StrReplace(Title, "[InfobaseNode]", String(Parameters.InfobaseNode));
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If EventName = "Write_DataExchangeScenarios" Then
		
		Items.List.Refresh();
		
	EndIf;
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersList

&AtClient
Procedure ListChoice(Item, RowSelected, Field, StandardProcessing)
	
	StandardProcessing = False;
	
	CurrentData = Items.List.RowData(RowSelected);
	
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	If Field = Items.ImportUsageFlag Then
		
		EnableDisableImportAtServer(CurrentData.ImportUsageFlag, CurrentData.Ref);
		
	ElsIf Field = Items.ExportUsageFlag Then
		
		EnableDisableExportAtServer(CurrentData.ExportUsageFlag, CurrentData.Ref);
		
	ElsIf Field = Items.Description Then
		
		ChangeDataExchangeScenario(Undefined);
		
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandHandlers

&AtClient
Procedure Create(Command)
	
	FormParameters = New Structure("InfobaseNode", Parameters.InfobaseNode);
	
	OpenForm("Catalog.DataExchangeScenarios.ObjectForm", FormParameters, ThisObject);
	
EndProcedure

&AtClient
Procedure ChangeDataExchangeScenario(Command)
	
	CurrentData = Items.List.CurrentData;
	
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	FormParameters = New Structure;
	FormParameters.Insert("Key", CurrentData.Ref);
	
	OpenForm("Catalog.DataExchangeScenarios.ObjectForm", FormParameters, ThisObject);
	
EndProcedure

&AtClient
Procedure EnableDisableScheduledJob(Command)
	
	CurrentData = Items.List.CurrentData;
	
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	EnableDisableScheduledJobAtServer(CurrentData.Ref);
	
EndProcedure

&AtClient
Procedure EnableDisableExport(Command)
	
	CurrentData = Items.List.CurrentData;
	
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	EnableDisableExportAtServer(CurrentData.ExportUsageFlag, CurrentData.Ref);
	
EndProcedure

&AtClient
Procedure EnableDisableImport(Command)
	
	CurrentData = Items.List.CurrentData;
	
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	EnableDisableImportAtServer(CurrentData.ImportUsageFlag, CurrentData.Ref);
	
EndProcedure

&AtClient
Procedure EnableDisableImportExport(Command)
	
	CurrentData = Items.List.CurrentData;
	
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	EnableDisableImportExportAtServer(CurrentData.ImportUsageFlag OR CurrentData.ExportUsageFlag, CurrentData.Ref);
	
EndProcedure

&AtClient
Procedure RunScenario(Command)
	
	CurrentData = Items.List.CurrentData;
	
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	Cancel = False;
	
	// Starting data exchange.
	DataExchangeServerCall.ExecuteDataExchangeUsingDataExchangeScenario(Cancel, CurrentData.Ref);
	
	If Cancel Then
		Message = NStr("ru = 'Сценарий синхронизации выполнен с ошибками.'; en = 'The synchronization scenario completed with errors.'; pl = 'Scenariusz synchronizacji danych wykonano z błędami.';de = 'Datensynchronisation Szenario mit Fehlern abgeschlossen.';ro = 'Scenariul de sincronizare a datelor a fost executat cu erori.';tr = 'Veri senkronizasyonu senaryosu hatalarla tamamlandı.'; es_ES = 'Escenario de la sincronización de datos se ha finalizado con errores.'");
		Picture = PictureLib.Error32;
	Else
		Message = NStr("ru = 'Сценарий синхронизации успешно выполнен.'; en = 'The synchronization scenario is completed.'; pl = 'Scenariusz synchronizacji został zakończony pomyślnie.';de = 'Die Synchronisation Szenario ist erfolgreich abgeschlossen.';ro = 'Scenariul de sincronizare este executat cu succes.';tr = 'Senkronizasyon senaryosu başarı ile tamamlandı.'; es_ES = 'Escenario de la sincronización se ha finalizado con éxito.'");
		Picture = Undefined;
	EndIf;
	ShowUserNotification(Message,,,Picture);
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure EnableDisableScheduledJobAtServer(Ref)
	
	SettingObject = Ref.GetObject();
	SettingObject.UseScheduledJob = Not SettingObject.UseScheduledJob;
	SettingObject.Write();
	
	// Updating list data
	Items.List.Refresh();
	
EndProcedure

&AtServer
Procedure EnableDisableExportAtServer(Val ExportUsageFlag, Val DataExchangeScenario)
	
	If ExportUsageFlag Then
		
		Catalogs.DataExchangeScenarios.DeleteExportToDataExchangeScenarios(DataExchangeScenario, Parameters.InfobaseNode);
		
	Else
		
		Catalogs.DataExchangeScenarios.AddExportToDataExchangeScenarios(DataExchangeScenario, Parameters.InfobaseNode);
		
	EndIf;
	
	Items.List.Refresh();
	
EndProcedure

&AtServer
Procedure EnableDisableImportAtServer(Val ImportUsageFlag, Val DataExchangeScenario)
	
	If ImportUsageFlag Then
		
		Catalogs.DataExchangeScenarios.DeleteImportToDataExchangeScenarios(DataExchangeScenario, Parameters.InfobaseNode);
		
	Else
		
		Catalogs.DataExchangeScenarios.AddImportToDataExchangeScenarios(DataExchangeScenario, Parameters.InfobaseNode);
		
	EndIf;
	
	Items.List.Refresh();
	
EndProcedure

&AtServer
Procedure EnableDisableImportExportAtServer(Val UsageFlag, Val DataExchangeScenario)
	
	EnableDisableImportAtServer(UsageFlag, DataExchangeScenario);
	
	EnableDisableExportAtServer(UsageFlag, DataExchangeScenario);
	
EndProcedure

&AtServer
Procedure SetConditionalAppearance()
	
	ConditionalAppearance.Items.Clear();
	
	//
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.List.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("List.UseScheduledJob");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	Item.Appearance.SetParameterValue("Font", New Font(WindowsFonts.DefaultGUIFont, , , True, False, False, False));
	
	//
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.List.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("List.UsageFlag");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	Item.Appearance.SetParameterValue("BackColor", WebColors.Azure);
	
EndProcedure

#EndRegion
