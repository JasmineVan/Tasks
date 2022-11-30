///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Public

// Opens backup form.
//
// Parameters:
//    Parameters - Structure - backup form parameters.
//
Procedure OpenBackupForm(Parameters = Undefined) Export
	
	OpenForm("DataProcessor.IBBackup.Form.DataBackup", Parameters);
	
EndProcedure

#EndRegion

#Region Internal

////////////////////////////////////////////////////////////////////////////////
// Configuration subsystems event handlers.

// See CommonClientOverridable.OnStart. 
Procedure OnStart(Parameters) Export
	
	If Not BackupAvailable() Then
		Return;
	EndIf;
	
	RunParameters = StandardSubsystemsClient.ClientParametersOnStart();
	If RunParameters.DataSeparationEnabled Then
		Return;
	EndIf;
	
	FixedIBBackupParameters = Undefined;
	If Not RunParameters.Property("IBBackup", FixedIBBackupParameters) Then
		Return;
	EndIf;
	If TypeOf(FixedIBBackupParameters) <> Type("FixedStructure") Then
		Return;
	EndIf;
	
	// Filling global variables.
	FillGlobalVariableValues(FixedIBBackupParameters);
	
	CheckIBBackup(FixedIBBackupParameters);
	
	If FixedIBBackupParameters.BackupRestored Then
		NotificationText = NStr("ru = 'Восстановление данных проведено успешно.'; en = 'Data successfully restored.'; pl = 'Odzyskiwanie danych zakończone pomyślnie.';de = 'Die Daten werden erfolgreich wiederhergestellt.';ro = 'Datele sunt restaurate cu succes.';tr = 'Veri başarıyla geri yüklendi.'; es_ES = 'Datos se han restablecido con éxito.'");
		ShowUserNotification(NStr("ru = 'Данные восстановлены.'; en = 'Data is restored.'; pl = 'Dane zostały odzyskane.';de = 'Die Daten werden wiederhergestellt.';ro = 'Datele sunt restaurate.';tr = 'Veri geri yüklendi.'; es_ES = 'Datos se han restablecido.'"), , NotificationText);
	EndIf;
	
	NotificationOption = FixedIBBackupParameters.NotificationParameter;
	
	If NotificationOption = "DoNotNotify" Then
		Return;
	EndIf;
	
	If CommonClient.SubsystemExists("StandardSubsystems.ToDoList") Then
		ShowWarning = False;
		IBBackupClientOverridable.OnDetermineBackupWarningRequired(ShowWarning);
	Else
		ShowWarning = True;
	EndIf;
	
	If ShowWarning
		AND (NotificationOption = "Overdue" Or NotificationOption = "NotConfiguredYet") Then
		NotifyUserOfBackup(NotificationOption);
	EndIf;
	
	AttachIdleBackupHandler();
	
EndProcedure

// See CommonClientOverridable.BeforeExit. 
Procedure BeforeExit(Cancel, Warnings) Export
	
	#If WebClient OR MobileClient Then
		Return;
	#EndIf
	
	If Not CommonClient.IsWindowsClient() Then
		Return;
	EndIf;
	
	Parameters = StandardSubsystemsClient.ClientParameter();
	If Parameters.DataSeparationEnabled Or Not Parameters.FileInfobase Then
		Return;
	EndIf;
	
	If Not Parameters.IBBackupOnExit.NotificationRolesAvailable
		Or Not Parameters.IBBackupOnExit.ExecuteOnExit Then
		Return;
	EndIf;
	
	WarningParameters = StandardSubsystemsClient.WarningOnExit();
	WarningParameters.CheckBoxText = NStr("ru = 'Выполнить резервное копирование'; en = 'Back up'; pl = 'Utworzyć kopię zapasową.';de = 'Sichern';ro = 'Înapoi';tr = 'Yedekleyin'; es_ES = 'Crear una copia de respaldo'");
	WarningParameters.Priority = 50;
	WarningParameters.WarningText = NStr("ru = 'Не выполнено резервное копирование при завершении работы.'; en = 'Back up on exit has not been done.'; pl = 'Kopia zapasowa danych nie została utworzona.';de = 'Die Daten wurden nicht gesichert.';ro = 'Nu a fost executată copierea de rezervă la finalizarea lucrului.';tr = 'Veri yedeklenmedi.'; es_ES = 'No se ha creado una copia de respaldo de los datos.'");
	
	ActionIfFlagSet = WarningParameters.ActionIfFlagSet;
	ActionIfFlagSet.Form = "DataProcessor.IBBackup.Form.DataBackup";
	FormParameters = New Structure();
	FormParameters.Insert("RunMode", "ExecuteOnExit");
	ActionIfFlagSet.FormParameters = FormParameters;
	
	Warnings.Add(WarningParameters);
	
