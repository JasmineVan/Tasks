///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Variables

&AtClient
Var WriteSettings, MinDateOfNextAutomaticBackup;

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
	
	BackupSettings = IBBackupServer.BackupSettings();
	
	Object.ExecutionOption = BackupSettings.ExecutionOption;
	Object.RunAutomaticBackup = BackupSettings.RunAutomaticBackup;
	Object.BackupConfigured = BackupSettings.BackupConfigured;
	
	If Not Object.BackupConfigured Then
		Object.RunAutomaticBackup = True;
	EndIf;
	IsBaseConfigurationVersion = StandardSubsystemsServer.IsBaseConfigurationVersion();
	Items.Normal.Visible = Not IsBaseConfigurationVersion;
	Items.Basic.Visible = IsBaseConfigurationVersion;
	
	IBAdministratorPassword = BackupSettings.IBAdministratorPassword;
	Schedule = CommonClientServer.StructureToSchedule(BackupSettings.CopyingSchedule);
	Items.EditSchedule.Title = String(Schedule);
	Object.BackupDirectory = BackupSettings.BackupsStorageDirectory;
	
	// Filling settings for storing old copies.
	
	FillPropertyValues(Object, BackupSettings.DeletionParameters);
	
	UpdateBackupDirectoryRestrictionType(ThisObject);
	
	UserInformation = IBBackupServer.UserInformation();
	PasswordRequired = UserInformation.PasswordRequired;
	If PasswordRequired Then
		IBAdministrator = UserInformation.Name;
	Else
		Items.AuthorizationGroup.Visible = False;
		Items.InfobaseAdministratorAuthorization.Visible = False;
		IBAdministratorPassword = "";
	EndIf;
	
	SetVisibilityAvailability();
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	Settings = ApplicationParameters["StandardSubsystems.InfobaseBackupParameters"];
	If Settings = Undefined Then
		Cancel = True;
		Return;
	EndIf;	
	
	MinDateOfNextAutomaticBackup = Settings.MinDateOfNextAutomaticBackup;
	Settings.MinDateOfNextAutomaticBackup = '29990101';
	WriteSettings = False;
	
EndProcedure

&AtClient
Procedure OnClose(Exit)
	
	If WriteSettings Then
		ParameterName = "IBBackupOnExit";
		ParametersOnExit = New Structure(StandardSubsystemsClient.ClientParameter(ParameterName));
		ParametersOnExit.ExecuteOnExit = Object.RunAutomaticBackup
			AND Object.ExecutionOption = "OnExit";
		ParametersOnExit = New FixedStructure(ParametersOnExit);
		StandardSubsystemsClient.SetClientParameter(ParameterName, ParametersOnExit);
	Else
		ParameterName = "StandardSubsystems.InfobaseBackupParameters";
		ApplicationParameters[ParameterName].MinDateOfNextAutomaticBackup
			= MinDateOfNextAutomaticBackup;
	EndIf;
	
	If Exit Then
		Return;
	EndIf;
	
	Notify("BackupSettingsFormClosed");
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure RunAutomaticBackupOnChange(Item)
	
	SetVisibilityAvailability();
	
EndProcedure

&AtClient
Procedure BackupDirectoryRestrictionTypeOnChange(Item)
	
	
	UpdateBackupDirectoryRestrictionType(ThisObject);
	
EndProcedure

&AtClient
Procedure PathToArchiveDirectoryStartChoice(Item, ChoiceData, StandardProcessing)
	
	OpenFileDialog = New FileDialog(FileDialogMode.ChooseDirectory);
	OpenFileDialog.Title= NStr("ru = 'Выберите каталог для сохранения резервных копий'; en = 'Choose a directory to save backups to'; pl = 'Wybierz katalog dla kopii zapasowych';de = 'Wählen Sie ein Verzeichnis zum Speichern von Sicherungen aus';ro = 'Selectați directorul pentru salvarea copiilor de rezervă';tr = 'Yedeklerin kaydedileceği klasörü seç'; es_ES = 'Seleccione un catálogo para guardar las copias de respaldo'");
	OpenFileDialog.Directory = Items.BackupDirectory.EditText;
	
	If OpenFileDialog.Choose() Then
		Object.BackupDirectory = OpenFileDialog.Directory;
	EndIf;
	
