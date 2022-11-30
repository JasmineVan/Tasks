///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

///////////////////////////////////////////////////////////////////////////////////////////////////////
// Locking external resources:
// - Disables scheduled jobs operating with external resources.
// - If there is the Conversations subsystem, infobase gets disconnected from the collaboration server.
// External resources can be locked in the following cases:
// - User signs in to the application.
// - A scheduled job marked as operating with external resources starts.
// The lock is always automatic.
// The administrator is offered to confirm the lock or unlock the infobase.
//
// BeforeStart or OnScheduledJobStart gets the session parameter 
// OperationsWithExternalResourcesLocked. Then, the OnSetSessionParameters event is called which 
// sets the lock if the environment is changed.
//
// If the session parameter value is Locked, scheduled jobs are disabled in OnScheduledJobStart.
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Internal

Function OperationsWithExternalResourcesLocked() Export
	
	Return SessionParameters.OperationsWithExternalResourcesLocked;
	
EndFunction

Procedure AllowExternalResources() Export
	
	BeginTransaction();
	Try
		BlockLockParametersData();
		
		LockParameters = SavedLockParameters();
		EnableDisabledScheduledJobs(LockParameters);
		
		LockParameters = CurrentLockParameters();
		SaveLockParameters(LockParameters);
		
		If Common.FileInfobase() Then
			WriteFileInfobaseIDToCheckFile(LockParameters.InfobaseID);
		EndIf;
		
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;
	
	If Common.SubsystemExists("StandardSubsystems.Conversations") Then
		ModuleConversationsInternal = Common.CommonModule("ConversationsService");
		ModuleConversationsInternal.Unlock();
	EndIf;
	
	SessionParameters.OperationsWithExternalResourcesLocked = False;
	
	RefreshReusableValues();
	
EndProcedure

Procedure DenyExternalResources() Export
	
	BeginTransaction();
	Try
		InfobaseID = New UUID();
		Constants.InfoBaseID.Set(String(InfobaseID));
		
		BlockLockParametersData();
		
		LockParameters = SavedLockParameters();
		LockParameters.InfobaseID = InfobaseID;
		LockParameters.OperationsWithExternalResourcesLocked = True;
		SaveLockParameters(LockParameters);
		
		If Common.FileInfobase() Then
			WriteFileInfobaseIDToCheckFile(LockParameters.InfobaseID);
		EndIf;
		
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;
	
	If Common.SubsystemExists("StandardSubsystems.Conversations") Then
		ModuleConversationsInternal = Common.CommonModule("ConversationsService");
		ModuleConversationsInternal.Lock();
	EndIf;
	
	SessionParameters.OperationsWithExternalResourcesLocked = True;
	
	RefreshReusableValues();
	
EndProcedure

Procedure SetServerNameCheckInLockParameters(CheckServerName) Export
	
	BeginTransaction();
	Try
		BlockLockParametersData();
		
		LockParameters = SavedLockParameters();
		LockParameters.CheckServerName = CheckServerName;
		SaveLockParameters(LockParameters);
		
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;
	
EndProcedure

#Region EventsSubscriptionsHandlers

Procedure OnAddSessionParameterSettingHandlers(Handlers) Export
	
	Handlers.Insert("OperationsWithExternalResourcesLocked",
		"ExternalResourcesOperationsLock.OnSetSessionParameters");
	
EndProcedure

Procedure OnSetSessionParameters(ParameterName, SpecifiedParameters) Export 
	
	If ParameterName = "OperationsWithExternalResourcesLocked" Then
		
		BeginTransaction();
		Try
			BlockLockParametersData();
			
			SessionParameters.OperationsWithExternalResourcesLocked = SetExternalResourcesOperationsLock();
			SpecifiedParameters.Add("OperationsWithExternalResourcesLocked");
			
			CommitTransaction();
		Except
			RollbackTransaction();
			Raise;
		EndTry;
		
	EndIf;
	
EndProcedure

