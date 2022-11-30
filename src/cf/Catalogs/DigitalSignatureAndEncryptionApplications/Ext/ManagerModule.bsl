///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

#Region ForCallsFromOtherSubsystems

// StandardSubsystems.BatchObjectsModification

// Returns object attributes allowed to be edited using batch attribute change data processor.
// 
//
// Returns:
//  Array - a list of object attribute names.
Function AttributesToEditInBatchProcessing() Export
	
	AttributesToEdit = New Array;
	Return AttributesToEdit;
	
EndFunction

// End StandardSubsystems.BatchObjectsModification

#EndRegion

#EndRegion

#Region EventHandlers

Procedure FormGetProcessing(FormType, Parameters, SelectedForm, AdditionalInformation, StandardProcessing)
	
	If FormType = "ListForm" Then
		StandardProcessing = False;
		Parameters.Insert("ShowApplicationsPage");
		SelectedForm = Metadata.CommonForms.DigitalSignatureAndEncryptionSettings;
		
	ElsIf Parameters.Property("Key")
	        AND Parameters.Key.IsCloudServiceApplication
	        AND Metadata.DataProcessors.Find("ApplicationForNewQualifiedCertificateIssue") <> Undefined Then
		
		StandardProcessing = False;
		SelectedForm = "DataProcessor.DigitalSignatureAndEncryptionApplications.Form.ApplicationInCloudService";
	EndIf;
	
EndProcedure

Procedure ChoiceDataGetProcessing(ChoiceData, Parameters, StandardProcessing)
	
	If Not DigitalSignatureInternal.UseDigitalSignatureSaaS() Then
		Parameters.Filter.Insert("IsCloudServiceApplication", False);
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

Function ApplicationsSettingsToSupply() Export
	
	Settings = New ValueTable;
	Settings.Columns.Add("Presentation");
	Settings.Columns.Add("ApplicationName");
	Settings.Columns.Add("ApplicationType");
	Settings.Columns.Add("SignAlgorithm");
	Settings.Columns.Add("HashAlgorithm");
	Settings.Columns.Add("EncryptAlgorithm");
	Settings.Columns.Add("ID");
	
	Settings.Columns.Add("SignAlgorithms",     New TypeDescription("Array"));
	Settings.Columns.Add("HashAlgorithms", New TypeDescription("Array"));
	Settings.Columns.Add("EncryptAlgorithms",  New TypeDescription("Array"));
	
	If Metadata.DataProcessors.Find("DigitalSignatureAndEncryptionApplications") <> Undefined Then
		DigitalSignatureAndEncryptionApplicationProcessing = Common.ObjectManagerByFullName(
			"DataProcessor.DigitalSignatureAndEncryptionApplications");
		DigitalSignatureAndEncryptionApplicationProcessing.AddApplicationsSuppliedSettings(Settings);
	Else
		AddMicrosoftEnhancedCSPSettings(Settings);
	EndIf;
	
	Return Settings;
	
EndFunction

Procedure AddMicrosoftEnhancedCSPSettings(Settings) Export
	
	// Microsoft Enhanced CSP
	Setting = Settings.Add();
	Setting.Presentation       = NStr("ru = 'Microsoft Enhanced CSP'; en = 'Microsoft Enhanced CSP'; pl = 'Microsoft Enhanced CSP';de = 'Microsoft Enhanced CSP';ro = 'Microsoft Enhanced CSP';tr = 'Microsoft Enhanced CSP'; es_ES = 'Microsoft Enhanced CSP'");
	Setting.ApplicationName        = "Microsoft Enhanced Cryptographic Provider v1.0";
	Setting.ApplicationType        = 1;
	Setting.SignAlgorithm     = "RSA_SIGN"; // One option.
	Setting.HashAlgorithm = "MD5";      // Options: SHA-1, MD2, MD4, MD5.
	Setting.EncryptAlgorithm  = "RC2";      // Options: RC2, RC4, DES, 3DES.
	Setting.ID       = "MicrosoftEnhanced";
	
	Setting.SignAlgorithms.Add("RSA_SIGN");
	Setting.HashAlgorithms.Add("SHA-1");
	Setting.HashAlgorithms.Add("MD2");
	Setting.HashAlgorithms.Add("MD4");
	Setting.HashAlgorithms.Add("MD5");
	Setting.EncryptAlgorithms.Add("RC2");
	Setting.EncryptAlgorithms.Add("RC4");
	Setting.EncryptAlgorithms.Add("DES");
	Setting.EncryptAlgorithms.Add("3DES");
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Updating an infobase.

