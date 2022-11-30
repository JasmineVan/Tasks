///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Internal

// See StandardSubsystemsServer.ExtensionParameter. 
Function ExtensionParameter(ParameterName, IgnoreExtensionsVersion = False) Export
	
	ExtensionsVersion = ?(IgnoreExtensionsVersion, Catalogs.ExtensionsVersions.EmptyRef(), SessionParameters.ExtensionsVersion);
	
	Query = New Query;
	Query.SetParameter("ExtensionsVersion", ExtensionsVersion);
	Query.SetParameter("ParameterName", ParameterName);
	Query.Text =
	"SELECT
	|	ExtensionVersionParameters.ParameterStorage
	|FROM
	|	InformationRegister.ExtensionVersionParameters AS ExtensionVersionParameters
	|WHERE
	|	ExtensionVersionParameters.ExtensionsVersion = &ExtensionsVersion
	|	AND ExtensionVersionParameters.ParameterName = &ParameterName";
	
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

// See StandardSubsystemsServer.SetExtensionParameter. 
Procedure SetExtensionParameter(ParameterName, Value, IgnoreExtensionsVersion = False) Export
	
	ExtensionsVersion = ?(IgnoreExtensionsVersion, Catalogs.ExtensionsVersions.EmptyRef(), SessionParameters.ExtensionsVersion);
	
	RecordSet = CreateRecordSet();
	RecordSet.Filter.ExtensionsVersion.Set(ExtensionsVersion);
	RecordSet.Filter.ParameterName.Set(ParameterName);
	
	NewRecord = RecordSet.Add();
	NewRecord.ExtensionsVersion   = ExtensionsVersion;
	NewRecord.ParameterName       = ParameterName;
	NewRecord.ParameterStorage = New ValueStorage(Value);
	
	RecordSet.DataExchange.Load = True;
	RecordSet.Write();
	
EndProcedure

// Forces all run parameters to be filled for the current extension version.
Procedure FillAllExtensionParameters() Export
	
	If Not Common.SeparatedDataUsageAvailable() Then
		Return;
	EndIf;
	
	// Fill extension metadata object IDs.
	If ValueIsFilled(SessionParameters.AttachedExtensions) Then
		Update = Catalogs.ExtensionObjectIDs.CurrentVersionExtensionObjectIDsFilled();
		StandardSubsystemsCached.MetadataObjectIDsUsageCheck(True, True);
	Else
		Update = True;
	EndIf;
	
	If Update Then
		Catalogs.ExtensionObjectIDs.UpdateCatalogData();
	EndIf;
	
	SSLSubsystemsIntegration.OnFillAllExtensionsParameters();
	
	ParameterName = "StandardSubsystems.Core.LastFillingDateOfAllExtensionsParameters";
	StandardSubsystemsServer.SetExtensionParameter(ParameterName, CurrentSessionDate(), True);
	
	If Common.SubsystemExists("StandardSubsystems.AccessManagement") Then
		ModuleAccessManagementInternal = Common.CommonModule("AccessManagementInternal");
		ModuleAccessManagementInternal.SetAccessUpdate(True);
	EndIf;
	
EndProcedure

// Returns the date of the last filling in the extension version operation parameters.
Function LastFillingDateOfAllExtensionsParameters() Export
	
	ParameterName = "StandardSubsystems.Core.LastFillingDateOfAllExtensionsParameters";
	UpdateDate = StandardSubsystemsServer.ExtensionParameter(ParameterName, True);
	
	If TypeOf(UpdateDate) <> Type("Date") Then
		UpdateDate = '00010101';
	EndIf;
	
	Return UpdateDate;
	
EndFunction

