///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then
	
#Region Private

#Region UpdateHandlers

Procedure RegisterDataToProcessForMigrationToNewVersion(Parameters) Export
	
	If Not Common.SeparatedDataUsageAvailable() Then
		Return;
	EndIf;
	
	AdditionalParameters = InfobaseUpdate.AdditionalProcessingMarkParameters();
	AdditionalParameters.IsIndependentInformationRegister = True;
	AdditionalParameters.FullRegisterName             = "InformationRegister.DeleteDataExchangeResults";
	
	Query = New Query(
	"SELECT
	|	DeleteDataExchangeResults.ObjectWithIssue AS ObjectWithIssue,
	|	DeleteDataExchangeResults.IssueType AS IssueType
	|FROM
	|	InformationRegister.DeleteDataExchangeResults AS DeleteDataExchangeResults");
	
	Result = Query.Execute().Unload();
	
	InfobaseUpdate.MarkForProcessing(Parameters, Result, AdditionalParameters);
	
EndProcedure

Procedure ProcessDataForMigrationToNewVersion(Parameters) Export
	
	If Not Common.SeparatedDataUsageAvailable() Then
		Return;
	EndIf;
	
	ProcessingCompleted = True;
	
	RegisterMetadata    = Metadata.InformationRegisters.DeleteDataExchangeResults;
	FullRegisterName     = RegisterMetadata.FullName();
	RegisterPresentation = RegisterMetadata.Presentation();
	
	AdditionalProcessingDataSelectionParameters = InfobaseUpdate.AdditionalProcessingDataSelectionParameters();
	
	Selection = InfobaseUpdate.SelectStandaloneInformationRegisterDimensionsToProcess(
		Parameters.Queue, FullRegisterName, AdditionalProcessingDataSelectionParameters);
	
	Processed = 0;
	RecordsWithIssuesCount = 0;
	
	While Selection.Next() Do
		
		Try
			
			TransferRegisterRecords(Selection);
			Processed = Processed + 1;
			
		Except
			
			RecordsWithIssuesCount = RecordsWithIssuesCount + 1;
			
			MessageText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'Не удалось обработать набор записей регистра ""%1"" по причине:
				|%2'; 
				|en = 'Failed to process the register record set ""%1"" due to:
				|%2'; 
				|pl = 'Nie udało się przetworzyć zestaw zapisów wielkości liter ""%1"" z powodu:
				|%2';
				|de = 'Aus diesem Grund war es nicht möglich, den Satz von Registereinträgen ""%1"" zu verarbeiten:
				|%2';
				|ro = 'Eșec la procesarea setului de înregistrări ale registrului ""%1"" din motivul:
				|%2';
				|tr = 'Kayıt defterinin ""%1"" kayıt seti aşağıdaki nedenle işlenemedi: 
				|%2 '; 
				|es_ES = 'No se ha podido procesar el conjunto de registros del registro ""%1"" a causa de:
				|%2'"), RegisterPresentation, DetailErrorDescription(ErrorInfo()));
				
			WriteLogEvent(InfobaseUpdate.EventLogEvent(), EventLogLevel.Warning,
				RegisterMetadata, , MessageText);
			
		EndTry;
		
	EndDo;
	
	If Not InfobaseUpdate.DataProcessingCompleted(Parameters.Queue, FullRegisterName) Then
		ProcessingCompleted = False;
	EndIf;
	
	If Processed = 0 AND RecordsWithIssuesCount <> 0 Then
		MessageText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Процедуре РегистрыСведений.УдалитьРезультатыОбменаДанными.ОбработатьДанныеДляПереходаНаНовуюВерсию не удалось обработать некоторые записи. Пропущены: %1'; en = 'The InformationRegisters.DeleteDataExchangeResults.ProcessDataForMigrationToNewVersion procedure unable to process some objects. Skipped: %1'; pl = 'Procedurze РегистрыСведений.УдалитьРезультатыОбменаДанными.ОбработатьДанныеДляПереходаНаНовуюВерсию nie udało się przetworzyć niektóre zapisy. Pominięte: %1';de = 'Die Prozedur Informationsregister.DatenaustauschergebnisseLöschen.DatenFürDenÜbergangZurNeuenVersionVerarbeiten konnte einige Datensätze nicht verarbeiten. Ausgelassen: %1';ro = 'Procedura РегистрыСведений.УдалитьРезультатыОбменаДанными.ОбработатьДанныеДляПереходаНаНовуюВерсию nu a putut procesa unele înregistrări. Omise: %1';tr = 'VeriKayıtDefterleri.VeriAlışverişiSonuçlarınıKaldır.YeniSürümeGeçişVerileriniİşle işlemi bazı nesneleri işleyemedi. Atlatılan: %1'; es_ES = 'El procedimiento РегистрыСведений.УдалитьРезультатыОбменаДанными.ОбработатьДанныеДляПереходаНаНовуюВерсию no ha podido procesar unos registros. Saltados: %1'"), 
			RecordsWithIssuesCount);
		Raise MessageText;
	Else
		WriteLogEvent(InfobaseUpdate.EventLogEvent(), EventLogLevel.Information,
			, ,
			StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Процедура РегистрыСведений.УдалитьРезультатыОбменаДанными.ОбработатьДанныеДляПереходаНаНовуюВерсию обработала очередную порцию записей: %1'; en = 'The InformationRegisters.DeleteDataExchangeResults.ProcessDataForMigrationToNewVersion procedure processed the next part of records: %1'; pl = 'Procedura РегистрыСведений.УдалитьРезультатыОбменаДанными.ОбработатьДанныеДляПереходаНаНовуюВерсию opracowała nową porcję zapisów (pominięte): %1';de = 'Die Prozedur Informationsregister.DatenaustauschergebnisseLöschen.DatenFürDenÜbergangZurNeuenVersionVerarbeiten verarbeitete den nächsten Teil der Datensätze: %1';ro = 'Procedura РегистрыСведений.УдалитьРезультатыОбменаДанными.ОбработатьДанныеДляПереходаНаНовуюВерсию a procesat porțiunea de rând a înregistrărilor: %1';tr = 'BilgiKaydedicileri.VeriAlışverişiSonuçlarınıKaldır.YeniSürümeGeçişİçinVerilerinİşlenmesi prosedürü veri alışverişi ünitesinin sıradaki kayıt partisini işledi: %1'; es_ES = 'El procedimiento РегистрыСведений.УдалитьРезультатыОбменаДанными.ОбработатьДанныеДляПереходаНаНовуюВерсию ha procesado una parte de registros: %1'"),
			Processed));
	EndIf;
	
	Parameters.ProcessingCompleted = ProcessingCompleted;
	