Procedure FillInitialSettings(Applications = Undefined, WithoutCloudApplication = False) Export
	
	If Applications = Undefined Then
		Applications = New Map;
		AddInitialPopulationApplications(Applications);
	EndIf;
	
	ApplicationsDetails = New Array;
	For Each KeyAndValue In Applications Do
		ApplicationsDetails.Add(DigitalSignature.NewApplicationDetails(
			KeyAndValue.Key, KeyAndValue.Value));
	EndDo;
	
	DigitalSignature.FillApplicationsList(ApplicationsDetails);
	
	If WithoutCloudApplication Then
		Return;
	EndIf;
	
	If Metadata.DataProcessors.Find("DigitalSignatureAndEncryptionApplications") <> Undefined Then
		DigitalSignatureAndEncryptionApplicationProcessing = Common.ObjectManagerByFullName(
			"DataProcessor.DigitalSignatureAndEncryptionApplications");
		DigitalSignatureAndEncryptionApplicationProcessing.UpdateCloudServiceApplication();
	EndIf;
	
EndProcedure

Procedure AddInitialPopulationApplications(Applications)
	
	If Metadata.DataProcessors.Find("DigitalSignatureAndEncryptionApplications") <> Undefined Then
		DigitalSignatureAndEncryptionApplicationProcessing = Common.ObjectManagerByFullName(
			"DataProcessor.DigitalSignatureAndEncryptionApplications");
		DigitalSignatureAndEncryptionApplicationProcessing.AddInitialPopulationApplications(Applications);
	Else
		Applications.Insert("Microsoft Enhanced Cryptographic Provider v1.0", 1);
	EndIf;
	
EndProcedure

Procedure RegisterDataToProcessForMigrationToNewVersion(Parameters) Export
	
	Query = New Query;
	Query.Text = 
	"SELECT
	|	DigitalSignatureAndEncryptionApplications.Ref
	|FROM
	|	Catalog.DigitalSignatureAndEncryptionApplications AS DigitalSignatureAndEncryptionApplications
	|WHERE
	|	NOT DigitalSignatureAndEncryptionApplications.IsCloudServiceApplication";
	
	QueryResult = Query.Execute();
	
	DetailedRecordsSelection = QueryResult.Select();
	
	While DetailedRecordsSelection.Next() Do
		InfobaseUpdate.MarkForProcessing(Parameters, DetailedRecordsSelection.Ref);
	EndDo;
	
EndProcedure

