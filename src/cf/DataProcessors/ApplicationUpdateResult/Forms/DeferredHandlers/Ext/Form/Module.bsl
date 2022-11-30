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
	
	UpdateInfo = InfobaseUpdateInternal.InfobaseUpdateInfo();
	DeferredUpdateStartTime = UpdateInfo.DeferredUpdateStartTime;
	DeferredUpdateEndTime = UpdateInfo.DeferredUpdateEndTime;
	CurrentSessionNumber = UpdateInfo.SessionNumber;
	FileIB = Common.FileInfobase();
	
	FullUser = Users.IsFullUser(, True);
	If Not FullUser Then
		Items.RunAgainGroup.Visible = False;
		Items.Run.Visible             = False;
		Items.Pause.Visible         = False;
		Items.OrderGroup.Visible         = False;
		Items.ContextMenuPause.Visible = False;
		Items.ContextMenuRun.Visible     = False;
		Items.DeferredHandlersContextMenuOrder.Visible = False;
	ElsIf Common.FileInfobase() Then
		Items.DeferredHandlersContextMenuOrder.Visible = False;
		Items.OrderGroup.Visible         = False;
	EndIf;
	
	If Not FileIB Then
		UpdateInProgress = (UpdateInfo.DeferredUpdateCompletedSuccessfully = Undefined);
	EndIf;
	
	If Not Common.DebugMode()
		Or UpdateInfo.DeferredUpdateCompletedSuccessfully = True Then
		Items.RunSelectedHandler.Visible = False;
		Items.ContextMenuRunSelectedHandler.Visible = False;
	EndIf;
	
	If Not AccessRight("View", Metadata.DataProcessors.EventLog) Then
		Items.DeferredUpdateHyperlink.Visible = False;
	EndIf;
	
	Status = "AllProcedures";
	
	FillProcessedDataTable(UpdateInfo);
	GenerateDeferredHandlerTable(, True);
	
	Items.UpdateProgressHyperlink.Visible = UseParallelMode;
	
	If Common.IsMobileClient() Then
		CommandBarLocation = FormCommandBarLabelLocation.Top;
		Items.ContentGroup.Representation = UsualGroupRepresentation.NormalSeparation;
		Items.Priority.Visible = False;
		Items.Number.Visible = False;
		Items.DeferredHandlersExecutionInterval.Visible = False;
		Items.DeferredHandlersExecutionDuration.Visible = False;
	EndIf;
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	If UpdateInProgress Then
		AttachIdleHandler("UpdateHandlersTable", 15);
	EndIf;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure DeferredHandlersOnActivateRow(Item)
	If Item.CurrentData = Undefined
		Or Not FullUser Then
		Return;
	EndIf;
	
	If Item.CurrentData.Status = "Running" Then
		Items.ContextMenuRun.Enabled = False;
		Items.ContextMenuPause.Enabled = True;
		Items.Run.Enabled = False;
		Items.Pause.Enabled = True;
	ElsIf Item.CurrentData.Status = "Paused" Then
		Items.ContextMenuRun.Enabled = True;
		Items.ContextMenuPause.Enabled = False;
		Items.Run.Enabled = True;
		Items.Pause.Enabled = False;
	Else
		Items.ContextMenuRun.Enabled = False;
		Items.ContextMenuPause.Enabled = False;
		Items.Run.Enabled = False;
		Items.Pause.Enabled = False;
	EndIf;
	
	If Not UpdateInProgress
		AND Item.CurrentData.Status <> "Completed" Then
		Items.RunSelectedHandler.Enabled = True;
		Items.ContextMenuRunSelectedHandler.Enabled = True;
	Else
		Items.RunSelectedHandler.Enabled = False;
		Items.ContextMenuRunSelectedHandler.Enabled = False;
	EndIf;
	
	UpdatePriorityCommandStatuses(Item);
	
EndProcedure

#EndRegion

#Region FormCommandHandlers

&AtClient
Procedure CloseForm(Command)
	Close();
EndProcedure

&AtClient
Procedure RunAgain(Command)
	Notify("DeferredUpdate");
	Close();
EndProcedure

&AtClient
Procedure DeferredUpdateHyperlinkClick(Item)
	
	GetUpdateInfo();
	If ValueIsFilled(DeferredUpdateStartTime) Then
		FormParameters = New Structure;
		FormParameters.Insert("StartDate", DeferredUpdateStartTime);
		If ValueIsFilled(DeferredUpdateEndTime) Then
			FormParameters.Insert("EndDate", DeferredUpdateEndTime);
		EndIf;
		FormParameters.Insert("Session", CurrentSessionNumber);
		
		OpenForm("DataProcessor.EventLog.Form.EventLog", FormParameters);
	Else
		WarningText = NStr("ru = 'Обработка данных еще не выполнялась.'; en = 'Data has not been processed yet.'; pl = 'Dane nie zostały jeszcze przetworzone.';de = 'Daten wurden noch nicht verarbeitet.';ro = 'Datele încă nu au fost procesate.';tr = 'Veri henüz işlenmemiş.'; es_ES = 'Datos aún no se han procesado.'");
		ShowMessageBox(,WarningText);
	EndIf;
	
