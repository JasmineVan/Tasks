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

// StandardSubsystems.AccessManagement

// See AccessManagementOverridable.OnFillListsWithAccessRestriction. 
Procedure OnFillAccessRestriction(Restriction) Export
	
	Restriction.Text =
	"AllowReadUpdate
	|WHERE
	|	ListReadingAllowed(ObjectWithIssue)";
	
EndProcedure

// End StandardSubsystems.AccessManagement

#EndRegion

#EndRegion

#Region Private

Procedure RegisterDataToProcessForMigrationToNewVersion(Parameters) Export
	
	AdditionalParameters = InfobaseUpdate.AdditionalProcessingMarkParameters();
	AdditionalParameters.IsIndependentInformationRegister = True;
	AdditionalParameters.FullRegisterName             = Metadata.InformationRegisters.AccountingCheckResults.FullName();
	
	AllIssuesProcessed = False;
	UniqueKey      = CommonClientServer.BlankUUID();
	While Not AllIssuesProcessed Do
		
		Query = New Query;
		Query.Text = "SELECT TOP 1000
			|	AccountingCheckResults.ObjectWithIssue AS ObjectWithIssue,
			|	AccountingCheckResults.CheckRule AS CheckRule,
			|	AccountingCheckResults.CheckKind AS CheckKind,
			|	AccountingCheckResults.UniqueKey AS UniqueKey
			|FROM
			|	InformationRegister.AccountingCheckResults AS AccountingCheckResults
			|WHERE
			|	AccountingCheckResults.UniqueKey > &UniqueKey
			|
			|ORDER BY
			|	UniqueKey";
		
		Query.SetParameter("UniqueKey", UniqueKey);
		Result = Query.Execute().Unload();
	
		InfobaseUpdate.MarkForProcessing(Parameters, Result, AdditionalParameters);
		
		RecordsCount = Result.Count();
		If RecordsCount < 1000 Then
			AllIssuesProcessed = True;
		EndIf;
		
		If RecordsCount > 0 Then
			UniqueKey = Result[RecordsCount - 1].UniqueKey;
		EndIf;
		
	EndDo;
	
EndProcedure