Procedure OnStartExecuteScheduledJob(ScheduledJob) Export
	
	If Not Common.SeparatedDataUsageAvailable() Then
		Return;
	EndIf;
	
	JobStartAllowed = Common.SystemSettingsStorageLoad(
		"ScheduledJobs", 
		ScheduledJob.MethodName);
	
	If JobStartAllowed = True Then
		Return;
	EndIf;
	
	If Not ScheduledJobUsesExternalResources(ScheduledJob) Then
		Return;
	EndIf;
	
	If Not OperationsWithExternalResourcesLocked() Then
		Return;
	EndIf;
	
	BeginTransaction();
	Try
		BlockLockParametersData();
		
		LockParameters = SavedLockParameters();
		DisableScheduledJob(LockParameters, ScheduledJob);
		SaveLockParameters(LockParameters);
		
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;
	
	If Common.DataSeparationEnabled() Then
		ExceptionText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Приложение было перемещено.
			           |Регламентное задание ""%1"", работающее с внешними ресурсами, отключено.'; 
			           |en = 'The application was transferred.
			           |The ""%1"" scheduled job working with external resources is disabled.'; 
			           |pl = 'Aplikacja została przeniesiona.
			           |Planowe zadanie ""%1"",działające z zewnętrznymi zasobami, zostało wyłączone.';
			           |de = 'Die Anwendung wurde verschoben.
			           |Die Routineaufgabe ""%1"", die mit externen Ressourcen arbeitet, ist deaktiviert.';
			           |ro = 'Aplicația a fost transferată.
			           |Sarcina reglementară ""%1"", care lucrează cu resursele externe, este dezactivată.';
			           |tr = 'Uygulama taşındı.
			           |Dış kaynaklarla çalışan Standart görev ""%1"", kapatıldı.'; 
			           |es_ES = 'La aplicación ha sido trasladada.
			           |La tarea programada ""%1"", que usa los recursos externos, ha sido desactivada.'"), 
			ScheduledJob.Synonym);
	Else 
		ExceptionText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Изменилась строка соединения информационной базы.
			           |Возможно информационная база была перемещена.
			           |Регламентное задание ""%1"" отключено.'; 
			           |en = 'Infobase connection string was changed.
			           |The infobase might have been transferred.
			           |The ""%1"" scheduled job is disabled.'; 
			           |pl = 'Zmienił się ciąg połączenia bazy informacyjnej.
			           |Możliwie, że baza informacyjna została przeniesiona.
			           |Planowe zadanie ""%1"" zostało wyłączone.';
			           |de = 'Die Verbindungszeichenfolge der Informationsdatenbank wurde geändert.
			           |Möglicherweise wurde die Informationsbasis verschoben.
			           |Die Routineaufgabe ""%1"" ist deaktiviert.';
			           |ro = 'S-a modificat rândul de conexiune al bazei de informații.
			           |Posibil, baza de informații a fost transferată.
			           |Sarcina reglementară ""%1"" este dezactivată.';
			           |tr = 'Veritabanın bağlantı satırı değişti.
			           |Veritabanı taşınmış olabilir.
			           |Standart görev ""%1"" devre dışı bırakıldı.'; 
			           |es_ES = 'Se ha cambiado la línea de conexión de la base de información.
			           |Es posible que la base de información ha sido trasladada.
			           |La tarea programada ""%1"" ha sido desactivada.'"), 
			ScheduledJob.Synonym);
	EndIf;
	
	Raise ExceptionText;
	
EndProcedure

Procedure OnAddClientParametersOnStart(ClientRunParameters, IsCallBeforeStart) Export
	
	ShowLockForm = False;
	
	If IsCallBeforeStart AND OperationsWithExternalResourcesLocked() Then
		LockParameters = SavedLockParameters();
		
		FlagOfNecessityToFinalizeDecisionIsSet = 
			LockParameters.OperationsWithExternalResourcesLocked = Undefined;
		
		ShowLockForm = FlagOfNecessityToFinalizeDecisionIsSet AND Users.IsFullUser();
	EndIf;
	
	ClientRunParameters.Insert("ShowExternalResourceLockForm", ShowLockForm);
	
EndProcedure

Procedure AfterImportData(Container) Export
	
	If Common.DataSeparationEnabled() Then
		LockParameters = CurrentLockParameters();
		SaveLockParameters(LockParameters);
	EndIf;
	
EndProcedure

#EndRegion

#EndRegion

#Region Private

#Region UpdateHandlers

Procedure UpdateExternalResourceAccessLockParameters() Export
	
	BeginTransaction();
	Try
		BlockLockParametersData();
		
		LockParameters = SavedLockParameters();
		
		DataSeparationEnabled = Common.DataSeparationEnabled();
		LockParameters.DataSeparationEnabled = DataSeparationEnabled;
		If DataSeparationEnabled Then
			LockParameters.ConnectionString = "";
			LockParameters.ComputerName = "";
		EndIf;
		
		SaveLockParameters(LockParameters);
		
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;
	
EndProcedure

#EndRegion

#Region LockParameters

