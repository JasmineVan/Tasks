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
	
	AllFilesOwnersProcessed = False;
	Ref = "";
	While Not AllFilesOwnersProcessed Do
		
		Query = New Query;
		Query.Text =
			"SELECT DISTINCT TOP 1000
			|	Files.Ref AS Ref
			|FROM
			|	Catalog.Files AS Files
			|		LEFT JOIN InformationRegister.FilesExist AS FilesExist
			|		ON Files.FileOwner = FilesExist.ObjectWithFiles
			|WHERE
			|	FilesExist.ObjectWithFiles IS NULL 
			|	AND Files.Ref > &Ref
			|
			|ORDER BY
			|	Ref";
			
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
	
EndProcedure

// Update register records.
Procedure ProcessDataForMigrationToNewVersion(Parameters) Export
	
	ProcessingCompleted = True;
	
	Selection = InfobaseUpdate.SelectRefsToProcess(Parameters.Queue, "Catalog.Files");
	
	ObjectsProcessed = 0;
	ObjectsWithIssuesCount = 0;
	
	While Selection.Next() Do
		
		FileOwner = Common.ObjectAttributeValue(Selection.Ref, "FileOwner");
		If NOT ValueIsFilled(FileOwner) Then
			InfobaseUpdate.MarkProcessingCompletion(Selection.Ref);
			Continue;
		EndIf;
		
		BeginTransaction();
		Try
			
			Lock = New DataLock;
			LockItem = Lock.Add("Catalog.Files");
			LockItem.SetValue("Ref", Selection.Ref);
			LockItem.Mode = DataLockMode.Shared;
			Lock.Lock();
			
			FilesExistWriteManager = CreateRecordManager();
			FilesExistWriteManager.ObjectWithFiles       = FileOwner;
			FilesExistWriteManager.HasFiles            = True;
			FilesExistWriteManager.ObjectID = FilesOperationsInternal.GetNextObjectID();
			FilesExistWriteManager.Write(True);
			
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
	
	If Not InfobaseUpdate.DataProcessingCompleted(Parameters.Queue, "Catalog.Files") Then
		ProcessingCompleted = False;
	EndIf;
	
	If ObjectsProcessed = 0 AND ObjectsWithIssuesCount <> 0 Then
		MessageText = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("ru = 'Процедуре РегистрыСведений.НаличиеФайлов.ОбработатьДанныеДляПереходаНаНовуюВерсию.ОбработатьДанныеДляПереходаНаНовуюВерсию не удалось обработать программы электронной подписи (пропущены): %1'; en = 'The InformationRegisters.FilesExist.ProcessDataForMigrationToNewVersion procedure cannot process digital signature applications (skipped): %1.'; pl = 'Procedurze InformationRegisters.FilesExist.ProcessDataForMigrationToNewVersion.ProcessDataForMigrationToNewVersion nie udało się przetworzyć programów podpisu elektronicznego (pominięte): %1';de = 'Das Verfahren InformationRegisters.FilesExist.ProcessDataForMigrationToNewVersion.ProcessDataForMigrationToNewVersion kann digitale Signatur-Anwendungen nicht verarbeiten (übersprungen): %1';ro = 'Procedura InformationRegisters.FilesExist.ProcessDataForMigrationToNewVersion.ProcessDataForMigrationToNewVersion procedura nu poate procesa aplicațiile semnăturii digitale (omis): %1';tr = 'BilgiKayıtları.DosyalarıVar.YeniSürümeGeçişİçinİşlemVerileri.Yeni.Sürüme.Geçiş.İçin.İşlem.Verileri prosedürü dijital imza uygulamalarını işleyemiyor (atlandı): %1'; es_ES = 'El procedimiento InformationRegisters.FilesExist.ProcessDataForMigrationToNewVersion.ProcessDataForMigrationToNewVersion no ha podido procesar los programas de firma electrónica (saltados): %1'"), 
		ObjectsWithIssuesCount);
		Raise MessageText;
	Else
		WriteLogEvent(InfobaseUpdate.EventLogEvent(), EventLogLevel.Information,
		, ,
		StringFunctionsClientServer.SubstituteParametersToString(
		NStr("ru = 'Процедура РегистрыСведений.НаличиеФайлов.ОбработатьДанныеДляПереходаНаНовуюВерсию обработала очередную порцию программ электронной подписи: %1'; en = 'The InformationRegisters.FilesExist.ProcessDataForMigrationToNewVersion procedure has processed digital signature applications: %1.'; pl = 'Procedura InformationRegisters.FilesExist.ProcessDataForMigrationToNewVersion przetworzyła kolejną partię programów podpisu elektronicznego: %1';de = 'Das Verfahren InformationRegisters.FilesExist.ProcessDataForMigrationToNewVersion hat digitale Signatur-Anwendungen verarbeitet: %1';ro = 'Procedura InformationRegisters.FilesExist.ProcessDataForMigrationToNewVersion a procesat aplicațiile pentru semnătura digitală: %1';tr = 'Kılavuzlar.Dosyalar.YeniSürümeGeçişİçinVeriİşle.YeniSürümeGeçişİçinVeriİşle prosedürü sıradaki e-imza uygulamaların kısmını işledi: %1'; es_ES = 'El procedimiento InformationRegisters.FilesExist.ProcessDataForMigrationToNewVersion no ha procesado una porción de programas de firma electrónica: %1'"),
		ObjectsProcessed));
	EndIf;
	
	Parameters.ProcessingCompleted = ProcessingCompleted;
	
EndProcedure

#EndRegion

#EndIf

