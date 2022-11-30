///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Variables

&AtClient
Var ChoiceContext;

#EndRegion

#Region EventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	SetConditionalAppearance();
	
	If Common.DataSeparationEnabled() Then
		Raise NStr("ru = 'Управление итогами и агрегатами недоступно в модели сервиса.'; en = 'Totals and aggregate management is unavailable in SaaS.'; pl = 'Totals and aggregate management is unavailable in SaaS.';de = 'Totals and aggregate management is unavailable in SaaS.';ro = 'Totals and aggregate management is unavailable in SaaS.';tr = 'Totals and aggregate management is unavailable in SaaS.'; es_ES = 'Totals and aggregate management is unavailable in SaaS.'");
	EndIf;
	
	If Not Users.IsFullUser() Then
		StandardProcessing = False;
		Return;
	EndIf;
	
	ReadInformationOnRegisters();
	
	UpdateTotalsListAtServer();
	UpdateAggregatesByRegistersAtServer();
	
	If AggregatesByRegisters.Count() <> 0 Then
		Items.AggregatesList.Title = Prefix() + " " + AggregatesByRegisters[0].Description;
	Else
		Items.AggregatesList.Title = Prefix();
	EndIf;
	
	If TotalsList.Count() = 0 Then
		Items.TotalsGroup.Enabled = False;
		Items.SetTotalsPeriod.Enabled = False;
		Items.EnableTotalsUsage.Enabled = False;
	EndIf;
	
	If AggregatesByRegisters.Count() = 0 Then
		Items.AggregatesGroup.Enabled = False;
		Items.RebuildAndFillAggregates.Enabled = False;
		Items.GetOptimalAggregates.Enabled = False;
	EndIf;
	
	Items.Operations.PagesRepresentation = FormPagesRepresentation.None;
	
	SetAdvancedMode();
	
	CalculateTotalsFor = CurrentSessionDate();
	
	Items.PeriodSettingDescription.Title = StringFunctionsClientServer.SubstituteParametersToString(
		Items.PeriodSettingDescription.Title,
		Format(PeriodEnd(AddMonth(CalculateTotalsFor, -1)), "DLF=D"),
		Format(PeriodEnd(CalculateTotalsFor), "DLF=D"));
	
EndProcedure

&AtServer
Procedure OnLoadDataFromSettingsAtServer(Settings)
	
	SetAdvancedMode();
	
EndProcedure

&AtClient
Procedure ChoiceProcessing(SelectedValue, ChoiceSource)
	
	If Upper(ChoiceSource.FormName) = Upper("DataProcessor.TotalsAndAggregatesManagement.Form.PeriodChoiceForm") Then
		
		If TypeOf(SelectedValue) <> Type("Structure") Then
			Return;
		EndIf;
		
		TotalsParameters = New Structure;
		TotalsParameters.Insert("ProcessTitle",  NStr("ru='Установка периода рассчитанных итогов ...'; en = 'Setting calculated totals period ...'; pl = 'Setting calculated totals period ...';de = 'Setting calculated totals period ...';ro = 'Setting calculated totals period ...';tr = 'Setting calculated totals period ...'; es_ES = 'Setting calculated totals period ...'"));
		TotalsParameters.Insert("AfterProcess",          NStr("ru='Установка периода рассчитанных итогов завершена'; en = 'Setting of calculated totals period is complete'; pl = 'Setting of calculated totals period is complete';de = 'Setting of calculated totals period is complete';ro = 'Setting of calculated totals period is complete';tr = 'Setting of calculated totals period is complete'; es_ES = 'Setting of calculated totals period is complete'"));
		TotalsParameters.Insert("Action",               "SetTotalPeriod");
		TotalsParameters.Insert("RowsArray",            Items.TotalsList.SelectedRows);
		TotalsParameters.Insert("Field",                   "TotalsPeriod");
		TotalsParameters.Insert("Value1",              SelectedValue.PeriodForAccumulationRegisters);
		TotalsParameters.Insert("Value2",              SelectedValue.PeriodForAccountingRegisters);
		TotalsParameters.Insert("ErrorMessageText", NStr("ru='Не удалось установить период рассчитанных итогов.'; en = 'Cannot set the calculated totals period.'; pl = 'Cannot set the calculated totals period.';de = 'Cannot set the calculated totals period.';ro = 'Cannot set the calculated totals period.';tr = 'Cannot set the calculated totals period.'; es_ES = 'Cannot set the calculated totals period.'"));
		
		TotalsControl(TotalsParameters);
		
	ElsIf Upper(ChoiceSource.FormName) = Upper("DataProcessor.TotalsAndAggregatesManagement.Form.RebuildParametersForm") Then
		
		If TypeOf(SelectedValue) <> Type("Structure") Then
			Return;
		EndIf;
		
		If ChoiceContext = "RebuildAggregates" Then
			
			RelativeSize = SelectedValue.RelativeSize;
			MinEffect   = SelectedValue.MinEffect;
			
			TotalsParameters = New Structure;
			TotalsParameters.Insert("ProcessTitle",  NStr("ru='Перестроение агрегатов ...'; en = 'Rebuilding aggregates ...'; pl = 'Rebuilding aggregates ...';de = 'Rebuilding aggregates ...';ro = 'Rebuilding aggregates ...';tr = 'Rebuilding aggregates ...'; es_ES = 'Rebuilding aggregates ...'"));
			TotalsParameters.Insert("AfterProcess",          NStr("ru='Перестроение агрегатов завершено'; en = 'Aggregates are rebuilt'; pl = 'Aggregates are rebuilt';de = 'Aggregates are rebuilt';ro = 'Aggregates are rebuilt';tr = 'Aggregates are rebuilt'; es_ES = 'Aggregates are rebuilt'"));
			TotalsParameters.Insert("Action",               "RebuildAggregates");
			TotalsParameters.Insert("RowsArray",            Items.AggregatesByRegisters.SelectedRows);
			TotalsParameters.Insert("Field",                   "Description");
			TotalsParameters.Insert("Value1",              SelectedValue.RelativeSize);
			TotalsParameters.Insert("Value2",              SelectedValue.MinEffect);
			TotalsParameters.Insert("ErrorMessageText", NStr("ru='Не удалось перестроить агрегаты.'; en = 'Cannot rebuild aggregates.'; pl = 'Cannot rebuild aggregates.';de = 'Cannot rebuild aggregates.';ro = 'Cannot rebuild aggregates.';tr = 'Cannot rebuild aggregates.'; es_ES = 'Cannot rebuild aggregates.'"));
			
			ChangeAggregatesClient(TotalsParameters);
			
		ElsIf ChoiceContext = "OptimalAggregates" Then
			
			OptimalRelativeSize = SelectedValue.RelativeSize;
			GetOptimalAggregatesClient();
			
		EndIf;
		
	EndIf;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure HyperlinkWithTextClick(Item, StandardProcessing)
	
	StandardProcessing = False;
	FullFunctionality = Not FullFunctionality;
	SetAdvancedMode();
	
EndProcedure

#EndRegion

#Region TotalsListFormTableItemsEventHandlers

&AtClient
Procedure TotalsListOnActivateRow(Item)
	
	AttachIdleHandler("TotalsListOnActivateRowDeferred", 0.1, True);	
		
EndProcedure

&AtClient
Procedure TotalsListOnActivateRowDeferred()
	
	TotalsListOnActivateRowAtServer();	
	
EndProcedure

&AtServer
Procedure TotalsListOnActivateRowAtServer()
		
	SelectedRows = Items.TotalsList.SelectedRows;
	
	RegistersWithTotalsSelected = False;
	RegistersWithTotalsAndBalanceSelected = False;
	RegistersWithTotalsSplitSelected = False;
	
	For Each RowID In SelectedRows Do
		TableRow =  TotalsList.FindByID(RowID);
		If TableRow = Undefined Then
			Continue;
		EndIf;
		If TableRow.AggregatesTotals = 0 Or TableRow.AggregatesTotals = 2 Then
			RegistersWithTotalsSelected = True;
			If TableRow.BalanceAndTurnovers Then
				RegistersWithTotalsAndBalanceSelected = True;
			EndIf;
		EndIf;
		If TableRow.EnableTotalsSplitting Then
			RegistersWithTotalsSplitSelected = True;
		EndIf;
	EndDo;
	
	Items.Totals1Group.Enabled              = RegistersWithTotalsSelected;
	Items.CurrentTotalsGroup.Enabled       = RegistersWithTotalsAndBalanceSelected;
	Items.TotalsSplittingGroup.Enabled   = RegistersWithTotalsSplitSelected;
	Items.SetTotalPeriod.Enabled   = RegistersWithTotalsAndBalanceSelected;	
	
EndProcedure
	
&AtClient
Procedure TotalsListChoice(Item, RowSelected, Field, StandardProcessing)
	
	MetadataName = TotalsList.FindByID(RowSelected).MetadataName;
	If Field.Name = "TotalsAggregatesTotals" Then
		
		StandardProcessing = False;
		
		ResultArray = AggregatesByRegisters.FindRows(
			New Structure("MetadataName", MetadataName));
		
		If ResultArray.Count() > 0 Then
			
			Index = AggregatesByRegisters.IndexOf(ResultArray[0]);
			CurrentItem = Items.AggregatesByRegisters;
			Items.AggregatesByRegisters.CurrentRow = Index;
			Items.AggregatesByRegisters.CurrentItem = Items.AggregatesByRegistersDescription;
			
		EndIf;
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandHandlers

&AtClient
Procedure EnableTotalsUsage(Command)
	
	TotalsParameters = New Structure;
	TotalsParameters.Insert("ProcessTitle",  NStr("ru='Включение использования итогов ...'; en = 'Enable totals usage...'; pl = 'Enable totals usage...';de = 'Enable totals usage...';ro = 'Enable totals usage...';tr = 'Enable totals usage...'; es_ES = 'Enable totals usage...'"));
	TotalsParameters.Insert("AfterProcess",          NStr("ru='Включение использования итогов завершено'; en = 'Enabling usage of totals is completed'; pl = 'Enabling usage of totals is completed';de = 'Enabling usage of totals is completed';ro = 'Enabling usage of totals is completed';tr = 'Enabling usage of totals is completed'; es_ES = 'Enabling usage of totals is completed'"));
	TotalsParameters.Insert("Action",               "SetTotalsUsing");
	TotalsParameters.Insert("RowsArray",            Items.TotalsList.SelectedRows);
	TotalsParameters.Insert("Field",                   "UseTotals");
	TotalsParameters.Insert("Value1",              True);
	TotalsParameters.Insert("Value2",              Undefined);
	TotalsParameters.Insert("ErrorMessageText", NStr("ru='Не удалось включить использование итогов.'; en = 'Cannot enable totals usage.'; pl = 'Cannot enable totals usage.';de = 'Cannot enable totals usage.';ro = 'Cannot enable totals usage.';tr = 'Cannot enable totals usage.'; es_ES = 'Cannot enable totals usage.'"));
	
	TotalsControl(TotalsParameters);

