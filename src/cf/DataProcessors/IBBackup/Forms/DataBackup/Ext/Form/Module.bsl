///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Variables

&AtClient
Var BackupInProgress;

#EndRegion

#Region EventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Not Common.IsWindowsClient() Then
		Raise NStr("ru = 'Резервное копирование и восстановление данных необходимо настроить средствами операционной системы или другими сторонними средствами.'; en = 'Set up data backup by the means of the operating system tools or third-party backup tools.'; pl = 'Tworzenie kopii zapasowych i odzyskiwanie danych muszą być konfigurowane za pomocą systemu operacyjnego lub innych narzędzi stron trzecich.';de = 'Die Sicherung und Wiederherstellung von Daten muss mit dem Betriebssystem oder anderen Tools von Drittanbietern konfiguriert werden.';ro = 'Copierea de rezervă și restabilirea datelor trebuie configurate prin mijloacele sistemului de operare sau alte mijloace terțe.';tr = 'Veri yedekleme ve geri yükleme, işletim sistemin araçları veya diğer üçüncü taraf araçları tarafından yapılandırılmalıdır.'; es_ES = 'Es necesario ajustar la creación de las copias de respaldo y la restauración de los datos con los recursos del sistema operativo o con otros recursos terceros.'");
	EndIf;
	
	If Common.IsWebClient() Then
		Raise NStr("ru = 'Резервное копирование недоступно в веб-клиенте.'; en = 'Web client does not support data backup.'; pl = 'Kopia zapasowa nie jest dostępna w kliencie www.';de = 'Die Sicherung ist im Webclient nicht verfügbar.';ro = 'Copia de rezervă nu este disponibilă în web client.';tr = 'Yedekleme web istemcisinde mevcut değildir.'; es_ES = 'Copia de respaldo no se encuentra disponible en el cliente web.'");
	EndIf;
	
	If NOT Common.FileInfobase() Then
		Raise NStr("ru = 'В клиент-серверном варианте работы резервное копирование следует выполнять сторонними средствами (средствами СУБД).'; en = 'In the client/server mode, you must back up data by the means of the DBMS.'; pl = 'Utwórz kopię zapasową danych za pomocą narzędzi zewnętrznych (narzędzia SUBD) w trybie klient/serwer.';de = 'Sichern Sie Daten mit externen Tools (DBMS-Tools) im Client / Server-Modus.';ro = 'Faceți copii de siguranță ale datelor utilizând instrumente externe (instrumente DBMS) în modul client / server.';tr = 'İstemci / sunucu modunda harici araçları (DBMS araçları) kullanarak verileri yedekleyin.'; es_ES = 'Datos de la copia de respaldo utilizando herramientas externas (herramientas DBMS) en el modo de cliente/servidor.'");
	EndIf;
	
	BackupSettings = IBBackupServer.BackupSettings();
	IBAdministratorPassword = BackupSettings.IBAdministratorPassword;
	
	If Parameters.RunMode = "ExecuteNow" Then
		Items.WizardPages.CurrentPage = Items.InformationAndBackupCreationPage;
		If Not IsBlankString(Parameters.Explanation) Then
			Items.WaitingGroup.CurrentPage = Items.WaitingForStartPage;
			Items.WaitingForBackupLabel.Title = Parameters.Explanation;
		EndIf;
	ElsIf Parameters.RunMode = "ExecuteOnExit" Then
		Items.WizardPages.CurrentPage = Items.InformationAndBackupCreationPage;
	ElsIf Parameters.RunMode = "CompletedSuccessfully" Then
		Items.WizardPages.CurrentPage = Items.BackupSuccessfulPage;
		BackupFileName = Parameters.BackupFileName;
	ElsIf Parameters.RunMode = "NotCompleted" Then
		Items.WizardPages.CurrentPage = Items.BackupCreationErrorsPage;
	EndIf;
	
	AutomaticRun = (Parameters.RunMode = "ExecuteNow" Or Parameters.RunMode = "ExecuteOnExit");
	
	If BackupSettings.Property("ManualBackupsStorageDirectory")
		AND Not IsBlankString(BackupSettings.ManualBackupsStorageDirectory)
		AND Not AutomaticRun Then
		Object.BackupDirectory = BackupSettings.ManualBackupsStorageDirectory;
	Else
		Object.BackupDirectory = BackupSettings.BackupsStorageDirectory;
	EndIf;
	
	If BackupSettings.LatestBackupDate = Date(1, 1, 1) Then
		TitleText = NStr("ru = 'Резервное копирование еще ни разу не проводилось'; en = 'The infobase has never been backed up'; pl = 'Tworzenie kopii zapasowej nigdy wcześniej nie było przeprowadzane';de = 'Sicherung wurde nie gemacht';ro = 'Copia de rezervă nu a fost făcut niciodată';tr = 'Yedekleme hiç yapılmadı'; es_ES = 'Nunca se ha creado una copia de respaldo'");
	Else
		TitleText = NStr("ru = 'В последний раз резервное копирование проводилось: %1'; en = 'Most recent backup: %1'; pl = 'Ostatnie utworzenie kopii zapasowej:%1';de = 'Letzte Sicherung: %1';ro = 'Ultima copie de siguranță: %1';tr = 'Son yedekleme: %1'; es_ES = 'Última copia de respaldo: %1'");
		LastBackupDate = Format(BackupSettings.LatestBackupDate, "DLF=DDT");
		TitleText = StringFunctionsClientServer.SubstituteParametersToString(TitleText, LastBackupDate);
	EndIf;
	Items.LastBackupDateLabel.Title = TitleText;
	
	Items.AutomaticBackupGroup.Visible = Not BackupSettings.RunAutomaticBackup;
	
	UserInformation = IBBackupServer.UserInformation();
	PasswordRequired = UserInformation.PasswordRequired;
	If PasswordRequired Then
		IBAdministrator = UserInformation.Name;
	Else
		Items.AuthorizationGroup.Visible = False;
		IBAdministratorPassword = "";
	EndIf;
	
	ManualStart = (Items.WizardPages.CurrentPage = Items.BackupCreationPage);
	
	If ManualStart Then
		
		If InfobaseSessionsCount() > 1 Then
			
			Items.BackupStatusPages.CurrentPage = Items.ActiveUsersPage;
			
		EndIf;
		
		Items.Next.Title = NStr("ru = 'Сохранить резервную копию'; en = 'Save backup'; pl = 'Zapisz kopię zapasową';de = 'Sicherung speichern';ro = 'Salvați copii de rezervă';tr = 'Yedeği kaydet'; es_ES = 'Guardar la copia de respaldo'");
		
	EndIf;
	
	IBBackupServer.SetSettingValue("LastBackupManualStart", ManualStart);
	
	Parameters.Property("ApplicationDirectory", ApplicationDirectory);
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	GoToPage(Items.WizardPages.CurrentPage);
	