Procedure ProcessDataForMigrationToNewVersion(Parameters) Export
	
	ProcessingCompleted = True;
	
	RegisterMetadata    = Metadata.InformationRegisters.AccountingCheckResults;
	FullRegisterName     = RegisterMetadata.FullName();
	RegisterPresentation = RegisterMetadata.Presentation();
	FilterPresentation   = NStr("ru = 'Проблемный объект = ""%1""
		|Правило проверки = ""%2""
		|Вид проверки = ""%3""
		|Ключ уникальности = ""%4""'; 
		|en = 'Object with issues = ""%1""
		|Check rule = ""%2""
		|Check kind = ""%3""
		|Unique key = ""%4""'; 
		|pl = 'Object with issues = ""%1""
		|Check rule = ""%2""
		|Check kind = ""%3""
		|Unique key = ""%4""';
		|de = 'Object with issues = ""%1""
		|Check rule = ""%2""
		|Check kind = ""%3""
		|Unique key = ""%4""';
		|ro = 'Object with issues = ""%1""
		|Check rule = ""%2""
		|Check kind = ""%3""
		|Unique key = ""%4""';
		|tr = 'Object with issues = ""%1""
		|Check rule = ""%2""
		|Check kind = ""%3""
		|Unique key = ""%4""'; 
		|es_ES = 'Object with issues = ""%1""
		|Check rule = ""%2""
		|Check kind = ""%3""
		|Unique key = ""%4""'");
	
	AdditionalProcessingDataSelectionParameters = InfobaseUpdate.AdditionalProcessingDataSelectionParameters();
	
	Selection = InfobaseUpdate.SelectStandaloneInformationRegisterDimensionsToProcess(
		Parameters.Queue, FullRegisterName, AdditionalProcessingDataSelectionParameters);
	
	ObjectsProcessed = 0;
	ObjectsWithIssuesCount = 0;
	
	While Selection.Next() Do
		
		BeginTransaction();
		
		Try
			
			ObjectWithIssue = Selection.ObjectWithIssue;
			CheckRule  = Selection.CheckRule;
			CheckKind      = Selection.CheckKind;
			UniqueKey = Selection.UniqueKey;
			
			Lock = New DataLock;
			LockItem = Lock.Add(FullRegisterName);
			LockItem.SetValue("ObjectWithIssue", ObjectWithIssue);
			LockItem.SetValue("CheckRule",  CheckRule);
			LockItem.SetValue("CheckKind",      CheckKind);
			LockItem.SetValue("UniqueKey", UniqueKey);
			Lock.Lock();
			
			RecordSet = CreateRecordSet();
			Filter = RecordSet.Filter;
			Filter.UniqueKey.Set(UniqueKey);
			Filter.ObjectWithIssue.Set(ObjectWithIssue);
			Filter.CheckRule.Set(CheckRule);
			Filter.CheckKind.Set(CheckKind);
			
			FilterPresentation = StringFunctionsClientServer.SubstituteParametersToString(FilterPresentation, ObjectWithIssue, CheckRule, CheckKind, UniqueKey);
			
			RecordSet.Read();
			For Each CurrentRecord In RecordSet Do
				
				If Not ValueIsFilled(CurrentRecord.Checksum) Then
					CurrentRecord.Checksum = AccountingAuditInternal.IssueChecksum(CurrentRecord);
				EndIf;
				
				If CurrentRecord.DeleteIgnoreIssue AND Not CurrentRecord.IgnoreIssue Then
					CurrentRecord.IgnoreIssue = CurrentRecord.DeleteIgnoreIssue;
				EndIf;
				
			EndDo;
			
			InfobaseUpdate.WriteRecordSet(RecordSet);
			
			ObjectsProcessed = ObjectsProcessed + 1;
			
			CommitTransaction();
			
		Except
			
			RollbackTransaction();
			
			ObjectsWithIssuesCount = ObjectsWithIssuesCount + 1;
			
			MessageText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'Не удалось обработать набор записей регистра ""%1"" с отбором %2 по причине:
				|%3'; 
				|en = 'Cannot process set of ""%1"" register records with filter %2 due to: 
				|%3'; 
				|pl = 'Cannot process set of ""%1"" register records with filter %2 due to: 
				|%3';
				|de = 'Cannot process set of ""%1"" register records with filter %2 due to: 
				|%3';
				|ro = 'Cannot process set of ""%1"" register records with filter %2 due to: 
				|%3';
				|tr = 'Cannot process set of ""%1"" register records with filter %2 due to: 
				|%3'; 
				|es_ES = 'Cannot process set of ""%1"" register records with filter %2 due to: 
				|%3'"), RegisterPresentation, FilterPresentation, DetailErrorDescription(ErrorInfo()));
				
			WriteLogEvent(InfobaseUpdate.EventLogEvent(), EventLogLevel.Warning,
				RegisterMetadata, , MessageText);
			
		EndTry;
		
	EndDo;
	
	If Not InfobaseUpdate.DataProcessingCompleted(Parameters.Queue, "InformationRegister.AccountingCheckResults") Then
		ProcessingCompleted = False;
	EndIf;
	
	If ObjectsProcessed = 0 AND ObjectsWithIssuesCount <> 0 Then
		MessageText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Процедуре РегистрыСведений.РезультатыПроверкиУчета.ОбработатьДанныеДляПереходаНаНовуюВерсию не удалось обработать некоторые записи проблемных объектов (пропущены): %1'; en = 'The InformationRegisters.AccountingCheckResults.ProcessDataForMigrationToNewVersion procedure cannot process some records of objects with issues (skipped): %1'; pl = 'The InformationRegisters.AccountingCheckResults.ProcessDataForMigrationToNewVersion procedure cannot process some records of objects with issues (skipped): %1';de = 'The InformationRegisters.AccountingCheckResults.ProcessDataForMigrationToNewVersion procedure cannot process some records of objects with issues (skipped): %1';ro = 'The InformationRegisters.AccountingCheckResults.ProcessDataForMigrationToNewVersion procedure cannot process some records of objects with issues (skipped): %1';tr = 'The InformationRegisters.AccountingCheckResults.ProcessDataForMigrationToNewVersion procedure cannot process some records of objects with issues (skipped): %1'; es_ES = 'The InformationRegisters.AccountingCheckResults.ProcessDataForMigrationToNewVersion procedure cannot process some records of objects with issues (skipped): %1'"), 
			ObjectsWithIssuesCount);
		Raise MessageText;
	Else
		WriteLogEvent(InfobaseUpdate.EventLogEvent(), EventLogLevel.Information,
			, ,
			StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Процедура РегистрыСведений.НаличиеФайлов.ОбработатьДанныеДляПереходаНаНовуюВерсию обработала очередную порцию проблемных объектов: %1'; en = 'The InformationRegisters.AccountingCheckResults.ProcessDataForMigrationToNewVersion procedure processed the next portion of objects with issues: %1'; pl = 'The InformationRegisters.AccountingCheckResults.ProcessDataForMigrationToNewVersion procedure processed the next portion of objects with issues: %1';de = 'The InformationRegisters.AccountingCheckResults.ProcessDataForMigrationToNewVersion procedure processed the next portion of objects with issues: %1';ro = 'The InformationRegisters.AccountingCheckResults.ProcessDataForMigrationToNewVersion procedure processed the next portion of objects with issues: %1';tr = 'The InformationRegisters.AccountingCheckResults.ProcessDataForMigrationToNewVersion procedure processed the next portion of objects with issues: %1'; es_ES = 'The InformationRegisters.AccountingCheckResults.ProcessDataForMigrationToNewVersion procedure processed the next portion of objects with issues: %1'"),
			ObjectsProcessed));
	EndIf;
	
	Parameters.ProcessingCompleted = ProcessingCompleted;
	
EndProcedure

#EndRegion

#EndIf