EndProcedure

&AtClient
Procedure EnableCurrentTotalsUsage(Command)
	
	TotalsParameters = New Structure;
	TotalsParameters.Insert("ProcessTitle",  NStr("ru='Включение использования текущих итогов ...'; en = 'Enabling usage of the current totals...'; pl = 'Enabling usage of the current totals...';de = 'Enabling usage of the current totals...';ro = 'Enabling usage of the current totals...';tr = 'Enabling usage of the current totals...'; es_ES = 'Enabling usage of the current totals...'"));
	TotalsParameters.Insert("AfterProcess",          NStr("ru='Включение использования текущих итогов завершено'; en = 'Enabling usage of the current totals is completed'; pl = 'Enabling usage of the current totals is completed';de = 'Enabling usage of the current totals is completed';ro = 'Enabling usage of the current totals is completed';tr = 'Enabling usage of the current totals is completed'; es_ES = 'Enabling usage of the current totals is completed'"));
	TotalsParameters.Insert("Action",               "UseCurrentTotals");
	TotalsParameters.Insert("RowsArray",            Items.TotalsList.SelectedRows);
	TotalsParameters.Insert("Field",                   "UseCurrentTotals");
	TotalsParameters.Insert("Value1",              True);
	TotalsParameters.Insert("Value2",              Undefined);
	TotalsParameters.Insert("ErrorMessageText", NStr("ru='Не удалось включить использование текущих итогов.'; en = 'Cannot enable usage of current subtotals.'; pl = 'Cannot enable usage of current subtotals.';de = 'Cannot enable usage of current subtotals.';ro = 'Cannot enable usage of current subtotals.';tr = 'Cannot enable usage of current subtotals.'; es_ES = 'Cannot enable usage of current subtotals.'"));
	
	TotalsControl(TotalsParameters);
	
EndProcedure

&AtClient
Procedure DisableTotalsUsage(Command)
	
	TotalsParameters = New Structure;
	TotalsParameters.Insert("ProcessTitle",  NStr("ru='Выключение использования итогов ...'; en = 'Disable totals usage...'; pl = 'Disable totals usage...';de = 'Disable totals usage...';ro = 'Disable totals usage...';tr = 'Disable totals usage...'; es_ES = 'Disable totals usage...'"));
	TotalsParameters.Insert("AfterProcess",          NStr("ru='Выключение использования итогов завершено'; en = 'Disabling usage of totals is completed'; pl = 'Disabling usage of totals is completed';de = 'Disabling usage of totals is completed';ro = 'Disabling usage of totals is completed';tr = 'Disabling usage of totals is completed'; es_ES = 'Disabling usage of totals is completed'"));
	TotalsParameters.Insert("Action",               "SetTotalsUsing");
	TotalsParameters.Insert("RowsArray",            Items.TotalsList.SelectedRows);
	TotalsParameters.Insert("Field",                   "UseTotals");
	TotalsParameters.Insert("Value1",              False);
	TotalsParameters.Insert("Value2",              Undefined);
	TotalsParameters.Insert("ErrorMessageText", NStr("ru='Не удалось выключить использование итогов.'; en = 'Cannot disable totals usage.'; pl = 'Cannot disable totals usage.';de = 'Cannot disable totals usage.';ro = 'Cannot disable totals usage.';tr = 'Cannot disable totals usage.'; es_ES = 'Cannot disable totals usage.'"));
	
	TotalsControl(TotalsParameters);
	
EndProcedure

&AtClient
Procedure DisableCurrentTotalsUsage(Command)
	
	TotalsParameters = New Structure;
	TotalsParameters.Insert("ProcessTitle",  NStr("ru='Выключение использования текущих итогов ...'; en = 'Disabling usage of the current totals ...'; pl = 'Disabling usage of the current totals ...';de = 'Disabling usage of the current totals ...';ro = 'Disabling usage of the current totals ...';tr = 'Disabling usage of the current totals ...'; es_ES = 'Disabling usage of the current totals ...'"));
	TotalsParameters.Insert("AfterProcess",          NStr("ru='Выключение использования текущих итогов завершено'; en = 'Disabling usage of the current totals is completed'; pl = 'Disabling usage of the current totals is completed';de = 'Disabling usage of the current totals is completed';ro = 'Disabling usage of the current totals is completed';tr = 'Disabling usage of the current totals is completed'; es_ES = 'Disabling usage of the current totals is completed'"));
	TotalsParameters.Insert("Action",               "UseCurrentTotals");
	TotalsParameters.Insert("RowsArray",            Items.TotalsList.SelectedRows);
	TotalsParameters.Insert("Field",                   "UseCurrentTotals");
	TotalsParameters.Insert("Value1",              False);
	TotalsParameters.Insert("Value2",              Undefined);
	TotalsParameters.Insert("ErrorMessageText", NStr("ru='Не удалось выключить использование текущих итогов.'; en = 'Cannot disable usage of current subtotals.'; pl = 'Cannot disable usage of current subtotals.';de = 'Cannot disable usage of current subtotals.';ro = 'Cannot disable usage of current subtotals.';tr = 'Cannot disable usage of current subtotals.'; es_ES = 'Cannot disable usage of current subtotals.'"));
	
	TotalsControl(TotalsParameters);
	
EndProcedure

&AtClient
Procedure UpdateTotalState(Command)
	
	UpdateTotalsListAtServer();
	
EndProcedure

&AtClient
Procedure SetTotalPeriod(Command)
	
	FormParameters = New Structure;
	FormParameters.Insert("AccumulationReg",  False);
	FormParameters.Insert("AccountingReg", False);
	
	For Each Index In Items.TotalsList.SelectedRows Do
		RegisterInformation = TotalsList.FindByID(Index);
		FormParameters.AccumulationReg  = FormParameters.AccumulationReg  Or RegisterInformation.Type = 0;
		FormParameters.AccountingReg = FormParameters.AccountingReg Or RegisterInformation.Type = 1;
	EndDo;
	
	OpenForm("DataProcessor.TotalsAndAggregatesManagement.Form.PeriodChoiceForm", FormParameters, ThisObject);
	
EndProcedure

&AtClient
Procedure EnableTotalsSplitting(Command)
	
	TotalsParameters = New Structure;
	TotalsParameters.Insert("ProcessTitle",  NStr("ru='Включение разделения итогов ...'; en = 'Enable totals separation...'; pl = 'Enable totals separation...';de = 'Enable totals separation...';ro = 'Enable totals separation...';tr = 'Enable totals separation...'; es_ES = 'Enable totals separation...'"));
	TotalsParameters.Insert("AfterProcess",          NStr("ru='Включение разделения итогов завершено'; en = 'Enabling of total separation is completed'; pl = 'Enabling of total separation is completed';de = 'Enabling of total separation is completed';ro = 'Enabling of total separation is completed';tr = 'Enabling of total separation is completed'; es_ES = 'Enabling of total separation is completed'"));
	TotalsParameters.Insert("Action",               "SetTotalsSeparation");
	TotalsParameters.Insert("RowsArray",            Items.TotalsList.SelectedRows);
	TotalsParameters.Insert("Field",                   "TotalsSeparation");
	TotalsParameters.Insert("Value1",              True);
	TotalsParameters.Insert("Value2",              Undefined);
	TotalsParameters.Insert("ErrorMessageText", NStr("ru='Не удалось включить разделение итогов.'; en = 'Cannot enable totals split.'; pl = 'Cannot enable totals split.';de = 'Cannot enable totals split.';ro = 'Cannot enable totals split.';tr = 'Cannot enable totals split.'; es_ES = 'Cannot enable totals split.'"));
	
	TotalsControl(TotalsParameters);
	
EndProcedure

&AtClient
Procedure DisableTotalsSplitting(Command)
	
	TotalsParameters = New Structure;
	TotalsParameters.Insert("ProcessTitle",  NStr("ru='Выключение разделения итогов ...'; en = 'Disable totals separation...'; pl = 'Disable totals separation...';de = 'Disable totals separation...';ro = 'Disable totals separation...';tr = 'Disable totals separation...'; es_ES = 'Disable totals separation...'"));
	TotalsParameters.Insert("AfterProcess",          NStr("ru='Выключение разделения итогов завершено'; en = 'Disabling division of totals is completed'; pl = 'Disabling division of totals is completed';de = 'Disabling division of totals is completed';ro = 'Disabling division of totals is completed';tr = 'Disabling division of totals is completed'; es_ES = 'Disabling division of totals is completed'"));
	TotalsParameters.Insert("Action",               "SetTotalsSeparation");
	TotalsParameters.Insert("RowsArray",            Items.TotalsList.SelectedRows);
	TotalsParameters.Insert("Field",                   "TotalsSeparation");
	TotalsParameters.Insert("Value1",              False);
	TotalsParameters.Insert("Value2",              Undefined);
	TotalsParameters.Insert("ErrorMessageText", NStr("ru='Не удалось выключить разделение итогов.'; en = 'Cannot disable totals split.'; pl = 'Cannot disable totals split.';de = 'Cannot disable totals split.';ro = 'Cannot disable totals split.';tr = 'Cannot disable totals split.'; es_ES = 'Cannot disable totals split.'"));
	
	TotalsControl(TotalsParameters);
	
EndProcedure

&AtClient
Procedure UpdateAggregatesInformation(Command)
	
	UpdateAggregatesByRegistersAtServer();
	SetAggregatesListFilter();
	
EndProcedure