EndProcedure

// See SSLSubsystemsIntegrationClient.OnCheckIfCanBackUpInUserMode. 
Procedure OnCheckIfCanBackUpInUserMode(Result) Export
	
	If CommonClient.FileInfobase() Then
		Result = True;
	EndIf;
	
EndProcedure

// See SSLSubsystemsIntegrationClient.OnPromptUserForBackup. 
Procedure OnPromptUserForBackup() Export
	
	OpenBackupForm();
	
EndProcedure

#EndRegion

#Region Private

// Filling global variables.
Procedure FillGlobalVariableValues(FixedIBBackupParameters) Export
	
	ParameterName = "StandardSubsystems.InfobaseBackupParameters";
	ApplicationParameters.Insert(ParameterName, New Structure);
	ApplicationParameters[ParameterName].Insert("ProcessRunning");
	ApplicationParameters[ParameterName].Insert("MinDateOfNextAutomaticBackup");
	ApplicationParameters[ParameterName].Insert("LatestBackupDate");
	ApplicationParameters[ParameterName].Insert("NotificationParameter");
	
	FillPropertyValues(ApplicationParameters[ParameterName], FixedIBBackupParameters);
	ApplicationParameters[ParameterName].Insert("ScheduleValue", CommonClientServer.StructureToSchedule(FixedIBBackupParameters.CopyingSchedule));
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Internal export procedures and functions.

// Checks whether it is necessary to start automatic backup during user working, as well as repeat 
// notification after ignoring the initial one.
//
Procedure StartIdleHandler() Export
	
	If Not BackupAvailable() Then
		Return;
	EndIf;
	
	If CommonClient.FileInfobase()
	   AND NecessityOfAutomaticBackup() Then
		
		BackUp();
	EndIf;
	
	If CommonClient.SubsystemExists("StandardSubsystems.ToDoList") Then
		ShowWarning = False;
		IBBackupClientOverridable.OnDetermineBackupWarningRequired(ShowWarning);
	Else
		ShowWarning = True;
	EndIf;
	
	NotificationOption = ApplicationParameters["StandardSubsystems.InfobaseBackupParameters"].NotificationParameter;
	If ShowWarning
		AND (NotificationOption = "Overdue" Or NotificationOption = "NotConfiguredYet") Then
		NotifyUserOfBackup(NotificationOption);
	EndIf;
	
EndProcedure

// Checks whether the automatic backup is required.
//
// Returns - Boolean - True if necessary, otherwise False.
//
Function NecessityOfAutomaticBackup()
	Var ScheduleValue;
	
	IBParameters = ApplicationParameters["StandardSubsystems.InfobaseBackupParameters"];
	If IBParameters = Undefined Then
		Return False;
	EndIf;
	
	If IBParameters.ProcessRunning
		OR NOT IBParameters.Property("MinDateOfNextAutomaticBackup")
		OR NOT IBParameters.Property("ScheduleValue", ScheduleValue)
		OR NOT IBParameters.Property("LatestBackupDate") Then
		Return False;
	EndIf;
	
	If ScheduleValue = Undefined Then
		Return False;
	EndIf;
	
	CheckDate = CommonClient.SessionDate();
	
	NextCopyingDate = IBParameters.MinDateOfNextAutomaticBackup;
	If NextCopyingDate = '29990101' Or NextCopyingDate > CheckDate Then
		Return False;
	EndIf;
	
	Return ScheduleValue.ExecutionRequired(CheckDate, IBParameters.LatestBackupDate);
EndFunction

