///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Internal

////////////////////////////////////////////////////////////////////////////////
// Update handlers.

// Registers objects, for which it is necessary to update register records on the InfobaseUpdate 
// exchange plan.
//
Procedure RegisterDataToProcessForMigrationToNewVersion(Parameters) Export
	
	Query = New Query;
	Query.Text = 
		"SELECT
		|	FilesVersions.Ref
		|FROM
		|	Catalog.FilesVersions AS FilesVersions
		|		LEFT JOIN InformationRegister.BinaryFilesData AS BinaryFilesData
		|		ON FilesVersions.Ref = BinaryFilesData.File
		|WHERE
		|	BinaryFilesData.File IS NULL 
		|	AND FilesVersions.FileStorageType = VALUE(Enum.FileStorageTypes.InInfobase)
		|
		|ORDER BY
		|	FilesVersions.UniversalModificationDate DESC";
	
	RefsArray = Query.Execute().Unload().UnloadColumn("Ref"); 
	InfobaseUpdate.MarkForProcessing(Parameters, RefsArray);
	
EndProcedure

// Update register records.
Procedure ProcessDataForMigrationToNewVersion(Parameters) Export
	
	ProcessingCompleted = True;
	
	Selection = InfobaseUpdate.SelectRefsToProcess(Parameters.Queue, "Catalog.FilesVersions");
	
	ObjectsProcessed = 0;
	ObjectsWithIssuesCount = 0;
	
	While Selection.Next() Do
		
		BeginTransaction();
		Try
			
			DataLock = New DataLock;
			DataLockItem = DataLock.Add("InformationRegister.DeleteStoredVersionFiles");
			DataLockItem.SetValue("FileVersion", Selection.Ref);
			DataLockItem.Mode = DataLockMode.Shared;
			DataLock.Lock();
			
			WriteFileVersionManager = InformationRegisters.DeleteStoredVersionFiles.CreateRecordManager();
			WriteFileVersionManager.FileVersion = Selection.Ref;
			WriteFileVersionManager.Read();
			
			BinaryData = WriteFileVersionManager.StoredFile.Get();
			
			RecordManager = CreateRecordManager();
			RecordManager.File = Selection.Ref;
			RecordManager.FileBinaryData = New ValueStorage(BinaryData, New Deflation(9));
			RecordManager.Write(True);
			
			InfobaseUpdate.MarkProcessingCompletion(Selection.Ref);
			ObjectsProcessed = ObjectsProcessed + 1;
			CommitTransaction();
		Except
			RollbackTransaction();
			// If you fail to process a document, try again.
			ObjectsWithIssuesCount = ObjectsWithIssuesCount + 1;
			
			MessageText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Не удалось обработать версию файла: %1 по причине:
			|%2'; 
			|en = 'Cannot process file version %1. Reason: 
			|%2'; 
			|pl = 'Nie można przetworzyć wersji pliku: %1 z powodu:
			|%2';
			|de = 'Die Version der Datei konnte nicht verarbeitet werden: %1aus dem Grund:
			|%2';
			|ro = 'Eșec la procesarea versiunii fișierului: %1 din motivul: 
			|%2';
			|tr = 'Dosya sürümü ""%1"" aşağıdaki nedenle işlenemedi: 
			|%2 '; 
			|es_ES = 'No se ha podido procesar la versión del archivo: %1 a causa de:
			|%2'"), 
			Selection.Ref, DetailErrorDescription(ErrorInfo()));
			WriteLogEvent(InfobaseUpdate.EventLogEvent(), EventLogLevel.Warning,
			Selection.Ref.Metadata(), Selection.Ref, MessageText);
		EndTry;
		
	EndDo;
	
	If Not InfobaseUpdate.DataProcessingCompleted(Parameters.Queue, "Catalog.FilesVersions") Then
		ProcessingCompleted = False;
	EndIf;
	
	If ObjectsProcessed = 0 AND ObjectsWithIssuesCount <> 0 Then
		MessageText = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("ru = 'Процедуре ПеренестиДвоичныеДанныеФайловВРегистрСведенийДвоичныеДанныеФайлов не удалось обработать некоторые версии файлов (пропущены): %1'; en = 'The MoveBinaryFilesDataToBinaryFilesDataInformationRegister procedure cannot process file versions (skipped): %1.'; pl = 'Procedurze  ПеренестиДвоичныеДанныеФайловВРегистрСведенийДвоичныеДанныеФайлов nie udało się przetworzyć niektórych wersji plików (pominięte): %1';de = 'Die Prozedur ÜbertragenVonBinärdatendateienZumRegistrierenVonInformationsBinärdatendateien konnte einige Versionen von Dateien nicht verarbeiten (übersprungen): %1';ro = 'Procedura ПеренестиДвоичныеДанныеФайловВРегистрСведенийДвоичныеДанныеФайлов nu a putut procesa unele versiuni ale fișierelor (omise): %1';tr = 'DosyalarınİkiliVerileriDosyalarınİkiliVerileriBilgiKaydediciyeTransferEt işlemi dosyaların bazı sürümlerini işlenemedi (atlatıldı): %1'; es_ES = 'El procedimiento MoveBinaryFilesDataToBinaryFilesDataInformationRegister no ha podido procesar unas versiones de archivos (saltadas): %1'"), 
		ObjectsWithIssuesCount);
		Raise MessageText;
	Else
		WriteLogEvent(InfobaseUpdate.EventLogEvent(), EventLogLevel.Information,
		Metadata.FindByFullName("Catalog.FilesVersions"),,
		StringFunctionsClientServer.SubstituteParametersToString(
		NStr("ru = 'Процедура ПеренестиДвоичныеДанныеФайловВРегистрСведенийДвоичныеДанныеФайлов обработала очередную порцию версий: %1'; en = 'The MoveBinaryFilesDataToBinaryFilesDataInformationRegister procedure has processed versions: %1.'; pl = 'Procedura ПеренестиДвоичныеДанныеФайловВРегистрСведенийДвоичныеДанныеФайлов przetworzyła kolejną porcję wersji: %1';de = 'Die Prozedur ÜbertragenVonBinärdatendateienZumRegistrierenVonInformationsBinärdatendateien verarbeitete einen weiteren Teil von Versionen: %1';ro = 'Procedura ПеренестиДвоичныеДанныеФайловВРегистрСведенийДвоичныеДанныеФайлов a procesat porțiunea de rând de versiuni: %1';tr = 'DosyalarınİkiliVerileriDosyalarınİkiliVerileriBilgiKaydediciyeTransferEt işlemi sıradaki sürümleri işledi: %1'; es_ES = 'El procedimiento MoveBinaryFilesDataToBinaryFilesDataInformationRegister ha procesado una porción de versiones: %1'"),
		ObjectsProcessed));
	EndIf;
	
	Parameters.ProcessingCompleted = ProcessingCompleted;
	
EndProcedure

#EndRegion

#EndIf