Function CurrentLockParameters()
	
	DataSeparationEnabled = Common.DataSeparationEnabled();
	ConnectionString = ?(DataSeparationEnabled, "", InfoBaseConnectionString());
	ComputerName = ?(DataSeparationEnabled, "", ComputerName());
	
	Result = New Structure;
	Result.Insert("InfobaseID", StandardSubsystemsServer.InfoBaseID());
	Result.Insert("IsFileInfobase", Common.FileInfobase());
	Result.Insert("DataSeparationEnabled", DataSeparationEnabled);
	Result.Insert("ConnectionString", ConnectionString);
	Result.Insert("ComputerName", ComputerName);
	Result.Insert("CheckServerName", True);
	Result.Insert("OperationsWithExternalResourcesLocked", False);
	Result.Insert("DisabledJobs", New Array);
	Result.Insert("LockReason", "");
	
	Return Result;
	
EndFunction

Function SavedLockParameters() Export 
	
	SetPrivilegedMode(True);
	SavedParameters = Constants.ExternalResourceAccessLockParameters.Get().Get();
	SetPrivilegedMode(False);
	
	Result = CurrentLockParameters();
	
	If SavedParameters = Undefined Then 
		SaveLockParameters(Result); // Automatic initialization.
		If Common.FileInfobase() Then
			WriteFileInfobaseIDToCheckFile(Result.InfobaseID);
		EndIf;
	EndIf;
	
	If TypeOf(SavedParameters) = Type("Structure") Then 
		FillPropertyValues(Result, SavedParameters); // Reinitializing new properties.
	EndIf;
	
	Return Result;
	
EndFunction

Procedure BlockLockParametersData()
	
	Lock = New DataLock;
	Lock.Add("Constant.ExternalResourceAccessLockParameters");
	Lock.Lock();
	
EndProcedure

Procedure SaveLockParameters(LockParameters)
	
	SetPrivilegedMode(True);
	
	ValueStorage = New ValueStorage(LockParameters);
	Constants.ExternalResourceAccessLockParameters.Set(ValueStorage);
	
	SetPrivilegedMode(False);
	
EndProcedure

#EndRegion

#Region ScheduledJobs

// ACC:453-disable integrated scheduled jobs management in the block of operation lock.

Function ScheduledJobUsesExternalResources(ScheduledJob)
	
	JobDependencies = ScheduledJobsInternal.ScheduledJobsDependentOnFunctionalOptions();
	
	Filter = New Structure;
	Filter.Insert("ScheduledJob", ScheduledJob);
	Filter.Insert("UseExternalResources", True);
	
	FoundRows = JobDependencies.FindRows(Filter);
	Return FoundRows.Count() <> 0;
	
EndFunction

Procedure DisableScheduledJob(LockParameters, ScheduledJob)
	
	If Common.DataSeparationEnabled() Then
		
		If Common.SubsystemExists("StandardSubsystems.SaaS.JobQueue") Then
			ModuleSaaS = Common.CommonModule("SaaS");
			DataArea = ModuleSaaS.SessionSeparatorValue();
			MethodName = ScheduledJob.MethodName;
			
			JobParameters = New Structure;
			JobParameters.Insert("DataArea", DataArea);
			JobParameters.Insert("MethodName", MethodName);
			JobParameters.Insert("Use", True);
			ModuleJobsQueue = Common.CommonModule("JobQueue");
			JobsList = ModuleJobsQueue.GetJobs(JobParameters);
			
			JobParameters = New Structure("Use", False);
			For Each Job In JobsList Do
				ModuleJobsQueue.ChangeJob(Job.ID, JobParameters);
				LockParameters.DisabledJobs.Add(Job.ID);
			EndDo;
		EndIf;
		
	Else
		
		Filter = New Structure;
		Filter.Insert("Metadata", ScheduledJob);
		Filter.Insert("Use", True);
		JobArray = ScheduledJobs.GetScheduledJobs(Filter);
		
		For Each Job In JobArray Do
			
			Job.Use = False;
			Job.Write();
			
			LockParameters.DisabledJobs.Add(Job.UUID);
			
		EndDo;
		
	EndIf;
	
EndProcedure