EndProcedure

&AtClient
Procedure UpdateProgressHyperlinkClick(Item)
	OpenForm("Report.DeferredUpdateProgress.Form");
EndProcedure

&AtClient
Procedure StatusOnChange(Item)
	
	If Status = "HighPriority" Then
		TableRowFilter = New Structure;
		TableRowFilter.Insert("Priority", PictureLib.ExclamationPointRed);
		Items.DeferredHandlers.RowFilter = New FixedStructure(TableRowFilter);
	ElsIf Status = "AllProcedures" Then
		Items.DeferredHandlers.RowFilter = New FixedStructure;
	Else
		TableRowFilter = New Structure;
		TableRowFilter.Insert("Status", Status);
		Items.DeferredHandlers.RowFilter = New FixedStructure(TableRowFilter);
	EndIf;
EndProcedure

&AtClient
Procedure SearchStringOnChange(Item)
	DeferredHandlers.Clear();
	GenerateDeferredHandlerTable(, True);
EndProcedure

&AtClient
Procedure Pause(Command)
	CurrentData = Items.DeferredHandlers.CurrentData;
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	UpdateProcedure = CurrentData.ID;
	
	QuestionText = NStr("ru = 'Остановка дополнительных процедур обработки данных
		|может привести к нестабильной работе или неработоспособности программы.
		|Выполнять отключение рекомендуется в случае обнаружения ошибки
		|в процедуре обработки данных и только после консультации со службой поддержки,
		|т.к. процедуры отработки данных могут зависеть друг от друга.'; 
		|en = 'If you stop an additional data processing procedure,
		|the application might malfunction.
		|It is recommended that you only stop a data processing procedure
		|if you find an error in it and only after technical support approval
		|because data processing procedures might depend on each other.'; 
		|pl = 'Zatrzymanie dodatkowych procedur przetwarzania danych 
		|może doprowadzić do niestabilnej pracy lub niesprawności programu. 
		|Wykonywać odłączenie jest zalecane w przypadku wykrycia błędu 
		|w procedurze przetwarzania danych i tylko po konsultacji ze służbą wsparcia, 
		|ponieważ procedury przetwarzania danych mogą być współzależne.';
		|de = 'Das Stoppen zusätzlicher Datenverarbeitungsverfahren
		|kann dazu führen, dass das Programm instabil oder funktionsunfähig wird.
		|Es wird empfohlen, das Programm zu deaktivieren, wenn ein Fehler
		|im Datenverarbeitungsverfahren festgestellt wird, und nur nach Rücksprache mit dem Support-Team,
		|da die Datenverarbeitungsverfahren voneinander abhängig sein können.';
		|ro = 'Stoparea procedurilor suplimentare de procesare a datelor
		|poate conduce la lucrul instabil sau la incapacitatea de lucru a programului.
		|Recomandăm să executați dezactivarea în cazul depistării erorii
		|în procedura de procesare a datelor și numai după consultarea cu serviciul de suport,
		|deoarece procedurile de procesare a datelor pot fi interdependente.';
		|tr = 'Ek veri işleme prosedürlerini durdurmak, 
		|programın dengesiz çalışmasına veya çalışamamasına neden olabilir. 
		|Veri işleme prosedüründe bir hata bulunursa ve yalnızca 
		|destek ekibine danıştıktan sonra veri işleme 
		|prosedürlerin birbirine bağlı olduğundan, devre dışı bırakılması önerilir.'; 
		|es_ES = 'La interrupción de los procedimientos adicionales del procesamiento se satos
		|puede llevar al funcionamiento inestable o ausencia de funcionamiento del programa.
		|Se recomienda desactivar en el caso de apariencia del error
		|en el procedimiento del procesamiento de datos y solo después de consultarse con el servicio de soporte,
		|porque los procedimientos de procesamientos de datos pueden depender uno de otro.'");
	QuestionButtons = New ValueList;
	QuestionButtons.Add("Yes", "Stop");
	QuestionButtons.Add("No", "Cancel");
	
	Notification = New NotifyDescription("PauseDeferredHandler", ThisObject, UpdateProcedure);
	ShowQueryBox(Notification, QuestionText, QuestionButtons);
	
EndProcedure

&AtClient
Procedure Run(Command)
	CurrentData = Items.DeferredHandlers.CurrentData;
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	UpdateProcedure = CurrentData.ID;
	StartDeferredHandler(UpdateProcedure);
	Notify("DeferredUpdate");
	AttachIdleHandler("UpdateHandlersTable", 15);
	
EndProcedure

&AtClient
Procedure Update(Command)
	UpdateHandlerStatuses(True);
EndProcedure

&AtClient
Procedure OnSchedule(Command)
	
	CurrentRow = Items.DeferredHandlers.CurrentData;
	If CurrentRow = Undefined
		Or Items.OnSchedule.Check Then
		Return;
	EndIf;
	
	ChangePriority("SchedulePriority", CurrentRow.ID, CurrentRow.Queue);
	CurrentRow.PriorityPicture = PictureLib.ExclamationMarkGray;
	CurrentRow.Priority = "Undefined";
	UpdatePriorityCommandStatuses(Items.DeferredHandlers);
	
EndProcedure

&AtClient
Procedure HighPriority(Command)
	CurrentRow = Items.DeferredHandlers.CurrentData;
	If CurrentRow = Undefined
		Or Items.HighPriority.Check Then
		Return;
	EndIf;
	
	ChangePriority("SpeedPriority", CurrentRow.ID, CurrentRow.Queue);
	CurrentRow.PriorityPicture = PictureLib.ExclamationMarkGray;
	CurrentRow.Priority = "Undefined";
	UpdatePriorityCommandStatuses(Items.DeferredHandlers);
	
EndProcedure

&AtClient
Procedure RunSelectedHandler(Command)
	If Items.DeferredHandlers.CurrentData = Undefined
		Or Not FullUser Then
		Return;
	EndIf;
	
	StartSelectedProcedureForDebug(Items.DeferredHandlers.CurrentData.ID);
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure StartSelectedProcedureForDebug(HandlerName)
	
	UpdateInfo = InfobaseUpdateInternal.InfobaseUpdateInfo();
	
	UpdateInfo.DeferredUpdateCompletedSuccessfully = Undefined;
	UpdateInfo.DeferredUpdateEndTime = Undefined;
	For Each TreeRowLibrary In UpdateInfo.HandlersTree.Rows Do
		For Each TreeRowVersion In TreeRowLibrary.Rows Do
			For Each Handler In TreeRowVersion.Rows Do
				If Handler.HandlerName <> HandlerName Then
					Continue;
				EndIf;
				
				Handler.AttemptCount = 0;
				If Handler.Status = "Error" Then
					Handler.ExecutionStatistics.Clear();
					Handler.Status = "NotCompleted";
				EndIf;
			EndDo;
		EndDo;
	EndDo;
	
	For Each UpdateCycle In UpdateInfo.DeferredUpdatePlan Do
		If UpdateCycle.Property("CompletedWithErrors") Then
			UpdateCycle.Delete("CompletedWithErrors");
		EndIf;
	EndDo;
	
	InfobaseUpdateInternal.WriteInfobaseUpdateInfo(UpdateInfo);
	
	InfobaseUpdateInternal.ExecuteDeferredUpdateNow(Undefined);
	
	UpdateInfo = InfobaseUpdateInternal.InfobaseUpdateInfo();
	
EndProcedure

&AtClient
Procedure UpdatePriorityCommandStatuses(Item)
	
	If Item.CurrentData.Priority = "HighPriority" Then
		Items.HighPriority.Check = True;
		Items.HighPriorityContextMenu.Check = True;
		Items.OnSchedule.Check = False;
		Items.NormalPriorityContextMenu.Check = False;
	Else
		Items.OnSchedule.Check = True;
		Items.NormalPriorityContextMenu.Check = True;
		Items.HighPriority.Check = False;
		Items.HighPriorityContextMenu.Check = False;
	EndIf;
	
	If Item.CurrentData.Priority = "Undefined"
		Or Item.CurrentData.Status = "Completed" Then
		Items.OnSchedule.Enabled = False;
		Items.NormalPriorityContextMenu.Enabled = False;
		Items.HighPriority.Enabled = False;
		Items.HighPriorityContextMenu.Enabled = False;
	Else
		Items.OnSchedule.Enabled = True;
		Items.NormalPriorityContextMenu.Enabled = True;
		Items.HighPriority.Enabled = True;
		Items.HighPriorityContextMenu.Enabled = True;
	EndIf;
	
EndProcedure

&AtClient
Procedure PauseDeferredHandler(Result, UpdateProcedure) Export
	If Result = "No" Then
		Return;
	EndIf;
	
	PauseDeferredHandlerAtServer(UpdateProcedure);
EndProcedure

&AtServer
Procedure PauseDeferredHandlerAtServer(UpdateProcedure)
	
	BeginTransaction();
	Try
		Lock = New DataLock;
		Lock.Add("Constant.IBUpdateInfo");
		Lock.Lock();
		
		UpdateInfo = InfobaseUpdateInternal.InfobaseUpdateInfo();
		If UpdateInfo.DeferredUpdateManagement.Property("StopHandlers")
			AND TypeOf(UpdateInfo.DeferredUpdateManagement.StopHandlers) = Type("Array") Then
			StoppedHandlers = UpdateInfo.DeferredUpdateManagement.StopHandlers;
			If StoppedHandlers.Find(UpdateProcedure) = Undefined Then
				StoppedHandlers.Add(UpdateProcedure);
			EndIf;
		Else
			StoppedHandlers = New Array;
			StoppedHandlers.Add(UpdateProcedure);
			UpdateInfo.DeferredUpdateManagement.Insert("StopHandlers", StoppedHandlers);
		EndIf;
		
		InfobaseUpdateInternal.WriteInfobaseUpdateInfo(UpdateInfo);
		
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;
	
EndProcedure

&AtServer
Procedure StartDeferredHandler(UpdateProcedure)
	
	BeginTransaction();
	Try
		Lock = New DataLock;
		Lock.Add("Constant.IBUpdateInfo");
		Lock.Lock();
		
		UpdateInfo = InfobaseUpdateInternal.InfobaseUpdateInfo();
		If UpdateInfo.DeferredUpdateManagement.Property("RunHandlers")
			AND TypeOf(UpdateInfo.DeferredUpdateManagement.RunHandlers) = Type("Array") Then
			RunningHandlers = UpdateInfo.DeferredUpdateManagement.RunHandlers;
			If RunningHandlers.Find(UpdateProcedure) = Undefined Then
				RunningHandlers.Add(UpdateProcedure);
			EndIf;
		Else
			RunningHandlers = New Array;
			RunningHandlers.Add(UpdateProcedure);
			UpdateInfo.DeferredUpdateManagement.Insert("RunHandlers", RunningHandlers);
		EndIf;
		
		InfobaseUpdateInternal.WriteInfobaseUpdateInfo(UpdateInfo);
		
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;
	
EndProcedure

&AtClient
Procedure UpdateHandlersTable()
	UpdateHandlerStatuses(False);
EndProcedure

&AtClient
Procedure UpdateHandlerStatuses(OnCommand)
	
	AllHandlersExecuted = True;
	GenerateDeferredHandlerTable(AllHandlersExecuted);
	If Not OnCommand AND AllHandlersExecuted Then
		DetachIdleHandler("UpdateHandlersTable");
	EndIf;
	
EndProcedure

&AtServer
Procedure GetUpdateInfo()
	UpdateInfo = InfobaseUpdateInternal.InfobaseUpdateInfo();
	DeferredUpdateStartTime = UpdateInfo.DeferredUpdateStartTime;
	DeferredUpdateEndTime = UpdateInfo.DeferredUpdateEndTime;
	CurrentSessionNumber = UpdateInfo.SessionNumber;
EndProcedure

&AtServer
Procedure GenerateDeferredHandlerTable(AllHandlersExecuted = True, InitialFilling = False)
	
	SubsystemsDetails = StandardSubsystemsCached.SubsystemsDetails().ByNames;
	
	HandlersNotExecuted = True;
	UpdateInfo = InfobaseUpdateInternal.InfobaseUpdateInfo();
	ChangingPriority = UpdateInfo.DeferredUpdateManagement.Property("SpeedPriority")
		Or UpdateInfo.DeferredUpdateManagement.Property("SchedulePriority");
	UpdateInProgress = (UpdateInfo.DeferredUpdateCompletedSuccessfully = Undefined);
	
	For Each TreeRowLibrary In UpdateInfo.HandlersTree.Rows Do
		For Each TreeRowVersion In TreeRowLibrary.Rows Do
			If Not UseParallelMode
				AND SubsystemsDetails[TreeRowLibrary.LibraryName].DeferredHandlerExecutionMode = "Parallel"
				AND TreeRowVersion.Rows.Count() > 0 Then
				UseParallelMode = True;
			EndIf;
			
			For Each HandlerRow In TreeRowVersion.Rows Do
				
				If Not IsBlankString(SearchString) Then
					If StrFind(Upper(HandlerRow.Comment), Upper(SearchString)) = 0
						AND StrFind(Upper(HandlerRow.HandlerName), Upper(SearchString)) = 0 Then
						Continue;
					EndIf;
				EndIf;
				AddDeferredHandler(HandlerRow, HandlersNotExecuted, AllHandlersExecuted, InitialFilling, ChangingPriority);
				
			EndDo;
		EndDo;
	EndDo;
	
	If Status = "HighPriority" Then
		TableRowFilter = New Structure;
		TableRowFilter.Insert("Priority", PictureLib.ExclamationPointRed);
		Items.DeferredHandlers.RowFilter = New FixedStructure(TableRowFilter);
	ElsIf Status <> "AllProcedures" Then
		TableRowFilter = New Structure;
		TableRowFilter.Insert("Status", Status);
		Items.DeferredHandlers.RowFilter = New FixedStructure(TableRowFilter);
	EndIf;
	
	If AllHandlersExecuted Or UpdateInProgress Then
		Items.RunAgainGroup.Visible = False;
	EndIf;
	
	If HandlersNotExecuted Then
		Items.NoteText.Title = NStr("ru = 'Рекомендуется запустить невыполненные процедуры обработки данных.'; en = 'It is recommended that you start the data processing procedures that have not been executed.'; pl = 'Zalecane uruchomienie niewykonanych procedur przetwarzania danych.';de = 'Erwägen Sie, ausstehende Datenverarbeitungsverfahren zu starten.';ro = 'Recomandăm să lansați procedurilor neexecutate de procesare a datelor.';tr = 'Gerçekleşmeyen veri işleme prosedürlerini başlatmak önerilir.'; es_ES = 'Considerar el inicio de los procedimientos de procesamiento de los datos pendientes.'");
	Else
		Items.NoteText.Title = NStr("ru = 'Невыполненные процедуры рекомендуется запустить повторно.'; en = 'It is recommended that you restart the procedures that have not been completed.'; pl = 'Zaleca się ponowne uruchomienie procedur aktualizacji, które nie zostały wykonane';de = 'Es wird empfohlen, Aktualisierungsprozeduren, die nicht ausgeführt wurden, neu zu starten';ro = 'Se recomandă să lansați repetat procedurile care nu au fost executate.';tr = 'Gerçekleşmeyen veri işleme prosedürlerini başlatmak önerilir.'; es_ES = 'Se recomienda reiniciar los procedimientos de actualización que no se han ejecutado'");
	EndIf;
	
	ItemNumber = 1;
	For Each TableRow In DeferredHandlers Do
		TableRow.Number = ItemNumber;
		ItemNumber = ItemNumber + 1;
	EndDo;
	
	Items.UpdateInProgress.Visible = UpdateInProgress;
	
EndProcedure

&AtServer
Procedure AddDeferredHandler(HandlerRow, HandlersNotExecuted, AllHandlersExecuted, InitialFilling, ChangingPriority)
	
	If InitialFilling Then
		ListLine = DeferredHandlers.Add();
	Else
		FilterParameters = New Structure;
		FilterParameters.Insert("ID", HandlerRow.HandlerName);
		ListLine = DeferredHandlers.FindRows(FilterParameters)[0];
	EndIf;
	
	ExecutionStatistics = HandlerRow.ExecutionStatistics;
	
	DataProcessingStart = ExecutionStatistics["DataProcessingStart"];
	DataProcessingCompletion = ExecutionStatistics["DataProcessingCompletion"];
	ExecutionDuration = ExecutionStatistics["ExecutionDuration"];
	ExecutionProgress = ExecutionStatistics["ExecutionProgress"];
	
	Progress = Undefined;
	If ExecutionProgress <> Undefined
		AND ExecutionProgress.TotalObjectCount <> 0 
		AND ExecutionProgress.ProcessedObjectsCount <> 0 Then
		Progress = ExecutionProgress.ProcessedObjectsCount / ExecutionProgress.TotalObjectCount * 100;
		Progress = Int(Progress);
		Progress = ?(Progress > 100, 99, Progress);
	EndIf;
	
	ListLine.Queue       = HandlerRow.DeferredProcessingQueue;
	ListLine.ID = HandlerRow.HandlerName;
	ListLine.Handler    = ?(ValueIsFilled(HandlerRow.Comment),
		                           HandlerRow.Comment,
		                           DataProcessingProcedure(HandlerRow.HandlerName));
	
	ExecutionPeriodTemplate =
		NStr("ru = '%1 -
		           |%2'; 
		           |en = '%1 -
		           |%2'; 
		           |pl = '%1 -
		           |%2';
		           |de = '%1 -
		           |%2';
		           |ro = '%1 -
		           |%2';
		           |tr = '%1 -
		           |%2'; 
		           |es_ES = '%1 -
		           |%2'");
	
	UpdateProcedureInformationTemplate = NStr("ru = '%1%2Процедура ""%3"" обработки данных %4.'; en = '%1%2Data processing procedure ""%3"" %4.'; pl = '%1%2Procedura ""%3"" przetwarzania danych %4.';de = '%1%2Verfahren ""%3"" zur Datenverarbeitung %4.';ro = '%1%2Procedura ""%3"" de procesare a datelor %4.';tr = '%1%2 Veri işleme ""%3"" prosedürü %4.'; es_ES = '%1%2Procesamiento ""%3"" del procedimiento de datos %4.'");
	
	ListLine.Status = ?(HandlerRow.Status = "NotCompleted", "NotStarted", HandlerRow.Status);
	If HandlerRow.Status = "Completed" Then
		
		HandlersNotExecuted = False;
		ExecutionStatusPresentation = NStr("ru = 'завершилась успешно'; en = 'is completed'; pl = 'zakończona pomyślnie';de = 'erfolgreich abgeschlossen';ro = 'este finalizată cu succes';tr = 'başarıyla tamamlandı'; es_ES = 'se ha terminado con éxito'");
		ListLine.StatusPresentation = NStr("ru = 'Выполнено'; en = 'Completed'; pl = 'Zakończono';de = 'Abgeschlossen';ro = 'Complet';tr = 'Tamamlandı'; es_ES = 'Finalizado'");
		ListLine.StatusPicture    = PictureLib.Success;
		ListLine.ExecutionDuration = UpdateProcedureDuration(ExecutionDuration);
	ElsIf HandlerRow.Status = "Running" Then
		
		HandlersNotExecuted = False;
		AllHandlersExecuted        = False;
		ListLine.StatusPicture    = New Picture;
		ExecutionStatusPresentation = NStr("ru = 'в данный момент выполняется'; en = 'is running'; pl = 'obecnie trwa';de = 'ist derzeit in Bearbeitung';ro = 'în acest moment are loc executarea';tr = 'şu anda yürütülüyor'; es_ES = 'se está realizando actualmente'");
		If Progress <> Undefined Then
			StatusTemplate = NStr("ru = 'Выполняется (%1%)'; en = 'Running (%1%)'; pl = 'Trwa (%1%)';de = 'Läuft (%1%)';ro = 'Se execută (%1%)';tr = 'Yürütülüyor (%1%)'; es_ES = 'Se está realizando (%1%)'");
			ListLine.StatusPresentation = StringFunctionsClientServer.SubstituteParametersToString(StatusTemplate, Progress)
		Else
			ListLine.StatusPresentation = NStr("ru = 'Выполняется'; en = 'Running'; pl = 'Trwa wykonywanie';de = 'Läuft';ro = 'Are loc executarea';tr = 'Aktif'; es_ES = 'Se está ejecutando'");
		EndIf;
	ElsIf HandlerRow.Status = "Error" Then
		
		HandlersNotExecuted = False;
		AllHandlersExecuted        = False;
		ExecutionStatusPresentation = NStr("ru = 'Процедура ""%1"" обработки данных завершилась с ошибкой:'; en = 'Data processing procedure ""%1"" completed with error:'; pl = 'Procedura ""%1"" przetwarzania danych zakończona z błędem:';de = 'Die Datenverarbeitungsprozedur ""%1"" wurde mit einem Fehler beendet:';ro = 'Procedura ""%1"" de procesare a datelor s-a soldat cu eroare:';tr = 'Veri işleme prosedürü %1"""" başarıyla tamamlandı:'; es_ES = 'Procedimiento ""%1"" de procesamiento de datos se ha finalizado con error:'") + Chars.LF + Chars.LF;
		ExecutionStatusPresentation = StringFunctionsClientServer.SubstituteParametersToString(ExecutionStatusPresentation, HandlerRow.HandlerName);
		ListLine.UpdateProcessInformation = ExecutionStatusPresentation + HandlerRow.ErrorInfo;
		ListLine.StatusPresentation = NStr("ru = 'Ошибка'; en = 'Error'; pl = 'Błąd';de = 'Fehler';ro = 'Eroare';tr = 'Hata'; es_ES = 'Error'");
		ListLine.StatusPicture = PictureLib.Stop;
		ListLine.ExecutionDuration = UpdateProcedureDuration(ExecutionDuration);
	ElsIf HandlerRow.Status = "Paused" Then
		
		HandlersNotExecuted = False;
		AllHandlersExecuted        = False;
		ExecutionStatusPresentation = NStr("ru = 'остановлена администратором'; en = 'is paused by administrator'; pl = 'zatrzymana przez administratora';de = 'vom Administrator gestoppt';ro = 'stopată de administrator';tr = 'yönetici tarafından durduruldu'; es_ES = 'parado por administrador'");
		ListLine.StatusPresentation = NStr("ru = 'Остановлено'; en = 'Paused'; pl = 'Zatrzymano';de = 'Gestoppt';ro = 'Stopat';tr = 'Durduruldu'; es_ES = 'Parado'");
		ListLine.StatusPicture    = PictureLib.StopSign;
	Else
		
		AllHandlersExecuted        = False;
		ExecutionStatusPresentation = NStr("ru = 'еще не выполнялась'; en = 'has not started yet'; pl = 'jeszcze nie była wykonywana';de = 'noch nicht aufgeführt';ro = 'încă nu a fost executată';tr = 'henüz yürütülmedi'; es_ES = 'todavía no se ha ejecutado'");
		ListLine.StatusPresentation = NStr("ru = 'Не выполнялась'; en = 'Not started'; pl = 'Nie było wykonywane';de = 'Nicht ausgeführt';ro = 'Nu a fost executată';tr = 'Yürütülmedi'; es_ES = 'No ejecutado'");
	EndIf;
	
	If Not IsBlankString(HandlerRow.Comment) Then
		Indent = Chars.LF + Chars.LF;
	Else
		Indent = "";
	EndIf;
	
	If ChangingPriority AND ListLine.Priority = "Undefined" Then
		// The priority for this string does not change.
	ElsIf HandlerRow.Priority = "HighPriority" Then
		ListLine.PriorityPicture = PictureLib.ExclamationPointRed;
		ListLine.Priority = HandlerRow.Priority;
	Else
		ListLine.PriorityPicture = New Picture;
		ListLine.Priority = "OnSchedule";
	EndIf;
	
	If HandlerRow.Status <> "Error" Then
		ListLine.UpdateProcessInformation = StringFunctionsClientServer.SubstituteParametersToString(
			UpdateProcedureInformationTemplate,
			HandlerRow.Comment,
			Indent,
			HandlerRow.HandlerName,
			ExecutionStatusPresentation);
	EndIf;
	
	ListLine.ExecutionInterval = StringFunctionsClientServer.SubstituteParametersToString(
		ExecutionPeriodTemplate,
		String(DataProcessingStart),
		String(DataProcessingCompletion));
	
EndProcedure

&AtServer
Function DataProcessingProcedure(HandlerName)
	HandlerNameArray = StrSplit(HandlerName, ".");
	ArrayItemCount = HandlerNameArray.Count();
	Return HandlerNameArray[ArrayItemCount-1];
EndFunction

&AtServer
Function UpdateProcedureDuration(ExecutionDuration)
	
	If ExecutionDuration = Undefined Then
		Return "";
	EndIf;
	
	SecondsTemplate = NStr("ru = '%1 сек.'; en = '%1 sec'; pl = '%1 sek.';de = ' %1 Sek.';ro = '%1 sec.';tr = '%1 san.'; es_ES = '%1 seg.'");
	MinutesTemplate = NStr("ru = '%1 мин. %2 сек.'; en = '%1 min %2 sec'; pl = '%1 min %2 sek.';de = '%1 min %2 s';ro = '%1 min %2 sec';tr = '%1 dak %2 san'; es_ES = '%1 minutos %2 segundos'");
	HoursTemplate = NStr("ru = '%1 ч. %2 мин.'; en = '%1 h %2 min'; pl = '%1 h %2 min';de = '%1 h %2 min';ro = '%1 h %2 min';tr = '%1 sa %2 dk'; es_ES = '%1 horas %2 minutos'");
	
	DurationInSeconds = ExecutionDuration/1000;
	DurationInSeconds = Round(DurationInSeconds);
	If DurationInSeconds < 1 Then
		Return NStr("ru = 'менее секунды'; en = 'less than a second'; pl = 'mniej sekundy';de = 'weniger als eine Sekunde';ro = 'mai puțin de o secundă';tr = 'saniyeden az'; es_ES = 'menos de segundo'")
	ElsIf DurationInSeconds < 60 Then
		Return StringFunctionsClientServer.SubstituteParametersToString(SecondsTemplate, DurationInSeconds);
	ElsIf DurationInSeconds < 3600 Then
		Minutes = DurationInSeconds/60;
		Seconds = (Minutes - Int(Minutes))*60;
		Return StringFunctionsClientServer.SubstituteParametersToString(MinutesTemplate, Int(Minutes), Int(Seconds));
	Else
		Hours = DurationInSeconds/60/60;
		Minutes = (Hours - Int(Hours))*60;
		Return StringFunctionsClientServer.SubstituteParametersToString(HoursTemplate, Int(Hours), Int(Minutes));
	EndIf;
	
EndFunction

&AtServer
Procedure FillProcessedDataTable(UpdateInfo)
	
	HandlerObjects = New Map;
	
	SourceData = UpdateInfo.DataToProcess;
	TableProcessedData = FormAttributeToValue("DataToProcess");
	For Each HandlerInformation In SourceData Do
		ObjectsList = New ValueList;
		Handler     = HandlerInformation.Key;
		ProcessedObjectsByQueues = HandlerInformation.Value.HandlerData;
		For Each ObjectToProcess In ProcessedObjectsByQueues Do
			ObjectName = ObjectToProcess.Key;
			Queue    = ObjectToProcess.Value.Queue;
			TableRow = TableProcessedData.Add();
			TableRow.Handler = Handler;
			TableRow.ObjectName = ObjectName;
			TableRow.Queue    = Queue;
			
			ObjectsList.Add(ObjectName);
		EndDo;
		HandlerObjects.Insert(Handler, ObjectsList);
	EndDo;
	
	HandlerObjectsAddress = PutToTempStorage(HandlerObjects, UUID);
	ValueToFormAttribute(TableProcessedData, "DataToProcess");
	
EndProcedure

&AtServer
Function HandlersToChange(Handler, ProcessedDataTable, Queue, SpeedPriority, ObjectsList = Undefined)
	
	HandlerObjects = GetFromTempStorage(HandlerObjectsAddress);
	If ObjectsList = Undefined Then
		ObjectsList = HandlerObjects[Handler];
		If ObjectsList = Undefined Then
			Return Undefined;
		EndIf;
	EndIf;
	
	HandlersToChange = New Array;
	HandlersToChange.Add(Handler);
	
	Query = New Query;
	Query.Text = 
		"SELECT
		|	ttObjectsToProcess.Handler,
		|	ttObjectsToProcess.ObjectName,
		|	ttObjectsToProcess.Queue
		|INTO Table
		|FROM
		|	&ttObjectsToProcess AS ttObjectsToProcess
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	Table.Handler,
		|	Table.ObjectName,
		|	Table.Queue
		|FROM
		|	Table AS Table
		|WHERE
		|	Table.ObjectName IN(&ObjectsList)
		|	AND Table.Queue < &QueueNumber";
	If Not SpeedPriority Then
		Query.Text = StrReplace(Query.Text, "AND Table.Queue < &QueueNumber", "AND Table.Queue > &QueueNumber");
	EndIf;
	Query.SetParameter("ObjectsList", ObjectsList);
	Query.SetParameter("QueueNumber", Queue);
	Query.SetParameter("ttObjectsToProcess", ProcessedDataTable);
	
	Result = Query.Execute().Unload();
	
	CurrentHandler = Undefined;
	For Each Row In Result Do
		If CurrentHandler = Row.Handler Then
			Continue;
		EndIf;
		
		If Row.Queue = 1 Then
			HandlersToChange.Add(Row.Handler);
			CurrentHandler = Row.Handler;
			Continue;
		EndIf;
		NewObjectList = New ValueList;
		CurrentHandlerObjectList = HandlerObjects[Row.Handler];
		For Each CurrentHandlerObject In CurrentHandlerObjectList Do
			If ObjectsList.FindByValue(CurrentHandlerObject) = Undefined Then
				NewObjectList.Add(CurrentHandlerObject);
			EndIf;
		EndDo;
		
		If NewObjectList.Count() = 0 Then
			HandlersToChange.Add(Row.Handler);
			CurrentHandler = Row.Handler;
			Continue;
		EndIf;
		NewArrayOfHandlersToChange = HandlersToChange(Row.Handler,
			ProcessedDataTable,
			Row.Queue,
			SpeedPriority,
			NewObjectList);
		
		For Each ArrayElement In NewArrayOfHandlersToChange Do
			If HandlersToChange.Find(ArrayElement) = Undefined Then
				HandlersToChange.Add(ArrayElement);
			EndIf;
		EndDo;
		
		CurrentHandler = Row.Handler;
	EndDo;
	
	Return HandlersToChange;
	
EndFunction

&AtServer
Procedure ChangePriority(Priority, Handler, Queue)
	
	ProcessedDataTable = FormAttributeToValue("DataToProcess");
	If Queue > 1 Then
		HandlersToChange = HandlersToChange(Handler,
			ProcessedDataTable,
			Queue,
			Priority = "SpeedPriority");
		If HandlersToChange = Undefined Then
			HandlersToChange = New Array;
			HandlersToChange.Add(Handler);
		EndIf;
	Else
		HandlersToChange = New Array;
		HandlersToChange.Add(Handler);
	EndIf;
	
	BeginTransaction();
	Try
		Lock = New DataLock;
		Lock.Add("Constant.IBUpdateInfo");
		Lock.Lock();
		
		UpdateInfo = InfobaseUpdateInternal.InfobaseUpdateInfo();
		
		If UpdateInfo.DeferredUpdateManagement.Property(Priority)
			AND TypeOf(UpdateInfo.DeferredUpdateManagement[Priority]) = Type("Array") Then
			Collection = UpdateInfo.DeferredUpdateManagement[Priority];
			For Each HandlerToChange In HandlersToChange Do
				If Collection.Find(HandlerToChange) = Undefined Then
					Collection.Add(HandlerToChange);
				EndIf;
			EndDo;
		Else
			UpdateInfo.DeferredUpdateManagement.Insert(Priority, HandlersToChange);
		EndIf;
		
		InfobaseUpdateInternal.WriteInfobaseUpdateInfo(UpdateInfo);
		
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;
	
EndProcedure

#EndRegion