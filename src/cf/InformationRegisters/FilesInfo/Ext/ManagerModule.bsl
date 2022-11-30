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
	
	Ref = "";
	AllFilesOwnersProcessed = False;
	While Not AllFilesOwnersProcessed Do
		
		Query = New Query;
		Query.Text =
		"SELECT DISTINCT TOP 1000
		|	Files.Ref AS Ref
		|FROM
		|	Catalog.Files AS Files
		|		LEFT JOIN InformationRegister.FilesInfo AS FilesInfo
		|		ON Files.Ref = FilesInfo.File
		|WHERE
		|	Files.Ref > &Ref
		|	AND FilesInfo.File IS NULL";
		
		Query.SetParameter("Ref", Ref);
		RefsArray = Query.Execute().Unload().UnloadColumn("Ref"); 
		
		InfobaseUpdate.MarkForProcessing(Parameters, RefsArray);
		
		RefsCount = RefsArray.Count();
		If RefsCount < 1000 Then
			AllFilesOwnersProcessed = True;
		EndIf;
		
		If RefsCount > 0 Then
			Ref = RefsArray[RefsCount-1];
		EndIf;
		
	EndDo;
	
	File = "";
	AllRegisterRecordsProcessed = False;
	While Not AllRegisterRecordsProcessed Do
		
		Query = New Query;
		Query.Text =
		"SELECT DISTINCT TOP 1000
		|	FilesInfo.File AS File
		|FROM
		|	InformationRegister.FilesInfo AS FilesInfo
		|WHERE
		|	FilesInfo.File > &File
		|	AND FilesInfo.FileStorageType = VALUE(Enum.FileStorageTypes.EmptyRef)";
		Query.SetParameter("File", File);
		RegisterDimensions = Query.Execute().Unload();
		
		AdditionalParameters = InfobaseUpdate.AdditionalProcessingMarkParameters();
		AdditionalParameters.IsIndependentInformationRegister = True;
		AdditionalParameters.FullRegisterName = "InformationRegister.FilesInfo";
		
		InfobaseUpdate.MarkForProcessing(Parameters, RegisterDimensions, AdditionalParameters);
		
		RecordsCount = RegisterDimensions.Count();
		If RecordsCount < 1000 Then
			AllRegisterRecordsProcessed = True;
		EndIf;
		
		If RecordsCount > 0 Then
			File = RegisterDimensions[RecordsCount-1].File;
		EndIf;
		
	EndDo;
		
EndProcedure

