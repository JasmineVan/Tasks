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
	
	If Not Parameters.Property("Variants") Or TypeOf(Parameters.Variants) <> Type("Array") Then
		ErrorText = NStr("ru = 'Не указаны варианты отчетов.'; en = 'No report options provided.'; pl = 'Opcje sprawozdania nie zostały określone.';de = 'Berichtsoptionen sind nicht angegeben.';ro = 'Opțiunile pentru rapoarte nu sunt specificate.';tr = 'Rapor seçenekleri belirtilmemiş.'; es_ES = 'Opciones del informe no especificadas.'");
		Return;
	EndIf;
	
	If Not HasUserSettings(Parameters.Variants) Then
		ErrorText = NStr("ru = 'Пользовательские настройки выбранных вариантов отчетов (%1 шт) не заданы или уже сброшены.'; en = 'Custom settings for the %1selected report options have not been defined or have been reset.'; pl = 'Ustawienia użytkownika wybranych opcji sprawozdania (%1 szt.) nie zostały określone lub zostały już zresetowane.';de = 'Benutzereinstellungen der ausgewählten Berichtsoptionen (%1Stück) wurden nicht angegeben oder wurden bereits zurückgesetzt.';ro = 'Setările de utilizator ale opțiunilor de rapoarte selectate (%1 buc.) Nu au fost specificate sau au fost deja resetate.';tr = 'Seçilen rapor seçeneklerinin (%1 adet) kullanıcı ayarları belirtilmemiş veya zaten sıfırlanmış.'; es_ES = 'Configuraciones del usuario de las opciones del informe seleccionadas (%1 piezas) no se han especificado o ya se han restablecido.'");
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(ErrorText, Format(Parameters.Variants.Count(), "NZ=0; NG=0"));
		Return;
	EndIf;
	
	DefineBehaviorInMobileClient();
	OptionsToAssign.LoadValues(Parameters.Variants);
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	If Not IsBlankString(ErrorText) Then
		Cancel = True;
		ShowMessageBox(, ErrorText);
	EndIf;
EndProcedure

#EndRegion

#Region FormCommandHandlers

&AtClient
Procedure ResetCommand(Command)
	OptionsCount = OptionsToAssign.Count();
	If OptionsCount = 0 Then
		ShowMessageBox(, NStr("ru = 'Не указаны варианты отчетов.'; en = 'No report options provided.'; pl = 'Opcje sprawozdania nie zostały określone.';de = 'Berichtsoptionen sind nicht angegeben.';ro = 'Opțiunile pentru rapoarte nu sunt specificate.';tr = 'Rapor seçenekleri belirtilmemiş.'; es_ES = 'Opciones del informe no especificadas.'"));
		Return;
	EndIf;
	
	ResetUserSettingsServer(OptionsToAssign);
	If OptionsCount = 1 Then
		OptionRef = OptionsToAssign[0].Value;
		NotificationTitle = NStr("ru = 'Сброшены пользовательские настройки варианта отчета'; en = 'Custom settings for the report option have been reset.'; pl = 'Ustawienia użytkownika opcji sprawozdania zostały zresetowane';de = 'Benutzereinstellungen der Berichtsoption wurden zurückgesetzt';ro = 'Setările utilizatorului din opțiunea de raport au fost resetate';tr = 'Rapor seçeneğinin kullanıcı ayarları sıfırlandı'; es_ES = 'Configuraciones del usuario de la opción del informe se han restablecido'");
		NotificationRef    = GetURL(OptionRef);
		NotificationText     = String(OptionRef);
		ShowUserNotification(NotificationTitle, NotificationRef, NotificationText);
	Else
		NotificationText = NStr("ru = 'Сброшены пользовательские настройки
		|вариантов отчетов (%1 шт.).'; 
		|en = 'Custom settings for %1 report options
		|have been reset.'; 
		|pl = 'Niestandardowe ustawienia opcji
		|sprawozdania są resetowane (%1 szt.).';
		|de = 'Die Benutzereinstellungen
		| für Berichtsoptionen (%1 Stk.) werden zurückgesetzt.';
		|ro = 'Setările de utilizator
		|ale variantelor rapoartelor au fost resetate (%1 elemente).';
		|tr = '
		| rapor seçeneklerinin kullanıcı ayarları sıfırlandı (%1 adet).'; 
		|es_ES = 'Los ajustes personalizadas
		|de las variantes del informe se han restablecido (%1 piezas).'");
		NotificationText = StringFunctionsClientServer.SubstituteParametersToString(NotificationText, Format(OptionsCount, "NZ=0; NG=0"));
		ShowUserNotification(, , NotificationText);
	EndIf;
	Close();
EndProcedure

#EndRegion

#Region Private

////////////////////////////////////////////////////////////////////////////////
// Server call

&AtServerNoContext
Procedure ResetUserSettingsServer(Val OptionsToAssign)
	BeginTransaction();
	Try
		Lock = New DataLock;
		For Each ListItem In OptionsToAssign Do
			LockItem = Lock.Add(Metadata.Catalogs.ReportsOptions.FullName());
			LockItem.SetValue("Ref", ListItem.Value);
		EndDo;
		Lock.Lock();
		
		InformationRegisters.ReportOptionsSettings.ClearSettings(OptionsToAssign.UnloadValues());
		
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Server

&AtServer
Procedure DefineBehaviorInMobileClient()
	If Not Common.IsMobileClient() Then 
		Return;
	EndIf;
	
	CommandBarLocation = FormCommandBarLabelLocation.Auto;
EndProcedure

&AtServer
Function HasUserSettings(OptionsArray)
	Query = New Query;
	Query.SetParameter("OptionsArray", OptionsArray);
	Query.Text =
	"SELECT TOP 1
	|	TRUE AS HasUserSettings
	|FROM
	|	InformationRegister.ReportOptionsSettings AS Settings
	|WHERE
	|	Settings.Variant IN(&OptionsArray)";
	
	HasUserSettings = NOT Query.Execute().IsEmpty();
	Return HasUserSettings;
EndFunction

#EndRegion