&AtClient
Procedure AggregatesByRegistersOnActivateRow(Item)
	
	SetAggregatesListFilter();
	
	If Item.CurrentData = Undefined Then
		ItemsAvailability = False;
		
	ElsIf Item.SelectionMode = TableSelectionMode.SingleRow Then
		ItemsAvailability = Item.CurrentData.AggregateMode;
	Else
		ItemsAvailability = True;
	EndIf;
	
	Items.AggregatesRebuildButton.Enabled                     = ItemsAvailability;
	Items.AggregatesClearAggregatesByRegistersButton.Enabled     = ItemsAvailability;
	Items.AggregatesFillAggregatesByRegistersButton.Enabled    = ItemsAvailability;
	Items.AggregatesOptimalButton.Enabled                     = ItemsAvailability;
	Items.AggregatesDisableAggregatesUsageButton.Enabled = ItemsAvailability;
	Items.AggregatesEnableAggregatesUsageButton.Enabled  = ItemsAvailability;
	
EndProcedure

&AtClient
Procedure EnableAggregateMode(Command)
	
	TotalsParameters = New Structure;
	TotalsParameters.Insert("ProcessTitle",  NStr("ru='Включение режима агрегатов ...'; en = 'Enable aggregate mode ...'; pl = 'Enable aggregate mode ...';de = 'Enable aggregate mode ...';ro = 'Enable aggregate mode ...';tr = 'Enable aggregate mode ...'; es_ES = 'Enable aggregate mode ...'"));
	TotalsParameters.Insert("AfterProcess",          NStr("ru='Включение режима агрегатов завершено'; en = 'Enabling of aggregate mode is completed'; pl = 'Enabling of aggregate mode is completed';de = 'Enabling of aggregate mode is completed';ro = 'Enabling of aggregate mode is completed';tr = 'Enabling of aggregate mode is completed'; es_ES = 'Enabling of aggregate mode is completed'"));
	TotalsParameters.Insert("Action",               "SetAggregatesMode");
	TotalsParameters.Insert("RowsArray",            Items.AggregatesByRegisters.SelectedRows);
	TotalsParameters.Insert("Field",                   "AggregateMode");
	TotalsParameters.Insert("Value1",              True);
	TotalsParameters.Insert("Value2",              Undefined);
	TotalsParameters.Insert("ErrorMessageText", NStr("ru='Не удалось включить режим агрегатов.'; en = 'Cannot enable aggregate mode.'; pl = 'Cannot enable aggregate mode.';de = 'Cannot enable aggregate mode.';ro = 'Cannot enable aggregate mode.';tr = 'Cannot enable aggregate mode.'; es_ES = 'Cannot enable aggregate mode.'"));
	
	ChangeAggregatesClient(TotalsParameters);
	
EndProcedure

&AtClient
Procedure EnableTotalsMode(Command)
	
	TotalsParameters = New Structure;
	TotalsParameters.Insert("ProcessTitle",  NStr("ru='Включение режима итогов ...'; en = 'Enabling the totals mode...'; pl = 'Enabling the totals mode...';de = 'Enabling the totals mode...';ro = 'Enabling the totals mode...';tr = 'Enabling the totals mode...'; es_ES = 'Enabling the totals mode...'"));
	TotalsParameters.Insert("AfterProcess",          NStr("ru='Включение режима итогов завершено'; en = 'Enabling of the totals mode is completed'; pl = 'Enabling of the totals mode is completed';de = 'Enabling of the totals mode is completed';ro = 'Enabling of the totals mode is completed';tr = 'Enabling of the totals mode is completed'; es_ES = 'Enabling of the totals mode is completed'"));
	TotalsParameters.Insert("Action",               "SetAggregatesMode");
	TotalsParameters.Insert("RowsArray",            Items.AggregatesByRegisters.SelectedRows);
	TotalsParameters.Insert("Field",                   "AggregateMode");
	TotalsParameters.Insert("Value1",              False);
	TotalsParameters.Insert("Value2",              Undefined);
	TotalsParameters.Insert("ErrorMessageText", NStr("ru='Не удалось включить режим итогов.'; en = 'Cannot enable totals mode.'; pl = 'Cannot enable totals mode.';de = 'Cannot enable totals mode.';ro = 'Cannot enable totals mode.';tr = 'Cannot enable totals mode.'; es_ES = 'Cannot enable totals mode.'"));
	
	ChangeAggregatesClient(TotalsParameters);
	
EndProcedure

&AtClient
Procedure EnableAggregatesUsage(Command)
	
	TotalsParameters = New Structure;
	TotalsParameters.Insert("ProcessTitle",  NStr("ru='Включение использования агрегатов ...'; en = 'Enable aggregate usage...'; pl = 'Enable aggregate usage...';de = 'Enable aggregate usage...';ro = 'Enable aggregate usage...';tr = 'Enable aggregate usage...'; es_ES = 'Enable aggregate usage...'"));
	TotalsParameters.Insert("AfterProcess",          NStr("ru='Включение использования агрегатов завершено'; en = 'Enabling of aggregate usage is completed'; pl = 'Enabling of aggregate usage is completed';de = 'Enabling of aggregate usage is completed';ro = 'Enabling of aggregate usage is completed';tr = 'Enabling of aggregate usage is completed'; es_ES = 'Enabling of aggregate usage is completed'"));
	TotalsParameters.Insert("Action",               "SetAggregatesUsing");
	TotalsParameters.Insert("RowsArray",            Items.AggregatesByRegisters.SelectedRows);
	TotalsParameters.Insert("Field",                   "AgregateUsage");
	TotalsParameters.Insert("Value1",              True);
	TotalsParameters.Insert("Value2",              Undefined);
	TotalsParameters.Insert("ErrorMessageText", NStr("ru='Не удалось включить использование агрегатов.'; en = 'Cannot enable aggregate usage.'; pl = 'Cannot enable aggregate usage.';de = 'Cannot enable aggregate usage.';ro = 'Cannot enable aggregate usage.';tr = 'Cannot enable aggregate usage.'; es_ES = 'Cannot enable aggregate usage.'"));
	
	ChangeAggregatesClient(TotalsParameters);
	
EndProcedure

&AtClient
Procedure DisableAggregatesUsage(Command)
	
	TotalsParameters = New Structure;
	TotalsParameters.Insert("ProcessTitle",  NStr("ru='Выключение использования агрегатов ...'; en = 'Disable aggregate usage...'; pl = 'Disable aggregate usage...';de = 'Disable aggregate usage...';ro = 'Disable aggregate usage...';tr = 'Disable aggregate usage...'; es_ES = 'Disable aggregate usage...'"));
	TotalsParameters.Insert("AfterProcess",          NStr("ru='Выключение использования агрегатов завершено'; en = 'Disabling aggregation usage is completed'; pl = 'Disabling aggregation usage is completed';de = 'Disabling aggregation usage is completed';ro = 'Disabling aggregation usage is completed';tr = 'Disabling aggregation usage is completed'; es_ES = 'Disabling aggregation usage is completed'"));
	TotalsParameters.Insert("Action",               "SetAggregatesUsing");
	TotalsParameters.Insert("RowsArray",            Items.AggregatesByRegisters.SelectedRows);
	TotalsParameters.Insert("Field",                   "AgregateUsage");
	TotalsParameters.Insert("Value1",              False);
	TotalsParameters.Insert("Value2",              Undefined);
	TotalsParameters.Insert("ErrorMessageText", NStr("ru='Не удалось выключить использование агрегатов.'; en = 'Cannot disable aggregate usage.'; pl = 'Cannot disable aggregate usage.';de = 'Cannot disable aggregate usage.';ro = 'Cannot disable aggregate usage.';tr = 'Cannot disable aggregate usage.'; es_ES = 'Cannot disable aggregate usage.'"));
	
	ChangeAggregatesClient(TotalsParameters);
	
EndProcedure

&AtClient
Procedure RebuildAggregates(Command)
	
	ChoiceContext = "RebuildAggregates";
	
	FormParameters = New Structure;
	FormParameters.Insert("RelativeSize", RelativeSize);
	FormParameters.Insert("MinEffect",   MinEffect);
	FormParameters.Insert("RebuildMode",   True);
	
	OpenForm("DataProcessor.TotalsAndAggregatesManagement.Form.RebuildParametersForm", FormParameters, ThisObject);
	
EndProcedure

&AtClient
Procedure ClearAggregatesByRegisters(Command)
	
	QuestionText = NStr("ru='Очистка агрегатов может привести к существенному замедлению отчетов.'; en = 'Aggregate cleanup may significantly slow down the reports.'; pl = 'Aggregate cleanup may significantly slow down the reports.';de = 'Aggregate cleanup may significantly slow down the reports.';ro = 'Aggregate cleanup may significantly slow down the reports.';tr = 'Aggregate cleanup may significantly slow down the reports.'; es_ES = 'Aggregate cleanup may significantly slow down the reports.'");
	
	Buttons = New ValueList;
	Buttons.Add(DialogReturnCode.Yes, NStr("ru = 'Очистить агрегаты'; en = 'Clear aggregates'; pl = 'Clear aggregates';de = 'Clear aggregates';ro = 'Clear aggregates';tr = 'Clear aggregates'; es_ES = 'Clear aggregates'"));
	Buttons.Add(DialogReturnCode.Cancel);
	
	Handler = New NotifyDescription("ClearAggregatesByRegistersCompletion", ThisObject);
	ShowQueryBox(Handler, QuestionText, Buttons, , DialogReturnCode.Cancel);
	
EndProcedure

&AtClient
Procedure FillAggregatesByRegisters(Command)
	
	TotalsParameters = New Structure;
	TotalsParameters.Insert("ProcessTitle",  NStr("ru='Заполнение агрегатов ...'; en = 'Populating aggregates...'; pl = 'Populating aggregates...';de = 'Populating aggregates...';ro = 'Populating aggregates...';tr = 'Populating aggregates...'; es_ES = 'Populating aggregates...'"));
	TotalsParameters.Insert("AfterProcess",          NStr("ru='Заполнение агрегатов завершено'; en = 'Aggregates are populated'; pl = 'Aggregates are populated';de = 'Aggregates are populated';ro = 'Aggregates are populated';tr = 'Aggregates are populated'; es_ES = 'Aggregates are populated'"));
	TotalsParameters.Insert("Action",               "FillAggregates");
	TotalsParameters.Insert("RowsArray",            Items.AggregatesByRegisters.SelectedRows);
	TotalsParameters.Insert("Field",                   "Description");
	TotalsParameters.Insert("Value1",              Undefined);
	TotalsParameters.Insert("Value2",              Undefined);
	TotalsParameters.Insert("ErrorMessageText", NStr("ru='Не удалось заполнить агрегаты.'; en = 'Cannot fill in aggregates.'; pl = 'Cannot fill in aggregates.';de = 'Cannot fill in aggregates.';ro = 'Cannot fill in aggregates.';tr = 'Cannot fill in aggregates.'; es_ES = 'Cannot fill in aggregates.'"));
	
	ChangeAggregatesClient(TotalsParameters);
	
