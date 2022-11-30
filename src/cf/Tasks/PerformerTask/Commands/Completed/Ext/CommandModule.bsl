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
	
	If CommandParameter = Undefined Then
		ShowMessageBox(,NStr("ru = 'Не выбраны задачи.'; en = 'Tasks are not selected.'; pl = 'Tasks are not selected.';de = 'Tasks are not selected.';ro = 'Tasks are not selected.';tr = 'Tasks are not selected.'; es_ES = 'Tasks are not selected.'"));
		Return;
	EndIf;
		
	ClearMessages();
	For Each Task In CommandParameter Do
		BusinessProcessesAndTasksServerCall.ExecuteTask(Task, True);
		ShowUserNotification(
			NStr("ru = 'Задача выполнена'; en = 'The task is completed'; pl = 'The task is completed';de = 'The task is completed';ro = 'The task is completed';tr = 'The task is completed'; es_ES = 'The task is completed'"),
			GetURL(Task),
			String(Task));
	EndDo;
	Notify("Write_PerformerTask", New Structure("Executed", True), CommandParameter);
	
EndProcedure

#EndRegion