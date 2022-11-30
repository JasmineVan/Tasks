///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Variables

&AtClient
Var AnswerBeforeClose;

#EndRegion

#Region EventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Common.IsMobileClient() Then
		
		Cancel = True;
		Raise NStr("ru = 'Для корректной работы необходим режим толстого, тонкого или ВЕБ-клиента.'; en = 'Thin, thick, or web client mode is required.'; pl = 'Do prawidłowego działania wymagany jest gruby, cienki tryb klienta lub tryb klienta WEB.';de = 'Für den korrekten Betrieb ist es notwendig, den Thick-, Thin- oder WEB-Client Modus zu verwenden.';ro = 'Pentru lucrul corect trebuie să utilizați regimul de fat-client, thin-client sau web-client.';tr = 'Doğu çalışma için kalın, ince veya WEB istemci modu gerekmektedir.'; es_ES = 'Para el funcionamiento correcto es necesario el modo del cliente grueso, ligero o cliente web.'");
		
	EndIf;
	
	BackupSettings = DataAreaBackup.GetAreaBackupSettings(
		SaaS.SessionSeparatorValue());
	FillPropertyValues(ThisObject, BackupSettings);
	
	For MonthNumber = 1 To 12 Do
		Items.EarlyBackupMonth.ChoiceList.Add(MonthNumber, 
			Format(Date(2, MonthNumber, 1), "DF=MMMM"));
	EndDo;
	
	Timezone = SessionTimeZone();
	AreaTimeZone = Timezone + " (" + TimeZonePresentation(Timezone) + ")";
	
EndProcedure

&AtClient
Procedure BeforeClose(Cancel, Exit, WarningText, StandardProcessing)
	
	If Not Modified Then
		Return;
	EndIf;
	
	If AnswerBeforeClose = True Then
		Return;
	EndIf;
	
	Cancel = True;
	If Exit Then
		Return;
	EndIf;
	
	NotifyDescription = New NotifyDescription("BeforeCloseCompletion", ThisObject);
	ShowQueryBox(NotifyDescription, NStr("ru = 'Настройки были изменены. Сохранить изменения?'; en = 'Settings were changed. Save changes?'; pl = 'Ustawienia zostały zmienione. Czy chcesz zachować zmiany?';de = 'Einstellungen wurden geändert. Möchten Sie Änderungen speichern?';ro = 'Setările au fost modificate. Salvezi modificările?';tr = 'Ayarlar değiştirildi. Değişiklikleri kaydetmek istiyor musunuz?'; es_ES = 'Configuraciones se han cambiado. ¿Quiere guardar los cambios?'"), 
		QuestionDialogMode.YesNoCancel, , DialogReturnCode.Yes);
		
EndProcedure
		
&AtClient
Procedure BeforeCloseCompletion(Response, AdditionalParameters) Export	
	
	If Response = DialogReturnCode.Cancel Then
		Return;
	EndIf;
	
	If Response = DialogReturnCode.Yes Then
		WriteBackupSettings();
	EndIf;
	AnswerBeforeClose = True;
    Close();
	
EndProcedure

#EndRegion

#Region FormCommandHandlers

&AtClient
Procedure SetDefault(Command)
	
	SetDefaultAtServer();
	
EndProcedure

&AtClient
Procedure WriteAndClose(Command)
	
	WriteBackupSettings();
	Modified = False;
	Close(DialogReturnCode.OK);
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SetDefaultAtServer()
	
	BackupSettings = DataAreaBackup.GetAreaBackupSettings();
	FillPropertyValues(ThisObject, BackupSettings);
	
EndProcedure

&AtServer
Procedure WriteBackupSettings()

	SettingsMap = DataAreasBackupCached.MapBetweenSMSettingsAndAppSettings();
	
	BackupSettings = New Structure;
	For Each KeyAndValue In SettingsMap Do
		BackupSettings.Insert(KeyAndValue.Value, ThisObject[KeyAndValue.Value]);
	EndDo;
	
	DataAreaBackup.SetAreaBackupSettings(
		SaaS.SessionSeparatorValue(), BackupSettings);
		
EndProcedure

#EndRegion