// Update register records.
Procedure ProcessDataForMigrationToNewVersion(Parameters) Export
	
	Selection = InfobaseUpdate.SelectRefsToProcess(Parameters.Queue, "Catalog.Files");
	ObjectsProcessed = 0;
	ObjectsWithIssuesCount = 0;
	
	While Selection.Next() Do
		BeginTransaction();
		Try
			Lock = New DataLock;
			LockItem = Lock.Add("Catalog.Files");
			LockItem.SetValue("Ref", Selection.Ref);
			LockItem.Mode = DataLockMode.Shared;
			Lock.Lock();
			
			RecordManager = CreateRecordManager();
			FillPropertyValues(RecordManager, Selection.Ref);
			RecordManager.File          = Selection.Ref;
			AttributesStructure          = Common.ObjectAttributesValues(Selection.Ref, "Author, FileOwner");
			RecordManager.Author         = AttributesStructure.Author;
			RecordManager.FileOwner = AttributesStructure.FileOwner;
			
			If Selection.Ref.SignedWithDS AND Selection.Ref.Encrypted Then
				RecordManager.SignedEncryptedPictureNumber = 2;
			ElsIf Selection.Ref.Encrypted Then
				RecordManager.SignedEncryptedPictureNumber = 1;
			ElsIf Selection.Ref.SignedWithDS Then
				RecordManager.SignedEncryptedPictureNumber = 0;
			Else
				RecordManager.SignedEncryptedPictureNumber = -1;
			EndIf;
			RecordManager.Write();
			
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
	
	FilesProcessingCompleted = InfobaseUpdate.DataProcessingCompleted(Parameters.Queue, "Catalog.Files");
	
	Selection = InfobaseUpdate.SelectStandaloneInformationRegisterDimensionsToProcess(
		Parameters.Queue, "InformationRegister.FilesInfo");
		
	While Selection.Next() Do
		
		Try
			
			FileStorageType = Common.ObjectAttributeValue(Selection.File, "FileStorageType");
			
			RecordSet = InformationRegisters.FilesInfo.CreateRecordSet();
			RecordSet.Filter.File.Set(Selection.File);
			RecordSet.Read();
			
			For Each FileInfo In RecordSet Do
				FileInfo.FileStorageType = FileStorageType;
			EndDo;
			
			RecordSet.Write();
			InfobaseUpdate.MarkProcessingCompletion(RecordSet);
			
			ObjectsProcessed = ObjectsProcessed + 1;
			
		Except
			
			ObjectsWithIssuesCount = ObjectsWithIssuesCount + 1;
			MessageText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'Не удалось обработать тип хранения файла: %1 по причине:
				|%2'; 
				|en = 'Cannot process storage for file %1. Reason:
				|%2'; 
				|pl = 'Nie udało się przetworzyć rodzaju przechowywania pliku: %1 z powodu:
				|%2';
				|de = 'Der Dateispeichertyp konnte nicht verarbeitet werden: %1 aus dem Grund:
				|%2';
				|ro = 'Eșec la procesarea tipului de stocare a fișierului: %1 din motivul:
				|%2';
				|tr = 'Dosya depolama türü işlenemedi: %1nedeniyle:
				|%2'; 
				|es_ES = 'No se ha podido procesar tipo de guardar el archivo: %1 a causa de:
				|%2'"), 
				Selection.File, DetailErrorDescription(ErrorInfo()));
			WriteLogEvent(InfobaseUpdate.EventLogEvent(), EventLogLevel.Warning,
				Selection.Ref.Metadata(), Selection.Ref, MessageText);
				
		EndTry;
		
	EndDo;
	
	RegisterProcessingCompleted = InfobaseUpdate.DataProcessingCompleted(Parameters.Queue, "InformationRegister.FilesInfo");
	
	Parameters.ProcessingCompleted = FilesProcessingCompleted AND RegisterProcessingCompleted;
	If ObjectsProcessed = 0 AND ObjectsWithIssuesCount <> 0 Then
		MessageText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Процедуре РегистрыСведений.СведенияОФайлах.ОбработатьДанныеДляПереходаНаНовуюВерсию не удалось обработать некоторые файлы файлов (пропущены): %1'; en = 'The InformationRegisters.FilesInfo.ProcessDataForMigrationToNewVersion procedure cannot process some file files (skipped): %1.'; pl = 'Procedurze InformationRegisters.FilesInfo.ProcessDataForMigrationToNewVersion nie udało się przetworzyć niektóre pliki plików (pomijane): %1';de = 'Die Prozedur InformationRegisters.FilesInfo.ProcessDataForMigrationToNewVersion kann einige Datei-Dateien nicht verarbeiten (übersprungen): %1';ro = 'Procedura InformationRegisters.FilesInfo.ProcessDataForMigrationToNewVersion nu poate procesa unele obiecte de tip fișier (omis): %1';tr = 'BilgiKaydedicileri.DosyaBilgileri.YeniSürümeGeçişİçinVerileriİşle prosedürü bazı dosyaları işleyemedi (atlatıldı): %1'; es_ES = 'El procedimiento InformationRegisters.FilesInfo.ProcessDataForMigrationToNewVersion no ha podido procesar algunos archivos de archivos (saltados): %1'"), 
			ObjectsWithIssuesCount);
		Raise MessageText;
	Else
		WriteLogEvent(InfobaseUpdate.EventLogEvent(), EventLogLevel.Information,
			Catalogs.Files,,
			StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'Процедура РегистрыСведений.СведенияОФайлах.ОбработатьДанныеДляПереходаНаНовуюВерсию обработала очередную порцию файлов: %1'; en = 'The InformationRegisters.FilesInfo.ProcessDataForMigrationToNewVersion procedure has processed files: %1.'; pl = 'Procedura InformationRegisters.FilesInfo.ProcessDataForMigrationToNewVersion opracowała kolejną porcję wersji plików: %1';de = 'Das Verfahren InformationRegisters.FilesInfo.ProcessDataForMigrationToNewVersion hat Dateien verarbeitet: %1';ro = 'Procedura InformationRegisters.FilesInfo.ProcessDataForMigrationToNewVersion a procesat fișiere: %1';tr = 'BilgiKayıtları.DosyalarBilgisiYeniSürümeGeçmekİçinVeriİşle prosedürü dosyaları işledi: %1'; es_ES = 'El procedimiento InformationRegisters.FilesInfo.ProcessDataForMigrationToNewVersion ha procesado los archivos: %1'"),
				ObjectsProcessed));
	EndIf;
	
EndProcedure

#EndRegion

#EndIf
