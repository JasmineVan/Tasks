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
	
	List.Parameters.SetParameterValue("User", Users.CurrentUser());
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersList

&AtClient
Procedure ListBeforeChangeRow(Item, Cancel)
	Cancel = True;
	OpenForm("InformationRegister.UserReminders.Form.Reminder", New Structure("Key", Items.List.CurrentRow));
EndProcedure

&AtClient
Procedure ListOnActivateRow(Item)
	RowIsSelected = Not Item.CurrentRow = Undefined;
	Items.DeleteButton.Enabled = RowIsSelected;
	Items.ChangeButton.Enabled = RowIsSelected;
EndProcedure

&AtClient
Procedure ListBeforeDelete(Item, Cancel)
	Cancel = True;
	DeleteReminder();
EndProcedure

&AtClient
Procedure ListChoice(Item, RowSelected, Field, StandardProcessing)
	If Field.Name = "Source" Then
		StandardProcessing = False;
		If ValueIsFilled(Items.List.CurrentData.Source) Then
			ShowValue(, Items.List.CurrentData.Source);
		Else
			ShowMessageBox(, NStr("ru = 'Источник напоминания не задан.'; en = 'Please specify the reminder source.'; pl = 'Źródło przypomnienia nie jest ustawione.';de = 'Erinnerungsquelle nicht gesetzt.';ro = 'Sursa de memento nu este specificată.';tr = 'Hatırlatıcı kaynağı belirlenmemiş.'; es_ES = 'La fuente de recuerdo no establecido.'"));
		EndIf;
	EndIf;
EndProcedure

#EndRegion

#Region FormCommandHandlers

&AtClient
Procedure Change(Command)
	OpenForm("InformationRegister.UserReminders.Form.Reminder", New Structure("Key", Items.List.CurrentRow));
EndProcedure

&AtClient
Procedure Delete(Command)
	DeleteReminder();
EndProcedure

&AtClient
Procedure Create(Command)
	OpenForm("InformationRegister.UserReminders.Form.Reminder");
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure DisableReminder(ReminderParameters)
	UserRemindersInternal.DisableReminder(ReminderParameters, False);
EndProcedure

&AtClient
Procedure DeleteReminder()
	
	DialogButtons = New ValueList;
	DialogButtons.Add(DialogReturnCode.Yes, NStr("ru = 'Удалить'; en = 'Delete'; pl = 'Usuń';de = 'Löschen';ro = 'Ștergeți';tr = 'Sil'; es_ES = 'Borrar'"));
	DialogButtons.Add(DialogReturnCode.Cancel, NStr("ru = 'Не удалять'; en = 'Do not delete'; pl = 'Nie usuwaj';de = 'Nicht löschen';ro = 'Nu ștergeți';tr = 'Silme'; es_ES = 'No borrar'"));
	NotifyDescription = New NotifyDescription("DeleteReminderCompletion", ThisObject);
	
	ShowQueryBox(NotifyDescription, NStr("ru = 'Удалить напоминание?'; en = 'Do you want to delete the reminder?'; pl = 'Usunąć przypomnienie?';de = 'Die Erinnerung ablehnen?';ro = 'Renunțați la memento?';tr = 'Hatırlatıcıyı reddet?'; es_ES = '¿Descartar el recordatorio?'"), DialogButtons);
	
EndProcedure

&AtClient
Procedure DeleteReminderCompletion(QuestionResult, AdditionalParameters) Export
	
	If QuestionResult <> DialogReturnCode.Yes Then
		Return;
	EndIf;

	RecordKey = Items.List.CurrentRow;
	ReminderParameters = New Structure("User,EventTime,Source");
	FillPropertyValues(ReminderParameters, Items.List.CurrentData);
	
	DisableReminder(ReminderParameters);
	UserRemindersClient.DeleteRecordFromNotificationsCache(ReminderParameters);
	Notify("Write_UserReminders", New Structure, RecordKey);
	NotifyChanged(Type("InformationRegisterRecordKey.UserReminders"));
	
EndProcedure

#EndRegion