#If WebClient Then
	Items.UpdateComponentVersionLabel.Visible = False;
#EndIf
	
	If Parameters.RunMode = "CompletedSuccessfully"
		AND CommonClient.SubsystemExists("OnlineUserSupport.CloudArchive") Then
		ModuleCloudArchiveClient = CommonClient.CommonModule("CloudArchiveClient");
		ModuleCloudArchiveClient.UploadFileToCloud(ThisObject.BackupFileName, 10);
	EndIf;
	
EndProcedure

&AtClient
Procedure BeforeClose(Cancel, Exit, WarningText, StandardProcessing)
	
	CurrentPage = Items.WizardPages.CurrentPage;
	If CurrentPage <> Items.WizardPages.ChildItems.InformationAndBackupCreationPage Then
		Return;
	EndIf;
	
	WarningText = NStr("ru = 'Прервать подготовку к резервному копированию данных?'; en = 'Do you want to cancel preparing for backup?'; pl = 'Czy chcesz zaprzestać przygotowanie do tworzenia kopii zapasowych?';de = 'Wollen Sie die Vorbereitung für die Sicherung stoppen?';ro = 'Doriți să întrerupeți pregătirea pentru copierea de rezervă a datelor?';tr = 'Yedeklemeye hazırlanmayı durdurmak istiyor musunuz?'; es_ES = '¿Quiere parar la preparación para la creación de la copia de respaldo?'");
	CommonClient.ShowArbitraryFormClosingConfirmation(ThisObject,
		Cancel, Exit, WarningText, "ForceCloseForm");
	
EndProcedure

&AtClient
Procedure OnClose(Exit)
	
	If Exit Then
		Return;
	EndIf;
	
	DetachIdleHandler("Timeout");
	DetachIdleHandler("CheckForSingleConnection");
	DetachIdleHandler("EndUserSessions");
	
	If BackupInProgress = True Then
		Return;
	EndIf;
	
	IBConnectionsClient.SetTerminateAllSessionsExceptCurrentFlag(False);
	IBConnectionsClient.SetUserTerminationInProgressFlag(False);
	IBConnectionsServerCall.AllowUserAuthorization();
	
	If ProcessRunning() Then
		ProcessRunning(False);
	EndIf;
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	If EventName = "UserSessionsCompletion" AND Parameter.SessionCount <= 1
		AND ApplicationParameters["StandardSubsystems.InfobaseBackupParameters"].ProcessRunning Then
			StartBackup();
	EndIf;
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure UsersListClick(Item)
	
	StandardSubsystemsClient.OpenActiveUserList(, ThisObject);
	
EndProcedure

