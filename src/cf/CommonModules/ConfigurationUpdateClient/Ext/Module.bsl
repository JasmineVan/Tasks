///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Public

// Returns whether configuration updates installation is supported by this computer.
// Update installation:
// - is available only in Windows;
// - is not available if connected via the web server (update requires batch run of Designer that 
//   directly connects to the infobase);
// - is available if Designer (full distribution package of 1C:Enterprise technological platform for Windows) is installed;
// - is available if administration rights are granted.
// - is not available in SaaS mode (update installation is centralized and executed via Service manager).
//
// Returns:
//    Structure - where:
//     * Supported - Boolean - True if configuration update installation is supported.
//     * ErrorDescription - String - error description if update installation is not supported.
//
Function UpdatesInstallationSupported() Export
	
	Result = New Structure;
	Result.Insert("Supported", False);
	Result.Insert("ErrorDescription", "");
	
	ClientRunParameters = StandardSubsystemsClient.ClientRunParameters();
	If ClientRunParameters.DataSeparationEnabled Then 
		Result.ErrorDescription = 
			NStr("ru = 'Установка обновлений для приложения в Интернете выполняется централизованно через Менеджер сервиса.'; en = 'Cloud applications support only centralized updates initiated from the service manager.'; pl = 'Zainstaluj aktualizacje dla aplikacji w Internecie są wykonywane centralnie za pośrednictwem Menedżera serwisu.';de = 'Updates für die Internetanwendung werden zentral über den Service Manager installiert.';ro = 'Instalarea actualizărilor pentru aplicație în Internet se execută în mod centralizat prin intermediul Managerului de serviciu.';tr = 'İnternet''teki uygulama güncellemeleri Servis Yöneticisi aracılığıyla merkezi olarak kurulur.'; es_ES = 'La instalación de actualizaciones para la aplicación en Internet se está realizando a través del Gestor de servicio.'");
		Return Result;
	EndIf;
	
	If Not ClientRunParameters.IsFullUser Then 
		Result.ErrorDescription = NStr("ru = 'Для установки обновления требуются права администрирования.'; en = 'You need the administrator rights to install the update.'; pl = 'Do zainstalowania aktualizacji wymagane są uprawnienia administracyjne.';de = 'Für die Installation des Updates sind Administratorrechte erforderlich.';ro = 'Pentru instalarea actualizărilor sunt necesare drepturile de administrare.';tr = 'Güncelleştirmeyi yüklemek için yönetici hakları gerekir.'; es_ES = 'Para instalar la actualización se requieren los derechos de administración.'");
		Return Result;
	EndIf;
	
