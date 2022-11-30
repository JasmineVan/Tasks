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
	
	If Object.Ref.IsEmpty() Then
		Schedule = New JobSchedule;
	EndIf;
	
EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)
	
	ID = Object.Ref.UUID();
	
	Schedule = CurrentObject.Schedule.Get();
	
EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	CurrentObject.Schedule = New ValueStorage(Schedule);
	
EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)
	
	ID = Object.Ref.UUID();
	
EndProcedure

&AtClient
Procedure BeforeClose(Cancel, Exit, WarningText, StandardProcessing)
	
	If Not Exit Then
		UnlockFormDataForEdit();
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandHandlers

&AtClient
Procedure OpenJobSchedule(Command)
	
	Dialog = New ScheduledJobDialog(Schedule);
	Dialog.Show(New NotifyDescription("OpenScheduleEnd", ThisObject));
	
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure OpenScheduleEnd(NewSchedule, CurrentData) Export

	If NewSchedule = Undefined Then
		Return;
	EndIf;
	
	Schedule = NewSchedule;
	LockFormDataForEdit();
	Modified = True;
	
	ShowUserNotification(NStr("ru = 'Перепланирование'; en = 'Rescheduling'; pl = 'Ponowne planowanie';de = 'Neuplanung';ro = 'Replanificare';tr = 'Yeniden planlama'; es_ES = 'Reprogramación'"), , NStr("ru = 'Новое расписание будет учтено при
		|следующем выполнении задания по 
		|шаблону или обновлении версии ИБ'; 
		|en = 'The new schedule will take effect
		|the next time you perform the job
		|using template or update infobase version'; 
		|pl = 'Nowy harmonogram zostanie
		|uwzględniony podczas wykonania następnego zadania
		|według szablonu lub aktualizacji wersji bazy informacyjnej.';
		|de = 'Der neue Zeitplan wird
		| bei der folgenden Aufgabenleistung 
		|durch Vorlage oder Update der IB-Version berücksichtigt';
		|ro = 'Orarul nou va fi luat în considerare la
		|următoarea executare a sarcinii conform
		|șablonului la actualizarea versiunii BI';
		|tr = 'Yeni çizelge aşağıdaki şablona göre görev 
		|performansında veya VT
		| versiyonu güncellenmesinde dikkate alınacaktır.'; 
		|es_ES = 'Nuevo horario se
		|considerará durante la realización
		|de la siguiente tarea según el modelo, o la actualización de la versión de la infobase'"));
	
EndProcedure


#EndRegion