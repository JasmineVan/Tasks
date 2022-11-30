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
	
	If Not Common.IsWindowsClient() Then
		Raise NStr("ru = 'Резервное копирование и восстановление данных необходимо настроить средствами операционной системы или другими сторонними средствами.'; en = 'Set up data backup by the means of the operating system tools or third-party backup tools.'; pl = 'Tworzenie kopii zapasowych i odzyskiwanie danych muszą być konfigurowane za pomocą systemu operacyjnego lub innych narzędzi stron trzecich.';de = 'Die Sicherung und Wiederherstellung von Daten muss mit dem Betriebssystem oder anderen Tools von Drittanbietern konfiguriert werden.';ro = 'Copierea de rezervă și restabilirea datelor trebuie configurate prin mijloacele sistemului de operare sau alte mijloace terțe.';tr = 'Veri yedekleme ve geri yükleme, işletim sistemin araçları veya diğer üçüncü taraf araçları tarafından yapılandırılmalıdır.'; es_ES = 'Es necesario ajustar la creación de las copias de respaldo y la restauración de los datos con los recursos del sistema operativo o con otros recursos terceros.'");
	EndIf;
	
	If Common.IsWebClient()
		Or Common.IsMobileClient() Then
		Raise NStr("ru = 'Резервное копирование недоступно в веб-клиенте и мобильном клиенте.'; en = 'Web client and mobile client do not support data backup.'; pl = 'Tworzenie kopii zapasowych nie jest dostępne w kliencie sieciowym i kliencie mobilnym.';de = 'Backups sind im Webclient und im mobilen Client nicht verfügbar.';ro = 'Copierea de rezervă este inaccesibilă în web-client și în clientul mobil.';tr = 'Web istemcide ve mobil istemcide yedeklenme yapılamaz.'; es_ES = 'La copia de respaldo no está disponible en el cliente web y en el cliente móvil.'");
	EndIf;
	
	If Not Common.FileInfobase() Then
		Raise NStr("ru = 'В клиент-серверном варианте работы резервное копирование следует выполнять сторонними средствами (средствами СУБД).'; en = 'In the client/server mode, you must back up data by the means of the DBMS.'; pl = 'Utwórz kopię zapasową danych za pomocą narzędzi zewnętrznych (narzędzia SUBD) w trybie klient/serwer.';de = 'Sichern Sie Daten mit externen Tools (DBMS-Tools) im Client / Server-Modus.';ro = 'Faceți copii de siguranță ale datelor utilizând instrumente externe (instrumente DBMS) în modul client / server.';tr = 'İstemci / sunucu modunda harici araçları (DBMS araçları) kullanarak verileri yedekleyin.'; es_ES = 'Datos de la copia de respaldo utilizando herramientas externas (herramientas DBMS) en el modo de cliente/servidor.'");
	EndIf;
	
	BackupSettings = IBBackupServer.BackupSettings();
	IBAdministratorPassword = BackupSettings.IBAdministratorPassword;
	Object.BackupDirectory = BackupSettings.BackupsStorageDirectory;
	
	If InfobaseSessionsCount() > 1 Then
		
		Items.RecoveryStatusPages.CurrentPage = Items.ActiveUsersPage;
		
	EndIf;
	
	UserInformation = IBBackupServer.UserInformation();
	PasswordRequired = UserInformation.PasswordRequired;
	If PasswordRequired Then
		IBAdministrator = UserInformation.Name;
	Else
		Items.AuthorizationGroup.Visible = False;
		IBAdministratorPassword = "";
	EndIf;
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
#If WebClient Then
	Items.ComcntrGroupFileMode.Visible = False;
#EndIf
	
EndProcedure