EndProcedure

Procedure TransferRegisterRecords(RegisterRecord) 
	
	If Not ValueIsFilled(RegisterRecord.ObjectWithIssue) Then
		RecordSetOld = CreateRecordSet();
		RecordSetOld.Filter.ObjectWithIssue.Set(RegisterRecord.ObjectWithIssue);
		RecordSetOld.Filter.IssueType.Set(RegisterRecord.IssueType);
		
		InfobaseUpdate.WriteRecordSet(RecordSetOld);
		Return;
	EndIf;
	
	BeginTransaction();
	Try
		
		MetadataObjectID = Common.MetadataObjectID(RegisterRecord.ObjectWithIssue.Metadata());
		
		Lock = New DataLock;
		
		LockItem = Lock.Add("InformationRegister.DeleteDataExchangeResults");
		LockItem.SetValue("ObjectWithIssue", RegisterRecord.ObjectWithIssue);
		LockItem.SetValue("IssueType",      RegisterRecord.IssueType);		
		
		LockItem = Lock.Add("InformationRegister.DataExchangeResults");
		LockItem.SetValue("IssueType",      RegisterRecord.IssueType);
		LockItem.SetValue("MetadataObject", MetadataObjectID);
		LockItem.SetValue("ObjectWithIssue", RegisterRecord.ObjectWithIssue);
		
		Lock.Lock();
		
		RecordSetOld = CreateRecordSet();
		RecordSetOld.Filter.ObjectWithIssue.Set(RegisterRecord.ObjectWithIssue);
		RecordSetOld.Filter.IssueType.Set(RegisterRecord.IssueType);
		
		RecordSetOld.Read();
		
		If RecordSetOld.Count() = 0 Then
			InfobaseUpdate.MarkProcessingCompletion(RecordSetOld);
		Else
			
			RecordSetNew = InformationRegisters.DataExchangeResults.CreateRecordSet();
			RecordSetNew.Filter.IssueType.Set(RegisterRecord.IssueType);		
			RecordSetNew.Filter.MetadataObject.Set(MetadataObjectID);
			RecordSetNew.Filter.ObjectWithIssue.Set(RegisterRecord.ObjectWithIssue);
			
			RecordNew = RecordSetNew.Add();
			FillPropertyValues(RecordNew, RecordSetOld[0]);
			
			RecordNew.MetadataObject = MetadataObjectID;
			
			InfobaseUpdate.WriteRecordSet(RecordSetNew);
			
			RecordSetOld.Clear();
			InfobaseUpdate.WriteRecordSet(RecordSetOld);
			
		EndIf;
		
		CommitTransaction();
		
	Except
		
		RollbackTransaction();
		Raise;
		
	EndTry	
	
EndProcedure

#EndRegion

#EndRegion
	
#EndIf