&AtClient
Procedure PathToArchiveDirectoryStartChoice(Item, ChoiceData, StandardProcessing)
	
	SelectedPath = GetPath(FileDialogMode.ChooseDirectory);
	If Not IsBlankString(SelectedPath) Then 
		Object.BackupDirectory = SelectedPath;
	EndIf;

EndProcedure

&AtClient
Procedure BackupFileNameOpen(Item, StandardProcessing)
	
	StandardProcessing = False;
	FileSystemClient.OpenExplorer(BackupFileName);
	
EndProcedure

#EndRegion

#Region FormCommandHandlers

&AtClient
Procedure Next(Command)
	
	ClearMessages();
	
	If Not CheckAttributeFilling() Then
		Return;
	EndIf;
	
	CurrentWizardPage = Items.WizardPages.CurrentPage;
	If CurrentWizardPage = Items.WizardPages.ChildItems.BackupCreationPage Then
		
		GoToPage(Items.InformationAndBackupCreationPage);
		SetBackupArchivePath(Object.BackupDirectory);
		
	Else
		
		Close();
		
	EndIf;
	
EndProcedure

&AtClient
Procedure Cancel(Command)
	
	Close();
	
EndProcedure

&AtClient
Procedure GoToEventLog(Command)
	OpenForm("DataProcessor.EventLog.Form.EventLog", , ThisObject);
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure GoToPage(NewPage)
	
	GoToNext = True;
	SubordinatePages = Items.WizardPages.ChildItems;
	If NewPage = SubordinatePages.InformationAndBackupCreationPage Then
		GoToInformationAndBackupPage(GoToNext);
	ElsIf NewPage = SubordinatePages.BackupCreationErrorsPage 
		OR NewPage = SubordinatePages.BackupSuccessfulPage Then
		GoToBackupResultsPage();
	EndIf;
	
	If Not GoToNext Then
		Return;
	EndIf;
	
	If NewPage <> Undefined Then
		Items.WizardPages.CurrentPage = NewPage;
	Else
		Close();
	EndIf;
	
EndProcedure

&AtClient
Procedure GoToInformationAndBackupPage(GoToNext)
	
	If Not CheckAttributeFilling(False) Then
		Items.WizardPages.CurrentPage = Items.BackupCreationErrorsPage;
		GoToNext = False;
		Return;
	EndIf;
	
	Notification = New NotifyDescription(
		"GoToPageBackupAfterInfobaseAccessCheck", ThisObject);
	
	IBBackupClient.CheckAccessToInfobase(IBAdministratorPassword, Notification);
	
EndProcedure

&AtClient
Procedure GoToPageBackupAfterInfobaseAccessCheck(ConnectionResult, 
	Context) Export
	
	If ConnectionResult.AddInAttachmentError Then
		Items.BackupStatusPages.CurrentPage = Items.ConnectionErrorPage;
		ConnectionErrorFound = ConnectionResult.BriefErrorDescription;
		Return;
	Else
		SetBackupParemeters();
	EndIf;
	
	ProcessRunning(True);
	
	InfobaseSessionsCount = InfobaseSessionsCount();
	Items.ActiveUserCount.Title = InfobaseSessionsCount;
	
	Items.Cancel.Enabled = True;
	Items.Next.Enabled = False;
	SetButtonTitleNext(True);
	
	IBConnectionsServerCall.SetConnectionLock(NStr("ru = 'Выполняется восстановление информационной базы.'; en = 'Restoring the infobase.'; pl = 'Wykonuje się odzyskiwanie bazy informacyjnej:';de = 'Die Wiederherstellung der Infobase läuft gerade.';ro = 'Are loc restaurarea bazei de informații.';tr = 'Veritabanı kurtarma işlemi devam ediyor.'; es_ES = 'Recuperación de la infobase está en progreso.'"), "Backup");
	
	If InfobaseSessionsCount = 1 Then
		IBConnectionsClient.SetTerminateAllSessionsExceptCurrentFlag(True);
		IBConnectionsClient.SetUserTerminationInProgressFlag(True);
		StartBackup();
	Else
		CheckForBlockingSessions();
		
		IBConnectionsClient.SetSessionTerminationHandlers(True);
		SetIdleIdleHandlerOfBackupStart();
		SetIdleHandlerOfBackupTimeout();
	EndIf;
	
EndProcedure

&AtServer
Procedure CheckForBlockingSessions()
	
	BlockingSessionsInformation = IBConnections.BlockingSessionsInformation("");
	HasBlockingSessions = BlockingSessionsInformation.HasBlockingSessions;
	
	If HasBlockingSessions Then
		Items.ActiveSessionsDecoration.Title = BlockingSessionsInformation.MessageText;
	EndIf;
	
	Items.ActiveSessionsDecoration.Visible = HasBlockingSessions;
	
EndProcedure