Procedure EnableDisabledScheduledJobs(LockParameters)
	
	For Each JobID In LockParameters.DisabledJobs Do
		
		If Common.DataSeparationEnabled() Then
			If Common.SubsystemExists("StandardSubsystems.SaaS.JobQueue") Then
				If TypeOf(JobID) = Type("UUID") Then
					Continue;
				EndIf;
				ModuleSaaS = Common.CommonModule("SaaS");
				
				JobParameters = New Structure;
				JobParameters.Insert("DataArea", ModuleSaaS.SessionSeparatorValue());
				JobParameters.Insert("ID", JobID);
				JobParameters.Insert("Use", False);
				ModuleJobQueue = Common.CommonModule("JobQueue");
				JobsList = ModuleJobQueue.GetJobs(JobParameters);
				
				JobParameters = New Structure("Use", True);
				For Each Job In JobsList Do
					ModuleJobQueue.ChangeJob(Job.ID, JobParameters);
				EndDo;
			EndIf;
		Else
			Filter = New Structure("UUID");
			Filter.UUID = JobID;
			FoundJobs = ScheduledJobs.GetScheduledJobs(Filter);
			
			For Each DisabledJob In FoundJobs Do
				DisabledJob.Use = True;
				DisabledJob.Write();
			EndDo;
		EndIf;
		
	EndDo;
	
EndProcedure

// CAC:453-enable

#EndRegion

#Region FileInfobaseIDCheckFile

Function FileInfobaseIDCheckFileExists()
	
	FileInfo = New File(PathToFileInfobaseIDCheckFile());
	Return FileInfo.Exist();
	
EndFunction

Function FileInfobaseIDFromCheckFile()
	
	TextReader = New TextReader(PathToFileInfobaseIDCheckFile());
	InfobaseID = TextReader.ReadLine();
	TextReader.Close();
	Return InfobaseID;
	
EndFunction

Procedure WriteFileInfobaseIDToCheckFile(InfobaseID)
	
	FileContent = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("ru = '%1
		           |
		           |Файл создан автоматически прикладным решением ""%2"".
		           |Он содержит идентификатор информационной базы и позволяет определить, что эта информационная база была скопирована.
		           |
		           |При копировании файлов информационной базы, в том числе при создании резервной копии, не следует копировать этот файл.
		           |Одновременное использование двух копий информационной базы с одинаковым идентификатором может привести к конфликтам
		           |при синхронизации данных, отправке почты и другой работе с внешними ресурсами.
		           |
		           |Если файл отсутствует в каталоге с информационной базой, то программа запросит администратора, должна ли эта
		           |информационная база работать с внешними ресурсами.'; 
		           |en = '%1
		           |
		           |The file is automatically created by the ""%2"" application.
		           |It contains the infobase ID and allows you to identify that this infobase was copied.
		           |
		           |Upon copying infobase files and creating a backup, do not copy this file.
		           |Using both infobase copies with the same ID at the same time can lead to conflicts
		           |while synchronizing data, sending emails, and performing other operations with external resources.
		           |
		           |If the file is missing in the directory with the infobase, then the application will ask the administrator if this
		           |infobase will operate with external resources.'; 
		           |pl = '%1
		           |
		           |Plik utworzony automatycznie stosowanym rozwiązaniem ""%2"".
		           |Zawiera on identyfikator bazy informacyjnej i pozwala ustalić, że ta baza informacyjna została skopiowana.
		           |
		           |Podczas kopiowania plików bazy informacyjnej, w tym podczas tworzenia kopii zapasowej, nie należy kopiować ten plik.
		           |Jednoczesne korzystanie z dwóch kopii bazy informacyjnej z tym samym identyfikatorem może prowadzić do konfliktów
		           |podczas synchronizacji danych, wysyłania poczty e-mail i innej pracy z zewnętrznymi zasobami.
		           |
		           |Jeśli plik nie istnieje w katalogu z bazy informacyjnej, program zapyta administratora, czy ta
		           |informacyjna baza powinna pracować z zewnętrznymi zasobami.';
		           |de = '%1
		           |
		           |Die Datei wird von der Anwendungslösung ""%2"" automatisch erstellt.
		           | Sie enthält die Kennung der Informationsbasis und ermöglicht es Ihnen, festzustellen, ob diese Informationsbasis kopiert wurde.
		           |
		           |Beim Kopieren der Datenbankdateien, auch beim Erstellen einer Sicherung, sollten Sie diese Datei nicht kopieren.
		           |Die gleichzeitige Verwendung von zwei Kopien der Datenbank mit der gleichen Kennung kann zu Konflikten
		           |bei der Datensynchronisation, dem Versenden von E-Mails und anderen Arbeiten mit externen Ressourcen führen.
		           |
		           |Wenn sich die Datei nicht im Verzeichnis mit der Informationsbasis befindet, fragt das Programm den Administrator, ob
		           |die Informationsbasis mit externen Ressourcen arbeiten soll.';
		           |ro = '%1
		           |
		           |Fișierul este creat automat de soluția aplicată ""%2"".
		           |Ea conține identificatorul bazei de informații și permite de a determina faptul că această bază de informații a fost copiată.
		           |
		           |La copierea fișierelor bazei de informații, inclusiv la crearea copiei de rezervă, nu trebuie să copiați acest fișier.
		           |Utilizarea concomitentă a două copii ale bazei de informații cu același identificator poate conduce la conflicte
		           |în timpul sincronizării datelor, trimiterii poștei și altor activități cu resursele externe.
		           |
		           |Dacă fișierul lipsește în catalogul cu baza de informații, atunci programul va interoga administratorul dacă această
		           |bază de informații trebuie să lucreze cu resursele externe.';
		           |tr = '%1
		           |
		           |Dosya otomatik olarak uygulama çözümü ""%2"" tarafından oluşturulur. 
		           |Bir veritabanı kimliği içerir ve bu veri tabanının kopyalandığını belirlemenizi sağlar. 
		           |
		           |Bir yedek oluştururken de dahil olmak üzere veritabanın dosyalarını kopyalarken, bu dosyayı kopyalamayın.
		           | Aynı kimliğe sahip bir veri tabanının iki kopyasını eş zamanlı olarak kullanmak, veri senkronizasyonu, posta gönderme ve diğer dış kaynaklarla 
		           |çakışmalara neden olabilir. 
		           |
		           |Dosya bilgi tabanı ile dizinde yoksa, program bu 
		           |veritabanı dış kaynaklarla çalışıp çalışmadığını yöneticiye sorar.'; 
		           |es_ES = '%1
		           |
		           |El archivo se ha creado automáticamente con la solución aplicada ""%2"".
		           |Contiene el identificador de la base de información y permite comprender que esta base de información ha sido copiada.
		           |
		           |Al copiar los archivos de la base de información incluso al crear la copia de reserva no hay que copiar este archivo.
		           |El uso simultáneo de dos copias de la base de información con el mismo identificador puede llevar a los conflictos
		           | al sincronizar los datos, al enviar el correo y al usar otros recursos externos.
		           |
		           |Si no hay archivo en el catálogo de la base de información, el programa preguntará al administrador si esta
		           |base de información debe usar los recursos externos.'"), 
		InfobaseID, 
		Metadata.Synonym);
	
	FileName = PathToFileInfobaseIDCheckFile();
	
	TextWriter = New TextWriter(FileName);
	Try
		TextWriter.Write(FileContent);
	Except
		TextWriter.Close();
		Raise;
	EndTry;
	TextWriter.Close();
	