EndProcedure

&AtClient
Procedure OptimalAggregates(Command)
	ChoiceContext = "OptimalAggregates";
	
	FormParameters = New Structure;
	FormParameters.Insert("RelativeSize", OptimalRelativeSize);
	FormParameters.Insert("MinEffect",   0);
	FormParameters.Insert("RebuildMode",   False);
	
	OpenForm("DataProcessor.TotalsAndAggregatesManagement.Form.RebuildParametersForm", FormParameters, ThisObject);
EndProcedure

&AtClient
Procedure SetTotalsPeriod(Command)
	
	ClearMessages();
	
	ActionsArray = TotalsList.FindRows(New Structure("BalanceAndTurnovers", True));
	
	If ActionsArray.Count() = 0 Then
		ShowMessageBox(, NStr("ru='Отсутствуют регистры, для которых можно выполнить данную операцию.'; en = 'No registers to perform this action.'; pl = 'No registers to perform this action.';de = 'No registers to perform this action.';ro = 'No registers to perform this action.';tr = 'No registers to perform this action.'; es_ES = 'No registers to perform this action.'"));
		Return;
	EndIf;
	
	TotalsParameters = New Structure;
	TotalsParameters.Insert("ProcessTitle",  NStr("ru='Установка периода рассчитанных итогов ...'; en = 'Setting calculated totals period ...'; pl = 'Setting calculated totals period ...';de = 'Setting calculated totals period ...';ro = 'Setting calculated totals period ...';tr = 'Setting calculated totals period ...'; es_ES = 'Setting calculated totals period ...'"));
	TotalsParameters.Insert("AfterProcess",          NStr("ru='Установка периода рассчитанных итогов завершена'; en = 'Setting of calculated totals period is complete'; pl = 'Setting of calculated totals period is complete';de = 'Setting of calculated totals period is complete';ro = 'Setting of calculated totals period is complete';tr = 'Setting of calculated totals period is complete'; es_ES = 'Setting of calculated totals period is complete'"));
	TotalsParameters.Insert("Action",               "SetTotalPeriod");
	TotalsParameters.Insert("RowsArray",            ActionsArray);
	TotalsParameters.Insert("Field",                   "TotalsPeriod");
	TotalsParameters.Insert("Value1",              PeriodEnd(AddMonth(CalculateTotalsFor, -1)) );
	TotalsParameters.Insert("Value2",              PeriodEnd(CalculateTotalsFor) );
	TotalsParameters.Insert("ErrorMessageText", NStr("ru='Не удалось установить период рассчитанных итогов.'; en = 'Cannot set the calculated totals period.'; pl = 'Cannot set the calculated totals period.';de = 'Cannot set the calculated totals period.';ro = 'Cannot set the calculated totals period.';tr = 'Cannot set the calculated totals period.'; es_ES = 'Cannot set the calculated totals period.'"));
	TotalsParameters.Insert("GroupProcessing",     True);
	
	TotalsControl(TotalsParameters);
	
EndProcedure

&AtClient
Procedure EnableTotalsUsageQuickAccess(Command)
	
	ClearMessages();
	
	ActionsArray = TotalsList.FindRows(New Structure("UseTotals", False));
	
	If ActionsArray.Count() = 0 Then
		ShowMessageBox(, NStr("ru='Отсутствуют регистры, для которых можно выполнить данную операцию.'; en = 'No registers to perform this action.'; pl = 'No registers to perform this action.';de = 'No registers to perform this action.';ro = 'No registers to perform this action.';tr = 'No registers to perform this action.'; es_ES = 'No registers to perform this action.'"));
		Return;
	EndIf;
	
	TotalsParameters = New Structure;
	TotalsParameters.Insert("ProcessTitle",  NStr("ru='Включение использования итогов ...'; en = 'Enable totals usage...'; pl = 'Enable totals usage...';de = 'Enable totals usage...';ro = 'Enable totals usage...';tr = 'Enable totals usage...'; es_ES = 'Enable totals usage...'"));
	TotalsParameters.Insert("AfterProcess",          NStr("ru='Включение использования итогов завершено'; en = 'Enabling usage of totals is completed'; pl = 'Enabling usage of totals is completed';de = 'Enabling usage of totals is completed';ro = 'Enabling usage of totals is completed';tr = 'Enabling usage of totals is completed'; es_ES = 'Enabling usage of totals is completed'"));
	TotalsParameters.Insert("Action",               "SetTotalsUsing");
	TotalsParameters.Insert("RowsArray",            ActionsArray);
	TotalsParameters.Insert("Field",                   "");
	TotalsParameters.Insert("Value1",              True);
	TotalsParameters.Insert("Value2",              Undefined);
	TotalsParameters.Insert("ErrorMessageText", NStr("ru='Не удалось включить использование итогов.'; en = 'Cannot enable totals usage.'; pl = 'Cannot enable totals usage.';de = 'Cannot enable totals usage.';ro = 'Cannot enable totals usage.';tr = 'Cannot enable totals usage.'; es_ES = 'Cannot enable totals usage.'"));
	TotalsParameters.Insert("GroupProcessing",     True);
	
	TotalsControl(TotalsParameters);
	
EndProcedure

&AtClient
Procedure FillAggregatesAndPerformRebuild(Command)
	
	ClearMessages();
	
	ActionsArray = AggregatesByRegisters.FindRows(New Structure("AggregateMode,AgregateUsage", True, True));
	
	If ActionsArray.Count() = 0 Then
		ShowMessageBox(, NStr("ru='Отсутствуют регистры, для которых можно выполнить выбранное действие.'; en = 'No registers to perform the selected action for.'; pl = 'No registers to perform the selected action for.';de = 'No registers to perform the selected action for.';ro = 'No registers to perform the selected action for.';tr = 'No registers to perform the selected action for.'; es_ES = 'No registers to perform the selected action for.'"));
		Return;
	EndIf;
	
	TotalsParameters = New Structure;
	TotalsParameters.Insert("ProcessTitle",  NStr("ru='Перестроение агрегатов ...'; en = 'Rebuilding aggregates ...'; pl = 'Rebuilding aggregates ...';de = 'Rebuilding aggregates ...';ro = 'Rebuilding aggregates ...';tr = 'Rebuilding aggregates ...'; es_ES = 'Rebuilding aggregates ...'"));
	TotalsParameters.Insert("AfterProcess",          NStr("ru='Перестроение агрегатов завершено'; en = 'Aggregates are rebuilt'; pl = 'Aggregates are rebuilt';de = 'Aggregates are rebuilt';ro = 'Aggregates are rebuilt';tr = 'Aggregates are rebuilt'; es_ES = 'Aggregates are rebuilt'"));
	TotalsParameters.Insert("Action",               "RebuildAggregates");
	TotalsParameters.Insert("RowsArray",            ActionsArray);
	TotalsParameters.Insert("Field",                   "");
	TotalsParameters.Insert("Value1",              0);
	TotalsParameters.Insert("Value2",              0);
	TotalsParameters.Insert("ErrorMessageText", NStr("ru='Не удалось перестроить агрегаты.'; en = 'Cannot rebuild aggregates.'; pl = 'Cannot rebuild aggregates.';de = 'Cannot rebuild aggregates.';ro = 'Cannot rebuild aggregates.';tr = 'Cannot rebuild aggregates.'; es_ES = 'Cannot rebuild aggregates.'"));
	TotalsParameters.Insert("GroupProcessing",     True);
	
	ChangeAggregatesClient(TotalsParameters, True);
	
	TotalsParameters = New Structure;
	TotalsParameters.Insert("ProcessTitle",  NStr("ru='Заполнение агрегатов ...'; en = 'Populating aggregates...'; pl = 'Populating aggregates...';de = 'Populating aggregates...';ro = 'Populating aggregates...';tr = 'Populating aggregates...'; es_ES = 'Populating aggregates...'"));
	TotalsParameters.Insert("AfterProcess",          NStr("ru='Заполнение агрегатов завершено'; en = 'Aggregates are populated'; pl = 'Aggregates are populated';de = 'Aggregates are populated';ro = 'Aggregates are populated';tr = 'Aggregates are populated'; es_ES = 'Aggregates are populated'"));
	TotalsParameters.Insert("Action",               "FillAggregates");
	TotalsParameters.Insert("RowsArray",            ActionsArray);
	TotalsParameters.Insert("Field",                   "");
	TotalsParameters.Insert("Value1",              Undefined);
	TotalsParameters.Insert("Value2",              Undefined);
	TotalsParameters.Insert("ErrorMessageText", NStr("ru='Не удалось заполнить агрегаты.'; en = 'Cannot fill in aggregates.'; pl = 'Cannot fill in aggregates.';de = 'Cannot fill in aggregates.';ro = 'Cannot fill in aggregates.';tr = 'Cannot fill in aggregates.'; es_ES = 'Cannot fill in aggregates.'"));
	
	ChangeAggregatesClient(TotalsParameters, False);
	
EndProcedure

&AtClient
Procedure GetOptimalAggregates(Command)
	GetOptimalAggregatesClient();
EndProcedure

&AtClient
Procedure RecalcTotals(Command)
	
	TotalsParameters = New Structure;
	TotalsParameters.Insert("ProcessTitle",  NStr("ru='Пересчет итогов ...'; en = 'Recalculating totals ...'; pl = 'Recalculating totals ...';de = 'Recalculating totals ...';ro = 'Recalculating totals ...';tr = 'Recalculating totals ...'; es_ES = 'Recalculating totals ...'"));
	TotalsParameters.Insert("AfterProcess",          NStr("ru='Пересчет итогов завершен.'; en = 'Totals are recalculated.'; pl = 'Totals are recalculated.';de = 'Totals are recalculated.';ro = 'Totals are recalculated.';tr = 'Totals are recalculated.'; es_ES = 'Totals are recalculated.'"));
	TotalsParameters.Insert("Action",               "RecalcTotals");
	TotalsParameters.Insert("RowsArray",            Items.TotalsList.SelectedRows);
	TotalsParameters.Insert("Field",                   "Description");
	TotalsParameters.Insert("Value1",              False);
	TotalsParameters.Insert("Value2",              Undefined);
	TotalsParameters.Insert("ErrorMessageText", NStr("ru='Не удалось пересчитать итоги.'; en = 'Cannot recalculate totals.'; pl = 'Cannot recalculate totals.';de = 'Cannot recalculate totals.';ro = 'Cannot recalculate totals.';tr = 'Cannot recalculate totals.'; es_ES = 'Cannot recalculate totals.'"));
	
	TotalsControl(TotalsParameters);
	