&AtClient
Procedure BeforeClose(Cancel, Exit, WarningText, StandardProcessing)
	
	CurrentPage = Items.DataImportPages.CurrentPage;
	If CurrentPage <> Items.DataImportPages.ChildItems.InformationAndBackupCreationPage Then
		Return;
	EndIf;
		
	WarningText = NStr("ru = 'Прервать подготовку к восстановлению данных?'; en = 'Do you want to cancel data restore preparations?'; pl = 'Czy chcesz zaprzestać przygotowanie do przywrócenia danych?';de = 'Möchten Sie die Wiederherstellung von Daten einstellen?';ro = 'Doriți să întrerupeți pregătirea pentru restaurarea datelor?';tr = 'Verileri geri yüklemek için hazırlanmaktan vazgeçmek istiyor musunuz?'; es_ES = '¿Quiere parar la preparación para recuperar los datos?'");
	CommonClient.ShowArbitraryFormClosingConfirmation(ThisObject,
		Cancel, Exit, WarningText, "ForceCloseForm");
	
EndProcedure

&AtClient
Procedure OnClose(Exit)
	
	If Exit Then
		Return;
	EndIf;
	
	IBConnectionsClient.SetTerminateAllSessionsExceptCurrentFlag(False);
	IBConnectionsClient.SetUserTerminationInProgressFlag(False);
	IBConnectionsServerCall.AllowUserAuthorization();
	
	DetachIdleHandler("Timeout");
	DetachIdleHandler("CheckForSingleConnection");
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	If EventName = "UserSessionsCompletion" AND Parameter.SessionCount <= 1
		AND Items.DataImportPages.CurrentPage = Items.InformationAndBackupCreationPage Then
			StartBackup();
	EndIf;
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure PathToArchiveDirectoryStartChoice(Item, ChoiceData, StandardProcessing)
	
	SelectBackupFile();
	
EndProcedure

&AtClient
Procedure UsersListClick(Item)
	
	StandardSubsystemsClient.OpenActiveUserList(, ThisObject);
	
EndProcedure

&AtClient
Procedure LableUpdateComponentVersionURLProcessing(Item, FormattedStringURL, StandardProcessing)
	
	StandardProcessing = False;
	CommonClient.RegisterCOMConnector();
	
EndProcedure

#EndRegion

#Region FormCommandHandlers

&AtClient
Procedure FormCancel(Command)
	
	Close();
	
EndProcedure

&AtClient
Procedure Finish(Command)
	
	ClearMessages();
	
	If Not CheckAttributeFilling() Then
		Return;
	EndIf;
	
	Notification = New NotifyDescription("FinishAfterCheckInfobaseAccess", ThisObject);
	
	IBBackupClient.CheckAccessToInfobase(IBAdministratorPassword, Notification);
	
EndProcedure

&AtClient
Procedure FinishAfterCheckInfobaseAccess(ConnectionResult, Context) Export
	
	If ConnectionResult.AddInAttachmentError Then
		Items.RecoveryStatusPages.CurrentPage = Items.ConnectionErrorPage;
		ConnectionErrorFound = ConnectionResult.BriefErrorDescription;
	Else
		SetBackupParemeters();
		
		Pages = Items.DataImportPages;
		
		Pages.CurrentPage = Items.InformationAndBackupCreationPage; 
		Items.Close.Enabled = True;
		Items.Finish.Enabled = False;
		
		InfobaseSessionsCount = InfobaseSessionsCount();
		Items.ActiveUserCount.Title = InfobaseSessionsCount;
		
		IBConnectionsServerCall.SetConnectionLock(NStr("ru = 'Выполняется восстановление информационной базы.'; en = 'Restoring the infobase...'; pl = 'Wykonuje się odzyskiwanie bazy informacyjnej:';de = 'Die Wiederherstellung der Infobase läuft gerade.';ro = 'Recuperarea bazei de date este în curs de desfășurare.';tr = 'Veritabanı kurtarma işlemi devam ediyor.'; es_ES = 'Recuperación de la infobase está en progreso.'"), "Backup");
		
		If InfobaseSessionsCount = 1 Then
			IBConnectionsClient.SetTerminateAllSessionsExceptCurrentFlag(True);
			IBConnectionsClient.SetUserTerminationInProgressFlag(True);
			StartBackup();
		Else
			IBConnectionsClient.SetSessionTerminationHandlers(True);
			SetIdleIdleHandlerOfBackupStart();
			SetIdleHandlerOfBackupTimeout();
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure GoToEventLog(Command)
	OpenForm("DataProcessor.EventLog.Form.EventLog", , ThisObject);