&AtClient
Procedure GoToBackupResultsPage()
	
	Items.Next.Visible= False;
	Items.Cancel.Title = NStr("ru = 'Закрыть'; en = 'Close'; pl = 'Zamknij';de = 'Schließen';ro = 'Închideți';tr = 'Kapat'; es_ES = 'Cerrar'");
	Items.Cancel.DefaultButton = True;
	BackupParameters = BackupSettings();
	IBBackupClient.FillGlobalVariableValues(BackupParameters);
	SetBackupResult();
	
EndProcedure

&AtServerNoContext
Procedure SetBackupResult()
	
	IBBackupServer.SetBackupResult();
	
EndProcedure

&AtServer
Procedure SetBackupParemeters()
	
	BackupParameters = IBBackupServer.BackupSettings();
	
	BackupParameters.Insert("IBAdministrator", IBAdministrator);
	BackupParameters.Insert("IBAdministratorPassword", ?(PasswordRequired, IBAdministratorPassword, ""));
	
	IBBackupServer.SetBackupParemeters(BackupParameters);
	
EndProcedure

&AtServerNoContext
Function BackupSettings()
	
	Return IBBackupServer.BackupSettings();
	
EndFunction

&AtClient
Function CheckAttributeFilling(ShowError = True)

#If WebClient Then
	MessageText = NStr("ru = 'Создание резервной копии не доступно в веб-клиенте.'; en = 'Web client does not support data backup.'; pl = 'Tworzenie kopii zapasowej nie jest dostępne w kliencie Web.';de = 'Eine Sicherung ist im Webclient nicht verfügbar.';ro = 'Crearea copiei de rezervă nu este accesibilă în web-client.';tr = 'Web istemcide yedekleme yapılamaz.'; es_ES = 'La creación de la copia de respaldo no está disponible en el cliente web.'");
	CommonClient.MessageToUser(MessageText);
	AttributesFilled = False;
#Else
	
	AttributesFilled = True;
	
	Object.BackupDirectory = TrimAll(Object.BackupDirectory);
	
	If IsBlankString(Object.BackupDirectory) Then
		
		MessageText = NStr("ru = 'Не выбран каталог для резервной копии.'; en = 'Backup directory is not provided.'; pl = 'Nie wybrano katalogu dla kopii rezerwowej.';de = 'Sicherungsverzeichnis ist nicht ausgewählt.';ro = 'Directorul de copii de rezerva nu este selectat.';tr = 'Yedekleme dizini seçilmedi.'; es_ES = 'Directorio de la copia de respaldo no se ha seleccionado.'");
		RecordAttributeCheckError(MessageText, "Object.BackupDirectory", ShowError);
		AttributesFilled = False;
		
	ElsIf FindFiles(Object.BackupDirectory).Count() = 0 Then
		
		MessageText = NStr("ru = 'Указан несуществующий каталог.'; en = 'The provided directory does not exist.'; pl = 'Podano nieistniejący katalog.';de = 'Nicht existierendes Verzeichnis ist angegeben.';ro = 'Se specifică directorul neexistent.';tr = 'Mevcut olmayan dizin belirlendi.'; es_ES = 'Directorio no existente está especificado.'");
		RecordAttributeCheckError(MessageText, "Object.BackupDirectory", ShowError);
		AttributesFilled = False;
		
	Else
		
		Try
			TestFile = New XMLWriter;
			TestFile.OpenFile(Object.BackupDirectory + "/test.test1C");
			TestFile.WriteXMLDeclaration();
			TestFile.Close();
		Except
			MessageText = NStr("ru = 'Нет доступа к каталогу с резервными копиями.'; en = 'Failed to access backup directory.'; pl = 'Nie można uzyskać dostępu do katalogu z kopiami zapasowymi.';de = 'Zugriff auf das Verzeichnis mit Sicherungen nicht möglich.';ro = 'Nu se poate accesa directorul cu copii de rezervă.';tr = 'Dizine yedeklerle erişilemiyor.'; es_ES = 'No se puede acceder el directorio con copias de respaldo.'");
			RecordAttributeCheckError(MessageText, "Object.BackupDirectory", ShowError);
			AttributesFilled = False;
		EndTry;
		
		If AttributesFilled Then
			
			// CAC:280-off Exceptions are not processed as files are not deleted on this step.
			Try
				DeleteFiles(Object.BackupDirectory, "*.test1C");
			Except
			EndTry;
			// CAC:280-off
			
		EndIf;
		
	EndIf;
	
	If PasswordRequired AND IsBlankString(IBAdministratorPassword) Then
		
		MessageText = NStr("ru = 'Не задан пароль администратора.'; en = 'Administrator password is not set.'; pl = 'Hasło administratora nie zostało określone.';de = 'Administrator-Kennwort ist nicht angegeben.';ro = 'Parola de administrator nu este specificată.';tr = 'Yönetici şifresi belirtilmemiş.'; es_ES = 'Contraseña del administrador no está especificada.'");
		RecordAttributeCheckError(MessageText, "IBAdministratorPassword", ShowError);
		AttributesFilled = False;
		
	EndIf;