EndProcedure

&AtClient
Procedure LabelGoToEventLogClick(Item)
	OpenForm("DataProcessor.EventLog.Form.EventLog", , ThisObject);
EndProcedure

&AtClient
Procedure BackupOptionOnChange(Item)
	
	Items.EditSchedule.Enabled = (Object.ExecutionOption = "Schedule");
	
EndProcedure

&AtClient
Procedure BackupStoragePeriodUOMClear(Item, StandardProcessing)
	
	StandardProcessing = False;
	
EndProcedure

#EndRegion

#Region FormCommandHandlers

&AtClient
Procedure Finish(Command)
	
	WriteSettings = True;
	GoFromSettingPage();
	
EndProcedure

&AtClient
Procedure EditSchedule(Command)
	
	ScheduleDialog = New ScheduledJobDialog(Schedule);
	NotifyDescription = New NotifyDescription("ChangeScheduleCompletion", ThisObject);
	ScheduleDialog.Show(NotifyDescription);
	
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure GoFromSettingPage()
	
	IBParameters = ApplicationParameters["StandardSubsystems.InfobaseBackupParameters"];
	CurrentUser = UsersClient.CurrentUser();
	
	If Object.RunAutomaticBackup Then
		
		If Not CheckDirectoryWithBackups() Then
			Return;
		EndIf;
		
		Context = New Structure;
		Context.Insert("InfobaseBackupParameters", IBParameters);
		Context.Insert("CurrentUser", CurrentUser);
		
		Notification = New NotifyDescription(
			"NavigateFromSettingPageAfterCheckAccessToInfobase", ThisObject, Context);
		
		IBBackupClient.CheckAccessToInfobase(IBAdministratorPassword, Notification);
		Return;
	EndIf;
		
	StopNotificationService(CurrentUser);
	IBBackupClient.DisableBackupIdleHandler();
	IBParameters.MinDateOfNextAutomaticBackup = '29990101';
	IBParameters.NotificationParameter = "DoNotNotify";
	
	RefreshReusableValues();
	Close();
	
EndProcedure

&AtClient
Procedure NavigateFromSettingPageAfterCheckAccessToInfobase(ConnectionResult, Context) Export
	
	IBBackupParameters = Context.InfobaseBackupParameters;
	CurrentUser = Context.CurrentUser;
	
	If ConnectionResult.AddInAttachmentError Then
		Items.WizardPages.CurrentPage = Items.AdditionalSettings;
		ConnectionErrorFound = ConnectionResult.BriefErrorDescription;
		Return;
	EndIf;
	
	WriteSettings(CurrentUser);
	
	If Object.ExecutionOption = "Schedule" Then
		CurrentDate = CommonClient.SessionDate();
		IBBackupParameters.MinDateOfNextAutomaticBackup = CurrentDate;
		IBBackupParameters.LatestBackupDate = CurrentDate;
		IBBackupParameters.ScheduleValue = Schedule;
	ElsIf Object.ExecutionOption = "OnExit" Then
		IBBackupParameters.MinDateOfNextAutomaticBackup = '29990101';
	EndIf;
	
	IBBackupClient.AttachIdleBackupHandler();
	
	SettingsFormName = "e1cib/app/DataProcessor.IBBackupSetup/";
	
	ShowUserNotification(NStr("ru = 'Резервное копирование'; en = 'Backup'; pl = 'Kopia zapasowa';de = 'Sicherungskopie';ro = 'Copie de rezervă';tr = 'Yedek'; es_ES = 'Copia de respaldo'"), SettingsFormName,
		NStr("ru = 'Резервное копирование настроено.'; en = 'Backup is all set up.'; pl = 'Kopia zapasowa została skonfigurowana';de = 'Die Sicherung ist eingerichtet.';ro = 'Copia de rezervă este configurată.';tr = 'Yedekleme ayarlandı.'; es_ES = 'Copia de respaldo se ha configurado.'"));
	
	IBBackupParameters.NotificationParameter = "DoNotNotify";
	
	RefreshReusableValues();
	Close();
	
