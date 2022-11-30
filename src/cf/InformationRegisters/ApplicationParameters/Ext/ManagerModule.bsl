///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Internal

// Checks whether the update or configuration of the infobase is required before you start using it.
// 
//
// Parameters:
//  SubordinateDIBNodeSetup - Boolean - (return value), it is set to True if the update is required 
//                                 due to the subordinate DIB node setup.
//
// Returns:
//  Boolean - returns True, if update or setup of the infobase is required.
//
Function UpdateRequired(SubordinateDIBNodeSetup = False) Export
	
	If Common.DataSeparationEnabled() Then
		// Updating in SaaS.
		If Common.SeparatedDataUsageAvailable() Then
			If InfobaseUpdate.InfobaseUpdateRequired() Then
				// Filling separated extension parameters.
				Return True;
			EndIf;
			
		ElsIf InfobaseUpdateInternal.SharedInfobaseDataUpdateRequired() Then
			// Updating shared application parameters.
			Return True;
		EndIf;
	Else
		// Updating in the local mode.
		If InfobaseUpdate.InfobaseUpdateRequired() Then
			Return True;
		EndIf;
	EndIf;
	
	If Common.SubsystemExists("StandardSubsystems.DataExchange") Then
		ModuleDataExchangeServer = Common.CommonModule("DataExchangeServer");
		
		// When starting the created initial image of a subordinate DIB node, no import is required but the 
		// update is required.
		If ModuleDataExchangeServer.SubordinateDIBNodeSetup() Then
			SubordinateDIBNodeSetup = True;
			Return True;
		EndIf;
	EndIf;
	
	Return False;
	
EndFunction

// Calls forced filling of all application parameters.
Procedure UpdateAllApplicationParameters() Export
	
	StandardSubsystemsServer.CheckApplicationVersionDynamicUpdate();
	
	UpdateApplicationParameters();
	
EndProcedure

// Returns the date of a successful check or update of application parameters.
Function AllApplicationParametersUpdateDate() Export
	
	ParameterName = "StandardSubsystems.Core.AllApplicationParametersUpdateDate";
	UpdateDate = StandardSubsystemsServer.ApplicationParameter(ParameterName);
	
	If TypeOf(UpdateDate) <> Type("Date") Then
		UpdateDate = '00010101';
	EndIf;
	
	Return UpdateDate;
	
EndFunction


// See StandardSubsystemsServer.ApplicationParameter. 
Function ApplicationParameter(ParameterName) Export
	
	ValueDetails = ApplicationParameterValueDescription(ParameterName);
	
	If StandardSubsystemsServer.ApplicationVersionUpdatedDynamically() Then
		Return ValueDetails.Value;
	EndIf;
	
	If ValueDetails.Version <> Metadata.Version Then
		Value = Undefined;
		CheckIfCanUpdateSaaS(ParameterName, Value, "Get");
		Return Value;
	EndIf;
	
	Return ValueDetails.Value;
	
EndFunction

// See StandardSubsystemsServer.SetApplicationParameter. 
Procedure SetApplicationParameter(ParameterName, Value) Export
	
	StandardSubsystemsServer.CheckApplicationVersionDynamicUpdate();
	CheckIfCanUpdateSaaS(ParameterName, Value, "Set");
	
	ValueDetails = New Structure;
	ValueDetails.Insert("Version", Metadata.Version);
	ValueDetails.Insert("Value", Value);
	
	SetApplicationParameterStoredData(ParameterName, ValueDetails);
	
EndProcedure

// See StandardSubsystemsServer.UpdateApplicationParameter. 
Procedure UpdateApplicationParameter(ParameterName, Value, HasChanges = False, PreviousValue = Undefined) Export
	
	StandardSubsystemsServer.CheckApplicationVersionDynamicUpdate();
	
	ValueDetails = ApplicationParameterValueDescription(ParameterName, False);
	PreviousValue = ValueDetails.Value;
	
	If Not Common.DataMatch(Value, PreviousValue) Then
		HasChanges = True;
	ElsIf ValueDetails.Version = Metadata.Version Then
		Return;
	EndIf;
	
	SetApplicationParameter(ParameterName, Value);
	
EndProcedure


// See StandardSubsystemsServer.ApplicationParameterChanges. 
Function ApplicationParameterChanges(ParameterName) Export
	
	ChangeStorageParameterName = ParameterName + ":Changes";
	LastChanges = ApplicationParameterStoredData(ChangeStorageParameterName);
	
	Version = Metadata.Version;
	NextVersion = NextVersion(Version);
	
	If Common.DataSeparationEnabled()
	   AND NOT Common.SeparatedDataUsageAvailable() Then
		
		// The area update plan is created only for areas whose versions are not lower then the version of 
		// shared data.
		// For other areas, all update handlers are executed.
		
		// Version of shared (common) data.
		IBVersion = InfobaseUpdateInternal.IBVersion(Metadata.Name, True);
	Else
		IBVersion = InfobaseUpdateInternal.IBVersion(Metadata.Name);
	EndIf;
	
	// In case of initial filling, application parameter changes are not defined.
	If CommonClientServer.CompareVersions(IBVersion, "0.0.0.0") = 0 Then
		Return Undefined;
	EndIf;
	
	UpdateOutsideIBUpdate = CommonClientServer.CompareVersions(IBVersion, Version) = 0;
	
	If Not IsApplicationParameterChanges(LastChanges) Then
		Raise StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Для параметра работы программы ""%1"" не найдены изменения.'; en = 'No changes are found for application parameter ""%1.""'; pl = 'Nie znaleziono żadnych zmian dla parametru pracy programu ""%1"".';de = 'Es wurden keine Änderungen für den Programmbetriebsparameter ""%1"" gefunden.';ro = 'Nu au fost găsite modificările pentru parametrul de lucru al programului ""%1"".';tr = '""%1"" programının çalışması için herhangi bir değişiklik bulunamadı.'; es_ES = 'Para el parámetro del funcionamiento del programa ""%1"" no se han encontrado los cambios.'"), ParameterName)
			+ StandardSubsystemsServer.ApplicationRunParameterErrorClarificationForDeveloper();
	EndIf;
	
	// Not updating to the higher versions except when updating outside the infobase update, which is 
	// when the infobase version equals the configuration version.
	// 
	// In this case, the changes to the next version are selected as well.
	
	Index = LastChanges.Count()-1;
	While Index >= 0 Do
		RevisionVersion = LastChanges[Index].ConfigurationVersion;
		
		If CommonClientServer.CompareVersions(IBVersion, RevisionVersion) >= 0
		   AND NOT (  UpdateOutsideIBUpdate
		         AND CommonClientServer.CompareVersions(NextVersion, RevisionVersion) = 0) Then
			
			LastChanges.Delete(Index);
		EndIf;
		Index = Index - 1;
	EndDo;
	
	Return LastChanges.UnloadColumn("Changes");
	