#EndIf
	
	Return AttributesFilled;
	
EndFunction

&AtClient
Procedure RecordAttributeCheckError(ErrorText, AttributePath, ShowError)
	
	If ShowError Then
		CommonClient.MessageToUser(ErrorText,, AttributePath);
	Else
		EventLogClient.AddMessageForEventLog(IBBackupClient.EventLogEvent(),
			"Error", ErrorText, , True);
	EndIf;
	
EndProcedure

&AtClient
Procedure SetIdleHandlerOfBackupTimeout()
	
	AttachIdleHandler("Timeout", 300, True);
	
EndProcedure

&AtClient
Procedure Timeout()
	
	DetachIdleHandler("CheckForSingleConnection");
	QuestionText = NStr("ru = 'Не удалось отключить всех пользователей от базы. Провести резервное копирование? (возможны ошибки при архивации)'; en = 'Cannot terminate all user sessions. Are you sure you still want to back up the data? The backup might contain errors.'; pl = 'Nie można odłączyć wszystkich użytkowników od tej bazy. Utworzyć kopię zapasową danych? (podczas tworzenia kopii zapasowej mogą wystąpić błędy)';de = 'Es können nicht alle Benutzer von der Basis getrennt werden. Sichern Sie die Daten? (Fehler können während der Sicherung auftreten)';ro = 'Nu pot fi deconectați toți utilizatorii de la bază. Executați copierea de rezervă? (pot apărea erori la arhivare)';tr = 'Tüm kullanıcılar tabandan kesilemez. Veriler yedeklensin mi? (yedekleme sırasında hatalar oluşabilir)'; es_ES = 'No se puede desconectar todos usuarios de la base. ¿Crear una copia de respaldo de los datos? (errores pueden ocurrir durante la creación de la copia de respaldo)'");
	NoteText = NStr("ru = 'Не удалось отключить пользователя.'; en = 'Cannot terminate the user session.'; pl = 'Nie można wyłączyć użytkownika.';de = 'Der Benutzer kann nicht deaktiviert werden.';ro = 'Nu se poate dezactiva utilizatorul.';tr = 'Kullanıcı devre dışı bırakılamaz.'; es_ES = 'No se puede desactivar el usuario.'");
	NotifyDescription = New NotifyDescription("ExpiringTimeoutCompletion", ThisObject);
	ShowQueryBox(NotifyDescription, QuestionText, QuestionDialogMode.YesNo, 30, DialogReturnCode.No, NoteText, DialogReturnCode.No);
	
EndProcedure

&AtClient
Procedure ExpiringTimeoutCompletion(Response, AdditionalParameters) Export
	
	If Response = DialogReturnCode.Yes Then
		StartBackup();
	Else
		ClearMessages();
		IBConnectionsClient.SetTerminateAllSessionsExceptCurrentFlag(False);
		CancelPreparation();
EndIf;
	
EndProcedure

&AtServer
Procedure CancelPreparation()
	
	Items.FailedLabel.Title = StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = '%1.
		|Подготовка к резервному копированию отменена. Информационная база разблокирована.'; 
		|en = '%1.
		|Preparation for backing up is canceled. Infobase is unlocked.'; 
		|pl = '%1.
		|Przygotowanie do tworzenia kopii zapasowej zostanie anulowane. Baza informacyjna jest zablokowana.';
		|de = '%1.
		|Die Vorbereitung für eine Sicherung wird abgebrochen. Infobase ist gesperrt.';
		|ro = '%1.
		|Pregătirea pentru copierea de rezervă este revocată. Baza de date este deblocată.';
		|tr = '%1. 
		| Yedekleme için hazırlık iptal edildi. Veritabanı kilitlendi.'; 
		|es_ES = '%1.
		|Preparación para una copia de respaldo se ha cancelado. Infobase está bloqueada.'"),
		IBConnections.ActiveSessionsMessage());
	Items.WizardPages.CurrentPage = Items.BackupCreationErrorsPage;
	Items.GoToEventLog1.Visible = False;
	Items.Next.Visible = False;
	Items.Cancel.Title = NStr("ru = 'Закрыть'; en = 'Close'; pl = 'Zamknij';de = 'Schließen';ro = 'Închideți';tr = 'Kapat'; es_ES = 'Cerrar'");
	Items.Cancel.DefaultButton = True;
	
	IBConnections.AllowUserAuthorization();
	
EndProcedure

&AtClient
Procedure SetIdleIdleHandlerOfBackupStart()
	
	AttachIdleHandler("CheckForSingleConnection", 5);
	
