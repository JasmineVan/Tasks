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
	
	If Common.IsWebClient() Then
		Raise NStr("ru = 'Резервное копирование недоступно в веб-клиенте.'; en = 'Web client does not support data backup.'; pl = 'Kopia zapasowa nie jest dostępna w kliencie www.';de = 'Die Sicherung ist im Webclient nicht verfügbar.';ro = 'Copia de rezervă nu este disponibilă în web client.';tr = 'Yedekleme web istemcisinde mevcut değildir.'; es_ES = 'Copia de respaldo no se encuentra disponible en el cliente web.'");
	EndIf;
	
	If Not Common.IsWindowsClient() Then
		Return; // Cancel is set in OnOpen().
	EndIf;
	
	BackupParameters = IBBackupServer.BackupParameters();
	DisableNotifications = BackupParameters.BackupConfigured;
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	If Not CommonClient.IsWindowsClient() Then
		Cancel = True;
		MessageText = NStr("ru = 'Резервное копирование поддерживается только в клиенте под управлением ОС Windows.'; en = 'Only clients that run on Windows support data backup.'; pl = 'Kopia zapasowa jest obsługiwana tylko w kliencie z systemem operacyjnym Windows.';de = 'Sicherungen werden nur von dem Client unter Windows unterstützt.';ro = 'Copierea de rezervă este susținută numai pe clientul gestionat de SO Windows.';tr = 'OS Windows işletim sistemini çalıştıran istemcide yedekleme desteklenir.'; es_ES = 'Copia de respaldo está admitida solo en el cliente bajo el sistema operativo Windows.'");
		ShowMessageBox(, MessageText);
		Return;
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandHandlers

&AtClient
Procedure OK(Command)
	
	ApplicationParameters["StandardSubsystems.InfobaseBackupParameters"].NotificationParameter =
		?(DisableNotifications, "DoNotNotify", "NotConfiguredYet");
	
	If DisableNotifications Then
		IBBackupClient.DisableBackupIdleHandler();
	Else
		IBBackupClient.AttachIdleBackupHandler();
	EndIf;
	
	OKAtServer();
	Notify("BackupSettingsFormClosed");
	Close();
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure OKAtServer()
	
	BackupParameters = IBBackupServer.BackupParameters();
	
	BackupParameters.BackupConfigured = DisableNotifications;
	BackupParameters.RunAutomaticBackup = False;
	
	IBBackupServer.SetBackupParemeters(BackupParameters);
	
EndProcedure

#EndRegion
