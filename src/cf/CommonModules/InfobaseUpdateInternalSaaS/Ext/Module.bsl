///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Internal

// Generates a data areas update plan and saves it to the infobase.
//
// Parameters:
//  LibraryID - String - configuration name or library ID,
//  AllHandlers - Map - list of all update handlers,
//  RequiredSeparatedHandlers - Map - list of required update handlers with CommonData = False,
//    
//  SourceInfobaseVersion - String - original infobase version,
//  IBMetadataVersion - String - configuration version (from metadata).
//
Procedure GenerateDataAreaUpdatePlan(LibraryID, AllHandlers, 
	MandatorySeparatedHandlers, SourceIBVersion, IBMetadataVersion) Export
	
	If SaaS.DataSeparationEnabled()
		AND Not SaaS.SeparatedDataUsageAvailable() Then
		
		UpdateHandlers = AllHandlers.CopyColumns();
		For Each HandlerRow In AllHandlers Do
			// When generating area update plan, mandatory (*) handlers are not added by default.
			If HandlerRow.Version = "*" Then
				Continue;
			EndIf;
			FillPropertyValues(UpdateHandlers.Add(), HandlerRow);
		EndDo;
		
		For Each RequiredHandler In MandatorySeparatedHandlers Do
			HandlerRow = UpdateHandlers.Add();
			FillPropertyValues(HandlerRow, RequiredHandler);
			HandlerRow.Version = "*";
		EndDo;
		
		FilterParameters = InfobaseUpdateInternal.HandlerFIlteringParameters();
		FilterParameters.GetSeparated = True;
		DataAreaUpdatePlan = InfobaseUpdateInternal.UpdateInIntervalHandlers(
			UpdateHandlers, SourceIBVersion, IBMetadataVersion, FilterParameters);
			
		PlanDetails = New Structure;
		PlanDetails.Insert("VersionFrom", SourceIBVersion);
		PlanDetails.Insert("VersionTo", IBMetadataVersion);
		PlanDetails.Insert("Plan", DataAreaUpdatePlan);
		
		RecordManager = InformationRegisters.SubsystemsVersions.CreateRecordManager();
		RecordManager.SubsystemName = LibraryID;
		
		Lock = New DataLock;
		LockItem = Lock.Add("InformationRegister.SubsystemsVersions");
		LockItem.SetValue("SubsystemName", LibraryID);
		
		BeginTransaction();
		Try
			Lock.Lock();
			
			RecordManager.Read();
			RecordManager.UpdatePlan = New ValueStorage(PlanDetails);
			RecordManager.Write();
			
			CommitTransaction();
		Except
			RollbackTransaction();
			Raise;
		EndTry;
		
		UpdatePlanEmpty = DataAreaUpdatePlan.Rows.Count() = 0;
		
		If LibraryID = Metadata.Name Then
			// Configuration version can be set only if no library updates are required, otherwise the update 
			// will not run in the areas and the libraries will not be updated.
			UpdatePlanEmpty = False;
			
			// Checking whether each plan is empty.
			Libraries = New ValueTable;
			Libraries.Columns.Add("Name", Metadata.InformationRegisters.SubsystemsVersions.Dimensions.SubsystemName.Type);
			Libraries.Columns.Add("Version", Metadata.InformationRegisters.SubsystemsVersions.Resources.Version.Type);
			
			SubsystemsDetails  = StandardSubsystemsCached.SubsystemsDetails();
			For each SubsystemName In SubsystemsDetails.Order Do
				SubsystemDetails = SubsystemsDetails.ByNames.Get(SubsystemName);
				If NOT ValueIsFilled(SubsystemDetails.MainServerModule) Then
					// The library has no module, therefore no update handlers.
					Continue;
				EndIf;
				
				LibraryRow = Libraries.Add();
				LibraryRow.Name = SubsystemDetails.Name;
				LibraryRow.Version = SubsystemDetails.Version;
			EndDo;
			
			Query = New Query;
			Query.SetParameter("Libraries", Libraries);
			Query.Text =
				"SELECT
				|	Libraries.Name AS Name,
				|	Libraries.Version AS Version
				|INTO Libraries
				|FROM
				|	&Libraries AS Libraries
				|;
				|
				|////////////////////////////////////////////////////////////////////////////////
				|SELECT
				|	Libraries.Name AS Name,
				|	Libraries.Version AS Version,
				|	SubsystemsVersions.UpdatePlan AS UpdatePlan,
				|	CASE
				|		WHEN SubsystemsVersions.Version = Libraries.Version
				|			THEN TRUE
				|		ELSE FALSE
				|	END AS Updated
				|FROM
				|	Libraries AS Libraries
				|		LEFT JOIN InformationRegister.SubsystemsVersions AS SubsystemsVersions
				|		ON Libraries.Name = SubsystemsVersions.SubsystemName";
				
			BeginTransaction();
			Try
				Lock = New DataLock;
				LockItem = Lock.Add("InformationRegister.SubsystemsVersions");
				LockItem.Mode = DataLockMode.Shared;
				Lock.Lock();
				
				Result = Query.Execute();
				
				CommitTransaction();
			Except
				RollbackTransaction();
				Raise;
			EndTry;
			
			Selection = Result.Select();
			While Selection.Next() Do
				
				If NOT Selection.Updated Then
					UpdatePlanEmpty = False;
					
					CommentTemplate = NStr("ru = 'Обновление версии конфигурации было выполнено до обновления версии библиотеки %1'; en = 'Configuration version update was performed before updating %1 library version'; pl = 'Wersja konfiguracji została zaktualizowana przed aktualizacją wersji biblioteki %1';de = 'Die Konfigurationsversion wurde aktualisiert, bevor eine Version der Bibliothek aktualisiert wurde %1';ro = 'Versiunea configurației a fost actualizată înainte de a actualiza versiunea librăriei %1';tr = 'Yapılandırma sürümü, kütüphanenin bir sürümünü güncellemeden önce güncellendi.%1'; es_ES = 'Versión de la configuración se ha actualizado antes de actualizar una versión de la biblioteca %1'");
					CommentText = StringFunctionsClientServer.SubstituteParametersToString(CommentTemplate, Selection.Name);
					WriteLogEvent(
						InfobaseUpdate.EventLogEvent(),
						EventLogLevel.Error,
						,
						,
						CommentText);
					
					Break;
				EndIf;
				
				If Selection.UpdatePlan = Undefined Then
					LibraryUpdatePlanDetails = Undefined;
				Else
					LibraryUpdatePlanDetails = Selection.UpdatePlan.Get();
				EndIf;
				
				If LibraryUpdatePlanDetails = Undefined Then
					UpdatePlanEmpty = False;
					
					CommentTemplate = NStr("ru = 'Не найден план обновления библиотеки %1'; en = '%1 library update plan not found'; pl = 'Nie znaleziono planu aktualizacji biblioteki %1';de = 'Der Aktualisierungsplan der Bibliothek %1 wurde nicht gefunden';ro = 'Planul de actualizare a librăriei %1 nu a fost găsit';tr = 'Kütüphanenin güncelleme planı bulunamadı%1'; es_ES = 'Plan de actualización de la biblioteca %1 no se ha encontrado'");
					CommentText = StringFunctionsClientServer.SubstituteParametersToString(CommentTemplate, Selection.Name);
					WriteLogEvent(
						InfobaseUpdate.EventLogEvent(),
						EventLogLevel.Error,
						,
						,
						CommentText);
					
					Break;
				EndIf;
				
				If LibraryUpdatePlanDetails.VersionTo <> Selection.Version Then
					UpdatePlanEmpty = False;
					
					CommentTemplate = NStr("ru = 'Обнаружен некорректный план обновления библиотеки %1
						|Требуется план обновления на версию %2, найден план для обновления на версию %3'; 
						|en = 'Invalid update plan of the %1 library is detected.
						|Plan for updating to version %2 is required, plan for updating to version %3 is found.'; 
						|pl = 'Został wykryty niepoprawny plan aktualizacji biblioteki %1
						|Wymagany jest plan aktualizacji do wersji %2, jest znaleziony plan dla aktualizacji do wersji %3';
						|de = 'Falscher Bibliothek-Update-Plan gefunden%1
						| Erfordert einen Update-Plan für die Version %2, findet einen Plan zum Update auf die Version %3';
						|ro = 'A fost găsit planul incorect de actualizare a librăriei%1
						|Este necesar planul de actualizare cu versiunea %2, s-a găsit planul de actualizare cu versiunea %3';
						|tr = '
						|Yanlış kütüphane güncelleme planı bulundu%1 Sürüm planına yönelik bir güncelleme gerekli%2, sürüm planında bir güncelleme bulundu%3'; 
						|es_ES = 'Plan incorrecto de actualización de la biblioteca %1
						|se ha encontrado Un plan de la actualización a la versión está requerido %2, un plan de la actualización a la versión se ha encontrado %3'");
					CommentText = StringFunctionsClientServer.SubstituteParametersToString(CommentTemplate, Selection.Name, String(LibraryUpdatePlanDetails.VersionTo), String(Selection.Version));
					WriteLogEvent(
						InfobaseUpdate.EventLogEvent(),
						EventLogLevel.Error,
						,
						,
						CommentText);
					
					Break;
				EndIf;
				
				If LibraryUpdatePlanDetails.Plan.Rows.Count() > 0 Then
					UpdatePlanEmpty = False;
					Break;
				EndIf;
				
			EndDo;
		EndIf;
		
		If UpdatePlanEmpty Then
			
			// Update plan does not contain separated or exclusive handlers.
			// Checking for the separated deferred handlers.
			DeferredFilterParameters = InfobaseUpdateInternal.HandlerFIlteringParameters();
			DeferredFilterParameters.GetSeparated = True;
			DeferredFilterParameters.UpdateMode = "Deferred";
			
			DeferredHandlers = InfobaseUpdateInternal.UpdateInIntervalHandlers(UpdateHandlers, SourceIBVersion, IBMetadataVersion, DeferredFilterParameters);
			
			// No separated deferred handlers, install a new version of the library.
			If DeferredHandlers.Rows.Count() = 0 Then
			
				SetAllDataAreasVersion(LibraryID, SourceIBVersion, IBMetadataVersion);
				
			EndIf;
			
		EndIf;
		
	EndIf;
	
EndProcedure

// Blocks the record in the DataAreaSubsystemVersions information register that corresponds to the 
// current data area, and returns the record key.
//
// Returns:
//   InformationRegisterRecordKey.
//
Function LockDataAreaVersions() Export
	
	RecordKey = Undefined;
	If SaaS.DataSeparationEnabled() Then
		
		If SaaS.SeparatedDataUsageAvailable() Then
			SetPrivilegedMode(True);
		EndIf;
		
		RecordKey = SubsystemVersionsRecordKey();
		
	EndIf;
	
	If RecordKey <> Undefined Then
		Try
			LockDataForEdit(RecordKey);
		Except
			WriteLogEvent(InfobaseUpdate.EventLogEvent() + "." 
				+ NStr("ru = 'Обновление области данных'; en = 'Data area update'; pl = 'Aktualizacja obszaru danych';de = 'Datenbereich aktualisieren';ro = 'Actualizarea domeniului de date';tr = 'Veri alanını güncelle'; es_ES = 'Actualizar el área de datos'", Common.DefaultLanguageCode()),
				EventLogLevel.Error,,,
				DetailErrorDescription(ErrorInfo()));
			Raise(NStr("ru = 'Ошибка обновления области данных. Запись версий области данных заблокирована.'; en = 'An error occurred when updating the data area. Writing of data area versions is locked.'; pl = 'Podczas aktualizacji obszaru danych wystąpił błąd. Zapis wersji obszaru danych jest zablokowany.';de = 'Beim Aktualisieren des Datenbereichs ist ein Fehler aufgetreten. Das Schreiben von Datenbereichsversionen ist gesperrt.';ro = 'A apărut o eroare la actualizarea zonei de date. Scrierea versiunilor zonei de date este blocată.';tr = 'Veri alanı güncellenirken bir hata oluştu. Veri alanı sürümlerinin yazılması kilitlenmiştir.'; es_ES = 'Ha ocurrido un error al actualizar el área de datos. Está bloqueado grabar las versiones del área de datos.'"));
		EndTry;
	EndIf;
	Return RecordKey;
	
EndFunction

// Unlocks the record in the DataAreaSubsystemVersions information register.
//
// Parameters:
//   RecordKey - InformationRegisterRecordKey.
//
Procedure UnlockDataAreaVersions(RecordKey) Export
	
	If RecordKey <> Undefined Then
		UnlockDataForEdit(RecordKey);
	EndIf;
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Configuration subsystems event handlers.

// Sets the job usage flag that corresponds to the deferred update scheduled job in the job queue.
// 
//
// Parameters:
//  Usage - Boolean - new value of the usage flag.
//
Procedure OnEnableDeferredUpdate(Val Usage) Export
	
	Template = JobQueue.TemplateByName("DeferredIBUpdate");
	
	JobFilter = New Structure;
	JobFilter.Insert("Template", Template);
	Jobs = JobQueue.GetJobs(JobFilter);
	
	JobParameters = New Structure("Use", Usage);
	JobQueue.ChangeJob(Jobs[0].ID, JobParameters);
	
EndProcedure

// See InfobaseUpdateSSL.InfobaseBeforeUpdate. 
Procedure BeforeUpdateInfobase() Export
	
	If SaaS.DataSeparationEnabled()
	   AND SaaS.SeparatedDataUsageAvailable() Then
		
		SharedDataVersion = InfobaseUpdateInternal.IBVersion(Metadata.Name, True);
		If InfobaseUpdateInternal.UpdateRequired(Metadata.Version, SharedDataVersion) Then
			Message = NStr("ru = 'Не выполнена общая часть обновления информационной базы.
				|Обратитесь к администратору.'; 
				|en = 'Common part of the infobase update is not performed.
				|Contact the administrator.'; 
				|pl = 'Łączna część aktualizacji bazy informacyjnej nie została przeprowadzona.
				|Skontaktuj się z administratorem.';
				|de = 'Der übliche Teil des Infobase-Updates wird nicht ausgeführt.
				|Wenden Sie sich an Ihren Administrator.';
				|ro = 'Partea generală a actualizării bazei de date nu este executată.
				|Adresați-vă administratorului.';
				|tr = 'Veritabanı güncellemesinin ortak kısmı yürütülmez.
				| Yöneticinize başvurun.'; 
				|es_ES = 'Parte común de la actualización de la infobase no se ha ejecutado.
				|Contactar su administrador.'");
			WriteLogEvent(InfobaseUpdate.EventLogEvent(), EventLogLevel.Error,,, Message);
			Raise Message;
		EndIf;
	EndIf;
	
EndProcedure	

// For internal use only.
Procedure OnDetermineIBVersion(Val LibraryID, Val GetSharedDataVersion, StandardProcessing, IBVersion) Export
	
	If SaaS.SessionSeparatorUsage() AND Not GetSharedDataVersion Then
		
		StandardProcessing = False;
		
		QueryText = 
		"SELECT
		|	DataAreasSubsystemsVersions.Version
		|FROM
		|	InformationRegister.DataAreasSubsystemsVersions AS DataAreasSubsystemsVersions
		|WHERE
		|	DataAreasSubsystemsVersions.SubsystemName = &SubsystemName
		|	AND DataAreasSubsystemsVersions.DataAreaAuxiliaryData = &DataAreaAuxiliaryData";
		Query = New Query(QueryText);
		Query.SetParameter("SubsystemName", LibraryID);
		Query.SetParameter("DataAreaAuxiliaryData", SaaS.SessionSeparatorValue());
		ValueTable = Query.Execute().Unload();
		IBVersion = "";
		If ValueTable.Count() > 0 Then
			IBVersion = TrimAll(ValueTable[0].Version);
		EndIf;
		
	EndIf;
	
EndProcedure

// For internal use only.
Procedure OnDetermineFirstSignInToDataArea(StandardProcessing, Result) Export
	
	If SaaS.SessionSeparatorUsage() Then
		
		StandardProcessing = False;
		
		QueryText = 
		"SELECT TOP 1
		|	1
		|FROM
		|	InformationRegister.DataAreasSubsystemsVersions AS DataAreasSubsystemsVersions
		|WHERE
		|	DataAreasSubsystemsVersions.DataAreaAuxiliaryData = &DataAreaAuxiliaryData";
		Query = New Query(QueryText);
		Query.SetParameter("DataAreaAuxiliaryData", SaaS.SessionSeparatorValue());
		Result = Query.Execute().IsEmpty();
		
	EndIf;
	
EndProcedure

// For internal use only.
Procedure OnSetIBVersion(Val LibraryID, Val VersionNumber, StandardProcessing) Export
	
	If SaaS.SessionSeparatorUsage() Then
		
		StandardProcessing = False;
		
		DataArea = SaaS.SessionSeparatorValue();
		
		RecordManager = InformationRegisters.DataAreasSubsystemsVersions.CreateRecordManager();
		RecordManager.DataAreaAuxiliaryData = DataArea;
		RecordManager.SubsystemName = LibraryID;
		RecordManager.Version = VersionNumber;
		RecordManager.Write();
		
	EndIf;
	
EndProcedure

// For internal use only.
Procedure OnCheckDeferredUpdateHandlersRegistration(RegistrationCompleted, StandardProcessing) Export
	
	If SaaS.SessionSeparatorUsage() Then
		StandardProcessing = False;
		Query = New Query;
		Query.Text =
			"SELECT
			|	DataAreasSubsystemsVersions.SubsystemName
			|FROM
			|	InformationRegister.DataAreasSubsystemsVersions AS DataAreasSubsystemsVersions
			|WHERE
			|	NOT DataAreasSubsystemsVersions.DeferredHandlersRegistrationCompleted
			|	AND DataAreasSubsystemsVersions.DataAreaAuxiliaryData = &DataAreaAuxiliaryData";
			
		Query.SetParameter("DataAreaAuxiliaryData", SaaS.SessionSeparatorValue());
		Result = Query.Execute().Unload();
		RegistrationCompleted = (Result.Count() = 0);
	EndIf;
	
EndProcedure

// For internal use only.
Procedure OnMarkDeferredUpdateHandlersRegistration(SubsystemName, Value, StandardProcessing) Export
	
	If SaaS.SessionSeparatorUsage() Then
		StandardProcessing = False;
		
		RecordSet = InformationRegisters.DataAreasSubsystemsVersions.CreateRecordSet();
		If SubsystemName <> Undefined Then
			RecordSet.Filter.SubsystemName.Set(SubsystemName);
		EndIf;
		RecordSet.Read();
		
		If RecordSet.Count() = 0 Then
			Return;
		EndIf;
		
		For Each RegisterRecord In RecordSet Do
			RegisterRecord.DeferredHandlersRegistrationCompleted = Value;
		EndDo;
		RecordSet.Write();
	EndIf;
	
EndProcedure

// For internal use only.
Procedure OnSendSubsystemVersions(DataItem, ItemSending, Val InitialImageCreation, StandardProcessing) Export
	
	If Not SaaS.SessionSeparatorUsage() Then
		Return;
	EndIf;
	StandardProcessing = False;
	
	If ItemSending = DataItemSend.Delete
		OR ItemSending = DataItemSend.Ignore Then
		
		// No overriding for standard data processor.
		
	ElsIf TypeOf(DataItem) = Type("InformationRegisterRecordSet.SubsystemsVersions") Then
		
		If InitialImageCreation Then
			
			If SaaS.DataSeparationEnabled() Then
				
				If SaaS.SeparatedDataUsageAvailable() Then
					
					For Each SetRow In DataItem Do
						
						QueryText =
						"SELECT
						|	DataAreasSubsystemsVersions.Version AS Version
						|FROM
						|	InformationRegister.DataAreasSubsystemsVersions AS DataAreasSubsystemsVersions
						|WHERE
						|	DataAreasSubsystemsVersions.SubsystemName = &SubsystemName";
						
						Query = New Query;
						Query.SetParameter("SubsystemName", SetRow.SubsystemName);
						Query.Text = QueryText;
						
						Selection = Query.Execute().Select();
						
						If Selection.Next() Then
							
							SetRow.Version = Selection.Version;
							
						Else
							
							SetRow.Version = "";
							
						EndIf;
						
					EndDo;
					
				EndIf;
				
			Else
				
				// When creating an initial image with disabled separation, register export is performed without 
				// additional data processing.
				
			EndIf;
			
		Else
			
			// Exporting the register during the initial image creation only.
			ItemSending = DataItemSend.Ignore;
			
		EndIf;
		
	EndIf;
	
EndProcedure

// See JobsQueueOverridable.OnDefineHandlersAliases. 
Procedure OnDefineHandlerAliases(NameAndAliasMap) Export
	
	NameAndAliasMap.Insert("InfobaseUpdateInternalSaaS.UpdateCurrentDataArea");
	
EndProcedure

// See ExportImportDataOverridable.OnFillTypesExcludedFromExportImport. 
Procedure OnFillTypesExcludedFromExportImport(Types) Export
	
	Types.Add(Metadata.InformationRegisters.DataAreasSubsystemsVersions);
	
EndProcedure

// See JobsQueueOverridable.OnDefineScheduledJobsUsage. 
Procedure OnDefineScheduledJobsUsage(UsageTable) Export
	
	NewRow = UsageTable.Add();
	NewRow.ScheduledJob = "DataAreasUpdate";
	NewRow.Use       = True;
	
EndProcedure

// See InfobaseUpdateSSL.AfterUpdateInfobase. 
Procedure AfterUpdateInfobase(Val PreviousVersion, Val CurrentVersion,
		Val CompletedHandlers, OutputUpdatesDetails, ExclusiveMode) Export
	
	If SaaS.SeparatedDataUsageAvailable() Then
		
		LockParameters = IBConnections.GetDataAreaSessionLock();
		If NOT LockParameters.Use Then
			Return;
		EndIf;
		LockParameters.Use = False;
		IBConnections.SetDataAreaSessionLock(LockParameters);
		
	Else
		
		DisableExclusiveMode = False;
		If Not ExclusiveMode() Then
			
			Try
				SetExclusiveMode(True);
				DisableExclusiveMode = True;
			Except
				// No exception processing required.
				// Expected exception - error setting exclusive mode because other sessions are running (for example, 
				// during dynamic configuration update).
				// In this case area update planning is performed considering the possible competition when 
				// accessing metadata object tables separated in the "Independent and shared" mode (which is less 
				// efficient than the execution in the exclusive mode).
				// 
				MessageString = NStr("ru = 'Не удалось установить монопольный режим. Описание ошибки: %1'; en = 'Cannot set exclusive mode. Error description: %1'; pl = 'Nie udało się ustawić tryb wyłączności. Opis błędu: %1';de = 'Der Monopolmodus konnte nicht eingestellt werden. Fehlerbeschreibung: %1';ro = 'Eșec la instalarea regimului monopol. Descrierea erorii: %1';tr = 'Özel mod ayarlanamıyor. Hata tanımı: %1'; es_ES = 'No se puede establecer el modo exclusivo. Descripción del error: %1'", Common.DefaultLanguageCode());
				MessageString = StringFunctionsClientServer.SubstituteParametersToString(MessageString, DetailErrorDescription(ErrorInfo()));
				
				WriteLogEvent(InfobaseUpdate.EventLogEvent(), 
					EventLogLevel.Warning, , , MessageString);
			EndTry;
			
		EndIf;
		
		ScheduleDataAreaUpdate(True);
		
		If DisableExclusiveMode Then
			SetExclusiveMode(False);
		EndIf;
		
	EndIf;
	
EndProcedure

// See InfobaseUpdateSSL.OnAddUpdateHandlers. 
Procedure OnAddUpdateHandlers(Handlers) Export
	
	Handler = Handlers.Add();
	Handler.Version = "2.1.3.19";
	Handler.Procedure = "InfobaseUpdateInternalSaaS.MoveSubsystemVersionsToAuxiliaryData";
	Handler.SharedData = True;
	
	Handler                     = Handlers.Add();
	Handler.Version              = "2.3.1.48";
	Handler.ExclusiveMode    = False;
	Handler.SharedData         = True;
	Handler.InitialFilling = True;
	Handler.Procedure           = "InfobaseUpdateInternalSaaS.MovePasswordsToSecureStorage";
	
EndProcedure

// See StandardSubsystemsServer.ValidateExchangePlanComposition. 
Procedure OnGetExchangePlanObjectsToExclude(Objects, Val DistributedInfobase) Export
	
	If DistributedInfobase Then
		
		Objects.Add(Metadata.InformationRegisters.DataAreasSubsystemsVersions);
		
	EndIf;
	
EndProcedure

// See ExportImportDataOverridable.AfterDataImport. 
Procedure AfterImportData(Container) Export
	
	Info = InfobaseUpdateInternal.InfobaseUpdateInfo();
	UpdateCompleted = Info.DeferredUpdateCompletedSuccessfully;
	If UpdateCompleted <> True Then
		InfobaseUpdateInternal.ReregisterDataForDeferredUpdate();
	EndIf;
	InfobaseUpdateInternal.CanlcelDeferredUpdateHandlersRegistration(, True);
	
EndProcedure

#EndRegion

#Region Private

////////////////////////////////////////////////////////////////////////////////
// INFOBASE UPDATE HANDLERS

// Transfers data from the DELETE information register to the DataAreaSubsystemVersions information 
//  register.
Procedure MoveSubsystemVersionsToAuxiliaryData() Export
	
	If Not SaaS.DataSeparationEnabled() Then
		Return;
	EndIf;
	
	BeginTransaction();
	
	Try
		
		Lock = New DataLock();
		Lock.Add("InformationRegister.DataAreasSubsystemsVersions");
		Lock.Lock();
		
		QueryText =
		"SELECT
		|	ISNULL(DataAreasSubsystemsVersions.DataAreaAuxiliaryData, DeleteSubsystemVersions.DataArea) AS DataAreaAuxiliaryData,
		|	ISNULL(DataAreasSubsystemsVersions.SubsystemName, DeleteSubsystemVersions.SubsystemName) AS SubsystemName,
		|	ISNULL(DataAreasSubsystemsVersions.Version, DeleteSubsystemVersions.Version) AS Version
		|FROM
		|	InformationRegister.DeleteSubsystemVersions AS DeleteSubsystemVersions
		|		LEFT JOIN InformationRegister.DataAreasSubsystemsVersions AS DataAreasSubsystemsVersions
		|		ON DeleteSubsystemVersions.DataArea = DataAreasSubsystemsVersions.DataAreaAuxiliaryData
		|			AND DeleteSubsystemVersions.SubsystemName = DataAreasSubsystemsVersions.SubsystemName
		|WHERE
		|	DeleteSubsystemVersions.DataArea <> -1";
		Query = New Query(QueryText);
		
		DataAreasSubsystemsVersions = InformationRegisters.DataAreasSubsystemsVersions.CreateRecordSet();
		DataAreasSubsystemsVersions.Load(Query.Execute().Unload());
		InfobaseUpdate.WriteData(DataAreasSubsystemsVersions);
		
		SetDELETE = InformationRegisters.DeleteSubsystemVersions.CreateRecordSet();
		InfobaseUpdate.WriteData(SetDELETE);
		
		CommitTransaction();
		
	Except
		
		RollbackTransaction();
		Raise;
		
	EndTry;
	
EndProcedure

// Transfer passwords to a secure storage.
//
Procedure MovePasswordsToSecureStorage() Export
	
	If Not Common.SubsystemExists("SaaSTechnology.SaaS.RemoteAdministrationSaaS") Then
		Return;
	EndIf;
	
	// For auxiliary service Manager user.
	AuxiliaryServiceManagerUserName = Constants.DeleteServiceManagerInternalUsername.Get();
	AuxiliaryServiceManagerUserPassword = Constants.DeleteServiceManagerInternalUserPassword.Get();
	Owner = Common.MetadataObjectID("Constant.InternalServiceManagerURL");
	SetPrivilegedMode(True);
	Common.WriteDataToSecureStorage(Owner, AuxiliaryServiceManagerUserName, "AuxiliaryServiceManagerUsername");
	Common.WriteDataToSecureStorage(Owner, AuxiliaryServiceManagerUserPassword, "AuxiliaryServiceManagerUserPassword");
	SetPrivilegedMode(False);
	Constants.DeleteServiceManagerInternalUsername.Set("");
	Constants.DeleteServiceManagerInternalUserPassword.Set("");
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Data areas update.

// Returns the record key for DataAreaSubsystemVersions information register.
//
// Returns:
//   InformationRegisterRecordKey.DataAreaSubsystemVersions - an information register record key.
//
Function SubsystemVersionsRecordKey()
	
	KeyValues = New Structure;
	If SaaS.SeparatedDataUsageAvailable() Then
		KeyValues.Insert("DataAreaAuxiliaryData", SaaS.SessionSeparatorValue());
		KeyValues.Insert("SubsystemName", "");
		RecordKey = SaaS.CreateAuxiliaryDataInformationRegisterRecordKey(
			InformationRegisters.DataAreasSubsystemsVersions, KeyValues);
	EndIf;
	
	Return RecordKey;
	
EndFunction

// Selects all data areas with outdated versions and generates background jobs for updating when 
// necessary.
// 
//
// Parameters:
//   LockAreas - Boolean - set data area session lock during the area update,
//     
//   LockMessage - String - lock message.
//
Procedure ScheduleDataAreaUpdate(Val LockAreas = True, Val LockMessage = "")
	
	SetPrivilegedMode(True);
	
	If NOT SaaS.DataSeparationEnabled() Then
		Return;
	EndIf;
	
	If IsBlankString(LockMessage) Then
		LockMessage = Constants.LockMessageOnConfigurationUpdate.Get();
		If IsBlankString(LockMessage) Then
			LockMessage = NStr("ru = 'Система заблокирована для выполнения обновления.'; en = 'System is locked for update.'; pl = 'System jest zablokowany do aktualizacji.';de = 'Das System ist für das Update gesperrt.';ro = 'Sistemul este blocat pentru actualizare.';tr = 'Sistem güncelleme için kilitlendi.'; es_ES = 'Sistema está bloqueado para la actualización.'");
		EndIf;
	EndIf;
	LockParameters = IBConnections.NewConnectionLockParameters();
	LockParameters.Begin = CurrentUniversalDate();
	LockParameters.Message = LockMessage;
	LockParameters.Use = True;
	LockParameters.Exclusive = True;
	
	MetadataVersion = Metadata.Version;
	If IsBlankString(MetadataVersion) Then
		Return;
	EndIf;
	
	SharedDataVersion = InfobaseUpdateInternal.IBVersion(Metadata.Name, True);
	If InfobaseUpdateInternal.UpdateRequired(MetadataVersion, SharedDataVersion) Then
		// Common data update is not performed yet, planning area update makes no sense.
		// 
		Return;
	EndIf;
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	DataAreas.DataAreaAuxiliaryData AS DataArea
	|FROM
	|	InformationRegister.DataAreas AS DataAreas
	|		LEFT JOIN InformationRegister.DataAreasSubsystemsVersions AS DataAreasSubsystemsVersions
	|		ON DataAreas.DataAreaAuxiliaryData = DataAreasSubsystemsVersions.DataAreaAuxiliaryData
	|			AND (DataAreasSubsystemsVersions.SubsystemName = &SubsystemName)
	|		LEFT JOIN InformationRegister.DataAreaActivityRating AS DataAreaActivityRating
	|		ON DataAreas.DataAreaAuxiliaryData = DataAreaActivityRating.DataAreaAuxiliaryData
	|WHERE
	|	DataAreas.Status IN (VALUE(Enum.DataAreaStatuses.Used))
	|	AND ISNULL(DataAreasSubsystemsVersions.Version, """") <> &Version
	|
	|ORDER BY
	|	ISNULL(DataAreaActivityRating.Rating, 9999999),
	|	DataArea";
	Query.SetParameter("SubsystemName", Metadata.Name);
	Query.SetParameter("Version", MetadataVersion);
	Result = SaaS.ExecuteQueryOutsideTransaction(Query);
	If Result.IsEmpty() Then // Preliminary reading, perhaps with dirty read parts.
		Return;
	EndIf;
	
	Query = New Query;
	Query.Text =
	"SELECT TOP 1
	|	DataAreas.Status AS Status
	|FROM
	|	InformationRegister.DataAreas AS DataAreas
	|WHERE
	|	DataAreas.DataAreaAuxiliaryData = &DataArea
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT TOP 1
	|	DataAreasSubsystemsVersions.Version AS Version
	|FROM
	|	InformationRegister.DataAreasSubsystemsVersions AS DataAreasSubsystemsVersions
	|WHERE
	|	DataAreasSubsystemsVersions.DataAreaAuxiliaryData = &DataArea
	|	AND DataAreasSubsystemsVersions.SubsystemName = &SubsystemName";
	Query.SetParameter("SubsystemName", Metadata.Name);
	
	Selection = Result.Select();
	While Selection.Next() Do
		KeyValues = New Structure;
		KeyValues.Insert("DataAreaAuxiliaryData", Selection.DataArea);
		KeyValues.Insert("SubsystemName", "");
		RecordKey = SaaS.CreateAuxiliaryDataInformationRegisterRecordKey(
			InformationRegisters.DataAreasSubsystemsVersions, KeyValues);
		
		LockingError = False;
		
		BeginTransaction();
		Try
			Try
				LockDataForEdit(RecordKey); // The lock will be removed after the transaction is completed.
			Except
				LockingError = True;
				Raise;
			EndTry;
			
			Query.SetParameter("DataArea", Selection.DataArea);
		
			Lock = New DataLock;
			
			LockItem = Lock.Add("InformationRegister.DataAreasSubsystemsVersions");
			LockItem.SetValue("DataAreaAuxiliaryData", Selection.DataArea);
			LockItem.SetValue("SubsystemName", Metadata.Name);
			LockItem.Mode = DataLockMode.Shared;
			
			LockItem = Lock.Add("InformationRegister.DataAreas");
			LockItem.SetValue("DataAreaAuxiliaryData", Selection.DataArea);
			LockItem.Mode = DataLockMode.Shared;
			
			Lock.Lock();
			
			Results = Query.ExecuteBatch();
			
			AreaRow = Undefined;
			If NOT Results[0].IsEmpty() Then
				AreaRow = Results[0].Unload()[0];
			EndIf;
			VersionString = Undefined;
			If NOT Results[1].IsEmpty() Then
				VersionString = Results[1].Unload()[0];
			EndIf;
			
			If AreaRow = Undefined
				OR AreaRow.Status <> Enums.DataAreaStatuses.Used
				OR (VersionString <> Undefined AND VersionString.Version = MetadataVersion) Then
				
				// Records do not match the original selection.
				CommitTransaction();
				Continue;
			EndIf;
			
			JobFilter = New Structure;
			JobFilter.Insert("MethodName", "InfobaseUpdateInternalSaaS.UpdateCurrentDataArea");
			JobFilter.Insert("Key", "1");
			JobFilter.Insert("DataArea", Selection.DataArea);
			Jobs = JobQueue.GetJobs(JobFilter);
			If Jobs.Count() > 0 Then
				// The area update job already exists.
				CommitTransaction();
				Continue;
			EndIf;
			
			JobParameters = New Structure;
			JobParameters.Insert("MethodName"    , "InfobaseUpdateInternalSaaS.UpdateCurrentDataArea");
			JobParameters.Insert("Parameters"    , New Array);
			JobParameters.Insert("Key"         , "1");
			JobParameters.Insert("DataArea", Selection.DataArea);
			JobParameters.Insert("ExclusiveExecution", True);
			JobParameters.Insert("RestartCountOnFailure", 3);
			
			JobQueue.AddJob(JobParameters);
			
			If LockAreas Then
				IBConnections.SetDataAreaSessionLock(LockParameters, False, Selection.DataArea);
			EndIf;
			
			CommitTransaction();
			
		Except
			
			RollbackTransaction();
			If LockingError Then
				Continue;
			Else
				Raise;
			EndIf;
			
		EndTry;
		
	EndDo;
	
EndProcedure

// Performs infobase version update in the current data area and removes session locks in the area 
// if they were previously set.
// 
//
Procedure UpdateCurrentDataArea() Export
	
	SetPrivilegedMode(True);
	
	InfobaseUpdate.UpdateInfobase();
	
EndProcedure

// DataAreaUpdate scheduled job handler.
// Selects all data areas with outdated versions and generates background IBUpdate jobs for them 
// when necessary.
//
Procedure DataAreasUpdate() Export
	
	If NOT SaaS.DataSeparationEnabled() Then
		Return;
	EndIf;
	
	// OnScheduledJobStart is not called because the necessary actions are executed privately.
	// 
	
	ScheduleDataAreaUpdate(True);
	
EndProcedure

// For internal use only.
Function EarliestDataAreaVersion() Export
	
	SetPrivilegedMode(True);
	
	If SaaS.DataSeparationEnabled() AND SaaS.SeparatedDataUsageAvailable() Then
		Raise NStr("ru = 'Вызов функции ОбновлениеИнформационнойБазыСлужебныйПовтИсп.МинимальнаяВерсияОбластейДанных()
		                             |недоступен из сеансов с установленным значением разделителей модели сервиса.'; 
		                             |en = 'Cannot call the InfobaseUpdateInternalCached.EarliestDataAreaVersion() function
		                             |from sessions with the set value of SaaS separators.'; 
		                             |pl = 'Wywołanie funkcji ОбновлениеИнформационнойБазыСлужебныйПовтИсп.МинимальнаяВерсияОбластейДанных()
		                             |jest niedostępne z sesji z ustanowioną wartością separatorów modelu serwisu.';
		                             |de = 'Der Aufruf der Funktion UpdateInformationsbasisWiederholteNutzung. MinimaleVersionDerDatenBereiche()
		                             |ist in Sitzungen mit dem eingestellten Wert von Service Model Trennzeichen nicht möglich.';
		                             |ro = 'Apelarea funcției InfobaseUpdateServiceReUse.MinIBVersion ()
		                             |nu este disponibil din sesiunile cu valoarea instalată a separatorilor modelului de serviciu.';
		                             |tr = '
		                             |InfobaseUpdateServiceReUse.MinIBVersion() işlevinin çağrı işlemi,  ayarlanmış hizmet modeli ayırıcı değeri olan oturumlardan kullanılamaz.'; 
		                             |es_ES = 'Llamada de la función InfobaseUpdateServiceReUse.MinIBVersion()
		                             |no se encuentra disponible desde las sesiones con el valor establecido de separadores del modelo de servicio.'");
	EndIf;
	
	Query = New Query;
	Query.SetParameter("SubsystemName", Metadata.Name);
	Query.Text =
	"SELECT DISTINCT
	|	DataAreasSubsystemsVersions.Version AS Version
	|FROM
	|	InformationRegister.DataAreasSubsystemsVersions AS DataAreasSubsystemsVersions
	|WHERE
	|	DataAreasSubsystemsVersions.SubsystemName = &SubsystemName";
	
	Selection = Query.Execute().Select();
	
	EarliestIBVersion = Undefined;
	
	While Selection.Next() Do
		If CommonClientServer.CompareVersions(Selection.Version, EarliestIBVersion) > 0 Then
			EarliestIBVersion = Selection.Version;
		EndIf
	EndDo;
	
	Return EarliestIBVersion;
	
EndFunction

// For internal use only.
Procedure SetAllDataAreasVersion(LibraryID, SourceIBVersion, IBMetadataVersion)
	
	Lock = New DataLock;
	Lock.Add("InformationRegister.DataAreasSubsystemsVersions");
	Lock.Add("InformationRegister.DataAreas");
	
	BeginTransaction();
	Try
		Lock.Lock();
		
		Query = New Query;
		Query.Text =
		"SELECT
		|	DataAreas.DataAreaAuxiliaryData AS DataArea
		|FROM
		|	InformationRegister.DataAreas AS DataAreas
		|		INNER JOIN InformationRegister.DataAreasSubsystemsVersions AS DataAreasSubsystemsVersions
		|		ON DataAreas.DataAreaAuxiliaryData = DataAreasSubsystemsVersions.DataAreaAuxiliaryData
		|WHERE
		|	DataAreas.Status = VALUE(Enum.DataAreaStatuses.Used)
		|	AND DataAreasSubsystemsVersions.SubsystemName = &SubsystemName
		|	AND DataAreasSubsystemsVersions.Version = &Version";
		Query.SetParameter("SubsystemName", LibraryID);
		Query.SetParameter("Version", SourceIBVersion);
		
		Selection = Query.Execute().Select();
		While Selection.Next() Do
			RecordManager = InformationRegisters.DataAreasSubsystemsVersions.CreateRecordManager();
			RecordManager.DataAreaAuxiliaryData = Selection.DataArea;
			RecordManager.SubsystemName = LibraryID;
			RecordManager.Version = IBMetadataVersion;
			RecordManager.Write();
		EndDo;
		
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;
	
EndProcedure

#EndRegion