EndFunction

// See StandardSubsystemsServer.AddApplicationParameterChanges. 
Procedure AddApplicationParameterChanges(ParameterName, Val Changes) Export
	
	StandardSubsystemsServer.CheckApplicationVersionDynamicUpdate();
	
	// Retrieving the infobase or shared data version.
	IBVersion = InfobaseUpdateInternal.IBVersion(Metadata.Name);
	
	// When you migrate to another application, the current configuration version is used.
	If Not Common.DataSeparationEnabled()
	   AND InfobaseUpdateInternal.DataUpdateMode() = "MigrationFromAnotherApplication" Then
		
		IBVersion = Metadata.Version;
	EndIf;
	
	// In case of initial filling, parameter changes are not added.
	If CommonClientServer.CompareVersions(IBVersion, "0.0.0.0") = 0 Then
		Changes = Undefined;
	EndIf;
	
	ChangeStorageParameterName = ParameterName + ":Changes";
	
	Lock = New DataLock;
	LockItem = Lock.Add("InformationRegister.ApplicationParameters");
	LockItem.SetValue("ParameterName", ChangeStorageParameterName);
	
	BeginTransaction();
	Try
		Lock.Lock();
		
		UpdateChangesComposition = False;
		LastChanges = ApplicationParameterStoredData(ChangeStorageParameterName);
		
		If Not IsApplicationParameterChanges(LastChanges) Then
			LastChanges = Undefined;
		EndIf;
		
		If LastChanges = Undefined Then
			UpdateChangesComposition = True;
			LastChanges = New ValueTable;
			LastChanges.Columns.Add("ConfigurationVersion");
			LastChanges.Columns.Add("Changes");
		EndIf;
		
		If ValueIsFilled(Changes) Then
			
			// If there is an update outside the infobase update, add the changes to the next version to keep 
			// these changes when updating the infobase.
			// 
			// 
			Version = Metadata.Version;
			
			UpdateOutsideIBUpdate =
				CommonClientServer.CompareVersions(IBVersion , Version) = 0;
			
			If UpdateOutsideIBUpdate Then
				Version = NextVersion(Version);
			EndIf;
			
			UpdateChangesComposition = True;
			Row = LastChanges.Add();
			Row.Changes          = Changes;
			Row.ConfigurationVersion = Version;
		EndIf;
		
		EarliestIBVersion = InfobaseUpdateInternalCached.EarliestIBVersion();
		
		// Deleting changes for infobase versions earlier than minimum one instead of versions earlier or 
		// equal to the minimum one, to make update outside the infobase update possible.
		// 
		Index = LastChanges.Count()-1;
		While Index >=0 Do
			RevisionVersion = LastChanges[Index].ConfigurationVersion;
			
			If CommonClientServer.CompareVersions(EarliestIBVersion, RevisionVersion) > 0 Then
				LastChanges.Delete(Index);
				UpdateChangesComposition = True;
			EndIf;
			Index = Index - 1;
		EndDo;
		
		If UpdateChangesComposition Then
			CheckIfCanUpdateSaaS(ParameterName, Changes, "AddChanges");
			SetApplicationParameterStoredData(ChangeStorageParameterName,
				LastChanges);
		EndIf;
		
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;
	
EndProcedure


// This method is required for call from the ExecuteInfobaseUpdate procedure.
Procedure ImportUpdateApplicationParameters() Export
	
	If Common.DataSeparationEnabled()
	   AND Common.SeparatedDataUsageAvailable() Then
		
		ProcessExtensionBersionParameters();
		Return;
	EndIf;
	
	If ValueIsFilled(SessionParameters.AttachedExtensions)
	   AND Not UpdateWithoutBackgroundJob() Then
		
		// Starting background job.
		Result = ImportUpdateApplicationParametersInBackground(Undefined, Undefined, False);
		ProcessedResult = ProcessedTimeConsumingOperationResult(Result);
		
		If ValueIsFilled(ProcessedResult.BriefErrorPresentation) Then
			Raise ProcessedResult.DetailedErrorPresentation;
		EndIf;
	Else
		ImportUpdateApplicationParametersIncludingRunMode(False);
		ProcessExtensionBersionParameters(); // It is called above on result processing.
	EndIf;
	
EndProcedure

