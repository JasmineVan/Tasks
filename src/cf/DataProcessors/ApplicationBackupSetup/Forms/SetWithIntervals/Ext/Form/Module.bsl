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
		Raise NStr("ru = 'Для корректной работы необходим режим толстого, или тонкого клиента.'; en = 'The thick or the thin client mode is required for correct work.'; pl = 'Do poprawnej pracy wymagany jest tryb grubego lub cienkiego klienta.';de = 'Für den korrekten Betrieb ist es notwendig, den Thick-, Thin- oder WEB-Client Modus zu verwenden.';ro = 'Pentru lucrul corect trebuie să utilizați regimul de fat-client, sau thin-client.';tr = 'Doğu çalışma için kalın veya ince istemci modu gerekmektedir.'; es_ES = 'Para el funcionamiento correcto es necesario el modo del cliente grueso o ligero.'");
		
	EndIf;
	
	// Form initialization
	For MonthNumber = 1 To 12 Do
		Items.EarlyBackupMonth.ChoiceList.Add(MonthNumber, 
			Format(Date(2, MonthNumber, 1), "DF=MMMM"));
	EndDo;
	
	SetLabelWidth();
	
	ApplySettingRestrictions();
	
	FillFormBySettings(Parameters.SettingsData);
	
EndProcedure

&AtClient
Procedure DailyBackupCountOnChange(Item)
	
	DailyBackupsCountLabel = BackupCountLabel(DailyBackupCount);
	
EndProcedure

&AtClient
Procedure MonthlyBackupCountOnChange(Item)
	
	MonthlyBackupsCountLabel = BackupCountLabel(MonthlyBackupCount);
	
EndProcedure

&AtClient
Procedure YearlyBackupCountOnChange(Item)
	
	AnnualBackupsCountLabel = BackupCountLabel(YearlyBackupCount);
	
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
	ShowQueryBox(NotifyDescription, NStr("ru = 'Данные были изменены. Сохранить изменения?'; en = 'The data was changed. Do you want to save the changes?'; pl = 'Dane zostały zmienione. Czy chcesz zapisać zmiany?';de = 'Daten wurden geändert. Wollen Sie die Änderungen speichern?';ro = 'Datele au fost modificate. Salvați modificările?';tr = 'Veriler değiştirildi. Değişiklikleri kaydetmek istiyor musunuz?'; es_ES = 'Datos se han cambiado. ¿Quiere guardar los cambios?'"), 
		QuestionDialogMode.YesNoCancel, , DialogReturnCode.Yes);
		
EndProcedure
		
#EndRegion

#Region FormCommandHandlers

&AtClient
Procedure Reread(Command)
	
	RereadAtServer();
	
EndProcedure

&AtClient
Procedure Write(Command)
	
	SaveNewSettings();
	
EndProcedure

&AtClient
Procedure WriteAndClose(Command)
	
	SaveNewSettings();
	Close();
	
EndProcedure

&AtClient
Procedure CustomizeStandardSettings(Command)
	
	SetStandardSettingsAtServer();
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure RereadAtServer()
	
	FillFormBySettings(
		DataAreaBackupFormDataInterface.GetAreaSettings(Parameters.DataArea));
		
	Modified = False;
	
EndProcedure

&AtServer
Procedure FillFormBySettings(Val SettingsData, Val UpdateInitialSettings = True)
	
	FillPropertyValues(ThisObject, SettingsData);
	
	If UpdateInitialSettings Then
		InitialSettings = SettingsData;
	EndIf;
	
	SetAllNumberLabels();
	
EndProcedure

&AtServer
Procedure SetLabelWidth()
	
	MaxWidth = 0;
	
	NumberForCheck = New Array;
	NumberForCheck.Add(1);
	NumberForCheck.Add(2);
	NumberForCheck.Add(5);
	
	For Each Number In NumberForCheck Do
		LabelWidth = StrLen(BackupCountLabel(Number));
		If LabelWidth > MaxWidth Then
			MaxWidth = LabelWidth;
		EndIf;
	EndDo;
	
	LabelItems = New Array;
	LabelItems.Add(Items.DailyBackupsCountLabel);
	LabelItems.Add(Items.MonthlyBackupsCountLabel);
	LabelItems.Add(Items.AnnualBackupsCountLabel);
	
	For each SignatureItem In LabelItems Do
		SignatureItem.Width = MaxWidth;
	EndDo;
	