EndProcedure

#EndRegion

#Region Private

// Attaches an idle time-out handler before forced start of data backup or restore.
// 
&AtClient
Procedure SetIdleHandlerOfBackupTimeout()
	
	AttachIdleHandler("Timeout", 300, True);
	
EndProcedure

// Attaches an idle deferred backup handler.
&AtClient
Procedure SetIdleIdleHandlerOfBackupStart() 
	
	AttachIdleHandler("CheckForSingleConnection", 5);
	
EndProcedure

// The function asks the user and returns a path to file or directory.
&AtClient
Procedure SelectBackupFile()
	
	OpenFileDialog = New FileDialog(FileDialogMode.Open);
	OpenFileDialog.Filter = NStr("ru = 'Резервная копия базы (*.zip, *.1CD)|*.zip;*.1cd'; en = 'Infobase backup (*.zip, *.1CD)|*.zip;*.1cd'; pl = 'Kopia zapasowa bazy danych (*.zip, *.1CD)|*.zip;*.1cd';de = 'Datenbanksicherung (*.zip, *.1CD)|*.zip;*.1cd';ro = 'Copia de rezervă a bazei (*.zip, *.1CD)|*.zip;*.1cd';tr = 'Veritabanın yedeği (*.zip, *.1CD)|*.zip;*.1cd'; es_ES = 'Copia de respaldo de la base (*.zip, *.1CD)|-*.zip;*.1cd'");
	OpenFileDialog.Title= NStr("ru = 'Выберите файл резервной копии'; en = 'Select a backup file'; pl = 'Wybierz plik kopii zapasowej';de = 'Wählen Sie eine Sicherungsdatei';ro = 'Selectați un fișier de rezervă';tr = 'Bir yedekleme dosyası seçin'; es_ES = 'Seleccionar un archivo de la copia de respaldo'");
	OpenFileDialog.CheckFileExist = True;
	
	If OpenFileDialog.Choose() Then
		
		Object.BackupImportFile = OpenFileDialog.FullFileName;
		
	EndIf;
	
EndProcedure

&AtClient
Function CheckAttributeFilling()
	
#If WebClient Or MobileClient Then
	MessageText = NStr("ru = 'Восстановление не доступно в веб-клиенте и мобильном клиенте.'; en = 'Web client and mobile client do not support data backup.'; pl = 'Odzyskiwanie nie jest dostępne w kliencie sieciowym i kliencie mobilnym.';de = 'Die Wiederherstellung ist im Webclient und im mobilen Client nicht verfügbar.';ro = 'Restaurarea este inaccesibilă în web-client și în clientul mobil.';tr = 'Web istemcide ve mobil istemcide geri yükleme yapılamaz.'; es_ES = 'No está disponible restablecer en el cliente web y en el cliente móvil.'");
	CommonClient.MessageToUser(MessageText);
	Return False;