// This is required to call from the InfobaseUpdateProgressIndicator form.
Function ImportUpdateApplicationParametersInBackground(WaitForCompletion, FormID, ReportProgress) Export
	
	OperationParameters = TimeConsumingOperations.BackgroundExecutionParameters(FormID);
	OperationParameters.BackgroundJobDescription = NStr("ru = 'Фоновое обновление параметров работы программы'; en = 'Update application parameters in background'; pl = 'Aktualizacja w tle parametrów pracy aplikacji';de = 'Hintergrundaktualisierung der Anwendungsparameter';ro = 'Actualizarea de fundal a parametrilor aplicației';tr = 'Uygulama parametrelerin arka plan güncellemesi'; es_ES = 'Actualización de fondo de los parámetros de la aplicación'");
	OperationParameters.WaitForCompletion = WaitForCompletion;
	OperationParameters.NoExtensions = True;
	
	If Common.DebugMode()
	   AND Not ValueIsFilled(SessionParameters.AttachedExtensions) Then
		ReportProgress = False;
	EndIf;
	
	If Not CanExecuteBackgroundJobs() Then
		Raise
			NStr("ru = 'Обновление параметров работы программы не может быть выполнено,
			           |т.к. подключены расширения конфигурации, модифицирующие права в ролях конфигурации.
			           |Для выполнения обновления необходимо отключить такие расширения.'; 
			           |en = 'Cannot update the application parameters
			           |because configuration extensions that modify rights in configuration roles are attached.
			           |Detach these extensions before performing the update.'; 
			           |pl = 'Aktualizacja parametrów pracy programu nie może być wykonana,
			           |ponieważ są połączone rozszerzenia konfiguracji, modyfikujące prawa w rolach konfiguracji.
			           |Aby wykonać aktualizację, musisz odłączyć te rozszerzenia.';
			           |de = 'Die Aktualisierung der Programmbetriebsparameter kann nicht durchgeführt werden,
			           |da die Konfigurationserweiterungen, die die Rechte in den Konfigurationsrollen ändern, verbunden sind.
			           |Um das Update durchzuführen, müssen Sie diese Erweiterungen deaktivieren.';
			           |ro = 'Parametrii de lucru ai programului nu pot fi actualizați,
			           |deoarece sunt conectate extensiile configurației care modifică drepturile în rolurile configurației.
			           |Pentru a executa actualizarea trebuie să dezactivați asemenea extensii.';
			           |tr = 'Yapılandırma rolündeki hakları değiştiren yapılandırma uzantıları bağlı olduğundan, 
			           |programın çalışma ayarlarını güncelleyemezsiniz.
			           | Güncellemeyi gerçekleştirmek için bu uzantıları devre dışı bırakmanız gerekir.'; 
			           |es_ES = 'La actualización de los parámetros del funcionamiento del programa,
			           |porque están conectadas las extensiones de la configuración que modifican los derechos en los roles de configuración.
			           |Para actualizar es necesario desactivar estas extensiones.'");
	EndIf;
	
	Return TimeConsumingOperations.ExecuteInBackground(
		"InformationRegisters.ApplicationParameters.UpdateDownloadTimeConsumingOperationHandler",
		ReportProgress,
		OperationParameters);
	
EndFunction

// This is required to call from the InfobaseUpdateProgressIndicator form.
Function ProcessedTimeConsumingOperationResult(Result) Export
	
	BriefErrorPresentation   = Undefined;
	DetailedErrorPresentation = Undefined;
	
	If Result = Undefined Or Result.Status = "Canceled" Then
		
		BriefErrorPresentation =
			NStr("ru = 'Не удалось обновить параметры работы программы по причине:
			           |Фоновое задание, выполняющее обновление отменено.'; 
			           |en = 'Cannot update application parameters. Reason:
			           |The update background job is canceled.'; 
			           |pl = 'Nie udało się zaktualizować parametrów pracy programu z powodu:
			           |Zadanie w tle, które wykonuje aktualizację, zostało anulowane.';
			           |de = 'Die Parameter des Programms konnten nicht aktualisiert werden, da:
			           |Der Hintergrundjob, der die Aktualisierung durchführte, wurde abgebrochen.';
			           |ro = 'Eșec la actualizarea parametrilor de lucru în program din motivul:
			           |Sarcina de fundal care execută actualizarea este revocată.';
			           |tr = 'Bir nedenle program ayarlarını güncelleştirilemedi: 
			           |Güncelleştirme gerçekleştiren arka plan görevi iptal edildi.'; 
			           |es_ES = 'No se ha podido actualizar los parámetros del funcionamiento a causa de:
			           |La tarea del fondo que realizaba la actualización ha sido cancelada.'");
		
	ElsIf Result.Status = "Completed" Then
		ExecutionResult = GetFromTempStorage(Result.ResultAddress);
		
		If TypeOf(ExecutionResult) = Type("Structure") Then
			BriefErrorPresentation   = ExecutionResult.BriefErrorPresentation;
			DetailedErrorPresentation = ExecutionResult.DetailedErrorPresentation;
		Else
			BriefErrorPresentation =
				NStr("ru = 'Не удалось обновить параметры работы программы по причине:
				           |Фоновое задание, выполняющее обновление не вернуло результат.'; 
				           |en = 'Cannot update application parameters. Reason:
				           |The update background job did not return the result.'; 
				           |pl = 'Nie udało się zaktualizować parametrów pracy programu z powodu:
				           |Zadanie w tle, które wykonuje aktualizację, nie zwróciło wyniku.';
				           |de = 'Die Parameter des Programms konnten nicht aktualisiert werden, da:
				           |Der Hintergrundjob, der die Aktualisierung durchführte, hat das Ergebnis nicht zurückgegeben.';
				           |ro = 'Eșec la actualizarea parametrilor de lucru în program din motivul:
				           |Sarcina de fundal care execută actualizarea nu a returnat rezultatul.';
				           |tr = 'Bir nedenle program ayarlarını güncelleştirilemedi: 
				           |Güncelleştirme gerçekleştiren arka plan görevi sonucu iade etmedi.'; 
				           |es_ES = 'No se ha podido actualizar los parámetros del funcionamiento a causa de:
				           |La tarea del fondo que realizaba la actualización no ha devuelto el resultado.'");
		EndIf;
	ElsIf Result.Status <> "StartupNotRequired" Then
		// Background job error.
		BriefErrorPresentation   = Result.BriefErrorPresentation;
		DetailedErrorPresentation = Result.DetailedErrorPresentation;
	EndIf;
	
	If Not ValueIsFilled(DetailedErrorPresentation)
	   AND    ValueIsFilled(BriefErrorPresentation) Then
		
		DetailedErrorPresentation = BriefErrorPresentation;
	EndIf;
	
	If Not ValueIsFilled(BriefErrorPresentation)
	   AND    ValueIsFilled(DetailedErrorPresentation) Then
		
		BriefErrorPresentation = DetailedErrorPresentation;
	EndIf;
	
	ProcessedResult = New Structure;
	ProcessedResult.Insert("BriefErrorPresentation",   BriefErrorPresentation);
	ProcessedResult.Insert("DetailedErrorPresentation", DetailedErrorPresentation);
	
	If Not ValueIsFilled(BriefErrorPresentation) Then
		ProcessExtensionBersionParameters();
	EndIf;
	
	Return ProcessedResult;
	
EndFunction

#EndRegion

#Region Private

// To call from the background job without attached configuration extensions.
Procedure UpdateDownloadTimeConsumingOperationHandler(ReportProgress, StorageAddress) Export
	
	ExecutionResult = New Structure;
	ExecutionResult.Insert("BriefErrorPresentation",   Undefined);
	ExecutionResult.Insert("DetailedErrorPresentation", Undefined);
	
	Try
		ImportUpdateApplicationParametersIncludingRunMode(ReportProgress);
	Except
		ErrorInformation = ErrorInfo();
		ExecutionResult.BriefErrorPresentation   = BriefErrorDescription(ErrorInformation);
		ExecutionResult.DetailedErrorPresentation = DetailErrorDescription(ErrorInformation);
		// Preparing to open the form for data resynchronization before startup with two options, 
		// "Synchronize and continue" and "Continue".
		If Common.SubsystemExists("StandardSubsystems.DataExchange")
		   AND Common.IsSubordinateDIBNode() Then
			ModuleDataExchangeServer = Common.CommonModule("DataExchangeServer");
			ModuleDataExchangeServer.EnableDataExchangeMessageImportRecurrenceBeforeStart();
		EndIf;
	EndTry;
	
	PutToTempStorage(ExecutionResult, StorageAddress);
	
EndProcedure

Procedure ImportUpdateApplicationParametersIncludingRunMode(ReportProgress)

	StandardSubsystemsServer.CheckApplicationVersionDynamicUpdate();
	
	If ValueIsFilled(SessionParameters.AttachedExtensions)
	   AND Not UpdateWithoutBackgroundJob() Then
		Raise
			NStr("ru = 'Не удалось обновить параметры работы программы по причине:
			           |Найдены подключенные расширения конфигурации.'; 
			           |en = 'Cannot update application parameters. Reason:
			           |Attached configuration extensions are found.'; 
			           |pl = 'Nie udało się zaktualizować parametrów pracy programu z powodu:
			           |Znaleziono połączone rozszerzenia konfiguracji.';
			           |de = 'Die Parameter des Programms konnten nicht aktualisiert werden, da:
			           |Verbundene Konfigurationserweiterungen gefunden.';
			           |ro = 'Eșec la actualizarea parametrilor de lucru în program din motivul:
			           |Au fost găsite extensii conectate ale configurației.';
			           |tr = 'Bir nedenle program ayarlarını güncelleştirilemedi: 
			           |Bağlı yapılandırma uzantıları bulundu.'; 
			           |es_ES = 'No se ha podido actualizar los parámetros del funcionamiento a causa de:
			           |Se han encontrado las extensiones conectadas de la configuración.'");
	EndIf;
	
	If Common.DataSeparationEnabled()
	   AND Common.SeparatedDataUsageAvailable() Then
		Raise
			NStr("ru = 'Не удалось обновить параметры работы программы по причине:
			           |Обновление невозможно выполнить в области данных.'; 
			           |en = 'Cannot update application parameters. Reason:
			           |Cannot perform the update in the data area.'; 
			           |pl = 'Nie udało się zaktualizować parametrów pracy programu z powodu:
			           |Aktualizacji nie można wykonać w obszarze danych.';
			           |de = 'Die Parameter des Programms konnten nicht aktualisiert werden, da:
			           |Die Aktualisierung im Datenbereich kann nicht durchgeführt werden.';
			           |ro = 'Eșec la actualizarea parametrilor de lucru în program din motivul:
			           |Nu puteți executa actualizarea în domeniul de date.';
			           |tr = 'Bir nedenle program ayarlarını güncelleştirilemedi: 
			           | Veri alanında güncelleme yapılamıyor.'; 
			           |es_ES = 'No se ha podido actualizar los parámetros del funcionamiento a causa de:
			           |Es imposible actualizar en el área de datos. '");
	EndIf;
	
	SubordinateDIBNodeSetup = False;
	If Not UpdateRequired(SubordinateDIBNodeSetup) Then
		Return;
	EndIf;
	
	ModulePerformanceMonitor = Undefined;
	If Common.SubsystemExists("StandardSubsystems.PerformanceMonitor") Then
		ModulePerformanceMonitor = Common.CommonModule("PerformanceMonitor");
		StartTime = ModulePerformanceMonitor.StartTimeMeasurement();
	EndIf;
	
	SetPrivilegedMode(True);
	If Common.IsSubordinateDIBNode() Then
		// There are a DIB data exchange and an update in the subordinate node.
		
		If Common.SubsystemExists("StandardSubsystems.DataExchange") Then
			ModuleDataExchangeServer = Common.CommonModule("DataExchangeServer");
		EndIf;
		
		If Not SubordinateDIBNodeSetup Then
			
			StandardProcessing = True;
			CommonOverridable.BeforeImportPriorityDataInSubordinateDIBNode(
				StandardProcessing);
			
			If StandardProcessing = True
			   AND Common.SubsystemExists("StandardSubsystems.DataExchange") Then
				
				// Importing predefined items and metadata object IDs from the master node.
				ModuleDataExchangeServer.ImportPriorityDataToSubordinateDIBNode();
			EndIf;
			
			If ReportProgress Then
				TimeConsumingOperations.ReportProgress(5);
			EndIf;
		EndIf;
		
		// Checking metadata object ID import from the master node.
		ListOfCriticalChanges = "";
		Try
			Catalogs.MetadataObjectIDs.RunDataUpdate(False, False, True, , ListOfCriticalChanges);
		Except
			// Preparing to open the form for data resynchronization before startup with one option, 
			// "Synchronize and continue".
			If Not SubordinateDIBNodeSetup
			   AND Common.SubsystemExists("StandardSubsystems.DataExchange") Then
				ModuleDataExchangeServer.EnableDataExchangeMessageImportRecurrenceBeforeStart();
			EndIf;
			Raise;
		EndTry;
		
		If ValueIsFilled(ListOfCriticalChanges) Then
			
			EventName = NStr("ru = 'Идентификаторы объектов метаданных.Требуется загрузить критичные изменения'; en = 'Metadata object IDs.Import of critical changes required'; pl = 'Identyfikator obiektu IDs.Importuj krytyczne zmiany';de = 'Metadatenobjekt-IDs. Importieren Sie wichtige Änderungen';ro = 'Identificatorii obiectelor de metadate.Necesitatea importului modificărilor critice';tr = 'Meta veri nesne kimlikleri. Kritik değişiklikleri içe aktar'; es_ES = 'Identificadores de objetos de metadatos.Importar los cambios críticos'",
				Common.DefaultLanguageCode());
			
			WriteLogEvent(EventName, EventLogLevel.Error, , , ListOfCriticalChanges);
			
			// Preparing to open the form for data resynchronization before startup with one option, 
			// "Synchronize and continue".
			If Not SubordinateDIBNodeSetup
			   AND Common.SubsystemExists("StandardSubsystems.DataExchange") Then
				ModuleDataExchangeServer.EnableDataExchangeMessageImportRecurrenceBeforeStart();
			EndIf;
			
			ErrorText =
				NStr("ru = 'Информационная база не может быть обновлена из-за проблемы в главном узле:
				           |- главный узел был некорректно обновлен (возможно не был увеличен номер версии конфигурации,
				           |  из-за чего не заполнился справочник Идентификаторы объектов метаданных);
				           |- либо были отменены к выгрузке приоритетные данные (элементы
				           |  справочника Идентификаторы объектов метаданных).
				           |
				           |Необходимо заново выполнить обновление главного узла, зарегистрировать к выгрузке
				           |приоритетные данные и повторить синхронизацию данных:
				           |- в главном узле запустите программу с параметром /C ЗапуститьОбновлениеИнформационнойБазы;
				           |%1'; 
				           |en = 'The infobase cannot be updated. Possible reasons:
				           |- The master node was updated incorrectly (the configuration version number might not be incremented),
				           |  therefore, the ""Metadata object IDs"" catalog was not populated).
				           |- Export of priority data (items of ""Metadata object IDs"" catalog)
				           |was canceled in the master node.
				           |
				           |Update the master node again, register priority data for export,
				           |and repeat data synchronization:
				           |- In the master node, run the application with /C StartInfobaseUpdate command-line option.
				           |%1'; 
				           |pl = 'Nie można zaktualizować bazy informacyjnej ze względu na problemy w głównym węźle:
				           |- główny węzeł został niepoprawnie zaktualizowany (prawdopodobnie nie został zwiększony numer wersji konfiguracji,
				           | przez co nie został wypełniony katalog Identyfikatory obiektów metadanych);
				           |- albo dane priorytetowe do wyeksportowania zostały anulowane (elementy
				           | katalogu Identyfikatory obiektów metadanych).
				           |
				           |Należy ponownie wykonać aktualizację głównego węzła, zarejestrować do wyeksportowania
				           |dane priorytetowe i powtórzyć synchronizację danych:
				           |- w głównym węźle należy uruchomić program z parametrem /C ЗапуститьОбновлениеИнформационнойБазы;
				           |%1';
				           |de = 'Die Informationsbasis kann aufgrund eines Problems im Hauptknoten nicht aktualisiert werden:
				           |- Der Hauptknoten wurde falsch aktualisiert (die Nummer der Konfigurationsversion wurde möglicherweise nicht erhöht,
				           |  weshalb das Verzeichnis Metadaten-Objekt Identifikatoren nicht ausgefüllt wurde);
				           |- oder Prioritätsdaten (Elemente des
				           |  Verzeichnisses Metadaten-Objekt Identifikatoren) wurden zum Hochladen gelöscht.
				           |
				           |Es ist notwendig, den Hauptknoten zu aktualisieren, sich für das Hochladen
				           |der Prioritätsdaten zu registrieren und die Synchronisation der Daten zu wiederholen:
				           |- im Hauptknoten starten Sie das Programm mit dem Parameter /C ЗапуститьОбновлениеИнформационнойБазы;
				           |%1';
				           |ro = 'Baza de informații nu poate fi actualizată din cauza problemei în nodul principal:
				           |- nodul principal a fost actualizat incorect (posibil, nu a fost majorat numărul versiunii configurației,
				           |  din care motiv nu a fost completat clasificatorul Identificatorii obiectelor de metadate);
				           |- sau a fost anulată descărcarea datelor prioritare (elementele
				           |  clasificatorului Identificatorii obiectelor de metadate).
				           |
				           |Trebuie să actualizați din nou nodul principal, să înregistrați datele prioritare
				           |pentru export și să repetați sincronizarea datelor:
				           |- în nodul principal lansați programul cu parametrul /C StartInfobaseUpdate;
				           |%1';
				           |tr = 'Veri tabanı, ana ünitedeki sorun nedeniyle güncellenemez: 
				           |- ana ünite yanlış güncelleştirildi (yapılandırma sürüm numarasını artırmamış olabilir, 
				           |çünkü meta veri nesne tanımlayıcıları dizini doldurulmamış olabilir); - 
				           |veya öncelikli verilerin (meta veri nesne tanımlayıcıları 
				           |öğeleri) boşaltılması iptal edildi. 
				           |
				           |Ana ünite yeniden güncelleştirilmeli, öncelikli veriler dışa aktarılmak üzere kaydedilmeli ve veri senkronizasyonu tekrarlanmalıdır: 
				           |- ana ünitede, /C StartInfobaseUpdate parametresiyle uygulamayı çalıştırın;
				           |
				           |%1'; 
				           |es_ES = 'La base de información no puede ser actualizada a causa del problema en el nodo principal:
				           |- el nodo principal ha sido actualizado incorrectamente (es posible que no haya sido aumentado el número de la versión de la configuración,
				           |así que no se ha rellenado el catálogo Identificadores de los objetos de metadatos);
				           |- o han sido cancelados los datos prioritarios para subir (elementos
				           | del catálogo Identificadores de los objetos de metadatos).
				           |
				           |Es necesario volver a actualizar el nodo principal, registrar para la subida
				           | los datos prioritarios y volver a sincronizar los datos:
				           |- en el nodo principal lance el programa con el parámetro /C ЗапуститьОбновлениеИнформационнойБазы;
				           |%1'");
			
			If SubordinateDIBNodeSetup Then
				// Setting up a subordinate DIB node during the first start.
				ErrorText = StringFunctionsClientServer.SubstituteParametersToString(ErrorText,
					NStr("ru = '- затем повторите создание подчиненного узла.'; en = '- Then retry creating a subordinate node.'; pl = '- następnie powtórz tworzenie węzła podrzędnego.';de = '- wiederholen Sie dann das Erstellen des Slave-Knotens.';ro = '- apoi repetați crearea nodului subordonat.';tr = '- sonra alt üniteyi tekrar oluşturun.'; es_ES = '- después vuelva a crear el nodo principal.'"));
			Else
				// Updating a subordinate DIB node.
				ErrorText = StringFunctionsClientServer.SubstituteParametersToString(ErrorText,
					NStr("ru = '- затем повторите синхронизацию данных с этой информационной базой
					           | (сначала в главном узле, затем в этой информационной базе после перезапуска).'; 
					           |en = '- Then repeat data synchronization with this infobase: 
					           | first in the master node, then in the infobase (restart the infobase before the synchronization).'; 
					           |pl = '- następnie powtórz synchronizację danych z tą bazą informacji
					           | (najpierw w głównym węźle, a następnie w tej bazie informacyjnej po ponownym uruchomieniu).';
					           |de = '- wiederholen Sie dann die Synchronisation mit dieser Datenbank
					           | (zuerst im Hauptknoten, dann in dieser Datenbank nach dem Neustart).';
					           |ro = '- apoi repetați sincronizarea datelor cu această bază de informații
					           | (mai întâi în nodul principal, apoi în baza de informații după relansare).';
					           |tr = '- ardından, verileri bu veritabanıyla yeniden senkronize edin
					           | (ilk önce ana ünitede, daha sonra yeniden başlatıldıktan sonra bu veritabanında).'; 
					           |es_ES = '- después vuelva a sincronizar los datos con esta base de información
					           | (al principio en el nodo principal, después en esta base de información al reiniciar).'"));
			EndIf;
			
			Raise ErrorText;
		EndIf;
		If ReportProgress Then
			TimeConsumingOperations.ReportProgress(10);
		EndIf;
	EndIf;
	
	// No DIB data exchange or master infobase node update or initial subordinate node update or update 
	// after importing the Metadata object IDs catalog from the master node.
	// 
	// 
	UpdateApplicationParameters(ReportProgress);
	
	If ModulePerformanceMonitor <> Undefined Then
		ModulePerformanceMonitor.EndTimeMeasurement("MetadataCacheUpdateTime", StartTime);
	EndIf;
	
EndProcedure

Procedure ProcessExtensionBersionParameters()
	
	If Not Common.SeparatedDataUsageAvailable() Then
		Return;
	EndIf;
	
	SetPrivilegedMode(True);
	ClientLaunchParameter = SessionParameters.ClientParametersAtServer.Get("LaunchParameter");
	SetPrivilegedMode(False);
	If StrFind(Lower(ClientLaunchParameter), Lower("StartInfobaseUpdate")) > 0 Then
		InformationRegisters.ExtensionVersionParameters.ClearAllExtensionParameters();
	EndIf;
	
	InformationRegisters.ExtensionVersionParameters.FillAllExtensionParameters();
	
EndProcedure

// This method is required by ApplicationParameterChanges function.
Function NextVersion(Version)
	
	Array = StrSplit(Version, ".");
	
	Return CommonClientServer.ConfigurationVersionWithoutBuildNumber(
		Version) + "." + Format(Number(Array[3]) + 1, "NG=");
	
EndFunction

// This method is required by ImportUpdateApplicationParameters and UpdateAllApplicationParameters procedures.
Procedure UpdateApplicationParameters(ReportProgress = False)
	
	If ReportProgress Then
		TimeConsumingOperations.ReportProgress(30);
	EndIf;
	
	If Not StandardSubsystemsCached.DisableMetadataObjectsIDs() Then
		Catalogs.MetadataObjectIDs.RunDataUpdate(False, False, False);
	EndIf;
	If ReportProgress Then
		TimeConsumingOperations.ReportProgress(60);
	EndIf;
	
	If Common.SubsystemExists("StandardSubsystems.AccessManagement") Then
		ModuleAccessManagementInternal = Common.CommonModule("AccessManagementInternal");
		ModuleAccessManagementInternal.UpdateAccessRestrictionParameters();
	EndIf;
	
	If Common.SubsystemExists("StandardSubsystems.AccountingAudit") Then
		ModuleAccountingAuditInternal = Common.CommonModule("AccountingAuditInternal");
		ModuleAccountingAuditInternal.UpdateAccountingChecksParameters();
	EndIf;
	
	If Common.SubsystemExists("StandardSubsystems.DataExchange") Then
		ModuleDataExchangeServer = Common.CommonModule("DataExchangeServer");
		ModuleDataExchangeServer.UpdateDataExchangeRules();
	EndIf;
	
	If ReportProgress Then
		TimeConsumingOperations.ReportProgress(100);
	EndIf;
	
	ParameterName = "StandardSubsystems.Core.AllApplicationParametersUpdateDate";
	StandardSubsystemsServer.SetApplicationParameter(ParameterName, CurrentSessionDate());
	
	If Common.SeparatedDataUsageAvailable()
	   AND Common.SubsystemExists("StandardSubsystems.AccessManagement") Then
		
		ModuleAccessManagementInternal = Common.CommonModule("AccessManagementInternal");
		ModuleAccessManagementInternal.SetAccessUpdate(True);
	EndIf;
	
EndProcedure

// This method is required by ApplicationParameter function and UpdateApplicationParameter procedure.
Function ApplicationParameterValueDescription(ParameterName, CheckIfCanUpdateSaaS = True)
	
	ValueDetails = ApplicationParameterStoredData(ParameterName);
	
	If TypeOf(ValueDetails) <> Type("Structure")
	 Or ValueDetails.Count() <> 2
	 Or Not ValueDetails.Property("Version")
	 Or Not ValueDetails.Property("Value") Then
		
		If StandardSubsystemsServer.ApplicationVersionUpdatedDynamically() Then
			StandardSubsystemsServer.RequireRestartDueToApplicationVersionDynamicUpdate();
		EndIf;
		ValueDetails = New Structure("Version, Value");
		If CheckIfCanUpdateSaaS Then
			CheckIfCanUpdateSaaS(ParameterName, Null, "Get");
		EndIf;
	EndIf;
	
	Return ValueDetails;
	
EndFunction

// This is required for the ApplicationParameterValueDetails, ApplicationParameterChanges functions 
// and the AddApplicationParameterChanges procedures.
//
Function ApplicationParameterStoredData(ParameterName)
	
	Query = New Query;
	Query.SetParameter("ParameterName", ParameterName);
	Query.Text =
	"SELECT
	|	ApplicationParameters.ParameterStorage
	|FROM
	|	InformationRegister.ApplicationParameters AS ApplicationParameters
	|WHERE
	|	ApplicationParameters.ParameterName = &ParameterName";
	
	SetSafeModeDisabled(True);
	SetPrivilegedMode(True);
	Selection = Query.Execute().Select();
	If Selection.Next() Then
		Return Selection.ParameterStorage.Get();
	EndIf;
	SetPrivilegedMode(False);
	SetSafeModeDisabled(False);
	
	Return Undefined;
	
EndFunction

// This method is required by SetApplicationParameter and AddApplicationParameterChanges procedures.
Procedure SetApplicationParameterStoredData(ParameterName, StoredData)
	
	RecordSet = CreateRecordSet();
	RecordSet.Filter.ParameterName.Set(ParameterName);
	
	NewRecord = RecordSet.Add();
	NewRecord.ParameterName       = ParameterName;
	NewRecord.ParameterStorage = New ValueStorage(StoredData);
	
	InfobaseUpdate.WriteRecordSet(RecordSet, , False, False);
	
EndProcedure

Procedure CheckIfCanUpdateSaaS(ParameterName, NewValue, Operation)
	
	If Not Common.DataSeparationEnabled()
	 Or Not Common.SeparatedDataUsageAvailable() Then
		Return;
	EndIf;
	
	// Writing the error context to the event log for the service administrator.
	ValueDetails = ApplicationParameterStoredData(ParameterName);
	
	ChangeStorageParameterName = ParameterName + ":Changes";
	LastChanges = ApplicationParameterStoredData(ChangeStorageParameterName);
	
	EventName = NStr("ru = 'Параметры работы программы.Не выполнено обновление в неразделенном режиме'; en = 'Application parameters.Not updated in shared mode'; pl = 'Parametry pracy programu. Brak aktualizacji w trybie nierozdzielonym';de = 'Parameter des Programmablaufs. Die Aktualisierung wird nicht im ungeteilten Modus durchgeführt';ro = 'Parametrii de lucru ai programului.Nu a fost executată actualizarea în regim neseparat';tr = 'Uygulama parametreleri.  Bölünmemiş modda güncelleme yapılmadı'; es_ES = 'Parámetros del uso del programa.No se ha realizado la actualización en el modo no distribuido'",
		Common.DefaultLanguageCode());
	
	Comment =
		NStr("ru = '1. Перешлите сообщение в техническую поддержку.
		           |2. Попытайтесь устранить проблему самостоятельно. Для этого
		           |запустите программу с параметром командной строки 1С:Предприятия 8
		           |""/С ЗапуститьОбновлениеИнформационнойБазы"" от имени пользователя
		           |с правами администратора сервиса, то есть в неразделенном режиме.
		           |
		           |Сведения об проблемном параметре:'; 
		           |en = '1. Send the message to the technical support.
		           |2. Attempt to resolve the issue manually: run the application
		           |with /C StartInfobaseUpdate command-line option
		           |on behalf of a user with service administrator rights
		           |(in shared mode).
		           |
		           |Invalid application parameter:'; 
		           |pl = '1. Przekaż wiadomość do działu pomocy technicznej.
		           |2. Spróbuj rozwiązać problem samodzielnie. Aby to zrobić
		           |, uruchom program za pomocą parametru wiersza poleceń 1C: Enterprise 8
		           |""/С StartInfobaseUpdate"" w imieniu użytkownika
		           |z uprawnieniami administratora usługi, czyli w trybie bez partycji. 
		           |
		           |Informacja o parametrze problemu:';
		           |de = '1. Leiten Sie die Nachricht an den technischen Support weiter.
		           |2. Versuchen Sie, das Problem selbst zu beheben. Führen Sie dazu
		           |das Programm mit dem Befehlszeilenparameter 1C: Enterprise 8
		           |""/ C StartInfobaseUpdate"" im Namen des Benutzers
		           |mit Serviceadministrator-Rechten aus, d.h. im nicht partitionierten Modus.
		           |
		           |Informationen über den Problemparameter:';
		           |ro = '1. Trimiteți mesajul în serviciul tehnic.
		           |2. Încercați să înlăturați problema de sine stătător. Pentru aceasta
		           |lansați programul cu parametrul liniei de comandă a 1С:Enterprise 8
		           |""/С StartInfobaseUpdate"" din numele utilizatorului
		           |cu drepturile administratorului serviciului, adică în regim neseparat.
		           |
		           |Informații despre parametrul cu problemă:';
		           |tr = '1. Teknik desteğe bir mesaj gönderin. 
		           |2. Sorunu kendiniz düzeltmeye çalışın. Bunu yapmak için, 1C:İşletme 8
		           |""/C StartInfobaseUpdate"" komut satırı seçeneği ile programı yönetici ayrıcalıkları olan kullanıcı adına"", yani karşılıksız modda çalıştırın. 
		           |
		           |
		           |Sorunlu parametre bilgileri:
		           |'; 
		           |es_ES = '1. Reenvíe el mensaje al soporte técnico.
		           |2. Prueba de solucionar el problema por su cuenta. Para hacerlo
		           | lance el programa con el parámetro de la línea de comando de 1C:Enterprise 8
		           |/С StartInfobaseUpdate del nombre de usuario
		           |con los derechos de administrador del servicio, es decir, en el modo no distribuido.
		           |
		           |Información del parámetro de dificultad:'");

	Comment = Comment + Chars.LF +
	"MetadataVersion = " + Metadata.Version + "
	|ParameterName = " + ParameterName + "
	|Operation = " + Operation + "
	|ValueDetails =
	|" + XMLString(New ValueStorage(ValueDetails)) + "
	|NewValue =
	|" + XMLString(New ValueStorage(NewValue)) + "
	|LastChanges =
	|" + XMLString(New ValueStorage(LastChanges));
	
	WriteLogEvent(EventName, EventLogLevel.Error,,, Comment);
	
	// Exception for a user.
	ErrorText =
		NStr("ru = 'Параметры работы программы не обновлены в неразделенном режиме.
		           |Обратитесь к администратору сервиса. Подробности в журнале регистрации.'; 
		           |en = 'The application parameters are not updated in shared mode.
		           |Please contact the service administrator. See the event log for details.'; 
		           |pl = 'Parametry działania programu nie są aktualizowane w trybie bez partycji.
		           |Skontaktuj się z administratorem usługi. Szczegóły w dzienniku rejestracji.';
		           |de = 'Die Programmbetriebsparameter werden im ungeteilten Modus nicht aktualisiert.
		           |Wenden Sie sich an den Service-Administrator. Details im Ereignisprotokoll.';
		           |ro = 'Parametrii de lucru ai programului nu sunt actualizați în regim neseparat.
		           |Adresați-vă administratorului serviciului. Detalii vezi în registrul logare.';
		           |tr = 'Uygulamanın parametreleri bölünmemiş modda güncellenmedi. 
		           |Servis yöneticisine başvurun.  Detaylar kayıt günlüğündedir.'; 
		           |es_ES = 'Los parámetros del funcionamiento del programa no han sido actualizados en el modo no distribuido.
		           |Diríjase al administrador del servicio. Véase los detalles en el registro eventos.'");
	
	Raise ErrorText;
	
EndProcedure

Function IsApplicationParameterChanges(LastChanges)
	
	If TypeOf(LastChanges)              <> Type("ValueTable")
	 OR LastChanges.Columns.Count() <> 2
	 OR LastChanges.Columns[0].Name       <> "ConfigurationVersion"
	 OR LastChanges.Columns[1].Name       <> "Changes" Then
		
		Return False;
	EndIf;
	
	Return True;
	
EndFunction

Function UpdateWithoutBackgroundJob()
	
	If Not CanExecuteBackgroundJobs()
	   AND Not HasRolesModifiedByExtensions() Then
		
		Return True;
	EndIf;
	
	Return False;
	
EndFunction

Function HasRolesModifiedByExtensions()
	
	For Each Role In Metadata.Roles Do
		If Role.ChangedByConfigurationExtensions() Then
			Return True;
		EndIf;
	EndDo;
	
	Return False;
	
EndFunction

Function CanExecuteBackgroundJobs()
	
	If CurrentRunMode() = Undefined
	   AND Common.FileInfobase() Then
		
		Session = GetCurrentInfoBaseSession();
		If Session.ApplicationName = "COMConnection" Then
			Return False;
		EndIf;
	EndIf;
	
	Return True;
	
EndFunction

#EndRegion

#EndIf
