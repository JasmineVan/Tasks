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
	
	If ValueIsFilled(Parameters.BusinessProcess) Then
		BusinessProcess = Parameters.BusinessProcess;
	EndIf;
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	UpdateFlowchart();
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure BusinessProcessOnChange(Item)
	UpdateFlowchart();
EndProcedure

&AtClient
Procedure FlowchartChoice(Item)
	OpenRoutePointTasksList();
EndProcedure

#EndRegion

#Region FormCommandHandlers

&AtClient
Procedure RefreshExecute(Command)
	UpdateFlowchart();   
EndProcedure

&AtClient
Procedure TasksComplete(Command)
	OpenRoutePointTasksList();
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure UpdateFlowchart()
	
	If ValueIsFilled(BusinessProcess) Then
		Flowchart = BusinessProcess.GetObject().GetFlowchart();
	ElsIf BusinessProcess <> Undefined Then
		Flowchart = BusinessProcesses[BusinessProcess.Metadata().Name].GetFlowchart();
		Return;
	Else
		Flowchart = New GraphicalSchema;
		Return;
	EndIf;
	
	HasState = BusinessProcess.Metadata().Attributes.Find("State") <> Undefined;
	BusinessProcessProperties = Common.ObjectAttributesValues(
		BusinessProcess, "Author,Date,CompletedOn,Completed,Started" 
		+ ?(HasState, ",State", ""));
	FillPropertyValues(ThisObject, BusinessProcessProperties);
	If BusinessProcessProperties.Completed Then
		Status = NStr("ru = 'Завершен'; en = 'Completed'; pl = 'Completed';de = 'Completed';ro = 'Completed';tr = 'Completed'; es_ES = 'Completed'");
		Items.StatusGroup.CurrentPage = Items.CompletedGroup;
	ElsIf BusinessProcessProperties.Started Then
		Status = NStr("ru = 'Стартован'; en = 'Started'; pl = 'Started';de = 'Started';ro = 'Started';tr = 'Started'; es_ES = 'Started'");
		Items.StatusGroup.CurrentPage = Items.NotCompletedGroup;
	Else	
		Status = NStr("ru = 'Не стартован'; en = 'Not started'; pl = 'Not started';de = 'Not started';ro = 'Not started';tr = 'Not started'; es_ES = 'Not started'");
		Items.StatusGroup.CurrentPage = Items.NotCompletedGroup;
	EndIf;
	If HasState Then
		Status = Status + ", " + Lower(State);
	EndIf;
	
EndProcedure

&AtClient
Procedure OpenRoutePointTasksList()

#If WebClient OR MobileClient Then
	ShowMessageBox(,NStr("ru = 'Для корректной работы необходим режим тонкого или толстого клиента.'; en = 'Thin or thick client mode is required.'; pl = 'Thin or thick client mode is required.';de = 'Thin or thick client mode is required.';ro = 'Thin or thick client mode is required.';tr = 'Thin or thick client mode is required.'; es_ES = 'Thin or thick client mode is required.'"));
	Return;
#EndIf
	ClearMessages();
	CurItem = Items.Flowchart.CurrentItem;

	If Not ValueIsFilled(BusinessProcess) Then
		CommonClient.MessageToUser(
			NStr("ru = 'Необходимо указать бизнес-процесс.'; en = 'Specify the business process.'; pl = 'Specify the business process.';de = 'Specify the business process.';ro = 'Specify the business process.';tr = 'Specify the business process.'; es_ES = 'Specify the business process.'"),,
			"BusinessProcess");
		Return;
	EndIf;
	
	If CurItem = Undefined 
		Or	NOT (TypeOf(CurItem) = Type("GraphicalSchemaItemActivity")
		Or TypeOf(CurItem) = Type("GraphicalSchemaItemSubBusinessProcess")) Then
		
		CommonClient.MessageToUser(
			NStr("ru = 'Для просмотра списка задач необходимо выбрать точку действия или вложенный бизнес-процесс карты маршрута.'; en = 'To view the task list, select an action point or a nested business process of the flowchart.'; pl = 'To view the task list, select an action point or a nested business process of the flowchart.';de = 'To view the task list, select an action point or a nested business process of the flowchart.';ro = 'To view the task list, select an action point or a nested business process of the flowchart.';tr = 'To view the task list, select an action point or a nested business process of the flowchart.'; es_ES = 'To view the task list, select an action point or a nested business process of the flowchart.'"),,
			"Flowchart");
		Return;
	EndIf;

	FormHeader = NStr("ru = 'Задачи по точке маршрута бизнес-процесса'; en = 'Business process route point tasks'; pl = 'Business process route point tasks';de = 'Business process route point tasks';ro = 'Business process route point tasks';tr = 'Business process route point tasks'; es_ES = 'Business process route point tasks'");
	
	FormParameters = New Structure;
	FormParameters.Insert("Filter", New Structure("BusinessProcess,RoutePoint", BusinessProcess, CurItem.Value));
	FormParameters.Insert("FormCaption", FormHeader);
	FormParameters.Insert("ShowTasks", 0);
	FormParameters.Insert("FiltersVisibility", False);
	FormParameters.Insert("OwnerWindowLock", FormWindowOpeningMode.LockOwnerWindow);
	FormParameters.Insert("Task", String(CurItem.Value));
	FormParameters.Insert("BusinessProcess", String(BusinessProcess));
	OpenForm("Task.PerformerTask.ListForm", FormParameters, ThisObject, BusinessProcess);

EndProcedure

#EndRegion
