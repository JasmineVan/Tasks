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
	
	If NOT Users.IsFullUser(, True) Then
		ReadOnly = True;
	EndIf;
	
	If Object.Ref.IsEmpty() Then
		SetSchedulePresentation(ThisObject);
		MethodParameters = Common.ValueToXMLString(New Array);
	EndIf;
	
EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)
	
	ID = Object.Ref.UUID();
	
	Schedule = CurrentObject.Schedule.Get();
	SetSchedulePresentation(ThisObject);
	
	MethodParameters = Common.ValueToXMLString(CurrentObject.Parameters.Get());
	
EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	CurrentObject.Schedule = New ValueStorage(Schedule);
	CurrentObject.Parameters = New ValueStorage(Common.ValueFromXMLString(MethodParameters));
	
EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)
	
	ID = Object.Ref.UUID();
	
EndProcedure

#EndRegion

#Region FormControlItemsEventHandlers

&AtClient
Procedure SchedulePresentationStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	LockFormDataForEdit();
	
	If ValueIsFilled(Object.Template) Then
		ShowMessageBox(, NStr("ru = 'Для заданий на основе шаблонов, расписание задается в шаблоне.'; en = 'Schedule is set in the template for jobs created from templates.'; pl = 'Harmonogram jest ustawiany w szablonie dla zadań utworzonych na podstawie szablonów.';de = 'Der Zeitplan wird in der Vorlage für Jobs festgelegt, die aus Vorlagen erstellt werden.';ro = 'Programul este setat în șablon pentru lucrările create din șabloane.';tr = 'Şablonlara dayalı görevler için, çizelge şablonda belirtilir.'; es_ES = 'Horario está establecido en el modelo para las tareas creadas desde los modelos.'"));
		Return;
	EndIf;
	
	If Schedule = Undefined Then
		ScheduleBeingEdited = New JobSchedule;
	Else
		ScheduleBeingEdited = Schedule;
	EndIf;
	
	Dialog = New ScheduledJobDialog(ScheduleBeingEdited);
	OnCloseNotifyDescription = New NotifyDescription("EditSchedule", ThisObject);
	Dialog.Show(OnCloseNotifyDescription);
	
EndProcedure

&AtClient
Procedure SchedulePresentationClearing(Item, StandardProcessing)
	
	StandardProcessing = False;
	LockFormDataForEdit();
	
	Schedule = Undefined;
	Modified = True;
	SetSchedulePresentation(ThisObject);
	
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure EditSchedule(NewSchedule, AdditionalParameters) Export
	
	If NewSchedule = Undefined Then
		Return;
	EndIf;
	
	Schedule = NewSchedule;
	Modified = True;
	SetSchedulePresentation(ThisObject);
	
	ShowUserNotification(NStr("ru = 'Перепланирование'; en = 'Rescheduling'; pl = 'Ponowne planowanie';de = 'Neuplanung';ro = 'Replanificare';tr = 'Yeniden planlama'; es_ES = 'Reprogramación'"), , NStr("ru = 'Новое расписание будет учтено при
		|следующем выполнении задания'; 
		|en = 'Next time the job will run
		|according to the new schedule.'; 
		|pl = 'Nowy harmonogram będzie
		|brany pod uwagę przy następnym wykonaniu zadania';
		|de = 'Der neue Zeitplan wird bei der folgenden Aufgabenausführung 
		|berücksichtigt';
		|ro = 'Orarul nou va fi luat în considerare la
		| următoarea executare a sarcinii';
		|tr = 'Yeni program 
		|aşağıdaki görev yerine getirilirken dikkate alınacaktır'; 
		|es_ES = 'Nuevo horario se
		|considerará durante la realización de la siguiente tarea'"));
	
EndProcedure

&AtClientAtServerNoContext
Procedure SetSchedulePresentation(Val Form)
	
	Schedule = Form.Schedule;
	
	If Schedule <> Undefined Then
		Form.SchedulePresentation = String(Schedule);
	ElsIf ValueIsFilled(Form.Object.Template) Then
		Form.SchedulePresentation = NStr("ru = '<Задается в шаблоне>'; en = '<Specified in the template>'; pl = '<Określono w szablonie>';de = '<In der Vorlage angegeben>';ro = '<Specificate în șablon>';tr = '<Şablonda belirtildi>'; es_ES = '<Especificado en el modelo>'");
	Else
		Form.SchedulePresentation = NStr("ru = '<Не задано>'; en = '<Not set>'; pl = '<Nieustawione>';de = '<Nicht festgelegt>';ro = '<Nu a fost setat>';tr = '<Belirlenmedi>'; es_ES = '<No establecido>'");
	EndIf;
	
EndProcedure

#EndRegion