EndProcedure

&AtClient
Procedure RecalcPresentTotals(Command)
	
	TotalsParameters = New Structure;
	TotalsParameters.Insert("ProcessTitle",  NStr("ru='Пересчет текущих итогов ...'; en = 'Recalculating the current totals ...'; pl = 'Recalculating the current totals ...';de = 'Recalculating the current totals ...';ro = 'Recalculating the current totals ...';tr = 'Recalculating the current totals ...'; es_ES = 'Recalculating the current totals ...'"));
	TotalsParameters.Insert("AfterProcess",          NStr("ru='Пересчет текущих итогов завершен.'; en = 'Current totals recalculation completed.'; pl = 'Current totals recalculation completed.';de = 'Current totals recalculation completed.';ro = 'Current totals recalculation completed.';tr = 'Current totals recalculation completed.'; es_ES = 'Current totals recalculation completed.'"));
	TotalsParameters.Insert("Action",               "RecalcPresentTotals");
	TotalsParameters.Insert("RowsArray",            Items.TotalsList.SelectedRows);
	TotalsParameters.Insert("Field",                   "Description");
	TotalsParameters.Insert("Value1",              False);
	TotalsParameters.Insert("Value2",              Undefined);
	TotalsParameters.Insert("ErrorMessageText", NStr("ru='Не удалось пересчитать текущие итоги.'; en = 'Cannot recalculate current totals.'; pl = 'Cannot recalculate current totals.';de = 'Cannot recalculate current totals.';ro = 'Cannot recalculate current totals.';tr = 'Cannot recalculate current totals.'; es_ES = 'Cannot recalculate current totals.'"));
	
	TotalsControl(TotalsParameters);
	
EndProcedure

&AtClient
Procedure RecalcTotalsForPeriod(Command)
	Handler = New NotifyDescription("RecalculateTotalsForPeriodCompletion", ThisObject);
	Dialog = New StandardPeriodEditDialog;
	Dialog.Period = RegistersRecalculationPeriod;
	Dialog.Show(Handler);
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SetConditionalAppearance()

	ConditionalAppearance.Items.Clear();

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.TotalsAggregatesTotals.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("TotalsList.AggregatesTotals");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = 0;

	Item.Appearance.SetParameterValue("Text", NStr("ru = 'Итоги'; en = 'Totals'; pl = 'Totals';de = 'Totals';ro = 'Totals';tr = 'Totals'; es_ES = 'Totals'"));

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.TotalsAggregatesTotals.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("TotalsList.AggregatesTotals");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = 1;

	Item.Appearance.SetParameterValue("Text", NStr("ru = 'Агрегаты'; en = 'Aggregates'; pl = 'Aggregates';de = 'Aggregates';ro = 'Aggregates';tr = 'Aggregates'; es_ES = 'Aggregates'"));

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.TotalsAggregatesTotals.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("TotalsList.AggregatesTotals");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = 2;

	Item.Appearance.SetParameterValue("Text", NStr("ru = 'Просто итоговый регистр'; en = 'Just total register'; pl = 'Just total register';de = 'Just total register';ro = 'Just total register';tr = 'Just total register'; es_ES = 'Just total register'"));

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.TotalsUseCurrentTotals.Name);

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.TotalsTotalsPeriod.Name);

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.TotalsTotalsSplitting.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("TotalsList.BalanceAndTurnovers");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;

	Item.Appearance.SetParameterValue("BackColor", WebColors.Gainsboro);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.TotalsAggregatesTotals.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("TotalsList.AggregatesTotals");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = 2;

	Item.Appearance.SetParameterValue("BackColor", WebColors.Gainsboro);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.TotalsUseTotals.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("TotalsList.AggregatesTotals");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = 1;

	Item.Appearance.SetParameterValue("BackColor", WebColors.Gainsboro);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.AggregatesByRegisters.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("AggregatesByRegisters.CompositionIsOptimal");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;

	Item.Appearance.SetParameterValue("Font", New Font(WindowsFonts.DefaultGUIFont, , , True, False, False, False, ));

EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Asynchronous dialog box handlers.

&AtClient
Procedure ClearAggregatesByRegistersCompletion(Response, AdditionalParameters) Export
	
	If Response = DialogReturnCode.Yes Then
		
		TotalsParameters = New Structure;
		TotalsParameters.Insert("ProcessTitle",  NStr("ru='Очистка агрегатов ...'; en = 'Clearing aggregates ...'; pl = 'Clearing aggregates ...';de = 'Clearing aggregates ...';ro = 'Clearing aggregates ...';tr = 'Clearing aggregates ...'; es_ES = 'Clearing aggregates ...'"));
		TotalsParameters.Insert("AfterProcess",          NStr("ru='Очистка агрегатов завершена'; en = 'Aggregates are cleared'; pl = 'Aggregates are cleared';de = 'Aggregates are cleared';ro = 'Aggregates are cleared';tr = 'Aggregates are cleared'; es_ES = 'Aggregates are cleared'"));
		TotalsParameters.Insert("Action",               "ClearAggregates");
		TotalsParameters.Insert("RowsArray",            Items.AggregatesByRegisters.SelectedRows);
		TotalsParameters.Insert("Field",                   "Description");
		TotalsParameters.Insert("Value1",              Undefined);
		TotalsParameters.Insert("Value2",              Undefined);
		TotalsParameters.Insert("ErrorMessageText", NStr("ru='Не удалось очистить агрегаты.'; en = 'Cannot clear aggregates.'; pl = 'Cannot clear aggregates.';de = 'Cannot clear aggregates.';ro = 'Cannot clear aggregates.';tr = 'Cannot clear aggregates.'; es_ES = 'Cannot clear aggregates.'"));
		
		ChangeAggregatesClient(TotalsParameters);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure RecalculateTotalsForPeriodCompletion(SelectedValue, AdditionalParameters) Export
	
	If SelectedValue = Undefined Then
		Return;
	EndIf;
	
	RegistersRecalculationPeriod = SelectedValue;
	
	TotalsParameters = New Structure;
	TotalsParameters.Insert("ProcessTitle",  NStr("ru='Пересчет итогов за период...'; en = 'Recalculating totals for the period...'; pl = 'Recalculating totals for the period...';de = 'Recalculating totals for the period...';ro = 'Recalculating totals for the period...';tr = 'Recalculating totals for the period...'; es_ES = 'Recalculating totals for the period...'"));
	TotalsParameters.Insert("AfterProcess",          NStr("ru='Пересчет итогов за период завершен.'; en = 'Totals recalculation for the period completed.'; pl = 'Totals recalculation for the period completed.';de = 'Totals recalculation for the period completed.';ro = 'Totals recalculation for the period completed.';tr = 'Totals recalculation for the period completed.'; es_ES = 'Totals recalculation for the period completed.'"));
	TotalsParameters.Insert("Action",               "RecalcTotalsForPeriod");
	TotalsParameters.Insert("RowsArray",            Items.TotalsList.SelectedRows);
	TotalsParameters.Insert("Field",                   "Description");
	TotalsParameters.Insert("Value1",              RegistersRecalculationPeriod.StartDate);
	TotalsParameters.Insert("Value2",              RegistersRecalculationPeriod.EndDate);
	TotalsParameters.Insert("ErrorMessageText", NStr("ru='Не удалось пересчитать итоги за период.'; en = 'Cannot recalculate totals for the period.'; pl = 'Cannot recalculate totals for the period.';de = 'Cannot recalculate totals for the period.';ro = 'Cannot recalculate totals for the period.';tr = 'Cannot recalculate totals for the period.'; es_ES = 'Cannot recalculate totals for the period.'"));
	
	TotalsControl(TotalsParameters);
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Client

&AtClient
Procedure SetAggregatesListFilter()
	
	CurrentData = Items.AggregatesByRegisters.CurrentData;
	
	If CurrentData <> Undefined Then
		Filter = New FixedStructure("MetadataName", CurrentData.MetadataName);
		NewTitle = Prefix() +  " " + CurrentData.Description;
	Else
		Filter = New FixedStructure("MetadataName", "");
		NewTitle = Prefix();
	EndIf;
	
	Items.AggregatesList.RowFilter = Filter;
	
	If Items.AggregatesList.Title <> NewTitle Then
		Items.AggregatesList.Title = NewTitle;
	EndIf;
	
EndProcedure

&AtClient
Procedure GetOptimalAggregatesClientCompletion(EmptyParameter, ExecutionResult) Export
	
	If ExecutionResult.HasErrors Then
		Raise ExecutionResult.MessageText;
	Else
		ShowUserNotification(NStr("ru = 'Агрегаты успешно получены.'; en = 'Aggregates are received successfully.'; pl = 'Aggregates are received successfully.';de = 'Aggregates are received successfully.';ro = 'Aggregates are received successfully.';tr = 'Aggregates are received successfully.'; es_ES = 'Aggregates are received successfully.'"),,
			 ExecutionResult.MessageText, PictureLib.Done32);
	EndIf;

EndProcedure

