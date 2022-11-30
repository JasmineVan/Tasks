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
	
	DaySchedule = Parameters.WorkSchedule;
	
	For Each IntervalDetails In DaySchedule Do
		FillPropertyValues(WorkSchedule.Add(), IntervalDetails);
	EndDo;
	WorkSchedule.Sort("BeginTime");
	
	If Common.IsMobileClient() Then
		CommandBarLocation = FormCommandBarLabelLocation.Auto;
		Items.FormCancel.Visible = False;
	EndIf;
	
EndProcedure

&AtClient
Procedure BeforeClose(Cancel, Exit, WarningText, StandardProcessing)
	
	Notification = New NotifyDescription("SelectAndClose", ThisObject);
	CommonClient.ShowFormClosingConfirmation(Notification, Cancel, Exit);
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure WorkScheduleOnEditEnd(Item, NewRow, CancelEdit)
		
	If CancelEdit Then
		Return;
	EndIf;
	
	WorkSchedulesClient.RestoreCollectionRowOrderAfterEditing(WorkSchedule, "BeginTime", Item.CurrentData);
	
EndProcedure

#EndRegion

#Region FormCommandHandlers

&AtClient
Procedure OK(Command)
	
	SelectAndClose();
	
EndProcedure

&AtClient
Procedure Cancel(Command)
	
	Modified = False;
	NotifyChoice(Undefined);
	
EndProcedure

#EndRegion

#Region Private

&AtClient
Function DaySchedule()
	
	Cancel = False;
	
	DaySchedule = New Array;
	
	EndDay = Undefined;
	
	For Each ScheduleString In WorkSchedule Do
		RowIndex = WorkSchedule.IndexOf(ScheduleString);
		If ScheduleString.BeginTime > ScheduleString.EndTime 
			AND ValueIsFilled(ScheduleString.EndTime) Then
			CommonClient.MessageToUser(
				NStr("ru = 'Время начала больше времени окончания'; en = 'The start time is greater than the end time.'; pl = 'Czas rozpoczęcia jest późniejszy niż czas zakończenia.';de = 'Startzeit ist größer als die Endzeit.';ro = 'Data începutului este mai mare decât data sfârșitului';tr = 'Başlangıç zamanı bitiş zamanından daha büyüktür.'; es_ES = 'Hora inicial es mayor que la hora final.'"), ,
				StringFunctionsClientServer.SubstituteParametersToString("WorkSchedule[%1].EndTime", RowIndex), ,
				Cancel);
		EndIf;
		If ScheduleString.BeginTime = ScheduleString.EndTime Then
			CommonClient.MessageToUser(
				NStr("ru = 'Длительность интервала не определена'; en = 'The interval length is not specified.'; pl = 'Nie określono czasu trwania interwału';de = 'Die Intervalldauer ist nicht angegeben';ro = 'Durata intervalului nu este specificată';tr = 'Aralık süresi belirtilmedi'; es_ES = 'Duración del intervalo no está especificada'"), ,
				StringFunctionsClientServer.SubstituteParametersToString("WorkSchedule[%1].EndTime", RowIndex), ,
				Cancel);
		EndIf;
		If EndDay <> Undefined Then
			If EndDay > ScheduleString.BeginTime 
				Or Not ValueIsFilled(EndDay) Then
				CommonClient.MessageToUser(
					NStr("ru = 'Обнаружены пересекающиеся интервалы'; en = 'Overlapping intervals are detected.'; pl = 'Wykryto nakładające się interwały';de = 'Überlappende Intervalle werden erkannt';ro = 'Sunt detectate intervale suprapuse';tr = 'Çakışan aralıklar tespit edildi'; es_ES = 'Intervalos de superposición se han detectado'"), ,
					StringFunctionsClientServer.SubstituteParametersToString("WorkSchedule[%1].BeginTime", RowIndex), ,
					Cancel);
			EndIf;
		EndIf;
		EndDay = ScheduleString.EndTime;
		DaySchedule.Add(New Structure("BeginTime, EndTime", ScheduleString.BeginTime, ScheduleString.EndTime));
	EndDo;
	
	If Cancel Then
		Return Undefined;
	EndIf;
	
	Return DaySchedule;
	
EndFunction

&AtClient
Procedure SelectAndClose(Result = Undefined, AdditionalParameters = Undefined) Export
	
	DaySchedule = DaySchedule();
	If DaySchedule = Undefined Then
		Return;
	EndIf;
	
	Modified = False;
	NotifyChoice(New Structure("WorkSchedule", DaySchedule));
	
EndProcedure

#EndRegion