EndProcedure

&AtClient
Function CheckDirectoryWithBackups()
	
#If WebClient OR MobileClient Then
	MessageText = NStr("ru = 'Для корректной работы необходим режим тонкого или толстого клиента.'; en = 'Thin client or thick client is required.'; pl = 'Aby wszystko działało poprawnie, potrzebujesz cienkiego lub grubego trybu klienta.';de = 'Für den korrekten Betrieb ist der Thin- oder Thick-Client-Modus erforderlich.';ro = 'Pentru lucrul corect este necesar regimul de thin-client sau fat-client.';tr = 'Doğu çalışma için ince veya kalın istemci modu gerekmektedir.'; es_ES = 'Para el funcionamiento correcto es necesario el modo del cliente ligero o grueso.'");
	CommonClient.MessageToUser(MessageText);
	AttributesFilled = False;
#Else
	AttributesFilled = True;
	
	If IsBlankString(Object.BackupDirectory) Then
		
		MessageText = NStr("ru = 'Не выбран каталог для резервной копии.'; en = 'Backup directory is not provided.'; pl = 'Nie wybrano katalogu dla kopii rezerwowej.';de = 'Sicherungsverzeichnis ist nicht ausgewählt.';ro = 'Directorul de copii de rezerva nu este selectat.';tr = 'Yedekleme dizini seçilmedi.'; es_ES = 'Directorio de la copia de respaldo no se ha seleccionado.'");
		CommonClient.MessageToUser(MessageText,, "Object.BackupDirectory");
		AttributesFilled = False;
		
	ElsIf FindFiles(Object.BackupDirectory).Count() = 0 Then
		
		MessageText = NStr("ru = 'Указан несуществующий каталог.'; en = 'The provided directory does not exist.'; pl = 'Podano nieistniejący katalog.';de = 'Nicht existierendes Verzeichnis ist angegeben.';ro = 'Se specifică directorul neexistent.';tr = 'Mevcut olmayan dizin belirlendi.'; es_ES = 'Directorio no existente está especificado.'");
		CommonClient.MessageToUser(MessageText,, "Object.BackupDirectory");
		AttributesFilled = False;
		
	Else
		
		Try
			TestFile = New XMLWriter;
			TestFile.OpenFile(Object.BackupDirectory + "/test.test1C");
			TestFile.WriteXMLDeclaration();
			TestFile.Close();
		Except
			MessageText = NStr("ru = 'Нет доступа к каталогу с резервными копиями.'; en = 'Failed to access backup directory.'; pl = 'Nie można uzyskać dostępu do katalogu z kopiami zapasowymi.';de = 'Zugriff auf das Verzeichnis mit Sicherungen nicht möglich.';ro = 'Nu se poate accesa directorul cu copii de rezervă.';tr = 'Dizine yedeklerle erişilemiyor.'; es_ES = 'No se puede acceder el directorio con copias de respaldo.'");
			CommonClient.MessageToUser(MessageText,, "Object.BackupDirectory");
			AttributesFilled = False;
		EndTry;
		
		If AttributesFilled Then
			
			Try
				DeleteFiles(Object.BackupDirectory, "*.test1C");
			Except
				// The exception is not processed as files are not deleted at this step.
			EndTry;
			
		EndIf;
		
	EndIf;
	
	If PasswordRequired AND IsBlankString(IBAdministratorPassword) Then
		
		MessageText = NStr("ru = 'Не задан пароль администратора.'; en = 'Administrator password is not set.'; pl = 'Hasło administratora nie zostało określone.';de = 'Administrator-Kennwort ist nicht angegeben.';ro = 'Parola de administrator nu este specificată.';tr = 'Yönetici şifresi belirtilmemiş.'; es_ES = 'Contraseña del administrador no está especificada.'");
		CommonClient.MessageToUser(MessageText,, "IBAdministratorPassword");
		AttributesFilled = False;
		
	EndIf;

