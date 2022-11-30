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
	
	Return FilesOperations.AttributesToEditInBatchProcessing();
	
EndFunction

// End StandardSubsystems.BatchObjectsModification

// StandardSubsystems.AccessManagement

// See AccessManagementOverridable.OnFillListsWithAccessRestriction. 
Procedure OnFillAccessRestriction(Restriction) Export
	
	Restriction.Text =
	"AllowRead
	|WHERE
	|	ObjectReadingAllowed(FileOwner)
	|;
	|AllowUpdateIfReadingAllowed
	|WHERE
	|	ObjectUpdateAllowed(FileOwner)";
	
	Restriction.TextForExternalUsers =
	"AllowRead
	|WHERE
	|	CASE 
	|		WHEN ValueType(FileOwner) = Type(Catalog.FilesFolders)
	|			THEN ObjectReadingAllowed(CAST(FileOwner AS Catalog.FilesFolders))
	|		ELSE ValueAllowed(CAST(Author AS Catalog.ExternalUsers))
	|	END
	|;
	|AllowUpdateIfReadingAllowed
	|WHERE
	|	CASE 
	|		WHEN ValueType(FileOwner) = Type(Catalog.FilesFolders)
	|			THEN ObjectUpdateAllowed(CAST(FileOwner AS Catalog.FilesFolders))
	|		ELSE ValueAllowed(CAST(Author AS Catalog.ExternalUsers))
	|	END";
	Restriction.ByOwnerWithoutSavingAccessKeysForExternalUsers = False;
	
EndProcedure

// End StandardSubsystems.AccessManagement

#EndRegion

#EndRegion

#Region EventHandlers

Procedure FormGetProcessing(FormType, Parameters, SelectedForm, AdditionalInformation, StandardProcessing)
	
	If Parameters.Count() = 0 Then
		SelectedForm = "Files"; // Opening the file list because the specific file is not specified.
		StandardProcessing = False;
	EndIf;
	If FormType = "ListForm" Then
		CurrentRow = CommonClientServer.StructureProperty(Parameters, "CurrentRow");
		If TypeOf(CurrentRow) = Type("CatalogRef.Files") AND Not CurrentRow.IsEmpty() Then
			StandardProcessing = False;
			FileOwner = Common.ObjectAttributeValue(CurrentRow, "FileOwner");
			If TypeOf(FileOwner) = Type("CatalogRef.FilesFolders") Then
				Parameters.Insert("Folder", FileOwner);
				SelectedForm = "DataProcessor.FilesOperations.Form.AttachedFiles";
			Else
				Parameters.Insert("FileOwner", FileOwner);
				SelectedForm = "DataProcessor.FilesOperations.Form.AttachedFiles";
			EndIf;
		EndIf;
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

// Registers the objects to be updated to the latest version in the InfobaseUpdate exchange plan.
// 
Procedure RegisterDataToProcessForMigrationToNewVersion(Parameters) Export
	
	AllFilesProcessed = False;
	Ref = "";
	
	While Not AllFilesProcessed Do
	
		Query = New Query;
		Query.Text = 
			"SELECT TOP 1000
			|	Files.Ref AS Ref
			|FROM
			|	Catalog.Files AS Files
			|WHERE
			|	((Files.UniversalModificationDate = DATETIME(1, 1, 1, 0, 0, 0)
			|	AND Files.CurrentVersion <> VALUE(Catalog.FilesVersions.EmptyRef))
			|	OR Files.FileStorageType = VALUE(Enum.FileStorageTypes.EmptyRef))
			|	AND Files.Ref > &Ref
			|
			|ORDER BY
			|	Ref";
		
		Query.SetParameter("Ref", Ref);
		RefsArray = Query.Execute().Unload().UnloadColumn("Ref");

		InfobaseUpdate.MarkForProcessing(Parameters, RefsArray);
		
		RefsCount = RefsArray.Count();
		If RefsCount < 1000 Then
			AllFilesProcessed = True;
		EndIf;
		
		If RefsCount > 0 Then
			Ref = RefsArray[RefsCount - 1];
		EndIf;
		
	EndDo;
	
EndProcedure

