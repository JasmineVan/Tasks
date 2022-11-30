///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Internal

// Checks whether it is necessary to update the shared infobase data during configuration version 
// change.
//
Function SharedInfobaseDataUpdateRequired() Export
	
	SetPrivilegedMode(True);
	
	If Common.DataSeparationEnabled() Then
		
		MetadataVersion = Metadata.Version;
		If IsBlankString(MetadataVersion) Then
			MetadataVersion = "0.0.0.0";
		EndIf;
		
		SharedDataVersion = IBVersion(Metadata.Name, True);
		
		If UpdateRequired(MetadataVersion, SharedDataVersion) Then
			Return True;
		EndIf;
		
		If NOT Common.SeparatedDataUsageAvailable() Then
			
			SetPrivilegedMode(True);
			Run = SessionParameters.ClientParametersAtServer.Get("StartInfobaseUpdate");
			SetPrivilegedMode(False);
			
			If Run <> Undefined AND CanUpdateInfobase() Then
				Return True;
			EndIf;
		EndIf;
	EndIf;
	
	Return False;
	
EndFunction

// Runs noninteractive infobase update.
//
// Parameters:
// 
//  UpdateParameters - Structure - properties:
//    * ExceptionOnCannotLockIB - Boolean - if False, then in case of unsuccessful attempt to set an 
//                 exclusive mode, an exception is not called and a "ExclusiveModeSettingError" 
//                 string returns.
// 
//    * OnClientStart - Boolean - False by default. If set to True, the application operating 
//                 parameters are not updated, because on client start they are updated first 
//                 (before user authorization and infobase update).
//                 This parameter is used to optimize the client start mode by avoiding repeated 
//                 updates of application operating parameters.
//                 In case of external call (for example, in external connection session), 
//                 application operating parameters must be updated before the infobase update can proceed.
//    * Restart             - Boolean - (return value) restart is necessary in some OnClientStart 
//                                  cases (for example, in case the subordinate DIB node is being 
//                                  returned to the database configuration). See the common module 
//                                  DataExchangeServer procedure.
//                                  SynchronizeWithoutInfobaseUpdate.
//    * IBLockSet - Structure - for the list of properties, see InfobaseLock(). 
//    * InBackground                     - Boolean - if an infobase update is executed on a 
//                 background, the True value should be passed, otherwise it will be False.
//    * ExecuteDeferredHandlers - Boolean - if True, then a deferred update will be executed in the 
//                 default update mode. Only for a client-server mode.
// 
// Returns:
//  String -  update hadlers execution flag:
//           "Done", "NotRequired", "ExclusiveModeSettingError".
//
Function UpdateInfobase(UpdateParameters) Export
	
	If Not UpdateParameters.OnClientStart Then
		Try
			InformationRegisters.ApplicationParameters.ImportUpdateApplicationParameters();
		Except
			WriteError(DetailErrorDescription(ErrorInfo()));
			Raise;
		EndTry;
	EndIf;
	
	DeferredUpdateMode = DeferredUpdateMode(UpdateParameters);
	
	// Checking whether the configuration name is changed.
	
	DataUpdateMode = DataUpdateMode();
	MetadataVersion = Metadata.Version;
	If IsBlankString(MetadataVersion) Then
		MetadataVersion = "0.0.0.0";
	EndIf;
	DataVersion = IBVersion(Metadata.Name);
	
	// Before infobase update.
	//
	If Common.SubsystemExists("StandardSubsystems.SaaS.IBVersionUpdateSaaS") Then
		ModuleInfobaseUpdateInternalSaaS = Common.CommonModule("InfobaseUpdateInternalSaaS");
		ModuleInfobaseUpdateInternalSaaS.BeforeUpdateInfobase();
		
		// Enabling privileged mode to allow infobase update SaaS, in case the data area administrator 
		// accesses the area before it is fully updated.
		If Common.DataSeparationEnabled() AND Common.SeparatedDataUsageAvailable() Then
			SetPrivilegedMode(True);
		EndIf;
		
	EndIf;
	
	// Importing and exporting exchange messages after restart, as configuration changes are received.
	If Common.SubsystemExists("StandardSubsystems.DataExchange") Then
		ModuleDataExchangeServer = Common.CommonModule("DataExchangeServer");
		ModuleDataExchangeServer.BeforeUpdateInfobase(UpdateParameters.OnClientStart, UpdateParameters.Restart);
	EndIf;
		
	If NOT InfobaseUpdate.InfobaseUpdateRequired() Then
		Return "NotRequired";
	EndIf;
	
	If UpdateParameters.InBackground Then
		TimeConsumingOperations.ReportProgress(1);
	EndIf;
	
	SubsystemsDetails  = StandardSubsystemsCached.SubsystemsDetails();
	For each SubsystemName In SubsystemsDetails.Order Do
		SubsystemDetails = SubsystemsDetails.ByNames.Get(SubsystemName);
		If NOT ValueIsFilled(SubsystemDetails.MainServerModule) Then
			Continue;
		EndIf;
		Module = Common.CommonModule(SubsystemDetails.MainServerModule);
		Module.BeforeUpdateInfobase();
	EndDo;
	InfobaseUpdateOverridable.BeforeUpdateInfobase();
	
	// Verifying rights to update the infobase.
	If NOT CanUpdateInfobase() Then
		Message = NStr("ru = 'Недостаточно прав для обновления версии программы.'; en = 'Insufficient rights for upgrading to a new application version.'; pl = 'Nie posiadasz wystarczających uprawnień, aby zaktualizować wersję aplikacji.';de = 'Unzureichende Rechte zum Aktualisieren der Anwendungsversion.';ro = 'Drepturi insuficiente pentru actualizarea versiunii aplicației.';tr = 'Uygulama sürümünü güncellemek için yetersiz haklar.'; es_ES = 'Insuficientes derechos para actualizar la versión de la aplicación.'");
		WriteError(Message);
		Raise Message;
	EndIf;
	
	If DataUpdateMode = "MigrationFromAnotherApplication" Then
		Message = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Изменилось имя конфигурации на ""%1"".
			           |Будет выполнен переход с другой программы.'; 
			           |en = 'The configuration name changed to ""%1"".
			           |Migration from another application will be performed.'; 
			           |pl = 'Zmiana nazwy konfiguracji na %1.
			           |Zostaniesz przeniesiony z innej aplikacji.';
			           |de = 'Ändern Sie den Konfigurationsnamen in %1. 
			           |Sie werden von einer anderen Anwendung weitergeleitet.';
			           |ro = 'Numele configurației s-a modificat în ""%1"".
			           |Va fi executat tranzitul din altă aplicație.';
			           |tr = 'Yapılandırma adını değiştirin%1.
			           | Başka bir uygulamadan aktarılacaksınız.'; 
			           |es_ES = 'Cambiar el nombre de la configuración para %1.
			           |Usted estará transitado desde otra aplicación.'"),
			Metadata.Name);
	ElsIf DataUpdateMode = "VersionUpdate" Then
		Message = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Изменился номер версии конфигурации: с ""%1"" на ""%2"".
			           |Будет выполнено обновление информационной базы.'; 
			           |en = 'The configuration version number changed from %1 to %2.
			           |Infobase update will be performed.'; 
			           |pl = 'Zmiana numeru wersji konfiguracji: z %1 na %2.
			           |Zostanie przeprowadzona aktualizacja bazy informacyjnej.';
			           |de = 'Nummer der Konfigurationsversion: von %1 bis %2.
			           |Infobase-Update wird durchgeführt.';
			           |ro = 'Numărul versiunii configurației s-a modificat: din ""%1"" în ""%2"".
			           |Va fi executată actualizarea bazei de informații.';
			           |tr = 'Yapılandırma versiyonunun numarası: %2 ile 
			           | arasında %1 veri tabanı güncellenecektir.'; 
			           |es_ES = 'Número de la versión de la configuración: desde %1 hasta %2.
			           |Actualización de la infobase se realizará.'"),
			DataVersion, MetadataVersion);
	Else
		Message = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Выполняется начальное заполнение данных до версии ""%1"".'; en = 'Populating initial data for version %1.'; pl = 'Trwa początkowe wypełnienie danych do wersji ""%1"".';de = 'Die erste Datenpopulation bis zur Version ""%1"" ist in Bearbeitung.';ro = 'Are loc completarea inițială a datelor până la versiunea ""%1"".';tr = '""%1"" Sürümüne kadar ilk veri doldurulması devam ediyor.'; es_ES = 'Población de datos iniciales hasta la versión ""%1"" está en progreso.'"),
			MetadataVersion);
	EndIf;
	WriteInformation(Message);
	
	// Locking the infobase.
	LockAlreadySet = UpdateParameters.IBLockSet <> Undefined 
		AND UpdateParameters.IBLockSet.Use;
	If LockAlreadySet Then
		UpdateIterations = UpdateIterations();
		IBLock = UpdateParameters.IBLockSet;
	Else
		IBLock = Undefined;
		UpdateIterations = LockIB(IBLock, UpdateParameters.ExceptionOnCannotLockIB);
		If IBLock.Error <> Undefined Then
			Return IBLock.Error;
		EndIf;
	EndIf;
	
	SeamlessUpdate = IBLock.NonexclusiveUpdate;
	
	Try
		
		If DataUpdateMode = "MigrationFromAnotherApplication" Then
			
			MigrateFromAnotherApplication();
			
			DataUpdateMode = DataUpdateMode();
			SeamlessUpdate = False;
			UpdateIterations = UpdateIterations();
		EndIf;
		
	Except
		If Not LockAlreadySet Then
			UnlockIB(IBLock);
		EndIf;
		Raise;
	EndTry;
	
	If UpdateParameters.InBackground Then
		TimeConsumingOperations.ReportProgress(10);
	EndIf;
	
	If Not Common.DataSeparationEnabled()
		Or Common.SeparatedDataUsageAvailable() Then
		GenerateDeferredUpdateHandlerList(UpdateIterations);
	EndIf;
	
	Parameters = New Structure;
	Parameters.Insert("HandlerExecutionProgress", HandlerCountForCurrentVersion(UpdateIterations, DeferredUpdateMode));
	Parameters.Insert("NonexclusiveUpdate", SeamlessUpdate);
	Parameters.Insert("InBackground", UpdateParameters.InBackground);
	Parameters.Insert("OnClientStart", UpdateParameters.OnClientStart);
	Parameters.Insert("DeferredUpdateMode", DeferredUpdateMode);
	
	Message = NStr("ru = 'Для обновления программы на новую версию будут выполнены обработчики: %1'; en = 'The following handlers will be executed during the application update: %1'; pl = 'Aby zaktualizować aplikację do nowej wersji, zostaną wykonane następujące procedury obsługi: %1';de = 'Um die Anwendung auf eine neue Version zu aktualisieren, werden die folgenden Anwender ausgeführt: %1';ro = 'Pentru actualizarea aplicației cu versiunea nouă, se vor executa următorii handleri: %1';tr = 'Uygulamayı yeni sürüme güncellemek için aşağıdaki işleyiciler çalıştırılacak:%1'; es_ES = 'Para actualizar la aplicación a una nueva versión, los siguientes manipuladores se ejecutarán: %1'");
	Message = StringFunctionsClientServer.SubstituteParametersToString(Message, Parameters.HandlerExecutionProgress.TotalHandlerCount);
	WriteInformation(Message);
	
	ClientLaunchParameter = SessionParameters.ClientParametersAtServer.Get("LaunchParameter");
	DeferredUpdateDebug = StrFind(Lower(ClientLaunchParameter), Lower("DeferredUpdateDebug")) > 0;
	
	Try
		
		// Executing all update handlers for configuration subsystems.
		For Each UpdateIteration In UpdateIterations Do
			UpdateIteration.CompletedHandlers = ExecuteUpdateIteration(UpdateIteration, Parameters);
		EndDo;
		
		// Clearing a list of new subsystems.
		UpdateInfo = InfobaseUpdateInfo();
		UpdateInfo.NewSubsystems = New Array;
		FillDataForParallelDeferredUpdate(UpdateInfo, Parameters);
		WriteInfobaseUpdateInfo(UpdateInfo);
		
		// During file infobase updates, the deferred handlers are executed in the primary update cycle.
		If DeferredUpdateMode = "Exclusive"
		   AND Not DeferredUpdateDebug Then
			
			ExecuteDeferredUpdateNow(Parameters);
		EndIf;
		
	Except
		If Not LockAlreadySet Then
			UnlockIB(IBLock);
		EndIf;
		Raise;
	EndTry;
	
	// Disabling the exclusive mode.
	If Not LockAlreadySet Then
		UnlockIB(IBLock);
	EndIf;

	Message = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("ru = 'Обновление информационной базы на версию ""%1"" выполнено успешно.'; en = 'The infobase was updated to version %1.'; pl = 'Aktualizacja bazy informacyjnej do wersji ""%1"" zakończona pomyślnie.';de = 'Infobase wurde erfolgreich auf Version ""%1"" aktualisiert.';ro = 'Baza de informații este actualizată cu succes cu versiunea ""%1"".';tr = 'Veritabanı ""%1"" sürümüne başarıyla güncellendi.'; es_ES = 'Infobase se ha actualizado con éxito a la versión ""%1"".'"), MetadataVersion);
	WriteInformation(Message);
	
	OutputUpdatesDetails = (DataUpdateMode <> "InitialFilling");
	
	RefreshReusableValues();
	
	// After infobase update.
	//
	ExecuteHandlersAfterInfobaseUpdate(
		UpdateIterations,
		Constants.WriteIBUpdateDetailsToEventLog.Get(),
		OutputUpdatesDetails,
		SeamlessUpdate);
	
	InfobaseUpdateOverridable.AfterUpdateInfobase(
		DataVersion,
		MetadataVersion,
		UpdateIterations,
		OutputUpdatesDetails,
		Not SeamlessUpdate);
	
	// Exporting the exchange message after restart, due to configuration changes received
	If Common.SubsystemExists("StandardSubsystems.DataExchange") Then
		ModuleDataExchangeServer = Common.CommonModule("DataExchangeServer");
		ModuleDataExchangeServer.AfterUpdateInfobase();
	EndIf;
	
	// Scheduling execution of the deferred update handlers (for client-server infobases).
	If DeferredUpdateMode <> Undefined
		AND DeferredUpdateMode = "Deferred" Then
		ScheduleDeferredUpdate();
	EndIf;
	
	DefineUpdateDetailsDisplay(OutputUpdatesDetails);
	
	// Clearing unsuccessful configuration update status in case of manual (without using scripts) update completion
	If Common.SubsystemExists("StandardSubsystems.ConfigurationUpdate") Then
		ModuleSoftwareUpdate = Common.CommonModule("ConfigurationUpdate");
		ModuleSoftwareUpdate.AfterUpdateInfobase();
	EndIf;
	
	RefreshReusableValues();
	
	SetPrivilegedMode(True);
	ClientLaunchParameter = SessionParameters.ClientParametersAtServer.Get("LaunchParameter");
	If StrFind(Lower(ClientLaunchParameter), Lower("StartInfobaseUpdate")) > 0 Then
		StandardSubsystemsServer.RegisterPriorityDataChangeForSubordinateDIBNodes();
	EndIf;
	SetPrivilegedMode(False);
	
	If DeferredUpdateMode = "Exclusive"
	   AND Not DeferredUpdateDebug
	   AND Common.SubsystemExists("StandardSubsystems.AccessManagement") Then
		
		ModuleAccessControlInternal = Common.CommonModule("AccessManagementInternal");
		If ModuleAccessControlInternal.LimitAccessAtRecordLevelUniversally(True) Then
			ModuleAccessControlInternal.UpdateAccess();
		EndIf;
	EndIf;
	
	SetInfobaseUpdateStartup(False);
	SessionParameters.IBUpdateInProgress = False;
	
	Return "Success";
	
EndFunction

// Get configuration or parent configuration (library) version that is stored in the infobase.
// 
//
// Parameters:
//  LibraryID - String - a configuration name or a library ID.
//  GetSharedDataVersion - Boolean - if you set a True value, a version in shared data will return 
//                                       for SaaS.
//
// Returns:
//   String   - version.
//
// Usage example:
//   IBСonfigurationVersion = IBVersion(Metadata.Name);
//
Function IBVersion(Val LibraryID, Val GetSharedDataVersion = False) Export
	
	SetSafeModeDisabled(True);
	SetPrivilegedMode(True);
	
	StandardProcessing = True;
	Result = "";
	
	If Common.SubsystemExists("StandardSubsystems.SaaS.IBVersionUpdateSaaS") Then
		
		ModuleInfobaseUpdateInternalSaaS = Common.CommonModule("InfobaseUpdateInternalSaaS");
		ModuleInfobaseUpdateInternalSaaS.OnDetermineIBVersion(LibraryID, GetSharedDataVersion,
			StandardProcessing, Result);
		
	EndIf;
	
	If StandardProcessing Then
		
		Query = New Query;
		Query.Text =
		"SELECT
		|	SubsystemsVersions.Version
		|FROM
		|	InformationRegister.SubsystemsVersions AS SubsystemsVersions
		|WHERE
		|	SubsystemsVersions.SubsystemName = &SubsystemName";
		
		Query.SetParameter("SubsystemName", LibraryID);
		ValueTable = Query.Execute().Unload();
		Result = "";
		If ValueTable.Count() > 0 Then
			Result = TrimAll(ValueTable[0].Version);
		EndIf;
		
		If IsBlankString(Result) Then
			
			// Support of update from SSL version 2.1.2.
			QueryText =
				"SELECT
				|	DeleteSubsystemVersions.Version
				|FROM
				|	InformationRegister.DeleteSubsystemVersions AS DeleteSubsystemVersions
				|WHERE
				|	DeleteSubsystemVersions.SubsystemName = &SubsystemName
				|	AND DeleteSubsystemVersions.DataArea = &DataArea";
			Query = New Query(QueryText);
			Query.SetParameter("SubsystemName", LibraryID);
			If Common.DataSeparationEnabled() Then
				Query.SetParameter("DataArea", -1);
			Else
				Query.SetParameter("DataArea", 0);
			EndIf;
			ValueTable = Query.Execute().Unload();
			If ValueTable.Count() > 0 Then
				Result = TrimAll(ValueTable[0].Version);
			EndIf;
			
		EndIf;
		
	EndIf;
	
	Return ?(IsBlankString(Result), "0.0.0.0", Result);
	
EndFunction

// Writes a configuration or parent configuration (library) version to the infobase.
//
// Parameters:
//  LibraryID - String - configuration (library) name or parent configuration (library) name,
//  VersionNumber             - String - version number.
//  IsMainConfiguration - Boolean - a flag indicating that the LibraryID corresponds to the configuration name.
//
Procedure SetIBVersion(Val LibraryID, Val VersionNumber, Val IsMainConfiguration) Export
	
	StandardProcessing = True;
	
	If Common.SubsystemExists("StandardSubsystems.SaaS.IBVersionUpdateSaaS") Then
		
		ModuleInfobaseUpdateInternalSaaS = Common.CommonModule("InfobaseUpdateInternalSaaS");
		ModuleInfobaseUpdateInternalSaaS.OnSetIBVersion(LibraryID, VersionNumber, StandardProcessing);
		
	EndIf;
	
	If Not StandardProcessing Then
		Return;
	EndIf;
		
	RecordSet = InformationRegisters.SubsystemsVersions.CreateRecordSet();
	RecordSet.Filter.SubsystemName.Set(LibraryID);
	
	NewRecord = RecordSet.Add();
	NewRecord.SubsystemName = LibraryID;
	NewRecord.Version = VersionNumber;
	NewRecord.IsMainConfiguration = IsMainConfiguration;
	
	RecordSet.Write();
	
EndProcedure

// Records details for deferred handlers registration on the exchange plan.
//
Procedure CanlcelDeferredUpdateHandlersRegistration(SubsystemName = Undefined, Value = True) Export
	
	StandardProcessing = True;
	
	If Common.SubsystemExists("StandardSubsystems.SaaS.IBVersionUpdateSaaS") Then
		ModuleInfobaseUpdateInternalSaaS = Common.CommonModule("InfobaseUpdateInternalSaaS");
		ModuleInfobaseUpdateInternalSaaS.OnMarkDeferredUpdateHandlersRegistration(SubsystemName, Value, StandardProcessing);
	EndIf;
	
	If Not StandardProcessing Then
		Return;
	EndIf;
	
	RecordSet = InformationRegisters.SubsystemsVersions.CreateRecordSet();
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
	
EndProcedure

// Returns an infobase data update mode.
// Can only be called before the infobase update starts (returns VersionUpdate otherwise).
// 
// Returns:
//   String   - "InitialFilling" in case it is a first opening of an empty database (data area);
//              "VersionUpdate" in case it is a first start after an infobase configuration update.
//              "MigrationFromAnotherApplication" in case it is a first start after an infobase 
//              configuration update where a base configuration name was changed.
//
Function DataUpdateMode() Export
	
	SetPrivilegedMode(True);
	
	StandardProcessing = True;
	DataUpdateMode = "";
	
	BaseConfigurationName = Metadata.Name;
	SubsystemsDetails  = StandardSubsystemsCached.SubsystemsDetails();
	For each SubsystemName In SubsystemsDetails.Order Do
		SubsystemDetails = SubsystemsDetails.ByNames.Get(SubsystemName);
		If NOT ValueIsFilled(SubsystemDetails.MainServerModule) Then
			Continue;
		EndIf;
		
		If SubsystemDetails.Name <> BaseConfigurationName Then
			Continue;
		EndIf;
		
		Module = Common.CommonModule(SubsystemDetails.MainServerModule);
		Module.OnDefineDataUpdateMode(DataUpdateMode, StandardProcessing);
	EndDo;
	
	If NOT StandardProcessing Then
		CommonClientServer.CheckParameter("OnDefineDataUpdateMode", "DataUpdateMode",
			DataUpdateMode, Type("String"));
		Message = StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = 'Недопустимое значение параметра %1 в %2. 
			|Ожидалось: %3; передано значение: %4 (тип %5).'; 
			|en = 'Invalid value of the %1 parameter in %2.
			|Expected value: %3, passed value: %4 (type: %5).'; 
			|pl = 'Niepoprawna wartość %1 parametru w %2. 
			|Oczekiwana: %3; wysłana wartość: %4 (typ %5).';
			|de = 'Ungültiger Wert des %1 Parameters in %2. 
			|Erwartet: %3; gesendeter Wert: %4 (%5Typ).';
			|ro = 'Valoare invalidă a parametrului %1 în %2. 
			|Așteptat: %3; valoarea trimisă: %4 (tipul %5).';
			|tr = '%1''deki %2 parametrenin geçersiz değeri.
			|Beklenen %5 ; gönderilen değer %3 (%4 tür).'; 
			|es_ES = 'Valor inválido del %1 parámetro en %2.
			|Esperado: %3; valor enviado: %4 (%5 tipo).'"),
			"DataUpdateMode", "OnDefineDataUpdateMode", 
			NStr("ru = 'НачальноеЗаполнение, ОбновлениеВерсии или ПереходСДругойПрограммы'; en = 'InitialFilling, VersionUpdate, or MigrationFromAnotherApplication'; pl = 'InitialFilling, VersionUpdate lub MigrationFromAnotherApplication';de = 'InitialFilling, VersionUpdate oder MigrationFromAnotherApplication';ro = 'InitialFilling, VersionUpdate sau TransferFromAnotherApplication';tr = 'İlk Doldurma, Sürüm Güncelleme veya Başka Bir Uygulamadan Aktarım'; es_ES = 'InitialFilling, VersionUpdate o TransferFromAnotherApplication'"), 
			DataUpdateMode, TypeOf(DataUpdateMode));
		CommonClientServer.Validate(DataUpdateMode = "InitialFilling" 
			Or DataUpdateMode = "VersionUpdate" Or DataUpdateMode = "MigrationFromAnotherApplication", Message);
		Return DataUpdateMode;
	EndIf;

	Result = Undefined;
	If Common.SubsystemExists("StandardSubsystems.SaaS.IBVersionUpdateSaaS") Then
		ModuleInfobaseUpdateInternalSaaS = Common.CommonModule("InfobaseUpdateInternalSaaS");
		ModuleInfobaseUpdateInternalSaaS.OnDetermineFirstSignInToDataArea(StandardProcessing, Result);
	EndIf;
	
	If NOT StandardProcessing Then
		Return ?(Result = True, "InitialFilling", "VersionUpdate");
	EndIf;
	
	Return DataUpdateModeInLocalMode();
	
EndFunction

// For internal use.
Function HandlerFIlteringParameters() Export
	
	Result = New Structure;
	Result.Insert("GetSeparated", False);
	Result.Insert("UpdateMode", "Exclusive");
	Result.Insert("IncludeFirstExchangeInDIB", False);
	Result.Insert("FirstExchangeInDIB", False);
	Return Result;
	
EndFunction

// For internal use.
Function UpdateInIntervalHandlers(Val InitialHandlerTable, Val VersionFrom, Val VersionTo, 
	Val HandlerFIlteringParameters = Undefined) Export
	
	FilterParameters = HandlerFIlteringParameters;
	If FilterParameters = Undefined Then
		FilterParameters = HandlerFIlteringParameters();
	EndIf;
	// Adding numbers to a table, to be sorted by adding order.
	AllHandlers = InitialHandlerTable.Copy();
	
	AllHandlers.Columns.Add("SerialNumber", New TypeDescription("Number", New NumberQualifiers(10, 0)));
	For Index = 0 To AllHandlers.Count() - 1 Do
		HandlerRow = AllHandlers[Index];
		HandlerRow.SerialNumber = Index + 1;
	EndDo;
	
	SelectNewSubsystemHandlers(AllHandlers);
	
	// Preparing parameters
	SelectSeparatedHandlers = True;
	SelectSharedHandlers = True;
	
	If Common.DataSeparationEnabled() Then
		If FilterParameters.GetSeparated Then
			SelectSharedHandlers = False;
		Else
			If Common.SeparatedDataUsageAvailable() Then
				SelectSharedHandlers = False;
			Else
				SelectSeparatedHandlers = False;
			EndIf;
		EndIf;
	EndIf;
	
	// Generating a handler tree.
	Schema = GetCommonTemplate("GetUpdateHandlersTree");
	Schema.Parameters.Find("SelectSeparatedHandlers").Value = SelectSeparatedHandlers;
	Schema.Parameters.Find("SelectSharedHandlers").Value = SelectSharedHandlers;
	Schema.Parameters.Find("VersionFrom").Value = VersionFrom;
	Schema.Parameters.Find("VersionTo").Value = VersionTo;
	Schema.Parameters.Find("VersionWeightFrom").Value = VersionWeight(Schema.Parameters.Find("VersionFrom").Value);
	Schema.Parameters.Find("VersionWeightTo").Value = VersionWeight(Schema.Parameters.Find("VersionTo").Value);
	Schema.Parameters.Find("NonexclusiveUpdate").Value = (FilterParameters.UpdateMode = "Seamless");
	Schema.Parameters.Find("DeferredUpdate").Value = (FilterParameters.UpdateMode = "Deferred");
	If FilterParameters.IncludeFirstExchangeInDIB Then
		Schema.Parameters.Find("FirstExchangeInDIB").Value = FilterParameters.FirstExchangeInDIB;
		Schema.Parameters.Find("IsDIBWithFilter").Value = StandardSubsystemsCached.DIBUsed("WithFilter");
	EndIf;
	
	Composer = New DataCompositionTemplateComposer;
	Template = Composer.Execute(Schema, Schema.DefaultSettings, , , Type("DataCompositionValueCollectionTemplateGenerator"));
	
	CompositionProcessor = New DataCompositionProcessor;
	CompositionProcessor.Initialize(Template, New Structure("Handlers", AllHandlers), , True);
	
	OutputProcessor = New DataCompositionResultValueCollectionOutputProcessor;
	OutputProcessor.SetObject(New ValueTree);
	
	HandlersToExecute = OutputProcessor.Output(CompositionProcessor);
	
	HandlersToExecute.Columns.Version.Name = "RegistrationVersion";
	HandlersToExecute.Columns.VersionGroup.Name = "Version";
	
	// Sorting handlers by SharedData flag.
	For Each Version In HandlersToExecute.Rows Do
		Version.Rows.Sort("SharedData Desc", True);
	EndDo;
	
	Return HandlersToExecute;
	
EndFunction

// For internal use.
//
Function UpdateRequired(Val MetadataVersion, Val DataVersion) Export
	Return NOT IsBlankString(MetadataVersion) AND DataVersion <> MetadataVersion;
EndFunction

// For internal use.
//
Function DeferredUpdateHandlersRegistered() Export
	
	SetSafeModeDisabled(True);
	SetPrivilegedMode(True);
	
	If Common.DataSeparationEnabled()
		AND Not Common.SeparatedDataUsageAvailable() Then
		Return True; // When in shared mode, the deferred update is not performed.
	EndIf;
	
	StandardProcessing = True;
	Result = "";
	If Common.SubsystemExists("StandardSubsystems.SaaS.IBVersionUpdateSaaS") Then
		ModuleInfobaseUpdateInternalSaaS = Common.CommonModule("InfobaseUpdateInternalSaaS");
		ModuleInfobaseUpdateInternalSaaS.OnCheckDeferredUpdateHandlersRegistration(Result, StandardProcessing);
	EndIf;
	
	If Not StandardProcessing Then
		Return Result;
	EndIf;
	
	Query = New Query;
	Query.Text =
		"SELECT
		|	SubsystemsVersions.SubsystemName
		|FROM
		|	InformationRegister.SubsystemsVersions AS SubsystemsVersions
		|WHERE
		|	SubsystemsVersions.DeferredHandlersRegistrationCompleted = FALSE";
	
	Result = Query.Execute().Unload();
	Return Result.Count() = 0;
	
EndFunction

// Returns True when a user enabled showing the change log and new changes are available.
// 
//
Function ShowChangeHistory() Export
	
	UpdateInfo = InfobaseUpdateInfo();
	If UpdateInfo.OutputUpdatesDetails = False Then
		Return False;
	EndIf;
	
	If Not AccessRight("SaveUserData", Metadata) Then
		// Hiding "what's new in this version" from anonymous users.
		Return False;
	EndIf;
	
	If Not AccessRight("View", Metadata.CommonForms.ApplicationReleaseNotes) Then
		Return False;
	EndIf;
	
	If Common.DataSeparationEnabled()
		AND Users.IsFullUser(, True) Then
		Return False;
	EndIf;
	
	OutputChangeDetailsForAdministrator = Common.CommonSettingsStorageLoad("IBUpdate", "OutputChangeDescriptionForAdministrator",,, UserName());
	If OutputChangeDetailsForAdministrator = True Then
		Return True;
	EndIf;
	
	LatestVersion = SystemChangesDisplayLastVersion();
	If LatestVersion = Undefined Then
		Return True;
	EndIf;
	
	Sections = UpdateDetailsSections();
	
	If Sections = Undefined Then
		Return False;
	EndIf;
	
	Return GetLaterVersions(Sections, LatestVersion).Count() > 0;
	
EndFunction

// Validates status of deferred update handlers.
//
Function UncompletedHandlersStatus(OnUpdate = False) Export
	
	UpdateInfo = InfobaseUpdateInfo();
	
	If OnUpdate Then
		DataVersion = IBVersion(Metadata.Name);
		DataVersionWithoutBuildNumber = CommonClientServer.ConfigurationVersionWithoutBuildNumber(DataVersion);
		MetadataVersionWithoutBuildNumber = CommonClientServer.ConfigurationVersionWithoutBuildNumber(Metadata.Version);
		IdenticalSubrevisions = (DataVersionWithoutBuildNumber = MetadataVersionWithoutBuildNumber);
		
		If DataVersion = "0.0.0.0" Or IdenticalSubrevisions Then
			// Can update on build level even if any deferred update handlers are not completed.
			// 
			Return "";
		EndIf;
		
		HandlerTreeVersion = UpdateInfo.HandlerTreeVersion;
		If HandlerTreeVersion <> "" AND CommonClientServer.CompareVersions(HandlerTreeVersion, DataVersion) > 0 Then
			// If an error occurs in the main update loop, do not check the deferred handler tree on restart as 
			// it will contain uncompleted handlers for the current version.
			// 
			Return "";
		EndIf;
	EndIf;
	
	HasHandlersWithErrors = False;
	HasUncompletedHandlers = False;
	HasPausedHandlers = False;
	For Each TreeRowLibrary In UpdateInfo.HandlersTree.Rows Do
		For Each TreeRowVersion In TreeRowLibrary.Rows Do
			For Each Handler In TreeRowVersion.Rows Do
				If Handler.Status = "Error" Then
					// If any handlers completed with errors are found, the loop continues to ensure that all handlers 
					// are completed.
					HasHandlersWithErrors = True;
				ElsIf Handler.Status <> "Completed" Then
					HasUncompletedHandlers = True;
					Break;
				ElsIf Handler.Status = "Paused" Then
					HasPausedHandlers = True;
				EndIf;
			EndDo;
		EndDo;
	EndDo;
	
	If HasUncompletedHandlers Then
		Return "UncompletedStatus";
	ElsIf HasHandlersWithErrors Then
		Return "ErrorStatus";
	ElsIf HasPausedHandlers Then
		Return "SuspendedStatus";
	Else
		Return "";
	EndIf;
	
EndFunction

// Executes all deferred update procedures in a single-call cycle.
//
Procedure ExecuteDeferredUpdateNow(UpdateParameters = Undefined) Export
	
	UpdateInfo = InfobaseUpdateInfo();
	
	If UpdateInfo.DeferredUpdateEndTime <> Undefined Then
		Return;
	EndIf;

	If UpdateInfo.DeferredUpdateStartTime = Undefined Then
		UpdateInfo.DeferredUpdateStartTime = CurrentSessionDate();
	EndIf;
	
	If TypeOf(UpdateInfo.SessionNumber) <> Type("ValueList") Then
		UpdateInfo.SessionNumber = New ValueList;
	EndIf;
	UpdateInfo.SessionNumber.Add(InfoBaseSessionNumber());
	WriteInfobaseUpdateInfo(UpdateInfo);
	
	HandlersExecutedEarlier = True;
	While HandlersExecutedEarlier Do
		HandlersExecutedEarlier = ExecuteDeferredUpdateHandler(UpdateInfo, UpdateParameters);
	EndDo;
	
	WriteInfobaseUpdateInfo(UpdateInfo);
	
EndProcedure

// For internal use.
Function AddClientParametersOnStart(Parameters) Export
	
	Parameters.Insert("MainConfigurationDataVersion", IBVersion(Metadata.Name));
	
	// Checking whether the application run will be continued.
	IsCallBeforeStart = Parameters.RetrievedClientParameters <> Undefined;
	ErrorDescription = InfobaseLockedForUpdate(, IsCallBeforeStart);
	If ValueIsFilled(ErrorDescription) Then
		Parameters.Insert("InfobaseLockedForUpdate", ErrorDescription);
		// Application will be closed.
		Return False;
	EndIf;
	
	If MustCheckLegitimateSoftware() Then
		Parameters.Insert("CheckLegitimateSoftware");
	EndIf;
	
	Return True;
	
EndFunction

// Used for testing purposes.
Function MustCheckLegitimateSoftware() Export
	
	If NOT Common.SubsystemExists("StandardSubsystems.SoftwareLicenseCheck") Then
		Return False;
	EndIf;
	
	If StandardSubsystemsServer.IsBaseConfigurationVersion() Then
		Return False;
	EndIf;
	
	If Common.DataSeparationEnabled() Then
		Return False;
	EndIf;
	
	If Common.IsSubordinateDIBNode() Then
		Return False;
	EndIf;
	
	LegitimateVersion = "";
	
	If DataUpdateModeInLocalMode() = "InitialFilling" Then
		LegitimateVersion = Metadata.Version;
	Else
		UpdateInfo = InfobaseUpdateInfo();
		LegitimateVersion = UpdateInfo.LegitimateVersion;
	EndIf;
	
	Return LegitimateVersion <> Metadata.Version;
	
EndFunction

// Returns a string containing infobase lock reasons in case the current user has insufficient 
// rights to update the infobase; returns an empty string otherwise.
//
// Parameters:
//  ForPrivilegedMode - Boolean - if set to False, the current user rights check will ignore 
//                                    privileged mode.
//  
// Returns:
//  String - blank string if the infobase is not locked, or lock reason message otherwise.
// 
Function InfobaseLockedForUpdate(ForPrivilegedMode = True, OnStart = Undefined) Export
	
	Message = "";
	
	CurrentIBUser = InfoBaseUsers.CurrentUser();
	
	// Administration rights are sufficient to access a locked infobase.
	If ForPrivilegedMode Then
		HasAdministrationRight = AccessRight("Administration", Metadata);
	Else
		HasAdministrationRight = AccessRight("Administration", Metadata, CurrentIBUser);
	EndIf;
	
	MessageForSystemAdministrator =
		NStr("ru = 'Вход в программу временно невозможен в связи с обновлением на новую версию.
		           |Для завершения обновления версии программы требуются административные права
		           |(роли ""Администратор системы"" и ""Полные права"").'; 
		           |en = 'The application is temporarily unavailable due to version update.
		           |To complete the version update, administrative rights are required
		           |(""System administrator"" and ""Full access"" roles).'; 
		           |pl = 'Wejście do programu tymczasowo jest niemożliwe w związku z aktualizacją do nowej wersji.
		           |Dla zakończenia aktualizacji wersji programu wymagane są prawa administracyjne
		           |(role ""Администратор системы"" i Полные права"").';
		           |de = 'Die Anmeldung am Programm ist aufgrund eines Upgrades auf eine neue Version vorübergehend nicht möglich.
		           |Für den Abschluss des Upgrades sind Administratorrechte erforderlich
		           |(die Rollen ""Systemadministrator"" und ""Vollrechte"").';
		           |ro = 'Intrarea în aplicație este temporar imposibilă din cauza actualizării cu versiunea nouă.
		           |Pentru a finaliza actualizarea versiunii aplicației aveți nevoie de drepturile de administrator
		           |(rolurile ”Administrator de sistem” și ”Drepturi depline”).';
		           |tr = 'Uygulamaya  giriş, yeni sürüme güncellemeden dolayı geçici olarak yapılamaz.
		           |  Uygulama sürümü güncellemesini tamamlamak için bir yönetici olmanız  gerekir
		           | (""Sistem yöneticisi"" ve ""Tam haklar rolleri"").'; 
		           |es_ES = 'Entrada en la aplicación es temporalmente imposible debido a la actualización para la nueva versión.
		           |Para terminar la actualización de la versión de la aplicación se requieren los derechos de administrador
		           |(""Administrador del sistema"" y ""Derechos completos"").'");
	
	SetPrivilegedMode(True);
	DataSeparationEnabled = Common.DataSeparationEnabled();
	SeparatedDataUsageAvailable = Common.SeparatedDataUsageAvailable();
	SetPrivilegedMode(False);
	
	If SharedInfobaseDataUpdateRequired() Then
		
		MessageForDataAreaAdministrator =
			NStr("ru = 'Вход в приложение временно невозможен в связи с обновлением на новую версию.
			           |Обратитесь к администратору сервиса за подробностями.'; 
			           |en = 'The application is temporarily unavailable due to version update.
			           |For details, contact the service administrator.'; 
			           |pl = 'Dostęp do aplikacji jest tymczasowo niemożliwy z powodu aktualizacji do nowej wersji.
			           |Aby uzyskać więcej informacji, skontaktuj się z administratorem serwisu.';
			           |de = 'Die Anmeldung am Programm ist aufgrund eines Upgrades auf eine neue Version vorübergehend nicht möglich.
			           |Wenden Sie sich für weitere Informationen an den Service-Administrator.';
			           |ro = 'Accesul la aplicație este temporar imposibil din cauza actualizării cu versiunea nouă.
			           |Contactați administratorul de servicii pentru detalii.';
			           |tr = 'Uygulamaya giriş, yeni sürüme yapılan güncellemeden dolayı geçici olarak yapılamaz.
			           | Ayrıntılar için yöneticiye başvurun.'; 
			           |es_ES = 'Es imposible temporalmente entrar en el programa a causa de actualización a la nueva versión.
			           |Diríjase al administrador para la información.'");
		
		If SeparatedDataUsageAvailable Then
			Message = MessageForDataAreaAdministrator;
			
		ElsIf NOT CanUpdateInfobase(ForPrivilegedMode, False) Then
			
			If HasAdministrationRight Then
				Message = MessageForSystemAdministrator;
			Else
				Message = MessageForDataAreaAdministrator;
			EndIf;
		EndIf;
		
		Return Message;
	EndIf;
	
	// No message is sent to the service administrator.
	If DataSeparationEnabled AND Not SeparatedDataUsageAvailable Then
		Return "";
	EndIf;
		
	If CanUpdateInfobase(ForPrivilegedMode, True) Then
		If InfobaseUpdate.InfobaseUpdateRequired()
			AND OnStart = True Then
			Result = UpdateStartMark();
			If Not Result.CanUpdate Then
				Message = NStr("ru = 'Вход в программу временно невозможен в связи с обновлением на новую версию.
					|Обновление уже выполняется:
					|  компьютер - %1
					|  пользователь - %2
					|  сеанс - %3
					|  начат - %4
					|  приложение - %5'; 
					|en = 'The application is temporarily unavailable due to version update.
					|Now updating:
					|  computer: %1
					|  user: %2
					|  session: %3
					|  start time: %4
					|  application: %5'; 
					|pl = 'Wejście do programu tymczasowo jest niemożliwe w związku z aktualizacją do nowej wersji.
					|Aktualizacja już jest wykonywana:
					|  komputer - %1
					|  użytkownik - %2
					|  sesja - %3
					|  rozpoczęta - %4
					|  aplikacja - %5';
					|de = 'Die Anmeldung am Programm ist aufgrund eines Upgrades auf eine neue Version vorübergehend nicht möglich.
					|Die Aktualisierung ist bereits im Gange:
					| Computer - %1
					|  Benutzer - %2
					|  Sitzung - %3
					|  Start - %4
					|Anwendung - %5';
					|ro = 'Intrarea în aplicație este temporar imposibilă din cauza actualizării cu versiunea nouă.
					|Actualizarea deja se execută
					|  computer - %1
					|  utilizator - %2
					|  sesiunea - %3
					|  începută - %4
					|  aplicația - %5';
					|tr = 'Programa giriş geçici olarak yeni sürüme yükseltme nedeniyle mümkün değildir.
					|Güncelleme zaten çalışıyor: 
					|bilgisayar-%1
					|kullanıcı-%2
					|oturum-%3
					|başlat-%4
					|uygulama -%5'; 
					|es_ES = 'Es imposible temporalmente entrar en el programa a causa de actualización a la nueva versión.
					|La actualización ya está ejecutando:
					| ordenador - %1
					| usuario - %2
					| sesión - %3
					| empezada - %4
					| aplicación - %5'");
				
				Message = StringFunctionsClientServer.SubstituteParametersToString(Message,
					Result.UpdateSession.ComputerName,
					Result.UpdateSession.User,
					Result.UpdateSession.SessionNumber,
					Result.UpdateSession.SessionStarted,
					Result.UpdateSession.ApplicationName);
				Return Message;
			EndIf;
		EndIf;
		Return "";
	EndIf;
	
	RepeatedDataExchangeMessageImportRequiredBeforeStart = False;
	If Common.IsSubordinateDIBNode()
	   AND Common.SubsystemExists("StandardSubsystems.DataExchange") Then
		ModuleDataExchangeInternal = Common.CommonModule("DataExchangeInternal");
		RepeatedDataExchangeMessageImportRequiredBeforeStart = 
			ModuleDataExchangeInternal.RetryDataExchangeMessageImportBeforeStart();
	EndIf;
	
	// In this situation, start is not prevented.
	If Not InfobaseUpdate.InfobaseUpdateRequired()
	   AND Not MustCheckLegitimateSoftware()
	   AND Not RepeatedDataExchangeMessageImportRequiredBeforeStart Then
		Return "";
	EndIf;
	
	// In all other situations, start is prevented.
	If HasAdministrationRight Then
		Return MessageForSystemAdministrator;
	EndIf;

	If DataSeparationEnabled Then
		// Message to service user.
		Message =
			NStr("ru = 'Вход в приложение временно невозможен в связи с обновлением на новую версию.
			           |Обратитесь к администратору сервиса за подробностями.'; 
			           |en = 'The application is temporarily unavailable due to version update.
			           |For details, contact the service administrator.'; 
			           |pl = 'Dostęp do aplikacji jest tymczasowo niemożliwy z powodu aktualizacji do nowej wersji.
			           |Aby uzyskać więcej informacji, skontaktuj się z administratorem serwisu.';
			           |de = 'Die Anmeldung am Programm ist aufgrund eines Upgrades auf eine neue Version vorübergehend nicht möglich.
			           |Wenden Sie sich für weitere Informationen an den Service-Administrator.';
			           |ro = 'Accesul la aplicație este temporar imposibil din cauza actualizării cu versiunea nouă.
			           |Contactați administratorul de servicii pentru detalii.';
			           |tr = 'Uygulamaya giriş, yeni sürüme yapılan güncellemeden dolayı geçici olarak yapılamaz.
			           | Ayrıntılar için yöneticiye başvurun.'; 
			           |es_ES = 'Es imposible temporalmente entrar en el programa a causa de actualización a la nueva versión.
			           |Diríjase al administrador para la información.'");
	Else
		// Message to local mode user.
		Message =
			NStr("ru = 'Вход в программу временно невозможен в связи с обновлением на новую версию.
			           |Обратитесь к администратору за подробностями.'; 
			           |en = 'The application is temporarily unavailable due to version update.
			           |For details, contact the service administrator.'; 
			           |pl = 'Wejście do programu tymczasowo jest niemożliwe w związku z aktualizacją do nowej wersji.
			           |Zwróć się do administratora o szczegółach.';
			           |de = 'Die Anmeldung am Programm ist aufgrund eines Upgrades auf eine neue Version vorübergehend nicht möglich.
			           |Wenden Sie sich für weitere Informationen an den Administrator.';
			           |ro = 'Intrarea în aplicație este temporar imposibilă din cauza actualizării cu versiunea nouă.
			           |Contactați administratorul pentru detalii.';
			           |tr = 'Uygulamaya giriş, yeni sürüme yapılan güncellemeden dolayı geçici olarak yapılamaz.
			           | Ayrıntılar için yöneticiye başvurun.'; 
			           |es_ES = 'Es imposible temporalmente entrar en el programa a causa de actualización a la nueva versión.
			           |Diríjase al administrador para la información.'");
	EndIf;
	
	Return Message;
	
EndFunction

// Sets the infobase update start state.
// Privileged mode required.
//
// Parameters:
//  Startup - Boolean - True sets the state, and False clears the state.
//           
//
Procedure SetInfobaseUpdateStartup(Startup) Export
	
	SetPrivilegedMode(True);
	CurrentParameters = New Map(SessionParameters.ClientParametersAtServer);
	
	If Startup = True Then
		CurrentParameters.Insert("StartInfobaseUpdate", True);
		
	ElsIf CurrentParameters.Get("StartInfobaseUpdate") <> Undefined Then
		CurrentParameters.Delete("StartInfobaseUpdate");
	EndIf;
	
	SessionParameters.ClientParametersAtServer = New FixedMap(CurrentParameters);
	
EndProcedure

// Gets infobase update information from the IBUpdateInfo constant.
// 
Function InfobaseUpdateInfo() Export
	
	SetPrivilegedMode(True);
	
	If Common.DataSeparationEnabled()
	   AND Not Common.SeparatedDataUsageAvailable() Then
		
		Return NewUpdateInfo();
	EndIf;
	
	IBUpdateInfo = Constants.IBUpdateInfo.Get().Get();
	If TypeOf(IBUpdateInfo) <> Type("Structure") Then
		Return NewUpdateInfo();
	EndIf;
	If IBUpdateInfo.Count() = 1 Then
		Return NewUpdateInfo();
	EndIf;
		
	IBUpdateInfo = NewUpdateInfo(IBUpdateInfo);
	Return IBUpdateInfo;
	
EndFunction

// Writes update data to the IBUpdateInfo constant.
//
Procedure WriteInfobaseUpdateInfo(Val UpdateInfo) Export
	
	If UpdateInfo = Undefined Then
		NewValue = NewUpdateInfo();
	Else
		NewValue = UpdateInfo;
	EndIf;
	
	ConstantManager = Constants.IBUpdateInfo.CreateValueManager();
	ConstantManager.Value = New ValueStorage(NewValue);
	InfobaseUpdate.WriteData(ConstantManager);
	
EndProcedure

// Writes the duration of the main update cycle to a constant.
//
Procedure WriteUpdateExecutionTime(UpdateStartTime, UpdateEndTime) Export
	
	If Common.DataSeparationEnabled() AND Not Common.SeparatedDataUsageAvailable() Then
		Return;
	EndIf;
	
	UpdateInfo = InfobaseUpdateInfo();
	UpdateInfo.UpdateStartTime = UpdateStartTime;
	UpdateInfo.UpdateEndTime = UpdateEndTime;
	
	TimeInSeconds = UpdateEndTime - UpdateStartTime;
	
	Hours = Int(TimeInSeconds/3600);
	Minutes = Int((TimeInSeconds - Hours * 3600) / 60);
	Seconds = TimeInSeconds - Hours * 3600 - Minutes * 60;
	
	DurationHours = ?(Hours = 0, "", StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = '%1 час'; en = '%1 h'; pl = '%1 g.';de = '%1 Stunde';ro = '%1 h';tr = 'saat%1'; es_ES = '%1 hora'"), Hours));
	DurationMinutes = ?(Minutes = 0, "", StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = '%1 мин'; en = '%1 min'; pl = '%1 min.';de = '%1 min';ro = '%1 min';tr = 'dakika%1'; es_ES = '%1 minuto'"), Minutes));
	DurationSeconds = ?(Seconds = 0, "", StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = '%1 сек'; en = '%1 sec'; pl = '%1 sek.';de = '%1 s';ro = '%1 sec';tr = 'saniye%1'; es_ES = '%1 segundo'"), Seconds));
	UpdateDuration = DurationHours + " " + DurationMinutes + " " + DurationSeconds;
	UpdateInfo.UpdateDuration = TrimAll(UpdateDuration);
	
	WriteInfobaseUpdateInfo(UpdateInfo);
	
EndProcedure

// For internal use only.
Procedure WriteLegitimateSoftwareConfirmation() Export
	
	If Common.DataSeparationEnabled()
	   AND Not Common.SeparatedDataUsageAvailable()
	   Or StandardSubsystemsServer.IsBaseConfigurationVersion() Then
		
		Return;
	EndIf;
	
	UpdateInfo = InfobaseUpdateInfo();
	UpdateInfo.LegitimateVersion = Metadata.Version;
	WriteInfobaseUpdateInfo(UpdateInfo);
	
EndProcedure

// Sets the version change details display flag both for the current version and earlier versions, 
// provided that the flag is not yet set for this user.
// 
//
// Parameters:
//  Username - String - the name of the user to set the flag for.
//   
//
Procedure SetShowDetailsToNewUserFlag(Val Username) Export
	
	If SystemChangesDisplayLastVersion(Username) = Undefined Then
		SetShowDetailsToCurrentVersionFlag(Username);
	EndIf;
	
EndProcedure

// Reregisters the data to be updated in exchange plan.
// InfobaseUpdate, required when importing data from service or exporting data to service.
// 
//
Procedure ReregisterDataForDeferredUpdate() Export
	
	UpdateInfo = InfobaseUpdateInfo();
	LibraryDetailsList    = StandardSubsystemsCached.SubsystemsDetails().ByNames;
	DataToProcess = New Map;
	ParametersInitialized = False;
	
	For Each RowLibrary In UpdateInfo.HandlersTree.Rows Do
		
		If LibraryDetailsList[RowLibrary.LibraryName].DeferredHandlerExecutionMode <> "Parallel" Then
			Continue;
		EndIf;
		
		ParallelSinceVersion = LibraryDetailsList[RowLibrary.LibraryName].ParralelDeferredUpdateFromVersion;
		
		If Not ParametersInitialized Then
			HandlerParametersStructure = InfobaseUpdate.MainProcessingMarkParameters();
			HandlerParametersStructure.ReRegistration = True;
			ParametersInitialized = True;
		EndIf;
		
		For Each VersionRow In RowLibrary.Rows Do
			
			If VersionRow.VersionNumber = "*" Then
				Continue;
			EndIf;
			
			If ValueIsFilled(ParallelSinceVersion)
				AND CommonClientServer.CompareVersions(VersionRow.VersionNumber, ParallelSinceVersion) < 0 Then
				Continue;
			EndIf;
			
			For Each Handler In VersionRow.Rows Do
				
				HandlerParametersStructure.Queue = Handler.DeferredProcessingQueue;
				HandlerParametersStructure.Insert("HandlerData", New Map);
				
				If Handler.Multithreaded Then
					HandlerParametersStructure.SelectionParameters =
						InfobaseUpdate.AdditionalMultithreadProcessingDataSelectionParameters();
				Else
					HandlerParametersStructure.SelectionParameters = Undefined;
				EndIf;
				
				HandlerParameters = New Array;
				HandlerParameters.Add(HandlerParametersStructure);
				Try
					Message = NStr("ru = 'Выполняется процедура заполнения данных
						                   |""%1""
						                   |отложенного обработчика обновления
						                   |""%2"".'; 
						                   |en = 'Executing data population procedure
						                   |%1
						                   |of deferred update handler
						                   |%2.'; 
						                   |pl = 'Jest wykonywana procedura wypełnienia danych
						                   |""%1""
						                   |odroczonego programu przetwarzania aktualizacji
						                   |""%2"".';
						                   |de = 'Der Vorgang zum Ausfüllen der Daten 
						                   |""%1""
						                   | des verzögerten Update-Handlers 
						                   |""%2"" wird durchgeführt.';
						                   |ro = 'Are loc executarea completării datelor
						                   |""%1""
						                   |handlerului de actualizare amânat
						                   |""%2"".';
						                   |tr = '"
"%1Ertelenmiş güncelleme işleyicisinin 
						                   |veri doldurma prosedürü yürütülüyor 
						                   |%2.'; 
						                   |es_ES = 'Se está realizando el procedimiento de relleno de datos
						                   |""%1""
						                   | del procesador aplazado de actualización
						                   |""%2"".'");
					Message = StringFunctionsClientServer.SubstituteParametersToString(Message,
						Handler.UpdateDataFillingProcedure,
						Handler.HandlerName);
					WriteInformation(Message);
					
					Common.ExecuteConfigurationMethod(Handler.UpdateDataFillingProcedure, HandlerParameters);
				Except
					WriteError(StringFunctionsClientServer.SubstituteParametersToString(
						NStr("ru = 'При вызове процедуры заполнения данных
								   |""%1""
								   |отложенного обработчика обновления
								   |""%2""
								   |произошла ошибка:
								   |""%3"".'; 
								   |en = 'Error while calling data population procedure
								   |%1
								   |of deferred update handler
								   |%2.
								   |Error:
								   |%3.'; 
								   |pl = 'Podczas wywołania procedury wypełnienia danych
								   |""%1""
								   |odroczonego programu przetwarzania aktualizacji
								   |""%2""
								   |zaistniał błąd:
								   |""%3"".';
								   |de = 'Beim Aufrufen der Prozedur zum Füllen der Daten
								   |""%1""
								   | des verzögerten Update-Handlers
								   |""%2""
								   | ist ein Fehler aufgetreten:
								   |""%3"".';
								   |ro = 'La apelarea procedurii de completare a datelor
								   |""%1""
								   |handlerului de actualizare amânat
								   |""%2""
								   |s-a produs eroarea:
								   |""%3"".';
								   |tr = 'Ertelenen güncelleştirme işleyicisi "
" %1
								   |veri doldurma %3prosedürü çağrıldığında bir 
								   |
								   |hata oluştu:%2 "
".'; 
								   |es_ES = 'Al llamar el procedimiento del relleno de datos
								   |""%1""
								   | del procesador aplazado de actualización
								   |""%2""
								   |se ha producido un error:
								   |""%3"".'"),
						Handler.UpdateDataFillingProcedure,
						Handler.HandlerName,
						DetailErrorDescription(ErrorInfo())));
					
					Raise;
				EndTry;
				
				DataToProcessDetails = NewDataToProcessDetails(Handler.Multithreaded);
				DataToProcessDetails.HandlerData = HandlerParametersStructure.HandlerData;
				
				If Handler.Multithreaded Then
					DataToProcessDetails.SelectionParameters = HandlerParametersStructure.SelectionParameters;
				EndIf;
				
				DataToProcess.Insert(Handler.HandlerName, DataToProcessDetails);
			EndDo;
		EndDo;
		
	EndDo;
	
	UpdateInfo.DataToProcess = DataToProcess;
	WriteInfobaseUpdateInfo(UpdateInfo);
	
EndProcedure

// Returns parameters of the deferred update handler.
// Checks whether the update handler has saved parameters and returns these parameters.
// 
// 
// Parameters:
//  ID - String, UUID - the name or unique ID of the handler procedure.
//                  
//
// Returns:
//  Structure - saved parameters of the update handler.
//
Function DeferredUpdateHandlerParameters(ID) Export
	UpdateInfo = InfobaseUpdateInfo();
	HandlersTree = UpdateInfo.HandlersTree.Rows;
	
	If TypeOf(ID) = Type("UUID") Then
		UpdateHandler = HandlersTree.Find(ID, "ID", True);
	Else
		UpdateHandler = HandlersTree.Find(ID, "HandlerName", True);
	EndIf;
	
	If UpdateHandler = Undefined Then
		Return Undefined;
	EndIf;
	
	Parameters = UpdateHandler.ExecutionStatistics["HandlerParameters"];
	If Parameters = Undefined Then
		Parameters = New Structure;
	EndIf;
	
	Return Parameters;
EndFunction

// Saves parameters of the deferred update handler.
// 
// Parameters:
//  ID - String, UUID - the name or unique ID of the handler procedure.
//                  
//  Parameters     - Structure - parameters to save.
//
Procedure WriteDeferredUpdateHandlerParameters(ID, Parameters) Export
	UpdateInfo = InfobaseUpdateInfo();
	HandlersTree = UpdateInfo.HandlersTree.Rows;
	
	If TypeOf(ID) = Type("UUID") Then
		UpdateHandler = HandlersTree.Find(ID, "ID", True);
	Else
		UpdateHandler = HandlersTree.Find(ID, "HandlerName", True);
	EndIf;
	
	If UpdateHandler = Undefined Then
		Return;
	EndIf;
	
	UpdateHandler.ExecutionStatistics.Insert("HandlerParameters", Parameters);
	WriteInfobaseUpdateInfo(UpdateInfo);
EndProcedure

// Returns the number of infobase update threads.
//
// If this number is specified in the UpdateThreadsCount command-line parameter, returns the value of the parameter.
// Otherwise, returns the value of the InfobaseUpdateThreadCount constant (if defined).
// Otherwise, returns the default value (see DefaultInfobaseUpdateThreadsCount())
//
// Returns:
//  Number - number of threads.
//
Function InfobaseUpdateThreadCount() Export
	
	If MultithreadUpdateAllowed() Then
		Count = 0;
		ParameterName = "UpdateThreadsCount=";
		Parameters = SessionParameters.ClientParametersAtServer.Get("LaunchParameter");
		ParameterPosition = StrFind(Parameters, ParameterName);
		
		If ParameterPosition > 0 Then
			SeparatorPosition = StrFind(Parameters, ";",, ParameterPosition + StrLen(ParameterName));
			Length = ?(SeparatorPosition > 0, SeparatorPosition, StrLen(Parameters) + 1) - ParameterPosition;
			UpdateThreads = StrSplit(Mid(Parameters, ParameterPosition, Length), "=");
			
			Try
				Count = Number(UpdateThreads[1]);
			Except
				ExceptionText = NStr(
					"ru = 'Параметр запуска программы ""ЧислоПотоковОбновления"" необходимо указать в формате
					|""ЧислоПотоковОбновления=Х"", где ""Х"" - максимальное количество потоков обновления.'; 
					|en = 'Specify the application startup parameter UpdateThreadsCount in the ""UpdateThreadsCount=X"" format,
					|where X is the maximum number of update threads.'; 
					|pl = 'Parametr uruchomienia programu ""ЧислоПотоковОбновления"" należy podać w formacie
					|""ЧислоПотоковОбновления=Х"", gdzie ""Х"" - maksymalna ilość przepływów aktualizacji.';
					|de = 'Der Startparameter des Programms ""AnzahlThreadUpdates"" muss im Format
					| ""AnzahlThreadUpdates=X"" angegeben werden, wobei ""X"" die maximale Anzahl von Update-Threads ist.';
					|ro = 'Parametrul de lansare a programului ""ЧислоПотоковОбновления"" trebuie indicat în formatul
					|""ЧислоПотоковОбновления=Х"", unde ""Х"" este cantitatea maximă a fluxurilor de actualizare.';
					|tr = '""GüncellemeAkışısayısı"" uygulamasının başlatma seçeneği ""GüncelleştirmeAkışıSayısı = X"" 
					|biçiminde belirtilmelidir; burada ""X"" en fazla güncelleme akışı sayısıdır.'; 
					|es_ES = 'Es necesario indicar parámetro de lanzar el programa ""ЧислоПотоковОбновления"" en el formato
					| ""ЧислоПотоковОбновления=X"" donde ""X"" es la cantidad máxima de los flujos de actualización.'");
				Raise ExceptionText;
			EndTry;
		EndIf;
		
		If Count = 0 Then
			Count = Constants.InfobaseUpdateThreadCount.Get();
			
			If Count = 0 Then
				Count = DefaultInfobaseUpdateThreadsCount();
			EndIf;
		EndIf;
		
		Return Count;
	Else
		Return 1;
	EndIf;
	
EndFunction

////////////////////////////////////////////////////////////////////////////////
// Configuration subsystems event handlers.

// See CommonOverridable.OnAddSessionParametersSettingHandlers. 
Procedure OnAddSessionParameterSettingHandlers(Handlers) Export
	
	Handlers.Insert("IBUpdateInProgress", "InfobaseUpdateInternal.SessionParametersSetting");
	Handlers.Insert("UpdateHandlerParameters", "InfobaseUpdateInternal.SessionParametersSetting");
	Handlers.Insert("CanceledTimeConsumingOperations", "TimeConsumingOperations.SessionParametersSetting");
	
EndProcedure

// See CommonOverridable.OnAddRefsSearchExceptions. 
Procedure OnAddReferenceSearchExceptions(RefSearchExclusions) Export
	
	RefSearchExclusions.Add(Metadata.InformationRegisters.DataProcessedInMasterDIBNode.FullName());

EndProcedure

// See MonitoringCenterOverridable.OnCollectConfigurationStatisticsParameters. 
Procedure OnCollectConfigurationStatisticsParameters() Export
	
	If Not Common.SubsystemExists("StandardSubsystems.MonitoringCenter") Then
		Return;
	EndIf;
	
	ModuleMonitoringCenter = Common.CommonModule("MonitoringCenter");
	
	UpdateInfo = InfobaseUpdateInfo();
	If UpdateInfo.DeferredUpdateCompletedSuccessfully <> True Then
		Return; // Getting information only when the deferred update has completed successfully.
	EndIf;
	
	For Each TreeRowLibrary In UpdateInfo.HandlersTree.Rows Do
		For Each TreeRowVersion In TreeRowLibrary.Rows Do
			For Each Handler In TreeRowVersion.Rows Do
				ModuleMonitoringCenter.WriteConfigurationObjectStatistics("DeferredHandlerRunTime." + Handler.HandlerName, Handler.ExecutionStatistics["ExecutionDuration"] / 1000);
			EndDo;
		EndDo;
	EndDo;
	
	StartTime = UpdateInfo.UpdateStartTime;
	EndTime = UpdateInfo.UpdateEndTime;
	
	If ValueIsFilled(StartTime) AND ValueIsFilled(EndTime) Then
		ModuleMonitoringCenter.WriteConfigurationObjectStatistics("HandlersRunTime",
			EndTime - StartTime);
	EndIf;
	
	StartTime = UpdateInfo.DeferredUpdateStartTime;
	EndTime = UpdateInfo.DeferredUpdateEndTime;
	
	If ValueIsFilled(StartTime) AND ValueIsFilled(EndTime) Then
		ModuleMonitoringCenter.WriteConfigurationObjectStatistics("DeferredHandlersRunTime",
			EndTime - StartTime);
	EndIf;
	
EndProcedure

// See StandardSubsystemsServer.OnSendDataToSlave. 
Procedure OnSendDataToSlave(DataItem, ItemSending, InitialImageCreation, Recipient) Export
	
	OnSendSubsystemVersions(DataItem, ItemSending, InitialImageCreation);
	
EndProcedure

// See StandardSubsystemsServer.OnSendDataToMaster. 
Procedure OnSendDataToMaster(DataItem, ItemSending, Recipient) Export
	
	OnSendSubsystemVersions(DataItem, ItemSending);
	
EndProcedure

// See CommonOverridable.OnAddClientParametersOnStart. 
Procedure OnAddClientParametersOnStart(Parameters) Export
	
	Parameters.Insert("InitialDataFilling", DataUpdateMode() = "InitialFilling");
	Parameters.Insert("ShowChangeHistory", ShowChangeHistory());
	
	If Common.DataSeparationEnabled() Then
		Return;
	EndIf;
	HandlersStatus = UncompletedHandlersStatus();
	If HandlersStatus = "" Then
		Return;
	EndIf;
	If HandlersStatus = "ErrorStatus"
		AND Users.IsFullUser(, True) Then
		Parameters.Insert("ShowInvalidHandlersMessage");
	Else
		Parameters.Insert("ShowUncompletedHandlersNotification");
	EndIf;
	
EndProcedure

// See InfobaseUpdateSSL.OnAddUpdateHandlers. 
Procedure OnAddUpdateHandlers(Handlers) Export
	
	If Common.SubsystemExists("StandardSubsystems.SoftwareLicenseCheck") Then
		Handler = Handlers.Add();
		Handler.InitialFilling = True;
		Handler.Procedure = "InfobaseUpdateInternal.WriteLegitimateSoftwareConfirmation";
	EndIf;
	
	Handler = Handlers.Add();
	Handler.Version = "2.1.3.4";
	Handler.Procedure = "InfobaseUpdateInternal.SetReleaseNotesVersion";
	
	Handler = Handlers.Add();
	Handler.Version = "2.1.3.19";
	Handler.Procedure = "InfobaseUpdateInternal.MoveSubsystemVersionsToSharedData";
	Handler.SharedData = True;
	
	Handler = Handlers.Add();
	Handler.Version = "2.2.2.7";
	Handler.Procedure = "InfobaseUpdateInternal.FillAttributeIsMainConfiguration";
	Handler.SharedData = True;
	
	If Not Common.DataSeparationEnabled() Then
		Handler = Handlers.Add();
		Handler.Version = "3.0.2.160";
		Handler.Procedure = "InfobaseUpdateInternal.InstallScheduledJobKey";
		Handler.ExecutionMode = "Seamless";
	EndIf;
	
EndProcedure

// See JobsQueueOverridable.OnGetTemplatesList. 
Procedure OnGetTemplateList(JobTemplates) Export
	
	JobTemplates.Add("DeferredIBUpdate");
	
EndProcedure

// See ToDoListOverridable.OnDetermineToDoListHandlers 
Procedure OnFillToDoList(ToDoList) Export
	
	ModuleToDoListServer = Common.CommonModule("ToDoListServer");
	If Not Users.IsFullUser(, True)
		Or ModuleToDoListServer.UserTaskDisabled("DeferredUpdate") Then
		Return;
	EndIf;
	
	If Common.DataSeparationEnabled() Then
		Return;
	EndIf;
	
	// This procedure is only called when To-do list subsystem is available. Therefore, the subsystem 
	// availability check is redundant.
	Sections = ModuleToDoListServer.SectionsForObject(Metadata.DataProcessors.ApplicationUpdateResult.FullName());
	
	HandlersStatus           = UncompletedHandlersStatus();
	HasHandlersWithErrors      = (HandlersStatus = "ErrorStatus");
	HasUncompletedHandlers = (HandlersStatus = "UncompletedStatus");
	HasPausedHandlers = (HandlersStatus = "SuspendedStatus");
	
	For Each Section In Sections Do
		ID = "DeferredUpdate" + StrReplace(Section.FullName(), ".", "");
		ToDoItem = ToDoList.Add();
		ToDoItem.ID = ID;
		ToDoItem.HasToDoItems      = (HasHandlersWithErrors Or HasUncompletedHandlers Or HasPausedHandlers);
		ToDoItem.Important        = HasHandlersWithErrors;
		ToDoItem.Presentation = NStr("ru = 'Обновление программы не завершено'; en = 'Application update is not completed'; pl = 'Aktualizacja aplikacji nie została zakończona';de = 'Anwendungsupdate ist nicht abgeschlossen';ro = 'Actualizarea aplicației nu este finalizată';tr = 'Uygulama güncellemesi tamamlanmadı'; es_ES = 'Actualización de la aplicación no se ha finalizado'");
		ToDoItem.Form         = "DataProcessor.ApplicationUpdateResult.Form.DeferredIBUpdateProgressIndicator";
		ToDoItem.Owner      = Section;
	EndDo;
	
EndProcedure

// See ReportsOptionsOverridable.CustomizeReportsOptions. 
Procedure OnSetUpReportsOptions(Settings) Export
	ModuleReportsOptions = Common.CommonModule("ReportsOptions");
	ModuleReportsOptions.CustomizeReportInManagerModule(Settings, Metadata.Reports.DeferredUpdateProgress);
EndProcedure

// See StandardSubsystemsServer.ValidateExchangePlanComposition. 
Procedure OnGetExchangePlanInitialImageObjects(Objects) Export
	
	Objects.Add(Metadata.InformationRegisters.SubsystemsVersions);
	
EndProcedure

// Restarts the deferred handlers running in the master node when the first exchange message is 
// received.
//
Procedure OnGetFirstDIBExchangeMessageAfterUpdate() Export
	
	SetPrivilegedMode(True);
	
	FileInfobase = Common.FileInfobase();
	UpdateInfo       = InfobaseUpdateInfo();
	If UpdateInfo.DeferredUpdateCompletedSuccessfully = Undefined
		AND Not FileInfobase Then
		CancelDeferredUpdate();
		FilterParameters = New Structure;
		FilterParameters.Insert("MethodName", "InfobaseUpdateInternal.ExecuteDeferredUpdate");
		FilterParameters.Insert("State", BackgroundJobState.Active);
		BackgroundJobArray = BackgroundJobs.GetBackgroundJobs(FilterParameters);
		If BackgroundJobArray.Count() = 1 Then
			BackgroundJob = BackgroundJobArray[0];
			BackgroundJob.Cancel();
		EndIf;
	EndIf;
	
	UpdateIterations = UpdateIterations();
	GenerateDeferredUpdateHandlerList(UpdateIterations, True);
	ReregisterDataForDeferredUpdate();
	If FileInfobase Then
		ExecuteDeferredUpdateNow();
	Else
		ScheduleDeferredUpdate();
	EndIf;
	
EndProcedure

// Called while executing the update script in procedure ConfigurationUpdate.FinishUpdate().
Procedure AfterUpdateCompletion() Export
	
	WriteLegitimateSoftwareConfirmation();
	
EndProcedure

// See ExportImportDataOverridable.AfterDataImport. 
Procedure AfterImportData(Container) Export
	UpdateInfo = InfobaseUpdateInfo();
	
	If UpdateInfo.DeferredUpdateCompletedSuccessfully <> True Then
		ScheduleDeferredUpdate();
	EndIf;
EndProcedure

#EndRegion

#Region Private

// Returns the flag indicating whether multithread updates are allowed.
// You can enable multithread updates in InfobaseUpdateOverridable.OnDefineSettings().
//
// Returns:
//  Boolean - multithread updates are allowed if True. The default value is False (for backward compatibility).
//
Function MultithreadUpdateAllowed() Export
	
	Parameters = SubsystemSettings();
	Return Parameters.MultiThreadUpdate;
	
EndFunction

// See CommonOverridable.OnAddSessionParametersSettingHandlers. 
Procedure SessionParametersSetting(Val ParameterName, SpecifiedParameters) Export
	
	If ParameterName = "IBUpdateInProgress" Then
		SessionParameters.IBUpdateInProgress = InfobaseUpdate.InfobaseUpdateRequired();
		SpecifiedParameters.Add("IBUpdateInProgress");
	ElsIf ParameterName = "UpdateHandlerParameters" Then
		SessionParameters.UpdateHandlerParameters = New FixedStructure(NewUpdateHandlerParameters());
		SpecifiedParameters.Add("UpdateHandlerParameters");
	EndIf;
	
EndProcedure

Function SubsystemSettings() Export
	
	UncompletedDeferredHandlersMessageParameters = New Structure;
	UncompletedDeferredHandlersMessageParameters.Insert("MessageText", "");
	UncompletedDeferredHandlersMessageParameters.Insert("MessagePicture", Undefined);
	UncompletedDeferredHandlersMessageParameters.Insert("ProhibitContinuation", False);
	
	
	Settings = New Structure;
	Settings.Insert("UpdateResultNotes", "");
	Settings.Insert("ApplicationChangeHistoryLocation", "");
	Settings.Insert("UncompletedDeferredHandlersMessageParameters", UncompletedDeferredHandlersMessageParameters);
	Settings.Insert("MultiThreadUpdate", False);
	Settings.Insert("DefaultInfobaseUpdateThreadsCount", 1);
	
	InfobaseUpdateOverridable.OnDefineSettings(Settings);
	
	Return Settings;
	
EndFunction

// Returns numeric weight coefficient of a version, used to compare and prioritize between versions.
//
// Parameters:
//  Version - String - Version in string format.
//
// Returns:
//  Number - weight of the version.
//
Function VersionWeight(Val Version) Export
	
	If Version = "" Then
		Return 0;
	EndIf;
	
	Return VersionWeightFromStringArray(StrSplit(Version, "."));
	
EndFunction

// For internal use.
//
Function UpdateIteration(ConfigurationOrLibraryName, Version, Handlers, IsMainConfiguration = Undefined) Export
	
	UpdateIteration = New Structure;
	UpdateIteration.Insert("Subsystem",  ConfigurationOrLibraryName);
	UpdateIteration.Insert("Version",      Version);
	UpdateIteration.Insert("IsMainConfiguration", 
		?(IsMainConfiguration <> Undefined, IsMainConfiguration, ConfigurationOrLibraryName = Metadata.Name));
	UpdateIteration.Insert("Handlers", Handlers);
	UpdateIteration.Insert("CompletedHandlers", Undefined);
	UpdateIteration.Insert("MainServerModuleName", "");
	UpdateIteration.Insert("MainServerModule", "");
	UpdateIteration.Insert("PreviousVersion", "");
	Return UpdateIteration;
	
EndFunction

// For internal use.
//
Function UpdateIterations()
	
	BaseConfigurationName = Metadata.Name;
	MainSubsystemUpdateIteration = Undefined;
	
	UpdateIterations = New Array;
	SubsystemsDetails  = StandardSubsystemsCached.SubsystemsDetails();
	For each SubsystemName In SubsystemsDetails.Order Do
		SubsystemDetails = SubsystemsDetails.ByNames.Get(SubsystemName);
		If NOT ValueIsFilled(SubsystemDetails.MainServerModule) Then
			Continue;
		EndIf;
		Module = Common.CommonModule(SubsystemDetails.MainServerModule);
		
		UpdateIteration = UpdateIteration(SubsystemDetails.Name, SubsystemDetails.Version, 
			InfobaseUpdate.NewUpdateHandlerTable(), SubsystemDetails.Name = BaseConfigurationName);
		UpdateIteration.MainServerModuleName = SubsystemDetails.MainServerModule;
		UpdateIteration.MainServerModule = Module;
		UpdateIteration.PreviousVersion = IBVersion(SubsystemDetails.Name);
		UpdateIterations.Add(UpdateIteration);
		
		Module.OnAddUpdateHandlers(UpdateIteration.Handlers);
		
		If SubsystemDetails.Name = BaseConfigurationName Then
			MainSubsystemUpdateIteration = UpdateIteration;
		EndIf;
		
		ValidateHandlerProperties(UpdateIteration);
	EndDo;
	
	If MainSubsystemUpdateIteration = Undefined AND BaseConfigurationName = "StandardSubsystemsLibrary" Then
		MessageText = NStr("ru = 'Файл поставки 1С:Библиотека стандартных подсистем не предназначен для создания
			|информационных баз по шаблону. Перед использованием необходимо
			|ознакомиться с документацией на ИТС (http://its.1c.ru/db/bspdoc)'; 
			|en = 'The 1C:Standard Subsystems Library distribution file is not intended
			|for template-based infobase creation. Before you start using it, 
			|read the documentation available on ITS (http://its.1c.ru/db/bspdoc, in Russian).'; 
			|pl = 'Plik dystrybucji 1C:Standard Subsystems Library nie jest przeznaczony do
			|tworzenia baz informacyjnych opartych na szablonach. Zanim zaczniesz go używać, przeczytaj
			|dokumentację dostępną w ITS (http://its.1c.ru/db/bspdoc, w języku rosyjskim).';
			|de = 'Die Lieferdatei 1C:Bibliothek von Standard-Subsystemen ist nicht für die Erstellung von 
			|Informationsbasen auf einer Vorlage vorgesehen. Vor der Verwendung ist es notwendig,
			|die Dokumentation zum ITS (http://its.1c.ru/db/bspdoc) zu lesen.';
			|ro = 'Fișierul de livrare 1C:Librăria subsistemelor standard nu este destinat pentru crearea
			|bazelor de informații conform șablonului. Înainte de utilizare trebuie să luați
			|cunoștință cu documentația pentru SIT (http://its.1c.ru/db/bspdoc)';
			|tr = '1C:Standart alt sistemler kitaplığı teslimat dosyası, 
			|veri tabanlarını şablondan oluşturmak üzere tasarlanmamıştır. Kullanmadan önce, 
			|ITS belgeleri incelenmelidir (http://its.1c.ru/db/bspdoc)'; 
			|es_ES = 'El archivo de suministro 1C:Biblioteca de los subsistema estándares no está destinado para crear
			|las bases de información por la plantilla. Antes de usar es necesario
			|leer la documentación en ITS (http://its.1c.ru/db/bspdoc)'");
		Raise MessageText;
	EndIf;
	
	Return UpdateIterations;
	
EndFunction

// For internal use.
//
Function ExecuteUpdateIteration(Val UpdateIteration, Val Parameters) Export
	
	LibraryID = UpdateIteration.Subsystem;
	IBMetadataVersion      = UpdateIteration.Version;
	UpdateHandlers   = UpdateIteration.Handlers;
	
	CurrentIBVersion = UpdateIteration.PreviousVersion;
	
	NewIBVersion = CurrentIBVersion;
	MetadataVersion = IBMetadataVersion;
	If IsBlankString(MetadataVersion) Then
		MetadataVersion = "0.0.0.0";
	EndIf;
	
	If CurrentIBVersion <> "0.0.0.0"
		AND Common.DataSeparationEnabled()
		AND Common.SeparatedDataUsageAvailable() Then
		
		// Getting an update plan generated during the shared handler execution phase.
		HandlersToExecute = GetUpdatePlan(LibraryID, CurrentIBVersion, MetadataVersion);
		If HandlersToExecute = Undefined Then
			If UpdateIteration.IsMainConfiguration Then 
				MessageTemplate = NStr("ru = 'Не найден план обновления конфигурации %1 с версии %2 на версию %3'; en = 'Update plan for configuration %1 (version %2 to %3) is not found.'; pl = 'Nie znaleziono planu aktualizacji konfiguracji %1 z wersji %2 do wersji %3';de = 'Aktualisierungsplan der Konfiguration %1 von Version %2 zu Version %3 wurde nicht gefunden';ro = 'Nu a fost găsit planul de actualizare a configurației %1 de la versiunea %2 la versiunea %3';tr = 'Sürümden sürüme yapılandırmanın%1 güncelleme%2 planı bulunamadı%3'; es_ES = 'Plan de actualización de la configuración %1 de la versión %2 a la versión %3 no se ha encontrado'");
			Else
				MessageTemplate = NStr("ru = 'Не найден план обновления библиотеки %1 с версии %2 на версию %3'; en = 'Update plan for library %1 (version %2 to %3) is not found.'; pl = 'Nie znaleziono planu aktualizacji biblioteki %1 z wersji %2 do wersji %3';de = 'Der Aktualisierungsplan der Bibliothek %1 von Version %2 zu Version %3 wurde nicht gefunden';ro = 'Nu a fost găsit planul de actualizare a librăriei %1 de la versiunea %2 la versiunea %3';tr = 'Sürümden sürümüne kütüphanenin %1 güncelleme  %2 planı bulunamadı %3'; es_ES = 'Plan de actualización de la biblioteca %1 de la versión %2 a la versión %3 no se ha encontrado'");
			EndIf;
			Message = StringFunctionsClientServer.SubstituteParametersToString(MessageTemplate, LibraryID, CurrentIBVersion, MetadataVersion);
			WriteInformation(Message);
			
			HandlersToExecute = UpdateInIntervalHandlers(UpdateHandlers, CurrentIBVersion, MetadataVersion);
		EndIf;
	Else
		HandlersToExecute = UpdateInIntervalHandlers(UpdateHandlers, CurrentIBVersion, MetadataVersion);
	EndIf;
	
	DetachUpdateHandlers(LibraryID, HandlersToExecute, MetadataVersion, Parameters.HandlerExecutionProgress);
	
	MandatorySeparatedHandlers = InfobaseUpdate.NewUpdateHandlerTable();
	SourceIBVersion = CurrentIBVersion;
	WriteToLog = Constants.WriteIBUpdateDetailsToEventLog.Get();
	
	For Each Version In HandlersToExecute.Rows Do
		
		If Version.Version = "*" Then
			Message = NStr("ru = 'Выполняются обязательные процедуры обновления информационной базы.'; en = 'Executing mandatory infobase update procedures.'; pl = 'Trwają wymagane procedury aktualizacji bazy informacyjnej.';de = 'Die erforderlichen Verfahren zur Aktualisierung der Infobase sind in Bearbeitung.';ro = 'Are loc executarea procedurilor obligatorii de actualizare a bazei de informații.';tr = 'Gerekli veritabanı güncellemesi prosedürleri devam ediyor.'; es_ES = 'Procedimientos requeridos de la actualización de la infobase están en progreso.'");
		Else
			NewIBVersion = Version.Version;
			If CurrentIBVersion = "0.0.0.0" Then
				Message = NStr("ru = 'Выполняется начальное заполнение данных.'; en = 'Populating data.'; pl = 'Trwa początkowe wypełnienie danych.';de = 'Die anfängliche Datenpopulation ist in Bearbeitung.';ro = 'Completarea inițială a datelor este în curs de desfășurare.';tr = 'İlk veri doldurulması devam ediyor'; es_ES = 'Población de los datos iniciales está en progreso.'");
			ElsIf UpdateIteration.IsMainConfiguration Then 
				Message = StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = 'Выполняется обновление информационной базы с версии %1 на версию %2.'; en = 'Updating infobase version %1 to version %2.'; pl = 'Trwa aktualizacja bazy informacyjnej z wersji %1 do wersji %2.';de = 'Aktualisieren der Infobase von Version %1 zu Version %2.';ro = 'Are loc actualizarea bazei de date de la versiunea %1 la versiunea %2.';tr = 'Veritabanı %1 sürümden %2 sürüme güncelleniyor.'; es_ES = 'Actualizando la infobase de la versión %1 a la versión %2.'"), 
					CurrentIBVersion, NewIBVersion);
			Else
				Message = StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = 'Выполняется обновление данных библиотеки %3 с версии %1 на версию %2.'; en = 'Updating %3 library version %1 to version %2.'; pl = 'Aktualizacja danych biblioteki %3 z wersji %1 do wersji %2.';de = 'Aktualisieren von Daten der Bibliothek %3 von Version %1 zu Version %2.';ro = 'Are loc actualizarea datelor din librăria %3 de la versiunea %1 la versiunea %2.';tr = 'Kütüphane verileri %3 sürümden %1 sürüme güncelleniyor.%2'; es_ES = 'Actualizando los datos de la biblioteca %3 de la versión %1 a la versión %2.'"), 
					CurrentIBVersion, NewIBVersion, LibraryID);
			EndIf;
		EndIf;
		WriteInformation(Message);
		
		For Each Handler In Version.Rows Do
			
			HandlerParameters = Undefined;
			If Handler.RegistrationVersion = "*" Then
				
				If Handler.HandlerManagement Then
					HandlerParameters = New Structure;
					HandlerParameters.Insert("SeparatedHandlers", MandatorySeparatedHandlers);
				EndIf;
				
				If Handler.ExclusiveMode = True Or Handler.ExecutionMode = "Exclusive" Then
					If Parameters.NonexclusiveUpdate Then
						// Checks are performed in CanExecuteNonexclusiveUpdate(). For these handlers, the update is only 
						// performed in case of regular update.
						Continue;
					EndIf;
					
					If HandlerParameters = Undefined Then
						HandlerParameters = New Structure;
					EndIf;
					HandlerParameters.Insert("ExclusiveMode", True);
				EndIf;
			EndIf;
			
			AdditionalParameters = New Structure;
			AdditionalParameters.Insert("WriteToLog", WriteToLog);
			AdditionalParameters.Insert("LibraryID", LibraryID);
			AdditionalParameters.Insert("HandlerExecutionProgress", Parameters.HandlerExecutionProgress);
			AdditionalParameters.Insert("InBackground", Parameters.InBackground);
			
			ExecuteUpdateHandler(Handler, HandlerParameters, AdditionalParameters);
		EndDo;
		
		If Version.Version = "*" Then
			Message = NStr("ru = 'Выполнены обязательные процедуры обновления информационной базы.'; en = 'Mandatory infobase update procedures are completed.'; pl = 'Żądane procedury aktualizacji bazy informacyjnej zostały przeprowadzone.';de = 'Erforderliche Prozeduren der Infobase-Aktualisierung werden durchgeführt.';ro = 'Au fost executate procedurile necesare pentru actualizarea bazei de date.';tr = 'Gerekli veritabanı güncellemesi prosedürleri gerçekleştirilir.'; es_ES = 'Procedimientos requeridos de la actualización de la infobase se han realizado.'");
		Else
			If UpdateIteration.IsMainConfiguration Then 
				Message = StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = 'Выполнено обновление информационной базы с версии %1 на версию %2.'; en = 'Infobase update from version %1 to version %2 is completed.'; pl = 'Baza informacyjna została zaktualizowana z wersji %1 do wersji %2.';de = 'Infobase-Update von Version %1 zu Version %2 ist abgeschlossen.';ro = 'Actualizarea bazei de date de la versiunea %1 la versiunea %2 este finalizată.';tr = 'Veritabanın %1 sürümden %2 sürüme  güncellemesi tamamlandı.'; es_ES = 'Actualización de la infobase de la versión %1 a la versión %2 se ha finalizado.'"), 
					CurrentIBVersion, NewIBVersion);
			Else
				Message = StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = 'Выполнено обновление данных библиотеки %3 с версии %1 на версию %2.'; en = 'The update of %3 library from version %1 to version %2 is completed.'; pl = 'Dane biblioteki %3 zostały zaktualizowane z wersji %1 do wersji %2.';de = 'Daten der Bibliothek %3 werden von Version %1 zu Version %2 aktualisiert.';ro = 'Actualizarea datelor librăriei %3 de la versiunea %1 la versiunea %2 este executată.';tr = 'Kütüphane verileri %3 sürümden%2 sürüme %1 güncellendi.'; es_ES = 'Datos de la biblioteca %3 se han actualizado de la versión %1 a la versión %2.'"), 
					CurrentIBVersion, NewIBVersion, LibraryID);
			EndIf;
		EndIf;
		WriteInformation(Message);
		
		If Version.Version <> "*" Then
			// Setting infobase version number.
			SetIBVersion(LibraryID, NewIBVersion, UpdateIteration.IsMainConfiguration);
			CurrentIBVersion = NewIBVersion;
		EndIf;
		
	EndDo;
	
	// Setting infobase version number.
	If IBVersion(LibraryID) <> IBMetadataVersion Then
		SetIBVersion(LibraryID, IBMetadataVersion, UpdateIteration.IsMainConfiguration);
	EndIf;
	
	If CurrentIBVersion <> "0.0.0.0" Then
		
		If Common.SubsystemExists("StandardSubsystems.SaaS.IBVersionUpdateSaaS") Then
			
			ModuleInfobaseUpdateInternalSaaS = Common.CommonModule("InfobaseUpdateInternalSaaS");
			ModuleInfobaseUpdateInternalSaaS.GenerateDataAreaUpdatePlan(LibraryID, UpdateHandlers,
				MandatorySeparatedHandlers, SourceIBVersion, IBMetadataVersion);
			
		EndIf;
		
	EndIf;
	
	Return HandlersToExecute;
	
EndFunction

// Verifies whether the current user has sufficient rights to update an infobase.
Function CanUpdateInfobase(ForPrivilegedMode = True, SeparatedData = Undefined) Export
	
	CheckSystemAdministrationRights = True;
	
	If SeparatedData = Undefined Then
		SeparatedData = NOT Common.DataSeparationEnabled()
			OR Common.SeparatedDataUsageAvailable();
	EndIf;
	
	If Common.DataSeparationEnabled()
	   AND SeparatedData Then
		
		If NOT Common.SeparatedDataUsageAvailable() Then
			Return False;
		EndIf;
		CheckSystemAdministrationRights = False;
	EndIf;
	
	Return Users.IsFullUser(
		, CheckSystemAdministrationRights, ForPrivilegedMode);
	
EndFunction

// For internal use.
//
Function UpdateInfobaseInBackground(UUIDOfForm, IBLock) Export
	
	// Run the background job
	IBUpdateParameters = New Structure;
	IBUpdateParameters.Insert("ExceptionOnCannotLockIB", False);
	IBUpdateParameters.Insert("IBLock", IBLock);
	IBUpdateParameters.Insert("ClientParametersAtServer", SessionParameters.ClientParametersAtServer);
	
	// Enabling exclusive mode before starting the update procedure in background
	Try
		LockIB(IBUpdateParameters.IBLock, False);
	Except
		ErrorInformation = ErrorInfo();
		
		Result = New Structure;
		Result.Insert("Status",    "Error");
		Result.Insert("IBLock", IBUpdateParameters.IBLock);
		Result.Insert("BriefErrorPresentation", BriefErrorDescription(ErrorInformation));
		Result.Insert("DetailedErrorPresentation", DetailErrorDescription(ErrorInformation));
		
		Return Result;
	EndTry;
	
	IBUpdateParameters.Insert("InBackground", Not IBUpdateParameters.IBLock.DebugMode);
	
	If Not IBUpdateParameters.InBackground Then
		IBUpdateParameters.Delete("ClientParametersAtServer");
	EndIf;
	
	ExecutionParameters = TimeConsumingOperations.BackgroundExecutionParameters(UUIDOfForm);
	ExecutionParameters.WaitForCompletion = 0;
	ExecutionParameters.BackgroundJobDescription = NStr("ru = 'Фоновое обновление информационной базы'; en = 'Background infobase update'; pl = 'Aktualizacja bazy informacyjnej w tle';de = 'Hintergrund-Update der Infobase';ro = 'Actualizarea de fundal a bazei de date';tr = 'Veritabanın arka plan güncellemesi'; es_ES = 'Actualización del fondo de la infobase'");
	
	Result = TimeConsumingOperations.ExecuteInBackground("InfobaseUpdateInternal.RunInfobaseUpdateInBackground",
		IBUpdateParameters, ExecutionParameters);
	
	Result.Insert("IBLock", IBUpdateParameters.IBLock);
	
	// Unlocking the infobase if the infobase update has completed.
	If Result.Status <> "Running" Then
		UnlockIB(IBUpdateParameters.IBLock);
	EndIf;
	
	Return Result;
	
EndFunction

// Starts infobase update as a time-consuming operation.
Procedure RunInfobaseUpdateInBackground(IBUpdateParameters, StorageAddress) Export
	
	If IBUpdateParameters.InBackground Then
		SessionParameters.ClientParametersAtServer = IBUpdateParameters.ClientParametersAtServer;
	EndIf;
	
	ErrorInformation = Undefined;
	Try
		UpdateParameters = UpdateParameters();
		UpdateParameters.ExceptionOnCannotLockIB = IBUpdateParameters.ExceptionOnCannotLockIB;
		UpdateParameters.OnClientStart = True;
		UpdateParameters.Restart = False;
		UpdateParameters.IBLockSet = IBUpdateParameters.IBLock;
		UpdateParameters.InBackground = IBUpdateParameters.InBackground;
		
		Result = UpdateInfobase(UpdateParameters);
	Except
		ErrorInformation = ErrorInfo();
		// Preparing to open the form for data resynchronization before startup with two options, 
		// "Synchronize and continue" and "Continue".
		If Common.SubsystemExists("StandardSubsystems.DataExchange")
		   AND Common.IsSubordinateDIBNode() Then
			ModuleDataExchangeServer = Common.CommonModule("DataExchangeServer");
			ModuleDataExchangeServer.EnableDataExchangeMessageImportRecurrenceBeforeStart();
		EndIf;
	EndTry;
	
	If ErrorInformation <> Undefined Then
		UpdateResult = New Structure;
		UpdateResult.Insert("BriefErrorPresentation", BriefErrorDescription(ErrorInformation));
		UpdateResult.Insert("DetailedErrorPresentation", DetailErrorDescription(ErrorInformation));
	ElsIf Not IBUpdateParameters.InBackground Then
		UpdateResult = Result;
	Else
		UpdateResult = New Structure;
		UpdateResult.Insert("ClientParametersAtServer", SessionParameters.ClientParametersAtServer);
		UpdateResult.Insert("Result", Result);
	EndIf;
	PutToTempStorage(UpdateResult, StorageAddress);
	
EndProcedure

// For internal use.
//
Function LockIB(IBLock, ExceptionOnCannotLockIB)
	
	UpdateIterations = Undefined;
	If IBLock = Undefined Then
		IBLock = IBLock();
	EndIf;
	
	IBLock.Use = True;
	If Common.DataSeparationEnabled() Then
		IBLock.DebugMode = False;
	Else
		IBLock.DebugMode = Common.DebugMode();
	EndIf;
	
	If Common.SubsystemExists("StandardSubsystems.SaaS.IBVersionUpdateSaaS") Then
		ModuleInfobaseUpdateInternalSaaS = Common.CommonModule("InfobaseUpdateInternalSaaS");
		IBLock.RecordKey = ModuleInfobaseUpdateInternalSaaS.LockDataAreaVersions();
	EndIf;
	
	UpdateIterations = UpdateIterations();
	IBLock.NonexclusiveUpdate = False;
	
	If IBLock.DebugMode Then
		Return UpdateIterations;
	EndIf;
	
	// Enabling exclusive mode for the infobase update purpose
	ErrorInformation = Undefined;
	Try
		If NOT ExclusiveMode() Then
			SetExclusiveMode(True);
		EndIf;
		Return UpdateIterations;
	Except
		If CanExecuteSeamlessUpdate(UpdateIterations) Then
			IBLock.NonexclusiveUpdate = True;
			Return UpdateIterations;
		EndIf;
		ErrorInformation = ErrorInfo();
	EndTry;
	
	// Processing a failed attempt to enable the exclusive mode
	Message = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("ru = 'Невозможно выполнить обновление информационной базы:
			|- Невозможно установить монопольный режим
			|- Версия конфигурации не предусматривает обновление без установки монопольного режима
			|
			|Подробности ошибки:
			|%1'; 
			|en = 'Cannot update the infobase:
			|- Cannot switch to exclusive mode.
			|- The configuration version does not support update in nonexclusive mode.
			|
			|Error details:
			|%1'; 
			|pl = 'Nie można zaktualizować bazy informacyjnej:
			|- Nie można ustawić
			|trybu wyłączności - Wersja konfiguracji nie zawiera aktualizacji ustawień
			|trybu
			| wyłączności 
			|Więcej o błędzie: %1';
			|de = 'Infobase kann nicht aktualisiert werden:
			|- Es kann kein 
			|exklusiver Modus eingestellt werden - Die Konfigurationsversion enthält kein Update, ohne
			| einen
			| exklusiven Modus
			|einzustellen Mehr über den Fehler: %1';
			|ro = 'Nu puteți actualiza baza de informații:
			|- Regimul monopol nu poate fi instalat
			|- Versiunea configurației nu presupune actualizarea fără setarea regimului monopol
			|
			|Mai multe despre eroare:
			|%1';
			|tr = 'Veritabanı güncellenemedi: 
			|- Özel bir mod 
			|belirlenemedi - Yapılandırma  sürümü, ayarları olmayan%1 modu güncellemeyi
			| içermiyor 
			|Hata hakkında daha  fazla bilgi:
			|'; 
			|es_ES = 'No se puede actualizar la infobase:
			|- No se puede establecer un
			|modo exclusivo - Versión de la configuración no incluye la actualización sin configurar
			|un
			|modo exclusivo
			|Más sobre el error: %1 '"),
		BriefErrorDescription(ErrorInformation));
	
	WriteError(Message);
	
	If Common.SubsystemExists("StandardSubsystems.SaaS.IBVersionUpdateSaaS") Then
		ModuleInfobaseUpdateInternalSaaS = Common.CommonModule("InfobaseUpdateInternalSaaS");
		ModuleInfobaseUpdateInternalSaaS.UnlockDataAreaVersions(IBLock.RecordKey);
	EndIf;
	
	If Not ExceptionOnCannotLockIB
	   AND Common.FileInfobase()
	   AND Common.SubsystemExists("StandardSubsystems.UserSessionsCompletion") Then
		
		ClientLaunchParameter = SessionParameters.ClientParametersAtServer.Get("LaunchParameter");
		If StrFind(ClientLaunchParameter, "ScheduledJobsDisabled") = 0 Then
			IBLock.Error = "LockScheduledJobsExecution";
		Else
			IBLock.Error = "ExclusiveModeSettingError";
		EndIf;
	EndIf;
	
	Raise Message;
	
EndFunction

// For internal use.
//
Procedure UnlockIB(IBLock) Export
	
	If IBLock.DebugMode Then
		Return;
	EndIf;
		
	If ExclusiveMode() Then
		While TransactionActive() Do
			RollbackTransaction();
		EndDo;
		
		SetExclusiveMode(False);
	EndIf;
	
	If Common.SubsystemExists("StandardSubsystems.SaaS.IBVersionUpdateSaaS") Then
		ModuleInfobaseUpdateInternalSaaS = Common.CommonModule("InfobaseUpdateInternalSaaS");
		ModuleInfobaseUpdateInternalSaaS.UnlockDataAreaVersions(IBLock.RecordKey);
	EndIf;
	
EndProcedure

// For internal use.
//
Function IBLock()
	
	Result = New Structure;
	Result.Insert("Use", False);
	Result.Insert("Error", Undefined);
	Result.Insert("NonexclusiveUpdate", Undefined);
	Result.Insert("RecordKey", Undefined);
	Result.Insert("DebugMode", Undefined);
	Return Result;
	
EndFunction

// For internal use.
//
Function UpdateParameters() Export
	
	Result = New Structure;
	Result.Insert("ExceptionOnCannotLockIB", True);
	Result.Insert("OnClientStart", False);
	Result.Insert("Restart", False);
	Result.Insert("IBLockSet", Undefined);
	Result.Insert("InBackground", False);
	Result.Insert("ExecuteDeferredHandlers", False);
	Return Result;
	
EndFunction

// For internal use.
//
Function NewApplicationMigrationHandlerTable()
	
	Handlers = New ValueTable;
	Handlers.Columns.Add("PreviousConfigurationName",	New TypeDescription("String", New StringQualifiers(0)));
	Handlers.Columns.Add("Procedure",					New TypeDescription("String", New StringQualifiers(0)));
	Return Handlers;
	
EndFunction

// For internal use.
//
Function ApplicationMigrationHandlers(PreviousConfigurationName) 
	
	MigrationHandlers = NewApplicationMigrationHandlerTable();
	BaseConfigurationName = Metadata.Name;
	
	SubsystemsDetails  = StandardSubsystemsCached.SubsystemsDetails();
	For each SubsystemName In SubsystemsDetails.Order Do
		SubsystemDetails = SubsystemsDetails.ByNames.Get(SubsystemName);
		If NOT ValueIsFilled(SubsystemDetails.MainServerModule) Then
			Continue;
		EndIf;
		
		If SubsystemDetails.Name <> BaseConfigurationName Then
			Continue;
		EndIf;
		
		Module = Common.CommonModule(SubsystemDetails.MainServerModule);
		Module.OnAddApplicationMigrationHandlers(MigrationHandlers);
	EndDo;
	
	Filter = New Structure("PreviousConfigurationName", "*");
	Result = MigrationHandlers.FindRows(Filter);
	
	Filter.PreviousConfigurationName = PreviousConfigurationName;
	CommonClientServer.SupplementArray(Result, MigrationHandlers.FindRows(Filter), True);
	
	Return Result;
	
EndFunction

Procedure MigrateFromAnotherApplication()
	
	// Previous name of the configuration to be used as migration source.
	Query = New Query;
	Query.Text = 
	"SELECT TOP 1
	|	SubsystemsVersions.SubsystemName AS SubsystemName,
	|	SubsystemsVersions.Version AS Version
	|FROM
	|	InformationRegister.SubsystemsVersions AS SubsystemsVersions
	|WHERE
	|	SubsystemsVersions.IsMainConfiguration = TRUE";
	QueryResult = Query.Execute();
	// If the FillAttributeIsMainConfiguration update handler fails for any reason.
	If QueryResult.IsEmpty() Then 
		Return;
	EndIf;
	
	If Common.DataSeparationEnabled() Then
		Raise NStr("ru = 'При работе в модели сервиса переход с другой программы не предусмотрен.'; en = 'Migration from another application is unavailable in SaaS mode.'; pl = 'Podczas pracy w SaaS, przemieszczenie z innej aplikacji nie jest przewidziane.';de = 'Wenn Sie in SaaS arbeiten, ist die Übertragung von einer anderen Anwendung unerwartet.';ro = 'În timpul lucrului în modelul serviciului nu este prevăzută tranziția din alt program.';tr = 'SaaS''de çalışırken, başka bir uygulamadan aktarma beklenmiyor.'; es_ES = 'Trabajando en SaaS, transferencia de otra aplicación es inesperada.'");
	EndIf;
	
	QueryResult = Query.Execute().Unload()[0];
	PreviousConfigurationName = QueryResult.SubsystemName;
	PreviousConfigurationVersion = QueryResult.Version;
	
	Filter = New Structure;
	Filter.Insert("LibraryName", PreviousConfigurationName);
	UpdateInfo = InfobaseUpdateInfo();
	SearchResult = UpdateInfo.HandlersTree.Rows.FindRows(Filter, True);
	For Each FoundRow In SearchResult Do
		FoundRow.LibraryName = Metadata.Name;
	EndDo;
	If SearchResult.Count() > 0 Then
		WriteInfobaseUpdateInfo(UpdateInfo);
	EndIf;
	
	Handlers = ApplicationMigrationHandlers(PreviousConfigurationName);
	
	SubsystemExists = Common.SubsystemExists("StandardSubsystems.AccessManagement");
	// Executing all migration handlers
	For Each Handler In Handlers Do
		
		TransactionActiveAtExecutionStartTime = TransactionActive();
		DisableAccessKeysUpdate(True, SubsystemExists);
		Try
			Common.ExecuteConfigurationMethod(Handler.Procedure);
			DisableAccessKeysUpdate(False, SubsystemExists);
		Except
			
			DisableAccessKeysUpdate(False, SubsystemExists);
			HandlerName = Handler.Procedure;
			WriteError(StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'При вызове обработчика перехода с другой программы
				           |""%1""
				           |произошла ошибка:
				           |""%2"".'; 
				           |en = 'Error while calling the handler of migration from another application
				           |%1:
				           |%2
				           |'; 
				           |pl = 'Podczas wywołania programu przetwarzania przejścia z innego programu
				           |""%1""
				           |zaistniał błąd:
				           |""%2"".';
				           |de = 'Beim Aufruf des Migrationshandlers aus einem anderen Programm
				           |""%1""
				           | ist ein Fehler aufgetreten:
				           |""%2"".';
				           |ro = 'La apelarea handlerului de migrare de la alt program
				           |""%1""
				           |s-a produs eroarea:
				           |""%2"".';
				           |tr = 'Başka bir programdan geçiş işleyicisini çağırdığınızda 
				           |"
" %2bir hata oluştu: 
				           |""%1"".'; 
				           |es_ES = 'Error al llamar al controlador de migración desde otra aplicación
				           |%1:
				           |%2
				           |'"),
				HandlerName,
				DetailErrorDescription(ErrorInfo())));
			
			Raise;
		EndTry;
		ValidateNestedTransaction(TransactionActiveAtExecutionStartTime, Handler.Procedure);
		
	EndDo;
		
	Parameters = New Structure();
	Parameters.Insert("ExecuteUpdateFromVersion", True);
	Parameters.Insert("ConfigurationVersion", Metadata.Version);
	Parameters.Insert("ClearPreviousConfigurationInfo", True);
	OnCompleteApplicationMigration(PreviousConfigurationName, PreviousConfigurationVersion, Parameters);
	
	// Setting current configuration name and version.
	BeginTransaction();
	Try
		If Parameters.ClearPreviousConfigurationInfo Then
			RecordSet = InformationRegisters.SubsystemsVersions.CreateRecordSet();
			RecordSet.Filter.SubsystemName.Set(PreviousConfigurationName);
			RecordSet.Write();
		EndIf;
		
		RecordSet = InformationRegisters.SubsystemsVersions.CreateRecordSet();
		RecordSet.Filter.SubsystemName.Set(Metadata.Name);
		
		ConfigurationVersion = Metadata.Version; 
		If Parameters.ExecuteUpdateFromVersion Then
			ConfigurationVersion = Parameters.ConfigurationVersion;
		EndIf;
		NewRecord = RecordSet.Add();
		NewRecord.SubsystemName = Metadata.Name;
		NewRecord.Version = ConfigurationVersion;
		NewRecord.UpdatePlan = Undefined;
		NewRecord.IsMainConfiguration = True;
		
		RecordSet.Write();
		CommitTransaction();
	Except	
		RollbackTransaction();
		Raise;
	EndTry;
	
	RefreshReusableValues();
	
EndProcedure

Procedure OnCompleteApplicationMigration(PreviousConfigurationName, PreviousConfigurationVersion, Parameters)
	
	ConfigurationName = Metadata.Name;
	SubsystemsDetails  = StandardSubsystemsCached.SubsystemsDetails();
	For each SubsystemName In SubsystemsDetails.Order Do
		SubsystemDetails = SubsystemsDetails.ByNames.Get(SubsystemName);
		If NOT ValueIsFilled(SubsystemDetails.MainServerModule) Then
			Continue;
		EndIf;
		
		If SubsystemDetails.Name <> ConfigurationName Then
			Continue;
		EndIf;
		
		Module = Common.CommonModule(SubsystemDetails.MainServerModule);
		Module.OnCompleteApplicationMigration(PreviousConfigurationName, PreviousConfigurationVersion, Parameters);
	EndDo;
	
EndProcedure

Procedure IBUpdateBeforeRomoveRefObject(Source, Cancel) Export
	// ACC:75-disable checking DataExchange.Import is not required as this event must always be executed 
	// in the process of deferred update execution.
	
	If GetFunctionalOption("DeferredUpdateCompletedSuccessfully")
		Or Not Common.SeparatedDataUsageAvailable() Then
		Return;
	EndIf;
	
	If Metadata.ExchangePlans.InfobaseUpdate.Content.Find(Source.Metadata()) = Undefined Then
		Return;
	EndIf;
	
	Query = New Query;
	Query.Text =
		"SELECT
		|	InfobaseUpdate.Ref AS Ref
		|FROM
		|	ExchangePlan.InfobaseUpdate AS InfobaseUpdate
		|WHERE
		|	InfobaseUpdate.ThisNode = FALSE";
	
	SetPrivilegedMode(True);
	Nodes = Query.Execute().Unload().UnloadColumn("Ref");
	ExchangePlans.DeleteChangeRecords(Nodes, Source);
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Logging the update progress.

// Returns a string constant for generating event log messages.
//
// Returns:
//   Row
//
Function EventLogEvent() Export
	
	Return NStr("ru = 'Обновление информационной базы'; en = 'Infobase update'; pl = 'Aktualizacja bazy informacyjnej';de = 'Infobase-Aktualisierung';ro = 'Actualizați baza de date';tr = 'Veritabanı güncellemesi'; es_ES = 'Actualización de la infobase'", Common.DefaultLanguageCode());
	
EndFunction

// Returns a string constant used to create event log messages describing update handler execution 
// progress.
//
// Returns:
//   Row
//
Function EventLogEventProtocol() Export
	
	Return EventLogEvent() + "." + NStr("ru = 'Протокол выполнения'; en = 'Execution log'; pl = 'Protokół wykonania';de = 'Ausführungsprotokoll';ro = 'Protocol de execuție';tr = 'Yürütme protokolü'; es_ES = 'Protocolo de ejecución'", Common.DefaultLanguageCode());
	
EndFunction

////////////////////////////////////////////////////////////////////////////////
// Update details

// Generates a spreadsheet document containing change description for each version in the Sections 
// version list.
//
Function DocumentUpdateDetails(Val Sections) Export
	
	DocumentUpdateDetails = New SpreadsheetDocument();
	If Sections.Count() = 0 Then
		Return DocumentUpdateDetails;
	EndIf;
	
	UpdateDetailsTemplate = Metadata.CommonTemplates.Find("ApplicationReleaseNotes");
	If UpdateDetailsTemplate <> Undefined Then
		UpdateDetailsTemplate = GetCommonTemplate(UpdateDetailsTemplate);
	Else
		Return New SpreadsheetDocument();
	EndIf;
	
	For Each Version In Sections Do
		
		OutputUpdateDetails(Version, DocumentUpdateDetails, UpdateDetailsTemplate);
		
	EndDo;
	
	Return DocumentUpdateDetails;
	
EndFunction

// Returns an array containing a list of versions later than the last displayed version, provided 
// that change logs are available for these versions.
//
// Returns:
//  Array - contains strings with version numbers.
//
Function NotShownUpdateDetailSections() Export
	
	Sections = UpdateDetailsSections();
	
	LatestVersion = SystemChangesDisplayLastVersion();
	
	If LatestVersion = Undefined Then
		Return New Array;
	EndIf;
	
	Return GetLaterVersions(Sections, LatestVersion);
	
EndFunction

// Sets the version change details display flag both for the current version and earlier versions.
// 
//
// Parameters:
//  Username - String - the name of the user to set the flag for.
//   
//
Procedure SetShowDetailsToCurrentVersionFlag(Val Username = Undefined) Export
	
	Common.CommonSettingsStorageSave("IBUpdate",
		"SystemChangesDisplayLastVersion", Metadata.Version, , Username);
		
	If Username = Undefined AND Users.IsFullUser() Then
		
		Common.CommonSettingsStorageDelete("IBUpdate", "OutputChangeDescriptionForAdministrator", UserName());
		
	EndIf;
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Deferred update mechanism.

// Generates the deferred update handler tree and writes it to the IBUpdateInfo constant.
//
Procedure GenerateDeferredUpdateHandlerList(UpdateIterations, FirstExchangeInDIB = False)
	
	CheckDeferredHandlerIDUniqueness(UpdateIterations);
	
	HandlersTree = PreviousVersionHandlersCompleted(UpdateIterations);
	UpdateInfo = InfobaseUpdateInfo();
	
	Constants.DeferredUpdateCompletedSuccessfully.Set(False);
	// Setting initial field values
	UpdateInfo.Insert("UpdateStartTime");
	UpdateInfo.Insert("UpdateEndTime");
	UpdateInfo.Insert("UpdateDuration");
	UpdateInfo.Insert("DeferredUpdateStartTime");
	UpdateInfo.Insert("DeferredUpdateEndTime");
	UpdateInfo.Insert("SessionNumber", New ValueList());
	UpdateInfo.Insert("UpdateHandlerParameters");
	UpdateInfo.Insert("DeferredUpdateCompletedSuccessfully");
	UpdateInfo.Insert("HandlersTree", New ValueTree());
	UpdateInfo.Insert("OutputUpdatesDetails", False);
	UpdateInfo.Insert("PausedUpdateProcedures", New Array);
	UpdateInfo.Insert("StartedUpdateProcedures", New Array);
	UpdateInfo.Insert("DeferredUpdateManagement", New Structure);
	UpdateInfo.Insert("DataToProcess", New Map);
	UpdateInfo.Insert("CurrentUpdateIteration", 1);
	UpdateInfo.Insert("DeferredUpdatePlan");
	
	LibraryName = "";
	ErrorsText   = "";
	
	LibraryDetailsList = StandardSubsystemsCached.SubsystemsDetails().ByNames;
	
	For each UpdateIteration In UpdateIterations Do
		
		PreviousVersion = ?(FirstExchangeInDIB, "1.0.0.0", UpdateIteration.PreviousVersion);
		LibraryName = UpdateIteration.Subsystem;
		DeferredHandlerExecutionMode = LibraryDetailsList[LibraryName].DeferredHandlerExecutionMode;
		ParallelSinceVersion = LibraryDetailsList[LibraryName].ParralelDeferredUpdateFromVersion;
		
		If FirstExchangeInDIB AND DeferredHandlerExecutionMode = "Sequentially" Then
			Continue;
		EndIf;
		
		FilterParameters = HandlerFIlteringParameters();
		FilterParameters.GetSeparated = True;
		FilterParameters.UpdateMode = "Deferred";
		FilterParameters.IncludeFirstExchangeInDIB = (DeferredHandlerExecutionMode = "Parallel");
		FilterParameters.FirstExchangeInDIB = FirstExchangeInDIB;
		
		HandlersByVersion = UpdateInIntervalHandlers(UpdateIteration.Handlers,
			PreviousVersion, UpdateIteration.Version, FilterParameters);
		If HandlersByVersion.Rows.Count() = 0 Then
			Continue;
		EndIf;
		
		// Adding a library string
		FoundRow = HandlersTree.Rows.Find(LibraryName, "LibraryName");
		If FoundRow <> Undefined Then
			TreeRowLibrary = FoundRow;
		Else
			TreeRowLibrary = HandlersTree.Rows.Add();
			TreeRowLibrary.LibraryName = LibraryName;
		EndIf;
		TreeRowLibrary.Status = "";
		
		For Each VersionRow In HandlersByVersion.Rows Do
			
			If FirstExchangeInDIB
				AND DeferredHandlerExecutionMode = "Parallel"
				AND (VersionRow.Version = "*"
					Or ValueIsFilled(ParallelSinceVersion)
						AND CommonClientServer.CompareVersions(VersionRow.Version, ParallelSinceVersion) < 0) Then
				Continue;
			EndIf;
			
			FoundRow = TreeRowLibrary.Rows.Find(VersionRow.Version, "VersionNumber");
			HasUncompletedHandlers = False;
			If FoundRow <> Undefined Then
				FoundRow.Status = "";
				
				For Each UncompletedHandler In FoundRow.Rows Do
					HasUncompletedHandlers = True;
					UncompletedHandler.AttemptCount = 0;
					UncompletedHandler.ExecutionStatistics = New Map;
				EndDo;
				VersionsTreeRow = FoundRow;
			Else
				VersionsTreeRow = TreeRowLibrary.Rows.Add();
				VersionsTreeRow.VersionNumber   = VersionRow.Version;
				VersionsTreeRow.Status = "";
			EndIf;
			
			ParallelSinceVersionMode = DeferredHandlerExecutionMode = "Parallel" AND ValueIsFilled(ParallelSinceVersion);
			
			For Each Handler In VersionRow.Rows Do
				
				If ParallelSinceVersionMode Then
					If VersionRow.Version = "*" Then
						DeferredHandlerMode = "Sequentially";
					Else
						Result = CommonClientServer.CompareVersions(VersionRow.Version, ParallelSinceVersion);
						DeferredHandlerMode = ?(Result > 0, "Parallel", "Sequentially");
					EndIf;
				Else
					DeferredHandlerMode = DeferredHandlerExecutionMode;
				EndIf;
				CheckDeferredHandlerProperties(Handler, DeferredHandlerMode, ErrorsText);
				
				If HasUncompletedHandlers Then
					FoundRow = VersionsTreeRow.Rows.Find(Handler.Procedure, "HandlerName");
					If FoundRow <> Undefined Then
						FillPropertyValues(FoundRow, Handler);
						Continue; // This handler already exists for this version.
					EndIf;
				EndIf;
				
				HandlersTreeRow = VersionsTreeRow.Rows.Add();
				
				FillPropertyValues(HandlersTreeRow, Handler);
				HandlersTreeRow.LibraryName = LibraryName;
				HandlersTreeRow.VersionNumber = Handler.Version;
				HandlersTreeRow.HandlerName = Handler.Procedure;
				HandlersTreeRow.Status = "NotCompleted";
				HandlersTreeRow.AttemptCount = 0;
			EndDo;
			
		EndDo;
		
	EndDo;
	
	If Not IsBlankString(ErrorsText) Then
		Raise ErrorsText; 
	EndIf;
	
	// Sorting the handler tree.
	LibrariesOrder = StandardSubsystemsCached.SubsystemsDetails().Order;
	Index = 0;
	For Each Library In LibrariesOrder Do
		FoundRow = HandlersTree.Rows.Find(Library, "LibraryName");
		If FoundRow <> Undefined Then
			RowIndex = HandlersTree.Rows.IndexOf(FoundRow);
			Offset = Index - RowIndex;
			If Offset <> 0 Then
				HandlersTree.Rows.Move(FoundRow, Offset);
			EndIf;
			Index = Index + 1
		EndIf;
	EndDo;
	
	HandlersQueue = New Map;
	InfobaseUpdateOverridable.OnFormingDeferredHandlersQueues(HandlersQueue);
	For Each HandlerAndQueue In HandlersQueue Do
		FoundHandler = HandlersTree.Rows.Find(HandlerAndQueue.Key, "HandlerName", True);
		If FoundHandler <> Undefined Then
			FoundHandler.DeferredProcessingQueue = HandlerAndQueue.Value;
		EndIf;
	EndDo;
	
	UpdateInfo.HandlerTreeVersion = Metadata.Version;
	
	CheckDeferredHandlerTree(HandlersTree);
	UpdateInfo.HandlersTree = HandlersTree;
	
	GenerateDeferredUpdatePlan(UpdateInfo);
	WriteInfobaseUpdateInfo(UpdateInfo);
	
EndProcedure

Procedure CheckDeferredHandlerProperties(Val Handler, Val DeferredHandlerExecutionMode, ErrorsText)
	
	If DeferredHandlerExecutionMode = "Parallel"
		AND Not ValueIsFilled(Handler.UpdateDataFillingProcedure) Then
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Не указана процедура заполнения данных
					   |отложенного обработчика обновления
					   |""%1"".'; 
					   |en = 'No data population procedure is specified
					   |for deferred update handler
					   |%1.'; 
					   |pl = 'Nie jest wskazana procedura wypełnienia danych
					   |odroczonego programu przetwarzania aktualizacji
					   |""%1"".';
					   |de = 'Die Vorgehensweise beim Ausfüllen der Daten
					   | des verzögerten Aktualisierungs-Handlers ist nicht spezifiziert
					   |""%1"".';
					   |ro = 'Nu este indicată procedura de completare a datelor
					   |handlerului de actualizare amânat
					   |""%1"".';
					   |tr = 'Bekleyen güncelleştirme işleyicisi "
" verilerini doldurmak için prosedür 
					   |belirtilmedi%1.'; 
					   |es_ES = 'No se ha indicado procedimiento de rellenar los datos
					   |del procesador aplazado de la actualización
					   |%1.'"),
			Handler.Procedure);
		
		WriteError(ErrorText);
		ErrorsText = ErrorsText + ErrorText + Chars.LF;
	EndIf;

	If Handler.ExclusiveMode = True Then
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = 'У отложенного обработчика ""%1""
			|не должен быть установлен признак ""МонопольныйРежим"".'; 
			|en = 'Deferred handler %1
			|cannot have the ExclusiveMode flag set.'; 
			|pl = 'Odroczony program przetwarzania ""%1""
			|nie powinien mieć ustanowionej oznaki ""ExclusiveMode"".';
			|de = 'Die Funktion ""ExclusiveMode"" sollte nicht für den ausstehenden Handler ""%1""
			| festgelegt werden.';
			|ro = 'La handlerul amânat ""%1""
			|nu trebuie să fie instalat indicele ""ExclusiveMode"".';
			|tr = 'Gecikmiş işleyici %1
			|ExclusiveMode özelliğine sahip olmamalıdır.'; 
			|es_ES = 'Para el procesador aplazado %1
			|no puede tener el ExclusiveMode establecido atributo.'"), 
			Handler.Procedure);
		WriteError(ErrorText);
		ErrorsText = ErrorsText + ErrorText + Chars.LF;
	EndIf;

	If DeferredHandlerExecutionMode = "Parallel" AND Handler.ExecuteInMasterNodeOnly
		AND Handler.RunAlsoInSubordinateDIBNodeWithFilters Then
		
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = 'У отложенного обработчика ""%1""
			|некорректно заполнены значения свойств:
			| - ""ЗапускатьТолькоВГлавномУзле""
			| - ""ЗапускатьИВПодчиненномУзлеРИБСФильтрами"".
			|
			|Данные свойства не могут одновременно принимать значение ""Истина"".'; 
			|en = 'In deferred handler %1,
			|the following properties have invalid values:
			| - ExecuteInMasterNodeOnly
			| - ExecuteAlsoInSubordinateDIBNodeWithFilters
			|
			|These properties cannot both be True at the same time.'; 
			|pl = 'W odroczonym programie przetwarzania ""%1""
			|niepoprawnie są wypełnione wartości właściwości:
			| - ""ЗапускатьТолькоВГлавномУзле""
			| - ""ЗапускатьИВПодчиненномУзлеРИБСФильтрами"".
			|
			|Dane właściwości nie mogą jednocześnie przyjmować wartość ""Истина"".';
			|de = 'Der aufgeschobene Handler ""%1""
			|hat die Eigenschaftswerte falsch ausgefüllt:
			| - ""NurImHauptknotenAusführen""
			| - ""AusführenUndImUntergeordnetenKnotenEinerVerteiltenInformationsbasisMitFiltern"".
			|
			|Diese Eigenschaften können nicht gleichzeitig auf ""True"" gesetzt werden.';
			|ro = 'La handlerul amânat ""%1""
			|sunt completate incorect valorile proprietăților:
			| - ""ЗапускатьТолькоВГлавномУзле""
			| - ""ЗапускатьИВПодчиненномУзлеРИБСФильтрами"".
			|
			|Aceste proprietăți nu pot accepta simultan valoarea ""Истина"".';
			|tr = 'Ertelenmiş işleyicinin ""%1""
			|özelliklerinin değerleri yanlış doldurulmuştur:
			| - ""SadeceAnaÜnitedeBaşlat""
			| - ""AltÜnitedeRIBSFiltresindeDeBaşlat"".
			|
			|Bu özellikler, aynı anda ""Doğru"" değerini alamaz.'; 
			|es_ES = 'Para el procesador aplazado ""%1"
"están rellenados incorrectamente los valores de las propiedades:
			| - ExecuteInMasterNodeOnly
			| - ExecuteAlsoInSubordinateDIBNodeWithFilters.
			|
			|Estas propiedades no pueden simultáneamente tener el valor ""Verdadero"".'"), 
			Handler.Procedure);
		WriteError(ErrorText);
		ErrorsText = ErrorsText + ErrorText + Chars.LF;
	EndIf;

	If Handler.SharedData = True Then
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = 'У отложенного обработчика ""%1""
			|указано недопустимое значение свойства ""ОбщиеДанные"".
			|
			|Данное свойство не может принимать значение ""Истина"" у отложенного обработчика.'; 
			|en = 'In deferred handler %1,
			|SharedData property has invalid value.
			|
			|This property cannot be True in deferred handlers.'; 
			|pl = 'W odroczonym programie przetwarzania ""%1""
			|jest wskazana niedopuszczalna wartość właściwości ""ОбщиеДанные"".
			|
			|Dana właściwość nie może przyjmować wartość ""Истина"" dla odroczonego programu przetwarzania.';
			|de = 'Ein verzögerter Handler ""%1""
			| hat einen ungültigen Wert der Eigenschaft ""AllgemeineDaten"".
			|
			|Diese Eigenschaft kann für einen ausstehenden Handler nicht auf ""True"" gesetzt werden.';
			|ro = 'La handlerul amânat ""%1""
			|este indicată valoarea inadmisibilă a proprietății ""ОбщиеДанные"".
			|
			|Această proprietate nu poate accepta valoarea ""Истина"" la handlerul amânat.';
			|tr = 'Ertelenmiş işleyicinin ""%1"
"OrtakVeriler"" özelliğinin belirtilen değeri kabul edilemez.
			|
			|Bu özellik, ertelenmiş işleyicide ""Doğru"" değerini alamaz. '; 
			|es_ES = 'Para el procesador aplazado ""%1""
			|está indicado el valor de la propiedad ""ОбщиеДанные"".
			|
			|Esta propiedad no puede tener el valor ""Verdadero"" del procesador aplazado.'"), 
			Handler.Procedure);
		WriteError(ErrorText);
		ErrorsText = ErrorsText + ErrorText + Chars.LF;
	EndIf;
	
EndProcedure

Procedure CheckDeferredHandlerIDUniqueness(UpdateIterations)
	
	UniquenessCheckTable = New ValueTable;
	UniquenessCheckTable.Columns.Add("ID");
	UniquenessCheckTable.Columns.Add("IndexOf");
	
	For Each UpdateIteration In UpdateIterations Do
		
		FilterParameters = New Structure;
		FilterParameters.Insert("ExecutionMode", "Deferred");
		HandlersTable = UpdateIteration.Handlers;
		
		Handlers = HandlersTable.FindRows(FilterParameters);
		For Each Handler In Handlers Do
			If Not ValueIsFilled(Handler.ID) Then
				Continue;
			EndIf;
			TableRow = UniquenessCheckTable.Add();
			TableRow.ID = String(Handler.ID);
			TableRow.IndexOf        = 1;
		EndDo;
		
	EndDo;
	
	InitialRowCount = UniquenessCheckTable.Count();
	UniquenessCheckTable.GroupBy("ID", "IndexOf");
	FinalRowCount = UniquenessCheckTable.Count();
	
	// Running a quick check.
	If InitialRowCount = FinalRowCount Then
		Return; // All IDs are unique.
	EndIf;
	
	UniquenessCheckTable.Sort("IndexOf Desc");
	MessageText = NStr("ru = 'Обнаружены отложенные обработчики обновления,
		|у которых совпадают уникальные идентификаторы. Следующие идентификаторы не уникальны:'; 
		|en = 'Deferred update handlers with duplicate UUIDs are found.
		|The following UUIDs are duplicate:'; 
		|pl = 'Wykryto odroczone programy przetwarzania aktualizacji,
		|które mają zgodne unikalne identyfikatory. Następujące identyfikatory nie są unikalne:';
		|de = 'Ausstehende Update-Handler
		|mit eindeutigen Kennungen wurden erkannt. Die folgenden Bezeichner sind nicht eindeutig:';
		|ro = 'Au fost depistați handlerii amânați de actualizare,
		|la care coincid identificatorii unici. Următorii identificatori nu sunt unici';
		|tr = 'Benzersiz tanımlayıcıları aynı olan
		| bekleyen güncelleme işleyicileri tespit edildi.  Aşağıdaki tanımlayıcılar benzersiz değildir:'; 
		|es_ES = 'Se han encontrado los procesador aplazados de la actualización
		|cuyos identificadores únicos no coinciden. Los siguientes identificadores no son únicos:'");
	For Each IDRow In UniquenessCheckTable Do
		If IDRow.IndexOf = 1 Then
			Break;
		Else
			MessageText = MessageText + Chars.LF + IDRow.ID;
		EndIf;
	EndDo;
	
	Raise MessageText;
	
EndProcedure

// Schedules the deferred update in client/server infobase.
//
Procedure ScheduleDeferredUpdate()
	
	// Scheduling a job.
	// Adding the scheduled job to queue when in SaaS.
	If Not Common.FileInfobase() Then
		OnEnableDeferredUpdate(True);
	EndIf;
	
EndProcedure

// Controls execution of the deferred update handlers.
// 
Procedure ExecuteDeferredUpdate() Export
	
	Common.OnStartExecuteScheduledJob();
	
	If InfobaseUpdateInternalCached.InfobaseUpdateRequired() Then
		Return;
	EndIf;
	
	UpdateInfo = InfobaseUpdateInfo();
	
	If UpdateInfo.DeferredUpdateEndTime <> Undefined Then
		CancelDeferredUpdate();
		Return;
	EndIf;
	
	If UpdateInfo.DeferredUpdateStartTime = Undefined Then
		UpdateInfo.DeferredUpdateStartTime = CurrentSessionDate();
	EndIf;
	If TypeOf(UpdateInfo.SessionNumber) <> Type("ValueList") Then
		UpdateInfo.SessionNumber = New ValueList;
	EndIf;
	UpdateInfo.SessionNumber.Add(InfoBaseSessionNumber());
	WriteInfobaseUpdateInfo(UpdateInfo);
	
	// Disabling the period-end closing date check in the scheduled job session.
	If Common.SubsystemExists("StandardSubsystems.PeriodClosingDates") Then
		ModulePeriodClosingDatesInternal = Common.CommonModule("PeriodClosingDatesInternal");
		ModulePeriodClosingDatesInternal.SkipPeriodClosingCheck(True);
	EndIf;
	
	HandlersExecutedEarlier = True;
	
	Try
		If ForceUpdate(UpdateInfo) Then
			If UpdateInfo.ThreadsDetails <> Undefined Then
				CancelAllThreadsExecution(UpdateInfo.ThreadsDetails, UpdateInfo);
			EndIf;
			
			ThreadsDetails = NewDetailsOfDeferredUpdateHandlerThreads();
			UpdateInfo.ThreadsDetails = ThreadsDetails;
			
			While HandlersExecutedEarlier Do
				Thread = AddDeferredUpdateHandlerThread(ThreadsDetails, UpdateInfo);
				
				If TypeOf(Thread) = Type("ValueTableRow") Then
					ExecuteThread(ThreadsDetails, Thread);
					WaitForAvailableThread(ThreadsDetails, UpdateInfo);
				ElsIf Thread = True Then
					WaitForAnyThreadCompletion(ThreadsDetails, UpdateInfo);
				ElsIf Thread = False Then
					HandlersExecutedEarlier = False;
					WaitForAllThreadsCompletion(ThreadsDetails, UpdateInfo);
					SaveThreadsStateToUpdateInfo(ThreadsDetails, UpdateInfo);
					Break;
				EndIf;
				
				SaveThreadsStateToUpdateInfo(ThreadsDetails, UpdateInfo);
				Job = ScheduledJobsServer.Job(Metadata.ScheduledJobs.DeferredIBUpdate);
				ExecutionRequired = Job.Schedule.ExecutionRequired(CurrentSessionDate());
				
				If Not ExecutionRequired Or Not ForceUpdate(UpdateInfo) Then
					WaitForAllThreadsCompletion(ThreadsDetails, UpdateInfo);
					SaveThreadsStateToUpdateInfo(Undefined, UpdateInfo);
					Break;
				EndIf;
			EndDo;
		Else
			HandlersExecutedEarlier = ExecuteDeferredUpdateHandler(UpdateInfo);
			WriteInfobaseUpdateInfo(UpdateInfo);
		EndIf;
	Except
		WriteError(DetailErrorDescription(ErrorInfo()));
		CancelAllThreadsExecution(UpdateInfo.ThreadsDetails, UpdateInfo);
		SaveThreadsStateToUpdateInfo(Undefined, UpdateInfo);
	EndTry;
	
	If Not HandlersExecutedEarlier Or AllDeferredHandlersCompleted(UpdateInfo) Then
		SaveThreadsStateToUpdateInfo(Undefined, UpdateInfo);
		CancelDeferredUpdate();
	EndIf;
	
EndProcedure

// Called when enabling or disabling the deferred update.
//
// Parameters:
//   Use - Boolean - True if the job must be enabled, otherwise, False.
//
Procedure OnEnableDeferredUpdate(Usage) Export
	
	If Not Common.DataSeparationEnabled() Then
		JobsFilter = New Structure;
		JobsFilter.Insert("Metadata", Metadata.ScheduledJobs.DeferredIBUpdate);
		Jobs = ScheduledJobsServer.FindJobs(JobsFilter);
		
		For Each Job In Jobs Do
			JobParameters = New Structure("Use", Usage);
			ScheduledJobsServer.ChangeJob(Job, JobParameters);
		EndDo;
		Return;
	EndIf;
	
	If Common.SubsystemExists("StandardSubsystems.SaaS.IBVersionUpdateSaaS") Then
		ModuleInfobaseUpdateInternalSaaS = Common.CommonModule("InfobaseUpdateInternalSaaS");
		ModuleInfobaseUpdateInternalSaaS.OnEnableDeferredUpdate(Usage);
	EndIf;
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Multithread update mechanism.

// Group name of data registration threads for a deferred update.
//
// Returns:
//  String - a group name.
//
Function DeferredUpdateDataRegistrationThreadsGroup()
	
	Return "Registration";
	
EndFunction

// Name of the deferred update thread group.
//
// Returns:
//  String - a group name.
//
Function DeferredUpdateThreadsGroup()
	
	Return "Update";
	
EndFunction

// Name of thread group to search data batches for multithread execution of update handlers.
//
// Returns:
//  String - a group name.
//
Function BatchesSearchThreadsGroup()
	
	Return "Search";
	
EndFunction

// Creates a new description of deferred update data registration threads.
//
// Returns:
//  Structure - see NewThreadsDetails(). 
//
Function NewDetailsOfDeferredUpdateDataRegistrationThreads()
	
	RegistrationGroup = NewThreadsGroupDetails();
	RegistrationGroup.Procedure =
		"InfobaseUpdateInternal.FillDeferredHandlerData";
	RegistrationGroup.CompletionProcedure =
		"InfobaseUpdateInternal.CompleteDeferredUpdateDataRegistration";
	
	Details = NewThreadsDetails();
	Details.Folders[DeferredUpdateDataRegistrationThreadsGroup()] = RegistrationGroup;
	
	Return Details;
	
EndFunction

// Adds a deferred update data registration thread.
//
// Parameters:
//  ThreadsDetails - Structure - see NewThreadsDetails(). 
//  DataToProcessDetails - Structure - see NewDataToProcessDetails(). 
//
// Returns:
//  ValueTableRow - a new thread (see NewThreadsDetails()).
//
Function AddDeferredUpdateDataRegistrationThread(ThreadsDetails, DataToProcessDetails)
	
	DescriptionTemplate = NStr("ru = 'Регистрация данных обработчика обновления ""%1""'; en = 'Register data of %1 update handler'; pl = 'Rejestracja danych programu przetwarzania aktualizacji ""%1""';de = 'Registrierung der Handlerdaten aktualisieren ""%1"".';ro = 'Înregistrarea datelor handlerului de actualizare ""%1""';tr = '""%1"" güncelleme işleyicisinin verilerinin kaydı'; es_ES = 'El registro de los datos del procesador de la actualización ""%1""'");
	DataToProcessDetails.Status = "Running";
	
	Thread = ThreadsDetails.Threads.Add();
	Thread.ProcedureParameters = DataToProcessDetails;
	Thread.CompletionProcedureParameters = DataToProcessDetails;
	Thread.Group = DeferredUpdateDataRegistrationThreadsGroup();
	Thread.Description = StringFunctionsClientServer.SubstituteParametersToString(DescriptionTemplate,
		DataToProcessDetails.HandlerName);
	
	Return Thread;
	
EndFunction

// Complete registration of the deferred update data.
// Called automatically in the main thread after FillDeferredHandlerData() has completed.
//
// Parameters:
//  DataToProcessDetails - Structure - see NewDataToProcessDetails(). 
//  ResultAddress - String - address of the temporary storage used to store the result returned by FillDeferredHandlerData().
//  UpdateInfo - Structure - update information (see NewUpdateInfo()).
//
Procedure CompleteDeferredUpdateDataRegistration(DataToProcessDetails,
                                                          ResultAddress,
                                                          UpdateInfo) Export
	
	Result = GetFromTempStorage(ResultAddress);
	
	If TypeOf(UpdateInfo.DataToProcess) <> Type("Map") Then
		UpdateInfo.DataToProcess = New Map;
	EndIf;
	
	DataToProcessDetails = UpdateInfo.DataToProcess[DataToProcessDetails.HandlerName];
	FillPropertyValues(DataToProcessDetails, Result);
	DataToProcessDetails.Status = "Completed";
	
	If Common.SubsystemExists("StandardSubsystems.DataExchange") Then
		If Result.UpdateData <> Undefined Then
			ModuleDataExchangeServer = Common.CommonModule("DataExchangeServer");
			ModuleDataExchangeServer.SaveUpdateData(Result.UpdateData, Result.NameOfChangedFile);
		EndIf;
	EndIf;
	
EndProcedure

// Creates a new description of deferred update handler threads.
//
// Returns:
//  Structure - see NewThreadsDetails(). 
//
Function NewDetailsOfDeferredUpdateHandlerThreads()
	
	UpdateGroup = NewThreadsGroupDetails();
	UpdateGroup.Procedure =
		"InfobaseUpdateInternal.ExecuteDeferredHandler";
	UpdateGroup.CompletionProcedure =
		"InfobaseUpdateInternal.CompleteDeferredHandlerExecution";
	UpdateGroup.OnAbnormalTermination =
		"InfobaseUpdateInternal.OnDeferredHandlerThreadAbnormalTermination";
	UpdateGroup.OnCancelThread =
		"InfobaseUpdateInternal.OnCancelDeferredHandlerThread";
	
	SearchGroup = NewThreadsGroupDetails();
	SearchGroup.Procedure =
		"InfobaseUpdateInternal.FindBatchToUpdate";
	SearchGroup.CompletionProcedure =
		"InfobaseUpdateInternal.EndSearchForBatchToUpdate";
	SearchGroup.OnAbnormalTermination =
		"InfobaseUpdateInternal.OnBatchToImportSearchThreadAbnormalTermination";
	SearchGroup.OnCancelThread =
		"InfobaseUpdateInternal.OnCancelSearchBatchToUpdate";
	
	Details = NewThreadsDetails();
	Details.Folders[DeferredUpdateThreadsGroup()] = UpdateGroup;
	Details.Folders[BatchesSearchThreadsGroup()] = SearchGroup;
	
	Return Details;
	
EndFunction

// Adds a deferred update handler thread.
//
// Parameters:
//  ThreadsDetails - Structure - see NewDetailsOfDeferredUpdateDataRegistrationThreads(). 
//  UpdateInfo - Structure - update information (see NewUpdateInfo()).
//
// Returns:
//  * ValueTableRow - a new thread (see NewThreadsDetails()).
//  * Boolean - True if the handler does not need to be completed, or False if the handler needs to be completed.
//
Function AddDeferredUpdateHandlerThread(ThreadsDetails, UpdateInfo)
	
	HandlerContext = NewHandlerContext();
	UpdateHandler = FindUpdateHandler(HandlerContext, UpdateInfo);
	
	If TypeOf(UpdateHandler) = Type("ValueTreeRow") Then
		If HandlerContext.ExecuteHandler Then
			Thread = ThreadsDetails.Threads.Add();
			
			If UpdateHandler.Multithreaded Then
				SupplementMultithreadHandlerContext(HandlerContext);
				Added = AddDatasearchThreadForUpdate(Thread,
					UpdateHandler,
					HandlerContext,
					UpdateInfo);
				
				If Not Added Then
					ThreadsDetails.Threads.Delete(Thread);
					Thread = True;
				EndIf;
			Else
				AddUpdateHandlerThread(Thread, HandlerContext);
			EndIf;
		Else
			Thread = True;
		EndIf;
	Else
		Thread = UpdateHandler;
	EndIf;
	
	Return Thread;
	
EndFunction

// Add a data search thread for the deferred update handler.
//
// Parameters:
//  Thread - ValueTableRow - description of the thread (see NewThreadsDetails()).
//  Handler - ValueTreeRow - the update handler represented as a row of the handler tree.
//  HandlerContext - Structure - see NewHandlerContext(). 
//  UpdateInfo - Structure - update information (see NewUpdateInfo()).
//
// Returns:
//  Boolean - True, a thread is added, otherwise False.
//
Function AddDatasearchThreadForUpdate(Thread, Handler, HandlerContext, UpdateInfo)
	
	HandlerName = Handler.HandlerName;
	Details = UpdateInfo.DataToProcess[HandlerName];
	
	If Not Details.BatchSearchInProgress Then
		BatchesToUpdate = Details.BatchesToUpdate;
		
		If Details.SearchCompleted AND (BatchesToUpdate = Undefined Or BatchesToUpdate.Count() = 0) Then
			BatchesToUpdate = Undefined;
			Details.LastSelectedRecord = Undefined;
			Details.SearchCompleted = False;
		EndIf;
		
		DescriptionTemplate = NStr("ru = 'Поиск данных для обработчика обновления ""%1""'; en = 'Searching data for the %1 update handler'; pl = 'Wyszukiwanie danych dla obsługi aktualizacji ""%1""';de = 'Suche nach Daten für den Update-Handler ""%1"".';ro = 'Căutarea datelor pentru handlerul de actualizare ""%1""';tr = 'Güncelleme işleyicisi ""%1"" için veri araması'; es_ES = 'Búsqueda de datos para procesador de actualización ""%1""'");
		Thread.Description = StringFunctionsClientServer.SubstituteParametersToString(DescriptionTemplate, HandlerName);
		Thread.Group = BatchesSearchThreadsGroup();
		Thread.CompletionPriority = 1;
		
		SearchParameters = NewBatchSearchParameters();
		SearchParameters.HandlerName = HandlerName;
		SearchParameters.HandlerContext = HandlerContext;
		SearchParameters.SelectionParameters = Details.SelectionParameters;
		SearchParameters.Queue = HandlerContext.Parameters.Queue;
		SearchParameters.ForceUpdate = ForceUpdate(UpdateInfo);
		
		UnprocessedBatch = FirstUnprocessedBatch(BatchesToUpdate);
		
		If UnprocessedBatch <> Undefined Then
			SearchParameters.BatchID = UnprocessedBatch.ID;
			SearchParameters.FirstRecord = UnprocessedBatch.FirstRecord;
			SearchParameters.LatestRecord = UnprocessedBatch.LatestRecord;
		ElsIf Details.LastSelectedRecord <> Undefined Then
			SearchParameters.LastSelectedRecord = Details.LastSelectedRecord;
		EndIf;
		
		Thread.ProcedureParameters = SearchParameters;
		Thread.CompletionProcedureParameters = SearchParameters;
		Details.BatchSearchInProgress = True;
		
		Return True;
	Else
		Return False;
	EndIf;
	
EndFunction

// Adds a deferred update handler thread.
//
// Parameters:
//  Thread - ValueTableRow - description of the thread (see NewThreadsDetails()).
//  HandlerContext - Structure - see NewHandlerContext(). 
//
Procedure AddUpdateHandlerThread(Thread, HandlerContext)
	
	HandlerName = HandlerContext.HandlerName;
	DescriptionTemplate = NStr("ru = 'Выполнение обработчика обновления ""%1""'; en = 'Run the %1 update handler'; pl = 'Wykonanie programu przetwarzania aktualizacji ""%1""';de = 'Ausführung des Update-Handlers ""%1""';ro = 'Executarea handlerului de actualizare ""%1""';tr = '""%1"" güncelleme işleyicisi yürütülüyor'; es_ES = 'Se ejecuta el procesador de la actualización ""%1""'");
	Thread.Description = StringFunctionsClientServer.SubstituteParametersToString(DescriptionTemplate, HandlerName);
	Thread.Group = DeferredUpdateThreadsGroup();
	Thread.ProcedureParameters = HandlerContext;
	Thread.CompletionProcedureParameters = HandlerContext;
	
EndProcedure

// Runs the deferred handler in a background job.
// Executed only when HandlerContext.ExecuteHandler = True (i.e. not in a subordinate DIB node).
//
// Parameters:
//  HandlerContext - Structure - see NewHandlerContext(). 
//  ResultAddress - String - an address of the temporary storage for storing the procedure result.
//
Procedure ExecuteDeferredHandler(HandlerContext, ResultAddress) Export
	
	SessionParameters.UpdateHandlerParameters = HandlerContext.UpdateHandlerParameters;
	
	SubsystemExists = Common.SubsystemExists("StandardSubsystems.AccessManagement");
	DisableAccessKeysUpdate(True, SubsystemExists);
	Try
		CallParameters = New Array;
		CallParameters.Add(HandlerContext.Parameters);
		Result = NewDeferredHandlerResult();
		
		Result.HandlerProcedureStart = CurrentUniversalDateInMilliseconds();
		Common.ExecuteConfigurationMethod(HandlerContext.HandlerName, CallParameters);
		Result.HandlerProcedureCompletion = CurrentUniversalDateInMilliseconds();
		
		Result.Parameters = HandlerContext.Parameters;
		Result.UpdateHandlerParameters = SessionParameters.UpdateHandlerParameters;
		
		Try
			ValidateNestedTransaction(HandlerContext.TransactionActiveAtExecutionStartTime,
				HandlerContext.HandlerName);
		Except
			Result.ErrorInfo = DetailErrorDescription(ErrorInfo());
			Result.HasOpenTransactions = True;
			
			While TransactionActive() Do
				RollbackTransaction();
			EndDo;
		EndTry;
		
		PutToTempStorage(Result, ResultAddress);
		DisableAccessKeysUpdate(False, SubsystemExists);
		SessionParameters.UpdateHandlerParameters = New FixedStructure(NewUpdateHandlerParameters());
	Except
		DisableAccessKeysUpdate(False, SubsystemExists);
		SessionParameters.UpdateHandlerParameters = New FixedStructure(NewUpdateHandlerParameters());
		Raise;
	EndTry;
	
EndProcedure

// Completes execution of a deferred handler.
// Called automatically in the main thread after ExecuteDeferredHandler() has completed.
//
// Parameters:
//  HandlerContext - Structure - see NewHandlerContext(). 
//  ResultAddress - String - address of the temporary storage used to store the result returned by ExecuteDeferredHandler().
//  UpdateInfo - Structure - see NewUpdateInfo(). 
//
Procedure CompleteDeferredHandlerExecution(HandlerContext, ResultAddress, UpdateInfo) Export
	
	UpdateHandler = FindHandlerInTree(UpdateInfo.HandlersTree.Rows,
		HandlerContext.HandlerID,
		HandlerContext.HandlerName);
	UpdateHandler.BatchProcessingCompleted = True;
	
	ImportHandlerExecutionResult(HandlerContext, ResultAddress);
	SessionParameters.UpdateHandlerParameters = HandlerContext.UpdateHandlerParameters;
	
	If HandlerContext.StartedWithoutErrors Then
		AfterStartDataProcessingProcedure(HandlerContext, UpdateHandler, UpdateInfo);
	EndIf;
	
	EndDataProcessingProcedure(HandlerContext, UpdateHandler, UpdateInfo);
	SessionParameters.UpdateHandlerParameters = New FixedStructure(NewUpdateHandlerParameters());
	EndDeferredUpdateHandlerExecution(HandlerContext, UpdateInfo);
	CalculateHandlerProcedureEecutionTime(HandlerContext, UpdateHandler);
	
	If UpdateHandler.Multithreaded Then
		CompleteMultithreadHandlerExecution(HandlerContext, UpdateInfo);
	EndIf;
	
EndProcedure

// Calculate execution time of the data processing procedure (not the whole handler).
//
// Parameters:
//  HandlerContext - Structure - see NewHandlerContext(). 
//  UpdateHandler - ValueTreeRow - the update handler represented as a row of the handler tree.
//
Procedure CalculateHandlerProcedureEecutionTime(HandlerContext, UpdateHandler)
	
	HandlerProcedureStart = HandlerContext.HandlerProcedureStart;
	HandlerProcedureCompletion = HandlerContext.HandlerProcedureCompletion;
	HandlerProcedureDuration = HandlerProcedureCompletion - HandlerProcedureStart;
	ExecutionStarted = '00010101' + HandlerProcedureStart / 1000;
	ExecutionCompletion = '00010101' + HandlerProcedureCompletion / 1000;
	StatisticsStart = UpdateHandler.ExecutionStatistics["HandlerProcedureStart"];
	StatisticsCompletion = UpdateHandler.ExecutionStatistics["HandlerProcedureCompletion"];
	StatisticsDuration = UpdateHandler.ExecutionStatistics["HandlerProcedureDuration"];
	
	If StatisticsStart = Undefined Then
		StatisticsStart = New Array;
		UpdateHandler.ExecutionStatistics["HandlerProcedureStart"] = StatisticsStart;
	EndIf;
	
	If StatisticsCompletion = Undefined Then
		StatisticsCompletion = New Array;
		UpdateHandler.ExecutionStatistics["HandlerProcedureCompletion"] = StatisticsCompletion;
	EndIf;
	
	If StatisticsDuration = Undefined Then
		StatisticsDuration = New Array;
		UpdateHandler.ExecutionStatistics["HandlerProcedureDuration"] = StatisticsDuration;
	EndIf;
	
	StatisticsStart.Add(ExecutionStarted);
	StatisticsCompletion.Add(ExecutionCompletion);
	StatisticsDuration.Add(HandlerProcedureDuration);
	
EndProcedure

// Deferred update thread termination handler.
//
// Parameters:
//  Thread - ValueTableRow - description of the thread (see NewThreadsDetails()).
//  ErrorInformation - ErrorInformation - an error description.
//  UpdateInfo - Structure - see NewUpdateInfo(). 
//
Procedure OnDeferredHandlerThreadAbnormalTermination(Thread, ErrorInformation, UpdateInfo) Export
	
	UpdateHandler = FindHandlerInTree(UpdateInfo.HandlersTree.Rows,
		Thread.ProcedureParameters.HandlerID,
		Thread.ProcedureParameters.HandlerName);
	ProcessHandlerException(Thread.ProcedureParameters, UpdateHandler, ErrorInformation);
	
	If UpdateHandler.Multithreaded Then
		CancelUpdatingDataOfMultithreadHandler(Thread, UpdateHandler, UpdateInfo);
	EndIf;
	
EndProcedure

// Thread cancellation handler.
//
// Parameters:
//  Thread - ValueTableRow - description of the thread (see NewThreadsDetails()).
//  UpdateInfo - Structure - see NewUpdateInfo(). 
//
Procedure OnCancelDeferredHandlerThread(Thread, UpdateInfo) Export
	
	UpdateHandler = FindHandlerInTree(UpdateInfo.HandlersTree.Rows,
		Thread.ProcedureParameters.HandlerID,
		Thread.ProcedureParameters.HandlerName);
	
	If UpdateHandler.Status = "Running" Then
		UpdateHandler.Status = Undefined;
	EndIf;
	
	If UpdateHandler.Multithreaded Then
		CancelUpdatingDataOfMultithreadHandler(Thread, UpdateHandler, UpdateInfo);
	EndIf;
	
EndProcedure

// Imports handler execution result data from temporary storage to the update handler context.
//
// Parameters:
//  HandlerContext - Structure - see NewHandlerContext(). 
//  ResultAddress - String - address of the result in the temporary storage.
//
Procedure ImportHandlerExecutionResult(HandlerContext, ResultAddress)
	
	Result = GetFromTempStorage(ResultAddress);
	
	If Result <> Undefined Then
		If HandlerContext.WriteToLog Then
			HandlerContext.HandlerFullDetails.Parameters = Result.Parameters;
		EndIf;
		
		HandlerContext.HasOpenTransactions = Result.HasOpenTransactions;
		HandlerContext.HandlerProcedureCompletion = Result.HandlerProcedureCompletion;
		HandlerContext.ErrorInfo = Result.ErrorInfo;
		HandlerContext.HandlerProcedureStart = Result.HandlerProcedureStart;
		HandlerContext.Parameters = Result.Parameters;
		HandlerContext.UpdateHandlerParameters = Result.UpdateHandlerParameters;
	EndIf;
	
EndProcedure

// Saves the update thread execution status to the update information.
//
// Parameters:
//  ThreadsDetails - Structure - a collection of threads (see NewThreadsDetails()).
//  UpdateInfo - Structure - see NewUpdateInfo(). 
//
Procedure SaveThreadsStateToUpdateInfo(ThreadsDetails, UpdateInfo)
	
	UpdateInfo.ThreadsDetails = ThreadsDetails;
	WriteInfobaseUpdateInfo(UpdateInfo);
	
EndProcedure

// Update handler execution context.
//
// Returns:
//  Structure - description of the context (serialized before passing to a background job):
//   * ExecuteHandler - Boolean - if True, the handler is ready for execution.
//   * HandlerFullDetails - Structure - see PrepareUpdateProgressDetails(). 
//   * HandlerProcedureCompletion - Number - completion of the data processing procedure.
//   * WriteToLog - Boolean - see Constants.WriteIBUpdateDetailsToEventLog. 
//   * StartedWithoutErrors - Boolean - if True, no exceptions were raised during handler start.
//   * HandlerID - UUID - the ID of the update handler.
//   * HandlerName - String - the name of the update handler.
//   * UpdateCycleDetailsIndex - Number - index of the update plan item.
//   * CurrentUpdateCycleIndex - Number - index of the current update plan item.
//   * DataProcessingStart - Date - start time of the update handler.
//   * HandlerProcedureStart - Number - data processing procedure start.
//   * ParallelMode - Boolean - indicates whether the update handler runs in parallel mode.
//   * Parameters - Structure - parameters of the update handler.
//   * UpdateParameters - Structure - description of the update parameters.
//   * UpdateHandlerParameters - FixedStructure - see SessionParameters.UpdateHandlerParameters. 
//   * SkipProcessedDataCheck - Boolean - skip check in a subordinate DIB node.
//   * CurrentUpdateIteration - Number - number of the current update iteration.
//   * TransactionActiveAtExecutionStartTime - Boolean - transaction activity status before running the handler.
//
Function NewHandlerContext()
	
	HandlerContext = New Structure;
	
	HandlerContext.Insert("ExecuteHandler", False);
	HandlerContext.Insert("HandlerFullDetails");
	HandlerContext.Insert("HasOpenTransactions", False);
	HandlerContext.Insert("HandlerProcedureCompletion");
	HandlerContext.Insert("WriteToLog");
	HandlerContext.Insert("StartedWithoutErrors", False);
	HandlerContext.Insert("HandlerID");
	HandlerContext.Insert("HandlerName");
	HandlerContext.Insert("UpdateCycleDetailsIndex");
	HandlerContext.Insert("CurrentUpdateCycleIndex");
	HandlerContext.Insert("ErrorInfo");
	HandlerContext.Insert("DataProcessingStart");
	HandlerContext.Insert("HandlerProcedureStart");
	HandlerContext.Insert("ParallelMode");
	HandlerContext.Insert("Parameters");
	HandlerContext.Insert("UpdateParameters");
	HandlerContext.Insert("UpdateHandlerParameters");
	HandlerContext.Insert("SkipProcessedDataCheck", False);
	HandlerContext.Insert("CurrentUpdateIteration");
	HandlerContext.Insert("TransactionActiveAtExecutionStartTime");
	
	Return HandlerContext;
	
EndFunction

// Add fields for a multithread handler to the handler context.
//
// Parameters:
//  HandlerContext - Structure (see NewHandlerContext()).
//
Procedure SupplementMultithreadHandlerContext(HandlerContext)
	
	HandlerContext.Parameters.Insert("DataToUpdate");
	
EndProcedure

// Result of deteffed update handler, to be passed to the handler completion procedure in the 
// control thread.
//
// Returns:
//  Structure - result description.
//   * HasOpenTransactions - Boolean - indicates that there are open transactions in the handler itself.
//   * HandlerProcedureCompletion - Number - time of completing an update handler procedure.
//   * ErrorInformation - ErrorInformation - an error description (if an error occurred).
//   * HandlerProcedureStart - Number - time of starting to execute an update handler procedure.
//   * Parameters - Structure - parameters that were passed to the update handler.
//   * UpdateHandlerParameters - FixedStructure - the value of session parameter
//                                      UpdateHandlerParameters
//
Function NewDeferredHandlerResult()
	
	Result = New Structure;
	Result.Insert("HasOpenTransactions", False);
	Result.Insert("HandlerProcedureCompletion");
	Result.Insert("ErrorInfo");
	Result.Insert("HandlerProcedureStart");
	Result.Insert("Parameters");
	Result.Insert("UpdateHandlerParameters");
	
	Return Result;
	
EndFunction

// The default number of update threads.
//
// Returns:
//  Number - the number of threads; it is equal to 1 (for backward compatibility) unless redefined in
//          InfobaseUpdateOverridable.OnDefineSettings().
//
Function DefaultInfobaseUpdateThreadsCount()
	
	Parameters = SubsystemSettings();
	Return Parameters.DefaultInfobaseUpdateThreadsCount;
	
EndFunction

// Determines the update priority.
//
// Parameters:
//  UpdateInfo - Structure - see NewUpdateInfo(). 
//
// Returns:
//  Boolean - True if data processing has priority, False if user operations have priority.
//
Function ForceUpdate(UpdateInfo)
	
	If Not Common.DataSeparationEnabled() Then
		Return UpdateInfo.DeferredUpdateManagement.Property("ForceUpdate");
	Else
		Priority = Undefined;
		SaaSIntegration.OnGetUpdatePriority(Priority);
		
		If Priority = "UserWork" Then
			Return False;
		ElsIf Priority = "DataProcessing" Then
			Return True;
		Else
			Return UpdateInfo.DeferredUpdateManagement.Property("ForceUpdate");
		EndIf;
	EndIf;
	
EndFunction

////////////////////////////////////////////////////////////////////////////////
// Thread operation mechanism.

// Executes the specified thread.
//
// Parameters:
//  ThreadsDetails - Structure - a collection of threads (see NewThreadsDetails()).
//  Thread - ValueTableRow - description of the thread (see Threads in NewThreadsDetails()).
//  FormID - UUID - the form ID, if any.
//
// Returns:
//  Boolean - True if the thread is running or has completed, False if the thread is not started or was terminated.
//
Procedure ExecuteThread(ThreadsDetails, Thread, FormID = Undefined)
	
	ThreadDetails = ThreadsDetails.Folders[Thread.Group];
	
	If Not IsBlankString(ThreadDetails.Procedure) AND Thread.ProcedureParameters <> Undefined Then
		ExecutionParameters = TimeConsumingOperations.BackgroundExecutionParameters(FormID);
		ExecutionParameters.BackgroundJobDescription = Thread.Description;
		ExecutionParameters.WaitForCompletion = 0;
		
		If FormID = Undefined Then
			ExecutionParameters.ResultAddress = PutToTempStorage(Undefined, New UUID);
		EndIf;
		
		RunResult = TimeConsumingOperations.ExecuteInBackground(ThreadDetails.Procedure,
			Thread.ProcedureParameters,
			ExecutionParameters);
		
		Thread.ResultAddress = RunResult.ResultAddress;
		Status = RunResult.Status;
		
		If Status = "Running" Then
			Thread.JobID = RunResult.JobID;
		ElsIf Status <> "Running" AND Status <> "Completed" Then
			Raise RunResult.BriefErrorPresentation;
		EndIf;
	EndIf;
	
EndProcedure

// Stops the threads that have completed their background jobs.
//
// Parameters:
//  ThreadsDetails - Structure - a collection of threads (see NewThreadsDetails()).
//  Parameters - Arbitrary - parameters of the calling thread to be passed to the completion procedure.
//
// Returns:
//  Boolean - True if one or several threads were stopped, False otherwise.
//
Function StopThreadsWithCompletedBackgroundJobs(ThreadsDetails, Parameters = Undefined)
	
	HasCompletedThreads = False;
	Threads = ThreadsDetails.Threads;
	Groups = ThreadsDetails.Folders;
	Threads.Sort("CompletionPriority Desc");
	Index = Threads.Count() - 1;
	
	While Index >= 0 Do
		Thread = Threads[Index];
		ThreadDetails = Groups[Thread.Group];
		JobID = Thread.JobID;
		
		If JobID <> Undefined Then
			Try
				JobCompleted = TimeConsumingOperations.JobCompleted(JobID);
			Except
				ErrorInformation = ErrorInfo();
				JobCompleted = Undefined;
				
				If Not IsBlankString(ThreadDetails.OnAbnormalTermination) Then
					CallParameters = New Array;
					CallParameters.Add(Thread);
					CallParameters.Add(ErrorInformation);
					CallParameters.Add(Parameters);
					
					Common.ExecuteConfigurationMethod(ThreadDetails.OnAbnormalTermination, CallParameters);
				Else
					Raise;
				EndIf;
			EndTry;
		EndIf;
		
		If JobID = Undefined Or JobCompleted <> False Then
			ExecuteJob = Not IsBlankString(ThreadDetails.CompletionProcedure)
			          AND Thread.CompletionProcedureParameters <> Undefined
			          AND (JobID = Undefined Or JobCompleted = True);
			
			If ExecuteJob Then
				CallParameters = New Array;
				CallParameters.Add(Thread.CompletionProcedureParameters);
				CallParameters.Add(Thread.ResultAddress);
				CallParameters.Add(Parameters);
				
				Common.ExecuteConfigurationMethod(ThreadDetails.CompletionProcedure, CallParameters);
			EndIf;
			
			DeleteFromTempStorage(Thread.ResultAddress);
			Threads.Delete(Thread);
			HasCompletedThreads = True;
		EndIf;
		
		Index = Index - 1;
	EndDo;
	
	Return HasCompletedThreads;
	
EndFunction

// Waits for completion of all threads.
//
// Parameters:
//  ThreadsDetails - Structure - a collection of threads (see NewThreadsDetails()).
//  Parameters - Arbitrary - parameters of the calling thread to be passed to the completion procedure.
//
Procedure WaitForAllThreadsCompletion(ThreadsDetails, Parameters = Undefined)
	
	Threads = ThreadsDetails.Threads;
	
	While Threads.Count() > 0 Do
		If Not StopThreadsWithCompletedBackgroundJobs(ThreadsDetails, Parameters) Then
			WaitForThreadCompletion(Threads[0]);
		EndIf;
	EndDo;
	
EndProcedure

// Waits for completion of any thread.
//
// Parameters:
//  ThreadsDetails - Structure - a collection of threads (see NewThreadsDetails()).
//  Parameters - Arbitrary - parameters of the calling thread to be passed to the completion procedure.
//
Procedure WaitForAnyThreadCompletion(ThreadsDetails, Parameters = Undefined)
	
	Threads = ThreadsDetails.Threads;
	ThreadsCount = Threads.Count();
	
	While ThreadsCount > 0 AND Threads.Count() >= ThreadsCount Do
		If Not StopThreadsWithCompletedBackgroundJobs(ThreadsDetails, Parameters) Then
			WaitForThreadCompletion(Threads[0]);
		EndIf;
	EndDo;
	
EndProcedure

// Waits until the number of active threads drops below the maximum limit.
//
// Parameters:
//  ThreadsDetails - Structure - a collection of threads (see NewThreadsDetails()).
//  Parameters - Arbitrary - parameters of the calling thread to be passed to the completion procedure.
//
Procedure WaitForAvailableThread(ThreadsDetails, Parameters = Undefined)
	
	MaxThreads = InfobaseUpdateThreadCount();
	Threads = ThreadsDetails.Threads;
	
	While Threads.Count() >= MaxThreads Do
		If StopThreadsWithCompletedBackgroundJobs(ThreadsDetails, Parameters) Then
			Continue;
		EndIf;
		
		WaitForThreadCompletion(Threads[0]);
		MaxThreads = InfobaseUpdateThreadCount();
	EndDo;
	
EndProcedure

// Terminates active threads.
//
// Parameters:
//  ThreadsDetails - Structure - a collection of threads (see NewThreadsDetails()).
//  CancellationParameters - Arbitrary - parameters of the OnCancelThread procedure.
//
Procedure CancelAllThreadsExecution(ThreadsDetails, CancellationParameters = Undefined) Export
	
	If ThreadsDetails <> Undefined Then
		Threads = ThreadsDetails.Threads;
		Groups = ThreadsDetails.Folders;
		
		If Threads <> Undefined Then
			ThreadsToDelete = New Array;
			Index = 0;
			
			While Index < Threads.Count() Do
				Thread = Threads[Index];
				ThreadDetails = Groups[Thread.Group];
				
				If Thread.JobID <> Undefined Then
					TimeConsumingOperations.CancelJobExecution(Thread.JobID);
				EndIf;
				
				If ThreadDetails.OnCancelThread <> Undefined Then
					CallParameters = New Array;
					CallParameters.Add(Thread);
					CallParameters.Add(CancellationParameters);
					Common.ExecuteConfigurationMethod(ThreadDetails.OnCancelThread, CallParameters);
				EndIf;
				
				ThreadsToDelete.Add(Thread);
				Index = Index + 1;
			EndDo;
			
			For each ThreadToDelete In ThreadsToDelete Do
				Threads.Delete(ThreadToDelete);
			EndDo;
		EndIf;
	EndIf;
	
EndProcedure

// Description of a group of threads.
//
// Returns:
//  Structure - common thread details with the following fields:
//   * Procedure - String - the name of the procedure executing in the background job. Declaration:
//                 ProcedureName(ProcedureDetails, ResultAddress), where:
//                  ** ProcedureDetails - Structure - details of the filling procedure.
//                  ** ResultAddress - String - an address of the temporary storage for storing the result.
//   * CompletionProcedure - String -  the name of the procedure executing after the background job has completed. Declaration:
//                           CompletionProcedure(ProcedureDetails, ResultAddress, AdditionalParameters), where:
//                            ** ProcedureDetails - Structure - details of the filling procedure.
//                            ** ResultAddress - String - address of the temporary storage used to store the result.
//                            ** AdditionalParameters - Arbitrary - the additional parameter.
//   * OnAbnormalTermination - String - the thread abonrmal termination handler. Declaration:
//                              OnAbnormalTermination(Thread, ErrorInformation, AdditionalParameters), where:
//                               ** Thread - ValueTableRow - description of the thread (see NewThreadsDetails()).
//                               ** ErrorInformation - ErrorInformation - an error description.
//                               ** AdditionalParameters - Arbitrary - the additional parameter.
//   * OnCancelThread - String - the thread cancelation handler. Declaration:
//                       OnCancelThread(Thread, AdditionalParameters), where:
//                        ** Thread - ValueTableRow - description of the thread (see NewThreadsDetails()).
//                        ** AdditionalParameters - Arbitrary - the additional parameter.
//
Function NewThreadsGroupDetails()
	
	Details = New Structure;
	Details.Insert("Procedure");
	Details.Insert("CompletionProcedure");
	Details.Insert("OnAbnormalTermination");
	Details.Insert("OnCancelThread");
	
	Return Details;
	
EndFunction

// Description of a group of threads.
//
// Returns:
//  * Groups - Map - a thread group details, where:
//    ** Key - String - a group name.
//    ** Value - Structure - see NewThreadsGroupDetails(). 
//  * Threads - ValueTable - description of the threads containing the following columns:
//    ** Description - String - arbitrary name of the thread (used in the description of the background job).
//    ** Group - String - name of the group with thread details.
//    ** JobID - UUID - unique ID of the background job.
//    ** ProcedureParameters - Arbitrary - parameters for Procedure.
//    ** CompletionProcedureParameters - Arbitrary - parameters for CompletionProcedure.
//    ** ResultAddress - String - an address of the temporary storage for storing the background job result.
//
Function NewThreadsDetails()
	
	Threads = New ValueTable;
	Columns = Threads.Columns;
	Columns.Add("Description");
	Columns.Add("Group");
	Columns.Add("CompletionPriority", New TypeDescription("Number"));
	Columns.Add("JobID");
	Columns.Add("ProcedureParameters");
	Columns.Add("CompletionProcedureParameters");
	Columns.Add("ResultAddress");
	
	Details = New Structure;
	Details.Insert("Folders", New Map);
	Details.Insert("Threads", Threads);
	
	Return Details;
	
EndFunction

// Waits the specified duration for a thread to stop.
//
// Parameters:
//   Thread - ValueTableRow - the thread.
//   Duration - Number - timeout duration, in seconds.
//
// Returns:
//  Boolean - True if the thread has stopped, False if the thread is still running.
//
Function WaitForThreadCompletion(Thread, Duration = 1)
	
	If Thread.JobID <> Undefined Then
		Job = BackgroundJobs.FindByUUID(Thread.JobID);
		
		If Job <> Undefined Then
			Try
				Job.WaitForCompletion(Duration);
				Return True;
			Except
				// No special processing is required. Perhaps the exception was raised because a time-out occurred.
				Return False;
			EndTry;
		EndIf;
	EndIf;
	
	Return True;
	
EndFunction

////////////////////////////////////////////////////////////////////////////////
// Multithread execution mechanism of the update handler.

// Find a data batch for the update handler thread.
//
// Parameters:
//  SearchParameters - Structure - see NewBatchSearchParameters(). 
//  ResultAddress - String - an address of the procedure execution result. A value table is returned.
//
Procedure FindBatchToUpdate(SearchParameters, ResultAddress) Export
	
	SelectionParameters = SearchParameters.SelectionParameters;
	CheckSelectionParameters(SelectionParameters);
	SelectionParameters.MaxSelection = InfobaseUpdate.MaxRecordsCountInSelection();
	OrderFields = OrderingFieldsOnSearchBatches(SearchParameters);
	SelectionParameters.OrderFields = OrderFields;
	SelectionParameters.OptimizeSelectionByPages = Not HasOrderingByExternalTables(OrderFields);
	Max = InfobaseUpdate.MaxRecordsCountInSelection();
	IterationParameters = DataIterationParametersForUpdate(SearchParameters);
	Iterator = CurrentIterationParameters(IterationParameters);
	SearchResult = NewBatchSearchResult();
	DataSet = NewDataSetForUpdate();
	SearchResult.DataSet = DataSet;
	SelectionParameters = SearchParameters.SelectionParameters;
	AdditionalDataSources = SelectionParameters.AdditionalDataSources;
	Queue = SearchParameters.Queue;
	
	While Iterator <> Undefined Do
		RefObject = Iterator.RefObject;
		TabularObject = Iterator.TabularObject;
		SetSelectionStartBorder(SearchParameters, Iterator.RefIndex, Iterator.TabularIndex);
		SetSelectionEndBorder(SearchParameters, RefObject, TabularObject);
		MaxSelection = SelectionParameters.MaxSelection;
		SelectionParameters.AdditionalDataSources = InfobaseUpdate.DataSources(
			AdditionalDataSources,
			RefObject,
			TabularObject);
		Data = SelectBatchData(SelectionParameters, Queue, RefObject, TabularObject);
		Count = Data.Count();
		SearchResult.Count = SearchResult.Count + Count;
		SelectionParameters.MaxSelection = SelectionParameters.MaxSelection - Count;
		
		If Count > 0 Then
			SetRecord = DataSet.Add();
			SetRecord.RefObject = RefObject;
			SetRecord.TabularObject = TabularObject;
			SetRecord.Data = Data;
		EndIf;
		
		If SearchResult.Count < Max Then
			NextIterationParameters(IterationParameters, Count = MaxSelection);
			Iterator = CurrentIterationParameters(IterationParameters);
		Else
			Break;
		EndIf;
	EndDo;
	
	SelectionParameters.AdditionalDataSources = AdditionalDataSources;
	SearchResult.SearchCompleted = (Iterator = Undefined);
	PutToTempStorage(SearchResult, ResultAddress);
	
EndProcedure

// Check the correctness of filling the update handler data selection parameters.
//
// Parameters:
//   SelectionParameters - Structure - see
//                      InfobaseUpdate.AdditionalMultithreadProcessingDataSelectionParameters().
//
Procedure CheckSelectionParameters(SelectionParameters)
	
	SelectionMethod = SelectionParameters.SelectionMethod;
	KnownMethod = (SelectionMethod = InfobaseUpdate.SelectionMethodOfIndependentInfoRegistryMeasurements())
	              Or (SelectionMethod = InfobaseUpdate.RegisterRecordersSelectionMethod())
	              Or (SelectionMethod = InfobaseUpdate.RefsSelectionMethod());
	If Not KnownMethod Then
		MessageTemplate = NStr(
			"ru = 'Укажите способ выборки в процедуре регистрации данных к обновлению.
			|Указывается в ""Параметры.ПараметрыВыборки.СпособВыборки"".
			|Сейчас указан неизвестный способ выборки ""%1"".'; 
			|en = 'Invalid selection method value in the update data registration procedure:
			|%1.
			|Specify a valid value in Parameters.SelectionParameters.SelectionMethod.'; 
			|pl = 'Określ metodę wyboru w procedurze rejestracji danych w celu aktualizacji.
			|Podawano w ""Parameters.SelectionParameters.SelectionMethod"".
			|Teraz określono nieznaną metodę wyboru ""%1"".';
			|de = 'Geben Sie die Stichprobenmethode im Datenprotokollierungsverfahren für die Aktualisierung an.
			|Angegeben unter ""Parameters.SelectionParameters.SelectionMethod"".
			|Es wird nun eine unbekannte Abtastmethode angegeben ""%1"".';
			|ro = 'Indicați modul de selectare în procedura de înregistrare a datelor spre actualizare.
			|Se indică în ""Parameters.SelectionParameters.SelectionMethod"".
			|Acum este indicat modul de selectare necunoscut ""%1"".';
			|tr = 'Güncellenecek veri kayıt prosedüründeki seçme yöntemini belirleyin. 
			| ""Parameters.SelectionParameters.SelectionMethod"" ''de belirtilir. 
			| Şu anda bilinmeyen seçme yöntemi ""%1"" belirtildi.'; 
			|es_ES = 'Indique el modo de seleccionar en el procedimiento de registro de datos para la actualización.
			|Se indica en ""Parameters.SelectionParameters.SelectionMethod"".
			|Ahora se ha indicado un modo de selección desconocido ""%1"".'");
		Raise StringFunctionsClientServer.SubstituteParametersToString(MessageTemplate, SelectionMethod);
	EndIf;
	
	TablesSpecified = Not IsBlankString(SelectionParameters.FullNamesOfObjects)
	             Or Not IsBlankString(SelectionParameters.FullRegistersNames);
	If Not TablesSpecified Then
		Raise NStr(
			"ru = 'Укажите обрабатываемые таблицы в процедуре регистрации данных к обновлению.
			|Указывается в ""Параметры.ПараметрыВыборки.ПолныеИменаОбъектов"" и/или
			|""Параметры.ПараметрыВыборки.ПолныеИменаРегистров"".'; 
			|en = 'The update data registration procedure requires tables to process.
			|Specify tables in Parameters.SelectionParameters.FullNamesOfObjects or
			|Parameters.SelectionParameters.FullNamesOfRegisters, or both.'; 
			|pl = 'Określ przetworzone tabele w procedurze rejestracji danych dla aktualizacji.
			|Podawano w ""Параметры.ПараметрыВыборки.ПолныеИменаОбъектов"" i/lub
			|""Параметры.ПараметрыВыборки.ПолныеИменаРегистров"".';
			|de = 'Geben Sie die Tabellen an, die im Datenprotokollierungsverfahren für die Aktualisierung verarbeitet werden sollen.
			|Angegeben unter ""Parameter.AuswahlDerParameter.Vollständige Objektnamen"" und/oder
			| ""Parameter.AuswahlDerParameter.VollständigeRegisterNamen"".';
			|ro = 'Indicați tabelele procesate în procedura de înregistrare a datelor pentru actualizare.
			|Se indică în ""Параметры.ПараметрыВыборки.ПолныеИменаОбъектов"" și/sau
			|""Параметры.ПараметрыВыборки.ПолныеИменаРегистров"".';
			|tr = 'Güncellenecek verilerin kayıt prosedüründe işlenen tabloları belirtin. 
			| ""Parametreler.SeçmeParametreleri.NesnelerinTamİsimleri"" ve/veya 
			|""Parametreler.SeçmeParametreleri.KaydedicilerinTamİsimleri"" ''de belirtilir.'; 
			|es_ES = 'Indique las tablas procesadas en el procedimiento de registro de datos para la actualización.
			| Se indica en ""Параметры.ПараметрыВыборки.ПолныеИменаОбъектов"" y/o
			|""Параметры.ПараметрыВыборки.ПолныеИменаРегистров"".'");
	EndIf;
	
EndProcedure

// Set a border of batch selection start.
//
// Parameters:
//  SearchParameters - Structure - see NewBatchSearchParameters(). 
//  RefIndex - Number - an iteration number by reference objects.
//  TabularIndex - Number - an iteration number by tabular objects.
//
Procedure SetSelectionStartBorder(SearchParameters, RefIndex, TabularIndex)
	
	SelectionParameters = SearchParameters.SelectionParameters;
	LastSelectedRecord = SearchParameters.LastSelectedRecord;
	FirstRecord = SearchParameters.FirstRecord;
	
	If RefIndex = 0 AND TabularIndex = 0 Then // A first page in the selection cycle is selected.
		SelectionParameters.LastSelectedRecord = LastSelectedRecord;
		SelectionParameters.FirstRecord = FirstRecord;
	Else // The following pages in the selection cycle are selected (always in a new object, that is why first).
		SelectionParameters.LastSelectedRecord = Undefined;
		SelectionParameters.FirstRecord = Undefined;
	EndIf;
	
EndProcedure

// Set a border of batch selection end.
//
// Parameters:
//  SearchParameters - Structure - see NewBatchSearchParameters(). 
//  RefObject - String - full name of a reference metadata object.
//  TabularObject - String - full name of a tabular metadata object.
//
Procedure SetSelectionEndBorder(SearchParameters, RefObject, TabularObject)
	
	SelectionParameters = SearchParameters.SelectionParameters;
	LatestRecord = SearchParameters.LatestRecord;
	IsLastObject = LatestRecord <> Undefined
	                   AND RefObject = LatestRecord[0].Value
	                   AND TabularObject = LatestRecord[1].Value;
	
	If IsLastObject Then // The last object in the metadata iteration cycle (end of selection).
		SelectionParameters.LatestRecord = LatestRecord;
	Else // Intermediate selection.
		SelectionParameters.LatestRecord = Undefined;
	EndIf;
	
EndProcedure

// Select these batches in the specified way.
//
// Parameters:
//  SelectionParameters - Structure - see
//                     InfobaseUpdate.AdditionalMultithreadProcessingDataSelectionParameters().
//  Queue - Number - a queue number.
//  RefObject - String - full name of a reference metadata object.
//  TabularObject - String - full name of a tabular metadata object.
//
// Returns:
//  ValueTable - a batch data.
//
Function SelectBatchData(SelectionParameters, Queue, RefObject, TabularObject)
	
	SelectionMethod = SelectionParameters.SelectionMethod;
	
	If SelectionMethod = InfobaseUpdate.SelectionMethodOfIndependentInfoRegistryMeasurements() Then
		Data = InfobaseUpdate.SelectStandaloneInformationRegisterDimensionsToProcess(
			Queue,
			TabularObject,
			SelectionParameters);
	ElsIf SelectionMethod = InfobaseUpdate.RegisterRecordersSelectionMethod() Then
		Data = InfobaseUpdate.SelectRegisterRecordersToProcess(
			Queue,
			?(IsBlankString(RefObject), Undefined, RefObject),
			TabularObject,
			SelectionParameters);
	ElsIf SelectionMethod = InfobaseUpdate.RefsSelectionMethod() Then
		Data = InfobaseUpdate.SelectRefsToProcess(
			Queue,
			RefObject,
			SelectionParameters);
	EndIf;
	
	Return Data;
	
EndFunction

// Prepare data iteration parameters for the update.
// It means to find the selection beginning boundary (the place where you stopped last time).
//
// Parameters:
//  SearchParameters - Structure - see NewBatchSearchParameters(). 
//
// Returns:
//  Structure - search parameters with the following fields:
//   RefObjects - Array - names of reference metadata objects.
//   TabularObjectsAll - Array - names of tabular metadata objects.
//   TabularObjectsBeginning - Array - names of tabular metadata objects at the first iteration.
//
Function DataIterationParametersForUpdate(SearchParameters)
	
	LastSelectedRecord = SearchParameters.LastSelectedRecord;
	FirstRecord = SearchParameters.FirstRecord;
	SelectionParameters = SearchParameters.SelectionParameters;
	FullNamesOfObjects = SelectionParameters.FullNamesOfObjects;
	FullRegistersNames = SelectionParameters.FullRegistersNames;
	FullRegistersNamesStart = FullRegistersNames;
	
	If LastSelectedRecord <> Undefined Then // Continue selection by pages.
		FirstReferenced = LastSelectedRecord[0].Value;
		FirstTabular = LastSelectedRecord[1].Value;
	ElsIf FirstRecord <> Undefined Then // Duplicate selection (terminated abnormally).
		FirstReferenced = FirstRecord[0].Value;
		FirstTabular = FirstRecord[1].Value;
	Else // Selection start (first page selection).
		FirstReferenced = Undefined;
		FirstTabular = Undefined;
	EndIf;
	
	If Not IsBlankString(FullNamesOfObjects) AND Not IsBlankString(FirstReferenced) Then // Has reference objects.
		// Set the reference part of the selection start to that place where it stopped last time.
		Beginning = StrFind(FullNamesOfObjects, FirstReferenced);
		FullNamesOfObjects = Mid(FullNamesOfObjects, Beginning);
	EndIf;
	
	If Not IsBlankString(FullRegistersNamesStart) AND Not IsBlankString(FirstTabular) Then // Has tabular objects.
		// Set the tabular part of the selection start to that place where it stopped last time.
		Beginning = StrFind(FullRegistersNamesStart, FirstTabular);
		FullRegistersNamesStart = Mid(FullRegistersNamesStart, Beginning);
	EndIf;
	
	Result = New Structure;
	Result.Insert("RefObjects", StrSplitTrimAll(FullNamesOfObjects, ","));
	Result.Insert("TabularObjectsAll", StrSplitTrimAll(FullRegistersNames, ","));
	Result.Insert("TabularObjectsBeginning", StrSplitTrimAll(FullRegistersNamesStart, ","));
	Result.Insert("RefIndex", 0);
	Result.Insert("TabularIndex", 0);
	
	Return Result;
	
EndFunction

// Get the next batch of data iteration parameters for an update.
//
// Parameters:
//  IterationParameters - Structure - see DataIterationParametersForUpdate(). 
//
// Returns:
//  * Structure - iteration parameters of current iteration as a structure with the following fields:
//    ** RefObject - String - a reference object name.
//    ** TabularObject - String - a tabular object name.
//  * Undefined - if iteration is completed.
//
Function CurrentIterationParameters(IterationParameters)
	
	If IterationParameters.RefIndex < IterationParameters.RefObjects.Count() Then
		If IterationParameters.RefIndex = 0 Then
			TabularObjects = IterationParameters.TabularObjectsBeginning;
		Else
			TabularObjects = IterationParameters.TabularObjectsAll;
		EndIf;
		
		If IterationParameters.TabularIndex < TabularObjects.Count() Then
			RefObject = IterationParameters.RefObjects[IterationParameters.RefIndex];
			TabularObject = TabularObjects[IterationParameters.TabularIndex];
			
			Result = New Structure;
			Result.Insert("RefObject", RefObject);
			Result.Insert("TabularObject", TabularObject);
			Result.Insert("RefIndex", IterationParameters.RefIndex);
			Result.Insert("TabularIndex", IterationParameters.TabularIndex);
			
			Return Result;
		EndIf;
	EndIf;
	
	Return Undefined;
	
EndFunction

// Go to next selection parameters if no records with current parameters have been selected.
//
// Parameters:
//  IterationParameters - Structure - see DataIterationParametersForUpdate(). 
//  FullSelection - Boolean - True if maximum number of records was selected.
//  
Procedure NextIterationParameters(IterationParameters, FullSelection)
	
	If Not FullSelection Then
		If IterationParameters.RefIndex = 0 Then
			TabularObjects = IterationParameters.TabularObjectsBeginning;
		Else
			TabularObjects = IterationParameters.TabularObjectsAll;
		EndIf;
		
		If IterationParameters.TabularIndex = TabularObjects.UBound() Then
			IterationParameters.TabularIndex = 0;
			IterationParameters.RefIndex = IterationParameters.RefIndex + 1;
		Else
			IterationParameters.TabularIndex = IterationParameters.TabularIndex + 1;
		EndIf;
	EndIf;
	
EndProcedure

// Get ordering fields for the specified batch search parameters.
//
// Parameters:
//  SearchParameters - Structure - see NewBatchSearchParameters(). 
//
// Returns:
//  String - Array - ordering fields.
//
Function OrderingFieldsOnSearchBatches(SearchParameters)
	
	SelectionParameters = SearchParameters.SelectionParameters;
	Return ?(SearchParameters.ForceUpdate,
		SelectionParameters.OrderingFieldsOnProcessData,
		SelectionParameters.OrderingFieldsOnUserOperations);
	
EndFunction

// Defind if there is ordering by fields of the tables being attached.
//
// Parameters:
//  OrderingFields - Array - ordering fields.
//
// Returns:
//  Boolean - True indicates whether there are ordering by the joined tables fields.
//
Function HasOrderingByExternalTables(OrderFields)
	
	For each OrderField In OrderFields Do
		If StrFind(OrderField, ".") > 0 Then
			Return True;
		EndIf;
	EndDo;
	
	Return False;
	
EndFunction

// Get search result, split it in batches and start update threads.
//
// Parameters:
//  SearchParameters - Structure - see NewBatchSearchParameters(). 
//  ResultAddress - String - an address of the FindBatchToUpdate execution result.
//  UpdateInfo - Structure - see NewUpdateInfo(). 
//
Procedure EndSearchForBatchToUpdate(SearchParameters, ResultAddress, UpdateInfo) Export
	
	SearchResult = GetFromTempStorage(ResultAddress);
	ThreadsDetails = UpdateInfo.ThreadsDetails;
	HandlerContext = SearchParameters.HandlerContext;
	FillingProcedureDetails = UpdateInfo.DataToProcess[HandlerContext.HandlerName];
	BatchesToUpdate = FillingProcedureDetails.BatchesToUpdate;
	BatchID = SearchParameters.BatchID;
	HasID = BatchID <> Undefined;
	OldBatch = ?(HasID, BatchesToUpdate.Find(BatchID, "ID"), Undefined);
	IsFirstSearch = SearchParameters.LastSelectedRecord = Undefined
	               AND SearchParameters.FirstRecord = Undefined
	               AND SearchParameters.LatestRecord = Undefined;
	IsDuplicateSearch = SearchParameters.FirstRecord <> Undefined
	                  AND SearchParameters.LatestRecord <> Undefined;
	
	If IsFirstSearch Then
		SaveFirstSearchResult(SearchResult, FillingProcedureDetails);
		BatchesToUpdate = FillingProcedureDetails.BatchesToUpdate;
	ElsIf IsDuplicateSearch Then
		SaveRepeatedSearchResult(SearchResult, FillingProcedureDetails, BatchID);
	Else
		SaveSearchResult(SearchResult, FillingProcedureDetails);
	EndIf;
	
	If SearchResult.Count > 0 Then
		MaximumThreads = InfobaseUpdateThreadCount();
		AvailableThreads = MaximumThreads - ThreadsDetails.Threads.Count() + 1;
		Particles = SplitSearchResultIntoParticles(SearchResult, AvailableThreads);
		ParticlesCount = Particles.Count();
		
		For ParticleNumber = 0 To ParticlesCount - 1 Do
			Fragment = Particles[ParticleNumber];
			HasOldBatch = (ParticleNumber = 0 AND OldBatch <> Undefined);
			
			If HasOldBatch Then
				Batch = OldBatch;
				Fragment.ID = Batch.ID;
			Else
				Batch = BatchesToUpdate.Add();
				Batch.ID = Fragment.ID;
			EndIf;
			
			Batch.FirstRecord = Fragment.FirstRecord;
			Batch.LatestRecord = Fragment.LatestRecord;
			Batch.Processing = True;
			
			ProcessDataFragmentInThread(Fragment, ThreadsDetails, HandlerContext);
		EndDo;
	Else
		Fragment = NewBatchForUpdate();
		Fragment.DataSet = NewDataSetForUpdate();
		ProcessDataFragmentInThread(Fragment, ThreadsDetails, HandlerContext);
	EndIf;
	
	FillingProcedureDetails.BatchSearchInProgress = False;
	
EndProcedure

// Update batch search thread termination handler.
//
// Parameters:
//  Thread - ValueTableRow - description of the thread (see NewThreadsDetails()).
//  ErrorInformation - ErrorInformation - an error description.
//  UpdateInfo - Structure - see NewUpdateInfo(). 
//
Procedure OnBatchToImportSearchThreadAbnormalTermination(Thread, ErrorInformation, UpdateInfo) Export
	
	Details = UpdateInfo.DataToProcess[Thread.ProcedureParameters.HandlerName];
	Details.BatchSearchInProgress = False;
	
EndProcedure

// Update batch search thread cancel handler.
//
// Parameters:
//  Thread - ValueTableRow - description of the thread (see NewThreadsDetails()).
//  UpdateInfo - Structure - see NewUpdateInfo(). 
//
Procedure OnCancelSearchBatchToUpdate(Thread, UpdateInfo) Export
	
	Details = UpdateInfo.DataToProcess[Thread.ProcedureParameters.HandlerName];
	Details.BatchSearchInProgress = False;
	
EndProcedure

// Complete updating data of a multithread update handler.
// Delete processed data batch.
//
// Parameters:
//  HandlerContext - Structure - see NewHandlerContext(). 
//  UpdateInfo - Structure - see NewUpdateInfo(). 
//
Procedure CompleteMultithreadHandlerExecution(HandlerContext, UpdateInfo)
	
	FillingProcedureDetails = UpdateInfo.DataToProcess[HandlerContext.HandlerName];
	BatchesToUpdate = FillingProcedureDetails.BatchesToUpdate;
	
	If BatchesToUpdate <> Undefined Then
		DataToUpdate = HandlerContext.Parameters.DataToUpdate;
		
		If DataToUpdate <> Undefined Then
			Batch = BatchesToUpdate.Find(DataToUpdate.ID, "ID");
			
			If Batch <> Undefined Then
				BatchesToUpdate.Delete(Batch);
			EndIf;
		EndIf;
	EndIf;
	
EndProcedure

// Cancel updating data of a multithread update handler.
// Mark that the found data batch will have to be processed again.
//
// Parameters:
//  Thread - ValueTableRow - description of the thread (see NewThreadsDetails()).
//  UpdateHandler - ValueTreeRow - the update handler represented as a row of the handler tree.
//  UpdateInfo - Structure - see NewUpdateInfo(). 
//  
Procedure CancelUpdatingDataOfMultithreadHandler(Thread, UpdateHandler, UpdateInfo)
	
	FillingProcedureDetails = UpdateInfo.DataToProcess[UpdateHandler.HandlerName];
	BatchesToUpdate = FillingProcedureDetails.BatchesToUpdate;
	
	If BatchesToUpdate <> Undefined Then
		DataToUpdate = Thread.ProcedureParameters.Parameters.DataToUpdate;
		
		If DataToUpdate <> Undefined Then
			Batch = BatchesToUpdate.Find(DataToUpdate.ID, "ID");
			
			If Batch <> Undefined Then
				Batch.Processing = False;
			EndIf;
		EndIf;
	EndIf;
	
EndProcedure

// Save the first data search result for the multithread handler.
//
// Parameters:
//  SearchResult - Structure - see NewBatchSearchResult(). 
//  FillingProcedureDetails - Structure - see NewDataToProcessDetails(). 
//
Procedure SaveFirstSearchResult(SearchResult, FillingProcedureDetails)
	
	If SearchResult.Count > 0 Then
		LastSelectedRecord = LastDataSetRowRecordKey(SearchResult.DataSet);
		FillingProcedureDetails.LastSelectedRecord = LastSelectedRecord;
		
		If FillingProcedureDetails.BatchesToUpdate = Undefined Then
			FillingProcedureDetails.BatchesToUpdate = NewBatchesTableForUpdate();
		EndIf;
	Else
		FillingProcedureDetails.LastSelectedRecord = Undefined;
	EndIf;
	
	FillingProcedureDetails.SearchCompleted = SearchResult.SearchCompleted;
	
EndProcedure

// Save the result of repeated data search (after an error) for the multithread handler.
//
// Parameters:
//  SearchResult - Structure - see NewBatchSearchResult(). 
//  FillingProcedureDetails - Structure - see NewDataToProcessDetails(). 
//  BatchID - UUID - an ID of the batch, for which data was searched.
//
Procedure SaveRepeatedSearchResult(SearchResult, FillingProcedureDetails, BatchID)
	
	If SearchResult.Count = 0 Then
		BatchesToUpdate = FillingProcedureDetails.BatchesToUpdate;
		Batch = BatchesToUpdate.Find(BatchID, "ID");
		BatchesToUpdate.Delete(Batch);
	EndIf;
	
	FillingProcedureDetails.SearchCompleted = SearchResult.SearchCompleted;
	
EndProcedure

// Save a data search result for the multithread handler.
//
// Parameters:
//  SearchResult - Structure - see NewBatchSearchResult(). 
//  FillingProcedureDetails - Structure - see NewDataToProcessDetails(). 
//
Procedure SaveSearchResult(SearchResult, FillingProcedureDetails)
	
	If SearchResult.Count > 0 Then
		LastSelectedRecord = LastDataSetRowRecordKey(SearchResult.DataSet);
		FillingProcedureDetails.LastSelectedRecord = LastSelectedRecord;
	EndIf;
	
	FillingProcedureDetails.SearchCompleted = SearchResult.SearchCompleted;
	
EndProcedure

// Split found data into the specified number of batches.
//
// Parameters:
//  SearchResult - Structure - see NewBatchSearchResult(). 
//  ParticlesCount - Number - a number of particles to split the data into.
//
// Returns:
//  BatchesSet - see NewBatchesSetForUpdate(). 
//
Function SplitSearchResultIntoParticles(SearchResult, Val ParticlesCount)
	
	Particles = NewBatchesSetForUpdate();
	FoundDataSet = SearchResult.DataSet;
	FoundItemsCount = SearchResult.Count;
	ParticlesCount = ?(FoundItemsCount < ParticlesCount, 1, ParticlesCount);
	MaxBatchSize = Int(FoundItemsCount / ParticlesCount);
	ProcessedItemsCount = 0;
	
	For ParticleNumber = 1 To ParticlesCount Do // Items are split from the end of the found data set.
		Fragment = NewBatchForUpdate();
		Fragment.ID = New UUID;
		Fragment.DataSet = NewDataSetForUpdate();
		Fragment.LatestRecord = LastDataSetRowRecordKey(FoundDataSet);
		Particles.Insert(0, Fragment);
		DataSetIndex = FoundDataSet.Count() - 1;
		FreeJobsCount = ?(ParticleNumber = ParticlesCount,
			FoundItemsCount - ProcessedItemsCount,
			MaxBatchSize);
		
		While DataSetIndex >= 0 Do
			CurrentDataRow = FoundDataSet[DataSetIndex];
			CurrentData = CurrentDataRow.Data;
			CurrentCount = CurrentData.Count();
			ParticleData = Fragment.DataSet.Add();
			
			If CurrentCount <= FreeJobsCount Then
				FillPropertyValues(ParticleData, CurrentDataRow);
				FoundDataSet.Delete(DataSetIndex);
				FreeJobsCount = FreeJobsCount - CurrentCount;
				ProcessedItemsCount = ProcessedItemsCount + CurrentCount;
			Else
				FillPropertyValues(ParticleData, CurrentDataRow, "RefObject, TabularObject");
				StartCutting = CurrentCount - FreeJobsCount;
				ParticleData.Data = CutRowsFromValueTable(CurrentData, StartCutting, FreeJobsCount);
				ProcessedItemsCount = ProcessedItemsCount + FreeJobsCount;
				FreeJobsCount = 0;
			EndIf;
			
			If FreeJobsCount = 0 Then
				Break;
			Else
				DataSetIndex = DataSetIndex - 1;
			EndIf;
		EndDo;
		
		Fragment.FirstRecord = FirstDataSetRowRecordKey(Fragment.DataSet);
	EndDo;
	
	Return Particles;
	
EndFunction

// Cut a value table fragment into a new value table.
//
// Parameters:
//  Table - ValueTable - a table, from which rows are cut.
//  Start - Number - an index of the first row to be cut.
//  Count - Number - a number of rows to be cut.
//
// Returns:
//  ValueTable - cut rows as a new value table.
//
Function CutRowsFromValueTable(Table, Beginning, Count)
	
	NewTable = Table.CopyColumns();
	Index = Beginning + Count - 1;
	
	While Index >= Beginning Do
		NewString = NewTable.Add();
		OldRow = Table[Index];
		FillPropertyValues(NewString, OldRow);
		Table.Delete(OldRow);
		Index = Index - 1;
	EndDo;
	
	Return NewTable;
	
EndFunction

// Defines if the handler has batches that can be updated in the new thread.
//
// Parameters:
//  UpdateHandler - ValueTreeRow - the update handler represented as a row of the handler tree.
//  UpdateInfo - Structure - see NewUpdateInfo(). 
//  
Function HasBatchesForUpdate(UpdateHandler, UpdateInfo)
	
	Details = UpdateInfo.DataToProcess[UpdateHandler.HandlerName];
	
	If Details.BatchSearchInProgress Then
		Return False;
	Else
		If Details.BatchesToUpdate <> Undefined AND Details.BatchesToUpdate.Count() > 0 Then
			For each Batch In Details.BatchesToUpdate Do
				If Not Batch.Processing Then
					Return True;
				EndIf;
			EndDo;
			
			Return False;
		Else
			Return True;
		EndIf;
	EndIf;
	
EndFunction

// Get record key of the first data set row.
//
// Parameters:
//  DataSet - ValueTable - see NewDataSetForUpdate(). 
//
// Returns:
//  ValueTable - a record key.
//
Function FirstDataSetRowRecordKey(DataSet)
	
	FirstDataRow = DataSet[0];
	Return NewRecordKeyFromDataTable(FirstDataRow.RefObject,
		FirstDataRow.TabularObject,
		FirstDataRow.Data,
		0);
	
EndFunction

// Get record key of the last data set row.
//
// Parameters:
//  DataSet - ValueTable - see NewDataSetForUpdate(). 
//
// Returns:
//  ValueTable - a record key.
//
Function LastDataSetRowRecordKey(DataSet)
	
	LastDataRow = DataSet[DataSet.Count() - 1];
	Return NewRecordKeyFromDataTable(LastDataRow.RefObject,
		LastDataRow.TabularObject,
		LastDataRow.Data,
		LastDataRow.Data.Count() - 1);
	
EndFunction

// A table with batch details of data being updated.
//
// Returns:
//  ValueTable - details of batches with the following structure:
//   * ID - UUID - a batch ID.
//   * FirstRecord - ValueList - the first batch record, where:
//     ** Presentation - String - field name.
//     ** Value - Arbitrary - a key field value.
//   * LastRecord - ValueList - the last batch record, where:
//     ** Presentation - String - field name.
//     ** Value - Arbitrary - a key field value.
//   * Processed - Boolean - True if the data update thread is started.
//
Function NewBatchesTableForUpdate()
	
	Table = New ValueTable;
	Columns = Table.Columns;
	Columns.Add("ID", New TypeDescription("UUID"));
	Columns.Add("FirstRecord", New TypeDescription("ValueList"));
	Columns.Add("LatestRecord", New TypeDescription("ValueList"));
	Columns.Add("Processing", New TypeDescription("Boolean"));
	Table.Indexes.Add("ID");
	
	Return Table;
	
EndFunction

// Update handler details of data being processed (for UpdateInfo.DataToProcess).
//
// Parameters:
//  Multithread - Boolean - True if it is used for multithread update handler.
//  Background - Boolean - True if it is used for FillDeferredHandlerData().
//
// Returns:
//  Structure - details with the following fields:
//   * HandlerData - Map - data that is registered and processed by the update handler.
//   * BatchSearchInProgress - indicates that there is a thread that searches a data batch for update.
//   * SelectionParameters - Structure - see
//                        InfobaseUpdate.AdditionalMultithreadProcessingDataSelectionParameters().
//   * BatchesForUpdate - ValueTable - see NewBatchesTableForUpdate(). 
//   * LastSelectedRecord - ValueList - details of selection start in a page selection:
//     ** Presentation - String - field name.
//     ** Value - Arbitrary - a field value.
//   * SearchCompleted - Boolean - True, the search is completed.
//   * ProcessingCompleted - Boolean - indicates that the processing that is populated by the update handler is completed.
//   * HandlerName - String - the name of the update handler.
//   * Queue - Number - a number of the update handler queue.
//   * FillingProcedure - String - a name of the data filling procedure for an update.
//   * Status - String - a data processing status.
//
Function NewDataToProcessDetails(Multithread = False, Background = False) Export
	
	Details = New Structure;
	Details.Insert("HandlerData");
	
	If Multithread Then
		Details.Insert("BatchSearchInProgress", False);
		Details.Insert("SelectionParameters");
		Details.Insert("BatchesToUpdate");
		Details.Insert("LastSelectedRecord");
		Details.Insert("SearchCompleted", False);
	EndIf;
	
	If Background Then
		Details.Insert("HandlerName");
		Details.Insert("Queue");
		Details.Insert("FillingProcedure");
		Details.Insert("Status");
	EndIf;
	
	Return Details;
	
EndFunction

// A filter for the FindBatchToUpdate() procedure.
// If LastSelectedRecord is filled, the search of the first 10000 records after it is executed.
// Otherwise, records are searched between FirstRecord and LastRecord.
//
// Returns:
//  Structure - a filter with the following fields:
//   * BatchID - UUID - an ID of the batch, for which data is being searched.
//   * HandlerContext - Structure - see NewHandlerContext(). 
//   * LastSelectedRecord - ValueList - details of selection start in a page selection:
//     ** Presentation - String - field name.
//     ** Value - Arbitrary - a field value.
//   * FirstRecord - ValueList - the first batch record, where:
//     ** Presentation - String - field name.
//     ** Value - Arbitrary - a key field value.
//   * LastRecord - ValueList - the last batch record, where:
//     ** Presentation - String - field name.
//     ** Value - Arbitrary - a key field value.
//   * SelectionParameters - Structure - see
//                        InfobaseUpdate.AdditionalMultithreadProcessingDataSelectionParameters().
//   * Queue - Number - a handler queue number.
//
Function NewBatchSearchParameters()
	
	SearchParameters = New Structure;
	SearchParameters.Insert("BatchID");
	SearchParameters.Insert("HandlerName");
	SearchParameters.Insert("HandlerContext");
	SearchParameters.Insert("LastSelectedRecord");
	SearchParameters.Insert("FirstRecord");
	SearchParameters.Insert("LatestRecord");
	SearchParameters.Insert("SelectionParameters");
	SearchParameters.Insert("Queue");
	SearchParameters.Insert("ForceUpdate", False);
	
	Return SearchParameters;
	
EndFunction

// Data batch record key.
//
// Parameters:
//  RefObject - String - full name of a reference type metadata object.
//  TabularObject - String - full name of a tabular type metadata object.
//
// Returns:
//  ValueTable - a record key.
//
Function NewRecordKey(RefObject, TabularObject)
	
	RecordKey = New ValueList;
	RecordKey.Add(RefObject);
	RecordKey.Add(TabularObject);
	
	Return RecordKey;
	
EndFunction

// A batch record key from a table with data.
//
// Parameters:
//  RefObject - String - full name of a reference type metadata object.
//  TabularObject - String - full name of a tabular type metadata object.
//  Data - ValueTable - a batch data.
//  Index - Number -  a data row index to generate a key.
//
// Returns:
//  ValueTable - a record key.
//
Function NewRecordKeyFromDataTable(RefObject, TabularObject, Data, Index)
	
	RecordKey = NewRecordKey(RefObject, TabularObject);
	String = Data[Index];
	
	For each Column In Data.Columns Do
		ColumnName = Column.Name;
		RecordKey.Add(String[ColumnName], ColumnName);
	EndDo;
	
	Return RecordKey;
	
EndFunction

// A value table with data details for an update.
// It is the search result for an update.
//
// Returns:
//  ValueTable - details of batches with the following structure:
//   * RefObject - String - a reference metadata object name (it can be Undefined).
//   * TabularObject - String - a tabular metadata object name (it can be Undefined).
//   * Data - ValueTable - a selection from DBMS as a value table.
//
Function NewDataSetForUpdate()
	
	DataSet = New ValueTable;
	Columns = DataSet.Columns;
	Columns.Add("RefObject", New TypeDescription("String"));
	Columns.Add("TabularObject", New TypeDescription("String"));
	Columns.Add("Data", New TypeDescription("ValueTable"));
	
	Return DataSet;
	
EndFunction

// An array of data batch details for an update.
// Is a result of splitting the found data into particles.
//
// Returns:
//  Array - an array of structures (see NewBatchForUpdate()).
//
Function NewBatchesSetForUpdate()
	
	Return New Array;
	
EndFunction

// Data batch details for an update.
//
// Returns:
//  Structure - details of a batch with the following structure:
//   * ID - UUID - a batch ID.
//   * FirstRecord - ValueList - a key of the first batch record (see NewRecordKeyFromBatchData()).
//   * LastRecord - ValueList - a key of the last batch record (see NewRecordKeyFromBatchData()).
//   * DataSet - ValueTable - data set for update (see NewDataSetForUpdate()).
//
Function NewBatchForUpdate()
	
	Batch = New Structure;
	Batch.Insert("ID");
	Batch.Insert("FirstRecord");
	Batch.Insert("LatestRecord");
	Batch.Insert("DataSet");
	
	Return Batch;
	
EndFunction

// Batch search execution result.
//
// Returns:
//  Structure - search result with the following fields:
//   Count - Number - a number of selected records.
//   DataSet - ValueTable - see NewDataSetForUpdate(). 
//   SearchCompleted - Boolean - True if there is nothing to search.
//
Function NewBatchSearchResult()
	
	SearchResult = New Structure;
	SearchResult.Insert("Count", 0);
	SearchResult.Insert("DataSet");
	SearchResult.Insert("SearchCompleted", False);
	
	Return SearchResult;
	
EndFunction

// Find the first unprocessed batch (whose processing terminated abnormally).
//
// Parameters:
//  BatchesForUpdate - ValueTable - see NewBatchesTableForUpdate(). 
//
// Returns:
//  * ValueTableRow - found batch.
//  * Undefined - if there are no unprocessed batches.
//
Function FirstUnprocessedBatch(BatchesToUpdate)
	
	If BatchesToUpdate <> Undefined Then
		For each Batch In BatchesToUpdate Do
			If Not Batch.Processing Then
				Return Batch;
			EndIf;
		EndDo;
	EndIf;
	
	Return Undefined;
	
EndFunction

// The StrSplit substitute with the particles shortened on the left and right.
//
// Parameters:
//  String - String - separated string.
//  Separator - String - string items separator.
//  IncludeBlanks - Boolean - True if the blank strings are placed into the result.
//
// Returns:
//  Array - string items split by the separator.
//
Function StrSplitTrimAll(String, Separator, IncludeBlanks = True)
	
	Array = StrSplit(String, Separator, IncludeBlanks);
	
	For Index = 0 To Array.UBound() Do
		Array[Index] = TrimAll(Array[Index]);
	EndDo;
	
	Return Array;
	
EndFunction

// Determines whether the handler details is multithread.
//
// Returns:
//  Boolean - True if the details is multithread.
//
Function IsMultithreadHandlerDataDetails(Details)
	
	Return Details.Property("BatchesToUpdate");
	
EndFunction

////////////////////////////////////////////////////////////////////////////////
// INFOBASE UPDATE HANDLERS

// Transfers data from the DELETE information register to the SubsystemVersions information register.
//
Procedure MoveSubsystemVersionsToSharedData() Export
	
	BeginTransaction();
	
	Try
		
		If Common.DataSeparationEnabled() Then
			SharedDataArea = -1;
		Else
			SharedDataArea = 0;
		EndIf;
		
		QueryText =
		"SELECT
		|	DeleteSubsystemVersions.SubsystemName,
		|	DeleteSubsystemVersions.Version,
		|	DeleteSubsystemVersions.UpdatePlan
		|FROM
		|	InformationRegister.DeleteSubsystemVersions AS DeleteSubsystemVersions
		|WHERE
		|	DeleteSubsystemVersions.DataArea = &DataArea";
		
		Query = New Query(QueryText);
		Query.SetParameter("DataArea", SharedDataArea);
		Selection = Query.Execute().Select();
		While Selection.Next() Do
			
			Manager = InformationRegisters.SubsystemsVersions.CreateRecordManager();
			Manager.SubsystemName = Selection.SubsystemName;
			Manager.Version = Selection.Version;
			Manager.UpdatePlan = Selection.UpdatePlan;
			Manager.Write();
			
		EndDo;
		
		Set = InformationRegisters.DeleteSubsystemVersions.CreateRecordSet();
		Set.Filter.DataArea.Set(SharedDataArea);
		Set.Write();
		
		CommitTransaction();
		
	Except
		
		RollbackTransaction();
		Raise;
		
	EndTry;
	
EndProcedure

// Fills the IsMainConfiguration attribute value for SubsystemVersions information register records.
//
Procedure FillAttributeIsMainConfiguration() Export
	
	SetIBVersion(Metadata.Name, IBVersion(Metadata.Name), True);
	
EndProcedure

// Overwrites the current version of release notes (according to the SubsystemVersions register) 
// with the latest displayed version for all data area users.
//
Procedure SetReleaseNotesVersion() Export
	
	CurrentVersion = IBVersion(Metadata.Name);
	
	SetPrivilegedMode(True);
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	Users.IBUserID AS ID
	|FROM
	|	Catalog.Users AS Users
	|WHERE
	|	Users.Internal = FALSE
	|	AND Users.IBUserID <> &BlankID";
	Query.SetParameter("BlankID", CommonClientServer.BlankUUID());
	Selection = Query.Execute().Select();
	
	While Selection.Next() Do
		
		InfobaseUser = InfoBaseUsers.FindByUUID(Selection.ID);
		If InfobaseUser = Undefined Then
			Continue;
		EndIf;
		
		LatestVersion = SystemChangesDisplayLastVersion(InfobaseUser.Name);
		If LatestVersion <> Undefined Then
			Return;
		EndIf;
		
		LatestVersion = CurrentVersion;
		
		CompletedHandlers = Common.CommonSettingsStorageLoad("IBUpdate", 
			"CompletedHandlers", , , InfobaseUser.Name);
			
		If CompletedHandlers <> Undefined Then
			
			If CompletedHandlers.Rows.Count() > 0 Then
				Version = CompletedHandlers.Rows[CompletedHandlers.Rows.Count() - 1].Version;
				If Version <> "*" Then
					LatestVersion = Version;
				EndIf;
			EndIf;
			
		EndIf;
		
		Common.CommonSettingsStorageSave("IBUpdate",
			"SystemChangesDisplayLastVersion", LatestVersion, , InfobaseUser.Name);
	EndDo;
	
EndProcedure

// Sets the key of the DeferredIBUpdate scheduled job.
//
Procedure InstallScheduledJobKey() Export
	
	Filter = New Structure;
	Filter.Insert("Metadata", Metadata.ScheduledJobs.DeferredIBUpdate);
	Filter.Insert("Predefined", True);
	Jobs = ScheduledJobsServer.FindJobs(Filter);
	For Each Job In Jobs Do
		If ValueIsFilled(Job.Key) Then
			Continue;
		EndIf;
		Job.Key = Metadata.ScheduledJobs.DeferredIBUpdate.Key;
		Job.Write();
	EndDo;
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// AUXILIARY PROCEDURES AND FUNCTIONS

////////////////////////////////////////////////////////////////////////////////
// Common use

Procedure DisableAccessKeysUpdate(Value, SubsystemExists)
	If SubsystemExists Then
		ModuleAccessManagement = Common.CommonModule("AccessManagement");
		ModuleAccessManagement.DisableAccessKeysUpdate(Value);
	EndIf;
EndProcedure

Function DataUpdateModeInLocalMode()
	
	SetPrivilegedMode(True);
	Query = New Query;
	Query.Text = 
		"SELECT
		|	1 AS HasSubsystemVersions
		|FROM
		|	InformationRegister.SubsystemsVersions AS SubsystemsVersions
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	1
		|FROM
		|	InformationRegister.DeleteSubsystemVersions AS DeleteSubsystemVersions";
	
	BatchExecutionResult = Query.ExecuteBatch();
	If BatchExecutionResult[0].IsEmpty() AND BatchExecutionResult[1].IsEmpty() Then
		Return "InitialFilling";
	ElsIf BatchExecutionResult[0].IsEmpty() AND Not BatchExecutionResult[1].IsEmpty() Then
		Return "VersionUpdate"; // Support of update from SSL version 2.1.2.
	EndIf;
	
	Query = New Query;
	Query.Text = 
		"SELECT
		|	1 AS HasSubsystemVersions
		|FROM
		|	InformationRegister.SubsystemsVersions AS SubsystemsVersions
		|WHERE
		|	SubsystemsVersions.IsMainConfiguration = TRUE
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	1 AS HasSubsystemVersions
		|FROM
		|	InformationRegister.SubsystemsVersions AS SubsystemsVersions
		|WHERE
		|	SubsystemsVersions.SubsystemName = &BaseConfigurationName
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	1 AS HasSubsystemVersions
		|FROM
		|	InformationRegister.SubsystemsVersions AS SubsystemsVersions
		|WHERE
		|	SubsystemsVersions.IsMainConfiguration = TRUE
		|	AND SubsystemsVersions.SubsystemName = &BaseConfigurationName";
	Query.SetParameter("BaseConfigurationName", Metadata.Name);
	BatchExecutionResult = Query.ExecuteBatch();
	If BatchExecutionResult[0].IsEmpty() AND Not BatchExecutionResult[1].IsEmpty() Then
		Return "VersionUpdate"; // IsMainConfiguration attribute is not yet filled.
	EndIf;
	
	// Making decision based on the IsMainConfiguration attribute filled earlier
	Return ?(BatchExecutionResult[2].IsEmpty(), "MigrationFromAnotherApplication", "VersionUpdate");
	
EndFunction	

Function CanExecuteSeamlessUpdate(UpdateIterationsToCheck = Undefined) Export
	
	If UpdateIterationsToCheck = Undefined Then
		// Call mode intended for determining the full list of procedures for update handlers that require 
		// exclusive mode (without writing any messages to the event log).
		UpdateIterations = UpdateIterations();
	Else
		UpdateIterations = UpdateIterationsToCheck;
	EndIf;
	
	HandlerSeparationFilters = New Array;
	If NOT Common.SeparatedDataUsageAvailable() Then
		HandlerSeparationFilters.Add(False);
	EndIf;
	HandlerSeparationFilters.Add(True);
	
	// In the check mode, this parameter is ignored.
	MandatorySeparatedHandlers = InfobaseUpdate.NewUpdateHandlerTable();
	
	WriteToLog = Constants.WriteIBUpdateDetailsToEventLog.Get();
	HandlerProcedures = New Array;
	
	// Validating update handlers with the ExclusiveMode flag for configuration subsystems.
	For each UpdateIteration In UpdateIterations Do
		
		FilterParameters = HandlerFIlteringParameters();
		FilterParameters.UpdateMode = "Seamless";
		
		For each SeparationFlag In HandlerSeparationFilters Do
		
			FilterParameters.GetSeparated = SeparationFlag;
			
			HandlersTree = UpdateInIntervalHandlers(UpdateIteration.Handlers, UpdateIteration.PreviousVersion,
				UpdateIteration.Version, FilterParameters);
			If HandlersTree.Rows.Count() = 0 Then
				Continue;
			EndIf;
				
			If HandlersTree.Rows.Count() > 1 
				OR HandlersTree.Rows[0].Version <> "*" Then
				For Each VersionRow In HandlersTree.Rows Do
					If VersionRow.Version = "*" Then
						Continue;
					EndIf;
					For Each Handler In VersionRow.Rows Do
						HandlerProcedures.Add(Handler.Procedure);
					EndDo;
				EndDo;
			EndIf;
			
			If SeparationFlag 
				AND Common.DataSeparationEnabled() 
				AND NOT Common.SeparatedDataUsageAvailable() Then
				
				// When updating a shared infobase version, the exclusive mode for separated mandatory update 
				// handlers is controlled by a shared handler.
				Continue;
			EndIf;
			
			FoundHandlers = HandlersTree.Rows[0].Rows.FindRows(New Structure("ExclusiveMode", Undefined));
			For Each Handler In FoundHandlers Do
				HandlerProcedures.Add(Handler.Procedure);
			EndDo;
			
			// Calling the mandatory update handlers in check mode.
			For each Handler In HandlersTree.Rows[0].Rows Do
				If Handler.RegistrationVersion <> "*" Then
					HandlerProcedures.Add(Handler.Procedure);
					Continue;
				EndIf;
				
				HandlerParameters = New Structure;
				If Handler.HandlerManagement Then
					HandlerParameters.Insert("SeparatedHandlers", MandatorySeparatedHandlers);
				EndIf;
				HandlerParameters.Insert("ExclusiveMode", False);
				
				AdditionalParameters = New Structure;
				AdditionalParameters.Insert("WriteToLog", WriteToLog);
				AdditionalParameters.Insert("LibraryID", UpdateIteration.Subsystem);
				AdditionalParameters.Insert("HandlerExecutionProgress", Undefined);
				AdditionalParameters.Insert("InBackground", False);
				
				ExecuteUpdateHandler(Handler, HandlerParameters, AdditionalParameters);
				
				If HandlerParameters.ExclusiveMode = True Then
					HandlerProcedures.Add(Handler.Procedure);
				EndIf;
			EndDo;
			
		EndDo;
	EndDo;
	
	If UpdateIterationsToCheck = Undefined Then
		UpdateIterationsToCheck = HandlerProcedures;
		Return HandlerProcedures.Count() = 0;
	EndIf;
	
	If HandlerProcedures.Count() <> 0 Then
		MessageText = NStr("ru = 'Следующие обработчики не поддерживают обновление без установки монопольного режима:'; en = 'The following handlers support update in exclusive mode only:'; pl = 'Następujące programy przetwarzania nie obsługują aktualizacji bez ustanowienia trybu wyłączności:';de = 'Die folgenden Handler unterstützen keine Upgrades, ohne den Monopol-Modus einzustellen:';ro = 'Handlerii următori nu susțin actualizarea fără instalarea regimului monopol:';tr = 'Aşağıdaki işleyicileri tekel modu yüklemeden güncelleştirme desteklemez:'; es_ES = 'Los siguientes procesadores no admiten la actualización sin instalar el modo monopolio:'");
		MessageText = MessageText + Chars.LF;
		For Each HandlerProcedure In HandlerProcedures Do
			MessageText = MessageText + Chars.LF + HandlerProcedure;
		EndDo;
		WriteError(MessageText);
	EndIf;
	
	Return HandlerProcedures.Count() = 0;
	
EndFunction

Procedure CopyRowsToTree(Val DestinationRows, Val SourceRows, Val ColumnStructure)
	
	For each SourceRow In SourceRows Do
		FillPropertyValues(ColumnStructure, SourceRow);
		FoundRows = DestinationRows.FindRows(ColumnStructure);
		If FoundRows.Count() = 0 Then
			DestinationRow = DestinationRows.Add();
			FillPropertyValues(DestinationRow, SourceRow);
		Else
			DestinationRow = FoundRows[0];
		EndIf;
		
		CopyRowsToTree(DestinationRow.Rows, SourceRow.Rows, ColumnStructure);
	EndDo;
	
EndProcedure

Function GetUpdatePlan(Val LibraryID, Val VersionFrom, Val VersionTo)
	
	RecordManager = InformationRegisters.SubsystemsVersions.CreateRecordManager();
	RecordManager.SubsystemName = LibraryID;
	RecordManager.Read();
	If NOT RecordManager.Selected() Then
		Return Undefined;
	EndIf;
	
	PlanDetails = RecordManager.UpdatePlan.Get();
	If PlanDetails = Undefined Then
		
		Return Undefined;
		
	Else
		
		If PlanDetails.VersionFrom <> VersionFrom
			OR PlanDetails.VersionTo <> VersionTo Then
			
			// The update plan is outdated and cannot be applied to the current version.
			Return Undefined;
		EndIf;
		
		Return PlanDetails.Plan;
		
	EndIf;
	
EndFunction

// Disables the upadte handlers filled in the procedure.
// InfobaseUpdateOverridable.OnDetachUpdateHandlers.
//
// Parameters:
//  LibraryID - String - the configuration name or library ID.
//  HandlersToExecute  - ValueTree - the infobase update handlers.
//  IBMetadataVersion      - String - a metadata version. Only the handlers with versions matching 
//                                     the metadata version are detached.
//
Procedure DetachUpdateHandlers(LibraryID, HandlersToExecute, MetadataVersion, HandlerExecutionProgress)
	
	DetachableHandlers = New ValueTable;
	DetachableHandlers.Columns.Add("LibraryID");
	DetachableHandlers.Columns.Add("Procedure");
	DetachableHandlers.Columns.Add("Version");
	
	InfobaseUpdateOverridable.OnDetachUpdateHandlers(DetachableHandlers);
	
	// Searching for a tree row containing update handlers of version "*.
	LibraryHandlers = HandlersToExecute.Rows.Find("*", "Version", False);
	
	For Each DetachableHandler In DetachableHandlers Do
		
		// Checking whether the detachable handler belongs to the passed library.
		If LibraryID <> DetachableHandler.LibraryID Then
			Continue;
		EndIf;
		
		// Checking whether the handler is in the exception list.
		HandlerToExecute = HandlersToExecute.Rows.Find(DetachableHandler.Procedure, "Procedure", True);
		If HandlerToExecute <> Undefined AND HandlerToExecute.Version = "*"
			AND DetachableHandler.Version = MetadataVersion Then
			LibraryHandlers.Rows.Delete(HandlerToExecute);
			HandlerExecutionProgress.HandlerCountForVersion = HandlerExecutionProgress.HandlerCountForVersion - 1;
		ElsIf HandlerToExecute <> Undefined AND HandlerToExecute.Version <> "*"
			AND DetachableHandler.Version = MetadataVersion Then
			ExceptionText = NStr("ru='Обработчик обновления %1 не может быть отключен, 
										|так как он выполняется только при переходе на версию %2'; 
										|en = 'Update handler %1 cannot be detached
										|because it is only executed when updating to version %2.'; 
										|pl = 'Program przetwarzania aktualizacji %1 nie może być odłączony, 
										|ponieważ jest on wykonywany tylko podczas przejścia do wersji %2';
										|de = 'Der Update-Handler %1 kann nicht deaktiviert werden, 
										|da er nur beim Upgrade auf die Version ausgeführt wird %2';
										|ro = 'Handlerul de actualizare %1 nu poate fi dezactivat, 
										|deoarece el se execută numai la migrare la versiunea %2';
										|tr = 'Güncelleme işleyicisi, yalnızca %1 sürüme geçirilirken çalıştırıldığı 
										|için devre dışı bırakılamaz%2.'; 
										|es_ES = 'El procesador de la actualización %1 no puede estar desactivado, 
										|porque está ejecutado solo al cambiar para la versión %2'");
			ExceptionText = StringFunctionsClientServer.SubstituteParametersToString(ExceptionText, HandlerToExecute.Procedure, HandlerToExecute.Version);
			
			Raise ExceptionText;
		ElsIf HandlerToExecute = Undefined Then
			ExceptionText = NStr("ru='Отключаемый обработчик обновления %1 не существует'; en = 'Detachable update handler %1 does not exist.'; pl = 'Wyłączany moduł obsługi %1 nie istnieje';de = 'Deaktivierter Update-Anwender %1 existiert nicht';ro = 'Managerul de actualizare dezactivat %1 nu există';tr = 'Devre dışı güncelleme işleyicisi %1 mevcut değil'; es_ES = 'Manipulador de la actualización desactivado %1 no existe'");
			ExceptionText = StringFunctionsClientServer.SubstituteParametersToString(ExceptionText, DetachableHandler.Procedure);
			
			Raise ExceptionText;
		EndIf;
		
	EndDo;
	
EndProcedure

Procedure ExecuteUpdateHandler(Handler, Parameters, AdditionalParameters)
	
	WriteUpdateProgressInformation(Handler, AdditionalParameters.HandlerExecutionProgress, AdditionalParameters.InBackground);
	HandlerDetails = 
		PrepareUpdateProgressDetails(Handler, Parameters, AdditionalParameters.LibraryID);
	
	If Common.SubsystemExists("StandardSubsystems.PerformanceMonitor") Then
		ModulePerformanceMonitor = Common.CommonModule("PerformanceMonitor");
		MeasurementStart = ModulePerformanceMonitor.StartTimeMeasurement();
	EndIf;
	
	If Parameters <> Undefined Then
		HandlerParameters = New Array;
		HandlerParameters.Add(Parameters);
	Else
		HandlerParameters = Undefined;
	EndIf;
	
	TransactionActiveAtExecutionStartTime = TransactionActive();
	
	SubsystemExists = Common.SubsystemExists("StandardSubsystems.AccessManagement");
	DisableAccessKeysUpdate(True, SubsystemExists);
	Try
		SetUpdateHandlerParameters(Handler);
		Common.ExecuteConfigurationMethod(Handler.Procedure, HandlerParameters);
		SetUpdateHandlerParameters(Undefined);
		DisableAccessKeysUpdate(False, SubsystemExists);
	Except
		
		DisableAccessKeysUpdate(False, SubsystemExists);
		If AdditionalParameters.WriteToLog Then
			WriteUpdateProgressDetails(HandlerDetails);
		EndIf;
		
		HandlerName = Handler.Procedure + "(" + ?(HandlerParameters = Undefined, "", "Parameters") + ")";
		
		WriteError(StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'При вызове обработчика обновления:
					   |""%1""
					   |произошла ошибка:
					   |""%2"".'; 
					   |en = 'An error occurred while calling update handler
					   |%1:
					   |%2.
					   |'; 
					   |pl = 'Podczas wywołania programu przetwarzania aktualizacji:
					   |""%1""
					   |zaistniał błąd:
					   |""%2"".';
					   |de = 'Beim Aufruf des Update-Handlers:
					   |""%1""
					   | ist ein Fehler aufgetreten:
					   |""%2"".';
					   |ro = 'La apelarea handlerului de actualizare:
					   |""%1""
					   |s-a produs eroarea:
					   |""%2"".';
					   |tr = 'Güncelleştirme işleyicisi çağrıldığında: 
					   |""%1"" %2bir hata oluştu:
					   |"
".'; 
					   |es_ES = 'Al llamar el procesador de actualización:
					   |""%1""
					   | se ha producido un error:
					   |""%2"".'"),
			HandlerName,
			DetailErrorDescription(ErrorInfo())));
		
		Raise;
	EndTry;
	
	ValidateNestedTransaction(TransactionActiveAtExecutionStartTime, Handler.Procedure);
	
	If AdditionalParameters.WriteToLog Then
		WriteUpdateProgressDetails(HandlerDetails);
	EndIf;
	
	If Common.SubsystemExists("StandardSubsystems.PerformanceMonitor") Then
		ModulePerformanceMonitor = Common.CommonModule("PerformanceMonitor");
		ModulePerformanceMonitor.EndTechnologicalTimeMeasurement("UpdateHandlerRunTime." + HandlerDetails.Procedure, MeasurementStart);
	EndIf;
	
EndProcedure

Procedure ExecuteHandlersAfterInfobaseUpdate(Val UpdateIterations, Val WriteToLog, OutputUpdatesDetails, Val SeamlessUpdate)
	
	For Each UpdateIteration In UpdateIterations Do
		
		If WriteToLog Then
			Handler = New Structure();
			Handler.Insert("Version", "*");
			Handler.Insert("RegistrationVersion", "*");
			Handler.Insert("ExecutionMode", "Seamless");
			Handler.Insert("Procedure", UpdateIteration.MainServerModuleName + ".AfterUpdateInfobase");
			HandlerDetails =  PrepareUpdateProgressDetails(Handler, Undefined, UpdateIteration.Subsystem);
		EndIf;
		
		Try
			
			UpdateIteration.MainServerModule.AfterUpdateInfobase(
				UpdateIteration.PreviousVersion,
				UpdateIteration.Version,
				UpdateIteration.CompletedHandlers,
				OutputUpdatesDetails,
				NOT SeamlessUpdate);
				
		Except
			
			If WriteToLog Then
				WriteUpdateProgressDetails(HandlerDetails);
			EndIf;
			
			Raise;
			
		EndTry;
		
		If WriteToLog Then
			WriteUpdateProgressDetails(HandlerDetails);
		EndIf;
		
	EndDo;
	
EndProcedure

Function PrepareUpdateProgressDetails(Handler, Parameters, LibraryID, HandlerDeferred = False)
	
	HandlerDetails = New Structure;
	HandlerDetails.Insert("Library", LibraryID);
	If HandlerDeferred Then
		HandlerDetails.Insert("Version", Handler.VersionNumber);
		HandlerDetails.Insert("Procedure", Handler.HandlerName);
	Else
		HandlerDetails.Insert("Version", Handler.Version);
		HandlerDetails.Insert("Procedure", Handler.Procedure);
	EndIf;
	HandlerDetails.Insert("RegistrationVersion", Handler.RegistrationVersion);
	HandlerDetails.Insert("Parameters", Parameters);
	
	If HandlerDeferred Then
		HandlerDetails.Insert("ExecutionMode", "Deferred");
	ElsIf ValueIsFilled(Handler.ExecutionMode) Then
		HandlerDetails.Insert("ExecutionMode", Handler.ExecutionMode);
	Else
		HandlerDetails.Insert("ExecutionMode", "Exclusive");
	EndIf;
	
	If Common.DataSeparationEnabled()
	   AND Common.SeparatedDataUsageAvailable() Then
		
		ModuleSaaS = Common.CommonModule("SaaS");
		
		HandlerDetails.Insert("DataAreaValue",
			ModuleSaaS.SessionSeparatorValue());
		HandlerDetails.Insert("DataAreaUsage", True);
		
	Else
		
		HandlerDetails.Insert("DataAreaValue", -1);
		HandlerDetails.Insert("DataAreaUsage", False);
		
	EndIf;
	
	HandlerDetails.Insert("ValueAtStart", CurrentUniversalDateInMilliseconds());
	
	Return HandlerDetails;
	
EndFunction

Procedure WriteUpdateProgressDetails(HandlerDetails)
	
	Duration = CurrentUniversalDateInMilliseconds() - HandlerDetails.ValueAtStart;
	
	HandlerDetails.Insert("Completed", False);
	HandlerDetails.Insert("Duration", Duration / 1000); // In seconds
	
	WriteLogEvent(
		EventLogEventProtocol(),
		EventLogLevel.Information,
		,
		,
		Common.ValueToXMLString(HandlerDetails));
		
EndProcedure

Procedure ValidateNestedTransaction(TransactionActiveAtExecutionStartTime, HandlerName)
	
	EventName = EventLogEvent() + "." + NStr("ru = 'Выполнение обработчиков'; en = 'Execute handlers'; pl = 'Wykonywanie procedur obsługi';de = 'Anwender ausführen';ro = 'Executarea handlerelor';tr = 'İşleyiciler yürütülüyor'; es_ES = 'Manipuladores de ejecución'", Common.DefaultLanguageCode());
	If TransactionActiveAtExecutionStartTime Then
		
		If TransactionActive() Then
			// Checking the absorbed exceptions in handlers.
			Try
				Constants.UseSeparationByDataAreas.Get();
			Except
				CommentTemplate = NStr("ru = 'Ошибка выполнения обработчика обновления %1:
				|Обработчиком обновления было поглощено исключение при активной внешней транзакции.
				|При активных транзакциях, открытых выше по стеку, исключение также необходимо пробрасывать выше по стеку.'; 
				|en = 'Error while executing update handler %1:
				|The update handler intercepted an exception while an external transaction was active.
				|If active transactions are open at higher stack levels, the exceptions also must be passed to higher stack levels.'; 
				|pl = 'Błąd podczas wykonywania procedury obsługi aktualizacji %1:
				|Program obsługi aktualizacji przechwycił wyjątek podczas aktywacji transakcji zewnętrznej.
				|Jeśli aktywne transakcje są otwarte na wyższych poziomach, wyjątki muszą być również przekazywane do wyższych poziomów.';
				|de = 'Ausführungsfehler des Update-Handlers %1:
				|Der Update-Handler hat eine Ausnahme in Anspruch genommen, während eine externe Transaktion aktiv ist.
				|Wenn aktive Transaktionen oberhalb des Stapels geöffnet werden, sollte die Ausnahme auch über den Stapel geworfen werden.';
				|ro = 'Eroare de executare a handlerului de actualizare %1:
				|Handlerul de actualizare a absorbit excepția la tranzacția externă activă.
				|În tranzacții active, deschise mai sus pe stack, excepția de asemenea trebuie redirecționată mai sus pe stack.';
				|tr = 'İşleyici  
				|güncelleştirmesi yürütülürken bir hata oluştu: Güncelleme işleyicisi,  etkin dış işlem sırasında özel durumu absorbe etti. %1Yığının üstünde  açılmış etkin işlemlerin söz konusu olması durumunda, 
				|istisnanın da  yığının üzerine yerleştirilmesi gerekir.'; 
				|es_ES = 'Un error ejecutando el procesador de la actualización %1:
				| El procesador de actualización ha absorbido la excepción durante la transacción externa activa.
				|En el caso de las transacciones activas abiertas arriba de la pila, la excepción también tiene que ubicarse arriba de la pila.'");
				Comment = StringFunctionsClientServer.SubstituteParametersToString(CommentTemplate, HandlerName);
				
				WriteLogEvent(EventName, EventLogLevel.Error,,, Comment);
				Raise(Comment);
			EndTry;
		Else
			CommentTemplate = NStr("ru = 'Ошибка выполнения обработчика обновления %1:
			|Обработчиком обновления была закрыта лишняя транзакция, открытая ранее (выше по стеку).'; 
			|en = 'Error while executing update handler %1:
			|The update handler closed an excessive transaction that was opened earlier (at a higher stack level).'; 
			|pl = 'Błąd podczas wykonywania procedury obsługi aktualizacji %1:
			|Program obsługi aktualizacji zamknął nadmierną transakcję, która została wcześniej otwarta (na wyższym poziomie stosu).';
			|de = 'Ausführungsfehler des Update-Handlers %1:
			|Der Update-Handler schloss eine zusätzliche Transaktion, die zuvor geöffnet wurde (höher im Stapel).';
			|ro = 'Eroare de executare a handlerului de actualizare %1:
			|Handlerul de actualizare a închis tranzacția în exces, deschisă mai devreme (mai sus pe stack).';
			|tr = 'Güncelleme  işleyicisini 
			|yürütürken bir hata %1 oluştu: Güncelleştirmenin işleyicisi,  daha önce açılmış bir ek işlemi kapattı (yığında).'; 
			|es_ES = 'Ha ocurrido un error ejecutando el procesador de la actualización %1:
			| El procesador de la actualización ha cerrado una extra transacción previamente abierta (arriba en una pila).'");
			Comment = StringFunctionsClientServer.SubstituteParametersToString(CommentTemplate, HandlerName);
			
			WriteLogEvent(EventName, EventLogLevel.Error,,, Comment);
			Raise(Comment);
		EndIf;
	Else
		If TransactionActive() Then
			CommentTemplate = NStr("ru = 'Ошибка выполнения обработчика обновления %1:
			|Открытая внутри обработчика обновления транзакция осталась активной (не была закрыта или отменена).'; 
			|en = 'Error while executing update handler %1:
			|A transaction that was opened in the update handler is still active (as it was not committed or rolled back).'; 
			|pl = 'Błąd podczas wykonywania procedury obsługi aktualizacji%1:
			|Transakcja, która została otwarta w programie obsługi aktualizacji, jest nadal aktywna (ponieważ nie została zatwierdzona lub wycofana).';
			|de = 'Ausführungsfehler des Update-Handlers %1:
			|Die im Update-Handler geöffnete Transaktion blieb aktiv (wurde nicht geschlossen oder abgebrochen).';
			|ro = 'Eroare de executare a handlerului de actualizare %1:
			|Tranzacția din interiorul handlerului de actualizare a rămas activă (nu a fost închisă sau anulată).';
			|tr = 'Güncelleme işleyicisi 
			|yürütülürken bir hata oluştu: %1İşleyici içinde açılan işlem etkin kaldı (kapatılmadı veya iptal edilmedi).'; 
			|es_ES = 'Ha ocurrido un error ejecutando el procesador de la actualización %1:
			| La transacción abierta dentro del procesador de la actualización se ha quedado activa (no se ha cerrado o cancelado).'");
			Comment = StringFunctionsClientServer.SubstituteParametersToString(CommentTemplate, HandlerName);
			
			WriteLogEvent(EventName, EventLogLevel.Error,,, Comment);
			Raise(Comment);
		EndIf;
	EndIf;
	
EndProcedure

Procedure ValidateHandlerProperties(UpdateIteration)
	
	For each Handler In UpdateIteration.Handlers Do
		ErrorDescription = "";
		
		If IsBlankString(Handler.Version) Then
			
			If Handler.InitialFilling <> True Then
				ErrorDescription = NStr("ru = 'У обработчика не заполнено свойство Версия или свойство НачальноеЗаполнение.'; en = 'One of the following handler properties is blank: Version or InitialFilling.'; pl = 'W module obsługi nie wypełniono wersji właściwości InitialFilling.';de = 'Die Version oder InitialFilling wird in dem Anwender nicht ausgefüllt.';ro = 'Proprietatea Version sau InitialFilling nu este completată în handler.';tr = 'Sürüm veya İlkDoldurma özelliği işleyicide doldurulmadı.'; es_ES = 'La propiedad Versión o InitialFilling no está rellenada en el manipulador.'");
			EndIf;
			
		ElsIf Handler.Version <> "*" Then
			
			Try
				ZeroVersion = CommonClientServer.CompareVersions(Handler.Version, "0.0.0.0") = 0;
			Except
				ZeroVersion = False;
				ErrorDescription = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("ru = 'У обработчика неправильно заполнено свойство Версия: ""%1"".
					           |Правильный формат, например: ""2.1.3.70"".'; 
					           |en = 'The Version property of the handler has invalid value: %1.
					           |Valid version example: 2.1.3.70.'; 
					           |pl = 'W programie przetwarzania niepoprawnie wypełniono właściwość Wersja: ""%1"".
					           |Prawidłowy format, na przykład: ""2.1.3.70"".';
					           |de = 'Der Handler hat die Eigenschaft Version: ""%1"" falsch ausgefüllt.
					           |Korrektes Format, z.B: ""2.1.3.70"".';
					           |ro = 'La handler este completată incorect proprietatea Versiunea: ""%1"".
					           |Exemplu de format corect: ""2.1.3.70"".';
					           |tr = 'İşleyici Sürüm özelliği yanlış dolduruldu:""%1"". 
					           |Doğru biçim, örneğin: 21.3.70.'; 
					           |es_ES = 'Para el procesador está rellenado incorrectamente Versión: ""%1"".
					           |Formato correcto, por ejemplo: ""2.1.3.70"".'"),
					Handler.Version);
			EndTry;
			
			If ZeroVersion Then
				ErrorDescription = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("ru = 'У обработчика неправильно заполнено свойство Версия: ""%1"".
					           |Версия не может быть нулевой.'; 
					           |en = 'The Version property of the handler has invalid value: %1.
					           |Zero versions are not allowed.'; 
					           |pl = 'W programie przetwarzania niepoprawnie wypełniono właściwość Wersja: ""%1"".
					           |Wersja nie może być zerowa.';
					           |de = 'Der Handler hat die Eigenschaft Version: ""%1"" falsch ausgefüllt.
					           |Die Version darf nicht Null sein.';
					           |ro = 'La handler este completată incorect proprietatea Versiunea: ""%1"".
					           |Versiunea nu poate fi egală cu zero.';
					           |tr = 'İşleyici Sürüm özelliği yanlış dolduruldu: ""%1"".
					           | Sürüm sıfır olamaz.'; 
					           |es_ES = 'Para el procesador está rellenado incorrectamente Versión: ""%1"".
					           |La versión no puede ser nula.'"),
					Handler.Version);
			EndIf;
			
			If NOT ValueIsFilled(ErrorDescription)
			   AND Handler.ExecuteInMandatoryGroup <> True
			   AND Handler.Priority <> 0 Then
				
				ErrorDescription = NStr("ru = 'У обработчика неправильно заполнено свойство Приоритет или
				                            |свойство ВыполнятьВГруппеОбязательных.'; 
				                            |en = 'One of the following handler properties has invalid value: Priority or
				                            |ExecuteInMandatoryGroup.'; 
				                            |pl = 'W programie przetwarzania niepoprawnie wypełniono właściwość Priority ytet lub
				                            |właściwość ExecuteInMandatoryGroup.';
				                            |de = 'Die Eigenschaft Priority oder
				                            |die Eigenschaft ExecuteInMandatoryGroup wurde vom Handler falsch ausgefüllt.';
				                            |ro = 'La handler este completată incorect proprietatea Priority sau
				                            |proprietatea ExecuteInMandatoryGroup.';
				                            |tr = 'Bir işleyicinin, Öncelik özelliği veya 
				                            |ExecuteInMandatoryGroup özelliği yanlış dolduruldu.'; 
				                            |es_ES = 'Para el procesador está rellenado incorrectamente Priority o 
				                            |la propiedad ExecuteInMandatoryGroup.'");
			EndIf;
		EndIf;
		
		If Handler.ExecutionMode <> ""
			AND Handler.ExecutionMode <> "Exclusive"
			AND Handler.ExecutionMode <> "Seamless"
			AND Handler.ExecutionMode <> "Deferred" Then
			ErrorDescription = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'У обработчика ""%1"" неправильно заполнено свойство РежимВыполнения.
				           |Допустимое значение: ""Монопольно"", ""Отложенно"", ""Оперативно"".'; 
				           |en = 'The ExecutionMode property of handler %1 has invalid value.
				           |Valid values are: ""Exclusive"", ""Deferred"", and ""Seamless.""'; 
				           |pl = 'W programie przetwarzania ""%1"" niepoprawnie wypełniono właściwość РежимВыполнения.
				           |Dopuszczalna wartość: ""Монопольно"", ""Отложенно"", ""Оперативно"".';
				           |de = 'Der Handler ""%1"" hat die Eigenschaft AusführungModus falsch ausgefüllt.
				           |Zulässiger Wert: ""Monopol"", "" Verzögert "", "" Operativ "".';
				           |ro = 'La handlerul ""%1"" este completată incorect proprietatea РежимВыполнения.
				           |Valoarea admisibilă: ""Monopol"", ""Amânat"", ""Operativ"".';
				           |tr = 'İşleyici Yürütme Modu özelliği işleyicide 
				           |yanlış dolduruldu. %1İzin verilen değer: Özel, Ertelenmiş, Çevrimiçi.'; 
				           |es_ES = 'Para el procesador ""%1"" está rellenada incorrectamente la propiedad РежимВыполнения.
				           |Valor admitido: ""Monopolio"", ""Aplazado"", ""Operativo"".'"),
				Handler.Procedure);
		EndIf;
		
		If NOT ValueIsFilled(ErrorDescription)
		   AND Handler.Optional = True
		   AND Handler.InitialFilling = True Then
			
			ErrorDescription = NStr("ru = 'У обработчика не правильно заполнено свойство Опциональный или
			                            |свойство НачальноеЗаполнение.'; 
			                            |en = 'One of the following handler properties has invalid value: Optional or
			                            |InitialFilling.'; 
			                            |pl = 'W programie przetwarzania nie poprawnie wypełniono właściwość Opcjonalny lub
			                            |właściwość InitialFilling.';
			                            |de = 'Der Handler hat die Eigenschaft Optional oder 
			                            |InitialFilling nicht korrekt ausgefüllt.';
			                            |ro = 'La handler este completată incorect proprietatea Opțional sau
			                            |proprietatea InitialFilling.';
			                            |tr = 'Opsiyonel veya İlkDoldurma özelliği 
			                            |işleyicide yanlış dolduruldu.'; 
			                            |es_ES = 'Para el procesador no está rellenado incorrectamente la propiedad Opcional o
			                            |la propiedad InitialFilling.'");
		EndIf;
			
		If Not ValueIsFilled(ErrorDescription) Then
			Continue;
		EndIf;
		
		If UpdateIteration.IsMainConfiguration Then
			ErrorTitle = NStr("ru = 'Ошибка в свойстве обработчика обновления конфигурации'; en = 'Configuration update handler property error'; pl = 'We właściwości konfiguracji modułu obsługi aktualizacji wystąpił błąd';de = 'In der Eigenschaft des Konfigurationsaktualisierungsanwenders ist ein Fehler aufgetreten';ro = 'Eroare în proprietatea handlerului de actualizare a configurației';tr = 'Yapılandırma güncelleme işleyicisinin özelliğinde bir hata oluştu'; es_ES = 'Ha ocurrido un error en la propiedad del manipulador de la actualización de la configuración'");
		Else
			ErrorTitle = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'Ошибка в свойстве обработчика обновления библиотеки %1 версии %2'; en = 'Error in a property of library %1 (version %2) update handler'; pl = 'We właściwości biblioteki modułu obsługi aktualizacji %1 wersji %2 wystąpił błąd';de = 'In der Eigenschaft des Bibliotheksupdate-Anwenders %1 der Version ist ein Fehler aufgetreten %2';ro = 'Eroare în proprietatea handlerului de actualizare a librăriei %1 de versiunea %2';tr = '%1Sürüm kütüphane güncelleme işleyicisi %2özelliğinde bir hata oluştu'; es_ES = 'Ha ocurrido un error en la propiedad del manipulador de la actualización de la biblioteca %1 de la versión %2'"),
				UpdateIteration.Subsystem,
				UpdateIteration.Version);
		EndIf;
		
		ErrorDescription = StringFunctionsClientServer.SubstituteParametersToString(
			ErrorTitle + Chars.LF
			+ NStr("ru = '(%1).'; en = '(%1).'; pl = '(%1).';de = '(%1).';ro = '(%1).';tr = '(%1).'; es_ES = '(%1).'") + Chars.LF
			+ Chars.LF
			+ ErrorDescription,
			Handler.Procedure);
		
		WriteError(ErrorDescription);
		Raise ErrorDescription;

	EndDo;
	
EndProcedure

Function HandlerCountForCurrentVersion(UpdateIterations, DeferredUpdateMode)
	
	HandlerCount = 0;
	
	// Exclusive update handlers.
	For Each UpdateIteration In UpdateIterations Do
		
		HandlersByVersion = UpdateInIntervalHandlers(
			UpdateIteration.Handlers, UpdateIteration.PreviousVersion, UpdateIteration.Version);
		For Each HandlersRowVersion In HandlersByVersion.Rows Do
			HandlerCount = HandlerCount + HandlersRowVersion.Rows.Count();
		EndDo;
		
	EndDo;
	
	UpdateInfo = InfobaseUpdateInfo();
	// Deferred update handlers.
	If DeferredUpdateMode = "Exclusive" Then
		DeferredUpdatePlan = UpdateInfo.DeferredUpdatePlan;
		For Each UpdateCycle In DeferredUpdatePlan Do
			HandlerCount = HandlerCount + UpdateCycle.Handlers.Count();
		EndDo;
	EndIf;
	
	// Parallel deferred update handler registration procedures.
	LibraryDetailsList = StandardSubsystemsCached.SubsystemsDetails().ByNames;
	If Common.SeparatedDataUsageAvailable() Then
		For Each RowLibrary In UpdateInfo.HandlersTree.Rows Do
			If LibraryDetailsList[RowLibrary.LibraryName].DeferredHandlerExecutionMode <> "Parallel" Then
				Continue;
			EndIf;
			For Each VersionRow In RowLibrary.Rows Do
				ParallelSinceVersion = LibraryDetailsList[RowLibrary.LibraryName].ParralelDeferredUpdateFromVersion;
				If VersionRow.VersionNumber = "*"
					Or (ValueIsFilled(ParallelSinceVersion)
						AND CommonClientServer.CompareVersions(VersionRow.VersionNumber, ParallelSinceVersion) < 0) Then
					Continue;
				EndIf;
				
				HandlerCount = HandlerCount + VersionRow.Rows.Count();
			EndDo;
		EndDo;
	EndIf;
	
	Return New Structure("TotalHandlerCount, CompletedHandlersCount", HandlerCount, 0);
	
EndFunction

Function MetadataObjectNameByManagerName(ManagerName)
	
	Position = StrFind(ManagerName, ".");
	If Position = 0 Then
		Return "CommonModule." + ManagerName;
	EndIf;
	ManagerType = Left(ManagerName, Position - 1);
	
	TypesNames = New Map;
	TypesNames.Insert("Catalogs", "Catalog");
	TypesNames.Insert("Documents", "Document");
	TypesNames.Insert("DataProcessors", "DataProcessor");
	TypesNames.Insert("ChartsOfCharacteristicTypes", "ChartOfCharacteristicTypes");
	TypesNames.Insert("AccountingRegisters", "AccountingRegister");
	TypesNames.Insert("AccumulationRegisters", "AccumulationRegister");
	TypesNames.Insert("CalculationRegisters", "CalculationRegister");
	TypesNames.Insert("InformationRegisters", "InformationRegister");
	TypesNames.Insert("BusinessProcesses", "BusinessProcess");
	TypesNames.Insert("DocumentJournals", "DocumentJournal");
	TypesNames.Insert("Tasks", "Task");
	TypesNames.Insert("Reports", "Report");
	TypesNames.Insert("Constants", "Constant");
	TypesNames.Insert("Enums", "Enum");
	TypesNames.Insert("ChartsOfCalculationTypes", "ChartOfCalculationTypes");
	TypesNames.Insert("ExchangePlans", "ExchangePlan");
	TypesNames.Insert("ChartsOfAccounts", "ChartOfAccounts");
	
	TypeName = TypesNames[ManagerType];
	If TypeName = Undefined Then
		Return ManagerName;
	EndIf;
	
	Return TypeName + Mid(ManagerName, Position);
EndFunction

Procedure SelectNewSubsystemHandlers(AllHandlers)
	
	// List of objects in new subsystems.
	NewSubsystemObjects = New Array;
	For Each SubsystemName In InfobaseUpdateInfo().NewSubsystems Do
		Subsystem = Metadata.FindByFullName(SubsystemName);
		If Subsystem = Undefined Then
			Continue;
		EndIf;
		For Each MetadataObject In Subsystem.Content Do
			NewSubsystemObjects.Add(MetadataObject.FullName());
		EndDo;
	EndDo;
	
	// Determines handlers in the new subsystems.
	AllHandlers.Columns.Add("IsNewSubsystem", New TypeDescription("Boolean"));
	For Each HandlerDetails In AllHandlers Do
		Position = StrFind(HandlerDetails.Procedure, ".", SearchDirection.FromEnd);
		ManagerName = Left(HandlerDetails.Procedure, Position - 1);
		If NewSubsystemObjects.Find(MetadataObjectNameByManagerName(ManagerName)) <> Undefined Then
			HandlerDetails.IsNewSubsystem = True;
		EndIf;
	EndDo;
	
EndProcedure

// See StandardSubsystemsServer.OnSendDataToSlave. 
Procedure OnSendSubsystemVersions(DataItem, ItemSending, Val InitialImageCreation = False)
	
	StandardProcessing = True;
	
	If Common.SubsystemExists("StandardSubsystems.SaaS.IBVersionUpdateSaaS") Then
		ModuleInfobaseUpdateInternalSaaS = Common.CommonModule("InfobaseUpdateInternalSaaS");
		ModuleInfobaseUpdateInternalSaaS.OnSendSubsystemVersions(DataItem, ItemSending, 
			InitialImageCreation, StandardProcessing);
	EndIf;
	
	If Not StandardProcessing Then
		Return;
	EndIf;
	
	If ItemSending = DataItemSend.Delete
		OR ItemSending = DataItemSend.Ignore Then
		
		// No overriding for standard data processor.
		
	ElsIf TypeOf(DataItem) = Type("InformationRegisterRecordSet.SubsystemsVersions") Then
		
		If Not InitialImageCreation Then
			
			// Exporting the register during the initial image creation only.
			ItemSending = DataItemSend.Ignore;
			
		EndIf;
		
	EndIf;
	
EndProcedure

Function UpdateStartMark()
	
	SessionDetails = New Structure;
	SessionDetails.Insert("ComputerName");
	SessionDetails.Insert("ApplicationName");
	SessionDetails.Insert("SessionStarted");
	SessionDetails.Insert("SessionNumber");
	SessionDetails.Insert("ConnectionNumber");
	SessionDetails.Insert("User");
	FillPropertyValues(SessionDetails, GetCurrentInfoBaseSession());
	SessionDetails.User = SessionDetails.User.Name;
	
	ParameterName = "StandardSubsystems.IBVersionUpdate.InfobaseUpdateSession";
	
	CanUpdate = True;
	
	Lock = New DataLock;
	If Common.DataSeparationEnabled()
		AND Common.SeparatedDataUsageAvailable() Then
		LockItem = Lock.Add("Constant.IBUpdateInfo");
	Else
		LockItem = Lock.Add("InformationRegister.ApplicationParameters");
		LockItem.SetValue("ParameterName", ParameterName);
	EndIf;
	
	BeginTransaction();
	Try
		Lock.Lock();
		SavedParameters = UpdateSessionInfo(ParameterName);
		
		If SavedParameters = Undefined Then
			SessionsMatch = False;
		Else
			SessionsMatch = DataMatch(SessionDetails, SavedParameters);
		EndIf;
		
		If Not SessionsMatch Then
			UpdateSessionActive = SessionActive(SavedParameters);
			If UpdateSessionActive Then
				UpdateSession = SavedParameters;
				CanUpdate = False;
			Else
				WriteUpdateSessionInfo(ParameterName, SessionDetails);
				UpdateSession = SessionDetails;
			EndIf;
		EndIf;
		
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;
	
	Result = New Structure;
	Result.Insert("CanUpdate", CanUpdate);
	Result.Insert("UpdateSession", UpdateSession);
	
	Return Result;
	
EndFunction

Function UpdateSessionInfo(ParameterName)
	If Common.DataSeparationEnabled()
		AND Common.SeparatedDataUsageAvailable() Then
		Info = InfobaseUpdateInfo();
		UpdateSession = Info.UpdateSession;
	Else
		UpdateSession = StandardSubsystemsServer.ApplicationParameter(ParameterName);
	EndIf;
	
	Return UpdateSession;
EndFunction

Procedure WriteUpdateSessionInfo(ParameterName, SessionDetails)
	If Common.DataSeparationEnabled()
		AND Common.SeparatedDataUsageAvailable() Then
		Info = InfobaseUpdateInfo();
		Info.UpdateSession = SessionDetails;
		WriteInfobaseUpdateInfo(Info);
	Else
		StandardSubsystemsServer.SetApplicationParameter(ParameterName, SessionDetails);
	EndIf;
EndProcedure

Function SessionActive(SessionDetails)
	If SessionDetails = Undefined Then
		Return False;
	EndIf;
	
	InfobaseSessions = GetInfoBaseSessions();
	
	For Each Session In InfobaseSessions Do
		Match = DataMatch(SessionDetails, Session);
		If Match Then
			Break;
		EndIf;
	EndDo;
	
	Return Match;
EndFunction

Function DataMatch(Data1, Data2)
	
	Match = True;
	For Each KeyAndValue In Data1 Do
		If KeyAndValue.Key = "User" Then
			Continue;
		EndIf;
		
		If Data2[KeyAndValue.Key] <> KeyAndValue.Value Then
			Match = False;
			Break;
		EndIf;
	EndDo;
	
	Return Match;
	
EndFunction

////////////////////////////////////////////////////////////////////////////////
// Logging the update progress.

Procedure WriteInformation(Val Text)
	
	EventLogOperations.AddMessageForEventLog(EventLogEvent(), EventLogLevel.Information,,, Text);
	
EndProcedure

Procedure WriteError(Val Text)
	
	EventLogOperations.AddMessageForEventLog(EventLogEvent(), EventLogLevel.Error,,, Text);
	
EndProcedure

Procedure WriteWarning(Val Text)
	
	EventLogOperations.AddMessageForEventLog(EventLogEvent(), EventLogLevel.Warning,,, Text);
	
EndProcedure

Procedure WriteUpdateProgressInformation(Handler, HandlerExecutionProgress, InBackground)
	
	If HandlerExecutionProgress = Undefined Then
		Return;
	EndIf;
	
	HandlerExecutionProgress.CompletedHandlersCount = HandlerExecutionProgress.CompletedHandlersCount + 1;
	
	If Not Common.DataSeparationEnabled() Then
		Message = NStr("ru = 'Выполняется обработчик обновления %1 (%2 из %3).'; en = 'Executing update handler %1 (%2 out of %3).'; pl = 'Trwa procedura aktualizacji %1 (%2 z %3).';de = 'Update-Anwender %1 ist in Bearbeitung (%2 von %3).';ro = 'Actualizarea handlerului %1 (%2 din %3) este în derulare.';tr = 'Güncelleme işleyicisi %1 devam ediyor (%2/%3).'; es_ES = 'Manipulador de la actualización %1 está en progreso (%2 de %3).'");
		Message = StringFunctionsClientServer.SubstituteParametersToString(
			Message, Handler.Procedure,
			HandlerExecutionProgress.CompletedHandlersCount, HandlerExecutionProgress.TotalHandlerCount);
		WriteInformation(Message);
	EndIf;
	
	If InBackground Then
		Progress = 10 + HandlerExecutionProgress.CompletedHandlersCount / HandlerExecutionProgress.TotalHandlerCount * 90;
		TimeConsumingOperations.ReportProgress(Progress);
	EndIf;
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Update details

// Displays update change description for a specified version.
//
// Parameters:
//  VersionNumber  - String - version number that is used to output the description from the 
//                          UpdateDetailsTemplate spreadsheet document template to the spreadsheet document.
//                          DocumentUpdateDetails.
//
Procedure OutputUpdateDetails(Val VersionNumber, DocumentUpdateDetails, UpdateDetailsTemplate)
	
	Number = StrReplace(VersionNumber, ".", "_");
	
	If UpdateDetailsTemplate.Areas.Find("Header" + Number) = Undefined Then
		Return;
	EndIf;
	
	DocumentUpdateDetails.Put(UpdateDetailsTemplate.GetArea("Header" + Number));
	DocumentUpdateDetails.StartRowGroup("Version" + Number);
	DocumentUpdateDetails.Put(UpdateDetailsTemplate.GetArea("Version" + Number));
	DocumentUpdateDetails.EndRowGroup();
	DocumentUpdateDetails.Put(UpdateDetailsTemplate.GetArea("Indent"));
	
EndProcedure

Function SystemChangesDisplayLastVersion(Val Username = Undefined) Export
	
	If Username = Undefined Then
		Username = UserName();
	EndIf;
	
	LatestVersion = Common.CommonSettingsStorageLoad("IBUpdate",
		"SystemChangesDisplayLastVersion", , , Username);
	
	Return LatestVersion;
	
EndFunction

Procedure DefineUpdateDetailsDisplay(OutputUpdatesDetails)
	
	If OutputUpdatesDetails AND Not Common.DataSeparationEnabled() Then
		Common.CommonSettingsStorageSave("IBUpdate", "OutputChangeDescriptionForAdministrator", True, , UserName());
	EndIf;
	
	If Common.SeparatedDataUsageAvailable() Then
		IBUpdateInfo = InfobaseUpdateInfo();
		IBUpdateInfo.OutputUpdatesDetails = OutputUpdatesDetails;
		
		WriteInfobaseUpdateInfo(IBUpdateInfo);
	EndIf;
	
EndProcedure

// Returns a list of change log sections.
//
// Returns:
//  ListValue - Value - version weight (numeric).
//    Presentation - version string.
//
Function UpdateDetailsSections() Export
	
	Sections = New ValueList;
	MetadataVersionWeight = VersionWeight(Metadata.Version);
	
	UpdateDetailsTemplate = Metadata.CommonTemplates.Find("ApplicationReleaseNotes");
	If UpdateDetailsTemplate <> Undefined Then
		VersionPredicate = "Version";
		HeaderPredicate = "Header";
		Template = GetCommonTemplate(UpdateDetailsTemplate);
		
		For each Area In Template.Areas Do
			If StrFind(Area.Name, VersionPredicate) = 0 Then
				Continue;
			EndIf;
			
			VersionInDescriptionFormat = Mid(Area.Name, StrLen(VersionPredicate) + 1);
			
			If Template.Areas.Find(HeaderPredicate + VersionInDescriptionFormat) = Undefined Then
				Continue;
			EndIf;
			
			VersionDigitsAsStrings = StrSplit(VersionInDescriptionFormat, "_");
			If VersionDigitsAsStrings.Count() <> 4 Then
				Continue;
			EndIf;
			
			VersionWeight = VersionWeightFromStringArray(VersionDigitsAsStrings);
			
			Version = ""
				+ Number(VersionDigitsAsStrings[0]) + "."
				+ Number(VersionDigitsAsStrings[1]) + "."
				+ Number(VersionDigitsAsStrings[2]) + "."
				+ Number(VersionDigitsAsStrings[3]);
			
			If VersionWeight > MetadataVersionWeight Then
				ExceptionText = NStr("ru = 'В общем макете ОписаниеИзмененийСистемы для одного из разделов изменений
					|установлена версия выше, чем в метаданных. (%1, должна быть %2)'; 
					|en = 'The version specified in a section of the ChangeHistory common template
					|is greater than the version specified in the metadata (%1 instead of correct version %2).'; 
					|pl = 'W ogólnej makiecie ОписаниеИзмененийСистемы dla jednego z rozdziałów zmian
					|jest określona wersja wyższa, niż w metadanych. (%1, powinna być %2)';
					|de = 'Im allgemeinen Layout BeschreibungVonSystemänderungen ist einer der Änderungsabschnitte
					|in einer höheren Version als in den Metadaten. (%1, muss sein %2)';
					|ro = 'În macheta comună ОписаниеИзмененийСистемы pentru unul din compartimentele modificărilor
					|este instalată versiunea mai mare, decât la metadate. (%1, trebuie să fie %2)';
					|tr = 'SistemDeğişikliklerinTanımı genel düzeninde, değişiklik bölümlerinden biri%2 için sürüm meta verilerden daha yüksek. (
					|, %1olmalıdır )'; 
					|es_ES = 'En la plantilla común ApplicationReleaseNotes para uno de los apartados de los cambios
					|está establecida la versión superior que en los metadatos. (%1 debe ser %2)'");
				ExceptionText = StringFunctionsClientServer.SubstituteParametersToString(ExceptionText,
					Version, Metadata.Version);
				Raise ExceptionText;
			EndIf;
			
			Sections.Add(VersionWeight, Version);
		EndDo;
		
		Sections.SortByValue(SortDirection.Desc);
	EndIf;
	
	
	Return Sections;
	
EndFunction

Function VersionWeightFromStringArray(VersionDigitsAsStrings)
	
	Return 0
		+ Number(VersionDigitsAsStrings[0]) * 1000000000
		+ Number(VersionDigitsAsStrings[1]) * 1000000
		+ Number(VersionDigitsAsStrings[2]) * 1000
		+ Number(VersionDigitsAsStrings[3]);
	
EndFunction

Function GetLaterVersions(Sections, Version)
	
	Result = New Array;
	
	If Sections = Undefined Then
		Sections = UpdateDetailsSections();
	EndIf;
	
	VersionWeight = VersionWeight(Version);
	For each ListItem In Sections Do
		If ListItem.Value <= VersionWeight Then
			Continue;
		EndIf;
		
		Result.Add(ListItem.Presentation);
	EndDo;
	
	Return Result;
	
EndFunction

Function PreviousVersionHandlersCompleted(UpdateIterations)
	
	UpdateInfo = InfobaseUpdateInfo();
	SearchParameters = New Structure;
	SearchParameters.Insert("Status");
	SearchParameters.Insert("LibraryName");
	
	If UpdateInfo.DeferredUpdateCompletedSuccessfully <> True
		AND UpdateInfo.HandlersTree <> Undefined
		AND UpdateInfo.HandlersTree.Rows.Count() > 0 Then
		
		CheckDeferredHandlerTree(UpdateInfo.HandlersTree, True);
		
		SaveUncompletedHandlersRequired = False;
		For Each Library In UpdateIterations Do
			SearchParameters.LibraryName = Library.Subsystem;
			
			// Resetting the attempt count for handlers with Error status.
			SearchParameters.Status = "Error";
			HandlersWithErrors = UpdateInfo.HandlersTree.Rows.FindRows(SearchParameters, True);
			CheckDeferredHandlers(HandlersWithErrors, Library, SaveUncompletedHandlersRequired);
			
			// Searching for uncompleted handlers that must be saved for further restart.
			SearchParameters.Status = "NotCompleted";
			UncompletedHandlers = UpdateInfo.HandlersTree.Rows.FindRows(SearchParameters, True);
			CheckDeferredHandlers(UncompletedHandlers, Library, SaveUncompletedHandlersRequired);
			
			// Searching for handlers with Running status.
			SearchParameters.Status = "Running";
			HandlersRunning = UpdateInfo.HandlersTree.Rows.FindRows(SearchParameters, True);
			CheckDeferredHandlers(HandlersRunning, Library, SaveUncompletedHandlersRequired);
			
			If SaveUncompletedHandlersRequired Then
				SaveUncompletedHandlersRequired = False;
			Else
				RowLibrary = UpdateInfo.HandlersTree.Rows.Find(Library.Subsystem, "LibraryName");
				If RowLibrary <> Undefined Then
					UpdateInfo.HandlersTree.Rows.Delete(RowLibrary);
				EndIf;
			EndIf;
			
		EndDo;
		
		// Deleting successfully completed handlers
		CompletedHandlers = UpdateInfo.HandlersTree.Rows.FindRows(New Structure("Status", "Completed"), True);
		For Each PreviousHandler In CompletedHandlers Do
			VersionRow = PreviousHandler.Parent.Rows;
			VersionRow.Delete(PreviousHandler);
		EndDo;
		
		Return UpdateInfo.HandlersTree;
		
	EndIf;
	
	Return NewUpdateHandlersInfo();
	
EndFunction

Procedure CheckDeferredHandlers(HandlersToCheck, Library, SaveUncompletedHandlersRequired)
	For Each HandlerToCheck In HandlersToCheck Do
		If Not ValueIsFilled(HandlerToCheck.ID) Then
			FoundHandler = Library.Handlers.Find(HandlerToCheck.HandlerName, "Procedure");
			If FoundHandler <> Undefined Then
				HandlerToCheck.ID = FoundHandler.ID;
			EndIf;
		Else
			CheckHandlerRenaming(HandlerToCheck, Library);
		EndIf;
		
		SaveUncompletedHandlers = SaveUncompletedDeferredHandlerRequired(Library, HandlerToCheck);
		If SaveUncompletedHandlers Then
			SaveUncompletedHandlersRequired = True;
		Else
			VersionRow = HandlerToCheck.Parent.Rows;
			VersionRow.Delete(HandlerToCheck);
		EndIf;
	EndDo;
EndProcedure

Function SaveUncompletedDeferredHandlerRequired(Library, Handler)
	If Handler.VersionNumber = "*" Then
		// The handler is added automatically during each update; saving the handler is not necessary.
		Return False;
	EndIf;
	
	FoundHandler = Library.Handlers.Find(Handler.HandlerName, "Procedure");
	If FoundHandler <> Undefined
		AND CommonClientServer.CompareVersions(FoundHandler.Version, Handler.VersionNumber) > 0
		AND CommonClientServer.CompareVersions(FoundHandler.Version, Library.PreviousVersion) > 0 Then
		// Version of the handler has changed; it is now greater than the current version of the library.
		// The handler will be added automatically; saving the handler is not necessary.
		Return False;
	EndIf;
	
	If CommonClientServer.CompareVersions(Handler.VersionNumber, Library.PreviousVersion) <= 0 Then
		// Version of the handler is equal to or less than the current version of the library. The handler 
		// will not be added to the execution list. You need to save it.
		If FoundHandler = Undefined Then
			// Ignoring and not saving the deleted handler.
			Return False;
		EndIf;
		FillPropertyValues(Handler, FoundHandler);
		
		HandlerParameters = Handler.ExecutionStatistics["HandlerParameters"];
		
		Handler.Status = "NotCompleted";
		Handler.ExecutionStatistics.Clear();
		If HandlerParameters <> Undefined Then
			Handler.ExecutionStatistics.Insert("HandlerParameters", HandlerParameters);
		EndIf;
		Handler.ErrorInfo = "";
		Handler.AttemptCount = 0;
		Return True;
	EndIf;
	
	Return False;
EndFunction

Procedure CheckHandlerRenaming(PreviousHandler, Library)
	NewHandler = Library.Handlers.Find(PreviousHandler.ID, "ID");
	If NewHandler <> Undefined
		AND NewHandler.Procedure <> PreviousHandler.HandlerName Then
		PreviousHandler.HandlerName = NewHandler.Procedure;
	EndIf;
EndProcedure

Procedure CheckDeferredHandlerTree(HandlersTree, InitialCheck = False)
	
	If InitialCheck Then
		NewHandlerTree = NewUpdateHandlersInfo();
		For Each Column In NewHandlerTree.Columns Do
			If HandlersTree.Columns.Find(Column.Name) = Undefined Then
				HandlersTree.Columns.Add(Column.Name, Column.ValueType);
			EndIf;
		EndDo;
		
		LibrariesToDelete = New Array;
		SubsystemsDetails = StandardSubsystemsCached.SubsystemsDetails().ByNames;
		For Each Library In HandlersTree.Rows Do
			LibraryExists = (SubsystemsDetails.Get(Library.LibraryName) <> Undefined);
			If LibraryExists Then
				Continue;
			EndIf;
			LibrariesToDelete.Add(Library);
		EndDo;
		
		For Each LibraryToDelete In LibrariesToDelete Do
			HandlersTree.Rows.Delete(LibraryToDelete);
		EndDo;
		
		Return;
	EndIf;
	
	AllHandlers = New Map;
	HandlersToDelete = New Array;
	For Each TreeRowLibrary In HandlersTree.Rows Do
		
		Index = 1;
		RowToMove = Undefined;
		Offset = 0;
		For Each TreeRowVersion In TreeRowLibrary.Rows Do
			
			If TreeRowVersion.VersionNumber = "*"
				AND Index <> 1 Then
				RowToMove = TreeRowVersion;
				Offset = Index - 1;
			EndIf;
			
			If TreeRowVersion.Rows.Count() = 0 Then
				TreeRowVersion.Status = "Completed";
			Else
				TreeRowVersion.Status = "";
			EndIf;
			
			// Checking for multiple copies of any update handler added.
			For Each TreeRowHandler In TreeRowVersion.Rows Do
				If AllHandlers[TreeRowHandler.HandlerName] = Undefined Then
					AllHandlers.Insert(TreeRowHandler.HandlerName, TreeRowHandler.HandlerName);
				Else
					HandlersToDelete.Add(TreeRowHandler);
				EndIf;
			EndDo;
			
			For Each Deleted In HandlersToDelete Do
				TreeRowVersion.Rows.Delete(Deleted);
			EndDo;
			HandlersToDelete.Clear();
			
			Index = Index + 1;
		EndDo;
		
		If RowToMove <> Undefined Then
			TreeRowLibrary.Rows.Move(RowToMove, Offset * (-1));
			RowToMove = Undefined;
		EndIf;
		
	EndDo;
	
EndProcedure

Procedure CancelDeferredUpdate()
	
	OnEnableDeferredUpdate(False);
	
EndProcedure

Function AllDeferredHandlersCompleted(UpdateInfo)
	
	CompletedHandlersCount = 0;
	TotalHandlerCount     = 0;
	For Each TreeRowLibrary In UpdateInfo.HandlersTree.Rows Do
		For Each TreeRowVersion In TreeRowLibrary.Rows Do
			TotalHandlerCount = TotalHandlerCount + TreeRowVersion.Rows.Count();
			For Each Handler In TreeRowVersion.Rows Do
				
				If Handler.Status = "Completed" Then
					CompletedHandlersCount = CompletedHandlersCount + 1;
				EndIf;
				
			EndDo;
		EndDo;
	EndDo;
	
	If TotalHandlerCount = CompletedHandlersCount Then
		UpdateInfo.DeferredUpdateEndTime = CurrentSessionDate();
		UpdateInfo.DeferredUpdateCompletedSuccessfully = True;
		WriteInfobaseUpdateInfo(UpdateInfo);
		Constants.DeferredUpdateCompletedSuccessfully.Set(True);
		If Not Common.IsSubordinateDIBNode() Then
			Constants.DeferredMasterNodeUpdateCompleted.Set(True);
		EndIf;
		
		Return True;
	Else
		Return False;
	EndIf;
	
EndFunction

////////////////////////////////////////////////////////////////////////////////
// Auxiliary procedures and deferred update functions.

// For internal use only.
//
Function ExecuteDeferredUpdateHandler(UpdateInfo, UpdateParameters = Undefined)
	
	HandlerContext = NewHandlerContext();
	UpdateHandler = FindUpdateHandler(HandlerContext, UpdateInfo, UpdateParameters);
	
	If TypeOf(UpdateHandler) = Type("ValueTreeRow") Then
		ResultAddress = PutToTempStorage(Undefined);
		
		Try
			If UpdateHandler.Multithreaded Then
				SupplementMultithreadHandlerContext(HandlerContext);
				DataToProcess = UpdateInfo.DataToProcess[UpdateHandler.HandlerName];
				SelectionParameters = DataToProcess.SelectionParameters;
				SelectionParameters.MaxSelection = InfobaseUpdate.MaxRecordsCountInSelection();
				SearchParameters = NewBatchSearchParameters();
				SearchParameters.SelectionParameters = SelectionParameters;
				SearchParameters.LastSelectedRecord = DataToProcess.LastSelectedRecord;
				IterationParameters = DataIterationParametersForUpdate(SearchParameters);
				Queue = HandlerContext.Parameters.Queue;
				Iterator = CurrentIterationParameters(IterationParameters);
				AdditionalDataSources = SelectionParameters.AdditionalDataSources;
				
				While Iterator <> Undefined Do
					RefObject = Iterator.RefObject;
					TabularObject = Iterator.TabularObject;
					DataSet = NewDataSetForUpdate();
					DataWriter = DataSet.Add();
					SelectionParameters.AdditionalDataSources = InfobaseUpdate.DataSources(
						AdditionalDataSources,
						RefObject,
						TabularObject);
					DataWriter.Data = SelectBatchData(SelectionParameters, Queue, RefObject, TabularObject);
					DataWriter.RefObject = RefObject;
					DataWriter.TabularObject = TabularObject;
					DataToUpdate = NewBatchForUpdate();
					DataToUpdate.DataSet = DataSet;
					
					If DataWriter.Data.Count() > 0 Then
						DataToUpdate.FirstRecord = FirstDataSetRowRecordKey(DataSet);
						DataToUpdate.LatestRecord = LastDataSetRowRecordKey(DataSet);
					EndIf;
					
					HandlerContext.Parameters.DataToUpdate = DataToUpdate;
					Count = DataWriter.Data.Count();
					ExecuteDeferredHandler(HandlerContext, ResultAddress);
					CompleteDeferredHandlerExecution(HandlerContext, ResultAddress, UpdateInfo);
					
					If Count > 0 Then
						DataToProcess.LastSelectedRecord = LastDataSetRowRecordKey(DataSet);
					Else
						DataToProcess.LastSelectedRecord = Undefined;
					EndIf;
					
					NextIterationParameters(IterationParameters, Count = SelectionParameters.MaxSelection);
					Iterator = CurrentIterationParameters(IterationParameters);
				EndDo;
				
				SelectionParameters.AdditionalDataSources = AdditionalDataSources;
			Else
				ExecuteDeferredHandler(HandlerContext, ResultAddress);
				CompleteDeferredHandlerExecution(HandlerContext, ResultAddress, UpdateInfo);
			EndIf;
		Except
			ProcessHandlerException(HandlerContext, UpdateHandler, ErrorInfo());
		EndTry;
	ElsIf UpdateHandler = False Then
		Return False;
	EndIf;
	
	Return True;
	
EndFunction

// Finds an update handler that needs to be executed.
//
// Parameters:
//  HandlerContext - Structure - see NewHandlerContext(). 
//  UpdateInfo - Structure - see NewUpdateInfo(). 
//  UpdateParameters - Structure - see ExecuteInfobaseUpdate(). 
//
// Returns:
//  * ValueTreeRow - the update handler represented as a row of the handler tree.
//  * Boolean - True if executing the handler is not necessary, False otherwise.
//
Function FindUpdateHandler(HandlerContext, UpdateInfo, UpdateParameters = Undefined)
	
	AttachDetachDeferredUpdateHandlers(UpdateInfo);
	
	UpdatePlan = UpdateInfo.DeferredUpdatePlan;
	CurrentUpdateIteration = UpdateInfo.CurrentUpdateIteration;
	CurrentUpdateCycle     = Undefined;
	CompletedSuccessfully = True;
	RunningMultithreadHandler = Undefined;
	MultithreadHandlerUpdateCycle = Undefined;
	MultithreadHandlerDetails = Undefined;
	
	While True Do
		HasUncompleted = False;
		HasRunning = False;
		PreviousUpdateCycle = Undefined;
		For Each UpdateCycleDetails In UpdatePlan Do
			If UpdateCycleDetails.Property("CompletedWithErrors")
				Or UpdateCycleDetails.Property("HasStopped") Then
				CompletedSuccessfully = False;
			Else
				
				If (PreviousUpdateCycle <> Undefined
						AND PreviousUpdateCycle.Handlers.Count() <> 0
						AND UpdateCycleDetails.DependsOnPrevious)
					Or UpdateCycleDetails.Handlers.Count() = 0 Then
					PreviousUpdateCycle = UpdateCycleDetails;
					Continue;
				EndIf;
				
				HasErrors = False;
				HasStopped = False;
				For Each HandlerDetails In UpdateCycleDetails.Handlers Do
					
					If HandlerDetails.Iteration = CurrentUpdateIteration Then
						HasUncompleted = True;
						Continue;
					EndIf;
					
					HandlersTree = UpdateInfo.HandlersTree.Rows;
					UpdateHandler = FindHandlerInTree(HandlersTree,
						HandlerDetails.ID,
						HandlerDetails.HandlerName);
					
					If UpdateHandler.Status = "Running" AND Not UpdateHandler.BatchProcessingCompleted Then
						If UpdateHandler.Multithreaded Then
							If HasBatchesForUpdate(UpdateHandler, UpdateInfo) Then
								RunningMultithreadHandler = UpdateHandler;
								MultithreadHandlerUpdateCycle = UpdateCycleDetails;
								MultithreadHandlerDetails = HandlerDetails;
							EndIf;
						EndIf;
						
						HasRunning = True;
						Continue;
					EndIf;
					
					If UpdateHandler.Status = "Paused" Then
						HasStopped = True;
						Continue;
					EndIf;
					
					MaxUpdateAttempts = MaxUpdateAttempts(UpdateInfo, UpdateHandler);
					If UpdateHandler.AttemptCount >= MaxUpdateAttempts Then
						If UpdateHandler.Status = "Error" Then
							HasErrors = True;
							Continue;
						ElsIf AllHandlersLoop(UpdateInfo) Then
							MarkLoopingHandlers(UpdateInfo);
							HasErrors = True;
							Continue;
						EndIf;
					EndIf;
					
					CurrentUpdateCycle = UpdateCycleDetails;
					Break;
					
				EndDo;
				
				If CurrentUpdateCycle = Undefined AND MultithreadHandlerUpdateCycle = Undefined Then
					If HasErrors Then
						UpdateCycleDetails.Insert("CompletedWithErrors");
						CompletedSuccessfully = False;
					ElsIf HasStopped Then
						UpdateCycleDetails.Insert("HasStopped");
					EndIf;
				Else
					If CurrentUpdateCycle = Undefined AND MultithreadHandlerUpdateCycle <> Undefined Then
						UpdateHandler = RunningMultithreadHandler;
						CurrentUpdateCycle = MultithreadHandlerUpdateCycle;
						HandlerDetails = MultithreadHandlerDetails;
					EndIf;
					Break;
				EndIf;
			EndIf;
			
			PreviousUpdateCycle = UpdateCycleDetails;
		EndDo;
		
		If CurrentUpdateCycle <> Undefined Then
			Break;
		ElsIf HasUncompleted Then
			CurrentUpdateIteration = CurrentUpdateIteration + 1;
			UpdateInfo.CurrentUpdateIteration = CurrentUpdateIteration;
		Else
			Break;
		EndIf;
	EndDo;
	
	If CurrentUpdateCycle = Undefined Then
		If HasRunning Then
			Return True;
		Else
			UpdateInfo.DeferredUpdatePlan = UpdatePlan;
			UpdateInfo.DeferredUpdateEndTime = CurrentSessionDate();
			UpdateInfo.DeferredUpdateCompletedSuccessfully = CompletedSuccessfully;
			WriteInfobaseUpdateInfo(UpdateInfo);
			Constants.DeferredUpdateCompletedSuccessfully.Set(CompletedSuccessfully);
			If Not Common.IsSubordinateDIBNode() Then
				Constants.DeferredMasterNodeUpdateCompleted.Set(CompletedSuccessfully);
			EndIf;
			
			Return False;
		EndIf;
	EndIf;
	
	ParallelMode = (CurrentUpdateCycle.Mode = "Parallel");
	UpdateParameters = ?(UpdateParameters = Undefined, New Structure, UpdateParameters);
	UpdateParameters.Insert("ParallelMode", ParallelMode);
	If ParallelMode Then
		Filter = New Structure("ExecuteInMasterNodeOnly", True);
		SearchResult = HandlersTree.FindRows(Filter, True);
		UpdateParameters.Insert("HandlersQueue", CurrentUpdateCycle.HandlersQueue);
		UpdateParameters.Insert("UpdatePlan", UpdatePlan);
		UpdateParameters.Insert("DataToProcess", UpdateInfo.DataToProcess);
		UpdateParameters.Insert("HasMasterNodeHandlers", (SearchResult.Count() > 0));
	EndIf;
	
	HandlersTree = UpdateInfo.HandlersTree;
	SetUpdateHandlerParameters(UpdateHandler, True, ParallelMode);
	BeforeStartDataProcessingProcedure(HandlerContext,
		UpdateHandler,
		UpdateParameters,
		UpdateInfo);
	
	HandlerContext.HandlerID = HandlerDetails.ID;
	HandlerContext.HandlerName = HandlerDetails.HandlerName;
	HandlerContext.UpdateCycleDetailsIndex = UpdatePlan.Find(UpdateCycleDetails);
	HandlerContext.CurrentUpdateCycleIndex = UpdatePlan.Find(CurrentUpdateCycle);
	HandlerContext.ParallelMode = ParallelMode;
	HandlerContext.UpdateParameters = UpdateParameters;
	HandlerContext.UpdateHandlerParameters = SessionParameters.UpdateHandlerParameters;
	HandlerContext.CurrentUpdateIteration = CurrentUpdateIteration;
	
	SetUpdateHandlerParameters(Undefined);
	
	Return UpdateHandler;
	
EndFunction

// Completes execution of the deferred handler in the main thread after the background job has completed.
//
// Parameters:
//  HandlerContext - Structure - see NewHandlerContext(). 
//  UpdateInfo - Structure - see NewUpdateInfo(). 
//
Procedure EndDeferredUpdateHandlerExecution(HandlerContext, UpdateInfo)
	
	ParallelMode = HandlerContext.ParallelMode;
	CurrentUpdateIteration = HandlerContext.CurrentUpdateIteration;
	UpdatePlan = UpdateInfo.DeferredUpdatePlan;
	CurrentUpdateCycle = UpdatePlan[HandlerContext.CurrentUpdateCycleIndex];
	HandlerCollection = CurrentUpdateCycle.Handlers;
	UpdateCycleDetails = UpdatePlan[HandlerContext.UpdateCycleDetailsIndex];
	HandlerDetailsList = UpdateCycleDetails.Handlers;
	
	HandlerDetails = FindHandlerInTable(HandlerDetailsList,
		HandlerContext.HandlerID,
		HandlerContext.HandlerName);
	
	UpdateHandler = FindHandlerInTree(UpdateInfo.HandlersTree.Rows,
		HandlerContext.HandlerID,
		HandlerContext.HandlerName);
	
	If UpdateHandler.Status = "Completed" Then
		Handler = HandlerCollection.Find(HandlerDetails);
		
		If Handler <> Undefined Then
			HandlerCollection.Delete(HandlerCollection.Find(HandlerDetails));
		EndIf;
		
		LockedObjectsInfo = LockedObjectsInfo();
		HandlerInfo = LockedObjectsInfo.Handlers[UpdateHandler.HandlerName];
		If HandlerInfo <> Undefined Then
			HandlerInfo.Completed = True;
			WriteLockedObjectsInfo(LockedObjectsInfo);
		EndIf;
		
		// Removing the handler from the queue when in parallel mode, in order to determine which queues 
		// have uncompleted handlers.
		If ParallelMode Then
			Row = CurrentUpdateCycle.HandlersQueue.Find(UpdateHandler.HandlerName, "Handler");
			
			If Row <> Undefined Then
				CurrentUpdateCycle.HandlersQueue.Delete(Row);
			EndIf;
		EndIf;
	ElsIf UpdateHandler.Status = "Running" Then
		
		// If the handler has high priority it is called five times, after which the next handler is called.
		// 
		StartsWithPriority = Undefined;
		If UpdateHandler.Priority = "HighPriority" Then
			StartsWithPriority = UpdateHandler.ExecutionStatistics["StartsWithPriority"];
			StartsWithPriority = ?(StartsWithPriority = Undefined, 1, ?(StartsWithPriority = 4, 0, StartsWithPriority + 1));
			UpdateHandler.ExecutionStatistics.Insert("StartsWithPriority", StartsWithPriority);
		EndIf;
		
		If StartsWithPriority = Undefined Or StartsWithPriority = 0 Then
			HandlerDetails.Iteration = CurrentUpdateIteration;
		EndIf;
		
	Else
		
		HandlerDetails.Iteration = CurrentUpdateIteration;
	EndIf;
	
	UpdateInfo.DeferredUpdatePlan = UpdatePlan;
	
	// Stopping the update in parallel mode if the handler failed to complete, because other handlers 
	// might depend on the data to be processed by it.
	If ParallelMode
		AND UpdateHandler.Status = "Error"
		AND UpdateHandler.AttemptCount >= MaxUpdateAttempts(UpdateInfo, UpdateHandler) Then
		UpdateInfo.DeferredUpdateEndTime = CurrentSessionDate();
		UpdateInfo.DeferredUpdateCompletedSuccessfully = False;
		WriteInfobaseUpdateInfo(UpdateInfo);
		Constants.DeferredUpdateCompletedSuccessfully.Set(False);
		If Not Common.IsSubordinateDIBNode() Then
			Constants.DeferredMasterNodeUpdateCompleted.Set(False);
		EndIf;
		
		ErrorTemplate = NStr("ru = 'Не удалось выполнить обработчик обновления ""%1"". Подробнее в журнале регистрации.'; en = 'Cannot execute update handler %1. See the event log for details.'; pl = 'Nie udało się wykonać program przetwarzania aktualizacji ""%1"". Szczegółowo w dzienniku rejestracji.';de = 'Der Update-Handler konnte ""%1"" nicht ausführen. Weitere Informationen finden Sie im Protokoll.';ro = 'Eșec la executarea handlerului de actualizare ""%1"". Detalii vezi în registrul logare.';tr = 'Güncelleştirme işleyicisi başarısız oldu ""%1"".  Daha fazla bilgi için bkz. kayıt günlüğüne.'; es_ES = 'No se ha podido ejecutar el procesador de la actualización ""%1"". Véase más en el registro de eventos.'");
		Raise StringFunctionsClientServer.SubstituteParametersToString(ErrorTemplate,
			HandlerContext.HandlerName);
	EndIf;
	
	If Common.FileInfobase() Then
		WriteInfobaseUpdateInfo(UpdateInfo);
	Else
		BeginTransaction();
		Try
			Lock = New DataLock;
			Lock.Add("Constant.IBUpdateInfo");
			Lock.Lock();
			
			NewUpdateInfo = InfobaseUpdateInfo();
			UpdateInfo.DeferredUpdateManagement = NewUpdateInfo.DeferredUpdateManagement;
			
			WriteInfobaseUpdateInfo(UpdateInfo);
			
			CommitTransaction();
		Except
			RollbackTransaction();
			Raise;
		EndTry;
	EndIf;
	
EndProcedure

Function PassedUpdateHandlerParameters(Parameters)
	PassedParameters = New Structure;
	For Each Parameter In Parameters Do
		If Parameter.Key <> "ProcessingCompleted"
			AND Parameter.Key <> "ExecutionProgress"
			AND Parameter.Key <> "Queue" Then
			PassedParameters.Insert(Parameter.Key, Parameter.Value);
		EndIf;
	EndDo;
	
	Return PassedParameters;
EndFunction

Function NewUpdateInfo(PreviousInfo = Undefined)
	
	UpdateInfo = New Structure;
	UpdateInfo.Insert("UpdateStartTime");
	UpdateInfo.Insert("UpdateEndTime");
	UpdateInfo.Insert("UpdateDuration");
	UpdateInfo.Insert("DeferredUpdateStartTime");
	UpdateInfo.Insert("DeferredUpdateEndTime");
	UpdateInfo.Insert("SessionNumber", New ValueList());
	UpdateInfo.Insert("UpdateHandlerParameters");
	UpdateInfo.Insert("DeferredUpdateCompletedSuccessfully");
	UpdateInfo.Insert("HandlersTree", New ValueTree());
	UpdateInfo.Insert("HandlerTreeVersion", "");
	UpdateInfo.Insert("OutputUpdatesDetails", False);
	UpdateInfo.Insert("LegitimateVersion", "");
	UpdateInfo.Insert("NewSubsystems", New Array);
	UpdateInfo.Insert("DeferredUpdateManagement", New Structure);
	UpdateInfo.Insert("DataToProcess", New Map);
	UpdateInfo.Insert("CurrentUpdateIteration", 1);
	UpdateInfo.Insert("DeferredUpdatePlan");
	UpdateInfo.Insert("UpdateSession");
	UpdateInfo.Insert("ThreadsDetails");
	
	If TypeOf(PreviousInfo) = Type("Structure") Then
		FillPropertyValues(UpdateInfo, PreviousInfo);
	EndIf;
	
	Return UpdateInfo;
	
EndFunction

Function NewUpdateHandlersInfo()
	
	HandlersTree = New ValueTree;
	HandlersTree.Columns.Add("LibraryName");
	HandlersTree.Columns.Add("VersionNumber");
	HandlersTree.Columns.Add("RegistrationVersion");
	HandlersTree.Columns.Add("ID");
	HandlersTree.Columns.Add("HandlerName");
	HandlersTree.Columns.Add("Status");
	HandlersTree.Columns.Add("AttemptCount");
	HandlersTree.Columns.Add("ExecutionStatistics", New TypeDescription("Map"));
	HandlersTree.Columns.Add("ErrorInfo");
	HandlersTree.Columns.Add("Comment");
	HandlersTree.Columns.Add("Priority");
	HandlersTree.Columns.Add("CheckProcedure");
	HandlersTree.Columns.Add("ObjectsToLock");
	HandlersTree.Columns.Add("UpdateDataFillingProcedure");
	HandlersTree.Columns.Add("DeferredProcessingQueue");
	HandlersTree.Columns.Add("ExecuteInMasterNodeOnly", New TypeDescription("Boolean"));
	HandlersTree.Columns.Add("RunAlsoInSubordinateDIBNodeWithFilters", New TypeDescription("Boolean"));
	HandlersTree.Columns.Add("BatchProcessingCompleted", New TypeDescription("Boolean"));
	HandlersTree.Columns.Add("Multithreaded", New TypeDescription("Boolean"));
	
	Return HandlersTree;
	
EndFunction

Function DeferredUpdateMode(UpdateParameters)
	
	FileInfobase             = Common.FileInfobase();
	DataSeparationEnabled                     = Common.DataSeparationEnabled();
	SeparatedDataUsageAvailable = Common.SeparatedDataUsageAvailable();
	ExecuteDeferredHandlers         = UpdateParameters.ExecuteDeferredHandlers;
	ClientLaunchParameter                 = SessionParameters.ClientParametersAtServer.Get("LaunchParameter");
	
	If Not DataSeparationEnabled Or SeparatedDataUsageAvailable Then
		If FileInfobase
			Or StrFind(Lower(ClientLaunchParameter), Lower("ExecuteDeferredUpdateNow")) > 0
			Or ExecuteDeferredHandlers Then
			Return "Exclusive";
		Else
			Return "Deferred";
		EndIf;
	Else
		Return Undefined;
	EndIf;
	
EndFunction

// Gets infobase update information from the IBUpdateInfo constant.
// 
Function LockedObjectsInfo() Export
	
	SetPrivilegedMode(True);
	
	If Common.DataSeparationEnabled()
	   AND Not Common.SeparatedDataUsageAvailable() Then
		
		Return NewLockedObjectsInfo();
	EndIf;
	
	LockedObjectsInfo = Constants.LockedObjectsInfo.Get().Get();
	If TypeOf(LockedObjectsInfo) <> Type("Structure") Then
		Return NewLockedObjectsInfo();
	EndIf;
	
	LockedObjectsInfo = NewLockedObjectsInfo(LockedObjectsInfo);
	Return LockedObjectsInfo;
	
EndFunction

// Preparing to run the update handler in the main thread.
//
//  HandlerContext - Structure - see NewHandlerContext(). 
//  UpdateHandler - ValueTreeRow - the update handler represented as a row of the handler tree.
//  UpdateParameters - Structure - see ExecuteInfobaseUpdate(). 
//  UpdateInfo - Structure - update information (see NewUpdateInfo()).
//
Procedure BeforeStartDataProcessingProcedure(HandlerContext,
                                                UpdateHandler,
                                                UpdateParameters,
                                                UpdateInfo)
	
	HandlerContext.WriteToLog = Constants.WriteIBUpdateDetailsToEventLog.Get();
	HandlerContext.TransactionActiveAtExecutionStartTime = TransactionActive();
	HandlerName = UpdateHandler.HandlerName;
	
	Try
		HandlerContext.StartedWithoutErrors = True;
		HandlerExecutionMessage = StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = 'Выполняется процедура обновления ""%1"".'; en = 'Executing update procedure %1.'; pl = 'Aktualizacja ""%1"".';de = 'Aktualisierung ""%1"".';ro = 'Are loc executarea procedurii de actualizare a ""%1"".';tr = 'Güncelleme ""%1"".'; es_ES = 'Actualizando ""%1"".'"), HandlerName);
		EventLogOperations.AddMessageForEventLog(EventLogEvent(),
				EventLogLevel.Information,,, HandlerExecutionMessage);
		
		// Data processing procedure progress.
		ExecutionProgress = New Structure;
		ExecutionProgress.Insert("TotalObjectCount", 0);
		ExecutionProgress.Insert("ProcessedObjectsCount", 0);
		If UpdateHandler.ExecutionStatistics["ExecutionProgress"] <> Undefined
			AND TypeOf(UpdateHandler.ExecutionStatistics["ExecutionProgress"]) = Type("Structure") Then
			FillPropertyValues(ExecutionProgress, UpdateHandler.ExecutionStatistics["ExecutionProgress"]);
		EndIf;
		
		// Initialization of handler parameters.
		Parameters = UpdateHandler.ExecutionStatistics["HandlerParameters"];
		If Parameters = Undefined Then
			Parameters = New Structure;
		EndIf;
		
		HandlerContext.Parameters = Parameters;
		
		If UpdateParameters.ParallelMode Then
			Parameters.Insert("ProcessingCompleted", Undefined);
		Else
			Parameters.Insert("ProcessingCompleted", True);
		EndIf;
		
		Parameters.Insert("ExecutionProgress", ExecutionProgress);
		
		Parameters.Insert("Queue", UpdateHandler.DeferredProcessingQueue);
		
		If HandlerContext.WriteToLog Then
			HandlerContext.HandlerFullDetails = PrepareUpdateProgressDetails(UpdateHandler,
				Parameters,
				UpdateHandler.LibraryName,
				True);
		EndIf;
		
		UpdateProcedureStartCount = UpdateProcedureStartCount(UpdateHandler);
		
		If UpdateProcedureStartCount > 10000 Then // Protection from looping.
			If UpdateParameters.ParallelMode
				AND Common.IsSubordinateDIBNode()
				AND UpdateParameters.HasMasterNodeHandlers Then
				ErrorText = NStr("ru = 'Превышено допустимое количество запусков процедуры обновления.
					|Убедитесь, что дополнительные процедуры обработки данных в главном узле
					|полностью завершились, выполните синхронизацию данных и повторно
					|запустите выполнение процедур обработки данных в данном узле.'; 
					|en = 'The maximum number of update handler execution attempts is exceeded.
					|Ensure that all additional update handlers in the main node
					|are completed, synchronize the data,
					|and execute the update handlers in this node again.'; 
					|pl = 'Przekroczono maksymalną liczbę prób wykonania programu obsługi aktualizacji.
					|Upewnij się, że wszystkie dodatkowe programy obsługi aktualizacji w głównym węźle
					|zostały ukończone, zsynchronizuj dane,
					|i ponownie uruchom programy obsługi aktualizacji w tym węźle.';
					|de = 'Die zulässige Anzahl der Starts des Aktualisierungsvorgangs wird überschritten.
					| Stellen Sie sicher, dass die zusätzlichen Datenverarbeitungsverfahren im Hauptknoten
					| vollständig abgeschlossen sind, synchronisieren Sie die Daten und starten
					| Sie die Datenverarbeitungsverfahren in diesem Knoten neu.';
					|ro = 'Cantitatea admisibilă de lansări ale procedurii de actualizare este depășită.
					|Convingeți-vă, că procedurile suplimentare de procesare a datelor în nodul principal
					|au fost finalizate complet, executați sincronizarea datelor și lansați repetat
					|executarea procedurilor de procesare a datelor în acest nod.';
					|tr = 'Güncelleştirme prosedürünün geçerli başlatma sayısı aşıldı. 
					|Ana düğümdeki ek veri işleme yordamlarının 
					|tam olarak tamamlandığından emin olun, verileri eşitleyin ve bu ünitedeki 
					|veri işleme prosedürlerini yeniden çalıştırın.'; 
					|es_ES = 'Se ha superado la cantidad de lanzamientos del procedimiento de la actualización.
					|Asegúrese de que los procedimientos adicionales del procesamiento de datos en el nodo principal
					|se ha terminado completamente, sincronice los datos y vuelva
					|a lanzar la realización de los procedimientos del procesamiento de datos en este nodo.'");
			Else
				ErrorText = NStr("ru = 'Превышено допустимое количество запусков процедуры обновления.
					|Выполнение прервано для предотвращения зацикливания механизма обработки данных.'; 
					|en = 'The maximum number of update attempts is exceeded.
					|The update is canceled to prevent an endless loop.'; 
					|pl = 'Przekroczono maksymalną liczbę prób aktualizacji.
					|Aktualizacja jest anulowana, aby zapobiec niekończącej się pętli.';
					|de = 'Die zulässige Anzahl der Starts des Aktualisierungsvorgangs wird überschritten.
					|Die Ausführung wird unterbrochen, um zu verhindern, dass der Datenverarbeitungsmechanismus zyklisch läuft.';
					|ro = 'Cantitatea admisibilă de lansări ale procedurii de actualizare este depășită.
					|Executarea este întreruptă pentru a evita loopingul mecanismului de procesare a datelor.';
					|tr = 'Güncelleştirme prosedürünün geçerli başlatma sayısı aşıldı. 
					|Yürütme veri işleme mekanizması döngü önlemek için durduruldu.'; 
					|es_ES = 'Se ha superado la cantidad de lanzamientos del procedimiento de la actualización.
					|La realización ha sido interrumpida para evitar que el mecanismo del procesamiento de datos entre en ciclo.'");
			EndIf;
			
			UpdateHandler.AttemptCount = MaxUpdateAttempts(UpdateInfo, UpdateHandler);
			Raise ErrorText;
		EndIf;
		
		// Starting the deffered update handler.
		UpdateHandler.Status = "Running";
		UpdateHandler.BatchProcessingCompleted = False;
		If UpdateHandler.ExecutionStatistics["DataProcessingStart"] = Undefined Then
			UpdateHandler.ExecutionStatistics.Insert("DataProcessingStart", CurrentSessionDate());
		EndIf;
		
		HandlerContext.DataProcessingStart = CurrentUniversalDateInMilliseconds();
		If UpdateParameters.ParallelMode
			AND Common.IsSubordinateDIBNode()
			AND UpdateHandler.ExecuteInMasterNodeOnly Then
			// In the subordinate DIB node, we only check that the data processed by the handler came from the 
			// main node and update the status of the handler.
			HandlerContext.SkipProcessedDataCheck = True;
			DataToProcessDetails = UpdateParameters.DataToProcess[UpdateHandler.HandlerName];
			HandlerData = DataToProcessDetails.HandlerData;
			
			If HandlerData.Count() = 0 Then
				Parameters.ProcessingCompleted = True;
			Else
				For Each ObjectToProcess In HandlerData Do
					Parameters.ProcessingCompleted = InfobaseUpdate.DataProcessingCompleted(
						UpdateHandler.DeferredProcessingQueue,
						ObjectToProcess.Key);
					If Not Parameters.ProcessingCompleted Then
						Break;
					EndIf;
				EndDo;
			EndIf;
		Else
			HandlerContext.ExecuteHandler = True;
			Return;
		EndIf;
	Except
		ProcessHandlerException(HandlerContext, UpdateHandler, ErrorInfo());
		HandlerContext.StartedWithoutErrors = False;
	EndTry;
	
	EndDataProcessingProcedure(HandlerContext, UpdateHandler, UpdateInfo);
	
EndProcedure

// End of the startup of the data processing procedure in the main thread.
//
// Parameters:
//  HandlerContext - Structure - see NewHandlerContext(). 
//  UpdateHandler - ValueTreeRow - the update handler represented as a row of the handler tree.
//  UpdateInfo - Structure - update information (see NewUpdateInfo()).
//
Procedure AfterStartDataProcessingProcedure(HandlerContext, UpdateHandler, UpdateInfo)
	
	Parameters = HandlerContext.Parameters;
	UpdateParameters = HandlerContext.UpdateParameters;
	
	Try
		DataProcessingCompletion = CurrentUniversalDateInMilliseconds();
		
		If Parameters.ProcessingCompleted = Undefined Then
			ErrorText = NStr("ru = 'Обработчик обновления не инициализировал параметр ОбработкаЗавершена.
			|Выполнение прервано из-за явной ошибки в коде обработчика.'; 
			|en = 'The update handler did not initialize ProcessingCompleted parameter.
			|The execution is canceled due to explicit error in the handler code.'; 
			|pl = 'Program obsługi aktualizacji nie zainicjował parametru ProcessingCompleted.
			|Wykonanie jest anulowane z powodu wyraźnego błędu w kodzie obsługi.';
			|de = 'Der Update-Handler hat den Parameter ProcessingCompleted nicht initialisiert.
			|Die Ausführung wird aufgrund eines offensichtlichen Fehlers im Handler-Code unterbrochen.';
			|ro = 'Handlerul de actualizare nu a inițializat parametrul ProcessingCompleted.
			|Executarea este întreruptă din cauza unei erori explicite în codul handlerului.';
			|tr = 'Güncelleme işleyicisi ProcessingCompleted parametresini başlatmamıştır. 
			| Yürütme, işleyicinin kodundaki belirli bir hata yüzünden durduruldu.'; 
			|es_ES = 'El procesador de la actualización no ha inicializado el parámetro ProcessingCompleted.
			|La realización ha sido interrumpida a causa del error en el código del procesador.'");
			Raise ErrorText;
		EndIf;
		
		If Parameters.ProcessingCompleted Then
			UpdateHandler.Status = "Completed";
			UpdateHandler.Priority = "OnSchedule";
			UpdateHandler.ExecutionStatistics.Insert("DataProcessingCompletion", CurrentSessionDate());
			
			// Writing the progress update.
			If UpdateParameters.Property("InBackground")
				AND UpdateParameters.InBackground Then
				HandlerExecutionProgress = UpdateParameters.HandlerExecutionProgress;
				HandlerExecutionProgress.CompletedHandlersCount = HandlerExecutionProgress.CompletedHandlersCount + 1;
				Progress = 10 + HandlerExecutionProgress.CompletedHandlersCount / HandlerExecutionProgress.TotalHandlerCount * 90;
				TimeConsumingOperations.ReportProgress(Progress);
			EndIf;
		ElsIf UpdateParameters.ParallelMode AND Not HandlerContext.SkipProcessedDataCheck Then
			HasProcessedObjects = SessionParameters.UpdateHandlerParameters.HasProcessedObjects;
			HandlerQueue = UpdateHandler.DeferredProcessingQueue;
			
			MinQueue = 0;
			If Not HasProcessedObjects Then
				For Each UpdateCycle In UpdateParameters.UpdatePlan Do
					If UpdateCycle.Mode = "Sequentially"
						Or UpdateCycle.HandlersQueue.Count() = 0 Then
						Continue;
					EndIf;
					
					If MinQueue = 0 Then
						MinQueue = UpdateCycle.HandlersQueue[0].Queue;
					Else
						MinCycleQueue = UpdateCycle.HandlersQueue[0].Queue;
						MinQueue = Min(MinQueue, MinCycleQueue);
					EndIf;
				EndDo;
			EndIf;
			
			If Not HasProcessedObjects
				AND HandlerQueue = MinQueue Then
				AttemptCount = UpdateHandler.AttemptCount;
				MaxAttempts = MaxUpdateAttempts(UpdateInfo, UpdateHandler) - 1;
				If AttemptCount >= MaxAttempts AND AllHandlersLoop(UpdateInfo) Then
					ExceptionText = NStr("ru = 'Произошло зацикливание процедуры обработки данных. Выполнение прервано.'; en = 'The data processing procedure went into an endless loop and was canceled.'; pl = 'Nastąpiło zapętlenie procedury przetwarzania danych. Wykonanie przerwano.';de = 'Das Datenverarbeitungsverfahren läuft zyklisch ab. Die Ausführung wird unterbrochen.';ro = 'Loopingul procedurii de procesare a datelor. Executare întreruptă.';tr = 'Veri işleme prosedürü döngüsü takıldı.  Yürütme durduruldu.'; es_ES = 'El procedimiento del procesamiento de datos ha entrado en ciclo. Realización interrumpida.'");
					Raise ExceptionText;
				Else
					AttemptsCountToAdd = AttemptsCountToAdd(UpdateHandler, HandlerContext);
					UpdateHandler.AttemptCount = AttemptCount + AttemptsCountToAdd;
				EndIf;
			Else
				UpdateHandler.AttemptCount = 0;
			EndIf;
		EndIf;
		
		// Saving data for the data processing procedure.
		If UpdateHandler.Multithreaded Then
			ExecutionProgress = UpdateHandler.ExecutionStatistics[ExecutionProgress];
			If ExecutionProgress = Undefined Then
				UpdateHandler.ExecutionStatistics.Insert("ExecutionProgress", Parameters.ExecutionProgress);
			Else
				ProcessedObjectsCount = Parameters.ExecutionProgress.ProcessedObjectsCount;
				ExecutionProgress.ProcessedObjectsCount = ExecutionProgress.ProcessedObjectsCount + ProcessedObjectsCount;
			EndIf;
		Else
			UpdateHandler.ExecutionStatistics.Insert("ExecutionProgress", Parameters.ExecutionProgress);
		EndIf;
		
		UpdateProcedureStartCount = UpdateProcedureStartCount(UpdateHandler) + 1;
		ExecutionDuration = DataProcessingCompletion - HandlerContext.DataProcessingStart;
		If UpdateHandler.ExecutionStatistics["ExecutionDuration"] <> Undefined Then
			ExecutionDuration = ExecutionDuration + UpdateHandler.ExecutionStatistics["ExecutionDuration"];
		EndIf;
		UpdateHandler.ExecutionStatistics.Insert("ExecutionDuration", ExecutionDuration);
		UpdateHandler.ExecutionStatistics.Insert("StartsCount", UpdateProcedureStartCount);
	Except
		ProcessHandlerException(HandlerContext, UpdateHandler, ErrorInfo());
	EndTry;
	
EndProcedure

// Completing the data processing procedure.
//
// Parameters:
//  HandlerContext - Structure - see NewHandlerContext(). 
//  UpdateHandler - ValueTreeRow - the update handler represented as a row of the handler tree.
//  UpdateInfo - Structure - update information (see NewUpdateInfo()).
//
Procedure EndDataProcessingProcedure(HandlerContext, UpdateHandler, UpdateInfo)
	
	Parameters = HandlerContext.Parameters;
	
	// Saving the parameters passed by the update handler, if any.
	PassedParameters = PassedUpdateHandlerParameters(Parameters);
	UpdateHandler.ExecutionStatistics.Insert("HandlerParameters", PassedParameters);
	
	If HandlerContext.HasOpenTransactions Then
		// If a nested transaction is found, the update handler is not called again.
		UpdateHandler.Status = "Error";
		UpdateHandler.ErrorInfo = String(UpdateHandler.ErrorInfo)
			+ Chars.LF + HandlerContext.ErrorInfo;
		
		UpdateHandler.AttemptCount = MaxUpdateAttempts(UpdateInfo, UpdateHandler);
	EndIf;
	
	If HandlerContext.WriteToLog Then
		WriteUpdateProgressDetails(HandlerContext.HandlerFullDetails);
	EndIf;
	
EndProcedure

Procedure GenerateDeferredUpdatePlan(IBUpdateInfo, RepeatedGeneration = False) Export
	
	IsSubordinateDIBNode = Common.IsSubordinateDIBNode();
	IsSubordinateDIBNodeWithFilter = Common.IsSubordinateDIBNodeWithFilter();
	
	HandlersTree = IBUpdateInfo.HandlersTree;
	SubsystemsDetails = StandardSubsystemsCached.SubsystemsDetails();
	
	// Initialize parameters.
	UpdatePlan = New Array;
	HasMasterNodeHandlersOnly = False;
	
	LockedObjectsInfo = NewLockedObjectsInfo();
	For Each Subsystem In SubsystemsDetails.Order Do
		
		SubsystemDetails = SubsystemsDetails.ByNames[Subsystem];
		ExecutionMode    = SubsystemDetails.DeferredHandlerExecutionMode;
		ParallelSinceVersion = SubsystemDetails.ParralelDeferredUpdateFromVersion;
		
		HandlerTreeLibrary = HandlersTree.Rows.Find(Subsystem, "LibraryName");
		If HandlerTreeLibrary = Undefined Then
			Continue;
		EndIf;
		
		HandlersTable = New ValueTable;
		HandlersTable.Columns.Add("Handler", New TypeDescription("String"));
		HandlersTable.Columns.Add("ID", New TypeDescription("UUID"));
		HandlersTable.Columns.Add("Queue", New TypeDescription("Number"));
		
		Iteration = 1;
		CreateNewIteration = True;
		SkipCheck     = False;
		For Each HandlerTreeVersion In HandlerTreeLibrary.Rows Do
			If Not RepeatedGeneration Then
				FillLockedItems(HandlerTreeVersion, IBUpdateInfo, LockedObjectsInfo);
			EndIf;
			
			If CreateNewIteration Then
				UpdateIteration = New Structure;
				UpdateIteration.Insert("Mode", "");
				UpdateIteration.Insert("DependsOnPrevious", False);
				UpdateIteration.Insert("Handlers");
			EndIf;
			
			If ExecutionMode = "Sequentially" Then
				UpdateIteration.Mode = ExecutionMode;
				UpdateIteration.DependsOnPrevious = ?(Iteration = 1, False, True);
				UpdateIteration.Handlers = New Array;
			ElsIf ExecutionMode = "Parallel" AND Not ValueIsFilled(ParallelSinceVersion) AND Iteration = 1 Then
				UpdateIteration.Mode = ExecutionMode;
				UpdateIteration.Handlers = HandlersTable.Copy();
				CreateNewIteration = False;
			ElsIf ExecutionMode = "Parallel" AND ValueIsFilled(ParallelSinceVersion) AND Not SkipCheck Then
				VersionNumber = HandlerTreeVersion.VersionNumber;
				If VersionNumber = "*" Then
					Result = -1;
				Else
					Result = CommonClientServer.CompareVersions(VersionNumber, ParallelSinceVersion);
				EndIf;
				
				If Result < 0 Then
					UpdateIteration.Mode = "Sequentially";
					UpdateIteration.DependsOnPrevious = (Iteration <> 1);
					UpdateIteration.Handlers = New Array;
				Else
					UpdateIteration.Mode = ExecutionMode;
					UpdateIteration.DependsOnPrevious = (Iteration <> 1);
					UpdateIteration.Handlers = HandlersTable.Copy();
					SkipCheck = True;
					CreateNewIteration = False;
				EndIf;
			EndIf;
			
			For Each Handler In HandlerTreeVersion.Rows Do
				If RepeatedGeneration AND Handler.Status = "Completed" Then
					Continue;
				EndIf;
				
				If UpdateIteration.Mode = "Parallel" AND Not IsSubordinateDIBNode
					AND Handler.ExecuteInMasterNodeOnly = True Then
					HasMasterNodeHandlersOnly = True;
				EndIf;
				
				If UpdateIteration.Mode = "Parallel" AND IsSubordinateDIBNodeWithFilter
					AND Not Handler.RunAlsoInSubordinateDIBNodeWithFilters Then
					HasMasterNodeHandlersOnly = True;
					Continue;
				EndIf;
				
				If UpdateIteration.Mode = "Parallel" Then
					RowHandler = UpdateIteration.Handlers.Add();
					RowHandler.Handler    = Handler.HandlerName;
					RowHandler.ID = Handler.ID;
					RowHandler.Queue       = Handler.DeferredProcessingQueue;
				Else
					HandlerDetails = New Structure;
					HandlerDetails.Insert("HandlerName", Handler.HandlerName);
					HandlerDetails.Insert("ID", Handler.ID);
					HandlerDetails.Insert("Iteration", 0);
					
					UpdateIteration.Handlers.Add(HandlerDetails);
				EndIf;
				
			EndDo;
			
			// In parallel mode, only handlers with ExecuteAlsoInSubordinateDIBNodeWithFilters = True are 
			// executed in DIB with filters in a subordinate node.
			If IsSubordinateDIBNodeWithFilter AND UpdateIteration.Mode = "Parallel" Then
				FilterParameters = New Structure;
				FilterParameters.Insert("RunAlsoInSubordinateDIBNodeWithFilters", False);
				MasterNodeHandlersOnly = HandlerTreeVersion.Rows.FindRows(FilterParameters);
				For Each MasterNodeHandler In MasterNodeHandlersOnly Do
					HandlerTreeVersion.Rows.Delete(MasterNodeHandler);
				EndDo;
			EndIf;
			
			If CreateNewIteration Then
				UpdatePlan.Add(UpdateIteration);
			EndIf;
			
			Iteration = Iteration + 1 ;
			
		EndDo;
		
		If Not CreateNewIteration Then
			UpdatePlan.Add(UpdateIteration);
		EndIf;
	EndDo;
	
	If Not RepeatedGeneration Then
		WriteLockedObjectsInfo(LockedObjectsInfo);
		Constants.DeferredMasterNodeUpdateCompleted.Set(Not HasMasterNodeHandlersOnly);
	EndIf;
	
	HandlerDetails = New Structure;
	HandlerDetails.Insert("HandlerName", "");
	HandlerDetails.Insert("Iteration", 0);
	
	// Converting the handler storage format.
	For Each UpdateCycle In UpdatePlan Do
		If TypeOf(UpdateCycle.Handlers) = Type("Array") Then
			Continue;
		EndIf;
		HandlersTable = UpdateCycle.Handlers.Copy();
		HandlersTable.Sort("Queue Asc");
		
		UpdateCycle.Handlers = New Array;
		For Each Item In HandlersTable Do
			HandlerDetails = New Structure;
			HandlerDetails.Insert("HandlerName", Item.Handler);
			HandlerDetails.Insert("ID", Item.ID);
			HandlerDetails.Insert("Iteration", 0);
			
			UpdateCycle.Handlers.Add(HandlerDetails);
		EndDo;
		
		UpdateCycle.Insert("HandlersQueue", HandlersTable);
	EndDo;
	
	IBUpdateInfo.DeferredUpdatePlan = UpdatePlan;
	
EndProcedure

Procedure FillLockedItems(VersionRow, UpdateInfo, LockedObjectsInfo)
	
	For Each Handler In VersionRow.Rows Do
		CheckProcedure  = Handler.CheckProcedure;
		ObjectsToLock = Handler.ObjectsToLock;
		If ValueIsFilled(CheckProcedure) AND ValueIsFilled(ObjectsToLock) Then
			HandlerProperties = New Structure;
			HandlerProperties.Insert("Completed", False);
			HandlerProperties.Insert("CheckProcedure", CheckProcedure);
			
			LockedObjectsInfo.Handlers.Insert(Handler.HandlerName, HandlerProperties);
			LockedObjectArray = StrSplit(ObjectsToLock, ",");
			For Each LockedObject In LockedObjectArray Do
				LockedObject = StrReplace(TrimAll(LockedObject), ".", "");
				ObjectInformation = LockedObjectsInfo.ObjectsToLock[LockedObject];
				If ObjectInformation = Undefined Then
					HandlersArray = New Array;
					HandlersArray.Add(Handler.HandlerName);
					LockedObjectsInfo.ObjectsToLock.Insert(LockedObject, HandlersArray);
				Else
					LockedObjectsInfo.ObjectsToLock[LockedObject].Add(Handler.HandlerName);
				EndIf;
			EndDo;
		ElsIf ValueIsFilled(ObjectsToLock) AND Not ValueIsFilled(CheckProcedure) Then
			ExceptionText = NStr("ru = 'У отложенного обработчика обновления ""%1""
				|заполнен список блокируемых объектов, но не задано свойство ""ПроцедураПроверки"".'; 
				|en = 'The list of locked objects is filled for deferred update handler %1
				|but the CheckProcedure property is not set.'; 
				|pl = 'W odroczonym programie przetwarzania aktualizacji ""%1""
				|jest wypełniona lista blokowanych obiektów, ale nie jest ustawiona właściwość ""CheckProcedure"".';
				|de = 'Die Liste der zu sperrenden Objekte wird im verzögerten Update-Handler ""%1""
				|ausgefüllt, aber die Eigenschaft ""CheckProcedure"" ist nicht eingestellt.';
				|ro = 'La handlerul de actualizare amânat ""%1""
				|este completată lista obiectelor blocate, dar nu este specificată proprietatea ""CheckProcedure"".';
				|tr = 'Ertelenmiş güncelleştirme işleyicisi ""%1"" engellenen nesnelerin bir listesini dolduruldu, 
				|ancak ""CheckProcedure"" özelliği ayarlanmamıştır.'; 
				|es_ES = 'Para el procesador aplazado de la actualización ""%1""
				|está rellenada la lista de los objetos bloqueados pero no está establecido la propiedad ""CheckProcedure"".'");
			
			Raise StringFunctionsClientServer.SubstituteParametersToString(ExceptionText, Handler.HandlerName);
		EndIf;
	EndDo;
	
EndProcedure

Procedure AttachDetachDeferredUpdateHandlers(UpdateInfo)
	
	UpdatePlan          = UpdateInfo.DeferredUpdatePlan;
	StartHandlers    = Undefined;
	StopHandlers   = Undefined;
	SpeedPriority = Undefined;
	SchedulePriority  = Undefined;
	
	UpdateInfo.DeferredUpdateManagement.Property("RunHandlers", StartHandlers);
	UpdateInfo.DeferredUpdateManagement.Property("StopHandlers", StopHandlers);
	UpdateInfo.DeferredUpdateManagement.Property("SpeedPriority", SpeedPriority);
	UpdateInfo.DeferredUpdateManagement.Property("SchedulePriority", SchedulePriority);
	
	// Starting the deferred update handlers that were stopped.
	If StartHandlers <> Undefined Then
		For Each RunningHandler In StartHandlers Do
			FoundHandler = UpdateInfo.HandlersTree.Rows.Find(RunningHandler, "HandlerName", True);
			If FoundHandler <> Undefined Then
				FoundHandler.Status = "NotCompleted";
				
				For Each UpdateCycle In UpdatePlan Do
					For Each HandlerDetails In UpdateCycle.Handlers Do
						If HandlerDetails.HandlerName = FoundHandler.HandlerName Then
							If UpdateCycle.Property("HasStopped") Then
								UpdateCycle.Delete("HasStopped");
							EndIf;
							Break;
						EndIf;
					EndDo;
				EndDo;
				
			EndIf;
		EndDo;
		
		UpdateInfo.DeferredUpdateManagement.Delete("RunHandlers");
	EndIf;
	
	// Stopping the deferred update handlers that are running.
	If StopHandlers <> Undefined Then
		For Each StoppedHandler In StopHandlers Do
			FoundHandler = UpdateInfo.HandlersTree.Rows.Find(StoppedHandler, "HandlerName", True);
			If FoundHandler <> Undefined
				AND FoundHandler.Status <> "Completed" Then
				FoundHandler.Status = "Paused";
			EndIf;
		EndDo;
		
		UpdateInfo.DeferredUpdateManagement.Delete("StopHandlers");
	EndIf;
	
	// Increasing priority of the data processing procedure.
	If SpeedPriority <> Undefined Then
		For Each Handler In SpeedPriority Do
			FoundHandler = UpdateInfo.HandlersTree.Rows.Find(Handler, "HandlerName", True);
			If FoundHandler <> Undefined
				AND FoundHandler.Status <> "Completed" Then
				FoundHandler.Priority = "HighPriority";
			EndIf;
		EndDo;
		
		UpdateInfo.DeferredUpdateManagement.Delete("SpeedPriority");
	EndIf;
	
	// Decreasing priority of the data processing procedure.
	If SchedulePriority <> Undefined Then
		For Each Handler In SchedulePriority Do
			FoundHandler = UpdateInfo.HandlersTree.Rows.Find(Handler, "HandlerName", True);
			If FoundHandler <> Undefined
				AND FoundHandler.Status <> "Completed" Then
				FoundHandler.Priority = "OnSchedule";
			EndIf;
		EndDo;
		
		UpdateInfo.DeferredUpdateManagement.Delete("SchedulePriority");
	EndIf;
	
	If StartHandlers <> Undefined
		Or StopHandlers <> Undefined
		Or SpeedPriority <> Undefined
		Or SchedulePriority <> Undefined Then
		WriteInfobaseUpdateInfo(UpdateInfo);
	EndIf;
	
EndProcedure

Function NewLockedObjectsInfo(PreviousInfo = Undefined)
	
	LockedObjectsInfo = New Structure;
	LockedObjectsInfo.Insert("ObjectsToLock", New Map);
	LockedObjectsInfo.Insert("Handlers", New Map);
	
	If TypeOf(PreviousInfo) = Type("Structure") Then
		FillPropertyValues(LockedObjectsInfo, PreviousInfo);
	EndIf;
	
	Return LockedObjectsInfo;
	
EndFunction

Procedure WriteLockedObjectsInfo(Info)
	
	If Info = Undefined Then
		NewValue = NewLockedObjectsInfo();
	Else
		NewValue = Info;
	EndIf;
	
	ConstantManager = Constants.LockedObjectsInfo.CreateValueManager();
	ConstantManager.Value = New ValueStorage(NewValue);
	InfobaseUpdate.WriteData(ConstantManager);
	
EndProcedure

Procedure FillDataForParallelDeferredUpdate(UpdateInfo, Parameters)
	
	If Not Common.SeparatedDataUsageAvailable() Then
		CanlcelDeferredUpdateHandlersRegistration();
		Return;
	EndIf;
	
	If Parameters.OnClientStart
		AND Parameters.DeferredUpdateMode = "Deferred" Then
		ClientServer  = Not Common.FileInfobase();
		Box       = Not Common.DataSeparationEnabled();
		
		If ClientServer AND Box Then
			// Skipping data registration for now.
			Return;
		EndIf;
	EndIf;
	
	If Not (StandardSubsystemsCached.DIBUsed("WithFilter") AND Common.IsSubordinateDIBNode()) Then
		Query = New Query;
		Query.Text = 
		"SELECT
		|	InfobaseUpdate.Ref AS Node
		|FROM
		|	ExchangePlan.InfobaseUpdate AS InfobaseUpdate
		|WHERE
		|	NOT InfobaseUpdate.ThisNode";
		
		Selection = Query.Execute().Select();
		While Selection.Next() Do
			ExchangePlans.DeleteChangeRecords(Selection.Node);
		EndDo;
	EndIf;
	
	If Not Common.IsSubordinateDIBNode()
		AND Common.SubsystemExists("StandardSubsystems.DataExchange") Then
		ModuleDataExchangeServer = Common.CommonModule("DataExchangeServer");
		ModuleDataExchangeServer.ClearConstantValueWithChangesForSUbordinateDIBNodeWithFilters();
	EndIf;
	
	DataToProcess = New Map;
	LibraryDetailsList = StandardSubsystemsCached.SubsystemsDetails().ByNames;
	ParametersInitialized = False;
	
	For Each RowLibrary In UpdateInfo.HandlersTree.Rows Do
		
		If LibraryDetailsList[RowLibrary.LibraryName].DeferredHandlerExecutionMode <> "Parallel" Then
			Continue;
		EndIf;
		
		ParallelSinceVersion = LibraryDetailsList[RowLibrary.LibraryName].ParralelDeferredUpdateFromVersion;
		
		If Not ParametersInitialized Then
			
			HandlerParametersStructure = InfobaseUpdate.MainProcessingMarkParameters();
			ParametersInitialized = True;
			
			If Common.SubsystemExists("StandardSubsystems.DataExchange") Then
				ModuleDataExchangeServer = Common.CommonModule("DataExchangeServer");
				ModuleDataExchangeServer.InitializeUpdateDataFile(HandlerParametersStructure);
			EndIf;
			
		EndIf;
		
		For Each VersionRow In RowLibrary.Rows Do
			If VersionRow.VersionNumber = "*" Then
				Continue;
			EndIf;
			
			If ValueIsFilled(ParallelSinceVersion)
				AND CommonClientServer.CompareVersions(VersionRow.VersionNumber, ParallelSinceVersion) < 0 Then
				Continue;
			EndIf;
			
			For Each Handler In VersionRow.Rows Do
				
				HandlerParametersStructure.Queue = Handler.DeferredProcessingQueue;
				HandlerParametersStructure.Insert("HandlerData", New Map);
				
				If Handler.Multithreaded Then
					HandlerParametersStructure.SelectionParameters =
						InfobaseUpdate.AdditionalMultithreadProcessingDataSelectionParameters();
				Else
					HandlerParametersStructure.SelectionParameters = Undefined;
				EndIf;
				
				HandlerParameters = New Array;
				HandlerParameters.Add(HandlerParametersStructure);
				Try
					Message = NStr("ru = 'Выполняется процедура заполнения данных
						                   |""%1""
						                   |отложенного обработчика обновления
						                   |""%2"".'; 
						                   |en = 'Executing data population procedure
						                   |%1
						                   |of deferred update handler
						                   |%2.'; 
						                   |pl = 'Jest wykonywana procedura wypełnienia danych
						                   |""%1""
						                   |odroczonego programu przetwarzania aktualizacji
						                   |""%2"".';
						                   |de = 'Der Vorgang zum Ausfüllen der Daten 
						                   |""%1""
						                   | des verzögerten Update-Handlers 
						                   |""%2"" wird durchgeführt.';
						                   |ro = 'Are loc executarea completării datelor
						                   |""%1""
						                   |handlerului de actualizare amânat
						                   |""%2"".';
						                   |tr = '"
"%1Ertelenmiş güncelleme işleyicisinin 
						                   |veri doldurma prosedürü yürütülüyor 
						                   |%2.'; 
						                   |es_ES = 'Se está realizando el procedimiento de relleno de datos
						                   |""%1""
						                   | del procesador aplazado de actualización
						                   |""%2"".'");
					Message = StringFunctionsClientServer.SubstituteParametersToString(Message,
						Handler.UpdateDataFillingProcedure,
						Handler.HandlerName);
					WriteInformation(Message);
					
					Common.ExecuteConfigurationMethod(Handler.UpdateDataFillingProcedure, HandlerParameters);
					
					// Writing the progress update.
					If Parameters.InBackground Then
						HandlerExecutionProgress = Parameters.HandlerExecutionProgress;
						HandlerExecutionProgress.CompletedHandlersCount = HandlerExecutionProgress.CompletedHandlersCount + 1;
						Progress = 10 + HandlerExecutionProgress.CompletedHandlersCount / HandlerExecutionProgress.TotalHandlerCount * 90;
						TimeConsumingOperations.ReportProgress(Progress);
					EndIf;
				Except
					CanlcelDeferredUpdateHandlersRegistration(RowLibrary.LibraryName, False);
					WriteError(StringFunctionsClientServer.SubstituteParametersToString(
						NStr("ru = 'При вызове процедуры заполнения данных
								   |""%1""
								   |отложенного обработчика обновления
								   |""%2""
								   |произошла ошибка:
								   |""%3"".'; 
								   |en = 'Error while calling data population procedure
								   |%1
								   |of deferred update handler
								   |%2.
								   |Error:
								   |%3.'; 
								   |pl = 'Podczas wywołania procedury wypełnienia danych
								   |""%1""
								   |odroczonego programu przetwarzania aktualizacji
								   |""%2""
								   |zaistniał błąd:
								   |""%3"".';
								   |de = 'Beim Aufrufen der Prozedur zum Füllen der Daten
								   |""%1""
								   | des verzögerten Update-Handlers
								   |""%2""
								   | ist ein Fehler aufgetreten:
								   |""%3"".';
								   |ro = 'La apelarea procedurii de completare a datelor
								   |""%1""
								   |handlerului de actualizare amânat
								   |""%2""
								   |s-a produs eroarea:
								   |""%3"".';
								   |tr = 'Ertelenen güncelleştirme işleyicisi "
" %1
								   |veri doldurma %3prosedürü çağrıldığında bir 
								   |
								   |hata oluştu:%2 "
".'; 
								   |es_ES = 'Al llamar el procedimiento del relleno de datos
								   |""%1""
								   | del procesador aplazado de actualización
								   |""%2""
								   |se ha producido un error:
								   |""%3"".'"),
						Handler.UpdateDataFillingProcedure,
						Handler.HandlerName,
						DetailErrorDescription(ErrorInfo())));
					
					Raise;
				EndTry;
				
				DataToProcessDetails = NewDataToProcessDetails(Handler.Multithreaded);
				DataToProcessDetails.HandlerData = HandlerParametersStructure.HandlerData;
				
				If Handler.Multithreaded Then
					DataToProcessDetails.SelectionParameters = HandlerParametersStructure.SelectionParameters;
				EndIf;
				
				DataToProcess.Insert(Handler.HandlerName, DataToProcessDetails);
			EndDo;
		EndDo;
		
	EndDo;
	
	UpdateInfo.DataToProcess = DataToProcess;
	CanlcelDeferredUpdateHandlersRegistration();
	
	If ParametersInitialized AND Common.SubsystemExists("StandardSubsystems.DataExchange") Then
		ModuleDataExchangeServer = Common.CommonModule("DataExchangeServer");
		ModuleDataExchangeServer.CompleteWriteUpdateDataFile(HandlerParametersStructure);
	EndIf;
	
EndProcedure

// Fills data for parallel deferred update in background using multiple threads.
//
// Parameters:
//  FormID - UUID - the ID of the form that displays the update progress.
//  ResultAddress - String - address of the temporary storage used to store the procedure result.
//
Procedure StartDeferredHandlerDataRegistration(FormID, ResultAddress) Export
	
	UpdateInfo = InfobaseUpdateInfo();
	ThreadsDetails = NewDetailsOfDeferredUpdateDataRegistrationThreads();
	UpdateInfo.ThreadsDetails = ThreadsDetails;
	
	Try
		For each DataToProcessDetails In UpdateInfo.DataToProcess Do
			Thread = AddDeferredUpdateDataRegistrationThread(ThreadsDetails, DataToProcessDetails.Value);
			ExecuteThread(ThreadsDetails, Thread, FormID);
			WaitForAvailableThread(ThreadsDetails, UpdateInfo);
			WriteInfobaseUpdateInfo(UpdateInfo);
		EndDo;
		
		WaitForAllThreadsCompletion(ThreadsDetails, UpdateInfo);
		SaveThreadsStateToUpdateInfo(Undefined, UpdateInfo);
	Except
		CancelAllThreadsExecution(UpdateInfo.ThreadsDetails);
		SaveThreadsStateToUpdateInfo(Undefined, UpdateInfo);
		Raise;
	EndTry;
	
EndProcedure

// Fills data for the deferred handler in a background job.
//
// Parameters:
//  DataToProcessDetails - Structure - (see NewDataToProcessDetails()).
//  ResultAddress - String - an address of the temporary storage for storing the procedure result.
//
Procedure FillDeferredHandlerData(DataToProcessDetails, ResultAddress) Export
	
	ProcessingMarkParameters = InfobaseUpdate.MainProcessingMarkParameters();
	DataExchangeSubsystemExists = Common.SubsystemExists("StandardSubsystems.DataExchange");
	
	If DataExchangeSubsystemExists Then
		ModuleDataExchangeServer = Common.CommonModule("DataExchangeServer");
		ModuleDataExchangeServer.InitializeUpdateDataFile(ProcessingMarkParameters);
	EndIf;
	
	ProcessingMarkParameters.Queue = DataToProcessDetails.Queue;
	ProcessingMarkParameters.Insert("HandlerData", New Map);
	MultithreadMode = IsMultithreadHandlerDataDetails(DataToProcessDetails);
	
	If MultithreadMode Then
		ProcessingMarkParameters.SelectionParameters =
			InfobaseUpdate.AdditionalMultithreadProcessingDataSelectionParameters();
	Else
		ProcessingMarkParameters.SelectionParameters = Undefined;
	EndIf;
	
	HandlerParameters = New Array;
	HandlerParameters.Add(ProcessingMarkParameters);
	
	MessageTemplate = NStr(
		"ru = 'Выполняется процедура заполнения данных
		|""%1""
		|отложенного обработчика обновления
		|""%2"".'; 
		|en = 'Executing data population procedure
		|%1
		|of deferred update handler
		|%2.'; 
		|pl = 'Jest wykonywana procedura wypełnienia danych
		|""%1""
		|odroczonego programu przetwarzania aktualizacji
		|""%2"".';
		|de = 'Der Vorgang zum Ausfüllen der Daten 
		|""%1""
		| des verzögerten Update-Handlers 
		|""%2"" wird durchgeführt.';
		|ro = 'Are loc executarea completării datelor
		|""%1""
		|handlerului de actualizare amânat
		|""%2"".';
		|tr = '"
"%1Ertelenmiş güncelleme işleyicisinin 
		|veri doldurma prosedürü yürütülüyor 
		|%2.'; 
		|es_ES = 'Se está realizando el procedimiento de relleno de datos
		|""%1""
		| del procesador aplazado de actualización
		|""%2"".'");
	MessageText = StringFunctionsClientServer.SubstituteParametersToString(MessageTemplate,
		DataToProcessDetails.FillingProcedure,
		DataToProcessDetails.HandlerName);
	WriteInformation(MessageText);
	
	Try
		Common.ExecuteConfigurationMethod(DataToProcessDetails.FillingProcedure, HandlerParameters);
	Except
		ErrorInformation = DetailErrorDescription(ErrorInfo());
		ErrorTemplate = NStr(
			"ru = 'При вызове процедуры заполнения данных
			|""%1""
			|отложенного обработчика обновления
			|""%2""
			|произошла ошибка:
			|""%3"".'; 
			|en = 'Error while calling data population procedure
			|%1
			|of deferred update handler
			|%2.
			|Error:
			|%3.'; 
			|pl = 'Podczas wywołania procedury wypełnienia danych
			|""%1""
			|odroczonego programu przetwarzania aktualizacji
			|""%2""
			|zaistniał błąd:
			|""%3"".';
			|de = 'Beim Aufrufen der Prozedur zum Füllen der Daten
			|""%1""
			| des verzögerten Update-Handlers
			|""%2""
			| ist ein Fehler aufgetreten:
			|""%3"".';
			|ro = 'La apelarea procedurii de completare a datelor
			|""%1""
			|handlerului de actualizare amânat
			|""%2""
			|s-a produs eroarea:
			|""%3"".';
			|tr = 'Ertelenen güncelleştirme işleyicisi "
" %1
			|veri doldurma %3prosedürü çağrıldığında bir 
			|
			|hata oluştu:%2 "
".'; 
			|es_ES = 'Al llamar el procedimiento del relleno de datos
			|""%1""
			| del procesador aplazado de actualización
			|""%2""
			|se ha producido un error:
			|""%3"".'");
		MessageText = StringFunctionsClientServer.SubstituteParametersToString(ErrorTemplate,
			DataToProcessDetails.FillingProcedure,
			DataToProcessDetails.HandlerName,
			ErrorInformation);
		WriteError(MessageText);
		Raise;
	EndTry;
	
	Result = New Structure;
	Result.Insert("HandlerData", ProcessingMarkParameters.HandlerData);
	
	If MultithreadMode Then
		Result.Insert("SelectionParameters", ProcessingMarkParameters.SelectionParameters);
	EndIf;
	
	If DataExchangeSubsystemExists Then
		UpdateData = ModuleDataExchangeServer.CompleteWriteFileAndGetUpdateData(ProcessingMarkParameters);
		Result.Insert("UpdateData", UpdateData);
		Result.Insert("NameOfChangedFile", ProcessingMarkParameters.NameOfChangedFile);
	EndIf;
	
	PutToTempStorage(Result, ResultAddress);
	
EndProcedure

Procedure SetUpdateHandlerParameters(UpdateHandler, Deferred = False, Parallel = False)
	
	If UpdateHandler = Undefined Then
		SessionParameters.UpdateHandlerParameters = New FixedStructure(NewUpdateHandlerParameters());
		Return;
	EndIf;
	
	If Deferred Then
		ExecutionMode = "Deferred";
		HandlerName = UpdateHandler.HandlerName;
	Else
		ExecutionMode = "Exclusive";
		HandlerName = UpdateHandler.Procedure;
	EndIf;
	
	If Parallel Then
		DeferredHandlerExecutionMode = "Parallel";
	Else
		DeferredHandlerExecutionMode = "Sequentially";
	EndIf;
	
	UpdateHandlerParameters = NewUpdateHandlerParameters();
	UpdateHandlerParameters.ExecuteInMasterNodeOnly = UpdateHandler.ExecuteInMasterNodeOnly;
	UpdateHandlerParameters.RunAlsoInSubordinateDIBNodeWithFilters = UpdateHandler.RunAlsoInSubordinateDIBNodeWithFilters;
	UpdateHandlerParameters.DeferredProcessingQueue = UpdateHandler.DeferredProcessingQueue;
	UpdateHandlerParameters.ExecutionMode = ExecutionMode;
	UpdateHandlerParameters.DeferredHandlerExecutionMode = DeferredHandlerExecutionMode;
	UpdateHandlerParameters.HasProcessedObjects = False;
	UpdateHandlerParameters.HandlerName = HandlerName;
	
	SessionParameters.UpdateHandlerParameters = New FixedStructure(UpdateHandlerParameters);
	
EndProcedure

Function NewUpdateHandlerParameters() Export
	UpdateHandlerParameters = New Structure;
	UpdateHandlerParameters.Insert("ExecuteInMasterNodeOnly", False);
	UpdateHandlerParameters.Insert("RunAlsoInSubordinateDIBNodeWithFilters", False);
	UpdateHandlerParameters.Insert("DeferredProcessingQueue", 0);
	UpdateHandlerParameters.Insert("ExecutionMode", "");
	UpdateHandlerParameters.Insert("DeferredHandlerExecutionMode", "");
	UpdateHandlerParameters.Insert("HasProcessedObjects", False);
	UpdateHandlerParameters.Insert("HandlerName", "");
	
	Return UpdateHandlerParameters;
EndFunction

// Processes an exception that was raised while preparing or completing handler execution in the main thread.
//
// Parameters:
//  HandlerContext - Structure - see NewHandlerContext(). 
//  UpdateHandler - ValueTreeRow - the update handler represented as a row of the handler tree.
//
Procedure ProcessHandlerException(HandlerContext, UpdateHandler, ErrorInformation)
	
	If HandlerContext.WriteToLog Then
		WriteUpdateProgressDetails(HandlerContext.HandlerFullDetails);
	EndIf;
	
	While TransactionActive() Do
		RollbackTransaction();
	EndDo;
	
	AttemptsCountToAdd = AttemptsCountToAdd(UpdateHandler, HandlerContext, True);
	UpdateHandler.AttemptCount = UpdateHandler.AttemptCount + AttemptsCountToAdd;
	DetailedErrorPresentation = DetailErrorDescription(ErrorInformation);
	
	MaxUpdateAttempts = MaxUpdateAttempts(InfobaseUpdateInfo(), UpdateHandler);
	
	If UpdateHandler.AttemptCount < MaxUpdateAttempts Then
		WriteWarning(DetailedErrorPresentation);
	Else
		WriteError(DetailedErrorPresentation);
	EndIf;
	
	If UpdateHandler.Status <> "Error" Then
		UpdateHandler.Status = "Error";
		UpdateHandler.ErrorInfo = DetailedErrorPresentation;
	EndIf;
	
EndProcedure

// Process the fragment received as a result of splitting data search result for an update in a separate thread.
//
// Parameters:
//  Particle - Array - see NewBatchesSetForUpdate(). 
//  ThreadsDetails - Structure - see NewThreadsDetails(). 
//  HandlerContext - Structure - see NewHandlerContext(). 
//
Procedure ProcessDataFragmentInThread(Fragment, ThreadsDetails, HandlerContext)
	
	HandlerContextForThread = Common.CopyRecursive(HandlerContext);
	HandlerContextForThread.Parameters.DataToUpdate = Fragment;
	Thread = ThreadsDetails.Threads.Add();
	AddUpdateHandlerThread(Thread, HandlerContextForThread);
	ExecuteThread(ThreadsDetails, Thread);
	HandlerContextForThread.Parameters.DataToUpdate.DataSet = Undefined;
	
EndProcedure

// Sets error status for all looped handlers.
//
// Parameters:
//  UpdateInfo - Structure - update information (see NewUpdateInfo()).
//
// Returns:
//  Boolean - True if all running handlers are looped (AttemptCount >= Max), False if at least one handler is running normally.
//
Procedure MarkLoopingHandlers(UpdateInfo)
	
	Filter = New Structure("Status", "Running");
	Running = UpdateInfo.HandlersTree.Rows.FindRows(Filter, True);
	
	For each UpdateHandler In Running Do
		MaxAttempts = MaxUpdateAttempts(UpdateInfo, UpdateHandler) - 1;
		
		If UpdateHandler.AttemptCount >= MaxAttempts Then
			UpdateHandler.Status = "Error";
			UpdateHandler.ErrorInfo = NStr("ru = 'Произошло зацикливание процедуры обработки данных. Выполнение прервано.'; en = 'The data processing procedure went into an endless loop and was canceled.'; pl = 'Nastąpiło zapętlenie procedury przetwarzania danych. Wykonanie przerwano.';de = 'Das Datenverarbeitungsverfahren läuft zyklisch ab. Die Ausführung wird unterbrochen.';ro = 'Loopingul procedurii de procesare a datelor. Executare întreruptă.';tr = 'Veri işleme prosedürü döngüsü takıldı.  Yürütme durduruldu.'; es_ES = 'El procedimiento del procesamiento de datos ha entrado en ciclo. Realización interrumpida.'");
		EndIf;
	EndDo;
	
EndProcedure

// Checks whether all running handlers are looped.
// Handlers are considered to be looped if any of these conditions are met:
// - All running handlers have attempt count >=2
// - or
// - At least one running handler has attempt count >=2
// - and
// - At least one handler has completed with errors.
//
// Parameters:
//  UpdateInfo - Structure - update information (see NewUpdateInfo()).
//
// Returns:
//  Boolean - True if all  handlers are looped.
//
Function AllHandlersLoop(UpdateInfo)
	
	Filter = New Structure("Status", "Running");
	HandlersTree = UpdateInfo.HandlersTree;
	Running = HandlersTree.Rows.FindRows(Filter, True);
	
	If Running.Count() > 0 Then
		HasExceeding = False;
		HasNormal = False;
		
		For each UpdateHandler In Running Do
			MaxAttempts = MaxUpdateAttempts(UpdateInfo, UpdateHandler) - 1;
			
			If UpdateHandler.AttemptCount < MaxAttempts Then
				HasNormal = True;
			Else
				HasExceeding = True;
			EndIf;
			
			If HasNormal AND HasExceeding Then
				Break;
			EndIf;
		EndDo;
		
		If HasExceeding Then
			If HasNormal Then
				Filter = New Structure("Status", "Error");
				WithErrors = HandlersTree.Rows.FindRows(Filter, True);
				
				Return WithErrors.Count() > 0;
			Else
				Return True;
			EndIf;
		EndIf;
	EndIf;
	
	Return False;
	
EndFunction

// Gets the number of times the update procedure was started.
//
// Parameters:
//  UpdateHandler - ValueTreeRow - the update handler represented as a row of the handler tree.
//
// Returns:
//  Number - number of startups.
//
Function UpdateProcedureStartCount(UpdateHandler)
	
	UpdateProcedureStartCount = UpdateHandler.ExecutionStatistics["StartsCount"];
	
	If UpdateProcedureStartCount = Undefined Then
		UpdateProcedureStartCount = 0;
	EndIf;
	
	Return UpdateProcedureStartCount;
	
EndFunction

// Finds the update handler in the handler tree.
//
// Parameters:
//  HandlerTree - ValueTreeRowCollection - top level of the tree.
//  ID - UUID - the unique ID of the update handler.
//  HandlerName - String - the name of the update handler.
//
// Returns:
//  * ValueTreeRow - the found handler.
//  * Undefined - if no handler was found.
//
Function FindHandlerInTree(HandlersTree, ID, HandlerName)
	
	If ValueIsFilled(ID) Then
		UpdateHandler = HandlersTree.Find(ID, "ID", True);
		If UpdateHandler = Undefined Then
			UpdateHandler = HandlersTree.Find(HandlerName, "HandlerName", True);
		EndIf;
	Else
		UpdateHandler = HandlersTree.Find(HandlerName, "HandlerName", True);
	EndIf;
	
	Return UpdateHandler;
	
EndFunction

// Finds the update handler in a value table.
//
// Parameters:
//  HandlerTable - ValueTable - the handler table.
//  ID - UUID - the unique ID of the update handler.
//  HandlerName - String - the name of the update handler.
//
// Returns:
//  * ValueTableRow - the found handler.
//  * Undefined - if no handler was found.
//
Function FindHandlerInTable(HandlersTable, ID, HandlerName)
	
	For each Handler In HandlersTable Do
		If Handler.ID = ID AND Handler.HandlerName = HandlerName Then
			Return Handler;
		EndIf;
	EndDo;
	
EndFunction

// Returns the maximum number of update attempts for the specified update handler.
//
// Parameters:
//  UpdateInfo - Structure - update information (see NewUpdateInfo()).
//  UpdateHandler - ValueTreeRow - the update handler represented as a row of the handler tree.
//
// Returns:
//  Number - maximum number of update attempts.
//
Function MaxUpdateAttempts(UpdateInfo, UpdateHandler)
	
	If UpdateHandler.Multithreaded Then
		DataToProcess = UpdateInfo.DataToProcess[UpdateHandler.HandlerName];
		SelectionParameters = DataToProcess.SelectionParameters;
		FullNamesOfObjects = SelectionParameters.FullNamesOfObjects;
		FullRegistersNames = SelectionParameters.FullRegistersNames;
		ObjectsComposition = StrSplit(FullNamesOfObjects, ",");
		RegistersComposition = StrSplit(FullRegistersNames, ",");
		BatchesToUpdate = DataToProcess.BatchesToUpdate;
		BatchesCount = ?(BatchesToUpdate <> Undefined, BatchesToUpdate.Count(), 0);
		Multiplier = ObjectsComposition.Count() * RegistersComposition.Count() + BatchesCount;
	Else
		Multiplier = 1;
	EndIf;
	
	Return 3 * Multiplier;
	
EndFunction

// The amount of added attempts for the AttemptsCount counter.
//
// Parameters:
//  UpdateHandler - ValueTreeRow - the update handler represented as a row of the handler tree.
//  HandlerContext - Structure - see NewHandlerContext(). 
//  Error - Boolean - True if an error has occurred in the update handler.
//
// Returns:
//  The number is 0 if it is a multithread handler, to which data for update was not passed. Otherwise the number is 1.
//
Function AttemptsCountToAdd(UpdateHandler, HandlerContext, Error = False)
	
	If UpdateHandler.Multithreaded Then
		DataToUpdate = HandlerContext.Parameters.DataToUpdate;
		
		// It is checked by the DataToUpdate.FirstRecord and DataToUpdate.LastRecord fields, not by the
		// DataToUpdate.DataSet field as it is cleared in ProcessDataFragmentInThread to save memory.
		// DataToProcess can be Undefined if the handler has raised an exception.
		If DataToUpdate <> Undefined Then
			HasData = DataToUpdate.FirstRecord <> Undefined Or DataToUpdate.LatestRecord <> Undefined;
			If Not HasData AND Not Error Then
				Return 0;
			EndIf;
		EndIf;
	EndIf;
	
	Return 1;
	
EndFunction

#EndRegion