EndProcedure

Function PathToFileInfobaseIDCheckFile()
	
	Return CommonClientServer.FileInfobaseDirectory() + GetPathSeparator() + "DoNotCopy.txt";
	
EndFunction

#EndRegion

#Region LockSetting

Function SetExternalResourcesOperationsLock()
	
	If Not Common.SeparatedDataUsageAvailable() Then
		Return False;
	EndIf;
	
	LockParameters = SavedLockParameters();
	
	If LockParameters.OperationsWithExternalResourcesLocked = Undefined Then
		Return True; // Flag shows necessity of lock is set.
	ElsIf LockParameters.OperationsWithExternalResourcesLocked = True Then
		Return True; // Lock of operations with external resources is confirmed by the administrator.
	EndIf;
	
	DataSeparationEnabled = Common.DataSeparationEnabled();
	If DataSeparationEnabled Then
		Return False; // Infobase transfer is determined by the service manager in SaaS mode.
	EndIf;
	
	// The following code is for the case when data separation is disabled.
	
	DataSeparationChanged = LockParameters.DataSeparationEnabled <> DataSeparationEnabled;
	
	If DataSeparationChanged Then
		MessageText = NStr("ru = 'Информационная база была перемещена из приложения в Интернете.'; en = 'The infobase was transferred from an online application.'; pl = 'Baza informacji została przeniesiona z aplikacji w Internecie.';de = 'Die Informationsbasis wurde aus der Anwendung im Internet verschoben.';ro = 'Baza de informații a fost transferată din aplicația din Internet.';tr = 'Veritabanı çevrimiçi uygulamadan taşındı.'; es_ES = 'La base de información ha sido trasladada de la aplicación en Internet.'");
		SetFlagShowsNecessityOfLock(LockParameters, MessageText);
		Return True;
	EndIf;
	
	ConnectionString = InfoBaseConnectionString();
	If ConnectionString = LockParameters.ConnectionString Then
		Return False; // If the connection string matches, do not perform any further check.
	EndIf;
	
	IsFileInfobase = Common.FileInfobase();
	
	MovedBetweenFileAndClientServerMode = IsFileInfobase <> LockParameters.IsFileInfobase;
	
	If MovedBetweenFileAndClientServerMode Then
		MessageText = 
			?(IsFileInfobase, 
				NStr("ru = 'Информационная база была перемещена из клиент-серверного режима работы в файловый.'; en = 'The infobase was transferred from the client/server mode to the file mode.'; pl = 'Baza informacji została przeniesiona z trybu klient-serwer do trybu pracy w pliku.';de = 'Die Informationsbasis wurde vom Client-Server-Modus in den Datei-Modus verschoben.';ro = 'Baza de informații a fost transferată din regimul de lucru client-server în cel de fișier.';tr = 'Veritabanı istemci-sunucu çalışma modundan dosya moduna taşındı.'; es_ES = 'La base de información ha sido trasladada del modo de cliente-servidor al modo de archivo.'"),
				NStr("ru = 'Информационная база была перемещена из файловый режима работы в клиент-серверный.'; en = 'The infobase was transferred from the file mode to the client/server mode.'; pl = 'Baza danych informacji została przeniesiona z trybu plików do trybu pracy w klient-serwer.';de = 'Die Informationsbasis wurde vom Datei-Modus in den Client-Server-Modus verschoben.';ro = 'Baza de informații a fost transferată din regimul de lucru fișier în cel de client-server.';tr = 'Veritabanı dosya modundan istemci-sunucu çalışma moduna taşındı.'; es_ES = 'La base de información ha sido trasladada del modo de archivo al modo de cliente-servidor.'"));
		SetFlagShowsNecessityOfLock(LockParameters, MessageText);
		Return True;
	EndIf;
	
	// The following code when the run mode is not changed:
	// 1. the infobase was file and remained file.
	// 2. the infobase was client/server and remained client/server.
	
	If IsFileInfobase Then
		
		// For the file infobase connection string can be different when connecting from different computers, 
		// so check the infobase movement using the check file.
		
		If Not FileInfobaseIDCheckFileExists() Then
			MessageText = NStr("ru = 'В каталоге информационной базы отсутствует файл проверки DoNotCopy.txt.'; en = 'The infobase directory does not contain the DoNotCopy.txt check file.'; pl = 'W katalogu bazy informacyjnej nie ma pliku weryfikacyjnego DoNotCopy.txt.';de = 'Es gibt keine DoNotCopy.txt-Prüfdatei im Datenbankverzeichnis.';ro = 'În catalogul bazei de informații lipsește fișierul verificării DoNotCopy.txt.';tr = 'Veritabanı dizininde DoNotCopy.txt. doğrulama dosyası yok.'; es_ES = 'En el catálogo de la base de información no hay archivo de prueba DoNotCopy.txt.'");
			SetFlagShowsNecessityOfLock(LockParameters, MessageText);
			Return True;
		EndIf;
		
		InfobaseIDChanged = FileInfobaseIDFromCheckFile() <> LockParameters.InfobaseID;
		
		If InfobaseIDChanged Then
			MessageText = 
				NStr("ru = 'Идентификатор информационной базы в файле проверки DoNotCopy.txt не соответствует идентификатору в текущей базе.'; en = 'The infobase ID in the DoNotCopy.txt check file does not match ID of the current infobase.'; pl = 'Identyfikator bazy informacyjnej w pliku kontrolnym DoNotCopy.txt nie pasuje do identyfikatora w bieżącej bazie danych.';de = 'Die Infobase-ID in der DoNotCopy.txt-Überprüfungsdatei stimmt nicht mit der ID in der aktuellen Datenbank überein.';ro = 'Identificatorul bazei de informații în fișierul verificării DoNotCopy.txt nu corespunde identificatorului în baza curentă.';tr = 'DoNotCopy.txt. doğrulama dosyasındaki bilgi tabanı kimliği geçerli veritabanındaki kimlikle eşleşmiyor.'; es_ES = 'El identificador de la base de información en el archivo de prueba DoNotCopy.txt. no corresponde al identificador en la base actual.'");
			SetFlagShowsNecessityOfLock(LockParameters, MessageText);
			Return True;
		EndIf;
		
	Else // Client/server infobase
		
		InfobaseName = Lower(StringFunctionsClientServer.ParametersFromString(ConnectionString).Ref);
		ConnectionManagerServerName = Lower(StringFunctionsClientServer.ParametersFromString(ConnectionString).Srvr);
		WorkingProcessServerName = Lower(ComputerName());
		
		SavedInfobaseName = 
			Lower(StringFunctionsClientServer.ParametersFromString(LockParameters.ConnectionString).Ref);
		SavedConnectionManagerServerName = 
			Lower(StringFunctionsClientServer.ParametersFromString(LockParameters.ConnectionString).Srvr);
		SavedWorkingProcessServerName = Lower(LockParameters.ComputerName);
		
		InfobaseNameChanged = InfobaseName <> SavedInfobaseName;
		ComputerNameChanged = LockParameters.CheckServerName
			AND WorkingProcessServerName <> SavedWorkingProcessServerName
			AND StrFind(SavedConnectionManagerServerName, ConnectionManagerServerName) = 0;
		
		// If the cluster is scalable, SavedConnectionManagerServerName contains the names of several 
		// servers that can act as a connection manager. When starting scheduled job session, 
		// ConnectionManagerServerName will contain the name of the current active manager.
		//  To resolve this situation, find the occurrence of the current name in the saved name.
		
		If InfobaseNameChanged Or ComputerNameChanged Then
			
			MessageText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'Изменились параметры контроля уникальности клиент-серверной базы.
				           |
				           |Было:
				           |Строка соединения: <%1>
				           |Имя компьютера: <%2>
				           |
				           |Стало:
				           |Строка соединения: <%3>
				           |Имя компьютера: <%4>
				           |
				           |Проверять имя сервера: <%5>'; 
				           |en = 'Parameters of client-server base uniqueness control were changed.
				           |
				           |Previous parameters:
				           |Connection string: <%1>
				           |Computer name: <%2>
				           |
				           |Current parameters:
				           |Connection string: <%3>
				           |Computer name: <%4>
				           |
				           |Check server name: <%5>'; 
				           |pl = 'Zmieniły się parametry kontroli unikalności bazy klient-serwer.
				           |
				           |Było:
				           |Wiersz połączenia: <%1>
				           |Nazwa komputera: <%2>
				           |
				           |Jest:
				           |Wiersz połączenia: <%3>
				           |Nazwa komputera: <%4>
				           |
				           |Sprawdź nazwę serwera: <%5>';
				           |de = 'Die Parameter der Eindeutigkeitskontrolle der Client-Server-Basis wurden geändert.
				           |
				           |War:
				           |Verbindungszeichenkette: <%1>
				           |Computername: <%2>
				           |
				           |Wurde:
				           |Verbindungszeichenkette: <%3>
				           | Computername: <%4>
				           |
				           | Servername überprüfen: <%5>';
				           |ro = 'S-au modificat parametrii de control ai unicității bazei de tip client-server.
				           |
				           |A fost:
				           |Rândul de conexiune: <%1>
				           |Numele computerului: <%2>
				           |
				           |Este:
				           |Rândul de conexiune: <%3>
				           |Numele computerului: <%4>
				           |
				           |Verifică numele serverului: <%5>';
				           |tr = 'Müşteri-sunucu tabanı eşsizliğinin kontrol parametreleri değişti.
				           |
				           |Önceki:
				           |Bağlantı satırı: <%1>
				           |Bilgisayarın adı: <%2>
				           |
				           |Şimdiki:
				           |Bağlantı satırı: <%3>
				           |Bilgisayarın adı: <%4>
				           |
				           |Sunucu adını kontrol et: <%5>'; 
				           |es_ES = 'Los parámetros del control de exclusividad de la base de cliente-servidor se han cambiado.
				           |
				           |Antes:
				           |Línea de conexión: <%1>
				           |Nombre del ordenador: <%2>
				           |
				           |Ahora:
				           |Línea de conexión: <%3>
				           |Nombre del ordenador: <%4>
				           |
				           |Comprobar el nombre de servidor: <%5>'"),
				LockParameters.ConnectionString, 
				SavedWorkingProcessServerName,
				ConnectionString,
				WorkingProcessServerName,
				LockParameters.CheckServerName);
			
			SetFlagShowsNecessityOfLock(LockParameters, MessageText);
			Return True;
		EndIf;
	EndIf;
	
	Return False;
	