&AtClient
Procedure ChangeAggregatesClient(Val TotalsParameters, Val ClearMessages = True)
	
	Result = True;
	If ClearMessages Then
		ClearMessages();
	EndIf;
	Selected = TotalsParameters.RowsArray;
	
	If Selected.Count() = 0 Then
		Return;
	EndIf;
	
	ProcessStep = 100/Selected.Count();
	
	If TotalsParameters.Property("GroupProcessing") Then
		NeedAbortAfterError = ?(TotalsParameters.GroupProcessing, False, InterruptOnError);
	Else
		NeedAbortAfterError = InterruptOnError;
	EndIf;
	
	For Counter = 1 To Selected.Count() Do
		If TypeOf(Selected[Counter - 1]) = Type("Number") Then
			SelectedRow = AggregatesByRegisters.FindByID(Selected[Counter-1]);
		Else
			SelectedRow = Selected[Counter-1];
		EndIf;
		
		AfterErrorMessage = "";
		If Not IsBlankString(TotalsParameters.Field) Then
			AfterErrorMessage = "AggregatesByRegisters[" + Selected[Counter-1] + "]." + TotalsParameters.Field;
		EndIf;
		
		If Not SelectedRow.AggregateMode
			AND Upper(TotalsParameters.Action) <> Upper("SetAggregatesMode") Then
			CommonClient.MessageToUser(
				NStr("ru = 'Операция невозможна в режиме итогов'; en = 'The operation is not allowed in the totals mode'; pl = 'The operation is not allowed in the totals mode';de = 'The operation is not allowed in the totals mode';ro = 'The operation is not allowed in the totals mode';tr = 'The operation is not allowed in the totals mode'; es_ES = 'The operation is not allowed in the totals mode'"),
				,
				AfterErrorMessage);
			Continue;
		EndIf;
		
		Status(TotalsParameters.ProcessTitle, Counter * ProcessStep, SelectedRow.Description);
		
		ServerParameters = New Structure;
		ServerParameters.Insert("RegisterName",        SelectedRow.MetadataName);
		ServerParameters.Insert("Action",           TotalsParameters.Action);
		ServerParameters.Insert("ActionValue1",  TotalsParameters.Value1);
		ServerParameters.Insert("ActionValue2",  TotalsParameters.Value2);
		ServerParameters.Insert("ErrorMessage",  TotalsParameters.ErrorMessageText);
		ServerParameters.Insert("FormField",          AfterErrorMessage);
		ServerParameters.Insert("FormID", UUID);
		Result = ChangeAggregatesServer(ServerParameters);
		
		UserInterruptProcessing();
		
		If Not Result.Success AND NeedAbortAfterError Then
			Break;
		EndIf;
		
	EndDo;
	
	If Upper(TotalsParameters.Action) = Upper("SetAggregatesMode")
		Or Upper(TotalsParameters.Action) = Upper("SetAggregatesUsing") Then
		UpdateTotalsListAtServer();
	EndIf;
	
	UpdateAggregatesByRegistersAtServer();
	
	Status(TotalsParameters.AfterProcess);
	SetAggregatesListFilter();
	
EndProcedure

&AtClient
Procedure TotalsControl(Val TotalsParameters)
	
	Result = True;
	ClearMessages();
	
	Selected = TotalsParameters.RowsArray;
	If Selected.Count() = 0 Then
		Return;
	EndIf;
	
	ProcessStep = 100/Selected.Count();
	Action = Lower(TotalsParameters.Action);
	
	If TotalsParameters.Property("GroupProcessing") Then
		NeedAbortAfterError = ?(TotalsParameters.GroupProcessing, False, InterruptOnError);
	Else
		NeedAbortAfterError = InterruptOnError;
	EndIf;
	
	ProcessedRowsCount = 0;
	HasRegistersToProcess    = False;
	
	For Counter = 1 To Selected.Count() Do
		If TypeOf(Selected[Counter-1]) = Type("Number") Then
			SelectedRow = TotalsList.FindByID(Selected[Counter-1]);
		Else
			SelectedRow = Selected[Counter-1];
		EndIf;
		
		Status(TotalsParameters.ProcessTitle, Counter * ProcessStep, SelectedRow.Description);
		
		If Upper(Action) = Upper("SetTotalsUsing") Then
			If SelectedRow.AggregatesTotals = 1 Then
				Continue;
			EndIf;
			
		ElsIf Upper(Action) = Upper("UseCurrentTotals") Then
			If SelectedRow.AggregatesTotals = 1 Or Not SelectedRow.BalanceAndTurnovers Then
				Continue;
			EndIf;
			
		ElsIf Upper(Action) = Upper("SetTotalPeriod") Then
			If SelectedRow.AggregatesTotals = 1 Or Not SelectedRow.BalanceAndTurnovers Then
				Continue;
			EndIf;
			
		ElsIf Upper(Action) = Upper("SetTotalsSeparation") Then
			If Not SelectedRow.EnableTotalsSplitting Then
				Continue;
			EndIf;
			
		ElsIf Upper(Action) = Upper("RecalcTotals") Then
			If SelectedRow.AggregatesTotals = 1 Then
				Continue;
			EndIf;
			
		ElsIf Upper(Action) = Upper("RecalcTotalsForPeriod") Then
			If SelectedRow.AggregatesTotals = 1 Or Not SelectedRow.BalanceAndTurnovers Then
				Continue;
			EndIf;
			
		ElsIf Upper(Action) = Upper("RecalcPresentTotals") Then
			If Not SelectedRow.BalanceAndTurnovers Then
				Continue;
			EndIf;
		EndIf;
		
		AfterErrorMessage = "";
		If Not IsBlankString(TotalsParameters.Field) Then
			AfterErrorMessage = "TotalsList[" + Selected[Counter - 1] + "]." + TotalsParameters.Field;
		EndIf;
		
		HasRegistersToProcess = True;
		
		Result = SetRegisterParametersAtServer(
			SelectedRow.Type,
			SelectedRow.MetadataName,
			TotalsParameters.Action,
			TotalsParameters.Value1,
			TotalsParameters.Value2,
			AfterErrorMessage,
			TotalsParameters.ErrorMessageText);
		
		UserInterruptProcessing();
		
		If Not Result AND NeedAbortAfterError Then
			Break;
		EndIf;
		
		If Result Then
			ProcessedRowsCount = ProcessedRowsCount + 1;
		EndIf;
	EndDo;
	
	If Not HasRegistersToProcess Then
		ShowMessageBox(, NStr("ru='Отсутствуют регистры, для которых можно выполнить данную операцию.'; en = 'No registers to perform this action.'; pl = 'No registers to perform this action.';de = 'No registers to perform this action.';ro = 'No registers to perform this action.';tr = 'No registers to perform this action.'; es_ES = 'No registers to perform this action.'"));
		Return;
	EndIf;
	
	UpdateTotalsListAtServer();
	
	StateText = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("ru='Пересчитаны (%1 из %2)'; en = 'Recalculated (%1 of %2)'; pl = 'Recalculated (%1 of %2)';de = 'Recalculated (%1 of %2)';ro = 'Recalculated (%1 of %2)';tr = 'Recalculated (%1 of %2)'; es_ES = 'Recalculated (%1 of %2)'"),
		ProcessedRowsCount,
		Selected.Count());
	
	Status(TotalsParameters.AfterProcess + StateText);
	
EndProcedure

&AtClient
Procedure GetOptimalAggregatesClient()
	
	If FullFunctionality Then
		If Items.AggregatesByRegisters.SelectedRows.Count() = 0 Then
			Return;
		EndIf;
	Else
		If AggregatesByRegisters.Count() = 0 Then
			ShowMessageBox(, NStr("ru='Отсутствуют регистры, для которых можно выполнить данную операцию.'; en = 'No registers to perform this action.'; pl = 'No registers to perform this action.';de = 'No registers to perform this action.';ro = 'No registers to perform this action.';tr = 'No registers to perform this action.'; es_ES = 'No registers to perform this action.'"));
			Return;
		EndIf;
	EndIf;
	
	Result = GetOptimalAggregatesServer();
	Handler = New NotifyDescription("GetOptimalAggregatesClientCompletion", ThisObject, Result);
	If Result.CanGet Then
		#If WebClient Then
			GetFile(Result.FileAddress, Result.FileName, True);
			ExecuteNotifyProcessing(Handler, True);
		#Else
			FilesToGet = New Array;
			FilesToGet.Add(New TransferableFileDescription(Result.FileName, Result.FileAddress));
			Extension = Lower(Mid(Result.FileName, StrFind(Result.FileName, ".") + 1));
			If Extension = "zip" Then
				Filter = NStr("ru = 'Архив ZIP (*.%1)|*.%1'; en = 'Archive ZIP (*.%1)|*.%1'; pl = 'Archive ZIP (*.%1)|*.%1';de = 'Archive ZIP (*.%1)|*.%1';ro = 'Archive ZIP (*.%1)|*.%1';tr = 'Archive ZIP (*.%1)|*.%1'; es_ES = 'Archive ZIP (*.%1)|*.%1'");
			ElsIf Extension = "xml" Then
				Filter = NStr("ru = 'Документ XML (*.%1)|*.%1'; en = 'XML document (*.%1)|*.%1'; pl = 'XML document (*.%1)|*.%1';de = 'XML document (*.%1)|*.%1';ro = 'XML document (*.%1)|*.%1';tr = 'XML document (*.%1)|*.%1'; es_ES = 'XML document (*.%1)|*.%1'");
			Else
				Filter = "";
			EndIf;
			Filter = StringFunctionsClientServer.SubstituteParametersToString(Filter, Extension);
			SaveFileDialog = New FileDialog(FileDialogMode.Save);
			SaveFileDialog.FullFileName = Result.FileName;
			SaveFileDialog.Filter = Filter;
			SaveFileDialog.Multiselect = False;
			BeginGettingFiles(Handler, FilesToGet, SaveFileDialog, True);
		#EndIf
	Else
		ExecuteNotifyProcessing(Handler, True);
	EndIf;
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Client, Server

&AtClientAtServerNoContext
Function PeriodEnd(Val Date)
	
	Return EndOfDay(EndOfMonth(Date));
	
EndFunction

&AtClientAtServerNoContext
Function Prefix()
	
	Return NStr("ru = 'Агрегаты регистра'; en = 'Register aggregates'; pl = 'Register aggregates';de = 'Register aggregates';ro = 'Register aggregates';tr = 'Register aggregates'; es_ES = 'Register aggregates'");
	
EndFunction

////////////////////////////////////////////////////////////////////////////////
// Server call, Server

