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
	AdditionalParameters.FullRegisterName             = "InformationRegister.DeleteExchangeTransportSettings";
	
	QueryParameters = New Structure;
	QueryParameters.Insert("ExchangePlansArray",                 New Array);
	QueryParameters.Insert("ExchangePlanAdditionalProperties", "");
	QueryParameters.Insert("ResultToTemporaryTable",       True);
	
	TempTablesManager = New TempTablesManager;
	
	ExchangeNodesQuery = New Query(DataExchangeServer.ExchangePlansForMonitorQueryText(QueryParameters, False));
	ExchangeNodesQuery.TempTablesManager = TempTablesManager;
	ExchangeNodesQuery.Execute();
	
	Query = New Query(
	"SELECT
	|	TransportSettings.InfobaseNode AS InfobaseNode
	|FROM
	|	ConfigurationExchangePlans AS ConfigurationExchangePlans
	|		INNER JOIN InformationRegister.DeleteExchangeTransportSettings AS TransportSettings
	|		ON (TransportSettings.InfobaseNode = ConfigurationExchangePlans.InfobaseNode)");
	
	Query.TempTablesManager = TempTablesManager;
	
	Result = Query.Execute().Unload();
	
	InfobaseUpdate.MarkForProcessing(Parameters, Result, AdditionalParameters);
	
EndProcedure

Procedure ProcessDataForMigrationToNewVersion(Parameters) Export
	
	If Not Common.SeparatedDataUsageAvailable() Then
		Return;
	EndIf;
	
	ProcessingCompleted = True;
	
	RegisterMetadata    = Metadata.InformationRegisters.DeleteExchangeTransportSettings;
	FullRegisterName     = RegisterMetadata.FullName();
	RegisterPresentation = RegisterMetadata.Presentation();
	
	AdditionalProcessingDataSelectionParameters = InfobaseUpdate.AdditionalProcessingDataSelectionParameters();
	
	Selection = InfobaseUpdate.SelectStandaloneInformationRegisterDimensionsToProcess(
		Parameters.Queue, FullRegisterName, AdditionalProcessingDataSelectionParameters);
	
	Processed = 0;
	RecordsWithIssuesCount = 0;
	
	While Selection.Next() Do
		
		Try
			
			TransferSettingsOfCorrespondentDataExchangeTransport(Selection.InfobaseNode);
			Processed = Processed + 1;
			
		Except
			
			RecordsWithIssuesCount = RecordsWithIssuesCount + 1;
			
			MessageText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'Не удалось обработать набор записей регистра ""%1"" с отбором ""УзелИнформационнойБазы = %2"" по причине:
				|%3'; 
				|en = 'Cannot process set of ""%1"" register records with filter ""InfobaseNode = %2"" due to: 
				|%3'; 
				|pl = 'Nie udało się przetworzyć zestawu rejestrów ""%1"" z wyborem ""InfobaseNode = %2"" z powodu: 
				|%3 ';
				|de = 'Der Satz von ""%1"" Registereinträgen mit dem Filter ""InfobaseNode = %2"" kann nicht verarbeitet werden aufgrund von:
				|%3 ';
				|ro = 'Nu se poate procesa setul de înregistrări ""%1"" înregistrate cu filtrul ""InfobaseNode = %2"" din cauza: 
				|%3';
				|tr = 'Aşağıdaki nedenle kaydedicinin kayıt kümesi ""%1"" ""VeriTabanıÜnitesi"" = %2"" seçimle işlenemedi: 
				|%3'; 
				|es_ES = 'No se ha podido procesar el conjunto de registros del registro ""%1"" con selección ""InfobaseNode = %2"" a causa de:
				|%3'"), RegisterPresentation, Selection.InfobaseNode, DetailErrorDescription(ErrorInfo()));
				
			WriteLogEvent(InfobaseUpdate.EventLogEvent(), EventLogLevel.Warning,
				RegisterMetadata, , MessageText);
			
		EndTry;
		
	EndDo;
	
	If Not InfobaseUpdate.DataProcessingCompleted(Parameters.Queue, FullRegisterName) Then
		ProcessingCompleted = False;
	EndIf;
	
	If Processed = 0 AND RecordsWithIssuesCount <> 0 Then
		MessageText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Процедуре РегистрыСведений.УдалитьНастройкиТранспортаОбмена.ОбработатьДанныеДляПереходаНаНовуюВерсию не удалось обработать некоторые записи узлов обмена (пропущены): %1'; en = 'The InformationRegisters.DeleteExchangeTransportSettings.ProcessDataForMigrationToNewVersion procedure cannot process some exchange node records (skipped): %1'; pl = 'Procedurze InformationRegisters.DeleteExchangeTransportSettings.ProcessDataForMigrationToNewVersion nie udało się opracować niektóre elementy zapisu węzłów wymiany (pominięte): %1';de = 'Das Verfahren InformationRegisters.DeleteExchangeTransportSettings.ProcessDataForMigrationToNewVersion kann einige Datensätze von Austauschknoten nicht verarbeiten (übersprungen): %1';ro = 'Procedura InformationRegisters.DeleteExchangeTransportSettings.ProcessDataForMigrationToNewVersion nu poate procesa unele înregistrări legate de nodul de schimb (omis): %1';tr = 'BilgiKaydedicileri.VeriAlışverişiÜnitelerininAyarlarınıKaldır.YeniSürümeGeçişİçinVerilerinİşlenmesi prosedürü veri alışverişi ünitesinin bazı kayıtlarını işleyemedi (atlatıldı): %1'; es_ES = 'El procedimiento InformationRegisters.DeleteExchangeTransportSettings.ProcessDataForMigrationToNewVersion no ha podido procesar unos registros del nodo de cambio (saltados): %1'"), 
			RecordsWithIssuesCount);
		Raise MessageText;
	Else
		WriteLogEvent(InfobaseUpdate.EventLogEvent(), EventLogLevel.Information,
			, ,
			StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Процедура РегистрыСведений.УдалитьНастройкиТранспортаОбмена.ОбработатьДанныеДляПереходаНаНовуюВерсию обработала очередную порцию записей: %1'; en = 'The InformationRegisters.DeleteExchangeTransportSettings.ProcessDataForMigrationToNewVersion procedure processed records: %1'; pl = 'Procedura InformationRegisters.DeleteExchangeTransportSettings.ProcessDataForMigrationToNewVersion opracowała kolejną porcję zapisów: %1';de = 'Die verarbeiteten Datensätze des InformationRegisters.DeleteExchangeTransportSettings.ProcessDataForMigrationToNewVersion Verfahrens: %1';ro = 'Înregistrările prelucrate în procedura InformationRegisters.DeleteExchangeTransportSettings.ProcessDataForMigrationToNewVersion: %1';tr = 'BilgiKaydedicileri.VeriAlışverişiÜnitelerininAyarlarınıKaldır.YeniSürümeGeçişİçinVerilerinİşlenmesi prosedürü kayıtları işilendi: %1'; es_ES = 'El procedimiento InformationRegisters.DeleteExchangeTransportSettings.ProcessDataForMigrationToNewVersion ha procesado una porción de registro: %1'"),
			Processed));
	EndIf;
	
	Parameters.ProcessingCompleted = ProcessingCompleted;
	