EndProcedure

&AtClient
Procedure CheckForSingleConnection()
	
	UsersCount = InfobaseSessionsCount();
	Items.ActiveUserCount.Title = String(UsersCount);
	If UsersCount = 1 Then
		StartBackup();
	Else
		CheckForBlockingSessions();
	EndIf;
	
EndProcedure

&AtClient
Procedure SetButtonTitleNext(ThisButtonNext)
	
	Items.Next.Title = ?(ThisButtonNext, NStr("ru = 'Далее >'; en = 'Next >'; pl = 'Dalej >';de = 'Weiter >';ro = 'Următorul >';tr = 'Sonraki >'; es_ES = 'Siguiente >'"), NStr("ru = 'Готово'; en = 'Finish'; pl = 'Koniec';de = 'Abschluss';ro = 'Sfârșit';tr = 'Bitiş'; es_ES = 'Finalizar'"));
	
EndProcedure

&AtClient
Function GetPath(DialogMode)
	
	Mode = DialogMode;
	OpenFileDialog = New FileDialog(Mode);
	If Mode = FileDialogMode.ChooseDirectory Then
		OpenFileDialog.Title= NStr("ru = 'Выберите каталог'; en = 'Select directory'; pl = 'Wybierz folder';de = 'Wählen Sie das Verzeichnis aus';ro = 'Selectați directorul';tr = 'Dizini seçin'; es_ES = 'Seleccionar el directorio'");
	Else
		OpenFileDialog.Title= NStr("ru = 'Выберите файл'; en = 'Select file'; pl = 'Wybierz plik';de = 'Datei auswählen';ro = 'Selectați fișierul';tr = 'Dosya seç'; es_ES = 'Seleccionar un archivo'");
	EndIf;	
		
	If OpenFileDialog.Choose() Then
		If DialogMode = FileDialogMode.ChooseDirectory Then
			Return OpenFileDialog.Directory;
		Else
			Return OpenFileDialog.FullFileName;
		EndIf;
	EndIf;
	
EndFunction

&AtClient
Procedure StartBackup()
	