&AtServer
Function GetOptimalAggregatesServer()
	
	Result = New Structure;
	Result.Insert("CanGet", False);
	Result.Insert("FileAddress", "");
	Result.Insert("FileName", "");
	Result.Insert("HasErrors", False);
	Result.Insert("MessageText", "");
	
	If FullFunctionality Then
		Collection = SelectedRows("AggregatesByRegisters");
		MaxRelativeSize = OptimalRelativeSize;
	Else
		Collection = AggregatesByRegisters;
		MaxRelativeSize = 0;
	EndIf;
	Total = Collection.Count();
	Success = 0;
	DetailedErrorText = "";
	
	TempFilesDirectory = CommonClientServer.AddLastPathSeparator(
		GetTempFileName(".TAM")); // Totals & Aggregates Management.
	CreateDirectory(TempFilesDirectory);
	
	FilesToArchive = New ValueList;
	
	// Get aggregates.
	For RowNumber = 1 To Total Do
		
		AccumulationRegisterName = Collection[RowNumber - 1].MetadataName;
		
		RegisterManager = AccumulationRegisters[AccumulationRegisterName];
		Try
			OptimalAggregates = RegisterManager.DetermineOptimalAggregates(MaxRelativeSize);
		Except
			Result.HasErrors = True;
			DetailedErrorText = DetailedErrorText
				+ ?(IsBlankString(DetailedErrorText), "", Chars.LF + Chars.LF)
				+ StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = '%1: %2'; en = '%1: %2'; pl = '%1: %2';de = '%1: %2';ro = '%1: %2';tr = '%1: %2'; es_ES = '%1: %2'"), AccumulationRegisterName, 
					BriefErrorDescription(ErrorInfo()));
			Continue;
		EndTry;
		
		FullFileName = TempFilesDirectory + AccumulationRegisterName + ".xml";
		
		XMLWriter = New XMLWriter();
		XMLWriter.OpenFile(FullFileName);
		XMLWriter.WriteXMLDeclaration();
		XDTOSerializer.WriteXML(XMLWriter, OptimalAggregates);
		XMLWriter.Close();
		
		FilesToArchive.Add(FullFileName, AccumulationRegisterName);
		Success = Success + 1;
		
	EndDo;
	
	// Preparing result to be passed to client.
	If Success > 0 Then
		
		If Success = 1 Then
			ListItem = FilesToArchive[0];
			FullFileName = ListItem.Value;
			ShortFileName = ListItem.Presentation + ".xml";
		Else
			ShortFileName = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'Оптимальные агрегаты регистров накопления %1.zip'; en = 'Optimal aggregates of accumulation register %1.zip'; pl = 'Optimal aggregates of accumulation register %1.zip';de = 'Optimal aggregates of accumulation register %1.zip';ro = 'Optimal aggregates of accumulation register %1.zip';tr = 'Optimal aggregates of accumulation register %1.zip'; es_ES = 'Optimal aggregates of accumulation register %1.zip'"),
				Format(CurrentSessionDate(), "DF=yyyy-MM-dd"));
			FullFileName = TempFilesDirectory + ShortFileName;
			SaveMode = ZIPStorePathMode.StoreRelativePath;
			ProcessingMode = ZIPSubDirProcessingMode.ProcessRecursively;
			ZipFileWriter = New ZipFileWriter(FullFileName);
			For Each ListItem In FilesToArchive Do
				ZipFileWriter.Add(ListItem.Value, SaveMode, ProcessingMode);
			EndDo;
			ZipFileWriter.Write();
		EndIf;
		BinaryData = New BinaryData(FullFileName);
		Result.CanGet = True;
		Result.FileName      = ShortFileName;
		Result.FileAddress    = PutToTempStorage(BinaryData, UUID);
		
	EndIf;
	
	// Clear garbage.
	DeleteFiles(TempFilesDirectory);
	
	// Prepare message texts.
	If Total = 1 Then
		
		// If there is 1 register.
		ListItem = Collection[0];
		RegisterName = ListItem.Description;
		If Result.HasErrors Then
			Result.MessageText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'Не удалось получить оптимальные агрегаты регистра накопления ""%1"" по причине:
					|%2'; 
					|en = 'Cannot receive optimal aggregates of the ""%1"" accumulation register due to:
					|%2'; 
					|pl = 'Cannot receive optimal aggregates of the ""%1"" accumulation register due to:
					|%2';
					|de = 'Cannot receive optimal aggregates of the ""%1"" accumulation register due to:
					|%2';
					|ro = 'Cannot receive optimal aggregates of the ""%1"" accumulation register due to:
					|%2';
					|tr = 'Cannot receive optimal aggregates of the ""%1"" accumulation register due to:
					|%2'; 
					|es_ES = 'Cannot receive optimal aggregates of the ""%1"" accumulation register due to:
					|%2'"), RegisterName, DetailedErrorText);
		Else
			Result.MessageText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = '%1 (регистр накопления)'; en = '%1 (accumulation register)'; pl = '%1 (accumulation register)';de = '%1 (accumulation register)';ro = '%1 (accumulation register)';tr = '%1 (accumulation register)'; es_ES = '%1 (accumulation register)'"),	RegisterName);
		EndIf;
		
	ElsIf Success = 0 Then
		
		// That did not work.
		Result.HasErrors = True;
		Result.MessageText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Не удалось получить оптимальные агрегаты регистров накопления по причине:
			|%1'; 
			|en = 'Cannot receive ideal aggregates of accumulation registers due to:
			|%1'; 
			|pl = 'Cannot receive ideal aggregates of accumulation registers due to:
			|%1';
			|de = 'Cannot receive ideal aggregates of accumulation registers due to:
			|%1';
			|ro = 'Cannot receive ideal aggregates of accumulation registers due to:
			|%1';
			|tr = 'Cannot receive ideal aggregates of accumulation registers due to:
			|%1'; 
			|es_ES = 'Cannot receive ideal aggregates of accumulation registers due to:
			|%1'"), DetailedErrorText);
		
	ElsIf Result.HasErrors Then
		
		// Partially succeeded.
		Result.MessageText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'Агрегаты успешно получены для %1 из %2 регистров.
				|Не получены для %3 по причине:
				|%4'; 
				|en = 'Aggregates are successfully received for %1 of %2 registers.
				|Not received for %3 due to:
				|%4'; 
				|pl = 'Aggregates are successfully received for %1 of %2 registers.
				|Not received for %3 due to:
				|%4';
				|de = 'Aggregates are successfully received for %1 of %2 registers.
				|Not received for %3 due to:
				|%4';
				|ro = 'Aggregates are successfully received for %1 of %2 registers.
				|Not received for %3 due to:
				|%4';
				|tr = 'Aggregates are successfully received for %1 of %2 registers.
				|Not received for %3 due to:
				|%4'; 
				|es_ES = 'Aggregates are successfully received for %1 of %2 registers.
				|Not received for %3 due to:
				|%4'"),
				Success,
				Total,
				Total - Success,
				DetailedErrorText);
		
	Else
		
		// Successfully completed.
		Result.MessageText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Регистры накопления (%1)'; en = 'Accumulation registers (%1)'; pl = 'Accumulation registers (%1)';de = 'Accumulation registers (%1)';ro = 'Accumulation registers (%1)';tr = 'Accumulation registers (%1)'; es_ES = 'Accumulation registers (%1)'"), Success);
			
	EndIf;
	
	Return Result;
EndFunction

&AtServer
Procedure UpdateTotalsListAtServer()
                
         Managers = New Array;
         Managers.Add(AccumulationRegisters);
         Managers.Add(AccountingRegisters);
                
         For Each TableRow In TotalsList Do
                                
         	Manager = Managers[TableRow.Type];
                Register = Manager[TableRow.MetadataName];
                                
                TableRow.UseTotals = Register.GetTotalsUsing();
                TableRow.TotalsSeparation  = Register.GetTotalsSplittingMode();
                                
                If TableRow.BalanceAndTurnovers Then
                                                
			TableRow.UseCurrentTotals = Register.GetPresentTotalsUsing();
                        TableRow.TotalsPeriod             = GetMaxTotalsPeriod(Manager, TableRow.MetadataName);
                        TableRow.AggregatesTotals            = 2;
                                                
             	Else
                                                
                        TableRow.UseCurrentTotals = False;
                        TableRow.TotalsPeriod             = Undefined;
			TableRow.AggregatesTotals            = Register.GetAggregatesMode();
                                                
	                If TableRow.AggregatesTotals Then
                        	TableRow.UseTotals = False;
                	EndIf;
                                                
        	EndIf;
                                
	EndDo;
                
                TotalsGroupTitle = NStr("ru = 'Итоги'; en = 'Totals'; pl = 'Totals';de = 'Totals';ro = 'Totals';tr = 'Totals'; es_ES = 'Totals'");
                TotalsCount = TotalsList.Count();
                If TotalsCount > 0 Then
                                TotalsGroupTitle = TotalsGroupTitle + " (" + Format(TotalsCount, "NG=") + ")";
                EndIf;
                
                Items.TotalsGroup.Title = TotalsGroupTitle;
                
EndProcedure

Function GetMaxTotalsPeriod(Manager, RegisterName)
                
        If Manager = AccumulationRegisters Then
			AccumulationRegisterManager = AccumulationRegisters[RegisterName];
        	MaxPeriod = AccumulationRegisterManager.GetMaxTotalsPeriod();
        ElsIf Manager = AccountingRegisters Then
			AccountingRegisterManager = AccountingRegisters[RegisterName];
        	MaxPeriod = AccountingRegisterManager.GetTotalsPeriod();
        Else
        	Raise NStr("ru = 'Некорректный тип регистра'; en = 'Invalid register type'; pl = 'Invalid register type';de = 'Invalid register type';ro = 'Invalid register type';tr = 'Invalid register type'; es_ES = 'Invalid register type'");
        EndIf;
                
        Return MaxPeriod;

EndFunction

&AtServer
Procedure UpdateAggregatesByRegistersAtServer()
	
	RegisterAggregatesList.Clear();
	
	For Each TableRow In AggregatesByRegisters Do
		
		RegisterManager = AccumulationRegisters[TableRow.MetadataName];
		
		TableRow.AggregateMode         = RegisterManager.GetAggregatesMode();
		TableRow.AgregateUsage = RegisterManager.GetAggregatesUsing();

		Aggregates = RegisterManager.GetAgregates();
		TableRow.BuildDate     = Aggregates.BuildDate;
		TableRow.Size             = Aggregates.Size;
		TableRow.SizeLimit = Aggregates.SizeLimit;
		TableRow.Effect             = Aggregates.Effect;
		
		For Each Aggregate In Aggregates.Aggregates Do
			
			RegisterAggregatesRow = RegisterAggregatesList.Add();
			
			DimensionString = "";
			For Each Dimensions In Aggregate.Dimensions Do
				DimensionString = DimensionString + Dimensions + ", ";
			EndDo;
			DimensionString = Mid(DimensionString, 1, StrLen(DimensionString)-2);
			
			RegisterAggregatesRow.MetadataName = TableRow.MetadataName;
			RegisterAggregatesRow.Periodicity  = String(Aggregate.Periodicity);
			RegisterAggregatesRow.Dimensions      = DimensionString;
			RegisterAggregatesRow.Use  = Aggregate.Use;
			RegisterAggregatesRow.BeginOfPeriod  = Aggregate.BeginOfPeriod;
			RegisterAggregatesRow.EndOfPeriod   = Aggregate.EndOfPeriod;
			RegisterAggregatesRow.Size         = Aggregate.Size;
			
		EndDo;
	EndDo;
	
	RegisterAggregatesList.Sort("Use Desc");
	
	AggregatesGroupTitle = NStr("ru = 'Агрегаты'; en = 'Aggregates'; pl = 'Aggregates';de = 'Aggregates';ro = 'Aggregates';tr = 'Aggregates'; es_ES = 'Aggregates'");
	AggregatesCount = AggregatesByRegisters.Count();
	If AggregatesCount > 0 Then
		AggregatesGroupTitle = AggregatesGroupTitle + " (" + Format(AggregatesCount, "NG=") + ")";
	EndIf;
	
	Items.AggregatesGroup.Title = AggregatesGroupTitle;
	