EndProcedure

Procedure TransferSettingsOfCorrespondentDataExchangeTransport(InfobaseNode) Export
	
	If Not Common.SeparatedDataUsageAvailable() Then
		Return;
	EndIf;
	
	If Not ValueIsFilled(InfobaseNode) Then
		RecordSet = CreateRecordSet();
		RecordSet.Filter.InfobaseNode.Set(InfobaseNode);
		
		InfobaseUpdate.MarkProcessingCompletion(RecordSet);
		Return;
	EndIf;
	
	BeginTransaction();
	Try
		Lock = New DataLock;
		
		LockItem = Lock.Add("InformationRegister.DeleteExchangeTransportSettings");
		LockItem.SetValue("InfobaseNode", InfobaseNode);
		
		LockItem = Lock.Add("InformationRegister.DataExchangeTransportSettings");
		LockItem.SetValue("Correspondent", InfobaseNode);
		
		Lock.Lock();
		
		RecordSetOld = CreateRecordSet();
		RecordSetOld.Filter.InfobaseNode.Set(InfobaseNode);
		
		RecordSetOld.Read();
		
		If RecordSetOld.Count() = 0 Then
			InfobaseUpdate.MarkProcessingCompletion(RecordSetOld);
		Else
			RecordSetNew = InformationRegisters.DataExchangeTransportSettings.CreateRecordSet();
			RecordSetNew.Filter.Correspondent.Set(InfobaseNode);
			
			RecordNew = RecordSetNew.Add();
			FillPropertyValues(RecordNew, RecordSetOld[0]);
			RecordNew.Correspondent = InfobaseNode;
			
			InfobaseUpdate.WriteRecordSet(RecordSetNew);
			
			RecordSetOld.Clear();
			InfobaseUpdate.WriteRecordSet(RecordSetOld);
		EndIf;
		
		CommitTransaction();
		
	Except
		
		RollbackTransaction();
		Raise;
		
	EndTry;
	
EndProcedure

#EndRegion

#EndRegion

#EndIf