// Starts backup on schedule.
// 
Procedure BackUp()
	
	Buttons = New ValueList;
	Buttons.Add("Yes", NStr("ru = 'Да'; en = 'Yes'; pl = 'Tak';de = 'Ja';ro = 'Da';tr = 'Evet'; es_ES = 'Sí'"));
	Buttons.Add("No", NStr("ru = 'Нет'; en = 'No'; pl = 'Nie';de = 'Nr.';ro = 'Nu';tr = 'No'; es_ES = 'No'"));
	Buttons.Add("Defer", NStr("ru = 'Отложить на 15 минут'; en = 'Snooze for 15 minutes'; pl = 'Odłóż na 15 minut';de = 'Um 15 Minuten verschieben';ro = 'Amânare cu 15 minute';tr = '15 dakika ertele'; es_ES = 'Aplazar para 15 minutos'"));
	
	NotifyDescription = New NotifyDescription("CreateBackupCompletion", ThisObject);
	ShowQueryBox(NotifyDescription, NStr("ru = 'Все готово для выполнения резервного копирования по расписанию.
		|Выполнить резервное копирование сейчас?'; 
		|en = 'Scheduled backup is all set to start.
		|Do you want to start it now?'; 
		|pl = 'Wszystko jest gotowe do wykonania kopii zapasowej według harmonogramu.
		| Utwórz kopię zapasową już teraz?';
		|de = 'Alles ist bereit für den geplanten Backup.
		|Backup jetzt ausführen?';
		|ro = 'Totul este gata pentru executarea copierii de rezervă conform orarului.
		|Executați acum?';
		|tr = 'Her şey zamanlanmış yedeklemeyi gerçekleştirmek için hazırdır. 
		|Şimdi yedekle?'; 
		|es_ES = 'Todo está listo para crear una copia de respaldo según el horario.
		|¿Crear una copia de respaldo ahora?'"),
		Buttons, 30, "Yes", NStr("ru = 'Резервное копирование по расписанию'; en = 'Scheduled backup'; pl = 'Zaplanowana kopia zapasowa';de = 'Geplante Backups';ro = 'Copierea de rezervă conform orarului';tr = 'Zamanlanmış yedeklenme'; es_ES = 'Copia de respaldo según el horario'"), "Yes");
	
EndProcedure

Procedure CreateBackupCompletion(QuestionResult, AdditionalParameters) Export
	
	ExecuteBackup = QuestionResult = "Yes" Or QuestionResult = DialogReturnCode.Timeout;
	DeferBackup = QuestionResult = "Defer";
	
	NextAutomaticCopyingDate = IBBackupServerCall.NextAutomaticCopyingDate(
		DeferBackup);
	FillPropertyValues(ApplicationParameters["StandardSubsystems.InfobaseBackupParameters"],
		NextAutomaticCopyingDate);
	
	If ExecuteBackup Then
		FormParameters = New Structure("RunMode", "ExecuteNow");
		OpenForm("DataProcessor.IBBackup.Form.DataBackup", FormParameters);
	EndIf;
	
EndProcedure

// Checks on application startup whether it is the first start after backup.
// If yes, it displays a handler form with backup results.
//
// Parameters:
//	Parameters - Structure - backup parameters.
//
Procedure CheckIBBackup(Parameters)
	
	If Not Parameters.BackupCreated Then
		Return;
	EndIf;
	
	If Parameters.LastBackupManualStart Then
		
		FormParameters = New Structure();
		FormParameters.Insert("RunMode", ?(Parameters.CopyingResult, "CompletedSuccessfully", "NotCompleted"));
		FormParameters.Insert("BackupFileName", Parameters.BackupFileName);
		OpenForm("DataProcessor.IBBackup.Form.DataBackup", FormParameters);
		
	Else
		
		ShowUserNotification(NStr("ru = 'Резервное копирование'; en = 'Backup'; pl = 'Kopia zapasowa';de = 'Datensicherung';ro = 'Copia de rezervă';tr = 'Yedek'; es_ES = 'Copia de respaldo'"),
			"e1cib/command/CommonCommand.ShowBackupResult",
			NStr("ru = 'Резервное копирование проведено успешно'; en = 'Backup successful'; pl = 'Tworzenie kopii zapasowej przeprowadzone pomyślnie';de = 'Backup wurde erfolgreich durchgeführt';ro = 'Copierea de rezervă executată cu succes';tr = 'Yedekleme başarıyla gerçekleştirildi'; es_ES = 'Creación de una copia de respaldo se ha realizados con éxito'"), PictureLib.Information32);
		IBBackupServerCall.SetSettingValue("BackupCreated", False);
		
	EndIf;
	
EndProcedure

// Shows a notification according to results of backup parameters analysis.
//
// Parameters:
//   NotificationOption - String - check result for notifications.
//
Procedure NotifyUserOfBackup(NotificationOption)
	
	NoteText = "";
	If NotificationOption = "Overdue" Then
		
		NoteText = NStr("ru = 'Автоматическое резервное копирование не было выполнено.'; en = 'Automatic backup has not been done.'; pl = 'Automatyczne tworzenie kopii zapasowej nie zostało wykonane.';de = 'Die automatische Sicherung wurde nicht ausgeführt.';ro = 'Copierea de rezervă automată nu a fost executată.';tr = 'Otomatik yedekleme gerçekleştirilmedi.'; es_ES = 'Copia de respaldo automática no se ha ejecutado.'"); 
		ShowUserNotification(NStr("ru = 'Резервное копирование'; en = 'Backup'; pl = 'Kopia zapasowa';de = 'Sicherungskopie';ro = 'Copie de rezervă';tr = 'Yedek'; es_ES = 'Copia de respaldo'"),
			"e1cib/app/DataProcessor.IBBackup", NoteText, PictureLib.Warning32);
		
	ElsIf NotificationOption = "NotConfiguredYet" Then
		
		SettingsFormName = "e1cib/app/DataProcessor.IBBackupSetup/";
		NoteText = NStr("ru = 'Рекомендуется настроить резервное копирование информационной базы.'; en = 'It is recommended that you set up infobase backup.'; pl = 'Zaleca się skonfigurować rezerwowe kopiowanie bazy informacyjnej.';de = 'Wir empfehlen, dass Sie die Sicherung für die Infobase konfigurieren.';ro = 'Vă recomandăm să configurați copia de rezervă pentru baza de date.';tr = 'Veritabanı için yedeklemeyi yapılandırmanızı öneririz.'; es_ES = 'Nosotros recomendamos configurar la creación de una copia de respaldo para la infobase.'"); 
		ShowUserNotification(NStr("ru = 'Резервное копирование'; en = 'Backup'; pl = 'Kopia zapasowa';de = 'Sicherungskopie';ro = 'Copie de rezervă';tr = 'Yedek'; es_ES = 'Copia de respaldo'"),
			SettingsFormName, NoteText, PictureLib.Warning32);
			
	EndIf;
	
	CurrentDate = CommonClient.SessionDate();
	IBBackupServerCall.SetLastNotificationDate(CurrentDate);
	
EndProcedure

// Returns an event type of the event log for the current subsystem.
//
// Returns - String - an event type of the event log.
//
Function EventLogEvent() Export
	
	Return NStr("ru = 'Резервное копирование информационной базы'; en = 'Infobase backup'; pl = 'Rezerwowe kopiowanie bazy informacyjnej';de = 'Infobase-Sicherung';ro = 'Copierea de rezervă a BI';tr = 'Veritabanı yedeği'; es_ES = 'Copia de respaldo de la infobase'",
		StandardSubsystemsClient.ClientParametersOnStart().DefaultLanguageCode);
	
EndFunction

// Getting user authentication parameters for update.
// Creates a virtual user if necessary.
//
// Returns
//  Structure - parameters of a virtual user.
//
Function UpdateAdministratorAuthenticationParameters(AdministratorPassword) Export
	
	Result = New Structure("UserName, UserPassword, StringForConnection, InfobaseConnectionString");
	
	CurrentConnections = IBConnectionsServerCall.ConnectionsInformation(True,
		ApplicationParameters["StandardSubsystems.MessagesForEventLog"]);
	Result.InfobaseConnectionString = CurrentConnections.InfobaseConnectionString;
	// Detects cases when role-based security is not provided by the application.
	// This means that any user can do everything in the application. 
	If Not CurrentConnections.HasActiveUsers Then
		Return Result;
	EndIf;
	
	Result.UserName    = StandardSubsystemsClient.ClientParametersOnStart().UserCurrentName;
	Result.UserPassword = StringUnicode(AdministratorPassword);
	Result.StringForConnection  = "Usr=""{0}"";Pwd=""{1}""";
	Return Result;
	
EndFunction

Function StringUnicode(Row) Export
	
	Result = "";
	
	For CharNumber = 1 To StrLen(Row) Do
		
		Char = Format(CharCode(Mid(Row, CharNumber, 1)), "NG=0");
		Char = StringFunctionsClientServer.SupplementString(Char, 4);
		Result = Result + Char;
		
	EndDo;
	
	Return Result;
	
EndFunction

// Checks whether an add-in can be attached to the infobase.
//
Procedure CheckAccessToInfobase(AdministratorPassword, Val Notification) Export
	
	Context = New Structure;
	Context.Insert("Notification", Notification);
	Context.Insert("AdministratorPassword", AdministratorPassword);
	
	Notification = New NotifyDescription("CheckAccessToInfobaseAfterCOMRegistration", ThisObject, Context);
	CommonClient.RegisterCOMConnector(False, Notification);
	
EndProcedure

Procedure CheckAccessToInfobaseAfterCOMRegistration(Registered, Context) Export
	
	Notification = Context.Notification;
	AdministratorPassword = Context.AdministratorPassword;
	
	ConnectionResult = ConnectionResult();
	
	If Registered Then 
		
		ClientRunParametersOnStart = StandardSubsystemsClient.ClientParametersOnStart();
		
		AttachmentParameters = CommonClientServer.ParametersStructureForExternalConnection();
		AttachmentParameters.InfobaseDirectory = StrSplit(InfoBaseConnectionString(), """")[1];
		AttachmentParameters.UserName = ClientRunParametersOnStart.UserCurrentName;
		AttachmentParameters.UserPassword = AdministratorPassword;
		
		Result = CommonClient.EstablishExternalConnectionWithInfobase(AttachmentParameters);
		
		If Result.AddInAttachmentError Then
			EventLogClient.AddMessageForEventLog(
				EventLogEvent(),"Error", Result.DetailedErrorDescription, , True);
		EndIf;
		
		FillPropertyValues(ConnectionResult, Result);
		
		Result.Connection = Undefined; // Disconnecting.
		
	EndIf;
	
	ExecuteNotifyProcessing(Notification, ConnectionResult);
	
EndProcedure

Function ConnectionResult()
	
	Result = New Structure;
	Result.Insert("AddInAttachmentError", False);
	Result.Insert("BriefErrorDescription", "");
	
	Return Result;
	
EndFunction

// Attaching a global idle handler.
//
Procedure AttachIdleBackupHandler() Export
	
	AttachIdleHandler("BackupActionsHandler", 60);
	
EndProcedure

// Disable global idle handler.
//
Procedure DisableBackupIdleHandler() Export
	
	DetachIdleHandler("BackupActionsHandler");
	
EndProcedure

Function NumberOfSecondsInPeriod(Period, PeriodType)
	
	If PeriodType = "Day" Then
		Multiplier = 3600 * 24;
	ElsIf PeriodType = "Week" Then
		Multiplier = 3600 * 24 * 7; 
	ElsIf PeriodType = "Month" Then
		Multiplier = 3600 * 24 * 30;
	ElsIf PeriodType = "Year" Then
		Multiplier = 3600 * 24 * 365;
	EndIf;
	
	Return Multiplier * Period;
	
EndFunction

#If Not WebClient AND Not MobileClient Then

// Deletes backups according to selected settings.
//
Procedure DeleteConfigurationBackups() Export
	
	// CAC:566-off code will never be executed in browser.
	
	// Clear catalog with backups.
	FixedIBBackupParameters = StandardSubsystemsClient.ClientRunParameters().IBBackup;
	StorageDirectory = FixedIBBackupParameters.BackupsStorageDirectory;
	DeletionParameters = FixedIBBackupParameters.DeletionParameters;
	
	If DeletionParameters.RestrictionType <> "StoreAll" AND StorageDirectory <> Undefined Then
		
		Try
			File = New File(StorageDirectory);
			If NOT File.IsDirectory() Then
				Return;
			EndIf;
			
			FilesArray = FindFiles(StorageDirectory, "backup????_??_??_??_??_??*", False);
			DeletedFileList = New Array;
			
			// Delete backups.
			If DeletionParameters.RestrictionType = "ByPeriod" Then
				For Each ItemFile In FilesArray Do
					CurrentDate = CommonClient.SessionDate();
					ValueInSeconds = NumberOfSecondsInPeriod(DeletionParameters.ValueInUOMs, DeletionParameters.PeriodUOM);
					Deletion = ((CurrentDate - ValueInSeconds) > ItemFile.GetModificationTime());
					If Deletion Then
						DeletedFileList.Add(ItemFile);
					EndIf;
				EndDo;
				
			ElsIf FilesArray.Count() >= DeletionParameters.CopiesCount Then
				FileList = New ValueList;
				FileList.LoadValues(FilesArray);
				
				For Each File In FileList Do
					File.Value = File.Value.GetModificationTime();
				EndDo;
				
				FileList.SortByValue(SortDirection.Desc);
				LastArchiveDate = FileList[DeletionParameters.CopiesCount-1].Value;
				
				For Each ItemFile In FilesArray Do
					
					If ItemFile.GetModificationTime() <= LastArchiveDate Then
						DeletedFileList.Add(ItemFile);
					EndIf;
					
				EndDo;
				
			EndIf;
			
			For Each DeletedFile In DeletedFileList Do
				DeleteFiles(DeletedFile.FullName);
			EndDo;
			
		Except
			
			EventLogClient.AddMessageForEventLog(EventLogEvent(), "Error",
				NStr("ru = 'Не удалось провести очистку каталога с резервными копиями.'; en = 'Failed to clean up backup storage directory.'; pl = 'Nie można oczyścić katalogu z kopiami zapasowymi.';de = 'Ein Verzeichnis mit Sicherungen kann nicht gelöscht werden.';ro = 'Eșec a golirea catalogului cu copiile de rezervă.';tr = 'Yedeklemeli bir dizin temizlenemiyor.'; es_ES = 'No se puede borrar un directorio con copias de respaldo.'") + Chars.LF 
				+ DetailErrorDescription(ErrorInfo()),,True);
			
		EndTry;
		
	EndIf;
	
	// CAC:566-on
	
EndProcedure

Function IBBackupApplicationFilesEncoding() Export
	
	// wscript.exe can process only UTF-16 LE-encoded files.
	Return TextEncoding.UTF16;
	
EndFunction

// Returns backup script parameters.
//
// Returns - Structure - structure of the backup script.
//
Function ClientBackupParameters() Export
	
	ParametersStructure = New Structure();
	ParametersStructure.Insert("ApplicationFileName", StandardSubsystemsClient.ApplicationExecutableFileName());
	ParametersStructure.Insert("EventLogEvent", NStr("ru = 'Резервное копирование ИБ'; en = 'Infobase backup'; pl = 'Rezerwowe kopiowanie bazy informacyjnej';de = 'Infobase-Sicherung';ro = 'Copierea de rezervă a BI';tr = 'Veritabanı yedeği'; es_ES = 'Copia de respaldo de la infobase'"));
	
	// Calling TempFilesDir instead of GetTempFileName as the directory cannot be deleted automatically 
	// on client application exit.
	TempFilesDirForUpdate = TempFilesDir() + "1Cv8Backup." + Format(CommonClient.SessionDate(), "DF=yymmddHHmmss") + "\";
	ParametersStructure.Insert("TempFilesDirForUpdate", TempFilesDirForUpdate);
	
	Return ParametersStructure;
	
EndFunction

#EndIf

Function BackupAvailable()
	
#If WebClient Or MobileClient Then
	Return False;
#Else
	Return CommonClient.IsWindowsClient();
#EndIf
	
EndFunction

#EndRegion