EndProcedure

&AtServerNoContext
Function SetRegisterParametersAtServer(Val RegisterKind,
                                             Val RegisterName,
                                             Val Action,
                                             Val Value1,
                                             Val Value2, // The default value is Undefined.
                                             Val ErrorField,
                                             Val ErrorMessage)
	
	Managers = New Array;
	Managers.Add(AccumulationRegisters);
	Managers.Add(AccountingRegisters);
	
	Manager = Managers[RegisterKind][RegisterName];
	Action = Lower(Action);
	
	Try
		
		If Upper(Action) = Upper("SetTotalsUsing") Then
			Manager.SetTotalsUsing(Value1);
			
		ElsIf Upper(Action) = Upper("UseCurrentTotals") Then
			Manager.SetPresentTotalsUsing(Value1);
			
		ElsIf Upper(Action) = Upper("SetTotalsSeparation") Then
			Manager.SetTotalsSplittingMode(Value1);
			
		ElsIf Upper(Action) = Upper("SetTotalPeriod") Then
			
			If RegisterKind = 0 Then
				Date = Value1;
				
			ElsIf RegisterKind = 1 Then
				Date = Value2;
			EndIf;
			
			Manager.SetMaxTotalsPeriod(Date);
			
		ElsIf Upper(Action) = Upper("RecalcTotals") Then
			Manager.RecalcTotals();
			
		ElsIf Upper(Action) = Upper("RecalcPresentTotals") Then
			Manager.RecalcPresentTotals();
			
		ElsIf Upper(Action) = Upper("RecalcTotalsForPeriod") Then
			Manager.RecalcTotalsForPeriod(Value1, Value2);
			
		Else
			Raise NStr("ru = 'Неправильное имя параметра'; en = 'Incorrect partner name'; pl = 'Incorrect partner name';de = 'Incorrect partner name';ro = 'Incorrect partner name';tr = 'Incorrect partner name'; es_ES = 'Incorrect partner name'") + "(1): " + Action;
		EndIf;
		
	Except
		
		Common.MessageToUser(
			ErrorMessage
			+ Chars.LF
			+ BriefErrorDescription(ErrorInfo()),
			,
			ErrorField);
		Return False;
		
	EndTry;
	
	Return True;
	
EndFunction

&AtServerNoContext
Function ChangeAggregatesServer(Val ServerParameters)
	
	Result = New Structure;
	Result.Insert("Success", True);
	Result.Insert("ActionValue1", ServerParameters.ActionValue1);
	Result.Insert("FileAddressInTempStorage", "");
	
	RegisterManager = AccumulationRegisters[ServerParameters.RegisterName];
	
	Try
		
		If Upper(ServerParameters.Action) = Upper("SetAggregatesMode") Then
			RegisterManager.SetAggregatesMode(ServerParameters.ActionValue1);
			
		ElsIf Upper(ServerParameters.Action) = Upper("SetAggregatesUsing") Then
			RegisterManager.SetAggregatesUsing(ServerParameters.ActionValue1);
			
		ElsIf Upper(ServerParameters.Action) = Upper("FillAggregates") Then
			RegisterManager.UpdateAggregates(False);
			
		ElsIf Upper(ServerParameters.Action) = Upper("RebuildAggregates") Then
			RegisterManager.RebuildAggregatesUsing(ServerParameters.ActionValue1, ServerParameters.ActionValue2);
			
		ElsIf Upper(ServerParameters.Action) = Upper("ClearAggregates") Then
			RegisterManager.ClearAggregates();
			
		Else
			Raise StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'Неправильное имя параметра: %1'; en = 'Incorrect name of parameter: %1'; pl = 'Incorrect name of parameter: %1';de = 'Incorrect name of parameter: %1';ro = 'Incorrect name of parameter: %1';tr = 'Incorrect name of parameter: %1'; es_ES = 'Incorrect name of parameter: %1'"),
				ServerParameters.Action);
		EndIf;
		
	Except
		
		ErrorMessage = ServerParameters.ErrorMessage + " (" + BriefErrorDescription(ErrorInfo()) + ")";
		Common.MessageToUser(ErrorMessage);
		Result.Success = False;
		
	EndTry;
	
	Return Result;
	
EndFunction

&AtServer
Procedure SetAdvancedMode()
	
	If FullFunctionality Then
		Title        = NStr("ru = 'Управление итогами - полные возможности'; en = 'Totals management - full functionality'; pl = 'Totals management - full functionality';de = 'Totals management - full functionality';ro = 'Totals management - full functionality';tr = 'Totals management - full functionality'; es_ES = 'Totals management - full functionality'");
		HyperlinkText = NStr("ru = 'Часто используемые возможности'; en = 'Frequently used features'; pl = 'Frequently used features';de = 'Frequently used features';ro = 'Frequently used features';tr = 'Frequently used features'; es_ES = 'Frequently used features'");
		Items.Operations.CurrentPage = Items.AdvancedFeatures;
	Else
		Title        = NStr("ru = 'Управление итогами - часто используемые возможности'; en = 'Totals management - frequently used features'; pl = 'Totals management - frequently used features';de = 'Totals management - frequently used features';ro = 'Totals management - frequently used features';tr = 'Totals management - frequently used features'; es_ES = 'Totals management - frequently used features'");
		HyperlinkText = NStr("ru = 'Полные возможности'; en = 'Full functionality'; pl = 'Full functionality';de = 'Full functionality';ro = 'Full functionality';tr = 'Full functionality'; es_ES = 'Full functionality'");
		Items.Operations.CurrentPage = Items.QuickAccess;
	EndIf;
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Server

&AtServer
Function SelectedRows(TableName)
	
	Result = New Array;
	SelectedRows = Items[TableName].SelectedRows;
	Table = ThisObject[TableName];
	For Each ID In SelectedRows Do
		Result.Add(Table.FindByID(ID));
	EndDo;
	Return Result;
	
EndFunction

&AtServer
Procedure ReadInformationOnRegisters()
	
	TotalsList.Clear();
	AggregatesByRegisters.Clear();
	RegisterAggregatesList.Clear();
	
	For Each Register In Metadata.AccountingRegisters Do
		
		If Not AccessRight("TotalsControl", Register) Then
			Continue;
		EndIf;
		
		Presentation = Register.Presentation() + " (" + NStr("ru = 'регистр бухгалтерии'; en = 'accounting register'; pl = 'accounting register';de = 'accounting register';ro = 'accounting register';tr = 'accounting register'; es_ES = 'accounting register'") + ")";
		Picture = PictureLib.AccountingRegister;
		
		TableRow = TotalsList.Add();
		TableRow.Type                       = 1;
		TableRow.MetadataName            = Register.Name;
		TableRow.Picture                  = Picture;
		TableRow.BalanceAndTurnovers           = True;
		TableRow.Description              = Presentation;
		TableRow.EnableTotalsSplitting = Register.EnableTotalsSplitting;
		
	EndDo;
	
	For Each Register In Metadata.AccumulationRegisters Do
		
		Postfix = "";
		If Register.RegisterType = Metadata.ObjectProperties.AccumulationRegisterType.Turnovers Then
			BalanceAndTurnovers = False;
			Postfix = NStr("ru = 'регистр накопления, только обороты'; en = 'accumulation register, turnovers only'; pl = 'accumulation register, turnovers only';de = 'accumulation register, turnovers only';ro = 'accumulation register, turnovers only';tr = 'accumulation register, turnovers only'; es_ES = 'accumulation register, turnovers only'");
		Else
			BalanceAndTurnovers = True;
			Postfix = NStr("ru = 'регистр накопления, остатки и обороты'; en = 'accumulation register, balance and turnovers'; pl = 'accumulation register, balance and turnovers';de = 'accumulation register, balance and turnovers';ro = 'accumulation register, balance and turnovers';tr = 'accumulation register, balance and turnovers'; es_ES = 'accumulation register, balance and turnovers'");
		EndIf;
		
		If Not AccessRight("TotalsControl", Register) Then
			Continue;
		EndIf;
		
		Presentation = Register.Presentation() + " (" + Postfix + ")";
		Picture = PictureLib.AccumulationRegister;
		
		TableRow = TotalsList.Add();
		TableRow.Type                       = 0;
		TableRow.MetadataName            = Register.Name;
		TableRow.Picture                  = Picture;
		TableRow.BalanceAndTurnovers           = BalanceAndTurnovers;
		TableRow.Description              = Presentation;
		TableRow.EnableTotalsSplitting = Register.EnableTotalsSplitting ;
		
	EndDo;
	
	For Each Register In Metadata.AccumulationRegisters Do
		
		If Register.RegisterType <> Metadata.ObjectProperties.AccumulationRegisterType.Turnovers Then
			Continue;
		EndIf;
		
		If Not AccessRight("TotalsControl", Register) Then
			Continue;
		EndIf;
		
		Presentation = Register.Presentation();
		Picture = PictureLib.AccumulationRegister;
		
		Aggregates = Register.Aggregates;
		
		If Aggregates.Count() = 0 Then
			Continue;
		EndIf;
		
		TableRow = AggregatesByRegisters.Add();
		TableRow.MetadataName       = Register.Name;
		TableRow.Picture             = Picture;
		TableRow.Description         = Presentation;
		TableRow.CompositionIsOptimal = True;
		
	EndDo;
	
	TotalsList.Sort("Description Asc");
	AggregatesByRegisters.Sort("Description Asc");
	
EndProcedure

#EndRegion