#Else
	
	If PasswordRequired AND IsBlankString(IBAdministratorPassword) Then
		MessageText = NStr("ru = 'Не задан пароль администратора.'; en = 'Administrator password is not set.'; pl = 'Hasło administratora nie zostało określone.';de = 'Administrator-Kennwort ist nicht angegeben.';ro = 'Parola de administrator nu este specificată.';tr = 'Yönetici şifresi belirtilmemiş.'; es_ES = 'Contraseña del administrador no está especificada.'");
		CommonClient.MessageToUser(MessageText,, "IBAdministratorPassword");
		Return False;
	EndIf;
	
	Object.BackupImportFile = TrimAll(Object.BackupImportFile);
	FileName = TrimAll(Object.BackupImportFile);
	
	If IsBlankString(FileName) Then
		MessageText = NStr("ru = 'Не выбран файл с резервной копией.'; en = 'Backup file is not provided.'; pl = 'Plik kopii zapasowej nie jest wybrany.';de = 'Sicherungsdatei ist nicht ausgewählt.';ro = 'Fișierul de rezervă nu este selectat.';tr = 'Yedekleme dosyası seçilmedi.'; es_ES = 'Archivo de la copia de respaldo no está seleccionado.'");
		CommonClient.MessageToUser(MessageText,, "Object.BackupImportFile");
		Return False;
	EndIf;
	
	ArchiveFile = New File(FileName);
	If Upper(ArchiveFile.Extension) <> ".ZIP" AND Upper(ArchiveFile.Extension) <> ".1CD"  Then
		
		MessageText = NStr("ru = 'Выбранный файл не является архивом с резервной копией.'; en = 'The selected file is not a backup file.'; pl = 'Wybrany plik nie jest archiwum z kopią zapasową.';de = 'Die ausgewählte Datei ist kein Archiv mit Sicherung.';ro = 'Fișierul selectat nu este o arhivă cu copii de rezervă.';tr = 'Seçilen dosya yedek kopyası olan bir arşiv değildir.'; es_ES = 'El archivo seleccionado no es un archivo con copia de respaldo.'");
		CommonClient.MessageToUser(MessageText,, "Object.BackupImportFile");
		Return False;
		
	EndIf;
	
	If Upper(ArchiveFile.Extension) = ".1CD" Then
		
		If Upper(ArchiveFile.BaseName) <> "1CV8" Then
			MessageText = NStr("ru = 'Выбранный файл не является резервной копией (неправильное имя файла информационной базы).'; en = 'The selected file is not a valid backup file for this infobase. It contains another infobase name.'; pl = 'Wybrany plik nie jest kopią zapasową (niepoprawna nazwa pliku bazy informacyjnej).';de = 'Die ausgewählte Datei ist keine Sicherungskopie (falscher Name der Informationsbasisdatei).';ro = 'Fișierul selectat nu este o copie de rezervă (nume invalid al fișierului bazei de date).';tr = 'Seçilen dosya yedek kopyası değildir (veritabanı dosyasının geçersiz adı).'; es_ES = 'El archivo seleccionado no es una copia de respaldo (nombre inválido del archivo de la infobase).'");
			CommonClient.MessageToUser(MessageText,, "Object.BackupImportFile");
			Return False;
		EndIf;
		
	Else 
		
		ZIPFile = New ZipFileReader(FileName);
		If ZIPFile.Items.Count() <> 1 Then
			
			MessageText = NStr("ru = 'Выбранный файл не является архивом с резервной копией (содержит более одного файла).'; en = 'The selected file is not a valid backup file. It contains more than one file.'; pl = 'Wybrany plik nie jest archiwum z kopią zapasową (zawiera więcej niż jeden plik).';de = 'Die ausgewählte Datei ist kein Archiv mit Sicherung (enthält mehr als eine Datei).';ro = 'Fișierul selectat nu este o arhivă cu backup (conține mai mult de un fișier).';tr = 'Seçilen dosya yedek kopyası olan bir arşiv değildir (birden fazla dosya içerir).'; es_ES = 'El archivo seleccionado no es un archivo con copia de respaldo (contiene más de un archivo).'");
			CommonClient.MessageToUser(MessageText,, "Object.BackupImportFile");
			Return False;
			
		EndIf;
		
		FileInArchive = ZIPFile.Items[0];
		
		If Upper(FileInArchive.Extension) <> "1CD" Then
			
			MessageText = NStr("ru = 'Выбранный файл не является архивом с резервной копией (не содержит файл информационной базы).'; en = 'The selected file is not a valid backup file. It does not contain any infobase.'; pl = 'Wybrany plik nie jest archiwum z kopią zapasową (nie zawiera pliku bazy informacyjnej).';de = 'Die ausgewählte Datei ist kein Archiv mit Sicherung (enthält keine Infobase-Datei).';ro = 'Fișierul selectat nu este o arhivă cu copia de rezervă (nu conține fișierul baza de date).';tr = 'Seçilen dosya yedek kopyası olan bir arşiv değildir (veritabanı dosyasını içermez).'; es_ES = 'El archivo seleccionado no es un archivo con copia de respaldo (no contiene un archivo de la infobase).'");
			CommonClient.MessageToUser(MessageText,, "Object.BackupImportFile");
			Return False;
			
		EndIf;
		
		If Upper(FileInArchive.BaseName) <> "1CV8" Then
			
			MessageText = NStr("ru = 'Выбранный файл не является архивом с резервной копией (неправильное имя файла информационной базы).'; en = 'The selected file is not a valid backup file. The infobase name is not correct.'; pl = 'Wybrany plik nie jest archiwum z kopią zapasową (nieprawidłowa nazwa pliku bazy informacyjnej).';de = 'Die ausgewählte Datei ist kein Archiv mit Sicherung (ungültiger Name der Infobase-Datei).';ro = 'Fișierul selectat nu este o arhivă cu copia de rezervă (numele nevalid al fișierului bazei de date).';tr = 'Seçilen dosya yedek kopyası olan bir arşiv değildir (veritabanı dosyasının geçersiz adı).'; es_ES = 'El archivo seleccionado no es un archivo con copia de respaldo (nombre inválido del archivo de la infobase).'");
			CommonClient.MessageToUser(MessageText,, "Object.BackupImportFile");
			Return False;
			
		EndIf;
		
	EndIf;
	
	Return True;
	