#If Not WebClient AND Not MobileClient Then
	
	MainScriptFileName = GenerateUpdateScriptFiles();
	
	EventLogClient.AddMessageForEventLog(
		IBBackupClient.EventLogEvent(),
		"Information", 
		NStr("ru = 'Выполняется резервное копирование информационной базы:'; en = 'Backing up the infobase backup:'; pl = 'Wykonuje się rezerwowe kopiowanie bazy informacyjnej:';de = 'Infobase-Sicherung läuft:';ro = 'Baza de date de rezervă este în curs de desfășurare:';tr = 'Veritabanı yedekleniyor:'; es_ES = 'Copia de respaldo de la infobase está en progreso:'") + " " + MainScriptFileName);
		
	If Parameters.RunMode = "ExecuteNow" Or Parameters.RunMode = "ExecuteOnExit" Then
		IBBackupClient.DeleteConfigurationBackups();
	EndIf;
	
	BackupInProgress = True;
	ForceCloseForm = True;
	
	ApplicationParameters.Insert("StandardSubsystems.SkipExitConfirmation", True);
	
	PathToLauncher = StandardSubsystemsClient.SystemApplicationFolder() + "mshta.exe";
	
	CommandLine = """%1"" ""%2"" [p1]%3[/p1]";
	CommandLine = StringFunctionsClientServer.SubstituteParametersToString(
		CommandLine,
		PathToLauncher, 
		MainScriptFileName, 
		IBBackupClient.StringUnicode(IBAdministratorPassword));
	
	ApplicationStartupParameters = FileSystemClient.ApplicationStartupParameters();
	ApplicationStartupParameters.Notification = New NotifyDescription("AfterStartScript", ThisObject);
	ApplicationStartupParameters.WaitForCompletion = False;
	
	FileSystemClient.StartApplication(CommandLine, ApplicationStartupParameters);
	
#EndIf
	
EndProcedure

&AtClient
Procedure AfterStartScript(Result, Context) Export
	
	If Result.ApplicationStarted Then 
		Exit(False);
	Else 
		ShowMessageBox(, Result.ErrorDescription);
	EndIf;
	
EndProcedure

/////////////////////////////////////////////////////////////////////////////////////////////////////////
// Handlers of form events on the server and changes of backup settings.

&AtServerNoContext
Procedure SetBackupArchivePath(Path)
	
	PathSettings = IBBackupServer.BackupSettings();
	PathSettings.Insert("ManualBackupsStorageDirectory", Path);
	IBBackupServer.SetBackupParemeters(PathSettings);
	
EndProcedure

//////////////////////////////////////////////////////////////////////////////////////////////////////////
// Procedures and functions of backup preparation.

#If Not WebClient AND Not MobileClient Then

&AtClient
Function GenerateUpdateScriptFiles()
	
	BackupParameters = IBBackupClient.ClientBackupParameters();
	ClientRunParametersOnStart = StandardSubsystemsClient.ClientParametersOnStart();
	CreateDirectory(BackupParameters.TempFilesDirForUpdate);
	
	// Parameters structure is necessary to determine them on the client and transfer to the server.
	ParametersStructure = New Structure;
	ParametersStructure.Insert("ApplicationFileName"            , BackupParameters.ApplicationFileName);
	ParametersStructure.Insert("EventLogEvent"    , BackupParameters.EventLogEvent);
	ParametersStructure.Insert("COMConnectorName"            , ClientRunParametersOnStart.COMConnectorName);
	ParametersStructure.Insert("IsBaseConfigurationVersion" , ClientRunParametersOnStart.IsBaseConfigurationVersion);
	ParametersStructure.Insert("ScriptParameters"             , IBBackupClient.UpdateAdministratorAuthenticationParameters(IBAdministratorPassword));
	ParametersStructure.Insert("EnterpriseStartParameters"  , CommonInternalClient.EnterpriseStartupParametersFromScript());
	
	TemplatesNames = "AddlBackupFile";
	TemplatesNames = TemplatesNames + ",BackupSplash";
	TemplatesTexts = GetTemplateTexts(TemplatesNames, ParametersStructure, ApplicationParameters["StandardSubsystems.MessagesForEventLog"]);
	
	ScriptFile = New TextDocument;
	ScriptFile.Output = UseOutput.Enable;
	ScriptFile.SetText(TemplatesTexts[0]);
	
	ScriptFileName = BackupParameters.TempFilesDirForUpdate + "main.js";
	ScriptFile.Write(ScriptFileName, IBBackupClient.IBBackupApplicationFilesEncoding());
	
	// Auxiliary file: helpers.js.
	ScriptFile = New TextDocument;
	ScriptFile.Output = UseOutput.Enable;
	ScriptFile.SetText(TemplatesTexts[1]);
	ScriptFile.Write(BackupParameters.TempFilesDirForUpdate + "helpers.js", IBBackupClient.IBBackupApplicationFilesEncoding());
	
	MainScriptFileName = Undefined;
	// Auxiliary file: splash.png.
	PictureLib.ExternalOperationSplash.Write(BackupParameters.TempFilesDirForUpdate + "splash.png");
	// Auxiliary file: splash.ico.
	PictureLib.ExternalOperationSplashIcon.Write(BackupParameters.TempFilesDirForUpdate + "splash.ico");
	// Auxiliary  file: progress.gif.
	PictureLib.TimeConsumingOperation48.Write(BackupParameters.TempFilesDirForUpdate + "progress.gif");
	// Main splash screen file: splash.hta.
	MainScriptFileName = BackupParameters.TempFilesDirForUpdate + "splash.hta";
	ScriptFile = New TextDocument;
	ScriptFile.Output = UseOutput.Enable;
	ScriptFile.SetText(TemplatesTexts[2]);
	ScriptFile.Write(MainScriptFileName, IBBackupClient.IBBackupApplicationFilesEncoding());
	
	LogFile = New TextDocument;
	LogFile.Output = UseOutput.Enable;
	LogFile.SetText(StandardSubsystemsClient.SupportInformation());
	LogFile.Write(BackupParameters.TempFilesDirForUpdate + "templog.txt", TextEncoding.System);
	
	Return MainScriptFileName;
	
EndFunction

#EndIf

&AtServer
Function GetTemplateTexts(TemplatesNames, ParametersStructure, MessagesForEventLog)
	
	// Writing accumulated events to the event log.
	EventLogOperations.WriteEventsToEventLog(MessagesForEventLog);
		
	Result = New Array();
	Result.Add(GetScriptText(ParametersStructure));
	
	TemplateNamesArray = StrSplit(TemplatesNames, ",");
	
	For each TemplateName In TemplateNamesArray Do
		Result.Add(DataProcessors.IBBackup.GetTemplate(TemplateName).GetText());
	EndDo;
	
	Return Result;
	
EndFunction

&AtServer
Function GetScriptText(ParametersStructure)
	
	// Configuration update file: main.js.
	ScriptTemplate = DataProcessors.IBBackup.GetTemplate("BackupFileTemplate");
	
	Script = ScriptTemplate.GetArea("ParametersArea");
	Script.DeleteLine(1);
	Script.DeleteLine(Script.LineCount());
	
	Text = ScriptTemplate.GetArea("BackupArea");
	Text.DeleteLine(1);
	Text.DeleteLine(Text.LineCount());
	
	Return InsertScriptParameters(Script.GetText(), ParametersStructure) + Text.GetText();
	
EndFunction

&AtServer
Function InsertScriptParameters(Val Text, Val ParametersStructure)
	
	Result = Text;
	
	ScriptParameters = ParametersStructure.ScriptParameters;
	InfobaseConnectionString = ScriptParameters.InfobaseConnectionString + ScriptParameters.StringForConnection;
	
	If StrEndsWith(InfobaseConnectionString, ";") Then
		InfobaseConnectionString = Left(InfobaseConnectionString, StrLen(InfobaseConnectionString) - 1);
	EndIf;
	
	ApplicationDirectory = ?(IsBlankString(ApplicationDirectory), BinDir(), ApplicationDirectory);
	NameOfExecutableApplicationFile = ApplicationDirectory + ParametersStructure.ApplicationFileName;
	
	// Determining path to the infobase.
	FileModeFlag = Undefined;
	InfobasePath = IBConnectionsClientServer.InfobasePath(FileModeFlag, 0);
	
	InfobasePathParameter = ?(FileModeFlag, "/F", "/S") + InfobasePath; 
	InfobasePathString	= ?(FileModeFlag, InfobasePath, "");
	
	DirectoryString = CheckDirectoryForRootItemIndication(Object.BackupDirectory);
	
	Result = StrReplace(Result, "[NameOfExecutableApplicationFile]"     , PrepareText(NameOfExecutableApplicationFile));
	Result = StrReplace(Result, "[InfobasePathParameter]"   , PrepareText(InfobasePathParameter));
	Result = StrReplace(Result, "[InfobaseFilePathString]", PrepareText(CommonClientServer.AddLastPathSeparator(StrReplace(InfobasePathString, """", ""))));
	Result = StrReplace(Result, "[InfobaseConnectionString]", PrepareText(InfobaseConnectionString));
	Result = StrReplace(Result, "[NameOfUpdateAdministrator]"       , PrepareText(UserName()));
	Result = StrReplace(Result, "[EventLogEvent]"         , PrepareText(ParametersStructure.EventLogEvent));
	Result = StrReplace(Result, "[CreateDataBackup]"           , "true");
	Result = StrReplace(Result, "[BackupDirectory]"             , PrepareText(DirectoryString + "\backup" + DirectoryStringFromDate()));
	Result = StrReplace(Result, "[RestoreInfobase]" , "false");
	Result = StrReplace(Result, "[COMConnectorName]"                 , PrepareText(ParametersStructure.COMConnectorName));
	Result = StrReplace(Result, "[UseCOMConnector]"        , ?(ParametersStructure.IsBaseConfigurationVersion, "false", "true"));
	Result = StrReplace(Result, "[ExecuteOnExit]"      , ?(Parameters.RunMode = "ExecuteOnExit", "true", "false"));
	Result = StrReplace(Result, "[EnterpriseStartParameters]"       , PrepareText(ParametersStructure.EnterpriseStartParameters));
	
	Return Result;
	