// Forces all run parameters to be cleared for the current extension version.
// Only registers are cleared, catalogs are not changed. Called to refill extension parameter values, 
// for example, when you use the StartInfobaseUpdate launch parameter.
// 
// 
// The ExtensionVersionParameters common register is cleared automatically. If you use your own 
// information registers that store extension metadata object cache versions, attach the 
// OnClearAllExtemsionRunParameters event of the SubsystemIntegrationSSL common module.
// 
//
Procedure ClearAllExtensionParameters() Export
	
	If Not Common.SeparatedDataUsageAvailable() Then
		Return;
	EndIf;
	
	SetPrivilegedMode(True);
	
	BeginTransaction();
	Try
		RecordSet = InformationRegisters.ExtensionVersionObjectIDs.CreateRecordSet();
		RecordSet.Filter.ExtensionsVersion.Set(SessionParameters.ExtensionsVersion);
		RecordSet.DataExchange.Load = True;
		RecordSet.Write();
		
		RecordSet = CreateRecordSet();
		RecordSet.Filter.ExtensionsVersion.Set(SessionParameters.ExtensionsVersion);
		RecordSet.DataExchange.Load = True;
		RecordSet.Write();
		
		SSLSubsystemsIntegration.OnClearAllExtemsionParameters();
		
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;
	
	RefreshReusableValues();
	
EndProcedure