#EndIf
	
EndFunction

////////////////////////////////////////////////////////////////////////////////
// Idle handler procedures.

&AtClient
Procedure Timeout()
	
	DetachIdleHandler("CheckForSingleConnection");
	CancelPreparation();
	
EndProcedure

&AtServer
Procedure CancelPreparation()
	
	Items.FailedLabel.Title = StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = '%1.
		|Подготовка к восстановлению данных из резервной копии отменена. Информационная база разблокирована.'; 
		|en = '%1.
		|Preparation for restoring data is canceled. Infobase is unlocked.'; 
		|pl = '%1
		|Przygotowanie do przywrócenia danych z kopii zapasowej zostanie anulowane. Baza informacyjna jest zablokowana.';
		|de = '%1.
		|Vorbereitung für die Datenwiederherstellung von der Sicherung wird abgebrochen. Infobase ist gesperrt.';
		|ro = '%1.
		|Pregătirea pentru restaurarea datelor din copia de rezervă este anulată. Baza de date este deblocată.';
		|tr = '%1. 
		| Yedekten veri yenilenmesi için hazırlık iptal edildi. Veritabanı kilitlendi.'; 
		|es_ES = '%1.
		|Preparación para recuperar los datos de la copia de respaldo se ha cancelado. Infobase está bloqueada.'"),
		IBConnections.ActiveSessionsMessage());
	Items.DataImportPages.CurrentPage = Items.BackupCreationErrorsPage;
	Items.Finish.Visible = False;
	Items.Close.Title = NStr("ru = 'Закрыть'; en = 'Close'; pl = 'Zamknij';de = 'Schließen';ro = 'Închideți';tr = 'Kapat'; es_ES = 'Cerrar'");
	Items.Close.DefaultButton = True;
	
	IBConnections.AllowUserAuthorization();
	
EndProcedure