EndProcedure

&AtServer
Procedure ApplySettingRestrictions()
	
	SettingsRestrictions = Parameters.SettingsRestrictions;
	
	TooltipTemplate = NStr("ru = 'Максимум %1'; en = 'Maximum %1'; pl = 'Maksymalny %1';de = 'Maximal %1';ro = 'Maxim %1';tr = 'Maksimum %1'; es_ES = 'Máximo %1'");
	
	RestrictionItems = New Structure;
	RestrictionItems.Insert("DailyBackupCount", "DailyBackupMax");
	RestrictionItems.Insert("MonthlyBackupCount", "MonthlyBackupMax");
	RestrictionItems.Insert("YearlyBackupCount", "YearlyBackupMax");
	
	For each KeyAndValue In RestrictionItems Do
		Item = Items[KeyAndValue.Key];
		Item.MaxValue = SettingsRestrictions[KeyAndValue.Value];
		Item.ToolTip = 
			StringFunctionsClientServer.SubstituteParametersToString(TooltipTemplate, 
				SettingsRestrictions[KeyAndValue.Value]);
	EndDo;
	
EndProcedure

&AtServer
Procedure SetAllNumberLabels()
	
	DailyBackupsCountLabel = BackupCountLabel(DailyBackupCount);
	MonthlyBackupsCountLabel = BackupCountLabel(MonthlyBackupCount);
	AnnualBackupsCountLabel = BackupCountLabel(YearlyBackupCount);
	
EndProcedure

&AtClientAtServerNoContext
Function BackupCountLabel(Val Count)

	PresentationsArray = New Array;
	PresentationsArray.Add(NStr("ru = 'последнюю копию'; en = 'the latest copy'; pl = 'ostatnia kopia';de = 'letzte Kopie';ro = 'ultima copie';tr = 'son kopya'; es_ES = 'última copia'"));
	PresentationsArray.Add(NStr("ru = 'последние копии'; en = 'last copies'; pl = 'ostatnie kopie';de = 'letzte kopien';ro = 'ultimele copii';tr = 'son kopyalar'; es_ES = 'últimas copias'"));
	PresentationsArray.Add(NStr("ru = 'последних копий'; en = 'last copies'; pl = 'ostatnie kopie';de = 'letzte kopien';ro = 'ultimele copii';tr = 'son kopyalar'; es_ES = 'últimas copias'"));
	
	If Count >= 100 Then
		Count = Count - Int(Count / 100)*100;
	EndIf;
	
	If Count > 20 Then
		Count = Count - Int(Count/10)*10;
	EndIf;
	
	If Count = 1 Then
		Result = PresentationsArray[0];
	ElsIf Count > 1 AND Count < 5 Then
		Result = PresentationsArray[1];
	Else
		Result = PresentationsArray[2];
	EndIf;
	
	Return Result;
	
EndFunction

&AtServer
Procedure SaveNewSettings()
	
	NewSettings = New Structure;
	For each KeyAndValue In InitialSettings Do
		NewSettings.Insert(KeyAndValue.Key, ThisObject[KeyAndValue.Key]);
	EndDo;
	
	NewSettings = New FixedStructure(NewSettings);
	
	DataAreaBackupFormDataInterface.SetAreaSettings(
		Parameters.DataArea,
		NewSettings,
		InitialSettings);
		
	Modified = False;
	InitialSettings = NewSettings;
	
EndProcedure

&AtServer
Procedure SetStandardSettingsAtServer()
	
	FillFormBySettings(
		DataAreaBackupFormDataInterface.GetStandardSettings(),
		False);
	
EndProcedure

&AtClient
Procedure BeforeCloseCompletion(Response, AdditionalParameters) Export	
	
	If Response = DialogReturnCode.Cancel Then
		Return;
	EndIf;
	
	If Response = DialogReturnCode.Yes Then
		SaveNewSettings();
	EndIf;
	AnswerBeforeClose = True;
    Close();
	
EndProcedure

#EndRegion