#EndIf
	
	Return AttributesFilled;
	
EndFunction

&AtServerNoContext
Procedure StopNotificationService(CurrentUser)
	// Stops notifications of backup.
	BackupSettings = IBBackupServer.BackupSettings();
	BackupSettings.RunAutomaticBackup = False;
	BackupSettings.BackupConfigured = True;
	BackupSettings.MinDateOfNextAutomaticBackup = '29990101';
	IBBackupServer.SetBackupParemeters(BackupSettings, CurrentUser);
EndProcedure

&AtServer
Procedure WriteSettings(CurrentUser)
	
	IsBaseConfigurationVersion = StandardSubsystemsServer.IsBaseConfigurationVersion();
	If IsBaseConfigurationVersion Then
		Object.ExecutionOption = "OnExit";
	EndIf;
	
	BackupParameters = IBBackupServer.BackupParameters();
	
	BackupParameters.Insert("IBAdministrator", IBAdministrator);
	BackupParameters.Insert("IBAdministratorPassword", ?(PasswordRequired, IBAdministratorPassword, ""));
	BackupParameters.LastNotificationDate = Date('29990101');
	BackupParameters.BackupsStorageDirectory = Object.BackupDirectory;
	BackupParameters.ExecutionOption = Object.ExecutionOption;
	BackupParameters.RunAutomaticBackup = Object.RunAutomaticBackup;
	BackupParameters.BackupConfigured = True;
	
	FillPropertyValues(BackupParameters.DeletionParameters, Object);
	
	If Object.ExecutionOption = "Schedule" Then
		
		ScheduleStructure = CommonClientServer.ScheduleToStructure(Schedule);
		BackupParameters.CopyingSchedule = ScheduleStructure;
		BackupParameters.MinDateOfNextAutomaticBackup = CurrentSessionDate();
		BackupParameters.LatestBackupDate = CurrentSessionDate();
		
	ElsIf Object.ExecutionOption = "OnExit" Then
		
		BackupParameters.MinDateOfNextAutomaticBackup = '29990101';
		
	EndIf;
	
	IBBackupServer.SetBackupParemeters(BackupParameters, CurrentUser);
	
EndProcedure

&AtClientAtServerNoContext
Procedure UpdateBackupDirectoryRestrictionType(Form)
	
	Form.Items.GroupStoreLastBackupsForPeriod.Enabled = (Form.Object.RestrictionType = "ByPeriod");
	Form.Items.BackupsCountInDirectoryGroup.Enabled = (Form.Object.RestrictionType = "ByCount");
	
EndProcedure

&AtClient
Procedure ChangeScheduleCompletion(ScheduleResult, AdditionalParameters) Export
	
	If ScheduleResult = Undefined Then
		Return;
	EndIf;
	
	Schedule = ScheduleResult;
	Items.EditSchedule.Title = String(Schedule);
	
EndProcedure

/////////////////////////////////////////////////////////
// Data presentation on the form.

&AtServer
Procedure SetVisibilityAvailability()
	
	Items.EditSchedule.Enabled = (Object.ExecutionOption = "Schedule");
	
	BackupAvailable = Object.RunAutomaticBackup;
	Items.ParametersGroup.Enabled = BackupAvailable;
	Items.SelectAutomaticBackupOption.Enabled = BackupAvailable;
	
EndProcedure

#EndRegion