EndFunction

Procedure SetFlagShowsNecessityOfLock(LockParameters, MessageText)
	
	LockParameters.OperationsWithExternalResourcesLocked = Undefined;
	LockParameters.LockReason = LockReasonPresentation(LockParameters);
	SaveLockParameters(LockParameters);
	
	If Common.SubsystemExists("StandardSubsystems.Conversations") Then
		ModuleConversationsInternal = Common.CommonModule("ConversationsService");
		ModuleConversationsInternal.Lock();
	EndIf;
	
	WriteLogEvent(EventLogEventName(), EventLogLevel.Warning,,, MessageText);
	
EndProcedure

Function LockReasonPresentation(LockParameters)
	
	Return StringFunctionsClientServer.SubstituteParametersToString(
		NStr("ru = 'Блокировка выполнена на сервере <b>%1</b> в <b>%2</b> %3.
		           |
		           |Размещение информационной базы изменилось с
		           |<b>%4</b>
		           |на 
		           |<b>%5</b>'; 
		           |en = 'Lock is performed on server <b>%1</b> in <b>%2</b> %3.
		           |
		           |Infobase location was changed from
		           |<b>%4</b>
		           |to 
		           |<b>%5</b>'; 
		           |pl = 'Blokada jest wykonywana na serwerze <b>%1</b> w <b>%2</b> %3.
		           |
		           |Położenie bazy informacyjnej zmieniło się z
		           |<b>%4</b>
		           |na 
		           |<b>%5</b>';
		           |de = 'Gesperrt auf dem <b>%1</b>Server in <b>%2</b> %3.
		           |
		           |Die Position der Informationsbasis hat sich von
		           |<b>%4</b>
		           |auf
		           |<b>%5</b> geändert';
		           |ro = 'Blocarea este executată pe serverul <b>%1</b> la <b>%2</b> %3.
		           |
		           |Amplasarea bazei de informații s-a modificat din
		           |<b>%4</b>
		           |în 
		           |<b>%5</b>';
		           |tr = 'Kilitleme <b>%1</b>  <b>%2</b>''de sunucuda yapıldı %3.
		           |
		           |Veri tabanı konumu 
		           |<b>%4</b>
		           |''den olarak 
		           |<b>%5</b> değişti'; 
		           |es_ES = 'El bloqueo se ha realizado en el servidor <b>%1</b> en <b>%2</b> %3.
		           |
		           |La situación de la base de información se ha cambiado de 
		           |<b>%4</b>
		           |a 
		           |<b>%5</b>'"),
		ComputerName(),
		CurrentDate(), // CAC:143 Lock information is required in server date.
		CurrentOperationPresentation(),
		ConnectionStringPresentation(LockParameters.ConnectionString),
		ConnectionStringPresentation(InfoBaseConnectionString()));
	
EndFunction

Function CurrentOperationPresentation()
	
	CurrentInfobaseSession = GetCurrentInfoBaseSession();
	BackgroundJob = CurrentInfobaseSession.GetBackgroundJob();
	
	If BackgroundJob <> Undefined 
		AND BackgroundJob.ScheduledJob <> Undefined Then 
		
		Return StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'при попытке выполнения регламентного задания <b>%1</b>'; en = 'when attempting to perform the scheduled job <b>%1</b>'; pl = 'podczas próby wykonywania zadania zaplanowanego <b>%1</b>';de = 'beim Versuch, eine Routineaufgabe auszuführen <b>%1</b>';ro = 'la tentativa de executare a sarcinii reglementare <b>%1</b>';tr = 'standart görevi yapmaya çalıştığında <b>%1</b>'; es_ES = 'al probar de ejecutar la tarea programada <b>%1</b>'"),
			BackgroundJob.ScheduledJob.Description);
	EndIf;
	
	Return StringFunctionsClientServer.SubstituteParametersToString(
		NStr("ru = 'при входе пользователя <b>%1</b>'; en = 'when user <b>%1</b> is signing in'; pl = 'przy logowaniu użytkownika <b>%1</b>';de = 'bei der Benutzeranmeldung <b>%1</b>';ro = 'la intrarea utilizatorului <b>%1</b>';tr = 'kullanıcının girişinde <b>%1</b>'; es_ES = 'a la entrada de usuario <b>%1</b>'"),
		UserName());
	
EndFunction

Function ConnectionStringPresentation(ConnectionString)
	
	Result = ConnectionString;
	
	Parameters = StringFunctionsClientServer.ParametersFromString(ConnectionString);
	If Parameters.Property("File") Then
		Result = Parameters.File;
	EndIf;
	
	Return Result;
	
EndFunction

Function EventLogEventName() Export 
	
	Return NStr("ru = 'Работа с внешними ресурсами заблокирована'; en = 'Operations with external resources have been locked'; pl = 'Praca z zasobami zewnętrznymi jest zablokowana';de = 'Die Arbeit mit externen Ressourcen ist gesperrt.';ro = 'Lucrul cu resursele externe este blocat';tr = 'Dış kaynaklarla çalışma kilitlendi'; es_ES = 'El uso de los recursos externos ha sido bloqueado'", Common.DefaultLanguageCode());
	
EndFunction

#EndRegion

#EndRegion