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
	If Not TotalsAndAggregatesManagementIntenal.MustMoveTotalsBorder() Then
		Cancel = True; // The period is already set in the session of another user.
		Return;
	EndIf;
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	TimeConsumingOperation = TimeConsumingOperationRunServer(UUID);
	
	WaitSettings = TimeConsumingOperationsClient.IdleParameters(ThisObject);
	WaitSettings.OutputIdleWindow = False;
	
	Handler = New NotifyDescription("TimeConsumingOperationCompletionClient", ThisObject);
	
	TimeConsumingOperationsClient.WaitForCompletion(TimeConsumingOperation, Handler, WaitSettings);
EndProcedure

#EndRegion

#Region Private

&AtServerNoContext
Function TimeConsumingOperationRunServer(UUID)
	MethodName = "DataProcessors.ShiftTotalsBoundary.ExecuteCommand";
	
	StartSettings = TimeConsumingOperations.BackgroundExecutionParameters(UUID);
	StartSettings.BackgroundJobDescription = NStr("ru = 'Итоги и агрегаты: Ускорение проведения документов и формирования отчетов'; en = 'Totals and aggregates: Accelerated document posting and report generation'; pl = 'Totals and aggregates: Accelerated document posting and report generation';de = 'Totals and aggregates: Accelerated document posting and report generation';ro = 'Totals and aggregates: Accelerated document posting and report generation';tr = 'Totals and aggregates: Accelerated document posting and report generation'; es_ES = 'Totals and aggregates: Accelerated document posting and report generation'");
	StartSettings.WaitForCompletion = 0;
	
	Return TimeConsumingOperations.ExecuteInBackground(MethodName, Undefined, StartSettings);
EndFunction

&AtClient
Procedure TimeConsumingOperationCompletionClient(Operation, AdditionalParameters) Export
	
	Handler = New NotifyDescription("TimeConsumingOperationAfterOutputResult", ThisObject);
	If Operation = Undefined Then
		ExecuteNotifyProcessing(Handler, False);
	Else
		If Operation.Status = "Completed" Then
			ShowUserNotification(NStr("ru = 'Оптимизация успешно завершена'; en = 'Optimization completed successfully'; pl = 'Optimization completed successfully';de = 'Optimization completed successfully';ro = 'Optimization completed successfully';tr = 'Optimization completed successfully'; es_ES = 'Optimization completed successfully'"),,, PictureLib.Done32);
			ExecuteNotifyProcessing(Handler, True);
		Else
			Raise Operation.BriefErrorPresentation;
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure TimeConsumingOperationAfterOutputResult(Result, AdditionalParameters) Export
	If OnCloseNotifyDescription <> Undefined Then
		ExecuteNotifyProcessing(OnCloseNotifyDescription, Result); // Bypass call characteristic from OnOpen.
	EndIf;
	If IsOpen() Then
		Close(Result);
	EndIf;
EndProcedure

#EndRegion