Procedure ProcessDataForMigrationToNewVersion(Parameters) Export
	
	ProcessingCompleted = True;
	
	Selection = InfobaseUpdate.SelectRefsToProcess(Parameters.Queue, "Catalog.Files");
	
	ObjectsProcessed = 0;
	ObjectsWithIssuesCount = 0;
	
	While Selection.Next() Do
		
		BeginTransaction();
		Try
			
			DataLock = New DataLock;
			DataLockItem = DataLock.Add("Catalog.Files");
			DataLockItem.SetValue("Ref", Selection.Ref);
			
			DataLockItem = DataLock.Add("Catalog.FilesVersions");
			DataLockItem.SetValue("Ref", Selection.Ref.CurrentVersion);
			DataLockItem.Mode = DataLockMode.Shared;
			
			DataLock.Lock();
			
			FileToUpdate = Selection.Ref.GetObject();
			FileToUpdate.UniversalModificationDate = FileToUpdate.CurrentVersion.UniversalModificationDate;
			FileToUpdate.FileStorageType             = FileToUpdate.CurrentVersion.FileStorageType;
			InfobaseUpdate.WriteObject(FileToUpdate);
			
			InfobaseUpdate.MarkProcessingCompletion(Selection.Ref);
			ObjectsProcessed = ObjectsProcessed + 1;
			CommitTransaction();
		Except
			RollbackTransaction();
			// If you fail to process a document, try again.
			ObjectsWithIssuesCount = ObjectsWithIssuesCount + 1;
			
			MessageText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'Не удалось обработать файл: %1 по причине:
				|%2'; 
				|en = 'Cannot process file %1. Reason:
				|%2'; 
				|pl = 'Nie udało się przetworzyć pliku: %1 z powodu:
				|%2';
				|de = 'Die Datei konnte nicht verarbeitet werden: %1 aus folgendem Grund:
				|%2';
				|ro = 'Eșec la procesarea fișierului: %1 din motivul: 
				|%2';
				|tr = 'Dosya aşağıdaki nedenle işlenemedi: 
				|%2 %1'; 
				|es_ES = 'No se ha podido procesar el archivo: %1 a causa de: 
				|%2'"), 
				Selection.Ref, DetailErrorDescription(ErrorInfo()));
				WriteLogEvent(InfobaseUpdate.EventLogEvent(), EventLogLevel.Warning,
				Selection.Ref.Metadata(), Selection.Ref, MessageText);
		EndTry;
		
	EndDo;
	
	If Not InfobaseUpdate.DataProcessingCompleted(Parameters.Queue, "Catalog.Files") Then
		ProcessingCompleted = False;
	EndIf;
	
	If ObjectsProcessed = 0 AND ObjectsWithIssuesCount <> 0 Then
		MessageText = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("ru = 'Процедуре Справочники.Файлы.ОбработатьДанныеДляПереходаНаНовуюВерсию.ОбработатьДанныеДляПереходаНаНовуюВерсию не удалось обработать программы электронной подписи (пропущены): %1'; en = 'The Catalogs.Files.ProcessDataForMigrationToNewVersion procedure cannot process digital signature applications (skipped): %1.'; pl = 'Procedurze Catalogs.Files.ProcessDataForMigrationToNewVersion.ProcessDataForMigrationToNewVersion nie udało się przetworzyć programów podpisu elektronicznego (pominięte): %1';de = 'Das Verfahren Catalogs.Files.ProcessDataForMigrationToNewVersion.ProcessDataForMigrationToNewVersion kann digitale Signatur-Anwendungen nicht verarbeiten (übersprungen): %1.';ro = 'Procedura Catalogs.Files.ProcessDataForMigrationToNewVersion.ProcessDataForMigrationToNewVersion nu poate procesa aplicațiile de semnătură digitală (omisă): %1.';tr = 'BilgiKaydedicileri.Dosyalar.YeniSürümeGeçişİçinVeriİşle.YeniSürümeGeçişİçinVeriİşle prosedürü, e-imza uygulamalarını işleyemedi (atladı) : %1'; es_ES = 'El procedimiento Catalogs.Files.ProcessDataForMigrationToNewVersion.ProcessDataForMigrationToNewVersion no ha podido procesar los programas de la firma electrónica (saltados): %1'"), 
		ObjectsWithIssuesCount);
		Raise MessageText;
	Else
		WriteLogEvent(InfobaseUpdate.EventLogEvent(), EventLogLevel.Information,
		, ,
		StringFunctionsClientServer.SubstituteParametersToString(
		NStr("ru = 'Процедура Справочники.Файлы.ОбработатьДанныеДляПереходаНаНовуюВерсию обработала очередную порцию программ электронной подписи: %1'; en = 'The Catalogs.Files.ProcessDataForMigrationToNewVersion procedure has processed digital signature applications: %1.'; pl = 'Procedura Catalogs.Files.ProcessDataForMigrationToNewVersion przetworzyć kolejną partię programów do podpisu elektronicznego: %1';de = 'Das Verfahren Catalogs.Files.ProcessDataForMigrationToNewVersion hat Anwendungen für digitale Signaturen verarbeitet: %1.';ro = 'Procedura Catalogs.Files.ProcessDataForMigrationToNewVersion a procesat cererile de semnătură digitală: %1.';tr = 'Catalogs.Files.ProcessDataForMigrationToNewVersion prosedürü sıradaki e-imza uygulamaların kısmını işledi: %1'; es_ES = 'El procedimiento Catalogs.Files.ProcessDataForMigrationToNewVersion no ha procesado una porción de programas de firma electrónica: %1'"),
		ObjectsProcessed));
	EndIf;
	
	Parameters.ProcessingCompleted = ProcessingCompleted;
	
EndProcedure

#EndRegion

#EndIf