EndFunction

&AtServer
Function CheckDirectoryForRootItemIndication(DirectoryString)
	
	If StrEndsWith(DirectoryString, ":\") Then
		Return Left(DirectoryString, StrLen(DirectoryString) - 1) ;
	Else
		Return DirectoryString;
	EndIf;
	
EndFunction

&AtServer
Function DirectoryStringFromDate()
	
	ReturnString = "";
	DateNow = CurrentSessionDate();
	ReturnString = Format(DateNow, "DF = yyyy_mm_dd_HH_mm_ss");
	Return ReturnString;
	
EndFunction

&AtServer
Function PrepareText(Val Text)
	
	Row = StrReplace(Text, "\", "\\");
	Row = StrReplace(Row, "'", "\'");
	
	Return StringFunctionsClientServer.SubstituteParametersToString("'%1'", Row);
	
EndFunction

&AtClient
Procedure LableUpdateComponentVersionURLProcessing(Item, URL, StandardProcessing)
	
	StandardProcessing = False;
	CommonClient.RegisterCOMConnector();
	
EndProcedure

&AtServerNoContext
Function InfobaseSessionsCount()
	
	Return IBConnections.InfobaseSessionCount(False, False);
	
EndFunction

&AtClient
Function ProcessRunning(Value = Undefined)
	
	ParameterName = "StandardSubsystems.InfobaseBackupParameters";
	If ApplicationParameters[ParameterName] = Undefined Then
		BackupParameters = BackupSettings();
		IBBackupClient.FillGlobalVariableValues(BackupParameters);
		ApplicationParameters[ParameterName].ProcessRunning = False;
	EndIf;
	
	If Value <> Undefined Then
		ApplicationParameters[ParameterName].ProcessRunning = Value;
		IBBackupServerCall.SetSettingValue("ProcessRunning", Value);
	Else
		Return ApplicationParameters[ParameterName].ProcessRunning;
	EndIf;
	
EndFunction

#EndRegion