Procedure ProcessDataForMigrationToNewVersion(Parameters) Export
	
	ProcessingCompleted = True;
	
	DetailedRecordsSelection = InfobaseUpdate.SelectRefsToProcess(Parameters.Queue,
		"Catalog.DigitalSignatureAndEncryptionApplications");
	
	ObjectsProcessed = 0;
	ObjectsWithIssuesCount = 0;
	
	SettingsToSupply = ApplicationsSettingsToSupply();
	
	While DetailedRecordsSelection.Next() Do
		UpdateApplicationPresentationDeferred(DetailedRecordsSelection.Ref,
			ObjectsProcessed, ObjectsWithIssuesCount, SettingsToSupply);
	EndDo;
	
	FillInitialSettingsDeferred(ObjectsProcessed, ObjectsWithIssuesCount);
	
	If Not InfobaseUpdate.DataProcessingCompleted(Parameters.Queue, "Catalog.DigitalSignatureAndEncryptionApplications") Then
		ProcessingCompleted = False;
	EndIf;
	
	If ObjectsProcessed = 0 AND ObjectsWithIssuesCount <> 0 Then
		MessageText = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("ru = 'Процедуре Справочники.ОбработатьДанныеДляПереходаНаНовуюВерсию.ОбработатьДанныеДляПереходаНаНовуюВерсию не удалось обработать некоторые программы электронной подписи (пропущены): %1'; en = 'The Catalogs.ProcessDataForMigrationToNewVersion.ProcessDataForMigrationToNewVersion procedure cannot process some digital signature applications (skipped): %1.'; pl = 'The Catalogs.ProcessDataForMigrationToNewVersion.ProcessDataForMigrationToNewVersion procedure cannot process some digital signature applications (skipped): %1.';de = 'The Catalogs.ProcessDataForMigrationToNewVersion.ProcessDataForMigrationToNewVersion procedure cannot process some digital signature applications (skipped): %1.';ro = 'The Catalogs.ProcessDataForMigrationToNewVersion.ProcessDataForMigrationToNewVersion procedure cannot process some digital signature applications (skipped): %1.';tr = 'The Catalogs.ProcessDataForMigrationToNewVersion.ProcessDataForMigrationToNewVersion procedure cannot process some digital signature applications (skipped): %1.'; es_ES = 'The Catalogs.ProcessDataForMigrationToNewVersion.ProcessDataForMigrationToNewVersion procedure cannot process some digital signature applications (skipped): %1.'"), 
		ObjectsWithIssuesCount);
		Raise MessageText;
	Else
		WriteLogEvent(InfobaseUpdate.EventLogEvent(), EventLogLevel.Information,
		Metadata.FindByFullName("Catalog.DigitalSignatureAndEncryptionApplications"),,
		StringFunctionsClientServer.SubstituteParametersToString(
		NStr("ru = 'Процедура Справочники.ОбработатьДанныеДляПереходаНаНовуюВерсию.ОбработатьДанныеДляПереходаНаНовуюВерсию обработала очередную порцию программ электронной подписи: %1'; en = 'The Catalogs.ProcessDataForMigrationToNewVersion.ProcessDataForMigrationToNewVersion procedure has processed digital signature applications: %1.'; pl = 'The Catalogs.ProcessDataForMigrationToNewVersion.ProcessDataForMigrationToNewVersion procedure has processed digital signature applications: %1.';de = 'The Catalogs.ProcessDataForMigrationToNewVersion.ProcessDataForMigrationToNewVersion procedure has processed digital signature applications: %1.';ro = 'The Catalogs.ProcessDataForMigrationToNewVersion.ProcessDataForMigrationToNewVersion procedure has processed digital signature applications: %1.';tr = 'The Catalogs.ProcessDataForMigrationToNewVersion.ProcessDataForMigrationToNewVersion procedure has processed digital signature applications: %1.'; es_ES = 'The Catalogs.ProcessDataForMigrationToNewVersion.ProcessDataForMigrationToNewVersion procedure has processed digital signature applications: %1.'"),
		ObjectsProcessed));
	EndIf;
	
	Parameters.ProcessingCompleted = ProcessingCompleted;

EndProcedure