&AtClient
Procedure CheckForSingleConnection()
	
	If InfobaseSessionsCount() = 1 Then
		StartBackup();
	EndIf;
	
EndProcedure

&AtClient
Procedure StartBackup() 
	
#If Not WebClient AND Not MobileClient Then
	
	MainScriptFileName = GenerateUpdateScriptFiles();
	EventLogClient.AddMessageForEventLog(
		IBBackupClient.EventLogEvent(), 
		"Information",
		NStr("ru = 'Выполняется восстановление данных информационной базы:'; en = 'Restoring the infobase:'; pl = 'Odtwarzane są informacje z bazy danych:';de = 'Die Daten der Informationsbasis werden wiederhergestellt:';ro = 'Are loc recuperarea datelor bazei de informații:';tr = 'Veritabanı kurtarma işlemi devam ediyor:'; es_ES = 'Recuperación de los datos de la infobase está en progreso:'") + " " + MainScriptFileName);
	
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
		Terminate();
	Else 
		ShowMessageBox(, Result.ErrorDescription);
	EndIf;
	
EndProcedure

//////////////////////////////////////////////////////////////////////////////////////////////////////////
// Procedures and functions of data recovery preparation.

#If Not WebClient AND Not MobileClient Then

&AtClient
Function GenerateUpdateScriptFiles() 
	
	CopyingParameters = IBBackupClient.ClientBackupParameters();
	ClientRunParameters = StandardSubsystemsClient.ClientRunParameters();
	CreateDirectory(CopyingParameters.TempFilesDirForUpdate);
	
	// Parameters structure is necessary to determine them on the client and transfer to the server.
	ParametersStructure = New Structure;
	ParametersStructure.Insert("ApplicationFileName"           , CopyingParameters.ApplicationFileName);
	ParametersStructure.Insert("EventLogEvent"   , CopyingParameters.EventLogEvent);
	ParametersStructure.Insert("COMConnectorName"           , ClientRunParameters.COMConnectorName);
	ParametersStructure.Insert("IsBaseConfigurationVersion", ClientRunParameters.IsBaseConfigurationVersion);
	ParametersStructure.Insert("FileInfobase"  , ClientRunParameters.FileInfobase);
	ParametersStructure.Insert("ScriptParameters"            , IBBackupClient.UpdateAdministratorAuthenticationParameters(IBAdministratorPassword));
	ParametersStructure.Insert("EnterpriseStartParameters" , CommonInternalClient.EnterpriseStartupParametersFromScript());
	
	TemplatesNames = "AddlBackupFile";
	TemplatesNames = TemplatesNames + ",RecoverySplash";
	
	TemplatesTexts = GetTemplateTexts(TemplatesNames, ParametersStructure, ApplicationParameters["StandardSubsystems.MessagesForEventLog"]);
	
	ScriptFile = New TextDocument;
	ScriptFile.Output = UseOutput.Enable;
	ScriptFile.SetText(TemplatesTexts[0]);
	
	ScriptFileName = CopyingParameters.TempFilesDirForUpdate + "main.js";
	ScriptFile.Write(ScriptFileName, IBBackupClient.IBBackupApplicationFilesEncoding());
	
	// Auxiliary file: helpers.js.
	ScriptFile = New TextDocument;
	ScriptFile.Output = UseOutput.Enable;
	ScriptFile.SetText(TemplatesTexts[1]);
	ScriptFile.Write(CopyingParameters.TempFilesDirForUpdate + "helpers.js", IBBackupClient.IBBackupApplicationFilesEncoding());
	
	MainScriptFileName = Undefined;
	// Auxiliary file: splash.png.
	PictureLib.ExternalOperationSplash.Write(CopyingParameters.TempFilesDirForUpdate + "splash.png");
	// Auxiliary file: splash.ico.
	PictureLib.ExternalOperationSplashIcon.Write(CopyingParameters.TempFilesDirForUpdate + "splash.ico");
	// Auxiliary  file: progress.gif.
	PictureLib.TimeConsumingOperation48.Write(CopyingParameters.TempFilesDirForUpdate + "progress.gif");
	// Main splash screen file: splash.hta.
	MainScriptFileName = CopyingParameters.TempFilesDirForUpdate + "splash.hta";
	ScriptFile = New TextDocument;
	ScriptFile.Output = UseOutput.Enable;
	ScriptFile.SetText(TemplatesTexts[2]);
	ScriptFile.Write(MainScriptFileName, IBBackupClient.IBBackupApplicationFilesEncoding());
	
	LogFile = New TextDocument;
	LogFile.Output = UseOutput.Enable;
	LogFile.SetText(StandardSubsystemsClient.SupportInformation());
	LogFile.Write(CopyingParameters.TempFilesDirForUpdate + "templog.txt", TextEncoding.System);
	
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
	ScriptTemplate = DataProcessors.IBBackup.GetTemplate("LoadIBFileTemplate");
	
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
	
	NameOfExecutableApplicationFile = BinDir() + ParametersStructure.ApplicationFileName;
	
	// Determining path to the infobase.
	FileModeFlag = Undefined;
	InfobasePath = IBConnectionsClientServer.InfobasePath(FileModeFlag, 0);
	
	InfobasePathParameter = ?(FileModeFlag, "/F", "/S") + InfobasePath; 
	InfobasePathString = ?(FileModeFlag, InfobasePath, "");
	
	Result = StrReplace(Result, "[NameOfExecutableApplicationFile]"     , PrepareText(NameOfExecutableApplicationFile));
	Result = StrReplace(Result, "[InfobasePathParameter]"   , PrepareText(InfobasePathParameter));
	Result = StrReplace(Result, "[InfobaseFilePathString]", PrepareText(CommonClientServer.AddLastPathSeparator(StrReplace(InfobasePathString, """", ""))));
	Result = StrReplace(Result, "[InfobaseConnectionString]", PrepareText(InfobaseConnectionString));
	Result = StrReplace(Result, "[NameOfUpdateAdministrator]"       , PrepareText(UserName()));
	Result = StrReplace(Result, "[EventLogEvent]"         , PrepareText(ParametersStructure.EventLogEvent));
	Result = StrReplace(Result, "[BackupFile]"                , PrepareText(Object.BackupImportFile));
	Result = StrReplace(Result, "[COMConnectorName]"                 , PrepareText(ParametersStructure.COMConnectorName));
	Result = StrReplace(Result, "[UseCOMConnector]"        , ?(ParametersStructure.IsBaseConfigurationVersion, "false", "true"));
	// TempFilesDir is used as automatic deletion of temporary directory is not allowed.
	Result = StrReplace(Result, "[TempFilesDirectory]"            , PrepareText(TempFilesDir()));
	Result = StrReplace(Result, "[EnterpriseStartParameters]"       , PrepareText(ParametersStructure.EnterpriseStartParameters));
	
	Return Result;
	
EndFunction

&AtServer
Function PrepareText(Val Text)
	
	Row = StrReplace(Text, "\", "\\");
	Row = StrReplace(Row, "'", "\'");
	
	Return StringFunctionsClientServer.SubstituteParametersToString("'%1'", Row);
	
EndFunction

&AtServer
Procedure SetBackupParemeters()
	
	BackupParameters = IBBackupServer.BackupSettings();
	
	BackupParameters.Insert("IBAdministrator", IBAdministrator);
	BackupParameters.Insert("IBAdministratorPassword", ?(PasswordRequired, IBAdministratorPassword, ""));
	
	IBBackupServer.SetBackupParemeters(BackupParameters);
	
EndProcedure

&AtServerNoContext
Function InfobaseSessionsCount()
	
	Return IBConnections.InfobaseSessionCount(False, False);
	
EndFunction

#EndRegion