#If WebClient Then
	Result.ErrorDescription =
		NStr("ru = 'Установка обновления не доступна в веб-клиенте.
		           |Необходимо установить полный дистрибутив технологической платформы 1С:Предприятие для Windows.'; 
		           |en = 'The update is not available in the web client.
		           |Please install 1C:Enterprise for Windows from the distribution package.'; 
		           |pl = 'Instalacja aktualizacji nie jest dostępna w kliencie www.
		           |Należy zainstalować pełną dystrybucję platformy technologicznej 1C:Enterprise dla systemu Windows.';
		           |de = 'Die Update-Installation ist im Web-Client nicht verfügbar.
		           |Es ist notwendig, die Vollversion der technologischen Plattform 1C:Enterprise für Windows zu installieren.';
		           |ro = 'Instalarea actualizării nu este disponibilă în web-client.
		           |Trebuie să instalați distributivul integral al platformei tehnologice 1С:Enterprise pentru Windows.';
		           |tr = 'Güncelleştirmeyi yükleme, web istemcisinde bulunmaz, Windows için 1C: Enterprise teknoloji platformunun tam dağıtımını yüklemeniz gerekir.
		           |'; 
		           |es_ES = 'La instalación de actualización no está disponible en el cliente web.
		           |Es necesario instalar distribución completa de la plataforma técnica de 1C:Enterprise para Windows. '");
	
#ElsIf MobileClient Then
	Result.ErrorDescription = NStr("ru = 'Установка обновления доступна только в ОС Windows.'; en = 'The update is available only on Windows.'; pl = 'Instalacja aktualizacji jest dostępna tylko w systemie Windows.';de = 'Die Update-Installation ist nur unter Windows verfügbar.';ro = 'Instalarea actualizării este disponibilă numai în SO Windows.';tr = 'Güncelleştirmeyi yükleme yalnızca Windows''ta mümkündür.'; es_ES = 'La instalación de actualización está disponible solo en Windows OS.'");
#Else
	
	If Not CommonClient.IsWindowsClient() Then 
		Result.ErrorDescription = NStr("ru = 'Установка обновления доступна только в ОС Windows.'; en = 'The update is available only on Windows.'; pl = 'Instalacja aktualizacji jest dostępna tylko w systemie Windows.';de = 'Die Update-Installation ist nur unter Windows verfügbar.';ro = 'Instalarea actualizării este disponibilă numai în SO Windows.';tr = 'Güncelleştirmeyi yükleme yalnızca Windows''ta mümkündür.'; es_ES = 'La instalación de actualización está disponible solo en Windows OS.'");
	EndIf;
	
	If CommonClient.ClientConnectedOverWebServer() Then 
		If Not IsBlankString(Result.ErrorDescription) Then
			Result.ErrorDescription = Result.ErrorDescription + Chars.LF + Chars.LF; 
		EndIf;
		Result.ErrorDescription = Result.ErrorDescription
			+ NStr("ru = 'Установка обновления не доступна при подключении через веб-сервер.
			             |Необходимо настроить прямое подключение к информационной базе.'; 
			             |en = 'The update is not available for connections over a web server.
			             |Please configure a direct connection to the infobase.'; 
			             |pl = 'Instalacja aktualizacji nie jest dostępna podczas łączenia się z serwerem www.
			             |Należy skonfigurować bezpośrednie połączenie z bazą informacyjną.';
			             |de = 'Die Update-Installation ist nicht verfügbar, wenn die Verbindung über einen Webserver hergestellt wird.
			             |Es ist notwendig, eine direkte Verbindung zur Informationsbasis herzustellen. ';
			             |ro = 'Instalarea actualizării nu este disponibilă la conectare prin web-server.
			             |Trebuie să configurați conectarea directă la baza de informații.';
			             |tr = 'Bir web sunucusu üzerinden bağlanırken güncelleme yapmak mümkün değildir.
			             |Bilgisayar veri tabanına doğrudan bir bağlantı yapılandırmanız gerekir.'; 
			             |es_ES = 'La instalación de actualización no está disponible al conectarse a través del servidor web.
			             |Es necesario ajustar conexión directa a la base de información.'");
	EndIf;
	
	If Not DesignerBatchModeSupported() Then 
		If Not IsBlankString(Result.ErrorDescription) Then
			Result.ErrorDescription = Result.ErrorDescription + Chars.LF + Chars.LF; 
		EndIf;
		Result.ErrorDescription = Result.ErrorDescription
			+ NStr("ru = 'Для установки обновления требуется конфигуратор.
			             |Необходимо установить полный дистрибутив технологической платформы 1С:Предприятие для Windows.'; 
			             |en = 'Designer is required to install the update.
			             |Please install 1C:Enterprise for Windows from the distribution package.'; 
			             |pl = 'W celu instalacji aktualizacji wymagany jest konfigurator.
			             |Konieczne jest zainstalowanie pełnej dystrybucji platformy technologicznej 1C:Enterprise dla systemu Windows.';
			             |de = 'Für die Installation des Updates ist ein Konfigurator erforderlich.
			             |Es ist notwendig, die Vollversion der technologischen Plattform 1C:Enterprise für Windows zu installieren.';
			             |ro = 'Pentru instalarea actualizării este necesar designerul.
			             |Trebuie să instalați distributivul integral al platformei tehnologice 1С:Enterprise pentru Windows.';
			             |tr = 'Güncelleştirmeyi yüklemek için yapılandırıcı gerekli, Windows için 1C: Enterprise teknoloji platformunun tam dağıtımını yüklemek gerekiyor.
			             |'; 
			             |es_ES = 'Para instalar la actualización se requiere configurador.
			             |Es necesario instalar distribución completa de la plataforma técnica de 1C:Enterprise para Windows.'");
	EndIf;
	
#EndIf
	
	Result.Supported = IsBlankString(Result.ErrorDescription);
	Return Result;
	
EndFunction

// Opens the update installation form with the specified parameters.
//
// Parameters:
//    UpdateInstallationParameters - Structure - Additional update installation parameters:
//     * Exit - Boolean - True if the application is closed after installing an update. 
//                                          The default value is False.
//     * ConfigurationUpdateRetrieved - Boolean - True if an update was retrieved from an online 
//                                          application. The default value is False (regular update installation mode).
//     * ExecuteUpdate     - Boolean - if True, skip update file selection and proceed to installing 
//                                          an update. The default value is False (offer a choice).
//
Procedure ShowUpdateSearchAndInstallation(UpdateIntallationParameters = Undefined) Export
	
	Result = UpdatesInstallationSupported();
	If Result.Supported Then
		OpenForm("DataProcessor.InstallUpdates.Form.Form", UpdateIntallationParameters);
	Else 
		ShowMessageBox(, Result.ErrorDescription);
	EndIf;
	
EndProcedure

// Displays a backup creation settings form.
//
// Parameters:
//    BackupParameters - Structure - backup form parameters.
//      * CreateBackup - Number - if 0, do not back up the infobase.
//                                          1 - create a temporary infobase backup.
//                                          2 - create an infobase backup.
//      * IBBackupDirectoryName - String - a backup directory.
//      * RestoreInfobase - Boolean - roll back in case of update errors.
//    NotifyDescription - NotifyDescription - a description of form closing notification.
//
Procedure ShowBackup(BackupParameters, NotifyDescription) Export
	
	OpenForm("DataProcessor.InstallUpdates.Form.BackupSettings", BackupParameters,,,,, NotifyDescription);
	
EndProcedure

#Region ForCallsFromOtherSubsystems

// OnlineUserSupport.GetApplicationUpdates

// Returns the backup settings title text for displaying in a form.
//
// Parameters:
//    Parameters - Structure - backup parameters.
//
// Returns:
//    String - backup creation hyperlink title.
//
Function BackupCreationTitle(Parameters) Export
	
	If Parameters.CreateDataBackup = 0 Then
		Return NStr("ru = 'Не создавать резервную копию ИБ'; en = 'Do not back up the infobase'; pl = 'Nie twórz kopii zapasowej bazy informacyjnej';de = 'Die Infobase nicht sichern';ro = 'Nu creați copii de rezervă pentru baza de date';tr = 'Veritabanını yedeklemeyin'; es_ES = 'No crear la copia de respaldo de la infobase'");
	ElsIf Parameters.CreateDataBackup = 1 Then
		If Parameters.RestoreInfobase Then 
			Return NStr("ru = 'Создавать временную резервную копию ИБ и выполнять откат при нештатной ситуации'; en = 'Create a temporary infobase backup and roll back if any issues occur'; pl = 'Tworzyć kopię zapasową BI i wykonywać powrót w przypadku wystąpienia nieoczekiwanej sytuacji';de = 'Erstellen Sie eine temporäre Sicherung der IB und führen Sie im Notfall einen Rollback durch';ro = 'Creare copia de rezervă temporară a BI și revenire în caz de situații excepționale';tr = 'Geçici IP yedeklemesi oluşturun ve acil durumda başlangıca dönün.'; es_ES = 'Crear una copia de respaldo temporal de la infobase y retroceder en el caso de errores'");
		Else 
			Return NStr("ru = 'Создавать временную резервную копию ИБ и не выполнять откат при нештатной ситуации'; en = 'Create a temporary infobase backup and do not roll back if any issues occur'; pl = 'Utwórz tymczasową kopię zapasową bazy informacyjnej oraz nie wycofaj zmiany w przypadku wystąpienia błędów';de = 'Erstellen Sie eine temporäre Sicherung der IB und führen Sie im Notfall kein Rollback durch';ro = 'Creare copia de rezervă temporară a BI fără revenire în caz de situații excepționale';tr = 'Geçici bir IB yedeği oluşturun ve acil durumlarda geri dönmeyin'; es_ES = 'Crear una copia de respaldo temporal de la infobase y no restablecer en el caso de errores'");
		EndIf;
	ElsIf Parameters.CreateDataBackup = 2 Then
		If Parameters.RestoreInfobase Then 
			Return NStr("ru = 'Создавать резервную копию ИБ и выполнять откат при нештатной ситуации'; en = 'Create an infobase backup and roll back if any issues occur'; pl = 'Utwórz kopię zapasową bazy informacyjnej oraz wycofaj zmiany w razie wystąpienia błędów';de = 'Erstellen Sie eine Sicherungskopie der IB und führen Sie im Notfall einen Rollback durch';ro = 'Creare copia de rezervă a BI și revenire în caz de situații excepționale';tr = 'IB''nin yedek bir kopyasını oluşturun ve acil bir durumda geri alma işlemini gerçekleştirin'; es_ES = 'Crear una copia de respaldo de la infobase y restablecer en el caso de errores'");
		Else 
			Return NStr("ru = 'Создавать резервную копию ИБ и не выполнять откат при нештатной ситуации'; en = 'Create an infobase backup and do not roll back if any issues occur'; pl = 'Utwórz kopię zapasową bazy informacyjnej oraz nie wycofaj zmiany w przypadku wystąpienia błędów';de = 'Erstellen Sie eine Sicherungskopie des IB und führen Sie in einer Notfallsituation kein Rollback durch';ro = 'Creare copia de rezervă a BI fără revenire în caz de situații excepționale';tr = 'IB''nin yedek bir kopyasını oluşturun ve acil bir durumda geri dönmeyin'; es_ES = 'Crear una copia de respaldo de la infobase y no restablecer en el caso de errores'");
		EndIf;
	Else
		Return "";
	EndIf;
	
EndFunction

// Checks whether update installation is possible. If possible, runs the update script or schedules 
// an update for a specified time.
//
// Parameters:
//    Form - ManagedForm - the form where a user initiates an update (it must be closed at the end).
//    Parameters - Structure - Update installation parameters:
//        * UpdateMode - Number - an update installation option. Available values:
//                                    0 - now, 1 - on exit, 2 - scheduled update.
//        * UpdateDateTime - Date - a scheduled update date.
//        * EmailReport - Boolean - shows whether update reports are sent by email.
//        * EmailAddress - String - an email address for sending update reports.
//        * SchedulerTaskCode - Number - a code of a scheduled update task.
//        * UpdateFileName - String - the update file name.
//        * CreateBackup - Number - shows whether a backup is created.
//        * IBBackupDirectoryName - String - a backup directory.
//        * RestoreInfobase - Boolean - shows whether an infobase is restored from a backup in case of update errors.
//        * Exit - Boolean - shows that an update is installed when the application is closed.
//        * UpdateFiles - Array - contains values of Structure type.
//        * Patches - Structure - with the following keys:
//           ** Install - Array - paths to the patch files in a temporary storage.
//                                    
//           ** Delete    - Array - UUIDs of patches to be deleted (String).
//        * PlatformDirectory - String - path to the platform to be updated if it is not specified 
//                                    that the update is running on the current session platform.
//    AdministrationParameters - Structure - See StandardSubsystemsServer.AdministrationParameters. 
//
Procedure InstallUpdate(Form, Parameters, AdministrationParameters) Export
	
#If Not WebClient AND NOT MobileClient Then
	
	If Not UpdateInstallationPossible(Parameters, AdministrationParameters) Then
		Return;
	EndIf;
	
	ConfigurationUpdateServerCall.SaveConfigurationUpdateSettings(Parameters);
	
	If Form <> Undefined Then
		Form.Close();
	EndIf;
	
	If Parameters.UpdateMode = 0 Then // Update now
		RunUpdateScript(Parameters, AdministrationParameters);
	ElsIf Parameters.UpdateMode = 1 Then // On exiting the application
		ParameterName = "StandardSubsystems.SuggestInfobaseUpdateOnExitSession";
		ApplicationParameters.Insert(ParameterName, True);
		ApplicationParameters.Insert("StandardSubsystems.UpdateFilesNames", UpdateFilesNames(Parameters));
	ElsIf Parameters.UpdateMode = 2 Then // Schedule an update
		ScheduleConfigurationUpdate(Parameters, AdministrationParameters);
	EndIf;
	
#EndIf
	
EndProcedure

// End OnlineUserSupport.GetApplicationUpdates

#EndRegion

#EndRegion

#Region Internal

Procedure ProcessUpdateResult(UpdateResult, ScriptDirectory) Export
	
	If IsBlankString(ScriptDirectory) Then
		EventLogClient.AddMessageForEventLog(EventLogEvent(),
			"Warning",
			NStr("ru = 'Обновление выполнено с очень старой версии программы. 
			           |Данные журнала обновления не были загружены, но сам журнал 
			           |можно найти в папке временных файлов %temp% - 
			           |в папке вида 1Cv8Update.<xxxxxxxx>(цифры).'; 
			           |en = 'The application is updated from a very old version.
			           |The update log data is not imported. See the log
			           |in the temporary files folder %temp%, in the
			           |1Cv8Update.<xxxxxxxx> subfolder (where xxxxxxxx are digits).'; 
			           |pl = 'Aktualizacja jest wykonana z bardzo starej wersji programu. 
			           |Dane dziennika aktualizacji nie były pobrane, ale sam dziennik 
			           |można znaleźć w folderze tymczasowych plików %temp% - 
			           |w folderze rodzaju 1Cv8Update.<xxxxxxxx>(cyfry).';
			           |de = 'Update erfolgt mit einer sehr alten Version des Programms. 
			           |Die Update-Protokolldaten wurden nicht heruntergeladen, das Protokoll 
			           |selbst befindet sich jedoch im Ordner für temporäre Dateien %temp% - 
			           |im Ordner des Typs 1Cv8Update. <Xxxxxxxx> (Zahlen).';
			           |ro = 'Actualizarea este executată de la o versiune foarte veche a programului. 
			           |Datele registrului logare nu au fost încărcate, însă registrul 
			           |poate foi găsit în folderul fișierelor temporare %temp% - 
			           |în folderul de tipul 1Cv8Update.<xxxxxxxx>(cifre).';
			           |tr = 'Güncelleme uygulamanın çok eski sürümünden yapıldı. 
			           |Güncelleme günlüğün verileri yüklenmedi, ancak günlük 
			           | geçici dosya klasöründe%temp% -
			           |1Cv8Update.<xxxxxxxx>(rakamlar)tür klasörde bulunabilir.'; 
			           |es_ES = 'El programa ha sido actualizado de la versión muy antigua. 
			           |Los datos del registro de la actualización no han sido cargados pero se puede encontrar 
			           |el registro mismo en la carpeta de los archivos temporales %temp% - 
			           | en la carpeta del tipo 1Cv8Update.<xxxxxxxx>(cifras).'"),
			, 
			True);
			
		UpdateResult = True; // Considering the update successful.
	Else 
		EventLogClient.AddMessageForEventLog(EventLogEvent(),
			"Information", 
			StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'Папка с журналом обновления расположена %1'; en = 'The update log is located in %1.'; pl = 'Folder z dziennikiem aktualizacji jest rozmieszczony %1';de = 'Der Ordner mit dem Aktualisierungsprotokoll befindet sich %1';ro = 'Folderul cu registrul de actualizare este amplasat %1';tr = 'Güncelleme günlüğü klasörün konumu%1'; es_ES = 'La carpeta con el registro se encuentra %1'"), ScriptDirectory),
			,
			True);
			
#If Not WebClient AND NOT MobileClient Then
		ReadDataToEventLog(UpdateResult, ScriptDirectory);
#EndIf
	EndIf;

EndProcedure

// Updates database configuration.
//
// Parameters:
//  StandardProcessing - Boolean - if False, do not show
//                                  the manual update instruction.
Procedure InstallConfigurationUpdate(Exit = False) Export
	
	FormParameters = New Structure("Exit, ConfigurationUpdateReceived",
		Exit, Exit);
	ShowUpdateSearchAndInstallation(FormParameters);
	
EndProcedure

// Writes an error marker file to the script directory.
//
Procedure WriteErrorLogFileAndExit(ScriptDirectory, DetailedErrorPresentation) Export
	
#If Not WebClient Then
	ErrorRegistrationFile = New TextWriter(ScriptDirectory + "error.txt");
	ErrorRegistrationFile.Close();
	
	LogFile = New TextWriter(ScriptDirectory + "templog.txt", TextEncoding.System);
	LogFile.Write(DetailedErrorPresentation);
	LogFile.Close();
	
	Terminate();
#EndIf
	
EndProcedure

// Opens a form with a list of installed patches.
//
// Parameters:
//  Patches - ValueList - a list of names of installed patches to be displayed.
//                                 If it is not specified, the method displays all patches.
//
Procedure ShowInstalledPatches(Patches = Undefined) Export
	
	FormParameters = New Structure("Patches", Patches);
	OpenForm("CommonForm.InstalledPatches", FormParameters);
	
EndProcedure

// Determines whether an extension is a patch.
// Parameters:
//  PatchName - String - an extension name.
//
Function IsPatch(PatchName) Export
	Return StrStartsWith(PatchName, "EF_");
EndFunction

////////////////////////////////////////////////////////////////////////////////
// Configuration subsystems event handlers.

// See CommonClientOverridable.OnStart. 
Procedure OnStart(Parameters) Export
	
	CheckForConfigurationUpdate();
	
EndProcedure

// See CommonClientOverridable.BeforeExit. 
Procedure BeforeExit(Cancel, Warnings) Export
	
	// Warning! When the "Configuration Update" subsystem sets its flag, it clears the list of all the 
	// previously added warnings.
	If ApplicationParameters["StandardSubsystems.SuggestInfobaseUpdateOnExitSession"] = True Then
		WarningParameters = StandardSubsystemsClient.WarningOnExit();
		WarningParameters.CheckBoxText  = NStr("ru = 'Установить обновление конфигурации'; en = 'Install configuration update'; pl = 'Zainstaluj aktualizację konfiguracji';de = 'Installieren Sie das Konfigurationsupdate';ro = 'Instalați actualizarea de configurare';tr = 'Yapılandırma güncellemesini yükle'; es_ES = 'Instalar la actualización de la configuración'");
		WarningParameters.WarningText  = NStr("ru = 'Запланирована установка обновления'; en = 'Update installation is scheduled'; pl = 'Zostało zaplanowane ustawienie aktualizacji';de = 'Geplante Update-Installation';ro = 'Este planificată instalarea actualizării';tr = 'Güncelleme planlandı'; es_ES = 'Se ha planificado la instalación de la actualización'");
		WarningParameters.Priority = 50;
		WarningParameters.OutputSingleWarning = True;
		
		ActionIfFlagSet = WarningParameters.ActionIfFlagSet;
		ActionIfFlagSet.Form = "DataProcessor.InstallUpdates.Form.Form";
		ActionIfFlagSet.FormParameters = New Structure("Exit, RunUpdate", True, True);
		
		Warnings.Add(WarningParameters);
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

Function UpdateInstallationPossible(Parameters, AdministrationParameters)
	
	Result = UpdatesInstallationSupported();
	If Not Result.Supported Then 
		ShowMessageBox(, Result.ErrorDescription);
		Return False;
	EndIf;
	
	IsFileInfobase = CommonClient.FileInfobase();
	
	If IsFileInfobase AND Parameters.CreateDataBackup = 2 Then
		File = New File(Parameters.IBBackupDirectoryName);
		If Not File.Exist() Or Not File.IsDirectory() Then
			ShowMessageBox(, NStr("ru = 'Укажите существующий каталог для сохранения резервной копии ИБ.'; en = 'Please specify an existing directory for storing the infobase backup.'; pl = 'Wskaż istniejący katalog dla zachowania kopii zapasowej BI.';de = 'Geben Sie ein vorhandenes Verzeichnis an, um die IB-Sicherung zu speichern.';ro = 'Indicați catalogul existent pentru salvarea copiei de rezervă a BI.';tr = 'IB yedeğini kaydetmek için varolan bir dizini belirtin.'; es_ES = 'Especificar un directorio existente para guardar la copia de respaldo de la infobase.'"));
			Return False;
		EndIf;
	EndIf;
	
	If Parameters.UpdateMode = 0 Then // Update now
		ParameterName = "StandardSubsystems.MessagesForEventLog";
		If IsFileInfobase AND ConfigurationUpdateServerCall.HasActiveConnections(ApplicationParameters[ParameterName]) Then
			ShowMessageBox(, NStr("ru = 'Невозможно продолжить обновление конфигурации, так как не завершены все соединения с информационной базой.'; en = 'Cannot proceed with configuration update as some infobase connections were not terminated.'; pl = 'Nie można kontynuować aktualizacji konfiguracji, ponieważ nie zostały zakończone wszystkie połączenia z bazą informacyjną.';de = 'Das Konfigurationsupdate kann nicht fortgesetzt werden, da Verbindungen mit der Infobase nicht beendet wurden.';ro = 'Nu puteți continua actualizarea configurației, deoarece nu sunt finalizate toate conexiunile cu baza de informații.';tr = 'Yapılandırma güncellemesi, veritabanı ile bağlantı sonlandırılmadığından devam edemez.'; es_ES = 'Esta actualización de configuraciones no puede procederse porque las conexiones con la infobase no se han finalizado.'"));
			Return False;
		EndIf;
	ElsIf Parameters.UpdateMode = 2 Then
		If Not UpdateDateCorrect(Parameters) Then
			Return False;
		EndIf;
		If Parameters.EmailReport
			AND Not CommonClientServer.EmailAddressMeetsRequirements(Parameters.EmailAddress) Then
			ShowMessageBox(, NStr("ru = 'Укажите допустимый адрес электронной почты.'; en = 'Please specify a valid email address.'; pl = 'Wskaż dopuszczalny adres poczty elektronicznej.';de = 'Geben Sie eine zulässige E-Mail-Adresse an.';ro = 'Indicați adresa de e-mail admisibilă.';tr = 'İzin verilen bir e-posta adresi belirtin.'; es_ES = 'Especificar una dirección de correo electrónico admisible.'"));
			Return False;
		EndIf;
		If Not TaskSchedulerSupported() Then
			ShowMessageBox(, NStr("ru = 'Планировщик заданий поддерживается только начиная с операционной системы версии 6.0 Vista.'; en = 'Job scheduler is supported only since Windows Vista 6.0.'; pl = 'Program planowania zadań jest obsługiwany tylko zaczynając od systemu operacyjnego wersji 6.0 Vista.';de = 'Der Job Scheduler wird erst ab der Betriebssystem-Version 6.0 von Vista unterstützt.';ro = 'Planificatorul de sarcini este susținut numai începând cu sistemul de operare de versiunea 6.0 Vista.';tr = 'Görev planlayıcısı işletim sistemin yalnızca 6.0 Vista sürümünden itibaren desteklenir.'; es_ES = 'El planificador de las tareas se admite solo empezando con el sistema operativo de la versión 6.0 Vista.'"));
			Return False;
		EndIf;
	EndIf;
	
	Return True;
	
EndFunction

Function UpdateDateCorrect(Parameters)
	
	CurrentDate = CommonClient.SessionDate();
	If Parameters.UpdateDateTime < CurrentDate Then
		MessageText = NStr("ru = 'Обновление конфигурации может быть запланировано только на будущую дату и время.'; en = 'A configuration update can be scheduled only for a future date and time.'; pl = 'Aktualizacja konfiguracji może być zaplanowana tylko na przyszłą datę i czas.';de = 'Das Konfigurationsupdate kann nur für ein zukünftiges Datum und eine geplante Uhrzeit geplant werden.';ro = 'Actualizarea configurației poate fi planificată numai pentru data și ora viitoare.';tr = 'Yapılandırma güncellemesi sadece ileriki bir tarih ve saat için planlanabilir.'; es_ES = 'Actualización de configuraciones puede programarse solo para una fecha y una hora en el futuro.'");
	ElsIf Parameters.UpdateDateTime > AddMonth(CurrentDate, 1) Then
		MessageText = NStr("ru = 'Обновление конфигурации может быть запланировано не позднее, чем через месяц относительно текущей даты.'; en = 'A configuration update cannot be scheduled to a date later than one month from the current date.'; pl = 'Aktualizacja konfiguracji może być zaplanowana nie później niż po miesiącu od bieżącej daty.';de = 'Die Aktualisierung der Konfiguration kann nicht später als in einem Monat ab dem aktuellen Datum geplant werden.';ro = 'Actualizarea configurației poate fi planificată nu mai târziu decât peste o lună în raport cu data curentă.';tr = 'Yapılandırma güncellemesi, geçerli tarihten itibaren bir ay içinde geçmeyecek şekilde programlanabilir.'; es_ES = 'Actualización de configuraciones puede programarse no más tarde que en un mes a partir de la fecha actual.'");
	EndIf;
	
	DateCorrect = IsBlankString(MessageText);
	If Not DateCorrect Then
		ShowMessageBox(, MessageText);
	EndIf;
	
	Return DateCorrect;
	
EndFunction

Procedure InsertScriptParameter(Val ParameterName, Val ParameterValue, DoFormat, ParametersArea)
	
	If DoFormat = True Then
		ParameterValue = DoFormat(ParameterValue);
	ElsIf DoFormat = False Then
		ParameterValue = ?(ParameterValue, "true", "false");
	EndIf;
	ParametersArea = StrReplace(ParametersArea, "[" + ParameterName + "]", ParameterValue);
	
EndProcedure

Function UpdateFilesNames(Parameters)
	
	ParameterName = "StandardSubsystems.UpdateFilesNames";
	If ApplicationParameters.Get(ParameterName) <> Undefined Then
		Return ApplicationParameters[ParameterName];
	EndIf;
	
	If Parameters.Property("UpdateFileRequired") AND Not Parameters.UpdateFileRequired Then
		UpdateFilesNames = "";
	Else
		If IsBlankString(Parameters.NameOfUpdateFile) Then
			FileNames = New Array;
			For Each UpdateFile In Parameters.UpdateFiles Do
				UpdateFilePrefix = ?(UpdateFile.RunUpdateHandlers, "+", "");
				FileNames.Add(DoFormat(UpdateFilePrefix + UpdateFile.UpdateFileFullName));
			EndDo;
			UpdateFilesNames = StrConcat(FileNames, ",");
		Else
			UpdateFilesNames = DoFormat(Parameters.NameOfUpdateFile);
		EndIf;
	EndIf;
	
	Return "[" + UpdateFilesNames + "]";
	
EndFunction

Function DoFormat(Val Text)
	Text = StrReplace(Text, "\", "\\");
	Text = StrReplace(Text, """", "\""");
	Text = StrReplace(Text, "'", "\'");
	Return "'" + Text + "'";
EndFunction

Function GetUpdateAdministratorAuthenticationParameters(AdministrationParameters)
	
	Result = New Structure("StringForConnection, InfobaseConnectionString");
	
	ClusterPort = AdministrationParameters.ClusterPort;
	CurrentConnections = IBConnectionsServerCall.ConnectionsInformation(True,
		ApplicationParameters["StandardSubsystems.MessagesForEventLog"], ClusterPort);
		
	Result.InfobaseConnectionString = CurrentConnections.InfobaseConnectionString;
	Result.StringForConnection = "Usr=""{0}"";Pwd=""{1}""";
	
	Return Result;
	
EndFunction

Function ScheduleServiceTaskName(Val TaskCode)
	
	Return StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = 'Обновление конфигурации (%1)'; en = 'Update configuration (%1)'; pl = 'Aktualizacja konfiguracji (%1)';de = 'Konfigurationsupdate (%1)';ro = 'Actualizarea configurației (%1)';tr = 'Yapılandırmayı güncelle (%1)'; es_ES = 'Actualizar la configuración (%1)'"), Format(TaskCode, "NG=0"));
	
EndFunction

Function StringUnicode(String)
	
	Result = "";
	
	For CharNumber = 1 To StrLen(String) Do
		
		Char = Format(CharCode(Mid(String, CharNumber, 1)), "NG=0");
		Char = StringFunctionsClientServer.SupplementString(Char, 4);
		Result = Result + Char;
		
	EndDo;
	
	Return Result;
	
EndFunction

// Returns the event name for writing to the event log.
Function EventLogEvent() Export
	Return NStr("ru = 'Обновление конфигурации'; en = 'Configuration update'; pl = 'Aktualizacja konfiguracji';de = 'Konfigurations-Update';ro = 'Actualizarea configurației';tr = 'Yapılandırma güncellemesi'; es_ES = 'Actualización de la configuración'", CommonClient.DefaultLanguageCode());
EndFunction

// Checks whether a configuration update is available at startup.
//
Procedure CheckForConfigurationUpdate()
	
	If Not CommonClient.IsWindowsClient() Then
		Return;
	EndIf;
	
#If NOT WebClient AND NOT MobileClient Then
	ClientRunParameters = StandardSubsystemsClient.ClientParametersOnStart();
	If ClientRunParameters.DataSeparationEnabled Or Not ClientRunParameters.SeparatedDataUsageAvailable Then
		Return;
	EndIf;
	
	If ClientRunParameters.Property("ShowInvalidHandlersMessage") Then
		Return; // Update results form will be shown later.
	EndIf;
	
	UpdateSettings = ClientRunParameters.UpdateSettings;
	UpdateAvailability = UpdateSettings.CheckPreviousInfobaseUpdates;
	
	If UpdateAvailability Then
		// The previous update must be completed.
		OpenForm("DataProcessor.ApplicationUpdateResult.Form.DeferredIBUpdateProgressIndicator");
		Return;
	EndIf;
	
	If UpdateSettings.ConfigurationChanged Then
		ShowUserNotification(NStr("ru = 'Обновление конфигурации'; en = 'Configuration update'; pl = 'Aktualizacja konfiguracji';de = 'Konfigurations-Update';ro = 'Actualizarea configurației';tr = 'Yapılandırma güncellemesi'; es_ES = 'Actualización de la configuración'"),
			"e1cib/app/DataProcessor.InstallUpdates",
			NStr("ru = 'Конфигурация отличается от основной конфигурации информационной базы.'; en = 'The configuration is different from the main infobase configuration.'; pl = 'Konfiguracja różni się od głównej konfiguracji bazy informacyjnej.';de = 'Die Konfiguration unterscheidet sich von der Grundkonfiguration der Infobase.';ro = 'Configurația este diferită de configurația principală a bazei de informații.';tr = 'Yapılandırma, veritabanın temel yapılandırmasından farklıdır.'; es_ES = 'La configuración es diferente de la configuración básica de la infobase.'"), 
			PictureLib.Information32);
	EndIf;
	
#EndIf

EndProcedure

Procedure WriteEventsToEventLog() Export
	
	EventsForEventLog = ApplicationParameters["StandardSubsystems.MessagesForEventLog"];
	
	If TypeOf(EventsForEventLog) <> Type("ValueList") Then
		Return;
	EndIf;
	
	If EventsForEventLog.Count() = 0 Then
		Return;
	EndIf;
	
	EventLogServerCall.WriteEventsToEventLog(EventsForEventLog);
	
EndProcedure

Function TaskSchedulerSupported()
	
	// Task Scheduler is supported for versions 6.0 (Windows Vista) and later.
	
	SystemInfo = New SystemInfo();
	
	DotPosition = StrFind(SystemInfo.OSVersion, ".");
	If DotPosition < 2 Then 
		Return False;
	EndIf;
	
	VersionNumber = Mid(SystemInfo.OSVersion, DotPosition - 2, 2);
	
	TypeDescriptionNumber = New TypeDescription("Number");
	VersionLaterThanVista = TypeDescriptionNumber.AdjustValue(VersionNumber) >= 6;
	
	Return VersionLaterThanVista;
	
EndFunction

#If Not WebClient AND NOT MobileClient Then

Procedure ReadDataToEventLog(UpdateResult, ScriptDirectory)
	
	UpdateResult = Undefined;
	ErrorOccurredDuringUpdate = False;
	
	FilesArray = FindFiles(ScriptDirectory, "log*.txt");
	
	If FilesArray.Count() = 0 Then
		Return;
	EndIf;
	
	LogFile = FilesArray[0];
	
	TextDocument = New TextDocument;
	TextDocument.Read(LogFile.FullName);
	
	For LineNumber = 1 To TextDocument.LineCount() Do
		
		CurrentLine = TextDocument.GetLine(LineNumber);
		If IsBlankString(CurrentLine) Then
			Continue;
		EndIf;
		
		LevelPresentation = "Information";
		If Mid(CurrentLine, 3, 1) = "." AND Mid(CurrentLine, 6, 1) = "." Then // A string with a date.
			StringArray = StrSplit(CurrentLine, " ", False);
			DateArray = StrSplit(StringArray[0], ".");
			TimeArray = StrSplit(StringArray[1], ":");
			EventDate = Date(DateArray[2], DateArray[1], DateArray[0], TimeArray[0], TimeArray[1], TimeArray[2]);
			If StringArray[2] = "{ERR}" Then
				LevelPresentation = "Error";
				ErrorOccurredDuringUpdate = True;
			EndIf;
			Comment = TrimAll(Mid(CurrentLine, StrFind(CurrentLine, "}") + 2));
			
			If Comment = NStr("ru = 'Обновление выполнено'; en = 'Update completed'; pl = 'Aktualizacja została zakończona';de = 'Update abgeschlossen';ro = 'Actualizarea este executată';tr = 'Güncelleme yapıldı'; es_ES = 'Actualización se ha realizado'", CommonClientServer.DefaultLanguageCode()) Then // CAC:1297 do not localize (part of log)
				UpdateResult = True;
				Continue;
			ElsIf Comment = NStr("ru = 'Обновление не выполнено'; en = 'Update failed'; pl = 'Aktualizacja nie jest wykonana';de = 'Update nicht abgeschlossen';ro = 'Actualizarea nu este executată';tr = 'Güncelleme yapılmadı'; es_ES = 'Actualización no se ha realizado'", CommonClientServer.DefaultLanguageCode()) Then // CAC:1297 do not localize (part of log)
				UpdateResult = False;
				Continue;
			EndIf;
			
			For NextLineNumber = LineNumber + 1 To TextDocument.LineCount() Do
				CurrentLine = TextDocument.GetLine(NextLineNumber);
				If Mid(CurrentLine, 3, 1) = "." AND Mid(CurrentLine, 6, 1) = "." Then
					// The next line is a new event line.
					LineNumber = NextLineNumber - 1;
					Break;
				EndIf;
				
				Comment = Comment + Chars.LF + CurrentLine;
				
			EndDo;
			
			EventLogClient.AddMessageForEventLog(
				EventLogEvent(), 
				LevelPresentation, 
				Comment, 
				EventDate);
			
		EndIf;
		
	EndDo;
	
	// If the update was performed from SSL version earlier than 2.3.1.6, the following log entries might be absent:
	// - "Update completed"
	// - "Update failed"
	// Therefore, let us rely on whether errors occurred during the update.
	If UpdateResult = Undefined Then 
		UpdateResult = Not ErrorOccurredDuringUpdate;
	EndIf;
	
	WriteEventsToEventLog();

EndProcedure

Function UpdateProgramFilesEncoding()
	
	// wscript.exe can process only UTF-16 LE-encoded files.
	Return TextEncoding.UTF16;
	
EndFunction

Function PatchFilesNames(Parameters, TempFilesDirectory)
	
	ParameterName = "StandardSubsystems.PatchFilesNames";
	If ApplicationParameters.Get(ParameterName) <> Undefined Then
		Return ApplicationParameters[ParameterName];
	EndIf;
	
	FileNames = New Array;
	For Each PatchFileName In Parameters.PatchesFiles Do
		If StrEndsWith(PatchFileName, ".cfe") Then
			ArchiveName = TempFilesDirectory + StrReplace(String(New UUID),"-", "") + ".zip";
			WriteArchive = New ZipFileWriter(ArchiveName);
			WriteArchive.Add(PatchFileName);
			WriteArchive.Write();
			
			FileNames.Add(DoFormat(ArchiveName));
		Else
			FileNames.Add(DoFormat(PatchFileName));
		EndIf;
	EndDo;
	PatchFilesNames = StrConcat(FileNames, ",");
	
	Return "[" + PatchFilesNames + "]";
	
EndFunction

Function PatchesInformation(Parameters, TempFilesDir)
	
	ParameterName = "StandardSubsystems.PatchesInformation";
	If ApplicationParameters.Get(ParameterName) <> Undefined Then
		Return ApplicationParameters[ParameterName];
	EndIf;
	
	PatchesToInstall = "['']";
	PatchesToDelete = "['']";
	If Parameters.Property("PatchesFiles") Then
		PatchesToInstall = PatchFilesNames(Parameters, TempFilesDir);
	ElsIf Parameters.Property("Patches") Then
		If Parameters.Patches.Property("Set")
			AND Parameters.Patches.Set.Count() > 0 Then
			FileNames = New Array;
			For Each NewPatch In Parameters.Patches.Set Do
				ArchiveName = TempFilesDir + StrReplace(String(New UUID),"-", "") + ".zip";
				Data = GetFromTempStorage(NewPatch);
				Data.Write(ArchiveName);
				FileNames.Add(DoFormat(ArchiveName));
			EndDo;
			PatchesToInstall = StrConcat(FileNames, ",");
			PatchesToInstall = "[" + PatchesToInstall + "]";
		EndIf;
		
		If Parameters.Patches.Property("Delete")
			AND Parameters.Patches.Delete.Count() > 0 Then
			PatchesToDelete = StrConcat(Parameters.Patches.Delete, ",");
			PatchesToDelete = "[" + PatchesToDelete + "]";
		EndIf;
	EndIf;
	
	PatchesInformation = New Structure;
	PatchesInformation.Insert("Set", PatchesToInstall);
	PatchesInformation.Insert("Delete", PatchesToDelete);
	
	Return PatchesInformation;
	
EndFunction

Function GenerateUpdateScriptFiles(Val InteractiveMode, Parameters, AdministrationParameters)
	
	ClientRunParameters = StandardSubsystemsClient.ClientRunParameters();
	IsFileInfobase = ClientRunParameters.FileInfobase;
	
	PlatformDirectory = Undefined;
	Parameters.Property("PlatformDirectory", PlatformDirectory);
	ApplicationDirectory = ?(ValueIsFilled(PlatformDirectory), PlatformDirectory, BinDir());
	
	
	DesignerExecutableFileName = ApplicationDirectory + StandardSubsystemsClient.ApplicationExecutableFileName(True);
	ClientExecutableFileName = ApplicationDirectory + StandardSubsystemsClient.ApplicationExecutableFileName();
	COMConnectorPath = BinDir() + "comcntr.dll";
	
	UseCOMConnector = Not (ClientRunParameters.IsBaseConfigurationVersion Or ClientRunParameters.IsTrainingPlatform);
	
	ScriptParameters = GetUpdateAdministratorAuthenticationParameters(AdministrationParameters);
	InfobaseConnectionString = ScriptParameters.InfobaseConnectionString + ScriptParameters.StringForConnection;
	If StrEndsWith(InfobaseConnectionString, ";") Then
		InfobaseConnectionString = Left(InfobaseConnectionString, StrLen(InfobaseConnectionString) - 1);
	EndIf;
	
	// Determining path to the infobase.
	InfobasePath = IBConnectionsClientServer.InfobasePath(, AdministrationParameters.ClusterPort);
	InfobasePathParameter = ?(IsFileInfobase, "/F", "/S") + InfobasePath;
	InfobasePathString = ?(IsFileInfobase, InfobasePath, "");
	InfobasePathString = CommonClientServer.AddLastPathSeparator(StrReplace(InfobasePathString, """", "")) + "1Cv8.1CD";
	
	EmailAddress = ?(Parameters.UpdateMode = 2 AND Parameters.EmailReport, Parameters.EmailAddress, "");
	
	
	// Calling TempFilesDir instead of GetTempFileName as the directory cannot be deleted automatically 
	// on client application exit.
	// It stores the executable files, execution log, and a backup (it the settings include backup creation).
	TempFilesDirForUpdate = TempFilesDir() + "1Cv8Update." + Format(CommonClient.SessionDate(), "DF=yymmddHHmmss") + "\";
	
	If Parameters.CreateDataBackup = 1 Then 
		BackupDirectory = TempFilesDirForUpdate;
	ElsIf Parameters.CreateDataBackup = 2 Then 
		BackupDirectory = CommonClientServer.AddLastPathSeparator(Parameters.IBBackupDirectoryName);
	Else 
		BackupDirectory = "";
	EndIf;
	
	CreateDataBackup = IsFileInfobase AND (Parameters.CreateDataBackup = 1 Or Parameters.CreateDataBackup = 2);
	
	ExecuteDeferredHandlers = False;
	IsDeferredUpdate = (Parameters.UpdateMode = 2);
	TemplatesTexts = ConfigurationUpdateServerCall.TemplatesTexts(InteractiveMode,
		ApplicationParameters["StandardSubsystems.MessagesForEventLog"], ExecuteDeferredHandlers, IsDeferredUpdate);
	Username = AdministrationParameters.InfobaseAdministratorName;
	
	If IsDeferredUpdate Then 
		RandomNumberGenerator = New RandomNumberGenerator;
		TaskCode = Format(RandomNumberGenerator.RandomNumber(1000, 9999), "NG=0");
		TaskName = ScheduleServiceTaskName(TaskCode);
	EndIf;
	
	EnterpriseStartupParametersFromScript = CommonInternalClient.EnterpriseStartupParametersFromScript();
	
	ParametersArea = TemplatesTexts.ParametersArea;
	InsertScriptParameter("DesignerExecutableFileName" , DesignerExecutableFileName          , True, ParametersArea);
	InsertScriptParameter("ClientExecutableFileName"       , ClientExecutableFileName                , True, ParametersArea);
	InsertScriptParameter("COMConnectorPath"               , COMConnectorPath                        , True, ParametersArea);
	InsertScriptParameter("InfobasePathParameter"   , InfobasePathParameter            , True, ParametersArea);
	InsertScriptParameter("InfobaseFilePathString", InfobasePathString              , True, ParametersArea);
	InsertScriptParameter("InfobaseConnectionString", InfobaseConnectionString         , True, ParametersArea);
	InsertScriptParameter("EventLogEvent"         , EventLogEvent()                , True, ParametersArea);
	InsertScriptParameter("EmailAddress"             , EmailAddress                      , True, ParametersArea);
	InsertScriptParameter("NameOfUpdateAdministrator"       , Username                            , True, ParametersArea);
	InsertScriptParameter("COMConnectorName"                 , ClientRunParameters.COMConnectorName   , True, ParametersArea);
	InsertScriptParameter("BackupDirectory"             , BackupDirectory                      , True, ParametersArea);
	InsertScriptParameter("CreateDataBackup"           , CreateDataBackup                    , False  , ParametersArea);
	InsertScriptParameter("RestoreInfobase" , Parameters.RestoreInfobase, False  , ParametersArea);
	InsertScriptParameter("BlockIBConnections"           , Not IsFileInfobase                         , False  , ParametersArea);
	InsertScriptParameter("UseCOMConnector"        , UseCOMConnector                 , False  , ParametersArea);
	InsertScriptParameter("StartSessionAfterUpdate"       , Not Parameters.Exit       , False  , ParametersArea);
	InsertScriptParameter("CompressIBTables"           , IsFileInfobase                            , False  , ParametersArea);
	InsertScriptParameter("ExecuteDeferredHandlers"    , ExecuteDeferredHandlers             , False  , ParametersArea);
	InsertScriptParameter("TaskSchedulerTaskName"        , TaskName                                  , True, ParametersArea);
	InsertScriptParameter("EnterpriseStartParameters"       , EnterpriseStartupParametersFromScript       , True, ParametersArea);
	
	CreateDirectory(TempFilesDirForUpdate);
	PatchesInformation = PatchesInformation(Parameters, TempFilesDirForUpdate);
	ParametersArea = StrReplace(ParametersArea, "[UpdateFilesNames]", UpdateFilesNames(Parameters));
	ParametersArea = StrReplace(ParametersArea, "[PatchFilesNames]", PatchesInformation.Set);
	ParametersArea = StrReplace(ParametersArea, "[DeletedChangesNames]", PatchesInformation.Delete);
	
	TemplatesTexts.ConfigurationUpdateFileTemplate = ParametersArea + TemplatesTexts.ConfigurationUpdateFileTemplate;
	TemplatesTexts.Delete("ParametersArea");
	
	//
	ScriptFile = New TextDocument;
	ScriptFile.Output = UseOutput.Enable;
	ScriptFile.SetText(TemplatesTexts.ConfigurationUpdateFileTemplate);
	
	ScriptFileName = TempFilesDirForUpdate + "main.js";
	ScriptFile.Write(ScriptFileName, UpdateProgramFilesEncoding());
	
	// Auxiliary file: helpers.js.
	ScriptFile = New TextDocument;
	ScriptFile.Output = UseOutput.Enable;
	ScriptFile.SetText(TemplatesTexts.AdditionalConfigurationUpdateFile);
	ScriptFile.Write(TempFilesDirForUpdate + "helpers.js", UpdateProgramFilesEncoding());
	
	If InteractiveMode Then
		// Auxiliary file: splash.png.
		PictureLib.ExternalOperationSplash.Write(TempFilesDirForUpdate + "splash.png");
		// Auxiliary file: splash.ico.
		PictureLib.ExternalOperationSplashIcon.Write(TempFilesDirForUpdate + "splash.ico");
		// Auxiliary  file: progress.gif.
		PictureLib.TimeConsumingOperation48.Write(TempFilesDirForUpdate + "progress.gif");
		// Main splash screen file: splash.hta.
		MainScriptFileName = TempFilesDirForUpdate + "splash.hta";
		ScriptFile = New TextDocument;
		ScriptFile.Output = UseOutput.Enable;
		ScriptFile.SetText(TemplatesTexts.ConfigurationUpdateSplash);
		ScriptFile.Write(MainScriptFileName, UpdateProgramFilesEncoding());
	Else
		MainScriptFileName = TempFilesDirForUpdate + "updater.js";
		ScriptFile = New TextDocument;
		ScriptFile.Output = UseOutput.Enable;
		ScriptFile.SetText(TemplatesTexts.NonInteractiveConfigurationUpdate);
		ScriptFile.Write(MainScriptFileName, UpdateProgramFilesEncoding());
	EndIf;
	
	If IsDeferredUpdate Then 
		
		StartDate = Format(Parameters.UpdateDateTime, "DF=yyyy-MM-ddTHH:mm:ss");
		
		ScriptPath = StandardSubsystemsClient.SystemApplicationFolder() + "wscript.exe";
		ScriptParameters = StringFunctionsClientServer.SubstituteParametersToString("//nologo ""%1"" /p1:""%2"" /p2:""%3""",
			MainScriptFileName,
			StringUnicode(AdministrationParameters.InfobaseAdministratorPassword),
			StringUnicode(AdministrationParameters.ClusterAdministratorPassword));
		
		TaskDetails = NStr("ru = 'Обновление конфигурации 1С:Предприятие'; en = 'Update 1C:Enterprise configuration'; pl = 'Aktualizacja konfiguracji 1C:Enterprise';de = 'Konfigurationsupdate 1C:Enterprise';ro = 'Actualizarea configurației 1C:Enterprise';tr = '1C:İşletme yapılandırmanın güncellemesi'; es_ES = 'Actualizar la configuración de 1C:Enterprise'");
		
		TaskSchedulerTaskCreationScript = TemplatesTexts.TaskSchedulerTaskCreationScript;
		
		InsertScriptParameter("StartDate" , StartDate, True, TaskSchedulerTaskCreationScript);
		InsertScriptParameter("ScriptPath" , ScriptPath, True, TaskSchedulerTaskCreationScript);
		InsertScriptParameter("ScriptParameters" , ScriptParameters, True, TaskSchedulerTaskCreationScript);
		InsertScriptParameter("TaskName" , TaskName, True, TaskSchedulerTaskCreationScript);
		InsertScriptParameter("TaskDetails" , TaskDetails, True, TaskSchedulerTaskCreationScript);
		
		TaskSchedulerTaskCreationScriptName = TempFilesDirForUpdate + "addsheduletask.js";
		ScriptFile = New TextDocument;
		ScriptFile.Output = UseOutput.Enable;
		ScriptFile.SetText(TaskSchedulerTaskCreationScript);
		ScriptFile.Write(TaskSchedulerTaskCreationScriptName, UpdateProgramFilesEncoding());
		
		Parameters.SchedulerTaskCode = TaskCode;
		
		Parameters.Insert("TaskSchedulerTaskCreationScriptName", TaskSchedulerTaskCreationScriptName);
		
	EndIf;
	
	LogFile = New TextDocument;
	LogFile.Output = UseOutput.Enable;
	LogFile.SetText(StandardSubsystemsClient.SupportInformation());
	LogFile.Write(TempFilesDirForUpdate + "templog.txt", TextEncoding.System);
	
	ScriptFile = New TextDocument;
	ScriptFile.Output = UseOutput.Enable;
	ScriptFile.SetText(TemplatesTexts.PatchesDeletionScript);
	ScriptFile.Write(TempFilesDirForUpdate + "add-delete-patches.js", UpdateProgramFilesEncoding());
	
	Return MainScriptFileName;
	
EndFunction

Procedure RunUpdateScript(Parameters, AdministrationParameters)
	
	MainScriptFileName = GenerateUpdateScriptFiles(True, Parameters, AdministrationParameters);
	EventLogClient.AddMessageForEventLog(EventLogEvent(), "Information",
		NStr("ru = 'Выполняется процедура обновления конфигурации:'; en = 'Running configuration update procedure:'; pl = 'Trwa aktualizacja konfiguracji:';de = 'Konfiguration aktualisieren:';ro = 'Are loc executarea procedurii de actualizare a configurației:';tr = 'Güncelleme yapılandırması:'; es_ES = 'Actualizando la configuración:'") + " " + MainScriptFileName);
	ConfigurationUpdateServerCall.WriteUpdateStatus(UserName(), True, False, False,
		MainScriptFileName, ApplicationParameters["StandardSubsystems.MessagesForEventLog"]);
		
	Shell = New COMObject("Wscript.Shell");
	Shell.RegWrite("HKCU\Software\Microsoft\Internet Explorer\Styles\MaxScriptStatements", 1107296255, "REG_DWORD");
	
	PathToLauncher = StandardSubsystemsClient.SystemApplicationFolder() + "mshta.exe";
	
	CommandLine = """%1"" ""%2"" [p1]%3[/p1][p2]%4[/p2]";
	CommandLine = StringFunctionsClientServer.SubstituteParametersToString(CommandLine,
		PathToLauncher, MainScriptFileName,
		StringUnicode(AdministrationParameters.InfobaseAdministratorPassword),
		StringUnicode(AdministrationParameters.ClusterAdministratorPassword));
	
	ReturnCode = Undefined;
	RunApp(CommandLine,,, ReturnCode); // CAC:534 update script start.
	ApplicationParameters.Insert("StandardSubsystems.SkipExitConfirmation", True);
	Exit(False);
	
EndProcedure

Procedure ScheduleConfigurationUpdate(Parameters, AdministrationParameters)
	
	GenerateUpdateScriptFiles(False, Parameters, AdministrationParameters);
	
	ApplicationStartupParameters = FileSystemClient.ApplicationStartupParameters();
	ApplicationStartupParameters.ExecuteWithFullRights = True;
	
	StartupCommand = New Array;
	StartupCommand.Add("wscript.exe");
	StartupCommand.Add("//nologo");
	StartupCommand.Add(Parameters.TaskSchedulerTaskCreationScriptName);
	
	FileSystemClient.StartApplication(StartupCommand, ApplicationStartupParameters);
	
	ConfigurationUpdateServerCall.WriteUpdateStatus(UserName(), True, False, False);
	
EndProcedure

#EndIf

// Returns True if Designer is available.
//
// See Common.DebugMode 
//
// Returns:
//  Boolean - True if Designer is available.
//
Function DesignerBatchModeSupported()
	
#If WebClient Or MobileClient Then
	Return False;
#Else
	Designer = BinDir() + "1cv8.exe";
	FileInfo = New File(Designer);
	Return FileInfo.Exist(); // APK:556 synchronized calls outside web client are allowed;
#EndIf
	
EndFunction

#EndRegion