Procedure UpdateApplicationPresentationDeferred(Application, ObjectsProcessed, ObjectsWithIssuesCount, SettingsToSupply)
	
	Lock = New DataLock;
	Lock.Add("Catalog.DigitalSignatureAndEncryptionApplications");
	
	BeginTransaction();
	Try
		Lock.Lock();
		
		Properties = Common.ObjectAttributesValues(Application,
			"ApplicationName, ApplicationType, Description, IsCloudServiceApplication");
		
		Filter = New Structure("ApplicationName, ApplicationType", Properties.ApplicationName, Properties.ApplicationType);
		Rows = SettingsToSupply.FindRows(Filter);
		
		If Not Properties.IsCloudServiceApplication
		   AND Rows.Count() = 1
		   AND Rows[0].Presentation <> Properties.Description Then
			
			ApplicationObject = Application.GetObject();
			ApplicationObject.Description = Rows[0].Presentation;
			
			InfobaseUpdate.WriteObject(ApplicationObject);
		EndIf;
		
		CommitTransaction();
	Except
		RollbackTransaction();
		ObjectsWithIssuesCount = ObjectsWithIssuesCount + 1;
		
		MessageText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Не удалось обновить программу ""%1"" по причине:
			|%2'; 
			|en = 'Cannot update the ""%1"" application due to:
			|%2'; 
			|pl = 'Cannot update the ""%1"" application due to:
			|%2';
			|de = 'Cannot update the ""%1"" application due to:
			|%2';
			|ro = 'Cannot update the ""%1"" application due to:
			|%2';
			|tr = 'Cannot update the ""%1"" application due to:
			|%2'; 
			|es_ES = 'Cannot update the ""%1"" application due to:
			|%2'"), String(Application), DetailErrorDescription(ErrorInfo()));
		
		WriteLogEvent(InfobaseUpdate.EventLogEvent(),
			EventLogLevel.Warning, , , MessageText);
		Return;
	EndTry;
	
	ObjectsProcessed = ObjectsProcessed + 1;
	InfobaseUpdate.MarkProcessingCompletion(Application.Ref);
	
EndProcedure

Procedure FillInitialSettingsDeferred(ObjectsProcessed, ObjectsWithIssuesCount)
	
	Query = New Query;
	Query.Text = 
	"SELECT
	|	DigitalSignatureAndEncryptionApplications.ApplicationName AS ApplicationName,
	|	DigitalSignatureAndEncryptionApplications.ApplicationType AS ApplicationType
	|FROM
	|	Catalog.DigitalSignatureAndEncryptionApplications AS DigitalSignatureAndEncryptionApplications
	|WHERE
	|	DigitalSignatureAndEncryptionApplications.IsCloudServiceApplication";
	
	Applications = New Map;
	AddInitialPopulationApplications(Applications);
	
	Lock = New DataLock;
	Lock.Add("Catalog.DigitalSignatureAndEncryptionApplications");
	
	BeginTransaction();
	Try
		Lock.Lock();
		
		Selection = Query.Execute().Select();
		
		While Selection.Next() Do
			If Applications.Get(Selection.ApplicationName) = Selection.ApplicationType Then
				Applications.Delete(Selection.ApplicationName);
			EndIf;
		EndDo;
		
		FillInitialSettings(Applications, True);
		
		CommitTransaction();
	Except
		RollbackTransaction();
		
		MessageText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Не удалось дозаполнить начальные настройки программ по причине:
			|%1'; 
			|en = 'Cannot fill in initial application settings due to:
			|%1'; 
			|pl = 'Cannot fill in initial application settings due to:
			|%1';
			|de = 'Cannot fill in initial application settings due to:
			|%1';
			|ro = 'Cannot fill in initial application settings due to:
			|%1';
			|tr = 'Cannot fill in initial application settings due to:
			|%1'; 
			|es_ES = 'Cannot fill in initial application settings due to:
			|%1'"), DetailErrorDescription(ErrorInfo()));
		
		Raise MessageText;
	EndTry;
	
	If Metadata.DataProcessors.Find("DigitalSignatureAndEncryptionApplications") <> Undefined Then
		DigitalSignatureAndEncryptionApplicationProcessing = Common.ObjectManagerByFullName(
			"DataProcessor.DigitalSignatureAndEncryptionApplications");
		DigitalSignatureAndEncryptionApplicationProcessing.UpdateCloudServiceApplication(True,
			ObjectsProcessed, ObjectsWithIssuesCount);
	EndIf;
	
EndProcedure

#EndRegion

#EndIf