// This is required for the Extensions common form.
Procedure FillAllExtensionParametersBackgroundJob(Parameters) Export
	
	ErrorText = "";
	UnattachedExtensions = "";
	
	If Parameters.ConfigurationName    <> Metadata.Name
	 Or Parameters.ConfigurationVersion <> Metadata.Version Then
		ErrorText =
			NStr("ru = 'Не удалось обновить все параметры работы расширений, так как
			           |изменилось имя или версия конфигурации - требуется перезапуск сеанса.'; 
			           |en = 'Cannot update all of the extension parameters
			           |because the configuration name or version was changed. Please restart the session.'; 
			           |pl = 'Nie udało się zaktualizować wszystkich parametrów rozszerzeń, ponieważ
			           |zmieniła się nazwa lub wersja konfiguracji - wymagane jest ponowne uruchomienie sesji.';
			           |de = 'Es war nicht möglich, alle Erweiterungseinstellungen zu aktualisieren, da sich
			           |der Name oder die Version der Konfiguration geändert hat - die Sitzung muss neu gestartet werden.';
			           |ro = 'Eșec la actualizarea tuturor parametrilor de lucru ale extensiilor, deoarece
			           |s-a modificat numele sau versiunea configurației - trebuie să relansați sesiunea.';
			           |tr = 'Adı veya yapılandırma sürümü değiştiğinden 
			           |tüm uzantı ayarlarını güncelleştirilemedi-oturum yeniden başlatılmalıdır.'; 
			           |es_ES = 'No se ha podido actualizar todos los parámetros de funcionamiento de extensiones, porque
			           |se ha cambiado el nombre o la versión de la configuración - se requiere reiniciar la sesión.'");
	EndIf;
	
	If Parameters.InstalledExtensions.Main    <> SessionParameters.InstalledExtensions.Main
	 Or Parameters.InstalledExtensions.Patches <> SessionParameters.InstalledExtensions.Patches Then
		ErrorText =
			NStr("ru = 'Не удалось обновить все параметры работы расширений,
			           |так как указанный состав расширений отличается от текущего.'; 
			           |en = 'Cannot update all of the extension parameters
			           |because the specified list of extensions does not match the current one.'; 
			           |pl = 'Nie udało się zaktualizować wszystkich parametrów pracy rozszerzeń,
			           |ponieważ określony skład rozszerzeń różni się od bieżącego.';
			           |de = 'Es war nicht möglich, alle Parameter der Erweiterungen zu aktualisieren,
			           |da die angegebene Zusammensetzung der Erweiterungen von der aktuellen abweicht.';
			           |ro = 'Eșec la actualizarea tuturor parametrilor de lucru ale extensiilor,
			           |deoarece componența indicată a extensiilor este diferită de cea curentă.';
			           |tr = 'Belirtilen uzantı içeriği geçerli olandan farklı olduğu için
			           | tüm uzantı parametreleri güncelleştirilemedi.'; 
			           |es_ES = 'No se ha podido actualizar todos los parámetros del funcionamiento de las extensiones,
			           |porque el contenido indicado de las extensiones se diferencia del actual.'");
	EndIf;
	
	If TypeOf(Parameters.ExtensionsToCheck) = Type("Map") Then
		Extensions = ConfigurationExtensions.Get(, ConfigurationExtensionsSource.SessionApplied);
		AttachedExtensions = New Map;
		For Each Extension In Extensions Do
			AttachedExtensions[Extension.Name] = True;
		EndDo;
		For Each ExtensionToCheck In Parameters.ExtensionsToCheck Do
			If AttachedExtensions[ExtensionToCheck.Key] = Undefined Then
				UnattachedExtensions = UnattachedExtensions
					 + ?(UnattachedExtensions = "", "", ", ") + ExtensionToCheck.Value;
			EndIf;
		EndDo;
	EndIf;
	
	If Not ValueIsFilled(ErrorText) Then
		Try
			FillAllExtensionParameters();
		Except
			ErrorInformation = ErrorInfo();
			ErrorText = DetailErrorDescription(ErrorInformation);
		EndTry;
	EndIf;
	
	If ValueIsFilled(Parameters.AsynchronousCallText) Then
		If ValueIsFilled(ErrorText) Then
			Raise Parameters.AsynchronousCallText + ":" + Chars.LF + ErrorText;
		Else
			Return;
		EndIf;
	EndIf;
	
	Result = New Structure;
	Result.Insert("ErrorText",              ErrorText);
	Result.Insert("UnattachedExtensions", UnattachedExtensions);
	
	PutToTempStorage(Result, Parameters.ResultAddress);
	
EndProcedure

Procedure UpdateExtensionParameters(ExtensionsToCheck = Undefined, UnattachedExtensions = "", AsynchronousCallText = "") Export
	
	If Not Common.SeparatedDataUsageAvailable() Then
		Return;
	EndIf;
	
	ExecutionParameters = New Structure;
	ExecutionParameters.Insert("ConfigurationName",         Metadata.Name);
	ExecutionParameters.Insert("ConfigurationVersion",      Metadata.Version);
	ExecutionParameters.Insert("InstalledExtensions", Catalogs.ExtensionsVersions.InstalledExtensions());
	ExecutionParameters.Insert("ExtensionsToCheck",   ExtensionsToCheck);
	ExecutionParameters.Insert("ResultAddress",         PutToTempStorage(Undefined));
	ExecutionParameters.Insert("AsynchronousCallText", AsynchronousCallText);
	ProcedureParameters = New Array;
	ProcedureParameters.Add(ExecutionParameters);
	
	BackgroundJob = ConfigurationExtensions.ExecuteBackgroundJobWithDatabaseExtensions(
		"StandardSubsystemsServer.FillAllExtensionParametersBackgroundJob", ProcedureParameters);
	If ValueIsFilled(AsynchronousCallText) Then
		Return;
	EndIf;
	BackgroundJob.WaitForCompletion();
	Filter = New Structure("UUID", BackgroundJob.UUID);
	BackgroundJob = BackgroundJobs.GetBackgroundJobs(Filter)[0];
	If BackgroundJob.ErrorInfo <> Undefined Then
		Raise DetailErrorDescription(BackgroundJob.ErrorInfo);
	EndIf;
	
	Result = GetFromTempStorage(ExecutionParameters.ResultAddress);
	If TypeOf(Result) <> Type("Structure") Then
		Raise NStr("ru = 'Фоновое задание подготовки расширений не вернуло результат.'; en = 'The background job that prepares extensions did not return the result.'; pl = 'Zadanie przygotowania rozszerzeń w tle nie zwróciło wyniku.';de = 'Der Hintergrundjob zur Vorbereitung von Erweiterungen lieferte kein Ergebnis.';ro = 'Sarcina de fundal de pregătire a extensiilor nu a returnat rezultatul.';tr = 'Uzantı hazırlama arka plan görevi sonucu iade etmedi.'; es_ES = 'La tarea del fondo de preparación de extensiones no ha devuelto el resultado.'");
	EndIf;
	
	If ValueIsFilled(Result.ErrorText) Then
		Raise Result.ErrorText;
	EndIf;
	
	If ValueIsFilled(Result.UnattachedExtensions) Then
		UnattachedExtensions = Result.UnattachedExtensions;
	EndIf;
	
EndProcedure

#EndRegion

#EndIf